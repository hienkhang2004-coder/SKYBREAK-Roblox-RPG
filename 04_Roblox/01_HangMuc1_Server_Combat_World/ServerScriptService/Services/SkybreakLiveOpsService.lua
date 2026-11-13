-- SKYBREAK: Fragments of the Core — Public-Launch LiveOps, Compliance, Badges, Playtime Gifts, Friend Boost & Cross-Server Leaderboards
-- Location: ServerScriptService/Services/SkybreakLiveOpsService.lua

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local PolicyService = game:GetService("PolicyService")
local BadgeService = game:GetService("BadgeService")
local DataStoreService = game:GetService("DataStoreService")

local C = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local BadgeConfig = nil
pcall(function()
	local skyShared = ReplicatedStorage:FindFirstChild("SkybreakShared") or ReplicatedStorage:WaitForChild("SkybreakShared", 5)
	local mod = skyShared and skyShared:FindFirstChild("BadgeConfig")
	if mod and mod:IsA("ModuleScript") then
		BadgeConfig = require(mod)
	end
end)

local LiveOps = {}

local policyCache = {}      -- [userId] = boolean (ArePaidRandomItemsRestricted)
local sessionState = {}     -- [Player] = { JoinClock = number, Claimed = {[1..6]=bool} }
local friendBoostPct = {}   -- [Player] = 0 | 5 | 10 | 15
local nameCache = {}        -- [userId] = string
local odsStores = {}        -- [category] = OrderedDataStore
local odsCache = {          -- [category] = { UpdatedAt = number, Rows = {}, Fetching = bool }
	Level = { UpdatedAt = 0, Rows = {}, Fetching = false },
	Renown = { UpdatedAt = 0, Rows = {}, Fetching = false },
	BossDPS = { UpdatedAt = 0, Rows = {}, Fetching = false },
}
local lastOdsWrite = {}     -- [key] = { Clock = number, Score = number }
local liveG = nil
local started = false

local PLAYTIME_TIERS = {
	{
		Index = 1,
		Minutes = 5,
		RequiredSec = 300,
		Seconds = 300,
		RewardType = "Gold",
		Amount = 15000,
		Icon = "Coin",
		Rarity = "Common",
		TitleVi = "5 Phút",
		TitleEn = "5 Min",
		LabelVi = "+15,000 Vàng",
		LabelEn = "+15,000 Gold",
	},
	{
		Index = 2,
		Minutes = 10,
		RequiredSec = 600,
		Seconds = 600,
		RewardType = "Shards",
		Amount = 75,
		Icon = "Core",
		Rarity = "Uncommon",
		TitleVi = "10 Phút",
		TitleEn = "10 Min",
		LabelVi = "+75 Tinh Thạch",
		LabelEn = "+75 Core Shards",
	},
	{
		Index = 3,
		Minutes = 20,
		RequiredSec = 1200,
		Seconds = 1200,
		RewardType = "DoubleExp",
		Amount = 900,
		Icon = "Bolt",
		Rarity = "Rare",
		TitleVi = "20 Phút",
		TitleEn = "20 Min",
		LabelVi = "+15 Phút x2 EXP",
		LabelEn = "+15m 2x EXP",
	},
	{
		Index = 4,
		Minutes = 30,
		RequiredSec = 1800,
		Seconds = 1800,
		RewardType = "ScrollAndShards",
		Amount = 1,
		ShardsBonus = 100,
		Icon = "Star",
		Rarity = "Epic",
		TitleVi = "30 Phút",
		TitleEn = "30 Min",
		LabelVi = "+1 Bùa Cổ Ngữ & +100 Tinh Thạch",
		LabelEn = "+1 Rune Scroll & +100 Shards",
	},
	{
		Index = 5,
		Minutes = 45,
		RequiredSec = 2700,
		Seconds = 2700,
		RewardType = "CoreVoucher",
		Amount = 1,
		Icon = "Fruit",
		Rarity = "Legendary",
		TitleVi = "45 Phút",
		TitleEn = "45 Min",
		LabelVi = "+1 Vé Quay Lõi Miễn Phí",
		LabelEn = "+1 Free Core Spin Voucher",
	},
	{
		Index = 6,
		Minutes = 60,
		RequiredSec = 3600,
		Seconds = 3600,
		RewardType = "RarePlusCore",
		Amount = 1,
		ShardsBonus = 200,
		Icon = "Crown",
		Rarity = "Mythic",
		TitleVi = "60 Phút",
		TitleEn = "60 Min",
		LabelVi = "Lõi Aether Hiếm+ & +200 Tinh Thạch",
		LabelEn = "Rare+ Aether Core & +200 Shards",
	},
}
LiveOps.PlaytimeTiers = PLAYTIME_TIERS

local ODS_NAMES = {
	Level = "SKYBREAK_ODS_Level_v1",
	Renown = "SKYBREAK_ODS_Renown_v1",
	BossDPS = "SKYBREAK_ODS_BossDPS_v1",
}

local function persistenceEnabled()
	if RunService:IsStudio() and not C.StudioPersistence then
		return false
	end
	return true
end

-- ============================================================================
-- 1. LOCALE & BILINGUAL SERVER NOTIFICATIONS
-- ============================================================================
function LiveOps.SetPlayerLocale(player, rawLang)
	if not player then
		return "en"
	end
	local s = string.lower(tostring(rawLang or ""))
	local lang = (string.sub(s, 1, 2) == "vi") and "vi" or "en"
	pcall(function()
		player:SetAttribute("Locale", lang)
		player:SetAttribute("Language", lang)
	end)
	return lang
end

function LiveOps.GetLang(player)
	if player then
		local okAttr, attr = pcall(function()
			local loc = player:GetAttribute("Locale")
			if type(loc) == "string" and loc ~= "" then
				return loc
			end
			return player:GetAttribute("Language")
		end)
		if okAttr and type(attr) == "string" and attr ~= "" then
			return (string.sub(string.lower(attr), 1, 2) == "vi") and "vi" or "en"
		end
		local okLoc, locId = pcall(function()
			return player.LocaleId
		end)
		if okLoc and type(locId) == "string" and locId ~= "" then
			local low = string.lower(locId)
			if string.sub(low, 1, 2) == "vi" then
				return "vi"
			end
			return "en"
		end
	end
	return "en"
end

function LiveOps.Pick(player, viText, enText)
	if LiveOps.GetLang(player) == "en" then
		return tostring(enText or viText or "")
	end
	return tostring(viText or enText or "")
end

function LiveOps.Notify(G, player, viText, enText)
	if G and G.Notify and player then
		G.Notify(player, LiveOps.Pick(player, viText, enText))
	end
end

function LiveOps.Broadcast(G, viText, enText)
	if not (G and G.Notify) then
		return
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		G.Notify(plr, LiveOps.Pick(plr, viText, enText))
	end
end

-- ============================================================================
-- 2. TEXTSERVICE BROADCAST MODERATION (CREW NAME / CREW TAG)
-- ============================================================================
function LiveOps.FilterBroadcastText(player, rawText, maxLen)
	if not player or type(rawText) ~= "string" then
		return false, nil
	end
	local limit = math.clamp(math.floor(tonumber(maxLen) or 24), 2, 60)
	local cleaned = rawText:gsub("[%c]", " "):gsub("%s+", " "):match("^%s*(.-)%s*$") or ""
	if #cleaned < 2 then
		return false, nil
	end
	if #cleaned > limit then
		cleaned = string.sub(cleaned, 1, limit)
	end
	local ok, filtered = pcall(function()
		local result = TextService:FilterStringAsync(cleaned, player.UserId, Enum.TextFilterContext.PublicChat)
		return result:GetNonChatStringForBroadcastAsync()
	end)
	if ok and type(filtered) == "string" then
		local trimmed = filtered:match("^%s*(.-)%s*$") or ""
		if trimmed == "" or trimmed:match("^#+$") then
			return false, nil
		end
		return true, trimmed
	end
	if RunService:IsStudio() then
		-- Studio offline fallback only: strip non-word symbols and never run in live servers
		local studioSafe = cleaned:gsub("[<>\"'`\\]", "")
		if #studioSafe >= 2 and not studioSafe:match("^#+$") then
			return true, studioSafe
		end
	end
	return false, nil
end

-- ============================================================================
-- 3. POLICYSERVICE REGIONAL PAID-RANDOM GATING (ArePaidRandomItemsRestricted)
-- ============================================================================
function LiveOps.IsPaidRandomRestricted(player)
	if not player then
		return false
	end
	local uid = tonumber(player.UserId) or 0
	if uid > 0 and policyCache[uid] ~= nil then
		return policyCache[uid] == true
	end
	local okAttr, curAttr = pcall(function()
		return player:GetAttribute("PaidRandomRestricted")
	end)
	if okAttr and type(curAttr) == "boolean" then
		if uid > 0 then
			policyCache[uid] = curAttr
		end
		return curAttr
	end
	local restricted = false
	if uid > 0 then
		local ok, info = pcall(function()
			return PolicyService:GetPolicyInfoForPlayerAsync(player)
		end)
		if ok and type(info) == "table" and info.ArePaidRandomItemsRestricted == true then
			restricted = true
		end
		policyCache[uid] = restricted
	end
	pcall(function()
		player:SetAttribute("PaidRandomRestricted", restricted)
	end)
	return restricted
end

-- ============================================================================
-- 4. 8 PUBLIC-LAUNCH BADGES (0-ID SAFE GUARD + LOCAL UNLOCK PERSISTENCE)
-- ============================================================================
function LiveOps.AwardBadge(arg1, arg2, arg3, arg4)
	local G, player, profile, badgeKey
	if arg4 == nil and typeof(arg1) == "Instance" and type(arg2) == "table" and type(arg3) == "string" then
		G, player, profile, badgeKey = liveG, arg1, arg2, arg3
	else
		G, player, profile, badgeKey = arg1, arg2, arg3, arg4
	end
	if not player or type(profile) ~= "table" or type(badgeKey) ~= "string" then
		return false
	end
	local def = BadgeConfig and BadgeConfig.Get and BadgeConfig.Get(badgeKey) or nil
	local canonKey = (def and def.Id) or badgeKey
	profile.UnlockedBadges = type(profile.UnlockedBadges) == "table" and profile.UnlockedBadges or {}
	local firstTime = (profile.UnlockedBadges[canonKey] ~= true)
	if firstTime then
		profile.UnlockedBadges[canonKey] = true
		if G and G.Notify then
			local titleVi = (def and def.TitleVi) or canonKey
			local titleEn = (def and def.TitleEn) or canonKey
			LiveOps.Notify(
				G,
				player,
				"HUY HIỆU MỚI: " .. tostring(titleVi) .. "!",
				"BADGE UNLOCKED: " .. tostring(titleEn) .. "!"
			)
		end
	end
	local numericId = def and (tonumber(def.BadgeId) or 0) or 0
	if numericId > 0 and (tonumber(player.UserId) or 0) > 0 then
		task.spawn(function()
			pcall(function()
				BadgeService:AwardBadge(player.UserId, numericId)
			end)
		end)
	end
	return firstTime
end

function LiveOps.EvaluateProgressionBadges(G, player, profile)
	if not player or type(profile) ~= "table" then
		return
	end
	local cq = type(profile.CompletedQuests) == "table" and profile.CompletedQuests or {}
	local fb = type(profile.FirstClearBosses) == "table" and profile.FirstClearBosses or {}
	local uw = type(profile.UnlockedWorlds) == "table" and profile.UnlockedWorlds or {}
	local inv = type(profile.Inventory) == "table" and profile.Inventory or {}
	local lv = tonumber(profile.Level) or 1

	if cq.Q01 or profile.StarterCoreVoucherGranted then
		LiveOps.AwardBadge(G, player, profile, "welcome_skyborn")
	end
	local hasFruit = (type(profile.Fruit) == "string" and profile.Fruit ~= "" and profile.Fruit ~= "None")
		or (type(profile.StoredFruits) == "table" and next(profile.StoredFruits) ~= nil)
	if hasFruit then
		LiveOps.AwardBadge(G, player, profile, "first_aether_core")
	end
	if fb.AureonSentinel or cq.Q10 then
		LiveOps.AwardBadge(G, player, profile, "aureon_slayer")
	end
	if lv >= 700 or uw.FrozenCyber then
		LiveOps.AwardBadge(G, player, profile, "sea2_cyberport")
	end
	if fb.CryonPrime or cq.Q17 then
		LiveOps.AwardBadge(G, player, profile, "cryon_slayer")
	end
	local hasAwk = (type(profile.AwakenedMoves) == "table" and next(profile.AwakenedMoves) ~= nil)
		or (type(profile.AwakenedFruits) == "table" and next(profile.AwakenedFruits) ~= nil)
	if hasAwk then
		LiveOps.AwardBadge(G, player, profile, "awakened_core_v2")
	end
	if fb.AbyssalLeviathan or (tonumber(inv.LeviathanHeart) or 0) > 0 or (tonumber(inv.leviathan_shield) or 0) > 0 then
		LiveOps.AwardBadge(G, player, profile, "leviathan_slayer")
	end
	if lv >= 2550 or fb.Veyr or cq.Q30 then
		LiveOps.AwardBadge(G, player, profile, "apex_architect_2550")
	end
end

-- ============================================================================
-- 5. SESSION PLAYTIME GIFTS (6 TIERS: 5m, 10m, 20m, 30m, 45m, 60m)
-- ============================================================================
local function ensureSession(player)
	if not player then
		return nil
	end
	local st = sessionState[player]
	if not st then
		st = {
			JoinClock = os.clock(),
			Claimed = { [1] = false, [2] = false, [3] = false, [4] = false, [5] = false, [6] = false },
		}
		sessionState[player] = st
	end
	return st
end

function LiveOps.GetPlaytimeState(player)
	local st = ensureSession(player)
	local elapsed = st and math.max(0, math.floor(os.clock() - st.JoinClock)) or 0
	local claimedCopy = {}
	for i = 1, #PLAYTIME_TIERS do
		claimedCopy[i] = (st and st.Claimed[i] == true) or false
	end
	return {
		ElapsedSec = elapsed,
		SyncUnix = os.time(),
		Claimed = claimedCopy,
		Tiers = PLAYTIME_TIERS,
	}
end

function LiveOps.ClaimPlaytimeGift(G, D, Helpers, Monetization, player, payload)
	local profile = D and D.Get and D.Get(player)
	if not player or not profile then
		return false, "Profile unavailable"
	end
	local st = ensureSession(player)
	local idx = math.floor(tonumber(type(payload) == "table" and (payload.index or payload.Index or payload.tier or payload.id) or payload) or 0)
	local tier = PLAYTIME_TIERS[idx]
	if not tier then
		return false, "Invalid tier"
	end
	if st.Claimed[idx] then
		LiveOps.Notify(G, player, "Bạn đã nhận mốc quà phiên chơi này rồi!", "You already claimed this session gift!")
		return false, "Already claimed"
	end
	local elapsed = math.max(0, math.floor(os.clock() - st.JoinClock))
	if elapsed < tier.RequiredSec then
		local rem = tier.RequiredSec - elapsed
		local mins = math.ceil(rem / 60)
		LiveOps.Notify(
			G,
			player,
			string.format("Cần online thêm %d phút để nhận mốc %s!", mins, tier.TitleVi),
			string.format("Stay online %d more min to claim the %s gift!", mins, tier.TitleEn)
		)
		return false, "Not ready"
	end

	st.Claimed[idx] = true
	profile.Inventory = type(profile.Inventory) == "table" and profile.Inventory or {}
	profile.StoredFruits = type(profile.StoredFruits) == "table" and profile.StoredFruits or {}

	local ownsGoldPass = Monetization and Monetization.OwnsPass and Monetization.OwnsPass(player, "x2_gold") or false
	local msgVi, msgEn = "", ""

	if tier.RewardType == "Gold" then
		local goldAmt = tier.Amount * (ownsGoldPass and 2 or 1)
		profile.Gold = (tonumber(profile.Gold) or 0) + goldAmt
		msgVi = string.format("Quà Online %s: +%d Vàng!", tier.TitleVi, goldAmt)
		msgEn = string.format("%s Playtime Gift: +%d Gold!", tier.TitleEn, goldAmt)
	elseif tier.RewardType == "Shards" then
		profile.CoreShards = (tonumber(profile.CoreShards) or 0) + tier.Amount
		msgVi = string.format("Quà Online %s: +%d Tinh Thạch!", tier.TitleVi, tier.Amount)
		msgEn = string.format("%s Playtime Gift: +%d Core Shards!", tier.TitleEn, tier.Amount)
	elseif tier.RewardType == "DoubleExp" then
		profile.DoubleExpRemainingSec = math.max(0, tonumber(profile.DoubleExpRemainingSec) or 0) + tier.Amount
		profile.DoubleExpUntil = os.time() + profile.DoubleExpRemainingSec
		msgVi = string.format("Quà Online %s: +15 Phút x2 EXP (chỉ tính giờ khi online)!", tier.TitleVi)
		msgEn = string.format("%s Playtime Gift: +15m 2x EXP (ticks only while online)!", tier.TitleEn)
	elseif tier.RewardType == "ScrollAndShards" then
		profile.Inventory.EnchantScroll = (tonumber(profile.Inventory.EnchantScroll) or 0) + 1
		local sb = tonumber(tier.ShardsBonus) or 100
		profile.CoreShards = (tonumber(profile.CoreShards) or 0) + sb
		msgVi = string.format("Quà Online %s: +1 Bùa Cổ Ngữ & +%d Tinh Thạch!", tier.TitleVi, sb)
		msgEn = string.format("%s Playtime Gift: +1 Rune Scroll & +%d Core Shards!", tier.TitleEn, sb)
	elseif tier.RewardType == "CoreVoucher" then
		profile.FreeFruitVouchers = (tonumber(profile.FreeFruitVouchers) or 0) + 1
		msgVi = string.format("Quà Online %s: +1 Vé Quay Lõi Aether Miễn Phí!", tier.TitleVi)
		msgEn = string.format("%s Playtime Gift: +1 Free Aether Core Spin Voucher!", tier.TitleEn)
	elseif tier.RewardType == "RarePlusCore" then
		local sb = tonumber(tier.ShardsBonus) or 200
		profile.CoreShards = (tonumber(profile.CoreShards) or 0) + sb
		local rolledId, fCfg = nil, nil
		if C.RollRarePlusFruit then
			rolledId, fCfg = C.RollRarePlusFruit()
		else
			rolledId, fCfg = C.RollWeightedFruit()
		end
		local canStore = Helpers and Helpers.CanStoreCore and Helpers.CanStoreCore(player, profile, rolledId)
		if canStore then
			profile.StoredFruits[rolledId] = (tonumber(profile.StoredFruits[rolledId]) or 0) + 1
			LiveOps.AwardBadge(G, player, profile, "first_aether_core")
			local fname = (fCfg and fCfg.Name) or tostring(rolledId)
			msgVi = string.format("Quà Online %s: Nhận [%s] vào Kho Lõi & +%d Tinh Thạch!", tier.TitleVi, fname, sb)
			msgEn = string.format("%s Playtime Gift: Stored [%s] & +%d Core Shards!", tier.TitleEn, fname, sb)
		else
			profile.FreeFruitVouchers = (tonumber(profile.FreeFruitVouchers) or 0) + 1
			msgVi = string.format("Kho Lõi đã đầy! Quà Online %s chuyển thành +1 Vé Quay Lõi Miễn Phí & +%d Tinh Thạch!", tier.TitleVi, sb)
			msgEn = string.format("Core Storage full! %s Gift converted to +1 Free Core Voucher & +%d Core Shards!", tier.TitleEn, sb)
		end
	end

	LiveOps.Notify(G, player, msgVi, msgEn)
	if G and G.Sync then
		G.Sync(player)
	end
	if D and D.Save then
		task.spawn(D.Save, player, false)
	end
	return true, msgEn
end

-- ============================================================================
-- 6. SERVER-VERIFIED FRIEND BOOST (+5% EXP/MASTERY PER FRIEND IN SERVER, MAX +15%)
-- ============================================================================
local function recomputeAllFriendBoosts(G)
	local list = Players:GetPlayers()
	for _, p in ipairs(list) do
		local count = 0
		if (tonumber(p.UserId) or 0) > 0 then
			for _, other in ipairs(list) do
				if other ~= p and (tonumber(other.UserId) or 0) > 0 then
					local ok, isFr = pcall(function()
						return p:IsFriendsWith(other.UserId)
					end)
					if ok and isFr then
						count += 1
						if count >= 3 then
							break
						end
					end
				end
			end
		end
		local pct = math.clamp(count * 5, 0, 15)
		local prev = friendBoostPct[p]
		friendBoostPct[p] = pct
		pcall(function()
			p:SetAttribute("FriendBoostPct", pct)
		end)
		if prev ~= pct and G and G.Sync then
			pcall(G.Sync, p)
		end
	end
end

function LiveOps.GetFriendBoostPct(player)
	return tonumber(friendBoostPct[player]) or 0
end

function LiveOps.GetFriendBoostMultiplier(player)
	local pct = LiveOps.GetFriendBoostPct(player)
	return 1 + (pct / 100)
end

-- ============================================================================
-- 7. CROSS-SERVER ORDEREDDATASTORE LEADERBOARDS (Level, Renown, BossDPS)
-- ============================================================================
local function getOds(category)
	if not persistenceEnabled() then
		return nil
	end
	local storeName = ODS_NAMES[category]
	if not storeName then
		return nil
	end
	if not odsStores[category] then
		local ok, store = pcall(function()
			return DataStoreService:GetOrderedDataStore(storeName)
		end)
		if ok and store then
			odsStores[category] = store
		end
	end
	return odsStores[category]
end

local function resolveUserName(uid)
	uid = tonumber(uid) or 0
	if uid <= 0 then
		return "Skyborn"
	end
	if nameCache[uid] then
		return nameCache[uid]
	end
	local livePlr = Players:GetPlayerByUserId(uid)
	if livePlr then
		nameCache[uid] = livePlr.DisplayName or livePlr.Name
		return nameCache[uid]
	end
	local ok, uname = pcall(function()
		return Players:GetNameFromUserIdAsync(uid)
	end)
	if ok and type(uname) == "string" and uname ~= "" then
		nameCache[uid] = uname
		return uname
	end
	return "Skyborn #" .. tostring(uid)
end

function LiveOps.RecordLeaderboardScore(player, category, rawScore, forceWrite)
	if not player or not ODS_NAMES[category] then
		return
	end
	local uid = tonumber(player.UserId) or 0
	local score = math.max(0, math.floor(tonumber(rawScore) or 0))
	if uid <= 0 or score <= 0 then
		return
	end
	nameCache[uid] = player.DisplayName or player.Name
	if not persistenceEnabled() then
		return
	end
	local key = category .. ":" .. tostring(uid)
	local prev = lastOdsWrite[key]
	local now = os.clock()
	if not forceWrite and prev then
		if score <= prev.Score and (now - prev.Clock) < 300 then
			return
		end
		if (now - prev.Clock) < 120 then
			return
		end
	end
	lastOdsWrite[key] = { Clock = now, Score = score }
	local store = getOds(category)
	if not store then
		return
	end
	task.spawn(function()
		pcall(function()
			store:SetAsync(tostring(uid), score)
		end)
	end)
end

function LiveOps.RefreshOrderedCategoryAsync(category)
	local bucket = odsCache[category]
	if not bucket or bucket.Fetching then
		return
	end
	if (os.clock() - bucket.UpdatedAt) < 90 and #bucket.Rows > 0 then
		return
	end
	local store = getOds(category)
	if not store then
		bucket.UpdatedAt = os.clock()
		return
	end
	bucket.Fetching = true
	task.spawn(function()
		local ok, pages = pcall(function()
			return store:GetSortedAsync(false, 20)
		end)
		if ok and pages then
			local okPage, page = pcall(function()
				return pages:GetCurrentPage()
			end)
			if okPage and type(page) == "table" then
				local rows = {}
				for rank, entry in ipairs(page) do
					local uid = tonumber(entry.key) or 0
					local val = math.max(0, math.floor(tonumber(entry.value) or 0))
					if uid > 0 and val > 0 then
						local nm = resolveUserName(uid)
						table.insert(rows, {
							Rank = rank,
							UserId = uid,
							Name = nm,
							DisplayName = nm,
							Value = val,
							Score = val,
						})
					end
				end
				bucket.Rows = rows
				bucket.UpdatedAt = os.clock()
			end
		end
		bucket.Fetching = false
	end)
end

local function buildMergedCategoryRows(category, liveEntries)
	local byKey = {}
	local bucket = odsCache[category]
	for _, r in ipairs((bucket and bucket.Rows) or {}) do
		local k = (r.UserId and r.UserId > 0) and ("u:" .. tostring(r.UserId)) or ("n:" .. tostring(r.Name))
		byKey[k] = {
			UserId = r.UserId or 0,
			Name = r.Name or "Skyborn",
			DisplayName = r.DisplayName or r.Name or "Skyborn",
			Value = tonumber(r.Value) or 0,
			Score = tonumber(r.Value) or 0,
		}
	end
	for _, live in ipairs(liveEntries or {}) do
		local k = (live.UserId and live.UserId > 0) and ("u:" .. tostring(live.UserId)) or ("n:" .. tostring(live.Name))
		local existing = byKey[k]
		if not existing or (tonumber(live.Value) or 0) >= (tonumber(existing.Value) or 0) then
			byKey[k] = {
				UserId = live.UserId or 0,
				Name = live.Name or "Skyborn",
				DisplayName = live.DisplayName or live.Name or "Skyborn",
				Value = tonumber(live.Value) or 0,
				Score = tonumber(live.Value) or 0,
			}
		end
	end
	local merged = {}
	for _, item in pairs(byKey) do
		if (tonumber(item.Value) or 0) > 0 then
			table.insert(merged, item)
		end
	end
	table.sort(merged, function(a, b)
		if a.Value == b.Value then
			return tostring(a.Name) < tostring(b.Name)
		end
		return a.Value > b.Value
	end)
	local out = {}
	for i = 1, math.min(20, #merged) do
		local row = merged[i]
		row.Rank = i
		table.insert(out, row)
	end
	return out
end

function LiveOps.GetGlobalLeaderboards(D, SocialEconomy)
	local liveLevel, liveRenown, liveDPS = {}, {}, {}
	local dpsByUser = {}
	if SocialEconomy and SocialEconomy.State and type(SocialEconomy.State.TopBossDPSRecords) == "table" then
		for _, rec in ipairs(SocialEconomy.State.TopBossDPSRecords) do
			if type(rec) == "table" and (tonumber(rec.DPS) or 0) > 0 then
				local key = tostring(rec.PlayerName or "")
				if key ~= "" and ((not dpsByUser[key]) or rec.DPS > dpsByUser[key].DPS) then
					dpsByUser[key] = rec
				end
			end
		end
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		local prof = D and D.Get and D.Get(plr)
		local uid = tonumber(plr.UserId) or 0
		local nm = plr.DisplayName or plr.Name
		if prof then
			table.insert(liveLevel, {
				UserId = uid,
				Name = plr.Name,
				DisplayName = nm,
				Value = math.max(1, math.floor(tonumber(prof.Level) or 1)),
			})
			table.insert(liveRenown, {
				UserId = uid,
				Name = plr.Name,
				DisplayName = nm,
				Value = math.max(0, math.floor(tonumber(prof.Bounty) or 0)),
			})
			local bestDps = math.max(
				0,
				math.floor(tonumber(prof.HighestBossDPS) or 0),
				math.floor(tonumber(dpsByUser[plr.Name] and dpsByUser[plr.Name].DPS) or 0)
			)
			if bestDps > 0 then
				table.insert(liveDPS, {
					UserId = uid,
					Name = plr.Name,
					DisplayName = nm,
					Value = bestDps,
				})
			end
		end
	end
	for pName, rec in pairs(dpsByUser) do
		local already = false
		for _, row in ipairs(liveDPS) do
			if row.Name == pName then
				already = true
				break
			end
		end
		if not already then
			table.insert(liveDPS, {
				UserId = tonumber(rec.UserId) or 0,
				Name = pName,
				DisplayName = pName,
				Value = math.max(0, math.floor(tonumber(rec.DPS) or 0)),
			})
		end
	end

	return {
		Level = buildMergedCategoryRows("Level", liveLevel),
		Renown = buildMergedCategoryRows("Renown", liveRenown),
		BossDPS = buildMergedCategoryRows("BossDPS", liveDPS),
	}
end

function LiveOps.HandleRequestGlobalLeaderboard(G, D, SocialEconomy, player, payload)
	local cat = type(payload) == "table" and tostring(payload.category or payload.Category or "") or ""
	if ODS_NAMES[cat] then
		LiveOps.RefreshOrderedCategoryAsync(cat)
	else
		LiveOps.RefreshOrderedCategoryAsync("Level")
		LiveOps.RefreshOrderedCategoryAsync("Renown")
		LiveOps.RefreshOrderedCategoryAsync("BossDPS")
	end
	if G and G.Sync and player then
		G.Sync(player)
	end
	return true, "Synced"
end

function LiveOps.SyncPlayerScoresOnSave(player, profile, forceWrite)
	if not player or type(profile) ~= "table" then
		return
	end
	LiveOps.RecordLeaderboardScore(player, "Level", profile.Level or 1, forceWrite)
	LiveOps.RecordLeaderboardScore(player, "Renown", profile.Bounty or 0, forceWrite)
	if (tonumber(profile.HighestBossDPS) or 0) > 0 then
		LiveOps.RecordLeaderboardScore(player, "BossDPS", profile.HighestBossDPS, forceWrite)
	end
end

-- ============================================================================
-- 8. LIFECYCLE START
-- ============================================================================
function LiveOps.Start(G, D)
	liveG = G or liveG
	if started then
		return
	end
	started = true

	local function onJoin(player)
		ensureSession(player)
		task.spawn(function()
			LiveOps.IsPaidRandomRestricted(player)
			recomputeAllFriendBoosts(G)
		end)
	end

	for _, plr in ipairs(Players:GetPlayers()) do
		onJoin(plr)
	end
	Players.PlayerAdded:Connect(onJoin)
	Players.PlayerRemoving:Connect(function(player)
		if D and D.Get then
			local prof = D.Get(player)
			if prof then
				LiveOps.SyncPlayerScoresOnSave(player, prof, true)
			end
		end
		sessionState[player] = nil
		friendBoostPct[player] = nil
		local uid = tonumber(player.UserId) or 0
		if uid > 0 then
			policyCache[uid] = nil
		end
		task.defer(function()
			recomputeAllFriendBoosts(G)
		end)
	end)

	LiveOps.RefreshOrderedCategoryAsync("Level")
	LiveOps.RefreshOrderedCategoryAsync("Renown")
	LiveOps.RefreshOrderedCategoryAsync("BossDPS")
end

return LiveOps
