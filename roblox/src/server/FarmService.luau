-- Farming: plant seeds in the garden patches of your plot, they grow in real time (also while you are away),
-- then harvest. Patches show their growth stage; the prompt says what to do and how long is left.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Farming = require(Shared.Farming)
local Items = require(Shared.Items)
local XP = require(Shared.XP)
local HouseGrid = require(Shared.HouseGrid)
local Remotes = require(Shared.Remotes)
local DataService = require(script.Parent.DataService)
local HomeService = require(script.Parent.HomeService)

local FarmService = {}
local rng = Random.new()
local hex = Color3.fromHex
local REACH = 14

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
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

local function key(i: number): string
	return "p" .. i -- string keys: DataStores don't like sparse number keys
end

-- ===== looks =====
local function drawPlants(soil: BasePart, kind: string, s, stage: number)
	local old = soil:FindFirstChild("Plants")
	if old then
		old:Destroy()
	end
	if stage == 0 then
		return
	end
	local f = Instance.new("Model")
	f.Name = "Plants"
	local top = soil.CFrame * CFrame.new(0, soil.Size.Y / 2, 0)
	local green = hex("#4fa83a")
	local ready = stage >= 4
	local grow = ({ 0.35, 0.6, 0.85, 1 })[stage]
	local fruit = hex(s.color)
	if kind == "tree" then
		local h = 2 + grow * 9
		part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, 0.4 + grow * 1.2, 0.4 + grow * 1.2), CFrame = top * CFrame.new(0, h / 2, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = hex("#6b4a2b"), Material = Enum.Material.Wood, Parent = f })
		local r = 2 + grow * 7
		part({ Shape = Enum.PartType.Ball, Size = Vector3.new(r, r, r), CFrame = top * CFrame.new(0, h + r * 0.25, 0), Color = ready and fruit or green, Material = Enum.Material.Grass, Parent = f })
	else
		local spots = kind == "allot" and { { -2.8, -1.6 }, { 0, -1.6 }, { 2.8, -1.6 }, { -2.8, 1.6 }, { 0, 1.6 }, { 2.8, 1.6 } } or { { -2.6, 0 }, { 0, 0.8 }, { 2.6, 0 } }
		for _, o in spots do
			local r = (kind == "herb" and 1.8 or 1.3) * grow
			local at = top * CFrame.new(o[1], r * 0.4, o[2])
			part({ Shape = Enum.PartType.Ball, Size = Vector3.new(r, r * 0.8, r), CFrame = at, Color = kind == "herb" and hex("#3f8f3a") or green, Material = Enum.Material.Grass, Parent = f })
			if ready then
				part({ Shape = Enum.PartType.Ball, Size = Vector3.new(0.9, 0.9, 0.9), CFrame = at * CFrame.new(0, r * 0.45, 0), Color = fruit, Material = Enum.Material.SmoothPlastic, Parent = f })
			end
		end
	end
	if ready then
		local glint = Instance.new("ParticleEmitter")
		glint.Color = ColorSequence.new(Color3.fromRGB(255, 240, 150))
		glint.LightEmission = 1
		glint.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.4), NumberSequenceKeypoint.new(1, 0) })
		glint.Lifetime = NumberRange.new(1, 1.6)
		glint.Rate = 5
		glint.Speed = NumberRange.new(1, 2)
		glint.SpreadAngle = Vector2.new(180, 180)
		glint.Parent = soil
		glint.Name = "Ready"
	else
		local g = soil:FindFirstChild("Ready")
		if g then
			g:Destroy()
		end
	end
	f.Parent = soil
end

-- bring one plot's patches up to date (cheap when nothing changed)
local function renderPlot(plotModel: Model, data, now: number)
	local folder = plotModel:FindFirstChild("Patches")
	if not folder then
		return
	end
	for i, def in Farming.PATCHES do
		local soil = folder:FindFirstChild("Patch_" .. i)
		if soil then
			local p = data and data.farm.patches[key(i)]
			local s = p and Farming.byId[p.seed]
			local stage = Farming.stage(p, now)
			local k = (s and s.id or "") .. stage
			if soil:GetAttribute("Key") ~= k then
				soil:SetAttribute("Key", k)
				drawPlants(soil, def.kind, s, stage)
				if stage == 0 then
					local g = soil:FindFirstChild("Ready")
					if g then
						g:Destroy()
					end
				end
			end
			local prompt = soil:FindFirstChild("PatchPrompt")
			if prompt then
				if not data then
					prompt.ActionText, prompt.ObjectText = "Look", Farming.KIND_NAME[def.kind]
				elseif not s then
					prompt.ActionText = "Plant"
					prompt.ObjectText = Farming.KIND_NAME[def.kind] .. (def.req and (" (Farming " .. def.req .. ")") or "")
				elseif stage >= 4 then
					prompt.ActionText = "Harvest"
					prompt.ObjectText = Items[s.out].name .. " – ready!"
				else
					prompt.ActionText = "Check"
					prompt.ObjectText = ("%s · %s left"):format(s.name:gsub(" Seed", ""):gsub(" Sapling", ""), Farming.fmtTime(Farming.timeLeft(p, now)))
				end
			end
		end
	end
end

function FarmService.refresh(player: Player)
	local plot = HomeService.plotOf(player)
	if plot then
		renderPlot(plot.model, DataService.get(player), os.time())
	end
end

-- ===== actions =====
local function soilOf(player: Player, i: number)
	local plot = HomeService.plotOf(player)
	local folder = plot and plot.model:FindFirstChild("Patches")
	return folder and folder:FindFirstChild("Patch_" .. i)
end

local function near(player: Player, soil: BasePart): boolean
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	return hrp ~= nil and (hrp.Position - soil.Position).Magnitude <= REACH
end

local function harvest(player: Player, data, i: number, p)
	local s = Farming.byId[p.seed]
	local n = rng:NextInteger(s.n[1], s.n[2])
	local xpEach = s.kind == "tree" and (s.hx / n) or s.hx
	local xp = math.floor(xpEach * n * HouseGrid.xpMultiplier(data.home.rooms))
	data.farm.patches[key(i)] = nil
	DataService.addItem(player, s.out, n)
	local before, after = DataService.addXp(player, "farming", xp)
	data.stats.harvested = (data.stats.harvested or 0) + 1
	DataService.sync(player)
	FarmService.refresh(player)
	Remotes.Gathered:FireClient(player, { skill = "farming", xp = xp, item = s.out, count = n, levelUp = after > before and after or nil })
	Remotes.Notify:FireClient(player, ("Harvested %d × %s!  +%d Farming XP"):format(n, Items[s.out].name, xp), "good")
end

-- the patch prompt: plant, check or harvest
function FarmService.interact(player: Player, plotModel: Model, i: number)
	if plotModel:GetAttribute("Owner") ~= player.UserId then
		Remotes.Notify:FireClient(player, "This is someone else's garden.", "warn")
		return
	end
	local data = DataService.get(player)
	local def = Farming.PATCHES[i]
	if not data or not def then
		return
	end
	local now = os.time()
	local p = data.farm.patches[key(i)]
	if p and Farming.byId[p.seed] then
		if Farming.stage(p, now) >= 4 then
			harvest(player, data, i, p)
		else
			Remotes.Notify:FireClient(player, ("%s is growing: %s left."):format(Farming.byId[p.seed].name, Farming.fmtTime(Farming.timeLeft(p, now))))
		end
		return
	end
	if def.req and XP.levelFromXp(data.skills.farming) < def.req then
		Remotes.Notify:FireClient(player, ("You need Farming level %d for the %s."):format(def.req, Farming.KIND_NAME[def.kind]:lower()), "warn")
		return
	end
	Remotes.OpenCraft:FireClient(player, "plant", i, def.kind)
end

function FarmService.plant(player: Player, i, seedId)
	local data = DataService.get(player)
	local def = type(i) == "number" and Farming.PATCHES[i]
	local s = type(seedId) == "string" and Farming.byId[seedId]
	if not data or not def or not s or s.kind ~= def.kind then
		return
	end
	local soil = soilOf(player, i)
	if not soil or not near(player, soil) then
		Remotes.Notify:FireClient(player, "Walk up to the patch first.", "warn")
		return
	end
	if data.farm.patches[key(i)] then
		return
	end
	if XP.levelFromXp(data.skills.farming) < s.lvl then
		Remotes.Notify:FireClient(player, ("You need Farming level %d to plant %s."):format(s.lvl, s.name), "warn")
		return
	end
	if (data.inv[s.id] or 0) < 1 then
		Remotes.Notify:FireClient(player, ("You have no %s."):format(s.name), "warn")
		return
	end
	DataService.addItem(player, s.id, -1)
	data.farm.patches[key(i)] = { seed = s.id, planted = os.time() }
	local xp = math.floor(s.px * HouseGrid.xpMultiplier(data.home.rooms))
	local before, after = DataService.addXp(player, "farming", xp)
	data.stats.planted = (data.stats.planted or 0) + 1
	DataService.sync(player)
	FarmService.refresh(player)
	Remotes.Gathered:FireClient(player, { skill = "farming", xp = xp, item = s.id, count = 0, levelUp = after > before and after or nil })
	Remotes.Notify:FireClient(player, ("Planted %s. Ready in %s."):format(s.name, Farming.fmtTime(s.time)), "good")
end

function FarmService.init()
	HomeService.onPatch = FarmService.interact
	DataService.onLoaded(function(player)
		task.defer(FarmService.refresh, player)
	end)
	-- grow: update every owned garden every few seconds
	task.spawn(function()
		while true do
			task.wait(3)
			for _, player in Players:GetPlayers() do
				FarmService.refresh(player)
			end
		end
	end)
end

return FarmService
