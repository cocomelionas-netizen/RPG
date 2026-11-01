-- Construction: workbench recipes (planks, nails) and the rooms of the hero's house.
-- Room costs use the web game's roomCost formula; the rooms themselves give bonuses for the skills in the game so far.
local Construction = {}

-- recipe "tier" is the index used by GatherService (skill "construction")
Construction.RECIPES = {
	[0] = { name = "Birch Planks", req = 1, time = 2.5, xp = 5, item = "plank0", out = 1, inputs = { log0 = 1 } },
	{ name = "Oak Planks", req = 10, time = 2.8, xp = 10, item = "plank1", out = 1, inputs = { log1 = 1 } },
	{ name = "Maple Planks", req = 25, time = 3.1, xp = 18, item = "plank2", out = 1, inputs = { log2 = 1 } },
	{ name = "Yew Planks", req = 40, time = 3.4, xp = 30, item = "plank3", out = 1, inputs = { log3 = 1 } },
	{ name = "Elder Planks", req = 60, time = 3.8, xp = 45, item = "plank4", out = 1, inputs = { log4 = 1 } },
	{ name = "Bronze Nails", req = 1, time = 3, xp = 8, item = "nails", out = 10, inputs = { ore_copper = 1, ore_tin = 1 } },
	{ name = "Iron Nails", req = 15, time = 3, xp = 12, item = "nails", out = 15, inputs = { ore_iron = 1 } },
}
Construction.RECIPE_COUNT = 7

-- bonus[t] is the bonus at room level t (1..5)
Construction.ROOMS = {
	{ id = "woodshed", name = "Woodshed", icon = "🪓", lv = { 1, 20, 40, 60, 80 }, kind = "speed", skill = "woodcutting", bonus = { 5, 10, 15, 20, 25 }, color = "#8a5a32" },
	{ id = "workshop", name = "Workshop", icon = "🔨", lv = { 2, 22, 42, 62, 82 }, kind = "speed", skill = "construction", bonus = { 5, 10, 15, 20, 25 }, color = "#6a6f78" },
	{ id = "cellar", name = "Ore Cellar", icon = "⛏️", lv = { 4, 24, 44, 64, 84 }, kind = "speed", skill = "mining", bonus = { 5, 10, 15, 20, 25 }, color = "#7d7a78" },
	{ id = "pond", name = "Fish Pond", icon = "🎣", lv = { 7, 27, 47, 67, 87 }, kind = "speed", skill = "fishing", bonus = { 5, 10, 15, 20, 25 }, color = "#3d8fd0" },
	{ id = "bedroom", name = "Bedroom", icon = "🛏️", lv = { 10, 30, 50, 70, 90 }, kind = "offline", bonus = { 2, 4, 6, 9, 12 }, color = "#b0607a" },
	{ id = "treasury", name = "Treasury", icon = "🏦", lv = { 15, 35, 55, 75, 95 }, kind = "sell", bonus = { 3, 6, 10, 13, 16 }, color = "#c9a040" },
}
Construction.ROOM_MAX = 5
Construction.byId = {}
for i, r in Construction.ROOMS do
	r.order = i
	Construction.byId[r.id] = r
end

-- cost of building room r up to level t (1..5); same numbers as the web game
function Construction.cost(r, t: number)
	local lvl = r.lv[t]
	local w = lvl < 15 and 0 or lvl < 30 and 1 or lvl < 50 and 2 or lvl < 70 and 3 or 4
	if t >= 4 then
		return { mats = { plank4 = 20 + lvl, nails = 60 + lvl * 2 }, gold = (100 + lvl * lvl * 12) * (t == 4 and 10 or 25) }
	end
	return { mats = { ["plank" .. w] = 6 + math.floor(lvl / 4), nails = 10 + lvl }, gold = 100 + lvl * lvl * 12 }
end

-- Construction XP for building room r to level t
function Construction.xp(r, t: number): number
	local lvl = r.lv[t]
	return math.floor(40 + lvl * lvl * 1.2) * t
end

-- total bonus of one kind from the rooms in rooms (a {id = level} table)
function Construction.bonus(rooms, kind: string, skill: string?): number
	local total = 0
	for _, r in Construction.ROOMS do
		local t = rooms and rooms[r.id] or 0
		if t > 0 and r.kind == kind and (skill == nil or r.skill == skill) then
			total += r.bonus[t]
		end
	end
	return total
end

return Construction
