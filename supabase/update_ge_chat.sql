-- Endless Road update: Grand Exchange + chat.
-- Paste ALL of this into Supabase -> SQL Editor (empty query) -> Run. Safe to run more than once.

-- compares an upload with the last accepted save; null when it is fine
create or replace function public.save_problems(prof profiles, old saves, p_data jsonb) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  el numeric; journey boolean; k text; gain numeric; total numeric := 0;
  reasons text[] := '{}';
  -- limits, well above anything the game can reach legitimately
  xp_rate constant numeric := 600;      -- XP per second in one skill
  xp_total_rate constant numeric := 1000; -- XP per second over all skills
  xp_grace constant numeric := 30000;   -- quest rewards land in one go
  gold_rate constant numeric := 600;    -- wealth per second
  gold_grace constant numeric := 150000;
begin
  el := least(extract(epoch from now() - old.updated_at), 86400) + 30;
  journey := coalesce((p_data ->> 'journeys')::int, 0) = coalesce((old.data ->> 'journeys')::int, 0) + 1;
  -- another device (or an old tab) sending older progress: hand it the newer save
  if (not journey and coalesce((p_data ->> 'kills')::numeric, 0) < coalesce((old.data ->> 'kills')::numeric, 0))
     or coalesce((p_data ->> 'geSeq')::int, 0) < coalesce((old.data ->> 'geSeq')::int, 0) then
    return jsonb_build_object('reason', 'stale', 'data', old.data);
  end if;
  for k in select jsonb_object_keys(p_data -> 'skills') loop
    gain := coalesce((p_data -> 'skills' ->> k)::numeric, 0)
          - case when journey then 0 else coalesce((old.data -> 'skills' ->> k)::numeric, 0) end;
    if gain < -1 then return jsonb_build_object('reason', 'stale', 'data', old.data); end if;
    if gain > el * xp_rate + xp_grace then reasons := reasons || format('%s +%s XP in %s s', k, round(gain), round(el)); end if;
    total := total + greatest(gain, 0);
  end loop;
  if total > el * xp_total_rate + xp_grace then reasons := reasons || format('total +%s XP in %s s', round(total), round(el)); end if;
  gain := net_worth(p_data) - case when journey then 0 else net_worth(old.data) end;
  if gain > el * gold_rate + gold_grace + prof.credit then reasons := reasons || format('wealth +%s in %s s', round(gain), round(el)); end if;
  -- kills are lifetime and survive a New Journey
  gain := coalesce((p_data ->> 'kills')::numeric, 0) - coalesce((old.data ->> 'kills')::numeric, 0);
  if gain > el / 0.8 + 10 then reasons := reasons || format('kills +%s in %s s', round(gain), round(el)); end if;
  if array_length(reasons, 1) > 0 then
    insert into cheat_flags (user_id, reason, detail) values (prof.id, array_to_string(reasons, '; '), jsonb_build_object('elapsed', round(el)));
    update profiles set flags = flags + 1 where id = prof.id;
    return jsonb_build_object('reason', 'rejected', 'detail', array_to_string(reasons, '; '), 'data', old.data);
  end if;
  return null;
end $$;

-- stores a save the server has checked or changed
create or replace function public.store_save(uid uuid, d jsonb) returns void
language plpgsql security definer set search_path = public as $$
begin
  update saves set data = d, updated_at = now(), syncs = syncs + 1 where user_id = uid;
  update profiles set credit = 0 where id = uid and credit <> 0;
  perform update_hiscore(uid, d);
end $$;

create or replace function public.sync_save(p_data jsonb) returns jsonb
language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); prof profiles; old saves; prob jsonb;
begin
  if uid is null then return jsonb_build_object('ok', false, 'reason', 'not_signed_in'); end if;
  select * into prof from profiles where id = uid;
  if prof.id is null then return jsonb_build_object('ok', false, 'reason', 'no_profile'); end if;
  if prof.banned then return jsonb_build_object('ok', false, 'reason', 'banned'); end if;
  if jsonb_typeof(p_data) <> 'object' or coalesce(p_data ->> 'v', '') <> '1' or jsonb_typeof(p_data -> 'skills') <> 'object'
     or octet_length(p_data::text) > 500000 then
    return jsonb_build_object('ok', false, 'reason', 'invalid');
  end if;
  select * into old from saves where user_id = uid for update;
  if old.user_id is null then
    -- first upload: accepted, but progress made before the account existed is marked on the hiscores
    insert into saves (user_id, data) values (uid, p_data);
    if total_xp(p_data) > 50000 then update profiles set imported = true where id = uid; end if;
    perform update_hiscore(uid, p_data);
    return jsonb_build_object('ok', true, 'first', true);
  end if;
  if extract(epoch from now() - old.updated_at) < 5 then return jsonb_build_object('ok', false, 'reason', 'too_fast'); end if;
  prob := save_problems(prof, old, p_data);
  if prob is not null then return prob || jsonb_build_object('ok', false); end if;
  perform store_save(uid, p_data);
  return jsonb_build_object('ok', true);
exception when others then
  return jsonb_build_object('ok', false, 'reason', 'invalid');
end $$;

-- ---------- Grand Exchange: offers hold the items or gold in escrow, the server matches them ----------
create table if not exists public.ge_offers (
  id bigserial primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  kind text not null check (kind in ('buy', 'sell')),
  item text not null,
  price bigint not null check (price between 1 and 2000000000),
  qty int not null check (qty between 1 and 100000000),
  left_qty int not null,
  status text not null default 'open' check (status in ('open', 'done', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists ge_offers_book on public.ge_offers (item, kind, status, price);
create index if not exists ge_offers_user on public.ge_offers (user_id, created_at desc);
create table if not exists public.ge_collect (
  id bigserial primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  item text not null,              -- '__gold' for coins
  qty bigint not null check (qty > 0),
  created_at timestamptz not null default now()
);
create table if not exists public.ge_trades (
  id bigserial primary key, item text not null, qty int not null, price bigint not null, created_at timestamptz not null default now()
);
create index if not exists ge_trades_item on public.ge_trades (item, created_at desc);
alter table public.ge_offers enable row level security;
alter table public.ge_collect enable row level security;
alter table public.ge_trades enable row level security;
drop policy if exists "open offers are public" on public.ge_offers;
create policy "open offers are public" on public.ge_offers for select using (status = 'open' or (select auth.uid()) = user_id);
drop policy if exists "own collection box" on public.ge_collect;
create policy "own collection box" on public.ge_collect for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists "trades are public" on public.ge_trades;
create policy "trades are public" on public.ge_trades for select using (true);
revoke insert, update, delete on public.ge_offers, public.ge_collect, public.ge_trades from anon, authenticated;

-- checks the hero the browser sends before any trade; the trade then works on that hero
create or replace function public.ge_check(p_data jsonb) returns jsonb
language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); prof profiles; old saves; prob jsonb;
begin
  if uid is null then return jsonb_build_object('ok', false, 'reason', 'Sign in first'); end if;
  select * into prof from profiles where id = uid;
  if prof.id is null or prof.banned then return jsonb_build_object('ok', false, 'reason', 'Your account cannot trade'); end if;
  if jsonb_typeof(p_data) <> 'object' or coalesce(p_data ->> 'v', '') <> '1' or jsonb_typeof(p_data -> 'inv') <> 'object' then
    return jsonb_build_object('ok', false, 'reason', 'invalid');
  end if;
  select * into old from saves where user_id = uid for update;
  if old.user_id is null then return jsonb_build_object('ok', false, 'reason', 'Save your hero to the cloud first'); end if;
  prob := save_problems(prof, old, p_data);
  if prob is not null then return prob || jsonb_build_object('ok', false); end if;
  -- every trade bumps geSeq, so an older copy of the hero (another tab or device) can never be saved over it
  return jsonb_build_object('ok', true, 'name', prof.name,
    'data', p_data || jsonb_build_object('geSeq', coalesce((old.data ->> 'geSeq')::int, 0) + 1));
end $$;

create or replace function public.ge_give(uid uuid, p_item text, p_qty numeric) returns void
language sql security definer set search_path = public as $$
  insert into ge_collect (user_id, item, qty) select uid, p_item, p_qty where p_qty > 0
$$;

create or replace function public.ge_place(p_data jsonb, p_kind text, p_item text, p_qty int, p_price bigint) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid(); c jsonb; d jsonb; have numeric; cost numeric; off ge_offers; o record; t int; tp bigint; left_q int;
begin
  if p_kind not in ('buy', 'sell') or p_qty is null or p_qty < 1 or p_qty > 100000000 or p_price is null or p_price < 1 or p_price > 2000000000 then
    return jsonb_build_object('ok', false, 'reason', 'Check the amount and the price');
  end if;
  if not exists (select 1 from item_stats where id = p_item) then return jsonb_build_object('ok', false, 'reason', 'Unknown item'); end if;
  c := ge_check(p_data);
  if not (c ->> 'ok')::boolean then return c; end if;
  if (select count(*) from ge_offers where user_id = uid and status = 'open') >= 8 then
    return jsonb_build_object('ok', false, 'reason', 'All 8 offer slots are in use');
  end if;
  d := c -> 'data';
  if p_kind = 'sell' then
    have := coalesce((d -> 'inv' ->> p_item)::numeric, 0);
    if have < p_qty then return jsonb_build_object('ok', false, 'reason', 'You don''t have that many'); end if;
    d := case when have = p_qty then d #- array['inv', p_item] else jsonb_set(d, array['inv', p_item], to_jsonb(have - p_qty)) end;
  else
    cost := p_qty::numeric * p_price;
    if coalesce((d ->> 'gold')::numeric, 0) < cost then return jsonb_build_object('ok', false, 'reason', 'Not enough gold'); end if;
    d := jsonb_set(d, '{gold}', to_jsonb((d ->> 'gold')::numeric - cost));
  end if;
  perform store_save(uid, d);
  insert into ge_offers (user_id, name, kind, item, price, qty, left_qty)
    values (uid, c ->> 'name', p_kind, p_item, p_price, p_qty, p_qty) returning * into off;
  left_q := p_qty;
  -- match the other side: best price first, then oldest; the older offer sets the price; no trading with yourself
  for o in select * from ge_offers
      where item = p_item and status = 'open' and user_id <> uid and kind = (case p_kind when 'sell' then 'buy' else 'sell' end)
        and (case when p_kind = 'sell' then price >= p_price else price <= p_price end)
      order by (case when p_kind = 'sell' then -price else price end), created_at
      for update loop
    exit when left_q = 0;
    t := least(left_q, o.left_qty); tp := o.price;
    update ge_offers set left_qty = left_qty - t, status = case when left_qty - t = 0 then 'done' else status end, updated_at = now() where id = o.id;
    left_q := left_q - t;
    insert into ge_trades (item, qty, price) values (p_item, t, tp);
    if p_kind = 'sell' then
      perform ge_give(o.user_id, p_item, t);
      perform ge_give(uid, '__gold', floor(t::numeric * tp * 0.99));          -- 1% tax, like the OSRS GE
    else
      perform ge_give(uid, p_item, t);
      perform ge_give(o.user_id, '__gold', floor(t::numeric * tp * 0.99));
      perform ge_give(uid, '__gold', t::numeric * (p_price - tp));             -- paid less than offered
    end if;
  end loop;
  update ge_offers set left_qty = left_q, status = case when left_q = 0 then 'done' else 'open' end, updated_at = now() where id = off.id;
  return jsonb_build_object('ok', true, 'data', d, 'filled', p_qty - left_q);
end $$;

create or replace function public.ge_cancel(p_id bigint) returns jsonb
language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); o ge_offers;
begin
  select * into o from ge_offers where id = p_id and user_id = uid and status = 'open' for update;
  if o.id is null then return jsonb_build_object('ok', false, 'reason', 'Offer not found'); end if;
  update ge_offers set status = 'cancelled', updated_at = now() where id = o.id;
  if o.kind = 'sell' then perform ge_give(uid, o.item, o.left_qty);
  else perform ge_give(uid, '__gold', o.left_qty::numeric * o.price); end if;
  return jsonb_build_object('ok', true);
end $$;

create or replace function public.ge_collect_all(p_data jsonb) returns jsonb
language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); c jsonb; d jsonb; r record; got jsonb := '{}';
begin
  c := ge_check(p_data);
  if not (c ->> 'ok')::boolean then return c; end if;
  d := c -> 'data';
  for r in select item, sum(qty) q from ge_collect where user_id = uid group by item loop
    if r.item = '__gold' then d := jsonb_set(d, '{gold}', to_jsonb(coalesce((d ->> 'gold')::numeric, 0) + r.q));
    else d := jsonb_set(d, array['inv', r.item], to_jsonb(coalesce((d -> 'inv' ->> r.item)::numeric, 0) + r.q)); end if;
    got := got || jsonb_build_object(r.item, r.q);
  end loop;
  delete from ge_collect where user_id = uid;
  perform store_save(uid, d);
  return jsonb_build_object('ok', true, 'data', d, 'got', got);
end $$;

-- ---------- chat ----------
alter table public.profiles add column if not exists muted boolean not null default false;
create table if not exists public.chat_messages (
  id bigserial primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  body text not null check (char_length(body) between 1 and 200),
  created_at timestamptz not null default now()
);
create index if not exists chat_messages_time on public.chat_messages (created_at desc);
alter table public.chat_messages enable row level security;
drop policy if exists "recent chat is public" on public.chat_messages;
create policy "recent chat is public" on public.chat_messages for select
  using (created_at > now() - interval '2 days' and not public.is_banned(user_id));
revoke insert, update, delete on public.chat_messages from anon, authenticated;

create or replace function public.chat_send(p_body text) returns jsonb
language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); prof profiles; b text;
begin
  if uid is null then return jsonb_build_object('ok', false, 'reason', 'Sign in to chat'); end if;
  select * into prof from profiles where id = uid;
  if prof.id is null or prof.banned or prof.muted then return jsonb_build_object('ok', false, 'reason', 'You cannot chat'); end if;
  b := left(trim(regexp_replace(coalesce(p_body, ''), '[[:cntrl:]]', '', 'g')), 200);
  if b = '' then return jsonb_build_object('ok', false, 'reason', 'Empty message'); end if;
  if exists (select 1 from chat_messages where user_id = uid and created_at > now() - interval '3 seconds')
     or (select count(*) from chat_messages where user_id = uid and created_at > now() - interval '1 minute') >= 15 then
    return jsonb_build_object('ok', false, 'reason', 'Slow down a little');
  end if;
  insert into chat_messages (user_id, name, body) values (uid, prof.name, b);
  return jsonb_build_object('ok', true);
end $$;

-- live chat: send new messages to open games (the publication only exists on Supabase)
do $$ begin
  alter publication supabase_realtime add table public.chat_messages;
exception when others then null;
end $$;

-- only the game functions can be called from the browser, and only when signed in
revoke execute on function public.level_from_xp(numeric), public.net_worth(jsonb), public.total_xp(jsonb),
  public.update_hiscore(uuid, jsonb), public.claim_name(text), public.sync_save(jsonb), public.fighter(jsonb),
  public.pvp_targets(), public.pvp_attack(uuid), public.save_problems(profiles, saves, jsonb), public.store_save(uuid, jsonb),
  public.ge_check(jsonb), public.ge_give(uuid, text, numeric), public.ge_place(jsonb, text, text, int, bigint), public.ge_cancel(bigint),
  public.ge_collect_all(jsonb), public.chat_send(text) from public, anon, authenticated;
grant execute on function public.claim_name(text), public.sync_save(jsonb), public.pvp_targets(), public.pvp_attack(uuid),
  public.ge_place(jsonb, text, text, int, bigint), public.ge_cancel(bigint), public.ge_collect_all(jsonb), public.chat_send(text) to authenticated;
grant execute on function public.is_banned(uuid) to anon, authenticated;
