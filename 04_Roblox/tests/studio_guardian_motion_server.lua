-- Transient Play Mode QA only; never placed under src or published.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local Http = game:GetService("HttpService")

local C = require(ReplicatedStorage.SkybreakShared.Config)
local G = require(ServerScriptService.Services.GameService)
local D = require(ServerScriptService.Services.PlayerDataService)

local SPAWN_POS = C.Spawn or Vector3.new(-317.4, 50.5, 527.8)
local p = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
local profile = D.Get(p)
assert(profile, "Profile must finish loading before QA")

profile.Level = 5
profile.Weapon = "starter_sword"
local rt = G.Runtime[p]
rt.InvincibleUntil = 0
G.Teleport(p, SPAWN_POS)
G.Sync(p)
task.wait(3)

local function checkNativeR15(ch)
	if not ch then
		return false
	end
	local hum = ch:FindFirstChildOfClass("Humanoid")
	return hum ~= nil
		and hum.RigType == Enum.HumanoidRigType.R15
		and ch:FindFirstChild("Head") ~= nil
		and ch:FindFirstChild("UpperTorso") ~= nil
		and ch:FindFirstChild("SkyGuardianVisual") == nil
		and ch:FindFirstChild("SkybreakStarterForm") == nil
end

local results = {
	SpawnTarget = { SPAWN_POS.X, SPAWN_POS.Y, SPAWN_POS.Z },
	NativeR15PreservedBefore = checkNativeR15(p.Character),
	Actions = {},
}

for _, action in ipairs({ "Attack", "Attack", "Attack", "Heavy", "SkySlash", "Dodge", "Dash", "GuardianShield" }) do
	local r = p.Character.HumanoidRootPart
	local before = r.Position
	local previousCooldown = rt.Cooldowns[action]
	G.Action(p, action)
	local accepted = rt.Cooldowns[action] ~= previousCooldown
	if action == "GuardianShield" then
		results.ShieldActive = (p.Character:GetAttribute("GuardianShieldUntil") or 0) > workspace:GetServerTimeNow()
	end
	task.wait(action == "GuardianShield" and 5.8 or (action == "Attack" and 1.05 or 1.4))
	table.insert(results.Actions, {
		Action = action,
		Accepted = accepted,
		Combo = rt.Combo,
		Travel = (r.Position - before).Magnitude,
	})
end

results.ShieldExpired = (p.Character:GetAttribute("GuardianShieldUntil") or 0) <= workspace:GetServerTimeNow()
local health = p.Character.Humanoid.Health
G.PlayerDamage(p, 20)
results.DamageApplied = p.Character.Humanoid.Health < health
task.wait(1)

-- Temporary isolated platform directly above GoldenSky Spawn tests movement sweeps against wall/edge.
local fxBase = SPAWN_POS + Vector3.new(0, 140, 0)
local fixture = Instance.new("Folder")
fixture.Name = "GuardianEvadeQAFixture"
fixture.Parent = workspace

local function makePart(name, size, pos)
	local o = Instance.new("Part")
	o.Name = name
	o.Size = size
	o.Position = pos
	o.Anchored = true
	o.Parent = fixture
	return o
end

makePart("Floor", Vector3.new(40, 1, 40), fxBase)
local wall = makePart("Wall", Vector3.new(30, 12, 1), fxBase + Vector3.new(0, 5, -8))

local r = p.Character.HumanoidRootPart
G.Teleport(p, fxBase + Vector3.new(0, 4, 0))
r.CFrame = CFrame.lookAt(r.Position, r.Position + Vector3.new(0, 0, -1))
task.wait(0.3)
rt.Stamina = 100
rt.EvadeUntil = 0
rt.ActionUntil = 0
rt.Cooldowns.Dash = 0
G.Action(p, "Dash")
task.wait(0.8)
results.Wall = {
	StoppedBeforeWall = r.Position.Z > (fxBase.Z - 6),
	OffsetZ = r.Position.Z - fxBase.Z,
}
wall:Destroy()

G.Teleport(p, fxBase + Vector3.new(0, 4, -16))
r.CFrame = CFrame.lookAt(r.Position, r.Position + Vector3.new(0, 0, -1))
task.wait(0.3)
rt.Stamina = 100
rt.EvadeUntil = 0
rt.ActionUntil = 0
rt.Cooldowns.Dash = 0
G.Action(p, "Dash")
task.wait(0.8)
results.Edge = {
	StoppedOnFloor = r.Position.Z >= (fxBase.Z - 20),
	OffsetZ = r.Position.Z - fxBase.Z,
}

results.NativeR15PreservedAfter = checkNativeR15(p.Character)
G.Teleport(p, SPAWN_POS)
fixture:Destroy()
p.Character.Humanoid.Health = 0
task.wait(2)
script:SetAttribute("Report", Http:JSONEncode(results))
