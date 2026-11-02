-- The "next goal" guide: one step at a time, each teaches the next part of the loop by doing it.
-- Checks only use numbers that never go back down (xp, counters, rooms, tools), so a step can't un-complete.
-- view is the DataSync view (skills, inv, gold, tools, rooms, stats).
local XP = require(script.Parent.XP)

local Goals = {}

local function made(v, item)
	return v.stats and v.stats.made and v.stats.made[item] or 0
end
local function stat(v, k)
	return v.stats and v.stats[k] or 0
end

-- target: what the arrow points at ("tree0", "rock0", "bench") or which menu button pulses ("bag", "home", "house", "tools")
Goals.LIST = {
	{ text = "Chop 5 logs from a Birch tree", target = "tree0", reward = 20,
		progress = function(v) return math.min(math.floor(v.skills.woodcutting / 10), 5), 5 end },
	{ text = "Mine a Copper and a Tin rock", target = "rock0", reward = 20,
		progress = function(v) return math.min(math.floor(v.skills.mining / 10), 2), 2 end },
	{ text = "Open the 🎒 Bag and sell some logs", target = "bag", reward = 30,
		progress = function(v) return math.min(stat(v, "sold"), 1), 1 end },
	{ text = "Tap 🏡 Go home to visit your plot", target = "home", reward = 20,
		progress = function(v) return math.min(stat(v, "homeTrips"), 1), 1 end },
	{ text = "Step on a ➕ spot in your plot to start your house", target = "home", reward = 30,
		progress = function(v) return v.layout and v.layout.entrance and 1 or 0, 1 end },
	{ text = "Make 6 Birch Planks at your workbench", target = "bench", reward = 40,
		progress = function(v) return math.min(made(v, "plank0"), 6), 6 end },
	{ text = "Make Bronze Nails at your workbench", target = "bench", reward = 40,
		progress = function(v) return math.min(made(v, "nails"), 10), 10 end },
	{ text = "Build the Woodshed on a ➕ spot next to your house", target = "home", reward = 100,
		progress = function(v) return v.layout and v.layout.woodshed and 1 or 0, 1 end },
	{ text = "Upgrade your axe (🛠️ Tools menu)", target = "tools", reward = 100,
		progress = function(v) return math.min(v.tools.axe or 0, 1), 1 end },
	{ text = "Build the Workshop on a ➕ spot next to your house", target = "home", reward = 150,
		progress = function(v) return v.layout and v.layout.workshop and 1 or 0, 1 end },
	{ text = "Reach Woodcutting level 15 to chop Oak", target = "tree0", reward = 250,
		progress = function(v) return math.min(XP.levelFromXp(v.skills.woodcutting), 15), 15 end },
	{ text = "Build the Ore Cellar on a ➕ spot next to your house", target = "home", reward = 250,
		progress = function(v) return v.layout and v.layout.cellar and 1 or 0, 1 end },
	{ text = "Buy seeds at the 🌱 Seed Stall in Riverbend", target = "stall", reward = 50,
		progress = function(v) return math.min(stat(v, "seedsBought"), 1), 1 end },
	{ text = "Plant seeds in a patch in your garden", target = "home", reward = 50,
		progress = function(v) return math.min(stat(v, "planted"), 1), 1 end },
	{ text = "Harvest your first crops", target = "home", reward = 100,
		progress = function(v) return math.min(stat(v, "harvested"), 1), 1 end },
	{ text = "Reach Farming level 10", target = "home", reward = 300,
		progress = function(v) return math.min(XP.levelFromXp(v.skills.farming), 10), 10 end },
}

function Goals.done(i: number, view): boolean
	local g = Goals.LIST[i]
	if not g then
		return false
	end
	local cur, max = g.progress(view)
	return cur >= max
end

return Goals
