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

task.delay(3, function()
	UI.toast("Walk up to a tree, rock or fishing spot and press E (or tap) to start gathering.")
	task.wait(4)
	UI.toast("Leave while gathering and your hero keeps working offline (up to 12h).", "good")
end)
