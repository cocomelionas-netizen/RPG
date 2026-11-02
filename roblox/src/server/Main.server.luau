-- Endless Road (Roblox) – server entry point
local ReplicatedStorage = game:GetService("ReplicatedStorage")
require(ReplicatedStorage:WaitForChild("Shared").Remotes) -- creates the RemoteEvents first

local DataService = require(script.Parent.DataService)
local WorldBuilder = require(script.Parent.WorldBuilder)
local GatherService = require(script.Parent.GatherService)
local HomeService = require(script.Parent.HomeService)
local FarmService = require(script.Parent.FarmService)
local CombatService = require(script.Parent.CombatService)
local ShopService = require(script.Parent.ShopService)
local TravelService = require(script.Parent.TravelService)
local HeroMotion = require(script.Parent.HeroMotion)

local nodes = WorldBuilder.build()
HomeService.buildTown(workspace.World)
GatherService.init(nodes)
HomeService.init()
FarmService.init()
CombatService.init(workspace.World)
TravelService.init(workspace.World)
HeroMotion.init()
ShopService.init()
DataService.start() -- last: loads players that are already in the game
print(("[Endless Road] server ready: %d resource nodes"):format(#nodes))
