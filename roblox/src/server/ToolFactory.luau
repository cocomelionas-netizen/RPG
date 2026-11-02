-- Builds the axe / pickaxe / fishing rod the hero holds while gathering (plain Parts, no uploaded assets)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local G = require(ReplicatedStorage:WaitForChild("Shared").Gathering)
local Combat = require(ReplicatedStorage.Shared.Combat)

local ToolFactory = {}

local function part(name, size, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	return p
end

local function attach(handle, p, offset)
	p.CFrame = handle.CFrame * offset
	local w = Instance.new("WeldConstraint")
	w.Part0 = handle
	w.Part1 = p
	w.Parent = p
	p.Parent = handle.Parent
end

-- the tool models (ServerStorage.AssetPacks.Weapons: Sword, Axe, Pick, Rod, made with Roblox's mesh generator) stand
-- upright with the working end at the top (the sword's blade points down). Returns a copy scaled to length `len`
-- as the handle, or nil when the pack is missing (the tool is then built from plain parts).
local function meshHandle(name: string, len: number): BasePart?
	local packs = ServerStorage:FindFirstChild("AssetPacks")
	local src = packs and packs:FindFirstChild("Weapons") and packs.Weapons:FindFirstChild(name)
	if not src then
		return nil
	end
	local h = src:Clone()
	h.Name = "Handle"
	h.Size *= len / h.Size.Y
	h.CanCollide = false
	h.CanQuery = false
	h.CanTouch = false
	h.Massless = true
	h.Anchored = false
	return h
end

-- held near the bottom of the handle, the head pointing forward and a little up (the sword model is upside down);
-- tilt < 0 raises the head further (the rod reaches out over the water)
local function gripFor(len: number, headDown: boolean?, tilt: number?): CFrame
	if headDown then
		return CFrame.new(0, len / 2 - 0.7, 0) * CFrame.Angles(math.rad(-110 + (tilt or 0)), 0, 0)
	end
	return CFrame.new(0, -len / 2 + 0.8, 0) * CFrame.Angles(math.rad(70 + (tilt or 0)), 0, 0)
end

-- kind: "axe" | "pick" | "rod" | "saw" | "sword"; level: 0..6 (metal tier), -1 = the training sword
function ToolFactory.make(kind: string, level: number): Tool
	local metal = Color3.fromHex(G.METAL_COLORS[level] or G.METAL_COLORS[0])
	local wood = Color3.fromRGB(120, 80, 45)

	local tool = Instance.new("Tool")
	tool.Name = kind == "sword" and "Sword" or G.toolName(kind, level)
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool:SetAttribute("EndlessRoadTool", true)
	tool:SetAttribute("Kind", kind) -- HeroMotion picks the hold pose and moves by this

	local len = kind == "rod" and 6 or (kind == "saw" or kind == "sword") and 1.2 or 3
	local handle = part("Handle", Vector3.new(0.3, len, 0.3), wood, Enum.Material.Wood)
	handle.CFrame = CFrame.new(0, 50, 0)
	handle.Parent = tool

	if kind == "sword" then
		-- the sword model (ServerStorage.AssetPacks.Weapons.Sword, made with Roblox's mesh generator) is the handle;
		-- the metal shows in a glowing trail that follows the blade when it swings. Level -1 is the wooden training sword.
		local metalHex = Combat.METAL_COLORS[level] or "#c8a070"
		tool.Name = level >= 0 and (Combat.METALS[level] .. " Sword") or "Training Sword"
		local len = 6.2
		local mesh = meshHandle("Sword", len)
		if mesh then
			handle:Destroy()
			handle = mesh
			handle.Parent = tool
		else
			handle.Size = Vector3.new(0.35, len, 0.35)
			handle.Color = Color3.fromHex(metalHex)
			handle.Material = Enum.Material.Metal
		end
		local a0 = Instance.new("Attachment")
		a0.Name = "TrailBase"
		a0.Position = Vector3.new(0, len / 2 - 1.4, 0) -- the model's grip is at its top end, the tip at the bottom
		a0.Parent = handle
		local a1 = Instance.new("Attachment")
		a1.Name = "TrailTip"
		a1.Position = Vector3.new(0, -len / 2, 0)
		a1.Parent = handle
		local trail = Instance.new("Trail")
		trail.Attachment0 = a0
		trail.Attachment1 = a1
		trail.Color = ColorSequence.new(Color3.fromHex(metalHex):Lerp(Color3.new(1, 1, 1), 0.3))
		trail.LightEmission = 0.7
		trail.Lifetime = 0.18
		trail.MinLength = 0.05
		trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		trail.FaceCamera = true
		trail.Enabled = false -- only while the blade swings (HeroMotion)
		trail.Parent = handle
		-- sparks drifting off the blade in the metal's colour, more of them the better the metal
		local sparks = Instance.new("ParticleEmitter")
		sparks.Name = "Sparks"
		sparks.Color = ColorSequence.new(Color3.fromHex(metalHex):Lerp(Color3.new(1, 1, 1), 0.4))
		sparks.LightEmission = 1
		sparks.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
		sparks.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
		sparks.Lifetime = NumberRange.new(0.5, 0.9)
		sparks.Rate = 4 + math.max(0, level) * 4
		sparks.Speed = NumberRange.new(0.5, 1.5)
		sparks.SpreadAngle = Vector2.new(180, 180)
		sparks.Shape = Enum.ParticleEmitterShape.Box
		sparks.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
		sparks.Parent = handle
		tool.Grip = gripFor(len, true)
		tool:SetAttribute("Weapon", true)
	elseif kind == "axe" or kind == "pick" or kind == "rod" then
		local name = ({ axe = "Axe", pick = "Pick", rod = "Rod" })[kind]
		local toolLen = kind == "rod" and 7 or 4
		local mesh = meshHandle(name, toolLen)
		if mesh then
			handle:Destroy()
			handle = mesh
			handle.Parent = tool
			-- the metal tier shows as a tint on the head (the mesh's own texture stays underneath)
			if kind ~= "rod" then
				handle.Color = metal
			end
			tool.Grip = gripFor(toolLen, false, kind == "rod" and -25 or 0)
		elseif kind == "axe" then
			attach(handle, part("Head", Vector3.new(0.25, 0.8, 1.1), metal, Enum.Material.Metal), CFrame.new(0, len / 2 - 0.4, -0.5))
			tool.Grip = CFrame.new(0, -1, 0)
		elseif kind == "pick" then
			attach(handle, part("Head", Vector3.new(0.25, 0.3, 2.4), metal, Enum.Material.Metal), CFrame.new(0, len / 2 - 0.15, 0))
			tool.Grip = CFrame.new(0, -1, 0)
		else
			handle.Size = Vector3.new(0.18, len, 0.18)
			attach(handle, part("Reel", Vector3.new(0.35, 0.35, 0.35), metal, Enum.Material.Metal), CFrame.new(0.2, -len / 2 + 1, 0))
			attach(handle, part("Tip", Vector3.new(0.1, 0.6, 0.1), metal, Enum.Material.Metal), CFrame.new(0, len / 2 + 0.3, 0))
			tool.Grip = (CFrame.Angles(math.rad(-40), 0, 0) * CFrame.new(0, 2.5, 0)):Inverse()
		end
	elseif kind == "saw" then
		attach(handle, part("Blade", Vector3.new(0.08, 0.9, 2.6), metal, Enum.Material.Metal), CFrame.new(0, 0.2, -1.4))
		tool.Grip = CFrame.new(0, -0.3, 0)
	end
	return tool
end

return ToolFactory
