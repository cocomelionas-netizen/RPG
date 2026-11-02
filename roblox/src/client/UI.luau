-- All of the game's screen UI, built in code (no uploaded assets needed).
-- Layout: currency + next goal at the top centre, skills bottom-left, menu on the right, windows in the middle.
-- Windows fill most of the screen on phones so text stays readable; everything else scales with the screen height.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Skills = require(Shared.Skills)
local XP = require(Shared.XP)
local Items = require(Shared.Items)
local G = require(Shared.Gathering)
local Construction = require(Shared.Construction)
local Goals = require(Shared.Goals)
local Icons = require(Shared.Icons)
local Tiers = require(Shared.Tiers)
local Zones = require(Shared.Zones)

local player = Players.LocalPlayer
local UI = {}

-- ===== style =====
local C = {
	bg = Color3.fromRGB(24, 22, 38),
	panel = Color3.fromRGB(36, 33, 56),
	panel2 = Color3.fromRGB(50, 46, 76),
	stroke = Color3.fromRGB(110, 98, 160),
	text = Color3.fromRGB(246, 242, 255),
	muted = Color3.fromRGB(176, 170, 204),
	gold = Color3.fromRGB(255, 205, 70),
	good = Color3.fromRGB(88, 200, 110),
	warn = Color3.fromRGB(255, 120, 95),
	bar = Color3.fromRGB(110, 220, 120),
	barBg = Color3.fromRGB(18, 16, 30),
	button = Color3.fromRGB(80, 120, 230),
	locked = Color3.fromRGB(84, 80, 104),
	goal = Color3.fromRGB(255, 180, 60),
}
-- each window and menu button has its own accent colour
local ACCENT = {
	bag = Color3.fromRGB(230, 130, 60),
	skills = Color3.fromRGB(90, 170, 240),
	tools = Color3.fromRGB(160, 160, 175),
	house = Color3.fromRGB(110, 200, 110),
	craft = Color3.fromRGB(190, 140, 80),
	spot = Color3.fromRGB(230, 170, 40),
	seeds = Color3.fromRGB(90, 180, 70),
	plant = Color3.fromRGB(90, 180, 70),
	travel = Color3.fromRGB(60, 180, 200),
	home = Color3.fromRGB(200, 110, 200),
	combat = Color3.fromRGB(220, 80, 80),
	smithy = Color3.fromRGB(150, 150, 165),
}
local TITLE = Enum.Font.FredokaOne
local BOLD = Enum.Font.GothamBold
local FONT = Enum.Font.GothamMedium

local function new(class: string, props, children)
	local o = Instance.new(class)
	for k, v in props or {} do
		if k ~= "Parent" then
			o[k] = v
		end
	end
	for _, c in children or {} do
		c.Parent = o
	end
	if props and props.Parent then
		o.Parent = props.Parent
	end
	return o
end

local function corner(r)
	return new("UICorner", { CornerRadius = UDim.new(0, r or 10) })
end
local function stroke(color, t)
	return new("UIStroke", { Color = color or C.stroke, Thickness = t or 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end
local function pad(p)
	return new("UIPadding", { PaddingLeft = UDim.new(0, p), PaddingRight = UDim.new(0, p), PaddingTop = UDim.new(0, p), PaddingBottom = UDim.new(0, p) })
end
-- a soft top-to-bottom shine on panels and buttons
local function shine(amount)
	return new("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1 - (amount or 0.18), 1 - (amount or 0.18), 1 - (amount or 0.18))),
	})
end

-- a label that holds just one emoji shows the matching Noto 3D picture instead (Icons.luau), also when its text changes
local function iconize(label: TextLabel)
	local img = nil
	local shown = label.TextTransparency
	local function update()
		local id = Icons.get(label.Text)
		if id then
			if not img then
				local px = math.max(16, label.TextSize * 1.3)
				img = new("ImageLabel", {
					Name = "Icon", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromOffset(px, px), ScaleType = Enum.ScaleType.Fit, ZIndex = label.ZIndex, Parent = label,
				})
			end
			img.Image = id
			img.Visible = true
			label.TextTransparency = 1
		else
			if img then
				img.Visible = false
			end
			label.TextTransparency = shown
		end
	end
	update()
	label:GetPropertyChangedSignal("Text"):Connect(update)
end

local function text(props, children)
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.Font = props.Font or FONT
	props.TextColor3 = props.TextColor3 or C.text
	props.TextSize = props.TextSize or 16
	local label = new("TextLabel", props, children)
	iconize(label)
	return label
end

-- buttons squash a little when pressed so every tap feels answered
local function button(props, onClick)
	props.BackgroundColor3 = props.BackgroundColor3 or C.button
	props.Font = props.Font or TITLE
	props.TextColor3 = props.TextColor3 or Color3.new(1, 1, 1)
	props.TextSize = props.TextSize or 18
	props.AutoButtonColor = true
	local b = new("TextButton", props, { corner(10), shine() })
	local sc = new("UIScale", { Parent = b })
	b.MouseButton1Down:Connect(function()
		TweenService:Create(sc, TweenInfo.new(0.07), { Scale = 0.92 }):Play()
	end)
	local function release()
		TweenService:Create(sc, TweenInfo.new(0.18, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
	b.MouseButton1Up:Connect(release)
	b.MouseLeave:Connect(release)
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b
end

local function bar(parent, props, color)
	local bg = new("Frame", { BackgroundColor3 = C.barBg, BorderSizePixel = 0, Parent = parent }, { corner(6) })
	for k, v in props do
		bg[k] = v
	end
	local fill = new("Frame", { Name = "Fill", BackgroundColor3 = color or C.bar, BorderSizePixel = 0, Size = UDim2.new(0, 0, 1, 0), Parent = bg }, { corner(6), shine(0.3) })
	return bg, fill
end

function UI.fmt(n: number): string
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end
local fmt = UI.fmt

-- ===== state =====
local state = nil -- latest DataSync view
local openPanel = nil
local selectedItem = nil
local request = function() end -- function(action, ...) set by Main

local gui = new("ScreenGui", {
	Name = "EndlessRoadUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
	Parent = player:WaitForChild("PlayerGui"),
})
local isPhone = false
local scale = new("UIScale", { Parent = gui })
-- windows, toasts and banners live in their own layer that is never shrunk, so text stays readable on phones
local wgui = new("ScreenGui", {
	Name = "EndlessRoadWindows", ResetOnSpawn = false, DisplayOrder = 5, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
	Parent = player:WaitForChild("PlayerGui"),
})

-- ===== bottom-left column: next goal, gold and total level, then the skills =====
-- (the top of the screen belongs to Roblox: chat on the left, player list on the right)
local left = new("Frame", {
	Name = "Left", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 10, 1, -10),
	Size = UDim2.fromOffset(330, 300), Parent = gui,
}, { new("UIListLayout", { Name = "List", Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = Enum.SortOrder.LayoutOrder }) })

local goalCard = new("Frame", {
	Name = "Goal", LayoutOrder = 1, BackgroundColor3 = C.bg, BackgroundTransparency = 0.08,
	Size = UDim2.fromOffset(330, 76), Visible = false, Parent = left,
}, { corner(12), stroke(C.goal, 2), pad(8) })

local top = new("Frame", { Name = "Currency", LayoutOrder = 2, BackgroundTransparency = 1, Size = UDim2.fromOffset(330, 38), Parent = left }, {
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
})
local function pill(icon, color, order)
	local f = new("Frame", { LayoutOrder = order, BackgroundColor3 = C.bg, BackgroundTransparency = 0.08, Size = UDim2.fromOffset(150, 38), Parent = top }, { corner(19), stroke(color, 2) })
	text({ Text = icon, Position = UDim2.fromOffset(6, 0), Size = UDim2.fromOffset(30, 38), TextSize = 21, Parent = f })
	return text({ Text = "0", Position = UDim2.fromOffset(38, 0), Size = UDim2.new(1, -46, 1, 0), Font = TITLE, TextSize = 21, TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Left, Parent = f })
end
local goldLabel = pill("💰", C.gold, 1)
local totalLabel = pill("⭐", Color3.fromRGB(150, 200, 255), 2)
local goalTitle = text({ Text = "🎯 NEXT GOAL", Size = UDim2.new(1, 0, 0, 16), Font = TITLE, TextSize = 14, TextColor3 = C.goal, TextXAlignment = Enum.TextXAlignment.Left, Parent = goalCard })
local goalText = text({ Text = "", Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, -54, 0, 38), Font = BOLD, TextSize = 15, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Parent = goalCard })
local goalCount = text({ Text = "", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 18), Size = UDim2.fromOffset(50, 22), Font = TITLE, TextSize = 17, TextColor3 = C.goal, TextXAlignment = Enum.TextXAlignment.Right, Parent = goalCard })
local _, goalFill = bar(goalCard, { Position = UDim2.new(0, 0, 1, -4), Size = UDim2.new(1, 0, 0, 5) }, C.goal)

-- ===== health (and cave loot in the Wraith Caves) =====
local vitals = new("Frame", { Name = "Vitals", LayoutOrder = 3, BackgroundTransparency = 1, Size = UDim2.fromOffset(330, 30), Parent = left }, {
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
})
local healthBox = new("Frame", { Name = "Health", LayoutOrder = 1, BackgroundColor3 = C.bg, BackgroundTransparency = 0.08, Size = UDim2.fromOffset(240, 30), Parent = vitals }, { corner(15), stroke(Color3.fromRGB(230, 80, 80), 2) })
text({ Text = "❤️", Position = UDim2.fromOffset(6, 0), Size = UDim2.fromOffset(24, 30), TextSize = 17, Parent = healthBox })
local _, healthFill = bar(healthBox, { Position = UDim2.fromOffset(34, 9), Size = UDim2.new(1, -110, 0, 12) }, Color3.fromRGB(230, 70, 70))
local healthText = text({ Text = "", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 0), Size = UDim2.fromOffset(70, 30), Font = TITLE, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Right, Parent = healthBox })
local lootBox = new("Frame", { Name = "CaveLoot", LayoutOrder = 2, BackgroundColor3 = Color3.fromRGB(30, 50, 30), BackgroundTransparency = 0.05, Size = UDim2.fromOffset(82, 30), Visible = false, Parent = vitals }, { corner(15), stroke(Color3.fromRGB(150, 255, 150), 2) })
local lootText = text({ Text = "", Size = UDim2.fromScale(1, 1), Font = TITLE, TextSize = 14, TextColor3 = Color3.fromRGB(190, 255, 190), Parent = lootBox })
task.spawn(function()
	while true do
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if hum and hum.MaxHealth > 0 then
			healthFill.Size = UDim2.new(math.clamp(hum.Health / hum.MaxHealth, 0, 1), 0, 1, 0)
			healthText.Text = ("%d/%d"):format(math.ceil(hum.Health), hum.MaxHealth)
		end
		task.wait(0.2)
	end
end)

-- ===== bottom-left: skills being trained =====
local hud = new("Frame", {
	Name = "SkillHud", LayoutOrder = 4, BackgroundColor3 = C.bg, BackgroundTransparency = 0.1,
	Size = UDim2.fromOffset(240, #Skills.GATHERING * 36 + 16), Parent = left,
}, { corner(12), stroke(), pad(8), new("UIListLayout", { Padding = UDim.new(0, 4) }) })
local hudRows = {}
for _, id in Skills.GATHERING do
	local s = Skills.byId[id]
	local row = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 32), Parent = hud })
	text({ Text = s.icon, Size = UDim2.fromOffset(28, 32), TextSize = 20, Parent = row })
	local name = text({ Text = s.name, Position = UDim2.fromOffset(32, 0), Size = UDim2.new(1, -90, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, Font = BOLD, TextSize = 14, Parent = row })
	local lv = text({ Text = "1", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(56, 18), TextXAlignment = Enum.TextXAlignment.Right, Font = TITLE, TextSize = 16, TextColor3 = C.gold, Parent = row })
	local _, fill = bar(row, { Position = UDim2.fromOffset(32, 21), Size = UDim2.new(1, -32, 0, 8) })
	hudRows[id] = { lv = lv, fill = fill, row = row, name = name }
end

-- ===== right side: menu buttons =====
local menu = new("Frame", {
	Name = "Menu", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -10, 0.5, 0),
	Size = UDim2.fromOffset(70, 5 * 70 + 4 * 8), Parent = gui,
}, { new("UIListLayout", { Name = "List", Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder }) })
local menuButtons = {}
local menuCount = 0

-- ===== windows =====
-- the dimmed backdrop is a plain frame: taps go through it to the menu buttons
local dim = new("Frame", { Name = "Dim", BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5, Size = UDim2.new(1, 0, 1, 80), Position = UDim2.fromOffset(0, -80), Visible = false, Parent = wgui })
local window = new("Frame", {
	Name = "Window", BackgroundColor3 = C.panel, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.52),
	Size = UDim2.new(0.6, 0, 0.74, 0), Visible = false, ZIndex = 3, Parent = wgui,
}, { corner(16), stroke(C.stroke, 3), new("UISizeConstraint", { MinSize = Vector2.new(360, 260), MaxSize = Vector2.new(640, 470) }) })
local header = new("Frame", { Name = "Header", BackgroundColor3 = ACCENT.bag, Size = UDim2.new(1, 0, 0, 52), ZIndex = 3, Parent = window }, { corner(16), shine(0.3) })
-- square off the header's bottom corners
new("Frame", { BackgroundColor3 = ACCENT.bag, BorderSizePixel = 0, Position = UDim2.new(0, 0, 1, -16), Size = UDim2.new(1, 0, 0, 16), ZIndex = 3, Parent = header }, { shine(0.3) })
local windowTitle = text({ Text = "", Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -80, 1, 0), Font = TITLE, TextSize = 26, TextXAlignment = Enum.TextXAlignment.Left, TextStrokeTransparency = 0.6, ZIndex = 4, Parent = header })
local body = new("Frame", { Name = "Body", BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 62), Size = UDim2.new(1, -24, 1, -72), ZIndex = 3, Parent = window })
local windowScale = new("UIScale", { Parent = window })

local panels = {}
local renderers = {}
local TITLES = { bag = "🎒 Bag", skills = "📊 Skills", tools = "🛠️ Tools", house = "🏗️ My House", craft = "🔨 Workbench", spot = "➕ What to build here?", seeds = "🌱 Seed Stall", plant = "🌱 Plant", combat = "⚔️ Combat", smithy = "⚔️ Smithy", travel = "🗺️ Map" }

local function showPanel(name)
	if openPanel == name or not name then
		openPanel = nil
		window.Visible = false
		dim.Visible = false
		return
	end
	openPanel = name
	for n, p in panels do
		p.Visible = n == name
	end
	windowTitle.Text = TITLES[name]
	header.BackgroundColor3 = ACCENT[name]
	header:FindFirstChildOfClass("Frame").BackgroundColor3 = ACCENT[name]
	window.Visible = true
	dim.Visible = true
	windowScale.Scale = 0.85
	TweenService:Create(windowScale, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	if renderers[name] then
		renderers[name]()
	end
end
UI.showPanel = showPanel

button({ Name = "Close", Text = "X", Size = UDim2.fromOffset(40, 40), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -8, 0.5, 0), BackgroundColor3 = Color3.fromRGB(200, 70, 70), TextSize = 22, ZIndex = 4, Parent = header }, function()
	showPanel(nil)
end)

local function menuButton(name, icon, label, color, onClick)
	menuCount += 1
	local b = button({ Name = name, LayoutOrder = menuCount, Text = "", Size = UDim2.fromOffset(70, 70), BackgroundColor3 = C.bg, Parent = menu }, onClick)
	local st = stroke(color, 2.5)
	st.Parent = b
	local disc = new("Frame", { BackgroundColor3 = color, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(40, 40), Parent = b }, { corner(20), shine(0.35) })
	local i = text({ Text = icon, Size = UDim2.fromScale(1, 1), TextSize = 24, Parent = disc })
	local l = text({ Text = label, Position = UDim2.new(0, 0, 1, -22), Size = UDim2.new(1, 0, 0, 18), Font = TITLE, TextSize = 13, Parent = b })
	-- a red dot when there is something to do in this window
	local dot = new("Frame", { Name = "Dot", BackgroundColor3 = Color3.fromRGB(255, 70, 70), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -6, 0, 6), Size = UDim2.fromOffset(16, 16), Visible = false, Parent = b }, { corner(8), stroke(Color3.new(1, 1, 1), 2) })
	menuButtons[name] = { button = b, stroke = st, icon = i, label = l, dot = dot, color = color }
	return menuButtons[name]
end
for _, m in { { "bag", "🎒", "Bag" }, { "skills", "📊", "Skills" }, { "tools", "🛠️", "Tools" }, { "house", "🏗️", "House" }, { "combat", "⚔️", "Combat" }, { "travel", "🗺️", "Map" } } do
	menuButton(m[1], m[2], m[3], ACCENT[m[1]], function()
		showPanel(m[1])
	end)
end
-- travel between Hometown and the road (the button flips depending on where the hero is)
local travelGoesHome = true
local travel = menuButton("home", "🏡", "Go home", ACCENT.home, function()
	request("home", travelGoesHome and "home" or "road")
end)
task.spawn(function()
	while true do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			travelGoesHome = Zones.indexAt(hrp.Position.X, hrp.Position.Z) ~= Zones.byId.home.index
			travel.icon.Text = travelGoesHome and "🏡" or "⛲"
			travel.label.Text = travelGoesHome and "Go home" or "To town"
		end
		task.wait(0.5)
	end
end)

-- "🟫 3 Oak Planks   📌 20 Nails   💰 500" with whatever the player is short of in red
local function costText(mats, gold)
	local parts = {}
	local inv = state and state.inv or {}
	for id, n in mats do
		local col = (inv[id] or 0) >= n and "#b4f0b4" or "#ff9a80"
		table.insert(parts, ('<font color="%s">%s %d %s</font>'):format(col, Items[id].icon, n, Items[id].name))
	end
	table.sort(parts)
	if gold then
		local col = state and state.gold >= gold and "#ffd24a" or "#ff9a80"
		table.insert(parts, ('<font color="%s">💰 %s</font>'):format(col, fmt(gold)))
	end
	return table.concat(parts, "   ")
end

local function scroller(name)
	local p = new("ScrollingFrame", {
		Name = name, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Visible = false, ScrollBarThickness = 6,
		ScrollBarImageColor3 = C.stroke, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 3, Parent = body,
	}, { new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }), new("UIPadding", { PaddingRight = UDim.new(0, 8) }) })
	panels[name] = p
	return p
end

local function hint(parent, str, order)
	return text({ Text = str, LayoutOrder = order or -10, Size = UDim2.new(1, 0, 0, 20), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextColor3 = C.muted, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Parent = parent })
end

-- one card in a list: icon on the left, title, a coloured info line, a detail line and a button on the right
local function card(parent, order, icon)
	local row = new("Frame", { LayoutOrder = order, BackgroundColor3 = C.panel2, Size = UDim2.new(1, 0, 0, 86), ZIndex = 3, Parent = parent }, { corner(12), pad(8) })
	local disc = new("Frame", { BackgroundColor3 = C.bg, Size = UDim2.fromOffset(56, 56), Position = UDim2.new(0, 0, 0.5, -28), ZIndex = 3, Parent = row }, { corner(28) })
	local ic = text({ Text = icon, Size = UDim2.fromScale(1, 1), TextSize = 30, ZIndex = 3, Parent = disc })
	local title = text({ Text = "", Position = UDim2.fromOffset(66, 0), Size = UDim2.new(1, -220, 0, 24), Font = TITLE, TextSize = 19, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 3, Parent = row })
	local info = text({ Text = "", Position = UDim2.fromOffset(66, 25), Size = UDim2.new(1, -220, 0, 18), Font = BOLD, TextSize = 14, TextColor3 = C.good, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 3, Parent = row })
	local detail = text({ Text = "", RichText = true, Position = UDim2.fromOffset(66, 45), Size = UDim2.new(1, -220, 0, 26), TextSize = 14, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 3, Parent = row })
	local go = button({ Text = "", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(140, 54), TextSize = 18, TextWrapped = true, ZIndex = 3, Parent = row })
	return { row = row, icon = ic, title = title, info = info, detail = detail, go = go }
end

local function setButton(b, label, enabled, color)
	b.Text = label
	b.BackgroundColor3 = enabled and (color or C.good) or C.locked
	b.TextColor3 = enabled and Color3.new(1, 1, 1) or Color3.fromRGB(200, 196, 214)
end

-- --- Bag ---
do
	local p = new("Frame", { Name = "bag", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 3, Parent = body })
	panels.bag = p
	local grid = new("ScrollingFrame", {
		BackgroundColor3 = C.bg, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, -104), ScrollBarThickness = 6, ScrollBarImageColor3 = C.stroke,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 3, Parent = p,
	}, { corner(12), pad(8), new("UIGridLayout", { CellSize = UDim2.fromOffset(80, 86), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
	local empty = text({ Text = "Your bag is empty.\nChop trees, mine rocks and fish to fill it!", Size = UDim2.new(1, 0, 1, -104), TextColor3 = C.muted, TextWrapped = true, TextSize = 17, ZIndex = 4, Parent = p })
	local detail = new("Frame", { BackgroundColor3 = C.panel2, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 94), ZIndex = 3, Parent = p }, { corner(12), pad(10) })
	local dName = text({ Text = "", Size = UDim2.new(1, -230, 0, 26), Font = TITLE, TextSize = 21, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 3, Parent = detail })
	local dInfo = text({ Text = "", Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, -230, 0, 44), TextColor3 = C.muted, TextSize = 15, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 3, Parent = detail })
	local sell1 = button({ Name = "Sell1", Text = "Sell 1", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -114, 0, 0), Size = UDim2.fromOffset(106, 34), ZIndex = 3, Parent = detail }, function()
		if selectedItem then request("sell", selectedItem, 1) end
	end)
	local sellAllOf = button({ Name = "SellAllOf", Text = "Sell all", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(106, 34), BackgroundColor3 = Color3.fromRGB(210, 140, 40), ZIndex = 3, Parent = detail }, function()
		if selectedItem then request("sell", selectedItem, "all") end
	end)
	local sellEverything = button({ Name = "SellEverything", Text = "💰 Sell all resources", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 0, 1, 0), Size = UDim2.fromOffset(220, 38), BackgroundColor3 = Color3.fromRGB(210, 150, 30), ZIndex = 3, Parent = detail }, function()
		request("sellAll")
	end)

	renderers.bag = function()
		for _, c in grid:GetChildren() do
			if c:IsA("GuiObject") then c:Destroy() end
		end
		local ids = {}
		for id in state and state.inv or {} do
			if Items[id] then table.insert(ids, id) end
		end
		table.sort(ids, function(a, b) return Items[a].order < Items[b].order end)
		empty.Visible = #ids == 0
		local mult = 1 + Construction.bonus(state and state.rooms, "sell") / 100
		local total = 0
		for _, id in ids do
			local it, n = Items[id], state.inv[id]
			total += math.floor(it.value * n * mult)
			local slot = button({ Name = id, Text = "", LayoutOrder = it.order, BackgroundColor3 = selectedItem == id and Color3.fromRGB(90, 80, 140) or C.panel2, ZIndex = 3, Parent = grid }, function()
				selectedItem = id
				renderers.bag()
			end)
			stroke(selectedItem == id and C.gold or Tiers.color(it.rarity or it.tier), selectedItem == id and 3 or 2).Parent = slot
			text({ Text = it.icon, Position = UDim2.fromOffset(0, 4), Size = UDim2.new(1, 0, 0, 44), TextSize = 34, ZIndex = 3, Parent = slot })
			text({ Text = fmt(n), Position = UDim2.fromOffset(0, 48), Size = UDim2.new(1, 0, 0, 18), Font = TITLE, TextSize = 17, ZIndex = 3, Parent = slot })
			if it.color then
				new("Frame", { BackgroundColor3 = Color3.fromHex(it.color), Size = UDim2.new(1, -20, 0, 5), Position = UDim2.new(0, 10, 1, -11), BorderSizePixel = 0, ZIndex = 3, Parent = slot }, { corner(3) })
			end
		end
		if selectedItem and not (state and state.inv[selectedItem]) then selectedItem = nil end
		if selectedItem then
			local it, n = Items[selectedItem], state.inv[selectedItem]
			dName.Text = it.icon .. " " .. it.name .. "  ×" .. fmt(n)
			dInfo.Text = ("%s  ·  %s gold each  ·  all worth 💰 %s"):format(it.type, fmt(math.floor(it.value * mult)), fmt(math.floor(it.value * n * mult)))
		else
			dName.Text = "🎒 Your bag"
			dInfo.Text = ("Tap an item to sell it. Everything here is worth 💰 %s."):format(fmt(total))
		end
		sell1.Visible = selectedItem ~= nil
		sellAllOf.Visible = selectedItem ~= nil
		sellEverything.Visible = #ids > 0 and selectedItem == nil
	end
end

-- --- Skills ---
do
	local p = scroller("skills")
	hint(p, "Skills level up as you use them. Higher levels unlock better trees, rocks, fish and rooms.")
	local rows = {}
	local trained = table.clone(Skills.GATHERING)
	for _, id in Skills.COMBAT do
		table.insert(trained, id)
	end
	for _, id in trained do
		local s = Skills.byId[id]
		local row = new("Frame", { LayoutOrder = s.order, BackgroundColor3 = C.panel2, Size = UDim2.new(1, 0, 0, 62), ZIndex = 3, Parent = p }, { corner(12), pad(8) })
		text({ Text = s.icon, Size = UDim2.fromOffset(46, 46), TextSize = 30, ZIndex = 3, Parent = row })
		text({ Text = s.name, Position = UDim2.fromOffset(54, 0), Size = UDim2.new(1, -130, 0, 22), Font = TITLE, TextSize = 19, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Parent = row })
		local lv = text({ Text = "", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(110, 22), Font = TITLE, TextSize = 19, TextColor3 = C.gold, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 3, Parent = row })
		local _, fill = bar(row, { Position = UDim2.fromOffset(54, 26), Size = UDim2.new(1, -54, 0, 10), ZIndex = 3 })
		local sub = text({ Text = "", Position = UDim2.fromOffset(54, 36), Size = UDim2.new(1, -54, 0, 16), TextSize = 13, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Parent = row })
		rows[id] = { lv = lv, fill = fill, sub = sub }
	end
	-- the rest of the 22 skills as small chips: shown so players know what's coming, but out of the way
	local later = new("Frame", { LayoutOrder = 100, BackgroundColor3 = C.bg, Size = UDim2.new(1, 0, 0, 30), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 3, Parent = p }, {
		corner(12), pad(10), new("UIGridLayout", { CellSize = UDim2.fromOffset(150, 28), CellPadding = UDim2.fromOffset(6, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	text({ Text = "🔒 Coming in later updates", LayoutOrder = 99, Size = UDim2.new(1, 0, 0, 22), Font = TITLE, TextSize = 17, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 3, Parent = p })
	for _, s in Skills.LIST do
		if not Skills.ACTIVE[s.id] then
			text({ Text = s.icon .. " " .. s.name, LayoutOrder = s.order, BackgroundTransparency = 0, BackgroundColor3 = C.panel2, TextSize = 13, TextColor3 = C.muted, ZIndex = 3, Parent = later }, { corner(14) })
		end
	end
	renderers.skills = function()
		if not state then return end
		for id, r in rows do
			local xp = state.skills[id] or 0
			local l, frac, need = XP.progress(xp)
			r.lv.Text = "Level " .. l
			r.fill.Size = UDim2.new(frac, 0, 1, 0)
			r.sub.Text = l >= XP.MAX_LEVEL and (fmt(xp) .. " XP · max level") or (fmt(xp) .. " XP · " .. fmt(need) .. " XP to level " .. (l + 1))
		end
	end
end

-- --- Tools ---
do
	local p = scroller("tools")
	hint(p, "Better tools work 12% faster per upgrade. Sell resources in your 🎒 Bag to get gold.")
	local rows = {}
	local skillOf = { axe = "woodcutting", pick = "mining", rod = "fishing" }
	for i, tool in G.TOOL_ORDER do
		local c = card(p, i, Skills.byId[skillOf[tool]].icon)
		c.go.Name = "Upgrade_" .. tool
		c.go.Activated:Connect(function()
			request("upgrade", tool)
		end)
		rows[tool] = c
	end
	renderers.tools = function()
		if not state then return end
		for tool, c in rows do
			local lvl = state.tools[tool] or 0
			local skill = Skills.byId[skillOf[tool]]
			c.title.Text = G.toolName(tool, lvl)
			c.info.Text = lvl > 0 and ("%d%% faster %s"):format(math.floor(12 * lvl + 0.5), skill.name:lower()) or ("Basic " .. skill.name:lower() .. " speed")
			if lvl >= G.TOOL_MAX then
				c.detail.Text = "The best tool there is!"
				setButton(c.go, "Max level", false)
			else
				local cost = G.TOOL_COST[lvl]
				c.detail.Text = ("Next: %s  (+12%% faster)   %s"):format(G.toolName(tool, lvl + 1), costText({}, cost))
				setButton(c.go, "Upgrade", state.gold >= cost)
			end
		end
	end
end

-- --- House ---
local function roomAffordable(r, t)
	if not state or t > Construction.ROOM_MAX then return false end
	if XP.levelFromXp(state.skills.construction or 0) < r.lv[t] then return false end
	local c = Construction.cost(r, t)
	if state.gold < c.gold then return false end
	for id, n in c.mats do
		if (state.inv[id] or 0) < n then return false end
	end
	return true
end
-- what a room level gives, in words
local function bonusText(r, t)
	local b = r.bonus[t]
	if r.kind == "speed" then
		return ("+%d%% %s speed"):format(b, r.skill == "construction" and "workbench" or Skills.byId[r.skill].name:lower())
	elseif r.kind == "offline" then
		return ("+%dh offline time"):format(b)
	end
	return ("+%d%% gold when selling"):format(b)
end
do
	local p = scroller("house")
	hint(p, "Walk onto a ➕ spot on your plot to build there. Upgrade rooms here. Every room level is +1 House Level = +1% XP on every skill.")
	-- house level, and a shortcut home
	local head = card(p, 0, "🏡")
	head.row.Name = "HouseHead"
	head.row.BackgroundColor3 = Color3.fromRGB(70, 60, 40)
	head.go.Name = "GoHome"
	head.go.Activated:Connect(function()
		request("home", "home")
		showPanel(nil)
	end)
	local rows = {}
	for _, r in Construction.ROOMS do
		local c = card(p, r.order, r.icon)
		c.row.Name = "Room_" .. r.id
		c.go.Name = "Build_" .. r.id
		c.go.Activated:Connect(function()
			if state and state.layout and state.layout[r.id] then
				request("build", r.id)
			else
				-- new rooms go on a build spot: take the player home to pick one
				request("home", "home")
				showPanel(nil)
			end
		end)
		rows[r.id] = c
	end
	renderers.house = function()
		if not state then return end
		local lvl = XP.levelFromXp(state.skills.construction or 0)
		local layout = state.layout or {}
		local houseLevel = 0
		for _, t in state.rooms or {} do
			houseLevel += t
		end
		head.title.Text = ("House Level %d"):format(houseLevel)
		head.info.Text = ("+%d%% XP on every skill"):format(houseLevel)
		head.detail.Text = layout.entrance and "New rooms go on the ➕ spots next to your house." or "Go to your plot and step on a ➕ spot to start your house."
		setButton(head.go, "🏡 Go home", true, Color3.fromRGB(200, 110, 200))
		for _, r in Construction.ROOMS do
			local c, t = rows[r.id], state.rooms and state.rooms[r.id] or 0
			local placed = layout[r.id] ~= nil
			c.title.Text = r.name .. (t > 0 and ("  ·  Lv " .. t) or "")
			if t >= Construction.ROOM_MAX then
				c.info.Text = "Now: " .. bonusText(r, t)
				c.detail.Text = "Fully built!"
				setButton(c.go, "Max level", false)
				continue
			end
			local cost = Construction.cost(r, t + 1)
			c.info.Text = t > 0 and ("%s  →  %s"):format(bonusText(r, t), bonusText(r, t + 1)) or bonusText(r, 1)
			c.detail.Text = costText(cost.mats, cost.gold)
			if not placed then
				setButton(c.go, "Build on ➕ spot", true, Color3.fromRGB(230, 170, 40))
			elseif lvl < r.lv[t + 1] then
				setButton(c.go, ("🔒 Construction %d"):format(r.lv[t + 1]), false)
			else
				setButton(c.go, "Upgrade to " .. (t + 1), roomAffordable(r, t + 1))
			end
		end
	end
end

-- --- What to build on a spot ---
local spotCell = nil
do
	local p = scroller("spot")
	local tip = hint(p, "")
	local start = card(p, 0, "🏡")
	start.row.Name = "Spot_entrance"
	start.title.Text = "Entrance Hall"
	start.info.Text = "Your house starts here"
	start.detail.Text = "Free! Every other room joins on to it."
	start.go.Name = "Build_entrance"
	start.go.Activated:Connect(function()
		if spotCell then
			request("buildAt", "entrance", spotCell.x, spotCell.z)
			showPanel(nil)
		end
	end)
	local rows = {}
	for _, r in Construction.ROOMS do
		local c = card(p, r.order, r.icon)
		c.row.Name = "Spot_" .. r.id
		c.title.Text = r.name
		c.go.Name = "Build_" .. r.id
		c.go.Activated:Connect(function()
			local built = state and state.rooms and (state.rooms[r.id] or 0) > 0
			if spotCell and (built or roomAffordable(r, 1)) then
				request("buildAt", r.id, spotCell.x, spotCell.z)
				showPanel(nil)
			end
		end)
		rows[r.id] = c
	end
	renderers.spot = function()
		if not state then return end
		local layout = state.layout or {}
		local starting = not layout.entrance
		start.row.Visible = starting
		tip.Text = starting and "Start your house on this spot? You can build every room next to it later." or "Pick a room for this spot. Rooms you can afford are green."
		local first = true
		for _, r in Construction.ROOMS do
			local c = rows[r.id]
			local t = state.rooms and state.rooms[r.id] or 0
			c.row.Visible = not starting and not layout[r.id]
			if c.row.Visible then
				c.info.Text = bonusText(r, math.max(t, 1))
				if t > 0 then
					-- built before rooms had places: it goes here for free
					c.detail.Text = "Already built – place it here for free."
					setButton(c.go, "Place here", true)
				else
					local cost = Construction.cost(r, 1)
					c.detail.Text = costText(cost.mats, cost.gold)
					local lvl = XP.levelFromXp(state.skills.construction or 0)
					if lvl < r.lv[1] then
						setButton(c.go, ("🔒 Construction %d"):format(r.lv[1]), false)
					else
						local ok = roomAffordable(r, 1)
						-- the first room the player can afford is the suggested one
						setButton(c.go, (ok and first) and "⭐ Build here" or "Build here", ok)
						if ok then first = false end
					end
				end
			end
		end
	end
end

-- --- Seed Stall ---
local Farming = require(Shared.Farming)
local function seedLine(s)
	return ("Farming %d  ·  %s  ·  grows in %s"):format(s.lvl, Farming.KIND_NAME[s.kind], Farming.fmtTime(s.time))
end
do
	local p = scroller("seeds")
	hint(p, "Plant seeds in the patches along the south fence of your plot. They grow even while you are away!")
	local rows = {}
	for i, offer in Farming.SHOP do
		local s = Farming.byId[offer[1]]
		local c = card(p, i, Items[s.id].icon)
		c.row.Name = "Offer_" .. i
		c.go.Name = "Buy_" .. i
		c.title.Text = ("%s  ×%d"):format(s.name, offer[2])
		c.go.Activated:Connect(function()
			request("buySeeds", i)
		end)
		rows[i] = c
	end
	renderers.seeds = function()
		if not state then return end
		local lvl = XP.levelFromXp(state.skills.farming or 0)
		for i, offer in Farming.SHOP do
			local s, c = Farming.byId[offer[1]], rows[i]
			c.info.Text = seedLine(s)
			c.info.TextColor3 = lvl >= s.lvl and C.good or C.warn
			c.detail.Text = costText({}, offer[3]) .. ("   <font color=\"#aaa4b4\">you have %d</font>"):format(state.inv[s.id] or 0)
			setButton(c.go, "Buy", state.gold >= offer[3])
		end
	end
end

-- --- Plant (a patch was tapped) ---
local plantPatch, plantKind = nil, nil
do
	local p = scroller("plant")
	local tip = hint(p, "")
	local rows = {}
	for _, s in Farming.SEEDS do
		local c = card(p, s.order, "🌱")
		c.row.Name = "Seed_" .. s.id
		c.go.Name = "Plant_" .. s.id
		c.title.Text = s.name
		c.go.Activated:Connect(function()
			if plantPatch then
				request("plant", plantPatch, s.id)
				showPanel(nil)
			end
		end)
		rows[s.id] = c
	end
	renderers.plant = function()
		if not state then return end
		local lvl = XP.levelFromXp(state.skills.farming or 0)
		local shown = 0
		for _, s in Farming.SEEDS do
			local c, have = rows[s.id], state.inv[s.id] or 0
			c.row.Visible = s.kind == plantKind and have > 0
			if c.row.Visible then
				shown += 1
				local out = Items[s.out]
				c.icon.Text = out.icon
				c.info.Text = seedLine(s)
				c.detail.Text = ("Gives %d–%d %s  ·  you have %d seeds"):format(s.n[1], s.n[2], out.name, have)
				if lvl < s.lvl then
					setButton(c.go, "🔒 Farming " .. s.lvl, false)
				else
					setButton(c.go, "Plant", true)
				end
			end
		end
		tip.Text = shown > 0 and ("Pick a seed for this %s."):format(Farming.KIND_NAME[plantKind or "allot"]:lower())
			or ("You have no seeds for a %s. Buy some at the 🌱 Seed Stall in Riverbend, or find them while gathering."):format(Farming.KIND_NAME[plantKind or "allot"]:lower())
	end
end

-- --- Combat ---
local Combat = require(Shared.Combat)
local function gearName(slot, t)
	if t < 0 then
		return slot == "weapon" and "Training Sword" or "No armour"
	end
	return Combat.METALS[t] .. (slot == "weapon" and " Sword" or " Armour")
end
do
	local p = scroller("combat")
	hint(p, "Walk up to a monster (or tap it) and your hero draws their sword and fights on their own, eating food (crops) when hurt. Monsters come for you if you get close! Better gear: ⚔️ Smithy in Riverbend.")
	local head = card(p, 0, "⚔️")
	head.row.Name = "CombatHead"
	head.go.Visible = false
	local styleRows = {}
	for i, st in Combat.STYLES do
		local c = card(p, i, ({ "🎯", "💪", "🛡️", "⚖️" })[i])
		c.row.Name = "Style_" .. st.id
		c.row.Size = UDim2.new(1, 0, 0, 66)
		c.title.Text = st.name
		c.info.Text = st.desc
		c.go.Name = "Pick_" .. st.id
		c.go.Activated:Connect(function()
			request("setStyle", st.id)
		end)
		styleRows[st.id] = c
	end
	local gearRow = card(p, 10, "🗡️")
	gearRow.row.Name = "Gear"
	gearRow.go.Visible = false
	renderers.combat = function()
		if not state then return end
		local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		local lvl = Combat.combatLevel(state.skills)
		head.title.Text = ("Combat level %d"):format(lvl)
		head.info.Text = ("❤️ %d / %d HP  ·  %d monsters defeated"):format(hum and math.ceil(hum.Health) or 0, Combat.maxHp(state.skills), state.kills or 0)
		head.detail.Text = lvl >= Combat.WILD_REQ and "☠️ The Wraith Caves are open to you – north, past the Ice Mountains. Other players can attack you there!"
			or ("☠️ The Wraith Caves (PvP) open at combat level %d."):format(Combat.WILD_REQ)
		local style = state.combat and state.combat.style or "accurate"
		for id, c in styleRows do
			setButton(c.go, id == style and "✔ Using" or "Use", id ~= style, Color3.fromRGB(80, 120, 230))
			c.row.BackgroundColor3 = id == style and Color3.fromRGB(70, 60, 100) or C.panel2
		end
		local g = state.gear or { weapon = -1, armour = -1 }
		local a = Combat.attackerStats(state)
		gearRow.title.Text = gearName("weapon", g.weapon) .. "  ·  " .. gearName("armour", g.armour)
		gearRow.info.Text = ("Max hit %d  ·  Armour %d"):format(a.maxHit, g.armour >= 0 and Combat.ARMOUR[g.armour] or 0)
		gearRow.detail.Text = "Better gear: ⚔️ Smithy on the Riverbend plaza."
	end
end

-- --- Smithy ---
do
	local p = scroller("smithy")
	hint(p, "Each upgrade replaces what you wear. Swords need Attack, armour needs Defence.")
	local rows = {}
	for i, slot in { "weapon", "armour" } do
		local c = card(p, i, slot == "weapon" and "🗡️" or "🛡️")
		c.row.Name = "Smithy_" .. slot
		c.go.Name = "Buy_" .. slot
		c.go.Activated:Connect(function()
			request("buyGear", slot)
		end)
		rows[slot] = c
	end
	renderers.smithy = function()
		if not state then return end
		local g = state.gear or { weapon = -1, armour = -1 }
		for slot, c in rows do
			local t = g[slot] + 1
			local skill = slot == "weapon" and "attack" or "defence"
			if t > Combat.GEAR_MAX then
				c.title.Text = gearName(slot, g[slot])
				c.info.Text = "The best there is!"
				c.detail.Text = ""
				setButton(c.go, "Max", false)
			else
				c.title.Text = gearName(slot, t)
				c.info.Text = slot == "weapon" and ("+%d power  ·  needs Attack %d"):format(Combat.POWER[t], Combat.EQUIP_REQ[t]) or ("+%d armour  ·  needs Defence %d"):format(Combat.ARMOUR[t], Combat.EQUIP_REQ[t])
				local cost = (slot == "weapon" and Combat.WEAPON_COST or Combat.ARMOUR_COST)[t]
				c.detail.Text = "Now: " .. gearName(slot, g[slot]) .. "   " .. costText({}, cost)
				local ok = XP.levelFromXp(state.skills[skill] or 0) >= Combat.EQUIP_REQ[t] and state.gold >= cost
				setButton(c.go, "Buy", ok)
			end
		end
	end
end

-- --- Map: teleport to any zone whose waystone you have found ---
do
	local p = scroller("travel")
	hint(p, "Walk into a zone once to unlock its 🗺️ Waystone. Then teleport there from here, or tap any waystone.")
	local ALWAYS = { town = true, meadow = true, home = true }
	local ORDER = { "home", "town", "meadow", "forest", "swamp", "caves", "ice", "dragon", "wild" }
	-- what each zone holds: monsters from the camps, resources from the zone's nodes
	local monsters = {}
	for _, camp in Combat.CAMPS do
		monsters[camp.zone] = monsters[camp.zone] or {}
		for _, id in camp.enemies do
			local name = Combat.ENEMIES[id].name
			if not table.find(monsters[camp.zone], name) then
				table.insert(monsters[camp.zone], name)
			end
		end
	end
	local rows = {}
	for i, id in ORDER do
		local z = Zones.byId[id]
		local c = card(p, i, z.icon)
		c.row.Name = "Zone_" .. id
		c.go.Name = "Go_" .. id
		c.go.Activated:Connect(function()
			request("travel", id)
			showPanel(nil)
		end)
		local found = {}
		for _, skill in { "woodcutting", "mining", "fishing" } do
			if z.res[skill] then
				table.insert(found, Skills.byId[skill].icon .. " " .. ({ woodcutting = "Trees", mining = "Rocks", fishing = "Fish" })[skill])
			end
		end
		if z.home then
			found = { "🏡 Your house", "🌱 Garden", "🔨 Workbench" }
		elseif z.town then
			found = { "⚔️ Smithy", "🌱 Seed Stall" }
		end
		c.detail.Text = table.concat(found, "  ·  ")
		rows[id] = { card = c, zone = z }
	end
	renderers.travel = function()
		if not state then return end
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local here = hrp and Zones.LIST[Zones.indexAt(hrp.Position.X, hrp.Position.Z)].id
		local lvl = Combat.combatLevel(state.skills)
		for id, r in rows do
			local z, c = r.zone, r.card
			c.title.Text = z.name .. ((z.home or z.town) and "" or ("  ·  Lv " .. z.req .. "+"))
			local mobs = monsters[id]
			c.info.Text = mobs and ("Monsters: " .. table.concat(mobs, ", ")) or z.desc
			c.info.TextColor3 = z.wild and C.warn or (mobs and Color3.fromRGB(255, 160, 140) or C.good)
			local open = ALWAYS[id] or (state.visited and state.visited[id])
			if id == here and not z.home then
				setButton(c.go, "You are here", false)
			elseif z.wild and lvl < Combat.WILD_REQ then
				setButton(c.go, ("🔒 Combat %d"):format(Combat.WILD_REQ), false)
			elseif not open then
				setButton(c.go, "🔒 Find it first", false)
			else
				setButton(c.go, z.home and "🏡 Go home" or "Teleport", true, z.wild and Color3.fromRGB(200, 70, 70) or Color3.fromRGB(60, 170, 190))
			end
		end
	end
end

function UI.openPlant(i: number, kind: string)
	plantPatch, plantKind = i, kind
	showPanel(nil)
	showPanel("plant")
end

function UI.openSpot(x: number, z: number)
	spotCell = { x = x, z = z }
	showPanel(nil)
	showPanel("spot")
end

-- --- Workbench ---
do
	local p = scroller("craft")
	hint(p, "Pick what to make. Your hero keeps working, even while you are offline, until the materials run out.")
	local rows = {}
	for i = 0, Construction.RECIPE_COUNT - 1 do
		local rc = Construction.RECIPES[i]
		local c = card(p, i, Items[rc.item].icon)
		c.row.Size = UDim2.new(1, 0, 0, 76)
		c.go.Name = "Make_" .. i
		c.go.Activated:Connect(function()
			request("craft", i)
			showPanel(nil)
		end)
		c.title.Text = rc.name .. (rc.out > 1 and ("  ×" .. rc.out) or "")
		rows[i] = c
	end
	renderers.craft = function()
		if not state then return end
		local lvl = XP.levelFromXp(state.skills.construction or 0)
		for i, c in rows do
			local rc = Construction.RECIPES[i]
			local n = math.huge
			for id, k in rc.inputs do
				n = math.min(n, math.floor((state.inv[id] or 0) / k))
			end
			c.info.Text = ("+%d Construction XP each  ·  you can make %d"):format(rc.xp, n)
			c.info.TextColor3 = n > 0 and C.good or C.muted
			c.detail.Text = "Uses " .. costText(rc.inputs)
			if lvl < rc.req then
				setButton(c.go, "🔒 Level " .. rc.req, false)
			else
				setButton(c.go, "Make", n > 0)
			end
		end
	end
end

-- ===== action bar (what the hero is doing right now) =====
local action = new("Frame", {
	Name = "Action", BackgroundColor3 = C.bg, BackgroundTransparency = 0.08, AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -14), Size = UDim2.fromOffset(400, 66), Visible = false, Parent = gui,
}, { corner(14), stroke(C.good, 2), pad(8) })
local actionIcon = text({ Text = "", Size = UDim2.fromOffset(48, 48), TextSize = 32, Parent = action })
local actionText = text({ Text = "", Position = UDim2.fromOffset(54, 0), Size = UDim2.new(1, -150, 0, 24), Font = TITLE, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, Parent = action })
local _, actionFill = bar(action, { Position = UDim2.fromOffset(54, 30), Size = UDim2.new(1, -150, 0, 16) })
button({ Name = "Stop", Text = "Stop", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(84, 46), BackgroundColor3 = Color3.fromRGB(210, 70, 70), Parent = action }, function()
	request("stop")
end)
local actionTween = nil

function UI.actionStart(info)
	action.Visible = true
	local have = state and state.inv[info.item] or 0
	actionIcon.Text = Items[info.item].icon
	actionText.Text = ("%s %s  ·  you have %s"):format(G.VERB_ING[info.skill], info.name, fmt(have))
	if actionTween then actionTween:Cancel() end
	actionFill.Size = UDim2.new(0, 0, 1, 0)
	actionTween = TweenService:Create(actionFill, TweenInfo.new(info.duration, Enum.EasingStyle.Linear), { Size = UDim2.new(1, 0, 1, 0) })
	actionTween:Play()
	for id, r in hudRows do
		r.row.BackgroundTransparency = id == info.skill and 0.6 or 1
	end
end

function UI.actionStop()
	if actionTween then actionTween:Cancel() end
	action.Visible = false
	for _, r in hudRows do
		r.row.BackgroundTransparency = 1
	end
end

-- ===== fight bar: who you are fighting and their health =====
local fighting = false
function UI.fightState(info)
	if info.active then
		fighting = true
		action.Visible = true
		actionIcon.Text = info.pvp and "☠️" or "⚔️"
		actionText.Text = info.pvp and ("Fighting %s  ·  %d/%d"):format(info.name, math.ceil(info.hp), info.maxHp) or ("Fighting %s (Lv %d)  ·  %d/%d"):format(info.name, info.level, math.ceil(info.hp), info.maxHp)
		if actionTween then actionTween:Cancel() end
		actionFill.BackgroundColor3 = Color3.fromRGB(230, 70, 70)
		TweenService:Create(actionFill, TweenInfo.new(0.2), { Size = UDim2.new(math.clamp(info.hp / info.maxHp, 0, 1), 0, 1, 0) }):Play()
		action:FindFirstChildOfClass("UIStroke").Color = Color3.fromRGB(230, 80, 80)
	elseif fighting then
		fighting = false
		action.Visible = false
		actionFill.BackgroundColor3 = C.bar
		action:FindFirstChildOfClass("UIStroke").Color = C.good
		if info.reason == "moved" then
			UI.toast("You walked away from the fight.")
		end
	end
end


-- ===== floating gains, toasts, banners =====
local floatHolder = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -96), Size = UDim2.fromOffset(320, 30), Parent = gui })
function UI.floatText(str, color)
	local t = text({ Text = str, Size = UDim2.fromScale(1, 1), Font = TITLE, TextSize = 24, TextColor3 = color or C.text, TextStrokeTransparency = 0.2, Parent = floatHolder })
	local sc = new("UIScale", { Scale = 0.6, Parent = t })
	TweenService:Create(sc, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	TweenService:Create(t, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(0, -80), TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(1.5, function() t:Destroy() end)
end

local toasts = new("Frame", { Name = "Toasts", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(440, 200), ZIndex = 20, Parent = wgui }, {
	new("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center }),
})
function UI.toast(msg, kind)
	local col = kind == "warn" and C.warn or (kind == "gold" or kind == "goal") and C.gold or kind == "good" and C.good or C.text
	local f = new("Frame", { BackgroundColor3 = C.bg, BackgroundTransparency = 0.08, Size = UDim2.fromOffset(440, 36), AutomaticSize = Enum.AutomaticSize.Y, Parent = toasts }, { corner(10), stroke(col, 2), pad(6) })
	local t = text({ Text = (kind == "goal" and "🎯 " or "") .. msg, Size = UDim2.new(1, 0, 0, 24), AutomaticSize = Enum.AutomaticSize.Y, Font = BOLD, TextColor3 = col, TextSize = 16, TextWrapped = true, Parent = f })
	local sc = new("UIScale", { Scale = 0.8, Parent = f })
	TweenService:Create(sc, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.delay(kind == "goal" and 5 or 3.5, function()
		TweenService:Create(f, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(t, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		local s = f:FindFirstChildOfClass("UIStroke")
		if s then TweenService:Create(s, TweenInfo.new(0.4), { Transparency = 1 }):Play() end
		task.wait(0.45)
		f:Destroy()
	end)
end

local banner = text({ ZIndex = 2, Text = "", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.36), Size = UDim2.fromOffset(700, 60), Font = TITLE, TextSize = 46, TextColor3 = C.gold, TextStrokeTransparency = 0, TextTransparency = 1, TextStrokeColor3 = Color3.fromRGB(40, 20, 0), Parent = wgui })
local bannerSub = text({ ZIndex = 2, Text = "", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.36, 44), Size = UDim2.fromOffset(700, 30), Font = TITLE, TextSize = 22, TextStrokeTransparency = 0.2, TextTransparency = 1, Parent = wgui })
local bannerScale = new("UIScale", { Parent = banner })
local bannerId = 0
function UI.banner(main, sub, color)
	bannerId += 1
	local id = bannerId
	banner.Text, bannerSub.Text = main, sub or ""
	banner.TextColor3 = color or C.gold
	banner.TextTransparency, banner.TextStrokeTransparency = 0, 0
	bannerSub.TextTransparency, bannerSub.TextStrokeTransparency = 0, 0.2
	bannerScale.Scale = 0.5
	TweenService:Create(bannerScale, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	task.delay(2.8, function()
		if id ~= bannerId then return end
		local ti = TweenInfo.new(0.6)
		TweenService:Create(banner, ti, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		TweenService:Create(bannerSub, ti, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end)
end

-- ===== offline summary =====
function UI.offline(o)
	local h, m = math.floor(o.counted / 3600), math.floor(o.counted % 3600 / 60)
	dim.Visible = true
	local modal = new("Frame", {
		Name = "Offline", BackgroundColor3 = C.panel, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(420, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 10, Parent = wgui,
	}, { corner(16), stroke(C.gold, 3), pad(16), new("UIListLayout", { Padding = UDim.new(0, 10), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }) })
	text({ Text = "⏳ Welcome back!", LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 34), Font = TITLE, TextSize = 30, TextColor3 = C.gold, ZIndex = 10, Parent = modal })
	text({ Text = ("You were away %dh %dm. Your hero kept %s:"):format(h, m, o.verb:lower()), LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 20), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextSize = 16, TextColor3 = C.muted, ZIndex = 10, Parent = modal })
	local function gain(order, icon, str)
		local row = new("Frame", { LayoutOrder = order, BackgroundColor3 = C.panel2, Size = UDim2.new(1, 0, 0, 46), ZIndex = 10, Parent = modal }, { corner(10) })
		text({ Text = icon, Size = UDim2.fromOffset(50, 46), TextSize = 28, ZIndex = 10, Parent = row })
		text({ Text = str, Position = UDim2.fromOffset(50, 0), Size = UDim2.new(1, -60, 1, 0), Font = TITLE, TextSize = 19, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 10, Parent = row })
	end
	local s = Skills.byId[o.skill]
	gain(3, s.icon, ("+%s %s XP%s"):format(fmt(o.xp), s.name, o.levelAfter > o.levelBefore and ("  (Lv %d → %d)"):format(o.levelBefore, o.levelAfter) or ""))
	gain(4, Items[o.item].icon, ("+%s %s"):format(fmt(o.actions), o.itemName))
	local notes = {}
	if o.ranOut then table.insert(notes, "Your hero ran out of materials.") end
	if o.seconds > o.cap then table.insert(notes, ("Offline time counts up to %dh. Build a 🛏️ Bedroom for more."):format(o.cap // 3600)) end
	if #notes > 0 then
		text({ Text = table.concat(notes, "\n"), LayoutOrder = 5, Size = UDim2.new(1, 0, 0, 20), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextSize = 14, TextColor3 = C.muted, ZIndex = 10, Parent = modal })
	end
	button({ Name = "Collect", Text = "Collect", LayoutOrder = 6, Size = UDim2.fromOffset(200, 50), BackgroundColor3 = C.good, TextSize = 22, ZIndex = 10, Parent = modal }, function()
		modal:Destroy()
		dim.Visible = window.Visible
	end)
	local sc = new("UIScale", { Scale = 0.7, Parent = modal })
	TweenService:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

-- ===== next goal =====
local currentGoal = nil
function UI.goal()
	return currentGoal
end

local function refreshGoal()
	local g = state and Goals.LIST[state.goal]
	currentGoal = g
	goalCard.Visible = g ~= nil
	if not g then return end
	local cur, max = g.progress(state)
	goalTitle.Text = ("🎯 NEXT GOAL  ·  %d of %d"):format(state.goal, #Goals.LIST)
	goalText.Text = g.text
	goalCount.Text = max > 1 and (cur .. "/" .. max) or ""
	goalFill.Size = UDim2.new(cur / max, 0, 1, 0)
end

-- pulse the menu button the current goal wants pressed
task.spawn(function()
	local t = 0
	while true do
		t += 0.05
		local target = currentGoal and currentGoal.target
		for name, mb in menuButtons do
			local on = name == target
			mb.stroke.Color = on and C.goal:Lerp(Color3.new(1, 1, 1), (math.sin(t * 6) + 1) / 2) or mb.color
			mb.stroke.Thickness = on and 4 or 2.5
		end
		task.wait(0.05)
	end
end)

-- ===== data refresh =====
local function refreshDots()
	if not state then return end
	-- something to do in the house: a room to build, a built room still to place, or the house not started
	local layout = state.layout or {}
	local canBuild = not layout.entrance
	for _, r in Construction.ROOMS do
		if roomAffordable(r, (state.rooms[r.id] or 0) + 1) then canBuild = true end
		if (state.rooms[r.id] or 0) > 0 and not layout[r.id] then canBuild = true end
	end
	menuButtons.house.dot.Visible = canBuild
	local canUpgrade = false
	for _, tool in G.TOOL_ORDER do
		local lvl = state.tools[tool] or 0
		if lvl < G.TOOL_MAX and state.gold >= G.TOOL_COST[lvl] then canUpgrade = true end
	end
	menuButtons.tools.dot.Visible = canUpgrade
end

function UI.setData(view)
	state = view
	goldLabel.Text = fmt(view.gold)
	local total = 0
	for _, s in Skills.LIST do
		total += XP.levelFromXp(view.skills[s.id] or 0)
	end
	totalLabel.Text = "Total " .. total
	for id, r in hudRows do
		local l, frac = XP.progress(view.skills[id] or 0)
		r.lv.Text = "Lv " .. l
		TweenService:Create(r.fill, TweenInfo.new(0.3), { Size = UDim2.new(frac, 0, 1, 0) }):Play()
	end
	local cl = view.caveLoot
	local wildNow = false
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then
		wildNow = Zones.contains(Zones.byId.wild, hrp.Position.X, hrp.Position.Z)
	end
	lootBox.Visible = wildNow or (cl and cl.gold > 0)
	lootText.Text = ("☠️ %s"):format(fmt(cl and cl.gold or 0))
	refreshGoal()
	refreshDots()
	if openPanel and renderers[openPanel] then
		renderers[openPanel]()
	end
end

function UI.getData()
	return state
end

function UI.setRequest(fn)
	request = fn
end

-- zone name banner (called by the lighting code)
function UI.zone(name, sub)
	UI.banner(name, sub, Color3.fromRGB(255, 240, 200))
end

-- ===== screen size =====
-- On phones Roblox puts the thumbstick bottom-left and the jump button bottom-right, so the HUD moves to the top:
-- goal, gold and skills top-left (skills without names), the menu as a row top-right. Windows nearly fill the screen.
local function layout(phone: boolean)
	local list = left:FindFirstChild("List")
	if phone then
		left.AnchorPoint, left.Position = Vector2.new(0, 0), UDim2.fromOffset(8, 4)
		list.VerticalAlignment = Enum.VerticalAlignment.Top
		list.Padding = UDim.new(0, 5)
	else
		left.AnchorPoint, left.Position = Vector2.new(0, 1), UDim2.new(0, 10, 1, -10)
		list.VerticalAlignment = Enum.VerticalAlignment.Bottom
		list.Padding = UDim.new(0, 8)
	end
	goalCard.Size = UDim2.fromOffset(phone and 290 or 330, phone and 62 or 76)
	goalText.TextSize = phone and 14 or 15
	for _, f in top:GetChildren() do
		if f:IsA("Frame") then
			f.Size = UDim2.fromOffset(phone and 120 or 150, phone and 34 or 38)
		end
	end
	local rows = #Skills.GATHERING
	hud.Size = UDim2.fromOffset(phone and 150 or 240, phone and (rows * 24 + 12) or (rows * 36 + 16))
	for _, r in hudRows do
		r.name.Visible = not phone
		r.row.Size = UDim2.new(1, 0, 0, phone and 20 or 32)
		r.fill.Parent.Position = UDim2.fromOffset(32, phone and 6 or 21)
		r.fill.Parent.Size = UDim2.new(1, phone and -80 or -32, 0, 8)
	end

	local mlist = menu:FindFirstChild("List")
	local n = 0
	for _, mb in menuButtons do
		n += 1
		mb.button.Size = UDim2.fromOffset(phone and 58 or 70, phone and 58 or 70)
		mb.label.TextSize = phone and 11 or 13
	end
	if phone then
		menu.AnchorPoint, menu.Position = Vector2.new(1, 0), UDim2.new(1, -8, 0, 4)
		menu.Size = UDim2.fromOffset(n * 58 + (n - 1) * 6, 58)
		mlist.FillDirection = Enum.FillDirection.Horizontal
		mlist.Padding = UDim.new(0, 6)
	else
		menu.AnchorPoint, menu.Position = Vector2.new(1, 0.5), UDim2.new(1, -10, 0.5, 0)
		menu.Size = UDim2.fromOffset(70, n * 70 + (n - 1) * 8)
		mlist.FillDirection = Enum.FillDirection.Vertical
		mlist.Padding = UDim.new(0, 8)
	end
	action.Size = UDim2.fromOffset(phone and 340 or 400, 66)
	-- toasts sit under the menu row on phones
	toasts.Position = UDim2.new(0.5, 0, 0, phone and 70 or 8)
	toasts.Size = UDim2.fromOffset(phone and 380 or 440, 200)

	window.Size = phone and UDim2.new(0.94, 0, 0.92, 0) or UDim2.new(0.6, 0, 0.74, 0)
	window.Position = phone and UDim2.fromScale(0.5, 0.5) or UDim2.fromScale(0.5, 0.52)
end

local function rescale()
	local cam = workspace.CurrentCamera
	local v = cam and cam.ViewportSize or Vector2.new(1280, 720)
	-- ForcePhone: a test switch to preview the phone layout on a PC
	isPhone = gui:GetAttribute("ForcePhone") == true or v.Y < 500 or v.X < 700
	scale.Scale = isPhone and 0.72 or math.clamp(v.Y / 720, 0.8, 1.2)
	layout(isPhone)
end
gui:GetAttributeChangedSignal("ForcePhone"):Connect(rescale)
rescale()
task.spawn(function()
	while not workspace.CurrentCamera do
		task.wait()
	end
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()
end)

return UI
