-- Melee on the OSRS clock: everything happens on 0.6 s ticks. Tap a rat to fight it; your hero walks up (the
-- client) and swings every 5 ticks with the longsword while the rat bites back every 4. Accuracy and max hit are
-- rolled from levels, the combat style and the sword's bonuses; damage gives 4 xp per point to the style's skill
-- and 1.33 to Hitpoints. A rat that dies falls over and comes back a little later somewhere in the granary yard.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local CollectionService = game:GetService("CollectionService")
local StarterPlayer = game:GetService("StarterPlayer")

local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)
local Sword = require(script.Parent.Sword)
local World = require(script.Parent.World)

local Combat = {}

local RAT_ASSET = 3374795585 -- "Rat" by Roblox
local RAT_RADIUS = 1.6

local remotes: Folder
local rng = Random.new()
local enemies = {} -- [Model] = state
local fights = {} -- [Player] = { target = Model, nextSwing = number }
local template: Model?

local function remote(name: string): RemoteEvent
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotes
	return r
end

local function rootOf(player: Player): (Humanoid?, BasePart?)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hum and hrp and hum.Health > 0 then
		return hum, hrp
	end
	return nil, nil
end

local function flat(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

-- ===== skills =====

local function xpOf(player: Player, skill: string): number
	return player:GetAttribute("XP_" .. skill) or 0
end

local function level(player: Player, skill: string): number
	return Config.levelFor(xpOf(player, skill))
end

local function addXp(player: Player, skill: string, amount: number)
	local before = level(player, skill)
	player:SetAttribute("XP_" .. skill, xpOf(player, skill) + amount)
	remotes.Xp:FireClient(player, skill, amount)
	local after = level(player, skill)
	if after > before then
		remotes.Message:FireClient(player, string.format("Congratulations, your %s level is now %d.", skill, after), "level")
		if skill == "Hitpoints" then
			local hum = rootOf(player)
			if hum then
				hum.MaxHealth = after
				hum.Health = math.min(after, hum.Health + (after - before))
			end
		end
	end
end

local function splat(target: BasePart, dmg: number, by: Player?)
	remotes.Splat:FireAllClients(target, dmg, by)
end

-- ===== the rats =====

local function yardPoint(): Vector3
	local y = World.RAT_YARD
	return y.center + Vector3.new(rng:NextNumber(-0.42, 0.42) * y.size.X, 0, rng:NextNumber(-0.4, 0.4) * y.size.Z)
end

local stopFight

local function spawnEnemy(kind: string)
	local def = Config.ENEMIES[kind]
	local m = (template :: Model):Clone()
	m.Name = kind
	local hum = m:FindFirstChildOfClass("Humanoid") :: Humanoid
	local hrp = m:FindFirstChild("HumanoidRootPart") :: BasePart
	local pos = yardPoint()
	m:PivotTo(CFrame.new(pos + Vector3.new(0, hrp.Size.Y / 2, 0)) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
	m:SetAttribute("Kind", kind)
	m:SetAttribute("Level", def.level)
	m:SetAttribute("Hp", def.hp)
	m:SetAttribute("MaxHp", def.hp)
	local click = Instance.new("ClickDetector")
	click.MaxActivationDistance = 120
	click.CursorIcon = "rbxasset://textures/Cursors/KeyboardMouse/ArrowCursor.png"
	click.Parent = m
	m.Parent = workspace:FindFirstChild("Enemies") or workspace
	hrp:SetNetworkOwner(nil)
	CollectionService:AddTag(m, "Enemy")

	local state = { kind = kind, def = def, hp = def.hp, alive = true, model = m, hum = hum, hrp = hrp, home = pos,
		target = nil :: Player?, nextBite = 0, nextWander = os.clock() + rng:NextNumber(1, 4) }
	enemies[m] = state

	-- the walk cycle that comes with the model (Roblox's own animation)
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	local anim = m:FindFirstChildWhichIsA("Animation", true)
	if anim then
		local walk = animator:LoadAnimation(anim)
		walk.Looped = true
		hum.Running:Connect(function(speed)
			if speed > 0.5 and state.alive then
				if not walk.IsPlaying then
					walk:Play(0.1)
				end
				walk:AdjustSpeed(speed / 7)
			elseif walk.IsPlaying then
				walk:Stop(0.15)
			end
		end)
	end

	click.MouseClick:Connect(function(player)
		Combat.attack(player, m)
	end)
end

local function killEnemy(state)
	state.alive = false
	state.model:SetAttribute("Dead", true)
	state.hum:MoveTo(state.hrp.Position)
	local cd = state.model:FindFirstChildOfClass("ClickDetector")
	if cd then
		cd:Destroy()
	end
	for player, f in fights do
		if f.target == state.model then
			stopFight(player)
		end
	end
	task.delay(1.6, function()
		enemies[state.model] = nil
		state.model:Destroy()
	end)
	task.delay(state.def.respawn, spawnEnemy, state.kind)
end

-- ===== fighting =====

function stopFight(player: Player)
	if fights[player] then
		fights[player] = nil
		remotes.Fight:FireClient(player, nil)
	end
end

function Combat.attack(player: Player, m: Model)
	local state = enemies[m]
	local hum, hrp = rootOf(player)
	if not state or not state.alive or not hum then
		return
	end
	-- single combat, as in OSRS
	if state.target and state.target ~= player and fights[state.target] and fights[state.target].target == m then
		remotes.Message:FireClient(player, "Someone else is fighting that.", "info")
		return
	end
	if flat(hrp.Position, state.hrp.Position) > 120 then
		return
	end
	local f = fights[player]
	if f and f.target == m then
		return
	end
	fights[player] = { target = m, nextSwing = 0 }
	remotes.Fight:FireClient(player, m)
end

local function swing(player: Player, f)
	local state = enemies[f.target]
	local hum, hrp = rootOf(player)
	if not state or not hum then
		return
	end
	local contact = Sword.swing(player.Character)
	-- the rat fights back from the first swing on
	if not state.target then
		state.target = player
		state.nextBite = os.clock() + Config.TICK * 2
	end
	task.delay(contact, function()
		if fights[player] ~= f or not state.alive then
			return
		end
		local style = Config.styleById(player:GetAttribute("Style"))
		local sword = Config.SWORD
		local effAtt = level(player, "Attack") + style.attack + 8
		local effStr = level(player, "Strength") + style.strength + 8
		local attackRoll = effAtt * (sword.attack + 64)
		local defenceRoll = (state.def.defence + 9) * 64
		local maxHit = math.max(1, math.floor(0.5 + effStr * (sword.strength + 64) / 640))
		local dmg = 0
		if rng:NextNumber() < Config.hitChance(attackRoll, defenceRoll) then
			dmg = math.min(rng:NextInteger(0, maxHit), state.hp)
		end
		state.hp -= dmg
		state.model:SetAttribute("Hp", state.hp)
		if dmg > 0 then
			state.model:SetAttribute("Hurt", (state.model:GetAttribute("Hurt") or 0) + 1)
			addXp(player, style.skill, dmg * 4)
			addXp(player, "Hitpoints", dmg * 4 / 3)
		end
		splat(state.hrp, dmg, player)
		if state.hp <= 0 then
			killEnemy(state)
		end
	end)
end

local function bite(state, player: Player)
	local hum, hrp = rootOf(player)
	if not hum then
		return
	end
	state.model:SetAttribute("Atk", (state.model:GetAttribute("Atk") or 0) + 1)
	task.delay(0.2, function()
		if not state.alive or not hum.Parent or hum.Health <= 0 then
			return
		end
		local style = Config.styleById(player:GetAttribute("Style"))
		local attackRoll = (state.def.attack + 9) * 64
		local defenceRoll = (level(player, "Defence") + style.defence + 8) * 64
		local dmg = 0
		if rng:NextNumber() < Config.hitChance(attackRoll, defenceRoll) then
			dmg = rng:NextInteger(0, state.def.maxHit)
		end
		if dmg > 0 then
			hum.Health = math.max(0, hum.Health - dmg)
		end
		splat(hrp, dmg, nil)
	end)
end

local function tick()
	local now = os.clock()
	for player, f in fights do
		local state = enemies[f.target]
		local hum, hrp = rootOf(player)
		if not state or not state.alive or not hum then
			stopFight(player)
			continue
		end
		local d = flat(hrp.Position, state.hrp.Position) - RAT_RADIUS
		if d > 60 then
			stopFight(player)
		elseif d <= Config.REACH and now >= f.nextSwing - 0.05 then
			f.nextSwing = now + Config.SWORD.speed * Config.TICK
			swing(player, f)
		end
	end
	for _, state in enemies do
		if not state.alive then
			continue
		end
		local p = state.target
		local hum, hrp
		if p then
			hum, hrp = rootOf(p)
		end
		-- give up when the hero is gone, dead or has run off
		if p and (not hum or flat(hrp.Position, state.home) > 70 or not (fights[p] and fights[p].target == state.model) and flat(hrp.Position, state.hrp.Position) > 14) then
			state.target = nil
			state.hum:MoveTo(state.home)
			continue
		end
		if p and hrp then
			local d = flat(hrp.Position, state.hrp.Position)
			if d > RAT_RADIUS + 2.4 then
				local toward = (state.hrp.Position - hrp.Position) * Vector3.new(1, 0, 1)
				state.hum:MoveTo(hrp.Position + toward.Unit * (RAT_RADIUS + 1.6))
			else
				state.hum:MoveTo(state.hrp.Position)
				state.hrp.CFrame = CFrame.lookAt(state.hrp.Position, Vector3.new(hrp.Position.X, state.hrp.Position.Y, hrp.Position.Z))
			end
			if d <= Config.REACH + RAT_RADIUS and now >= state.nextBite then
				state.nextBite = now + state.def.speed * Config.TICK
				bite(state, p)
			end
		elseif now >= state.nextWander then
			state.nextWander = now + rng:NextNumber(3, 8)
			state.hum.WalkSpeed = state.def.walk * 0.6
			state.hum:MoveTo(yardPoint())
		end
		if p then
			state.hum.WalkSpeed = state.def.walk * 1.4
		end
	end
end

-- ===== players =====

local function setupPlayer(player: Player)
	for _, skill in Config.SKILLS do
		player:SetAttribute("XP_" .. skill, Config.START_XP[skill] or 0)
	end
	player:SetAttribute("Style", "accurate")
	local function onChar(char: Model)
		local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
		if not hum then
			return
		end
		local hp = level(player, "Hitpoints")
		hum.MaxHealth = hp
		hum.Health = hp
		hum.Died:Connect(function()
			stopFight(player)
			remotes.Message:FireClient(player, "Oh dear, you are dead!", "dead")
		end)
	end
	player.CharacterAdded:Connect(onChar)
	if player.Character then
		task.spawn(onChar, player.Character)
	end
end

function Combat.init()
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remote("Splat")
	remote("Xp")
	remote("Fight")
	remote("Message")
	remote("SetStyle")
	remote("StopFight")
	remotes.Parent = ReplicatedStorage

	-- Hitpoints work as in OSRS: no Roblox health regeneration, one point back a minute instead
	if not StarterPlayer.StarterCharacterScripts:FindFirstChild("Health") then
		local none = Instance.new("Script")
		none.Name = "Health"
		none.Parent = StarterPlayer.StarterCharacterScripts
	end
	task.spawn(function()
		while true do
			task.wait(60)
			for _, p in Players:GetPlayers() do
				local hum = rootOf(p)
				if hum and hum.Health < hum.MaxHealth then
					hum.Health = math.min(hum.MaxHealth, hum.Health + 1)
				end
			end
		end
	end)

	remotes.SetStyle.OnServerEvent:Connect(function(player, id)
		if type(id) == "string" and Config.styleById(id).id == id then
			player:SetAttribute("Style", id)
		end
	end)
	remotes.StopFight.OnServerEvent:Connect(stopFight)

	-- for play tests in Studio: the command bar has its own copy of this module, so it starts fights through this
	if game:GetService("RunService"):IsStudio() then
		local test = Instance.new("BindableEvent")
		test.Name = "TestAttack"
		test.Event:Connect(Combat.attack)
		test.Parent = game:GetService("ServerStorage")
	end

	for _, p in Players:GetPlayers() do
		setupPlayer(p)
	end
	Players.PlayerAdded:Connect(setupPlayer)
	Players.PlayerRemoving:Connect(function(p)
		fights[p] = nil
		for _, state in enemies do
			if state.target == p then
				state.target = nil
			end
		end
	end)

	local folder = Instance.new("Folder")
	folder.Name = "Enemies"
	folder.Parent = workspace
	local ok, loaded = pcall(InsertService.LoadAsset, InsertService, RAT_ASSET)
	if ok then
		local rig = loaded:FindFirstChildWhichIsA("Humanoid", true)
		template = rig and rig.Parent :: Model
		if template then
			template.Parent = nil
			local hum = template:FindFirstChildOfClass("Humanoid") :: Humanoid
			-- an R15 humanoid stands its root part HipHeight above the ground; the meshes only ride along
			hum.RigType = Enum.HumanoidRigType.R15
			hum.HipHeight = 0.1
			for _, d in template:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = false
					d.CanCollide = d.Name == "HumanoidRootPart"
					d.Massless = d.Name ~= "HumanoidRootPart"
				end
			end
			hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
			hum.BreakJointsOnDeath = false
			hum.MaxHealth = math.huge
			hum.Health = math.huge
			template.PrimaryPart = template:FindFirstChild("HumanoidRootPart")
			for _ = 1, Config.ENEMIES.Rat.count do
				spawnEnemy("Rat")
			end
		end
	else
		warn("Rat model failed to load: " .. tostring(loaded))
	end

	task.spawn(function()
		while true do
			task.wait(Config.TICK)
			tick()
		end
	end)
end

return Combat
