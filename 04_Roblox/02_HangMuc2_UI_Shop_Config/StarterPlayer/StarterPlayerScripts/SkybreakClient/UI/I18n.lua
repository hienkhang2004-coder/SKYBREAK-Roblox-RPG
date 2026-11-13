--!strict
--[[
	I18n.lua (#94)
	Lightweight Bilingual Localization Module (Vietnamese default + English)
	Synced directly with LocalPlayer:GetAttribute("Language") ("vi" | "en").
]]

local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local SharedConfig: any = nil
task.spawn(function()
	local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
	local cfgMod = sharedFolder and sharedFolder:FindFirstChild("Config")
	if cfgMod and cfgMod:IsA("ModuleScript") then
		local ok, mod = pcall(require, cfgMod)
		if ok then
			SharedConfig = mod
		end
	end
end)

local I18n = {}

-- Viet hoa ho tro tieng Viet: string.upper chi doi chu ASCII nen "Kiếm" thanh "KIếM".
local VI_UPPER = {}
do
	local lowerChars = "àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ"
	local upperChars = "ÀÁẢÃẠĂẰẮẲẴẶÂẦẤẨẪẬÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴĐ"
	local ups = {}
	for _, cp in utf8.codes(upperChars) do
		table.insert(ups, utf8.char(cp))
	end
	local i = 0
	for _, cp in utf8.codes(lowerChars) do
		i += 1
		VI_UPPER[utf8.char(cp)] = ups[i]
	end
end

function I18n.Upper(text)
	local s = string.upper(tostring(text or ""))
	return (string.gsub(s, utf8.charpattern, VI_UPPER))
end

local CurrentLang: string = "en"
local Listeners: { (string) -> () } = {}

local function normalizeLang(raw: any): string
	if type(raw) == "string" then
		local lower = string.lower(raw)
		if lower == "vi" or lower == "vn" or lower == "vietnamese" or string.sub(lower, 1, 2) == "vi" then
			return "vi"
		end
	end
	return "en"
end

local function detectDefaultLanguage(): string
	if LocalPlayer then
		local existing = LocalPlayer:GetAttribute("Language") or LocalPlayer:GetAttribute("Locale")
		if type(existing) == "string" and existing ~= "" then
			return normalizeLang(existing)
		end
	end

	local okSys, sysLocale = pcall(function()
		return LocalizationService.SystemLocaleId
	end)
	local okRbx, rbxLocale = pcall(function()
		return LocalizationService.RobloxLocaleId
	end)

	local sysPrefix = okSys and type(sysLocale) == "string" and string.sub(string.lower(sysLocale), 1, 2) or ""
	local rbxPrefix = okRbx and type(rbxLocale) == "string" and string.sub(string.lower(rbxLocale), 1, 2) or ""

	if rbxPrefix == "vi" or sysPrefix == "vi" then
		return "vi"
	end
	return "en"
end

CurrentLang = detectDefaultLanguage()

if LocalPlayer then
	pcall(function()
		LocalPlayer:SetAttribute("Language", CurrentLang)
	end)

	LocalPlayer:GetAttributeChangedSignal("Language"):Connect(function()
		local nextLang = normalizeLang(LocalPlayer:GetAttribute("Language"))
		if nextLang ~= CurrentLang then
			CurrentLang = nextLang
			for _, fn in ipairs(table.clone(Listeners)) do
				task.spawn(fn, CurrentLang)
			end
		end
	end)
end

I18n.Dict = {
	vi = {
		-- Shared Navigation Tabs (#10, #91)
		["nav.hud"] = "CHIẾN ĐẤU [ESC]",
		["nav.fruits"] = "KHO LÕI [G]",
		["nav.inventory"] = "TÚI ĐỒ [I]",
		["nav.skills"] = "KỸ NĂNG [K]",
		["nav.forge"] = "LÒ RÈN",
		["nav.map"] = "BẢN ĐỒ [M]",
		["nav.quests"] = "NHẬT KÝ [L]",
		["nav.raid"] = "ĐỘT KÍCH",
		["nav.settings"] = "CÀI ĐẶT [O]",
		["nav.menu"] = "TRANG CHỦ",
		["nav.resume"] = "ĐÓNG [ESC]",

		-- Viewport Orbit Hint (#9)
		["orbit.hint"] = "Kéo để xoay 360° • Lăn chuột để Zoom",

		-- HUD (#10, #50, #92, #96, #125)
		["hud.hp"] = "SINH LỰC",
		["hud.energy"] = "NĂNG LƯỢNG",
		["hud.exp"] = "KINH NGHIỆM",
		["hud.squad"] = "ĐỘI HÌNH SKYBORN",
		["hud.minimap_title"] = "LA BÀN THIÊN GIỚI [M]",
		["hud.fruit_radar"] = "Lõi Tự Nhiên: %s (%dm)",
		["hud.buff.haki_arm"] = "Giáp Ý Chí [J]",
		["hud.buff.haki_ken"] = "Thấu Ý (%d Né)",
		["hud.buff.race_v4"] = "Thăng Hoa [Y]",
		["hud.buff.x2_exp"] = "X2 EXP (%s)",
		["hud.buff.shield"] = "Khiên Hộ Thể",
		["hud.buff.transform"] = "Hóa Hình Thần Thú",
		["hud.slot.1"] = "VÕ THUẬT",
		["hud.slot.2"] = "LÕI AETHER",
		["hud.slot.3"] = "THẦN KIẾM",
		["hud.slot.4"] = "PHÁP KHÍ",

		-- Quest Tracker & Journal (#91)
		["quest.tracker_header"] = "NHẬT KÝ NHIỆM VỤ",
		["quest.none"] = "Chưa ghim nhiệm vụ nào",
		["quest.title"] = "NHẬT KÝ NHIỆM VỤ [L]",
		["quests.title"] = "NHẬT KÝ NHIỆM VỤ [L]",

		-- Forge & Star Ascension (#3, #104)
		["forge.title"] = "LÒ RÈN THẦN KHÍ KAEL [F]",
		["forge.tab_craft"] = "RÈN THẦN KHÍ",
		["forge.tab_enhance"] = "CƯỜNG HÓA +15",
		["forge.tab_star"] = "THĂNG SAO *5",
		["forge.btn_craft"] = "RÈN THẦN KHÍ",
		["forge.btn_enhance"] = "CƯỜNG HÓA",
		["forge.btn_star"] = "NÂNG CẤP SAO *5",
		["forge.pity_label"] = "Chúc Phúc Tinh Tú (Pity): %d%%",

		-- Fruits & Gacha (#7, #11)
		["fruits.title"] = "KHO LÕI AETHER [G]",
		["fruits.eat"] = "Hấp Thụ Lõi Này",
		["fruits.hold"] = "Cầm 3D Trên Tay",
		["fruits.store"] = "Cất Vào Kho",
		["fruits.awaken_on"] = "Tắt Lõi Thức Tỉnh",
		["fruits.awaken_off"] = "Lõi Thức Tỉnh",
		["fruits.spin_btn"] = "Quay Gacha Hiền Giả Aether",
		["fruits.spin_rolling"] = "HIỀN GIẢ AETHER ĐANG TRIỆU HỒI LÕI AETHER...",
		["fruits.spin_won"] = "CHÚC MỪNG NHẬN ĐƯỢC!",
		["fruits.cd_fmt"] = "Hồi: %ss",
		["fruits.odds_header"] = "TỶ LỆ CẦU LÕI AETHER • GACHA DROP RATES",
		["fruits.odds_btn"] = "BẢNG TỶ LỆ",

		-- Inventory & Diff (#3, #97)
		["inv.title"] = "TÚI ĐỒ & TRANG BỊ [I]",
		["inv.view_weapon"] = "XEM VŨ KHÍ 3D",
		["inv.view_hero"] = "XEM NHÂN VẬT 3D",
		["inv.vs_equipped"] = "SO VỚI ĐANG MẶC",

		-- Skills & Presets (#60)
		["skills.title"] = "KỸ NĂNG & CHỈ SỐ [K]",
		["skills.preset_1"] = "Cấu Hình 1: Võ Sĩ",
		["skills.preset_2"] = "Cấu Hình 2: Kiếm Thánh",
		["skills.preset_3"] = "Cấu Hình 3: Lõi Aether",
		["skills.save"] = "LƯU",
		["skills.load"] = "NẠP",
		["skills.refund"] = "TẨY ĐIỂM (STAT REFUND)",
		["skills.arsenal_header"] = "CƠ CHẾ THỰC CHIẾN 4 Ô VŨ KHÍ & LÕI ĐANG CẦM",
		["skills.arsenal_sub"] = " Kiểu Đòn (Archetype) & Nhãn Cơ Chế (Tags) trực tiếp từ Ô [1]–[4]",

		-- World Map & Bestiary (#61, #99)
		["map.title"] = "BẢN ĐỒ TAM TẦNG TRỜI & ĐẢO TRỜI [M]",
		["map.here"] = "BẠN ĐANG Ở ĐÂY",
		["map.teleport"] = "Dịch Chuyển Nhanh",
		["map.codex_tab"] = "CODEX / TỈ LỆ RỚT ĐỒ",
		["map.islands_tab"] = "DANH SÁCH ĐẢO",
		["map.boss_alive"] = "BOSS ĐANG SỐNG",
		["map.boss_respawn"] = "ĐANG HỒI SINH",

		-- Raid (#6)
		["raid.title"] = "ĐẤU TRƯỜNG ĐỘT KÍCH BOSS [P]",

		-- Settings (#94, #100, #123)
		["settings.title"] = "CÀI ĐẶT HỆ THỐNG & GIFTCODE [O]",
		["settings.language"] = "Ngôn Ngữ / Language",
		["settings.lowfx"] = "Chế Độ Giảm Hiệu Ứng (Low FX -65% Hạt)",
		["settings.gfx_title"] = "CHẾ ĐỘ ĐỒ HỌA & VFX 3 CẤP ĐỘ",
		["settings.gfx_ultra"] = "ĐIỆN ẢNH TỐI ĐA",
		["settings.gfx_balanced"] = "CÂN BẰNG",
		["settings.gfx_smooth"] = "MƯỢT NHẸ",
		["settings.gfx_desc_ultra"] = "Trọn bộ VFX 5 lớp, mây thể tích 3D, ánh sáng & bóng đổ điện ảnh tối đa (Mặc định PC).",
		["settings.gfx_desc_balanced"] = "Cân bằng sắc nét 60 FPS: giữ trọn khung chiêu thực chiến & mây trời tối ưu (Mặc định Mobile).",
		["settings.gfx_desc_smooth"] = "Ưu tiên FPS tối đa cho máy yếu: tự đồng bộ Low FX (-65% hạt) & tắt bóng đổ nặng.",
		["settings.giftcode_title"] = "NHẬP MÃ QUÀ TẶNG (GIFTCODE)",
		["settings.giftcode_placeholder"] = "Nhập Mã Quà Tặng (Giftcode)...",
		["settings.giftcode_btn"] = "NHẬN QUÀ",
		["settings.master_vol"] = "Âm Lượng Tổng",
		["settings.bgm_vol"] = "Nhạc Nền (BGM)",
		["settings.sfx_vol"] = "Hiệu Ứng Chiêu (SFX)",
		["settings.auto_lowfx"] = "Tự gợi ý Low FX khi tụt FPS < 28",

		-- Main Menu (#93)
		["menu.enter"] = "VÀO THẾ GIỚI",
		["menu.vista_badge"] = "KHUNG CẢNH TRỰC TIẾP 3D • SKY HUB",
	},
	en = {
		-- Shared Navigation Tabs (#10, #91)
		["nav.hud"] = "COMBAT HUD [ESC]",
		["nav.fruits"] = "CORES [G]",
		["nav.inventory"] = "INVENTORY [I]",
		["nav.skills"] = "SKILLS [K]",
		["nav.forge"] = "FORGE",
		["nav.map"] = "WORLD MAP [M]",
		["nav.quests"] = "QUESTS [L]",
		["nav.raid"] = "BOSS RAID",
		["nav.settings"] = "SETTINGS [O]",
		["nav.menu"] = "MAIN MENU",
		["nav.resume"] = "CLOSE [ESC]",

		-- Viewport Orbit Hint (#9)
		["orbit.hint"] = "Drag to rotate 360° • Scroll to Zoom",

		-- HUD (#10, #50, #92, #96, #125)
		["hud.hp"] = "HEALTH",
		["hud.energy"] = "ENERGY",
		["hud.exp"] = "EXPERIENCE",
		["hud.squad"] = "SKYBORN SQUAD",
		["hud.minimap_title"] = "CELESTIAL RADAR [M]",
		["hud.fruit_radar"] = "Natural Core: %s (%dm)",
		["hud.buff.haki_arm"] = "Will Armor [J]",
		["hud.buff.haki_ken"] = "Will Sense (%d Dodges)",
		["hud.buff.race_v4"] = "Ascension Awakened [Y]",
		["hud.buff.x2_exp"] = "2X EXP (%s)",
		["hud.buff.shield"] = "Aegis Barrier",
		["hud.buff.transform"] = "Beast Transformation",
		["hud.slot.1"] = "MELEE",
		["hud.slot.2"] = "AETHER CORE",
		["hud.slot.3"] = "SWORD",
		["hud.slot.4"] = "ARCANE GUN",

		-- Quest Tracker & Journal (#91)
		["quest.tracker_header"] = "QUEST TRACKER",
		["quest.none"] = "No active quest pinned",
		["quest.title"] = "QUEST JOURNAL [L]",
		["quests.title"] = "QUEST JOURNAL [L]",

		-- Forge & Star Ascension (#3, #104)
		["forge.title"] = "KAEL'S CELESTIAL FORGE [F]",
		["forge.tab_craft"] = "CRAFT WEAPONS",
		["forge.tab_enhance"] = "ENHANCE +15",
		["forge.tab_star"] = "STAR ASCEND *5",
		["forge.btn_craft"] = "FORGE WEAPON",
		["forge.btn_enhance"] = "ENHANCE",
		["forge.btn_star"] = "ASCEND STAR *5",
		["forge.pity_label"] = "Astral Pity Blessing: %d%%",

		-- Fruits & Gacha (#7, #11)
		["fruits.title"] = "AETHER CORES [G]",
		["fruits.eat"] = "Absorb Core",
		["fruits.hold"] = "Hold 3D Core",
		["fruits.store"] = "Store in Vault",
		["fruits.awaken_on"] = "Disable Awakened Core",
		["fruits.awaken_off"] = "Awakened Core",
		["fruits.spin_btn"] = "Spin Aether Oracle Gacha",
		["fruits.spin_rolling"] = "AETHER ORACLE IS CHANNELLING AETHER CORES...",
		["fruits.spin_won"] = "CONGRATULATIONS! YOU OBTAINED:",
		["fruits.cd_fmt"] = "CD: %ss",
		["fruits.odds_header"] = "AETHER CORE GACHA DROP RATES",
		["fruits.odds_btn"] = "ODDS TABLE",

		-- Inventory & Diff (#3, #97)
		["inv.title"] = "INVENTORY & GEAR [I]",
		["inv.view_weapon"] = "3D WEAPON VIEW",
		["inv.view_hero"] = "3D HERO VIEW",
		["inv.vs_equipped"] = "VS EQUIPPED",

		-- Skills & Presets (#60)
		["skills.title"] = "SKILLS & STAT MASTERY [K]",
		["skills.preset_1"] = "Preset 1: Brawler",
		["skills.preset_2"] = "Preset 2: Swordmaster",
		["skills.preset_3"] = "Preset 3: Core Sovereign",
		["skills.save"] = "SAVE",
		["skills.load"] = "LOAD",
		["skills.refund"] = "STAT REFUND (RESET)",
		["skills.arsenal_header"] = "EQUIPPED 4-SLOT ARSENAL MECHANICS",
		["skills.arsenal_sub"] = "Live Archetypes & Mechanical Tags for your equipped Slots [1]–[4]",

		-- World Map & Bestiary (#61, #99)
		["map.title"] = "GRAND SKY TIERS WORLD MAP [M]",
		["map.here"] = "YOU ARE HERE",
		["map.teleport"] = "Fast Travel",
		["map.codex_tab"] = "CODEX / DROP RATES",
		["map.islands_tab"] = "SKY ISLANDS",
		["map.boss_alive"] = "BOSS ALIVE",
		["map.boss_respawn"] = "RESPAWNING",

		-- Raid (#6)
		["raid.title"] = "BOSS RAID ARENA [P]",

		-- Settings (#94, #100, #123)
		["settings.title"] = "SYSTEM SETTINGS & GIFTCODES [O]",
		["settings.language"] = "Language / Ngôn Ngữ",
		["settings.lowfx"] = "Low FX Mode (-65% Particles & No Shadows)",
		["settings.gfx_title"] = "3-TIER GRAPHICS & VFX MODE",
		["settings.gfx_ultra"] = "ULTRA CINEMA",
		["settings.gfx_balanced"] = "BALANCED",
		["settings.gfx_smooth"] = "MOBILE SMOOTH",
		["settings.gfx_desc_ultra"] = "Full 5-layer VFX, volumetric 3D clouds, dynamic lighting & shadows (Desktop Default).",
		["settings.gfx_desc_balanced"] = "Crisp 60 FPS balance: clear combat silhouettes & optimized sky rendering (Mobile Default).",
		["settings.gfx_desc_smooth"] = "Max FPS for low-end devices: syncs Low FX (-65% particles) & disables heavy shadows.",
		["settings.giftcode_title"] = "REDEEM PROMO GIFTCODE",
		["settings.giftcode_placeholder"] = "Enter Promo Giftcode...",
		["settings.giftcode_btn"] = "REDEEM",
		["settings.master_vol"] = "Master Volume",
		["settings.bgm_vol"] = "BGM Volume",
		["settings.sfx_vol"] = "SFX Volume",
		["settings.auto_lowfx"] = "Auto-Suggest Low FX (< 28 FPS)",

		-- Main Menu (#93)
		["menu.enter"] = "ENTER SKYBREAK",
		["menu.vista_badge"] = "LIVE 3D SKY HUB DIORAMA",
	},
}

local ITEM_NAME_VI: { [string]: string } = {
	-- Fighting Styles (Slot 1 — canonical snake_case + legacy PascalCase aliases)
	skyborn_combat = "Võ Thuật Skyborn",
	SkybornCombat = "Võ Thuật Skyborn",
	SkyStep = "Bộ Không",
	jade_dragon = "Long Quyền Ngọc Bích",
	JadeDragon = "Long Quyền Ngọc Bích",
	GlacialFist = "Long Quyền Ngọc Bích",
	thunder_talon = "Lôi Trảo Cước",
	ThunderTalon = "Lôi Trảo Cước",
	ElectricClaw = "Lôi Trảo Cước",
	solar_ashura = "Thái Dương Tu La",
	SolarAshura = "Thái Dương Tu La",
	AbyssalTalon = "Thái Dương Tu La",
	celestial_godhuman = "Thần Quyền Lục Giới",
	CelestialGodhuman = "Thần Quyền Lục Giới",
	SanguineVoidArt = "Huyết Hư Không Quyền",
	sanguine_void_art = "Huyết Hư Không Quyền",
	ChronoVoidPalm = "Chưởng Pháp Thời Không",
	chrono_void_palm = "Chưởng Pháp Thời Không",

	-- Aether Fruits (Slot 2)
	GaleCore = "Lõi Gió",
	SandstoneCore = "Lõi Cát Vàng",
	SolarFlameCore = "Lõi Lửa Mặt Trời",
	GlacierIceCore = "Lõi Băng Vĩnh Cửu",
	CelestialLightCore = "Lõi Ánh Sáng",
	StarforgedMagmaCore = "Lõi Dung Nham",
	ThunderRumbleCore = "Lõi Lôi Đình",
	AstralGravityCore = "Lõi Trọng Lực",
	DimensionalPortalCore = "Lõi Khe Nứt",
	SolarTitanCore = "Lõi Kim Thân",
	AetherflowCore = "Lõi Tinh Thể",
	AbyssalSovereignCore = "Lõi Long Vương Hư Không",

	-- Swords & Weapons (Slot 3)
	starter_sword = "Kiếm Skyborn",
	starter_daggers = "Song Đao Skyborn",
	starter_staff = "Trượng Arcane",
	dawnbringer_sword = "Thánh Kiếm Ban Mai",
	Dawnbringer = "Thánh Kiếm Ban Mai",
	stormfang_daggers = "Song Đao Lôi Đình",
	Stormfang = "Song Đao Lôi Đình",
	astral_staff = "Quyền Trượng Tinh Cầu",
	EternalFrost = "Quyền Trượng Băng Giá",
	saber_of_aureon = "Đại Kiếm Thánh Quang",
	cryon_frostblade = "Tuyệt Độ Hàn Đao",
	cursed_dual_skyblades = "Song Kiếm Nguyệt Thực",
	CursedDualSkyblades = "Song Kiếm Nguyệt Thực",
	noxar_abyssal_greatsword = "Hắc Kiếm Hư Không",
	noxar_greatsword = "Đại Kiếm Hắc Tinh Noxar",
	abyssal_greatsword = "Đại Kiếm Vực Thẳm",
	yamo_voidblade = "Yêu Đao Hư Không Yamo",
	ArchitectsSeverance = "Thần Kiếm Kiến Tạo",

	-- Guns (Slot 4)
	aether_flintlock = "Súng Lục Aether",
	solar_kabucha = "Ná Gió Mặt Trời",
	kabucha_wind = "Ná Gió Mặt Trời",
	KabuchaSling = "Ná Gió Mặt Trời",
	cryo_railgun = "Pháo Từ Trường Băng",
	soul_guitar_void = "Đàn Hồn Hư Không",
	SoulGuitar = "Đàn Hồn Hư Không",

	-- Armor, Shields, Rings & Artifacts (8-Slot Equipment)
	SkyHelm = "Mũ Giáp Skyborn",
	CelestialPlate = "Chiến Giáp Thiên Khiên",
	StarlightGauntlets = "Hộ Uyển Tinh Quang",
	WindstriderGreaves = "Chiến Hài Phong Hành",
	AureonCrestShield = "Khiên Hộ Vệ Aureon",
	SolarBand = "Nhẫn Thái Dương",
	CoreShardArtifact = "Cổ Vật Mảnh Lõi",
	skyward_helm = "Mũ Giáp Tiên Phong Thiên Thanh",
	skyward_chest = "Chiến Giáp Thiên Vũ",
	skyward_gloves = "Hộ Uyển Thiên Không",
	skyward_boots = "Chiến Hài Lướt Gió",
	aether_ring = "Nhẫn Tinh Cầu Aether",
	celestial_necklace = "Dây Chuyền Ánh Sao",
	core_artifact = "Thánh Vật Ánh Sáng",
	leviathan_shield = "Khiên Thủy Xà Vực Thẳm",
	nerith_leviathan_ring = "Nhẫn Thủy Xà Vực Thẳm Nerith",
	sovereign_cloak = "Áo Choàng Đế Vương Hư Không",
	aion_chrono_cloak = "Áo Choàng Thời Gian Aion",

	-- Crafting Materials, Quest Items & Currencies
	upgrade_material = "Hợp Kim Ánh Sáng",
	SkyIron = "Thiết Tinh Không",
	SkyCrystal = "Pha Lê Bầu Trời",
	SunshardCore = "Lõi Thái Dương",
	CelestialFeather = "Lông Vũ Thiên Giới",
	CoreEssence = "Tinh Chất Lõi Cổ Đại",
	CoreOfLight = "Lõi Ánh Sáng (Core of Light)",
	DawnbringerBlueprint = "Bản Vẽ Dawnbringer",
	VoidShard = "Mảnh Hư Không",
	VoidEssence = "Tinh Chất Hư Không",
	BossKey = "Chìa Khóa Tháp Ánh Sáng",
	EnchantScroll = "Cuộn Phù Phép Cổ Ngữ",
	RandomFruitBox = "Rương Lõi Aether Bí Ẩn",
	BlueResonanceGear = "Bánh Răng Cộng Hưởng Xanh",
	CoreGear = "Bánh Răng Thăng Hoa",
	LeviathanHeart = "Trái Tim Thủy Xà Vực Thẳm",
	AwakeningMicrochip = "Chip Lõi Thức Tỉnh",
	CoreShards = "Tinh Thạch Lõi (Core Shards)",
	Gold = "Vàng (Gold)",
}

local ITEM_NAME_EN: { [string]: string } = {
	-- Fighting Styles (Slot 1 — canonical snake_case + legacy PascalCase aliases)
	skyborn_combat = "Skyborn Combat",
	SkybornCombat = "Skyborn Combat",
	SkyStep = "Sky Step",
	jade_dragon = "Jade Dragon Fist",
	JadeDragon = "Jade Dragon Fist",
	GlacialFist = "Jade Dragon Fist",
	thunder_talon = "Thunder Talon",
	ThunderTalon = "Thunder Talon",
	ElectricClaw = "Thunder Talon",
	solar_ashura = "Solar Ashura Fist",
	SolarAshura = "Solar Ashura Fist",
	AbyssalTalon = "Solar Ashura Fist",
	celestial_godhuman = "Celestial Ascendant",
	CelestialGodhuman = "Celestial Ascendant",
	SanguineVoidArt = "Sanguine Void Art",
	sanguine_void_art = "Sanguine Void Art",
	ChronoVoidPalm = "Chrono Void Palm",
	chrono_void_palm = "Chrono Void Palm",

	-- Aether Fruits (Slot 2)
	GaleCore = "Gale Core",
	SandstoneCore = "Sandstone Core",
	SolarFlameCore = "Solar Flame Core",
	GlacierIceCore = "Glacier Ice Core",
	CelestialLightCore = "Celestial Light Core",
	StarforgedMagmaCore = "Starforged Magma",
	ThunderRumbleCore = "Thunder Rumble",
	AstralGravityCore = "Astral Gravity",
	DimensionalPortalCore = "Rift Core",
	SolarTitanCore = "Colossus Core",
	AetherflowCore = "Aetherflow Core",
	AbyssalSovereignCore = "Abyssal Sovereign",

	-- Swords & Weapons (Slot 3)
	starter_sword = "Skyborn Blade",
	starter_daggers = "Skyborn Twinblades",
	starter_staff = "Arcane Staff",
	dawnbringer_sword = "Dawnbringer",
	Dawnbringer = "Dawnbringer",
	stormfang_daggers = "Stormfang Twinblades",
	Stormfang = "Stormfang Twinblades",
	astral_staff = "Chronostaff",
	EternalFrost = "Eternal Frost",
	saber_of_aureon = "Saber of Aureon",
	cryon_frostblade = "Cryon Frostblade",
	cursed_dual_skyblades = "Eclipse Twinblades",
	CursedDualSkyblades = "Eclipse Twinblades",
	noxar_abyssal_greatsword = "Noxar Abyssal Greatsword",
	noxar_greatsword = "Noxar Greatsword",
	abyssal_greatsword = "Abyssal Greatsword",
	yamo_voidblade = "Yamo Voidblade",
	ArchitectsSeverance = "Architect's Severance",

	-- Guns (Slot 4)
	aether_flintlock = "Aether Flintlock",
	solar_kabucha = "Sunwind Sling",
	kabucha_wind = "Sunwind Sling",
	KabuchaSling = "Sunwind Sling",
	cryo_railgun = "Cryo Railgun",
	soul_guitar_void = "Void Lyre",
	SoulGuitar = "Void Lyre",

	-- Armor, Shields, Rings & Artifacts (8-Slot Equipment)
	SkyHelm = "Skyborn Vanguard Helm",
	CelestialPlate = "Celestial Aegis Plate",
	StarlightGauntlets = "Starlight Gauntlets",
	WindstriderGreaves = "Windstrider Greaves",
	AureonCrestShield = "Aureon Crest Bulwark",
	SolarBand = "Solar Band",
	CoreShardArtifact = "Astral Core Reliquary",
	skyward_helm = "Azure Vanguard Helm",
	skyward_chest = "Skyward Aegis Armor",
	skyward_gloves = "Skyward Gauntlets",
	skyward_boots = "Windwalker Greaves",
	aether_ring = "Aether Orb Ring",
	celestial_necklace = "Starlight Pendant",
	core_artifact = "Core of Light Reliquary",
	leviathan_shield = "Abyss Serpent Shield",
	nerith_leviathan_ring = "Nerith Abyss Serpent Ring",
	sovereign_cloak = "Void Sovereign Mantle",
	aion_chrono_cloak = "Aion Chrono Cloak",

	-- Crafting Materials, Quest Items & Currencies
	upgrade_material = "Luminous Alloy",
	SkyIron = "Sky Iron",
	SkyCrystal = "Sky Crystal",
	SunshardCore = "Sunshard Core",
	CelestialFeather = "Celestial Feather",
	CoreEssence = "Core Essence",
	CoreOfLight = "Core of Light",
	DawnbringerBlueprint = "Dawnbringer Blueprint",
	VoidShard = "Void Shard",
	VoidEssence = "Void Essence",
	BossKey = "Sun Citadel Key",
	EnchantScroll = "Arcane Enchant Scroll",
	RandomFruitBox = "Mystery Aether Core Chest",
	BlueResonanceGear = "Blue Resonance Gear",
	CoreGear = "Ascension Core Gear",
	LeviathanHeart = "Abyss Serpent Heart",
	AwakeningMicrochip = "Awakened Core Microchip",
	CoreShards = "Core Shards",
	Gold = "Gold",
}

function I18n.GetLanguage(): string
	if LocalPlayer then
		local attr = LocalPlayer:GetAttribute("Language")
		if attr ~= nil then
			CurrentLang = normalizeLang(attr)
		end
	end
	return CurrentLang
end

function I18n.IsEnglish(): boolean
	return I18n.GetLanguage() == "en"
end

function I18n.SetLanguage(lang: string)
	local nextLang = normalizeLang(lang)
	local changed = (nextLang ~= CurrentLang)
	CurrentLang = nextLang
	if LocalPlayer then
		pcall(function()
			LocalPlayer:SetAttribute("Language", nextLang)
		end)
	end
	if changed then
		for _, fn in ipairs(table.clone(Listeners)) do
			task.spawn(function()
				pcall(fn, CurrentLang)
			end)
		end
	end
end

function I18n.OnChanged(callback: (string) -> ()): () -> ()
	if type(callback) ~= "function" then
		return function() end
	end
	table.insert(Listeners, callback)
	return function()
		local idx = table.find(Listeners, callback)
		if idx then
			table.remove(Listeners, idx)
		end
	end
end

function I18n.OnLanguageChanged(callback: (string) -> ()): () -> ()
	return I18n.OnChanged(callback)
end

function I18n.T(key: string, ...: any): string
	local lang = I18n.GetLanguage()
	local tableForLang = I18n.Dict[lang] or I18n.Dict.vi
	local raw = tableForLang[key] or I18n.Dict.vi[key] or key
	if select("#", ...) > 0 then
		local ok, formatted = pcall(string.format, raw, ...)
		if ok then
			return formatted
		end
	end
	return raw
end

function I18n.Pick(viText: string, enText: string): string
	if I18n.IsEnglish() then
		return enText
	end
	return viText
end

function I18n.GetItemDisplayName(itemId: string?, fallbackName: string?): string
	local id = tostring(itemId or "")
	local isEn = I18n.IsEnglish()
	if id ~= "" then
		if isEn and ITEM_NAME_EN[id] then
			return ITEM_NAME_EN[id]
		elseif not isEn and ITEM_NAME_VI[id] then
			return ITEM_NAME_VI[id]
		end
	end

	local raw = tostring(fallbackName or id)
	if raw == "" then
		return isEn and "None" or "Chưa Trang Bị"
	end

	local left, right = string.match(raw, "^(.-)%s*•%s*(.+)$")
	if not left or not right then
		left, right = string.match(raw, "^(.-)%s+%-%s+(.+)$")
	end
	if left and right then
		local leftHasVi = string.find(left, "[\192-\255]") ~= nil
		local rightHasVi = string.find(right, "[\192-\255]") ~= nil
		if isEn then
			if leftHasVi and not rightHasVi then
				return right
			end
			return left
		else
			if rightHasVi and not leftHasVi then
				return right
			end
			return left
		end
	end

	return raw
end

local SLOT_LABEL_VI: { [string]: string } = {
	Helm = "MŨ GIÁP",
	Chest = "GIÁP NGỰC",
	Gauntlets = "HỘ UYỂN",
	Greaves = "CHIẾN HÀI",
	Weapon = "VŨ KHÍ",
	Gun = "PHÁP KHÍ",
	Offhand = "PHỤ KIỆN",
	Ring = "NHẪN",
	Artifact = "THÁNH VẬT",
	Weapons = "Vũ Khí",
	Armor = "Giáp Trụ",
	Materials = "Nguyên Liệu",
	Quest = "Nhiệm Vụ",
}

local SLOT_LABEL_EN: { [string]: string } = {
	Helm = "HELM",
	Chest = "CHEST",
	Gauntlets = "GAUNTLETS",
	Greaves = "GREAVES",
	Weapon = "WEAPON",
	Gun = "GUN",
	Offhand = "OFFHAND",
	Ring = "RING",
	Artifact = "ARTIFACT",
	Weapons = "Weapons",
	Armor = "Armor",
	Materials = "Materials",
	Quest = "Quest",
}

local RARITY_LABEL_VI: { [string]: string } = {
	Common = "THƯỜNG",
	Uncommon = "KHÁ HIẾM",
	Rare = "HIẾM",
	Epic = "SỬ THI",
	Legendary = "HUYỀN THOẠI",
	Mythic = "THẦN THOẠI",
	Mythical = "THẦN THOẠI",
}

local SORT_LABEL_VI: { [string]: string } = {
	Rarity = "PHẨM CHẤT",
	Level = "CẤP ĐỘ",
	Name = "TÊN",
}

function I18n.GetSlotLabel(slotOrCategory: string?): string
	local key = tostring(slotOrCategory or "Item")
	if I18n.IsEnglish() then
		return SLOT_LABEL_EN[key] or I18n.Upper(key)
	end
	return SLOT_LABEL_VI[key] or key
end

function I18n.GetRarityLabel(rarityId: string?): string
	local key = tostring(rarityId or "Common")
	if I18n.IsEnglish() then
		return I18n.Upper(key)
	end
	return RARITY_LABEL_VI[key] or I18n.Upper(key)
end

function I18n.GetSortLabel(sortMode: string?): string
	local key = tostring(sortMode or "Rarity")
	if I18n.IsEnglish() then
		return I18n.Upper(key)
	end
	return SORT_LABEL_VI[key] or I18n.Upper(key)
end

function I18n.GetHotbarSlotSummary(slotIndex: number, snapshot: any): (string, string, string)
	local isEn = I18n.IsEnglish()
	local p = LocalPlayer
	if slotIndex == 1 then
		local styleId = tostring(
			(p and (p:GetAttribute("FightingStyle") or p:GetAttribute("EquippedStyle")))
				or (snapshot and snapshot.fruits and snapshot.fruits.fightingStyle)
				or (snapshot and snapshot.equippedStyle)
				or "skyborn_combat"
		)
		if styleId == "" then
			styleId = "skyborn_combat"
		end
		local lowStyle = string.lower(styleId)
		local elem = "Sky"
		if SharedConfig and SharedConfig.FightingStyles and SharedConfig.FightingStyles[styleId] then
			elem = SharedConfig.FightingStyles[styleId].Element or "Sky"
		elseif string.find(lowStyle, "glacial") or string.find(lowStyle, "frost") then
			elem = "Frost"
		elseif string.find(lowStyle, "thunder") or string.find(lowStyle, "electric") then
			elem = "Lightning"
		elseif string.find(lowStyle, "abyssal") or string.find(lowStyle, "void") then
			elem = "Void"
		end
		return I18n.T("hud.slot.1"), I18n.GetItemDisplayName(styleId, styleId), elem
	elseif slotIndex == 2 then
		local fruitId = tostring(
			(p and p:GetAttribute("EquippedFruit"))
				or (snapshot and snapshot.fruits and snapshot.fruits.equippedFruit)
				or (snapshot and snapshot.equippedFruit)
				or ""
		)
		if fruitId == "" or fruitId == "None" then
			return I18n.T("hud.slot.2"), (isEn and "No Core" or "Chưa Có Lõi"), "Void"
		end
		local elem = "Void"
		if SharedConfig and SharedConfig.AetherFruits and SharedConfig.AetherFruits[fruitId] then
			elem = SharedConfig.AetherFruits[fruitId].Element or "Void"
		elseif string.find(fruitId, "Ice") or string.find(fruitId, "Aetherflow") then
			elem = "Frost"
		elseif string.find(fruitId, "Thunder") then
			elem = "Lightning"
		elseif string.find(fruitId, "Gale") or string.find(fruitId, "Light") or string.find(fruitId, "Flame") or string.find(fruitId, "Titan") then
			elem = "Sky"
		end
		return I18n.T("hud.slot.2"), I18n.GetItemDisplayName(fruitId, fruitId), elem
	elseif slotIndex == 3 then
		local swordId = tostring((p and p:GetAttribute("EquippedSword")) or "")
		if swordId == "" and snapshot and snapshot.equipped and snapshot.equipped.Weapon then
			swordId = tostring(snapshot.equipped.Weapon)
		end
		if swordId == "" then
			swordId = "starter_sword"
		end
		local lowSword = string.lower(swordId)
		local elem = "Sky"
		if SharedConfig and SharedConfig.Swords and SharedConfig.Swords[swordId] then
			elem = SharedConfig.Swords[swordId].Element or "Sky"
		elseif string.find(lowSword, "frost") or string.find(lowSword, "cryon") then
			elem = "Frost"
		elseif string.find(lowSword, "storm") or string.find(lowSword, "dagger") then
			elem = "Lightning"
		elseif string.find(lowSword, "noxar") or string.find(lowSword, "cursed") or string.find(lowSword, "yamo") or string.find(lowSword, "void") or string.find(lowSword, "abyssal") then
			elem = "Void"
		end
		return I18n.T("hud.slot.3"), I18n.GetItemDisplayName(swordId, swordId), elem
	else
		local gunId = tostring((p and p:GetAttribute("EquippedGun")) or "")
		if gunId == "" and snapshot and snapshot.fruits and snapshot.fruits.equippedGun then
			gunId = tostring(snapshot.fruits.equippedGun)
		end
		if gunId == "" and snapshot and snapshot.equipped then
			gunId = tostring(snapshot.equipped.EquippedGun or snapshot.equipped.Gun or snapshot.equipped.Offhand or "")
		end
		if gunId == "" then
			gunId = "aether_flintlock"
		end
		local lowGun = string.lower(gunId)
		local elem = "Sky"
		if string.find(lowGun, "cryo") then
			elem = "Frost"
		elseif string.find(lowGun, "soul") or string.find(lowGun, "void") then
			elem = "Void"
		end
		return I18n.T("hud.slot.4"), I18n.GetItemDisplayName(gunId, gunId), elem
	end
end

local function stripTrailingBracket(raw: string): string
	local stripped = string.gsub(raw, "%s*%b()%s*$", "")
	return (stripped ~= "" and stripped) or raw
end

function I18n.QuestTitle(cfgQ: any, fallback: string?): string
	if I18n.IsEnglish() then
		if type(cfgQ) == "table" then
			local enTitle = cfgQ.TitleEn or cfgQ.NameEn
			if type(enTitle) == "string" and enTitle ~= "" then
				return stripTrailingBracket(enTitle)
			end
		end
		local fb = tostring(fallback or (type(cfgQ) == "table" and (cfgQ.Title or cfgQ.Name or cfgQ.Id)) or "")
		return stripTrailingBracket(fb)
	end
	if type(cfgQ) == "table" then
		if type(cfgQ.VietnameseName) == "string" and cfgQ.VietnameseName ~= "" then
			return cfgQ.VietnameseName
		end
		local viTitle = cfgQ.Title or cfgQ.Name or cfgQ.Id
		if type(viTitle) == "string" and viTitle ~= "" then
			return stripTrailingBracket(viTitle)
		end
	end
	return stripTrailingBracket(tostring(fallback or ""))
end

function I18n.QuestDesc(cfgQ: any, fallback: string?): string
	if I18n.IsEnglish() then
		if type(cfgQ) == "table" then
			local enDesc = cfgQ.DescEn or cfgQ.DescriptionEn
			if type(enDesc) == "string" and enDesc ~= "" then
				return enDesc
			end
		end
	end
	if type(cfgQ) == "table" and type(cfgQ.Description) == "string" and cfgQ.Description ~= "" then
		return cfgQ.Description
	end
	return tostring(fallback or "")
end

function I18n.QuestObjectiveLabel(cfgQ: any, obj: any, idx: number?): string
	local cfgObj: any = nil
	if type(cfgQ) == "table" and type(cfgQ.Objectives) == "table" then
		if idx and cfgQ.Objectives[idx] then
			cfgObj = cfgQ.Objectives[idx]
		elseif type(obj) == "table" and obj.id ~= nil then
			for _, cand in ipairs(cfgQ.Objectives) do
				if tostring(cand.Id or "") == tostring(obj.id) then
					cfgObj = cand
					break
				end
			end
		end
	end

	if I18n.IsEnglish() then
		local enLbl = (type(obj) == "table" and (obj.labelEn or obj.LabelEn))
			or (type(cfgObj) == "table" and (cfgObj.LabelEn or cfgObj.DescriptionEn))
		if type(enLbl) == "string" and enLbl ~= "" then
			return enLbl
		end
		local raw = tostring(
			(type(obj) == "table" and (obj.label or obj.Label or obj.Description))
				or (type(cfgObj) == "table" and (cfgObj.Label or cfgObj.Description))
				or ("Objective " .. tostring(idx or 1))
		)
		raw = string.gsub(raw, "^Hạ gục quái vật bất kỳ$", "Defeat Any Hostile Mobs")
		raw = string.gsub(raw, "^Hạ gục ", "Defeat ")
		raw = string.gsub(raw, "^Đánh bại ", "Defeat ")
		raw = string.gsub(raw, "^Tiêu diệt ", "Defeat ")
		raw = string.gsub(raw, "^Thu thập ", "Collect ")
		raw = string.gsub(raw, "^Khám phá ", "Explore ")
		raw = string.gsub(raw, "^Nói chuyện với ", "Speak with ")
		raw = string.gsub(raw, "^Gặp ", "Speak with ")
		return raw
	end

	local viLbl = (type(cfgObj) == "table" and (cfgObj.Label or cfgObj.Description))
		or (type(obj) == "table" and (obj.label or obj.Label or obj.Description))
	if type(viLbl) == "string" and viLbl ~= "" then
		return viLbl
	end
	return "Mục tiêu " .. tostring(idx or 1)
end

-- ============================================================================
-- STAGE 1: BILINGUAL SKILL ARCHETYPE & MECHANICAL TAG BRIDGE (SkybreakSkillBlueprints)
-- ============================================================================
local CachedBlueprints: any = nil
local CachedCombatData: any = nil

local function getSkillBlueprints(): any
	if CachedBlueprints ~= nil then
		return CachedBlueprints
	end
	local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
	if sharedFolder then
		local bpMod = sharedFolder:FindFirstChild("SkybreakSkillBlueprints")
		if bpMod and bpMod:IsA("ModuleScript") then
			local ok, mod = pcall(require, bpMod)
			if ok and type(mod) == "table" then
				CachedBlueprints = mod
				return CachedBlueprints
			end
		end
		if CachedCombatData == nil then
			local cdMod = sharedFolder:FindFirstChild("SkybreakCombatData")
			if cdMod and cdMod:IsA("ModuleScript") then
				local okCd, cd = pcall(require, cdMod)
				if okCd and type(cd) == "table" then
					CachedCombatData = cd
				end
			end
		end
		if CachedCombatData and type(CachedCombatData.SkillBlueprints) == "table" then
			CachedBlueprints = CachedCombatData.SkillBlueprints
			return CachedBlueprints
		end
	end
	return nil
end

-- Rule 3: Complete 12-Core Canonical + Legacy Alias Map
local CORE_ALIAS_MAP: { [string]: string } = {
	GaleCore = "GaleCore",
	Gale = "GaleCore",
	SandstoneCore = "SandstoneCore",
	Smoke = "SandstoneCore",
	Sand = "SandstoneCore",
	SolarFlameCore = "SolarFlameCore",
	Flame = "SolarFlameCore",
	Fire = "SolarFlameCore",
	GlacierIceCore = "GlacierIceCore",
	Ice = "GlacierIceCore",
	Frost = "GlacierIceCore",
	ThunderRumbleCore = "ThunderRumbleCore",
	Rumble = "ThunderRumbleCore",
	Lightning = "ThunderRumbleCore",
	CelestialLightCore = "CelestialLightCore",
	Light = "CelestialLightCore",
	StarforgedMagmaCore = "StarforgedMagmaCore",
	Magma = "StarforgedMagmaCore",
	AstralGravityCore = "AstralGravityCore",
	Gravity = "AstralGravityCore",
	DimensionalPortalCore = "DimensionalPortalCore",
	Portal = "DimensionalPortalCore",
	SolarTitanCore = "SolarTitanCore",
	Buddha = "SolarTitanCore",
	AetherflowCore = "AetherflowCore",
	SweetDoughCore = "AetherflowCore",
	Dough = "AetherflowCore",
	AbyssalSovereignCore = "AbyssalSovereignCore",
	Dragon = "AbyssalSovereignCore",
}

local STYLE_ALIAS_MAP: { [string]: string } = {
	skyborn_combat = "skyborn_combat",
	SkybornCombat = "skyborn_combat",
	SkyStep = "SkyStep",
	sky_step = "SkyStep",
	black_leg = "SkyStep",
	flame_step = "SkyStep",
	jade_dragon = "jade_dragon",
	JadeDragon = "jade_dragon",
	GlacialFist = "jade_dragon",
	GlacialKarate = "jade_dragon",
	thunder_talon = "thunder_talon",
	ThunderTalon = "thunder_talon",
	ElectricClaw = "thunder_talon",
	solar_ashura = "solar_ashura",
	SolarAshura = "solar_ashura",
	AbyssalTalon = "solar_ashura",
	DragonTalon = "solar_ashura",
	celestial_godhuman = "celestial_godhuman",
	CelestialGodhuman = "celestial_godhuman",
	GodhumanSkyborn = "celestial_godhuman",
	SanguineVoidArt = "SanguineVoidArt",
	sanguine_void_art = "SanguineVoidArt",
	ChronoVoidPalm = "ChronoVoidPalm",
	chrono_void_palm = "ChronoVoidPalm",
}

-- Rule 2: Explicit 6 Flying Cores (+ AbyssalSovereignCore ONLY in Form 2)
local TRUE_FLIGHT_CORES: { [string]: boolean } = {
	GaleCore = true,
	SandstoneCore = true,
	SolarFlameCore = true,
	CelestialLightCore = true,
	StarforgedMagmaCore = true,
	AstralGravityCore = true,
}

function I18n.ResolveCanonicalCoreId(rawId: string?): string
	local raw = tostring(rawId or "")
	if raw == "" or raw == "None" then
		return ""
	end
	local bp = getSkillBlueprints()
	if bp and type(bp.ResolveCoreId) == "function" then
		local ok, res = pcall(bp.ResolveCoreId, raw)
		if ok and type(res) == "string" and res ~= "" then
			return res
		end
	end
	return CORE_ALIAS_MAP[raw] or raw
end

function I18n.FruitName(rawFruitId: string?): string
	local canon = I18n.ResolveCanonicalCoreId(rawFruitId)
	if canon == "" then
		return I18n.IsEnglish() and "None" or "Chưa Trang Bị"
	end
	return I18n.GetItemDisplayName(canon, canon)
end

function I18n.ResolveCanonicalStyleId(rawId: string?): string
	local raw = tostring(rawId or "")
	if raw == "" then
		return "skyborn_combat"
	end
	local bp = getSkillBlueprints()
	if bp and type(bp.ResolveStyleId) == "function" then
		local ok, res = pcall(bp.ResolveStyleId, raw)
		if ok and type(res) == "string" and res ~= "" then
			return res
		end
	end
	return STYLE_ALIAS_MAP[raw] or STYLE_ALIAS_MAP[string.lower(raw)] or raw
end

local ARCHETYPE_LABEL_EN: { [string]: string } = {
	-- Weapon Archetypes (Slot 3)
	Spear = "Polearm / Spear",
	Katana = "Iaido Katana",
	Greatsword = "Heavy Greatsword",
	DualBlades = "Twin Blades",
	Scythe = "Reaper Scythe",
	-- Gun Archetypes (Slot 4)
	Railgun = "Piercing Railgun",
	VoidLyre = "Harmonic Void Lyre",
	AcousticGuitar = "Harmonic Void Lyre",
	Bow = "Gale Sling / Bow",
	Cannon = "Siege Cannon",
	PistolRifle = "Aether Flintlock",
	-- Martial Archetypes (Slot 1)
	SkyKata = "Aero Palm Kata",
	KickKata = "Blaze Kick Kata",
	DragonClaw = "Vortex Claw Kata",
	VoltTalon = "Lightning Talon",
	SolarHeavy = "Guard-Break Heavy",
	CelestialSix = "Six-Realm Rush",
	SanguineDrain = "Vampiric Void Claw",
	ChronoPalm = "Temporal Stasis Palm",
	-- Skill Mechanical Archetypes (20 Canonical)
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
	TrueFlight = "3D Aerial Flight",
}

local ARCHETYPE_LABEL_VI: { [string]: string } = {
	-- Weapon Archetypes (Slot 3)
	Spear = "Trường Thương",
	Katana = "Đao Thuật Iaido",
	Greatsword = "Trọng Đại Kiếm",
	DualBlades = "Song Đao Tốc Trảm",
	Scythe = "Lưỡi Hái Hư Không",
	-- Gun Archetypes (Slot 4)
	Railgun = "Pháo Từ Trường",
	VoidLyre = "Đàn Hồn Hư Không",
	AcousticGuitar = "Đàn Hồn Hư Không",
	Bow = "Ná Gió / Cung",
	Cannon = "Đại Pháo Công Thành",
	PistolRifle = "Súng Aether",
	-- Martial Archetypes (Slot 1)
	SkyKata = "Chưởng Phong Kata",
	KickKata = "Phi Cước Hỏa Vũ",
	DragonClaw = "Long Trảo Hút Gom",
	VoltTalon = "Lôi Trảo Tốc Kích",
	SolarHeavy = "Trọng Quyền Phá Giáp",
	CelestialSix = "Thần Quyền Lục Giới",
	SanguineDrain = "Huyết Trảo Hút Máu",
	ChronoPalm = "Chưởng Ngưng Thời Không",
	-- Skill Mechanical Archetypes (20 Canonical)
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
	TrueFlight = "Bay Lượn 3D Tự Do",
}

local MECH_TAG_VI: { [string]: string } = {
	["BLINK"] = "TỐC BIẾN",
	["IAI CUT"] = "TRẢM IAI",
	["DELAYED SLASH"] = "TRẢM TRỄ",
	["PULL"] = "HÚT GOM",
	["VORTEX"] = "XOÁY HÚT",
	["FREEZE+SHATTER"] = "BĂNG+PHÁ VỠ",
	["FREEZE"] = "ĐÓNG BĂNG",
	["SHATTER"] = "PHÁ BĂNG",
	["LAVA POOL"] = "HỒ DUNG NHAM",
	["MAGMA POOL"] = "HỒ DUNG NHAM",
	["FROST SHEET"] = "THẢM BĂNG",
	["STORM CAGE"] = "LỒNG SẤM",
	["CHRONO FIELD"] = "NGƯNG ĐỌNG",
	["QUICKSAND"] = "CÁT LÚN",
	["POLE-VAULT"] = "CHỐNG GIÁO",
	["PIERCE"] = "XUYÊN PHÁ",
	["PIERCING"] = "XUYÊN PHÁ",
	["LIFESTEAL"] = "HÚT MÁU",
	["SIPHON"] = "HÚT SINH LỰC",
	["STUN"] = "CHOÁNG",
	["BURN"] = "THIÊU ĐỐT",
	["3D FLIGHT"] = "BAY 3D",
	["FLIGHT"] = "BAY 3D",
	["DASH HIT"] = "ĐỘT KÍCH",
	["DASH"] = "LƯỚT ĐÁNH",
	["WORLD GATE"] = "CỔNG ĐẢO",
	["PORTAL"] = "DỊCH CHUYỂN",
	["TRANSFORM"] = "BIẾN HÌNH",
	["IFRAME"] = "BẤT TỬ NGẮN",
	["PHASE"] = "ẨN KHÔNG",
	["MIRROR"] = "PHẢN QUANG",
	["ZIG-ZAG"] = "ZÍCH-ZẮC",
	["METEOR"] = "THIÊN THẠCH",
	["VOLLEY"] = "TÁN XẠ",
	["SPREAD"] = "ĐA TIA",
	["GUARD BREAK"] = "PHÁ GIÁP",
	["ARMOR SHRED"] = "XÉ GIÁP",
	["LAUNCH"] = "HẤT TUNG",
	["KNOCKUP"] = "HẤT TUNG",
	["DRAG"] = "CUỐN KÉO",
	["IMPLODE"] = "NỔ ÉP",
	["AOE"] = "DIỆN RỘNG",
	["ULTIMATE"] = "TUYỆT KỸ",
	["BEAM"] = "TIA XUYÊN",
	["WAVE"] = "SÓNG TRẢM",
	["SPIKES"] = "GAI ĐỊA CHẤN",
}

function I18n.GetArchetypeLabel(archId: string?): string
	local key = tostring(archId or "")
	if key == "" then
		return I18n.IsEnglish() and "Combat Arts" or "Chiến Kỹ"
	end
	if I18n.IsEnglish() then
		return ARCHETYPE_LABEL_EN[key] or key
	end
	return ARCHETYPE_LABEL_VI[key] or ARCHETYPE_LABEL_EN[key] or key
end

function I18n.LocalizeMechTag(rawTag: string?): string
	local clean = I18n.Upper(tostring(rawTag or ""))
	if clean == "" then
		return ""
	end
	if I18n.IsEnglish() then
		return clean
	end
	if MECH_TAG_VI[clean] then
		return MECH_TAG_VI[clean]
	end
	local chainN = string.match(clean, "^CHAIN%s*X?(%d+)$")
	if chainN then
		return "GIẬT XÍCH x" .. chainN
	end
	local hitsN = string.match(clean, "^(%d+)%s*HITS?$") or string.match(clean, "^HITS?%s*X?(%d+)$")
	if hitsN then
		return hitsN .. " ĐÒN"
	end
	return clean
end

local function inferWeaponArchetypeFallback(weaponId: string): string
	local low = string.lower(weaponId)
	if string.find(low, "staff") or string.find(low, "spear") or string.find(low, "frost") and string.find(low, "eternal") then
		return "Spear"
	elseif string.find(low, "scythe") or string.find(low, "severance") then
		return "Scythe"
	elseif string.find(low, "dagger") or string.find(low, "dual") or string.find(low, "twin") then
		return "DualBlades"
	elseif string.find(low, "great") or string.find(low, "saber") or string.find(low, "noxar") then
		return "Greatsword"
	end
	return "Katana"
end

local function inferGunArchetypeFallback(gunId: string): string
	local low = string.lower(gunId)
	if string.find(low, "railgun") then
		return "Railgun"
	elseif string.find(low, "guitar") or string.find(low, "lyre") then
		return "VoidLyre"
	elseif string.find(low, "kabucha") or string.find(low, "sling") or string.find(low, "bow") then
		return "Bow"
	elseif string.find(low, "cannon") then
		return "Cannon"
	end
	return "PistolRifle"
end

local STYLE_FALLBACK_ARCH: { [string]: string } = {
	skyborn_combat = "SkyKata",
	SkyStep = "KickKata",
	jade_dragon = "DragonClaw",
	thunder_talon = "VoltTalon",
	solar_ashura = "SolarHeavy",
	celestial_godhuman = "CelestialSix",
	SanguineVoidArt = "SanguineDrain",
	ChronoVoidPalm = "ChronoPalm",
}

local FALLBACK_STYLE_MOVES: { [string]: { [string]: { arch: string, tags: { string } } } } = {
	skyborn_combat = {
		Z = { arch = "MobilityDashHit", tags = { "DASH HIT", "GUARD BREAK" } },
		X = { arch = "PoleVaultSlam", tags = { "LAUNCH", "AOE" } },
		C = { arch = "DragRushSlam", tags = { "4 HITS", "DASH HIT" } },
	},
	SkyStep = {
		Z = { arch = "MobilityDashHit", tags = { "DASH HIT", "BURN" } },
		X = { arch = "TravellingWave", tags = { "WAVE", "LAUNCH" } },
		C = { arch = "PoleVaultSlam", tags = { "4 HITS", "STUN" } },
	},
	jade_dragon = {
		Z = { arch = "DragRushSlam", tags = { "ARMOR SHRED", "DASH HIT" } },
		X = { arch = "VortexPullCage", tags = { "PULL", "AOE" } },
		C = { arch = "PiercingBeam", tags = { "PIERCE", "GUARD BREAK" } },
	},
	thunder_talon = {
		Z = { arch = "BlinkDelayedSlash", tags = { "BLINK", "STUN" } },
		X = { arch = "ChainLightning", tags = { "CHAIN x4", "STUN" } },
		C = { arch = "ZigZagMirrorKick", tags = { "6 HITS", "CHAIN x5" } },
	},
	solar_ashura = {
		Z = { arch = "MobilityDashHit", tags = { "BURN", "GUARD BREAK" } },
		X = { arch = "GroundMonolithShatter", tags = { "LAUNCH", "BURN" } },
		C = { arch = "SkyfallSphere", tags = { "LAVA POOL", "GUARD BREAK" } },
	},
	celestial_godhuman = {
		Z = { arch = "DragRushSlam", tags = { "5 HITS", "DASH HIT" } },
		X = { arch = "GroundMonolithShatter", tags = { "STUN", "GUARD BREAK" } },
		C = { arch = "BlinkDelayedSlash", tags = { "BLINK", "6 HITS" } },
	},
	SanguineVoidArt = {
		Z = { arch = "DragRushSlam", tags = { "LIFESTEAL", "5 HITS" } },
		X = { arch = "SpreadVolley", tags = { "LIFESTEAL", "STUN" } },
		C = { arch = "VortexPullCage", tags = { "PULL", "LIFESTEAL" } },
	},
	ChronoVoidPalm = {
		Z = { arch = "TravellingWave", tags = { "CHRONO FIELD", "DASH HIT" } },
		X = { arch = "VortexPullCage", tags = { "CHRONO FIELD", "STUN" } },
		C = { arch = "SkyfallSphere", tags = { "PULL", "STUN" } },
	},
}

local FALLBACK_CORE_MOVES: { [string]: { [string]: { arch: string, tags: { string } } } } = {
	GaleCore = {
		Z = { arch = "TravellingWave", tags = { "WAVE", "LAUNCH" } },
		X = { arch = "VortexPullCage", tags = { "PULL", "AOE" } },
		C = { arch = "DragRushSlam", tags = { "PULL", "GUARD BREAK" } },
		V = { arch = "VortexPullCage", tags = { "PULL", "ULTIMATE" } },
	},
	SandstoneCore = {
		Z = { arch = "TravellingWave", tags = { "QUICKSAND", "WAVE" } },
		X = { arch = "SandCoffinImplode", tags = { "PULL", "IMPLODE" } },
		C = { arch = "VortexPullCage", tags = { "QUICKSAND", "PULL" } },
		V = { arch = "SandCoffinImplode", tags = { "QUICKSAND", "ULTIMATE" } },
	},
	SolarFlameCore = {
		Z = { arch = "SpreadVolley", tags = { "BURN", "VOLLEY" } },
		X = { arch = "SkybeamPillars", tags = { "BURN", "LAUNCH" } },
		C = { arch = "DragRushSlam", tags = { "BURN", "DASH HIT" } },
		V = { arch = "SkyfallSphere", tags = { "BURN", "ULTIMATE" } },
	},
	GlacierIceCore = {
		Z = { arch = "MultiLaneSpikes", tags = { "FREEZE", "SPIKES" } },
		X = { arch = "GroundMonolithShatter", tags = { "FREEZE+SHATTER", "STUN" } },
		C = { arch = "VortexPullCage", tags = { "FROST SHEET", "FREEZE" } },
		V = { arch = "GroundMonolithShatter", tags = { "FREEZE+SHATTER", "FROST SHEET" } },
		F = { arch = "MobilityDashHit", tags = { "FROST SHEET", "DASH HIT" } },
	},
	ThunderRumbleCore = {
		Z = { arch = "ChainLightning", tags = { "CHAIN x5", "STUN" } },
		X = { arch = "SkybeamPillars", tags = { "STORM CAGE", "STUN" } },
		C = { arch = "PiercingBeam", tags = { "PIERCE", "CHAIN x5" } },
		V = { arch = "SkyfallSphere", tags = { "STORM CAGE", "ULTIMATE" } },
		F = { arch = "BlinkDelayedSlash", tags = { "BLINK", "CHAIN x3" } },
	},
	CelestialLightCore = {
		Z = { arch = "PiercingBeam", tags = { "PIERCE", "BEAM" } },
		X = { arch = "ZigZagMirrorKick", tags = { "MIRROR", "BLINK" } },
		C = { arch = "SkybeamPillars", tags = { "BLINK", "STUN" } },
		V = { arch = "MeteorShower", tags = { "PIERCE", "ULTIMATE" } },
	},
	StarforgedMagmaCore = {
		Z = { arch = "SpreadVolley", tags = { "LAVA POOL", "BURN" } },
		X = { arch = "DragRushSlam", tags = { "LAVA POOL", "GUARD BREAK" } },
		C = { arch = "GroundMonolithShatter", tags = { "LAVA POOL", "AOE" } },
		V = { arch = "MeteorShower", tags = { "LAVA POOL", "METEOR" } },
	},
	AstralGravityCore = {
		Z = { arch = "VortexPullCage", tags = { "PULL", "STUN" } },
		X = { arch = "GroundMonolithShatter", tags = { "PULL", "GUARD BREAK" } },
		C = { arch = "VortexPullCage", tags = { "PULL", "IMPLODE" } },
		V = { arch = "MeteorShower", tags = { "METEOR", "PULL" } },
	},
	DimensionalPortalCore = {
		Z = { arch = "BlinkDelayedSlash", tags = { "BLINK", "IAI CUT" } },
		X = { arch = "RiftPhaseEscape", tags = { "IFRAME", "PHASE" } },
		C = { arch = "PortalWorldGate", tags = { "WORLD GATE", "PORTAL" } },
		V = { arch = "VortexPullCage", tags = { "PULL", "CHRONO FIELD" } },
		F = { arch = "RiftPhaseEscape", tags = { "BLINK", "PHASE" } },
	},
	SolarTitanCore = {
		Z = { arch = "TransformToggle", tags = { "TRANSFORM", "AOE" } },
		X = { arch = "GroundMonolithShatter", tags = { "GUARD BREAK", "STUN" } },
		C = { arch = "SkybeamPillars", tags = { "PIERCE", "AOE" } },
		V = { arch = "SkybeamPillars", tags = { "STUN", "ULTIMATE" } },
		F = { arch = "PoleVaultSlam", tags = { "DASH HIT", "LAUNCH" } },
	},
	AetherflowCore = {
		Z = { arch = "MultiLaneSpikes", tags = { "PULL", "GUARD BREAK" } },
		X = { arch = "DragRushSlam", tags = { "DRAG", "STUN" } },
		C = { arch = "VortexPullCage", tags = { "PULL", "STUN" } },
		V = { arch = "MultiLaneSpikes", tags = { "STUN", "ULTIMATE" } },
		F = { arch = "MobilityDashHit", tags = { "DASH HIT", "DRAG" } },
	},
	AbyssalSovereignCore = {
		Z = { arch = "PiercingBeam", tags = { "PIERCE", "BURN" } },
		X = { arch = "DragRushSlam", tags = { "DRAG", "LAUNCH" } },
		C = { arch = "MeteorShower", tags = { "BURN", "AOE" } },
		V = { arch = "TransformToggle", tags = { "TRANSFORM", "ULTIMATE" } },
		F = { arch = "MobilityDashHit", tags = { "DASH HIT", "BURN" } },
	},
}

local FALLBACK_WEAPON_MOVES: { [string]: { [string]: { arch: string, tags: { string } } } } = {
	Spear = {
		Z = { arch = "PoleVaultSlam", tags = { "POLE-VAULT", "PIERCE" } },
		X = { arch = "MultiLaneSpikes", tags = { "PIERCE", "LAUNCH" } },
	},
	Katana = {
		Z = { arch = "BlinkDelayedSlash", tags = { "BLINK", "IAI CUT" } },
		X = { arch = "TravellingWave", tags = { "IAI CUT", "PIERCE" } },
	},
	Greatsword = {
		Z = { arch = "GroundMonolithShatter", tags = { "GUARD BREAK", "AOE" } },
		X = { arch = "TravellingWave", tags = { "PIERCE", "GUARD BREAK" } },
	},
	DualBlades = {
		Z = { arch = "BlinkDelayedSlash", tags = { "BLINK", "6 HITS" } },
		X = { arch = "VortexPullCage", tags = { "PULL", "IAI CUT" } },
	},
	Scythe = {
		Z = { arch = "VortexPullCage", tags = { "PULL", "LIFESTEAL" } },
		X = { arch = "BlinkDelayedSlash", tags = { "BLINK", "LIFESTEAL" } },
	},
}

local FALLBACK_GUN_MOVES: { [string]: { [string]: { arch: string, tags: { string } } } } = {
	Railgun = {
		Z = { arch = "PiercingBeam", tags = { "PIERCE", "FREEZE+SHATTER" } },
		X = { arch = "ChainLightning", tags = { "CHAIN x5", "STUN" } },
	},
	VoidLyre = {
		Z = { arch = "HarmonicSiphonWave", tags = { "LIFESTEAL", "WAVE" } },
		X = { arch = "VortexPullCage", tags = { "PULL", "LIFESTEAL" } },
	},
	Bow = {
		Z = { arch = "SpreadVolley", tags = { "VOLLEY", "LAUNCH" } },
		X = { arch = "VortexPullCage", tags = { "PULL", "PIERCE" } },
	},
	Cannon = {
		Z = { arch = "SkyfallSphere", tags = { "BURN", "GUARD BREAK" } },
		X = { arch = "MeteorShower", tags = { "LAVA POOL", "AOE" } },
	},
	PistolRifle = {
		Z = { arch = "PiercingBeam", tags = { "PIERCE", "DASH HIT" } },
		X = { arch = "SpreadVolley", tags = { "VOLLEY", "STUN" } },
	},
}

local HAZARD_TO_TAG: { [string]: string } = {
	MagmaPool = "LAVA POOL",
	SolarFlare = "LAVA POOL",
	FrostSheet = "FROST SHEET",
	StormCage = "STORM CAGE",
	ChronoField = "CHRONO FIELD",
	Quicksand = "QUICKSAND",
	GravityWell = "PULL",
}

function I18n.GetSlotArchetypeMeta(slotIdx: number, rawId: string?, ctx: any?): { archetypeId: string, archetypeLabel: string, m1Tags: { string } }
	local slot = math.clamp(tonumber(slotIdx) or 1, 1, 4)
	local bp = getSkillBlueprints()
	local archId = ""
	local rawM1Tags: { string } = {}

	if slot == 1 then
		local stId = I18n.ResolveCanonicalStyleId(rawId)
		archId = STYLE_FALLBACK_ARCH[stId] or "SkyKata"
		if bp and type(bp.GetM1Blueprint) == "function" then
			local ok, m1 = pcall(bp.GetM1Blueprint, 1, stId, 4, ctx or {})
			if ok and type(m1) == "table" then
				if type(m1.WeaponArchetype) == "string" and m1.WeaponArchetype ~= "" then
					archId = m1.WeaponArchetype
				elseif type(m1.Archetype) == "string" and m1.Archetype ~= "" then
					archId = m1.Archetype
				end
				if type(m1.Tags) == "table" then
					for _, t in ipairs(m1.Tags) do
						table.insert(rawM1Tags, tostring(t))
					end
				end
			end
		end
	elseif slot == 2 then
		local coreId = I18n.ResolveCanonicalCoreId(rawId)
		if coreId == "" then
			return { archetypeId = "", archetypeLabel = I18n.Pick("Chưa Trang Bị", "Unequipped"), m1Tags = {} }
		end
		local tier = tonumber(ctx and ctx.DragonFormTier) or 0
		local tf = tostring((ctx and ctx.FruitTransform) or "")
		local isFlight = false
		if bp and type(bp.IsTrueFlightCore) == "function" then
			local ok, fl = pcall(bp.IsTrueFlightCore, coreId, tier, tf)
			if ok then
				isFlight = (fl == true)
			end
		else
			isFlight = (coreId == "AbyssalSovereignCore" and (tier >= 2 or tf == "AbyssalSovereign" or tf == "DragonFull"))
				or (TRUE_FLIGHT_CORES[coreId] == true)
		end
		archId = isFlight and "TrueFlight" or "MobilityDashHit"
		if isFlight then
			table.insert(rawM1Tags, "3D FLIGHT")
		end
	elseif slot == 3 then
		local wId = tostring(rawId or "starter_sword")
		if bp and type(bp.ResolveWeaponArchetype) == "function" then
			local ok, wArch = pcall(bp.ResolveWeaponArchetype, wId)
			if ok and type(wArch) == "string" and wArch ~= "" then
				archId = wArch
			end
		end
		if archId == "" then
			archId = inferWeaponArchetypeFallback(wId)
		end
	else
		local gId = tostring(rawId or "aether_flintlock")
		if bp and type(bp.ResolveGunArchetype) == "function" then
			local ok, gArch = pcall(bp.ResolveGunArchetype, gId)
			if ok and type(gArch) == "string" and gArch ~= "" then
				archId = gArch
			end
		end
		if archId == "" then
			archId = inferGunArchetypeFallback(gId)
		end
	end

	local locTags: { string } = {}
	for _, rt in ipairs(rawM1Tags) do
		local lt = I18n.LocalizeMechTag(rt)
		if lt ~= "" then
			table.insert(locTags, lt)
		end
	end

	return {
		archetypeId = archId,
		archetypeLabel = I18n.GetArchetypeLabel(archId),
		m1Tags = locTags,
	}
end

function I18n.GetSkillMechanicsMeta(slotIdx: number, rawId: string?, moveKey: string?, ctx: any?): any
	local slot = math.clamp(tonumber(slotIdx) or 1, 1, 4)
	local key = string.upper(tostring(moveKey or "Z"))
	local bp = getSkillBlueprints()
	local safeCtx = type(ctx) == "table" and ctx or {}

	local canonId = tostring(rawId or "")
	if slot == 1 then
		canonId = I18n.ResolveCanonicalStyleId(canonId)
	elseif slot == 2 then
		canonId = I18n.ResolveCanonicalCoreId(canonId)
	end

	local spec: any = nil
	if bp and type(bp.GetSkillBlueprint) == "function" and canonId ~= "" then
		local ok, res = pcall(bp.GetSkillBlueprint, slot, canonId, key, safeCtx)
		if ok and type(res) == "table" then
			spec = res
		end
	end

	local archId = ""
	local weaponArch = ""
	local rawTags: { string } = {}
	local seenRaw: { [string]: boolean } = {}
	local function pushTag(t: string?)
		local up = I18n.Upper(tostring(t or ""))
		if up ~= "" and not seenRaw[up] then
			seenRaw[up] = true
			table.insert(rawTags, up)
		end
	end

	-- Rule 2 check for Slot 2 [F] True 3D Flight vs Instant Non-Flight [F]
	if slot == 2 and key == "F" and canonId ~= "" then
		local tier = tonumber(safeCtx.DragonFormTier) or 0
		local tf = tostring(safeCtx.FruitTransform or "")
		local canFly = false
		if bp and type(bp.IsTrueFlightCore) == "function" then
			local okF, fl = pcall(bp.IsTrueFlightCore, canonId, tier, tf)
			if okF then
				canFly = (fl == true)
			end
		else
			canFly = (canonId == "AbyssalSovereignCore" and (tier >= 2 or tf == "AbyssalSovereign" or tf == "DragonFull"))
				or (TRUE_FLIGHT_CORES[canonId] == true)
		end
		if canFly then
			archId = "TrueFlight"
			pushTag("3D FLIGHT")
		end
	end

	if spec then
		if archId == "" and type(spec.Archetype) == "string" and spec.Archetype ~= "" then
			archId = spec.Archetype
		end
		if type(spec.WeaponArchetype) == "string" and spec.WeaponArchetype ~= "" then
			weaponArch = spec.WeaponArchetype
		end
		if type(spec.Tags) == "table" then
			for _, t in ipairs(spec.Tags) do
				-- Guard Rule 2: never attach 3D FLIGHT to Slots 1/3/4 or non-flying [F] cores
				local upT = I18n.Upper(tostring(t))
				if (upT ~= "3D FLIGHT" and upT ~= "FLIGHT") or archId == "TrueFlight" then
					pushTag(upT)
				end
			end
		end
		if (tonumber(spec.ChainCount) or 0) > 1 then
			pushTag("CHAIN x" .. tostring(math.floor(tonumber(spec.ChainCount) or 2)))
		end
		if (tonumber(spec.FreezeDur) or 0) > 0 then
			if (tonumber(spec.ShatterBonusMult) or 0) > 1.01 then
				pushTag("FREEZE+SHATTER")
			else
				pushTag("FREEZE")
			end
		end
		if type(spec.HazardKind) == "string" and HAZARD_TO_TAG[spec.HazardKind] then
			pushTag(HAZARD_TO_TAG[spec.HazardKind])
		end
		if (tonumber(spec.PullStrength) or 0) > 0 then
			pushTag("PULL")
		end
		if (tonumber(spec.LifestealPct) or 0) > 0 then
			pushTag("LIFESTEAL")
		end
		if (tonumber(spec.StunDur) or 0) >= 0.5 then
			pushTag("STUN")
		end
		if (tonumber(spec.BurnTicks) or 0) > 0 then
			pushTag("BURN")
		end
	end

	-- Fallback derivation when SkybreakSkillBlueprints has not loaded yet or omitted tags
	if archId == "" or #rawTags == 0 then
		local fb: { arch: string, tags: { string } }? = nil
		if slot == 1 then
			local stMap = FALLBACK_STYLE_MOVES[canonId] or FALLBACK_STYLE_MOVES.skyborn_combat
			fb = stMap and stMap[key] or nil
		elseif slot == 2 and canonId ~= "" then
			local cMap = FALLBACK_CORE_MOVES[canonId]
			fb = cMap and cMap[key] or nil
		elseif slot == 3 then
			local wArch = (weaponArch ~= "" and weaponArch) or I18n.GetSlotArchetypeMeta(3, canonId, safeCtx).archetypeId
			weaponArch = wArch
			local wMap = FALLBACK_WEAPON_MOVES[wArch] or FALLBACK_WEAPON_MOVES.Katana
			fb = wMap and wMap[key] or nil
		elseif slot == 4 then
			local gArch = (weaponArch ~= "" and weaponArch) or I18n.GetSlotArchetypeMeta(4, canonId, safeCtx).archetypeId
			weaponArch = gArch
			local gMap = FALLBACK_GUN_MOVES[gArch] or FALLBACK_GUN_MOVES.PistolRifle
			fb = gMap and gMap[key] or nil
		end
		if fb then
			if archId == "" then
				archId = fb.arch
			end
			for _, t in ipairs(fb.tags) do
				pushTag(t)
			end
		end
	end

	local locTags: { string } = {}
	for _, rt in ipairs(rawTags) do
		local lt = I18n.LocalizeMechTag(rt)
		if lt ~= "" then
			table.insert(locTags, lt)
		end
	end

	local bpMoveName: string? = nil
	if spec then
		if I18n.IsEnglish() and type(spec.Name) == "string" and spec.Name ~= "" then
			bpMoveName = spec.Name
		elseif (not I18n.IsEnglish()) and type(spec.NameVI) == "string" and spec.NameVI ~= "" then
			bpMoveName = spec.NameVI
		elseif type(spec.Name) == "string" and spec.Name ~= "" then
			bpMoveName = spec.Name
		end
	end

	return {
		archetypeId = archId,
		weaponArchetype = weaponArch,
		archetypeLabel = I18n.GetArchetypeLabel(archId ~= "" and archId or weaponArch),
		weaponArchetypeLabel = (weaponArch ~= "") and I18n.GetArchetypeLabel(weaponArch) or nil,
		primaryTag = locTags[1] or "",
		tags = locTags,
		rawTags = rawTags,
		moveName = bpMoveName,
		hits = spec and tonumber(spec.Hits) or nil,
	}
end

return I18n
