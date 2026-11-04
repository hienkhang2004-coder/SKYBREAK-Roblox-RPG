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

local MAX_LIGHT_BRIGHTNESS = 4.25
local MAX_LIGHT_RANGE = 28
local MAX_PARTICLE_EMISSION = 1.0

local TEX_FIRE_PLASMA = "rbxasset://textures/particles/fire_main.dds"
local TEX_SMOKE_CLOUD = "rbxasset://textures/particles/smoke_main.dds"
local TEX_SHOCK_RING = "rbxasset://textures/particles/forcefield_glow_main.dds"
local TEX_IMPLOSION = "rbxasset://textures/particles/explosion01_implosion_main.dds"
local TEX_SPARK_FLARE = "rbxasset://textures/particles/sparkles_main.dds"

local PALETTE = {
	Crimson = Color3.fromRGB(255, 46, 150),
	BloodFlame = Color3.fromRGB(255, 36, 68),
	SolarGold = Color3.fromRGB(255, 196, 56),
	Violet = Color3.fromRGB(168, 38, 255),
	Magma = Color3.fromRGB(255, 116, 42),
	Obsidian = Color3.fromRGB(20, 12, 36),
	SlateArmor = Color3.fromRGB(48, 38, 76),
	HotCore = Color3.fromRGB(255, 232, 248),
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
	local nm = name or "DragonVFXPart"
	local sh = shape or Enum.PartType.Block
	local sz = size or Vector3.new(1, 1, 1)
	local col = color or PALETTE.Crimson
	local isEnergyMat = (material == nil) or (material == Enum.Material.ForceField) or (material == Enum.Material.Neon)

	p.Name = nm
	p.Shape = sh
	p.Size = sz
	p.CFrame = cf or CFrame.new()
	p.Color = col
	p.Material = (material == nil or material == Enum.Material.ForceField) and Enum.Material.Neon or material
	p.Transparency = math.clamp(transparency or 0.08, 0, 1)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Massless = true

	if isEnergyMat and sh == Enum.PartType.Block and p.Transparency < 0.95 then
		local maxD = math.max(sz.X, sz.Y, sz.Z)
		local minD = math.max(0.01, math.min(sz.X, sz.Y, sz.Z))
		if (maxD / minD >= 1.85) or string.find(nm, "Bolt") or string.find(nm, "Slash") or string.find(nm, "Claw") or string.find(nm, "Talon") or string.find(nm, "Spoke") or string.find(nm, "Spark") or string.find(nm, "Arc") or string.find(nm, "Ribbon") or string.find(nm, "Streak") or string.find(nm, "Ray") then
			local sm = Instance.new("SpecialMesh")
			sm.MeshType = Enum.MeshType.Sphere
			sm.Parent = p
		end
	end

	if isEnergyMat and p.Transparency < 0.85 and not isLowFX() then
		if string.find(nm, "Core") or string.find(nm, "Meteor") or string.find(nm, "Orb") or string.find(nm, "Breath") or string.find(nm, "Beam") or string.find(nm, "Pillar") or string.find(nm, "Vortex") then
			local att = Instance.new("Attachment")
			att.Name = "DragonLiveAtt"
			att.Parent = p
			local pe = Instance.new("ParticleEmitter")
			pe.Name = "DragonLivePlasma"
			pe.Texture = TEX_FIRE_PLASMA
			pe.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, PALETTE.HotCore),
				ColorSequenceKeypoint.new(0.45, col),
				ColorSequenceKeypoint.new(1, PALETTE.Obsidian),
			})
			local baseScale = math.clamp(math.max(sz.X, sz.Y, sz.Z) * 0.28, 0.4, 3.6)
			pe.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, baseScale * 0.85),
				NumberSequenceKeypoint.new(0.55, baseScale * 1.25),
				NumberSequenceKeypoint.new(1, 0),
			})
			pe.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.04),
				NumberSequenceKeypoint.new(0.65, 0.36),
				NumberSequenceKeypoint.new(1, 1),
			})
			pe.LightEmission = 1.0
			pe.LightInfluence = 0
			pcall(function() pe.Brightness = 3.8 end)
			pe.Lifetime = NumberRange.new(0.15, 0.30)
			pe.Speed = NumberRange.new(4, 14)
			pe.SpreadAngle = Vector2.new(180, 180)
			pe.RotSpeed = NumberRange.new(-240, 240)
			pe.Rotation = NumberRange.new(0, 360)
			pe.Rate = 52
			pe.Enabled = true
			pe.Parent = att
		end
	end

	p.Parent = parent or (getTempFolder())
	return p
end

local function makeSafeLight(parent, color, brightness, range, dur)
	if isLowFX() or not parent then return nil end
	local pl = Instance.new("PointLight")
	pl.Color = color or PALETTE.Crimson
	pl.Brightness = math.clamp((brightness or 1.4) * 1.85, 0, MAX_LIGHT_BRIGHTNESS)
	pl.Range = math.clamp((range or 14) * 1.45, 4, MAX_LIGHT_RANGE)
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
	tr.Texture = TEX_FIRE_PLASMA
	tr.TextureMode = Enum.TextureMode.Stretch
	tr.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color1),
		ColorSequenceKeypoint.new(0.5, color2),
		ColorSequenceKeypoint.new(1, PALETTE.Obsidian),
	})
	tr.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.02),
		NumberSequenceKeypoint.new(0.65, 0.32),
		NumberSequenceKeypoint.new(1, 1),
	})
	tr.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.6, 0.65),
		NumberSequenceKeypoint.new(1, 0),
	})
	tr.LightEmission = 1.0
	tr.LightInfluence = 0
	pcall(function() tr.Brightness = 3.8 end)
	tr.FaceCamera = true
	tr.Lifetime = lifetime or 0.28
	tr.MinLength = 0.04
	tr.Parent = hostPart

	if not isLowFX() then
		local sp = Instance.new("ParticleEmitter")
		sp.Name = "DragonTrailSparks"
		sp.Texture = TEX_SPARK_FLARE
		sp.Orientation = Enum.ParticleOrientation.VelocityParallel
		sp.Squash = NumberSequence.new({
			NumberSequenceKeypoint.new(0, -1.4),
			NumberSequenceKeypoint.new(1, -2.2),
		})
		sp.Color = tr.Color
		sp.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, math.clamp(width * 0.38, 0.24, 1.5)),
			NumberSequenceKeypoint.new(1, 0),
		})
		sp.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		sp.LightEmission = 1.0
		sp.LightInfluence = 0
		pcall(function() sp.Brightness = 4.2 end)
		sp.Lifetime = NumberRange.new(0.14, 0.26)
		sp.Speed = NumberRange.new(10, 26)
		sp.SpreadAngle = Vector2.new(180, 180)
		sp.Drag = 4.2
		sp.Rate = 44
		sp.Enabled = true
		sp.Parent = a0
	end

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

local Lib = require(script.Parent:WaitForChild("VFXStudioLibrary"))

local function spawnShockRing(pos, upCF, color, startR, endR, thickness, dur, mat, parent)
	return Lib.SpawnShockRing(pos, upCF, color or PALETTE.Crimson, startR, endR, thickness, dur, mat, parent)
end

local function spawnDraconicLightningArc(p0, p1, colMain, colCore, thickness, segments, dur, parent)
	if isLowFX() then return end
	local span = p1 - p0
	local dist = span.Magnitude
	if dist < 1.2 then return end
	local segCount = math.clamp(segments or 6, 3, 10)
	local baseCF = safeLookAt(p0, p1)
	local rightV = baseCF.RightVector
	local upV = baseCF.UpVector
	local jitterAmp = math.clamp(dist * 0.11, 0.55, 3.2)
	local th = thickness or 0.26
	local d = dur or 0.28

	local pts = { p0 }
	for i = 1, segCount - 1 do
		local frac = i / segCount
		local envelope = math.sin(frac * math.pi)
		local rOff = (math.random() - 0.5) * 2 * jitterAmp * envelope
		local uOff = (math.random() - 0.5) * 2 * jitterAmp * envelope
		pts[i + 1] = p0:Lerp(p1, frac) + rightV * rOff + upV * uOff
	end
	pts[segCount + 1] = p1

	for i = 1, segCount do
		local a = pts[i]
		local b = pts[i + 1]
		local sLen = (b - a).Magnitude
		if sLen > 0.05 then
			local mid = (a + b) * 0.5
			local sCF = safeLookAt(mid, b)
			local outer = makePart("DraconicBoltOuter_" .. i, Enum.PartType.Block, Vector3.new(th, th, sLen + th * 0.4), sCF, colMain or PALETTE.Crimson, 0.08, Enum.Material.ForceField, parent)
			local inner = makePart("DraconicBoltCore_" .. i, Enum.PartType.Block, Vector3.new(th * 0.48, th * 0.48, sLen + th * 0.2), sCF, colCore or PALETTE.HotCore, 0.02, Enum.Material.Neon, parent)
			TweenService:Create(outer, TweenInfo.new(d, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = Vector3.new(0.03, 0.03, sLen),
				Transparency = 1,
			}):Play()
			TweenService:Create(inner, TweenInfo.new(d * 0.88, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = Vector3.new(0.01, 0.01, sLen),
				Transparency = 1,
			}):Play()
			Debris:AddItem(outer, d + 0.04)
			Debris:AddItem(inner, d + 0.04)
		end
	end
end

local function spawnRunicMagicCircle(centerCF, radius, colPrimary, colSecondary, dur, parent, spinSpeed)
	local d = dur or 0.75
	local r = radius or 12
	local spd = spinSpeed or 4.2
	local sealModel = Instance.new("Model")
	sealModel.Name = "DraconicRunicCircle"
	sealModel.Parent = parent or (getTempFolder())
	Debris:AddItem(sealModel, d + 0.08)

	local outerRing = makePart("RunicOuterRing", Enum.PartType.Cylinder, Vector3.new(0.18, r * 0.2, r * 0.2), centerCF * CFrame.Angles(0, 0, math.pi * 0.5), colPrimary or PALETTE.Crimson, 0.10, Enum.Material.ForceField, sealModel)
	local innerRing = makePart("RunicInnerRing", Enum.PartType.Cylinder, Vector3.new(0.22, r * 0.14, r * 0.14), centerCF * CFrame.Angles(0, 0, math.pi * 0.5), colSecondary or PALETTE.SolarGold, 0.12, Enum.Material.ForceField, sealModel)
	TweenService:Create(outerRing, TweenInfo.new(math.min(0.24, d * 0.35), Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.18, r * 2.0, r * 2.0),
	}):Play()
	TweenService:Create(innerRing, TweenInfo.new(math.min(0.26, d * 0.38), Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.22, r * 1.32, r * 1.32),
	}):Play()

	local spokes = {}
	local glyphCount = isLowFX() and 4 or 8
	for i = 1, glyphCount do
		local ang = (i - 1) * ((math.pi * 2) / glyphCount)
		local col = (i % 2 == 0) and (colPrimary or PALETTE.Crimson) or (colSecondary or PALETTE.SolarGold)
		local spoke = makePart("RunicSpoke_" .. i, Enum.PartType.Block, Vector3.new(0.18, 0.14, r * 1.85), centerCF * CFrame.Angles(0, ang, 0), col, 0.14, Enum.Material.ForceField, sealModel)
		local fangGlyph = makePart("RunicFangGlyph_" .. i, Enum.PartType.Wedge, Vector3.new(0.32, r * 0.22, r * 0.32), centerCF * CFrame.Angles(0, ang, 0) * CFrame.new(0, 0, -r * 1.05) * CFrame.Angles(math.pi * 0.5, 0, 0), col, 0.08, Enum.Material.Neon, sealModel)
		table.insert(spokes, { Spoke = spoke, Glyph = fangGlyph, Angle = ang })
	end

	local t0 = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local el = os.clock() - t0
		if el >= d or not sealModel.Parent then
			if conn then conn:Disconnect() end
			return
		end
		local u = el / d
		local rotCF = centerCF * CFrame.Angles(0, el * spd, 0)
		local fade = (u > 0.68) and ((u - 0.68) / 0.32) or 0
		if outerRing.Parent then
			outerRing.CFrame = rotCF * CFrame.Angles(0, 0, math.pi * 0.5)
			outerRing.Transparency = 0.10 + fade * 0.90
		end
		if innerRing.Parent then
			innerRing.CFrame = (centerCF * CFrame.Angles(0, -el * spd * 1.35, 0)) * CFrame.Angles(0, 0, math.pi * 0.5)
			innerRing.Transparency = 0.12 + fade * 0.88
		end
		for _, sp in ipairs(spokes) do
			local aCF = rotCF * CFrame.Angles(0, sp.Angle, 0)
			if sp.Spoke and sp.Spoke.Parent then
				sp.Spoke.CFrame = aCF
				sp.Spoke.Transparency = 0.14 + fade * 0.86
			end
			if sp.Glyph and sp.Glyph.Parent then
				sp.Glyph.CFrame = aCF * CFrame.new(0, 0, -r * (0.95 + 0.12 * math.sin(el * 10 + sp.Angle))) * CFrame.Angles(math.pi * 0.5, 0, 0)
				sp.Glyph.Transparency = 0.08 + fade * 0.92
			end
		end
	end)
	return sealModel
end

local function spawnSpectralDragonHeadConstruct(startCF, endCF, scale, colPrimary, colSecondary, colEye, dur, parent, snapJaws)
	local s = scale or 1.35
	local d = dur or 0.36
	local headFolder = Instance.new("Folder")
	headFolder.Name = "SpectralDragonHeadConstruct"
	headFolder.Parent = parent or (getTempFolder())
	Debris:AddItem(headFolder, d + 0.12)

	local cranium = makePart("DragonHeadCranium", Enum.PartType.Block, Vector3.new(2.2, 1.35, 2.8) * s, startCF, colPrimary or PALETTE.Crimson, 0.08, Enum.Material.ForceField, headFolder)
	local snout = makePart("DragonHeadSnout", Enum.PartType.Wedge, Vector3.new(1.75, 1.05, 2.6) * s, startCF * CFrame.new(0, 0.15 * s, -2.4 * s), colPrimary or PALETTE.Crimson, 0.06, Enum.Material.ForceField, headFolder)
	local innerCore = makePart("DragonHeadInnerCore", Enum.PartType.Ball, Vector3.new(1.55, 1.15, 2.4) * s, startCF * CFrame.new(0, 0, -0.8 * s), colSecondary or PALETTE.SolarGold, 0.04, Enum.Material.Neon, headFolder)
	local lowerJaw = makePart("DragonHeadLowerJaw", Enum.PartType.Wedge, Vector3.new(1.55, 0.72, 2.8) * s, startCF * CFrame.new(0, -0.75 * s, -1.8 * s) * CFrame.Angles(math.pi + 0.38, 0, 0), colPrimary or PALETTE.Crimson, 0.08, Enum.Material.ForceField, headFolder)

	local hornL = makePart("DragonHornL", Enum.PartType.Wedge, Vector3.new(0.42, 0.85, 3.2) * s, startCF * CFrame.new(-1.05 * s, 0.95 * s, 1.1 * s) * CFrame.Angles(0.42, -0.28, -0.2), colSecondary or PALETTE.SolarGold, 0.04, Enum.Material.Neon, headFolder)
	local hornR = makePart("DragonHornR", Enum.PartType.Wedge, Vector3.new(0.42, 0.85, 3.2) * s, startCF * CFrame.new(1.05 * s, 0.95 * s, 1.1 * s) * CFrame.Angles(0.42, 0.28, 0.2), colSecondary or PALETTE.SolarGold, 0.04, Enum.Material.Neon, headFolder)
	local eyeL = makePart("DragonEyeL", Enum.PartType.Ball, Vector3.new(0.42, 0.34, 0.65) * s, startCF * CFrame.new(-0.88 * s, 0.38 * s, -1.05 * s), colEye or PALETTE.HotCore, 0.0, Enum.Material.Neon, headFolder)
	local eyeR = makePart("DragonEyeR", Enum.PartType.Ball, Vector3.new(0.42, 0.34, 0.65) * s, startCF * CFrame.new(0.88 * s, 0.38 * s, -1.05 * s), colEye or PALETTE.HotCore, 0.0, Enum.Material.Neon, headFolder)

	if not isLowFX() then
		attachRibbonTrail(hornL, colEye or PALETTE.HotCore, colPrimary or PALETTE.Crimson, 0.75 * s, 0.24)
		attachRibbonTrail(hornR, colEye or PALETTE.HotCore, colPrimary or PALETTE.Crimson, 0.75 * s, 0.24)
	end

	local fangs = {}
	for f = -1, 1 do
		local xOff = f * 0.56 * s
		local uFang = makePart("DragonUpperFang_" .. f, Enum.PartType.Wedge, Vector3.new(0.26, 0.88, 0.36) * s, startCF * CFrame.new(xOff, -0.35 * s, -2.65 * s) * CFrame.Angles(math.pi, 0, 0), colEye or PALETTE.HotCore, 0.02, Enum.Material.Neon, headFolder)
		local lFang = makePart("DragonLowerFang_" .. f, Enum.PartType.Wedge, Vector3.new(0.24, 0.78, 0.34) * s, startCF * CFrame.new(xOff, -0.95 * s, -2.45 * s), colSecondary or PALETTE.SolarGold, 0.02, Enum.Material.Neon, headFolder)
		table.insert(fangs, { Upper = uFang, Lower = lFang, X = xOff })
	end

	local t0 = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local el = os.clock() - t0
		if el >= d or not headFolder.Parent then
			if conn then conn:Disconnect() end
			return
		end
		local u = math.clamp(el / d, 0, 1)
		local curCF = startCF:Lerp(endCF, u)
		local jawAngle = snapJaws and (0.45 * (1 - math.min(1, u * 1.35))) or (0.28 + 0.14 * math.sin(el * 24))
		local fade = (u > 0.74) and ((u - 0.74) / 0.26) or 0

		if cranium.Parent then
			cranium.CFrame = curCF * CFrame.Angles(-jawAngle * 0.35, 0, 0)
			cranium.Transparency = 0.08 + fade * 0.92
		end
		if snout.Parent then
			snout.CFrame = curCF * CFrame.Angles(-jawAngle * 0.35, 0, 0) * CFrame.new(0, 0.15 * s, -2.4 * s)
			snout.Transparency = 0.06 + fade * 0.94
		end
		if innerCore.Parent then
			innerCore.CFrame = curCF * CFrame.new(0, 0, -0.8 * s)
			innerCore.Transparency = 0.04 + fade * 0.96
		end
		if lowerJaw.Parent then
			lowerJaw.CFrame = curCF * CFrame.new(0, -0.58 * s, -1.75 * s) * CFrame.Angles(math.pi + jawAngle, 0, 0)
			lowerJaw.Transparency = 0.08 + fade * 0.92
		end
		if hornL.Parent then
			hornL.CFrame = curCF * CFrame.Angles(-jawAngle * 0.35, 0, 0) * CFrame.new(-1.05 * s, 0.95 * s, 1.1 * s) * CFrame.Angles(0.42, -0.28, -0.2)
			hornL.Transparency = 0.04 + fade * 0.96
		end
		if hornR.Parent then
			hornR.CFrame = curCF * CFrame.Angles(-jawAngle * 0.35, 0, 0) * CFrame.new(1.05 * s, 0.95 * s, 1.1 * s) * CFrame.Angles(0.42, 0.28, 0.2)
			hornR.Transparency = 0.04 + fade * 0.96
		end
		if eyeL.Parent then
			eyeL.CFrame = curCF * CFrame.Angles(-jawAngle * 0.35, 0, 0) * CFrame.new(-0.88 * s, 0.38 * s, -1.05 * s)
			eyeL.Transparency = fade
		end
		if eyeR.Parent then
			eyeR.CFrame = curCF * CFrame.Angles(-jawAngle * 0.35, 0, 0) * CFrame.new(0.88 * s, 0.38 * s, -1.05 * s)
			eyeR.Transparency = fade
		end
		for _, fg in ipairs(fangs) do
			if fg.Upper and fg.Upper.Parent then
				fg.Upper.CFrame = curCF * CFrame.Angles(-jawAngle * 0.35, 0, 0) * CFrame.new(fg.X, -0.32 * s, -2.65 * s) * CFrame.Angles(math.pi, 0, 0)
				fg.Upper.Transparency = 0.02 + fade * 0.98
			end
			if fg.Lower and fg.Lower.Parent then
				fg.Lower.CFrame = curCF * CFrame.Angles(jawAngle * 0.65, 0, 0) * CFrame.new(fg.X, -0.78 * s, -2.45 * s)
				fg.Lower.Transparency = 0.02 + fade * 0.98
			end
		end
	end)
	return headFolder
end

-- ============================================================================
-- 1. VFX STUDIO PREFAB BRIDGE (EmitCount / EmitDelay / EmitDuration)
-- ============================================================================
local function makeStudioEmitter(parent, name, c1, c2, c3, sz0, sz1, lifeMin, lifeMax, spdMin, spdMax, emitCount, emitDelay, spread, drag)
	local pe = Instance.new("ParticleEmitter")
	local nm = tostring(name or "DragonStudioEmitter")
	pe.Name = nm
	pe.Enabled = false
	pe.Rate = 76
	if string.find(nm, "Mist") or string.find(nm, "Smoke") or string.find(nm, "Wisps") or string.find(nm, "Ash") then
		pe.Texture = TEX_SMOKE_CLOUD
		pe.LightEmission = 0.72
		pe.LightInfluence = 0.06
		pcall(function() pe.Brightness = 2.8 end)
		pe.ZOffset = -0.25
	elseif string.find(nm, "Sparks") or string.find(nm, "Cinders") or string.find(nm, "Embers") then
		pe.Texture = TEX_SPARK_FLARE
		pe.Orientation = Enum.ParticleOrientation.VelocityParallel
		pe.Squash = NumberSequence.new({
			NumberSequenceKeypoint.new(0, -1.3),
			NumberSequenceKeypoint.new(0.65, -2.1),
			NumberSequenceKeypoint.new(1, -0.6),
		})
		pe.LightEmission = 1.0
		pe.LightInfluence = 0
		pcall(function() pe.Brightness = 4.4 end)
		pe.ZOffset = 0.4
	else
		pe.Texture = TEX_FIRE_PLASMA
		pe.LightEmission = 1.0
		pe.LightInfluence = 0
		pcall(function() pe.Brightness = 4.0 end)
		pe.ZOffset = 0.2
	end
	pe.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, c1),
		ColorSequenceKeypoint.new(0.48, c2),
		ColorSequenceKeypoint.new(1, c3 or PALETTE.Obsidian),
	})
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, sz0 * 1.18),
		NumberSequenceKeypoint.new(0.55, (sz0 + sz1) * 0.68),
		NumberSequenceKeypoint.new(1, sz1),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.02),
		NumberSequenceKeypoint.new(0.68, 0.32),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.Lifetime = NumberRange.new(lifeMin, lifeMax)
	pe.Speed = NumberRange.new(spdMin * 1.18, spdMax * 1.28)
	pe.SpreadAngle = Vector2.new(spread or 180, spread or 180)
	pe.Drag = drag or 3.4
	pe.RotSpeed = NumberRange.new(-240, 240)
	pe.Rotation = NumberRange.new(0, 360)
	pe:SetAttribute("EmitCount", math.floor((emitCount or 18) * 1.7 + 0.5))
	pe:SetAttribute("EmitDelay", emitDelay or 0)
	pe:SetAttribute("EmitDuration", 0.16)
	pe.Parent = parent
	return pe
end

local function attachDragonSignatureStudioLayers(att)
	local coreFlash = Instance.new("ParticleEmitter")
	coreFlash.Name = "DragonStudioCoreFlash"
	coreFlash.Texture = TEX_SHOCK_RING
	coreFlash.Orientation = Enum.ParticleOrientation.FacingCamera
	coreFlash.Enabled = false
	coreFlash.Rate = 0
	coreFlash.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, PALETTE.HotCore),
		ColorSequenceKeypoint.new(0.5, PALETTE.Crimson),
		ColorSequenceKeypoint.new(1, PALETTE.Violet),
	})
	coreFlash.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.0),
		NumberSequenceKeypoint.new(0.35, 5.4),
		NumberSequenceKeypoint.new(1, 0.2),
	})
	coreFlash.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.55, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	coreFlash.LightEmission = 1.0
	coreFlash.LightInfluence = 0
	pcall(function() coreFlash.Brightness = 5.0 end)
	coreFlash.ZOffset = 0.85
	coreFlash.Lifetime = NumberRange.new(0.16, 0.24)
	coreFlash.Speed = NumberRange.new(0.1, 0.5)
	coreFlash.SpreadAngle = Vector2.new(180, 180)
	coreFlash:SetAttribute("EmitCount", 5)
	coreFlash:SetAttribute("EmitDelay", 0)
	coreFlash:SetAttribute("EmitDuration", 0)
	coreFlash.Parent = att

	local planarRing = Instance.new("ParticleEmitter")
	planarRing.Name = "DragonStudioPlanarRing"
	planarRing.Texture = TEX_SHOCK_RING
	planarRing.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
	planarRing.Enabled = false
	planarRing.Rate = 0
	planarRing.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, PALETTE.HotCore),
		ColorSequenceKeypoint.new(0.45, PALETTE.Crimson),
		ColorSequenceKeypoint.new(1, PALETTE.Violet),
	})
	planarRing.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.4),
		NumberSequenceKeypoint.new(0.65, 9.2),
		NumberSequenceKeypoint.new(1, 12.4),
	})
	planarRing.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.04),
		NumberSequenceKeypoint.new(0.65, 0.35),
		NumberSequenceKeypoint.new(1, 1),
	})
	planarRing.LightEmission = 1.0
	planarRing.LightInfluence = 0
	pcall(function() planarRing.Brightness = 4.2 end)
	planarRing.ZOffset = 0.45
	planarRing.Lifetime = NumberRange.new(0.24, 0.36)
	planarRing.Speed = NumberRange.new(0.08, 0.25)
	planarRing.SpreadAngle = Vector2.new(25, 25)
	planarRing:SetAttribute("EmitCount", 4)
	planarRing:SetAttribute("EmitDelay", 0)
	planarRing:SetAttribute("EmitDuration", 0)
	planarRing.Parent = att

	local velSparks = Instance.new("ParticleEmitter")
	velSparks.Name = "DragonStudioVelocitySparks"
	velSparks.Texture = TEX_SPARK_FLARE
	velSparks.Orientation = Enum.ParticleOrientation.VelocityParallel
	velSparks.Squash = NumberSequence.new({
		NumberSequenceKeypoint.new(0, -1.6),
		NumberSequenceKeypoint.new(0.6, -2.4),
		NumberSequenceKeypoint.new(1, -0.7),
	})
	velSparks.Enabled = false
	velSparks.Rate = 0
	velSparks.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, PALETTE.HotCore),
		ColorSequenceKeypoint.new(0.45, PALETTE.Crimson),
		ColorSequenceKeypoint.new(1, PALETTE.SolarGold),
	})
	velSparks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.74),
		NumberSequenceKeypoint.new(0.65, 0.45),
		NumberSequenceKeypoint.new(1, 0),
	})
	velSparks.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.75, 0.22),
		NumberSequenceKeypoint.new(1, 1),
	})
	velSparks.LightEmission = 1.0
	velSparks.LightInfluence = 0
	pcall(function() velSparks.Brightness = 4.8 end)
	velSparks.ZOffset = 0.55
	velSparks.Lifetime = NumberRange.new(0.18, 0.34)
	velSparks.Speed = NumberRange.new(32, 76)
	velSparks.SpreadAngle = Vector2.new(180, 180)
	velSparks.Drag = 4.6
	velSparks:SetAttribute("EmitCount", 32)
	velSparks:SetAttribute("EmitDelay", 0)
	velSparks:SetAttribute("EmitDuration", 0)
	velSparks.Parent = att
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
			attachDragonSignatureStudioLayers(att)
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

	if not low then
		for bIdx = 1, 2 do
			local sign = (bIdx == 1) and 1 or -1
			local a0 = Instance.new("Attachment")
			a0.Position = Vector3.new(-3.6 * mult * sign, -0.8 * mult, 0)
			a0.Parent = hostPart
			local a1 = Instance.new("Attachment")
			a1.Position = Vector3.new(3.6 * mult * sign, 1.6 * mult, 0)
			a1.Parent = hostPart
			local bm = Instance.new("Beam")
			bm.Name = "DragonStudioCurvedBeam_" .. bIdx
			bm.Attachment0 = a0
			bm.Attachment1 = a1
			bm.Texture = TEX_FIRE_PLASMA
			bm.TextureMode = Enum.TextureMode.Wrap
			bm.TextureSpeed = 4.6 * sign
			bm.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, PALETTE.HotCore),
				ColorSequenceKeypoint.new(0.5, (bIdx == 1) and PALETTE.Crimson or PALETTE.Violet),
				ColorSequenceKeypoint.new(1, PALETTE.Obsidian),
			})
			bm.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.2, 0.04),
				NumberSequenceKeypoint.new(0.8, 0.14),
				NumberSequenceKeypoint.new(1, 1),
			})
			bm.LightEmission = 1.0
			bm.LightInfluence = 0
			pcall(function() bm.Brightness = 4.2 end)
			bm.FaceCamera = true
			bm.Segments = 18
			bm.CurveSize0 = 4.8 * mult * sign
			bm.CurveSize1 = -4.8 * mult * sign
			bm.Width0 = 1.65 * mult
			bm.Width1 = 0.30 * mult
			bm.Parent = hostPart
			TweenService:Create(a0, TweenInfo.new(0.36, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Position = Vector3.new(-7.2 * mult * sign, 1.4 * mult, 2.5 * mult * sign),
			}):Play()
			TweenService:Create(a1, TweenInfo.new(0.36, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Position = Vector3.new(7.2 * mult * sign, 3.6 * mult, -2.5 * mult * sign),
			}):Play()
			TweenService:Create(bm, TweenInfo.new(0.36, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Width0 = 0,
				Width1 = 0,
			}):Play()
		end
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

			if emitDelay <= 0 then
				if emitCount > 0 then
					desc:Emit(emitCount)
				end
				if emitDur > 0 and not low then
					desc.Enabled = true
					task.delay(emitDur, function()
						if desc and desc.Parent then
							desc.Enabled = false
						end
					end)
				end
			else
				task.delay(emitDelay, function()
					if not desc or not desc.Parent then return end
					if emitCount > 0 then
						desc:Emit(emitCount)
					end
					if emitDur > 0 and not low then
						desc.Enabled = true
						task.delay(emitDur, function()
							if desc and desc.Parent then
								desc.Enabled = false
							end
						end)
					end
				end)
			end
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
	local scale = (isSovereign and 1.48 or 1.12) * (isAwakened and 1.22 or 1.0)
	local anchors = DragonSovereignVFX.ResolveDragonStateAndAnchors(actorChar, pos, nil)
	local gPos = anchors.GroundPos
	local cPos = anchors.CenterPos
	local folder = Instance.new("Folder")
	folder.Name = isSovereign and "SovereignDragon_AscensionVFX" or "HybridDragon_AscensionVFX"
	folder.Parent = (getTempFolder())
	Debris:AddItem(folder, 1.55)

	local primaryCol = isSovereign and PALETTE.Crimson or PALETTE.BloodFlame
	local secondaryCol = isSovereign and PALETTE.AwakenedGold or PALETTE.SolarGold
	local accentCol = isSovereign and PALETTE.Violet or PALETTE.Magma

	DragonSovereignVFX.EmitPrefab("Dragon_V_Ascension", CFrame.new(cPos + Vector3.new(0, 2.2 * scale, 0)), scale)

	-- Multi-Ring Rotating Draconic Runic Magic Circle on the ground
	spawnRunicMagicCircle(CFrame.new(gPos + Vector3.new(0, 0.18, 0)), (isSovereign and 18 or 13) * scale, primaryCol, secondaryCol, 1.15, folder, isSovereign and 5.2 or 4.4)
	if isSovereign then
		spawnRunicMagicCircle(CFrame.new(gPos + Vector3.new(0, 0.28, 0)), 11.5 * scale, accentCol, PALETTE.HotCore, 1.05, folder, -6.4)
	end

	-- Stage 1 (0.00s): Abyssal Gravity Implosion Sphere + 3 Counter-Rotating Draconic Ground Seals + Monolith Fangs
	local implosion = makePart("AbyssalImplosionSphere", Enum.PartType.Ball, Vector3.new(15, 15, 15) * scale, CFrame.new(cPos + Vector3.new(0, 2.5 * scale, 0)), PALETTE.Obsidian, 0.18, Enum.Material.ForceField, folder)
	local implosionRim = makePart("AbyssalImplosionRim", Enum.PartType.Ball, Vector3.new(17.5, 17.5, 17.5) * scale, implosion.CFrame, primaryCol, 0.35, Enum.Material.ForceField, folder)
	makeSafeLight(implosion, primaryCol, 1.38, 16, 0.95)
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
		local col = (rIdx == 1 and secondaryCol) or (rIdx == 2 and primaryCol or accentCol)
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

	local fangCount = isLowFX() and 6 or (isSovereign and 12 or 9)
	for i = 1, fangCount do
		local ang = (i - 1) * ((math.pi * 2) / fangCount)
		local distR = (isSovereign and 9.8 or 7.2) * scale
		local fPos = gPos + Vector3.new(math.cos(ang) * distR, -1.2, math.sin(ang) * distR)
		local h = (isSovereign and 10.2 or 7.0) * scale
		local fang = makePart(
			"AscensionObsidianFang_" .. i,
			Enum.PartType.Wedge,
			Vector3.new(1.55 * scale, h, 2.15 * scale),
			CFrame.lookAt(fPos, gPos + Vector3.new(0, h * 0.85, 0)) * CFrame.Angles(-0.28, 0, 0),
			(i % 3 == 0) and secondaryCol or ((i % 2 == 0) and PALETTE.SlateArmor or primaryCol),
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

	-- Stage 2 (0.14s): Towering Sovereign Ascension Pillar + 3 Coiling Spectral Dragon Spirits + Conqueror Lightning Dome
	task.delay(0.14, function()
		if not folder.Parent then return end
		local pillarH = (isSovereign and 48 or 32) * scale
		local pillarR = (isSovereign and 9.2 or 6.4) * scale
		local pCenter = gPos + Vector3.new(0, pillarH * 0.5, 0)

		local corePillar = makePart("SovereignPillarCore", Enum.PartType.Cylinder, Vector3.new(pillarH, 1.2, 1.2), CFrame.new(pCenter) * CFrame.Angles(0, 0, math.pi * 0.5), secondaryCol, 0.04, Enum.Material.Neon, folder)
		local plasmaPillar = makePart("SovereignPillarPlasma", Enum.PartType.Cylinder, Vector3.new(pillarH, 2.2, 2.2), corePillar.CFrame, primaryCol, 0.14, Enum.Material.ForceField, folder)
		local voidSheath = makePart("SovereignPillarVoid", Enum.PartType.Cylinder, Vector3.new(pillarH, 3.0, 3.0), corePillar.CFrame, accentCol, 0.26, Enum.Material.ForceField, folder)

		TweenService:Create(corePillar, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = Vector3.new(pillarH, pillarR * 0.52, pillarR * 0.52) }):Play()
		TweenService:Create(plasmaPillar, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = Vector3.new(pillarH, pillarR, pillarR) }):Play()
		TweenService:Create(voidSheath, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = Vector3.new(pillarH, pillarR * 1.32, pillarR * 1.32) }):Play()

		local domeR = (isSovereign and 48 or 32) * (isAwakened and 1.18 or 1.0)
		local dome = makePart("SovereignConquerorDome", Enum.PartType.Ball, Vector3.new(4, 4, 4), CFrame.new(cPos + Vector3.new(0, 2.4, 0)), primaryCol, 0.16, Enum.Material.ForceField, folder)
		local innerVoidDome = makePart("SovereignVoidDome", Enum.PartType.Ball, Vector3.new(3, 3, 3), dome.CFrame, PALETTE.Obsidian, 0.14, Enum.Material.ForceField, folder)
		TweenService:Create(dome, TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = Vector3.new(domeR, domeR, domeR), Transparency = 1 }):Play()
		TweenService:Create(innerVoidDome, TweenInfo.new(0.46, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = Vector3.new(domeR * 0.82, domeR * 0.82, domeR * 0.82), Transparency = 1 }):Play()

		spawnShockRing(gPos + Vector3.new(0, 0.25, 0), nil, primaryCol, 4, domeR * 1.15, 0.38, 0.58, Enum.Material.ForceField, folder)
		spawnShockRing(gPos + Vector3.new(0, 0.55, 0), nil, accentCol, 3, domeR * 0.88, 0.28, 0.48, Enum.Material.ForceField, folder)
		spawnShockRing(gPos + Vector3.new(0, 0.85, 0), nil, secondaryCol, 3, domeR * 1.02, 0.24, 0.52, Enum.Material.ForceField, folder)

		-- Radial Conqueror / Draconic Lightning Bolts erupting outward
		local boltCount = isLowFX() and 0 or (isSovereign and 12 or 8)
		for b = 1, boltCount do
			local bAng = (b - 1) * ((math.pi * 2) / boltCount)
			local bStart = gPos + Vector3.new(math.cos(bAng) * 2.2 * scale, (1.5 + (b % 3) * 3.5) * scale, math.sin(bAng) * 2.2 * scale)
			local bEnd = gPos + Vector3.new(math.cos(bAng) * (15 + (b % 2) * 5) * scale, (0.4 + (b % 2) * 4.5) * scale, math.sin(bAng) * (15 + (b % 2) * 5) * scale)
			spawnDraconicLightningArc(bStart, bEnd, (b % 2 == 0) and primaryCol or accentCol, secondaryCol, 0.34 * scale, 6, 0.38, folder)
		end

		-- Rising 3D Spectral Dragon Head Construct ascending up the pillar!
		spawnSpectralDragonHeadConstruct(
			CFrame.lookAt(gPos + Vector3.new(0, 2.5 * scale, 0), gPos + Vector3.new(0, pillarH, 0)),
			CFrame.lookAt(gPos + Vector3.new(0, pillarH * 0.72, 0), gPos + Vector3.new(0, pillarH * 1.2, 0)),
			(isSovereign and 2.1 or 1.45) * scale,
			primaryCol,
			secondaryCol,
			PALETTE.HotCore,
			0.62,
			folder,
			false
		)

		-- 3 Live Coiling Spectral Dragon Helices spiraling up the Ascension Pillar
		if not isLowFX() then
			local helices = {}
			for h = 1, 3 do
				local col = (h == 1 and primaryCol) or (h == 2 and secondaryCol) or accentCol
				local node = makePart("CoilingDragonSpirit_" .. h, Enum.PartType.Ball, Vector3.new(1.4, 1.4, 2.4) * scale, CFrame.new(gPos), col, 0.06, Enum.Material.ForceField, folder)
				attachRibbonTrail(node, PALETTE.HotCore, col, 1.95 * scale, 0.36)
				table.insert(helices, { Node = node, Phase = (h - 1) * ((math.pi * 2) / 3) })
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
						local ang = el * 16 + h.Phase
						local rad = (pillarR * 0.78) * (1 - u * 0.25)
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
					voidSheath.Transparency = 0.26 + f * 0.74
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
			emitCameraTrauma(isSovereign and 0.58 or 0.42, isSovereign and 6.5 or 4.0)
		end
	end)

	-- Stage 3 (0.38s): Wing-Unfurl Sonic Booms & Sovereign Roar Maw Cone locked to live 3D Dragon bones!
	task.delay(0.38, function()
		if not folder.Parent then return end
		local liveAnchors = DragonSovereignVFX.ResolveDragonStateAndAnchors(actorChar, cPos, nil)
		spawnShockRing(liveAnchors.WingL_CF.Position, liveAnchors.WingL_CF, accentCol, 1.8, 13.5 * scale, 0.24, 0.38, Enum.Material.ForceField, folder)
		spawnShockRing(liveAnchors.WingR_CF.Position, liveAnchors.WingR_CF, accentCol, 1.8, 13.5 * scale, 0.24, 0.38, Enum.Material.ForceField, folder)
		spawnShockRing(liveAnchors.MawCF.Position, liveAnchors.MawCF * CFrame.Angles(math.pi * 0.5, 0, 0), secondaryCol, 1.6, 16.0 * scale, 0.28, 0.42, Enum.Material.ForceField, folder)
	end)
end

-- ============================================================================
-- 4. [M1] DRACONIC QUAD-TALON REND & ABYSSAL FANG SNAP-BITE FINISHER
--    Distinct Form 1 (Crimson-Magma Martial Claws + Fire Dragon Bite) vs
--    Form 2 (Colossal Sovereign Gold-Violet Spatial Rends + Abyssal Skull Crunch)
-- ============================================================================
function DragonSovereignVFX.SpawnDragonM1(actorChar, startPos, lookDir, combo, isHeavy, isAwakened, isLocal)
	local anchors = DragonSovereignVFX.ResolveDragonStateAndAnchors(actorChar, startPos, lookDir)
	local tier = math.max(1, anchors.Tier)
	local isSovereign = (tier >= 2)
	local scale = (isSovereign and 1.46 or 1.08) * (isAwakened and 1.2 or 1.0)
	local idx = tonumber(combo) or 1
	local folder = Instance.new("Folder")
	folder.Name = "Dragon_M1_VFX"
	folder.Parent = (getTempFolder())
	Debris:AddItem(folder, 0.75)

	local primaryCol = isSovereign and PALETTE.Crimson or PALETTE.BloodFlame
	local secondaryCol = isSovereign and PALETTE.AwakenedGold or PALETTE.SolarGold
	local accentCol = isSovereign and PALETTE.Violet or PALETTE.Magma

	local isBiteFinisher = isHeavy or (idx % 4 == 0)
	local side = (idx % 2 == 0) and 1 or -1
	local originCF = isBiteFinisher and anchors.MawCF or ((side > 0) and anchors.ClawR_CF or anchors.ClawL_CF)
	local strikeCenter = originCF.Position + anchors.LookDir * (4.2 * scale)

	DragonSovereignVFX.EmitPrefab("Dragon_M1_TalonRend", CFrame.lookAt(strikeCenter, strikeCenter + anchors.LookDir), scale)

	if not isBiteFinisher then
		-- 4 Parallel Curved Dragon Talon Crescent Slashes + 3D Claw Blades + Draconic Lightning Arcs
		local slashTilt = side * 0.52 + ((idx == 3) and -side * 0.25 or 0)
		local sweepCF = CFrame.lookAt(originCF.Position + anchors.LookDir * (1.8 * scale), originCF.Position + anchors.LookDir * (14 * scale))
			* CFrame.Angles(0, 0, slashTilt)

		for claw = 1, 4 do
			local lane = (claw - 2.5) * 0.78 * scale
			local col = (claw == 2 or claw == 3) and primaryCol or ((claw == 1) and secondaryCol or accentCol)
			local arc = makePart(
				"DragonTalonArc_" .. claw,
				Enum.PartType.Cylinder,
				Vector3.new(0.26 * scale, (6.0 + claw * 0.4) * scale, (6.0 + claw * 0.4) * scale),
				sweepCF * CFrame.new(0, lane, 0) * CFrame.Angles(0, 0, math.pi * 0.5),
				col,
				0.06,
				Enum.Material.ForceField,
				folder
			)
			local clawWedge = makePart(
				"DragonTalonBlade_" .. claw,
				Enum.PartType.Wedge,
				Vector3.new(0.28 * scale, 0.52 * scale, 5.8 * scale),
				sweepCF * CFrame.new(0, lane, -1.6 * scale) * CFrame.Angles(0, side * 0.18, 0),
				(claw == 2) and secondaryCol or col,
				0.04,
				Enum.Material.Neon,
				folder
			)
			local darkCore = makePart(
				"DragonTalonVoidCore_" .. claw,
				Enum.PartType.Block,
				Vector3.new(7.4 * scale, 0.18 * scale, 0.38 * scale),
				sweepCF * CFrame.new(0, lane, -1.2 * scale) * CFrame.Angles(0, side * 0.22, 0),
				(claw == 2) and PALETTE.HotCore or PALETTE.Obsidian,
				0.04,
				Enum.Material.SmoothPlastic,
				folder
			)
			if claw == 2 then
				makeSafeLight(arc, primaryCol, 1.25, 14, 0.26)
			end
			TweenService:Create(arc, TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				CFrame = arc.CFrame * CFrame.new(0, 0, -5.2 * scale),
				Size = Vector3.new(0.06, 11.2 * scale, 11.2 * scale),
				Transparency = 1,
			}):Play()
			TweenService:Create(clawWedge, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				CFrame = clawWedge.CFrame * CFrame.new(0, 0, -5.8 * scale),
				Size = Vector3.new(0.08, 0.16, 9.2 * scale),
				Transparency = 1,
			}):Play()
			TweenService:Create(darkCore, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				CFrame = darkCore.CFrame * CFrame.new(0, 0, -5.4 * scale),
				Size = Vector3.new(12.4 * scale, 0.06, 0.12),
				Transparency = 1,
			}):Play()
		end

		-- Crackling Draconic Lightning across the claw slash
		local boltTotal = isSovereign and 4 or 3
		for b = 1, boltTotal do
			local bOff = (b - 2) * 1.4 * scale
			local pA = (sweepCF * CFrame.new(-3.8 * scale, bOff, -1.5 * scale)).Position
			local pB = (sweepCF * CFrame.new(3.8 * scale, -bOff, -5.2 * scale)).Position
			spawnDraconicLightningArc(pA, pB, (b % 2 == 0) and primaryCol or accentCol, secondaryCol, 0.24 * scale, 5, 0.24, folder)
		end
		spawnShockRing(strikeCenter, sweepCF, secondaryCol, 1.6 * scale, 8.5 * scale, 0.18 * scale, 0.24, Enum.Material.ForceField, folder)

		if isLocal then
			emitCameraTrauma(isSovereign and 0.22 or 0.18, isSovereign and 1.6 or 1.2, anchors.LookDir)
		end
	else
		-- Combo 4 / Heavy: 3D Spectral Dragon Head Construct lunging & snapping its jaws shut!
		local biteStartCF = CFrame.lookAt(anchors.MawCF.Position + anchors.LookDir * (1.2 * scale), anchors.MawCF.Position + anchors.LookDir * (16 * scale))
		local biteEndCF = biteStartCF * CFrame.new(0, 0, -4.8 * scale)
		makeSafeLight(makePart("BiteFlashAnchor", Enum.PartType.Ball, Vector3.new(1.6, 1.6, 1.6) * scale, biteStartCF, PALETTE.HotCore, 0.1, Enum.Material.ForceField, folder), primaryCol, 1.38, 15, 0.36)

		spawnSpectralDragonHeadConstruct(
			biteStartCF,
			biteEndCF,
			(isSovereign and 1.65 or 1.25) * scale,
			primaryCol,
			secondaryCol,
			PALETTE.HotCore,
			0.32,
			folder,
			true
		)

		for fangIdx = -2, 2 do
			local xOff = fangIdx * 1.15 * scale
			local fangLen = (3.8 - math.abs(fangIdx) * 0.42) * scale
			local upFang = makePart(
				"UpperAbyssFang_" .. fangIdx,
				Enum.PartType.Wedge,
				Vector3.new(0.62 * scale, fangLen, 0.88 * scale),
				biteStartCF * CFrame.new(xOff, 3.0 * scale, -1.2 * scale) * CFrame.Angles(math.pi, 0, 0),
				(fangIdx == 0) and secondaryCol or primaryCol,
				0.04,
				Enum.Material.ForceField,
				folder
			)
			local lowFang = makePart(
				"LowerAbyssFang_" .. fangIdx,
				Enum.PartType.Wedge,
				Vector3.new(0.58 * scale, fangLen * 0.9, 0.82 * scale),
				biteStartCF * CFrame.new(xOff, -2.8 * scale, -1.2 * scale),
				(math.abs(fangIdx) == 1) and accentCol or primaryCol,
				0.04,
				Enum.Material.ForceField,
				folder
			)
			TweenService:Create(upFang, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				CFrame = biteStartCF * CFrame.new(xOff * 0.85, 0.35 * scale, -4.2 * scale) * CFrame.Angles(math.pi - 0.25, 0, 0),
			}):Play()
			TweenService:Create(lowFang, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
				CFrame = biteStartCF * CFrame.new(xOff * 0.85, -0.35 * scale, -4.2 * scale) * CFrame.Angles(0.25, 0, 0),
			}):Play()
			task.delay(0.18, function()
				if upFang.Parent then TweenService:Create(upFang, TweenInfo.new(0.18), { Transparency = 1 }):Play() end
				if lowFang.Parent then TweenService:Create(lowFang, TweenInfo.new(0.18), { Transparency = 1 }):Play() end
			end)
		end

		task.delay(0.15, function()
			if not folder.Parent then return end
			local crunchPos = biteEndCF.Position
			local gCrunch = findGroundPos(crunchPos, actorChar)
			spawnShockRing(crunchPos, biteStartCF * CFrame.Angles(math.pi * 0.5, 0, 0), primaryCol, 1.8, 14.5 * scale, 0.30, 0.34, Enum.Material.ForceField, folder)
			spawnShockRing(crunchPos, biteStartCF * CFrame.Angles(math.pi * 0.5, 0, 0), secondaryCol, 1.2, 10.2 * scale, 0.20, 0.26, Enum.Material.ForceField, folder)
			spawnShockRing(gCrunch + Vector3.new(0, 0.16, 0), nil, accentCol, 2.0, 13.0 * scale, 0.24, 0.36, Enum.Material.ForceField, folder)

			local boltNum = isLowFX() and 0 or (isSovereign and 7 or 5)
			for b = 1, boltNum do
				local ang = (b - 1) * ((math.pi * 2) / boltNum)
				local pEnd = crunchPos + Vector3.new(math.cos(ang) * 7.5 * scale, math.sin(ang * 2) * 2.5 * scale, math.sin(ang) * 7.5 * scale)
				spawnDraconicLightningArc(crunchPos, pEnd, (b % 2 == 0) and primaryCol or accentCol, secondaryCol, 0.28 * scale, 5, 0.28, folder)
			end
			if isLocal then
				emitCameraTrauma(isSovereign and 0.38 or 0.32, isSovereign and 3.0 or 2.4, anchors.LookDir)
			end
		end)
	end
end

-- ============================================================================
-- 5. [Z] SOVEREIGN ABYSSAL BREATH (QUAD-CORE HELICAL BOLO HYPER-BEAM)
-- Locked directly to Bone `FX_BreathCore` (`Jaw`) on the 3D Blender Dragon!
-- ============================================================================
function DragonSovereignVFX.SpawnSovereignBreath(actorChar, startPos, endPos, lookDir, baseScale, isAwakened, isLocal)
	local anchors = DragonSovereignVFX.ResolveDragonStateAndAnchors(actorChar, startPos, lookDir)
	local tierMult = (anchors.Tier >= 2 and 1.38) or (anchors.Tier == 1 and 1.15 or 1.0)
	local scale = (baseScale or 1.0) * tierMult
	local mawOrigin = anchors.MawCF.Position

	local rawVec = endPos - mawOrigin
	local beamLen = math.clamp(rawVec.Magnitude, 28 * scale, 54 * scale)
	local beamDir = (rawVec.Magnitude > 3) and rawVec.Unit or anchors.LookDir
	local impactPos = mawOrigin + beamDir * beamLen
	local beamAimCF = CFrame.lookAt(mawOrigin, impactPos)

	local folder = Instance.new("Folder")
	folder.Name = "Dragon_Z_SovereignBreath"
	folder.Parent = (getTempFolder())
	local totalDur = 0.92
	Debris:AddItem(folder, totalDur + 0.38)

	DragonSovereignVFX.EmitPrefab("Dragon_Z_SovereignBreath", beamAimCF, scale)

	-- Rotating Sovereign Runic Muzzle Magic Circle in front of FX_BreathCore
	spawnRunicMagicCircle(beamAimCF * CFrame.new(0, 0, -1.5 * scale) * CFrame.Angles(math.pi * 0.5, 0, 0), 5.8 * scale, PALETTE.Crimson, PALETTE.AwakenedGold, totalDur, folder, 7.5)

	-- Colossal 3D Spectral Dragon Skull Construct rocketing down the Bolo Breath beam!
	spawnSpectralDragonHeadConstruct(
		beamAimCF * CFrame.new(0, 0, -2.0 * scale),
		CFrame.lookAt(impactPos, impactPos + beamDir),
		1.95 * scale,
		PALETTE.Crimson,
		PALETTE.AwakenedGold,
		PALETTE.HotCore,
		0.42,
		folder,
		true
	)

	-- Stage 1 (0.00s - 0.10s): Maw Vacuum Compression Orb & Triple Runic Muzzle Halos at FX_BreathCore
	local mawOrb = makePart("MawCompressionCore", Enum.PartType.Ball, Vector3.new(1.6, 1.6, 1.6) * scale, beamAimCF, PALETTE.HotCore, 0.02, Enum.Material.Neon, folder)
	local mawShell = makePart("MawCompressionShell", Enum.PartType.Ball, Vector3.new(3.0, 3.0, 3.0) * scale, beamAimCF, PALETTE.Crimson, 0.16, Enum.Material.ForceField, folder)
	local muzzleRing1 = makePart("MawRunicHalo1", Enum.PartType.Cylinder, Vector3.new(0.26 * scale, 6.2 * scale, 6.2 * scale), beamAimCF * CFrame.Angles(0, math.pi * 0.5, 0), PALETTE.Crimson, 0.10, Enum.Material.ForceField, folder)
	local muzzleRing2 = makePart("MawRunicHalo2", Enum.PartType.Cylinder, Vector3.new(0.20 * scale, 8.8 * scale, 8.8 * scale), beamAimCF * CFrame.Angles(0, math.pi * 0.5, 0), PALETTE.Violet, 0.16, Enum.Material.ForceField, folder)
	local muzzleRing3 = makePart("MawRunicHalo3", Enum.PartType.Cylinder, Vector3.new(0.16 * scale, 10.8 * scale, 10.8 * scale), beamAimCF * CFrame.Angles(0, math.pi * 0.5, 0), PALETTE.AwakenedGold, 0.18, Enum.Material.ForceField, folder)
	makeSafeLight(mawOrb, PALETTE.Crimson, 1.42, 16, totalDur)

	TweenService:Create(mawOrb, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = Vector3.new(3.6, 3.6, 3.6) * scale }):Play()
	TweenService:Create(mawShell, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = Vector3.new(5.4, 5.4, 5.4) * scale }):Play()

	-- Stage 2: Quad-Core Coaxial Bolo Hyper-Beam + 3 Helical Dragon Spirits + 10 Mach Rings + Conqueror Lightning
	local midCF = CFrame.lookAt((mawOrigin + impactPos) * 0.5, impactPos) * CFrame.Angles(0, math.pi * 0.5, 0)
	local rInner = 1.85 * scale
	local rGold = 2.85 * scale
	local rPlasma = 4.2 * scale
	local rVoid = 6.0 * scale

	local innerBeam = makePart("BoloHotCore", Enum.PartType.Cylinder, Vector3.new(beamLen, 0.4, 0.4), midCF, PALETTE.HotCore, 0.02, Enum.Material.Neon, folder)
	local goldBeam = makePart("BoloGoldCore", Enum.PartType.Cylinder, Vector3.new(beamLen, 0.65, 0.65), midCF, PALETTE.AwakenedGold, 0.08, Enum.Material.ForceField, folder)
	local plasmaBeam = makePart("BoloCrimsonPlasma", Enum.PartType.Cylinder, Vector3.new(beamLen, 0.9, 0.9), midCF, PALETTE.Crimson, 0.14, Enum.Material.ForceField, folder)
	local voidMantle = makePart("BoloObsidianMantle", Enum.PartType.Cylinder, Vector3.new(beamLen, 1.4, 1.4), midCF, PALETTE.Obsidian, 0.26, Enum.Material.ForceField, folder)

	TweenService:Create(innerBeam, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = Vector3.new(beamLen, rInner, rInner) }):Play()
	TweenService:Create(goldBeam, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = Vector3.new(beamLen, rGold, rGold) }):Play()
	TweenService:Create(plasmaBeam, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = Vector3.new(beamLen, rPlasma, rPlasma) }):Play()
	TweenService:Create(voidMantle, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = Vector3.new(beamLen, rVoid, rVoid) }):Play()

	local machCount = isLowFX() and 5 or 10
	local machRings = {}
	for i = 1, machCount do
		local col = (i % 3 == 0 and PALETTE.AwakenedGold) or ((i % 2 == 0) and PALETTE.Crimson or PALETTE.Violet)
		local mr = makePart("BoloMachRing_" .. i, Enum.PartType.Cylinder, Vector3.new(0.28 * scale, rPlasma * 1.2, rPlasma * 1.2), beamAimCF * CFrame.new(0, 0, -(i / machCount) * beamLen) * CFrame.Angles(0, math.pi * 0.5, 0), col, 0.12, Enum.Material.ForceField, folder)
		table.insert(machRings, { Part = mr, Index = i })
	end

	-- Crackling Conqueror & Void-Gold Lightning Bolts along the beam shaft
	if not isLowFX() then
		for wave = 1, 3 do
			task.delay((wave - 1) * 0.18, function()
				if not folder.Parent then return end
				for b = 1, 3 do
					local f0 = (b - 1) / 3
					local f1 = b / 3
					local ang0 = (wave + b) * 1.7
					local ang1 = ang0 + 2.1
					local pA = (beamAimCF * CFrame.new(math.cos(ang0) * rPlasma * 0.55, math.sin(ang0) * rPlasma * 0.55, -f0 * beamLen)).Position
					local pB = (beamAimCF * CFrame.new(math.cos(ang1) * rPlasma * 0.65, math.sin(ang1) * rPlasma * 0.65, -f1 * beamLen)).Position
					spawnDraconicLightningArc(pA, pB, (b % 2 == 0) and PALETTE.Crimson or PALETTE.Violet, PALETTE.AwakenedGold, 0.32 * scale, 6, 0.24, folder)
				end
			end)
		end
	end

	-- Scorched Molten Magma Ground Trench beneath beam
	local trenchCount = isLowFX() and 4 or 7
	for t = 1, trenchCount do
		local p = mawOrigin:Lerp(impactPos, t / trenchCount)
		local gp = findGroundPos(p, actorChar)
		if math.abs(p.Y - gp.Y) < 18 then
			local seam = makePart(
				"ScorchedMagmaTrench_" .. t,
				Enum.PartType.Block,
				Vector3.new(2.8 * scale, 0.18, (beamLen / trenchCount) * 0.92),
				CFrame.lookAt(gp + Vector3.new(0, 0.08, 0), gp + Vector3.new(0, 0.08, 0) + Vector3.new(beamDir.X, 0, beamDir.Z) + Vector3.new(0, 0, 0.001)),
				(t % 2 == 0) and PALETTE.Magma or PALETTE.Crimson,
				0.14,
				Enum.Material.ForceField,
				folder
			)
			TweenService:Create(seam, TweenInfo.new(0.88, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Size = Vector3.new(0.5, 0.05, (beamLen / trenchCount) * 0.92),
				Transparency = 1,
			}):Play()
		end
	end

	local helixNodes = {}
	if not isLowFX() then
		for h = 1, 3 do
			local col = (h == 1 and PALETTE.HotCore) or (h == 2 and PALETTE.AwakenedGold) or PALETTE.Violet
			local hn = makePart("BoloHelixSpirit_" .. h, Enum.PartType.Ball, Vector3.new(0.95, 0.95, 1.6) * scale, beamAimCF, col, 0.04, Enum.Material.ForceField, folder)
			attachRibbonTrail(hn, col, (h == 1) and PALETTE.Crimson or PALETTE.Violet, 1.45 * scale, 0.26)
			table.insert(helixNodes, { Node = hn, Phase = (h - 1) * ((math.pi * 2) / 3) })
		end
	end

	-- Stage 3 (0.14s): Terminal Abyssal Singularity, Ground Runic Seal, Conqueror Lightning & Obsidian Fang Crater at Impact
	task.delay(0.14, function()
		if not folder.Parent then return end
		local gImpact = findGroundPos(impactPos, actorChar)
		DragonSovereignVFX.EmitPrefab("Dragon_Z_SovereignBreath", CFrame.new(impactPos), scale * 1.25)

		spawnRunicMagicCircle(CFrame.new(gImpact + Vector3.new(0, 0.2, 0)), 14 * scale, PALETTE.Crimson, PALETTE.AwakenedGold, 0.78, folder, -6.5)

		local singCore = makePart("TerminalSingularityCore", Enum.PartType.Ball, Vector3.new(3.6, 3.6, 3.6) * scale, CFrame.new(impactPos), PALETTE.Obsidian, 0.04, Enum.Material.SmoothPlastic, folder)
		local singGold = makePart("TerminalSingularityGold", Enum.PartType.Ball, Vector3.new(4.8, 4.8, 4.8) * scale, CFrame.new(impactPos), PALETTE.AwakenedGold, 0.10, Enum.Material.Neon, folder)
		local singCorona = makePart("TerminalSingularityCorona", Enum.PartType.Ball, Vector3.new(6.0, 6.0, 6.0) * scale, CFrame.new(impactPos), PALETTE.Crimson, 0.14, Enum.Material.ForceField, folder)
		local singOuter = makePart("TerminalSingularityViolet", Enum.PartType.Ball, Vector3.new(7.6, 7.6, 7.6) * scale, CFrame.new(impactPos), PALETTE.Violet, 0.24, Enum.Material.ForceField, folder)
		makeSafeLight(singCore, PALETTE.Crimson, 1.42, 16, 0.72)

		TweenService:Create(singCore, TweenInfo.new(0.56, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = Vector3.new(20, 20, 20) * scale, Transparency = 1 }):Play()
		TweenService:Create(singGold, TweenInfo.new(0.60, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = Vector3.new(24, 24, 24) * scale, Transparency = 1 }):Play()
		TweenService:Create(singCorona, TweenInfo.new(0.66, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = Vector3.new(29, 29, 29) * scale, Transparency = 1 }):Play()
		TweenService:Create(singOuter, TweenInfo.new(0.72, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = Vector3.new(35, 35, 35) * scale, Transparency = 1 }):Play()

		spawnShockRing(gImpact + Vector3.new(0, 0.2, 0), nil, PALETTE.Crimson, 4, 34 * scale, 0.36, 0.60, Enum.Material.ForceField, folder)
		spawnShockRing(gImpact + Vector3.new(0, 0.45, 0), nil, PALETTE.AwakenedGold, 3, 26 * scale, 0.28, 0.50, Enum.Material.ForceField, folder)
		spawnShockRing(gImpact + Vector3.new(0, 0.70, 0), nil, PALETTE.Violet, 3, 20 * scale, 0.22, 0.44, Enum.Material.ForceField, folder)

		local boltNum = isLowFX() and 0 or 8
		for b = 1, boltNum do
			local bAng = (b - 1) * ((math.pi * 2) / boltNum)
			local bEnd = gImpact + Vector3.new(math.cos(bAng) * 14 * scale, (1.5 + (b % 3) * 3.5) * scale, math.sin(bAng) * 14 * scale)
			spawnDraconicLightningArc(impactPos, bEnd, (b % 2 == 0) and PALETTE.Crimson or PALETTE.Violet, PALETTE.AwakenedGold, 0.34 * scale, 6, 0.36, folder)
		end

		local craterSpikes = isLowFX() and 6 or 12
		for s = 1, craterSpikes do
			local ang = (s - 1) * ((math.pi * 2) / craterSpikes)
			local cr = 8.4 * scale
			local spPos = gImpact + Vector3.new(math.cos(ang) * cr, -0.6, math.sin(ang) * cr)
			local shard = makePart(
				"BreathCraterSpike_" .. s,
				Enum.PartType.Wedge,
				Vector3.new(1.55 * scale, 6.2 * scale, 2.1 * scale),
				CFrame.lookAt(spPos, gImpact + Vector3.new(0, 5.2 * scale, 0)) * CFrame.Angles(-0.35, 0, 0),
				(s % 3 == 0) and PALETTE.AwakenedGold or ((s % 2 == 0) and PALETTE.SlateArmor or PALETTE.Crimson),
				0.06,
				(s % 2 == 0) and Enum.Material.Slate or Enum.Material.ForceField,
				folder
			)
			TweenService:Create(shard, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				CFrame = shard.CFrame * CFrame.new(0, 2.6 * scale, 0),
			}):Play()
			task.delay(0.48, function()
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
		local pulse = 1 + 0.18 * math.sin(el * 38)

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
		muzzleRing3.CFrame = liveAim * CFrame.Angles(el * 15, math.pi * 0.5, 0)
		muzzleRing1.Size = Vector3.new(0.26 * scale, 6.2 * scale * pulse, 6.2 * scale * pulse)
		muzzleRing2.Size = Vector3.new(0.20 * scale, 8.8 * scale * pulse, 8.8 * scale * pulse)
		muzzleRing3.Size = Vector3.new(0.16 * scale, 10.8 * scale * pulse, 10.8 * scale * pulse)

		innerBeam.CFrame = liveMid
		goldBeam.CFrame = liveMid
		plasmaBeam.CFrame = liveMid
		voidMantle.CFrame = liveMid

		if el > 0.20 and el <= 0.60 then
			innerBeam.Size = Vector3.new(liveLen, rInner * pulse, rInner * pulse)
			goldBeam.Size = Vector3.new(liveLen, rGold * pulse, rGold * pulse)
			plasmaBeam.Size = Vector3.new(liveLen, rPlasma * pulse, rPlasma * pulse)
			voidMantle.Size = Vector3.new(liveLen, rVoid * (2 - pulse * 0.9), rVoid * (2 - pulse * 0.9))
		elseif el > 0.60 then
			local fade = (el - 0.60) / (totalDur - 0.60)
			innerBeam.Size = Vector3.new(liveLen, rInner * (1 - fade), rInner * (1 - fade))
			goldBeam.Size = Vector3.new(liveLen, rGold * (1 - fade * 0.85), rGold * (1 - fade * 0.85))
			plasmaBeam.Size = Vector3.new(liveLen, rPlasma * (1 - fade * 0.72), rPlasma * (1 - fade * 0.72))
			voidMantle.Size = Vector3.new(liveLen, rVoid * (1 - fade * 0.5), rVoid * (1 - fade * 0.5))
			innerBeam.Transparency = fade
			goldBeam.Transparency = 0.08 + fade * 0.92
			plasmaBeam.Transparency = 0.14 + fade * 0.86
			voidMantle.Transparency = 0.26 + fade * 0.74
			mawOrb.Transparency = fade
			mawShell.Transparency = 0.16 + fade * 0.84
			muzzleRing1.Transparency = 0.10 + fade * 0.90
			muzzleRing2.Transparency = 0.16 + fade * 0.84
			muzzleRing3.Transparency = 0.18 + fade * 0.82
		end

		for _, mr in ipairs(machRings) do
			if mr.Part and mr.Part.Parent then
				local travel = ((el * 54 + (mr.Index - 1) * (liveLen / machCount)) % liveLen)
				local rSz = (rPlasma * 1.32 + math.sin(el * 24 + mr.Index) * 1.2 * scale) * (1 - u * 0.35)
				mr.Part.CFrame = liveAim * CFrame.new(0, 0, -travel) * CFrame.Angles(el * 15 + mr.Index, math.pi * 0.5, 0)
				mr.Part.Size = Vector3.new(0.26 * scale, rSz, rSz)
				mr.Part.Transparency = math.clamp(0.10 + u * 0.90, 0.10, 1)
			end
		end

		for _, hn in ipairs(helixNodes) do
			if hn.Node and hn.Node.Parent then
				local zTravel = ((el * 68) % liveLen)
				local ang = el * 28 + hn.Phase
				local hRad = rPlasma * 0.74
				hn.Node.CFrame = liveAim * CFrame.new(math.cos(ang) * hRad, math.sin(ang) * hRad, -zTravel)
				if u > 0.72 then
					hn.Node.Transparency = (u - 0.72) / 0.28
				end
			end
		end
	end)

	if isLocal then
		emitCameraTrauma(0.55, 5.0, beamDir)
	end
end

-- ============================================================================
-- 6. [X] BÁN LONG HƯ KHÔNG TRẢO (TWIN 4-CLAW X-CROSS, DRAGON JAW & MOLTEN GOUGES)
-- Locked to `Paw_FL` & `Paw_FR` (`LeftHand`/`RightHand` on Hybrid)!
-- ============================================================================
function DragonSovereignVFX.SpawnVoidTalons(actorChar, startPos, endPos, lookDir, baseScale, isAwakened, isLocal)
	local anchors = DragonSovereignVFX.ResolveDragonStateAndAnchors(actorChar, startPos, lookDir)
	local tierMult = (anchors.Tier >= 2 and 1.34) or (anchors.Tier == 1 and 1.18 or 1.05)
	local scale = (baseScale or 1.0) * tierMult

	local originMid = (anchors.ClawL_CF.Position + anchors.ClawR_CF.Position) * 0.5
	local rawVec = endPos - originMid
	local lungeDist = math.clamp(rawVec.Magnitude, 20 * scale, 36 * scale)
	local dir = (rawVec.Magnitude > 3) and rawVec.Unit or anchors.LookDir
	local dstPos = originMid + dir * lungeDist
	local pathCF = CFrame.lookAt(originMid, dstPos)

	local folder = Instance.new("Folder")
	folder.Name = "Dragon_X_VoidTalons"
	folder.Parent = (getTempFolder())
	Debris:AddItem(folder, 1.15)

	DragonSovereignVFX.EmitPrefab("Dragon_X_VoidTalons", pathCF * CFrame.new(0, 0, -2.5 * scale), scale)

	-- Ground Draconic Launch Seal + Lunging 3D Spectral Fire-Dragon Head Construct
	local gStart = findGroundPos(originMid, actorChar)
	spawnRunicMagicCircle(CFrame.new(gStart + Vector3.new(0, 0.16, 0)), 8.5 * scale, PALETTE.BloodFlame, PALETTE.SolarGold, 0.55, folder, 6.2)
	spawnSpectralDragonHeadConstruct(
		pathCF * CFrame.new(0, 0.8 * scale, -1.5 * scale),
		CFrame.lookAt(dstPos + Vector3.new(0, 0.8 * scale, 0), dstPos + dir * 5),
		1.48 * scale,
		PALETTE.BloodFlame,
		PALETTE.SolarGold,
		PALETTE.HotCore,
		0.34,
		folder,
		true
	)

	-- Twin Colossal 4-Clawed Obsidian-Crimson Spectral Dragon Talons raking in X-Cross
	for _, side in ipairs({ -1, 1 }) do
		local pawStart = (side < 0) and anchors.ClawL_CF.Position or anchors.ClawR_CF.Position
		local startClawCF = safeLookAt(pawStart, dstPos, dir) * CFrame.new(side * 2.4 * scale, 2.0 * scale, 0) * CFrame.Angles(math.rad(-16), math.rad(-side * 24), math.rad(side * 38))
		local endClawCF = safeLookAt(dstPos, dstPos + dir, dir) * CFrame.new(-side * 3.0 * scale, -0.4 * scale, 1.4 * scale) * CFrame.Angles(math.rad(22), math.rad(side * 28), math.rad(-side * 42))

		local gauntlet = makePart("SpectralDragonPaw_" .. side, Enum.PartType.Block, Vector3.new(3.1, 1.15, 2.9) * scale, startClawCF, PALETTE.SlateArmor, 0.08, Enum.Material.Slate, folder)
		TweenService:Create(gauntlet, TweenInfo.new(0.34, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			CFrame = endClawCF,
			Transparency = 1,
		}):Play()

		for finger = 1, 4 do
			local fOff = (finger - 2.5) * 0.84 * scale
			local col = (finger % 2 == 0) and PALETTE.BloodFlame or PALETTE.SolarGold
			local blade = makePart("SpectralClawBlade_" .. side .. "_" .. finger, Enum.PartType.Wedge, Vector3.new(0.42, 0.68, 7.4) * scale, startClawCF * CFrame.new(fOff, 0, -3.2 * scale), col, 0.04, Enum.Material.ForceField, folder)
			local core = makePart("SpectralClawCore_" .. side .. "_" .. finger, Enum.PartType.Block, Vector3.new(0.22, 0.36, 8.0) * scale, startClawCF * CFrame.new(fOff, 0, -3.5 * scale), (finger == 2) and PALETTE.HotCore or PALETTE.Obsidian, 0.02, Enum.Material.Neon, folder)
			if not isLowFX() and (finger == 1 or finger == 4) then
				attachRibbonTrail(blade, PALETTE.HotCore, col, 0.85 * scale, 0.24)
			end
			TweenService:Create(blade, TweenInfo.new(0.36, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				CFrame = endClawCF * CFrame.new(fOff * 1.4, 0, -4.6 * scale),
				Size = Vector3.new(0.18, 0.30, 11.6) * scale,
				Transparency = 1,
			}):Play()
			TweenService:Create(core, TweenInfo.new(0.36, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				CFrame = endClawCF * CFrame.new(fOff * 1.4, 0, -4.9 * scale),
				Size = Vector3.new(0.10, 0.16, 12.2) * scale,
				Transparency = 1,
			}):Play()
		end
	end

	-- 10 Suspended Spatial Void-Flame Rift Slash Gashes forming a blazing X-Cross
	local midRiftCF = pathCF * CFrame.new(0, 0.8 * scale, -lungeDist * 0.55)
	local gashTotal = isLowFX() and 4 or 10
	for g = 1, gashTotal do
		local side = (g <= gashTotal * 0.5) and -1 or 1
		local lane = ((g - 1) % math.max(1, gashTotal * 0.5)) - 2.0
		local gCF = midRiftCF * CFrame.Angles(0, 0, math.rad(side * 38)) * CFrame.new(0, lane * 0.92 * scale, -(g % 2) * 0.5)
		local gash = makePart("VoidRiftGash_" .. g, Enum.PartType.Block, Vector3.new(16.0 * scale, 0.32 * scale, 0.95 * scale), gCF, (g % 2 == 0) and PALETTE.BloodFlame or PALETTE.SolarGold, 0.04, Enum.Material.ForceField, folder)
		local gashCore = makePart("VoidRiftCore_" .. g, Enum.PartType.Block, Vector3.new(13.5 * scale, 0.45 * scale, 0.48 * scale), gCF, PALETTE.Obsidian, 0.02, Enum.Material.SmoothPlastic, folder)
		TweenService:Create(gash, TweenInfo.new(0.50, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = Vector3.new(24.5 * scale, 0.10, 1.9 * scale),
			CFrame = gCF * CFrame.new(0, 0, -3.2 * scale),
			Transparency = 1,
		}):Play()
		TweenService:Create(gashCore, TweenInfo.new(0.46, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = Vector3.new(20.5 * scale, 0.15, 0.95 * scale),
			CFrame = gCF * CFrame.new(0, 0, -3.2 * scale),
			Transparency = 1,
		}):Play()
	end

	-- 4 Parallel Molten Magma Claw-Gouge Trenches + 10 Erupting Obsidian-Magma Fang Spires + Draconic Lightning at Impact
	task.delay(0.18, function()
		if not folder.Parent then return end
		local gDst = findGroundPos(dstPos, actorChar)
		DragonSovereignVFX.EmitPrefab("Dragon_X_VoidTalons", CFrame.new(gDst + Vector3.new(0, 1.2, 0)), scale * 1.2)
		makeSafeLight(makePart("TalonImpactNode", Enum.PartType.Ball, Vector3.new(2.4, 2.4, 2.4) * scale, CFrame.new(gDst + Vector3.new(0, 1.4, 0)), PALETTE.HotCore, 0.15, Enum.Material.ForceField, folder), PALETTE.BloodFlame, 1.40, 16, 0.58)

		spawnRunicMagicCircle(CFrame.new(gDst + Vector3.new(0, 0.18, 0)), 12.5 * scale, PALETTE.BloodFlame, PALETTE.SolarGold, 0.68, folder, -5.8)

		local flatDir = Vector3.new(dir.X, 0, dir.Z)
		flatDir = (flatDir.Magnitude > 0.05) and flatDir.Unit or Vector3.new(0, 0, -1)
		local gougeCF = CFrame.lookAt(gDst + Vector3.new(0, 0.10, 0), gDst + Vector3.new(0, 0.10, 0) + flatDir)

		for c = 1, 4 do
			local xOff = (c - 2.5) * 1.75 * scale
			local gouge = makePart(
				"MoltenClawGouge_" .. c,
				Enum.PartType.Block,
				Vector3.new(0.72 * scale, 0.18, 15.0 * scale),
				gougeCF * CFrame.new(xOff, 0, 2.4 * scale),
				(c % 2 == 0) and PALETTE.Magma or PALETTE.BloodFlame,
				0.08,
				Enum.Material.ForceField,
				folder
			)
			TweenService:Create(gouge, TweenInfo.new(0.72, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Size = Vector3.new(0.14, 0.05, 17.0 * scale),
				Transparency = 1,
			}):Play()
		end

		local spireCount = isLowFX() and 5 or 10
		for f = 1, spireCount do
			local ang = (f - 1) * ((math.pi * 2) / spireCount)
			local spPos = gDst + Vector3.new(math.cos(ang) * 6.4 * scale, -0.8, math.sin(ang) * 6.4 * scale)
			local h = 8.6 * scale
			local spire = makePart(
				"TalonObsidianSpire_" .. f,
				Enum.PartType.Wedge,
				Vector3.new(1.55 * scale, h, 2.1 * scale),
				CFrame.lookAt(spPos, gDst + Vector3.new(0, h, 0)) * CFrame.Angles(-0.30, 0, 0),
				(f % 3 == 0) and PALETTE.SolarGold or ((f % 2 == 0) and PALETTE.SlateArmor or PALETTE.BloodFlame),
				0.06,
				(f % 2 == 0) and Enum.Material.Slate or Enum.Material.ForceField,
				folder
			)
			TweenService:Create(spire, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				CFrame = spire.CFrame * CFrame.new(0, h * 0.44, 0),
			}):Play()
			task.delay(0.45, function()
				if spire.Parent then
					TweenService:Create(spire, TweenInfo.new(0.28), { Transparency = 1 }):Play()
				end
			end)
		end

		local boltNum = isLowFX() and 0 or 8
		for b = 1, boltNum do
			local bAng = (b - 1) * ((math.pi * 2) / boltNum)
			local bEnd = gDst + Vector3.new(math.cos(bAng) * 12.5 * scale, (1.2 + (b % 3) * 2.8) * scale, math.sin(bAng) * 12.5 * scale)
			spawnDraconicLightningArc(gDst + Vector3.new(0, 1.5 * scale, 0), bEnd, (b % 2 == 0) and PALETTE.BloodFlame or PALETTE.Magma, PALETTE.SolarGold, 0.30 * scale, 5, 0.32, folder)
		end

		spawnShockRing(gDst + Vector3.new(0, 0.22, 0), nil, PALETTE.BloodFlame, 3.5, 28 * scale, 0.32, 0.52, Enum.Material.ForceField, folder)
		spawnShockRing(gDst + Vector3.new(0, 0.45, 0), nil, PALETTE.SolarGold, 2.5, 21 * scale, 0.24, 0.44, Enum.Material.ForceField, folder)
		if isLocal then
			emitCameraTrauma(0.48, 3.8, dir)
		end
	end)
end

-- ============================================================================
-- 7. [C] CATACLYSMIC STARSHOWER & SERPENTINE ABYSSAL MAELSTROM
-- Projects from `FX_CrownHalo` -> Overhead Eclipse Stargate -> 12 Dragon-Skull Meteors!
-- ============================================================================
function DragonSovereignVFX.SpawnCataclysmicStarshower(actorChar, startPos, endPos, lookDir, baseScale, isAwakened, isLocal)
	local anchors = DragonSovereignVFX.ResolveDragonStateAndAnchors(actorChar, startPos, lookDir)
	local tierMult = (anchors.Tier >= 2 and 1.38) or (anchors.Tier == 1 and 1.15 or 1.0)
	local scale = (baseScale or 1.0) * tierMult

	local targetCenter = ((endPos - anchors.CenterPos).Magnitude > 3) and endPos or (anchors.CenterPos + anchors.LookDir * (20 * scale))
	local gCenter = findGroundPos(targetCenter, actorChar)
	local skyCenter = gCenter + Vector3.new(0, 32 * scale, 0)

	local folder = Instance.new("Folder")
	folder.Name = "Dragon_C_CataclysmicStarshower"
	folder.Parent = (getTempFolder())
	local totalDur = 1.25
	Debris:AddItem(folder, totalDur + 0.45)

	-- Skyward Beacon Beam shooting from Dragon's `FX_CrownHalo` to Overhead Eclipse Stargate!
	local crownPos = anchors.CrownCF.Position
	local beaconVec = skyCenter - crownPos
	local beaconLen = math.max(6, beaconVec.Magnitude)
	local beaconPart = makePart(
		"CrownSkyBeacon",
		Enum.PartType.Cylinder,
		Vector3.new(beaconLen, 1.8 * scale, 1.8 * scale),
		CFrame.lookAt((crownPos + skyCenter) * 0.5, skyCenter) * CFrame.Angles(0, math.pi * 0.5, 0),
		PALETTE.AwakenedGold,
		0.08,
		Enum.Material.Neon,
		folder
	)
	TweenService:Create(beaconPart, TweenInfo.new(0.36, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = Vector3.new(beaconLen, 0.12, 0.12),
		Transparency = 1,
	}):Play()

	-- Overhead Sovereign Eclipse Stargate + Rotating Runic Sky Circle + Rotating Ground Seal
	spawnRunicMagicCircle(CFrame.new(skyCenter), 18 * scale, PALETTE.AwakenedGold, PALETTE.Crimson, totalDur, folder, 5.2)
	spawnRunicMagicCircle(CFrame.new(gCenter + Vector3.new(0, 0.22, 0)), 16 * scale, PALETTE.Crimson, PALETTE.Violet, totalDur, folder, -4.8)

	local eclipseCore = makePart("SovereignEclipseCore", Enum.PartType.Cylinder, Vector3.new(0.55, 4, 4), CFrame.new(skyCenter) * CFrame.Angles(0, 0, math.pi * 0.5), PALETTE.Obsidian, 0.04, Enum.Material.SmoothPlastic, folder)
	local eclipseCrimson = makePart("SovereignEclipseCrimson", Enum.PartType.Cylinder, Vector3.new(0.42, 6, 6), eclipseCore.CFrame, PALETTE.Crimson, 0.12, Enum.Material.ForceField, folder)
	local eclipseViolet = makePart("SovereignEclipseViolet", Enum.PartType.Cylinder, Vector3.new(0.28, 8, 8), eclipseCore.CFrame, PALETTE.Violet, 0.20, Enum.Material.ForceField, folder)

	TweenService:Create(eclipseCore, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = Vector3.new(0.55, 22 * scale, 22 * scale) }):Play()
	TweenService:Create(eclipseCrimson, TweenInfo.new(0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = Vector3.new(0.42, 30 * scale, 30 * scale) }):Play()
	TweenService:Create(eclipseViolet, TweenInfo.new(0.36, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = Vector3.new(0.28, 38 * scale, 38 * scale) }):Play()

	-- Ground Target Abyssal Seal + 3 Swirling Serpentine Fire-Vortex Maelstrom Dragons
	local groundSeal = makePart("StarfallGroundSeal", Enum.PartType.Cylinder, Vector3.new(0.16, 4, 4), CFrame.new(gCenter + Vector3.new(0, 0.14, 0)) * CFrame.Angles(0, 0, math.pi * 0.5), PALETTE.Crimson, 0.18, Enum.Material.ForceField, folder)
	TweenService:Create(groundSeal, TweenInfo.new(0.30, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.16, 30 * scale, 30 * scale),
	}):Play()

	local vortexNodes = {}
	if not isLowFX() then
		for v = 1, 3 do
			local col = (v == 1 and PALETTE.Crimson) or (v == 2 and PALETTE.AwakenedGold) or PALETTE.Violet
			local vn = makePart("MaelstromSerpent_" .. v, Enum.PartType.Ball, Vector3.new(1.4, 1.4, 2.2) * scale, CFrame.new(gCenter), col, 0.06, Enum.Material.ForceField, folder)
			attachRibbonTrail(vn, PALETTE.HotCore, col, 1.9 * scale, 0.32)
			table.insert(vortexNodes, { Node = vn, Phase = (v - 1) * ((math.pi * 2) / 3) })
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
				local ang = el * 15 + vn.Phase
				local vRad = (5.0 + math.sin(el * 6 + vn.Phase) * 4.2) * scale
				local vY = ((el * 22 + vn.Phase * 2) % (20 * scale))
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

	-- 12 Diagonal Obsidian-Crimson-Gold Draconic Starfall Meteors raining from Eclipse Stargate!
	local meteorCount = isLowFX() and 6 or 12
	for m = 1, meteorCount do
		task.delay(0.06 + (m - 1) * 0.062, function()
			if not folder.Parent then return end
			local isFinal = (m == meteorCount)
			local ang = (m - 1) * 2.39996
			local spreadR = isFinal and 0 or (math.sqrt(m / meteorCount) * 13.0 * scale)
			local hitPos = gCenter + Vector3.new(math.cos(ang) * spreadR, 0, math.sin(ang) * spreadR)
			local spawnPos = skyCenter + Vector3.new(math.cos(ang) * (spreadR * 0.45) - 4.5 * scale, 1.5, math.sin(ang) * (spreadR * 0.45) - 3.2 * scale)

			local mSz = (isFinal and 6.2 or 3.1) * scale
			local mCol = (isFinal and PALETTE.AwakenedGold) or ((m % 2 == 0) and PALETTE.Crimson or PALETTE.Violet)
			local rock = makePart("DraconicMeteorCore_" .. m, Enum.PartType.Ball, Vector3.new(mSz, mSz, mSz), CFrame.lookAt(spawnPos, hitPos), PALETTE.SlateArmor, 0.04, Enum.Material.Slate, folder)
			local corona = makePart("DraconicMeteorCorona_" .. m, Enum.PartType.Ball, Vector3.new(mSz * 1.38, mSz * 1.38, mSz * 1.38), rock.CFrame, mCol, 0.18, Enum.Material.ForceField, folder)
			if not isLowFX() then
				attachRibbonTrail(rock, PALETTE.HotCore, mCol, mSz * 0.92, 0.28)
			end

			local fallDur = isFinal and 0.30 or 0.24
			if isFinal or (m % 3 == 0) then
				spawnSpectralDragonHeadConstruct(
					CFrame.lookAt(spawnPos, hitPos),
					CFrame.lookAt(hitPos, hitPos + (hitPos - spawnPos)),
					(isFinal and 2.15 or 1.15) * scale,
					mCol,
					PALETTE.AwakenedGold,
					PALETTE.HotCore,
					fallDur + 0.06,
					folder,
					true
				)
			end

			TweenService:Create(rock, TweenInfo.new(fallDur, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = CFrame.lookAt(hitPos, hitPos + (hitPos - spawnPos)) }):Play()
			TweenService:Create(corona, TweenInfo.new(fallDur, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = CFrame.lookAt(hitPos, hitPos + (hitPos - spawnPos)) }):Play()

			task.delay(fallDur, function()
				if rock.Parent then rock:Destroy() end
				if corona.Parent then corona:Destroy() end
				if not folder.Parent then return end

				spawnShockRing(hitPos + Vector3.new(0, 0.18, 0), nil, mCol, 2.0, (isFinal and 34 or 14.0) * scale, isFinal and 0.40 or 0.24, isFinal and 0.58 or 0.36, Enum.Material.ForceField, folder)
				if m % 2 == 1 or isFinal then
					spawnDraconicLightningArc(hitPos + Vector3.new(0, 12 * scale, 0), hitPos, mCol, PALETTE.AwakenedGold, (isFinal and 0.48 or 0.26) * scale, 6, 0.30, folder)
				end
				if m % 3 == 1 or isFinal then
					DragonSovereignVFX.EmitPrefab("Dragon_C_CataclysmicStarshower", CFrame.new(hitPos + Vector3.new(0, 0.8, 0)), isFinal and (scale * 1.35) or (scale * 0.85))
				end
				if isFinal then
					local blast = makePart("FinalStarfallSupernova", Enum.PartType.Ball, Vector3.new(4.5, 4.5, 4.5) * scale, CFrame.new(hitPos), PALETTE.Crimson, 0.12, Enum.Material.ForceField, folder)
					local goldBlast = makePart("FinalStarfallGoldCore", Enum.PartType.Ball, Vector3.new(3.5, 3.5, 3.5) * scale, CFrame.new(hitPos), PALETTE.AwakenedGold, 0.08, Enum.Material.Neon, folder)
					makeSafeLight(blast, PALETTE.Crimson, 1.42, 16, 0.62)
					TweenService:Create(blast, TweenInfo.new(0.52, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
						Size = Vector3.new(30, 30, 30) * scale,
						Transparency = 1,
					}):Play()
					TweenService:Create(goldBlast, TweenInfo.new(0.44, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
						Size = Vector3.new(23, 23, 23) * scale,
						Transparency = 1,
					}):Play()

					local spireNum = isLowFX() and 5 or 10
					for s = 1, spireNum do
						local sAng = (s - 1) * ((math.pi * 2) / spireNum)
						local sPos = hitPos + Vector3.new(math.cos(sAng) * 9.5 * scale, -0.6, math.sin(sAng) * 9.5 * scale)
						local sp = makePart("SupernovaMonolith_" .. s, Enum.PartType.Wedge, Vector3.new(1.6 * scale, 7.5 * scale, 2.2 * scale), CFrame.lookAt(sPos, hitPos + Vector3.new(0, 6.5 * scale, 0)) * CFrame.Angles(-0.32, 0, 0), (s % 2 == 0) and PALETTE.AwakenedGold or PALETTE.Crimson, 0.06, Enum.Material.ForceField, folder)
						TweenService:Create(sp, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { CFrame = sp.CFrame * CFrame.new(0, 3.2 * scale, 0) }):Play()
						task.delay(0.42, function()
							if sp.Parent then TweenService:Create(sp, TweenInfo.new(0.26), { Transparency = 1 }):Play() end
						end)
					end
					if isLocal then
						emitCameraTrauma(0.60, 6.0)
					end
				elseif isLocal and m % 2 == 0 then
					emitCameraTrauma(0.18, 0.9)
				end
			end)
		end)
	end
end

-- ============================================================================
-- 8. [F] SOARING SOVEREIGN SLIPSTREAM RUSH (3D DRAGON HEAD SPEARHEAD, MACH CONES & LIGHTNING)
-- ============================================================================
function DragonSovereignVFX.SpawnSoaringRush(actorChar, startPos, endPos, lookDir, baseScale, isAwakened, isLocal)
	local anchors = DragonSovereignVFX.ResolveDragonStateAndAnchors(actorChar, startPos, lookDir)
	local tierMult = (anchors.Tier >= 2 and 1.35) or (anchors.Tier == 1 and 1.15 or 1.0)
	local scale = (baseScale or 1.0) * tierMult

	local p0 = anchors.CenterPos
	local rawVec = endPos - p0
	local rushDist = math.clamp(rawVec.Magnitude, 22 * scale, 38 * scale)
	local dir = (rawVec.Magnitude > 3) and rawVec.Unit or anchors.LookDir
	local p1 = p0 + dir * rushDist
	local rushCF = CFrame.lookAt(p0, p1)

	local folder = Instance.new("Folder")
	folder.Name = "Dragon_F_SoaringRush"
	folder.Parent = (getTempFolder())
	Debris:AddItem(folder, 0.90)

	DragonSovereignVFX.EmitPrefab("Dragon_F_SoarRush", rushCF, scale)
	makeSafeLight(makePart("RushSonicCore", Enum.PartType.Ball, Vector3.new(2.0, 2.0, 2.0) * scale, rushCF, PALETTE.HotCore, 0.14, Enum.Material.ForceField, folder), PALETTE.Violet, 1.35, 15, 0.45)

	-- Colossal 3D Spectral Sovereign Dragon Head Spearhead leading the flight rush!
	spawnSpectralDragonHeadConstruct(
		rushCF * CFrame.new(0, 0.5 * scale, -1.5 * scale),
		CFrame.lookAt(p1, p1 + dir * 5),
		1.85 * scale,
		PALETTE.Violet,
		PALETTE.AwakenedGold,
		PALETTE.HotCore,
		0.38,
		folder,
		false
	)

	-- 8 Expanding Supersonic Mach Cones + Conqueror Lightning Arcs along flight path
	local coneCount = isLowFX() and 4 or 8
	for i = 1, coneCount do
		local frac = (i - 1) / math.max(1, coneCount - 1)
		task.delay((i - 1) * 0.026, function()
			if not folder.Parent then return end
			local pt = p0:Lerp(p1, frac)
			local col = (i % 3 == 0 and PALETTE.AwakenedGold) or ((i % 2 == 0) and PALETTE.Crimson or PALETTE.Violet)
			local ring = makePart(
				"SupersonicMachRing_" .. i,
				Enum.PartType.Cylinder,
				Vector3.new(0.34 * scale, (4.0 + frac * 2.5) * scale, (4.0 + frac * 2.5) * scale),
				CFrame.lookAt(pt, pt + dir) * CFrame.Angles(0, math.pi * 0.5, i * 0.6),
				col,
				0.10,
				Enum.Material.ForceField,
				folder
			)
			TweenService:Create(ring, TweenInfo.new(0.40, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = Vector3.new(0.08, (13.0 + frac * 4.0) * scale, (13.0 + frac * 4.0) * scale),
				Transparency = 1,
			}):Play()
			if i > 1 and not isLowFX() then
				local prevPt = p0:Lerp(p1, (i - 2) / math.max(1, coneCount - 1))
				spawnDraconicLightningArc(prevPt, pt + Vector3.new(0, (i % 2 == 0 and 1.5 or -1.5) * scale, 0), col, PALETTE.AwakenedGold, 0.28 * scale, 4, 0.28, folder)
			end
		end)
	end

	-- Triple Helical Wingtip & Tail Slipstream Ribbons racing from `WingForearm_L/R` to `p1`
	if not isLowFX() then
		local spirits = {}
		for idx = 1, 3 do
			local wStart = (idx == 1 and anchors.WingL_CF.Position) or (idx == 2 and anchors.WingR_CF.Position) or anchors.Tail_CF.Position
			local col = (idx == 1 and PALETTE.Crimson) or (idx == 2 and PALETTE.Violet) or PALETTE.AwakenedGold
			local sp = makePart("WingtipSlipstream_" .. idx, Enum.PartType.Ball, Vector3.new(0.9, 0.9, 1.6) * scale, safeLookAt(wStart, p1, dir), col, 0.04, Enum.Material.ForceField, folder)
			attachRibbonTrail(sp, PALETTE.HotCore, col, 1.55 * scale, 0.30)
			table.insert(spirits, { Node = sp, Phase = (idx - 1) * ((math.pi * 2) / 3) })
		end

		local t0 = os.clock()
		local conn
		conn = RunService.Heartbeat:Connect(function()
			local el = os.clock() - t0
			if el >= 0.38 or not folder.Parent then
				if conn then conn:Disconnect() end
				return
			end
			local u = el / 0.38
			for _, sp in ipairs(spirits) do
				if sp.Node and sp.Node.Parent then
					local ang = u * math.pi * 4.0 + sp.Phase
					local rad = (4.2 * (1 - u * 0.45)) * scale
					sp.Node.CFrame = rushCF * CFrame.new(math.cos(ang) * rad, math.sin(ang) * rad, -u * rushDist)
				end
			end
		end)
	end

	if isLocal then
		emitCameraTrauma(0.32, 3.4, dir)
	end
end

-- ============================================================================
-- 8B. DISTINCT FORM 1 (HYBRID) vs FORM 2 (SOVEREIGN) SKILL SET VFX
--   Form 1 [Z]: Hỏa Long Liên Đạn (SpawnHybridFireballVolley — 5 Dragon-Head Magma Barrage)
--   Form 1 [C]: Cuồng Long Lốc Xoáy (SpawnHybridInfernoCyclone — Coiling Dragon Fire Tornado)
--   Form 1 [F]: Long Ảnh Bộ (SpawnHybridWingDash — Dragon Spearhead & 6 Twin-Wing Slash Rush)
--   Form 2 [X]: Long Hoàng Giáng Thế (SpawnSovereignSkyfallDive — Sky Stargate & Sovereign Dragon Dive)
-- ============================================================================
function DragonSovereignVFX.SpawnHybridFireballVolley(actorChar, startPos, endPos, lookDir, baseScale, isAwakened, isLocal)
	local anchors = DragonSovereignVFX.ResolveDragonStateAndAnchors(actorChar, startPos, lookDir)
	local scale = (baseScale or 1.0) * 1.15
	local origin = anchors.MawCF.Position
	local rawVec = endPos - origin
	local dist = math.clamp(rawVec.Magnitude, 20 * scale, 36 * scale)
	local dir = (rawVec.Magnitude > 2) and rawVec.Unit or anchors.LookDir
	local aimCF = CFrame.lookAt(origin, origin + dir * dist)

	local folder = Instance.new("Folder")
	folder.Name = "DragonForm1_Z_FireballVolley"
	folder.Parent = (getTempFolder())
	Debris:AddItem(folder, 1.65)

	-- Rotating Crimson-Solar Draconic Muzzle Seal in front of caster
	spawnRunicMagicCircle(aimCF * CFrame.new(0, 0, -1.6 * scale) * CFrame.Angles(math.pi * 0.5, 0, 0), 4.5 * scale, PALETTE.BloodFlame, PALETTE.SolarGold, 0.78, folder, 8.0)

	local shotCount = isLowFX() and 3 or 5
	for shot = 1, shotCount do
		task.delay((shot - 1) * 0.085, function()
			if not folder.Parent then return end
			local laneOffset = (shot - (shotCount + 1) * 0.5) * 1.25 * scale
			local launchPos = origin + anchors.BaseCF.RightVector * laneOffset + Vector3.new(0, (0.35 + (shot % 2) * 0.45) * scale, 0)
			local targetPos = findGroundPos(origin + dir * (dist * (0.48 + (shot / shotCount) * 0.56)) + anchors.BaseCF.RightVector * (laneOffset * 0.65), actorChar) + Vector3.new(0, 0.6, 0)
			local orbSz = (1.95 + shot * 0.22) * scale

			local core = makePart("HybridFireballCore_" .. shot, Enum.PartType.Ball, Vector3.new(orbSz, orbSz, orbSz), CFrame.lookAt(launchPos, targetPos), PALETTE.SolarGold, 0.02, Enum.Material.Neon, folder)
			local shell = makePart("HybridFireballShell_" .. shot, Enum.PartType.Ball, Vector3.new(orbSz * 1.48, orbSz * 1.48, orbSz * 1.48), core.CFrame, PALETTE.BloodFlame, 0.18, Enum.Material.ForceField, folder)
			if not isLowFX() then
				attachRibbonTrail(core, PALETTE.SolarGold, PALETTE.BloodFlame, orbSz * 1.05, 0.25)
			end
			spawnShockRing(launchPos, CFrame.lookAt(launchPos, targetPos), PALETTE.SolarGold, 1.2 * scale, 5.8 * scale, 0.20 * scale, 0.24, Enum.Material.ForceField, folder)

			local flyDur = 0.22
			-- 3D Sculpted Fire-Dragon Head Construct leading each fireball!
			spawnSpectralDragonHeadConstruct(
				CFrame.lookAt(launchPos, targetPos),
				CFrame.lookAt(targetPos, targetPos + (targetPos - launchPos)),
				(0.92 + shot * 0.08) * scale,
				PALETTE.BloodFlame,
				PALETTE.SolarGold,
				PALETTE.HotCore,
				flyDur + 0.05,
				folder,
				true
			)

			TweenService:Create(core, TweenInfo.new(flyDur, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = CFrame.new(targetPos) }):Play()
			TweenService:Create(shell, TweenInfo.new(flyDur, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = CFrame.new(targetPos) }):Play()

			task.delay(flyDur, function()
				if core.Parent then core:Destroy() end
				if shell.Parent then shell:Destroy() end
				if not folder.Parent then return end
				DragonSovereignVFX.EmitPrefab("Dragon_Z_SovereignBreath", CFrame.new(targetPos), scale * 0.90)
				spawnShockRing(targetPos, nil, (shot == shotCount) and PALETTE.SolarGold or PALETTE.Magma, 2.2 * scale, (12 + shot * 2.8) * scale, 0.30 * scale, 0.40, Enum.Material.ForceField, folder)
				spawnShockRing(targetPos + Vector3.new(0, 0.25, 0), nil, PALETTE.BloodFlame, 1.8 * scale, (9 + shot * 2.2) * scale, 0.22 * scale, 0.32, Enum.Material.ForceField, folder)

				-- Rising Volcanic Magma Geyser Pillar + Erupting Fangs + Flame Lightning
				local geyserH = (11 + shot * 2.4) * scale
				local geyser = makePart("VolcanicGeyser_" .. shot, Enum.PartType.Cylinder, Vector3.new(geyserH, (3.2 + shot * 0.45) * scale, (3.2 + shot * 0.45) * scale), CFrame.new(targetPos + Vector3.new(0, geyserH * 0.45, 0)) * CFrame.Angles(0, 0, math.pi * 0.5), (shot % 2 == 0) and PALETTE.SolarGold or PALETTE.BloodFlame, 0.10, Enum.Material.ForceField, folder)
				TweenService:Create(geyser, TweenInfo.new(0.38, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					Size = Vector3.new(geyserH * 1.35, 0.25, 0.25),
					Transparency = 1,
				}):Play()

				local dome = makePart("FireballBlast_" .. shot, Enum.PartType.Ball, Vector3.new(2.8, 2.8, 2.8) * scale, CFrame.new(targetPos), PALETTE.BloodFlame, 0.12, Enum.Material.ForceField, folder)
				makeSafeLight(dome, PALETTE.Magma, 1.36, 15, 0.38)
				TweenService:Create(dome, TweenInfo.new(0.36, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					Size = Vector3.new(11 + shot * 2.4, 11 + shot * 2.4, 11 + shot * 2.4) * scale,
					Transparency = 1,
				}):Play()

				if not isLowFX() then
					for b = 1, 3 do
						local bAng = (b - 1) * ((math.pi * 2) / 3) + shot
						local bEnd = targetPos + Vector3.new(math.cos(bAng) * 7.5 * scale, (2.2 + b * 1.4) * scale, math.sin(bAng) * 7.5 * scale)
						spawnDraconicLightningArc(targetPos, bEnd, PALETTE.BloodFlame, PALETTE.SolarGold, 0.26 * scale, 5, 0.26, folder)
					end
				end
				if isLocal then
					emitCameraTrauma(0.22 + shot * 0.04, 1.6, dir)
				end
			end)
		end)
	end
end

function DragonSovereignVFX.SpawnHybridInfernoCyclone(actorChar, startPos, endPos, lookDir, baseScale, isAwakened, isLocal)
	local anchors = DragonSovereignVFX.ResolveDragonStateAndAnchors(actorChar, startPos, lookDir)
	local scale = (baseScale or 1.0) * 1.18
	local centerPos = anchors.CenterPos
	local gPos = findGroundPos(centerPos, actorChar)

	local folder = Instance.new("Folder")
	folder.Name = "DragonForm1_C_InfernoCyclone"
	folder.Parent = (getTempFolder())
	Debris:AddItem(folder, 1.38)

	DragonSovereignVFX.EmitPrefab("Dragon_X_VoidTalons", CFrame.new(centerPos), scale * 1.2)
	makeSafeLight(makePart("CycloneCoreLight", Enum.PartType.Ball, Vector3.new(1.8, 1.8, 1.8), CFrame.new(centerPos), PALETTE.Magma, 0.18, Enum.Material.ForceField, folder), PALETTE.Magma, 1.40, 16, 0.92)

	-- Double-Ring Rotating Crimson-Gold Draconic Magic Seal on the ground
	spawnRunicMagicCircle(CFrame.new(gPos + Vector3.new(0, 0.18, 0)), 14.5 * scale, PALETTE.BloodFlame, PALETTE.SolarGold, 0.95, folder, 6.8)

	-- Central Towering Firestorm Funnel Core + Outer Crimson Vortex
	local funnelH = 24 * scale
	local coreFunnel = makePart("CycloneCoreFunnel", Enum.PartType.Cylinder, Vector3.new(funnelH, 3.8 * scale, 3.8 * scale), CFrame.new(gPos + Vector3.new(0, funnelH * 0.5, 0)) * CFrame.Angles(0, 0, math.pi * 0.5), PALETTE.SolarGold, 0.10, Enum.Material.Neon, folder)
	local outerFunnel = makePart("CycloneOuterFunnel", Enum.PartType.Cylinder, Vector3.new(funnelH, 7.6 * scale, 7.6 * scale), coreFunnel.CFrame, PALETTE.BloodFlame, 0.22, Enum.Material.ForceField, folder)

	local blades = {}
	local ringLayers = isLowFX() and 4 or 6
	for i = 1, ringLayers do
		local col = (i % 3 == 0 and PALETTE.SolarGold) or ((i % 2 == 0) and PALETTE.Magma or PALETTE.BloodFlame)
		local ring = makePart("CycloneRing_" .. i, Enum.PartType.Cylinder, Vector3.new(0.28 * scale, (6.5 + i * 2.5) * scale, (6.5 + i * 2.5) * scale), CFrame.new(gPos + Vector3.new(0, i * 2.1 * scale, 0)) * CFrame.Angles(0, 0, math.pi * 0.5), col, 0.14, Enum.Material.ForceField, folder)
		if not isLowFX() then
			attachRibbonTrail(ring, PALETTE.HotCore, col, 1.25 * scale, 0.26)
		end
		table.insert(blades, { Part = ring, Index = i })
	end

	-- 3 Coiling Fire-Dragon Spirits spiraling up the Cyclone
	local dragonSpirits = {}
	if not isLowFX() then
		for d = 1, 3 do
			local col = (d == 1 and PALETTE.BloodFlame) or (d == 2 and PALETTE.SolarGold) or PALETTE.Magma
			local sp = makePart("CycloneFireDragon_" .. d, Enum.PartType.Ball, Vector3.new(1.35, 1.35, 2.2) * scale, CFrame.new(gPos), col, 0.04, Enum.Material.Neon, folder)
			attachRibbonTrail(sp, PALETTE.HotCore, col, 1.85 * scale, 0.32)
			table.insert(dragonSpirits, { Node = sp, Phase = (d - 1) * ((math.pi * 2) / 3) })
		end
	end

	for pulse = 1, 4 do
		task.delay((pulse - 1) * 0.14, function()
			if not folder.Parent then return end
			spawnShockRing(gPos + Vector3.new(0, 0.2, 0), nil, (pulse % 2 == 0) and PALETTE.SolarGold or PALETTE.BloodFlame, 18 * scale, 3.5 * scale, 0.28 * scale, 0.28, Enum.Material.ForceField, folder)
			if not isLowFX() then
				for b = 1, 2 do
					local bAng = (pulse * 1.7) + b * math.pi
					local pA = gPos + Vector3.new(math.cos(bAng) * 8.5 * scale, 0.5, math.sin(bAng) * 8.5 * scale)
					local pB = gPos + Vector3.new(math.cos(bAng + 1.1) * 4.5 * scale, 16 * scale, math.sin(bAng + 1.1) * 4.5 * scale)
					spawnDraconicLightningArc(pA, pB, PALETTE.BloodFlame, PALETTE.SolarGold, 0.28 * scale, 5, 0.24, folder)
				end
			end
		end)
	end

	-- Final Outward Inferno Detonation at 0.58s
	task.delay(0.58, function()
		if not folder.Parent then return end
		local curRoot = actorChar and actorChar:FindFirstChild("HumanoidRootPart")
		local finPos = findGroundPos((curRoot and curRoot.Position) or centerPos, actorChar)
		spawnShockRing(finPos + Vector3.new(0, 0.25, 0), nil, PALETTE.BloodFlame, 3.0 * scale, 26 * scale, 0.36 * scale, 0.45, Enum.Material.ForceField, folder)
		spawnShockRing(finPos + Vector3.new(0, 0.55, 0), nil, PALETTE.SolarGold, 2.5 * scale, 20 * scale, 0.26 * scale, 0.38, Enum.Material.ForceField, folder)
		local blastDome = makePart("CycloneFinalBlastDome", Enum.PartType.Ball, Vector3.new(4, 4, 4) * scale, CFrame.new(finPos + Vector3.new(0, 2.0 * scale, 0)), PALETTE.BloodFlame, 0.14, Enum.Material.ForceField, folder)
		TweenService:Create(blastDome, TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = Vector3.new(24, 24, 24) * scale,
			Transparency = 1,
		}):Play()
	end)

	local t0 = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function()
		local el = os.clock() - t0
		if el >= 0.78 or not folder.Parent then
			if conn then conn:Disconnect() end
			return
		end
		local u = el / 0.78
		local curRoot = actorChar and actorChar:FindFirstChild("HumanoidRootPart")
		local cPos = (curRoot and curRoot.Position) or centerPos
		local curG = Vector3.new(cPos.X, gPos.Y, cPos.Z)

		if coreFunnel.Parent then
			coreFunnel.CFrame = CFrame.new(curG + Vector3.new(0, funnelH * 0.5, 0)) * CFrame.Angles(0, el * 14, math.pi * 0.5)
			outerFunnel.CFrame = CFrame.new(curG + Vector3.new(0, funnelH * 0.5, 0)) * CFrame.Angles(0, -el * 10, math.pi * 0.5)
			if u > 0.65 then
				local f = (u - 0.65) / 0.35
				coreFunnel.Transparency = 0.10 + f * 0.90
				outerFunnel.Transparency = 0.22 + f * 0.78
			end
		end

		for _, b in ipairs(blades) do
			if b.Part and b.Part.Parent then
				local idx = b.Index
				local ang = el * 20 * ((idx % 2 == 0) and 1 or -1) + idx * 1.1
				local rad = (6.5 + idx * 2.8 + math.sin(el * 14 + idx) * 1.6) * scale * (1 + u * 0.38)
				local yOff = (-1.2 + idx * 2.05) * scale
				b.Part.Size = Vector3.new(0.26 * scale, rad, rad)
				b.Part.CFrame = CFrame.new(cPos + Vector3.new(math.cos(ang) * 0.85, yOff, math.sin(ang) * 0.85))
					* CFrame.Angles(math.sin(ang) * 0.20, ang, math.pi * 0.5)
				if u > 0.65 then
					b.Part.Transparency = 0.14 + ((u - 0.65) / 0.35) * 0.86
				end
			end
		end

		for _, ds in ipairs(dragonSpirits) do
			if ds.Node and ds.Node.Parent then
				local ang = el * 18 + ds.Phase
				local sRad = (5.2 + u * 4.5) * scale
				local sY = ((el * 26 + ds.Phase * 3) % funnelH)
				local p = curG + Vector3.new(math.cos(ang) * sRad, sY, math.sin(ang) * sRad)
				local tan = Vector3.new(-math.sin(ang), 0.45, math.cos(ang)).Unit
				ds.Node.CFrame = CFrame.lookAt(p, p + tan)
				if u > 0.70 then
					ds.Node.Transparency = (u - 0.70) / 0.30
				end
			end
		end
	end)

	if isLocal then
		emitCameraTrauma(0.42, 3.6)
	end
end

function DragonSovereignVFX.SpawnHybridWingDash(actorChar, startPos, endPos, lookDir, baseScale, isAwakened, isLocal)
	local anchors = DragonSovereignVFX.ResolveDragonStateAndAnchors(actorChar, startPos, lookDir)
	local scale = (baseScale or 1.0) * 1.12
	local p0 = anchors.CenterPos
	local rawVec = endPos - p0
	local dist = math.clamp(rawVec.Magnitude, 20 * scale, 36 * scale)
	local dir = (rawVec.Magnitude > 2) and rawVec.Unit or anchors.LookDir
	local p1 = p0 + dir * dist
	local dashCF = CFrame.lookAt(p0, p1)

	local folder = Instance.new("Folder")
	folder.Name = "DragonForm1_F_HybridWingDash"
	folder.Parent = (getTempFolder())
	Debris:AddItem(folder, 0.82)

	DragonSovereignVFX.EmitPrefab("Dragon_F_SoarRush", dashCF, scale)

	-- 3D Spectral Fire-Dragon Head Spearhead leading the Wing Dash!
	spawnSpectralDragonHeadConstruct(
		dashCF * CFrame.new(0, 0.4 * scale, -1.2 * scale),
		CFrame.lookAt(p1, p1 + dir * 5),
		1.35 * scale,
		PALETTE.BloodFlame,
		PALETTE.SolarGold,
		PALETTE.HotCore,
		0.34,
		folder,
		false
	)

	local stepCount = isLowFX() and 3 or 6
	for i = 1, stepCount do
		local frac = (i - 1) / math.max(1, stepCount - 1)
		task.delay((i - 1) * 0.025, function()
			if not folder.Parent then return end
			local pt = p0:Lerp(p1, frac)
			spawnShockRing(pt, CFrame.lookAt(pt, pt + dir), (i % 2 == 0) and PALETTE.SolarGold or PALETTE.BloodFlame, 2.2 * scale, 8.8 * scale, 0.22 * scale, 0.30, Enum.Material.ForceField, folder)
			for side = -1, 1, 2 do
				local wingSlash = makePart(
					"HybridWingAfterimage_" .. i .. "_" .. side,
					Enum.PartType.Wedge,
					Vector3.new(0.22 * scale, 1.65 * scale, 5.6 * scale),
					CFrame.lookAt(pt, pt + dir) * CFrame.new(side * 2.6 * scale, 0.5 * scale, 0) * CFrame.Angles(0, side * 0.55, side * 0.25),
					(i % 2 == 0) and PALETTE.SolarGold or PALETTE.BloodFlame,
					0.10,
					Enum.Material.ForceField,
					folder
				)
				TweenService:Create(wingSlash, TweenInfo.new(0.34, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					Size = Vector3.new(0.05, 0.4, 7.4 * scale),
					Transparency = 1,
				}):Play()
			end
			if i > 1 and not isLowFX() then
				local prevPt = p0:Lerp(p1, (i - 2) / math.max(1, stepCount - 1))
				spawnDraconicLightningArc(prevPt, pt + Vector3.new(0, (i % 2 == 0 and 1.2 or -1.2) * scale, 0), PALETTE.BloodFlame, PALETTE.SolarGold, 0.24 * scale, 4, 0.26, folder)
			end
		end)
	end
	if isLocal then
		emitCameraTrauma(0.28, 2.6, dir)
	end
end

function DragonSovereignVFX.SpawnSovereignSkyfallDive(actorChar, startPos, endPos, lookDir, baseScale, isAwakened, isLocal)
	local anchors = DragonSovereignVFX.ResolveDragonStateAndAnchors(actorChar, startPos, lookDir)
	local scale = (baseScale or 1.0) * 1.38
	local p0 = anchors.CenterPos
	local rawVec = endPos - p0
	local dist = math.clamp(rawVec.Magnitude, 20 * scale, 36 * scale)
	local dir = (rawVec.Magnitude > 2) and rawVec.Unit or anchors.LookDir
	local impactPos = findGroundPos(p0 + dir * dist, actorChar)
	local apexPos = p0 + dir * (dist * 0.35) + Vector3.new(0, 22 * scale, 0)

	local folder = Instance.new("Folder")
	folder.Name = "DragonForm2_X_SovereignSkyfallDive"
	folder.Parent = (getTempFolder())
	Debris:AddItem(folder, 1.55)

	-- Stage 1: Overhead Sovereign Runic Stargate + Target Ground Runic Seal + Colossal 3D Spectral Dragon Dive!
	spawnRunicMagicCircle(CFrame.new(apexPos), 12.5 * scale, PALETTE.AwakenedGold, PALETTE.Violet, 0.65, folder, 7.2)
	spawnRunicMagicCircle(CFrame.new(impactPos + Vector3.new(0, 0.20, 0)), 16.5 * scale, PALETTE.AwakenedGold, PALETTE.Crimson, 0.95, folder, -6.4)
	spawnShockRing(apexPos, nil, PALETTE.AwakenedGold, 2.8 * scale, 20 * scale, 0.34 * scale, 0.44, Enum.Material.ForceField, folder)

	local diveVec = impactPos - apexPos
	local diveLen = math.max(8, diveVec.Magnitude)
	local diveMid = (apexPos + impactPos) * 0.5
	local diveBeam = makePart("SovereignDiveLance", Enum.PartType.Cylinder, Vector3.new(diveLen, 4.4 * scale, 4.4 * scale), CFrame.lookAt(diveMid, impactPos) * CFrame.Angles(0, math.pi * 0.5, 0), PALETTE.Violet, 0.08, Enum.Material.ForceField, folder)
	local diveCrimson = makePart("SovereignDiveCrimson", Enum.PartType.Cylinder, Vector3.new(diveLen, 3.0 * scale, 3.0 * scale), diveBeam.CFrame, PALETTE.Crimson, 0.06, Enum.Material.ForceField, folder)
	local diveCore = makePart("SovereignDiveCore", Enum.PartType.Cylinder, Vector3.new(diveLen, 1.9 * scale, 1.9 * scale), diveBeam.CFrame, PALETTE.AwakenedGold, 0.02, Enum.Material.Neon, folder)
	TweenService:Create(diveBeam, TweenInfo.new(0.48, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = Vector3.new(diveLen, 0.2, 0.2), Transparency = 1 }):Play()
	TweenService:Create(diveCrimson, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = Vector3.new(diveLen, 0.15, 0.15), Transparency = 1 }):Play()
	TweenService:Create(diveCore, TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = Vector3.new(diveLen, 0.1, 0.1), Transparency = 1 }):Play()

	-- Colossal 3D Spectral Sovereign Dragon Skull diving down the Spear Lance!
	spawnSpectralDragonHeadConstruct(
		CFrame.lookAt(apexPos, impactPos),
		CFrame.lookAt(impactPos, impactPos + diveVec),
		2.25 * scale,
		PALETTE.Crimson,
		PALETTE.AwakenedGold,
		PALETTE.HotCore,
		0.32,
		folder,
		true
	)

	-- Stage 2: 4 Tectonic Sovereign Shockwaves, Void-Gold Pillars, 10 Erupting Monolith Spires & 10 Conqueror Lightning Bolts
	DragonSovereignVFX.EmitPrefab("Dragon_V_Ascension", CFrame.new(impactPos + Vector3.new(0, 1.0, 0)), scale * 1.25)
	makeSafeLight(makePart("SkyfallImpactLight", Enum.PartType.Ball, Vector3.new(3.2, 3.2, 3.2) * scale, CFrame.new(impactPos), PALETTE.AwakenedGold, 0.1, Enum.Material.ForceField, folder), PALETTE.Violet, 1.42, 16, 0.72)

	local spireTotal = isLowFX() and 5 or 10
	for s = 1, spireTotal do
		local sAng = (s - 1) * ((math.pi * 2) / spireTotal)
		local sPos = impactPos + Vector3.new(math.cos(sAng) * 8.2 * scale, -0.8, math.sin(sAng) * 8.2 * scale)
		local h = 9.2 * scale
		local monolith = makePart(
			"SkyfallMonolith_" .. s,
			Enum.PartType.Wedge,
			Vector3.new(1.6 * scale, h, 2.2 * scale),
			CFrame.lookAt(sPos, impactPos + Vector3.new(0, h, 0)) * CFrame.Angles(-0.32, 0, 0),
			(s % 3 == 0) and PALETTE.AwakenedGold or ((s % 2 == 0) and PALETTE.Violet or PALETTE.Crimson),
			0.06,
			Enum.Material.ForceField,
			folder
		)
		TweenService:Create(monolith, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			CFrame = monolith.CFrame * CFrame.new(0, h * 0.46, 0),
		}):Play()
		task.delay(0.48, function()
			if monolith.Parent then
				TweenService:Create(monolith, TweenInfo.new(0.28), { Transparency = 1 }):Play()
			end
		end)
	end

	if not isLowFX() then
		for b = 1, 10 do
			local bAng = (b - 1) * ((math.pi * 2) / 10)
			local bEnd = impactPos + Vector3.new(math.cos(bAng) * 15 * scale, (1.5 + (b % 3) * 4.2) * scale, math.sin(bAng) * 15 * scale)
			spawnDraconicLightningArc(impactPos + Vector3.new(0, 1.5 * scale, 0), bEnd, (b % 2 == 0) and PALETTE.Crimson or PALETTE.Violet, PALETTE.AwakenedGold, 0.36 * scale, 6, 0.38, folder)
		end
	end

	for wave = 1, 4 do
		task.delay((wave - 1) * 0.11, function()
			if not folder.Parent then return end
			local col = (wave == 2 or wave == 4) and PALETTE.AwakenedGold or ((wave == 1) and PALETTE.Violet or PALETTE.Crimson)
			spawnShockRing(impactPos + Vector3.new(0, 0.25, 0), nil, col, 3.0 * scale, (18 + wave * 6.5) * scale, 0.38 * scale, 0.52, Enum.Material.ForceField, folder)
			local pillar = makePart("SkyfallTectonicPillar_" .. wave, Enum.PartType.Cylinder, Vector3.new(25 * scale, (4.8 + wave * 1.8) * scale, (4.8 + wave * 1.8) * scale), CFrame.new(impactPos + Vector3.new(0, 12.5 * scale, 0)) * CFrame.Angles(0, 0, math.pi * 0.5), col, 0.14, Enum.Material.ForceField, folder)
			TweenService:Create(pillar, TweenInfo.new(0.48, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = Vector3.new(34 * scale, 0.4, 0.4),
				Transparency = 1,
			}):Play()
		end)
	end

	if isLocal then
		emitCameraTrauma(0.58, 5.6, dir)
	end
end

local DRAGON_CALLOUT_NAMES = {
	[1] = {
		Z = "Hỏa Long Liên Đạn • Fireball Volley",
		X = "Bán Long Đột Trảo • Hybrid Talon Rend",
		C = "Cuồng Long Lốc Xoáy • Inferno Vortex",
		V = "Hóa Hình Bán Long / Long Hoàng",
		F = "Long Ảnh Bộ • Hybrid Wing Dash",
	},
	[2] = {
		Z = "Thái Cổ Long Tức • Sovereign Breath",
		X = "Long Hoàng Giáng Thế • Skyfall Dive",
		C = "Vạn Long Thiên Hỏa Vũ • Eclipse Starshower",
		V = "Thu Hồi Long Hồn • Revert Form",
		F = "Long Vũ Cửu Thiên • Supersonic Flight",
	},
}

local function spawnDragonSkillCallout(pos, tier, key)
	if typeof(pos) ~= "Vector3" then return end
	local t = (tier and tier >= 2) and 2 or 1
	local title = (DRAGON_CALLOUT_NAMES[t] and DRAGON_CALLOUT_NAMES[t][key]) or ("Dragon [" .. tostring(key) .. "]")
	local col = (t == 2) and PALETTE.Violet or PALETTE.Crimson
	local folder, token = createMoveFolder("DragonCallout_" .. key, 1.05)
	local anchor = makePart("CalloutNode", Enum.PartType.Ball, Vector3.new(0.2, 0.2, 0.2), CFrame.new(pos + Vector3.new(0, (t == 2) and 9.5 or 4.8, 0)), col, 1, Enum.Material.SmoothPlastic, folder)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(320, 44)
	bb.StudsOffset = Vector3.new(0, 1.2, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 140
	bb.Parent = anchor

	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 0.78)
	bg.Position = UDim2.fromScale(0.5, 0.5)
	bg.AnchorPoint = Vector2.new(0.5, 0.5)
	bg.BackgroundColor3 = Color3.fromRGB(10, 12, 22)
	bg.BackgroundTransparency = 0.16
	bg.BorderSizePixel = 0
	bg.Parent = bb
	local cr = Instance.new("UICorner")
	cr.CornerRadius = UDim.new(0, 8)
	cr.Parent = bg
	local st = Instance.new("UIStroke")
	st.Color = col
	st.Thickness = 2
	st.Parent = bg

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -12, 1, 0)
	lbl.Position = UDim2.fromOffset(6, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextSize = 14
	lbl.TextColor3 = Color3.fromRGB(255, 245, 220)
	lbl.TextStrokeTransparency = 0.15
	lbl.Text = "[" .. tostring(key) .. "] " .. title
	lbl.Parent = bg

	TweenService:Create(bb, TweenInfo.new(0.95, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		StudsOffset = Vector3.new(0, 3.8, 0),
	}):Play()
	task.delay(0.55, function()
		if not isFolderAlive(folder, token) then return end
		TweenService:Create(bg, TweenInfo.new(0.38), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(st, TweenInfo.new(0.38), { Transparency = 1 }):Play()
		TweenService:Create(lbl, TweenInfo.new(0.38), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
	end)
end

-- ============================================================================
-- 9. UNIFIED DISPATCHER FOR ALL DRAGON MOVES & TRANSFORMATIONS
--    Routes to Form 1 (Hybrid) vs Form 2 (Sovereign) Skill Sets automatically!
-- ============================================================================
function DragonSovereignVFX.DispatchMove(moveKey, actorChar, startPos, endPos, lookDir, scale, isAwakened, isLocal, fx)
	local k = tostring(moveKey or "Z"):upper()
	local tier = tonumber(fx and fx.DragonFormTier)
	if not tier then
		local subMode = tostring(fx and fx.SubMode or "")
		if subMode == "AbyssalSovereign" then
			tier = 2
		elseif subMode == "AbyssalDragonHybrid" then
			tier = 1
		else
			local anchors = DragonSovereignVFX.ResolveDragonStateAndAnchors(actorChar, startPos, lookDir)
			tier = anchors.Tier
		end
	end

	pcall(spawnDragonSkillCallout, startPos, tier, k)

	local sc = math.clamp(scale or 1, 0.7, 2.2)
	local safeDir = (typeof(lookDir) == "Vector3" and lookDir.Magnitude > 0.05) and lookDir.Unit or Vector3.new(0, 0, -1)
	local dst = (typeof(endPos) == "Vector3" and (endPos - startPos).Magnitude > 4) and endPos or (startPos + safeDir * 28 * sc)
	local folder = getTempFolder()
	local cMain = ((tier or 0) >= 2) and PALETTE.Violet or PALETTE.Crimson
	local cSub = PALETTE.AwakenedGold

	if actorChar and (tier or 0) < 2 then
		Lib.PlaySkillCastPose(actorChar, k, 0.36)
		Lib.SpawnHandChargeIgnition(actorChar, k, cMain, cSub, 0.34, folder)
		if k == "X" or k == "C" or k == "V" or k == "F" then
			Lib.SpawnCharacterAfterimageBurst(actorChar, 3, cMain, 0.30, folder)
		end
	end
	Lib.SpawnFadeAtmosphericWindSmoke(startPos, 5.2 * sc, cMain, folder)
	Lib.PlayLayeredSkillAudio(startPos, dst, k, "Dragon")
	Lib.SpawnLingeringGroundAftermath(dst, 12.5 * sc, cMain, cSub, "Dragon", folder)

	if k == "V" then
		local vTier = tier
		if not vTier or vTier < 0 then
			local anchors = DragonSovereignVFX.ResolveDragonStateAndAnchors(actorChar, startPos, lookDir)
			vTier = (anchors.Tier > 0) and anchors.Tier or 1
		end
		Lib.SpawnFadeJaggedImpactSpikes(startPos, 20.0 * sc, isLowFX() and 6 or 12, cMain, cSub, 0.75, folder)
		if isLocal then
			Lib.TriggerAnimeImpactFrame(cMain, 0.050, 6.4, 0.68)
		end
		DragonSovereignVFX.SpawnTransformAscension(actorChar, startPos, vTier, isAwakened, isLocal)
		return
	end

	-- FADE / Haymaker Showcase Layering for Dragon Moves (Z / X / C / F)
	if k == "Z" then
		Lib.SpawnFadeCorkscrewTunnel(startPos + Vector3.new(0, 1.8 * sc, 0), dst + Vector3.new(0, 1.4 * sc, 0), 3.4 * sc, 6, cMain, cSub, 0.46, folder)
		Lib.SpawnFadeGroundSlashRibbon(startPos, dst, 2.4 * sc, cMain, cSub, 0.48, folder)
	elseif k == "X" then
		Lib.SpawnFadeCorkscrewTunnel(startPos + Vector3.new(0, 1.6 * sc, 0), dst + Vector3.new(0, 1.2 * sc, 0), 3.8 * sc, 7, cMain, cSub, 0.50, folder)
		Lib.SpawnFadeGroundSlashRibbon(startPos, dst, 2.8 * sc, cMain, cSub, 0.52, folder)
		if isLocal then Lib.TriggerAnimeImpactFrame(cMain, 0.036, 4.2, 0.46) end
	elseif k == "C" then
		Lib.SpawnFadeJaggedImpactSpikes(dst, 18.0 * sc, isLowFX() and 6 or 12, cMain, cSub, 0.68, folder)
		if isLocal then Lib.TriggerAnimeImpactFrame(cMain, 0.044, 5.2, 0.58) end
	elseif k == "F" then
		Lib.SpawnFadeGroundSlashRibbon(startPos, dst, 2.6 * sc, cMain, cSub, 0.46, folder)
		Lib.SpawnFadeCorkscrewTunnel(startPos + Vector3.new(0, 1.2 * sc, 0), dst + Vector3.new(0, 1.2 * sc, 0), 2.8 * sc, 5, cMain, cSub, 0.38, folder)
	end

	if (tier or 0) >= 2 then
		-- === FORM 2: CHÂN THÂN THÁI CỔ LONG HOÀNG (Sovereign Dragon Skill Set) ===
		if k == "Z" then
			DragonSovereignVFX.SpawnSovereignBreath(actorChar, startPos, endPos, lookDir, scale, true, isLocal)
		elseif k == "X" then
			DragonSovereignVFX.SpawnSovereignSkyfallDive(actorChar, startPos, endPos, lookDir, scale, true, isLocal)
		elseif k == "C" then
			DragonSovereignVFX.SpawnCataclysmicStarshower(actorChar, startPos, endPos, lookDir, scale, true, isLocal)
		elseif k == "F" then
			DragonSovereignVFX.SpawnSoaringRush(actorChar, startPos, endPos, lookDir, scale, true, isLocal)
		else
			DragonSovereignVFX.SpawnSovereignBreath(actorChar, startPos, endPos, lookDir, scale, true, isLocal)
		end
	else
		-- === FORM 1: BÁN LONG NHÂN / NHÂN DẠNG (Hybrid Dragon Skill Set) ===
		if k == "Z" then
			DragonSovereignVFX.SpawnHybridFireballVolley(actorChar, startPos, endPos, lookDir, scale, isAwakened, isLocal)
		elseif k == "X" then
			DragonSovereignVFX.SpawnVoidTalons(actorChar, startPos, endPos, lookDir, scale, isAwakened, isLocal)
		elseif k == "C" then
			DragonSovereignVFX.SpawnHybridInfernoCyclone(actorChar, startPos, endPos, lookDir, scale, isAwakened, isLocal)
		elseif k == "F" then
			DragonSovereignVFX.SpawnHybridWingDash(actorChar, startPos, endPos, lookDir, scale, isAwakened, isLocal)
		else
			DragonSovereignVFX.SpawnHybridFireballVolley(actorChar, startPos, endPos, lookDir, scale, isAwakened, isLocal)
		end
	end
end

return DragonSovereignVFX
