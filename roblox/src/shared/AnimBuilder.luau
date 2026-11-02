-- Studio tool: builds the hero's own animations as KeyframeSequences (R15). Run in the Studio command bar:
--   require(game.ReplicatedStorage.Shared.AnimBuilder).save()
-- then right-click each one in ServerStorage.Animations > Save to Roblox and put its id in Config.ANIM.
-- In a play test, AnimBuilder.preview(name) registers a temporary copy and returns its id to try it out.
-- Poses are degrees around each joint's own axes: X raises an arm forward, +Z swings the right arm out to the
-- side (-Z across the body), +Y turns the torso to the left, -X on the hand tips the blade down (a hanging
-- fist holds it level, so -90 lines it up with the forearm). Keys: { time, poses, easing, marker? }.
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

local AnimBuilder = {}

local PARENTS = {
	LowerTorso = "HumanoidRootPart",
	UpperTorso = "LowerTorso",
	Head = "UpperTorso",
	RightUpperArm = "UpperTorso",
	RightLowerArm = "RightUpperArm",
	RightHand = "RightLowerArm",
	LeftUpperArm = "UpperTorso",
	LeftLowerArm = "LeftUpperArm",
	LeftHand = "LeftLowerArm",
	RightUpperLeg = "LowerTorso",
	LeftUpperLeg = "LowerTorso",
}

local REST = {}

-- one-handed slash, right hand only: the blade goes back over the shoulder, holds for a beat, then comes down hard
-- in front of the hero (low enough for a rat) and follows through across the body before settling
local SLASH = {
	{ 0, REST, "Out" },
	{ 0.2, {
		LowerTorso = { 0, -8, 0 },
		UpperTorso = { 4, -26, 0 },
		RightUpperArm = { 150, 0, 18 },
		RightLowerArm = { 50, 0, 0 },
		RightHand = { -25, 0, 0 },
		LeftUpperArm = { 18, 0, -8 },
		Head = { 0, 14, 0 },
	}, "Out", "Swish" },
	{ 0.25, {
		LowerTorso = { 0, -9, 0 },
		UpperTorso = { 6, -28, 0 },
		RightUpperArm = { 156, 0, 20 },
		RightLowerArm = { 54, 0, 0 },
		RightHand = { -28, 0, 0 },
		LeftUpperArm = { 20, 0, -8 },
		Head = { 0, 15, 0 },
	}, "In" },
	{ 0.33, {
		LowerTorso = { 0, 6, 0 },
		UpperTorso = { -10, 18, 0 },
		RightUpperArm = { 55, 0, -22 },
		RightLowerArm = { 0, 0, 0 },
		RightHand = { -65, 0, 0 },
		LeftUpperArm = { -14, 0, -6 },
		Head = { 6, -8, 0 },
	}, "Out", "Hit" },
	{ 0.46, {
		LowerTorso = { 0, 9, 0 },
		UpperTorso = { -12, 26, 0 },
		RightUpperArm = { 28, 0, -38 },
		RightLowerArm = { 10, 0, 0 },
		RightHand = { -70, 0, 0 },
		LeftUpperArm = { -18, 0, -6 },
		Head = { 4, -10, 0 },
	}, "InOut" },
	{ 0.8, REST, "InOut" },
}

AnimBuilder.MOVES = {
	Slash = { keys = SLASH, priority = Enum.AnimationPriority.Action },
}

local EASING = {
	Out = Enum.PoseEasingStyle.Cubic,
	In = Enum.PoseEasingStyle.Cubic,
	InOut = Enum.PoseEasingStyle.Cubic,
	Linear = Enum.PoseEasingStyle.Linear,
}
local DIRECTION = {
	Out = Enum.PoseEasingDirection.Out,
	In = Enum.PoseEasingDirection.In,
	InOut = Enum.PoseEasingDirection.InOut,
	Linear = Enum.PoseEasingDirection.In,
}

local function pose(name: string, deg: { number }?, easing: string)
	local p = Instance.new("Pose")
	p.Name = name
	p.Weight = 1
	if deg then
		p.CFrame = CFrame.Angles(math.rad(deg[1]), math.rad(deg[2]), math.rad(deg[3]))
	end
	p.EasingStyle = EASING[easing]
	p.EasingDirection = DIRECTION[easing]
	return p
end

function AnimBuilder.build(name: string): KeyframeSequence
	local move = AnimBuilder.MOVES[name]
	local seq = Instance.new("KeyframeSequence")
	seq.Name = name
	seq.Loop = move.loop == true
	seq.Priority = move.priority
	for _, k in move.keys do
		local kf = Instance.new("Keyframe")
		kf.Time = k[1]
		local poses = { HumanoidRootPart = pose("HumanoidRootPart", nil, k[3]) }
		-- every joint the move uses is keyed in every frame, so nothing drifts between keys
		for joint, parent in PARENTS do
			local used = false
			for _, other in move.keys do
				if other[2][joint] then
					used = true
				end
			end
			if used then
				poses[joint] = pose(joint, k[2][joint] or { 0, 0, 0 }, k[3])
			end
		end
		-- nest each pose under its parent's, creating untouched parents as needed
		local function attach(joint: string)
			local parent = PARENTS[joint]
			if not parent then
				return
			end
			if not poses[parent] then
				local p = pose(parent, nil, k[3])
				p.Weight = 0
				poses[parent] = p
			end
			attach(parent)
			poses[joint].Parent = poses[parent]
		end
		for joint in poses do
			attach(joint)
		end
		poses.HumanoidRootPart.Parent = kf
		if k[4] then
			local marker = Instance.new("KeyframeMarker")
			marker.Name = k[4]
			kf:AddMarker(marker)
		end
		kf.Parent = seq
	end
	return seq
end

-- builds every move into ServerStorage.Animations, ready to upload
function AnimBuilder.save()
	local folder = game:GetService("ServerStorage"):FindFirstChild("Animations") or Instance.new("Folder")
	folder.Name = "Animations"
	folder.Parent = game:GetService("ServerStorage")
	for name in AnimBuilder.MOVES do
		local old = folder:FindFirstChild(name)
		if old then
			old:Destroy()
		end
		AnimBuilder.build(name).Parent = folder
	end
	return folder
end

function AnimBuilder.preview(name: string): string
	return KeyframeSequenceProvider:RegisterKeyframeSequence(AnimBuilder.build(name))
end

return AnimBuilder
