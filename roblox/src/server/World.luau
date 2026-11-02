-- Builds Millbrook, the town every new player starts in: a market square with a fountain (the spawn), a river
-- crossed by a stone bridge, Millbrook Keep on the far bank, shops, a windmill with wheat fields, the granary yard
-- where the rats live and a forest to the south. North is -Z. Everything is built from parts and terrain at start.
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")

local World = {}

local terrain = workspace.Terrain
local root: Folder

local STONE = Color3.fromRGB(150, 148, 142)
local STONE_DARK = Color3.fromRGB(112, 110, 106)
local PLASTER = Color3.fromRGB(232, 222, 196)
local TIMBER = Color3.fromRGB(92, 64, 42)
local WOOD = Color3.fromRGB(140, 100, 62)
local ROOF_RED = Color3.fromRGB(150, 70, 52)
local ROOF_SLATE = Color3.fromRGB(78, 88, 104)
local THATCH = Color3.fromRGB(196, 160, 92)

-- the rat yard in front of the granary (Combat spawns the rats here)
World.RAT_YARD = { center = Vector3.new(-112, 0, 18), size = Vector3.new(40, 0, 26) }
World.SPAWN = Vector3.new(0, 0, 16)

local function part(props: { [string]: any }, parent: Instance?): BasePart
	local class = props.Class or "Part"
	local p = Instance.new(class)
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		if k ~= "Class" then
			p[k] = v
		end
	end
	p.Parent = parent or root
	return p
end

local function model(name: string, parent: Instance?): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent or root
	return m
end

local function sign(parent: Instance, cf: CFrame, text: string, width: number?)
	local w = width or 7
	local board = part({ Name = "Sign", Size = Vector3.new(w, 1.8, 0.3), CFrame = cf, Color = TIMBER, Material = Enum.Material.Wood }, parent)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextScaled = true
	label.Font = Enum.Font.Fantasy
	label.TextColor3 = Color3.fromRGB(255, 236, 190)
	label.Parent = gui
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.12, 0)
	pad.PaddingBottom = UDim.new(0.12, 0)
	pad.Parent = label
	return board
end

-- a gable roof over a w x d footprint whose ridge runs along local X, eaves overhanging by o
local function gableRoof(parent: Instance, base: CFrame, w: number, d: number, rise: number, color: Color3, material: Enum.Material)
	local o = 1.2
	local half = d / 2 + o
	local size = Vector3.new(w + o * 2, rise, half)
	-- a wedge is high at its +Z side: the front half rises toward the ridge, the back half is turned around
	part({ Class = "WedgePart", Name = "Roof", Size = size, Color = color, Material = material,
		CFrame = base * CFrame.new(0, rise / 2, -half / 2) }, parent)
	part({ Class = "WedgePart", Name = "Roof", Size = size, Color = color, Material = material,
		CFrame = base * CFrame.new(0, rise / 2, half / 2) * CFrame.Angles(0, math.pi, 0) }, parent)
	-- gable ends
	for _, sx in { -1, 1 } do
		local gsize = Vector3.new(0.6, rise, d / 2)
		part({ Class = "WedgePart", Name = "Gable", Size = gsize, Color = PLASTER, Material = Enum.Material.Plaster,
			CFrame = base * CFrame.new(sx * (w / 2 - 0.3), rise / 2, -d / 4) }, parent)
		part({ Class = "WedgePart", Name = "Gable", Size = gsize, Color = PLASTER, Material = Enum.Material.Plaster,
			CFrame = base * CFrame.new(sx * (w / 2 - 0.3), rise / 2, d / 4) * CFrame.Angles(0, math.pi, 0) }, parent)
	end
	part({ Name = "Ridge", Size = Vector3.new(w + o * 2 + 0.4, 0.6, 0.8), Color = TIMBER, Material = Enum.Material.Wood,
		CFrame = base * CFrame.new(0, rise + 0.1, 0) }, parent)
end

-- a timber-framed house; the door is in the front wall (local -Z) and cf is the centre of the floor
local function house(name: string, cf: CFrame, w: number, d: number, h: number, opts: { [string]: any }?)
	opts = opts or {}
	local m = model(name)
	local wall = opts.wall or PLASTER
	local wallMat = opts.wallMat or Enum.Material.Plaster
	local t = 0.8
	part({ Name = "Floor", Size = Vector3.new(w, 0.6, d), CFrame = cf * CFrame.new(0, 0.3, 0), Color = WOOD, Material = Enum.Material.WoodPlanks }, m)
	-- back and side walls
	part({ Name = "Wall", Size = Vector3.new(w, h, t), CFrame = cf * CFrame.new(0, h / 2, d / 2 - t / 2), Color = wall, Material = wallMat }, m)
	for _, sx in { -1, 1 } do
		part({ Name = "Wall", Size = Vector3.new(t, h, d), CFrame = cf * CFrame.new(sx * (w / 2 - t / 2), h / 2, 0), Color = wall, Material = wallMat }, m)
		-- a window in each side wall
		part({ Name = "Window", Size = Vector3.new(t + 0.1, 2.6, 3), CFrame = cf * CFrame.new(sx * (w / 2 - t / 2), h * 0.55, 0),
			Color = Color3.fromRGB(120, 160, 190), Material = Enum.Material.Glass, Transparency = 0.35 }, m)
		part({ Name = "Shutter", Size = Vector3.new(0.3, 2.8, 1.3), CFrame = cf * CFrame.new(sx * (w / 2 + 0.15), h * 0.55, -2.2), Color = opts.trim or Color3.fromRGB(70, 100, 70), Material = Enum.Material.Wood }, m)
		part({ Name = "Shutter", Size = Vector3.new(0.3, 2.8, 1.3), CFrame = cf * CFrame.new(sx * (w / 2 + 0.15), h * 0.55, 2.2), Color = opts.trim or Color3.fromRGB(70, 100, 70), Material = Enum.Material.Wood }, m)
	end
	-- front wall with a door gap of 5
	local door = 5
	local side = (w - door) / 2
	for _, sx in { -1, 1 } do
		part({ Name = "Wall", Size = Vector3.new(side, h, t), CFrame = cf * CFrame.new(sx * (door / 2 + side / 2), h / 2, -d / 2 + t / 2), Color = wall, Material = wallMat }, m)
		if side > 6 then
			part({ Name = "Window", Size = Vector3.new(3, 2.6, t + 0.1), CFrame = cf * CFrame.new(sx * (door / 2 + side / 2), h * 0.55, -d / 2 + t / 2),
				Color = Color3.fromRGB(120, 160, 190), Material = Enum.Material.Glass, Transparency = 0.35 }, m)
		end
	end
	part({ Name = "Lintel", Size = Vector3.new(door, h - 7.5, t), CFrame = cf * CFrame.new(0, 7.5 + (h - 7.5) / 2, -d / 2 + t / 2), Color = wall, Material = wallMat }, m)
	-- timber frame: corner posts and a beam under the roof
	if wallMat == Enum.Material.Plaster then
		for _, sx in { -1, 1 } do
			for _, sz in { -1, 1 } do
				part({ Name = "Post", Size = Vector3.new(1, h, 1), CFrame = cf * CFrame.new(sx * (w / 2 - 0.4), h / 2, sz * (d / 2 - 0.4)), Color = TIMBER, Material = Enum.Material.Wood }, m)
			end
		end
		part({ Name = "Beam", Size = Vector3.new(w + 0.2, 0.8, 1), CFrame = cf * CFrame.new(0, h - 0.4, -d / 2 + 0.4), Color = TIMBER, Material = Enum.Material.Wood }, m)
		part({ Name = "Beam", Size = Vector3.new(w + 0.2, 0.8, 1), CFrame = cf * CFrame.new(0, h - 0.4, d / 2 - 0.4), Color = TIMBER, Material = Enum.Material.Wood }, m)
		part({ Name = "Beam", Size = Vector3.new(door + 1.6, 0.8, 1.1), CFrame = cf * CFrame.new(0, 7.6, -d / 2 + 0.4), Color = TIMBER, Material = Enum.Material.Wood }, m)
	end
	-- ceiling, so the roof reads from inside too
	part({ Name = "Ceiling", Size = Vector3.new(w, 0.4, d), CFrame = cf * CFrame.new(0, h + 0.2, 0), Color = WOOD, Material = Enum.Material.WoodPlanks }, m)
	gableRoof(m, cf * CFrame.new(0, h + 0.4, 0), w, d, opts.rise or d * 0.45, opts.roof or ROOF_RED, opts.roofMat or Enum.Material.Slate)
	if opts.chimney then
		part({ Name = "Chimney", Size = Vector3.new(2.4, opts.rise or d * 0.45 + 5, 2.4), CFrame = cf * CFrame.new(w / 2 - 3, h + (opts.rise or d * 0.45) / 2 + 2.5, d / 4), Color = STONE_DARK, Material = Enum.Material.Brick }, m)
	end
	if opts.sign then
		sign(m, cf * CFrame.new(0, 9.4, -d / 2 - 0.3) * CFrame.Angles(0, math.pi, 0), opts.sign, math.min(w - 2, 11))
	end
	return m
end

local function tree(pos: Vector3, rng: Random)
	local m = model("Tree")
	local h = rng:NextNumber(9, 14)
	local trunk = rng:NextNumber(1.4, 2)
	part({ Class = "Part", Shape = Enum.PartType.Cylinder, Name = "Trunk", Size = Vector3.new(h, trunk, trunk),
		CFrame = CFrame.new(pos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color = Color3.fromRGB(105, 74, 50), Material = Enum.Material.Wood }, m)
	local green = Color3.fromHSV(rng:NextNumber(0.24, 0.32), rng:NextNumber(0.5, 0.7), rng:NextNumber(0.42, 0.58))
	for i = 1, 4 do
		local r = rng:NextNumber(5.5, 8)
		local off = i == 1 and Vector3.zero or Vector3.new(rng:NextNumber(-3, 3), rng:NextNumber(-1.5, 2), rng:NextNumber(-3, 3))
		part({ Shape = Enum.PartType.Ball, Name = "Leaves", Size = Vector3.new(r, r, r), CFrame = CFrame.new(pos + Vector3.new(0, h + 1, 0) + off),
			Color = green:Lerp(Color3.new(0.1, 0.25, 0.05), rng:NextNumber(0, 0.3)), Material = Enum.Material.Grass }, m)
	end
	return m
end

local function lamp(pos: Vector3)
	local m = model("Lamp")
	part({ Name = "Post", Size = Vector3.new(0.6, 9, 0.6), CFrame = CFrame.new(pos + Vector3.new(0, 4.5, 0)), Color = Color3.fromRGB(40, 40, 44), Material = Enum.Material.Metal }, m)
	local lantern = part({ Name = "Lantern", Size = Vector3.new(1.2, 1.4, 1.2), CFrame = CFrame.new(pos + Vector3.new(0, 9.5, 0)), Color = Color3.fromRGB(255, 214, 140), Material = Enum.Material.Neon }, m)
	part({ Name = "Cap", Size = Vector3.new(1.8, 0.4, 1.8), CFrame = CFrame.new(pos + Vector3.new(0, 10.4, 0)), Color = Color3.fromRGB(40, 40, 44), Material = Enum.Material.Metal }, m)
	local light = Instance.new("PointLight")
	light.Range = 18
	light.Brightness = 1.2
	light.Color = Color3.fromRGB(255, 210, 150)
	light.Parent = lantern
end

local function fence(a: Vector3, b: Vector3, parent: Instance?)
	local m = parent or model("Fence")
	local len = (b - a).Magnitude
	local dir = (b - a).Unit
	local cf = CFrame.lookAt(a, b)
	local posts = math.max(1, math.floor(len / 6))
	for i = 0, posts do
		local p = a + dir * (len * i / posts)
		part({ Name = "Post", Size = Vector3.new(0.6, 3.6, 0.6), CFrame = CFrame.new(p + Vector3.new(0, 1.8, 0)), Color = WOOD, Material = Enum.Material.Wood }, m)
	end
	for _, y in { 1.3, 2.7 } do
		part({ Name = "Rail", Size = Vector3.new(0.3, 0.4, len), CFrame = cf * CFrame.new(0, y, -len / 2), Color = WOOD, Material = Enum.Material.Wood }, m)
	end
	return m
end

-- smooth terrain draws a full voxel's surface 2 studs above the block's top, so every fill is lowered by 2 to
-- put the ground's surface at y = 0
local SINK = Vector3.new(0, 2, 0)
local function fill(cf: CFrame, size: Vector3, material: Enum.Material)
	terrain:FillBlock(cf - SINK, size, material)
end

local function ground()
	terrain:Clear()
	fill(CFrame.new(0, -8, 0), Vector3.new(1100, 16, 1100), Enum.Material.Grass)
	-- river from west to east, with sandy banks
	fill(CFrame.new(0, -2, -60), Vector3.new(1100, 4, 32), Enum.Material.Sand)
	fill(CFrame.new(0, -6, -60), Vector3.new(1100, 12, 24), Enum.Material.Air)
	fill(CFrame.new(0, -13, -60), Vector3.new(1100, 2, 24), Enum.Material.Mud)
	fill(CFrame.new(0, -5.5, -60), Vector3.new(1100, 13, 24), Enum.Material.Water)
	-- rolling hills close the valley in on every side but the river's
	local rng = Random.new(3)
	for i = 0, 35 do
		local a = i / 36 * math.pi * 2
		local r = rng:NextNumber(300, 360)
		local p = Vector3.new(math.cos(a) * r, rng:NextNumber(-30, -10), math.sin(a) * r)
		if math.abs(p.Z + 60) > 70 then
			terrain:FillBall(p, rng:NextNumber(45, 75), Enum.Material.Grass)
		end
	end
	-- cobbled square and roads
	fill(CFrame.new(0, -2, 0), Vector3.new(52, 4, 52), Enum.Material.Cobblestone)
	fill(CFrame.new(0, -2, 140), Vector3.new(10, 4, 260), Enum.Material.Cobblestone) -- south road
	fill(CFrame.new(0, -2, -32), Vector3.new(10, 4, 28), Enum.Material.Cobblestone) -- to the bridge
	fill(CFrame.new(0, -2, -88), Vector3.new(10, 4, 24), Enum.Material.Cobblestone) -- bridge to keep
	fill(CFrame.new(0, -2, -140), Vector3.new(92, 4, 72), Enum.Material.Cobblestone) -- keep courtyard
	fill(CFrame.new(140, -2, 0), Vector3.new(260, 4, 10), Enum.Material.Cobblestone) -- east road
	fill(CFrame.new(-140, -2, 0), Vector3.new(260, 4, 10), Enum.Material.Cobblestone) -- west road
	-- dirt tracks to the granary and the windmill
	fill(CFrame.new(-112, -2, 12), Vector3.new(8, 4, 24), Enum.Material.Ground)
	fill(CFrame.new(108, -2, 18), Vector3.new(8, 4, 36), Enum.Material.Ground)
	fill(CFrame.new(World.RAT_YARD.center + Vector3.new(0, -2, 0)),World.RAT_YARD.size + Vector3.new(0, 4, 0), Enum.Material.Ground)
end

local function bridge()
	local m = model("Bridge")
	local len, w = 40, 14
	local cf = CFrame.new(0, 0, -60)
	part({ Name = "Deck", Size = Vector3.new(w, 1.4, len), CFrame = cf * CFrame.new(0, 0.2, 0), Color = STONE, Material = Enum.Material.Cobblestone }, m)
	for _, sx in { -1, 1 } do
		part({ Name = "Parapet", Size = Vector3.new(1.4, 3, len), CFrame = cf * CFrame.new(sx * (w / 2 - 0.7), 2.2, 0), Color = STONE_DARK, Material = Enum.Material.Cobblestone }, m)
		for _, z in { -len / 2, len / 2 } do
			part({ Name = "Pillar", Size = Vector3.new(2, 4.4, 2), CFrame = cf * CFrame.new(sx * (w / 2 - 0.7), 2.4, z), Color = STONE_DARK, Material = Enum.Material.Cobblestone }, m)
		end
	end
	for _, z in { -6, 6 } do
		part({ Name = "Pier", Size = Vector3.new(w - 2, 12, 4), CFrame = cf * CFrame.new(0, -6, z), Color = STONE_DARK, Material = Enum.Material.Cobblestone }, m)
	end
end

local function battlements(m: Instance, cf: CFrame, len: number, y: number)
	local n = math.floor(len / 4)
	for i = 0, n - 1 do
		part({ Name = "Merlon", Size = Vector3.new(2, 2.4, 1.6), CFrame = cf * CFrame.new(-len / 2 + 2 + i * 4, y + 1.2, 0), Color = STONE, Material = Enum.Material.Cobblestone }, m)
	end
end

local function tower(m: Instance, pos: Vector3, r: number, h: number, flag: Color3?)
	part({ Shape = Enum.PartType.Cylinder, Name = "Tower", Size = Vector3.new(h, r * 2, r * 2),
		CFrame = CFrame.new(pos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color = STONE, Material = Enum.Material.Cobblestone }, m)
	part({ Shape = Enum.PartType.Cylinder, Name = "TowerTop", Size = Vector3.new(1.2, r * 2 + 1.6, r * 2 + 1.6),
		CFrame = CFrame.new(pos + Vector3.new(0, h + 0.6, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color = STONE_DARK, Material = Enum.Material.Cobblestone }, m)
	for i = 0, 9 do
		local a = i / 10 * math.pi * 2
		part({ Name = "Merlon", Size = Vector3.new(2, 2.4, 1.4),
			CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * (r + 0.4), h + 2.4, math.sin(a) * (r + 0.4))) * CFrame.Angles(0, -a + math.pi / 2, 0), Color = STONE, Material = Enum.Material.Cobblestone }, m)
	end
	for i = 0, 2 do
		local a = i / 3 * math.pi * 2 + 0.5
		part({ Name = "Slit", Size = Vector3.new(0.8, 3, 0.4), CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * r, h * 0.6, math.sin(a) * r)) * CFrame.Angles(0, -a + math.pi / 2, 0),
			Color = Color3.fromRGB(30, 30, 34) }, m)
	end
	if flag then
		part({ Name = "Pole", Size = Vector3.new(0.4, 8, 0.4), CFrame = CFrame.new(pos + Vector3.new(0, h + 5, 0)), Color = Color3.fromRGB(60, 50, 40), Material = Enum.Material.Wood }, m)
		part({ Name = "Banner", Size = Vector3.new(0.15, 2.6, 4), CFrame = CFrame.new(pos + Vector3.new(0, h + 7.4, 2.1)), Color = flag, Material = Enum.Material.Fabric }, m)
	end
end

local function keep()
	local m = model("Millbrook Keep")
	local c = Vector3.new(0, 0, -140)
	local W, D, H, T = 100, 80, 18, 4
	local north, south = c.Z - D / 2, c.Z + D / 2
	local banner = Color3.fromRGB(40, 80, 150)
	-- curtain walls (the south one has the gate)
	part({ Name = "Wall", Size = Vector3.new(W, H, T), CFrame = CFrame.new(c.X, H / 2, north), Color = STONE, Material = Enum.Material.Cobblestone }, m)
	battlements(m, CFrame.new(c.X, 0, north - T / 2 + 0.8), W, H)
	for _, sx in { -1, 1 } do
		part({ Name = "Wall", Size = Vector3.new(T, H, D), CFrame = CFrame.new(c.X + sx * W / 2, H / 2, c.Z), Color = STONE, Material = Enum.Material.Cobblestone }, m)
		battlements(m, CFrame.new(c.X + sx * (W / 2 + T / 2 - 0.8), 0, c.Z) * CFrame.Angles(0, math.pi / 2, 0), D, H)
		local seg = (W - 16) / 2
		part({ Name = "Wall", Size = Vector3.new(seg, H, T), CFrame = CFrame.new(c.X + sx * (8 + seg / 2), H / 2, south), Color = STONE, Material = Enum.Material.Cobblestone }, m)
		battlements(m, CFrame.new(c.X + sx * (8 + seg / 2), 0, south + T / 2 - 0.8), seg, H)
		-- gatehouse towers
		tower(m, Vector3.new(c.X + sx * 10, 0, south), 5, H + 6, nil)
		for _, sz in { -1, 1 } do
			tower(m, Vector3.new(c.X + sx * W / 2, 0, c.Z + sz * D / 2), 7, H + 10, banner)
		end
	end
	part({ Name = "Gate", Size = Vector3.new(16, H - 11, T + 2), CFrame = CFrame.new(c.X, 11 + (H - 11) / 2, south), Color = STONE_DARK, Material = Enum.Material.Cobblestone }, m)
	-- the portcullis is raised: only its bottom shows under the arch
	for i = -3, 3 do
		part({ Name = "Bar", Size = Vector3.new(0.4, 2, 0.4), CFrame = CFrame.new(c.X + i * 2, 10, south), Color = Color3.fromRGB(50, 50, 54), Material = Enum.Material.Metal }, m)
	end
	sign(m, CFrame.new(c.X, 14.5, south + T / 2 + 1.2), "Millbrook Keep", 12)
	-- the keep itself
	local kw, kd, kh = 40, 28, 28
	local kc = Vector3.new(c.X, 0, c.Z - 8)
	part({ Name = "KeepHall", Size = Vector3.new(kw, kh, kd), CFrame = CFrame.new(kc + Vector3.new(0, kh / 2, 0)), Color = STONE, Material = Enum.Material.Cobblestone }, m)
	battlements(m, CFrame.new(kc + Vector3.new(0, 0, kd / 2 - 0.8)), kw, kh)
	battlements(m, CFrame.new(kc + Vector3.new(0, 0, -kd / 2 + 0.8)), kw, kh)
	for _, sx in { -1, 1 } do
		battlements(m, CFrame.new(kc + Vector3.new(sx * (kw / 2 - 0.8), 0, 0)) * CFrame.Angles(0, math.pi / 2, 0), kd, kh)
		tower(m, kc + Vector3.new(sx * kw / 2, 0, kd / 2), 5, kh + 8, banner)
		for _, y in { 10, 19 } do
			for _, x in { 8, 15 } do
				part({ Name = "Window", Size = Vector3.new(1.6, 3.4, 0.4), CFrame = CFrame.new(kc + Vector3.new(sx * x, y, kd / 2 + 0.1)), Color = Color3.fromRGB(40, 36, 30) }, m)
			end
		end
	end
	part({ Name = "Door", Size = Vector3.new(6, 9, 0.6), CFrame = CFrame.new(kc + Vector3.new(0, 4.5, kd / 2 + 0.2)), Color = TIMBER, Material = Enum.Material.WoodPlanks }, m)
	part({ Name = "Steps", Size = Vector3.new(10, 0.8, 4), CFrame = CFrame.new(kc + Vector3.new(0, 0.4, kd / 2 + 2)), Color = STONE_DARK, Material = Enum.Material.Cobblestone }, m)
	for _, sx in { -1, 1 } do
		part({ Name = "Banner", Size = Vector3.new(3, 8, 0.2), CFrame = CFrame.new(kc + Vector3.new(sx * 5, 13, kd / 2 + 0.15)), Color = banner, Material = Enum.Material.Fabric }, m)
	end
end

local function fountain()
	local m = model("Fountain")
	part({ Shape = Enum.PartType.Cylinder, Name = "Basin", Size = Vector3.new(2, 14, 14), CFrame = CFrame.new(0, 1, 0) * CFrame.Angles(0, 0, math.pi / 2), Color = STONE, Material = Enum.Material.Cobblestone }, m)
	part({ Shape = Enum.PartType.Cylinder, Name = "Water", Size = Vector3.new(0.4, 12.4, 12.4), CFrame = CFrame.new(0, 1.9, 0) * CFrame.Angles(0, 0, math.pi / 2),
		Color = Color3.fromRGB(70, 140, 190), Material = Enum.Material.Glass, Transparency = 0.25, CanCollide = false }, m)
	part({ Shape = Enum.PartType.Cylinder, Name = "Column", Size = Vector3.new(5, 1.6, 1.6), CFrame = CFrame.new(0, 3.5, 0) * CFrame.Angles(0, 0, math.pi / 2), Color = STONE, Material = Enum.Material.Marble }, m)
	part({ Shape = Enum.PartType.Cylinder, Name = "Bowl", Size = Vector3.new(0.8, 5, 5), CFrame = CFrame.new(0, 6.2, 0) * CFrame.Angles(0, 0, math.pi / 2), Color = STONE, Material = Enum.Material.Marble }, m)
	local spout = part({ Name = "Spout", Size = Vector3.new(0.5, 0.5, 0.5), CFrame = CFrame.new(0, 7, 0), Transparency = 1, CanCollide = false }, m)
	local spray = Instance.new("ParticleEmitter")
	spray.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	spray.Color = ColorSequence.new(Color3.fromRGB(200, 230, 255))
	spray.Size = NumberSequence.new(0.35, 0.1)
	spray.Transparency = NumberSequence.new(0.2, 1)
	spray.Lifetime = NumberRange.new(0.8, 1.1)
	spray.Rate = 40
	spray.Speed = NumberRange.new(6, 8)
	spray.SpreadAngle = Vector2.new(25, 25)
	spray.Acceleration = Vector3.new(0, -22, 0)
	spray.Parent = spout
end

local function smithy()
	local cf = CFrame.new(-40, 0, -22) * CFrame.Angles(0, -math.pi / 2 - 0.5, 0)
	local m = house("Smithy", cf, 18, 14, 10, { wall = STONE, wallMat = Enum.Material.Cobblestone, roof = ROOF_SLATE, chimney = true, sign = "Smithy" })
	part({ Name = "Furnace", Size = Vector3.new(4, 5, 3), CFrame = cf * CFrame.new(-5, 2.5, 4.5), Color = STONE_DARK, Material = Enum.Material.Brick }, m)
	local glow = part({ Name = "Fire", Size = Vector3.new(2.4, 1.6, 0.3), CFrame = cf * CFrame.new(-5, 1.6, 2.95), Color = Color3.fromRGB(255, 120, 40), Material = Enum.Material.Neon }, m)
	local fire = Instance.new("PointLight")
	fire.Color = Color3.fromRGB(255, 140, 60)
	fire.Range = 14
	fire.Parent = glow
	part({ Name = "AnvilBase", Size = Vector3.new(1.2, 1.6, 1.2), CFrame = cf * CFrame.new(3, 1.4, 1), Color = Color3.fromRGB(60, 60, 64), Material = Enum.Material.Metal }, m)
	part({ Name = "Anvil", Size = Vector3.new(2.8, 0.9, 1.2), CFrame = cf * CFrame.new(3, 2.6, 1), Color = Color3.fromRGB(70, 70, 76), Material = Enum.Material.Metal }, m)
end

local function store()
	local cf = CFrame.new(40, 0, -22) * CFrame.Angles(0, math.pi / 2 + 0.5, 0)
	local m = house("General Store", cf, 20, 14, 11, { chimney = false, sign = "General Store", trim = Color3.fromRGB(150, 60, 50) })
	part({ Name = "Counter", Size = Vector3.new(10, 3.4, 1.6), CFrame = cf * CFrame.new(0, 2.3, 2.5), Color = WOOD, Material = Enum.Material.WoodPlanks }, m)
	for i = -1, 1 do
		part({ Name = "Barrel", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 2.4, 2.4), CFrame = cf * CFrame.new(i * 3.2, 1.5, 5.6) * CFrame.Angles(0, 0, math.pi / 2), Color = WOOD, Material = Enum.Material.Wood }, m)
	end
	-- an awning over the door
	part({ Name = "Awning", Size = Vector3.new(9, 0.3, 3.4), CFrame = cf * CFrame.new(0, 8.8, -8.4) * CFrame.Angles(math.rad(-18), 0, 0), Color = Color3.fromRGB(170, 60, 50), Material = Enum.Material.Fabric }, m)
end

local function inn()
	local cf = CFrame.new(42, 0, 30) * CFrame.Angles(0, math.pi / 2 - 0.4, 0)
	local m = house("The Sleepy Ox Inn", cf, 24, 16, 15, { chimney = true, sign = "The Sleepy Ox", roof = Color3.fromRGB(120, 72, 48), trim = Color3.fromRGB(60, 80, 120) })
	for _, x in { -6, 6 } do
		part({ Name = "Table", Size = Vector3.new(4, 0.4, 3), CFrame = cf * CFrame.new(x, 3, 3), Color = WOOD, Material = Enum.Material.WoodPlanks }, m)
		part({ Name = "Leg", Size = Vector3.new(0.6, 2.6, 0.6), CFrame = cf * CFrame.new(x, 1.6, 3), Color = TIMBER, Material = Enum.Material.Wood }, m)
	end
end

local function cottages()
	house("Cottage", CFrame.new(-42, 0, 32) * CFrame.Angles(0, -math.pi / 2 + 0.4, 0), 16, 12, 9, { roof = THATCH, roofMat = Enum.Material.Grass, chimney = true })
	house("Cottage", CFrame.new(-28, 0, 62) * CFrame.Angles(0, -math.pi / 2 + 0.1, 0), 14, 12, 9, { roof = ROOF_RED, chimney = true })
	house("Cottage", CFrame.new(28, 0, 66) * CFrame.Angles(0, math.pi / 2 - 0.1, 0), 14, 12, 9, { roof = THATCH, roofMat = Enum.Material.Grass })
	house("Cottage", CFrame.new(-70, 0, -24) * CFrame.Angles(0, 0, 0), 14, 12, 9, { roof = ROOF_SLATE })
	house("Cottage", CFrame.new(70, 0, -26) * CFrame.Angles(0, 0, 0), 14, 12, 9, { roof = ROOF_RED, chimney = true })
end

local function granary()
	local yard = World.RAT_YARD
	local cf = CFrame.new(yard.center.X, 0, yard.center.Z - yard.size.Z / 2 - 11)
	local m = house("Granary", cf * CFrame.Angles(0, math.pi, 0), 26, 18, 13, { wall = Color3.fromRGB(150, 60, 48), wallMat = Enum.Material.WoodPlanks, roof = Color3.fromRGB(70, 60, 56), sign = "Granary" })
	for i = 1, 6 do
		part({ Name = "Sack", Size = Vector3.new(1.6, 2, 1.2), CFrame = cf * CFrame.new(-8 + i * 2.2, 1.6, -6) * CFrame.Angles(0, i, 0.1), Color = Color3.fromRGB(200, 180, 130), Material = Enum.Material.Fabric }, m)
	end
	-- the yard fence, open toward the road
	local c, s = yard.center, yard.size
	local x0, x1, z0, z1 = c.X - s.X / 2, c.X + s.X / 2, c.Z - s.Z / 2, c.Z + s.Z / 2
	local f = model("Rat Yard Fence")
	fence(Vector3.new(x0, 0, z0), Vector3.new(x0, 0, z1), f)
	fence(Vector3.new(x1, 0, z0), Vector3.new(x1, 0, z1), f)
	fence(Vector3.new(x0, 0, z1), Vector3.new(c.X - 4, 0, z1), f)
	fence(Vector3.new(c.X + 4, 0, z1), Vector3.new(x1, 0, z1), f)
	for i = 1, 5 do
		part({ Name = "Crate", Size = Vector3.new(3, 3, 3), CFrame = CFrame.new(x0 + 4 + (i % 2) * 2, 1.5 + (i > 3 and 3 or 0), z0 + 3 + i), Color = WOOD, Material = Enum.Material.WoodPlanks }, f)
	end
	part({ Name = "Hay", Size = Vector3.new(4, 3, 6), CFrame = CFrame.new(x1 - 4, 1.5, z0 + 6), Color = THATCH, Material = Enum.Material.Grass }, f)
	sign(f, CFrame.new(c.X, 4.6, z1 + 0.6) * CFrame.Angles(0, 0, 0), "Beware of rats", 8)
	part({ Name = "SignPost", Size = Vector3.new(0.5, 4, 0.5), CFrame = CFrame.new(c.X, 2, z1 + 0.9), Color = WOOD, Material = Enum.Material.Wood }, f)
end

local function windmill()
	local m = model("Windmill")
	local base = Vector3.new(108, 0, 44)
	for i, s in { { 12, 7 }, { 11, 6.2 }, { 10, 5.4 } } do
		local h = 8
		part({ Shape = Enum.PartType.Cylinder, Name = "Tower", Size = Vector3.new(h, s[1], s[1]),
			CFrame = CFrame.new(base + Vector3.new(0, (i - 1) * h + h / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), Color = PLASTER, Material = Enum.Material.Plaster }, m)
	end
	part({ Shape = Enum.PartType.Ball, Name = "Cap", Size = Vector3.new(11, 9, 11), CFrame = CFrame.new(base + Vector3.new(0, 24.5, 0)), Color = ROOF_RED, Material = Enum.Material.Slate }, m)
	part({ Name = "Door", Size = Vector3.new(4, 7, 1), CFrame = CFrame.new(base + Vector3.new(0, 3.5, -5.8)), Color = TIMBER, Material = Enum.Material.WoodPlanks }, m)
	-- the sails turn on the clients (tag "Sails", pivot at the hub)
	local sails = model("Sails", m)
	local hub = base + Vector3.new(0, 22, -6.6)
	local hubPart = part({ Shape = Enum.PartType.Cylinder, Name = "Hub", Size = Vector3.new(1.6, 2, 2), CFrame = CFrame.new(hub) * CFrame.Angles(0, math.pi / 2, 0), Color = TIMBER, Material = Enum.Material.Wood }, sails)
	sails.PrimaryPart = hubPart
	for i = 0, 3 do
		local arm = CFrame.new(hub) * CFrame.Angles(0, 0, i * math.pi / 2)
		part({ Name = "Arm", Size = Vector3.new(0.8, 15, 0.5), CFrame = arm * CFrame.new(0, 8, -0.3), Color = TIMBER, Material = Enum.Material.Wood }, sails)
		part({ Name = "Cloth", Size = Vector3.new(3.6, 11, 0.2), CFrame = arm * CFrame.new(2.2, 9.5, -0.3), Color = Color3.fromRGB(236, 230, 214), Material = Enum.Material.Fabric }, sails)
	end
	CollectionService:AddTag(sails, "Sails")
	-- wheat fields on both sides
	local f = model("Wheat Field")
	for _, fx in { 84, 132 } do
		for row = 0, 7 do
			part({ Name = "Wheat", Size = Vector3.new(16, 1.8, 1.4), CFrame = CFrame.new(fx, 0.9, 30 + row * 4), Color = Color3.fromRGB(222, 190, 96), Material = Enum.Material.Grass }, f)
		end
		fence(Vector3.new(fx - 9, 0, 27), Vector3.new(fx + 9, 0, 27), f)
		fence(Vector3.new(fx - 9, 0, 61), Vector3.new(fx + 9, 0, 61), f)
	end
end

local function forest()
	local rng = Random.new(7)
	-- keep trees off the roads, the river and the buildings
	local function clear(p: Vector3): boolean
		if math.abs(p.X) < 12 or math.abs(p.Z) < 12 then
			return false
		end
		if p.Z > -82 and p.Z < -38 then
			return false
		end
		if p.Z < -82 and math.abs(p.X) < 64 and p.Z > -190 then
			return false
		end
		if p.Magnitude < 85 then
			return false
		end
		if (p - Vector3.new(108, 0, 44)).Magnitude < 40 then
			return false
		end
		if (p - World.RAT_YARD.center).Magnitude < 40 then
			return false
		end
		return true
	end
	local placed = 0
	for _ = 1, 600 do
		if placed >= 110 then
			break
		end
		local p = Vector3.new(rng:NextNumber(-300, 300), 0, rng:NextNumber(-300, 300))
		-- denser forest to the south
		if p.Z < 80 and rng:NextNumber() < 0.55 then
			continue
		end
		if clear(p) then
			tree(p, rng)
			placed += 1
		end
	end
end

local function lamps()
	for _, z in { 30, 60, 90, 120 } do
		lamp(Vector3.new(7, 0, z))
	end
	for _, x in { -30, 30, -60, 60 } do
		lamp(Vector3.new(x, 0, 7))
	end
	lamp(Vector3.new(7, 0, -30))
	lamp(Vector3.new(-7, 0, -30))
end

function World.build()
	for _, name in { "Baseplate", "SpawnLocation" } do
		local old = workspace:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
	root = Instance.new("Folder")
	root.Name = "Millbrook"
	root.Parent = workspace

	ground()
	bridge()
	keep()
	fountain()
	smithy()
	store()
	inn()
	cottages()
	granary()
	windmill()
	forest()
	lamps()

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(6, 0.4, 6)
	spawn.CFrame = CFrame.new(World.SPAWN + Vector3.new(0, 0.2, 0))
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = root

	Lighting.ClockTime = 14.5
	Lighting.Brightness = 2.2
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 150)
	local air = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
	air.Density = 0.32
	air.Offset = 0.1
	air.Haze = 1.2
	air.Color = Color3.fromRGB(200, 214, 230)
	air.Decay = Color3.fromRGB(120, 140, 170)
end

return World
