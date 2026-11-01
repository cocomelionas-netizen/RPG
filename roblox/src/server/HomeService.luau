-- The hero's house: Hometown (behind the start of the road) has a row of plots; every player gets one while in the server.
-- Each plot has a workbench (planks and nails) and shows the rooms the player has built.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Construction = require(Shared.Construction)
local Items = require(Shared.Items)
local XP = require(Shared.XP)
local Zones = require(Shared.Zones)
local Remotes = require(Shared.Remotes)
local DataService = require(script.Parent.DataService)
local GatherService = require(script.Parent.GatherService)

local HomeService = {}

local hex = Color3.fromHex
local PLOTS_PER_SIDE = 6
local PLOT_SIZE = 36
local PLOT_STEP = 42
local PLOT_Z = 40 -- distance of a plot's centre from the road
local BENCH_DIST = 14
HomeService.TOWN_LENGTH = PLOT_STEP * PLOTS_PER_SIDE + 12 -- Hometown runs from -TOWN_LENGTH to 0 along X

local plots = {} -- array of { index, center, side, model, owner }
local plotOf = {} -- [Player] = plot

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		p[k] = v
	end
	return p
end

local function billboard(parent, title, sub, dist)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Label"
	bb.Size = UDim2.fromOffset(220, 46)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 2, 0)
	bb.MaxDistance = dist or 60
	bb.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.Name = "Title"
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 0.6, 0)
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.4
	t.Text = title
	t.Parent = bb
	local s = t:Clone()
	s.Name = "Sub"
	s.Position = UDim2.new(0, 0, 0.6, 0)
	s.Size = UDim2.new(1, 0, 0.4, 0)
	s.Font = Enum.Font.Gotham
	s.TextColor3 = Color3.fromRGB(255, 230, 140)
	s.Text = sub or ""
	s.Parent = bb
	bb.Parent = parent
	return bb
end

-- ===================== Hometown =====================
local function makeWorkbench(parent, pos: Vector3, facing: number)
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
	local side = index <= PLOTS_PER_SIDE and 1 or -1
	local i = (index - 1) % PLOTS_PER_SIDE
	local center = Vector3.new(-30 - PLOT_STEP * i, 0, side * PLOT_Z)
	local model = Instance.new("Model")
	model.Name = "Plot_" .. index
	part({ Name = "Lawn", Size = Vector3.new(PLOT_SIZE, 0.4, PLOT_SIZE), CFrame = CFrame.new(center + Vector3.new(0, 0.05, 0)), Color = hex("#6fb04a"), Material = Enum.Material.Grass, Parent = model })
	-- a path from the road to the plot
	part({ Name = "Path", Size = Vector3.new(4, 0.3, PLOT_Z - PLOT_SIZE / 2 - 6), CFrame = CFrame.new(center.X, 0.05, side * (8 + (PLOT_Z - PLOT_SIZE / 2 - 8) / 2 + 1)), Color = hex("#c9b27a"), Material = Enum.Material.Cobblestone, Parent = model })
	-- low fence with a gap facing the road
	local half = PLOT_SIZE / 2
	local fence = hex("#8a6a44")
	part({ Size = Vector3.new(PLOT_SIZE, 2, 0.5), CFrame = CFrame.new(center + Vector3.new(0, 1, side * half)), Color = fence, Material = Enum.Material.Wood, Parent = model })
	for _, x in { -1, 1 } do
		part({ Size = Vector3.new(0.5, 2, PLOT_SIZE), CFrame = CFrame.new(center + Vector3.new(x * half, 1, 0)), Color = fence, Material = Enum.Material.Wood, Parent = model })
		part({ Size = Vector3.new(half - 3, 2, 0.5), CFrame = CFrame.new(center + Vector3.new(x * (half + 3) / 2, 1, -side * half)), Color = fence, Material = Enum.Material.Wood, Parent = model })
	end
	-- the sign by the gate
	local post = part({ Name = "SignPost", Size = Vector3.new(0.6, 6, 0.6), CFrame = CFrame.new(center + Vector3.new(4, 3, -side * (half + 1))), Color = fence, Material = Enum.Material.Wood, Parent = model })
	local sign = billboard(post, "For rent", "A free plot", 80)
	sign.StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
	-- workbench just inside the gate
	local facing = side > 0 and 0 or math.pi
	makeWorkbench(model, center + Vector3.new(-9, 0, -side * (half - 5)), facing)
	local rooms = Instance.new("Folder")
	rooms.Name = "Rooms"
	rooms.Parent = model
	model.Parent = parent
	return { index = index, center = center, side = side, model = model, sign = sign, rooms = rooms, owner = nil }
end

-- rooms stand in two rows of three at the back of the plot
local function roomCell(plot, order: number): Vector3
	local col = (order - 1) % 3
	local row = math.floor((order - 1) / 3)
	return plot.center + Vector3.new((col - 1) * 10.5, 0, plot.side * (3 + row * 10))
end

local function renderRooms(plot)
	plot.rooms:ClearAllChildren()
	local data = plot.owner and DataService.get(plot.owner)
	if not data then
		return
	end
	for _, r in Construction.ROOMS do
		local t = data.home.rooms[r.id] or 0
		local pos = roomCell(plot, r.order)
		if t == 0 then
			-- an empty foundation shows where the room will go
			local slab = part({ Name = r.id, Size = Vector3.new(9, 0.4, 9), CFrame = CFrame.new(pos + Vector3.new(0, 0.4, 0)), Color = hex("#9a9086"), Material = Enum.Material.Concrete, Transparency = 0.35, Parent = plot.rooms })
			billboard(slab, r.icon .. " " .. r.name, "Not built yet", 35).StudsOffsetWorldSpace = Vector3.new(0, 2, 0)
		else
			local h = 5 + t * 1.3
			local color = hex(r.color)
			local body = part({ Name = r.id, Size = Vector3.new(9, h, 9), CFrame = CFrame.new(pos + Vector3.new(0, h / 2 + 0.2, 0)), Color = color, Material = t >= 4 and Enum.Material.Marble or (t >= 2 and Enum.Material.Brick or Enum.Material.WoodPlanks), Parent = plot.rooms })
			local roof = Instance.new("WedgePart")
			roof.Anchored = true
			roof.Size = Vector3.new(9.6, 2.4, 4.8)
			roof.Color = Color3.new(color.R * 0.55, color.G * 0.45, color.B * 0.45)
			roof.Material = Enum.Material.Slate
			for _, s in { -1, 1 } do
				local w = roof:Clone()
				w.CFrame = CFrame.new(pos + Vector3.new(0, h + 1.4, s * 2.4)) * CFrame.Angles(0, s > 0 and math.pi or 0, 0)
				w.Parent = plot.rooms
			end
			roof:Destroy()
			-- a door facing the road
			part({ Size = Vector3.new(2.2, 3.6, 0.3), CFrame = CFrame.new(pos + Vector3.new(0, 2, -plot.side * 4.55)), Color = hex("#4a321c"), Material = Enum.Material.Wood, Parent = plot.rooms })
			if t >= 3 then
				local light = Instance.new("PointLight")
				light.Color = Color3.fromRGB(255, 220, 160)
				light.Range = 12
				light.Parent = body
			end
			local bb = billboard(body, r.icon .. " " .. r.name, "Level " .. t, 50)
			bb.StudsOffsetWorldSpace = Vector3.new(0, h / 2 + 4, 0)
		end
	end
end

local function claimPlot(player: Player)
	for _, plot in plots do
		if not plot.owner then
			plot.owner = player
			plotOf[player] = plot
			plot.sign.Title.Text = player.DisplayName .. "'s Home"
			plot.sign.Sub.Text = "Plot " .. plot.index
			renderRooms(plot)
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
		plot.sign.Title.Text = "For rent"
		plot.sign.Sub.Text = "A free plot"
		plot.rooms:ClearAllChildren()
	end
end

function HomeService.buildTown(world: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Hometown"
	local len = HomeService.TOWN_LENGTH
	part({ Name = "Ground", Size = Vector3.new(len, 4, Zones.WIDTH), CFrame = CFrame.new(-len / 2, -2, 0), Color = hex("#5c9a3c"), Material = Enum.Material.Grass, Parent = folder })
	part({ Name = "Road", Size = Vector3.new(len, 1, Zones.ROAD_WIDTH), CFrame = CFrame.new(-len / 2, -0.4, 0), Color = hex("#9a8a70"), Material = Enum.Material.Cobblestone, Parent = folder })
	-- lamp posts along the street
	for x = -12, -len + 12, -21 do
		for _, z in { Zones.ROAD_WIDTH / 2 + 1, -(Zones.ROAD_WIDTH / 2 + 1) } do
			part({ Size = Vector3.new(0.5, 7, 0.5), CFrame = CFrame.new(x, 3.5, z), Color = hex("#3a3a40"), Material = Enum.Material.Metal, Parent = folder })
			local lamp = part({ Size = Vector3.new(1.2, 1.2, 1.2), CFrame = CFrame.new(x, 7.4, z), Color = hex("#ffe6a0"), Material = Enum.Material.Neon, CanCollide = false, Parent = folder })
			local l = Instance.new("PointLight")
			l.Range = 16
			l.Brightness = 1.2
			l.Color = lamp.Color
			l.Parent = lamp
		end
	end
	local plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "Plots"
	plotsFolder.Parent = folder
	for i = 1, PLOTS_PER_SIDE * 2 do
		table.insert(plots, makePlot(plotsFolder, i))
	end
	local welcome = part({ Name = "TownSign", Size = Vector3.new(0.6, 6, Zones.ROAD_WIDTH + 2), CFrame = CFrame.new(-len + 4, 3, 0), Color = hex("#5a3d22"), Material = Enum.Material.Wood, Parent = folder })
	billboard(welcome, "🏡 Hometown", "Build your house and live here", 90)
	folder.Parent = world
	return folder
end

-- ===================== requests =====================
local function nearestBench(player: Player)
	local plot = nil
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return nil
	end
	for _, p in plots do
		local bench = p.model:FindFirstChild("Workbench")
		if bench and (bench.PrimaryPart.Position - hrp.Position).Magnitude <= BENCH_DIST then
			plot = bench
		end
	end
	return plot
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
	local lvl = XP.levelFromXp(data.skills.construction)
	if lvl < r.lv[t] then
		Remotes.Notify:FireClient(player, ("You need Construction level %d."):format(r.lv[t]), "warn")
		return
	end
	local cost = Construction.cost(r, t)
	if data.gold < cost.gold then
		Remotes.Notify:FireClient(player, "Not enough gold.", "warn")
		return
	end
	for id, n in cost.mats do
		if (data.inv[id] or 0) < n then
			Remotes.Notify:FireClient(player, ("You need %d %s."):format(n, Items[id].name), "warn")
			return
		end
	end
	for id, n in cost.mats do
		DataService.addItem(player, id, -n)
	end
	DataService.addGold(player, -cost.gold)
	data.home.rooms[r.id] = t
	local xp = Construction.xp(r, t)
	local before, after = DataService.addXp(player, "construction", xp)
	DataService.sync(player)
	local plot = plotOf[player]
	if plot then
		renderRooms(plot)
	end
	Remotes.Notify:FireClient(player, ("%s %s is now level %d!  +%d Construction XP"):format(r.icon, r.name, t, xp), "good")
	if after > before then
		Remotes.Notify:FireClient(player, ("Construction is now level %d"):format(after), "good")
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
		local gate = plot.center + Vector3.new(0, 3, -plot.side * (PLOT_SIZE / 2 + 3))
		target = CFrame.lookAt(gate, Vector3.new(plot.center.X, 3, plot.center.Z))
	else
		target = CFrame.new(14, 3, 0) * CFrame.Angles(0, -math.pi / 2, 0)
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
				Remotes.Notify:FireClient(player, ("Your home is plot %d in Hometown, behind the start of the road. Tap 🏠 Home to go there."):format(plot.index), "good")
			end
		end)
	end)
	Players.PlayerRemoving:Connect(freePlot)
end

return HomeService
