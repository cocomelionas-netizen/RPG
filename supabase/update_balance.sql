-- Endless Road update: balance fixes (item values, save limits, PvP formula).
-- Paste ALL of this into Supabase -> SQL Editor (empty query) -> Run. Safe to run more than once.

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
  ('cape0', 40),
  ('cbow', 2500),
  ('chainbody0', 26),
  ('chainbody1', 40),
  ('chainbody2', 99),
  ('chainbody3', 198),
  ('chainbody4', 396),
  ('chainbody5', 858),
  ('cooked0', 5),
  ('cooked1', 12),
  ('cooked2', 25),
  ('cooked3', 50),
  ('cooked4', 100),
  ('craw', 15000),
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
  ('frostcape', 2000),
  ('fullhelm0', 18),
  ('fullhelm1', 26),
  ('fullhelm2', 66),
  ('fullhelm3', 132),
  ('fullhelm4', 264),
  ('fullhelm5', 572),
  ('gem', 150),
  ('gloves0', 30),
  ('gobboots', 600),
  ('kiteshield0', 26),
  ('kiteshield1', 40),
  ('kiteshield2', 99),
  ('kiteshield3', 198),
  ('kiteshield4', 396),
  ('kiteshield5', 858),
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
  ('ore_adamantite', 55),
  ('ore_coal', 10),
  ('ore_copper', 3),
  ('ore_iron', 7),
  ('ore_mithril', 30),
  ('ore_runite', 110),
  ('ore_tin', 3),
  ('platelegs0', 26),
  ('platelegs1', 40),
  ('platelegs2', 99),
  ('platelegs3', 198),
  ('platelegs4', 396),
  ('platelegs5', 858),
  ('r_air', 2),
  ('r_blood', 20),
  ('r_chaos', 6),
  ('r_death', 15),
  ('r_earth', 3),
  ('r_fire', 4),
  ('r_mind', 3),
  ('r_water', 3),
  ('scale', 600),
  ('scimitar0', 18),
  ('scimitar1', 26),
  ('scimitar2', 66),
  ('scimitar3', 132),
  ('scimitar4', 264),
  ('scimitar5', 572),
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
  ('thammaron', 15000),
  ('tips0', 1),
  ('tips1', 1),
  ('tips2', 2),
  ('tips3', 5),
  ('tips4', 10),
  ('tips5', 21),
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
  ('cape0', 'Red Cape', 'cape', null, 0, 1, null, 0, 0, 0, 0),
  ('cbow', 'Crystal Bow', 'weapon', 'ranged', 36, 0, '1.5', 0, 0, 0, 0),
  ('chainbody0', 'Bronze Chainbody', 'body', null, 0, 1, null, 0, 0, 0, 0),
  ('chainbody1', 'Iron Chainbody', 'body', null, 0, 2, null, 0, 0, 0, 0),
  ('chainbody2', 'Steel Chainbody', 'body', null, 0, 3, null, 0, 0, 0, 0),
  ('chainbody3', 'Mithril Chainbody', 'body', null, 0, 4, null, 0, 0, 0, 0),
  ('chainbody4', 'Adamant Chainbody', 'body', null, 0, 6, null, 0, 0, 0, 0),
  ('chainbody5', 'Rune Chainbody', 'body', null, 0, 8, null, 0, 0, 0, 0),
  ('cooked0', 'Cooked Roach', null, null, 0, 0, null, 0, 0, 0, 20),
  ('cooked1', 'Cooked Perch', null, null, 0, 0, null, 0, 0, 0, 45),
  ('cooked2', 'Cooked Pike', null, null, 0, 0, null, 0, 0, 0, 80),
  ('cooked3', 'Cooked Salmon', null, null, 0, 0, null, 0, 0, 0, 120),
  ('cooked4', 'Cooked Eel', null, null, 0, 0, null, 0, 0, 0, 170),
  ('craw', 'Craw''s Bow', 'weapon', 'ranged', 30, 0, '1.5', 0, 0, 0, 0),
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
  ('frostcape', 'Frost Cape', 'cape', null, 0, 6, null, 0, 0, 0.03, 0),
  ('fullhelm0', 'Bronze Full Helm', 'helm', null, 0, 1, null, 0, 0, 0, 0),
  ('fullhelm1', 'Iron Full Helm', 'helm', null, 0, 1, null, 0, 0, 0, 0),
  ('fullhelm2', 'Steel Full Helm', 'helm', null, 0, 2, null, 0, 0, 0, 0),
  ('fullhelm3', 'Mithril Full Helm', 'helm', null, 0, 3, null, 0, 0, 0, 0),
  ('fullhelm4', 'Adamant Full Helm', 'helm', null, 0, 4, null, 0, 0, 0, 0),
  ('fullhelm5', 'Rune Full Helm', 'helm', null, 0, 5, null, 0, 0, 0, 0),
  ('gem', 'Gem', null, null, 0, 0, null, 0, 0, 0, 0),
  ('gloves0', 'Leather Gloves', 'hands', null, 0, 1, null, 0, 0, 0, 0),
  ('gobboots', 'Goblin War Boots', 'feet', null, 0, 4, null, 0, 0, 0, 0),
  ('kiteshield0', 'Bronze Kiteshield', 'shield', null, 0, 1, null, 0, 0, 0, 0),
  ('kiteshield1', 'Iron Kiteshield', 'shield', null, 0, 1, null, 0, 0, 0, 0),
  ('kiteshield2', 'Steel Kiteshield', 'shield', null, 0, 2, null, 0, 0, 0, 0),
  ('kiteshield3', 'Mithril Kiteshield', 'shield', null, 0, 3, null, 0, 0, 0, 0),
  ('kiteshield4', 'Adamant Kiteshield', 'shield', null, 0, 4, null, 0, 0, 0, 0),
  ('kiteshield5', 'Rune Kiteshield', 'shield', null, 0, 6, null, 0, 0, 0, 0),
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
  ('ore_adamantite', 'Adamantite Ore', null, null, 0, 0, null, 0, 0, 0, 0),
  ('ore_coal', 'Coal', null, null, 0, 0, null, 0, 0, 0, 0),
  ('ore_copper', 'Copper Ore', null, null, 0, 0, null, 0, 0, 0, 0),
  ('ore_iron', 'Iron Ore', null, null, 0, 0, null, 0, 0, 0, 0),
  ('ore_mithril', 'Mithril Ore', null, null, 0, 0, null, 0, 0, 0, 0),
  ('ore_runite', 'Runite Ore', null, null, 0, 0, null, 0, 0, 0, 0),
  ('ore_tin', 'Tin Ore', null, null, 0, 0, null, 0, 0, 0, 0),
  ('platelegs0', 'Bronze Platelegs', 'legs', null, 0, 1, null, 0, 0, 0, 0),
  ('platelegs1', 'Iron Platelegs', 'legs', null, 0, 1, null, 0, 0, 0, 0),
  ('platelegs2', 'Steel Platelegs', 'legs', null, 0, 2, null, 0, 0, 0, 0),
  ('platelegs3', 'Mithril Platelegs', 'legs', null, 0, 4, null, 0, 0, 0, 0),
  ('platelegs4', 'Adamant Platelegs', 'legs', null, 0, 5, null, 0, 0, 0, 0),
  ('platelegs5', 'Rune Platelegs', 'legs', null, 0, 7, null, 0, 0, 0, 0),
  ('r_air', 'Air Rune', null, null, 0, 0, null, 0, 0, 0, 0),
  ('r_blood', 'Blood Rune', null, null, 0, 0, null, 0, 0, 0, 0),
  ('r_chaos', 'Chaos Rune', null, null, 0, 0, null, 0, 0, 0, 0),
  ('r_death', 'Death Rune', null, null, 0, 0, null, 0, 0, 0, 0),
  ('r_earth', 'Earth Rune', null, null, 0, 0, null, 0, 0, 0, 0),
  ('r_fire', 'Fire Rune', null, null, 0, 0, null, 0, 0, 0, 0),
  ('r_mind', 'Mind Rune', null, null, 0, 0, null, 0, 0, 0, 0),
  ('r_water', 'Water Rune', null, null, 0, 0, null, 0, 0, 0, 0),
  ('scale', 'Dragon Scale', null, null, 0, 0, null, 0, 0, 0, 0),
  ('scimitar0', 'Bronze Scimitar', 'weapon', 'melee', 3, 0, '1.8', 0, 0, 0, 0),
  ('scimitar1', 'Iron Scimitar', 'weapon', 'melee', 7, 0, '1.8', 0, 0, 0, 0),
  ('scimitar2', 'Steel Scimitar', 'weapon', 'melee', 12, 0, '1.8', 0, 0, 0, 0),
  ('scimitar3', 'Mithril Scimitar', 'weapon', 'melee', 17, 0, '1.8', 0, 0, 0, 0),
  ('scimitar4', 'Adamant Scimitar', 'weapon', 'melee', 24, 0, '1.8', 0, 0, 0, 0),
  ('scimitar5', 'Rune Scimitar', 'weapon', 'melee', 32, 0, '1.8', 0, 0, 0, 0),
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
  ('thammaron', 'Thammaron''s Sceptre', 'weapon', 'magic', 24, 0, null, 0, 0, 0, 0),
  ('tips0', 'Bronze Arrowtips', null, null, 0, 0, null, 0, 0, 0, 0),
  ('tips1', 'Iron Arrowtips', null, null, 0, 0, null, 0, 0, 0, 0),
  ('tips2', 'Steel Arrowtips', null, null, 0, 0, null, 0, 0, 0, 0),
  ('tips3', 'Mithril Arrowtips', null, null, 0, 0, null, 0, 0, 0, 0),
  ('tips4', 'Adamant Arrowtips', null, null, 0, 0, null, 0, 0, 0, 0),
  ('tips5', 'Rune Arrowtips', null, null, 0, 0, null, 0, 0, 0, 0),
  ('totem', 'Ancient Totem', null, null, 0, 0, null, 0, 0, 0, 0),
  ('viggora', 'Viggora''s Chainmace', 'weapon', 'melee', 32, 0, '1.8', 0, 0, 0, 0),
  ('whip', 'Abyssal Whip', 'weapon', 'melee', 38, 0, '1.6', 0, 0, 0, 0)
on conflict (id) do update set name = excluded.name, slot = excluded.slot, wtype = excluded.wtype, power = excluded.power, armor = excluded.armor,
  speed = excluded.speed, acc = excluded.acc, dmg = excluded.dmg, dr = excluded.dr, heal = excluded.heal;

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
