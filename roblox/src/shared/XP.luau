-- RuneScape/Melvor style XP curve, ported 1:1 from the web game (XP_TABLE / levelFromXp)
local XP = {}

XP.MAX_LEVEL = 99

local TABLE = { [1] = 0 }
do
	local pts = 0
	for l = 1, 98 do
		pts += math.floor(l + 300 * 2 ^ (l / 7))
		TABLE[l + 1] = math.floor(pts / 4)
	end
end
XP.TABLE = TABLE

function XP.levelFromXp(xp: number): number
	local l = 1
	while l < XP.MAX_LEVEL and xp >= TABLE[l + 1] do
		l += 1
	end
	return l
end

function XP.xpForLevel(level: number): number
	return TABLE[math.clamp(level, 1, XP.MAX_LEVEL)]
end

-- level, fraction of the way to the next level (0..1), xp still needed
function XP.progress(xp: number): (number, number, number)
	local l = XP.levelFromXp(xp)
	if l >= XP.MAX_LEVEL then
		return l, 1, 0
	end
	local a, b = TABLE[l], TABLE[l + 1]
	return l, (xp - a) / (b - a), b - xp
end

return XP
