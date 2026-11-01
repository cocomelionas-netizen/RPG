-- Player saves: DataStoreService with session locking (UpdateAsync), autosave and BindToClose.
-- If DataStores are not available (unpublished place / Studio API access off) it keeps data in memory only.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Skills = require(Shared.Skills)
local XP = require(Shared.XP)
local Items = require(Shared.Items)
local Construction = require(Shared.Construction)
local Goals = require(Shared.Goals)
local Remotes = require(Shared.Remotes)

local DataService = {}

local STORE_NAME = "EndlessRoad_v1"
local AUTOSAVE_EVERY = 60 -- seconds
local LOCK_EXPIRE = 300 -- a lock older than this (no autosave refreshed it) is treated as abandoned
local LOAD_RETRIES = 8
local LOAD_RETRY_WAIT = 4
local DATA_VERSION = 1

local store = nil
local memoryOnly = false
local profiles = {} -- [Player] = data
local saving = {} -- [Player] = true while a save runs
local beforeLeave = {} -- callbacks run before the final save (e.g. stop gathering)

local onLoaded = {} -- callbacks (player, data, offlineSeconds) run once a save is loaded

local function jobId(): string
	-- in Studio JobId is empty; give the session its own id so locks still work
	if game.JobId == "" then
		if not DataService._studioId then
			DataService._studioId = "studio-" .. tostring(math.random(1, 1e9))
		end
		return DataService._studioId
	end
	return game.JobId
end

local function defaultData()
	local skills = {}
	for _, s in Skills.LIST do
		skills[s.id] = 0
	end
	return {
		version = DATA_VERSION,
		skills = skills,
		inv = {},
		gold = 0,
		tools = { axe = 0, pick = 0, rod = 0 },
		home = { rooms = {} }, -- [roomId] = level 1..5
		activity = nil, -- { skill, tier } while gathering: used for offline progress
		lastSeen = 0,
		created = os.time(),
		stats = { actions = 0, offlineSeconds = 0, sold = 0, homeTrips = 0, made = {} },
		goal = 1, -- index into Goals.LIST: the next-goal guide
	}
end

-- fill in anything missing (new fields added in later versions) and drop junk
local function reconcile(data)
	local def = defaultData()
	if type(data) ~= "table" then
		return def
	end
	for k, v in def do
		if data[k] == nil then
			data[k] = v
		end
	end
	for _, s in Skills.LIST do
		if type(data.skills[s.id]) ~= "number" then
			data.skills[s.id] = 0
		end
	end
	for id, n in data.inv do
		if not Items[id] or type(n) ~= "number" or n <= 0 then
			data.inv[id] = nil
		end
	end
	for t, _ in def.tools do
		if type(data.tools[t]) ~= "number" then
			data.tools[t] = 0
		end
	end
	if type(data.home) ~= "table" or type(data.home.rooms) ~= "table" then
		data.home = def.home
	end
	for id, t in data.home.rooms do
		if not Construction.byId[id] or type(t) ~= "number" then
			data.home.rooms[id] = nil
		end
	end
	for k, v in def.stats do
		if data.stats[k] == nil then
			data.stats[k] = v
		end
	end
	if type(data.goal) ~= "number" then
		data.goal = 1
	end
	data.version = DATA_VERSION
	return data
end

local function keyFor(player: Player): string
	return "p_" .. player.UserId
end

local function initStore()
	local ok, err = pcall(function()
		store = DataStoreService:GetDataStore(STORE_NAME)
		store:GetAsync("__probe") -- fails in Studio if API access is off
	end)
	if not ok then
		memoryOnly = true
		warn("[Endless Road] DataStores unavailable, progress will NOT be saved: " .. tostring(err))
		if RunService:IsStudio() then
			warn("[Endless Road] Publish the place and turn on Game Settings > Security > Enable Studio Access to API Services.")
		end
	end
end

-- client view of the save (no lock / internal fields)
function DataService.view(data)
	return {
		skills = data.skills, inv = data.inv, gold = data.gold, tools = data.tools, rooms = data.home.rooms,
		stats = { sold = data.stats.sold, homeTrips = data.stats.homeTrips, made = data.stats.made }, goal = data.goal,
		memoryOnly = memoryOnly,
	}
end

-- finished next-goal steps pay out a little gold and move the guide on
local function advanceGoals(player: Player, data)
	while Goals.LIST[data.goal] and Goals.done(data.goal, DataService.view(data)) do
		local g = Goals.LIST[data.goal]
		data.goal += 1
		data.gold += g.reward
		Remotes.Notify:FireClient(player, ("Goal complete: %s  +%d gold"):format(g.text, g.reward), "goal")
	end
end

function DataService.sync(player: Player)
	local data = profiles[player]
	if data then
		advanceGoals(player, data)
		DataService.refreshLeaderstats(player)
		Remotes.DataSync:FireClient(player, DataService.view(data))
	end
end

local function totalLevel(data): number
	local t = 0
	for _, s in Skills.LIST do
		t += XP.levelFromXp(data.skills[s.id])
	end
	return t
end

local function setupLeaderstats(player: Player, data)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	local total = Instance.new("IntValue")
	total.Name = "Total Lv"
	total.Value = totalLevel(data)
	total.Parent = ls
	local gold = Instance.new("IntValue")
	gold.Name = "Gold"
	gold.Value = data.gold
	gold.Parent = ls
	ls.Parent = player
end

function DataService.refreshLeaderstats(player: Player)
	local data = profiles[player]
	local ls = player:FindFirstChild("leaderstats")
	if data and ls then
		ls["Total Lv"].Value = totalLevel(data)
		ls.Gold.Value = data.gold
	end
end

-- ===== load with session lock =====
local function load(player: Player)
	if memoryOnly then
		return reconcile(nil)
	end
	local key = keyFor(player)
	for attempt = 1, LOAD_RETRIES do
		local lockedBy = nil
		local result = nil
		local ok, err = pcall(function()
			store:UpdateAsync(key, function(old)
				local data = reconcile(old)
				local lock = data.lock
				if lock and lock.jobId ~= jobId() and os.time() - (lock.time or 0) < LOCK_EXPIRE then
					lockedBy = lock.jobId
					return nil -- leave the save untouched: another server still has it open
				end
				data.lock = { jobId = jobId(), time = os.time() }
				result = data
				return data
			end)
		end)
		if ok and result then
			return result
		end
		if not ok then
			warn(("[Endless Road] load failed for %s (try %d): %s"):format(player.Name, attempt, tostring(err)))
		end
		if not player.Parent then
			return nil
		end
		task.wait(LOAD_RETRY_WAIT)
	end
	return nil
end

-- ===== save; release = true drops the lock (player left) =====
function DataService.save(player: Player, release: boolean?)
	local data = profiles[player]
	if not data or memoryOnly then
		return true
	end
	while saving[player] do
		task.wait(0.1)
	end
	saving[player] = true
	local key = keyFor(player)
	local success = false
	for attempt = 1, 3 do
		local lost = false
		local ok, err = pcall(function()
			store:UpdateAsync(key, function(old)
				if old and old.lock and old.lock.jobId ~= jobId() then
					lost = true -- someone else took the save over; never overwrite them
					return nil
				end
				data.lastSeen = os.time()
				data.lock = (not release) and { jobId = jobId(), time = os.time() } or nil
				return data
			end)
		end)
		if ok then
			success = not lost
			if lost then
				warn("[Endless Road] lost session lock for " .. player.Name)
			end
			break
		end
		warn(("[Endless Road] save failed for %s (try %d): %s"):format(player.Name, attempt, tostring(err)))
		task.wait(2 ^ attempt)
	end
	saving[player] = nil
	return success
end

-- ===== API used by the game =====
function DataService.get(player: Player)
	return profiles[player]
end

function DataService.isMemoryOnly(): boolean
	return memoryOnly
end

function DataService.onLoaded(fn)
	table.insert(onLoaded, fn)
end

function DataService.onBeforeLeave(fn)
	table.insert(beforeLeave, fn)
end

-- returns old level, new level
function DataService.addXp(player: Player, skill: string, amount: number): (number, number)
	local data = profiles[player]
	if not data or data.skills[skill] == nil then
		return 1, 1
	end
	local before = XP.levelFromXp(data.skills[skill])
	data.skills[skill] = math.min(data.skills[skill] + amount, 200000000)
	local after = XP.levelFromXp(data.skills[skill])
	if after ~= before then
		DataService.refreshLeaderstats(player)
	end
	return before, after
end

function DataService.level(player: Player, skill: string): number
	local data = profiles[player]
	return data and XP.levelFromXp(data.skills[skill] or 0) or 1
end

function DataService.addItem(player: Player, id: string, n: number)
	local data = profiles[player]
	if not data or not Items[id] then
		return
	end
	data.inv[id] = (data.inv[id] or 0) + n
	if data.inv[id] <= 0 then
		data.inv[id] = nil
	end
end

function DataService.addGold(player: Player, n: number)
	local data = profiles[player]
	if data then
		data.gold = math.max(0, data.gold + n)
		DataService.refreshLeaderstats(player)
	end
end

-- ===== lifecycle =====
local function onPlayerAdded(player: Player)
	local data = load(player)
	if not player.Parent then
		if data and not memoryOnly then
			-- left while loading: give the lock back
			profiles[player] = data
			DataService.save(player, true)
			profiles[player] = nil
		end
		return
	end
	if not data then
		player:Kick("Your save is still open in another server. Please wait a minute and rejoin.")
		return
	end
	local offline = 0
	if data.lastSeen and data.lastSeen > 0 then
		offline = math.max(0, os.time() - data.lastSeen)
	end
	profiles[player] = data
	for _, fn in onLoaded do
		local ok, err = pcall(fn, player, data, offline)
		if not ok then
			warn("[Endless Road] onLoaded: " .. tostring(err))
		end
	end
	setupLeaderstats(player, data) -- after onLoaded, so offline levels are counted
	DataService.sync(player)
	if memoryOnly then
		Remotes.Notify:FireClient(player, "Test mode: saving is off (DataStores unavailable).", "warn")
	end
end

local function onPlayerRemoving(player: Player)
	if not profiles[player] then
		return
	end
	for _, fn in beforeLeave do
		pcall(fn, player)
	end
	DataService.save(player, true)
	profiles[player] = nil
end

function DataService.start()
	initStore()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, p in Players:GetPlayers() do
		task.spawn(onPlayerAdded, p)
	end

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_EVERY)
			for player in profiles do
				task.spawn(DataService.save, player, false)
			end
		end
	end)

	game:BindToClose(function()
		if memoryOnly then
			return
		end
		local pending = 0
		for player in profiles do
			pending += 1
			task.spawn(function()
				for _, fn in beforeLeave do
					pcall(fn, player)
				end
				DataService.save(player, true)
				pending -= 1
			end)
		end
		local t0 = os.clock()
		while pending > 0 and os.clock() - t0 < 25 do
			task.wait(0.1)
		end
	end)
end

return DataService
