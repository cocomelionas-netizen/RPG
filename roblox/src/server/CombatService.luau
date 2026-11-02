-- Combat: monster camps in every zone and PvP in the Wraith Caves.
-- No buttons: walk up to a monster (or tap it) and the hero draws their sword and fights on their own until one side
-- falls or the hero walks away. Monsters wander about their camp and come for heroes who get close, unless the hero
-- is more than twice their level (as in OSRS). Food is eaten automatically when health runs low.
-- The server moves an invisible Root box; every client animates the monster's model after it (MobAnim.luau).
--
-- Wraith Caves rules (DESIGN.md): gold and items won in there are "cave loot", carried separately. Walk out and
-- it goes to your bag. Die and you lose only the cave loot: a player who killed you takes it.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Combat = require(Shared.Combat)
local Items = require(Shared.Items)
local XP = require(Shared.XP)
local Zones = require(Shared.Zones)
local HouseGrid = require(Shared.HouseGrid)
local Remotes = require(Shared.Remotes)
local DataService = require(script.Parent.DataService)
local GatherService = require(script.Parent.GatherService)

local CombatService = {}
local monsterStep, autoFight -- moving about (defined with the enemy models)

local hex = Color3.fromHex
local rng = Random.new()
local enemies = {} -- array of enemy state { def, model, root, hp, alive, home, attackers = {[Player]=true}, target }
local fights = {} -- [Player] = { token, kind = "enemy" | "player", enemy, victim }
local lastHurt = {} -- [Player] = os.clock() of the last damage taken (no regen in combat)
local lastPvpBy = {} -- [Player] = { by = Player, at = os.clock() }
local inWild = {} -- [Player] = true while inside the Wraith Caves
local noAutoUntil = {} -- [Player] = os.clock(): no auto-fighting right after the player stopped a fight

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

local function humanoidOf(player: Player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health > 0 then
		return hum, char:FindFirstChild("HumanoidRootPart")
	end
	return nil
end

local function flat(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function isWild(pos: Vector3): boolean
	return Zones.contains(Zones.byId.wild, pos.X, pos.Z)
end

-- ===================== hitpoints =====================
function CombatService.applyMaxHp(player: Player)
	local data = DataService.get(player)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if data and hum then
		local max = Combat.maxHp(data.skills)
		if hum.MaxHealth ~= max then
			local frac = hum.MaxHealth > 0 and hum.Health / hum.MaxHealth or 1
			hum.MaxHealth = max
			hum.Health = math.max(1, max * frac)
		end
	end
end

-- eat the best food in the bag when health falls under 40%
local function autoEat(player: Player, hum: Humanoid)
	if hum.Health > hum.MaxHealth * 0.4 then
		return
	end
	local data = DataService.get(player)
	if not data then
		return
	end
	local best, heal = nil, 0
	for id, n in data.inv do
		local it = Items[id]
		if n > 0 and it and it.heal and it.heal > heal then
			best, heal = id, it.heal
		end
	end
	if best then
		DataService.addItem(player, best, -1)
		hum.Health = math.min(hum.MaxHealth, hum.Health + heal)
		DataService.sync(player)
		Remotes.Notify:FireClient(player, ("Ate %s  +%d HP"):format(Items[best].name, heal), "good")
	end
end

local function splat(target: BasePart, dmg: number, kind: string)
	Remotes.HitSplat:FireAllClients(target, dmg, kind)
end

local function hurtPlayer(player: Player, dmg: number, by: Player?)
	local hum = humanoidOf(player)
	if not hum then
		return
	end
	lastHurt[player] = os.clock()
	if by then
		lastPvpBy[player] = { by = by, at = os.clock() }
	end
	hum:TakeDamage(dmg)
	if hum.Health > 0 then
		autoEat(player, hum)
	end
end

-- ===================== loot =====================
local function caveLoot(data)
	data.caveLoot = data.caveLoot or { gold = 0, items = {} }
	return data.caveLoot
end

local function giveLoot(player: Player, gold: number, items)
	local data = DataService.get(player)
	if not data then
		return
	end
	if inWild[player] then
		local cl = caveLoot(data)
		cl.gold += gold
		for id, n in items do
			cl.items[id] = (cl.items[id] or 0) + n
		end
	else
		DataService.addGold(player, gold)
		for id, n in items do
			DataService.addItem(player, id, n)
		end
	end
end

local function bankCaveLoot(player: Player)
	local data = DataService.get(player)
	local cl = data and data.caveLoot
	if not cl or (cl.gold == 0 and next(cl.items) == nil) then
		return
	end
	DataService.addGold(player, cl.gold)
	for id, n in cl.items do
		DataService.addItem(player, id, n)
	end
	Remotes.Notify:FireClient(player, ("☠️ You made it out! Cave loot saved: %d gold"):format(cl.gold), "gold")
	data.caveLoot = { gold = 0, items = {} }
	DataService.sync(player)
end

-- lose the cave loot; a player killer takes it
local function dropCaveLoot(player: Player, killer: Player?)
	local data = DataService.get(player)
	local cl = data and data.caveLoot
	if not cl or (cl.gold == 0 and next(cl.items) == nil) then
		return
	end
	data.caveLoot = { gold = 0, items = {} }
	DataService.sync(player)
	local kd = killer and DataService.get(killer)
	if kd then
		local kl = caveLoot(kd)
		kl.gold += cl.gold
		for id, n in cl.items do
			kl.items[id] = (kl.items[id] or 0) + n
		end
		DataService.sync(killer)
		Remotes.Notify:FireClient(killer, ("☠️ You took %s's cave loot: %d gold! Get out alive to keep it."):format(player.DisplayName, cl.gold), "gold")
		Remotes.Notify:FireClient(player, ("☠️ %s took your cave loot (%d gold)."):format(killer.DisplayName, cl.gold), "warn")
	else
		Remotes.Notify:FireClient(player, ("☠️ You lost your cave loot (%d gold)."):format(cl.gold), "warn")
	end
end

-- ===================== fights =====================
local function sendState(player: Player)
	local f = fights[player]
	if not f then
		Remotes.CombatState:FireClient(player, { active = false })
		return
	end
	if f.kind == "enemy" then
		local e = f.enemy
		Remotes.CombatState:FireClient(player, { active = true, name = e.def.name, level = e.def.level, hp = e.hp, maxHp = e.def.hp })
	else
		local hum = f.victim.Character and f.victim.Character:FindFirstChildOfClass("Humanoid")
		Remotes.CombatState:FireClient(player, { active = true, name = f.victim.DisplayName, pvp = true, hp = hum and hum.Health or 0, maxHp = hum and hum.MaxHealth or 1 })
	end
end

function CombatService.stop(player: Player, reason: string?)
	local f = fights[player]
	if not f then
		return
	end
	if reason == "player" then
		noAutoUntil[player] = os.clock() + 4 -- pressed stop: give them time to walk away
	end
	fights[player] = nil
	if f.enemy then
		f.enemy.attackers[player] = nil
	end
	Remotes.CombatState:FireClient(player, { active = false, reason = reason })
end

local function combatXp(player: Player, data, dmg: number)
	local mult = HouseGrid.xpMultiplier(data.home.rooms)
	local skill = Combat.xpSkill(data)
	local b1, a1 = DataService.addXp(player, skill, dmg * 2.5 * mult)
	local b2, a2 = DataService.addXp(player, "hitpoints", dmg * 0.83 * mult)
	if a1 > b1 then
		Remotes.Notify:FireClient(player, ("Level up! %s is now %d"):format(skill:sub(1, 1):upper() .. skill:sub(2), a1), "good")
	end
	if a2 > b2 then
		CombatService.applyMaxHp(player)
	end
end

local function killEnemy(e, killer: Player?)
	e.alive = false
	e.chase = nil
	for p in e.attackers do
		CombatService.stop(p, "won")
	end
	e.attackers = {}
	-- clients play the fall; the body goes a moment later
	e.model:SetAttribute("Dead", true)
	task.delay(1.1, function()
		if not e.alive then
			e.model.Parent = nil
		end
	end)
	if killer then
		local data = DataService.get(killer)
		if data then
			local gold = rng:NextInteger(e.def.gold[1], e.def.gold[2])
			local items = {}
			if e.def.ghost and rng:NextNumber() < 0.5 then
				items.wraith_ether = rng:NextInteger(1, 3)
			end
			giveLoot(killer, gold, items)
			data.stats.kills = (data.stats.kills or 0) + 1
			DataService.sync(killer)
			Remotes.Notify:FireClient(killer, ("Defeated %s!  +%d gold%s%s"):format(e.def.name, gold, items.wraith_ether and ("  +" .. items.wraith_ether .. " Wraith Ether") or "", inWild[killer] and " (cave loot)" or ""), "gold")
		end
	end
	task.delay(12, function()
		e.hp = e.def.hp
		e.alive = true
		e.model:PivotTo(CFrame.new(e.home))
		e.pos = e.home
		e.model:SetAttribute("Dead", false)
		e.model.Parent = e.folder
	end)
end

-- the hero swings on their own until the fight ends
local function fightLoop(player: Player, f)
	task.spawn(function()
		while fights[player] == f do
			task.wait(Combat.PLAYER_SPEED)
			if fights[player] ~= f then
				return
			end
			local hum, hrp = humanoidOf(player)
			local data = DataService.get(player)
			if not hum or not data then
				CombatService.stop(player, "dead")
				return
			end
			local targetRoot, defend
			if f.kind == "enemy" then
				if not f.enemy.alive then
					CombatService.stop(player, "won")
					return
				end
				targetRoot = f.enemy.root
				defend = { def = f.enemy.def.def }
			else
				local vh, vroot = humanoidOf(f.victim)
				local vd = DataService.get(f.victim)
				if not vh or not vd or not inWild[f.victim] or not inWild[player] then
					CombatService.stop(player, "won")
					return
				end
				targetRoot = vroot
				defend = Combat.defenderStats(vd)
			end
			if flat(hrp.Position, targetRoot.Position) > Combat.REACH + 4 then
				CombatService.stop(player, "moved")
				return
			end
			-- face the target and swing: Roblox's own sword slash, a lunge every third swing (clients add the sound)
			hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(targetRoot.Position.X, hrp.Position.Y, targetRoot.Position.Z))
			local char = player.Character
			local n = (char:GetAttribute("Swing") or 0) + 1
			char:SetAttribute("Swing", n)
			GatherService.swing(player, n % 3 == 0 and "Lunge" or "Slash")
			local a = Combat.attackerStats(data)
			local chance = Combat.hitChance(a.acc, defend.def + (defend.armour or 0) * 0.5)
			if rng:NextNumber() >= chance then
				splat(targetRoot, 0, "miss")
			else
				local dmg = rng:NextInteger(1, math.max(1, a.maxHit))
				if f.kind == "enemy" then
					local e = f.enemy
					dmg = math.min(dmg, e.hp)
					e.hp -= dmg
					e.model:SetAttribute("Hurt", (e.model:GetAttribute("Hurt") or 0) + 1)
					splat(targetRoot, dmg, "hit")
					combatXp(player, data, dmg)
					if e.hp <= 0 then
						killEnemy(e, player)
						return
					end
				else
					dmg = math.max(1, math.floor(dmg * (1 - defend.dr)))
					splat(targetRoot, dmg, "hit")
					combatXp(player, data, dmg)
					hurtPlayer(f.victim, dmg, player)
					-- the victim fights back on their own if they were doing nothing
					if not fights[f.victim] then
						CombatService.attackPlayer(f.victim, player, true)
					end
				end
			end
			sendState(player)
		end
	end)
end

function CombatService.attackEnemy(player: Player, e)
	if not e or not e.alive then
		return
	end
	local hum, hrp = humanoidOf(player)
	if not hum or flat(hrp.Position, e.root.Position) > Combat.REACH + 2 then
		return
	end
	if fights[player] and fights[player].enemy == e then
		return
	end
	CombatService.stop(player, "switch")
	GatherService.stop(player, "player")
	local f = { kind = "enemy", enemy = e }
	fights[player] = f
	e.attackers[player] = true
	e.target = e.target or player
	GatherService.equipWeapon(player)
	sendState(player)
	fightLoop(player, f)
end

function CombatService.attackPlayer(player: Player, victim: Player, retaliate: boolean?)
	if not victim or victim == player or not inWild[player] or not inWild[victim] then
		if not retaliate then
			Remotes.Notify:FireClient(player, "You can only fight other players inside the ☠️ Wraith Caves.", "warn")
		end
		return
	end
	local _, hrp = humanoidOf(player)
	local _, vroot = humanoidOf(victim)
	if not hrp or not vroot or flat(hrp.Position, vroot.Position) > Combat.REACH + 4 then
		return
	end
	CombatService.stop(player, "switch")
	GatherService.stop(player, "player")
	local f = { kind = "player", victim = victim }
	fights[player] = f
	GatherService.equipWeapon(player)
	if not retaliate then
		Remotes.Notify:FireClient(victim, ("⚔️ %s is attacking you!"):format(player.DisplayName), "warn")
	end
	sendState(player)
	fightLoop(player, f)
end

-- enemies hit back at whoever is fighting them
local function enemyLoop(e)
	task.spawn(function()
		while true do
			task.wait(e.def.speed)
			if e.alive and next(e.attackers) then
				-- keep hitting the same hero while they stay, otherwise pick another attacker
				if not (e.target and e.attackers[e.target]) then
					e.target = next(e.attackers)
				end
				local p = e.target
				local hum, hrp = humanoidOf(p)
				local data = DataService.get(p)
				if hum and data and flat(hrp.Position, e.root.Position) <= Combat.REACH + 4 then
					e.model:SetAttribute("Atk", (e.model:GetAttribute("Atk") or 0) + 1)
					local d = Combat.defenderStats(data)
					if rng:NextNumber() < Combat.enemyHitChance(e.def.atk, d) then
						local dmg = math.max(1, math.floor(rng:NextInteger(1, e.def.maxHit) * (1 - d.dr)))
						splat(hrp, dmg, "hurt")
						hurtPlayer(p, dmg, nil)
						-- defensive style trains Defence from the hits you block, like the web game's xp per damage dealt
					else
						splat(hrp, 0, "block")
					end
				else
					e.attackers[p] = nil
					e.target = nil
				end
			elseif e.alive and not next(e.attackers) and e.hp < e.def.hp then
				e.hp = math.min(e.def.hp, e.hp + math.ceil(e.def.hp * 0.1)) -- heal up when left alone
			end
		end
	end)
end

-- ===================== enemy models =====================
-- Monster models live in ServerStorage.AssetPacks.Monsters (saved in the place, not in git): Roblox's own Wolf and
-- meshes made with Roblox's mesh generator. The wraiths of the Wraith Caves reuse them as see-through ghosts.
-- Without a model an enemy is built from plain parts as before.
local ServerStorage = game:GetService("ServerStorage")
local MODEL_OF = { revimp = "imp", revgob = "goblin", revknight = "drakeknight", revdragon = "dragon" }
local HEIGHT = { blob = 3, quad = 3.2, humanoid = 6, flyer = 3, dragon = 8 }

local function monsterModel(def, pos: Vector3)
	local packs = ServerStorage:FindFirstChild("AssetPacks")
	local src = packs and packs:FindFirstChild("Monsters") and packs.Monsters:FindFirstChild(MODEL_OF[def.id] or def.id)
	if not src then
		return nil
	end
	local c = src:Clone()
	for _, d in c:GetDescendants() do
		if d:IsA("LuaSourceContainer") or d:IsA("Humanoid") then
			d:Destroy()
		end
	end
	for _, d in c:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			if def.ghost then
				d.Transparency = math.max(d.Transparency, 0.4)
			end
		end
	end
	local h = (HEIGHT[def.shape] or 5) * def.size
	c:ScaleTo(c:GetScale() * h / math.max(c:GetExtentsSize().Y, 0.1))
	local lift = def.shape == "flyer" and 3.5 or 0
	local box, size = c:GetBoundingBox()
	local bottom = box.Position - Vector3.new(0, size.Y / 2, 0)
	c:PivotTo(c:GetPivot() + (pos + Vector3.new(0, lift, 0) - bottom))
	return c, h, lift
end

local function buildEnemy(def, pos: Vector3, folder: Folder)
	local s = def.size
	local model = Instance.new("Model")
	model.Name = def.name
	local color, body = hex(def.color), hex(def.body or def.color)
	local mat = def.ghost and Enum.Material.Neon or Enum.Material.SmoothPlastic
	local tr = def.ghost and 0.35 or 0
	local cf = CFrame.new(pos)
	local root
	local asset, assetH, lift = monsterModel(def, pos)
	if asset then
		-- an invisible box around the model carries the label, the prompt and the taps
		root = part({ Name = "Root", Size = Vector3.new(3.5 * s, assetH, 3.5 * s), CFrame = cf * CFrame.new(0, lift + assetH / 2, 0), Transparency = 1, Parent = model })
		asset.Name = "Look"
		asset.Parent = model
		model:SetAttribute("LookOffset", root.CFrame:ToObjectSpace(asset:GetPivot()))
		model:SetAttribute("Height", assetH)
		model:SetAttribute("Flyer", def.shape == "flyer")
	elseif def.shape == "blob" then
		root = part({ Name = "Root", Shape = Enum.PartType.Ball, Size = Vector3.new(3, 2.4, 3) * s, CFrame = cf * CFrame.new(0, 1.2 * s, 0), Color = color, Material = Enum.Material.Glass, Transparency = 0.2, Parent = model })
	elseif def.shape == "quad" then
		root = part({ Name = "Root", Size = Vector3.new(2, 2, 4) * s * 1.4, CFrame = cf * CFrame.new(0, 2 * s, 0), Color = color, Material = mat, Transparency = tr, Parent = model })
		part({ Size = Vector3.new(1.8, 1.8, 1.8) * s * 1.2, CFrame = root.CFrame * CFrame.new(0, 0.8 * s, -3 * s), Color = color, Material = mat, Transparency = tr, Parent = model })
		for _, x in { -0.9, 0.9 } do
			for _, z in { -1.8, 1.8 } do
				part({ Size = Vector3.new(0.7, 1.6, 0.7) * s * 1.2, CFrame = root.CFrame * CFrame.new(x * s, -1.8 * s, z * s), Color = color, Material = mat, Transparency = tr, Parent = model })
			end
		end
	elseif def.shape == "flyer" then
		root = part({ Name = "Root", Shape = Enum.PartType.Ball, Size = Vector3.new(2.6, 2.6, 2.6) * s, CFrame = cf * CFrame.new(0, 5, 0), Color = color, Material = mat, Transparency = tr, Parent = model })
		for _, x in { -1, 1 } do
			part({ Size = Vector3.new(3.2, 0.3, 1.8) * s, CFrame = root.CFrame * CFrame.new(x * 2.6 * s, 0.3, 0) * CFrame.Angles(0, 0, x * 0.3), Color = color:Lerp(Color3.new(0, 0, 0), 0.3), Material = mat, Transparency = tr, Parent = model })
		end
	elseif def.shape == "dragon" then
		root = part({ Name = "Root", Size = Vector3.new(6, 5, 11), CFrame = cf * CFrame.new(0, 4, 0), Color = color, Material = mat, Transparency = tr, Parent = model })
		part({ Size = Vector3.new(3.5, 3.5, 5), CFrame = root.CFrame * CFrame.new(0, 2.5, -7), Color = color, Material = mat, Transparency = tr, Parent = model })
		for _, x in { -1, 1 } do
			part({ Size = Vector3.new(9, 0.4, 5), CFrame = root.CFrame * CFrame.new(x * 7, 2, 0) * CFrame.Angles(0, 0, x * 0.35), Color = color:Lerp(Color3.new(0, 0, 0), 0.35), Material = mat, Transparency = tr, Parent = model })
		end
	else -- humanoid
		local h = 5 * s
		root = part({ Name = "Root", Size = Vector3.new(2, 2.4, 1.2) * s * 1.3, CFrame = cf * CFrame.new(0, h * 0.62, 0), Color = body, Material = mat, Transparency = tr, Parent = model })
		part({ Shape = Enum.PartType.Ball, Size = Vector3.new(1.7, 1.7, 1.7) * s * 1.2, CFrame = root.CFrame * CFrame.new(0, 2.3 * s, 0), Color = color, Material = mat, Transparency = tr, Parent = model })
		for _, x in { -0.6, 0.6 } do
			part({ Size = Vector3.new(0.8, 2.6, 0.8) * s * 1.2, CFrame = root.CFrame * CFrame.new(x * s * 1.2, -2.6 * s, 0), Color = body:Lerp(Color3.new(0, 0, 0), 0.2), Material = mat, Transparency = tr, Parent = model })
			part({ Size = Vector3.new(0.6, 2.2, 0.6) * s * 1.2, CFrame = root.CFrame * CFrame.new(x * s * 2.4, 0, 0), Color = color, Material = mat, Transparency = tr, Parent = model })
		end
	end
	root.CanQuery = true
	model.PrimaryPart = root
	if def.ghost then
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(160, 255, 160)
		l.Range = 12
		l.Parent = root
	end
	-- name, level and a health bar
	local bb = Instance.new("BillboardGui")
	bb.Name = "EnemyLabel"
	bb.Size = UDim2.fromScale(7, 1.8)
	bb.StudsOffsetWorldSpace = Vector3.new(0, (asset and assetH / 2 or 3.5 * s) + 2, 0)
	bb.MaxDistance = 70
	bb.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 0.6)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.3
	t.Text = ("%s  (Lv %d)"):format(def.name, def.level)
	t.Parent = bb
	local barBg = Instance.new("Frame")
	barBg.Name = "Bar"
	barBg.Position = UDim2.fromScale(0.1, 0.68)
	barBg.Size = UDim2.fromScale(0.8, 0.25)
	barBg.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
	barBg.Parent = bb
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(90, 220, 90)
	fill.BorderSizePixel = 0
	fill.Parent = barBg
	bb.Parent = root
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "AttackPrompt"
	prompt.ActionText = "Attack"
	prompt.ObjectText = ("%s (Lv %d)"):format(def.name, def.level)
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = Combat.REACH
	prompt.RequiresLineOfSight = false
	prompt.Style = Enum.ProximityPromptStyle.Custom -- nothing to press: walking up starts the fight, the prompt only serves taps
	prompt.Parent = root
	model.Parent = folder
	return model, root, fill, prompt
end

-- ===================== moving about =====================
-- put the monster at pos, facing a point: the Root box when a client animates the model, the whole model otherwise
local function placeEnemy(e, pos: Vector3, face: Vector3?)
	local look = face and Vector3.new(face.X, pos.Y, face.Z) or nil
	local cf = (look and (look - pos).Magnitude > 0.1) and CFrame.lookAt(pos, look) or (CFrame.new(pos) * e.root.CFrame.Rotation)
	if e.look then
		e.root.CFrame = cf
	else
		e.model:PivotTo(cf)
	end
	e.pos = pos
end

local function safeZone(pos: Vector3): boolean
	local z = Zones.LIST[Zones.indexAt(pos.X, pos.Z)]
	return z.town == true or z.home == true
end

-- step towards a point at a speed (studs a second), stopping `stop` studs short
local function walkTowards(e, target: Vector3, speed: number, dt: number, stop: number)
	local to = Vector3.new(target.X - e.pos.X, 0, target.Z - e.pos.Z)
	local d = to.Magnitude
	if d <= stop then
		placeEnemy(e, e.pos, target)
		return true
	end
	local step = math.min(speed * dt, d - stop)
	placeEnemy(e, e.pos + to.Unit * step, target)
	return false
end

-- the nearest hero a monster would go for: close, alive, not in a safe zone, and not more than twice its level
local function preyFor(e)
	local best, bestD = nil, Combat.AGGRO
	for _, p in Players:GetPlayers() do
		local hum, hrp = humanoidOf(p)
		local data = DataService.get(p)
		-- one monster at a time comes for a hero: no crowding round someone already busy
		local busy = fights[p] ~= nil
		for _, other in enemies do
			if other.chase == p and other ~= e then
				busy = true
				break
			end
		end
		if hum and data and not busy and not safeZone(hrp.Position) then
			local d = flat(hrp.Position, e.pos)
			local weak = Combat.combatLevel(data.skills) <= e.def.level * 2 or e.zone == "wild"
			if d < bestD and weak then
				best, bestD = p, d
			end
		end
	end
	return best
end

function monsterStep(e, dt: number)
	local fromHome = flat(e.pos, e.home)
	local fighting = next(e.attackers) ~= nil
	if fighting then
		-- stand close to the hero being fought
		local p = e.target and e.attackers[e.target] and e.target or next(e.attackers)
		local _, hrp = humanoidOf(p)
		if hrp and fromHome < Combat.LEASH then
			walkTowards(e, hrp.Position, 10, dt, 4.5 + e.def.size * 1.5)
		end
		return
	end
	-- chasing someone who came too close
	if e.chase then
		local _, hrp = humanoidOf(e.chase)
		if not hrp or fromHome > Combat.LEASH or safeZone(hrp.Position) then
			e.chase = nil
		else
			walkTowards(e, hrp.Position, 12, dt, 4.5 + e.def.size * 1.5)
			return
		end
	end
	if fromHome > 2 and not e.wander then
		e.wander = e.home -- go back home after a chase
	end
	local prey = preyFor(e)
	if prey and fromHome < Combat.LEASH - 6 then
		e.chase = prey
		e.wander = nil
		return
	end
	-- wander about the camp spot
	if e.wander then
		if walkTowards(e, e.wander, e.wander == e.home and 10 or 4, dt, 0.3) then
			e.wander = nil
			e.rest = os.clock() + rng:NextNumber(2, 6)
		end
	elseif os.clock() > (e.rest or 0) then
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(2, 8)
		e.wander = e.home + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
	end
end

-- heroes who walk up to a monster (or a monster that came for them) fight it on their own
function autoFight()
	for _, p in Players:GetPlayers() do
		if not fights[p] and os.clock() > (noAutoUntil[p] or 0) then
			local hum, hrp = humanoidOf(p)
			if hum and not safeZone(hrp.Position) then
				local best, bestD = nil, Combat.AUTO
				for _, e in enemies do
					if e.alive then
						local d = flat(hrp.Position, e.root.Position)
						if d < bestD or (e.chase == p and d < Combat.REACH) then
							best, bestD = e, math.min(d, bestD)
						end
					end
				end
				-- a hero busy gathering only stops for a monster that came for them
				if best and (best.chase == p or not GatherService.isGathering(p)) then
					CombatService.attackEnemy(p, best)
				end
			end
		end
	end
end

-- a camp is a marked spot: a ring of trampled ground, a campfire and a sign with its name and levels
local function buildCamp(parent: Instance, camp)
	if camp.zone == "wild" then
		return -- the Wraith Caves are one big hunting ground
	end
	local zone = Zones.byId[camp.zone]
	local c = camp.center
	local r = (camp.spread or 32) + 6
	local ground = Color3.fromHex(zone.th.dirt or zone.th.ground)
	part({ Name = "CampGround", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, r * 2, r * 2), CFrame = CFrame.new(c + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = ground, Material = Enum.Material.Ground, Transparency = 0.15, CanQuery = false, Parent = parent })
	-- campfire
	for i = 0, 3 do
		part({ Size = Vector3.new(0.7, 0.7, 4), CFrame = CFrame.new(c + Vector3.new(0, 0.5, 0)) * CFrame.Angles(0, i * math.pi / 4, 0), Color = hex("#6b4a2b"), Material = Enum.Material.Wood, Parent = parent })
	end
	local fire = part({ Name = "Fire", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(c + Vector3.new(0, 1.2, 0)), Transparency = 1, CanQuery = false, Parent = parent })
	local f = Instance.new("Fire")
	f.Size = 4
	f.Heat = 6
	f.Parent = fire
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(255, 170, 90)
	l.Range = 20
	l.Brightness = 1.4
	l.Parent = fire
	-- sign with crossed swords
	local post = part({ Name = "CampSign", Size = Vector3.new(0.6, 9, 0.6), CFrame = CFrame.new(c + Vector3.new(r - 3, 4.5, 0)), Color = hex("#6b4a2b"), Material = Enum.Material.Wood, Parent = parent })
	part({ Size = Vector3.new(5, 2.4, 0.4), CFrame = post.CFrame * CFrame.new(0, 3, 0), Color = hex("#8a5a32"), Material = Enum.Material.WoodPlanks, Parent = parent })
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(14, 3)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 7, 0)
	bb.MaxDistance = 160
	bb.LightInfluence = 0
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 0.6)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = Color3.fromRGB(255, 120, 100)
	t.TextStrokeTransparency = 0.2
	t.Text = "⚔️ " .. camp.name
	t.Parent = bb
	local sub = t:Clone()
	sub.Position = UDim2.fromScale(0, 0.6)
	sub.Size = UDim2.fromScale(1, 0.4)
	sub.Font = Enum.Font.GothamBold
	sub.TextColor3 = Color3.fromRGB(255, 220, 160)
	sub.Text = camp.lo == camp.hi and ("Level %d"):format(camp.lo) or ("Levels %d–%d"):format(camp.lo, camp.hi)
	sub.Parent = bb
	bb.Parent = post
end

local function spawnEnemies(world: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Enemies"
	folder.Parent = world
	local camps = Instance.new("Folder")
	camps.Name = "Camps"
	camps.Parent = world
	for _, sp in Combat.CAMPS do
		buildCamp(camps, sp)
		local zoneId = sp.zone
		local spread = sp.spread or 32
		for k, id in sp.enemies do
			local def = Combat.ENEMIES[id]
			for j = 1, sp.each do
				local a = (k * 2.1 + j * 1.3)
				local r = spread * (0.35 + 0.65 * ((k + j) % 3) / 2)
				local pos = sp.center + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
				local zr = Zones.byId[zoneId].rect
				pos = Vector3.new(math.clamp(pos.X, zr[1] + 12, zr[3] - 12), 0, math.clamp(pos.Z, zr[2] + 12, zr[4] - 12))
				local model, root, fill, prompt = buildEnemy(def, pos, folder)
				local home = model:GetPivot().Position
				local e = { def = def, model = model, root = root, fill = fill, hp = def.hp, alive = true, home = home, pos = home, attackers = {}, folder = folder, zone = zoneId, look = model:FindFirstChild("Look") ~= nil, camp = sp }
				prompt.Triggered:Connect(function(player)
					CombatService.attackEnemy(player, e)
				end)
				table.insert(enemies, e)
				enemyLoop(e)
			end
		end
	end
	-- health bars, wandering, chasing and auto-fighting
	task.spawn(function()
		local STEP = 0.2
		while true do
			task.wait(STEP)
			for _, e in enemies do
				if e.alive then
					e.fill.Size = UDim2.fromScale(math.max(0, e.hp / e.def.hp), 1)
					e.fill.BackgroundColor3 = e.hp / e.def.hp > 0.5 and Color3.fromRGB(90, 220, 90) or e.hp / e.def.hp > 0.25 and Color3.fromRGB(240, 190, 60) or Color3.fromRGB(230, 70, 60)
					monsterStep(e, STEP)
				end
			end
			autoFight()
		end
	end)
end

-- ===================== players =====================
local function onCharacter(player: Player, char: Model)
	local hum = char:WaitForChild("Humanoid", 10)
	if not hum then
		return
	end
	-- our own health rules: no default regeneration script
	local regen = char:FindFirstChild("Health")
	if regen then
		regen:Destroy()
	end
	task.defer(CombatService.applyMaxHp, player)
	hum.Died:Connect(function()
		CombatService.stop(player, "dead")
		if inWild[player] then
			local by = lastPvpBy[player]
			local killer = by and os.clock() - by.at < 20 and by.by.Parent and by.by or nil
			dropCaveLoot(player, killer)
			if killer then
				local kd = DataService.get(killer)
				if kd then
					kd.stats.pks = (kd.stats.pks or 0) + 1
				end
			end
		end
		inWild[player] = nil
		lastPvpBy[player] = nil
	end)
end

function CombatService.setStyle(player: Player, style)
	local data = DataService.get(player)
	if data and type(style) == "string" and Combat.STYLE_BY[style] then
		data.combat.style = style
		DataService.sync(player)
	end
end

-- buy and wear the next weapon or armour set at the Smithy
function CombatService.buyGear(player: Player, slot)
	local data = DataService.get(player)
	if not data or (slot ~= "weapon" and slot ~= "armour") then
		return
	end
	local smithy = workspace:FindFirstChild("Smithy", true)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not smithy or not hrp or (hrp.Position - smithy:GetPivot().Position).Magnitude > 18 then
		Remotes.Notify:FireClient(player, "Visit the ⚔️ Smithy in Riverbend to buy gear.", "warn")
		return
	end
	local t = data.gear[slot] + 1
	if t > Combat.GEAR_MAX then
		return
	end
	local skill = slot == "weapon" and "attack" or "defence"
	local need = Combat.EQUIP_REQ[t]
	if XP.levelFromXp(data.skills[skill]) < need then
		Remotes.Notify:FireClient(player, ("You need %s level %d."):format(skill == "attack" and "Attack" or "Defence", need), "warn")
		return
	end
	local cost = (slot == "weapon" and Combat.WEAPON_COST or Combat.ARMOUR_COST)[t]
	if data.gold < cost then
		Remotes.Notify:FireClient(player, "Not enough gold.", "warn")
		return
	end
	DataService.addGold(player, -cost)
	data.gear[slot] = t
	DataService.sync(player)
	Remotes.Notify:FireClient(player, ("Now wearing %s %s!"):format(Combat.METALS[t], slot == "weapon" and "Sword" or "Armour"), "good")
	if slot == "weapon" and fights[player] then
		GatherService.equipWeapon(player)
	end
end

function CombatService.isFighting(player: Player): boolean
	return fights[player] ~= nil
end

function CombatService.init(world: Instance)
	spawnEnemies(world)
	GatherService.onStart = function(player)
		CombatService.stop(player, "switch")
	end
	local function hook(player: Player)
		player.CharacterAdded:Connect(function(char)
			onCharacter(player, char)
		end)
		if player.Character then
			task.spawn(onCharacter, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(hook)
	for _, p in Players:GetPlayers() do
		hook(p)
	end
	DataService.onLoaded(function(player)
		task.defer(CombatService.applyMaxHp, player)
	end)
	-- leaving the game: keep the cave loot unless someone was fighting you (no logging out to escape)
	DataService.onBeforeLeave(function(player)
		CombatService.stop(player, "leave")
		if inWild[player] then
			local by = lastPvpBy[player]
			if by and os.clock() - by.at < 15 and by.by.Parent then
				dropCaveLoot(player, by.by)
			else
				bankCaveLoot(player)
			end
		end
		inWild[player] = nil
	end)

	-- zone watch (Wraith Caves entry, banking cave loot on the way out) and health regeneration out of combat
	local wild = Zones.byId.wild
	task.spawn(function()
		while true do
			task.wait(0.5)
			for _, player in Players:GetPlayers() do
				local hum, hrp = humanoidOf(player)
				local data = DataService.get(player)
				if hum and hrp and data then
					local inside = isWild(hrp.Position)
					if inside and not inWild[player] then
						if Combat.combatLevel(data.skills) < wild.req then
							-- too weak: back out through the cave mouth
							hrp.CFrame = CFrame.new(wild.mouthX, 4, wild.rect[4] + 14)
							Remotes.Notify:FireClient(player, ("☠️ The Wraith Caves need combat level %d (you are %d)."):format(wild.req, Combat.combatLevel(data.skills)), "warn")
						else
							inWild[player] = true
							Remotes.Notify:FireClient(player, "☠️ You entered the Wraith Caves: other players can attack you here! Loot you win is only yours once you get out.", "warn")
						end
					elseif not inside and inWild[player] then
						inWild[player] = nil
						CombatService.stop(player, "left")
						bankCaveLoot(player)
					end
					if not fights[player] and os.clock() - (lastHurt[player] or 0) > 6 and hum.Health < hum.MaxHealth then
						hum.Health = math.min(hum.MaxHealth, hum.Health + math.max(1, hum.MaxHealth * 0.01))
					end
				end
			end
		end
	end)
end

-- was the player hit in the last `seconds`? (no teleporting out of a fight)
function CombatService.hurtWithin(player: Player, seconds: number): boolean
	return os.clock() - (lastHurt[player] or -math.huge) < seconds
end

function CombatService.inWild(player: Player): boolean
	return inWild[player] == true
end

return CombatService
