-- Sword sounds for every hero on screen: the sword being drawn, and a whoosh on each swing (the server counts swings
-- in the character's "Swing" attribute). The swing itself is Roblox's own tool slash / lunge animation.
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local HeroAnim = {}

local SLASH = "rbxasset://sounds/swordslash.wav"
local LUNGE = "rbxasset://sounds/swordlunge.wav"
local UNSHEATH = "rbxasset://sounds/unsheath.wav"

local function sound(parent: Instance?, id: string, volume: number)
	if not parent then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = volume
	s.RollOffMaxDistance = 80
	s.Parent = parent
	s:Play()
	Debris:AddItem(s, 2)
end

local function weaponOf(char: Model): Tool?
	for _, c in char:GetChildren() do
		if c:IsA("Tool") and c:GetAttribute("Weapon") then
			return c
		end
	end
	return nil
end

local function track(char: Model)
	char:GetAttributeChangedSignal("Swing"):Connect(function()
		local tool = weaponOf(char)
		local n = char:GetAttribute("Swing") or 0
		sound(tool and tool:FindFirstChild("Handle"), n % 3 == 0 and LUNGE or SLASH, 0.45)
	end)
	char.ChildAdded:Connect(function(c)
		if c:IsA("Tool") and c:GetAttribute("Weapon") then
			sound(c:WaitForChild("Handle", 2), UNSHEATH, 0.5)
		end
	end)
end

function HeroAnim.init()
	local function hook(p: Player)
		if p.Character then
			task.defer(track, p.Character)
		end
		p.CharacterAdded:Connect(track)
	end
	for _, p in Players:GetPlayers() do
		hook(p)
	end
	Players.PlayerAdded:Connect(hook)
end

return HeroAnim
