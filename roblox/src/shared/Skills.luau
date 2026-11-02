-- All 22 skills of Endless Road, in the web game's order
local Skills = {}

Skills.LIST = {
	{ id = "attack", name = "Attack", icon = "⚔️" },
	{ id = "strength", name = "Strength", icon = "💪" },
	{ id = "defence", name = "Defence", icon = "🛡️" },
	{ id = "hitpoints", name = "Hitpoints", icon = "❤️" },
	{ id = "ranged", name = "Ranged", icon = "🏹" },
	{ id = "magic", name = "Magic", icon = "✨" },
	{ id = "prayer", name = "Prayer", icon = "🙏" },
	{ id = "slayer", name = "Slayer", icon = "💀" },
	{ id = "woodcutting", name = "Woodcutting", icon = "🪓" },
	{ id = "mining", name = "Mining", icon = "⛏️" },
	{ id = "fishing", name = "Fishing", icon = "🎣" },
	{ id = "smithing", name = "Smithing", icon = "🔨" },
	{ id = "cooking", name = "Cooking", icon = "🍳" },
	{ id = "fletching", name = "Fletching", icon = "🪶" },
	{ id = "runecrafting", name = "Runeweaving", icon = "🔮" },
	{ id = "thieving", name = "Thieving", icon = "🥷" },
	{ id = "firemaking", name = "Firemaking", icon = "🔥" },
	{ id = "agility", name = "Agility", icon = "🏃" },
	{ id = "farming", name = "Farming", icon = "🌱" },
	{ id = "herblore", name = "Herbalism", icon = "🧪" },
	{ id = "construction", name = "Construction", icon = "🏠" },
	{ id = "summoning", name = "Summoning", icon = "🐺" },
}

Skills.byId = {}
for i, s in Skills.LIST do
	s.order = i
	Skills.byId[s.id] = s
end

-- skills that can be trained in this part of the Roblox version
Skills.GATHERING = { "woodcutting", "mining", "fishing", "farming", "construction" }
Skills.COMBAT = { "attack", "strength", "defence", "hitpoints" }
Skills.ACTIVE = { woodcutting = true, mining = true, fishing = true, farming = true, construction = true, attack = true, strength = true, defence = true, hitpoints = true }

return Skills
