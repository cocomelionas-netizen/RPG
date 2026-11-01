-- One rarity ladder for everything: node rings and labels in the world, item borders in the bag.
-- Tier 0 is the starter resource, higher tiers are rarer and need higher levels.
local Tiers = {}

Tiers.COLORS = {
	[0] = Color3.fromRGB(205, 205, 215), -- common: white/grey
	Color3.fromRGB(100, 215, 100), -- green
	Color3.fromRGB(80, 160, 255), -- blue
	Color3.fromRGB(185, 105, 255), -- purple
	Color3.fromRGB(255, 165, 40), -- orange
	Color3.fromRGB(255, 80, 80), -- red
	Color3.fromRGB(70, 235, 235), -- cyan
}

function Tiers.color(tier: number?): Color3
	return Tiers.COLORS[tier or 0] or Tiers.COLORS[0]
end

return Tiers
