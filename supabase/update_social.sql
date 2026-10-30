-- Endless Road update: friends, private messages, recovery codes, quest-aware save checks.
-- Paste ALL of this into Supabase -> SQL Editor (empty query) -> Run. Safe to run more than once.

-- quest rewards: a save that finishes a quest may jump by exactly its reward
create table if not exists public.quest_rewards (id text primary key, gold bigint not null, items bigint not null, xp bigint not null);
alter table public.quest_rewards enable row level security;
insert into public.quest_rewards (id, gold, items, xp) values
  ('q1', 50, 20, 0),
  ('q2', 100, 0, 200),
  ('q3', 120, 50, 0),
  ('q4', 0, 180, 300),
  ('q5', 0, 150, 300),
  ('q6', 0, 1012, 300),
  ('q7', 300, 200, 0),
  ('q8', 800, 300, 0),
  ('q9', 0, 0, 1500),
  ('q10', 0, 0, 1000),
  ('q11', 3000, 450, 0),
  ('q12', 10000, 600, 0),
  ('q13', 20000, 0, 5000),
  ('q15', 400, 0, 400),
  ('q16', 0, 150, 600),
  ('q14', 50000, 600, 0),
  ('q17', 2000, 0, 0),
  ('q18', 15000, 0, 0),
  ('q19', 40000, 0, 0)
on conflict (id) do update set gold = excluded.gold, items = excluded.items, xp = excluded.xp;
alter table public.profiles add column if not exists last_seen timestamptz;
revoke all on public.quest_rewards from anon, authenticated;

-- compares an upload with the last accepted save; null when it is fine
create or replace function public.save_problems(prof profiles, old saves, p_data jsonb) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  el numeric; journey boolean; k text; gain numeric; total numeric := 0;
  reasons text[] := '{}'; q_gold numeric; q_xp numeric;
  -- limits, well above anything the game can reach legitimately
  xp_rate constant numeric := 600;      -- XP per second in one skill
  xp_total_rate constant numeric := 1000; -- XP per second over all skills
  xp_grace constant numeric := 10000;   -- small jumps such as a level-up landing between saves
  gold_rate constant numeric := 300;    -- wealth per second (best legit money makers are near 150)
  gold_grace constant numeric := 25000; -- one rare drop between saves
begin
  el := least(extract(epoch from now() - old.updated_at), 86400) + 30;
  -- quests finished since the last save bring exactly their reward
  select coalesce(sum(r.gold + r.items), 0), coalesce(sum(r.xp), 0) into q_gold, q_xp
    from jsonb_each(case when jsonb_typeof(p_data -> 'quests') = 'object' then p_data -> 'quests' else '{}' end) e
    join quest_rewards r on r.id = e.key
    where e.value ->> 's' = 'done' and coalesce(old.data -> 'quests' -> e.key ->> 's', '') <> 'done';
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
    if gain > el * xp_rate + xp_grace + q_xp then reasons := reasons || format('%s +%s XP in %s s', k, round(gain), round(el)); end if;
    total := total + greatest(gain, 0);
  end loop;
  if total > el * xp_total_rate + xp_grace + q_xp then reasons := reasons || format('total +%s XP in %s s', round(total), round(el)); end if;
  gain := net_worth(p_data) - case when journey then 0 else net_worth(old.data) end;
  if gain > el * gold_rate + gold_grace + q_gold + prof.credit then reasons := reasons || format('wealth +%s in %s s', round(gain), round(el)); end if;
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
  update profiles set credit = 0, last_seen = now() where id = uid;
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

-- ---------- friends and private messages ----------
create table if not exists public.friends (
  user_id uuid not null references auth.users (id) on delete cascade,
  friend_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, friend_id)
);
create table if not exists public.pms (
  id bigserial primary key,
  from_id uuid not null references auth.users (id) on delete cascade,
  to_id uuid not null references auth.users (id) on delete cascade,
  from_name text not null,
  to_name text not null,
  body text not null check (char_length(body) between 1 and 200),
  created_at timestamptz not null default now()
);
create index if not exists pms_to on public.pms (to_id, created_at desc);
create index if not exists pms_from on public.pms (from_id, created_at desc);
alter table public.friends enable row level security;
alter table public.pms enable row level security;
drop policy if exists "own friends" on public.friends;
create policy "own friends" on public.friends for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists "own messages" on public.pms;
create policy "own messages" on public.pms for select to authenticated using ((select auth.uid()) = from_id or (select auth.uid()) = to_id);
revoke insert, update, delete on public.friends, public.pms from anon, authenticated;

create or replace function public.friend_add(p_name text) returns jsonb
language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); f profiles;
begin
  if uid is null then return jsonb_build_object('ok', false, 'reason', 'Sign in first'); end if;
  select * into f from profiles where lower(name) = lower(trim(p_name));
  if f.id is null or f.banned then return jsonb_build_object('ok', false, 'reason', 'No hero with that name'); end if;
  if f.id = uid then return jsonb_build_object('ok', false, 'reason', 'That is you!'); end if;
  if (select count(*) from friends where user_id = uid) >= 100 then return jsonb_build_object('ok', false, 'reason', 'Your friends list is full'); end if;
  insert into friends (user_id, friend_id) values (uid, f.id) on conflict do nothing;
  return jsonb_build_object('ok', true, 'name', f.name);
end $$;

create or replace function public.friend_remove(p_id uuid) returns jsonb
language sql security definer set search_path = public as $$
  with d as (delete from friends where user_id = auth.uid() and friend_id = p_id returning 1)
  select jsonb_build_object('ok', true)
$$;

create or replace function public.friends_list() returns jsonb
language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(x order by x.online desc, x.name), '[]') from (
    select p.id, p.name, p.rating, coalesce(h.combat, 3) as combat, coalesce(h.total_level, 0) as total_level,
           coalesce(p.last_seen > now() - interval '3 minutes', false) as online
    from friends f join profiles p on p.id = f.friend_id left join hiscores h on h.user_id = p.id
    where f.user_id = auth.uid() and not p.banned) x
$$;

create or replace function public.pm_send(p_to uuid, p_body text) returns jsonb
language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); me profiles; t profiles; b text;
begin
  if uid is null then return jsonb_build_object('ok', false, 'reason', 'Sign in first'); end if;
  select * into me from profiles where id = uid;
  select * into t from profiles where id = p_to;
  if me.id is null or me.banned or me.muted then return jsonb_build_object('ok', false, 'reason', 'You cannot send messages'); end if;
  if t.id is null or t.banned or t.id = uid then return jsonb_build_object('ok', false, 'reason', 'That player is gone'); end if;
  b := left(trim(regexp_replace(coalesce(p_body, ''), '[[:cntrl:]]', '', 'g')), 200);
  if b = '' then return jsonb_build_object('ok', false, 'reason', 'Empty message'); end if;
  if exists (select 1 from pms where from_id = uid and created_at > now() - interval '2 seconds')
     or (select count(*) from pms where from_id = uid and created_at > now() - interval '1 minute') >= 20 then
    return jsonb_build_object('ok', false, 'reason', 'Slow down a little');
  end if;
  insert into pms (from_id, to_id, from_name, to_name, body) values (uid, t.id, me.name, t.name, b);
  return jsonb_build_object('ok', true);
end $$;

do $$ begin
  alter publication supabase_realtime add table public.pms;
exception when others then null;
end $$;

-- ---------- password recovery codes (the game has no email) ----------
create table if not exists public.recovery (
  user_id uuid primary key references auth.users (id) on delete cascade,
  code_hash text not null,
  created_at timestamptz not null default now()
);
create table if not exists public.reset_attempts (id bigserial primary key, name text not null, created_at timestamptz not null default now());
alter table public.recovery enable row level security;
alter table public.reset_attempts enable row level security;
revoke all on public.recovery, public.reset_attempts from anon, authenticated;

-- a new one-time code; only its hash is stored, the player writes the code down
create or replace function public.set_recovery() returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare uid uuid := auth.uid(); abc constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; raw bytea := gen_random_bytes(12); code text := ''; i int;
begin
  if uid is null then return jsonb_build_object('ok', false, 'reason', 'Sign in first'); end if;
  for i in 0..11 loop code := code || substr(abc, get_byte(raw, i) % 32 + 1, 1); end loop;
  insert into recovery (user_id, code_hash) values (uid, crypt(code, gen_salt('bf')))
    on conflict (user_id) do update set code_hash = excluded.code_hash, created_at = now();
  return jsonb_build_object('ok', true, 'code', substr(code, 1, 4) || '-' || substr(code, 5, 4) || '-' || substr(code, 9, 4));
end $$;

create or replace function public.reset_password(p_name text, p_code text, p_password text) returns jsonb
language plpgsql security definer set search_path = public, extensions as $$
declare p profiles; r recovery; c text := upper(regexp_replace(coalesce(p_code, ''), '[^A-Za-z0-9]', '', 'g'));
begin
  if (select count(*) from reset_attempts where name = lower(trim(p_name)) and created_at > now() - interval '1 hour') >= 5
     or (select count(*) from reset_attempts where created_at > now() - interval '1 minute') >= 30 then
    return jsonb_build_object('ok', false, 'reason', 'Too many tries – wait an hour');
  end if;
  insert into reset_attempts (name) values (lower(trim(p_name)));
  if char_length(coalesce(p_password, '')) < 8 then return jsonb_build_object('ok', false, 'reason', 'Use a password of at least 8 characters'); end if;
  select * into p from profiles where lower(name) = lower(trim(p_name));
  if p.id is not null then select * into r from recovery where user_id = p.id; end if;
  if p.id is null or r.user_id is null or crypt(c, r.code_hash) <> r.code_hash then
    return jsonb_build_object('ok', false, 'reason', 'Wrong name or recovery code');
  end if;
  update auth.users set encrypted_password = crypt(p_password, gen_salt('bf')), updated_at = now() where id = p.id;
  delete from recovery where user_id = p.id;   -- each code works once
  return jsonb_build_object('ok', true);
end $$;

-- only the game functions can be called from the browser, and only when signed in
revoke execute on function public.level_from_xp(numeric), public.net_worth(jsonb), public.total_xp(jsonb),
  public.update_hiscore(uuid, jsonb), public.claim_name(text), public.sync_save(jsonb), public.fighter(jsonb),
  public.pvp_targets(), public.pvp_attack(uuid), public.save_problems(profiles, saves, jsonb), public.store_save(uuid, jsonb),
  public.ge_check(jsonb), public.ge_give(uuid, text, numeric), public.ge_place(jsonb, text, text, int, bigint), public.ge_cancel(bigint),
  public.ge_collect_all(jsonb), public.chat_send(text), public.friend_add(text), public.friend_remove(uuid), public.friends_list(),
  public.pm_send(uuid, text), public.set_recovery(), public.reset_password(text, text, text) from public, anon, authenticated;
grant execute on function public.claim_name(text), public.sync_save(jsonb), public.pvp_targets(), public.pvp_attack(uuid),
  public.ge_place(jsonb, text, text, int, bigint), public.ge_cancel(bigint), public.ge_collect_all(jsonb), public.chat_send(text),
  public.friend_add(text), public.friend_remove(uuid), public.friends_list(), public.pm_send(uuid, text), public.set_recovery() to authenticated;
grant execute on function public.reset_password(text, text, text) to anon, authenticated;
grant execute on function public.is_banned(uuid) to anon, authenticated;
