--!strict
--[[
	I18n.lua (#94)
	Lightweight Bilingual Localization Module (Vietnamese default + English)
	Synced directly with LocalPlayer:GetAttribute("Language") ("vi" | "en").
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

local CurrentLang: string = "vi"
local Listeners: { (string) -> () } = {}

local function normalizeLang(raw: any): string
	if type(raw) == "string" then
		local lower = string.lower(raw)
		if lower == "en" or lower == "english" then
			return "en"
		end
	end
	return "vi"
end

if LocalPlayer then
	local existing = LocalPlayer:GetAttribute("Language")
	if existing == nil then
		pcall(function()
			LocalPlayer:SetAttribute("Language", "vi")
		end)
		CurrentLang = "vi"
	else
		CurrentLang = normalizeLang(existing)
	end

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
		["nav.fruits"] = "TRÁI ÁC QUỶ [G]",
		["nav.inventory"] = "TÚI ĐỒ [I]",
		["nav.skills"] = "KỸ NĂNG [K]",
		["nav.forge"] = "LÒ RÈN [F]",
		["nav.map"] = "BẢN ĐỒ [M]",
		["nav.quests"] = "NHẬT KÝ [L]",
		["nav.raid"] = "ĐỘT KÍCH [P]",
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
		["hud.fruit_radar"] = "Trái Tự Nhiên: %s (%dm)",
		["hud.buff.haki_arm"] = "Haki Vũ Trang [J]",
		["hud.buff.haki_ken"] = "Quan Sát (%d Né)",
		["hud.buff.race_v4"] = "Thức Tỉnh V4 [Y]",
		["hud.buff.x2_exp"] = "X2 EXP (%s)",
		["hud.buff.shield"] = "Khiên Hộ Thể",
		["hud.buff.transform"] = "Hóa Hình Thần Thú",
		["hud.slot.1"] = "VÕ THUẬT",
		["hud.slot.2"] = "TRÁI ÁC QUỶ",
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
		["fruits.title"] = "KHO TRÁI ÁC QUỶ AETHER [G]",
		["fruits.eat"] = "Ăn Trái Này",
		["fruits.hold"] = "Cầm 3D Trên Tay",
		["fruits.store"] = "Cất Vào Kho",
		["fruits.awaken_on"] = "Tắt V2 -> V1",
		["fruits.awaken_off"] = "Thức Tỉnh V2",
		["fruits.spin_btn"] = "Quay Gacha Zioles",
		["fruits.spin_rolling"] = "ZIOLES ĐANG TRIỆU HỒI TRÁI AETHER...",
		["fruits.spin_won"] = "CHÚC MỪNG NHẬN ĐƯỢC!",
		["fruits.cd_fmt"] = "Hồi: %ss",

		-- Inventory & Diff (#3, #97)
		["inv.title"] = "TÚI ĐỒ & TRANG BỊ [I]",
		["inv.view_weapon"] = "XEM VŨ KHÍ 3D",
		["inv.view_hero"] = "XEM NHÂN VẬT 3D",
		["inv.vs_equipped"] = "SO VỚI ĐANG MẶC",

		-- Skills & Presets (#60)
		["skills.title"] = "KỸ NĂNG & CHỈ SỐ [K]",
		["skills.preset_1"] = "Cấu Hình 1: Võ Sĩ",
		["skills.preset_2"] = "Cấu Hình 2: Kiếm Thánh",
		["skills.preset_3"] = "Cấu Hình 3: Trái Ác Quỷ",
		["skills.save"] = "LƯU",
		["skills.load"] = "NẠP",
		["skills.refund"] = "TẨY ĐIỂM (STAT REFUND)",

		-- World Map & Bestiary (#61, #99)
		["map.title"] = "BẢN ĐỒ TAM HẢI & ĐẢO TRỜI [M]",
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
		["settings.giftcode_title"] = "NHẬP MÃ QUÀ TẶNG (GIFTCODE)",
		["settings.giftcode_placeholder"] = "Nhập mã (VD: SKYBREAK2026)...",
		["settings.giftcode_btn"] = "NHẬN QUÀ",

		-- Main Menu (#93)
		["menu.enter"] = "VÀO THẾ GIỚI",
		["menu.vista_badge"] = "KHUNG CẢNH TRỰC TIẾP 3D • SKY HUB",
	},
	en = {
		-- Shared Navigation Tabs (#10, #91)
		["nav.hud"] = "COMBAT HUD [ESC]",
		["nav.fruits"] = "FRUITS [G]",
		["nav.inventory"] = "INVENTORY [I]",
		["nav.skills"] = "SKILLS [K]",
		["nav.forge"] = "FORGE [F]",
		["nav.map"] = "WORLD MAP [M]",
		["nav.quests"] = "QUESTS [L]",
		["nav.raid"] = "BOSS RAID [P]",
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
		["hud.fruit_radar"] = "Natural Fruit: %s (%dm)",
		["hud.buff.haki_arm"] = "Armament Haki [J]",
		["hud.buff.haki_ken"] = "Instinct (%d Dodges)",
		["hud.buff.race_v4"] = "Race V4 Awakened [Y]",
		["hud.buff.x2_exp"] = "2X EXP (%s)",
		["hud.buff.shield"] = "Aegis Barrier",
		["hud.buff.transform"] = "Beast Transformation",
		["hud.slot.1"] = "MELEE",
		["hud.slot.2"] = "DEVIL FRUIT",
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
		["fruits.title"] = "AETHER DEVIL FRUITS [G]",
		["fruits.eat"] = "Consume Fruit",
		["fruits.hold"] = "Hold 3D Fruit",
		["fruits.store"] = "Store in Vault",
		["fruits.awaken_on"] = "Disable V2 -> V1",
		["fruits.awaken_off"] = "Awaken V2",
		["fruits.spin_btn"] = "Spin Zioles Gacha",
		["fruits.spin_rolling"] = "ZIOLES IS CHANNELLING AETHER CORES...",
		["fruits.spin_won"] = "CONGRATULATIONS! YOU OBTAINED:",
		["fruits.cd_fmt"] = "CD: %ss",

		-- Inventory & Diff (#3, #97)
		["inv.title"] = "INVENTORY & GEAR [I]",
		["inv.view_weapon"] = "3D WEAPON VIEW",
		["inv.view_hero"] = "3D HERO VIEW",
		["inv.vs_equipped"] = "VS EQUIPPED",

		-- Skills & Presets (#60)
		["skills.title"] = "SKILLS & STAT MASTERY [K]",
		["skills.preset_1"] = "Preset 1: Brawler",
		["skills.preset_2"] = "Preset 2: Swordmaster",
		["skills.preset_3"] = "Preset 3: Fruit Sovereign",
		["skills.save"] = "SAVE",
		["skills.load"] = "LOAD",
		["skills.refund"] = "STAT REFUND (RESET)",

		-- World Map & Bestiary (#61, #99)
		["map.title"] = "GRAND SKY SEAS WORLD MAP [M]",
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
		["settings.giftcode_title"] = "REDEEM PROMO GIFTCODE",
		["settings.giftcode_placeholder"] = "Enter code (e.g. SKYBREAK2026)...",
		["settings.giftcode_btn"] = "REDEEM",

		-- Main Menu (#93)
		["menu.enter"] = "ENTER SKYBREAK",
		["menu.vista_badge"] = "LIVE 3D SKY HUB DIORAMA",
	},
}

local ITEM_NAME_VI: { [string]: string } = {
	-- Fighting Styles (Slot 1 — canonical snake_case + legacy PascalCase aliases)
	skyborn_combat = "Võ Thuật Skyborn",
	SkybornCombat = "Võ Thuật Skyborn",
	SkyStep = "Thiên Cước",
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

	-- Aether Fruits (Slot 2)
	GaleCore = "Trái Gió",
	SandstoneCore = "Trái Cát Vàng",
	SolarFlameCore = "Trái Lửa Mặt Trời",
	GlacierIceCore = "Trái Băng Vĩnh Cửu",
	CelestialLightCore = "Trái Ánh Sáng",
	StarforgedMagmaCore = "Trái Dung Nham",
	ThunderRumbleCore = "Trái Lôi Đình",
	AstralGravityCore = "Trái Trọng Lực",
	DimensionalPortalCore = "Trái Không Gian",
	SolarTitanCore = "Trái Kim Thân",
	AetherflowCore = "Trái Tinh Thể",
	AbyssalSovereignCore = "Trái Long Vương Hư Không",

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
	noxar_abyssal_greatsword = "Hắc Kiếm Hư Không",
	noxar_greatsword = "Đại Kiếm Hắc Tinh Noxar",
	abyssal_greatsword = "Đại Kiếm Vực Thẳm",
	yamo_voidblade = "Yêu Đao Hư Không Yamo",
	ArchitectsSeverance = "Thần Kiếm Kiến Tạo",

	-- Guns (Slot 4)
	aether_flintlock = "Súng Lục Aether",
	solar_kabucha = "Ná Thần Mặt Trời",
	cryo_railgun = "Pháo Từ Trường Băng",
	soul_guitar_void = "Đàn Linh Hồn Hư Không",

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
	leviathan_shield = "Khiên Thần Leviathan",
	sovereign_cloak = "Áo Choàng Đế Vương Hư Không",

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
	BlueResonanceGear = "Bánh Răng Cộng Hưởng Xanh",
	CoreGear = "Bánh Răng Thức Tỉnh V4",
	LeviathanHeart = "Trái Tim Thủy Tổ Leviathan",
	AwakeningMicrochip = "Chip Thức Tỉnh V2",
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
	celestial_godhuman = "Celestial Godhuman",
	CelestialGodhuman = "Celestial Godhuman",

	-- Aether Fruits (Slot 2)
	GaleCore = "Gale Core",
	SandstoneCore = "Sandstone Core",
	SolarFlameCore = "Solar Flame Core",
	GlacierIceCore = "Glacier Ice Core",
	CelestialLightCore = "Celestial Light Core",
	StarforgedMagmaCore = "Starforged Magma",
	ThunderRumbleCore = "Thunder Rumble",
	AstralGravityCore = "Astral Gravity",
	DimensionalPortalCore = "Dimensional Portal",
	SolarTitanCore = "Solar Titan (Buddha)",
	AetherflowCore = "Aetherflow (Dough)",
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
	cursed_dual_skyblades = "Cursed Dual Skyblades",
	noxar_abyssal_greatsword = "Noxar Abyssal Greatsword",
	noxar_greatsword = "Noxar Greatsword",
	abyssal_greatsword = "Abyssal Greatsword",
	yamo_voidblade = "Yamo Voidblade",
	ArchitectsSeverance = "Architect's Severance",

	-- Guns (Slot 4)
	aether_flintlock = "Aether Flintlock",
	solar_kabucha = "Solar Kabucha",
	cryo_railgun = "Cryo Railgun",
	soul_guitar_void = "Soul Guitar of Void",

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
	leviathan_shield = "Leviathan Aegis Shield",
	sovereign_cloak = "Void Sovereign Mantle",

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
	BlueResonanceGear = "Blue Resonance Gear",
	CoreGear = "Awakened Core Gear V4",
	LeviathanHeart = "Leviathan Heart",
	AwakeningMicrochip = "Awakening Microchip V2",
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
			task.spawn(fn, CurrentLang)
		end
	end
end

function I18n.OnChanged(callback: (string) -> ()): () -> ()
	table.insert(Listeners, callback)
	return function()
		local idx = table.find(Listeners, callback)
		if idx then
			table.remove(Listeners, idx)
		end
	end
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
}

local SORT_LABEL_VI: { [string]: string } = {
	Rarity = "PHẨM CHẤT",
	Level = "CẤP ĐỘ",
	Name = "TÊN",
}

function I18n.GetSlotLabel(slotOrCategory: string?): string
	local key = tostring(slotOrCategory or "Item")
	if I18n.IsEnglish() then
		return SLOT_LABEL_EN[key] or string.upper(key)
	end
	return SLOT_LABEL_VI[key] or key
end

function I18n.GetRarityLabel(rarityId: string?): string
	local key = tostring(rarityId or "Common")
	if I18n.IsEnglish() then
		return string.upper(key)
	end
	return RARITY_LABEL_VI[key] or string.upper(key)
end

function I18n.GetSortLabel(sortMode: string?): string
	local key = tostring(sortMode or "Rarity")
	if I18n.IsEnglish() then
		return string.upper(key)
	end
	return SORT_LABEL_VI[key] or string.upper(key)
end

function I18n.GetHotbarSlotSummary(slotIndex: number, snapshot: any): (string, string, string)
	local isEn = I18n.IsEnglish()
	local p = LocalPlayer
	if slotIndex == 1 then
		local styleId = tostring((p and p:GetAttribute("EquippedStyle")) or (snapshot and snapshot.equippedStyle) or "skyborn_combat")
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
		local fruitId = tostring((p and p:GetAttribute("EquippedFruit")) or (snapshot and snapshot.equippedFruit) or "")
		if fruitId == "" then
			return I18n.T("hud.slot.2"), (isEn and "No Fruit" or "Chưa Ăn Trái"), "Void"
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
		if gunId == "" and snapshot and snapshot.equipped then
			gunId = tostring(snapshot.equipped.EquippedGun or snapshot.equipped.Gun or "")
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

return I18n
