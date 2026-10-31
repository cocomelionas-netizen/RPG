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
  ('2h0', 26),
  ('2h1', 40),
  ('2h2', 99),
  ('2h3', 198),
  ('2h4', 396),
  ('2h5', 858),
  ('abyssring', 8000),
  ('amu_acc', 200),
  ('amu_def', 300),
  ('amu_fury', 3000),
  ('amu_slayer', 300),
  ('amu_str', 400),
  ('armor0', 44),
  ('armor1', 66),
  ('armor2', 165),
  ('armor3', 330),
  ('armor4', 660),
  ('armor5', 1430),
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
  ('bstaff_air', 200),
  ('bstaff_earth', 200),
  ('bstaff_fire', 200),
  ('bstaff_water', 200),
  ('burnt', 1),
  ('bwhat', 400),
  ('cape0', 40),
  ('cbow', 2500),
  ('chainbody0', 26),
  ('chainbody1', 40),
  ('chainbody2', 99),
  ('chainbody3', 198),
  ('chainbody4', 396),
  ('chainbody5', 858),
  ('charm_blue', 35),
  ('charm_crimson', 20),
  ('charm_gold', 4),
  ('charm_green', 10),
  ('clue_easy', 10),
  ('clue_elite', 100),
  ('clue_hard', 50),
  ('clue_medium', 25),
  ('cooked0', 5),
  ('cooked1', 12),
  ('cooked2', 25),
  ('cooked3', 50),
  ('cooked4', 100),
  ('craw', 15000),
  ('crop_cabbage', 5),
  ('crop_onion', 4),
  ('crop_potato', 2),
  ('crop_snape', 23),
  ('crop_strawberry', 14),
  ('crop_sweetcorn', 11),
  ('crop_tomato', 7),
  ('crop_watermelon', 20),
  ('crystalgloves', 3000),
  ('dagger0', 9),
  ('dagger1', 13),
  ('dagger2', 33),
  ('dagger3', 66),
  ('dagger4', 132),
  ('dagger5', 286),
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
  ('flared', 400),
  ('frostcape', 2000),
  ('fullhelm0', 18),
  ('fullhelm1', 26),
  ('fullhelm2', 66),
  ('fullhelm3', 132),
  ('fullhelm4', 264),
  ('fullhelm5', 572),
  ('gem', 150),
  ('gloves0', 30),
  ('gnomescarf', 1500),
  ('gobboots', 600),
  ('gplate', 6000),
  ('grace_body', 165),
  ('grace_cape', 120),
  ('grace_feet', 120),
  ('grace_hands', 90),
  ('grace_helm', 105),
  ('grace_legs', 150),
  ('gshield', 6000),
  ('herb_cadantine', 100),
  ('herb_dwarfweed', 117),
  ('herb_guam', 10),
  ('herb_harralander', 35),
  ('herb_irit', 68),
  ('herb_kwuarm', 84),
  ('herb_marrentill', 17),
  ('herb_ranarr', 51),
  ('herb_snapdragon', 93),
  ('herb_tarromin', 24),
  ('herb_torstol', 125),
  ('hsandals', 1500),
  ('hwmask', 400),
  ('kiteshield0', 26),
  ('kiteshield1', 40),
  ('kiteshield2', 99),
  ('kiteshield3', 198),
  ('kiteshield4', 396),
  ('kiteshield5', 858),
  ('lamp', 0),
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
  ('mark', 0),
  ('medhelm0', 9),
  ('medhelm1', 13),
  ('medhelm2', 33),
  ('medhelm3', 66),
  ('medhelm4', 132),
  ('medhelm5', 286),
  ('mstaff_air', 700),
  ('mstaff_earth', 700),
  ('mstaff_fire', 700),
  ('mstaff_water', 700),
  ('nails', 1),
  ('ore_adamantite', 55),
  ('ore_coal', 10),
  ('ore_copper', 3),
  ('ore_iron', 7),
  ('ore_mithril', 30),
  ('ore_runite', 110),
  ('ore_tin', 3),
  ('pirhat', 6000),
  ('plank0', 5),
  ('plank1', 10),
  ('plank2', 17),
  ('plank3', 32),
  ('plank4', 62),
  ('platelegs0', 26),
  ('platelegs1', 40),
  ('platelegs2', 99),
  ('platelegs3', 198),
  ('platelegs4', 396),
  ('platelegs5', 858),
  ('pot_agi', 132),
  ('pot_att', 22),
  ('pot_craft', 108),
  ('pot_def', 32),
  ('pot_gather', 60),
  ('pot_luck', 183),
  ('pot_pray', 84),
  ('pot_str', 43),
  ('pot_super', 197),
  ('pot_ward', 915),
  ('pot_wis', 321),
  ('pouch_beaver', 39),
  ('pouch_firetitan', 155),
  ('pouch_golem', 70),
  ('pouch_ibis', 57),
  ('pouch_magpie', 111),
  ('pouch_sdragon', 788),
  ('pouch_steeltitan', 290),
  ('pouch_terror', 95),
  ('pouch_unicorn', 253),
  ('pouch_wolf', 24),
  ('pouch_yak', 175),
  ('r_air', 2),
  ('r_blood', 20),
  ('r_chaos', 6),
  ('r_death', 15),
  ('r_earth', 3),
  ('r_fire', 4),
  ('r_mind', 3),
  ('r_water', 3),
  ('rboots', 1500),
  ('rhood', 6000),
  ('sapling_magic', 1500),
  ('sapling_maple', 200),
  ('sapling_oak', 60),
  ('sapling_yew', 600),
  ('scale', 600),
  ('scimitar0', 18),
  ('scimitar1', 26),
  ('scimitar2', 66),
  ('scimitar3', 132),
  ('scimitar4', 264),
  ('scimitar5', 572),
  ('seed_cabbage', 7),
  ('seed_cadantine', 64),
  ('seed_dwarfweed', 75),
  ('seed_guam', 7),
  ('seed_harralander', 23),
  ('seed_irit', 44),
  ('seed_kwuarm', 54),
  ('seed_marrentill', 11),
  ('seed_onion', 5),
  ('seed_potato', 3),
  ('seed_ranarr', 33),
  ('seed_snapdragon', 60),
  ('seed_snape', 33),
  ('seed_strawberry', 20),
  ('seed_sweetcorn', 15),
  ('seed_tarromin', 16),
  ('seed_tomato', 10),
  ('seed_torstol', 81),
  ('seed_watermelon', 27),
  ('shard', 3),
  ('slimegloves', 300),
  ('sstaff', 2500),
  ('staff0', 12),
  ('staff1', 30),
  ('staff2', 60),
  ('staff3', 120),
  ('staff4', 240),
  ('statuette', 40000),
  ('sword0', 9),
  ('sword1', 13),
  ('sword2', 33),
  ('sword3', 66),
  ('sword4', 132),
  ('sword5', 286),
  ('sword6', 900),
  ('tagbow', 20000),
  ('tagcloak', 20000),
  ('tagplate', 20000),
  ('tagwand', 20000),
  ('tcape', 400),
  ('thammaron', 15000),
  ('tips0', 1),
  ('tips1', 1),
  ('tips2', 2),
  ('tips3', 5),
  ('tips4', 10),
  ('tips5', 21),
  ('totem', 12000),
  ('viggora', 15000),
  ('wboots', 1500),
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
  ('q19', 40000, 0, 0),
  ('q20', 300, 115, 0),
  ('q21', 0, 130, 800),
  ('q22', 1500, 325, 1500)
on conflict (id) do update set gold = excluded.gold, items = excluded.items, xp = excluded.xp;
create table if not exists public.item_stats (
  id text primary key, name text, slot text, wtype text, power numeric not null default 0, armor numeric not null default 0,
  speed numeric, acc numeric not null default 0, dmg numeric not null default 0, dr numeric not null default 0, heal numeric not null default 0
);
alter table public.item_stats enable row level security;
insert into public.item_stats (id, name, slot, wtype, power, armor, speed, acc, dmg, dr, heal) values
  ('2h0', 'Bronze 2h Sword', 'weapon', 'melee', 5, 0, '2.6', 0, 0, 0, 0),
  ('2h1', 'Iron 2h Sword', 'weapon', 'melee', 11, 0, '2.6', 0, 0, 0, 0),
  ('2h2', 'Steel 2h Sword', 'weapon', 'melee', 18, 0, '2.6', 0, 0, 0, 0),
  ('2h3', 'Mithril 2h Sword', 'weapon', 'melee', 27, 0, '2.6', 0, 0, 0, 0),
  ('2h4', 'Adamant 2h Sword', 'weapon', 'melee', 38, 0, '2.6', 0, 0, 0, 0),
  ('2h5', 'Rune 2h Sword', 'weapon', 'melee', 50, 0, '2.6', 0, 0, 0, 0),
  ('abyssring', 'Ring of the Abyss', 'ring', null, 0, 0, null, 0.03, 0.06, 0, 0),
  ('amu_acc', 'Amulet of Accuracy', 'amulet', null, 0, 0, null, 0.06, 0, 0, 0),
  ('amu_def', 'Amulet of Warding', 'amulet', null, 0, 0, null, 0, 0, 0.05, 0),
  ('amu_fury', 'Amulet of Fury', 'amulet', null, 0, 0, null, 0.06, 0.1, 0.05, 0),
  ('amu_slayer', 'Slayer Amulet', 'amulet', null, 0, 0, null, 0, 0, 0, 0),
  ('amu_str', 'Amulet of Strength', 'amulet', null, 0, 0, null, 0, 0.1, 0, 0),
  ('armor0', 'Bronze Platebody', 'body', null, 0, 1, null, 0, 0, 0, 0),
  ('armor1', 'Iron Platebody', 'body', null, 0, 2, null, 0, 0, 0, 0),
  ('armor2', 'Steel Platebody', 'body', null, 0, 4, null, 0, 0, 0, 0),
  ('armor3', 'Mithril Platebody', 'body', null, 0, 6, null, 0, 0, 0, 0),
  ('armor4', 'Adamant Platebody', 'body', null, 0, 8, null, 0, 0, 0, 0),
  ('armor5', 'Rune Platebody', 'body', null, 0, 11, null, 0, 0, 0, 0),
  ('armor6', 'Dragon Platebody', 'body', null, 0, 18, null, 0, 0, 0, 0),
  ('arrow0', 'Bronze Arrows', null, null, 1, 0, null, 0, 0, 0, 0),
  ('arrow1', 'Iron Arrows', null, null, 3, 0, null, 0, 0, 0, 0),
  ('arrow2', 'Steel Arrows', null, null, 5, 0, null, 0, 0, 0, 0),
  ('arrow3', 'Mithril Arrows', null, null, 8, 0, null, 0, 0, 0, 0),
  ('arrow4', 'Adamant Arrows', null, null, 12, 0, null, 0, 0, 0, 0),
  ('arrow5', 'Rune Arrows', null, null, 16, 0, null, 0, 0, 0, 0),
  ('bar0', 'Bronze Bar', null, null, 0, 0, null, 0, 0, 0, 0),
  ('bar1', 'Iron Bar', null, null, 0, 0, null, 0, 0, 0, 0),
  ('bar2', 'Steel Bar', null, null, 0, 0, null, 0, 0, 0, 0),
  ('bar3', 'Mithril Bar', null, null, 0, 0, null, 0, 0, 0, 0),
  ('bar4', 'Adamant Bar', null, null, 0, 0, null, 0, 0, 0, 0),
  ('bar5', 'Rune Bar', null, null, 0, 0, null, 0, 0, 0, 0),
  ('bigbones', 'Big Bones', null, null, 0, 0, null, 0, 0, 0, 0),
  ('bogring', 'Ring of the Bog', 'ring', null, 0, 0, null, 0, 0, 0, 0),
  ('bonering', 'Ring of the Bone Lord', 'ring', null, 0, 0, null, 0.04, 0, 0, 0),
  ('bones', 'Bones', null, null, 0, 0, null, 0, 0, 0, 0),
  ('boots0', 'Leather Boots', 'feet', null, 0, 1, null, 0, 0, 0, 0),
  ('bow0', 'Birch Shortbow', 'weapon', 'ranged', 3, 0, '1.5', 0, 0, 0, 0),
  ('bow1', 'Oak Shortbow', 'weapon', 'ranged', 7, 0, '1.5', 0, 0, 0, 0),
  ('bow2', 'Maple Shortbow', 'weapon', 'ranged', 12, 0, '1.5', 0, 0, 0, 0),
  ('bow3', 'Yew Shortbow', 'weapon', 'ranged', 18, 0, '1.5', 0, 0, 0, 0),
  ('bow4', 'Magic Shortbow', 'weapon', 'ranged', 26, 0, '1.5', 0, 0, 0, 0),
  ('bracelet', 'Bracelet of Ethereum', 'hands', null, 0, 2, null, 0, 0, 0, 0),
  ('bread', 'Bread', null, null, 0, 0, null, 0, 0, 0, 15),
  ('bstaff_air', 'Air Battlestaff', 'weapon', 'magic', 9, 0, null, 0, 0, 0, 0),
  ('bstaff_earth', 'Earth Battlestaff', 'weapon', 'magic', 9, 0, null, 0, 0, 0, 0),
  ('bstaff_fire', 'Fire Battlestaff', 'weapon', 'magic', 9, 0, null, 0, 0, 0, 0),
  ('bstaff_water', 'Water Battlestaff', 'weapon', 'magic', 9, 0, null, 0, 0, 0, 0),
  ('burnt', 'Burnt Fish', null, null, 0, 0, null, 0, 0, 0, 0),
  ('bwhat', 'Blue Wizard Hat', 'helm', null, 0, 1, null, 0, 0.01, 0, 0),
  ('cape0', 'Red Cape', 'cape', null, 0, 1, null, 0, 0, 0, 0),
  ('cbow', 'Crystal Bow', 'weapon', 'ranged', 36, 0, '1.5', 0, 0, 0, 0),
  ('chainbody0', 'Bronze Chainbody', 'body', null, 0, 1, null, 0, 0, 0, 0),
  ('chainbody1', 'Iron Chainbody', 'body', null, 0, 2, null, 0, 0, 0, 0),
  ('chainbody2', 'Steel Chainbody', 'body', null, 0, 3, null, 0, 0, 0, 0),
  ('chainbody3', 'Mithril Chainbody', 'body', null, 0, 4, null, 0, 0, 0, 0),
  ('chainbody4', 'Adamant Chainbody', 'body', null, 0, 6, null, 0, 0, 0, 0),
  ('chainbody5', 'Rune Chainbody', 'body', null, 0, 8, null, 0, 0, 0, 0),
  ('charm_blue', 'Blue Charm', null, null, 0, 0, null, 0, 0, 0, 0),
  ('charm_crimson', 'Crimson Charm', null, null, 0, 0, null, 0, 0, 0, 0),
  ('charm_gold', 'Gold Charm', null, null, 0, 0, null, 0, 0, 0, 0),
  ('charm_green', 'Green Charm', null, null, 0, 0, null, 0, 0, 0, 0),
  ('clue_easy', 'Clue Scroll (easy)', null, null, 0, 0, null, 0, 0, 0, 0),
  ('clue_elite', 'Clue Scroll (elite)', null, null, 0, 0, null, 0, 0, 0, 0),
  ('clue_hard', 'Clue Scroll (hard)', null, null, 0, 0, null, 0, 0, 0, 0),
  ('clue_medium', 'Clue Scroll (medium)', null, null, 0, 0, null, 0, 0, 0, 0),
  ('cooked0', 'Cooked Roach', null, null, 0, 0, null, 0, 0, 0, 20),
  ('cooked1', 'Cooked Perch', null, null, 0, 0, null, 0, 0, 0, 45),
  ('cooked2', 'Cooked Pike', null, null, 0, 0, null, 0, 0, 0, 80),
  ('cooked3', 'Cooked Salmon', null, null, 0, 0, null, 0, 0, 0, 120),
  ('cooked4', 'Cooked Eel', null, null, 0, 0, null, 0, 0, 0, 170),
  ('craw', 'Craw''s Bow', 'weapon', 'ranged', 30, 0, '1.5', 0, 0, 0, 0),
  ('crop_cabbage', 'Cabbage', null, null, 0, 0, null, 0, 0, 0, 18),
  ('crop_onion', 'Onion', null, null, 0, 0, null, 0, 0, 0, 14),
  ('crop_potato', 'Potato', null, null, 0, 0, null, 0, 0, 0, 10),
  ('crop_snape', 'Snape Grass', null, null, 0, 0, null, 0, 0, 0, 0),
  ('crop_strawberry', 'Strawberry', null, null, 0, 0, null, 0, 0, 0, 50),
  ('crop_sweetcorn', 'Sweetcorn', null, null, 0, 0, null, 0, 0, 0, 35),
  ('crop_tomato', 'Tomato', null, null, 0, 0, null, 0, 0, 0, 25),
  ('crop_watermelon', 'Watermelon', null, null, 0, 0, null, 0, 0, 0, 75),
  ('crystalgloves', 'Crystal Gauntlets', 'hands', null, 0, 6, null, 0.03, 0, 0, 0),
  ('dagger0', 'Bronze Dagger', 'weapon', 'melee', 2, 0, '1.5', 0, 0, 0, 0),
  ('dagger1', 'Iron Dagger', 'weapon', 'melee', 4, 0, '1.5', 0, 0, 0, 0),
  ('dagger2', 'Steel Dagger', 'weapon', 'melee', 7, 0, '1.5', 0, 0, 0, 0),
  ('dagger3', 'Mithril Dagger', 'weapon', 'melee', 11, 0, '1.5', 0, 0, 0, 0),
  ('dagger4', 'Adamant Dagger', 'weapon', 'melee', 15, 0, '1.5', 0, 0, 0, 0),
  ('dagger5', 'Rune Dagger', 'weapon', 'melee', 20, 0, '1.5', 0, 0, 0, 0),
  ('dboots', 'Dragon Boots', 'feet', null, 0, 7, null, 0, 0, 0, 0),
  ('dragonbones', 'Dragon Bones', null, null, 0, 0, null, 0, 0, 0, 0),
  ('emblem', 'Ancient Emblem', null, null, 0, 0, null, 0, 0, 0, 0),
  ('essence', 'Rune Essence', null, null, 0, 0, null, 0, 0, 0, 0),
  ('ether', 'Revenant Ether', null, null, 0, 0, null, 0, 0, 0, 0),
  ('firecape', 'Dragonfire Cape', 'cape', null, 0, 9, null, 0, 0.05, 0, 0),
  ('fish0', 'Raw Roach', null, null, 0, 0, null, 0, 0, 0, 0),
  ('fish1', 'Raw Perch', null, null, 0, 0, null, 0, 0, 0, 0),
  ('fish2', 'Raw Pike', null, null, 0, 0, null, 0, 0, 0, 0),
  ('fish3', 'Raw Salmon', null, null, 0, 0, null, 0, 0, 0, 0),
  ('fish4', 'Raw Eel', null, null, 0, 0, null, 0, 0, 0, 0),
  ('flared', 'Flared Trousers', 'legs', null, 0, 2, null, 0, 0, 0, 0),
  ('frostcape', 'Frost Cape', 'cape', null, 0, 6, null, 0, 0, 0.03, 0),
  ('fullhelm0', 'Bronze Full Helm', 'helm', null, 0, 1, null, 0, 0, 0, 0),
  ('fullhelm1', 'Iron Full Helm', 'helm', null, 0, 1, null, 0, 0, 0, 0),
  ('fullhelm2', 'Steel Full Helm', 'helm', null, 0, 2, null, 0, 0, 0, 0),
  ('fullhelm3', 'Mithril Full Helm', 'helm', null, 0, 3, null, 0, 0, 0, 0),
  ('fullhelm4', 'Adamant Full Helm', 'helm', null, 0, 4, null, 0, 0, 0, 0),
  ('fullhelm5', 'Rune Full Helm', 'helm', null, 0, 5, null, 0, 0, 0, 0),
  ('gem', 'Gem', null, null, 0, 0, null, 0, 0, 0, 0),
  ('gloves0', 'Leather Gloves', 'hands', null, 0, 1, null, 0, 0, 0, 0),
  ('gnomescarf', 'Gnome Scarf', 'cape', null, 0, 1, null, 0, 0, 0, 0),
  ('gobboots', 'Goblin War Boots', 'feet', null, 0, 4, null, 0, 0, 0, 0),
  ('gplate', 'Gilded Platebody', 'body', null, 0, 15, null, 0, 0, 0, 0),
  ('grace_body', 'Graceful Top', 'body', null, 0, 1, null, 0, 0, 0, 0),
  ('grace_cape', 'Graceful Cape', 'cape', null, 0, 1, null, 0, 0, 0, 0),
  ('grace_feet', 'Graceful Boots', 'feet', null, 0, 1, null, 0, 0, 0, 0),
  ('grace_hands', 'Graceful Gloves', 'hands', null, 0, 1, null, 0, 0, 0, 0),
  ('grace_helm', 'Graceful Hood', 'helm', null, 0, 1, null, 0, 0, 0, 0),
  ('grace_legs', 'Graceful Legs', 'legs', null, 0, 1, null, 0, 0, 0, 0),
  ('gshield', 'Gilded Kiteshield', 'shield', null, 0, 7, null, 0, 0, 0, 0),
  ('herb_cadantine', 'Cadantine', null, null, 0, 0, null, 0, 0, 0, 0),
  ('herb_dwarfweed', 'Dwarf Weed', null, null, 0, 0, null, 0, 0, 0, 0),
  ('herb_guam', 'Guam', null, null, 0, 0, null, 0, 0, 0, 0),
  ('herb_harralander', 'Harralander', null, null, 0, 0, null, 0, 0, 0, 0),
  ('herb_irit', 'Irit', null, null, 0, 0, null, 0, 0, 0, 0),
  ('herb_kwuarm', 'Kwuarm', null, null, 0, 0, null, 0, 0, 0, 0),
  ('herb_marrentill', 'Marrentill', null, null, 0, 0, null, 0, 0, 0, 0),
  ('herb_ranarr', 'Ranarr', null, null, 0, 0, null, 0, 0, 0, 0),
  ('herb_snapdragon', 'Snapdragon', null, null, 0, 0, null, 0, 0, 0, 0),
  ('herb_tarromin', 'Tarromin', null, null, 0, 0, null, 0, 0, 0, 0),
  ('herb_torstol', 'Torstol', null, null, 0, 0, null, 0, 0, 0, 0),
  ('hsandals', 'Holy Sandals', 'feet', null, 0, 2, null, 0, 0, 0.02, 0),
  ('hwmask', 'Highwayman Mask', 'helm', null, 0, 2, null, 0.01, 0, 0, 0),
  ('kiteshield0', 'Bronze Kiteshield', 'shield', null, 0, 1, null, 0, 0, 0, 0),
  ('kiteshield1', 'Iron Kiteshield', 'shield', null, 0, 1, null, 0, 0, 0, 0),
  ('kiteshield2', 'Steel Kiteshield', 'shield', null, 0, 2, null, 0, 0, 0, 0),
  ('kiteshield3', 'Mithril Kiteshield', 'shield', null, 0, 3, null, 0, 0, 0, 0),
  ('kiteshield4', 'Adamant Kiteshield', 'shield', null, 0, 4, null, 0, 0, 0, 0),
  ('kiteshield5', 'Rune Kiteshield', 'shield', null, 0, 6, null, 0, 0, 0, 0),
  ('lamp', 'XP Lamp', null, null, 0, 0, null, 0, 0, 0, 0),
  ('lbow0', 'Birch Longbow', 'weapon', 'ranged', 5, 0, '2', 0.12, 0, 0, 0),
  ('lbow1', 'Oak Longbow', 'weapon', 'ranged', 12, 0, '2', 0.12, 0, 0, 0),
  ('lbow2', 'Maple Longbow', 'weapon', 'ranged', 21, 0, '2', 0.12, 0, 0, 0),
  ('lbow3', 'Yew Longbow', 'weapon', 'ranged', 32, 0, '2', 0.12, 0, 0, 0),
  ('lbow4', 'Magic Longbow', 'weapon', 'ranged', 46, 0, '2', 0.12, 0, 0, 0),
  ('log0', 'Birch Logs', null, null, 0, 0, null, 0, 0, 0, 0),
  ('log1', 'Oak Logs', null, null, 0, 0, null, 0, 0, 0, 0),
  ('log2', 'Maple Logs', null, null, 0, 0, null, 0, 0, 0, 0),
  ('log3', 'Yew Logs', null, null, 0, 0, null, 0, 0, 0, 0),
  ('log4', 'Magic Logs', null, null, 0, 0, null, 0, 0, 0, 0),
  ('mark', 'Mark of Grace', null, null, 0, 0, null, 0, 0, 0, 0),
  ('medhelm0', 'Bronze Med Helm', 'helm', null, 0, 1, null, 0, 0, 0, 0),
  ('medhelm1', 'Iron Med Helm', 'helm', null, 0, 1, null, 0, 0, 0, 0),
  ('medhelm2', 'Steel Med Helm', 'helm', null, 0, 1, null, 0, 0, 0, 0),
  ('medhelm3', 'Mithril Med Helm', 'helm', null, 0, 2, null, 0, 0, 0, 0),
  ('medhelm4', 'Adamant Med Helm', 'helm', null, 0, 2, null, 0, 0, 0, 0),
  ('medhelm5', 'Rune Med Helm', 'helm', null, 0, 3, null, 0, 0, 0, 0),
  ('mstaff_air', 'Mystic Air Staff', 'weapon', 'magic', 15, 0, null, 0, 0, 0, 0),
  ('mstaff_earth', 'Mystic Earth Staff', 'weapon', 'magic', 15, 0, null, 0, 0, 0, 0),
  ('mstaff_fire', 'Mystic Fire Staff', 'weapon', 'magic', 15, 0, null, 0, 0, 0, 0),
  ('mstaff_water', 'Mystic Water Staff', 'weapon', 'magic', 15, 0, null, 0, 0, 0, 0),
  ('nails', 'Nails', null, null, 0, 0, null, 0, 0, 0, 0),
  ('ore_adamantite', 'Adamantite Ore', null, null, 0, 0, null, 0, 0, 0, 0),
  ('ore_coal', 'Coal', null, null, 0, 0, null, 0, 0, 0, 0),
  ('ore_copper', 'Copper Ore', null, null, 0, 0, null, 0, 0, 0, 0),
  ('ore_iron', 'Iron Ore', null, null, 0, 0, null, 0, 0, 0, 0),
  ('ore_mithril', 'Mithril Ore', null, null, 0, 0, null, 0, 0, 0, 0),
  ('ore_runite', 'Runite Ore', null, null, 0, 0, null, 0, 0, 0, 0),
  ('ore_tin', 'Tin Ore', null, null, 0, 0, null, 0, 0, 0, 0),
  ('pirhat', 'Pirate Hat', 'helm', null, 0, 3, null, 0, 0.03, 0, 0),
  ('plank0', 'Birch Plank', null, null, 0, 0, null, 0, 0, 0, 0),
  ('plank1', 'Oak Plank', null, null, 0, 0, null, 0, 0, 0, 0),
  ('plank2', 'Maple Plank', null, null, 0, 0, null, 0, 0, 0, 0),
  ('plank3', 'Yew Plank', null, null, 0, 0, null, 0, 0, 0, 0),
  ('plank4', 'Magic Plank', null, null, 0, 0, null, 0, 0, 0, 0),
  ('platelegs0', 'Bronze Platelegs', 'legs', null, 0, 1, null, 0, 0, 0, 0),
  ('platelegs1', 'Iron Platelegs', 'legs', null, 0, 1, null, 0, 0, 0, 0),
  ('platelegs2', 'Steel Platelegs', 'legs', null, 0, 2, null, 0, 0, 0, 0),
  ('platelegs3', 'Mithril Platelegs', 'legs', null, 0, 4, null, 0, 0, 0, 0),
  ('platelegs4', 'Adamant Platelegs', 'legs', null, 0, 5, null, 0, 0, 0, 0),
  ('platelegs5', 'Rune Platelegs', 'legs', null, 0, 7, null, 0, 0, 0, 0),
  ('pot_agi', 'Stamina Potion', null, null, 0, 0, null, 0, 0, 0, 0),
  ('pot_att', 'Attack Potion', null, null, 0, 0, null, 0, 0, 0, 0),
  ('pot_craft', 'Artisan''s Draught', null, null, 0, 0, null, 0, 0, 0, 0),
  ('pot_def', 'Defence Potion', null, null, 0, 0, null, 0, 0, 0, 0),
  ('pot_gather', 'Gatherer''s Brew', null, null, 0, 0, null, 0, 0, 0, 0),
  ('pot_luck', 'Lucky Potion', null, null, 0, 0, null, 0, 0, 0, 0),
  ('pot_pray', 'Prayer Potion', null, null, 0, 0, null, 0, 0, 0, 0),
  ('pot_str', 'Strength Potion', null, null, 0, 0, null, 0, 0, 0, 0),
  ('pot_super', 'Super Combat Potion', null, null, 0, 0, null, 0, 0, 0, 0),
  ('pot_ward', 'Antifire Potion', null, null, 0, 0, null, 0, 0, 0, 0),
  ('pot_wis', 'Wisdom Potion', null, null, 0, 0, null, 0, 0, 0, 0),
  ('pouch_beaver', 'Beaver Pouch', null, null, 0, 0, null, 0, 0, 0, 0),
  ('pouch_firetitan', 'Fire Titan Pouch', null, null, 0, 0, null, 0, 0, 0, 0),
  ('pouch_golem', 'Rock Golem Pouch', null, null, 0, 0, null, 0, 0, 0, 0),
  ('pouch_ibis', 'Ibis Pouch', null, null, 0, 0, null, 0, 0, 0, 0),
  ('pouch_magpie', 'Magpie Pouch', null, null, 0, 0, null, 0, 0, 0, 0),
  ('pouch_sdragon', 'Spirit Dragon Pouch', null, null, 0, 0, null, 0, 0, 0, 0),
  ('pouch_steeltitan', 'Steel Titan Pouch', null, null, 0, 0, null, 0, 0, 0, 0),
  ('pouch_terror', 'Spirit Terrorbird Pouch', null, null, 0, 0, null, 0, 0, 0, 0),
  ('pouch_unicorn', 'Unicorn Stallion Pouch', null, null, 0, 0, null, 0, 0, 0, 0),
  ('pouch_wolf', 'Spirit Wolf Pouch', null, null, 0, 0, null, 0, 0, 0, 0),
  ('pouch_yak', 'Pack Yak Pouch', null, null, 0, 0, null, 0, 0, 0, 0),
  ('r_air', 'Air Rune', null, null, 0, 0, null, 0, 0, 0, 0),
  ('r_blood', 'Blood Rune', null, null, 0, 0, null, 0, 0, 0, 0),
  ('r_chaos', 'Chaos Rune', null, null, 0, 0, null, 0, 0, 0, 0),
  ('r_death', 'Death Rune', null, null, 0, 0, null, 0, 0, 0, 0),
  ('r_earth', 'Earth Rune', null, null, 0, 0, null, 0, 0, 0, 0),
  ('r_fire', 'Fire Rune', null, null, 0, 0, null, 0, 0, 0, 0),
  ('r_mind', 'Mind Rune', null, null, 0, 0, null, 0, 0, 0, 0),
  ('r_water', 'Water Rune', null, null, 0, 0, null, 0, 0, 0, 0),
  ('rboots', 'Ranger Boots', 'feet', null, 0, 2, null, 0.03, 0, 0, 0),
  ('rhood', 'Robin Hood Hat', 'helm', null, 0, 4, null, 0.04, 0, 0, 0),
  ('sapling_magic', 'Magic Sapling', null, null, 0, 0, null, 0, 0, 0, 0),
  ('sapling_maple', 'Maple Sapling', null, null, 0, 0, null, 0, 0, 0, 0),
  ('sapling_oak', 'Oak Sapling', null, null, 0, 0, null, 0, 0, 0, 0),
  ('sapling_yew', 'Yew Sapling', null, null, 0, 0, null, 0, 0, 0, 0),
  ('scale', 'Dragon Scale', null, null, 0, 0, null, 0, 0, 0, 0),
  ('scimitar0', 'Bronze Scimitar', 'weapon', 'melee', 3, 0, '1.8', 0, 0, 0, 0),
  ('scimitar1', 'Iron Scimitar', 'weapon', 'melee', 7, 0, '1.8', 0, 0, 0, 0),
  ('scimitar2', 'Steel Scimitar', 'weapon', 'melee', 12, 0, '1.8', 0, 0, 0, 0),
  ('scimitar3', 'Mithril Scimitar', 'weapon', 'melee', 17, 0, '1.8', 0, 0, 0, 0),
  ('scimitar4', 'Adamant Scimitar', 'weapon', 'melee', 24, 0, '1.8', 0, 0, 0, 0),
  ('scimitar5', 'Rune Scimitar', 'weapon', 'melee', 32, 0, '1.8', 0, 0, 0, 0),
  ('seed_cabbage', 'Cabbage Seed', null, null, 0, 0, null, 0, 0, 0, 0),
  ('seed_cadantine', 'Cadantine Seed', null, null, 0, 0, null, 0, 0, 0, 0),
  ('seed_dwarfweed', 'Dwarf Weed Seed', null, null, 0, 0, null, 0, 0, 0, 0),
  ('seed_guam', 'Guam Seed', null, null, 0, 0, null, 0, 0, 0, 0),
  ('seed_harralander', 'Harralander Seed', null, null, 0, 0, null, 0, 0, 0, 0),
  ('seed_irit', 'Irit Seed', null, null, 0, 0, null, 0, 0, 0, 0),
  ('seed_kwuarm', 'Kwuarm Seed', null, null, 0, 0, null, 0, 0, 0, 0),
  ('seed_marrentill', 'Marrentill Seed', null, null, 0, 0, null, 0, 0, 0, 0),
  ('seed_onion', 'Onion Seed', null, null, 0, 0, null, 0, 0, 0, 0),
  ('seed_potato', 'Potato Seed', null, null, 0, 0, null, 0, 0, 0, 0),
  ('seed_ranarr', 'Ranarr Seed', null, null, 0, 0, null, 0, 0, 0, 0),
  ('seed_snapdragon', 'Snapdragon Seed', null, null, 0, 0, null, 0, 0, 0, 0),
  ('seed_snape', 'Snape Grass Seed', null, null, 0, 0, null, 0, 0, 0, 0),
  ('seed_strawberry', 'Strawberry Seed', null, null, 0, 0, null, 0, 0, 0, 0),
  ('seed_sweetcorn', 'Sweetcorn Seed', null, null, 0, 0, null, 0, 0, 0, 0),
  ('seed_tarromin', 'Tarromin Seed', null, null, 0, 0, null, 0, 0, 0, 0),
  ('seed_tomato', 'Tomato Seed', null, null, 0, 0, null, 0, 0, 0, 0),
  ('seed_torstol', 'Torstol Seed', null, null, 0, 0, null, 0, 0, 0, 0),
  ('seed_watermelon', 'Watermelon Seed', null, null, 0, 0, null, 0, 0, 0, 0),
  ('shard', 'Spirit Shards', null, null, 0, 0, null, 0, 0, 0, 0),
  ('slimegloves', 'Slime Gloves', 'hands', null, 0, 3, null, 0, 0, 0, 0),
  ('sstaff', 'Shadow Staff', 'weapon', 'magic', 28, 0, null, 0, 0, 0, 0),
  ('staff0', 'Apprentice Staff', 'weapon', 'magic', 2, 0, null, 0, 0, 0, 0),
  ('staff1', 'Adept Staff', 'weapon', 'magic', 5, 0, null, 0, 0, 0, 0),
  ('staff2', 'Mystic Staff', 'weapon', 'magic', 9, 0, null, 0, 0, 0, 0),
  ('staff3', 'Master Staff', 'weapon', 'magic', 14, 0, null, 0, 0, 0, 0),
  ('staff4', 'Archmage Staff', 'weapon', 'magic', 20, 0, null, 0, 0, 0, 0),
  ('statuette', 'Ancient Statuette', null, null, 0, 0, null, 0, 0, 0, 0),
  ('sword0', 'Bronze Sword', 'weapon', 'melee', 3, 0, '1.8', 0, 0, 0, 0),
  ('sword1', 'Iron Sword', 'weapon', 'melee', 6, 0, '1.8', 0, 0, 0, 0),
  ('sword2', 'Steel Sword', 'weapon', 'melee', 10, 0, '1.8', 0, 0, 0, 0),
  ('sword3', 'Mithril Sword', 'weapon', 'melee', 15, 0, '1.8', 0, 0, 0, 0),
  ('sword4', 'Adamant Sword', 'weapon', 'melee', 21, 0, '1.8', 0, 0, 0, 0),
  ('sword5', 'Rune Sword', 'weapon', 'melee', 28, 0, '1.8', 0, 0, 0, 0),
  ('sword6', 'Dragon Scimitar', 'weapon', 'melee', 40, 0, '1.8', 0, 0, 0, 0),
  ('tagbow', '3rd Age Bow', 'weapon', 'ranged', 50, 0, '2', 0.1, 0, 0, 0),
  ('tagcloak', '3rd Age Cloak', 'cape', null, 0, 4, null, 0.03, 0.04, 0, 0),
  ('tagplate', '3rd Age Platebody', 'body', null, 0, 22, null, 0, 0, 0.02, 0),
  ('tagwand', '3rd Age Wand', 'weapon', 'magic', 22, 0, null, 0, 0, 0, 0),
  ('tcape', 'Team Cape', 'cape', null, 0, 1, null, 0.01, 0, 0, 0),
  ('thammaron', 'Thammaron''s Sceptre', 'weapon', 'magic', 24, 0, null, 0, 0, 0, 0),
  ('tips0', 'Bronze Arrowtips', null, null, 0, 0, null, 0, 0, 0, 0),
  ('tips1', 'Iron Arrowtips', null, null, 0, 0, null, 0, 0, 0, 0),
  ('tips2', 'Steel Arrowtips', null, null, 0, 0, null, 0, 0, 0, 0),
  ('tips3', 'Mithril Arrowtips', null, null, 0, 0, null, 0, 0, 0, 0),
  ('tips4', 'Adamant Arrowtips', null, null, 0, 0, null, 0, 0, 0, 0),
  ('tips5', 'Rune Arrowtips', null, null, 0, 0, null, 0, 0, 0, 0),
  ('totem', 'Ancient Totem', null, null, 0, 0, null, 0, 0, 0, 0),
  ('viggora', 'Viggora''s Chainmace', 'weapon', 'melee', 32, 0, '1.8', 0, 0, 0, 0),
  ('wboots', 'Wizard Boots', 'feet', null, 0, 2, null, 0, 0.02, 0, 0),
  ('whip', 'Abyssal Whip', 'weapon', 'melee', 38, 0, '1.6', 0, 0, 0, 0)
on conflict (id) do update set name = excluded.name, slot = excluded.slot, wtype = excluded.wtype, power = excluded.power, armor = excluded.armor,
  speed = excluded.speed, acc = excluded.acc, dmg = excluded.dmg, dr = excluded.dr, heal = excluded.heal;

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

alter table public.profiles add column if not exists rating int not null default 1000;
alter table public.profiles add column if not exists wins int not null default 0;
alter table public.profiles add column if not exists losses int not null default 0;
alter table public.profiles add column if not exists credit bigint not null default 0;   -- PvP gold the next save may add
alter table public.hiscores add column if not exists rating int not null default 1000;

create table if not exists public.pvp_fights (
  id bigserial primary key,
  attacker uuid not null references auth.users (id) on delete cascade,
  defender uuid not null references auth.users (id) on delete cascade,
  attacker_name text not null,
  defender_name text not null,
  winner uuid,
  rating_change int not null default 0,
  gold int not null default 0,
  log jsonb,
  created_at timestamptz not null default now()
);
create index if not exists pvp_fights_attacker on public.pvp_fights (attacker, created_at desc);
create index if not exists pvp_fights_defender on public.pvp_fights (defender, created_at desc);

alter table public.profiles add column if not exists last_seen timestamptz;
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
alter table public.pvp_fights enable row level security;

-- policies can't read hidden columns, so ban checks go through this helper
create or replace function public.is_banned(uid uuid) returns boolean
language sql stable security definer set search_path = public as $$
  select coalesce((select banned from profiles where id = uid), false)
$$;

drop policy if exists "profiles are public" on public.profiles;
create policy "profiles are public" on public.profiles for select using (true);
drop policy if exists "read own save" on public.saves;
create policy "read own save" on public.saves for select to authenticated using ((select auth.uid()) = user_id);
drop policy if exists "hiscores are public" on public.hiscores;
create policy "hiscores are public" on public.hiscores for select using (not public.is_banned(user_id));
drop policy if exists "own fights" on public.pvp_fights;
create policy "own fights" on public.pvp_fights for select to authenticated
  using ((select auth.uid()) = attacker or (select auth.uid()) = defender);
-- cheat_flags, item_values and xp_table have no policies: only the functions below can use them

revoke insert, update, delete on public.profiles, public.saves, public.hiscores from anon, authenticated;
revoke insert, update, delete on public.pvp_fights from anon, authenticated;
revoke all on public.cheat_flags, public.item_values, public.xp_table, public.item_stats, public.quest_rewards from anon, authenticated;
-- profiles: only the public columns can be read (not flags, bans or pending gold)
revoke select on public.profiles from anon, authenticated;
grant select (id, name, rating, wins, losses, imported, created_at) on public.profiles to anon, authenticated;

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
  insert into hiscores (user_id, name, total_level, total_xp, combat, skills, kills, bosses, pks, imported, updated_at, rating)
  select uid, p.name, tl, tx, cmb, coalesce(d -> 'skills', '{}'), coalesce((d ->> 'kills')::numeric, 0), bosses,
         coalesce((d -> 'wild' ->> 'pks')::int, 0), p.imported, now(), p.rating
  from profiles p where p.id = uid
  on conflict (user_id) do update set name = excluded.name, total_level = excluded.total_level, total_xp = excluded.total_xp,
    combat = excluded.combat, skills = excluded.skills, kills = excluded.kills, bosses = excluded.bosses, pks = excluded.pks,
    imported = excluded.imported, rating = excluded.rating, updated_at = now();
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

-- compares an upload with the last accepted save; null when it is fine
create or replace function public.save_problems(prof profiles, old saves, p_data jsonb) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  el numeric; journey boolean; k text; gain numeric; total numeric := 0;
  reasons text[] := '{}'; q_gold numeric; q_xp numeric; m numeric;
  xp_rate numeric; xp_total_rate numeric; xp_grace numeric;
  -- wealth limits, well above the best legitimate money makers (about 150 gold a second)
  gold_rate constant numeric := 200;
  gold_grace constant numeric := 60000; -- one rare drop (Ancient Statuette 40k) between two quick saves
begin
  el := least(extract(epoch from now() - old.updated_at), 86400) + 30;
  -- XP limits follow the hero's own XP multiplier: Renown Wisdom (+15% each) and achievements (up to +76%);
  -- 3 covers rested x shrine x bonfire, mastery and pets, which can all be active at once
  m := 1.76 + 0.15 * least(coalesce((p_data -> 'rup' ->> 'wisdom')::numeric, 0), 10);
  xp_rate := 330 * m * 3; xp_total_rate := 500 * m * 3; xp_grace := 10000 * m;
  -- quests finished since the last save bring exactly their reward
  select coalesce(sum(r.gold + r.items), 0), coalesce(sum(r.xp), 0) into q_gold, q_xp
    from jsonb_each(case when jsonb_typeof(p_data -> 'quests') = 'object' then p_data -> 'quests' else '{}' end) e
    join quest_rewards r on r.id = e.key
    where e.value ->> 's' = 'done' and coalesce(old.data -> 'quests' -> e.key ->> 's', '') <> 'done';
  q_xp := q_xp * m;   -- quest XP goes through the same multiplier
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
  if gain > el / 3 + 10 then reasons := reasons || format('kills +%s in %s s', round(gain), round(el)); end if;
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
    update profiles set last_seen = now() where id = uid;
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

-- ---------- PvP between real players: the server picks the stats from saved heroes and rolls the fight ----------
create or replace function public.fighter(d jsonb) returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  lv jsonb := '{}'; k text; x numeric; w item_stats; t text; r record;
  armor numeric := 0; acc numeric := 0; dmg numeric := 0; dr numeric := 0;
  atk int; str int; def int; hpl int; power numeric; maxhit int; spd numeric; food int; heal numeric; cmb int; extra numeric := 0;
begin
  for k, x in select key, value::numeric from jsonb_each_text(coalesce(d -> 'skills', '{}')) loop
    lv := lv || jsonb_build_object(k, level_from_xp(x));
  end loop;
  select * into w from item_stats where id = d -> 'equip' ->> 'weapon';
  t := coalesce(w.wtype, 'melee');
  for r in select s.* from jsonb_each_text(coalesce(d -> 'equip', '{}')) e join item_stats s on s.id = e.value loop
    armor := armor + r.armor; acc := acc + r.acc; dmg := dmg + r.dmg; dr := dr + r.dr;
  end loop;
  power := coalesce(w.power, 0);
  atk := coalesce((lv ->> (case t when 'melee' then 'attack' else t end))::int, 1);
  str := coalesce((lv ->> (case t when 'melee' then 'strength' else t end))::int, 1);
  def := coalesce((lv ->> 'defence')::int, 1);
  hpl := coalesce((lv ->> 'hitpoints')::int, 1);
  if t = 'magic' then
    -- the best spell this Magic level can cast (game spellbook: level, max hit)
    select coalesce(max(v.mx), 8) into extra from (values (1, 8), (5, 10), (9, 12), (13, 14), (17, 16), (23, 18), (29, 20), (35, 22), (41, 26), (47, 28), (53, 30), (59, 32), (62, 36), (65, 38), (70, 40), (75, 42), (81, 48), (85, 50), (90, 53), (95, 56)) v(lv, mx) where v.lv <= str;
  elsif t = 'ranged' then
    -- the best arrows in the bag (the Crystal Bow needs none)
    select coalesce(max(s.power), 0) into extra from jsonb_each_text(coalesce(d -> 'inv', '{}')) e join item_stats s on s.id = e.key
      where e.key like 'arrow%' and e.value::numeric > 0;
    if w.id = 'cbow' then extra := 12; end if;
  end if;
  maxhit := floor((case t when 'magic' then extra + str * 0.35 + power when 'ranged' then 4 + str * 0.7 + power * 0.8 + extra else 4 + str * 0.7 + power end) * (1 + dmg));
  spd := coalesce(w.speed, case t when 'ranged' then 1.6 when 'magic' then 2.2 else 1.8 end);
  cmb := floor((greatest((coalesce((lv ->> 'attack')::int, 1) + coalesce((lv ->> 'strength')::int, 1)) / 2.0,
                         coalesce((lv ->> 'ranged')::int, 1), coalesce((lv ->> 'magic')::int, 1)) + def + hpl) / 3);
  -- the best food in the bag, ten pieces at most
  select s.heal, least(e.value::numeric, 10)::int into heal, food
    from jsonb_each_text(coalesce(d -> 'inv', '{}')) e join item_stats s on s.id = e.key where s.heal > 0 and e.value::numeric > 0
    order by s.heal desc limit 1;
  return jsonb_build_object('type', t, 'atk', atk + (power + case when t = 'magic' then extra else 0 end) * 0.5, 'def', def, 'armor', armor, 'hp', 40 + hpl * 10,
    'maxhit', greatest(1, maxhit), 'speed', spd, 'acc', acc, 'dr', least(0.4, armor * 0.012 + def * 0.002 + dr),
    'food', coalesce(food, 0), 'heal', coalesce(heal, 0), 'combat', cmb);
end $$;

create or replace function public.pvp_targets() returns jsonb
language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(x), '[]') from (
    select h.user_id as id, h.name, h.combat, h.total_level, p.rating, p.wins, p.losses, s.data -> 'equip' as equip
    from hiscores h join profiles p on p.id = h.user_id join saves s on s.user_id = h.user_id
    where h.user_id <> auth.uid() and not p.banned
    order by abs(h.combat - coalesce((select combat from hiscores where user_id = auth.uid()), 3)), random()
    limit 8) x
$$;

create or replace function public.pvp_attack(p_target uuid) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  uid uuid := auth.uid(); me profiles; op profiles; ms saves; os saves; a jsonb; b jsonb;
  ahp numeric; bhp numeric; amax numeric; bmax numeric; at numeric; bt numeric; afood int; bfood int;
  ev jsonb := '[]'; t numeric; dmg numeric; tri numeric; n int := 0; adealt numeric := 0; bdealt numeric := 0;
  win boolean; expct numeric; chg int; gold int;
  beats constant jsonb := '{"melee":"ranged","ranged":"magic","magic":"melee"}';
begin
  if uid is null then return jsonb_build_object('ok', false, 'reason', 'Sign in first'); end if;
  if p_target = uid then return jsonb_build_object('ok', false, 'reason', 'You cannot fight yourself'); end if;
  select * into me from profiles where id = uid;
  select * into op from profiles where id = p_target;
  if me.id is null or me.banned then return jsonb_build_object('ok', false, 'reason', 'Your account cannot fight'); end if;
  if op.id is null or op.banned then return jsonb_build_object('ok', false, 'reason', 'That player is gone'); end if;
  -- limits so nobody can farm a player or flood the server
  if exists (select 1 from pvp_fights where attacker = uid and created_at > now() - interval '20 seconds') then
    return jsonb_build_object('ok', false, 'reason', 'Catch your breath – one fight every 20 seconds'); end if;
  if (select count(*) from pvp_fights where attacker = uid and created_at > now() - interval '1 hour') >= 40 then
    return jsonb_build_object('ok', false, 'reason', 'You have fought enough this hour'); end if;
  if exists (select 1 from pvp_fights where attacker = uid and defender = p_target and created_at > now() - interval '10 minutes') then
    return jsonb_build_object('ok', false, 'reason', 'You fought this player in the last 10 minutes'); end if;
  if (select count(*) from pvp_fights where defender = p_target and created_at > now() - interval '1 hour') >= 15 then
    return jsonb_build_object('ok', false, 'reason', 'This player was attacked too often – try later'); end if;
  select * into ms from saves where user_id = uid;
  select * into os from saves where user_id = p_target;
  if ms.user_id is null or os.user_id is null then return jsonb_build_object('ok', false, 'reason', 'Save your hero to the cloud first'); end if;

  a := fighter(ms.data); b := fighter(os.data);
  amax := (a ->> 'hp')::numeric; bmax := (b ->> 'hp')::numeric; ahp := amax; bhp := bmax;
  afood := least(4, (a ->> 'food')::int); bfood := least(4, (b ->> 'food')::int);   -- short fights, not food races
  at := (a ->> 'speed')::numeric * 0.5; bt := (b ->> 'speed')::numeric * 0.8;
  while ahp > 0 and bhp > 0 and n < 400 loop
    n := n + 1;
    if at <= bt then
      t := at; at := at + (a ->> 'speed')::numeric;
      if random() < greatest(0.1, least(0.95, 0.6 + ((a ->> 'atk')::numeric - (b ->> 'def')::numeric - (b ->> 'armor')::numeric * 0.5) * 0.02 + (a ->> 'acc')::numeric)) then
        tri := case when beats ->> (a ->> 'type') = b ->> 'type' then 1.1 when beats ->> (b ->> 'type') = a ->> 'type' then 0.92 else 1 end;
        dmg := greatest(1, round((1 + floor(random() * (a ->> 'maxhit')::numeric)) * (1 - (b ->> 'dr')::numeric) * tri));
      else dmg := 0; end if;
      bhp := greatest(0, bhp - dmg); adealt := adealt + dmg;
      ev := ev || jsonb_build_object('t', round(t, 2), 's', 'a', 'd', dmg, 'hp', bhp);
      if bhp > 0 and bhp < bmax * 0.4 and bfood > 0 then
        bfood := bfood - 1; bhp := least(bmax, bhp + (b ->> 'heal')::numeric);
        ev := ev || jsonb_build_object('t', round(t + 0.2, 2), 's', 'be', 'h', (b ->> 'heal')::numeric, 'hp', bhp);
      end if;
    else
      t := bt; bt := bt + (b ->> 'speed')::numeric;
      if random() < greatest(0.1, least(0.95, 0.6 + ((b ->> 'atk')::numeric - (a ->> 'def')::numeric - (a ->> 'armor')::numeric * 0.5) * 0.02 + (b ->> 'acc')::numeric)) then
        tri := case when beats ->> (b ->> 'type') = a ->> 'type' then 1.1 when beats ->> (a ->> 'type') = b ->> 'type' then 0.92 else 1 end;
        dmg := greatest(1, round((1 + floor(random() * (b ->> 'maxhit')::numeric)) * (1 - (a ->> 'dr')::numeric) * tri));
      else dmg := 0; end if;
      ahp := greatest(0, ahp - dmg); bdealt := bdealt + dmg;
      ev := ev || jsonb_build_object('t', round(t, 2), 's', 'd', 'd', dmg, 'hp', ahp);
      if ahp > 0 and ahp < amax * 0.4 and afood > 0 then
        afood := afood - 1; ahp := least(amax, ahp + (a ->> 'heal')::numeric);
        ev := ev || jsonb_build_object('t', round(t + 0.2, 2), 's', 'ae', 'h', (a ->> 'heal')::numeric, 'hp', ahp);
      end if;
    end if;
    exit when t > 240;
  end loop;
  win := bhp <= 0 or (ahp > 0 and adealt >= bdealt);   -- on a timeout the harder hitter wins
  expct := 1 / (1 + power(10, (op.rating - me.rating) / 400.0));
  chg := round(32 * ((case when win then 1 else 0 end) - expct));
  gold := case when win then 40 * (b ->> 'combat')::int else 0 end;
  update profiles set rating = rating + chg, wins = wins + win::int, losses = losses + (not win)::int, credit = credit + gold where id = uid;
  update profiles set rating = rating - chg, wins = wins + (not win)::int, losses = losses + win::int where id = p_target;
  update hiscores set rating = (select rating from profiles where id = uid) where user_id = uid;
  update hiscores set rating = (select rating from profiles where id = p_target) where user_id = p_target;
  insert into pvp_fights (attacker, defender, attacker_name, defender_name, winner, rating_change, gold, log)
    values (uid, p_target, me.name, op.name, case when win then uid else p_target end, chg, gold, ev);
  return jsonb_build_object('ok', true, 'win', win, 'gold', gold, 'rating_change', chg, 'rating', me.rating + chg,
    'me', a, 'opp', b || jsonb_build_object('name', op.name, 'equip', os.data -> 'equip'), 'log', ev);
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
-- ---------- world boss: everyone fights the same boss; the server caps damage by each hero's real max hit ----------
create table if not exists public.world_boss (
  id bigserial primary key,
  kind int not null,
  max_hp bigint not null,
  hp bigint not null,
  started_at timestamptz not null default now(),
  ends_at timestamptz not null,
  killed_at timestamptz
);
create table if not exists public.world_boss_hits (
  boss_id bigint not null references public.world_boss (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  dmg bigint not null default 0,
  last_hit timestamptz not null default now(),
  rewarded boolean not null default false,
  primary key (boss_id, user_id)
);
alter table public.world_boss enable row level security;
alter table public.world_boss_hits enable row level security;
drop policy if exists "world boss is public" on public.world_boss;
create policy "world boss is public" on public.world_boss for select using (true);
drop policy if exists "world boss damage is public" on public.world_boss_hits;
create policy "world boss damage is public" on public.world_boss_hits for select using (true);
revoke insert, update, delete on public.world_boss, public.world_boss_hits from anon, authenticated;

-- the boss that is up now; a new one rises when the last one dies or its week runs out
create or replace function public.wb_current() returns world_boss
language plpgsql security definer set search_path = public as $$
declare b world_boss; last world_boss; n int;
begin
  select * into b from world_boss where killed_at is null and ends_at > now() order by id desc limit 1;
  if b.id is not null then return b; end if;
  select * into last from world_boss order by id desc limit 1;
  -- more fighters last time = more HP this time
  select count(*) into n from world_boss_hits where boss_id = last.id;
  insert into world_boss (kind, max_hp, hp, ends_at)
    values (coalesce(last.kind + 1, 0) % 4, 300000 + greatest(n, 1) * 150000, 300000 + greatest(n, 1) * 150000, now() + interval '7 days')
    returning * into b;
  return b;
end $$;

create or replace function public.wb_state() returns jsonb
language plpgsql security definer set search_path = public as $$
declare b world_boss; top jsonb; mine bigint;
begin
  b := wb_current();
  select coalesce(jsonb_agg(x), '[]') into top from (select name, dmg from world_boss_hits where boss_id = b.id order by dmg desc limit 10) x;
  select dmg into mine from world_boss_hits where boss_id = b.id and user_id = auth.uid();
  return jsonb_build_object('id', b.id, 'kind', b.kind, 'hp', b.hp, 'max_hp', b.max_hp, 'ends_at', b.ends_at, 'top', top, 'mine', coalesce(mine, 0),
    'fighters', (select count(*) from world_boss_hits where boss_id = b.id),
    'unclaimed', (select count(*) from world_boss_hits h join world_boss w on w.id = h.boss_id where h.user_id = auth.uid() and not h.rewarded and (w.killed_at is not null or w.ends_at < now())));
end $$;

create or replace function public.wb_hit(p_dmg bigint) returns jsonb
language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); prof profiles; sv saves; b world_boss; h world_boss_hits; f jsonb; el numeric; cap numeric; dmg bigint;
begin
  if uid is null then return jsonb_build_object('ok', false, 'reason', 'Sign in to fight'); end if;
  select * into prof from profiles where id = uid;
  if prof.id is null or prof.banned then return jsonb_build_object('ok', false, 'reason', 'You cannot fight'); end if;
  select * into sv from saves where user_id = uid;
  if sv.user_id is null then return jsonb_build_object('ok', false, 'reason', 'Save your game first'); end if;
  b := wb_current();
  select * into b from world_boss where id = b.id for update;
  select * into h from world_boss_hits where boss_id = b.id and user_id = uid;
  f := fighter(sv.data);
  if (f ->> 'combat')::int < 40 then return jsonb_build_object('ok', false, 'reason', 'Reach combat level 40 to fight the world boss'); end if;
  -- at most every swing a max hit (with room for potions, prayers and familiars) since the last report
  el := least(extract(epoch from now() - coalesce(h.last_hit, now() - interval '30 seconds')), 60);
  cap := (f ->> 'maxhit')::numeric * 1.8 / greatest((f ->> 'speed')::numeric - 0.2, 1) * el;
  dmg := greatest(0, least(coalesce(p_dmg, 0), floor(cap), b.hp));
  insert into world_boss_hits (boss_id, user_id, name, dmg, last_hit) values (b.id, uid, prof.name, dmg, now())
    on conflict (boss_id, user_id) do update set dmg = world_boss_hits.dmg + excluded.dmg, last_hit = now(), name = excluded.name;
  update world_boss set hp = hp - dmg, killed_at = case when hp - dmg <= 0 then now() else null end where id = b.id returning * into b;
  return jsonb_build_object('ok', true, 'counted', dmg, 'hp', b.hp, 'max_hp', b.max_hp, 'dead', b.killed_at is not null);
end $$;

-- rewards for bosses that are over: gold by share of the damage, a clue for the top three
create or replace function public.wb_claim() returns jsonb
language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); r record; gold bigint := 0; g bigint; clues int := 0; rk int; total numeric;
begin
  if uid is null then return jsonb_build_object('ok', false); end if;
  for r in select h.*, w.max_hp, w.killed_at from world_boss_hits h join world_boss w on w.id = h.boss_id
           where h.user_id = uid and not h.rewarded and (w.killed_at is not null or w.ends_at < now()) for update of h loop
    select coalesce(sum(dmg), 1) into total from world_boss_hits where boss_id = r.boss_id;
    select count(*) + 1 into rk from world_boss_hits where boss_id = r.boss_id and dmg > r.dmg;
    g := case when r.dmg <= 0 then 0 else least(50000, 2000 + floor(r.dmg / total * 120000)) * (case when r.killed_at is null then 0.5 else 1 end) end;
    gold := gold + g;
    if rk <= 3 and r.dmg > 0 then clues := clues + 1; end if;
    update world_boss_hits set rewarded = true where boss_id = r.boss_id and user_id = uid;
  end loop;
  -- the next save may grow by this much (a clue scroll is worth 100)
  update profiles set credit = credit + gold + clues * 100 where id = uid;
  return jsonb_build_object('ok', true, 'gold', gold, 'clues', clues);
end $$;

-- ---------- clans ----------
create table if not exists public.clans (
  id bigserial primary key,
  name text not null unique check (name ~ '^[A-Za-z0-9][A-Za-z0-9 _-]{1,16}[A-Za-z0-9]$'),
  tag text not null unique check (tag ~ '^[A-Z0-9]{2,4}$'),
  owner uuid not null references auth.users (id) on delete cascade,
  motd text not null default '' check (char_length(motd) <= 120),
  created_at timestamptz not null default now()
);
create table if not exists public.clan_members (
  user_id uuid primary key references auth.users (id) on delete cascade,
  clan_id bigint not null references public.clans (id) on delete cascade,
  joined_at timestamptz not null default now()
);
create table if not exists public.clan_chat (
  id bigserial primary key,
  clan_id bigint not null references public.clans (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  body text not null check (char_length(body) between 1 and 200),
  created_at timestamptz not null default now()
);
create index if not exists clan_chat_time on public.clan_chat (clan_id, created_at desc);
alter table public.clans enable row level security;
alter table public.clan_members enable row level security;
alter table public.clan_chat enable row level security;
drop policy if exists "clans are public" on public.clans;
create policy "clans are public" on public.clans for select using (true);
drop policy if exists "clan members are public" on public.clan_members;
create policy "clan members are public" on public.clan_members for select using (true);
drop policy if exists "clan chat is for members" on public.clan_chat;
create policy "clan chat is for members" on public.clan_chat for select
  using (exists (select 1 from public.clan_members m where m.user_id = auth.uid() and m.clan_id = clan_chat.clan_id) and created_at > now() - interval '7 days');
revoke insert, update, delete on public.clans, public.clan_members, public.clan_chat from anon, authenticated;
do $$ begin
  alter publication supabase_realtime add table public.clan_chat;
exception when others then null;
end $$;

create or replace function public.clan_create(p_name text, p_tag text) returns jsonb
language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); prof profiles; c clans; tl int;
begin
  if uid is null then return jsonb_build_object('ok', false, 'reason', 'Sign in first'); end if;
  select * into prof from profiles where id = uid;
  if prof.id is null or prof.banned then return jsonb_build_object('ok', false, 'reason', 'You cannot do that'); end if;
  if exists (select 1 from clan_members where user_id = uid) then return jsonb_build_object('ok', false, 'reason', 'Leave your clan first'); end if;
  select total_level into tl from hiscores where user_id = uid;
  if coalesce(tl, 0) < 100 then return jsonb_build_object('ok', false, 'reason', 'Reach total level 100 to found a clan'); end if;
  insert into clans (name, tag, owner) values (trim(p_name), upper(trim(p_tag)), uid) returning * into c;
  insert into clan_members (user_id, clan_id) values (uid, c.id);
  return jsonb_build_object('ok', true, 'id', c.id);
exception
  when check_violation then return jsonb_build_object('ok', false, 'reason', 'Names are 3-18 letters/numbers, tags 2-4 capital letters or numbers');
  when unique_violation then return jsonb_build_object('ok', false, 'reason', 'That name or tag is taken');
end $$;

create or replace function public.clan_join(p_id bigint) returns jsonb
language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid();
begin
  if uid is null then return jsonb_build_object('ok', false, 'reason', 'Sign in first'); end if;
  if exists (select 1 from clan_members where user_id = uid) then return jsonb_build_object('ok', false, 'reason', 'Leave your clan first'); end if;
  if not exists (select 1 from clans where id = p_id) then return jsonb_build_object('ok', false, 'reason', 'No such clan'); end if;
  if (select count(*) from clan_members where clan_id = p_id) >= 50 then return jsonb_build_object('ok', false, 'reason', 'That clan is full (50)'); end if;
  insert into clan_members (user_id, clan_id) values (uid, p_id);
  return jsonb_build_object('ok', true);
end $$;

-- leaving as the owner hands the clan to the longest member, or closes it when nobody is left
create or replace function public.clan_leave() returns jsonb
language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); cid bigint; heir uuid;
begin
  select clan_id into cid from clan_members where user_id = uid;
  if cid is null then return jsonb_build_object('ok', false, 'reason', 'You are not in a clan'); end if;
  delete from clan_members where user_id = uid;
  if exists (select 1 from clans where id = cid and owner = uid) then
    select user_id into heir from clan_members where clan_id = cid order by joined_at limit 1;
    if heir is null then delete from clans where id = cid; else update clans set owner = heir where id = cid; end if;
  end if;
  return jsonb_build_object('ok', true);
end $$;

create or replace function public.clan_kick(p_user uuid) returns jsonb
language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); cid bigint;
begin
  select id into cid from clans where owner = uid;
  if cid is null or p_user = uid then return jsonb_build_object('ok', false, 'reason', 'Only the clan owner can do that'); end if;
  delete from clan_members where user_id = p_user and clan_id = cid;
  return jsonb_build_object('ok', true);
end $$;

create or replace function public.clan_motd(p_text text) returns jsonb
language plpgsql security definer set search_path = public as $$
begin
  update clans set motd = left(trim(regexp_replace(coalesce(p_text, ''), '[[:cntrl:]]', '', 'g')), 120) where owner = auth.uid();
  return jsonb_build_object('ok', found);
end $$;

-- all clans by the total XP of their members
create or replace function public.clan_list() returns jsonb
language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(x order by x.xp desc), '[]') from (
    select c.id, c.name, c.tag, c.motd, count(m.user_id) as members, coalesce(sum(h.total_xp), 0)::bigint as xp, coalesce(sum(h.total_level), 0) as levels,
      (select name from profiles where id = c.owner) as owner
    from clans c left join clan_members m on m.clan_id = c.id left join hiscores h on h.user_id = m.user_id
    group by c.id) x
$$;

create or replace function public.clan_info(p_id bigint) returns jsonb
language sql stable security definer set search_path = public as $$
  select jsonb_build_object('id', c.id, 'name', c.name, 'tag', c.tag, 'motd', c.motd, 'owner', c.owner,
    'members', coalesce((select jsonb_agg(jsonb_build_object('id', m.user_id, 'name', p.name, 'total_level', h.total_level, 'total_xp', h.total_xp, 'combat', h.combat) order by h.total_xp desc nulls last)
      from clan_members m join profiles p on p.id = m.user_id left join hiscores h on h.user_id = m.user_id where m.clan_id = c.id), '[]'))
  from clans c where c.id = p_id
$$;

create or replace function public.clan_say(p_body text) returns jsonb
language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); prof profiles; cid bigint; b text;
begin
  select * into prof from profiles where id = uid;
  if prof.id is null or prof.banned or prof.muted then return jsonb_build_object('ok', false, 'reason', 'You cannot chat'); end if;
  select clan_id into cid from clan_members where user_id = uid;
  if cid is null then return jsonb_build_object('ok', false, 'reason', 'Join a clan first'); end if;
  b := left(trim(regexp_replace(coalesce(p_body, ''), '[[:cntrl:]]', '', 'g')), 200);
  if b = '' then return jsonb_build_object('ok', false, 'reason', 'Empty message'); end if;
  if exists (select 1 from clan_chat where user_id = uid and created_at > now() - interval '2 seconds') then return jsonb_build_object('ok', false, 'reason', 'Slow down a little'); end if;
  insert into clan_chat (clan_id, user_id, name, body) values (cid, uid, prof.name, b);
  return jsonb_build_object('ok', true);
end $$;

revoke execute on function public.wb_current(), public.wb_state(), public.wb_hit(bigint), public.wb_claim(), public.clan_create(text, text), public.clan_join(bigint),
  public.clan_leave(), public.clan_kick(uuid), public.clan_motd(text), public.clan_list(), public.clan_info(bigint), public.clan_say(text) from public, anon, authenticated;
grant execute on function public.wb_state(), public.wb_hit(bigint), public.wb_claim(), public.clan_create(text, text), public.clan_join(bigint),
  public.clan_leave(), public.clan_kick(uuid), public.clan_motd(text), public.clan_list(), public.clan_info(bigint), public.clan_say(text) to authenticated;
