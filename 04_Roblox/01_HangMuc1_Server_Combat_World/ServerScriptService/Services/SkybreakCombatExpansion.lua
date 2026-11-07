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

local Expansion = {}

-- Module runtime references populated during Expansion.Init(G, D, W, C)
local G, D, W, C, R
local WorldRoot = nil

local TokenBuckets = {}      -- [Player] = { Tokens = 45, LastRefill = os.clock() }
local ActiveTrades = {}      -- [sessionId] = TradeSession
local PlayerTradeMap = {}    -- [Player] = TradeSession
local AlliedSeaBeasts = {}   -- [Player] = SeaBeastRecord
local TrialSessions = {}     -- [Player] = { EndsAt, Enemies = {}, Active = true }
local LastWaterPadPos = {}   -- [Player] = Vector3
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
	local limit = math.clamp(tonumber(maxRange) or 120, 8, 185)
	local fallbackOrigin = hrp.Position + Vector3.new(0, 1.5, 0)
	local fallbackDir = hrp.CFrame.LookVector
	if type(payload) ~= "table" then
		return fallbackOrigin, fallbackDir, fallbackOrigin + fallbackDir * limit
	end

	local rawOrigin = sanitizeVec3(payload.AimOrigin or payload.aimOrigin or payload.Origin or payload.origin)
	local origin = fallbackOrigin
	if rawOrigin and (rawOrigin - hrp.Position).Magnitude <= 18 then
		origin = rawOrigin
	end

	local dir = nil
	local rawDir = sanitizeVec3(payload.AimDir or payload.aimDir or payload.Direction or payload.direction)
	local rawTarget = sanitizeVec3(payload.TargetPos or payload.targetPos)
	if rawTarget then
		local delta = rawTarget - origin
		if delta.Magnitude > 0.05 then
			local clampedDist = math.min(limit, delta.Magnitude)
			dir = delta.Unit
			return origin, dir, origin + dir * clampedDist
		end
	end
	if rawDir and rawDir.Magnitude > 0.05 then
		dir = rawDir.Unit
	else
		dir = fallbackDir.Magnitude > 0.05 and fallbackDir.Unit or Vector3.new(0, 0, -1)
	end
	return origin, dir, origin + dir * limit
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
		local fid = CombatData.ResolveFruitId(profile and profile.EquippedFruit or "")
		local cat = CombatData.FruitCatalog[fid]
		rt.FuryMeter = (cat and cat.MythicalZoan) and 55 or 25
	end
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
		if key == "V" and cat and cat.Rarity == "Mythic" then
			reqLv = tonumber(mCfg.MythicalVThreshold) or 250
		end
		local fCfg = C and C.AetherFruits and C.AetherFruits[fid]
		if fCfg and fCfg.Moves and fCfg.Moves[key] and fCfg.Moves[key].Mastery then
			reqLv = tonumber(fCfg.Moves[key].Mastery) or reqLv
		end
	elseif slot == 3 then
		local wCfg = C and C.Weapons and C.Weapons[itemId]
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
	local hasDoubleExp = (profile.DoubleExpUntil and profile.DoubleExpUntil > os.time())
		or ((tonumber(profile.DoubleExpSeconds) or 0) > 0)
		or (p and (tonumber(p:GetAttribute("DoubleExpSeconds")) or 0) > 0)
	local mult = hasDoubleExp and 2 or 1
	local add = math.max(1, math.floor((tonumber(rawXP) or 10) * mult))

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
	local bVal = ls:FindFirstChild("Bounty")
	if not bVal then
		bVal = Instance.new("IntValue")
		bVal.Name = "Bounty"
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
		local factionTag = (profile.Faction == "Marine") and "Honor" or "Bounty"
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
	syncLeaderstats(p, profile)
	if prev < CombatData.SeaBeastSummonBounty and nextB >= CombatData.SeaBeastSummonBounty then
		unlockTitle(p, profile, "seabeast_caller_10m", false)
		G.Notify(p, "ĐẠT 10,000,000 BOUNTY! Đã mở khóa tuyệt kỹ Triệu Hồi SkySeaBeast Guardian!")
	end
	evaluateAutoTitles(p, profile)
	if reason and reason ~= "" and math.abs(nextB - prev) >= 25000 then
		G.Notify(p, string.format("+%s Bounty (%s) -> Tổng: %s", formatBountyShort(nextB - prev), reason, formatBountyShort(nextB)))
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

local function spawnMagmaPool(p, centerPos, radius, tickDmg, ticks)
	local fxFolder = ensureWorldFolder("CombatZones")
	local fy = groundYAt(centerPos, centerPos.Y - 2.5) + 0.46
	local pool = Instance.new("Part")
	pool.Name = "AwakenedMagmaPool"
	pool.Shape = Enum.PartType.Cylinder
	pool.Size = Vector3.new(0.35, radius * 1.8, radius * 1.8)
	pool.CFrame = CFrame.new(centerPos.X, fy, centerPos.Z) * CFrame.Angles(0, 0, math.pi * 0.5)
	pool.Color = Color3.fromRGB(255, 86, 24)
	pool.Material = Enum.Material.Neon
	pool.Transparency = 0.22
	pool.Anchored = true
	pool.CanCollide = false
	pool.CanQuery = false
	pool.CanTouch = false
	pool.Parent = fxFolder
	Debris:AddItem(pool, ticks * 0.75 + 0.4)

	for i = 1, ticks do
		task.delay(i * 0.7, function()
			if not p or not p.Parent then
				return
			end
			for _, e in ipairs(G.Enemies or {}) do
				if e.Alive and e.Body and (Vector3.new(e.Body.Position.X - centerPos.X, 0, e.Body.Position.Z - centerPos.Z).Magnitude <= radius) then
					G.Hit(p, e, tickDmg, 4, "AwakenedMagmaPool")
				end
			end
		end)
	end
end

-- ============================================================================
-- COMBAT EXECUTION: 5 MARTIAL STYLES (#31-#33), GREATSWORD (#35), GUNS (#36-#38)
-- ============================================================================
local function getEnemiesAlongSegment(origin, endPos, width)
	local results = {}
	local seg = endPos - origin
	local segLen = seg.Magnitude
	local segDir = segLen > 0.05 and seg.Unit or Vector3.new(0, 0, -1)
	local effWidth = math.max(tonumber(width) or 8, 8.5)
	for _, e in ipairs(G.Enemies or {}) do
		if e.Alive and e.Body and e.Model and e.Model.Parent then
			local ep = e.Body.Position
			local rel = ep - origin
			local proj = math.clamp(rel:Dot(segDir), 0, segLen)
			local closest = origin + segDir * proj
			local perpDist = (ep - closest).Magnitude
			local flatPerpDist = Vector3.new(ep.X - closest.X, 0, ep.Z - closest.Z).Magnitude
			local bodyRad = math.max(e.Body.Size.X, e.Body.Size.Z) * 0.5 + 3.5
			if perpDist <= (effWidth + bodyRad)
				or (flatPerpDist <= (effWidth + bodyRad) and math.abs(ep.Y - closest.Y) <= 22)
				or rel.Magnitude <= 14
			then
				table.insert(results, { Enemy = e, Dist = proj })
			end
		end
	end
	table.sort(results, function(a, b)
		return a.Dist < b.Dist
	end)
	return results
end

local function executeMartialStyleKata(p, payload)
	local hrp, hum = getCharRoot(p)
	local rt = G.Runtime[p]
	local profile = D.Get(p)
	if not hrp or not hum or not rt or not profile then
		return true
	end
	ensureExpansionProfile(profile)
	ensureRuntimeFields(p, rt, profile)

	local styleId = CombatData.ResolveStyleId(profile.FightingStyle)
	local style = CombatData.MartialStyles[styleId] or CombatData.MartialStyles.skyborn_combat
	local now = os.clock()
	if now < (rt.NextStyleM1At or 0) then
		return true
	end

	if now - (rt.LastKataAt or 0) > 1.35 then
		rt.KataStep = 1
	else
		rt.KataStep = ((rt.KataStep or 0) % 4) + 1
	end
	rt.LastKataAt = now

	local kata = style.Kata[rt.KataStep] or style.Kata[1]
	rt.NextStyleM1At = now + (kata.Cadence or 0.24)

	local origin, dir = clampAimRay(hrp, payload, math.min(45, kata.Reach or 16))
	local reach = math.min(45, kata.Reach or 16)
	local endPos = hrp.Position + dir * reach

	if kata.Dash and kata.Dash > 0 then
		rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, now + 0.45)
	end

	local stats = G.Stats(p)
	local baseAtk = (stats and stats.ATK) or 40
	local mLv = getMasteryLevel(profile, styleId)
	local masteryMult = 1 + (mLv - 1) * CombatData.MasteryConfig.SkillDamagePerLevel
	local dmg = baseAtk * (kata.Mult or 1.0) * masteryMult

	local hits = getEnemiesAlongSegment(hrp.Position, endPos, (kata.Width or 9) * 0.6)
	local hitAny = false
	for _, rec in ipairs(hits) do
		local e = rec.Enemy
		hitAny = true
		if kata.ArmorShred then
			e.ArmorShredUntil = now + 4.0
		end
		if kata.Pull then
			pullEnemyToward(e, hrp.Position + dir * 4, 8)
		end
		if kata.StunDur and not isBossEnemy(e) then
			e.StunnedUntil = math.max(e.StunnedUntil or 0, now + kata.StunDur)
		end
		G.Hit(p, e, dmg, kata.Break or 6, "StyleKata_" .. styleId)
		if kata.BurnPct then
			applyBurnOrDoT(p, e, dmg * kata.BurnPct, 2, "Flame")
		end
		if not kata.AoE and #hits > 3 then
			break
		end
	end

	if hitAny then
		addMasteryXP(p, styleId, 8 + rt.KataStep * 2)
	end

	if R and R.CombatFX then
		R.CombatFX:FireAllClients({
			Kind = "StyleMove",
			MoveType = "Kata",
			StyleId = styleId,
			MoveKey = "M1",
			MoveName = kata.Name,
			Combo = rt.KataStep,
			Element = style.Element,
			Color = style.Color,
			Origin = origin,
			Position = hrp.Position + dir * (reach * 0.6),
			Direction = dir,
			Actor = p.UserId,
		})
	end
	return true
end

local function executeMartialStyleTechnique(p, key, payload)
	local hrp, hum = getCharRoot(p)
	local rt = G.Runtime[p]
	local profile = D.Get(p)
	if not hrp or not hum or not rt or not profile then
		return true
	end
	ensureExpansionProfile(profile)
	ensureRuntimeFields(p, rt, profile)

	local styleId = CombatData.ResolveStyleId(profile.FightingStyle)
	local style = CombatData.MartialStyles[styleId] or CombatData.MartialStyles.skyborn_combat
	local move = style.Moves[key]
	if not move then
		return false
	end

	if not checkMoveMasteryUnlock(p, profile, styleId, key, 1) then
		return true
	end

	local now = os.clock()
	local cdKey = "Style_" .. styleId .. "_" .. key
	if now < (rt.Cooldowns[cdKey] or 0) or now < (rt.Cooldowns["Slot_" .. key] or 0) then
		return true
	end
	local cost = move.Cost or 10
	if (rt.Energy or 100) < cost then
		G.Notify(p, "Không đủ Aether Energy để thi triển [" .. move.Name .. "]!")
		return true
	end

	local cdMult = 1
	if profile.RaceV4Active and profile.Race == "Ghoul" then
		cdMult = 1 - CombatData.RaceV4Passives.Ghoul.CooldownReductionPct
	end
	local finalCd = (move.Cooldown or 6) * cdMult
	rt.Cooldowns[cdKey] = now + finalCd
	rt.Cooldowns["Slot_" .. key] = now + finalCd
	rt.Energy = math.max(0, (rt.Energy or 100) - cost)
	rt.LastCastAt = now

	local range = math.min(45, move.Range or 24)
	local origin, dir, targetCenter = clampAimRay(hrp, payload, range)
	if move.Dash and move.Dash > 0 then
		rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, now + 1.2)
	end

	local stats = G.Stats(p)
	local baseAtk = (stats and stats.ATK) or 45
	local mLv = getMasteryLevel(profile, styleId)
	local skillMult = (1 + (mLv - 1) * CombatData.MasteryConfig.SkillDamagePerLevel) * (1 + ((stats and stats.StarSkillDmgPct) or 0))
	local totalDmg = baseAtk * (move.Multiplier or 2.8) * skillMult
	local hitsCount = math.max(1, move.Hits or 1)
	local perHitDmg = totalDmg / hitsCount
	local radius = move.Radius or 14

	for pulse = 1, hitsCount do
		local delaySec = (pulse - 1) * 0.11
		task.delay(delaySec, function()
			if not p or not p.Parent then
				return
			end
			local curHrp = getCharRoot(p)
			local pOrigin = curHrp and curHrp.Position or origin
			local pEnd = pOrigin + dir * range
			local hitList = getEnemiesAlongSegment(pOrigin, pEnd, radius)
			local hitCount = 0
			for _, rec in ipairs(hitList) do
				local e = rec.Enemy
				hitCount += 1
				if move.Pull then
					pullEnemyToward(e, pOrigin + dir * 6, 14)
				end
				if move.StunDur and pulse == hitsCount and not isBossEnemy(e) then
					e.StunnedUntil = math.max(e.StunnedUntil or 0, os.clock() + move.StunDur)
				end
				G.Hit(p, e, perHitDmg, math.ceil((move.Break or 28) / hitsCount), "Style_" .. styleId .. "_" .. key)
				if move.BurnTicks and pulse == hitsCount then
					applyBurnOrDoT(p, e, totalDmg * 0.16, move.BurnTicks, "Flame")
				end
			end
			if hitCount > 0 and pulse == hitsCount then
				addMasteryXP(p, styleId, 18 + hitCount * 4)
			end
		end)
	end

	if R and R.CombatFX then
		R.CombatFX:FireAllClients({
			Kind = "StyleMove",
			MoveType = "Technique",
			StyleId = styleId,
			MoveKey = key,
			MoveName = move.Name,
			Combo = 0,
			Hits = hitsCount,
			Element = style.Element,
			Color = style.Color,
			Origin = origin,
			Position = targetCenter,
			Direction = dir,
			Radius = radius,
			Range = range,
			Actor = p.UserId,
		})
	end
	G.Sync(p)
	return true
end

local function executeChargedCrescentSlash(p, payload)
	local hrp, hum = getCharRoot(p)
	local rt = G.Runtime[p]
	local profile = D.Get(p)
	if not hrp or not hum or not rt or not profile then
		return false
	end
	ensureExpansionProfile(profile)
	local swordId = tostring(profile.Weapon or "")
	if (tonumber(profile.ActiveSlot) or 3) ~= 3 or not CombatData.IsChargedSlashWeapon(swordId) then
		return false
	end

	local spec = CombatData.ChargedCrescentSpec
	local now = os.clock()
	if now < (rt.Cooldowns.ChargedCrescentSlash or 0) then
		return true
	end
	local stamCost = tonumber(spec.StaminaCost) or 14
	if (rt.Stamina or 100) < stamCost then
		G.Notify(p, "Không đủ Stamina!")
		return true
	end
	rt.Stamina = math.max(0, (rt.Stamina or 100) - stamCost)
	rt.Cooldowns.ChargedCrescentSlash = now + spec.Cooldown
	rt.Cooldowns.Heavy = now + 1.4

	local rawRatio = type(payload) == "table" and (payload.ChargeRatio or payload.chargeRatio) or 1.0
	local ratio = math.clamp(tonumber(rawRatio) or 1.0, 0, 1)
	local mult = spec.MinMultiplier + (spec.MaxMultiplier - spec.MinMultiplier) * ratio
	local range = spec.MinRange + (spec.MaxRange - spec.MinRange) * ratio
	local radius = spec.MinRadius + (spec.MaxRadius - spec.MinRadius) * ratio
	local breakAdd = math.floor(spec.MinBreakGauge + (spec.MaxBreakGauge - spec.MinBreakGauge) * ratio + 0.5)

	local origin, dir, waveEnd = clampAimRay(hrp, payload, math.min(45, range))
	local stats = G.Stats(p)
	local baseAtk = (stats and stats.ATK) or 60
	local mLv = getMasteryLevel(profile, swordId)
	local skillMult = (1 + (mLv - 1) * CombatData.MasteryConfig.SkillDamagePerLevel) * (1 + ((stats and stats.StarSkillDmgPct) or 0))
	local dmg = baseAtk * mult * skillMult

	local hitList = getEnemiesAlongSegment(hrp.Position, hrp.Position + dir * range, radius)
	for _, rec in ipairs(hitList) do
		G.Hit(p, rec.Enemy, dmg, breakAdd, "ChargedCrescentSlash")
		applyBurnOrDoT(p, rec.Enemy, dmg * 0.14, 2, "Void")
	end
	if #hitList > 0 then
		addMasteryXP(p, swordId, 20 + #hitList * 4)
	end

	if R and R.CombatFX then
		R.CombatFX:FireAllClients({
			Kind = "ChargedSlash",
			WeaponId = swordId,
			MoveName = spec.Name,
			ChargeRatio = ratio,
			Multiplier = mult,
			BreakAdded = breakAdd,
			Element = "VoidMagma",
			Origin = origin,
			Position = waveEnd,
			Direction = dir,
			Range = range,
			Radius = radius,
			Actor = p.UserId,
		})
	end
	G.Sync(p)
	return true
end

local function executeAimedGunShot(p, moveKey, payload)
	local hrp, hum = getCharRoot(p)
	local rt = G.Runtime[p]
	local profile = D.Get(p)
	if not hrp or not hum or not rt or not profile then
		return true
	end
	ensureExpansionProfile(profile)
	local gunId = tostring(profile.EquippedGun or "aether_flintlock")
	local spec = CombatData.GunSpecs[gunId] or CombatData.GunSpecs.aether_flintlock

	local isSkill = (moveKey == "Z" or moveKey == "X" or moveKey == "C" or moveKey == "V")
	if isSkill and not checkMoveMasteryUnlock(p, profile, gunId, moveKey, 4) then
		return true
	end

	local now = os.clock()
	local cdKey = isSkill and ("Slot_" .. moveKey) or "GunM1"
	if now < (rt.Cooldowns[cdKey] or 0) then
		return true
	end

	local gunCfg = (C.Guns and C.Guns[gunId]) or nil
	local moveCfg = (isSkill and gunCfg and gunCfg.Moves and gunCfg.Moves[moveKey]) or nil
	local cd = isSkill and ((moveCfg and moveCfg.Cooldown) or 5.5) or (spec.Cooldown or 0.42)
	local cost = isSkill and ((moveCfg and moveCfg.Cost) or 10) or 0
	if cost > 0 and (rt.Energy or 100) < cost then
		G.Notify(p, "Không đủ Aether Energy!")
		return true
	end
	rt.Cooldowns[cdKey] = now + cd
	if cost > 0 then
		rt.Energy = math.max(0, (rt.Energy or 100) - cost)
		rt.LastCastAt = now
	end

	local maxLen = math.min(180, (gunId == "cryo_railgun" and 115) or (spec.MaxRange or 115))
	local origin, dir, rayEnd = clampAimRay(hrp, payload, maxLen)
	if gunId == "cryo_railgun" then
		rayEnd = origin + dir * 115
	end

	local stats = G.Stats(p)
	local baseAtk = (stats and stats.ATK) or 45
	local mLv = getMasteryLevel(profile, gunId)
	local mult = isSkill and ((moveCfg and moveCfg.Multiplier) or 3.2) or (spec.M1Multiplier or 1.35)
	local skillScale = (1 + (mLv - 1) * CombatData.MasteryConfig.SkillDamagePerLevel) * (1 + ((stats and stats.StarSkillDmgPct) or 0))
	local dmg = baseAtk * mult * skillScale
	local beamRad = (spec.BeamRadius or 6) * (isSkill and 1.35 or 1.0)
	local brk = isSkill and ((moveCfg and moveCfg.Break) or 32) or (spec.Break or 16)

	local candidates = getEnemiesAlongSegment(origin, rayEnd, beamRad)
	local totalDealt = 0
	local hitCount = 0

	for _, rec in ipairs(candidates) do
		local e = rec.Enemy
		local preHP = e.HP or 0
		G.Hit(p, e, dmg, brk, "Gun_" .. gunId .. "_" .. tostring(moveKey or "M1"))
		local dealt = math.max(0, preHP - (e.HP or 0))
		totalDealt += dealt
		hitCount += 1

		if gunId == "soul_guitar_void" then
			-- #37: 1.4s Acoustic Stun on hit enemies
			e.StunnedUntil = math.max(e.StunnedUntil or 0, now + (spec.StunDuration or 1.4))
			if e.Model then
				e.Model:SetAttribute("AcousticStun", true)
				task.delay(spec.StunDuration or 1.4, function()
					if e and e.Model and e.Model.Parent then
						e.Model:SetAttribute("AcousticStun", false)
					end
				end)
			end
		elseif gunId == "cryo_railgun" then
			-- #38: 2.2s Cryo Freeze along entire 115-stud piercing beam
			applyCryoFreeze(e, spec.FreezeDuration or 2.2)
		elseif spec.BurnTicks then
			applyBurnOrDoT(p, e, dmg * 0.14, spec.BurnTicks, "Flame")
		end

		if not spec.Piercing and not isSkill then
			rayEnd = e.Body and e.Body.Position or rayEnd
			break
		end
	end

	-- #37: Soul Guitar Void heals caster for 15% of total damage dealt
	local healAmt = 0
	if gunId == "soul_guitar_void" and totalDealt > 0 and hum.Health > 0 then
		healAmt = math.max(1, math.floor(totalDealt * (spec.LifestealPct or 0.15)))
		hum.Health = math.min(hum.MaxHealth, hum.Health + healAmt)
	end

	if hitCount > 0 then
		addMasteryXP(p, gunId, (isSkill and 18 or 9) + hitCount * 3)
	end

	if R and R.CombatFX then
		R.CombatFX:FireAllClients({
			Kind = "GunShot",
			SubKind = spec.SubKind,
			WeaponId = gunId,
			MoveKey = moveKey or "M1",
			Element = spec.Element,
			Color = spec.Color,
			Origin = origin,
			EndPos = rayEnd,
			Position = rayEnd,
			Direction = dir,
			Length = (rayEnd - origin).Magnitude,
			PiercedCount = hitCount,
			HealAmount = healAmt,
			Actor = p.UserId,
		})
	end
	if isSkill then
		G.Sync(p)
	end
	return true
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

	local function isBlockedFromPortalWarp(plr)
		if G.Boss and G.Boss.Party and G.Boss.Party[plr] then
			return true
		end
		if PlayerTradeMap[plr] ~= nil or TrialSessions[plr] ~= nil then
			return true
		end
		if plr:GetAttribute("RaidActive") == true or plr:GetAttribute("ColosseumActive") == true or plr:GetAttribute("InColosseum") == true or plr:GetAttribute("InColosseumDuel") == true then
			return true
		end
		return false
	end

	local warpedPlayers = {}
	for _, plr in ipairs(Players:GetPlayers()) do
		local phrp = getCharRoot(plr)
		local prt = G.Runtime[plr]
		local pprof = D.Get(plr)
		if phrp and prt and pprof and not isBlockedFromPortalWarp(plr) and (plr == caster or (phrp.Position - entryPos).Magnitude <= 14) then
			prt.JumpPadUntil = os.clock() + 3.5
			pprof.UnlockedWorlds = pprof.UnlockedWorlds or {}
			if type(destIsland.Realm) == "string" and destIsland.Realm ~= "" then
				pprof.UnlockedWorlds[destIsland.Realm] = true
			end
			if type(destIsland.Id) == "string" and destIsland.Id ~= "" and not tonumber(destIsland.Id) then
				pprof.UnlockedWorlds[destIsland.Id] = true
			end
			plr:SetAttribute("CurrentRealm", destIsland.Realm or "GoldenSky")
			G.Teleport(plr, destPos)
			table.insert(warpedPlayers, plr.UserId)
			if plr == caster then
				unlockTitle(plr, pprof, "dimensional_traveler", false)
			end
			G.Notify(plr, "PORTAL WORLD WARP -> " .. destIsland.Name .. "!")
			G.Sync(plr)
		end
	end

	if R and R.CombatFX then
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
	if now < (rt.Cooldowns.PortalWarpC or 0) then
		return true
	end
	rt.Cooldowns.PortalWarpC = now + 5.5
	rt.Cooldowns.Slot_C = now + 5.5

	local islands = getOrderedIslands()
	if #islands == 0 then
		return false
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
			addMasteryXP(p, "DimensionalPortalCore", 22)
			performPortalWorldWarp(p, hrp.Position, chosen)
			return true
		end
	end

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
		rt.SelectedPortalIndex = (rt.SelectedPortalIndex % #islands) + 1
		curDest = islands[rt.SelectedPortalIndex]
		destLabel.Text = string.format("CỔNG KHÔNG GIAN [%d/%d]: %s", rt.SelectedPortalIndex, #islands, curDest.Name)
		warpPrompt.ActionText = "Dịch Chuyển Tức Thời -> " .. curDest.Name
		G.Notify(who, string.format("Đổi đích Cổng Không Gian [%d/%d]: %s", rt.SelectedPortalIndex, #islands, curDest.Name))
	end)

	warpPrompt.Triggered:Connect(function(who)
		if gateModel and gateModel.Parent then
			gateModel:Destroy()
		end
		addMasteryXP(p, "DimensionalPortalCore", 22)
		performPortalWorldWarp(who, gatePos, curDest)
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

	if not checkMoveMasteryUnlock(p, profile, fruitId, "V", 2) then
		return true
	end

	local fury = tonumber(rt.FuryMeter) or 0
	local curTier = tonumber(rt.DragonFormTier) or 0
	-- Toggle Dragon Form OFF if already at Tier 2, or if at Tier 1 without 100% Fury to ascend to Tier 2
	if curTier == 2 or (curTier == 1 and fury < 99.5) then
		rt.DragonFormTier = 0
		p:SetAttribute("DragonFormTier", 0)
		p:SetAttribute("FruitTransform", "")
		if ch then
			ch:SetAttribute("DragonFormTier", 0)
			ch:SetAttribute("FruitTransform", "")
		end
		if R and R.CombatFX then
			R.CombatFX:FireAllClients({
				Kind = "DragonTransform",
				DragonFormTier = 0,
				TransformName = "",
				Awakened = profile.AwakenedFruits and profile.AwakenedFruits[fruitId] == true,
				FuryMeter = fury,
				Radius = 14,
				Position = hrp.Position,
				Actor = p.UserId,
			})
		end
		G.Notify(p, "Đã thu hồi Long Hóa, trở về nhân dạng.")
		G.Sync(p)
		return true
	end

	if fury < 50 then
		G.Notify(p, string.format("Cần tối thiểu 50%% Nộ Khí (Fury) để Hóa Bán Long hoặc 100%% để Hóa Hoàng Long! (Hiện tại: %d%%)", math.floor(fury)))
		return true
	end

	local tier = (fury >= 99.5) and 2 or 1
	rt.DragonFormTier = tier
	local tfName = (tier == 2) and "AbyssalSovereign" or "AbyssalDragonHybrid"
	p:SetAttribute("DragonFormTier", tier)
	p:SetAttribute("FruitTransform", tfName)
	if ch then
		ch:SetAttribute("DragonFormTier", tier)
		ch:SetAttribute("FruitTransform", tfName)
	end

	local stats = G.Stats(p)
	local atk = (stats and stats.ATK) or 65
	local awk = profile.AwakenedFruits and profile.AwakenedFruits[fruitId] == true
	local burstMult = (tier == 2 and 6.2 or 4.1) * (awk and 1.38 or 1.0)
	local burstRadius = tier == 2 and 46 or 28
	local burstBreak = tier == 2 and 68 or 42

	if tier == 2 then
		rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, os.clock() + 40)
		unlockTitle(p, profile, "sovereign_dragon_king", false)
		G.Notify(p, "TIER 2 FULL SOVEREIGN DRAGON (100% FURY): Hoàng Long Khổng Lồ giáng thế (+40% DEF, +32% ATK, Phi Hành)!")
	else
		G.Notify(p, "TIER 1 ABYSSAL DRAGON HYBRID (50%+ FURY): Hóa Bán Long Nhân (+22% Speed, +25% DEF)!")
	end

	for _, e in ipairs(G.Enemies or {}) do
		if e.Alive and e.Body and (e.Body.Position - hrp.Position).Magnitude <= burstRadius then
			G.Hit(p, e, atk * burstMult, burstBreak, "DragonFuryAscension_T" .. tostring(tier))
			applyBurnOrDoT(p, e, atk * 0.45, tier == 2 and 4 or 2, "Void")
		end
	end
	addMasteryXP(p, fruitId, tier == 2 and 34 or 22)

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

local function executeAwakenedFruitV2Move(p, fruitId, key, payload)
	local hrp = getCharRoot(p)
	local rt = G.Runtime[p]
	local profile = D.Get(p)
	if not hrp or not rt or not profile then
		return false
	end
	local cid = CombatData.ResolveFruitId(fruitId)
	local isAwakened = profile.AwakenedFruits and (profile.AwakenedFruits[cid] == true or profile.AwakenedFruits[fruitId] == true)
	if not isAwakened then
		return false
	end
	local v2Set = CombatData.AwakenedFruitMoves[cid]
	local v2 = v2Set and v2Set[key]
	if not v2 then
		return false
	end
	if not checkMoveMasteryUnlock(p, profile, cid, key, 2) then
		return true
	end

	local fruitCfg = C.AetherFruits and C.AetherFruits[cid]
	local baseMove = fruitCfg and fruitCfg.Moves and fruitCfg.Moves[key]
	local cd = (baseMove and baseMove.Cooldown) or 7.0
	local cost = (baseMove and baseMove.Cost) or 14
	local now = os.clock()
	if now < (rt.Cooldowns["Slot_" .. key] or 0) then
		return true
	end
	if (rt.Energy or 100) < cost then
		G.Notify(p, "Không đủ Aether Energy!")
		return true
	end
	local cdMult = (profile.RaceV4Active and profile.Race == "Ghoul") and (1 - CombatData.RaceV4Passives.Ghoul.CooldownReductionPct) or 1
	rt.Cooldowns["Slot_" .. key] = now + cd * cdMult
	rt.Energy = math.max(0, (rt.Energy or 100) - cost)
	rt.LastCastAt = now

	local mLv = getMasteryLevel(profile, cid)
	if cid == "SolarTitanCore" and key == "Z" then
		local ch = p.Character
		local curTf = (ch and ch:GetAttribute("FruitTransform")) or p:GetAttribute("FruitTransform") or ""
		local nextTf = (curTf == "SolarTitan") and "" or "SolarTitan"
		p:SetAttribute("FruitTransform", nextTf)
		if ch then
			ch:SetAttribute("FruitTransform", nextTf)
		end
		if nextTf == "SolarTitan" then
			G.Notify(p, "AWAKENED SOLAR TITAN SHIFT: Hóa Đại Kim Thân Thức Tỉnh 3D (+58% Giáp, x2.5 Tầm Đánh)!")
		else
			G.Notify(p, "AWAKENED SOLAR TITAN SHIFT: Thu hồi Kim Thân, trở về nhân dạng!")
		end
	elseif key == "F" then
		local flightBoost = (mLv >= CombatData.MasteryConfig.FlightEnhancedLevel) and 1.35 or 1.0
		rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, now + 3.2 * flightBoost)
	end

	local baseRange = math.min(60, (baseMove and baseMove.Range) or 28)
	local radius = math.min(48, baseRange * 0.62 * (v2.RadiusScale or 1.4))
	local origin, dir, centerPos = clampAimRay(hrp, payload, baseRange)

	local stats = G.Stats(p)
	local baseAtk = (stats and stats.ATK) or 55
	local baseMult = (baseMove and baseMove.Multiplier) or 3.2
	local skillMult = (1 + (mLv - 1) * CombatData.MasteryConfig.SkillDamagePerLevel) * (1 + ((stats and stats.StarSkillDmgPct) or 0))
	local totalDmg = baseAtk * baseMult * (v2.MultBoost or 1.34) * skillMult
	local hits = math.max(1, v2.Hits or 3)
	local perHit = totalDmg / hits
	local brk = math.ceil((((baseMove and baseMove.Break) or 30) * 1.25) / hits)

	if v2.Mechanic == "MagmaPoolDoT" then
		spawnMagmaPool(p, centerPos, math.max(10, radius * 0.75), totalDmg * 0.16, v2.DoTTicks or 4)
	end

	for pulse = 1, hits do
		task.delay((pulse - 1) * 0.12, function()
			if not p or not p.Parent then
				return
			end
			local hitCount = 0
			for _, e in ipairs(G.Enemies or {}) do
				if e.Alive and e.Body and (e.Body.Position - centerPos).Magnitude <= radius then
					hitCount += 1
					if v2.PullStrength then
						pullEnemyToward(e, centerPos, v2.PullStrength / hits)
					end
					if pulse == hits then
						if v2.FreezeDur then
							applyCryoFreeze(e, v2.FreezeDur)
						elseif v2.StunDur and not isBossEnemy(e) then
							e.StunnedUntil = math.max(e.StunnedUntil or 0, os.clock() + v2.StunDur)
						end
						if v2.DoTTicks and v2.Mechanic ~= "MagmaPoolDoT" then
							applyBurnOrDoT(p, e, totalDmg * 0.14, v2.DoTTicks, (fruitCfg and fruitCfg.Element) or "Flame")
						end
					end
					G.Hit(p, e, perHit, brk, "AwakenedV2_" .. cid .. "_" .. key)
				end
			end
			if pulse == hits and hitCount > 0 then
				addMasteryXP(p, cid, 24 + hitCount * 4)
			end
		end)
	end

	if R and R.CombatFX then
		R.CombatFX:FireAllClients({
			Kind = "FruitMove",
			Awakened = true,
			FruitId = cid,
			MoveKey = key,
			MoveName = v2.Name,
			Mechanic = v2.Mechanic,
			Hits = hits,
			Element = (fruitCfg and fruitCfg.Element) or "Sky",
			Origin = origin,
			Position = centerPos,
			Direction = dir,
			Radius = radius,
			Actor = p.UserId,
		})
	end
	G.Sync(p)
	return true
end

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
	if not profile then
		return false
	end
	ensureExpansionProfile(profile)
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
		G.Notify(p, "Lõi Aether này hiện không có trong Kho Hư Quang giờ này!")
		return false
	end

	local price = chosenItem.PriceGold or 250000
	if (profile.Gold or 0) < price then
		G.Notify(p, string.format("Không đủ Gold mua [%s] (Cần %d Gold, hiện có %d Gold)!", chosenItem.Name, price, profile.Gold or 0))
		return false
	end

	profile.Gold -= price
	profile.StoredFruits[chosenItem.Id] = (profile.StoredFruits[chosenItem.Id] or 0) + 1
	if equipNow == true or profile.EquippedFruit == "" or profile.EquippedFruit == nil then
		profile.EquippedFruit = chosenItem.Id
		profile.ActiveSlot = 2
	end
	profile.HeldFruit = chosenItem.Id
	unlockTitle(p, profile, "mirage_tycoon", false)
	G.Notify(p, string.format("THƯƠNG NHÂN HƯ QUANG: Đã mua trực tiếp [%s] với giá %d Gold!", chosenItem.Name, price))
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
		if claimed or not m.Parent then
			return
		end
		local pprof = D.Get(picker)
		if not pprof then
			return
		end
		claimed = true
		ensureExpansionProfile(pprof)
		pprof.StoredFruits[cid] = (pprof.StoredFruits[cid] or 0) + 1
		pprof.HeldFruit = cid
		m:Destroy()
		G.Notify(picker, "Đã nhặt Lõi Aether 3D: [" .. cat.Name .. "]!")
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
	for _, fid in ipairs(session.OfferA) do
		needA[fid] = (needA[fid] or 0) + 1
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
		for _, fid in ipairs(session.OfferB) do
			needB[fid] = (needB[fid] or 0) + 1
		end
		for fid, cnt in pairs(needB) do
			if (tonumber(profB.StoredFruits[fid]) or 0) < cnt then
				cancelTradeSession(session, "Kho Lõi Aether của " .. pB.Name .. " không đủ số lượng đã đặt!")
				return
			end
		end
	else
		for _, fid in ipairs(session.OfferB) do
			needB[fid] = (needB[fid] or 0) + 1
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

local function spawnNPCCollectorAtSeat(seatPos, lookPos, parentFolder)
	local m = Instance.new("Model")
	m.Name = "NPC_FruitCollector"
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2.0, 2.2, 1.1)
	torso.CFrame = CFrame.lookAt(seatPos + Vector3.new(0, 1.6, 0), Vector3.new(lookPos.X, seatPos.Y + 1.6, lookPos.Z))
	torso.Color = Color3.fromRGB(48, 36, 84)
	torso.Material = Enum.Material.SmoothPlastic
	torso.Anchored = true
	torso.CanCollide = false
	torso.Parent = m

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.3, 1.3, 1.3)
	head.CFrame = torso.CFrame * CFrame.new(0, 1.75, 0)
	head.Color = Color3.fromRGB(238, 208, 178)
	head.Material = Enum.Material.SmoothPlastic
	head.Anchored = true
	head.CanCollide = false
	head.Parent = m

	local bill = Instance.new("BillboardGui")
	bill.Size = UDim2.fromOffset(180, 32)
	bill.StudsOffset = Vector3.new(0, 2.0, 0)
	bill.MaxDistance = 45
	bill.LightInfluence = 0
	bill.Parent = head

	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamBold
	tl.TextSize = 12
	tl.TextColor3 = Color3.fromRGB(162, 242, 210)
	tl.TextStrokeTransparency = 0.2
	tl.Text = "Nhà Sưu Tầm Ảo Ảnh [Trade]"
	tl.Parent = bill

	m.PrimaryPart = torso
	m.Parent = parentFolder
	return m
end

local function buildCafeTradingTables()
	local hubFolder = ensureWorldFolder("CyberportCafeTradingHub")
	hubFolder:ClearAllChildren()

	local cafeBase = (C.FastTravel and C.FastTravel.CyberportCafe and C.FastTravel.CyberportCafe.Pos) or Vector3.new(9400, 50.9, 1785)
	local tableCenters = {
		Vector3.new(cafeBase.X - 10, cafeBase.Y, cafeBase.Z - 14),
		Vector3.new(cafeBase.X + 12, cafeBase.Y, cafeBase.Z - 14),
	}

	for tIdx, rawCenter in ipairs(tableCenters) do
		local fy = groundYAt(rawCenter, 46.9)
		local center = Vector3.new(rawCenter.X, fy, rawCenter.Z)

		local tModel = Instance.new("Model")
		tModel.Name = "FruitTradingTable_" .. tostring(tIdx)
		tModel.Parent = hubFolder

		local pedestal = Instance.new("Part")
		pedestal.Name = "TablePedestal"
		pedestal.Size = Vector3.new(2.2, 2.6, 2.2)
		pedestal.Position = center + Vector3.new(0, 1.3, 0)
		pedestal.Color = Color3.fromRGB(28, 36, 52)
		pedestal.Material = Enum.Material.Metal
		pedestal.Anchored = true
		pedestal.Parent = tModel

		local top = Instance.new("Part")
		top.Name = "TableTop"
		top.Size = Vector3.new(7.6, 0.45, 5.4)
		top.Position = center + Vector3.new(0, 2.75, 0)
		top.Color = Color3.fromRGB(18, 24, 38)
		top.Material = Enum.Material.Glass
		top.Anchored = true
		top.Parent = tModel

		local trim = Instance.new("Part")
		trim.Name = "NeonTrim"
		trim.Size = Vector3.new(7.8, 0.16, 5.6)
		trim.Position = center + Vector3.new(0, 2.62, 0)
		trim.Color = Color3.fromRGB(72, 226, 255)
		trim.Material = Enum.Material.Neon
		trim.Anchored = true
		trim.CanCollide = false
		trim.Parent = tModel

		local holoBill = Instance.new("BillboardGui")
		holoBill.Size = UDim2.fromOffset(290, 40)
		holoBill.StudsOffset = Vector3.new(0, 3.8, 0)
		holoBill.MaxDistance = 60
		holoBill.LightInfluence = 0
		holoBill.Parent = top

		local statusLbl = Instance.new("TextLabel")
		statusLbl.Name = "StatusLabel"
		statusLbl.Size = UDim2.fromScale(1, 1)
		statusLbl.BackgroundTransparency = 1
		statusLbl.Font = Enum.Font.GothamBlack
		statusLbl.TextSize = 13
		statusLbl.TextColor3 = Color3.fromRGB(110, 238, 255)
		statusLbl.TextStrokeTransparency = 0.2
		statusLbl.Text = "BÀN GIAO DỊCH LÕI AETHER #" .. tostring(tIdx) .. " (<= 40% Value Lock)"
		statusLbl.Parent = holoBill

		-- 4 Chairs: Pair 1 (Chair 1 North <-> Chair 2 South, West lane), Pair 2 (Chair 3 North <-> Chair 4 South, East lane)
		local chairSpecs = {
			{ Idx = 1, Pair = 1, Side = "A", Offset = Vector3.new(-1.9, 1.35, -4.1) },
			{ Idx = 2, Pair = 1, Side = "B", Offset = Vector3.new(-1.9, 1.35, 4.1) },
			{ Idx = 3, Pair = 2, Side = "A", Offset = Vector3.new(1.9, 1.35, -4.1) },
			{ Idx = 4, Pair = 2, Side = "B", Offset = Vector3.new(1.9, 1.35, 4.1) },
		}

		local pairSeats = { [1] = {}, [2] = {} }
		local pairSessions = { [1] = nil, [2] = nil }

		local function getPlayerFromHumanoid(hum)
			if not hum or not hum.Parent then
				return nil
			end
			return Players:GetPlayerFromCharacter(hum.Parent)
		end

		local function refreshPairSession(pairId)
			local seats = pairSeats[pairId]
			local pA = getPlayerFromHumanoid(seats.A and seats.A.Occupant)
			local pB = getPlayerFromHumanoid(seats.B and seats.B.Occupant)
			local cur = pairSessions[pairId]

			if not pA and not pB then
				if cur then
					cancelTradeSession(cur, "Hai ghế giao dịch đã trống.")
					pairSessions[pairId] = nil
				end
				return
			end

			if pA and pB and pA ~= pB then
				if cur and (cur.IsNPCCollector or cur.PlayerA ~= pA or cur.PlayerB ~= pB) then
					cancelTradeSession(cur, "Người chơi mới tham gia bàn giao dịch.")
					cur = nil
				end
				if not cur or cur.Closed then
					local sid = string.format("CafeTable%d_Pair%d_%d", tIdx, pairId, math.floor(os.clock() * 100))
					cur = {
						Id = sid,
						PlayerA = pA,
						PlayerB = pB,
						IsNPCCollector = false,
						OfferA = {},
						OfferB = {},
						AcceptedA = false,
						AcceptedB = false,
						Countdown = 0,
						StatusLabel = statusLbl,
					}
					pairSessions[pairId] = cur
					ActiveTrades[sid] = cur
					PlayerTradeMap[pA] = cur
					PlayerTradeMap[pB] = cur
					pA:SetAttribute("InTrade", true)
					pB:SetAttribute("InTrade", true)
					G.Notify(pA, "Đã kết nối Bàn Giao Dịch Lõi Aether với " .. pB.Name .. " (Khóa <= 40% giá trị)!")
					G.Notify(pB, "Đã kết nối Bàn Giao Dịch Lõi Aether với " .. pA.Name .. " (Khóa <= 40% giá trị)!")
					sendTradeSnapshot(cur, "TradeStarted", "Phiên giao dịch 2 người đã mở!")
				end
				return
			end

			-- Single-player seated: spawn interactive NPC Collector Trade Partner across the table after 1.0s!
			local soloPlr = pA or pB
			if soloPlr and (not cur or cur.Closed) then
				task.delay(1.0, function()
					local checkA = getPlayerFromHumanoid(seats.A and seats.A.Occupant)
					local checkB = getPlayerFromHumanoid(seats.B and seats.B.Occupant)
					if (checkA == soloPlr and not checkB) or (checkB == soloPlr and not checkA) then
						if pairSessions[pairId] and not pairSessions[pairId].Closed then
							return
						end
						local oppSeat = (checkA == soloPlr) and seats.B or seats.A
						local npcModel = spawnNPCCollectorAtSeat(oppSeat.Position, center, tModel)
						local sid = string.format("CafeSoloTable%d_Pair%d_%d", tIdx, pairId, math.floor(os.clock() * 100))
						local soloSession = {
							Id = sid,
							PlayerA = soloPlr,
							PlayerB = nil,
							IsNPCCollector = true,
							NPCModel = npcModel,
							OfferA = {},
							OfferB = {},
							AcceptedA = false,
							AcceptedB = false,
							Countdown = 0,
							StatusLabel = statusLbl,
						}
						pairSessions[pairId] = soloSession
						ActiveTrades[sid] = soloSession
						PlayerTradeMap[soloPlr] = soloSession
						soloPlr:SetAttribute("InTrade", true)
						G.Notify(soloPlr, "Nhà Sưu Tầm Hư Quang đã ngồi đối diện! Đặt Lõi Aether (AddFruit) để giao dịch (<= 40% Value Lock + 5s Countdown)!")
						sendTradeSnapshot(soloSession, "TradeStarted", "Nhà Sưu Tầm Hư Quang sẵn sàng đổi lõi công bằng!")
					end
				end)
			elseif cur and not cur.Closed and cur.PlayerA ~= soloPlr and cur.PlayerB ~= soloPlr then
				cancelTradeSession(cur, "Người chơi đã đứng dậy rời ghế.")
				pairSessions[pairId] = nil
			end
		end

		for _, cs in ipairs(chairSpecs) do
			local seatPos = center + cs.Offset
			local lookAtTable = Vector3.new(center.X + cs.Offset.X, seatPos.Y, center.Z)
			local seat = Instance.new("Seat")
			seat.Name = "TradeChair_" .. tostring(cs.Idx)
			seat.Size = Vector3.new(2.1, 0.55, 2.1)
			seat.CFrame = CFrame.lookAt(seatPos, lookAtTable)
			seat.Color = Color3.fromRGB(36, 48, 72)
			seat.Material = Enum.Material.SmoothPlastic
			seat.Anchored = true
			seat.Parent = tModel

			local back = Instance.new("Part")
			back.Name = "ChairBack_" .. tostring(cs.Idx)
			back.Size = Vector3.new(2.1, 1.8, 0.35)
			back.CFrame = seat.CFrame * CFrame.new(0, 1.1, 0.95)
			back.Color = Color3.fromRGB(52, 68, 98)
			back.Material = Enum.Material.Metal
			back.Anchored = true
			back.Parent = tModel

			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Ngồi Giao Dịch Lõi Aether (Ghế " .. tostring(cs.Idx) .. ")"
			prompt.ObjectText = "Bàn Giao Dịch #" .. tostring(tIdx)
			prompt.HoldDuration = 0
			prompt.MaxActivationDistance = 10
			prompt.RequiresLineOfSight = false
			prompt.Parent = seat

			prompt.Triggered:Connect(function(who)
				local _, whum = getCharRoot(who)
				if whum and not seat.Occupant then
					seat:Sit(whum)
				end
			end)

			pairSeats[cs.Pair][cs.Side] = seat
			seat:GetPropertyChangedSignal("Occupant"):Connect(function()
				if not seat.Occupant then
					local cur = pairSessions[cs.Pair]
					if cur and not cur.Closed then
						local occA = getPlayerFromHumanoid(pairSeats[cs.Pair].A and pairSeats[cs.Pair].A.Occupant)
						local occB = getPlayerFromHumanoid(pairSeats[cs.Pair].B and pairSeats[cs.Pair].B.Occupant)
						if cur.IsNPCCollector and not occA and not occB then
							cancelTradeSession(cur, "Đã rời ghế giao dịch.")
							pairSessions[cs.Pair] = nil
						elseif not cur.IsNPCCollector and (not occA or not occB) then
							cancelTradeSession(cur, "Một bên đã rời ghế giao dịch.")
							pairSessions[cs.Pair] = nil
						end
					end
				end
				refreshPairSession(cs.Pair)
			end)
		end
	end
end

-- ============================================================================
-- WATER / DENSE-CLOUD SEA HAZARD & ICE/MAGMA STEPPING PLATFORMS (#46)
-- ============================================================================
local function buildDockSeaWaterBasins()
	local waterFolder = ensureWorldFolder("SeaWaterZones")
	waterFolder:ClearAllChildren()

	local basins = {
		{ Name = "SkyHubSeaBasin", Pos = Vector3.new(-428, 18.5, 565), Size = Vector3.new(320, 1.4, 320) },
		{ Name = "CyberportSeaBasin", Pos = Vector3.new(9400, 18.5, 2365), Size = Vector3.new(320, 1.4, 320) },
	}
	for _, b in ipairs(basins) do
		local p = Instance.new("Part")
		p.Name = b.Name
		p.Size = b.Size
		p.Position = b.Pos
		p.Color = Color3.fromRGB(32, 118, 185)
		p.Material = Enum.Material.Glass
		p.Transparency = 0.38
		p.Anchored = true
		p.CanCollide = true
		p:SetAttribute("IsSeaWaterZone", true)
		p.Parent = waterFolder
	end
end

local function spawnSteppingPlatform(p, pos, mode)
	local lastPos = LastWaterPadPos[p]
	if lastPos and (Vector3.new(pos.X - lastPos.X, 0, pos.Z - lastPos.Z).Magnitude < 3.4) then
		return
	end
	LastWaterPadPos[p] = pos

	local padFolder = ensureWorldFolder("ElementalWaterPads")
	local pad = Instance.new("Part")
	pad.Name = (mode == "Ice") and "GlacierStepPad" or "MagmaBasaltPad"
	pad.Shape = Enum.PartType.Cylinder
	pad.Size = Vector3.new(1.1, 11.5, 11.5)
	pad.CFrame = CFrame.new(pos.X, pos.Y - 3.35, pos.Z) * CFrame.Angles(0, 0, math.pi * 0.5)
	if mode == "Ice" then
		pad.Color = Color3.fromRGB(132, 236, 255)
		pad.Material = Enum.Material.Ice
		pad.Transparency = 0.15
	else
		pad.Color = Color3.fromRGB(54, 42, 46)
		pad.Material = Enum.Material.Basalt
		pad.Transparency = 0
	end
	pad.Anchored = true
	pad.CanCollide = true
	pad.Parent = padFolder
	Debris:AddItem(pad, 6.5)
end

local function tickPlayerWaterAndFury(p, dt)
	local hrp, hum, ch = getCharRoot(p)
	local rt = G.Runtime[p]
	local profile = D.Get(p)
	if not hrp or not hum or not rt or not profile then
		return
	end
	ensureExpansionProfile(profile)
	ensureRuntimeFields(p, rt, profile)

	-- #48: Fury Meter passive regen / transformation drain
	local fid = CombatData.ResolveFruitId(profile.EquippedFruit)
	local cat = CombatData.FruitCatalog[fid]
	if (rt.DragonFormTier or 0) > 0 and ((p:GetAttribute("DragonFormTier") or 0) == 0 or (ch and (ch:GetAttribute("DragonFormTier") or 0) == 0)) then
		rt.DragonFormTier = 0
		p:SetAttribute("FruitTransform", "")
	end
	if (rt.DragonFormTier or 0) > 0 then
		local drain = (rt.DragonFormTier == 2) and 3.0 or 2.0
		rt.FuryMeter = math.max(0, (rt.FuryMeter or 0) - drain * dt)
		if rt.FuryMeter <= 0 then
			rt.DragonFormTier = 0
			p:SetAttribute("DragonFormTier", 0)
			p:SetAttribute("FruitTransform", "")
			if ch then
				ch:SetAttribute("DragonFormTier", 0)
				ch:SetAttribute("FruitTransform", "")
			end
			if R and R.CombatFX then
				R.CombatFX:FireAllClients({
					Kind = "DragonTransform",
					DragonFormTier = 0,
					TransformName = "",
					FuryMeter = 0,
					Radius = 12,
					Position = hrp.Position,
					Actor = p.UserId,
				})
			end
			G.Notify(p, "Nộ Khí (Fury) đã cạn - Kết thúc trạng thái Hóa Rồng.")
		end
	elseif cat and cat.MythicalZoan then
		rt.FuryMeter = math.min(100, (rt.FuryMeter or 0) + 1.6 * dt)
	end
	p:SetAttribute("FuryMeter", math.floor((rt.FuryMeter or 0) + 0.5))
	if ch then
		ch:SetAttribute("FuryMeter", math.floor((rt.FuryMeter or 0) + 0.5))
	end

	-- #52: Race V4 active passives & AwakeningMeter drain/regen
	if profile.RaceV4Active then
		local race = profile.Race or "Skyborn"
		local now = os.clock()
		profile.AwakeningMeter = math.max(0, (tonumber(profile.AwakeningMeter) or 100) - 2.2 * dt)
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
			if sAfter then
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
	elseif profile.RaceV4Unlocked or (tonumber(profile.Level) or 1) >= 1500 then
		profile.AwakeningMeter = math.min(100, (tonumber(profile.AwakeningMeter) or 0) + 1.4 * dt)
		p:SetAttribute("AwakeningMeter", math.floor(profile.AwakeningMeter + 0.5))
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
			spawnSteppingPlatform(p, hrp.Position, cat.WaterWalk)
		elseif fid ~= "" then
			-- Gentle water-drain for non-Leviathan Devil Fruit users
			local drainHP = math.max(1, hum.MaxHealth * 0.035 * dt)
			if hum.Health > drainHP + 5 then
				hum:TakeDamage(drainHP)
			end
			rt.Energy = math.max(0, (rt.Energy or 100) - 4 * dt)
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
	if not style then
		return false
	end

	if not profile.UnlockedStyles[sid] then
		local needGold = style.PriceGold or 0
		local needShards = style.PriceShards or 0
		if (profile.Gold or 0) < needGold or (profile.CoreShards or 0) < needShards then
			G.Notify(p, string.format("Cần %d Gold & %d Core Shards để lĩnh ngộ [%s]!", needGold, needShards, style.Name))
			return false
		end
		profile.Gold -= needGold
		profile.CoreShards -= needShards
		profile.UnlockedStyles[sid] = true
	end

	profile.FightingStyle = sid
	profile.ActiveSlot = 1
	p:SetAttribute("FightingStyle", sid)
	if p.Character then
		p.Character:SetAttribute("FightingStyle", sid)
	end
	evaluateAutoTitles(p, profile)
	G.Notify(p, "Đã trang bị Võ Thuật [Slot 1]: " .. style.DisplayName .. "!")
	G.Sync(p)
	return true
end

local function startTempleRaceV4Trial(p, altarPos)
	local profile = D.Get(p)
	local hrp = getCharRoot(p)
	if not profile or not hrp then
		return
	end
	ensureExpansionProfile(profile)
	if TrialSessions[p] and TrialSessions[p].Active then
		G.Notify(p, "Bạn đang trong Thử Thách Thăng Hoa (60s)!")
		return
	end

	local enemies = {}
	local offsets = { Vector3.new(-14, 2, -10), Vector3.new(14, 2, -10), Vector3.new(0, 2, -16) }
	for _, off in ipairs(offsets) do
		local e = G.SpawnEnemy("AbyssalKnight", altarPos + off, false, true)
		if e then
			e.MaxHP = math.max(900, math.floor((profile.Level or 100) * 14))
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
	G.Notify(p, "THỬ THÁCH THĂNG HOA BẮT ĐẦU (60 GIÂY): Tiêu diệt 3 Hộ Vệ Đền Thăng Hoa để mở khóa vĩnh viễn THĂNG HOA & Core Gear!")

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
					G.Notify(p, "Thử Thách Thăng Hoa kết thúc do bạn đã rời khỏi Đền Thăng Hoa. Hãy quay lại kéo Cần Gạt Cổ Đại!")
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
					prof.CoreShards = (prof.CoreShards or 0) + 300
					unlockTitle(p, prof, "core_gear_awakened", false)
					p:SetAttribute("RaceV4Unlocked", true)
					G.Notify(p, "HOÀN TẤT THỬ THÁCH THĂNG HOA! Đã mở khóa vĩnh viễn THĂNG HOA [" .. tostring(prof.Race) .. "] + 1 Core Gear + 300 Shards!")
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
				G.Notify(p, "Hết 60 giây Thử Thách Cổ Đại! Hãy kéo Cần Gạt Cổ Đại để thử lại.")
			end
		end
	end)
end

local function spawnNPCStation(folder, id, titleText, subText, rawPos, color, actionText, onTrigger)
	local fy = groundYAt(rawPos, rawPos.Y - 2)
	local base = Vector3.new(rawPos.X, fy, rawPos.Z)

	local m = Instance.new("Model")
	m.Name = "Station_" .. id

	local dais = Instance.new("Part")
	dais.Name = "Dais"
	dais.Shape = Enum.PartType.Cylinder
	dais.Size = Vector3.new(0.64, 4.6, 4.6)
	dais.CFrame = CFrame.new(base + Vector3.new(0, 0.32, 0)) * CFrame.Angles(0, 0, math.pi * 0.5)
	dais.Color = Color3.fromRGB(26, 34, 48)
	dais.Material = Enum.Material.Metal
	dais.Anchored = true
	dais.Parent = m

	local pillar = Instance.new("Part")
	pillar.Name = "BodyPillar"
	pillar.Size = Vector3.new(2.1, 4.2, 1.3)
	pillar.Position = base + Vector3.new(0, 2.55, 0)
	pillar.Color = color
	pillar.Material = Enum.Material.SmoothPlastic
	pillar.Anchored = true
	pillar.Parent = m

	local crest = Instance.new("Part")
	crest.Name = "HoloCrest"
	crest.Shape = Enum.PartType.Ball
	crest.Size = Vector3.new(1.35, 1.35, 1.35)
	crest.Position = base + Vector3.new(0, 5.3, 0)
	crest.Color = color
	crest.Material = Enum.Material.Neon
	crest.Anchored = true
	crest.CanCollide = false
	crest.Parent = m

	local bill = Instance.new("BillboardGui")
	bill.Size = UDim2.fromOffset(230, 44)
	bill.StudsOffset = Vector3.new(0, 2.6, 0)
	bill.MaxDistance = 70
	bill.LightInfluence = 0
	bill.Parent = crest

	local l1 = Instance.new("TextLabel")
	l1.Size = UDim2.new(1, 0, 0, 22)
	l1.BackgroundTransparency = 1
	l1.Font = Enum.Font.GothamBlack
	l1.TextSize = 13
	l1.TextColor3 = color
	l1.TextStrokeTransparency = 0.2
	l1.Text = titleText
	l1.Parent = bill

	local l2 = Instance.new("TextLabel")
	l2.Size = UDim2.new(1, 0, 0, 18)
	l2.Position = UDim2.fromOffset(0, 22)
	l2.BackgroundTransparency = 1
	l2.Font = Enum.Font.GothamMedium
	l2.TextSize = 11
	l2.TextColor3 = Color3.fromRGB(224, 234, 248)
	l2.TextStrokeTransparency = 0.25
	l2.Text = subText
	l2.Parent = bill

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = titleText
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = pillar

	prompt.Triggered:Connect(function(plr)
		if onTrigger then
			onTrigger(plr, base)
		end
	end)

	m.PrimaryPart = pillar
	m.Parent = folder
	return m
end

local function buildWorldNPCsAndAltars()
	local npcFolder = ensureWorldFolder("InteractiveNPCs")
	npcFolder:ClearAllChildren()

	local skyPos = C.Spawn or Vector3.new(-317.4, 50.5, 527.8)
	local cafePos = (C.FastTravel and C.FastTravel.CyberportCafe and C.FastTravel.CyberportCafe.Pos) or Vector3.new(9400, 50.9, 1785)
	local templePos = (C.FastTravel and C.FastTravel.TempleOfTheCore and C.FastTravel.TempleOfTheCore.Pos) or Vector3.new(-14600, 50.9, -1785)

	-- 1. Five Martial Arts Masters (#31)
	for _, sid in ipairs(CombatData.StyleOrder) do
		local st = CombatData.MartialStyles[sid]
		local anchor = skyPos
		if st.IslandId == "CyberportCafe" then
			anchor = cafePos
		elseif st.IslandId == "TempleOfTheCore" then
			anchor = templePos
		end
		local priceTag = (st.PriceGold == 0) and "Miễn Phí" or string.format("%s Gold + %d Shards", formatBountyShort(st.PriceGold), st.PriceShards)
		spawnNPCStation(
			npcFolder,
			st.MasterNPC,
			st.MasterName,
			st.Name .. " (" .. priceTag .. ")",
			anchor + st.MasterOffset,
			st.Color,
			"Mở Võ Đường 3D • " .. st.Name,
			function(plr)
				G.SendDialogue(
					plr,
					st.MasterName,
					"ĐẠI SƯ VÕ ĐẠO • MARTIAL DOJO",
					"Ta truyền dạy [" .. st.Name .. "] cùng 7 tuyệt kỹ Thần Quyền 3 Tầng Trời! Hãy mở Võ Đường 3D để lĩnh ngộ hoặc chuyển đổi võ phái.",
					"Mở Võ Đường 3D",
					"OpenScreen:NPCShop:MartialDojo"
				)
			end
		)
	end

	-- 2. Phantom Core Stock Dealers at Sky Hub & Trade Station (#43)
	for idx, anchor in ipairs({ skyPos + Vector3.new(32, 0, -24), cafePos + Vector3.new(-24, 0, 6) }) do
		spawnNPCStation(
			npcFolder,
			"MirageDealer_" .. tostring(idx),
			"Thương Nhân Hư Quang",
			"Xoay vòng mỗi giờ - Mua trực tiếp bằng Gold",
			anchor,
			Color3.fromRGB(255, 198, 78),
			"Xem & Mua Kho Lõi Hư Quang",
			function(plr)
				refreshMirageStock()
				G.SendDialogue(
					plr,
					"Thương Nhân Hư Quang",
					"THƯƠNG NHÂN ĐẢO HƯ QUANG",
					"Kho Lõi Aether Hư Quang xoay vòng mỗi giờ với tỉ lệ xuất hiện Lõi Thần Thoại gấp đôi! Hãy mở Cửa Hàng Hư Quang 3D để chọn mua trực tiếp bằng Gold.",
					"Mở Kho Lõi Hư Quang",
					"OpenScreen:NPCShop:MirageDealer"
				)
			end
		)
	end

	-- 3. Dr. Vega Race Reroll NPC at Sky Hub & Trade Station (#59)
	for idx, anchor in ipairs({ skyPos + Vector3.new(42, 0, -18), cafePos + Vector3.new(24, 0, 6) }) do
		spawnNPCStation(
			npcFolder,
			"DrVega_" .. tostring(idx),
			"Dr. Vega - Nhà Khoa Học Tộc Hệ",
			"Tái Cấu Trúc Huyết Mạch (50 Core Shards) & Thăng Hoa",
			anchor,
			Color3.fromRGB(112, 242, 195),
			"Mở Viện Nghiên Cứu Tộc Hệ & Thăng Hoa",
			function(plr)
				G.SendDialogue(
					plr,
					"Dr. Vega - Nhà Khoa Học Tộc Hệ",
					"VIỆN NGHIÊN CỨU HUYẾT MẠCH & THĂNG HOA",
					"Ta tái cấu trúc huyết mạch sang 6 Tộc Hệ Thượng Cổ và kết nối Đền Thăng Hoa!",
					"Mở Phòng Nghiên Cứu Thăng Hoa",
					"OpenScreen:NPCShop:DrVegaAndTempleV4"
				)
			end
		)
	end

	-- 4. Ascension Shrine Ancient Gear Altar & Trial Lever (#51)
	Expansion.StartTempleRaceV4Trial = startTempleRaceV4Trial
	spawnNPCStation(
		npcFolder,
		"AncientGearTrialLever",
		"Ancient Gear Altar & Trial Lever",
		"Đền Thăng Hoa - Thử Thách Thăng Hoa (60s)",
		templePos + Vector3.new(0, 0, -12),
		Color3.fromRGB(255, 178, 72),
		"Mở Đền Thăng Hoa & Thử Thách (60s)",
		function(plr)
			G.SendDialogue(
				plr,
				"Đài Bánh Răng Cổ Đại",
				"THÁNH ĐIỆN ĐỀN THĂNG HOA • ASCENSION SHRINE",
				"Cần Gạt Cổ Đại mở khóa Thử Thách Thăng Hoa (60 giây) và nâng cấp Core Gear! Hãy mở Bảng Đền Thăng Hoa để bắt đầu thử thách.",
				"Mở Thử Thách Đền Thăng Hoa",
				"OpenScreen:NPCShop:DrVegaAndTempleV4"
			)
		end
	)
end

-- ============================================================================
-- 10M BOUNTY ALLIED SKY BEAST GUARDIAN SUMMON (#57)
-- ============================================================================
function Expansion.SummonAlliedSeaBeast(p)
	local profile = D.Get(p)
	local rt = G.Runtime[p]
	local hrp = getCharRoot(p)
	if not profile or not rt or not hrp then
		return false
	end
	ensureExpansionProfile(profile)

	if (profile.Bounty or 0) < CombatData.SeaBeastSummonBounty and p:GetAttribute("BypassBountyLock") ~= true then
		G.Notify(p, string.format("Cần đạt >= 10,000,000 Bounty để Triệu Hồi Thú Trời Hộ Vệ (Hiện tại: %s)!", formatBountyShort(profile.Bounty)))
		return false
	end

	local existing = AlliedSeaBeasts[p]
	if existing and existing.Model and existing.Model.Parent then
		existing.Model:Destroy()
		AlliedSeaBeasts[p] = nil
		G.Notify(p, "Đã thu hồi Thú Trời Hộ Vệ (Sky Beast Guardian).")
		return true
	end

	local now = os.clock()
	if now < (rt.Cooldowns.SummonSeaBeast or 0) then
		G.Notify(p, string.format("Triệu Hồi Thú Trời đang hồi (%ds)!", math.ceil(rt.Cooldowns.SummonSeaBeast - now)))
		return false
	end
	rt.Cooldowns.SummonSeaBeast = now + 45

	local beastFolder = ensureWorldFolder("AlliedSeaBeasts")
	local m = Instance.new("Model")
	m.Name = "AlliedSkySeaBeast_" .. p.Name

	local spawnPos = hrp.Position + Vector3.new(12, 5.5, 10)
	local body = Instance.new("Part")
	body.Name = "BeastCore"
	body.Size = Vector3.new(6.2, 11.5, 6.2)
	body.Position = spawnPos
	body.Color = Color3.fromRGB(36, 138, 205)
	body.Material = Enum.Material.Metal
	body.Anchored = true
	body.CanCollide = false
	body.Parent = m

	local head = Instance.new("Part")
	head.Name = "BeastHead"
	head.Size = Vector3.new(6.8, 5.2, 8.2)
	head.Position = spawnPos + Vector3.new(0, 6.5, -2.5)
	head.Color = Color3.fromRGB(72, 224, 255)
	head.Material = Enum.Material.Neon
	head.Anchored = true
	head.CanCollide = false
	head.Parent = m

	for idx = 1, 2 do
		local side = (idx == 1) and -1 or 1
		local crest = Instance.new("Part")
		crest.Name = "FinCrest_" .. tostring(idx)
		crest.Size = Vector3.new(1.1, 5.4, 2.4)
		crest.CFrame = CFrame.new(spawnPos + Vector3.new(side * 3.4, 8.4, -1.2)) * CFrame.Angles(-0.3, 0, side * 0.42)
		crest.Color = Color3.fromRGB(115, 245, 255)
		crest.Material = Enum.Material.Neon
		crest.Anchored = true
		crest.CanCollide = false
		crest.Parent = m
	end

	local bill = Instance.new("BillboardGui")
	bill.Size = UDim2.fromOffset(220, 36)
	bill.StudsOffset = Vector3.new(0, 5.0, 0)
	bill.MaxDistance = 95
	bill.LightInfluence = 0
	bill.Parent = head

	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamBlack
	tl.TextSize = 13
	tl.TextColor3 = Color3.fromRGB(95, 236, 255)
	tl.TextStrokeTransparency = 0.2
	tl.Text = "SKY BEAST GUARDIAN - " .. (p.DisplayName or p.Name)
	tl.Parent = bill

	m.PrimaryPart = body
	m.Parent = beastFolder
	Debris:AddItem(m, CombatData.SeaBeastDuration + 0.5)

	local rec = {
		Owner = p,
		Model = m,
		Body = body,
		Head = head,
		ExpiresAt = now + CombatData.SeaBeastDuration,
		NextBeamAt = now + 1.0,
	}
	AlliedSeaBeasts[p] = rec
	G.Notify(p, "TRIỆU HỒI THÚ TRỜI HỘ VỆ (35s): Bắn tia Hydro-Aether Beam 380% ATK mỗi 3.5s!")
	return true
end

local function tickAlliedSeaBeasts(dt)
	local now = os.clock()
	for p, rec in pairs(AlliedSeaBeasts) do
		if not p or not p.Parent or not rec.Model or not rec.Model.Parent or now >= rec.ExpiresAt then
			if rec.Model and rec.Model.Parent then
				rec.Model:Destroy()
			end
			AlliedSeaBeasts[p] = nil
		else
			local hrp = getCharRoot(p)
			if hrp then
				local bob = math.sin(now * 2.4) * 1.2
				local goal = hrp.Position + Vector3.new(11, 5.2 + bob, 9)
				local cur = rec.Body.Position
				local nextPos = cur:Lerp(goal, math.min(1, dt * 5))
				local nearest, bestDist = nil, 90
				for _, e in ipairs(G.Enemies or {}) do
					if e.Alive and e.Body then
						local d = (e.Body.Position - hrp.Position).Magnitude
						if d < bestDist then
							bestDist = d
							nearest = e
						end
					end
				end
				local lookTarget = (nearest and nearest.Body and nearest.Body.Position) or (nextPos + hrp.CFrame.LookVector * 12)
				local cf = CFrame.lookAt(nextPos, Vector3.new(lookTarget.X, nextPos.Y, lookTarget.Z))
				rec.Model:PivotTo(cf)

				if nearest and now >= rec.NextBeamAt then
					rec.NextBeamAt = now + CombatData.SeaBeastBeamInterval
					local st = G.Stats(p)
					local beamDmg = ((st and st.ATK) or 60) * CombatData.SeaBeastBeamAtkMultiplier
					local impactPos = nearest.Body.Position
					for _, e in ipairs(G.Enemies or {}) do
						if e.Alive and e.Body and (e.Body.Position - impactPos).Magnitude <= 20 then
							G.Hit(p, e, beamDmg, 24, "SkySeaBeastHydroBeam")
						end
					end
					if R and R.CombatFX then
						R.CombatFX:FireAllClients({
							Kind = "SeaBeastBeam",
							Origin = rec.Head.Position,
							EndPos = impactPos,
							Position = impactPos,
							Radius = 20,
							Owner = p.UserId,
						})
					end
				end
			end
		end
	end
end

-- ============================================================================
-- WAVE 1 AUTHORITATIVE UI HANDLERS (#100 GIFTCODES, #104 STARS, #60 PRESETS)
-- ============================================================================
function Expansion.RefundAllStats(p, silent)
	local profile = D.Get(p)
	if not profile then
		return 0
	end
	ensureExpansionProfile(profile)
	profile.StatAlloc = type(profile.StatAlloc) == "table" and profile.StatAlloc or { Melee = 1, Defense = 1, Sword = 1, Gun = 1, Fruit = 1 }
	local refunded = 0
	for k, v in pairs(profile.StatAlloc) do
		local n = math.floor(tonumber(v) or 1)
		if n > 1 then
			refunded += (n - 1)
			profile.StatAlloc[k] = 1
		end
	end
	profile.StatPoints = (tonumber(profile.StatPoints) or 0) + refunded
	if not silent then
		G.Notify(p, string.format("Đã hoàn trả toàn bộ chỉ số! Tổng Stat Points khả dụng: %d", profile.StatPoints))
	end
	return refunded
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
	if tonumber(spec.Expires) and os.time() > tonumber(spec.Expires) then
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

	profile.RedeemedCodes[cleaned] = true
	if spec.Gold then
		profile.Gold = (profile.Gold or 0) + spec.Gold
	end
	if spec.CoreShards then
		profile.CoreShards = (profile.CoreShards or 0) + spec.CoreShards
	end
	if spec.DoubleExpSeconds then
		local baseTime = math.max(os.time(), tonumber(profile.DoubleExpUntil) or 0)
		profile.DoubleExpUntil = baseTime + spec.DoubleExpSeconds
	end
	if spec.StoredFruit then
		profile.StoredFruits[spec.StoredFruit] = (profile.StoredFruits[spec.StoredFruit] or 0) + 1
	end
	if spec.FreeFruitVouchers then
		profile.FreeFruitVouchers = (profile.FreeFruitVouchers or 0) + spec.FreeFruitVouchers
	end
	if spec.FreeStatRefund then
		Expansion.RefundAllStats(p, true)
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

	local target = type(statsTable) == "table" and statsTable or profile.StatPresets[tostring(slot)] or profile.StatPresets[slot]
	if type(target) ~= "table" then
		-- Smart default build presets 1..3 when slot has no saved custom table yet
		local totalPool = (tonumber(profile.StatPoints) or 0)
		for _, v in pairs(profile.StatAlloc or {}) do
			totalPool += math.max(0, (tonumber(v) or 1) - 1)
		end
		local half = math.floor(totalPool * 0.40)
		local fifth = math.floor(totalPool * 0.20)
		if slot == 1 then
			target = { Melee = fifth, Defense = half, Fruit = totalPool - half - fifth, Sword = 0, Gun = 0 }
		elseif slot == 2 then
			target = { Melee = fifth, Defense = half, Sword = totalPool - half - fifth, Fruit = 0, Gun = 0 }
		else
			target = { Melee = fifth, Defense = half, Gun = totalPool - half - fifth, Sword = 0, Fruit = 0 }
		end
	end

	Expansion.RefundAllStats(p, true)
	local maxSt = (C and C.MaxStat) or 2550
	for _, key in ipairs({ "Melee", "Defense", "Sword", "Gun", "Fruit" }) do
		local rawWant = tonumber(target[key]) or 0
		-- Support either additive points (0..2549) or absolute stat level (1..2550)
		local addPts = rawWant
		if target._isAbsolute then
			addPts = math.max(0, rawWant - 1)
		end
		addPts = math.clamp(math.floor(addPts), 0, math.min(maxSt - 1, profile.StatPoints or 0))
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
	local id = tostring(rawIslandId or "SkyHub")
	if (G.Boss and G.Boss.Party and G.Boss.Party[p])
		or PlayerTradeMap[p] ~= nil
		or TrialSessions[p] ~= nil
		or p:GetAttribute("RaidActive") == true
		or p:GetAttribute("ColosseumActive") == true
		or p:GetAttribute("InColosseum") == true
		or p:GetAttribute("InColosseumDuel") == true then
		G.Notify(p, "Không thể dịch chuyển khi đang trong Đấu Trường, Giao Dịch, Raid hoặc Thử Thách!")
		return false
	end

	local isl = (C.FastTravel and C.FastTravel[id]) or (not tonumber(id) and C.Islands and C.Islands[id])
	if not isl then
		for k, v in pairs(C.FastTravel or {}) do
			if type(k) == "string" and string.lower(k) == string.lower(id) then
				id = tostring((type(v) == "table" and v.Id) or k)
				isl = v
				break
			end
		end
	end
	if not isl and C and C.Islands then
		for _, v in ipairs(C.Islands) do
			if type(v) == "table" and type(v.Id) == "string" and string.lower(v.Id) == string.lower(id) then
				id = v.Id
				isl = v
				break
			end
		end
	end
	if not isl then
		return false
	end

	local canonId = (type(isl.Id) == "string" and isl.Id ~= "" and isl.Id) or id
	local pos = isl.Pos or isl.Spawn or C.Spawn
	local realm = isl.Realm or "GoldenSky"
	profile.UnlockedWorlds = profile.UnlockedWorlds or {}
	local realmMinLv = ({
		FrozenCyber = 700,
		ShadowRealm = 1500,
		VerdantCrown = 2200,
		EmberforgeWastes = 2270,
		AbyssalTides = 2340,
		ChronosBastion = 2410,
		VeilsEnd = 2480,
	})[realm] or 1
	if realm ~= "GoldenSky" and realm ~= "SkyHub"
		and not profile.UnlockedWorlds[realm]
		and not profile.UnlockedWorlds[canonId]
		and not DevGate.IsAllowed(p)
		and (tonumber(profile.Level) or 1) < realmMinLv then
		G.Notify(p, string.format("Cần đạt Level %d để mở khóa dịch chuyển tới %s!", realmMinLv, isl.Name or realm))
		return false
	end
	if type(realm) == "string" and realm ~= "" then
		profile.UnlockedWorlds[realm] = true
	end
	if type(canonId) == "string" and canonId ~= "" and not tonumber(canonId) then
		profile.UnlockedWorlds[canonId] = true
	end
	rt.JumpPadUntil = os.clock() + 3.0
	p:SetAttribute("CurrentRealm", realm)
	G.Teleport(p, pos + Vector3.new(0, 3, 0))
	G.Notify(p, "Dịch chuyển nhanh -> " .. (isl.Name or canonId) .. "!")
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

function Expansion.EquipHakiColor(p, rawColorId)
	local profile = D.Get(p)
	if not profile then
		return false
	end
	ensureExpansionProfile(profile)
	local cid = tostring(rawColorId or "crimson_conqueror")
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
		if PlayerTradeMap[p] ~= nil or p:GetAttribute("InTrade") == true then
			return
		end
		local rt = G.Runtime[p]
		local profile = D.Get(p)
		local hrp, hum = getCharRoot(p)
		local cid = CombatData.ResolveFruitId(fid)
		if rt and profile and hrp and hum and hum.Health > 0 and CombatData.FruitCatalog[cid] then
			local now = os.clock()
			if now < (rt.NextWildFruitClaimAt or 0) then
				return
			end
			local validSource = false
			local matchedDrop = nil
			local dropFolder = workspace:FindFirstChild("DroppedDevilFruits") or (workspace:FindFirstChild("WorldObjects") and workspace.WorldObjects:FindFirstChild("DroppedDevilFruits"))
			if dropFolder then
				for _, m in ipairs(dropFolder:GetChildren()) do
					if m:GetAttribute("FruitId") == cid then
						local pp = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
						if pp and (pp.Position - hrp.Position).Magnitude <= 25 then
							validSource = true
							matchedDrop = m
							break
						end
					end
				end
			end
			if not validSource then
				for _, tp in ipairs({ Vector3.new(105, 46.5, 58), Vector3.new(12095, 46.9, 65), Vector3.new(-11892, 46.9, 165) }) do
					if Vector3.new(hrp.Position.X - tp.X, 0, hrp.Position.Z - tp.Z).Magnitude <= 45 then
						validSource = true
						break
					end
				end
			end
			if not validSource then
				return
			end
			if matchedDrop and matchedDrop.Parent then
				matchedDrop:Destroy()
			end
			rt.NextWildFruitClaimAt = now + 22
			ensureExpansionProfile(profile)
			profile.StoredFruits[cid] = (profile.StoredFruits[cid] or 0) + 1
			profile.HeldFruit = cid
			p:SetAttribute("HeldFruit", cid)
			if p.Character then
				p.Character:SetAttribute("HeldFruit", cid)
			end
			G.Notify(p, "Đã thu thập Lõi Aether Tự Nhiên: [" .. CombatData.FruitCatalog[cid].Name .. "] (Đã lưu kho & cầm trên tay 3D)!")
			G.Sync(p)
		end
	elseif act == "AwakenFruit" then
		local profile = D.Get(p)
		if profile then
			ensureExpansionProfile(profile)
			local cid = CombatData.ResolveFruitId(fid ~= "" and fid or profile.EquippedFruit)
			local cat = CombatData.FruitCatalog[cid]
			if cat then
				local cost = cat.AwakenShards or 500
				if not profile.AwakenedFruits[cid] then
					if (profile.CoreShards or 0) < cost then
						G.Notify(p, string.format("Cần %d Core Shards (hoặc hoàn thành Awakening Raid) để Thức Tỉnh V2 [%s]!", cost, cat.Name))
						return
					end
					profile.CoreShards -= cost
				end
				profile.AwakenedFruits[cid] = true
				unlockTitle(p, profile, "awakened_ascendant", false)
				G.Notify(p, "AWAKENED V2 MỞ KHÓA: [" .. cat.Name .. "] (+28%..42% DMG & Hiệu Ứng V2)!")
				G.Sync(p)
			end
		end
	elseif act == "PortalWarp" then
		executePortalMoveC(p, type(data) == "table" and data or { targetIslandId = fid })
	elseif act == "SummonSeaBeast" then
		Expansion.SummonAlliedSeaBeast(p)
	elseif act == "EatFruit" or act == "HoldFruit" or act == "RollFruit" then
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

	if cmd == "RedeemCode" then
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
		Expansion.RefundAllStats(p, false)
		G.Sync(p)
		return true
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
	elseif cmd == "EquipHakiColor" then
		return Expansion.EquipHakiColor(p, payload.colorId or payload.id or payload.value)
	elseif cmd == "RerollRace" then
		return Expansion.RerollRace(p)
	elseif cmd == "SummonSeaBeast" then
		return Expansion.SummonAlliedSeaBeast(p)
	elseif cmd == "DropHeldFruit" or cmd == "DropFruit" then
		return Expansion.DropHeldFruit(p, payload.fruitId or payload.id)
	elseif cmd == "AwakenFruit" then
		Expansion.HandleFruitAction(p, "AwakenFruit", payload)
		return true
	elseif cmd == "RollFruit" or cmd == "EatFruit" or cmd == "HoldFruit" then
		G.Equipment(p, { action = cmd, fruitId = CombatData.ResolveFruitId(payload.fruitId or payload.id or "") })
		return true
	end
	return false
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
	G.HandleUIRequest = Expansion.HandleUIRequest
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
		local expRem = math.max(0, (tonumber(profile.DoubleExpUntil) or 0) - os.time())

		p:SetAttribute("FightingStyle", styleId)
		p:SetAttribute("EquippedFruit", fid)
		p:SetAttribute("FruitMastery", fruitMastery)
		p:SetAttribute("FruitAwakened", fruitAwk)
		p:SetAttribute("Bounty", profile.Bounty or 0)
		p:SetAttribute("Title", (CombatData.Titles[profile.Title] or CombatData.Titles.sky_rookie).Name)
		p:SetAttribute("Race", profile.Race or "Skyborn")
		p:SetAttribute("RaceV4Unlocked", profile.RaceV4Unlocked == true)
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
			statePayload.CoreGears = profile.CoreGears or 0
			statePayload.DoubleExpSeconds = expRem
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
	G.Stats = function(p)
		local s = origStats(p)
		local profile = D.Get(p)
		local rt = G.Runtime[p]
		if not s or not profile then
			return s
		end
		ensureExpansionProfile(profile)

		-- Adjust Busoshoku Haki from flat 1.20/1.15 to authoritative Stage 0..5 (up to +22% ATK, +18% DEF at Stage 5)
		if p.Character and p.Character:GetAttribute("HakiAura") then
			local stInfo = CombatData.HakiStages[profile.HakiStage or 0] or CombatData.HakiStages[0]
			s.ATK = math.floor((s.ATK / 1.20) * (1 + stInfo.AtkBonus))
			s.DEF = math.floor((s.DEF / 1.15) * (1 + stInfo.DefBonus))
			s.Break = (s.Break or 100) + (stInfo.BreakBonus or 0)
		end

		-- Bounty Prestige Combat Buff (+1% ATK & +1% DEF per 1.5M up to +20% at 30M) (#56)
		local bountyPct = CombatData.GetBountyBuffPct(profile.Bounty)
		if bountyPct > 0 then
			s.ATK = math.floor(s.ATK * (1 + bountyPct))
			s.DEF = math.floor(s.DEF * (1 + bountyPct))
		end

		-- Weapon Star Ascension (1..5 Stars) (#104)
		local activeWep = (profile.ActiveSlot == 4 and profile.EquippedGun) or profile.Weapon
		local starLv = activeWep and tonumber(profile.WeaponStars[activeWep]) or 0
		if starLv and starLv >= 1 and CombatData.StarAscension[starLv] then
			local tier = CombatData.StarAscension[starLv]
			s.ATK = math.floor(s.ATK * (1 + tier.AtkPct))
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

		-- Apply WalkSpeed modifiers (Mink V4 +45%, Skyborn V4 +28%, Dragon Hybrid +22% / Sovereign +32%)
		local _, hum = getCharRoot(p)
		if hum then
			local baseSpd = (C.Classes and C.Classes[profile.ClassId] and C.Classes[profile.ClassId].Speed) or 18
			local spdMult = 1.0
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
			hum.WalkSpeed = math.clamp(baseSpd * spdMult, 16, 46)
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
				local activeWep = (profile.ActiveSlot == 4 and profile.EquippedGun) or profile.Weapon
				local starLv = activeWep and tonumber(profile.WeaponStars[activeWep]) or 0
				local starTier = starLv and CombatData.StarAscension[starLv]
				if starTier and (starTier.SkillDmgPct or 0) > 0 then
					mult *= (1 + starTier.SkillDmgPct)
				end
			end
		end

		local preHP = e.HP or 0
		local preBreak = e.Break or 0
		origHit(p, e, (tonumber(damage) or 1) * mult, 0, action)
		local dealt = math.max(0, preHP - (e.HP or 0))

		-- Authoritative Boss Break Gauge (#16)
		local extraBreak = (tonumber(breakPower) or 0)
		if profile and profile.Haki and profile.Haki.Aura then
			local stInfo = CombatData.HakiStages[profile.HakiStage or 0]
			extraBreak += (stInfo and stInfo.BreakBonus or 3)
			addBusoHakiEXP(p, 3)
		end
		e.Break = preBreak
		updateBossBreakGauge(e, extraBreak)

		if rt and dealt > 0 then
			ensureRuntimeFields(p, rt, profile)
			if (rt.DragonFormTier or 0) == 0 then
				rt.FuryMeter = math.min(100, (rt.FuryMeter or 0) + 2.8)
			end
			if profile and not profile.RaceV4Active then
				profile.AwakeningMeter = math.min(100, (tonumber(profile.AwakeningMeter) or 0) + 3.5)
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
					rt.Energy = math.min(100, (rt.Energy or 0) + CombatData.RaceV4Passives.Cyborg.EnergyRefundPerChain)
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

		-- #45: 100% Authoritative Logia Elemental Reflex when playerLevel >= enemyLevel + 15 & non-Boss & lacks HasBusoHaki
		local fid = CombatData.ResolveFruitId(profile.EquippedFruit)
		local cat = CombatData.FruitCatalog[fid]
		if cat and cat.Logia and attackerEnemy and not isBossEnemy(attackerEnemy) then
			local enemyHasHaki = (attackerEnemy.Config and attackerEnemy.Config.HasBusoHaki == true)
				or (attackerEnemy.Model and attackerEnemy.Model:GetAttribute("HasBusoHaki") == true)
			local enemyLv = (attackerEnemy.Config and attackerEnemy.Config.Level) or 1
			if not enemyHasHaki and (tonumber(profile.Level) or 1) >= (enemyLv + 15) then
				if R and R.CombatFX then
					R.CombatFX:FireAllClients({
						Kind = "DamageNumber",
						Position = hrp.Position + Vector3.new(0, 2.6, 0),
						Amount = 0,
						IsImmune = true,
						Tag = "LOGIA!",
						Text = "LOGIA!",
						Element = cat.Element,
						Target = p.Character,
					})
				end
				G.FireCombatEvent({
					kind = "DamageNumber",
					pos = hrp.Position + Vector3.new(0, 2.6, 0),
					amount = 0,
					crit = false,
					element = cat.Element,
					Text = "LOGIA!",
				})
				return
			end
		end

		-- #54: Track Kenbunshoku dodge EXP toward V2 unlock
		local preDodges = profile.Haki and profile.Haki.InstinctDodges or 0

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

		rt.FuryMeter = math.min(100, (rt.FuryMeter or 0) + 3.2)
		origPlayerDamage(p, incoming, attackerEnemy)

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

	-- 7. Wrap G.Action & G.UseSlotMove for 5 Martial Styles, Greatsword Crescent Slash, Guns, V2 Fruits, Dragon Fury & Portal Warp
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
		elseif (act == "Attack" or act == "Heavy" or act == "Shoot") and slot == 4 then
			executeAimedGunShot(p, nil, payload)
			return
		elseif (act == "Heavy" or act == "ChargeHeavy" or act == "ChargedSlash") and slot == 3 and CombatData.IsChargedSlashWeapon(profile.Weapon) then
			if executeChargedCrescentSlash(p, payload) then
				return
			end
		end
		return origAction(p, act)
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

		-- Slot 1: 5 Martial Arts Styles [Z][X][C] (#31-#33)
		if slot == 1 and (key == "Z" or key == "X" or key == "C") then
			if executeMartialStyleTechnique(p, key, payload) then
				return
			end
		end

		-- Slot 3: Charged [Z] on Noxar Greatsword when ChargeRatio is supplied (#35)
		if slot == 3 and key == "Z" and type(payload) == "table" and (payload.ChargeRatio or payload.chargeRatio) and CombatData.IsChargedSlashWeapon(profile.Weapon) then
			if executeChargedCrescentSlash(p, payload) then
				return
			end
		end

		-- Slot 4: Aimed Raycast Gunplay [Z][X][C][V] (#36-#38)
		if slot == 4 and (key == "Z" or key == "X" or key == "C" or key == "V") then
			if executeAimedGunShot(p, key, payload) then
				return
			end
		end

		-- Slot 2: Devil Fruit Mastery Gate (#41), Portal [C] Warp (#49), Dragon Fury [V] (#48), Awakened V2 (#42)
		if slot == 2 then
			local fid = CombatData.ResolveFruitId(profile.EquippedFruit)
			if fid ~= "" then
				profile.EquippedFruit = fid
				if fid == "DimensionalPortalCore" and key == "C" then
					executePortalMoveC(p, payload)
					return
				end
				local cat = CombatData.FruitCatalog[fid]
				if cat and cat.DragonFury and key == "V" then
					executeDragonFuryMoveV(p, fid)
					return
				end
				if not checkMoveMasteryUnlock(p, profile, fid, key, 2) then
					return
				end
				if key == "F" then
					local mLv = getMasteryLevel(profile, fid)
					local boost = (mLv >= CombatData.MasteryConfig.FlightEnhancedLevel) and 1.35 or 1.0
					rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, os.clock() + 3.0 * boost)
				end
				if executeAwakenedFruitV2Move(p, fid, key, payload) then
					return
				end
				addMasteryXP(p, fid, 16)
			end
		else
			local discId = getActiveDisciplineId(profile, slot)
			if not checkMoveMasteryUnlock(p, profile, discId, key, slot) then
				return
			end
			addMasteryXP(p, discId, 14)
		end

		return origUseSlotMove(p, key)
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
			or act == "ApplyStatPreset" or act == "SaveStatPreset" or act == "BuyMirageFruit"
			or act == "SelectFightingStyle" or act == "SwitchFightingStyle" or act == "LearnFightingStyle"
			or act == "EquipTitle" or act == "EquipHakiColor" or act == "RerollRace"
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
				if not prof.RaceV4Unlocked and (tonumber(prof.Level) or 1) < 1500 then
					G.Notify(p, "Hãy vượt qua Thử Thách Thăng Hoa tại Đền Thăng Hoa (Tầng Trời 3) để mở khóa THĂNG HOA!")
					return
				end
				if not prof.RaceV4Active then
					if (tonumber(prof.AwakeningMeter) or 0) < 25 then
						G.Notify(p, string.format("Cần tối thiểu 25%% Thanh Thức Tỉnh để kích hoạt THĂNG HOA (Hiện tại: %d%%)!", math.floor(prof.AwakeningMeter or 0)))
						return
					end
					if rt then
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
		elseif idOrAction == "DrVega" then
			Expansion.RerollRace(p)
			return
		elseif idOrAction == "MirageDealer" then
			local stock = refreshMirageStock()
			if stock.Items[1] then
				Expansion.BuyMirageFruit(p, stock.Items[1].Id, false)
			end
			return
		end
		return origInteract(p, idOrAction)
	end

	G.HandleAbilityExtra = function(p, payload)
		local id = tostring(payload.skillId or payload.action or "")
		if id == "FreeFlight" then
			local isFlying = (payload.active == true)
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
			if not RemoteGuard.Allow(p, "UI") then
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
		LastWaterPadPos[p] = nil
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
		if AlliedSeaBeasts[p] then
			if AlliedSeaBeasts[p].Model and AlliedSeaBeasts[p].Model.Parent then
				AlliedSeaBeasts[p].Model:Destroy()
			end
			AlliedSeaBeasts[p] = nil
		end
	end)

	-- Build 3D World Tables, NPCs, Trial Altar & Sea Water Basins
	refreshMirageStock()
	pcall(buildCafeTradingTables)
	pcall(buildWorldNPCsAndAltars)
	pcall(buildDockSeaWaterBasins)

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

			tickAlliedSeaBeasts(dt)

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
