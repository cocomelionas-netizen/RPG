-- The player's side: walking up to whatever you tapped and facing it while you fight, hit splats, the rats'
-- names, health bars and moves, the swing's swish and trail, xp drops, the skills panel and the combat style.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local ContentProvider = game:GetService("ContentProvider")
local PathfindingService = game:GetService("PathfindingService")
local StarterPlayer = game:GetService("StarterPlayer")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes = ReplicatedStorage:WaitForChild("Remotes")

local player = Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.Name = "Hud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")

local FONT = Enum.Font.FredokaOne
local GOLD = Color3.fromRGB(255, 220, 90)

local function corner(parent: Instance, r: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 10)
	c.Parent = parent
end

local function stroke(parent: Instance, thickness: number?, color: Color3?)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness or 2
	s.Color = color or Color3.new(0, 0, 0)
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Parent = parent
	return s
end

local function label(parent: Instance, text: string, size: number, color: Color3?): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = FONT
	l.Text = text
	l.TextSize = size
	l.TextColor3 = color or Color3.new(1, 1, 1)
	stroke(l, 1.5)
	l.Parent = parent
	return l
end

local function sound(id: number, parent: Instance, volume: number?, pitch: number?)
	local s = Instance.new("Sound")
	s.SoundId = "rbxassetid://" .. id
	s.Volume = volume or 0.6
	s.PlaybackSpeed = pitch or 1
	s.RollOffMaxDistance = 80
	s.Parent = parent
	s:Play()
	s.Ended:Once(function()
		s:Destroy()
	end)
end

-- ===== skills panel and hitpoints =====

local panel = Instance.new("Frame")
panel.Name = "Skills"
panel.Position = UDim2.fromOffset(12, 12)
panel.Size = UDim2.fromOffset(200, 0)
panel.AutomaticSize = Enum.AutomaticSize.Y
panel.BackgroundColor3 = Color3.fromRGB(40, 34, 28)
panel.BackgroundTransparency = 0.15
corner(panel, 12)
stroke(panel, 2, Color3.fromRGB(120, 96, 60)).ApplyStrokeMode = Enum.ApplyStrokeMode.Border
panel.Parent = gui
local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 4)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = panel
local pad = Instance.new("UIPadding")
pad.PaddingTop = UDim.new(0, 8)
pad.PaddingBottom = UDim.new(0, 8)
pad.PaddingLeft = UDim.new(0, 10)
pad.PaddingRight = UDim.new(0, 10)
pad.Parent = panel

local hpBack = Instance.new("Frame")
hpBack.LayoutOrder = 0
hpBack.Size = UDim2.new(1, 0, 0, 24)
hpBack.BackgroundColor3 = Color3.fromRGB(110, 20, 20)
corner(hpBack, 8)
hpBack.Parent = panel
local hpFill = Instance.new("Frame")
hpFill.Size = UDim2.fromScale(1, 1)
hpFill.BackgroundColor3 = Color3.fromRGB(70, 190, 70)
corner(hpFill, 8)
hpFill.Parent = hpBack
local hpText = label(hpBack, "10 / 10", 18)
hpText.Size = UDim2.fromScale(1, 1)
hpText.ZIndex = 2

local ICONS = { Attack = "⚔️", Strength = "💪", Defence = "🛡️", Hitpoints = "❤️" }
local rows = {}
for i, skill in Config.SKILLS do
	local l = label(panel, "", 18)
	l.LayoutOrder = i
	l.Size = UDim2.new(1, 0, 0, 22)
	l.TextXAlignment = Enum.TextXAlignment.Left
	rows[skill] = l
end
local function refreshSkills()
	for skill, l in rows do
		local xp = player:GetAttribute("XP_" .. skill) or 0
		l.Text = string.format("%s %s  <font color=\"#ffdc5a\">%d</font>", ICONS[skill], skill, Config.levelFor(xp))
		l.RichText = true
	end
end
for _, skill in Config.SKILLS do
	player:GetAttributeChangedSignal("XP_" .. skill):Connect(refreshSkills)
end
refreshSkills()

local function watchHealth(hum: Humanoid)
	local function update()
		local max = math.max(1, hum.MaxHealth)
		hpFill.Size = UDim2.fromScale(math.clamp(hum.Health / max, 0, 1), 1)
		hpText.Text = string.format("❤️ %d / %d", math.ceil(hum.Health), max)
	end
	hum.HealthChanged:Connect(update)
	hum:GetPropertyChangedSignal("MaxHealth"):Connect(update)
	update()
end

-- ===== combat style =====

local styleButton = Instance.new("TextButton")
styleButton.Name = "Style"
styleButton.AnchorPoint = Vector2.new(1, 1)
styleButton.Position = UDim2.new(1, -12, 1, -12)
styleButton.Size = UDim2.fromOffset(190, 56)
styleButton.BackgroundColor3 = Color3.fromRGB(150, 50, 40)
styleButton.Font = FONT
styleButton.TextSize = 18
styleButton.TextColor3 = Color3.new(1, 1, 1)
styleButton.AutoButtonColor = true
corner(styleButton, 14)
stroke(styleButton, 2, Color3.fromRGB(70, 20, 15)).ApplyStrokeMode = Enum.ApplyStrokeMode.Border
styleButton.Parent = gui
local function refreshStyle()
	local s = Config.styleById(player:GetAttribute("Style"))
	styleButton.Text = string.format("⚔️ %s\n<font size=\"14\">trains %s</font>", s.name, s.skill)
	styleButton.RichText = true
end
player:GetAttributeChangedSignal("Style"):Connect(refreshStyle)
refreshStyle()
styleButton.Activated:Connect(function()
	local current = Config.styleById(player:GetAttribute("Style"))
	for i, s in Config.STYLES do
		if s == current then
			remotes.SetStyle:FireServer(Config.STYLES[i % #Config.STYLES + 1].id)
		end
	end
end)

-- ===== messages and xp drops =====

local messageLabel = label(gui, "", 22)
messageLabel.AnchorPoint = Vector2.new(0.5, 1)
messageLabel.Position = UDim2.new(0.5, 0, 1, -80)
messageLabel.Size = UDim2.new(0.8, 0, 0, 30)
messageLabel.TextTransparency = 1
messageLabel.TextStrokeTransparency = 1
local messageSeq = 0
remotes.Message.OnClientEvent:Connect(function(text: string, kind: string?)
	messageSeq += 1
	local seq = messageSeq
	messageLabel.Text = text
	messageLabel.TextColor3 = kind == "level" and GOLD or kind == "dead" and Color3.fromRGB(255, 90, 80) or Color3.new(1, 1, 1)
	messageLabel.TextTransparency = 0
	task.delay(3, function()
		if seq == messageSeq then
			TweenService:Create(messageLabel, TweenInfo.new(0.6), { TextTransparency = 1 }):Play()
		end
	end)
end)

remotes.Xp.OnClientEvent:Connect(function(skill: string, amount: number)
	local l = label(gui, string.format("%s +%s xp", ICONS[skill] or "", (amount % 1 == 0) and tostring(amount) or string.format("%.1f", amount)), 20, GOLD)
	l.AnchorPoint = Vector2.new(1, 0.5)
	l.Position = UDim2.new(1, -20, 0.45, skill == "Hitpoints" and 26 or 0)
	l.Size = UDim2.fromOffset(160, 26)
	l.TextXAlignment = Enum.TextXAlignment.Right
	TweenService:Create(l, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Position = l.Position - UDim2.fromOffset(0, 70), TextTransparency = 1 }):Play()
	task.delay(1.5, l.Destroy, l)
end)

-- ===== hit splats =====

remotes.Splat.OnClientEvent:Connect(function(target: BasePart, dmg: number, by: Player?)
	if not target or not target.Parent then
		return
	end
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(44, 44)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 1.2, 0)
	bb.AlwaysOnTop = true
	bb.Adornee = target
	bb.Parent = gui
	local disc = Instance.new("Frame")
	disc.AnchorPoint = Vector2.new(0.5, 0.5)
	disc.Position = UDim2.fromScale(0.5, 0.5)
	disc.Size = UDim2.fromScale(0.4, 0.4)
	disc.BackgroundColor3 = dmg > 0 and Color3.fromRGB(190, 20, 20) or Color3.fromRGB(40, 90, 200)
	corner(disc, 22)
	stroke(disc, 2, Color3.fromRGB(30, 0, 0)).ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	disc.Parent = bb
	local n = label(disc, tostring(dmg), 22)
	n.Size = UDim2.fromScale(1, 1)
	TweenService:Create(disc, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromScale(1, 1) }):Play()
	if dmg > 0 then
		sound(Config.SOUNDS.Hit, target, 0.7, by == player and 1 or 0.9)
	end
	task.delay(1.1, function()
		TweenService:Create(disc, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(n, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
		task.delay(0.3, bb.Destroy, bb)
	end)
end)

-- ===== the hero's swing: swish and blade trail =====

local slashIds = {
	["rbxassetid://" .. Config.ANIM.RobloxSlash] = true,
	["rbxassetid://" .. Config.ANIM.Slash] = Config.ANIM.Slash ~= 0 or nil,
}
local function watchSwings(char: Model)
	local hum = char:WaitForChild("Humanoid", 10)
	local animator = hum and hum:WaitForChild("Animator", 10) :: Animator?
	if not animator then
		return
	end
	animator.AnimationPlayed:Connect(function(track: AnimationTrack)
		if not slashIds[track.Animation.AnimationId] then
			return
		end
		local tool = char:FindFirstChildOfClass("Tool")
		local handle = tool and tool:FindFirstChild("Handle")
		local trail = handle and handle:FindFirstChildOfClass("Trail")
		-- the blade starts coming down just before contact: the swish and trail cover the downswing and follow-through
		task.delay(Config.CONTACT * 0.7, function()
			if handle then
				sound(Config.SOUNDS.Swish, handle, 0.5, 0.95 + math.random() * 0.15)
			end
			if trail then
				trail.Enabled = true
				task.delay(0.3, function()
					trail.Enabled = false
				end)
			end
		end)
	end)
end
local function hookPlayer(p: Player)
	p.CharacterAdded:Connect(watchSwings)
	if p.Character then
		task.spawn(watchSwings, p.Character)
	end
end
for _, p in Players:GetPlayers() do
	hookPlayer(p)
end
Players.PlayerAdded:Connect(hookPlayer)

-- ===== rats: name, health bar, flinch, bite, death =====

local function decorate(m: Model)
	local head = m:WaitForChild("Head", 5) :: BasePart?
	local hrp = m:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	if not head or not hrp then
		return
	end
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(140, 40)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 1.6, 0)
	bb.MaxDistance = 60
	bb.Adornee = head
	bb.Parent = m
	local name = label(bb, string.format("%s  <font color=\"#ffdc5a\">(level-%d)</font>", m.Name, m:GetAttribute("Level") or 1), 16)
	name.RichText = true
	name.Size = UDim2.new(1, 0, 0, 20)
	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0.5, 0)
	bar.Position = UDim2.new(0.5, 0, 0, 24)
	bar.Size = UDim2.fromOffset(60, 8)
	bar.BackgroundColor3 = Color3.fromRGB(200, 20, 20)
	bar.BorderSizePixel = 0
	bar.Visible = false
	bar.Parent = bb
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(40, 220, 40)
	fill.BorderSizePixel = 0
	fill.Parent = bar
	local function hp()
		local cur, max = m:GetAttribute("Hp") or 1, m:GetAttribute("MaxHp") or 1
		fill.Size = UDim2.fromScale(math.clamp(cur / max, 0, 1), 1)
		bar.Visible = cur < max
	end
	m:GetAttributeChangedSignal("Hp"):Connect(hp)
	hp()

	local body = hrp:FindFirstChild("Body") :: Motor6D?
	local rest = body and body.C0
	-- flinch: a red flash and a hop back
	m:GetAttributeChangedSignal("Hurt"):Connect(function()
		local hl = Instance.new("Highlight")
		hl.FillColor = Color3.fromRGB(255, 40, 40)
		hl.FillTransparency = 0.35
		hl.OutlineTransparency = 1
		hl.Parent = m
		TweenService:Create(hl, TweenInfo.new(0.3), { FillTransparency = 1 }):Play()
		task.delay(0.32, hl.Destroy, hl)
		if body and rest then
			body.C0 = rest * CFrame.new(0, 0.15, 0.35) * CFrame.Angles(math.rad(12), 0, 0)
			TweenService:Create(body, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { C0 = rest }):Play()
		end
	end)
	-- the bite: rear up, then lunge
	m:GetAttributeChangedSignal("Atk"):Connect(function()
		if not body or not rest then
			return
		end
		local up = TweenService:Create(body, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { C0 = rest * CFrame.new(0, 0.2, 0.3) * CFrame.Angles(math.rad(18), 0, 0) })
		local lunge = TweenService:Create(body, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { C0 = rest * CFrame.new(0, -0.05, -0.8) * CFrame.Angles(math.rad(-8), 0, 0) })
		local back = TweenService:Create(body, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { C0 = rest })
		up:Play()
		up.Completed:Once(function()
			lunge:Play()
		end)
		lunge.Completed:Once(function()
			back:Play()
		end)
	end)
	-- death: roll over onto its back and fade
	m:GetAttributeChangedSignal("Dead"):Connect(function()
		bb.Enabled = false
		if body and rest then
			TweenService:Create(body, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { C0 = rest * CFrame.new(0, -0.2, 0) * CFrame.Angles(0, 0, math.rad(170)) }):Play()
		end
		task.delay(0.8, function()
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") and d.Transparency < 1 then
					TweenService:Create(d, TweenInfo.new(0.6), { Transparency = 1 }):Play()
				end
			end
		end)
	end)
end
CollectionService:GetInstanceAddedSignal("Enemy"):Connect(decorate)
for _, m in CollectionService:GetTagged("Enemy") do
	task.spawn(decorate, m)
end

-- ===== walking up to the target and facing it =====

-- how hard the player is steering (stick or keys). Roblox's newer player module sits in StarterPlayer and reads
-- it through an InputAction; the older one sits in PlayerScripts and has GetControls
local steering = function(): number
	return 0
end
task.spawn(function()
	local module = StarterPlayer:FindFirstChild("PlayerModule")
	local move = module and module:FindFirstChild("MoveAction", true)
	if move and move:IsA("InputAction") then
		steering = function()
			return (move:GetState() :: Vector2).Magnitude
		end
		return
	end
	local old = player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 15)
	local ok, controls = pcall(function()
		return require(old :: ModuleScript):GetControls()
	end)
	if ok and controls then
		steering = function()
			return controls:GetMoveVector().Magnitude
		end
	end
end)
local target: Model? = nil
local lastMove = 0
local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = false, WaypointSpacing = 4 })
local route = { busy = false, at = 0, goal = Vector3.zero, points = nil :: { any }?, i = 1 }
remotes.Fight.OnClientEvent:Connect(function(m: Model?)
	target = m
	lastMove = 0
	route.points = nil
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum and not m then
		hum.AutoRotate = true
	end
end)

RunService.Heartbeat:Connect(function()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not target or not hum or not hrp then
		return
	end
	local troot = target:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not troot or not target.Parent then
		target = nil
		hum.AutoRotate = true
		return
	end
	-- walking off (stick or keys) ends the fight, as clicking away does in OSRS
	if steering() > 0.1 then
		target = nil
		hum.AutoRotate = true
		remotes.StopFight:FireServer()
		return
	end
	local offset = (hrp.Position - troot.Position) * Vector3.new(1, 0, 1)
	local dist = offset.Magnitude - 1.6
	if dist > Config.REACH - 1 then
		hum.AutoRotate = true
		local goal = troot.Position + offset.Unit * (1.6 + Config.REACH - 2)
		-- a path around fences and walls, worked out again when the target has moved off it
		if not route.busy and (not route.points or (route.goal - goal).Magnitude > 3 and os.clock() - route.at > 0.8) then
			route.busy = true
			task.spawn(function()
				local ok = pcall(path.ComputeAsync, path, hrp.Position, goal)
				route.busy = false
				route.at = os.clock()
				route.goal = goal
				route.points = ok and path.Status == Enum.PathStatus.Success and path:GetWaypoints() or { { Position = goal } }
				route.i = math.min(2, #route.points)
			end)
		end
		if route.points then
			local wp = route.points[route.i]
			if wp and route.i < #route.points and ((wp.Position - hrp.Position) * Vector3.new(1, 0, 1)).Magnitude < 2.5 then
				route.i += 1
				wp = route.points[route.i]
			end
			if wp and os.clock() - lastMove > 0.2 then
				lastMove = os.clock()
				hum:MoveTo(route.i >= #route.points and goal or wp.Position)
			end
		end
	else
		route.points = nil
		hum.AutoRotate = false
		local look = Vector3.new(troot.Position.X, hrp.Position.Y, troot.Position.Z)
		hrp.CFrame = hrp.CFrame:Lerp(CFrame.lookAt(hrp.Position, look), 0.25)
	end
end)

-- ===== the windmill's sails =====

local sails = {}
local function addSails(m: Model)
	local hub = m.PrimaryPart or m:FindFirstChild("Hub") :: BasePart?
	if not hub then
		return
	end
	local center = CFrame.new(hub.Position)
	local parts = {}
	for _, p in m:GetDescendants() do
		if p:IsA("BasePart") then
			parts[p] = center:ToObjectSpace(p.CFrame)
		end
	end
	table.insert(sails, { center = center, parts = parts })
end
CollectionService:GetInstanceAddedSignal("Sails"):Connect(addSails)
for _, m in CollectionService:GetTagged("Sails") do
	task.spawn(addSails, m)
end
RunService.RenderStepped:Connect(function()
	local a = os.clock() * 0.6
	for _, s in sails do
		local turn = s.center * CFrame.Angles(0, 0, a)
		for p, off in s.parts do
			p.CFrame = turn * off
		end
	end
end)

-- ===== spawning =====

local function onCharacter(char: Model)
	local hum = char:WaitForChild("Humanoid") :: Humanoid
	watchHealth(hum)
	target = nil
end
player.CharacterAdded:Connect(onCharacter)
if player.Character then
	task.spawn(onCharacter, player.Character)
end

task.spawn(function()
	local assets = {}
	for _, id in { Config.SOUNDS.Swish, Config.SOUNDS.Hit } do
		local s = Instance.new("Sound")
		s.SoundId = "rbxassetid://" .. id
		table.insert(assets, s)
	end
	ContentProvider:PreloadAsync(assets)
end)
