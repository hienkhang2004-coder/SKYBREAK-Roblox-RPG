-- SKYBREAK: Fragments of the Core — Canonical 8 Public-Launch Badges Configuration
-- Location: ReplicatedStorage/SkybreakShared/BadgeConfig.lua
-- Creator Hub Setup: Create 8 Badges under Experience -> Creations -> Badges and paste their numeric IDs into BadgeId below.
-- When BadgeId == 0, server tracks local profile unlock (profile.UnlockedBadges[Id] = true) without BadgeService errors.

local BadgeConfig = {}

BadgeConfig.Badges = {
	{
		Order = 1,
		Id = "welcome_skyborn",
		Key = "welcome_skyborn",
		BadgeId = 0, -- Paste Roblox Badge ID after publishing
		Rarity = "Rare",
		Icon = "Sword",
		TitleVi = "Tân Chiến Binh Bầu Trời",
		TitleEn = "Skyborn Initiate",
		NameVi = "Tân Chiến Binh Bầu Trời",
		NameEn = "Skyborn Initiate",
		DescVi = "Đặt chân tới Thành Phố Sky Hub và hoàn thành huấn luyện khởi đầu Q01.",
		DescEn = "Arrive at Sky Hub Sanctuary and complete starter training quest Q01.",
	},
	{
		Order = 2,
		Id = "first_aether_core",
		Key = "first_aether_core",
		BadgeId = 0, -- Paste Roblox Badge ID after publishing
		Rarity = "Epic",
		Icon = "Fruit",
		TitleVi = "Khế Ước Lõi Aether",
		TitleEn = "First Aether Core",
		NameVi = "Khế Ước Lõi Aether",
		NameEn = "First Aether Core",
		DescVi = "Cầu nguyện hoặc hấp thụ Lõi Aether đầu tiên tại Điện Hiền Giả Zioles.",
		DescEn = "Roll or attune your very first Aether Core at Oracle Zioles' Shrine.",
	},
	{
		Order = 3,
		Id = "aureon_slayer",
		Key = "aureon_slayer",
		BadgeId = 0, -- Paste Roblox Badge ID after publishing
		Rarity = "Epic",
		Icon = "Shield",
		TitleVi = "Kẻ Phá Vỡ Hào Quang",
		TitleEn = "Warden of Dawnbreaker",
		NameVi = "Kẻ Phá Vỡ Hào Quang",
		NameEn = "Warden of Dawnbreaker",
		DescVi = "Đánh bại Boss Aureon Sentinel tại Tháp Phán Quyết (Tầng Trời 1).",
		DescEn = "Vanquish Aureon Sentinel in the Sun Citadel Arena (Sky 1).",
	},
	{
		Order = 4,
		Id = "sea2_cyberport",
		Key = "sea2_cyberport",
		BadgeId = 0, -- Paste Roblox Badge ID after publishing
		Rarity = "Legendary",
		Icon = "Compass",
		TitleVi = "Lữ Khách Băng Thành",
		TitleEn = "Frozen Cyber Voyager",
		NameVi = "Lữ Khách Băng Thành",
		NameEn = "Frozen Cyber Voyager",
		DescVi = "Đạt Cấp 700 và mở khóa hành trình tới Tầng Trời 2 • Frozen Cyber.",
		DescEn = "Reach Level 700 and unlock passage into Sky 2 • Frozen Cyber.",
	},
	{
		Order = 5,
		Id = "cryon_slayer",
		Key = "cryon_slayer",
		BadgeId = 0, -- Paste Roblox Badge ID after publishing
		Rarity = "Legendary",
		Icon = "Frost",
		TitleVi = "Chinh Phục Tuyệt Độ",
		TitleEn = "Sub-Zero Conqueror",
		NameVi = "Chinh Phục Tuyệt Độ",
		NameEn = "Sub-Zero Conqueror",
		DescVi = "Đánh bại Băng Đế Cryon Prime và khai mở cánh cổng Hư Không Tầng Trời 3.",
		DescEn = "Defeat Cryon Prime and unseal the Void Gate to Sky 3 • Shadow Realm.",
	},
	{
		Order = 6,
		Id = "awakened_core_v2",
		Key = "awakened_core_v2",
		BadgeId = 0, -- Paste Roblox Badge ID after publishing
		Rarity = "Legendary",
		Icon = "Bolt",
		TitleVi = "Thức Tỉnh Lõi Cực Hạn",
		TitleEn = "Awakened Core Sovereign",
		NameVi = "Thức Tỉnh Lõi Cực Hạn",
		NameEn = "Awakened Core Sovereign",
		DescVi = "Vượt Đấu Trường Giải Mã Lõi và Thức Tỉnh V2 một Lõi Aether bất kỳ.",
		DescEn = "Clear the Microchip Raid Lab and awaken any Aether Core to V2.",
	},
	{
		Order = 7,
		Id = "leviathan_slayer",
		Key = "leviathan_slayer",
		BadgeId = 0, -- Paste Roblox Badge ID after publishing
		Rarity = "Mythic",
		Icon = "Crown",
		TitleVi = "Thợ Săn Thủy Xà Vực Thẳm",
		TitleEn = "Abyssal Leviathan Slayer",
		NameVi = "Thợ Săn Thủy Xà Vực Thẳm",
		NameEn = "Abyssal Leviathan Slayer",
		DescVi = "Hạ gục Đại Thủy Xà Vực Thẳm và kéo Trái Tim Thủy Xà về cảng an toàn.",
		DescEn = "Slay the Abyssal Leviathan and harpoon-tow its Heart back to port.",
	},
	{
		Order = 8,
		Id = "apex_architect_2550",
		Key = "apex_architect_2550",
		BadgeId = 0, -- Paste Roblox Badge ID after publishing
		Rarity = "Mythic",
		Icon = "Core",
		TitleVi = "Đỉnh Cao Thiên Giới Lv.2550",
		TitleEn = "Apex Skyborn (Lv. 2550)",
		NameVi = "Đỉnh Cao Thiên Giới Lv.2550",
		NameEn = "Apex Skyborn (Lv. 2550)",
		DescVi = "Chạm mốc Cấp Độ Tối Đa 2550 hoặc khuất phục Đấng Kiến Tạo Veyr tại Veil's End.",
		DescEn = "Reach Max Level 2550 or defeat Veyr, The First Architect at Veil's End.",
	},
}

BadgeConfig.ById = {}
for _, b in ipairs(BadgeConfig.Badges) do
	BadgeConfig.ById[b.Id] = b
end

function BadgeConfig.Get(badgeKey)
	if type(badgeKey) ~= "string" then
		return nil
	end
	return BadgeConfig.ById[badgeKey]
end

function BadgeConfig.IsConfigured(badgeOrKey)
	local b = type(badgeOrKey) == "table" and badgeOrKey or BadgeConfig.Get(badgeOrKey)
	return type(b) == "table" and (tonumber(b.BadgeId) or 0) > 0
end

return BadgeConfig
