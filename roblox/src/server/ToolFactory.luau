-- Builds the axe / pickaxe / fishing rod the hero holds while gathering (plain Parts, no uploaded assets)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local G = require(ReplicatedStorage:WaitForChild("Shared").Gathering)

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

-- kind: "axe" | "pick" | "rod" | "saw"; level: 0..4 (metal tier)
function ToolFactory.make(kind: string, level: number): Tool
	local metal = Color3.fromHex(G.METAL_COLORS[level] or G.METAL_COLORS[0])
	local wood = Color3.fromRGB(120, 80, 45)

	local tool = Instance.new("Tool")
	tool.Name = G.toolName(kind, level)
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool:SetAttribute("EndlessRoadTool", true)

	local len = kind == "rod" and 6 or kind == "saw" and 1.2 or 3
	local handle = part("Handle", Vector3.new(0.3, len, 0.3), wood, Enum.Material.Wood)
	handle.CFrame = CFrame.new(0, 50, 0)
	handle.Parent = tool

	if kind == "saw" then
		attach(handle, part("Blade", Vector3.new(0.08, 0.9, 2.6), metal, Enum.Material.Metal), CFrame.new(0, 0.2, -1.4))
		tool.Grip = CFrame.new(0, -0.3, 0)
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
		-- tilt the rod forward over the water
		tool.Grip = (CFrame.Angles(math.rad(-40), 0, 0) * CFrame.new(0, 2.5, 0)):Inverse()
	end
	return tool
end

return ToolFactory
