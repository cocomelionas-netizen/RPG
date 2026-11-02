-- Rules shared by the server and the clients: OSRS-style melee (game ticks of 0.6 s, accuracy and max hit
-- rolls), the skills' xp curve, the longsword and the rat.
local Config = {}

Config.TICK = 0.6

-- the hero's one-handed moves: our own uploaded animations (0 = not uploaded yet, Roblox's sword slash stands in)
Config.ANIM = {
	Hold = 71244894888144, -- AnimBuilder's Hold: the OSRS stance, in place of Roblox's arm-straight-out tool pose
	Slash = 92915599436003, -- AnimBuilder's Slash: from the stance over the shoulder, down in front, follow-through
	RobloxSlash = 522635514, -- Roblox's own R15 tool slash
}
Config.CONTACT = 0.33 -- seconds from the start of a swing to the blade landing (the Slash's "Hit" marker)

Config.SOUNDS = {
	Swish = 9126283272,
	Hit = 9120893061,
}

Config.SWORD = {
	name = "Bronze longsword",
	speed = 5, -- ticks between swings
	attack = 6, -- slash attack bonus
	strength = 5,
	color = Color3.fromRGB(214, 156, 88),
}

Config.STYLES = {
	{ id = "accurate", name = "Accurate", skill = "Attack", attack = 3, strength = 0, defence = 0 },
	{ id = "aggressive", name = "Aggressive", skill = "Strength", attack = 0, strength = 3, defence = 0 },
	{ id = "defensive", name = "Defensive", skill = "Defence", attack = 0, strength = 0, defence = 3 },
}

Config.REACH = 5 -- studs between the hero and the target's edge for a melee swing

Config.ENEMIES = {
	Rat = {
		level = 1,
		hp = 2,
		attack = 1,
		strength = 1,
		defence = 1,
		maxHit = 1,
		speed = 4, -- ticks between bites
		respawn = 15, -- seconds
		count = 7,
		walk = 7,
	},
}

Config.SKILLS = { "Attack", "Strength", "Defence", "Hitpoints" }
Config.START_XP = { Hitpoints = 1154 } -- level 10 Hitpoints, as every new adventurer has

-- total xp needed for each level (the standard RuneScape curve)
local XP = { [1] = 0 }
do
	local points = 0
	for lvl = 1, 98 do
		points += math.floor(lvl + 300 * 2 ^ (lvl / 7))
		XP[lvl + 1] = math.floor(points / 4)
	end
end

function Config.levelFor(xp: number): number
	local lvl = 1
	while lvl < 99 and xp >= XP[lvl + 1] do
		lvl += 1
	end
	return lvl
end

function Config.xpFor(level: number): number
	return XP[math.clamp(level, 1, 99)]
end

-- the chance an attack roll beats a defence roll
function Config.hitChance(attackRoll: number, defenceRoll: number): number
	if attackRoll > defenceRoll then
		return 1 - (defenceRoll + 2) / (2 * (attackRoll + 1))
	end
	return attackRoll / (2 * (defenceRoll + 1))
end

function Config.styleById(id: string?)
	for _, s in Config.STYLES do
		if s.id == id then
			return s
		end
	end
	return Config.STYLES[1]
end

return Config
