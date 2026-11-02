-- Farming: seeds, what they grow into and the garden patches of a house plot.
-- Numbers ported from the web game's defSeed calls (time in seconds of real time, so crops also grow while you are away).
local Farming = {}

-- kind: "allot" (allotment crops), "herb", "tree"
Farming.SEEDS = {}
Farming.byId = {}

local function seed(o)
	o.order = #Farming.SEEDS + 1
	table.insert(Farming.SEEDS, o)
	Farming.byId[o.id] = o
end

-- allotment crops: { key, name, icon, level, colour }
Farming.CROPS = {
	{ "potato", "Potato", "🥔", 1, "#c8a060" },
	{ "onion", "Onion", "🧅", 5, "#e8c890" },
	{ "cabbage", "Cabbage", "🥬", 9, "#7ac85a" },
	{ "tomato", "Tomato", "🍅", 15, "#e04a3a" },
	{ "sweetcorn", "Sweetcorn", "🌽", 25, "#f2d24a" },
	{ "strawberry", "Strawberry", "🍓", 35, "#e83a5a" },
	{ "watermelon", "Watermelon", "🍉", 50, "#3a9a4a" },
	{ "snape", "Silvergrass", "🌾", 61, "#9ad86a" },
}
for i, c in Farming.CROPS do
	local lvl = c[4]
	seed({
		id = "seed_" .. c[1], name = c[2] .. " Seed", kind = "allot", lvl = lvl, time = 300 + (i - 1) * 150,
		out = "crop_" .. c[1], n = { 6, 12 }, px = math.floor(5 + lvl * 0.8 + 0.5), hx = math.floor(2 + lvl * 0.45 + 0.5),
		color = c[5], value = math.floor(2 + lvl * 0.5 + 0.5),
	})
end

-- herbs: { key, name, level, colour }
Farming.HERBS = {
	{ "guam", "Greenleaf", 3, "#7fbf4a" }, { "marrentill", "Moonwort", 8, "#5aa83a" }, { "tarromin", "Thistlewort", 13, "#a8c84a" },
	{ "harralander", "Hollyroot", 21, "#8ab03a" }, { "ranarr", "Sunpetal", 32, "#3a9a6a" }, { "irit", "Ironleaf", 44, "#9ac84a" },
	{ "kwuarm", "Bramblewort", 56, "#6a8a2a" }, { "snapdragon", "Snapdragon", 62, "#c8d84a" }, { "cadantine", "Duskbloom", 67, "#4a7a3a" },
	{ "dwarfweed", "Stoneweed", 79, "#7ab84a" }, { "torstol", "Starbloom", 85, "#b8a83a" },
}
for i, h in Farming.HERBS do
	local lvl = h[3]
	seed({
		id = "seed_" .. h[1], name = h[2] .. " Seed", kind = "herb", lvl = lvl, time = 900 + (i - 1) * 180,
		out = "herb_" .. h[1], n = { 3, 6 }, px = math.floor(8 + lvl * 1.1 + 0.5), hx = math.floor(6 + lvl + 0.5),
		color = h[4], value = math.floor(4 + lvl * 0.9 + 0.5),
	})
end

-- trees: { key, name, level, seconds, log item, logs, colour, sapling price }
Farming.TREES = {
	{ "oak", "Oak", 15, 2400, "log1", 15, "#3f8f3a", 60 },
	{ "maple", "Maple", 35, 4800, "log2", 20, "#d0702f", 200 },
	{ "yew", "Yew", 60, 9000, "log3", 25, "#2f6b45", 600 },
	{ "magic", "Elder", 80, 14400, "log4", 30, "#b06be0", 1500 },
}
for _, t in Farming.TREES do
	local lvl = t[3]
	seed({
		id = "sapling_" .. t[1], name = t[2] .. " Sapling", kind = "tree", lvl = lvl, time = t[4],
		out = t[5], n = { t[6], t[6] + 10 }, px = math.floor(20 + lvl * 3 + 0.5), hx = math.floor(150 + lvl * lvl * 0.7 + 0.5),
		color = t[7], value = t[8],
	})
end

Farming.KIND_NAME = { allot = "Allotment", herb = "Herb patch", tree = "Tree patch" }

-- the garden patches along the south fence of every plot: x offset from the plot centre
Farming.PATCHES = {
	{ kind = "allot", x = -42 }, { kind = "allot", x = -28 }, { kind = "allot", x = -14 },
	{ kind = "herb", x = 2 }, { kind = "herb", x = 16 },
	{ kind = "tree", x = 36, req = 15 },
}

-- the seed shop in Riverbend: { seed, how many, price }
Farming.SHOP = {
	{ "seed_potato", 5, 25 }, { "seed_onion", 5, 40 }, { "seed_cabbage", 5, 70 }, { "seed_tomato", 5, 120 },
	{ "seed_guam", 3, 45 }, { "seed_marrentill", 3, 70 }, { "seed_tarromin", 3, 110 },
	{ "sapling_oak", 1, 250 }, { "sapling_maple", 1, 900 },
}

-- 0..1 of the way to ready
function Farming.progress(p, now: number): number
	local s = p and Farming.byId[p.seed]
	if not s then
		return 0
	end
	return math.clamp((now - p.planted) / s.time, 0, 1)
end

-- growth stage 0 (empty) .. 4 (ready)
function Farming.stage(p, now: number): number
	if not p or not Farming.byId[p.seed] then
		return 0
	end
	local f = Farming.progress(p, now)
	return f >= 1 and 4 or math.clamp(1 + math.floor(f * 3), 1, 3)
end

function Farming.timeLeft(p, now: number): number
	local s = p and Farming.byId[p.seed]
	return s and math.max(0, s.time - (now - p.planted)) or 0
end

function Farming.fmtTime(sec: number): string
	sec = math.floor(sec)
	if sec >= 3600 then
		return ("%dh %dm"):format(sec // 3600, sec % 3600 // 60)
	elseif sec >= 60 then
		return ("%dm %ds"):format(sec // 60, sec % 60)
	end
	return sec .. "s"
end

-- a seed that may drop while gathering: lower tiers of every kind, rarer ones from better nodes
function Farming.dropFor(tier: number, rng: Random): string?
	local pool = {}
	for _, s in Farming.SEEDS do
		if s.kind ~= "tree" and s.lvl <= 5 + tier * 15 then
			table.insert(pool, s.id)
		end
	end
	if #pool == 0 then
		return nil
	end
	return pool[rng:NextInteger(1, #pool)]
end

return Farming
