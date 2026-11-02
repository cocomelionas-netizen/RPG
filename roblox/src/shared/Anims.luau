-- Our own hero animations (built by AnimBuilder in Studio, uploaded to Roblox): ids by name, 0 = not uploaded yet.
-- HeroMotion plays a hold pose while a tool is in hand and an action for every swing, cast or saw stroke.
local Anims = {}

Anims.IDS = {
	SwordHold = 96123493076913,
	SwordSlash = 133261795701381,
	SwordChop = 126650803505518,
	SwordThrust = 97245163340260,
	SwordSweep = 133346705921836,
	AxeHold = 129138592230681,
	AxeChop = 104554036106006,
	PickHold = 120818175822033,
	PickSwing = 121462348989827,
	RodHold = 81280362995248,
	RodCast = 116336395077690,
	SawHold = 127245151828481,
	SawPush = 92263880436788,
}

-- by tool kind (ToolFactory): the pose while holding it, and the moves to pick from for each action
Anims.HOLD = { sword = "SwordHold", axe = "AxeHold", pick = "PickHold", rod = "RodHold", saw = "SawHold" }
Anims.ACT = {
	sword = { "SwordSlash", "SwordChop", "SwordThrust", "SwordSweep" },
	axe = { "AxeChop" },
	pick = { "PickSwing" },
	rod = { "RodCast" },
	saw = { "SawPush" },
}

return Anims
