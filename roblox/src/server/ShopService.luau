-- Client requests: sell items, upgrade tools, stop gathering. Everything is validated here.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local G = require(Shared.Gathering)
local Items = require(Shared.Items)
local Construction = require(Shared.Construction)
local Remotes = require(Shared.Remotes)
local DataService = require(script.Parent.DataService)
local GatherService = require(script.Parent.GatherService)
local HomeService = require(script.Parent.HomeService)

local ShopService = {}

local lastRequest = {} -- [Player] = os.clock(), simple spam guard

local function fmt(n: number): string
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

-- gold for n of an item, with the Treasury bonus
local function worth(data, it, n: number): number
	return math.floor(n * it.value * (1 + Construction.bonus(data.home.rooms, "sell") / 100))
end

local function sell(player: Player, id, amount)
	local data = DataService.get(player)
	if type(id) ~= "string" or not Items[id] or not data then
		return
	end
	local have = data.inv[id] or 0
	local n = amount == "all" and have or tonumber(amount)
	if not n or n ~= n then
		return
	end
	n = math.clamp(math.floor(n), 0, have)
	if n <= 0 then
		return
	end
	local gold = worth(data, Items[id], n)
	DataService.addItem(player, id, -n)
	DataService.addGold(player, gold)
	data.stats.sold += 1
	DataService.sync(player)
	Remotes.Notify:FireClient(player, ("Sold %d × %s for %s gold"):format(n, Items[id].name, fmt(gold)), "gold")
end

local function sellAll(player: Player)
	local data = DataService.get(player)
	if not data then
		return
	end
	local gold, count = 0, 0
	for id, n in data.inv do
		local it = Items[id]
		if it and (it.type == "Resources" or it.type == "Ores") then
			gold += worth(data, it, n)
			count += n
			data.inv[id] = nil
		end
	end
	if count == 0 then
		return
	end
	DataService.addGold(player, gold)
	data.stats.sold += 1
	DataService.sync(player)
	Remotes.Notify:FireClient(player, ("Sold %d resources for %s gold"):format(count, fmt(gold)), "gold")
end

local function upgrade(player: Player, tool)
	local data = DataService.get(player)
	if not data or type(tool) ~= "string" or not table.find(G.TOOL_ORDER, tool) then
		return
	end
	local lvl = data.tools[tool]
	if lvl >= G.TOOL_MAX then
		return
	end
	local cost = G.TOOL_COST[lvl]
	if data.gold < cost then
		Remotes.Notify:FireClient(player, "Not enough gold.", "warn")
		return
	end
	DataService.addGold(player, -cost)
	data.tools[tool] = lvl + 1
	DataService.sync(player)
	Remotes.Notify:FireClient(player, ("Upgraded to %s! 12%% faster."):format(G.toolName(tool, lvl + 1)), "good")
end

function ShopService.init()
	Remotes.Request.OnServerEvent:Connect(function(player, action, a, b, c)
		local now = os.clock()
		if lastRequest[player] and now - lastRequest[player] < 0.1 then
			return
		end
		lastRequest[player] = now
		if action == "sell" then
			sell(player, a, b)
		elseif action == "sellAll" then
			sellAll(player)
		elseif action == "upgrade" then
			upgrade(player, a)
		elseif action == "stop" then
			GatherService.stop(player, "player")
		elseif action == "craft" then
			HomeService.craft(player, a)
		elseif action == "build" then
			HomeService.build(player, a)
		elseif action == "buildAt" then
			HomeService.buildAt(player, a, b, c)
		elseif action == "home" then
			HomeService.teleport(player, a == "road" and "road" or "home")
		end
	end)
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		lastRequest[player] = nil
	end)
end

return ShopService
