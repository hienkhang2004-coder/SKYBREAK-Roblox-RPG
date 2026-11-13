-- SKYBREAK: Fragments of the Core — Server-Authoritative Monetization Service (D2 / P2-01)
-- Location: ServerScriptService/Services/MonetizationService.lua
-- Implements idempotent ProcessReceipt, cached GamePass ownership sync, cosmetic perks, and Studio QA test flow.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MonetizationConfig = require(ReplicatedStorage:WaitForChild("SkybreakShared"):WaitForChild("Config"):WaitForChild("MonetizationConfig"))
local D = require(script.Parent:WaitForChild("PlayerDataService"))
local DevGate = require(script.Parent:WaitForChild("DevGate"))
local LiveOps = require(script.Parent:WaitForChild("SkybreakLiveOpsService"))

local MonetizationService = {
	Started = false,
	SessionPassCache = {},
	InFlightReceipts = {},
	LastPromptAt = {},
	StudioReceiptSeq = 0,
}

local MAX_RECEIPT_HISTORY = 200
local STAT_KEYS = { "Melee", "Defense", "Sword", "Gun", "Fruit" }

local cachedGameService = nil
local function getGameService()
	if cachedGameService then
		return cachedGameService
	end
	local gsMod = script.Parent:FindFirstChild("GameService")
	if gsMod and gsMod:IsA("ModuleScript") then
		local ok, svc = pcall(require, gsMod)
		if ok and type(svc) == "table" then
			cachedGameService = svc
			return svc
		end
	end
	return nil
end

local function registerVipTitleIfPresent()
	pcall(function()
		local coreShared = ReplicatedStorage:FindFirstChild("Shared")
		local cdMod = coreShared and coreShared:FindFirstChild("SkybreakCombatData")
		if cdMod and cdMod:IsA("ModuleScript") then
			local cd = require(cdMod)
			if type(cd) == "table" and type(cd.Titles) == "table" and cd.Titles.celestial_vip == nil then
				cd.Titles.celestial_vip = {
					Id = "celestial_vip",
					Name = "Thiên Giới Chí Tôn [VIP]",
					Color = Color3.fromRGB(255, 218, 92),
					Desc = "Đặc quyền Hào Quang Danh Hiệu Thiên Giới.",
				}
			end
		end
	end)
end

local function sendToastAndNotify(player, msg, kind)
	if not player or type(msg) ~= "string" or msg == "" then
		return
	end
	local gs = getGameService()
	if gs and type(gs.Notify) == "function" then
		pcall(gs.Notify, player, msg)
	end
	pcall(function()
		local skyShared = ReplicatedStorage:FindFirstChild("SkybreakShared")
		local rems = skyShared and skyShared:FindFirstChild("Remotes")
		local uiStateEv = rems and rems:FindFirstChild("UIStateUpdated")
		if uiStateEv and uiStateEv:IsA("RemoteEvent") then
			uiStateEv:FireClient(player, {
				Toast = {
					message = msg,
					kind = kind or "info",
				},
			})
		end
	end)
end

local function syncPlayerState(player)
	local gs = getGameService()
	if gs and type(gs.Sync) == "function" then
		pcall(gs.Sync, player)
	end
end

local function cloneFlatTable(tbl)
	if type(tbl) ~= "table" then
		return {}
	end
	local out = {}
	for k, v in pairs(tbl) do
		out[k] = v
	end
	return out
end

local function applyGoldenShipCosmetic(shipModel)
	if not shipModel or not shipModel:IsA("Model") then
		return
	end
	local ownerId = tonumber(shipModel:GetAttribute("OwnerUserId")) or 0
	if ownerId <= 0 then
		return
	end
	local owner = Players:GetPlayerByUserId(ownerId)
	if not owner then
		return
	end
	local prof = D.Get(owner)
	local ownsGoldShip = (owner:GetAttribute("OwnedPass_golden_sky_ship") == true)
		or (type(prof) == "table" and type(prof.OwnedGamePasses) == "table" and prof.OwnedGamePasses.golden_sky_ship == true)
	if not ownsGoldShip then
		return
	end
	shipModel:SetAttribute("GoldenShipSkin", true)
	if not shipModel:FindFirstChild("GoldenSovereignHighlight") then
		local hl = Instance.new("Highlight")
		hl.Name = "GoldenSovereignHighlight"
		hl.FillColor = Color3.fromRGB(255, 212, 84)
		hl.FillTransparency = 0.72
		hl.OutlineColor = Color3.fromRGB(255, 238, 152)
		hl.OutlineTransparency = 0.22
		hl.DepthMode = Enum.HighlightDepthMode.Occluded
		hl.Parent = shipModel
	end
	local hull = shipModel:FindFirstChild("HullRoot") or shipModel.PrimaryPart
	if hull and hull:IsA("BasePart") and not hull:FindFirstChild("GoldenSovereignLight") then
		local pt = Instance.new("PointLight")
		pt.Name = "GoldenSovereignLight"
		pt.Color = Color3.fromRGB(255, 214, 96)
		pt.Brightness = 1.6
		pt.Range = 28
		pt.Parent = hull
	end
end

local function applyCharacterNameAura(player, character)
	local ch = character or (player and player.Character)
	if not player or not ch then
		return
	end
	local prof = D.Get(player)
	local ownsAura = (player:GetAttribute("OwnedPass_sovereign_name_aura") == true)
		or (type(prof) == "table" and type(prof.OwnedGamePasses) == "table" and prof.OwnedGamePasses.sovereign_name_aura == true)
	if not ownsAura then
		return
	end
	ch:SetAttribute("SovereignNameAura", true)
	task.defer(function()
		if not ch.Parent then
			return
		end
		local head = ch:FindFirstChild("Head")
		local bill = head and head:FindFirstChild("SkybreakOverheadGui")
		local nameLbl = bill and bill:FindFirstChild("NameLabel")
		if nameLbl and nameLbl:IsA("TextLabel") and not nameLbl:FindFirstChild("SovereignAuraGradient") then
			nameLbl.TextColor3 = Color3.fromRGB(255, 244, 196)
			local grad = Instance.new("UIGradient")
			grad.Name = "SovereignAuraGradient"
			grad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 238, 156)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 196, 68)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 246, 198)),
			})
			grad.Parent = nameLbl
		end
	end)
end

local function syncPassAttributesAndPerks(player, profile, newlyGrantedKey)
	if not player or type(profile) ~= "table" then
		return
	end
	profile.OwnedGamePasses = type(profile.OwnedGamePasses) == "table" and profile.OwnedGamePasses or {}
	local owned = profile.OwnedGamePasses

	for _, pass in ipairs(MonetizationConfig.GamePasses) do
		local hasPass = (owned[pass.Key] == true)
		player:SetAttribute("OwnedPass_" .. pass.Key, hasPass)
	end

	local ownsExtraStorage = (owned.extra_core_storage == true)
	local maxCoreStorage = 1 + (ownsExtraStorage and 3 or 0)
	player:SetAttribute("MaxCoreStorage", maxCoreStorage)

	if owned.golden_sky_ship == true then
		profile.UnlockedShips = type(profile.UnlockedShips) == "table" and profile.UnlockedShips or { SkySloop = true }
		profile.UnlockedShips.SkySloop = true
		profile.UnlockedShips.GoldenSovereignSloop = true
		profile.UnlockedShips.SkyGalleon = true
		player:SetAttribute("GoldenShipSkin", true)
		local shipsFolder = workspace:FindFirstChild("ActiveShips")
		if shipsFolder then
			for _, child in ipairs(shipsFolder:GetChildren()) do
				if child:IsA("Model") and tonumber(child:GetAttribute("OwnerUserId")) == player.UserId then
					applyGoldenShipCosmetic(child)
				end
			end
		end
	else
		player:SetAttribute("GoldenShipSkin", false)
	end

	if owned.sovereign_name_aura == true then
		registerVipTitleIfPresent()
		profile.UnlockedTitles = type(profile.UnlockedTitles) == "table" and profile.UnlockedTitles or { sky_rookie = true }
		profile.UnlockedTitles.celestial_vip = true
		if newlyGrantedKey == "sovereign_name_aura" or profile.Title == nil or profile.Title == "" or profile.Title == "sky_rookie" or profile.Title == "Skyborn Novice" then
			profile.Title = "celestial_vip"
		end
		player:SetAttribute("SovereignNameAura", true)
		player:SetAttribute("HasSovereignAura", true)
		player:SetAttribute("VIPChatTag", true)
		if player.Character then
			applyCharacterNameAura(player, player.Character)
		end
	else
		player:SetAttribute("SovereignNameAura", false)
		player:SetAttribute("HasSovereignAura", false)
		player:SetAttribute("VIPChatTag", false)
	end
end

function MonetizationService.UserOwnsPass(player, passKey)
	if not player or type(passKey) ~= "string" or passKey == "" then
		return false
	end
	if player:GetAttribute("OwnedPass_" .. passKey) == true then
		return true
	end
	local prof = D.Get(player)
	if type(prof) == "table" and type(prof.OwnedGamePasses) == "table" and prof.OwnedGamePasses[passKey] == true then
		return true
	end
	local uCache = MonetizationService.SessionPassCache[player.UserId]
	return type(uCache) == "table" and uCache[passKey] == true
end
MonetizationService.OwnsPass = MonetizationService.UserOwnsPass

function MonetizationService.GetMaxCoreStorage(player, profile)
	local prof = profile or (player and D.Get(player))
	local ownsExtra = (type(prof) == "table" and type(prof.OwnedGamePasses) == "table" and prof.OwnedGamePasses.extra_core_storage == true)
		or (player ~= nil and player:GetAttribute("OwnedPass_extra_core_storage") == true)
	return 1 + (ownsExtra and 3 or 0)
end

function MonetizationService.SyncPlayerPasses(player, forceRefresh)
	if not player or player.Parent ~= Players then
		return false
	end
	local profile = D.Get(player)
	local waitDeadline = os.clock() + 18
	while not profile and player.Parent == Players and os.clock() < waitDeadline do
		task.wait(0.25)
		profile = D.Get(player)
	end
	if not profile or player.Parent ~= Players then
		return false
	end

	profile.OwnedGamePasses = type(profile.OwnedGamePasses) == "table" and profile.OwnedGamePasses or {}
	local uid = player.UserId
	local uCache = MonetizationService.SessionPassCache[uid]
	if type(uCache) ~= "table" then
		uCache = {}
		MonetizationService.SessionPassCache[uid] = uCache
	end

	local changed = false
	for _, pass in ipairs(MonetizationConfig.GamePasses) do
		local key = pass.Key
		local gpId = tonumber(pass.GamePassId) or 0
		local isOwned = (profile.OwnedGamePasses[key] == true) or (uCache[key] == true)
		if (not isOwned or forceRefresh == true) and gpId > 0 then
			local okOwn, ownsRemote = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(uid, gpId)
			end)
			if okOwn and ownsRemote == true then
				isOwned = true
			end
		end
		if isOwned then
			uCache[key] = true
			if profile.OwnedGamePasses[key] ~= true then
				profile.OwnedGamePasses[key] = true
				changed = true
			end
		end
	end

	syncPassAttributesAndPerks(player, profile, nil)
	if changed and not D.IsReadOnlyFallback(player) then
		task.spawn(D.Save, player, false)
	end
	syncPlayerState(player)
	return true
end

local function grantDevProductRewards(player, profile, prod)
	if tonumber(prod.GoldGrant) and tonumber(prod.GoldGrant) > 0 then
		local addGold = math.floor(tonumber(prod.GoldGrant))
		profile.Gold = math.max(0, tonumber(profile.Gold) or 0) + addGold
		return LiveOps.Pick(
			player,
			string.format("Đã nhận +%d Vàng từ [%s]!", addGold, prod.NameVi or prod.Key),
			string.format("Received +%d Gold from [%s]!", addGold, prod.NameEn or prod.NameVi or prod.Key)
		)
	elseif prod.StatRefund == true then
		profile.StatAlloc = type(profile.StatAlloc) == "table" and profile.StatAlloc or { Melee = 1, Defense = 1, Sword = 1, Gun = 1, Fruit = 1 }
		local refunded = 0
		for _, k in ipairs(STAT_KEYS) do
			local cur = math.floor(tonumber(profile.StatAlloc[k]) or 1)
			if cur > 1 then
				refunded += (cur - 1)
				profile.StatAlloc[k] = 1
			else
				profile.StatAlloc[k] = 1
			end
		end
		profile.StatPoints = math.max(0, tonumber(profile.StatPoints) or 0) + refunded
		return LiveOps.Pick(
			player,
			string.format("Đã hoàn trả toàn bộ Điểm Chỉ Số (Khả dụng: %d Stat Points)!", profile.StatPoints),
			string.format("All Stat Points refunded (Available: %d Stat Points)!", profile.StatPoints)
		)
	elseif tonumber(prod.DoubleExpSec) and tonumber(prod.DoubleExpSec) > 0 then
		local addSec = math.floor(tonumber(prod.DoubleExpSec))
		local remSec = math.max(0, tonumber(profile.DoubleExpRemainingSec) or tonumber(profile.DoubleExpRemaining) or 0) + addSec
		profile.DoubleExpRemainingSec = remSec
		profile.DoubleExpRemaining = remSec
		profile.DoubleExpUntil = os.time() + remSec
		player:SetAttribute("DoubleExpUntil", profile.DoubleExpUntil)
		player:SetAttribute("DoubleExpSeconds", remSec)
		local totalMin = math.ceil(remSec / 60)
		return LiveOps.Pick(
			player,
			string.format("Đã kích hoạt +30 phút x2 EXP (Còn lại: %d phút online)!", totalMin),
			string.format("Activated +30m 2x EXP (%d min online remaining)!", totalMin)
		)
	end
	return LiveOps.Pick(
		player,
		"Đã nhận vật phẩm [" .. tostring(prod.NameVi or prod.Key) .. "]!",
		"Received [" .. tostring(prod.NameEn or prod.NameVi or prod.Key) .. "]!"
	)
end

-- Idempotent MarketplaceService.ProcessReceipt handler (PUBLISH_PLAN P2-01)
function MonetizationService.ProcessReceipt(receiptInfo)
	if type(receiptInfo) ~= "table" then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local playerId = tonumber(receiptInfo.PlayerId) or 0
	local productId = tonumber(receiptInfo.ProductId) or 0
	local receiptId = tostring(receiptInfo.PurchaseId or "")
	if playerId <= 0 or receiptId == "" then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local player = Players:GetPlayerByUserId(playerId)
	if not player or player.Parent ~= Players then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local profile = D.Get(player)
	if not profile then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if (D.IsReadOnlyFallback and D.IsReadOnlyFallback(player)) or profile._ReadOnlyFallback == true then
		warn("[SKYBREAK][Monetization] Deferring receipt while profile is in ReadOnlyFallback for", player.Name)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	profile.ProcessedReceipts = type(profile.ProcessedReceipts) == "table" and profile.ProcessedReceipts or {}
	profile.ProcessedReceiptOrder = type(profile.ProcessedReceiptOrder) == "table" and profile.ProcessedReceiptOrder or {}

	-- Idempotency guard: already granted & saved in an earlier receipt callback
	if profile.ProcessedReceipts[receiptId] == true then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	if MonetizationService.InFlightReceipts[receiptId] then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	MonetizationService.InFlightReceipts[receiptId] = true

	local prod = nil
	if type(receiptInfo._StudioProductKey) == "string" and DevGate.IsAllowed(player) then
		prod = MonetizationConfig.GetDevProduct(receiptInfo._StudioProductKey)
	else
		prod = MonetizationConfig.GetDevProduct(productId)
	end
	if not prod then
		warn("[SKYBREAK][Monetization] Unrecognized ProductId in ProcessReceipt:", productId)
		MonetizationService.InFlightReceipts[receiptId] = nil
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Snapshot pre-grant values so we can roll back cleanly if synchronous D.Save fails
	local prevGold = tonumber(profile.Gold) or 0
	local prevStatPoints = tonumber(profile.StatPoints) or 0
	local prevStatAlloc = cloneFlatTable(profile.StatAlloc)
	local prevDoubleExpUntil = tonumber(profile.DoubleExpUntil) or 0
	local prevDoubleExpRemaining = tonumber(profile.DoubleExpRemaining) or 0
	local prevDoubleExpRemainingSec = tonumber(profile.DoubleExpRemainingSec) or 0
	local prevOrder = cloneFlatTable(profile.ProcessedReceiptOrder)
	local prevReceipts = cloneFlatTable(profile.ProcessedReceipts)

	local grantMsg = grantDevProductRewards(player, profile, prod)
	profile.ProcessedReceipts[receiptId] = true
	table.insert(profile.ProcessedReceiptOrder, receiptId)
	while #profile.ProcessedReceiptOrder > MAX_RECEIPT_HISTORY do
		local oldest = table.remove(profile.ProcessedReceiptOrder, 1)
		if oldest and oldest ~= receiptId then
			profile.ProcessedReceipts[oldest] = nil
		end
	end

	-- Note: PlayerDataService.Save(player, release) 2nd arg is `release` (unlocks session on player leave).
	-- Passing `false` executes a synchronous immediate DataStore UpdateAsync while keeping the session lock!
	local okCall, okSave = pcall(D.Save, player, false)
	if not okCall or okSave ~= true then
		profile.Gold = prevGold
		profile.StatPoints = prevStatPoints
		profile.StatAlloc = prevStatAlloc
		profile.DoubleExpUntil = prevDoubleExpUntil
		profile.DoubleExpRemaining = prevDoubleExpRemaining
		profile.DoubleExpRemainingSec = prevDoubleExpRemainingSec
		profile.ProcessedReceiptOrder = prevOrder
		profile.ProcessedReceipts = prevReceipts
		player:SetAttribute("DoubleExpUntil", prevDoubleExpUntil)
		player:SetAttribute("DoubleExpSeconds", prevDoubleExpRemainingSec)
		MonetizationService.InFlightReceipts[receiptId] = nil
		warn("[SKYBREAK][Monetization] Synchronous save failed in ProcessReceipt for", player.Name, okSave)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	MonetizationService.InFlightReceipts[receiptId] = nil
	if not receiptInfo._SilentNotify then
		sendToastAndNotify(player, grantMsg, "success")
	end
	syncPlayerState(player)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local function onGamePassPurchaseFinished(player, gamePassId, wasPurchased)
	if not player or wasPurchased ~= true then
		return
	end
	local pass = MonetizationConfig.GetGamePass(tonumber(gamePassId) or 0)
	if not pass then
		return
	end
	local profile = D.Get(player)
	if not profile then
		return
	end
	local uid = player.UserId
	MonetizationService.SessionPassCache[uid] = MonetizationService.SessionPassCache[uid] or {}
	MonetizationService.SessionPassCache[uid][pass.Key] = true

	profile.OwnedGamePasses = type(profile.OwnedGamePasses) == "table" and profile.OwnedGamePasses or {}
	profile.OwnedGamePasses[pass.Key] = true
	syncPassAttributesAndPerks(player, profile, pass.Key)

	if not (D.IsReadOnlyFallback and D.IsReadOnlyFallback(player)) and profile._ReadOnlyFallback ~= true then
		pcall(D.Save, player, false)
	end
	sendToastAndNotify(player, string.format("Đã mở khóa vĩnh viễn [%s]!", pass.NameVi), "success")
	syncPlayerState(player)
end

function MonetizationService.HandleUIRequest(player, cmd, payload)
	if cmd ~= "PromptGamePass" and cmd ~= "PromptDevProduct" and cmd ~= "RefreshGamePasses" then
		return false
	end
	if not player or player.Parent ~= Players then
		return true
	end
	local now = os.clock()
	if now - (MonetizationService.LastPromptAt[player] or 0) < 0.55 then
		return true
	end
	MonetizationService.LastPromptAt[player] = now
	payload = type(payload) == "table" and payload or {}

	if cmd == "RefreshGamePasses" then
		MonetizationService.SyncPlayerPasses(player, true)
		sendToastAndNotify(player, "Đã đồng bộ trạng thái Đặc Quyền Game Pass!", "info")
		return true
	end

	local profile = D.Get(player)
	if not profile then
		sendToastAndNotify(player, "Hồ sơ nhân vật đang tải, vui lòng thử lại sau giây lát!", "warning")
		return true
	end
	if (D.IsReadOnlyFallback and D.IsReadOnlyFallback(player)) or profile._ReadOnlyFallback == true then
		sendToastAndNotify(player, "Đang ở chế độ Bảo Vệ Dữ Liệu (ReadOnly), tạm khóa giao dịch Robux để bảo vệ tài khoản!", "warning")
		return true
	end

	if cmd == "PromptGamePass" then
		local passKey = tostring(payload.passKey or payload.key or payload.id or payload.value or "")
		local pass = MonetizationConfig.GetGamePass(passKey)
		if not pass then
			sendToastAndNotify(player, "Không tìm thấy gói Đặc Quyền yêu cầu!", "warning")
			return true
		end
		if MonetizationService.UserOwnsPass(player, pass.Key) then
			syncPassAttributesAndPerks(player, profile, nil)
			syncPlayerState(player)
			sendToastAndNotify(player, "Bạn đã sở hữu vĩnh viễn [" .. pass.NameVi .. "]!", "info")
			return true
		end
		local gpId = tonumber(pass.GamePassId) or 0
		if gpId > 0 then
			local okPrompt, errPrompt = pcall(function()
				MarketplaceService:PromptGamePassPurchase(player, gpId)
			end)
			if not okPrompt then
				warn("[SKYBREAK][Monetization] PromptGamePassPurchase error:", errPrompt)
				sendToastAndNotify(player, "Không thể mở cửa sổ thanh toán Roblox lúc này!", "warning")
			end
			return true
		end
		-- GamePassId == 0: Studio / DevGate test flow vs Live placeholder message
		if DevGate.IsAllowed(player) then
			local uid = player.UserId
			MonetizationService.SessionPassCache[uid] = MonetizationService.SessionPassCache[uid] or {}
			MonetizationService.SessionPassCache[uid][pass.Key] = true
			profile.OwnedGamePasses = type(profile.OwnedGamePasses) == "table" and profile.OwnedGamePasses or {}
			profile.OwnedGamePasses[pass.Key] = true
			syncPassAttributesAndPerks(player, profile, pass.Key)
			pcall(D.Save, player, false)
			sendToastAndNotify(
				player,
				string.format("[STUDIO TEST] Đã kích hoạt thử nghiệm %s (%d R$)!", pass.NameVi, tonumber(pass.PriceRobux) or 0),
				"success"
			)
			syncPlayerState(player)
		else
			sendToastAndNotify(
				player,
				LiveOps.Pick(player, "Sắp mở bán trên Roblox Store!", "Coming soon on Roblox Store!"),
				"info"
			)
		end
		return true

	elseif cmd == "PromptDevProduct" then
		local productKey = tostring(payload.productKey or payload.key or payload.id or payload.value or "")
		local prod = MonetizationConfig.GetDevProduct(productKey)
		if not prod then
			sendToastAndNotify(
				player,
				LiveOps.Pick(player, "Không tìm thấy vật phẩm tiện ích yêu cầu!", "Requested utility product not found!"),
				"warning"
			)
			return true
		end
		if (tonumber(prod.GoldGrant) or 0) > 0 and LiveOps.IsPaidRandomRestricted(player) then
			sendToastAndNotify(
				player,
				LiveOps.Pick(
					player,
					"Khu vực tài khoản của bạn hạn chế mua Gói Vàng Robux theo chính sách tuân thủ của Roblox. Mọi Lõi Aether & Cổ Ngữ đều cày miễn phí 100% trong game!",
					"Robux Gold Pouches are restricted in your region under Roblox paid-random compliance policy. All Cores & Runes are 100% earnable via F2P gameplay!"
				),
				"info"
			)
			return true
		end
		local prodId = tonumber(prod.ProductId) or 0
		if prodId > 0 then
			local okPrompt, errPrompt = pcall(function()
				MarketplaceService:PromptProductPurchase(player, prodId)
			end)
			if not okPrompt then
				warn("[SKYBREAK][Monetization] PromptProductPurchase error:", errPrompt)
				sendToastAndNotify(
					player,
					LiveOps.Pick(player, "Không thể mở cửa sổ thanh toán Roblox lúc này!", "Unable to open Roblox purchase prompt right now!"),
					"warning"
				)
			end
			return true
		end
		-- ProductId == 0: Studio / DevGate end-to-end receipt test flow vs Live placeholder message
		if DevGate.IsAllowed(player) then
			MonetizationService.StudioReceiptSeq += 1
			local synReceiptId = string.format("studio_%d_%s_%d_%d", player.UserId, prod.Key, os.time(), MonetizationService.StudioReceiptSeq)
			local decision = MonetizationService.ProcessReceipt({
				PlayerId = player.UserId,
				ProductId = 0,
				PurchaseId = synReceiptId,
				_StudioProductKey = prod.Key,
				_SilentNotify = true,
			})
			if decision == Enum.ProductPurchaseDecision.PurchaseGranted then
				sendToastAndNotify(
					player,
					string.format("[STUDIO TEST] Đã kích hoạt thử nghiệm %s (%d R$)!", prod.NameVi, tonumber(prod.PriceRobux) or 0),
					"success"
				)
			else
				sendToastAndNotify(player, "[STUDIO TEST] Không thể lưu giao dịch thử nghiệm lúc này!", "warning")
			end
		else
			sendToastAndNotify(
				player,
				LiveOps.Pick(player, "Sắp mở bán trên Roblox Store!", "Coming soon on Roblox Store!"),
				"info"
			)
		end
		return true
	end

	return false
end

local function bindActiveShipsWatcher()
	local function attachFolder(folder)
		if not folder then
			return
		end
		for _, ch in ipairs(folder:GetChildren()) do
			task.defer(applyGoldenShipCosmetic, ch)
		end
		folder.ChildAdded:Connect(function(ch)
			task.defer(applyGoldenShipCosmetic, ch)
		end)
	end
	local existing = workspace:FindFirstChild("ActiveShips")
	if existing then
		attachFolder(existing)
	else
		workspace.ChildAdded:Connect(function(ch)
			if ch.Name == "ActiveShips" then
				attachFolder(ch)
			end
		end)
	end
end

local function bindPlayerLifecycle(player)
	player.CharacterAdded:Connect(function(ch)
		task.defer(applyCharacterNameAura, player, ch)
	end)
	if player.Character then
		task.defer(applyCharacterNameAura, player, player.Character)
	end
	task.spawn(MonetizationService.SyncPlayerPasses, player, false)
end

function MonetizationService.Start()
	if MonetizationService.Started then
		return
	end
	MonetizationService.Started = true
	registerVipTitleIfPresent()

	MarketplaceService.ProcessReceipt = MonetizationService.ProcessReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(onGamePassPurchaseFinished)

	bindActiveShipsWatcher()

	Players.PlayerAdded:Connect(bindPlayerLifecycle)
	Players.PlayerRemoving:Connect(function(player)
		MonetizationService.LastPromptAt[player] = nil
		if player then
			MonetizationService.SessionPassCache[player.UserId] = nil
		end
	end)
	for _, plr in ipairs(Players:GetPlayers()) do
		bindPlayerLifecycle(plr)
	end
end

return MonetizationService
