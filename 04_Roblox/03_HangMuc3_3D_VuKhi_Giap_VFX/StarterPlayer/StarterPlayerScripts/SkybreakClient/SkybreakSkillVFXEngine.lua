--!nonstrict
-- ============================================================================
-- SkybreakSkillVFXEngine.lua
-- Stage 2 Bespoke Skill-Matched 5-Layer Combat VFX Engine
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/SkybreakSkillVFXEngine.lua
-- Layers:
--   Layer 1: 3-Tone Core -> Mid -> Rim ColorSequence Palettes (12 Cores + 8 Styles + 10 Weapons/Guns)
--   Layer 2: 1:1 Logical Archetype Geometry, Beams, Delayed Cuts & 5 Persistent Hazards
--   Layer 3: Raycast-Verified 3D Ground Destruction (ImpactGround==true <=10st) vs Aerial Sonic Rings
--   Layer 4: Future Dynamic PointLight + Token-Guarded 35ms Ultimate Impact Frame & Sky-Tint
--   Layer 5: Synchronized Cast + ImpactDelaySec Camera Choreography
-- ============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local Engine = {}

local LocalPlayer = Players.LocalPlayer
local SharedBlueprints = nil
local LastBlueprintTryAt = -10
local Initialized = false
local LifecycleConns = {}
local RecentCastDedup = {}
local UltimateVFXToken = 0

local TEX_PLASMA = "rbxasset://textures/particles/fire_main.dds"
local TEX_SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local TEX_RING = "rbxasset://textures/particles/forcefield_glow_main.dds"
local TEX_SPARK = "rbxasset://textures/particles/sparkles_main.dds"

local function getBlueprints()
	if SharedBlueprints then
		return SharedBlueprints
	end
	local now = os.clock()
	if (now - LastBlueprintTryAt) < 1.0 then
		return nil
	end
	LastBlueprintTryAt = now
	local sh = ReplicatedStorage:FindFirstChild("Shared")
	if sh then
		local mod = sh:FindFirstChild("SkybreakSkillBlueprints")
		if mod and mod:IsA("ModuleScript") then
			local ok, res = pcall(require, mod)
			if ok and type(res) == "table" then
				SharedBlueprints = res
				return SharedBlueprints
			end
		end
	end
	return nil
end

-- ============================================================================
-- GRAPHICS TIER SCALING ("Ultra" | "Balanced" | "Smooth")
-- ============================================================================
local function normalizeTierName(raw)
	local s = tostring(raw or "")
	if s == "Ultra" or s == "Balanced" or s == "Smooth" then
		return s
	end
	local low = string.lower(s)
	if low == "high" or low == "ultra" then
		return "Ultra"
	elseif low == "medium" or low == "balanced" then
		return "Balanced"
	elseif low == "low" or low == "smooth" then
		return "Smooth"
	end
	return nil
end

function Engine.GetGraphicsTier()
	local lp = LocalPlayer or Players.LocalPlayer
	local fromPlayer = lp and normalizeTierName(lp:GetAttribute("GraphicsTier")) or nil
	if fromPlayer then
		return fromPlayer
	end
	local fromWs = normalizeTierName(Workspace:GetAttribute("GraphicsTier"))
	if fromWs then
		return fromWs
	end
	if (lp and lp:GetAttribute("LowFXMode") == true) or (Workspace:GetAttribute("LowFXMode") == true) then
		return "Smooth"
	end
	if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
		return "Balanced"
	end
	return "Ultra"
end

local function getTierBudget()
	local tier = Engine.GetGraphicsTier()
	if tier == "Smooth" then
		return tier, 0.28, 0.0, false, false
	elseif tier == "Balanced" then
		return tier, 0.60, 0.60, false, true
	end
	return "Ultra", 1.0, 1.0, true, true
end

-- ============================================================================
-- RULE 2 & RULE 3 CANONICAL + LEGACY ALIAS RESOLVERS
-- ============================================================================
local CORE_ALIASES = {
	galecore = "GaleCore", gale = "GaleCore", gale_core = "GaleCore", wind = "GaleCore", aetherwindcore = "GaleCore",
	sandstonecore = "SandstoneCore", sandstone = "SandstoneCore", sandstone_core = "SandstoneCore", sand = "SandstoneCore", smoke = "SandstoneCore", smokecore = "SandstoneCore",
	solarflamecore = "SolarFlameCore", solar_flame = "SolarFlameCore", flame = "SolarFlameCore", flamecore = "SolarFlameCore", fire = "SolarFlameCore",
	glaciericecore = "GlacierIceCore", glacier_ice = "GlacierIceCore", ice = "GlacierIceCore", icecore = "GlacierIceCore", frost = "GlacierIceCore", frostbite = "GlacierIceCore",
	thunderrumblecore = "ThunderRumbleCore", thunder_rumble = "ThunderRumbleCore", rumble = "ThunderRumbleCore", rumblecore = "ThunderRumbleCore", thunder = "ThunderRumbleCore",
	celestiallightcore = "CelestialLightCore", celestial_light = "CelestialLightCore", light = "CelestialLightCore", lightcore = "CelestialLightCore",
	starforgedmagmacore = "StarforgedMagmaCore", starforged_magma = "StarforgedMagmaCore", magma = "StarforgedMagmaCore", magmacore = "StarforgedMagmaCore",
	astralgravitycore = "AstralGravityCore", astral_gravity = "AstralGravityCore", gravity = "AstralGravityCore", gravitycore = "AstralGravityCore",
	dimensionalportalcore = "DimensionalPortalCore", dimensional_portal = "DimensionalPortalCore", portal = "DimensionalPortalCore", portalcore = "DimensionalPortalCore",
	solartitancore = "SolarTitanCore", solar_titan = "SolarTitanCore", buddha = "SolarTitanCore", quake = "SolarTitanCore", starlight_quake = "SolarTitanCore", starlightquakecore = "SolarTitanCore",
	aetherflowcore = "AetherflowCore", aetherflow = "AetherflowCore", sweetdoughcore = "AetherflowCore", sweet_dough = "AetherflowCore", dough = "AetherflowCore", mochi = "AetherflowCore",
	abyssalsovereigncore = "AbyssalSovereignCore", abyssal_sovereign = "AbyssalSovereignCore", dragon = "AbyssalSovereignCore", dragoncore = "AbyssalSovereignCore", abyssal_dragon = "AbyssalSovereignCore", void_dragon = "AbyssalSovereignCore",
}

local TRUE_FLIGHT_CORES = {
	GaleCore = true,
	SandstoneCore = true,
	SolarFlameCore = true,
	CelestialLightCore = true,
	StarforgedMagmaCore = true,
	AstralGravityCore = true,
}

function Engine.ResolveCoreId(rawId)
	local s = tostring(rawId or ""):match("^([^|]+)") or ""
	if s == "" or s == "None" then
		return ""
	end
	local bp = getBlueprints()
	if bp and type(bp.ResolveCoreId) == "function" then
		local ok, res = pcall(bp.ResolveCoreId, s)
		if ok and type(res) == "string" and res ~= "" then
			return res
		end
	end
	return CORE_ALIASES[string.lower(s)] or ""
end

function Engine.IsTrueFlightCore(coreId, dragonTier, fruitTransform)
	local cid = Engine.ResolveCoreId(coreId)
	if cid == "" then
		return false
	end
	if cid == "AbyssalSovereignCore" then
		local t = tonumber(dragonTier) or 0
		local tf = tostring(fruitTransform or "")
		return (t >= 2) or (tf == "AbyssalSovereign") or (tf == "DragonFull") or (tf == "AbyssalDragonFull")
	end
	return TRUE_FLIGHT_CORES[cid] == true
end

-- ============================================================================
-- LAYER 1: 3-TONE CORE (0.0) -> MID (0.38) -> RIM (1.0) COLOR PALETTES
-- ============================================================================
local function makePalette(cR, cG, cB, mR, mG, mB, rR, rG, rB)
	local core = Color3.fromRGB(cR, cG, cB)
	local mid = Color3.fromRGB(mR, mG, mB)
	local rim = Color3.fromRGB(rR, rG, rB)
	local seq = ColorSequence.new({
		ColorSequenceKeypoint.new(0.0, core),
		ColorSequenceKeypoint.new(0.38, mid),
		ColorSequenceKeypoint.new(1.0, rim),
	})
	return { Core = core, Mid = mid, Rim = rim, Seq = seq }
end

local PALETTES = {
	-- 12 Canonical Aether Cores
	ThunderRumbleCore     = makePalette(246, 254, 255,  64, 218, 255,  88,  26, 168), -- Hot-White -> Cyan -> Violet-Obsidian
	SolarFlameCore        = makePalette(255, 252, 232, 255, 166,  38, 134,  18,  24), -- White -> Solar Gold -> Crimson-Charcoal
	StarforgedMagmaCore   = makePalette(255, 248, 182, 248,  84,  24,  28,  14,  18), -- White-Yellow -> Molten Orange -> Basalt-Black
	GlacierIceCore        = makePalette(248, 254, 255, 114, 234, 255,  14,  34,  84), -- White -> Arctic Cyan -> Abyssal Navy
	DimensionalPortalCore = makePalette(245, 252, 255,  64, 224, 255,  32,  18,  98), -- White -> Quantum Cyan -> Deep Indigo
	AstralGravityCore     = makePalette(252, 242, 255, 194,  68, 255,  18,   8,  34), -- White -> Magenta-Violet -> Void-Black
	AetherflowCore        = makePalette(255, 246, 212, 236,  46,  96,  22,  12,  28), -- Cream-Gold -> Crimson-Haki -> Obsidian
	AbyssalSovereignCore  = makePalette(248, 252, 255,  58, 188, 255,  42,  22,  98), -- White -> Azure-Gold -> Abyssal-Indigo
	GaleCore              = makePalette(246, 255, 250,  96, 246, 198,  16,  62,  78), -- White -> Tempest Emerald-Cyan -> Deep Teal
	SandstoneCore         = makePalette(255, 248, 220, 238, 192,  98,  76,  48,  22), -- Cream -> Desert Gold -> Umber
	CelestialLightCore    = makePalette(255, 255, 244, 255, 224,  92, 148,  88,  18), -- White -> Celestial Gold -> Warm Bronze
	SolarTitanCore        = makePalette(255, 254, 236, 255, 204,  64, 124,  62,  14), -- Divine White -> Sovereign Gold -> Amber-Obsidian

	-- 8 Martial Arts Styles
	skyborn_combat        = makePalette(248, 253, 255, 118, 228, 255,  26,  64, 108),
	SkyStep               = makePalette(255, 250, 226, 255, 116,  34, 118,  16,  24),
	jade_dragon           = makePalette(244, 255, 248,  62, 238, 164,  14,  58,  52),
	thunder_talon         = makePalette(246, 254, 255,  72, 214, 255,  86,  28, 164),
	solar_ashura          = makePalette(255, 248, 216, 252,  96,  32,  92,  16,  22),
	celestial_godhuman    = makePalette(255, 254, 240, 255, 216,  92,  68,  38, 128),
	SanguineVoidArt       = makePalette(255, 236, 242, 236,  34,  78,  20,   8,  26),
	ChronoVoidPalm        = makePalette(248, 244, 255, 168,  88, 255,  22,  12,  58),

	-- Element & Weapon Fallbacks
	Lightning             = makePalette(246, 254, 255,  64, 218, 255,  88,  26, 168),
	Flame                 = makePalette(255, 252, 232, 255, 166,  38, 134,  18,  24),
	Solar                 = makePalette(255, 252, 232, 255, 186,  52, 134,  24,  24),
	Magma                 = makePalette(255, 248, 182, 248,  84,  24,  28,  14,  18),
	VoidMagma             = makePalette(255, 242, 198, 244,  64,  88,  24,  10,  36),
	Frost                 = makePalette(248, 254, 255, 114, 234, 255,  14,  34,  84),
	Ice                   = makePalette(248, 254, 255, 114, 234, 255,  14,  34,  84),
	Portal                = makePalette(245, 252, 255,  64, 224, 255,  32,  18,  98),
	Gravity               = makePalette(252, 242, 255, 194,  68, 255,  18,   8,  34),
	Void                  = makePalette(248, 240, 255, 162,  64, 255,  18,   8,  36),
	Aether                = makePalette(255, 246, 212, 236,  46,  96,  22,  12,  28),
	Sky                   = makePalette(248, 254, 255, 106, 232, 255,  24,  58,  98),
	Jade                  = makePalette(244, 255, 248,  62, 238, 164,  14,  58,  52),
	Sand                  = makePalette(255, 248, 220, 238, 192,  98,  76,  48,  22),
	Light                 = makePalette(255, 255, 244, 255, 224,  92, 148,  88,  18),
	Celestial             = makePalette(255, 254, 240, 255, 216,  92,  68,  38, 128),
	Spear                 = makePalette(248, 254, 255, 108, 232, 255,  24,  58, 104),
	Katana                = makePalette(250, 254, 255, 136, 224, 255,  28,  42,  88),
	Greatsword            = makePalette(255, 246, 214, 246,  96,  48,  32,  14,  28),
	DualBlades            = makePalette(246, 254, 255,  88, 214, 255,  78,  24, 148),
	Scythe                = makePalette(250, 240, 255, 178,  58, 255,  18,   8,  34),
	Railgun               = makePalette(248, 254, 255,  96, 232, 255,  16,  38,  92),
	VoidLyre              = makePalette(250, 240, 255, 184,  68, 255,  22,  10,  44),
	Bow                   = makePalette(246, 255, 248,  98, 244, 188,  18,  62,  68),
	Cannon                = makePalette(255, 248, 186, 252,  94,  28,  32,  16,  18),
	PistolRifle           = makePalette(255, 252, 236, 255, 208,  84,  48,  64, 108),
}

function Engine.ResolvePalette(data)
	if type(data) ~= "table" then
		return PALETTES.Sky
	end
	local cid = Engine.ResolveCoreId(data.FruitId or data.CoreId or (tonumber(data.Slot) == 2 and data.ItemId) or "")
	if cid ~= "" and PALETTES[cid] then
		return PALETTES[cid]
	end
	local sid = tostring(data.StyleId or (tonumber(data.Slot) == 1 and data.ItemId) or "")
	if sid ~= "" then
		local bp = getBlueprints()
		if bp and type(bp.ResolveStyleId) == "function" then
			local ok, r = pcall(bp.ResolveStyleId, sid)
			if ok and type(r) == "string" and PALETTES[r] then
				return PALETTES[r]
			end
		end
		if PALETTES[sid] then
			return PALETTES[sid]
		end
	end
	local el = tostring(data.Element or data.element or "")
	if el ~= "" and PALETTES[el] then
		return PALETTES[el]
	end
	local wArch = tostring(data.WeaponArchetype or "")
	if wArch ~= "" and PALETTES[wArch] then
		return PALETTES[wArch]
	end
	return PALETTES.Sky
end

-- ============================================================================
-- PRESERVE-GEOMETRY CONTAINER, PARTS, BEAMS & 3-TONE EMITTERS
-- ============================================================================
local function getVFXRoot()
	local tf = Workspace:FindFirstChild("TempFX")
	if not tf then
		tf = Instance.new("Folder")
		tf.Name = "TempFX"
		tf.Parent = Workspace
	end
	local sub = tf:FindFirstChild("SkybreakSkillVFX5L")
	if not sub then
		sub = Instance.new("Folder")
		sub.Name = "SkybreakSkillVFX5L"
		sub:SetAttribute("PreserveGeometry", true)
		sub.Parent = tf
	end
	return sub, tf
end

local function safeLook(fromPos, toPos, upVec)
	local d = toPos - fromPos
	if d.Magnitude < 0.005 then
		return CFrame.new(fromPos)
	end
	local u = d.Unit
	if math.abs(u.Y) > 0.995 then
		return CFrame.lookAt(fromPos, toPos, Vector3.new(1, 0, 0))
	end
	return CFrame.lookAt(fromPos, toPos, upVec or Vector3.yAxis)
end

local function makeGeoPart(name, shape, size, cf, color, transparency, material, parent, useSphereMesh)
	local p = Instance.new("Part")
	p.Name = name or "SkillGeo"
	p:SetAttribute("PreserveGeometry", true)
	p.Shape = shape or Enum.PartType.Block
	p.Size = size or Vector3.new(1, 1, 1)
	p.CFrame = cf or CFrame.identity
	p.Color = color or Color3.fromRGB(110, 230, 255)
	p.Material = material or Enum.Material.Neon
	p.Transparency = math.clamp(transparency or 0.08, 0, 1)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Massless = true
	if useSphereMesh == true then
		local sm = Instance.new("SpecialMesh")
		sm.MeshType = Enum.MeshType.Sphere
		sm.Parent = p
	end
	p.Parent = parent or getVFXRoot()
	return p
end

local function makeAnchorNode(pos, life, parent)
	local node = makeGeoPart("VFXNode", Enum.PartType.Block, Vector3.new(0.2, 0.2, 0.2), CFrame.new(pos), Color3.new(1, 1, 1), 1, Enum.Material.SmoothPlastic, parent, false)
	if life and life > 0 then
		Debris:AddItem(node, life)
	end
	return node
end

local function tweenOutAndDebris(inst, dur, props, style)
	local d = math.max(0.05, tonumber(dur) or 0.35)
	TweenService:Create(inst, TweenInfo.new(d, style or Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
	Debris:AddItem(inst, d + 0.06)
end

local function makeRibbonBeam(posA, posB, pal, w0, w1, curve0, curve1, dur, parent, segments)
	local life = math.max(0.08, tonumber(dur) or 0.30)
	local holder = makeAnchorNode((posA + posB) * 0.5, life + 0.08, parent)
	local a0 = Instance.new("Attachment")
	a0.WorldPosition = posA
	a0.Parent = holder
	local a1 = Instance.new("Attachment")
	a1.WorldPosition = posB
	a1.Parent = holder

	local bm = Instance.new("Beam")
	bm.Attachment0 = a0
	bm.Attachment1 = a1
	bm.Color = pal.Seq
	bm.Width0 = w0 or 1.4
	bm.Width1 = w1 or 0.4
	bm.CurveSize0 = curve0 or 0
	bm.CurveSize1 = curve1 or 0
	bm.FaceCamera = true
	bm.LightEmission = 0.92
	bm.LightInfluence = 0
	bm.Segments = segments or 16
	bm.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.06),
		NumberSequenceKeypoint.new(0.75, 0.22),
		NumberSequenceKeypoint.new(1, 0.85),
	})
	bm.Parent = holder

	TweenService:Create(bm, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Width0 = 0,
		Width1 = 0,
	}):Play()
	return bm, a0, a1, holder
end

local function emit3ToneBurst(posOrPart, pal, baseCount, sz0, sz1, spdMin, spdMax, life, tex, spreadDeg)
	local _, pMult = getTierBudget()
	local count = math.max(1, math.floor((baseCount or 12) * pMult + 0.5))
	local maxLife = math.max(0.14, tonumber(life) or 0.40)
	local host = (typeof(posOrPart) == "Instance" and posOrPart:IsA("BasePart")) and posOrPart or makeAnchorNode(posOrPart, maxLife + 0.15)
	local att = Instance.new("Attachment")
	att.Parent = host
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = tex or TEX_SPARK
	pe.Color = pal.Seq
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, sz0 or 0.9),
		NumberSequenceKeypoint.new(0.5, ((sz0 or 0.9) + (sz1 or 0.05)) * 0.55),
		NumberSequenceKeypoint.new(1, sz1 or 0),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.04),
		NumberSequenceKeypoint.new(0.68, 0.36),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.LightEmission = 0.92
	pe.LightInfluence = 0.05
	pe.Lifetime = NumberRange.new(maxLife * 0.65, maxLife)
	pe.Speed = NumberRange.new(spdMin or 8, spdMax or 26)
	local sp = spreadDeg or 180
	pe.SpreadAngle = Vector2.new(sp, sp)
	pe.Drag = 3.8
	pe.Rate = 0
	pe.Parent = att
	pe:Emit(count)
	Debris:AddItem(att, maxLife + 0.12)
	return pe
end

local function spawnHoopRing(cfCenter, color, r0, r1, thick, dur, mat)
	local cyl = makeGeoPart(
		"SonicHoop",
		Enum.PartType.Cylinder,
		Vector3.new(thick or 0.22, r0, r0),
		cfCenter * CFrame.Angles(0, 0, math.pi * 0.5),
		color,
		0.14,
		mat or Enum.Material.Neon
	)
	tweenOutAndDebris(cyl, dur or 0.36, {
		Size = Vector3.new(math.max(0.06, (thick or 0.22) * 0.3), r1, r1),
		Transparency = 1,
	})
	return cyl
end

-- ============================================================================
-- LAYER 3: RAYCAST-GATED 3D GROUND DESTRUCTION VS AERIAL SONIC CLOUD RINGS
-- ============================================================================
local function buildWorldRaycastParams(actorChar)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	local excl = {}
	local _, tf = getVFXRoot()
	if tf then table.insert(excl, tf) end
	if actorChar then table.insert(excl, actorChar) end
	if LocalPlayer and LocalPlayer.Character then table.insert(excl, LocalPlayer.Character) end
	local ae = Workspace:FindFirstChild("ActiveEnemies")
	if ae then table.insert(excl, ae) end
	local ab = Workspace:FindFirstChild("ActiveBosses")
	if ab then table.insert(excl, ab) end
	rp.FilterDescendantsInstances = excl
	rp.RespectCanCollide = true
	return rp
end

local function resolveFloorMaterial(rawMat, rayHit)
	if type(rawMat) == "string" and rawMat ~= "" then
		local ok, m = pcall(function() return Enum.Material[rawMat] end)
		if ok and m then
			return m
		end
	end
	if rayHit and rayHit.Material and rayHit.Material ~= Enum.Material.Air then
		return rayHit.Material
	end
	return Enum.Material.Slate
end

function Engine.SpawnGroundOrAerialImpact(pos, dir, radius, pal, impactGround, groundMatName, groundColor, actorChar)
	local tier, _, debrisMult = getTierBudget()
	local rad = math.clamp(tonumber(radius) or 12, 5, 30)
	local rp = buildWorldRaycastParams(actorChar)
	-- Must hit solid floor/terrain within <= 10 studs below pos!
	local rayOrigin = pos + Vector3.new(0, 3.5, 0)
	local hit = Workspace:Raycast(rayOrigin, Vector3.new(0, -13.5, 0), rp)
	local floorWithin10 = (hit ~= nil) and ((pos.Y - hit.Position.Y) <= 10.0)

	if impactGround == true and floorWithin10 and hit then
		local gPos = hit.Position
		local gNorm = hit.Normal.Unit
		local upRight = math.abs(gNorm.Y) > 0.95 and Vector3.xAxis or Vector3.yAxis
		local tangent = gNorm:Cross(upRight).Unit
		local bitangent = tangent:Cross(gNorm).Unit
		local surfCF = CFrame.fromMatrix(gPos + gNorm * 0.08, tangent, gNorm, bitangent)

		-- Shockwave rings flush with floor normal
		spawnHoopRing(surfCF, pal.Core, rad * 0.25, rad * 1.45, 0.24, 0.42, Enum.Material.Neon)
		spawnHoopRing(surfCF * CFrame.new(0, 0.14, 0), pal.Mid, rad * 0.18, rad * 1.15, 0.18, 0.34, Enum.Material.Neon)

		-- Glowing elemental fissure cracks radiating outward along ground plane
		local crackCount = (tier == "Smooth") and 4 or ((tier == "Balanced") and 5 or 7)
		for i = 1, crackCount do
			local ang = ((i - 1) / crackCount) * math.pi * 2 + (i * 0.19)
			local cLen = rad * (0.65 + (i % 3) * 0.18)
			local cCF = surfCF * CFrame.Angles(0, ang, 0) * CFrame.new(0, 0.04, -cLen * 0.5)
			local fissure = makeGeoPart(
				"GroundFissure",
				Enum.PartType.Block,
				Vector3.new(0.32, 0.08, cLen),
				cCF,
				(i % 2 == 0) and pal.Core or pal.Mid,
				0.08,
				Enum.Material.Neon,
				nil,
				false
			)
			tweenOutAndDebris(fissure, 0.68, {
				Size = Vector3.new(0.06, 0.04, cLen * 1.08),
				Transparency = 1,
			})
		end

		-- Tilted 3D rubble slabs inheriting actual floor Material & Color (skipped on "Smooth")
		if debrisMult > 0 then
			local slabMat = resolveFloorMaterial(groundMatName, hit)
			local slabCol = (typeof(groundColor) == "Color3" and groundColor)
				or (hit.Instance and hit.Instance:IsA("BasePart") and hit.Instance.Color)
				or Color3.fromRGB(92, 98, 112)
			local slabCount = math.max(4, math.floor(10 * debrisMult + 0.5))
			for i = 1, slabCount do
				local ang = ((i - 1) / slabCount) * math.pi * 2
				local r0 = rad * 0.38
				local r1 = rad * 0.88
				local startCF = surfCF * CFrame.Angles(0, ang, 0) * CFrame.new(0, -0.25, -r0) * CFrame.Angles(math.rad(28 + (i % 3) * 8), 0, math.rad((i % 2 == 0 and 12 or -12)))
				local peakCF = surfCF * CFrame.Angles(0, ang, 0) * CFrame.new(0, 0.52, -r1) * CFrame.Angles(math.rad(42), 0, math.rad((i % 2 == 0 and 18 or -18)))
				local sinkCF = peakCF * CFrame.new(0, -1.35, -0.35)
				local slabSz = Vector3.new(1.35 + (i % 2) * 0.55, 0.52, 1.15 + (i % 3) * 0.35)
				local slab = makeGeoPart("GroundRubbleSlab", Enum.PartType.Block, slabSz, startCF, slabCol, 0, slabMat, nil, false)
				TweenService:Create(slab, TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { CFrame = peakCF }):Play()
				task.delay(0.42, function()
					if slab and slab.Parent then
						tweenOutAndDebris(slab, 0.45, { CFrame = sinkCF, Transparency = 1 }, Enum.EasingStyle.Quad)
					end
				end)
				Debris:AddItem(slab, 0.96)
			end
		end
		emit3ToneBurst(gPos + gNorm * 0.4, pal, 16, 1.1, 0.1, 12, 34, 0.46, TEX_SPARK, 160)
	else
		-- Aerial / Non-Ground Impact: Crisp sonic wind/cloud rings ONLY — NEVER floating rocks!
		local aimDir = (typeof(dir) == "Vector3" and dir.Magnitude > 0.05) and dir.Unit or Vector3.yAxis
		local ringCF = safeLook(pos, pos + aimDir) * CFrame.Angles(math.pi * 0.5, 0, 0)
		spawnHoopRing(ringCF, pal.Core, rad * 0.22, rad * 1.25, 0.20, 0.34, Enum.Material.Neon)
		spawnHoopRing(CFrame.new(pos), pal.Mid, rad * 0.18, rad * 0.95, 0.14, 0.30, Enum.Material.Neon)
		emit3ToneBurst(pos, pal, 10, 1.35, 2.6, 6, 18, 0.34, TEX_SMOKE, 180)
	end
end

-- ============================================================================
-- LAYER 4: FUTURE POINTLIGHT + TOKEN-GUARDED 35MS ULTIMATE IMPACT FRAME
-- ============================================================================
function Engine.SpawnDynamicLight(pos, pal, isMajorSkill, isM1, dur)
	local tier, _, _, allowShadows = getTierBudget()
	if tier == "Smooth" and isM1 then
		return
	end
	local life = math.max(0.14, tonumber(dur) or (isM1 and 0.20 or 0.38))
	local node = makeAnchorNode(pos, life + 0.08)
	local pl = Instance.new("PointLight")
	pl.Color = pal.Core:Lerp(pal.Mid, 0.55)
	if isM1 then
		pl.Brightness = 0.90
		pl.Range = 10
		pl.Shadows = false
	else
		pl.Brightness = isMajorSkill and 2.05 or 1.45
		pl.Range = isMajorSkill and 20 or 14
		pl.Shadows = (allowShadows and isMajorSkill == true)
	end
	pl.Parent = node
	TweenService:Create(pl, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Brightness = 0,
	}):Play()
end

function Engine.ResetUltimateImpactState()
	UltimateVFXToken += 1
	local cc = Lighting:FindFirstChild("SkybreakUltImpactCC")
	if cc and cc:IsA("ColorCorrectionEffect") then
		cc.Enabled = false
		cc.Brightness = 0
		cc.Contrast = 0
		cc.Saturation = 0
		cc.TintColor = Color3.new(1, 1, 1)
	end
	Workspace:SetAttribute("SkybreakUltimateUntil", 0)
end

function Engine.TriggerUltimateImpactAndSkyTint(pos, pal, isLocal)
	local _, _, _, _, allowUlt = getTierBudget()
	if not allowUlt then
		return
	end
	local lp = LocalPlayer or Players.LocalPlayer
	if not isLocal then
		local r = lp and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
		if not r or (r.Position - pos).Magnitude > 180 then
			return
		end
	end

	UltimateVFXToken += 1
	local myToken = UltimateVFXToken

	Workspace:SetAttribute("SkybreakUltimateTint", pal.Mid)
	Workspace:SetAttribute("SkybreakUltimateUntil", os.clock() + 0.75)

	if isLocal then
		local cc = Lighting:FindFirstChild("SkybreakUltImpactCC")
		if not (cc and cc:IsA("ColorCorrectionEffect")) then
			cc = Instance.new("ColorCorrectionEffect")
			cc.Name = "SkybreakUltImpactCC"
			cc.Parent = Lighting
		end
		cc.Brightness = 0.06
		cc.Contrast = 0.65
		cc.Saturation = -0.22
		cc.TintColor = pal.Core:Lerp(pal.Mid, 0.45)
		cc.Enabled = true

		task.delay(0.035, function()
			if UltimateVFXToken ~= myToken then return end
			if cc and cc.Parent then
				cc.Enabled = false
				cc.Brightness = 0
				cc.Contrast = 0
				cc.Saturation = 0
				cc.TintColor = Color3.new(1, 1, 1)
			end
		end)
	end

	task.delay(0.76, function()
		if UltimateVFXToken == myToken then
			Workspace:SetAttribute("SkybreakUltimateUntil", 0)
		end
	end)
end

-- ============================================================================
-- LAYER 5: SYNCHRONIZED CAMERA CHOREOGRAPHY (CAST SNAP + DELAYED DETONATION)
-- ============================================================================
function Engine.PulseCamera(pos, trauma, fovPunch, dirVec, isLocal)
	local tier = Engine.GetGraphicsTier()
	if tier == "Smooth" then
		return
	end
	local lp = LocalPlayer or Players.LocalPlayer
	if not lp then return end
	local scale = 1.0
	if not isLocal then
		local r = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
		if not r then return end
		local d = (r.Position - pos).Magnitude
		if d > 95 then return end
		scale = math.clamp(1 - (d / 95), 0.15, 0.65)
	end
	local _, tf = getVFXRoot()
	local camEvt = tf and tf:FindFirstChild("SkybreakCameraImpulse")
	local tr = (trauma or 0.24) * scale
	local fv = (fovPunch or 0) * scale
	if camEvt and camEvt:IsA("BindableEvent") then
		camEvt:Fire(tr, fv, dirVec)
	else
		lp:SetAttribute("SkybreakTraumaPulse", tr)
		if math.abs(fv) > 0.05 then
			lp:SetAttribute("SkybreakFovPunch", fv)
		end
	end
end


-- ============================================================================
-- LAYER 2 GEOMETRY HELPERS: CURVED 3D SLASH ARCS, THRUST CONES & SIPHON WISPS
-- ============================================================================
local function spawnCurvedSlashArc(originCF, radius, arcDeg, rollDeg, width, pal, dur, segs)
	local tier = Engine.GetGraphicsTier()
	local nSeg = (tier == "Smooth") and 5 or ((tier == "Balanced") and 7 or (segs or 9))
	local life = math.max(0.14, tonumber(dur) or 0.26)
	local r0 = math.max(2.5, tonumber(radius) or 7.5)
	local halfRad = math.rad((tonumber(arcDeg) or 140) * 0.5)
	local planeCF = originCF * CFrame.Angles(0, 0, math.rad(tonumber(rollDeg) or 0))
	local holder = makeAnchorNode(planeCF.Position, life + 0.10)

	local attsOuter = {}
	local attsCore = {}
	for i = 0, nSeg do
		local frac = i / nSeg
		local ang = -halfRad + (frac * halfRad * 2)
		local pLocal = Vector3.new(math.sin(ang) * r0, 0, -math.cos(ang) * r0)
		local pWorld = planeCF:PointToWorldSpace(pLocal)

		local aOut = Instance.new("Attachment")
		aOut.WorldPosition = pWorld
		aOut.Parent = holder
		attsOuter[i + 1] = aOut

		local aIn = Instance.new("Attachment")
		aIn.WorldPosition = planeCF:PointToWorldSpace(pLocal * 0.94)
		aIn.Parent = holder
		attsCore[i + 1] = aIn

		local endWorld = planeCF:PointToWorldSpace(pLocal * 1.24)
		TweenService:Create(aOut, TweenInfo.new(life, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			WorldPosition = endWorld,
		}):Play()
		TweenService:Create(aIn, TweenInfo.new(life, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			WorldPosition = planeCF:PointToWorldSpace(pLocal * 1.18),
		}):Play()
	end

	for i = 1, nSeg do
		local edgeFactor = math.sin(((i - 0.5) / nSeg) * math.pi)
		local wSheath = math.max(0.18, (width or 1.35) * (0.35 + 0.85 * edgeFactor))
		local wCore = wSheath * 0.44

		local bmSheath = Instance.new("Beam")
		bmSheath.Attachment0 = attsOuter[i]
		bmSheath.Attachment1 = attsOuter[i + 1]
		bmSheath.Color = pal.Seq
		bmSheath.Width0 = wSheath
		bmSheath.Width1 = wSheath
		bmSheath.LightEmission = 0.90
		bmSheath.LightInfluence = 0
		bmSheath.FaceCamera = true
		bmSheath.Segments = 4
		bmSheath.Transparency = NumberSequence.new(0.10, 0.36)
		bmSheath.Parent = holder

		local bmCore = Instance.new("Beam")
		bmCore.Attachment0 = attsCore[i]
		bmCore.Attachment1 = attsCore[i + 1]
		bmCore.Color = ColorSequence.new(pal.Core)
		bmCore.Width0 = wCore
		bmCore.Width1 = wCore
		bmCore.LightEmission = 0.98
		bmCore.LightInfluence = 0
		bmCore.FaceCamera = true
		bmCore.Segments = 4
		bmCore.Transparency = NumberSequence.new(0.02, 0.18)
		bmCore.Parent = holder

		TweenService:Create(bmSheath, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Width0 = 0,
			Width1 = 0,
		}):Play()
		TweenService:Create(bmCore, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Width0 = 0,
			Width1 = 0,
		}):Play()
	end

	-- Crisp leading wedge blade-edge tip (PreserveGeometry = true, never sphere-blobbed)
	local tipAng = halfRad * 0.86
	local tipCF = planeCF * CFrame.Angles(0, -tipAng, 0) * CFrame.new(0, 0, -r0)
	local tipWedge = makeGeoPart("SlashRazorTip", Enum.PartType.Wedge, Vector3.new(0.14, (width or 1.2) * 0.55, 2.4), tipCF, pal.Core, 0.06, Enum.Material.Neon, holder, false)
	tweenOutAndDebris(tipWedge, life * 0.9, {
		CFrame = tipCF * CFrame.new(0, 0, -r0 * 0.25),
		Size = Vector3.new(0.04, 0.12, 3.2),
		Transparency = 1,
	})
	return holder
end

local function spawnThrustCone(originPos, dirVec, length, baseRad, pal, dur)
	local u = (typeof(dirVec) == "Vector3" and dirVec.Magnitude > 0.05) and dirVec.Unit or Vector3.new(0, 0, -1)
	local len = math.max(5, tonumber(length) or 15)
	local rad = math.max(0.8, tonumber(baseRad) or 2.2)
	local life = math.max(0.14, tonumber(dur) or 0.24)
	local aimCF = safeLook(originPos, originPos + u)

	-- Central razor thrust needle + outer slipstream cone wedges
	local coreShaft = makeGeoPart(
		"ThrustCoreShaft",
		Enum.PartType.Block,
		Vector3.new(rad * 0.22, rad * 0.22, len * 0.72),
		aimCF * CFrame.new(0, 0, -len * 0.36),
		pal.Core,
		0.04,
		Enum.Material.Neon
	)
	tweenOutAndDebris(coreShaft, life, {
		CFrame = aimCF * CFrame.new(0, 0, -len * 0.62),
		Size = Vector3.new(0.05, 0.05, len * 1.05),
		Transparency = 1,
	})

	for fin = 1, 4 do
		local roll = (fin - 1) * (math.pi * 0.5)
		local wCF = aimCF * CFrame.Angles(0, 0, roll) * CFrame.new(0, rad * 0.32, -len * 0.34)
		local finWedge = makeGeoPart(
			"ThrustConeFin",
			Enum.PartType.Wedge,
			Vector3.new(0.10, rad * 0.62, len * 0.64),
			wCF,
			(fin % 2 == 0) and pal.Mid or pal.Core,
			0.18,
			Enum.Material.Neon
		)
		tweenOutAndDebris(finWedge, life, {
			CFrame = aimCF * CFrame.Angles(0, 0, roll) * CFrame.new(0, rad * 0.58, -len * 0.58),
			Size = Vector3.new(0.04, rad * 0.14, len * 0.88),
			Transparency = 1,
		})
	end

	-- Concentric Mach air-pierce ring perpendicular to thrust axis
	local ringCF = aimCF * CFrame.new(0, 0, -2.4) * CFrame.Angles(math.pi * 0.5, 0, 0)
	spawnHoopRing(ringCF, pal.Mid, rad * 0.55, rad * 2.15, 0.16, life * 1.05, Enum.Material.Neon)
end

local function spawnSiphonWispsToCaster(fromPos, actorChar, pal, wispCount)
	local root = actorChar and actorChar:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	local tier = Engine.GetGraphicsTier()
	local n = (tier == "Smooth") and 1 or math.clamp(tonumber(wispCount) or 3, 1, 5)
	for i = 1, n do
		task.delay((i - 1) * 0.045, function()
			if not (root and root.Parent) then return end
			local dst = root.Position
			local sideOffset = Vector3.new(math.cos(i * 2.1) * 3.2, 1.4 + (i % 2) * 1.2, math.sin(i * 2.1) * 3.2)
			local startP = fromPos + sideOffset * 0.45
			makeRibbonBeam(startP, dst, pal, 0.55, 0.18, (i % 2 == 0 and 4.5 or -4.5), 2.0, 0.34, nil, 14)
			local orb = makeGeoPart("SiphonWisp", Enum.PartType.Ball, Vector3.new(0.68, 0.68, 0.68), CFrame.new(startP), pal.Core, 0.06, Enum.Material.Neon, nil, false)
			tweenOutAndDebris(orb, 0.32, {
				CFrame = CFrame.new(dst),
				Size = Vector3.new(0.18, 0.18, 0.18),
				Transparency = 1,
			}, Enum.EasingStyle.Sine)
		end)
	end
end

-- ============================================================================
-- 0MS LOCAL BEAT-1 PRE-CAST COIL (NO DUPLICATE TRAJECTORY / PROJECTILES)
-- ============================================================================
function Engine.SpawnLocalPreCast(pos, actorChar, data, pal)
	local slot = tonumber(data.Slot) or 2
	local key = string.upper(tostring(data.MoveKey or data.key or "Z"))
	local root = actorChar and actorChar:FindFirstChild("HumanoidRootPart")
	local baseCF = root and root.CFrame or CFrame.new(pos)
	local footPos = baseCF.Position - Vector3.new(0, 2.55, 0)

	-- Clean stance coil ring at feet + focused hand/weapon gather spark
	spawnHoopRing(CFrame.new(footPos), pal.Mid, 1.6, (key == "V" and 7.2 or 4.8), 0.16, 0.22, Enum.Material.Neon)
	local handOrigin = (baseCF * CFrame.new((slot == 3 or slot == 4) and 1.15 or 0, 0.45, -1.35)).Position
	local sparkCore = makeGeoPart("PreCastGather", Enum.PartType.Ball, Vector3.new(0.45, 0.45, 0.45), CFrame.new(handOrigin), pal.Core, 0.08, Enum.Material.Neon, nil, false)
	tweenOutAndDebris(sparkCore, 0.18, {
		Size = Vector3.new(1.55, 1.55, 1.55),
		Transparency = 1,
	})
	emit3ToneBurst(handOrigin, pal, (key == "V" and 10 or 6), 0.65, 0.05, 6, 16, 0.22, TEX_SPARK, 180)
end

-- ============================================================================
-- CHOREOGRAPHY-SYNCHRONIZED M1 VFX (SLOTS 1..4: SPEAR, KATANA, GREATSWORD, ETC.)
-- ============================================================================
function Engine.SpawnM1VFX(pos, endPos, dir, actorChar, data, pal, isLocal)
	local bp = getBlueprints()
	local root = actorChar and actorChar:FindFirstChild("HumanoidRootPart")
	local slot = tonumber(data.Slot or data.slot or (actorChar and actorChar:GetAttribute("ActiveSlot")) or (LocalPlayer and LocalPlayer:GetAttribute("ActiveSlot"))) or 3
	if tostring(data.Kind or "") == "StyleMove" then
		slot = 1
	elseif tostring(data.Kind or "") == "GunShot" then
		slot = 4
	elseif tostring(data.Kind or "") == "ChargedSlash" then
		slot = 3
	end

	local step = ((math.max(1, math.floor(tonumber(data.Combo or data.ComboStep) or 1)) - 1) % 4) + 1
	local isHeavy = (data.Heavy == true) or (tostring(data.Kind or "") == "ChargedSlash") or (step == 4)
	local itemId = tostring(data.ItemId or data.ActiveId or data.StyleId or data.FruitId or "")
	if itemId == "" and actorChar then
		if slot == 1 then
			itemId = tostring(actorChar:GetAttribute("FightingStyle") or "skyborn_combat")
		elseif slot == 2 then
			itemId = tostring(actorChar:GetAttribute("EquippedFruit") or "GaleCore")
		elseif slot == 3 then
			itemId = tostring(actorChar:GetAttribute("EquippedWeapon") or "starter_sword")
		else
			itemId = tostring(actorChar:GetAttribute("EquippedGun") or "aether_flintlock")
		end
	end

	local m1Spec = nil
	if bp and type(bp.GetM1Blueprint) == "function" then
		local dTier = tonumber(data.DragonFormTier or (actorChar and actorChar:GetAttribute("DragonFormTier"))) or 0
		local fTrans = tostring((actorChar and actorChar:GetAttribute("FruitTransform")) or "")
		local ok, res = pcall(bp.GetM1Blueprint, slot, itemId, step, { DragonFormTier = dTier, FruitTransform = fTrans })
		if ok and type(res) == "table" then
			m1Spec = res
		end
	end

	local wArch = tostring(data.WeaponArchetype or (m1Spec and m1Spec.WeaponArchetype) or "")
	local beatArch = tostring(data.Archetype or (m1Spec and m1Spec.Archetype) or "")
	local reach = math.clamp(tonumber(data.Range or (m1Spec and m1Spec.Reach)) or 15, 8, 120)
	local impactGround = (data.ImpactGround == true) or (m1Spec and m1Spec.ImpactGround == true) or false
	if (not data.Element) and m1Spec and m1Spec.Element then
		data.Element = m1Spec.Element
		pal = Engine.ResolvePalette(data)
	elseif wArch ~= "" and PALETTES[wArch] and (not data.Element) then
		pal = PALETTES[wArch]
	end

	local aimDir = (typeof(dir) == "Vector3" and dir.Magnitude > 0.05) and dir.Unit
		or (root and root.CFrame.LookVector)
		or Vector3.new(0, 0, -1)
	local origin = (root and (root.Position + Vector3.new(0, 0.35, 0))) or pos
	local baseCF = safeLook(origin, origin + aimDir)

	if slot == 3 then
		if wArch == "Spear" then
			-- MUA GIAO 4-BEAT POLEARM CHOREOGRAPHY
			if step == 1 and not (data.Heavy == true) then
				spawnCurvedSlashArc(baseCF, 8.6, 155, -10, 1.35, pal, 0.25, 9)
			elseif step == 2 or beatArch == "SpearTriplePoke" then
				for k = 1, 3 do
					task.delay((k - 1) * 0.055, function()
						local off = Vector3.new((k - 2) * 0.85, ((k % 2 == 0) and 0.35 or -0.20), 0)
						local p0 = baseCF:PointToWorldSpace(off)
						spawnThrustCone(p0, aimDir, reach * 0.92, 1.95, pal, 0.20)
					end)
				end
			elseif step == 3 then
				-- 360-degree helical dual-ribbon shaft vortex around polearm center
				spawnCurvedSlashArc(baseCF * CFrame.new(0, 0.3, -2.0), 6.8, 320, 14, 1.25, pal, 0.28, 11)
				spawnCurvedSlashArc(baseCF * CFrame.new(0, -0.2, -2.0) * CFrame.Angles(0, math.pi, 0), 6.2, 300, -14, 1.05, pal, 0.28, 10)
				spawnHoopRing(baseCF * CFrame.new(0, 0, -2.2), pal.Core, 3.0, 13.5, 0.18, 0.28, Enum.Material.Neon)
			else
				-- Beat 4 / Heavy: Vaulting overhead lance slam + shock-cone
				spawnCurvedSlashArc(baseCF, 9.5, 135, 86, 1.65, pal, 0.30, 9)
				spawnThrustCone(origin + aimDir * 1.5, (aimDir - Vector3.new(0, 0.18, 0)).Unit, reach, 2.8, pal, 0.28)
			end
		elseif wArch == "Katana" then
			-- Razor-thin Iaido gleam + 4-point star sheath glint at left hip
			local hipPos = baseCF:PointToWorldSpace(Vector3.new(-1.35, -0.45, 0.35))
			for s = 1, 2 do
				local star = makeGeoPart("SheathGlint", Enum.PartType.Block, Vector3.new(0.10, (s == 1 and 2.6 or 0.10), (s == 1 and 0.10 or 2.6)), baseCF - baseCF.Position + hipPos, pal.Core, 0.02, Enum.Material.Neon)
				tweenOutAndDebris(star, 0.18, { Transparency = 1 })
			end
			if isHeavy then
				spawnCurvedSlashArc(baseCF, 8.2, 145, 34, 0.65, pal, 0.24, 9)
				spawnCurvedSlashArc(baseCF, 8.2, 145, -34, 0.65, pal, 0.24, 9)
			else
				local roll = (step == 1 and -22) or (step == 2 and 24) or -68
				spawnCurvedSlashArc(baseCF, 7.6, 138, roll, 0.56, pal, 0.21, 9)
			end
		elseif wArch == "Greatsword" then
			-- Heavy molten/steel wide cleave arc; Beat 4 earth-splitter!
			if isHeavy then
				spawnCurvedSlashArc(baseCF, 10.2, 152, 88, 2.35, pal, 0.34, 10)
				spawnCurvedSlashArc(baseCF, 9.2, 140, 82, 1.55, pal, 0.30, 8)
				impactGround = true
			else
				local roll = (step == 1 and -16) or (step == 2 and 18) or -32
				spawnCurvedSlashArc(baseCF, 9.2, 155, roll, 2.05, pal, 0.30, 9)
			end
		elseif wArch == "DualBlades" then
			-- Simultaneous twin X-cross slash ribbons
			if step == 3 then
				spawnCurvedSlashArc(baseCF, 6.8, 310, 18, 1.05, pal, 0.24, 10)
				spawnCurvedSlashArc(baseCF * CFrame.Angles(0, math.pi, 0), 6.8, 310, -18, 1.05, pal, 0.24, 10)
			else
				local tilt = (step % 2 == 1) and 38 or 54
				spawnCurvedSlashArc(baseCF, 6.8, 130, tilt, 0.92, pal, 0.21, 8)
				spawnCurvedSlashArc(baseCF, 6.8, 130, -tilt, 0.92, pal, 0.21, 8)
			end
		elseif wArch == "Scythe" then
			-- Dark-crescent reaper arc + siphon wisps returning to caster
			local roll = isHeavy and 72 or ((step % 2 == 1) and -20 or 22)
			spawnCurvedSlashArc(baseCF, 9.4, 172, roll, 1.75, pal, 0.28, 10)
			spawnSiphonWispsToCaster(origin + aimDir * 8.5, actorChar, pal, isHeavy and 3 or 2)
		else
			local roll = isHeavy and 82 or ((step % 2 == 1) and -24 or 24)
			spawnCurvedSlashArc(baseCF, 7.8, 142, roll, 1.15, pal, 0.23, 8)
		end

		local tipPos = origin + aimDir * math.min(reach * 0.72, 11)
		emit3ToneBurst(tipPos, pal, isHeavy and 12 or 6, 0.85, 0.08, 8, 22, 0.26, TEX_SPARK, 140)
		Engine.SpawnDynamicLight(tipPos, pal, false, true, 0.20)
		if isHeavy and impactGround then
			Engine.SpawnGroundOrAerialImpact(origin + aimDir * 7.5, aimDir, 10.5, pal, true, data.GroundMaterial, data.GroundColor, actorChar)
			Engine.PulseCamera(origin, 0.24, 1.4, aimDir, isLocal)
		end
		return
	end

	if slot == 4 then
		-- SLOT 4 GUN ARCHETYPES: RAILGUN, VOID LYRE, BOW, CANNON, PISTOL/RIFLE
		local muzzlePos = baseCF:PointToWorldSpace(Vector3.new(0.85, 0.35, -2.2))
		local targetPos = (typeof(endPos) == "Vector3" and (endPos - muzzlePos).Magnitude > 2)
			and endPos
			or (muzzlePos + aimDir * reach)
		local shotVec = targetPos - muzzlePos
		local shotLen = math.clamp(shotVec.Magnitude, 6, 118)
		local shotDir = shotVec.Unit
		targetPos = muzzlePos + shotDir * shotLen

		if wArch == "Railgun" then
			-- 115m Cryo-Rail 3-shell beam + concentric frost Mach rings
			makeRibbonBeam(muzzlePos, targetPos, pal, 1.45, 0.95, 0, 0, 0.32, nil, 8)
			local coreRod = makeGeoPart("CryoRailCore", Enum.PartType.Block, Vector3.new(0.32, 0.32, shotLen), safeLook(muzzlePos, targetPos) * CFrame.new(0, 0, -shotLen * 0.5), pal.Core, 0.02, Enum.Material.Neon)
			tweenOutAndDebris(coreRod, 0.28, { Size = Vector3.new(0.05, 0.05, shotLen), Transparency = 1 })
			local ringCount = (Engine.GetGraphicsTier() == "Smooth") and 3 or 5
			for r = 1, ringCount do
				local rpPos = muzzlePos + shotDir * (shotLen * ((r - 0.5) / ringCount))
				spawnHoopRing(safeLook(rpPos, rpPos + shotDir) * CFrame.Angles(math.pi * 0.5, 0, 0), (r % 2 == 0) and pal.Mid or pal.Core, 1.4, 5.6, 0.16, 0.30, Enum.Material.Neon)
			end
			emit3ToneBurst(targetPos, pal, 12, 1.0, 0.1, 10, 28, 0.32, TEX_SPARK, 180)
		elseif wArch == "VoidLyre" or wArch == "AcousticGuitar" then
			-- Expanding harmonic soundwave rings + soul-siphon motes returning to caster
			for w = 1, 3 do
				task.delay((w - 1) * 0.045, function()
					local wp = muzzlePos + shotDir * (shotLen * (w / 3.2))
					spawnHoopRing(safeLook(wp, wp + shotDir) * CFrame.Angles(math.pi * 0.5, 0, 0), (w == 2) and pal.Core or pal.Mid, 1.8, 7.5 + w * 1.4, 0.20, 0.34, Enum.Material.Neon)
				end)
			end
			makeRibbonBeam(muzzlePos, targetPos, pal, 0.9, 0.4, 3.2, -3.2, 0.30, nil, 16)
			spawnSiphonWispsToCaster(targetPos, actorChar, pal, 3)
		elseif wArch == "Bow" then
			-- Gale arrow streak + spiral wind slipstream ribbon
			spawnThrustCone(muzzlePos, shotDir, math.min(shotLen, 22), 1.4, pal, 0.22)
			makeRibbonBeam(muzzlePos, targetPos, pal, 0.65, 0.18, 2.4, -2.4, 0.26, nil, 14)
			emit3ToneBurst(targetPos, pal, 8, 0.8, 0.08, 8, 22, 0.28, TEX_SPARK, 160)
		elseif wArch == "Cannon" then
			-- Siege muzzle blast + molten shell impact burst
			spawnHoopRing(safeLook(muzzlePos, targetPos) * CFrame.Angles(math.pi * 0.5, 0, 0), pal.Core, 1.2, 5.2, 0.24, 0.26, Enum.Material.Neon)
			makeRibbonBeam(muzzlePos, targetPos, pal, 1.15, 0.65, 0, 2.5, 0.28, nil, 12)
			local blast = makeGeoPart("CannonImpact", Enum.PartType.Ball, Vector3.new(2.2, 2.2, 2.2), CFrame.new(targetPos), pal.Mid, 0.12, Enum.Material.Neon, nil, false)
			tweenOutAndDebris(blast, 0.32, { Size = Vector3.new(9.5, 9.5, 9.5), Transparency = 1 })
			Engine.SpawnGroundOrAerialImpact(targetPos, shotDir, 8.5, pal, true, data.GroundMaterial, data.GroundColor, actorChar)
		else
			-- Crisp flintlock / twin chrono pistols muzzle star + high-speed tracer
			local shots = (itemId == "aion_chrono_pistols") and 2 or 1
			for s = 1, shots do
				task.delay((s - 1) * 0.065, function()
					local mOff = baseCF:PointToWorldSpace(Vector3.new((s == 2 and -0.85 or 0.85), 0.35, -2.2))
					spawnHoopRing(safeLook(mOff, targetPos) * CFrame.Angles(math.pi * 0.5, 0, 0), pal.Core, 0.7, 2.8, 0.12, 0.18, Enum.Material.Neon)
					makeRibbonBeam(mOff, targetPos, pal, 0.48, 0.14, 0, 0, 0.19, nil, 6)
					emit3ToneBurst(targetPos, pal, 6, 0.65, 0.05, 8, 20, 0.22, TEX_SPARK, 160)
				end)
			end
		end
		Engine.SpawnDynamicLight(muzzlePos, pal, false, true, 0.18)
		return
	end

	if slot == 1 then
		-- SLOT 1 MARTIAL ARTS KATAS (8 STYLES)
		if wArch == "KickKata" or itemId == "SkyStep" then
			local roll = isHeavy and 85 or ((step % 2 == 1) and 16 or -18)
			spawnCurvedSlashArc(baseCF, isHeavy and 8.4 or 7.0, isHeavy and 175 or 230, roll, 1.35, pal, 0.25, 9)
		elseif wArch == "DragonClaw" or wArch == "VoltTalon" or wArch == "SanguineDrain" then
			-- 3 parallel razor claw-rip arcs
			local sideSign = (step % 2 == 1) and 1 or -1
			for c = -1, 1 do
				local cCF = baseCF * CFrame.new(0, c * 0.48, 0)
				spawnCurvedSlashArc(cCF, 7.2, 122, sideSign * 28, 0.48, pal, 0.22, 7)
			end
			if wArch == "SanguineDrain" or itemId == "SanguineVoidArt" then
				spawnSiphonWispsToCaster(origin + aimDir * 6.5, actorChar, pal, 2)
			end
		else
			-- Sonic fist / palm compression shock-cone + hoop
			spawnThrustCone(origin + aimDir * 1.1, aimDir, isHeavy and 13.5 or 10.2, isHeavy and 2.5 or 1.85, pal, 0.21)
		end
		local hitPos = origin + aimDir * 6.5
		emit3ToneBurst(hitPos, pal, isHeavy and 10 or 5, 0.75, 0.06, 8, 20, 0.24, TEX_SPARK, 150)
		Engine.SpawnDynamicLight(hitPos, pal, false, true, 0.18)
		if isHeavy and impactGround then
			Engine.SpawnGroundOrAerialImpact(hitPos, aimDir, 9.5, pal, true, data.GroundMaterial, data.GroundColor, actorChar)
			Engine.PulseCamera(origin, 0.22, 1.2, aimDir, isLocal)
		end
		return
	end

	-- SLOT 2 CORE M1S (FROST SPEAR, LIGHT KATANA, DRAGON CLAW, ELEMENTAL PALM)
	local cid = Engine.ResolveCoreId(itemId)
	if cid == "GlacierIceCore" then
		if step == 2 then
			for k = 1, 3 do
				task.delay((k - 1) * 0.055, function()
					spawnThrustCone(baseCF:PointToWorldSpace(Vector3.new((k - 2) * 0.8, 0, 0)), aimDir, 13.5, 1.75, pal, 0.20)
				end)
			end
		else
			spawnCurvedSlashArc(baseCF, 8.2, 145, isHeavy and 80 or -18, 1.25, pal, 0.24, 8)
		end
	elseif cid == "CelestialLightCore" then
		spawnCurvedSlashArc(baseCF, 8.0, 142, isHeavy and 75 or ((step % 2 == 1) and -24 or 24), 0.70, pal, 0.21, 9)
	elseif cid == "AbyssalSovereignCore" then
		local tScale = (tonumber(data.DragonFormTier or (actorChar and actorChar:GetAttribute("DragonFormTier"))) or 0) >= 2 and 1.35 or 1.0
		for c = -1, 1 do
			spawnCurvedSlashArc(baseCF * CFrame.new(0, c * 0.65 * tScale, 0), 8.6 * tScale, 132, ((step % 2 == 1) and 32 or -32), 0.75 * tScale, pal, 0.24, 8)
		end
	else
		spawnThrustCone(origin + aimDir * 1.2, aimDir, isHeavy and 15.0 or 11.5, isHeavy and 2.6 or 1.95, pal, 0.23)
	end
	local pHit = origin + aimDir * 7.5
	emit3ToneBurst(pHit, pal, isHeavy and 12 or 6, 0.85, 0.08, 8, 22, 0.25, TEX_PLASMA, 160)
	Engine.SpawnDynamicLight(pHit, pal, false, true, 0.20)
	if isHeavy and impactGround then
		Engine.SpawnGroundOrAerialImpact(pHit, aimDir, 10.5, pal, true, data.GroundMaterial, data.GroundColor, actorChar)
	end
end

-- ============================================================================
-- PERSISTENT HAZARD ZONES (ALL 5 HAZARDKINDS MATCHING HAZARDDURATION)
-- ============================================================================
function Engine.SpawnHazardZoneVFX(centerPos, radius, duration, hazardKind, pal, actorChar)
	local dur = math.clamp(tonumber(duration) or 3.2, 0.8, 12.0)
	local rad = math.clamp(tonumber(radius) or 12, 6, 34)
	local kind = tostring(hazardKind or "MagmaPool")
	local tier, pMult = getTierBudget()

	local rp = buildWorldRaycastParams(actorChar)
	local hit = Workspace:Raycast(centerPos + Vector3.new(0, 5, 0), Vector3.new(0, -18, 0), rp)
	local gPos = hit and (hit.Position + Vector3.new(0, 0.08, 0)) or centerPos

	local rootFolder = getVFXRoot()
	local mdl = Instance.new("Model")
	mdl.Name = "HazardZone_" .. kind
	mdl:SetAttribute("PreserveGeometry", true)
	mdl.Parent = rootFolder
	Debris:AddItem(mdl, dur + 0.55)

	local hPal = (kind == "MagmaPool" and PALETTES.StarforgedMagmaCore)
		or (kind == "FrostSheet" and PALETTES.GlacierIceCore)
		or (kind == "StormCage" and PALETTES.ThunderRumbleCore)
		or (kind == "ChronoField" and PALETTES.ChronoVoidPalm)
		or (kind == "Quicksand" and PALETTES.SandstoneCore)
		or pal

	local baseMat = (kind == "FrostSheet" and Enum.Material.Ice)
		or (kind == "Quicksand" and Enum.Material.Sand)
		or Enum.Material.Neon
	local disc = makeGeoPart(
		"HazardDisc",
		Enum.PartType.Cylinder,
		Vector3.new(0.18, 2, 2),
		CFrame.new(gPos) * CFrame.Angles(0, 0, math.pi * 0.5),
		(kind == "FrostSheet") and hPal.Mid or hPal.Core:Lerp(hPal.Mid, 0.65),
		(kind == "FrostSheet") and 0.28 or 0.22,
		baseMat,
		mdl,
		false
	)
	if kind == "FrostSheet" then
		disc.Reflectance = 0.08
	end
	TweenService:Create(disc, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.18, rad * 2, rad * 2),
	}):Play()

	-- Perimeter geometry tailored to each of the 5 HazardKinds
	local pylonCount = (tier == "Smooth") and 4 or 6
	local pylons = {}
	for i = 1, pylonCount do
		local ang = ((i - 1) / pylonCount) * math.pi * 2
		local pPos = gPos + Vector3.new(math.cos(ang) * (rad * 0.92), 0, math.sin(ang) * (rad * 0.92))
		if kind == "StormCage" then
			local post = makeGeoPart("StormFencePost", Enum.PartType.Block, Vector3.new(0.32, 4.6, 0.32), CFrame.new(pPos + Vector3.new(0, 2.3, 0)), hPal.Core, 0.10, Enum.Material.Neon, mdl, false)
			pylons[i] = post
		elseif kind == "FrostSheet" then
			makeGeoPart("FrostPerimeterSpire", Enum.PartType.Wedge, Vector3.new(0.75, 2.8, 1.15), safeLook(pPos, gPos) * CFrame.new(0, 1.1, 0) * CFrame.Angles(math.rad(-24), 0, 0), hPal.Mid, 0.16, Enum.Material.Glass, mdl, false)
		elseif kind == "MagmaPool" and tier ~= "Smooth" then
			makeGeoPart("MagmaBasaltCrust", Enum.PartType.Block, Vector3.new(1.8, 0.55, 1.4), safeLook(pPos, gPos) * CFrame.Angles(math.rad(18), 0, 0), hPal.Rim, 0.04, Enum.Material.Basalt, mdl, false)
		elseif kind == "ChronoField" then
			local tickCF = CFrame.new(gPos) * CFrame.Angles(0, ang, 0) * CFrame.new(0, 0.14, -rad * 0.80)
			makeGeoPart("ChronoClockTick", Enum.PartType.Block, Vector3.new(0.28, 0.10, rad * 0.26), tickCF, hPal.Core, 0.10, Enum.Material.Neon, mdl, false)
		elseif kind == "Quicksand" then
			local swirlCF = CFrame.new(gPos + Vector3.new(0, 0.12 + (i % 2) * 0.10, 0))
			local ring = makeGeoPart("SandVortexBand", Enum.PartType.Cylinder, Vector3.new(0.10, rad * (0.35 + i * 0.22), rad * (0.35 + i * 0.22)), swirlCF * CFrame.Angles(0, 0, math.pi * 0.5), hPal.Mid, 0.38, Enum.Material.Neon, mdl, false)
			ring.Parent = mdl
		end
	end

	if kind == "StormCage" and #pylons >= 2 then
		for i = 1, #pylons do
			local nxt = pylons[(i % #pylons) + 1]
			makeRibbonBeam(pylons[i].Position + Vector3.new(0, 1.4, 0), nxt.Position + Vector3.new(0, 1.4, 0), hPal, 0.45, 0.45, 0.6, -0.6, dur, mdl, 8)
		end
	elseif kind == "ChronoField" then
		local hand = makeGeoPart("ChronoClockHand", Enum.PartType.Block, Vector3.new(0.26, 0.12, rad * 0.78), CFrame.new(gPos + Vector3.new(0, 0.22, -rad * 0.39)), hPal.Core, 0.08, Enum.Material.Neon, mdl, false)
		TweenService:Create(hand, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
			CFrame = CFrame.new(gPos + Vector3.new(0, 0.22, 0)) * CFrame.Angles(0, math.pi * 1.5, 0) * CFrame.new(0, 0, -rad * 0.39),
		}):Play()
	end

	-- Sustained ambient emitter over the hazard disc
	local att = Instance.new("Attachment")
	att.Parent = disc
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = (kind == "MagmaPool" and TEX_PLASMA) or (kind == "Quicksand" and TEX_SMOKE) or (kind == "ChronoField" and TEX_RING) or TEX_SPARK
	pe.Color = hPal.Seq
	pe.Rate = math.max(3, math.floor(16 * pMult))
	pe.Lifetime = NumberRange.new(0.45, 0.85)
	pe.Speed = NumberRange.new(2, (kind == "Quicksand" and 5 or 9))
	pe.Size = NumberSequence.new(0.75, 0)
	pe.Transparency = NumberSequence.new(0.18, 1)
	pe.LightEmission = 0.85
	pe.SpreadAngle = Vector2.new(75, 75)
	pe.Parent = att

	task.delay(math.max(0.1, dur - 0.35), function()
		if not mdl.Parent then return end
		pe.Enabled = false
		for _, ch in ipairs(mdl:GetDescendants()) do
			if ch:IsA("BasePart") then
				TweenService:Create(ch, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Transparency = 1 }):Play()
			end
		end
	end)
end

-- ============================================================================
-- ELEMENTAL SYNERGY (CRYOSHATTER) & WALL-SLAM RADIAL CRACK BURSTS
-- ============================================================================
function Engine.SpawnSynergyVFX(subKind, pos, dir, pal, actorChar, isLocal)
	local tier, _, debrisMult = getTierBudget()
	local sk = tostring(subKind or "CryoShatter")

	if sk == "WallSlam" then
		local nrm = (typeof(dir) == "Vector3" and dir.Magnitude > 0.05) and dir.Unit or Vector3.zAxis
		local upRef = math.abs(nrm.Y) > 0.94 and Vector3.xAxis or Vector3.yAxis
		local tan = nrm:Cross(upRef).Unit
		local bitan = tan:Cross(nrm).Unit
		local wallCF = CFrame.fromMatrix(pos + nrm * 0.10, tan, nrm, bitan)

		spawnHoopRing(wallCF, pal.Core, 1.4, 10.5, 0.22, 0.36, Enum.Material.Neon)
		local cracks = (tier == "Smooth") and 4 or 6
		for i = 1, cracks do
			local ang = ((i - 1) / cracks) * math.pi * 2 + 0.25
			local len = 4.2 + (i % 2) * 2.1
			local cCF = wallCF * CFrame.Angles(0, ang, 0) * CFrame.new(0, 0.04, -len * 0.5)
			local bar = makeGeoPart("WallSlamCrack", Enum.PartType.Block, Vector3.new(0.24, 0.08, len), cCF, (i % 2 == 0) and pal.Core or pal.Mid, 0.08, Enum.Material.Neon)
			tweenOutAndDebris(bar, 0.52, { Transparency = 1 })
		end
		emit3ToneBurst(pos + nrm * 0.4, pal, 14, 1.0, 0.1, 10, 28, 0.38, TEX_SPARK, 150)
		Engine.SpawnDynamicLight(pos + nrm * 0.6, pal, false, false, 0.30)
		Engine.PulseCamera(pos, 0.30, 1.6, -nrm, isLocal)
		return
	end

	-- CryoShatter: Explosive thermal/frost prism shatter!
	local cryoPal = PALETTES.GlacierIceCore
	spawnHoopRing(CFrame.new(pos), cryoPal.Core, 1.8, 15.5, 0.26, 0.38, Enum.Material.Neon)
	spawnHoopRing(CFrame.new(pos) * CFrame.Angles(math.rad(55), 0, math.rad(35)), pal.Mid, 1.5, 13.0, 0.20, 0.34, Enum.Material.Neon)
	local shardCount = math.max(4, math.floor(10 * math.max(0.4, debrisMult) + 0.5))
	for i = 1, shardCount do
		local ang = ((i - 1) / shardCount) * math.pi * 2
		local elev = ((i % 3) - 1) * 0.38
		local outDir = Vector3.new(math.cos(ang), 0.35 + elev, math.sin(ang)).Unit
		local sCF = safeLook(pos + outDir * 1.2, pos + outDir * 6.0)
		local prism = makeGeoPart("CryoPrismShard", Enum.PartType.Wedge, Vector3.new(0.55, 0.85, 2.35), sCF, (i % 2 == 0) and cryoPal.Mid or pal.Core, 0.10, Enum.Material.Glass)
		tweenOutAndDebris(prism, 0.44, {
			CFrame = safeLook(pos + outDir * 8.2, pos + outDir * 12.0) * CFrame.Angles(0.8, 0.6, 0),
			Size = Vector3.new(0.12, 0.18, 0.85),
			Transparency = 1,
		})
	end
	emit3ToneBurst(pos, cryoPal, 18, 1.15, 0.1, 14, 36, 0.42, TEX_SPARK, 180)
	Engine.SpawnDynamicLight(pos, cryoPal, true, false, 0.34)
	Engine.PulseCamera(pos, 0.34, 2.2, dir, isLocal)
end


-- ============================================================================
-- ALL 20 SERVER SKILL ARCHETYPES (1:1 MECHANICAL TRAJECTORY & DELAYED BEATS)
-- ============================================================================
local ARCHETYPE_SOLVERS = {}

-- 1. ChainLightning: Jagged node-to-node Beam arcs strictly following data.ChainNodes
ARCHETYPE_SOLVERS.ChainLightning = function(ctx)
	local nodes = {}
	if type(ctx.Data.ChainNodes) == "table" and #ctx.Data.ChainNodes >= 2 then
		for _, pt in ipairs(ctx.Data.ChainNodes) do
			if typeof(pt) == "Vector3" then
				table.insert(nodes, pt)
			end
		end
	end
	if #nodes < 2 then
		nodes = { ctx.Origin, ctx.EndPos }
	end

	local tier = Engine.GetGraphicsTier()
	local jittersPerHop = (tier == "Smooth") and 2 or 4
	for i = 1, (#nodes - 1) do
		local aPos = nodes[i]
		local bPos = nodes[i + 1]
		local segSpan = bPos - aPos
		local dist = math.max(1, segSpan.Magnitude)
		local dirU = segSpan.Unit
		local rightU = dirU:Cross(Vector3.yAxis)
		if rightU.Magnitude < 0.05 then rightU = Vector3.xAxis else rightU = rightU.Unit end
		local upU = rightU:Cross(dirU).Unit

		local hopDelay = (i - 1) * 0.035
		task.delay(hopDelay, function()
			local holder = makeAnchorNode((aPos + bPos) * 0.5, 0.36)
			local prevAtt = Instance.new("Attachment")
			prevAtt.WorldPosition = aPos
			prevAtt.Parent = holder

			for s = 1, jittersPerHop do
				local frac = s / (jittersPerHop + 1)
				local amp = math.min(2.6, dist * 0.14) * ((s % 2 == 0) and 1 or -1)
				local midP = aPos + segSpan * frac + rightU * amp + upU * (amp * 0.55)
				local curAtt = Instance.new("Attachment")
				curAtt.WorldPosition = midP
				curAtt.Parent = holder

				for pass = 1, 2 do
					local bm = Instance.new("Beam")
					bm.Attachment0 = prevAtt
					bm.Attachment1 = curAtt
					bm.Color = (pass == 1) and ColorSequence.new(ctx.Pal.Core) or ctx.Pal.Seq
					bm.Width0 = (pass == 1) and 0.42 or 1.25
					bm.Width1 = (pass == 1) and 0.42 or 1.25
					bm.LightEmission = 0.96
					bm.LightInfluence = 0
					bm.FaceCamera = true
					bm.Segments = 2
					bm.Parent = holder
					TweenService:Create(bm, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Width0 = 0, Width1 = 0 }):Play()
				end
				prevAtt = curAtt
			end

			local endAtt = Instance.new("Attachment")
			endAtt.WorldPosition = bPos
			endAtt.Parent = holder
			local finalBm = Instance.new("Beam")
			finalBm.Attachment0 = prevAtt
			finalBm.Attachment1 = endAtt
			finalBm.Color = ctx.Pal.Seq
			finalBm.Width0 = 1.15
			finalBm.Width1 = 0.65
			finalBm.LightEmission = 0.95
			finalBm.LightInfluence = 0
			finalBm.FaceCamera = true
			finalBm.Segments = 2
			finalBm.Parent = holder
			TweenService:Create(finalBm, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Width0 = 0, Width1 = 0 }):Play()

			-- Branch sparks + crisp shock ring at each chained target node
			spawnHoopRing(CFrame.new(bPos), ctx.Pal.Core, 1.0, 5.8, 0.16, 0.24, Enum.Material.Neon)
			emit3ToneBurst(bPos, ctx.Pal, 10, 0.85, 0.06, 12, 30, 0.28, TEX_SPARK, 180)
			Engine.SpawnDynamicLight(bPos, ctx.Pal, false, true, 0.22)
		end)
	end
end

-- 2. BlinkDelayedSlash: Instant dash ribbon + suspended spatial cut-line detonating at ImpactDelaySec
ARCHETYPE_SOLVERS.BlinkDelayedSlash = function(ctx)
	local delaySec = math.clamp(tonumber(ctx.Data.ImpactDelaySec) or 0.38, 0.16, 1.25)
	local span = ctx.EndPos - ctx.Origin
	local dist = math.clamp(span.Magnitude, 8, 65)
	local dirU = (span.Magnitude > 0.2) and span.Unit or ctx.Dir
	local finishPos = ctx.Origin + dirU * dist
	local midPos = (ctx.Origin + finishPos) * 0.5

	-- Beat 1 (0ms): Dash ghost-ribbon + taut suspended razor cut-line
	makeRibbonBeam(ctx.Origin, finishPos, ctx.Pal, 2.2, 0.6, 0, 0, delaySec + 0.16, nil, 8)
	local cutLine = makeGeoPart(
		"SuspendedCutLine",
		Enum.PartType.Block,
		Vector3.new(0.16, 0.16, dist),
		safeLook(ctx.Origin, finishPos) * CFrame.new(0, 0, -dist * 0.5),
		ctx.Pal.Core,
		0.02,
		Enum.Material.Neon
	)
	Debris:AddItem(cutLine, delaySec + 0.35)

	-- Beat 2 (ImpactDelaySec): Sheath click -> spatial cross-slash detonation along the line!
	task.delay(delaySec, function()
		if cutLine and cutLine.Parent then
			tweenOutAndDebris(cutLine, 0.22, {
				Size = Vector3.new(1.85, 1.85, dist * 1.04),
				Transparency = 1,
			})
		end
		local cuts = (Engine.GetGraphicsTier() == "Smooth") and 3 or 5
		for i = 1, cuts do
			local p = ctx.Origin:Lerp(finishPos, i / (cuts + 1))
			local crossCF = safeLook(p, p + dirU) * CFrame.Angles(0, 0, math.rad((i % 2 == 0) and 42 or -42))
			local slashBar = makeGeoPart("DelayedCrossCut", Enum.PartType.Block, Vector3.new(0.18, 9.5, 0.28), crossCF, ctx.Pal.Core, 0.04, Enum.Material.Neon)
			tweenOutAndDebris(slashBar, 0.24, { Size = Vector3.new(0.04, 15.5, 0.08), Transparency = 1 })
			emit3ToneBurst(p, ctx.Pal, 8, 0.9, 0.08, 12, 30, 0.28, TEX_SPARK, 160)
		end
		Engine.SpawnDynamicLight(midPos, ctx.Pal, true, false, 0.30)
		Engine.PulseCamera(finishPos, 0.32, 2.0, dirU, ctx.IsLocal)
	end)
end

-- 3. MultiLaneSpikes: 3 diverging lanes of sequential tilted crystalline spires/thorns
ARCHETYPE_SOLVERS.MultiLaneSpikes = function(ctx)
	local tier = Engine.GetGraphicsTier()
	local spikesPerLane = (tier == "Smooth") and 3 or 5
	local range = math.clamp((ctx.EndPos - ctx.Origin).Magnitude, 16, 44)
	local baseCF = safeLook(ctx.Origin, ctx.Origin + ctx.Dir)
	local isCrystal = (ctx.Pal == PALETTES.GlacierIceCore) or (tostring(ctx.Data.Element or "") == "Frost")

	for lane = -1, 1 do
		local yaw = math.rad(lane * 18)
		local laneDir = (baseCF * CFrame.Angles(0, yaw, 0)).LookVector
		for s = 1, spikesPerLane do
			task.delay((s - 1) * 0.045, function()
				local d = 4.0 + ((s - 0.5) / spikesPerLane) * (range - 4.0)
				local p = ctx.Origin + laneDir * d - Vector3.new(0, 1.8, 0)
				local h = 3.8 + s * 0.75
				local sCF = safeLook(p, p + laneDir) * CFrame.Angles(math.rad(62), 0, math.rad(lane * 8))
				local spire = makeGeoPart(
					"LaneSpire",
					Enum.PartType.Wedge,
					Vector3.new(1.15, h * 0.3, 1.45),
					sCF,
					(s % 2 == 0) and ctx.Pal.Core or ctx.Pal.Mid,
					isCrystal and 0.14 or 0.06,
					isCrystal and Enum.Material.Glass or Enum.Material.Neon
				)
				TweenService:Create(spire, TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Size = Vector3.new(1.35, h, 1.75),
					CFrame = sCF * CFrame.new(0, h * 0.35, 0),
				}):Play()
				task.delay(0.38, function()
					if spire and spire.Parent then
						tweenOutAndDebris(spire, 0.28, { Size = Vector3.new(0.2, 0.4, 0.2), Transparency = 1 })
					end
				end)
				Debris:AddItem(spire, 0.75)
			end)
		end
	end
end

-- 4. TravellingWave: Advancing wide crescent wave-blade + twin wake ribbons
ARCHETYPE_SOLVERS.TravellingWave = function(ctx)
	local dist = math.clamp((ctx.EndPos - ctx.Origin).Magnitude, 14, 54)
	local startCF = safeLook(ctx.Origin, ctx.Origin + ctx.Dir)
	local endCF = startCF * CFrame.new(0, 0, -dist)
	local travelDur = 0.34

	spawnCurvedSlashArc(startCF, ctx.Radius * 0.75, 150, 0, 1.85, ctx.Pal, 0.28, 9)
	local crest = makeGeoPart("WaveCrestBlade", Enum.PartType.Wedge, Vector3.new(ctx.Radius * 1.25, 3.4, 2.6), startCF * CFrame.Angles(0, 0, 0), ctx.Pal.Core, 0.10, Enum.Material.Neon)
	local sheath = makeGeoPart("WaveCrestSheath", Enum.PartType.Wedge, Vector3.new(ctx.Radius * 1.45, 4.2, 3.4), startCF, ctx.Pal.Mid, 0.32, Enum.Material.Neon)
	tweenOutAndDebris(crest, travelDur, { CFrame = endCF, Transparency = 1 }, Enum.EasingStyle.Sine)
	tweenOutAndDebris(sheath, travelDur + 0.05, { CFrame = endCF, Transparency = 1 }, Enum.EasingStyle.Sine)
	makeRibbonBeam(startCF:PointToWorldSpace(Vector3.new(-ctx.Radius * 0.5, 0, 0)), endCF:PointToWorldSpace(Vector3.new(-ctx.Radius * 0.5, 0, 0)), ctx.Pal, 1.2, 0.3, 0, 0, 0.38, nil, 10)
	makeRibbonBeam(startCF:PointToWorldSpace(Vector3.new(ctx.Radius * 0.5, 0, 0)), endCF:PointToWorldSpace(Vector3.new(ctx.Radius * 0.5, 0, 0)), ctx.Pal, 1.2, 0.3, 0, 0, 0.38, nil, 10)
end

-- 5. SpreadVolley: Rapid multi-pulse fan of streaking elemental bolts/fists
ARCHETYPE_SOLVERS.SpreadVolley = function(ctx)
	local count = (Engine.GetGraphicsTier() == "Smooth") and 4 or math.clamp(tonumber(ctx.Data.Hits) or 6, 4, 8)
	local baseCF = safeLook(ctx.Origin, ctx.EndPos)
	local dist = math.clamp((ctx.EndPos - ctx.Origin).Magnitude, 14, 48)
	for i = 1, count do
		task.delay((i - 1) * 0.042, function()
			local yaw = math.rad(((i - (count + 1) * 0.5) / count) * 34)
			local pitch = math.rad(((i % 3) - 1) * 5)
			local pStart = baseCF:PointToWorldSpace(Vector3.new(((i % 2 == 0) and 1.4 or -1.4), ((i % 3) - 1) * 0.7, -1.2))
			local shotDir = (baseCF * CFrame.Angles(pitch, yaw, 0)).LookVector
			local pEnd = pStart + shotDir * dist
			makeRibbonBeam(pStart, pEnd, ctx.Pal, 0.85, 0.25, 0, 0, 0.24, nil, 8)
			local bolt = makeGeoPart("VolleyBolt", Enum.PartType.Block, Vector3.new(0.65, 0.65, 3.2), safeLook(pStart, pEnd), ctx.Pal.Core, 0.04, Enum.Material.Neon)
			tweenOutAndDebris(bolt, 0.20, { CFrame = safeLook(pEnd, pEnd + shotDir), Transparency = 1 }, Enum.EasingStyle.Linear)
			emit3ToneBurst(pEnd, ctx.Pal, 5, 0.75, 0.06, 8, 20, 0.22, TEX_SPARK, 150)
		end)
	end
end

-- 6. PiercingBeam: 3-shell core + elemental sheath + helical shock-hoops
ARCHETYPE_SOLVERS.PiercingBeam = function(ctx)
	local span = ctx.EndPos - ctx.Origin
	local len = math.clamp(span.Magnitude, 16, 88)
	local dirU = (span.Magnitude > 0.2) and span.Unit or ctx.Dir
	local pEnd = ctx.Origin + dirU * len
	local midCF = safeLook(ctx.Origin, pEnd) * CFrame.new(0, 0, -len * 0.5) * CFrame.Angles(0, math.pi * 0.5, 0)
	local w = math.clamp(ctx.Radius * 0.28, 1.8, 5.2)

	-- Shell 1 (Hot White Core) + Shell 2 (Elemental Sheath)
	local coreCyl = makeGeoPart("BeamInnerCore", Enum.PartType.Cylinder, Vector3.new(len, w * 0.36, w * 0.36), midCF, ctx.Pal.Core, 0.06, Enum.Material.Neon)
	local midCyl = makeGeoPart("BeamOuterSheath", Enum.PartType.Cylinder, Vector3.new(len, w * 1.15, w * 1.15), midCF, ctx.Pal.Mid, 0.42, Enum.Material.Neon)
	tweenOutAndDebris(coreCyl, 0.42, { Size = Vector3.new(len, 0.08, 0.08), Transparency = 1 })
	tweenOutAndDebris(midCyl, 0.46, { Size = Vector3.new(len, w * 1.85, w * 1.85), Transparency = 1 })

	-- Shell 3: Helical shock ribbons + Mach hoops along beam axis
	makeRibbonBeam(ctx.Origin, pEnd, ctx.Pal, w * 0.9, w * 0.5, 5.5, -5.5, 0.42, nil, 18)
	makeRibbonBeam(ctx.Origin, pEnd, ctx.Pal, w * 0.9, w * 0.5, -5.5, 5.5, 0.42, nil, 18)
	local rings = (Engine.GetGraphicsTier() == "Smooth") and 3 or 5
	for r = 1, rings do
		local rp = ctx.Origin + dirU * (len * (r / (rings + 1)))
		spawnHoopRing(safeLook(rp, rp + dirU) * CFrame.Angles(math.pi * 0.5, 0, 0), (r % 2 == 0) and ctx.Pal.Core or ctx.Pal.Mid, w * 0.8, w * 2.9, 0.20, 0.38, Enum.Material.Neon)
	end
	emit3ToneBurst(pEnd, ctx.Pal, 16, 1.2, 0.1, 14, 34, 0.38, TEX_PLASMA, 180)
end

-- 7. HarmonicSiphonWave: Acoustic chord rings + soul-siphon wisps returning to caster
ARCHETYPE_SOLVERS.HarmonicSiphonWave = function(ctx)
	local rings = (Engine.GetGraphicsTier() == "Smooth") and 3 or 5
	for i = 1, rings do
		task.delay((i - 1) * 0.048, function()
			local p = ctx.Origin:Lerp(ctx.Pos, i / rings)
			spawnHoopRing(safeLook(p, p + ctx.Dir) * CFrame.Angles(math.pi * 0.5, 0, 0), (i % 2 == 0) and ctx.Pal.Core or ctx.Pal.Mid, 2.0, ctx.Radius * 1.15, 0.22, 0.38, Enum.Material.Neon)
		end)
	end
	makeRibbonBeam(ctx.Origin, ctx.Pos, ctx.Pal, 1.4, 0.6, 4.2, -4.2, 0.38, nil, 16)
	spawnSiphonWispsToCaster(ctx.Pos, ctx.ActorChar, ctx.Pal, 4)
end

-- 8. VortexPullCage: Inward-spiraling accretion ribbons + vertical cage ribs
ARCHETYPE_SOLVERS.VortexPullCage = function(ctx)
	local arms = (Engine.GetGraphicsTier() == "Smooth") and 4 or 6
	local center = ctx.Pos
	local coreOrb = makeGeoPart("VortexSingularity", Enum.PartType.Ball, Vector3.new(4.8, 4.8, 4.8), CFrame.new(center), ctx.Pal.Rim, 0.08, Enum.Material.Neon, nil, false)
	local rimHalo = makeGeoPart("VortexRim", Enum.PartType.Ball, Vector3.new(6.2, 6.2, 6.2), CFrame.new(center), ctx.Pal.Mid, 0.45, Enum.Material.Neon, nil, false)
	tweenOutAndDebris(coreOrb, 0.58, { Size = Vector3.new(0.5, 0.5, 0.5), Transparency = 1 })
	tweenOutAndDebris(rimHalo, 0.58, { Size = Vector3.new(ctx.Radius * 1.25, ctx.Radius * 1.25, ctx.Radius * 1.25), Transparency = 1 })

	for i = 1, arms do
		local ang = ((i - 1) / arms) * math.pi * 2
		local outP = center + Vector3.new(math.cos(ang) * ctx.Radius, 1.5 + (i % 2) * 1.5, math.sin(ang) * ctx.Radius)
		makeRibbonBeam(outP, center, ctx.Pal, 1.15, 0.25, 6.5, -3.5, 0.52, nil, 16)
		local rib = makeGeoPart("CageRib", Enum.PartType.Block, Vector3.new(0.28, 6.5, 0.28), safeLook(outP, center) * CFrame.Angles(math.rad(16), 0, 0), ctx.Pal.Core, 0.14, Enum.Material.Neon)
		tweenOutAndDebris(rib, 0.50, { CFrame = CFrame.new(center), Size = Vector3.new(0.08, 1.2, 0.08), Transparency = 1 })
	end
end

-- 9. SandCoffinImplode: Encasing prism swirl -> delayed implosion burst at ImpactDelaySec
ARCHETYPE_SOLVERS.SandCoffinImplode = function(ctx)
	local delaySec = math.clamp(tonumber(ctx.Data.ImpactDelaySec) or 0.42, 0.18, 1.2)
	local center = ctx.Pos
	local shell = makeGeoPart("CoffinPrismShell", Enum.PartType.Block, Vector3.new(ctx.Radius * 0.9, ctx.Radius * 1.1, ctx.Radius * 0.9), CFrame.new(center) * CFrame.Angles(0.4, 0.6, 0.2), ctx.Pal.Mid, 0.28, Enum.Material.Neon)
	TweenService:Create(shell, TweenInfo.new(delaySec, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
		Size = Vector3.new(2.2, 2.8, 2.2),
		CFrame = CFrame.new(center) * CFrame.Angles(1.8, 2.4, 0.8),
	}):Play()
	Debris:AddItem(shell, delaySec + 0.30)

	for b = 1, 3 do
		spawnHoopRing(CFrame.new(center + Vector3.new(0, (b - 2) * 2.2, 0)), ctx.Pal.Core, ctx.Radius * 1.1, 2.0, 0.22, delaySec, Enum.Material.Neon)
	end

	task.delay(delaySec, function()
		if shell and shell.Parent then
			shell.Transparency = 1
		end
		spawnHoopRing(CFrame.new(center), ctx.Pal.Core, 1.8, ctx.Radius * 1.55, 0.30, 0.36, Enum.Material.Neon)
		emit3ToneBurst(center, ctx.Pal, 20, 1.25, 0.1, 16, 38, 0.42, TEX_SPARK, 180)
		Engine.SpawnDynamicLight(center, ctx.Pal, true, false, 0.34)
		Engine.PulseCamera(center, 0.34, 2.0, ctx.Dir, ctx.IsLocal)
	end)
end

-- 10. DragRushSlam: Forward plow wake ribbons + grab crush impact
ARCHETYPE_SOLVERS.DragRushSlam = function(ctx)
	local baseCF = safeLook(ctx.Origin, ctx.Pos)
	makeRibbonBeam(baseCF:PointToWorldSpace(Vector3.new(-1.8, -1.2, 0)), ctx.Pos + Vector3.new(-1.2, -0.8, 0), ctx.Pal, 1.35, 0.45, 0, 0, 0.34, nil, 10)
	makeRibbonBeam(baseCF:PointToWorldSpace(Vector3.new(1.8, -1.2, 0)), ctx.Pos + Vector3.new(1.2, -0.8, 0), ctx.Pal, 1.35, 0.45, 0, 0, 0.34, nil, 10)
	spawnThrustCone(ctx.Origin, ctx.Dir, math.clamp((ctx.Pos - ctx.Origin).Magnitude, 8, 32), 2.8, ctx.Pal, 0.26)
	spawnHoopRing(CFrame.new(ctx.Pos), ctx.Pal.Core, 2.0, ctx.Radius * 1.35, 0.26, 0.36, Enum.Material.Neon)
	emit3ToneBurst(ctx.Pos, ctx.Pal, 16, 1.1, 0.1, 12, 32, 0.38, TEX_PLASMA, 170)
end

-- 11. PoleVaultSlam: Rising helical wind spiral -> arched leap -> delayed crater slam
ARCHETYPE_SOLVERS.PoleVaultSlam = function(ctx)
	local delaySec = math.clamp(tonumber(ctx.Data.ImpactDelaySec) or 0.26, 0.12, 0.85)
	-- Beat 1: Rising helical pole-vault wind rings at origin + overhead leap arc
	for h = 1, 3 do
		spawnHoopRing(CFrame.new(ctx.Origin + Vector3.new(0, h * 2.2, 0)), ctx.Pal.Mid, 2.2, 7.2, 0.16, 0.28, Enum.Material.Neon)
	end
	local apex = ((ctx.Origin + ctx.Pos) * 0.5) + Vector3.new(0, 9.5, 0)
	makeRibbonBeam(ctx.Origin, apex, ctx.Pal, 1.25, 0.85, 0, 3.5, delaySec + 0.18, nil, 12)
	makeRibbonBeam(apex, ctx.Pos, ctx.Pal, 1.25, 0.55, 3.5, 0, delaySec + 0.22, nil, 12)

	-- Beat 2: Vaulting lance touchdown shockwave at ImpactDelaySec
	task.delay(delaySec, function()
		spawnThrustCone(ctx.Pos + Vector3.new(0, 7.5, 0), Vector3.new(0, -1, 0), 9.5, 3.4, ctx.Pal, 0.28)
		Engine.SpawnGroundOrAerialImpact(ctx.Pos, Vector3.new(0, -1, 0), ctx.Radius, ctx.Pal, true, ctx.Data.GroundMaterial, ctx.Data.GroundColor, ctx.ActorChar)
		Engine.SpawnDynamicLight(ctx.Pos, ctx.Pal, true, false, 0.34)
		Engine.PulseCamera(ctx.Pos, 0.32, 1.8, Vector3.new(0, -1, 0), ctx.IsLocal)
	end)
end

-- 12. ZigZagMirrorKick: Glowing prism light-mirrors at bounce vertices + zig-zag beams
ARCHETYPE_SOLVERS.ZigZagMirrorKick = function(ctx)
	local pts = {}
	if type(ctx.Data.ChainNodes) == "table" and #ctx.Data.ChainNodes >= 2 then
		for _, p in ipairs(ctx.Data.ChainNodes) do
			if typeof(p) == "Vector3" then table.insert(pts, p) end
		end
	end
	if #pts < 3 then
		local baseCF = safeLook(ctx.Origin, ctx.EndPos)
		local dist = math.clamp((ctx.EndPos - ctx.Origin).Magnitude, 18, 46)
		pts = {
			ctx.Origin,
			baseCF:PointToWorldSpace(Vector3.new(-5.2, 2.2, -dist * 0.28)),
			baseCF:PointToWorldSpace(Vector3.new(5.2, 3.6, -dist * 0.56)),
			baseCF:PointToWorldSpace(Vector3.new(-4.0, 1.8, -dist * 0.82)),
			ctx.Origin + ctx.Dir * dist,
		}
	end

	for i = 1, (#pts - 1) do
		task.delay((i - 1) * 0.04, function()
			local a = pts[i]
			local b = pts[i + 1]
			makeRibbonBeam(a, b, ctx.Pal, 1.05, 0.85, 0, 0, 0.32, nil, 4)
			-- Diamond prism light-mirror at vertex
			local mCF = safeLook(a, b) * CFrame.Angles(0, 0, math.pi * 0.25)
			local mirror = makeGeoPart("PrismLightMirror", Enum.PartType.Block, Vector3.new(3.4, 3.4, 0.16), mCF, ctx.Pal.Core, 0.16, Enum.Material.Glass)
			local rim = makeGeoPart("PrismMirrorRim", Enum.PartType.Block, Vector3.new(3.9, 3.9, 0.08), mCF, ctx.Pal.Mid, 0.22, Enum.Material.Neon)
			tweenOutAndDebris(mirror, 0.36, { Size = Vector3.new(0.4, 0.4, 0.06), Transparency = 1 })
			tweenOutAndDebris(rim, 0.36, { Size = Vector3.new(4.8, 4.8, 0.04), Transparency = 1 })
			emit3ToneBurst(b, ctx.Pal, 6, 0.75, 0.05, 10, 24, 0.24, TEX_SPARK, 160)
		end)
	end
end

-- 13. RiftPhaseEscape: Dimensional tear slit at origin + exit warp aperture
ARCHETYPE_SOLVERS.RiftPhaseEscape = function(ctx)
	local function spawnRiftSlit(p, scale)
		local cf = safeLook(p, p + ctx.Dir)
		local slit = makeGeoPart("DimensionalRiftSlit", Enum.PartType.Block, Vector3.new(0.35, 7.5 * scale, 0.35), cf, ctx.Pal.Core, 0.02, Enum.Material.Neon)
		local halo = makeGeoPart("DimensionalRiftHalo", Enum.PartType.Cylinder, Vector3.new(0.18, 6.8 * scale, 3.6 * scale), cf * CFrame.Angles(0, math.pi * 0.5, 0), ctx.Pal.Rim, 0.18, Enum.Material.Neon)
		tweenOutAndDebris(slit, 0.45, { Size = Vector3.new(3.2 * scale, 0.4, 0.2), Transparency = 1 })
		tweenOutAndDebris(halo, 0.48, { Size = Vector3.new(0.06, 0.6, 0.6), Transparency = 1 })
		emit3ToneBurst(p, ctx.Pal, 12, 0.95, 0.08, 10, 26, 0.34, TEX_SPARK, 180)
	end
	spawnRiftSlit(ctx.Origin, 1.0)
	if (ctx.Pos - ctx.Origin).Magnitude > 3.5 then
		spawnRiftSlit(ctx.Pos, 1.15)
		makeRibbonBeam(ctx.Origin, ctx.Pos, ctx.Pal, 1.6, 0.4, 0, 0, 0.28, nil, 8)
	end
end

-- 14. SkyfallSphere: Overhead storm-cloud/corona + giant multi-shell sphere timed to ImpactDelaySec
ARCHETYPE_SOLVERS.SkyfallSphere = function(ctx)
	local delaySec = math.clamp(tonumber(ctx.Data.ImpactDelaySec) or 0.52, 0.22, 1.4)
	local skyPos = ctx.Pos + Vector3.new(0, 34, 0)
	local orbR = math.clamp(ctx.Radius * 0.68, 8, 20)

	-- Overhead storm/solar corona ring
	spawnHoopRing(CFrame.new(skyPos), ctx.Pal.Mid, orbR * 0.6, orbR * 2.2, 0.35, delaySec + 0.25, Enum.Material.Neon)

	-- Multi-shell descending sphere (Core + Mid Plasma + Rim Equatorial Ring — 3-tone depth without whiteout)
	local inner = makeGeoPart("SkyfallCore", Enum.PartType.Ball, Vector3.new(orbR * 0.42, orbR * 0.42, orbR * 0.42), CFrame.new(skyPos), ctx.Pal.Core, 0.06, Enum.Material.Neon, nil, false)
	local outer = makeGeoPart("SkyfallShell", Enum.PartType.Ball, Vector3.new(orbR, orbR, orbR), CFrame.new(skyPos), ctx.Pal.Mid, 0.40, Enum.Material.Neon, nil, false)
	local eqRing = makeGeoPart("SkyfallRimRing", Enum.PartType.Cylinder, Vector3.new(0.28, orbR * 1.38, orbR * 1.38), CFrame.new(skyPos) * CFrame.Angles(0.35, 0, math.pi * 0.5), ctx.Pal.Rim, 0.14, Enum.Material.Neon, nil, false)
	TweenService:Create(inner, TweenInfo.new(delaySec, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = CFrame.new(ctx.Pos) }):Play()
	TweenService:Create(outer, TweenInfo.new(delaySec, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = CFrame.new(ctx.Pos) }):Play()
	TweenService:Create(eqRing, TweenInfo.new(delaySec, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = CFrame.new(ctx.Pos) * CFrame.Angles(-0.35, math.pi, math.pi * 0.5) }):Play()
	Debris:AddItem(inner, delaySec + 0.40)
	Debris:AddItem(outer, delaySec + 0.45)
	Debris:AddItem(eqRing, delaySec + 0.40)

	task.delay(delaySec, function()
		if inner and inner.Parent then
			tweenOutAndDebris(inner, 0.32, { Size = Vector3.new(ctx.Radius * 1.6, ctx.Radius * 1.6, ctx.Radius * 1.6), Transparency = 1 })
		end
		if outer and outer.Parent then
			tweenOutAndDebris(outer, 0.36, { Size = Vector3.new(ctx.Radius * 2.1, ctx.Radius * 2.1, ctx.Radius * 2.1), Transparency = 1 })
		end
		Engine.SpawnGroundOrAerialImpact(ctx.Pos, Vector3.new(0, -1, 0), ctx.Radius, ctx.Pal, ctx.ImpactGround, ctx.Data.GroundMaterial, ctx.Data.GroundColor, ctx.ActorChar)
		Engine.SpawnDynamicLight(ctx.Pos, ctx.Pal, true, false, 0.46)
		Engine.PulseCamera(ctx.Pos, 0.46, 3.0, Vector3.new(0, -1, 0), ctx.IsLocal)
	end)
end

-- 15. MeteorShower: Overhead rift + meteors streaking into EXACT data.ImpactPoints
ARCHETYPE_SOLVERS.MeteorShower = function(ctx)
	local pts = {}
	if type(ctx.Data.ImpactPoints) == "table" and #ctx.Data.ImpactPoints >= 1 then
		for _, p in ipairs(ctx.Data.ImpactPoints) do
			if typeof(p) == "Vector3" then table.insert(pts, p) end
		end
	end
	if #pts == 0 then
		for i = 1, 4 do
			local ang = ((i - 1) / 4) * math.pi * 2
			table.insert(pts, ctx.Pos + Vector3.new(math.cos(ang) * (ctx.Radius * 0.4), 0, math.sin(ang) * (ctx.Radius * 0.4)))
		end
	end

	local baseDelay = math.clamp(tonumber(ctx.Data.ImpactDelaySec) or 0.32, 0.16, 0.9)
	spawnHoopRing(CFrame.new(ctx.Pos + Vector3.new(0, 36, 0)), ctx.Pal.Rim, 6.0, ctx.Radius * 1.8, 0.34, baseDelay + (#pts * 0.09) + 0.25, Enum.Material.Neon)

	for idx, targetPt in ipairs(pts) do
		local launchWait = (idx - 1) * 0.085
		task.delay(launchWait, function()
			local spawnPt = targetPt + Vector3.new(-12 + (idx % 3) * 4, 36, -10)
			local rock = makeGeoPart("MeteorCore", Enum.PartType.Block, Vector3.new(3.8, 3.8, 3.8), CFrame.new(spawnPt) * CFrame.Angles(0.5, 0.8, 0.3), ctx.Pal.Rim, 0.02, Enum.Material.Basalt)
			local corona = makeGeoPart("MeteorCorona", Enum.PartType.Ball, Vector3.new(5.2, 5.2, 5.2), CFrame.new(spawnPt), ctx.Pal.Mid, 0.26, Enum.Material.Neon, nil, false)
			makeRibbonBeam(spawnPt, targetPt, ctx.Pal, 2.2, 0.6, 0, 0, baseDelay + 0.16, nil, 8)
			TweenService:Create(rock, TweenInfo.new(baseDelay, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				CFrame = CFrame.new(targetPt) * CFrame.Angles(2.4, 1.9, 1.2),
			}):Play()
			TweenService:Create(corona, TweenInfo.new(baseDelay, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				CFrame = CFrame.new(targetPt),
			}):Play()
			Debris:AddItem(rock, baseDelay + 0.30)
			Debris:AddItem(corona, baseDelay + 0.30)

			task.delay(baseDelay, function()
				if rock and rock.Parent then rock.Transparency = 1 end
				if corona and corona.Parent then
					tweenOutAndDebris(corona, 0.26, { Size = Vector3.new(12, 12, 12), Transparency = 1 })
				end
				Engine.SpawnGroundOrAerialImpact(targetPt, Vector3.new(0, -1, 0), math.max(7, ctx.Radius * 0.55), ctx.Pal, ctx.ImpactGround, ctx.Data.GroundMaterial, ctx.Data.GroundColor, ctx.ActorChar)
				Engine.SpawnDynamicLight(targetPt, ctx.Pal, (idx == 1), false, 0.30)
				if idx == 1 or idx == #pts then
					Engine.PulseCamera(targetPt, 0.32, 1.8, Vector3.new(0, -1, 0), ctx.IsLocal)
				end
			end)
		end)
	end
end

-- 16. SkybeamPillars: Heaven-to-earth cylindrical pillars at exact ImpactPoints
ARCHETYPE_SOLVERS.SkybeamPillars = function(ctx)
	local pts = {}
	if type(ctx.Data.ImpactPoints) == "table" and #ctx.Data.ImpactPoints >= 1 then
		for _, p in ipairs(ctx.Data.ImpactPoints) do
			if typeof(p) == "Vector3" then table.insert(pts, p) end
		end
	end
	if #pts == 0 then
		pts = { ctx.Pos }
	end

	local height = 44
	for idx, pt in ipairs(pts) do
		task.delay((idx - 1) * 0.065, function()
			local colCF = CFrame.new(pt + Vector3.new(0, height * 0.5, 0)) * CFrame.Angles(0, 0, math.pi * 0.5)
			local w = math.clamp(ctx.Radius * 0.36, 3.2, 8.5)
			local inner = makeGeoPart("SkybeamInner", Enum.PartType.Cylinder, Vector3.new(height, w * 0.55, w * 0.55), colCF, ctx.Pal.Core, 0.02, Enum.Material.Neon)
			local outer = makeGeoPart("SkybeamOuter", Enum.PartType.Cylinder, Vector3.new(height, w, w), colCF, ctx.Pal.Mid, 0.32, Enum.Material.Neon)
			tweenOutAndDebris(inner, 0.42, { Size = Vector3.new(height, 0.1, 0.1), Transparency = 1 })
			tweenOutAndDebris(outer, 0.46, { Size = Vector3.new(height, w * 1.65, w * 1.65), Transparency = 1 })
			spawnHoopRing(CFrame.new(pt), ctx.Pal.Core, 1.8, w * 2.4, 0.24, 0.38, Enum.Material.Neon)
			emit3ToneBurst(pt, ctx.Pal, 12, 1.0, 0.08, 10, 28, 0.34, TEX_SPARK, 170)
		end)
	end
end

-- 17. GroundMonolithShatter: Erupting tectonic monolith pillars shattering outward
ARCHETYPE_SOLVERS.GroundMonolithShatter = function(ctx)
	local count = (Engine.GetGraphicsTier() == "Smooth") and 4 or 6
	for i = 1, count do
		local ang = ((i - 1) / count) * math.pi * 2
		local r = ctx.Radius * 0.52
		local p = ctx.Pos + Vector3.new(math.cos(ang) * r, -2.2, math.sin(ang) * r)
		local mCF = safeLook(p, ctx.Pos) * CFrame.Angles(math.rad(-18), 0, math.rad((i % 2 == 0) and 10 or -10))
		local mono = makeGeoPart("TectonicMonolith", Enum.PartType.Block, Vector3.new(2.4, 6.8, 1.8), mCF, (i % 2 == 0) and ctx.Pal.Rim or ctx.Pal.Mid, 0.04, (i % 2 == 0) and Enum.Material.Slate or Enum.Material.Neon)
		TweenService:Create(mono, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			CFrame = mCF * CFrame.new(0, 3.6, 0),
		}):Play()
		task.delay(0.26, function()
			if mono and mono.Parent then
				emit3ToneBurst(mono.Position, ctx.Pal, 6, 0.85, 0.08, 10, 24, 0.28, TEX_SPARK, 180)
				tweenOutAndDebris(mono, 0.28, {
					CFrame = mCF * CFrame.new(0, 4.8, -2.5) * CFrame.Angles(0.5, 0, 0),
					Size = Vector3.new(0.4, 1.2, 0.4),
					Transparency = 1,
				})
			end
		end)
		Debris:AddItem(mono, 0.65)
	end
end

-- 18. TransformToggle: Ascension pillar + stacked sovereign/titan halo rings
ARCHETYPE_SOLVERS.TransformToggle = function(ctx)
	local h = 36
	local colCF = CFrame.new(ctx.Pos + Vector3.new(0, h * 0.5 - 2, 0)) * CFrame.Angles(0, 0, math.pi * 0.5)
	local pillar = makeGeoPart("AscensionPillar", Enum.PartType.Cylinder, Vector3.new(h, 5.5, 5.5), colCF, ctx.Pal.Core, 0.12, Enum.Material.Neon)
	tweenOutAndDebris(pillar, 0.52, { Size = Vector3.new(h, 14.5, 14.5), Transparency = 1 })
	for r = 1, 3 do
		spawnHoopRing(CFrame.new(ctx.Pos + Vector3.new(0, (r - 1) * 3.2, 0)), (r == 2) and ctx.Pal.Core or ctx.Pal.Mid, 3.0, ctx.Radius * (1.1 + r * 0.2), 0.26, 0.48, Enum.Material.Neon)
	end
	emit3ToneBurst(ctx.Pos, ctx.Pal, 22, 1.2, 0.1, 14, 36, 0.46, TEX_SPARK, 180)
end

-- 19. PortalWorldGate: Upright spinning twin-ring dimensional stargate aperture
ARCHETYPE_SOLVERS.PortalWorldGate = function(ctx)
	local gatePos = ctx.EndPos
	local gateCF = safeLook(gatePos, gatePos + ctx.Dir) * CFrame.new(0, 3.5, 0)
	local outerRing = makeGeoPart("StargateOuter", Enum.PartType.Cylinder, Vector3.new(0.35, 13.5, 13.5), gateCF * CFrame.Angles(0, math.pi * 0.5, 0), ctx.Pal.Mid, 0.08, Enum.Material.Neon)
	local innerAperture = makeGeoPart("StargateAperture", Enum.PartType.Cylinder, Vector3.new(0.16, 11.2, 11.2), gateCF * CFrame.Angles(0, math.pi * 0.5, 0), ctx.Pal.Rim, 0.34, Enum.Material.Glass)
	tweenOutAndDebris(outerRing, 0.85, { Size = Vector3.new(0.10, 15.5, 15.5), Transparency = 1 })
	tweenOutAndDebris(innerAperture, 0.85, { Size = Vector3.new(0.06, 0.8, 0.8), Transparency = 1 })
	if (gatePos - ctx.Origin).Magnitude > 4 then
		makeRibbonBeam(ctx.Origin, gatePos + Vector3.new(0, 2, 0), ctx.Pal, 1.8, 0.8, 0, 0, 0.42, nil, 10)
	end
	emit3ToneBurst(gatePos + Vector3.new(0, 3.5, 0), ctx.Pal, 16, 1.0, 0.1, 10, 26, 0.44, TEX_SPARK, 180)
end

-- 20. MobilityDashHit: Sonic boom entry cone + aerodynamic wingtip slipstream ribbons
ARCHETYPE_SOLVERS.MobilityDashHit = function(ctx)
	local baseCF = safeLook(ctx.Origin, ctx.EndPos)
	spawnHoopRing(baseCF * CFrame.Angles(math.pi * 0.5, 0, 0), ctx.Pal.Core, 1.6, 8.2, 0.20, 0.30, Enum.Material.Neon)
	if ctx.Data.IsTrueFlight == true then
		emit3ToneBurst(ctx.Origin, ctx.Pal, 10, 0.9, 0.1, 8, 20, 0.30, TEX_SMOKE, 160)
		return
	end
	spawnThrustCone(ctx.Origin, ctx.Dir, math.clamp((ctx.EndPos - ctx.Origin).Magnitude, 10, 36), 2.4, ctx.Pal, 0.26)
	makeRibbonBeam(baseCF:PointToWorldSpace(Vector3.new(-1.4, 0, 0)), ctx.EndPos + Vector3.new(-0.6, 0, 0), ctx.Pal, 0.95, 0.2, 0, 0, 0.30, nil, 10)
	makeRibbonBeam(baseCF:PointToWorldSpace(Vector3.new(1.4, 0, 0)), ctx.EndPos + Vector3.new(0.6, 0, 0), ctx.Pal, 0.95, 0.2, 0, 0, 0.30, nil, 10)
end

-- ============================================================================
-- LIFECYCLE BINDINGS (RULE 4 & RULE 5D CLEANUP) + CENTRAL DISPATCHER
-- ============================================================================
local function bindCharacterCleanup(ch)
	if not ch then return end
	local hum = ch:FindFirstChildOfClass("Humanoid")
	if hum then
		table.insert(LifecycleConns, hum.Died:Connect(function()
			Engine.ResetUltimateImpactState()
		end))
	end
end

function Engine.Init(ctx)
	if Initialized then
		return Engine
	end
	Initialized = true
	if type(ctx) == "table" and ctx.Player then
		LocalPlayer = ctx.Player
	end
	local lp = LocalPlayer or Players.LocalPlayer
	if lp then
		table.insert(LifecycleConns, lp:GetAttributeChangedSignal("GraphicsTier"):Connect(function()
			local t = normalizeTierName(lp:GetAttribute("GraphicsTier"))
			if t then
				local low = (t == "Smooth")
				if lp:GetAttribute("LowFXMode") ~= low then
					lp:SetAttribute("LowFXMode", low)
				end
				if Workspace:GetAttribute("LowFXMode") ~= low then
					Workspace:SetAttribute("LowFXMode", low)
				end
				if Workspace:GetAttribute("GraphicsTier") ~= t then
					Workspace:SetAttribute("GraphicsTier", t)
				end
			end
		end))
		table.insert(LifecycleConns, lp:GetAttributeChangedSignal("ActiveSlot"):Connect(function()
			Engine.ResetUltimateImpactState()
		end))
		table.insert(LifecycleConns, lp.CharacterRemoving:Connect(function()
			Engine.ResetUltimateImpactState()
		end))
		table.insert(LifecycleConns, lp.CharacterAdded:Connect(bindCharacterCleanup))
		if lp.Character then
			bindCharacterCleanup(lp.Character)
		end
	end
	return Engine
end

local function checkAndMarkDedup(key, windowSec)
	local now = os.clock()
	local prev = RecentCastDedup[key]
	if prev and (now - prev) < windowSec then
		return true
	end
	RecentCastDedup[key] = now
	return false
end

function Engine.Dispatch(action, pos, actorChar, data, isLocal)
	if type(data) ~= "table" then
		return false
	end
	local act = tostring(action or data.Action or data.action or data.skillId or "")
	local kind = tostring(data.Kind or data.kind or "")
	local pal = Engine.ResolvePalette(data)
	local actorKey = isLocal and "LP" or tostring(data.Actor or data.actor or (actorChar and actorChar.Name) or "R")

	-- 1. 0ms Local Beat-1 Pre-Cast (coil ring + hand gather ONLY; server CombatFX spawns authoritative trajectory)
	if data.IsLocalPreCast == true or act == "LocalPreCast" then
		Engine.SpawnLocalPreCast(pos, actorChar, data, pal)
		return true
	end

	-- 2. Elemental Synergy (CryoShatter) & WallSlam
	if kind == "ElementalSynergy" or kind == "WallSlam" or kind == "CryoShatter" or act == "WallSlam" or act == "CryoShatter" then
		local sub = tostring(data.SubKind or ((kind == "WallSlam" or act == "WallSlam") and "WallSlam") or "CryoShatter")
		if checkAndMarkDedup("SYN:" .. actorKey .. ":" .. sub, 0.12) then
			return true
		end
		Engine.SpawnSynergyVFX(sub, pos, data.Direction, pal, actorChar, isLocal)
		return true
	end

	-- 3. Standalone Persistent HazardZone packet
	if kind == "HazardZone" then
		Engine.SpawnHazardZoneVFX(pos, data.Radius or 12, data.HazardDuration or data.Duration or 3.5, data.HazardKind or "MagmaPool", pal, actorChar)
		return true
	end

	-- Determine MoveKey & M1 vs Skill classification
	local moveKey = string.upper(tostring(data.MoveKey or data.key or ""))
	if moveKey == "" then
		local tail = act:match("_([ZXCVF])$") or act:match("^Skill([ZXCVF])$")
		if tail then moveKey = tail end
	end

	local isStyleM1 = (kind == "StyleMove") and (moveKey == "M1" or tostring(data.MoveType or "") == "Kata")
	local isM1 = isStyleM1
		or (moveKey == "" and (kind == "Swing" or kind == "GunShot" or kind == "ChargedSlash" or kind == "M1Hit" or act == "Attack" or act == "Heavy"))

	if isM1 then
		local step = ((math.max(1, math.floor(tonumber(data.Combo or data.ComboStep) or 1)) - 1) % 4) + 1
		-- Prevent double-spawning between 0ms IsLocalM1, Server CombatFX, and Server CombatEvent!
		if checkAndMarkDedup("M1:" .. actorKey .. ":" .. tostring(step), 0.24) then
			return true
		end
		local endP = (typeof(data.EndPos) == "Vector3" and data.EndPos) or (typeof(data.TargetPos) == "Vector3" and data.TargetPos) or nil
		Engine.SpawnM1VFX(pos, endP, data.Direction, actorChar, data, pal, isLocal)
		return true
	end

	-- 4. Resolve Skill Archetype (authoritative CombatFX packet OR shared SkybreakSkillBlueprints lookup)
	local slot = tonumber(data.Slot or data.slot or (actorChar and actorChar:GetAttribute("ActiveSlot")) or (isLocal and LocalPlayer and LocalPlayer:GetAttribute("ActiveSlot"))) or 2
	local arch = tostring(data.Archetype or "")
	local bpSpec = nil
	if arch == "" and (moveKey == "Z" or moveKey == "X" or moveKey == "C" or moveKey == "V" or moveKey == "F") then
		local bp = getBlueprints()
		if bp and type(bp.GetSkillBlueprint) == "function" then
			local itemId = tostring(data.ItemId or data.ActiveId or data.FruitId or data.StyleId or "")
			if itemId == "" and actorChar then
				itemId = (slot == 1 and tostring(actorChar:GetAttribute("FightingStyle") or ""))
					or (slot == 2 and tostring(actorChar:GetAttribute("EquippedFruit") or ""))
					or (slot == 3 and tostring(actorChar:GetAttribute("EquippedWeapon") or ""))
					or tostring(actorChar:GetAttribute("EquippedGun") or "")
			end
			local dTier = tonumber(data.DragonFormTier or (actorChar and actorChar:GetAttribute("DragonFormTier"))) or 0
			local awk = (data.Awakened == true) or (actorChar and actorChar:GetAttribute("FruitAwakened") == true)
			local ok, spec = pcall(bp.GetSkillBlueprint, slot, itemId, moveKey, { Awakened = awk, DragonFormTier = dTier }, dTier)
			if ok and type(spec) == "table" then
				bpSpec = spec
				arch = tostring(spec.Archetype or "")
			end
		end
	end

	local solver = ARCHETYPE_SOLVERS[arch]
	if not solver then
		return false
	end

	-- Deduplicate dual server broadcast (CombatFX + CombatEvent fired 1ms apart for the same cast)
	local dedupTag = "SK:" .. actorKey .. ":" .. tostring(slot) .. ":" .. (moveKey ~= "" and moveKey or arch)
	if checkAndMarkDedup(dedupTag, 0.20) then
		return true
	end

	if bpSpec and not data.Element and bpSpec.Element then
		data.Element = bpSpec.Element
		pal = Engine.ResolvePalette(data)
	end

	local root = actorChar and actorChar:FindFirstChild("HumanoidRootPart")
	local origin = (typeof(data.Origin) == "Vector3" and data.Origin)
		or (typeof(data.StartPos) == "Vector3" and data.StartPos)
		or (root and root.Position)
		or pos
	local endPos = (typeof(data.EndPos) == "Vector3" and data.EndPos)
		or (typeof(data.TargetPos) == "Vector3" and data.TargetPos)
		or pos
	local dir = (typeof(data.Direction) == "Vector3" and data.Direction.Magnitude > 0.05 and data.Direction.Unit)
		or (((endPos - origin).Magnitude > 0.25) and (endPos - origin).Unit)
		or (root and root.CFrame.LookVector)
		or Vector3.new(0, 0, -1)
	if (endPos - origin).Magnitude < 0.5 then
		local rng = tonumber(data.Range or (bpSpec and bpSpec.Range)) or 26
		endPos = origin + dir * rng
	end

	local radius = math.clamp(tonumber(data.Radius or (bpSpec and bpSpec.Radius)) or 13, 5, 42)
	local impactGround = (data.ImpactGround == true) or (data.ImpactGround == nil and bpSpec ~= nil and bpSpec.ImpactGround == true)
	local isUlt = (data.IsUltimate == true) or (data.IsUltimate == nil and bpSpec ~= nil and bpSpec.IsUltimate == true)
	local isMajor = isUlt or (moveKey == "C") or (moveKey == "V")
	local delaySec = tonumber(data.ImpactDelaySec or (bpSpec and bpSpec.ImpactDelaySec)) or 0

	-- Layer 2: Execute 1:1 Mechanical Archetype Solver
	solver({
		Data = data,
		Pal = pal,
		Origin = origin,
		Pos = pos,
		EndPos = endPos,
		Dir = dir,
		Radius = radius,
		ImpactGround = impactGround,
		IsUltimate = isUlt,
		ActorChar = actorChar,
		IsLocal = isLocal,
	})

	-- Layer 3: Logical Raycast-Gated Ground Destruction vs Aerial Sonic Rings (skip if solver handles delayed touchdown)
	if arch ~= "SkyfallSphere" and arch ~= "MeteorShower" and arch ~= "PoleVaultSlam" and not (arch == "MobilityDashHit" and data.IsTrueFlight == true) then
		local impactFn = function()
			Engine.SpawnGroundOrAerialImpact(pos, dir, radius, pal, impactGround, data.GroundMaterial, data.GroundColor, actorChar)
		end
		if delaySec > 0.08 then
			task.delay(delaySec, impactFn)
		else
			impactFn()
		end
	end

	-- Layer 4: Future Dynamic PointLight + Token-Guarded 35ms Ultimate Impact Frame & Sky-Tint
	Engine.SpawnDynamicLight(pos, pal, isMajor, false, isUlt and 0.48 or 0.34)
	if isUlt then
		Engine.TriggerUltimateImpactAndSkyTint(pos, pal, isLocal)
	end

	-- Layer 5: Cast-Snap Camera Choreography
	Engine.PulseCamera(origin, isUlt and 0.38 or (isMajor and 0.26 or 0.18), isUlt and 2.6 or (isMajor and 1.4 or 0.7), dir, isLocal)

	-- Persistent Hazard Zone when skill carries HazardKind
	local hazKind = data.HazardKind or (bpSpec and bpSpec.HazardKind)
	local hazDur = tonumber(data.HazardDuration or (bpSpec and bpSpec.HazardDuration)) or 0
	if type(hazKind) == "string" and hazKind ~= "" and hazDur > 0 then
		Engine.SpawnHazardZoneVFX(pos, radius, hazDur, hazKind, pal, actorChar)
	end

	return true
end

return Engine
