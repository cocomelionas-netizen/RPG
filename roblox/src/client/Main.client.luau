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
	UI.floatText(("+%d XP %s   +%d %s"):format(g.xp, s.icon, g.count or 1, Items[g.item].icon), Color3.fromRGB(150, 230, 150))
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

Remotes.OpenCraft.OnClientEvent:Connect(function()
	UI.showPanel("craft")
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
			Brightness = th.cave and 0.4 or (th.lava and 1.4 or 2.2),
			Ambient = th.cave and Color3.fromRGB(45, 38, 60) or sky:Lerp(Color3.new(0.5, 0.5, 0.5), 0.6),
			OutdoorAmbient = th.cave and Color3.fromRGB(55, 45, 70) or sky2:Lerp(Color3.new(0.6, 0.6, 0.6), 0.4),
			ExposureCompensation = th.cave and 0.3 or 0,
		},
		atmosphere = {
			Color = sky2,
			Decay = far,
			Density = th.cave and 0.5 or th.lava and 0.42 or th.snow and 0.33 or 0.3,
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
		UI.zone(zone.name, i == 1 and "Where every adventurer starts out" or ("Recommended Lv " .. zone.req))
	end
end

task.spawn(function()
	while true do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local i = Zones.indexAt(hrp.Position.X)
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
