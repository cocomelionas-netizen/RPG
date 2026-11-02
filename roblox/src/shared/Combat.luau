-- Combat: enemies, gear and the formulas, ported from the web game (ENEMIES, METAL_*, playerMaxHit, playerHitChance ...).
-- Hitpoints are on the web game's scale: max HP = 40 + 10 per Hitpoints level, enemies hit for tens.
local XP = require(script.Parent.XP)

local Combat = {}

-- shape: blob | quad | humanoid | flyer | dragon
Combat.ENEMIES = {
	slime = { name = "Slime", hp = 12, maxHit = 2, atk = 1, def = 1, speed = 2.6, gold = { 1, 3 }, shape = "blob", size = 1, color = "#5fd35f" },
	rat = { name = "Rat", hp = 18, maxHit = 3, atk = 3, def = 2, speed = 2.2, gold = { 1, 4 }, shape = "quad", size = 0.6, color = "#8a7f75" },
	goblin = { name = "Goblin", hp = 60, maxHit = 7, atk = 11, def = 10, speed = 2.4, gold = { 4, 10 }, shape = "humanoid", size = 0.8, color = "#6fae46", body = "#7a5a3a" },
	gobarcher = { name = "Goblin Archer", hp = 50, maxHit = 8, atk = 12, def = 8, speed = 2.2, gold = { 4, 10 }, shape = "humanoid", size = 0.8, color = "#6fae46", body = "#3f5a2a" },
	wolf = { name = "Wolf", hp = 75, maxHit = 9, atk = 13, def = 12, speed = 2.0, gold = { 3, 8 }, shape = "quad", size = 0.95, color = "#6b6f78" },
	bat = { name = "Bat", hp = 180, maxHit = 16, atk = 27, def = 25, speed = 1.6, gold = { 6, 14 }, shape = "flyer", size = 1, color = "#4a3a5a" },
	skeleton = { name = "Skeleton Archer", hp = 260, maxHit = 20, atk = 31, def = 30, speed = 2.4, gold = { 10, 22 }, shape = "humanoid", size = 1, color = "#eeeadf", body = "#e2ddcc" },
	cultist = { name = "Dark Cultist", hp = 220, maxHit = 22, atk = 30, def = 26, speed = 2.6, gold = { 10, 20 }, shape = "humanoid", size = 1, color = "#d8c0a0", body = "#3a2050" },
	orc = { name = "Orc", hp = 520, maxHit = 32, atk = 48, def = 47, speed = 2.6, gold = { 20, 40 }, shape = "humanoid", size = 1.15, color = "#7f9a3e", body = "#4a3a2c" },
	icemage = { name = "Ice Mage", hp = 600, maxHit = 36, atk = 50, def = 44, speed = 2.6, gold = { 20, 45 }, shape = "humanoid", size = 1, color = "#e0eaff", body = "#4a6aa8" },
	troll = { name = "Troll", hp = 800, maxHit = 40, atk = 54, def = 54, speed = 3.0, gold = { 30, 60 }, shape = "humanoid", size = 1.45, color = "#8b9bb0", body = "#5c5248" },
	yeti = { name = "Yeti", hp = 1000, maxHit = 44, atk = 60, def = 58, speed = 2.8, gold = { 35, 70 }, shape = "quad", size = 1.5, color = "#e8eef5" },
	lizard = { name = "Fire Lizard", hp = 1200, maxHit = 50, atk = 68, def = 68, speed = 2.2, gold = { 50, 90 }, shape = "quad", size = 1.2, color = "#d8562a" },
	imp = { name = "Fire Imp", hp = 1000, maxHit = 46, atk = 64, def = 62, speed = 1.8, gold = { 45, 80 }, shape = "flyer", size = 1, color = "#c43a2a" },
	drakeknight = { name = "Dragon Knight", hp = 1300, maxHit = 52, atk = 70, def = 72, speed = 2.6, gold = { 55, 95 }, shape = "humanoid", size = 1.2, color = "#c8a080", body = "#7a1e14" },
	bog = { name = "Bog Horror", hp = 300, maxHit = 18, atk = 28, def = 26, speed = 2.4, gold = { 15, 30 }, shape = "blob", size = 1.4, color = "#5a7a3a" },
	wisp = { name = "Will-o'-Wisp", hp = 220, maxHit = 22, atk = 30, def = 22, speed = 2.0, gold = { 12, 26 }, shape = "flyer", size = 1, color = "#a8f0ff", ghost = true },
	revimp = { name = "Wraith Imp", hp = 160, maxHit = 14, atk = 40, def = 30, speed = 2.2, gold = { 20, 45 }, shape = "flyer", size = 0.9, color = "#8aa07a", ghost = true },
	revgob = { name = "Wraith Goblin", hp = 420, maxHit = 24, atk = 52, def = 46, speed = 2.4, gold = { 40, 90 }, shape = "humanoid", size = 0.9, color = "#a8d098", body = "#3a4a3a", ghost = true },
	revknight = { name = "Wraith Knight", hp = 1600, maxHit = 46, atk = 74, def = 76, speed = 2.6, gold = { 120, 240 }, shape = "humanoid", size = 1.3, color = "#c8e8c0", body = "#2a3a2a", ghost = true },
	revdragon = { name = "Wraith Dragon", hp = 3600, maxHit = 60, atk = 86, def = 84, speed = 3.0, gold = { 260, 480 }, shape = "dragon", size = 1, color = "#6a8a5a", ghost = true },
}
for id, e in Combat.ENEMIES do
	e.id = id
	e.level = math.max(1, math.floor((e.atk + e.def) / 2 + e.hp / 40))
end

-- monster camps: { zone, centre, enemies, how many of each, spread }
Combat.CAMPS = {
	{ zone = "meadow", center = Vector3.new(-55, 0, 200), enemies = { "slime", "rat" }, each = 3 },
	{ zone = "meadow", center = Vector3.new(-300, 0, 88), enemies = { "slime" }, each = 3, spread = 18 },
	{ zone = "swamp", center = Vector3.new(-90, 0, 355), enemies = { "bog", "wisp" }, each = 3 },
	{ zone = "swamp", center = Vector3.new(-280, 0, 385), enemies = { "bog" }, each = 2, spread = 18 },
	{ zone = "forest", center = Vector3.new(-265, 0, -90), enemies = { "goblin", "gobarcher", "wolf" }, each = 2 },
	{ zone = "forest", center = Vector3.new(-110, 0, 35), enemies = { "wolf" }, each = 3, spread = 14 },
	{ zone = "caves", center = Vector3.new(-120, 0, -200), enemies = { "bat", "skeleton", "cultist" }, each = 2 },
	{ zone = "caves", center = Vector3.new(-280, 0, -372), enemies = { "skeleton", "bat" }, each = 2, spread = 18 },
	{ zone = "ice", center = Vector3.new(130, 0, -230), enemies = { "orc", "icemage", "troll", "yeti" }, each = 2 },
	{ zone = "dragon", center = Vector3.new(430, 0, -330), enemies = { "lizard", "imp", "drakeknight" }, each = 2 },
	{ zone = "dragon", center = Vector3.new(255, 0, -250), enemies = { "lizard" }, each = 3, spread = 18 },
	{ zone = "wild", center = Vector3.new(0, 0, -520), enemies = { "revimp", "revgob", "revknight", "revdragon" }, each = 2, spread = 150 },
}

-- gear: one weapon and one armour set, by metal tier (web METAL_EQUIP / METAL_POWER / METAL_ARMOUR)
Combat.METALS = { [0] = "Bronze", "Iron", "Steel", "Cobalt", "Verdite", "Skyrite", "Wyrmsteel" }
Combat.METAL_COLORS = { [0] = "#b07a45", "#8a8f98", "#b8bec8", "#5a68b8", "#4a9a5a", "#4aa8c0", "#c0392b" }
Combat.EQUIP_REQ = { [0] = 1, 1, 5, 20, 30, 40, 60 }
Combat.POWER = { [0] = 3, 6, 10, 15, 21, 28, 34 }
Combat.ARMOUR = { [0] = 2, 4, 7, 10, 14, 19, 26 }
Combat.WEAPON_COST = { [0] = 60, 400, 1500, 6000, 18000, 45000, 120000 }
Combat.ARMOUR_COST = { [0] = 80, 500, 1800, 7000, 21000, 52000, 140000 }
Combat.GEAR_MAX = 6

-- melee styles: which skill the XP goes to, and the +8 bonus
Combat.STYLES = {
	{ id = "accurate", name = "Accurate", skill = "attack", desc = "Hit more often · Attack XP" },
	{ id = "aggressive", name = "Aggressive", skill = "strength", desc = "Hit harder · Strength XP" },
	{ id = "defensive", name = "Defensive", skill = "defence", desc = "Take less damage · Defence XP" },
	{ id = "balanced", name = "Balanced", skill = nil, desc = "XP to your lowest of the three" },
}
Combat.STYLE_BY = {}
for _, s in Combat.STYLES do
	Combat.STYLE_BY[s.id] = s
end

Combat.PLAYER_SPEED = 1.8 -- seconds per swing
Combat.REACH = 12 -- studs: how close you must stand to fight
Combat.WILD_REQ = 40 -- combat level to enter the Wraith Caves

local function lv(skills, id)
	return XP.levelFromXp(skills[id] or 0)
end

function Combat.combatLevel(skills): number
	return math.floor(((lv(skills, "attack") + lv(skills, "strength")) / 2 + lv(skills, "defence") + lv(skills, "hitpoints")) / 3)
end

function Combat.maxHp(skills): number
	return 40 + lv(skills, "hitpoints") * 10
end

-- the attacker's numbers for one fight: data = save (skills, gear, style)
function Combat.attackerStats(data)
	local s = data.skills
	local style = data.combat and data.combat.style or "accurate"
	local w = data.gear and data.gear.weapon or -1
	local power = w >= 0 and Combat.POWER[w] or 0
	local str = lv(s, "strength") + (style == "aggressive" and 8 or 0)
	return {
		maxHit = math.floor(4 + str * 0.7 + power),
		acc = lv(s, "attack") + (style == "accurate" and 8 or 0) + power * 0.5,
	}
end

function Combat.defenderStats(data)
	local s = data.skills
	local a = data.gear and data.gear.armour or -1
	local armour = a >= 0 and Combat.ARMOUR[a] or 0
	local def = lv(s, "defence") + ((data.combat and data.combat.style) == "defensive" and 8 or 0)
	return {
		def = def,
		armour = armour,
		dr = math.min(0.6, armour * 0.012 + def * 0.002),
	}
end

function Combat.hitChance(acc: number, def: number): number
	return math.clamp(0.5 + (acc - def) * 0.02, 0.1, 0.97)
end

function Combat.enemyHitChance(atk: number, d): number
	return math.clamp(0.6 + (atk - d.def - d.armour * 0.5) * 0.02, 0.15, 0.95)
end

-- which skill gets the XP for a hit with this style (balanced: the lowest of the three)
function Combat.xpSkill(data): string
	local style = Combat.STYLE_BY[data.combat and data.combat.style or "accurate"] or Combat.STYLES[1]
	if style.skill then
		return style.skill
	end
	local best = "attack"
	for _, k in { "strength", "defence" } do
		if (data.skills[k] or 0) < (data.skills[best] or 0) then
			best = k
		end
	end
	return best
end

return Combat
