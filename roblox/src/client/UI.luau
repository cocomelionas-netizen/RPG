-- All of the game's screen UI, built in code (no uploaded assets needed).
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Skills = require(Shared.Skills)
local XP = require(Shared.XP)
local Items = require(Shared.Items)
local G = require(Shared.Gathering)

local player = Players.LocalPlayer
local UI = {}

-- ===== style =====
local C = {
	panel = Color3.fromRGB(28, 26, 34),
	panel2 = Color3.fromRGB(42, 39, 50),
	stroke = Color3.fromRGB(90, 80, 110),
	text = Color3.fromRGB(240, 236, 228),
	muted = Color3.fromRGB(170, 164, 180),
	gold = Color3.fromRGB(242, 201, 76),
	good = Color3.fromRGB(110, 210, 120),
	warn = Color3.fromRGB(240, 120, 90),
	bar = Color3.fromRGB(90, 190, 110),
	barBg = Color3.fromRGB(20, 18, 24),
	button = Color3.fromRGB(70, 110, 190),
}
local FONT = Enum.Font.GothamMedium
local BOLD = Enum.Font.GothamBold

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
	return new("UICorner", { CornerRadius = UDim.new(0, r or 8) })
end
local function stroke(color, t)
	return new("UIStroke", { Color = color or C.stroke, Thickness = t or 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end
local function pad(p)
	return new("UIPadding", { PaddingLeft = UDim.new(0, p), PaddingRight = UDim.new(0, p), PaddingTop = UDim.new(0, p), PaddingBottom = UDim.new(0, p) })
end

local function text(props)
	props.BackgroundTransparency = props.BackgroundTransparency or 1
	props.Font = props.Font or FONT
	props.TextColor3 = props.TextColor3 or C.text
	props.TextSize = props.TextSize or 16
	return new("TextLabel", props)
end

local function button(props, onClick)
	props.BackgroundColor3 = props.BackgroundColor3 or C.button
	props.Font = props.Font or BOLD
	props.TextColor3 = props.TextColor3 or Color3.new(1, 1, 1)
	props.TextSize = props.TextSize or 16
	props.AutoButtonColor = true
	local b = new("TextButton", props, { corner(8) })
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b
end

local function bar(parent, props)
	local bg = new("Frame", { BackgroundColor3 = C.barBg, BorderSizePixel = 0, Parent = parent }, { corner(4) })
	for k, v in props do
		bg[k] = v
	end
	local fill = new("Frame", { Name = "Fill", BackgroundColor3 = C.bar, BorderSizePixel = 0, Size = UDim2.new(0, 0, 1, 0), Parent = bg }, { corner(4) })
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
local request = nil -- function(action, ...) set by Main

local gui = new("ScreenGui", {
	Name = "EndlessRoadUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = player:WaitForChild("PlayerGui"),
})
-- shrink everything a little on small (phone) screens
local scale = new("UIScale", { Parent = gui })
local function rescale()
	local cam = workspace.CurrentCamera
	local v = cam and cam.ViewportSize or Vector2.new(1280, 720)
	scale.Scale = math.clamp(math.min(v.X / 1100, v.Y / 650), 0.6, 1.15)
end
rescale()
task.spawn(function()
	while not workspace.CurrentCamera do
		task.wait()
	end
	local cam = workspace.CurrentCamera
	cam:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()
end)

-- ===== top-left: gold and total level =====
local top = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(360, 36), Parent = gui }, {
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }),
})
local function pill(icon)
	local f = new("Frame", { BackgroundColor3 = C.panel, BackgroundTransparency = 0.15, Size = UDim2.fromOffset(150, 36), Parent = top }, { corner(18), stroke() })
	return text({ Text = icon .. " 0", Size = UDim2.fromScale(1, 1), Font = BOLD, TextSize = 18, Parent = f })
end
local goldLabel = pill("🪙")
goldLabel.TextColor3 = C.gold
local totalLabel = pill("⭐")

-- ===== bottom-left: gathering skills =====
local hud = new("Frame", {
	BackgroundColor3 = C.panel, BackgroundTransparency = 0.15, AnchorPoint = Vector2.new(0, 1),
	Position = UDim2.new(0, 12, 1, -12), Size = UDim2.fromOffset(250, 118), Parent = gui,
}, { corner(10), stroke(), pad(8), new("UIListLayout", { Padding = UDim.new(0, 4) }) })
local hudRows = {}
for _, id in Skills.GATHERING do
	local s = Skills.byId[id]
	local row = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), Parent = hud })
	local lbl = text({ Text = s.icon .. " " .. s.name, Size = UDim2.new(1, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, TextSize = 14, Parent = row })
	local lv = text({ Text = "Lv 1", Size = UDim2.new(1, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Right, Font = BOLD, TextSize = 14, TextColor3 = C.gold, Parent = row })
	local _, fill = bar(row, { Position = UDim2.fromOffset(0, 19), Size = UDim2.new(1, 0, 0, 8) })
	hudRows[id] = { lv = lv, fill = fill, label = lbl }
end

-- ===== right side: menu buttons =====
local menu = new("Frame", {
	BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0),
	Size = UDim2.fromOffset(64, 220), Parent = gui,
}, { new("UIListLayout", { Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Center }) })

-- ===== windows =====
local window = new("Frame", {
	BackgroundColor3 = C.panel, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(560, 420), Visible = false, Parent = gui,
}, { corner(12), stroke(C.stroke, 2) })
local windowTitle = text({ Text = "", Position = UDim2.fromOffset(16, 8), Size = UDim2.new(1, -70, 0, 32), Font = BOLD, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left, Parent = window })
local body = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 48), Size = UDim2.new(1, -24, 1, -60), Parent = window })

local panels = {}
local renderers = {}

local function showPanel(name)
	if openPanel == name or not name then
		openPanel = nil
		window.Visible = false
		return
	end
	openPanel = name
	for n, p in panels do
		p.Visible = n == name
	end
	windowTitle.Text = ({ bag = "🎒 Bag", skills = "📊 Skills", tools = "🛠️ Tools" })[name]
	window.Visible = true
	if renderers[name] then
		renderers[name]()
	end
end
UI.showPanel = showPanel

button({ Text = "✕", Size = UDim2.fromOffset(36, 36), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 8), BackgroundColor3 = C.panel2, Parent = window }, function()
	showPanel(nil)
end)

for _, m in { { "bag", "🎒", "Bag" }, { "skills", "📊", "Skills" }, { "tools", "🛠️", "Tools" } } do
	local b = button({ Text = "", Size = UDim2.fromOffset(64, 64), BackgroundColor3 = C.panel, Parent = menu }, function()
		showPanel(m[1])
	end)
	stroke().Parent = b
	text({ Text = m[2], Size = UDim2.new(1, 0, 0, 40), TextSize = 28, Parent = b })
	text({ Text = m[3], Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 0, 18), TextSize = 12, TextColor3 = C.muted, Parent = b })
end

-- --- Bag ---
do
	local p = new("Frame", { Name = "bag", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = body })
	panels.bag = p
	local grid = new("ScrollingFrame", {
		BackgroundColor3 = C.panel2, BorderSizePixel = 0, Size = UDim2.new(1, 0, 1, -96), ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = p,
	}, { corner(8), pad(8), new("UIGridLayout", { CellSize = UDim2.fromOffset(78, 78), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
	local empty = text({ Text = "Your bag is empty. Chop trees, mine rocks and fish to fill it!", Size = UDim2.new(1, 0, 1, -96), TextColor3 = C.muted, TextWrapped = true, Parent = p })
	local detail = new("Frame", { BackgroundColor3 = C.panel2, AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), Size = UDim2.new(1, 0, 0, 86), Parent = p }, { corner(8), pad(10) })
	local dName = text({ Text = "", Size = UDim2.new(0.5, 0, 0, 24), Font = BOLD, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left, Parent = detail })
	local dInfo = text({ Text = "Tap an item to sell it.", Position = UDim2.fromOffset(0, 26), Size = UDim2.new(0.55, 0, 0, 40), TextColor3 = C.muted, TextSize = 14, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Parent = detail })
	local sell1 = button({ Text = "Sell 1", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -230, 0, 0), Size = UDim2.fromOffset(100, 30), Parent = detail }, function()
		if selectedItem then request("sell", selectedItem, 1) end
	end)
	local sellAllOf = button({ Text = "Sell all", AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -120, 0, 0), Size = UDim2.fromOffset(100, 30), BackgroundColor3 = Color3.fromRGB(170, 120, 40), Parent = detail }, function()
		if selectedItem then request("sell", selectedItem, "all") end
	end)
	local sellEverything = button({ Text = "💰 Sell all resources", AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, 0, 1, 0), Size = UDim2.fromOffset(210, 32), BackgroundColor3 = Color3.fromRGB(150, 100, 30), Parent = detail }, function()
		request("sellAll")
	end)
	sellAllOf.AnchorPoint = Vector2.new(1, 0)
	sellAllOf.Position = UDim2.new(1, 0, 0, 0)
	sell1.Position = UDim2.new(1, -108, 0, 0)

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
		local total = 0
		for _, id in ids do
			local it, n = Items[id], state.inv[id]
			total += it.value * n
			local slot = button({ Text = "", LayoutOrder = it.order, BackgroundColor3 = selectedItem == id and Color3.fromRGB(80, 70, 110) or C.panel, Parent = grid }, function()
				selectedItem = id
				renderers.bag()
			end)
			if it.color then
				new("Frame", { BackgroundColor3 = Color3.fromHex(it.color), Size = UDim2.new(1, -16, 0, 4), Position = UDim2.new(0, 8, 1, -8), BorderSizePixel = 0, Parent = slot }, { corner(2) })
			end
			text({ Text = it.icon, Size = UDim2.new(1, 0, 0, 46), TextSize = 32, Parent = slot })
			text({ Text = fmt(n), Position = UDim2.fromOffset(0, 46), Size = UDim2.new(1, 0, 0, 20), Font = BOLD, TextSize = 15, Parent = slot })
		end
		if selectedItem and not (state and state.inv[selectedItem]) then selectedItem = nil end
		if selectedItem then
			local it, n = Items[selectedItem], state.inv[selectedItem]
			dName.Text = it.icon .. " " .. it.name
			dInfo.Text = ("%s × %d  ·  %s gold each  ·  worth %s"):format(it.type, n, fmt(it.value), fmt(it.value * n))
		else
			dName.Text = "Bag"
			dInfo.Text = ("Tap an item to sell it. Everything is worth %s gold."):format(fmt(total))
		end
		sell1.Visible = selectedItem ~= nil
		sellAllOf.Visible = selectedItem ~= nil
		sellEverything.Visible = #ids > 0
	end
end

-- --- Skills ---
do
	local p = new("ScrollingFrame", {
		Name = "skills", BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Visible = false, ScrollBarThickness = 6,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), Parent = body,
	}, { new("UIGridLayout", { CellSize = UDim2.fromOffset(170, 52), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }) })
	panels.skills = p
	local cells = {}
	for _, s in Skills.LIST do
		local active = Skills.ACTIVE[s.id]
		local cell = new("Frame", { LayoutOrder = s.order, BackgroundColor3 = C.panel2, BackgroundTransparency = active and 0 or 0.5, Parent = p }, { corner(8), pad(6) })
		local name = text({ Text = s.icon .. " " .. s.name, Size = UDim2.new(1, 0, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, TextSize = 14, TextColor3 = active and C.text or C.muted, Parent = cell })
		local lv = text({ Text = "1", Size = UDim2.new(1, 0, 0, 18), TextXAlignment = Enum.TextXAlignment.Right, Font = BOLD, TextSize = 15, TextColor3 = C.gold, Parent = cell })
		local sub = text({ Text = active and "" or "Coming soon", Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 12), TextSize = 11, TextColor3 = C.muted, TextXAlignment = Enum.TextXAlignment.Left, Parent = cell })
		local bg, fill = bar(cell, { Position = UDim2.fromOffset(0, 22), Size = UDim2.new(1, 0, 0, 4), Visible = active })
		cells[s.id] = { lv = lv, fill = fill, sub = sub, bg = bg, name = name }
	end
	renderers.skills = function()
		if not state then return end
		for _, s in Skills.LIST do
			local xp = state.skills[s.id] or 0
			local l, frac, need = XP.progress(xp)
			local c = cells[s.id]
			c.lv.Text = tostring(l)
			c.fill.Size = UDim2.new(frac, 0, 1, 0)
			if Skills.ACTIVE[s.id] then
				c.sub.Position = UDim2.fromOffset(0, 27)
				c.sub.Text = l >= XP.MAX_LEVEL and (fmt(xp) .. " XP · max") or (fmt(xp) .. " XP · " .. fmt(need) .. " to go")
			end
		end
	end
end

-- --- Tools ---
do
	local p = new("Frame", { Name = "tools", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, Parent = body }, {
		new("UIListLayout", { Padding = UDim.new(0, 10) }),
	})
	panels.tools = p
	text({ Text = "Better tools gather 12% faster per upgrade. Sell resources in your bag for gold.", Size = UDim2.new(1, 0, 0, 36), TextWrapped = true, TextColor3 = C.muted, TextSize = 14, LayoutOrder = 0, Parent = p })
	local rows = {}
	local skillOf = { axe = "woodcutting", pick = "mining", rod = "fishing" }
	for i, tool in G.TOOL_ORDER do
		local row = new("Frame", { LayoutOrder = i, BackgroundColor3 = C.panel2, Size = UDim2.new(1, 0, 0, 74), Parent = p }, { corner(8), pad(10) })
		local name = text({ Text = "", Size = UDim2.new(0.6, 0, 0, 24), Font = BOLD, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
		local info = text({ Text = "", Position = UDim2.fromOffset(0, 28), Size = UDim2.new(0.62, 0, 0, 30), TextSize = 13, TextColor3 = C.muted, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = row })
		local buy = button({ Text = "", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(190, 44), Parent = row }, function()
			request("upgrade", tool)
		end)
		rows[tool] = { name = name, info = info, buy = buy, skill = skillOf[tool] }
	end
	renderers.tools = function()
		if not state then return end
		for tool, r in rows do
			local lvl = state.tools[tool] or 0
			r.name.Text = Skills.byId[r.skill].icon .. " " .. G.toolName(tool, lvl)
			r.info.Text = ("%d%% faster %s"):format(math.floor(12 * lvl + 0.5), Skills.byId[r.skill].name:lower())
			if lvl >= G.TOOL_MAX then
				r.buy.Text = "Max level"
				r.buy.BackgroundColor3 = C.panel
				r.buy.Active = false
			else
				local cost = G.TOOL_COST[lvl]
				r.buy.Text = ("%s – 🪙 %s"):format(G.METALS[lvl + 1], fmt(cost))
				r.buy.BackgroundColor3 = state.gold >= cost and C.good or Color3.fromRGB(90, 85, 100)
				r.buy.Active = true
			end
		end
	end
end

-- ===== action bar =====
local action = new("Frame", {
	BackgroundColor3 = C.panel, BackgroundTransparency = 0.1, AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -20), Size = UDim2.fromOffset(380, 64), Visible = false, Parent = gui,
}, { corner(10), stroke(), pad(10) })
local actionText = text({ Text = "", Size = UDim2.new(1, -90, 0, 22), Font = BOLD, TextXAlignment = Enum.TextXAlignment.Left, Parent = action })
local _, actionFill = bar(action, { Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, -90, 0, 14) })
button({ Text = "Stop", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(76, 40), BackgroundColor3 = Color3.fromRGB(170, 60, 60), Parent = action }, function()
	request("stop")
end)
local actionTween = nil

function UI.actionStart(info)
	action.Visible = true
	local have = state and state.inv[info.item] or 0
	actionText.Text = ("%s %s  ·  %s %s"):format(G.VERB_ING[info.skill], info.name, Items[info.item].icon, fmt(have))
	if actionTween then actionTween:Cancel() end
	actionFill.Size = UDim2.new(0, 0, 1, 0)
	actionTween = TweenService:Create(actionFill, TweenInfo.new(info.duration, Enum.EasingStyle.Linear), { Size = UDim2.new(1, 0, 1, 0) })
	actionTween:Play()
end

function UI.actionStop()
	if actionTween then actionTween:Cancel() end
	action.Visible = false
end

-- ===== floating gains, toasts, banners =====
local floatHolder = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -96), Size = UDim2.fromOffset(300, 30), Parent = gui })
function UI.floatText(str, color)
	local t = text({ Text = str, Size = UDim2.fromScale(1, 1), Font = BOLD, TextSize = 20, TextColor3 = color or C.text, TextStrokeTransparency = 0.3, Parent = floatHolder })
	TweenService:Create(t, TweenInfo.new(1.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Position = UDim2.fromOffset(0, -70), TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	task.delay(1.5, function() t:Destroy() end)
end

local toasts = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 12), Size = UDim2.fromOffset(460, 200), Parent = gui }, {
	new("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center }),
})
function UI.toast(msg, kind)
	local col = kind == "warn" and C.warn or kind == "gold" and C.gold or kind == "good" and C.good or C.text
	local f = new("Frame", { BackgroundColor3 = C.panel, BackgroundTransparency = 0.1, Size = UDim2.fromOffset(460, 34), Parent = toasts }, { corner(8), stroke(col, 1.5) })
	local t = text({ Text = msg, Size = UDim2.fromScale(1, 1), TextColor3 = col, TextSize = 15, TextWrapped = true, Parent = f })
	task.delay(3.5, function()
		TweenService:Create(f, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(t, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		local s = f:FindFirstChildOfClass("UIStroke")
		if s then TweenService:Create(s, TweenInfo.new(0.4), { Transparency = 1 }):Play() end
		task.wait(0.45)
		f:Destroy()
	end)
end

local banner = text({ Text = "", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.3), Size = UDim2.fromOffset(700, 60), Font = Enum.Font.GothamBlack, TextSize = 38, TextColor3 = C.gold, TextStrokeTransparency = 0.2, TextTransparency = 1, TextStrokeColor3 = Color3.new(0, 0, 0), Parent = gui })
local bannerSub = text({ Text = "", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.3, 40), Size = UDim2.fromOffset(700, 30), Font = BOLD, TextSize = 20, TextStrokeTransparency = 0.3, TextTransparency = 1, Parent = gui })
local bannerId = 0
function UI.banner(main, sub, color)
	bannerId += 1
	local id = bannerId
	banner.Text, bannerSub.Text = main, sub or ""
	banner.TextColor3 = color or C.gold
	banner.TextTransparency, banner.TextStrokeTransparency = 0, 0.2
	bannerSub.TextTransparency, bannerSub.TextStrokeTransparency = 0, 0.3
	banner.Size = UDim2.fromOffset(500, 40)
	TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(700, 60) }):Play()
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
	local modal = new("Frame", { BackgroundColor3 = C.panel, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(440, 290), ZIndex = 10, Parent = gui }, { corner(12), stroke(C.gold, 2), pad(16) })
	local lines = {
		("While you were away (%dh %dm) your hero kept %s:"):format(h, m, o.verb:lower()),
		"",
		("%s  %s: +%s XP%s"):format(Skills.byId[o.skill].icon, Skills.byId[o.skill].name, fmt(o.xp), o.levelAfter > o.levelBefore and ("  (Lv %d → %d)"):format(o.levelBefore, o.levelAfter) or ""),
		("%s  %s: +%s"):format(Items[o.item].icon, o.itemName, fmt(o.actions)),
	}
	if o.seconds > o.cap then
		table.insert(lines, "")
		table.insert(lines, ("Offline progress is capped at %dh."):format(o.cap // 3600))
	end
	text({ Text = "⏳ Welcome back!", Size = UDim2.new(1, 0, 0, 30), Font = BOLD, TextSize = 24, TextColor3 = C.gold, ZIndex = 10, Parent = modal })
	text({ Text = table.concat(lines, "\n"), Position = UDim2.fromOffset(0, 40), Size = UDim2.new(1, 0, 1, -96), TextWrapped = true, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, ZIndex = 10, Parent = modal })
	button({ Text = "Collect", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.fromOffset(180, 44), BackgroundColor3 = C.good, ZIndex = 10, Parent = modal }, function()
		modal:Destroy()
	end)
end

-- ===== data refresh =====
function UI.setData(view)
	state = view
	goldLabel.Text = "🪙 " .. fmt(view.gold)
	local total = 0
	for _, s in Skills.LIST do
		total += XP.levelFromXp(view.skills[s.id] or 0)
	end
	totalLabel.Text = "⭐ Total " .. total
	for id, r in hudRows do
		local l, frac = XP.progress(view.skills[id] or 0)
		r.lv.Text = "Lv " .. l
		TweenService:Create(r.fill, TweenInfo.new(0.3), { Size = UDim2.new(frac, 0, 1, 0) }):Play()
	end
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

return UI
