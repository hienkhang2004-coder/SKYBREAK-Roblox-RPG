-- SKYBREAK: Fragments of the Core — Modular Server Combat, Progression, Aiming & NPC Experience Helpers
-- Location: ServerScriptService/Services/GameExperienceHelpers.lua

local Helpers = {}

local _V3 = Vector3.new
local _CF = CFrame.new
local _lookAt = CFrame.lookAt

local MAX_PITCH_RAD = math.rad(75)
local MAX_SIN_PITCH = math.sin(MAX_PITCH_RAD)
local MIN_COS_PITCH = math.cos(MAX_PITCH_RAD)

-- Rule 3: Full 12 Canonical + Legacy Alias Devil Fruit Lookup
Helpers.CANONICAL_FRUIT_MAP = {
	galecore = "GaleCore", gale = "GaleCore", wind = "GaleCore",
	sandstonecore = "SandstoneCore", sandstone = "SandstoneCore", smoke = "SandstoneCore", sand = "SandstoneCore",
	solarflamecore = "SolarFlameCore", solarflame = "SolarFlameCore", flame = "SolarFlameCore", fire = "SolarFlameCore",
	glaciericecore = "GlacierIceCore", glacierice = "GlacierIceCore", ice = "GlacierIceCore", frost = "GlacierIceCore",
	thunderrumblecore = "ThunderRumbleCore", thunderrumble = "ThunderRumbleCore", rumble = "ThunderRumbleCore", thunder = "ThunderRumbleCore",
	celestiallightcore = "CelestialLightCore", celestiallight = "CelestialLightCore", light = "CelestialLightCore",
	starforgedmagmacore = "StarforgedMagmaCore", starforgedmagma = "StarforgedMagmaCore", magma = "StarforgedMagmaCore",
	astralgravitycore = "AstralGravityCore", astralgravity = "AstralGravityCore", gravity = "AstralGravityCore",
	dimensionalportalcore = "DimensionalPortalCore", dimensionalportal = "DimensionalPortalCore", portal = "DimensionalPortalCore",
	solartitancore = "SolarTitanCore", solartitan = "SolarTitanCore", buddha = "SolarTitanCore", quake = "SolarTitanCore", starlightquakecore = "SolarTitanCore",
	aetherflowcore = "AetherflowCore", aetherflow = "AetherflowCore", sweetdoughcore = "AetherflowCore", dough = "AetherflowCore", mochi = "AetherflowCore",
	abyssalsovereigncore = "AbyssalSovereignCore", dragon = "AbyssalSovereignCore", abyssal_dragon = "AbyssalSovereignCore", void_dragon = "AbyssalSovereignCore",
}

-- Rule 2: Explicit Whitelist of 6 True Flight Fruits (plus AbyssalSovereignCore at Form 2 only)
Helpers.TRUE_FLIGHT_FRUITS = {
	GaleCore = true, Gale = true,
	SandstoneCore = true, Smoke = true,
	SolarFlameCore = true, Flame = true,
	CelestialLightCore = true, Light = true,
	StarforgedMagmaCore = true, Magma = true,
	AstralGravityCore = true, Gravity = true,
}

Helpers.GACHA_FRUIT_WEIGHTS = {
	{ Id = "GaleCore", Weight = 320 },
	{ Id = "SandstoneCore", Weight = 290 },
	{ Id = "SolarFlameCore", Weight = 90 },
	{ Id = "GlacierIceCore", Weight = 90 },
	{ Id = "CelestialLightCore", Weight = 60 },
	{ Id = "ThunderRumbleCore", Weight = 60 },
	{ Id = "StarforgedMagmaCore", Weight = 22 },
	{ Id = "AstralGravityCore", Weight = 22 },
	{ Id = "DimensionalPortalCore", Weight = 22 },
	{ Id = "SolarTitanCore", Weight = 8 },
	{ Id = "AetherflowCore", Weight = 8 },
	{ Id = "AbyssalSovereignCore", Weight = 8 },
}

function Helpers.ResolveFruitId(rawId)
	if type(rawId) ~= "string" or rawId == "" or rawId == "None" then
		return ""
	end
	local head = rawId:match("^([^|]+)") or rawId
	return Helpers.CANONICAL_FRUIT_MAP[string.lower(head)] or ""
end

local function isFiniteV3(v)
	return typeof(v) == "Vector3"
		and v.X == v.X and v.Y == v.Y and v.Z == v.Z
		and math.abs(v.X) < 1e6 and math.abs(v.Y) < 1e6 and math.abs(v.Z) < 1e6
end

local function clampPitchUnit(rawDir, fallbackLook)
	local dir = rawDir
	if not isFiniteV3(dir) or dir.Magnitude < 0.001 then
		dir = isFiniteV3(fallbackLook) and fallbackLook.Magnitude > 0.001 and fallbackLook.Unit or _V3(0, 0, -1)
	else
		dir = dir.Unit
	end
	if math.abs(dir.Y) > MAX_SIN_PITCH then
		local signY = (dir.Y >= 0) and 1 or -1
		local hx, hz = dir.X, dir.Z
		local hLen = math.sqrt(hx * hx + hz * hz)
		if hLen < 1e-4 then
			local fb = isFiniteV3(fallbackLook) and fallbackLook or _V3(0, 0, -1)
			local fh = math.sqrt(fb.X * fb.X + fb.Z * fb.Z)
			if fh > 1e-4 then
				hx, hz, hLen = fb.X, fb.Z, fh
			else
				hx, hz, hLen = 0, -1, 1
			end
		end
		local scaleH = MIN_COS_PITCH / hLen
		dir = _V3(hx * scaleH, signY * MAX_SIN_PITCH, hz * scaleH).Unit
	end
	return dir
end

function Helpers.Resolve3DAimDirection(hrp, payload)
	local fallbackLook = (hrp and hrp.CFrame.LookVector) or _V3(0, 0, -1)
	local baseOrigin = (hrp and (hrp.Position + _V3(0, 1.4, 0))) or _V3(0, 50, 0)
	if type(payload) ~= "table" then
		return clampPitchUnit(fallbackLook, fallbackLook), baseOrigin
	end

	local rawOrigin = payload.AimOrigin or payload.aimOrigin or payload.Origin or payload.origin
	local origin = baseOrigin
	if isFiniteV3(rawOrigin) and (rawOrigin - baseOrigin).Magnitude <= 18 then
		origin = rawOrigin
	end

	local rawDir = payload.AimDir or payload.aimDir or payload.Direction or payload.direction
	if isFiniteV3(rawDir) and rawDir.Magnitude > 0.05 then
		return clampPitchUnit(rawDir, fallbackLook), origin
	end

	local rawTarget = payload.TargetPos or payload.targetPos or payload.HitPos or payload.MousePos or payload.AimPos
	if isFiniteV3(rawTarget) then
		local delta = rawTarget - origin
		if delta.Magnitude > 0.25 then
			return clampPitchUnit(delta, fallbackLook), origin
		end
	end

	return clampPitchUnit(fallbackLook, fallbackLook), origin
end

function Helpers.Resolve3DAimRay(hrp, payload, maxRange)
	local lim = math.clamp(tonumber(maxRange) or 85, 8, 220)
	local dir, origin = Helpers.Resolve3DAimDirection(hrp, payload)
	local targetEnd = origin + dir * lim
	if type(payload) == "table" then
		local rawTarget = payload.TargetPos or payload.targetPos or payload.HitPos or payload.MousePos or payload.AimPos
		if isFiniteV3(rawTarget) then
			local dist = (rawTarget - origin).Magnitude
			if dist >= 1.5 and dist <= lim then
				targetEnd = origin + dir * dist
			end
		end
	end
	return origin, dir, targetEnd
end

function Helpers.GetRaceTierMultipliers(C, raceTier)
	local tier = math.clamp(math.floor(tonumber(raceTier) or 1), 1, 4)
	local evoTbl = type(C) == "table" and type(C.RaceEvolution) == "table" and C.RaceEvolution or nil
	local tierSpec = evoTbl and (evoTbl[tier] or evoTbl["V" .. tostring(tier)]) or nil
	if type(tierSpec) == "table" then
		return tonumber(tierSpec.ATKMult) or ((tier == 2 and 1.06) or (tier >= 3 and 1.12) or 1.0),
			tonumber(tierSpec.DEFMult) or ((tier == 2 and 1.08) or (tier >= 3 and 1.15) or 1.0),
			tonumber(tierSpec.WalkSpeedMult) or ((tier == 2 and 1.08) or (tier >= 3 and 1.14) or 1.0)
	end
	if tier == 2 then
		return 1.06, 1.08, 1.08
	elseif tier >= 3 then
		return 1.12, 1.15, 1.14
	end
	return 1.0, 1.0, 1.0
end

local ARMOR_AND_ACCESSORY_SLOTS = { "Helmet", "Chest", "Gloves", "Boots", "Ring", "Necklace", "Artifact" }
local SLOT_DEDUP_GROUP = {
	Helmet = "Head", Helm = "Head",
	Chest = "Chest", Armor = "Chest",
	Gloves = "Hands", Gauntlets = "Hands",
	Boots = "Feet", Greaves = "Feet",
	Ring = "Ring",
	Necklace = "Necklace",
	Artifact = "Artifact",
}

function Helpers.ComputeStats(C, profile, slotOverride, p)
	local effSlot = math.clamp(math.floor(tonumber(slotOverride) or tonumber(profile.ActiveSlot) or 1), 1, 4)
	local lv = math.clamp(tonumber(profile.Level) or 1, 1, tonumber(C.MaxLevel) or 2550)
	local alloc = type(profile.StatAlloc) == "table" and profile.StatAlloc or {}

	local s = C.Stats(lv, profile.ClassId, alloc, effSlot)
	if type(s) ~= "table" then
		s = { HP = 100, DEF = 10, ATK = 20, CritRate = 5, CritDmg = 50, Break = 0 }
	end

	-- Fallback 5-branch stat completion if Config.Stats didn't populate all fields
	local meleePts = math.max(0, tonumber(alloc.Melee) or tonumber(alloc.STR) or 0)
	local defPts = math.max(0, tonumber(alloc.Defense) or tonumber(alloc.VIT) or 0)
	local swordPts = math.max(0, tonumber(alloc.Sword) or tonumber(alloc.DEX) or 0)
	local gunPts = math.max(0, tonumber(alloc.Gun) or tonumber(alloc.INT) or 0)
	local fruitPts = math.max(0, tonumber(alloc.Fruit) or tonumber(alloc.LCK) or 0)

	if s.MaxEnergy == nil then
		s.MaxEnergy = math.floor(100 + meleePts * 0.45 + (lv - 1) * 0.04)
	end
	local baseBranch = math.max(12, math.floor(12 + 0.07 * (lv - 1)))
	if s.MeleeATK == nil then s.MeleeATK = math.floor(baseBranch + meleePts * 0.22) end
	if s.FruitATK == nil then s.FruitATK = math.floor(baseBranch + fruitPts * 0.22) end
	if s.SwordATK == nil then s.SwordATK = math.floor(baseBranch + swordPts * 0.22) end
	if s.GunATK == nil then s.GunATK = math.floor(baseBranch + gunPts * 0.22) end

	local eq = type(profile.Equipped) == "table" and profile.Equipped or {}
	local upgrades = type(profile.Upgrades) == "table" and profile.Upgrades or {}
	local baseEnhance = tonumber(profile.WeaponEnhance) or 0

	-- 1. Armor & Accessory bonuses apply to ALL slots (skip Gun items stored in Offhand/Necklace!)
	local seenGroup = {}
	local gearAtkAll, gearDefAll, gearHpAll, gearCritAll, gearCritDmgAll, gearBreakAll = 0, 0, 0, 0, 0, 0
	for _, slotName in ipairs(ARMOR_AND_ACCESSORY_SLOTS) do
		local grp = SLOT_DEDUP_GROUP[slotName] or slotName
		local itemId = eq[slotName]
		if not itemId and slotName == "Helmet" then itemId = eq.Helm end
		if not itemId and slotName == "Chest" then itemId = eq.Armor end
		if not itemId and slotName == "Gloves" then itemId = eq.Gauntlets end
		if not itemId and slotName == "Boots" then itemId = eq.Greaves end
		local item = itemId and C.Items and C.Items[itemId] or nil
		if item and not seenGroup[grp] then
			local itemSlot = tostring(item.Slot or item.CanonicalSlot or "")
			local isWeaponOrGun = (itemSlot == "Weapon" or itemSlot == "Sword" or itemSlot == "Gun" or item.WeaponType == "Gun" or item.WeaponType == "Sword")
			if not isWeaponOrGun then
				seenGroup[grp] = true
				gearAtkAll += (tonumber(item.ATK) or 0)
				gearDefAll += (tonumber(item.DEF) or 0)
				gearHpAll += (tonumber(item.HP) or 0)
				gearCritAll += (tonumber(item.CritRate) or 0)
				gearCritDmgAll += (tonumber(item.CritDmg) or 0)
				gearBreakAll += (tonumber(item.Break) or 0)
			end
		end
	end

	-- 2. Sword item bonus: adds to SwordATK, and ONLY adds to active s.ATK when effSlot == 3!
	local swordId = eq.Weapon or profile.Weapon
	local swordItem = swordId and C.Items and C.Items[swordId] or nil
	local swordItemAtk, swordCrit, swordCritDmg, swordBreak = 0, 0, 0, 0
	if swordItem and tostring(swordItem.Slot or "") ~= "Gun" and swordItem.WeaponType ~= "Gun" then
		local enh = math.max(baseEnhance, tonumber(upgrades[swordId]) or 0)
		swordItemAtk = math.floor((tonumber(swordItem.ATK) or 0) * (1 + 0.06 * enh))
		swordCrit = tonumber(swordItem.CritRate) or 0
		swordCritDmg = tonumber(swordItem.CritDmg) or 0
		swordBreak = tonumber(swordItem.Break) or 0
		-- Non-offensive defensive stats on sword if any: only when holding slot 3
	end

	-- 3. Gun item bonus: adds to GunATK, and ONLY adds to active s.ATK when effSlot == 4!
	local gunId = eq.Gun or profile.EquippedGun or eq.Offhand
	local gunItem = gunId and C.Items and C.Items[gunId] or nil
	local gunItemAtk, gunCrit, gunCritDmg, gunBreak = 0, 0, 0, 0
	if gunItem and (tostring(gunItem.Slot or "") == "Gun" or gunItem.WeaponType == "Gun" or (C.Guns and C.Guns[gunId] ~= nil)) then
		local enh = math.max(baseEnhance, tonumber(upgrades[gunId]) or 0)
		gunItemAtk = math.floor((tonumber(gunItem.ATK) or 0) * (1 + 0.06 * enh))
		gunCrit = tonumber(gunItem.CritRate) or 0
		gunCritDmg = tonumber(gunItem.CritDmg) or 0
		gunBreak = tonumber(gunItem.Break) or 0
	end

	s.MeleeATK = math.floor((tonumber(s.MeleeATK) or baseBranch) + gearAtkAll)
	s.FruitATK = math.floor((tonumber(s.FruitATK) or baseBranch) + gearAtkAll)
	s.SwordATK = math.floor((tonumber(s.SwordATK) or baseBranch) + gearAtkAll + swordItemAtk)
	s.GunATK = math.floor((tonumber(s.GunATK) or baseBranch) + gearAtkAll + gunItemAtk)

	-- Active slot ATK selection without cross-slot weapon bleed
	if effSlot == 1 then
		s.ATK = s.MeleeATK
	elseif effSlot == 2 then
		s.ATK = s.FruitATK
	elseif effSlot == 3 then
		s.ATK = s.SwordATK
		gearCritAll += swordCrit
		gearCritDmgAll += swordCritDmg
		gearBreakAll += swordBreak
	elseif effSlot == 4 then
		s.ATK = s.GunATK
		gearCritAll += gunCrit
		gearCritDmgAll += gunCritDmg
		gearBreakAll += gunBreak
	end

	s.DEF = math.floor((tonumber(s.DEF) or 10) + gearDefAll)
	s.HP = math.floor((tonumber(s.HP) or 100) + gearHpAll)
	s.CritRate = (tonumber(s.CritRate) or 5) + gearCritAll
	s.CritDmg = (tonumber(s.CritDmg) or 50) + gearCritDmgAll
	s.Break = (tonumber(s.Break) or 0) + gearBreakAll

	-- Busoshoku Haki (Aura)
	local auraOn = (profile.Haki and (profile.Haki.Aura == true or profile.Haki.AuraActive == true))
		or (p and p.Character and p.Character:GetAttribute("HakiAura") == true)
	if auraOn then
		local stage = math.clamp(tonumber(profile.HakiStage) or tonumber(profile.Haki and profile.Haki.AuraStage) or 1, 1, 5)
		local auraAtkMult = 1 + 0.14 + stage * 0.02
		s.ATK = math.floor(s.ATK * auraAtkMult)
		s.MeleeATK = math.floor(s.MeleeATK * auraAtkMult)
		s.FruitATK = math.floor(s.FruitATK * auraAtkMult)
		s.SwordATK = math.floor(s.SwordATK * auraAtkMult)
		s.GunATK = math.floor(s.GunATK * auraAtkMult)
		s.DEF = math.floor(s.DEF * 1.15)
	end

	-- Race Tier V2 / V3 Passive Multipliers (+6%/+8% on V2, +12%/+15% on V3) & RaceV4Active (+30% ATK/HP/DEF)
	local raceTier = math.clamp(tonumber(profile.RaceTier) or (profile.RaceV4Unlocked and 4 or 1), 1, 4)
	local rAtkMult, rDefMult, rSpdMult = Helpers.GetRaceTierMultipliers(C, raceTier)
	if rAtkMult > 1.0 then
		s.ATK = math.floor(s.ATK * rAtkMult)
		s.MeleeATK = math.floor(s.MeleeATK * rAtkMult)
		s.FruitATK = math.floor(s.FruitATK * rAtkMult)
		s.SwordATK = math.floor(s.SwordATK * rAtkMult)
		s.GunATK = math.floor(s.GunATK * rAtkMult)
	end
	if rDefMult > 1.0 then
		s.DEF = math.floor(s.DEF * rDefMult)
	end
	s.RaceWalkSpeedMult = rSpdMult

	local rv4Attr = p and p.Character and p.Character:GetAttribute("RaceV4")
	if profile.RaceV4Active or (type(rv4Attr) == "string" and rv4Attr ~= "") then
		s.ATK = math.floor(s.ATK * 1.30)
		s.MeleeATK = math.floor(s.MeleeATK * 1.30)
		s.FruitATK = math.floor(s.FruitATK * 1.30)
		s.SwordATK = math.floor(s.SwordATK * 1.30)
		s.GunATK = math.floor(s.GunATK * 1.30)
		s.DEF = math.floor(s.DEF * 1.30)
		s.HP = math.floor(s.HP * 1.30)
	end

	local ftAttr = p and p.Character and p.Character:GetAttribute("FruitTransform")
	if type(ftAttr) == "string" and ftAttr ~= "" then
		s.DEF = math.floor(s.DEF * 1.80)
	end

	s.BestATK = math.max(s.MeleeATK or 0, s.FruitATK or 0, s.SwordATK or 0, s.GunATK or 0, s.ATK or 0)
	s.MaxEnergy = math.max(100, math.floor(tonumber(s.MaxEnergy) or 100))
	return s
end

-- ============================================================================
-- WEIGHTED GACHA & DYNAMIC COST
-- ============================================================================
function Helpers.GetGachaGoldCost(C, level)
	if type(C) == "table" then
		local fn = C.FruitGachaCost or C.GetGachaGoldCost
		if type(fn) == "function" then
			local ok, val = pcall(fn, level)
			if ok and tonumber(val) and tonumber(val) > 0 then
				return math.floor(tonumber(val))
			end
		end
	end
	return math.min(165000, 25000 + math.floor(math.max(0, (tonumber(level) or 1) - 1) * 55))
end

function Helpers.RollWeightedFruit(C)
	if type(C) == "table" and type(C.RollWeightedFruit) == "function" then
		local ok, fid = pcall(C.RollWeightedFruit)
		if ok and type(fid) == "string" and fid ~= "" then
			local canon = Helpers.ResolveFruitId(fid)
			return canon ~= "" and canon or fid
		end
	end
	local totalW = 0
	for _, entry in ipairs(Helpers.GACHA_FRUIT_WEIGHTS) do
		totalW += entry.Weight
	end
	local roll = math.random(1, totalW)
	local acc = 0
	for _, entry in ipairs(Helpers.GACHA_FRUIT_WEIGHTS) do
		acc += entry.Weight
		if roll <= acc then
			return entry.Id
		end
	end
	return "GaleCore"
end

function Helpers.GetMaxCoreStorage(p, profile)
	local plr = p
	local prof = profile
	if prof == nil and type(p) == "table" then
		local okAttr = pcall(function()
			return p:GetAttribute("OwnedPass_extra_core_storage")
		end)
		if not okAttr then
			prof = p
			plr = nil
		end
	end
	local ownsExtra = (type(prof) == "table" and type(prof.OwnedGamePasses) == "table" and prof.OwnedGamePasses.extra_core_storage == true)
		or (plr ~= nil and pcall(function() return plr:GetAttribute("OwnedPass_extra_core_storage") end) and plr:GetAttribute("OwnedPass_extra_core_storage") == true)
	return 1 + (ownsExtra and 3 or 0)
end

function Helpers.CanStoreCore(p, profile, fruitId)
	if type(profile) ~= "table" then
		return false, 0, 1
	end
	local canon = Helpers.ResolveFruitId(fruitId)
	local fid = (canon ~= "" and canon) or tostring(fruitId or "")
	if fid == "" then
		return false, 0, Helpers.GetMaxCoreStorage(p, profile)
	end
	local stored = type(profile.StoredFruits) == "table" and profile.StoredFruits or {}
	local cur = math.max(0, math.floor(tonumber(stored[fid]) or 0))
	local maxCap = Helpers.GetMaxCoreStorage(p, profile)
	return (cur < maxCap), cur, maxCap
end

local cachedLiveOps = nil
local function getLiveOps()
	if cachedLiveOps then
		return cachedLiveOps
	end
	if script and script.Parent and script.Parent.FindFirstChild then
		local mod = script.Parent:FindFirstChild("SkybreakLiveOpsService")
		if mod then
			local ok, svc = pcall(require, mod)
			if ok and type(svc) == "table" then
				cachedLiveOps = svc
				return svc
			end
		end
	end
	return nil
end

local MYTHIC_CORE_SET = {
	SolarTitanCore = true,
	AetherflowCore = true,
	AbyssalSovereignCore = true,
}

function Helpers.ExecuteRollFruit(p, profile, rt, G, C, currencyMode)
	if not p or not profile or not rt then
		return false
	end
	local liveOps = getLiveOps()
	local now = os.clock()
	local vouchers = math.max(0, math.floor(tonumber(profile.FreeFruitVouchers) or 0))
	local modeStr = tostring(currencyMode or "")
	local useShards = (modeStr == "Shards" or modeStr == "CoreShards")
	local useVoucher = (not useShards) and (vouchers > 0)

	local cdLeft = math.ceil((tonumber(rt.NextGachaRollAt) or 0) - now)
	if cdLeft > 0 and not rt.ZeroCooldowns and not useVoucher then
		if liveOps then
			liveOps.Notify(
				G,
				p,
				string.format("Đài Cầu Nguyện Zioles đang hồi năng lượng! Vui lòng chờ %ds.", cdLeft),
				string.format("Zioles' Shrine is recharging! Please wait %ds.", cdLeft)
			)
		else
			G.Notify(p, string.format("Đài Cầu Nguyện Zioles đang hồi năng lượng! Vui lòng chờ %ds.", cdLeft))
		end
		return false
	end

	local goldCost = Helpers.GetGachaGoldCost(C, profile.Level)
	local shardCost = (type(C) == "table" and tonumber(C.GachaCostShards)) or 200

	if useVoucher then
		profile.FreeFruitVouchers = vouchers - 1
	elseif useShards then
		if (tonumber(profile.CoreShards) or 0) < shardCost then
			if liveOps then
				liveOps.Notify(
					G,
					p,
					string.format("Cần %d Core Shards để cầu Lõi Aether tại Hiền Giả Zioles!", shardCost),
					string.format("Need %d Core Shards to roll an Aether Core at Zioles!", shardCost)
				)
			else
				G.Notify(p, string.format("Cần %d Core Shards để cầu Lõi Aether tại Hiền Giả Zioles!", shardCost))
			end
			return false
		end
		profile.CoreShards = (tonumber(profile.CoreShards) or 0) - shardCost
	else
		if (tonumber(profile.Gold) or 0) < goldCost then
			if liveOps then
				liveOps.Notify(
					G,
					p,
					string.format("Cần %d Vàng để cầu Lõi Aether (Lv.%d)!", goldCost, tonumber(profile.Level) or 1),
					string.format("Need %d Gold to roll an Aether Core (Lv.%d)!", goldCost, tonumber(profile.Level) or 1)
				)
			else
				G.Notify(p, string.format("Cần %d Gold để cầu Lõi Aether (Lv.%d)!", goldCost, tonumber(profile.Level) or 1))
			end
			return false
		end
		profile.Gold = (tonumber(profile.Gold) or 0) - goldCost
	end

	local cdSec = (type(C) == "table" and tonumber(C.FruitGachaCooldown)) or 60
	rt.NextGachaRollAt = now + cdSec
	pcall(function()
		p:SetAttribute("NextGachaRollAt", workspace:GetServerTimeNow() + cdSec)
	end)

	local pityMax = (type(C) == "table" and tonumber(C.FruitPityMax)) or 50
	local nextPity = math.clamp((tonumber(profile.FruitPity) or 0) + 1, 1, pityMax)
	local rolled
	local hitGuaranteedPity = false
	if nextPity >= pityMax then
		hitGuaranteedPity = true
		if type(C) == "table" and type(C.RollMythicFruit) == "function" then
			rolled = C.RollMythicFruit()
		else
			local mythics = { "SolarTitanCore", "AetherflowCore", "AbyssalSovereignCore" }
			rolled = mythics[math.random(1, #mythics)]
		end
	else
		rolled = Helpers.RollWeightedFruit(C)
	end
	local canonRolled = Helpers.ResolveFruitId(rolled)
	if canonRolled ~= "" then
		rolled = canonRolled
	end

	local fDef = (C.AetherFruits and C.AetherFruits[rolled]) or (C.Fruits and C.Fruits[rolled])
	local fRarity = tostring((fDef and fDef.Rarity) or "Rare")
	if hitGuaranteedPity or MYTHIC_CORE_SET[rolled] or fRarity == "Mythic" or fRarity == "Mythical" then
		profile.FruitPity = 0
	else
		profile.FruitPity = nextPity
	end

	profile.HeldFruit = rolled
	profile.StoredFruits = type(profile.StoredFruits) == "table" and profile.StoredFruits or {}
	local maxCap = Helpers.GetMaxCoreStorage(p, profile)
	local curStored = tonumber(profile.StoredFruits[rolled]) or 0
	local storedOk = false
	if curStored < maxCap then
		profile.StoredFruits[rolled] = curStored + 1
		curStored += 1
		storedOk = true
		if rt then rt.HeldAlreadyStored = true end
	else
		if rt then rt.HeldAlreadyStored = false end
	end
	if not profile.EquippedFruit or profile.EquippedFruit == "" then
		profile.EquippedFruit = rolled
		profile.ActiveSlot = 2
	end
	pcall(function()
		p:SetAttribute("FruitPity", profile.FruitPity)
		p:SetAttribute("FreeFruitVouchers", profile.FreeFruitVouchers or 0)
		p:SetAttribute("HeldFruit", rolled)
		p:SetAttribute("EquippedFruit", profile.EquippedFruit or "")
		if p.Character then
			p.Character:SetAttribute("HeldFruit", rolled)
			p.Character:SetAttribute("EquippedFruit", profile.EquippedFruit or "")
		end
	end)

	if liveOps and liveOps.AwardBadge then
		liveOps.AwardBadge(G, p, profile, "first_aether_core")
	end

	local fName = (fDef and fDef.Name) or rolled
	local tagVi = useVoucher and "[VÉ MIỄN PHÍ] " or ""
	local tagEn = useVoucher and "[FREE VOUCHER] " or ""
	if storedOk then
		local vi = string.format("%s[ZIOLES] Cầu trúng [%s] (%s)! Đã lưu Kho Lõi (%d/%d) • Bảo Hiểm: %d/%d.", tagVi, fName, fRarity, curStored, maxCap, profile.FruitPity, pityMax)
		local en = string.format("%s[ZIOLES] Rolled [%s] (%s)! Stored (%d/%d) • Pity: %d/%d.", tagEn, fName, fRarity, curStored, maxCap, profile.FruitPity, pityMax)
		if liveOps then liveOps.Notify(G, p, vi, en) else G.Notify(p, vi) end
	else
		local vi = string.format("%s[ZIOLES] Cầu trúng [%s] (%s)! Kho Lõi đã đầy (%d/%d) — Lõi đang cầm trên tay! (Bảo Hiểm: %d/%d)", tagVi, fName, fRarity, curStored, maxCap, profile.FruitPity, pityMax)
		local en = string.format("%s[ZIOLES] Rolled [%s] (%s)! Storage full (%d/%d) — Core held in hand! (Pity: %d/%d)", tagEn, fName, fRarity, curStored, maxCap, profile.FruitPity, pityMax)
		if liveOps then liveOps.Notify(G, p, vi, en) else G.Notify(p, vi) end
	end
	G.Sync(p)
	return true, rolled
end

-- ============================================================================
-- MARTIAL STYLE REQUIREMENTS & PROGRESSION
-- ============================================================================
Helpers.MARTIAL_PROGRESSION = {
	{
		Id = "skyborn_combat",
		Alias = "SkybornCombat",
		Name = "Võ Thuật Skyborn (Skyborn Combat)",
		MinLevel = 1,
		ReqMastery = 0,
		Gold = 0,
		Shards = 0,
	},
	{
		Id = "thunder_talon",
		Alias = "ElectricClaw",
		Name = "Lôi Trảo Cước (Electric Claw)",
		MinLevel = 300,
		ReqMastery = 0,
		Gold = 150000,
		Shards = 0,
	},
	{
		Id = "jade_dragon",
		Alias = "GlacialKarate",
		Name = "Băng Long Không Thủ (Glacial Karate)",
		MinLevel = 650,
		ReqMastery = 0,
		Gold = 400000,
		Shards = 0,
	},
	{
		Id = "solar_ashura",
		Alias = "DragonTalon",
		Name = "Long Trảo Tu La (Dragon Talon)",
		MinLevel = 1100,
		ReqMastery = 300,
		Gold = 1200000,
		Shards = 1000,
	},
	{
		Id = "celestial_godhuman",
		Alias = "GodhumanSkyborn",
		Name = "Thần Võ Skyborn (Godhuman Skyborn)",
		MinLevel = 1800,
		ReqMastery = 350,
		Gold = 3500000,
		Shards = 3000,
	},
	{
		Id = "SanguineVoidArt",
		Alias = "SanguineVoidArt",
		Name = "Huyết Hư Không Quyền (Sanguine Void Art)",
		MinLevel = 2200,
		ReqMastery = 400,
		Gold = 5000000,
		Shards = 5000,
	},
	{
		Id = "ChronoVoidPalm",
		Alias = "ChronoVoidPalm",
		Name = "Chưởng Pháp Thời Không (Chrono Void Palm)",
		MinLevel = 2450,
		ReqMastery = 400,
		Gold = 5000000,
		Shards = 5000,
	},
}

local MARTIAL_BY_ID = {}
for _, spec in ipairs(Helpers.MARTIAL_PROGRESSION) do
	MARTIAL_BY_ID[spec.Id] = spec
	MARTIAL_BY_ID[string.lower(spec.Id)] = spec
	MARTIAL_BY_ID[spec.Alias] = spec
	MARTIAL_BY_ID[string.lower(spec.Alias)] = spec
end

function Helpers.GetMartialReq(styleId)
	if type(styleId) ~= "string" then
		return MARTIAL_BY_ID.skyborn_combat
	end
	return MARTIAL_BY_ID[styleId] or MARTIAL_BY_ID[string.lower(styleId)]
end

function Helpers.GetBestMartialMastery(profile)
	local mTbl = type(profile and profile.Mastery) == "table" and profile.Mastery or {}
	local best = tonumber(mTbl.Melee) or 1
	for _, spec in ipairs(Helpers.MARTIAL_PROGRESSION) do
		local v = tonumber(mTbl[spec.Id]) or tonumber(mTbl[spec.Alias]) or 0
		if v > best then
			best = v
		end
	end
	return best
end

-- ============================================================================
-- ISLAND DISCOVERY & TELEPORT GATING (1:1 WITH Config.FastTravel & TravelService)
-- ============================================================================
local ISLAND_REALM_MIN_LEVEL = {
	-- Sea 1: GoldenSky (Lv. 1-700)
	SkyHub = { Realm = "GoldenSky", Sea = 1, MinLevel = 1, Name = "Đảo Khởi Đầu (Sky Hub)" },
	GoldenSky = { Realm = "GoldenSky", Sea = 1, MinLevel = 1, Name = "Bầu Trời Hoàng Kim (Golden Sky)" },
	ZiolesGachaShrine = { Realm = "GoldenSky", Sea = 1, MinLevel = 75, Name = "Điện Cầu Lõi (Core Shrine)" },
	AetherShrines = { Realm = "GoldenSky", Sea = 1, MinLevel = 150, Name = "Đài Điện Thờ Aether" },
	WestGarden = { Realm = "GoldenSky", Sea = 1, MinLevel = 250, Name = "Pháo Đài Vườn Tây (West Garden)" },
	LumenPlaza = { Realm = "GoldenSky", Sea = 1, MinLevel = 375, Name = "Quảng Trường Ánh Sáng (Lumen Plaza)" },
	SunshardSanctuary = { Realm = "GoldenSky", Sea = 1, MinLevel = 525, Name = "Thánh Địa Thái Dương (Sunshard Sanctuary)" },
	BossForecourt = { Realm = "GoldenSky", Sea = 1, MinLevel = 650, Name = "Tháp Phán Quyết Aureon" },
	-- Sea 2: FrozenCyber (Lv. 700-1500)
	FrozenCyber = { Realm = "FrozenCyber", Sea = 2, MinLevel = 700, Name = "Cảng Băng Giá (Frozen Cyber)" },
	CyberportCafe = { Realm = "FrozenCyber", Sea = 2, MinLevel = 850, Name = "Trạm Giao Thương (Cyberport Café)" },
	PermafrostGarrison = { Realm = "FrozenCyber", Sea = 2, MinLevel = 975, Name = "Pháo Đài Tuyết (Permafrost Garrison)" },
	MicrochipRaidLab = { Realm = "FrozenCyber", Sea = 2, MinLevel = 1150, Name = "Phòng Thí Nghiệm Đột Kích (Microchip Raid Lab)" },
	GlacialWreckage = { Realm = "FrozenCyber", Sea = 2, MinLevel = 1300, Name = "Xác Tàu Băng Cổ Đại (Glacial Wreckage)" },
	CryonArena = { Realm = "FrozenCyber", Sea = 2, MinLevel = 1425, Name = "Ngai Vàng Băng Đế (Cryon Citadel)" },
	-- Sea 3: ShadowRealm (Lv. 1500-2200)
	ShadowRealm = { Realm = "ShadowRealm", Sea = 3, MinLevel = 1500, Name = "Tiền Đồn Hư Không (Shadow Realm)" },
	CastleOnTheVoid = { Realm = "ShadowRealm", Sea = 3, MinLevel = 1650, Name = "Pháo Đài Hư Không (Void Bastion)" },
	UmbralSanctum = { Realm = "ShadowRealm", Sea = 3, MinLevel = 1775, Name = "Rừng Tinh Thể Đen (Umbral Sanctum)" },
	TempleOfTheCore = { Realm = "ShadowRealm", Sea = 3, MinLevel = 1900, Name = "Đền Thăng Hoa (Temple of the Core)" },
	LeviathanAbyss = { Realm = "ShadowRealm", Sea = 3, MinLevel = 2025, Name = "Đảo Hư Quang & Vực Thẳm Thủy Xà" },
	NoxarArena = { Realm = "ShadowRealm", Sea = 3, MinLevel = 2125, Name = "Ngai Vàng Hư Không Noxar" },
	-- Realms 4-8 (Lv. 2200-2550)
	VerdantCrown = { Realm = "VerdantCrown", Sea = 4, MinLevel = 2200, Name = "Vương Miện Cổ Thụ (Verdant Crown)" },
	VerdantWestBough = { Realm = "VerdantCrown", Sea = 4, MinLevel = 2215, Name = "Cánh Rừng Tây Cổ Thụ" },
	VerdantEastGrove = { Realm = "VerdantCrown", Sea = 4, MinLevel = 2235, Name = "Đảo Rừng Ngọc Bích" },
	VerdantNorthSpire = { Realm = "VerdantCrown", Sea = 4, MinLevel = 2250, Name = "Đỉnh Tháp Nhựa Aether" },
	EmberforgeWastes = { Realm = "EmberforgeWastes", Sea = 5, MinLevel = 2270, Name = "Hoang Mạc Lò Rèn Lửa" },
	EmberWestFoundry = { Realm = "EmberforgeWastes", Sea = 5, MinLevel = 2285, Name = "Xưởng Đúc Tây Hỏa" },
	EmberEastCaldera = { Realm = "EmberforgeWastes", Sea = 5, MinLevel = 2305, Name = "Miệng Núi Lửa Đông" },
	EmberNorthCitadel = { Realm = "EmberforgeWastes", Sea = 5, MinLevel = 2320, Name = "Pháo Đài Sao Nung" },
	AbyssalTides = { Realm = "AbyssalTides", Sea = 6, MinLevel = 2340, Name = "Thủy Triều Vực Sâu" },
	AbyssalWestReef = { Realm = "AbyssalTides", Sea = 6, MinLevel = 2355, Name = "Rạn San Hô Phát Quang" },
	AbyssalEastTrench = { Realm = "AbyssalTides", Sea = 6, MinLevel = 2375, Name = "Vực Hải Lưu Ngược" },
	AbyssalNorthSpire = { Realm = "AbyssalTides", Sea = 6, MinLevel = 2390, Name = "Cung Điện Thủy Triều" },
	ChronosBastion = { Realm = "ChronosBastion", Sea = 7, MinLevel = 2410, Name = "Pháo Đài Thời Gian (Chronos Bastion)" },
	ChronosWestDial = { Realm = "ChronosBastion", Sea = 7, MinLevel = 2425, Name = "Vòng Tinh Cầu Quá Khứ" },
	ChronosEastDial = { Realm = "ChronosBastion", Sea = 7, MinLevel = 2445, Name = "Vòng Tinh Cầu Tương Lai" },
	ChronosNorthSpire = { Realm = "ChronosBastion", Sea = 7, MinLevel = 2460, Name = "Tháp Niên Đại Vĩnh Hằng" },
	VeilsEnd = { Realm = "VeilsEnd", Sea = 8, MinLevel = 2480, Name = "Tận Cùng Bức Màn (The Veil's End)" },
	VeilsWestHorizon = { Realm = "VeilsEnd", Sea = 8, MinLevel = 2495, Name = "Chân Trời Sự Kiện Tây" },
	VeilsEastHorizon = { Realm = "VeilsEnd", Sea = 8, MinLevel = 2515, Name = "Tinh Vân Sụp Đổ Đông" },
	VeilsNorthThrone = { Realm = "VeilsEnd", Sea = 8, MinLevel = 2530, Name = "Ngai Vàng Đấng Kiến Tạo" },
}

local ISLAND_ALIAS_LOOKUP = {
	questcheckpoint = "GoldenSky",
	westgardenpiratebastion = "WestGarden",
	glacialdangersea = "GlacialWreckage",
	umbralcrystalforest = "UmbralSanctum",
	emberforgewestfoundry = "EmberWestFoundry",
	emberforgeeastcaldera = "EmberEastCaldera",
	emberforgenorthcitadel = "EmberNorthCitadel",
}
for k, v in pairs(ISLAND_REALM_MIN_LEVEL) do
	ISLAND_ALIAS_LOOKUP[string.lower(k)] = k
	ISLAND_ALIAS_LOOKUP[string.lower(v.Name)] = k
end

function Helpers.ResolveIslandId(rawId, C)
	if type(rawId) ~= "string" or rawId == "" then
		return nil
	end
	if ISLAND_REALM_MIN_LEVEL[rawId] then
		return rawId
	end
	local hit = ISLAND_ALIAS_LOOKUP[string.lower(rawId)]
	if hit then
		return hit
	end
	if type(C) == "table" and type(C.FastTravel) == "table" and C.FastTravel[rawId] then
		return C.FastTravel[rawId].Id or rawId
	end
	return rawId
end

function Helpers.SyncDiscoveredIslands(profile, C)
	if type(profile) ~= "table" then
		return {}
	end
	profile.DiscoveredIslands = type(profile.DiscoveredIslands) == "table" and profile.DiscoveredIslands or {}
	local disc = profile.DiscoveredIslands
	disc.SkyHub = true
	disc.GoldenSky = true

	if type(profile.HomeIsland) == "string" and profile.HomeIsland ~= "" then
		local hid = Helpers.ResolveIslandId(profile.HomeIsland, C)
		if hid then disc[hid] = true end
	end

	if type(profile.UnlockedWorlds) == "table" then
		for k, val in pairs(profile.UnlockedWorlds) do
			if val == true then
				local cid = Helpers.ResolveIslandId(k, C)
				if cid and ISLAND_REALM_MIN_LEVEL[cid] then
					local minReq = ISLAND_REALM_MIN_LEVEL[cid].MinLevel or 1
					if (tonumber(profile.Level) or 1) >= minReq or (cid ~= "FrozenCyber" and cid ~= "ShadowRealm") then
						disc[cid] = true
					end
				end
			end
		end
	end

	-- Auto-unlock any island whose quest the player has reached or completed!
	local qIdx = math.max(1, tonumber(profile.QuestIndex) or 1)
	local quests = type(C) == "table" and type(C.Quests) == "table" and C.Quests or {}
	local completed = type(profile.CompletedQuests) == "table" and profile.CompletedQuests or {}
	local lv = math.max(1, tonumber(profile.Level) or 1)

	for idx, q in ipairs(quests) do
		if type(q) == "table" then
			local qReached = (idx <= qIdx and lv >= (tonumber(q.Level or q.LevelReq) or 1)) or (q.Id and completed[q.Id] == true)
			if qReached then
				local qIsl = q.IslandId or q.Island or q.Zone
				if type(qIsl) == "string" and qIsl ~= "" then
					local cid = Helpers.ResolveIslandId(qIsl, C)
					if cid then disc[cid] = true end
				end
				if type(q.Realm) == "string" and ISLAND_REALM_MIN_LEVEL[q.Realm] and lv >= (ISLAND_REALM_MIN_LEVEL[q.Realm].MinLevel or 1) then
					disc[q.Realm] = true
				end
			end
		end
	end
	return disc
end

function Helpers.CheckIslandTeleportGate(p, profile, C, rawIslandId, G)
	local canonId = Helpers.ResolveIslandId(rawIslandId, C)
	if not canonId or canonId == "" then
		if G and G.Notify then G.Notify(p, "Không tìm thấy tọa độ hòn đảo yêu cầu!") end
		return false, nil
	end
	local disc = Helpers.SyncDiscoveredIslands(profile, C)
	if canonId == "SkyHub" or canonId == "GoldenSky" then
		disc[canonId] = true
		return true, canonId
	end
	local spec = ISLAND_REALM_MIN_LEVEL[canonId]
	local cIsl = (type(C) == "table" and type(C.FastTravel) == "table" and C.FastTravel[canonId]) or nil
	if not spec and not cIsl then
		if G and G.Notify then G.Notify(p, "Không tìm thấy đảo hoặc cõi đích!") end
		return false, canonId
	end

	local parentRealm = (cIsl and cIsl.Realm) or (spec and spec.Realm) or "GoldenSky"
	local sea = tonumber(cIsl and cIsl.Sea) or (spec and spec.Sea) or 1
	local islMinLv = tonumber((cIsl and cIsl.MinLevel) or (spec and spec.MinLevel)) or 1
	local realmFloor = (sea == 2 or parentRealm == "FrozenCyber") and 700
		or ((sea == 3 or parentRealm == "ShadowRealm") and 1500)
		or 1
	local reqLv = math.max(realmFloor, islMinLv)
	local islName = tostring((cIsl and cIsl.Name) or (spec and spec.Name) or canonId)

	if not disc[canonId] then
		if G and G.Notify then
			G.Notify(p, string.format("Bạn chưa khám phá [%s]! Hãy lái Tàu Bay khám phá hoặc làm Nhiệm Vụ Chính (Lv. %d+) để mở Dịch Chuyển Nhanh.", islName, reqLv))
		end
		return false, canonId
	end
	if (tonumber(profile.Level) or 1) < reqLv then
		if G and G.Notify then
			G.Notify(p, string.format("Cần đạt Lv. %d+ để dịch chuyển đến [%s]!", reqLv, islName))
		end
		return false, canonId
	end
	return true, canonId
end

-- ============================================================================
-- RACE EVOLUTION (V1 -> V2 -> V3) & ENDGAME GATES
-- ============================================================================
function Helpers.EvolveRace(p, profile, G, C)
	if not p or not profile then
		return false
	end
	local curTier = math.clamp(math.floor(tonumber(profile.RaceTier) or (profile.RaceV4Unlocked and 4 or 1)), 1, 4)
	local lv = tonumber(profile.Level) or 1
	local gold = tonumber(profile.Gold) or 0
	local shards = tonumber(profile.CoreShards) or 0

	if curTier == 1 then
		if lv < 350 then
			G.Notify(p, string.format("Tiến hóa Huyết Thống Tộc V2 yêu cầu Lv. 350+ (Hiện tại: Lv. %d)!", lv))
			return false
		end
		if gold < 250000 then
			G.Notify(p, "Cần 250,000 Gold để tiến hóa Huyết Thống Tộc V2!")
			return false
		end
		profile.Gold = gold - 250000
		profile.RaceTier = 2
		p:SetAttribute("RaceTier", 2)
		if p.Character then p.Character:SetAttribute("RaceTier", 2) end
		G.Notify(p, string.format("[TIẾN HÓA TỘC V2] %s đã thức tỉnh Huyết Thống V2 (+6%% ATK, +8%% DEF, +8%% Tốc Chạy)!", tostring(profile.Race or "Skyborn")))
		G.Sync(p)
		return true
	elseif curTier == 2 then
		if lv < 850 then
			G.Notify(p, string.format("Tiến hóa Huyết Thống Tộc V3 yêu cầu Lv. 850+ (Hiện tại: Lv. %d)!", lv))
			return false
		end
		if gold < 750000 or shards < 500 then
			G.Notify(p, "Cần 750,000 Gold và 500 Core Shards để tiến hóa Huyết Thống Tộc V3!")
			return false
		end
		profile.Gold = gold - 750000
		profile.CoreShards = shards - 500
		profile.RaceTier = 3
		p:SetAttribute("RaceTier", 3)
		if p.Character then p.Character:SetAttribute("RaceTier", 3) end
		G.Notify(p, string.format("[TIẾN HÓA TỘC V3] %s đã đạt cảnh giới Huyết Thống V3 (+12%% ATK, +15%% DEF, +14%% Tốc Chạy)! Đạt Lv. 1900+ để mở Khảo Thí V4 tại Đền Thăng Hoa.", tostring(profile.Race or "Skyborn")))
		G.Sync(p)
		return true
	else
		if not profile.RaceV4Unlocked then
			G.Notify(p, "Bạn đã đạt Tộc V3! Hãy đạt Lv. 1900+ và đến Đền Thăng Hoa (Sea 3) để vượt Khảo Thí Tộc V4!")
		else
			G.Notify(p, "Huyết Thống của bạn đã đạt cảnh giới Tối Thượng V4!")
		end
		return false
	end
end

function Helpers.CheckAndAutoUnlockConqueror(p, profile, G, defeatedEnemyId)
	if type(profile) ~= "table" then
		return false
	end
	profile.Haki = type(profile.Haki) == "table" and profile.Haki or {
		AuraUnlocked = true, AuraActive = false, AuraStage = 1, AuraXP = 0,
		InstinctUnlocked = true, InstinctActive = false, InstinctDodges = 8,
		ConquerorUnlocked = false,
	}
	if profile.Haki.ConquerorUnlocked == true then
		return true
	end
	local fc = type(profile.FirstClearBosses) == "table" and profile.FirstClearBosses or {}
	local bossUnlock = (defeatedEnemyId == "AureonSentinel" or defeatedEnemyId == "CryonPrime" or defeatedEnemyId == "Noxar")
		or fc.AureonSentinel == true or fc.CryonPrime == true or fc.Noxar == true
	local stageUnlock = ((tonumber(profile.HakiStage) or tonumber(profile.Haki.AuraStage) or 1) >= 3)
		and ((tonumber(profile.Level) or 1) >= 700)

	if bossUnlock or stageUnlock then
		profile.Haki.ConquerorUnlocked = true
		if p then
			p:SetAttribute("ConquerorUnlocked", true)
			if G and G.Notify then
				G.Notify(p, "[BÁ VƯƠNG HAKI THỨC TỈNH] Uy áp đế vương bùng nổ! Bạn đã mở khóa Bá Ý [H]!")
			end
		end
		return true
	end
	return false
end

function Helpers.CanAwakenFruit(p, profile, canonFruitId, G)
	if type(profile) ~= "table" then
		return false
	end
	local chipsCleared = tonumber(profile.RaidChipsCleared) or 0
	local mapCleared = type(profile.MicrochipRaidsCleared) == "table" and profile.MicrochipRaidsCleared[canonFruitId] == true
	if chipsCleared < 1 and not mapCleared then
		if G and G.Notify then
			G.Notify(p, "Cần vượt ải Phòng Thí Nghiệm Đột Kích (Microchip Raid Lab • Sea 2) ít nhất 1 lần để giải mã Thức Tỉnh V2!")
		end
		return false
	end
	if (tonumber(profile.CoreShards) or 0) < 1000 then
		if G and G.Notify then
			G.Notify(p, "Cần 1,000 Core Shards để giải mã Thức Tỉnh Lõi V2!")
		end
		return false
	end
	return true
end

-- ============================================================================
-- CONFIRM-BEFORE-SPEND DIALOGUES & 18 REGIONAL NPCS
-- ============================================================================
local function makeChoice(idx, label, subAction, extraPayload, directCmd)
	local cmdStr = directCmd or ("ConfirmNPCAction:" .. tostring(subAction))
	local pl = type(extraPayload) == "table" and extraPayload or {}
	pl.action = pl.action or subAction
	pl.subAction = pl.subAction or subAction
	return {
		index = idx,
		id = subAction,
		Id = subAction,
		action = subAction,
		Action = subAction,
		label = label,
		Label = label,
		command = cmdStr,
		Command = cmdStr,
		payload = pl,
		Payload = pl,
	}
end

function Helpers.OpenZiolesDialogue(p, profile, rt, G, C)
	local isEn = (p and p:GetAttribute("Language") == "en")
	local goldCost = Helpers.GetGachaGoldCost(C, profile.Level)
	local shardCost = tonumber(C and C.GachaCostShards) or 200
	local pityMax = tonumber(C and C.FruitPityMax) or 50
	local pity = math.clamp(math.floor(tonumber(profile.FruitPity) or 0), 0, pityMax)
	local vouchers = math.max(0, math.floor(tonumber(profile.FreeFruitVouchers) or 0))
	local cdLeft = math.max(0, math.ceil((tonumber(rt and rt.NextGachaRollAt) or 0) - os.clock()))
	local msg, choices, speaker, role
	if isEn then
		local cdText = (cdLeft > 0) and string.format(" (Cooldown: %ds)", cdLeft) or " (Ready)"
		local vText = (vouchers > 0) and string.format(" • Free Spin Vouchers: x%d", vouchers) or ""
		msg = string.format(
			"Greetings Lv.%d Skyborn! Rolling a weighted Aether Core at the Shrine costs %d Gold or %d Core Shards (60s CD%s%s • Mythic Pity: %d/%d). Drop Odds: Common 32%% • Uncommon 29%% • Rare 18%% • Epic 12%% • Legendary 6.6%% • Mythic 2.4%%.",
			tonumber(profile.Level) or 1,
			goldCost,
			shardCost,
			cdText,
			vText,
			pity,
			pityMax
		)
		choices = {
			makeChoice(1, "[1] OPEN 3D AETHER GACHA SHRINE", "OpenGachaShrine", { npcId = "Zioles" }, "OpenScreen:Fruits:Gacha"),
			makeChoice(2, string.format("[2] QUICK ROLL (%d SHARDS)", shardCost), "RollFruitShards", { npcId = "Zioles", currency = "Shards" }),
			makeChoice(3, "[3] MIRAGE CORE STOCK", "OpenMirageStock", { npcId = "Zioles" }, "OpenScreen:NPCShop:MirageDealer"),
			makeChoice(4, "[ESC] CLOSE", "Close", { npcId = "Zioles" }),
		}
		speaker = "Sage Zioles • Aether Core Gacha"
		role = "Aether Core Oracle • Sky Hub"
	else
		local cdText = (cdLeft > 0) and string.format(" (Đang hồi: %ds)", cdLeft) or " (Sẵn sàng)"
		local vText = (vouchers > 0) and string.format(" • Vé Quay Miễn Phí: x%d", vouchers) or ""
		msg = string.format(
			"Chào lữ khách Lv.%d! Cầu Lõi Aether ngẫu nhiên theo trọng số tại Điện Thờ có giá %d Gold hoặc %d Core Shards (Hồi chiêu 60s%s%s • Bảo Hiểm Mythic: %d/%d). Tỷ lệ rơi: Common 32%% • Uncommon 29%% • Rare 18%% • Epic 12%% • Legendary 6.6%% • Mythic 2.4%%.",
			tonumber(profile.Level) or 1,
			goldCost,
			shardCost,
			cdText,
			vText,
			pity,
			pityMax
		)
		choices = {
			makeChoice(1, "[1] MỞ ĐÀI TRIỆU HỒI GACHA 3D", "OpenGachaShrine", { npcId = "Zioles" }, "OpenScreen:Fruits:Gacha"),
			makeChoice(2, string.format("[2] QUAY NHANH BẰNG %d SHARDS", shardCost), "RollFruitShards", { npcId = "Zioles", currency = "Shards" }),
			makeChoice(3, "[3] KỆ LÕI HƯ QUANG (MIRAGE)", "OpenMirageStock", { npcId = "Zioles" }, "OpenScreen:NPCShop:MirageDealer"),
			makeChoice(4, "[ESC] ĐÓNG", "Close", { npcId = "Zioles" }),
		}
		speaker = "Hiền Giả Zioles • Gacha Lõi Aether"
		role = "Aether Core Oracle • Sky Hub"
	end
	G.SendDialogue(p, speaker, role, msg, choices[1].label, choices[1].command, choices)
end

function Helpers.OpenAncientMonkDialogue(p, profile, G)
	profile.UnlockedStyles = type(profile.UnlockedStyles) == "table" and profile.UnlockedStyles or { skyborn_combat = true }
	profile.UnlockedStyles.skyborn_combat = true

	local nextSpec = nil
	for _, spec in ipairs(Helpers.MARTIAL_PROGRESSION) do
		if not profile.UnlockedStyles[spec.Id] and not profile.UnlockedStyles[spec.Alias] then
			nextSpec = spec
			break
		end
	end

	local bestMas = Helpers.GetBestMartialMastery(profile)
	if nextSpec then
		local reqParts = { string.format("Lv.%d+", nextSpec.MinLevel) }
		if nextSpec.ReqMastery > 0 then
			table.insert(reqParts, string.format("Mastery %d+", nextSpec.ReqMastery))
		end
		local costParts = { string.format("%d Gold", nextSpec.Gold) }
		if nextSpec.Shards > 0 then
			table.insert(costParts, string.format("%d Core Shards", nextSpec.Shards))
		end
		local msg = string.format(
			"Tuyệt kỹ tiếp theo: [%s] • Yêu cầu: %s (Mastery quyền pháp hiện tại: %d) • Học phí: %s. Xác nhận bái sư lĩnh hội?",
			nextSpec.Name,
			table.concat(reqParts, " + "),
			bestMas,
			table.concat(costParts, " + ")
		)
		local choices = {
			makeChoice(1, "[1] XÁC NHẬN HỌC: " .. nextSpec.Alias, "LearnMartialStyle:" .. nextSpec.Id, { npcId = "AncientMonk", styleId = nextSpec.Id }),
			makeChoice(2, "[2] ĐỔI QUYỀN PHÁP ĐÃ MỞ", "CycleMartialStyle", { npcId = "AncientMonk" }),
			makeChoice(3, "[3] MỞ VÕ ĐƯỜNG 3D", "OpenMartialDojo", { npcId = "AncientMonk" }, "OpenScreen:NPCShop:MartialDojo"),
			makeChoice(4, "[ESC] ĐÓNG", "Close", { npcId = "AncientMonk" }),
		}
		G.SendDialogue(p, "Tông Sư Quyền Pháp • Ancient Monk", "Grandmaster Martial Dojo", msg, choices[1].label, choices[1].command, choices)
	else
		local msg = string.format("Nhà ngươi đã lĩnh hội toàn bộ 7 tuyệt học Võ Đường (Mastery cao nhất: %d)! Muốn luân chuyển quyền pháp đang trang bị không?", bestMas)
		local choices = {
			makeChoice(1, "[1] ĐỔI QUYỀN PHÁP TIẾP THEO", "CycleMartialStyle", { npcId = "AncientMonk" }),
			makeChoice(2, "[2] MỞ VÕ ĐƯỜNG 3D", "OpenMartialDojo", { npcId = "AncientMonk" }, "OpenScreen:NPCShop:MartialDojo"),
			makeChoice(3, "[3] XEM KỸ NĂNG [K]", "OpenSkills", { npcId = "AncientMonk" }, "OpenScreen:Skills"),
			makeChoice(4, "[ESC] ĐÓNG", "Close", { npcId = "AncientMonk" }),
		}
		G.SendDialogue(p, "Tông Sư Quyền Pháp • Ancient Monk", "Grandmaster Martial Dojo", msg, choices[1].label, choices[1].command, choices)
	end
end

function Helpers.OpenKaelDialogue(p, profile, G, C)
	local swordId = tostring((profile.Equipped and profile.Equipped.Weapon) or profile.Weapon or "starter_sword")
	local gunId = tostring((profile.Equipped and profile.Equipped.Gun) or profile.EquippedGun or "aether_flintlock")
	local mTbl = type(profile.Mastery) == "table" and profile.Mastery or {}
	local sMas = tonumber(mTbl[swordId] or mTbl.Sword) or 1
	local gMas = tonumber(mTbl[gunId] or mTbl.Gun) or 1
	local enh = tonumber(profile.WeaponEnhance) or 0
	local cls = tostring(profile.ClassId or "SkyGuardian")
	local msg = string.format(
		"Lò Rèn Thần Khí luôn rực lửa! Hệ phái hiện tại: [%s] • Kiếm [%s +%d] (Mastery %d) • Súng [%s] (Mastery %d). Ngươi muốn rèn thần binh hay chuyển hệ phái?",
		cls, swordId, enh, sMas, gunId, gMas
	)
	local choices = {
		makeChoice(1, "[1] MỞ LÒ RÈN THẦN KHÍ", "OpenForge", { npcId = "Kael" }, "OpenScreen:Forge"),
		makeChoice(2, "[2] ĐỔI HỆ PHÁI CHIẾN ĐẤU", "SwitchClass", { npcId = "Kael" }),
		makeChoice(3, "[3] KIỂM TRA THÔNG THẠO VŨ KHÍ", "CheckWeaponMastery", { npcId = "Kael" }),
		makeChoice(4, "[ESC] ĐÓNG", "Close", { npcId = "Kael" }),
	}
	G.SendDialogue(p, "Thợ Rèn Kael • Lò Rèn Thần Khí", "Master Weaponsmith • Sky Hub", msg, choices[1].label, choices[1].command, choices)
end

function Helpers.OpenDrVegaDialogue(p, profile, G)
	local race = tostring(profile.Race or "Skyborn")
	local rTier = math.clamp(tonumber(profile.RaceTier) or (profile.RaceV4Unlocked and 4 or 1), 1, 4)
	local nextEvoTxt = (rTier == 1 and "Tiến hóa V2: Lv.350 + 250,000 Gold")
		or (rTier == 2 and "Tiến hóa V3: Lv.850 + 750,000 Gold + 500 Shards")
		or (not profile.RaceV4Unlocked and "Đạt Tộc V3! Đến Đền Thăng Hoa (Lv.1900+) mở V4")
		or "Đã đạt Tộc V4 Tối Thượng"
	local chips = tonumber(profile.RaidChipsCleared) or 0
	local msg = string.format(
		"Phòng Thí Nghiệm Huyết Thống & Lõi Aether! Huyết thống hiện tại: [%s • V%d] (%s) • Số ải Microchip Raid đã phá: %d (Đổi Tộc mới tốn 50 Core Shards).",
		race, rTier, nextEvoTxt, chips
	)
	local choices = {
		makeChoice(1, string.format("[1] TIẾN HÓA TỘC (HIỆN TẠI V%d)", rTier), "EvolveRace", { npcId = "DrVega" }),
		makeChoice(2, "[2] ĐỔI TỘC NGẪU NHIÊN (50 SHARDS)", "RerollRace", { npcId = "DrVega" }),
		makeChoice(3, "[3] PHÒNG THÍ NGHIỆM RAID", "OpenRaid", { npcId = "DrVega" }, "OpenScreen:Raid"),
		makeChoice(4, "[ESC] ĐÓNG", "Close", { npcId = "DrVega" }),
	}
	G.SendDialogue(p, "Tiến Sĩ Dr. Vega • Học Giả Huyết Thống", "Lineage & Microchip Alchemist • Sky Hub", msg, choices[1].label, choices[1].command, choices)
end

local _RGB = Color3.fromRGB
-- All 18 Regional NPCs on SKYBREAK's actual floating islands with Plaza LookAt coordinates (>= 15 studs apart) & authentic roles
Helpers.REGIONAL_NPCS = {
	{ Id = "NPC_AetherShrineKeeper", Name = "Dr. Vega • Học Giả Điện Thờ Aether", Role = "Điện Thờ Aether • Lv.150", IslandId = "AetherShrines", Pos = _V3(340, 50.7, 977), FloorY = 48.5, LookAt = _V3(340, 50.7, 1005), Visual = "DrVega", Col = _RGB(95, 235, 255), Kind = "Commander" },
	{ Id = "NPC_WestGardenScout", Name = "Thợ Săn Tiền Thưởng • West Garden Scout", Role = "Chỉ Huy Tiền Đồn Vườn Tây • Lv.250", IslandId = "WestGarden", Pos = _V3(-2764.0, 48.7, -55.0), FloorY = 46.5, LookAt = _V3(-2800, 49.0, -65), Visual = "SkyShipwrightNPC", Col = _RGB(255, 205, 82), Kind = "Commander" },
	{ Id = "NPC_FrozenOutpostCommander", Name = "Chỉ Huy Tiền Đồn Băng • Cyberport Outpost", Role = "Tư Lệnh Cảng Băng Giá • Lv.700", IslandId = "FrozenCyber", Pos = _V3(11684.4, 49.1, 243.0), FloorY = 46.9, LookAt = _V3(11620.5, 49.1, 534.8), Visual = "DrVega", Col = _RGB(105, 240, 255), Kind = "Commander" },
	{ Id = "NPC_CyberportBroker", Name = "Thương Nhân Cyberport • Giao Dịch Aether", Role = "Trạm Giao Thương Sea 2 • Lv.820", IslandId = "CyberportCafe", Pos = _V3(9405.9, 49.1, 1787.0), FloorY = 46.9, LookAt = _V3(9400, 49.1, 1785), Visual = "ZiolesGachaNPC", Col = _RGB(88, 238, 255), Kind = "ShipBroker" },
	{ Id = "NPC_PermafrostQuartermaster", Name = "Thiết Giáp Quân Nhu • Permafrost Warden", Role = "Lò Rèn Pháo Đài Tuyết • Lv.950", IslandId = "PermafrostGarrison", Pos = _V3(9369.3, 49.1, -2037.0), FloorY = 46.9, LookAt = _V3(9400, 49.1, -2055), Visual = "Kael", Col = _RGB(125, 242, 255), Kind = "ForgeOutpost" },
	{ Id = "NPC_RaidLabScientist", Name = "Tiến Sĩ Giải Mã • Raid Lab Scientist", Role = "Phòng Thí Nghiệm Đột Kích • Lv.1150", IslandId = "MicrochipRaidLab", Pos = _V3(14578, 49.1, 1772), FloorY = 46.9, LookAt = _V3(14600, 49.1, 1785), Visual = "DrVega", Col = _RGB(95, 245, 255), Kind = "RaidScientist" },
	{ Id = "NPC_GlacialExplorer", Name = "Thuyền Trưởng Thám Hiểm • Glacial Navigator", Role = "Xác Tàu Băng Cổ Đại • Lv.1310", IslandId = "GlacialWreckage", Pos = _V3(14567.3, 49.1, -1791.0), FloorY = 46.9, LookAt = _V3(14600, 49.1, -1812), Visual = "SkyShipwrightNPC", Col = _RGB(145, 242, 255), Kind = "Commander" },
	{ Id = "NPC_CryonCitadelSentinel", Name = "Chỉ Huy Tiền Tuyến • Cryon Citadel Vanguard", Role = "Tiền Tuyến Ngai Băng • Lv.1430", IslandId = "CryonArena", Pos = _V3(11972, 49.5, -278), FloorY = 46.9, LookAt = _V3(12000, 49.5, -285), Visual = "Lyra", Col = _RGB(115, 240, 255), Kind = "Commander" },
	{ Id = "NPC_ShadowVanguard", Name = "Chronos • Giám Hộ Hư Ảnh (Shadow Outpost)", Role = "Tiền Đồn Hư Không • Lv.1500", IslandId = "ShadowRealm", Pos = _V3(-12568.8, 49.1, 435.0), FloorY = 46.9, LookAt = _V3(-12593.4, 49.5, 414), Visual = "Chronos", Col = _RGB(215, 115, 255), Kind = "Commander" },
	{ Id = "NPC_CastleVoidSteward", Name = "Tổng Quản Hư Không • Void Citadel Steward", Role = "Pháo Đài Hư Không • Lv.1620", IslandId = "CastleOnTheVoid", Pos = _V3(-14631.9, 49.1, 2152.0), FloorY = 46.9, LookAt = _V3(-14600, 49.1, 2173.1), Visual = "Lyra", Col = _RGB(225, 110, 255), Kind = "Commander" },
	{ Id = "NPC_UmbralSwordmaster", Name = "Kiếm Thánh Hắc Tinh • Eclipse Twinblades Smith", Role = "Bí Thuật Song Kiếm Nguyệt Thực • Lv.1750", IslandId = "UmbralSanctum", Pos = _V3(-9432.1, 49.1, 1798.0), FloorY = 46.9, LookAt = _V3(-9400, 49.1, 1815), Visual = "Kael", Col = _RGB(245, 95, 255), Kind = "TwinbladesSmith" },
	{ Id = "NPC_MirageHunter", Name = "Thợ Săn Thủy Xà • Serpent Hunter", Role = "Vực Thẳm Thủy Xà • Lv.2040", IslandId = "LeviathanAbyss", Pos = _V3(-12033.2, 49.1, -3347.2), FloorY = 46.9, LookAt = _V3(-12000, 49.1, -3364.5), Visual = "SkyShipwrightNPC", Col = _RGB(78, 238, 255), Kind = "ShipBroker" },
	{ Id = "NPC_NoxarThroneKeeper", Name = "Hiền Triết Thăng Hoa • Temple & Throne Sage", Role = "Khảo Thí Tộc V4 & Ngai Hư Không • Lv.1900+", IslandId = "TempleOfTheCore", Pos = _V3(-11698, 49.5, -102), FloorY = 46.9, LookAt = _V3(-11672.2, 49.5, -110), Visual = "Chronos", Col = _RGB(215, 115, 255), Kind = "TempleSage" },
	{ Id = "NPC_VerdantKeeper", Name = "Đại Sư Cổ Thụ • Verdant Temple Sage", Role = "Cổ Thụ Thăng Hoa • Lv.2200", IslandId = "VerdantCrown", Pos = _V3(-13.0, 169.1, -8963.3), FloorY = 166.9, LookAt = _V3(0, 169.1, -8985), Visual = "AncientMonkNPC", Col = _RGB(95, 242, 155), Kind = "TempleSage" },
	{ Id = "NPC_EmberforgeSmith", Name = "Thợ Rèn Hỏa Tinh • Star-Forge Master", Role = "Hoang Mạc Lò Rèn Lửa • Lv.2270", IslandId = "EmberforgeWastes", Pos = _V3(11987.0, 168.7, -9243.3), FloorY = 166.5, LookAt = _V3(12000, 168.7, -9265), Visual = "Kael", Col = _RGB(255, 145, 78), Kind = "ForgeOutpost" },
	{ Id = "NPC_AbyssalNavigator", Name = "Hoa Tiêu Vực Thẳm • Abyssal Navigator", Role = "Thủy Triều Vực Sâu • Lv.2340", IslandId = "AbyssalTides", Pos = _V3(-12021.4, 169.1, -8944.1), FloorY = 166.9, LookAt = _V3(-12000, 169.1, -8964.5), Visual = "SkyShipwrightNPC", Col = _RGB(68, 215, 245), Kind = "Commander" },
	{ Id = "NPC_ChronosArchivist", Name = "Chronos • Đại Giám Hộ Thời Gian", Role = "Pháo Đài Thời Gian • Lv.2410", IslandId = "ChronosBastion", Pos = _V3(-9.6, 229.1, -13464.3), FloorY = 226.9, LookAt = _V3(0, 229.1, -13485), Visual = "Chronos", Col = _RGB(255, 215, 92), Kind = "Commander" },
	{ Id = "NPC_AstraelVanguard", Name = "Astrael • Thủ Vệ Tận Cùng Bức Màn", Role = "Tận Cùng Bức Màn • Lv.2480", IslandId = "VeilsEnd", Pos = _V3(-12.6, 309.1, -17605.6), FloorY = 306.9, LookAt = _V3(0, 309.1, -17626.9), Visual = "Male_SkyGuardian", Col = _RGB(215, 115, 255), Kind = "Commander" },
}

local REGIONAL_BY_ID = {}
for _, r in ipairs(Helpers.REGIONAL_NPCS) do
	REGIONAL_BY_ID[r.Id] = r
end

local function findBestQuestForIsland(C, profile, islandId)
	local quests = type(C) == "table" and type(C.Quests) == "table" and C.Quests or {}
	local lv = math.max(1, tonumber(profile.Level) or 1)
	local spec = ISLAND_REALM_MIN_LEVEL[islandId]
	local targetMinLv = (spec and spec.MinLevel) or 1
	local bestIdx, bestQ = nil, nil
	for idx, q in ipairs(quests) do
		if type(q) == "table" then
			local qIsl = tostring(q.Island or q.IslandId or q.Zone or "")
			local qLv = tonumber(q.Level or q.LevelReq) or 1
			if qIsl == islandId then
				if lv >= qLv or not bestQ then
					bestIdx, bestQ = idx, q
				end
			elseif not bestQ and math.abs(qLv - targetMinLv) <= 45 and lv >= qLv then
				bestIdx, bestQ = idx, q
			end
		end
	end
	if not bestQ then
		local curIdx = math.clamp(tonumber(profile.QuestIndex) or 1, 1, math.max(1, #quests))
		bestIdx, bestQ = curIdx, quests[curIdx]
	end
	return bestIdx, bestQ
end

function Helpers.InteractRegionalNPC(p, npcId, profile, G, C)
	local r = REGIONAL_BY_ID[npcId]
	if not r or not profile then
		return false
	end
	Helpers.SyncDiscoveredIslands(profile, C)
	profile.DiscoveredIslands[r.IslandId] = true

	if r.Kind == "TwinbladesSmith" then
		local inv = type(profile.Inventory) == "table" and profile.Inventory or {}
		local mTbl = type(profile.Mastery) == "table" and profile.Mastery or {}
		local mStorm = tonumber(mTbl.stormfang_twin or mTbl.cyber_katana) or 1
		local mYamo = tonumber(mTbl.yamo_voidblade or mTbl.noxar_abyssal_greatsword) or 1
		local hasTwin = (tonumber(inv.eclipse_twinblades) or 0) > 0
		local msg = string.format(
			"Ta rèn đúc Song Kiếm Nguyệt Thực từ 2 luồng kiếm ý Bão Tố & Hư Không! Thông thạo hiện tại: Đao Lôi Phong (%d/350) • Yêu Đao Yamo (%d/350) • Trạng thái: %s.",
			mStorm, mYamo, hasTwin and "ĐÃ SỞ HỮU" or "Chưa rèn"
		)
		local choices = {
			makeChoice(1, "[1] MỞ LÒ RÈN THẦN KHÍ", "OpenForge", { npcId = npcId }, "OpenScreen:Forge"),
			makeChoice(2, "[2] TIỆM DANH KIẾM 3D", "OpenSwordShop", { npcId = npcId }, "OpenScreen:NPCShop:SwordDealer"),
			makeChoice(3, "[3] ĐẶT ĐIỂM HỒI SINH TẠI ĐÂY", "SetRegionalHome:" .. r.IslandId, { npcId = npcId, islandId = r.IslandId }),
			makeChoice(4, "[ESC] ĐÓNG", "Close", { npcId = npcId }),
		}
		G.SendDialogue(p, r.Name, r.Role, msg, choices[1].label, choices[1].command, choices)
		return true

	elseif r.Kind == "RaidScientist" then
		local chips = tonumber(profile.RaidChipsCleared) or 0
		local fId = Helpers.ResolveFruitId(profile.EquippedFruit)
		local msg = string.format(
			"Phòng Thí Nghiệm Đột Kích Microchip! Vượt 5 tầng đảo Raid sẽ tăng lượt Giải Mã Thức Tỉnh V2 (Đã hoàn thành: %d lần • Lõi đang mang: %s).",
			chips, fId ~= "" and fId or "Chưa trang bị"
		)
		local choices = {
			makeChoice(1, "[1] MỞ BẢNG ĐỘT KÍCH RAID", "OpenRaid", { npcId = npcId }, "OpenScreen:Raid"),
			makeChoice(2, "[2] KHỞI ĐỘNG MICROCHIP RAID", "StartMicrochipRaid", { npcId = npcId }),
			makeChoice(3, "[3] ĐẶT ĐIỂM HỒI SINH TẠI ĐÂY", "SetRegionalHome:" .. r.IslandId, { npcId = npcId, islandId = r.IslandId }),
			makeChoice(4, "[ESC] ĐÓNG", "Close", { npcId = npcId }),
		}
		G.SendDialogue(p, r.Name, r.Role, msg, choices[1].label, choices[1].command, choices)
		return true

	elseif r.Kind == "TempleSage" then
		local rTier = math.clamp(tonumber(profile.RaceTier) or (profile.RaceV4Unlocked and 4 or 1), 1, 4)
		local lv = tonumber(profile.Level) or 1
		local readyV4 = (rTier >= 3 and lv >= 1900)
		local msg = string.format(
			"Đền Thăng Hoa chỉ mở cửa Khảo Thí Tộc V4 cho chiến binh đạt Tộc V3 và Lv.1900+! Trạng thái của ngươi: [%s • V%d • Lv.%d] — %s.",
			tostring(profile.Race or "Skyborn"), rTier, lv,
			profile.RaceV4Unlocked and "ĐÃ MỞ KHÓA TỘC V4" or (readyV4 and "ĐỦ ĐIỀU KIỆN KHẢO THÍ V4!" or "Cần tiến hóa Tộc V3 & đạt Lv.1900+")
		)
		local primarySub = (rTier < 3) and "EvolveRace" or "StartTempleV4Trial"
		local primaryLbl = (rTier < 3) and string.format("[1] TIẾN HÓA TỘC LÊN V%d", rTier + 1) or "[1] BẮT ĐẦU KHẢO THÍ TỘC V4"
		local choices = {
			makeChoice(1, primarySub == "EvolveRace" and primaryLbl or "[1] BẮT ĐẦU KHẢO THÍ TỘC V4", primarySub, { npcId = npcId }),
			makeChoice(2, "[2] MỞ TẾ ĐÀN THĂNG HOA", "OpenTempleUI", { npcId = npcId }, "OpenScreen:NPCShop:DrVegaAndTempleV4"),
			makeChoice(3, "[3] ĐẶT ĐIỂM HỒI SINH TẠI ĐÂY", "SetRegionalHome:" .. r.IslandId, { npcId = npcId, islandId = r.IslandId }),
			makeChoice(4, "[ESC] ĐÓNG", "Close", { npcId = npcId }),
		}
		G.SendDialogue(p, r.Name, r.Role, msg, choices[1].label, choices[1].command, choices)
		return true

	elseif r.Kind == "ForgeOutpost" or r.Kind == "ShipBroker" then
		local isShip = (r.Kind == "ShipBroker")
		local _, q = findBestQuestForIsland(C, profile, r.IslandId)
		local qTitle = (q and (q.Title or q.Name)) or "Tuần Tra Khu Vực"
		local msg = isShip
			and string.format("Thiên Cảng Sea 3 đón mọi chiến hạm săn Thủy Xà! Nhiệm vụ khu vực hiện tại: [%s].", qTitle)
			or string.format("Lửa dung nham tại Hỏa Lò nung chảy mọi quặng Aether! Nhiệm vụ khu vực hiện tại: [%s].", qTitle)
		local openCmd = isShip and "OpenScreen:NPCShop:Shipwright" or "OpenScreen:Forge"
		local openLbl = isShip and "[1] MỞ XƯỞNG CHIẾN HẠM 3D" or "[1] MỞ LÒ RÈN THẦN KHÍ"
		local choices = {
			makeChoice(1, openLbl, "OpenRegionalScreen", { npcId = npcId }, openCmd),
			makeChoice(2, "[2] NHẬN NHIỆM VỤ & LƯU ĐẢO", "TrackIslandQuest:" .. r.IslandId, { npcId = npcId, islandId = r.IslandId, pos = r.Pos }),
			makeChoice(3, "[3] MỞ BẢN ĐỒ ĐẢO [M]", "OpenWorldMap", { npcId = npcId }, "OpenScreen:WorldMap"),
			makeChoice(4, "[ESC] ĐÓNG", "Close", { npcId = npcId }),
		}
		G.SendDialogue(p, r.Name, r.Role, msg, choices[1].label, choices[1].command, choices)
		return true
	end

	-- Default Regional Outpost / Harbor Commander: tracks matching quest in Config.Quests + sets HomePoint!
	local _, q = findBestQuestForIsland(C, profile, r.IslandId)
	local qTitle = (q and (q.Title or q.Name)) or "Chiến Dịch Khu Vực"
	local qLv = (q and (q.Level or q.LevelReq)) or 1
	local msg = string.format(
		"Chào mừng đến [%s]! Chiến dịch khu vực phù hợp: [%s • Lv.%d]. Hãy xác nhận để ghim nhiệm vụ và lưu Điểm Hồi Sinh trên đảo này!",
		tostring((ISLAND_REALM_MIN_LEVEL[r.IslandId] and ISLAND_REALM_MIN_LEVEL[r.IslandId].Name) or r.IslandId),
		qTitle, qLv
	)
	local choices = {
		makeChoice(1, "[1] GHIM NHIỆM VỤ & LƯU HỒI SINH", "TrackIslandQuest:" .. r.IslandId, { npcId = npcId, islandId = r.IslandId }),
		makeChoice(2, "[2] NHẬT KÝ NHIỆM VỤ [L]", "OpenQuestJournal", { npcId = npcId }, "OpenScreen:QuestJournal"),
		makeChoice(3, "[3] BẢN ĐỒ ĐẢO BAY [M]", "OpenWorldMap", { npcId = npcId }, "OpenScreen:WorldMap"),
		makeChoice(4, "[ESC] ĐÓNG", "Close", { npcId = npcId }),
	}
	G.SendDialogue(p, r.Name, r.Role, msg, choices[1].label, choices[1].command, choices)
	return true
end

function Helpers.HandleConfirmNPCAction(p, rawSubAction, payload, G, D, C, Expansion)
	local profile = D and D.Get(p)
	local rt = G and G.Runtime and G.Runtime[p]
	if not p or not profile or not rt then
		return false
	end
	payload = type(payload) == "table" and payload or {}
	local sub = tostring(rawSubAction or payload.subAction or payload.action or payload.choiceId or payload.id or payload.value or "")
	if sub:sub(1, 17) == "ConfirmNPCAction:" then
		sub = sub:sub(18)
	end
	local argAfterColon = nil
	local colonPos = string.find(sub, ":", 1, true)
	if colonPos then
		argAfterColon = sub:sub(colonPos + 1)
		sub = sub:sub(1, colonPos - 1)
	end

	if sub == "Close" or sub == "" then
		return true
	elseif sub == "RollFruitGold" then
		Helpers.ExecuteRollFruit(p, profile, rt, G, C, "Gold")
		return true
	elseif sub == "RollFruitShards" then
		Helpers.ExecuteRollFruit(p, profile, rt, G, C, "Shards")
		return true
	elseif sub == "LearnMartialStyle" then
		local styleId = tostring(argAfterColon or payload.styleId or payload.id or "")
		if Expansion and type(Expansion.SelectOrLearnStyle) == "function" and styleId ~= "" then
			Expansion.SelectOrLearnStyle(p, styleId)
		end
		return true
	elseif sub == "CycleMartialStyle" then
		profile.UnlockedStyles = type(profile.UnlockedStyles) == "table" and profile.UnlockedStyles or { skyborn_combat = true }
		local unlockedOrder = {}
		for _, spec in ipairs(Helpers.MARTIAL_PROGRESSION) do
			if profile.UnlockedStyles[spec.Id] or profile.UnlockedStyles[spec.Alias] or spec.Id == "skyborn_combat" then
				table.insert(unlockedOrder, spec)
			end
		end
		local cur = tostring(profile.FightingStyle or "skyborn_combat")
		local nextSpec = unlockedOrder[1]
		for idx, spec in ipairs(unlockedOrder) do
			if spec.Id == cur or spec.Alias == cur then
				nextSpec = unlockedOrder[(idx % #unlockedOrder) + 1]
				break
			end
		end
		if nextSpec and Expansion and type(Expansion.SelectOrLearnStyle) == "function" then
			Expansion.SelectOrLearnStyle(p, nextSpec.Id)
		end
		return true
	elseif sub == "SwitchClass" then
		local order = { "SkyGuardian", "ThunderStriker", "ArcaneMage" }
		local cur = tostring(profile.ClassId or "SkyGuardian")
		local nextCls = "ThunderStriker"
		for i, cid in ipairs(order) do
			if cid == cur then
				nextCls = order[(i % #order) + 1]
				break
			end
		end
		G.Equipment(p, { action = "SelectClass", classId = nextCls })
		return true
	elseif sub == "CheckWeaponMastery" then
		local swordId = tostring((profile.Equipped and profile.Equipped.Weapon) or profile.Weapon or "starter_sword")
		local gunId = tostring((profile.Equipped and profile.Equipped.Gun) or profile.EquippedGun or "aether_flintlock")
		local mTbl = type(profile.Mastery) == "table" and profile.Mastery or {}
		G.Notify(p, string.format(
			"[THÔNG THẠO VŨ KHÍ] Kiếm [%s]: Mastery Lv.%d • Súng [%s]: Mastery Lv.%d • Cường Hóa: +%d",
			swordId, tonumber(mTbl[swordId] or mTbl.Sword) or 1,
			gunId, tonumber(mTbl[gunId] or mTbl.Gun) or 1,
			tonumber(profile.WeaponEnhance) or 0
		))
		return true
	elseif sub == "EvolveRace" then
		Helpers.EvolveRace(p, profile, G, C)
		return true
	elseif sub == "RerollRace" then
		if Expansion and type(Expansion.RerollRace) == "function" then
			Expansion.RerollRace(p)
		end
		return true
	elseif sub == "StartTempleV4Trial" then
		if Expansion and type(Expansion.HandleUIRequest) == "function" then
			Expansion.HandleUIRequest(p, "StartTempleV4Trial", payload)
		end
		return true
	elseif sub == "StartMicrochipRaid" then
		if G.WorldEvents and type(G.WorldEvents.HandleUIRequest) == "function" then
			G.WorldEvents.HandleUIRequest(p, "StartRaid", payload)
		elseif G.HandleUIRequest then
			G.HandleUIRequest(p, "StartRaid", payload)
		end
		return true
	elseif sub == "SetRegionalHome" or sub == "TrackIslandQuest" then
		local npcSpec = REGIONAL_BY_ID[tostring(payload.npcId or "")]
		local islId = tostring(argAfterColon or payload.islandId or (npcSpec and npcSpec.IslandId) or "SkyHub")
		profile.HomeIsland = islId
		Helpers.SyncDiscoveredIslands(profile, C)
		profile.DiscoveredIslands[islId] = true
		if npcSpec and npcSpec.LookAt then
			rt.CustomRespawnPos = npcSpec.LookAt + _V3(0, 3.0, 0)
			p:SetAttribute("RespawnPos", rt.CustomRespawnPos)
		end
		if sub == "TrackIslandQuest" then
			local qIdx, q = findBestQuestForIsland(C, profile, islId)
			if q and (tonumber(profile.Level) or 1) >= (tonumber(q.Level or q.LevelReq) or 1) then
				profile.QuestIndex = qIdx
				profile.Accepted = true
				profile.Progress = {}
				G.Notify(p, string.format("Đã nhận nhiệm vụ [%s] & lưu Điểm Hồi Sinh tại [%s]!", tostring(q.Title or q.Name or q.Id), islId))
			else
				G.Notify(p, string.format("Đã lưu Điểm Hồi Sinh tại [%s]!", islId))
			end
		else
			G.Notify(p, string.format("Đã lưu Điểm Hồi Sinh tại [%s]!", islId))
		end
		G.Sync(p)
		return true
	end
	return false
end

-- ============================================================================
-- ENEMY BOID SEPARATION (< 4.5 STUDS) + CLIFF & OBSTACLE RAYCAST SAFETY
-- ============================================================================
local sharedEnemyRayParams = nil
local function getStaticWorldRayParams()
	if not sharedEnemyRayParams then
		sharedEnemyRayParams = RaycastParams.new()
		sharedEnemyRayParams.FilterType = Enum.RaycastFilterType.Exclude
		sharedEnemyRayParams.RespectCanCollide = true
	end
	local excl = {}
	local ae = workspace:FindFirstChild("ActiveEnemies")
	local ab = workspace:FindFirstChild("ActiveBosses")
	local tfx = workspace:FindFirstChild("SkybreakTempFX")
	if ae then excl[#excl + 1] = ae end
	if ab then excl[#excl + 1] = ab end
	if tfx then excl[#excl + 1] = tfx end
	for _, plr in ipairs(game:GetService("Players"):GetPlayers()) do
		if plr.Character then excl[#excl + 1] = plr.Character end
	end
	sharedEnemyRayParams.FilterDescendantsInstances = excl
	return sharedEnemyRayParams
end

function Helpers.ComputeSafeEnemyTransform(e, goalPos, speed, dt, enemiesList, W)
	if not e or not e.Body or speed <= 0 then
		return nil
	end
	local curPos = e.Body.Position
	local toGoal = _V3(goalPos.X - curPos.X, 0, goalPos.Z - curPos.Z)
	local distGoal = toGoal.Magnitude

	-- Lightweight Boid Separation between nearby active enemies (< 4.5 studs)
	local sepX, sepZ = 0, 0
	if type(enemiesList) == "table" then
		for i = 1, #enemiesList do
			local other = enemiesList[i]
			if other ~= e and other and other.Alive and other.Body then
				local op = other.Body.Position
				local dx, dz = curPos.X - op.X, curPos.Z - op.Z
				local dSq = dx * dx + dz * dz
				if dSq < 20.25 and dSq > 0.0004 then -- 4.5^2 = 20.25
					local d = math.sqrt(dSq)
					local push = ((4.5 - d) / 4.5)
					sepX += (dx / d) * push
					sepZ += (dz / d) * push
				elseif dSq <= 0.0004 and math.abs(curPos.Y - op.Y) < 8 then
					local ang = ((tonumber(e.SpawnSerial) or i) * 2.39996)
					sepX += math.cos(ang) * 0.85
					sepZ += math.sin(ang) * 0.85
				end
			end
		end
	end

	local moveVec = _V3(0, 0, 0)
	if distGoal > 0.35 then
		moveVec = toGoal.Unit
	end
	local combined = _V3(moveVec.X + sepX * 1.15, 0, moveVec.Z + sepZ * 1.15)
	if combined.Magnitude < 0.04 then
		return nil
	end

	local stepLen = math.min(math.max(distGoal, math.sqrt(sepX * sepX + sepZ * sepZ) * 3.2), speed * dt)
	if stepLen < 0.01 then
		return nil
	end
	local stepDir = combined.Unit
	local bodyHalfY = e.Body.Size.Y * 0.5
	local curFloorY = curPos.Y - bodyHalfY
	local bodyRad = math.clamp(math.max(e.Body.Size.X, e.Body.Size.Z) * 0.45, 1.4, 4.2)
	local isFlying = (e.Config and e.Config.CanFly == true)

	local function tryCandidate(dirVec, len)
		local nx = curPos.X + dirVec.X * len
		local nz = curPos.Z + dirVec.Z * len
		-- 1. Solid3DObstacles AABB check
		if W and W.IsBlockedByObstacle and W.IsBlockedByObstacle(nx, curFloorY, nz, bodyRad) then
			return nil
		end
		-- 2. Horizontal wall / Solid3DObstacle raycast check
		local rp = getStaticWorldRayParams()
		local wallHit = workspace:Raycast(_V3(curPos.X, curFloorY + 2.2, curPos.Z), _V3(dirVec.X, 0, dirVec.Z) * (len + bodyRad), rp)
		if wallHit and wallHit.Instance and wallHit.Instance.CanCollide then
			return nil
		end
		-- 3. Cliff / Sky-Island Ledge Ground Raycast check
		if not isFlying and W and W.RaycastGround then
			local gHit = W.RaycastGround(_V3(nx, curFloorY + 8, nz), curFloorY)
			if not gHit or gHit.Position.Y < 10 or math.abs(gHit.Position.Y - curFloorY) > 9.0 then
				return nil
			end
			return _V3(nx, gHit.Position.Y + bodyHalfY, nz)
		end
		local ny = isFlying and (curPos.Y + math.clamp(goalPos.Y - curPos.Y, -speed * dt * 0.6, speed * dt * 0.6)) or curPos.Y
		return _V3(nx, ny, nz)
	end

	local nextPos = tryCandidate(stepDir, stepLen)
	if not nextPos then
		-- Slide along tangent X or Z around obstacle/cliff
		local slideA = _V3(-stepDir.Z, 0, stepDir.X)
		local slideB = _V3(stepDir.Z, 0, -stepDir.X)
		if slideA:Dot(moveVec) < slideB:Dot(moveVec) then
			slideA, slideB = slideB, slideA
		end
		nextPos = tryCandidate(slideA, stepLen * 0.75) or tryCandidate(slideB, stepLen * 0.75)
	end
	if not nextPos then
		return nil
	end

	local facePos = _V3(goalPos.X, nextPos.Y, goalPos.Z)
	if (facePos - nextPos).Magnitude < 0.15 then
		facePos = nextPos + _V3(stepDir.X, 0, stepDir.Z)
	end
	return _lookAt(nextPos, facePos)
end

function Helpers.ExecuteForgeEnhance(p, profile, payload, G, C, LiveOps)
	local targetId = tostring((payload and payload.itemId) or profile.Weapon or "")
	if targetId ~= "" and (profile.Inventory[targetId] or 0) <= 0 and profile.Weapon ~= targetId and profile.EquippedGun ~= targetId then
		LiveOps.Notify(G, p, "Hãy rèn sở hữu vũ khí trước khi Cường Hóa!", "Craft or own this weapon before enhancing!")
		return false
	end
	local cur = math.clamp(math.floor(tonumber(profile.WeaponEnhance) or 0), 0, 15)
	if cur >= 15 then
		LiveOps.Notify(G, p, "Vũ khí đã đạt cấp cường hóa tối đa (+15)!", "Weapon has reached max enhancement (+15)!")
		return false
	end
	local nextPlus = cur + 1
	local costCfg = (C.GetForgeUpgradeCost and C.GetForgeUpgradeCost(nextPlus)) or {
		Gold = 5000 * nextPlus,
		Shards = 20 * nextPlus,
		Materials = math.ceil(nextPlus / 2),
		Rate = 100,
		PityGain = 15,
	}
	local reqGold = math.max(0, tonumber(costCfg.Gold) or 0)
	local reqShards = math.max(0, tonumber(costCfg.Shards) or 0)
	local reqMats = math.max(1, tonumber(costCfg.Materials) or 1)
	local availUpg = math.max(0, tonumber(profile.Inventory.upgrade_material) or 0)
	local availIron = math.max(0, tonumber(profile.Inventory.SkyIron) or 0)
	if (tonumber(profile.Gold) or 0) < reqGold or (tonumber(profile.CoreShards) or 0) < reqShards or (availUpg + availIron) < reqMats then
		LiveOps.Notify(
			G,
			p,
			string.format("Cường hóa +%d cần %d Gold, %d Tinh Thạch & %d Khoáng Thạch/Vật Liệu!", nextPlus, reqGold, reqShards, reqMats),
			string.format("+%d Enhancement requires %d Gold, %d Core Shards & %d Sky Iron/Upgrade Mat!", nextPlus, reqGold, reqShards, reqMats)
		)
		return false
	end
	profile.Gold -= reqGold
	profile.CoreShards -= reqShards
	local takeUpg = math.min(availUpg, reqMats)
	profile.Inventory.upgrade_material = availUpg - takeUpg
	profile.Inventory.SkyIron = availIron - (reqMats - takeUpg)
	local pity = math.clamp(math.floor(tonumber(profile.EnhancePity) or 0), 0, 100)
	local effRate = math.min(100, (tonumber(costCfg.Rate) or 100) + pity)
	if effRate >= 100 or math.random(1, 100) <= effRate then
		profile.WeaponEnhance = nextPlus
		profile.EnhancePity = 0
		profile.Upgrades = type(profile.Upgrades) == "table" and profile.Upgrades or {}
		if targetId ~= "" then
			profile.Upgrades[targetId] = nextPlus
		end
		LiveOps.Notify(
			G,
			p,
			string.format("Cường hóa thành công: +%d (+%d%% ATK Vũ Khí)!", nextPlus, nextPlus * 6),
			string.format("Enhancement succeeded: +%d (+%d%% Weapon ATK)!", nextPlus, nextPlus * 6)
		)
	else
		profile.EnhancePity = math.min(100, pity + (tonumber(costCfg.PityGain) or 15))
		LiveOps.Notify(
			G,
			p,
			string.format("Cường hóa +%d thất bại (Không tụt cấp! Bảo hiểm Pity: +%d%%)!", nextPlus, profile.EnhancePity),
			string.format("+%d Enhancement missed (No downgrade! Pity bonus: +%d%%)!", nextPlus, profile.EnhancePity)
		)
	end
	return true
end

function Helpers.ExecuteRefundStats(p, profile, ensureProfileFields, G, C, LiveOps)
	local refund = 0
	for _, v in pairs(profile.StatAlloc) do
		if type(v) == "number" and v > 1 then
			refund += (v - 1)
		end
	end
	if refund <= 0 then
		LiveOps.Notify(G, p, "Chưa có Điểm Chỉ Số nào cần đặt lại!", "No allocated Stat Points to reset!")
		return false
	end
	local shardCost = tonumber(C.StatRefundCostShards) or 150
	local tokens = math.max(0, math.floor(tonumber(profile.StatRefundTokens) or 0))
	if tokens > 0 then
		profile.StatRefundTokens = tokens - 1
	elseif (tonumber(profile.CoreShards) or 0) >= shardCost then
		profile.CoreShards = (tonumber(profile.CoreShards) or 0) - shardCost
	else
		LiveOps.Notify(
			G,
			p,
			string.format("Cần 1 Thẻ Đặt Lại Chỉ Số hoặc %d Tinh Thạch để tẩy điểm!", shardCost),
			string.format("Requires 1 Stat Refund Token or %d Core Shards to reset stats!", shardCost)
		)
		return false
	end
	for k, v in pairs(profile.StatAlloc) do
		if type(v) == "number" and v > 1 then
			profile.StatAlloc[k] = 1
		end
	end
	profile.StatPoints = (profile.StatPoints or 0) + refund
	if ensureProfileFields then
		ensureProfileFields(profile)
	end
	LiveOps.Notify(G, p, "Đã hoàn trả " .. tostring(profile.StatPoints) .. " Điểm Chỉ Số (Stat Points)!", "Refunded " .. tostring(profile.StatPoints) .. " Stat Points!")
	return true
end

return Helpers
