-- A Studio tool, never used by the running game: builds the hero's tool animations as KeyframeSequences in
-- ServerStorage.Animations (R15). In Studio (edit mode): require(game.ServerScriptService.Server.AnimBuilder)(),
-- preview, then right-click each one > Save / Export > Save to Roblox and put the ids in src/shared/Anims.luau.
--
-- Joint turns are in degrees, { x, y, z } = CFrame.Angles on the joint:
--   arms: x+ raises the arm forward, z+ takes the right arm out to the side (z- across the body; mirrored for the left)
--   elbows (LowerArm): x+ bends the forearm up; torso: y+ turns left, x- leans forward
-- The tools sit in the right hand pointing along the forearm, so the forearm's angle aims the sword, axe or pick.
-- Measured on the rig: forearm angle = upper arm x + elbow x + 25 (0 = down, 90 = forward, 180 = up, 270 = back).

local DEFS = {}

-- poses reused below
-- the sword held low, the arm hanging relaxed at the side, blade pointing down and a little forward (like the katana games)
local SWORD_GUARD = { RightUpperArm = { 2, 0, 12 }, RightLowerArm = { 8, 0, 0 }, RightHand = { 38, 0, 0 }, LeftUpperArm = { 4, 0, -6 }, LeftLowerArm = { 10, 0, 0 } }
local function with(base, extra)
	local t = table.clone(base)
	for k, v in extra do
		t[k] = v
	end
	return t
end

-- ===== sword =====
DEFS.SwordHold = { loop = true, priority = "Action", keys = {
	{ 0, SWORD_GUARD },
	{ 1.2, with(SWORD_GUARD, { RightUpperArm = { 5, 0, 12 }, RightLowerArm = { 11, 0, 0 }, RightHand = { 34, 0, 0 } }) },
	{ 2.4, SWORD_GUARD },
} }

-- 1: diagonal slash from over the right shoulder down across the body
DEFS.SwordSlash = { priority = "Action2", keys = {
	{ 0, SWORD_GUARD },
	{ 0.14, { UpperTorso = { 0, -25, 0 }, LowerTorso = { 0, -6, 0 }, RightUpperArm = { 150, 0, 30 }, RightLowerArm = { 20, 0, 0 }, RightHand = { 0, 0, 0 }, LeftUpperArm = { 40, 0, -25 }, LeftLowerArm = { 40, 0, 0 } } },
	{ 0.25, { UpperTorso = { -10, 28, 0 }, LowerTorso = { -6, 8, 0 }, RightUpperArm = { 55, 0, -35 }, RightLowerArm = { 5, 0, 0 }, RightHand = { 10, 0, 0 }, LeftUpperArm = { 10, 0, -35 }, LeftLowerArm = { 20, 0, 0 } } },
	{ 0.33, { UpperTorso = { -8, 32, 0 }, LowerTorso = { -4, 10, 0 }, RightUpperArm = { 25, 0, -45 }, RightLowerArm = { 10, 0, 0 }, RightHand = { 0, 0, 0 }, LeftUpperArm = { 5, 0, -35 }, LeftLowerArm = { 20, 0, 0 } } },
	{ 0.62, SWORD_GUARD },
} }

-- 2: overhead chop straight down
DEFS.SwordChop = { priority = "Action2", keys = {
	{ 0, SWORD_GUARD },
	{ 0.16, { UpperTorso = { 10, 0, 0 }, LowerTorso = { 4, 0, 0 }, RightUpperArm = { 150, 0, 8 }, RightLowerArm = { 25, 0, 0 }, RightHand = { 0, 0, 0 }, LeftUpperArm = { 140, 0, 15 }, LeftLowerArm = { 25, 0, 0 } } },
	{ 0.27, { UpperTorso = { -22, 0, 0 }, LowerTorso = { -8, 0, 0 }, RightUpperArm = { 70, 0, -5 }, RightLowerArm = { 0, 0, 0 }, RightHand = { 15, 0, 0 }, LeftUpperArm = { 55, 0, 15 }, LeftLowerArm = { 10, 0, 0 } } },
	{ 0.36, { UpperTorso = { -24, 0, 0 }, LowerTorso = { -9, 0, 0 }, RightUpperArm = { 50, 0, -5 }, RightLowerArm = { 0, 0, 0 }, RightHand = { 15, 0, 0 }, LeftUpperArm = { 40, 0, 15 }, LeftLowerArm = { 10, 0, 0 } } },
	{ 0.68, SWORD_GUARD },
} }

-- 3: stab: pull back, then a straight thrust with a lean
DEFS.SwordThrust = { priority = "Action2", keys = {
	{ 0, SWORD_GUARD },
	{ 0.15, { UpperTorso = { 6, -30, 0 }, LowerTorso = { 0, -10, 0 }, RightUpperArm = { -30, 0, 15 }, RightLowerArm = { 95, 0, 0 }, RightHand = { 0, 0, 0 }, LeftUpperArm = { 60, 0, -20 }, LeftLowerArm = { 30, 0, 0 } } },
	{ 0.24, { UpperTorso = { -15, 20, 0 }, LowerTorso = { -8, 8, 0 }, RightUpperArm = { 70, 0, -5 }, RightLowerArm = { 0, 0, 0 }, RightHand = { 0, 0, 0 }, LeftUpperArm = { 0, 0, -30 }, LeftLowerArm = { 20, 0, 0 } } },
	{ 0.34, { UpperTorso = { -16, 22, 0 }, LowerTorso = { -8, 8, 0 }, RightUpperArm = { 68, 0, -5 }, RightLowerArm = { 0, 0, 0 }, RightHand = { 0, 0, 0 }, LeftUpperArm = { 0, 0, -30 }, LeftLowerArm = { 20, 0, 0 } } },
	{ 0.62, SWORD_GUARD },
} }

-- 4: a wide sweep from the right all the way round to the left
DEFS.SwordSweep = { priority = "Action2", keys = {
	{ 0, SWORD_GUARD },
	{ 0.15, { UpperTorso = { 0, -45, 0 }, LowerTorso = { 0, -15, 0 }, RightUpperArm = { 75, 0, 75 }, RightLowerArm = { 0, 0, 0 }, RightHand = { 0, 0, 0 }, LeftUpperArm = { 30, 0, -20 }, LeftLowerArm = { 30, 0, 0 } } },
	{ 0.27, { UpperTorso = { -5, 15, 0 }, LowerTorso = { 0, 5, 0 }, RightUpperArm = { 70, 0, 0 }, RightLowerArm = { 0, 0, 0 }, RightHand = { 0, 0, 0 }, LeftUpperArm = { 10, 0, -40 }, LeftLowerArm = { 10, 0, 0 } } },
	{ 0.36, { UpperTorso = { -5, 45, 0 }, LowerTorso = { 0, 15, 0 }, RightUpperArm = { 68, 0, -55 }, RightLowerArm = { 0, 0, 0 }, RightHand = { 0, 0, 0 }, LeftUpperArm = { 5, 0, -50 }, LeftLowerArm = { 10, 0, 0 } } },
	{ 0.66, SWORD_GUARD },
} }

-- ===== axe: rest it on the shoulder, chop sideways into the trunk =====
local AXE_REST = { RightUpperArm = { 25, 0, 10 }, RightLowerArm = { 120, 0, 0 }, RightHand = { 0, 0, 0 }, LeftUpperArm = { 10, 0, -8 }, LeftLowerArm = { 20, 0, 0 } }
DEFS.AxeHold = { loop = true, priority = "Action", keys = { { 0, AXE_REST }, { 1.5, with(AXE_REST, { RightLowerArm = { 115, 0, 0 } }) }, { 3, AXE_REST } } }
DEFS.AxeChop = { priority = "Action2", keys = {
	{ 0, AXE_REST },
	{ 0.3, { UpperTorso = { 0, -40, 0 }, LowerTorso = { 0, -12, 0 }, RightUpperArm = { 95, 0, 70 }, RightLowerArm = { 40, 0, 0 }, RightHand = { 0, 0, 0 }, LeftUpperArm = { 80, 0, 10 }, LeftLowerArm = { 50, 0, 0 } } },
	{ 0.42, { UpperTorso = { -6, 20, 0 }, LowerTorso = { 0, 6, 0 }, RightUpperArm = { 70, 0, -10 }, RightLowerArm = { 0, 0, 0 }, RightHand = { 0, 0, 0 }, LeftUpperArm = { 70, 0, 25 }, LeftLowerArm = { 15, 0, 0 } } },
	{ 0.5, { UpperTorso = { -6, 22, 0 }, LowerTorso = { 0, 7, 0 }, RightUpperArm = { 67, 0, -12 }, RightLowerArm = { 0, 0, 0 }, RightHand = { 0, 0, 0 }, LeftUpperArm = { 68, 0, 25 }, LeftLowerArm = { 15, 0, 0 } } },
	{ 0.85, AXE_REST },
} }

-- ===== pickaxe: both hands up over the head, swing down onto the rock =====
local PICK_REST = { RightUpperArm = { 35, 0, 10 }, RightLowerArm = { 70, 0, 0 }, RightHand = { 0, 0, 0 }, LeftUpperArm = { 35, 0, 15 }, LeftLowerArm = { 70, 0, 0 } }
DEFS.PickHold = { loop = true, priority = "Action", keys = { { 0, PICK_REST }, { 1.5, with(PICK_REST, { RightUpperArm = { 38, 0, 10 } }) }, { 3, PICK_REST } } }
DEFS.PickSwing = { priority = "Action2", keys = {
	{ 0, PICK_REST },
	{ 0.32, { UpperTorso = { 12, 0, 0 }, LowerTorso = { 4, 0, 0 }, RightUpperArm = { 150, 0, 10 }, RightLowerArm = { 40, 0, 0 }, RightHand = { 0, 0, 0 }, LeftUpperArm = { 145, 0, 20 }, LeftLowerArm = { 40, 0, 0 } } },
	{ 0.44, { UpperTorso = { -28, 0, 0 }, LowerTorso = { -10, 0, 0 }, RightUpperArm = { 55, 0, 0 }, RightLowerArm = { 0, 0, 0 }, RightHand = { 20, 0, 0 }, LeftUpperArm = { 50, 0, 20 }, LeftLowerArm = { 5, 0, 0 } } },
	{ 0.52, { UpperTorso = { -30, 0, 0 }, LowerTorso = { -11, 0, 0 }, RightUpperArm = { 48, 0, 0 }, RightLowerArm = { 0, 0, 0 }, RightHand = { 20, 0, 0 }, LeftUpperArm = { 45, 0, 20 }, LeftLowerArm = { 5, 0, 0 } } },
	{ 0.85, PICK_REST },
} }

-- ===== fishing rod: hold it out over the water with a gentle bob; cast when a fish is caught =====
local ROD_HOLD = { RightUpperArm = { 18, 0, 8 }, RightLowerArm = { 10, 0, 0 }, RightHand = { 0, 0, 0 }, LeftUpperArm = { 25, 0, 20 }, LeftLowerArm = { 45, 0, 0 } }
DEFS.RodHold = { loop = true, priority = "Action", keys = {
	{ 0, ROD_HOLD },
	{ 1, with(ROD_HOLD, { RightUpperArm = { 21, 0, 8 }, RightHand = { -5, 0, 0 } }) },
	{ 2, ROD_HOLD },
} }
DEFS.RodCast = { priority = "Action2", keys = {
	{ 0, ROD_HOLD },
	{ 0.3, { UpperTorso = { 10, -10, 0 }, RightUpperArm = { 140, 0, 10 }, RightLowerArm = { 40, 0, 0 }, RightHand = { 0, 0, 0 }, LeftUpperArm = { 60, 0, 20 }, LeftLowerArm = { 50, 0, 0 } } },
	{ 0.45, { UpperTorso = { -12, 8, 0 }, RightUpperArm = { 40, 0, 5 }, RightLowerArm = { 5, 0, 0 }, RightHand = { 5, 0, 0 }, LeftUpperArm = { 30, 0, 20 }, LeftLowerArm = { 45, 0, 0 } } },
	{ 0.9, ROD_HOLD },
} }

-- ===== saw at the workbench: push and pull =====
local SAW_REST = { RightUpperArm = { 45, 0, 5 }, RightLowerArm = { 55, 0, 0 }, RightHand = { 0, 0, 0 }, LeftUpperArm = { 30, 0, 20 }, LeftLowerArm = { 70, 0, 0 }, UpperTorso = { -10, 0, 0 } }
DEFS.SawHold = { loop = true, priority = "Action", keys = { { 0, SAW_REST }, { 2, SAW_REST } } }
DEFS.SawPush = { priority = "Action2", keys = {
	{ 0, SAW_REST },
	{ 0.25, with(SAW_REST, { RightUpperArm = { 75, 0, 5 }, RightLowerArm = { 10, 0, 0 }, UpperTorso = { -16, 0, 0 } }) },
	{ 0.5, with(SAW_REST, { RightUpperArm = { 35, 0, 5 }, RightLowerArm = { 80, 0, 0 } }) },
	{ 0.8, SAW_REST },
} }

-- ===== build =====
local PARENT = {
	LowerTorso = "HumanoidRootPart", UpperTorso = "LowerTorso", Head = "UpperTorso",
	RightUpperArm = "UpperTorso", RightLowerArm = "RightUpperArm", RightHand = "RightLowerArm",
	LeftUpperArm = "UpperTorso", LeftLowerArm = "LeftUpperArm", LeftHand = "LeftLowerArm",
}
local ORDER = { "LowerTorso", "UpperTorso", "Head", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperArm", "LeftLowerArm", "LeftHand" }

local function build(name, def)
	local joints = {}
	for _, k in def.keys do
		for j in k[2] do
			joints[j] = true
		end
	end
	-- the joints on the way up from every used joint must exist too (with no weight of their own)
	local chain = {}
	for j in joints do
		local p = PARENT[j]
		while p and p ~= "HumanoidRootPart" do
			chain[p] = true
			p = PARENT[p]
		end
	end
	local ks = Instance.new("KeyframeSequence")
	ks.Name = name
	ks.Loop = def.loop == true
	ks.Priority = Enum.AnimationPriority[def.priority]
	for _, k in def.keys do
		local kf = Instance.new("Keyframe")
		kf.Time = k[1]
		local poses = {}
		local root = Instance.new("Pose")
		root.Name = "HumanoidRootPart"
		root.Weight = 0
		root.Parent = kf
		poses.HumanoidRootPart = root
		for _, j in ORDER do
			if joints[j] or chain[j] then
				local pose = Instance.new("Pose")
				pose.Name = j
				local a = k[2][j]
				if a then
					pose.CFrame = CFrame.Angles(math.rad(a[1]), math.rad(a[2]), math.rad(a[3]))
					pose.Weight = 1
				elseif joints[j] then
					pose.Weight = 1 -- used elsewhere in this animation: back to rest here
				else
					pose.Weight = 0
				end
				pose.EasingStyle = Enum.PoseEasingStyle.Cubic
				pose.EasingDirection = Enum.PoseEasingDirection.InOut
				pose.Parent = poses[PARENT[j]]
				poses[j] = pose
			end
		end
		kf.Parent = ks
	end
	return ks
end

return function()
	local folder = game:GetService("ServerStorage"):FindFirstChild("Animations") or Instance.new("Folder")
	folder.Name = "Animations"
	folder.Parent = game:GetService("ServerStorage")
	local made = {}
	for name, def in DEFS do
		local old = folder:FindFirstChild(name)
		if old then
			old:Destroy()
		end
		build(name, def).Parent = folder
		table.insert(made, name)
	end
	table.sort(made)
	return table.concat(made, ", ")
end
