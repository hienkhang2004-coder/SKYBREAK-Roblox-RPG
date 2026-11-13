-- SKYBREAK: Fragments of the Core — Fair Utility & Cosmetic Monetization Catalog (D2 / P2-01)
-- Location: ReplicatedStorage/SkybreakShared/Config/MonetizationConfig.lua
-- Strict Fair-Play Policy: Utility & Cosmetics ONLY. Zero Mythic Cores or Robux Gacha!
--
-- ============================================================================
-- CREATOR HUB ID SETUP INSTRUCTIONS (FOR LIVE ROBLOX STORE CHECKOUT)
-- ============================================================================
-- 1. Publish the Place to Roblox via Studio (File -> Publish to Roblox).
-- 2. Open https://create.roblox.com -> Creations -> Experiences -> SKYBREAK -> Monetization:
--    - Under "Passes": Create the 5 GamePasses below (using the 512x512 icons in UI_And_Storefront_Kit)
--      and paste each numeric Pass ID into `GamePassId = <ID>` below.
--    - Under "Developer Products": Create the 5 Developer Products below and paste each numeric
--      Product ID into `ProductId = <ID>` below.
-- 3. While an ID remains `0`, live non-DevGate servers safely display a polite bilingual
--    "Sắp mở bán trên Roblox Store / Coming soon on Roblox Store" notice with zero errors.
-- ============================================================================

local MonetizationConfig = {}

MonetizationConfig.ComingSoonToastVi = "Sắp mở bán trên Roblox Store"
MonetizationConfig.ComingSoonToastEn = "Coming soon on Roblox Store"
MonetizationConfig.PolicyRestrictedToastVi = "Khu vực của bạn hạn chế mua gói tiền tệ dùng cho tính năng ngẫu nhiên theo chính sách Roblox. Bạn vẫn có thể cày Gold & Vé Quay miễn phí 100% trong game!"
MonetizationConfig.PolicyRestrictedToastEn = "Your region restricts purchasing currency bundles tied to randomized features under Roblox Policy. You can still earn 100% of Gold & Spin Tickets free via gameplay!"

MonetizationConfig.FairPlayBannerVi = "100% Công Bằng: Chỉ bán tiện ích & trang trí — Không bán Lõi Thần Thoại hay quay Gacha bằng Robux!"
MonetizationConfig.FairPlayBannerEn = "100% Fair Play: Utility & Cosmetics only — No Mythic Cores or Robux Gacha!"

MonetizationConfig.GamePasses = {
	{
		Key = "x2_exp",
		Id = "x2_exp",
		Kind = "GamePass",
		NameVi = "Đặc Quyền x2 EXP Vĩnh Viễn",
		NameEn = "Permanent 2x EXP Pass",
		DescVi = "Nhân đôi toàn bộ EXP từ Quái, Boss và Nhiệm Vụ vĩnh viễn.",
		DescEn = "Permanently doubles all EXP earned from Enemies, Bosses, and Quests.",
		PriceRobux = 299,
		GamePassId = 0,
		Icon = "PassExp",
		Rarity = "Legendary",
	},
	{
		Key = "x2_gold",
		Id = "x2_gold",
		Kind = "GamePass",
		NameVi = "Đặc Quyền x2 Gold Vĩnh Viễn",
		NameEn = "Permanent 2x Gold Pass",
		DescVi = "Nhân đôi lượng Gold rơi ra từ Quái, Boss và Nhiệm Vụ.",
		DescEn = "Permanently doubles Gold earned from Enemies, Bosses, and Quests.",
		PriceRobux = 249,
		GamePassId = 0,
		Icon = "PassGold",
		Rarity = "Legendary",
	},
	{
		Key = "extra_core_storage",
		Id = "extra_core_storage",
		Kind = "GamePass",
		NameVi = "Mở Rộng Kho Lõi (+3 Ô)",
		NameEn = "Expanded Core Storage (+3)",
		DescVi = "Tăng sức chứa tối đa mỗi loại Lõi Aether trong Kho thêm +3 ô.",
		DescEn = "Increases maximum storage per Aether Core in your Vault by +3.",
		PriceRobux = 199,
		GamePassId = 0,
		Icon = "PassStorage",
		BonusCoreStorage = 3,
		Rarity = "Epic",
	},
	{
		Key = "golden_sky_ship",
		Id = "golden_sky_ship",
		Kind = "GamePass",
		NameVi = "Thuyền Hoàng Kim (Trang Trí)",
		NameEn = "Golden Sovereign Sloop (Cosmetic)",
		DescVi = "Mở khóa ngoại trang Thuyền Hoàng Kim rực sáng (tốc độ cân bằng như thuyền chuẩn).",
		DescEn = "Unlocks the radiant Golden Sovereign Ship skin (balanced standard speed).",
		PriceRobux = 349,
		GamePassId = 0,
		Icon = "PassShip",
		Rarity = "Mythic",
	},
	{
		Key = "sovereign_name_aura",
		Id = "sovereign_name_aura",
		Kind = "GamePass",
		NameVi = "Hào Quang Danh Hiệu Thiên Giới",
		NameEn = "Celestial Nameplate Aura",
		DescVi = "Mở khóa hiệu ứng hào quang danh hiệu Hoàng Kim & huy hiệu VIP.",
		DescEn = "Unlocks the radiant Golden Nameplate Aura & Sovereign title badge.",
		PriceRobux = 99,
		GamePassId = 0,
		Icon = "PassAura",
		Rarity = "Epic",
	},
}

MonetizationConfig.DevProducts = {
	{
		Key = "gold_pouch_s",
		Id = "gold_pouch_s",
		Kind = "DevProduct",
		NameVi = "Túi Gold Nhỏ (+5,000 Gold)",
		NameEn = "Small Gold Pouch (+5,000 Gold)",
		DescVi = "Nhận ngay +5,000 Gold vào túi đồ để rèn vũ khí và nâng cấp thuyền.",
		DescEn = "Instantly grants +5,000 Gold for weapon forging and ship upgrades.",
		GoldGrant = 5000,
		PriceRobux = 49,
		ProductId = 0,
		Icon = "Gold",
		Rarity = "Rare",
	},
	{
		Key = "gold_pouch_m",
		Id = "gold_pouch_m",
		Kind = "DevProduct",
		NameVi = "Rương Gold Vừa (+20,000 Gold)",
		NameEn = "Medium Gold Chest (+20,000 Gold)",
		DescVi = "Nhận ngay +20,000 Gold vào túi đồ để mua trang bị và học Võ Đường.",
		DescEn = "Instantly grants +20,000 Gold for gear and Martial Dojo training.",
		GoldGrant = 20000,
		PriceRobux = 149,
		ProductId = 0,
		Icon = "Gold",
		Rarity = "Epic",
	},
	{
		Key = "gold_pouch_l",
		Id = "gold_pouch_l",
		Kind = "DevProduct",
		NameVi = "Kho Báu Gold Lớn (+60,000 Gold)",
		NameEn = "Large Gold Treasury (+60,000 Gold)",
		DescVi = "Nhận ngay +60,000 Gold vào túi đồ để mở khóa Thần Khí và Chiến Hạm.",
		DescEn = "Instantly grants +60,000 Gold for high-tier weapons and ships.",
		GoldGrant = 60000,
		PriceRobux = 399,
		ProductId = 0,
		Icon = "Gold",
		Rarity = "Legendary",
	},
	{
		Key = "stat_refund",
		Id = "stat_refund",
		Kind = "DevProduct",
		NameVi = "Tẩy Toàn Bộ Điểm Chỉ Số",
		NameEn = "Full Stat Points Refund",
		DescVi = "Hoàn trả toàn bộ Điểm Chỉ Số đã cộng để phân bổ lại theo hướng mới.",
		DescEn = "Refunds all allocated Stat Points so you can respec freely.",
		StatRefund = true,
		PriceRobux = 79,
		ProductId = 0,
		Icon = "Skill",
		Rarity = "Rare",
	},
	{
		Key = "double_exp_30m",
		Id = "double_exp_30m",
		Kind = "DevProduct",
		NameVi = "Buff x2 EXP (30 Phút)",
		NameEn = "2x EXP Boost (30 Minutes)",
		DoubleExpSec = 1800,
		DescVi = "Cộng dồn thời gian x2 EXP (nhân cùng Game Pass x2 EXP!).",
		DescEn = "Adds 30 minutes of 2x EXP (stacks with 2x EXP Game Pass!).",
		PriceRobux = 39,
		ProductId = 0,
		Icon = "Bolt",
		Rarity = "Uncommon",
	},
}

MonetizationConfig.GamePassesByKey = {}
MonetizationConfig.GamePassesById = {}
MonetizationConfig.DevProductsByKey = {}
MonetizationConfig.DevProductsById = {}
MonetizationConfig.ByKey = {}

for _, pass in ipairs(MonetizationConfig.GamePasses) do
	MonetizationConfig.GamePassesByKey[pass.Key] = pass
	MonetizationConfig.ByKey[pass.Key] = pass
	if tonumber(pass.GamePassId) and tonumber(pass.GamePassId) > 0 then
		MonetizationConfig.GamePassesById[tonumber(pass.GamePassId)] = pass
	end
end

for _, prod in ipairs(MonetizationConfig.DevProducts) do
	MonetizationConfig.DevProductsByKey[prod.Key] = prod
	MonetizationConfig.ByKey[prod.Key] = prod
	if tonumber(prod.ProductId) and tonumber(prod.ProductId) > 0 then
		MonetizationConfig.DevProductsById[tonumber(prod.ProductId)] = prod
	end
end

function MonetizationConfig.GetGamePass(keyOrId)
	if type(keyOrId) == "string" then
		return MonetizationConfig.GamePassesByKey[keyOrId]
	end
	local numId = tonumber(keyOrId)
	if numId and numId > 0 then
		if MonetizationConfig.GamePassesById[numId] then
			return MonetizationConfig.GamePassesById[numId]
		end
		for _, pass in ipairs(MonetizationConfig.GamePasses) do
			if tonumber(pass.GamePassId) == numId then
				MonetizationConfig.GamePassesById[numId] = pass
				return pass
			end
		end
	end
	return nil
end

function MonetizationConfig.GetDevProduct(keyOrId)
	if type(keyOrId) == "string" then
		return MonetizationConfig.DevProductsByKey[keyOrId]
	end
	local numId = tonumber(keyOrId)
	if numId and numId > 0 then
		if MonetizationConfig.DevProductsById[numId] then
			return MonetizationConfig.DevProductsById[numId]
		end
		for _, prod in ipairs(MonetizationConfig.DevProducts) do
			if tonumber(prod.ProductId) == numId then
				MonetizationConfig.DevProductsById[numId] = prod
				return prod
			end
		end
	end
	return nil
end

function MonetizationConfig.IsConfigured(itemOrKey)
	local item = itemOrKey
	if type(itemOrKey) == "string" then
		item = MonetizationConfig.ByKey[itemOrKey]
	end
	if type(item) ~= "table" then
		return false
	end
	if item.Kind == "GamePass" or item.GamePassId ~= nil then
		return (tonumber(item.GamePassId) or 0) > 0
	end
	if item.Kind == "DevProduct" or item.ProductId ~= nil then
		return (tonumber(item.ProductId) or 0) > 0
	end
	return false
end

function MonetizationConfig.RequiresPaidRandomPolicyCheck(itemOrKey)
	local item = itemOrKey
	if type(itemOrKey) == "string" then
		item = MonetizationConfig.ByKey[itemOrKey]
	end
	if type(item) ~= "table" then
		return false
	end
	return (tonumber(item.GoldGrant) or 0) > 0
end

return MonetizationConfig
