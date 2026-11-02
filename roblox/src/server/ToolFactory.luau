-- Builds the tools the hero holds: sword, axe, pickaxe, fishing rod and the workbench saw.
-- They are Creator Store tools (ServerStorage.AssetPacks.Tools, saved in the place, credits in README.md), each one
-- already gripped in Studio to sit in a relaxed hand: Roblox's own tool pose (the arm held straight out in front) is
-- replaced by an empty one (HeroMotion), so the arm hangs and swings with the hero's idle and walk. The sword hangs at
-- the side with the blade down and forward, the axe and pickaxe stand up by the shoulder, the rod reaches out over the
-- water. The swings (Shared.Anims) are made for the tool held straight out of the forearm instead, so each template
-- also carries that grip as "ActGrip" and HeroMotion switches to it for a swing (as Roblox's ClassicSword does for its
-- lunge). Here a copy is named for its metal, and parts marked "Metal" (a shade, 1 = full) take the metal's colour.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local G = require(ReplicatedStorage:WaitForChild("Shared").Gathering)
local Combat = require(ReplicatedStorage.Shared.Combat)

local ToolFactory = {}

local TEMPLATE = { sword = "Sword", axe = "Axe", pick = "Pick", rod = "Rod", saw = "Saw" }
local TRAINING = Color3.fromHex("#c8a070") -- the wooden training sword (level -1)

-- without the pack: a plain wooden stick in the hand
local function stick(): Tool
	local tool = Instance.new("Tool")
	local h = Instance.new("Part")
	h.Name = "Handle"
	h.Size = Vector3.new(0.3, 3, 0.3)
	h.Color = Color3.fromRGB(120, 80, 45)
	h.Material = Enum.Material.Wood
	h.CanCollide = false
	h.CanQuery = false
	h.CanTouch = false
	h.Massless = true
	h.Parent = tool
	tool.Grip = CFrame.new(0, -1, 0)
	return tool
end

-- a glowing trail that follows the blade while it swings (HeroMotion switches it on) and sparks in the metal's colour,
-- more of them the better the metal
local function bladeEffects(blade: BasePart, handle: BasePart, color: Color3, level: number)
	local len = blade.Size.Y
	local side = blade.CFrame:PointToObjectSpace(handle.Position).Y < 0 and -1 or 1 -- the end nearest the hilt
	local a0 = Instance.new("Attachment")
	a0.Name = "TrailBase"
	a0.Position = Vector3.new(0, side * (len / 2 - 0.3), 0)
	a0.Parent = blade
	local a1 = Instance.new("Attachment")
	a1.Name = "TrailTip"
	a1.Position = Vector3.new(0, -side * len / 2, 0)
	a1.Parent = blade
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.3))
	trail.LightEmission = 0.7
	trail.Lifetime = 0.18
	trail.MinLength = 0.05
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	trail.FaceCamera = true
	trail.Enabled = false
	trail.Parent = blade
	if level < 0 then
		return
	end
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "Sparks"
	sparks.Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.4))
	sparks.LightEmission = 1
	sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) })
	sparks.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
	sparks.Lifetime = NumberRange.new(0.5, 0.9)
	sparks.Rate = 2 + level * 3
	sparks.Speed = NumberRange.new(0.3, 1)
	sparks.SpreadAngle = Vector2.new(180, 180)
	sparks.Shape = Enum.ParticleEmitterShape.Box
	sparks.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	sparks.Parent = blade
end

-- kind: "sword" | "axe" | "pick" | "rod" | "saw"; level: the metal tier (swords: Combat.METALS, -1 = the training
-- sword; tools: Gathering.METALS)
function ToolFactory.make(kind: string, level: number): Tool
	local packs = ServerStorage:FindFirstChild("AssetPacks")
	local src = packs and packs:FindFirstChild("Tools") and packs.Tools:FindFirstChild(TEMPLATE[kind])
	local tool = src and src:Clone() or stick()
	if kind == "sword" then
		tool.Name = level >= 0 and (Combat.METALS[level] .. " Sword") or "Training Sword"
	else
		tool.Name = G.toolName(kind, level)
	end
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool:SetAttribute("HoldGrip", tool.Grip)
	tool:SetAttribute("EndlessRoadTool", true)
	tool:SetAttribute("Kind", kind) -- HeroMotion picks the moves by this

	local metal = Color3.fromHex((kind == "sword" and Combat.METAL_COLORS or G.METAL_COLORS)[level] or G.METAL_COLORS[0])
	local wooden = kind == "sword" and level < 0
	for _, p in tool:GetDescendants() do
		local shade = p:IsA("BasePart") and p:GetAttribute("Metal")
		if shade then
			p.Color = (wooden and TRAINING or metal):Lerp(Color3.new(0, 0, 0), 1 - shade)
			p.Material = wooden and Enum.Material.Wood or Enum.Material.Metal
		end
	end
	if kind == "sword" then
		local blade = tool:FindFirstChild("Blade")
		if blade then
			bladeEffects(blade, tool.Handle, wooden and TRAINING or metal, level)
		end
		tool:SetAttribute("Weapon", true)
	end
	return tool
end

return ToolFactory
