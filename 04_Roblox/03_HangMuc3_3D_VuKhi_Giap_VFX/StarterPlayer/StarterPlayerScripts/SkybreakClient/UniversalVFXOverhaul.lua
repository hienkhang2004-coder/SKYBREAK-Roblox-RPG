--!nonstrict
-- ============================================================================
-- SKYBREAK: UNIVERSAL GAME-WIDE 3D VFX OVERHAUL ENGINE
-- Overhauls all non-Dragon VFX across SKYBREAK with multi-layered anti-glare
-- 3D geometry (Obsidian dark cores + vibrant ForceField/Glass/Slate edges),
-- live RunService.Heartbeat motion, Trail ribbons, and VFXStudioLibrary prefabs:
--   1. All 11 non-Dragon Devil Fruits x 5 Moves (55 Moves / 16 Archetypes)
--   2. All 6 Martial Arts Fighting Styles (PalmRings, BlazeKickArcs,
--      WaterVortex, VoltClawSlashes, DraconicTalons, GodhumanPrism)
--   3. Melee M1 Combos 1-4 & Heavy Cleave + Sword Waves + Gun Rail-Tracers
--   4. All Class Skills (SkyGuardian, ThunderStriker, ArcaneMage, WorldGate, SeaBeast)
--   5. Hit-Impacts / Crits / Guard-Breaks, Logia Elemental Reflex,
--      Busoshoku Ignition, Haoshoku Conqueror Lightning, Race V4 Awakening
--   6. Geppo Air-Steps, Dash/Dodge/Soru Multi-Limb Afterimages & Mach Cones
--   7. Level-Up / Heal / Shrine Progression, Boss Telegraphs & Boss/Mob Dissolve
-- Strict Anti-Glare Budget:
--   PointLight.Brightness <= 1.45, Range <= 16, ParticleEmitter.LightEmission <= 0.78
-- ============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Lib = require(script.Parent:WaitForChild("VFXStudioLibrary"))
local ExpansionVFX = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SkybreakExpansion3DAndVFX"))
local PAL = Lib.Palette

local UniversalVFXOverhaul = {}

local function animateOver(duration, stepFn, onDone)
	local startAt = os.clock()
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		local alpha = math.clamp((os.clock() - startAt) / math.max(0.01, duration), 0, 1)
		local ok = pcall(stepFn, alpha, dt)
		if not ok or alpha >= 1 then
			if conn then
				conn:Disconnect()
				conn = nil
			end
			if onDone then
				pcall(onDone)
			end
		end
	end)
	return conn
end

-- ============================================================================
-- 1. STAGE 1 RUNIC MANDALA & STAGE 3 SHATTER CRATER / ELEMENTAL PREFAB BURST
-- ============================================================================
function UniversalVFXOverhaul.SpawnStage1Sigil(originCF, prof, scale, isAwakened)
	local sc = math.clamp(scale or 1, 0.65, 2.2)
	local pos = originCF.Position
	local gPos = Lib.FindGround(pos)
	local folder = Lib.GetTempFolder("UniversalVFX")
	local low = Lib.IsLowFX()

	-- High-contrast Obsidian backing disc so glowing rings pop without glare
	local baseDisc = Lib.MakePart(
		"SigilShadowDisc",
		Enum.PartType.Cylinder,
		Vector3.new(0.07, 1.8 * sc, 1.8 * sc),
		CFrame.new(gPos + Vector3.new(0, 0.08, 0)) * CFrame.Angles(0, 0, math.pi * 0.5),
		PAL.Obsidian,
		0.32,
		Enum.Material.SmoothPlastic,
		folder
	)
	local outerRing = Lib.MakePart(
		"SigilOuterRing",
		Enum.PartType.Cylinder,
		Vector3.new(0.13, 2.4 * sc, 2.4 * sc),
		CFrame.new(gPos + Vector3.new(0, 0.13, 0)) * CFrame.Angles(0, 0, math.pi * 0.5),
		prof.Primary,
		0.14,
		Enum.Material.ForceField,
		folder
	)
	local innerRing = Lib.MakePart(
		"SigilInnerRing",
		Enum.PartType.Cylinder,
		Vector3.new(0.16, 1.4 * sc, 1.4 * sc),
		CFrame.new(gPos + Vector3.new(0, 0.17, 0)) * CFrame.Angles(0, 0, math.pi * 0.5),
		prof.Secondary,
		0.18,
		Enum.Material.ForceField,
		folder
	)
	Lib.SafeLight(outerRing, prof.Primary, 1.18, 12, 0.30)

	TweenService:Create(baseDisc, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.04, 6.8 * sc, 6.8 * sc),
		Transparency = 1,
	}):Play()
	TweenService:Create(outerRing, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.06, 7.8 * sc, 7.8 * sc),
		Transparency = 0.88,
	}):Play()
	TweenService:Create(innerRing, TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.08, 4.8 * sc, 4.8 * sc),
		Transparency = 0.92,
	}):Play()
	Debris:AddItem(baseDisc, 0.32)
	Debris:AddItem(outerRing, 0.32)
	Debris:AddItem(innerRing, 0.30)

	local spokeCount = low and 3 or 6
	for i = 1, spokeCount do
		local ang = (i - 1) * (math.pi / spokeCount)
		local bar = Lib.MakePart(
			"SigilRuneBar_" .. i,
			Enum.PartType.Block,
			Vector3.new(0.16 * sc, 0.09, 5.8 * sc),
			CFrame.new(gPos + Vector3.new(0, 0.16, 0)) * CFrame.Angles(0, ang, 0),
			(i % 2 == 0) and prof.Primary or prof.Secondary,
			0.18,
			Enum.Material.ForceField,
			folder
		)
		TweenService:Create(bar, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			CFrame = bar.CFrame * CFrame.Angles(0, (i % 2 == 0) and 0.72 or -0.72, 0),
			Size = Vector3.new(0.06, 0.05, 7.6 * sc),
			Transparency = 1,
		}):Play()
		Debris:AddItem(bar, 0.32)
	end

	-- Native VFX Studio Cast Muzzle Burst at caster origin
	Lib.EmitElement(prof.Element, originCF, math.clamp(sc * 0.85, 0.65, 1.5), prof.Primary, prof.Secondary)

	-- Awakened V2 Dual Tilted Sovereign Corona Halos
	if isAwakened then
		for i = 1, 2 do
			local r = (4.6 + i * 1.9) * sc
			local halo = Lib.MakePart(
				"AwakenedCorona_" .. i,
				Enum.PartType.Cylinder,
				Vector3.new(0.16, r, r),
				originCF * CFrame.Angles(i == 1 and 0.48 or -0.48, i * 0.8, math.pi * 0.5),
				(i == 1) and PAL.Gold or PAL.Cyan,
				0.18,
				Enum.Material.ForceField,
				folder
			)
			TweenService:Create(halo, TweenInfo.new(0.46, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = Vector3.new(0.06, r * 1.85, r * 1.85),
				CFrame = halo.CFrame * CFrame.Angles(0.95, 1.25, 0),
				Transparency = 1,
			}):Play()
			Debris:AddItem(halo, 0.50)
		end
	end
end

function UniversalVFXOverhaul.SpawnStage3Aftermath(impactPos, prof, radius, scale, isAwakened, isLocal)
	local sc = math.clamp(scale or 1, 0.65, 2.2)
	local r = math.clamp((radius or 10) * sc, 5, 34)
	local folder = Lib.GetTempFolder("UniversalVFX")
	local gPos = Lib.FindGround(impactPos)

	Lib.SpawnShatterCrater(impactPos, prof.Primary, prof.Secondary, prof.Accent, r * 0.58, (r >= 18) and 10 or 7, 0.58, folder)
	Lib.SpawnShockRing(gPos + Vector3.new(0, 0.22, 0), nil, prof.Primary, r * 0.22, r * 1.48, 0.28, 0.46, Enum.Material.ForceField, folder)

	-- High-contrast Dark Core + Outer Plasma Shell (zero whitewash)
	local darkCore = Lib.MakePart("AftermathDarkCore", Enum.PartType.Ball, Vector3.new(1.5, 1.5, 1.5) * sc, CFrame.new(impactPos), PAL.Obsidian, 0.14, Enum.Material.SmoothPlastic, folder)
	local plasmaShell = Lib.MakePart("AftermathShell", Enum.PartType.Ball, Vector3.new(2.3, 2.3, 2.3) * sc, CFrame.new(impactPos), prof.Primary, 0.20, Enum.Material.ForceField, folder)
	Lib.SafeLight(plasmaShell, prof.Primary, 1.38, math.min(Lib.MAX_LIGHT_RANGE, r), 0.44)

	TweenService:Create(darkCore, TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = Vector3.new(r * 0.52, r * 0.52, r * 0.52),
		Transparency = 1,
	}):Play()
	TweenService:Create(plasmaShell, TweenInfo.new(0.44, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = Vector3.new(r * 1.02, r * 1.02, r * 1.02),
		Transparency = 1,
	}):Play()
	Debris:AddItem(darkCore, 0.36)
	Debris:AddItem(plasmaShell, 0.48)

	-- Native VFX Studio Prefab Elemental Burst + FADE Atmospheric Wind-Smoke & 1.75s Lingering Ground Aftermath
	Lib.EmitElement(prof.Element, CFrame.new(impactPos), math.clamp(r / 12, 0.8, 1.85), prof.Primary, prof.Secondary)
	Lib.SpawnFadeAtmosphericWindSmoke(impactPos, impactPos + CFrame.Angles(0, math.random() * math.pi * 2, 0).LookVector * r * 0.65, r * 0.65, prof.Primary, 0.65, folder)
	Lib.SpawnLingeringGroundAftermath(impactPos, r * 0.68, prof.Element, prof.Primary, prof.Secondary, folder)

	if isAwakened then
		Lib.SpawnShockRing(CFrame.new(impactPos).Position, CFrame.new(impactPos) * CFrame.Angles(0.42, 0.6, 0), PAL.Gold, r * 0.35, r * 1.65, 0.22, 0.50, Enum.Material.ForceField, folder)
	end
	if isLocal then
		local trauma = (r >= 20) and 0.56 or ((r >= 12) and 0.36 or 0.24)
		local fov = (r >= 20) and 5.2 or 2.0
		Lib.EmitCameraTrauma(trauma, fov)
	end
end

-- ============================================================================
-- 2. FADE / HAYMAKER CURVED CRESCENT WAVE & RIBBON TRAVELER HELPER
-- ============================================================================
local function spawnLayeredSlashWave(originPos, targetPos, tiltRad, widthScale, cPrimary, cSecondary, dur, folder)
	local dir = (targetPos - originPos)
	local unitDir = (dir.Magnitude > 0.05) and dir.Unit or Vector3.new(0, 0, -1)
	local safeTarget = (dir.Magnitude > 0.05) and targetPos or (originPos + unitDir * 4)
	local startCF = Lib.SafeLookAt(originPos, safeTarget, unitDir) * CFrame.Angles(0, 0, tiltRad)
	local endCF = Lib.SafeLookAt(safeTarget, safeTarget + unitDir, unitDir) * CFrame.Angles(0, 0, tiltRad)
	local d = dur or 0.32
	local w = math.clamp(widthScale or 1.0, 0.65, 2.5)

	-- 1. Traveling 3D Hollow Curved-Beam Crescent Blade (Dark Obsidian Silhouette + Elemental Glow + White Razor Core)
	local host = Instance.new("Part")
	host.Name = "FadeTravelingCrescent"
	host.Size = Vector3.new(0.2, 0.2, 0.2)
	host.CFrame = startCF
	host.Transparency = 1
	host.Anchored = true
	host.CanCollide = false
	host.CanQuery = false
	host.CanTouch = false
	host.Parent = folder

	local span0 = 3.2 * w
	local aL = Instance.new("Attachment")
	aL.Position = Vector3.new(-span0, 0, 0)
	aL.Orientation = Vector3.new(0, 90, 0)
	aL.Parent = host
	local aR = Instance.new("Attachment")
	aR.Position = Vector3.new(span0, 0, 0)
	aR.Orientation = Vector3.new(0, -90, 0)
	aR.Parent = host

	local darkCrescent = Instance.new("Beam")
	darkCrescent.Attachment0 = aL
	darkCrescent.Attachment1 = aR
	darkCrescent.Texture = Lib.Textures.FirePlasma
	darkCrescent.Segments = 28
	darkCrescent.CurveSize0 = span0 * 1.18
	darkCrescent.CurveSize1 = span0 * 1.18
	darkCrescent.Width0 = 0.25 * w
	darkCrescent.Width1 = 2.2 * w
	darkCrescent.Color = ColorSequence.new(PAL.Obsidian)
	darkCrescent.LightEmission = 0
	darkCrescent.LightInfluence = 0
	darkCrescent.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0.08),
		NumberSequenceKeypoint.new(0.8, 0.08),
		NumberSequenceKeypoint.new(1, 1),
	})
	darkCrescent.Parent = host

	local glowCrescent = Instance.new("Beam")
	glowCrescent.Attachment0 = aL
	glowCrescent.Attachment1 = aR
	glowCrescent.Texture = Lib.Textures.FirePlasma
	glowCrescent.Segments = 28
	glowCrescent.CurveSize0 = span0 * 1.15
	glowCrescent.CurveSize1 = span0 * 1.15
	glowCrescent.Width0 = 0.18 * w
	glowCrescent.Width1 = 1.65 * w
	glowCrescent.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, cSecondary or PAL.HotWhite),
		ColorSequenceKeypoint.new(0.5, cPrimary),
		ColorSequenceKeypoint.new(1, PAL.HotWhite),
	})
	glowCrescent.LightEmission = 1.0
	glowCrescent.LightInfluence = 0
	pcall(function() glowCrescent.Brightness = 5.2 end)
	glowCrescent.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.18, 0.02),
		NumberSequenceKeypoint.new(0.82, 0.02),
		NumberSequenceKeypoint.new(1, 1),
	})
	glowCrescent.FaceCamera = true
	glowCrescent.Parent = host

	local whiteCore = Instance.new("Beam")
	whiteCore.Attachment0 = aL
	whiteCore.Attachment1 = aR
	whiteCore.Segments = 24
	whiteCore.CurveSize0 = span0 * 1.12
	whiteCore.CurveSize1 = span0 * 1.12
	whiteCore.Width0 = 0.08 * w
	whiteCore.Width1 = 0.58 * w
	whiteCore.Color = ColorSequence.new(PAL.HotWhite)
	whiteCore.LightEmission = 1.0
	whiteCore.LightInfluence = 0
	pcall(function() whiteCore.Brightness = 6.8 end)
	whiteCore.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.25, 0),
		NumberSequenceKeypoint.new(0.75, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	whiteCore.FaceCamera = true
	whiteCore.Parent = host

	local tipRunner = Lib.MakePart("SlashRibbonTip", Enum.PartType.Ball, Vector3.new(0.42, 0.42, 0.42) * w, startCF, cSecondary or PAL.HotWhite, 0.12, Enum.Material.ForceField, folder)
	Lib.AttachRibbonTrail(tipRunner, PAL.HotWhite, cPrimary, PAL.Obsidian, 1.45 * w, 0.24)

	animateOver(d, function(a)
		local curCF = startCF:Lerp(endCF, a)
		local curSpan = (3.2 + a * 3.8) * w
		local fadeFactor = 1 - a * 0.85
		if host.Parent then
			host.CFrame = curCF
			aL.Position = Vector3.new(-curSpan, 0, 0)
			aR.Position = Vector3.new(curSpan, 0, 0)
			darkCrescent.CurveSize0 = curSpan * 1.18
			darkCrescent.CurveSize1 = curSpan * 1.18
			darkCrescent.Width1 = 2.2 * w * fadeFactor
			glowCrescent.CurveSize0 = curSpan * 1.15
			glowCrescent.CurveSize1 = curSpan * 1.15
			glowCrescent.Width1 = 1.65 * w * fadeFactor
			whiteCore.CurveSize0 = curSpan * 1.12
			whiteCore.CurveSize1 = curSpan * 1.12
			whiteCore.Width1 = 0.58 * w * fadeFactor
		end
		if tipRunner.Parent then
			local sweepAng = (a - 0.5) * 2.5
			tipRunner.CFrame = curCF * CFrame.new(math.sin(sweepAng) * curSpan * 0.85, math.cos(sweepAng) * curSpan * 0.35, -0.5)
		end
	end)

	Debris:AddItem(host, d + 0.06)
	Debris:AddItem(tipRunner, d + 0.24)
end

-- ============================================================================
-- 2B. BESPOKE 3D SIGNATURE CONSTRUCTS FOR EACH OF THE 11 NON-DRAGON FRUITS
--     (DISTINCT PER-MOVE CHOREOGRAPHY FOR Z / X / C / V / F — ZERO REPETITION!)
-- ============================================================================
local FRUIT_SKILL_DISPLAY_NAMES = {
	GaleCore = { Z = "Phong Đao • Gale Blades", X = "Lốc Xoáy Không Trung • Cyclone Burst", C = "Bão Phong Nghiền Nát • Tornado Crush", V = "Đại Cuồng Phong • Skyborn Typhoon", F = "Phong Dực Phi Hành • Wind Ride" },
	SandstoneCore = { Z = "Sa Đao • Desert Blade", X = "Quan Tài Cát • Sand Coffin", C = "Hố Cát Tử Thần • Quicksand Vortex", V = "Bão Cát Hoàng Kim • Pharaoh's Tempest", F = "Sa Bão Phi Hành • Sand Flight" },
	SolarFlameCore = { Z = "Hỏa Đạn Liên Hoàn • Fire Bullets", X = "Hỏa Quyền Xuyên Thấu • Prominence Fist", C = "Hỏa Trụ Xung Thiên • Flame Pillar", V = "Thái Dương Viêm Đế • Supernova Sun", F = "Hỏa Dực Xung Kích • Plasma Jet" },
	GlacierIceCore = { Z = "Băng Tiêu Tam Liên • Ice Shards", X = "Băng Sơn Trỗi Dậy • Glacial Surge", C = "Băng Điểu Xung Kích • Cryo Phoenix", V = "Tuyệt Độ Hàn Băng • Absolute Zero", F = "Trượt Băng Tốc Độ • Ice Skate" },
	CelestialLightCore = { Z = "Tia Sáng Phán Quyết • Light Ray", X = "Mưa Kiếm Ánh Sáng • Barrage of Light", C = "Bát Chỉ Kính Thiểm • Reflection Kick", V = "Đại Quang Vũ • Wrath of Aureon", F = "Thiên Quang Tốc Hành • Light Flight" },
	StarforgedMagmaCore = { Z = "Dung Nham Thiết Chưởng • Magma Clap", X = "Nanh Chó Địa Ngục • Hellhound Fang", C = "Cú Đấm Nham Thạch • Magma Fist", V = "Mưa Sao Băng Dung Nham • Meteor Volcano", F = "Thiên Thạch Phản Lực • Magma Jet" },
	ThunderRumbleCore = { Z = "Lôi Long Phá • Rumble Dragon", X = "Thiên Lôi Giáng Thế • Sky Thunder", C = "Pháo Từ Trường Lôi Đế • Storm Judgement", V = "Quả Cầu Lôi Thần • Raigo Sphere", F = "Lôi Bộ Tam Đoạn • Lightning Flash" },
	AstralGravityCore = { Z = "Xung Lực Đẩy • Gravity Push", X = "Vùng Trọng Lực Đè Nén • Gravity Crush", C = "Triệu Hồi Thiên Thạch • Meteor Strike", V = "Mưa Thiên Thạch Vũ Trụ • Cosmic Extinction", F = "Thiên Thạch Ngự Không • Boulder Ride" },
	DimensionalPortalCore = { Z = "Đột Kích Xuyên Không • Rift Slash", X = "Ẩn Thân Dị Giới • Void Shift", C = "Cổng Dịch Chuyển Thế Giới • Nexus Gate", V = "Chiều Không Gian Thứ Tư • Dimensional Rift", F = "Bước Nhảy Lượng Tử • Warp Step" },
	SolarTitanCore = { Z = "Hóa Kim Thân Khổng Lồ • Solar Titan", X = "Thiên Địa Chấn Động • Halo Shockwave", C = "Như Lai Thần Chưởng • Solar Palm", V = "Hoàng Hôn Chư Thần • Divine Retribution", F = "Bước Nhảy Kim Thân • Titan Leap" },
	AetherflowCore = { Z = "Thiết Quyền Tinh Thể • Piercing Fist", X = "Gai Tinh Thể Trỗi Dậy • Aether Spikes", C = "Bánh Xe Gai Hủy Diệt • Carved Aether", V = "Vạn Quyền Diệt Thế • Restless Barrage", F = "Bánh Xe Tốc Độ • Roller Donut" },
}

local function spawnOverheadSkillCallout(startPos, fruitKey, moveKey, prof, spec)
	local fMap = FRUIT_SKILL_DISPLAY_NAMES[fruitKey]
	local moveTitle = (fMap and fMap[moveKey]) or (spec and spec.Name) or ("Skill [" .. tostring(moveKey) .. "]")
	local folder = Lib.GetTempFolder("UniversalVFX")
	local anchor = Lib.MakePart("SkillCalloutAnchor", Enum.PartType.Ball, Vector3.new(0.2, 0.2, 0.2), CFrame.new(startPos + Vector3.new(0, 4.4, 0)), prof.Primary, 1, Enum.Material.SmoothPlastic, folder)
	local bb = Instance.new("BillboardGui")
	bb.Name = "FruitSkillCallout"
	bb.Size = UDim2.fromOffset(320, 46)
	bb.StudsOffset = Vector3.new(0, 1.2, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 120
	bb.Parent = anchor

	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromScale(1, 0.80)
	bg.Position = UDim2.fromScale(0.5, 0.5)
	bg.AnchorPoint = Vector2.new(0.5, 0.5)
	bg.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
	bg.BackgroundTransparency = 0.14
	bg.BorderSizePixel = 0
	bg.Parent = bb
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = bg
	local stroke = Instance.new("UIStroke")
	stroke.Color = prof.Primary
	stroke.Thickness = 2.0
	stroke.Parent = bg

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, -12, 1, 0)
	lbl.Position = UDim2.fromOffset(6, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextSize = 14
	lbl.TextColor3 = Color3.fromRGB(255, 250, 240)
	lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	lbl.TextStrokeTransparency = 0.12
	lbl.Text = "[" .. tostring(moveKey) .. "] " .. moveTitle
	lbl.Parent = bg

	TweenService:Create(bb, TweenInfo.new(0.95, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		StudsOffset = Vector3.new(0, 3.8, 0),
	}):Play()
	task.delay(0.58, function()
		if bg.Parent then
			TweenService:Create(bg, TweenInfo.new(0.38), { BackgroundTransparency = 1 }):Play()
			TweenService:Create(stroke, TweenInfo.new(0.38), { Transparency = 1 }):Play()
			TweenService:Create(lbl, TweenInfo.new(0.38), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
	Debris:AddItem(anchor, 1.0)
end

local function spawnBespokeFruitSignature(fruitKey, moveKey, startPos, endPos, lookDir, prof, sc, isAwakened, folder, low, isLocal, actorChar)
	local gEnd = Lib.FindGround(endPos)
	local gStart = Lib.FindGround(startPos)
	local pathCF = Lib.SafeLookAt(startPos, endPos, lookDir)
	local k = tostring(moveKey or "Z")

	-- Dynamic Cast Pose on Character + FADE Showcase Core Layering per Move Key (Z vs X vs C vs V vs F)
	if actorChar then
		Lib.PlaySkillCastPose(actorChar, k, (k == "V") and 0.50 or ((k == "C") and 0.42 or 0.32))
		Lib.SpawnHandChargeIgnition(actorChar, startPos, lookDir, k, prof.Primary, prof.Secondary, sc, folder)
		if k == "X" or k == "C" or k == "V" or k == "F" then
			Lib.SpawnCharacterAfterimageBurst(actorChar, lookDir, k, prof.Primary, prof.Secondary, folder)
		end
	end
	Lib.SpawnFadeAtmosphericWindSmoke(startPos, endPos, 4.2 * sc, prof.Primary, 0.65, folder)
	Lib.PlayLayeredSkillAudio(startPos, endPos, k, prof.Element)

	-- Distinct Per-Key FADE Showcase Backbone so Z, X, C, V, F NEVER look identical:
	if k == "Z" then
		-- [Z] Opening Razor Ground Slash Ribbon + Suspended Void/Element Orbs (Screenshot 2 style)
		Lib.SpawnFadeGroundSlashRibbon(startPos, endPos, 1.8 * sc, prof.Primary, prof.Secondary, 0.44, folder)
	elseif k == "X" then
		-- [X] Haymaker Corkscrew Shockwave Tunnel (Screenshot 3 style)
		Lib.SpawnFadeCorkscrewTunnel(startPos + Vector3.new(0, 1.4, 0), endPos + Vector3.new(0, 1.2, 0), 2.8 * sc, 6, prof.Primary, prof.Secondary, 0.44, folder)
		Lib.SpawnFadeGroundSlashRibbon(startPos, endPos, 2.2 * sc, prof.Primary, prof.Secondary, 0.48, folder)
	elseif k == "C" then
		-- [C] Cataclysmic Jagged Dark-Core Impact Spikes + Crown Crescent Arcs (Screenshot 1 style) + Mini Impact Frame
		Lib.SpawnFadeJaggedImpactSpikes(endPos, 12.5 * sc, low and 6 or 10, prof.Primary, prof.Secondary, 0.62, folder)
		if isLocal then
			Lib.TriggerAnimeImpactFrame(prof.Primary, 0.035, 3.8, 0.42)
		end
	elseif k == "V" then
		-- [V] Sovereign Ultimate: Corkscrew Tunnel + Colossal Jagged Impact Spikes + Ground Slash + 0.048s Anime Impact Frame!
		Lib.SpawnFadeCorkscrewTunnel(startPos + Vector3.new(0, 1.8, 0), endPos + Vector3.new(0, 1.6, 0), 4.2 * sc, 8, prof.Primary, prof.Secondary, 0.56, folder)
		Lib.SpawnFadeGroundSlashRibbon(startPos, endPos, 3.6 * sc, prof.Primary, prof.Secondary, 0.62, folder)
		Lib.SpawnFadeJaggedImpactSpikes(endPos, 19.5 * sc, low and 8 or 14, prof.Primary, prof.Secondary, 0.78, folder)
		if isLocal then
			Lib.TriggerAnimeImpactFrame(prof.Primary, 0.050, 6.2, 0.64)
		end
	elseif k == "F" then
		-- [F] Traversal Burst Signature
		Lib.SpawnFadeGroundSlashRibbon(startPos, endPos, 2.4 * sc, prof.Primary, prof.Secondary, 0.46, folder)
		Lib.SpawnFadeCrescentArc(pathCF, 1.8 * sc, 8.5 * sc, 1.6 * sc, prof.Primary, PAL.HotWhite, 0.38, folder)
	end

	-- Fruit-Specific 3D Construct tailored to Move Key (Z / X / C / V / F)
	if fruitKey == "GaleCore" then
		local arcCount = (k == "V") and (low and 6 or 12) or ((k == "C") and 8 or 4)
		for i = 1, arcCount do
			local ang = (i / arcCount) * math.pi * 2
			local rad = ((k == "V") and 9.5 or ((k == "C") and 6.2 or 3.8)) * sc
			local hOff = ((k == "C" or k == "V") and (i * 1.4) or 1.2) * sc
			local arcCF = CFrame.new(gEnd + Vector3.new(math.cos(ang) * rad * 0.5, hOff, math.sin(ang) * rad * 0.5)) * CFrame.Angles(0.35, ang, (i % 2 == 0) and 0.45 or -0.45)
			Lib.SpawnFadeCrescentArc(arcCF, rad * 0.35, rad * 1.35, 1.4 * sc, (i % 2 == 0) and prof.Primary or prof.Secondary, PAL.HotWhite, 0.48, folder)
		end

	elseif fruitKey == "SandstoneCore" then
		if k == "X" or k == "V" then
			-- 4-Sided Golden Pharaoh Pyramid Tomb slamming shut around target
			local pyrR = ((k == "V") and 12.5 or 7.5) * sc
			local pyrH = ((k == "V") and 15.0 or 9.6) * sc
			for side = 1, 4 do
				local ang = (side - 1) * (math.pi * 0.5)
				local dirVec = Vector3.new(math.cos(ang), 0, math.sin(ang))
				local startFacePos = gEnd + dirVec * (pyrR * 1.45) + Vector3.new(0, pyrH * 0.45, 0)
				local targetFacePos = gEnd + dirVec * (pyrR * 0.42) + Vector3.new(0, pyrH * 0.45, 0)
				local startCF = Lib.SafeLookAt(startFacePos, gEnd + Vector3.new(0, pyrH * 0.9, 0), Vector3.yAxis)
				local closeCF = Lib.SafeLookAt(targetFacePos, gEnd + Vector3.new(0, pyrH * 0.95, 0), Vector3.yAxis)
				local wall = Lib.MakePart("PharaohPyramidWall_" .. side, Enum.PartType.Wedge, Vector3.new(pyrR * 1.15, pyrH, 1.2 * sc), startCF, prof.Primary, 0.08, Enum.Material.Sandstone, folder)
				local glyph = Lib.MakePart("PharaohGlyph_" .. side, Enum.PartType.Block, Vector3.new(pyrR * 0.65, pyrH * 0.55, 1.35 * sc), startCF, prof.Secondary, 0.14, Enum.Material.ForceField, folder)
				TweenService:Create(wall, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { CFrame = closeCF }):Play()
				TweenService:Create(glyph, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { CFrame = closeCF }):Play()
				task.delay(0.32, function()
					if wall.Parent then
						TweenService:Create(wall, TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = Vector3.new(pyrR * 1.5, 0.4, 0.4), Transparency = 1 }):Play()
					end
					if glyph.Parent then
						TweenService:Create(glyph, TweenInfo.new(0.24), { Transparency = 1 }):Play()
					end
				end)
				Debris:AddItem(wall, 0.62)
				Debris:AddItem(glyph, 0.60)
			end
		else
			-- Swirling Golden Sand Obelisk Spires & Quicksand Crescent Vortex
			for i = 1, 4 do
				local ang = (i / 4) * math.pi * 2
				local vCF = CFrame.new(gEnd + Vector3.new(0, 0.5 * i, 0)) * CFrame.Angles(0, ang, 0.25)
				Lib.SpawnFadeCrescentArc(vCF, 2.2 * sc, (7.5 + i * 2.2) * sc, 1.5 * sc, prof.Primary, prof.Secondary, 0.46, folder)
			end
		end

	elseif fruitKey == "SolarFlameCore" then
		if k == "C" or k == "V" then
			-- Blazing Curved-Beam Phoenix Wings + Descending Supernova Sun Core
			for side = -1, 1, 2 do
				local wingCF = pathCF * CFrame.new(side * 2.4 * sc, 2.0 * sc, 0.5) * CFrame.Angles(0.25, side * -0.45, side * 0.52)
				Lib.SpawnFadeCrescentArc(wingCF, 2.5 * sc, 11.5 * sc, 2.2 * sc, prof.Primary, PAL.Gold, 0.48, folder)
			end
		end
		if k == "V" then
			local sunCenter = endPos + Vector3.new(0, 8 * sc, 0)
			for r = 1, 6 do
				local ang = (r / 6) * math.pi * 2
				local arcCF = CFrame.new(sunCenter) * CFrame.Angles(ang, ang * 0.7, 0)
				Lib.SpawnFadeCrescentArc(arcCF, 3.5 * sc, 16.5 * sc, 2.4 * sc, PAL.Gold, prof.Primary, 0.56, folder)
			end
		end

	elseif fruitKey == "GlacierIceCore" then
		-- Crystalline Hexagonal Frost Snowflake & Shattering Glacier Needles scaled by Move Key
		local hexCount = (k == "V") and 8 or ((k == "C") and 6 or 4)
		local snowR = ((k == "V") and 15.5 or ((k == "C") and 10.5 or 6.8)) * sc
		for i = 1, hexCount do
			local ang = (i - 1) * ((math.pi * 2) / hexCount)
			local crystalPos = gEnd + Vector3.new(math.cos(ang) * snowR * 0.62, 0, math.sin(ang) * snowR * 0.62)
			local crystalH = ((k == "V") and 11.5 or 6.4) * sc
			local pillar = Lib.MakePart("GlacierCrystalSpire_" .. i, Enum.PartType.Block, Vector3.new(1.4 * sc, crystalH, 1.4 * sc), CFrame.new(crystalPos + Vector3.new(0, crystalH * 0.45, 0)) * CFrame.Angles(0.24, ang, 0.18), (i % 2 == 0) and prof.Primary or prof.Secondary, 0.08, Enum.Material.Glass, folder)
			local sm = Instance.new("SpecialMesh")
			sm.MeshType = Enum.MeshType.Sphere
			sm.Parent = pillar
			TweenService:Create(pillar, TweenInfo.new(0.52, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				CFrame = pillar.CFrame * CFrame.new(0, 2.8 * sc, 0),
				Size = Vector3.new(0.2, crystalH * 1.35, 0.2),
				Transparency = 1,
			}):Play()
			Debris:AddItem(pillar, 0.56)
		end

	elseif fruitKey == "CelestialLightCore" then
		local swordCount = (k == "V") and (low and 6 or 12) or ((k == "X") and 7 or 3)
		for i = 1, swordCount do
			task.delay((i - 1) * 0.028, function()
				local ang = (i / swordCount) * math.pi * 2
				local rad = (i == 1) and 0 or (((k == "V") and 8.5 or 4.2) * sc)
				local impactP = gEnd + Vector3.new(math.cos(ang) * rad, 0, math.sin(ang) * rad)
				local spawnP = impactP + Vector3.new(0, 19 * sc, 0)
				local blade = Lib.MakePart("SacredLightSword_" .. i, Enum.PartType.Block, Vector3.new(0.65 * sc, 9.5 * sc, 0.28 * sc), CFrame.new(spawnP), prof.Primary, 0.04, Enum.Material.ForceField, folder)
				TweenService:Create(blade, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
					Position = impactP + Vector3.new(0, 3.2 * sc, 0),
				}):Play()
				task.delay(0.24, function()
					if blade.Parent then TweenService:Create(blade, TweenInfo.new(0.22), { Transparency = 1, Size = Vector3.new(0.1, 12 * sc, 0.1) }):Play() end
				end)
				Debris:AddItem(blade, 0.50)
			end)
		end

	elseif fruitKey == "StarforgedMagmaCore" then
		if k == "X" or k == "C" or k == "V" then
			-- 3D Hellhound Magma Fang Jaws tearing forward
			local jawOrigin = startPos + lookDir * 2.5 + Vector3.new(0, 1.8 * sc, 0)
			local jawTarget = endPos + Vector3.new(0, 1.5 * sc, 0)
			local jawSc = (k == "V") and (sc * 1.45) or sc
			local upperJaw = Lib.MakePart("HellhoundUpperJaw", Enum.PartType.Wedge, Vector3.new(4.4 * jawSc, 2.5 * jawSc, 5.8 * jawSc), Lib.SafeLookAt(jawOrigin, jawTarget, lookDir) * CFrame.Angles(0.35, 0, 0), prof.Primary, 0.06, Enum.Material.Slate, folder)
			local lowerJaw = Lib.MakePart("HellhoundLowerJaw", Enum.PartType.Wedge, Vector3.new(4.0 * jawSc, 1.9 * jawSc, 5.2 * jawSc), Lib.SafeLookAt(jawOrigin - Vector3.new(0, 1.4 * jawSc, 0), jawTarget, lookDir) * CFrame.Angles(-0.35, 0, math.pi), PAL.Obsidian, 0.08, Enum.Material.Slate, folder)
			TweenService:Create(upperJaw, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				CFrame = Lib.SafeLookAt(jawTarget, jawTarget + lookDir, lookDir) * CFrame.Angles(-0.08, 0, 0),
				Transparency = 0.85,
			}):Play()
			TweenService:Create(lowerJaw, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				CFrame = Lib.SafeLookAt(jawTarget, jawTarget + lookDir, lookDir) * CFrame.Angles(0.08, 0, math.pi),
				Transparency = 0.85,
			}):Play()
			Debris:AddItem(upperJaw, 0.34)
			Debris:AddItem(lowerJaw, 0.34)
		end

	elseif fruitKey == "ThunderRumbleCore" then
		-- 6 Raijin Thunder Drums + Multi-Arc Kirin Lightning Crown
		local drumCount = 6
		local drumRadius = 3.6 * sc
		for d = 1, drumCount do
			local ang = (d / drumCount) * math.pi * 2
			local drumCF = pathCF * CFrame.new(math.cos(ang) * drumRadius, 1.8 * sc + math.sin(ang) * drumRadius, 1.4)
			Lib.SpawnFadeCrescentArc(drumCF, 0.55 * sc, 1.45 * sc, 0.45 * sc, prof.Primary, PAL.HotWhite, 0.42, folder)
		end
		if k == "X" or k == "C" or k == "V" then
			local cloudPos = endPos + Vector3.new(0, ((k == "V") and 22 or 16) * sc, 0)
			Lib.SpawnJaggedLightning(cloudPos, gEnd, 8, 2.2 * sc, ((k == "V") and 0.65 or 0.42) * sc, PAL.HotWhite, prof.Primary, 0.45, folder)
		end

	elseif fruitKey == "AstralGravityCore" then
		-- Black Hole Singularity Core + Dual Curved-Beam Accretion Disks
		local bhCenter = endPos + Vector3.new(0, ((k == "V") and 6.5 or 3.2) * sc, 0)
		local bhScale = ((k == "V") and 1.65 or ((k == "C") and 1.25 or 0.85)) * sc
		local singularity = Lib.MakePart("GravityBlackHole", Enum.PartType.Ball, Vector3.new(4.2, 4.2, 4.2) * bhScale, CFrame.new(bhCenter), PAL.Obsidian, 0.02, Enum.Material.SmoothPlastic, folder)
		local lensShell = Lib.MakePart("GravityLensShell", Enum.PartType.Ball, Vector3.new(5.2, 5.2, 5.2) * bhScale, CFrame.new(bhCenter), prof.Primary, 0.22, Enum.Material.ForceField, folder)
		Lib.SpawnFadeCrescentArc(CFrame.new(bhCenter) * CFrame.Angles(0.38, 0, 0), 3.2 * bhScale, 12.5 * bhScale, 1.8 * bhScale, prof.Primary, PAL.HotWhite, 0.52, folder)
		Lib.SpawnFadeCrescentArc(CFrame.new(bhCenter) * CFrame.Angles(-0.38, math.pi, 0), 3.2 * bhScale, 14.0 * bhScale, 1.6 * bhScale, prof.Secondary, prof.Primary, 0.52, folder)
		TweenService:Create(singularity, TweenInfo.new(0.50), { Size = Vector3.new(0.4, 0.4, 0.4), Transparency = 1 }):Play()
		TweenService:Create(lensShell, TweenInfo.new(0.50), { Size = Vector3.new(11, 11, 11) * bhScale, Transparency = 1 }):Play()
		Debris:AddItem(singularity, 0.54)
		Debris:AddItem(lensShell, 0.54)

	elseif fruitKey == "DimensionalPortalCore" then
		local function spawnHexGate(centerPos, scaleGate, col)
			local baseCF = Lib.SafeLookAt(centerPos, centerPos + lookDir, lookDir)
			local rGate = 4.2 * scaleGate
			for e = 1, 6 do
				local a1 = (e - 1) * (math.pi / 3)
				local edgeCF = baseCF * CFrame.Angles(0, 0, a1) * CFrame.new(0, rGate, 0)
				local bar = Lib.MakePart("HexPortalEdge_" .. e, Enum.PartType.Block, Vector3.new(rGate * 1.18, 0.34 * scaleGate, 0.34 * scaleGate), edgeCF, col, 0.06, Enum.Material.ForceField, folder)
				TweenService:Create(bar, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					CFrame = edgeCF * CFrame.new(0, 1.8 * scaleGate, 0),
					Transparency = 1,
				}):Play()
				Debris:AddItem(bar, 0.50)
			end
		end
		spawnHexGate(startPos + lookDir * 2.2 + Vector3.new(0, 1.5, 0), sc, prof.Primary)
		if k ~= "Z" then
			spawnHexGate(endPos + Vector3.new(0, 1.5, 0), sc * ((k == "V") and 1.65 or 1.25), prof.Secondary)
		end

	elseif fruitKey == "SolarTitanCore" then
		if k == "C" or k == "V" then
			-- Colossal Descending 3D Buddha Palm with Sonic Entry Crescent Rings
			local palmSky = endPos + Vector3.new(0, 19 * sc, 0)
			local palmGround = gEnd + Vector3.new(0, 1.6 * sc, 0)
			local palmSc = ((k == "V") and 1.45 or 1.0) * sc
			local palmBase = Lib.MakePart("BuddhaGiantPalm", Enum.PartType.Block, Vector3.new(7.5 * palmSc, 1.6 * palmSc, 7.5 * palmSc), CFrame.new(palmSky), PAL.Gold, 0.06, Enum.Material.ForceField, folder)
			local fingers = {}
			for f = -2, 2 do
				local fPart = Lib.MakePart("BuddhaFinger_" .. f, Enum.PartType.Block, Vector3.new(1.15 * palmSc, 1.4 * palmSc, 4.6 * palmSc), CFrame.new(palmSky + Vector3.new(f * 1.45 * palmSc, 0, -5.2 * palmSc)), PAL.Gold, 0.06, Enum.Material.ForceField, folder)
				table.insert(fingers, { Part = fPart, OffX = f * 1.45 * palmSc })
			end
			animateOver(0.26, function(a)
				local curP = palmSky:Lerp(palmGround, a)
				if palmBase.Parent then palmBase.Position = curP end
				for _, fg in ipairs(fingers) do
					if fg.Part.Parent then
						fg.Part.Position = curP + Vector3.new(fg.OffX, 0, -5.2 * palmSc)
					end
				end
			end, function()
				if palmBase.Parent then TweenService:Create(palmBase, TweenInfo.new(0.28), { Transparency = 1, Size = palmBase.Size * 1.35 }):Play() end
				for _, fg in ipairs(fingers) do
					if fg.Part.Parent then TweenService:Create(fg.Part, TweenInfo.new(0.28), { Transparency = 1 }):Play() end
				end
			end)
			Debris:AddItem(palmBase, 0.58)
			for _, fg in ipairs(fingers) do Debris:AddItem(fg.Part, 0.58) end
		end

	elseif fruitKey == "AetherflowCore" then
		local ringCount = (k == "V") and (low and 5 or 8) or ((k == "C") and 4 or 2)
		for i = 1, ringCount do
			task.delay((i - 1) * 0.038, function()
				local ang = (i / ringCount) * math.pi * 2
				local ringPos = endPos + Vector3.new(math.cos(ang) * 7.8 * sc, (2.2 + (i % 3) * 1.8) * sc, math.sin(ang) * 7.8 * sc)
				local aimCF = Lib.SafeLookAt(ringPos, endPos + Vector3.new(0, 1.2, 0), lookDir)
				Lib.SpawnFadeCrescentArc(aimCF, 1.4 * sc, 3.8 * sc, 0.9 * sc, prof.Primary, PAL.Crimson, 0.36, folder)
				local hakiFist = Lib.MakePart("MochiHakiGiantFist_" .. i, Enum.PartType.Ball, Vector3.new(2.6 * sc, 2.6 * sc, 3.8 * sc), aimCF, PAL.Obsidian, 0.04, Enum.Material.SmoothPlastic, folder)
				local crimsonAura = Lib.MakePart("MochiHakiCrimsonShell_" .. i, Enum.PartType.Ball, Vector3.new(3.1 * sc, 3.1 * sc, 4.3 * sc), aimCF, PAL.Crimson, 0.18, Enum.Material.ForceField, folder)
				TweenService:Create(hakiFist, TweenInfo.new(0.19, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
					CFrame = Lib.SafeLookAt(endPos, endPos + aimCF.LookVector, Vector3.yAxis),
				}):Play()
				TweenService:Create(crimsonAura, TweenInfo.new(0.19, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
					CFrame = Lib.SafeLookAt(endPos, endPos + aimCF.LookVector, Vector3.yAxis),
					Transparency = 0.85,
				}):Play()
				Debris:AddItem(hakiFist, 0.25)
				Debris:AddItem(crimsonAura, 0.25)
			end)
		end
	end
end

-- ============================================================================
-- 3. ALL 16 DEVIL FRUIT ARCHETYPES (COVERING ALL 55 NON-DRAGON FRUIT MOVES)
-- ============================================================================
function UniversalVFXOverhaul.ExecuteFruitArchetype(arch, fruitKey, moveKey, startPos, endPos, lookDir, prof, spec, scale, isAwakened, isLocal, actorChar)
	local sc = math.clamp(scale or 1, 0.65, 2.2)
	local folder = Lib.GetTempFolder("UniversalVFX")
	local low = Lib.IsLowFX()

	local safeLookDir = (typeof(lookDir) == "Vector3" and lookDir.Magnitude > 0.05) and lookDir.Unit or Vector3.new(0, 0, -1)
	lookDir = safeLookDir
	local dist = (endPos - startPos).Magnitude
	if dist ~= dist or dist < 8.5 then
		endPos = startPos + lookDir * ((spec.Range or 24) * sc)
		dist = (endPos - startPos).Magnitude
	else
		dist = math.min(46, dist)
		endPos = startPos + (endPos - startPos).Unit * dist
	end
	local pathCF = Lib.SafeLookAt(startPos, endPos, lookDir)
	local count = spec.Count or 5
	if low then
		count = math.max(2, math.floor(count * 0.35 + 0.5))
	end

	UniversalVFXOverhaul.SpawnStage1Sigil(Lib.SafeLookAt(startPos, startPos + lookDir, lookDir), prof, sc, isAwakened)
	Lib.EmitElement(prof.Element, Lib.SafeLookAt(startPos + lookDir * 1.8, endPos, lookDir), sc * 0.85, prof.Primary, prof.Secondary)
	pcall(spawnOverheadSkillCallout, startPos, fruitKey, moveKey, prof, spec)
	pcall(spawnBespokeFruitSignature, fruitKey, moveKey, startPos, endPos, lookDir, prof, sc, isAwakened, folder, low, isLocal, actorChar)

	-- ========================================================================
	-- VIBEGG (@vibeggvn) 5-STEP ELEMENTAL SPELL & FINISHER INTEGRATION
	-- (Scoped to specific moves so Z / X / C / V remain visually distinct!)
	-- ========================================================================
	local isFinisherMove = (moveKey == "V" or moveKey == "C" or isAwakened)
	local isUltimatePaperCrush = (moveKey == "V" or isAwakened)
	local elem = tostring(prof and prof.Element or "")
	if (fruitKey == "SolarFlameCore" or elem == "Flame") and (moveKey == "Z" or moveKey == "V") then
		Lib.VibeGG_Fireball5Steps(startPos + Vector3.new(0, 1.2, 0), endPos, sc, isFinisherMove, isLocal, actorChar)
	elseif (fruitKey == "GlacierIceCore" or elem == "Frost" or elem == "Ice") and (moveKey == "X" or moveKey == "V") then
		Lib.VibeGG_IceSpikes5Steps(startPos, endPos, lookDir, sc, isFinisherMove, isLocal, actorChar)
	elseif (fruitKey == "ThunderRumbleCore" or elem == "Lightning" or elem == "Thunder") and (moveKey == "X" or moveKey == "C" or moveKey == "V") then
		Lib.VibeGG_Lightning5Steps(startPos + Vector3.new(0, 1.5, 0), endPos, sc, prof.Primary, prof.Secondary, isFinisherMove, isLocal, actorChar)
	elseif (fruitKey == "AstralGravityCore" or elem == "Gravity") and (moveKey == "X" or moveKey == "V") then
		Lib.VibeGG_GravitySpell5Steps(endPos, sc, isUltimatePaperCrush, isLocal, actorChar)
	elseif (fruitKey == "StarforgedMagmaCore" or elem == "Magma") and (moveKey == "Z" or moveKey == "C" or moveKey == "V") then
		Lib.VibeGG_MagmaSpell5Steps(endPos, sc, isFinisherMove, isLocal, actorChar)
	end

	if arch == "CrescentWave" then
		for i = 1, count do
			local spread = (i - (count + 1) * 0.5) * 0.20
			local dir = (pathCF * CFrame.Angles(0, spread, 0)).LookVector
			local dst = startPos + dir * dist
			local tilt = (i % 2 == 0) and 0.42 or -0.42
			if i == math.ceil(count * 0.5) then tilt = 0 end
			task.delay((i - 1) * 0.035, function()
				spawnLayeredSlashWave(startPos + Vector3.new(0, 0.6, 0), dst, tilt, sc * 1.05, (i % 2 == 0) and prof.Secondary or prof.Primary, prof.Accent, 0.34, folder)
			end)
		end
		task.delay(0.30, function()
			UniversalVFXOverhaul.SpawnStage3Aftermath(endPos, prof, spec.Radius, sc, isAwakened, isLocal)
		end)

	elseif arch == "TornadoColumn" then
		local gPos = Lib.FindGround(endPos)
		local tiers = {}
		local maxH = 17.5 * sc
		for i = 1, count do
			local hFrac = i / count
			local rad = (2.8 + hFrac * 7.4) * sc
			local ring = Lib.MakePart(
				"CycloneTier_" .. i,
				Enum.PartType.Cylinder,
				Vector3.new(0.42 * sc, rad, rad),
				CFrame.new(gPos + Vector3.new(0, hFrac * maxH, 0)) * CFrame.Angles(0.14, i * 0.7, math.pi * 0.5),
				(i % 2 == 0) and prof.Primary or prof.Secondary,
				0.18,
				Enum.Material.ForceField,
				folder
			)
			table.insert(tiers, { Part = ring, Frac = hFrac, BaseR = rad })
		end
		local coreFunnel = Lib.MakePart("CycloneObsidianCore", Enum.PartType.Cylinder, Vector3.new(maxH * 0.92, 2.2 * sc, 2.2 * sc), CFrame.new(gPos + Vector3.new(0, maxH * 0.46, 0)) * CFrame.Angles(0, 0, math.pi * 0.5), PAL.Obsidian, 0.28, Enum.Material.SmoothPlastic, folder)
		local streamerA = Lib.MakePart("CycloneRibbonA", Enum.PartType.Ball, Vector3.new(0.5, 0.5, 0.5), CFrame.new(gPos), prof.Primary, 1, Enum.Material.SmoothPlastic, folder)
		local streamerB = Lib.MakePart("CycloneRibbonB", Enum.PartType.Ball, Vector3.new(0.5, 0.5, 0.5), CFrame.new(gPos), prof.Secondary, 1, Enum.Material.SmoothPlastic, folder)
		Lib.AttachRibbonTrail(streamerA, PAL.HotWhite, prof.Primary, PAL.Obsidian, 1.3 * sc, 0.30)
		Lib.AttachRibbonTrail(streamerB, prof.Secondary, prof.Primary, PAL.Obsidian, 1.1 * sc, 0.30)

		local dur = 0.66
		animateOver(dur, function(a)
			local spin = a * 13.5
			for idx, t in ipairs(tiers) do
				if t.Part.Parent then
					local curR = t.BaseR * (1 + a * 0.58)
					local wobbleX = math.sin(spin + idx) * 0.85 * sc
					local wobbleZ = math.cos(spin + idx) * 0.85 * sc
					t.Part.CFrame = CFrame.new(gPos + Vector3.new(wobbleX, t.Frac * maxH * (1 + a * 0.15), wobbleZ)) * CFrame.Angles(0.14 * math.sin(spin), spin + idx, math.pi * 0.5)
					t.Part.Size = Vector3.new(math.max(0.08, 0.42 * sc * (1 - a * 0.7)), curR, curR)
					t.Part.Transparency = 0.18 + a * 0.82
				end
			end
			if coreFunnel.Parent then
				coreFunnel.Transparency = 0.28 + a * 0.72
				coreFunnel.Size = Vector3.new(maxH, (2.2 + a * 2.4) * sc, (2.2 + a * 2.4) * sc)
			end
			local hA = (a * 1.4) % 1
			local rA = (2.6 + hA * 7.6) * sc
			if streamerA.Parent then
				streamerA.CFrame = CFrame.new(gPos + Vector3.new(math.cos(spin * 1.6) * rA, hA * maxH, math.sin(spin * 1.6) * rA))
			end
			if streamerB.Parent then
				streamerB.CFrame = CFrame.new(gPos + Vector3.new(math.cos(spin * 1.6 + math.pi) * rA, ((hA + 0.5) % 1) * maxH, math.sin(spin * 1.6 + math.pi) * rA))
			end
		end)
		for _, t in ipairs(tiers) do Debris:AddItem(t.Part, dur + 0.06) end
		Debris:AddItem(coreFunnel, dur + 0.06)
		Debris:AddItem(streamerA, dur + 0.28)
		Debris:AddItem(streamerB, dur + 0.28)
		UniversalVFXOverhaul.SpawnStage3Aftermath(endPos, prof, spec.Radius, sc, isAwakened, isLocal)

	elseif arch == "RapidBarrage" or arch == "HomingOrbs" or arch == "MirrorVolley" then
		-- Optional Sacred Mirror Halo Array behind caster for MirrorVolley / HomingOrbs
		for i = 1, count do
			task.delay((i - 1) * 0.036, function()
				local ang = (i - 1) * ((math.pi * 2) / count)
				local off = pathCF.RightVector * (math.cos(ang) * 3.1 * sc) + pathCF.UpVector * (math.sin(ang) * 2.1 * sc + 1.4)
				local p0 = startPos + off
				local p1 = endPos + pathCF.RightVector * (math.cos(ang * 1.7) * 1.6 * sc)
				local midCtrl = (p0 + p1) * 0.5 + off * 1.35 + Vector3.new(0, 2.2 * sc, 0)

				if arch == "MirrorVolley" then
					local mirror = Lib.MakePart("SacredMirror_" .. i, Enum.PartType.Cylinder, Vector3.new(0.10, 2.2 * sc, 2.2 * sc), Lib.SafeLookAt(p0, p1, lookDir) * CFrame.Angles(0, math.pi * 0.5, 0), prof.Secondary, 0.16, Enum.Material.Glass, folder)
					TweenService:Create(mirror, TweenInfo.new(0.28), { Size = Vector3.new(0.04, 3.4 * sc, 3.4 * sc), Transparency = 1 }):Play()
					Debris:AddItem(mirror, 0.32)
				end

				local isOrb = (arch == "HomingOrbs")
				local sz = isOrb and (Vector3.new(1.45, 1.45, 1.45) * sc) or (Vector3.new(0.55, 0.55, 3.4) * sc)
				local proj = Lib.MakePart("BarrageProj_" .. i, isOrb and Enum.PartType.Ball or Enum.PartType.Block, sz, Lib.SafeLookAt(p0, p1, lookDir), (i % 2 == 0) and prof.Primary or prof.Secondary, 0.08, Enum.Material.ForceField, folder)
				local core = Lib.MakePart("BarrageCore_" .. i, isOrb and Enum.PartType.Ball or Enum.PartType.Block, sz * 0.52, proj.CFrame, PAL.Obsidian, 0.12, Enum.Material.SmoothPlastic, folder)
				Lib.AttachRibbonTrail(proj, PAL.HotWhite, prof.Primary, PAL.Obsidian, 0.85 * sc, 0.20)

				local flightDur = 0.24
				animateOver(flightDur, function(a)
					local omt = 1 - a
					local curP = p0 * (omt * omt) + midCtrl * (2 * omt * a) + p1 * (a * a)
					local nxtA = math.min(1, a + 0.05)
					local omt2 = 1 - nxtA
					local nxtP = p0 * (omt2 * omt2) + midCtrl * (2 * omt2 * nxtA) + p1 * (nxtA * nxtA)
					local cf = Lib.SafeLookAt(curP, nxtP, lookDir)
					if proj.Parent then proj.CFrame = cf end
					if core.Parent then core.CFrame = cf end
				end, function()
					Lib.SpawnShockRing(p1, Lib.SafeLookAt(p1, p1 + lookDir, lookDir), prof.Primary, 0.8 * sc, 4.4 * sc, 0.16, 0.22, Enum.Material.ForceField, folder)
				end)
				Debris:AddItem(proj, flightDur + 0.18)
				Debris:AddItem(core, flightDur + 0.04)

				if i == count then
					task.delay(flightDur, function()
						UniversalVFXOverhaul.SpawnStage3Aftermath(endPos, prof, spec.Radius, sc, isAwakened, isLocal)
					end)
				end
			end)
		end

	elseif arch == "AirCrackShatter" then
		for side = -1, 1, 2 do
			local origin = startPos + pathCF.RightVector * (side * 2.3 * sc) + Vector3.new(0, 1.3, 0)
			local aimCF = Lib.SafeLookAt(origin, endPos, lookDir)
			local pane = Lib.MakePart("SpaceFracturePane", Enum.PartType.Cylinder, Vector3.new(0.12, 7.4 * sc, 7.4 * sc), aimCF * CFrame.Angles(0, math.pi * 0.5, 0), prof.Secondary, 0.22, Enum.Material.Glass, folder)
			local darkRift = Lib.MakePart("SpaceVoidCore", Enum.PartType.Ball, Vector3.new(1.8, 1.8, 0.4) * sc, aimCF, PAL.Obsidian, 0.10, Enum.Material.SmoothPlastic, folder)
			TweenService:Create(pane, TweenInfo.new(0.40, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = Vector3.new(0.05, 14.2 * sc, 14.2 * sc),
				Transparency = 1,
			}):Play()
			TweenService:Create(darkRift, TweenInfo.new(0.34, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = Vector3.new(4.2, 4.2, 0.15) * sc,
				Transparency = 1,
			}):Play()
			Debris:AddItem(pane, 0.44)
			Debris:AddItem(darkRift, 0.38)

			local branches = low and 2 or 5
			for b = 1, branches do
				local bAng = (b / branches) * math.pi * 2 + side * 0.35
				local tip = origin + (aimCF * CFrame.Angles(0, 0, bAng)).RightVector * (5.6 * sc) + lookDir * (3.2 * sc)
				Lib.SpawnJaggedLightning(origin, tip, 4, 0.65 * sc, 0.22 * sc, PAL.HotWhite, prof.Primary, 0.34, folder)
			end
		end
		Lib.SpawnJaggedLightning(startPos + Vector3.new(0, 1.2, 0), endPos, 6, 1.2 * sc, 0.28 * sc, prof.Primary, prof.Secondary, 0.36, folder)
		UniversalVFXOverhaul.SpawnStage3Aftermath(endPos, prof, spec.Radius, sc, isAwakened, isLocal)

	elseif arch == "GroundSpireLine" or arch == "CrystalLanceFan" then
		local isFan = (arch == "CrystalLanceFan")
		for i = 1, count do
			task.delay((i - 1) * (isFan and 0.025 or 0.042), function()
				if isFan then
					local spread = (i - (count + 1) * 0.5) * 0.17
					local dir = (pathCF * CFrame.Angles(0, spread, 0)).LookVector
					local p0 = startPos + Vector3.new(0, 1.8, 0) + pathCF.RightVector * ((i - (count + 1) * 0.5) * 1.3 * sc)
					local p1 = startPos + dir * dist
					local lance = Lib.MakePart("CrystalLance_" .. i, Enum.PartType.Wedge, Vector3.new(0.85 * sc, 0.95 * sc, 4.8 * sc), Lib.SafeLookAt(p0, p1, dir), (i % 2 == 0) and prof.Primary or prof.Secondary, 0.08, Enum.Material.Glass, folder)
					Lib.AttachRibbonTrail(lance, PAL.HotWhite, prof.Primary, prof.Accent, 0.95 * sc, 0.22)
					TweenService:Create(lance, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
						CFrame = Lib.SafeLookAt(p1, p1 + dir, dir),
					}):Play()
					Debris:AddItem(lance, 0.30)
				else
					local frac = i / count
					local p = startPos:Lerp(endPos, frac)
					local gPos = Lib.FindGround(p)
					local h = (4.4 + frac * 5.6) * sc
					local spire = Lib.MakePart("EruptSpire_" .. i, Enum.PartType.Wedge, Vector3.new(1.9 * sc, h, 2.3 * sc), Lib.SafeLookAt(gPos - Vector3.new(0, h * 0.55, 0), gPos + lookDir, lookDir) * CFrame.Angles(-0.24, 0, 0), (i % 2 == 0) and prof.Primary or prof.Secondary, 0.08, prof.Mat, folder)
					local core = Lib.MakePart("SpireCore_" .. i, Enum.PartType.Wedge, Vector3.new(1.0 * sc, h * 0.85, 1.3 * sc), spire.CFrame, PAL.Obsidian, 0.14, Enum.Material.Slate, folder)
					Lib.SpawnShockRing(gPos + Vector3.new(0, 0.14, 0), nil, prof.Primary, 1.0 * sc, 5.4 * sc, 0.18, 0.28, Enum.Material.ForceField, folder)
					local targetCF = Lib.SafeLookAt(gPos + Vector3.new(0, h * 0.45, 0), gPos + Vector3.new(0, h * 0.45, 0) + lookDir, lookDir) * CFrame.Angles(-0.24, 0, 0)
					TweenService:Create(spire, TweenInfo.new(0.17, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { CFrame = targetCF }):Play()
					TweenService:Create(core, TweenInfo.new(0.17, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { CFrame = targetCF }):Play()
					task.delay(0.34, function()
						if spire.Parent then TweenService:Create(spire, TweenInfo.new(0.22), { Transparency = 1 }):Play() end
						if core.Parent then TweenService:Create(core, TweenInfo.new(0.22), { Transparency = 1 }):Play() end
					end)
					Debris:AddItem(spire, 0.60)
					Debris:AddItem(core, 0.60)
				end
			end)
		end
		task.delay(0.26, function()
			UniversalVFXOverhaul.SpawnStage3Aftermath(endPos, prof, spec.Radius, sc, isAwakened, isLocal)
		end)

	elseif arch == "TwinQuakeFist" or arch == "BeastJaws" or arch == "AvianConstruct" then
		local p0 = startPos + lookDir * 2.6 + Vector3.new(0, 0.8, 0)
		local p0CF = Lib.SafeLookAt(p0, endPos, lookDir)
		local head = Lib.MakePart("ConstructHead", (arch == "TwinQuakeFist") and Enum.PartType.Ball or Enum.PartType.Wedge, Vector3.new(3.8, 2.9, 4.8) * sc, p0CF, prof.Primary, 0.10, prof.Mat, folder)
		local core = Lib.MakePart("ConstructObsidian", Enum.PartType.Ball, Vector3.new(2.2, 1.9, 3.0) * sc, head.CFrame, PAL.Obsidian, 0.12, Enum.Material.SmoothPlastic, folder)
		local flankL = Lib.MakePart("ConstructFlankL", Enum.PartType.Wedge, Vector3.new(0.75, 2.4, 4.6) * sc, p0CF * CFrame.new(-2.6 * sc, 0.3, 0.4) * CFrame.Angles(0, 0.48, 0), prof.Secondary, 0.14, Enum.Material.ForceField, folder)
		local flankR = Lib.MakePart("ConstructFlankR", Enum.PartType.Wedge, Vector3.new(0.75, 2.4, 4.6) * sc, p0CF * CFrame.new(2.6 * sc, 0.3, 0.4) * CFrame.Angles(0, -0.48, 0), prof.Secondary, 0.14, Enum.Material.ForceField, folder)
		Lib.AttachRibbonTrail(flankL, PAL.HotWhite, prof.Primary, PAL.Obsidian, 1.3 * sc, 0.24)
		Lib.AttachRibbonTrail(flankR, PAL.HotWhite, prof.Primary, PAL.Obsidian, 1.3 * sc, 0.24)

		local dur = 0.30
		animateOver(dur, function(a)
			local curP = p0:Lerp(endPos, a)
			local base = Lib.SafeLookAt(curP, curP + lookDir, lookDir)
			local flap = (arch == "AvianConstruct") and (math.sin(a * 16) * 0.42) or ((arch == "BeastJaws") and (-a * 0.35) or 0)
			if head.Parent then head.CFrame = base end
			if core.Parent then core.CFrame = base end
			if flankL.Parent then flankL.CFrame = base * CFrame.new(-2.6 * sc, 0.3, 0.4) * CFrame.Angles(0, 0.48, flap) end
			if flankR.Parent then flankR.CFrame = base * CFrame.new(2.6 * sc, 0.3, 0.4) * CFrame.Angles(0, -0.48, -flap) end
		end)
		for _, pt in ipairs({ head, core, flankL, flankR }) do
			Debris:AddItem(pt, dur + 0.18)
		end
		task.delay(dur - 0.02, function()
			UniversalVFXOverhaul.SpawnStage3Aftermath(endPos, prof, spec.Radius, sc, isAwakened, isLocal)
		end)

	elseif arch == "ColossalBeam" or arch == "LaserBeam" or arch == "ZigzagBolt" then
		local mid = (startPos + endPos) * 0.5
		local r = ((arch == "LaserBeam") and 1.55 or 3.15) * sc
		local beamCF = Lib.SafeLookAt(mid, endPos, lookDir) * CFrame.Angles(0, math.pi * 0.5, 0)
		local sheath = Lib.MakePart("HyperBeamSheath", Enum.PartType.Cylinder, Vector3.new(dist, r, r), beamCF, prof.Primary, 0.16, Enum.Material.ForceField, folder)
		local midCore = Lib.MakePart("HyperBeamMid", Enum.PartType.Cylinder, Vector3.new(dist, r * 0.56, r * 0.56), beamCF, prof.Secondary, 0.08, Enum.Material.ForceField, folder)
		local darkSpine = Lib.MakePart("HyperBeamObsidian", Enum.PartType.Cylinder, Vector3.new(dist, r * 0.26, r * 0.26), beamCF, PAL.Obsidian, 0.10, Enum.Material.SmoothPlastic, folder)

		-- Helical ribbon runner spiraling down the beam!
		local helixNode = Lib.MakePart("BeamHelixRunner", Enum.PartType.Ball, Vector3.new(0.45, 0.45, 0.45), CFrame.new(startPos), PAL.HotWhite, 1, Enum.Material.SmoothPlastic, folder)
		Lib.AttachRibbonTrail(helixNode, PAL.HotWhite, prof.Primary, PAL.Obsidian, 1.15 * sc, 0.24)
		animateOver(0.32, function(a)
			if helixNode.Parent then
				local ang = a * math.pi * 6
				local base = Lib.SafeLookAt(startPos:Lerp(endPos, a), endPos + lookDir, lookDir)
				helixNode.CFrame = base * CFrame.new(math.cos(ang) * r * 0.85, math.sin(ang) * r * 0.85, 0)
			end
		end)

		TweenService:Create(sheath, TweenInfo.new(0.40, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = Vector3.new(dist, r * 2.0, r * 2.0),
			Transparency = 1,
		}):Play()
		TweenService:Create(midCore, TweenInfo.new(0.34, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = Vector3.new(dist, r * 0.15, r * 0.15),
			Transparency = 1,
		}):Play()
		TweenService:Create(darkSpine, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = Vector3.new(dist, 0.05, 0.05),
			Transparency = 1,
		}):Play()
		Debris:AddItem(sheath, 0.44)
		Debris:AddItem(midCore, 0.38)
		Debris:AddItem(darkSpine, 0.32)
		Debris:AddItem(helixNode, 0.52)

		if arch == "ZigzagBolt" then
			Lib.SpawnJaggedLightning(startPos, endPos, 8, 1.65 * sc, 0.34 * sc, PAL.HotWhite, prof.Primary, 0.34, folder)
			Lib.SpawnJaggedLightning(startPos, endPos, 7, 1.95 * sc, 0.22 * sc, prof.Secondary, prof.Primary, 0.30, folder)
		end
		UniversalVFXOverhaul.SpawnStage3Aftermath(endPos, prof, spec.Radius, sc, isAwakened, isLocal)

	elseif arch == "EruptionPillar" or arch == "SkyDropPillar" then
		local gPos = Lib.FindGround(endPos)
		local pillarH = 28 * sc
		local pillarR = 5.6 * sc
		local pCF = CFrame.new(gPos + Vector3.new(0, pillarH * 0.5, 0)) * CFrame.Angles(0, 0, math.pi * 0.5)
		local outerCol = Lib.MakePart("JudgmentColumnOuter", Enum.PartType.Cylinder, Vector3.new(pillarH, pillarR * 0.35, pillarR * 0.35), pCF, prof.Primary, 0.16, Enum.Material.ForceField, folder)
		local innerCol = Lib.MakePart("JudgmentColumnObsidian", Enum.PartType.Cylinder, Vector3.new(pillarH, pillarR * 0.18, pillarR * 0.18), pCF, PAL.Obsidian, 0.12, Enum.Material.SmoothPlastic, folder)

		TweenService:Create(outerCol, TweenInfo.new(0.48, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = Vector3.new(pillarH * 1.15, pillarR * 1.75, pillarR * 1.75),
			Transparency = 1,
		}):Play()
		TweenService:Create(innerCol, TweenInfo.new(0.38, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = Vector3.new(pillarH * 1.1, pillarR * 0.72, pillarR * 0.72),
			Transparency = 1,
		}):Play()
		Debris:AddItem(outerCol, 0.52)
		Debris:AddItem(innerCol, 0.42)

		for h = 1, 3 do
			local ring = Lib.MakePart("PillarAscendRing_" .. h, Enum.PartType.Cylinder, Vector3.new(0.24, pillarR * 0.9, pillarR * 0.9), CFrame.new(gPos + Vector3.new(0, h * 3.5 * sc, 0)) * CFrame.Angles(0, 0, math.pi * 0.5), prof.Secondary, 0.16, Enum.Material.ForceField, folder)
			TweenService:Create(ring, TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				CFrame = CFrame.new(gPos + Vector3.new(0, (h * 6.5 + 8) * sc, 0)) * CFrame.Angles(0, 0, math.pi * 0.5),
				Size = Vector3.new(0.08, pillarR * 2.1, pillarR * 2.1),
				Transparency = 1,
			}):Play()
			Debris:AddItem(ring, 0.46)
		end
		UniversalVFXOverhaul.SpawnStage3Aftermath(endPos, prof, spec.Radius, sc, isAwakened, isLocal)

	elseif arch == "DescendingSun" or arch == "MeteorCataclysm" or arch == "SkyRainBarrage" then
		local dropCount = (arch == "DescendingSun") and 1 or math.min(count, low and 3 or 6)
		for i = 1, dropCount do
			task.delay((i - 1) * 0.055, function()
				local ang = (i - 1) * ((math.pi * 2) / math.max(1, dropCount))
				local rad = (dropCount == 1) and 0 or (4.8 * sc)
				local dst = endPos + Vector3.new(math.cos(ang) * rad, 0, math.sin(ang) * rad)
				local skyOrigin = dst + Vector3.new(-4.5 * sc, 24 * sc, -3.5 * sc)
				local orbSz = ((dropCount == 1) and 10.2 or 4.0) * sc
				local isMeteor = (arch == "MeteorCataclysm")

				local core = Lib.MakePart("CelestialDropCore", Enum.PartType.Ball, Vector3.new(orbSz * 0.76, orbSz * 0.76, orbSz * 0.76), CFrame.new(skyOrigin), isMeteor and PAL.Obsidian or prof.Primary, 0.06, isMeteor and Enum.Material.Slate or Enum.Material.SmoothPlastic, folder)
				local corona = Lib.MakePart("CelestialDropCorona", Enum.PartType.Ball, Vector3.new(orbSz * 1.18, orbSz * 1.18, orbSz * 1.18), CFrame.new(skyOrigin), (dropCount == 1) and prof.Secondary or prof.Primary, 0.24, Enum.Material.ForceField, folder)
				Lib.AttachRibbonTrail(corona, PAL.HotWhite, prof.Primary, PAL.Obsidian, orbSz * 0.75, 0.28)
				if dropCount == 1 then
					Lib.SafeLight(corona, prof.Primary, 1.42, 16, 0.40)
				end

				TweenService:Create(core, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = dst }):Play()
				TweenService:Create(corona, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = dst }):Play()
				Debris:AddItem(core, 0.36)
				Debris:AddItem(corona, 0.50)

				if dropCount > 1 then
					task.delay(0.31, function()
						Lib.SpawnShockRing(Lib.FindGround(dst) + Vector3.new(0, 0.14, 0), nil, prof.Primary, 1.2 * sc, 6.8 * sc, 0.20, 0.30, Enum.Material.ForceField, folder)
					end)
				end
				if i == dropCount then
					task.delay(0.31, function()
						UniversalVFXOverhaul.SpawnStage3Aftermath(endPos, prof, spec.Radius, sc, isAwakened, isLocal)
					end)
				end
			end)
		end

	elseif arch == "PortalRingStrike" or arch == "PortalGateDash" or arch == "PortalFistBarrage" then
		local function makeStargate(gatePos, aimPos, col)
			local cf = Lib.SafeLookAt(gatePos, aimPos, lookDir) * CFrame.Angles(0, math.pi * 0.5, 0)
			local rim = Lib.MakePart("StargateRim", Enum.PartType.Cylinder, Vector3.new(0.26, 6.8 * sc, 6.8 * sc), cf, col, 0.12, Enum.Material.ForceField, folder)
			local horizon = Lib.MakePart("StargateHorizon", Enum.PartType.Cylinder, Vector3.new(0.18, 5.2 * sc, 5.2 * sc), cf, PAL.Obsidian, 0.08, Enum.Material.SmoothPlastic, folder)
			TweenService:Create(rim, TweenInfo.new(0.46, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = Vector3.new(0.08, 10.2 * sc, 10.2 * sc),
				Transparency = 1,
			}):Play()
			TweenService:Create(horizon, TweenInfo.new(0.40, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = Vector3.new(0.06, 0.5, 0.5),
				Transparency = 1,
			}):Play()
			Debris:AddItem(rim, 0.50)
			Debris:AddItem(horizon, 0.44)
		end

		makeStargate(startPos + lookDir * 2.0, endPos, prof.Primary)
		makeStargate(endPos, endPos + lookDir, prof.Secondary)
		Lib.SpawnJaggedLightning(startPos + lookDir * 2.0, endPos, 6, 1.1 * sc, 0.24 * sc, prof.Primary, prof.Accent, 0.34, folder)

		if arch == "PortalFistBarrage" then
			for i = 1, count do
				task.delay((i - 1) * 0.035, function()
					local ang = i * 1.15
					local p0 = endPos + Vector3.new(math.cos(ang) * 7.5 * sc, 2.8 + (i % 3) * 1.5, math.sin(ang) * 7.5 * sc)
					local aimCF = Lib.SafeLookAt(p0, endPos, lookDir)
					local miniRim = Lib.MakePart("MiniPortalRift", Enum.PartType.Cylinder, Vector3.new(0.18, 3.0 * sc, 3.0 * sc), aimCF * CFrame.Angles(0, math.pi * 0.5, 0), prof.Accent, 0.14, Enum.Material.ForceField, folder)
					local fist = Lib.MakePart("PortalHakiFist", Enum.PartType.Ball, Vector3.new(1.85, 1.85, 2.8) * sc, aimCF, prof.Primary, 0.06, Enum.Material.SmoothPlastic, folder)
					Lib.AttachRibbonTrail(fist, prof.Primary, prof.Secondary, PAL.Obsidian, 1.1 * sc, 0.18)
					TweenService:Create(fist, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
						CFrame = Lib.SafeLookAt(endPos, endPos + (endPos - p0), aimCF.LookVector),
						Transparency = 0.75,
					}):Play()
					TweenService:Create(miniRim, TweenInfo.new(0.26), { Transparency = 1 }):Play()
					Debris:AddItem(fist, 0.26)
					Debris:AddItem(miniRim, 0.30)
				end)
			end
		end
		task.delay(0.24, function()
			UniversalVFXOverhaul.SpawnStage3Aftermath(endPos, prof, spec.Radius, sc, isAwakened, isLocal)
		end)

	elseif arch == "CubeSanctuary" or arch == "GravityCrushZone" or arch == "FrostNovaDomain" or arch == "CataclysmDome" or arch == "TectonicTsunami" then
		local shape = (arch == "CubeSanctuary") and Enum.PartType.Block or Enum.PartType.Ball
		local r = (spec.Radius or 18) * sc
		local domain = Lib.MakePart("DomainOuterField", shape, Vector3.new(3.5, 3.5, 3.5), CFrame.new(endPos), prof.Primary, 0.26, (arch == "FrostNovaDomain") and Enum.Material.Glass or Enum.Material.ForceField, folder)
		local innerVoid = Lib.MakePart("DomainDarkHeart", shape, Vector3.new(2.2, 2.2, 2.2), CFrame.new(endPos), PAL.Obsidian, 0.24, Enum.Material.SmoothPlastic, folder)
		local targetSz = (arch == "GravityCrushZone") and Vector3.new(r * 1.45, 2.2 * sc, r * 1.45)
			or ((arch == "TectonicTsunami") and Vector3.new(r * 1.6, r * 0.85, r * 1.2) or Vector3.new(r * 1.38, r * 1.38, r * 1.38))

		TweenService:Create(domain, TweenInfo.new(0.56, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = targetSz,
			CFrame = domain.CFrame * CFrame.Angles(0, 0.95, 0),
			Transparency = 1,
		}):Play()
		TweenService:Create(innerVoid, TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = targetSz * 0.56,
			CFrame = innerVoid.CFrame * CFrame.Angles(0, -0.75, 0),
			Transparency = 1,
		}):Play()
		Debris:AddItem(domain, 0.60)
		Debris:AddItem(innerVoid, 0.46)
		UniversalVFXOverhaul.SpawnStage3Aftermath(endPos, prof, spec.Radius, sc, isAwakened, isLocal)

	else
		-- SlipstreamRush / WhirlwindDash / IceTrackDash / LightReflectDash / WheelRollSmash / SerpentRush
		local runner = Lib.MakePart("RushRibbonHead", Enum.PartType.Ball, Vector3.new(1.1, 1.1, 1.1) * sc, CFrame.new(startPos), prof.Primary, 0.25, Enum.Material.ForceField, folder)
		Lib.AttachRibbonTrail(runner, PAL.HotWhite, prof.Primary, PAL.Obsidian, 2.1 * sc, 0.32)

		animateOver(0.24, function(a)
			if runner.Parent then
				local p = startPos:Lerp(endPos, a)
				if arch == "SerpentRush" then
					local sway = math.sin(a * math.pi * 4) * 2.4 * sc
					p = p + pathCF.RightVector * sway + Vector3.new(0, math.cos(a * math.pi * 4) * 1.1 * sc, 0)
				elseif arch == "LightReflectDash" then
					local zig = ((math.floor(a * 4) % 2 == 0) and 1 or -1) * math.sin(a * math.pi * 4) * 3.0 * sc
					p = p + pathCF.RightVector * zig
				end
				runner.CFrame = Lib.SafeLookAt(p, p + lookDir, lookDir)
			end
		end)
		Debris:AddItem(runner, 0.56)

		for i = 1, count do
			local frac = i / count
			task.delay((i - 1) * 0.026, function()
				local p = startPos:Lerp(endPos, frac)
				local isIce = (arch == "IceTrackDash")
				local isWheel = (arch == "WheelRollSmash")
				local shape = isIce and Enum.PartType.Block or Enum.PartType.Cylinder
				local sz = isIce and Vector3.new(3.8 * sc, 0.42, 4.4 * sc)
					or Vector3.new(0.46 * sc, (3.8 + (isWheel and 2.4 or 0)) * sc, (3.8 + (isWheel and 2.4 or 0)) * sc)
				local gPos = Lib.FindGround(p)
				local cf = isIce and Lib.SafeLookAt(gPos + Vector3.new(0, 0.16, 0), gPos + Vector3.new(0, 0.16, 0) + lookDir, lookDir)
					or (Lib.SafeLookAt(p, p + lookDir, lookDir) * CFrame.Angles(0, isWheel and 0 or math.pi * 0.5, frac * 3.14))
				local seg = Lib.MakePart("RushWake_" .. i, shape, sz, cf, (i % 2 == 0) and prof.Primary or prof.Secondary, 0.14, prof.Mat, folder)
				TweenService:Create(seg, TweenInfo.new(0.36, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					Size = isIce and Vector3.new(1.2, 0.08, 4.4 * sc) or Vector3.new(0.10, 8.6 * sc, 8.6 * sc),
					Transparency = 1,
				}):Play()
				Debris:AddItem(seg, 0.40)
			end)
		end
		task.delay(0.22, function()
			UniversalVFXOverhaul.SpawnStage3Aftermath(endPos, prof, spec.Radius, sc, isAwakened, isLocal)
		end)
	end
end

-- ============================================================================
-- 4. ALL 6 MARTIAL ARTS FIGHTING STYLES (BESPOKE KATA CHOREOGRAPHY)
-- ============================================================================
function UniversalVFXOverhaul.SpawnMartialKata(styleProf, moveKey, startPos, endPos, lookDir, scale, isAwakened, isLocal)
	local sc = math.clamp(scale or 1, 0.7, 2.0)
	local folder = Lib.GetTempFolder("UniversalVFX")
	local low = Lib.IsLowFX()
	local prof = {
		Primary = styleProf.Primary,
		Secondary = styleProf.Secondary,
		Accent = PAL.Slate,
		Element = (styleProf.Style == "VoltClawSlashes" and "Thunder")
			or (styleProf.Style == "BlazeKickArcs" and "Flame")
			or (styleProf.Style == "WaterVortex" and "Ice")
			or "Sky",
		Mat = Enum.Material.ForceField,
	}

	lookDir = (typeof(lookDir) == "Vector3" and lookDir.Magnitude > 0.05) and lookDir.Unit or Vector3.new(0, 0, -1)
	UniversalVFXOverhaul.SpawnStage1Sigil(Lib.SafeLookAt(startPos, startPos + lookDir, lookDir), prof, sc * 0.9, moveKey == "V" or isAwakened)
	local dst = ((endPos - startPos).Magnitude > 3.5) and endPos or (startPos + lookDir * 20 * sc)
	Lib.Emit("Combat", "Martial_KataBurst", Lib.SafeLookAt(startPos + lookDir * 1.8, dst, lookDir), sc, prof.Primary, prof.Secondary)

	-- FADE / Haymaker Martial Kata Backbone per Move Key (Z / X / C / V)
	local mk = tostring(moveKey or "Z")
	if mk == "Z" then
		Lib.SpawnFadeGroundSlashRibbon(startPos, dst, 1.8 * sc, prof.Primary, prof.Secondary, 0.38, folder)
	elseif mk == "X" then
		Lib.SpawnFadeCorkscrewTunnel(startPos + Vector3.new(0, 1.2, 0), dst + Vector3.new(0, 1.2, 0), 2.6 * sc, 5, prof.Primary, prof.Secondary, 0.40, folder)
		Lib.SpawnFadeGroundSlashRibbon(startPos, dst, 2.1 * sc, prof.Primary, prof.Secondary, 0.42, folder)
	elseif mk == "C" then
		Lib.SpawnFadeJaggedImpactSpikes(dst, 11.5 * sc, low and 5 or 8, prof.Primary, prof.Secondary, 0.56, folder)
		if isLocal then Lib.TriggerAnimeImpactFrame(prof.Primary, 0.032, 3.2, 0.38) end
	elseif mk == "V" then
		Lib.SpawnFadeCorkscrewTunnel(startPos + Vector3.new(0, 1.5, 0), dst + Vector3.new(0, 1.4, 0), 3.6 * sc, 7, prof.Primary, prof.Secondary, 0.50, folder)
		Lib.SpawnFadeGroundSlashRibbon(startPos, dst, 3.2 * sc, prof.Primary, prof.Secondary, 0.55, folder)
		Lib.SpawnFadeJaggedImpactSpikes(dst, 16.5 * sc, low and 7 or 12, prof.Primary, prof.Secondary, 0.68, folder)
		if isLocal then Lib.TriggerAnimeImpactFrame(prof.Primary, 0.045, 5.4, 0.56) end
	end

	local count = (moveKey == "V") and 8 or ((moveKey == "C") and 6 or 4)
	if low then count = math.max(2, math.floor(count * 0.35 + 0.5)) end
	local style = styleProf.Style

	if style == "VoltClawSlashes" or style == "DraconicTalons" then
		for i = 1, count do
			task.delay((i - 1) * 0.032, function()
				local frac = i / count
				local p = startPos:Lerp(dst, frac)
				local tilt = (i % 2 == 0) and 0.62 or -0.62
				for c = -1, 1 do
					local clawCF = Lib.SafeLookAt(p, p + lookDir, lookDir) * CFrame.new(c * 0.82 * sc, 0.4, 0) * CFrame.Angles(0.18, 0, tilt)
					local claw = Lib.MakePart("TalonRake_" .. c, Enum.PartType.Block, Vector3.new(0.20 * sc, 0.24 * sc, 5.8 * sc), clawCF, (c == 0) and PAL.HotWhite or prof.Primary, 0.08, Enum.Material.ForceField, folder)
					local dark = Lib.MakePart("TalonDark_" .. c, Enum.PartType.Block, Vector3.new(0.10 * sc, 0.12 * sc, 4.6 * sc), clawCF, PAL.Obsidian, 0.12, Enum.Material.SmoothPlastic, folder)
					TweenService:Create(claw, TweenInfo.new(0.24), { Size = Vector3.new(0.04, 0.04, 8.8 * sc), Transparency = 1 }):Play()
					TweenService:Create(dark, TweenInfo.new(0.20), { Size = Vector3.new(0.02, 0.02, 6.8 * sc), Transparency = 1 }):Play()
					Debris:AddItem(claw, 0.28)
					Debris:AddItem(dark, 0.24)
				end
				if style == "VoltClawSlashes" then
					Lib.SpawnJaggedLightning(startPos + Vector3.new(0, 0.8, 0), p, 4, 0.9 * sc, 0.18 * sc, PAL.HotWhite, prof.Primary, 0.24, folder)
				end
			end)
		end

	elseif style == "BlazeKickArcs" then
		for i = 1, math.max(2, math.floor(count * 0.75)) do
			task.delay((i - 1) * 0.045, function()
				local tilt = (i % 2 == 0) and 0.85 or -0.85
				spawnLayeredSlashWave(startPos + Vector3.new(0, 0.5, 0), dst, tilt, sc * 0.95, prof.Primary, prof.Secondary, 0.30, folder)
			end)
		end

	elseif style == "WaterVortex" then
		local swimmer = Lib.MakePart("TideDragonHead", Enum.PartType.Ball, Vector3.new(1.3, 1.3, 1.8) * sc, Lib.SafeLookAt(startPos, dst, lookDir), prof.Primary, 0.14, Enum.Material.Glass, folder)
		Lib.AttachRibbonTrail(swimmer, PAL.HotWhite, prof.Primary, PAL.Cyan, 1.8 * sc, 0.28)
		animateOver(0.26, function(a)
			if swimmer.Parent then
				local p = startPos:Lerp(dst, a)
				local ang = a * math.pi * 5
				local base = Lib.SafeLookAt(p, p + lookDir, lookDir)
				swimmer.CFrame = base * CFrame.new(math.cos(ang) * 2.1 * sc, math.sin(ang) * 1.6 * sc, 0)
			end
		end)
		Debris:AddItem(swimmer, 0.54)
		for i = 1, count do
			task.delay((i - 1) * 0.032, function()
				local p = startPos:Lerp(dst, i / count)
				Lib.SpawnShockRing(p, Lib.SafeLookAt(p, p + lookDir, lookDir) * CFrame.Angles(math.pi * 0.5, 0, 0), (i % 2 == 0) and prof.Primary or prof.Secondary, 2.2 * sc, 9.2 * sc, 0.22, 0.32, Enum.Material.Glass, folder)
			end)
		end

	elseif style == "GodhumanPrism" then
		Lib.SpawnFadeCorkscrewTunnel(startPos + Vector3.new(0, 1.3, 0), dst + Vector3.new(0, 1.3, 0), 3.0 * sc, count, PAL.Gold, PAL.Cyan, 0.38, folder)

	else
		-- PalmRings (Skyborn Combat)
		Lib.SpawnFadeCorkscrewTunnel(startPos + Vector3.new(0, 1.2, 0), dst + Vector3.new(0, 1.2, 0), 2.6 * sc, count, prof.Primary, prof.Secondary, 0.36, folder)
	end

	local rad = (moveKey == "V") and 18 or ((moveKey == "C") and 13 or 9)
	task.delay(0.20, function()
		UniversalVFXOverhaul.SpawnStage3Aftermath(dst, prof, rad, sc, moveKey == "V" or isAwakened, isLocal)
	end)
end

-- ============================================================================
-- 5. BASIC MELEE M1 COMBOS 1-4 & HEAVY CLEAVE (FADE SHOWCASE SLASH & TUNNEL)
-- ============================================================================
function UniversalVFXOverhaul.SpawnMeleeCombo(actorChar, startPos, lookDir, combo, isHeavy, hakiColor, isAwakened, isLocal)
	local folder = Lib.GetTempFolder("UniversalVFX")
	lookDir = (typeof(lookDir) == "Vector3" and lookDir.Magnitude > 0.05) and lookDir.Unit or Vector3.new(0, 0, -1)
	local cNum = math.clamp(tonumber(combo) or 1, 1, 4)
	local isFinisher = isHeavy or (cNum == 4)
	local expProf = ExpansionVFX.GetSwordVFXProfile(actorChar, nil)
	local primary = hakiColor or (expProf and expProf.Primary) or (isHeavy and PAL.Gold or PAL.Cyan)
	local secondary = hakiColor and PAL.HotWhite or (expProf and expProf.Secondary) or (isHeavy and PAL.Solar or PAL.HotWhite)
	local sc = (isHeavy and 1.25 or (cNum == 4 and 1.12 or 0.90)) * (isAwakened and 1.2 or 1.0)
	local reach = isFinisher and 10.5 or 7.2
	local dst = startPos + lookDir * reach

	ExpansionVFX.SpawnExpansionM1Extra(Lib, folder, actorChar, startPos, dst, lookDir, cNum, isFinisher, sc)

	-- VibeGG 5-Step Melee Slash Juice (Hit Flash, Random Pitch Sound, Directional Sparks, Knockback, Hit-Stop & Shake)
	Lib.VibeGG_MeleeHit5Steps(dst, lookDir, isFinisher, isHeavy, nil, isLocal)

	if isFinisher then
		-- X-Cross Dual Curved Crescent Wave + Haymaker Corkscrew Finisher Tunnel + Ground Slash Ribbon
		spawnLayeredSlashWave(startPos + lookDir * 1.4, dst, 0.56, sc, primary, secondary, 0.28, folder)
		spawnLayeredSlashWave(startPos + lookDir * 1.4, dst, -0.56, sc, secondary, primary, 0.28, folder)
		Lib.SpawnFadeCorkscrewTunnel(startPos + lookDir * 1.2 + Vector3.new(0, 1.0, 0), dst + Vector3.new(0, 1.0, 0), 2.1 * sc, 4, primary, secondary, 0.30, folder)
		Lib.SpawnFadeGroundSlashRibbon(startPos + lookDir * 1.0, dst, 1.8 * sc, primary, secondary, 0.34, folder)
		Lib.Emit("Combat", "Sword_SlashWave", Lib.SafeLookAt(startPos + lookDir * 2.5, dst, lookDir), sc, primary, PAL.Obsidian)
		local gPos = Lib.FindGround(startPos + lookDir * 4.2)
		Lib.SpawnShockRing(gPos + Vector3.new(0, 0.14, 0), nil, primary, 1.8 * sc, 11.2 * sc, 0.22, 0.32, Enum.Material.ForceField, folder)
		if isLocal then
			Lib.EmitCameraTrauma(isHeavy and 0.30 or 0.22, isHeavy and 2.2 or 1.2, lookDir)
		end
	else
		local tilts = { -0.52, 0.54, -0.18 }
		spawnLayeredSlashWave(startPos + lookDir * 1.4, dst, tilts[cNum] or 0.48, sc, primary, secondary, 0.22, folder)
		Lib.SpawnFadeGroundSlashRibbon(startPos + lookDir * 1.2, dst, 1.15 * sc, primary, secondary, 0.26, folder)
		Lib.Emit("Combat", "Sword_SlashWave", Lib.SafeLookAt(startPos + lookDir * 2.2, dst, lookDir), sc * 0.72, primary, PAL.Obsidian)
	end
end

-- ============================================================================
-- 6. BESPOKE CLASS SKILLS, SWORD SLASHES, GUN RAIL-SHOTS & SHIELD BUBBLES
-- ============================================================================
function UniversalVFXOverhaul.SpawnShieldBubble(targetChar, isArcane)
	local r = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
	if not r then return end
	local folder = Lib.GetTempFolder("UniversalVFX")
	local col = isArcane and PAL.Violet or PAL.Gold
	local subCol = isArcane and PAL.Cyan or PAL.Cyan

	local old = folder:FindFirstChild("AegisSanctuary_" .. targetChar.Name)
	if old then old:Destroy() end

	local model = Instance.new("Model")
	model.Name = "AegisSanctuary_" .. targetChar.Name
	model.Parent = folder

	local dome = Lib.MakePart("SanctuaryShell", Enum.PartType.Ball, Vector3.new(8.2, 8.2, 8.2), r.CFrame, col, 0.42, Enum.Material.ForceField, model)
	local ringA = Lib.MakePart("SanctuaryHaloA", Enum.PartType.Cylinder, Vector3.new(0.14, 9.2, 9.2), r.CFrame, subCol, 0.24, Enum.Material.ForceField, model)
	local ringB = Lib.MakePart("SanctuaryHaloB", Enum.PartType.Cylinder, Vector3.new(0.14, 9.2, 9.2), r.CFrame, col, 0.28, Enum.Material.ForceField, model)
	Lib.SpawnShockRing(r.Position, nil, col, 2.0, 12.5, 0.24, 0.38, Enum.Material.ForceField, folder)

	local untilTime = os.clock() + 5.0
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not model.Parent or not r.Parent or os.clock() >= untilTime then
			if conn then conn:Disconnect() end
			if model.Parent then model:Destroy() end
			return
		end
		local t = os.clock()
		local base = CFrame.new(r.Position)
		dome.CFrame = base * CFrame.Angles(0, t * 1.2, 0)
		ringA.CFrame = base * CFrame.Angles(0.55, t * 2.4, math.pi * 0.5)
		ringB.CFrame = base * CFrame.Angles(-0.55, -t * 2.1, math.pi * 0.5)
	end)
end

function UniversalVFXOverhaul.SpawnClassOrWeaponSkill(action, kind, moveKey, actorChar, startPos, endPos, lookDir, scale, isAwakened, isLocal, fx)
	local act = tostring(action or "")
	local k = tostring(kind or "")
	local sc = math.clamp(scale or 1, 0.7, 2.1)
	local folder = Lib.GetTempFolder("UniversalVFX")
	lookDir = (typeof(lookDir) == "Vector3" and lookDir.Magnitude > 0.05) and lookDir.Unit or Vector3.new(0, 0, -1)
	local dst = ((endPos - startPos).Magnitude > 4) and endPos or (startPos + lookDir * 24 * sc)

	-- 0. World & Economy Event VFX (ChestOpened, ShipCannonBlast, LootOrbPickup, CloudGeyserRescue)
	if k == "ChestOpened" then
		local tier = tostring((type(fx) == "table" and fx.Tier) or "Gold")
		local col = (tier == "Mythic" or tier == "Diamond") and PAL.Cyan or PAL.Gold
		local sub = (tier == "Mythic" or tier == "Diamond") and PAL.Violet or PAL.Solar
		Lib.Emit("TraversalAndWorld", "Progression_LevelUp", CFrame.new(startPos), 1.05, col, sub)
		Lib.SpawnShockRing(startPos + Vector3.new(0, 0.35, 0), nil, col, 1.4, 9.6, 0.22, 0.42, Enum.Material.ForceField, folder)
		Lib.SpawnShockRing(startPos + Vector3.new(0, 1.1, 0), nil, sub, 1.0, 6.8, 0.16, 0.34, Enum.Material.ForceField, folder)
		return true
	elseif k == "LootOrbPickup" then
		local rar = tostring((type(fx) == "table" and fx.Rarity) or "Rare")
		local col = (rar == "Mythic" and PAL.Crimson) or (rar == "Legendary" and PAL.Gold) or PAL.Cyan
		Lib.Emit("TraversalAndWorld", "Progression_Heal", CFrame.new(startPos), 0.85, col, PAL.HotWhite)
		Lib.SpawnShockRing(startPos, nil, col, 0.8, 5.4, 0.16, 0.28, Enum.Material.ForceField, folder)
		return true
	elseif k == "ShipCannonBlast" then
		local prof = { Primary = PAL.Solar, Secondary = PAL.Gold, Accent = PAL.Obsidian, Element = "Magma", Mat = Enum.Material.ForceField }
		UniversalVFXOverhaul.SpawnStage3Aftermath(endPos, prof, 13, sc, false, isLocal)
		return true
	elseif k == "CloudGeyserRescue" then
		local gPos = Lib.FindGround(startPos)
		Lib.Emit("TraversalAndWorld", "Traversal_Geppo", CFrame.new(startPos), 1.4, PAL.Wind, PAL.Cyan)
		Lib.SpawnShockRing(gPos + Vector3.new(0, 0.2, 0), nil, PAL.Wind, 2.5, 16.5, 0.26, 0.45, Enum.Material.ForceField, folder)
		local column = Lib.MakePart("CloudGeyserColumn", Enum.PartType.Cylinder, Vector3.new(20, 3.2, 3.2), CFrame.new(startPos + Vector3.new(0, 10, 0)) * CFrame.Angles(0, 0, math.pi * 0.5), PAL.Wind, 0.22, Enum.Material.ForceField, folder)
		TweenService:Create(column, TweenInfo.new(0.50, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = Vector3.new(24, 10.5, 10.5), Transparency = 1 }):Play()
		Debris:AddItem(column, 0.55)
		return true
	end

	-- A. Slot 4 Guns / Railgun Tracer Shots (FADE Corkscrew Tunnel + Muzzle Crescent Ring)
	if k == "GunShot" or act:find("Gun") or act:find("Rifle") or act:find("Shot") or act:find("Bullet") or act:find("Rail") then
		if moveKey == "Z" or moveKey == "X" then
			if ExpansionVFX.SpawnExpansionSkillVFX(Lib, UniversalVFXOverhaul, spawnLayeredSlashWave, folder, act, k, moveKey, actorChar, startPos, dst, lookDir, sc, isAwakened, isLocal, fx) then
				return true
			end
		elseif ExpansionVFX.SpawnExpansionGunShot(Lib, UniversalVFXOverhaul, folder, actorChar, startPos, dst, lookDir, sc, isLocal, fx) then
			return true
		end
		local muzzlePos = startPos + lookDir * 2.0 + Vector3.new(0, 0.5, 0)
		local col = PAL.Cyan
		local sub = PAL.Violet
		local aimCF = Lib.SafeLookAt(muzzlePos, dst, lookDir)
		if actorChar then Lib.PlaySkillCastPose(actorChar, moveKey or "Z", 0.26) end
		Lib.VibeGG_Gunplay5Steps(muzzlePos, dst, lookDir, col, sub, sc, (moveKey == "X" or moveKey == "V" or isAwakened), isLocal, actorChar)
		Lib.Emit("Combat", "Gun_RailBurst", aimCF, sc, col, sub)
		Lib.SpawnFadeCorkscrewTunnel(muzzlePos, dst, 1.85 * sc, 5, col, sub, 0.32, folder)

		local bullet = Lib.MakePart("RailSlug", Enum.PartType.Ball, Vector3.new(0.4, 0.4, 0.4), CFrame.new(muzzlePos), PAL.HotWhite, 1, Enum.Material.SmoothPlastic, folder)
		Lib.AttachRibbonTrail(bullet, PAL.HotWhite, col, PAL.Obsidian, 0.9 * sc, 0.22)
		animateOver(0.14, function(a)
			if bullet.Parent then bullet.CFrame = CFrame.new(muzzlePos:Lerp(dst, a)) end
		end, function()
			Lib.Emit("Combat", "Gun_RailBurst", CFrame.new(dst), sc * 1.15, PAL.Gold, col)
			Lib.SpawnShockRing(dst, nil, PAL.Gold, 1.2 * sc, 8.6 * sc, 0.22, 0.28, Enum.Material.ForceField, folder)
		end)
		Debris:AddItem(bullet, 0.40)
		if isLocal then Lib.EmitCameraTrauma(0.24, 1.6, lookDir) end
		return true
	end

	-- B. Slot 3 Swords / SkySlash / ChargedSlash (FADE Ground Slash Ribbon + Crescent Waves + Jagged Spikes)
	if k == "ChargedSlash" or act == "SkySlash" or act:find("Slash") or act:find("Blade") or act:find("Sword") then
		if ExpansionVFX.SpawnExpansionSkillVFX(Lib, UniversalVFXOverhaul, spawnLayeredSlashWave, folder, act, k, moveKey, actorChar, startPos, dst, lookDir, sc, isAwakened, isLocal, fx) then
			return true
		end
		local col = (act:find("Void") or act:find("Abyss")) and PAL.Violet or PAL.Gold
		local sub = PAL.Cyan
		if actorChar then Lib.PlaySkillCastPose(actorChar, moveKey or "Z", 0.34) end
		UniversalVFXOverhaul.SpawnStage1Sigil(Lib.SafeLookAt(startPos, dst, lookDir), { Primary = col, Secondary = sub, Accent = PAL.Slate, Element = "Light" }, sc * 0.9, isAwakened)
		Lib.Emit("Combat", "Sword_SlashWave", Lib.SafeLookAt(startPos + lookDir * 2.2, dst, lookDir), sc * 1.2, col, sub)
		Lib.SpawnFadeGroundSlashRibbon(startPos, dst, 2.2 * sc, col, sub, 0.44, folder)
		spawnLayeredSlashWave(startPos + Vector3.new(0, 0.6, 0), dst, 0.36, sc * 1.18, col, sub, 0.32, folder)
		spawnLayeredSlashWave(startPos + Vector3.new(0, 0.6, 0), dst, -0.36, sc * 1.05, sub, col, 0.32, folder)
		if moveKey == "X" or moveKey == "C" or moveKey == "V" then
			Lib.SpawnFadeCorkscrewTunnel(startPos + Vector3.new(0, 1.1, 0), dst + Vector3.new(0, 1.1, 0), 2.5 * sc, 5, col, sub, 0.38, folder)
		end
		if moveKey == "C" or moveKey == "V" then
			if isLocal then Lib.TriggerAnimeImpactFrame(col, 0.038, 4.2, 0.45) end
		end
		task.delay(0.28, function()
			UniversalVFXOverhaul.SpawnStage3Aftermath(dst, { Primary = col, Secondary = sub, Accent = PAL.Slate, Element = "Light" }, (moveKey == "V" and 16 or 10), sc, isAwakened, isLocal)
		end)
		return true
	end

	-- C. SkyGuardian: GuardianShield, JudgmentStrike, CelestialAegis
	if act == "GuardianShield" or act == "ManaBarrier" then
		if actorChar then
			UniversalVFXOverhaul.SpawnShieldBubble(actorChar, act == "ManaBarrier")
		end
		return true
	elseif act == "JudgmentStrike" or act == "CelestialAegis" then
		local isUlt = (act == "CelestialAegis")
		local gPos = Lib.FindGround(dst)
		local prof = { Primary = PAL.Gold, Secondary = PAL.Cyan, Accent = PAL.Slate, Element = "Sky" }
		UniversalVFXOverhaul.SpawnStage1Sigil(CFrame.new(dst), prof, sc * (isUlt and 1.35 or 1.0), true)

		-- Descending Colossal Celestial Greatsword Construct!
		local skyStart = gPos + Vector3.new(0, 26 * sc, 0)
		local landPos = gPos + Vector3.new(0, 4.5 * sc, 0)
		local blade = Lib.MakePart("CelestialGreatswordBlade", Enum.PartType.Block, Vector3.new(2.2 * sc, 14.5 * sc, 0.55 * sc), CFrame.new(skyStart), PAL.Gold, 0.08, Enum.Material.ForceField, folder)
		local spine = Lib.MakePart("CelestialGreatswordCore", Enum.PartType.Block, Vector3.new(0.85 * sc, 13.5 * sc, 0.65 * sc), CFrame.new(skyStart), PAL.Obsidian, 0.10, Enum.Material.SmoothPlastic, folder)
		local guard = Lib.MakePart("CelestialCrossguard", Enum.PartType.Block, Vector3.new(5.8 * sc, 0.95 * sc, 0.85 * sc), CFrame.new(skyStart + Vector3.new(0, 6.2 * sc, 0)), PAL.Cyan, 0.10, Enum.Material.ForceField, folder)

		TweenService:Create(blade, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { CFrame = CFrame.new(landPos) }):Play()
		TweenService:Create(spine, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { CFrame = CFrame.new(landPos) }):Play()
		TweenService:Create(guard, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.In), { CFrame = CFrame.new(landPos + Vector3.new(0, 6.2 * sc, 0)) }):Play()

		task.delay(0.22, function()
			UniversalVFXOverhaul.SpawnStage3Aftermath(gPos, prof, isUlt and 22 or 14, sc, true, isLocal)
			if isUlt then
				-- 6 Orbiting Spirit Swords around Sanctuary Arena
				local spirits = {}
				for i = 1, 6 do
					local sb = Lib.MakePart("AegisSpiritBlade_" .. i, Enum.PartType.Block, Vector3.new(0.85 * sc, 5.2 * sc, 0.28 * sc), CFrame.new(gPos), (i % 2 == 0) and PAL.Gold or PAL.Cyan, 0.12, Enum.Material.ForceField, folder)
					Lib.AttachRibbonTrail(sb, PAL.HotWhite, PAL.Gold, PAL.Cyan, 1.2 * sc, 0.22)
					table.insert(spirits, sb)
				end
				animateOver(0.75, function(a)
					for idx, sb in ipairs(spirits) do
						if sb.Parent then
							local ang = a * math.pi * 3.5 + (idx - 1) * (math.pi / 3)
							local rad = (8.5 + a * 4.5) * sc
							local p = gPos + Vector3.new(math.cos(ang) * rad, 3.6 * sc, math.sin(ang) * rad)
							sb.CFrame = Lib.SafeLookAt(p, gPos + Vector3.new(0, 3.6 * sc, 0), lookDir) * CFrame.Angles(0.35, 0, 0)
							sb.Transparency = 0.12 + a * 0.88
						end
					end
				end)
				for _, sb in ipairs(spirits) do Debris:AddItem(sb, 0.95) end
			end
			for _, pt in ipairs({ blade, spine, guard }) do
				if pt.Parent then
					TweenService:Create(pt, TweenInfo.new(0.36), { Transparency = 1 }):Play()
				end
			end
		end)
		Debris:AddItem(blade, 0.65)
		Debris:AddItem(spine, 0.65)
		Debris:AddItem(guard, 0.65)
		return true
	end

	-- D. ThunderStriker: ArcCut, StormBlitz, ThunderJudgement
	if act == "ArcCut" or act == "StormBlitz" or act == "ThunderJudgement" then
		local prof = { Primary = PAL.Thunder, Secondary = PAL.Violet, Accent = PAL.Slate, Element = "Thunder" }
		UniversalVFXOverhaul.SpawnStage1Sigil(Lib.SafeLookAt(startPos, dst, lookDir), prof, sc, act == "ThunderJudgement" or isAwakened)
		-- VibeGG 5-Step Lightning (Zigzag + Sub-branches, Taper, Dual-Layer Glow, White Core, 4-Frame Flicker + Electro-Convulsion & Charred Smoke Finisher)
		Lib.VibeGG_Lightning5Steps(startPos + Vector3.new(0, 1.5, 0), dst, sc, PAL.Thunder, PAL.Violet, act == "ThunderJudgement" or isAwakened, isLocal, actorChar)
		if act == "ArcCut" then
			spawnLayeredSlashWave(startPos + Vector3.new(0, 0.6, 0), dst, 0.48, sc * 1.1, PAL.Thunder, PAL.Violet, 0.26, folder)
			spawnLayeredSlashWave(startPos + Vector3.new(0, 0.6, 0), dst, -0.48, sc * 1.1, PAL.Violet, PAL.Thunder, 0.26, folder)
			Lib.SpawnJaggedLightning(startPos, dst, 7, 1.4 * sc, 0.28 * sc, PAL.HotWhite, PAL.Thunder, 0.30, folder)
			UniversalVFXOverhaul.SpawnStage3Aftermath(dst, prof, 11, sc, isAwakened, isLocal)
		else
			local isUlt = (act == "ThunderJudgement")
			local gPos = Lib.FindGround(dst)
			local bolts = Lib.IsLowFX() and 4 or (isUlt and 10 or 6)
			for i = 1, bolts do
				local ang = (i - 1) * ((math.pi * 2) / bolts)
				local r = (isUlt and 9.5 or 6.0) * sc * ((i % 2 == 0) and 1 or 0.55)
				local strikePos = gPos + Vector3.new(math.cos(ang) * r, 0, math.sin(ang) * r)
				Lib.SpawnJaggedLightning(strikePos + Vector3.new(0, 26 * sc, 0), strikePos, 7, 1.5 * sc, (isUlt and 0.38 or 0.26) * sc, PAL.HotWhite, (i % 2 == 0) and PAL.Thunder or PAL.Violet, 0.38, folder)
			end
			Lib.SpawnJaggedLightning(gPos + Vector3.new(0, 30 * sc, 0), gPos, 8, 1.2 * sc, 0.55 * sc, PAL.HotWhite, PAL.Thunder, 0.44, folder)
			UniversalVFXOverhaul.SpawnStage3Aftermath(gPos, prof, isUlt and 23 or 15, sc, isUlt or isAwakened, isLocal)
		end
		return true
	end

	-- E. ArcaneMage: FrostBolt, ArcaneComet, AstralCataclysm + PortalWarp + SeaBeastBeam
	if act == "FrostBolt" then
		local prof = { Primary = PAL.Ice, Secondary = PAL.HotWhite, Accent = PAL.Cyan, Element = "Ice", Mat = Enum.Material.Glass }
		UniversalVFXOverhaul.ExecuteFruitArchetype("CrystalLanceFan", "GlacierIceCore", "Z", startPos, dst, lookDir, prof, { Count = 5, Range = 28, Radius = 9 }, sc, isAwakened, isLocal, actorChar)
		return true
	elseif act == "ArcaneComet" or act == "AstralCataclysm" then
		local isUlt = (act == "AstralCataclysm")
		local prof = { Primary = PAL.Gravity, Secondary = PAL.Cyan, Accent = PAL.Obsidian, Element = "Gravity", Mat = Enum.Material.ForceField }
		UniversalVFXOverhaul.ExecuteFruitArchetype(isUlt and "DescendingSun" or "MeteorCataclysm", "AstralGravityCore", isUlt and "V" or "C", startPos, dst, lookDir, prof, { Count = isUlt and 1 or 4, Range = 26, Radius = isUlt and 25 or 14 }, sc, isUlt or isAwakened, isLocal, actorChar)
		return true
	elseif k == "PortalWarp" or act:find("Portal") or act:find("Gate") then
		local prof = { Primary = PAL.Cyan, Secondary = PAL.Violet, Accent = PAL.Obsidian, Element = "Portal", Mat = Enum.Material.ForceField }
		UniversalVFXOverhaul.ExecuteFruitArchetype("PortalRingStrike", "DimensionalPortalCore", "X", startPos, dst, lookDir, prof, { Count = 4, Range = 28, Radius = 11 }, sc, isAwakened, isLocal, actorChar)
		return true
	elseif k == "SeaBeastBeam" or act:find("SeaBeast") then
		local prof = { Primary = PAL.Cyan, Secondary = PAL.Emerald, Accent = PAL.Obsidian, Element = "Ice", Mat = Enum.Material.ForceField }
		UniversalVFXOverhaul.ExecuteFruitArchetype("ColossalBeam", "GlacierIceCore", "C", startPos, dst, lookDir, prof, { Count = 6, Range = 40, Radius = 16 }, sc * 1.25, true, isLocal, actorChar)
		return true
	end

	return false
end

-- ============================================================================
-- 7. HIT-IMPACT POLISH, LOGIA REFLEX, HAKI (BUSO / HAOSHOKU) & RACE V4
-- ============================================================================
function UniversalVFXOverhaul.SpawnHitImpact(hitPos, isCrit, breakDmg, knockDir, targetModel)
	local folder = Lib.GetTempFolder("UniversalVFX")
	local isBreak = (breakDmg and breakDmg >= 35)
	local heavy = isBreak or isCrit
	local col = isBreak and PAL.Violet or (isCrit and PAL.Gold or PAL.Cyan)
	local sub = isBreak and PAL.Crimson or (isCrit and PAL.Solar or PAL.HotWhite)

	-- VibeGG 5-Step Melee Hit Juice (White Hit Flash, Random Pitch Impact Sound, Directional Sparks, Knockback, Hit-Stop & Shake)
	Lib.VibeGG_MeleeHit5Steps(hitPos, knockDir, isCrit, heavy, targetModel, true)

	local prefabName = isBreak and "Hit_GuardBreak" or (isCrit and "Hit_Crit" or "Hit_Normal")
	Lib.Emit("Combat", prefabName, CFrame.new(hitPos), heavy and 1.25 or 0.95)

	local randCF = CFrame.new(hitPos) * CFrame.Angles(math.random() * 3.14, math.random() * 3.14, 0)
	Lib.SpawnShockRing(hitPos, randCF, col, 1.2, heavy and 9.4 or 5.8, 0.22, 0.26, Enum.Material.ForceField, folder)
	Lib.SpawnFadeCrescentArc(randCF, 1.4, heavy and 7.4 or 4.6, heavy and 1.4 or 0.9, col, sub, 0.26, folder)
	if heavy then
		Lib.SpawnShockRing(hitPos, randCF * CFrame.Angles(1.1, 0.8, 0), sub, 0.9, 6.8, 0.16, 0.22, Enum.Material.ForceField, folder)
		Lib.SpawnFadeCrescentArc(randCF * CFrame.Angles(1.1, 0.8, 0.5), 1.1, 5.8, 1.1, sub, col, 0.22, folder)
	end

	if not Lib.IsLowFX() then
		-- 3-Axis Anime Star-Cross + Dark Contrast Center
		local darkDot = Lib.MakePart("ImpactDarkCenter", Enum.PartType.Ball, Vector3.new(0.85, 0.85, 0.85), CFrame.new(hitPos), PAL.Obsidian, 0.10, Enum.Material.SmoothPlastic, folder)
		TweenService:Create(darkDot, TweenInfo.new(0.18), { Size = Vector3.new(0.1, 0.1, 0.1), Transparency = 1 }):Play()
		Debris:AddItem(darkDot, 0.20)

		for i = 1, (heavy and 4 or 3) do
			local ang = (i - 1) * (math.pi / (heavy and 4 or 3))
			local sp = Lib.MakePart("AnimeImpactStar_" .. i, Enum.PartType.Block, Vector3.new(0.20, 0.20, heavy and 5.8 or 3.8), CFrame.new(hitPos) * CFrame.Angles(ang, ang * 0.75, 0), (i == 1) and PAL.HotWhite or col, 0.08, Enum.Material.ForceField, folder)
			if i == 1 then Lib.SafeLight(sp, col, 1.22, 11, 0.22) end
			TweenService:Create(sp, TweenInfo.new(0.20, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = Vector3.new(0.04, 0.04, heavy and 9.8 or 6.2),
				Transparency = 1,
			}):Play()
			Debris:AddItem(sp, 0.24)
		end

		-- Guard-Break Shattering Glass Armor Prisms
		if isBreak then
			for s = 1, 6 do
				local a = (s - 1) * (math.pi / 3)
				local dir = Vector3.new(math.cos(a), (s % 2 == 0 and 0.45 or -0.25), math.sin(a)).Unit
				local prism = Lib.MakePart("GuardBreakPrism_" .. s, Enum.PartType.Wedge, Vector3.new(0.55, 0.95, 0.85), CFrame.lookAt(hitPos + dir * 0.7, hitPos + dir * 4), (s % 2 == 0) and PAL.Violet or PAL.Crimson, 0.12, Enum.Material.Glass, folder)
				TweenService:Create(prism, TweenInfo.new(0.34, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					CFrame = CFrame.lookAt(hitPos + dir * 5.2, hitPos + dir * 8) * CFrame.Angles(1.2, 0.9, 0),
					Size = Vector3.new(0.15, 0.25, 0.25),
					Transparency = 1,
				}):Play()
				Debris:AddItem(prism, 0.38)
			end
		end
	end
end

function UniversalVFXOverhaul.SpawnLogiaReflex(pos, prof, targetModel)
	local folder = Lib.GetTempFolder("UniversalVFX")
	Lib.Emit("HakiAndAwakening", "Logia_Reflex", CFrame.new(pos), 1.05, prof.Primary, prof.Secondary)

	if targetModel and targetModel:IsA("Model") then
		for _, partName in ipairs({ "UpperTorso", "LowerTorso", "Torso" }) do
			local bp = targetModel:FindFirstChild(partName)
			if bp and bp:IsA("BasePart") and bp.Transparency < 0.8 then
				local origT = bp.Transparency
				bp.Transparency = 0.74
				task.delay(0.22, function()
					if bp and bp.Parent then
						TweenService:Create(bp, TweenInfo.new(0.16), { Transparency = origT }):Play()
					end
				end)
			end
		end
	end

	local cavity = Lib.MakePart("LogiaPhaseRing", Enum.PartType.Cylinder, Vector3.new(0.28, 2.2, 2.2), CFrame.new(pos) * CFrame.Angles(0, 0, math.pi * 0.5), prof.Primary, 0.16, Enum.Material.ForceField, folder)
	local voidCore = Lib.MakePart("LogiaVoidCenter", Enum.PartType.Ball, Vector3.new(1.5, 1.5, 1.5), CFrame.new(pos), PAL.Obsidian, 0.18, Enum.Material.SmoothPlastic, folder)
	Lib.SafeLight(cavity, prof.Primary, 1.15, 11, 0.32)
	TweenService:Create(cavity, TweenInfo.new(0.36, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = Vector3.new(0.08, 8.2, 8.2), Transparency = 1 }):Play()
	TweenService:Create(voidCore, TweenInfo.new(0.28), { Size = Vector3.new(0.2, 0.2, 0.2), Transparency = 1 }):Play()
	Debris:AddItem(cavity, 0.40)
	Debris:AddItem(voidCore, 0.32)

	-- Swirling Elemental Ribbon Wisp reforming around torso
	if not Lib.IsLowFX() then
		local wisp = Lib.MakePart("LogiaReformRibbon", Enum.PartType.Ball, Vector3.new(0.35, 0.35, 0.35), CFrame.new(pos), prof.Primary, 1, Enum.Material.SmoothPlastic, folder)
		Lib.AttachRibbonTrail(wisp, PAL.HotWhite, prof.Primary, prof.Secondary, 0.95, 0.24)
		animateOver(0.30, function(a)
			if wisp.Parent then
				local ang = a * math.pi * 4
				local r = (1 - a * 0.5) * 2.8
				wisp.CFrame = CFrame.new(pos + Vector3.new(math.cos(ang) * r, (a - 0.5) * 2.6, math.sin(ang) * r))
			end
		end)
		Debris:AddItem(wisp, 0.54)
	end
end

function UniversalVFXOverhaul.SpawnBusoIgnite(ch, auraColor, stage)
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local folder = Lib.GetTempFolder("UniversalVFX")
	local col = auraColor or PAL.Crimson
	local sc = 0.85 + math.clamp(stage or 1, 1, 5) * 0.10
	Lib.Emit("HakiAndAwakening", "Haki_BusoIgnite", root.CFrame, sc, col, PAL.Obsidian)
	local gPos = Lib.FindGround(root.Position, ch)
	Lib.SpawnShockRing(gPos + Vector3.new(0, 0.14, 0), nil, col, 1.5, 7.8 * sc, 0.20, 0.32, Enum.Material.ForceField, folder)
	Lib.SpawnShockRing(root.Position, root.CFrame * CFrame.Angles(0.45, 0, 0), PAL.Obsidian, 1.2, 5.6 * sc, 0.18, 0.28, Enum.Material.SmoothPlastic, folder)
end

function UniversalVFXOverhaul.SpawnRaceV4Awakening(ch, raceName)
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local folder = Lib.GetTempFolder("UniversalVFX")
	local pos = root.Position
	local gPos = Lib.FindGround(pos, ch)
	local col = (raceName == "Draconian" and PAL.Crimson)
		or (raceName == "Cyborg" and PAL.Violet)
		or (raceName == "Mink" and PAL.Thunder)
		or PAL.Gold

	Lib.Emit("HakiAndAwakening", "RaceV4_Awakening", CFrame.new(pos), 1.45, col, PAL.Cyan)
	Lib.SpawnShatterCrater(pos, col, PAL.Cyan, PAL.Obsidian, 9.5, 10, 0.62, folder)

	local pillar = Lib.MakePart("RaceV4AscensionPillar", Enum.PartType.Cylinder, Vector3.new(30, 2.2, 2.2), CFrame.new(gPos + Vector3.new(0, 15, 0)) * CFrame.Angles(0, 0, math.pi * 0.5), col, 0.16, Enum.Material.ForceField, folder)
	local darkCore = Lib.MakePart("RaceV4ObsidianSpine", Enum.PartType.Cylinder, Vector3.new(30, 0.9, 0.9), pillar.CFrame, PAL.Obsidian, 0.14, Enum.Material.SmoothPlastic, folder)
	Lib.SafeLight(pillar, col, 1.42, 16, 0.58)
	TweenService:Create(pillar, TweenInfo.new(0.58, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = Vector3.new(32, 12.5, 12.5), Transparency = 1 }):Play()
	TweenService:Create(darkCore, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = Vector3.new(30, 3.2, 3.2), Transparency = 1 }):Play()
	Debris:AddItem(pillar, 0.62)
	Debris:AddItem(darkCore, 0.50)

	for i = 1, 6 do
		local ang = (i - 1) * (math.pi / 3)
		Lib.SpawnJaggedLightning(gPos + Vector3.new(0, 0.4, 0), gPos + Vector3.new(math.cos(ang) * 11, 5.5, math.sin(ang) * 11), 5, 1.0, 0.24, PAL.HotWhite, col, 0.44, folder)
	end
	if Players.LocalPlayer and ch == Players.LocalPlayer.Character then
		Lib.EmitCameraTrauma(0.54, 4.5)
	end
end

function UniversalVFXOverhaul.SpawnHaoshokuConqueror(centerPos, isLocalCaster)
	local folder = Lib.GetTempFolder("UniversalVFX")
	local crimson = PAL.Crimson
	local obsidian = PAL.Obsidian
	local gPos = Lib.FindGround(centerPos)

	Lib.Emit("HakiAndAwakening", "Haki_ConquerorBurst", CFrame.new(centerPos), 1.45)

	local outerDome = Lib.MakePart("HaoshokuOuterDome", Enum.PartType.Ball, Vector3.new(4, 4, 4), CFrame.new(centerPos), crimson, 0.24, Enum.Material.ForceField, folder)
	local darkDome = Lib.MakePart("HaoshokuObsidianCore", Enum.PartType.Ball, Vector3.new(3, 3, 3), CFrame.new(centerPos), obsidian, 0.16, Enum.Material.SmoothPlastic, folder)
	Lib.SafeLight(outerDome, crimson, 1.42, 16, 0.58)

	TweenService:Create(outerDome, TweenInfo.new(0.64, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = Vector3.new(48, 48, 48), Transparency = 1 }):Play()
	TweenService:Create(darkDome, TweenInfo.new(0.48, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = Vector3.new(28, 28, 28), Transparency = 1 }):Play()
	Debris:AddItem(outerDome, 0.68)
	Debris:AddItem(darkDome, 0.52)

	Lib.SpawnShockRing(gPos + Vector3.new(0, 0.18, 0), nil, crimson, 3.8, 50, 0.36, 0.60, Enum.Material.ForceField, folder)
	Lib.SpawnShockRing(gPos + Vector3.new(0, 0.34, 0), nil, obsidian, 2.6, 36, 0.28, 0.50, Enum.Material.SmoothPlastic, folder)
	Lib.SpawnShatterCrater(centerPos, crimson, PAL.Gold, obsidian, 16, 10, 0.65, folder)

	-- 12 Jagged 3D Red-Black Conqueror Lightning Arcs (Ground + Sky-Arcing!)
	local boltCount = Lib.IsLowFX() and 6 or 12
	for i = 1, boltCount do
		local ang = (i - 1) * ((math.pi * 2) / boltCount)
		local reach = 19 + (i % 3) * 3.5
		local yEnd = (i % 2 == 0) and 0.45 or (5.5 + (i % 3) * 2.2)
		local p1 = gPos + Vector3.new(math.cos(ang) * reach, yEnd, math.sin(ang) * reach)
		Lib.SpawnJaggedLightning(gPos + Vector3.new(0, 0.8, 0), p1, 6, 1.35, 0.32, crimson, obsidian, 0.52, folder)
	end

	if isLocalCaster and not Lib.IsLowFX() then
		Lib.EmitCameraTrauma(0.64, 5.2)
		local pulse = Lighting:FindFirstChild("SkybreakHaoPulse") or Instance.new("ColorCorrectionEffect")
		pulse.Name = "SkybreakHaoPulse"
		pulse.Contrast = 0.24
		pulse.Saturation = -0.18
		pulse.TintColor = Color3.fromRGB(255, 224, 228)
		pulse.Enabled = true
		pulse.Parent = Lighting
		TweenService:Create(pulse, TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Contrast = 0,
			Saturation = 0,
			TintColor = Color3.fromRGB(255, 255, 255),
		}):Play()
		task.delay(0.21, function()
			if pulse and pulse.Parent then pulse.Enabled = false end
		end)
	end
end

-- ============================================================================
-- 8. TRAVERSAL VFX: ANTI-GLARE GEPPO AIR-STEPS & MULTI-LIMB DASH AFTERIMAGES
-- ============================================================================
function UniversalVFXOverhaul.SpawnGeppoStep(footPos, isSkyborn, jumpIdx, rootCF)
	local folder = Lib.GetTempFolder("UniversalVFX")
	local isFlipStep = (jumpIdx and (jumpIdx % 3 == 0)) or false
	local primary = isSkyborn and PAL.Gold or (isFlipStep and PAL.Cyan or PAL.Ice)
	local secondary = isSkyborn and PAL.Cyan or PAL.HotWhite

	local stepOffset = Vector3.zero
	if rootCF and jumpIdx then
		local m = jumpIdx % 3
		if m == 1 then
			stepOffset = -rootCF.RightVector * 0.95 + rootCF.LookVector * 0.25
		elseif m == 2 then
			stepOffset = rootCF.RightVector * 0.95 + rootCF.LookVector * 0.25
		end
	end
	local stepOrigin = footPos + stepOffset

	Lib.Emit("TraversalAndWorld", "Traversal_Geppo", CFrame.new(stepOrigin), isFlipStep and 1.25 or 0.95, primary, secondary)

	-- Anti-Glare ForceField Compressed Air Pad + Dual Expanding Vortex Rings + Obsidian Pressure Core
	local corePad = Lib.MakePart("GeppoDarkCore", Enum.PartType.Cylinder, Vector3.new(0.14, 1.8, 1.8), CFrame.new(stepOrigin) * CFrame.Angles(0, 0, math.pi * 0.5), PAL.Obsidian, 0.28, Enum.Material.SmoothPlastic, folder)
	TweenService:Create(corePad, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.04, isFlipStep and 6.4 or 4.6, isFlipStep and 6.4 or 4.6),
		Transparency = 1,
	}):Play()
	Debris:AddItem(corePad, 0.28)

	Lib.SpawnShockRing(stepOrigin, nil, primary, 2.4, isFlipStep and 16.0 or 12.2, 0.22, 0.34, Enum.Material.ForceField, folder)
	Lib.SpawnShockRing(stepOrigin - Vector3.new(0, 0.85, 0), nil, secondary, 1.6, isFlipStep and 10.5 or 8.2, 0.16, 0.30, Enum.Material.ForceField, folder)

	if not Lib.IsLowFX() then
		local swirl = Lib.MakePart("GeppoWindSpiral", Enum.PartType.Ball, Vector3.new(0.3, 0.3, 0.3), CFrame.new(stepOrigin), primary, 1, Enum.Material.SmoothPlastic, folder)
		Lib.AttachRibbonTrail(swirl, PAL.HotWhite, primary, PAL.Obsidian, 0.85, 0.20)
		animateOver(0.22, function(a)
			if swirl.Parent then
				local ang = a * math.pi * 3.5
				local r = (1.2 + a * 4.2)
				swirl.CFrame = CFrame.new(stepOrigin + Vector3.new(math.cos(ang) * r, -a * 2.4, math.sin(ang) * r))
			end
		end)
		Debris:AddItem(swirl, 0.42)
	end
end

local AFTERIMAGE_LIMBS = {
	"Head", "UpperTorso", "LowerTorso", "Torso",
	"RightUpperArm", "RightLowerArm", "LeftUpperArm", "LeftLowerArm", "Right Arm", "Left Arm",
	"RightUpperLeg", "RightLowerLeg", "LeftUpperLeg", "LeftLowerLeg", "Right Leg", "Left Leg",
}

function UniversalVFXOverhaul.SpawnDashSlipstream(ch, originCF, accentColor, afterimageOnly)
	local folder = Lib.GetTempFolder("UniversalVFX")
	local col = accentColor or PAL.Cyan

	if not afterimageOnly and originCF then
		Lib.Emit("TraversalAndWorld", "Traversal_DashSoru", originCF, 1.05, col, PAL.Obsidian)
		-- Dual Mach Slipstream Rings oriented along dash travel axis
		local ringCF = originCF * CFrame.Angles(math.pi * 0.5, 0, 0)
		Lib.SpawnShockRing(originCF.Position, ringCF, col, 2.4, 11.8, 0.22, 0.30, Enum.Material.ForceField, folder)
		Lib.SpawnShockRing(originCF.Position - originCF.LookVector * 1.4, ringCF, PAL.HotWhite, 1.6, 8.2, 0.14, 0.24, Enum.Material.ForceField, folder)
	end

	if not ch then return end
	local low = Lib.IsLowFX()
	local spawnedAny = false

	if not low then
		local ghostModel = Instance.new("Model")
		ghostModel.Name = "SkybreakSoruSilhouette"
		ghostModel.Parent = folder
		for _, limbName in ipairs(AFTERIMAGE_LIMBS) do
			local limb = ch:FindFirstChild(limbName)
			if limb and limb:IsA("BasePart") and limb.Transparency < 0.9 then
				spawnedAny = true
				local clone = Lib.MakePart(
					"Ghost_" .. limbName,
					(limbName == "Head") and Enum.PartType.Ball or Enum.PartType.Block,
					limb.Size * 0.96,
					limb.CFrame,
					col,
					0.46,
					Enum.Material.ForceField,
					ghostModel
				)
				TweenService:Create(clone, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Transparency = 1,
					Size = limb.Size * 0.78,
				}):Play()
			end
		end
		Debris:AddItem(ghostModel, 0.28)
	end

	-- Fallback silhouette capsule for custom Blender/Dragon rigs or LowFX mode
	if not spawnedAny then
		local root = ch:FindFirstChild("HumanoidRootPart")
		if root then
			local ghost = Lib.MakePart("SoruCoreGhost", Enum.PartType.Block, Vector3.new(2.1, 4.5, 1.3), root.CFrame, col, 0.48, Enum.Material.ForceField, folder)
			TweenService:Create(ghost, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = Vector3.new(1.1, 4.8, 2.6),
				Transparency = 1,
			}):Play()
			Debris:AddItem(ghost, 0.28)
		end
	end
end

-- ============================================================================
-- 9. PROGRESSION (LEVEL-UP / HEAL / SHRINE), BOSS TELEGRAPHS & ENEMY DEATH VFX
-- ============================================================================
function UniversalVFXOverhaul.SpawnProgressionVFX(kind, ch)
	local targetChar = ch or (Players.LocalPlayer and Players.LocalPlayer.Character)
	local root = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local folder = Lib.GetTempFolder("UniversalVFX")
	local pos = root.Position
	local gPos = Lib.FindGround(pos, targetChar)
	local k = tostring(kind or "LevelUp")

	if k == "Heal" then
		Lib.Emit("TraversalAndWorld", "Progression_Heal", CFrame.new(pos), 1.1)
		Lib.SpawnShockRing(gPos + Vector3.new(0, 0.16, 0), nil, PAL.Emerald, 1.6, 8.2, 0.18, 0.42, Enum.Material.ForceField, folder)
		if not Lib.IsLowFX() then
			local wisp = Lib.MakePart("HealVitalityRibbon", Enum.PartType.Ball, Vector3.new(0.35, 0.35, 0.35), CFrame.new(gPos), PAL.Emerald, 1, Enum.Material.SmoothPlastic, folder)
			Lib.AttachRibbonTrail(wisp, PAL.HotWhite, PAL.Emerald, PAL.Wind, 0.95, 0.28)
			animateOver(0.48, function(a)
				if wisp.Parent and root.Parent then
					local ang = a * math.pi * 4
					wisp.CFrame = CFrame.new(root.Position + Vector3.new(math.cos(ang) * 2.4, -2.5 + a * 5.6, math.sin(ang) * 2.4))
				end
			end)
			Debris:AddItem(wisp, 0.78)
		end
	else
		-- LevelUp / Quest / Shrine Golden-Cyan Helical Ascension Pillar!
		local col = (k == "Shrine") and PAL.Cyan or PAL.Gold
		local sub = (k == "Shrine") and PAL.Gold or PAL.Cyan
		Lib.Emit("TraversalAndWorld", "Progression_LevelUp", CFrame.new(pos), 1.25, col, sub)

		local pillar = Lib.MakePart("AscensionPillar", Enum.PartType.Cylinder, Vector3.new(22, 1.8, 1.8), CFrame.new(gPos + Vector3.new(0, 11, 0)) * CFrame.Angles(0, 0, math.pi * 0.5), col, 0.20, Enum.Material.ForceField, folder)
		Lib.SafeLight(pillar, col, 1.32, 15, 0.55)
		TweenService:Create(pillar, TweenInfo.new(0.60, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = Vector3.new(24, 9.6, 9.6),
			Transparency = 1,
		}):Play()
		Debris:AddItem(pillar, 0.64)

		for h = 1, 3 do
			local halo = Lib.MakePart("AscensionCrown_" .. h, Enum.PartType.Cylinder, Vector3.new(0.18, 3.2, 3.2), CFrame.new(gPos + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.pi * 0.5), (h % 2 == 0) and sub or col, 0.16, Enum.Material.ForceField, folder)
			TweenService:Create(halo, TweenInfo.new(0.45 + h * 0.08, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				CFrame = CFrame.new(gPos + Vector3.new(0, h * 3.4, 0)) * CFrame.Angles(0, 0, math.pi * 0.5),
				Size = Vector3.new(0.06, 9.2 + h * 1.4, 9.2 + h * 1.4),
				Transparency = 1,
			}):Play()
			Debris:AddItem(halo, 0.75)
		end

		if not Lib.IsLowFX() then
			local helixA = Lib.MakePart("LevelHelixA", Enum.PartType.Ball, Vector3.new(0.35, 0.35, 0.35), CFrame.new(gPos), col, 1, Enum.Material.SmoothPlastic, folder)
			local helixB = Lib.MakePart("LevelHelixB", Enum.PartType.Ball, Vector3.new(0.35, 0.35, 0.35), CFrame.new(gPos), sub, 1, Enum.Material.SmoothPlastic, folder)
			Lib.AttachRibbonTrail(helixA, PAL.HotWhite, col, PAL.Obsidian, 1.05, 0.32)
			Lib.AttachRibbonTrail(helixB, PAL.HotWhite, sub, PAL.Obsidian, 1.05, 0.32)
			animateOver(0.56, function(a)
				local ang = a * math.pi * 4.5
				local r = (2.8 - a * 1.2)
				local baseP = root.Parent and (root.Position - Vector3.new(0, 2.5, 0)) or gPos
				if helixA.Parent then helixA.CFrame = CFrame.new(baseP + Vector3.new(math.cos(ang) * r, a * 11.5, math.sin(ang) * r)) end
				if helixB.Parent then helixB.CFrame = CFrame.new(baseP + Vector3.new(math.cos(ang + math.pi) * r, a * 11.5, math.sin(ang + math.pi) * r)) end
			end)
			Debris:AddItem(helixA, 0.90)
			Debris:AddItem(helixB, 0.90)
		end
	end
end

function UniversalVFXOverhaul.SpawnEnemyDeathDissolve(enemyModel, isBoss)
	if not enemyModel or not enemyModel.Parent then return end
	local folder = Lib.GetTempFolder("UniversalVFX")
	local root = enemyModel:FindFirstChild("Body") or enemyModel.PrimaryPart or enemyModel:FindFirstChildWhichIsA("BasePart")
	local centerPos = root and root.Position or enemyModel:GetPivot().Position
	local bossFlag = isBoss or (enemyModel.Parent and enemyModel.Parent.Name == "ActiveBosses") or (enemyModel:GetAttribute("IsBoss") == true)

	-- VibeGG Finisher: Death Pop (Phình nhẹ rồi nổ tung thành mảnh sáng văng ra)
	Lib.VibeGG_MeleeDeathPopFinisher(enemyModel, centerPos, bossFlag)

	if bossFlag then
		-- Grand Boss Cataclysmic Implosion -> Supernova Shockwave + Soul Pillar!
		Lib.Emit("TraversalAndWorld", "Boss_CataclysmDeath", CFrame.new(centerPos), 1.6)
		local implosion = Lib.MakePart("BossImplodeSphere", Enum.PartType.Ball, Vector3.new(18, 18, 18), CFrame.new(centerPos), PAL.Obsidian, 0.25, Enum.Material.SmoothPlastic, folder)
		local rim = Lib.MakePart("BossSupernovaShell", Enum.PartType.Ball, Vector3.new(3, 3, 3), CFrame.new(centerPos), PAL.Crimson, 0.18, Enum.Material.ForceField, folder)
		Lib.SafeLight(rim, PAL.Crimson, 1.45, 16, 0.72)

		TweenService:Create(implosion, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = Vector3.new(1.5, 1.5, 1.5), Transparency = 0.05 }):Play()
		task.delay(0.20, function()
			if implosion.Parent then implosion:Destroy() end
			if rim.Parent then
				TweenService:Create(rim, TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = Vector3.new(38, 38, 38), Transparency = 1 }):Play()
			end
			Lib.SpawnShatterCrater(centerPos, PAL.Crimson, PAL.Gold, PAL.Obsidian, 15, 12, 0.68, folder)
			for b = 1, (Lib.IsLowFX() and 4 or 8) do
				local ang = (b - 1) * (math.pi / 4)
				Lib.SpawnJaggedLightning(centerPos, centerPos + Vector3.new(math.cos(ang) * 16, 4 + (b % 3) * 2, math.sin(ang) * 16), 5, 1.2, 0.30, PAL.Gold, PAL.Crimson, 0.48, folder)
			end
			Lib.EmitCameraTrauma(0.58, 4.5)
		end)
		Debris:AddItem(implosion, 0.30)
		Debris:AddItem(rim, 0.80)
	else
		-- Standard Enemy Ascending Soul-Ribbon Aether Dissolve
		Lib.Emit("TraversalAndWorld", "Enemy_AetherDissolve", CFrame.new(centerPos), 1.05)
		local soulCore = Lib.MakePart("EnemySoulSpire", Enum.PartType.Ball, Vector3.new(1.4, 1.4, 1.4), CFrame.new(centerPos), PAL.Cyan, 0.24, Enum.Material.ForceField, folder)
		Lib.SafeLight(soulCore, PAL.Cyan, 1.18, 12, 0.50)
		TweenService:Create(soulCore, TweenInfo.new(0.54, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Position = centerPos + Vector3.new(0, 5.8, 0),
			Size = Vector3.new(0.22, 6.8, 0.22),
			Transparency = 1,
		}):Play()
		Debris:AddItem(soulCore, 0.58)
		Lib.SpawnShockRing(Lib.FindGround(centerPos, enemyModel) + Vector3.new(0, 0.14, 0), nil, PAL.Cyan, 1.6, 8.8, 0.20, 0.45, Enum.Material.ForceField, folder)

		if not Lib.IsLowFX() then
			local soulRibbon = Lib.MakePart("SoulAscendRibbon", Enum.PartType.Ball, Vector3.new(0.3, 0.3, 0.3), CFrame.new(centerPos), PAL.Gold, 1, Enum.Material.SmoothPlastic, folder)
			Lib.AttachRibbonTrail(soulRibbon, PAL.HotWhite, PAL.Cyan, PAL.Gold, 0.85, 0.26)
			animateOver(0.46, function(a)
				if soulRibbon.Parent then
					local ang = a * math.pi * 3.5
					local r = (1 - a * 0.6) * 2.2
					soulRibbon.CFrame = CFrame.new(centerPos + Vector3.new(math.cos(ang) * r, -1.0 + a * 7.2, math.sin(ang) * r))
				end
			end)
			Debris:AddItem(soulRibbon, 0.74)
		end
	end

	-- Dissolve enemy BaseParts cleanly
	for _, desc in ipairs(enemyModel:GetDescendants()) do
		if desc:IsA("BasePart") and desc.Transparency < 0.98 then
			TweenService:Create(desc, TweenInfo.new(0.52, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Transparency = 1,
				Size = desc.Size * 0.72,
			}):Play()
		elseif desc:IsA("Decal") or desc:IsA("Texture") then
			TweenService:Create(desc, TweenInfo.new(0.45), { Transparency = 1 }):Play()
		end
	end
end

function UniversalVFXOverhaul.EnhanceBossTelegraph(inst)
	if not inst or not inst:IsA("BasePart") or inst:GetAttribute("_EnhancedTelegraph") then return end
	inst:SetAttribute("_EnhancedTelegraph", true)
	-- Anti-glare material swap if server spawned raw Neon telegraph disc
	if inst.Material == Enum.Material.Neon then
		inst.Material = Enum.Material.ForceField
		inst.Transparency = math.max(0.32, inst.Transparency)
	end
	local diam = math.max(inst.Size.Y, inst.Size.Z, inst.Size.X)
	if diam < 3 then return end
	local folder = Lib.GetTempFolder("UniversalVFX")
	local ring = Lib.MakePart(
		"TelegraphTimingRing",
		Enum.PartType.Cylinder,
		Vector3.new(0.20, diam * 1.02, diam * 1.02),
		CFrame.new(inst.Position + Vector3.new(0, 0.16, 0)) * CFrame.Angles(0, 0, math.pi * 0.5),
		PAL.Crimson,
		0.16,
		Enum.Material.ForceField,
		folder
	)
	TweenService:Create(ring, TweenInfo.new(0.85, Enum.EasingStyle.Linear, Enum.EasingDirection.In), {
		Size = Vector3.new(0.24, 1.2, 1.2),
		Color = PAL.Gold,
	}):Play()
	Debris:AddItem(ring, 0.92)
end

return UniversalVFXOverhaul
