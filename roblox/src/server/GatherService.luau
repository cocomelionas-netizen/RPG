-- Woodcutting, mining, fishing and workbench crafting: the hero keeps working a node until told to stop or walking away.
-- Workbench recipes (skill "construction") use up inputs and stop when they run out.
-- Also handles offline (idle) progress for whatever the hero was doing when they left.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local G = require(Shared.Gathering)
local Items = require(Shared.Items)
local Skills = require(Shared.Skills)
local XP = require(Shared.XP)
local Remotes = require(Shared.Remotes)
local HouseGrid = require(Shared.HouseGrid)
local Farming = require(Shared.Farming)
local DataService = require(script.Parent.DataService)
local ToolFactory = require(script.Parent.ToolFactory)
local HeroMotion = require(script.Parent.HeroMotion)

local GatherService = {}

local MAX_DIST = 14 -- studs from the node before the hero counts as having walked away
local SWING_EVERY = 0.9
local SEED_CHANCE = 0.04 -- per gathered resource
local seedRng = Random.new()
local active = {} -- [Player] = { token, node, skill, tier }

local function root(player: Player)
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return nil
	end
	return char:FindFirstChild("HumanoidRootPart")
end

local function flatDist(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function clearTools(player: Player)
	local char = player.Character
	if char then
		for _, t in char:GetChildren() do
			if t:IsA("Tool") and t:GetAttribute("EndlessRoadTool") then
				t:Destroy()
			end
		end
	end
	local bp = player:FindFirstChildOfClass("Backpack")
	if bp then
		for _, t in bp:GetChildren() do
			if t:GetAttribute("EndlessRoadTool") then
				t:Destroy()
			end
		end
	end
end

local function equip(player: Player, skill: string)
	clearTools(player)
	local data = DataService.get(player)
	local kind = G.TOOL_OF[skill]
	local tool = ToolFactory.make(kind, data and data.tools[kind] or 0)
	tool.Parent = player.Character -- parenting to the character equips it
	return tool
end

-- our own move for the tool (HeroMotion); without one, the default Animate script plays the tool slash animation
-- when a "toolanim" value appears in the held tool
local function swing(tool: Tool?, kind: string?)
	if tool and tool.Parent and HeroMotion.act(tool.Parent, tool:GetAttribute("Kind")) then
		return
	end
	if tool and tool.Parent then
		local v = Instance.new("StringValue")
		v.Name = "toolanim"
		v.Value = kind or "Slash"
		v.Parent = tool
	end
end

-- how many times the recipe's inputs are in the bag (math.huge for plain gathering)
local function timesAffordable(data, info): number
	if not info.inputs then
		return math.huge
	end
	local n = math.huge
	for id, need in info.inputs do
		n = math.min(n, math.floor((data.inv[id] or 0) / need))
	end
	return n
end

local function missingText(info): string
	local parts = {}
	for id, need in info.inputs do
		table.insert(parts, ("%d %s"):format(need, Items[id].name))
	end
	return table.concat(parts, " + ")
end

-- reason: "player" (pressed stop), "moved", "switch", "leave", "dead", "nomats"
-- only "leave" keeps data.activity, so leaving while gathering keeps earning offline
-- (dying clears it: otherwise you could die at a node, walk off and still earn offline)
function GatherService.stop(player: Player, reason: string?)
	local st = active[player]
	if not st then
		return
	end
	active[player] = nil
	if reason ~= "leave" then
		local data = DataService.get(player)
		if data and reason ~= "switch" then
			data.activity = nil
		end
		clearTools(player)
		if reason ~= "switch" then
			Remotes.ActionState:FireClient(player, { active = false, reason = reason })
		end
	end
end

local function grant(player: Player, st)
	local info = G.node(st.skill, st.tier)
	local data = DataService.get(player)
	if not data then
		return
	end
	if info.inputs then
		for id, need in info.inputs do
			DataService.addItem(player, id, -need)
		end
	end
	local out = info.out or 1
	-- every House Level adds 1% XP
	local xp = info.xp * HouseGrid.xpMultiplier(data.home.rooms)
	local before, after = DataService.addXp(player, st.skill, xp)
	DataService.addItem(player, info.item, out)
	data.stats.actions += 1
	if info.inputs then
		data.stats.made[info.item] = (data.stats.made[info.item] or 0) + out
	end
	-- now and then a seed turns up while gathering (better nodes, rarer seeds)
	if not info.inputs and seedRng:NextNumber() < SEED_CHANCE then
		local seed = Farming.dropFor(st.tier or 0, seedRng)
		if seed then
			local n = seedRng:NextInteger(1, 2)
			DataService.addItem(player, seed, n)
			Remotes.Notify:FireClient(player, ("🌱 You found %d × %s!"):format(n, Items[seed].name), "good")
		end
	end
	DataService.sync(player)
	Remotes.Gathered:FireClient(player, {
		node = st.node,
		skill = st.skill,
		xp = math.floor(xp + 0.5),
		item = info.item,
		count = out,
		levelUp = after > before and after or nil,
	})
end

-- tier: only for workbenches, where the player picks the recipe; other nodes carry their own tier
-- for fights (CombatService): hold the sword, and play a swing
function GatherService.equipWeapon(player: Player)
	clearTools(player)
	local data = DataService.get(player)
	-- everyone has at least the wooden training sword (-1)
	local w = data and data.gear and data.gear.weapon or -1
	if player.Character then
		local tool = ToolFactory.make("sword", w)
		tool.Parent = player.Character
	end
end

function GatherService.isGathering(player: Player): boolean
	return active[player] ~= nil
end

function GatherService.swing(player: Player, kind: string?)
	local char = player.Character
	for _, t in char and char:GetChildren() or {} do
		if t:IsA("Tool") and t:GetAttribute("EndlessRoadTool") then
			swing(t, kind)
		end
	end
end

GatherService.onStart = function(_player) end -- set by CombatService: gathering ends a fight

function GatherService.start(player: Player, node: Model, tier: number?)
	local data = DataService.get(player)
	if not data or not node or not node.Parent then
		return
	end
	local skill = node:GetAttribute("Skill")
	if skill ~= "construction" then
		tier = node:GetAttribute("Tier")
	end
	local info = skill and type(tier) == "number" and G.node(skill, tier)
	if not info then
		return
	end
	local current = active[player]
	if current and current.node == node and current.tier == tier then
		return
	end
	local lvl = DataService.level(player, skill)
	if lvl < info.req then
		Remotes.Notify:FireClient(player, ("You need %s level %d to %s %s."):format(Skills.byId[skill].name, info.req, G.VERB[skill]:lower(), skill == "construction" and info.name or "here"), "warn")
		return
	end
	if timesAffordable(data, info) < 1 then
		Remotes.Notify:FireClient(player, ("You need %s to make %s."):format(missingText(info), info.name), "warn")
		return
	end
	local hrp = root(player)
	if not hrp or flatDist(hrp.Position, node.PrimaryPart.Position) > MAX_DIST then
		return
	end
	if current then
		GatherService.stop(player, "switch")
	end
	GatherService.onStart(player)

	local st = { token = {}, node = node, skill = skill, tier = tier }
	active[player] = st
	data.activity = { skill = skill, tier = tier }

	-- turn to face the node
	local target = node.PrimaryPart.Position
	hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(target.X, hrp.Position.Y, target.Z))
	local tool = equip(player, skill)

	task.spawn(function()
		while active[player] == st do
			if timesAffordable(data, info) < 1 then
				Remotes.Notify:FireClient(player, ("Out of materials for %s."):format(info.name), "warn")
				GatherService.stop(player, "nomats")
				return
			end
			local duration = G.actionTime(skill, tier, data.tools[G.TOOL_OF[skill]], data.home.rooms)
			Remotes.ActionState:FireClient(player, {
				active = true, node = node, skill = skill, tier = tier,
				name = info.name, item = info.item, duration = duration,
			})
			local elapsed, sinceSwing = 0, SWING_EVERY
			while elapsed < duration do
				if sinceSwing >= SWING_EVERY and skill ~= "fishing" then
					swing(tool)
					sinceSwing = 0
				end
				local dt = task.wait(0.2)
				elapsed += dt
				sinceSwing += dt
				if active[player] ~= st then
					return
				end
				if not player.Parent then
					return -- leaving: keep data.activity so offline progress continues
				end
				local r = root(player)
				if not r then
					GatherService.stop(player, "dead")
					return
				end
				if flatDist(r.Position, target) > MAX_DIST then
					GatherService.stop(player, "moved")
					return
				end
				if not tool.Parent then
					tool = equip(player, skill) -- character reset / tool removed
				end
			end
			grant(player, st)
			if skill == "fishing" then
				swing(tool)
			end
		end
	end)
end

-- ===== idle: progress while away =====
local function applyOffline(player: Player, data, seconds: number)
	local act = data.activity
	if not act or seconds < G.OFFLINE_MIN then
		return
	end
	local info = G.node(act.skill, act.tier)
	if not info or XP.levelFromXp(data.skills[act.skill] or 0) < info.req then
		data.activity = nil
		return
	end
	local cap = G.offlineCap(data.home.rooms)
	local counted = math.min(seconds, cap)
	local each = G.actionTime(act.skill, act.tier, data.tools[G.TOOL_OF[act.skill]], data.home.rooms)
	-- a workbench stops when the materials run out
	local n = math.min(math.floor(counted / each), timesAffordable(data, info))
	-- they are no longer standing at the node
	data.activity = nil
	if n <= 0 then
		return
	end
	if info.inputs then
		for id, need in info.inputs do
			data.inv[id] -= need * n
			if data.inv[id] <= 0 then
				data.inv[id] = nil
			end
		end
	end
	local out = n * (info.out or 1)
	local before = XP.levelFromXp(data.skills[act.skill])
	local xp = math.floor(n * info.xp * HouseGrid.xpMultiplier(data.home.rooms))
	data.skills[act.skill] = math.min(data.skills[act.skill] + xp, 200000000)
	local after = XP.levelFromXp(data.skills[act.skill])
	data.inv[info.item] = (data.inv[info.item] or 0) + out
	data.stats.actions += n
	if info.inputs then
		data.stats.made[info.item] = (data.stats.made[info.item] or 0) + out
	end
	data.stats.offlineSeconds += counted
	task.delay(2, function()
		if player.Parent then
			Remotes.Offline:FireClient(player, {
				seconds = seconds, counted = counted, cap = cap,
				skill = act.skill, verb = G.VERB_ING[act.skill], node = info.name,
				actions = out, xp = xp, item = info.item, itemName = Items[info.item].name,
				levelBefore = before, levelAfter = after,
				ranOut = info.inputs ~= nil and n < math.floor(counted / each),
			})
		end
	end)
end

-- hook up a node made after start (house rooms)
function GatherService.attach(node: Model)
	local prompt = node.PrimaryPart and node.PrimaryPart:FindFirstChild("GatherPrompt")
	if prompt then
		prompt.Triggered:Connect(function(player)
			GatherService.start(player, node)
		end)
	end
end

function GatherService.init(nodes)
	for _, node in nodes do
		local prompt = node.PrimaryPart:FindFirstChild("GatherPrompt")
		if prompt then
			prompt.Triggered:Connect(function(player)
				GatherService.start(player, node)
			end)
		end
	end

	DataService.onLoaded(applyOffline)
	DataService.onBeforeLeave(function(player)
		GatherService.stop(player, "leave")
	end)

	local function watch(player: Player)
		player.CharacterRemoving:Connect(function()
			if active[player] and player.Parent then
				GatherService.stop(player, "dead")
			end
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, p in Players:GetPlayers() do
		watch(p)
	end
end

function GatherService.isActive(player: Player): boolean
	return active[player] ~= nil
end

return GatherService
