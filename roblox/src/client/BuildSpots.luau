-- Build spots: glowing ➕ pads on the player's own plot, made on the client so only the owner sees them.
-- Before the house is started every cell is a spot; after that only the free cells next to the house (HouseGrid rules).
-- Walking onto a pad, or its "Build here" prompt, asks what to build there.
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HouseGrid = require(Shared.HouseGrid)
local Construction = require(Shared.Construction)

local player = Players.LocalPlayer
local BuildSpots = {}

local folder = Instance.new("Folder")
folder.Name = "BuildSpots"
local onPick = function(_x: number, _z: number) end
local lastKey = nil
local lastView = nil

local function myPlot()
	local town = workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Hometown")
	for _, plot in town and town.Plots:GetChildren() or {} do
		if plot:GetAttribute("Owner") == player.UserId and plot:FindFirstChild("Lawn") then
			return plot
		end
	end
	return nil
end

-- is there anything new left to build? (otherwise no pads once the house is started)
local function anythingToBuild(layout): boolean
	if not layout[HouseGrid.START] then
		return true
	end
	for _, r in Construction.ROOMS do
		if not layout[r.id] then
			return true
		end
	end
	return false
end

local function makePad(center: Vector3, x: number, z: number, starting: boolean)
	local pad = Instance.new("Part")
	pad.Name = ("Spot_%d_%d"):format(x, z)
	pad.Anchored = true
	pad.CanCollide = false
	pad.CanQuery = true
	pad.CanTouch = true
	pad.Material = Enum.Material.Neon
	pad.Color = starting and Color3.fromRGB(255, 205, 70) or Color3.fromRGB(110, 235, 130)
	pad.Transparency = starting and 0.75 or 0.55
	pad.Size = Vector3.new(HouseGrid.CELL - 3, 0.3, HouseGrid.CELL - 3)
	pad.CFrame = CFrame.new(center + HouseGrid.cellOffset(x, z) + Vector3.new(0, 0.35, 0))
	pad:SetAttribute("CellX", x)
	pad:SetAttribute("CellZ", z)

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(5, 5)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 3, 0)
	bb.MaxDistance = starting and 60 or 120
	bb.LightInfluence = 0
	local plus = Instance.new("TextLabel")
	plus.BackgroundColor3 = pad.Color:Lerp(Color3.new(0, 0, 0), 0.35)
	plus.Size = UDim2.fromScale(1, 1)
	plus.Font = Enum.Font.FredokaOne
	plus.Text = "+"
	plus.TextScaled = true
	plus.TextColor3 = Color3.new(1, 1, 1)
	plus.Parent = bb
	Instance.new("UICorner", plus).CornerRadius = UDim.new(0.5, 0)
	local ring = Instance.new("UIStroke", plus)
	ring.Color = Color3.new(1, 1, 1)
	ring.Thickness = 3
	ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border -- ring round the disc, not an outline on the "+"
	bb.Parent = pad
	-- gentle bob so the spots catch the eye
	TweenService:Create(bb, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { StudsOffsetWorldSpace = Vector3.new(0, 4, 0) }):Play()

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = starting and "Start house here" or "Build here"
	prompt.ObjectText = "Build spot"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = pad
	prompt.Triggered:Connect(function()
		onPick(x, z)
	end)
	pad.Touched:Connect(function(hit)
		local char = player.Character
		if char and hit:IsDescendantOf(char) then
			local k = x .. "," .. z
			if lastKey ~= k then
				lastKey = k
				onPick(x, z)
			end
		end
	end)
	pad.TouchEnded:Connect(function(hit)
		local char = player.Character
		if char and hit:IsDescendantOf(char) then
			-- stepping off and back on asks again
			task.delay(1, function()
				if lastKey == x .. "," .. z then
					lastKey = nil
				end
			end)
		end
	end)
	pad.Parent = folder
end

-- rebuild the pads for the current layout
function BuildSpots.refresh(view)
	lastView = view or lastView
	folder:ClearAllChildren()
	local plot = myPlot()
	if not plot or not lastView then
		return
	end
	local layout = lastView.layout or {}
	if not anythingToBuild(layout) then
		return
	end
	local starting = not layout[HouseGrid.START]
	-- any new room uses the same rule, so check with a room that isn't placed yet
	local probe = starting and HouseGrid.START or "__new"
	local lawn = plot.Lawn
	local center = Vector3.new(lawn.Position.X, 0, lawn.Position.Z)
	for x = 0, HouseGrid.SIZE - 1 do
		for z = 0, HouseGrid.SIZE - 1 do
			if HouseGrid.canPlace(layout, probe, x, z) then
				makePad(center, x, z, starting)
			end
		end
	end
	folder.Parent = workspace
end

-- forget the last pad stepped on (after the menu closes), so stepping on it again asks again
function BuildSpots.reset()
	lastKey = nil
end

function BuildSpots.init(pick)
	onPick = pick
	-- the plot streams in and out: refresh when the hero gets near it
	task.spawn(function()
		local had = false
		while true do
			local has = myPlot() ~= nil
			if has ~= had then
				had = has
				BuildSpots.refresh()
			end
			task.wait(1)
		end
	end)
end

return BuildSpots
