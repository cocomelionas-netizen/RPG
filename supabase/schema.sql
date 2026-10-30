-- Endless Road online: accounts, validated cloud saves and hiscores.
-- Paste this whole file into Supabase -> SQL Editor -> Run. Running it again is safe.
--
-- Security model:
--  * Every table has Row Level Security. Players can read only their own save; profiles and hiscores are public.
--  * There are no insert/update/delete policies at all: the browser cannot write any table directly.
--    All writes go through the SECURITY DEFINER functions below, which check the data first.
--  * sync_save compares each upload with the last accepted one, using the server clock, and rejects
--    progress that is faster than the game allows (XP per skill, total XP, wealth, kills). Rejections are
--    logged in cheat_flags and the player gets the last good save back.

-- ---------- game data the checks need (generated from index.html) ----------
create table if not exists public.item_values (id text primary key, value bigint not null);
create table if not exists public.xp_table (lvl int primary key, xp bigint not null);
alter table public.item_values enable row level security;
alter table public.xp_table enable row level security;
insert into public.item_values (id, value) values
  ('2h0', 27),
  ('2h1', 51),
  ('2h2', 70),
  ('2h3', 121),
  ('2h4', 148),
  ('2h5', 199),
  ('abyssring', 8000),
  ('amu_acc', 200),
  ('amu_def', 300),
  ('amu_fury', 3000),
  ('amu_slayer', 300),
  ('amu_str', 400),
  ('armor0', 43),
  ('armor1', 82),
  ('armor2', 115),
  ('armor3', 199),
  ('armor4', 245),
  ('armor5', 329),
  ('armor6', 1400),
  ('arrow0', 1),
  ('arrow1', 2),
  ('arrow2', 3),
  ('arrow3', 5),
  ('arrow4', 8),
  ('arrow5', 14),
  ('bar0', 8),
  ('bar1', 12),
  ('bar2', 30),
  ('bar3', 60),
  ('bar4', 120),
  ('bar5', 260),
  ('bigbones', 10),
  ('bogring', 1200),
  ('bonering', 1200),
  ('bones', 3),
  ('boots0', 30),
  ('bow0', 10),
  ('bow1', 25),
  ('bow2', 50),
  ('bow3', 100),
  ('bow4', 200),
  ('bracelet', 3000),
  ('bread', 2),
  ('bstaff_air', 400),
  ('bstaff_earth', 400),
  ('bstaff_fire', 400),
  ('bstaff_water', 400),
  ('burnt', 1),
  ('cape0', 40),
  ('cbow', 2500),
  ('chainbody0', 27),
  ('chainbody1', 51),
  ('chainbody2', 70),
  ('chainbody3', 121),
  ('chainbody4', 148),
  ('chainbody5', 199),
  ('cooked0', 5),
  ('cooked1', 12),
  ('cooked2', 25),
  ('cooked3', 50),
  ('cooked4', 100),
  ('craw', 15000),
  ('crystalgloves', 3000),
  ('dagger0', 12),
  ('dagger1', 20),
  ('dagger2', 26),
  ('dagger3', 43),
  ('dagger4', 52),
  ('dagger5', 69),
  ('dboots', 4000),
  ('dragonbones', 60),
  ('emblem', 5000),
  ('essence', 2),
  ('ether', 10),
  ('firecape', 6000),
  ('fish0', 2),
  ('fish1', 5),
  ('fish2', 10),
  ('fish3', 20),
  ('fish4', 40),
  ('frostcape', 2000),
  ('fullhelm0', 20),
  ('fullhelm1', 35),
  ('fullhelm2', 48),
  ('fullhelm3', 82),
  ('fullhelm4', 100),
  ('fullhelm5', 134),
  ('gem', 150),
  ('gloves0', 30),
  ('gobboots', 600),
  ('kiteshield0', 27),
  ('kiteshield1', 51),
  ('kiteshield2', 70),
  ('kiteshield3', 121),
  ('kiteshield4', 148),
  ('kiteshield5', 199),
  ('lbow0', 15),
  ('lbow1', 35),
  ('lbow2', 70),
  ('lbow3', 140),
  ('lbow4', 280),
  ('log0', 2),
  ('log1', 5),
  ('log2', 10),
  ('log3', 20),
  ('log4', 40),
  ('medhelm0', 12),
  ('medhelm1', 20),
  ('medhelm2', 26),
  ('medhelm3', 43),
  ('medhelm4', 52),
  ('medhelm5', 69),
  ('mstaff_air', 1500),
  ('mstaff_earth', 1500),
  ('mstaff_fire', 1500),
  ('mstaff_water', 1500),
  ('ore_adamantite', 55),
  ('ore_coal', 10),
  ('ore_copper', 3),
  ('ore_iron', 7),
  ('ore_mithril', 30),
  ('ore_runite', 110),
  ('ore_tin', 3),
  ('platelegs0', 27),
  ('platelegs1', 51),
  ('platelegs2', 70),
  ('platelegs3', 121),
  ('platelegs4', 148),
  ('platelegs5', 199),
  ('r_air', 2),
  ('r_blood', 20),
  ('r_chaos', 8),
  ('r_death', 15),
  ('r_earth', 3),
  ('r_fire', 4),
  ('r_mind', 3),
  ('r_water', 3),
  ('scale', 600),
  ('scimitar0', 20),
  ('scimitar1', 35),
  ('scimitar2', 48),
  ('scimitar3', 82),
  ('scimitar4', 100),
  ('scimitar5', 134),
  ('slimegloves', 300),
  ('sstaff', 2500),
  ('staff0', 12),
  ('staff1', 30),
  ('staff2', 60),
  ('staff3', 120),
  ('staff4', 240),
  ('statuette', 40000),
  ('sword0', 12),
  ('sword1', 20),
  ('sword2', 26),
  ('sword3', 43),
  ('sword4', 52),
  ('sword5', 69),
  ('sword6', 900),
  ('thammaron', 15000),
  ('tips0', 12),
  ('tips1', 20),
  ('tips2', 26),
  ('tips3', 43),
  ('tips4', 52),
  ('tips5', 69),
  ('totem', 12000),
  ('viggora', 15000),
  ('whip', 2500)
on conflict (id) do update set value = excluded.value;
insert into public.xp_table (lvl, xp) values
  (1, 0),
  (2, 83),
  (3, 174),
  (4, 276),
  (5, 388),
  (6, 512),
  (7, 650),
  (8, 801),
  (9, 969),
  (10, 1154),
  (11, 1358),
  (12, 1584),
  (13, 1833),
  (14, 2107),
  (15, 2411),
  (16, 2746),
  (17, 3115),
  (18, 3523),
  (19, 3973),
  (20, 4470),
  (21, 5018),
  (22, 5624),
  (23, 6291),
  (24, 7028),
  (25, 7842),
  (26, 8740),
  (27, 9730),
  (28, 10824),
  (29, 12031),
  (30, 13363),
  (31, 14833),
  (32, 16456),
  (33, 18247),
  (34, 20224),
  (35, 22406),
  (36, 24815),
  (37, 27473),
  (38, 30408),
  (39, 33648),
  (40, 37224),
  (41, 41171),
  (42, 45529),
  (43, 50339),
  (44, 55649),
  (45, 61512),
  (46, 67983),
  (47, 75127),
  (48, 83014),
  (49, 91721),
  (50, 101333),
  (51, 111945),
  (52, 123660),
  (53, 136594),
  (54, 150872),
  (55, 166636),
  (56, 184040),
  (57, 203254),
  (58, 224466),
  (59, 247886),
  (60, 273742),
  (61, 302288),
  (62, 333804),
  (63, 368599),
  (64, 407015),
  (65, 449428),
  (66, 496254),
  (67, 547953),
  (68, 605032),
  (69, 668051),
  (70, 737627),
  (71, 814445),
  (72, 899257),
  (73, 992895),
  (74, 1096278),
  (75, 1210421),
  (76, 1336443),
  (77, 1475581),
  (78, 1629200),
  (79, 1798808),
  (80, 1986068),
  (81, 2192818),
  (82, 2421087),
  (83, 2673114),
  (84, 2951373),
  (85, 3258594),
  (86, 3597792),
  (87, 3972294),
  (88, 4385776),
  (89, 4842295),
  (90, 5346332),
  (91, 5902831),
  (92, 6517253),
  (93, 7195629),
  (94, 7944614),
  (95, 8771558),
  (96, 9684577),
  (97, 10692629),
  (98, 11805606),
  (99, 13034431)
on conflict (lvl) do update set xp = excluded.xp;

-- ---------- tables ----------
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  name text not null check (name ~ '^[A-Za-z0-9][A-Za-z0-9 _-]{1,10}[A-Za-z0-9]$'),
  imported boolean not null default false,   -- first upload already had progress made offline
  banned boolean not null default false,
  flags int not null default 0,
  created_at timestamptz not null default now()
);
create unique index if not exists profiles_name_key on public.profiles (lower(name));

create table if not exists public.saves (
  user_id uuid primary key references auth.users (id) on delete cascade,
  data jsonb not null,
  updated_at timestamptz not null default now(),
  syncs int not null default 0
);

create table if not exists public.hiscores (
  user_id uuid primary key references auth.users (id) on delete cascade,
  name text not null,
  total_level int not null default 0,
  total_xp bigint not null default 0,
  combat int not null default 3,
  skills jsonb not null default '{}',
  kills bigint not null default 0,
  bosses int not null default 0,
  pks int not null default 0,
  imported boolean not null default false,
  updated_at timestamptz not null default now()
);
create index if not exists hiscores_total on public.hiscores (total_level desc, total_xp desc);

create table if not exists public.cheat_flags (
  id bigserial primary key,
  user_id uuid references auth.users (id) on delete cascade,
  reason text not null,
  detail jsonb,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.saves enable row level security;
alter table public.hiscores enable row level security;
alter table public.cheat_flags enable row level security;

drop policy if exists "profiles are public" on public.profiles;
create policy "profiles are public" on public.profiles for select using (true);
drop policy if exists "read own save" on public.saves;
create policy "read own save" on public.saves for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists "hiscores are public" on public.hiscores;
create policy "hiscores are public" on public.hiscores for select
  using (not exists (select 1 from public.profiles p where p.id = hiscores.user_id and p.banned));
-- cheat_flags, item_values and xp_table have no policies: only the functions below can use them

revoke insert, update, delete on public.profiles, public.saves, public.hiscores from anon, authenticated;
revoke all on public.cheat_flags, public.item_values, public.xp_table from anon, authenticated;

-- ---------- helpers ----------
create or replace function public.level_from_xp(x numeric) returns int
language sql stable set search_path = public as $$
  select coalesce(max(lvl), 1) from xp_table where xp <= x
$$;

-- gold + everything owned, valued at the shop price
create or replace function public.net_worth(d jsonb) returns numeric
language sql stable set search_path = public as $$
  select coalesce((d ->> 'gold')::numeric, 0)
    + coalesce((select sum(v.value * e.value::numeric) from jsonb_each_text(coalesce(d -> 'inv', '{}')) e join item_values v on v.id = e.key), 0)
    + coalesce((select sum(v.value) from jsonb_each_text(coalesce(d -> 'equip', '{}')) e join item_values v on v.id = e.value), 0)
    + coalesce((d -> 'wild' ->> 'gold')::numeric, 0)
    + coalesce((select sum(v.value * e.value::numeric) from jsonb_each_text(coalesce(d -> 'wild' -> 'loot', '{}')) e join item_values v on v.id = e.key), 0)
$$;

create or replace function public.total_xp(d jsonb) returns numeric
language sql stable set search_path = public as $$
  select coalesce(sum(e.value::numeric), 0) from jsonb_each_text(coalesce(d -> 'skills', '{}')) e
$$;

create or replace function public.update_hiscore(uid uuid, d jsonb) returns void
language plpgsql security definer set search_path = public as $$
declare
  tl int := 0; tx numeric := 0; k text; x numeric; lv jsonb := '{}';
  cmb int; bosses int;
begin
  for k, x in select key, value::numeric from jsonb_each_text(coalesce(d -> 'skills', '{}')) loop
    tl := tl + level_from_xp(x); tx := tx + x; lv := lv || jsonb_build_object(k, level_from_xp(x));
  end loop;
  cmb := floor((greatest((coalesce((lv ->> 'attack')::int, 1) + coalesce((lv ->> 'strength')::int, 1)) / 2.0,
                         coalesce((lv ->> 'ranged')::int, 1), coalesce((lv ->> 'magic')::int, 1))
                + coalesce((lv ->> 'defence')::int, 1) + coalesce((lv ->> 'hitpoints')::int, 1)) / 3);
  select count(*) into bosses from jsonb_each_text(coalesce(d -> 'kc', '{}')) e
    where e.key = any (array['kingslime','gobchief','bonelord','frosttroll','dragon','bogmother','warden','overlord']) and e.value::numeric > 0;
  insert into hiscores (user_id, name, total_level, total_xp, combat, skills, kills, bosses, pks, imported, updated_at)
  select uid, p.name, tl, tx, cmb, coalesce(d -> 'skills', '{}'), coalesce((d ->> 'kills')::numeric, 0), bosses,
         coalesce((d -> 'wild' ->> 'pks')::int, 0), p.imported, now()
  from profiles p where p.id = uid
  on conflict (user_id) do update set name = excluded.name, total_level = excluded.total_level, total_xp = excluded.total_xp,
    combat = excluded.combat, skills = excluded.skills, kills = excluded.kills, bosses = excluded.bosses, pks = excluded.pks,
    imported = excluded.imported, updated_at = now();
end $$;

-- ---------- functions the game calls ----------
create or replace function public.claim_name(p_name text) returns jsonb
language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); cur text;
begin
  if uid is null then return jsonb_build_object('ok', false, 'reason', 'Not signed in'); end if;
  select name into cur from profiles where id = uid;
  if cur is not null then return jsonb_build_object('ok', true, 'name', cur); end if;
  if exists (select 1 from profiles where lower(name) = lower(trim(p_name))) then
    return jsonb_build_object('ok', false, 'reason', 'That name is taken');
  end if;
  insert into profiles (id, name) values (uid, trim(p_name));
  return jsonb_build_object('ok', true, 'name', trim(p_name));
exception
  when check_violation then return jsonb_build_object('ok', false, 'reason', 'Names are 3-12 letters, numbers, spaces, - or _');
  when unique_violation then return jsonb_build_object('ok', false, 'reason', 'That name is taken');
end $$;

create or replace function public.sync_save(p_data jsonb) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid();
  prof profiles; old saves;
  el numeric; journey boolean; k text; gain numeric; total numeric := 0;
  reasons text[] := '{}';
  -- limits, well above anything the game can reach legitimately
  xp_rate constant numeric := 600;      -- XP per second in one skill
  xp_total_rate constant numeric := 1000; -- XP per second over all skills
  xp_grace constant numeric := 30000;   -- quest rewards and lamps land in one go
  gold_rate constant numeric := 600;    -- wealth per second
  gold_grace constant numeric := 150000;
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

  el := extract(epoch from now() - old.updated_at);
  if el < 5 then return jsonb_build_object('ok', false, 'reason', 'too_fast'); end if;
  el := least(el, 86400) + 30;
  journey := coalesce((p_data ->> 'journeys')::int, 0) = coalesce((old.data ->> 'journeys')::int, 0) + 1;

  -- another device (or an old tab) sending older progress: hand it the newer save
  if not journey and coalesce((p_data ->> 'kills')::numeric, 0) < coalesce((old.data ->> 'kills')::numeric, 0) then
    return jsonb_build_object('ok', false, 'reason', 'stale', 'data', old.data);
  end if;

  for k in select jsonb_object_keys(p_data -> 'skills') loop
    gain := coalesce((p_data -> 'skills' ->> k)::numeric, 0)
          - case when journey then 0 else coalesce((old.data -> 'skills' ->> k)::numeric, 0) end;
    if gain < -1 then return jsonb_build_object('ok', false, 'reason', 'stale', 'data', old.data); end if;
    if gain > el * xp_rate + xp_grace then reasons := reasons || format('%s +%s XP in %s s', k, round(gain), round(el)); end if;
    total := total + greatest(gain, 0);
  end loop;
  if total > el * xp_total_rate + xp_grace then reasons := reasons || format('total +%s XP in %s s', round(total), round(el)); end if;

  gain := net_worth(p_data) - case when journey then 0 else net_worth(old.data) end;
  if gain > el * gold_rate + gold_grace then reasons := reasons || format('wealth +%s in %s s', round(gain), round(el)); end if;

  -- kills are lifetime and survive a New Journey
  gain := coalesce((p_data ->> 'kills')::numeric, 0) - coalesce((old.data ->> 'kills')::numeric, 0);
  if gain > el / 0.8 + 10 then reasons := reasons || format('kills +%s in %s s', round(gain), round(el)); end if;

  if array_length(reasons, 1) > 0 then
    insert into cheat_flags (user_id, reason, detail) values (uid, array_to_string(reasons, '; '), jsonb_build_object('elapsed', round(el)));
    update profiles set flags = flags + 1 where id = uid;
    return jsonb_build_object('ok', false, 'reason', 'rejected', 'detail', array_to_string(reasons, '; '), 'data', old.data);
  end if;

  update saves set data = p_data, updated_at = now(), syncs = syncs + 1 where user_id = uid;
  perform update_hiscore(uid, p_data);
  return jsonb_build_object('ok', true);
exception when others then
  return jsonb_build_object('ok', false, 'reason', 'invalid');
end $$;

-- only the two game functions can be called from the browser, and only when signed in
revoke execute on function public.level_from_xp(numeric), public.net_worth(jsonb), public.total_xp(jsonb),
  public.update_hiscore(uuid, jsonb), public.claim_name(text), public.sync_save(jsonb) from public, anon, authenticated;
grant execute on function public.claim_name(text), public.sync_save(jsonb) to authenticated;
