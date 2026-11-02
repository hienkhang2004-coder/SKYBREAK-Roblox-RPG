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

VFXStudioLibrary.MAX_LIGHT_BRIGHTNESS = 1.45
VFXStudioLibrary.MAX_LIGHT_RANGE = 16
VFXStudioLibrary.MAX_PARTICLE_EMISSION = 0.78

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
	p.Name = name or "SkybreakVFXPart"
	p.Shape = shape or Enum.PartType.Block
	p.Size = size or Vector3.new(1, 1, 1)
	p.CFrame = cf or CFrame.new()
	p.Color = color or PAL.Cyan
	p.Material = material or Enum.Material.ForceField
	p.Transparency = math.clamp(transparency or 0.14, 0, 1)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Massless = true
	p.Parent = parent or (VFXStudioLibrary.GetTempFolder("UniversalVFX"))
	return p
end

function VFXStudioLibrary.SafeLight(parent, color, brightness, range, dur)
	if VFXStudioLibrary.IsLowFX() or not parent then return nil end
	local pl = Instance.new("PointLight")
	pl.Color = color or PAL.Gold
	pl.Brightness = math.clamp(brightness or 1.2, 0, VFXStudioLibrary.MAX_LIGHT_BRIGHTNESS)
	pl.Range = math.clamp(range or 13, 2, VFXStudioLibrary.MAX_LIGHT_RANGE)
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
	tr.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color1 or PAL.HotWhite),
		ColorSequenceKeypoint.new(0.5, color2 or color1 or PAL.Cyan),
		ColorSequenceKeypoint.new(1, color3 or PAL.Obsidian),
	})
	tr.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.08),
		NumberSequenceKeypoint.new(0.65, 0.42),
		NumberSequenceKeypoint.new(1, 1),
	})
	tr.WidthScale = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.55, 0.72),
		NumberSequenceKeypoint.new(1, 0),
	})
	tr.LightEmission = math.min(VFXStudioLibrary.MAX_PARTICLE_EMISSION, 0.72)
	tr.LightInfluence = 0.16
	tr.FaceCamera = true
	tr.Lifetime = lifetime or 0.25
	tr.MinLength = 0.05
	tr.Parent = hostPart
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

function VFXStudioLibrary.SpawnShockRing(pos, upCF, color, startR, endR, thickness, dur, mat, parent)
	local baseCF = upCF or CFrame.new(pos)
	local ring = VFXStudioLibrary.MakePart(
		"ShockRing",
		Enum.PartType.Cylinder,
		Vector3.new(thickness or 0.26, startR, startR),
		baseCF * CFrame.Angles(0, 0, math.pi * 0.5),
		color,
		0.14,
		mat or Enum.Material.ForceField,
		parent
	)
	local d = dur or 0.42
	TweenService:Create(ring, TweenInfo.new(d, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = Vector3.new(math.max(0.06, (thickness or 0.26) * 0.3), endR, endR),
		Transparency = 1,
	}):Play()
	Debris:AddItem(ring, d + 0.05)
	return ring
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
			0.05,
			Enum.Material.ForceField,
			parent
		)
		TweenService:Create(bolt, TweenInfo.new(d, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(thickness * 0.15, thickness * 0.15, segLen),
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
		n = math.max(3, math.floor(n * 0.45))
	end
	local d = dur or 0.56
	VFXStudioLibrary.SpawnShockRing(gPos + Vector3.new(0, 0.14, 0), nil, primaryCol, radius * 0.3, radius * 1.45, 0.26, d * 0.85, Enum.Material.ForceField, parent)
	VFXStudioLibrary.SpawnShockRing(gPos + Vector3.new(0, 0.32, 0), nil, secondaryCol or primaryCol, radius * 0.2, radius * 1.05, 0.18, d * 0.72, Enum.Material.ForceField, parent)

	for i = 1, n do
		local ang = (i - 1) * ((math.pi * 2) / n)
		local r0 = radius * 0.42
		local r1 = radius * 0.98
		local p0 = gPos + Vector3.new(math.cos(ang) * r0, -0.25, math.sin(ang) * r0)
		local p1 = gPos + Vector3.new(math.cos(ang) * r1, 0.45, math.sin(ang) * r1)
		local isElem = (i % 2 == 0)
		local shard = VFXStudioLibrary.MakePart(
			"CraterFang_" .. i,
			Enum.PartType.Wedge,
			Vector3.new(1.15, math.clamp(radius * 0.28, 1.4, 5.2), 1.65),
			VFXStudioLibrary.SafeLookAt(p0, gPos + Vector3.new(0, 2.4, 0)) * CFrame.Angles(-0.34, 0, (isElem and 0.18 or -0.18)),
			isElem and primaryCol or (rockCol or PAL.Slate),
			isElem and 0.08 or 0.04,
			isElem and Enum.Material.ForceField or Enum.Material.Slate,
			parent
		)
		TweenService:Create(shard, TweenInfo.new(d * 0.42, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			CFrame = VFXStudioLibrary.SafeLookAt(p1, gPos + Vector3.new(0, 3.4, 0)) * CFrame.Angles(-0.48, 0, 0),
		}):Play()
		task.delay(d * 0.55, function()
			if shard and shard.Parent then
				TweenService:Create(shard, TweenInfo.new(d * 0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Transparency = 1,
					Size = shard.Size * 0.45,
				}):Play()
			end
		end)
		Debris:AddItem(shard, d + 0.06)
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

local function makeStudioEmitter(parent, spec)
	local pe = Instance.new("ParticleEmitter")
	pe.Name = spec[1]
	pe.Enabled = false
	pe.Rate = 0
	pe.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, spec[2]),
		ColorSequenceKeypoint.new(0.52, spec[3]),
		ColorSequenceKeypoint.new(1, spec[4] or PAL.Obsidian),
	})
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, spec[5]),
		NumberSequenceKeypoint.new(0.55, (spec[5] + spec[6]) * 0.52),
		NumberSequenceKeypoint.new(1, spec[6]),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.08),
		NumberSequenceKeypoint.new(0.68, 0.42),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.LightEmission = math.min(VFXStudioLibrary.MAX_PARTICLE_EMISSION, 0.72)
	pe.LightInfluence = 0.20
	pe.Lifetime = NumberRange.new(spec[7], spec[8])
	pe.Speed = NumberRange.new(spec[9], spec[10])
	pe.SpreadAngle = Vector2.new(spec[13] or 180, spec[13] or 180)
	pe.Drag = spec[14] or 3.2
	pe.RotSpeed = NumberRange.new(-140, 140)
	pe.Rotation = NumberRange.new(0, 360)
	pe:SetAttribute("EmitCount", spec[11] or 18)
	pe:SetAttribute("EmitDelay", spec[12] or 0)
	pe:SetAttribute("EmitDuration", 0)
	pe.Parent = parent
	return pe
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
				for _, s in ipairs(emitterList) do
					makeStudioEmitter(att, s)
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

return VFXStudioLibrary
