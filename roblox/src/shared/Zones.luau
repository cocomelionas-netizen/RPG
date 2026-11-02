-- The world map: regions laid out close around the town of Riverbend, north is -Z.
--
--   Shadow Caves | Ice Mountains        | Dragon's Lair
--   Dark Forest  | Riverbend (town)     | Hometown (house plots)
--   Green Meadow (start, south)         |
--
-- Each zone is a rectangle (x0, z0, x1, z1). res lists the resource tiers on offer (same as the web game's LOC table),
-- clusters say where on the map each kind of node grows.
local Zones = {}

Zones.ROAD_WIDTH = 16
Zones.BOUNDS = { x0 = -340, z0 = -640, x1 = 500, z1 = 265 }
Zones.SPAWN = Vector3.new(0, 3, 42)

Zones.LIST = {
	{
		id = "meadow", name = "Green Meadow", req = 1, desc = "Rolling fields where every adventurer starts out.",
		rect = { -340, 55, 55, 265 },
		res = { woodcutting = { 0, 1 }, mining = { 0, 1 }, fishing = { 0, 1 } },
		clusters = { woodcutting = Vector3.new(-250, 0, 140), mining = Vector3.new(-105, 0, 140), fishing = Vector3.new(-190, 0, 232) },
		th = { sky = "#78c4ff", sky2 = "#dff3ff", far = "#a9cbe0", ground = "#5c9a3c", dirt = "#7a5a3a", decor = "tree", material = "Grass", clock = 14 },
	},
	{
		id = "town", name = "Riverbend", req = 1, desc = "The town at the crossroads. Every road starts here.", town = true,
		rect = { -55, -145, 55, 55 },
		res = {},
		th = { sky = "#86c9f5", sky2 = "#e6f5ff", far = "#b3d3e3", ground = "#6aa646", dirt = "#9a8a70", decor = "none", material = "Grass", clock = 13 },
	},
	{
		id = "forest", name = "Dark Forest", req = 10, desc = "Old pines, goblin camps and wolves in the shadows.",
		rect = { -340, -145, -55, 55 },
		res = { woodcutting = { 0, 1, 2, 3 }, mining = { 0, 1, 2 }, fishing = { 1, 2 } },
		clusters = { woodcutting = Vector3.new(-170, 0, -100), mining = Vector3.new(-250, 0, 30), fishing = Vector3.new(-150, 0, -38) },
		th = { sky = "#3f6b7d", sky2 = "#a5c6b2", far = "#4f7366", ground = "#365f2b", dirt = "#4a3826", decor = "pine", material = "Grass", clock = 17 },
	},
	{
		id = "caves", name = "Shadow Caves", req = 25, desc = "Tunnels full of ore veins, rune essence and the restless dead.",
		rect = { -340, -400, -55, -145 }, mouthX = -310,
		res = { mining = { 0, 1, 2, 3, 4 }, fishing = { 2 } },
		clusters = { mining = Vector3.new(-185, 0, -265), fishing = Vector3.new(-170, 0, -365) },
		th = { sky = "#140f1d", sky2 = "#352841", far = "#2a2134", ground = "#6e6278", dirt = "#4a3e52", decor = "stalag", material = "Slate", clock = 0, cave = true },
	},
	{
		id = "ice", name = "Ice Mountains", req = 45, desc = "Rich veins from iron to runite lie under the snow, guarded by orcs and trolls.",
		rect = { -55, -400, 200, -145 },
		res = { mining = { 2, 3, 4, 5, 6 }, woodcutting = { 3 }, fishing = { 3 } },
		clusters = { mining = Vector3.new(110, 0, -300), woodcutting = Vector3.new(-30, 0, -300), fishing = Vector3.new(100, 0, -368) },
		th = { sky = "#8fa9cc", sky2 = "#eef4fb", far = "#d3deeb", ground = "#e9eff6", dirt = "#a3b0be", decor = "rock", material = "Snow", clock = 12, snow = true },
	},
	{
		id = "dragon", name = "Dragon's Lair", req = 65, desc = "Lava fields around the Dragon's nest. The heat forges the finest metal.",
		rect = { 200, -400, 500, -145 },
		res = { mining = { 3, 5, 6 }, woodcutting = { 4 } },
		clusters = { mining = Vector3.new(350, 0, -280), woodcutting = Vector3.new(300, 0, -355) },
		th = { sky = "#2a0808", sky2 = "#c2481e", far = "#5a1a14", ground = "#2b1a17", dirt = "#140b09", decor = "spike", material = "Basalt", clock = 18.5, lava = true },
	},
	{
		-- the Wilderness: PvP is on in here (CombatService); north of the Ice Mountains through a cave mouth
		id = "wild", name = "Wraith Caves", req = 40, desc = "PvP zone · Combat 40+ · loot you carry can be lost", wild = true,
		rect = { -200, -640, 200, -400 }, mouthX = 0,
		res = {},
		th = { sky = "#0a0806", sky2 = "#2a3a2a", far = "#2a3a28", ground = "#4a5a48", dirt = "#2a3226", decor = "stalag", material = "Slate", clock = 0, cave = true, ghostly = true },
	},
	{
		id = "home", name = "Hometown", req = 1, desc = "Build your house and live here.", home = true,
		rect = { 55, -145, 500, 265 },
		res = {},
		th = { sky = "#86c9f5", sky2 = "#e6f5ff", far = "#b3d3e3", ground = "#68a848", dirt = "#9a8a70", decor = "none", material = "Grass", clock = 15 },
	},
}

Zones.byId = {}
for i, z in Zones.LIST do
	z.index = i
	Zones.byId[z.id] = z
end

-- roads: straight segments { from, to } on the ground (y ignored)
Zones.ROADS = {
	{ Vector3.new(0, 0, -145), Vector3.new(0, 0, 260) }, -- town north-south and down into the Meadow
	{ Vector3.new(-335, 0, 0), Vector3.new(0, 0, 0) }, -- town west to the Dark Forest
	{ Vector3.new(-310, 0, -330), Vector3.new(-310, 0, 0) }, -- forest north into the Shadow Caves
	{ Vector3.new(0, 0, -630), Vector3.new(0, 0, -145) }, -- up through the Ice Mountains into the Wraith Caves
	{ Vector3.new(0, 0, -190), Vector3.new(495, 0, -190) }, -- across the mountains to the Dragon's Lair
	{ Vector3.new(0, 0, -8), Vector3.new(495, 0, -8) }, -- Hometown main street
	{ Vector3.new(67, 0, -140), Vector3.new(67, 0, 260) }, -- Hometown streets
	{ Vector3.new(212, 0, -140), Vector3.new(212, 0, 260) },
	{ Vector3.new(357, 0, -140), Vector3.new(357, 0, 260) },
}

function Zones.contains(z, x: number, zc: number): boolean
	local r = z.rect
	return x >= r[1] and x <= r[3] and zc >= r[2] and zc <= r[4]
end

-- index of the zone at a map position (falls back to the town)
function Zones.indexAt(x: number, z: number): number
	for i, zone in Zones.LIST do
		if Zones.contains(zone, x, z) then
			return i
		end
	end
	return Zones.byId.town.index
end

function Zones.center(zone): Vector3
	local r = zone.rect
	return Vector3.new((r[1] + r[3]) / 2, 0, (r[2] + r[4]) / 2)
end

return Zones
