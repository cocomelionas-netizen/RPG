-- Endless Road: builds the starter town, hands out the longsword and runs combat.
local World = require(script.Parent.World)
local Sword = require(script.Parent.Sword)
local Combat = require(script.Parent.Combat)

World.build()
Sword.init()
Combat.init()
