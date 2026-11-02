--!nonstrict
-- ============================================================================
-- SKYBREAK: ABYSSAL SOVEREIGN DRAGON & HYBRID TRANSFORMATION SKILL VFX ENGINE
-- Synchronized 1:1 with 37-Bone AbyssalSovereignDragon & 34-Bone Hybrid Rigs
-- + Native VFX Studio Prefab Bridge (EmitCount / EmitDelay / EmitDuration)
-- Strict Anti-Glare Budget: PointLight.Brightness <= 1.45, Range <= 16,
--                           ParticleEmitter.LightEmission <= 0.78
-- ============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local DragonSovereignVFX = {}

local MAX_LIGHT_BRIGHTNESS = 1.45
local MAX_LIGHT_RANGE = 16
local MAX_PARTICLE_EMISSION = 0.78

local PALETTE = {
	Crimson = Color3.fromRGB(255, 46, 150),
	Violet = Color3.fromRGB(168, 38, 255),
	Magma = Color3.fromRGB(255, 116, 42),
	Obsidian = Color3.fromRGB(20, 12, 36),
	SlateArmor = Color3.fromRGB(48, 38, 76),
	HotCore = Color3.fromRGB(255, 216, 248),
	AwakenedGold = Color3.fromRGB(255, 212, 88),
}

local lastTransformBurstAt = setmetatable({}, { __mode = "k" })

local function getLocalPlayer()
	return Players.LocalPlayer
end

local function isLowFX()
	local lp = getLocalPlayer()
	return (lp and lp:GetAttribute("LowFXMode") == true) or (Workspace:GetAttribute("LowFXMode") == true) or false
end

local function getTempFolder()
	local tf = Workspace:FindFirstChild("TempFX")
	if not tf then
		tf = Instance.new("Folder")
		tf.Name = "TempFX"
		tf.Parent = Workspace
	end
	local sub = tf:FindFirstChild("DragonSovereignVFX")
	if not sub then
		sub = Instance.new("Folder")
		sub.Name = "DragonSovereignVFX"
		sub.Parent = tf
	end
	return sub, tf
end

local function emitCameraTrauma(trauma, fovPunch, dirVec)
	local lp = getLocalPlayer()
	if not lp or isLowFX() then return end
	local _, tf = getTempFolder()
	local camEvt = tf and tf:FindFirstChild("SkybreakCameraImpulse")
	if camEvt and camEvt:IsA("BindableEvent") then
		camEvt:Fire(trauma or 0.28, fovPunch or 0, dirVec)
	else
		lp:SetAttribute("SkybreakTraumaPulse", tonumber(trauma) or 0.28)
		if fovPunch and fovPunch ~= 0 then
			lp:SetAttribute("SkybreakFovPunch", tonumber(fovPunch) or 0)
		end
	end
end

local function safeLookAt(fromPos, toPos, fallbackDir)
	local delta = toPos - fromPos
	local dir
	if delta.Magnitude > 0.05 then
		dir = delta.Unit
	elseif typeof(fallbackDir) == "Vector3" and fallbackDir.Magnitude > 0.05 then
		dir = fallbackDir.Unit
	else
		dir = Vector3.new(0, 0, -1)
	end
	local upVec = (math.abs(dir.Y) > 0.995) and Vector3.new(0, 0, 1) or Vector3.new(0, 1, 0)
	return CFrame.lookAt(fromPos, fromPos + dir, upVec)
end

local function makePart(name, shape, size, cf, color, transparency, material, parent)
	local p = Instance.new("Part")
	p.Name = name or "DragonVFXPart"
	p.Shape = shape or Enum.PartType.Block
	p.Size = size or Vector3.new(1, 1, 1)
	p.CFrame = cf or CFrame.new()
	p.Color = color or PALETTE.Crimson
	p.Material = material or Enum.Material.ForceField
	p.Transparency = math.clamp(transparency or 0.14, 0, 1)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Massless = true
	p.Parent = parent or (getTempFolder())
	return p
end

local function makeSafeLight(parent, color, brightness, range, dur)
	if isLowFX() or not parent then return nil end
	local pl = Instance.new("PointLight")
	pl.Color = color or PALETTE.Crimson
	pl.Brightness = math.clamp(brightness or 1.25, 0, MAX_LIGHT_BRIGHTNESS)
	pl.Range = math.clamp(range or 14, 2, MAX_LIGHT_RANGE)
	pl.Shadows = false
	pl.Parent = parent
	if dur and dur > 0 then
		TweenService:Create(pl, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Brightness = 0,
		}):Play()
	end
	return pl
end

local function attachRibbonTrail(hostPart, color1, color2, width, lifetime)
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, width * 0.5, 0)
	a0.Parent = hostPart
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -width * 0.5, 0)
	a1.Parent = hostPart

	local tr = Instance.new("Trail")
	tr.Attachment0 = a0
	tr.Attachment1 = a1
	tr.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color1),
		ColorSequenceKeypoint.new(0.55, color2),
		ColorSequenceKeypoint.new(1, PALETTE.Obsidian),
	})
	tr.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.08),
		NumberSequenceKeypoint.new(0.65, 0.38),
		NumberSequenceKeypoint.new(1, 1),
	})
	tr.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.6, 0.65),
		NumberSequenceKeypoint.new(1, 0),
	})
	tr.LightEmission = 0.72
	tr.LightInfluence = 0.15
	tr.FaceCamera = true
	tr.Lifetime = lifetime or 0.28
	tr.MinLength = 0.05
	tr.Parent = hostPart
	return tr
end

local function findGroundPos(origin, ignoreChar)
	local sub, tf = getTempFolder()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ex = { tf, sub }
	if ignoreChar then table.insert(ex, ignoreChar) end
	local lp = getLocalPlayer()
	if lp and lp.Character and lp.Character ~= ignoreChar then
		table.insert(ex, lp.Character)
	end
	params.FilterDescendantsInstances = ex
	local hit = Workspace:Raycast(origin + Vector3.new(0, 6, 0), Vector3.new(0, -42, 0), params)
	return hit and hit.Position or (origin - Vector3.new(0, 2.6, 0))
end

local function spawnShockRing(pos, upCF, color, startR, endR, thickness, dur, mat, parent)
	local baseCF = upCF or CFrame.new(pos)
	local ring = makePart(
		"DragonShockRing",
		Enum.PartType.Cylinder,
		Vector3.new(thickness or 0.28, startR, startR),
		baseCF * CFrame.Angles(0, 0, math.pi * 0.5),
		color,
		0.14,
		mat or Enum.Material.ForceField,
		parent
	)
	local d = dur or 0.44
	TweenService:Create(ring, TweenInfo.new(d, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = Vector3.new(math.max(0.06, (thickness or 0.28) * 0.3), endR, endR),
		Transparency = 1,
	}):Play()
	Debris:AddItem(ring, d + 0.05)
	return ring
end

-- ============================================================================
-- 1. VFX STUDIO PREFAB BRIDGE (EmitCount / EmitDelay / EmitDuration)
-- ============================================================================
local function makeStudioEmitter(parent, name, c1, c2, c3, sz0, sz1, lifeMin, lifeMax, spdMin, spdMax, emitCount, emitDelay, spread, drag)
	local pe = Instance.new("ParticleEmitter")
	pe.Name = name
	pe.Enabled = false
	pe.Rate = 0
	pe.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, c1),
		ColorSequenceKeypoint.new(0.52, c2),
		ColorSequenceKeypoint.new(1, c3 or PALETTE.Obsidian),
	})
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, sz0),
		NumberSequenceKeypoint.new(0.55, (sz0 + sz1) * 0.52),
		NumberSequenceKeypoint.new(1, sz1),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.08),
		NumberSequenceKeypoint.new(0.68, 0.42),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.LightEmission = math.min(MAX_PARTICLE_EMISSION, 0.72)
	pe.LightInfluence = 0.2
	pe.Lifetime = NumberRange.new(lifeMin, lifeMax)
	pe.Speed = NumberRange.new(spdMin, spdMax)
	pe.SpreadAngle = Vector2.new(spread or 180, spread or 180)
	pe.Drag = drag or 3.2
	pe.RotSpeed = NumberRange.new(-140, 140)
	pe.Rotation = NumberRange.new(0, 360)
	pe:SetAttribute("EmitCount", emitCount or 18)
	pe:SetAttribute("EmitDelay", emitDelay or 0)
	pe:SetAttribute("EmitDuration", 0)
	pe.Parent = parent
	return pe
end

function DragonSovereignVFX.EnsureDefaultPrefabs()
	local rootFolder = ReplicatedStorage:FindFirstChild("VFXStudioPrefabs")
	if not rootFolder then
		rootFolder = Instance.new("Folder")
		rootFolder.Name = "VFXStudioPrefabs"
		rootFolder.Parent = ReplicatedStorage
	end
	local dragonFolder = rootFolder:FindFirstChild("Dragon")
	if not dragonFolder then
		dragonFolder = Instance.new("Folder")
		dragonFolder.Name = "Dragon"
		dragonFolder.Parent = rootFolder
	end

	local specs = {
		Dragon_M1_TalonRend = {
			{ "TalonSlashSparks", PALETTE.HotCore, PALETTE.Crimson, PALETTE.Violet, 0.75, 0.05, 0.22, 0.38, 12, 28, 18, 0, 110, 4.0 },
			{ "MagmaClawCinders", PALETTE.Magma, PALETTE.Crimson, PALETTE.Obsidian, 0.48, 0, 0.28, 0.48, 8, 20, 12, 0.03, 150, 3.2 },
			{ "AbyssalVoidWisps", PALETTE.Violet, PALETTE.Obsidian, PALETTE.Obsidian, 1.15, 0.2, 0.30, 0.52, 4, 12, 10, 0.05, 180, 2.5 },
		},
		Dragon_Z_SovereignBreath = {
			{ "MawChargeSparks", PALETTE.HotCore, PALETTE.Crimson, PALETTE.Violet, 1.05, 0.08, 0.26, 0.46, 14, 34, 24, 0, 75, 3.0 },
			{ "BoloPlasmaPlume", PALETTE.Crimson, PALETTE.Violet, PALETTE.Obsidian, 1.85, 0.25, 0.35, 0.62, 18, 42, 30, 0.08, 55, 2.4 },
			{ "ScorchedMagmaAsh", PALETTE.Magma, PALETTE.Crimson, PALETTE.Obsidian, 0.85, 0, 0.42, 0.72, 10, 26, 18, 0.14, 160, 3.5 },
		},
		Dragon_X_VoidTalons = {
			{ "ClawRiftBurst", PALETTE.HotCore, PALETTE.Crimson, PALETTE.Violet, 1.15, 0.08, 0.26, 0.48, 14, 34, 26, 0, 140, 3.6 },
			{ "ObsidianShatterMotes", PALETTE.Magma, PALETTE.SlateArmor, PALETTE.Obsidian, 0.78, 0.1, 0.35, 0.60, 10, 26, 18, 0.04, 180, 3.0 },
			{ "VoidRiftMist", PALETTE.Violet, PALETTE.Obsidian, PALETTE.Obsidian, 1.65, 0.3, 0.38, 0.65, 5, 14, 14, 0.08, 180, 2.2 },
		},
		Dragon_C_CataclysmicStarshower = {
			{ "StarfallImpactFlash", PALETTE.HotCore, PALETTE.Crimson, PALETTE.Magma, 1.55, 0.12, 0.30, 0.55, 14, 36, 26, 0, 180, 3.2 },
			{ "DraconicMeteorCinders", PALETTE.Magma, PALETTE.Crimson, PALETTE.Obsidian, 0.92, 0, 0.42, 0.78, 12, 30, 22, 0.05, 180, 2.8 },
			{ "AbyssalMaelstromSmoke", PALETTE.Violet, PALETTE.Crimson, PALETTE.Obsidian, 2.10, 0.4, 0.45, 0.82, 6, 18, 18, 0.10, 180, 2.0 },
		},
		Dragon_V_Ascension = {
			{ "ImplosionVoidCore", PALETTE.Violet, PALETTE.Crimson, PALETTE.Obsidian, 1.45, 0.1, 0.28, 0.48, 12, 28, 28, 0, 180, 3.8 },
			{ "SovereignPillarBurst", PALETTE.HotCore, PALETTE.Crimson, PALETTE.Violet, 2.25, 0.2, 0.42, 0.78, 18, 46, 38, 0.14, 180, 2.6 },
			{ "ConquerorMagmaEmbers", PALETTE.Magma, PALETTE.Crimson, PALETTE.Obsidian, 0.95, 0, 0.50, 0.92, 14, 34, 26, 0.24, 180, 2.4 },
		},
		Dragon_F_SoarRush = {
			{ "SonicSlipstreamMist", PALETTE.HotCore, PALETTE.Violet, PALETTE.Obsidian, 1.25, 0.15, 0.25, 0.45, 12, 28, 20, 0, 120, 3.5 },
			{ "WingtipPlasmaSparks", PALETTE.Crimson, PALETTE.Magma, PALETTE.Obsidian, 0.65, 0, 0.28, 0.50, 10, 24, 20, 0.04, 150, 3.2 },
		},
		Dragon_Detransform = {
			{ "ObsidianScaleDispersal", PALETTE.Violet, PALETTE.SlateArmor, PALETTE.Obsidian, 1.15, 0.15, 0.35, 0.65, 8, 20, 22, 0, 180, 2.8 },
			{ "ResidualDragonEmbers", PALETTE.Crimson, PALETTE.Magma, PALETTE.Obsidian, 0.58, 0, 0.38, 0.68, 6, 16, 16, 0.05, 180, 2.6 },
		},
	}

	for prefabName, emitterList in pairs(specs) do
		if not dragonFolder:FindFirstChild(prefabName) then
			local holder = Instance.new("Part")
			holder.Name = prefabName
			holder.Size = Vector3.new(0.4, 0.4, 0.4)
			holder.Transparency = 1
			holder.Anchored = true
			holder.CanCollide = false
			holder.CanQuery = false
			holder.CanTouch = false
			local att = Instance.new("Attachment")
			att.Name = "VFXAttachment"
			att.Parent = holder
			for _, s in ipairs(emitterList) do
				makeStudioEmitter(att, s[1], s[2], s[3], s[4], s[5], s[6], s[7], s[8], s[9], s[10], s[11], s[12], s[13], s[14])
			end
			holder.Parent = dragonFolder
		end
	end
	return dragonFolder
end

local function scaleNumberSequence(ns, mult)
	if math.abs(mult - 1) < 0.02 then return ns end
	local kps = {}
	for _, kp in ipairs(ns.Keypoints) do
		table.insert(kps, NumberSequenceKeypoint.new(kp.Time, kp.Value * mult, kp.Envelope * mult))
	end
	return NumberSequence.new(kps)
end

function DragonSovereignVFX.EmitPrefab(prefabName, worldCF, scale)
	local dragonFolder = DragonSovereignVFX.EnsureDefaultPrefabs()
	local template = dragonFolder and dragonFolder:FindFirstChild(prefabName)
	if not template then return nil end

	local mult = math.clamp(tonumber(scale) or 1, 0.6, 2.4)
	local low = isLowFX()
	local clone = template:Clone()
	local hostPart = nil
	if clone:IsA("BasePart") then
		hostPart = clone
		hostPart.Anchored = true
		hostPart.CanCollide = false
		hostPart.CanQuery = false
		hostPart.CanTouch = false
		hostPart.Transparency = 1
		hostPart.CFrame = worldCF
		hostPart.Parent = (getTempFolder())
	else
		hostPart = makePart(prefabName .. "_Host", Enum.PartType.Block, Vector3.new(0.25, 0.25, 0.25), worldCF, PALETTE.Crimson, 1, Enum.Material.SmoothPlastic)
		clone.Parent = hostPart
	end

	local maxCleanup = 1.2
	for _, desc in ipairs(hostPart:GetDescendants()) do
		if desc:IsA("ParticleEmitter") then
			desc.Enabled = false
			desc.LightEmission = math.min(MAX_PARTICLE_EMISSION, desc.LightEmission)
			desc.Size = scaleNumberSequence(desc.Size, mult)
			desc.Speed = NumberRange.new(desc.Speed.Min * mult, desc.Speed.Max * mult)

			local emitCount = tonumber(desc:GetAttribute("EmitCount")) or 16
			if low then
				emitCount = math.max(1, math.floor(emitCount * 0.35 + 0.5))
			end
			local emitDelay = tonumber(desc:GetAttribute("EmitDelay")) or 0
			local emitDur = tonumber(desc:GetAttribute("EmitDuration")) or 0
			maxCleanup = math.max(maxCleanup, emitDelay + emitDur + desc.Lifetime.Max + 0.35)

			task.spawn(function()
				if emitDelay > 0 then
					task.wait(emitDelay)
				else
					task.wait()
				end
				if not desc or not desc.Parent then return end
				if emitCount > 0 then
					desc:Emit(emitCount)
				end
				if emitDur > 0 then
					desc.Enabled = true
					task.wait(emitDur)
					if desc and desc.Parent then
						desc.Enabled = false
					end
				end
			end)
		elseif desc:IsA("PointLight") then
			desc.Brightness = math.min(MAX_LIGHT_BRIGHTNESS, desc.Brightness)
			desc.Range = math.min(MAX_LIGHT_RANGE, desc.Range)
		end
	end

	Debris:AddItem(hostPart, maxCleanup)
	return hostPart
end

-- ============================================================================
-- 2. SYNCHRONIZED 37-BONE / 34-BONE BLENDER DRAGON RIG LOCATOR
-- ============================================================================
function DragonSovereignVFX.ResolveDragonStateAndAnchors(actorChar, fallbackPos, lookDir)
	local lp = getLocalPlayer()
	local isLocal = (actorChar == nil) or (lp and actorChar == lp.Character)
	local ch = actorChar or (lp and lp.Character)
	local root = ch and ch:FindFirstChild("HumanoidRootPart")

	local tf = tostring((ch and ch:GetAttribute("FruitTransform")) or (isLocal and lp and lp:GetAttribute("FruitTransform")) or "")
	local rawTier = tonumber((ch and ch:GetAttribute("DragonFormTier")) or (isLocal and lp and lp:GetAttribute("DragonFormTier")))
	local tier = 0
	if rawTier and rawTier >= 2 then
		tier = 2
	elseif rawTier and rawTier == 1 then
		tier = 1
	elseif tf == "AbyssalSovereign" or tf == "DragonFull" then
		tier = 2
	elseif tf == "AbyssalDragonHybrid" or tf == "DragonHybrid" then
		tier = 1
	end

	local dir = (typeof(lookDir) == "Vector3" and lookDir.Magnitude > 0.05 and lookDir.Unit)
		or (root and root.CFrame.LookVector)
		or Vector3.new(0, 0, -1)
	local centerPos = (root and root.Position) or fallbackPos or Vector3.zero
	local baseCF = safeLookAt(centerPos, centerPos + dir, dir)

	-- Locate live 3D Blender Dragon model inside FruitTransformFX
	local formModel = nil
	local boneMap = {}
	if ch then
		local fxFolder = ch:FindFirstChild("FruitTransformFX", true)
		if fxFolder then
			formModel = fxFolder:FindFirstChild("AbyssalSovereignDragon_3DForm")
				or fxFolder:FindFirstChild("AbyssalDragonHybrid_3DForm")
			if formModel and tier == 0 then
				tier = (formModel.Name == "AbyssalSovereignDragon_3DForm") and 2 or 1
			end
		end
	end
	if formModel then
		local rp = formModel:FindFirstChild("RootPart") or formModel.PrimaryPart
		if rp then
			for _, d in ipairs(rp:GetDescendants()) do
				if d:IsA("Bone") then
					boneMap[d.Name] = d
				end
			end
		end
	end

	local function bonePos(candidates, localOffset)
		for _, bName in ipairs(candidates) do
			local b = boneMap[bName]
			if b then
				local ok, wcf = pcall(function() return b.TransformedWorldCFrame end)
				if ok and typeof(wcf) == "CFrame" then
					return wcf.Position
				end
			end
		end
		return (baseCF * localOffset).Position
	end

	local mawPos = bonePos({ "FX_BreathCore", "Jaw", "Head" }, (tier == 2) and CFrame.new(0, 5.2, -5.8) or ((tier == 1) and CFrame.new(0, 2.8, -2.2) or CFrame.new(0, 1.5, -1.8)))
	local crownPos = bonePos({ "FX_CrownHalo", "Head" }, (tier == 2) and CFrame.new(0, 7.6, -4.2) or CFrame.new(0, 3.8, -0.8))
	local clawLPos = bonePos({ "Paw_FL", "Forearm_FL", "LeftHand", "LeftLowerArm", "FX_Orb_L" }, (tier == 2) and CFrame.new(-3.2, 1.6, -4.0) or CFrame.new(-1.8, 1.2, -1.6))
	local clawRPos = bonePos({ "Paw_FR", "Forearm_FR", "RightHand", "RightLowerArm", "FX_Orb_R" }, (tier == 2) and CFrame.new(3.2, 1.6, -4.0) or CFrame.new(1.8, 1.2, -1.6))
	local wingLPos = bonePos({ "WingForearm_L", "Wing_L_03", "Wing_L_02", "Wing_L_01", "Wing_L", "DragonWing_L_02", "DragonWing_L_01" }, (tier == 2) and CFrame.new(-7.5, 6.2, -0.5) or CFrame.new(-3.6, 3.0, 0.6))
	local wingRPos = bonePos({ "WingForearm_R", "Wing_R_03", "Wing_R_02", "Wing_R_01", "Wing_R", "DragonWing_R_02", "DragonWing_R_01" }, (tier == 2) and CFrame.new(7.5, 6.2, -0.5) or CFrame.new(3.6, 3.0, 0.6))
	local tailPos = bonePos({ "Spine_12", "Spine_10", "Tail_04", "Tail_03", "DragonTail_04", "DragonTail_03" }, (tier == 2) and CFrame.new(0, 1.8, 6.5) or CFrame.new(0, 1.1, 3.6))

	return {
		Tier = tier,
		IsLocal = isLocal,
		Model = formModel,
		Bones = boneMap,
		CenterPos = centerPos,
		GroundPos = findGroundPos(centerPos, ch),
		BaseCF = baseCF,
		LookDir = dir,
		MawCF = CFrame.lookAt(mawPos, mawPos + dir),
		CrownCF = CFrame.lookAt(crownPos, crownPos + dir),
		ClawL_CF = CFrame.lookAt(clawLPos, clawLPos + dir),
		ClawR_CF = CFrame.lookAt(clawRPos, clawRPos + dir),
		WingL_CF = CFrame.lookAt(wingLPos, wingLPos + dir),
		WingR_CF = CFrame.lookAt(wingRPos, wingRPos + dir),
		Tail_CF = CFrame.lookAt(tailPos, tailPos - dir),
	}
end

-- ============================================================================
-- 3. [V] SOVEREIGN DRAGON TRANSFORMATION ASCENSION & DETRANSFORM VFX
-- ============================================================================
function DragonSovereignVFX.SpawnDetransformDispersal(actorChar, pos)
	local anchors = DragonSovereignVFX.ResolveDragonStateAndAnchors(actorChar, pos, nil)
	local gPos = anchors.GroundPos
	local cPos = anchors.CenterPos
	DragonSovereignVFX.EmitPrefab("Dragon_Detransform", CFrame.new(cPos), 1.1)

	spawnShockRing(gPos + Vector3.new(0, 0.18, 0), nil, PALETTE.Violet, 3.5, 16, 0.24, 0.42, Enum.Material.ForceField)
	spawnShockRing(cPos, nil, PALETTE.Crimson, 2.2, 11, 0.18, 0.34, Enum.Material.ForceField)

	local scaleCount = isLowFX() and 5 or 10
	for i = 1, scaleCount do
		local ang = (i - 1) * ((math.pi * 2) / scaleCount)
		local p0 = cPos + Vector3.new(math.cos(ang) * 2.4, (i % 3) * 1.1 - 0.5, math.sin(ang) * 2.4)
		local p1 = p0 + Vector3.new(math.cos(ang) * 4.5, 3.2 + (i % 2) * 1.4, math.sin(ang) * 4.5)
		local shard = makePart(
			"ObsidianScaleMote",
			Enum.PartType.Wedge,
			Vector3.new(0.45, 0.9, 0.65),
			CFrame.new(p0) * CFrame.Angles(0.5, ang, 0.4),
			(i % 2 == 0) and PALETTE.SlateArmor or PALETTE.Crimson,
			0.12,
			(i % 2 == 0) and Enum.Material.Slate or Enum.Material.ForceField
		)
		TweenService:Create(shard, TweenInfo.new(0.48, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			CFrame = CFrame.new(p1) * CFrame.Angles(1.8, ang + 1.4, 1.1),
			Size = Vector3.new(0.1, 0.2, 0.15),
			Transparency = 1,
		}):Play()
		Debris:AddItem(shard, 0.52)
	end
end

function DragonSovereignVFX.SpawnTransformAscension(actorChar, pos, tier, isAwakened, isLocal)
	local keyObj = actorChar or getLocalPlayer()
	local now = os.clock()
	if keyObj and lastTransformBurstAt[keyObj] and (now - lastTransformBurstAt[keyObj] < 0.32) then
		return
	end
	if keyObj then
		lastTransformBurstAt[keyObj] = now
	end

	if (tonumber(tier) or 0) <= 0 then
		DragonSovereignVFX.SpawnDetransformDispersal(actorChar, pos)
		return
	end

	local isSovereign = (tonumber(tier) or 2) >= 2
	local scale = (isSovereign and 1.42 or 1.05) * (isAwakened and 1.22 or 1.0)
	local anchors = DragonSovereignVFX.ResolveDragonStateAndAnchors(actorChar, pos, nil)
	local gPos = anchors.GroundPos
	local cPos = anchors.CenterPos
	local folder = Instance.new("Folder")
	folder.Name = isSovereign and "SovereignDragon_AscensionVFX" or "HybridDragon_AscensionVFX"
	folder.Parent = (getTempFolder())
	Debris:AddItem(folder, 1.45)

	DragonSovereignVFX.EmitPrefab("Dragon_V_Ascension", CFrame.new(cPos + Vector3.new(0, 2.2 * scale, 0)), scale)

	-- Stage 1 (0.00s): Abyssal Gravity Implosion Sphere + 3 Counter-Rotating Draconic Ground Seals + 8 Obsidian Monolith Fangs
	local implosion = makePart("AbyssalImplosionSphere", Enum.PartType.Ball, Vector3.new(15, 15, 15) * scale, CFrame.new(cPos + Vector3.new(0, 2.5 * scale, 0)), PALETTE.Obsidian, 0.18, Enum.Material.ForceField, folder)
	local implosionRim = makePart("AbyssalImplosionRim", Enum.PartType.Ball, Vector3.new(17.5, 17.5, 17.5) * scale, implosion.CFrame, PALETTE.Crimson, 0.35, Enum.Material.ForceField, folder)
	makeSafeLight(implosion, PALETTE.Crimson, 1.38, 16, 0.95)
	TweenService:Create(implosion, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = Vector3.new(1.8, 1.8, 1.8) * scale,
		Transparency = 0.04,
	}):Play()
	TweenService:Create(implosionRim, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = Vector3.new(2.2, 2.2, 2.2) * scale,
		Transparency = 0.08,
	}):Play()
	Debris:AddItem(implosion, 0.20)
	Debris:AddItem(implosionRim, 0.20)

	for rIdx = 1, 3 do
		local sealR = (6 + rIdx * 5.2) * scale
		local col = (rIdx == 1 and PALETTE.HotCore) or (rIdx == 2 and PALETTE.Crimson or PALETTE.Violet)
		local seal = makePart("DraconicSealRing_" .. rIdx, Enum.PartType.Cylinder, Vector3.new(0.16, 2, 2), CFrame.new(gPos + Vector3.new(0, 0.12 + rIdx * 0.05, 0)) * CFrame.Angles(0, 0, math.pi * 0.5), col, 0.12, Enum.Material.ForceField, folder)
		TweenService:Create(seal, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.16, sealR, sealR),
		}):Play()
		task.delay(0.55, function()
			if seal and seal.Parent then
				TweenService:Create(seal, TweenInfo.new(0.42, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = Vector3.new(0.05, sealR * 1.35, sealR * 1.35),
					Transparency = 1,
				}):Play()
			end
		end)
	end

	local fangCount = isLowFX() and 5 or (isSovereign and 10 or 7)
	for i = 1, fangCount do
		local ang = (i - 1) * ((math.pi * 2) / fangCount)
		local distR = (isSovereign and 9.5 or 6.8) * scale
		local fPos = gPos + Vector3.new(math.cos(ang) * distR, -1.2, math.sin(ang) * distR)
		local h = (isSovereign and 9.6 or 6.4) * scale
		local fang = makePart(
			"AscensionObsidianFang_" .. i,
			Enum.PartType.Wedge,
			Vector3.new(1.5 * scale, h, 2.1 * scale),
			CFrame.lookAt(fPos, gPos + Vector3.new(0, h * 0.85, 0)) * CFrame.Angles(-0.28, 0, 0),
			(i % 2 == 0) and PALETTE.SlateArmor or PALETTE.Crimson,
			0.06,
			(i % 2 == 0) and Enum.Material.Slate or Enum.Material.ForceField,
			folder
		)
		TweenService:Create(fang, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			CFrame = CFrame.lookAt(fPos + Vector3.new(0, h * 0.48, 0), gPos + Vector3.new(0, h * 1.35, 0)) * CFrame.Angles(-0.34, 0, 0),
		}):Play()
		task.delay(0.62, function()
			if fang and fang.Parent then
				TweenService:Create(fang, TweenInfo.new(0.36, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Transparency = 1,
					Size = Vector3.new(0.4, h * 0.4, 0.5),
				}):Play()
			end
		end)
	end

	-- Stage 2 (0.14s): Towering Sovereign Ascension Pillar + Coiling Spectral Dragon Helices + Conqueror Blast Dome
	task.delay(0.14, function()
		if not folder.Parent then return end
		local pillarH = (isSovereign and 42 or 28) * scale
		local pillarR = (isSovereign and 8.4 or 5.8) * scale
		local pCenter = gPos + Vector3.new(0, pillarH * 0.5, 0)

		local corePillar = makePart("SovereignPillarCore", Enum.PartType.Cylinder, Vector3.new(pillarH, 1.2, 1.2), CFrame.new(pCenter) * CFrame.Angles(0, 0, math.pi * 0.5), PALETTE.HotCore, 0.04, Enum.Material.SmoothPlastic, folder)
		local plasmaPillar = makePart("SovereignPillarPlasma", Enum.PartType.Cylinder, Vector3.new(pillarH, 2.2, 2.2), corePillar.CFrame, PALETTE.Crimson, 0.14, Enum.Material.ForceField, folder)
		local voidSheath = makePart("SovereignPillarVoid", Enum.PartType.Cylinder, Vector3.new(pillarH, 3.0, 3.0), corePillar.CFrame, PALETTE.Obsidian, 0.28, Enum.Material.ForceField, folder)

		TweenService:Create(corePillar, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = Vector3.new(pillarH, pillarR * 0.52, pillarR * 0.52) }):Play()
		TweenService:Create(plasmaPillar, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = Vector3.new(pillarH, pillarR, pillarR) }):Play()
		TweenService:Create(voidSheath, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = Vector3.new(pillarH, pillarR * 1.32, pillarR * 1.32) }):Play()

		local domeR = (isSovereign and 44 or 28) * (isAwakened and 1.18 or 1.0)
		local dome = makePart("SovereignConquerorDome", Enum.PartType.Ball, Vector3.new(4, 4, 4), CFrame.new(cPos + Vector3.new(0, 2.4, 0)), PALETTE.Crimson, 0.16, Enum.Material.ForceField, folder)
		local innerVoidDome = makePart("SovereignVoidDome", Enum.PartType.Ball, Vector3.new(3, 3, 3), dome.CFrame, PALETTE.Obsidian, 0.14, Enum.Material.ForceField, folder)
		TweenService:Create(dome, TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = Vector3.new(domeR, domeR, domeR), Transparency = 1 }):Play()
		TweenService:Create(innerVoidDome, TweenInfo.new(0.46, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = Vector3.new(domeR * 0.82, domeR * 0.82, domeR * 0.82), Transparency = 1 }):Play()

		spawnShockRing(gPos + Vector3.new(0, 0.25, 0), nil, PALETTE.Crimson, 4, domeR * 1.12, 0.38, 0.58, Enum.Material.ForceField, folder)
		spawnShockRing(gPos + Vector3.new(0, 0.55, 0), nil, PALETTE.Violet, 3, domeR * 0.86, 0.28, 0.48, Enum.Material.ForceField, folder)
		if isAwakened then
			spawnShockRing(gPos + Vector3.new(0, 0.85, 0), nil, PALETTE.AwakenedGold, 3, domeR * 0.98, 0.24, 0.52, Enum.Material.ForceField, folder)
		end

		-- 2 Live Coiling Spectral Dragon Helices spiraling up the Ascension Pillar
		if not isLowFX() then
			local helices = {}
			for h = 1, 2 do
				local col = (h == 1) and PALETTE.Crimson or PALETTE.Violet
				local node = makePart("CoilingDragonSpirit_" .. h, Enum.PartType.Ball, Vector3.new(1.3, 1.3, 2.2) * scale, CFrame.new(gPos), col, 0.06, Enum.Material.ForceField, folder)
				attachRibbonTrail(node, (h == 1) and PALETTE.HotCore or PALETTE.Crimson, col, 1.85 * scale, 0.34)
				table.insert(helices, { Node = node, Phase = (h - 1) * math.pi })
			end
			local t0 = os.clock()
			local conn
			conn = RunService.Heartbeat:Connect(function()
				local el = os.clock() - t0
				if el >= 0.72 or not folder.Parent then
					if conn then conn:Disconnect() end
					return
				end
				local u = el / 0.72
				for _, h in ipairs(helices) do
					if h.Node and h.Node.Parent then
						local ang = el * 15 + h.Phase
						local rad = (pillarR * 0.72) * (1 - u * 0.28)
						local y = u * pillarH * 0.92
						local p = gPos + Vector3.new(math.cos(ang) * rad, y, math.sin(ang) * rad)
						local tangent = Vector3.new(-math.sin(ang) * rad, pillarH * 0.16, math.cos(ang) * rad).Unit
						h.Node.CFrame = CFrame.lookAt(p, p + tangent)
						if u > 0.72 then
							h.Node.Transparency = (u - 0.72) / 0.28
						end
					end
				end
				if el > 0.34 then
					local f = (el - 0.34) / 0.38
					corePillar.Size = Vector3.new(pillarH, pillarR * 0.52 * (1 - f), pillarR * 0.52 * (1 - f))
					plasmaPillar.Transparency = 0.14 + f * 0.86
					voidSheath.Transparency = 0.28 + f * 0.72
					corePillar.Transparency = f
				end
			end)
		else
			task.delay(0.32, function()
				if corePillar.Parent then
					TweenService:Create(corePillar, TweenInfo.new(0.28), { Transparency = 1 }):Play()
					TweenService:Create(plasmaPillar, TweenInfo.new(0.28), { Transparency = 1 }):Play()
					TweenService:Create(voidSheath, TweenInfo.new(0.28), { Transparency = 1 }):Play()
				end
			end)
		end

		if isLocal then
			emitCameraTrauma(isSovereign and 0.54 or 0.38, isSovereign and 6.0 or 3.5)
		end
	end)

	-- Stage 3 (0.38s): Wing-Unfurl Sonic Booms & Sovereign Roar Maw Cone locked to live 3D Dragon bones!
	task.delay(0.38, function()
		if not folder.Parent then return end
		local liveAnchors = DragonSovereignVFX.ResolveDragonStateAndAnchors(actorChar, cPos, nil)
		spawnShockRing(liveAnchors.WingL_CF.Position, liveAnchors.WingL_CF, PALETTE.Violet, 1.8, 12.5 * scale, 0.22, 0.36, Enum.Material.ForceField, folder)
		spawnShockRing(liveAnchors.WingR_CF.Position, liveAnchors.WingR_CF, PALETTE.Violet, 1.8, 12.5 * scale, 0.22, 0.36, Enum.Material.ForceField, folder)
		spawnShockRing(liveAnchors.MawCF.Position, liveAnchors.MawCF * CFrame.Angles(math.pi * 0.5, 0, 0), PALETTE.HotCore, 1.6, 15.0 * scale, 0.26, 0.40, Enum.Material.ForceField, folder)
	end)
end

-- ============================================================================
-- 4. [M1] DRACONIC QUAD-TALON REND & ABYSSAL FANG SNAP-BITE FINISHER
-- ============================================================================
function DragonSovereignVFX.SpawnDragonM1(actorChar, startPos, lookDir, combo, isHeavy, isAwakened, isLocal)
	local anchors = DragonSovereignVFX.ResolveDragonStateAndAnchors(actorChar, startPos, lookDir)
	local tier = math.max(1, anchors.Tier)
	local scale = ((tier >= 2) and 1.38 or 1.0) * (isAwakened and 1.2 or 1.0)
	local idx = tonumber(combo) or 1
	local folder = Instance.new("Folder")
	folder.Name = "Dragon_M1_VFX"
	folder.Parent = (getTempFolder())
	Debris:AddItem(folder, 0.65)

	local isBiteFinisher = isHeavy or (idx % 4 == 0)
	local side = (idx % 2 == 0) and 1 or -1
	local originCF = isBiteFinisher and anchors.MawCF or ((side > 0) and anchors.ClawR_CF or anchors.ClawL_CF)
	local strikeCenter = originCF.Position + anchors.LookDir * (3.8 * scale)

	DragonSovereignVFX.EmitPrefab("Dragon_M1_TalonRend", CFrame.lookAt(strikeCenter, strikeCenter + anchors.LookDir), scale)

	if not isBiteFinisher then
		-- 4 Parallel Curved Crimson-Obsidian Dragon Talon Crescent Slashes
		local slashTilt = side * 0.52 + ((idx == 3) and -side * 0.25 or 0)
		local sweepCF = CFrame.lookAt(originCF.Position + anchors.LookDir * (1.8 * scale), originCF.Position + anchors.LookDir * (12 * scale))
			* CFrame.Angles(0, 0, slashTilt)

		for claw = 1, 4 do
			local lane = (claw - 2.5) * 0.72 * scale
			local col = (claw == 2 or claw == 3) and PALETTE.Crimson or PALETTE.Violet
			local arc = makePart(
				"DragonTalonArc_" .. claw,
				Enum.PartType.Cylinder,
				Vector3.new(0.22 * scale, (5.4 + claw * 0.35) * scale, (5.4 + claw * 0.35) * scale),
				sweepCF * CFrame.new(0, lane, 0) * CFrame.Angles(0, 0, math.pi * 0.5),
				col,
				0.08,
				Enum.Material.ForceField,
				folder
			)
			local darkCore = makePart(
				"DragonTalonVoidCore_" .. claw,
				Enum.PartType.Block,
				Vector3.new(6.8 * scale, 0.16 * scale, 0.34 * scale),
				sweepCF * CFrame.new(0, lane, -1.2 * scale) * CFrame.Angles(0, side * 0.22, 0),
				(claw == 2) and PALETTE.HotCore or PALETTE.Obsidian,
				0.04,
				Enum.Material.SmoothPlastic,
				folder
			)
			if claw == 2 then
				makeSafeLight(arc, PALETTE.Crimson, 1.2, 13, 0.24)
			end
			TweenService:Create(arc, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				CFrame = arc.CFrame * CFrame.new(0, 0, -4.4 * scale),
				Size = Vector3.new(0.06, 9.8 * scale, 9.8 * scale),
				Transparency = 1,
			}):Play()
			TweenService:Create(darkCore, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				CFrame = darkCore.CFrame * CFrame.new(0, 0, -4.8 * scale),
				Size = Vector3.new(11.2 * scale, 0.06, 0.12),
				Transparency = 1,
			}):Play()
		end
		if isLocal then
			emitCameraTrauma(0.18, 1.2, anchors.LookDir)
		end
	else
		-- Combo 4 / Heavy: Abyssal Sovereign Snap-Bite Jaws slamming shut at FX_BreathCore!
		local biteCF = CFrame.lookAt(anchors.MawCF.Position + anchors.LookDir * (2.6 * scale), anchors.MawCF.Position + anchors.LookDir * (14 * scale))
		makeSafeLight(makePart("BiteFlashAnchor", Enum.PartType.Ball, Vector3.new(1.4, 1.4, 1.4) * scale, biteCF, PALETTE.HotCore, 0.1, Enum.Material.ForceField, folder), PALETTE.Crimson, 1.35, 15, 0.32)

		for fangIdx = -2, 2 do
			local xOff = fangIdx * 1.05 * scale
			local fangLen = (3.4 - math.abs(fangIdx) * 0.42) * scale
			-- Upper Fang slamming down
			local upFang = makePart(
				"UpperAbyssFang_" .. fangIdx,
				Enum.PartType.Wedge,
				Vector3.new(0.58 * scale, fangLen, 0.82 * scale),
				biteCF * CFrame.new(xOff, 2.8 * scale, -1.2 * scale) * CFrame.Angles(math.pi, 0, 0),
				(fangIdx == 0) and PALETTE.HotCore or PALETTE.Crimson,
				0.04,
				Enum.Material.ForceField,
				folder
			)
			-- Lower Fang slamming up
			local lowFang = makePart(
				"LowerAbyssFang_" .. fangIdx,
				Enum.PartType.Wedge,
				Vector3.new(0.54 * scale, fangLen * 0.9, 0.78 * scale),
				biteCF * CFrame.new(xOff, -2.6 * scale, -1.2 * scale),
				(math.abs(fangIdx) == 1) and PALETTE.Violet or PALETTE.Crimson,
				0.04,
				Enum.Material.ForceField,
				folder
			)
			TweenService:Create(upFang, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				CFrame = biteCF * CFrame.new(xOff * 0.85, 0.35 * scale, -3.4 * scale) * CFrame.Angles(math.pi - 0.25, 0, 0),
			}):Play()
			TweenService:Create(lowFang, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				CFrame = biteCF * CFrame.new(xOff * 0.85, -0.35 * scale, -3.4 * scale) * CFrame.Angles(0.25, 0, 0),
			}):Play()
			task.delay(0.17, function()
				if upFang.Parent then TweenService:Create(upFang, TweenInfo.new(0.18), { Transparency = 1 }):Play() end
				if lowFang.Parent then TweenService:Create(lowFang, TweenInfo.new(0.18), { Transparency = 1 }):Play() end
			end)
		end

		task.delay(0.15, function()
			if not folder.Parent then return end
			local crunchPos = (biteCF * CFrame.new(0, 0, -3.4 * scale)).Position
			spawnShockRing(crunchPos, biteCF * CFrame.Angles(math.pi * 0.5, 0, 0), PALETTE.Crimson, 1.8, 12.5 * scale, 0.28, 0.32, Enum.Material.ForceField, folder)
			spawnShockRing(crunchPos, biteCF * CFrame.Angles(math.pi * 0.5, 0, 0), PALETTE.HotCore, 1.2, 8.5 * scale, 0.18, 0.24, Enum.Material.ForceField, folder)
			if isLocal then
				emitCameraTrauma(0.32, 2.4, anchors.LookDir)
			end
		end)
	end
end

-- ============================================================================
-- 5. [Z] SOVEREIGN ABYSSAL BREATH (TRIPLE-CORE HELICAL BOLO HYPER-BEAM)
-- Locked directly to Bone `FX_BreathCore` (`Jaw`) on the 3D Blender Dragon!
-- ============================================================================
function DragonSovereignVFX.SpawnSovereignBreath(actorChar, startPos, endPos, lookDir, baseScale, isAwakened, isLocal)
	local anchors = DragonSovereignVFX.ResolveDragonStateAndAnchors(actorChar, startPos, lookDir)
	local tierMult = (anchors.Tier >= 2 and 1.32) or (anchors.Tier == 1 and 1.12 or 1.0)
	local scale = (baseScale or 1.0) * tierMult
	local mawOrigin = anchors.MawCF.Position

	local rawVec = endPos - mawOrigin
	local beamLen = math.clamp(rawVec.Magnitude, 24 * scale, 48 * scale)
	local beamDir = (rawVec.Magnitude > 3) and rawVec.Unit or anchors.LookDir
	local impactPos = mawOrigin + beamDir * beamLen
	local beamAimCF = CFrame.lookAt(mawOrigin, impactPos)

	local folder = Instance.new("Folder")
	folder.Name = "Dragon_Z_SovereignBreath"
	folder.Parent = (getTempFolder())
	local totalDur = 0.88
	Debris:AddItem(folder, totalDur + 0.35)

	DragonSovereignVFX.EmitPrefab("Dragon_Z_SovereignBreath", beamAimCF, scale)

	-- Stage 1 (0.00s - 0.10s): Maw Vacuum Compression Orb & Double Runic Muzzle Halos at FX_BreathCore
	local mawOrb = makePart("MawCompressionCore", Enum.PartType.Ball, Vector3.new(1.4, 1.4, 1.4) * scale, beamAimCF, PALETTE.HotCore, 0.02, Enum.Material.SmoothPlastic, folder)
	local mawShell = makePart("MawCompressionShell", Enum.PartType.Ball, Vector3.new(2.6, 2.6, 2.6) * scale, beamAimCF, PALETTE.Crimson, 0.18, Enum.Material.ForceField, folder)
	local muzzleRing1 = makePart("MawRunicHalo1", Enum.PartType.Cylinder, Vector3.new(0.24 * scale, 5.6 * scale, 5.6 * scale), beamAimCF * CFrame.Angles(0, math.pi * 0.5, 0), PALETTE.Crimson, 0.12, Enum.Material.ForceField, folder)
	local muzzleRing2 = makePart("MawRunicHalo2", Enum.PartType.Cylinder, Vector3.new(0.18 * scale, 7.8 * scale, 7.8 * scale), beamAimCF * CFrame.Angles(0, math.pi * 0.5, 0), PALETTE.Violet, 0.18, Enum.Material.ForceField, folder)
	makeSafeLight(mawOrb, PALETTE.Crimson, 1.42, 16, totalDur)

	TweenService:Create(mawOrb, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = Vector3.new(3.2, 3.2, 3.2) * scale }):Play()
	TweenService:Create(mawShell, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = Vector3.new(4.8, 4.8, 4.8) * scale }):Play()

	-- Stage 2: Triple-Core Coaxial Bolo Hyper-Beam + Helical Dragon Ribbons + 8 Mach Compression Rings + Scorched Magma Trench
	local midCF = CFrame.lookAt((mawOrigin + impactPos) * 0.5, impactPos) * CFrame.Angles(0, math.pi * 0.5, 0)
	local rInner = 1.65 * scale
	local rPlasma = 3.6 * scale
	local rVoid = 5.2 * scale

	local innerBeam = makePart("BoloHotCore", Enum.PartType.Cylinder, Vector3.new(beamLen, 0.4, 0.4), midCF, PALETTE.HotCore, 0.02, Enum.Material.SmoothPlastic, folder)
	local plasmaBeam = makePart("BoloCrimsonPlasma", Enum.PartType.Cylinder, Vector3.new(beamLen, 0.9, 0.9), midCF, PALETTE.Crimson, 0.14, Enum.Material.ForceField, folder)
	local voidMantle = makePart("BoloObsidianMantle", Enum.PartType.Cylinder, Vector3.new(beamLen, 1.4, 1.4), midCF, PALETTE.Obsidian, 0.28, Enum.Material.ForceField, folder)

	TweenService:Create(innerBeam, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = Vector3.new(beamLen, rInner, rInner) }):Play()
	TweenService:Create(plasmaBeam, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = Vector3.new(beamLen, rPlasma, rPlasma) }):Play()
	TweenService:Create(voidMantle, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = Vector3.new(beamLen, rVoid, rVoid) }):Play()

	local machCount = isLowFX() and 4 or 8
	local machRings = {}
	for i = 1, machCount do
		local col = (i % 2 == 0) and PALETTE.Crimson or PALETTE.Violet
		local mr = makePart("BoloMachRing_" .. i, Enum.PartType.Cylinder, Vector3.new(0.26 * scale, rPlasma * 1.15, rPlasma * 1.15), beamAimCF * CFrame.new(0, 0, -(i / machCount) * beamLen) * CFrame.Angles(0, math.pi * 0.5, 0), col, 0.14, Enum.Material.ForceField, folder)
		table.insert(machRings, { Part = mr, Index = i })
	end

	-- Scorched Molten Magma Ground Trench beneath beam
	local trenchCount = isLowFX() and 3 or 6
	for t = 1, trenchCount do
		local p = mawOrigin:Lerp(impactPos, t / trenchCount)
		local gp = findGroundPos(p, actorChar)
		if math.abs(p.Y - gp.Y) < 16 then
			local seam = makePart(
				"ScorchedMagmaTrench_" .. t,
				Enum.PartType.Block,
				Vector3.new(2.4 * scale, 0.16, (beamLen / trenchCount) * 0.88),
				CFrame.lookAt(gp + Vector3.new(0, 0.08, 0), gp + Vector3.new(0, 0.08, 0) + Vector3.new(beamDir.X, 0, beamDir.Z) + Vector3.new(0, 0, 0.001)),
				(t % 2 == 0) and PALETTE.Magma or PALETTE.Crimson,
				0.18,
				Enum.Material.ForceField,
				folder
			)
			TweenService:Create(seam, TweenInfo.new(0.85, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Size = Vector3.new(0.5, 0.05, (beamLen / trenchCount) * 0.88),
				Transparency = 1,
			}):Play()
		end
	end

	local helixNodes = {}
	if not isLowFX() then
		for h = 1, 2 do
			local col = (h == 1) and PALETTE.HotCore or PALETTE.Violet
			local hn = makePart("BoloHelixSpirit_" .. h, Enum.PartType.Ball, Vector3.new(0.85, 0.85, 1.4) * scale, beamAimCF, col, 0.06, Enum.Material.ForceField, folder)
			attachRibbonTrail(hn, col, (h == 1) and PALETTE.Crimson or PALETTE.Magma, 1.25 * scale, 0.24)
			table.insert(helixNodes, { Node = hn, Phase = (h - 1) * math.pi })
		end
	end

	-- Stage 3 (0.14s): Terminal Abyssal Singularity & Obsidian Fang Crater at Impact
	task.delay(0.14, function()
		if not folder.Parent then return end
		local gImpact = findGroundPos(impactPos, actorChar)
		DragonSovereignVFX.EmitPrefab("Dragon_Z_SovereignBreath", CFrame.new(impactPos), scale * 1.15)

		local singCore = makePart("TerminalSingularityCore", Enum.PartType.Ball, Vector3.new(3.2, 3.2, 3.2) * scale, CFrame.new(impactPos), PALETTE.Obsidian, 0.04, Enum.Material.SmoothPlastic, folder)
		local singCorona = makePart("TerminalSingularityCorona", Enum.PartType.Ball, Vector3.new(5.2, 5.2, 5.2) * scale, CFrame.new(impactPos), PALETTE.Crimson, 0.14, Enum.Material.ForceField, folder)
		local singOuter = makePart("TerminalSingularityViolet", Enum.PartType.Ball, Vector3.new(6.8, 6.8, 6.8) * scale, CFrame.new(impactPos), PALETTE.Violet, 0.26, Enum.Material.ForceField, folder)
		makeSafeLight(singCore, PALETTE.Crimson, 1.42, 16, 0.68)

		TweenService:Create(singCore, TweenInfo.new(0.56, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = Vector3.new(18, 18, 18) * scale, Transparency = 1 }):Play()
		TweenService:Create(singCorona, TweenInfo.new(0.64, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = Vector3.new(25, 25, 25) * scale, Transparency = 1 }):Play()
		TweenService:Create(singOuter, TweenInfo.new(0.70, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = Vector3.new(31, 31, 31) * scale, Transparency = 1 }):Play()

		spawnShockRing(gImpact + Vector3.new(0, 0.2, 0), nil, PALETTE.Crimson, 4, 30 * scale, 0.34, 0.58, Enum.Material.ForceField, folder)
		spawnShockRing(gImpact + Vector3.new(0, 0.45, 0), nil, PALETTE.Magma, 3, 22 * scale, 0.24, 0.48, Enum.Material.ForceField, folder)

		local craterSpikes = isLowFX() and 5 or 9
		for s = 1, craterSpikes do
			local ang = (s - 1) * ((math.pi * 2) / craterSpikes)
			local cr = 7.4 * scale
			local spPos = gImpact + Vector3.new(math.cos(ang) * cr, -0.6, math.sin(ang) * cr)
			local shard = makePart(
				"BreathCraterSpike_" .. s,
				Enum.PartType.Wedge,
				Vector3.new(1.4 * scale, 5.2 * scale, 1.9 * scale),
				CFrame.lookAt(spPos, gImpact + Vector3.new(0, 4.5 * scale, 0)) * CFrame.Angles(-0.35, 0, 0),
				(s % 3 == 0) and PALETTE.Magma or ((s % 2 == 0) and PALETTE.SlateArmor or PALETTE.Crimson),
				0.08,
				(s % 2 == 0) and Enum.Material.Slate or Enum.Material.ForceField,
				folder
			)
			TweenService:Create(shard, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				CFrame = shard.CFrame * CFrame.new(0, 2.2 * scale, 0),
			}):Play()
			task.delay(0.45, function()
				if shard.Parent then
					TweenService:Create(shard, TweenInfo.new(0.28), { Transparency = 1 }):Play()
				end
			end)
		end
	end)

	local t0 = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local el = os.clock() - t0
		if el >= totalDur or not folder.Parent then
			if conn then conn:Disconnect() end
			return
		end
		local u = el / totalDur
		local pulse = 1 + 0.16 * math.sin(el * 36)

		-- Follow live FX_BreathCore bone while roaring!
		local liveMawPos = mawOrigin
		if anchors.Model and anchors.Model.Parent then
			local b = anchors.Bones["FX_BreathCore"] or anchors.Bones["Jaw"] or anchors.Bones["Head"]
			if b then
				local ok, wcf = pcall(function() return b.TransformedWorldCFrame end)
				if ok and typeof(wcf) == "CFrame" then
					liveMawPos = wcf.Position
				end
			end
		end
		local liveAim = safeLookAt(liveMawPos, impactPos, beamDir)
		local liveLen = math.max(4, (impactPos - liveMawPos).Magnitude)
		local liveMid = safeLookAt((liveMawPos + impactPos) * 0.5, impactPos, beamDir) * CFrame.Angles(0, math.pi * 0.5, 0)

		mawOrb.CFrame = liveAim
		mawShell.CFrame = liveAim
		muzzleRing1.CFrame = liveAim * CFrame.Angles(el * 12, math.pi * 0.5, 0)
		muzzleRing2.CFrame = liveAim * CFrame.Angles(-el * 9, math.pi * 0.5, 0)
		muzzleRing1.Size = Vector3.new(0.24 * scale, 5.8 * scale * pulse, 5.8 * scale * pulse)
		muzzleRing2.Size = Vector3.new(0.18 * scale, 8.0 * scale * pulse, 8.0 * scale * pulse)

		innerBeam.CFrame = liveMid
		plasmaBeam.CFrame = liveMid
		voidMantle.CFrame = liveMid

		if el > 0.22 and el <= 0.58 then
			innerBeam.Size = Vector3.new(liveLen, rInner * pulse, rInner * pulse)
			plasmaBeam.Size = Vector3.new(liveLen, rPlasma * pulse, rPlasma * pulse)
			voidMantle.Size = Vector3.new(liveLen, rVoid * (2 - pulse * 0.9), rVoid * (2 - pulse * 0.9))
		elseif el > 0.58 then
			local fade = (el - 0.58) / (totalDur - 0.58)
			innerBeam.Size = Vector3.new(liveLen, rInner * (1 - fade), rInner * (1 - fade))
			plasmaBeam.Size = Vector3.new(liveLen, rPlasma * (1 - fade * 0.72), rPlasma * (1 - fade * 0.72))
			voidMantle.Size = Vector3.new(liveLen, rVoid * (1 - fade * 0.5), rVoid * (1 - fade * 0.5))
			innerBeam.Transparency = fade
			plasmaBeam.Transparency = 0.14 + fade * 0.86
			voidMantle.Transparency = 0.28 + fade * 0.72
			mawOrb.Transparency = fade
			mawShell.Transparency = 0.18 + fade * 0.82
			muzzleRing1.Transparency = 0.12 + fade * 0.88
			muzzleRing2.Transparency = 0.18 + fade * 0.82
		end

		for _, mr in ipairs(machRings) do
			if mr.Part and mr.Part.Parent then
				local travel = ((el * 48 + (mr.Index - 1) * (liveLen / machCount)) % liveLen)
				local rSz = (rPlasma * 1.28 + math.sin(el * 22 + mr.Index) * 1.1 * scale) * (1 - u * 0.35)
				mr.Part.CFrame = liveAim * CFrame.new(0, 0, -travel) * CFrame.Angles(el * 14 + mr.Index, math.pi * 0.5, 0)
				mr.Part.Size = Vector3.new(0.24 * scale, rSz, rSz)
				mr.Part.Transparency = math.clamp(0.12 + u * 0.88, 0.12, 1)
			end
		end

		for _, hn in ipairs(helixNodes) do
			if hn.Node and hn.Node.Parent then
				local zTravel = ((el * 62) % liveLen)
				local ang = el * 26 + hn.Phase
				local hRad = rPlasma * 0.68
				hn.Node.CFrame = liveAim * CFrame.new(math.cos(ang) * hRad, math.sin(ang) * hRad, -zTravel)
				if u > 0.72 then
					hn.Node.Transparency = (u - 0.72) / 0.28
				end
			end
		end
	end)

	if isLocal then
		emitCameraTrauma(0.50, 4.5, beamDir)
	end
end

-- ============================================================================
-- 6. [X] VOID TALONS CATACLYSMIC POUNCE (TWIN 4-CLAW X-CROSS & MOLTEN GOUGES)
-- Locked to `Paw_FL` & `Paw_FR` (`LeftHand`/`RightHand` on Hybrid)!
-- ============================================================================
function DragonSovereignVFX.SpawnVoidTalons(actorChar, startPos, endPos, lookDir, baseScale, isAwakened, isLocal)
	local anchors = DragonSovereignVFX.ResolveDragonStateAndAnchors(actorChar, startPos, lookDir)
	local tierMult = (anchors.Tier >= 2 and 1.30) or (anchors.Tier == 1 and 1.12 or 1.0)
	local scale = (baseScale or 1.0) * tierMult

	local originMid = (anchors.ClawL_CF.Position + anchors.ClawR_CF.Position) * 0.5
	local rawVec = endPos - originMid
	local lungeDist = math.clamp(rawVec.Magnitude, 18 * scale, 34 * scale)
	local dir = (rawVec.Magnitude > 3) and rawVec.Unit or anchors.LookDir
	local dstPos = originMid + dir * lungeDist
	local pathCF = CFrame.lookAt(originMid, dstPos)

	local folder = Instance.new("Folder")
	folder.Name = "Dragon_X_VoidTalons"
	folder.Parent = (getTempFolder())
	Debris:AddItem(folder, 1.05)

	DragonSovereignVFX.EmitPrefab("Dragon_X_VoidTalons", pathCF * CFrame.new(0, 0, -2.5 * scale), scale)

	-- Twin Colossal 4-Clawed Obsidian-Crimson Spectral Dragon Talons raking in X-Cross
	for _, side in ipairs({ -1, 1 }) do
		local pawStart = (side < 0) and anchors.ClawL_CF.Position or anchors.ClawR_CF.Position
		local startClawCF = safeLookAt(pawStart, dstPos, dir) * CFrame.new(side * 2.2 * scale, 1.8 * scale, 0) * CFrame.Angles(math.rad(-16), math.rad(-side * 24), math.rad(side * 38))
		local endClawCF = safeLookAt(dstPos, dstPos + dir, dir) * CFrame.new(-side * 2.8 * scale, -0.4 * scale, 1.2 * scale) * CFrame.Angles(math.rad(22), math.rad(side * 28), math.rad(-side * 42))

		local gauntlet = makePart("SpectralDragonPaw_" .. side, Enum.PartType.Block, Vector3.new(2.8, 1.0, 2.6) * scale, startClawCF, PALETTE.SlateArmor, 0.08, Enum.Material.Slate, folder)
		TweenService:Create(gauntlet, TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			CFrame = endClawCF,
			Transparency = 1,
		}):Play()

		for finger = 1, 4 do
			local fOff = (finger - 2.5) * 0.78 * scale
			local col = (finger % 2 == 0) and PALETTE.Crimson or PALETTE.Violet
			local blade = makePart("SpectralClawBlade_" .. side .. "_" .. finger, Enum.PartType.Wedge, Vector3.new(0.38, 0.62, 6.6) * scale, startClawCF * CFrame.new(fOff, 0, -3.0 * scale), col, 0.04, Enum.Material.ForceField, folder)
			local core = makePart("SpectralClawCore_" .. side .. "_" .. finger, Enum.PartType.Block, Vector3.new(0.20, 0.32, 7.2) * scale, startClawCF * CFrame.new(fOff, 0, -3.3 * scale), (finger == 2) and PALETTE.HotCore or PALETTE.Obsidian, 0.02, Enum.Material.SmoothPlastic, folder)
			if not isLowFX() and (finger == 1 or finger == 4) then
				attachRibbonTrail(blade, PALETTE.HotCore, col, 0.75 * scale, 0.22)
			end
			TweenService:Create(blade, TweenInfo.new(0.34, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				CFrame = endClawCF * CFrame.new(fOff * 1.35, 0, -4.2 * scale),
				Size = Vector3.new(0.18, 0.30, 10.4) * scale,
				Transparency = 1,
			}):Play()
			TweenService:Create(core, TweenInfo.new(0.34, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				CFrame = endClawCF * CFrame.new(fOff * 1.35, 0, -4.5 * scale),
				Size = Vector3.new(0.10, 0.16, 11.0) * scale,
				Transparency = 1,
			}):Play()
		end
	end

	-- 8 Suspended Spatial Void Rift Slash Gashes forming a blazing X-Cross
	local midRiftCF = pathCF * CFrame.new(0, 0.6 * scale, -lungeDist * 0.55)
	local gashTotal = isLowFX() and 4 or 8
	for g = 1, gashTotal do
		local side = (g <= gashTotal * 0.5) and -1 or 1
		local lane = ((g - 1) % math.max(1, gashTotal * 0.5)) - 1.5
		local gCF = midRiftCF * CFrame.Angles(0, 0, math.rad(side * 38)) * CFrame.new(0, lane * 0.95 * scale, -(g % 2) * 0.5)
		local gash = makePart("VoidRiftGash_" .. g, Enum.PartType.Block, Vector3.new(14.5 * scale, 0.28 * scale, 0.9 * scale), gCF, (g % 2 == 0) and PALETTE.Crimson or PALETTE.Violet, 0.04, Enum.Material.ForceField, folder)
		local gashCore = makePart("VoidRiftCore_" .. g, Enum.PartType.Block, Vector3.new(12.2 * scale, 0.42 * scale, 0.45 * scale), gCF, PALETTE.Obsidian, 0.02, Enum.Material.SmoothPlastic, folder)
		TweenService:Create(gash, TweenInfo.new(0.48, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = Vector3.new(22.0 * scale, 0.10, 1.8 * scale),
			CFrame = gCF * CFrame.new(0, 0, -2.8 * scale),
			Transparency = 1,
		}):Play()
		TweenService:Create(gashCore, TweenInfo.new(0.44, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = Vector3.new(18.5 * scale, 0.15, 0.9 * scale),
			CFrame = gCF * CFrame.new(0, 0, -2.8 * scale),
			Transparency = 1,
		}):Play()
	end

	-- 4 Parallel Molten Magma Claw-Gouge Trenches carved into ground + 8 Erupting Obsidian Fang Spires at Impact
	task.delay(0.18, function()
		if not folder.Parent then return end
		local gDst = findGroundPos(dstPos, actorChar)
		DragonSovereignVFX.EmitPrefab("Dragon_X_VoidTalons", CFrame.new(gDst + Vector3.new(0, 1.2, 0)), scale * 1.15)
		makeSafeLight(makePart("TalonImpactNode", Enum.PartType.Ball, Vector3.new(2.2, 2.2, 2.2) * scale, CFrame.new(gDst + Vector3.new(0, 1.4, 0)), PALETTE.HotCore, 0.15, Enum.Material.ForceField, folder), PALETTE.Crimson, 1.38, 16, 0.55)

		local flatDir = Vector3.new(dir.X, 0, dir.Z)
		flatDir = (flatDir.Magnitude > 0.05) and flatDir.Unit or Vector3.new(0, 0, -1)
		local gougeCF = CFrame.lookAt(gDst + Vector3.new(0, 0.10, 0), gDst + Vector3.new(0, 0.10, 0) + flatDir)

		for c = 1, 4 do
			local xOff = (c - 2.5) * 1.65 * scale
			local gouge = makePart(
				"MoltenClawGouge_" .. c,
				Enum.PartType.Block,
				Vector3.new(0.65 * scale, 0.16, 13.5 * scale),
				gougeCF * CFrame.new(xOff, 0, 2.2 * scale),
				(c % 2 == 0) and PALETTE.Magma or PALETTE.Crimson,
				0.10,
				Enum.Material.ForceField,
				folder
			)
			TweenService:Create(gouge, TweenInfo.new(0.68, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Size = Vector3.new(0.14, 0.05, 15.5 * scale),
				Transparency = 1,
			}):Play()
		end

		local spireCount = isLowFX() and 4 or 8
		for f = 1, spireCount do
			local ang = (f - 1) * ((math.pi * 2) / spireCount)
			local spPos = gDst + Vector3.new(math.cos(ang) * 5.8 * scale, -0.8, math.sin(ang) * 5.8 * scale)
			local h = 7.8 * scale
			local spire = makePart(
				"TalonObsidianSpire_" .. f,
				Enum.PartType.Wedge,
				Vector3.new(1.45 * scale, h, 1.95 * scale),
				CFrame.lookAt(spPos, gDst + Vector3.new(0, h, 0)) * CFrame.Angles(-0.30, 0, 0),
				(f % 2 == 0) and PALETTE.SlateArmor or PALETTE.Crimson,
				0.06,
				(f % 2 == 0) and Enum.Material.Slate or Enum.Material.ForceField,
				folder
			)
			TweenService:Create(spire, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				CFrame = spire.CFrame * CFrame.new(0, h * 0.44, 0),
			}):Play()
			task.delay(0.42, function()
				if spire.Parent then
					TweenService:Create(spire, TweenInfo.new(0.28), { Transparency = 1 }):Play()
				end
			end)
		end

		spawnShockRing(gDst + Vector3.new(0, 0.22, 0), nil, PALETTE.Crimson, 3.5, 26 * scale, 0.30, 0.50, Enum.Material.ForceField, folder)
		spawnShockRing(gDst + Vector3.new(0, 0.45, 0), nil, PALETTE.Violet, 2.5, 19 * scale, 0.22, 0.42, Enum.Material.ForceField, folder)
		if isLocal then
			emitCameraTrauma(0.44, 3.4, dir)
		end
	end)
end

-- ============================================================================
-- 7. [C] CATACLYSMIC STARSHOWER & SERPENTINE ABYSSAL MAELSTROM
-- Projects from `FX_CrownHalo` -> Overhead Eclipse Stargate -> 10 Trailing Meteors!
-- ============================================================================
function DragonSovereignVFX.SpawnCataclysmicStarshower(actorChar, startPos, endPos, lookDir, baseScale, isAwakened, isLocal)
	local anchors = DragonSovereignVFX.ResolveDragonStateAndAnchors(actorChar, startPos, lookDir)
	local tierMult = (anchors.Tier >= 2 and 1.32) or (anchors.Tier == 1 and 1.12 or 1.0)
	local scale = (baseScale or 1.0) * tierMult

	local targetCenter = ((endPos - anchors.CenterPos).Magnitude > 3) and endPos or (anchors.CenterPos + anchors.LookDir * (20 * scale))
	local gCenter = findGroundPos(targetCenter, actorChar)
	local skyCenter = gCenter + Vector3.new(0, 28 * scale, 0)

	local folder = Instance.new("Folder")
	folder.Name = "Dragon_C_CataclysmicStarshower"
	folder.Parent = (getTempFolder())
	local totalDur = 1.18
	Debris:AddItem(folder, totalDur + 0.4)

	-- Skyward Beacon Beam shooting from Dragon's `FX_CrownHalo` to Overhead Eclipse Stargate!
	local crownPos = anchors.CrownCF.Position
	local beaconVec = skyCenter - crownPos
	local beaconLen = math.max(6, beaconVec.Magnitude)
	local beaconPart = makePart(
		"CrownSkyBeacon",
		Enum.PartType.Cylinder,
		Vector3.new(beaconLen, 1.4 * scale, 1.4 * scale),
		CFrame.lookAt((crownPos + skyCenter) * 0.5, skyCenter) * CFrame.Angles(0, math.pi * 0.5, 0),
		PALETTE.Crimson,
		0.12,
		Enum.Material.ForceField,
		folder
	)
	TweenService:Create(beaconPart, TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = Vector3.new(beaconLen, 0.12, 0.12),
		Transparency = 1,
	}):Play()

	-- Overhead Sovereign Eclipse Stargate (Obsidian Core + Crimson Runic Halo + Violet Outer Ring)
	local eclipseCore = makePart("SovereignEclipseCore", Enum.PartType.Cylinder, Vector3.new(0.55, 4, 4), CFrame.new(skyCenter) * CFrame.Angles(0, 0, math.pi * 0.5), PALETTE.Obsidian, 0.04, Enum.Material.SmoothPlastic, folder)
	local eclipseCrimson = makePart("SovereignEclipseCrimson", Enum.PartType.Cylinder, Vector3.new(0.42, 6, 6), eclipseCore.CFrame, PALETTE.Crimson, 0.12, Enum.Material.ForceField, folder)
	local eclipseViolet = makePart("SovereignEclipseViolet", Enum.PartType.Cylinder, Vector3.new(0.28, 8, 8), eclipseCore.CFrame, PALETTE.Violet, 0.20, Enum.Material.ForceField, folder)

	TweenService:Create(eclipseCore, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = Vector3.new(0.55, 19 * scale, 19 * scale) }):Play()
	TweenService:Create(eclipseCrimson, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = Vector3.new(0.42, 26 * scale, 26 * scale) }):Play()
	TweenService:Create(eclipseViolet, TweenInfo.new(0.36, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = Vector3.new(0.28, 33 * scale, 33 * scale) }):Play()

	-- Ground Target Abyssal Seal + Live Swirling Serpentine Fire-Vortex Maelstrom
	local groundSeal = makePart("StarfallGroundSeal", Enum.PartType.Cylinder, Vector3.new(0.16, 4, 4), CFrame.new(gCenter + Vector3.new(0, 0.14, 0)) * CFrame.Angles(0, 0, math.pi * 0.5), PALETTE.Crimson, 0.18, Enum.Material.ForceField, folder)
	TweenService:Create(groundSeal, TweenInfo.new(0.30, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.16, 26 * scale, 26 * scale),
	}):Play()

	local vortexNodes = {}
	if not isLowFX() then
		for v = 1, 2 do
			local col = (v == 1) and PALETTE.Crimson or PALETTE.Violet
			local vn = makePart("MaelstromSerpent_" .. v, Enum.PartType.Ball, Vector3.new(1.3, 1.3, 2.0) * scale, CFrame.new(gCenter), col, 0.06, Enum.Material.ForceField, folder)
			attachRibbonTrail(vn, (v == 1) and PALETTE.HotCore or PALETTE.Magma, col, 1.75 * scale, 0.30)
			table.insert(vortexNodes, { Node = vn, Phase = (v - 1) * math.pi })
		end
	end

	local t0 = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local el = os.clock() - t0
		if el >= totalDur or not folder.Parent then
			if conn then conn:Disconnect() end
			return
		end
		local u = el / totalDur
		eclipseCrimson.CFrame = CFrame.new(skyCenter) * CFrame.Angles(0, el * 4.5, math.pi * 0.5)
		eclipseViolet.CFrame = CFrame.new(skyCenter) * CFrame.Angles(0, -el * 3.2, math.pi * 0.5)
		groundSeal.CFrame = CFrame.new(gCenter + Vector3.new(0, 0.14, 0)) * CFrame.Angles(0, el * 3.8, math.pi * 0.5)

		for _, vn in ipairs(vortexNodes) do
			if vn.Node and vn.Node.Parent then
				local ang = el * 14 + vn.Phase
				local vRad = (4.5 + math.sin(el * 6 + vn.Phase) * 3.8) * scale
				local vY = ((el * 20 + vn.Phase * 2) % (18 * scale))
				local p = gCenter + Vector3.new(math.cos(ang) * vRad, vY, math.sin(ang) * vRad)
				local tan = Vector3.new(-math.sin(ang), 0.38, math.cos(ang)).Unit
				vn.Node.CFrame = CFrame.lookAt(p, p + tan)
				if u > 0.78 then
					vn.Node.Transparency = (u - 0.78) / 0.22
				end
			end
		end

		if u > 0.76 then
			local f = (u - 0.76) / 0.24
			eclipseCore.Transparency = f
			eclipseCrimson.Transparency = 0.12 + f * 0.88
			eclipseViolet.Transparency = 0.20 + f * 0.80
			groundSeal.Transparency = 0.18 + f * 0.82
		end
	end)

	-- 10 Diagonal Obsidian-Crimson Draconic Starfall Meteors raining from Eclipse Stargate!
	local meteorCount = isLowFX() and 5 or 10
	for m = 1, meteorCount do
		task.delay(0.08 + (m - 1) * 0.068, function()
			if not folder.Parent then return end
			local isFinal = (m == meteorCount)
			local ang = (m - 1) * 2.39996 -- Golden angle distribution for natural meteor spread
			local spreadR = isFinal and 0 or (math.sqrt(m / meteorCount) * 11.5 * scale)
			local hitPos = gCenter + Vector3.new(math.cos(ang) * spreadR, 0, math.sin(ang) * spreadR)
			local spawnPos = skyCenter + Vector3.new(math.cos(ang) * (spreadR * 0.45) - 4.2 * scale, 1.5, math.sin(ang) * (spreadR * 0.45) - 3.0 * scale)

			local mSz = (isFinal and 5.4 or 2.8) * scale
			local rock = makePart("DraconicMeteorCore_" .. m, Enum.PartType.Ball, Vector3.new(mSz, mSz, mSz), CFrame.lookAt(spawnPos, hitPos), PALETTE.SlateArmor, 0.04, Enum.Material.Slate, folder)
			local corona = makePart("DraconicMeteorCorona_" .. m, Enum.PartType.Ball, Vector3.new(mSz * 1.32, mSz * 1.32, mSz * 1.32), rock.CFrame, (m % 2 == 0) and PALETTE.Crimson or PALETTE.Magma, 0.20, Enum.Material.ForceField, folder)
			if not isLowFX() then
				attachRibbonTrail(rock, PALETTE.HotCore, (m % 2 == 0) and PALETTE.Crimson or PALETTE.Magma, mSz * 0.85, 0.26)
			end

			local fallDur = isFinal and 0.30 or 0.24
			TweenService:Create(rock, TweenInfo.new(fallDur, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = CFrame.lookAt(hitPos, hitPos + (hitPos - spawnPos)) }):Play()
			TweenService:Create(corona, TweenInfo.new(fallDur, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = CFrame.lookAt(hitPos, hitPos + (hitPos - spawnPos)) }):Play()

			task.delay(fallDur, function()
				if rock.Parent then rock:Destroy() end
				if corona.Parent then corona:Destroy() end
				if not folder.Parent then return end

				spawnShockRing(hitPos + Vector3.new(0, 0.18, 0), nil, (m % 2 == 0) and PALETTE.Crimson or PALETTE.Violet, 1.8, (isFinal and 30 or 12.5) * scale, isFinal and 0.36 or 0.22, isFinal and 0.56 or 0.34, Enum.Material.ForceField, folder)
				if m % 3 == 1 or isFinal then
					DragonSovereignVFX.EmitPrefab("Dragon_C_CataclysmicStarshower", CFrame.new(hitPos + Vector3.new(0, 0.8, 0)), isFinal and (scale * 1.25) or (scale * 0.8))
				end
				if isFinal then
					local blast = makePart("FinalStarfallSupernova", Enum.PartType.Ball, Vector3.new(4, 4, 4) * scale, CFrame.new(hitPos), PALETTE.Crimson, 0.14, Enum.Material.ForceField, folder)
					makeSafeLight(blast, PALETTE.Crimson, 1.42, 16, 0.58)
					TweenService:Create(blast, TweenInfo.new(0.50, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
						Size = Vector3.new(26, 26, 26) * scale,
						Transparency = 1,
					}):Play()
					if isLocal then
						emitCameraTrauma(0.56, 5.5)
					end
				elseif isLocal and m % 2 == 0 then
					emitCameraTrauma(0.18, 0.8)
				end
			end)
		end)
	end
end

-- ============================================================================
-- 8. [F] SOARING SOVEREIGN SLIPSTREAM RUSH (MACH CONES & WINGTIP VORTEX)
-- ============================================================================
function DragonSovereignVFX.SpawnSoaringRush(actorChar, startPos, endPos, lookDir, baseScale, isAwakened, isLocal)
	local anchors = DragonSovereignVFX.ResolveDragonStateAndAnchors(actorChar, startPos, lookDir)
	local tierMult = (anchors.Tier >= 2 and 1.30) or (anchors.Tier == 1 and 1.12 or 1.0)
	local scale = (baseScale or 1.0) * tierMult

	local p0 = anchors.CenterPos
	local rawVec = endPos - p0
	local rushDist = math.clamp(rawVec.Magnitude, 20 * scale, 36 * scale)
	local dir = (rawVec.Magnitude > 3) and rawVec.Unit or anchors.LookDir
	local p1 = p0 + dir * rushDist
	local rushCF = CFrame.lookAt(p0, p1)

	local folder = Instance.new("Folder")
	folder.Name = "Dragon_F_SoaringRush"
	folder.Parent = (getTempFolder())
	Debris:AddItem(folder, 0.85)

	DragonSovereignVFX.EmitPrefab("Dragon_F_SoarRush", rushCF, scale)
	makeSafeLight(makePart("RushSonicCore", Enum.PartType.Ball, Vector3.new(1.8, 1.8, 1.8) * scale, rushCF, PALETTE.HotCore, 0.14, Enum.Material.ForceField, folder), PALETTE.Violet, 1.30, 15, 0.42)

	-- 6 Expanding Supersonic Mach Cones along flight path
	local coneCount = isLowFX() and 3 or 6
	for i = 1, coneCount do
		local frac = (i - 1) / math.max(1, coneCount - 1)
		task.delay((i - 1) * 0.028, function()
			if not folder.Parent then return end
			local pt = p0:Lerp(p1, frac)
			local col = (i % 2 == 0) and PALETTE.Crimson or PALETTE.Violet
			local ring = makePart(
				"SupersonicMachRing_" .. i,
				Enum.PartType.Cylinder,
				Vector3.new(0.32 * scale, (3.6 + frac * 2.2) * scale, (3.6 + frac * 2.2) * scale),
				CFrame.lookAt(pt, pt + dir) * CFrame.Angles(0, math.pi * 0.5, i * 0.6),
				col,
				0.12,
				Enum.Material.ForceField,
				folder
			)
			TweenService:Create(ring, TweenInfo.new(0.38, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = Vector3.new(0.08, (11.5 + frac * 3.5) * scale, (11.5 + frac * 3.5) * scale),
				Transparency = 1,
			}):Play()
		end)
	end

	-- Dual Helical Wingtip Slipstream Ribbons racing from `WingForearm_L/R` to `p1`
	if not isLowFX() then
		local spirits = {}
		for idx, side in ipairs({ -1, 1 }) do
			local wStart = (side < 0) and anchors.WingL_CF.Position or anchors.WingR_CF.Position
			local col = (idx == 1) and PALETTE.Crimson or PALETTE.Violet
			local sp = makePart("WingtipSlipstream_" .. idx, Enum.PartType.Ball, Vector3.new(0.8, 0.8, 1.4) * scale, safeLookAt(wStart, p1, dir), col, 0.06, Enum.Material.ForceField, folder)
			attachRibbonTrail(sp, PALETTE.HotCore, col, 1.35 * scale, 0.28)
			table.insert(spirits, { Node = sp, Phase = (idx - 1) * math.pi })
		end

		local t0 = os.clock()
		local conn
		conn = RunService.Heartbeat:Connect(function()
			local el = os.clock() - t0
			if el >= 0.36 or not folder.Parent then
				if conn then conn:Disconnect() end
				return
			end
			local u = el / 0.36
			for _, sp in ipairs(spirits) do
				if sp.Node and sp.Node.Parent then
					local ang = u * math.pi * 3.5 + sp.Phase
					local rad = (3.8 * (1 - u * 0.45)) * scale
					sp.Node.CFrame = rushCF * CFrame.new(math.cos(ang) * rad, math.sin(ang) * rad, -u * rushDist)
				end
			end
		end)
	end

	if isLocal then
		emitCameraTrauma(0.28, 3.0, dir)
	end
end

-- ============================================================================
-- 9. UNIFIED DISPATCHER FOR ALL DRAGON MOVES & TRANSFORMATIONS
-- ============================================================================
function DragonSovereignVFX.DispatchMove(moveKey, actorChar, startPos, endPos, lookDir, scale, isAwakened, isLocal, fx)
	local k = tostring(moveKey or "Z"):upper()
	if k == "Z" then
		DragonSovereignVFX.SpawnSovereignBreath(actorChar, startPos, endPos, lookDir, scale, isAwakened, isLocal)
	elseif k == "X" then
		DragonSovereignVFX.SpawnVoidTalons(actorChar, startPos, endPos, lookDir, scale, isAwakened, isLocal)
	elseif k == "C" then
		DragonSovereignVFX.SpawnCataclysmicStarshower(actorChar, startPos, endPos, lookDir, scale, isAwakened, isLocal)
	elseif k == "V" then
		local tier = tonumber(fx and fx.DragonFormTier)
		if not tier then
			local anchors = DragonSovereignVFX.ResolveDragonStateAndAnchors(actorChar, startPos, lookDir)
			tier = (anchors.Tier > 0) and anchors.Tier or 2
		end
		DragonSovereignVFX.SpawnTransformAscension(actorChar, startPos, tier, isAwakened, isLocal)
	elseif k == "F" then
		DragonSovereignVFX.SpawnSoaringRush(actorChar, startPos, endPos, lookDir, scale, isAwakened, isLocal)
	else
		DragonSovereignVFX.SpawnSovereignBreath(actorChar, startPos, endPos, lookDir, scale, isAwakened, isLocal)
	end
end

return DragonSovereignVFX
