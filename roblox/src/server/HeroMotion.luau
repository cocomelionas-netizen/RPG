-- Plays the hero's tool animations (Shared.Anims) on the server, so every player sees them: a hold pose for as long
-- as one of our tools is in the hero's hand, and an action (a sword stroke, a chop, a swing, a cast) on request.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Anims = require(ReplicatedStorage:WaitForChild("Shared").Anims)

local HeroMotion = {}

-- per Animator (plain tables: an Instance as a weak key gets dropped while the instance still lives, which loaded
-- every track again and left old holds playing); cleared when the character goes
local tracks = {} -- [Animator] = { [name] = AnimationTrack }
local last = {} -- [Animator] = the action played last (no move twice in a row)
local rng = Random.new()

local function animatorOf(char: Model?)
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	return hum and hum:FindFirstChildOfClass("Animator")
end

local function track(animator: Animator, name: string)
	local id = Anims.IDS[name]
	if not id or id == 0 then
		return nil
	end
	tracks[animator] = tracks[animator] or {}
	local t = tracks[animator][name]
	if not t then
		local anim = Instance.new("Animation")
		anim.AnimationId = "rbxassetid://" .. id
		local ok, loaded = pcall(animator.LoadAnimation, animator, anim)
		if not ok then
			return nil
		end
		t = loaded
		tracks[animator][name] = t
	end
	return t
end

-- stop every hold pose on the animator, whoever started it (the tracks list, not our cache, is the truth)
local HOLD_IDS = {}
for _, name in Anims.HOLD do
	HOLD_IDS["rbxassetid://" .. (Anims.IDS[name] or 0)] = true
end
local function stopHolds(animator: Animator)
	for _, t in animator:GetPlayingAnimationTracks() do
		if t.Animation and HOLD_IDS[t.Animation.AnimationId] then
			t:Stop(0.2)
		end
	end
end

-- an action for the tool in hand; false when there is no animation for it (the caller falls back to Roblox's)
function HeroMotion.act(char: Model?, kind: string): boolean
	local animator = animatorOf(char)
	local list = Anims.ACT[kind]
	if not animator or not list then
		return false
	end
	local name = list[rng:NextInteger(1, #list)]
	if #list > 1 and name == last[animator] then
		name = list[(table.find(list, name) % #list) + 1]
	end
	local t = track(animator, name)
	if not t then
		return false
	end
	last[animator] = name
	t:Play(0.08, 1, rng:NextNumber(0.95, 1.08))
	-- the blade's trail shows while it moves
	for _, c in char:GetChildren() do
		local trail = c:IsA("Tool") and c:FindFirstChild("Handle") and c.Handle:FindFirstChildOfClass("Trail")
		if trail then
			trail.Enabled = true
			task.delay(0.5, function()
				trail.Enabled = false
			end)
		end
	end
	return true
end

-- hold poses follow whatever tool of ours is in the hero's hand
local function watch(char: Model)
	local function update()
		local animator = animatorOf(char)
		if not animator then
			return
		end
		stopHolds(animator)
		for _, c in char:GetChildren() do
			if c:IsA("Tool") and c:GetAttribute("Kind") then
				local t = track(animator, Anims.HOLD[c:GetAttribute("Kind")])
				if t then
					t.Looped = true
					t:Play(0.25)
				end
			end
		end
	end
	char.ChildAdded:Connect(function(c)
		if c:IsA("Tool") then
			update()
		end
	end)
	char.ChildRemoved:Connect(function(c)
		if c:IsA("Tool") then
			update()
		end
	end)
	char.Destroying:Connect(function()
		local animator = animatorOf(char)
		if animator then
			tracks[animator] = nil
			last[animator] = nil
		end
	end)
end

function HeroMotion.init()
	local function hook(p: Player)
		if p.Character then
			watch(p.Character)
		end
		p.CharacterAdded:Connect(watch)
	end
	for _, p in Players:GetPlayers() do
		hook(p)
	end
	Players.PlayerAdded:Connect(hook)
end

return HeroMotion
