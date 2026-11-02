-- Monster animation, on every client. The server only moves each monster's invisible Root box (and counts attacks,
-- hits and the death in attributes); here the model ("Look") follows the Root smoothly and comes alive:
-- breathing when idle, a bouncy walk, a lunge when it attacks, a red flash and a flinch when hit, and a fall when it dies.
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local MobAnim = {}

local state = {} -- [Model] = { cf, prev, phase, atk, hurt, atkT, hurtT, deadT }
local FAR = 160 -- only animate monsters this close to the camera

local function flash(model: Model)
	local h = Instance.new("Highlight")
	h.FillColor = Color3.fromRGB(255, 60, 60)
	h.FillTransparency = 0.4
	h.OutlineTransparency = 1
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Adornee = model
	h.Parent = model
	Debris:AddItem(h, 0.14)
end

local function poof(pos: Vector3, size: number)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.one
	p.CFrame = CFrame.new(pos)
	p.Parent = workspace
	local e = Instance.new("ParticleEmitter")
	e.Color = ColorSequence.new(Color3.fromRGB(235, 235, 235))
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size), NumberSequenceKeypoint.new(1, 0) })
	e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
	e.Lifetime = NumberRange.new(0.5, 0.9)
	e.Speed = NumberRange.new(4, 9)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Enabled = false
	e.Parent = p
	e:Emit(30)
	Debris:AddItem(p, 1.5)
end

-- 0..1..0 over a time span (a quick out-and-back)
local function pulse(since: number?, span: number): number
	if not since then
		return 0
	end
	local k = (os.clock() - since) / span
	if k <= 0 or k >= 1 then
		return 0
	end
	return math.sin(k * math.pi)
end

local function animate(model: Model, dt: number, camPos: Vector3, t: number)
	local root = model:FindFirstChild("Root")
	local look = model:FindFirstChild("Look")
	local offset = model:GetAttribute("LookOffset")
	if not root or not look or typeof(offset) ~= "CFrame" then
		return
	end
	local target = root.CFrame
	if (target.Position - camPos).Magnitude > FAR then
		return
	end
	local s = state[model]
	if not s then
		s = { cf = target, prev = target.Position, phase = math.random() * 10, atk = model:GetAttribute("Atk") or 0, hurt = model:GetAttribute("Hurt") or 0 }
		state[model] = s
		model.Destroying:Connect(function()
			state[model] = nil
		end)
	end
	-- cues from the server
	local atk, hurt = model:GetAttribute("Atk") or 0, model:GetAttribute("Hurt") or 0
	if atk ~= s.atk then
		s.atk, s.atkT = atk, os.clock()
	end
	if hurt ~= s.hurt then
		s.hurt, s.hurtT = hurt, os.clock()
		flash(model)
	end
	local h = model:GetAttribute("Height") or 4
	local dead = model:GetAttribute("Dead") == true
	if dead and not s.deadT then
		s.deadT = os.clock()
	elseif not dead and s.deadT then
		s.deadT, s.poofed = nil, nil
		s.cf = target -- back from the dead at home
	end

	-- follow the Root smoothly (snap after a teleport or respawn)
	if (target.Position - s.cf.Position).Magnitude > 25 then
		s.cf = target
	else
		s.cf = s.cf:Lerp(target, 1 - math.exp(-dt * 8))
	end
	local speed = (s.cf.Position - s.prev).Magnitude / math.max(dt, 1 / 240)
	s.prev = s.cf.Position
	local ph = s.phase
	local anim
	if s.deadT then
		-- tip over sideways, then sink into the ground
		local k = os.clock() - s.deadT
		local fall = math.min(k / 0.45, 1)
		local sink = math.max(0, k - 0.6) * h * 1.5
		anim = CFrame.new(0, -sink, 0) * CFrame.Angles(0, 0, fall * math.pi / 2 * 0.95)
		if k > 0.6 and not s.poofed then
			s.poofed = true
			poof(s.cf.Position, math.max(1.5, h * 0.35))
		end
	else
		if speed > 0.6 then
			-- a bouncy walk
			local hop = math.abs(math.sin(t * 9 + ph)) * 0.12 * h
			anim = CFrame.new(0, hop, 0) * CFrame.Angles(math.sin(t * 9 + ph) * 0.06, 0, math.sin(t * 4.5 + ph) * 0.07)
		else
			-- breathing and a little sway
			anim = CFrame.new(0, math.sin(t * 2 + ph) * 0.03 * h, 0) * CFrame.Angles(0, math.sin(t * 0.7 + ph) * 0.12, math.sin(t * 1.3 + ph) * 0.03)
		end
		if model:GetAttribute("Flyer") then
			anim = CFrame.new(0, math.sin(t * 2.4 + ph) * 0.7, 0) * anim
		end
		-- attack: lean in and lunge forward; hit: flinch back
		local a = pulse(s.atkT, 0.35)
		local f = pulse(s.hurtT, 0.25)
		anim = anim * CFrame.new(0, 0, -a * (1 + h * 0.15) + f * 0.6) * CFrame.Angles(-a * 0.35 + f * 0.2, 0, 0)
	end
	-- pivot the animation about the monster's feet
	local feet = s.cf * CFrame.new(0, -h / 2, 0)
	look:PivotTo(feet * anim * CFrame.new(0, h / 2, 0) * offset)
end

function MobAnim.init()
	local t = 0
	RunService.RenderStepped:Connect(function(dt)
		t += dt
		local world = workspace:FindFirstChild("World")
		local folder = world and world:FindFirstChild("Enemies")
		if not folder then
			return
		end
		local camPos = workspace.CurrentCamera.CFrame.Position
		for _, model in folder:GetChildren() do
			animate(model, dt, camPos, t)
		end
	end)
end

return MobAnim
