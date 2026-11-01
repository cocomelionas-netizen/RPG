-- The road: the five story zones of the web game laid out one after another along +X.
local Zones = {}

Zones.LENGTH = 320 -- studs per zone along the road
Zones.WIDTH = 260 -- playable width (road runs down the middle, Z = 0)
Zones.ROAD_WIDTH = 16

-- res lists the resource tiers on offer (same as the web game's LOC table)
Zones.LIST = {
	{
		name = "Green Meadow", req = 1, desc = "Rolling fields where every adventurer starts out.",
		res = { woodcutting = { 0, 1 }, mining = { 0, 1 }, fishing = { 0, 1 } },
		th = { sky = "#78c4ff", sky2 = "#dff3ff", far = "#a9cbe0", ground = "#5c9a3c", dirt = "#7a5a3a", decor = "tree", material = "Grass", clock = 14 },
	},
	{
		name = "Dark Forest", req = 10, desc = "Old pines, goblin camps and wolves in the shadows.",
		res = { woodcutting = { 0, 1, 2, 3 }, mining = { 0, 1, 2 }, fishing = { 1, 2 } },
		th = { sky = "#3f6b7d", sky2 = "#a5c6b2", far = "#4f7366", ground = "#365f2b", dirt = "#4a3826", decor = "pine", material = "Grass", clock = 17 },
	},
	{
		name = "Shadow Caves", req = 25, desc = "Tunnels full of ore veins, rune essence and the restless dead.",
		res = { mining = { 0, 1, 2, 3, 4 }, fishing = { 2 } },
		th = { sky = "#140f1d", sky2 = "#352841", far = "#2a2134", ground = "#4a3f4f", dirt = "#2a2230", decor = "stalag", material = "Slate", clock = 0, cave = true },
	},
	{
		name = "Ice Mountains", req = 45, desc = "Rich veins from iron to runite lie under the snow, guarded by orcs and trolls.",
		res = { mining = { 2, 3, 4, 5, 6 }, woodcutting = { 3 }, fishing = { 3 } },
		th = { sky = "#8fa9cc", sky2 = "#eef4fb", far = "#d3deeb", ground = "#e9eff6", dirt = "#a3b0be", decor = "rock", material = "Snow", clock = 12, snow = true },
	},
	{
		name = "Dragon's Lair", req = 65, desc = "Lava fields around the Dragon's nest. The heat forges the finest metal.",
		res = { mining = { 3, 5, 6 }, woodcutting = { 4 } },
		th = { sky = "#2a0808", sky2 = "#c2481e", far = "#5a1a14", ground = "#2b1a17", dirt = "#140b09", decor = "spike", material = "Basalt", clock = 18.5, lava = true },
	},
}

function Zones.startX(index: number): number
	return (index - 1) * Zones.LENGTH
end

function Zones.centerX(index: number): number
	return (index - 0.5) * Zones.LENGTH
end

function Zones.indexAt(x: number): number
	return math.clamp(math.floor(x / Zones.LENGTH) + 1, 1, #Zones.LIST)
end

return Zones
