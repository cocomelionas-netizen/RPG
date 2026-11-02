-- Tap (or click) to act, like OSRS: tap a tree, rock, fishing spot, monster, patch or station and the hero walks
-- over and starts; tap the ground and the hero walks there. Works through the objects' own ProximityPrompts, so the
-- server rules stay the same as pressing the prompt. Drags (turning the camera) are not taps.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Interact = {}

local TAP_MOVE = 12 -- pixels a finger may move and still count as a tap
local TAP_TIME = 0.35
local job = 0 -- bumps on every new tap, so an older walk gives up

-- the prompt that belongs to whatever was tapped: look on the part and up through its models
local function promptFor(hit: Instance)
	local node = hit
	for _ = 1, 4 do
		if not node or node:IsA("Folder") or node == workspace then
			return nil
		end
		-- big models (a whole plot) hold many prompts: tapping their lawn is a walk, not an action
		if node:IsA("Model") and #node:GetDescendants() > 160 then
			return nil
		end
		local p = node:FindFirstChildWhichIsA("ProximityPrompt", true)
		if p and p.Enabled then
			return p, node
		end
		node = node.Parent
	end
	return nil
end

local marker = nil
local function showMarker(pos: Vector3, color: Color3)
	if marker then
		marker:Destroy()
	end
	marker = Instance.new("Part")
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanQuery = false
	marker.CanTouch = false
	marker.Shape = Enum.PartType.Cylinder
	marker.Size = Vector3.new(0.15, 3, 3)
	marker.CFrame = CFrame.new(pos + Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90))
	marker.Material = Enum.Material.Neon
	marker.Color = color
	marker.Transparency = 0.3
	marker.Parent = workspace
	local m = marker
	task.delay(0.6, function()
		if marker == m then
			m:Destroy()
			marker = nil
		end
	end)
end

local function flash(model: Instance)
	local h = Instance.new("Highlight")
	h.FillTransparency = 1
	h.OutlineColor = Color3.fromRGB(255, 230, 120)
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Adornee = model
	h.Parent = workspace
	game:GetService("Debris"):AddItem(h, 0.8)
end

-- walk until close enough to use the prompt, then use it
local function goUse(prompt: ProximityPrompt, model: Instance)
	job += 1
	local my = job
	local part = prompt.Parent
	if not part:IsA("BasePart") then
		part = part:FindFirstAncestorWhichIsA("BasePart") or model:FindFirstChildWhichIsA("BasePart", true)
	end
	if not part then
		return
	end
	flash(model)
	local reach = math.max(4, prompt.MaxActivationDistance - 2)
	task.spawn(function()
		local t0 = os.clock()
		while job == my and os.clock() - t0 < 15 do
			local char = player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			if not hum or not hrp or not part.Parent then
				return
			end
			local target = part.Position
			local flat = Vector3.new(target.X - hrp.Position.X, 0, target.Z - hrp.Position.Z)
			if flat.Magnitude <= reach then
				hum:MoveTo(hrp.Position) -- stop walking
				prompt:InputHoldBegin()
				task.wait(0.05)
				prompt:InputHoldEnd()
				return
			end
			-- aim for a spot just short of the object, on the near side
			local stop = target - flat.Unit * (reach - 1.5)
			hum:MoveTo(Vector3.new(stop.X, hrp.Position.Y, stop.Z))
			task.wait(0.25)
		end
	end)
end

local function walkTo(pos: Vector3)
	job += 1
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum:MoveTo(pos)
		showMarker(pos, Color3.fromRGB(255, 255, 255))
	end
end

local function onTap(screen: Vector2)
	local cam = workspace.CurrentCamera
	local ray = cam:ScreenPointToRay(screen.X, screen.Y) -- input positions are screen points (below the top bar)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 500, params)
	if not hit then
		return
	end
	local prompt, model = promptFor(hit.Instance)
	if prompt then
		goUse(prompt, model)
	elseif hit.Normal.Y > 0.6 then
		walkTo(hit.Position)
	end
end

-- on touch screens tapping the object is the way in, so the floating prompt buttons only clutter the screen:
-- hide them (Custom style shows nothing) but keep them working underneath
local function hidePrompts()
	if not (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled) then
		return
	end
	local function hide(d)
		if d:IsA("ProximityPrompt") then
			d.Style = Enum.ProximityPromptStyle.Custom
		end
	end
	for _, d in workspace:GetDescendants() do
		hide(d)
	end
	workspace.DescendantAdded:Connect(hide)
end

function Interact.init()
	hidePrompts()
	-- a tap is a short press that hardly moves (a drag turns the camera instead)
	local downs = {}
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		local t = input.UserInputType
		if t == Enum.UserInputType.Touch or t == Enum.UserInputType.MouseButton1 then
			downs[input] = { pos = Vector2.new(input.Position.X, input.Position.Y), at = os.clock() }
		end
	end)
	UserInputService.InputEnded:Connect(function(input, processed)
		local d = downs[input]
		downs[input] = nil
		if not d or processed then
			return
		end
		local pos = Vector2.new(input.Position.X, input.Position.Y)
		if (pos - d.pos).Magnitude <= TAP_MOVE and os.clock() - d.at <= TAP_TIME then
			onTap(pos)
		end
	end)
	-- walking with the keys or thumbstick cancels a tap-walk
	RunService.Heartbeat:Connect(function()
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum and UserInputService:GetFocusedTextBox() == nil then
			local keys = UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.A)
				or UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.D)
			if keys then
				job += 1
			end
		end
	end)
end

return Interact
