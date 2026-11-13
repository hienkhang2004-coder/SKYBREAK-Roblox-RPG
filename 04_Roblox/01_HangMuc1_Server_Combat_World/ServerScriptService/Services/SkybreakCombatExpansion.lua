-- SkybreakCombatExpansion.lua
-- Modular authoritative server implementation for SKYBREAK Wave 2 Combat,
-- 5 Martial Arts Styles, Mastery (1..600), 12-Fruit Awakened V2 Movesets,
-- Charged Greatsword Crescent Slash, Aimed Raycast Gunplay (Soul Guitar & Cryo Railgun),
-- Mirage Hourly Stock Dealer, 4-Chair Cafe Fruit Trading (40% Lock + 5s Countdown),
-- Logia Elemental Reflex, Water/Ice/Magma Platforms, Drop 3D Fruit,
-- 2-Tier 50%/100% Dragon Fury, Portal [C] World Warp, Temple of the Core Race V4 Trial,
-- 6 Race V4 Passives, DrVega Reroll, 5-Stage Busoshoku Haki + 8 Aura Skins, Ken V2 Inspector,
-- Bounty/Honor (0..30M), 10M Allied SkySeaBeast Guardian, 34 Glowing Titles,
-- Boss 100% Break Gauge (4.5s Kneel + 1.5x DMG), Server Sanity Checks, and Wave 1 UI Handlers.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local CombatData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SkybreakCombatData"))
local DevGate = require(script.Parent:WaitForChild("DevGate"))
local RemoteGuard = require(script.Parent:WaitForChild("RemoteGuard"))
local Helpers = require(script.Parent:WaitForChild("GameExperienceHelpers"))
local WildCoreService = require(script.Parent:WaitForChild("SkybreakWildCoreService"))
local SkillMechanics = require(script.Parent:WaitForChild("SkybreakSkillMechanicsService"))

local function getMaxCoreStorage(plr, prof)
	if Helpers and type(Helpers.GetMaxCoreStorage) == "function" then
		local ok, cap = pcall(Helpers.GetMaxCoreStorage, plr, prof)
		if ok and tonumber(cap) then
			return math.max(1, math.floor(tonumber(cap)))
		end
	end
	return math.max(1, math.floor(tonumber(prof and prof.MaxFruitStorage) or 1))
end

local function isPlayerPvPCombatTagged(plr, rt)
	if plr then
		local untilTs = tonumber(plr:GetAttribute("PvPCombatUntil")) or 0
		if untilTs > 0 and (untilTs > os.time() or untilTs > workspace:GetServerTimeNow()) then
			return true
		end
	end
	if rt and (tonumber(rt.PvPCombatTagUntil) or 0) > os.clock() then
		return true
	end
	return false
end

local SERVER_FRUIT_ALIASES = {
	galecore = "GaleCore",
	gale = "GaleCore",
	aetherwindcore = "GaleCore",
	sandstonecore = "SandstoneCore",
	smoke = "SandstoneCore",
	smokecore = "SandstoneCore",
	solarflamecore = "SolarFlameCore",
	flame = "SolarFlameCore",
	flamecore = "SolarFlameCore",
	cyberphoenixcore = "SolarFlameCore",
	glaciericecore = "GlacierIceCore",
	ice = "GlacierIceCore",
	icecore = "GlacierIceCore",
	thunderrumblecore = "ThunderRumbleCore",
	rumble = "ThunderRumbleCore",
	rumblecore = "ThunderRumbleCore",
	celestiallightcore = "CelestialLightCore",
	light = "CelestialLightCore",
	lightcore = "CelestialLightCore",
	starforgedmagmacore = "StarforgedMagmaCore",
	magma = "StarforgedMagmaCore",
	magmacore = "StarforgedMagmaCore",
	magmaburstcore = "StarforgedMagmaCore",
	astralgravitycore = "AstralGravityCore",
	gravity = "AstralGravityCore",
	gravitycore = "AstralGravityCore",
	dimensionalportalcore = "DimensionalPortalCore",
	portal = "DimensionalPortalCore",
	portalcore = "DimensionalPortalCore",
	solartitancore = "SolarTitanCore",
	buddha = "SolarTitanCore",
	quake = "SolarTitanCore",
	quakecore = "SolarTitanCore",
	starlightquakecore = "SolarTitanCore",
	aetherflowcore = "AetherflowCore",
	sweetdoughcore = "AetherflowCore",
	dough = "AetherflowCore",
	doughcore = "AetherflowCore",
	abyssalsovereigncore = "AbyssalSovereignCore",
	dragon = "AbyssalSovereignCore",
	dragoncore = "AbyssalSovereignCore",
	abyssaldarkcore = "AbyssalSovereignCore",
}

local TRUE_FLIGHT_FRUITS = {
	GaleCore = true,
	SandstoneCore = true,
	SolarFlameCore = true,
	CelestialLightCore = true,
	StarforgedMagmaCore = true,
	AstralGravityCore = true,
}

do
	local origResolve = CombatData.ResolveFruitId
	CombatData.ResolveFruitId = function(rawId)
		if type(rawId) ~= "string" or rawId == "" then
			return ""
		end
		local clean = string.lower((string.gsub(rawId, "%s+", "")))
		if SERVER_FRUIT_ALIASES[clean] then
			return SERVER_FRUIT_ALIASES[clean]
		end
		if type(origResolve) == "function" then
			return origResolve(rawId)
		end
		return rawId
	end
end

local Expansion = {}

-- Module runtime references populated during Expansion.Init(G, D, W, C)
local G, D, W, C, R
local WorldRoot = nil

local TokenBuckets = {}      -- [Player] = { Tokens = 45, LastRefill = os.clock() }
local ActiveTrades = {}      -- [sessionId] = TradeSession
local PlayerTradeMap = {}    -- [Player] = TradeSession
local TrialSessions = {}     -- [Player] = { EndsAt, Enemies = {}, Active = true }
local CurrentMirageStock = nil
local LastMirageHourSeed = -1

-- ============================================================================
-- SANITY & VECTOR HELPERS (#127)
-- ============================================================================
local function finiteNumber(n)
	return type(n) == "number" and n == n and n > -1e9 and n < 1e9
end

local function sanitizeVec3(v)
	if typeof(v) ~= "Vector3" then
		if type(v) == "table" and finiteNumber(v.X or v.x) and finiteNumber(v.Y or v.y) and finiteNumber(v.Z or v.z) then
			return Vector3.new(v.X or v.x, v.Y or v.y, v.Z or v.z)
		end
		return nil
	end
	if not (finiteNumber(v.X) and finiteNumber(v.Y) and finiteNumber(v.Z)) then
		return nil
	end
	return v
end

local function consumeToken(p, cost)
	if typeof(p) ~= "Instance" or not p:IsA("Player") then
		return false
	end
	local now = os.clock()
	local b = TokenBuckets[p]
	if not b then
		b = { Tokens = 45, LastRefill = now }
		TokenBuckets[p] = b
	end
	local elapsed = math.max(0, now - b.LastRefill)
	b.LastRefill = now
	b.Tokens = math.min(45, b.Tokens + elapsed * 45)
	local need = cost or 1
	if b.Tokens < need then
		return false
	end
	b.Tokens -= need
	return true
end

local function getCharRoot(p)
	local ch = p and p.Character
	if not ch then
		return nil, nil, nil
	end
	local hrp = ch:FindFirstChild("HumanoidRootPart")
	local hum = ch:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then
		return nil, nil, ch
	end
	return hrp, hum, ch
end

local function clampAimRay(hrp, payload, maxRange)
	return Helpers.Resolve3DAimRay(hrp, payload, maxRange)
end

local function groundYAt(pos, refY)
	if W and W.RaycastGround then
		local hit = W.RaycastGround(pos + Vector3.new(0, 18, 0), refY or pos.Y)
		if hit and hit.Position then
			return hit.Position.Y
		end
	end
	return refY or pos.Y
end

local function ensureWorldFolder(subName)
	if not WorldRoot or not WorldRoot.Parent then
		WorldRoot = workspace:FindFirstChild("SkybreakExpansionWorld")
		if not WorldRoot then
			WorldRoot = Instance.new("Folder")
			WorldRoot.Name = "SkybreakExpansionWorld"
			WorldRoot.Parent = workspace
		end
	end
	if not subName then
		return WorldRoot
	end
	local sub = WorldRoot:FindFirstChild(subName)
	if not sub then
		sub = Instance.new("Folder")
		sub.Name = subName
		sub.Parent = WorldRoot
	end
	return sub
end

local function formatBountyShort(val)
	local n = math.floor(tonumber(val) or 0)
	if n >= 1000000 then
		return string.format("%.2fM", n / 1000000)
	elseif n >= 1000 then
		return string.format("%.1fK", n / 1000)
	end
	return tostring(n)
end

-- ============================================================================
-- PROFILE HYDRATION & ATTRIBUTES
-- ============================================================================
local function ensureExpansionProfile(profile)
	if type(profile) ~= "table" then
		return
	end
	local resolvedStyle = CombatData.ResolveStyleId(profile.FightingStyle)
	profile.FightingStyle = resolvedStyle
	profile.UnlockedStyles = type(profile.UnlockedStyles) == "table" and profile.UnlockedStyles or {}
	profile.UnlockedStyles.skyborn_combat = true
	profile.UnlockedStyles.SkybornCombat = true
	profile.UnlockedStyles[resolvedStyle] = true

	profile.Mastery = type(profile.Mastery) == "table" and profile.Mastery or {}
	profile.MasteryXP = type(profile.MasteryXP) == "table" and profile.MasteryXP or {}
	profile.MasteryMilestones = type(profile.MasteryMilestones) == "table" and profile.MasteryMilestones or {}

	profile.AwakenedFruits = type(profile.AwakenedFruits) == "table" and profile.AwakenedFruits or {}
	profile.StoredFruits = type(profile.StoredFruits) == "table" and profile.StoredFruits or {}
	profile.Inventory = type(profile.Inventory) == "table" and profile.Inventory or {}

	profile.WeaponStars = type(profile.WeaponStars) == "table" and profile.WeaponStars or {}
	profile.StarPity = type(profile.StarPity) == "table" and profile.StarPity or {}
	profile.StatPresets = type(profile.StatPresets) == "table" and profile.StatPresets or {}
	profile.RedeemedCodes = type(profile.RedeemedCodes) == "table" and profile.RedeemedCodes or {}
	profile.DoubleExpUntil = tonumber(profile.DoubleExpUntil) or 0
	profile.DoubleExpRemainingSec = math.max(0, math.floor(tonumber(profile.DoubleExpRemainingSec) or 0))
	profile.FreeFruitVouchers = tonumber(profile.FreeFruitVouchers) or 0
	profile.StatRefundTokens = tonumber(profile.StatRefundTokens) or 0

	profile.Haki = type(profile.Haki) == "table" and profile.Haki or { Aura = false, Instinct = false, InstinctDodges = 8 }
	profile.HakiEXP = math.max(0, tonumber(profile.HakiEXP) or 0)
	profile.HakiStage = math.clamp(math.max(tonumber(profile.HakiStage) or 0, CombatData.GetHakiStageForEXP(profile.HakiEXP)), 0, 5)
	profile.HakiColorId = CombatData.HakiColors[profile.HakiColorId] and profile.HakiColorId or "solar_gold"
	profile.UnlockedHakiColors = type(profile.UnlockedHakiColors) == "table" and profile.UnlockedHakiColors or {}
	profile.UnlockedHakiColors.solar_gold = true

	profile.KenEXP = math.max(0, tonumber(profile.KenEXP) or 0)
	if (tonumber(profile.Level) or 1) >= 700 or profile.KenEXP >= CombatData.KenV2UnlockDodgesEXP then
		profile.KenV2Unlocked = true
	else
		profile.KenV2Unlocked = profile.KenV2Unlocked == true
	end

	profile.Bounty = math.clamp(math.floor(tonumber(profile.Bounty) or 0), 0, CombatData.MaxBounty)
	profile.Honor = math.clamp(math.floor(tonumber(profile.Honor) or profile.Bounty), 0, CombatData.MaxBounty)

	profile.UnlockedTitles = type(profile.UnlockedTitles) == "table" and profile.UnlockedTitles or {}
	profile.UnlockedTitles.sky_rookie = true
	if type(profile.Title) ~= "string" or not CombatData.Titles[profile.Title] then
		profile.Title = "sky_rookie"
	end

	profile.Race = (type(profile.Race) == "string" and CombatData.RaceV4Passives[profile.Race]) and profile.Race or "Skyborn"
	profile.RaceV4Unlocked = (profile.RaceV4Unlocked == true) or ((tonumber(profile.RaceTier) or 1) >= 4)
	profile.CoreGears = tonumber(profile.CoreGears) or 0
	if profile.AwakeningMeter == nil then
		profile.AwakeningMeter = profile.RaceV4Unlocked and 100 or 0
	else
		profile.AwakeningMeter = math.clamp(tonumber(profile.AwakeningMeter) or 0, 0, 100)
	end

	if type(profile.UnlockedWorlds) == "table" then
		local numericKeys = {}
		for k, v in pairs(profile.UnlockedWorlds) do
			if type(k) == "number" or tonumber(k) ~= nil then
				table.insert(numericKeys, { Key = k, Val = v })
			end
		end
		for _, entry in ipairs(numericKeys) do
			local idx = tonumber(entry.Key)
			local isl = idx and C and C.Islands and rawget(C.Islands, idx)
			if entry.Val and type(isl) == "table" and type(isl.Id) == "string" and isl.Id ~= "" then
				profile.UnlockedWorlds[isl.Id] = true
			end
			profile.UnlockedWorlds[entry.Key] = nil
		end
	end
end

local function ensureRuntimeFields(p, rt, profile)
	if not rt then
		return
	end
	if rt.FuryMeter == nil then
		rt.FuryMeter = 100
	end
	rt.AwakeningMeter = tonumber(profile and profile.AwakeningMeter) or tonumber(rt.AwakeningMeter) or 0
	rt.DragonFormTier = tonumber(rt.DragonFormTier) or 0
	rt.KataStep = tonumber(rt.KataStep) or 0
	rt.LastKataAt = tonumber(rt.LastKataAt) or 0
	rt.LeviathanShieldHP = tonumber(rt.LeviathanShieldHP) or 0
	rt.SelectedPortalIndex = tonumber(rt.SelectedPortalIndex) or 1
	rt.RecentCodeDedup = rt.RecentCodeDedup or {}
	rt.RecentStarDedup = rt.RecentStarDedup or {}
end

-- ============================================================================
-- MASTERY PROGRESSION (#41)
-- ============================================================================
local function getActiveDisciplineId(profile, slotOverride)
	local slot = slotOverride or math.clamp(tonumber(profile.ActiveSlot) or 2, 1, 4)
	if slot == 1 then
		return CombatData.ResolveStyleId(profile.FightingStyle), 1
	elseif slot == 2 then
		local fid = CombatData.ResolveFruitId(profile.EquippedFruit)
		return (fid ~= "" and fid or "GaleCore"), 2
	elseif slot == 3 then
		return tostring(profile.Weapon or "starter_sword"), 3
	else
		return tostring(profile.EquippedGun or "aether_flintlock"), 4
	end
end

local function getMasteryLevel(profile, itemId)
	if not profile or type(itemId) ~= "string" or itemId == "" then
		return 1
	end
	ensureExpansionProfile(profile)
	local lv = tonumber(profile.Mastery[itemId])
	if not lv or lv < 1 then
		profile.Mastery[itemId] = 1
		return 1
	end
	return math.clamp(math.floor(lv), 1, CombatData.MasteryConfig.MaxLevel)
end

local function checkMoveMasteryUnlock(p, profile, itemId, moveKey, slot)
	if DevGate.IsAllowed(p) and G and G.Runtime and G.Runtime[p] and (G.Runtime[p].ZeroCooldowns == true or G.Runtime[p].DevSandboxUnlocked == true) then
		return true, 1
	end
	local key = string.upper(tostring(moveKey or "Z"))
	local mCfg = CombatData.MasteryConfig or {}
	local thresholds = mCfg.MoveUnlockThresholds or { Z = 1, F = 1, X = 50, C = 100, V = 200 }
	local reqLv = tonumber(thresholds[key]) or 1

	if slot == 1 then
		local st = CombatData.MartialStyles and CombatData.MartialStyles[CombatData.ResolveStyleId(itemId)]
		if st and st.Moves and st.Moves[key] and st.Moves[key].Mastery then
			reqLv = tonumber(st.Moves[key].Mastery) or reqLv
		end
	elseif slot == 2 then
		local fid = CombatData.ResolveFruitId(itemId)
		local cat = CombatData.FruitCatalog and CombatData.FruitCatalog[fid]
		if key == "V" and cat and (cat.Rarity == "Mythic" or cat.Rarity == "Mythical") then
			reqLv = tonumber(mCfg.MythicalVThreshold) or 250
		end
		local fCfg = C and C.AetherFruits and C.AetherFruits[fid]
		if fCfg and fCfg.Moves and fCfg.Moves[key] and fCfg.Moves[key].Mastery then
			reqLv = tonumber(fCfg.Moves[key].Mastery) or reqLv
		end
	elseif slot == 3 then
		local wCfg = C and ((C.Swords and C.Swords[itemId]) or (C.Weapons and C.Weapons[itemId]))
		if wCfg and wCfg.Moves and wCfg.Moves[key] and wCfg.Moves[key].Mastery then
			reqLv = tonumber(wCfg.Moves[key].Mastery) or reqLv
		end
	elseif slot == 4 then
		local gCfg = C and C.Guns and C.Guns[itemId]
		if gCfg and gCfg.Moves and gCfg.Moves[key] and gCfg.Moves[key].Mastery then
			reqLv = tonumber(gCfg.Moves[key].Mastery) or reqLv
		end
	end

	local curLv = getMasteryLevel(profile, itemId)
	if curLv < reqLv then
		if G and G.Notify and p then
			G.Notify(p, string.format("Kỹ năng [%s] yêu cầu Mastery Lv. %d (Hiện tại: Lv. %d)!", key, reqLv, curLv))
		end
		return false, reqLv
	end
	return true, reqLv
end

local function addMasteryXP(p, itemId, rawXP)
	local profile = D.Get(p)
	if not profile or type(itemId) ~= "string" or itemId == "" then
		return
	end
	ensureExpansionProfile(profile)
	local hasDoubleExp = ((tonumber(profile.DoubleExpRemainingSec) or 0) > 0)
		or (profile.DoubleExpUntil and profile.DoubleExpUntil > os.time())
		or ((tonumber(profile.DoubleExpSeconds) or 0) > 0)
		or (p and (tonumber(p:GetAttribute("DoubleExpSeconds")) or 0) > 0)
	local ownsMasteryPass = (type(profile.OwnedGamePasses) == "table" and profile.OwnedGamePasses.x2_mastery == true)
		or (p and p:GetAttribute("OwnedPass_x2_mastery") == true)
	local fbMult = 1 + math.clamp(tonumber(p and p:GetAttribute("FriendBoostPct")) or 0, 0, 15) / 100
	local mult = (hasDoubleExp and 2 or 1) * (ownsMasteryPass and 2 or 1) * fbMult
	local add = math.max(1, math.floor((tonumber(rawXP) or 10) * mult + 0.5))

	local curLv = getMasteryLevel(profile, itemId)
	if curLv >= CombatData.MasteryConfig.MaxLevel then
		return
	end
	local xp = (tonumber(profile.MasteryXP[itemId]) or 0) + add
	local leveledUp = false
	while curLv < CombatData.MasteryConfig.MaxLevel do
		local need = CombatData.RequiredMasteryXP(curLv)
		if xp >= need then
			xp -= need
			curLv += 1
			leveledUp = true
		else
			break
		end
	end
	profile.Mastery[itemId] = curLv
	profile.MasteryXP[itemId] = curLv >= CombatData.MasteryConfig.MaxLevel and 0 or xp

	local fid = CombatData.ResolveFruitId(profile.EquippedFruit)
	if itemId == profile.EquippedFruit or itemId == fid then
		p:SetAttribute("FruitMastery", curLv)
	end

	if leveledUp then
		profile.MasteryMilestones[itemId] = type(profile.MasteryMilestones[itemId]) == "table" and profile.MasteryMilestones[itemId] or {}
		local mTable = profile.MasteryMilestones[itemId]
		for _, ms in ipairs(CombatData.MasteryConfig.Milestones) do
			local mKey = tostring(ms.Level)
			if curLv >= ms.Level and not mTable[mKey] then
				mTable[mKey] = true
				profile.Gold = (profile.Gold or 0) + (ms.Gold or 0)
				profile.CoreShards = (profile.CoreShards or 0) + (ms.Shards or 0)
				if ms.TitleId then
					profile.UnlockedTitles[ms.TitleId] = true
				end
				G.Notify(p, string.format("MASTERY %s Lv.%d! %s (+%d Gold, +%d Core Shards)", itemId, ms.Level, ms.Label, ms.Gold or 0, ms.Shards or 0))
			end
		end
	end
end

-- ============================================================================
-- BOUNTY / HONOR (#56), LEADERSTATS, 34 GLOWING TITLES & OVERHEAD GUI (#58)
-- ============================================================================
local function syncLeaderstats(p, profile)
	if not p or not profile then
		return
	end
	local ls = p:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		ls.Parent = p
	end
	local oldBountyVal = ls:FindFirstChild("Bounty")
	if oldBountyVal then
		oldBountyVal:Destroy()
	end
	local bVal = ls:FindFirstChild("Renown")
	if not bVal then
		bVal = Instance.new("IntValue")
		bVal.Name = "Renown"
		bVal.Parent = ls
	end
	bVal.Value = math.clamp(math.floor(tonumber(profile.Bounty) or 0), 0, CombatData.MaxBounty)

	local lvVal = ls:FindFirstChild("Level")
	if not lvVal then
		lvVal = Instance.new("IntValue")
		lvVal.Name = "Level"
		lvVal.Parent = ls
	end
	lvVal.Value = math.floor(tonumber(profile.Level) or 1)
end

local function updateOverheadTitleGui(p, profile)
	local _, _, ch = getCharRoot(p)
	if not ch or not profile then
		return
	end
	local head = ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart")
	if not head then
		return
	end

	local tSpec = CombatData.Titles[profile.Title] or CombatData.Titles.sky_rookie
	local bill = head:FindFirstChild("SkybreakTitleTag")
	if not bill then
		bill = Instance.new("BillboardGui")
		bill.Name = "SkybreakTitleTag"
		bill.Size = UDim2.fromOffset(240, 56)
		bill.StudsOffset = Vector3.new(0, 3.3, 0)
		bill.AlwaysOnTop = false
		bill.LightInfluence = 0
		bill.Brightness = 1
		bill.MaxDistance = 105
		bill.Parent = head

		local titleLbl = Instance.new("TextLabel")
		titleLbl.Name = "TitleLabel"
		titleLbl.Size = UDim2.new(1, 0, 0, 22)
		titleLbl.Position = UDim2.fromOffset(0, 0)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Font = Enum.Font.GothamBlack
		titleLbl.TextSize = 14
		titleLbl.TextStrokeTransparency = 0.18
		titleLbl.TextStrokeColor3 = Color3.fromRGB(10, 14, 24)
		titleLbl.Parent = bill

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Name = "NameLabel"
		nameLbl.Size = UDim2.new(1, 0, 0, 18)
		nameLbl.Position = UDim2.fromOffset(0, 21)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font = Enum.Font.GothamBold
		nameLbl.TextSize = 13
		nameLbl.TextColor3 = Color3.fromRGB(242, 247, 255)
		nameLbl.TextStrokeTransparency = 0.25
		nameLbl.Parent = bill

		local bountyLbl = Instance.new("TextLabel")
		bountyLbl.Name = "BountyLabel"
		bountyLbl.Size = UDim2.new(1, 0, 0, 15)
		bountyLbl.Position = UDim2.fromOffset(0, 39)
		bountyLbl.BackgroundTransparency = 1
		bountyLbl.Font = Enum.Font.GothamMedium
		bountyLbl.TextSize = 11
		bountyLbl.TextColor3 = Color3.fromRGB(255, 208, 102)
		bountyLbl.TextStrokeTransparency = 0.3
		bountyLbl.Parent = bill
	end

	local titleLbl = bill:FindFirstChild("TitleLabel")
	local nameLbl = bill:FindFirstChild("NameLabel")
	local bountyLbl = bill:FindFirstChild("BountyLabel")
	if titleLbl then
		titleLbl.Text = "[" .. tSpec.Name .. "]"
		titleLbl.TextColor3 = tSpec.Color
	end
	if nameLbl then
		nameLbl.Text = string.format("%s - Lv.%d", p.DisplayName or p.Name, tonumber(profile.Level) or 1)
	end
	if bountyLbl then
		local bPct = math.floor(CombatData.GetBountyBuffPct(profile.Bounty) * 100 + 0.5)
		local factionTag = (profile.Faction == "Marine") and "Valor" or "Renown"
		bountyLbl.Text = string.format("%s: %s (+%d%% ATK/DEF)", factionTag, formatBountyShort(profile.Bounty), bPct)
	end
end

local function unlockTitle(p, profile, titleId, silent)
	if not profile or not CombatData.Titles[titleId] then
		return
	end
	ensureExpansionProfile(profile)
	if not profile.UnlockedTitles[titleId] then
		profile.UnlockedTitles[titleId] = true
		if not silent then
			G.Notify(p, "Mở khóa Danh Hiệu mới: [" .. CombatData.Titles[titleId].Name .. "]!")
		end
	end
end

local function evaluateAutoTitles(p, profile)
	if not profile then
		return
	end
	ensureExpansionProfile(profile)
	local lv = tonumber(profile.Level) or 1
	local bounty = tonumber(profile.Bounty) or 0
	local inv = profile.Inventory or {}
	local worlds = profile.UnlockedWorlds or {}
	local bosses = profile.FirstClearBosses or {}

	for id, spec in pairs(CombatData.Titles) do
		if not profile.UnlockedTitles[id] then
			local ok = false
			if spec.MinLevel and lv >= spec.MinLevel then
				ok = true
			end
			if spec.BossClear and bosses[spec.BossClear] then
				ok = true
			end
			if spec.WorldReq and worlds[spec.WorldReq] then
				ok = true
			end
			if spec.ItemOwned and ((inv[spec.ItemOwned] or 0) > 0 or profile.Weapon == spec.ItemOwned or profile.EquippedGun == spec.ItemOwned) then
				ok = true
			end
			if spec.StyleReq and profile.UnlockedStyles[spec.StyleReq] then
				ok = true
			end
			if spec.MinHakiStage and (profile.HakiStage or 0) >= spec.MinHakiStage then
				ok = true
			end
			if spec.KenV2Req and profile.KenV2Unlocked then
				ok = true
			end
			if spec.RaceV4Req and profile.RaceV4Unlocked then
				ok = true
			end
			if spec.MinBounty and bounty >= spec.MinBounty then
				ok = true
			end
			if spec.MaxStarReq then
				for _, st in pairs(profile.WeaponStars or {}) do
					if (tonumber(st) or 0) >= spec.MaxStarReq then
						ok = true
						break
					end
				end
			end
			if ok then
				unlockTitle(p, profile, id, true)
			end
		end
	end
	for _, mLv in pairs(profile.Mastery or {}) do
		if (tonumber(mLv) or 1) >= 600 then
			unlockTitle(p, profile, "grand_master_600", true)
		end
		if (tonumber(mLv) or 1) >= 300 then
			unlockTitle(p, profile, "golden_sword_saint", true)
		end
	end
	for _, awk in pairs(profile.AwakenedFruits or {}) do
		if awk == true then
			unlockTitle(p, profile, "awakened_ascendant", true)
			break
		end
	end
end

local function awardBounty(p, delta, reason)
	local profile = D.Get(p)
	if not profile then
		return
	end
	ensureExpansionProfile(profile)
	local prev = profile.Bounty or 0
	local nextB = math.clamp(prev + math.floor(tonumber(delta) or 0), 0, CombatData.MaxBounty)
	if nextB == prev then
		return
	end
	profile.Bounty = nextB
	profile.Honor = nextB
	p:SetAttribute("Bounty", nextB)
	p:SetAttribute("Renown", nextB)
	syncLeaderstats(p, profile)
	if prev < CombatData.SeaBeastSummonBounty and nextB >= CombatData.SeaBeastSummonBounty then
		unlockTitle(p, profile, "seabeast_caller_10m", false)
		G.Notify(p, "ĐẠT 10,000,000 ĐIỂM DANH VỌNG (RENOWN)! Đã mở khóa tuyệt kỹ Triệu Hồi Thú Trời Hộ Vệ (Sky Beast Guardian)!")
	end
	evaluateAutoTitles(p, profile)
	if reason and reason ~= "" and math.abs(nextB - prev) >= 25000 then
		G.Notify(p, string.format("+%s Điểm Danh Vọng / Renown (%s) -> Tổng: %s", formatBountyShort(nextB - prev), reason, formatBountyShort(nextB)))
	end
end

-- ============================================================================
-- 5-STAGE BUSOSHOKU HAKI (#53) & KENBUNSHOKU V2 INSPECTOR (#54)
-- ============================================================================
local function syncHakiAttributes(p, profile)
	if not p or not profile then
		return
	end
	ensureExpansionProfile(profile)
	local stage = profile.HakiStage or 0
	local colorId = profile.HakiColorId or "crimson_conqueror"
	local colorSpec = CombatData.HakiColors[colorId] or CombatData.HakiColors.crimson_conqueror
	local auraOn = (profile.Haki and profile.Haki.Aura == true) or false
	local kenOn = (profile.Haki and profile.Haki.Instinct == true) or false
	local dodges = math.clamp(tonumber(profile.Haki and profile.Haki.InstinctDodges) or 8, 0, 8)
	local kenV2 = (kenOn and profile.KenV2Unlocked == true)
	local v4Active = profile.RaceV4Active == true
	local v4Race = v4Active and (profile.Race or "Skyborn") or ""
	local awkMeter = math.floor((tonumber(profile.AwakeningMeter) or 0) + 0.5)

	p:SetAttribute("HakiAura", auraOn)
	p:SetAttribute("HakiInstinct", kenOn)
	p:SetAttribute("InstinctDodges", dodges)
	p:SetAttribute("HakiStage", stage)
	p:SetAttribute("HakiColorId", colorId)
	p:SetAttribute("HakiColorRGB", colorSpec.Color)
	p:SetAttribute("KenV2Active", kenV2)
	p:SetAttribute("RaceV4Active", v4Active)
	p:SetAttribute("RaceV4", v4Race)
	p:SetAttribute("AwakeningMeter", awkMeter)
	if p.Character then
		p.Character:SetAttribute("HakiAura", auraOn)
		p.Character:SetAttribute("HakiInstinct", kenOn)
		p.Character:SetAttribute("InstinctDodges", dodges)
		p.Character:SetAttribute("HakiStage", stage)
		p.Character:SetAttribute("HakiColorId", colorId)
		p.Character:SetAttribute("HakiColorRGB", colorSpec.Color)
		p.Character:SetAttribute("KenV2Active", kenV2)
		p.Character:SetAttribute("RaceV4Active", v4Active)
		p.Character:SetAttribute("RaceV4", v4Race)
	end
end

local function addBusoHakiEXP(p, amount)
	local profile = D.Get(p)
	if not profile or not (profile.Haki and profile.Haki.Aura) then
		return
	end
	ensureExpansionProfile(profile)
	local oldStage = profile.HakiStage or 0
	profile.HakiEXP = (profile.HakiEXP or 0) + (tonumber(amount) or 3)
	local newStage = CombatData.GetHakiStageForEXP(profile.HakiEXP)
	if newStage > oldStage then
		profile.HakiStage = newStage
		local stInfo = CombatData.HakiStages[newStage]
		syncHakiAttributes(p, profile)
		evaluateAutoTitles(p, profile)
		G.Notify(p, string.format("GIÁP Ý CHÍ THĂNG CẤP: %s (+%d%% ATK, +%d%% DEF)!", stInfo.Name, math.floor(stInfo.AtkBonus * 100), math.floor(stInfo.DefBonus * 100)))
		local hrp = getCharRoot(p)
		if hrp and R and R.CombatFX then
			R.CombatFX:FireAllClients({
				Kind = "HakiStageUp",
				Stage = newStage,
				Color = (CombatData.HakiColors[profile.HakiColorId] or CombatData.HakiColors.crimson_conqueror).Color,
				Position = hrp.Position,
				Actor = p.UserId,
			})
		end
	end
end

local function tickKenV2Inspector(p, profile)
	if not profile then
		return
	end
	local kenActive = (profile.Haki and profile.Haki.Instinct == true and profile.KenV2Unlocked == true)
	if not kenActive then
		if p:GetAttribute("InspectedTargetInfo") ~= "" then
			p:SetAttribute("InspectedTargetInfo", "")
		end
		return
	end
	local hrp = getCharRoot(p)
	if not hrp then
		return
	end

	local bestDist = 140
	local bestInfo = nil
	local look = hrp.CFrame.LookVector

	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= p then
			local ohrp, ohum = getCharRoot(other)
			local op = D.Get(other)
			local ort = G.Runtime[other]
			if ohrp and ohum and op then
				local delta = ohrp.Position - hrp.Position
				local dist = delta.Magnitude
				if dist <= 140 then
					other.Character:SetAttribute("InspectLevel", op.Level or 1)
					other.Character:SetAttribute("InspectWeapon", op.Weapon or "Unarmed")
					other.Character:SetAttribute("InspectFruit", op.EquippedFruit or "None")
					other.Character:SetAttribute("InspectHP", math.floor(ohum.Health))
					other.Character:SetAttribute("InspectMaxHP", math.floor(ohum.MaxHealth))
					other.Character:SetAttribute("InspectEnergy", math.floor((ort and ort.Energy) or 100))
					local score = dist * (1.25 - math.max(0, delta.Unit:Dot(look)) * 0.5)
					if score < bestDist then
						bestDist = score
						bestInfo = {
							Kind = "Player",
							Name = other.DisplayName or other.Name,
							Level = op.Level or 1,
							Weapon = op.Weapon or "Unarmed",
							FightingStyle = op.FightingStyle or "skyborn_combat",
							Fruit = op.EquippedFruit or "None",
							HP = math.floor(ohum.Health),
							MaxHP = math.floor(ohum.MaxHealth),
							Energy = math.floor((ort and ort.Energy) or 100),
							Bounty = op.Bounty or 0,
							Distance = math.floor(dist),
						}
					end
				end
			end
		end
	end

	for _, e in ipairs(G.Enemies or {}) do
		if e.Alive and e.Body and e.Model and e.Model.Parent then
			local delta = e.Body.Position - hrp.Position
			local dist = delta.Magnitude
			if dist <= 140 then
				e.Model:SetAttribute("InspectLevel", (e.Config and e.Config.Level) or 1)
				e.Model:SetAttribute("InspectHP", math.floor(e.HP or 0))
				e.Model:SetAttribute("InspectMaxHP", math.floor(e.MaxHP or 1))
				e.Model:SetAttribute("InspectBreak", math.floor(e.Break or 0))
				local score = dist * (1.25 - math.max(0, delta.Unit:Dot(look)) * 0.5)
				if score < bestDist then
					bestDist = score
					bestInfo = {
						Kind = (e.Config and e.Config.Boss) and "Boss" or "Enemy",
						Name = (e.Config and e.Config.Name) or e.Id,
						Level = (e.Config and e.Config.Level) or 1,
						Weapon = (e.Config and e.Config.Element) or "Aether",
						Fruit = (e.Config and e.Config.Boss) and "Boss Core" or "None",
						HP = math.floor(e.HP or 0),
						MaxHP = math.floor(e.MaxHP or 1),
						Energy = 100,
						BreakGauge = math.floor(e.Break or 0),
						Distance = math.floor(dist),
					}
				end
			end
		end
	end

	if bestInfo then
		local ok, encoded = pcall(HttpService.JSONEncode, HttpService, bestInfo)
		if ok then
			p:SetAttribute("InspectedTargetInfo", encoded)
		end
	else
		p:SetAttribute("InspectedTargetInfo", "")
	end
end

-- ============================================================================
-- BOSS 100% BREAK GAUGE KNEEL / STAGGER (4.5s, 1.5x AMPLIFIED DMG) (#16)
-- ============================================================================
local function isBossEnemy(e)
	if not e then
		return false
	end
	if e == G.Boss or (e.Config and e.Config.Boss) then
		return true
	end
	local id = e.Id
	return id == "AureonSentinel" or id == "CryonPrime" or id == "Noxar"
		or id == "OrderCyborgBoss" or id == "SoulReaperRift" or id == "PirateCaptainVance"
		or id == "SkySeaBeast" or id == "AbyssalLeviathan"
		or id == "Sylvaris" or id == "Ignivar" or id == "Nerith" or id == "Aion" or id == "Veyr"
end

local function updateBossBreakGauge(e, addBreak)
	if not e or not e.Alive or not e.Model or not e.Model.Parent then
		return
	end
	local now = os.clock()
	if not isBossEnemy(e) then
		e.Model:SetAttribute("BreakGauge", math.clamp(math.floor(e.Break or 0), 0, 100))
		return
	end
	if now < (e.BossBrokenUntil or 0) then
		return
	end
	e.Break = math.clamp((tonumber(e.Break) or 0) + math.max(0, tonumber(addBreak) or 0), 0, 100)
	e.Model:SetAttribute("BreakGauge", math.floor(e.Break))
	e.Model:SetAttribute("MaxBreakGauge", 100)

	if e.Break >= 100 then
		e.Break = 0
		e.BossBrokenUntil = now + 4.5
		e.StunnedUntil = math.max(e.StunnedUntil or 0, now + 4.5)
		e.ImmuneUntil = now + 9.5
		e.Model:SetAttribute("BreakGauge", 0)
		e.Model:SetAttribute("BossBroken", true)
		e.Model:SetAttribute("BossBrokenUntil", workspace:GetServerTimeNow() + 4.5)

		local savedCF = e.Body and e.Body.CFrame
		if e.Body and savedCF then
			local kneelCF = (savedCF - Vector3.new(0, 1.35, 0)) * CFrame.Angles(math.rad(18), 0, 0)
			if e.Model and e.Model.Parent then
				e.Model:PivotTo(kneelCF)
			else
				e.Body.CFrame = kneelCF
			end
		end

		if R and R.CombatFX and e.Body then
			R.CombatFX:FireAllClients({
				Kind = "BossBreak",
				Tag = "BREAK!",
				EnemyId = e.Id,
				BossName = (e.Config and e.Config.Name) or e.Id,
				Duration = 4.5,
				DamageMult = 1.5,
				Position = e.Body.Position,
				Target = e.Model,
			})
		end
		G.FireCombatEvent({
			kind = "DamageNumber",
			pos = (e.Body and e.Body.Position or Vector3.zero) + Vector3.new(0, 4, 0),
			amount = 0,
			crit = true,
			breakDmg = 100,
			element = "Lightning",
			Text = "BOSS BREAK! (1.5x DMG - 4.5s)",
		})

		task.delay(4.5, function()
			if e and e.Model and e.Model.Parent then
				e.Model:SetAttribute("BossBroken", false)
				if e.Alive and e.Body then
					local pNow = e.Body.Position
					local fy = e.HomeFloorY or groundYAt(pNow, pNow.Y - 2)
					local halfH = math.max(2.2, e.Body.Size.Y * 0.5)
					local recoverCF = CFrame.new(pNow.X, fy + halfH, pNow.Z)
					e.Model:PivotTo(recoverCF)
					e.CachedGroundY = nil
				end
			end
		end)
	end
end

-- ============================================================================
-- ELEMENTAL DOTS, FREEZE, PULL & MAGMA POOLS (#38, #42)
-- ============================================================================
local function applyCryoFreeze(e, duration)
	if not e or not e.Alive or not e.Model or not e.Model.Parent then
		return
	end
	local dur = tonumber(duration) or 2.2
	local now = os.clock()
	e.FrozenUntil = math.max(e.FrozenUntil or 0, now + dur)
	e.StunnedUntil = math.max(e.StunnedUntil or 0, now + dur)
	e.Model:SetAttribute("FrozenState", true)
	e.Model:SetAttribute("FrozenUntil", workspace:GetServerTimeNow() + dur)
	local hum = e.Model:FindFirstChildOfClass("Humanoid")
	if hum then
		if e.OrigWalkSpeed == nil then
			e.OrigWalkSpeed = hum.WalkSpeed
		end
		hum.WalkSpeed = 0
	end
	task.delay(dur + 0.05, function()
		if e and e.Model and e.Model.Parent and os.clock() >= (e.FrozenUntil or 0) then
			e.Model:SetAttribute("FrozenState", false)
			local h2 = e.Model:FindFirstChildOfClass("Humanoid")
			if h2 and e.OrigWalkSpeed then
				h2.WalkSpeed = e.OrigWalkSpeed
			end
		end
	end)
end

local function applyBurnOrDoT(p, e, tickDmg, ticks, element)
	if not e or not e.Alive or ticks <= 0 then
		return
	end
	for t = 1, ticks do
		task.delay(t * 0.65, function()
			if p and p.Parent and e and e.Alive and e.Model and e.Model.Parent then
				G.Hit(p, e, math.max(1, math.floor(tickDmg)), 2, "ElementalDoT_" .. tostring(element or "Flame"))
			end
		end)
	end
end

local function pullEnemyToward(e, centerPos, strength)
	if not e or not e.Alive or not e.Body or not e.Model or isBossEnemy(e) or e.BossOwner or (e.Config and (e.Config.Speed or 0) <= 0) then
		return
	end
	local delta = Vector3.new(centerPos.X - e.Body.Position.X, 0, centerPos.Z - e.Body.Position.Z)
	if delta.Magnitude > 1.5 then
		local step = math.min(delta.Magnitude - 1.2, tonumber(strength) or 14)
		local np = e.Body.Position + delta.Unit * step
		local fy = e.HomeFloorY or groundYAt(np, e.Body.Position.Y - 2)
		local targetPos = Vector3.new(np.X, fy + math.max(2.2, e.Body.Size.Y * 0.5), np.Z)
		local curRot = e.Body.CFrame - e.Body.Position
		e.Model:PivotTo(CFrame.new(targetPos) * curRot)
		e.CachedGroundY = nil
	end
end

-- ============================================================================
-- COMBAT EXECUTION DELEGATION -> SkybreakSkillMechanicsService (Stage 1 Engine)
-- ============================================================================
local function executeMartialStyleKata(p, payload)
	return SkillMechanics.ExecuteM1(p, 1, payload)
end

local function executeSwordComboM1(p, payload)
	return SkillMechanics.ExecuteM1(p, 3, payload)
end

local function executeChargedCrescentSlash(p, payload)
	return SkillMechanics.ExecuteChargedWeaponSlash(p, payload)
end

local function executeAimedGunShot(p, moveKey, payload)
	if moveKey and moveKey ~= "M1" then
		return SkillMechanics.ExecuteSlotSkill(p, 4, moveKey, payload)
	end
	return SkillMechanics.ExecuteM1(p, 4, payload)
end

-- ============================================================================
-- 2-TIER 50%/100% DRAGON FURY (#48), PORTAL [C] WARP (#49) & V2 FRUITS (#42)
-- ============================================================================
local function getOrderedIslands()
	local list = {}
	local seen = {}
	local function pushIsland(rawKey, isl)
		if type(isl) ~= "table" then
			return
		end
		local strId = (type(isl.Id) == "string" and isl.Id ~= "" and isl.Id)
			or (type(rawKey) == "string" and rawKey ~= "" and not tonumber(rawKey) and rawKey)
			or nil
		if not strId or seen[strId] then
			return
		end
		seen[strId] = true
		table.insert(list, {
			Id = strId,
			Name = isl.Name or strId,
			Realm = isl.Realm or "GoldenSky",
			Pos = isl.Pos or isl.Spawn or C.Spawn,
			Order = isl.Order or isl.MinLevel or 1,
			MinLevel = isl.MinLevel or 1,
		})
	end
	if C and C.Islands then
		for idx, isl in ipairs(C.Islands) do
			pushIsland(idx, isl)
		end
	end
	if C and C.FastTravel then
		for id, node in pairs(C.FastTravel) do
			pushIsland(id, node)
		end
	end
	table.sort(list, function(a, b)
		if a.Order ~= b.Order then
			return a.Order < b.Order
		end
		if a.MinLevel ~= b.MinLevel then
			return a.MinLevel < b.MinLevel
		end
		return a.Id < b.Id
	end)
	return list
end

local function spawnPortalRingModel(folder, name, pos, color, labelText)
	local m = Instance.new("Model")
	m.Name = name
	local ring = Instance.new("Part")
	ring.Name = "PortalRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.7, 11.5, 11.5)
	ring.CFrame = CFrame.new(pos + Vector3.new(0, 5.2, 0)) * CFrame.Angles(0, 0, math.pi * 0.5)
	ring.Color = color
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.18
	ring.Anchored = true
	ring.CanCollide = false
	ring.Parent = m

	local core = Instance.new("Part")
	core.Name = "PortalCore"
	core.Shape = Enum.PartType.Cylinder
	core.Size = Vector3.new(0.35, 9.4, 9.4)
	core.CFrame = ring.CFrame
	core.Color = Color3.fromRGB(18, 32, 68)
	core.Material = Enum.Material.ForceField
	core.Transparency = 0.28
	core.Anchored = true
	core.CanCollide = false
	core.Parent = m

	local bill = Instance.new("BillboardGui")
	bill.Size = UDim2.fromOffset(220, 40)
	bill.StudsOffset = Vector3.new(0, 7.2, 0)
	bill.MaxDistance = 90
	bill.LightInfluence = 0
	bill.Parent = ring

	local tl = Instance.new("TextLabel")
	tl.Name = "DestLabel"
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamBlack
	tl.TextSize = 14
	tl.TextColor3 = Color3.fromRGB(125, 225, 255)
	tl.TextStrokeTransparency = 0.2
	tl.Text = labelText
	tl.Parent = bill

	m.PrimaryPart = ring
	m.Parent = folder
	return m, ring, tl
end

local function performPortalWorldWarp(caster, entryPos, destIsland)
	if not caster or not destIsland or not destIsland.Pos then
		return
	end
	local riftsFolder = ensureWorldFolder("PortalRifts")
	local destPos = destIsland.Pos + Vector3.new(0, 3.5, 0)

	local entryModel = spawnPortalRingModel(riftsFolder, "EntryRift_" .. caster.Name, entryPos, Color3.fromRGB(72, 188, 255), "RIFT -> " .. destIsland.Name)
	local exitModel = spawnPortalRingModel(riftsFolder, "ExitRift_" .. destIsland.Id, destIsland.Pos, Color3.fromRGB(165, 110, 255), "EXIT: " .. destIsland.Name)
	Debris:AddItem(entryModel, 10)
	Debris:AddItem(exitModel, 10)

	local function getPortalDestMinLevel(isl)
		local realm = isl and isl.Realm or "GoldenSky"
		local realmMin = ({
			FrozenCyber = 700,
			ShadowRealm = 1500,
			VerdantCrown = 2200,
			EmberforgeWastes = 2270,
			AbyssalTides = 2340,
			ChronosBastion = 2410,
			VeilsEnd = 2480,
		})[realm] or 1
		return math.max(tonumber(isl and isl.LevelReq) or 1, realmMin)
	end

	local function isBlockedFromPortalWarp(plr)
		if G.Boss and G.Boss.Party and G.Boss.Party[plr] then
			return true
		end
		if PlayerTradeMap[plr] ~= nil or TrialSessions[plr] ~= nil then
			return true
		end
		local prt = G.Runtime and G.Runtime[plr]
		if prt and (prt.InRaid or prt.InDuel or prt.InTrial) then
			return true
		end
		if isPlayerPvPCombatTagged(plr, prt) then
			return true
		end
		if plr:GetAttribute("RaidActive") == true
			or plr:GetAttribute("ColosseumActive") == true
			or plr:GetAttribute("InColosseum") == true
			or plr:GetAttribute("InColosseumDuel") == true
			or (tonumber(plr:GetAttribute("SpireFloor")) or 0) > 0 then
			return true
		end
		return false
	end

	local function isCasterOrPortalAlly(plr)
		if not plr or plr.Parent ~= Players then
			return false
		end
		if plr == caster then
			return true
		end
		if not caster or caster.Parent ~= Players then
			return false
		end
		if G.SocialEconomy and type(G.SocialEconomy.AreInSameParty) == "function" then
			local okP, sameP = pcall(G.SocialEconomy.AreInSameParty, caster, plr)
			if okP and sameP == true then
				return true
			end
		end
		local cCrew = tostring(caster:GetAttribute("CrewName") or "")
		local pCrew = tostring(plr:GetAttribute("CrewName") or "")
		return cCrew ~= "" and cCrew == pCrew
	end

	local reqDestLv = getPortalDestMinLevel(destIsland)
	local destRealm = tostring(destIsland.Realm or "GoldenSky")
	local destId = tostring(destIsland.Id or "")
	local warpedPlayers = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		local phrp = getCharRoot(plr)
		local prt = G.Runtime[plr]
		local pprof = D.Get(plr)
		if phrp and prt and pprof and isCasterOrPortalAlly(plr) and not isBlockedFromPortalWarp(plr) and (plr == caster or (phrp.Position - entryPos).Magnitude <= 14) then
			pprof.UnlockedWorlds = pprof.UnlockedWorlds or {}
			local canEnterDest = (destRealm == "GoldenSky" or destRealm == "SkyHub")
				or pprof.UnlockedWorlds[destRealm] == true
				or (destId ~= "" and pprof.UnlockedWorlds[destId] == true)
				or (tonumber(pprof.Level) or 1) >= reqDestLv
				or DevGate.IsAllowed(plr)
			if not canEnterDest then
				if plr == caster then
					G.Notify(plr, string.format("Cổng Không Gian tới [%s] yêu cầu đạt Level %d!", destIsland.Name or destId, reqDestLv))
				end
			else
				prt.JumpPadUntil = os.clock() + 3.5
				if destRealm ~= "" then
					pprof.UnlockedWorlds[destRealm] = true
				end
				if destId ~= "" and not tonumber(destId) then
					pprof.UnlockedWorlds[destId] = true
				end
				plr:SetAttribute("CurrentRealm", destRealm)
				G.Teleport(plr, destPos)
				table.insert(warpedPlayers, plr.UserId)
				if plr == caster then
					unlockTitle(plr, pprof, "dimensional_traveler", false)
				end
				G.Notify(plr, "PORTAL WORLD WARP -> " .. destIsland.Name .. "!")
				G.Sync(plr)
			end
		end
	end

	if #warpedPlayers > 0 and R and R.CombatFX then
		R.CombatFX:FireAllClients({
			Kind = "PortalWarp",
			EntryPos = entryPos,
			ExitPos = destPos,
			Position = entryPos,
			TargetIslandId = destIsland.Id,
			TargetIslandName = destIsland.Name,
			WarpedUsers = warpedPlayers,
			Actor = caster.UserId,
		})
	end
end

local function executePortalMoveC(p, payload)
	local hrp = getCharRoot(p)
	local rt = G.Runtime[p]
	local profile = D.Get(p)
	if not hrp or not rt or not profile then
		return true
	end
	ensureExpansionProfile(profile)
	ensureRuntimeFields(p, rt, profile)

	if not checkMoveMasteryUnlock(p, profile, "DimensionalPortalCore", "C", 2) then
		return true
	end

	local now = os.clock()
	if now < (tonumber(rt.StunnedUntil) or 0) then
		return true
	end
	if isPlayerPvPCombatTagged(p, rt) then
		G.Notify(p, "Không thể mở Cổng Không Gian khi đang trong trạng thái Giao Tranh PvP! / Cannot open World Gate while in PvP combat!")
		return true
	end
	if (G.Boss and G.Boss.Party and G.Boss.Party[p])
		or PlayerTradeMap[p] ~= nil
		or TrialSessions[p] ~= nil
		or rt.InRaid or rt.InDuel or rt.InTrial
		or p:GetAttribute("RaidActive") == true
		or p:GetAttribute("ColosseumActive") == true
		or p:GetAttribute("InColosseum") == true
		or p:GetAttribute("InColosseumDuel") == true
		or (tonumber(p:GetAttribute("SpireFloor")) or 0) > 0 then
		G.Notify(p, "Không thể mở Cổng Không Gian khi đang trong Phó Bản, Tháp Vô Tận, Đấu Trường hoặc Giao Dịch!")
		return true
	end
	if now < (rt.Cooldowns.PortalWarpC or 0) then
		return true
	end

	local cMove = C and C.AetherFruits and C.AetherFruits.DimensionalPortalCore and C.AetherFruits.DimensionalPortalCore.Moves and C.AetherFruits.DimensionalPortalCore.Moves.C
	local energyCost = math.max(0, tonumber(cMove and (cMove.Cost or cMove.EnergyCost)) or 18)
	if (tonumber(rt.Energy) or 0) < energyCost then
		G.Notify(p, "Không đủ Energy!")
		return true
	end

	local islands = getOrderedIslands()
	if #islands == 0 then
		return false
	end

	local function canCasterTravelTo(isl)
		if not isl then return false end
		local realm = tostring(isl.Realm or "GoldenSky")
		if realm == "GoldenSky" or realm == "SkyHub" or DevGate.IsAllowed(p) then
			return true
		end
		profile.UnlockedWorlds = profile.UnlockedWorlds or {}
		if profile.UnlockedWorlds[realm] == true or (isl.Id and profile.UnlockedWorlds[isl.Id] == true) then
			return true
		end
		local realmMin = ({
			FrozenCyber = 700,
			ShadowRealm = 1500,
			VerdantCrown = 2200,
			EmberforgeWastes = 2270,
			AbyssalTides = 2340,
			ChronosBastion = 2410,
			VeilsEnd = 2480,
		})[realm] or 1
		local reqLv = math.max(tonumber(isl.LevelReq) or 1, realmMin)
		return (tonumber(profile.Level) or 1) >= reqLv, reqLv
	end

	local requestedId = type(payload) == "table" and (payload.targetIslandId or payload.islandId or payload.nodeId) or nil
	if type(requestedId) == "string" and requestedId ~= "" then
		local chosen = nil
		for _, isl in ipairs(islands) do
			if isl.Id == requestedId or string.lower(isl.Id) == string.lower(requestedId) then
				chosen = isl
				break
			end
		end
		if chosen then
			local okLv, reqLv = canCasterTravelTo(chosen)
			if not okLv then
				G.Notify(p, string.format("Cổng Không Gian tới [%s] yêu cầu đạt Level %d!", chosen.Name or chosen.Id, reqLv or 1))
				return true
			end
			rt.Energy = math.max(0, (tonumber(rt.Energy) or 0) - energyCost)
			rt.LastCastAt = now
			rt._LastSkillAt = now
			rt.Cooldowns.PortalWarpC = now + 5.5
			rt.Cooldowns.Slot_C = now + 5.5
			addMasteryXP(p, "DimensionalPortalCore", 22)
			performPortalWorldWarp(p, hrp.Position, chosen)
			return true
		end
	end

	rt.Energy = math.max(0, (tonumber(rt.Energy) or 0) - energyCost)
	rt.LastCastAt = now
	rt._LastSkillAt = now
	rt.Cooldowns.PortalWarpC = now + 5.5
	rt.Cooldowns.Slot_C = now + 5.5

	-- Interactive 3D Dimensional Rift Gate with cycle + instant warp prompts across all 20 islands
	rt.SelectedPortalIndex = ((rt.SelectedPortalIndex - 1) % #islands) + 1
	local curDest = islands[rt.SelectedPortalIndex]
	local gatePos = hrp.Position + hrp.CFrame.LookVector * 7
	local riftsFolder = ensureWorldFolder("PortalRifts")
	local existing = riftsFolder:FindFirstChild("InteractiveGate_" .. p.Name)
	if existing then
		existing:Destroy()
	end

	local gateModel, ringPart, destLabel = spawnPortalRingModel(
		riftsFolder,
		"InteractiveGate_" .. p.Name,
		gatePos,
		Color3.fromRGB(68, 200, 255),
		string.format("CỔNG KHÔNG GIAN [%d/%d]: %s", rt.SelectedPortalIndex, #islands, curDest.Name)
	)
	Debris:AddItem(gateModel, 25)

	local warpPrompt = Instance.new("ProximityPrompt")
	warpPrompt.Name = "WarpPrompt"
	warpPrompt.ActionText = "Dịch Chuyển Tức Thời -> " .. curDest.Name
	warpPrompt.ObjectText = "Dimensional Rift Gate"
	warpPrompt.KeyboardKeyCode = Enum.KeyCode.E
	warpPrompt.HoldDuration = 0
	warpPrompt.MaxActivationDistance = 14
	warpPrompt.RequiresLineOfSight = false
	warpPrompt.Parent = ringPart

	local cyclePrompt = Instance.new("ProximityPrompt")
	cyclePrompt.Name = "CyclePrompt"
	cyclePrompt.ActionText = string.format("Đổi Đảo Đích (%d Đảo)", #islands)
	cyclePrompt.ObjectText = "Dimensional Rift Gate"
	cyclePrompt.KeyboardKeyCode = Enum.KeyCode.R
	cyclePrompt.HoldDuration = 0
	cyclePrompt.MaxActivationDistance = 14
	cyclePrompt.RequiresLineOfSight = false
	cyclePrompt.UIOffset = Vector2.new(0, 68)
	cyclePrompt.Parent = ringPart

	cyclePrompt.Triggered:Connect(function(who)
		if who ~= p then
			G.Notify(who, "Chỉ chủ nhân Cổng Không Gian mới có thể đổi đảo đích! / Only the caster can change this gate's destination!")
			return
		end
		rt.SelectedPortalIndex = (rt.SelectedPortalIndex % #islands) + 1
		curDest = islands[rt.SelectedPortalIndex]
		destLabel.Text = string.format("CỔNG KHÔNG GIAN [%d/%d]: %s", rt.SelectedPortalIndex, #islands, curDest.Name)
		warpPrompt.ActionText = "Dịch Chuyển Tức Thời -> " .. curDest.Name
		G.Notify(who, string.format("Đổi đích Cổng Không Gian [%d/%d]: %s", rt.SelectedPortalIndex, #islands, curDest.Name))
	end)

	warpPrompt.Triggered:Connect(function(who)
		if not who or who.Parent ~= Players then
			return
		end
		if isPlayerPvPCombatTagged(who, G.Runtime and G.Runtime[who]) then
			G.Notify(who, "Không thể bước qua Cổng Không Gian khi đang Giao Tranh PvP! / Cannot use World Gate while in PvP combat!")
			return
		end
		local allowedAlly = (who == p)
		if not allowedAlly and p and p.Parent == Players then
			if G.SocialEconomy and type(G.SocialEconomy.AreInSameParty) == "function" then
				local okP, sameP = pcall(G.SocialEconomy.AreInSameParty, p, who)
				if okP and sameP == true then
					allowedAlly = true
				end
			end
			local cCrew = tostring(p:GetAttribute("CrewName") or "")
			local wCrew = tostring(who:GetAttribute("CrewName") or "")
			if cCrew ~= "" and cCrew == wCrew then
				allowedAlly = true
			end
		end
		if not allowedAlly then
			G.Notify(who, "Cổng Không Gian này chỉ dành cho Chủ Nhân và Đồng Đội Tổ Đội / Hạm Đội! / Restricted to caster and Party/Crew allies!")
			return
		end
		if gateModel and gateModel.Parent then
			gateModel:Destroy()
		end
		if p and p.Parent == Players then
			addMasteryXP(p, "DimensionalPortalCore", 22)
			performPortalWorldWarp(p, gatePos, curDest)
		else
			performPortalWorldWarp(who, gatePos, curDest)
		end
	end)

	if type(payload) == "table" and payload.instant == true then
		gateModel:Destroy()
		addMasteryXP(p, "DimensionalPortalCore", 22)
		performPortalWorldWarp(p, hrp.Position, curDest)
	else
		G.Notify(p, string.format("Đã mở Cổng Không Gian 3D! Bấm [E] để xuyên không tới %s hoặc [R] để đổi %d đảo!", curDest.Name, #islands))
		if R and R.CombatFX then
			R.CombatFX:FireAllClients({
				Kind = "PortalWarp",
				SubKind = "GateOpened",
				EntryPos = gatePos,
				Position = gatePos,
				TargetIslandId = curDest.Id,
				TargetIslandName = curDest.Name,
				Actor = p.UserId,
			})
		end
	end
	return true
end

local function executeDragonFuryMoveV(p, fruitId)
	local hrp, hum, ch = getCharRoot(p)
	local rt = G.Runtime[p]
	local profile = D.Get(p)
	if not hrp or not hum or not rt or not profile then
		return true
	end
	ensureExpansionProfile(profile)
	ensureRuntimeFields(p, rt, profile)

	local now = os.clock()
	if now < (rt.Cooldowns.Slot_V or 0) or now < (rt._DragonToggleDebounceAt or 0) then
		return true
	end

	local fury = tonumber(rt.FuryMeter) or tonumber(rt.DragonFury) or 100
	local curTier = tonumber(rt.DragonFormTier) or tonumber(ch and ch:GetAttribute("DragonFormTier")) or tonumber(p:GetAttribute("DragonFormTier")) or 0
	local nextTier = (curTier == 0 and 1) or (curTier == 1 and 2) or 0

	if curTier == 0 then
		if not checkMoveMasteryUnlock(p, profile, fruitId, "V", 2) then
			return true
		end
		if fury < 15 then
			G.Notify(p, string.format("Cần tối thiểu 15%% Nộ Khí (Fury) để hóa Bán Long Nhân (Hiện tại: %d%%)! / Need 15%% Fury for Hybrid Form 1!", math.floor(fury)))
			return true
		end
	elseif curTier == 1 then
		if not checkMoveMasteryUnlock(p, profile, fruitId, "V", 2) or fury < 25 then
			nextTier = 0
		end
	end

	local awk = profile.AwakenedFruits and (profile.AwakenedFruits[fruitId] == true or profile.AwakenedFruits.AbyssalSovereignCore == true)
	if nextTier == 0 then
		rt._DragonToggleDebounceAt = now + 1.4
		rt.DragonFormTier = 0
		rt.FreeFlightActive = false
		rt.FreeFlightUntil = 0
		rt.FuryMeter = fury
		rt.DragonFury = fury
		p:SetAttribute("DragonFormTier", 0)
		p:SetAttribute("FruitTransform", "")
		p:SetAttribute("SkybreakFlightActive", false)
		p:SetAttribute("FreeFlightUntil", 0)
		if ch then
			ch:SetAttribute("DragonFormTier", 0)
			ch:SetAttribute("FruitTransform", "")
			ch:SetAttribute("SkybreakFlightActive", false)
		end
		if R and R.CombatFX then
			R.CombatFX:FireAllClients({
				Kind = "DragonTransform",
				DragonFormTier = 0,
				TransformName = "",
				Awakened = awk,
				FuryMeter = fury,
				Radius = 14,
				Position = hrp.Position,
				Actor = p.UserId,
			})
		end
		G.Notify(p, "Đã thu hồi Long Hóa, trở về nhân dạng (0 Energy). / Reverted to Human form (0 Energy).")
		G.Sync(p)
		return true
	end

	local vCost = 15
	if (tonumber(rt.Energy) or 0) < vCost then
		G.Notify(p, "Không đủ Aether Energy! / Not enough Energy!")
		return true
	end
	rt.Energy = math.max(0, (tonumber(rt.Energy) or 0) - vCost)
	rt.LastCastAt = now
	rt.Cooldowns.Slot_V = now + 3.0

	local tier = nextTier
	rt.DragonFormTier = tier
	rt.FuryMeter = fury
	rt.DragonFury = fury
	local tfName = (tier == 2) and "AbyssalSovereign" or "AbyssalDragonHybrid"
	p:SetAttribute("DragonFormTier", tier)
	p:SetAttribute("FruitTransform", tfName)
	if ch then
		ch:SetAttribute("DragonFormTier", tier)
		ch:SetAttribute("FruitTransform", tfName)
	end
	if tier < 2 then
		rt.FreeFlightActive = false
		rt.FreeFlightUntil = 0
		p:SetAttribute("SkybreakFlightActive", false)
		p:SetAttribute("FreeFlightUntil", 0)
		if ch then
			ch:SetAttribute("SkybreakFlightActive", false)
		end
	end

	local stats = G.Stats(p, 2)
	local atk = (stats and stats.ATK) or 65
	local burstMult = (tier == 2 and 2.8 or 2.0) * (awk and 1.28 or 1.0)
	local burstRadius = tier == 2 and 38 or 26
	local burstBreak = tier == 2 and 42 or 26

	if tier == 2 then
		rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, now + 45)
		unlockTitle(p, profile, "sovereign_dragon_king", false)
		G.Notify(p, "[DẠNG 2 • THÁI CỔ LONG HOÀNG / SOVEREIGN FORM 2] Mở khóa Bay 3D [F] & Tuyệt Kỹ Long Đế! Nhấn [V] để thu hồi (0 Energy).")
	else
		G.Notify(p, "[DẠNG 1 • BÁN LONG NHÂN / HYBRID FORM 1] Hóa Bán Long Nhân (+22% Speed, +25% DEF)! Nhấn [V] lần nữa để hóa Rồng Dạng 2!")
	end

	for _, e in ipairs(G.Enemies or {}) do
		if e.Alive and e.Body and (e.Body.Position - hrp.Position).Magnitude <= burstRadius then
			G.Hit(p, e, atk * burstMult, burstBreak, "DragonFuryAscension_T" .. tostring(tier))
			applyBurnOrDoT(p, e, atk * 0.35, tier == 2 and 3 or 2, "Void")
		end
	end
	addMasteryXP(p, fruitId, tier == 2 and 30 or 20)

	if R and R.CombatFX then
		R.CombatFX:FireAllClients({
			Kind = "DragonTransform",
			DragonFormTier = tier,
			TransformName = tfName,
			Awakened = awk,
			FuryMeter = fury,
			Radius = burstRadius,
			Position = hrp.Position,
			Actor = p.UserId,
		})
	end
	G.Sync(p)
	return true
end

-- Awakened V2 & V1 Fruit Skills are executed authoritatively via SkillMechanics.ExecuteSlotSkill


-- ============================================================================
-- HOURLY MIRAGE FRUIT STOCK DEALER (#43)
-- ============================================================================
local function refreshMirageStock()
	local now = os.time()
	local stock = CombatData.GetHourlyMirageStock(now)
	CurrentMirageStock = stock
	ReplicatedStorage:SetAttribute("MirageStockRefreshIn", stock.RefreshIn)
	if stock.HourSeed ~= LastMirageHourSeed or ReplicatedStorage:GetAttribute("MirageFruitStockJSON") == nil then
		LastMirageHourSeed = stock.HourSeed
		local ok, encoded = pcall(HttpService.JSONEncode, HttpService, stock)
		if ok then
			ReplicatedStorage:SetAttribute("MirageFruitStockJSON", encoded)
		end
	end
	return stock
end

function Expansion.BuyMirageFruit(p, rawFruitId, equipNow)
	local profile = D.Get(p)
	local hrp = getCharRoot(p)
	if not profile or not hrp then
		return false
	end
	ensureExpansionProfile(profile)

	-- D-A7: Must have an active Mirage Island event AND stand within <= 35 studs of the Mirage Stock Dealer
	local swo = workspace:FindFirstChild("SkybreakWorldObjects")
	local mirageModel = (swo and swo:FindFirstChild("MirageSkyIsland_Event")) or workspace:FindFirstChild("MirageSkyIsland_Event", true)
	if workspace:GetAttribute("MirageIslandActive") ~= true or not mirageModel then
		G.Notify(p, "Đảo Hư Quang (Phantom Isle) hiện chưa xuất hiện! Không thể mua từ xa! / Phantom Isle is not currently active!")
		return false
	end
	local dealerNode = mirageModel:FindFirstChild("NPC_MirageStockDealer", true)
	local dealerPos = nil
	if dealerNode then
		dealerPos = dealerNode:IsA("Model") and dealerNode:GetPivot().Position or (dealerNode:IsA("BasePart") and dealerNode.Position or nil)
	end
	if not dealerPos then
		dealerPos = mirageModel:GetPivot().Position
	end
	if (hrp.Position - dealerPos).Magnitude > 35 then
		G.Notify(p, "Bạn phải đứng gần Thương Nhân Đảo Hư Quang (<= 35m) mới có thể giao dịch! / Must be within 35 studs of the Mirage Stock Dealer!")
		return false
	end

	local stock = refreshMirageStock()
	local cid = CombatData.ResolveFruitId(tostring(rawFruitId or ""))

	local chosenItem = nil
	if cid == "" and stock.Items[1] then
		chosenItem = stock.Items[1]
	else
		for _, item in ipairs(stock.Items) do
			if item.Id == cid then
				chosenItem = item
				break
			end
		end
	end

	if not chosenItem then
		G.Notify(p, "Lõi Aether này hiện không có trong Kho Hư Quang giờ này! / This Aether Core is not in the current Mirage Stock!")
		return false
	end

	local shouldEquipOnly = (equipNow == true)
	if not shouldEquipOnly then
		local maxCap = getMaxCoreStorage(p, profile)
		local curCnt = tonumber(profile.StoredFruits[chosenItem.Id]) or 0
		if curCnt >= maxCap then
			G.Notify(
				p,
				string.format(
					"Kho Lõi [%s] đã đầy (%d/%d)! Hãy mở rộng Sức Chứa Lõi hoặc chọn Trang Bị Ngay! / [%s] Core Storage full (%d/%d)!",
					chosenItem.Name,
					curCnt,
					maxCap,
					chosenItem.Id,
					curCnt,
					maxCap
				)
			)
			return false
		end
	end

	local price = chosenItem.PriceGold or CombatData.GetFruitGoldValue(chosenItem.Id)
	if (profile.Gold or 0) < price then
		G.Notify(p, string.format("Không đủ Gold mua [%s] (Cần %d Gold, hiện có %d Gold)! / Not enough Gold!", chosenItem.Name, price, profile.Gold or 0))
		return false
	end

	profile.Gold -= price
	if shouldEquipOnly then
		-- D-A7 Single-Copy Rule: equipNow equips directly onto Slot 2 WITHOUT adding a duplicate StoredFruits copy
		profile.EquippedFruit = chosenItem.Id
		profile.ActiveSlot = 2
		local rt = G.Runtime and G.Runtime[p]
		if rt then
			rt.DragonFormTier = 0
			rt.FreeFlightActive = false
		end
		p:SetAttribute("DragonFormTier", 0)
		p:SetAttribute("FruitTransform", "")
		p:SetAttribute("SkybreakFlightActive", false)
		if p.Character then
			p.Character:SetAttribute("DragonFormTier", 0)
			p.Character:SetAttribute("FruitTransform", "")
			p.Character:SetAttribute("SkybreakFlightActive", false)
		end
	else
		-- Store ONLY 1 copy in StoredFruits
		profile.StoredFruits[chosenItem.Id] = (tonumber(profile.StoredFruits[chosenItem.Id]) or 0) + 1
		profile.HeldFruit = chosenItem.Id
	end
	unlockTitle(p, profile, "mirage_tycoon", false)
	G.Notify(p, string.format("THƯƠNG NHÂN HƯ QUANG: Đã mua [%s] với giá %d Gold! / Purchased [%s] for %d Gold!", chosenItem.Name, price, chosenItem.Id, price))
	G.Sync(p)
	return true
end

-- ============================================================================
-- DROP 3D HELD FRUIT (#47) & WILD FRUIT CLAIM
-- ============================================================================
local function spawnPhysicalDroppedFruit(fruitId, dropPos, dropperName)
	local cid = CombatData.ResolveFruitId(fruitId)
	local cat = CombatData.FruitCatalog[cid]
	if not cat then
		return nil
	end
	local worldObjects = workspace:FindFirstChild("SkybreakWorldObjects")
	if not worldObjects then
		worldObjects = Instance.new("Folder")
		worldObjects.Name = "SkybreakWorldObjects"
		worldObjects.Parent = workspace
	end
	local dropFolder = worldObjects:FindFirstChild("DroppedFruits")
	if not dropFolder then
		dropFolder = Instance.new("Folder")
		dropFolder.Name = "DroppedFruits"
		dropFolder.Parent = worldObjects
	end

	local fy = groundYAt(dropPos, dropPos.Y - 3)
	local basePos = Vector3.new(dropPos.X, fy, dropPos.Z)

	local m = Instance.new("Model")
	m.Name = "DroppedFruit_" .. cid
	m:SetAttribute("FruitId", cid)
	m:SetAttribute("DroppedBy", dropperName or "")

	local ped = Instance.new("Part")
	ped.Name = "Pedestal"
	ped.Shape = Enum.PartType.Cylinder
	ped.Size = Vector3.new(0.62, 2.8, 2.8)
	ped.CFrame = CFrame.new(basePos + Vector3.new(0, 0.31, 0)) * CFrame.Angles(0, 0, math.pi * 0.5)
	ped.Color = Color3.fromRGB(28, 34, 48)
	ped.Material = Enum.Material.Metal
	ped.Anchored = true
	ped.CanCollide = false
	ped.Parent = m

	local rarityColors = {
		Common = Color3.fromRGB(165, 215, 255),
		Uncommon = Color3.fromRGB(98, 238, 165),
		Rare = Color3.fromRGB(84, 185, 255),
		Legendary = Color3.fromRGB(255, 192, 68),
		Mythic = Color3.fromRGB(214, 92, 255),
	}
	local col = rarityColors[cat.Rarity] or Color3.fromRGB(130, 220, 255)

	local orb = Instance.new("Part")
	orb.Name = "FruitOrb"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(1.85, 1.85, 1.85)
	orb.Position = basePos + Vector3.new(0, 2.05, 0)
	orb.Color = col
	orb.Material = Enum.Material.Neon
	orb.Anchored = true
	orb.CanCollide = false
	orb.Parent = m

	local halo = Instance.new("Part")
	halo.Name = "FruitHalo"
	halo.Shape = Enum.PartType.Cylinder
	halo.Size = Vector3.new(0.18, 2.7, 2.7)
	halo.CFrame = CFrame.new(orb.Position) * CFrame.Angles(math.rad(25), 0, math.pi * 0.5)
	halo.Color = col
	halo.Material = Enum.Material.ForceField
	halo.Anchored = true
	halo.CanCollide = false
	halo.Parent = m

	local pl = Instance.new("PointLight")
	pl.Color = col
	pl.Brightness = 1.35
	pl.Range = 14
	pl.Parent = orb

	local bill = Instance.new("BillboardGui")
	bill.Size = UDim2.fromOffset(200, 34)
	bill.StudsOffset = Vector3.new(0, 2.3, 0)
	bill.MaxDistance = 55
	bill.LightInfluence = 0
	bill.Parent = orb

	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamBold
	tl.TextSize = 12
	tl.TextColor3 = col
	tl.TextStrokeTransparency = 0.2
	tl.Text = "[" .. cat.Rarity .. "] " .. cat.Name
	tl.Parent = bill

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Nhặt Lõi Aether"
	prompt.ObjectText = cat.Name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = orb

	local claimed = false
	prompt.Triggered:Connect(function(picker)
		if claimed or not m.Parent or m:GetAttribute("Claimed") == true then
			return
		end
		if PlayerTradeMap[picker] ~= nil or picker:GetAttribute("InTrade") == true then
			return
		end
		local pprof = D.Get(picker)
		if not pprof then
			return
		end
		ensureExpansionProfile(pprof)
		local maxCap = getMaxCoreStorage(picker, pprof)
		local curCnt = tonumber(pprof.StoredFruits[cid]) or 0
		if curCnt >= maxCap then
			G.Notify(
				picker,
				string.format(
					"Kho Lõi [%s] đã đầy (%d/%d)! Không thể nhặt thêm! / [%s] Core Storage is full (%d/%d)!",
					cat.Name,
					curCnt,
					maxCap,
					cid,
					curCnt,
					maxCap
				)
			)
			return
		end
		claimed = true
		m:SetAttribute("Claimed", true)
		pprof.StoredFruits[cid] = curCnt + 1
		pprof.HeldFruit = cid
		m:Destroy()
		G.Notify(picker, string.format("Đã nhặt Lõi Aether 3D: [%s] (%d/%d)! / Picked up [%s]!", cat.Name, curCnt + 1, maxCap, cid))
		G.Sync(picker)
	end)

	m.PrimaryPart = orb
	m.Parent = dropFolder
	Debris:AddItem(m, 180)
	return m
end

function Expansion.DropHeldFruit(p, rawFruitId)
	local hrp = getCharRoot(p)
	local profile = D.Get(p)
	if not hrp or not profile then
		return false
	end
	if PlayerTradeMap[p] ~= nil or p:GetAttribute("InTrade") == true then
		G.Notify(p, "Không thể thả Lõi Aether khi đang ngồi Bàn Giao Dịch!")
		return false
	end
	ensureExpansionProfile(profile)
	local held = tostring(rawFruitId or profile.HeldFruit or "")
	if held == "" and profile.ActiveSlot == 2 then
		held = tostring(profile.EquippedFruit or "")
	end
	local cid = CombatData.ResolveFruitId(held)
	if cid == "" or not CombatData.FruitCatalog[cid] then
		G.Notify(p, "Bạn hiện không cầm Lõi Aether 3D nào trên tay để thả!")
		return false
	end

	local count = tonumber(profile.StoredFruits[cid]) or 0
	if count <= 0 then
		G.Notify(p, "Bạn không có bản sao lưu kho của Lõi Aether này để thả ra ngoài!")
		return false
	end
	profile.StoredFruits[cid] = count - 1
	if profile.StoredFruits[cid] <= 0 then
		profile.StoredFruits[cid] = nil
	end

	profile.HeldFruit = ""
	p:SetAttribute("HeldFruit", "")
	if p.Character then
		p.Character:SetAttribute("HeldFruit", "")
	end

	local dropPos = hrp.Position + hrp.CFrame.LookVector * 3.6
	spawnPhysicalDroppedFruit(cid, dropPos, p.Name)
	G.Notify(p, "Đã thả Lõi Aether 3D [" .. CombatData.FruitCatalog[cid].Name .. "] xuống mặt đất!")
	G.Sync(p)
	return true
end

-- ============================================================================
-- 3D 4-CHAIR CAFE DEVIL FRUIT TRADING TABLE (#44)
-- ============================================================================
local function computeOfferValue(offerList)
	local sum = 0
	for _, fid in ipairs(offerList or {}) do
		sum += CombatData.GetFruitGoldValue(fid)
	end
	return sum
end

local function computeTradeValueDiff(valA, valB)
	local maxV = math.max(valA, valB)
	if maxV <= 0 then
		return 1.0, false
	end
	if valA <= 0 or valB <= 0 then
		return 1.0, false
	end
	local diff = math.abs(valA - valB) / maxV
	return diff, (diff <= CombatData.TradeMaxValueDiffRatio + 1e-5)
end

local function sendTradeSnapshot(session, eventKind, extraMsg)
	if not session or not R or not R.TradeAction then
		return
	end
	local valA = computeOfferValue(session.OfferA)
	local valB = computeOfferValue(session.OfferB)
	local diffRatio, withinLimit = computeTradeValueDiff(valA, valB)

	local snap = {
		Kind = eventKind or "TradeState",
		SessionId = session.Id,
		PlayerA = session.PlayerA and (session.PlayerA.DisplayName or session.PlayerA.Name) or "Trống",
		PlayerB = session.IsNPCCollector and "Nhà Sưu Tầm Ảo Ảnh (NPC)" or (session.PlayerB and (session.PlayerB.DisplayName or session.PlayerB.Name) or "Đang chờ..."),
		IsNPCCollector = session.IsNPCCollector == true,
		OfferA = session.OfferA,
		OfferB = session.OfferB,
		ValueA = valA,
		ValueB = valB,
		ValueDiffPct = math.floor(diffRatio * 100 + 0.5),
		Within40Pct = withinLimit,
		AcceptedA = session.AcceptedA == true,
		AcceptedB = session.AcceptedB == true,
		Countdown = session.Countdown or 0,
		Message = extraMsg or "",
	}
	if session.PlayerA and session.PlayerA.Parent then
		R.TradeAction:FireClient(session.PlayerA, snap)
	end
	if not session.IsNPCCollector and session.PlayerB and session.PlayerB.Parent then
		R.TradeAction:FireClient(session.PlayerB, snap)
	end
	if session.StatusLabel and session.StatusLabel.Parent then
		if session.Countdown and session.Countdown > 0 then
			session.StatusLabel.Text = string.format("XÁC NHẬN GIAO DỊCH TRONG %ds... (Lệch %d%% <= 40%%)", session.Countdown, snap.ValueDiffPct)
		else
			session.StatusLabel.Text = string.format("%s [%s] <-> %s [%s] | Lệch: %d%%", snap.PlayerA, formatBountyShort(valA), snap.PlayerB, formatBountyShort(valB), snap.ValueDiffPct)
		end
	end
end

local function cancelTradeSession(session, reason)
	if not session or session.Closed then
		return
	end
	session.Closed = true
	session.Countdown = 0
	ActiveTrades[session.Id] = nil
	if session.PlayerA then
		PlayerTradeMap[session.PlayerA] = nil
		if session.PlayerA.Parent then
			session.PlayerA:SetAttribute("InTrade", false)
		end
	end
	if session.PlayerB then
		PlayerTradeMap[session.PlayerB] = nil
		if session.PlayerB.Parent then
			session.PlayerB:SetAttribute("InTrade", false)
		end
	end
	if session.NPCModel and session.NPCModel.Parent then
		session.NPCModel:Destroy()
	end
	if session.StatusLabel and session.StatusLabel.Parent then
		session.StatusLabel.Text = "BÀN GIAO DỊCH LÕI AETHER (<= 40% Value Lock)"
	end
	sendTradeSnapshot(session, "TradeCancelled", reason or "Giao dịch đã kết thúc.")
end

local function syncNPCCollectorOffer(session)
	if not session or not session.IsNPCCollector then
		return
	end
	session.OfferB = {}
	session.AcceptedB = false
	local valA = computeOfferValue(session.OfferA)
	if valA <= 0 then
		return
	end
	local offeredByA = {}
	for _, f in ipairs(session.OfferA) do
		offeredByA[f] = true
	end

	-- Pick 1..2 fruits from catalog matching within <= 40% value difference
	local bestId, bestDiff = nil, 999
	for _, fid in ipairs(CombatData.FruitOrder) do
		if not offeredByA[fid] then
			local fv = CombatData.GetFruitGoldValue(fid)
			local diff, ok = computeTradeValueDiff(valA, fv)
			if ok and diff < bestDiff then
				bestDiff = diff
				bestId = fid
			end
		end
	end
	if not bestId then
		-- Try 2-fruit bundle
		for i = #CombatData.FruitOrder, 1, -1 do
			local f1 = CombatData.FruitOrder[i]
			if not offeredByA[f1] then
				for j = i, 1, -1 do
					local f2 = CombatData.FruitOrder[j]
					local sum = CombatData.GetFruitGoldValue(f1) + CombatData.GetFruitGoldValue(f2)
					local diff, ok = computeTradeValueDiff(valA, sum)
					if ok then
						session.OfferB = { f1, f2 }
						session.AcceptedB = true
						return
					end
				end
			end
		end
	else
		session.OfferB = { bestId }
		session.AcceptedB = true
	end
end

local function executeAtomicTradeSwap(session)
	if not session or session.Closed or session.Swapping then
		return
	end
	local pA = session.PlayerA
	local profA = pA and D.Get(pA)
	if not pA or not pA.Parent or not profA or not getCharRoot(pA) then
		cancelTradeSession(session, "Người chơi đã rời bàn giao dịch.")
		return
	end
	if profA._ReadOnlyFallback == true or (D.Sessions and D.Sessions[pA] and D.Sessions[pA].ReadOnlyFallback == true) then
		cancelTradeSession(session, "Không thể giao dịch khi dữ liệu đang ở chế độ Bảo Vệ (ReadOnly)!")
		return
	end
	ensureExpansionProfile(profA)

	local valA = computeOfferValue(session.OfferA)
	local valB = computeOfferValue(session.OfferB)
	local _, withinLimit = computeTradeValueDiff(valA, valB)
	if not withinLimit then
		session.Countdown = 0
		session.AcceptedA = false
		session.AcceptedB = false
		sendTradeSnapshot(session, "TradeError", "Chênh lệch giá trị vượt quá 40%!")
		return
	end

	-- Verify PlayerA owns all offered fruits right before atomic swap
	local needA = {}
	for _, rawFid in ipairs(session.OfferA) do
		local fid = CombatData.ResolveFruitId(rawFid)
		if fid ~= "" then
			needA[fid] = (needA[fid] or 0) + 1
		end
	end
	for fid, cnt in pairs(needA) do
		if (tonumber(profA.StoredFruits[fid]) or 0) < cnt then
			cancelTradeSession(session, "Kho Lõi Aether của " .. pA.Name .. " không đủ số lượng đã đặt!")
			return
		end
	end

	local pB = session.PlayerB
	local profB = (not session.IsNPCCollector and pB) and D.Get(pB) or nil
	local needB = {}
	if not session.IsNPCCollector then
		if not pB or not pB.Parent or not profB or not getCharRoot(pB) then
			cancelTradeSession(session, "Đối tác đã rời bàn giao dịch.")
			return
		end
		if profB._ReadOnlyFallback == true or (D.Sessions and D.Sessions[pB] and D.Sessions[pB].ReadOnlyFallback == true) then
			cancelTradeSession(session, "Đối tác đang ở chế độ Bảo Vệ Dữ Liệu (ReadOnly), không thể giao dịch!")
			return
		end
		ensureExpansionProfile(profB)
		for _, rawFid in ipairs(session.OfferB) do
			local fid = CombatData.ResolveFruitId(rawFid)
			if fid ~= "" then
				needB[fid] = (needB[fid] or 0) + 1
			end
		end
		for fid, cnt in pairs(needB) do
			if (tonumber(profB.StoredFruits[fid]) or 0) < cnt then
				cancelTradeSession(session, "Kho Lõi Aether của " .. pB.Name .. " không đủ số lượng đã đặt!")
				return
			end
		end
	else
		for _, rawFid in ipairs(session.OfferB) do
			local fid = CombatData.ResolveFruitId(rawFid)
			if fid ~= "" then
				needB[fid] = (needB[fid] or 0) + 1
			end
		end
	end

	-- Enforce GetMaxCoreStorage cap on BOTH receiving sides before mutating inventories
	local maxStoreA = getMaxCoreStorage(pA, profA)
	local maxStoreB = (profB and pB) and getMaxCoreStorage(pB, profB) or 999
	if profB and pB then
		for fid, cnt in pairs(needA) do
			local curB = math.max(0, (tonumber(profB.StoredFruits[fid]) or 0) - (needB[fid] or 0))
			if (curB + cnt) > maxStoreB then
				cancelTradeSession(
					session,
					string.format(
						"Kho Lõi Aether của %s đã đầy [%s] (%d/%d)! / %s's Core Storage is full (%d/%d)!",
						pB.Name,
						fid,
						tonumber(profB.StoredFruits[fid]) or 0,
						maxStoreB,
						pB.Name,
						tonumber(profB.StoredFruits[fid]) or 0,
						maxStoreB
					)
				)
				return
			end
		end
	end
	for fid, cnt in pairs(needB) do
		local curA = math.max(0, (tonumber(profA.StoredFruits[fid]) or 0) - (needA[fid] or 0))
		if (curA + cnt) > maxStoreA then
			cancelTradeSession(
				session,
				string.format(
					"Kho Lõi Aether của %s đã đầy [%s] (%d/%d)! / %s's Core Storage is full (%d/%d)!",
					pA.Name,
					fid,
					tonumber(profA.StoredFruits[fid]) or 0,
					maxStoreA,
					pA.Name,
					tonumber(profA.StoredFruits[fid]) or 0,
					maxStoreA
				)
			)
			return
		end
	end

	session.Swapping = true

	-- Atomic deduction and swap
	for fid, cnt in pairs(needA) do
		profA.StoredFruits[fid] = math.max(0, (tonumber(profA.StoredFruits[fid]) or 0) - cnt)
		if profA.StoredFruits[fid] <= 0 then
			profA.StoredFruits[fid] = nil
		end
		if profB then
			profB.StoredFruits[fid] = (tonumber(profB.StoredFruits[fid]) or 0) + cnt
		end
	end
	for fid, cnt in pairs(needB) do
		if profB then
			profB.StoredFruits[fid] = math.max(0, (tonumber(profB.StoredFruits[fid]) or 0) - cnt)
			if profB.StoredFruits[fid] <= 0 then
				profB.StoredFruits[fid] = nil
			end
		end
		profA.StoredFruits[fid] = (tonumber(profA.StoredFruits[fid]) or 0) + cnt
	end

	local function clearOrphanHeldFruit(plr, prof)
		local held = CombatData.ResolveFruitId(prof.HeldFruit or "")
		if held ~= "" and (tonumber(prof.StoredFruits[held]) or 0) <= 0 and CombatData.ResolveFruitId(prof.EquippedFruit or "") ~= held then
			prof.HeldFruit = ""
			plr:SetAttribute("HeldFruit", "")
			if plr.Character then
				plr.Character:SetAttribute("HeldFruit", "")
			end
		end
	end
	clearOrphanHeldFruit(pA, profA)
	if profB and pB then
		clearOrphanHeldFruit(pB, profB)
	end

	unlockTitle(pA, profA, "cafe_broker", false)
	G.Notify(pA, "GIAO DỊCH THÀNH CÔNG! Đã hoán đổi Lõi Aether an toàn!")
	G.Sync(pA)
	D.Save(pA, false)

	if profB and pB then
		unlockTitle(pB, profB, "cafe_broker", false)
		G.Notify(pB, "GIAO DỊCH THÀNH CÔNG! Đã hoán đổi Lõi Aether an toàn!")
		G.Sync(pB)
		D.Save(pB, false)
	end

	sendTradeSnapshot(session, "TradeCompleted", "Giao dịch hoàn tất!")
	session.Closed = true
	ActiveTrades[session.Id] = nil
	PlayerTradeMap[pA] = nil
	pA:SetAttribute("InTrade", false)
	if pB then
		PlayerTradeMap[pB] = nil
		if pB.Parent then
			pB:SetAttribute("InTrade", false)
		end
	end
	if session.NPCModel and session.NPCModel.Parent then
		session.NPCModel:Destroy()
	end
end

local function startTradeCountdownIfReady(session)
	if not session or session.Closed then
		return
	end
	local valA = computeOfferValue(session.OfferA)
	local valB = computeOfferValue(session.OfferB)
	local diffRatio, withinLimit = computeTradeValueDiff(valA, valB)
	if not (session.AcceptedA and session.AcceptedB and withinLimit) then
		session.Countdown = 0
		session.CountdownToken = (session.CountdownToken or 0) + 1
		return
	end

	session.CountdownToken = (session.CountdownToken or 0) + 1
	local myToken = session.CountdownToken
	session.Countdown = CombatData.TradeCountdownSeconds

	sendTradeSnapshot(session, "TradeCountdown", string.format("Đếm ngược %ds (Chênh lệch %d%% <= 40%%)", session.Countdown, math.floor(diffRatio * 100 + 0.5)))

	task.spawn(function()
		for rem = CombatData.TradeCountdownSeconds - 1, 0, -1 do
			task.wait(1.0)
			if session.Closed or session.CountdownToken ~= myToken then
				return
			end
			if not (session.PlayerA and session.PlayerA.Parent and getCharRoot(session.PlayerA))
				or (not session.IsNPCCollector and not (session.PlayerB and session.PlayerB.Parent and getCharRoot(session.PlayerB))) then
				cancelTradeSession(session, "Người chơi đã rời bàn giao dịch.")
				return
			end
			if not (session.AcceptedA and session.AcceptedB) then
				session.Countdown = 0
				sendTradeSnapshot(session, "TradeState", "Đã hủy đếm ngược.")
				return
			end
			session.Countdown = rem
			if rem > 0 then
				sendTradeSnapshot(session, "TradeCountdown", string.format("Đếm ngược %ds...", rem))
			else
				executeAtomicTradeSwap(session)
			end
		end
	end)
end

function Expansion.HandleTradeAction(p, actionOrPayload, arg2)
	if not consumeToken(p, 1) then
		return
	end
	local act = actionOrPayload
	local data = arg2
	if type(actionOrPayload) == "table" then
		act = actionOrPayload.action or actionOrPayload.Action or actionOrPayload.cmd
		data = actionOrPayload
	end
	act = tostring(act or "")
	local session = PlayerTradeMap[p]
	if not session or session.Closed then
		if act ~= "CancelTrade" then
			G.Notify(p, "Hãy ngồi vào Bàn Giao Dịch 4 Ghế tại Trạm Giao Thương (Trade Station) để bắt đầu giao dịch!")
		end
		return
	end

	local isSideA = (session.PlayerA == p)
	local isSideB = (not session.IsNPCCollector and session.PlayerB == p)
	if not isSideA and not isSideB then
		return
	end

	local profile = D.Get(p)
	if not profile then
		return
	end
	ensureExpansionProfile(profile)

	local myOffer = isSideA and session.OfferA or session.OfferB
	local rawFruit = type(data) == "string" and data or (type(data) == "table" and (data.fruitId or data.id)) or ""
	local cid = CombatData.ResolveFruitId(rawFruit)

	if act == "AddFruit" then
		if cid == "" or not CombatData.FruitCatalog[cid] then
			return
		end
		if #myOffer >= 4 then
			G.Notify(p, "Chỉ được đặt tối đa 4 Lõi Aether mỗi phiên giao dịch!")
			return
		end
		local alreadyOffered = 0
		for _, f in ipairs(myOffer) do
			if f == cid then
				alreadyOffered += 1
			end
		end
		if (tonumber(profile.StoredFruits[cid]) or 0) <= alreadyOffered then
			G.Notify(p, "Bạn không đủ [" .. cid .. "] trong kho lưu trữ!")
			return
		end
		table.insert(myOffer, cid)
		-- Reset countdown & ready states whenever either side modifies offer!
		session.AcceptedA = false
		session.AcceptedB = false
		session.Countdown = 0
		session.CountdownToken = (session.CountdownToken or 0) + 1
		if session.IsNPCCollector then
			syncNPCCollectorOffer(session)
		end
		sendTradeSnapshot(session, "TradeState", "Đã thêm " .. CombatData.FruitCatalog[cid].Name)

	elseif act == "RemoveFruit" then
		for idx = #myOffer, 1, -1 do
			if cid == "" or myOffer[idx] == cid then
				table.remove(myOffer, idx)
				break
			end
		end
		session.AcceptedA = false
		session.AcceptedB = false
		session.Countdown = 0
		session.CountdownToken = (session.CountdownToken or 0) + 1
		if session.IsNPCCollector then
			syncNPCCollectorOffer(session)
		end
		sendTradeSnapshot(session, "TradeState", "Đã gỡ trái khỏi bàn giao dịch.")

	elseif act == "AcceptTrade" then
		local valA = computeOfferValue(session.OfferA)
		local valB = computeOfferValue(session.OfferB)
		local diffRatio, withinLimit = computeTradeValueDiff(valA, valB)
		if not withinLimit then
			G.Notify(p, string.format("KHÓA 40%% GIÁ TRỊ: Chênh lệch hiện tại %d%% (> 40%%)! Hãy cân bằng giá trị hai bên!", math.floor(diffRatio * 100 + 0.5)))
			sendTradeSnapshot(session, "TradeLocked", "Chênh lệch vượt quá 40%!")
			return
		end
		if isSideA then
			session.AcceptedA = true
		else
			session.AcceptedB = true
		end
		if session.IsNPCCollector and #session.OfferB > 0 then
			session.AcceptedB = true
		end
		sendTradeSnapshot(session, "TradeState", p.Name .. " đã xác nhận giao dịch.")
		startTradeCountdownIfReady(session)

	elseif act == "CancelTrade" then
		cancelTradeSession(session, p.Name .. " đã hủy giao dịch.")
	end
end

local function buildCafeTradingTables()
	local hubFolder = ensureWorldFolder("CyberportCafeTradingHub")
	hubFolder:ClearAllChildren()
	-- Duplicate blocky FruitTradingTable_1/2 props removed; Trade Station broker & UI handle fruit trading cleanly.
end

-- ============================================================================
-- WATER / DENSE-CLOUD SEA HAZARD & ICE/MAGMA STEPPING PLATFORMS (#46)
-- ============================================================================
local function tickPlayerWaterAndFury(p, dt)
	local hrp, hum, ch = getCharRoot(p)
	local rt = G.Runtime[p]
	local profile = D.Get(p)
	if not hrp or not hum or not rt or not profile then
		return
	end
	ensureExpansionProfile(profile)
	ensureRuntimeFields(p, rt, profile)

	-- #48: Fury Meter passive regen / transformation drain (authoritatively managed in CombatRuntimeOverrides when hooked)
	local fid = CombatData.ResolveFruitId(profile.EquippedFruit)
	local cat = CombatData.FruitCatalog[fid]
	local curTf = tostring((ch and ch:GetAttribute("FruitTransform")) or p:GetAttribute("FruitTransform") or "")
	if (curTf == "SolarTitan" and fid ~= "SolarTitanCore")
		or ((curTf == "AbyssalSovereign" or curTf == "AbyssalDragonHybrid" or (rt.DragonFormTier or 0) > 0) and fid ~= "AbyssalSovereignCore") then
		rt.DragonFormTier = 0
		p:SetAttribute("DragonFormTier", 0)
		p:SetAttribute("FruitTransform", "")
		if ch then
			ch:SetAttribute("DragonFormTier", 0)
			ch:SetAttribute("FruitTransform", "")
		end
		if not TRUE_FLIGHT_FRUITS[fid] then
			rt.FreeFlightActive = false
			p:SetAttribute("SkybreakFlightActive", false)
			if ch then
				ch:SetAttribute("SkybreakFlightActive", false)
			end
		end
	elseif (rt.DragonFormTier or 0) > 0 and ((p:GetAttribute("DragonFormTier") or 0) == 0 or (ch and (ch:GetAttribute("DragonFormTier") or 0) == 0)) then
		rt.DragonFormTier = 0
		p:SetAttribute("FruitTransform", "")
	end
	if not G._DragonDualFormsHooked then
		local nowF = os.clock()
		local inCombat = (nowF - math.max(tonumber(rt.LastCombatAt) or 0, tonumber(rt.LastHurt) or 0)) < 6.0
		if (rt.DragonFormTier or 0) >= 2 and inCombat then
			rt.FuryMeter = math.max(0, (tonumber(rt.FuryMeter) or 100) - 1.8 * dt)
			if rt.FuryMeter <= 0 then
				rt.DragonFormTier = 0
				rt.FreeFlightActive = false
				p:SetAttribute("DragonFormTier", 0)
				p:SetAttribute("FruitTransform", "")
				p:SetAttribute("SkybreakFlightActive", false)
				if ch then
					ch:SetAttribute("DragonFormTier", 0)
					ch:SetAttribute("FruitTransform", "")
					ch:SetAttribute("SkybreakFlightActive", false)
				end
				G.Notify(p, "Nộ Khí (Fury) đã cạn - Kết thúc trạng thái Thái Cổ Long Hoàng.")
				G.Sync(p)
			end
		elseif not inCombat then
			rt.FuryMeter = math.min(100, (tonumber(rt.FuryMeter) or 100) + 3.0 * dt)
		end
	end
	local furyInt = math.floor((tonumber(rt.FuryMeter) or 0) + 0.5)
	rt.DragonFury = tonumber(rt.FuryMeter) or furyInt
	p:SetAttribute("FuryMeter", furyInt)
	p:SetAttribute("DragonFury", furyInt)
	if ch then
		ch:SetAttribute("FuryMeter", furyInt)
		ch:SetAttribute("DragonFury", furyInt)
	end

	-- #52: Race V4 active passives & AwakeningMeter drain (charged via combat hits/damage taken!)
	if profile.RaceV4Active then
		local race = profile.Race or "Skyborn"
		local now = os.clock()
		profile.AwakeningMeter = math.max(0, (tonumber(profile.AwakeningMeter) or 100) - 2.2 * dt)
		rt.AwakeningMeter = profile.AwakeningMeter
		p:SetAttribute("AwakeningMeter", math.floor(profile.AwakeningMeter + 0.5))
		if profile.AwakeningMeter <= 0 then
			local prevPct = (hum.MaxHealth > 0) and math.clamp(hum.Health / hum.MaxHealth, 0.01, 1) or 1
			profile.RaceV4Active = false
			rt.LeviathanShieldHP = 0
			p:SetAttribute("RaceV4Active", false)
			p:SetAttribute("RaceV4", "")
			p:SetAttribute("LeviathanShieldHP", 0)
			if ch then
				ch:SetAttribute("RaceV4Active", false)
				ch:SetAttribute("RaceV4", "")
				ch:SetAttribute("LeviathanShieldHP", 0)
			end
			local sAfter = G.Stats(p)
			if sAfter and hum.Health > 0 then
				hum.MaxHealth = sAfter.HP
				hum.Health = math.clamp(math.floor(sAfter.HP * prevPct), 1, sAfter.HP)
			end
			G.Notify(p, "Năng lượng Thức Tỉnh V4 đã cạn — Thu hồi huyết mạch [" .. race .. "].")
			G.Sync(p)
		elseif race == "Skyborn" and now >= (rt.NextSkybornPulse or 0) then
			rt.NextSkybornPulse = now + CombatData.RaceV4Passives.Skyborn.StaggerInterval
			for _, e in ipairs(G.Enemies or {}) do
				if e.Alive and e.Body and (e.Body.Position - hrp.Position).Magnitude <= CombatData.RaceV4Passives.Skyborn.StaggerRadius then
					if not isBossEnemy(e) then
						e.StunnedUntil = math.max(e.StunnedUntil or 0, now + CombatData.RaceV4Passives.Skyborn.StaggerDuration)
					else
						updateBossBreakGauge(e, 6)
					end
				end
			end
		elseif race == "Leviathan" then
			local maxShield = math.floor(hum.MaxHealth * CombatData.RaceV4Passives.Leviathan.ShieldMaxHPPct)
			local regen = hum.MaxHealth * CombatData.RaceV4Passives.Leviathan.ShieldRegenPctPerSec * dt
			rt.LeviathanShieldHP = math.min(maxShield, (rt.LeviathanShieldHP or 0) + regen)
			p:SetAttribute("LeviathanShieldHP", math.floor(rt.LeviathanShieldHP))
			if ch then
				ch:SetAttribute("LeviathanShieldHP", math.floor(rt.LeviathanShieldHP))
			end
		elseif race == "Draco" and now >= (rt.NextDracoAura or 0) then
			rt.NextDracoAura = now + 1.0
			local st = G.Stats(p)
			local burnDmg = ((st and st.ATK) or 50) * CombatData.RaceV4Passives.Draco.BurnAuraAtkRatio
			for _, e in ipairs(G.Enemies or {}) do
				if e.Alive and e.Body and (e.Body.Position - hrp.Position).Magnitude <= CombatData.RaceV4Passives.Draco.BurnAuraRadius then
					G.Hit(p, e, burnDmg, 4, "DracoV4PyreAura")
				end
			end
		end
	else
		local curAwk = math.clamp(math.max(tonumber(profile.AwakeningMeter) or 0, tonumber(rt.AwakeningMeter) or 0), 0, 100)
		profile.AwakeningMeter = curAwk
		rt.AwakeningMeter = curAwk
		p:SetAttribute("AwakeningMeter", math.floor(curAwk + 0.5))
	end

	-- #46: Water / Low-Sea Zone Detection
	local hit = W and W.RaycastGround and W.RaycastGround(hrp.Position + Vector3.new(0, 4, 0), hrp.Position.Y - 4)
	local onWaterPart = hit and hit.Instance and (hit.Instance:GetAttribute("IsSeaWaterZone") == true or string.find(string.lower(hit.Instance.Name), "water", 1, true) ~= nil)
	local inLowSeaPlane = (hrp.Position.Y <= 23.5 and hrp.Position.Y >= 11.0) and (onWaterPart or not hit)

	rt.InWaterZone = inLowSeaPlane or onWaterPart
	if rt.InWaterZone then
		if profile.Race == "Leviathan" then
			-- Leviathan swims freely with +35% speed & 80% water resistance!
			hum.WalkSpeed = math.max(hum.WalkSpeed, 24 * 1.35)
		elseif cat and cat.WaterWalk then
			-- GlacierIceCore ("Ice") or StarforgedMagmaCore ("Basalt") spawns solid 3D stepping platforms!
			rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, os.clock() + 0.8)
			WildCoreService.SpawnSteppingPlatform(p, hrp.Position, cat.WaterWalk)
		elseif fid ~= "" then
			-- Gentle water-drain for non-Leviathan Devil Fruit users
			local drainHP = math.max(1, hum.MaxHealth * 0.035 * dt)
			if hum.Health > drainHP + 5 then
				hum:TakeDamage(drainHP)
			end
			rt.Energy = math.max(0, (tonumber(rt.Energy) or tonumber(rt.MaxEnergy) or 100) - 4 * dt)
		end
	end
end

-- ============================================================================
-- TEMPLE OF THE CORE RACE V4 TRIAL (#51) & DR. VEGA RACE REROLL (#59) & STYLES
-- ============================================================================
function Expansion.RerollRace(p)
	local profile = D.Get(p)
	if not profile then
		return false
	end
	ensureExpansionProfile(profile)
	local cost = CombatData.RaceRerollCostShards or 50
	if (profile.CoreShards or 0) < cost then
		G.Notify(p, string.format("Cần %d Core Shards để gặp Dr. Vega đổi Tộc Hệ (Hiện có %d)!", cost, profile.CoreShards or 0))
		return false
	end

	profile.CoreShards -= cost
	local pool = {}
	for _, rName in ipairs(CombatData.RaceOrder) do
		if rName ~= profile.Race then
			table.insert(pool, rName)
		end
	end
	local newRace = (#pool > 0 and pool[math.random(1, #pool)]) or "Skyborn"
	profile.Race = newRace
	p:SetAttribute("Race", newRace)
	if profile.RaceV4Active then
		p:SetAttribute("RaceV4", newRace)
	end
	if newRace ~= "Leviathan" then
		local rt = G and G.Runtime and G.Runtime[p]
		if rt then
			rt.LeviathanShieldHP = 0
		end
		p:SetAttribute("LeviathanShieldHP", 0)
	end
	if p.Character then
		p.Character:SetAttribute("Race", newRace)
		if profile.RaceV4Active then
			p.Character:SetAttribute("RaceV4", newRace)
		end
		if newRace ~= "Leviathan" then
			p.Character:SetAttribute("LeviathanShieldHP", 0)
		end
	end
	G.Notify(p, "DR. VEGA: Đã tái cấu trúc ADN thành công -> Tộc Hệ mới: [" .. newRace .. "] (-50 Core Shards)!")
	G.Sync(p)
	return true
end

function Expansion.SelectOrLearnStyle(p, rawStyleId)
	local profile = D.Get(p)
	if not profile then
		return false
	end
	ensureExpansionProfile(profile)
	local sid = CombatData.ResolveStyleId(rawStyleId)
	local style = CombatData.MartialStyles[sid]
	local req = Helpers.GetMartialReq(sid) or Helpers.GetMartialReq(rawStyleId)
	if not style and not req then
		return false
	end
	local canonSid = (style and sid) or (req and req.Id) or sid
	local dispName = (style and style.DisplayName) or (req and req.Name) or canonSid

	local alreadyUnlocked = profile.UnlockedStyles[canonSid] == true
		or (req and req.Alias and profile.UnlockedStyles[req.Alias] == true)
		or (canonSid == "SkyStep" and profile.UnlockedStyles.sky_step == true)
		or (canonSid == "ChronoVoidPalm" and profile.UnlockedStyles.chrono_void_palm == true)
	if not alreadyUnlocked then
		local minLv = (req and (req.MinLevel or req.LevelReq)) or (style and (style.LevelReq or style.MinLevel)) or 1
		local reqMas = (req and req.ReqMastery) or (style and style.ReqMastery) or 0
		local needGold = (req and req.Gold) or (style and style.PriceGold) or 0
		local needShards = (req and req.Shards) or (style and style.PriceShards) or 0
		local curLv = tonumber(profile.Level) or 1
		if curLv < minLv then
			G.Notify(p, string.format("Lĩnh ngộ [%s] yêu cầu đạt Lv. %d+ (Hiện tại: Lv. %d)!", dispName, minLv, curLv))
			return false
		end
		if reqMas > 0 then
			local bestMas = Helpers.GetBestMartialMastery(profile)
			if bestMas < reqMas then
				G.Notify(p, string.format("Lĩnh ngộ [%s] yêu cầu Mastery Võ Thuật %d+ (Hiện tại cao nhất: %d)!", dispName, reqMas, bestMas))
				return false
			end
		end
		if (tonumber(profile.Gold) or 0) < needGold or (tonumber(profile.CoreShards) or 0) < needShards then
			G.Notify(p, string.format("Cần %d Gold & %d Core Shards để lĩnh ngộ [%s]!", needGold, needShards, dispName))
			return false
		end
		profile.Gold = (tonumber(profile.Gold) or 0) - needGold
		profile.CoreShards = (tonumber(profile.CoreShards) or 0) - needShards
		profile.UnlockedStyles[canonSid] = true
		if req and req.Alias then
			profile.UnlockedStyles[req.Alias] = true
		end
		if canonSid == "SkyStep" then
			profile.UnlockedStyles.sky_step = true
		elseif canonSid == "ChronoVoidPalm" then
			profile.UnlockedStyles.chrono_void_palm = true
		end
	end

	profile.FightingStyle = canonSid
	profile.ActiveSlot = 1
	p:SetAttribute("FightingStyle", canonSid)
	if p.Character then
		p.Character:SetAttribute("FightingStyle", canonSid)
	end
	evaluateAutoTitles(p, profile)
	G.Notify(p, "Đã trang bị Võ Thuật [Slot 1]: " .. dispName .. "!")
	G.Sync(p)
	return true
end

local function startTempleRaceV4Trial(p, altarPos)
	local profile = D.Get(p)
	local hrp = getCharRoot(p)
	if not profile or not hrp then
		return false
	end
	ensureExpansionProfile(profile)

	-- Strict Endgame Gate (D-A7): RaceTier >= 3 AND Level >= 1900 AND BlueResonanceGearFound == true required before Temple V4 Trial!
	local curTier = math.clamp(tonumber(profile.RaceTier) or (profile.RaceV4Unlocked and 4 or 1), 1, 4)
	local curLv = tonumber(profile.Level) or 1
	if curTier < 3 or curLv < 1900 then
		G.Notify(
			p,
			string.format(
				"Khảo Thí Đền Thăng Hoa (Tộc V4) yêu cầu đạt Tộc V3 và Lv. 1900+ (Hiện tại: V%d • Lv. %d)! / Ancient Temple V4 Trial requires Race V3 and Lv. 1900+ (Current: V%d • Lv. %d)!",
				curTier,
				curLv,
				curTier,
				curLv
			)
		)
		return false
	end
	if p:GetAttribute("BlueResonanceGearFound") == true then
		profile.BlueResonanceGearFound = true
	end
	if profile.RaceV4Unlocked ~= true and profile.BlueResonanceGearFound ~= true then
		G.Notify(
			p,
			"Khảo Thí Đền Thăng Hoa (Tộc V4) yêu cầu tìm được [Bánh Răng Cộng Hưởng Xanh / Blue Resonance Gear] trên Đảo Hư Quang (Mirage Sky Island) trước! / Requires finding the [Blue Resonance Gear] on Mirage Sky Island first!"
		)
		return false
	end

	if not altarPos then
		local defaultTemple = ((C and C.FastTravel and C.FastTravel.TempleOfTheCore and C.FastTravel.TempleOfTheCore.Pos) or Vector3.new(-14600, 50.9, -1785)) + Vector3.new(0, -4, -12)
		local sagePlaza = Vector3.new(-11685, 46.9, -106)
		if (hrp.Position - sagePlaza).Magnitude <= 220 then
			altarPos = sagePlaza
		else
			altarPos = defaultTemple
		end
	end
	if TrialSessions[p] and TrialSessions[p].Active then
		G.Notify(p, "Bạn đang trong Thử Thách Thăng Hoa (60s)!")
		return true
	end

	local enemies = {}
	local offsets = { Vector3.new(-14, 2, -10), Vector3.new(14, 2, -10), Vector3.new(0, 2, -16) }
	for _, off in ipairs(offsets) do
		local e = G.SpawnEnemy("AbyssalKnight", altarPos + off, false, true)
		if e then
			e.MaxHP = math.max(900, math.floor((profile.Level or 1900) * 14))
			e.HP = e.MaxHP
			table.insert(enemies, e)
		end
	end

	local session = {
		Active = true,
		EndsAt = os.clock() + CombatData.TrialDurationSeconds,
		Enemies = enemies,
	}
	TrialSessions[p] = session
	p:SetAttribute("InRaceTrial", true)
	G.Notify(p, "THỬ THÁCH THĂNG HOA BẮT ĐẦU (60 GIÂY): Tiêu diệt 3 Hộ Vệ Đền Thăng Hoa để mở khóa vĩnh viễn TỘC V4 & Core Gear!")

	task.spawn(function()
		while session.Active and p.Parent and os.clock() < session.EndsAt do
			local trialHrp, trialHum = getCharRoot(p)
			if not trialHrp or not trialHum or (trialHrp.Position - altarPos).Magnitude > 220 then
				session.Active = false
				TrialSessions[p] = nil
				if p.Parent then
					p:SetAttribute("InRaceTrial", false)
				end
				for _, e in ipairs(session.Enemies) do
					if e and e.Alive and e.Model and e.Model.Parent then
						e.Alive = false
						e.Model:Destroy()
					end
				end
				if p.Parent then
					G.Notify(p, "Thử Thách Thăng Hoa kết thúc do bạn đã rời khỏi khu vực Tế Đàn!")
				end
				return
			end
			local allDefeated = true
			for _, e in ipairs(session.Enemies) do
				if e and e.Alive then
					allDefeated = false
					break
				end
			end
			if allDefeated then
				session.Active = false
				TrialSessions[p] = nil
				if p.Parent then
					p:SetAttribute("InRaceTrial", false)
				end
				local prof = D.Get(p)
				if prof then
					ensureExpansionProfile(prof)
					prof.RaceV4Unlocked = true
					prof.RaceTier = 4
					prof.CoreGears = (prof.CoreGears or 0) + 1
					prof.AwakeningMeter = 100
					if G.Runtime and G.Runtime[p] then
						G.Runtime[p].AwakeningMeter = 100
					end
					prof.CoreShards = (prof.CoreShards or 0) + 300
					unlockTitle(p, prof, "core_gear_awakened", false)
					p:SetAttribute("RaceV4Unlocked", true)
					p:SetAttribute("RaceTier", 4)
					p:SetAttribute("AwakeningMeter", 100)
					G.Notify(p, "HOÀN TẤT THỬ THÁCH THĂNG HOA! Đã mở khóa vĩnh viễn TỘC V4 [" .. tostring(prof.Race) .. "] + 1 Core Gear + 300 Shards!")
					local curHrp = getCharRoot(p)
					if curHrp and R and R.CombatFX then
						R.CombatFX:FireAllClients({
							Kind = "RaceV4Unlock",
							Race = prof.Race,
							Position = curHrp.Position,
							Actor = p.UserId,
						})
					end
					G.Sync(p)
					task.spawn(D.Save, p, false)
				end
				return
			end
			task.wait(0.35)
		end
		if session.Active then
			session.Active = false
			TrialSessions[p] = nil
			if p.Parent then
				p:SetAttribute("InRaceTrial", false)
			end
			for _, e in ipairs(session.Enemies) do
				if e and e.Alive and e.Model and e.Model.Parent then
					e.Alive = false
					e.Model:Destroy()
				end
			end
			if p.Parent then
				G.Notify(p, "Hết 60 giây Thử Thách Đền Thăng Hoa! Hãy gặp Hiền Triết Thăng Hoa để thử lại.")
			end
		end
	end)
end

-- ============================================================================
-- 10M RENOWN ALLIED SKY BEAST GUARDIAN SUMMON (#57)
-- ============================================================================
function Expansion.SummonAlliedSeaBeast(p)
	return WildCoreService.SummonAlliedSeaBeast(p, ensureExpansionProfile, formatBountyShort)
end

-- ============================================================================
-- WAVE 1 AUTHORITATIVE UI HANDLERS (#100 GIFTCODES, #104 STARS, #60 PRESETS)
-- ============================================================================
function Expansion.RefundAllStats(p, silent, bypassCost)
	local profile = D.Get(p)
	local rt = G and G.Runtime and G.Runtime[p]
	if not profile then
		return 0, false
	end
	ensureExpansionProfile(profile)
	if not bypassCost and rt and rt.LastStatRefundAt and (os.clock() - rt.LastStatRefundAt) < 0.25 then
		return 0, true
	end
	profile.StatAlloc = type(profile.StatAlloc) == "table" and profile.StatAlloc or { Melee = 1, Defense = 1, Sword = 1, Gun = 1, Fruit = 1 }
	local pendingRefund = 0
	for _, v in pairs(profile.StatAlloc) do
		local n = math.floor(tonumber(v) or 1)
		if n > 1 then
			pendingRefund += (n - 1)
		end
	end
	if pendingRefund <= 0 then
		if not silent then
			G.Notify(p, "Chưa có điểm chỉ số nào đã cộng để hoàn trả! / No allocated stat points to reset!")
		end
		return 0, true
	end

	local costTag = ""
	if not bypassCost then
		local shardCost = (C and tonumber(C.StatRefundCostShards)) or 150
		local tokens = math.max(0, math.floor(tonumber(profile.StatRefundTokens) or 0))
		local shards = math.max(0, math.floor(tonumber(profile.CoreShards) or 0))
		if tokens > 0 then
			profile.StatRefundTokens = tokens - 1
			costTag = " (-1 Thẻ Tẩy Điểm / Stat Refund Token)"
		elseif shards >= shardCost then
			profile.CoreShards = shards - shardCost
			costTag = string.format(" (-%d Core Shards)", shardCost)
		else
			G.Notify(
				p,
				string.format(
					"Cần 1 Thẻ Tẩy Điểm hoặc %d Core Shards để Tẩy Điểm Chỉ Số (Hiện có: %d Shards)! / Requires 1 Stat Refund Token or %d Core Shards (Current: %d Shards)!",
					shardCost,
					shards,
					shardCost,
					shards
				)
			)
			return 0, false
		end
		if rt then
			rt.LastStatRefundAt = os.clock()
		end
	end

	for k, v in pairs(profile.StatAlloc) do
		local n = math.floor(tonumber(v) or 1)
		if n > 1 then
			profile.StatAlloc[k] = 1
		end
	end
	profile.StatPoints = (tonumber(profile.StatPoints) or 0) + pendingRefund
	if not silent then
		G.Notify(p, string.format("Đã hoàn trả toàn bộ chỉ số%s! Tổng Stat Points khả dụng: %d", costTag, profile.StatPoints))
	end
	return pendingRefund, true
end

Expansion.GetMaxCoreStorage = getMaxCoreStorage

-- Ngay publish: lan dau mot server that (khong phai Studio) chay, ghi os.time() vao DataStore.
-- Loi DataStore thi tra nil va giftcode tam khong tinh han, de khong khoa nham nguoi choi.
local launchUnixCache = nil
local launchUnixRetryAt = 0
local function getLaunchUnix()
	if tonumber(CombatData.LaunchUnixOverride) then
		return tonumber(CombatData.LaunchUnixOverride)
	end
	if launchUnixCache then
		return launchUnixCache
	end
	if game:GetService("RunService"):IsStudio() then
		return nil
	end
	if os.clock() < launchUnixRetryAt then
		return nil
	end
	launchUnixRetryAt = os.clock() + 60
	local ok, value = pcall(function()
		local store = game:GetService("DataStoreService"):GetDataStore("SKYBREAK_META_v1")
		return store:UpdateAsync("LaunchUnix", function(old)
			if tonumber(old) then
				return nil
			end
			return os.time()
		end)
	end)
	if ok and tonumber(value) then
		launchUnixCache = tonumber(value)
	elseif ok then
		local okGet, got = pcall(function()
			return game:GetService("DataStoreService"):GetDataStore("SKYBREAK_META_v1"):GetAsync("LaunchUnix")
		end)
		if okGet and tonumber(got) then
			launchUnixCache = tonumber(got)
		end
	end
	return launchUnixCache
end

function Expansion.RedeemCode(p, rawCode)
	local profile = D.Get(p)
	local rt = G.Runtime[p]
	if not profile or not rt then
		return false
	end
	ensureExpansionProfile(profile)
	ensureRuntimeFields(p, rt, profile)

	local cleaned = string.upper(string.gsub(tostring(rawCode or ""), "%s+", ""))
	if cleaned == "" then
		return false
	end

	-- Deduplicate dual-remote clicks (Settings.lua fires UIRequest AND EquipmentRequest together)
	local now = os.clock()
	if rt.RecentCodeDedup[cleaned] and (now - rt.RecentCodeDedup[cleaned]) < 0.75 then
		return true
	end
	rt.RecentCodeDedup[cleaned] = now

	local spec = CombatData.Giftcodes[cleaned]
	if not spec then
		G.Notify(p, "Giftcode không hợp lệ hoặc đã hết hạn: [" .. cleaned .. "]!")
		return false
	end
	local expiresAt = tonumber(spec.Expires)
	if not expiresAt and tonumber(spec.ExpiresDays) then
		local launchUnix = getLaunchUnix()
		if launchUnix then
			expiresAt = launchUnix + tonumber(spec.ExpiresDays) * 86400
		end
	end
	if expiresAt and os.time() > expiresAt then
		G.Notify(p, "Giftcode [" .. cleaned .. "] đã hết hạn sử dụng!")
		return false
	end
	local playerLv = tonumber(profile.Level) or 1
	if tonumber(spec.MinLevel) and playerLv < tonumber(spec.MinLevel) then
		G.Notify(p, string.format("Giftcode [%s] yêu cầu đạt tối thiểu Level %d!", cleaned, tonumber(spec.MinLevel)))
		return false
	end
	if tonumber(spec.MaxLevel) and playerLv > tonumber(spec.MaxLevel) then
		G.Notify(p, string.format("Giftcode [%s] chỉ dành cho người chơi từ Level %d trở xuống!", cleaned, tonumber(spec.MaxLevel)))
		return false
	end
	if profile.RedeemedCodes[cleaned] == true then
		G.Notify(p, "Bạn đã sử dụng Giftcode [" .. cleaned .. "] trước đó!")
		return false
	end

	local grantFid = nil
	if spec.StoredFruit then
		grantFid = CombatData.ResolveFruitId(spec.StoredFruit)
		if grantFid == "" then
			grantFid = tostring(spec.StoredFruit)
		end
		profile.StoredFruits = type(profile.StoredFruits) == "table" and profile.StoredFruits or {}
		local maxStore = (Expansion.GetMaxCoreStorage and Expansion.GetMaxCoreStorage(p, profile))
			or math.max(1, math.floor(tonumber(profile.MaxFruitStorage) or 1))
		local curCnt = tonumber(profile.StoredFruits[grantFid]) or 0
		if curCnt >= maxStore then
			G.Notify(
				p,
				string.format(
					"Kho Lõi Aether [%s] đã đầy (%d/%d) — Hãy dọn kho trước khi nhập Giftcode [%s]! / Core Storage full (%d/%d)!",
					grantFid,
					curCnt,
					maxStore,
					cleaned,
					curCnt,
					maxStore
				)
			)
			return false
		end
	end

	profile.RedeemedCodes[cleaned] = true
	if spec.Gold then
		profile.Gold = (profile.Gold or 0) + spec.Gold
	end
	if spec.CoreShards then
		profile.CoreShards = (profile.CoreShards or 0) + spec.CoreShards
	end
	if spec.DoubleExpSeconds then
		profile.DoubleExpRemainingSec = math.max(0, math.floor(tonumber(profile.DoubleExpRemainingSec) or 0)) + spec.DoubleExpSeconds
		profile.DoubleExpUntil = 0
	end
	if grantFid then
		profile.StoredFruits[grantFid] = (tonumber(profile.StoredFruits[grantFid]) or 0) + 1
	end
	if spec.FreeFruitVouchers then
		profile.FreeFruitVouchers = (profile.FreeFruitVouchers or 0) + spec.FreeFruitVouchers
	end
	if spec.FreeStatRefund then
		Expansion.RefundAllStats(p, true, true)
	end
	if spec.StatRefundTokens then
		profile.StatRefundTokens = (profile.StatRefundTokens or 0) + spec.StatRefundTokens
	end

	G.Notify(p, "GIFTCODE [" .. cleaned .. "] THÀNH CÔNG: " .. spec.Desc .. "!")
	G.Sync(p)
	task.spawn(D.Save, p, false)
	return true
end

function Expansion.AscendWeaponStar(p, rawItemId)
	local profile = D.Get(p)
	local rt = G.Runtime[p]
	if not profile or not rt then
		return false
	end
	ensureExpansionProfile(profile)
	ensureRuntimeFields(p, rt, profile)

	local itemId = tostring(rawItemId or profile.Weapon or "")
	local itemCfg = C.Items and C.Items[itemId]
	if itemId == "" or not itemCfg then
		G.Notify(p, "Hãy chọn vũ khí hợp lệ cần Thăng Hoa Sao (Star Ascension)!")
		return false
	end
	if (tonumber(profile.Inventory and profile.Inventory[itemId]) or 0) <= 0 and profile.Weapon ~= itemId and profile.EquippedGun ~= itemId then
		G.Notify(p, "Hãy rèn sở hữu [" .. (itemCfg.Name or itemId) .. "] trước khi Thăng Hoa Sao!")
		return false
	end

	-- Deduplicate dual-remote firing from Forge.lua
	local now = os.clock()
	if rt.RecentStarDedup[itemId] and (now - rt.RecentStarDedup[itemId]) < 0.45 then
		return true
	end
	rt.RecentStarDedup[itemId] = now

	local dispName = itemCfg.Name or itemId
	local curStar = math.clamp(math.floor(tonumber(profile.WeaponStars[itemId]) or 1), 1, 5)
	if curStar >= 5 then
		G.Notify(p, "Thần khí [" .. dispName .. "] đã đạt tối đa 5 Sao!")
		return false
	end

	local nextStar = curStar + 1
	local tier = CombatData.StarAscension[nextStar]
	if not tier then
		return false
	end

	if (profile.Gold or 0) < tier.Gold or (profile.CoreShards or 0) < tier.Shards then
		G.Notify(p, string.format("Cần %d Gold & %d Core Shards để Thăng Hoa %d Sao!", tier.Gold, tier.Shards, nextStar))
		return false
	end

	profile.Gold -= tier.Gold
	profile.CoreShards -= tier.Shards

	local curPity = math.clamp(tonumber(profile.StarPity[itemId]) or 0, 0, 100)
	local guaranteed = (curPity >= 100) or (tier.Rate >= 1.0)
	local rollOk = guaranteed or (math.random() <= tier.Rate)

	if rollOk then
		profile.WeaponStars[itemId] = nextStar
		profile.StarPity[itemId] = 0
		evaluateAutoTitles(p, profile)
		G.Notify(p, string.format("THĂNG HOA %d SAO THÀNH CÔNG [%s]! (+%d%% Crit, +%d%% Skill DMG)", nextStar, dispName, tier.CritRateBonus, math.floor(tier.SkillDmgPct * 100)))
	else
		local newPity = math.min(100, curPity + (tier.PityGain or 40))
		profile.StarPity[itemId] = newPity
		G.Notify(p, string.format("Thăng hoa %d Sao chưa thành công - Chúc Phúc Pity tăng lên %d%%/100%%!", nextStar, newPity))
	end

	G.Sync(p)
	task.spawn(D.Save, p, false)
	return true
end

function Expansion.ApplyStatPreset(p, slotIdx, statsTable)
	local profile = D.Get(p)
	local rt = G.Runtime[p]
	if not profile or not rt then
		return false
	end
	ensureExpansionProfile(profile)
	local slot = math.clamp(math.floor(tonumber(slotIdx) or 1), 1, 3)
	local maxSt = (C and C.MaxStat) or 2550
	local maxAdd = maxSt - 1

	local target = type(statsTable) == "table" and statsTable or profile.StatPresets[tostring(slot)] or profile.StatPresets[slot]
	if type(target) ~= "table" then
		-- Focused 2-3 branch builds (Melee-Sword / Fruit-Defense / Marksman-Defense) with max-branch overflow
		local totalPool = (tonumber(profile.StatPoints) or 0)
		for _, v in pairs(profile.StatAlloc or {}) do
			totalPool += math.max(0, (tonumber(v) or 1) - 1)
		end
		local function buildFocusedPreset(b1, w1, b2, w2, b3)
			local out = { Melee = 0, Defense = 0, Sword = 0, Gun = 0, Fruit = 0 }
			local p1 = math.min(maxAdd, math.floor(totalPool * w1))
			local rem1 = totalPool - p1
			local p2 = math.min(maxAdd, math.floor(rem1 * (w2 / math.max(0.01, 1 - w1))))
			local p3 = math.min(maxAdd, rem1 - p2)
			local extra = totalPool - (p1 + p2 + p3)
			if extra > 0 and p2 < maxAdd then
				local add2 = math.min(maxAdd - p2, extra)
				p2 += add2
				extra -= add2
			end
			if extra > 0 and p3 < maxAdd then
				p3 += math.min(maxAdd - p3, extra)
			end
			out[b1] = p1
			out[b2] = p2
			out[b3] = p3
			return out
		end
		if slot == 1 then
			-- Preset #1: Melee-Sword Hybrid (Sword 50%, Defense 30%, Melee 20%)
			target = buildFocusedPreset("Sword", 0.50, "Defense", 0.30, "Melee")
		elseif slot == 2 then
			-- Preset #2: Fruit-Defense Mage (Fruit 50%, Defense 35%, Melee 15%)
			target = buildFocusedPreset("Fruit", 0.50, "Defense", 0.35, "Melee")
		else
			-- Preset #3: Marksman-Defense Hybrid (Gun 45%, Defense 35%, Melee 20%)
			target = buildFocusedPreset("Gun", 0.45, "Defense", 0.35, "Melee")
		end
	end

	local _, okRef = Expansion.RefundAllStats(p, true, false)
	if not okRef then
		return false
	end
	for _, key in ipairs({ "Melee", "Defense", "Sword", "Gun", "Fruit" }) do
		local rawWant = tonumber(target[key]) or 0
		local addPts = rawWant
		if target._isAbsolute then
			addPts = math.max(0, rawWant - 1)
		end
		addPts = math.clamp(math.floor(addPts), 0, math.min(maxAdd, profile.StatPoints or 0))
		if addPts > 0 then
			profile.StatAlloc[key] = 1 + addPts
			profile.StatPoints -= addPts
		end
	end

	-- Record timestamp so Skills.lua's immediate follow-up RefundStats+AddStat loop doesn't clobber preset
	rt.PresetAppliedAt = os.clock()
	rt.PresetTarget = table.clone(profile.StatAlloc)

	G.Notify(p, string.format("Đã áp dụng Cấu Hình Chỉ Số Preset #%d (Còn %d Stat Points)!", slot, profile.StatPoints or 0))
	G.Sync(p)
	return true
end

function Expansion.SaveStatPreset(p, slotIdx, statsTable)
	local profile = D.Get(p)
	if not profile then
		return false
	end
	ensureExpansionProfile(profile)
	local slot = math.clamp(math.floor(tonumber(slotIdx) or 1), 1, 3)
	local saved = { _isAbsolute = true }
	for _, key in ipairs({ "Melee", "Defense", "Sword", "Gun", "Fruit" }) do
		if type(statsTable) == "table" and statsTable[key] ~= nil then
			saved[key] = math.max(1, math.floor(tonumber(statsTable[key]) or 1))
		else
			saved[key] = math.max(1, math.floor(tonumber(profile.StatAlloc[key]) or 1))
		end
	end
	profile.StatPresets[tostring(slot)] = saved
	G.Notify(p, "Đã lưu Cấu Hình Chỉ Số Preset #" .. tostring(slot) .. "!")
	G.Sync(p)
	return true
end

function Expansion.TeleportToIsland(p, rawIslandId)
	local profile = D.Get(p)
	local rt = G.Runtime[p]
	local hrp = getCharRoot(p)
	if not profile or not rt or not hrp then
		return false
	end
	if isPlayerPvPCombatTagged(p, rt) then
		G.Notify(p, "Đang trong Giao Tranh PvP — không thể Dịch Chuyển Nhanh lúc này! / Cannot Fast Travel while PvP combat-tagged!")
		return false
	end
	if (G.Boss and G.Boss.Party and G.Boss.Party[p])
		or PlayerTradeMap[p] ~= nil
		or TrialSessions[p] ~= nil
		or p:GetAttribute("RaidActive") == true
		or p:GetAttribute("ColosseumActive") == true
		or p:GetAttribute("InColosseum") == true
		or p:GetAttribute("InColosseumDuel") == true
		or (tonumber(p:GetAttribute("SpireFloor")) or 0) > 0 then
		G.Notify(p, "Không thể dịch chuyển khi đang trong Đấu Trường, Tháp Vô Tận, Giao Dịch, Raid hoặc Thử Thách!")
		return false
	end

	local allowed, resolvedId = Helpers.CheckIslandTeleportGate(p, profile, C, tostring(rawIslandId or "SkyHub"), G)
	if not allowed or not resolvedId then
		return false
	end

	local isl = (C.FastTravel and C.FastTravel[resolvedId]) or (not tonumber(resolvedId) and C.Islands and C.Islands[resolvedId])
	if not isl and C and C.Islands then
		for _, v in ipairs(C.Islands) do
			if type(v) == "table" and type(v.Id) == "string" and string.lower(v.Id) == string.lower(resolvedId) then
				isl = v
				break
			end
		end
	end
	if not isl and resolvedId ~= "SkyHub" and resolvedId ~= "GoldenSky" then
		return false
	end

	local canonId = (isl and type(isl.Id) == "string" and isl.Id ~= "" and isl.Id) or resolvedId
	local pos = (isl and (isl.Pos or isl.Spawn)) or C.Spawn
	local realm = (isl and isl.Realm) or "GoldenSky"
	profile.UnlockedWorlds = profile.UnlockedWorlds or {}
	if type(realm) == "string" and realm ~= "" then
		profile.UnlockedWorlds[realm] = true
	end
	if type(canonId) == "string" and canonId ~= "" and not tonumber(canonId) then
		profile.UnlockedWorlds[canonId] = true
	end
	profile.DiscoveredIslands = type(profile.DiscoveredIslands) == "table" and profile.DiscoveredIslands or {}
	profile.DiscoveredIslands[canonId] = true

	rt.JumpPadUntil = os.clock() + 3.0
	p:SetAttribute("CurrentRealm", realm)
	G.Teleport(p, pos + Vector3.new(0, 3, 0))
	G.Notify(p, "Dịch chuyển nhanh -> " .. ((isl and isl.Name) or canonId) .. "!")
	G.Sync(p)
	return true
end

function Expansion.EquipTitle(p, rawTitleId)
	local profile = D.Get(p)
	if not profile then
		return false
	end
	ensureExpansionProfile(profile)
	evaluateAutoTitles(p, profile)
	local tid = tostring(rawTitleId or "sky_rookie")
	local spec = CombatData.Titles[tid]
	if not spec then
		for k, v in pairs(CombatData.Titles) do
			if v.Name == tid or string.lower(k) == string.lower(tid) then
				tid = k
				spec = v
				break
			end
		end
	end
	if not spec then
		return false
	end
	if not profile.UnlockedTitles[tid] then
		G.Notify(p, "Chưa mở khóa Danh Hiệu [" .. spec.Name .. "]: " .. (spec.Desc or ""))
		return false
	end
	profile.Title = tid
	p:SetAttribute("Title", spec.Name)
	updateOverheadTitleGui(p, profile)
	G.Notify(p, "Đã trang bị Danh Hiệu Phát Sáng: [" .. spec.Name .. "]!")
	G.Sync(p)
	return true
end

local HAKI_COLOR_ALIASES = {
	gold = "solar_gold",
	solar_gold = "solar_gold",
	crimson = "crimson_conqueror",
	rose = "crimson_conqueror",
	crimson_conqueror = "crimson_conqueror",
	cyan = "glacial_cyan",
	glacial_cyan = "glacial_cyan",
	violet = "abyssal_violet",
	abyssal_violet = "abyssal_violet",
	emerald = "verdant_emerald",
	verdant_emerald = "verdant_emerald",
	rainbow = "prismatic_aether",
	prismatic_aether = "prismatic_aether",
}

function Expansion.EquipHakiColor(p, rawColorId)
	local profile = D.Get(p)
	if not profile then
		return false
	end
	ensureExpansionProfile(profile)
	local rawStr = tostring(rawColorId or "crimson_conqueror")
	local cid = HAKI_COLOR_ALIASES[string.lower(rawStr)] or rawStr
	local spec = CombatData.HakiColors[cid]
	if not spec then
		return false
	end
	if not profile.UnlockedHakiColors[cid] then
		local cost = spec.CostShards or 150
		if (profile.CoreShards or 0) < cost then
			G.Notify(p, string.format("Cần %d Core Shards để mở khóa Sắc Ý Chí [%s]!", cost, spec.Name))
			return false
		end
		profile.CoreShards -= cost
		profile.UnlockedHakiColors[cid] = true
	end
	profile.HakiColorId = cid
	syncHakiAttributes(p, profile)
	G.Notify(p, "Đã trang bị Sắc Giáp Ý Chí: [" .. spec.Name .. "]!")
	G.Sync(p)
	return true
end

-- ============================================================================
-- UNIFIED UIREQUEST / FRUITACTION ROUTERS
-- ============================================================================
function Expansion.HandleFruitAction(p, actOrPayload, arg2)
	if not consumeToken(p, 1) then
		return
	end
	local act = actOrPayload
	local data = arg2
	if type(actOrPayload) == "table" then
		act = actOrPayload.action or actOrPayload.Action or actOrPayload.cmd
		data = actOrPayload
	end
	act = tostring(act or "")
	local fid = type(data) == "string" and data or (type(data) == "table" and (data.fruitId or data.id)) or ""

	if act == "GetMirageStock" then
		local stock = refreshMirageStock()
		if R and R.FruitAction then
			R.FruitAction:FireClient(p, "MirageStock", stock)
		end
	elseif act == "BuyMirageFruit" then
		local equipNow = type(data) == "table" and data.equipNow == true
		Expansion.BuyMirageFruit(p, fid, equipNow)
	elseif act == "DropHeldFruit" or act == "DropFruit" then
		Expansion.DropHeldFruit(p, fid ~= "" and fid or nil)
	elseif act == "ClaimWildFruit" then
		WildCoreService.TryClaimWildCore(p, fid, ensureExpansionProfile, function(plr)
			return PlayerTradeMap[plr] ~= nil
		end)
	elseif act == "AwakenFruit" then
		local profile = D.Get(p)
		if profile then
			ensureExpansionProfile(profile)
			local cid = CombatData.ResolveFruitId(fid ~= "" and fid or profile.EquippedFruit)
			local cat = CombatData.FruitCatalog[cid]
			if cat then
				if not profile.AwakenedFruits[cid] then
					if not Helpers.CanAwakenFruit(p, profile, cid, G) then
						return
					end
					profile.CoreShards = (tonumber(profile.CoreShards) or 0) - 1000
				end
				profile.AwakenedFruits[cid] = true
				unlockTitle(p, profile, "awakened_ascendant", false)
				G.Notify(p, "AWAKENED V2 MỞ KHÓA: [" .. cat.Name .. "] (-1,000 Core Shards • +28%..42% DMG & Hiệu Ứng V2)!")
				G.Sync(p)
			end
		end
	elseif act == "PortalWarp" then
		executePortalMoveC(p, type(data) == "table" and data or { targetIslandId = fid })
	elseif act == "SummonSeaBeast" then
		Expansion.SummonAlliedSeaBeast(p)
	elseif act == "RollFruit" or act == "RollFruitGold" or act == "RollFruitShards" then
		local curMode = (act == "RollFruitShards" and "Shards") or (type(data) == "table" and data.currency) or "Gold"
		G.Equipment(p, { action = "RollFruit", currency = curMode })
	elseif act == "EatFruit" or act == "HoldFruit" or act == "StoreFruit" then
		G.Equipment(p, { action = act, fruitId = CombatData.ResolveFruitId(fid) })
	end
end

function Expansion.HandleUIRequest(p, cmdOrPayload, arg2)
	if not consumeToken(p, 1) then
		return false
	end
	local cmd = cmdOrPayload
	local payload = arg2
	if type(cmdOrPayload) == "table" then
		cmd = cmdOrPayload.command or cmdOrPayload.action or cmdOrPayload.cmd
		payload = cmdOrPayload
	end
	cmd = tostring(cmd or "")
	payload = type(payload) == "table" and payload or { value = arg2 }

	if cmd == "ConfirmNPCAction" or cmd:sub(1, 17) == "ConfirmNPCAction:" then
		return Helpers.HandleConfirmNPCAction(p, cmd == "ConfirmNPCAction" and nil or cmd, payload, G, D, C, Expansion)
	elseif cmd == "EvolveRace" then
		local prof = D.Get(p)
		if prof then
			return Helpers.EvolveRace(p, prof, G, C)
		end
		return false
	elseif cmd == "StartTempleV4Trial" or cmd == "StartTempleRaceV4Trial" then
		return startTempleRaceV4Trial(p)
	elseif cmd == "SelectClass" then
		G.ChooseAppearance(p, { ClassId = payload.classId or payload.ClassId or payload.id or payload.value })
		return true
	elseif cmd == "RollFruitGold" or cmd == "RollFruitShards" then
		G.Equipment(p, { action = "RollFruit", currency = (cmd == "RollFruitShards" and "Shards") or payload.currency or "Gold" })
		return true
	elseif cmd == "RedeemCode" then
		return Expansion.RedeemCode(p, payload.code or payload.Code or payload.value)
	elseif cmd == "AscendStar" or cmd == "UpgradeStar" or cmd == "UpgradeWeaponStar" then
		return Expansion.AscendWeaponStar(p, payload.itemId or payload.weaponId or payload.id)
	elseif cmd == "ApplyStatPreset" then
		return Expansion.ApplyStatPreset(p, payload.slot or payload.preset or 1, payload.stats)
	elseif cmd == "SaveStatPreset" then
		return Expansion.SaveStatPreset(p, payload.slot or payload.preset or 1, payload.stats)
	elseif cmd == "RefundStats" or cmd == "ResetStats" then
		local rt = G.Runtime[p]
		if rt and rt.PresetAppliedAt and (os.clock() - rt.PresetAppliedAt) < 0.12 then
			return true
		end
		local _, okRef = Expansion.RefundAllStats(p, false, false)
		if okRef then
			G.Sync(p)
		end
		return okRef == true
	elseif cmd == "ClaimWildFruit" then
		return WildCoreService.TryClaimWildCore(p, payload.fruitId or payload.id or payload.value or "", ensureExpansionProfile, function(plr)
			return PlayerTradeMap[plr] ~= nil
		end)
	elseif cmd == "TeleportIsland" or cmd == "FastTravel" then
		return Expansion.TeleportToIsland(p, payload.islandId or payload.nodeId or payload.realmId or payload.id or payload.value)
	elseif cmd == "BuyMirageFruit" then
		return Expansion.BuyMirageFruit(p, payload.fruitId or payload.id or payload.value, payload.equipNow == true)
	elseif cmd == "GetMirageStock" then
		Expansion.HandleFruitAction(p, "GetMirageStock")
		return true
	elseif cmd == "SelectFightingStyle" or cmd == "SwitchFightingStyle" or cmd == "LearnFightingStyle" then
		return Expansion.SelectOrLearnStyle(p, payload.styleId or payload.id or payload.value)
	elseif cmd == "EquipTitle" then
		return Expansion.EquipTitle(p, payload.titleId or payload.id or payload.value)
	elseif cmd == "EquipHakiColor" or cmd == "SetHakiColor" then
		return Expansion.EquipHakiColor(p, payload.colorId or payload.id or payload.color or payload.value)
	elseif cmd == "RerollRace" then
		return Expansion.RerollRace(p)
	elseif cmd == "SummonSeaBeast" then
		return Expansion.SummonAlliedSeaBeast(p)
	elseif cmd == "DropHeldFruit" or cmd == "DropFruit" then
		return Expansion.DropHeldFruit(p, payload.fruitId or payload.id)
	elseif cmd == "AwakenFruit" then
		Expansion.HandleFruitAction(p, "AwakenFruit", payload)
		return true
	elseif cmd == "RollFruit" or cmd == "EatFruit" or cmd == "HoldFruit" or cmd == "StoreFruit" then
		G.Equipment(p, { action = cmd, currency = payload.currency, fruitId = CombatData.ResolveFruitId(payload.fruitId or payload.id or "") })
		return true
	end
	return false
end

Expansion.StartTempleRaceV4Trial = startTempleRaceV4Trial
Expansion.AddMasteryXP = addMasteryXP

function Expansion.DamagePlayersInPvPArea(attacker, centerPos, reach, rawDmg, skillName)
	if not attacker or not G or not G.SocialEconomy or type(G.SocialEconomy.ApplyPvPHitCheck) ~= "function" then
		return
	end
	local hrp = getCharRoot(attacker)
	local dir = (hrp and hrp.CFrame.LookVector) or Vector3.new(0, 0, -1)
	pcall(G.SocialEconomy.ApplyPvPHitCheck, attacker, centerPos, dir, reach, rawDmg, skillName)
end

-- ============================================================================
-- MAIN HOOK INITIALIZATION: Expansion.Init(G, D, W, C)
-- ============================================================================
function Expansion.Init(gameService, dataService, worldService, configModule)
	if Expansion._initialized then
		return
	end
	Expansion._initialized = true

	G = gameService
	D = dataService or require(script.Parent:WaitForChild("PlayerDataService"))
	W = worldService or require(script.Parent:WaitForChild("WorldService"))
	C = configModule or require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
	R = ReplicatedStorage:WaitForChild("Remotes")

	G.CombatData = CombatData
	G.CombatExpansion = Expansion
	G.SkillMechanics = SkillMechanics
	SkillMechanics.Init({
		Config = C,
		Data = D,
		Game = G,
		World = W,
		Remotes = R,
		CombatData = CombatData,
		EnsureProfile = ensureExpansionProfile,
		EnsureRuntime = ensureRuntimeFields,
		CheckMastery = checkMoveMasteryUnlock,
		GetMasteryLevel = getMasteryLevel,
		AddMasteryXP = addMasteryXP,
		ApplyCryoFreeze = applyCryoFreeze,
		ApplyBurnOrDoT = applyBurnOrDoT,
		PullEnemyToward = pullEnemyToward,
		IsBossEnemy = isBossEnemy,
		GroundYAt = groundYAt,
		ClampAimRay = clampAimRay,
		EnsureWorldFolder = ensureWorldFolder,
		ExecutePortalMoveC = executePortalMoveC,
		ExecuteDragonFuryMoveV = executeDragonFuryMoveV,
	})
	local prevHandleUI = G.HandleUIRequest
	G.HandleUIRequest = function(p, cmd, payload)
		if Expansion.HandleUIRequest(p, cmd, payload) then
			return true
		end
		return (type(prevHandleUI) == "function" and prevHandleUI(p, cmd, payload)) or false
	end
	G.HandleFruitAction = Expansion.HandleFruitAction
	G.HandleTradeAction = Expansion.HandleTradeAction
	G.RedeemCode = Expansion.RedeemCode
	G.AscendWeaponStar = Expansion.AscendWeaponStar
	G.ApplyStatPreset = Expansion.ApplyStatPreset
	G.BuyMirageFruit = Expansion.BuyMirageFruit
	G.SummonAlliedSeaBeast = Expansion.SummonAlliedSeaBeast

	-- Enrich StateUpdate payload right before GameService fires StateUpdate
	G.OnBeforeSync = function(p, profile, rt, s, statePayload)
		ensureExpansionProfile(profile)
		ensureRuntimeFields(p, rt, profile)
		evaluateAutoTitles(p, profile)
		syncLeaderstats(p, profile)
		syncHakiAttributes(p, profile)
		updateOverheadTitleGui(p, profile)

		local styleId = CombatData.ResolveStyleId(profile.FightingStyle)
		local fid = CombatData.ResolveFruitId(profile.EquippedFruit)
		local fruitMastery = (fid ~= "" and getMasteryLevel(profile, fid)) or 1
		local fruitAwk = (fid ~= "" and profile.AwakenedFruits[fid] == true) or false
		local wepStar = (profile.Weapon and tonumber(profile.WeaponStars[profile.Weapon])) or 0
		local expRem = math.max(
			math.floor(tonumber(profile.DoubleExpRemainingSec) or 0),
			math.max(0, (tonumber(profile.DoubleExpUntil) or 0) - os.time())
		)

		p:SetAttribute("FightingStyle", styleId)
		p:SetAttribute("EquippedFruit", fid)
		p:SetAttribute("FruitMastery", fruitMastery)
		p:SetAttribute("FruitAwakened", fruitAwk)
		p:SetAttribute("Bounty", profile.Bounty or 0)
		p:SetAttribute("Title", (CombatData.Titles[profile.Title] or CombatData.Titles.sky_rookie).Name)
		p:SetAttribute("Race", profile.Race or "Skyborn")
		p:SetAttribute("RaceV4Unlocked", profile.RaceV4Unlocked == true)
		p:SetAttribute("BlueResonanceGearFound", profile.BlueResonanceGearFound == true)
		p:SetAttribute("EquippedWeaponStar", wepStar)
		p:SetAttribute("DoubleExpSeconds", expRem)
		if p.Character then
			p.Character:SetAttribute("FightingStyle", styleId)
			p.Character:SetAttribute("EquippedFruit", fid)
			p.Character:SetAttribute("FruitAwakened", fruitAwk)
			p.Character:SetAttribute("Race", profile.Race or "Skyborn")
		end

		if type(statePayload) == "table" then
			statePayload.FightingStyle = styleId
			statePayload.FruitMastery = fruitMastery
			statePayload.FruitAwakened = fruitAwk
			statePayload.WeaponStars = profile.WeaponStars
			statePayload.StarPity = profile.StarPity
			statePayload.StatPresets = profile.StatPresets
			statePayload.StatRefundTokens = profile.StatRefundTokens or 0
			statePayload.RedeemedCodes = profile.RedeemedCodes
			statePayload.HakiStage = profile.HakiStage
			statePayload.HakiEXP = profile.HakiEXP
			statePayload.HakiColorId = profile.HakiColorId
			statePayload.UnlockedHakiColors = profile.UnlockedHakiColors
			statePayload.KenV2Active = p:GetAttribute("KenV2Active") == true
			statePayload.Bounty = profile.Bounty
			statePayload.Honor = profile.Honor
			statePayload.TitleId = profile.Title
			statePayload.Title = (CombatData.Titles[profile.Title] or CombatData.Titles.sky_rookie).Name
			statePayload.UnlockedTitles = profile.UnlockedTitles
			statePayload.FuryMeter = math.floor((rt.FuryMeter or 0) + 0.5)
			statePayload.DragonFormTier = rt.DragonFormTier or 0
			statePayload.RaceV4Unlocked = profile.RaceV4Unlocked == true
			statePayload.BlueResonanceGearFound = profile.BlueResonanceGearFound == true
			statePayload.CoreGears = profile.CoreGears or 0
			statePayload.DoubleExpSeconds = expRem
			statePayload.DoubleExpRemainingSec = expRem
			statePayload.MirageStock = CurrentMirageStock or refreshMirageStock()
		end
	end

	-- 1. Wrap G.Rate with Token-Bucket Sanity Protection (#127)
	local origRate = G.Rate
	G.Rate = function(p, channel, interval)
		if not consumeToken(p, (channel == "Equipment_AddStat") and 0.15 or 1) then
			return false
		end
		if channel == "Equipment_AddStat" then
			return true
		end
		return origRate(p, channel, interval)
	end

	-- 2. Wrap G.Stats with Haki Stage 0..5 (#53), Bounty Buff (#56), Star Ascension (#104), Dragon Fury (#48), Race V4 (#52)
	local origStats = G.Stats
	G.Stats = function(p, slotOverride)
		local s = origStats(p, slotOverride)
		local profile = D.Get(p)
		local rt = G.Runtime[p]
		if not s or not profile then
			return s
		end
		ensureExpansionProfile(profile)
		local effSlot = math.clamp(math.floor(tonumber(slotOverride) or tonumber(profile.ActiveSlot) or 2), 1, 4)

		-- Adjust Busoshoku Haki to authoritative Stage 0..5 (up to +22% ATK, +18% DEF at Stage 5)
		if p.Character and p.Character:GetAttribute("HakiAura") then
			local stInfo = CombatData.HakiStages[profile.HakiStage or 0] or CombatData.HakiStages[0]
			local prevAuraMult = 1 + 0.14 + math.clamp(tonumber(profile.HakiStage) or tonumber(profile.Haki and profile.Haki.AuraStage) or 1, 1, 5) * 0.02
			s.ATK = math.floor((s.ATK / prevAuraMult) * (1 + stInfo.AtkBonus))
			s.DEF = math.floor((s.DEF / 1.15) * (1 + stInfo.DefBonus))
			s.Break = (s.Break or 100) + (stInfo.BreakBonus or 0)
		end

		-- Bounty Prestige Combat Buff (+1% ATK & +1% DEF per 1.5M up to +20% at 30M) (#56)
		local bountyPct = CombatData.GetBountyBuffPct(profile.Bounty)
		if bountyPct > 0 then
			s.ATK = math.floor(s.ATK * (1 + bountyPct))
			s.DEF = math.floor(s.DEF * (1 + bountyPct))
		end

		-- Weapon Star Ascension (1..5 Stars, slot-isolated to Sword Slot 3 or Gun Slot 4) (#104)
		local activeWep = (effSlot == 4 and profile.EquippedGun) or (effSlot == 3 and profile.Weapon) or nil
		local starLv = activeWep and tonumber(profile.WeaponStars[activeWep]) or 0
		if starLv and starLv >= 1 and CombatData.StarAscension[starLv] then
			local tier = CombatData.StarAscension[starLv]
			s.ATK = math.floor(s.ATK * (1 + tier.AtkPct))
			if effSlot == 3 and s.SwordATK then
				s.SwordATK = math.floor(s.SwordATK * (1 + tier.AtkPct))
			elseif effSlot == 4 and s.GunATK then
				s.GunATK = math.floor(s.GunATK * (1 + tier.AtkPct))
			end
			s.CritRate = (s.CritRate or 5) + tier.CritRateBonus
			s.StarSkillDmgPct = tier.SkillDmgPct
		else
			s.StarSkillDmgPct = 0
		end

		-- 2-Tier Dragon Fury Transformation (#48)
		if rt and (rt.DragonFormTier or 0) > 0 then
			if rt.DragonFormTier == 2 then
				s.ATK = math.floor(s.ATK * 1.32)
				s.DEF = math.floor(s.DEF * 1.40)
			else
				s.ATK = math.floor(s.ATK * 1.18)
				s.DEF = math.floor(s.DEF * 1.25)
			end
		end

		-- Apply WalkSpeed modifiers (Race Tier V2/V3, Mink V4 +45%, Skyborn V4 +28%, Dragon Hybrid +22% / Sovereign +32%)
		local _, hum = getCharRoot(p)
		if hum then
			local baseSpd = (C.Classes and C.Classes[profile.ClassId] and C.Classes[profile.ClassId].Speed) or 18
			local spdMult = tonumber(s.RaceWalkSpeedMult) or 1.0
			if profile.RaceV4Active then
				if profile.Race == "Mink" then
					spdMult += CombatData.RaceV4Passives.Mink.WalkSpeedBonus -- +45%
				elseif profile.Race == "Skyborn" then
					spdMult += CombatData.RaceV4Passives.Skyborn.GlideSpeedBonus
				end
			end
			if rt and (rt.DragonFormTier or 0) == 1 then
				spdMult += 0.22
			elseif rt and (rt.DragonFormTier or 0) == 2 then
				spdMult += 0.32
			end
			if rt and rt.InWaterZone and profile.Race == "Leviathan" then
				spdMult += 0.35
			end
			hum.WalkSpeed = math.clamp(baseSpd * spdMult, 16, 48)
		end

		return s
	end

	-- 3. Wrap G.Hit for Boss 1.5x Break Amplification (#16), Buso Haki EXP (#53), Fury Gain (#48), & Race V4 On-Hit (#52)
	local origHit = G.Hit
	local inChainLightning = false
	G.Hit = function(p, e, damage, breakPower, action)
		if not e or not e.Alive then
			return
		end
		local now = os.clock()
		local profile = D.Get(p)
		local rt = G.Runtime[p]
		local mult = 1.0

		-- #16: 1.5x amplified damage while Boss is in 4.5s BOSS BREAK kneel state!
		if now < (e.BossBrokenUntil or 0) then
			mult *= 1.5
		end
		if now < (e.ArmorShredUntil or 0) then
			mult *= 1.08
		end
		-- #104: Apply ★1..★5 Weapon Star Skill Damage Bonus (+12%..+45%) on non-M1 skill hits!
		if profile and type(profile.WeaponStars) == "table" then
			local actStr = tostring(action or "")
			if actStr ~= "" and actStr ~= "Attack" and actStr ~= "Light" and actStr ~= "M1"
				and actStr ~= "DracoV4ThornReflect" and actStr ~= "CyborgV4ChainOrb" and actStr ~= "ChainVolt" then
				local activeWep = (profile.ActiveSlot == 4 and profile.EquippedGun) or (profile.ActiveSlot == 3 and profile.Weapon) or nil
				local starLv = activeWep and tonumber(profile.WeaponStars[activeWep]) or 0
				local starTier = starLv and CombatData.StarAscension[starLv]
				if starTier and (starTier.SkillDmgPct or 0) > 0 then
					mult *= (1 + starTier.SkillDmgPct)
				end
			end
		end

		local preHP = e.HP or 0
		local preBreak = e.Break or 0
		local preAwk = (profile and tonumber(profile.AwakeningMeter)) or (rt and tonumber(rt.AwakeningMeter)) or 0
		origHit(p, e, (tonumber(damage) or 1) * mult, 0, action)
		local dealt = math.max(0, preHP - (e.HP or 0))
		if profile and profile.RaceV4Active then
			profile.AwakeningMeter = preAwk
			if rt then
				rt.AwakeningMeter = preAwk
			end
		end

		-- Authoritative Boss Break Gauge (#16)
		local extraBreak = (tonumber(breakPower) or 0)
		if profile and profile.Haki and profile.Haki.Aura then
			local stInfo = CombatData.HakiStages[profile.HakiStage or 0]
			extraBreak += (stInfo and stInfo.BreakBonus or 3)
			addBusoHakiEXP(p, 3)
			Helpers.CheckAndAutoUnlockConqueror(p, profile, G, nil)
		end
		e.Break = preBreak
		updateBossBreakGauge(e, extraBreak)

		if rt and dealt > 0 then
			ensureRuntimeFields(p, rt, profile)
			rt.LastCombatAt = now
			if not G._DragonDualFormsHooked then
				rt.FuryMeter = math.min(100, (tonumber(rt.FuryMeter) or 100) + 4.0)
				rt.DragonFury = rt.FuryMeter
			end
			if profile then
				local syncedAwk = math.clamp(tonumber(profile.AwakeningMeter) or tonumber(rt.AwakeningMeter) or 0, 0, 100)
				profile.AwakeningMeter = syncedAwk
				rt.AwakeningMeter = syncedAwk
				p:SetAttribute("AwakeningMeter", math.floor(syncedAwk + 0.5))
			end
		end

		-- #52: Race V4 On-Hit Passives (Cyborg Chain Orbs, Ghoul Life-Leech, Mink Whirlwind, Leviathan Armor-Break Slow)
		if profile and profile.RaceV4Active and dealt > 0 then
			local race = profile.Race or "Skyborn"
			local _, hum = getCharRoot(p)
			if race == "Ghoul" and hum and hum.Health > 0 then
				local isSkill = tostring(action or "") ~= "Attack"
				local pct = isSkill and CombatData.RaceV4Passives.Ghoul.SkillLifeLeechPct or CombatData.RaceV4Passives.Ghoul.BasicLifeLeechPct
				hum.Health = math.min(hum.MaxHealth, hum.Health + math.max(1, math.floor(dealt * pct)))
			elseif race == "Cyborg" and not inChainLightning and e.Body then
				inChainLightning = true
				local chained = 0
				local chainDmg = math.max(1, math.floor(dealt * CombatData.RaceV4Passives.Cyborg.ChainDamageRatio))
				for _, otherE in ipairs(G.Enemies or {}) do
					if otherE ~= e and otherE.Alive and otherE.Body and (otherE.Body.Position - e.Body.Position).Magnitude <= CombatData.RaceV4Passives.Cyborg.ChainRadius then
						chained += 1
						origHit(p, otherE, chainDmg, 4, "CyborgV4ChainOrb")
						if chained >= CombatData.RaceV4Passives.Cyborg.ChainMaxTargets then
							break
						end
					end
				end
				if rt and chained > 0 then
					local maxE = tonumber(rt.MaxEnergy) or 100
					rt.Energy = math.min(maxE, (tonumber(rt.Energy) or 0) + CombatData.RaceV4Passives.Cyborg.EnergyRefundPerChain)
				end
				inChainLightning = false
			elseif race == "Mink" and not isBossEnemy(e) then
				e.StunnedUntil = math.max(e.StunnedUntil or 0, now + CombatData.RaceV4Passives.Mink.MiniStunDuration)
			elseif race == "Leviathan" then
				e.ArmorShredUntil = now + CombatData.RaceV4Passives.Leviathan.ArmorBreakDuration
				e.SlowedUntil = now + CombatData.RaceV4Passives.Leviathan.ArmorBreakDuration
			end
		end
	end

	-- 4. Wrap G.Kill for Bounty / Honor Progression (#56), Mastery Kill Bonus (#41), & Sea King Titles (#58)
	local origKill = G.Kill
	G.Kill = function(e)
		if e and e.Alive then
			local isBoss = isBossEnemy(e)
			local enemyLv = (e.Config and e.Config.Level) or 25
			for p, hit in pairs(e.Contributors or {}) do
				local prof = D.Get(p)
				if prof and (os.clock() - (hit.Time or 0)) < 45 then
					local activeId = getActiveDisciplineId(prof)
					addMasteryXP(p, activeId, isBoss and 140 or math.clamp(16 + math.floor(enemyLv * 0.06), 16, 85))

					local bountyGain = isBoss and math.clamp(180000 + enemyLv * 320, 200000, 950000)
						or math.clamp(3500 + enemyLv * 18, 3500, 47500)
					awardBounty(p, bountyGain, (e.Config and e.Config.Name) or e.Id)

					if e.Id == "SkySeaBeast" or e.Id == "AbyssalLeviathan" then
						unlockTitle(p, prof, "sea_king_slayer", false)
					end
				end
			end
		end
		return origKill(e)
	end

	-- 5. Wrap G.PlayerDamage for Logia Elemental Reflex (#45), Ken V2 EXP (#54), Leviathan Shield & Draco Reflect (#52)
	local origPlayerDamage = G.PlayerDamage
	G.PlayerDamage = function(p, amount, attackerEnemy)
		local hrp, hum = getCharRoot(p)
		local rt = G.Runtime[p]
		local profile = D.Get(p)
		if not hrp or not hum or not rt or not profile then
			return
		end
		ensureExpansionProfile(profile)
		ensureRuntimeFields(p, rt, profile)

		-- #54: Track Kenbunshoku dodge EXP toward V2 unlock (Logia immunity & +5 AwakeningMeter are authoritatively handled inside origPlayerDamage)
		local preDodges = profile.Haki and profile.Haki.InstinctDodges or 0
		local preAwk = tonumber(profile.AwakeningMeter) or tonumber(rt.AwakeningMeter) or 0

		-- #52: Draco V4 25% Primordial Thorn-Reflect
		if profile.RaceV4Active and profile.Race == "Draco" and attackerEnemy and attackerEnemy.Alive then
			local reflectDmg = math.max(5, math.floor((tonumber(amount) or 10) * CombatData.RaceV4Passives.Draco.ThornReflectPct))
			origHit(p, attackerEnemy, reflectDmg, 5, "DracoV4ThornReflect")
		end

		-- #52: Leviathan V4 Water Shield absorption & 80% water zone resistance
		local incoming = tonumber(amount) or 0
		if rt.InWaterZone and profile.Race == "Leviathan" then
			incoming = incoming * (1 - CombatData.RaceV4Passives.Leviathan.WaterResistPct)
		end
		if profile.RaceV4Active and profile.Race == "Leviathan" and (rt.LeviathanShieldHP or 0) > 0 then
			local absorbed = math.min(rt.LeviathanShieldHP, incoming)
			rt.LeviathanShieldHP -= absorbed
			incoming -= absorbed
			p:SetAttribute("LeviathanShieldHP", math.floor(rt.LeviathanShieldHP))
			if incoming <= 0.5 then
				return
			end
		end

		rt.LastCombatAt = os.clock()
		origPlayerDamage(p, incoming, attackerEnemy)
		if profile.RaceV4Active then
			profile.AwakeningMeter = preAwk
			rt.AwakeningMeter = preAwk
		end
		local syncedAwk = math.clamp(tonumber(profile.AwakeningMeter) or tonumber(rt.AwakeningMeter) or 0, 0, 100)
		profile.AwakeningMeter = syncedAwk
		rt.AwakeningMeter = syncedAwk
		p:SetAttribute("AwakeningMeter", math.floor(syncedAwk + 0.5))

		local postDodges = profile.Haki and profile.Haki.InstinctDodges or 0
		if postDodges < preDodges then
			profile.KenEXP = (profile.KenEXP or 0) + 10
			if not profile.KenV2Unlocked and profile.KenEXP >= CombatData.KenV2UnlockDodgesEXP then
				profile.KenV2Unlocked = true
				unlockTitle(p, profile, "all_seeing_oracle", false)
				syncHakiAttributes(p, profile)
				G.Notify(p, "THẤU Ý V2 THỨC TỈNH: Mở khóa Thiên Nhãn Thấu Thị Target Inspector!")
			end
		end
	end

	-- 6. Wrap G.TickEnemy to enforce Cryo Freeze (#38) & Boss Break 4.5s Kneel Pause (#16)
	local origTickEnemy = G.TickEnemy
	G.TickEnemy = function(e, dt)
		if not e or not e.Alive then
			return
		end
		local now = os.clock()
		if now < (e.FrozenUntil or 0) or now < (e.BossBrokenUntil or 0) then
			return
		end
		local effDt = (now < (e.SlowedUntil or 0)) and (dt * 0.65) or dt
		return origTickEnemy(e, effDt)
	end

	-- 7. Wrap G.Action & G.UseSlotMove for 5 Martial Styles, Fast 4-Hit Sword Combo, Greatsword Crescent Slash, Guns, V2 Fruits, Dragon Fury & Portal Warp
	local origAction = G.Action
	G.Action = function(p, action, payload)
		local profile = D.Get(p)
		if not profile then
			return
		end
		ensureExpansionProfile(profile)
		local slot = math.clamp(tonumber(profile.ActiveSlot) or 2, 1, 4)
		local act = tostring(action or "")

		if act == "Light" or act == "M1" then
			act = "Attack"
		end

		if (act == "Attack" or act == "Shoot") and slot == 1 then
			executeMartialStyleKata(p, payload)
			return
		elseif act == "Attack" and slot == 3 then
			executeSwordComboM1(p, payload)
			return
		elseif (act == "Attack" or act == "Heavy" or act == "Shoot") and slot == 4 then
			executeAimedGunShot(p, nil, payload)
			return
		elseif (act == "Heavy" or act == "ChargeHeavy" or act == "ChargedSlash") and slot == 3 and CombatData.IsChargedSlashWeapon(profile.Weapon) then
			if executeChargedCrescentSlash(p, payload) then
				return
			end
		end
		return origAction(p, act, payload)
	end

	local origUseSlotMove = G.UseSlotMove
	G.UseSlotMove = function(p, rawKey, payload)
		local profile = D.Get(p)
		local rt = G.Runtime[p]
		if not profile or not rt then
			return
		end
		ensureExpansionProfile(profile)
		local key = string.upper(tostring(rawKey or "Z"))
		local slot = math.clamp(tonumber(profile.ActiveSlot) or 2, 1, 4)

		-- Stage 1 Mechanical Skill Engine across all 4 Slots (8 Martial Styles, 12 V1/V2/Dragon Cores, 5 Melee Archetypes, 5 Gun Archetypes)
		if SkillMechanics.ExecuteSlotSkill(p, slot, key, payload) then
			return
		end

		-- Fallback when Slot 2 has no equipped Aether Core yet
		local discId = getActiveDisciplineId(profile, slot)
		if not checkMoveMasteryUnlock(p, profile, discId, key, slot) then
			return
		end
		local baseKey = (key == "Z" or key == "X" or key == "C" or key == "V" or key == "F") and key or "Z"
		local cdBefore = rt.Cooldowns["Slot_" .. baseKey]
		local res = origUseSlotMove(p, key, payload)
		local rtAfter = G.Runtime[p]
		if discId and rtAfter and rtAfter.Cooldowns and rtAfter.Cooldowns["Slot_" .. baseKey] ~= cdBefore then
			addMasteryXP(p, discId, 14)
		end
		return res
	end

	-- 8. Wrap G.Equipment & G.Interact so Wave 1/Wave 2 actions on EquipmentRequest & InteractRequest route cleanly
	local origEquipment = G.Equipment
	G.Equipment = function(p, payload)
		if type(payload) ~= "table" then
			return
		end
		local act = tostring(payload.action or "")
		-- Guard against Skills.lua's immediate post-ApplyStatPreset RefundStats/AddStat echo
		local rt = G.Runtime[p]
		if rt and rt.PresetAppliedAt and (os.clock() - rt.PresetAppliedAt) < 0.25 then
			if act == "RefundStats" or act == "AddStat" then
				return
			end
		end
		if act == "RedeemCode" or act == "UpgradeWeaponStar" or act == "AscendStar" or act == "UpgradeStar"
			or act == "ApplyStatPreset" or act == "SaveStatPreset" or act == "RefundStats" or act == "ResetStats"
			or act == "BuyMirageFruit"
			or act == "SelectFightingStyle" or act == "SwitchFightingStyle" or act == "LearnFightingStyle"
			or act == "EquipTitle" or act == "EquipHakiColor" or act == "RerollRace" or act == "EvolveRace"
			or act == "DropHeldFruit" or act == "DropFruit" or act == "SummonSeaBeast" then
			Expansion.HandleUIRequest(p, act, payload)
			return
		elseif act == "FastTravel" or act == "TeleportIsland" then
			Expansion.TeleportToIsland(p, payload.islandId or payload.nodeId or payload.id)
			return
		elseif act == "ActivateRaceV4" then
			local prof = D.Get(p)
			if prof then
				ensureExpansionProfile(prof)
				if prof.RaceV4Unlocked ~= true then
					G.Notify(p, "Bạn cần hoàn thành Khảo Thí Đền Thăng Hoa (Sea 3 • Lv. 1900+) để mở khóa Tộc V4!")
					return
				end
				if not prof.RaceV4Active then
					local curAwk = math.max(tonumber(rt and rt.AwakeningMeter) or 0, tonumber(prof.AwakeningMeter) or 0)
					if curAwk < 100 then
						G.Notify(p, string.format("Cần tích đầy 100%% Thanh Thức Tỉnh trong chiến đấu để kích hoạt Tộc V4 (Hiện tại: %d%%)!", math.floor(curAwk)))
						return
					end
					prof.AwakeningMeter = 100
					if rt then
						rt.AwakeningMeter = 100
						local _, hum = getCharRoot(p)
						if prof.Race == "Leviathan" and hum then
							rt.LeviathanShieldHP = math.floor(hum.MaxHealth * CombatData.RaceV4Passives.Leviathan.ShieldMaxHPPct)
						end
					end
				end
			end
		end
		return origEquipment(p, payload)
	end

	local origInteract = G.Interact
	G.Interact = function(p, idOrAction, extraTbl)
		if idOrAction == "FastTravel" or idOrAction == "TeleportIsland" then
			local targetId = type(extraTbl) == "table" and (extraTbl.islandId or extraTbl.nodeId or extraTbl.id) or extraTbl
			Expansion.TeleportToIsland(p, targetId)
			return
		elseif idOrAction == "DrVega" or idOrAction == "DrVega_Alchemist" then
			local prof = D.Get(p)
			if prof then
				Helpers.OpenDrVegaDialogue(p, prof, G)
			end
			return
		elseif idOrAction == "MirageDealer" then
			refreshMirageStock()
			G.SendDialogue(
				p,
				"Thương Nhân Hư Quang",
				"THƯƠNG NHÂN ĐẢO HƯ QUANG",
				"Kho Lõi Aether Hư Quang xoay vòng mỗi giờ! Hãy mở Cửa Hàng Hư Quang để xem giá và xác nhận mua bằng Gold.",
				"[1] MỞ KHO LÕI HƯ QUANG",
				"OpenScreen:NPCShop:MirageDealer"
			)
			return
		end
		return origInteract(p, idOrAction, extraTbl)
	end

	G.HandleAbilityExtra = function(p, payload)
		local id = tostring(payload.skillId or payload.action or "")
		if id == "FreeFlight" then
			local wantFly = (payload.active == true)
			local isFlying = false
			local rt = G.Runtime and G.Runtime[p]
			local profile = D.Get(p)
			if wantFly and profile and rt then
				local now = os.clock()
				local notStunned = now >= (tonumber(rt.StunnedUntil) or 0)
				local hasEnergy = (tonumber(rt.Energy) or 0) > 0
				local isSlot2 = (tonumber(profile.ActiveSlot) == 2)
				if isSlot2 and notStunned and hasEnergy then
					local fid = CombatData.ResolveFruitId(profile.EquippedFruit or "")
					local ch = p.Character
					local dTier = tonumber(rt.DragonFormTier) or tonumber(ch and ch:GetAttribute("DragonFormTier")) or tonumber(p:GetAttribute("DragonFormTier")) or 0
					local tf = tostring((ch and ch:GetAttribute("FruitTransform")) or p:GetAttribute("FruitTransform") or "")
					local canFruitFly = (TRUE_FLIGHT_FRUITS[fid] == true)
						or (fid == "AbyssalSovereignCore" and (dTier >= 2 or tf == "AbyssalSovereign"))
					if canFruitFly and checkMoveMasteryUnlock(p, profile, fid, "F", 2) then
						isFlying = true
					end
				end
			end
			if rt then
				rt.FreeFlightActive = isFlying
			end
			p:SetAttribute("SkybreakFlightActive", isFlying)
			if p.Character then
				p.Character:SetAttribute("SkybreakFlightActive", isFlying)
			end
			return true
		elseif id == "SummonSeaBeast" then
			Expansion.SummonAlliedSeaBeast(p)
			return true
		elseif id == "ChargeHeavy" or id == "ChargedSlash" then
			G.Action(p, "ChargeHeavy", payload)
			return true
		elseif id == "PortalWarp" then
			executePortalMoveC(p, payload)
			return true
		end
		return false
	end

	-- 9. Connect Wave 2 & Wave 1 Remotes (UIRequest is unified via UIRequestHandler.server.lua & G.HandleUIRequest)
	if R:FindFirstChild("FruitAction") then
		R.FruitAction.OnServerEvent:Connect(function(p, ...)
			if not RemoteGuard.Allow(p, "UI") then
				return
			end
			Expansion.HandleFruitAction(p, ...)
		end)
	end
	if R:FindFirstChild("TradeAction") then
		R.TradeAction.OnServerEvent:Connect(function(p, ...)
			if not RemoteGuard.Allow(p, "UI") then
				return
			end
			Expansion.HandleTradeAction(p, ...)
		end)
	end
	if R:FindFirstChild("StatAllocate") then
		R.StatAllocate.OnServerEvent:Connect(function(p, statOrTbl, amount)
			if not RemoteGuard.Allow(p, "StatAllocate") then
				return
			end
			if type(statOrTbl) == "table" then
				if statOrTbl.preset or statOrTbl.slot then
					Expansion.ApplyStatPreset(p, statOrTbl.preset or statOrTbl.slot, statOrTbl.stats)
				else
					G.Equipment(p, { action = "AddStat", stat = statOrTbl.stat, amount = statOrTbl.amount })
				end
			else
				G.Equipment(p, { action = "AddStat", stat = statOrTbl, amount = amount })
			end
		end)
	end
	if R:FindFirstChild("TeleportIsland") then
		R.TeleportIsland.OnServerEvent:Connect(function(p, islOrTbl)
			if not RemoteGuard.Allow(p, "UI") then
				return
			end
			local targetId = type(islOrTbl) == "table" and (islOrTbl.islandId or islOrTbl.nodeId or islOrTbl.id) or islOrTbl
			Expansion.TeleportToIsland(p, targetId)
		end)
	end
	if R:FindFirstChild("ForgeRequest") then
		R.ForgeRequest.OnServerEvent:Connect(function(p, actOrTbl, itemId)
			if not RemoteGuard.Allow(p, "UI") then
				return
			end
			if type(actOrTbl) == "table" then
				local a = tostring(actOrTbl.action or "ForgeCraft")
				if a == "AscendStar" or a == "UpgradeStar" or a == "UpgradeWeaponStar" then
					Expansion.AscendWeaponStar(p, actOrTbl.itemId)
				elseif a == "ForgeEnhance" or a == "Upgrade" then
					G.Equipment(p, { action = "ForgeEnhance", itemId = actOrTbl.itemId or actOrTbl.recipeId })
				else
					G.Equipment(p, { action = "ForgeCraft", itemId = actOrTbl.itemId or actOrTbl.recipeId })
				end
			elseif actOrTbl == "AscendStar" or actOrTbl == "UpgradeStar" or actOrTbl == "UpgradeWeaponStar" then
				Expansion.AscendWeaponStar(p, itemId)
			elseif actOrTbl == "ForgeEnhance" or actOrTbl == "Upgrade" then
				G.Equipment(p, { action = "ForgeEnhance", itemId = itemId })
			else
				G.Equipment(p, { action = "ForgeCraft", itemId = itemId or actOrTbl })
			end
		end)
	end

	Players.PlayerRemoving:Connect(function(p)
		TokenBuckets[p] = nil
		WildCoreService.CleanupPlayer(p)
		SkillMechanics.CleanupPlayer(p)
		local ts = TrialSessions[p]
		if ts then
			ts.Active = false
			for _, e in ipairs(ts.Enemies or {}) do
				if e and e.Alive and e.Model and e.Model.Parent then
					e.Alive = false
					e.Model:Destroy()
				end
			end
			TrialSessions[p] = nil
		end
		if PlayerTradeMap[p] then
			cancelTradeSession(PlayerTradeMap[p], p.Name .. " đã rời máy chủ.")
		end
	end)

	-- Build 3D World Tables, NPCs, Sea Water Basins & 45m Wild Core Spawner
	refreshMirageStock()
	pcall(buildCafeTradingTables)
	pcall(WildCoreService.Init, {
		Config = C,
		Data = D,
		Game = G,
		World = W,
		Remotes = R,
		Helpers = Helpers,
		CombatData = CombatData,
		EnsureProfile = ensureExpansionProfile,
		IsInTrade = function(plr)
			return PlayerTradeMap[plr] ~= nil
		end,
	})

	-- Hydrate any already-connected players
	for _, p in ipairs(Players:GetPlayers()) do
		local prof = D.Get(p)
		if prof then
			ensureExpansionProfile(prof)
			G.Sync(p)
		end
	end

	-- Authoritative Background Ticker (Water/Ice/Magma Platforms, Fury, Race V4 Passives, Allied SeaBeast, Mirage Stock, Ken V2)
	task.spawn(function()
		local stockAccum = 0
		local kenAccum = 0
		local prev = os.clock()
		while true do
			task.wait(0.20)
			local now = os.clock()
			local dt = math.min(0.5, now - prev)
			prev = now
			stockAccum += dt
			kenAccum += dt

			if stockAccum >= 1.0 then
				stockAccum = 0
				refreshMirageStock()
			end

			WildCoreService.TickAlliedSeaBeasts(dt)
			SkillMechanics.TickHazards(dt)

			local doKen = false
			if kenAccum >= 0.5 then
				kenAccum = 0
				doKen = true
			end

			for _, p in ipairs(Players:GetPlayers()) do
				tickPlayerWaterAndFury(p, dt)
				if doKen then
					local prof = D.Get(p)
					if prof then
						tickKenV2Inspector(p, prof)
					end
				end
			end
		end
	end)
end

return Expansion
