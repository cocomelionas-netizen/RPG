-- Woodcutting, mining and fishing: the hero keeps working a node until told to stop or walking away.
-- Also handles offline (idle) progress for whatever the hero was doing when they left.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local G = require(Shared.Gathering)
local Items = require(Shared.Items)
local Skills = require(Shared.Skills)
local XP = require(Shared.XP)
local Remotes = require(Shared.Remotes)
local DataService = require(script.Parent.DataService)
local ToolFactory = require(script.Parent.ToolFactory)

local GatherService = {}

local MAX_DIST = 14 -- studs from the node before the hero counts as having walked away
local SWING_EVERY = 0.9
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

-- the default Animate script plays the tool slash animation when a "toolanim" value appears in the held tool
local function swing(tool: Tool?)
	if tool and tool.Parent then
		local v = Instance.new("StringValue")
		v.Name = "toolanim"
		v.Value = "Slash"
		v.Parent = tool
	end
end

-- reason: "player" (pressed stop), "moved", "switch", "leave", "dead"
-- "leave" and "dead" keep data.activity, so leaving while gathering keeps earning offline
function GatherService.stop(player: Player, reason: string?)
	local st = active[player]
	if not st then
		return
	end
	active[player] = nil
	if reason ~= "leave" then
		local data = DataService.get(player)
		if data and reason ~= "switch" and reason ~= "dead" then
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
	local before, after = DataService.addXp(player, st.skill, info.xp)
	DataService.addItem(player, info.item, 1)
	data.stats.actions += 1
	DataService.sync(player)
	Remotes.Gathered:FireClient(player, {
		node = st.node,
		skill = st.skill,
		xp = info.xp,
		item = info.item,
		levelUp = after > before and after or nil,
	})
end

function GatherService.start(player: Player, node: Model)
	local data = DataService.get(player)
	if not data or not node or not node.Parent then
		return
	end
	local skill, tier = node:GetAttribute("Skill"), node:GetAttribute("Tier")
	local info = skill and G.node(skill, tier)
	if not info then
		return
	end
	local current = active[player]
	if current and current.node == node then
		return
	end
	local lvl = DataService.level(player, skill)
	if lvl < info.req then
		Remotes.Notify:FireClient(player, ("You need %s level %d to %s here."):format(Skills.byId[skill].name, info.req, G.VERB[skill]:lower()), "warn")
		return
	end
	local hrp = root(player)
	if not hrp or flatDist(hrp.Position, node.PrimaryPart.Position) > MAX_DIST then
		return
	end
	if current then
		GatherService.stop(player, "switch")
	end

	local st = { token = {}, node = node, skill = skill, tier = tier }
	active[player] = st
	data.activity = { skill = skill, tier = tier }

	-- turn to face the node
	local target = node.PrimaryPart.Position
	hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(target.X, hrp.Position.Y, target.Z))
	local tool = equip(player, skill)

	task.spawn(function()
		while active[player] == st do
			local duration = G.actionTime(skill, tier, data.tools[G.TOOL_OF[skill]])
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
	local counted = math.min(seconds, G.OFFLINE_CAP)
	local each = G.actionTime(act.skill, act.tier, data.tools[G.TOOL_OF[act.skill]])
	local n = math.floor(counted / each)
	if n <= 0 then
		return
	end
	local before = XP.levelFromXp(data.skills[act.skill])
	data.skills[act.skill] = math.min(data.skills[act.skill] + n * info.xp, 200000000)
	local after = XP.levelFromXp(data.skills[act.skill])
	data.inv[info.item] = (data.inv[info.item] or 0) + n
	data.stats.actions += n
	data.stats.offlineSeconds += counted
	-- they are no longer standing at the node
	data.activity = nil
	task.delay(2, function()
		if player.Parent then
			Remotes.Offline:FireClient(player, {
				seconds = seconds, counted = counted, cap = G.OFFLINE_CAP,
				skill = act.skill, verb = G.VERB_ING[act.skill], node = info.name,
				actions = n, xp = n * info.xp, item = info.item, itemName = Items[info.item].name,
				levelBefore = before, levelAfter = after,
			})
		end
	end)
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
