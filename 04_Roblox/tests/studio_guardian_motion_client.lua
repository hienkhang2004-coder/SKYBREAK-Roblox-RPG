-- Transient Play Mode QA only. Insert as a LocalScript in StarterPlayerScripts during Studio Play QA.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Http = game:GetService("HttpService")

local C = require(ReplicatedStorage:WaitForChild("SkybreakShared"):WaitForChild("Config"))
local SPAWN_POS = C.Spawn or Vector3.new(-317.4, 50.5, 527.8)

local p = Players.LocalPlayer
local ch0 = p.Character or p.CharacterAdded:Wait()
ch0:WaitForChild("Humanoid")
ch0:WaitForChild("HumanoidRootPart")

require(script.Parent:WaitForChild("UI"):WaitForChild("Interface")).Show("HUD")

local trackedJointNames = {
	Root = true,
	Waist = true,
	Neck = true,
	RightShoulder = true,
	LeftShoulder = true,
	RightHip = true,
	LeftHip = true,
}

local report = {}
local elapsed = 0
local bound = nil
local joints = {}
local shieldLegPoses = {}
local nativeR15Violations = 0

local connection = Run.PostSimulation:Connect(function(dt)
	local ch = p.Character
	if ch ~= bound then
		bound = ch
		joints = {}
		if ch then
			for _, o in ipairs(ch:GetDescendants()) do
				if o:IsA("Motor6D") and trackedJointNames[o.Name] then
					table.insert(joints, o)
				end
			end
			table.sort(joints, function(a, b)
				return a.Name < b.Name
			end)
		end
	end

	if ch then
		local hum = ch:FindFirstChildOfClass("Humanoid")
		-- Rule 4 invariant: preserve 100% native R15 avatar without proxy rig overlays
		if
			not hum
			or hum.RigType ~= Enum.HumanoidRigType.R15
			or ch:FindFirstChild("Head") == nil
			or ch:FindFirstChild("UpperTorso") == nil
			or ch:FindFirstChild("SkyGuardianVisual") ~= nil
			or ch:FindFirstChild("SkybreakStarterForm") ~= nil
		then
			nativeR15Violations += 1
		end

		local animator = hum and hum:FindFirstChildOfClass("Animator")
		local clipName = ch:GetAttribute("GuardianCurrentClip")
		if not clipName and animator then
			local tracks = animator:GetPlayingAnimationTracks()
			clipName = (#tracks > 0 and (tracks[1].Name or "PlayingTrack")) or "NativeIdle"
		end

		if hum and clipName and #joints > 0 then
			local row = report[clipName] or { Samples = 0, Poses = {} }
			row.Samples += 1
			local pose = {}
			for _, j in ipairs(joints) do
				table.insert(pose, tostring(j.Transform))
			end
			row.Poses[table.concat(pose, "|")] = true
			report[clipName] = row

			local shieldActive = (ch:GetAttribute("GuardianShieldUntil") or 0) > workspace:GetServerTimeNow()
			if (clipName == "ShieldLoop" or shieldActive) and hum.MoveDirection.Magnitude > 0.1 then
				for _, j in ipairs(joints) do
					if j.Name == "RightHip" then
						shieldLegPoses[tostring(j.Transform)] = true
					end
				end
			end
		end
	end

	elapsed += dt
	if elapsed > 0.1 then
		elapsed = 0
		local clips = {}
		for name, row in pairs(report) do
			local count = 0
			for _ in pairs(row.Poses) do
				count += 1
			end
			clips[name] = { Samples = row.Samples, UniquePoses = count }
		end
		local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		script:SetAttribute(
			"Report",
			Http:JSONEncode({
				SpawnTarget = { SPAWN_POS.X, SPAWN_POS.Y, SPAWN_POS.Z },
				DistanceFromSpawn = hrp and (hrp.Position - SPAWN_POS).Magnitude or -1,
				NativeR15Intact = (nativeR15Violations == 0),
				NativeR15Violations = nativeR15Violations,
				Clips = clips,
			})
		)
		local count = 0
		for _ in pairs(shieldLegPoses) do
			count += 1
		end
		script:SetAttribute("ShieldRunPoses", count)
	end
end)

task.delay(120, function()
	connection:Disconnect()
end)

-- Exercise physical Humanoid locomotion on native R15 rig
task.wait(1)
local h = p.Character:WaitForChild("Humanoid")
local move = Run.PreSimulation:Connect(function()
	h:Move(Vector3.new(1, 0, 0), false)
end)
task.wait(0.6)
h:ChangeState(Enum.HumanoidStateType.Jumping)
task.wait(1)
move:Disconnect()
h:Move(Vector3.zero, false)
script:SetAttribute("MovementFinished", true)

local deadline = os.clock() + 35
while (p.Character:GetAttribute("GuardianShieldUntil") or 0) <= workspace:GetServerTimeNow() and os.clock() < deadline do
	task.wait(0.1)
end
if os.clock() < deadline then
	task.wait(0.7)
	local shieldMove = Run.PreSimulation:Connect(function()
		h:Move(Vector3.new(0, 0, -1), false)
	end)
	task.wait(1.2)
	shieldMove:Disconnect()
	h:Move(Vector3.zero, false)
end
