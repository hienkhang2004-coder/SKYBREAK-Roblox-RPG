-- SkybreakSkillBlueprints.lua
-- Shared authoritative skill mechanical blueprints, weapon/gun/style/core resolvers,
-- Rule 2 flight whitelist, 4-beat M1 katas, and 20-archetype skill specs across Slots 1..4.

local Blueprints = {}

Blueprints.ArchetypeList = {
	"ChainLightning",
	"BlinkDelayedSlash",
	"TravellingWave",
	"MultiLaneSpikes",
	"SpreadVolley",
	"PiercingBeam",
	"VortexPullCage",
	"DragRushSlam",
	"SkyfallSphere",
	"MeteorShower",
	"SkybeamPillars",
	"GroundMonolithShatter",
	"SandCoffinImplode",
	"PoleVaultSlam",
	"ZigZagMirrorKick",
	"RiftPhaseEscape",
	"HarmonicSiphonWave",
	"TransformToggle",
	"PortalWorldGate",
	"MobilityDashHit",
}

Blueprints.Archetypes = {}
for _, name in ipairs(Blueprints.ArchetypeList) do
	Blueprints.Archetypes[name] = name
end

local ARCHETYPE_LABELS_EN = {
	ChainLightning = "Chain Lightning",
	BlinkDelayedSlash = "Blink Delayed Slash",
	TravellingWave = "Travelling Wave",
	MultiLaneSpikes = "Multi-Lane Spikes",
	SpreadVolley = "Spread Volley",
	PiercingBeam = "Piercing Beam",
	VortexPullCage = "Vortex Pull Cage",
	DragRushSlam = "Drag Rush Slam",
	SkyfallSphere = "Skyfall Sphere",
	MeteorShower = "Meteor Shower",
	SkybeamPillars = "Skybeam Pillars",
	GroundMonolithShatter = "Monolith Shatter",
	SandCoffinImplode = "Sand Coffin Implode",
	PoleVaultSlam = "Pole-Vault Slam",
	ZigZagMirrorKick = "Mirror Zig-Zag",
	RiftPhaseEscape = "Rift Phase Escape",
	HarmonicSiphonWave = "Harmonic Siphon",
	TransformToggle = "Beast Ascension",
	PortalWorldGate = "World Rift Gate",
	MobilityDashHit = "Blitz Dash Strike",
	Spear = "Polearm / Spear",
	Katana = "Iaido Katana",
	Greatsword = "Heavy Greatsword",
	DualBlades = "Twin Blades",
	Scythe = "Reaper Scythe",
	Railgun = "Piercing Railgun",
	VoidLyre = "Harmonic Void Lyre",
	AcousticGuitar = "Harmonic Void Lyre",
	Bow = "Gale Sling / Bow",
	Cannon = "Siege Cannon",
	PistolRifle = "Aether Flintlock",
	SkyKata = "Aero Palm Kata",
	KickKata = "Blaze Kick Kata",
	DragonClaw = "Vortex Claw Kata",
	VoltTalon = "Lightning Talon",
	SolarHeavy = "Guard-Break Heavy",
	CelestialSix = "Six-Realm Rush",
	SanguineDrain = "Vampiric Void Claw",
	ChronoPalm = "Temporal Stasis Palm",
}

local ARCHETYPE_LABELS_VI = {
	ChainLightning = "Sét Giật Dây Chuyền",
	BlinkDelayedSlash = "Tốc Biến Trảm Trễ",
	TravellingWave = "Sóng Trảm Xuyên Tuyến",
	MultiLaneSpikes = "Gai Đâm Đa Luồng",
	SpreadVolley = "Tán Xạ Liên Loạt",
	PiercingBeam = "Tia Cực Quang Xuyên Phá",
	VortexPullCage = "Lồng Xoáy Hút Gom",
	DragRushSlam = "Lao Quặp Nện Đất",
	SkyfallSphere = "Cầu Thiên Phạt",
	MeteorShower = "Mưa Thiên Thạch",
	SkybeamPillars = "Cột Sáng Thiên Giới",
	GroundMonolithShatter = "Thạch Trụ Nứt Toác",
	SandCoffinImplode = "Quan Tài Cát Nổ Giam",
	PoleVaultSlam = "Chống Giáo Bổ Nhào",
	ZigZagMirrorKick = "Phản Quang Zích-Zắc",
	RiftPhaseEscape = "Ẩn Thân Xé Không",
	HarmonicSiphonWave = "Sóng Âm Hút Hồn",
	TransformToggle = "Hóa Thân Thần Thú",
	PortalWorldGate = "Cổng Dịch Chuyển Đảo",
	MobilityDashHit = "Đột Kích Lướt Trảm",
	Spear = "Trường Thương",
	Katana = "Đao Thuật Iaido",
	Greatsword = "Trọng Đại Kiếm",
	DualBlades = "Song Đao Tốc Trảm",
	Scythe = "Lưỡi Hái Hư Không",
	Railgun = "Pháo Từ Trường",
	VoidLyre = "Đàn Hồn Hư Không",
	AcousticGuitar = "Đàn Hồn Hư Không",
	Bow = "Ná Gió / Cung",
	Cannon = "Đại Pháo Công Thành",
	PistolRifle = "Súng Aether",
	SkyKata = "Chưởng Phong Kata",
	KickKata = "Phi Cước Hỏa Vũ",
	DragonClaw = "Long Trảo Hút Gom",
	VoltTalon = "Lôi Trảo Tốc Kích",
	SolarHeavy = "Trọng Quyền Phá Giáp",
	CelestialSix = "Thần Quyền Lục Giới",
	SanguineDrain = "Huyết Trảo Hút Máu",
	ChronoPalm = "Chưởng Ngưng Thời Không",
}

-- ============================================================================
-- 1. CANONICAL ID & ARCHETYPE RESOLVERS (RULES 2 & 3)
-- ============================================================================
local CANONICAL_CORES = {
	GaleCore = true,
	SandstoneCore = true,
	SolarFlameCore = true,
	GlacierIceCore = true,
	CelestialLightCore = true,
	StarforgedMagmaCore = true,
	ThunderRumbleCore = true,
	AstralGravityCore = true,
	DimensionalPortalCore = true,
	SolarTitanCore = true,
	AetherflowCore = true,
	AbyssalSovereignCore = true,
}

local CORE_ALIASES = {
	galecore = "GaleCore",
	gale = "GaleCore",
	gale_core = "GaleCore",
	wind = "GaleCore",
	aetherwindcore = "GaleCore",
	sandstonecore = "SandstoneCore",
	sandstone = "SandstoneCore",
	sandstone_core = "SandstoneCore",
	sand = "SandstoneCore",
	smoke = "SandstoneCore",
	smokecore = "SandstoneCore",
	solarflamecore = "SolarFlameCore",
	solar_flame = "SolarFlameCore",
	flame = "SolarFlameCore",
	flamecore = "SolarFlameCore",
	cyberphoenixcore = "SolarFlameCore",
	glaciericecore = "GlacierIceCore",
	glacier_ice = "GlacierIceCore",
	ice = "GlacierIceCore",
	icecore = "GlacierIceCore",
	frostbite = "GlacierIceCore",
	thunderrumblecore = "ThunderRumbleCore",
	thunder_rumble = "ThunderRumbleCore",
	rumble = "ThunderRumbleCore",
	rumblecore = "ThunderRumbleCore",
	thunder = "ThunderRumbleCore",
	celestiallightcore = "CelestialLightCore",
	celestial_light = "CelestialLightCore",
	light = "CelestialLightCore",
	lightcore = "CelestialLightCore",
	starforgedmagmacore = "StarforgedMagmaCore",
	starforged_magma = "StarforgedMagmaCore",
	magma = "StarforgedMagmaCore",
	magmacore = "StarforgedMagmaCore",
	magmaburstcore = "StarforgedMagmaCore",
	astralgravitycore = "AstralGravityCore",
	astral_gravity = "AstralGravityCore",
	gravity = "AstralGravityCore",
	gravitycore = "AstralGravityCore",
	dimensionalportalcore = "DimensionalPortalCore",
	dimensional_portal = "DimensionalPortalCore",
	portal = "DimensionalPortalCore",
	portalcore = "DimensionalPortalCore",
	solartitancore = "SolarTitanCore",
	solar_titan = "SolarTitanCore",
	buddha = "SolarTitanCore",
	quake = "SolarTitanCore",
	quakecore = "SolarTitanCore",
	starlight_quake = "SolarTitanCore",
	starlightquakecore = "SolarTitanCore",
	aetherflowcore = "AetherflowCore",
	aetherflow = "AetherflowCore",
	sweetdoughcore = "AetherflowCore",
	sweet_dough = "AetherflowCore",
	dough = "AetherflowCore",
	doughcore = "AetherflowCore",
	mochi = "AetherflowCore",
	abyssalsovereigncore = "AbyssalSovereignCore",
	abyssal_sovereign = "AbyssalSovereignCore",
	dragon = "AbyssalSovereignCore",
	dragoncore = "AbyssalSovereignCore",
	abyssal_dragon = "AbyssalSovereignCore",
	void_dragon = "AbyssalSovereignCore",
	abyssaldarkcore = "AbyssalSovereignCore",
}

function Blueprints.ResolveCoreId(rawId)
	if type(rawId) ~= "string" or rawId == "" or rawId == "None" then
		return ""
	end
	local head = string.match(rawId, "^([^|]+)") or rawId
	if CANONICAL_CORES[head] then
		return head
	end
	return CORE_ALIASES[head] or CORE_ALIASES[string.lower(head)] or ""
end
Blueprints.ResolveFruitId = Blueprints.ResolveCoreId

local CANONICAL_STYLES = {
	skyborn_combat = true,
	SkyStep = true,
	jade_dragon = true,
	thunder_talon = true,
	solar_ashura = true,
	celestial_godhuman = true,
	SanguineVoidArt = true,
	ChronoVoidPalm = true,
}

local STYLE_ALIASES = {
	skyborn_combat = "skyborn_combat",
	skyborncombat = "skyborn_combat",
	combat = "skyborn_combat",
	unarmed = "skyborn_combat",
	skystep = "SkyStep",
	sky_step = "SkyStep",
	black_leg = "SkyStep",
	flame_step = "SkyStep",
	death_step = "SkyStep",
	jade_dragon = "jade_dragon",
	jadedragon = "jade_dragon",
	glacialfist = "jade_dragon",
	glacial_fist = "jade_dragon",
	glacial_karate = "jade_dragon",
	glacialkarate = "jade_dragon",
	sharkman_karate = "jade_dragon",
	thunder_talon = "thunder_talon",
	thundertalon = "thunder_talon",
	electricclaw = "thunder_talon",
	electric_claw = "thunder_talon",
	electro = "thunder_talon",
	solar_ashura = "solar_ashura",
	solarashura = "solar_ashura",
	abyssaltalon = "solar_ashura",
	abyssal_talon = "solar_ashura",
	dragon_talon = "solar_ashura",
	dragontalon = "solar_ashura",
	celestial_godhuman = "celestial_godhuman",
	celestialgodhuman = "celestial_godhuman",
	godhuman = "celestial_godhuman",
	godhumanskyborn = "celestial_godhuman",
	superhuman = "celestial_godhuman",
	sanguinevoidart = "SanguineVoidArt",
	sanguine_void_art = "SanguineVoidArt",
	sanguine = "SanguineVoidArt",
	sanguine_arts = "SanguineVoidArt",
	chronovoidpalm = "ChronoVoidPalm",
	chrono_void_palm = "ChronoVoidPalm",
	chrono_palm = "ChronoVoidPalm",
	chronos_fist = "ChronoVoidPalm",
}

function Blueprints.ResolveStyleId(rawId)
	if type(rawId) ~= "string" or rawId == "" then
		return "skyborn_combat"
	end
	if CANONICAL_STYLES[rawId] then
		return rawId
	end
	return STYLE_ALIASES[rawId] or STYLE_ALIASES[string.lower(rawId)] or "skyborn_combat"
end

-- Exact weapon table from Config.Swords, Config.Items & ArsenalExpansionConfig.Items
local WEAPON_ARCHETYPE_EXACT = {
	sunshard_halberd = "Spear",
	nerith_abyssal_trident = "Spear",
	sky_halberd = "Spear",
	tempest_trident = "Spear",
	starter_sword = "Katana",
	cyber_katana_mk2 = "Katana",
	cryon_frostblade = "Katana",
	yamo_voidblade = "Katana",
	saber_of_aureon = "Katana",
	dawnbringer_sword = "Katana",
	Dawnbringer = "Katana",
	sylvaris_thornblade = "Greatsword",
	ignivar_magma_breaker = "Greatsword",
	noxar_abyssal_greatsword = "Greatsword",
	noxar_greatsword = "Greatsword",
	abyssal_greatsword = "Greatsword",
	ArchitectsSeverance = "Greatsword",
	architect_severance = "Greatsword",
	dragon_cleaver = "Greatsword",
	starter_daggers = "DualBlades",
	stormfang_daggers = "DualBlades",
	Stormfang = "DualBlades",
	cursed_dual_skyblades = "DualBlades",
	CursedDualSkyblades = "DualBlades",
	cursed_dual_katana = "DualBlades",
	dual_eclipse = "DualBlades",
	twin_fang_daggers = "DualBlades",
	aion_chrono_scythe = "Scythe",
	void_reaper_scythe = "Scythe",
	starter_staff = "Scythe",
	astral_staff = "Scythe",
	EternalFrost = "Scythe",
	eternal_frost_staff = "Scythe",
}

function Blueprints.ResolveWeaponArchetype(weaponId)
	if type(weaponId) ~= "string" or weaponId == "" then
		return "Katana"
	end
	if WEAPON_ARCHETYPE_EXACT[weaponId] then
		return WEAPON_ARCHETYPE_EXACT[weaponId]
	end
	local low = string.lower(weaponId)
	if WEAPON_ARCHETYPE_EXACT[low] then
		return WEAPON_ARCHETYPE_EXACT[low]
	end
	if string.find(low, "halberd", 1, true)
		or string.find(low, "trident", 1, true)
		or string.find(low, "lance", 1, true)
		or string.find(low, "spear", 1, true)
		or string.find(low, "glaive", 1, true)
		or string.find(low, "pole", 1, true)
	then
		return "Spear"
	end
	if string.find(low, "greatsword", 1, true)
		or string.find(low, "greatsaber", 1, true)
		or string.find(low, "cleaver", 1, true)
		or string.find(low, "sunblade", 1, true)
		or string.find(low, "colossus", 1, true)
		or string.find(low, "claymore", 1, true)
		or string.find(low, "warhammer", 1, true)
		or string.find(low, "breaker", 1, true)
	then
		return "Greatsword"
	end
	if string.find(low, "dagger", 1, true)
		or string.find(low, "twin", 1, true)
		or string.find(low, "dual_fang", 1, true)
		or string.find(low, "cursed_dual", 1, true)
		or string.find(low, "dual", 1, true)
	then
		return "DualBlades"
	end
	if string.find(low, "scythe", 1, true)
		or string.find(low, "reaper", 1, true)
		or string.find(low, "staff", 1, true)
	then
		return "Scythe"
	end
	return "Katana"
end

-- Exact gun table from Config.Guns, SkybreakCombatData.GunSpecs & ArsenalExpansionConfig.Items
local GUN_ARCHETYPE_EXACT = {
	cryo_railgun = "Railgun",
	soul_guitar_void = "VoidLyre",
	sylvaris_thornbow = "Bow",
	solar_kabucha = "Bow",
	kabucha_wind = "Bow",
	storm_longbow = "Bow",
	ignivar_hellcannon = "Cannon",
	veyr_singularity_cannon = "Cannon",
	magma_blaster = "Cannon",
	aether_flintlock = "PistolRifle",
	aion_chrono_pistols = "PistolRifle",
	bizarre_rifle_cyber = "PistolRifle",
}

function Blueprints.ResolveGunArchetype(gunId)
	if type(gunId) ~= "string" or gunId == "" then
		return "PistolRifle"
	end
	if GUN_ARCHETYPE_EXACT[gunId] then
		return GUN_ARCHETYPE_EXACT[gunId]
	end
	local low = string.lower(gunId)
	if GUN_ARCHETYPE_EXACT[low] then
		return GUN_ARCHETYPE_EXACT[low]
	end
	if string.find(low, "railgun", 1, true) or string.find(low, "sniper", 1, true) or string.find(low, "gauss", 1, true) then
		return "Railgun"
	end
	if string.find(low, "lyre", 1, true) or string.find(low, "guitar", 1, true) or string.find(low, "harp", 1, true) then
		return "VoidLyre"
	end
	if string.find(low, "bow", 1, true) or string.find(low, "kabucha", 1, true) or string.find(low, "sling", 1, true) then
		return "Bow"
	end
	if string.find(low, "cannon", 1, true) or string.find(low, "mortar", 1, true) or string.find(low, "blaster", 1, true) then
		return "Cannon"
	end
	return "PistolRifle"
end

-- Rule 2 Exact Whitelist: ONLY these 6 Cores + AbyssalSovereignCore at Form 2 may enter 3D free flight
local TRUE_FLIGHT_CORES = {
	GaleCore = true,
	SandstoneCore = true,
	SolarFlameCore = true,
	CelestialLightCore = true,
	StarforgedMagmaCore = true,
	AstralGravityCore = true,
}

function Blueprints.IsTrueFlightCore(coreId, dragonFormTier, fruitTransform)
	local cid = Blueprints.ResolveCoreId(coreId)
	if cid == "" then
		return false
	end
	if TRUE_FLIGHT_CORES[cid] == true then
		return true
	end
	if cid == "AbyssalSovereignCore" then
		local tier = tonumber(dragonFormTier) or 0
		local tf = tostring(fruitTransform or "")
		return (tier >= 2 or tf == "AbyssalSovereign" or tf == "DragonFull" or tf == "AbyssalDragonFull")
	end
	return false
end

-- ============================================================================
-- 2. FOUR-BEAT M1 BLUEPRINTS (SLOTS 1..4)
-- ============================================================================
local STYLE_META: { [string]: any } = {
	skyborn_combat = { SubArch = "SkyKata", PosePrefix = "Martial_Punch_", Element = "Sky", Mults = { 1.00, 1.08, 1.18, 1.50 }, Reach = { 14.0, 14.5, 15.2, 17.0 }, Width = { 8.5, 9.0, 9.5, 11.5 }, Lunge = { 3.5, 4.0, 4.5, 5.5 }, Impact4 = false, Tags = { "AERO PALM", "KNOCKBACK" } },
	SkyStep = { SubArch = "KickKata", PosePrefix = "Martial_Kick_", Element = "Flame", Mults = { 1.08, 1.16, 1.26, 1.62 }, Reach = { 14.8, 15.4, 16.0, 18.0 }, Width = { 9.0, 9.5, 10.2, 12.5 }, Lunge = { 4.5, 5.0, 5.5, 6.5 }, Impact4 = true, Burn = 1, Tags = { "100% KICK KATA", "BURN" } },
	jade_dragon = { SubArch = "DragonClaw", PosePrefix = "Martial_Claw_", Element = "Jade", Mults = { 1.08, 1.16, 1.28, 1.65 }, Reach = { 14.8, 15.2, 16.0, 18.0 }, Width = { 9.0, 9.5, 10.2, 12.5 }, Lunge = { 4.0, 4.5, 4.5, 5.5 }, Impact4 = false, Tags = { "ARMOR SHRED", "PULL" } },
	thunder_talon = { SubArch = "VoltTalon", PosePrefix = "Martial_Claw_", Element = "Lightning", Mults = { 1.10, 1.20, 1.32, 1.75 }, Reach = { 15.0, 15.6, 16.4, 18.5 }, Width = { 9.0, 9.6, 10.2, 13.0 }, Lunge = { 5.5, 5.5, 5.5, 6.5 }, Impact4 = true, Stun4 = 0.75, Tags = { "BLITZ CLAW", "STUN" } },
	solar_ashura = { SubArch = "SolarHeavy", PosePrefix = "Martial_Punch_", Element = "Flame", Mults = { 1.18, 1.30, 1.44, 1.92 }, Reach = { 15.0, 15.5, 16.2, 19.2 }, Width = { 9.8, 10.4, 11.0, 14.0 }, Lunge = { 3.5, 4.0, 4.5, 6.0 }, Impact4 = true, Burn = 2, Tags = { "GUARD BREAK", "BURN" } },
	celestial_godhuman = { SubArch = "CelestialSix", PosePrefix = "Martial_Punch_", Element = "Celestial", Mults = { 1.25, 1.38, 1.52, 2.18 }, Reach = { 16.5, 17.2, 18.0, 21.0 }, Width = { 10.5, 11.0, 12.0, 15.0 }, Lunge = { 6.5, 6.5, 6.5, 7.5 }, Impact4 = true, Stun4 = 0.90, Tags = { "SIX REALMS", "STUN" } },
	SanguineVoidArt = { SubArch = "SanguineDrain", PosePrefix = "Martial_Claw_", Element = "Void", Mults = { 1.26, 1.40, 1.55, 2.22 }, Reach = { 16.5, 17.5, 18.2, 21.5 }, Width = { 10.5, 11.5, 12.2, 15.5 }, Lunge = { 6.5, 6.5, 6.5, 7.5 }, Impact4 = false, Leech = 0.06, Stun4 = 0.92, Tags = { "LIFESTEAL", "VOID CLAW" } },
	ChronoVoidPalm = { SubArch = "ChronoPalm", PosePrefix = "Martial_Punch_", Element = "Void", Mults = { 1.28, 1.42, 1.58, 2.28 }, Reach = { 17.0, 17.8, 18.8, 22.0 }, Width = { 11.0, 11.5, 12.5, 16.0 }, Lunge = { 6.5, 6.5, 6.5, 7.5 }, Impact4 = true, Stun4 = 0.95, Tags = { "CHRONO PALM", "STUN" } },
}

local WEAPON_M1_ARCHETYPES: { [string]: any } = {
	Spear = {
		{ A = "WidePoleSweep", P = "Spear_M1_1", Wu = 0.08, Snap = 0.08, Hs = 0.038, Rc = 0.12, Reach = 20.5, Width = 10.5, M = 1.04, H = 1, Intv = 0, Lunge = 4.2, Impact = false, T = {"WIDE SWEEP", "REACH"} },
		{ A = "RapidTriplePoke", P = "Spear_M1_2", Wu = 0.06, Snap = 0.11, Hs = 0.035, Rc = 0.12, Reach = 22.0, Width = 8.2, M = 1.18, H = 3, Intv = 0.055, Lunge = 4.8, Impact = false, T = {"3 HITS", "PIERCE"} },
		{ A = "FigureEightWhirl", P = "Spear_M1_3", Wu = 0.08, Snap = 0.09, Hs = 0.040, Rc = 0.13, Reach = 20.8, Width = 12.0, M = 1.24, H = 1, Intv = 0, Lunge = 4.5, Impact = false, T = {"360 WHIRL", "AOE"} },
		{ A = "VaultingPierce", P = "Spear_M1_4", Wu = 0.10, Snap = 0.10, Hs = 0.048, Rc = 0.18, Reach = 24.5, Width = 11.8, M = 1.56, H = 1, Intv = 0, Lunge = 6.5, Impact = true, T = {"POLE-VAULT", "GUARD BREAK"} },
	},
	Katana = {
		{ A = "DiagonalDrawCut", P = "Katana_M1_1", Wu = 0.06, Snap = 0.07, Hs = 0.035, Rc = 0.10, Reach = 18.0, Width = 9.0, M = 1.02, H = 1, Intv = 0, Lunge = 4.0, Impact = false, T = {"IAI CUT"} },
		{ A = "ReverseRisingCut", P = "Katana_M1_2", Wu = 0.06, Snap = 0.07, Hs = 0.035, Rc = 0.10, Reach = 18.4, Width = 9.2, M = 1.10, H = 1, Intv = 0, Lunge = 4.2, Impact = false, T = {"IAI CUT"} },
		{ A = "SpinningCrossSlash", P = "Katana_M1_3", Wu = 0.07, Snap = 0.08, Hs = 0.038, Rc = 0.11, Reach = 19.0, Width = 9.8, M = 1.20, H = 1, Intv = 0, Lunge = 4.6, Impact = false, T = {"SPIN CUT"} },
		{ A = "SheathFlashFinisher", P = "Katana_M1_4", Wu = 0.09, Snap = 0.09, Hs = 0.045, Rc = 0.16, Reach = 22.0, Width = 11.5, M = 1.48, H = 1, Intv = 0, Lunge = 6.0, Impact = false, T = {"IAI CUT", "PIERCE"} },
	},
	Greatsword = {
		{ A = "HeavyHorizontalCleave", P = "Greatsword_M1_1", Wu = 0.11, Snap = 0.10, Hs = 0.045, Rc = 0.15, Reach = 20.0, Width = 11.5, M = 1.16, H = 1, Intv = 0, Lunge = 3.6, Impact = false, T = {"HEAVY CLEAVE", "GUARD BREAK"} },
		{ A = "TorsoTorqueBackCleave", P = "Greatsword_M1_2", Wu = 0.11, Snap = 0.10, Hs = 0.045, Rc = 0.15, Reach = 20.5, Width = 12.0, M = 1.26, H = 1, Intv = 0, Lunge = 3.8, Impact = false, T = {"HEAVY CLEAVE", "GUARD BREAK"} },
		{ A = "RisingUppercutCleave", P = "Greatsword_M1_3", Wu = 0.12, Snap = 0.10, Hs = 0.048, Rc = 0.16, Reach = 21.2, Width = 12.4, M = 1.38, H = 1, Intv = 0, Lunge = 4.2, Impact = false, T = {"LAUNCH", "GUARD BREAK"} },
		{ A = "EarthshatterGuillotine", P = "Greatsword_M1_4", Wu = 0.14, Snap = 0.11, Hs = 0.050, Rc = 0.20, Reach = 24.0, Width = 14.5, M = 1.78, H = 1, Intv = 0, Lunge = 5.4, Impact = true, T = {"SLAM", "GUARD BREAK"} },
	},
	DualBlades = {
		{ A = "TwinCrossSlash", P = "DualBlades_M1_1", Wu = 0.05, Snap = 0.07, Hs = 0.032, Rc = 0.09, Reach = 16.8, Width = 9.0, M = 1.06, H = 2, Intv = 0.055, Lunge = 4.6, Impact = false, T = {"2 HITS", "BLITZ"} },
		{ A = "ReverseScissorCut", P = "DualBlades_M1_2", Wu = 0.05, Snap = 0.07, Hs = 0.032, Rc = 0.09, Reach = 17.2, Width = 9.2, M = 1.14, H = 2, Intv = 0.055, Lunge = 4.8, Impact = false, T = {"2 HITS", "BLITZ"} },
		{ A = "CycloneTwinSpin", P = "DualBlades_M1_3", Wu = 0.06, Snap = 0.08, Hs = 0.035, Rc = 0.10, Reach = 18.0, Width = 10.4, M = 1.24, H = 2, Intv = 0.055, Lunge = 5.2, Impact = false, T = {"2 HITS", "SPIN"} },
		{ A = "XExecutionRend", P = "DualBlades_M1_4", Wu = 0.08, Snap = 0.09, Hs = 0.044, Rc = 0.15, Reach = 20.8, Width = 11.8, M = 1.54, H = 2, Intv = 0.060, Lunge = 6.4, Impact = false, T = {"2 HITS", "PIERCE"} },
	},
	Scythe = {
		{ A = "CrescentReapHook", P = "Scythe_M1_1", Wu = 0.09, Snap = 0.09, Hs = 0.040, Rc = 0.13, Reach = 19.8, Width = 11.8, M = 1.08, H = 1, Intv = 0, Lunge = 4.0, Impact = false, T = {"WIDE REAP"} },
		{ A = "BackhandHarvestArc", P = "Scythe_M1_2", Wu = 0.09, Snap = 0.09, Hs = 0.040, Rc = 0.13, Reach = 20.2, Width = 12.2, M = 1.18, H = 1, Intv = 0, Lunge = 4.2, Impact = false, T = {"WIDE REAP"} },
		{ A = "FullMoonSpinHarvest", P = "Scythe_M1_3", Wu = 0.10, Snap = 0.09, Hs = 0.042, Rc = 0.14, Reach = 21.0, Width = 13.0, M = 1.30, H = 1, Intv = 0, Lunge = 4.6, Impact = false, T = {"360 REAP", "PULL"} },
		{ A = "SoulGuillotineDrop", P = "Scythe_M1_4", Wu = 0.12, Snap = 0.10, Hs = 0.048, Rc = 0.18, Reach = 23.5, Width = 13.8, M = 1.64, H = 1, Intv = 0, Lunge = 5.6, Impact = true, Leech = 0.05, T = {"LIFESTEAL", "AOE"} },
	},
}

local GUN_M1_ARCHETYPES: { [string]: any } = {
	Railgun = { A = "PiercingBeam", P = "Gun_Railgun_Brace", Wu = 0.08, Snap = 0.07, Hs = 0.040, Rc = 0.18, Reach = 115.0, Width = 8.5, M = 1.56, Element = "Frost", T = {"PIERCE", "FREEZE"} },
	VoidLyre = { A = "HarmonicSiphonWave", P = "Gun_VoidLyre_Strum", Wu = 0.07, Snap = 0.08, Hs = 0.038, Rc = 0.15, Reach = 125.0, Width = 11.5, M = 1.42, Element = "Void", Leech = 0.15, T = {"LIFESTEAL", "STUN"} },
	Bow = { A = "PiercingBeam", P = "Gun_Bow_Draw", Wu = 0.07, Snap = 0.06, Hs = 0.032, Rc = 0.13, Reach = 115.0, Width = 9.0, M = 1.45, Element = "Sky", T = {"PIERCE", "VOLLEY"} },
	Cannon = { A = "SkyfallSphere", P = "Gun_Railgun_Brace", Wu = 0.10, Snap = 0.09, Hs = 0.045, Rc = 0.18, Reach = 125.0, Width = 11.5, M = 1.75, Element = "Flame", Impact = true, T = {"AOE", "BURN"} },
	PistolRifle = { A = "SpreadVolley", P = "Gun_Pistol_Fire", Wu = 0.05, Snap = 0.06, Hs = 0.030, Rc = 0.11, Reach = 85.0, Width = 8.5, M = 1.32, Element = "Sky", T = {"RAPID SHOT"} },
}

-- ============================================================================
-- 3. SLOT 1 MARTIAL STYLE SKILL BLUEPRINTS (ALL 8 STYLES)
-- ============================================================================
local STYLE_SKILLS: { [string]: any } = {
	skyborn_combat = {
		Element = "Sky",
		WeaponArch = "SkyKata",
		Z = { N = "Gale Palm Thrust", V = "Kình Phong Chưởng", A = "TravellingWave", P = "Martial_Palm", Rng = 24, Rad = 11, D = 16, M = 2.25, Cd = 4.5, C = 8, Kb = 14, T = {"WAVE", "DASH HIT"} },
		X = { N = "Rising Sky Kick", V = "Thăng Thiên Cước", A = "PoleVaultSlam", P = "Martial_Uppercut", Rng = 20, Rad = 13, D = 14, H = 2, Intv = 0.08, M = 2.75, Cd = 7.0, C = 12, Ku = 22, Gnd = true, T = {"LAUNCH", "AOE"} },
		C = { N = "Aether Flurry", V = "Liên Hoàn Bách Chưởng", A = "DragRushSlam", P = "Martial_Flurry", Rng = 24, Rad = 15, D = 18, H = 4, Intv = 0.07, M = 3.45, Cd = 9.5, C = 16, Kb = 18, Gnd = true, T = {"4 HITS", "DRAG"} },
		V = { N = "Heaven's Ascent", V = "Thiên Phạt Sơ Khai", A = "SkybeamPillars", P = "Core_Cast_GroundSlam", Rng = 28, Rad = 18, H = 4, Intv = 0.09, M = 4.20, Cd = 13.5, C = 22, Gnd = true, Ult = true, T = {"ULTIMATE", "AOE"} },
		F = { N = "Cloud Stride", V = "Bộ Pháp Cưỡi Gió", A = "MobilityDashHit", P = "Martial_Rush", Rng = 28, Rad = 10, D = 28, M = 1.55, Cd = 4.5, C = 8, T = {"DASH HIT"} },
	},
	SkyStep = {
		Element = "Flame",
		WeaponArch = "KickKata",
		Z = { N = "Rocket Kick", V = "Hỏa Tiễn Phi Cước", A = "MobilityDashHit", P = "Martial_Kick_4", Rng = 26, Rad = 12, D = 24, H = 2, Intv = 0.07, M = 2.45, Cd = 4.6, C = 10, Brn = 2, Sh = 1.35, T = {"DASH HIT", "BURN"} },
		X = { N = "Blaze Mirror Whip", V = "Phong Đạn Trảm Không", A = "ZigZagMirrorKick", P = "Martial_Kick_2", Rng = 28, Rad = 14, D = 24, H = 3, ChCnt = 4, M = 2.95, Cd = 7.2, C = 14, Brn = 3, Ku = 18, T = {"ZIG-ZAG", "BURN"} },
		C = { N = "Vermilion Drill", V = "Chu Tước Xoáy Khoan", A = "PoleVaultSlam", P = "Martial_Kick_4", Rng = 26, Rad = 16, D = 22, H = 4, Intv = 0.07, M = 3.70, Cd = 9.8, C = 18, Brn = 4, St = 0.85, Gnd = true, Sh = 1.38, T = {"POLE-VAULT", "BURN", "STUN"} },
		V = { N = "Diable Supernova Drop", V = "Hỏa Vũ Thiên Phạt", A = "SkyfallSphere", P = "Martial_Kick_4", Rng = 30, Rad = 20, Delay = 0.30, H = 4, M = 4.50, Cd = 13.5, C = 22, Brn = 4, Gnd = true, Ult = true, T = {"ULTIMATE", "BURN"} },
		F = { N = "Flame Step Blitz", V = "Hỏa Ảnh Phi Bộ", A = "MobilityDashHit", P = "Martial_Kick_1", Rng = 30, Rad = 10, D = 30, M = 1.65, Cd = 4.4, C = 8, Brn = 2, T = {"DASH HIT", "BURN"} },
	},
	jade_dragon = {
		Element = "Jade",
		WeaponArch = "DragonClaw",
		Z = { N = "Jade Whirlpool Claw", V = "Ngọc Long Xoáy Trảo", A = "VortexPullCage", P = "Martial_Claw_3", Rng = 26, Rad = 15, H = 3, Intv = 0.08, Pull = 16, M = 2.55, Cd = 4.8, C = 10, T = {"PULL", "ARMOR SHRED"} },
		X = { N = "Emerald Dragon Jet", V = "Ngọc Long Cửu Thiên Khí", A = "PiercingBeam", P = "Martial_Palm", Rng = 34, Rad = 11, H = 3, Intv = 0.08, M = 3.10, Cd = 7.8, C = 14, Kb = 16, T = {"PIERCE", "BEAM"} },
		C = { N = "Coiling Dragon Crush", V = "Cuộn Long Phá Địa", A = "DragRushSlam", P = "Martial_Claw_4", Rng = 28, Rad = 16, D = 24, H = 3, Intv = 0.08, M = 3.95, Cd = 10.8, C = 18, Pull = 14, Gnd = true, T = {"DRAG", "PULL", "GUARD BREAK"} },
		V = { N = "Imperial Dragon Roar", V = "Long Hoàng Chấn Thế", A = "GroundMonolithShatter", P = "Core_Cast_GroundSlam", Rng = 32, Rad = 21, H = 4, M = 4.70, Cd = 13.5, C = 22, St = 1.0, Gnd = true, Ult = true, T = {"ULTIMATE", "STUN"} },
		F = { N = "Serpent Scale Glide", V = "Du Long Bộ", A = "MobilityDashHit", P = "Martial_Rush", Rng = 30, Rad = 10, D = 30, M = 1.65, Cd = 4.4, C = 8, T = {"DASH HIT"} },
	},
	thunder_talon = {
		Element = "Lightning",
		WeaponArch = "VoltTalon",
		Z = { N = "Volt Snap Kick", V = "Điện Thiểm Cước", A = "BlinkDelayedSlash", P = "Martial_Claw_1", Rng = 28, Rad = 12, D = 26, Delay = 0.22, H = 2, M = 2.75, Cd = 4.5, C = 10, St = 0.65, T = {"BLINK", "DELAYED SLASH", "STUN"} },
		X = { N = "Arc Chain Talon", V = "Thiên Lôi Liên Xích", A = "ChainLightning", P = "Core_Cast_ChainBolt", Rng = 28, Rad = 16, ChCnt = 5, ChRad = 18, H = 2, M = 3.40, Cd = 7.5, C = 15, St = 1.0, T = {"CHAIN x5", "STUN"} },
		C = { N = "Storm Talon Barrage", V = "Bão Lôi Vạn Trảo", A = "ZigZagMirrorKick", P = "Martial_Flurry", Rng = 30, Rad = 18, D = 26, H = 6, ChCnt = 6, Intv = 0.06, M = 4.30, Cd = 10.5, C = 20, St = 1.2, Gnd = true, T = {"6 HITS", "ZIG-ZAG", "STUN"} },
		V = { N = "Kirin Thunder Crash", V = "Lôi Lân Giáng Thế", A = "SkybeamPillars", P = "Core_Cast_GroundSlam", Rng = 32, Rad = 22, H = 5, M = 4.95, Cd = 13.8, C = 24, St = 1.3, Gnd = true, Ult = true, T = {"ULTIMATE", "STUN"} },
		F = { N = "Flash Volt Step", V = "Lôi Ảnh Tật Bộ", A = "MobilityDashHit", P = "Core_Dash_Pose", Rng = 34, Rad = 10, D = 34, M = 1.75, Cd = 4.2, C = 8, St = 0.45, T = {"BLINK", "DASH HIT"} },
	},
	solar_ashura = {
		Element = "Flame",
		WeaponArch = "SolarHeavy",
		Z = { N = "Ignited Knuckle", V = "Viêm Dương Thiết Quyền", A = "TravellingWave", P = "Martial_Punch_4", Rng = 26, Rad = 13, D = 18, M = 3.00, Cd = 5.0, C = 11, Brn = 3, Kb = 18, Sh = 1.38, T = {"WAVE", "BURN", "GUARD BREAK"} },
		X = { N = "Eruption Uppercut", V = "Dung Nham Xung Thiên Quyền", A = "PoleVaultSlam", P = "Martial_Uppercut", Rng = 24, Rad = 17, D = 18, H = 2, M = 3.70, Cd = 8.2, C = 16, Brn = 4, Ku = 26, Gnd = true, Sh = 1.40, T = {"LAUNCH", "BURN", "GUARD BREAK"} },
		C = { N = "Ashura Sunburst", V = "Tu La Nhật Thực Bạo", A = "DragRushSlam", P = "Core_Cast_GroundSlam", Rng = 28, Rad = 21, D = 22, H = 4, Intv = 0.08, M = 4.65, Cd = 11.5, C = 22, Brn = 5, Haz = "MagmaPool", HazDur = 3.2, Gnd = true, Sh = 1.45, T = {"DRAG", "LAVA POOL", "BURN"} },
		V = { N = "Nine-Sun Cataclysm", V = "Cửu Nhật Hủy Diệt", A = "MeteorShower", P = "Core_Cast_SkySphere", Rng = 34, Rad = 24, H = 6, M = 5.25, Cd = 14.0, C = 24, Brn = 5, Haz = "MagmaPool", HazDur = 3.8, Gnd = true, Ult = true, T = {"ULTIMATE", "METEOR", "LAVA POOL"} },
		F = { N = "Cinder Charge", V = "Viêm Đế Đột Xung", A = "MobilityDashHit", P = "Martial_Rush", Rng = 30, Rad = 11, D = 30, M = 1.80, Cd = 4.5, C = 9, Brn = 2, T = {"DASH HIT", "BURN"} },
	},
	celestial_godhuman = {
		Element = "Celestial",
		WeaponArch = "CelestialSix",
		Z = { N = "Soaring Beast Barrage", V = "Bách Thú Tinh Quyền", A = "BlinkDelayedSlash", P = "Martial_Flurry", Rng = 32, Rad = 15, D = 28, Delay = 0.22, H = 5, Intv = 0.06, M = 3.35, Cd = 4.8, C = 12, St = 0.70, T = {"BLINK", "5 HITS", "DELAYED SLASH"} },
		X = { N = "Heaven & Earth Shatter", V = "Thiên Địa Phá Toái", A = "TravellingWave", P = "Martial_Palm", Rng = 30, Rad = 20, H = 3, Intv = 0.08, M = 4.25, Cd = 8.0, C = 18, St = 1.1, Kb = 22, Gnd = true, Sh = 1.40, T = {"WAVE", "STUN", "GUARD BREAK"} },
		C = { N = "Sixth Realm Celestial Impact", V = "Lục Giới Thần Xung", A = "DragRushSlam", P = "Core_Cast_GroundSlam", Rng = 36, Rad = 23, D = 30, H = 6, Intv = 0.06, M = 5.45, Cd = 11.8, C = 24, St = 1.4, Gnd = true, Sh = 1.45, T = {"6 HITS", "DRAG", "STUN"} },
		V = { N = "Paragon Star Judgment", V = "Thần Võ Vạn Giới", A = "SkyfallSphere", P = "Core_Cast_SkySphere", Rng = 36, Rad = 25, Delay = 0.34, H = 6, M = 5.80, Cd = 14.5, C = 26, St = 1.4, Gnd = true, Ult = true, T = {"ULTIMATE", "AOE", "STUN"} },
		F = { N = "Astral Sovereign Step", V = "Thần Tốc Tinh Bộ", A = "MobilityDashHit", P = "Core_Dash_Pose", Rng = 36, Rad = 11, D = 36, M = 1.90, Cd = 4.2, C = 9, T = {"BLINK", "DASH HIT"} },
	},
	SanguineVoidArt = {
		Element = "Void",
		WeaponArch = "SanguineDrain",
		Z = { N = "Bloodscar Drain", V = "Huyết Trảo Hút Hồn", A = "DragRushSlam", P = "Martial_Claw_4", Rng = 28, Rad = 14, D = 26, H = 5, Intv = 0.06, M = 3.40, Cd = 4.8, C = 12, Leech = 0.22, T = {"LIFESTEAL", "DRAG", "5 HITS"} },
		X = { N = "Scarlet Rift Volley", V = "Huyết Nguyệt Xung Kích", A = "SpreadVolley", P = "Martial_Claw_2", Rng = 32, Rad = 19, H = 3, Intv = 0.08, M = 4.30, Cd = 8.4, C = 18, St = 1.1, Leech = 0.16, T = {"VOLLEY", "LIFESTEAL", "STUN"} },
		C = { N = "Devouring Void Maw", V = "Thực Không Huyết Ngục", A = "VortexPullCage", P = "Core_Cast_Vortex", Rng = 34, Rad = 22, D = 24, H = 6, Intv = 0.07, Pull = 20, M = 5.50, Cd = 11.8, C = 24, St = 1.4, Leech = 0.28, T = {"PULL", "LIFESTEAL", "STUN"} },
		V = { N = "Crimson Abyssal Feast", V = "Huyết Hải Thực Thiên", A = "HarmonicSiphonWave", P = "Core_Cast_Vortex", Rng = 36, Rad = 24, H = 6, Pull = 22, M = 5.85, Cd = 14.5, C = 26, St = 1.4, Leech = 0.30, Ult = true, T = {"ULTIMATE", "LIFESTEAL", "PULL"} },
		F = { N = "Batshadow Rift Step", V = "Huyết Ảnh Độn", A = "MobilityDashHit", P = "Core_Dash_Pose", Rng = 36, Rad = 11, D = 36, M = 1.85, Cd = 4.2, C = 9, Leech = 0.12, T = {"DASH HIT", "LIFESTEAL"} },
	},
	ChronoVoidPalm = {
		Element = "Void",
		WeaponArch = "ChronoPalm",
		Z = { N = "Chrono Ripple Palm", V = "Chưởng Gợn Thời Gian", A = "BlinkDelayedSlash", P = "Martial_Palm", Rng = 30, Rad = 15, D = 26, Delay = 0.25, H = 4, Intv = 0.07, M = 3.50, Cd = 4.6, C = 12, St = 0.80, T = {"BLINK", "DELAYED SLASH", "STUN"} },
		X = { N = "Stasis Collapse", V = "Nhãn Ấn Ngưng Đọng", A = "VortexPullCage", P = "Core_Cast_Vortex", Rng = 32, Rad = 20, H = 3, Intv = 0.09, Pull = 19, M = 4.40, Cd = 8.2, C = 18, St = 1.2, Haz = "ChronoField", HazDur = 4.0, T = {"PULL", "CHRONO FIELD", "STUN"} },
		C = { N = "Genesis Singularity Strike", V = "Vạn Kiếp Quy Không Chưởng", A = "GroundMonolithShatter", P = "Core_Cast_GroundSlam", Rng = 36, Rad = 24, D = 28, H = 6, Intv = 0.07, M = 5.70, Cd = 11.5, C = 24, St = 1.5, Haz = "ChronoField", HazDur = 4.5, Gnd = true, Sh = 1.42, T = {"CHRONO FIELD", "STUN", "AOE"} },
		V = { N = "Aion Epoch Severance", V = "Thời Không Đoạn Kiếp", A = "SkybeamPillars", P = "Core_Cast_SkySphere", Rng = 38, Rad = 26, H = 6, M = 6.00, Cd = 14.5, C = 26, St = 1.6, Haz = "ChronoField", HazDur = 5.0, Gnd = true, Ult = true, T = {"ULTIMATE", "CHRONO FIELD", "STUN"} },
		F = { N = "Temporal Rewind Step", V = "Nghịch Thời Bộ", A = "MobilityDashHit", P = "Core_Dash_Pose", Rng = 36, Rad = 11, D = 36, M = 1.90, Cd = 4.2, C = 9, T = {"BLINK", "DASH HIT"} },
	},
}

-- ============================================================================
-- 4. SLOT 2 AETHER CORE SKILL BLUEPRINTS (ALL 12 CORES + V2 + DRAGON TIERS 0/1/2)
-- ============================================================================
local CORE_SKILLS: { [string]: any } = {
	ThunderRumbleCore = {
		Element = "Lightning",
		Z = { N = "Thunder Drake", V = "Lôi Long Phá", Awk = "Raigo Dragon Bolt V2", AwkVI = "Lôi Long Giáng Thế V2", A = "ChainLightning", P = "Core_Cast_ChainBolt", Rng = 34, Rad = 12, ChCnt = 5, ChRad = 20, H = 2, M = 2.90, Cd = 5.5, C = 12, St = 0.75, T = {"CHAIN x5", "STUN"} },
		X = { N = "Sky Thunder Flash", V = "Thiên Lôi Giáng Thế", Awk = "Sky Judgment Pillar V2", AwkVI = "Cột Thiên Lôi Phán Quyết V2", A = "BlinkDelayedSlash", P = "Core_Dash_Pose", Rng = 30, Rad = 15, D = 28, Delay = 0.24, H = 2, M = 3.50, Cd = 9.5, C = 16, St = 1.0, T = {"BLINK", "DELAYED SLASH", "STUN"} },
		C = { N = "Storm Judgement Cage", V = "Lồng Điện Phán Quyết", Awk = "Plasma Storm Dome V2", AwkVI = "Lồng Điện Từ Trường V2", A = "VortexPullCage", P = "Core_Cast_Vortex", Rng = 30, Rad = 17, H = 4, Intv = 0.08, Pull = 15, M = 4.00, Cd = 12.0, C = 20, St = 1.1, Haz = "StormCage", HazDur = 3.6, T = {"PULL", "STORM CAGE", "STUN"} },
		V = { N = "Raigo Thunderball", V = "Quả Cầu Lôi Thần", Awk = "Thundercloud Apocalypse Orb V2", AwkVI = "Lôi Nghinh Diệt Thế V2", A = "SkyfallSphere", P = "Core_Cast_SkySphere", Rng = 38, Rad = 26, Delay = 0.42, H = 5, Intv = 0.09, M = 5.40, Cd = 19.0, C = 30, St = 1.6, Haz = "StormCage", HazDur = 4.2, Gnd = true, Ult = true, T = {"ULTIMATE", "STORM CAGE", "STUN"} },
		F = { N = "Voltaic Blink-Dash", V = "Lôi Bộ Tam Đoạn", Awk = "Triple Flash Teleport V2", AwkVI = "Tam Đoạn Điện Thiểm V2", A = "MobilityDashHit", P = "Core_Dash_Pose", Rng = 38, Rad = 11, D = 38, H = 1, M = 1.80, Cd = 4.5, C = 10, St = 0.55, T = {"BLINK", "DASH HIT", "STUN"} },
	},
	GlacierIceCore = {
		Element = "Frost",
		Z = { N = "Ice Shards", V = "Băng Tiêu Tam Liên", Awk = "Absolute Zero Lances V2", AwkVI = "Băng Thương Tuyệt Độ V2", A = "MultiLaneSpikes", P = "Core_Cast_GroundSlam", Rng = 28, Rad = 11, H = 3, Intv = 0.07, M = 2.50, Cd = 5.0, C = 10, Frz = 1.6, Gnd = true, T = {"SPIKES", "FREEZE"} },
		X = { N = "Glacial Monolith", V = "Băng Sơn Trỗi Dậy", Awk = "Glacial Surge Wave V2", AwkVI = "Sóng Thần Băng Vĩnh Cửu V2", A = "GroundMonolithShatter", P = "Core_Cast_GroundSlam", Rng = 26, Rad = 15, H = 2, M = 3.00, Cd = 9.0, C = 15, Frz = 1.8, Sh = 1.35, Gnd = true, T = {"FREEZE+SHATTER", "LAUNCH"} },
		C = { N = "Cryo Phoenix", V = "Băng Điểu Xung Kích", Awk = "Cryo Pheasant Talon V2", AwkVI = "Băng Điểu Tuyệt Sát V2", A = "TravellingWave", P = "Core_Cast_Beam", Rng = 34, Rad = 13, H = 2, M = 3.50, Cd = 12.0, C = 18, Frz = 1.8, Sh = 1.35, T = {"WAVE", "FREEZE"} },
		V = { N = "Absolute Zero Epoch", V = "Tuyệt Độ Hàn Băng", Awk = "Eternal Ice Age V2", AwkVI = "Kỷ Băng Hà Vĩnh Cửu V2", A = "VortexPullCage", P = "Core_Cast_Vortex", Rng = 30, Rad = 25, H = 5, Intv = 0.09, Pull = 14, M = 4.70, Cd = 18.0, C = 26, Frz = 2.6, Sh = 1.40, Haz = "FrostSheet", HazDur = 4.5, Gnd = true, Ult = true, T = {"ULTIMATE", "FROST SHEET", "FREEZE"} },
		F = { N = "Glacier Ice Skate", V = "Trượt Băng Tốc Độ", Awk = "Glacier Skate Overdrive V2", AwkVI = "Trượt Băng Cực Quang V2", A = "MobilityDashHit", P = "Core_Dash_Pose", Rng = 38, Rad = 10.5, D = 38, H = 1, M = 1.45, Cd = 5.5, C = 10, Frz = 1.2, T = {"DASH HIT", "FREEZE"} },
	},
	StarforgedMagmaCore = {
		Element = "Magma",
		Z = { N = "Magma Clap", V = "Dung Nham Thiết Chưởng", Awk = "Volcanic Hound Fang V2", AwkVI = "Minh Khuyển Dung Nham V2", A = "TravellingWave", P = "Core_Cast_GroundSlam", Rng = 26, Rad = 13, H = 2, M = 2.90, Cd = 5.2, C = 12, Brn = 3, Haz = "MagmaPool", HazDur = 3.4, Sh = 1.40, Gnd = true, T = {"LAVA POOL", "BURN"} },
		X = { N = "Hellhound Lunge", V = "Nanh Chó Địa Ngục", Awk = "Tectonic Eruption Clamp V2", AwkVI = "Đại Địa Phun Trào V2", A = "DragRushSlam", P = "Core_Dash_Pose", Rng = 26, Rad = 14, D = 24, H = 3, M = 3.40, Cd = 9.0, C = 16, Brn = 4, Haz = "MagmaPool", HazDur = 3.6, Sh = 1.40, Gnd = true, T = {"DRAG", "LAVA POOL", "BURN"} },
		C = { N = "Starforged Magma Fist", V = "Cú Đấm Nham Thạch", Awk = "Starcore Lava Hound V2", AwkVI = "Hỏa Ngục Tinh Cầu V2", A = "TravellingWave", P = "Core_Cast_Beam", Rng = 32, Rad = 16, H = 3, M = 3.90, Cd = 11.5, C = 18, Brn = 4, Kb = 16, Haz = "MagmaPool", HazDur = 3.8, Sh = 1.42, Gnd = true, T = {"WAVE", "LAVA POOL", "BURN"} },
		V = { N = "Meteor Volcano", V = "Mưa Sao Băng Dung Nham", Awk = "Apocalyptic Meteor Shower V2", AwkVI = "Mưa Thiên Thạch Dung Nham V2", A = "MeteorShower", P = "Core_Cast_SkySphere", Rng = 36, Rad = 26, Delay = 0.34, H = 8, Intv = 0.08, M = 5.20, Cd = 18.0, C = 28, Brn = 5, Haz = "MagmaPool", HazDur = 4.5, Sh = 1.45, Gnd = true, Ult = true, T = {"ULTIMATE", "METEOR", "LAVA POOL"} },
		F = { N = "Magma Hound Flight", V = "Cưỡi Thú Dung Nham", Awk = "Magma Beast Glide V2", AwkVI = "Phi Thăng Nham Thạch V2", A = "MobilityDashHit", P = "Core_Dash_Pose", Rng = 26, Rad = 12, D = 24, M = 1.70, Cd = 6.0, C = 10, Brn = 2, T = {"3D FLIGHT", "BURN"} },
	},
	AstralGravityCore = {
		Element = "Gravity",
		Z = { N = "Gravity Repulse", V = "Xung Lực Đẩy", Awk = "Graviton Crush Wave V2", AwkVI = "Sóng Trọng Lực Nghiền Nát V2", A = "TravellingWave", P = "Core_Cast_Beam", Rng = 28, Rad = 13, H = 2, M = 2.80, Cd = 5.5, C = 12, Kb = 22, Sh = 1.35, T = {"WAVE", "GUARD BREAK"} },
		X = { N = "Tenfold Gravity Crush", V = "Vùng Trọng Lực Đè Nén", Awk = "Zero-G Pinion Slam V2", AwkVI = "Trọng Trường Khóa Chặt V2", A = "VortexPullCage", P = "Core_Cast_Vortex", Rng = 28, Rad = 17, H = 4, Intv = 0.09, Pull = 20, M = 3.40, Cd = 10.0, C = 16, St = 1.1, Gnd = true, Sh = 1.38, T = {"PULL", "STUN", "AOE"} },
		C = { N = "Twin Starfall", V = "Triệu Hồi Thiên Thạch", Awk = "Black Hole Convergence V2", AwkVI = "Kỳ Điểm Hố Đen V2", A = "MeteorShower", P = "Core_Cast_SkySphere", Rng = 36, Rad = 18, Delay = 0.30, H = 2, Intv = 0.14, Pull = 18, M = 4.10, Cd = 12.5, C = 20, St = 1.0, Gnd = true, Sh = 1.40, T = {"METEOR", "PULL"} },
		V = { N = "Astral Meteor Cataclysm", V = "Mưa Thiên Thạch Vũ Trụ", Awk = "Planetary Asteroid Fall V2", AwkVI = "Đại Tinh Thạch Va Chạm V2", A = "MeteorShower", P = "Core_Cast_SkySphere", Rng = 40, Rad = 27, Delay = 0.38, H = 8, Intv = 0.08, Pull = 24, M = 5.30, Cd = 19.0, C = 30, St = 1.4, Gnd = true, Sh = 1.45, Ult = true, T = {"ULTIMATE", "METEOR", "PULL"} },
		F = { N = "Orbital Boulder Flight", V = "Cưỡi Đá Không Trung", Awk = "Orbital Meteor Surf V2", AwkVI = "Cưỡi Thiên Thạch Tinh Cầu V2", A = "MobilityDashHit", P = "Core_Dash_Pose", Rng = 26, Rad = 12, D = 24, M = 1.50, Cd = 6.0, C = 10, T = {"3D FLIGHT"} },
	},
	SolarFlameCore = {
		Element = "Flame",
		Z = { N = "Fire Bullets", V = "Hỏa Đạn Liên Hoàn", Awk = "Blue Flare Bullets V2", AwkVI = "Thanh Viêm Liên Đạn V2", A = "SpreadVolley", P = "Core_Cast_Beam", Rng = 30, Rad = 12, H = 4, Intv = 0.07, M = 2.50, Cd = 5.0, C = 10, Brn = 3, Sh = 1.35, T = {"VOLLEY", "BURN"} },
		X = { N = "Prominence Fist Beam", V = "Hỏa Quyền Xuyên Thấu", Awk = "Prominence Pillar V2", AwkVI = "Cột Lửa Nhật Thực V2", A = "PiercingBeam", P = "Core_Cast_Beam", Rng = 34, Rad = 12, H = 3, Intv = 0.08, M = 2.90, Cd = 8.5, C = 15, Brn = 3, Kb = 18, Sh = 1.38, T = {"PIERCE", "BURN"} },
		C = { N = "Flame Pillar Eruption", V = "Hỏa Trụ Xung Thiên", Awk = "Hellfire Vortex V2", AwkVI = "Vòng Xoáy Luyện Ngục V2", A = "SkybeamPillars", P = "Core_Cast_GroundSlam", Rng = 26, Rad = 17, H = 4, Intv = 0.08, M = 3.40, Cd = 11.0, C = 18, Brn = 4, Ku = 22, Gnd = true, Sh = 1.38, T = {"LAUNCH", "BURN", "AOE"} },
		V = { N = "Solar Emperor", V = "Thái Dương Viêm Đế", Awk = "Cruel Sun Supernova V2", AwkVI = "Đại Nhật Hủy Diệt V2", A = "SkyfallSphere", P = "Core_Cast_SkySphere", Rng = 36, Rad = 26, Delay = 0.40, H = 5, M = 4.60, Cd = 18.0, C = 26, Brn = 5, Haz = "MagmaPool", HazDur = 3.8, Gnd = true, Sh = 1.45, Ult = true, T = {"ULTIMATE", "BURN", "LAVA POOL"} },
		F = { N = "Rocket Flight", V = "Hỏa Tiễn Phi Hành", Awk = "Blazing Rocket Trail V2", AwkVI = "Hỏa Tiễn Xuyên Mây V2", A = "MobilityDashHit", P = "Core_Dash_Pose", Rng = 26, Rad = 12, D = 24, M = 1.40, Cd = 5.5, C = 10, Brn = 2, T = {"3D FLIGHT", "BURN"} },
	},
	GaleCore = {
		Element = "Sky",
		Z = { N = "Gale Blades", V = "Phong Đao", Awk = "Tempest Razor V2", AwkVI = "Lưỡi Đao Siêu Bão V2", A = "SpreadVolley", P = "Core_Cast_Beam", Rng = 28, Rad = 11, H = 3, Intv = 0.07, M = 2.20, Cd = 4.5, C = 8, T = {"VOLLEY", "WAVE"} },
		X = { N = "Cyclone Burst", V = "Lốc Xoáy Không Trung", Awk = "Hurricane Prison V2", AwkVI = "Ngục Tù Lốc Xoáy V2", A = "TravellingWave", P = "Core_Cast_Vortex", Rng = 26, Rad = 14, H = 3, M = 2.60, Cd = 7.0, C = 12, Kb = 22, Ku = 18, T = {"LAUNCH", "WAVE"} },
		C = { N = "Tornado Crush", V = "Bão Phong Nghiền Nát", Awk = "Skyward Stratosphere V2", AwkVI = "Bão Tầng Bình Lưu V2", A = "VortexPullCage", P = "Core_Cast_Vortex", Rng = 28, Rad = 17, H = 4, Intv = 0.08, Pull = 18, M = 3.10, Cd = 9.5, C = 16, Haz = "StormCage", HazDur = 3.0, T = {"PULL", "VORTEX"} },
		V = { N = "Skyborn Typhoon", V = "Đại Cuồng Phong", Awk = "Eye of the Sovereign Storm V2", AwkVI = "Đại Phong Thần Nộ V2", A = "VortexPullCage", P = "Core_Cast_SkySphere", Rng = 32, Rad = 25, H = 5, Intv = 0.09, Pull = 24, M = 3.90, Cd = 14.0, C = 22, St = 1.0, Ult = true, T = {"ULTIMATE", "PULL", "AOE"} },
		F = { N = "Wind Ride", V = "Cưỡi Gió", Awk = "Supersonic Jetstream V2", AwkVI = "Cánh Gió Siêu Thanh V2", A = "MobilityDashHit", P = "Core_Dash_Pose", Rng = 26, Rad = 11, D = 24, M = 1.40, Cd = 5.0, C = 8, T = {"3D FLIGHT"} },
	},
	SandstoneCore = {
		Element = "Sand",
		Z = { N = "Desert Spada", V = "Sa Đao", Awk = "Dune Guillotine V2", AwkVI = "Lưỡi Hái Cát Vàng V2", A = "TravellingWave", P = "Core_Cast_GroundSlam", Rng = 28, Rad = 11, H = 2, M = 2.30, Cd = 5.0, C = 10, Gnd = true, T = {"WAVE", "ARMOR SHRED"} },
		X = { N = "Sand Coffin", V = "Quan Tài Cát", Awk = "Abyssal Quicksand Pit V2", AwkVI = "Hố Cát Tử Thần V2", A = "SandCoffinImplode", P = "Core_Cast_Vortex", Rng = 25, Rad = 14, Delay = 0.30, H = 3, Pull = 18, M = 2.80, Cd = 9.0, C = 15, St = 1.0, T = {"IMPLODE", "PULL", "STUN"} },
		C = { N = "Quicksand Vortex", V = "Hố Cát Tử Thần", Awk = "Pharaoh Sandstorm V2", AwkVI = "Bão Cát Hoàng Đế V2", A = "VortexPullCage", P = "Core_Cast_Vortex", Rng = 28, Rad = 17, H = 4, Intv = 0.09, Pull = 20, M = 3.30, Cd = 12.0, C = 18, Haz = "Quicksand", HazDur = 3.8, Gnd = true, T = {"QUICKSAND", "PULL"} },
		V = { N = "Sandstorm Burial", V = "Bão Cát Hoàng Kim", Awk = "Desert Burial Cataclysm V2", AwkVI = "Đại Mộ Sa Mạc V2", A = "SandCoffinImplode", P = "Core_Cast_SkySphere", Rng = 34, Rad = 25, Delay = 0.35, H = 5, Pull = 26, M = 4.20, Cd = 17.0, C = 25, St = 1.2, Haz = "Quicksand", HazDur = 4.5, Gnd = true, Ult = true, T = {"ULTIMATE", "QUICKSAND", "IMPLODE"} },
		F = { N = "Sand Flight", V = "Cát Lưu", Awk = "Phantom Sand Flight V2", AwkVI = "Lốc Cát Phi Hành V2", A = "MobilityDashHit", P = "Core_Dash_Pose", Rng = 24, Rad = 11, D = 24, M = 1.30, Cd = 6.0, C = 10, T = {"3D FLIGHT"} },
	},
	CelestialLightCore = {
		Element = "Light",
		Z = { N = "Sacred Light Ray", V = "Tia Sáng Phán Quyết", Awk = "Divine Photon Spear V2", AwkVI = "Thánh Thương Ánh Sáng V2", A = "PiercingBeam", P = "Core_Cast_Beam", Rng = 42, Rad = 10, H = 2, M = 2.70, Cd = 4.8, C = 10, Kb = 16, T = {"PIERCE", "BEAM"} },
		X = { N = "Photon Jewel Volley", V = "Mưa Kiếm Ánh Sáng", Awk = "Mirror Star Reflection V2", AwkVI = "Kính Quang Phản Chiếu V2", A = "SpreadVolley", P = "Core_Cast_Beam", Rng = 34, Rad = 15, H = 6, Intv = 0.06, M = 3.20, Cd = 8.5, C = 15, T = {"6 HITS", "VOLLEY"} },
		C = { N = "Yata Mirror Kick", V = "Phản Quang Cước", Awk = "Lightspeed Judgment Kick V2", AwkVI = "Quang Tốc Thần Cước V2", A = "ZigZagMirrorKick", P = "Martial_Kick_4", Rng = 30, Rad = 13, D = 30, ChCnt = 5, H = 4, M = 3.70, Cd = 11.0, C = 18, St = 0.85, Gnd = true, T = {"MIRROR", "ZIG-ZAG", "STUN"} },
		V = { N = "Skybeam Barrage", V = "Đại Quang Vũ", Awk = "Heaven's Starfall Barrage V2", AwkVI = "Vạn Tinh Thiên Phạt V2", A = "SkybeamPillars", P = "Core_Cast_SkySphere", Rng = 36, Rad = 25, H = 7, Intv = 0.07, M = 4.90, Cd = 17.0, C = 25, St = 1.1, Gnd = true, Ult = true, T = {"ULTIMATE", "7 HITS", "AOE"} },
		F = { N = "Light Flight", V = "Hóa Tia Sáng", Awk = "Relativistic Beam Flight V2", AwkVI = "Tia Sáng Đổi Hướng V2", A = "MobilityDashHit", P = "Core_Dash_Pose", Rng = 34, Rad = 11, D = 32, M = 1.60, Cd = 4.5, C = 8, T = {"3D FLIGHT"} },
	},
	DimensionalPortalCore = {
		Element = "Portal",
		Z = { N = "Portal Severance Dash", V = "Đột Kích Xuyên Không", Awk = "Quantum Severance Dash V2", AwkVI = "Trảm Không Gian Lượng Tử V2", A = "BlinkDelayedSlash", P = "Core_Dash_Pose", Rng = 28, Rad = 12, D = 28, Delay = 0.24, H = 3, M = 2.80, Cd = 5.0, C = 12, St = 0.70, T = {"BLINK", "DELAYED SLASH"} },
		X = { N = "Parallel Rift Escape", V = "Ẩn Thân Dị Giới", Awk = "Void Phase Sanctuary V2", AwkVI = "Lãnh Địa Hư Không Ẩn V2", A = "RiftPhaseEscape", P = "Core_Dash_Pose", Rng = 26, Rad = 14, D = 20, Delay = 0.28, H = 2, M = 3.20, Cd = 10.0, C = 16, St = 0.85, T = {"PHASE", "IFRAME", "BLINK"} },
		C = { N = "World Warp Gate", V = "Cổng Dịch Chuyển Thế Giới", Awk = "Omniversal World Gate V2", AwkVI = "Đại Cổng Dịch Chuyển 20 Đảo V2", A = "PortalWorldGate", P = "Core_Cast_Vortex", Rng = 34, Rad = 14, H = 2, M = 3.80, Cd = 12.0, C = 20, T = {"WORLD GATE", "PORTAL"} },
		V = { N = "Dimensional Collapse", V = "Chiều Không Gian Thứ Tư", Awk = "Collapsed Dimension Prison V2", AwkVI = "Không Gian Sụp Đổ V2", A = "VortexPullCage", P = "Core_Cast_Vortex", Rng = 36, Rad = 24, Delay = 0.34, H = 5, Intv = 0.08, Pull = 22, M = 5.10, Cd = 20.0, C = 30, St = 1.3, Haz = "ChronoField", HazDur = 4.0, Ult = true, T = {"ULTIMATE", "PULL", "CHRONO FIELD"} },
		F = { N = "Quantum Rift Step", V = "Bước Nhảy Lượng Tử", Awk = "Rift Step Blink V2", AwkVI = "Bước Nhảy Xuyên Không V2", A = "MobilityDashHit", P = "Core_Dash_Pose", Rng = 42, Rad = 10.5, D = 42, M = 1.70, Cd = 4.0, C = 8, T = {"BLINK", "DASH HIT"} },
	},
	SolarTitanCore = {
		Element = "Light",
		Z = { N = "Transform: Solar Titan", V = "Hóa Kim Thân Khổng Lồ", Awk = "Sovereign Golden Impact V2", AwkVI = "Đại Kim Thân Thức Tỉnh V2", A = "TransformToggle", P = "Core_Cast_GroundSlam", Rng = 26, Rad = 18, H = 1, M = 2.60, Cd = 4.0, C = 10, Gnd = true, Ult = true, T = {"TRANSFORM", "AOE"} },
		X = { N = "Heavenly Impact", V = "Thiên Địa Chấn Động", Awk = "Heavenly Halo Judgment V2", AwkVI = "Vòng Thánh Quang Phán Xét V2", A = "PoleVaultSlam", P = "Core_Cast_GroundSlam", Rng = 28, Rad = 18, D = 20, Delay = 0.22, H = 2, M = 3.40, Cd = 9.0, C = 16, St = 1.0, Ku = 20, Gnd = true, Sh = 1.40, T = {"POLE-VAULT", "STUN", "GUARD BREAK"} },
		C = { N = "Solar Palm Wave", V = "Thiên Quang Thần Chưởng", Awk = "Divine Supernova Pillar V2", AwkVI = "Thánh Trụ Quang Minh V2", A = "TravellingWave", P = "Core_Cast_Beam", Rng = 34, Rad = 16, H = 3, Intv = 0.08, M = 4.10, Cd = 12.0, C = 20, Kb = 22, Sh = 1.38, T = {"WAVE", "GUARD BREAK"} },
		V = { N = "Twilight of the Gods", V = "Hoàng Hôn Chư Thần", Awk = "Twilight of the Gods V2", AwkVI = "Hoàng Hôn Chư Thần Kim Thân V2", A = "SkybeamPillars", P = "Core_Cast_SkySphere", Rng = 38, Rad = 27, H = 8, Intv = 0.07, M = 5.50, Cd = 18.0, C = 28, St = 1.4, Gnd = true, Sh = 1.45, Ult = true, T = {"ULTIMATE", "8 HITS", "STUN"} },
		F = { N = "Titan Seismic Leap", V = "Bước Nhảy Kim Thân", Awk = "Radiant Ascent Leap V2", AwkVI = "Kim Thân Đạp Không V2", A = "MobilityDashHit", P = "Core_Cast_GroundSlam", Rng = 34, Rad = 14, D = 34, M = 2.20, Cd = 6.0, C = 10, Gnd = true, Sh = 1.35, T = {"DASH HIT", "AOE"} },
	},
	AetherflowCore = {
		Element = "Aether",
		Z = { N = "Searing Missile Jab", V = "Thiết Quyền Tinh Thể", Awk = "Searing Aether Missile V2", AwkVI = "Pháo Tinh Chất Nóng Chảy V2", A = "TravellingWave", P = "Martial_Punch_4", Rng = 30, Rad = 13, H = 2, M = 3.10, Cd = 5.5, C = 12, Kb = 20, St = 0.70, Sh = 1.35, T = {"WAVE", "GUARD BREAK"} },
		X = { N = "Sticky Aether Snare", V = "Gai Tinh Thể Trỗi Dậy", Awk = "Crystalline Spike Skewers V2", AwkVI = "Rừng Gai Huyết Tinh V2", A = "SandCoffinImplode", P = "Core_Cast_Vortex", Rng = 28, Rad = 15, Delay = 0.28, H = 4, Pull = 18, M = 3.70, Cd = 9.5, C = 16, St = 1.0, Gnd = true, T = {"IMPLODE", "PULL", "STUN"} },
		C = { N = "Carved Aether Roller", V = "Vòng Xoáy Nghiền Nát", Awk = "Piercing Chariot Wheel V2", AwkVI = "Bánh Xe Gai Nghiền Nát V2", A = "DragRushSlam", P = "Core_Dash_Pose", Rng = 30, Rad = 15, D = 28, H = 4, Intv = 0.07, Pull = 18, M = 4.30, Cd = 12.0, C = 20, St = 1.1, Gnd = true, Sh = 1.38, T = {"DRAG", "PULL", "STUN"} },
		V = { N = "Dimensional Fist Fusillade", V = "Liên Hoàn Bách Quyền", Awk = "Dimensional Aether Fist Fusillade V2", AwkVI = "Bách Quyền Không Gian V2", A = "SpreadVolley", P = "Martial_Flurry", Rng = 36, Rad = 23, H = 12, Intv = 0.055, M = 5.70, Cd = 19.0, C = 30, St = 1.3, Sh = 1.40, Ult = true, T = {"ULTIMATE", "12 HITS", "STUN"} },
		F = { N = "Aether Roller Dash", V = "Bánh Xe Tốc Độ", Awk = "Rolling Aether Wheel V2", AwkVI = "Vòng Xoáy Thần Tốc V2", A = "MobilityDashHit", P = "Core_Dash_Pose", Rng = 40, Rad = 12, D = 40, M = 1.90, Cd = 5.5, C = 10, Kb = 12, T = {"DASH HIT", "GUARD BREAK"} },
	},
	AbyssalSovereignCore = {
		Element = "Void",
		Z = { N = "Draconic Bolo Breath", V = "Hỏa Long Liên Đạn", Awk = "Abyssal Heat Ray V2", AwkVI = "Long Tức Xuyên Thiên V2", A = "PiercingBeam", P = "Core_Cast_Beam", Rng = 36, Rad = 12, H = 4, Intv = 0.08, M = 2.80, Cd = 6.0, C = 14, Brn = 3, Kb = 16, Sh = 1.40, T = {"PIERCE", "BURN"} },
		X = { N = "Sovereign Talon Rush", V = "Bán Long Đột Trảo", Awk = "Void Sovereign Talons V2", AwkVI = "Tuyệt Trảo Hắc Long Vương V2", A = "DragRushSlam", P = "Martial_Claw_4", Rng = 26, Rad = 14, D = 24, H = 3, Intv = 0.08, M = 3.20, Cd = 8.5, C = 18, Brn = 3, St = 0.85, Gnd = true, Sh = 1.38, T = {"DRAG", "BURN", "STUN"} },
		C = { N = "Demolition Twister Meteors", V = "Cuồng Long Lốc Xoáy", Awk = "Cataclysmic Dragon Starshower V2", AwkVI = "Vạn Long Thiên Hỏa Vũ V2", A = "MeteorShower", P = "Core_Cast_SkySphere", Rng = 36, Rad = 21, Delay = 0.30, H = 8, Intv = 0.08, Pull = 16, M = 4.10, Cd = 12.0, C = 24, Brn = 4, Haz = "MagmaPool", HazDur = 3.4, Gnd = true, Sh = 1.42, T = {"METEOR", "PULL", "LAVA POOL"} },
		V = { N = "Dragon Form Ascension", V = "Chuyển Dạng Hoàng Long", Awk = "Sovereign Dragon Ascension V2", AwkVI = "Chân Thân Hoàng Long Tối Thượng V2", A = "TransformToggle", P = "Core_Cast_SkySphere", Rng = 28, Rad = 20, H = 1, M = 2.40, Cd = 3.5, C = 15, Ult = true, T = {"TRANSFORM", "ULTIMATE"} },
		F = { N = "Hybrid Wing Dash", V = "Long Ảnh Bộ", Awk = "Crimson Wing Blitz V2", AwkVI = "Long Ảnh Bộ V2", A = "MobilityDashHit", P = "Core_Dash_Pose", Rng = 38, Rad = 12, D = 38, M = 1.65, Cd = 6.5, C = 14, Brn = 2, T = {"DASH HIT", "BURN"} },
	},
}

local DRAGON_TIER1_SKILLS: { [string]: any } = {
	Z = { N = "Hybrid Crimson Breath", V = "Bán Long Hỏa Tức", A = "PiercingBeam", P = "Core_Cast_Beam", Rng = 40, Rad = 14, H = 5, Intv = 0.07, M = 3.20, Cd = 6.0, C = 14, Brn = 4, Kb = 18, Sh = 1.42, T = {"5 HITS", "PIERCE", "BURN"} },
	X = { N = "Hybrid Talon Rend", V = "Bán Long Đột Trảo", A = "DragRushSlam", P = "Martial_Claw_4", Rng = 30, Rad = 16, D = 28, H = 3, Intv = 0.08, M = 3.65, Cd = 8.5, C = 18, Brn = 3, St = 1.0, Gnd = true, Sh = 1.40, T = {"DRAG", "BURN", "STUN"} },
	C = { N = "Hybrid Inferno Starshower", V = "Cuồng Long Hỏa Vũ", A = "MeteorShower", P = "Core_Cast_SkySphere", Rng = 40, Rad = 23, Delay = 0.30, H = 10, Intv = 0.07, Pull = 20, M = 4.65, Cd = 12.0, C = 24, Brn = 4, Haz = "MagmaPool", HazDur = 3.8, Gnd = true, Sh = 1.44, T = {"10 HITS", "METEOR", "PULL"} },
	V = { N = "Ascend Full Sovereign", V = "Hóa Thái Cổ Long Hoàng", A = "TransformToggle", P = "Core_Cast_SkySphere", Rng = 32, Rad = 24, H = 1, M = 2.80, Cd = 3.5, C = 15, Ult = true, T = {"TRANSFORM", "ULTIMATE"} },
	F = { N = "Hybrid Wing Blitz", V = "Bán Long Ảnh Bộ", A = "MobilityDashHit", P = "Core_Dash_Pose", Rng = 42, Rad = 13, D = 42, M = 1.80, Cd = 6.5, C = 14, Brn = 2, T = {"DASH HIT", "BURN"} },
}

local DRAGON_TIER2_SKILLS: { [string]: any } = {
	Z = { N = "Sovereign Obliteration Beam", V = "Thái Cổ Long Tức", A = "PiercingBeam", P = "Core_Cast_Beam", Rng = 52, Rad = 17, H = 6, Intv = 0.07, M = 4.10, Cd = 8.0, C = 22, Brn = 5, Kb = 24, Sh = 1.48, T = {"PIERCE", "BEAM", "BURN"} },
	X = { N = "Sovereign Skyfall Talon Dive", V = "Long Hoàng Giáng Thế", A = "PoleVaultSlam", P = "Core_Cast_GroundSlam", Rng = 38, Rad = 22, D = 34, Delay = 0.24, H = 4, Intv = 0.08, M = 4.55, Cd = 11.5, C = 26, Brn = 4, St = 1.2, Gnd = true, Sh = 1.46, T = {"POLE-VAULT", "STUN", "BURN"} },
	C = { N = "Apocalyptic Eclipse Starshower", V = "Vạn Long Thiên Hỏa Vũ", A = "MeteorShower", P = "Core_Cast_SkySphere", Rng = 46, Rad = 28, Delay = 0.34, H = 10, Intv = 0.07, Pull = 24, M = 5.45, Cd = 16.0, C = 34, Brn = 5, Haz = "MagmaPool", HazDur = 4.4, Gnd = true, Sh = 1.50, Ult = true, T = {"10 HITS", "METEOR", "LAVA POOL"} },
	V = { N = "Revert Sovereign Form", V = "Thu Hồi Long Hồn", A = "TransformToggle", P = "Core_Cast_SkySphere", Rng = 24, Rad = 18, H = 1, M = 0.0, Cd = 3.5, C = 0, Ult = true, T = {"TRANSFORM"} },
	F = { N = "Sovereign Supersonic Flight", V = "Long Vũ Cửu Thiên", A = "MobilityDashHit", P = "Core_Dash_Pose", Rng = 48, Rad = 15, D = 46, M = 1.85, Cd = 7.5, C = 18, Brn = 2, T = {"3D FLIGHT", "BURN"} },
}

-- ============================================================================
-- 5. SLOT 3 MELEE WEAPON & SLOT 4 GUN SKILL BLUEPRINTS
-- ============================================================================
local WEAPON_ARCHETYPE_SKILLS: { [string]: any } = {
	Spear = {
		Element = "Sky",
		Z = { N = "Dragon Skewer Thrust", V = "Long Thương Đột Kích", A = "DragRushSlam", P = "Spear_Z_Thrust", Rng = 28, Rad = 11, D = 26, H = 3, Intv = 0.06, M = 3.10, Cd = 5.2, C = 12, St = 0.65, Gnd = true, T = {"3 HITS", "DRAG", "PIERCE"} },
		X = { N = "Heavensfall Pole-Vault", V = "Thương Vân Giáng Địa", A = "PoleVaultSlam", P = "Spear_X_PoleVault", Rng = 26, Rad = 15, D = 24, Delay = 0.22, H = 2, M = 4.00, Cd = 9.8, C = 18, St = 0.90, Ku = 18, Gnd = true, Sh = 1.38, T = {"POLE-VAULT", "STUN", "AOE"} },
		C = { N = "Tempest Trident Surge", V = "Tam Xoa Phá Lãng", A = "MultiLaneSpikes", P = "Spear_Z_Thrust", Rng = 32, Rad = 12, H = 3, M = 3.60, Cd = 9.5, C = 16, Gnd = true, T = {"SPIKES", "PIERCE"} },
		V = { N = "Sovereign Spear Starfall", V = "Vạn Thương Thiên Phạt", A = "SkybeamPillars", P = "Spear_X_PoleVault", Rng = 32, Rad = 21, H = 6, Intv = 0.07, M = 4.80, Cd = 14.0, C = 22, St = 1.0, Gnd = true, Ult = true, T = {"ULTIMATE", "POLE-VAULT", "AOE"} },
		F = { N = "Polearm Vault Lunge", V = "Phi Thương Lướt Gió", A = "MobilityDashHit", P = "Spear_Z_Thrust", Rng = 38, Rad = 10, D = 38, M = 1.60, Cd = 5.0, C = 8, T = {"DASH HIT", "PIERCE"} },
	},
	Katana = {
		Element = "Sky",
		Z = { N = "Iaido Flash Severance", V = "Nhất Đao Trảm Không", A = "BlinkDelayedSlash", P = "Katana_Z_IaiDraw", Rng = 28, Rad = 11, D = 26, Delay = 0.22, H = 2, M = 3.00, Cd = 5.0, C = 12, St = 0.60, T = {"IAI CUT", "BLINK", "DELAYED SLASH"} },
		X = { N = "Crescent Moon Wave", V = "Bán Nguyệt Kiếm Quang", A = "TravellingWave", P = "Katana_X_Crescent", Rng = 32, Rad = 12, H = 2, M = 3.90, Cd = 9.5, C = 18, Kb = 16, T = {"WAVE", "PIERCE"} },
		C = { N = "Tempest Blade Dance", V = "Liên Hoàn Bão Kiếm", A = "ZigZagMirrorKick", P = "Katana_Z_IaiDraw", Rng = 28, Rad = 12, D = 26, ChCnt = 4, H = 4, M = 3.50, Cd = 9.5, C = 16, St = 0.70, T = {"IAI CUT", "ZIG-ZAG"} },
		V = { N = "Dimension Judgment Cut", V = "Tuyệt Kiếm Phán Quyết", A = "BlinkDelayedSlash", P = "Katana_Z_IaiDraw", Rng = 32, Rad = 18, D = 30, Delay = 0.28, H = 5, M = 4.60, Cd = 14.0, C = 22, St = 1.0, Ult = true, T = {"ULTIMATE", "IAI CUT", "DELAYED SLASH"} },
		F = { N = "Zephyr Sheath Dash", V = "Kiếm Phong Lướt Gió", A = "MobilityDashHit", P = "Katana_Z_IaiDraw", Rng = 38, Rad = 10, D = 38, M = 1.55, Cd = 5.0, C = 8, T = {"IAI CUT", "DASH HIT"} },
	},
	Greatsword = {
		Element = "Void",
		Z = { N = "Charged Earthsplit Wave", V = "Hắc Nguyệt Xé Đất", A = "TravellingWave", P = "Greatsword_Z_EarthSplit", Rng = 34, Rad = 15, H = 2, M = 3.80, Cd = 5.5, C = 14, Kb = 20, Gnd = true, Sh = 1.42, T = {"WAVE", "GUARD BREAK"} },
		X = { N = "Colossus Guillotine Slam", V = "Đoạn Đầu Đại Trảm", A = "PoleVaultSlam", P = "Greatsword_X_Guillotine", Rng = 30, Rad = 18, D = 22, Delay = 0.24, H = 2, M = 4.90, Cd = 11.0, C = 22, St = 1.0, Gnd = true, Sh = 1.45, T = {"GUARD BREAK", "STUN", "AOE"} },
		C = { N = "Tectonic Cleave Rush", V = "Đại Kiếm Nghiền Nát", A = "DragRushSlam", P = "Greatsword_Z_EarthSplit", Rng = 26, Rad = 16, D = 22, H = 3, M = 4.10, Cd = 10.0, C = 18, Gnd = true, Sh = 1.40, T = {"DRAG", "GUARD BREAK"} },
		V = { N = "Sovereign Blade Cataclysm", V = "Thần Kiếm Diệt Thế", A = "SkybeamPillars", P = "Greatsword_X_Guillotine", Rng = 34, Rad = 23, H = 5, M = 5.40, Cd = 14.5, C = 24, St = 1.2, Gnd = true, Sh = 1.48, Ult = true, T = {"ULTIMATE", "GUARD BREAK", "STUN"} },
		F = { N = "Heavy Shoulder Ram", V = "Trọng Kiếm Xung Phong", A = "MobilityDashHit", P = "Greatsword_Z_EarthSplit", Rng = 34, Rad = 12, D = 34, M = 1.70, Cd = 5.2, C = 10, Kb = 16, T = {"DASH HIT", "GUARD BREAK"} },
	},
	DualBlades = {
		Element = "Lightning",
		Z = { N = "Twin Cross Blitz", V = "Song Đao Đột Kích", A = "BlinkDelayedSlash", P = "DualBlades_Z_Blitz", Rng = 28, Rad = 11.5, D = 28, Delay = 0.20, H = 4, Intv = 0.055, M = 3.20, Cd = 4.8, C = 12, St = 0.55, T = {"4 HITS", "BLINK", "DELAYED SLASH"} },
		X = { N = "Eclipse Blade Cyclone", V = "Vòng Xoáy Song Kiếm", A = "VortexPullCage", P = "DualBlades_X_Spin", Rng = 26, Rad = 15, H = 5, Intv = 0.065, Pull = 15, M = 4.20, Cd = 10.0, C = 18, St = 0.75, T = {"5 HITS", "PULL", "VORTEX"} },
		C = { N = "Lightning Cross Flurry", V = "Thập Tự Liên Trảm", A = "ZigZagMirrorKick", P = "DualBlades_Z_Blitz", Rng = 28, Rad = 13, D = 28, ChCnt = 5, H = 5, M = 3.70, Cd = 9.5, C = 16, St = 0.70, T = {"5 HITS", "ZIG-ZAG"} },
		V = { N = "Slayer of Skies", V = "Tuyệt Kiếm Phá Thiên", A = "SpreadVolley", P = "DualBlades_X_Spin", Rng = 34, Rad = 20, H = 8, Intv = 0.06, M = 5.20, Cd = 14.0, C = 22, St = 1.0, Ult = true, T = {"ULTIMATE", "8 HITS", "STUN"} },
		F = { N = "Twin Flash Stride", V = "Lôi Ảnh Song Bộ", A = "MobilityDashHit", P = "DualBlades_Z_Blitz", Rng = 42, Rad = 10, D = 42, M = 1.60, Cd = 4.8, C = 8, T = {"BLINK", "DASH HIT"} },
	},
	Scythe = {
		Element = "Void",
		Z = { N = "Reaper Soul Hook", V = "Lưỡi Hái Câu Hồn", A = "VortexPullCage", P = "Scythe_Z_Hook", Rng = 30, Rad = 15, H = 3, Intv = 0.08, Pull = 18, M = 3.30, Cd = 5.4, C = 12, Leech = 0.18, T = {"PULL", "LIFESTEAL"} },
		X = { N = "Dimensional Rift Reap", V = "Lưỡi Hái Xé Không", A = "BlinkDelayedSlash", P = "Scythe_X_Rift", Rng = 30, Rad = 14, D = 28, Delay = 0.25, H = 3, M = 4.30, Cd = 10.5, C = 18, St = 0.85, Leech = 0.14, Haz = "ChronoField", HazDur = 3.0, T = {"BLINK", "LIFESTEAL", "CHRONO FIELD"} },
		C = { N = "Astral Convergence", V = "Tinh Cầu Hội Tụ", A = "HarmonicSiphonWave", P = "Scythe_Z_Hook", Rng = 30, Rad = 16, H = 3, Pull = 16, M = 3.60, Cd = 9.5, C = 16, Leech = 0.14, T = {"SIPHON", "PULL"} },
		V = { N = "Chrono Eclipse Harvest", V = "Nguyệt Thực Thu Hồn", A = "SkyfallSphere", P = "Scythe_X_Rift", Rng = 34, Rad = 23, Delay = 0.34, H = 5, M = 4.90, Cd = 14.0, C = 22, St = 1.15, Leech = 0.20, Gnd = true, Ult = true, T = {"ULTIMATE", "LIFESTEAL", "STUN"} },
		F = { N = "Wraith Phase Glide", V = "U Ảnh Bộ", A = "MobilityDashHit", P = "Scythe_X_Rift", Rng = 40, Rad = 10.5, D = 40, M = 1.60, Cd = 5.0, C = 8, Leech = 0.08, T = {"DASH HIT", "LIFESTEAL"} },
	},
}

local WEAPON_ELEMENT_OVERRIDES = {
	sunshard_halberd = { Element = "Flame", Brn = 2 },
	nerith_abyssal_trident = { Element = "Frost", Frz = 1.2 },
	cryon_frostblade = { Element = "Frost", Frz = 1.5 },
	cyber_katana_mk2 = { Element = "Lightning", St = 0.7 },
	yamo_voidblade = { Element = "Void" },
	saber_of_aureon = { Element = "Light" },
	dawnbringer_sword = { Element = "Light" },
	Dawnbringer = { Element = "Light" },
	ignivar_magma_breaker = { Element = "Magma", Brn = 3, Haz = "MagmaPool", HazDur = 3.2 },
	sylvaris_thornblade = { Element = "Sky", Leech = 0.08 },
	noxar_abyssal_greatsword = { Element = "Void", Brn = 2 },
	noxar_greatsword = { Element = "Void", Brn = 2 },
	abyssal_greatsword = { Element = "Void", Brn = 2 },
	ArchitectsSeverance = { Element = "Void", St = 1.1 },
	cursed_dual_skyblades = { Element = "Lightning", St = 0.75 },
	stormfang_daggers = { Element = "Lightning", ChCnt = 4, ChRad = 16 },
	Stormfang = { Element = "Lightning", ChCnt = 4, ChRad = 16 },
	aion_chrono_scythe = { Element = "Void", Haz = "ChronoField", HazDur = 3.2 },
	starter_staff = { Element = "Frost", Frz = 1.1 },
	astral_staff = { Element = "Void", Haz = "ChronoField", HazDur = 2.8 },
	EternalFrost = { Element = "Frost", Frz = 1.6 },
}

local GUN_ARCHETYPE_SKILLS: { [string]: any } = {
	Railgun = {
		Element = "Frost",
		Z = { N = "Cryo Overcharge Rail", V = "Tia Xung Từ Trường Băng", A = "PiercingBeam", P = "Gun_Railgun_Brace", Rng = 95, Rad = 9.5, H = 1, M = 3.40, Cd = 6.0, C = 12, Frz = 2.2, Sh = 1.38, T = {"PIERCE", "BEAM", "FREEZE"} },
		X = { N = "Orbital EMP Subzero", V = "Đại Pháo Hàn Băng", A = "ChainLightning", P = "Gun_Railgun_Brace", Rng = 68, Rad = 16, ChCnt = 5, ChRad = 22, H = 3, M = 4.40, Cd = 11.0, C = 18, Frz = 1.8, St = 1.1, T = {"CHAIN x5", "FREEZE", "STUN"} },
		C = { N = "Cryo Containment Cell", V = "Lồng Giữ Từ Trường", A = "VortexPullCage", P = "Gun_Railgun_Brace", Rng = 54, Rad = 16, H = 4, Pull = 14, M = 3.80, Cd = 10.0, C = 16, Frz = 1.8, Haz = "FrostSheet", HazDur = 3.4, T = {"PULL", "FROST SHEET"} },
		V = { N = "Zero-Kelvin Orbital Strike", V = "Quỹ Đạo Độ Không Tuyệt Đối", A = "SkybeamPillars", P = "Gun_Railgun_Brace", Rng = 70, Rad = 24, H = 6, M = 5.10, Cd = 15.0, C = 24, Frz = 2.4, Gnd = true, Ult = true, T = {"ULTIMATE", "FREEZE", "AOE"} },
		F = { N = "Magnetic Thruster Slide", V = "Phản Lực Từ Trường", A = "MobilityDashHit", P = "Gun_Railgun_Brace", Rng = 36, Rad = 9.5, D = 36, M = 1.50, Cd = 5.0, C = 8, T = {"DASH HIT"} },
	},
	VoidLyre = {
		Element = "Void",
		Z = { N = "Soul Shaker Chord", V = "Sóng Âm Rung Chuyển Linh Hồn", A = "HarmonicSiphonWave", P = "Gun_VoidLyre_Strum", Rng = 56, Rad = 15, H = 3, Intv = 0.08, M = 3.80, Cd = 6.0, C = 14, St = 1.4, Leech = 0.20, T = {"SIPHON", "LIFESTEAL", "STUN"} },
		X = { N = "Void Requiem Cage", V = "Khúc Nhạc Hư Không", A = "VortexPullCage", P = "Gun_VoidLyre_Strum", Rng = 48, Rad = 18, H = 4, Intv = 0.09, Pull = 18, M = 4.90, Cd = 11.5, C = 20, St = 1.4, Leech = 0.18, Haz = "ChronoField", HazDur = 3.4, T = {"PULL", "LIFESTEAL", "STUN"} },
		C = { N = "Dissonant Riff Chain", V = "Cung Đàn Cộng Hưởng", A = "ChainLightning", P = "Gun_VoidLyre_Strum", Rng = 56, Rad = 14, ChCnt = 5, ChRad = 22, H = 3, M = 4.10, Cd = 10.0, C = 18, St = 1.1, Leech = 0.15, T = {"CHAIN x5", "LIFESTEAL"} },
		V = { N = "Abyssal Symphony Finale", V = "Bản Giao Hưởng Hư Không", A = "SkyfallSphere", P = "Gun_VoidLyre_Strum", Rng = 56, Rad = 25, Delay = 0.34, H = 5, M = 5.40, Cd = 15.0, C = 24, St = 1.6, Leech = 0.22, Gnd = true, Ult = true, T = {"ULTIMATE", "LIFESTEAL", "STUN"} },
		F = { N = "Echo Tempo Glide", V = "Bước Nhạc Dư Âm", A = "MobilityDashHit", P = "Gun_VoidLyre_Strum", Rng = 38, Rad = 10, D = 38, M = 1.55, Cd = 5.0, C = 8, Leech = 0.10, T = {"DASH HIT", "LIFESTEAL"} },
	},
	Bow = {
		Element = "Sky",
		Z = { N = "Wind-Piercer Snipe", V = "Mũi Tên Xuyên Phong", A = "PiercingBeam", P = "Gun_Bow_Draw", Rng = 78, Rad = 9.5, H = 2, M = 3.10, Cd = 5.5, C = 10, Kb = 18, T = {"PIERCE", "KNOCKBACK"} },
		X = { N = "Starlight Arrow Rain", V = "Mưa Tên Tinh Linh", A = "MeteorShower", P = "Gun_Bow_Draw", Rng = 58, Rad = 18, Delay = 0.26, H = 6, Intv = 0.07, M = 3.95, Cd = 9.5, C = 15, Kb = 14, Gnd = true, T = {"6 HITS", "VOLLEY", "AOE"} },
		C = { N = "Cyclone Snare Shot", V = "Cung Phong Trói Buộc", A = "VortexPullCage", P = "Gun_Bow_Draw", Rng = 54, Rad = 15, H = 4, Pull = 15, M = 3.60, Cd = 9.5, C = 16, T = {"PULL", "VORTEX"} },
		V = { N = "Emerald Tempest Barrage", V = "Đại Vũ Tiễn Sylvaris", A = "MeteorShower", P = "Gun_Bow_Draw", Rng = 64, Rad = 24, H = 8, M = 4.80, Cd = 14.0, C = 22, Gnd = true, Ult = true, T = {"ULTIMATE", "8 HITS", "AOE"} },
		F = { N = "Gale Backflip Vault", V = "Phong Cung Bật Nhảy", A = "MobilityDashHit", P = "Gun_Bow_Draw", Rng = 40, Rad = 9.5, D = 40, M = 1.50, Cd = 4.8, C = 8, T = {"DASH HIT"} },
	},
	Cannon = {
		Element = "Flame",
		Z = { N = "Siege Mortar Shell", V = "Pháo Kích Dung Nham", A = "SkyfallSphere", P = "Gun_Railgun_Brace", Rng = 62, Rad = 15, Delay = 0.28, H = 2, M = 3.60, Cd = 5.8, C = 12, Brn = 3, Kb = 18, Gnd = true, Sh = 1.40, T = {"AOE", "BURN", "GUARD BREAK"} },
		X = { N = "Cluster Napalm Salvo", V = "Liên Hoàn Hỏa Pháo", A = "SpreadVolley", P = "Gun_Railgun_Brace", Rng = 54, Rad = 17, H = 5, Intv = 0.08, M = 4.50, Cd = 10.5, C = 18, Brn = 4, Haz = "MagmaPool", HazDur = 3.6, Gnd = true, Sh = 1.42, T = {"5 HITS", "LAVA POOL", "BURN"} },
		C = { N = "Gravity Singularity Shell", V = "Hố Đen Kỳ Điểm", A = "VortexPullCage", P = "Gun_Railgun_Brace", Rng = 54, Rad = 18, H = 4, Pull = 18, M = 4.20, Cd = 10.5, C = 18, T = {"PULL", "AOE"} },
		V = { N = "Hellfire Bombardment", V = "Mưa Pháo Hủy Diệt", A = "MeteorShower", P = "Gun_Railgun_Brace", Rng = 66, Rad = 25, H = 7, M = 5.40, Cd = 15.0, C = 24, Brn = 5, Haz = "MagmaPool", HazDur = 4.2, Gnd = true, Sh = 1.45, Ult = true, T = {"ULTIMATE", "METEOR", "LAVA POOL"} },
		F = { N = "Cannon Recoil Blast", V = "Phản Lực Đại Pháo", A = "MobilityDashHit", P = "Gun_Railgun_Brace", Rng = 36, Rad = 11, D = 36, M = 1.65, Cd = 5.0, C = 9, Kb = 15, T = {"DASH HIT", "GUARD BREAK"} },
	},
	PistolRifle = {
		Element = "Sky",
		Z = { N = "Ricochet Fan Volley", V = "Loạt Đạn Xuyên Giáp", A = "SpreadVolley", P = "Gun_Pistol_Fire", Rng = 64, Rad = 12, H = 4, Intv = 0.06, M = 2.60, Cd = 4.5, C = 8, T = {"4 HITS", "VOLLEY"} },
		X = { N = "High-Caliber Stun Piercer", V = "Đạn Xung Phá Giáp", A = "PiercingBeam", P = "Gun_Pistol_Fire", Rng = 78, Rad = 9.5, H = 2, M = 3.40, Cd = 7.5, C = 12, St = 0.85, Kb = 16, T = {"PIERCE", "STUN"} },
		C = { N = "Tactical Phase Vault", V = "Xạ Kích Thoát Thân", A = "RiftPhaseEscape", P = "Gun_Pistol_Fire", Rng = 48, Rad = 12, D = 18, H = 3, M = 3.30, Cd = 9.5, C = 16, St = 0.60, T = {"PHASE", "IFRAME"} },
		V = { N = "Aether Overcharge Barrage", V = "Đại Pháo Ánh Sáng", A = "SkybeamPillars", P = "Gun_Pistol_Fire", Rng = 64, Rad = 20, H = 6, M = 4.30, Cd = 14.0, C = 22, Gnd = true, Ult = true, T = {"ULTIMATE", "6 HITS"} },
		F = { N = "Recoil Jet Dash", V = "Phản Lực Đẩy Lướt", A = "MobilityDashHit", P = "Gun_Pistol_Fire", Rng = 36, Rad = 9.5, D = 36, M = 1.45, Cd = 5.0, C = 8, T = {"DASH HIT"} },
	},
}

local GUN_ELEMENT_OVERRIDES = {
	aion_chrono_pistols = { Element = "Void", Haz = "ChronoField", HazDur = 2.8 },
	bizarre_rifle_cyber = { Element = "Frost", Frz = 1.4 },
	veyr_singularity_cannon = { Element = "Void", Pull = 20 },
	solar_kabucha = { Element = "Flame", Brn = 2 },
}

-- ============================================================================
-- 6. PUBLIC QUERY API: GetM1Blueprint & GetSkillBlueprint
-- ============================================================================
local function copyTags(src)
	local out = {}
	if type(src) == "table" then
		for i = 1, #src do
			out[i] = tostring(src[i])
		end
	end
	return out
end

local function parseCtx(ctxOrAwk, tierOpt)
	if type(ctxOrAwk) == "table" then
		return ctxOrAwk.Awakened == true,
			tonumber(ctxOrAwk.DragonFormTier) or 0,
			tostring(ctxOrAwk.FruitTransform or ""),
			tonumber(ctxOrAwk.ChargeRatio)
	end
	if type(ctxOrAwk) == "boolean" then
		return ctxOrAwk, tonumber(tierOpt) or 0, "", nil
	end
	if type(ctxOrAwk) == "number" then
		return false, ctxOrAwk, "", nil
	end
	return false, tonumber(tierOpt) or 0, "", nil
end

function Blueprints.GetArchetypeLabel(archetype, lang)
	local key = tostring(archetype or "")
	if string.lower(tostring(lang or "vi")) == "en" then
		return ARCHETYPE_LABELS_EN[key] or key
	end
	return ARCHETYPE_LABELS_VI[key] or ARCHETYPE_LABELS_EN[key] or key
end

function Blueprints.GetM1Blueprint(slot, activeId, comboStep, ctx)
	local sNum = math.clamp(math.floor(tonumber(slot) or 3), 1, 4)
	local step = ((math.max(1, math.floor(tonumber(comboStep) or 1)) - 1) % 4) + 1
	local _, dragonTier, fruitTransform = parseCtx(ctx, nil)

	if sNum == 1 then
		local styleId = Blueprints.ResolveStyleId(activeId)
		local meta = STYLE_META[styleId] or STYLE_META.skyborn_combat
		local isFinisher = (step == 4)
		return {
			BlueprintId = string.format("M1_Slot1_%s_%d", styleId, step),
			Slot = 1,
			ActiveId = styleId,
			ComboStep = step,
			Archetype = meta.SubArch,
			WeaponArchetype = meta.SubArch,
			PoseClip = meta.PosePrefix .. tostring(step),
			WindupSec = isFinisher and 0.09 or 0.06,
			SnapSec = isFinisher and 0.09 or 0.07,
			HitstopSec = isFinisher and 0.045 or 0.035,
			RecoverSec = isFinisher and 0.16 or 0.10,
			Reach = meta.Reach[step],
			Width = meta.Width[step],
			Mult = meta.Mults[step],
			Multiplier = meta.Mults[step],
			Hits = 1,
			HitInterval = 0,
			LungeDist = meta.Lunge[step],
			ImpactGround = isFinisher and (meta.Impact4 == true) or false,
			Element = meta.Element,
			BurnTicks = meta.Burn or 0,
			StunDur = isFinisher and (meta.Stun4 or 0) or 0,
			LifestealPct = meta.Leech or 0,
			Tags = copyTags(meta.Tags),
		}
	elseif sNum == 2 then
		local coreId = Blueprints.ResolveCoreId(activeId)
		if coreId == "" then
			coreId = "GaleCore"
		end
		local coreDef = CORE_SKILLS[coreId] or CORE_SKILLS.GaleCore
		local posePrefix = "Martial_Punch_"
		local wArch = "CoreM1"
		if coreId == "GlacierIceCore" then
			posePrefix = "Spear_M1_"
			wArch = "Spear"
		elseif coreId == "CelestialLightCore" then
			posePrefix = "Katana_M1_"
			wArch = "Katana"
		elseif coreId == "AbyssalSovereignCore" then
			posePrefix = "Martial_Claw_"
			wArch = "DragonClaw"
		end
		local tScale = (coreId == "AbyssalSovereignCore" and dragonTier >= 2 and 1.35)
			or (coreId == "AbyssalSovereignCore" and dragonTier == 1 and 1.15)
			or (fruitTransform == "SolarTitan" and 1.35)
			or 1.0
		local isFinisher = (step == 4)
		local mult = (isFinisher and 1.48 or (0.98 + step * 0.08)) * (dragonTier >= 1 and 1.15 or 1.0)
		return {
			BlueprintId = string.format("M1_Slot2_%s_%d", coreId, step),
			Slot = 2,
			ActiveId = coreId,
			ComboStep = step,
			Archetype = "ElementalStrike",
			WeaponArchetype = wArch,
			PoseClip = posePrefix .. tostring(step),
			WindupSec = 0.07,
			SnapSec = 0.08,
			HitstopSec = isFinisher and 0.044 or 0.035,
			RecoverSec = isFinisher and 0.15 or 0.10,
			Reach = (isFinisher and 20.0 or 16.5) * tScale,
			Width = (isFinisher and 11.5 or 9.2) * tScale,
			Mult = mult,
			Multiplier = mult,
			Hits = (coreId == "GlacierIceCore" and step == 2) and 3 or 1,
			HitInterval = (coreId == "GlacierIceCore" and step == 2) and 0.055 or 0,
			LungeDist = isFinisher and 5.5 or 4.0,
			ImpactGround = isFinisher and (coreId == "SolarTitanCore" or dragonTier >= 1),
			Element = coreDef.Element,
			Tags = { string.upper(coreDef.Element) },
		}
	elseif sNum == 3 then
		local rawWep = tostring(activeId or "starter_sword")
		if rawWep == "" then
			rawWep = "starter_sword"
		end
		local wArch = Blueprints.ResolveWeaponArchetype(rawWep)
		local seq = WEAPON_M1_ARCHETYPES[wArch] or WEAPON_M1_ARCHETYPES.Katana
		local beat = seq[step] or seq[1]
		local ov = WEAPON_ELEMENT_OVERRIDES[rawWep]
		local baseElem = (ov and ov.Element) or (WEAPON_ARCHETYPE_SKILLS[wArch] and WEAPON_ARCHETYPE_SKILLS[wArch].Element) or "Sky"
		return {
			BlueprintId = string.format("M1_Slot3_%s_%d", wArch, step),
			Slot = 3,
			ActiveId = rawWep,
			ComboStep = step,
			Archetype = beat.A or beat.Arch or beat.Archetype,
			WeaponArchetype = wArch,
			PoseClip = beat.P or beat.Pose or beat.PoseClip,
			WindupSec = beat.Wu or beat.Windup,
			SnapSec = beat.Snap,
			HitstopSec = beat.Hs or beat.Hitstop,
			RecoverSec = beat.Rc or beat.Recover,
			Reach = beat.Reach,
			Width = beat.Width,
			Mult = beat.M or beat.Mult,
			Multiplier = beat.M or beat.Mult,
			Hits = beat.H or beat.Hits,
			HitInterval = beat.Intv or beat.Interval or 0,
			LungeDist = beat.Lunge,
			ImpactGround = beat.Impact == true,
			Element = baseElem,
			LifestealPct = beat.Leech or 0,
			Tags = copyTags(beat.T or beat.Tags),
		}
	else
		local rawGun = tostring(activeId or "aether_flintlock")
		if rawGun == "" then
			rawGun = "aether_flintlock"
		end
		local gArch = Blueprints.ResolveGunArchetype(rawGun)
		local spec = GUN_M1_ARCHETYPES[gArch] or GUN_M1_ARCHETYPES.PistolRifle
		local ov = GUN_ELEMENT_OVERRIDES[rawGun]
		local gm = spec.M or spec.Mult
		return {
			BlueprintId = string.format("M1_Slot4_%s_%d", gArch, step),
			Slot = 4,
			ActiveId = rawGun,
			ComboStep = step,
			Archetype = spec.A or spec.Arch or spec.Archetype,
			WeaponArchetype = gArch,
			PoseClip = spec.P or spec.Pose or spec.PoseClip,
			WindupSec = spec.Wu or spec.Windup,
			SnapSec = spec.Snap,
			HitstopSec = spec.Hs or spec.Hitstop,
			RecoverSec = spec.Rc or spec.Recover,
			Reach = spec.Reach,
			Width = spec.Width,
			Mult = gm,
			Multiplier = gm,
			Hits = (rawGun == "aion_chrono_pistols") and 2 or 1,
			HitInterval = (rawGun == "aion_chrono_pistols") and 0.08 or 0,
			LungeDist = 0,
			ImpactGround = spec.Impact == true,
			Element = (ov and ov.Element) or spec.Element,
			LifestealPct = spec.Leech or 0,
			Tags = copyTags(spec.T or spec.Tags),
		}
	end
end

function Blueprints.GetSkillBlueprint(slot, activeId, moveKey, ctx, dragonTierOpt)
	local sNum = math.clamp(math.floor(tonumber(slot) or 2), 1, 4)
	local key = string.upper(tostring(moveKey or "Z"))
	if key ~= "Z" and key ~= "X" and key ~= "C" and key ~= "V" and key ~= "F" then
		if key == "1" then
			key = "Z"
		elseif key == "2" then
			key = "X"
		elseif key == "3" then
			key = "C"
		elseif key == "R" then
			key = "V"
		else
			key = "Z"
		end
	end

	local awakened, dragonTier, fruitTransform, chargeRatio = parseCtx(ctx, dragonTierOpt)
	if dragonTier < 2 and (fruitTransform == "AbyssalSovereign" or fruitTransform == "DragonFull" or fruitTransform == "AbyssalDragonFull") then
		dragonTier = 2
	elseif dragonTier < 1 and (fruitTransform == "DragonHybrid" or fruitTransform == "AbyssalHybrid") then
		dragonTier = 1
	end

	local resolvedId = tostring(activeId or "")
	local wArch = ""
	local elem = "Sky"
	local src = nil

	if sNum == 1 then
		resolvedId = Blueprints.ResolveStyleId(resolvedId)
		local st = STYLE_SKILLS[resolvedId] or STYLE_SKILLS.skyborn_combat
		wArch = st.WeaponArch or st.WeaponArchetype or "SkyKata"
		elem = st.Element
		src = st[key] or st.Z
	elseif sNum == 2 then
		resolvedId = Blueprints.ResolveCoreId(resolvedId)
		if resolvedId == "" then
			resolvedId = "GaleCore"
		end
		local core = CORE_SKILLS[resolvedId] or CORE_SKILLS.GaleCore
		wArch = resolvedId
		elem = core.Element
		src = core[key] or core.Z
		if resolvedId == "AbyssalSovereignCore" then
			if dragonTier >= 2 and DRAGON_TIER2_SKILLS[key] then
				src = DRAGON_TIER2_SKILLS[key]
			elseif dragonTier == 1 and DRAGON_TIER1_SKILLS[key] then
				src = DRAGON_TIER1_SKILLS[key]
			end
		end
	elseif sNum == 3 then
		if resolvedId == "" then
			resolvedId = "starter_sword"
		end
		wArch = Blueprints.ResolveWeaponArchetype(resolvedId)
		local archTbl = WEAPON_ARCHETYPE_SKILLS[wArch] or WEAPON_ARCHETYPE_SKILLS.Katana
		elem = archTbl.Element
		src = archTbl[key] or archTbl.Z
	else
		if resolvedId == "" then
			resolvedId = "aether_flintlock"
		end
		wArch = Blueprints.ResolveGunArchetype(resolvedId)
		local archTbl = GUN_ARCHETYPE_SKILLS[wArch] or GUN_ARCHETYPE_SKILLS.PistolRifle
		elem = archTbl.Element
		src = archTbl[key] or archTbl.Z
	end

	local tags = copyTags(src.T or src.Tags)
	local nameEN = src.N or src.Name or (resolvedId .. " [" .. key .. "]")
	local nameVI = src.V or src.NameVI or nameEN
	local range = tonumber(src.Rng or src.Range) or 28
	local radius = tonumber(src.Rad or src.Radius) or 13
	local hits = tonumber(src.H or src.Hits) or 1
	local mult = tonumber(src.M or src.Mult) or 2.8
	local chainCount = tonumber(src.ChCnt or src.ChainCount) or 0
	local chainRadius = tonumber(src.ChRad or src.ChainRadius) or 0
	local freezeDur = tonumber(src.Frz or src.FreezeDur) or 0
	local shatterMult = tonumber(src.Sh or src.Shatter or src.ShatterBonusMult) or 1.0
	local stunDur = tonumber(src.St or src.Stun or src.StunDur) or 0
	local burnTicks = tonumber(src.Brn or src.BurnTicks) or 0
	local pullStrength = tonumber(src.Pull or src.PullStrength) or 0
	local lifestealPct = tonumber(src.Leech or src.LifestealPct) or 0
	local hazardKind = src.Haz or src.HazardKind
	local hazardDuration = tonumber(src.HazDur or src.HazardDuration) or 0

	-- Per-item elemental & passive overrides for Slot 3 & Slot 4
	if sNum == 3 then
		local ov = WEAPON_ELEMENT_OVERRIDES[resolvedId]
		if ov then
			elem = ov.Element or elem
			local ovFrz = ov.Frz or ov.FreezeDur
			local ovBrn = ov.Brn or ov.BurnTicks
			local ovStun = ov.Stun or ov.StunDur
			local ovLeech = ov.Leech or ov.LifestealPct
			local ovChCnt = ov.ChCnt or ov.ChainCount
			local ovHaz = ov.Haz or ov.HazardKind
			if ovFrz and freezeDur <= 0 then
				freezeDur = ovFrz
			end
			if ovBrn and burnTicks <= 0 then
				burnTicks = ovBrn
			end
			if ovStun and stunDur < ovStun then
				stunDur = ovStun
			end
			if ovLeech and lifestealPct < ovLeech then
				lifestealPct = ovLeech
			end
			if ovChCnt and chainCount < ovChCnt and key == "Z" then
				chainCount = ovChCnt
				chainRadius = ov.ChRad or ov.ChainRadius or 16
			end
			if ovHaz and not hazardKind and key == "X" then
				hazardKind = ovHaz
				hazardDuration = ov.HazDur or ov.HazardDuration or 3.2
			end
		end
		if wArch == "Greatsword" and key == "Z" and chargeRatio ~= nil then
			local cr = math.clamp(chargeRatio, 0, 1)
			range = 22 + (42 - 22) * cr
			radius = 14 + (24 - 14) * cr
			mult = 1.35 + (2.35 - 1.35) * cr
		end
	elseif sNum == 4 then
		local ov = GUN_ELEMENT_OVERRIDES[resolvedId]
		if ov then
			elem = ov.Element or elem
			local ovFrz = ov.Frz or ov.FreezeDur
			local ovBrn = ov.Brn or ov.BurnTicks
			local ovPull = ov.Pull or ov.PullStrength
			local ovHaz = ov.Haz or ov.HazardKind
			if ovFrz and freezeDur <= 0 then
				freezeDur = ovFrz
			end
			if ovBrn and burnTicks <= 0 then
				burnTicks = ovBrn
			end
			if ovPull and pullStrength < ovPull and key == "Z" then
				pullStrength = ovPull
			end
			if ovHaz and not hazardKind and key == "X" then
				hazardKind = ovHaz
				hazardDuration = ov.HazDur or ov.HazardDuration or 2.8
			end
		end
	elseif sNum == 2 and awakened then
		nameEN = (src.Awk or src.AwakenedName) or (nameEN .. " V2")
		nameVI = (src.AwkVI or src.AwakenedNameVI) or (nameVI .. " V2")
		mult = mult * 1.34
		range = math.min(60, range * 1.16)
		radius = math.min(42, radius * 1.36)
		hits = math.max(hits, (key == "V" and hits + 2) or (hits + 1))
		if (src.A or src.Arch or src.Archetype) == "ChainLightning" then
			chainCount = math.max(chainCount, 7)
			chainRadius = math.max(chainRadius, 24)
			for i = 1, #tags do
				if tags[i] == "CHAIN x5" then
					tags[i] = "CHAIN x7"
				end
			end
		end
		if freezeDur > 0 then
			freezeDur = freezeDur + 0.4
		end
		if shatterMult > 1.0 then
			shatterMult = math.max(shatterMult, 1.45)
		end
		if burnTicks > 0 then
			burnTicks = burnTicks + 1
		end
		if pullStrength > 0 then
			pullStrength = pullStrength + 4
		end
		if hazardDuration > 0 then
			hazardDuration = hazardDuration + 0.6
		end
	end

	-- Strict Rule 2 enforcement on [F]: never emit "3D FLIGHT" unless IsTrueFlightCore is true in Slot 2!
	local isTrueFlight = (sNum == 2 and key == "F" and Blueprints.IsTrueFlightCore(resolvedId, dragonTier, fruitTransform))
	if not isTrueFlight then
		local cleaned = {}
		for i = 1, #tags do
			if tags[i] ~= "3D FLIGHT" and tags[i] ~= "FLIGHT" then
				table.insert(cleaned, tags[i])
			end
		end
		tags = cleaned
	end

	local isUlt = ((src.Ult or src.IsUltimate) == true)
	return {
		BlueprintId = string.format("Skill_S%d_%s_%s_%s_T%d", sNum, resolvedId, key, awakened and "V2" or "V1", dragonTier),
		Name = nameEN,
		NameVI = nameVI,
		MoveName = nameEN .. " - " .. nameVI,
		Slot = sNum,
		ActiveId = resolvedId,
		ItemId = resolvedId,
		MoveKey = key,
		Archetype = (src.A or src.Arch or src.Archetype),
		WeaponArchetype = wArch,
		PoseClip = (src.P or src.Pose or src.PoseClip),
		WindupSec = tonumber(src.WindupSec) or (isUlt and 0.16 or 0.10),
		SnapSec = tonumber(src.SnapSec) or (isUlt and 0.14 or 0.09),
		HitstopSec = tonumber(src.HitstopSec) or (isUlt and 0.050 or 0.040),
		RecoverSec = tonumber(src.RecoverSec) or (isUlt and 0.24 or 0.16),
		ImpactDelaySec = tonumber((src.Delay or src.ImpactDelaySec)) or 0,
		Hits = hits,
		HitInterval = tonumber((src.Intv or src.HitInterval)) or (hits > 1 and 0.075 or 0),
		Range = range,
		Radius = radius,
		DashDist = tonumber((src.D or src.Dash or src.DashDist)) or 0,
		PullStrength = pullStrength,
		Knockback = tonumber((src.Kb or src.Knockback)) or 0,
		Knockup = tonumber((src.Ku or src.Knockup)) or 0,
		FreezeDur = freezeDur,
		ShatterBonusMult = shatterMult,
		StunDur = stunDur,
		BurnTicks = burnTicks,
		HazardKind = hazardKind,
		HazardDuration = hazardDuration,
		ChainCount = chainCount,
		ChainRadius = chainRadius,
		LifestealPct = lifestealPct,
		ImpactGround = ((src.Gnd or src.ImpactGround) == true),
		IsUltimate = isUlt,
		IsTrueFlight = isTrueFlight,
		Awakened = awakened,
		TransformTier = dragonTier,
		ChargeRatio = chargeRatio,
		Cooldown = tonumber((src.Cd or src.Cooldown)) or 6.0,
		Cost = tonumber(src.C or src.Cost) or 12,
		Mult = mult,
		Multiplier = mult,
		Element = elem,
		Tags = tags,
	}
end

function Blueprints.GetItemSkillBlueprints(slot, activeId, ctx)
	local sNum = math.clamp(math.floor(tonumber(slot) or 2), 1, 4)
	local keys = (sNum == 2 and { "Z", "X", "C", "V", "F" })
		or (sNum == 1 and { "Z", "X", "C" })
		or { "Z", "X" }
	local list = {}
	for i = 1, #keys do
		list[i] = Blueprints.GetSkillBlueprint(sNum, activeId, keys[i], ctx)
	end
	return list
end

return Blueprints
