-- The longsword every hero carries, and how it is held and swung. It is built from parts around its grip so
-- the hand closes on the grip itself. Every weapon model follows one rule: its Handle holds an Attachment
-- "GripPoint" where the fist closes, with +Y pointing up the blade and +Z out of the cutting edge. Tool.Grip is
-- worked out from that point, measured against Roblox's RightGripAttachment (which every avatar scales into its
-- palm), so any model that follows the rule sits in every hand the same way. Roblox's arm-straight-out tool pose
-- is swapped for our own OSRS stance, which holds only the right arm; swings are one-handed and played on the
-- server so everyone sees them.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)

local Sword = {}

local GRIP_LENGTH = 0.9
local GUARD = Vector3.new(0.26, 0.18, 1.15)
local BLADE = Vector3.new(0.08, 2.6, 0.3)
local TIP = 0.45
local HOLD_TILT = math.rad(20) -- the blade's tip dips this much below the line of the fist
local HOLD_ROLL = math.rad(40) -- the blade turned on its own axis so the camera behind the hero sees its flat, not its edge

local tracks = {} -- [Animator] = { [name] = AnimationTrack }

local function piece(tool: Tool, handle: BasePart, name: string, props: { [string]: any }, offset: CFrame)
	local p = Instance.new(props.Class or "Part")
	p.Name = name
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		if k ~= "Class" then
			p[k] = v
		end
	end
	p.CFrame = handle.CFrame * offset
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = p
	weld.Parent = p
	p.Parent = tool
	return p
end

-- sets Tool.Grip from the model's GripPoint (see the top of this file)
function Sword.fit(tool: Tool)
	local handle = tool:FindFirstChild("Handle")
	local point = handle and handle:FindFirstChild("GripPoint")
	if point and point:IsA("Attachment") then
		tool.Grip = point.CFrame * CFrame.Angles(HOLD_TILT, 0, 0) * CFrame.Angles(0, HOLD_ROLL, 0)
	end
end

function Sword.make(): Tool
	local cfg = Config.SWORD
	local tool = Instance.new("Tool")
	tool.Name = cfg.name
	tool.ToolTip = cfg.name
	tool.CanBeDropped = false

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.2, GRIP_LENGTH, 0.2)
	handle.Color = Color3.fromRGB(74, 48, 32)
	handle.Material = Enum.Material.Fabric
	handle.CanCollide = false
	handle.CanQuery = false
	handle.Massless = true
	handle.CFrame = CFrame.new()
	handle.Parent = tool

	local metal = cfg.color
	local top = GRIP_LENGTH / 2
	piece(tool, handle, "Guard", { Size = GUARD, Color = metal, Material = Enum.Material.Metal }, CFrame.new(0, top + GUARD.Y / 2, 0))
	local bladeBase = top + GUARD.Y
	piece(tool, handle, "Blade", { Size = BLADE, Color = metal, Material = Enum.Material.Metal, Reflectance = 0.2 },
		CFrame.new(0, bladeBase + BLADE.Y / 2, 0))
	-- a fuller (the groove down the middle of the blade)
	piece(tool, handle, "Fuller", { Size = Vector3.new(BLADE.X + 0.02, BLADE.Y * 0.7, 0.07), Color = metal:Lerp(Color3.new(0, 0, 0), 0.25), Material = Enum.Material.Metal },
		CFrame.new(0, bladeBase + BLADE.Y * 0.38, 0))
	-- the point: two wedges meeting on the blade's centre line
	local tipY = bladeBase + BLADE.Y + TIP / 2
	local tipSize = Vector3.new(BLADE.X, TIP, BLADE.Z / 2)
	piece(tool, handle, "Tip", { Class = "WedgePart", Size = tipSize, Color = metal, Material = Enum.Material.Metal }, CFrame.new(0, tipY, -BLADE.Z / 4))
	piece(tool, handle, "Tip", { Class = "WedgePart", Size = tipSize, Color = metal, Material = Enum.Material.Metal },
		CFrame.new(0, tipY, BLADE.Z / 4) * CFrame.Angles(0, math.pi, 0))
	piece(tool, handle, "Pommel", { Shape = Enum.PartType.Ball, Size = Vector3.new(0.3, 0.3, 0.3), Color = metal, Material = Enum.Material.Metal },
		CFrame.new(0, -top - 0.1, 0))

	-- the tip of the blade, for the swing trail
	local a0 = Instance.new("Attachment")
	a0.Name = "TrailBase"
	a0.Position = Vector3.new(0, bladeBase + 0.3, 0)
	a0.Parent = handle
	local a1 = Instance.new("Attachment")
	a1.Name = "TrailTip"
	a1.Position = Vector3.new(0, tipY + TIP / 2, 0)
	a1.Parent = handle
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Lifetime = 0.14
	trail.MinLength = 0.05
	trail.FaceCamera = true
	trail.Color = ColorSequence.new(Color3.fromRGB(255, 244, 220))
	trail.Transparency = NumberSequence.new(0.35, 1)
	trail.LightEmission = 0.4
	trail.Enabled = false
	trail.Parent = handle

	-- the fist closes on the middle of the grip
	local point = Instance.new("Attachment")
	point.Name = "GripPoint"
	point.Parent = handle
	Sword.fit(tool)
	return tool
end

local function animatorOf(char: Model?)
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	return hum and hum:FindFirstChildOfClass("Animator")
end

local function track(animator: Animator, name: string, id: number)
	tracks[animator] = tracks[animator] or {}
	local t = tracks[animator][name]
	if not t then
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://" .. id
		local ok, loaded = pcall(animator.LoadAnimation, animator, anim)
		if not ok then
			return nil
		end
		t = loaded
		t.Priority = Enum.AnimationPriority.Action3 -- above the Action hold
		tracks[animator][name] = t
	end
	return t
end

-- one swing of the sword; returns the seconds until the blade lands
function Sword.swing(char: Model?): number
	local animator = animatorOf(char)
	if not animator then
		return Config.CONTACT
	end
	local id = Config.ANIM.Slash ~= 0 and Config.ANIM.Slash or Config.ANIM.RobloxSlash
	local t = track(animator, "Slash", id)
	if t then
		t:Play(0.05)
	end
	return Config.CONTACT
end

local function equip(player: Player, char: Model)
	local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
	if not hum then
		return
	end
	-- the OSRS stance in place of Roblox's tool pose: the Animate script picks up the changed animation
	task.spawn(function()
		local animate = char:WaitForChild("Animate", 10)
		local none = animate and animate:WaitForChild("toolnone", 10)
		if not none then
			return
		end
		local id = "rbxassetid://" .. Config.ANIM.Hold
		local function relax(a: Instance)
			if a:IsA("Animation") and a.AnimationId ~= id then
				a.AnimationId = id
			end
		end
		for _, a in none:GetChildren() do
			relax(a)
		end
		none.ChildAdded:Connect(relax)
	end)
	-- an avatar that changes size after spawning (a new outfit or body scale) moves its grip point; the hand's weld
	-- follows it so the sword stays in the fist
	local hand = char:WaitForChild("RightHand", 10)
	local point = hand and hand:WaitForChild("RightGripAttachment", 10) :: Attachment?
	if point then
		point:GetPropertyChangedSignal("CFrame"):Connect(function()
			local weld = hand:FindFirstChild("RightGrip")
			if weld and weld:IsA("Weld") then
				weld.C0 = point.CFrame
			end
		end)
	end
	local tool = Sword.make()
	tool.Parent = player:WaitForChild("Backpack")
	hum:EquipTool(tool)
	char.Destroying:Connect(function()
		local animator = hum:FindFirstChildOfClass("Animator")
		if animator then
			tracks[animator] = nil
		end
	end)
end

function Sword.init()
	local function hook(player: Player)
		player.CharacterAdded:Connect(function(char)
			equip(player, char)
		end)
		if player.Character then
			task.spawn(equip, player, player.Character)
		end
	end
	for _, p in Players:GetPlayers() do
		hook(p)
	end
	Players.PlayerAdded:Connect(hook)
end

return Sword
