-- Combat: enemies in every zone and PvP in the Wraith Caves.
-- Tap an enemy (or, in the Wraith Caves, another player) and the hero fights on their own until one side falls
-- or the hero walks away. Food is eaten automatically when health runs low. Hitpoints use the web game's scale.
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

local hex = Color3.fromHex
local rng = Random.new()
local enemies = {} -- array of enemy state { def, model, root, hp, alive, home, attackers = {[Player]=true}, target }
local fights = {} -- [Player] = { token, kind = "enemy" | "player", enemy, victim }
local lastHurt = {} -- [Player] = os.clock() of the last damage taken (no regen in combat)
local lastPvpBy = {} -- [Player] = { by = Player, at = os.clock() }
local inWild = {} -- [Player] = true while inside the Wraith Caves

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
	for p in e.attackers do
		CombatService.stop(p, "won")
	end
	e.attackers = {}
	e.model.Parent = nil
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
			-- face the target and swing
			hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(targetRoot.Position.X, hrp.Position.Y, targetRoot.Position.Z))
			GatherService.swing(player)
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
					e.model:PivotTo(CFrame.lookAt(e.root.Position, Vector3.new(hrp.Position.X, e.root.Position.Y, hrp.Position.Z)))
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
local function buildEnemy(def, pos: Vector3, folder: Folder)
	local s = def.size
	local model = Instance.new("Model")
	model.Name = def.name
	local color, body = hex(def.color), hex(def.body or def.color)
	local mat = def.ghost and Enum.Material.Neon or Enum.Material.SmoothPlastic
	local tr = def.ghost and 0.35 or 0
	local cf = CFrame.new(pos)
	local root
	if def.shape == "blob" then
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
	bb.StudsOffsetWorldSpace = Vector3.new(0, 3.5 * s + 2, 0)
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
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.Parent = root
	model.Parent = folder
	return model, root, fill, prompt
end

local function spawnEnemies(world: Instance)
	local folder = Instance.new("Folder")
	folder.Name = "Enemies"
	folder.Parent = world
	for _, sp in Combat.CAMPS do
		local zoneId = sp.zone
		local spread = sp.spread or 32
		for k, id in sp.enemies do
			local def = Combat.ENEMIES[id]
			for j = 1, sp.each do
				local a = (k * 2.1 + j * 1.3)
				local r = spread * (0.35 + 0.65 * ((k + j) % 3) / 2)
				local pos = sp.center + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
				local model, root, fill, prompt = buildEnemy(def, pos, folder)
				local e = { def = def, model = model, root = root, fill = fill, hp = def.hp, alive = true, home = model:GetPivot().Position, attackers = {}, folder = folder, zone = zoneId }
				prompt.Triggered:Connect(function(player)
					CombatService.attackEnemy(player, e)
				end)
				table.insert(enemies, e)
				enemyLoop(e)
			end
		end
	end
	-- health bars and a gentle idle bob
	task.spawn(function()
		local t = 0
		while true do
			t += 0.25
			for i, e in enemies do
				if e.alive then
					e.fill.Size = UDim2.fromScale(math.max(0, e.hp / e.def.hp), 1)
					e.fill.BackgroundColor3 = e.hp / e.def.hp > 0.5 and Color3.fromRGB(90, 220, 90) or e.hp / e.def.hp > 0.25 and Color3.fromRGB(240, 190, 60) or Color3.fromRGB(230, 70, 60)
					if not next(e.attackers) then
						local bob = (e.def.shape == "flyer") and math.sin(t + i) * 0.8 or 0
						e.model:PivotTo(CFrame.new(e.home + Vector3.new(0, bob, 0)) * CFrame.Angles(0, (t * 0.2 + i) % (math.pi * 2), 0))
					end
				end
			end
			task.wait(0.25)
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

function CombatService.inWild(player: Player): boolean
	return inWild[player] == true
end

return CombatService
