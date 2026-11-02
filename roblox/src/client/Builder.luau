-- Room placement: the camera looks down on the player's plot and every cell the room may go on lights up green
-- (same rules as the server: HouseGrid.canPlace). Tap or click a green cell to put the room there.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HouseGrid = require(Shared.HouseGrid)
local Construction = require(Shared.Construction)

local player = Players.LocalPlayer
local Builder = {}

local active = nil -- { roomId, tiles, conn, gui, camera state }

local function myPlot()
	local town = workspace:FindFirstChild("World") and workspace.World:FindFirstChild("Hometown")
	for _, plot in town and town.Plots:GetChildren() or {} do
		if plot:GetAttribute("Owner") == player.UserId then
			return plot
		end
	end
	return nil
end

local function roomName(id)
	if id == HouseGrid.START then
		return "🏡 Entrance Hall"
	end
	local r = Construction.byId[id]
	return r and (r.icon .. " " .. r.name) or id
end

function Builder.stop()
	if not active then
		return
	end
	for _, c in active.conns do
		c:Disconnect()
	end
	active.folder:Destroy()
	active.gui:Destroy()
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Custom
	active = nil
end

-- view: the DataSync view (layout); request: function(action, ...) to the server
function Builder.start(roomId: string, view, request)
	Builder.stop()
	local plot = myPlot()
	local lawn = plot and plot:FindFirstChild("Lawn")
	if not lawn then
		return
	end
	local center = Vector3.new(lawn.Position.X, 0, lawn.Position.Z)
	local layout = view and view.layout or {}

	local folder = Instance.new("Folder")
	folder.Name = "PlacementTiles"
	local tiles = {}
	local green = Color3.fromRGB(90, 230, 110)
	for x = 0, HouseGrid.SIZE - 1 do
		for z = 0, HouseGrid.SIZE - 1 do
			if HouseGrid.canPlace(layout, roomId, x, z) then
				local t = Instance.new("Part")
				t.Name = ("Cell_%d_%d"):format(x, z)
				t.Anchored = true
				t.CanCollide = false
				t.CanTouch = false
				t.Material = Enum.Material.Neon
				t.Color = green
				t.Transparency = 0.45
				t.Size = Vector3.new(HouseGrid.CELL - 2, 0.3, HouseGrid.CELL - 2)
				t.CFrame = CFrame.new(center + HouseGrid.cellOffset(x, z) + Vector3.new(0, 0.6, 0))
				t:SetAttribute("CellX", x)
				t:SetAttribute("CellZ", z)
				t.Parent = folder
				table.insert(tiles, t)
			end
		end
	end
	folder.Parent = workspace

	-- bird's-eye view over the plot
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	local goal = CFrame.lookAt(center + Vector3.new(-70, 150, 0), center)
	TweenService:Create(cam, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { CFrame = goal }):Play()

	-- instruction bar with a cancel button
	local gui = Instance.new("ScreenGui")
	gui.Name = "Placement"
	gui.DisplayOrder = 10
	gui.ResetOnSpawn = false
	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 0, 1, -16)
	bar.Size = UDim2.fromOffset(460, 70)
	bar.BackgroundColor3 = Color3.fromRGB(24, 22, 38)
	bar.BackgroundTransparency = 0.05
	bar.Parent = gui
	Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 14)
	local st = Instance.new("UIStroke", bar)
	st.Color = green
	st.Thickness = 2
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(14, 0)
	label.Size = UDim2.new(1, -140, 1, 0)
	label.Font = Enum.Font.FredokaOne
	label.TextSize = 18
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = #tiles > 0 and ("Tap a green square to place " .. roomName(roomId)) or "No free spot next to your house – move a room first."
	label.Parent = bar
	local cancel = Instance.new("TextButton")
	cancel.Name = "Cancel"
	cancel.AnchorPoint = Vector2.new(1, 0.5)
	cancel.Position = UDim2.new(1, -12, 0.5, 0)
	cancel.Size = UDim2.fromOffset(110, 46)
	cancel.BackgroundColor3 = Color3.fromRGB(210, 70, 70)
	cancel.Font = Enum.Font.FredokaOne
	cancel.TextSize = 20
	cancel.TextColor3 = Color3.new(1, 1, 1)
	cancel.Text = "Cancel"
	cancel.Parent = bar
	Instance.new("UICorner", cancel).CornerRadius = UDim.new(0, 10)
	gui.Parent = player:WaitForChild("PlayerGui")

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { folder }
	local function tileAt(screen: Vector2)
		local ray = cam:ViewportPointToRay(screen.X, screen.Y)
		local hit = workspace:Raycast(ray.Origin, ray.Direction * 600, params)
		return hit and hit.Instance
	end

	local conns = {}
	local hovered = nil
	table.insert(conns, cancel.Activated:Connect(Builder.stop))
	table.insert(conns, UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			local t = tileAt(Vector2.new(input.Position.X, input.Position.Y))
			if hovered and hovered ~= t then
				hovered.Transparency = 0.45
			end
			hovered = t
			if t then
				t.Transparency = 0.1
			end
		end
	end))
	table.insert(conns, UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			local t = tileAt(Vector2.new(input.Position.X, input.Position.Y))
			if t then
				request("place", roomId, t:GetAttribute("CellX"), t:GetAttribute("CellZ"))
				Builder.stop()
			end
		end
	end))
	active = { roomId = roomId, folder = folder, gui = gui, conns = conns }
end

function Builder.isActive(): boolean
	return active ~= nil
end

return Builder
