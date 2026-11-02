-- Our own hero animations (built by AnimBuilder in Studio, uploaded to Roblox): ids by name, 0 = not uploaded yet.
-- HeroMotion plays an action for every swing, cast or saw stroke, and puts TOOL_NONE in place of Roblox's tool pose.
local Anims = {}

Anims.TOOL_NONE = 122117143323639 -- moves nothing: the arm holding a tool hangs and swings as it does without one

Anims.IDS = {
	SwordSlash = 133261795701381,
	SwordChop = 126650803505518,
	SwordThrust = 97245163340260,
	SwordSweep = 133346705921836,
	AxeChop = 104554036106006,
	PickSwing = 121462348989827,
	RodCast = 116336395077690,
	SawPush = 92263880436788,
}

-- by tool kind (ToolFactory): the moves to pick from for each action
Anims.ACT = {
	sword = { "SwordSlash", "SwordChop", "SwordThrust", "SwordSweep" },
	axe = { "AxeChop" },
	pick = { "PickSwing" },
	rod = { "RodCast" },
	saw = { "SawPush" },
}

return Anims
