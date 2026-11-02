-- Waystones and teleporting. Every zone has a waystone by its road; walking into a zone the first time unlocks it,
-- and from then on the 🗺️ Map (or tapping any waystone) teleports the hero there. Riverbend, the Meadow and your own
-- plot are always open. No teleporting out of a fight in the Wraith Caves: you have to run.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Zones = require(Shared.Zones)
local Combat = require(Shared.Combat)
local Remotes = require(Shared.Remotes)
local DataService = require(script.Parent.DataService)
local GatherService = require(script.Parent.GatherService)
local HomeService = require(script.Parent.HomeService)
local CombatService = require(script.Parent.CombatService)

local TravelService = {}

local hex = Color3.fromHex
local ALWAYS = { town = true, meadow = true, home = true }
local TELEBLOCK = 10 -- seconds after being hit in the Wraith Caves

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

function TravelService.unlocked(data, zoneId: string): boolean
	return ALWAYS[zoneId] or (data.visited and data.visited[zoneId]) == true
end

-- a standing stone on a round plinth with a glowing ring, the zone's name over it, and a prompt that opens the map
local function buildStone(parent, zone)
	local pos = zone.stone
	local model = Instance.new("Model")
	model.Name = "Waystone_" .. zone.id
	local glow = zone.th.ghostly and hex("#9fff9f") or zone.th.lava and hex("#ffb060") or hex("#7fe0ff")
	part({ Name = "Plinth", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 11, 11), CFrame = CFrame.new(pos + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = hex("#8a8494"), Material = Enum.Material.Cobblestone, Parent = model })
	part({ Name = "Rune", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.1, 8, 8), CFrame = CFrame.new(pos + Vector3.new(0, 1.05, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = glow, Material = Enum.Material.Neon, Transparency = 0.35, CanCollide = false, Parent = model })
	local stone = part({ Name = "Stone", Size = Vector3.new(3, 9, 2), CFrame = CFrame.new(pos + Vector3.new(0, 5.5, 0)) * CFrame.Angles(0, 0.4, 0.06), Color = hex("#6a6478"), Material = Enum.Material.Slate, Parent = model })
	part({ Size = Vector3.new(1.2, 1.2, 2.2), CFrame = stone.CFrame * CFrame.new(0, 2, 0) * CFrame.Angles(0, 0, math.rad(45)), Color = glow, Material = Enum.Material.Neon, CanCollide = false, Parent = model })
	local ring = part({ Name = "Ring", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 6, 6), CFrame = CFrame.new(pos + Vector3.new(0, 11.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = glow, Material = Enum.Material.Neon, Transparency = 0.5, CanCollide = false, CanQuery = false, Parent = model })
	local light = Instance.new("PointLight")
	light.Color = glow
	light.Range = 18
	light.Brightness = 1.5
	light.Parent = ring
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Color = ColorSequence.new(glow)
	sparkle.LightEmission = 1
	sparkle.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) })
	sparkle.Lifetime = NumberRange.new(1.5, 2.5)
	sparkle.Rate = 6
	sparkle.Speed = NumberRange.new(1, 2)
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.Parent = ring

	local bb = Instance.new("BillboardGui")
	bb.Name = "Label"
	bb.Size = UDim2.fromScale(12, 2.6)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
	bb.MaxDistance = 90
	bb.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 0.6)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.3
	t.Text = "🗺️ Waystone"
	t.Parent = bb
	local s = t:Clone()
	s.Position = UDim2.fromScale(0, 0.6)
	s.Size = UDim2.fromScale(1, 0.4)
	s.Font = Enum.Font.GothamBold
	s.TextColor3 = glow
	s.Text = zone.name .. " · tap to travel"
	s.Parent = bb
	bb.Parent = ring

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "WaystonePrompt"
	prompt.ActionText = "Travel"
	prompt.ObjectText = "Waystone"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = stone
	prompt.Triggered:Connect(function(player)
		Remotes.OpenCraft:FireClient(player, "travel")
	end)
	model.PrimaryPart = stone
	model.Parent = parent
	return model
end

-- scenery that happens to stand where a waystone goes is moved out of the way (props only, never nodes or buildings)
local function clearAround(world: Instance, pos: Vector3, radius: number)
	for _, folder in world:GetChildren() do
		if folder.Name:sub(1, 5) == "Zone_" and folder.Name ~= "Zone_town" then
			for _, c in folder:GetChildren() do
				local ok, cf, size = pcall(function()
					if c:IsA("Model") then
						return c:GetBoundingBox()
					end
					return c.CFrame, c.Size
				end)
				if ok and cf and size.X < 40 and size.Z < 40 then
					local flat = Vector3.new(cf.X - pos.X, 0, cf.Z - pos.Z)
					if flat.Magnitude < radius + math.max(size.X, size.Z) / 2 then
						c:Destroy()
					end
				end
			end
		end
	end
end

local function puff(pos: Vector3, color: Color3)
	local p = part({ Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(pos), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false, Parent = workspace })
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(color)
	e.LightEmission = 1
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(0.6, 1)
	e.Speed = NumberRange.new(8, 14)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Enabled = false
	e.Parent = p
	e:Emit(40)
	game:GetService("Debris"):AddItem(p, 2)
end

-- teleport to a zone ("home" = your own plot); every rule is checked here
function TravelService.travel(player: Player, zoneId)
	local data = DataService.get(player)
	local zone = type(zoneId) == "string" and Zones.byId[zoneId]
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not data or not zone or not hrp then
		return
	end
	if CombatService.inWild(player) and CombatService.hurtWithin(player, TELEBLOCK) then
		Remotes.Notify:FireClient(player, "☠️ You can't teleport during a fight in the Wraith Caves. Run!", "warn")
		return
	end
	if not TravelService.unlocked(data, zone.id) then
		Remotes.Notify:FireClient(player, ("🗺️ Walk to %s once to unlock its waystone."):format(zone.name), "warn")
		return
	end
	if zone.wild and Combat.combatLevel(data.skills) < zone.req then
		Remotes.Notify:FireClient(player, ("☠️ The Wraith Caves need combat level %d."):format(zone.req), "warn")
		return
	end
	CombatService.stop(player, "left")
	GatherService.stop(player, "player")
	puff(hrp.Position, Color3.fromRGB(150, 230, 255))
	if zone.home then
		HomeService.teleport(player, "home")
	else
		-- arrive beside the stone, facing the road
		local road = zone.stone.X > 0 and -1 or 1
		local at = zone.stone + Vector3.new(road * 6, 3, 0)
		char:PivotTo(CFrame.lookAt(at, at + Vector3.new(road, 0, 0)))
	end
	task.defer(function()
		if char.Parent then
			puff(char:GetPivot().Position, Color3.fromRGB(150, 230, 255))
		end
	end)
end

function TravelService.init(world: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Waystones"
	for _, zone in Zones.LIST do
		if zone.stone then
			clearAround(world, zone.stone, 8)
			buildStone(folder, zone)
		end
	end
	folder.Parent = world

	-- walking into a zone unlocks its waystone
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in Players:GetPlayers() do
				local data = DataService.get(player)
				local char = player.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if data and hrp then
					local zone = Zones.LIST[Zones.indexAt(hrp.Position.X, hrp.Position.Z)]
					data.visited = data.visited or {}
					local allowed = not zone.wild or Combat.combatLevel(data.skills) >= zone.req
					if zone.stone and allowed and not TravelService.unlocked(data, zone.id) then
						data.visited[zone.id] = true
						DataService.sync(player)
						Remotes.Notify:FireClient(player, ("🗺️ Waystone unlocked: %s! Teleport here any time from the Map."):format(zone.name), "good")
					end
				end
			end
		end
	end)
end

return TravelService
