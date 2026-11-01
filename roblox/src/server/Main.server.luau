-- Endless Road (Roblox) – server entry point
local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage:WaitForChild("Shared").Remotes) -- creates the RemoteEvents first

local DataService = require(script.Parent.DataService)
local WorldBuilder = require(script.Parent.WorldBuilder)
local GatherService = require(script.Parent.GatherService)
local HomeService = require(script.Parent.HomeService)
local ShopService = require(script.Parent.ShopService)

local nodes = WorldBuilder.build(-HomeService.TOWN_LENGTH)
HomeService.buildTown(workspace.World)
GatherService.init(nodes)
HomeService.init()
ShopService.init()
DataService.start() -- last: loads players that are already in the game
print(("[Endless Road] server ready: %d resource nodes"):format(#nodes))
