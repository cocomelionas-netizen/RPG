-- Endless Road (Roblox) – client entry point: UI, feedback effects and zone lighting
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)
local Skills = require(Shared.Skills)
local Items = require(Shared.Items)
local Zones = require(Shared.Zones)
local UI = require(script.Parent:WaitForChild("UI"))
local BuildSpots = require(script.Parent:WaitForChild("BuildSpots"))
local Interact = require(script.Parent:WaitForChild("Interact"))
Interact.init()

local player = Players.LocalPlayer

-- the hero's tools are handed out by the server; hide the Roblox hotbar
task.spawn(function()
	for _ = 1, 10 do
		if pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.Backpack, false) then
			break
		end
		task.wait(1)
	end
end)

UI.setRequest(function(action, ...)
	Remotes.Request:FireServer(action, ...)
end)

Remotes.DataSync.OnClientEvent:Connect(function(view)
	UI.setData(view)
	BuildSpots.refresh(view)
end)

Remotes.Notify.OnClientEvent:Connect(function(msg, kind)
	UI.toast(msg, kind)
end)

-- ===== gathering feedback =====
local current = nil -- info of the node being worked
local swingToken = 0

local function emit(node, n)
	local core = node and node.PrimaryPart
	local e = core and core:FindFirstChild("Chips")
	if e then
		e:Emit(n)
	end
end

Remotes.ActionState.OnClientEvent:Connect(function(info)
	if info.active then
		local first = not current or current.node ~= info.node
		current = info
		UI.actionStart(info)
		if first and info.skill ~= "fishing" then
			swingToken += 1
			local token = swingToken
			task.spawn(function()
				task.wait(0.35)
				while swingToken == token and current and current.node == info.node do
					emit(info.node, 5) -- chips fly in time with the swings
					task.wait(0.9)
				end
			end)
		end
	else
		current = nil
		swingToken += 1
		UI.actionStop()
		if info.reason == "moved" then
			UI.toast("You walked away and stopped gathering.")
		end
	end
end)

Remotes.Gathered.OnClientEvent:Connect(function(g)
	local s = Skills.byId[g.skill]
	emit(g.node, 14)
	local gain = (g.count or 1) > 0 and ("   +%d %s"):format(g.count or 1, Items[g.item].icon) or ""
	UI.floatText(("+%d XP %s%s"):format(g.xp, s.icon, gain), Color3.fromRGB(150, 230, 150))
	if g.levelUp then
		UI.banner("Level up!", ("%s %s is now level %d"):format(s.icon, s.name, g.levelUp))
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
		sound.Volume = 0.6
		sound.Parent = workspace.CurrentCamera
		sound:Play()
		game:GetService("Debris"):AddItem(sound, 3)
	end
end)

-- ===== build spots on the plot =====
BuildSpots.init(function(x, z)
	UI.openSpot(x, z)
end)

-- a station asks to open a window (workbench by default, the house plans from the Entrance Hall)
-- ===== combat feedback =====
Remotes.CombatState.OnClientEvent:Connect(function(info)
	UI.fightState(info)
end)

-- damage numbers that pop up over whoever was hit
local SPLAT = { hit = Color3.fromRGB(255, 80, 80), hurt = Color3.fromRGB(255, 160, 60), miss = Color3.fromRGB(120, 170, 255), block = Color3.fromRGB(120, 170, 255) }
Remotes.HitSplat.OnClientEvent:Connect(function(target, dmg, kind)
	if not target or not target.Parent then
		return
	end
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(70, 40)
	bb.StudsOffsetWorldSpace = Vector3.new(math.random(-10, 10) / 10, 3, 0)
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Adornee = target
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = SPLAT[kind] or Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0
	t.Text = dmg > 0 and tostring(dmg) or (kind == "block" and "block" or "miss")
	t.Parent = bb
	bb.Parent = player:WaitForChild("PlayerGui")
	local TweenService = game:GetService("TweenService")
	TweenService:Create(bb, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { StudsOffsetWorldSpace = bb.StudsOffsetWorldSpace + Vector3.new(0, 3, 0) }):Play()
	TweenService:Create(t, TweenInfo.new(0.9), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	game:GetService("Debris"):AddItem(bb, 1)
end)

-- PvP: an Attack prompt on other players while both of you are in the Wraith Caves
local pvpPrompts = {}
task.spawn(function()
	local wild = Zones.byId.wild
	local function inWild(char)
		local r = char and char:FindFirstChild("HumanoidRootPart")
		return r and Zones.contains(wild, r.Position.X, r.Position.Z)
	end
	while true do
		local meIn = inWild(player.Character)
		for _, other in Players:GetPlayers() do
			if other ~= player then
				local r = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
				local want = meIn and r and inWild(other.Character)
				local pr = pvpPrompts[other]
				if want and (not pr or pr.Parent ~= r) then
					if pr then pr:Destroy() end
					pr = Instance.new("ProximityPrompt")
					pr.Name = "PvpPrompt"
					pr.ActionText = "Attack"
					pr.ObjectText = "☠️ " .. other.DisplayName
					pr.HoldDuration = 0
					pr.MaxActivationDistance = 12
					pr.RequiresLineOfSight = false
					pr.KeyboardKeyCode = Enum.KeyCode.F
					pr.Triggered:Connect(function()
						Remotes.Request:FireServer("attackPlayer", other.UserId)
					end)
					pr.Parent = r
					pvpPrompts[other] = pr
				elseif not want and pr then
					pr:Destroy()
					pvpPrompts[other] = nil
				end
			end
		end
		task.wait(0.5)
	end
end)

Remotes.OpenCraft.OnClientEvent:Connect(function(panel, a, b)
	if panel == "plant" then
		UI.openPlant(a, b)
		return
	end
	UI.showPanel(nil)
	UI.showPanel(panel or "craft")
end)

Remotes.Offline.OnClientEvent:Connect(function(o)
	UI.offline(o)
end)

-- ===== zone lighting: each zone has its own sky, fog and time of day =====
local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atmosphere.Parent = Lighting
local hex = Color3.fromHex

local function zoneLook(th)
	local sky, sky2, far = hex(th.sky), hex(th.sky2), hex(th.far)
	local look = {
		lighting = {
			ClockTime = th.clock,
			-- caves: moody purple but bright enough to see every rock clearly
			Brightness = th.cave and 1.2 or (th.lava and 1.4 or 2.2),
			Ambient = th.ghostly and Color3.fromRGB(140, 175, 140) or th.cave and Color3.fromRGB(170, 155, 195) or sky:Lerp(Color3.new(0.5, 0.5, 0.5), 0.6),
			OutdoorAmbient = th.ghostly and Color3.fromRGB(150, 185, 150) or th.cave and Color3.fromRGB(180, 165, 205) or sky2:Lerp(Color3.new(0.6, 0.6, 0.6), 0.4),
			ExposureCompensation = th.cave and 0.7 or 0,
		},
		atmosphere = {
			Color = sky2,
			Decay = far,
			Density = th.cave and 0.32 or th.lava and 0.42 or th.snow and 0.33 or 0.3,
			Haze = th.lava and 2.5 or 1.2,
			Glare = th.snow and 0.4 or 0,
		},
	}
	return look
end

local zoneIndex = 0
local function applyZone(i, instant)
	local zone = Zones.LIST[i]
	local look = zoneLook(zone.th)
	local ti = TweenInfo.new(instant and 0 or 3, Enum.EasingStyle.Sine)
	TweenService:Create(Lighting, ti, look.lighting):Play()
	TweenService:Create(atmosphere, ti, look.atmosphere):Play()
	if not instant then
		UI.zone(zone.name, (zone.town or zone.home or zone.req <= 1) and zone.desc or ("Recommended Lv " .. zone.req))
	end
end

task.spawn(function()
	while true do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local i = Zones.indexAt(hrp.Position.X, hrp.Position.Z)
			if i ~= zoneIndex then
				applyZone(i, zoneIndex == 0)
				zoneIndex = i
			end
		end
		task.wait(0.5)
	end
end)

task.delay(4, function()
	UI.toast("Leave while gathering and your hero keeps working offline (up to 12h).", "good")
end)

-- ===== goal pointer: a bouncing arrow over the thing the next goal needs, and a glowing line to it =====
local arrow = Instance.new("BillboardGui")
arrow.Name = "GoalArrow"
arrow.Size = UDim2.fromOffset(60, 60)
arrow.AlwaysOnTop = true
arrow.LightInfluence = 0
arrow.Enabled = false
local arrowText = Instance.new("TextLabel")
arrowText.BackgroundTransparency = 1
arrowText.Size = UDim2.fromScale(1, 1)
arrowText.Text = "⬇️"
arrowText.TextScaled = true
arrowText.Parent = arrow
arrow.Parent = player:WaitForChild("PlayerGui")

local beam = Instance.new("Beam")
beam.Name = "GoalBeam"
beam.Color = ColorSequence.new(Color3.fromRGB(255, 190, 60))
beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.7) })
beam.LightEmission = 1
beam.LightInfluence = 0
beam.Width0, beam.Width1 = 0.5, 0.25
beam.FaceCamera = true
beam.Segments = 1
beam.Enabled = false
local targetAttachment = Instance.new("Attachment")
targetAttachment.Name = "GoalTarget"
targetAttachment.Parent = workspace.Terrain

local function nearestNode(skill, tier, from)
	local nodes = workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Nodes")
	local best, bd = nil, math.huge
	for _, n in nodes and nodes:GetChildren() or {} do
		if n:GetAttribute("Skill") == skill and n:GetAttribute("Tier") == tier and n.PrimaryPart then
			local d = (n.PrimaryPart.Position - from).Magnitude
			if d < bd then
				best, bd = n, d
			end
		end
	end
	return best
end

local function myBench()
	local town = workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Hometown")
	for _, plot in town and town.Plots:GetChildren() or {} do
		if plot:GetAttribute("Owner") == player.UserId then
			return plot:FindFirstChild("Workbench")
		end
	end
	return nil
end

task.spawn(function()
	local t = 0
	while true do
		local goal = UI.goal()
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local target = nil
		if goal and hrp then
			if goal.target == "tree0" then
				target = nearestNode("woodcutting", 0, hrp.Position)
			elseif goal.target == "rock0" then
				target = nearestNode("mining", 0, hrp.Position)
			elseif goal.target == "bench" then
				target = myBench()
			elseif goal.target == "stall" then
				target = workspace:FindFirstChild("SeedStall", true)
			elseif goal.target == "smithy" then
				target = workspace:FindFirstChild("Smithy", true)
			end
		end
		-- no arrow once the hero is already working right there
		local pos = target and target.PrimaryPart and target:GetPivot().Position
		local near = pos and hrp and (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)).Magnitude < 12
		if pos and not near then
			t += 0.1
			arrow.Adornee = target.PrimaryPart
			arrow.StudsOffsetWorldSpace = Vector3.new(0, 8 + math.sin(t * 4) * 0.8, 0)
			arrow.Enabled = true
			targetAttachment.WorldPosition = pos + Vector3.new(0, 1, 0)
			local a0 = hrp:FindFirstChild("GoalFrom")
			if not a0 then
				a0 = Instance.new("Attachment")
				a0.Name = "GoalFrom"
				a0.Position = Vector3.new(0, -2, 0)
				a0.Parent = hrp
			end
			beam.Attachment0, beam.Attachment1 = a0, targetAttachment
			beam.Parent = workspace.Terrain
			beam.Enabled = true
		else
			arrow.Enabled = false
			beam.Enabled = false
		end
		task.wait(0.1)
	end
end)

-- ===== node labels: green level when you can gather there, red with a lock when you can't yet =====
local XP = require(Shared.XP)
local CAN = Color3.fromRGB(130, 240, 130)
local CANT = Color3.fromRGB(255, 110, 95)
task.spawn(function()
	while true do
		local view = UI.getData()
		local nodes = workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Nodes")
		if view and nodes then
			for _, n in nodes:GetChildren() do
				local core = n.PrimaryPart
				local bb = core and core:FindFirstChild("LabelAnchor") and core.LabelAnchor:FindFirstChild("NodeLabel")
				local lv = bb and bb:FindFirstChild("Level", true)
				if lv then
					local req = bb:GetAttribute("Req") or 1
					local ok = XP.levelFromXp(view.skills[n:GetAttribute("Skill")] or 0) >= req
					lv.Text = ok and ("Lv " .. req) or ("🔒 Needs Lv " .. req)
					lv.TextColor3 = ok and CAN or CANT
				end
			end
		end
		task.wait(1)
	end
end)

-- ===== fish fins circle inside their ripple =====
local RunService = game:GetService("RunService")
-- (the place streams parts in and out, so fins are picked up as they arrive and dropped when they leave)
local fins = {}
local function addFin(d)
	if d:IsA("BasePart") and d:GetAttribute("Swim") and not fins[d] then
		fins[d] = { part = d, center = d.Position - Vector3.new(1.5, 0.5, 0), phase = math.random() * 6 }
	end
end
task.spawn(function()
	local world = workspace:WaitForChild("World")
	world.DescendantAdded:Connect(addFin)
	world.DescendantRemoving:Connect(function(d)
		fins[d] = nil
	end)
	for _, d in world:GetDescendants() do
		addFin(d)
	end
end)
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for _, f in fins do
		local a = t * 1.2 + f.phase
		local p = f.center + Vector3.new(math.cos(a) * 1.6, 0.35 + math.sin(t * 3 + f.phase) * 0.15, math.sin(a) * 1.6)
		f.part.CFrame = CFrame.lookAt(p, p + Vector3.new(-math.sin(a), 0, math.cos(a)))
	end
end)
