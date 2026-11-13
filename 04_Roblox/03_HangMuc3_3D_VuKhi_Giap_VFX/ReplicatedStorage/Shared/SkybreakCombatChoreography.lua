-- SkybreakCombatChoreography.lua
-- Token-Guarded 4-Beat Full-Body R15 Procedural Pose Choreography Engine
-- Location: ReplicatedStorage/Shared/SkybreakCombatChoreography.lua
-- Animates all 15 R15 joints (Root, Waist, Neck, Shoulders, Elbows, Wrists, Hips, Knees, Ankles)
-- plus 3D RightWeaponDeltaCF & LeftWeaponDeltaCF across Spear (Mua Giao), Katana, Greatsword,
-- DualBlades, Scythe, 8 Martial Styles (Punch / Pure Leg-Kata / Claw), 12 Aether Cores, and 5 Gun Archetypes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Choreo = {}

local JOINT_ROLES = {
	"Root",
	"Waist",
	"Neck",
	"RightShoulder",
	"RightElbow",
	"RightWrist",
	"LeftShoulder",
	"LeftElbow",
	"LeftWrist",
	"RightHip",
	"RightKnee",
	"RightAnkle",
	"LeftHip",
	"LeftKnee",
	"LeftAnkle",
}

local SharedBlueprints = nil
local LastBlueprintCheckAt = -10

local function getBlueprints()
	if SharedBlueprints then
		return SharedBlueprints
	end
	local now = os.clock()
	if (now - LastBlueprintCheckAt) < 1.0 then
		return nil
	end
	LastBlueprintCheckAt = now
	local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
	if sharedFolder then
		local bpMod = sharedFolder:FindFirstChild("SkybreakSkillBlueprints")
		if bpMod and bpMod:IsA("ModuleScript") then
			local ok, res = pcall(require, bpMod)
			if ok and type(res) == "table" then
				SharedBlueprints = res
				return SharedBlueprints
			end
		end
		local cdMod = sharedFolder:FindFirstChild("SkybreakCombatData")
		if cdMod and cdMod:IsA("ModuleScript") then
			local ok, cd = pcall(require, cdMod)
			if ok and type(cd) == "table" and type(cd.SkillBlueprints) == "table" then
				SharedBlueprints = cd.SkillBlueprints
				return SharedBlueprints
			end
		end
	end
	return nil
end

-- Rule 3: Complete Canonical + Legacy Alias Lookup for all 12 Aether Cores
local CORE_ALIASES = {
	galecore = "GaleCore", gale = "GaleCore", gale_core = "GaleCore", wind = "GaleCore",
	sandstonecore = "SandstoneCore", sandstone = "SandstoneCore", sandstone_core = "SandstoneCore", sand = "SandstoneCore", smoke = "SandstoneCore",
	solarflamecore = "SolarFlameCore", solarflame = "SolarFlameCore", solar_flame = "SolarFlameCore", flame = "SolarFlameCore", fire = "SolarFlameCore",
	glaciericecore = "GlacierIceCore", glacierice = "GlacierIceCore", glacier_ice = "GlacierIceCore", ice = "GlacierIceCore", frost = "GlacierIceCore", frostbite = "GlacierIceCore",
	celestiallightcore = "CelestialLightCore", celestiallight = "CelestialLightCore", celestial_light = "CelestialLightCore", light = "CelestialLightCore",
	starforgedmagmacore = "StarforgedMagmaCore", starforgedmagma = "StarforgedMagmaCore", starforged_magma = "StarforgedMagmaCore", magma = "StarforgedMagmaCore",
	thunderrumblecore = "ThunderRumbleCore", thunderrumble = "ThunderRumbleCore", thunder_rumble = "ThunderRumbleCore", rumble = "ThunderRumbleCore", thunder = "ThunderRumbleCore",
	astralgravitycore = "AstralGravityCore", astralgravity = "AstralGravityCore", astral_gravity = "AstralGravityCore", gravity = "AstralGravityCore",
	dimensionalportalcore = "DimensionalPortalCore", dimensionalportal = "DimensionalPortalCore", dimensional_portal = "DimensionalPortalCore", portal = "DimensionalPortalCore",
	solartitancore = "SolarTitanCore", solartitan = "SolarTitanCore", solar_titan = "SolarTitanCore", buddha = "SolarTitanCore", quake = "SolarTitanCore", starlight_quake = "SolarTitanCore", starlightquakecore = "SolarTitanCore",
	aetherflowcore = "AetherflowCore", aetherflow = "AetherflowCore", sweetdoughcore = "AetherflowCore", sweet_dough = "AetherflowCore", dough = "AetherflowCore", mochi = "AetherflowCore",
	abyssalsovereigncore = "AbyssalSovereignCore", abyssal_sovereign = "AbyssalSovereignCore", abyssal_dragon = "AbyssalSovereignCore", void_dragon = "AbyssalSovereignCore", dragon = "AbyssalSovereignCore",
}

-- Rule 2: Explicit True-Flight Whitelist (ONLY these 6 Cores + AbyssalSovereignCore at DragonFormTier >= 2)
local TRUE_FLIGHT_CORES = {
	GaleCore = true,
	SandstoneCore = true,
	SolarFlameCore = true,
	CelestialLightCore = true,
	StarforgedMagmaCore = true,
	AstralGravityCore = true,
}

local STYLE_ALIASES = {
	skyborn_combat = "skyborn_combat", skyborncombat = "skyborn_combat",
	skystep = "SkyStep", sky_step = "SkyStep", black_leg = "SkyStep", flame_step = "SkyStep",
	jade_dragon = "jade_dragon", jadedragon = "jade_dragon", glacialfist = "jade_dragon", glacial_karate = "jade_dragon",
	thunder_talon = "thunder_talon", thundertalon = "thunder_talon", electricclaw = "thunder_talon", electric_claw = "thunder_talon",
	solar_ashura = "solar_ashura", solarashura = "solar_ashura", abyssaltalon = "solar_ashura", dragon_talon = "solar_ashura",
	celestial_godhuman = "celestial_godhuman", celestialgodhuman = "celestial_godhuman", godhuman = "celestial_godhuman", godhumanskyborn = "celestial_godhuman",
	sanguinevoidart = "SanguineVoidArt", sanguine_void_art = "SanguineVoidArt", sanguine = "SanguineVoidArt",
	chronovoidpalm = "ChronoVoidPalm", chrono_void_palm = "ChronoVoidPalm",
}

local STYLE_KATA_KIND = {
	skyborn_combat = "Punch",
	SkyStep = "Kick",
	jade_dragon = "Claw",
	thunder_talon = "Claw",
	solar_ashura = "Punch",
	celestial_godhuman = "Punch",
	SanguineVoidArt = "Claw",
	ChronoVoidPalm = "Punch",
}

local WEAPON_ARCHETYPE_MAP = {
	starter_sword = "Katana",
	cyber_katana_mk2 = "Katana",
	cryon_frostblade = "Katana",
	yamo_voidblade = "Katana",
	iron_saber = "Katana",
	aether_katana = "Katana",
	sol_blade = "Katana",
	storm_katana = "Katana",
	dawnbringer_sword = "Greatsword",
	dawnbringer = "Greatsword",
	saber_of_aureon = "Greatsword",
	sylvaris_thornblade = "Greatsword",
	noxar_greatsword = "Greatsword",
	noxar_abyssal_greatsword = "Greatsword",
	abyssal_greatsword = "Greatsword",
	dragon_cleaver = "Greatsword",
	ignivar_magma_breaker = "Greatsword",
	architectsseverance = "Greatsword",
	architect_severance = "Greatsword",
	starter_daggers = "DualBlades",
	stormfang_daggers = "DualBlades",
	stormfang = "DualBlades",
	cursed_dual_skyblades = "DualBlades",
	dual_eclipse = "DualBlades",
	twin_fang_daggers = "DualBlades",
	starter_staff = "Spear",
	astral_staff = "Spear",
	eternalfrost = "Spear",
	eternal_frost_staff = "Spear",
	sky_halberd = "Spear",
	tempest_trident = "Spear",
	sunshard_halberd = "Spear",
	nerith_abyssal_trident = "Spear",
	void_reaper_scythe = "Scythe",
	aion_chrono_scythe = "Scythe",
}

local GUN_ARCHETYPE_MAP = {
	aether_flintlock = "PistolRifle",
	aion_chrono_pistols = "DualPistols",
	bizarre_rifle_cyber = "Railgun",
	cryo_railgun = "Railgun",
	veyr_singularity_cannon = "Railgun",
	magma_blaster = "Cannon",
	ignivar_hellcannon = "Cannon",
	soul_guitar_void = "VoidLyre",
	solar_kabucha = "Bow",
	kabucha_wind = "Bow",
	storm_longbow = "Bow",
	sylvaris_thornbow = "Bow",
}

function Choreo.ResolveCoreId(rawId)
	local s = tostring(rawId or ""):match("^([^|]+)") or ""
	if s == "" or s == "None" then
		return ""
	end
	local bp = getBlueprints()
	if bp and type(bp.ResolveCoreId) == "function" then
		local ok, res = pcall(bp.ResolveCoreId, s)
		if ok and type(res) == "string" and res ~= "" and res ~= "None" then
			return res
		end
	end
	return CORE_ALIASES[string.lower(s)] or ""
end

function Choreo.IsTrueFlightCore(coreId, dragonFormTier, fruitTransform)
	local cid = Choreo.ResolveCoreId(coreId)
	if cid == "" then
		return false
	end
	if cid == "AbyssalSovereignCore" then
		local tier = tonumber(dragonFormTier) or 0
		local tf = tostring(fruitTransform or "")
		return (tier >= 2) or (tf == "AbyssalSovereign") or (tf == "DragonFull")
	end
	return TRUE_FLIGHT_CORES[cid] == true
end

function Choreo.ResolveStyleId(rawId)
	local s = tostring(rawId or "")
	if s == "" then
		return "skyborn_combat"
	end
	local bp = getBlueprints()
	if bp and type(bp.ResolveStyleId) == "function" then
		local ok, res = pcall(bp.ResolveStyleId, s)
		if ok and type(res) == "string" and res ~= "" then
			return res
		end
	end
	return STYLE_ALIASES[string.lower(s)] or s
end

function Choreo.ResolveWeaponArchetype(weaponId)
	local raw = tostring(weaponId or "")
	local bp = getBlueprints()
	if bp and type(bp.ResolveWeaponArchetype) == "function" and raw ~= "" then
		local ok, res = pcall(bp.ResolveWeaponArchetype, raw)
		if ok and type(res) == "string" and res ~= "" then
			return res
		end
	end
	local low = string.lower(raw)
	local mapped = WEAPON_ARCHETYPE_MAP[low]
	if mapped then
		return mapped
	end
	if low:find("halberd") or low:find("trident") or low:find("spear") or low:find("staff") or low:find("lance") or low:find("frost") and low:find("eternal") then
		return "Spear"
	elseif low:find("scythe") or low:find("reaper") then
		return "Scythe"
	elseif low:find("dual") or low:find("dagger") or low:find("twin") or low:find("stormfang") then
		return "DualBlades"
	elseif low:find("greatsword") or low:find("breaker") or low:find("hammer") or low:find("thornblade") or low:find("severance") or low:find("aureon") or low:find("dawn") then
		return "Greatsword"
	end
	return "Katana"
end

function Choreo.ResolveGunArchetype(gunId)
	local raw = tostring(gunId or "")
	local low = string.lower(raw)
	if low == "aion_chrono_pistols" or low:find("dual") and low:find("pistol") then
		return "DualPistols"
	end
	local bp = getBlueprints()
	if bp and type(bp.ResolveGunArchetype) == "function" and raw ~= "" then
		local ok, res = pcall(bp.ResolveGunArchetype, raw)
		if ok and type(res) == "string" and res ~= "" then
			if res == "AcousticGuitar" then
				return "VoidLyre"
			end
			return res
		end
	end
	local mapped = GUN_ARCHETYPE_MAP[low]
	if mapped then
		return mapped
	end
	if low:find("guitar") or low:find("lyre") then
		return "VoidLyre"
	elseif low:find("bow") or low:find("kabucha") or low:find("sling") then
		return "Bow"
	elseif low:find("rail") or low:find("rifle") or low:find("singularity") then
		return "Railgun"
	elseif low:find("cannon") or low:find("blaster") then
		return "Cannon"
	end
	return "PistolRifle"
end

-- Compact degree-based CFrame constructors in R15 rig-offset space
local RAD = math.pi / 180
local function ang(rx, ry, rz)
	return CFrame.Angles(rx * RAD, ry * RAD, rz * RAD)
end
local function cf(px, py, pz, rx, ry, rz)
	return CFrame.new(px, py, pz) * CFrame.Angles((rx or 0) * RAD, (ry or 0) * RAD, (rz or 0) * RAD)
end

-- ============================================================================
-- BESPOKE 4-BEAT FULL-BODY POSE CLIP LIBRARY
-- Beat 1: WindupSec | Beat 2: SnapSec (Overshoot) | Beat 3: HitstopSec (35-50ms) | Beat 4: RecoverSec
-- ============================================================================
local CLIPS = {
	-- ------------------------------------------------------------------------
	-- 1. SPEAR (MUA GIAO: Halberd / Trident / Arcane Polearm)
	-- ------------------------------------------------------------------------
	Spear_M1_1 = {
		WindupSec = 0.085, SnapSec = 0.095, HitstopSec = 0.040, RecoverSec = 0.18,
		Windup = {
			R=cf(0, -0.18, 0.14, 6, -42, -4), W=ang(4, -36, 0), N=ang(-4, 52, 0), RS=ang(74, -22, 54), RE=ang(48, 0, 0), RW=ang(-18, 0, 14), LS=ang(66, 28, 28), LE=ang(56, 0, 0), RH=ang(-24, 8, 14), RK=ang(-28, 0, 0), RA=ang(12, 0, 0), LH=ang(28, -8, -14), LK=ang(-38, 0, 0), LA=ang(10, 0, 0), RWep=cf(0, 0.25, 0, -48, 32, -22),
		},
		Strike = {
			R=cf(0, -0.22, -0.30, -14, 48, 6), W=ang(-12, 44, 0), N=ang(8, -56, 0), RS=ang(88, 24, -38), RE=ang(16, 0, 0), RW=ang(-32, 0, -18), LS=ang(52, -18, -36), LE=ang(34, 0, 0), RH=ang(32, -6, 12), RK=ang(-42, 0, 0), RA=ang(14, 0, 0), LH=ang(-28, 8, -12), LK=ang(-22, 0, 0), LA=ang(-8, 0, 0), RWep=cf(0, 0.38, 0, -68, -36, 26),
		},
	},

	Spear_M1_2 = {
		WindupSec = 0.070, SnapSec = 0.135, HitstopSec = 0.042, RecoverSec = 0.16,
		Windup = {
			R=cf(0, -0.24, 0.18, -8, -34, 0), W=ang(-6, -28, 0), N=ang(8, 42, 0), RS=ang(32, -18, 24), RE=ang(82, 0, 0), RW=ang(-24, 0, 0), LS=ang(78, 22, 16), LE=ang(52, 0, 0), RH=ang(-30, 10, 14), RK=ang(-34, 0, 0), LH=ang(34, -8, -12), LK=ang(-46, 0, 0), RWep=cf(0, 0.10, 0, -64, 12, 0),
		},
		Strike = {
			R=cf(0, -0.26, -0.38, -18, 32, 0), W=ang(-14, 38, 0), N=ang(12, -46, 0), RS=ang(96, -8, -8), RE=ang(8, 0, 0), RW=ang(-38, 0, 0), LS=ang(68, 26, 22), LE=ang(44, 0, 0), RH=ang(-36, 8, 12), RK=ang(-18, 0, 0), RA=ang(-14, 0, 0), LH=ang(42, -6, -12), LK=ang(-54, 0, 0), LA=ang(16, 0, 0), RWep=cf(0, 0.62, 0, -74, -8, 0),
		},
		-- Rapid coiled triple-thrust piston pulses across Beat 2
		DynamicFn = function(info, pose, rWep, lWep)
			if info.Beat == 2 then
				local pulse = math.sin(info.BeatU * math.pi * 3)
				local jab = math.abs(pulse)
				local laneYaw = (info.BeatU < 0.34 and -7) or (info.BeatU < 0.67 and 7) or 0
				pose.RightShoulder = ang(64 + 36 * jab, -8 + laneYaw, -6)
				pose.RightElbow = ang(56 * (1 - jab) + 6, 0, 0)
				pose.Waist = ang(-12, 18 + 24 * jab + laneYaw, 0)
				rWep = cf(0, 0.15 + 0.62 * jab, 0, -72, laneYaw * 0.8, 0)
			end
			return rWep, lWep
		end,
	},

	Spear_M1_3 = {
		WindupSec = 0.075, SnapSec = 0.180, HitstopSec = 0.040, RecoverSec = 0.18,
		LockLegs = true,
		Windup = {
			R=cf(0, -0.14, 0.06, -6, -28, -6), W=ang(-4, -24, 0), N=ang(4, 30, 0), RS=ang(88, 0, 18), RE=ang(28, 0, 0), LS=ang(74, 18, -26), LE=ang(42, 0, 0), RH=ang(22, 0, 12), RK=ang(-32, 0, 0), LH=ang(-22, 0, -12), LK=ang(-24, 0, 0), RWep=cf(0, 0.42, 0, 0, 0, 24),
		},
		Strike = {
			R=cf(0, 0.08, -0.26, -12, 36, 6), W=ang(-10, 32, 0), N=ang(8, -38, 0), RS=ang(96, -12, 12), RE=ang(18, 0, 0), RW=ang(-16, 22, 0), LS=ang(58, -14, -42), LE=ang(34, 0, 0), RH=ang(30, 0, 14), RK=ang(-38, 0, 0), LH=ang(-26, 0, -14), LK=ang(-20, 0, 0), RWep=cf(0, 0.45, 0, -58, -18, 16),
		},
		-- Full 360-degree Figure-8 infinity shaft spin around polearm center of mass
		DynamicFn = function(info, pose, rWep, lWep)
			if info.Beat == 2 or info.Beat == 3 then
				local u = (info.Beat == 3) and 1.0 or info.BeatU
				local theta = u * math.pi * 2
				local fig8Tilt = math.sin(theta) * 38
				local waistWeave = math.sin(theta) * 28
				pose.Waist = ang(-10, waistWeave, math.cos(theta) * 8)
				pose.RightShoulder = ang(92 + math.cos(theta) * 14, -math.sin(theta) * 18, 16 + math.sin(theta) * 14)
				pose.LeftShoulder = ang(72 - math.cos(theta) * 18, 12, -32 - math.sin(theta) * 12)
				rWep = CFrame.new(0, 0.58, 0)
					* CFrame.Angles(-theta, fig8Tilt * RAD, 18 * RAD)
					* CFrame.new(0, -0.58, 0)
			end
			return rWep, lWep
		end,
	},

	Spear_M1_4 = {
		WindupSec = 0.115, SnapSec = 0.110, HitstopSec = 0.050, RecoverSec = 0.24,
		LockLegs = true,
		Windup = {
			R=cf(0, 0.68, 0.10, 18, -24, 0), W=ang(16, -22, 0), N=ang(-14, 24, 0), RS=ang(154, -14, 22), RE=ang(36, 0, 0), RW=ang(18, 0, 0), LS=ang(138, 22, -16), LE=ang(44, 0, 0), RH=ang(68, 0, 10), RK=ang(-82, 0, 0), RA=ang(-24, 0, 0), LH=ang(-34, 0, -10), LK=ang(-38, 0, 0), LA=ang(-26, 0, 0), RWep=cf(0, 0.20, 0, 28, 12, 0),
		},
		Strike = {
			R=cf(0, -0.34, -0.44, -26, 28, 0), W=ang(-22, 26, 0), N=ang(20, -28, 0), RS=ang(68, -8, -14), RE=ang(12, 0, 0), RW=ang(-42, 0, 0), LS=ang(56, 24, 18), LE=ang(36, 0, 0), RH=ang(46, 0, 14), RK=ang(-58, 0, 0), RA=ang(18, 0, 0), LH=ang(-42, 0, -12), LK=ang(-22, 0, 0), LA=ang(-16, 0, 0), RWep=cf(0, 0.56, 0, -82, -10, 0),
		},
	},

	Spear_Z_Thrust = {
		WindupSec = 0.110, SnapSec = 0.105, HitstopSec = 0.046, RecoverSec = 0.22,
		LockLegs = true,
		Windup = {
			R=cf(0, -0.32, 0.26, -12, -42, 0), W=ang(-10, -36, 0), N=ang(14, 54, 0), RS=ang(24, -22, 28), RE=ang(88, 0, 0), RW=ang(-28, 0, 0), LS=ang(82, 28, 18), LE=ang(56, 0, 0), RH=ang(-38, 12, 16), RK=ang(-36, 0, 0), LH=ang(42, -10, -14), LK=ang(-56, 0, 0), RWep=cf(0, 0.08, 0, -68, 16, 0),
		},
		Strike = {
			R=cf(0, -0.28, -0.52, -24, 38, 0), W=ang(-18, 42, 0), N=ang(18, -52, 0), RS=ang(98, -10, -10), RE=ang(6, 0, 0), RW=ang(-42, 0, 0), LS=ang(-32, 0, -34), LE=ang(28, 0, 0), RH=ang(-46, 8, 14), RK=ang(-14, 0, 0), RA=ang(-18, 0, 0), LH=ang(48, -6, -14), LK=ang(-62, 0, 0), LA=ang(18, 0, 0), RWep=cf(0, 0.72, 0, -76, -8, 0),
		},
	},

	Spear_X_PoleVault = {
		WindupSec = 0.130, SnapSec = 0.125, HitstopSec = 0.048, RecoverSec = 0.26,
		LockLegs = true,
		Windup = {
			R=cf(0, 0.92, -0.12, 22, -16, 0), W=ang(18, -14, 0), N=ang(-18, 16, 0), RS=ang(162, -10, 16), RE=ang(24, 0, 0), LS=ang(156, 10, -16), LE=ang(28, 0, 0), RH=ang(82, 0, 12), RK=ang(-92, 0, 0), RA=ang(-28, 0, 0), LH=ang(54, 0, -12), LK=ang(-76, 0, 0), LA=ang(-26, 0, 0), RWep=cf(0, 0.35, 0, 42, 0, 0),
		},
		Strike = {
			R=cf(0, -0.40, -0.38, -28, 22, 0), W=ang(-24, 20, 0), N=ang(22, -22, 0), RS=ang(58, -6, -12), RE=ang(14, 0, 0), RW=ang(-44, 0, 0), LS=ang(48, 20, 16), LE=ang(34, 0, 0), RH=ang(52, 0, 14), RK=ang(-66, 0, 0), RA=ang(20, 0, 0), LH=ang(-40, 0, -14), LK=ang(-26, 0, 0), LA=ang(-14, 0, 0), RWep=cf(0, 0.58, 0, -86, 0, 0),
		},
	},

	-- ------------------------------------------------------------------------
	-- 2. KATANA (Kesa-giri, Gyaku-kesa, Yokomen, Kirioroshi & Iai Battojutsu)
	-- ------------------------------------------------------------------------
	Katana_M1_1 = {
		WindupSec = 0.070, SnapSec = 0.085, HitstopSec = 0.038, RecoverSec = 0.16,
		Windup = {
			R=cf(0, -0.14, 0.10, 6, -32, 0), W=ang(8, -28, 0), N=ang(-4, 38, 0), RS=ang(138, -18, 36), RE=ang(46, 0, 0), RW=ang(14, 0, 0), LS=ang(112, 28, 24), LE=ang(54, 0, 0), RH=ang(-18, 6, 10), RK=ang(-22, 0, 0), LH=ang(22, -6, -10), LK=ang(-30, 0, 0), RWep=cf(0, 0, 0, 12, 0, 18),
		},
		Strike = {
			R=cf(0, -0.20, -0.26, -14, 38, 0), W=ang(-14, 42, 0), N=ang(10, -46, 0), RS=ang(42, 16, -42), RE=ang(14, 0, 0), RW=ang(-32, 0, -18), LS=ang(-28, 0, -26), LE=ang(36, 0, 0), RH=ang(28, -4, 12), RK=ang(-36, 0, 0), LH=ang(-26, 6, -12), LK=ang(-18, 0, 0), RWep=cf(0, 0, 0, -54, -22, -28),
		},
	},

	Katana_M1_2 = {
		WindupSec = 0.070, SnapSec = 0.085, HitstopSec = 0.038, RecoverSec = 0.16,
		Windup = {
			R=cf(0, -0.22, 0.08, -10, 34, 0), W=ang(-12, 36, 0), N=ang(8, -42, 0), RS=ang(36, 28, -46), RE=ang(52, 0, 0), LS=ang(24, 14, -22), LE=ang(48, 0, 0), RH=ang(22, 0, 10), RK=ang(-32, 0, 0), LH=ang(-20, 0, -10), LK=ang(-24, 0, 0), RWep=cf(0, 0, 0, -36, 26, 38),
		},
		Strike = {
			R=cf(0, -0.12, -0.24, 6, -38, 0), W=ang(8, -42, 0), N=ang(-4, 46, 0), RS=ang(126, -24, 48), RE=ang(16, 0, 0), RW=ang(-24, 0, 22), LS=ang(-24, 0, -32), LE=ang(32, 0, 0), RH=ang(-22, 0, 12), RK=ang(-20, 0, 0), LH=ang(28, 0, -12), LK=ang(-36, 0, 0), RWep=cf(0, 0, 0, -28, -18, 34),
		},
	},

	Katana_M1_3 = {
		WindupSec = 0.070, SnapSec = 0.090, HitstopSec = 0.040, RecoverSec = 0.16,
		Windup = {
			R=cf(0, -0.24, 0.12, -8, 42, -4), W=ang(-8, 44, 0), N=ang(8, -52, 0), RS=ang(64, 34, -52), RE=ang(68, 0, 0), LS=ang(18, 22, 16), LE=ang(58, 0, 0), RH=ang(24, 0, 12), RK=ang(-34, 0, 0), LH=ang(-24, 0, -12), LK=ang(-24, 0, 0), RWep=cf(0, 0, 0, -68, 38, 76),
		},
		Strike = {
			R=cf(0, -0.22, -0.30, -14, -46, 6), W=ang(-12, -48, 0), N=ang(12, 56, 0), RS=ang(86, -32, 62), RE=ang(12, 0, 0), RW=ang(-28, 0, 24), LS=ang(-18, 12, -24), LE=ang(46, 0, 0), RH=ang(-28, 0, 12), RK=ang(-20, 0, 0), LH=ang(34, 0, -12), LK=ang(-44, 0, 0), RWep=cf(0, 0, 0, -64, -24, 82),
		},
	},

	Katana_M1_4 = {
		WindupSec = 0.095, SnapSec = 0.115, HitstopSec = 0.048, RecoverSec = 0.22,
		LockLegs = true,
		Windup = {
			R=cf(0, 0.34, 0.06, 14, -120, 0), W=ang(12, -32, 0), N=ang(-8, 36, 0), RS=ang(156, 0, 14), RE=ang(34, 0, 0), LS=ang(148, 16, -14), LE=ang(38, 0, 0), RH=ang(44, 0, 10), RK=ang(-58, 0, 0), LH=ang(-22, 0, -10), LK=ang(-34, 0, 0), RWep=cf(0, 0, 0, 18, 0, 0),
		},
		Strike = {
			R=cf(0, -0.30, -0.36, -22, 18, 0), W=ang(-20, 16, 0), N=ang(18, -18, 0), RS=ang(34, 0, -12), RE=ang(14, 0, 0), RW=ang(-38, 0, 0), LS=ang(30, 18, 14), LE=ang(24, 0, 0), RH=ang(38, 0, 14), RK=ang(-48, 0, 0), LH=ang(-36, 0, -14), LK=ang(-20, 0, 0), RWep=cf(0, 0, 0, -72, 0, 0),
		},
	},

	Katana_Z_IaiDraw = {
		WindupSec = 0.125, SnapSec = 0.080, HitstopSec = 0.050, RecoverSec = 0.24,
		LockLegs = true,
		Windup = {
			R=cf(0, -0.40, 0.16, -22, 48, -8), W=ang(-18, 42, 0), N=ang(24, -58, 6), RS=ang(44, 38, -58), RE=ang(82, 0, 0), RW=ang(18, 24, 0), LS=ang(26, 24, 18), LE=ang(64, 0, 0), RH=ang(38, -8, 16), RK=ang(-56, 0, 0), RA=ang(18, 0, 0), LH=ang(-38, 10, -16), LK=ang(-36, 0, 0), LA=ang(12, 0, 0), RWep=cf(-0.18, -0.10, 0, -108, 36, 78),
		},
		Strike = {
			R=cf(0, -0.32, -0.46, -26, -54, 10), W=ang(-16, -52, 0), N=ang(22, 62, -6), RS=ang(92, -36, 72), RE=ang(8, 0, 0), RW=ang(-34, -18, 28), LS=ang(-36, 12, -32), LE=ang(44, 0, 0), RH=ang(-42, 8, 14), RK=ang(-16, 0, 0), RA=ang(-18, 0, 0), LH=ang(46, -6, -14), LK=ang(-58, 0, 0), LA=ang(20, 0, 0), RWep=cf(0, 0.18, 0, -68, -28, 86),
		},
	},

	Katana_X_Crescent = {
		WindupSec = 0.095, SnapSec = 0.100, HitstopSec = 0.042, RecoverSec = 0.22,
		LockLegs = true,
		Windup = {
			R=cf(0, -0.28, 0.12, -14, 38, 0), W=ang(-12, 36, 0), N=ang(12, -40, 0), RS=ang(22, 32, -48), RE=ang(56, 0, 0), LS=ang(18, 18, -22), LE=ang(48, 0, 0), RH=ang(30, 0, 12), RK=ang(-44, 0, 0), LH=ang(-26, 0, -12), LK=ang(-28, 0, 0), RWep=cf(0, 0, 0, -42, 28, 44),
		},
		Strike = {
			R=cf(0, 0.36, -0.24, 12, -42, 0), W=ang(14, -44, 0), N=ang(-8, 46, 0), RS=ang(148, -24, 42), RE=ang(12, 0, 0), RW=ang(-26, 0, 18), LS=ang(-32, 0, -38), LE=ang(28, 0, 0), RH=ang(46, 0, 10), RK=ang(-58, 0, 0), RA=ang(-18, 0, 0), LH=ang(-28, 0, -10), LK=ang(-34, 0, 0), LA=ang(-20, 0, 0), RWep=cf(0, 0.12, 0, -18, -16, 28),
		},
	},

	-- ------------------------------------------------------------------------
	-- 3. GREATSWORD / WARHAMMER (Heavy Torso-Torqued Cleaves & Earth-Splitters)
	-- ------------------------------------------------------------------------
	Greatsword_M1_1 = {
		WindupSec = 0.105, SnapSec = 0.105, HitstopSec = 0.046, RecoverSec = 0.22,
		Windup = {
			R=cf(0, -0.20, 0.18, 8, -52, -8), W=ang(10, -46, -6), N=ang(-6, 58, 0), RS=ang(128, -28, 56), RE=ang(58, 0, 0), LS=ang(106, 36, 34), LE=ang(64, 0, 0), RH=ang(-28, 10, 16), RK=ang(-32, 0, 0), LH=ang(32, -8, -16), LK=ang(-44, 0, 0), RWep=cf(0, 0, 0, 24, 18, 32),
		},
		Strike = {
			R=cf(0, -0.28, -0.34, -18, 56, 8), W=ang(-18, 52, 6), N=ang(14, -62, 0), RS=ang(52, 26, -48), RE=ang(16, 0, 0), RW=ang(-36, 0, -24), LS=ang(44, -18, -32), LE=ang(28, 0, 0), RH=ang(36, -6, 16), RK=ang(-48, 0, 0), LH=ang(-34, 8, -16), LK=ang(-22, 0, 0), RWep=cf(0, 0.14, 0, -64, -28, -42),
		},
	},

	Greatsword_M1_2 = {
		WindupSec = 0.100, SnapSec = 0.105, HitstopSec = 0.046, RecoverSec = 0.20,
		Windup = {
			R=cf(0, -0.30, 0.12, -16, 48, 8), W=ang(-18, 46, 0), N=ang(14, -54, 0), RS=ang(18, 32, -52), RE=ang(42, 0, 0), LS=ang(24, -16, -28), LE=ang(48, 0, 0), RH=ang(28, 0, 14), RK=ang(-42, 0, 0), LH=ang(-26, 0, -14), LK=ang(-26, 0, 0), RWep=cf(0, 0, 0, -56, 34, 52),
		},
		Strike = {
			R=cf(0, -0.10, -0.28, 12, -48, -6), W=ang(14, -46, 0), N=ang(-8, 52, 0), RS=ang(142, -26, 48), RE=ang(18, 0, 0), RW=ang(-22, 0, 24), LS=ang(118, 22, 18), LE=ang(32, 0, 0), RH=ang(-26, 0, 14), RK=ang(-20, 0, 0), LH=ang(34, 0, -14), LK=ang(-42, 0, 0), RWep=cf(0, 0.10, 0, -18, -22, 36),
		},
	},

	Greatsword_M1_3 = {
		WindupSec = 0.100, SnapSec = 0.155, HitstopSec = 0.046, RecoverSec = 0.22,
		LockLegs = true,
		Windup = {
			R=cf(0, -0.22, 0.10, -10, -56, -6), W=ang(-8, -44, 0), N=ang(8, 48, 0), RS=ang(84, -24, 56), RE=ang(34, 0, 0), LS=ang(76, 28, 26), LE=ang(44, 0, 0), RH=ang(-24, 0, 14), RK=ang(-28, 0, 0), LH=ang(28, 0, -14), LK=ang(-38, 0, 0), RWep=cf(0, 0.10, 0, -58, 24, 72),
		},
		Strike = {
			R=cf(0, -0.18, -0.32, -16, 54, 6), W=ang(-14, 48, 0), N=ang(12, -52, 0), RS=ang(88, 28, -48), RE=ang(14, 0, 0), LS=ang(72, -18, -24), LE=ang(26, 0, 0), RH=ang(32, 0, 14), RK=ang(-42, 0, 0), LH=ang(-30, 0, -14), LK=ang(-22, 0, 0), RWep=cf(0, 0.18, 0, -68, -28, -76),
		},
		DynamicFn = function(info, pose, rWep, lWep)
			if info.Beat == 2 then
				local spin = -info.BeatU * 360
				pose.Root = cf(0, -0.16, -0.24 * info.BeatU, -14, spin, 0)
			end
			return rWep, lWep
		end,
	},

	Greatsword_M1_4 = {
		WindupSec = 0.130, SnapSec = 0.115, HitstopSec = 0.050, RecoverSec = 0.26,
		LockLegs = true,
		Windup = {
			R=cf(0, 0.42, 0.14, 22, -18, 0), W=ang(20, -14, 0), N=ang(-16, 14, 0), RS=ang(164, -8, 16), RE=ang(42, 0, 0), LS=ang(158, 12, -16), LE=ang(44, 0, 0), RH=ang(48, 0, 12), RK=ang(-64, 0, 0), LH=ang(-28, 0, -12), LK=ang(-36, 0, 0), RWep=cf(0, 0, 0, 34, 0, 0),
		},
		Strike = {
			R=cf(0, -0.38, -0.40, -28, 14, 0), W=ang(-24, 12, 0), N=ang(22, -12, 0), RS=ang(28, 0, -10), RE=ang(12, 0, 0), RW=ang(-44, 0, 0), LS=ang(26, 14, 12), LE=ang(18, 0, 0), RH=ang(48, 0, 16), RK=ang(-62, 0, 0), RA=ang(20, 0, 0), LH=ang(-42, 0, -16), LK=ang(-22, 0, 0), LA=ang(-16, 0, 0), RWep=cf(0, 0.22, 0, -84, 0, 0),
		},
	},

	Greatsword_Z_EarthSplit = {
		WindupSec = 0.140, SnapSec = 0.110, HitstopSec = 0.050, RecoverSec = 0.28,
		LockLegs = true,
		Windup = {
			R=cf(0, -0.26, 0.22, 24, -28, 0), W=ang(22, -24, 0), N=ang(-18, 26, 0), RS=ang(168, -12, 20), RE=ang(46, 0, 0), LS=ang(160, 16, -18), LE=ang(48, 0, 0), RH=ang(-30, 8, 16), RK=ang(-34, 0, 0), LH=ang(34, -8, -16), LK=ang(-46, 0, 0), RWep=cf(0, 0, 0, 38, 0, 0),
		},
		Strike = {
			R=cf(0, -0.42, -0.44, -30, 18, 0), W=ang(-26, 16, 0), N=ang(24, -16, 0), RS=ang(24, 0, -12), RE=ang(10, 0, 0), RW=ang(-46, 0, 0), LS=ang(22, 16, 14), LE=ang(16, 0, 0), RH=ang(52, 0, 16), RK=ang(-66, 0, 0), RA=ang(22, 0, 0), LH=ang(-44, 0, -16), LK=ang(-20, 0, 0), LA=ang(-18, 0, 0), RWep=cf(0, 0.26, 0, -88, 0, 0),
		},
	},

	Greatsword_X_Guillotine = {
		WindupSec = 0.135, SnapSec = 0.125, HitstopSec = 0.050, RecoverSec = 0.26,
		LockLegs = true,
		Windup = {
			R=cf(0, 0.78, 0.06, 20, -140, 0), W=ang(18, -32, 0), N=ang(-14, 34, 0), RS=ang(162, -10, 22), RE=ang(38, 0, 0), LS=ang(154, 14, -20), LE=ang(40, 0, 0), RH=ang(66, 0, 12), RK=ang(-80, 0, 0), RA=ang(-24, 0, 0), LH=ang(38, 0, -12), LK=ang(-64, 0, 0), LA=ang(-22, 0, 0), RWep=cf(0, 0, 0, 32, 0, 0),
		},
		Strike = {
			R=cf(0, -0.40, -0.38, -28, 22, 0), W=ang(-24, 18, 0), N=ang(22, -18, 0), RS=ang(26, 0, -12), RE=ang(12, 0, 0), RW=ang(-44, 0, 0), LS=ang(24, 14, 14), LE=ang(18, 0, 0), RH=ang(50, 0, 16), RK=ang(-64, 0, 0), RA=ang(20, 0, 0), LH=ang(-42, 0, -16), LK=ang(-24, 0, 0), LA=ang(-14, 0, 0), RWep=cf(0, 0.24, 0, -86, 0, 0),
		},
	},

	-- ------------------------------------------------------------------------
	-- 4. DUAL BLADES (Twin Cross Cuts, Reverse Scissor, Reverse-Grip Spin)
	-- ------------------------------------------------------------------------
	DualBlades_M1_1 = {
		WindupSec = 0.060, SnapSec = 0.075, HitstopSec = 0.036, RecoverSec = 0.14,
		Windup = {
			R=cf(0, -0.16, 0.10, -6, 0, 0), W=ang(8, 0, 0), RS=ang(118, -24, 58), RE=ang(44, 0, 0), LS=ang(118, 24, -58), LE=ang(44, 0, 0), RH=ang(-18, 0, 12), RK=ang(-24, 0, 0), LH=ang(22, 0, -12), LK=ang(-32, 0, 0), RWep=cf(0, 0, 0, -18, 0, 28), LWep=cf(0, 0, 0, -18, 0, -28),
		},
		Strike = {
			R=cf(0, -0.24, -0.28, -18, 12, 0), W=ang(-16, 14, 0), RS=ang(64, 28, -48), RE=ang(18, 0, 0), RW=ang(-28, 0, -24), LS=ang(58, -28, 48), LE=ang(22, 0, 0), LW=ang(-28, 0, 24), RH=ang(28, 0, 12), RK=ang(-38, 0, 0), LH=ang(-26, 0, -12), LK=ang(-20, 0, 0), RWep=cf(0, 0, 0, -58, -24, -36), LWep=cf(0, 0, 0, -58, 24, 36),
		},
	},

	DualBlades_M1_2 = {
		WindupSec = 0.060, SnapSec = 0.075, HitstopSec = 0.036, RecoverSec = 0.14,
		Windup = {
			R=cf(0, -0.24, 0.06, -14, -10, 0), W=ang(-12, -12, 0), RS=ang(68, 32, -52), RE=ang(56, 0, 0), LS=ang(64, -32, 52), LE=ang(56, 0, 0), RH=ang(22, 0, 12), RK=ang(-32, 0, 0), LH=ang(-20, 0, -12), LK=ang(-24, 0, 0), RWep=cf(0, 0, 0, -48, 24, -44), LWep=cf(0, 0, 0, -48, -24, 44),
		},
		Strike = {
			R=cf(0, -0.16, -0.26, -8, 0, 0), W=ang(10, 0, 0), RS=ang(96, -34, 68), RE=ang(12, 0, 0), RW=ang(-24, 0, 32), LS=ang(96, 34, -68), LE=ang(12, 0, 0), LW=ang(-24, 0, -32), RH=ang(-24, 0, 14), RK=ang(-20, 0, 0), LH=ang(30, 0, -14), LK=ang(-38, 0, 0), RWep=cf(0, 0, 0, -54, -22, 64), LWep=cf(0, 0, 0, -54, 22, -64),
		},
	},

	DualBlades_M1_3 = {
		WindupSec = 0.065, SnapSec = 0.115, HitstopSec = 0.038, RecoverSec = 0.15,
		LockLegs = true,
		Windup = {
			R=cf(0, -0.28, 0.08, -18, -46, -6), W=ang(-14, -38, 0), RS=ang(-38, 0, 42), RE=ang(42, 0, 0), LS=ang(88, 22, -32), LE=ang(38, 0, 0), RH=ang(-26, 0, 14), RK=ang(-28, 0, 0), LH=ang(32, 0, -14), LK=ang(-42, 0, 0), RWep=cf(0, 0, 0, 168, 0, 18), LWep=cf(0, 0, 0, 168, 0, -18),
		},
		Strike = {
			R=cf(0, -0.22, -0.32, -22, 48, 6), W=ang(-16, 46, 0), RS=ang(92, -24, 54), RE=ang(16, 0, 0), LS=ang(-42, 0, -44), LE=ang(28, 0, 0), RH=ang(34, 0, 14), RK=ang(-44, 0, 0), LH=ang(-32, 0, -14), LK=ang(-22, 0, 0), RWep=cf(0, 0, 0, 162, 0, 42), LWep=cf(0, 0, 0, 162, 0, -42),
		},
		DynamicFn = function(info, pose, rWep, lWep)
			if info.Beat == 2 then
				pose.Root = cf(0, -0.22, -0.28 * info.BeatU, -20, -360 * info.BeatU, 0)
			end
			return rWep, lWep
		end,
	},

	DualBlades_M1_4 = {
		WindupSec = 0.085, SnapSec = 0.095, HitstopSec = 0.046, RecoverSec = 0.20,
		LockLegs = true,
		Windup = {
			R=cf(0, 0.52, 0.08, 16, 0, 0), W=ang(14, 0, 0), RS=ang(156, -18, 44), RE=ang(32, 0, 0), LS=ang(156, 18, -44), LE=ang(32, 0, 0), RH=ang(56, 0, 12), RK=ang(-74, 0, 0), LH=ang(-24, 0, -12), LK=ang(-38, 0, 0),
		},
		Strike = {
			R=cf(0, -0.32, -0.38, -24, 0, 0), W=ang(-22, 0, 0), RS=ang(38, 22, -38), RE=ang(14, 0, 0), RW=ang(-36, 0, -18), LS=ang(38, -22, 38), LE=ang(14, 0, 0), LW=ang(-36, 0, 18), RH=ang(42, 0, 14), RK=ang(-54, 0, 0), LH=ang(-36, 0, -14), LK=ang(-22, 0, 0), RWep=cf(0, 0, 0, -68, -18, -28), LWep=cf(0, 0, 0, -68, 18, 28),
		},
	},

	DualBlades_Z_Blitz = {
		WindupSec = 0.080, SnapSec = 0.085, HitstopSec = 0.044, RecoverSec = 0.20,
		LockLegs = true,
		Windup = {
			R=cf(0, -0.36, 0.18, -28, 0, 0), W=ang(-14, 0, 0), N=ang(28, 0, 0), RS=ang(-54, 0, 34), RE=ang(38, 0, 0), LS=ang(-54, 0, -34), LE=ang(38, 0, 0), RH=ang(44, 0, 14), RK=ang(-58, 0, 0), LH=ang(-40, 0, -14), LK=ang(-32, 0, 0), RWep=cf(0, 0, 0, 168, 0, 22), LWep=cf(0, 0, 0, 168, 0, -22),
		},
		Strike = {
			R=cf(0, -0.26, -0.46, -20, 0, 0), W=ang(-16, 0, 0), N=ang(18, 0, 0), RS=ang(92, -28, 64), RE=ang(10, 0, 0), LS=ang(92, 28, -64), LE=ang(10, 0, 0), RH=ang(-38, 0, 14), RK=ang(-18, 0, 0), LH=ang(46, 0, -14), LK=ang(-56, 0, 0), RWep=cf(0, 0, 0, -64, -22, 68), LWep=cf(0, 0, 0, -64, 22, -68),
		},
	},

	DualBlades_X_Spin = {
		WindupSec = 0.085, SnapSec = 0.210, HitstopSec = 0.042, RecoverSec = 0.20,
		LockLegs = true,
		Windup = {
			R=cf(0, -0.24, 0, -10, -45, 0), RS=ang(76, 24, -46), RE=ang(48, 0, 0), LS=ang(76, -24, 46), LE=ang(48, 0, 0), RH=ang(28, 0, 12), RK=ang(-42, 0, 0), LH=ang(-24, 0, -12), LK=ang(-28, 0, 0),
		},
		Strike = {
			R=cf(0, 0.32, 0, -12, 0, 0), RS=ang(94, 0, 74), RE=ang(10, 0, 0), LS=ang(94, 0, -74), LE=ang(10, 0, 0), RH=ang(38, 0, 14), RK=ang(-52, 0, 0), LH=ang(-24, 0, -14), LK=ang(-34, 0, 0), RWep=cf(0, 0, 0, -68, 0, 82), LWep=cf(0, 0, 0, -68, 0, -82),
		},
		DynamicFn = function(info, pose, rWep, lWep)
			if info.Beat == 2 then
				pose.Root = cf(0, 0.34 * math.sin(info.BeatU * math.pi), 0, -12, -720 * info.BeatU, 0)
			end
			return rWep, lWep
		end,
	},

	-- ------------------------------------------------------------------------
	-- 5. SCYTHE (Wide Crescent Harvest, Soul Hook & Dimensional Rift)
	-- ------------------------------------------------------------------------
	Scythe_M1_1 = {
		WindupSec = 0.095, SnapSec = 0.100, HitstopSec = 0.044, RecoverSec = 0.20,
		Windup = {
			R=cf(0, -0.20, 0.14, 6, -48, -6), W=ang(8, -44, 0), N=ang(-4, 56, 0), RS=ang(82, -26, 62), RE=ang(42, 0, 0), LS=ang(72, 32, 32), LE=ang(54, 0, 0), RH=ang(-26, 8, 14), RK=ang(-30, 0, 0), LH=ang(30, -8, -14), LK=ang(-40, 0, 0), RWep=cf(0, 0.28, 0, -58, 42, 68),
		},
		Strike = {
			R=cf(0, -0.26, -0.28, -16, 52, 6), W=ang(-16, 48, 0), N=ang(12, -58, 0), RS=ang(76, 28, -46), RE=ang(22, 0, 0), RW=ang(-28, -24, -22), LS=ang(48, -18, -36), LE=ang(32, 0, 0), RH=ang(34, -6, 14), RK=ang(-44, 0, 0), LH=ang(-32, 8, -14), LK=ang(-20, 0, 0), RWep=cf(0, 0.36, 0, -72, -46, -68),
		},
	},

	Scythe_M1_2 = {
		WindupSec = 0.090, SnapSec = 0.095, HitstopSec = 0.042, RecoverSec = 0.18,
		Windup = {
			R=cf(0, -0.26, 0.08, -14, 46, 6), W=ang(-14, 44, 0), N=ang(10, -50, 0), RS=ang(54, 30, -48), RE=ang(48, 0, 0), LS=ang(44, -14, -28), LE=ang(42, 0, 0), RH=ang(28, 0, 14), RK=ang(-38, 0, 0), LH=ang(-26, 0, -14), LK=ang(-24, 0, 0), RWep=cf(0, 0.24, 0, -64, -38, -58),
		},
		Strike = {
			R=cf(0, -0.14, -0.24, 8, -48, -6), W=ang(10, -46, 0), N=ang(-6, 54, 0), RS=ang(116, -28, 58), RE=ang(16, 0, 0), LS=ang(88, 24, 22), LE=ang(36, 0, 0), RH=ang(-26, 0, 14), RK=ang(-20, 0, 0), LH=ang(32, 0, -14), LK=ang(-40, 0, 0), RWep=cf(0, 0.34, 0, -48, 36, 64),
		},
	},

	Scythe_M1_3 = {
		WindupSec = 0.090, SnapSec = 0.165, HitstopSec = 0.044, RecoverSec = 0.20,
		LockLegs = true,
		Windup = {
			R=cf(0, -0.20, 0.08, -8, -52, 0), W=ang(-6, -40, 0), RS=ang(84, -22, 58), RE=ang(32, 0, 0), LS=ang(74, 26, 24), LE=ang(42, 0, 0), RH=ang(-22, 0, 14), RK=ang(-28, 0, 0), LH=ang(28, 0, -14), LK=ang(-36, 0, 0), RWep=cf(0, 0.38, 0, -68, 32, 78),
		},
		Strike = {
			R=cf(0, 0.16, -0.26, -14, 48, 0), W=ang(-12, 44, 0), RS=ang(88, 24, -44), RE=ang(18, 0, 0), LS=ang(68, -16, -28), LE=ang(28, 0, 0), RH=ang(32, 0, 14), RK=ang(-42, 0, 0), LH=ang(-28, 0, -14), LK=ang(-24, 0, 0), RWep=cf(0, 0.42, 0, -72, -38, -76),
		},
		DynamicFn = function(info, pose, rWep, lWep)
			if info.Beat == 2 then
				pose.Root = cf(0, 0.18 * math.sin(info.BeatU * math.pi), -0.22 * info.BeatU, -12, -360 * info.BeatU, 0)
			end
			return rWep, lWep
		end,
	},

	Scythe_M1_4 = {
		WindupSec = 0.115, SnapSec = 0.110, HitstopSec = 0.050, RecoverSec = 0.24,
		LockLegs = true,
		Windup = {
			R=cf(0, 0.58, -0.10, 18, -22, 0), W=ang(16, -18, 0), RS=ang(160, -12, 24), RE=ang(34, 0, 0), LS=ang(150, 18, -18), LE=ang(38, 0, 0), RH=ang(62, 0, 12), RK=ang(-78, 0, 0), LH=ang(-28, 0, -12), LK=ang(-36, 0, 0), RWep=cf(0, 0.30, 0, 22, -28, 0),
		},
		Strike = {
			R=cf(0, -0.36, -0.22, -24, 28, 0), W=ang(-22, 24, 0), RS=ang(24, 14, -22), RE=ang(36, 0, 0), RW=ang(-38, -22, 0), LS=ang(18, 22, 16), LE=ang(42, 0, 0), RH=ang(46, 0, 16), RK=ang(-60, 0, 0), LH=ang(-40, 0, -16), LK=ang(-22, 0, 0), RWep=cf(0, 0.44, 0, -96, -34, 0),
		},
	},

	Scythe_Z_Hook = {
		WindupSec = 0.115, SnapSec = 0.110, HitstopSec = 0.048, RecoverSec = 0.24,
		LockLegs = true,
		Windup = {
			R=cf(0, -0.22, -0.38, -22, 34, 0), W=ang(-18, 36, 0), N=ang(18, -38, 0), RS=ang(108, -12, 18), RE=ang(8, 0, 0), LS=ang(88, 24, 18), LE=ang(26, 0, 0), RH=ang(42, 0, 14), RK=ang(-54, 0, 0), LH=ang(-38, 0, -14), LK=ang(-20, 0, 0), RWep=cf(0, 0.64, 0, -82, -38, 0),
		},
		Strike = {
			R=cf(0, -0.28, 0.28, 12, -46, 0), W=ang(10, -44, 0), N=ang(-6, 48, 0), RS=ang(-28, -24, 48), RE=ang(64, 0, 0), LS=ang(34, 26, -32), LE=ang(52, 0, 0), RH=ang(-32, 0, 16), RK=ang(-36, 0, 0), LH=ang(36, 0, -16), LK=ang(-44, 0, 0), RWep=cf(0, 0.18, 0, -32, 42, 48),
		},
	},

	Scythe_X_Rift = {
		WindupSec = 0.110, SnapSec = 0.100, HitstopSec = 0.048, RecoverSec = 0.24,
		LockLegs = true,
		Windup = {
			R=cf(0, -0.30, 0.16, -12, -56, -8), W=ang(-10, -50, 0), N=ang(12, 60, 0), RS=ang(96, -32, 66), RE=ang(44, 0, 0), LS=ang(82, 34, 34), LE=ang(52, 0, 0), RH=ang(-30, 8, 16), RK=ang(-34, 0, 0), LH=ang(36, -8, -16), LK=ang(-48, 0, 0), RWep=cf(0, 0.34, 0, -64, 46, 76),
		},
		Strike = {
			R=cf(0, -0.24, -0.40, -18, 58, 8), W=ang(-16, 54, 0), N=ang(16, -62, 0), RS=ang(82, 32, -54), RE=ang(14, 0, 0), LS=ang(-28, 0, -42), LE=ang(32, 0, 0), RH=ang(40, -6, 16), RK=ang(-52, 0, 0), LH=ang(-38, 8, -16), LK=ang(-20, 0, 0), RWep=cf(0, 0.48, 0, -74, -48, -78),
		},
	},
	-- ------------------------------------------------------------------------
	-- 6. MARTIAL STYLES (Slot 1: Punch Kata, Pure Leg-Kata & Dragon/Void Claw)
	-- ------------------------------------------------------------------------
	Martial_Punch_1 = {
		WindupSec = 0.060, SnapSec = 0.075, HitstopSec = 0.038, RecoverSec = 0.14,
		Windup = {
			R=cf(0, -0.16, 0.10, -4, -34, 0), W=ang(-4, -38, 0), N=ang(6, 42, 0), RS=ang(28, -16, 26), RE=ang(96, 0, 0), LS=ang(78, 22, -16), LE=ang(82, 0, 0), RH=ang(-20, 8, 12), RK=ang(-26, 0, 0), LH=ang(24, -6, -12), LK=ang(-34, 0, 0),
		},
		Strike = {
			R=cf(0, -0.20, -0.28, -14, 34, 0), W=ang(-16, 48, 0), N=ang(12, -52, 0), RS=ang(96, -14, -14), RE=ang(8, 0, 0), RW=ang(-12, 0, -24), LS=ang(64, 20, -22), LE=ang(88, 0, 0), RH=ang(28, -4, 12), RK=ang(-38, 0, 0), LH=ang(-28, 6, -12), LK=ang(-20, 0, 0),
		},
	},

	Martial_Punch_2 = {
		WindupSec = 0.060, SnapSec = 0.075, HitstopSec = 0.038, RecoverSec = 0.14,
		Windup = {
			R=cf(0, -0.18, 0.08, -6, 36, 0), W=ang(-6, 42, 0), N=ang(6, -46, 0), LS=ang(34, 18, -32), LE=ang(94, 0, 0), RS=ang(74, -20, 18), RE=ang(84, 0, 0), RH=ang(24, 0, 12), RK=ang(-32, 0, 0), LH=ang(-22, 0, -12), LK=ang(-26, 0, 0),
		},
		Strike = {
			R=cf(0, -0.22, -0.30, -16, -38, 0), W=ang(-16, -52, 0), N=ang(12, 56, 0), LS=ang(98, 22, 28), LE=ang(22, 0, 0), LW=ang(-10, 0, 26), RS=ang(62, -18, 22), RE=ang(88, 0, 0), RH=ang(-30, 0, 12), RK=ang(-20, 0, 0), LH=ang(32, 0, -12), LK=ang(-42, 0, 0),
		},
	},

	Martial_Punch_3 = {
		WindupSec = 0.065, SnapSec = 0.085, HitstopSec = 0.042, RecoverSec = 0.16,
		Windup = {
			R=cf(0, -0.24, 0.10, -8, -48, -6), W=ang(-8, -44, 0), N=ang(8, 52, 0), RS=ang(72, -28, 48), RE=ang(98, 0, 0), LS=ang(68, 20, -18), LE=ang(80, 0, 0), RH=ang(-26, 0, 14), RK=ang(-30, 0, 0), LH=ang(30, 0, -14), LK=ang(-42, 0, 0),
		},
		Strike = {
			R=cf(0, -0.26, -0.34, -18, 52, 6), W=ang(-18, 54, 0), N=ang(14, -58, 0), RS=ang(94, 24, -36), RE=ang(58, 0, 0), LS=ang(-28, 0, -32), LE=ang(46, 0, 0), RH=ang(36, 0, 14), RK=ang(-46, 0, 0), LH=ang(-34, 0, -14), LK=ang(-20, 0, 0),
		},
	},

	Martial_Punch_4 = {
		WindupSec = 0.095, SnapSec = 0.095, HitstopSec = 0.050, RecoverSec = 0.22,
		LockLegs = true,
		Windup = {
			R=cf(0, -0.36, 0.20, 12, 0, 0), W=ang(14, 0, 0), N=ang(-8, 0, 0), RS=ang(18, -18, 34), RE=ang(102, 0, 0), LS=ang(18, 18, -34), LE=ang(102, 0, 0), RH=ang(-28, 12, 22), RK=ang(-44, 0, 0), RA=ang(18, 0, 0), LH=ang(34, -12, -22), LK=ang(-52, 0, 0), LA=ang(18, 0, 0),
		},
		Strike = {
			R=cf(0, -0.30, -0.44, -22, 0, 0), W=ang(-20, 0, 0), N=ang(18, 0, 0), RS=ang(96, -12, -16), RE=ang(8, 0, 0), RW=ang(28, 0, 0), LS=ang(96, 12, 16), LE=ang(8, 0, 0), LW=ang(28, 0, 0), RH=ang(-42, 8, 18), RK=ang(-18, 0, 0), RA=ang(-16, 0, 0), LH=ang(48, -8, -18), LK=ang(-62, 0, 0), LA=ang(20, 0, 0),
		},
	},

	-- Pure Leg-Kata (SkyStep & ThunderTalon): Arms stay disciplined in tight combat guard!
	Martial_Kick_1 = {
		WindupSec = 0.065, SnapSec = 0.085, HitstopSec = 0.040, RecoverSec = 0.16,
		LockLegs = true,
		Windup = {
			R=cf(0, -0.10, 0.08, 8, -42, 10), W=ang(4, -24, -8), N=ang(-4, 46, 0), RS=ang(64, -18, 18), RE=ang(92, 0, 0), LS=ang(72, 20, -18), LE=ang(88, 0, 0), RH=ang(78, -14, 28), RK=ang(-88, 0, 0), RA=ang(-22, 0, 0), LH=ang(-12, 12, -10), LK=ang(-24, 0, 0), LA=ang(10, 0, 0),
		},
		Strike = {
			R=cf(0, 0.12, -0.22, 22, 54, -22), W=ang(-10, -28, 14), N=ang(-8, -42, 10), RS=ang(58, -16, 22), RE=ang(94, 0, 0), LS=ang(68, 22, -20), LE=ang(90, 0, 0), RH=ang(116, -18, 34), RK=ang(-6, 0, 0), RA=ang(-32, 0, 0), LH=ang(-22, 16, -12), LK=ang(-18, 0, 0), LA=ang(8, 0, 0),
		},
	},

	Martial_Kick_2 = {
		WindupSec = 0.065, SnapSec = 0.090, HitstopSec = 0.040, RecoverSec = 0.16,
		LockLegs = true,
		Windup = {
			R=cf(0, -0.12, 0.06, 10, 48, -10), W=ang(4, 26, 8), N=ang(-4, -50, 0), RS=ang(72, -20, 18), RE=ang(88, 0, 0), LS=ang(64, 18, -18), LE=ang(92, 0, 0), LH=ang(82, 14, -28), LK=ang(-86, 0, 0), LA=ang(-20, 0, 0), RH=ang(-14, -12, 10), RK=ang(-24, 0, 0),
		},
		Strike = {
			R=cf(0, 0.16, -0.24, 24, -62, 24), W=ang(-10, 32, -14), N=ang(-8, 46, -10), RS=ang(68, -22, 20), RE=ang(92, 0, 0), LS=ang(58, 16, -22), LE=ang(94, 0, 0), LH=ang(120, 18, -36), LK=ang(-6, 0, 0), LA=ang(18, 0, 0), RH=ang(-24, -16, 12), RA=ang(14, 0, 0), RK=ang(-18, 0, 0),
		},
	},

	Martial_Kick_3 = {
		WindupSec = 0.080, SnapSec = 0.095, HitstopSec = 0.044, RecoverSec = 0.18,
		LockLegs = true,
		Windup = {
			R=cf(0, 0.24, 0.06, 26, -18, 0), W=ang(14, -12, 0), N=ang(-14, 14, 0), RS=ang(66, -18, 20), RE=ang(92, 0, 0), LS=ang(70, 18, -20), LE=ang(90, 0, 0), RH=ang(138, 0, 8), RK=ang(-12, 0, 0), RA=ang(18, 0, 0), LH=ang(-24, 0, -8), LK=ang(-26, 0, 0),
		},
		Strike = {
			R=cf(0, -0.26, -0.32, -18, 16, 0), W=ang(-16, 14, 0), N=ang(14, -14, 0), RS=ang(58, -16, 24), RE=ang(94, 0, 0), LS=ang(66, 18, -22), LE=ang(90, 0, 0), RH=ang(38, 0, 10), RK=ang(-14, 0, 0), RA=ang(22, 0, 0), LH=ang(-34, 0, -10), LK=ang(-28, 0, 0),
		},
	},

	Martial_Kick_4 = {
		WindupSec = 0.095, SnapSec = 0.105, HitstopSec = 0.050, RecoverSec = 0.24,
		LockLegs = true,
		Windup = {
			R=cf(0, 0.72, 0.12, 34, -24, -14), W=ang(12, -18, 0), N=ang(-18, 22, 0), RS=ang(68, -18, 24), RE=ang(90, 0, 0), LS=ang(72, 18, -24), LE=ang(90, 0, 0), RH=ang(96, 0, 16), RK=ang(-88, 0, 0), LH=ang(64, 0, -14), LK=ang(-82, 0, 0),
		},
		Strike = {
			R=cf(0, 0.18, -0.46, 46, 28, -18), W=ang(-12, -20, 0), N=ang(-22, -20, 0), RS=ang(54, -16, 28), RE=ang(94, 0, 0), LS=ang(64, 18, -26), LE=ang(92, 0, 0), RH=ang(118, 0, 14), RK=ang(-4, 0, 0), RA=ang(20, 0, 0), LH=ang(42, 0, -14), LK=ang(-76, 0, 0), LA=ang(-24, 0, 0),
		},
	},

	-- Claw / Void-Palm Kata (JadeDragon, SanguineVoidArt, ChronoVoidPalm)
	Martial_Claw_1 = {
		WindupSec = 0.065, SnapSec = 0.080, HitstopSec = 0.040, RecoverSec = 0.15,
		Windup = {
			R=cf(0, -0.22, 0.12, -8, -42, -6), W=ang(6, -38, 0), N=ang(4, 48, 0), RS=ang(124, -24, 52), RE=ang(54, 0, 0), RW=ang(26, 0, 0), LS=ang(52, 20, -24), LE=ang(74, 0, 0), RH=ang(-24, 0, 14), RK=ang(-28, 0, 0), LH=ang(28, 0, -14), LK=ang(-38, 0, 0),
		},
		Strike = {
			R=cf(0, -0.28, -0.32, -18, 44, 6), W=ang(-18, 48, 0), N=ang(14, -52, 0), RS=ang(58, 28, -44), RE=ang(24, 0, 0), RW=ang(-34, 0, -22), LS=ang(-24, 0, -32), LE=ang(48, 0, 0), RH=ang(34, 0, 14), RK=ang(-44, 0, 0), LH=ang(-32, 0, -14), LK=ang(-20, 0, 0),
		},
	},

	Martial_Claw_2 = {
		WindupSec = 0.065, SnapSec = 0.080, HitstopSec = 0.040, RecoverSec = 0.15,
		Windup = {
			R=cf(0, -0.24, 0.10, -8, 42, 6), W=ang(6, 38, 0), N=ang(4, -48, 0), LS=ang(124, 24, -52), LE=ang(54, 0, 0), LW=ang(26, 0, 0), RS=ang(52, -20, 24), RE=ang(74, 0, 0), RH=ang(28, 0, 14), RK=ang(-38, 0, 0), LH=ang(-24, 0, -14), LK=ang(-28, 0, 0),
		},
		Strike = {
			R=cf(0, -0.28, -0.32, -18, -44, -6), W=ang(-18, -48, 0), N=ang(14, 52, 0), LS=ang(58, -28, 44), LE=ang(24, 0, 0), LW=ang(-34, 0, 22), RS=ang(-24, 0, 32), RE=ang(48, 0, 0), RH=ang(-32, 0, 14), RK=ang(-20, 0, 0), LH=ang(34, 0, -14), LK=ang(-44, 0, 0),
		},
	},

	Martial_Claw_3 = {
		WindupSec = 0.070, SnapSec = 0.090, HitstopSec = 0.042, RecoverSec = 0.16,
		Windup = {
			R=cf(0, -0.20, -0.18, -14, 0, 0), W=ang(-12, 0, 0), RS=ang(104, -18, 48), RE=ang(24, 0, 0), RW=ang(24, 0, 0), LS=ang(104, 18, -48), LE=ang(24, 0, 0), LW=ang(24, 0, 0), RH=ang(26, 0, 14), RK=ang(-36, 0, 0), LH=ang(-24, 0, -14), LK=ang(-24, 0, 0),
		},
		Strike = {
			R=cf(0, -0.30, 0.14, 8, 0, 0), W=ang(10, 0, 0), RS=ang(42, 24, -28), RE=ang(78, 0, 0), RW=ang(-36, 0, 0), LS=ang(42, -24, 28), LE=ang(78, 0, 0), LW=ang(-36, 0, 0), RH=ang(-28, 0, 16), RK=ang(-34, 0, 0), LH=ang(32, 0, -16), LK=ang(-44, 0, 0),
		},
	},

	Martial_Claw_4 = {
		WindupSec = 0.095, SnapSec = 0.095, HitstopSec = 0.050, RecoverSec = 0.22,
		LockLegs = true,
		Windup = {
			R=cf(0, -0.32, 0.18, 16, 0, 0), W=ang(18, 0, 0), RS=ang(136, -24, 62), RE=ang(48, 0, 0), RW=ang(28, 0, 0), LS=ang(136, 24, -62), LE=ang(48, 0, 0), LW=ang(28, 0, 0), RH=ang(-32, 0, 18), RK=ang(-38, 0, 0), LH=ang(36, 0, -18), LK=ang(-48, 0, 0),
		},
		Strike = {
			R=cf(0, -0.30, -0.44, -24, 0, 0), W=ang(-22, 0, 0), RS=ang(78, 28, -36), RE=ang(18, 0, 0), RW=ang(-38, 0, -24), LS=ang(78, -28, 36), LE=ang(18, 0, 0), LW=ang(-38, 0, 24), RH=ang(-42, 0, 18), RK=ang(-18, 0, 0), LH=ang(48, 0, -18), LK=ang(-60, 0, 0),
		},
	},

	Martial_Z_Rush = {
		WindupSec = 0.085, SnapSec = 0.090, HitstopSec = 0.046, RecoverSec = 0.20,
		LockLegs = true,
		Windup = {
			R=cf(0, -0.36, 0.22, -16, -42, 0), W=ang(-12, -38, 0), N=ang(18, 50, 0), RS=ang(14, -22, 32), RE=ang(104, 0, 0), LS=ang(84, 24, -18), LE=ang(68, 0, 0), RH=ang(-38, 8, 16), RK=ang(-38, 0, 0), LH=ang(42, -8, -16), LK=ang(-56, 0, 0),
		},
		Strike = {
			R=cf(0, -0.28, -0.50, -24, 42, 0), W=ang(-20, 48, 0), N=ang(20, -54, 0), RS=ang(98, -12, -14), RE=ang(6, 0, 0), RW=ang(-18, 0, -24), LS=ang(-36, 0, -34), LE=ang(38, 0, 0), RH=ang(-46, 6, 14), RK=ang(-14, 0, 0), RA=ang(-18, 0, 0), LH=ang(50, -6, -14), LK=ang(-64, 0, 0), LA=ang(20, 0, 0),
		},
	},

	Martial_Z_Kick = {
		WindupSec = 0.080, SnapSec = 0.095, HitstopSec = 0.046, RecoverSec = 0.20,
		LockLegs = true,
		Windup = {
			R=cf(0, 0.28, 0.14, 22, -36, 0), W=ang(10, -22, 0), RS=ang(66, -18, 22), RE=ang(90, 0, 0), LS=ang(70, 18, -22), LE=ang(90, 0, 0), RH=ang(88, 0, 18), RK=ang(-92, 0, 0), LH=ang(34, 0, -14), LK=ang(-68, 0, 0),
		},
		Strike = {
			R=cf(0, 0.34, -0.48, 52, 34, -22), W=ang(-14, -24, 0), N=ang(-26, -24, 0), RS=ang(56, -16, 26), RE=ang(94, 0, 0), LS=ang(64, 18, -24), LE=ang(92, 0, 0), RH=ang(112, 0, 16), RK=ang(-4, 0, 0), RA=ang(-32, 0, 0), LH=ang(48, 0, -14), LK=ang(-84, 0, 0), LA=ang(-24, 0, 0),
		},
	},

	Martial_X_Uppercut = {
		WindupSec = 0.095, SnapSec = 0.095, HitstopSec = 0.048, RecoverSec = 0.22,
		LockLegs = true,
		Windup = {
			R=cf(0, -0.44, 0.12, -24, -36, 0), W=ang(-22, -34, 0), N=ang(18, 38, 0), RS=ang(-12, -18, 28), RE=ang(106, 0, 0), LS=ang(68, 20, -20), LE=ang(84, 0, 0), RH=ang(38, 0, 16), RK=ang(-58, 0, 0), LH=ang(-32, 0, -16), LK=ang(-48, 0, 0),
		},
		Strike = {
			R=cf(0, 0.56, -0.24, 18, 38, 0), W=ang(20, 42, 0), N=ang(-14, -40, 0), RS=ang(154, -14, -8), RE=ang(22, 0, 0), LS=ang(48, 18, -28), LE=ang(76, 0, 0), RH=ang(64, 0, 12), RK=ang(-76, 0, 0), RA=ang(-24, 0, 0), LH=ang(-32, 0, -12), LK=ang(-22, 0, 0), LA=ang(-26, 0, 0),
		},
	},

	Martial_C_Flurry = {
		WindupSec = 0.075, SnapSec = 0.240, HitstopSec = 0.048, RecoverSec = 0.22,
		LockLegs = true,
		Windup = {
			R=cf(0, -0.30, 0.14, -10, 0, 0), W=ang(-8, 0, 0), RS=ang(42, -16, 28), RE=ang(96, 0, 0), LS=ang(42, 16, -28), LE=ang(96, 0, 0), RH=ang(-28, 0, 18), RK=ang(-38, 0, 0), LH=ang(34, 0, -18), LK=ang(-48, 0, 0),
		},
		Strike = {
			R=cf(0, -0.28, -0.40, -20, 0, 0), W=ang(-18, 0, 0), RS=ang(98, -10, -12), RE=ang(8, 0, 0), RW=ang(24, 0, 0), LS=ang(98, 10, 12), LE=ang(8, 0, 0), LW=ang(24, 0, 0), RH=ang(-38, 0, 18), RK=ang(-20, 0, 0), LH=ang(46, 0, -18), LK=ang(-58, 0, 0),
		},
		-- Rapid 6-fist Ashura / Paragon alternating barrage across Beat 2
		DynamicFn = function(info, pose, rWep, lWep)
			if info.Beat == 2 then
				local cyc = info.BeatU * math.pi * 6
				local rExt = math.max(0, math.sin(cyc))
				local lExt = math.max(0, -math.sin(cyc))
				local twist = math.sin(cyc) * 32
				pose.Waist = ang(-16, twist, 0)
				pose.Neck = ang(14, -twist * 0.85, 0)
				pose.RightShoulder = ang(38 + 64 * rExt, -12, 22 - 34 * rExt)
				pose.RightElbow = ang(96 * (1 - rExt) + 6, 0, 0)
				pose.LeftShoulder = ang(38 + 64 * lExt, 12, -22 + 34 * lExt)
				pose.LeftElbow = ang(96 * (1 - lExt) + 6, 0, 0)
			end
			return rWep, lWep
		end,
	},

	Martial_C_Drill = {
		WindupSec = 0.085, SnapSec = 0.220, HitstopSec = 0.046, RecoverSec = 0.22,
		LockLegs = true,
		Windup = {
			R=cf(0, 0.22, 0.10, 18, -32, 0), RS=ang(66, -18, 20), RE=ang(92, 0, 0), LS=ang(66, 18, -20), LE=ang(92, 0, 0), RH=ang(84, 0, 14), RK=ang(-86, 0, 0), LH=ang(42, 0, -14), LK=ang(-72, 0, 0),
		},
		Strike = {
			R=cf(0, 0.36, -0.44, 64, 0, 0), RS=ang(58, -16, 22), RE=ang(96, 0, 0), LS=ang(58, 16, -22), LE=ang(96, 0, 0), RH=ang(106, 0, 8), RK=ang(-4, 0, 0), RA=ang(-34, 0, 0), LH=ang(58, 0, -10), LK=ang(-88, 0, 0),
		},
		DynamicFn = function(info, pose, rWep, lWep)
			if info.Beat == 2 then
				pose.Root = cf(0, 0.34, -0.40 * info.BeatU, 62, 0, 720 * info.BeatU)
			end
			return rWep, lWep
		end,
	},

	Martial_Palm_Burst = {
		WindupSec = 0.100, SnapSec = 0.095, HitstopSec = 0.048, RecoverSec = 0.22,
		LockLegs = true,
		Windup = {
			R=cf(0, -0.30, 0.18, 10, -28, 0), W=ang(12, -24, 0), RS=ang(44, -22, 38), RE=ang(88, 0, 0), RW=ang(34, 0, 0), LS=ang(44, 22, -38), LE=ang(88, 0, 0), LW=ang(34, 0, 0), RH=ang(-30, 8, 18), RK=ang(-36, 0, 0), LH=ang(36, -8, -18), LK=ang(-48, 0, 0),
		},
		Strike = {
			R=cf(0, -0.26, -0.42, -20, 0, 0), W=ang(-18, 0, 0), N=ang(16, 0, 0), RS=ang(94, -8, -12), RE=ang(10, 0, 0), RW=ang(42, 0, 0), LS=ang(94, 8, 12), LE=ang(10, 0, 0), LW=ang(42, 0, 0), RH=ang(-40, 6, 18), RK=ang(-18, 0, 0), LH=ang(46, -6, -18), LK=ang(-58, 0, 0),
		},
	},

	-- ------------------------------------------------------------------------
	-- 7. AETHER CORES (Slot 2: 12 Cores Elemental Casts, SkySphere, GroundSlam)
	-- ------------------------------------------------------------------------
	Core_M1_1 = {
		WindupSec = 0.065, SnapSec = 0.080, HitstopSec = 0.036, RecoverSec = 0.15,
		Windup = {
			R=cf(0, -0.12, 0.08, 4, -30, 0), W=ang(6, -32, 0), N=ang(-2, 36, 0), RS=ang(76, -18, 38), RE=ang(64, 0, 0), RW=ang(22, 0, 0), LS=ang(-18, 12, -24), LE=ang(42, 0, 0), RH=ang(-16, 0, 10), RK=ang(-20, 0, 0), LH=ang(20, 0, -10), LK=ang(-28, 0, 0),
		},
		Strike = {
			R=cf(0, -0.16, -0.24, -12, 32, 0), W=ang(-14, 38, 0), N=ang(10, -42, 0), RS=ang(96, -8, -12), RE=ang(10, 0, 0), RW=ang(36, 0, 0), LS=ang(-26, 0, -32), LE=ang(36, 0, 0), RH=ang(24, 0, 12), RK=ang(-34, 0, 0), LH=ang(-24, 0, -12), LK=ang(-18, 0, 0),
		},
	},

	Core_M1_2 = {
		WindupSec = 0.065, SnapSec = 0.080, HitstopSec = 0.036, RecoverSec = 0.15,
		Windup = {
			R=cf(0, -0.14, 0.08, 4, 32, 0), W=ang(6, 34, 0), N=ang(-2, -38, 0), LS=ang(82, 22, -44), LE=ang(58, 0, 0), LW=ang(22, 0, 0), RS=ang(46, -14, 22), RE=ang(62, 0, 0), RH=ang(20, 0, 10), RK=ang(-28, 0, 0), LH=ang(-16, 0, -10), LK=ang(-20, 0, 0),
		},
		Strike = {
			R=cf(0, -0.18, -0.24, -12, -36, 0), W=ang(-14, -40, 0), N=ang(10, 44, 0), LS=ang(92, -16, 36), LE=ang(14, 0, 0), LW=ang(32, 0, 0), RS=ang(-22, 0, 28), RE=ang(40, 0, 0), RH=ang(-24, 0, 12), RK=ang(-18, 0, 0), LH=ang(26, 0, -12), LK=ang(-34, 0, 0),
		},
	},

	Core_M1_3 = {
		WindupSec = 0.070, SnapSec = 0.095, HitstopSec = 0.038, RecoverSec = 0.16,
		Windup = {
			R=cf(0, -0.20, 0.06, -10, -38, 0), W=ang(-8, -36, 0), RS=ang(34, -22, 42), RE=ang(52, 0, 0), LS=ang(68, 22, -32), LE=ang(54, 0, 0), RH=ang(-22, 0, 12), RK=ang(-26, 0, 0), LH=ang(26, 0, -12), LK=ang(-34, 0, 0),
		},
		Strike = {
			R=cf(0, 0.18, -0.22, 8, 38, 0), W=ang(10, 42, 0), RS=ang(128, -18, 36), RE=ang(16, 0, 0), RW=ang(28, 0, 0), LS=ang(82, 16, -38), LE=ang(28, 0, 0), RH=ang(32, 0, 12), RK=ang(-42, 0, 0), LH=ang(-24, 0, -12), LK=ang(-24, 0, 0),
		},
	},

	Core_M1_4 = {
		WindupSec = 0.090, SnapSec = 0.095, HitstopSec = 0.048, RecoverSec = 0.22,
		LockLegs = true,
		Windup = {
			R=cf(0, -0.26, 0.14, 14, 0, 0), W=ang(16, 0, 0), RS=ang(52, -24, 48), RE=ang(76, 0, 0), LS=ang(52, 24, -48), LE=ang(76, 0, 0), RH=ang(-26, 0, 16), RK=ang(-34, 0, 0), LH=ang(30, 0, -16), LK=ang(-42, 0, 0),
		},
		Strike = {
			R=cf(0, -0.22, -0.36, -18, 0, 0), W=ang(-18, 0, 0), N=ang(16, 0, 0), RS=ang(98, -12, 18), RE=ang(10, 0, 0), RW=ang(40, 0, 0), LS=ang(98, 12, -18), LE=ang(10, 0, 0), LW=ang(40, 0, 0), RH=ang(-36, 0, 16), RK=ang(-18, 0, 0), LH=ang(42, 0, -16), LK=ang(-54, 0, 0),
		},
	},

	Core_Cast_Beam = {
		WindupSec = 0.130, SnapSec = 0.100, HitstopSec = 0.050, RecoverSec = 0.28,
		LockLegs = true,
		Windup = {
			R=cf(0, -0.30, 0.18, -6, -46, 0), W=ang(-4, -40, 0), N=ang(8, 52, 0), RS=ang(22, -24, 34), RE=ang(88, 0, 0), RW=ang(28, 0, 0), LS=ang(48, 36, 28), LE=ang(78, 0, 0), LW=ang(28, 0, 0), RH=ang(-32, 10, 18), RK=ang(-36, 0, 0), RA=ang(14, 0, 0), LH=ang(38, -8, -18), LK=ang(-50, 0, 0), LA=ang(16, 0, 0),
		},
		Strike = {
			R=cf(0, -0.28, -0.38, -18, 0, 0), W=ang(-16, 0, 0), N=ang(16, 0, 0), RS=ang(94, -14, -14), RE=ang(10, 0, 0), RW=ang(44, 0, 0), LS=ang(94, 14, 14), LE=ang(10, 0, 0), LW=ang(44, 0, 0), RH=ang(-38, 8, 18), RK=ang(-18, 0, 0), RA=ang(-14, 0, 0), LH=ang(44, -8, -18), LK=ang(-56, 0, 0), LA=ang(18, 0, 0),
		},
	},

	Core_Cast_SkySphere = {
		WindupSec = 0.160, SnapSec = 0.115, HitstopSec = 0.050, RecoverSec = 0.30,
		LockLegs = true,
		Windup = {
			R=cf(0, 0.56, 0.08, 22, 0, 0), W=ang(20, 0, 0), N=ang(24, 0, 0), RS=ang(162, -16, 36), RE=ang(22, 0, 0), RW=ang(32, 0, 0), LS=ang(162, 16, -36), LE=ang(22, 0, 0), LW=ang(32, 0, 0), RH=ang(36, 0, 12), RK=ang(-54, 0, 0), RA=ang(-20, 0, 0), LH=ang(-22, 0, -12), LK=ang(-36, 0, 0), LA=ang(-20, 0, 0),
		},
		Strike = {
			R=cf(0, 0.22, -0.34, -22, 0, 0), W=ang(-20, 0, 0), N=ang(14, 0, 0), RS=ang(74, -10, 18), RE=ang(14, 0, 0), RW=ang(-28, 0, 0), LS=ang(74, 10, -18), LE=ang(14, 0, 0), LW=ang(-28, 0, 0), RH=ang(44, 0, 14), RK=ang(-56, 0, 0), LH=ang(-34, 0, -14), LK=ang(-26, 0, 0),
		},
	},

	Core_Cast_GroundSlam = {
		WindupSec = 0.135, SnapSec = 0.110, HitstopSec = 0.050, RecoverSec = 0.28,
		LockLegs = true,
		Windup = {
			R=cf(0, 0.78, 0.06, 20, -24, 0), W=ang(18, -22, 0), N=ang(-14, 24, 0), RS=ang(158, -14, 26), RE=ang(34, 0, 0), LS=ang(64, 18, -32), LE=ang(54, 0, 0), RH=ang(66, 0, 12), RK=ang(-82, 0, 0), RA=ang(-24, 0, 0), LH=ang(-28, 0, -12), LK=ang(-42, 0, 0), LA=ang(-24, 0, 0),
		},
		-- Classic 3-point superhero ground-fist impact
		Strike = {
			R=cf(0, -0.52, -0.36, -34, 26, 0), W=ang(-28, 28, 0), N=ang(32, -26, 0), RS=ang(46, -8, -10), RE=ang(14, 0, 0), LS=ang(-44, 0, -38), LE=ang(28, 0, 0), RH=ang(64, 0, 16), RK=ang(-78, 0, 0), RA=ang(24, 0, 0), LH=ang(-48, 0, -16), LK=ang(-56, 0, 0), LA=ang(-12, 0, 0),
		},
	},

	Core_Cast_ChainBolt = {
		WindupSec = 0.105, SnapSec = 0.085, HitstopSec = 0.046, RecoverSec = 0.22,
		Windup = {
			R=cf(0, -0.10, 0.10, 14, -32, 0), W=ang(14, -28, 0), N=ang(12, 34, 0), RS=ang(164, -12, 22), RE=ang(16, 0, 0), LS=ang(32, 24, -22), LE=ang(76, 0, 0), RH=ang(-22, 0, 14), RK=ang(-24, 0, 0), LH=ang(26, 0, -14), LK=ang(-34, 0, 0),
		},
		Strike = {
			R=cf(0, -0.22, -0.28, -14, 28, 0), W=ang(-12, 32, 0), N=ang(12, -34, 0), RS=ang(92, -6, 6), RE=ang(6, 0, 0), RW=ang(-18, 0, 0), LS=ang(-28, 12, -32), LE=ang(48, 0, 0), RH=ang(30, 0, 14), RK=ang(-40, 0, 0), LH=ang(-28, 0, -14), LK=ang(-20, 0, 0),
		},
	},

	Core_Cast_Vortex = {
		WindupSec = 0.125, SnapSec = 0.105, HitstopSec = 0.048, RecoverSec = 0.24,
		LockLegs = true,
		Windup = {
			R=cf(0, -0.18, 0.12, 16, 0, 0), W=ang(18, 0, 0), N=ang(8, 0, 0), RS=ang(96, -24, 74), RE=ang(24, 0, 0), RW=ang(28, 0, 0), LS=ang(96, 24, -74), LE=ang(24, 0, 0), LW=ang(28, 0, 0), RH=ang(-24, 0, 18), RK=ang(-30, 0, 0), LH=ang(28, 0, -18), LK=ang(-38, 0, 0),
		},
		Strike = {
			R=cf(0, -0.32, -0.24, -20, 0, 0), W=ang(-22, 0, 0), N=ang(16, 0, 0), RS=ang(78, 28, -32), RE=ang(64, 0, 0), RW=ang(-34, 0, 0), LS=ang(78, -28, 32), LE=ang(64, 0, 0), LW=ang(-34, 0, 0), RH=ang(34, 0, 18), RK=ang(-46, 0, 0), LH=ang(-30, 0, -18), LK=ang(-26, 0, 0),
		},
	},

	Core_Cast_Wave = {
		WindupSec = 0.095, SnapSec = 0.090, HitstopSec = 0.042, RecoverSec = 0.20,
		Windup = {
			R=cf(0, -0.20, 0.12, 6, -42, 0), W=ang(8, -38, 0), N=ang(-4, 46, 0), RS=ang(108, -24, 58), RE=ang(42, 0, 0), LS=ang(44, 18, -26), LE=ang(56, 0, 0), RH=ang(-24, 0, 14), RK=ang(-28, 0, 0), LH=ang(28, 0, -14), LK=ang(-38, 0, 0),
		},
		Strike = {
			R=cf(0, -0.24, -0.32, -16, 44, 0), W=ang(-16, 46, 0), N=ang(12, -48, 0), RS=ang(82, 26, -42), RE=ang(12, 0, 0), RW=ang(32, 0, 0), LS=ang(-28, 0, -34), LE=ang(36, 0, 0), RH=ang(34, 0, 14), RK=ang(-44, 0, 0), LH=ang(-32, 0, -14), LK=ang(-20, 0, 0),
		},
	},

	Core_Transform_Roar = {
		WindupSec = 0.140, SnapSec = 0.120, HitstopSec = 0.050, RecoverSec = 0.30,
		LockLegs = true,
		Windup = {
			R=cf(0, -0.36, 0.06, -24, 0, 0), W=ang(-26, 0, 0), N=ang(-18, 0, 0), RS=ang(64, 28, -38), RE=ang(98, 0, 0), LS=ang(64, -28, 38), LE=ang(98, 0, 0), RH=ang(28, 0, 18), RK=ang(-48, 0, 0), LH=ang(28, 0, -18), LK=ang(-48, 0, 0),
		},
		Strike = {
			R=cf(0, 0.24, -0.14, 28, 0, 0), W=ang(26, 0, 0), N=ang(28, 0, 0), RS=ang(48, -28, 72), RE=ang(42, 0, 0), LS=ang(48, 28, -72), LE=ang(42, 0, 0), RH=ang(-18, 0, 22), RK=ang(-22, 0, 0), LH=ang(-18, 0, -22), LK=ang(-22, 0, 0),
		},
	},

	Core_Dash_Pose = {
		WindupSec = 0.055, SnapSec = 0.110, HitstopSec = 0.036, RecoverSec = 0.18,
		LockLegs = true,
		Windup = {
			R=cf(0, -0.30, 0.10, -22, -18, 0), W=ang(-14, -14, 0), N=ang(20, 16, 0), RS=ang(42, -16, 24), RE=ang(68, 0, 0), LS=ang(-34, 0, -28), LE=ang(42, 0, 0), RH=ang(36, 0, 12), RK=ang(-52, 0, 0), LH=ang(-32, 0, -12), LK=ang(-34, 0, 0),
		},
		Strike = {
			R=cf(0, -0.20, -0.44, -36, 12, 0), W=ang(-14, 12, 0), N=ang(28, -12, 0), RS=ang(98, -10, 12), RE=ang(14, 0, 0), RW=ang(24, 0, 0), LS=ang(-54, 0, -30), LE=ang(28, 0, 0), RH=ang(52, 0, 10), RK=ang(-64, 0, 0), RA=ang(-18, 0, 0), LH=ang(-44, 0, -10), LK=ang(-26, 0, 0), LA=ang(-22, 0, 0),
		},
	},

	-- ------------------------------------------------------------------------
	-- 8. GUNS / RANGED (Slot 4: Pistol, DualPistols, Railgun, Cannon, Bow, VoidLyre)
	-- ------------------------------------------------------------------------
	Gun_Pistol_Fire = {
		WindupSec = 0.050, SnapSec = 0.070, HitstopSec = 0.036, RecoverSec = 0.15,
		Windup = {
			R=cf(0, -0.10, -0.06, -4, -30, 0), W=ang(-2, 26, 0), N=ang(2, 6, 0), RS=ang(88, -10, 6), RE=ang(8, 0, 0), LS=ang(38, 18, -18), LE=ang(64, 0, 0), RH=ang(-16, 0, 10), RK=ang(-18, 0, 0), LH=ang(18, 0, -10), LK=ang(-22, 0, 0),
		},
		Strike = {
			R=cf(0, -0.08, 0.14, 6, -34, 0), W=ang(8, 28, 0), N=ang(-4, 6, 0), RS=ang(114, -12, 8), RE=ang(24, 0, 0), RW=ang(18, 0, 0), LS=ang(32, 18, -22), LE=ang(68, 0, 0), RH=ang(-20, 0, 12), RK=ang(-22, 0, 0), LH=ang(22, 0, -12), LK=ang(-26, 0, 0), RWep=cf(0, 0, 0, 14, 0, 0),
		},
	},

	Gun_DualPistol_Fire = {
		WindupSec = 0.050, SnapSec = 0.075, HitstopSec = 0.036, RecoverSec = 0.15,
		Windup = {
			R=cf(0, -0.14, -0.08, -6, 0, 0), W=ang(-4, 0, 0), RS=ang(88, -8, 12), RE=ang(10, 0, 0), LS=ang(88, 8, -12), LE=ang(10, 0, 0), RH=ang(-18, 0, 12), RK=ang(-22, 0, 0), LH=ang(20, 0, -12), LK=ang(-26, 0, 0),
		},
		Strike = {
			R=cf(0, -0.12, 0.16, 8, 0, 0), W=ang(8, 0, 0), RS=ang(112, -10, 16), RE=ang(26, 0, 0), LS=ang(112, 10, -16), LE=ang(26, 0, 0), RH=ang(-22, 0, 14), RK=ang(-24, 0, 0), LH=ang(24, 0, -14), LK=ang(-28, 0, 0), RWep=cf(0, 0, 0, 16, 0, 0), LWep=cf(0, 0, 0, 16, 0, 0),
		},
	},

	Gun_Railgun_Brace = {
		WindupSec = 0.075, SnapSec = 0.080, HitstopSec = 0.044, RecoverSec = 0.20,
		Windup = {
			R=cf(0, -0.18, -0.08, -6, -42, 0), W=ang(-4, 34, 0), N=ang(6, 10, -8), RS=ang(78, -18, 14), RE=ang(44, 0, 0), LS=ang(84, 34, 28), LE=ang(48, 0, 0), RH=ang(-24, 6, 14), RK=ang(-28, 0, 0), LH=ang(28, -6, -14), LK=ang(-36, 0, 0), RWep=cf(0, 0, 0, -8, 12, 0),
		},
		Strike = {
			R=cf(0, -0.16, 0.24, 10, -46, 0), W=ang(12, 36, 0), N=ang(-6, 10, -6), RS=ang(98, -20, 16), RE=ang(56, 0, 0), LS=ang(102, 36, 26), LE=ang(58, 0, 0), RH=ang(-30, 6, 16), RK=ang(-34, 0, 0), LH=ang(34, -6, -16), LK=ang(-40, 0, 0), RWep=cf(0, 0, 0, 12, 12, 0),
		},
	},

	Gun_Cannon_Fire = {
		WindupSec = 0.085, SnapSec = 0.085, HitstopSec = 0.048, RecoverSec = 0.22,
		LockLegs = true,
		Windup = {
			R=cf(0, -0.24, -0.10, -8, -38, 0), W=ang(-6, 30, 0), RS=ang(64, -16, 18), RE=ang(52, 0, 0), LS=ang(76, 32, 26), LE=ang(54, 0, 0), RH=ang(-28, 8, 16), RK=ang(-34, 0, 0), LH=ang(32, -8, -16), LK=ang(-44, 0, 0),
		},
		Strike = {
			R=cf(0, -0.22, 0.34, 16, -42, 0), W=ang(18, 34, 0), RS=ang(92, -18, 22), RE=ang(66, 0, 0), LS=ang(98, 34, 24), LE=ang(64, 0, 0), RH=ang(-36, 8, 18), RK=ang(-42, 0, 0), LH=ang(38, -8, -18), LK=ang(-46, 0, 0), RWep=cf(0, 0, 0, 18, 8, 0),
		},
	},

	Gun_Bow_Draw = {
		WindupSec = 0.095, SnapSec = 0.075, HitstopSec = 0.040, RecoverSec = 0.18,
		Windup = {
			R=cf(0, -0.14, 0.08, 2, -56, 0), W=ang(2, 46, 0), N=ang(0, 12, 0), RS=ang(92, -14, 28), RE=ang(108, 0, 0), LS=ang(90, 12, -8), LE=ang(8, 0, 0), RH=ang(-20, 0, 14), RK=ang(-22, 0, 0), LH=ang(22, 0, -14), LK=ang(-26, 0, 0), RWep=cf(-0.35, 0.15, 0, 0, 18, 0),
		},
		Strike = {
			R=cf(0, -0.14, 0.14, 4, -58, 0), W=ang(4, 48, 0), N=ang(0, 12, 0), RS=ang(88, -22, 54), RE=ang(32, 0, 0), LS=ang(96, 12, -8), LE=ang(6, 0, 0), RH=ang(-22, 0, 14), RK=ang(-24, 0, 0), LH=ang(24, 0, -14), LK=ang(-28, 0, 0), RWep=cf(-0.30, 0.15, 0, 8, 18, 0),
		},
	},

	Gun_VoidLyre_Strum = {
		WindupSec = 0.070, SnapSec = 0.140, HitstopSec = 0.042, RecoverSec = 0.20,
		Windup = {
			R=cf(0, -0.14, 0.06, 8, -28, -4), W=ang(10, -18, 0), N=ang(6, 20, -8), RS=ang(74, 18, -22), RE=ang(78, 0, 0), LS=ang(68, 26, -24), LE=ang(56, 0, 0), RH=ang(-18, 0, 14), RK=ang(-22, 0, 0), LH=ang(22, 0, -14), LK=ang(-30, 0, 0), RWep=cf(-0.22, -0.08, 0, 14, 34, -22),
		},
		Strike = {
			R=cf(0, -0.18, -0.12, -8, -22, 6), W=ang(-6, -12, 0), N=ang(10, 16, 6), RS=ang(32, -24, 52), RE=ang(24, 0, 0), LS=ang(74, 28, -20), LE=ang(52, 0, 0), RH=ang(-16, 0, 16), RK=ang(-20, 0, 0), LH=ang(26, 0, -16), LK=ang(-34, 0, 0), RWep=cf(-0.20, -0.04, 0, 18, 38, -18),
		},
		DynamicFn = function(info, pose, rWep, lWep)
			if info.Beat == 2 then
				local strum = math.sin(info.BeatU * math.pi * 2)
				pose.RightShoulder = ang(56 - 26 * strum, -6 - 18 * strum, 16 + 38 * strum)
				pose.RightElbow = ang(54 - 28 * strum, 0, 0)
			end
			return rWep, lWep
		end,
	},
}


-- ============================================================================

local POSE_SHORT_KEYS = {
	R = "Root", W = "Waist", N = "Neck",
	RS = "RightShoulder", RE = "RightElbow", RW = "RightWrist",
	LS = "LeftShoulder", LE = "LeftElbow", LW = "LeftWrist",
	RH = "RightHip", RK = "RightKnee", RA = "RightAnkle",
	LH = "LeftHip", LK = "LeftKnee", LA = "LeftAnkle",
	RWep = "RightWeapon", LWep = "LeftWeapon",
}
local function expandPoseKeys(tbl)
	if type(tbl) ~= "table" then return end
	for shortKey, fullKey in pairs(POSE_SHORT_KEYS) do
		local v = tbl[shortKey]
		if v ~= nil then
			tbl[fullKey] = v
			tbl[shortKey] = nil
		end
	end
end
for _, clipDef in pairs(CLIPS) do
	expandPoseKeys(clipDef.Windup)
	expandPoseKeys(clipDef.Strike)
end

-- ============================================================================
-- SERVER & BLUEPRINT POSE-CLIP ALIASES + 20 ARCHETYPE MAPPINGS
-- ============================================================================
local CLIP_ALIASES = {
	-- Shared Blueprint shorthands
	Martial_Palm = "Martial_Palm_Burst",
	Martial_Uppercut = "Martial_X_Uppercut",
	Martial_Flurry = "Martial_C_Flurry",
	Martial_Rush = "Martial_Z_Rush",
	Martial_Drill = "Martial_C_Drill",
	Martial_Kick = "Martial_Z_Kick",
	Spear_Z = "Spear_Z_Thrust",
	Spear_X = "Spear_X_PoleVault",
	Spear_C = "Spear_M1_3",
	Spear_V = "Spear_M1_4",
	Spear_F = "Core_Dash_Pose",
	Katana_Z = "Katana_Z_IaiDraw",
	Katana_X = "Katana_X_Crescent",
	Katana_C = "Katana_M1_3",
	Katana_V = "Katana_Z_IaiDraw",
	Katana_F = "Core_Dash_Pose",
	Greatsword_Z = "Greatsword_Z_EarthSplit",
	Greatsword_X = "Greatsword_X_Guillotine",
	Greatsword_C = "Greatsword_M1_3",
	Greatsword_V = "Greatsword_M1_4",
	Greatsword_F = "Core_Dash_Pose",
	DualBlades_Z = "DualBlades_Z_Blitz",
	DualBlades_X = "DualBlades_X_Spin",
	DualBlades_C = "DualBlades_M1_3",
	DualBlades_V = "DualBlades_M1_4",
	DualBlades_F = "Core_Dash_Pose",
	Scythe_Z = "Scythe_Z_Hook",
	Scythe_X = "Scythe_X_Rift",
	Scythe_C = "Scythe_M1_3",
	Scythe_V = "Scythe_M1_4",
	Scythe_F = "Core_Dash_Pose",
	Gun_Guitar_Strum = "Gun_VoidLyre_Strum",
	PistolRifle_M1 = "Gun_Pistol_Fire",
	DualPistols_M1 = "Gun_DualPistol_Fire",
	Railgun_M1 = "Gun_Railgun_Brace",
	Cannon_M1 = "Gun_Cannon_Fire",
	AcousticGuitar_M1 = "Gun_VoidLyre_Strum",
	VoidLyre_M1 = "Gun_VoidLyre_Strum",
	Bow_M1 = "Gun_Bow_Draw",

	-- Server SkybreakSkillMechanicsService Aether Core PoseClips
	WindSlashCast = "Core_Cast_Wave",
	VortexRaise = "Core_Cast_Vortex",
	JetstreamBlink = "Core_Dash_Pose",
	SkyCastRaise = "Core_Cast_SkySphere",
	SkyFlightBurst = "Core_Dash_Pose",
	GroundWaveSlash = "Core_Cast_Wave",
	CoffinClutch = "Core_Cast_Vortex",
	SandstormSpin = "Core_Cast_Vortex",
	GroundSlamDrop = "Core_Cast_GroundSlam",
	SandFlightStream = "Core_Dash_Pose",
	RapidPalmVolley = "Martial_C_Flurry",
	JetFistRush = "Martial_Z_Rush",
	SolarEmperorRaise = "Core_Cast_SkySphere",
	SolarFlightJet = "Core_Dash_Pose",
	GroundFrostSweep = "Core_Cast_Wave",
	FrostLanceThrust = "Core_Cast_Beam",
	GlacialDomain = "Core_Cast_Vortex",
	AbsoluteZeroStomp = "Core_Cast_GroundSlam",
	FrostSkateDash = "Core_Dash_Pose",
	ThunderSnapCast = "Core_Cast_ChainBolt",
	ElThorCall = "Core_Cast_ChainBolt",
	StormCageBrace = "Core_Cast_Vortex",
	RaigoSkyRaise = "Core_Cast_SkySphere",
	ThunderBlinkStep = "Core_Dash_Pose",
	PhotonFingerBeam = "Core_Cast_ChainBolt",
	SacredJewelsBarrage = "Core_Cast_SkySphere",
	MirrorKickDash = "Martial_Z_Kick",
	CelestialJudgmentRaise = "Core_Cast_SkySphere",
	LightStarFlight = "Core_Dash_Pose",
	MagmaFistPunch = "Martial_Punch_4",
	MagmaHoundRush = "Martial_Z_Rush",
	LavaGeyserStomp = "Core_Cast_GroundSlam",
	VolcanicPlumeCall = "Core_Cast_SkySphere",
	MagmaJetFlight = "Core_Dash_Pose",
	GravityRepulsePalm = "Martial_Palm_Burst",
	SingularityCrush = "Core_Cast_Vortex",
	TectonicPress = "Core_Cast_GroundSlam",
	AstralMeteorSummon = "Core_Cast_SkySphere",
	GravityBoulderHover = "Core_Dash_Pose",
	RiftBlinkSever = "Katana_Z_IaiDraw",
	DimensionPhaseStep = "Core_Dash_Pose",
	WorldGateOpen = "Core_Cast_Vortex",
	DimensionCollapse = "Core_Cast_Vortex",
	PortalFlashWarp = "Core_Dash_Pose",
	TitanShiftAscend = "Core_Transform_Roar",
	HeavenlyPalmLeap = "Core_Cast_GroundSlam",
	JudgmentPillarRing = "Core_Cast_ChainBolt",
	TwilightHaloBurst = "Core_Cast_SkySphere",
	TitanSeismicBound = "Core_Dash_Pose",
	GildedFistCannon = "Martial_Punch_4",
	PastrySpikeErupt = "Core_Cast_GroundSlam",
	ClotheslineWheelRoll = "Core_Dash_Pose",
	FusilladeRingGates = "Martial_C_Flurry",
	RollerDonutDash = "Core_Dash_Pose",
	DragonHeatBreath = "Core_Cast_Beam",
	DraconicTalonDive = "Martial_Claw_4",
	DragonFireShower = "Core_Cast_SkySphere",
	DragonSovereignAscend = "Core_Transform_Roar",
	WyrmWingRush = "Core_Dash_Pose",

	-- Server Weapon PoseClips
	SpearTriplePoke = "Spear_M1_2",
	SpearVaultPierce = "Spear_M1_4",
	SpearSkewerCharge = "Spear_Z_Thrust",
	SpearDragonDive = "Spear_X_PoleVault",
	SpearTridentSurge = "Spear_M1_2",
	SpearHeavenFall = "Spear_M1_4",
	SpearVaultLunge = "Core_Dash_Pose",
	KatanaIaiBlink = "Katana_Z_IaiDraw",
	KatanaCrescentWave = "Katana_X_Crescent",
	KatanaTempestStep = "Katana_M1_3",
	KatanaJudgmentCut = "Katana_Z_IaiDraw",
	KatanaGaleStep = "Core_Dash_Pose",
	GreatswordEarthsplit = "Greatsword_Z_EarthSplit",
	GreatswordChargedCrescent = "Greatsword_Z_EarthSplit",
	GreatswordColossusSpin = "Greatsword_M1_3",
	GreatswordCraterLeap = "Greatsword_X_Guillotine",
	GreatswordCataclysm = "Greatsword_M1_4",
	GreatswordShoulderCharge = "Core_Dash_Pose",
	DualCrossBlitz = "DualBlades_Z_Blitz",
	DualBladeCyclone = "DualBlades_X_Spin",
	DualPhantomDance = "DualBlades_M1_3",
	DualEclipseFrenzy = "DualBlades_M1_4",
	DualShadowDash = "Core_Dash_Pose",
	ScytheReapPull = "Scythe_Z_Hook",
	ScytheGuillotineBlink = "Scythe_X_Rift",
	ScytheSoulVortex = "Scythe_M1_3",
	ScytheReaperEclipse = "Scythe_M1_4",
	ScytheWraithGlide = "Core_Dash_Pose",

	-- Server Gun PoseClips
	GunDeadeyeSnap = "Gun_Pistol_Fire",
	GunFanBarrage = "Gun_Pistol_Fire",
	GunBackstepVault = "Core_Dash_Pose",
	GunOrbitalLock = "Gun_Pistol_Fire",
	GunTacticalSlide = "Core_Dash_Pose",
	RailgunOverchargeBrace = "Gun_Railgun_Brace",
	RailgunPrismSplit = "Gun_Railgun_Brace",
	RailgunCryoCell = "Gun_Railgun_Brace",
	RailgunOrbitalZero = "Gun_Railgun_Brace",
	RailgunThrusterStep = "Core_Dash_Pose",
	CannonMortarBrace = "Gun_Cannon_Fire",
	CannonNapalmWell = "Gun_Cannon_Fire",
	CannonSiegeSalvo = "Gun_Cannon_Fire",
	CannonHellfireRain = "Gun_Cannon_Fire",
	CannonRecoilBlast = "Core_Dash_Pose",
	GuitarPowerChord = "Gun_VoidLyre_Strum",
	GuitarRequiemAmp = "Gun_VoidLyre_Strum",
	GuitarResonanceRiff = "Gun_VoidLyre_Strum",
	GuitarVoidSymphony = "Gun_VoidLyre_Strum",
	GuitarEchoGlide = "Core_Dash_Pose",
	BowSplitVolley = "Gun_Bow_Draw",
	BowTempestSnipe = "Gun_Bow_Draw",
	BowSnareArrow = "Gun_Bow_Draw",
	BowArrowStormSky = "Gun_Bow_Draw",
	BowWindflipStep = "Core_Dash_Pose",
}

local ARCHETYPE_TO_CLIP = {
	ChainLightning = "Core_Cast_ChainBolt",
	BlinkDelayedSlash = "Katana_Z_IaiDraw",
	TravellingWave = "Core_Cast_Wave",
	MultiLaneSpikes = "Core_Cast_GroundSlam",
	SpreadVolley = "Core_Cast_Beam",
	PiercingBeam = "Core_Cast_Beam",
	VortexPullCage = "Core_Cast_Vortex",
	DragRushSlam = "Martial_Z_Rush",
	SkyfallSphere = "Core_Cast_SkySphere",
	MeteorShower = "Core_Cast_SkySphere",
	SkybeamPillars = "Core_Cast_SkySphere",
	GroundMonolithShatter = "Core_Cast_GroundSlam",
	SandCoffinImplode = "Core_Cast_Vortex",
	PoleVaultSlam = "Core_Cast_GroundSlam",
	ZigZagMirrorKick = "Martial_Z_Kick",
	RiftPhaseEscape = "Core_Dash_Pose",
	HarmonicSiphonWave = "Gun_VoidLyre_Strum",
	TransformToggle = "Core_Transform_Roar",
	PortalWorldGate = "Core_Cast_Vortex",
	MobilityDashHit = "Core_Dash_Pose",
}

local function resolveDirectOrAlias(name)
	if type(name) ~= "string" then
		return nil
	end
	local sName: string = tostring(name)
	if sName == "" then
		return nil
	end
	if CLIPS[sName] then
		return sName
	end
	local aliased = CLIP_ALIASES[sName]
	if aliased and CLIPS[aliased] then
		return aliased
	end
	local kataStyle, kataStep = string.match(sName, "^Kata_(.+)_(%d)$")
	if kataStyle and kataStep then
		local sid = Choreo.ResolveStyleId(kataStyle)
		local kind = STYLE_KATA_KIND[sid] or "Punch"
		local cand = "Martial_" .. kind .. "_" .. kataStep
		if CLIPS[cand] then
			return cand
		end
	end
	local mStyle, mKey = string.match(sName, "^Martial_(.+)_([ZXCVF])$")
	if mStyle and mKey then
		local sid = Choreo.ResolveStyleId(mStyle)
		local kind = STYLE_KATA_KIND[sid] or "Punch"
		if kind == "Kick" then
			if mKey == "Z" then return "Martial_Z_Kick"
			elseif mKey == "X" then return "Martial_Kick_2"
			elseif mKey == "C" then return "Martial_C_Drill"
			elseif mKey == "V" then return "Martial_Kick_4"
			else return "Martial_Kick_1" end
		elseif kind == "Claw" then
			if mKey == "Z" then return "Martial_Claw_1"
			elseif mKey == "X" then return "Martial_Claw_3"
			elseif mKey == "C" then return "Martial_Claw_4"
			elseif mKey == "V" then return "Core_Cast_Vortex"
			else return "Core_Dash_Pose" end
		else
			if mKey == "Z" then return "Martial_Z_Rush"
			elseif mKey == "X" then return "Martial_X_Uppercut"
			elseif mKey == "C" then return "Martial_C_Flurry"
			elseif mKey == "V" then return "Core_Cast_SkySphere"
			else return "Core_Dash_Pose" end
		end
	end
	return nil
end

function Choreo.ResolveClipName(rawClip, archetype, slot, activeId, moveKey, comboStep, isHeavy)
	local direct = resolveDirectOrAlias(rawClip)
	if direct then
		return direct
	end

	local nSlot = tonumber(slot) or 1
	local key = type(moveKey) == "string" and string.upper(moveKey) or ""
	local step = math.clamp(tonumber(comboStep) or 1, 1, 4)
	if isHeavy then
		step = 4
	end

	-- Query authoritative SkybreakSkillBlueprints when loaded
	local bp = getBlueprints()
	if bp then
		if key ~= "" and type(bp.GetSkillBlueprint) == "function" then
			local ok, spec = pcall(bp.GetSkillBlueprint, nSlot, activeId, key)
			if ok and type(spec) == "table" then
				local fromBp = resolveDirectOrAlias(spec.PoseClip)
				if fromBp then
					return fromBp
				end
				if (archetype == nil or archetype == "") and type(spec.Archetype) == "string" then
					archetype = spec.Archetype
				end
			end
		elseif key == "" and type(bp.GetM1Blueprint) == "function" then
			local ok, spec = pcall(bp.GetM1Blueprint, nSlot, activeId, step)
			if ok and type(spec) == "table" then
				local fromBp = resolveDirectOrAlias(spec.PoseClip)
				if fromBp then
					if nSlot == 4 and fromBp == "Gun_Pistol_Fire" and string.lower(tostring(activeId or "")) == "aion_chrono_pistols" then
						return "Gun_DualPistol_Fire"
					end
					return fromBp
				end
			end
		end
	end

	-- Slot-specific M1 kata resolution
	if key == "" or key == "M1" or key == "HEAVY" then
		if nSlot == 3 then
			local wArch = Choreo.ResolveWeaponArchetype(activeId)
			local cand = wArch .. "_M1_" .. tostring(step)
			return CLIPS[cand] and cand or ("Katana_M1_" .. tostring(step))
		elseif nSlot == 1 then
			local sid = Choreo.ResolveStyleId(activeId)
			local kind = STYLE_KATA_KIND[sid] or "Punch"
			local cand = "Martial_" .. kind .. "_" .. tostring(step)
			return CLIPS[cand] and cand or ("Martial_Punch_" .. tostring(step))
		elseif nSlot == 2 then
			local cand = "Core_M1_" .. tostring(step)
			return CLIPS[cand] and cand or "Core_M1_1"
		elseif nSlot == 4 then
			local gArch = Choreo.ResolveGunArchetype(activeId)
			if gArch == "DualPistols" then return "Gun_DualPistol_Fire"
			elseif gArch == "Railgun" then return "Gun_Railgun_Brace"
			elseif gArch == "Cannon" then return "Gun_Cannon_Fire"
			elseif gArch == "Bow" then return "Gun_Bow_Draw"
			elseif gArch == "VoidLyre" then return "Gun_VoidLyre_Strum"
			else return "Gun_Pistol_Fire" end
		end
	end

	-- Context-aware mechanical archetype resolution for [Z, X, C, V, F]
	if nSlot == 3 then
		local wArch = Choreo.ResolveWeaponArchetype(activeId)
		if key == "F" then
			return "Core_Dash_Pose"
		elseif wArch == "Spear" then
			if key == "Z" then return "Spear_Z_Thrust"
			elseif key == "X" or archetype == "PoleVaultSlam" then return "Spear_X_PoleVault"
			elseif key == "C" then return "Spear_M1_3"
			else return "Spear_M1_4" end
		elseif wArch == "Katana" then
			if key == "Z" or key == "V" or archetype == "BlinkDelayedSlash" then return "Katana_Z_IaiDraw"
			elseif key == "X" then return "Katana_X_Crescent"
			else return "Katana_M1_3" end
		elseif wArch == "Greatsword" then
			if key == "Z" then return "Greatsword_Z_EarthSplit"
			elseif key == "X" or archetype == "PoleVaultSlam" then return "Greatsword_X_Guillotine"
			elseif key == "C" then return "Greatsword_M1_3"
			else return "Greatsword_M1_4" end
		elseif wArch == "DualBlades" then
			if key == "Z" then return "DualBlades_Z_Blitz"
			elseif key == "X" then return "DualBlades_X_Spin"
			elseif key == "C" then return "DualBlades_M1_3"
			else return "DualBlades_M1_4" end
		elseif wArch == "Scythe" then
			if key == "Z" then return "Scythe_Z_Hook"
			elseif key == "X" then return "Scythe_X_Rift"
			elseif key == "C" then return "Scythe_M1_3"
			else return "Scythe_M1_4" end
		end
	elseif nSlot == 4 then
		if key == "F" or archetype == "MobilityDashHit" then
			return "Core_Dash_Pose"
		end
		local gArch = Choreo.ResolveGunArchetype(activeId)
		if gArch == "DualPistols" then return "Gun_DualPistol_Fire"
		elseif gArch == "Railgun" then return "Gun_Railgun_Brace"
		elseif gArch == "Cannon" then return "Gun_Cannon_Fire"
		elseif gArch == "Bow" then return "Gun_Bow_Draw"
		elseif gArch == "VoidLyre" then return "Gun_VoidLyre_Strum"
		else return "Gun_Pistol_Fire" end
	elseif nSlot == 1 then
		local sid = Choreo.ResolveStyleId(activeId)
		local kind = STYLE_KATA_KIND[sid] or "Punch"
		if kind == "Kick" then
			if key == "Z" or archetype == "ZigZagMirrorKick" then return "Martial_Z_Kick"
			elseif key == "X" then return "Martial_Kick_2"
			elseif key == "C" then return "Martial_C_Drill"
			elseif key == "V" then return "Martial_Kick_4"
			else return "Martial_Kick_1" end
		end
	end

	if type(archetype) == "string" and ARCHETYPE_TO_CLIP[archetype] then
		if archetype == "BlinkDelayedSlash" and nSlot ~= 3 then
			return "Core_Dash_Pose"
		elseif archetype == "HarmonicSiphonWave" and nSlot ~= 4 then
			return "Core_Cast_Vortex"
		end
		return ARCHETYPE_TO_CLIP[archetype]
	end

	if nSlot == 1 then
		if key == "Z" then return "Martial_Z_Rush"
		elseif key == "X" then return "Martial_X_Uppercut"
		elseif key == "C" then return "Martial_C_Flurry"
		elseif key == "V" then return "Core_Cast_GroundSlam"
		else return "Core_Dash_Pose" end
	end
	if key == "F" then
		return "Core_Dash_Pose"
	elseif key == "V" then
		return "Core_Cast_SkySphere"
	end
	return "Core_Cast_Beam"
end

-- ============================================================================
-- TOKEN-GUARDED 4-BEAT FULL-BODY STATE MACHINE (RULE 4 & RULE 5 SAFE)
-- ============================================================================
local CharStates = setmetatable({}, { __mode = "k" })

local function getOrCreateState(ch)
	local st = CharStates[ch]
	if not st then
		st = {
			Token = 0,
			Active = false,
			CurrentPose = {},
			FromPose = {},
			WorkTargets = {},
			DiedConn = nil,
		}
		CharStates[ch] = st
	end
	if not st.DiedConn then
		local hum = ch:FindFirstChildOfClass("Humanoid")
		if hum then
			st.DiedConn = hum.Died:Connect(function()
				Choreo.CancelCharacter(ch)
			end)
		end
	end
	return st
end

function Choreo.CancelCharacter(ch)
	if not ch then
		return
	end
	local st = CharStates[ch]
	if not st then
		return
	end
	st.Token = (st.Token or 0) + 1
	st.Active = false
	st.Clip = nil
	st.ClipName = nil
	st.RightWep = nil
	st.LeftWep = nil
	table.clear(st.CurrentPose)
	table.clear(st.FromPose)
end

local function isCharacterBlocked(ch, plr, flightActive, isBeastNow)
	if not ch or not ch.Parent then
		return true
	end
	if flightActive == true or isBeastNow == true then
		return true
	end
	local hum = ch:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return true
	end
	if ch:GetAttribute("SkyShipPilot") == true then
		return true
	end
	local tier = tonumber(ch:GetAttribute("DragonFormTier"))
		or (plr and tonumber(plr:GetAttribute("DragonFormTier")))
		or 0
	local tf = tostring(ch:GetAttribute("FruitTransform") or (plr and plr:GetAttribute("FruitTransform")) or "")
	if tier >= 2 or tf == "AbyssalSovereign" or tf == "DragonFull" or tf == "AbyssalDragonFull" then
		return true
	end
	if ch:GetAttribute("Stunned") == true then
		return true
	end
	local stunnedUntil = tonumber(ch:GetAttribute("StunnedUntil")) or 0
	if stunnedUntil > 0 then
		local okNow, srvNow = pcall(function()
			return Workspace:GetServerTimeNow()
		end)
		if okNow and stunnedUntil > srvNow then
			return true
		end
	end
	return false
end

local function lerpOvershoot(cfA, cfB, u)
	if u <= 1.0 then
		return cfA:Lerp(cfB, u)
	end
	local extra = u - 1.0
	local delta = cfA:Inverse() * cfB
	return cfB * CFrame.identity:Lerp(delta, extra)
end

local function scaleRootCFrame(cfVal, scaleRatio)
	if not cfVal or math.abs(scaleRatio - 1.0) <= 0.03 then
		return cfVal
	end
	local rx, ry, rz, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cfVal:GetComponents()
	return CFrame.new(
		rx * scaleRatio,
		ry * scaleRatio,
		rz * scaleRatio,
		r00, r01, r02,
		r10, r11, r12,
		r20, r21, r22
	)
end

function Choreo.PlayClip(ch, plr, clipName, opts)
	if not ch or type(clipName) ~= "string" then
		return false
	end
	local clip = CLIPS[clipName] or (CLIP_ALIASES[clipName] and CLIPS[CLIP_ALIASES[clipName]])
	if not clip then
		return false
	end
	if isCharacterBlocked(ch, plr, false, false) then
		return false
	end

	local st = getOrCreateState(ch)
	local now = os.clock()
	st.Token = (st.Token or 0) + 1
	local myToken = st.Token

	-- Snapshot current joint offsets so rapid M1 chains blend seamlessly without T-pose snapping
	table.clear(st.FromPose)
	if st.Active then
		for _, role in ipairs(JOINT_ROLES) do
			st.FromPose[role] = st.CurrentPose[role] or CFrame.identity
		end
		st.FromRWep = st.RightWep or CFrame.identity
		st.FromLWep = st.LeftWep or CFrame.identity
	else
		for _, role in ipairs(JOINT_ROLES) do
			st.FromPose[role] = CFrame.identity
		end
		st.FromRWep = CFrame.identity
		st.FromLWep = CFrame.identity
	end

	local o = type(opts) == "table" and opts or {}
	local curSlot = tonumber(o.Slot)
		or (plr and tonumber(plr:GetAttribute("ActiveSlot")))
		or tonumber(ch:GetAttribute("ActiveSlot"))
		or 1

	st.Active = true
	st.Player = plr
	st.Slot = curSlot
	st.ClipName = clipName
	st.Clip = clip
	st.StartTime = now
	st.WindupSec = math.clamp(tonumber(o.WindupSec) or clip.WindupSec or 0.075, 0.030, 0.350)
	st.SnapSec = math.clamp(tonumber(o.SnapSec) or clip.SnapSec or 0.090, 0.035, 0.450)
	st.HitstopSec = math.clamp(tonumber(o.HitstopSec) or clip.HitstopSec or 0.042, 0.035, 0.055)
	st.RecoverSec = math.clamp(tonumber(o.RecoverSec) or clip.RecoverSec or 0.180, 0.080, 0.450)
	st.Source = o.Source or "local"
	st.Sig = tostring(o.Sig or clipName)
	st.StartedAtClock = now
	st.ActiveToken = myToken
	return true
end

function Choreo.TriggerLocalM1(plr, slot, activeId, comboStep, isHeavy)
	if not plr or not plr.Character then
		return false
	end
	local ch = plr.Character
	local nSlot = tonumber(slot) or tonumber(plr:GetAttribute("ActiveSlot")) or 1
	local step = math.clamp(tonumber(comboStep) or 1, 1, 4)
	if isHeavy then
		step = 4
	end
	local clipName = Choreo.ResolveClipName(nil, nil, nSlot, activeId, "", step, isHeavy == true)
	local sig = string.format("M1:%d:%d", nSlot, step)
	return Choreo.PlayClip(ch, plr, clipName, {
		Slot = nSlot,
		Source = "local",
		Sig = sig,
		HitstopSec = (step == 4 or isHeavy) and 0.048 or nil,
	})
end

function Choreo.TriggerLocalSkill(plr, slot, activeId, moveKey)
	if not plr or not plr.Character then
		return false
	end
	local ch = plr.Character
	local nSlot = tonumber(slot) or tonumber(plr:GetAttribute("ActiveSlot")) or 1
	local key = string.upper(tostring(moveKey or ""))
	if key ~= "Z" and key ~= "X" and key ~= "C" and key ~= "V" and key ~= "F" then
		return false
	end

	-- Rule 2 Strict Guard: Slot 2 [F] on True Flight Cores enters 3D flight, NOT ground dash choreography
	if nSlot == 2 and key == "F" then
		local tier = tonumber(ch:GetAttribute("DragonFormTier")) or tonumber(plr:GetAttribute("DragonFormTier")) or 0
		local tf = tostring(ch:GetAttribute("FruitTransform") or plr:GetAttribute("FruitTransform") or "")
		if Choreo.IsTrueFlightCore(activeId, tier, tf) then
			return false
		end
	end

	local clipName = Choreo.ResolveClipName(nil, nil, nSlot, activeId, key, 1, false)
	local sig = string.format("SKILL:%d:%s", nSlot, key)
	return Choreo.PlayClip(ch, plr, clipName, {
		Slot = nSlot,
		Source = "local",
		Sig = sig,
	})
end

function Choreo.TriggerFromCombatFX(actorChar, actorPlr, fx)
	if not actorChar or type(fx) ~= "table" then
		return false
	end
	local kind = tostring(fx.Kind or fx.Type or fx.Action or "")
	local kl = string.lower(kind)
	if kl == "damage" or kl == "hit" or kl == "status" or kl == "heal" or kl == "buff" or kl == "hazardtick" then
		return false
	end

	local rawClip = fx.PoseClip or fx.poseClip
	local arch = fx.Archetype or fx.SkillArchetype
	local hasExplicitPose = (type(rawClip) == "string" and rawClip ~= "") or (type(arch) == "string" and arch ~= "")
	local moveKey = tostring(fx.MoveKey or fx.Key or fx.SkillKey or "")
	local isM1Packet = (kl == "m1" or kl == "melee" or kl == "weaponm1" or kl == "gunshot" or kl == "gunfire" or fx.Combo ~= nil)
	local isSkillPacket = (moveKey ~= "" or kl == "skill" or kl == "ability" or kl == "slotmove" or hasExplicitPose)
	if not isM1Packet and not isSkillPacket then
		return false
	end

	local nSlot = tonumber(fx.Slot)
		or (actorPlr and tonumber(actorPlr:GetAttribute("ActiveSlot")))
		or tonumber(actorChar:GetAttribute("ActiveSlot"))
		or 1
	local activeId = tostring(
		fx.ItemId or fx.WeaponId or fx.GunId or fx.StyleId or fx.FruitId or fx.CoreId or fx.BlueprintId or ""
	)
	if activeId == "" and actorPlr then
		if nSlot == 1 then
			activeId = tostring(actorPlr:GetAttribute("EquippedStyle") or "skyborn_combat")
		elseif nSlot == 2 then
			activeId = tostring(actorPlr:GetAttribute("EquippedFruit") or "")
		elseif nSlot == 3 then
			activeId = tostring(actorPlr:GetAttribute("EquippedSword") or actorPlr:GetAttribute("EquippedWeapon") or "")
		elseif nSlot == 4 then
			activeId = tostring(actorPlr:GetAttribute("EquippedGun") or "")
		end
	end

	-- Rule 2 Strict Guard on Slot 2 [F] True Flight Cores
	if nSlot == 2 and string.upper(moveKey) == "F" then
		local tier = tonumber(actorChar:GetAttribute("DragonFormTier"))
			or (actorPlr and tonumber(actorPlr:GetAttribute("DragonFormTier")))
			or 0
		local tf = tostring(actorChar:GetAttribute("FruitTransform") or (actorPlr and actorPlr:GetAttribute("FruitTransform")) or "")
		if Choreo.IsTrueFlightCore(activeId, tier, tf) then
			return false
		end
	end

	local comboStep = math.clamp(tonumber(fx.Combo or fx.ComboStep) or 1, 1, 4)
	local isHeavy = (fx.Heavy == true) or (kl == "heavy")
	local sig = (moveKey ~= "")
		and string.format("SKILL:%d:%s", nSlot, string.upper(moveKey))
		or string.format("M1:%d:%d", nSlot, isHeavy and 4 or comboStep)

	local st = getOrCreateState(actorChar)
	local now = os.clock()
	-- Deduplicate paired CombatFX + CombatEvent packets and preserve 0ms local prediction without stutter
	if st.Active then
		local age = now - (st.StartedAtClock or 0)
		if st.Source == "local" and st.Slot == nSlot and st.Sig == sig and age < 0.42 then
			return false
		end
		if st.Source == "remote" and st.Sig == sig and age < 0.10 then
			return false
		end
	end

	local clipName = Choreo.ResolveClipName(rawClip, arch, nSlot, activeId, moveKey, comboStep, isHeavy)
	return Choreo.PlayClip(actorChar, actorPlr, clipName, {
		Slot = nSlot,
		Source = "remote",
		Sig = sig,
		WindupSec = fx.WindupSec,
		SnapSec = fx.SnapSec,
		HitstopSec = fx.HitstopSec,
		RecoverSec = fx.RecoverSec,
	})
end

function Choreo.StepCharacter(s, ch, _stepDt, _now, flightActive, isBeastNow)
	local st = CharStates[ch]
	if not st or not st.Active or not st.Clip then
		return nil
	end

	local plr = st.Player or (s and s.Player) or Players:GetPlayerFromCharacter(ch)
	if isCharacterBlocked(ch, plr, flightActive, isBeastNow) then
		Choreo.CancelCharacter(ch)
		return nil
	end

	-- Rule 5a: Instant cancel & cleanup if player switched weapon/combat slot mid-animation
	local curSlot = (plr and tonumber(plr:GetAttribute("ActiveSlot")))
		or tonumber(ch:GetAttribute("ActiveSlot"))
		or st.Slot
	if curSlot ~= st.Slot then
		Choreo.CancelCharacter(ch)
		return nil
	end

	local clip = st.Clip
	local elapsed = os.clock() - st.StartTime
	local t1 = st.WindupSec
	local t2 = t1 + st.SnapSec
	local t3 = t2 + st.HitstopSec
	local t4 = t3 + st.RecoverSec

	if elapsed >= t4 or st.Token ~= st.ActiveToken then
		Choreo.CancelCharacter(ch)
		return nil
	end

	-- Rule 5b: Proportional Root offset scaling on SolarTitan / RaceV4 scaled rigs
	local scaleRatio = 1.0
	local okScale, modelScale = pcall(function()
		return ch:GetScale()
	end)
	if okScale and type(modelScale) == "number" and modelScale > 0.2 then
		scaleRatio = math.clamp(modelScale, 0.75, 2.75)
	elseif tostring(ch:GetAttribute("FruitTransform") or (plr and plr:GetAttribute("FruitTransform")) or "") == "SolarTitan" then
		scaleRatio = 2.05
	end

	local windPose = clip.Windup or {}
	local strikePose = clip.Strike or {}
	local work = st.WorkTargets
	table.clear(work)

	local beat = 1
	local beatU = 0
	local blendSpeed = 28

	if elapsed < t1 then
		-- Beat 1: Windup / Coil / Anticipation (smooth ease-out)
		beat = 1
		local rawU = math.clamp(elapsed / math.max(t1, 0.001), 0, 1)
		beatU = 1 - (1 - rawU) * (1 - rawU)
		blendSpeed = 30
		for _, role in ipairs(JOINT_ROLES) do
			local a = st.FromPose[role] or CFrame.identity
			local b = windPose[role] or CFrame.identity
			if role == "Root" then
				b = scaleRootCFrame(b, scaleRatio)
			end
			work[role] = a:Lerp(b, beatU)
		end
		st.RightWep = (st.FromRWep or CFrame.identity):Lerp(windPose.RightWeapon or CFrame.identity, beatU)
		st.LeftWep = (st.FromLWep or CFrame.identity):Lerp(windPose.LeftWeapon or CFrame.identity, beatU)
	elseif elapsed < t2 then
		-- Beat 2: Overshoot Snap Strike (explosive quintic snap with 1.07x peak impact)
		beat = 2
		local rawU = math.clamp((elapsed - t1) / math.max(st.SnapSec, 0.001), 0, 1)
		beatU = rawU
		local snapAlpha = (1 - math.pow(1 - rawU, 4)) * 1.07
		if rawU > 0.82 then
			local settle = (rawU - 0.82) / 0.18
			snapAlpha = 1.07 - 0.07 * settle
		end
		blendSpeed = 48
		for _, role in ipairs(JOINT_ROLES) do
			local a = windPose[role] or CFrame.identity
			local b = strikePose[role] or CFrame.identity
			if role == "Root" then
				a = scaleRootCFrame(a, scaleRatio)
				b = scaleRootCFrame(b, scaleRatio)
			end
			work[role] = lerpOvershoot(a, b, snapAlpha)
		end
		st.RightWep = lerpOvershoot(windPose.RightWeapon or CFrame.identity, strikePose.RightWeapon or CFrame.identity, snapAlpha)
		st.LeftWep = lerpOvershoot(windPose.LeftWeapon or CFrame.identity, strikePose.LeftWeapon or CFrame.identity, snapAlpha)
	elseif elapsed < t3 then
		-- Beat 3: Hitstop Freeze (35-50ms crisp impact hold WITHOUT HumanoidRootPart.Anchored)
		beat = 3
		beatU = math.clamp((elapsed - t2) / math.max(st.HitstopSec, 0.001), 0, 1)
		blendSpeed = 54
		for _, role in ipairs(JOINT_ROLES) do
			local b = strikePose[role] or CFrame.identity
			if role == "Root" then
				b = scaleRootCFrame(b, scaleRatio)
			end
			work[role] = b
		end
		st.RightWep = strikePose.RightWeapon or CFrame.identity
		st.LeftWep = strikePose.LeftWeapon or CFrame.identity
	else
		-- Beat 4: Follow-Through & Smooth S-Curve Recovery to Idle/Locomotion
		beat = 4
		local rawU = math.clamp((elapsed - t3) / math.max(st.RecoverSec, 0.001), 0, 1)
		beatU = rawU * rawU * (3 - 2 * rawU)
		blendSpeed = 22
		for _, role in ipairs(JOINT_ROLES) do
			local a = strikePose[role] or CFrame.identity
			if role == "Root" then
				a = scaleRootCFrame(a, scaleRatio)
			end
			work[role] = a:Lerp(CFrame.identity, beatU)
		end
		st.RightWep = (strikePose.RightWeapon or CFrame.identity):Lerp(CFrame.identity, beatU)
		st.LeftWep = (strikePose.LeftWeapon or CFrame.identity):Lerp(CFrame.identity, beatU)
	end

	if type(clip.DynamicFn) == "function" then
		local rOut, lOut = clip.DynamicFn({
			Beat = beat,
			BeatU = beatU,
			Elapsed = elapsed,
			Scale = scaleRatio,
		}, work, st.RightWep, st.LeftWep)
		if rOut then
			st.RightWep = rOut
		end
		if lOut then
			st.LeftWep = lOut
		end
	end

	for _, role in ipairs(JOINT_ROLES) do
		st.CurrentPose[role] = work[role] or CFrame.identity
	end

	local lockLegs = (clip.LockLegs == true) and (beat <= 3 or beatU < 0.65)
	return work, st.RightWep, st.LeftWep, blendSpeed, lockLegs
end

return Choreo
