local Players = game:GetService("Players")
local DSS = game:GetService("DataStoreService")
local Http = game:GetService("HttpService")
local Run = game:GetService("RunService")
local C = require(game.ReplicatedStorage.Shared.Config)

local D = {
	Sessions = {},
	Loading = {},
	StudioSessionCache = {},
}

local PERMANENT_STARTER_GEAR = {
	-- Chỉ phát đồ khởi đầu. Đồ cao cấp phải kiếm trong game; muốn thử đồ thì dùng Dev Sandbox trong Studio.
	starter_sword = 1,
	starter_daggers = 1,
	starter_staff = 1,
	aether_flintlock = 1,
}

local function cleanNum(v, minV, maxV, fallback, doFloor)
	if type(v) ~= "number" or v ~= v or v == math.huge or v == -math.huge then
		return fallback
	end
	if doFloor ~= false then
		v = math.floor(v)
	end
	if minV ~= nil and v < minV then
		v = minV
	end
	if maxV ~= nil and v > maxV then
		v = maxV
	end
	return v
end

local function sanitizeForDataStore(val, depth)
	depth = (depth or 0) + 1
	if depth > 14 then
		return nil
	end
	local tv = type(val)
	if tv == "nil" or tv == "boolean" then
		return val
	elseif tv == "number" then
		if val ~= val or val == math.huge or val == -math.huge then
			return 0
		end
		return val
	elseif tv == "string" then
		return val
	elseif tv ~= "table" then
		return nil
	end

	local totalKeys = 0
	local allPositiveInts = true
	local maxIntKey = 0
	for k in pairs(val) do
		totalKeys += 1
		if type(k) == "number" and k >= 1 and k == math.floor(k) and k ~= math.huge then
			if k > maxIntKey then
				maxIntKey = k
			end
		else
			allPositiveInts = false
		end
	end
	if totalKeys == 0 then
		return {}
	end

	local out = {}
	if allPositiveInts and maxIntKey == totalKeys then
		for i = 1, totalKeys do
			local sv = sanitizeForDataStore(val[i], depth)
			out[i] = (sv ~= nil) and sv or false
		end
	else
		for k, v in pairs(val) do
			local sk = (type(k) == "string") and k or tostring(k)
			if sk ~= "" then
				local sv = sanitizeForDataStore(v, depth)
				if sv ~= nil then
					out[sk] = sv
				end
			end
		end
	end
	return out
end

local persistent = not Run:IsStudio() or C.StudioPersistence
local okStore, store = pcall(function()
	return persistent and DSS:GetDataStore(C.StoreName) or nil
end)
if not okStore or not store then
	persistent = false
	store = nil
end
local token = game.JobId .. ":" .. Http:GenerateGUID(false)

local function clone(t)
	if type(t) ~= "table" then
		return t
	end
	local copy = {}
	for k, v in pairs(t) do
		copy[k] = clone(v)
	end
	return copy
end

local function defaultSkillLevels()
	local levels = {}
	for skillId in pairs(C.SkillNames) do
		levels[skillId] = 1
	end
	return levels
end

local function defaults()
	return {
		SchemaVersion = 1,
		StarterGrantDone = true,
		Level = 1,
		XP = 0,
		Gold = 300,
		CoreShards = 50,
		SkillPoints = 1,
		StatPoints = 0,
		StatAlloc = {
			Melee = 1,
			Defense = 1,
			Sword = 1,
			Gun = 1,
			Fruit = 1,
		},
		Potions = 4,
		DailyClaimed = 0,
		PartySize = "Solo",
		WeaponEnhance = 0,
		EnhancePity = 0,
		WeaponStars = {},
		StarPity = {},
		WeaponEnchants = {},
		StatPresets = {},
		ClassId = "SkyGuardian",
		Gender = "Male",
		ActiveSlot = 3, -- 1=FightingStyle, 2=AetherFruit, 3=Sword, 4=Gun
		FightingStyle = "SkybornCombat",
		UnlockedStyles = {
			SkybornCombat = true,
			SkyStep = true,
			ElectricClaw = true,
			GlacialKarate = true,
			AshuraStep = true,
			JadeDragonTalon = true,
			AbyssalTalon = true,
			ChronoVoidPalm = true,
		},
		EquippedFruit = "GaleCore",
		HeldFruit = "",
		StoredFruits = {
			GaleCore = 1,
			SolarFlameCore = 1,
			ThunderRumbleCore = 1,
			GlacierIceCore = 1,
			AetherWindCore = 1,
			AstralGravityCore = 1,
			MagmaBurstCore = 1,
			AbyssalDarkCore = 1,
			CelestialLightCore = 1,
			DimensionalPortalCore = 1,
			SolarTitanCore = 1,
			AetherflowCore = 1,
			AbyssalSovereignCore = 1,
		},
		AwakenedFruits = {},
		EquippedGun = "aether_flintlock",
		Mastery = {
			SkybornCombat = 300,
			GaleCore = 300,
			starter_sword = 300,
			starter_daggers = 300,
			starter_staff = 300,
			aether_flintlock = 300,
			sunshard_halberd = 300,
			cyber_katana_mk2 = 300,
			sylvaris_thornblade = 300,
			ignivar_magma_breaker = 300,
			nerith_abyssal_trident = 300,
			aion_chrono_scythe = 300,
			architect_severance = 300,
			eternal_frost_staff = 300,
			sylvaris_thornbow = 300,
			ignivar_hellcannon = 300,
			aion_chrono_pistols = 300,
			veyr_singularity_cannon = 300,
			kabucha_wind = 300,
			bizarre_rifle_cyber = 300,
		},
		MasteryXP = {},
		MasteryMilestones = {},
		Haki = {
			Aura = false,
			AuraStage = 1,
			Instinct = false,
			InstinctDodges = 8,
			MaxDodges = 8,
			ConquerorUnlocked = false,
		},
		HakiStage = 0,
		HakiEXP = 0,
		HakiColorId = "crimson_conqueror",
		UnlockedHakiColors = {
			crimson_conqueror = true,
		},
		KenEXP = 0,
		KenV2Unlocked = false,
		Race = "Skyborn",
		RaceTier = 1,
		RaceV4Active = false,
		RaceV4Unlocked = false,
		CoreGears = 0,
		AwakeningMeter = 0,
		DoubleExpUntil = 0,
		RedeemedCodes = {},
		FreeFruitVouchers = 0,
		StatRefundTokens = 0,
		Faction = "Pirate",
		Bounty = 0,
		Honor = 0,
		Title = "Skyborn Novice",
		UnlockedTitles = {
			["Skyborn Novice"] = true,
			sky_rookie = true,
		},
		ActiveShip = "CelestialAetherGalleon",
		UnlockedShips = {
			SkySloop = true,
			CelestialBrigantine = true,
			CelestialAetherGalleon = true,
		},
		Transformed = false,
		TransformId = nil,
		HomeIsland = "SkyHub",
		Loadouts = {
			SkyGuardian = "starter_sword",
			ThunderStriker = "starter_daggers",
			ArcaneMage = "starter_staff",
		},
		SkillLevels = defaultSkillLevels(),
		Equipped = {
			Weapon = "starter_sword",
		},
		QuestIndex = 1,
		Accepted = true,
		Progress = {},
		CompletedQuests = {},
		Inventory = clone(PERMANENT_STARTER_GEAR),
		Weapon = "starter_sword",
		FirstClearBosses = {},
		UnlockedWorlds = {
			SkyHub = true,
			GoldenSky = true,
			FrozenCyber = false,
			ShadowRealm = false,
			VerdantCrown = false,
			EmberforgeWastes = false,
			AbyssalTides = false,
			ChronosBastion = false,
			VeilsEnd = false,
		},
		DiscoveredPortals = {},
		CurrentWorldOrder = 1,
		CollectedLore = {},
		LoginStreak = 1,
		LastLoginDay = 0,
		DailyClaimedDay = 0,
		DailyTasks = {},
		Achievements = {},
		HighestSpireFloor = 0,
		LeviathanHearts = 0,
		CrewName = "",
		CrewTag = "",
		CrewColor = "255,210,80",
	}
end

D.Default = defaults

local TABLE_FIELDS = {
	"WeaponStars",
	"StarPity",
	"WeaponEnchants",
	"StatPresets",
	"MasteryXP",
	"MasteryMilestones",
	"UnlockedHakiColors",
	"RedeemedCodes",
	"DiscoveredPortals",
	"CollectedLore",
	"DailyTasks",
	"Achievements",
	"Progress",
	"CompletedQuests",
	"FirstClearBosses",
}

local function hydrate(p)
	if type(p) ~= "table" then
		return defaults()
	end
	local def = defaults()
	local isLegacyUnseeded = (p.StarterGrantDone == nil and p.StoredFruits == nil and p.Inventory == nil)
	for k, v in pairs(def) do
		if p[k] == nil then
			p[k] = clone(v)
		end
	end

	p.SchemaVersion = 1
	p.StarterGrantDone = true
	p.ClassId = (type(p.ClassId) == "string" and C.Classes[p.ClassId]) and p.ClassId or def.ClassId
	p.Level = cleanNum(p.Level, 1, C.MaxLevel, def.Level)
	p.XP = cleanNum(p.XP, 0, 1e15, def.XP)
	p.Gold = cleanNum(p.Gold, 0, 1e15, def.Gold)
	p.CoreShards = cleanNum(p.CoreShards, 0, 1e15, def.CoreShards)
	p.Potions = cleanNum(p.Potions, 0, 9999, def.Potions)
	p.QuestIndex = cleanNum(p.QuestIndex, 1, math.max(1, #C.Quests + 1), def.QuestIndex)
	p.Accepted = (p.Accepted ~= false)
	p.Gender = (p.Gender == "Female") and "Female" or "Male"
	p.PartySize = type(p.PartySize) == "string" and p.PartySize or "Solo"
	p.ActiveSlot = cleanNum(p.ActiveSlot, 1, 4, 3)
	p.StatPoints = cleanNum(p.StatPoints, 0, 1e6, def.StatPoints)
	p.SkillPoints = cleanNum(p.SkillPoints, 0, 1e6, def.SkillPoints)
	p.WeaponEnhance = cleanNum(p.WeaponEnhance, 0, 15, 0)
	p.EnhancePity = cleanNum(p.EnhancePity, 0, 100, 0)

	for _, tKey in ipairs(TABLE_FIELDS) do
		if type(p[tKey]) ~= "table" then
			p[tKey] = clone(def[tKey] or {})
		end
	end

	local cleanStars = {}
	for wid, st in pairs(p.WeaponStars) do
		local sk = type(wid) == "string" and wid or tostring(wid)
		if sk ~= "" then
			cleanStars[sk] = cleanNum(st, 1, 5, 1)
		end
	end
	p.WeaponStars = cleanStars

	local cleanStarPity = {}
	for wid, pt in pairs(p.StarPity) do
		local sk = type(wid) == "string" and wid or tostring(wid)
		if sk ~= "" then
			cleanStarPity[sk] = cleanNum(pt, 0, 100, 0)
		end
	end
	p.StarPity = cleanStarPity

	p.StatAlloc = type(p.StatAlloc) == "table" and p.StatAlloc or clone(def.StatAlloc)
	for statKey, defVal in pairs(def.StatAlloc) do
		p.StatAlloc[statKey] = cleanNum(p.StatAlloc[statKey], 1, 2550, defVal)
	end

	p.FightingStyle = (type(p.FightingStyle) == "string" and p.FightingStyle ~= "") and p.FightingStyle or def.FightingStyle
	p.UnlockedStyles = type(p.UnlockedStyles) == "table" and p.UnlockedStyles or clone(def.UnlockedStyles)
	for styleId, unlocked in pairs(def.UnlockedStyles) do
		if p.UnlockedStyles[styleId] == nil then
			p.UnlockedStyles[styleId] = unlocked
		end
	end

	p.EquippedFruit = type(p.EquippedFruit) == "string" and p.EquippedFruit or def.EquippedFruit
	p.HeldFruit = type(p.HeldFruit) == "string" and p.HeldFruit or ""
	p.StoredFruits = type(p.StoredFruits) == "table" and p.StoredFruits or {}
	local cleanFruits = {}
	for fruitId, count in pairs(p.StoredFruits) do
		if type(fruitId) == "string" and fruitId ~= "" then
			local c = cleanNum(count, 0, 9999, 0)
			if c > 0 then
				cleanFruits[fruitId] = c
			end
		end
	end
	for fruitId, count in pairs(def.StoredFruits) do
		if (cleanFruits[fruitId] or 0) < count then
			cleanFruits[fruitId] = count
		end
	end
	p.StoredFruits = cleanFruits

	p.AwakenedFruits = type(p.AwakenedFruits) == "table" and p.AwakenedFruits or clone(def.AwakenedFruits)
	p.EquippedGun = (type(p.EquippedGun) == "string" and p.EquippedGun ~= "") and p.EquippedGun or def.EquippedGun

	p.Mastery = type(p.Mastery) == "table" and p.Mastery or clone(def.Mastery)
	local cleanMastery = {}
	for key, val in pairs(p.Mastery) do
		local sk = type(key) == "string" and key or tostring(key)
		if sk ~= "" then
			cleanMastery[sk] = cleanNum(val, 1, 600, 1)
		end
	end
	for key, val in pairs(def.Mastery) do
		if cleanMastery[key] == nil then
			cleanMastery[key] = val
		end
	end
	p.Mastery = cleanMastery

	p.Haki = type(p.Haki) == "table" and p.Haki or clone(def.Haki)
	for k, v in pairs(def.Haki) do
		if p.Haki[k] == nil then
			p.Haki[k] = v
		end
	end
	p.Haki.InstinctDodges = cleanNum(p.Haki.InstinctDodges, 0, 8, 8)
	p.Haki.MaxDodges = cleanNum(p.Haki.MaxDodges, 1, 12, 8)
	p.HakiStage = cleanNum(p.HakiStage, 0, 5, 0)
	p.HakiEXP = cleanNum(p.HakiEXP, 0, 1e12, 0)
	p.HakiColorId = (type(p.HakiColorId) == "string" and p.HakiColorId ~= "") and p.HakiColorId or def.HakiColorId
	p.UnlockedHakiColors.crimson_conqueror = true
	p.KenEXP = cleanNum(p.KenEXP, 0, 1e12, 0)
	p.KenV2Unlocked = p.KenV2Unlocked == true

	p.Race = (type(p.Race) == "string" and p.Race ~= "") and p.Race or def.Race
	p.RaceTier = cleanNum(p.RaceTier, 1, 4, def.RaceTier)
	p.RaceV4Active = p.RaceV4Active == true
	p.RaceV4Unlocked = p.RaceV4Unlocked == true
	p.CoreGears = cleanNum(p.CoreGears, 0, 9999, 0)
	p.AwakeningMeter = cleanNum(p.AwakeningMeter, 0, 100, 0, false)
	p.DoubleExpUntil = cleanNum(p.DoubleExpUntil, 0, 4e9, 0)
	p.FreeFruitVouchers = cleanNum(p.FreeFruitVouchers, 0, 9999, 0)
	p.StatRefundTokens = cleanNum(p.StatRefundTokens, 0, 9999, 0)

	p.Faction = (p.Faction == "Marine") and "Marine" or "Pirate"
	p.Bounty = cleanNum(p.Bounty, 0, 1e15, def.Bounty)
	p.Honor = cleanNum(p.Honor, 0, 1e15, def.Honor)
	p.Title = type(p.Title) == "string" and p.Title or def.Title
	p.UnlockedTitles = type(p.UnlockedTitles) == "table" and p.UnlockedTitles or clone(def.UnlockedTitles)
	p.ActiveShip = (type(p.ActiveShip) == "string" and p.ActiveShip ~= "") and p.ActiveShip or def.ActiveShip
	p.UnlockedShips = type(p.UnlockedShips) == "table" and p.UnlockedShips or clone(def.UnlockedShips)
	p.UnlockedShips.SkySloop = true
	p.UnlockedShips.CelestialAetherGalleon = true
	p.Transformed = p.Transformed == true
	p.HomeIsland = (type(p.HomeIsland) == "string" and p.HomeIsland ~= "") and p.HomeIsland or "SkyHub"

	p.Loadouts = type(p.Loadouts) == "table" and p.Loadouts or clone(def.Loadouts)
	for classId, weaponId in pairs(def.Loadouts) do
		if type(p.Loadouts[classId]) ~= "string" or p.Loadouts[classId] == "" then
			p.Loadouts[classId] = weaponId
		end
	end
	p.SkillLevels = type(p.SkillLevels) == "table" and p.SkillLevels or {}
	for skillId in pairs(C.SkillNames) do
		p.SkillLevels[skillId] = cleanNum(p.SkillLevels[skillId], 1, 999, 1)
	end

	p.Inventory = type(p.Inventory) == "table" and p.Inventory or {}
	local cleanInv = {}
	for itemId, count in pairs(p.Inventory) do
		if type(itemId) == "string" and itemId ~= "" then
			local c = cleanNum(count, 0, 1e9, 0)
			if c > 0 then
				cleanInv[itemId] = c
			end
		end
	end
	for gearId, minCount in pairs(PERMANENT_STARTER_GEAR) do
		if (cleanInv[gearId] or 0) < minCount then
			cleanInv[gearId] = minCount
		end
	end
	if isLegacyUnseeded then
		for itemId, count in pairs(def.Inventory) do
			if cleanInv[itemId] == nil then
				cleanInv[itemId] = count
			end
		end
	end
	p.Inventory = cleanInv

	p.Equipped = type(p.Equipped) == "table" and p.Equipped or clone(def.Equipped)
	for eqSlot, defItemId in pairs(def.Equipped) do
		if type(p.Equipped[eqSlot]) ~= "string" or p.Equipped[eqSlot] == "" then
			p.Equipped[eqSlot] = defItemId
		end
	end
	if type(p.Weapon) ~= "string" or p.Weapon == "" then
		p.Weapon = (type(p.Equipped.Weapon) == "string" and p.Equipped.Weapon ~= "") and p.Equipped.Weapon or def.Weapon
	end
	if type(p.Equipped.Weapon) ~= "string" or p.Equipped.Weapon == "" then
		p.Equipped.Weapon = p.Weapon
	end

	local rawWorlds = type(p.UnlockedWorlds) == "table" and p.UnlockedWorlds or clone(def.UnlockedWorlds)
	local cleanWorlds = {}
	for wk, wv in pairs(rawWorlds) do
		if type(wk) == "string" and wk ~= "" then
			cleanWorlds[wk] = (wv == true)
		elseif type(wk) == "number" and C.Islands and C.Islands[wk] and type(C.Islands[wk].Id) == "string" then
			cleanWorlds[C.Islands[wk].Id] = (wv == true)
		end
	end
	for wk, wv in pairs(def.UnlockedWorlds) do
		if cleanWorlds[wk] == nil then
			cleanWorlds[wk] = wv
		end
	end
	cleanWorlds.SkyHub = true
	cleanWorlds.GoldenSky = true
	p.UnlockedWorlds = cleanWorlds

	p.LoginStreak = cleanNum(p.LoginStreak, 1, 7, 1)
	p.LastLoginDay = cleanNum(p.LastLoginDay, 0, 1e9, 0)
	p.DailyClaimedDay = cleanNum(p.DailyClaimedDay, 0, 1e9, 0)
	p.HighestSpireFloor = cleanNum(p.HighestSpireFloor, 0, 50, 0)
	p.LeviathanHearts = cleanNum(p.LeviathanHearts, 0, 1e6, 0)
	p.CrewName = type(p.CrewName) == "string" and p.CrewName:sub(1, 32) or ""
	p.CrewTag = type(p.CrewTag) == "string" and p.CrewTag:sub(1, 6) or ""
	p.CrewColor = (type(p.CrewColor) == "string" and p.CrewColor ~= "") and p.CrewColor or "255,210,80"
	p.CurrentWorldOrder = cleanNum(p.CurrentWorldOrder, 1, 20, 1)

	return sanitizeForDataStore(p, 0)
end

local function valid(p)
	if type(p) ~= "table" or p.SchemaVersion ~= 1 then
		return false
	end
	for _, key in ipairs({"Level", "XP", "Gold", "QuestIndex", "CoreShards", "Bounty", "Honor"}) do
		local v = p[key]
		if v ~= nil and (type(v) ~= "number" or v ~= v or v < 0 or v > 1e15) then
			return false
		end
	end
	if type(p.Level) ~= "number" or p.Level < 1 or p.Level > C.MaxLevel then
		return false
	end
	if type(p.QuestIndex) ~= "number" or p.QuestIndex < 1 or p.QuestIndex > math.max(#C.Quests + 10, 100) then
		return false
	end
	for _, key in ipairs({"Progress", "CompletedQuests", "Inventory", "FirstClearBosses", "UnlockedWorlds"}) do
		if type(p[key]) ~= "table" then
			return false
		end
	end
	for _, tKey in ipairs(TABLE_FIELDS) do
		if p[tKey] ~= nil and type(p[tKey]) ~= "table" then
			return false
		end
	end
	if not C.Classes[p.ClassId] or type(p.Accepted) ~= "boolean" then
		return false
	end
	if p.Gender ~= nil and p.Gender ~= "Male" and p.Gender ~= "Female" then
		return false
	end
	for _, optTable in ipairs({"Loadouts", "Equipped", "SkillLevels", "StatAlloc", "StoredFruits", "AwakenedFruits", "Mastery", "Haki", "UnlockedStyles", "UnlockedTitles", "UnlockedShips"}) do
		if p[optTable] ~= nil and type(p[optTable]) ~= "table" then
			return false
		end
	end
	for k, v in pairs(p.Inventory) do
		if type(k) ~= "string" or type(v) ~= "number" or v ~= v or v < 0 or v > 1e9 then
			return false
		end
	end
	if p.Weapon ~= nil and type(p.Weapon) ~= "string" then
		return false
	end
	return true
end

D.Hydrate = hydrate
D.Valid = valid
D.Sanitize = sanitizeForDataStore

local function retry(fn)
	for n = 1, 3 do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		warn("[SKYBREAK] DataStore attempt", n, result)
		if n < 3 then
			task.wait(2 ^ (n - 1) + math.random())
		end
	end
	return false, nil
end

function D.Load(player)
	if not player then
		return nil
	end
	if D.Sessions[player] and D.Sessions[player].Active then
		return D.Sessions[player].Profile
	end
	local uid = player.UserId
	local waitDeadline = os.clock() + 12
	while D.Loading[uid] and os.clock() < waitDeadline do
		task.wait(0.1)
	end
	if D.Sessions[player] and D.Sessions[player].Active then
		return D.Sessions[player].Profile
	end
	D.Loading[uid] = true

	local cached = D.StudioSessionCache[uid]
	local profile = cached and hydrate(clone(cached)) or hydrate(defaults())
	local expires = os.time() + C.LeaseSeconds
	local loadedFromStore = false
	local loadedFromStudioCache = (cached ~= nil)

	if persistent and store then
		for lockTry = 1, 2 do
			local lockHeldByOther = false
			local ok, record = retry(function()
				return store:UpdateAsync("u_" .. uid, function(old)
					local nowSec = os.time()
					if lockTry == 1 and type(old) == "table" and old.Owner ~= nil and old.Owner ~= token and (tonumber(old.Expires) or 0) > nowSec then
						lockHeldByOther = true
						return nil
					end
					local rawData = (type(old) == "table" and type(old.Data) == "table") and clone(old.Data)
						or (cached and clone(cached))
						or defaults()
					local migrated = hydrate(rawData)
					if not valid(migrated) then
						warn("[SKYBREAK] Repaired invalid profile fields for", player.Name)
						migrated = hydrate(migrated)
					end
					return {
						Data = migrated,
						Owner = token,
						Expires = nowSec + C.LeaseSeconds,
					}
				end)
			end)
			if lockHeldByOther and lockTry == 1 then
				task.wait(1.5)
			else
				if ok and type(record) == "table" and type(record.Data) == "table" then
					profile = hydrate(record.Data)
					expires = record.Expires or expires
					loadedFromStore = true
				else
					warn("[SKYBREAK] Falling back to protected in-memory profile for", player.Name)
				end
				break
			end
		end
	end

	profile = hydrate(profile)
	if Run:IsStudio() or not persistent then
		D.StudioSessionCache[uid] = clone(profile)
	end

	local readOnlyFallback = (persistent and store ~= nil and not loadedFromStore and not loadedFromStudioCache)
	local statusText = "Studio Cache"
	if loadedFromStore then
		statusText = "Đã tải"
	elseif readOnlyFallback then
		statusText = "Tạm lưu bộ nhớ (Bảo vệ)"
	elseif persistent then
		statusText = "Tạm lưu bộ nhớ"
	elseif loadedFromStudioCache then
		statusText = "Studio Cache (Phục hồi)"
	end

	D.Sessions[player] = {
		Profile = profile,
		Expires = expires,
		Busy = false,
		Active = true,
		Releasing = false,
		ReadOnlyFallback = readOnlyFallback,
		SaveStatus = statusText,
	}
	D.Loading[uid] = nil

	if player.Parent ~= Players then
		D.Release(player)
		return nil
	end
	return profile
end

function D.Get(player)
	local s = D.Sessions[player]
	if not s or not s.Active then
		return nil
	end
	if persistent and os.time() >= s.Expires then
		s.Expires = os.time() + C.LeaseSeconds
	end
	return s.Profile
end

function D.Save(player, release)
	local s = D.Sessions[player]
	if not s then
		return false
	end
	local waitStart = os.clock()
	while s.Busy and (os.clock() - waitStart) < 15 do
		task.wait(0.1)
	end
	if not s.Active then
		return false
	end
	s.Busy = true

	local hydratedSnapshot = hydrate(clone(s.Profile))
	if Run:IsStudio() or not persistent then
		D.StudioSessionCache[player.UserId] = hydratedSnapshot
	end

	if not persistent or not store then
		s.SaveStatus = "Studio Cache"
		s.Busy = false
		return true
	end

	local lockStolen = false
	local blockedClobber = false
	local ok, record = retry(function()
		return store:UpdateAsync("u_" .. player.UserId, function(old)
			local nowSec = os.time()
			if type(old) == "table" then
				if old.Owner ~= nil and old.Owner ~= token and (tonumber(old.Expires) or 0) > nowSec then
					lockStolen = true
					return nil
				end
				if s.ReadOnlyFallback and type(old.Data) == "table" then
					local cloudLv = tonumber(old.Data.Level) or 1
					local localLv = tonumber(hydratedSnapshot.Level) or 1
					local cloudGold = tonumber(old.Data.Gold) or 0
					local localGold = tonumber(hydratedSnapshot.Gold) or 0
					if cloudLv > localLv or cloudGold > localGold then
						blockedClobber = true
						return nil
					end
				end
			end
			return {
				Data = hydratedSnapshot,
				Owner = not release and token or nil,
				Expires = not release and (nowSec + C.LeaseSeconds) or 0,
			}
		end)
	end)

	if lockStolen then
		warn("[SKYBREAK] Session lock superseded by newer server for", player.Name)
		s.SaveStatus = "Phiên khác đang mở"
		s.Active = false
		s.Busy = false
		return false
	end
	if blockedClobber then
		warn("[SKYBREAK] Protected cloud save from fallback overwrite for", player.Name)
		s.SaveStatus = "Bảo vệ dữ liệu gốc"
		s.Busy = false
		return false
	end

	local saved = ok and type(record) == "table" and record.Data ~= nil and (release or record.Owner == token)
	if saved then
		s.ReadOnlyFallback = false
		s.Expires = record.Expires or (os.time() + C.LeaseSeconds)
		s.SaveStatus = "Đã lưu"
		if release and not Run:IsStudio() then
			D.StudioSessionCache[player.UserId] = nil
		end
	else
		D.StudioSessionCache[player.UserId] = hydratedSnapshot
		s.SaveStatus = "Tạm lưu bộ nhớ"
	end
	s.Busy = false
	return saved == true
end

function D.Release(player)
	if player then
		D.Loading[player.UserId] = nil
	end
	local s = D.Sessions[player]
	if not s or s.Releasing then
		return
	end
	s.Releasing = true
	D.Save(player, true)
	s.Active = false
	D.Sessions[player] = nil
end

function D.Start()
	task.spawn(function()
		while true do
			task.wait(C.AutosaveSeconds)
			for player, s in pairs(D.Sessions) do
				if s.Active and not s.Releasing then
					task.spawn(D.Save, player, false)
				end
			end
		end
	end)
	game:BindToClose(function()
		if not persistent or not store then
			for player in pairs(D.Sessions) do
				D.Release(player)
			end
			return
		end
		local count = 0
		for player in pairs(D.Sessions) do
			count += 1
			task.spawn(function()
				D.Release(player)
				count -= 1
			end)
		end
		local deadline = os.clock() + 25
		while count > 0 and os.clock() < deadline do
			task.wait(0.05)
		end
	end)
end

return D
