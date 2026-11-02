-- The hero's house. Hometown (east of Riverbend) has 9 plots; every player gets one while in the server.
-- A plot holds an 8x8 grid of room cells (HouseGrid.luau): the player picks where the house starts (the Entrance Hall),
-- then every room has to join the house side by side, door to door.
-- Every room level adds one House Level, and each House Level gives +1% XP to every skill.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Construction = require(Shared.Construction)
local HouseGrid = require(Shared.HouseGrid)
local Items = require(Shared.Items)
local XP = require(Shared.XP)
local Zones = require(Shared.Zones)
local G = require(Shared.Gathering)
local Farming = require(Shared.Farming)
local Remotes = require(Shared.Remotes)
local DataService = require(script.Parent.DataService)
local GatherService = require(script.Parent.GatherService)
local WorldBuilder = require(script.Parent.WorldBuilder)

local HomeService = {}

local hex = Color3.fromHex
local CELL = HouseGrid.CELL
local PLOT = HouseGrid.PLOT
local BENCH_DIST = 14
-- plot centres: three columns, each with a street on its west side, and four rows
local PLOT_X = { 150, 295, 440 }
local PLOT_Z = { -85, 70, 200 }

local plots = {} -- array of { index, center, model, sign, rooms, owner }
local makeWorkbenchModel -- defined with the plots, also used by the Workshop room
HomeService.onSellAll = function(_player) end -- set by ShopService (it requires this module)
HomeService.onPatch = function(_player, _plotModel, _i) end -- set by FarmService
local plotOf = {} -- [Player] = plot

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props.Shape then
		p.Shape = props.Shape
	end
	for k, v in props do
		p[k] = v
	end
	return p
end

local function billboard(parent, title, sub, dist)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Label"
	bb.Size = UDim2.fromScale(11, 2.4)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 2, 0)
	bb.MaxDistance = dist or 60
	bb.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.Name = "Title"
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 0.6, 0)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.3
	t.Text = title
	t.Parent = bb
	local s = t:Clone()
	s.Name = "Sub"
	s.Position = UDim2.new(0, 0, 0.6, 0)
	s.Size = UDim2.new(1, 0, 0.4, 0)
	s.Font = Enum.Font.GothamBold
	s.TextColor3 = Color3.fromRGB(255, 220, 120)
	s.Text = sub or ""
	s.Parent = bb
	bb.Parent = parent
	return bb
end

-- ===================== rooms =====================
-- small props so every room shows what it is for
local FURNITURE = {
	entrance = function(f, cf)
		part({ Size = Vector3.new(7, 0.1, 9), CFrame = cf * CFrame.new(0, 0.6, 0), Color = hex("#a03a3a"), Material = Enum.Material.Fabric, CanCollide = false, Parent = f })
		part({ Shape = Enum.PartType.Ball, Size = Vector3.new(3, 3, 3), CFrame = cf * CFrame.new(5, 2.2, 5), Color = hex("#3f8f3a"), Material = Enum.Material.Grass, Parent = f })
		part({ Size = Vector3.new(1.6, 1.4, 1.6), CFrame = cf * CFrame.new(5, 0.9, 5), Color = hex("#a0603a"), Material = Enum.Material.Brick, Parent = f })
	end,
	woodshed = function(f, cf)
		for i = 0, 2 do
			for j = 0, 2 - i do
				part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(6, 1.2, 1.2), CFrame = cf * CFrame.new(-3, 1 + i * 1.05, -4 + j * 1.25 + i * 0.6), Color = hex("#a0703a"), Material = Enum.Material.Wood, Parent = f })
			end
		end
	end,
	workshop = function(f, cf)
		part({ Size = Vector3.new(6, 0.5, 3), CFrame = cf * CFrame.new(-2, 3, -4), Color = hex("#a0703a"), Material = Enum.Material.WoodPlanks, Parent = f })
		part({ Size = Vector3.new(5.6, 2.6, 2.6), CFrame = cf * CFrame.new(-2, 1.5, -4), Color = hex("#6b4a2b"), Material = Enum.Material.Wood, Parent = f })
		part({ Size = Vector3.new(2.4, 1.2, 1.2), CFrame = cf * CFrame.new(3.5, 2.2, 3), Color = hex("#40444c"), Material = Enum.Material.Metal, Parent = f })
		part({ Size = Vector3.new(1.4, 1.6, 1.4), CFrame = cf * CFrame.new(3.5, 0.9, 3), Color = hex("#30343a"), Material = Enum.Material.Metal, Parent = f })
	end,
	cellar = function(f, cf)
		for i, c in { "#c87533", "#c9ccd2", "#9a5f4a" } do
			part({ Size = Vector3.new(2.6, 2.4, 2.6), CFrame = cf * CFrame.new(-4 + i * 2.8, 1.4, -4), Color = hex("#8a6a44"), Material = Enum.Material.WoodPlanks, Parent = f })
			part({ Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1.4, 1.4), CFrame = cf * CFrame.new(-4 + i * 2.8, 2.9, -4), Color = hex(c), Material = Enum.Material.Metal, Parent = f })
		end
	end,
	pond = function(f, cf)
		part({ Size = Vector3.new(9, 0.6, 9), CFrame = cf * CFrame.new(0, 0.6, 0), Color = hex("#8a8076"), Material = Enum.Material.Cobblestone, Parent = f })
		part({ Size = Vector3.new(8, 0.3, 8), CFrame = cf * CFrame.new(0, 0.85, 0), Color = hex("#3d8fd0"), Material = Enum.Material.Glass, Transparency = 0.2, CanCollide = false, Parent = f })
	end,
	bedroom = function(f, cf)
		part({ Size = Vector3.new(5, 1.4, 8), CFrame = cf * CFrame.new(-3, 1.1, -2), Color = hex("#6b4a2b"), Material = Enum.Material.Wood, Parent = f })
		part({ Size = Vector3.new(4.8, 0.6, 5.5), CFrame = cf * CFrame.new(-3, 2, -0.8), Color = hex("#5a7ad0"), Material = Enum.Material.Fabric, Parent = f })
		part({ Size = Vector3.new(4, 0.8, 1.6), CFrame = cf * CFrame.new(-3, 2.1, -5), Color = Color3.new(1, 1, 1), Material = Enum.Material.Fabric, Parent = f })
	end,
	treasury = function(f, cf)
		part({ Size = Vector3.new(4, 2.4, 2.6), CFrame = cf * CFrame.new(0, 1.5, -4), Color = hex("#8a5a32"), Material = Enum.Material.Wood, Parent = f })
		part({ Size = Vector3.new(4.2, 0.4, 2.8), CFrame = cf * CFrame.new(0, 2.4, -4), Color = hex("#d4a020"), Material = Enum.Material.Metal, Parent = f })
		for i = 1, 7 do
			part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 1.2, 1.2), CFrame = cf * CFrame.new(-2 + (i % 4), 0.6 + math.floor(i / 4) * 0.3, 2 + (i % 3) * 0.5) * CFrame.Angles(0, 0, math.rad(90)), Color = hex("#ffd24a"), Material = Enum.Material.Neon, CanCollide = false, Parent = f })
		end
	end,
}

-- something to do in every room: a prompt on a station
local function stationPrompt(core: BasePart, action: string, object: string)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "StationPrompt"
	prompt.ActionText = action
	prompt.ObjectText = object
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = core
	return prompt
end

-- a gathering node inside a room (the room's level picks the tier), worked like any node in the world
local function roomNode(f, core: BasePart, skill: string, tier: number)
	local node = Instance.new("Model")
	node.Name = "RoomNode"
	core.Parent = node
	node.PrimaryPart = core
	node:SetAttribute("Skill", skill)
	node:SetAttribute("Tier", tier)
	local info = G.node(skill, tier)
	local prompt = stationPrompt(core, G.VERB[skill], ("%s (Lv %d)"):format(info.name, info.req))
	prompt.Name = "GatherPrompt"
	local chips = Instance.new("ParticleEmitter")
	chips.Name = "Chips"
	chips.Enabled = false
	chips.Color = ColorSequence.new(core.Color)
	chips.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
	chips.Lifetime = NumberRange.new(0.4, 0.8)
	chips.Speed = NumberRange.new(6, 12)
	chips.SpreadAngle = Vector2.new(60, 60)
	chips.Acceleration = Vector3.new(0, -30, 0)
	chips.Parent = core
	node.Parent = f
	GatherService.attach(node)
	return node
end

local CELLAR_ORE = { 0, 2, 3, 4, 5 } -- ore tier by Ore Cellar level
local WOOD_COLOR = { [0] = "#e8d9b0", "#b08850", "#c0703a", "#7a5a30", "#8a5ab0" }

-- the stations: what each room lets you do
local STATIONS = {
	entrance = function(f, cf, _level)
		local board = part({ Name = "HouseBoard", Size = Vector3.new(3, 4, 0.4), CFrame = cf * CFrame.new(-5, 3.5, -6), Color = hex("#8a5a32"), Material = Enum.Material.Wood, Parent = f })
		stationPrompt(board, "Open", "House plans").Triggered:Connect(function(player)
			Remotes.OpenCraft:FireClient(player, "house")
		end)
	end,
	workshop = function(f, cf, _level)
		makeWorkbenchModel(f, (cf * CFrame.new(-3, 0.7, 4)).Position, 0)
	end,
	woodshed = function(f, cf, level)
		local tier = math.clamp(level - 1, 0, 4)
		local stump = part({ Name = "ChoppingBlock", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.4, 3, 3), CFrame = cf * CFrame.new(4, 1.9, 4) * CFrame.Angles(0, 0, math.rad(90)), Color = hex(WOOD_COLOR[tier]), Material = Enum.Material.Wood, Parent = f })
		roomNode(f, stump, "woodcutting", tier)
	end,
	cellar = function(f, cf, level)
		local tier = CELLAR_ORE[math.clamp(level, 1, 5)]
		local vein = part({ Name = "OreVein", Size = Vector3.new(4, 3.4, 3.4), CFrame = cf * CFrame.new(4, 2.4, 4) * CFrame.Angles(0.1, 0.6, 0.1), Color = hex("#5e5a58"):Lerp(hex(G.ORES[tier].color), 0.35), Material = Enum.Material.Slate, Parent = f })
		for i = 1, 4 do
			part({ Shape = Enum.PartType.Ball, Size = Vector3.new(1.2, 1.2, 1.2), CFrame = vein.CFrame * CFrame.new(math.cos(i * 1.6) * 1.8, 0.6, math.sin(i * 1.6) * 1.6), Color = hex(G.ORES[tier].color), Material = Enum.Material.Metal, CanCollide = false, Parent = f })
		end
		roomNode(f, vein, "mining", tier)
	end,
	pond = function(f, cf, level)
		local tier = math.clamp(level - 1, 0, 4)
		local ripple = part({ Name = "Ripple", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 4, 4), CFrame = cf * CFrame.new(0, 1.85, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.new(1, 1, 1), Material = Enum.Material.Neon, Transparency = 0.6, CanCollide = false, Parent = f })
		roomNode(f, ripple, "fishing", tier)
	end,
	treasury = function(f, cf, _level)
		local counter = part({ Name = "Counter", Size = Vector3.new(5, 3, 2), CFrame = cf * CFrame.new(4, 2.2, 4), Color = hex("#8a5a32"), Material = Enum.Material.WoodPlanks, Parent = f })
		stationPrompt(counter, "Sell all", "Treasury").Triggered:Connect(function(player)
			HomeService.onSellAll(player)
		end)
	end,
	bedroom = function(f, cf, _level)
		local pillow = part({ Name = "Bed", Size = Vector3.new(4, 2, 6), CFrame = cf * CFrame.new(-3, 2.5, -2), Transparency = 1, CanCollide = false, CanQuery = false, Parent = f })
		stationPrompt(pillow, "Rest", "Bed").Triggered:Connect(function(player)
			local data = DataService.get(player)
			if data then
				Remotes.Notify:FireClient(player, ("💤 A good rest! While you are away your hero keeps working for up to %dh."):format(G.offlineCap(data.home.rooms) // 3600), "good")
			end
		end)
	end,
}

-- one room on its cell. Rooms that touch have no wall between them, and every room shares the same cream walls and
-- red roof, so the rooms read as one house; the room's own colour is on its shutters and flower boxes, its icon over the roof.
-- open[side] = a neighbouring room on that side (0 = +Z, 1 = +X, 2 = -Z, 3 = -X). Only the Entrance Hall has front doors.
-- Every level shows: 2 flower boxes, 3 a smoking chimney, 4 a golden ridge, 5 a flag on the roof.
local HOUSE_WALL = hex("#f4ead8")
local HOUSE_ROOF = hex("#c0503a")
local function buildRoom(parent, cf: CFrame, id: string, name: string, icon: string, level: number, color: Color3, fresh: boolean?, open)
	open = open or {}
	local f = Instance.new("Model")
	f.Name = id
	local h = 10
	local wood = hex("#6b4a2b")
	local wallColor = HOUSE_WALL
	local roofColor = HOUSE_ROOF
	local accent = id == "entrance" and hex("#4a8ad0") or color
	part({ Name = "Base", Size = Vector3.new(CELL, 1, CELL), CFrame = cf * CFrame.new(0, 0.5, 0), Color = hex("#9a948c"), Material = Enum.Material.Cobblestone, Parent = f })
	part({ Name = "Floor", Size = Vector3.new(CELL - 1.4, 0.2, CELL - 1.4), CFrame = cf * CFrame.new(0, 1.05, 0), Color = hex("#c9a070"), Material = Enum.Material.WoodPlanks, Parent = f })
	local door, inset = 5, CELL / 2 - 0.6
	local seg = (CELL - 1.2 - door) / 2
	for side = 0, 3 do
		local rot = cf * CFrame.Angles(0, side * math.pi / 2, 0)
		-- timber corner post
		part({ Size = Vector3.new(1.2, h, 1.2), CFrame = rot * CFrame.new(inset, 1 + h / 2, inset), Color = wood, Material = Enum.Material.Wood, Parent = f })
		if open[side] then
			continue -- the next room carries on here
		end
		for _, s in { -1, 1 } do
			local wx = s * (door / 2 + seg / 2)
			part({ Size = Vector3.new(seg, h, 0.8), CFrame = rot * CFrame.new(wx, 1 + h / 2, inset), Color = wallColor, Material = Enum.Material.SmoothPlastic, Parent = f })
			-- window with a white frame and warm light
			part({ Size = Vector3.new(2.8, 2.8, 0.9), CFrame = rot * CFrame.new(wx, 6.2, inset), Color = Color3.new(1, 1, 1), Material = Enum.Material.SmoothPlastic, Parent = f })
			part({ Size = Vector3.new(2.2, 2.2, 1), CFrame = rot * CFrame.new(wx, 6.2, inset), Color = hex("#ffe2a0"), Material = Enum.Material.Neon, Transparency = 0.25, Parent = f })
			for _, k in { -1, 1 } do -- shutters in the room's colour
				part({ Size = Vector3.new(1.1, 2.8, 0.3), CFrame = rot * CFrame.new(wx + k * 2.1, 6.2, inset + 0.5), Color = accent, Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = f })
			end
			if level >= 2 then
				part({ Size = Vector3.new(3, 0.8, 1), CFrame = rot * CFrame.new(wx, 4.5, inset + 0.8), Color = wood, Material = Enum.Material.Wood, Parent = f })
				for k = -1, 1 do
					part({ Shape = Enum.PartType.Ball, Size = Vector3.new(0.8, 0.8, 0.8), CFrame = rot * CFrame.new(wx + k * 0.9, 5.1, inset + 0.8), Color = hex(({ "#ff7aa8", "#ffd84a", "#b07aff" })[k + 2]), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = f })
				end
			end
		end
		part({ Size = Vector3.new(door, h - 7, 0.8), CFrame = rot * CFrame.new(0, 8 + (h - 7) / 2, inset), Color = wallColor, Material = Enum.Material.SmoothPlastic, Parent = f })
		if id == "entrance" then
			-- an open front door in a wooden frame, with a doormat
			for _, s in { -1, 1 } do
				part({ Size = Vector3.new(0.5, 7, 1), CFrame = rot * CFrame.new(s * (door / 2 + 0.25), 4.5, inset), Color = wood, Material = Enum.Material.Wood, Parent = f })
			end
			part({ Size = Vector3.new(door + 1, 0.5, 1), CFrame = rot * CFrame.new(0, 8.2, inset), Color = wood, Material = Enum.Material.Wood, Parent = f })
			part({ Size = Vector3.new(0.3, 7, door - 0.4), CFrame = rot * CFrame.new(door / 2 - 0.1, 4.5, inset + door / 2 - 0.2), Color = accent, Material = Enum.Material.WoodPlanks, CanCollide = false, Parent = f })
			part({ Size = Vector3.new(door - 1, 0.1, 2.4), CFrame = rot * CFrame.new(0, 1.05, inset + 1.8), Color = hex("#a0603a"), Material = Enum.Material.Fabric, CanCollide = false, Parent = f })
		else
			-- no door here: the wall goes on, with a flower box in the room's colour
			part({ Size = Vector3.new(door, 7, 0.8), CFrame = rot * CFrame.new(0, 4.5, inset), Color = wallColor, Material = Enum.Material.SmoothPlastic, Parent = f })
			part({ Size = Vector3.new(door - 1, 0.6, 1.2), CFrame = rot * CFrame.new(0, 3.2, inset + 0.6), Color = accent, Material = Enum.Material.WoodPlanks, Parent = f })
		end
		-- a strip of timber along the top of the outside walls
		part({ Size = Vector3.new(CELL - 1.2, 0.7, 1), CFrame = rot * CFrame.new(0, 1 + h - 0.35, inset), Color = wood, Material = Enum.Material.Wood, Parent = f })
	end
	-- pitched roof with an overhang; the ridge runs along the row of rooms so neighbours share one long roof
	local top = 1 + h
	local rise = 5
	local turned = (open[0] or open[2]) and not (open[1] or open[3])
	local roofCf = turned and cf * CFrame.Angles(0, math.pi / 2, 0) or cf
	-- roof edges: 1 stud of overhang over the garden, and stopping half a stud short of a neighbouring room, so two
	-- roofs never overlap (overlapping parts flicker) and a thin gap shows where one room ends
	local px, nx, pz, nz = 1, 3, 0, 2 -- the side each roof-local direction (+X, -X, +Z, -Z) faces
	if turned then
		px, nx, pz, nz = 2, 0, 1, 3
	end
	local function edge(side)
		return CELL / 2 + (open[side] and -0.5 or 1)
	end
	local len, mid = edge(px) + edge(nx), (edge(px) - edge(nx)) / 2
	for _, s in { -1, 1 } do
		local depth = edge(s > 0 and pz or nz)
		local w = Instance.new("WedgePart")
		w.Anchored = true
		w.Size = Vector3.new(len, rise, depth)
		w.CFrame = roofCf * CFrame.new(mid, top + rise / 2, s * depth / 2) * CFrame.Angles(0, s > 0 and math.pi or 0, 0)
		w.Color = roofColor
		w.Material = Enum.Material.SmoothPlastic
		w.Parent = f
	end
	part({ Name = "Ridge", Size = Vector3.new(len - 0.2, 0.6, 0.8), CFrame = roofCf * CFrame.new(mid, top + rise, 0), Color = level >= 4 and hex("#ffd24a") or wood, Material = level >= 4 and Enum.Material.Neon or Enum.Material.Wood, Parent = f })
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 225, 170)
	light.Range = 16
	light.Brightness = 0.9
	light.Parent = f:FindFirstChild("Floor")
	if level >= 3 then
		local chimney = part({ Size = Vector3.new(2, 5, 2), CFrame = cf * CFrame.new(CELL / 4, top + rise, CELL / 4), Color = hex("#a05a40"), Material = Enum.Material.Brick, Parent = f })
		local smoke = Instance.new("Smoke")
		smoke.Size = 1.2
		smoke.RiseVelocity = 3
		smoke.Opacity = 0.15
		smoke.Parent = chimney
	end
	if level >= 5 then
		part({ Size = Vector3.new(0.3, 5, 0.3), CFrame = cf * CFrame.new(-CELL / 2 + 1, top + rise + 2, 0), Color = wood, Material = Enum.Material.Wood, Parent = f })
		part({ Size = Vector3.new(0.1, 1.8, 2.8), CFrame = cf * CFrame.new(-CELL / 2 + 1, top + rise + 3.6, 1.5), Color = accent, Material = Enum.Material.Fabric, Parent = f })
	end
	if FURNITURE[id] then
		FURNITURE[id](f, cf * CFrame.new(0, 0.7, 0))
	end
	if STATIONS[id] then
		STATIONS[id](f, cf, level)
	end
	local bb = billboard(f:FindFirstChild("Ridge"), icon .. " " .. name, level > 0 and ("Level " .. level) or "", 80)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 3.5, 0)
	f.Parent = parent
	if fresh then
		-- a puff of dust and sparkles when the room has just been built
		local burst = Instance.new("ParticleEmitter")
		burst.Color = ColorSequence.new(Color3.fromRGB(255, 240, 200))
		burst.LightEmission = 0.6
		burst.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 0) })
		burst.Lifetime = NumberRange.new(0.8, 1.4)
		burst.Speed = NumberRange.new(10, 20)
		burst.SpreadAngle = Vector2.new(180, 180)
		burst.Enabled = false
		burst.Parent = f:FindFirstChild("Floor")
		burst:Emit(60)
	end
	return f
end

-- ===================== plots =====================
makeWorkbenchModel = function(parent, pos: Vector3, facing: number)
	local model = Instance.new("Model")
	model.Name = "Workbench"
	local cf = CFrame.new(pos) * CFrame.Angles(0, facing, 0)
	local top = part({ Name = "Top", Size = Vector3.new(6, 0.6, 3), CFrame = cf * CFrame.new(0, 3, 0), Color = hex("#a0703a"), Material = Enum.Material.WoodPlanks, Parent = model })
	for _, x in { -2.6, 2.6 } do
		for _, z in { -1.1, 1.1 } do
			part({ Size = Vector3.new(0.5, 3, 0.5), CFrame = cf * CFrame.new(x, 1.5, z), Color = hex("#6b4a2b"), Material = Enum.Material.Wood, Parent = model })
		end
	end
	part({ Name = "Log", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 1, 1), CFrame = cf * CFrame.new(-1, 3.8, 0), Color = hex("#c8a070"), Material = Enum.Material.Wood, Parent = model })
	part({ Name = "SawBlade", Size = Vector3.new(0.1, 1.2, 2), CFrame = cf * CFrame.new(1.6, 3.9, 0), Color = hex("#b8bec8"), Material = Enum.Material.Metal, Parent = model })
	model.PrimaryPart = top
	model:SetAttribute("Skill", "construction")

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "WorkbenchPrompt"
	prompt.ActionText = "Use"
	prompt.ObjectText = "Workbench"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 11
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = top
	prompt.Triggered:Connect(function(player)
		Remotes.OpenCraft:FireClient(player)
	end)

	local chips = Instance.new("ParticleEmitter")
	chips.Name = "Chips"
	chips.Enabled = false
	chips.Color = ColorSequence.new(hex("#e0c090"))
	chips.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
	chips.Lifetime = NumberRange.new(0.4, 0.8)
	chips.Speed = NumberRange.new(5, 9)
	chips.SpreadAngle = Vector2.new(60, 60)
	chips.Acceleration = Vector3.new(0, -30, 0)
	chips.Parent = top

	billboard(top, "🔨 Workbench", "Planks & nails", 40)
	model.Parent = parent
	return model
end

local function makePlot(parent, index: number)
	local col = (index - 1) % #PLOT_X + 1
	local row = math.floor((index - 1) / #PLOT_X) + 1
	local center = Vector3.new(PLOT_X[col], 0, PLOT_Z[row])
	local model = Instance.new("Model")
	model.Name = "Plot_" .. index
	model:SetAttribute("PlotIndex", index)
	local half = PLOT / 2
	part({ Name = "Kerb", Size = Vector3.new(PLOT + 3, 0.5, PLOT + 3), CFrame = CFrame.new(center + Vector3.new(0, -0.05, 0)), Color = hex("#b8b0a4"), Material = Enum.Material.Cobblestone, Parent = model })
	part({ Name = "Lawn", Size = Vector3.new(PLOT, 0.4, PLOT), CFrame = CFrame.new(center + Vector3.new(0, 0.05, 0)), Color = hex("#74b850"), Material = Enum.Material.Grass, Parent = model })
	-- the garden strip between the fence and the house: bushes and flowers along the north and east fences,
	-- two small trees in the north corners (the south strip is the vegetable garden)
	local rng = Random.new(index * 7)
	local prop = WorldBuilder.prop
	local PLANTS = { "PurpleFlower", "PolygonNature_Plant_Flowers_01", "Bush_Plant_Bush_Leaves_03", "PolygonNature_Plant_Bush_01", "PolygonNature_Plant_Bush_02", "Fern_Plant_Fern_Leaves_01" }
	for t = -half + 14, half - 14, 9 do
		for _, off in { Vector3.new(t, 0, -half + 4), Vector3.new(half - 4, 0, t * 0.75) } do
			prop(PLANTS[rng:NextInteger(1, #PLANTS)], model, center + off, rng:NextNumber(2.2, 3.6), rng:NextNumber(0, 6.3))
		end
	end
	for _, x in { -1, 1 } do
		prop("Birch_Tree_Birch_02", model, center + Vector3.new(x * (half - 5), 0, -half + 5), 11, rng:NextNumber(0, 6.3), true)
	end
	-- a white picket fence with a gate on the west side, facing the street
	local fence = hex("#f4f0e8")
	local gate = 14
	local function fenceRun(a: Vector3, b: Vector3)
		local len = (b - a).Magnitude
		local mid = center + (a + b) / 2
		local look = CFrame.lookAt(mid, mid + (b - a))
		for _, y in { 1, 2.1 } do
			part({ Size = Vector3.new(0.3, 0.4, len), CFrame = look * CFrame.new(0, y, 0), Color = fence, Material = Enum.Material.SmoothPlastic, Parent = model })
		end
		for d = 0, len, 2.4 do
			part({ Size = Vector3.new(0.5, 2.8, 0.5), CFrame = look * CFrame.new(0, 1.4, -len / 2 + d), Color = fence, Material = Enum.Material.SmoothPlastic, Parent = model })
		end
	end
	fenceRun(Vector3.new(-half, 0, -half), Vector3.new(half, 0, -half))
	fenceRun(Vector3.new(-half, 0, half), Vector3.new(half, 0, half))
	fenceRun(Vector3.new(half, 0, -half), Vector3.new(half, 0, half))
	fenceRun(Vector3.new(-half, 0, -half), Vector3.new(-half, 0, -gate / 2))
	fenceRun(Vector3.new(-half, 0, gate / 2), Vector3.new(-half, 0, half))
	for _, s in { -1, 1 } do -- gate posts with lanterns
		local post = part({ Size = Vector3.new(1.2, 4.5, 1.2), CFrame = CFrame.new(center + Vector3.new(-half, 2.25, s * (gate / 2 + 0.6))), Color = hex("#8a6a44"), Material = Enum.Material.Wood, Parent = model })
		local lantern = part({ Size = Vector3.new(0.9, 0.9, 0.9), CFrame = post.CFrame * CFrame.new(0, 2.7, 0), Color = hex("#ffe6a0"), Material = Enum.Material.Neon, CanCollide = false, Parent = model })
		local l = Instance.new("PointLight")
		l.Range = 12
		l.Brightness = 0.8
		l.Color = lantern.Color
		l.Parent = lantern
	end
	-- a mailbox by the gate
	local mail = center + Vector3.new(-half - 3, 0, gate / 2 + 4)
	part({ Size = Vector3.new(0.5, 3.4, 0.5), CFrame = CFrame.new(mail + Vector3.new(0, 1.7, 0)), Color = hex("#6b4a2b"), Material = Enum.Material.Wood, Parent = model })
	part({ Size = Vector3.new(2.2, 1.4, 1.3), CFrame = CFrame.new(mail + Vector3.new(0, 4, 0)), Color = hex("#4a8ad0"), Material = Enum.Material.SmoothPlastic, Parent = model })
	part({ Size = Vector3.new(0.15, 0.9, 0.5), CFrame = CFrame.new(mail + Vector3.new(0.6, 4.6, -0.75)), Color = hex("#e04a4a"), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = model })
	-- path from the street through the gate to the foundation
	local streetX = center.X - half - 23
	local pathEnd = center.X - HouseGrid.SIZE * CELL / 2
	part({ Name = "Path", Size = Vector3.new(pathEnd - streetX, 0.3, 6), CFrame = CFrame.new((streetX + pathEnd) / 2, 0.15, center.Z), Color = hex("#c9b27a"), Material = Enum.Material.Cobblestone, Parent = model })
	-- the sign by the gate
	local post = part({ Name = "SignPost", Size = Vector3.new(0.6, 7, 0.6), CFrame = CFrame.new(center + Vector3.new(-half - 2, 3.5, -gate / 2 - 3)), Color = hex("#8a6a44"), Material = Enum.Material.Wood, Parent = model })
	local sign = billboard(post, "For rent", "A free plot", 120)
	sign.Size = UDim2.fromScale(16, 3.4)
	sign.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
	-- workbench just inside the gate
	makeWorkbenchModel(model, center + Vector3.new(-half + 7, 0, gate / 2 + 8), math.pi / 2)
	-- the vegetable garden: soil patches along the south fence (FarmService grows things in them)
	local patches = Instance.new("Folder")
	patches.Name = "Patches"
	for i, def in Farming.PATCHES do
		local w = def.kind == "tree" and 12 or 11
		local soil = part({ Name = "Patch_" .. i, Size = Vector3.new(w, 0.6, 7), CFrame = CFrame.new(center + Vector3.new(def.x, 0.35, half - 5.5)), Color = hex("#6b4a2b"), Material = Enum.Material.Ground, Parent = patches })
		soil:SetAttribute("Kind", def.kind)
		part({ Size = Vector3.new(w + 0.8, 0.5, 7.8), CFrame = soil.CFrame * CFrame.new(0, -0.1, 0), Color = hex("#8a6a44"), Material = Enum.Material.WoodPlanks, Parent = patches })
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "PatchPrompt"
		prompt.ActionText = "Plant"
		prompt.ObjectText = Farming.KIND_NAME[def.kind]
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 9
		prompt.RequiresLineOfSight = false
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.Parent = soil
		prompt.Triggered:Connect(function(player)
			HomeService.onPatch(player, model, i)
		end)
	end
	patches.Parent = model
	local rooms = Instance.new("Folder")
	rooms.Name = "Rooms"
	rooms.Parent = model
	model.Parent = parent
	return { index = index, center = center, model = model, sign = sign, rooms = rooms, owner = nil }
end

local function renderHouse(plot, fresh: string?)
	plot.rooms:ClearAllChildren()
	local data = plot.owner and DataService.get(plot.owner)
	if not data then
		return
	end
	local function cellCF(x, z)
		return CFrame.new(plot.center + HouseGrid.cellOffset(x, z))
	end
	-- which sides of a cell have another room next to them
	local cells = HouseGrid.occupied(data.home.layout)
	local function openSides(c)
		local o = {}
		for side, d in { [0] = { 0, 1 }, { 1, 0 }, { 0, -1 }, { -1, 0 } } do
			o[side] = cells[(c.x + d[1]) .. "," .. (c.z + d[2])] ~= nil
		end
		return o
	end
	for id, c in data.home.layout do
		local r = Construction.byId[id]
		local t = data.home.rooms[id] or 0
		if id == HouseGrid.START then
			buildRoom(plot.rooms, cellCF(c.x, c.z), "entrance", "Entrance Hall", "🏡", 0, hex("#b0a090"), fresh == id, openSides(c))
		elseif r and t > 0 then
			buildRoom(plot.rooms, cellCF(c.x, c.z), id, r.name, r.icon, t, hex(r.color), fresh == id, openSides(c))
		end
	end
	local lvl = HouseGrid.houseLevel(data.home.rooms)
	plot.sign.Title.Text = plot.owner.DisplayName .. "'s Home"
	plot.sign.Sub.Text = ("🏠 House Level %d  ·  +%d%% XP"):format(lvl, lvl)
end

function HomeService.render(player: Player, fresh: string?)
	local plot = plotOf[player]
	if plot then
		renderHouse(plot, fresh)
	end
end

local function claimPlot(player: Player)
	for _, plot in plots do
		if not plot.owner then
			plot.owner = player
			plotOf[player] = plot
			plot.model:SetAttribute("Owner", player.UserId)
			renderHouse(plot)
			return plot
		end
	end
	return nil
end

local function freePlot(player: Player)
	local plot = plotOf[player]
	if plot then
		plotOf[player] = nil
		plot.owner = nil
		plot.model:SetAttribute("Owner", nil)
		plot.sign.Title.Text = "For rent"
		plot.sign.Sub.Text = "A free plot"
		plot.rooms:ClearAllChildren()
		-- the next owner starts with an empty garden
		for _, soil in plot.model.Patches:GetChildren() do
			for _, n in { "Plants", "Ready" } do
				local x = soil:FindFirstChild(n)
				if x then
					x:Destroy()
				end
			end
			soil:SetAttribute("Key", nil)
		end
	end
end

-- Hometown: the plots and street lamps; the zone's ground, streets and arch come from WorldBuilder
function HomeService.buildTown(world: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Hometown"
	local plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "Plots"
	plotsFolder.Parent = folder
	for i = 1, #PLOT_X * #PLOT_Z do
		table.insert(plots, makePlot(plotsFolder, i))
	end
	-- trees along the east side of every street, between the street lamps and the plots, away from the gates
	local rng = Random.new(99)
	for _, x in { 67, 212, 357 } do
		for z = -125, 250, 26 do
			local nearGate = false
			for _, pz in PLOT_Z do
				if math.abs(z - pz) < 14 then
					nearGate = true
				end
			end
			if not nearGate and math.abs(z + 8) > 14 then
				WorldBuilder.prop(rng:NextNumber() < 0.5 and "PolygonNature_Tree_Round_03" or "Birch_Tree_Birch_01", folder, Vector3.new(x + 16, 0, z), rng:NextNumber(14, 18), rng:NextNumber(0, 6.3), true)
			end
		end
	end
	for _, x in { 67, 212, 357 } do
		for z = -135, 255, 40 do
			local p = Vector3.new(x + Zones.ROAD_WIDTH / 2 + 1, 0, z)
			part({ Size = Vector3.new(0.5, 7, 0.5), CFrame = CFrame.new(p + Vector3.new(0, 3.5, 0)), Color = hex("#3a3a40"), Material = Enum.Material.Metal, Parent = folder })
			local lamp = part({ Size = Vector3.new(1.2, 1.2, 1.2), CFrame = CFrame.new(p + Vector3.new(0, 7.4, 0)), Color = hex("#ffe6a0"), Material = Enum.Material.Neon, CanCollide = false, Parent = folder })
			local l = Instance.new("PointLight")
			l.Range = 16
			l.Brightness = 1
			l.Color = lamp.Color
			l.Parent = lamp
		end
	end
	folder.Parent = world
	return folder
end

-- ===================== requests =====================
local function nearestBench(player: Player)
	local found = nil
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return nil
	end
	-- the workbench in the garden, or the one in a Workshop room
	for _, p in plots do
		for _, bench in p.model:GetDescendants() do
			if bench.Name == "Workbench" and bench:IsA("Model") and bench.PrimaryPart and (bench.PrimaryPart.Position - hrp.Position).Magnitude <= BENCH_DIST then
				found = bench
			end
		end
	end
	return found
end

function HomeService.craft(player: Player, recipe)
	if type(recipe) ~= "number" or recipe ~= math.floor(recipe) or recipe < 0 or recipe >= Construction.RECIPE_COUNT then
		return
	end
	local bench = nearestBench(player)
	if not bench then
		Remotes.Notify:FireClient(player, "Walk up to a workbench first.", "warn")
		return
	end
	GatherService.start(player, bench, recipe)
end

-- checks and takes the cost of room r at level t; returns true when paid
local function pay(player: Player, data, r, t: number): boolean
	if XP.levelFromXp(data.skills.construction) < r.lv[t] then
		Remotes.Notify:FireClient(player, ("You need Construction level %d."):format(r.lv[t]), "warn")
		return false
	end
	local cost = Construction.cost(r, t)
	if data.gold < cost.gold then
		Remotes.Notify:FireClient(player, "Not enough gold.", "warn")
		return false
	end
	for id, n in cost.mats do
		if (data.inv[id] or 0) < n then
			Remotes.Notify:FireClient(player, ("You need %d %s."):format(n, Items[id].name), "warn")
			return false
		end
	end
	for id, n in cost.mats do
		DataService.addItem(player, id, -n)
	end
	DataService.addGold(player, -cost.gold)
	return true
end

local function levelUp(player: Player, data, r, t: number)
	data.home.rooms[r.id] = t
	local xp = Construction.xp(r, t)
	local before, after = DataService.addXp(player, "construction", xp)
	DataService.sync(player)
	HomeService.render(player, r.id)
	Remotes.Notify:FireClient(player, ("%s %s is now level %d!  +%d Construction XP  ·  House Level +1"):format(r.icon, r.name, t, xp), "good")
	if after > before then
		Remotes.Notify:FireClient(player, ("Construction is now level %d"):format(after), "good")
	end
end

-- upgrade a room that already stands in the house
function HomeService.build(player: Player, roomId)
	local data = DataService.get(player)
	local r = type(roomId) == "string" and Construction.byId[roomId]
	if not data or not r then
		return
	end
	local t = (data.home.rooms[r.id] or 0) + 1
	if t > Construction.ROOM_MAX then
		return
	end
	if t == 1 or not data.home.layout[r.id] then
		Remotes.Notify:FireClient(player, "Walk onto a ➕ spot next to your house to build this room.", "warn")
		return
	end
	if pay(player, data, r, t) then
		levelUp(player, data, r, t)
	end
end

-- a build spot on the plot: start the house there (Entrance Hall, free) or build a new room there
function HomeService.buildAt(player: Player, roomId, x, z)
	local data = DataService.get(player)
	if not data or type(roomId) ~= "string" or type(x) ~= "number" or type(z) ~= "number" then
		return
	end
	local layout = data.home.layout
	if roomId == HouseGrid.START then
		if layout[HouseGrid.START] then
			return
		end
	else
		local r = Construction.byId[roomId]
		if not r or layout[roomId] then
			return
		end
	end
	local ok, why = HouseGrid.canPlace(layout, roomId, x, z)
	if not ok then
		Remotes.Notify:FireClient(player, why, "warn")
		return
	end
	if roomId == HouseGrid.START then
		layout[roomId] = { x = x, z = z }
		DataService.sync(player)
		HomeService.render(player, roomId)
		Remotes.Notify:FireClient(player, "🏡 Your house starts here! Build rooms on the ➕ spots next to it.", "good")
		return
	end
	local r = Construction.byId[roomId]
	local t = data.home.rooms[r.id] or 0
	if t == 0 and not pay(player, data, r, 1) then
		return
	end
	layout[r.id] = { x = x, z = z }
	if t == 0 then
		levelUp(player, data, r, 1)
	else
		-- built before the house had a layout: just put it here
		DataService.sync(player)
		HomeService.render(player, r.id)
	end
end

function HomeService.teleport(player: Player, where: string)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	GatherService.stop(player, "player")
	local target
	if where == "home" then
		local plot = plotOf[player]
		if not plot then
			Remotes.Notify:FireClient(player, "Hometown is full right now.", "warn")
			return
		end
		-- stand at the gate, facing the house
		local gate = plot.center + Vector3.new(-PLOT / 2 - 4, 3, 0)
		target = CFrame.lookAt(gate, plot.center + Vector3.new(0, 3, 0))
		local data = DataService.get(player)
		if data then
			data.stats.homeTrips += 1
			DataService.sync(player)
		end
	else
		target = CFrame.new(Zones.SPAWN) * CFrame.Angles(0, math.pi, 0)
	end
	char:PivotTo(target)
end

function HomeService.plotOf(player: Player)
	return plotOf[player]
end

function HomeService.init()
	DataService.onLoaded(function(player)
		local plot = claimPlot(player)
		task.delay(6, function()
			if player.Parent and plot then
				Remotes.Notify:FireClient(player, ("Your home is plot %d in Hometown, east of town. Tap 🏡 Go home to go there."):format(plot.index), "good")
			end
		end)
	end)
	Players.PlayerRemoving:Connect(freePlot)
end

return HomeService
