-- One place for every RemoteEvent. The server creates them, clients wait for them.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local NAMES = {
	"DataSync", -- server -> client: full player state
	"Notify", -- server -> client: short message toast
	"ActionState", -- server -> client: gathering started / next swing / stopped
	"Gathered", -- server -> client: one resource gathered (xp, item, level up)
	"Offline", -- server -> client: offline progress summary
	"Request", -- client -> server: (action, ...) sell / upgrade / stop / craft / build / buildAt / home
	"OpenCraft", -- server -> client: the hero is at a workbench, show the recipe list
}

local Remotes = {}

local folder
if RunService:IsServer() then
	folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	for _, n in NAMES do
		if not folder:FindFirstChild(n) then
			local r = Instance.new("RemoteEvent")
			r.Name = n
			r.Parent = folder
		end
	end
else
	folder = ReplicatedStorage:WaitForChild("Remotes")
end

for _, n in NAMES do
	Remotes[n] = folder:WaitForChild(n)
end

return Remotes
