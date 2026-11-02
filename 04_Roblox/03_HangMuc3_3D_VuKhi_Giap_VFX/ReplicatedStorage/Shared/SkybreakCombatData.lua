-- SkybreakCombatData.lua
-- Shared authoritative definitions for SKYBREAK Wave 2 Combat, 5 Martial Arts Styles,
-- Mastery & 12-Fruit Awakened V2 Movesets, Mirage Hourly Stock, 4-Chair Cafe Fruit Trading,
-- 5-Stage Busoshoku Haki + 8 Aura Skins, 6 Race V4 Passives, Bounty/Honor (0..30M),
-- 34 Glowing Overhead Titles, Star Ascension, and Giftcodes.

local CombatData = {}

-- ============================================================================
-- 1. FIVE MARTIAL ARTS STYLES (SLOT 1) - M1 KATAS & [Z][X][C] TECHNIQUES (#31-#33)
-- ============================================================================
CombatData.StyleOrder = {
	"skyborn_combat",
	"jade_dragon",
	"thunder_talon",
	"solar_ashura",
	"celestial_godhuman",
}

CombatData.StyleAliases = {
	skyborn_combat = "skyborn_combat",
	skyborncombat = "skyborn_combat",
	SkybornCombat = "skyborn_combat",
	skystep = "skyborn_combat",
	SkyStep = "skyborn_combat",

	jade_dragon = "jade_dragon",
	jadedragon = "jade_dragon",
	JadeDragon = "jade_dragon",
	glacialfist = "jade_dragon",
	GlacialFist = "jade_dragon",
	glacial_karate = "jade_dragon",
	GlacialKarate = "jade_dragon",

	thunder_talon = "thunder_talon",
	thundertalon = "thunder_talon",
	ThunderTalon = "thunder_talon",
	electricclaw = "thunder_talon",
	ElectricClaw = "thunder_talon",
	electric_claw = "thunder_talon",

	solar_ashura = "solar_ashura",
	solarashura = "solar_ashura",
	SolarAshura = "solar_ashura",
	abyssaltalon = "solar_ashura",
	AbyssalTalon = "solar_ashura",
	dragon_talon = "solar_ashura",
	DragonTalon = "solar_ashura",

	celestial_godhuman = "celestial_godhuman",
	celestialgodhuman = "celestial_godhuman",
	CelestialGodhuman = "celestial_godhuman",
	godhuman = "celestial_godhuman",
	GodhumanSkyborn = "celestial_godhuman",
}

CombatData.MartialStyles = {
	skyborn_combat = {
		Id = "skyborn_combat",
		Name = "Võ Thuật Skyborn",
		DisplayName = "Võ Thuật Skyborn - Skyborn Combat",
		MasterNPC = "MasterZephyr",
		MasterName = "Võ Sư Zephyr - Skyborn Dojo",
		IslandId = "SkyHub",
		MasterOffset = Vector3.new(-36, 0, -28),
		PriceGold = 0,
		PriceShards = 0,
		Element = "Sky",
		Color = Color3.fromRGB(120, 220, 255),
		Desc = "Quyền pháp chưởng phong linh hoạt của chiến binh bầu trời với chuỗi 4 đòn M1 Kata cân bằng.",
		Kata = {
			{ Step = 1, Name = "Wind Palm Jab", Mult = 1.00, Reach = 14.0, Width = 8.5, Cadence = 0.24, Break = 5, Dash = 3.5 },
			{ Step = 2, Name = "Aero Cross Strike", Mult = 1.08, Reach = 14.5, Width = 9.0, Cadence = 0.24, Break = 6, Dash = 4.0 },
			{ Step = 3, Name = "Cyclone Backhand", Mult = 1.18, Reach = 15.2, Width = 9.5, Cadence = 0.26, Break = 7, Dash = 4.5 },
			{ Step = 4, Name = "Skyborn Tempest Finisher", Mult = 1.50, Reach = 17.0, Width = 11.5, Cadence = 0.36, Break = 14, Knockback = 24, AoE = true },
		},
		Moves = {
			Z = {
				Key = "Z",
				Name = "Gale Palm Thrust",
				DisplayName = "Gale Palm Thrust - Kình Phong Chưởng",
				Mastery = 1,
				Cooldown = 4.5,
				Cost = 8,
				Range = 22,
				Radius = 11,
				Multiplier = 2.25,
				Hits = 1,
				Break = 22,
				Dash = 16,
				Element = "Sky",
			},
			X = {
				Key = "X",
				Name = "Rising Sky Kick",
				DisplayName = "Rising Sky Kick - Thăng Thiên Cước",
				Mastery = 50,
				Cooldown = 7.0,
				Cost = 12,
				Range = 20,
				Radius = 13,
				Multiplier = 2.75,
				Hits = 2,
				Break = 28,
				Knockup = 22,
				Element = "Sky",
			},
			C = {
				Key = "C",
				Name = "Aether Flurry",
				DisplayName = "Aether Flurry - Liên Hoàn Bách Chưởng",
				Mastery = 100,
				Cooldown = 9.5,
				Cost = 16,
				Range = 24,
				Radius = 15,
				Multiplier = 3.45,
				Hits = 4,
				Break = 35,
				Dash = 12,
				Element = "Sky",
			},
		},
	},

	jade_dragon = {
		Id = "jade_dragon",
		Name = "Long Quyền Ngọc Bích",
		DisplayName = "Long Quyền Ngọc Bích - Jade Dragon Kung Fu",
		MasterNPC = "MasterShen",
		MasterName = "Tông Sư Shen - Jade Dragon",
		IslandId = "SkyHub",
		SecondaryIslandId = "SunshardIsle",
		MasterOffset = Vector3.new(-46, 0, -24),
		PriceGold = 450000,
		PriceShards = 350,
		Element = "Jade",
		Color = Color3.fromRGB(64, 242, 168),
		Desc = "Tuyệt học Long Trảo xoáy ngọc bích chuyên phá giáp, cuốn hút mục tiêu và phóng long khí.",
		Kata = {
			{ Step = 1, Name = "Emerald Fang Strike", Mult = 1.08, Reach = 14.8, Width = 9.0, Cadence = 0.23, Break = 6, ArmorShred = 0.06, Dash = 4.0 },
			{ Step = 2, Name = "Coiling Scale Claw", Mult = 1.16, Reach = 15.2, Width = 9.5, Cadence = 0.23, Break = 7, ArmorShred = 0.06, Dash = 4.5 },
			{ Step = 3, Name = "Spiral Jade Whip", Mult = 1.28, Reach = 16.0, Width = 10.2, Cadence = 0.25, Break = 9, Pull = true },
			{ Step = 4, Name = "Imperial Dragon Snap", Mult = 1.65, Reach = 18.0, Width = 12.5, Cadence = 0.35, Break = 17, Knockback = 26, AoE = true },
		},
		Moves = {
			Z = {
				Key = "Z",
				Name = "Jade Claw Rush",
				DisplayName = "Jade Claw Rush - Ngọc Long Đột Trảo",
				Mastery = 1,
				Cooldown = 4.8,
				Cost = 10,
				Range = 26,
				Radius = 12,
				Multiplier = 2.55,
				Hits = 3,
				Break = 26,
				Dash = 22,
				Element = "Jade",
			},
			X = {
				Key = "X",
				Name = "Coiling Dragon Sweep",
				DisplayName = "Coiling Dragon Sweep - Cuộn Long Quét Địa",
				Mastery = 50,
				Cooldown = 7.8,
				Cost = 14,
				Range = 24,
				Radius = 16,
				Multiplier = 3.10,
				Hits = 2,
				Break = 32,
				Pull = true,
				Element = "Jade",
			},
			C = {
				Key = "C",
				Name = "Emerald Dragon Roar",
				DisplayName = "Emerald Dragon Roar - Ngọc Long Cửu Thiên Hống",
				Mastery = 100,
				Cooldown = 10.8,
				Cost = 18,
				Range = 34,
				Radius = 16,
				Multiplier = 3.95,
				Hits = 3,
				Break = 42,
				Piercing = true,
				Element = "Jade",
			},
		},
	},

	thunder_talon = {
		Id = "thunder_talon",
		Name = "Lôi Trảo Cước",
		DisplayName = "Lôi Trảo Cước - Thunder Talon",
		MasterNPC = "MasterRaiden",
		MasterName = "Lôi Sư Raiden - Thunder Talon",
		IslandId = "CyberportCafe",
		MasterOffset = Vector3.new(-28, 0, 22),
		PriceGold = 1250000,
		PriceShards = 1200,
		Element = "Lightning",
		Color = Color3.fromRGB(95, 195, 255),
		Desc = "Cước pháp sấm sét tốc độ ánh sáng với M1 Kata siêu tốc và chuỗi đòn giáng lôi tê liệt.",
		Kata = {
			{ Step = 1, Name = "Flash Low Kick", Mult = 1.10, Reach = 15.0, Width = 9.0, Cadence = 0.19, Break = 6, Dash = 5.5 },
			{ Step = 2, Name = "Arcing Roundhouse", Mult = 1.20, Reach = 15.6, Width = 9.6, Cadence = 0.19, Break = 7, Dash = 5.5 },
			{ Step = 3, Name = "Twin Volt Talon", Mult = 1.32, Reach = 16.4, Width = 10.2, Cadence = 0.21, Break = 9, StunDur = 0.35 },
			{ Step = 4, Name = "Thunderclap Heel Drop", Mult = 1.75, Reach = 18.5, Width = 13.0, Cadence = 0.31, Break = 19, StunDur = 0.75, AoE = true },
		},
		Moves = {
			Z = {
				Key = "Z",
				Name = "Volt Snap Kick",
				DisplayName = "Volt Snap Kick - Điện Thiểm Cước",
				Mastery = 1,
				Cooldown = 4.5,
				Cost = 10,
				Range = 28,
				Radius = 12,
				Multiplier = 2.75,
				Hits = 2,
				Break = 28,
				Dash = 26,
				StunDur = 0.65,
				Element = "Lightning",
			},
			X = {
				Key = "X",
				Name = "Lightning Drop Heel",
				DisplayName = "Lightning Drop Heel - Thiên Lôi Giáng Cước",
				Mastery = 50,
				Cooldown = 7.5,
				Cost = 15,
				Range = 26,
				Radius = 16,
				Multiplier = 3.40,
				Hits = 2,
				Break = 35,
				StunDur = 1.0,
				Element = "Lightning",
			},
			C = {
				Key = "C",
				Name = "Storm Talon Barrage",
				DisplayName = "Storm Talon Barrage - Bão Lôi Vạn Trảo",
				Mastery = 100,
				Cooldown = 10.5,
				Cost = 20,
				Range = 30,
				Radius = 18,
				Multiplier = 4.30,
				Hits = 6,
				Break = 46,
				Dash = 22,
				StunDur = 1.2,
				Element = "Lightning",
			},
		},
	},

	solar_ashura = {
		Id = "solar_ashura",
		Name = "Thái Dương Tu La Quyền",
		DisplayName = "Thái Dương Tu La Quyền - Solar Ashura Fist",
		MasterNPC = "MasterIgnis",
		MasterName = "Tu La Võ Đế Ignis - Solar Ashura",
		IslandId = "CyberportCafe",
		MasterOffset = Vector3.new(28, 0, 22),
		PriceGold = 2200000,
		PriceShards = 2200,
		Element = "Flame",
		Color = Color3.fromRGB(255, 128, 42),
		Desc = "Trọng quyền rực lửa mặt trời mang sức phá vỡ Break Gauge cực lớn và thiêu đốt liên tục.",
		Kata = {
			{ Step = 1, Name = "Cinder Straight", Mult = 1.18, Reach = 15.0, Width = 9.8, Cadence = 0.25, Break = 8, BurnPct = 0.14 },
			{ Step = 2, Name = "Molten Hook", Mult = 1.30, Reach = 15.5, Width = 10.4, Cadence = 0.25, Break = 10, BurnPct = 0.16 },
			{ Step = 3, Name = "Ashura Gut Crusher", Mult = 1.44, Reach = 16.2, Width = 11.0, Cadence = 0.27, Break = 13, BurnPct = 0.18 },
			{ Step = 4, Name = "Solar Supernova Slam", Mult = 1.92, Reach = 19.2, Width = 14.0, Cadence = 0.37, Break = 25, BurnPct = 0.26, Knockback = 30, AoE = true },
		},
		Moves = {
			Z = {
				Key = "Z",
				Name = "Ignited Knuckle",
				DisplayName = "Ignited Knuckle - Viêm Dương Thiết Quyền",
				Mastery = 1,
				Cooldown = 5.0,
				Cost = 11,
				Range = 24,
				Radius = 13,
				Multiplier = 3.00,
				Hits = 1,
				Break = 32,
				Dash = 18,
				BurnTicks = 3,
				Element = "Flame",
			},
			X = {
				Key = "X",
				Name = "Eruption Uppercut",
				DisplayName = "Eruption Uppercut - Dung Nham Xung Thiên Quyền",
				Mastery = 50,
				Cooldown = 8.2,
				Cost = 16,
				Range = 24,
				Radius = 17,
				Multiplier = 3.70,
				Hits = 2,
				Break = 40,
				BurnTicks = 4,
				Knockup = 26,
				Element = "Flame",
			},
			C = {
				Key = "C",
				Name = "Ashura Sunburst",
				DisplayName = "Ashura Sunburst - Tu La Nhật Thực Bạo",
				Mastery = 100,
				Cooldown = 11.5,
				Cost = 22,
				Range = 28,
				Radius = 21,
				Multiplier = 4.65,
				Hits = 4,
				Break = 52,
				BurnTicks = 5,
				Element = "Flame",
			},
		},
	},

	celestial_godhuman = {
		Id = "celestial_godhuman",
		Name = "Thiên Thần Tuyệt Kỹ",
		DisplayName = "Thiên Thần Tuyệt Kỹ - Celestial Godhuman",
		MasterNPC = "GrandmasterAurelius",
		MasterName = "Thần Võ Aurelius - Celestial Godhuman",
		IslandId = "TempleOfTheCore",
		MasterOffset = Vector3.new(22, 0, -18),
		PriceGold = 3500000,
		PriceShards = 3500,
		Element = "Celestial",
		Color = Color3.fromRGB(255, 224, 125),
		Desc = "Đỉnh cao võ học hợp nhất lục giới, tung thần quyền tinh tú chấn vỡ không gian.",
		Kata = {
			{ Step = 1, Name = "Astral Palm Flash", Mult = 1.25, Reach = 16.5, Width = 10.5, Cadence = 0.20, Break = 9, Dash = 6.5 },
			{ Step = 2, Name = "Divine Gale Kick", Mult = 1.38, Reach = 17.2, Width = 11.0, Cadence = 0.20, Break = 11, Dash = 6.5 },
			{ Step = 3, Name = "Sovereign Void Elbow", Mult = 1.52, Reach = 18.0, Width = 12.0, Cadence = 0.22, Break = 14, StunDur = 0.40 },
			{ Step = 4, Name = "Heaven Piercing Impact", Mult = 2.18, Reach = 21.0, Width = 15.0, Cadence = 0.33, Break = 28, StunDur = 0.90, Knockback = 34, AoE = true },
		},
		Moves = {
			Z = {
				Key = "Z",
				Name = "Soaring Beast Barrage",
				DisplayName = "Soaring Beast Barrage - Bách Thú Tinh Quyền",
				Mastery = 1,
				Cooldown = 4.8,
				Cost = 12,
				Range = 32,
				Radius = 15,
				Multiplier = 3.35,
				Hits = 5,
				Break = 36,
				Dash = 28,
				Element = "Celestial",
			},
			X = {
				Key = "X",
				Name = "Heaven & Earth Shatter",
				DisplayName = "Heaven & Earth Shatter - Thiên Địa Phá Toái",
				Mastery = 50,
				Cooldown = 8.0,
				Cost = 18,
				Range = 30,
				Radius = 20,
				Multiplier = 4.25,
				Hits = 3,
				Break = 48,
				StunDur = 1.1,
				Element = "Celestial",
			},
			C = {
				Key = "C",
				Name = "Sixth Realm Celestial Impact",
				DisplayName = "Sixth Realm Celestial Impact - Lục Giới Thần Xung",
				Mastery = 100,
				Cooldown = 11.8,
				Cost = 24,
				Range = 36,
				Radius = 23,
				Multiplier = 5.45,
				Hits = 6,
				Break = 62,
				Dash = 30,
				StunDur = 1.4,
				Element = "Celestial",
			},
		},
	},
}

function CombatData.ResolveStyleId(rawId)
	if type(rawId) ~= "string" or rawId == "" then
		return "skyborn_combat"
	end
	if CombatData.MartialStyles[rawId] then
		return rawId
	end
	local hit = CombatData.StyleAliases[rawId] or CombatData.StyleAliases[string.lower(rawId)]
	return hit or "skyborn_combat"
end

-- ============================================================================
-- 2. CHARGED HEAVY SLASH (#35) & AIMED RAYCAST GUNPLAY SPECS (#36, #37, #38)
-- ============================================================================
CombatData.ChargedSlashWeapons = {
	noxar_abyssal_greatsword = true,
	noxar_greatsword = true,
	abyssal_greatsword = true,
	yamo_voidblade = true,
}

CombatData.ChargedCrescentSpec = {
	Name = "Charged Crescent Slash",
	MinMultiplier = 1.35,
	MaxMultiplier = 2.35,
	MinRange = 22,
	MaxRange = 42,
	MinRadius = 14,
	MaxRadius = 24,
	MinBreakGauge = 20,
	MaxBreakGauge = 45,
	Cooldown = 2.6,
	StaminaCost = 14,
	Element = "VoidMagma",
}

function CombatData.IsChargedSlashWeapon(weaponId)
	if type(weaponId) ~= "string" or weaponId == "" then
		return false
	end
	if CombatData.ChargedSlashWeapons[weaponId] then
		return true
	end
	local low = string.lower(weaponId)
	return string.find(low, "noxar", 1, true) ~= nil
		or string.find(low, "greatsword", 1, true) ~= nil
		or string.find(low, "yamo", 1, true) ~= nil
		or string.find(low, "sunshard", 1, true) ~= nil
		or string.find(low, "cyber_katana", 1, true) ~= nil
		or string.find(low, "sylvaris", 1, true) ~= nil
		or string.find(low, "ignivar", 1, true) ~= nil
		or string.find(low, "nerith", 1, true) ~= nil
		or string.find(low, "aion", 1, true) ~= nil
		or string.find(low, "architect", 1, true) ~= nil
		or string.find(low, "frost_staff", 1, true) ~= nil
end

CombatData.GunSpecs = {
	soul_guitar_void = {
		Id = "soul_guitar_void",
		Name = "Soul Guitar of the Void",
		SubKind = "SoulGuitarWave",
		MaxRange = 125,
		BeamRadius = 11.5,
		Piercing = true,
		M1Multiplier = 1.42,
		LifestealPct = 0.15,
		StunDuration = 1.4,
		Break = 18,
		Cooldown = 0.42,
		Element = "Void",
		Color = Color3.fromRGB(185, 88, 255),
	},
	cryo_railgun = {
		Id = "cryo_railgun",
		Name = "Cryo Railgun",
		SubKind = "CryoRailLaser",
		MaxRange = 115,
		BeamLength = 115,
		BeamRadius = 8.5,
		Piercing = true,
		M1Multiplier = 1.56,
		FreezeDuration = 2.2,
		Break = 22,
		Cooldown = 0.50,
		Element = "Frost",
		Color = Color3.fromRGB(82, 236, 255),
	},
	solar_kabucha = {
		Id = "solar_kabucha",
		Name = "Solar Kabucha",
		SubKind = "SolarBlast",
		MaxRange = 115,
		BeamRadius = 8.5,
		Piercing = false,
		M1Multiplier = 1.28,
		BurnTicks = 2,
		Break = 14,
		Cooldown = 0.38,
		Element = "Flame",
		Color = Color3.fromRGB(255, 185, 65),
	},
	aether_flintlock = {
		Id = "aether_flintlock",
		Name = "Aether Flintlock",
		SubKind = "AetherShot",
		MaxRange = 105,
		BeamRadius = 8.5,
		Piercing = false,
		M1Multiplier = 1.25,
		Break = 12,
		Cooldown = 0.34,
		Element = "Sky",
		Color = Color3.fromRGB(130, 215, 255),
	},
	kabucha_wind = {
		Id = "kabucha_wind",
		Name = "Tempest Kabucha Slingshot",
		SubKind = "WindGaleShot",
		MaxRange = 115,
		BeamRadius = 9.0,
		Piercing = true,
		M1Multiplier = 1.38,
		Break = 16,
		Cooldown = 0.36,
		Element = "Sky",
		Color = Color3.fromRGB(56, 189, 248),
	},
	bizarre_rifle_cyber = {
		Id = "bizarre_rifle_cyber",
		Name = "Cyber Bizarre Pulse Rifle",
		SubKind = "CyberPulseBeam",
		MaxRange = 125,
		BeamRadius = 9.0,
		Piercing = true,
		M1Multiplier = 1.48,
		FreezeDuration = 1.4,
		Break = 18,
		Cooldown = 0.38,
		Element = "Frost",
		Color = Color3.fromRGB(34, 211, 238),
	},
	sylvaris_thornbow = {
		Id = "sylvaris_thornbow",
		Name = "Sylvaris Spirit Longbow",
		SubKind = "SpiritArrowVolley",
		MaxRange = 135,
		BeamRadius = 9.5,
		Piercing = true,
		M1Multiplier = 1.62,
		Break = 20,
		Cooldown = 0.36,
		Element = "Sky",
		Color = Color3.fromRGB(52, 211, 153),
	},
	ignivar_hellcannon = {
		Id = "ignivar_hellcannon",
		Name = "Ignivar Hellfire Cannon",
		SubKind = "HellfireMortar",
		MaxRange = 125,
		BeamRadius = 11.5,
		Piercing = true,
		M1Multiplier = 1.75,
		BurnTicks = 3,
		Break = 26,
		Cooldown = 0.46,
		Element = "Flame",
		Color = Color3.fromRGB(249, 115, 22),
	},
	aion_chrono_pistols = {
		Id = "aion_chrono_pistols",
		Name = "Aion Dual Chrono Pistols",
		SubKind = "ChronoTwinBarrage",
		MaxRange = 130,
		BeamRadius = 9.5,
		Piercing = true,
		M1Multiplier = 1.82,
		Break = 22,
		Cooldown = 0.28,
		Element = "Void",
		Color = Color3.fromRGB(168, 85, 247),
	},
	veyr_singularity_cannon = {
		Id = "veyr_singularity_cannon",
		Name = "Veyr Singularity Rail-Cannon",
		SubKind = "SingularityBeam",
		MaxRange = 145,
		BeamRadius = 12.0,
		Piercing = true,
		M1Multiplier = 1.98,
		Break = 30,
		Cooldown = 0.44,
		Element = "Void",
		Color = Color3.fromRGB(244, 63, 94),
	},
}

-- ============================================================================
-- 3. MASTERY PROGRESSION (#41) & 12-FRUIT AWAKENED V2 MOVESETS (#42)
-- ============================================================================
CombatData.MasteryConfig = {
	MaxLevel = 600,
	SkillDamagePerLevel = 0.0005, -- +30% Skill DMG at Mastery Lv. 600
	MoveUnlockThresholds = {
		Z = 1,   -- Always usable immediately
		F = 1,   -- Flight/Mobility always usable immediately; Lv. 75 unlocks V2 Flight Overdrive
		X = 50,
		C = 100,
		V = 200,
	},
	MythicalVThreshold = 250,
	FlightEnhancedLevel = 75,
	Milestones = {
		{ Level = 50, Gold = 2500, Shards = 25, Label = "Mở khóa chiêu [X]" },
		{ Level = 100, Gold = 6000, Shards = 60, Label = "Mở khóa chiêu [C] & Cường hóa [F]" },
		{ Level = 200, Gold = 15000, Shards = 150, Label = "Mở khóa Tuyệt Kỹ [V]" },
		{ Level = 300, Gold = 30000, Shards = 300, Label = "Đột phá Tinh Thông Cao Cấp" },
		{ Level = 600, Gold = 100000, Shards = 1000, TitleId = "grand_master_600", Label = "Đạt Đỉnh Cao Mastery Lv. 600" },
	},
}

function CombatData.RequiredMasteryXP(level)
	local lv = math.clamp(tonumber(level) or 1, 1, 600)
	return math.floor(45 + lv * 16 + math.pow(lv, 1.32) * 2.2)
end

CombatData.FruitOrder = {
	"GaleCore",
	"SandstoneCore",
	"SolarFlameCore",
	"GlacierIceCore",
	"CelestialLightCore",
	"StarforgedMagmaCore",
	"ThunderRumbleCore",
	"AstralGravityCore",
	"DimensionalPortalCore",
	"SolarTitanCore",
	"AetherflowCore",
	"AbyssalSovereignCore",
}

CombatData.FruitAliases = {
	gale = "GaleCore",
	gale_core = "GaleCore",
	galecore = "GaleCore",
	sand = "SandstoneCore",
	sandstone = "SandstoneCore",
	sandstone_core = "SandstoneCore",
	sandstonecore = "SandstoneCore",
	flame = "SolarFlameCore",
	solar_flame = "SolarFlameCore",
	solarflamecore = "SolarFlameCore",
	ice = "GlacierIceCore",
	frostbite = "GlacierIceCore",
	glacier_ice = "GlacierIceCore",
	glaciericecore = "GlacierIceCore",
	light = "CelestialLightCore",
	celestial_light = "CelestialLightCore",
	celestiallightcore = "CelestialLightCore",
	magma = "StarforgedMagmaCore",
	starforged_magma = "StarforgedMagmaCore",
	starforgedmagmacore = "StarforgedMagmaCore",
	rumble = "ThunderRumbleCore",
	thunder = "ThunderRumbleCore",
	thunder_rumble = "ThunderRumbleCore",
	thunderrumblecore = "ThunderRumbleCore",
	gravity = "AstralGravityCore",
	astral_gravity = "AstralGravityCore",
	astralgravitycore = "AstralGravityCore",
	portal = "DimensionalPortalCore",
	dimensional_portal = "DimensionalPortalCore",
	dimensionalportalcore = "DimensionalPortalCore",
	buddha = "SolarTitanCore",
	solar_titan = "SolarTitanCore",
	solartitancore = "SolarTitanCore",
	dough = "AetherflowCore",
	mochi = "AetherflowCore",
	aetherflow = "AetherflowCore",
	aetherflowcore = "AetherflowCore",
	dragon = "AbyssalSovereignCore",
	abyssal_dragon = "AbyssalSovereignCore",
	void_dragon = "AbyssalSovereignCore",
	abyssal_sovereign = "AbyssalSovereignCore",
	abyssalsovereigncore = "AbyssalSovereignCore",
}

function CombatData.ResolveFruitId(rawId)
	if type(rawId) ~= "string" or rawId == "" then
		return ""
	end
	for _, canonical in ipairs(CombatData.FruitOrder) do
		if rawId == canonical then
			return canonical
		end
	end
	return CombatData.FruitAliases[rawId] or CombatData.FruitAliases[string.lower(rawId)] or rawId
end

CombatData.FruitCatalog = {
	GaleCore = { Id = "GaleCore", Name = "Trái Cuồng Phong - Gale Core", Rarity = "Common", Type = "Elemental", Logia = true, Element = "Sky", GoldValue = 75000, AwakenShards = 400 },
	SandstoneCore = { Id = "SandstoneCore", Name = "Trái Sa Mạc - Sandstone Core", Rarity = "Uncommon", Type = "Elemental", Logia = true, Element = "Sand", GoldValue = 240000, AwakenShards = 500 },
	SolarFlameCore = { Id = "SolarFlameCore", Name = "Trái Thái Dương Hỏa - Solar Flame", Rarity = "Uncommon", Type = "Elemental", Logia = true, Element = "Flame", GoldValue = 380000, AwakenShards = 650 },
	GlacierIceCore = { Id = "GlacierIceCore", Name = "Trái Vĩnh Băng - Glacier Ice", Rarity = "Rare", Type = "Elemental", Logia = true, Element = "Frost", GoldValue = 550000, AwakenShards = 800, WaterWalk = "Ice" },
	CelestialLightCore = { Id = "CelestialLightCore", Name = "Trái Thánh Quang - Celestial Light", Rarity = "Rare", Type = "Elemental", Logia = true, Element = "Light", GoldValue = 850000, AwakenShards = 950 },
	StarforgedMagmaCore = { Id = "StarforgedMagmaCore", Name = "Trái Dung Nham Tinh Cầu - Starforged Magma", Rarity = "Rare", Type = "Elemental", Logia = true, Element = "Magma", GoldValue = 1150000, AwakenShards = 1100, WaterWalk = "Basalt" },
	ThunderRumbleCore = { Id = "ThunderRumbleCore", Name = "Trái Lôi Thần - Thunder Rumble", Rarity = "Legendary", Type = "Elemental", Logia = true, Element = "Lightning", GoldValue = 2100000, AwakenShards = 1500 },
	AstralGravityCore = { Id = "AstralGravityCore", Name = "Trái Trọng Trường - Astral Gravity", Rarity = "Legendary", Type = "Natural", Logia = false, Element = "Gravity", GoldValue = 2500000, AwakenShards = 1650 },
	DimensionalPortalCore = { Id = "DimensionalPortalCore", Name = "Trái Không Gian - Dimensional Portal", Rarity = "Legendary", Type = "Natural", Logia = false, Element = "Portal", GoldValue = 2900000, AwakenShards = 1800 },
	SolarTitanCore = { Id = "SolarTitanCore", Name = "Trái Kim Thân Hộ Pháp - Solar Titan", Rarity = "Mythic", Type = "Beast", Logia = false, MythicalZoan = true, Element = "Light", GoldValue = 4200000, AwakenShards = 2200 },
	AetherflowCore = { Id = "AetherflowCore", Name = "Trái Huyết Tinh Aether - Aetherflow", Rarity = "Mythic", Type = "Natural", Logia = false, Element = "Aether", GoldValue = 4800000, AwakenShards = 2400 },
	AbyssalSovereignCore = { Id = "AbyssalSovereignCore", Name = "Trái Hắc Long Hư Không - Abyssal Sovereign", Rarity = "Mythic", Type = "Beast", Logia = false, MythicalZoan = true, DragonFury = true, Element = "Void", GoldValue = 6500000, AwakenShards = 2800 },
}

-- Complete Awakened V2 Moveset for all 12 Devil Fruits (#42)
-- MultBoost ranges +28%..+42% (1.28..1.42), RadiusScale expands AoE, Hits adds multi-hit shockwaves
CombatData.AwakenedFruitMoves = {
	GaleCore = {
		Z = { Name = "Tempest Razor V2 - Lưỡi Đao Siêu Bão", MultBoost = 1.30, RadiusScale = 1.35, Hits = 3, Mechanic = "CyclonePull", PullStrength = 16 },
		X = { Name = "Hurricane Prison V2 - Ngục Tù Lốc Xoáy", MultBoost = 1.32, RadiusScale = 1.40, Hits = 3, Mechanic = "CyclonePull", PullStrength = 20 },
		C = { Name = "Skyward Stratosphere V2 - Bão Tầng Bình Lưu", MultBoost = 1.34, RadiusScale = 1.45, Hits = 4, Mechanic = "ShockwaveMulti" },
		V = { Name = "Eye of the Sovereign Storm V2 - Đại Phong Thần Nộ", MultBoost = 1.38, RadiusScale = 1.50, Hits = 5, Mechanic = "CyclonePull", PullStrength = 26 },
		F = { Name = "Supersonic Jetstream V2 - Cánh Gió Siêu Thanh", MultBoost = 1.28, RadiusScale = 1.30, Hits = 2, Mechanic = "SpeedGlide" },
	},
	SandstoneCore = {
		Z = { Name = "Dune Guillotine V2 - Lưỡi Hái Cát Vàng", MultBoost = 1.30, RadiusScale = 1.35, Hits = 2, Mechanic = "QuicksandSink", SlowPct = 0.35 },
		X = { Name = "Abyssal Quicksand Pit V2 - Hố Cát Tử Thần", MultBoost = 1.33, RadiusScale = 1.42, Hits = 3, Mechanic = "QuicksandSink", PullStrength = 22 },
		C = { Name = "Pharaoh Sandstorm V2 - Bão Cát Hoàng Đế", MultBoost = 1.35, RadiusScale = 1.45, Hits = 4, Mechanic = "BlindDoT", DoTTicks = 3 },
		V = { Name = "Desert Burial Cataclysm V2 - Đại Mộ Sa Mạc", MultBoost = 1.39, RadiusScale = 1.52, Hits = 5, Mechanic = "QuicksandSink", PullStrength = 28 },
		F = { Name = "Mirage Sand Flight V2 - Lốc Cát Phi Hành", MultBoost = 1.28, RadiusScale = 1.30, Hits = 2, Mechanic = "SpeedGlide" },
	},
	SolarFlameCore = {
		Z = { Name = "Blue Flare Bullets V2 - Thanh Viêm Liên Đạn", MultBoost = 1.31, RadiusScale = 1.35, Hits = 3, Mechanic = "SolarBurnDoT", DoTTicks = 3 },
		X = { Name = "Prominence Pillar V2 - Cột Lửa Nhật Thực", MultBoost = 1.34, RadiusScale = 1.42, Hits = 3, Mechanic = "SolarBurnDoT", DoTTicks = 4 },
		C = { Name = "Hellfire Vortex V2 - Vòng Xoáy Luyện Ngục", MultBoost = 1.36, RadiusScale = 1.48, Hits = 4, Mechanic = "SolarBurnDoT", DoTTicks = 4 },
		V = { Name = "Cruel Sun Supernova V2 - Đại Nhật Hủy Diệt", MultBoost = 1.40, RadiusScale = 1.55, Hits = 5, Mechanic = "SolarBurnDoT", DoTTicks = 5 },
		F = { Name = "Blazing Rocket Trail V2 - Hỏa Tiễn Xuyên Mây", MultBoost = 1.29, RadiusScale = 1.32, Hits = 2, Mechanic = "SolarBurnDoT", DoTTicks = 2 },
	},
	GlacierIceCore = {
		Z = { Name = "Absolute Zero Lances V2 - Băng Thương Tuyệt Độ", MultBoost = 1.31, RadiusScale = 1.36, Hits = 3, Mechanic = "AbsoluteZeroChill", FreezeDur = 1.3 },
		X = { Name = "Glacial Surge Wave V2 - Sóng Thần Băng Vĩnh Cửu", MultBoost = 1.34, RadiusScale = 1.44, Hits = 3, Mechanic = "AbsoluteZeroChill", FreezeDur = 1.6 },
		C = { Name = "Cryo Pheasant Talon V2 - Băng Điểu Tuyệt Sát", MultBoost = 1.36, RadiusScale = 1.46, Hits = 3, Mechanic = "AbsoluteZeroChill", FreezeDur = 1.8 },
		V = { Name = "Eternal Ice Age V2 - Kỷ Băng Hà Vĩnh Cửu", MultBoost = 1.41, RadiusScale = 1.55, Hits = 5, Mechanic = "AbsoluteZeroChill", FreezeDur = 2.4 },
		F = { Name = "Glacier Skate Overdrive V2 - Trượt Băng Cực Quang", MultBoost = 1.28, RadiusScale = 1.30, Hits = 2, Mechanic = "SpeedGlide" },
	},
	CelestialLightCore = {
		Z = { Name = "Divine Photon Spear V2 - Thánh Thương Ánh Sáng", MultBoost = 1.32, RadiusScale = 1.36, Hits = 2, Mechanic = "LightSpeedBarrage" },
		X = { Name = "Mirror Star Reflection V2 - Kính Quang Phản Chiếu", MultBoost = 1.34, RadiusScale = 1.42, Hits = 4, Mechanic = "LightSpeedBarrage" },
		C = { Name = "Lightspeed Judgment Kick V2 - Quang Tốc Thần Cước", MultBoost = 1.37, RadiusScale = 1.45, Hits = 3, Mechanic = "ThunderChainStun", StunDur = 1.0 },
		V = { Name = "Heaven's Starfall Barrage V2 - Vạn Tinh Thiên Phạt", MultBoost = 1.40, RadiusScale = 1.54, Hits = 6, Mechanic = "LightSpeedBarrage" },
		F = { Name = "Relativistic Beam Flight V2 - Tia Sáng Đổi Hướng", MultBoost = 1.30, RadiusScale = 1.32, Hits = 2, Mechanic = "SpeedGlide" },
	},
	StarforgedMagmaCore = {
		Z = { Name = "Volcanic Hound Fang V2 - Minh Khuyển Dung Nham", MultBoost = 1.33, RadiusScale = 1.38, Hits = 2, Mechanic = "MagmaPoolDoT", DoTTicks = 4 },
		X = { Name = "Tectonic Eruption Clamp V2 - Đại Địa Phun Trào", MultBoost = 1.36, RadiusScale = 1.44, Hits = 3, Mechanic = "MagmaPoolDoT", DoTTicks = 5 },
		C = { Name = "Starcore Lava Hound V2 - Hỏa Ngục Tinh Cầu", MultBoost = 1.38, RadiusScale = 1.48, Hits = 4, Mechanic = "MagmaPoolDoT", DoTTicks = 5 },
		V = { Name = "Apocalyptic Meteor Shower V2 - Mưa Thiên Thạch Dung Nham", MultBoost = 1.42, RadiusScale = 1.55, Hits = 6, Mechanic = "MagmaPoolDoT", DoTTicks = 6 },
		F = { Name = "Magma Beast Glide V2 - Cưỡi Thú Dung Nham", MultBoost = 1.29, RadiusScale = 1.34, Hits = 2, Mechanic = "MagmaPoolDoT", DoTTicks = 3 },
	},
	ThunderRumbleCore = {
		Z = { Name = "Raigo Dragon Bolt V2 - Lôi Long Giáng Thế", MultBoost = 1.32, RadiusScale = 1.38, Hits = 3, Mechanic = "ThunderChainStun", StunDur = 1.1 },
		X = { Name = "Sky Judgment Pillar V2 - Cột Thiên Lôi Phán Quyết", MultBoost = 1.35, RadiusScale = 1.45, Hits = 3, Mechanic = "ThunderChainStun", StunDur = 1.3 },
		C = { Name = "Plasma Storm Dome V2 - Lồng Điện Từ Trường", MultBoost = 1.38, RadiusScale = 1.48, Hits = 4, Mechanic = "ThunderChainStun", StunDur = 1.5 },
		V = { Name = "Thundercloud Apocalypse Orb V2 - Lôi Cầu Diệt Thế", MultBoost = 1.42, RadiusScale = 1.56, Hits = 5, Mechanic = "ThunderChainStun", StunDur = 1.9 },
		F = { Name = "Triple Flash Teleport V2 - Tam Đoạn Điện Thiểm", MultBoost = 1.30, RadiusScale = 1.32, Hits = 2, Mechanic = "SpeedGlide" },
	},
	AstralGravityCore = {
		Z = { Name = "Graviton Crush Wave V2 - Sóng Trọng Lực Nghiền Nát", MultBoost = 1.31, RadiusScale = 1.38, Hits = 2, Mechanic = "SingularityGravityPull", PullStrength = 22 },
		X = { Name = "Zero-G Pinion Slam V2 - Trọng Trường Khóa Chặt", MultBoost = 1.34, RadiusScale = 1.44, Hits = 3, Mechanic = "SingularityGravityPull", StunDur = 1.3 },
		C = { Name = "Black Hole Convergence V2 - Kỳ Điểm Hố Đen", MultBoost = 1.37, RadiusScale = 1.50, Hits = 4, Mechanic = "SingularityGravityPull", PullStrength = 30 },
		V = { Name = "Planetary Asteroid Fall V2 - Đại Tinh Thạch Va Chạm", MultBoost = 1.41, RadiusScale = 1.56, Hits = 5, Mechanic = "SingularityGravityPull", PullStrength = 34 },
		F = { Name = "Orbital Meteor Surf V2 - Cưỡi Thiên Thạch Tinh Cầu", MultBoost = 1.29, RadiusScale = 1.32, Hits = 2, Mechanic = "SpeedGlide" },
	},
	DimensionalPortalCore = {
		Z = { Name = "Quantum Severance Dash V2 - Trảm Không Gian Lượng Tử", MultBoost = 1.31, RadiusScale = 1.36, Hits = 3, Mechanic = "DimensionalRiftSlash" },
		X = { Name = "Void Phase Sanctuary V2 - Lãnh Địa Hư Không Ẩn", MultBoost = 1.34, RadiusScale = 1.42, Hits = 3, Mechanic = "DimensionalRiftSlash", StunDur = 1.1 },
		C = { Name = "Omniversal World Gate V2 - Đại Cổng Dịch Chuyển 20 Đảo", MultBoost = 1.35, RadiusScale = 1.45, Hits = 2, Mechanic = "WorldWarpRift" },
		V = { Name = "Collapsed Dimension Prison V2 - Không Gian Sụp Đổ", MultBoost = 1.40, RadiusScale = 1.54, Hits = 5, Mechanic = "SingularityGravityPull", PullStrength = 28 },
		F = { Name = "Rift Step Blink V2 - Bước Nhảy Xuyên Không", MultBoost = 1.28, RadiusScale = 1.30, Hits = 2, Mechanic = "SpeedGlide" },
	},
	SolarTitanCore = {
		Z = { Name = "Sovereign Golden Impact V2 - Phật Quang Trấn Địa", MultBoost = 1.32, RadiusScale = 1.42, Hits = 2, Mechanic = "ColossusShockwave" },
		X = { Name = "Heavenly Halo Judgment V2 - Vòng Thánh Quang Phán Xét", MultBoost = 1.35, RadiusScale = 1.46, Hits = 3, Mechanic = "ColossusShockwave", StunDur = 1.2 },
		C = { Name = "Divine Supernova Pillar V2 - Thánh Trụ Quang Minh", MultBoost = 1.38, RadiusScale = 1.50, Hits = 4, Mechanic = "ColossusShockwave" },
		V = { Name = "Twilight of the Gods V2 - Hoàng Hôn Chư Thần Kim Thân", MultBoost = 1.42, RadiusScale = 1.58, Hits = 5, Mechanic = "ColossusShockwave", StunDur = 1.6 },
		F = { Name = "Radiant Ascent Leap V2 - Kim Thân Đạp Không", MultBoost = 1.29, RadiusScale = 1.35, Hits = 2, Mechanic = "ColossusShockwave" },
	},
	AetherflowCore = {
		Z = { Name = "Searing Aether Missile V2 - Pháo Tinh Chất Nóng Chảy", MultBoost = 1.33, RadiusScale = 1.38, Hits = 2, Mechanic = "AetherBindBarrage", StunDur = 0.9 },
		X = { Name = "Crystalline Spike Skewers V2 - Rừng Gai Huyết Tinh", MultBoost = 1.36, RadiusScale = 1.45, Hits = 4, Mechanic = "AetherBindBarrage", StunDur = 1.2 },
		C = { Name = "Piercing Chariot Wheel V2 - Bánh Xe Gai Nghiền Nát", MultBoost = 1.39, RadiusScale = 1.48, Hits = 4, Mechanic = "AetherBindBarrage", PullStrength = 24 },
		V = { Name = "Dimensional Aether Fist Fusillade V2 - Bách Quyền Không Gian", MultBoost = 1.42, RadiusScale = 1.55, Hits = 6, Mechanic = "AetherBindBarrage", StunDur = 1.5 },
		F = { Name = "Rolling Aether Wheel V2 - Vòng Xoáy Thần Tốc", MultBoost = 1.30, RadiusScale = 1.34, Hits = 2, Mechanic = "SpeedGlide" },
	},
	AbyssalSovereignCore = {
		Z = { Name = "Abyssal Heat Ray V2 - Long Tức Xuyên Thiên", MultBoost = 1.34, RadiusScale = 1.40, Hits = 3, Mechanic = "AbyssalVoidBreath", DoTTicks = 4 },
		X = { Name = "Void Sovereign Talons V2 - Tuyệt Trảo Hắc Long Vương", MultBoost = 1.37, RadiusScale = 1.45, Hits = 3, Mechanic = "AbyssalVoidBreath", StunDur = 1.2 },
		C = { Name = "Cataclysmic Dragon Starshower V2 - Vạn Long Thiên Hỏa Vũ", MultBoost = 1.40, RadiusScale = 1.54, Hits = 5, Mechanic = "AbyssalVoidBreath", DoTTicks = 5 },
		V = { Name = "Sovereign Dragon Ascension V2 - Chân Thân Hoàng Long Tối Thượng", MultBoost = 1.42, RadiusScale = 1.60, Hits = 5, Mechanic = "DragonSovereignTransform" },
		F = { Name = "Abyssal Wing Hurricane V2 - Long Vũ Xuyên Vân", MultBoost = 1.30, RadiusScale = 1.36, Hits = 2, Mechanic = "SpeedGlide" },
	},
}

-- ============================================================================
-- 4. HOURLY DETERMINISTIC MIRAGE FRUIT STOCK ROTATION (#43) & 40% TRADING (#44)
-- ============================================================================
CombatData.TradeMaxValueDiffRatio = 0.40
CombatData.TradeCountdownSeconds = 5

function CombatData.GetFruitGoldValue(fruitId)
	local cid = CombatData.ResolveFruitId(fruitId)
	local spec = CombatData.FruitCatalog[cid]
	return (spec and spec.GoldValue) or 250000
end

function CombatData.GetHourlyMirageStock(unixTime)
	local now = math.floor(tonumber(unixTime) or os.time())
	local hourSeed = math.floor(now / 3600)
	local refreshIn = math.max(1, 3600 - (now % 3600))

	local rngState = (hourSeed * 1103515245 + 12345) % 2147483647
	local function nextRand(maxN)
		rngState = (rngState * 48271) % 2147483647
		return (rngState % maxN) + 1
	end

	local tierCommon = { "GaleCore", "SandstoneCore", "SolarFlameCore" }
	local tierMid = { "SandstoneCore", "SolarFlameCore", "GlacierIceCore", "CelestialLightCore" }
	local tierRare = { "GlacierIceCore", "CelestialLightCore", "StarforgedMagmaCore" }
	local tierHigh = { "StarforgedMagmaCore", "ThunderRumbleCore", "AstralGravityCore", "DimensionalPortalCore" }
	local tierApex = { "ThunderRumbleCore", "AstralGravityCore", "DimensionalPortalCore", "SolarTitanCore", "AetherflowCore", "AbyssalSovereignCore" }

	local picked = {}
	local pickedSet = {}
	local function pickFrom(pool)
		local startIdx = nextRand(#pool)
		for offset = 0, #pool - 1 do
			local id = pool[((startIdx + offset - 1) % #pool) + 1]
			if not pickedSet[id] then
				pickedSet[id] = true
				table.insert(picked, id)
				return
			end
		end
	end

	pickFrom(tierCommon)
	pickFrom(tierMid)
	pickFrom(tierRare)
	pickFrom(tierHigh)
	pickFrom(tierApex)

	local items = {}
	for idx, fid in ipairs(picked) do
		local cat = CombatData.FruitCatalog[fid]
		if cat then
			table.insert(items, {
				Slot = idx,
				Id = cat.Id,
				Name = cat.Name,
				Rarity = cat.Rarity,
				Type = cat.Type,
				Element = cat.Element,
				PriceGold = cat.GoldValue,
			})
		end
	end

	return {
		HourSeed = hourSeed,
		RefreshIn = refreshIn,
		Items = items,
	}
end

-- ============================================================================
-- 5. SIX RACE V4 PASSIVES & DR. VEGA RACE REROLL (#51, #52, #59)
-- ============================================================================
CombatData.RaceOrder = { "Skyborn", "Mink", "Leviathan", "Cyborg", "Ghoul", "Draco" }
CombatData.RaceRerollCostShards = 50
CombatData.TrialDurationSeconds = 60

CombatData.RaceV4Passives = {
	Skyborn = {
		Id = "Skyborn",
		Name = "Thiên Tộc V4 - King's Aerial Dominion",
		StaggerRadius = 22,
		StaggerInterval = 2.8,
		StaggerDuration = 0.85,
		GlideSpeedBonus = 0.28,
		AtkMult = 1.22,
		DefMult = 1.18,
	},
	Mink = {
		Id = "Mink",
		Name = "Tộc Thú V4 - Tempest Tornado Dash",
		WalkSpeedBonus = 0.45,
		WhirlwindRadius = 15,
		MiniStunDuration = 0.55,
		AtkMult = 1.18,
		DefMult = 1.14,
	},
	Leviathan = {
		Id = "Leviathan",
		Name = "Hải Tộc V4 - Water Leviathan Shield",
		ShieldMaxHPPct = 0.25,
		ShieldRegenPctPerSec = 0.035,
		ArmorBreakSlowPct = 0.35,
		ArmorBreakDuration = 2.5,
		WaterSpeedBonus = 0.35,
		WaterResistPct = 0.80,
		AtkMult = 1.18,
		DefMult = 1.32,
	},
	Cyborg = {
		Id = "Cyborg",
		Name = "Cơ Giới V4 - Quantum Chain Orbs",
		ChainMaxTargets = 4,
		ChainRadius = 26,
		ChainDamageRatio = 0.32,
		EnergyRefundPerChain = 4,
		AtkMult = 1.22,
		DefMult = 1.24,
	},
	Ghoul = {
		Id = "Ghoul",
		Name = "Huyết Tộc V4 - Blood-Siphon Domain",
		SkillLifeLeechPct = 0.18,
		BasicLifeLeechPct = 0.10,
		CooldownReductionPct = 0.22,
		DomainRadius = 22,
		AtkMult = 1.25,
		DefMult = 1.15,
	},
	Draco = {
		Id = "Draco",
		Name = "Long Tộc V4 - Primordial Thorn Pyre",
		ThornReflectPct = 0.25,
		BurnAuraRadius = 24,
		BurnAuraAtkRatio = 0.42,
		AtkMult = 1.30,
		DefMult = 1.26,
	},
}

-- ============================================================================
-- 6. 5-STAGE BUSOSHOKU HAKI + 8 AURA COLOR SKINS (#53) & KEN V2 (#54)
-- ============================================================================
CombatData.HakiStages = {
	[0] = { Stage = 0, Name = "Stage 0 - Buso Hands", Coverage = "Hands", MinEXP = 0, AtkBonus = 0.08, DefBonus = 0.05, BreakBonus = 3 },
	[1] = { Stage = 1, Name = "Stage 1 - Buso Arms", Coverage = "Arms", MinEXP = 80, AtkBonus = 0.11, DefBonus = 0.08, BreakBonus = 5 },
	[2] = { Stage = 2, Name = "Stage 2 - Buso Torso & Arms", Coverage = "Torso+Arms", MinEXP = 240, AtkBonus = 0.14, DefBonus = 0.11, BreakBonus = 7 },
	[3] = { Stage = 3, Name = "Stage 3 - Buso Upper Body & Legs", Coverage = "UpperBody+Legs", MinEXP = 520, AtkBonus = 0.17, DefBonus = 0.13, BreakBonus = 10 },
	[4] = { Stage = 4, Name = "Stage 4 - Full Body Busoshoku", Coverage = "FullBody", MinEXP = 950, AtkBonus = 0.19, DefBonus = 0.16, BreakBonus = 13 },
	[5] = { Stage = 5, Name = "Stage 5 - Sovereign Overdrive", Coverage = "SovereignOverdrive", MinEXP = 1600, AtkBonus = 0.22, DefBonus = 0.18, BreakBonus = 16 },
}

function CombatData.GetHakiStageForEXP(exp)
	local val = tonumber(exp) or 0
	local best = 0
	for stage = 0, 5 do
		if val >= CombatData.HakiStages[stage].MinEXP then
			best = stage
		end
	end
	return best
end

CombatData.HakiColorOrder = {
	"crimson_conqueror",
	"solar_gold",
	"cryo_cyan",
	"void_violet",
	"emerald_jade",
	"sakura_pink",
	"electric_cobalt",
	"pure_white",
}

CombatData.HakiColors = {
	crimson_conqueror = { Id = "crimson_conqueror", Name = "Hồng Liên Bá Vương - Crimson Conqueror", Color = Color3.fromRGB(255, 52, 72), CostShards = 0 },
	solar_gold = { Id = "solar_gold", Name = "Hoàng Kim Thái Dương - Solar Gold", Color = Color3.fromRGB(255, 206, 68), CostShards = 150 },
	cryo_cyan = { Id = "cryo_cyan", Name = "Hàn Băng Cực Quang - Cryo Cyan", Color = Color3.fromRGB(72, 232, 255), CostShards = 150 },
	void_violet = { Id = "void_violet", Name = "Tử Tinh Hư Không - Void Violet", Color = Color3.fromRGB(178, 84, 255), CostShards = 250 },
	emerald_jade = { Id = "emerald_jade", Name = "Ngọc Bích Long Khí - Emerald Jade", Color = Color3.fromRGB(62, 240, 152), CostShards = 200 },
	sakura_pink = { Id = "sakura_pink", Name = "Anh Đào Huyễn Ảnh - Sakura Pink", Color = Color3.fromRGB(255, 132, 208), CostShards = 200 },
	electric_cobalt = { Id = "electric_cobalt", Name = "Lôi Lam Thiên Kích - Electric Cobalt", Color = Color3.fromRGB(58, 138, 255), CostShards = 250 },
	pure_white = { Id = "pure_white", Name = "Bạch Quang Thần Thánh - Pure White", Color = Color3.fromRGB(245, 250, 255), CostShards = 350 },
}

CombatData.KenV2UnlockDodgesEXP = 50

-- ============================================================================
-- 7. BOUNTY / HONOR (0..30M) (#56, #57) & 34 GLOWING OVERHEAD TITLES (#58)
-- ============================================================================
CombatData.MaxBounty = 30000000
CombatData.SeaBeastSummonBounty = 10000000
CombatData.SeaBeastDuration = 35
CombatData.SeaBeastBeamInterval = 3.5
CombatData.SeaBeastBeamAtkMultiplier = 3.80

function CombatData.GetBountyBuffPct(bounty)
	local b = math.clamp(tonumber(bounty) or 0, 0, CombatData.MaxBounty)
	local steps = math.clamp(math.floor(b / 1500000), 0, 20)
	return steps * 0.01 -- +1% ATK & +1% DEF per 1.5M up to +20% ATK & +20% DEF at 30M
end

CombatData.TitleOrder = {
	"sky_rookie",
	"cloud_strider",
	"aureon_slayer",
	"cyber_vanguard",
	"cryon_breaker",
	"shadow_walker",
	"void_emperor",
	"apex_creator",
	"golden_sword_saint",
	"cursed_dual_master",
	"abyssal_blade_lord",
	"six_realms_godfist",
	"jade_dragon_sifu",
	"thunder_talon_flash",
	"ashura_sun_fist",
	"soul_virtuoso",
	"subzero_marksman",
	"sea_king_slayer",
	"awakened_ascendant",
	"sovereign_dragon_king",
	"dimensional_traveler",
	"mirage_tycoon",
	"cafe_broker",
	"iron_buso_master",
	"conqueror_overdrive",
	"all_seeing_oracle",
	"core_gear_awakened",
	"star_forger",
	"rising_hunter_1m",
	"sky_warlord_5m",
	"seabeast_caller_10m",
	"yonko_sky_20m",
	"celestial_supremacy_30m",
	"grand_master_600",
	"spire_challenger",
	"spire_ascendant",
	"sky_spire_sovereign",
	"apex_of_the_spire",
	"leviathan_slayer",
	"sky_vanguard",
	"golden_conqueror",
	"cyber_overlord",
	"skybreak_sovereign",
	"awakened_core",
	"starforged_master",
	"arcane_enchanter",
	"forge_grandmaster",
	"warlord_of_clouds",
	"emperor_of_the_sky",
	"skyborn_scholar",
	"core_archivist",
	"omniscient_chronicler",
	"lore_seeker",
	"chronicler_of_aether",
	"fleet_commander",
	"haki_grandmaster",
}

CombatData.Titles = {
	sky_rookie = { Id = "sky_rookie", Name = "Tân Binh Bầu Trời", Color = Color3.fromRGB(165, 225, 255), Desc = "Khởi đầu hành trình trên đại hải trình bầu trời." },
	cloud_strider = { Id = "cloud_strider", Name = "Kẻ Lướt Mây Trắng", Color = Color3.fromRGB(125, 235, 255), MinLevel = 120, Desc = "Đạt cấp độ Lv. 120." },
	aureon_slayer = { Id = "aureon_slayer", Name = "Người Phá Tháp Ánh Sáng", Color = Color3.fromRGB(255, 214, 92), MinLevel = 700, BossClear = "AureonSentinel", Desc = "Chinh phục Aureon Sentinel hoặc đạt Lv. 700." },
	cyber_vanguard = { Id = "cyber_vanguard", Name = "Tiên Phong Băng Thành", Color = Color3.fromRGB(102, 240, 255), WorldReq = "FrozenCyber", Desc = "Đặt chân tới Sea 2 - Frozen Cyber." },
	cryon_breaker = { Id = "cryon_breaker", Name = "Kẻ Nghiền Băng Vĩnh Cửu", Color = Color3.fromRGB(85, 210, 255), MinLevel = 1500, BossClear = "CryonPrime", Desc = "Chinh phục Cryon Prime hoặc đạt Lv. 1500." },
	shadow_walker = { Id = "shadow_walker", Name = "Hành Giả Bóng Đêm", Color = Color3.fromRGB(190, 120, 255), WorldReq = "ShadowRealm", Desc = "Bước vào Sea 3 - Shadow Realm." },
	void_emperor = { Id = "void_emperor", Name = "Đế Vương Hư Không", Color = Color3.fromRGB(196, 84, 255), MinLevel = 2200, BossClear = "Noxar", Desc = "Đánh bại Noxar - The Void Sovereign." },
	apex_creator = { Id = "apex_creator", Name = "Đỉnh Cao Sáng Thế", Color = Color3.fromRGB(255, 240, 165), MinLevel = 2550, BossClear = "Veyr", Desc = "Đạt MAX LEVEL 2550 hoặc đánh bại Veyr." },
	golden_sword_saint = { Id = "golden_sword_saint", Name = "Kiếm Thánh Hoàng Kim", Color = Color3.fromRGB(255, 208, 72), ItemOwned = "saber_of_aureon", Desc = "Sở hữu Đại Kiếm Thánh Quang hoặc Kiếm Thuật tinh thông." },
	cursed_dual_master = { Id = "cursed_dual_master", Name = "Song Kiếm Tuyệt Thế", Color = Color3.fromRGB(255, 110, 195), ItemOwned = "cursed_dual_skyblades", Desc = "Sở hữu Cursed Dual Skyblades (CDK)." },
	abyssal_blade_lord = { Id = "abyssal_blade_lord", Name = "Hắc Kiếm Bá Chủ", Color = Color3.fromRGB(178, 92, 255), ItemOwned = "noxar_abyssal_greatsword", Desc = "Sở hữu Noxar's Abyssal Greatsword." },
	six_realms_godfist = { Id = "six_realms_godfist", Name = "Thần Quyền Lục Giới", Color = Color3.fromRGB(255, 232, 130), StyleReq = "celestial_godhuman", Desc = "Lĩnh ngộ Thiên Thần Tuyệt Kỹ - Celestial Godhuman." },
	jade_dragon_sifu = { Id = "jade_dragon_sifu", Name = "Long Quyền Tông Sư", Color = Color3.fromRGB(64, 245, 168), StyleReq = "jade_dragon", Desc = "Lĩnh ngộ Long Quyền Ngọc Bích." },
	thunder_talon_flash = { Id = "thunder_talon_flash", Name = "Lôi Trảo Nhất Thiểm", Color = Color3.fromRGB(92, 198, 255), StyleReq = "thunder_talon", Desc = "Lĩnh ngộ Lôi Trảo Cước." },
	ashura_sun_fist = { Id = "ashura_sun_fist", Name = "Tu La Thái Dương", Color = Color3.fromRGB(255, 132, 48), StyleReq = "solar_ashura", Desc = "Lĩnh ngộ Thái Dương Tu La Quyền." },
	soul_virtuoso = { Id = "soul_virtuoso", Name = "Nhạc Sĩ Hư Không", Color = Color3.fromRGB(205, 112, 255), ItemOwned = "soul_guitar_void", Desc = "Sở hữu Soul Guitar of the Void." },
	subzero_marksman = { Id = "subzero_marksman", Name = "Xạ Thủ Tuyệt Độ", Color = Color3.fromRGB(95, 242, 255), ItemOwned = "cryo_railgun", Desc = "Sở hữu Cryo Railgun." },
	sea_king_slayer = { Id = "sea_king_slayer", Name = "Kẻ Diệt Hải Vương", Color = Color3.fromRGB(68, 215, 255), Desc = "Hạ gục Sky Sea Beast hoặc Abyssal Leviathan." },
	awakened_ascendant = { Id = "awakened_ascendant", Name = "Chân Thân Thức Tỉnh", Color = Color3.fromRGB(255, 155, 72), Desc = "Thức tỉnh V2 bất kỳ Trái Ác Quỷ nào." },
	sovereign_dragon_king = { Id = "sovereign_dragon_king", Name = "Hoàng Long Cửu Thiên", Color = Color3.fromRGB(215, 92, 255), Desc = "Hóa Hoàng Long Khổng Lồ ở 100% Nộ Khí." },
	dimensional_traveler = { Id = "dimensional_traveler", Name = "Lữ Khách Xuyên Không", Color = Color3.fromRGB(120, 185, 255), Desc = "Khai mở Cổng Không Gian dịch chuyển liên đảo." },
	mirage_tycoon = { Id = "mirage_tycoon", Name = "Đại Thương Gia Ảo Ảnh", Color = Color3.fromRGB(255, 215, 108), Desc = "Mua Trái Ác Quỷ trực tiếp từ Mirage Fruit Dealer." },
	cafe_broker = { Id = "cafe_broker", Name = "Nhà Môi Giới Trái Ác Quỷ", Color = Color3.fromRGB(132, 245, 195), Desc = "Hoàn tất giao dịch Trái Ác Quỷ tại Cyberport Cafe." },
	iron_buso_master = { Id = "iron_buso_master", Name = "Thiết Giáp Bá Khí", Color = Color3.fromRGB(255, 92, 108), MinHakiStage = 4, Desc = "Đạt Busoshoku Haki Stage 4 (Full Body)." },
	conqueror_overdrive = { Id = "conqueror_overdrive", Name = "Bá Vương Tuyệt Đỉnh", Color = Color3.fromRGB(255, 52, 78), MinHakiStage = 5, Desc = "Đạt Busoshoku Haki Stage 5 (Sovereign Overdrive)." },
	all_seeing_oracle = { Id = "all_seeing_oracle", Name = "Thiên Nhãn Thấu Thị", Color = Color3.fromRGB(135, 232, 255), KenV2Req = true, Desc = "Khai mở Kenbunshoku Haki V2." },
	core_gear_awakened = { Id = "core_gear_awakened", Name = "Huyết Mạch Thức Tỉnh V4", Color = Color3.fromRGB(255, 196, 84), RaceV4Req = true, Desc = "Vượt qua Thử Thách Cổ Đại mở khóa Tộc V4." },
	star_forger = { Id = "star_forger", Name = "Thần Thợ Rèn Tinh Tú", Color = Color3.fromRGB(255, 224, 98), MaxStarReq = 5, Desc = "Thăng hoa bất kỳ thần khí nào lên 5 Sao." },
	rising_hunter_1m = { Id = "rising_hunter_1m", Name = "Thợ Săn Tân Tinh 1M", Color = Color3.fromRGB(145, 228, 255), MinBounty = 1000000, Desc = "Đạt 1,000,000 Bounty." },
	sky_warlord_5m = { Id = "sky_warlord_5m", Name = "Thất Vũ Hải Bầu Trời 5M", Color = Color3.fromRGB(120, 245, 185), MinBounty = 5000000, Desc = "Đạt 5,000,000 Bounty." },
	seabeast_caller_10m = { Id = "seabeast_caller_10m", Name = "Bá Vương Chiến Hải 10M", Color = Color3.fromRGB(72, 215, 255), MinBounty = 10000000, Desc = "Đạt 10,000,000 Bounty & mở khóa Triệu Hồi Hải Vương." },
	yonko_sky_20m = { Id = "yonko_sky_20m", Name = "Tứ Hoàng Thượng Giới 20M", Color = Color3.fromRGB(255, 148, 64), MinBounty = 20000000, Desc = "Đạt 20,000,000 Bounty." },
	celestial_supremacy_30m = { Id = "celestial_supremacy_30m", Name = "Độc Tôn Thiên Giới 30M", Color = Color3.fromRGB(255, 78, 125), MinBounty = 30000000, Desc = "Đạt đỉnh phong 30,000,000 Bounty." },
	grand_master_600 = { Id = "grand_master_600", Name = "Đại Tông Sư Thông Thạo", Color = Color3.fromRGB(255, 236, 145), Desc = "Đạt Mastery Lv. 600 trên bất kỳ vũ khí hoặc trái nào." },
	spire_challenger = { Id = "spire_challenger", Name = "Kẻ Thách Đấu Tháp Vô Tận", Color = Color3.fromRGB(130, 226, 255), Desc = "Chinh phục Tầng 10 Tháp Vô Tận Sky Spire." },
	spire_ascendant = { Id = "spire_ascendant", Name = "Bậc Thăng Thiên Tháp Vô Tận", Color = Color3.fromRGB(196, 138, 255), Desc = "Chinh phục Tầng 25 Tháp Vô Tận Sky Spire." },
	sky_spire_sovereign = { Id = "sky_spire_sovereign", Name = "Độc Tôn Đỉnh Tháp Vô Tận", Color = Color3.fromRGB(255, 214, 88), Desc = "Chinh phục đỉnh Tầng 50/50 Endless Sky Spire." },
	apex_of_the_spire = { Id = "apex_of_the_spire", Name = "Thiên Đỉnh Vô Cực", Color = Color3.fromRGB(255, 226, 118), Desc = "Đạt thành tựu Tầng 50 Tháp Vô Tận Sky Spire." },
	leviathan_slayer = { Id = "leviathan_slayer", Name = "Thợ Săn Thủy Tổ Leviathan", Color = Color3.fromRGB(72, 238, 255), Desc = "Kéo thành công Tim Thủy Tổ Leviathan về Cảng Sky Shipwright." },
	sky_vanguard = { Id = "sky_vanguard", Name = "Tiên Phong Thiên Không", Color = Color3.fromRGB(142, 228, 255), MinLevel = 100, Desc = "Đạt cột mốc Cấp 100." },
	golden_conqueror = { Id = "golden_conqueror", Name = "Chinh Phục Tầng Mây Vàng", Color = Color3.fromRGB(255, 212, 92), MinLevel = 700, Desc = "Đạt cột mốc Cấp 700." },
	cyber_overlord = { Id = "cyber_overlord", Name = "Bá Chủ Băng Giá Cyber", Color = Color3.fromRGB(96, 238, 255), MinLevel = 1500, Desc = "Đạt cột mốc Cấp 1500." },
	skybreak_sovereign = { Id = "skybreak_sovereign", Name = "Chúa Tể Thiên Giới Skybreak", Color = Color3.fromRGB(255, 238, 152), MinLevel = 2550, Desc = "Đạt đỉnh cao tối thượng Cấp 2550." },
	awakened_core = { Id = "awakened_core", Name = "Lõi Aether Thức Tỉnh", Color = Color3.fromRGB(255, 162, 84), Desc = "Hoàn thành thành tựu Thức Tỉnh Trái Aether V2 đầu tiên." },
	starforged_master = { Id = "starforged_master", Name = "Chủ Nhân Thần Binh Ngũ Tinh", Color = Color3.fromRGB(255, 222, 96), MaxStarReq = 5, Desc = "Sở hữu vũ khí Thăng Hoa 5 Sao." },
	arcane_enchanter = { Id = "arcane_enchanter", Name = "Nghệ Nhân Phù Phép Cổ Ngữ", Color = Color3.fromRGB(186, 124, 255), Desc = "Khắc phù phép Enchant lên vũ khí lần đầu." },
	forge_grandmaster = { Id = "forge_grandmaster", Name = "Tuyệt Đỉnh Thần Rèn (+15)", Color = Color3.fromRGB(255, 194, 78), Desc = "Cường hóa thần binh chạm mốc +15." },
	warlord_of_clouds = { Id = "warlord_of_clouds", Name = "Danh Vọng Thiên Hà 3M", Color = Color3.fromRGB(132, 242, 198), MinBounty = 3000000, Desc = "Đạt thành tựu 3,000,000 Bounty / Honor." },
	emperor_of_the_sky = { Id = "emperor_of_the_sky", Name = "Tứ Hoàng Biển Mây 10M", Color = Color3.fromRGB(255, 138, 72), MinBounty = 10000000, Desc = "Đạt thành tựu 10,000,000 Bounty / Honor." },
	skyborn_scholar = { Id = "skyborn_scholar", Name = "Học Giả Thiên Không", Color = Color3.fromRGB(146, 224, 255), Desc = "Thu thập 10/30 Bia Cổ Lore Skybreak." },
	core_archivist = { Id = "core_archivist", Name = "Sử Quan Mảnh Lõi", Color = Color3.fromRGB(196, 148, 255), Desc = "Thu thập 20/30 Bia Cổ Lore Skybreak." },
	omniscient_chronicler = { Id = "omniscient_chronicler", Name = "Đại Học Giả Toàn Tri", Color = Color3.fromRGB(255, 228, 112), Desc = "Giải mã trọn bộ 30/30 Bia Cổ Lore Skybreak." },
	lore_seeker = { Id = "lore_seeker", Name = "Người Tầm Cổ Ngữ", Color = Color3.fromRGB(152, 232, 255), Desc = "Đạt thành tựu thu thập 10 Bia Cổ Ngữ." },
	chronicler_of_aether = { Id = "chronicler_of_aether", Name = "Hiền Triết Lõi Sáng Thế", Color = Color3.fromRGB(255, 234, 136), Desc = "Đạt thành tựu trọn bộ 30 Bia Cổ Ngữ." },
	fleet_commander = { Id = "fleet_commander", Name = "Thuyền Trưởng Hạm Đội Sky Crew", Color = Color3.fromRGB(112, 218, 255), Desc = "Thành lập hoặc gia nhập Hạm Đội Sky Crew." },
	haki_grandmaster = { Id = "haki_grandmaster", Name = "Tông Sư Bá Khí Vũ Trang", Color = Color3.fromRGB(255, 76, 98), MinHakiStage = 5, Desc = "Đạt thành tựu Bá Khí Vũ Trang Toàn Thân (Stage 5)." },
}

-- ============================================================================
-- 8. GIFTCODES (#100) & STAR ASCENSION TIERS (#104)
-- ============================================================================
CombatData.Giftcodes = {
	SKYBREAK2026 = {
		Code = "SKYBREAK2026",
		Gold = 25000,
		DoubleExpSeconds = 900,
		Desc = "+25,000 Gold & 15 Phút x2 EXP",
	},
	AETHERV2 = {
		Code = "AETHERV2",
		CoreShards = 150,
		Desc = "+150 Core Shards",
	},
	MYTHICFRUIT = {
		Code = "MYTHICFRUIT",
		StoredFruit = "AbyssalSovereignCore",
		AltStoredFruit = "SolarTitanCore",
		FreeFruitVouchers = 1,
		Desc = "+1 Trái Thần Thoại Lưu Kho",
	},
	FREESTAT = {
		Code = "FREESTAT",
		FreeStatRefund = true,
		StatRefundTokens = 1,
		Desc = "Hoàn Toàn Bộ Điểm Chỉ Số Miễn Phí",
	},
}

CombatData.StarAscension = {
	[1] = { Star = 1, Gold = 1500, Shards = 25, Rate = 1.00, CritRateBonus = 3, SkillDmgPct = 0.06, AtkPct = 0.06, PityGain = 35 },
	[2] = { Star = 2, Gold = 3500, Shards = 60, Rate = 0.85, CritRateBonus = 6, SkillDmgPct = 0.12, AtkPct = 0.13, PityGain = 35 },
	[3] = { Star = 3, Gold = 7500, Shards = 120, Rate = 0.65, CritRateBonus = 10, SkillDmgPct = 0.20, AtkPct = 0.22, PityGain = 40 },
	[4] = { Star = 4, Gold = 15000, Shards = 220, Rate = 0.45, CritRateBonus = 15, SkillDmgPct = 0.30, AtkPct = 0.33, PityGain = 50 },
	[5] = { Star = 5, Gold = 30000, Shards = 400, Rate = 0.30, CritRateBonus = 22, SkillDmgPct = 0.45, AtkPct = 0.48, PityGain = 55 },
}

return CombatData
