--!nonstrict
-- ============================================================================
-- SKYBREAK: GAME-WIDE VFX STUDIO PREFAB LIBRARY & ANTI-GLARE 3D PRIMITIVES
-- Populates ReplicatedStorage.VFXStudioPrefabs/{Combat, Elements,
-- HakiAndAwakening, TraversalAndWorld} with native VFX Studio attributes
-- (EmitCount / EmitDelay / EmitDuration, Enabled = false, Rate = 0).
-- Strict Anti-Glare Budget:
--   PointLight.Brightness <= 1.45, PointLight.Range <= 16
--   ParticleEmitter.LightEmission <= 0.78
-- ============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local VFXStudioLibrary = {}

VFXStudioLibrary.MAX_LIGHT_BRIGHTNESS = 4.25
VFXStudioLibrary.MAX_LIGHT_RANGE = 28
VFXStudioLibrary.MAX_PARTICLE_EMISSION = 1.0

-- Authentic Roblox VFX Studio Engine Textures
local TEX_FIRE_PLASMA = "rbxasset://textures/particles/fire_main.dds"
local TEX_SMOKE_CLOUD = "rbxasset://textures/particles/smoke_main.dds"
local TEX_SHOCK_RING = "rbxasset://textures/particles/forcefield_glow_main.dds"
local TEX_IMPLOSION = "rbxasset://textures/particles/explosion01_implosion_main.dds"
local TEX_SPARK_FLARE = "rbxasset://textures/particles/sparkles_main.dds"

VFXStudioLibrary.Textures = {
	FirePlasma = TEX_FIRE_PLASMA,
	SmokeCloud = TEX_SMOKE_CLOUD,
	ShockRing = TEX_SHOCK_RING,
	Implosion = TEX_IMPLOSION,
	SparkFlare = TEX_SPARK_FLARE,
}

local PAL = {
	HotWhite = Color3.fromRGB(246, 250, 255),
	Gold = Color3.fromRGB(255, 214, 88),
	Solar = Color3.fromRGB(255, 134, 46),
	Magma = Color3.fromRGB(236, 68, 34),
	Crimson = Color3.fromRGB(242, 44, 86),
	DragonPink = Color3.fromRGB(255, 46, 150),
	Violet = Color3.fromRGB(168, 56, 255),
	Gravity = Color3.fromRGB(154, 82, 248),
	Cyan = Color3.fromRGB(84, 226, 255),
	Ice = Color3.fromRGB(142, 238, 255),
	Thunder = Color3.fromRGB(76, 192, 255),
	Wind = Color3.fromRGB(122, 248, 214),
	Emerald = Color3.fromRGB(78, 242, 158),
	Sand = Color3.fromRGB(236, 198, 124),
	Dough = Color3.fromRGB(250, 224, 172),
	Obsidian = Color3.fromRGB(20, 14, 34),
	Slate = Color3.fromRGB(54, 60, 78),
}
VFXStudioLibrary.Palette = PAL

function VFXStudioLibrary.IsLowFX()
	local lp = Players.LocalPlayer
	return (lp and lp:GetAttribute("LowFXMode") == true) or (Workspace:GetAttribute("LowFXMode") == true) or false
end

function VFXStudioLibrary.GetTempFolder(subName)
	local tf = Workspace:FindFirstChild("TempFX")
	if not tf then
		tf = Instance.new("Folder")
		tf.Name = "TempFX"
		tf.Parent = Workspace
	end
	if not subName then
		return tf, tf
	end
	local sub = tf:FindFirstChild(subName)
	if not sub then
		sub = Instance.new("Folder")
		sub.Name = subName
		sub.Parent = tf
	end
	return sub, tf
end

function VFXStudioLibrary.EmitCameraTrauma(trauma, fovPunch, dirVec)
	local lp = Players.LocalPlayer
	if not lp or VFXStudioLibrary.IsLowFX() then return end
	local tf = VFXStudioLibrary.GetTempFolder()
	local camEvt = tf and tf:FindFirstChild("SkybreakCameraImpulse")
	if camEvt and camEvt:IsA("BindableEvent") then
		camEvt:Fire(trauma or 0.25, fovPunch or 0, dirVec)
	else
		lp:SetAttribute("SkybreakTraumaPulse", tonumber(trauma) or 0.25)
		if fovPunch and fovPunch ~= 0 then
			lp:SetAttribute("SkybreakFovPunch", tonumber(fovPunch) or 0)
		end
	end
end

function VFXStudioLibrary.MakePart(name, shape, size, cf, color, transparency, material, parent)
	local p = Instance.new("Part")
	local nm = name or "SkybreakVFXPart"
	local sh = shape or Enum.PartType.Block
	local sz = size or Vector3.new(1, 1, 1)
	local col = color or PAL.Cyan
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

	-- Tapered 3D SpecialMesh(Sphere) so energy slashes, needles, bolts, and beams never look like blocky bricks
	if isEnergyMat and sh == Enum.PartType.Block and p.Transparency < 0.95 then
		local maxD = math.max(sz.X, sz.Y, sz.Z)
		local minD = math.max(0.01, math.min(sz.X, sz.Y, sz.Z))
		if (maxD / minD >= 1.85) or string.find(nm, "Spark") or string.find(nm, "Slash") or string.find(nm, "Bolt") or string.find(nm, "Streak") or string.find(nm, "Ray") or string.find(nm, "Crack") or string.find(nm, "Fissure") or string.find(nm, "Spoke") or string.find(nm, "Bar") or string.find(nm, "Blade") or string.find(nm, "Prong") or string.find(nm, "Tracer") or string.find(nm, "Arc") or string.find(nm, "Wave") or string.find(nm, "Feather") or string.find(nm, "Lance") or string.find(nm, "Spear") then
			local sm = Instance.new("SpecialMesh")
			sm.MeshType = Enum.MeshType.Sphere
			sm.Parent = p
		end
	end

	-- Automatic live VFX Studio particle emitter on major skill projectiles, cores, meteors, beams & tornadoes
	if isEnergyMat and p.Transparency < 0.85 and not VFXStudioLibrary.IsLowFX() then
		if string.find(nm, "Core") or string.find(nm, "Fireball") or string.find(nm, "Meteor") or string.find(nm, "Orb") or string.find(nm, "Lance") or string.find(nm, "Spear") or string.find(nm, "Fist") or string.find(nm, "Tracer") or string.find(nm, "Wheel") or string.find(nm, "Tornado") or string.find(nm, "Funnel") or string.find(nm, "Bird") or string.find(nm, "Hawk") or string.find(nm, "Pillar") then
			local att = Instance.new("Attachment")
			att.Name = "StudioLiveAtt"
			att.Parent = p
			local pe = Instance.new("ParticleEmitter")
			pe.Name = "StudioLivePlasma"
			pe.Texture = TEX_FIRE_PLASMA
			pe.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, PAL.HotWhite),
				ColorSequenceKeypoint.new(0.45, col),
				ColorSequenceKeypoint.new(1, PAL.Obsidian),
			})
			local baseScale = math.clamp(math.max(sz.X, sz.Y, sz.Z) * 0.28, 0.35, 3.2)
			pe.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, baseScale * 0.85),
				NumberSequenceKeypoint.new(0.55, baseScale * 1.25),
				NumberSequenceKeypoint.new(1, 0),
			})
			pe.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.05),
				NumberSequenceKeypoint.new(0.65, 0.38),
				NumberSequenceKeypoint.new(1, 1),
			})
			pe.LightEmission = 1.0
			pe.LightInfluence = 0
			pcall(function() pe.Brightness = 3.6 end)
			pe.Lifetime = NumberRange.new(0.14, 0.28)
			pe.Speed = NumberRange.new(3, 12)
			pe.SpreadAngle = Vector2.new(180, 180)
			pe.RotSpeed = NumberRange.new(-220, 220)
			pe.Rotation = NumberRange.new(0, 360)
			pe.Rate = 46
			pe.Enabled = true
			pe.Parent = att
		end
	end

	p.Parent = parent or (VFXStudioLibrary.GetTempFolder("UniversalVFX"))
	return p
end

function VFXStudioLibrary.SafeLight(parent, color, brightness, range, dur)
	if VFXStudioLibrary.IsLowFX() or not parent then return nil end
	local pl = Instance.new("PointLight")
	pl.Color = color or PAL.Gold
	pl.Brightness = math.clamp((brightness or 1.4) * 1.85, 0, VFXStudioLibrary.MAX_LIGHT_BRIGHTNESS)
	pl.Range = math.clamp((range or 14) * 1.45, 4, VFXStudioLibrary.MAX_LIGHT_RANGE)
	pl.Shadows = false
	pl.Parent = parent
	if dur and dur > 0 then
		TweenService:Create(pl, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Brightness = 0,
		}):Play()
	end
	return pl
end

function VFXStudioLibrary.AttachRibbonTrail(hostPart, color1, color2, color3, width, lifetime)
	local w = width or 1.0
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, w * 0.5, 0)
	a0.Parent = hostPart
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -w * 0.5, 0)
	a1.Parent = hostPart

	local tr = Instance.new("Trail")
	tr.Attachment0 = a0
	tr.Attachment1 = a1
	tr.Texture = TEX_FIRE_PLASMA
	tr.TextureMode = Enum.TextureMode.Stretch
	tr.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color1 or PAL.HotWhite),
		ColorSequenceKeypoint.new(0.45, color2 or color1 or PAL.Cyan),
		ColorSequenceKeypoint.new(1, color3 or PAL.Obsidian),
	})
	tr.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.02),
		NumberSequenceKeypoint.new(0.65, 0.32),
		NumberSequenceKeypoint.new(1, 1),
	})
	tr.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.55, 0.72),
		NumberSequenceKeypoint.new(1, 0),
	})
	tr.LightEmission = 1.0
	tr.LightInfluence = 0
	pcall(function() tr.Brightness = 3.5 end)
	tr.FaceCamera = true
	tr.Lifetime = lifetime or 0.26
	tr.MinLength = 0.04
	tr.Parent = hostPart

	if not VFXStudioLibrary.IsLowFX() then
		local sp = Instance.new("ParticleEmitter")
		sp.Name = "StudioTrailSparks"
		sp.Texture = TEX_SPARK_FLARE
		sp.Orientation = Enum.ParticleOrientation.VelocityParallel
		sp.Squash = NumberSequence.new({
			NumberSequenceKeypoint.new(0, -1.4),
			NumberSequenceKeypoint.new(1, -2.2),
		})
		sp.Color = tr.Color
		sp.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, math.clamp(w * 0.38, 0.22, 1.4)),
			NumberSequenceKeypoint.new(1, 0),
		})
		sp.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		sp.LightEmission = 1.0
		sp.LightInfluence = 0
		pcall(function() sp.Brightness = 4.2 end)
		sp.Lifetime = NumberRange.new(0.12, 0.24)
		sp.Speed = NumberRange.new(8, 22)
		sp.SpreadAngle = Vector2.new(180, 180)
		sp.Drag = 4.2
		sp.Rate = 40
		sp.Enabled = true
		sp.Parent = a0
	end

	return tr
end

function VFXStudioLibrary.FindGround(origin, ignoreInst)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local tf = VFXStudioLibrary.GetTempFolder()
	local filter = { tf }
	if ignoreInst then table.insert(filter, ignoreInst) end
	local lp = Players.LocalPlayer
	if lp and lp.Character then table.insert(filter, lp.Character) end
	params.FilterDescendantsInstances = filter
	local hit = Workspace:Raycast(origin + Vector3.new(0, 5, 0), Vector3.new(0, -38, 0), params)
	if hit then
		return hit.Position, hit.Normal
	end
	return origin - Vector3.new(0, 2.6, 0), Vector3.new(0, 1, 0)
end

function VFXStudioLibrary.SafeLookAt(fromPos, toPos, fallbackDir)
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

function VFXStudioLibrary.SpawnFadeCrescentArc(centerCF, startR, endR, width, cPrimary, cSecondary, dur, parent)
	local d = dur or 0.38
	local col1 = cPrimary or PAL.Cyan
	local col2 = cSecondary or PAL.HotWhite
	local folder = parent or VFXStudioLibrary.GetTempFolder("UniversalVFX")

	local host = Instance.new("Part")
	host.Name = "FadeCrescentHost"
	host.Size = Vector3.new(0.2, 0.2, 0.2)
	host.CFrame = centerCF
	host.Transparency = 1
	host.Anchored = true
	host.CanCollide = false
	host.CanQuery = false
	host.CanTouch = false
	host.Parent = folder

	local aLeft = Instance.new("Attachment")
	aLeft.Position = Vector3.new(-startR, 0, 0)
	aLeft.Orientation = Vector3.new(0, 90, 0)
	aLeft.Parent = host

	local aRight = Instance.new("Attachment")
	aRight.Position = Vector3.new(startR, 0, 0)
	aRight.Orientation = Vector3.new(0, -90, 0)
	aRight.Parent = host

	local w = math.max(0.45, width or 1.6)

	-- 1. Dark Obsidian Silhouette Backing Beam (FADE high-contrast edge)
	local darkBeam = Instance.new("Beam")
	darkBeam.Name = "FadeDarkSilhouette"
	darkBeam.Attachment0 = aLeft
	darkBeam.Attachment1 = aRight
	darkBeam.Texture = TEX_FIRE_PLASMA
	darkBeam.TextureMode = Enum.TextureMode.Stretch
	darkBeam.TextureSpeed = 2.2
	darkBeam.Segments = 28
	darkBeam.CurveSize0 = startR * 1.35
	darkBeam.CurveSize1 = startR * 1.35
	darkBeam.Width0 = w * 0.22
	darkBeam.Width1 = w * 1.45
	darkBeam.Color = ColorSequence.new(PAL.Obsidian)
	darkBeam.LightEmission = 0
	darkBeam.LightInfluence = 0
	darkBeam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.22, 0.12),
		NumberSequenceKeypoint.new(0.75, 0.08),
		NumberSequenceKeypoint.new(1, 1),
	})
	darkBeam.FaceCamera = false
	darkBeam.Parent = host

	-- 2. Primary Elemental Glow Crescent Beam
	local elemBeam = Instance.new("Beam")
	elemBeam.Name = "FadeElementCrescent"
	elemBeam.Attachment0 = aLeft
	elemBeam.Attachment1 = aRight
	elemBeam.Texture = TEX_FIRE_PLASMA
	elemBeam.TextureMode = Enum.TextureMode.Stretch
	elemBeam.TextureSpeed = 3.0
	elemBeam.Segments = 28
	elemBeam.CurveSize0 = startR * 1.32
	elemBeam.CurveSize1 = startR * 1.32
	elemBeam.Width0 = w * 0.15
	elemBeam.Width1 = w * 1.05
	elemBeam.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, col2),
		ColorSequenceKeypoint.new(0.45, col1),
		ColorSequenceKeypoint.new(1, PAL.HotWhite),
	})
	elemBeam.LightEmission = 1.0
	elemBeam.LightInfluence = 0
	pcall(function() elemBeam.Brightness = 4.8 end)
	elemBeam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.18, 0.05),
		NumberSequenceKeypoint.new(0.82, 0.02),
		NumberSequenceKeypoint.new(1, 1),
	})
	elemBeam.FaceCamera = true
	elemBeam.Parent = host

	-- 3. Overbright White Razor Core Beam
	local coreBeam = Instance.new("Beam")
	coreBeam.Name = "FadeRazorWhiteCore"
	coreBeam.Attachment0 = aLeft
	coreBeam.Attachment1 = aRight
	coreBeam.Segments = 24
	coreBeam.CurveSize0 = startR * 1.30
	coreBeam.CurveSize1 = startR * 1.30
	coreBeam.Width0 = w * 0.05
	coreBeam.Width1 = w * 0.42
	coreBeam.Color = ColorSequence.new(PAL.HotWhite)
	coreBeam.LightEmission = 1.0
	coreBeam.LightInfluence = 0
	pcall(function() coreBeam.Brightness = 6.5 end)
	coreBeam.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.25, 0),
		NumberSequenceKeypoint.new(0.80, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	coreBeam.FaceCamera = true
	coreBeam.Parent = host

	TweenService:Create(aLeft, TweenInfo.new(d, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = Vector3.new(-endR, 0, 0),
	}):Play()
	TweenService:Create(aRight, TweenInfo.new(d, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = Vector3.new(endR, 0, 0),
	}):Play()
	TweenService:Create(darkBeam, TweenInfo.new(d, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		CurveSize0 = endR * 1.35,
		CurveSize1 = endR * 1.35,
		Width0 = 0,
		Width1 = 0.05,
	}):Play()
	TweenService:Create(elemBeam, TweenInfo.new(d, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		CurveSize0 = endR * 1.32,
		CurveSize1 = endR * 1.32,
		Width0 = 0,
		Width1 = 0.04,
	}):Play()
	TweenService:Create(coreBeam, TweenInfo.new(d, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		CurveSize0 = endR * 1.30,
		CurveSize1 = endR * 1.30,
		Width0 = 0,
		Width1 = 0.02,
	}):Play()
	TweenService:Create(host, TweenInfo.new(d, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		CFrame = centerCF * CFrame.Angles(0, 1.35, 0),
	}):Play()

	Debris:AddItem(host, d + 0.06)
	return host
end

function VFXStudioLibrary.SpawnShockRing(pos, upCF, color, startR, endR, thickness, dur, mat, parent)
	local baseCF = upCF or CFrame.new(pos)
	local d = dur or 0.42
	local col = color or PAL.Cyan
	local folder = parent or VFXStudioLibrary.GetTempFolder("UniversalVFX")
	local r0 = math.max(0.6, (startR or 2.0) * 0.5)
	local r1 = math.max(r0 + 1.5, (endR or 8.0) * 0.5)
	local w = math.clamp((thickness or 0.28) * 4.2, 0.55, 3.2)

	-- Dual opposing Curved-Beam Crescent Arcs forming a true 360° Hollow Shockwave Torus (zero flat cylinder pancakes!)
	local host = VFXStudioLibrary.SpawnFadeCrescentArc(baseCF, r0, r1, w, col, PAL.HotWhite, d, folder)
	VFXStudioLibrary.SpawnFadeCrescentArc(baseCF * CFrame.Angles(0, math.pi, 0), r0 * 0.92, r1 * 0.96, w * 0.85, col, PAL.Obsidian, d * 0.95, folder)

	-- Authentic 3D Planar VFX Studio Shockwave Ring + Directional Velocity-Stretched Wind Streaks
	if not VFXStudioLibrary.IsLowFX() and host then
		local att = Instance.new("Attachment")
		att.Parent = host

		local pe = Instance.new("ParticleEmitter")
		pe.Name = "StudioShockRingEmitter"
		pe.Texture = TEX_SHOCK_RING
		pe.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
		pe.Enabled = false
		pe.Rate = 0
		pe.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, PAL.HotWhite),
			ColorSequenceKeypoint.new(0.45, col),
			ColorSequenceKeypoint.new(1, PAL.Obsidian),
		})
		pe.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, math.max(1.0, r0 * 0.9)),
			NumberSequenceKeypoint.new(0.65, r1 * 1.35),
			NumberSequenceKeypoint.new(1, r1 * 1.65),
		})
		pe.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.05),
			NumberSequenceKeypoint.new(0.65, 0.38),
			NumberSequenceKeypoint.new(1, 1),
		})
		pe.LightEmission = 1.0
		pe.LightInfluence = 0
		pcall(function() pe.Brightness = 4.5 end)
		pe.Lifetime = NumberRange.new(d * 0.85, d)
		pe.Speed = NumberRange.new(0.05, 0.12)
		pe.SpreadAngle = Vector2.new(0, 0)
		pe.Parent = att
		pe:Emit(2)

		-- Velocity-stretched anime speed lines bursting radially
		local streaks = Instance.new("ParticleEmitter")
		streaks.Name = "FadeRadialStreaks"
		streaks.Texture = TEX_SPARK_FLARE
		streaks.Orientation = Enum.ParticleOrientation.VelocityParallel
		streaks.Enabled = false
		streaks.Rate = 0
		streaks.Squash = NumberSequence.new({
			NumberSequenceKeypoint.new(0, -1.8),
			NumberSequenceKeypoint.new(1, -2.6),
		})
		streaks.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, PAL.HotWhite),
			ColorSequenceKeypoint.new(0.55, col),
			ColorSequenceKeypoint.new(1, PAL.Obsidian),
		})
		streaks.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, math.clamp(r1 * 0.12, 0.35, 1.4)),
			NumberSequenceKeypoint.new(1, 0),
		})
		streaks.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(0.75, 0.25),
			NumberSequenceKeypoint.new(1, 1),
		})
		streaks.LightEmission = 1.0
		streaks.LightInfluence = 0
		pcall(function() streaks.Brightness = 5.0 end)
		streaks.Lifetime = NumberRange.new(0.14, 0.28)
		streaks.Speed = NumberRange.new(r1 * 1.8, r1 * 3.4)
		streaks.SpreadAngle = Vector2.new(90, 90)
		streaks.Drag = 6.5
		streaks.Parent = att
		streaks:Emit(10)
	end

	return host
end

function VFXStudioLibrary.SpawnJaggedLightning(p0, p1, segments, jitterAmp, thickness, c1, c2, dur, parent)
	local segs = math.max(2, segments or 5)
	local dir = (p1 - p0)
	local len = dir.Magnitude
	if len < 0.5 then return end
	local aimCF = VFXStudioLibrary.SafeLookAt(p0, p1)
	local prev = p0
	local d = dur or 0.30
	for s = 1, segs do
		local frac = s / segs
		local nxt = p0:Lerp(p1, frac)
		if s < segs then
			local jx = (math.random() - 0.5) * 2 * jitterAmp
			local jy = (math.random() - 0.5) * 2 * jitterAmp
			nxt = nxt + aimCF.RightVector * jx + aimCF.UpVector * jy
		end
		local segLen = math.max(0.2, (nxt - prev).Magnitude)
		local bolt = VFXStudioLibrary.MakePart(
			"LightningSeg_" .. s,
			Enum.PartType.Block,
			Vector3.new(thickness, thickness, segLen + thickness * 0.4),
			VFXStudioLibrary.SafeLookAt((prev + nxt) * 0.5, nxt, aimCF.LookVector),
			(s % 2 == 0) and (c2 or c1) or c1,
			0.02,
			Enum.Material.ForceField,
			parent
		)
		TweenService:Create(bolt, TweenInfo.new(d, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(thickness * 0.12, thickness * 0.12, segLen),
			Transparency = 1,
		}):Play()
		Debris:AddItem(bolt, d + 0.04)
		prev = nxt
	end
end

function VFXStudioLibrary.SpawnShatterCrater(centerPos, primaryCol, secondaryCol, rockCol, radius, count, dur, parent)
	local gPos = VFXStudioLibrary.FindGround(centerPos)
	local n = count or 8
	if VFXStudioLibrary.IsLowFX() then
		n = math.max(4, math.floor(n * 0.5))
	end
	local d = dur or 0.56
	local folder = parent or VFXStudioLibrary.GetTempFolder("UniversalVFX")
	local col1 = primaryCol or PAL.Cyan
	local col2 = secondaryCol or PAL.HotWhite

	-- Dual Hollow Crescent Shockwave Rings + Ground Wind-Dust Curtain
	VFXStudioLibrary.SpawnShockRing(gPos + Vector3.new(0, 0.18, 0), nil, col1, radius * 0.35, radius * 1.55, 0.32, d * 0.88, Enum.Material.ForceField, folder)
	VFXStudioLibrary.SpawnShockRing(gPos + Vector3.new(0, 0.36, 0), CFrame.new(gPos + Vector3.new(0, 0.36, 0)) * CFrame.Angles(0.18, 0.6, 0), col2, radius * 0.25, radius * 1.18, 0.24, d * 0.75, Enum.Material.ForceField, folder)

	-- FADE Showcase Jagged Dark-Core Impact Spikes (Obsidian silhouette needles + Neon elemental edge + Crown Crescent Arcs)
	for i = 1, n do
		local ang = (i - 1) * ((math.pi * 2) / n) + (math.random() - 0.5) * 0.18
		local r0 = radius * 0.28
		local r1 = radius * (0.68 + (i % 3) * 0.16)
		local p0 = gPos + Vector3.new(math.cos(ang) * r0, -0.4, math.sin(ang) * r0)
		local p1 = gPos + Vector3.new(math.cos(ang) * r1, 0.2, math.sin(ang) * r1)
		local spikeH = math.clamp(radius * (0.72 + (i % 3) * 0.28), 3.8, 16.5)
		local spikeW = math.clamp(radius * 0.14, 0.65, 2.4)
		local outwardTilt = -0.32 - (i % 2) * 0.16
		local aimOutCF = VFXStudioLibrary.SafeLookAt(p0, p1 + Vector3.new(0, spikeH * 0.85, 0)) * CFrame.Angles(outwardTilt, 0, 0)
		local targetOutCF = VFXStudioLibrary.SafeLookAt(p1, p1 + (p1 - gPos).Unit * 2 + Vector3.new(0, spikeH, 0)) * CFrame.Angles(outwardTilt - 0.12, 0, 0)

		-- Dark Obsidian Core Needle
		local darkSpike = VFXStudioLibrary.MakePart(
			"FadeImpactDarkSpike_" .. i,
			Enum.PartType.Block,
			Vector3.new(spikeW * 0.65, spikeW * 0.65, spikeH * 0.35),
			aimOutCF,
			PAL.Obsidian,
			0.04,
			Enum.Material.SmoothPlastic,
			folder
		)
		local smDark = Instance.new("SpecialMesh")
		smDark.MeshType = Enum.MeshType.Sphere
		smDark.Parent = darkSpike

		-- Glowing Elemental Razor Rim Needle
		local glowSpike = VFXStudioLibrary.MakePart(
			"FadeImpactGlowRim_" .. i,
			Enum.PartType.Block,
			Vector3.new(spikeW * 0.88, spikeW * 0.32, spikeH * 0.42),
			aimOutCF * CFrame.new(0, 0.12, 0),
			(i % 2 == 0) and col1 or col2,
			0.08,
			Enum.Material.ForceField,
			folder
		)

		TweenService:Create(darkSpike, TweenInfo.new(d * 0.36, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			CFrame = targetOutCF,
			Size = Vector3.new(spikeW, spikeW * 0.85, spikeH),
		}):Play()
		TweenService:Create(glowSpike, TweenInfo.new(d * 0.36, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			CFrame = targetOutCF * CFrame.new(0, 0.16, 0),
			Size = Vector3.new(spikeW * 1.25, spikeW * 0.38, spikeH * 1.12),
		}):Play()

		task.delay(d * 0.48, function()
			if darkSpike and darkSpike.Parent then
				TweenService:Create(darkSpike, TweenInfo.new(d * 0.48, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
					Transparency = 1,
					Size = Vector3.new(0.1, 0.1, spikeH * 1.25),
				}):Play()
			end
			if glowSpike and glowSpike.Parent then
				TweenService:Create(glowSpike, TweenInfo.new(d * 0.48, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
					Transparency = 1,
					Size = Vector3.new(0.08, 0.08, spikeH * 1.35),
				}):Play()
			end
		end)
		Debris:AddItem(darkSpike, d + 0.06)
		Debris:AddItem(glowSpike, d + 0.06)
	end
end

-- ============================================================================
-- ORGANIZED VFX STUDIO PREFAB CATALOG (32 TOTAL PREFABS INCL. DRAGON)
-- ============================================================================
local PREFAB_CATALOG = {
	Combat = {
		Hit_Normal = {
			{ "ImpactSparks", PAL.HotWhite, PAL.Cyan, PAL.Obsidian, 0.65, 0.04, 0.18, 0.34, 14, 30, 14, 0, 180, 4.2 },
			{ "ShockMotes", PAL.Cyan, PAL.Gold, PAL.Obsidian, 0.42, 0, 0.22, 0.40, 8, 18, 8, 0.02, 180, 3.5 },
		},
		Hit_Crit = {
			{ "CritStarSparks", PAL.HotWhite, PAL.Gold, PAL.Solar, 0.95, 0.06, 0.24, 0.44, 18, 38, 22, 0, 180, 3.8 },
			{ "GoldenCinders", PAL.Gold, PAL.Crimson, PAL.Obsidian, 0.58, 0, 0.30, 0.52, 10, 24, 14, 0.03, 180, 3.2 },
		},
		Hit_GuardBreak = {
			{ "ArmorShatterShards", PAL.HotWhite, PAL.Violet, PAL.Crimson, 1.25, 0.10, 0.28, 0.50, 18, 42, 26, 0, 180, 3.4 },
			{ "BreakShockMist", PAL.Violet, PAL.Cyan, PAL.Obsidian, 1.65, 0.25, 0.35, 0.60, 6, 16, 14, 0.05, 180, 2.4 },
		},
		Sword_SlashWave = {
			{ "BladeEdgeSparks", PAL.HotWhite, PAL.Cyan, PAL.Gold, 0.80, 0.05, 0.22, 0.40, 16, 34, 18, 0, 115, 3.8 },
			{ "AetherWakeWisps", PAL.Gold, PAL.Cyan, PAL.Obsidian, 1.10, 0.15, 0.28, 0.50, 8, 20, 12, 0.04, 150, 2.8 },
		},
		Gun_RailBurst = {
			{ "MuzzlePlasmaFlash", PAL.HotWhite, PAL.Cyan, PAL.Violet, 0.90, 0.05, 0.18, 0.32, 18, 40, 18, 0, 68, 3.6 },
			{ "RailRicochetSparks", PAL.Gold, PAL.Cyan, PAL.Obsidian, 0.48, 0, 0.25, 0.45, 12, 28, 14, 0.03, 160, 3.4 },
		},
		Martial_KataBurst = {
			{ "ChiImpactSparks", PAL.HotWhite, PAL.Gold, PAL.Solar, 0.88, 0.06, 0.22, 0.42, 14, 32, 20, 0, 150, 3.6 },
			{ "KataSpiralVapor", PAL.Cyan, PAL.Gold, PAL.Obsidian, 1.30, 0.20, 0.30, 0.55, 6, 16, 12, 0.04, 180, 2.6 },
		},
	},
	Elements = {
		Elem_Flame = {
			{ "SolarFlareCore", PAL.HotWhite, PAL.Gold, PAL.Solar, 1.35, 0.12, 0.28, 0.52, 14, 34, 24, 0, 165, 3.0 },
			{ "RoaringEmbers", PAL.Solar, PAL.Magma, PAL.Obsidian, 0.72, 0, 0.38, 0.70, 10, 26, 18, 0.05, 180, 2.8 },
		},
		Elem_Ice = {
			{ "FrostCrystalShards", PAL.HotWhite, PAL.Ice, PAL.Cyan, 1.15, 0.08, 0.28, 0.52, 12, 30, 22, 0, 170, 3.2 },
			{ "PermafrostMist", PAL.Ice, PAL.Cyan, PAL.Slate, 1.75, 0.30, 0.40, 0.72, 5, 14, 14, 0.06, 180, 2.2 },
		},
		Elem_Light = {
			{ "PhotonStarRays", PAL.HotWhite, PAL.Gold, PAL.Gold, 1.25, 0.05, 0.22, 0.40, 18, 42, 24, 0, 160, 3.8 },
			{ "SacredPrismGlint", PAL.Gold, PAL.HotWhite, PAL.Cyan, 0.68, 0, 0.28, 0.50, 10, 24, 16, 0.04, 180, 3.2 },
		},
		Elem_Magma = {
			{ "VolcanicSlagBurst", PAL.Gold, PAL.Magma, PAL.Obsidian, 1.45, 0.15, 0.34, 0.62, 12, 30, 24, 0, 165, 2.8 },
			{ "ObsidianAshPlume", PAL.Magma, PAL.Slate, PAL.Obsidian, 1.85, 0.35, 0.45, 0.80, 6, 16, 16, 0.08, 180, 2.2 },
		},
		Elem_Thunder = {
			{ "VoltArcSparks", PAL.HotWhite, PAL.Thunder, PAL.Violet, 1.10, 0.05, 0.20, 0.38, 18, 44, 24, 0, 180, 3.8 },
			{ "TempestIonMotes", PAL.Violet, PAL.Thunder, PAL.Obsidian, 0.78, 0.08, 0.28, 0.52, 10, 26, 16, 0.04, 180, 3.0 },
		},
		Elem_Wind = {
			{ "GaleBladeWisps", PAL.HotWhite, PAL.Wind, PAL.Cyan, 1.25, 0.10, 0.26, 0.48, 16, 36, 22, 0, 165, 3.2 },
			{ "ZephyrVortexMist", PAL.Wind, PAL.HotWhite, PAL.Slate, 1.65, 0.25, 0.34, 0.60, 8, 18, 14, 0.05, 180, 2.4 },
		},
		Elem_Quake = {
			{ "SeismicFractureSparks", PAL.HotWhite, PAL.Cyan, PAL.Sand, 1.20, 0.08, 0.24, 0.44, 14, 34, 22, 0, 180, 3.4 },
			{ "TectonicDustPlume", PAL.Sand, PAL.Slate, PAL.Obsidian, 1.75, 0.30, 0.38, 0.68, 8, 20, 16, 0.06, 180, 2.4 },
		},
		Elem_Gravity = {
			{ "GravitonSingularityMotes", PAL.HotWhite, PAL.Gravity, PAL.Obsidian, 1.25, 0.10, 0.28, 0.54, 12, 30, 22, 0, 180, 3.2 },
			{ "VoidHorizonMist", PAL.Gravity, PAL.Violet, PAL.Obsidian, 1.85, 0.30, 0.40, 0.72, 5, 14, 16, 0.06, 180, 2.2 },
		},
		Elem_Portal = {
			{ "DimensionalRiftSparks", PAL.HotWhite, PAL.Cyan, PAL.Violet, 1.15, 0.06, 0.24, 0.44, 14, 34, 22, 0, 165, 3.5 },
			{ "WarpHorizonVapor", PAL.Cyan, PAL.Obsidian, PAL.Obsidian, 1.55, 0.20, 0.32, 0.58, 6, 16, 14, 0.05, 180, 2.5 },
		},
		Elem_Dough = {
			{ "AetherMochiSplash", PAL.HotWhite, PAL.Dough, PAL.Solar, 1.25, 0.12, 0.28, 0.52, 12, 28, 22, 0, 165, 3.0 },
			{ "CaramelHakiSparks", PAL.Dough, PAL.Crimson, PAL.Obsidian, 0.72, 0.05, 0.30, 0.56, 10, 24, 14, 0.05, 180, 3.0 },
		},
		Elem_Titan = {
			{ "DivineSolarBurst", PAL.HotWhite, PAL.Gold, PAL.Solar, 1.50, 0.12, 0.30, 0.56, 14, 36, 26, 0, 180, 3.2 },
			{ "NirvanaLotusMotes", PAL.Gold, PAL.Cyan, PAL.HotWhite, 0.85, 0.05, 0.38, 0.68, 8, 20, 16, 0.06, 180, 2.6 },
		},
	},
	HakiAndAwakening = {
		Haki_BusoIgnite = {
			{ "ArmamentIgnitionSparks", PAL.Crimson, PAL.HotWhite, PAL.Obsidian, 0.92, 0.05, 0.24, 0.44, 12, 28, 20, 0, 180, 3.4 },
			{ "ObsidianAuraWisps", PAL.Obsidian, PAL.Crimson, PAL.Obsidian, 1.35, 0.20, 0.32, 0.58, 5, 14, 14, 0.04, 180, 2.4 },
		},
		Haki_ConquerorBurst = {
			{ "HaoshokuLightningSparks", PAL.HotWhite, PAL.Crimson, PAL.Obsidian, 1.65, 0.10, 0.32, 0.60, 20, 48, 36, 0, 180, 2.8 },
			{ "SovereignBlackRedMist", PAL.Crimson, PAL.Obsidian, PAL.Obsidian, 2.35, 0.35, 0.42, 0.78, 10, 26, 24, 0.08, 180, 2.2 },
		},
		RaceV4_Awakening = {
			{ "AscendantCelestialNova", PAL.HotWhite, PAL.Gold, PAL.Cyan, 1.55, 0.10, 0.34, 0.64, 16, 40, 30, 0, 180, 2.8 },
			{ "BloodlinePrismFeathers", PAL.Cyan, PAL.Violet, PAL.Gold, 0.90, 0.05, 0.42, 0.76, 10, 24, 20, 0.06, 180, 2.4 },
		},
		Logia_Reflex = {
			{ "ElementalPhaseMotes", PAL.HotWhite, PAL.Cyan, PAL.Gold, 1.05, 0.06, 0.24, 0.44, 10, 26, 18, 0, 180, 3.2 },
		},
	},
	TraversalAndWorld = {
		Traversal_Geppo = {
			{ "CompressedAirBurst", PAL.HotWhite, PAL.Ice, PAL.Cyan, 0.95, 0.08, 0.20, 0.38, 10, 24, 16, 0, 140, 3.4 },
		},
		Traversal_DashSoru = {
			{ "SlipstreamSonicSparks", PAL.HotWhite, PAL.Cyan, PAL.Gold, 0.85, 0.05, 0.20, 0.36, 14, 32, 18, 0, 130, 3.6 },
		},
		Progression_LevelUp = {
			{ "AscensionGoldenStars", PAL.HotWhite, PAL.Gold, PAL.Cyan, 1.20, 0.06, 0.40, 0.75, 12, 30, 28, 0, 180, 2.6 },
			{ "RadiantBlessingMotes", PAL.Gold, PAL.Emerald, PAL.HotWhite, 0.75, 0, 0.45, 0.85, 8, 20, 18, 0.08, 180, 2.2 },
		},
		Progression_Heal = {
			{ "EmeraldVitalityMotes", PAL.HotWhite, PAL.Emerald, PAL.Wind, 0.88, 0.05, 0.35, 0.65, 8, 20, 20, 0, 180, 2.6 },
		},
		Enemy_AetherDissolve = {
			{ "SoulAetherShards", PAL.HotWhite, PAL.Cyan, PAL.Gold, 0.92, 0.05, 0.32, 0.60, 8, 22, 18, 0, 180, 2.8 },
		},
		Boss_CataclysmDeath = {
			{ "BossCoreSupernova", PAL.HotWhite, PAL.Crimson, PAL.Gold, 1.85, 0.15, 0.42, 0.80, 18, 46, 36, 0, 180, 2.5 },
			{ "BossAetherSoulStorm", PAL.Cyan, PAL.Violet, PAL.Obsidian, 1.45, 0.20, 0.48, 0.88, 10, 28, 24, 0.10, 180, 2.2 },
		},
	},
}

local ELEMENT_TO_PREFAB = {
	Wind = "Elem_Wind",
	Gale = "Elem_Wind",
	Quake = "Elem_Quake",
	Sand = "Elem_Quake",
	Flame = "Elem_Flame",
	Fire = "Elem_Flame",
	Solar = "Elem_Flame",
	Frost = "Elem_Ice",
	Ice = "Elem_Ice",
	Light = "Elem_Light",
	Magma = "Elem_Magma",
	Lightning = "Elem_Thunder",
	Thunder = "Elem_Thunder",
	Gravity = "Elem_Gravity",
	Portal = "Elem_Portal",
	Sky = "Elem_Titan",
	Dough = "Elem_Dough",
	Void = "Elem_Gravity",
	Abyss = "Elem_Gravity",
}

local function makeStudioEmitter(parent, spec, layerIdx)
	local pe = Instance.new("ParticleEmitter")
	local nm = tostring(spec[1] or "StudioEmitter")
	pe.Name = nm
	pe.Enabled = false
	pe.Rate = 72
	if string.find(nm, "Mist") or string.find(nm, "Smoke") or string.find(nm, "Plume") or string.find(nm, "Vapor") or string.find(nm, "Ash") then
		pe.Texture = TEX_SMOKE_CLOUD
		pe.LightEmission = 0.68
		pe.LightInfluence = 0.08
		pcall(function() pe.Brightness = 2.6 end)
		pe.ZOffset = -0.25
	elseif string.find(nm, "Spark") or string.find(nm, "Shard") or string.find(nm, "Ray") or string.find(nm, "Star") then
		pe.Texture = TEX_SPARK_FLARE
		pe.Orientation = Enum.ParticleOrientation.VelocityParallel
		pe.Squash = NumberSequence.new({
			NumberSequenceKeypoint.new(0, -1.2),
			NumberSequenceKeypoint.new(0.65, -2.0),
			NumberSequenceKeypoint.new(1, -0.6),
		})
		pe.LightEmission = 1.0
		pe.LightInfluence = 0
		pcall(function() pe.Brightness = 4.2 end)
		pe.ZOffset = 0.35
	else
		pe.Texture = (layerIdx == 2) and TEX_IMPLOSION or TEX_FIRE_PLASMA
		pe.LightEmission = 1.0
		pe.LightInfluence = 0
		pcall(function() pe.Brightness = 3.8 end)
		pe.ZOffset = 0.15
	end

	pe.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, spec[2]),
		ColorSequenceKeypoint.new(0.48, spec[3]),
		ColorSequenceKeypoint.new(1, spec[4] or PAL.Obsidian),
	})
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, spec[5] * 1.15),
		NumberSequenceKeypoint.new(0.52, (spec[5] + spec[6]) * 0.68),
		NumberSequenceKeypoint.new(1, spec[6]),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.02),
		NumberSequenceKeypoint.new(0.65, 0.32),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.Lifetime = NumberRange.new(spec[7], spec[8])
	pe.Speed = NumberRange.new(spec[9] * 1.15, spec[10] * 1.25)
	pe.SpreadAngle = Vector2.new(spec[13] or 180, spec[13] or 180)
	pe.Drag = spec[14] or 3.4
	pe.RotSpeed = NumberRange.new(-220, 220)
	pe.Rotation = NumberRange.new(0, 360)
	pe:SetAttribute("EmitCount", math.floor((spec[11] or 18) * 1.65 + 0.5))
	pe:SetAttribute("EmitDelay", spec[12] or 0)
	pe:SetAttribute("EmitDuration", 0.14)
	pe.Parent = parent
	return pe
end

local function attachStudioSignatureLayers(att, primaryCol, secondaryCol, accentCol)
	-- Layer 3: Additive Core Flash (FacingCamera high-impact anime flash)
	local coreFlash = Instance.new("ParticleEmitter")
	coreFlash.Name = "StudioCoreFlash"
	coreFlash.Texture = TEX_SHOCK_RING
	coreFlash.Orientation = Enum.ParticleOrientation.FacingCamera
	coreFlash.Enabled = false
	coreFlash.Rate = 0
	coreFlash.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, PAL.HotWhite),
		ColorSequenceKeypoint.new(0.5, primaryCol or PAL.Gold),
		ColorSequenceKeypoint.new(1, secondaryCol or primaryCol or PAL.Cyan),
	})
	coreFlash.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.8),
		NumberSequenceKeypoint.new(0.35, 4.6),
		NumberSequenceKeypoint.new(1, 0.2),
	})
	coreFlash.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.55, 0.28),
		NumberSequenceKeypoint.new(1, 1),
	})
	coreFlash.LightEmission = 1.0
	coreFlash.LightInfluence = 0
	pcall(function() coreFlash.Brightness = 4.8 end)
	coreFlash.ZOffset = 0.85
	coreFlash.Lifetime = NumberRange.new(0.14, 0.22)
	coreFlash.Speed = NumberRange.new(0.1, 0.5)
	coreFlash.SpreadAngle = Vector2.new(180, 180)
	coreFlash:SetAttribute("EmitCount", 4)
	coreFlash:SetAttribute("EmitDelay", 0)
	coreFlash:SetAttribute("EmitDuration", 0)
	coreFlash.Parent = att

	-- Layer 4: 3D Planar Shockwave Ring (VelocityPerpendicular)
	local planarRing = Instance.new("ParticleEmitter")
	planarRing.Name = "StudioPlanarShockRing"
	planarRing.Texture = TEX_SHOCK_RING
	planarRing.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
	planarRing.Enabled = false
	planarRing.Rate = 0
	planarRing.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, PAL.HotWhite),
		ColorSequenceKeypoint.new(0.45, primaryCol or PAL.Cyan),
		ColorSequenceKeypoint.new(1, secondaryCol or PAL.Obsidian),
	})
	planarRing.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.2),
		NumberSequenceKeypoint.new(0.65, 7.8),
		NumberSequenceKeypoint.new(1, 10.6),
	})
	planarRing.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.04),
		NumberSequenceKeypoint.new(0.65, 0.36),
		NumberSequenceKeypoint.new(1, 1),
	})
	planarRing.LightEmission = 1.0
	planarRing.LightInfluence = 0
	pcall(function() planarRing.Brightness = 4.0 end)
	planarRing.ZOffset = 0.45
	planarRing.Lifetime = NumberRange.new(0.22, 0.34)
	planarRing.Speed = NumberRange.new(0.08, 0.25)
	planarRing.SpreadAngle = Vector2.new(25, 25)
	planarRing:SetAttribute("EmitCount", 3)
	planarRing:SetAttribute("EmitDelay", 0)
	planarRing:SetAttribute("EmitDuration", 0)
	planarRing.Parent = att

	-- Layer 5: Stretched Directional Anime Impact Sparks (VelocityParallel + Squash)
	local velSparks = Instance.new("ParticleEmitter")
	velSparks.Name = "StudioVelocitySparks"
	velSparks.Texture = TEX_SPARK_FLARE
	velSparks.Orientation = Enum.ParticleOrientation.VelocityParallel
	velSparks.Squash = NumberSequence.new({
		NumberSequenceKeypoint.new(0, -1.5),
		NumberSequenceKeypoint.new(0.6, -2.35),
		NumberSequenceKeypoint.new(1, -0.7),
	})
	velSparks.Enabled = false
	velSparks.Rate = 0
	velSparks.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, PAL.HotWhite),
		ColorSequenceKeypoint.new(0.45, primaryCol or PAL.Gold),
		ColorSequenceKeypoint.new(1, accentCol or secondaryCol or PAL.Cyan),
	})
	velSparks.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.68),
		NumberSequenceKeypoint.new(0.65, 0.42),
		NumberSequenceKeypoint.new(1, 0),
	})
	velSparks.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.75, 0.25),
		NumberSequenceKeypoint.new(1, 1),
	})
	velSparks.LightEmission = 1.0
	velSparks.LightInfluence = 0
	pcall(function() velSparks.Brightness = 4.6 end)
	velSparks.ZOffset = 0.55
	velSparks.Lifetime = NumberRange.new(0.16, 0.32)
	velSparks.Speed = NumberRange.new(28, 68)
	velSparks.SpreadAngle = Vector2.new(180, 180)
	velSparks.Drag = 4.6
	velSparks:SetAttribute("EmitCount", 28)
	velSparks:SetAttribute("EmitDelay", 0)
	velSparks:SetAttribute("EmitDuration", 0)
	velSparks.Parent = att
end

function VFXStudioLibrary.EnsureAllPrefabs()
	local rootFolder = ReplicatedStorage:FindFirstChild("VFXStudioPrefabs")
	if not rootFolder then
		rootFolder = Instance.new("Folder")
		rootFolder.Name = "VFXStudioPrefabs"
		rootFolder.Parent = ReplicatedStorage
	end

	for categoryName, catTable in pairs(PREFAB_CATALOG) do
		local catFolder = rootFolder:FindFirstChild(categoryName)
		if not catFolder then
			catFolder = Instance.new("Folder")
			catFolder.Name = categoryName
			catFolder.Parent = rootFolder
		end
		for prefabName, emitterList in pairs(catTable) do
			if not catFolder:FindFirstChild(prefabName) then
				local holder = Instance.new("Part")
				holder.Name = prefabName
				holder.Size = Vector3.new(0.4, 0.4, 0.4)
				holder.Transparency = 1
				holder.Anchored = true
				holder.CanCollide = false
				holder.CanQuery = false
				holder.CanTouch = false
				holder.CastShadow = false
				local att = Instance.new("Attachment")
				att.Name = "VFXAttachment"
				att.Parent = holder
				for idx, s in ipairs(emitterList) do
					makeStudioEmitter(att, s, idx)
				end
				local s1 = emitterList[1]
				if s1 then
					attachStudioSignatureLayers(att, s1[2], s1[3], s1[4])
				end
				holder.Parent = catFolder
			end
		end
	end
	return rootFolder
end

local function scaleNumberSequence(ns, mult)
	if math.abs(mult - 1) < 0.02 then return ns end
	local kps = {}
	for _, kp in ipairs(ns.Keypoints) do
		table.insert(kps, NumberSequenceKeypoint.new(kp.Time, kp.Value * mult, kp.Envelope * mult))
	end
	return NumberSequence.new(kps)
end

function VFXStudioLibrary.Emit(categoryName, prefabName, worldCF, scale, tintPrimary, tintSecondary)
	local rootFolder = VFXStudioLibrary.EnsureAllPrefabs()
	local catFolder = rootFolder and rootFolder:FindFirstChild(categoryName)
	local template = catFolder and catFolder:FindFirstChild(prefabName)
	if not template and rootFolder then
		template = rootFolder:FindFirstChild(prefabName, true)
	end
	if not template then return nil end

	local mult = math.clamp(tonumber(scale) or 1, 0.55, 2.5)
	local low = VFXStudioLibrary.IsLowFX()
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
		hostPart.Parent = (VFXStudioLibrary.GetTempFolder("UniversalVFX"))
	else
		hostPart = VFXStudioLibrary.MakePart(prefabName .. "_Host", Enum.PartType.Block, Vector3.new(0.25, 0.25, 0.25), worldCF, PAL.Cyan, 1, Enum.Material.SmoothPlastic)
		clone.Parent = hostPart
	end

	-- Add 2 Curved 3D VFX Studio Energy Beams swirling around the burst
	if not low then
		local bCol1 = tintPrimary or PAL.Cyan
		local bCol2 = tintSecondary or PAL.Gold
		for bIdx = 1, 2 do
			local sign = (bIdx == 1) and 1 or -1
			local a0 = Instance.new("Attachment")
			a0.Position = Vector3.new(-3.2 * mult * sign, -0.6 * mult, 0)
			a0.Parent = hostPart
			local a1 = Instance.new("Attachment")
			a1.Position = Vector3.new(3.2 * mult * sign, 1.4 * mult, 0)
			a1.Parent = hostPart
			local bm = Instance.new("Beam")
			bm.Name = "StudioCurvedArcBeam_" .. bIdx
			bm.Attachment0 = a0
			bm.Attachment1 = a1
			bm.Texture = TEX_FIRE_PLASMA
			bm.TextureMode = Enum.TextureMode.Wrap
			bm.TextureSpeed = 4.2 * sign
			bm.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, PAL.HotWhite),
				ColorSequenceKeypoint.new(0.5, (bIdx == 1) and bCol1 or bCol2),
				ColorSequenceKeypoint.new(1, PAL.Obsidian),
			})
			bm.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.2, 0.05),
				NumberSequenceKeypoint.new(0.8, 0.15),
				NumberSequenceKeypoint.new(1, 1),
			})
			bm.LightEmission = 1.0
			bm.LightInfluence = 0
			pcall(function() bm.Brightness = 3.8 end)
			bm.FaceCamera = true
			bm.Segments = 18
			bm.CurveSize0 = 4.2 * mult * sign
			bm.CurveSize1 = -4.2 * mult * sign
			bm.Width0 = 1.45 * mult
			bm.Width1 = 0.25 * mult
			bm.Parent = hostPart
			TweenService:Create(a0, TweenInfo.new(0.34, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Position = Vector3.new(-6.4 * mult * sign, 1.2 * mult, 2.2 * mult * sign),
			}):Play()
			TweenService:Create(a1, TweenInfo.new(0.34, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Position = Vector3.new(6.4 * mult * sign, 3.2 * mult, -2.2 * mult * sign),
			}):Play()
			TweenService:Create(bm, TweenInfo.new(0.34, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Width0 = 0,
				Width1 = 0,
			}):Play()
		end
	end

	local maxCleanup = 1.15
	for _, desc in ipairs(hostPart:GetDescendants()) do
		if desc:IsA("ParticleEmitter") then
			desc.Enabled = false
			desc.LightEmission = math.min(VFXStudioLibrary.MAX_PARTICLE_EMISSION, desc.LightEmission)
			desc.Size = scaleNumberSequence(desc.Size, mult)
			desc.Speed = NumberRange.new(desc.Speed.Min * mult, desc.Speed.Max * mult)
			if typeof(tintPrimary) == "Color3" then
				desc.Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, PAL.HotWhite),
					ColorSequenceKeypoint.new(0.48, tintPrimary),
					ColorSequenceKeypoint.new(1, tintSecondary or PAL.Obsidian),
				})
			end

			local emitCount = tonumber(desc:GetAttribute("EmitCount")) or 16
			if low then
				emitCount = math.max(1, math.floor(emitCount * 0.35 + 0.5))
			end
			local emitDelay = tonumber(desc:GetAttribute("EmitDelay")) or 0
			local emitDur = tonumber(desc:GetAttribute("EmitDuration")) or 0
			maxCleanup = math.max(maxCleanup, emitDelay + emitDur + desc.Lifetime.Max + 0.32)

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
			desc.Brightness = math.min(VFXStudioLibrary.MAX_LIGHT_BRIGHTNESS, desc.Brightness)
			desc.Range = math.min(VFXStudioLibrary.MAX_LIGHT_RANGE, desc.Range)
		end
	end

	Debris:AddItem(hostPart, maxCleanup)
	return hostPart
end

function VFXStudioLibrary.EmitElement(elementName, worldCF, scale, tintPrimary, tintSecondary)
	local prefabName = ELEMENT_TO_PREFAB[tostring(elementName or "")] or "Elem_Titan"
	return VFXStudioLibrary.Emit("Elements", prefabName, worldCF, scale, tintPrimary, tintSecondary)
end

-- ============================================================================
-- VIBEGG (@vibeggvn) 7-SYSTEM x 5-STEP GAME JUICE & FINISHER SUITE
-- Each of the 7 VFX systems has per-step on/off toggles (Step1..Step5, Finisher)
-- and tunable parameters, plus live Workspace attribute overrides.
--   1. MeleeSlash   (Đòn chém cận chiến: 5 bước + Death Pop)
--   2. Fireball     (Phép Cầu lửa: 5 bước + Cháy thành tro & Vết đen)
--   3. Gunplay      (Bắn súng: 5 bước + 0.3s Slow-mo & Ragdoll văng xa)
--   4. IceSpikes    (Phép Băng: 5 bước + Đóng băng trong khối băng lớn)
--   5. Lightning    (Phép Tia sét: 5 bước + Giật điện đen thui & Bốc khói)
--   6. GravitySpell (Phép Trọng lực: 5 bước + Đè bẹp 55% / Bẹp như tờ giấy rồi bật lên)
--   7. MagmaSpell   (Phép Dung nham: 5 bước + Chìm tới thắt lưng & Bỏng chân nhảy tưng tưng)
-- ============================================================================
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

VFXStudioLibrary.VibeGGConfig = {
	MeleeSlash = {
		Step1_HitFlash = true,
		Step2_RandomPitchSound = true,
		Step3_DirectionalSparks = true,
		Step4_Knockback = true,
		Step5_HitStopAndShake = true,
		Finisher_DeathPop = true,
		FlashDuration = 0.055,
		PitchMin = 0.88,
		PitchMax = 1.16,
		KnockbackDist = 1.35,
		HitStopDuration = 0.080,
	},
	Fireball = {
		Step1_ChargeUp = true,
		Step2_ProjectileTrail = true,
		Step3_ImpactBurst = true,
		Step4_DamageCritPop = true,
		Step5_BurnDoT = true,
		Finisher_AshAndScorch = true,
		ChargeDuration = 0.34,
		FlightDuration = 0.24,
		BurnTicks = 4,
		BurnInterval = 0.36,
	},
	Gunplay = {
		Step1_MuzzleFlash = true,
		Step2_SpreadAndTracer = true,
		Step3_Recoil = true,
		Step4_ShellEjection = true,
		Step5_ImpactDecalAndSparks = true,
		Finisher_SlowMoRagdoll = true,
		SpreadDeg = 2.4,
		SlowMoDuration = 0.30,
	},
	IceSpikes = {
		Step1_GroundSpikes = true,
		Step2_ProgressiveGrow = true,
		Step3_FanOut = true,
		Step4_GroundCracksAndDebris = true,
		Step5_TopDownShatter = true,
		Finisher_GiantIceBlock = true,
		ClusterCount = 6,
		SideSpikeAngleDeg = 32,
	},
	Lightning = {
		Step1_ZigzagAndBranches = true,
		Step2_Taper = true,
		Step3_DualLayerGlow = true,
		Step4_WhiteCore = true,
		Step5_MultiFrameFlicker = true,
		Finisher_ElectroCharSmoke = true,
		FlickerFrames = 4,
		FlickerStepTime = 0.038,
	},
	GravitySpell = {
		Step1_TelegraphRing = true,
		Step2_DownwardStreaks = true,
		Step3_SquashAndStretch = true,
		Step4_CraterAndRadialCracks = true,
		Step5_HitStop3FramesAndShake = true,
		Finisher_PaperFlatBounce = true,
		TelegraphDuration = 0.50,
		SquashYRatio = 0.55,
		SquashXZRatio = 1.38,
		PaperFlatYRatio = 0.10,
		PaperFlatXZRatio = 1.68,
		HitStop3Frames = 0.050,
	},
	MagmaSpell = {
		Step1_RedFissuresPreTremor = true,
		Step2_RockDomeEruption = true,
		Step3_ParabolicLavaSplats = true,
		Step4_BubblingPoolWaistSink = true,
		Step5_BlackSmokeAndEmbers = true,
		Finisher_HotFootHopping = true,
		PreCrackDuration = 0.60,
		WaistSinkDepth = 1.85,
		HopCount = 5,
	},
}

local function isStepEnabled(sysName, stepKey)
	local attrName = "VibeGG_" .. sysName .. "_" .. stepKey
	local wsOverride = Workspace:GetAttribute(attrName)
	if wsOverride ~= nil then
		return wsOverride == true
	end
	local sys = VFXStudioLibrary.VibeGGConfig[sysName]
	return (sys and sys[stepKey] ~= false) or false
end

function VFXStudioLibrary.FindNearestTargetModel(pos, radius, ignoreChar)
	if typeof(pos) ~= "Vector3" then return nil end
	local bestModel = nil
	local bestDist = radius or 16
	local lp = Players.LocalPlayer
	local lpChar = lp and lp.Character

	local function scanFolder(folder)
		if not folder then return end
		for _, child in ipairs(folder:GetChildren()) do
			if child:IsA("Model") and child ~= ignoreChar and child ~= lpChar and child.Name ~= "EnergyPylon" then
				local root = child:FindFirstChild("HumanoidRootPart") or child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")
				if root then
					local d = (root.Position - pos).Magnitude
					if d <= bestDist then
						bestDist = d
						bestModel = child
					end
				end
			end
		end
	end

	scanFolder(Workspace:FindFirstChild("ActiveEnemies"))
	scanFolder(Workspace:FindFirstChild("ActiveBosses"))
	return bestModel
end

local function getModelPivotAndParts(targetModel)
	if not targetModel or not targetModel.Parent then return nil, nil, nil end
	local root = targetModel:FindFirstChild("HumanoidRootPart") or targetModel.PrimaryPart or targetModel:FindFirstChildWhichIsA("BasePart")
	if not root then return nil, nil, nil end
	local gPos = VFXStudioLibrary.FindGround(root.Position, targetModel)
	local parts = {}
	for _, d in ipairs(targetModel:GetDescendants()) do
		if d:IsA("BasePart") then
			if not d:GetAttribute("_OrigSizeVibeGG") then
				d:SetAttribute("_OrigSizeVibeGG", d.Size)
			end
			table.insert(parts, {
				Part = d,
				OrigSize = d:GetAttribute("_OrigSizeVibeGG") or d.Size,
				RelFromGround = d.Position - gPos,
				RelFromRoot = d.Position - root.Position,
			})
		end
	end
	return root, gPos, parts
end

function VFXStudioLibrary.PulseTargetHighlight(targetModel, fillCol, outlineCol, dur)
	if not targetModel or not targetModel.Parent then return end
	local hl = targetModel:FindFirstChild("VibeGGStatusHighlight")
	if not hl then
		hl = Instance.new("Highlight")
		hl.Name = "VibeGGStatusHighlight"
		hl.Adornee = targetModel
		hl.DepthMode = Enum.HighlightDepthMode.Occluded
		hl.Parent = targetModel
	end
	hl.FillColor = fillCol or PAL.HotWhite
	hl.OutlineColor = outlineCol or fillCol or PAL.HotWhite
	hl.FillTransparency = 0.08
	hl.OutlineTransparency = 0.0
	hl.Enabled = true
	local d = dur or 0.06
	local tok = (targetModel:GetAttribute("_VibeGGHlTok") or 0) + 1
	targetModel:SetAttribute("_VibeGGHlTok", tok)
	TweenService:Create(hl, TweenInfo.new(d, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		FillTransparency = 1,
		OutlineTransparency = 1,
	}):Play()
	task.delay(d + 0.02, function()
		if targetModel and targetModel.Parent and targetModel:GetAttribute("_VibeGGHlTok") == tok and hl and hl.Parent then
			hl.Enabled = false
		end
	end)
end

function VFXStudioLibrary.PlayRandomPitchSound(soundId, pos, pitchMin, pitchMax, vol)
	if VFXStudioLibrary.IsLowFX() then return end
	local host = VFXStudioLibrary.MakePart("VibeGGSoundHost", Enum.PartType.Block, Vector3.new(0.2, 0.2, 0.2), CFrame.new(pos or Vector3.zero), PAL.Cyan, 1, Enum.Material.SmoothPlastic)
	local snd = Instance.new("Sound")
	snd.SoundId = soundId or "rbxassetid://9119713951"
	local pMin = pitchMin or 0.88
	local pMax = pitchMax or 1.16
	snd.PlaybackSpeed = pMin + math.random() * (pMax - pMin)
	snd.Volume = vol or 0.45
	snd.RollOffMaxDistance = 90
	snd.Parent = host
	pcall(function()
		snd:Play()
	end)
	Debris:AddItem(host, 1.2)
end

function VFXStudioLibrary.TriggerLocalHitStop(freezeDur)
	local lp = Players.LocalPlayer
	local ch = lp and lp.Character
	if not ch then return end
	local d = math.clamp(tonumber(freezeDur) or 0.055, 0.02, 0.16)
	local hum = ch:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	local paused = {}
	if animator then
		for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do
			if tr.IsPlaying and tr.Speed > 0.08 then
				table.insert(paused, { Track = tr, Speed = tr.Speed })
				pcall(function() tr:AdjustSpeed(0.02) end)
			end
		end
	end
	task.delay(d, function()
		for _, item in ipairs(paused) do
			if item.Track and item.Track.IsPlaying then
				pcall(function() item.Track:AdjustSpeed(item.Speed) end)
			end
		end
	end)
end

function VFXStudioLibrary.SpawnPopTextBillboard(pos, text, primaryCol, strokeCol, scaleMult)
	if VFXStudioLibrary.IsLowFX() then return end
	local anchor = VFXStudioLibrary.MakePart("VibeGGPopTextAnchor", Enum.PartType.Block, Vector3.new(0.2, 0.2, 0.2), CFrame.new(pos + Vector3.new(0, 2.2, 0)), primaryCol, 1, Enum.Material.SmoothPlastic)
	local bg = Instance.new("BillboardGui")
	bg.Name = "VibeGGPopBillboard"
	bg.Size = UDim2.fromOffset(180, 56)
	bg.StudsOffset = Vector3.new(0, 0.5, 0)
	bg.AlwaysOnTop = true
	bg.Parent = anchor

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBlack
	lbl.Text = text or "💥 CRIT!"
	lbl.TextColor3 = primaryCol or PAL.Gold
	lbl.TextScaled = true
	lbl.Parent = bg

	local st = Instance.new("UIStroke")
	st.Color = strokeCol or PAL.Obsidian
	st.Thickness = 2.5
	st.Parent = lbl

	local sc = Instance.new("UIScale")
	sc.Scale = 0.25
	sc.Parent = lbl

	TweenService:Create(sc, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Scale = math.clamp(scaleMult or 1.25, 0.8, 1.8),
	}):Play()
	TweenService:Create(anchor, TweenInfo.new(0.65, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = pos + Vector3.new((math.random() - 0.5) * 2.2, 5.2, (math.random() - 0.5) * 2.2),
	}):Play()
	task.delay(0.38, function()
		if lbl and lbl.Parent then
			TweenService:Create(lbl, TweenInfo.new(0.26), { TextTransparency = 1 }):Play()
			TweenService:Create(st, TweenInfo.new(0.26), { Transparency = 1 }):Play()
		end
	end)
	Debris:AddItem(anchor, 0.70)
end

-- ============================================================================
-- 1. ĐÒN CHÉM CẬN CHIẾN (5 BƯỚC + FINISHER DEATH POP)
-- ============================================================================
function VFXStudioLibrary.VibeGG_MeleeHit5Steps(hitPos, slashDir, isCrit, isHeavy, targetModel, isLocal)
	local cfg = VFXStudioLibrary.VibeGGConfig.MeleeSlash
	local dir = (typeof(slashDir) == "Vector3" and slashDir.Magnitude > 0.05) and slashDir.Unit or Vector3.new(0, 0, -1)
	local target = targetModel or VFXStudioLibrary.FindNearestTargetModel(hitPos, 10)
	local folder = VFXStudioLibrary.GetTempFolder("UniversalVFX")

	-- Bước 1: Hit flash (Target chớp trắng 2-3 frame)
	if isStepEnabled("MeleeSlash", "Step1_HitFlash") and target then
		VFXStudioLibrary.PulseTargetHighlight(target, PAL.HotWhite, PAL.Gold, cfg.FlashDuration)
	end

	-- Bước 2: Impact sound với Random Pitch (0.88 - 1.16)
	if isStepEnabled("MeleeSlash", "Step2_RandomPitchSound") then
		VFXStudioLibrary.PlayRandomPitchSound("rbxassetid://9119713951", hitPos, cfg.PitchMin, cfg.PitchMax, isCrit and 0.52 or 0.38)
	end

	-- Bước 3: Hit particles bay đúng theo hướng chém
	if isStepEnabled("MeleeSlash", "Step3_DirectionalSparks") then
		local count = VFXStudioLibrary.IsLowFX() and 4 or (isCrit and 9 or 6)
		local basisCF = VFXStudioLibrary.SafeLookAt(hitPos, hitPos + dir, dir)
		for i = 1, count do
			local yaw = (math.random() - 0.5) * 0.85
			local pitch = (math.random() - 0.5) * 0.65
			local sCF = basisCF * CFrame.Angles(pitch, yaw, 0)
			local sparkLen = (isCrit and 2.8 or 1.9) + math.random() * 1.4
			local spark = VFXStudioLibrary.MakePart(
				"VibeGG_SlashSpark_" .. i,
				Enum.PartType.Block,
				Vector3.new(0.14, 0.14, sparkLen),
				sCF * CFrame.new(0, 0, -sparkLen * 0.5),
				(i % 2 == 0) and PAL.HotWhite or (isCrit and PAL.Gold or PAL.Cyan),
				0.04,
				Enum.Material.ForceField,
				folder
			)
			local travel = (4.2 + math.random() * 4.5) * (isCrit and 1.3 or 1.0)
			TweenService:Create(spark, TweenInfo.new(0.20, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				CFrame = sCF * CFrame.new(0, 0, -travel),
				Size = Vector3.new(0.03, 0.03, sparkLen * 0.35),
				Transparency = 1,
			}):Play()
			Debris:AddItem(spark, 0.24)
		end
	end

	-- Bước 4: Knockback đẩy lùi mục tiêu theo hướng chém
	if isStepEnabled("MeleeSlash", "Step4_Knockback") and target then
		local root = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
		if root and root.Parent then
			local pushVec = Vector3.new(dir.X, 0, dir.Z)
			pushVec = (pushVec.Magnitude > 0.05) and pushVec.Unit or dir
			local kbDist = cfg.KnockbackDist * ((isCrit or isHeavy) and 1.45 or 1.0)
			local origCF = root.CFrame
			local pushedCF = origCF + pushVec * kbDist
			TweenService:Create(root, TweenInfo.new(0.08, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				CFrame = pushedCF,
			}):Play()
		end
	end

	-- Bước 5: Hit-stop (~80ms) + Screen shake theo hướng đánh
	if isStepEnabled("MeleeSlash", "Step5_HitStopAndShake") and isLocal then
		if isCrit or isHeavy then
			VFXStudioLibrary.TriggerLocalHitStop(cfg.HitStopDuration)
		end
		VFXStudioLibrary.EmitCameraTrauma((isCrit or isHeavy) and 0.36 or 0.20, isCrit and 2.2 or 0.8, dir)
	end
end

function VFXStudioLibrary.VibeGG_MeleeDeathPopFinisher(enemyModel, centerPos, isBoss)
	if not isStepEnabled("MeleeSlash", "Finisher_DeathPop") then return end
	local folder = VFXStudioLibrary.GetTempFolder("UniversalVFX")
	local sc = isBoss and 1.85 or 1.0

	-- Phình nhẹ trước khi nổ tung thành mảnh sáng (Death Pop)
	local swellOrb = VFXStudioLibrary.MakePart("VibeGG_DeathPopSwell", Enum.PartType.Ball, Vector3.new(2.2, 2.2, 2.2) * sc, CFrame.new(centerPos), PAL.HotWhite, 0.12, Enum.Material.ForceField, folder)
	TweenService:Create(swellOrb, TweenInfo.new(0.09, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = Vector3.new(5.6, 5.6, 5.6) * sc,
		Transparency = 0.02,
	}):Play()
	task.delay(0.09, function()
		if swellOrb and swellOrb.Parent then
			TweenService:Create(swellOrb, TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = Vector3.new(9.5, 9.5, 9.5) * sc,
				Transparency = 1,
			}):Play()
		end
		local shardCount = VFXStudioLibrary.IsLowFX() and 6 or (isBoss and 16 or 12)
		for i = 1, shardCount do
			local u = (math.random() - 0.5) * 2
			local theta = math.random() * math.pi * 2
			local r = math.sqrt(math.max(0, 1 - u * u))
			local dir = Vector3.new(r * math.cos(theta), math.abs(u) * 0.85 + 0.25, r * math.sin(theta)).Unit
			local shard = VFXStudioLibrary.MakePart(
				"DeathPopShard_" .. i,
				(i % 2 == 0) and Enum.PartType.Wedge or Enum.PartType.Block,
				Vector3.new(0.65, 0.85, 1.05) * sc,
				CFrame.new(centerPos),
				(i % 3 == 0) and PAL.HotWhite or ((i % 2 == 0) and PAL.Gold or PAL.Cyan),
				0.04,
				Enum.Material.ForceField,
				folder
			)
			local dist = (5.5 + math.random() * 6.5) * sc
			TweenService:Create(shard, TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				CFrame = CFrame.new(centerPos + dir * dist - Vector3.new(0, 1.8, 0)) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6),
				Size = Vector3.new(0.12, 0.12, 0.12),
				Transparency = 1,
			}):Play()
			Debris:AddItem(shard, 0.46)
		end
	end)
	Debris:AddItem(swellOrb, 0.28)
end

-- ============================================================================
-- 2. PHÉP CẦU LỬA (5 BƯỚC + FINISHER CHÁY THÀNH TRO & VẾT ĐEN TRÊN ĐẤT)
-- ============================================================================
function VFXStudioLibrary.VibeGG_Fireball5Steps(startPos, endPos, scale, isFinisher, isLocal, ignoreChar)
	local cfg = VFXStudioLibrary.VibeGGConfig.Fireball
	local sc = math.clamp(tonumber(scale) or 1, 0.6, 2.4)
	local folder = VFXStudioLibrary.GetTempFolder("UniversalVFX")
	local chargeTime = isStepEnabled("Fireball", "Step1_ChargeUp") and cfg.ChargeDuration or 0.02

	-- Bước 1: Charge-up (Tụ lực ở tay 0.3-0.5s trước khi bắn)
	if isStepEnabled("Fireball", "Step1_ChargeUp") then
		local chargeCore = VFXStudioLibrary.MakePart("Fireball_ChargeCore", Enum.PartType.Ball, Vector3.new(0.4, 0.4, 0.4) * sc, CFrame.new(startPos), PAL.HotWhite, 0.06, Enum.Material.ForceField, folder)
		local chargeShell = VFXStudioLibrary.MakePart("Fireball_ChargeShell", Enum.PartType.Ball, Vector3.new(0.8, 0.8, 0.8) * sc, CFrame.new(startPos), PAL.Solar, 0.24, Enum.Material.ForceField, folder)
		VFXStudioLibrary.SafeLight(chargeCore, PAL.Solar, 1.35, 12, chargeTime + 0.1)
		TweenService:Create(chargeCore, TweenInfo.new(chargeTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = Vector3.new(2.2, 2.2, 2.2) * sc,
		}):Play()
		TweenService:Create(chargeShell, TweenInfo.new(chargeTime, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = Vector3.new(3.4, 3.4, 3.4) * sc,
			Transparency = 0.55,
		}):Play()
		local moteCount = VFXStudioLibrary.IsLowFX() and 4 or 7
		for m = 1, moteCount do
			local ang = m * ((math.pi * 2) / moteCount)
			local mOrigin = startPos + Vector3.new(math.cos(ang) * 3.8 * sc, (m % 2 == 0 and 1.2 or -1.0) * sc, math.sin(ang) * 3.8 * sc)
			local mote = VFXStudioLibrary.MakePart("FireChargeMote_" .. m, Enum.PartType.Ball, Vector3.new(0.55, 0.55, 0.55) * sc, CFrame.new(mOrigin), (m % 2 == 0) and PAL.Gold or PAL.Magma, 0.08, Enum.Material.ForceField, folder)
			TweenService:Create(mote, TweenInfo.new(chargeTime * 0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Position = startPos,
				Size = Vector3.new(0.15, 0.15, 0.15),
				Transparency = 0.8,
			}):Play()
			Debris:AddItem(mote, chargeTime)
		end
		Debris:AddItem(chargeCore, chargeTime + 0.05)
		Debris:AddItem(chargeShell, chargeTime + 0.05)
	end

	-- Bước 2: Projectile trail (Đuôi lửa dày + hạt tàn rơi dọc đường bay)
	task.delay(chargeTime * 0.75, function()
		local fbCore = VFXStudioLibrary.MakePart("VibeGG_FireballCore", Enum.PartType.Ball, Vector3.new(2.4, 2.4, 2.4) * sc, CFrame.new(startPos), PAL.HotWhite, 0.04, Enum.Material.ForceField, folder)
		local fbMantle = VFXStudioLibrary.MakePart("VibeGG_FireballMantle", Enum.PartType.Ball, Vector3.new(3.5, 3.5, 3.5) * sc, CFrame.new(startPos), PAL.Solar, 0.18, Enum.Material.ForceField, folder)
		if isStepEnabled("Fireball", "Step2_ProjectileTrail") then
			VFXStudioLibrary.AttachRibbonTrail(fbCore, PAL.HotWhite, PAL.Solar, PAL.Magma, 2.4 * sc, 0.30)
		end
		local flightDur = cfg.FlightDuration
		local t0 = os.clock()
		local lastEmberAt = 0
		local conn
		conn = RunService.Heartbeat:Connect(function()
			local a = math.clamp((os.clock() - t0) / flightDur, 0, 1)
			local arcY = math.sin(a * math.pi) * 2.2 * sc
			local curPos = startPos:Lerp(endPos, a) + Vector3.new(0, arcY, 0)
			if fbCore.Parent then fbCore.CFrame = CFrame.new(curPos) end
			if fbMantle.Parent then fbMantle.CFrame = CFrame.new(curPos) end

			-- Hạt tàn lửa rơi xuống dọc đường bay
			if isStepEnabled("Fireball", "Step2_ProjectileTrail") and not VFXStudioLibrary.IsLowFX() and (os.clock() - lastEmberAt >= 0.04) then
				lastEmberAt = os.clock()
				local ember = VFXStudioLibrary.MakePart("DroppingEmber", Enum.PartType.Ball, Vector3.new(0.42, 0.42, 0.42) * sc, CFrame.new(curPos + Vector3.new((math.random() - 0.5) * 1.2, -0.3, (math.random() - 0.5) * 1.2)), PAL.Gold, 0.06, Enum.Material.ForceField, folder)
				TweenService:Create(ember, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Position = ember.Position - Vector3.new(0, 3.4 * sc, 0),
					Size = Vector3.new(0.08, 0.08, 0.08),
					Color = PAL.Magma,
					Transparency = 1,
				}):Play()
				Debris:AddItem(ember, 0.35)
			end

			if a >= 1 then
				conn:Disconnect()
				if fbCore.Parent then fbCore.Transparency = 1 end
				if fbMantle.Parent then fbMantle.Transparency = 1 end

				-- Bước 3: Impact burst (Chớp sáng + Vòng sóng xung kích)
				local gPos = VFXStudioLibrary.FindGround(endPos)
				if isStepEnabled("Fireball", "Step3_ImpactBurst") then
					VFXStudioLibrary.Emit("Elements", "Elem_Flame", CFrame.new(endPos), sc * 1.25, PAL.Solar, PAL.Magma)
					local flash = VFXStudioLibrary.MakePart("Fireball_ImpactFlash", Enum.PartType.Ball, Vector3.new(3.2, 3.2, 3.2) * sc, CFrame.new(endPos), PAL.HotWhite, 0.04, Enum.Material.ForceField, folder)
					VFXStudioLibrary.SafeLight(flash, PAL.Solar, 1.45, 16, 0.38)
					TweenService:Create(flash, TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
						Size = Vector3.new(13.5, 13.5, 13.5) * sc,
						Color = PAL.Magma,
						Transparency = 1,
					}):Play()
					Debris:AddItem(flash, 0.36)
					VFXStudioLibrary.SpawnShockRing(gPos + Vector3.new(0, 0.2, 0), nil, PAL.Gold, 1.6 * sc, 14.5 * sc, 0.32, 0.42, Enum.Material.ForceField, folder)
					VFXStudioLibrary.SpawnShockRing(gPos + Vector3.new(0, 0.4, 0), nil, PAL.Magma, 1.2 * sc, 10.5 * sc, 0.24, 0.34, Enum.Material.ForceField, folder)
					if isLocal then
						VFXStudioLibrary.EmitCameraTrauma(0.35, 2.2)
					end
				end

				-- Bước 4: Damage numbers / Crit pop nảy lên
				if isStepEnabled("Fireball", "Step4_DamageCritPop") then
					VFXStudioLibrary.SpawnPopTextBillboard(endPos, isFinisher and "🔥 SOLAR CRIT!" or "🔥 BURN!", PAL.Gold, PAL.Magma, isFinisher and 1.45 or 1.18)
				end

				-- Bước 5: Burn DoT (Mục tiêu bốc cháy nhấp nháy theo nhịp)
				local target = VFXStudioLibrary.FindNearestTargetModel(endPos, 14 * sc, ignoreChar)
				if isStepEnabled("Fireball", "Step5_BurnDoT") then
					local burnCenter = (target and target:FindFirstChild("HumanoidRootPart") and target.HumanoidRootPart.Position) or endPos
					for tickIdx = 1, cfg.BurnTicks do
						task.delay((tickIdx - 1) * cfg.BurnInterval, function()
							local curPosTick = (target and target.Parent and target:FindFirstChild("HumanoidRootPart") and target.HumanoidRootPart.Position) or burnCenter
							if target and target.Parent then
								VFXStudioLibrary.PulseTargetHighlight(target, PAL.Solar, PAL.Gold, 0.16)
							end
							local burnRing = VFXStudioLibrary.MakePart("BurnDoTPulse_" .. tickIdx, Enum.PartType.Cylinder, Vector3.new(0.24, 2.6 * sc, 2.6 * sc), CFrame.new(curPosTick - Vector3.new(0, 1.2, 0)) * CFrame.Angles(0, 0, math.pi * 0.5), (tickIdx % 2 == 0) and PAL.Solar or PAL.Gold, 0.12, Enum.Material.ForceField, folder)
							TweenService:Create(burnRing, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
								Position = curPosTick + Vector3.new(0, 2.2, 0),
								Size = Vector3.new(0.08, 4.4 * sc, 4.4 * sc),
								Transparency = 1,
							}):Play()
							Debris:AddItem(burnRing, 0.32)
						end)
					end
				end

				-- Finisher: Cháy thành tro + Để lại vết đen trên đất
				if isFinisher and isStepEnabled("Fireball", "Finisher_AshAndScorch") then
					local scorch = VFXStudioLibrary.MakePart("Fireball_ScorchMark", Enum.PartType.Cylinder, Vector3.new(0.08, 1.5 * sc, 1.5 * sc), CFrame.new(gPos + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, 0, math.pi * 0.5), PAL.Obsidian, 0.10, Enum.Material.Slate, folder)
					local emberRim = VFXStudioLibrary.MakePart("Fireball_ScorchRim", Enum.PartType.Cylinder, Vector3.new(0.06, 1.8 * sc, 1.8 * sc), CFrame.new(gPos + Vector3.new(0, 0.04, 0)) * CFrame.Angles(0, 0, math.pi * 0.5), PAL.Magma, 0.25, Enum.Material.ForceField, folder)
					TweenService:Create(scorch, TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
						Size = Vector3.new(0.08, 9.2 * sc, 9.2 * sc),
					}):Play()
					TweenService:Create(emberRim, TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
						Size = Vector3.new(0.06, 10.4 * sc, 10.4 * sc),
						Transparency = 0.85,
					}):Play()
					task.delay(1.8, function()
						if scorch and scorch.Parent then
							TweenService:Create(scorch, TweenInfo.new(0.8), { Transparency = 1 }):Play()
						end
					end)
					Debris:AddItem(scorch, 2.7)
					Debris:AddItem(emberRim, 1.2)

					local ashCount = VFXStudioLibrary.IsLowFX() and 5 or 10
					for aIdx = 1, ashCount do
						local ash = VFXStudioLibrary.MakePart("BurnAshFlake_" .. aIdx, Enum.PartType.Block, Vector3.new(0.38, 0.12, 0.38) * sc, CFrame.new(gPos + Vector3.new((math.random() - 0.5) * 4.5 * sc, 0.6 + math.random() * 2.5, (math.random() - 0.5) * 4.5 * sc)), (aIdx % 3 == 0) and PAL.Solar or PAL.Obsidian, 0.12, Enum.Material.Slate, folder)
						TweenService:Create(ash, TweenInfo.new(0.95, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
							CFrame = CFrame.new(ash.Position + Vector3.new((math.random() - 0.5) * 2.4, 3.8 * sc, (math.random() - 0.5) * 2.4)) * CFrame.Angles(math.random() * 4, math.random() * 4, 0),
							Transparency = 1,
						}):Play()
						Debris:AddItem(ash, 1.0)
					end
				end
			end
		end)
		Debris:AddItem(fbCore, flightDur + 0.35)
		Debris:AddItem(fbMantle, flightDur + 0.15)
	end)
end

-- ============================================================================
-- 3. BẮN SÚNG (5 BƯỚC + FINISHER 0.3S SLOW-MOTION & RAGDOLL VĂNG XA)
-- ============================================================================
function VFXStudioLibrary.VibeGG_Gunplay5Steps(muzzlePos, targetPos, lookDir, primaryCol, secondaryCol, scale, isFinisher, isLocal, actorChar)
	local cfg = VFXStudioLibrary.VibeGGConfig.Gunplay
	local sc = math.clamp(tonumber(scale) or 1, 0.6, 2.2)
	local folder = VFXStudioLibrary.GetTempFolder("UniversalVFX")
	local pCol = primaryCol or PAL.Gold
	local sCol = secondaryCol or PAL.Cyan
	local aimCF = VFXStudioLibrary.SafeLookAt(muzzlePos, targetPos, lookDir)

	-- Bước 1: Muzzle flash (Tia lửa đầu nòng đa cánh + PointLight lóe 2-3 frame)
	if isStepEnabled("Gunplay", "Step1_MuzzleFlash") then
		local flashCore = VFXStudioLibrary.MakePart("Gun_MuzzleCore", Enum.PartType.Ball, Vector3.new(1.1, 1.1, 1.1) * sc, aimCF, PAL.HotWhite, 0.02, Enum.Material.ForceField, folder)
		VFXStudioLibrary.SafeLight(flashCore, pCol, 1.42, 12, 0.06)
		TweenService:Create(flashCore, TweenInfo.new(0.06), { Size = Vector3.new(2.2, 2.2, 2.2) * sc, Transparency = 1 }):Play()
		Debris:AddItem(flashCore, 0.08)
		for prong = 1, 3 do
			local pCF = aimCF * CFrame.Angles(0, 0, (prong - 1) * (math.pi / 3))
			local spike = VFXStudioLibrary.MakePart("Gun_MuzzleProng_" .. prong, Enum.PartType.Block, Vector3.new(0.22 * sc, 2.4 * sc, 0.22 * sc), pCF, (prong % 2 == 0) and pCol or PAL.HotWhite, 0.04, Enum.Material.ForceField, folder)
			TweenService:Create(spike, TweenInfo.new(0.065), { Size = Vector3.new(0.05, 3.6 * sc, 0.05), Transparency = 1 }):Play()
			Debris:AddItem(spike, 0.08)
		end
	end

	-- Bước 2: Bullet spread nhẹ + đường đạn sáng (Tracer)
	local actualDst = targetPos
	if isStepEnabled("Gunplay", "Step2_SpreadAndTracer") then
		local dist = math.max(2, (targetPos - muzzlePos).Magnitude)
		local spreadRad = math.rad(cfg.SpreadDeg)
		local spreadCF = aimCF * CFrame.Angles((math.random() - 0.5) * spreadRad, (math.random() - 0.5) * spreadRad, 0)
		actualDst = muzzlePos + spreadCF.LookVector * dist
		local tracerBullet = VFXStudioLibrary.MakePart("Gun_SpreadTracer", Enum.PartType.Block, Vector3.new(0.18 * sc, 0.18 * sc, 2.8 * sc), spreadCF, PAL.HotWhite, 0.02, Enum.Material.ForceField, folder)
		VFXStudioLibrary.AttachRibbonTrail(tracerBullet, PAL.HotWhite, pCol, sCol, 0.55 * sc, 0.14)
		TweenService:Create(tracerBullet, TweenInfo.new(0.09, Enum.EasingStyle.Linear), {
			CFrame = CFrame.new(actualDst) * (spreadCF - spreadCF.Position),
		}):Play()
		Debris:AddItem(tracerBullet, 0.22)
	end

	-- Bước 3: Recoil (Giật lùi vũ khí/nhân vật & giật camera hồi lại mượt)
	if isStepEnabled("Gunplay", "Step3_Recoil") then
		if isLocal then
			VFXStudioLibrary.EmitCameraTrauma(isFinisher and 0.38 or 0.22, isFinisher and 2.8 or 1.4, -aimCF.LookVector)
		end
		local root = actorChar and actorChar:FindFirstChild("HumanoidRootPart")
		if root and root.Parent then
			local backVec = Vector3.new(-aimCF.LookVector.X, 0, -aimCF.LookVector.Z)
			if backVec.Magnitude > 0.05 then
				local recoilCF = root.CFrame + backVec.Unit * (0.35 * sc)
				TweenService:Create(root, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = recoilCF }):Play()
			end
		end
	end

	-- Bước 4: Shell ejection (Vỏ đạn đồng văng vòng cung sang bên phải và nảy trên sàn)
	if isStepEnabled("Gunplay", "Step4_ShellEjection") and not VFXStudioLibrary.IsLowFX() then
		local shellOrigin = muzzlePos - aimCF.LookVector * 0.9 + aimCF.RightVector * 0.45
		local shell = VFXStudioLibrary.MakePart("Gun_BrassShell", Enum.PartType.Cylinder, Vector3.new(0.42 * sc, 0.16 * sc, 0.16 * sc), CFrame.new(shellOrigin), PAL.Gold, 0.0, Enum.Material.Metal, folder)
		local floorPos = VFXStudioLibrary.FindGround(shellOrigin, actorChar)
		local landPos = Vector3.new(shellOrigin.X, floorPos.Y + 0.08, shellOrigin.Z) + aimCF.RightVector * (2.6 + math.random() * 1.4) - aimCF.LookVector * (0.6 + math.random() * 0.8)
		local t0 = os.clock()
		local dur = 0.48
		local conn
		conn = RunService.Heartbeat:Connect(function()
			local a = math.clamp((os.clock() - t0) / dur, 0, 1)
			local xz = shellOrigin:Lerp(landPos, a)
			local bounceY
			if a < 0.65 then
				local u = a / 0.65
				bounceY = shellOrigin.Y * (1 - u) + landPos.Y * u + math.sin(u * math.pi) * 1.85
			else
				local u = (a - 0.65) / 0.35
				bounceY = landPos.Y + math.abs(math.sin(u * math.pi * 2)) * (0.55 * (1 - u))
			end
			if shell.Parent then
				shell.CFrame = CFrame.new(xz.X, bounceY, xz.Z) * CFrame.Angles(a * 18, a * 12, a * 22)
			end
			if a >= 1 then
				conn:Disconnect()
				task.delay(0.45, function()
					if shell and shell.Parent then
						TweenService:Create(shell, TweenInfo.new(0.25), { Transparency = 1 }):Play()
					end
				end)
			end
		end)
		Debris:AddItem(shell, 1.25)
	end

	-- Bước 5: Decals (Vết đạn đen + tia lửa bắn ra ở điểm trúng)
	if isStepEnabled("Gunplay", "Step5_ImpactDecalAndSparks") then
		task.delay(0.06, function()
			local hole = VFXStudioLibrary.MakePart("Gun_BulletHoleDecal", Enum.PartType.Cylinder, Vector3.new(0.06, 0.85 * sc, 0.85 * sc), VFXStudioLibrary.SafeLookAt(actualDst, actualDst + aimCF.LookVector, aimCF.LookVector) * CFrame.Angles(0, math.pi * 0.5, 0), PAL.Obsidian, 0.08, Enum.Material.Slate, folder)
			local rim = VFXStudioLibrary.MakePart("Gun_BulletHoleRim", Enum.PartType.Cylinder, Vector3.new(0.04, 1.35 * sc, 1.35 * sc), hole.CFrame, pCol, 0.18, Enum.Material.ForceField, folder)
			TweenService:Create(rim, TweenInfo.new(0.35), { Size = Vector3.new(0.04, 2.2 * sc, 2.2 * sc), Transparency = 1 }):Play()
			task.delay(1.2, function()
				if hole and hole.Parent then
					TweenService:Create(hole, TweenInfo.new(0.45), { Transparency = 1 }):Play()
				end
			end)
			Debris:AddItem(hole, 1.7)
			Debris:AddItem(rim, 0.4)

			local spCount = VFXStudioLibrary.IsLowFX() and 3 or 6
			for s = 1, spCount do
				local rDir = (-aimCF.LookVector + Vector3.new((math.random() - 0.5) * 1.4, math.random() * 1.1, (math.random() - 0.5) * 1.4)).Unit
				local sp = VFXStudioLibrary.MakePart("BulletHitSpark_" .. s, Enum.PartType.Block, Vector3.new(0.12, 0.12, 1.4 * sc), VFXStudioLibrary.SafeLookAt(actualDst, actualDst + rDir, rDir), (s % 2 == 0) and PAL.HotWhite or pCol, 0.04, Enum.Material.ForceField, folder)
				TweenService:Create(sp, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					CFrame = CFrame.new(actualDst + rDir * (3.2 * sc)) * (sp.CFrame - sp.CFrame.Position),
					Size = Vector3.new(0.03, 0.03, 0.4),
					Transparency = 1,
				}):Play()
				Debris:AddItem(sp, 0.22)
			end
		end)
	end

	-- Finisher: 0.3s Slow-motion + Ragdoll / Văng xa mục tiêu
	if isFinisher and isStepEnabled("Gunplay", "Finisher_SlowMoRagdoll") then
		if isLocal then
			VFXStudioLibrary.TriggerLocalHitStop(cfg.SlowMoDuration * 0.35)
			local cam = Workspace.CurrentCamera
			if cam then
				local baseFov = cam.FieldOfView
				TweenService:Create(cam, TweenInfo.new(0.08, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { FieldOfView = math.max(52, baseFov - 8) }):Play()
				task.delay(cfg.SlowMoDuration, function()
					if cam then
						TweenService:Create(cam, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = baseFov }):Play()
					end
				end)
			end
		end
		local target = VFXStudioLibrary.FindNearestTargetModel(actualDst, 12 * sc, actorChar)
		if target then
			local root = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
			if root and root.Parent then
				local launchDir = Vector3.new(aimCF.LookVector.X, 0, aimCF.LookVector.Z)
				launchDir = (launchDir.Magnitude > 0.05) and launchDir.Unit or Vector3.new(0, 0, -1)
				local startCF = root.CFrame
				local endGround = VFXStudioLibrary.FindGround( startCF.Position + launchDir * (6.5 * sc), target)
				local finalPos = Vector3.new(endGround.X, startCF.Position.Y, endGround.Z)
				local t0 = os.clock()
				local conn
				conn = RunService.Heartbeat:Connect(function()
					local a = math.clamp((os.clock() - t0) / cfg.SlowMoDuration, 0, 1)
					if not root or not root.Parent then
						conn:Disconnect()
						return
					end
					local p = startCF.Position:Lerp(finalPos, a) + Vector3.new(0, math.sin(a * math.pi) * 3.4 * sc, 0)
					root.CFrame = CFrame.new(p) * (startCF - startCF.Position) * CFrame.Angles(-a * 0.55 * (1 - a), 0, 0)
					if a >= 1 then
						conn:Disconnect()
					end
				end)
			end
		end
	end
end

-- ============================================================================
-- 4. PHÉP BĂNG (5 BƯỚC + FINISHER ĐÓNG BĂNG MỤC TIÊU TRONG KHỐI BĂNG LỚN)
-- ============================================================================
function VFXStudioLibrary.VibeGG_IceSpikes5Steps(startPos, endPos, lookDir, scale, isFinisher, isLocal, ignoreChar)
	local cfg = VFXStudioLibrary.VibeGGConfig.IceSpikes
	local sc = math.clamp(tonumber(scale) or 1, 0.6, 2.4)
	local folder = VFXStudioLibrary.GetTempFolder("UniversalVFX")
	local dir = (typeof(lookDir) == "Vector3" and lookDir.Magnitude > 0.05) and lookDir.Unit or Vector3.new(0, 0, -1)
	local count = VFXStudioLibrary.IsLowFX() and 4 or cfg.ClusterCount

	-- Bước 1: Ground spikes trồi lên tuần tự từ đất về phía mục tiêu
	for i = 1, count do
		task.delay((i - 1) * 0.055, function()
			local frac = i / count
			local clusterPos = startPos:Lerp(endPos, frac)
			local gPos = VFXStudioLibrary.FindGround(clusterPos, ignoreChar)
			local basisCF = VFXStudioLibrary.SafeLookAt(gPos, gPos + dir, dir)

			-- Bước 2: Grow (Càng gần mục tiêu gai băng càng to và cao hơn)
			local growMult = isStepEnabled("IceSpikes", "Step2_ProgressiveGrow") and (0.55 + frac * 1.05) or 1.0
			local h = 5.4 * sc * growMult
			local w = 1.65 * sc * growMult

			-- Bước 4: Ground cracks (Vết nứt băng dưới đất + đá/băng vụn văng lên)
			if isStepEnabled("IceSpikes", "Step4_GroundCracksAndDebris") then
				for c = 1, 3 do
					local cAng = (c - 2) * 0.85 + (i % 2 == 0 and 0.2 or -0.2)
					local crack = VFXStudioLibrary.MakePart("IceGroundCrack_" .. c, Enum.PartType.Block, Vector3.new(0.18 * sc, 0.08, 3.6 * sc * growMult), basisCF * CFrame.Angles(0, cAng, 0) * CFrame.new(0, 0.05, -1.2 * sc), PAL.Cyan, 0.08, Enum.Material.ForceField, folder)
					TweenService:Create(crack, TweenInfo.new(0.65), { Transparency = 1 }):Play()
					Debris:AddItem(crack, 0.70)
				end
				if not VFXStudioLibrary.IsLowFX() then
					for d = 1, 2 do
						local chunk = VFXStudioLibrary.MakePart("IceDebrisChunk_" .. d, Enum.PartType.Wedge, Vector3.new(0.55, 0.55, 0.75) * sc * growMult, CFrame.new(gPos + Vector3.new(0, 0.3, 0)), (d == 1) and PAL.Ice or PAL.Slate, 0.08, (d == 1) and Enum.Material.Glass or Enum.Material.Slate, folder)
						local dVel = Vector3.new((math.random() - 0.5) * 4.5, 2.8 + math.random() * 2.2, (math.random() - 0.5) * 4.5) * sc
						TweenService:Create(chunk, TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							CFrame = CFrame.new(gPos + dVel) * CFrame.Angles(math.random() * 5, math.random() * 5, 0),
							Transparency = 1,
						}):Play()
						Debris:AddItem(chunk, 0.42)
					end
				end
			end

			-- Bước 3: Fan out (Gai chính ở giữa + 2 gai phụ nghiêng sang hai bên)
			local fanSpecs = { { Side = 0, Scale = 1.0, Roll = 0 } }
			if isStepEnabled("IceSpikes", "Step3_FanOut") then
				local radAng = math.rad(cfg.SideSpikeAngleDeg)
				table.insert(fanSpecs, { Side = -1, Scale = 0.68, Roll = radAng })
				table.insert(fanSpecs, { Side = 1, Scale = 0.68, Roll = -radAng })
			end

			-- Xây mỗi gai băng gồm 3 tầng (Base, Mid, Tip) để Bước 5 vỡ từ ngọn xuống gốc!
			for _, fSpec in ipairs(fanSpecs) do
				local spikeCF = basisCF * CFrame.new(fSpec.Side * w * 0.65, 0, 0) * CFrame.Angles(-0.18, fSpec.Side * 0.22, fSpec.Roll)
				local sH = h * fSpec.Scale
				local sW = w * fSpec.Scale
				local tiers = {
					{ Name = "Base", Y0 = 0.0, Y1 = 0.38, W = 1.00, Delay = 0.14 },
					{ Name = "Mid",  Y0 = 0.38, Y1 = 0.72, W = 0.68, Delay = 0.07 },
					{ Name = "Tip",  Y0 = 0.72, Y1 = 1.00, W = 0.36, Delay = 0.00 },
				}
				for _, t in ipairs(tiers) do
					local segH = sH * (t.Y1 - t.Y0)
					local midY = sH * ((t.Y0 + t.Y1) * 0.5)
					local segPart = VFXStudioLibrary.MakePart(
						"IceSpike_" .. t.Name,
						(t.Name == "Tip") and Enum.PartType.Wedge or Enum.PartType.Block,
						Vector3.new(sW * t.W, segH, sW * t.W),
						spikeCF * CFrame.new(0, -segH, 0),
						(t.Name == "Tip") and PAL.HotWhite or ((t.Name == "Mid") and PAL.Ice or PAL.Cyan),
						0.12,
						Enum.Material.Glass,
						folder
					)
					local targetSegCF = spikeCF * CFrame.new(0, midY, 0)
					TweenService:Create(segPart, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
						CFrame = targetSegCF,
					}):Play()

					-- Bước 5: Shatter (Vỡ tuần tự từ ngọn Tip -> Mid -> Base thành mảnh băng rơi xuống)
					task.delay(0.36 + (isStepEnabled("IceSpikes", "Step5_TopDownShatter") and t.Delay or 0), function()
						if segPart and segPart.Parent then
							local fallOffset = Vector3.new((math.random() - 0.5) * 2.4 * sc, -midY * 0.85, (math.random() - 0.5) * 2.4 * sc)
							TweenService:Create(segPart, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
								CFrame = targetSegCF * CFrame.new(fallOffset) * CFrame.Angles(math.random() * 3, math.random() * 3, math.random() * 3),
								Size = segPart.Size * 0.25,
								Transparency = 1,
							}):Play()
						end
					end)
					Debris:AddItem(segPart, 0.82)
				end
			end
		end)
	end

	-- Finisher: Đóng băng mục tiêu trong khối băng lớn (Giant Ice Block)
	if isFinisher and isStepEnabled("IceSpikes", "Finisher_GiantIceBlock") then
		task.delay(count * 0.055 + 0.08, function()
			local target = VFXStudioLibrary.FindNearestTargetModel(endPos, 14 * sc, ignoreChar)
			local freezePos = (target and target:FindFirstChild("HumanoidRootPart") and target.HumanoidRootPart.Position) or endPos
			local gPos = VFXStudioLibrary.FindGround(freezePos, ignoreChar)
			if target then
				VFXStudioLibrary.PulseTargetHighlight(target, PAL.Ice, PAL.HotWhite, 0.95)
			end
			local iceBlock = VFXStudioLibrary.MakePart(
				"VibeGG_GiantIceBlock",
				Enum.PartType.Block,
				Vector3.new(1.2, 1.2, 1.2) * sc,
				CFrame.new(gPos + Vector3.new(0, 3.8 * sc, 0)) * CFrame.Angles(0, 0.35, 0),
				PAL.Ice,
				0.28,
				Enum.Material.Glass,
				folder
			)
			local innerPrism = VFXStudioLibrary.MakePart(
				"VibeGG_IceBlockCore",
				Enum.PartType.Block,
				Vector3.new(0.8, 0.8, 0.8) * sc,
				iceBlock.CFrame * CFrame.Angles(0.15, 0.78, 0),
				PAL.HotWhite,
				0.42,
				Enum.Material.ForceField,
				folder
			)
			VFXStudioLibrary.Emit("Elements", "Elem_Ice", CFrame.new(gPos + Vector3.new(0, 3.2 * sc, 0)), sc * 1.35, PAL.Ice, PAL.Cyan)
			TweenService:Create(iceBlock, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = Vector3.new(6.2, 7.8, 6.2) * sc,
			}):Play()
			TweenService:Create(innerPrism, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = Vector3.new(4.8, 6.4, 4.8) * sc,
			}):Play()
			task.delay(0.85, function()
				if iceBlock and iceBlock.Parent then
					TweenService:Create(iceBlock, TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
						Size = Vector3.new(8.2, 9.2, 8.2) * sc,
						Transparency = 1,
					}):Play()
				end
				if innerPrism and innerPrism.Parent then
					TweenService:Create(innerPrism, TweenInfo.new(0.26), { Transparency = 1 }):Play()
				end
			end)
			Debris:AddItem(iceBlock, 1.22)
			Debris:AddItem(innerPrism, 1.18)
		end)
	end
end

-- ============================================================================
-- 5. PHÉP TIA SÉT (5 BƯỚC + FINISHER GIẬT ĐIỆN ĐEN THUI & BỐC KHÓI)
-- ============================================================================
function VFXStudioLibrary.VibeGG_Lightning5Steps(p0, p1, scale, primaryCol, secondaryCol, isFinisher, isLocal, ignoreChar)
	local cfg = VFXStudioLibrary.VibeGGConfig.Lightning
	local sc = math.clamp(tonumber(scale) or 1, 0.6, 2.5)
	local folder = VFXStudioLibrary.GetTempFolder("UniversalVFX")
	local c1 = primaryCol or PAL.Thunder
	local c2 = secondaryCol or PAL.Violet
	local aimCF = VFXStudioLibrary.SafeLookAt(p0, p1)
	local segs = VFXStudioLibrary.IsLowFX() and 5 or 7
	local poses = isStepEnabled("Lightning", "Step5_MultiFrameFlicker") and cfg.FlickerFrames or 1
	local stepTime = cfg.FlickerStepTime

	-- Bước 5: Flicker (Đổi hình dáng tia sét liên tục mỗi 2 frame rồi tắt)
	for poseIdx = 1, poses do
		task.delay((poseIdx - 1) * stepTime, function()
			local prev = p0
			for s = 1, segs do
				local frac = s / segs
				local nxt = p0:Lerp(p1, frac)
				if s < segs and isStepEnabled("Lightning", "Step1_ZigzagAndBranches") then
					local amp = (1.65 + math.sin(frac * math.pi) * 1.45) * sc
					local jx = (math.random() - 0.5) * 2 * amp
					local jy = (math.random() - 0.5) * 2 * amp
					nxt = nxt + aimCF.RightVector * jx + aimCF.UpVector * jy
				end

				-- Bước 2: Taper (Phình to ở khúc gãy giữa và thon nhỏ ở 2 đầu)
				local midWeight = math.sin(frac * math.pi)
				local taperMult = isStepEnabled("Lightning", "Step2_Taper") and (0.45 + midWeight * 0.95) or 1.0
				local baseThick = 0.42 * sc * taperMult
				local segLen = math.max(0.2, (nxt - prev).Magnitude)
				local segCF = VFXStudioLibrary.SafeLookAt((prev + nxt) * 0.5, nxt, aimCF.LookVector)

				-- Bước 3: Glow 2 lớp (Lớp ngoài ForceField rộng + Lớp trong sáng mạnh)
				if isStepEnabled("Lightning", "Step3_DualLayerGlow") then
					local outerGlow = VFXStudioLibrary.MakePart(
						"BoltOuterGlow",
						Enum.PartType.Block,
						Vector3.new(baseThick * 2.35, baseThick * 2.35, segLen + baseThick),
						segCF,
						(s % 2 == 0) and c2 or c1,
						0.45,
						Enum.Material.ForceField,
						folder
					)
					TweenService:Create(outerGlow, TweenInfo.new(stepTime * 1.6), { Transparency = 1 }):Play()
					Debris:AddItem(outerGlow, stepTime * 1.8)
				end

				-- Bước 4: White core (Lõi trắng rực chạy dọc chính giữa)
				local coreCol = isStepEnabled("Lightning", "Step4_WhiteCore") and PAL.HotWhite or c1
				local innerCore = VFXStudioLibrary.MakePart(
					"BoltWhiteCore",
					Enum.PartType.Block,
					Vector3.new(baseThick * 0.52, baseThick * 0.52, segLen + baseThick * 0.3),
					segCF,
					coreCol,
					0.02,
					Enum.Material.SmoothPlastic,
					folder
				)
				TweenService:Create(innerCore, TweenInfo.new(stepTime * 1.5), {
					Size = Vector3.new(baseThick * 0.12, baseThick * 0.12, segLen),
					Transparency = 1,
				}):Play()
				Debris:AddItem(innerCore, stepTime * 1.7)

				-- Bước 1 (Nhánh phụ Sub-branches tẽ ra từ các khúc gãy giữa)
				if isStepEnabled("Lightning", "Step1_ZigzagAndBranches") and (s == 2 or s == 4 or s == 5) and not VFXStudioLibrary.IsLowFX() then
					local branchDir = (aimCF.LookVector + aimCF.RightVector * ((s % 2 == 0 and 0.85 or -0.85)) + aimCF.UpVector * ((math.random() - 0.5) * 0.6)).Unit
					local bMid = nxt + branchDir * (2.6 * sc)
					local bTip = bMid + (branchDir + aimCF.RightVector * ((math.random() - 0.5) * 0.8)).Unit * (2.2 * sc)
					for bSeg, pair in ipairs({ { nxt, bMid, 0.24 * sc }, { bMid, bTip, 0.12 * sc } }) do
						local bLen = (pair[2] - pair[1]).Magnitude
						local bPart = VFXStudioLibrary.MakePart("BoltSubBranch_" .. bSeg, Enum.PartType.Block, Vector3.new(pair[3], pair[3], bLen), VFXStudioLibrary.SafeLookAt((pair[1] + pair[2]) * 0.5, pair[2], branchDir), (bSeg == 1) and PAL.HotWhite or c1, 0.08, Enum.Material.ForceField, folder)
						TweenService:Create(bPart, TweenInfo.new(stepTime * 1.5), { Transparency = 1 }):Play()
						Debris:AddItem(bPart, stepTime * 1.7)
					end
				end

				prev = nxt
			end
		end)
	end

	VFXStudioLibrary.SafeLight(VFXStudioLibrary.MakePart("LightningFlashNode", Enum.PartType.Ball, Vector3.new(0.5, 0.5, 0.5), CFrame.new(p1), PAL.HotWhite, 1, Enum.Material.SmoothPlastic, folder), c1, 1.45, 16, poses * stepTime + 0.08)
	if isLocal then
		VFXStudioLibrary.EmitCameraTrauma(0.32, 1.8)
	end

	-- Finisher: Mục tiêu giật điện rung lắc, cháy đen thui và bốc khói đen
	if isFinisher and isStepEnabled("Lightning", "Finisher_ElectroCharSmoke") then
		local target = VFXStudioLibrary.FindNearestTargetModel(p1, 13 * sc, ignoreChar)
		local charCenter = (target and target:FindFirstChild("HumanoidRootPart") and target.HumanoidRootPart.Position) or p1
		if target then
			local root = target:FindFirstChild("HumanoidRootPart") or target.PrimaryPart
			local baseCF = root and root.CFrame
			for j = 1, 6 do
				task.delay((j - 1) * 0.045, function()
					if target and target.Parent then
						VFXStudioLibrary.PulseTargetHighlight(
							target,
							(j % 2 == 1) and PAL.HotWhite or PAL.Obsidian,
							(j % 2 == 1) and c1 or PAL.Obsidian,
							0.06
						)
						if root and root.Parent and baseCF then
							root.CFrame = baseCF * CFrame.new((math.random() - 0.5) * 0.85, (math.random() - 0.5) * 0.45, (math.random() - 0.5) * 0.85)
						end
					end
				end)
			end
			task.delay(0.28, function()
				if target and target.Parent then
					VFXStudioLibrary.PulseTargetHighlight(target, PAL.Obsidian, c2, 0.65)
					if root and root.Parent and baseCF then
						root.CFrame = baseCF
					end
				end
			end)
		end

		-- Khói đen bốc lên từ mục tiêu bị giật sét cháy đen
		local smokeCount = VFXStudioLibrary.IsLowFX() and 4 or 7
		for sm = 1, smokeCount do
			task.delay(0.12 + (sm - 1) * 0.055, function()
				local puff = VFXStudioLibrary.MakePart(
					"LightningCharSmoke_" .. sm,
					Enum.PartType.Ball,
					Vector3.new(1.1, 1.1, 1.1) * sc,
					CFrame.new(charCenter + Vector3.new((math.random() - 0.5) * 2.2 * sc, 0.5, (math.random() - 0.5) * 2.2 * sc)),
					PAL.Obsidian,
					0.22,
					Enum.Material.Slate,
					folder
				)
				TweenService:Create(puff, TweenInfo.new(0.75, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
					Position = puff.Position + Vector3.new((math.random() - 0.5) * 1.8, 5.4 * sc, (math.random() - 0.5) * 1.8),
					Size = Vector3.new(2.8, 2.8, 2.8) * sc,
					Transparency = 1,
				}):Play()
				Debris:AddItem(puff, 0.80)
			end)
		end
	end
end

-- ============================================================================
-- 6. PHÉP TRỌNG LỰC - 5 BƯỚC (VIBEGG ẢNH 1: VÒNG BÁO -> VỆT ĐỔ XUỐNG ->
--    ĐÈ BẸP 55% -> ĐẤT LÚN TIA NỨT -> DỪNG 3 FRAME & LẮC + BẸP NHƯ TỜ GIẤY)
-- ============================================================================
function VFXStudioLibrary.VibeGG_GravitySpell5Steps(targetPos, scale, isOvercrushFinisher, isLocal, ignoreChar)
	local cfg = VFXStudioLibrary.VibeGGConfig.GravitySpell
	local sc = math.clamp(tonumber(scale) or 1, 0.65, 2.5)
	local folder = VFXStudioLibrary.GetTempFolder("UniversalVFX")
	local target = VFXStudioLibrary.FindNearestTargetModel(targetPos, 15 * sc, ignoreChar)
	local centerPos = (target and target:FindFirstChild("HumanoidRootPart") and target.HumanoidRootPart.Position) or targetPos
	local gPos = VFXStudioLibrary.FindGround(centerPos, ignoreChar)
	local teleDur = isStepEnabled("GravitySpell", "Step1_TelegraphRing") and cfg.TelegraphDuration or 0.04

	-- Bước 1: Vòng báo (Vòng phép tím hiện dưới chân mục tiêu, xoay chậm ~0.5 giây trước khi đè)
	if isStepEnabled("GravitySpell", "Step1_TelegraphRing") then
		local outerRing = VFXStudioLibrary.MakePart("Gravity_TelegraphRing", Enum.PartType.Cylinder, Vector3.new(0.14, 2.4 * sc, 2.4 * sc), CFrame.new(gPos + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.pi * 0.5), PAL.Gravity, 0.14, Enum.Material.ForceField, folder)
		local innerRing = VFXStudioLibrary.MakePart("Gravity_TelegraphInner", Enum.PartType.Cylinder, Vector3.new(0.18, 1.4 * sc, 1.4 * sc), CFrame.new(gPos + Vector3.new(0, 0.15, 0)) * CFrame.Angles(0, 0, math.pi * 0.5), PAL.Violet, 0.18, Enum.Material.ForceField, folder)
		VFXStudioLibrary.SafeLight(outerRing, PAL.Gravity, 1.25, 14, teleDur + 0.2)
		TweenService:Create(outerRing, TweenInfo.new(teleDur, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.14, 13.5 * sc, 13.5 * sc),
		}):Play()
		TweenService:Create(innerRing, TweenInfo.new(teleDur, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.18, 8.2 * sc, 8.2 * sc),
		}):Play()

		local runes = {}
		for r = 1, 4 do
			local bar = VFXStudioLibrary.MakePart("Gravity_RuneSpoke_" .. r, Enum.PartType.Block, Vector3.new(0.24 * sc, 0.12, 11.2 * sc), CFrame.new(gPos + Vector3.new(0, 0.16, 0)) * CFrame.Angles(0, (r - 1) * (math.pi * 0.25), 0), PAL.HotWhite, 0.22, Enum.Material.ForceField, folder)
			table.insert(runes, bar)
			Debris:AddItem(bar, teleDur + 0.15)
		end
		local t0 = os.clock()
		local conn
		conn = RunService.Heartbeat:Connect(function(dt)
			if os.clock() - t0 >= teleDur then
				conn:Disconnect()
				return
			end
			for _, bar in ipairs(runes) do
				if bar.Parent then
					bar.CFrame = bar.CFrame * CFrame.Angles(0, dt * 1.45, 0)
				end
			end
		end)
		Debris:AddItem(outerRing, teleDur + 0.15)
		Debris:AddItem(innerRing, teleDur + 0.15)
	end

	-- Sau ~0.5s vòng báo: Cột sáng tím + Vệt đổ xuống + Đè bẹp + Đất lún + Dừng 3 frame & Lắc
	task.delay(teleDur, function()
		local curTarget = target and target.Parent and target or VFXStudioLibrary.FindNearestTargetModel(gPos, 15 * sc, ignoreChar)
		local root, curGround, modelParts = getModelPivotAndParts(curTarget)
		local hitGround = curGround or gPos

		-- Bước 2: Vệt đổ xuống (Một cột sáng tím và nhiều vệt mảnh lao từ trên cao xuống mục tiêu)
		if isStepEnabled("GravitySpell", "Step2_DownwardStreaks") then
			local pillarH = 28 * sc
			local pillar = VFXStudioLibrary.MakePart(
				"Gravity_CrushPillar",
				Enum.PartType.Cylinder,
				Vector3.new(pillarH, 9.5 * sc, 9.5 * sc),
				CFrame.new(hitGround + Vector3.new(0, pillarH * 0.5, 0)) * CFrame.Angles(0, 0, math.pi * 0.5),
				PAL.Gravity,
				0.22,
				Enum.Material.ForceField,
				folder
			)
			local corePillar = VFXStudioLibrary.MakePart(
				"Gravity_CrushPillarCore",
				Enum.PartType.Cylinder,
				Vector3.new(pillarH, 4.2 * sc, 4.2 * sc),
				pillar.CFrame,
				PAL.Violet,
				0.14,
				Enum.Material.ForceField,
				folder
			)
			TweenService:Create(pillar, TweenInfo.new(0.38, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = Vector3.new(pillarH, 14.5 * sc, 14.5 * sc),
				Transparency = 1,
			}):Play()
			TweenService:Create(corePillar, TweenInfo.new(0.30, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = Vector3.new(pillarH, 0.4, 0.4),
				Transparency = 1,
			}):Play()
			Debris:AddItem(pillar, 0.42)
			Debris:AddItem(corePillar, 0.34)

			local streakCount = VFXStudioLibrary.IsLowFX() and 6 or 12
			for s = 1, streakCount do
				local ang = (s - 1) * ((math.pi * 2) / streakCount) + (math.random() - 0.5) * 0.25
				local rOff = (1.2 + (s % 3) * 1.85) * sc
				local topPos = hitGround + Vector3.new(math.cos(ang) * rOff, (20 + (s % 4) * 3.5) * sc, math.sin(ang) * rOff)
				local botPos = hitGround + Vector3.new(math.cos(ang) * rOff, 1.2 * sc, math.sin(ang) * rOff)
				local streak = VFXStudioLibrary.MakePart(
					"Gravity_DownStreak_" .. s,
					Enum.PartType.Block,
					Vector3.new(0.16 * sc, 6.8 * sc, 0.16 * sc),
					CFrame.new(topPos),
					(s % 2 == 0) and PAL.HotWhite or PAL.Gravity,
					0.04,
					Enum.Material.ForceField,
					folder
				)
				TweenService:Create(streak, TweenInfo.new(0.14, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
					Position = botPos,
					Size = Vector3.new(0.06, 2.2 * sc, 0.06),
					Transparency = 0.85,
				}):Play()
				Debris:AddItem(streak, 0.18)
			end
		end

		-- Bước 3 & Finisher: Đè bẹp mục tiêu (Còn ~55% chiều cao, bè ra 2 bên rồi bật lại;
		-- nếu Đè quá mạnh / Finisher thì bẹp mỏng như tờ giấy 10% rồi bật vọt lên!)
		if isStepEnabled("GravitySpell", "Step3_SquashAndStretch") then
			local targetYRatio = (isOvercrushFinisher and isStepEnabled("GravitySpell", "Finisher_PaperFlatBounce")) and cfg.PaperFlatYRatio or cfg.SquashYRatio
			local targetXZRatio = (isOvercrushFinisher and isStepEnabled("GravitySpell", "Finisher_PaperFlatBounce")) and cfg.PaperFlatXZRatio or cfg.SquashXZRatio

			if curTarget and modelParts and #modelParts > 0 then
				VFXStudioLibrary.PulseTargetHighlight(curTarget, PAL.Gravity, PAL.HotWhite, 0.35)
				for _, entry in ipairs(modelParts) do
					local p = entry.Part
					if p and p.Parent then
						local newRel = Vector3.new(entry.RelFromGround.X * targetXZRatio, entry.RelFromGround.Y * targetYRatio, entry.RelFromGround.Z * targetXZRatio)
						TweenService:Create(p, TweenInfo.new(0.09, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
							Size = Vector3.new(entry.OrigSize.X * targetXZRatio, math.max(0.08, entry.OrigSize.Y * targetYRatio), entry.OrigSize.Z * targetXZRatio),
							Position = hitGround + newRel,
						}):Play()
					end
				end

				-- Giữ trạng thái bẹp trong 3 frame hit-stop + 0.16s rồi bật nảy đàn hồi lại!
				task.delay(0.24, function()
					if isOvercrushFinisher and isStepEnabled("GravitySpell", "Finisher_PaperFlatBounce") then
						-- Bẹp như tờ giấy rồi bật vọt lên cao!
						for _, entry in ipairs(modelParts) do
							local p = entry.Part
							if p and p.Parent then
								local stretchRel = Vector3.new(entry.RelFromGround.X * 0.82, entry.RelFromGround.Y * 1.25 + 6.8 * sc, entry.RelFromGround.Z * 0.82)
								TweenService:Create(p, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
									Size = Vector3.new(entry.OrigSize.X * 0.85, entry.OrigSize.Y * 1.22, entry.OrigSize.Z * 0.85),
									Position = hitGround + stretchRel,
								}):Play()
							end
						end
						task.delay(0.24, function()
							for _, entry in ipairs(modelParts) do
								local p = entry.Part
								if p and p.Parent then
									TweenService:Create(p, TweenInfo.new(0.22, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
										Size = entry.OrigSize,
										Position = hitGround + entry.RelFromGround,
									}):Play()
								end
							end
						end)
					else
						-- Đè 55% rồi đàn hồi trở lại 100%
						for _, entry in ipairs(modelParts) do
							local p = entry.Part
							if p and p.Parent then
								TweenService:Create(p, TweenInfo.new(0.26, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
									Size = entry.OrigSize,
									Position = hitGround + entry.RelFromGround,
								}):Play()
							end
						end
					end
				end)
			else
				-- Nếu đánh xuống mặt đất trống, tạo khối cầu trọng lực bị đè bẹp 55% / tờ giấy rồi bật lên để vẫn thấy rõ hiệu ứng!
				local proxy = VFXStudioLibrary.MakePart("Gravity_SquashProxy", Enum.PartType.Ball, Vector3.new(4.2, 4.2, 4.2) * sc, CFrame.new(hitGround + Vector3.new(0, 2.1 * sc, 0)), PAL.Gravity, 0.14, Enum.Material.ForceField, folder)
				TweenService:Create(proxy, TweenInfo.new(0.09, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					Size = Vector3.new(4.2 * targetXZRatio, 4.2 * targetYRatio, 4.2 * targetXZRatio) * sc,
					Position = hitGround + Vector3.new(0, 2.1 * targetYRatio * sc, 0),
				}):Play()
				task.delay(0.24, function()
					if proxy and proxy.Parent then
						TweenService:Create(proxy, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
							Size = Vector3.new(3.2, 5.4, 3.2) * sc,
							Position = hitGround + Vector3.new(0, (isOvercrushFinisher and 8.5 or 3.6) * sc, 0),
							Transparency = 1,
						}):Play()
					end
				end)
				Debris:AddItem(proxy, 0.58)
			end
		end

		-- Bước 4: Đất lún (Mặt đất lún thành hố, có vết nứt hình tia và đá vụn văng ra)
		if isStepEnabled("GravitySpell", "Step4_CraterAndRadialCracks") then
			local craterPit = VFXStudioLibrary.MakePart(
				"Gravity_DepressedCrater",
				Enum.PartType.Cylinder,
				Vector3.new(0.18, 2.0 * sc, 2.0 * sc),
				CFrame.new(hitGround + Vector3.new(0, 0.04, 0)) * CFrame.Angles(0, 0, math.pi * 0.5),
				PAL.Obsidian,
				0.08,
				Enum.Material.Slate,
				folder
			)
			TweenService:Create(craterPit, TweenInfo.new(0.16, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = Vector3.new(0.18, 11.8 * sc, 11.8 * sc),
			}):Play()
			task.delay(0.95, function()
				if craterPit and craterPit.Parent then
					TweenService:Create(craterPit, TweenInfo.new(0.45), { Transparency = 1 }):Play()
				end
			end)
			Debris:AddItem(craterPit, 1.45)

			local rayCount = VFXStudioLibrary.IsLowFX() and 5 or 8
			for r = 1, rayCount do
				local ang = (r - 1) * ((math.pi * 2) / rayCount)
				local dirVec = Vector3.new(math.cos(ang), 0, math.sin(ang))
				local crackRay = VFXStudioLibrary.MakePart(
					"Gravity_RadialCrack_" .. r,
					Enum.PartType.Block,
					Vector3.new(0.22 * sc, 0.10, 1.2 * sc),
					VFXStudioLibrary.SafeLookAt(hitGround + dirVec * (1.5 * sc) + Vector3.new(0, 0.08, 0), hitGround + dirVec * (8.5 * sc) + Vector3.new(0, 0.08, 0), dirVec),
					(r % 2 == 0) and PAL.Gravity or PAL.Obsidian,
					0.06,
					(r % 2 == 0) and Enum.Material.ForceField or Enum.Material.Slate,
					folder
				)
				TweenService:Create(crackRay, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					Size = Vector3.new(0.26 * sc, 0.10, 8.6 * sc),
					Position = hitGround + dirVec * (4.8 * sc) + Vector3.new(0, 0.08, 0),
				}):Play()
				task.delay(0.75, function()
					if crackRay and crackRay.Parent then
						TweenService:Create(crackRay, TweenInfo.new(0.35), { Transparency = 1 }):Play()
					end
				end)
				Debris:AddItem(crackRay, 1.15)

				-- Đá vụn văng ra từ hố lún
				local rock = VFXStudioLibrary.MakePart(
					"Gravity_CraterRock_" .. r,
					Enum.PartType.Wedge,
					Vector3.new(0.95, 0.75, 1.25) * sc,
					CFrame.new(hitGround + dirVec * (2.4 * sc) + Vector3.new(0, 0.2, 0)),
					(r % 3 == 0) and PAL.Violet or PAL.Slate,
					0.04,
					Enum.Material.Slate,
					folder
				)
				TweenService:Create(rock, TweenInfo.new(0.46, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					CFrame = CFrame.new(hitGround + dirVec * (7.5 * sc) + Vector3.new(0, 1.8 * sc, 0)) * CFrame.Angles(math.random() * 5, math.random() * 5, math.random() * 5),
					Size = rock.Size * 0.35,
					Transparency = 1,
				}):Play()
				Debris:AddItem(rock, 0.50)
			end
		end

		-- Bước 5: Dừng và lắc (Lúc chạm đáy đứng hình 3 frame ~0.05s, rồi lắc màn hình mạnh và có vòng sóng lan ra)
		if isStepEnabled("GravitySpell", "Step5_HitStop3FramesAndShake") then
			if isLocal then
				VFXStudioLibrary.TriggerLocalHitStop(cfg.HitStop3Frames)
			end
			task.delay(cfg.HitStop3Frames, function()
				if isLocal then
					VFXStudioLibrary.EmitCameraTrauma(isOvercrushFinisher and 0.62 or 0.48, isOvercrushFinisher and 4.8 or 3.2, Vector3.new(0, -1, 0))
				end
				VFXStudioLibrary.SpawnShockRing(hitGround + Vector3.new(0, 0.22, 0), nil, PAL.Gravity, 2.0 * sc, 18.5 * sc, 0.38, 0.46, Enum.Material.ForceField, folder)
				VFXStudioLibrary.SpawnShockRing(hitGround + Vector3.new(0, 0.45, 0), nil, PAL.HotWhite, 1.4 * sc, 13.5 * sc, 0.22, 0.36, Enum.Material.ForceField, folder)
				VFXStudioLibrary.Emit("Elements", "Elem_Gravity", CFrame.new(hitGround + Vector3.new(0, 1.0, 0)), sc * 1.3, PAL.Gravity, PAL.Violet)
			end)
		end
	end)
end

-- ============================================================================
-- 7. PHÉP DUNG NHAM - 5 BƯỚC (VIBEGG ẢNH 2: VẾT NỨT ĐỎ 0.6S -> ĐẤT NHÔ VÒM ĐÁ ->
--    GIỌT BẮN NGUỘI THÀNH ĐEN -> VŨNG NÓNG BONG BÓNG & CHÌM TỚI THẮT LƯNG ->
--    KHÓI ĐEN & TÀN LỬA + BỎNG CHÂN NHẢY TƯNG TƯNG)
-- ============================================================================
function VFXStudioLibrary.VibeGG_MagmaSpell5Steps(targetPos, scale, isHotFootFinisher, isLocal, ignoreChar)
	local cfg = VFXStudioLibrary.VibeGGConfig.MagmaSpell
	local sc = math.clamp(tonumber(scale) or 1, 0.65, 2.5)
	local folder = VFXStudioLibrary.GetTempFolder("UniversalVFX")
	local target = VFXStudioLibrary.FindNearestTargetModel(targetPos, 15 * sc, ignoreChar)
	local centerPos = (target and target:FindFirstChild("HumanoidRootPart") and target.HumanoidRootPart.Position) or targetPos
	local gPos = VFXStudioLibrary.FindGround(centerPos, ignoreChar)
	local preDur = isStepEnabled("MagmaSpell", "Step1_RedFissuresPreTremor") and cfg.PreCrackDuration or 0.04

	-- Bước 1: Vết nứt đỏ (Khoảng 0.6 giây trước, vết nứt cam sáng dần lan ra dưới chân mục tiêu, đất rung nhẹ)
	if isStepEnabled("MagmaSpell", "Step1_RedFissuresPreTremor") then
		if isLocal then
			VFXStudioLibrary.EmitCameraTrauma(0.16, 0)
		end
		local crackCount = VFXStudioLibrary.IsLowFX() and 5 or 8
		for c = 1, crackCount do
			local ang = (c - 1) * ((math.pi * 2) / crackCount) + (math.random() - 0.5) * 0.22
			local dirVec = Vector3.new(math.cos(ang), 0, math.sin(ang))
			local fissure = VFXStudioLibrary.MakePart(
				"Magma_PreFissure_" .. c,
				Enum.PartType.Block,
				Vector3.new(0.16 * sc, 0.10, 0.8 * sc),
				VFXStudioLibrary.SafeLookAt(gPos + dirVec * (0.8 * sc) + Vector3.new(0, 0.06, 0), gPos + dirVec * (7.5 * sc) + Vector3.new(0, 0.06, 0), dirVec),
				PAL.Magma,
				0.35,
				Enum.Material.ForceField,
				folder
			)
			TweenService:Create(fissure, TweenInfo.new(preDur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = Vector3.new(0.34 * sc, 0.12, 8.2 * sc),
				Position = gPos + dirVec * (4.2 * sc) + Vector3.new(0, 0.07, 0),
				Color = PAL.Gold,
				Transparency = 0.02,
			}):Play()
			Debris:AddItem(fissure, preDur + 0.35)
		end
	end

	-- Sau ~0.6s vết nứt đỏ: Đất nhô lên thành vòm đá rồi vỡ tung -> Giọt bắn -> Vũng nóng -> Khói & Tàn lửa
	task.delay(preDur, function()
		local curTarget = target and target.Parent and target or VFXStudioLibrary.FindNearestTargetModel(gPos, 15 * sc, ignoreChar)
		local root, curGround, modelParts = getModelPivotAndParts(curTarget)
		local hitGround = curGround or gPos

		-- Bước 2: Đất nhô lên (Đất nhô thành vòm đá bao lấy chân mục tiêu, vân cam nóng dần, rồi vỡ tung thành vòng dung nham và mảnh đá)
		local domeBreakDelay = 0.24
		if isStepEnabled("MagmaSpell", "Step2_RockDomeEruption") then
			local rockDome = VFXStudioLibrary.MakePart(
				"Magma_RockDome",
				Enum.PartType.Ball,
				Vector3.new(2.2, 0.6, 2.2) * sc,
				CFrame.new(hitGround + Vector3.new(0, 0.2, 0)),
				PAL.Slate,
				0.04,
				Enum.Material.Slate,
				folder
			)
			local veinDome = VFXStudioLibrary.MakePart(
				"Magma_DomeOrangeVeins",
				Enum.PartType.Ball,
				Vector3.new(2.35, 0.65, 2.35) * sc,
				CFrame.new(hitGround + Vector3.new(0, 0.22, 0)),
				PAL.Magma,
				0.32,
				Enum.Material.ForceField,
				folder
			)
			TweenService:Create(rockDome, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = Vector3.new(7.4, 4.6, 7.4) * sc,
				Position = hitGround + Vector3.new(0, 1.5 * sc, 0),
			}):Play()
			TweenService:Create(veinDome, TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				Size = Vector3.new(7.65, 4.8, 7.65) * sc,
				Position = hitGround + Vector3.new(0, 1.55 * sc, 0),
				Color = PAL.Gold,
				Transparency = 0.04,
			}):Play()

			task.delay(domeBreakDelay, function()
				if rockDome and rockDome.Parent then rockDome:Destroy() end
				if veinDome and veinDome.Parent then veinDome:Destroy() end
				if isLocal then
					VFXStudioLibrary.EmitCameraTrauma(0.44, 3.0)
				end
				VFXStudioLibrary.Emit("Elements", "Elem_Magma", CFrame.new(hitGround + Vector3.new(0, 1.2, 0)), sc * 1.35, PAL.Magma, PAL.Gold)
				VFXStudioLibrary.SpawnShockRing(hitGround + Vector3.new(0, 0.25, 0), nil, PAL.Magma, 2.2 * sc, 15.5 * sc, 0.36, 0.44, Enum.Material.ForceField, folder)
				VFXStudioLibrary.SpawnShockRing(hitGround + Vector3.new(0, 0.45, 0), nil, PAL.Gold, 1.6 * sc, 11.2 * sc, 0.24, 0.36, Enum.Material.ForceField, folder)

				local fragCount = VFXStudioLibrary.IsLowFX() and 5 or 8
				for f = 1, fragCount do
					local fAng = (f - 1) * ((math.pi * 2) / fragCount)
					local fDir = Vector3.new(math.cos(fAng), 0.55, math.sin(fAng)).Unit
					local frag = VFXStudioLibrary.MakePart("MagmaDomeRockFrag_" .. f, Enum.PartType.Wedge, Vector3.new(1.1, 0.9, 1.4) * sc, CFrame.new(hitGround + Vector3.new(0, 1.4 * sc, 0)), (f % 2 == 0) and PAL.Slate or PAL.Obsidian, 0.04, Enum.Material.Slate, folder)
					TweenService:Create(frag, TweenInfo.new(0.44, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
						CFrame = CFrame.new(hitGround + fDir * (7.8 * sc)) * CFrame.Angles(math.random() * 6, math.random() * 6, 0),
						Size = frag.Size * 0.3,
						Transparency = 1,
					}):Play()
					Debris:AddItem(frag, 0.48)
				end
			end)
			Debris:AddItem(rockDome, domeBreakDelay + 0.1)
			Debris:AddItem(veinDome, domeBreakDelay + 0.1)
		else
			domeBreakDelay = 0.02
		end

		task.delay(domeBreakDelay, function()
			-- Bước 3: Giọt bắn (Cục dung nham bay vòng cung, chạm đất bẹp thành vệt rồi nguội dần thành đen)
			if isStepEnabled("MagmaSpell", "Step3_ParabolicLavaSplats") then
				local globCount = VFXStudioLibrary.IsLowFX() and 4 or 8
				for g = 1, globCount do
					local ang = (g - 1) * ((math.pi * 2) / globCount) + (math.random() - 0.5) * 0.35
					local dist = (4.5 + math.random() * 5.2) * sc
					local startG = hitGround + Vector3.new(0, 1.6 * sc, 0)
					local endG = VFXStudioLibrary.FindGround(hitGround + Vector3.new(math.cos(ang) * dist, 2, math.sin(ang) * dist), ignoreChar)
					local glob = VFXStudioLibrary.MakePart("Magma_LavaGlob_" .. g, Enum.PartType.Ball, Vector3.new(0.95, 0.95, 0.95) * sc, CFrame.new(startG), PAL.Gold, 0.04, Enum.Material.ForceField, folder)
					local arcDur = 0.34 + (g % 3) * 0.05
					local t0 = os.clock()
					local conn
					conn = RunService.Heartbeat:Connect(function()
						local a = math.clamp((os.clock() - t0) / arcDur, 0, 1)
						local p = startG:Lerp(endG, a) + Vector3.new(0, math.sin(a * math.pi) * (3.8 * sc), 0)
						if glob.Parent then
							glob.CFrame = CFrame.new(p)
						end
						if a >= 1 then
							conn:Disconnect()
							if glob.Parent then glob:Destroy() end
							-- Chạm đất bẹp thành vệt rồi nguội dần từ Cam -> Đỏ -> Đen!
							local splat = VFXStudioLibrary.MakePart(
								"Magma_CoolingSplat_" .. g,
								Enum.PartType.Cylinder,
								Vector3.new(0.12, 0.8 * sc, 0.8 * sc),
								CFrame.new(endG + Vector3.new(0, 0.06, 0)) * CFrame.Angles(0, 0, math.pi * 0.5),
								PAL.Solar,
								0.06,
								Enum.Material.ForceField,
								folder
							)
							TweenService:Create(splat, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
								Size = Vector3.new(0.10, 2.6 * sc, 2.6 * sc),
								Color = PAL.Magma,
							}):Play()
							task.delay(0.16, function()
								if splat and splat.Parent then
									splat.Material = Enum.Material.Slate
									TweenService:Create(splat, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
										Color = PAL.Obsidian,
									}):Play()
								end
							end)
							task.delay(0.95, function()
								if splat and splat.Parent then
									TweenService:Create(splat, TweenInfo.new(0.40), { Transparency = 1 }):Play()
								end
							end)
							Debris:AddItem(splat, 1.40)
						end
					end)
					Debris:AddItem(glob, arcDur + 0.1)
				end
			end

			-- Bước 4: Vũng nóng (Vũng dung nham quanh chân mục tiêu, sáng nhấp nháy, nổi bong bóng rồi vỡ; mục tiêu chìm tới thắt lưng)
			local poolLife = 1.65
			if isStepEnabled("MagmaSpell", "Step4_BubblingPoolWaistSink") then
				local outerPool = VFXStudioLibrary.MakePart(
					"Magma_LavaPoolOuter",
					Enum.PartType.Cylinder,
					Vector3.new(0.16, 2.4 * sc, 2.4 * sc),
					CFrame.new(hitGround + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, 0, math.pi * 0.5),
					PAL.Magma,
					0.08,
					Enum.Material.ForceField,
					folder
				)
				local innerPool = VFXStudioLibrary.MakePart(
					"Magma_LavaPoolCore",
					Enum.PartType.Cylinder,
					Vector3.new(0.20, 1.6 * sc, 1.6 * sc),
					CFrame.new(hitGround + Vector3.new(0, 0.11, 0)) * CFrame.Angles(0, 0, math.pi * 0.5),
					PAL.Gold,
					0.10,
					Enum.Material.ForceField,
					folder
				)
				VFXStudioLibrary.SafeLight(innerPool, PAL.Solar, 1.40, 15, poolLife)
				TweenService:Create(outerPool, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					Size = Vector3.new(0.16, 11.2 * sc, 11.2 * sc),
				}):Play()
				TweenService:Create(innerPool, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					Size = Vector3.new(0.20, 7.6 * sc, 7.6 * sc),
				}):Play()

				-- Sáng nhấp nháy + Nổi bong bóng dung nham rồi vỡ
				local bubCount = VFXStudioLibrary.IsLowFX() and 4 or 7
				for b = 1, bubCount do
					task.delay((b - 1) * 0.18, function()
						if innerPool and innerPool.Parent then
							innerPool.Color = (b % 2 == 0) and PAL.Gold or PAL.Solar
						end
						local bAng = math.random() * math.pi * 2
						local bRad = math.random() * 3.8 * sc
						local bPos = hitGround + Vector3.new(math.cos(bAng) * bRad, 0.18, math.sin(bAng) * bRad)
						local bubble = VFXStudioLibrary.MakePart("Magma_LavaBubble_" .. b, Enum.PartType.Ball, Vector3.new(0.25, 0.25, 0.25) * sc, CFrame.new(bPos), (b % 2 == 0) and PAL.Gold or PAL.Magma, 0.08, Enum.Material.ForceField, folder)
						TweenService:Create(bubble, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							Size = Vector3.new(1.35, 1.35, 1.35) * sc,
							Position = bPos + Vector3.new(0, 0.45 * sc, 0),
						}):Play()
						task.delay(0.24, function()
							if bubble and bubble.Parent then bubble:Destroy() end
							VFXStudioLibrary.SpawnShockRing(bPos + Vector3.new(0, 0.16, 0), nil, PAL.Gold, 0.4 * sc, 2.2 * sc, 0.12, 0.18, Enum.Material.ForceField, folder)
						end)
						Debris:AddItem(bubble, 0.30)
					end)
				end

				task.delay(poolLife - 0.35, function()
					if outerPool and outerPool.Parent then
						TweenService:Create(outerPool, TweenInfo.new(0.35), { Color = PAL.Obsidian, Transparency = 1 }):Play()
					end
					if innerPool and innerPool.Parent then
						TweenService:Create(innerPool, TweenInfo.new(0.35), { Transparency = 1 }):Play()
					end
				end)
				Debris:AddItem(outerPool, poolLife + 0.1)
				Debris:AddItem(innerPool, poolLife + 0.1)

				-- Mục tiêu chìm tới thắt lưng (-1.85 studs) rồi nhảy tưng tưng vì bỏng chân!
				if curTarget and modelParts and #modelParts > 0 then
					local sinkDepth = cfg.WaistSinkDepth
					VFXStudioLibrary.PulseTargetHighlight(curTarget, PAL.Magma, PAL.Gold, 0.45)
					for _, entry in ipairs(modelParts) do
						local p = entry.Part
						if p and p.Parent then
							TweenService:Create(p, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
								Position = hitGround + entry.RelFromGround - Vector3.new(0, sinkDepth, 0),
							}):Play()
						end
					end

					-- Finisher / Phản ứng đặc biệt: Mục tiêu giẫm phải vũng thì bỏng chân, nhảy tưng tưng!
					task.delay(0.32, function()
						if isHotFootFinisher and isStepEnabled("MagmaSpell", "Finisher_HotFootHopping") then
							VFXStudioLibrary.SpawnPopTextBillboard(hitGround + Vector3.new(0, 3.5, 0), "🔥 BỎNG CHÂN!!", PAL.Solar, PAL.Obsidian, 1.35)
							local hops = cfg.HopCount
							local hopDur = 0.18
							for hIdx = 1, hops do
								task.delay((hIdx - 1) * hopDur, function()
									if curTarget and curTarget.Parent then
										VFXStudioLibrary.PulseTargetHighlight(curTarget, (hIdx % 2 == 1) and PAL.Solar or PAL.Gold, PAL.HotWhite, hopDur * 0.8)
									end
									local jitterXZ = Vector3.new((math.random() - 0.5) * 1.4, 0, (math.random() - 0.5) * 1.4)
									local hopHeight = (2.2 + (hIdx % 2) * 0.8) * sc
									for _, entry in ipairs(modelParts) do
										local p = entry.Part
										if p and p.Parent then
											TweenService:Create(p, TweenInfo.new(hopDur * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
												Position = hitGround + entry.RelFromGround + jitterXZ + Vector3.new(0, hopHeight, 0),
											}):Play()
										end
									end
									VFXStudioLibrary.SpawnShockRing(hitGround + Vector3.new(0, 0.2, 0), nil, PAL.Solar, 0.8 * sc, 3.8 * sc, 0.16, 0.18, Enum.Material.ForceField, folder)
									task.delay(hopDur * 0.5, function()
										for _, entry in ipairs(modelParts) do
											local p = entry.Part
											if p and p.Parent then
												TweenService:Create(p, TweenInfo.new(hopDur * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
													Position = hitGround + entry.RelFromGround,
												}):Play()
											end
										end
									end)
								end)
							end
						else
							-- Trồi lên lại vị trí chuẩn sau khi chìm tới thắt lưng
							task.delay(0.45, function()
								for _, entry in ipairs(modelParts) do
									local p = entry.Part
									if p and p.Parent then
										TweenService:Create(p, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
											Position = hitGround + entry.RelFromGround,
										}):Play()
									end
								end
							end)
						end
					end)
				end
			end

			-- Bước 5: Khói và tàn lửa (Khói đen bốc lên cuồn cuộn, đốm lửa nhỏ bay lượn lên cao)
			if isStepEnabled("MagmaSpell", "Step5_BlackSmokeAndEmbers") then
				local smokeCount = VFXStudioLibrary.IsLowFX() and 4 or 8
				for sm = 1, smokeCount do
					task.delay((sm - 1) * 0.08, function()
						local sAng = math.random() * math.pi * 2
						local sRad = math.random() * 3.6 * sc
						local sOrigin = hitGround + Vector3.new(math.cos(sAng) * sRad, 0.6, math.sin(sAng) * sRad)
						local smoke = VFXStudioLibrary.MakePart("Magma_BillowingBlackSmoke_" .. sm, Enum.PartType.Ball, Vector3.new(1.4, 1.4, 1.4) * sc, CFrame.new(sOrigin), PAL.Obsidian, 0.20, Enum.Material.Slate, folder)
						TweenService:Create(smoke, TweenInfo.new(0.95, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
							Position = sOrigin + Vector3.new((math.random() - 0.5) * 3.2 * sc, (6.5 + math.random() * 3.5) * sc, (math.random() - 0.5) * 3.2 * sc),
							Size = Vector3.new(3.8, 3.8, 3.8) * sc,
							Transparency = 1,
						}):Play()
						Debris:AddItem(smoke, 1.0)
					end)
				end

				local emberCount = VFXStudioLibrary.IsLowFX() and 5 or 10
				for em = 1, emberCount do
					task.delay((em - 1) * 0.06, function()
						local eAng = math.random() * math.pi * 2
						local eRad = math.random() * 4.2 * sc
						local eOrigin = hitGround + Vector3.new(math.cos(eAng) * eRad, 0.4, math.sin(eAng) * eRad)
						local ember = VFXStudioLibrary.MakePart("Magma_WeavingEmber_" .. em, Enum.PartType.Ball, Vector3.new(0.36, 0.36, 0.36) * sc, CFrame.new(eOrigin), (em % 2 == 0) and PAL.Gold or PAL.Solar, 0.04, Enum.Material.ForceField, folder)
						TweenService:Create(ember, TweenInfo.new(0.88, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
							Position = eOrigin + Vector3.new(math.sin(em * 1.7) * 2.8 * sc, (7.8 + math.random() * 4.0) * sc, math.cos(em * 1.7) * 2.8 * sc),
							Size = Vector3.new(0.08, 0.08, 0.08),
							Color = PAL.Magma,
							Transparency = 1,
						}):Play()
						Debris:AddItem(ember, 0.92)
					end)
				end
			end
		end)
	end)
end

-- ============================================================================
-- FADE / HAYMAKER SHOWCASE STUDIO PRIMITIVES:
-- 1. SpawnFadeCorkscrewTunnel (Screenshot 3: Haymaker spiraling crescent rings + central dual-beam + wind shear)
-- 2. SpawnFadeGroundSlashRibbon (Screenshot 2: Ground-hugging razor slash + suspended void/element orbs + wind fins)
-- 3. SpawnFadeJaggedImpactSpikes (Screenshot 1: Tall jagged dark-core spikes + crown crescent arcs + mist curtain)
-- 4. TriggerAnimeImpactFrame (0.04s Anime Showcase Impact Frame + FOV Zoom)
-- 5. PlaySkillCastPose (Dynamic Lunge / Punch / Slam / Sovereign Cast Pose with Token Safety)
-- ============================================================================
function VFXStudioLibrary.SpawnFadeCorkscrewTunnel(startPos, endPos, radius, ringCount, cPrimary, cSecondary, dur, parent)
	local d = dur or 0.42
	local col1 = cPrimary or PAL.Cyan
	local col2 = cSecondary or PAL.HotWhite
	local folder = parent or VFXStudioLibrary.GetTempFolder("UniversalVFX")
	local delta = endPos - startPos
	local dist = math.clamp(delta.Magnitude, 6, 52)
	local dir = (delta.Magnitude > 0.05) and delta.Unit or Vector3.new(0, 0, -1)
	local actualEnd = startPos + dir * dist
	local pathCF = VFXStudioLibrary.SafeLookAt(startPos, actualEnd, dir)
	local r = math.clamp(radius or 3.2, 1.2, 12.0)
	local nRings = VFXStudioLibrary.IsLowFX() and math.max(3, math.floor((ringCount or 6) * 0.5)) or (ringCount or 6)

	-- 1. Central Dual-Layer Piercing Beam (Dark Obsidian outer contrast + Elemental Plasma + Overbright White Core)
	local beamHost = Instance.new("Part")
	beamHost.Name = "HaymakerTunnelBeamHost"
	beamHost.Size = Vector3.new(0.2, 0.2, 0.2)
	beamHost.CFrame = pathCF
	beamHost.Transparency = 1
	beamHost.Anchored = true
	beamHost.CanCollide = false
	beamHost.CanQuery = false
	beamHost.CanTouch = false
	beamHost.Parent = folder

	local aStart = Instance.new("Attachment")
	aStart.Position = Vector3.zero
	aStart.Parent = beamHost
	local aEnd = Instance.new("Attachment")
	aEnd.Position = Vector3.new(0, 0, -dist)
	aEnd.Parent = beamHost

	local function makeTunnelBeam(nm, w0, w1, colSeq, lightEm, bright, c0, c1)
		local b = Instance.new("Beam")
		b.Name = nm
		b.Attachment0 = aStart
		b.Attachment1 = aEnd
		b.Texture = TEX_FIRE_PLASMA
		b.TextureMode = Enum.TextureMode.Stretch
		b.TextureSpeed = 3.6
		b.Segments = 28
		b.Width0 = w0
		b.Width1 = w1
		b.CurveSize0 = c0 or 0
		b.CurveSize1 = c1 or 0
		b.Color = colSeq
		b.LightEmission = lightEm
		b.LightInfluence = 0
		if bright then pcall(function() b.Brightness = bright end) end
		b.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.08),
			NumberSequenceKeypoint.new(0.85, 0.04),
			NumberSequenceKeypoint.new(1, 1),
		})
		b.FaceCamera = true
		b.Parent = beamHost
		TweenService:Create(b, TweenInfo.new(d, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Width0 = 0,
			Width1 = 0,
		}):Play()
		return b
	end

	makeTunnelBeam("DarkContrastBeam", r * 1.15, r * 1.45, ColorSequence.new(PAL.Obsidian), 0, nil, 0, 0)
	makeTunnelBeam("ElementOuterBeam", r * 0.85, r * 1.10, ColorSequence.new({
		ColorSequenceKeypoint.new(0, col2),
		ColorSequenceKeypoint.new(0.5, col1),
		ColorSequenceKeypoint.new(1, PAL.Obsidian),
	}), 1.0, 4.8, 0, 0)
	makeTunnelBeam("RazorWhiteCoreBeam", r * 0.35, r * 0.42, ColorSequence.new(PAL.HotWhite), 1.0, 6.8, 0, 0)

	-- 2. Dual Helical Wind-Shear Ribbon Beams coiling around the central beam
	makeTunnelBeam("HelixShearA", r * 0.32, r * 0.12, ColorSequence.new({
		ColorSequenceKeypoint.new(0, PAL.HotWhite),
		ColorSequenceKeypoint.new(1, col1),
	}), 1.0, 5.2, r * 2.2, -r * 2.2)
	makeTunnelBeam("HelixShearB", r * 0.32, r * 0.12, ColorSequence.new({
		ColorSequenceKeypoint.new(0, col2),
		ColorSequenceKeypoint.new(1, PAL.Obsidian),
	}), 0.85, 4.2, -r * 2.2, r * 2.2)

	Debris:AddItem(beamHost, d + 0.06)

	-- 3. Spiraling Tilted Hollow Crescent Shockwave Rings along the tunnel (Screenshot 3 exact look!)
	for i = 1, nRings do
		local frac = (i - 0.5) / nRings
		task.delay((i - 1) * 0.018, function()
			local ringPos = startPos:Lerp(actualEnd, frac)
			local tiltX = ((i % 2 == 0) and 0.36 or -0.36)
			local tiltY = ((i % 2 == 0) and -0.28 or 0.28)
			local spinZ = i * 1.15
			local ringCF = VFXStudioLibrary.SafeLookAt(ringPos, ringPos + dir, Vector3.yAxis)
				* CFrame.Angles(math.pi * 0.5 + tiltX, tiltY, spinZ)
			local rStart = r * (0.45 + frac * 0.35)
			local rEnd = r * (1.55 + frac * 0.85)
			VFXStudioLibrary.SpawnFadeCrescentArc(ringCF, rStart, rEnd, r * 0.52, col1, col2, d * 0.92, folder)
			VFXStudioLibrary.SpawnFadeCrescentArc(ringCF * CFrame.Angles(0, math.pi * 0.85, 0), rStart * 0.85, rEnd * 0.90, r * 0.38, col2, PAL.HotWhite, d * 0.85, folder)
		end)
	end
end

function VFXStudioLibrary.SpawnFadeGroundSlashRibbon(startPos, endPos, width, cPrimary, cSecondary, dur, parent)
	local d = dur or 0.52
	local col1 = cPrimary or PAL.Cyan
	local col2 = cSecondary or PAL.Violet
	local folder = parent or VFXStudioLibrary.GetTempFolder("UniversalVFX")
	local gStart = VFXStudioLibrary.FindGround(startPos)
	local gEnd = VFXStudioLibrary.FindGround(endPos)
	local delta = gEnd - gStart
	local dist = math.clamp(delta.Magnitude, 6, 54)
	local dir = (delta.Magnitude > 0.05) and delta.Unit or Vector3.new(0, 0, -1)
	local actualEnd = gStart + dir * dist
	local slashCF = VFXStudioLibrary.SafeLookAt(gStart + Vector3.new(0, 0.22, 0), actualEnd + Vector3.new(0, 0.22, 0), dir)
	local w = math.clamp(width or 2.4, 0.8, 7.5)

	-- 1. Razor-Tapered Ground Chasm Cut (Obsidian Dark Core + Neon Edge + White Center Line)
	local midPos = (gStart + actualEnd) * 0.5 + Vector3.new(0, 0.18, 0)
	local midCF = VFXStudioLibrary.SafeLookAt(midPos, actualEnd + Vector3.new(0, 0.18, 0), dir)

	local darkCut = VFXStudioLibrary.MakePart("FadeGroundDarkCut", Enum.PartType.Block, Vector3.new(w * 0.95, 0.16, dist * 1.04), midCF, PAL.Obsidian, 0.04, Enum.Material.SmoothPlastic, folder)
	local smCut = Instance.new("SpecialMesh")
	smCut.MeshType = Enum.MeshType.Sphere
	smCut.Parent = darkCut

	local glowEdge = VFXStudioLibrary.MakePart("FadeGroundGlowCut", Enum.PartType.Block, Vector3.new(w * 1.35, 0.10, dist * 1.08), midCF, col1, 0.10, Enum.Material.ForceField, folder)
	local whiteLine = VFXStudioLibrary.MakePart("FadeGroundWhiteCore", Enum.PartType.Block, Vector3.new(w * 0.36, 0.22, dist * 0.98), midCF, PAL.HotWhite, 0.02, Enum.Material.ForceField, folder)

	TweenService:Create(darkCut, TweenInfo.new(d, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.08, 0.04, dist * 1.08),
		Transparency = 1,
	}):Play()
	TweenService:Create(glowEdge, TweenInfo.new(d * 0.92, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = Vector3.new(w * 2.1, 0.04, dist * 1.12),
		Transparency = 1,
	}):Play()
	TweenService:Create(whiteLine, TweenInfo.new(d * 0.78, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.04, 0.04, dist * 1.02),
		Transparency = 1,
	}):Play()
	Debris:AddItem(darkCut, d + 0.06)
	Debris:AddItem(glowEdge, d + 0.06)
	Debris:AddItem(whiteLine, d + 0.06)

	-- 2. Diagonal Peeling Wind-Smoke Fins & Suspended Void/Elemental Orbs (Screenshot 2 exact look!)
	local orbCount = VFXStudioLibrary.IsLowFX() and 8 or 18
	for i = 1, orbCount do
		local frac = i / orbCount
		local baseP = gStart:Lerp(actualEnd, frac)
		local side = (i % 2 == 0) and 1 or -1
		local lat = (0.4 + math.random() * 1.4) * w * side
		local h0 = 0.35 + math.random() * 1.2
		local spawnP = baseP + slashCF.RightVector * lat + Vector3.new(0, h0, 0)
		local driftP = spawnP + slashCF.RightVector * (side * w * (0.8 + math.random() * 1.2)) + Vector3.new(0, 1.4 + math.random() * 2.8, 0) + dir * 1.8
		local isDarkOrb = (i % 3 ~= 0)
		local orbSz = (0.24 + math.random() * 0.38) * math.clamp(w * 0.45, 0.7, 1.8)
		local orb = VFXStudioLibrary.MakePart(
			isDarkOrb and ("FadeVoidOrb_" .. i) or ("FadeSparkOrb_" .. i),
			Enum.PartType.Ball,
			Vector3.new(orbSz, orbSz, orbSz),
			CFrame.new(spawnP),
			isDarkOrb and PAL.Obsidian or ((i % 2 == 0) and PAL.HotWhite or col1),
			isDarkOrb and 0.04 or 0.02,
			isDarkOrb and Enum.Material.SmoothPlastic or Enum.Material.ForceField,
			folder
		)
		local orbDur = d * (0.85 + math.random() * 0.45)
		TweenService:Create(orb, TweenInfo.new(orbDur, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Position = driftP,
			Size = Vector3.new(0.04, 0.04, 0.04),
			Transparency = 1,
		}):Play()
		Debris:AddItem(orb, orbDur + 0.05)
	end

	-- Peeling Wind-Shear Crescent Fins at 3 points along the ground slash
	for k = 1, 3 do
		local finP = gStart:Lerp(actualEnd, k / 3.2) + Vector3.new(0, 0.8, 0)
		local finCF = VFXStudioLibrary.SafeLookAt(finP, finP + dir, Vector3.yAxis) * CFrame.Angles(0.35, 0, (k % 2 == 0) and 0.45 or -0.45)
		VFXStudioLibrary.SpawnFadeCrescentArc(finCF, w * 0.45, w * 2.1, w * 0.42, col2, PAL.HotWhite, d * 0.75, folder)
	end
end

function VFXStudioLibrary.SpawnFadeJaggedImpactSpikes(centerPos, radius, spikeCount, cPrimary, cSecondary, dur, parent)
	local gPos = VFXStudioLibrary.FindGround(centerPos)
	local r = math.clamp(radius or 10, 4, 32)
	local n = spikeCount or 8
	local d = dur or 0.58
	local folder = parent or VFXStudioLibrary.GetTempFolder("UniversalVFX")
	local col1 = cPrimary or PAL.Cyan
	local col2 = cSecondary or PAL.HotWhite

	-- Spawn Jagged Dark-Core Spikes + Crown Crescent Arcs (Screenshot 1 exact look!)
	VFXStudioLibrary.SpawnShatterCrater(gPos, col1, col2, PAL.Obsidian, r, n, d, folder)

	local arcCount = VFXStudioLibrary.IsLowFX() and 2 or 4
	for a = 1, arcCount do
		local ang = (a / arcCount) * math.pi * 2
		local arcPos = gPos + Vector3.new(math.cos(ang) * r * 0.48, r * 0.42, math.sin(ang) * r * 0.48)
		local arcCF = CFrame.new(arcPos) * CFrame.Angles(0.55, ang, 0.35)
		VFXStudioLibrary.SpawnFadeCrescentArc(arcCF, r * 0.25, r * 0.95, math.clamp(r * 0.16, 0.8, 2.8), col1, PAL.HotWhite, d * 0.88, folder)
	end
end

local lastImpactFrameAt = 0
function VFXStudioLibrary.TriggerAnimeImpactFrame(cPrimary, duration, fovPunch, trauma)
	local lp = Players.LocalPlayer
	if not lp or VFXStudioLibrary.IsLowFX() then return end
	if fovPunch or trauma then
		VFXStudioLibrary.EmitCameraTrauma(trauma or 0.42, fovPunch or 4.5)
	end
	local now = os.clock()
	if (now - lastImpactFrameAt) < 0.22 then return end
	lastImpactFrameAt = now

	local Lighting = game:GetService("Lighting")
	local cc = Lighting:FindFirstChild("SkybreakAnimeImpactCC")
	if not cc then
		cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "SkybreakAnimeImpactCC"
		cc.Parent = Lighting
	end
	local flashDur = math.clamp(duration or 0.045, 0.03, 0.07)
	local col = cPrimary or PAL.HotWhite
	local tint = Color3.new(
		0.82 + col.R * 0.18,
		0.82 + col.G * 0.18,
		0.82 + col.B * 0.18
	)
	cc.Enabled = true
	cc.Contrast = 0.62
	cc.Saturation = 0.28
	cc.Brightness = 0.07
	cc.TintColor = tint

	task.delay(flashDur, function()
		if cc and cc.Parent then
			TweenService:Create(cc, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Contrast = 0,
				Saturation = 0,
				Brightness = 0,
				TintColor = Color3.fromRGB(255, 255, 255),
			}):Play()
		end
	end)
end

function VFXStudioLibrary.PlaySkillCastPose(actorChar, moveKey, dur)
	if not actorChar or not actorChar.Parent then return end
	local upperTorso = actorChar:FindFirstChild("UpperTorso") or actorChar:FindFirstChild("Torso")
	local rootPart = actorChar:FindFirstChild("HumanoidRootPart")
	if not upperTorso or not rootPart then return end

	local waist = upperTorso:FindFirstChild("Waist") or rootPart:FindFirstChild("RootJoint")
	local rArm = actorChar:FindFirstChild("RightUpperArm") or actorChar:FindFirstChild("Right Arm")
	local lArm = actorChar:FindFirstChild("LeftUpperArm") or actorChar:FindFirstChild("Left Arm")
	local rShoulder = (rArm and rArm:FindFirstChild("RightShoulder")) or upperTorso:FindFirstChild("Right Shoulder")
	local lShoulder = (lArm and lArm:FindFirstChild("LeftShoulder")) or upperTorso:FindFirstChild("Left Shoulder")

	local nextToken = (tonumber(actorChar:GetAttribute("SkybreakCastPoseToken")) or 0) + 1
	actorChar:SetAttribute("SkybreakCastPoseToken", nextToken)

	-- Cache base C0s once per rig joint
	local function getBaseC0(motor)
		if not motor or not motor:IsA("Motor6D") then return nil end
		local saved = motor:GetAttribute("SkybreakBaseC0")
		if typeof(saved) ~= "CFrame" then
			saved = motor.C0
			motor:SetAttribute("SkybreakBaseC0", saved)
		end
		return saved
	end

	local wBase = getBaseC0(waist)
	local rBase = getBaseC0(rShoulder)
	local lBase = getBaseC0(lShoulder)
	local d = math.clamp(dur or 0.34, 0.22, 0.55)
	local k = tostring(moveKey or "Z")

	local wOffset = CFrame.Angles(-0.22, -0.32, 0)
	local rOffset = CFrame.new(0, 0.15, -0.35) * CFrame.Angles(math.rad(88), 0, math.rad(-14))
	local lOffset = CFrame.Angles(math.rad(-28), 0, math.rad(-22))

	if k == "X" then
		-- Haymaker Deep Lunge / Two-Hand Surge Pose (Screenshot 2 & 3!)
		wOffset = CFrame.new(0, -0.15, -0.25) * CFrame.Angles(-0.38, 0.42, 0)
		rOffset = CFrame.new(0, 0.2, -0.45) * CFrame.Angles(math.rad(96), math.rad(12), math.rad(-8))
		lOffset = CFrame.new(0, 0.1, -0.25) * CFrame.Angles(math.rad(72), math.rad(-14), math.rad(12))
	elseif k == "C" then
		-- Ground Slam / Wide-Arm Cataclysm Release Pose (Screenshot 1!)
		wOffset = CFrame.new(0, -0.22, 0) * CFrame.Angles(-0.32, 0, 0)
		rOffset = CFrame.Angles(math.rad(110), 0, math.rad(42))
		lOffset = CFrame.Angles(math.rad(110), 0, math.rad(-42))
	elseif k == "V" then
		-- Sovereign Skyward Ultimate Release Pose
		wOffset = CFrame.new(0, 0.25, 0) * CFrame.Angles(0.24, 0, 0)
		rOffset = CFrame.Angles(math.rad(148), 0, math.rad(32))
		lOffset = CFrame.Angles(math.rad(148), 0, math.rad(-32))
	end

	if waist and wBase then
		TweenService:Create(waist, TweenInfo.new(d * 0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { C0 = wBase * wOffset }):Play()
	end
	if rShoulder and rBase then
		TweenService:Create(rShoulder, TweenInfo.new(d * 0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { C0 = rBase * rOffset }):Play()
	end
	if lShoulder and lBase then
		TweenService:Create(lShoulder, TweenInfo.new(d * 0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { C0 = lBase * lOffset }):Play()
	end

	task.delay(d * 0.58, function()
		if not actorChar or not actorChar.Parent then return end
		if actorChar:GetAttribute("SkybreakCastPoseToken") ~= nextToken then return end
		if waist and waist.Parent and wBase then
			TweenService:Create(waist, TweenInfo.new(d * 0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { C0 = wBase }):Play()
		end
		if rShoulder and rShoulder.Parent and rBase then
			TweenService:Create(rShoulder, TweenInfo.new(d * 0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { C0 = rBase }):Play()
		end
		if lShoulder and lShoulder.Parent and lBase then
			TweenService:Create(lShoulder, TweenInfo.new(d * 0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { C0 = lBase }):Play()
		end
	end)
end

return VFXStudioLibrary
