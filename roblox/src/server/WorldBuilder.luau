-- Builds the world map (Zones.luau): zone grounds, roads with arches, the town, scenery and the resource nodes, out of plain Parts.
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Zones = require(Shared.Zones)
local G = require(Shared.Gathering)
local Tiers = require(Shared.Tiers)
local Remotes = require(Shared.Remotes)

local WorldBuilder = {}

local hex = Color3.fromHex
local RW = Zones.ROAD_WIDTH

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if props.Shape then
		p.Shape = props.Shape -- before Size: changing the shape afterwards can reshape the part
	end
	for k, v in props do
		p[k] = v
	end
	return p
end

local function darker(c: Color3, f: number): Color3
	return Color3.new(c.R * f, c.G * f, c.B * f)
end

local function label(parent, text, sub, dist)
	local bb = Instance.new("BillboardGui")
	bb.Name = "Label"
	bb.Size = UDim2.fromOffset(200, 44)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 1.5, 0)
	bb.AlwaysOnTop = false
	bb.MaxDistance = dist or 45
	bb.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 0.6, 0)
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.4
	t.Text = text
	t.Parent = bb
	local s = t:Clone()
	s.Position = UDim2.new(0, 0, 0.6, 0)
	s.Size = UDim2.new(1, 0, 0.4, 0)
	s.Font = Enum.Font.Gotham
	s.TextColor3 = Color3.fromRGB(255, 230, 140)
	s.Text = sub
	s.Parent = bb
	bb.Parent = parent
	return bb
end

-- ===================== resource nodes =====================
-- Every node tells the player what it is three ways, so colour is never the only cue:
-- its own shape, a ring on the ground in the rarity colour (Tiers.luau) and a label with name and level.
-- The client recolours the level line for the local player (green: you can, red with a lock: not yet).
local nodeCount = 0

local function chipEmitter(core, color)
	local e = Instance.new("ParticleEmitter")
	e.Name = "Chips"
	e.Enabled = false
	e.Rate = 0
	e.Color = ColorSequence.new(color)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(0.4, 0.8)
	e.Speed = NumberRange.new(6, 12)
	e.SpreadAngle = Vector2.new(60, 60)
	e.Acceleration = Vector3.new(0, -30, 0)
	e.LightInfluence = 0.5
	e.Parent = core
end

-- slow rising glints that mark rare nodes from far away
local function sparkles(parent, color, rate)
	local e = Instance.new("ParticleEmitter")
	e.Name = "Sparkles"
	e.Color = ColorSequence.new(color)
	e.LightEmission = 1
	e.LightInfluence = 0
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.35), NumberSequenceKeypoint.new(1, 0) })
	e.Lifetime = NumberRange.new(1, 1.8)
	e.Rate = rate or 4
	e.Speed = NumberRange.new(1, 2.5)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Acceleration = Vector3.new(0, 1.5, 0)
	e.Parent = parent
end

local function tierRing(model, pos: Vector3, radius: number, color: Color3)
	part({
		Name = "TierRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.12, radius * 2, radius * 2),
		CFrame = CFrame.new(pos + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = color, Material = Enum.Material.Neon, Transparency = 0.72, CanCollide = false, CanQuery = false, CanTouch = false, Parent = model,
	})
end

-- name on top, "Lv 15" underneath; the BillboardGui is sized in studs so far-away labels shrink
local function nodeLabel(anchor, title: string, req: number, color: Color3)
	local bb = Instance.new("BillboardGui")
	bb.Name = "NodeLabel"
	bb.Size = UDim2.fromScale(7, 2.3)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 1.4, 0)
	bb.MaxDistance = 70
	bb.LightInfluence = 0
	bb:SetAttribute("Req", req)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = Color3.fromRGB(24, 22, 38)
	f.BackgroundTransparency = 0.25
	f.Size = UDim2.fromScale(1, 1)
	f.Parent = bb
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0.25, 0)
	c.Parent = f
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = 2
	s.Parent = f
	local t = Instance.new("TextLabel")
	t.Name = "Title"
	t.BackgroundTransparency = 1
	t.Position = UDim2.fromScale(0.05, 0.06)
	t.Size = UDim2.fromScale(0.9, 0.5)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.Text = title
	t.Parent = f
	local lv = t:Clone()
	lv.Name = "Level"
	lv.Position = UDim2.fromScale(0.05, 0.56)
	lv.Size = UDim2.fromScale(0.9, 0.38)
	lv.Font = Enum.Font.GothamBold
	lv.TextColor3 = color
	lv.Text = "Lv " .. req
	lv.Parent = f
	bb.Parent = anchor
	return bb
end

local SKILL_ICON = { woodcutting = "🌲", mining = "⛏️", fishing = "🎣" }

local function finishNode(model, core, skill, tier, top: Vector3, ringRadius: number)
	nodeCount += 1
	local info = G.node(skill, tier)
	local color = Tiers.color(G.rarity(skill, tier))
	model.Name = "Node_" .. nodeCount
	model.PrimaryPart = core
	model:SetAttribute("NodeId", nodeCount)
	model:SetAttribute("Skill", skill)
	model:SetAttribute("Tier", tier)

	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "GatherPrompt"
	prompt.ActionText = G.VERB[skill]
	prompt.ObjectText = ("%s (Lv %d)"):format(info.name, info.req)
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 11
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = core

	local base = Vector3.new(core.Position.X, 0, core.Position.Z)
	tierRing(model, base, ringRadius, color)
	local anchor = Instance.new("Attachment")
	anchor.Name = "LabelAnchor"
	anchor.Parent = core
	anchor.WorldPosition = top
	nodeLabel(anchor, SKILL_ICON[skill] .. " " .. info.name, info.req, color)
end

-- each tree type has its own silhouette, not just another colour
local TREES = {
	[0] = { trunk = "#ece8de", d = 1.1, h = 8, leaves = "#a6dc72", r = 6, form = "round" }, -- Birch: thin white trunk
	{ trunk = "#6b4a2b", d = 2.4, h = 7, leaves = "#3f8f3a", r = 8.5, form = "wide" }, -- Oak: fat trunk, wide crown
	{ trunk = "#7a4a2a", d = 1.6, h = 9, leaves = "#e8742c", r = 7.5, form = "round", fall = true }, -- Maple: autumn orange
	{ trunk = "#3e2a1a", d = 1.8, h = 6, leaves = "#24604a", r = 9, form = "cone" }, -- Yew: tall dark cone
	{ trunk = "#4a2a5a", d = 2.1, h = 10, leaves = "#b56cf0", r = 8, form = "round", glow = true }, -- Elder: magic
}

local function makeTree(parent, pos, tier, rng)
	local st = TREES[tier]
	local model = Instance.new("Model")
	local h, d = st.h, st.d
	local trunk = part({
		Name = "Trunk", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, d, d),
		CFrame = CFrame.new(pos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = hex(st.trunk), Material = Enum.Material.Wood, Parent = model,
	})
	local leaves = hex(st.leaves)
	local top = h
	if tier == 0 then
		-- birch bark stripes
		for i = 1, 4 do
			part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.25, d + 0.06, d + 0.06), CFrame = CFrame.new(pos + Vector3.new(0, i * h / 5 + rng:NextNumber(-0.4, 0.4), 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = hex("#2a2a2a"), Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = model })
		end
	end
	if st.form == "cone" then
		for i = 0, 3 do
			local s = st.r * (1 - i * 0.22)
			part({ Name = "Leaves" .. i, Size = Vector3.new(s, 3, s), CFrame = CFrame.new(pos + Vector3.new(0, h - 1 + i * 2.6, 0)) * CFrame.Angles(0, math.rad(45 * i), 0), Color = darker(leaves, 1 - i * 0.06), Material = Enum.Material.Grass, CanCollide = false, Parent = model })
		end
		top = h + 4 * 2.6
	elseif st.form == "wide" then
		local r = st.r
		part({ Name = "Canopy", Shape = Enum.PartType.Ball, Size = Vector3.new(r, r * 0.8, r), CFrame = CFrame.new(pos + Vector3.new(0, h + r * 0.2, 0)), Color = leaves, Material = Enum.Material.Grass, CanCollide = false, Parent = model })
		for i = 1, 4 do
			local a = i * math.pi / 2 + rng:NextNumber(-0.3, 0.3)
			local rr = r * 0.62
			part({ Name = "Canopy" .. i, Shape = Enum.PartType.Ball, Size = Vector3.new(rr, rr, rr), CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * r * 0.45, h - 0.4, math.sin(a) * r * 0.45)), Color = darker(leaves, 0.88), Material = Enum.Material.Grass, CanCollide = false, Parent = model })
		end
		top = h + r * 0.7
	else
		local r = st.r
		local canopy = part({ Name = "Canopy", Shape = Enum.PartType.Ball, Size = Vector3.new(r, r, r), CFrame = CFrame.new(pos + Vector3.new(0, h + r * 0.25, 0)), Color = leaves, Material = st.glow and Enum.Material.Neon or Enum.Material.Grass, Transparency = st.glow and 0.15 or 0, CanCollide = false, Parent = model })
		for i = 1, 2 do
			local rr = r * 0.65
			local off = Vector3.new(rng:NextNumber(-1, 1) * r * 0.35, -r * 0.1, rng:NextNumber(-1, 1) * r * 0.35)
			part({ Name = "Canopy" .. i, Shape = Enum.PartType.Ball, Size = Vector3.new(rr, rr, rr), CFrame = CFrame.new(pos + Vector3.new(0, h, 0) + off), Color = darker(leaves, 0.85), Material = Enum.Material.Grass, CanCollide = false, Parent = model })
		end
		if st.fall then
			local e = Instance.new("ParticleEmitter")
			e.Name = "Leaves"
			e.Color = ColorSequence.new(leaves, hex("#c0402a"))
			e.Size = NumberSequence.new(0.3)
			e.Lifetime = NumberRange.new(2.5, 4)
			e.Rate = 2
			e.Speed = NumberRange.new(0.5, 1)
			e.Acceleration = Vector3.new(0.4, -1.2, 0)
			e.RotSpeed = NumberRange.new(-90, 90)
			e.Rotation = NumberRange.new(0, 360)
			e.Parent = canopy
		end
		if st.glow then
			local light = Instance.new("PointLight")
			light.Color = leaves
			light.Range = 16
			light.Brightness = 1.6
			light.Parent = canopy
			sparkles(canopy, Color3.fromRGB(230, 200, 255), 6)
		end
		top = h + r * 0.8
	end
	chipEmitter(trunk, hex("#c8a070"))
	finishNode(model, trunk, "woodcutting", tier, pos + Vector3.new(0, top + 0.8, 0), math.max(st.r * 0.42, 3))
	model.Parent = parent
	return model
end

-- low ores are lumps on the rock, high ores grow as glowing crystals
local ROCK_FORM = { [0] = "lumps", "cubes", "lumps", "coal", "crystals", "crystals", "crystals" }

local function makeRock(parent, pos, tier, rng)
	local model = Instance.new("Model")
	local ore = G.ORES[tier]
	local oreColor = hex(ore.color)
	local size = 1 + tier * 0.07
	local rockColor = hex("#5e5a58"):Lerp(oreColor, 0.18) -- dark stone so light ores (tin) still stand out
	local base = part({
		Name = "Rock", Size = Vector3.new(5.5, 3.6, 5) * size,
		CFrame = CFrame.new(pos + Vector3.new(0, 1.6 * size, 0)) * CFrame.Angles(math.rad(rng:NextNumber(-8, 8)), rng:NextNumber(0, math.pi * 2), math.rad(rng:NextNumber(-8, 8))),
		Color = rockColor, Material = Enum.Material.Slate, Parent = model,
	})
	part({
		Name = "Rock2", Size = Vector3.new(3.4, 2.6, 3.2) * size,
		CFrame = base.CFrame * CFrame.new(1.2, 1.6, 0.4) * CFrame.Angles(0.3, 0.5, 0.2),
		Color = darker(rockColor, 1.08), Material = Enum.Material.Slate, Parent = model,
	})
	local form = ROCK_FORM[tier]
	local count = form == "crystals" and 6 or 6 + tier
	for i = 1, count do
		local a = (i / count) * math.pi * 2
		local at = base.CFrame * CFrame.new(math.cos(a) * 2.6 * size, rng:NextNumber(0.6, 1.9), math.sin(a) * 2.4 * size)
		if form == "crystals" then
			local hgt = rng:NextNumber(1.6, 3.2)
			part({ Name = "Ore" .. i, Size = Vector3.new(0.7, hgt, 0.7), CFrame = at * CFrame.new(0, hgt / 2, 0) * CFrame.Angles(rng:NextNumber(-0.5, 0.5), rng:NextNumber(0, 3), rng:NextNumber(-0.5, 0.5)), Color = oreColor, Material = Enum.Material.Neon, Transparency = 0.1, CanCollide = false, Parent = model })
		elseif form == "cubes" then
			local s = rng:NextNumber(0.8, 1.2)
			part({ Name = "Ore" .. i, Size = Vector3.new(s, s, s), CFrame = at * CFrame.Angles(rng:NextNumber(0, 1), rng:NextNumber(0, 1), 0), Color = oreColor, Material = Enum.Material.Metal, Reflectance = 0.25, CanCollide = false, Parent = model })
		elseif form == "coal" then
			local s = rng:NextNumber(1, 1.5)
			part({ Name = "Ore" .. i, Size = Vector3.new(s, s * 0.7, s), CFrame = at * CFrame.Angles(rng:NextNumber(0, 1), rng:NextNumber(0, 1), 0), Color = oreColor, Material = Enum.Material.Slate, CanCollide = false, Parent = model })
		else
			local s = rng:NextNumber(1.4, 1.9)
			part({ Name = "Ore" .. i, Shape = Enum.PartType.Ball, Size = Vector3.new(s, s, s), CFrame = at, Color = oreColor, Material = Enum.Material.Metal, Reflectance = 0.15, CanCollide = false, Parent = model })
		end
	end
	if form == "crystals" then
		local light = Instance.new("PointLight")
		light.Color = oreColor
		light.Range = 12
		light.Brightness = 1.4
		light.Parent = base
		sparkles(base, oreColor, 3 + tier)
	end
	chipEmitter(base, oreColor)
	finishNode(model, base, "mining", tier, pos + Vector3.new(0, 6 * size + (form == "crystals" and 1.5 or 0), 0), 4 * size)
	model.Parent = parent
	return model
end

local function makeFishSpot(parent, pos, tier)
	local model = Instance.new("Model")
	local color = Tiers.color(tier)
	local ring = part({
		Name = "Ripple", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 5, 5),
		CFrame = CFrame.new(pos + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = Color3.new(1, 1, 1), Material = Enum.Material.Neon, Transparency = 0.7, CanCollide = false, Parent = model,
	})
	local bubbles = Instance.new("ParticleEmitter")
	bubbles.Name = "Bubbles"
	bubbles.Rate = 6 + tier * 2
	bubbles.Lifetime = NumberRange.new(0.6, 1.2)
	bubbles.Speed = NumberRange.new(1, 3)
	bubbles.SpreadAngle = Vector2.new(30, 30)
	bubbles.Size = NumberSequence.new(0.3)
	bubbles.Color = ColorSequence.new(Color3.new(1, 1, 1):Lerp(color, 0.5))
	bubbles.Transparency = NumberSequence.new(0.3)
	bubbles.EmissionDirection = Enum.NormalId.Right -- the cylinder's axis points up
	bubbles.Parent = ring
	-- a fish fin circling in the ripple shows what kind of spot this is
	local fin = part({ Name = "Fin", Size = Vector3.new(0.2, 0.9, 1.1), CFrame = CFrame.new(pos + Vector3.new(1.5, 0.5, 0)), Color = color, Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = model })
	fin:SetAttribute("Swim", true)
	chipEmitter(ring, hex("#bfe8ff"))
	finishNode(model, ring, "fishing", tier, pos + Vector3.new(0, 3.5, 0), 3)
	model.Parent = parent
	return model
end

-- ===================== scenery =====================
local function decorTree(parent, pos, rng, color)
	local h = rng:NextNumber(8, 14)
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, 1.6, 1.6), CFrame = CFrame.new(pos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = hex("#5a3d22"), Material = Enum.Material.Wood, Parent = parent })
	local r = rng:NextNumber(7, 11)
	part({ Shape = Enum.PartType.Ball, Size = Vector3.new(r, r, r), CFrame = CFrame.new(pos + Vector3.new(0, h, 0)), Color = color, Material = Enum.Material.Grass, Parent = parent })
end

local function decorPine(parent, pos, rng, color)
	local h = rng:NextNumber(10, 18)
	part({ Size = Vector3.new(1.4, h * 0.4, 1.4), CFrame = CFrame.new(pos + Vector3.new(0, h * 0.2, 0)), Color = hex("#4a321c"), Material = Enum.Material.Wood, Parent = parent })
	for i = 0, 2 do
		local s = (h * 0.55) * (1 - i * 0.28)
		part({ Size = Vector3.new(s, h * 0.28, s), CFrame = CFrame.new(pos + Vector3.new(0, h * (0.4 + i * 0.2), 0)) * CFrame.Angles(0, math.rad(45 * i + rng:NextNumber(0, 30)), 0), Color = darker(color, 1 - i * 0.08), Material = Enum.Material.Grass, Parent = parent })
	end
end

local function decorStalag(parent, pos, rng, color)
	local h = rng:NextNumber(6, 20)
	local d = rng:NextNumber(2, 4)
	part({ Size = Vector3.new(d, h, d), CFrame = CFrame.new(pos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), Color = color, Material = Enum.Material.Slate, Parent = parent })
	part({ Size = Vector3.new(d * 0.6, h * 0.7, d * 0.6), CFrame = CFrame.new(pos + Vector3.new(rng:NextNumber(-6, 6), 45 - h * 0.35, rng:NextNumber(-6, 6))), Color = color, Material = Enum.Material.Slate, CanCollide = false, Parent = parent })
	if rng:NextNumber() < 0.35 then
		local c = part({ Size = Vector3.new(1, 3, 1), CFrame = CFrame.new(pos + Vector3.new(d, 1.5, 0)) * CFrame.Angles(0.3, 0, 0.3), Color = hex("#b06bff"), Material = Enum.Material.Neon, CanCollide = false, Parent = parent })
		local l = Instance.new("PointLight")
		l.Color = c.Color
		l.Range = 12
		l.Parent = c
	end
end

local function decorRock(parent, pos, rng, color)
	local s = rng:NextNumber(4, 10)
	local p = part({ Size = Vector3.new(s, s * 0.7, s * 0.9), CFrame = CFrame.new(pos + Vector3.new(0, s * 0.3, 0)) * CFrame.Angles(0.1, rng:NextNumber(0, 3), 0.1), Color = hex("#7f8b98"), Material = Enum.Material.Slate, Parent = parent })
	part({ Size = Vector3.new(s * 1.02, s * 0.15, s * 0.92), CFrame = p.CFrame * CFrame.new(0, s * 0.35, 0), Color = color, Material = Enum.Material.Snow, Parent = parent })
end

local function decorSpike(parent, pos, rng, _color)
	local h = rng:NextNumber(5, 14)
	part({ Size = Vector3.new(2.5, h, 2.5), CFrame = CFrame.new(pos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(rng:NextNumber(-0.2, 0.2), rng:NextNumber(0, 3), rng:NextNumber(-0.2, 0.2)), Color = hex("#1c0806"), Material = Enum.Material.Basalt, Parent = parent })
	if rng:NextNumber() < 0.4 then
		local lava = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 9, 9), CFrame = CFrame.new(pos + Vector3.new(6, 0.05, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = hex("#ff6a1a"), Material = Enum.Material.Neon, CanCollide = false, Parent = parent })
		local l = Instance.new("PointLight")
		l.Color = lava.Color
		l.Range = 16
		l.Brightness = 2
		l.Parent = lava
	end
end

local DECOR = { tree = decorTree, pine = decorPine, stalag = decorStalag, rock = decorRock, spike = decorSpike }

-- flower patches and bushes for the grassy zones
local FLOWERS = { "#ff7aa8", "#ffd84a", "#b07aff", "#ffffff", "#ff8a4a" }
local function decorFlowers(parent, pos, rng)
	if rng:NextNumber() < 0.4 then
		local s = rng:NextNumber(3, 6)
		part({ Shape = Enum.PartType.Ball, Size = Vector3.new(s, s * 0.7, s), CFrame = CFrame.new(pos + Vector3.new(0, s * 0.25, 0)), Color = hex("#4a8f38"), Material = Enum.Material.Grass, CanCollide = false, Parent = parent })
		return
	end
	local col = hex(FLOWERS[rng:NextInteger(1, #FLOWERS)])
	for _ = 1, rng:NextInteger(5, 9) do
		local o = Vector3.new(rng:NextNumber(-3, 3), 0, rng:NextNumber(-3, 3))
		part({ Size = Vector3.new(0.2, 1, 0.2), CFrame = CFrame.new(pos + o + Vector3.new(0, 0.5, 0)), Color = hex("#3f8f3a"), Material = Enum.Material.Grass, CanCollide = false, Parent = parent })
		part({ Shape = Enum.PartType.Ball, Size = Vector3.new(0.8, 0.8, 0.8), CFrame = CFrame.new(pos + o + Vector3.new(0, 1.1, 0)), Color = col, Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = parent })
	end
end

local function torch(parent, pos)
	part({ Size = Vector3.new(0.5, 5, 0.5), CFrame = CFrame.new(pos + Vector3.new(0, 2.5, 0)), Color = hex("#4a321c"), Material = Enum.Material.Wood, Parent = parent })
	local flame = part({ Shape = Enum.PartType.Ball, Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(pos + Vector3.new(0, 5.3, 0)), Color = hex("#ffb347"), Material = Enum.Material.Neon, CanCollide = false, Parent = parent })
	local l = Instance.new("PointLight")
	l.Color = flame.Color
	l.Range = 22
	l.Brightness = 2
	l.Parent = flame
	local fire = Instance.new("Fire")
	fire.Size = 2
	fire.Heat = 4
	fire.Parent = flame
end

local function signBoard(board, title, sub)
	for _, normal in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local sg = Instance.new("SurfaceGui")
		sg.Face = normal
		sg.CanvasSize = Vector2.new(400, 100)
		sg.LightInfluence = 0
		local t = Instance.new("TextLabel")
		t.BackgroundTransparency = 1
		t.Size = UDim2.new(1, 0, 0.62, 0)
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.TextColor3 = Color3.fromRGB(255, 240, 200)
		t.Text = title
		t.Parent = sg
		local s = t:Clone()
		s.Font = Enum.Font.GothamBold
		s.Position = UDim2.new(0, 0, 0.62, 0)
		s.Size = UDim2.new(1, 0, 0.34, 0)
		s.TextColor3 = Color3.fromRGB(255, 210, 110)
		s.Text = sub
		s.Parent = sg
		sg.Parent = board
	end
end

-- a stone arch over a road where it enters a zone; alongX: the road runs along X
local function archGate(parent, pos: Vector3, alongX: boolean, title: string, sub: string)
	local stone = hex("#8a7f70")
	local rot = alongX and CFrame.Angles(0, math.rad(90), 0) or CFrame.new()
	local base = CFrame.new(pos) * rot
	for _, x in { -(RW / 2 + 2), RW / 2 + 2 } do
		part({ Name = "Pillar", Size = Vector3.new(3, 16, 3), CFrame = base * CFrame.new(x, 8, 0), Color = stone, Material = Enum.Material.Cobblestone, Parent = parent })
	end
	part({ Name = "Beam", Size = Vector3.new(RW + 9, 2.5, 3), CFrame = base * CFrame.new(0, 16, 0), Color = stone, Material = Enum.Material.Cobblestone, Parent = parent })
	local board = part({ Name = "Sign", Size = Vector3.new(RW + 2, 4.5, 0.6), CFrame = base * CFrame.new(0, 12.2, 0), Color = hex("#5a3d22"), Material = Enum.Material.Wood, CanCollide = false, Parent = parent })
	signBoard(board, title, sub)
end

local function road(parent, a: Vector3, b: Vector3, color: Color3)
	local d = b - a
	local len = d.Magnitude
	local mid = (a + b) / 2
	local cf = CFrame.lookAt(Vector3.new(mid.X, -0.4, mid.Z), Vector3.new(b.X, -0.4, b.Z))
	part({ Name = "Road", Size = Vector3.new(RW, 1, len + RW), CFrame = cf, Color = color, Material = Enum.Material.Ground, Parent = parent })
end

-- distance from point p to the segment a-b on the ground plane
local function segDist(p: Vector3, a: Vector3, b: Vector3): number
	local ab = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local ap = Vector3.new(p.X - a.X, 0, p.Z - a.Z)
	local t = math.clamp(ap:Dot(ab) / math.max(ab:Dot(ab), 1e-6), 0, 1)
	return (ap - ab * t).Magnitude
end

local function nearRoad(p: Vector3, margin: number): boolean
	for _, r in Zones.ROADS do
		if segDist(p, r[1], r[2]) < RW / 2 + margin then
			return true
		end
	end
	return false
end

-- nodes go into parent, the pond they stand on into scenery
local function placeNodes(parent, scenery, zone, rng)
	local nodes = {}
	-- trees and rocks: one column of three per tier, lower tiers on the left (west)
	for skill, make in { woodcutting = makeTree, mining = makeRock } do
		local tiers = zone.res[skill]
		local c = zone.clusters and zone.clusters[skill]
		if tiers and c then
			for i, tier in tiers do
				local x = c.X + (i - (#tiers + 1) / 2) * 34
				for _, o in { Vector2.new(-8, -9), Vector2.new(8, -9), Vector2.new(0, 9) } do
					local pos = Vector3.new(x + o.X + rng:NextNumber(-2, 2), 0, c.Z + o.Y + rng:NextNumber(-2, 2))
					table.insert(nodes, make(parent, pos, tier, rng))
				end
			end
		end
	end
	local fish = zone.res.fishing
	local c = zone.clusters and zone.clusters.fishing
	if fish and c then
		local pondLen = 70 * #fish + 40
		local pond = part({
			Name = "Pond", Size = Vector3.new(pondLen, 1, 34), CFrame = CFrame.new(c.X, -0.35, c.Z),
			Color = zone.th.snow and hex("#7fb6d8") or hex("#3d8fd0"), Material = zone.th.snow and Enum.Material.Ice or Enum.Material.Glass,
			Transparency = 0.15, Reflectance = 0.1, Parent = scenery,
		})
		part({ Name = "Shore", Size = Vector3.new(pondLen + 6, 0.6, 40), CFrame = pond.CFrame * CFrame.new(0, 0.1, 0), Color = hex("#c9b27a"), Material = Enum.Material.Sand, Parent = scenery })
		local slot = pondLen / #fish
		for i, tier in fish do
			for j = 1, 2 do
				local x = c.X - pondLen / 2 + slot * (i - 1) + slot * (j - 0.5) / 2
				table.insert(nodes, makeFishSpot(parent, Vector3.new(x, 0, c.Z - 14 + rng:NextNumber(0, 4)), tier))
			end
		end
	end
	return nodes
end

-- ===================== Riverbend =====================
local function cottage(parent, pos: Vector3, facing: number, color: Color3)
	local cf = CFrame.new(pos) * CFrame.Angles(0, facing, 0)
	part({ Size = Vector3.new(16, 10, 14), CFrame = cf * CFrame.new(0, 5, 0), Color = color, Material = Enum.Material.Plaster, Parent = parent })
	local roof = Instance.new("WedgePart")
	roof.Anchored = true
	roof.Size = Vector3.new(17, 5, 7.5)
	roof.Color = hex("#8a3a2a")
	roof.Material = Enum.Material.Slate
	for _, s in { -1, 1 } do
		local w = roof:Clone()
		w.CFrame = cf * CFrame.new(0, 12.5, s * 3.75) * CFrame.Angles(0, s > 0 and math.pi or 0, 0)
		w.Parent = parent
	end
	roof:Destroy()
	part({ Size = Vector3.new(3, 6, 0.4), CFrame = cf * CFrame.new(0, 3, -7.1), Color = hex("#4a321c"), Material = Enum.Material.Wood, Parent = parent })
	for _, x in { -5, 5 } do
		part({ Size = Vector3.new(2.5, 2.5, 0.3), CFrame = cf * CFrame.new(x, 6, -7.1), Color = hex("#ffe6a0"), Material = Enum.Material.Neon, Transparency = 0.3, Parent = parent })
	end
end

local function buildTown(folder)
	local plaza = part({ Name = "Plaza", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 56, 56), CFrame = CFrame.new(0, 0.05, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = hex("#b8a888"), Material = Enum.Material.Cobblestone, Parent = folder })
	plaza.CanCollide = true
	-- fountain in the middle
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 14, 14), CFrame = CFrame.new(0, 1, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = hex("#9a9086"), Material = Enum.Material.Marble, Parent = folder })
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 12, 12), CFrame = CFrame.new(0, 1.9, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = hex("#4aa8e0"), Material = Enum.Material.Glass, Transparency = 0.2, CanCollide = false, Parent = folder })
	local spout = part({ Size = Vector3.new(1.4, 6, 1.4), CFrame = CFrame.new(0, 4, 0), Color = hex("#9a9086"), Material = Enum.Material.Marble, Parent = folder })
	local water = Instance.new("ParticleEmitter")
	water.Color = ColorSequence.new(hex("#bfe8ff"))
	water.Size = NumberSequence.new(0.4)
	water.Lifetime = NumberRange.new(0.8, 1.2)
	water.Rate = 30
	water.Speed = NumberRange.new(8, 10)
	water.SpreadAngle = Vector2.new(25, 25)
	water.Acceleration = Vector3.new(0, -30, 0)
	water.EmissionDirection = Enum.NormalId.Top
	water.Parent = spout

	-- a signpost so every direction is named
	local post = part({ Name = "Signpost", Size = Vector3.new(0.8, 9, 0.8), CFrame = CFrame.new(14, 4.5, 14), Color = hex("#5a3d22"), Material = Enum.Material.Wood, Parent = folder })
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(20, 11)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 8, 0)
	bb.MaxDistance = 90
	bb.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.BackgroundColor3 = Color3.fromRGB(24, 22, 38)
	t.BackgroundTransparency = 0.2
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.Text = "⬆️ North: Ice Mountains (45+)\n⬅️ West: Dark Forest (10+)\n➡️ East: Hometown – your house\n⬇️ South: Green Meadow (start)"
	t.Parent = bb
	local corner = Instance.new("UICorner")
	corner.Parent = t
	bb.Parent = post

	local colors = { "#e8dcc0", "#d8e4f0", "#f0d8c8", "#dcecc8" }
	local spots = { { -36, -50, 0 }, { 36, -50, 0 }, { -36, -110, math.pi / 2 }, { 36, -110, -math.pi / 2 }, { -36, 40, math.pi }, { 36, 40, math.pi } }
	for i, s in spots do
		cottage(folder, Vector3.new(s[1], 0, s[2]), s[3], hex(colors[(i - 1) % #colors + 1]))
	end

	-- the Seed Stall on the plaza: buy seeds and saplings
	local stall = Instance.new("Model")
	stall.Name = "SeedStall"
	local base = CFrame.new(-20, 0, -20) * CFrame.Angles(0, math.rad(45), 0)
	local counter = part({ Name = "Counter", Size = Vector3.new(8, 3, 3), CFrame = base * CFrame.new(0, 1.5, 0), Color = hex("#a0703a"), Material = Enum.Material.WoodPlanks, Parent = stall })
	for _, x in { -3.6, 3.6 } do
		part({ Size = Vector3.new(0.5, 8, 0.5), CFrame = base * CFrame.new(x, 4, -1.2), Color = hex("#6b4a2b"), Material = Enum.Material.Wood, Parent = stall })
	end
	for i = 0, 3 do
		part({ Size = Vector3.new(2.25, 0.3, 4), CFrame = base * CFrame.new(-3.4 + i * 2.25, 8.2, 0.4) * CFrame.Angles(math.rad(-12), 0, 0), Color = i % 2 == 0 and hex("#5ab84a") or Color3.new(1, 1, 1), Material = Enum.Material.Fabric, Parent = stall })
	end
	for i, c in { "#c8a060", "#e04a3a", "#7ac85a", "#f2d24a" } do
		part({ Shape = Enum.PartType.Ball, Size = Vector3.new(1.2, 1.2, 1.2), CFrame = base * CFrame.new(-3 + i * 1.3, 3.5, 0), Color = hex(c), Material = Enum.Material.SmoothPlastic, Parent = stall })
	end
	stall.PrimaryPart = counter
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Shop"
	prompt.ObjectText = "Seed Stall"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = counter
	prompt.Triggered:Connect(function(player)
		Remotes.OpenCraft:FireClient(player, "seeds")
	end)
	local bb = label(counter, "🌱 Seed Stall", "Seeds & saplings", 70)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 9, 0)
	stall.Parent = folder
end

-- ===================== the whole map =====================
function WorldBuilder.build()
	for _, name in { "Baseplate", "SpawnLocation", "World" } do
		local old = Workspace:FindFirstChild(name)
		while old do
			old:Destroy()
			old = Workspace:FindFirstChild(name)
		end
	end

	local world = Instance.new("Folder")
	world.Name = "World"
	local nodesFolder = Instance.new("Folder")
	nodesFolder.Name = "Nodes"
	nodesFolder.Parent = world

	local allNodes = {}
	for index, zone in Zones.LIST do
		local th = zone.th
		local folder = Instance.new("Folder")
		folder.Name = "Zone_" .. zone.id -- "Hometown" itself is the plots folder (HomeService)
		folder.Parent = world
		local rng = Random.new(1000 + index)
		local r = zone.rect
		local size = Vector3.new(r[3] - r[1], 4, r[4] - r[2])
		local center = Zones.center(zone)

		part({ Name = "Ground", Size = size, CFrame = CFrame.new(center.X, -2, center.Z), Color = hex(th.ground), Material = Enum.Material[th.material], Parent = folder })
		if th.cave then
			-- a mountain block: rock walls all round with an opening where the road comes in, and a roof
			local rock = darker(hex(th.ground), 0.75)
			part({ Name = "Ceiling", Size = size + Vector3.new(8, 4, 8), CFrame = CFrame.new(center.X, 49, center.Z), Color = rock, Material = Enum.Material.Rock, Parent = folder })
			local h = 50
			local function cliff(cf, s)
				part({ Name = "Cliff", Size = s, CFrame = cf, Color = rock, Material = Enum.Material.Rock, Parent = folder })
			end
			cliff(CFrame.new(center.X, h / 2, r[2] - 2), Vector3.new(size.X + 8, h, 6))
			cliff(CFrame.new(r[1] - 2, h / 2, center.Z), Vector3.new(6, h, size.Z))
			cliff(CFrame.new(r[3] + 2, h / 2, center.Z), Vector3.new(6, h, size.Z))
			-- south wall with a cave mouth for the road at x = -210
			local gap, gx = 30, -310
			cliff(CFrame.new((r[1] + gx - gap / 2) / 2, h / 2, r[4] + 2), Vector3.new(gx - gap / 2 - r[1], h, 6))
			cliff(CFrame.new((gx + gap / 2 + r[3]) / 2, h / 2, r[4] + 2), Vector3.new(r[3] - gx - gap / 2, h, 6))
			cliff(CFrame.new(gx, 34, r[4] + 2), Vector3.new(gap, 32, 6))
			-- break up the box: rough boulders along the outside of every wall and peaks on the roof
			local function boulder(pos, w, hh)
				part({
					Name = "Crag", Size = Vector3.new(w, hh, w * rng:NextNumber(0.7, 1.1)),
					CFrame = CFrame.new(pos + Vector3.new(0, hh / 2 - 4, 0)) * CFrame.Angles(rng:NextNumber(-0.25, 0.25), rng:NextNumber(0, 3), rng:NextNumber(-0.25, 0.25)),
					Color = rock:Lerp(Color3.fromRGB(110, 100, 120), rng:NextNumber(0, 0.4)), Material = Enum.Material.Rock, Parent = folder,
				})
			end
			for x = r[1], r[3], 26 do
				if math.abs(x - gx) > 34 then
					boulder(Vector3.new(x + rng:NextNumber(-6, 6), 0, r[4] + 8), rng:NextNumber(16, 30), rng:NextNumber(26, 62))
				end
				boulder(Vector3.new(x + rng:NextNumber(-6, 6), 0, r[2] - 8), rng:NextNumber(16, 30), rng:NextNumber(26, 62))
			end
			for zc = r[2], r[4], 26 do
				boulder(Vector3.new(r[1] - 8, 0, zc + rng:NextNumber(-6, 6)), rng:NextNumber(16, 30), rng:NextNumber(26, 62))
				boulder(Vector3.new(r[3] + 8, 0, zc + rng:NextNumber(-6, 6)), rng:NextNumber(16, 30), rng:NextNumber(26, 62))
			end
			for _ = 1, 40 do
				local p = Vector3.new(rng:NextNumber(r[1], r[3]), 51, rng:NextNumber(r[2], r[4]))
				boulder(p, rng:NextNumber(30, 70), rng:NextNumber(14, 40))
			end
			-- glowing crystal lamps hanging from the roof light the whole cave
			for lx = r[1] + 40, r[3] - 20, 70 do
				for lz = r[2] + 40, r[4] - 20, 70 do
					local lamp = part({ Name = "CaveLamp", Size = Vector3.new(2.5, 5, 2.5), CFrame = CFrame.new(lx, 44, lz) * CFrame.Angles(0, rng:NextNumber(0, 3), 0), Color = hex("#c8a0ff"), Material = Enum.Material.Neon, CanCollide = false, Parent = folder })
					local l = Instance.new("PointLight")
					l.Color = Color3.fromRGB(225, 205, 255)
					l.Range = 60
					l.Brightness = 1.6
					l.Shadows = false
					l.Parent = lamp
				end
			end
			-- a lit cave mouth
			torch(folder, Vector3.new(gx - 12, 0, r[4] + 10))
			torch(folder, Vector3.new(gx + 12, 0, r[4] + 10))
		end
		if zone.town then
			buildTown(folder)
		end

		-- scenery, kept off the roads and away from the resource clusters
		local decorFn = DECOR[th.decor]
		if decorFn then
			local decorColor = th.decor == "rock" and Color3.new(1, 1, 1) or (th.decor == "stalag" and hex(th.far) or hex(th.ground):Lerp(hex("#2f6b45"), 0.5))
			local count = math.floor(size.X * size.Z / (th.decor == "pine" and 3000 or 4500))
			local placed, tries = 0, 0
			while placed < count and tries < count * 6 do
				tries += 1
				local p = Vector3.new(rng:NextNumber(r[1] + 8, r[3] - 8), 0, rng:NextNumber(r[2] + 8, r[4] - 8))
				local clear = not nearRoad(p, 10)
				for _, c in zone.clusters or {} do
					if (Vector3.new(p.X, 0, p.Z) - c).Magnitude < 55 then
						clear = false
					end
				end
				if clear then
					decorFn(folder, p, rng, decorColor)
					placed += 1
				end
			end
		end

		-- flowers and bushes on the grass
		if th.material == "Grass" and not zone.home then -- plots have their own flower beds
			local count = math.floor(size.X * size.Z / 2200)
			for _ = 1, count do
				local p = Vector3.new(rng:NextNumber(r[1] + 6, r[3] - 6), 0, rng:NextNumber(r[2] + 6, r[4] - 6))
				if not nearRoad(p, 4) and not (zone.town and p.Magnitude < 34) then
					decorFlowers(folder, p, rng)
				end
			end
		end

		for _, n in placeNodes(nodesFolder, folder, zone, rng) do
			table.insert(allNodes, n)
		end
	end

	-- roads, and torches along them in the dark zones
	local roads = Instance.new("Folder")
	roads.Name = "Roads"
	roads.Parent = world
	for _, seg in Zones.ROADS do
		road(roads, seg[1], seg[2], hex("#8a7258"))
		local len = (seg[2] - seg[1]).Magnitude
		local dir = (seg[2] - seg[1]).Unit
		local side = Vector3.new(-dir.Z, 0, dir.X)
		for d = 15, len, 32 do
			local p = seg[1] + dir * d
			local zone = Zones.LIST[Zones.indexAt(p.X, p.Z)]
			if zone.th.cave or zone.th.lava then
				torch(roads, p + side * (RW / 2 + 1.5))
			end
		end
	end

	-- arches where the roads enter each zone
	local function zoneArch(id, pos, alongX)
		local z = Zones.byId[id]
		archGate(roads, pos, alongX, z.name, z.id == "meadow" and "Your journey begins" or z.id == "home" and "Build your house here" or ("Recommended Lv " .. z.req))
	end
	zoneArch("meadow", Vector3.new(0, 0, 59), false)
	zoneArch("forest", Vector3.new(-59, 0, 0), true)
	zoneArch("caves", Vector3.new(-310, 0, -149), false)
	zoneArch("ice", Vector3.new(0, 0, -149), false)
	zoneArch("dragon", Vector3.new(204, 0, -190), true)
	zoneArch("home", Vector3.new(59, 0, -8), true)

	-- the north gate: Wraith Caves (PvP) come later
	local b = Zones.BOUNDS
	archGate(roads, Vector3.new(0, 0, b.z0 + 8), false, "☠️ Wraith Caves", "PvP · Combat 40+ · coming soon")
	part({ Name = "WraithMist", Size = Vector3.new(30, 18, 2), CFrame = CFrame.new(0, 9, b.z0 + 3), Color = hex("#2a1a3a"), Material = Enum.Material.Neon, Transparency = 0.4, Parent = roads })

	-- invisible walls around the map
	local function wall(cf, s)
		part({ Name = "Wall", Size = s, CFrame = cf, Transparency = 1, CanCollide = true, Parent = world })
	end
	local w, d = b.x1 - b.x0, b.z1 - b.z0
	wall(CFrame.new(b.x0 + w / 2, 40, b.z0 - 1), Vector3.new(w, 90, 2))
	wall(CFrame.new(b.x0 + w / 2, 40, b.z1 + 1), Vector3.new(w, 90, 2))
	wall(CFrame.new(b.x0 - 1, 40, b.z0 + d / 2), Vector3.new(2, 90, d))
	wall(CFrame.new(b.x1 + 1, 40, b.z0 + d / 2), Vector3.new(2, 90, d))

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(Zones.SPAWN.X, 0.2, Zones.SPAWN.Z)
	spawn.Color = hex("#c9b27a")
	spawn.Material = Enum.Material.Cobblestone
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Parent = world

	world.Parent = Workspace
	return allNodes
end

return WorldBuilder
