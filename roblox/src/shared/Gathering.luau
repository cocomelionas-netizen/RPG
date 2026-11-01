-- Gathering numbers ported from the web game (GATHER_REQ/TIME/XP, ORES, TOOL_COST ...)
-- Tiers are 0-based like in the web game.
local Construction = require(script.Parent.Construction)

local G = {}

G.GATHER_REQ = { [0] = 1, 15, 30, 50, 70 }
G.GATHER_TIME = { [0] = 3, 3.5, 4, 4.5, 5 }
G.GATHER_XP = { [0] = 10, 20, 35, 55, 80 }

G.TREE_N = { [0] = "Birch", "Oak", "Maple", "Yew", "Elder Tree" }
G.FISH_N = { [0] = "Roach", "Perch", "Pike", "Salmon", "Eel" }
G.CANOPY = { [0] = "#8ccf6b", "#3f8f3a", "#d0702f", "#2f6b45", "#b06be0" }

G.ORES = {
	[0] = { id = "copper", name = "Copper Ore", rock = "Copper Rock", lvl = 1, xp = 10, time = 3.0, color = "#c87533", value = 3 },
	{ id = "tin", name = "Tin Ore", rock = "Tin Rock", lvl = 1, xp = 10, time = 3.0, color = "#c9ccd2", value = 3 },
	{ id = "iron", name = "Iron Ore", rock = "Iron Rock", lvl = 15, xp = 20, time = 3.5, color = "#9a5f4a", value = 7 },
	{ id = "coal", name = "Coal", rock = "Coal Rock", lvl = 30, xp = 30, time = 3.8, color = "#26262b", value = 10 },
	{ id = "mithril", name = "Cobalt Ore", rock = "Cobalt Rock", lvl = 55, xp = 50, time = 4.4, color = "#5a6ad8", value = 30 },
	{ id = "adamantite", name = "Verdite Ore", rock = "Verdite Rock", lvl = 70, xp = 65, time = 4.9, color = "#4a9a5a", value = 55 },
	{ id = "runite", name = "Skyrite Ore", rock = "Skyrite Rock", lvl = 85, xp = 85, time = 5.6, color = "#3fc6e0", value = 65 },
}

G.METALS = { [0] = "Bronze", "Iron", "Steel", "Cobalt", "Verdite", "Skyrite", "Wyrmsteel" }
G.METAL_COLORS = { [0] = "#b07a45", "#8a8f98", "#b8bec8", "#5a68b8", "#4a9a5a", "#4aa8c0", "#c0392b" }

-- tool upgrades: level 0 (Bronze) .. 4 (Verdite); each level is 12% faster
G.TOOL_COST = { [0] = 300, 3000, 20000, 80000 }
G.TOOL_MAX = 4
G.TOOL_NAMES = { axe = "Axe", pick = "Pickaxe", rod = "Fishing Rod", saw = "Saw" }
G.TOOL_OF = { woodcutting = "axe", mining = "pick", fishing = "rod", construction = "saw" }
G.TOOL_ORDER = { "axe", "pick", "rod" }

G.VERB = { woodcutting = "Chop", mining = "Mine", fishing = "Fish", construction = "Make" }
G.VERB_ING = { woodcutting = "Chopping", mining = "Mining", fishing = "Fishing", construction = "Making" }

-- idle: how much time away from the game still counts (web base cap is 12h)
G.OFFLINE_CAP = 12 * 3600
G.OFFLINE_MIN = 60

function G.toolName(tool: string, level: number): string
	return G.METALS[level] .. " " .. G.TOOL_NAMES[tool]
end

-- everything about one kind of node: display name, level needed, seconds, xp and the item it gives
function G.node(skill: string, tier: number)
	if skill == "mining" then
		local o = G.ORES[tier]
		return { name = o.rock, req = o.lvl, time = o.time, xp = o.xp, item = "ore_" .. o.id }
	elseif skill == "woodcutting" then
		return { name = G.TREE_N[tier], req = G.GATHER_REQ[tier], time = G.GATHER_TIME[tier], xp = G.GATHER_XP[tier], item = "log" .. tier }
	elseif skill == "fishing" then
		return { name = G.FISH_N[tier] .. " Spot", req = G.GATHER_REQ[tier], time = G.GATHER_TIME[tier], xp = G.GATHER_XP[tier], item = "fish" .. tier }
	elseif skill == "construction" then
		-- workbench recipes also have inputs and can make more than one item at a time
		return Construction.RECIPES[tier]
	end
	return nil
end

-- seconds per action: tools are 12% faster per level, house rooms add a speed bonus on top
function G.actionTime(skill: string, tier: number, toolLevel: number, rooms): number
	local n = G.node(skill, tier)
	local roomBonus = Construction.bonus(rooms, "speed", skill)
	return n.time * (1 - 0.12 * (toolLevel or 0)) / (1 + roomBonus / 100)
end

-- how many hours of offline progress count (12h plus the Bedroom)
function G.offlineCap(rooms): number
	return G.OFFLINE_CAP + Construction.bonus(rooms, "offline") * 3600
end

return G
