-- Plays the hero's tool animations (Shared.Anims) on the server, so every player sees them: an action (a sword stroke,
-- a chop, a swing, a cast) on request. Holding a tool is no pose of its own: Roblox's Animate script would hold it with
-- the arm straight out in front ("toolnone"), so that is swapped for an empty animation and the arm hangs and swings
-- as it does empty-handed; the tools are gripped for that relaxed hand (ToolFactory). A swing switches the tool to its
-- "ActGrip", straight out of the forearm as the swings were made for, and back to its "HoldGrip" once it is over.
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
	local speed = rng:NextNumber(0.95, 1.08)
	t:Play(0.08, 1, speed)
	local length = (t.Length > 0 and t.Length or 0.9) / speed
	for _, tool in char:GetChildren() do
		if tool:IsA("Tool") and tool:GetAttribute("ActGrip") then
			-- held for the swing; back to the relaxed hold a moment after the last swing ends
			local until_ = os.clock() + length + 0.3
			tool:SetAttribute("ActUntil", until_)
			tool.Grip = tool:GetAttribute("ActGrip")
			task.delay(length + 0.35, function()
				if tool.Parent and tool:GetAttribute("ActUntil") == until_ then
					tool.Grip = tool:GetAttribute("HoldGrip")
				end
			end)
			-- the blade's trail shows while it moves
			local trail = tool:FindFirstChild("Trail", true)
			if trail then
				trail.Enabled = true
				task.delay(0.5, function()
					trail.Enabled = false
				end)
			end
		end
	end
	return true
end

local function watch(char: Model)
	-- the Animate script picks up the change (it listens to its animations), so set it on the server once
	task.spawn(function()
		local animate = char:WaitForChild("Animate", 10)
		local none = animate and animate:WaitForChild("toolnone", 10)
		if not none then
			return
		end
		local id = "rbxassetid://" .. Anims.TOOL_NONE
		local function relax(a: Instance)
			if a:IsA("Animation") and a.AnimationId ~= id then
				a.AnimationId = id
			end
		end
		for _, a in none:GetChildren() do
			relax(a)
		end
		none.ChildAdded:Connect(relax)
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
