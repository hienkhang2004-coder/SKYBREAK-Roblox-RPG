-- SKYBREAK: Fragments of the Core — Rarity, Currency, Item & Forge Catalog
-- Location: ReplicatedStorage/SkybreakShared/Config/RarityConfig.lua

local Theme = require(script.Parent.Theme)

local RarityConfig = {}

-- Canonical 5 Rarities (Section 08 of Build Guide)
RarityConfig.Rarities = {
    Common = {
        Id = "Common",
        Name = "Common",
        DisplayName = "Common",
        Tier = 1,
        Color = Color3.fromRGB(168, 185, 209),       -- Muted Steel
        BackgroundTint = Color3.fromRGB(18, 30, 48),
        MaxUpgrade = 5,
        UpgradeMultiplier = 0.06,
    },
    Rare = {
        Id = "Rare",
        Name = "Rare",
        DisplayName = "Rare",
        Tier = 2,
        Color = Theme.Colors.ACCENT_SAPPHIRE,        -- #40AAFF Sapphire
        BackgroundTint = Color3.fromRGB(16, 38, 66),
        MaxUpgrade = 7,
        UpgradeMultiplier = 0.08,
    },
    Epic = {
        Id = "Epic",
        Name = "Epic",
        DisplayName = "Epic",
        Tier = 3,
        Color = Theme.Colors.VOID_PURPLE,            -- #B46AFA Void Purple
        BackgroundTint = Color3.fromRGB(34, 24, 62),
        MaxUpgrade = 8,
        UpgradeMultiplier = 0.10,
    },
    Legendary = {
        Id = "Legendary",
        Name = "Legendary",
        DisplayName = "Legendary",
        Tier = 4,
        Color = Theme.Colors.ACCENT_GOLD,            -- #E4B863 Champagne Gold
        BackgroundTint = Color3.fromRGB(46, 36, 22),
        MaxUpgrade = 10,
        UpgradeMultiplier = 0.12,
    },
    Mythic = {
        Id = "Mythic",
        Name = "Mythic",
        DisplayName = "Mythic",
        Tier = 5,
        Color = Color3.fromRGB(255, 110, 125),       -- Celestial Crimson-Gold
        BackgroundTint = Color3.fromRGB(54, 22, 34),
        MaxUpgrade = 10,
        UpgradeMultiplier = 0.15,
    },
}

RarityConfig.OrderedRarities = { "Common", "Rare", "Epic", "Legendary", "Mythic" }

-- Canonical Currencies (Section 08: Gold, Core Shard, Void Essence — no fake premium gems)
RarityConfig.Currencies = {
    Gold = {
        Id = "Gold",
        Name = "Gold",
        ShortName = "GOLD",
        Color = Theme.Colors.ACCENT_GOLD,
        Icon = "Gold",
        Description = "Standard currency forged across the Sky Hub and floating realms.",
    },
    CoreShards = {
        Id = "CoreShards",
        Name = "Core Shard",
        ShortName = "SHARDS",
        Color = Theme.Colors.ACCENT_SAPPHIRE,
        Icon = "Core",
        Description = "Crystallized fragments of the Sky Core used for Ascension and Forge synthesis.",
    },
    VoidEssence = {
        Id = "VoidEssence",
        Name = "Void Essence",
        ShortName = "VOID",
        Color = Theme.Colors.VOID_PURPLE,
        Icon = "Void",
        Description = "Concentrated entropy harvested from Shadow Realm and Veil's End bosses.",
    },
}

-- Canonical 8 Equipment Slots (Section 04.C)
RarityConfig.EquipmentSlots = {
    { Id = "Helm", Name = "HELM", Icon = "Shield", Order = 1 },
    { Id = "Chest", Name = "CHEST", Icon = "Shield", Order = 2 },
    { Id = "Gauntlets", Name = "GAUNTLETS", Icon = "Shield", Order = 3 },
    { Id = "Greaves", Name = "GREAVES", Icon = "Shield", Order = 4 },
    { Id = "Weapon", Name = "WEAPON", Icon = "Sword", Order = 5 },
    { Id = "Offhand", Name = "OFFHAND", Icon = "Shield", Order = 6 },
    { Id = "Ring", Name = "RING", Icon = "Gem", Order = 7 },
    { Id = "Artifact", Name = "ARTIFACT", Icon = "Core", Order = 8 },
}

-- Unified Item Catalog (Bridges live P0 items + V2 expansion items seamlessly)
RarityConfig.Items = {
    -- Starter / Live Server Weapons
    starter_sword = {
        Id = "starter_sword",
        Name = "Skyborn Greatsword",
        VietnameseName = "Kiếm Skyborn",
        Category = "Weapons",
        Slot = "Weapon",
        Rarity = "Common",
        ClassId = "SkyGuardian",
        LevelReq = 1,
        Icon = "Sword",
        Stats = { ATK = 14, DEF = 6, HP = 25 },
        Passive = "Skyborn Edge: Basic combo 3rd strike deals +45% Break damage.",
        Description = "Standard-issue broadsword tempered in the Golden Sky wind tunnels.",
    },
    starter_daggers = {
        Id = "starter_daggers",
        Name = "Skyborn Twinblades",
        VietnameseName = "Song đao Skyborn",
        Category = "Weapons",
        Slot = "Weapon",
        Rarity = "Common",
        ClassId = "ThunderStriker",
        LevelReq = 1,
        Icon = "Daggers",
        Stats = { ATK = 16, CRIT = 8, SPEED = 4 },
        Passive = "Static Edge: Consecutive hits grant +4% attack speed (up to 5 stacks).",
        Description = "Lightweight dual blades balanced for rapid aerial strikes.",
    },
    starter_staff = {
        Id = "starter_staff",
        Name = "Arcane Conduit Staff",
        VietnameseName = "Trượng Arcane",
        Category = "Weapons",
        Slot = "Weapon",
        Rarity = "Common",
        ClassId = "ArcaneMage",
        LevelReq = 1,
        Icon = "Staff",
        Stats = { ATK = 18, ENERGY = 25, CRIT = 5 },
        Passive = "Resonant Focus: Ranged bolts pierce air currents up to 34 studs.",
        Description = "A crystal-tipped staff channeling frost and arcane ley-lines.",
    },

    -- V2 Signature Legendary & Mythic Weapons
    Dawnbringer = {
        Id = "Dawnbringer",
        Name = "Dawnbringer",
        VietnameseName = "Thánh Kiếm Dawnbringer",
        Category = "Weapons",
        Slot = "Weapon",
        Rarity = "Legendary",
        ClassId = "SkyGuardian",
        LevelReq = 10,
        Icon = "Sword",
        Stats = { ATK = 120, DEF = 35, HP = 180, CRIT = 10 },
        Passive = "Solar Slash: Sky Slash releases a solar wave dealing +35% radiant damage.",
        Description = "Forged by Kael from Aureon's Core of Light. Radiates undying dawn.",
    },
    Stormfang = {
        Id = "Stormfang",
        Name = "Stormfang",
        VietnameseName = "Song Đao Stormfang",
        Category = "Weapons",
        Slot = "Weapon",
        Rarity = "Legendary",
        ClassId = "ThunderStriker",
        LevelReq = 20,
        Icon = "Daggers",
        Stats = { ATK = 135, CRIT = 18, SPEED = 12 },
        Passive = "Chain Lightning: Arc Cut arcs lightning between up to 3 nearby targets.",
        Description = "Twin fangs condensed from Frozen Cyber's high-voltage storm conduits.",
    },
    EternalFrost = {
        Id = "EternalFrost",
        Name = "Eternal Frost",
        VietnameseName = "Quyền Trượng Eternal Frost",
        Category = "Weapons",
        Slot = "Weapon",
        Rarity = "Legendary",
        ClassId = "ArcaneMage",
        LevelReq = 20,
        Icon = "Staff",
        Stats = { ATK = 142, ENERGY = 60, CRIT = 14 },
        Passive = "Permafrost Dominion: Frost Bolt slows targets and amplifies Break by 25%.",
        Description = "Crowned with Cryon Prime's sub-zero heart crystal.",
    },
    ArchitectsSeverance = {
        Id = "ArchitectsSeverance",
        Name = "Architect's Severance",
        VietnameseName = "Kiếm Kiến Tạo Veyr",
        Category = "Weapons",
        Slot = "Weapon",
        Rarity = "Mythic",
        ClassId = "SkyGuardian",
        LevelReq = 85,
        Icon = "Sword",
        Stats = { ATK = 380, DEF = 95, HP = 620, CRIT = 22 },
        Passive = "Reality Anchor: Ultimate creates a Celestial Anchor field reducing party damage by 25%.",
        Description = "Woven from Veil's End singularities. Only those who face Veyr may wield it.",
    },

    -- Armor & Accessories (8-Slot Equipment Support)
    SkyHelm = {
        Id = "SkyHelm",
        Name = "Skyborn Vanguard Helm",
        VietnameseName = "Mũ Giáp Skyborn",
        Category = "Armor",
        Slot = "Helm",
        Rarity = "Rare",
        LevelReq = 5,
        Icon = "Shield",
        Stats = { HP = 65, DEF = 14 },
        Passive = "Clear Sight: Reduces incoming stun duration by 15%.",
        Description = "Polished steel-glass visor worn by the Sky Hub sentries.",
    },
    CelestialPlate = {
        Id = "CelestialPlate",
        Name = "Celestial Aegis Plate",
        VietnameseName = "Giáp Celestial Plate",
        Category = "Armor",
        Slot = "Chest",
        Rarity = "Epic",
        LevelReq = 15,
        Icon = "Shield",
        Stats = { HP = 160, DEF = 38 },
        Passive = "Aegis Resonance: Guardian Shield and Mana Barrier absorb +15% damage.",
        Description = "Obsidian-steel breastplate inlaid with sapphire core conduits.",
    },
    StarlightGauntlets = {
        Id = "StarlightGauntlets",
        Name = "Starlight Gauntlets",
        VietnameseName = "Hộ Uyển Tinh Quang",
        Category = "Armor",
        Slot = "Gauntlets",
        Rarity = "Rare",
        LevelReq = 8,
        Icon = "Shield",
        Stats = { ATK = 18, DEF = 12, CRIT = 4 },
        Passive = "Firm Grip: Heavy attacks consume 15% less Stamina.",
        Description = "Articulated gauntlets reinforced with Golden Sky alloy.",
    },
    WindstriderGreaves = {
        Id = "WindstriderGreaves",
        Name = "Windstrider Greaves",
        VietnameseName = "Chiến Hài Phong Hành",
        Category = "Armor",
        Slot = "Greaves",
        Rarity = "Rare",
        LevelReq = 8,
        Icon = "Shield",
        Stats = { HP = 50, DEF = 14, SPEED = 6 },
        Passive = "Tailwind: Dash cooldown recovers 10% faster.",
        Description = "Aether-threaded boots designed for leaping across shattered sky bridges.",
    },
    AureonCrestShield = {
        Id = "AureonCrestShield",
        Name = "Aureon Crest Bulwark",
        VietnameseName = "Khiên Hộ Vệ Aureon",
        Category = "Armor",
        Slot = "Offhand",
        Rarity = "Epic",
        LevelReq = 10,
        Icon = "Shield",
        Stats = { HP = 110, DEF = 28 },
        Passive = "Sunburst Guard: Blocking or shielding reflects radiant shockwaves.",
        Description = "A wing-forged crest reclaimed from the Aureon Sentinel.",
    },
    SolarBand = {
        Id = "SolarBand",
        Name = "Solar Band",
        VietnameseName = "Nhẫn Thái Dương",
        Category = "Armor",
        Slot = "Ring",
        Rarity = "Epic",
        LevelReq = 12,
        Icon = "Gem",
        Stats = { ATK = 24, CRIT = 8, ENERGY = 20 },
        Passive = "Solar Conduit: Generates +2 bonus Energy on every skill hit.",
        Description = "A champagne-gold ring warm to the touch.",
    },
    CoreShardArtifact = {
        Id = "CoreShardArtifact",
        Name = "Astral Core Reliquary",
        VietnameseName = "Cổ Vật Mảnh Lõi",
        Category = "Armor",
        Slot = "Artifact",
        Rarity = "Legendary",
        LevelReq = 20,
        Icon = "Core",
        Stats = { HP = 140, ATK = 32, DEF = 20, ENERGY = 30 },
        Passive = "Core Harmonic: Ultimate charge rate increased by 20%.",
        Description = "A stabilized fragment of the Prime Sky Core suspended in obsidian glass.",
    },

    -- Crafting Materials & Quest Items
    upgrade_material = {
        Id = "upgrade_material",
        Name = "Luminous Alloy",
        VietnameseName = "Vật liệu ánh sáng",
        Category = "Materials",
        Rarity = "Rare",
        LevelReq = 1,
        Icon = "Gem",
        Stats = {},
        Description = "Refined celestial metal used by Kael to temper weapons and armor.",
    },
    SkyCrystal = {
        Id = "SkyCrystal",
        Name = "Sky Crystal",
        VietnameseName = "Pha Lê Bầu Trời",
        Category = "Materials",
        Rarity = "Rare",
        LevelReq = 1,
        Icon = "Gem",
        Stats = {},
        Description = "Pure aether crystal harvested from Golden Sky and Frozen Cyber.",
    },
    CoreOfLight = {
        Id = "CoreOfLight",
        Name = "Core of Light",
        VietnameseName = "Core of Light",
        Category = "Quest",
        Rarity = "Legendary",
        LevelReq = 10,
        Icon = "Core",
        Stats = {},
        Description = "Reclaimed from Aureon Sentinel. Essential for restoring the Sky Core and forging Dawnbringer.",
    },
    DawnbringerBlueprint = {
        Id = "DawnbringerBlueprint",
        Name = "Dawnbringer Blueprint",
        VietnameseName = "Bản vẽ Dawnbringer",
        Category = "Quest",
        Rarity = "Epic",
        LevelReq = 10,
        Icon = "Quest",
        Stats = {},
        Description = "Ancient schematic detailing how to bind the Core of Light into a blade.",
    },
    VoidShard = {
        Id = "VoidShard",
        Name = "Void Shard",
        VietnameseName = "Mảnh Hư Không",
        Category = "Materials",
        Rarity = "Epic",
        LevelReq = 20,
        Icon = "Void",
        Stats = {},
        Description = "Crystallized shadow matter dropped by Noxar's vanguard.",
    },
    BossKey = {
        Id = "BossKey",
        Name = "Sun Citadel Key",
        VietnameseName = "Chìa khóa tháp",
        Category = "Quest",
        Rarity = "Epic",
        LevelReq = 8,
        Icon = "Quest",
        Stats = {},
        Description = "Unlocks the Light Tower gate leading to Aureon Sentinel's arena.",
    },
    dawnbringer_sword = {
        Id = "dawnbringer_sword", Name = "Dawnbringer • Sword of the First Light", Category = "Weapons", Slot = "Weapon",
        Rarity = "Legendary", ClassId = "SkyGuardian", LevelReq = 1, Icon = "Sword",
        Stats = { ATK = 72, CRIT = 12 }, Passive = "Heaven's Cleave: 15% chance to unleash 300% Solar wave.",
        Description = "Thanh đại kiếm ánh sáng ban mai dành cho Sky Guardian (+72 ATK, +12% Crit, +24% Crit DMG).",
    },
    stormfang_daggers = {
        Id = "stormfang_daggers", Name = "Stormfang • Twinblades of the Tempest", Category = "Weapons", Slot = "Weapon",
        Rarity = "Legendary", ClassId = "ThunderStriker", LevelReq = 1, Icon = "Daggers",
        Stats = { ATK = 76, CRIT = 18 }, Passive = "Tempest Arc: Critical strikes chain lightning across enemies.",
        Description = "Song đao Lôi Đình dành cho Thunder Striker (+76 ATK, +18% Crit, +30% Crit DMG).",
    },
    astral_staff = {
        Id = "astral_staff", Name = "Chronostaff • Scepter of the Void Star", Category = "Weapons", Slot = "Weapon",
        Rarity = "Legendary", ClassId = "ArcaneMage", LevelReq = 1, Icon = "Staff",
        Stats = { ATK = 78, CRIT = 15, ENERGY = 30 }, Passive = "Astral Resonance: Amplifies spell damage and barrier shielding.",
        Description = "Quyền trượng Tinh Cầu dành cho Arcane Mage (+78 ATK, +15% Crit, +28% Crit DMG).",
    },
    saber_of_aureon = {
        Id = "saber_of_aureon", Name = "Saber of Aureon • Đại Kiếm Thánh Quang", Category = "Weapons", Slot = "Weapon",
        Rarity = "Legendary", LevelReq = 1, Icon = "Sword",
        Stats = { ATK = 115, CRIT = 16 }, Passive = "Radiant Wave: Slashes pierce enemy armor.",
        Description = "Thanh đại kiếm của Aureon Sentinel (+115 ATK, +16% Crit, +32% Crit DMG).",
    },
    cryon_frostblade = {
        Id = "cryon_frostblade", Name = "Cryon Frostblade • Tuyệt Độ Hàn Đao", Category = "Weapons", Slot = "Weapon",
        Rarity = "Legendary", LevelReq = 1, Icon = "Sword",
        Stats = { ATK = 135, CRIT = 18 }, Passive = "Absolute Zero: Chills and slows struck targets.",
        Description = "Đại đao băng tinh của Cryon Prime (+135 ATK, +18% Crit, +36% Crit DMG).",
    },
    cursed_dual_skyblades = {
        Id = "cursed_dual_skyblades", Name = "Cursed Dual Skyblades (CDK)", Category = "Weapons", Slot = "Weapon",
        Rarity = "Mythic", LevelReq = 1, Icon = "Sword",
        Stats = { ATK = 185, CRIT = 25 }, Passive = "Eclipse Cleave: Combines Solar Light & Abyssal Void energy.",
        Description = "Song kiếm thần thoại kết hợp Ánh Sáng & Hư Không (+185 ATK, +25% Crit, +48% Crit DMG).",
    },
    noxar_abyssal_greatsword = {
        Id = "noxar_abyssal_greatsword", Name = "Noxar's Abyssal Greatsword", Category = "Weapons", Slot = "Weapon",
        Rarity = "Mythic", LevelReq = 1, Icon = "Sword",
        Stats = { ATK = 210, CRIT = 28 }, Passive = "Void Singularity: Tears space with every heavy strike.",
        Description = "Đại kiếm tối thượng của Hư Không Vương Noxar (+210 ATK, +28% Crit, +55% Crit DMG).",
    },
    aether_flintlock = {
        Id = "aether_flintlock", Name = "Aether Flintlock", Category = "Weapons", Slot = "Offhand",
        Rarity = "Common", LevelReq = 1, Icon = "Sword",
        Stats = { ATK = 35, CRIT = 5 }, Description = "Súng lục Aether cơ bản của thợ săn bầu trời.",
    },
    solar_kabucha = {
        Id = "solar_kabucha", Name = "Solar Kabucha • Ná Thần Mặt Trời", Category = "Weapons", Slot = "Offhand",
        Rarity = "Rare", LevelReq = 1, Icon = "Sword",
        Stats = { ATK = 78, CRIT = 12 }, Description = "Ná thần bắn đạn mặt trời phá giáp (+78 ATK, +12% Crit).",
    },
    cryo_railgun = {
        Id = "cryo_railgun", Name = "Cryo Railgun • Pháo Từ Trường Băng", Category = "Weapons", Slot = "Offhand",
        Rarity = "Legendary", LevelReq = 1, Icon = "Sword",
        Stats = { ATK = 125, CRIT = 18 }, Description = "Pháo từ trường bắn tia laser băng giá (+125 ATK, +18% Crit).",
    },
    soul_guitar_void = {
        Id = "soul_guitar_void", Name = "Soul Guitar of the Void • Đàn Linh Hồn", Category = "Weapons", Slot = "Offhand",
        Rarity = "Mythic", LevelReq = 1, Icon = "Sword",
        Stats = { ATK = 165, CRIT = 22 }, Description = "Đàn linh hồn thần thoại triệu hồi sóng âm hư không (+165 ATK, +22% Crit).",
    },
    skyward_helm = {
        Id = "skyward_helm", Name = "Mũ Giáp Azure Vanguard", Category = "Armor", Slot = "Helm",
        Rarity = "Epic", LevelReq = 1, Icon = "Shield",
        Stats = { HP = 180, DEF = 18 }, Description = "Mũ giáp hợp kim thiên thanh bảo vệ khỏi chấn động không gian.",
    },
    skyward_chest = {
        Id = "skyward_chest", Name = "Chiến Giáp Skyward Cloak", Category = "Armor", Slot = "Chest",
        Rarity = "Legendary", LevelReq = 1, Icon = "Shield",
        Stats = { HP = 320, DEF = 32 }, Description = "Chiến giáp dệt từ lông vũ thiên giới và lõi tinh thể.",
    },
    skyward_gloves = {
        Id = "skyward_gloves", Name = "Hộ Uyển Thiên Không", Category = "Armor", Slot = "Gauntlets",
        Rarity = "Epic", LevelReq = 1, Icon = "Shield",
        Stats = { ATK = 22, CRIT = 6 }, Description = "Hộ uyển gia tăng lực cầm nắm và độ chuẩn xác khi ra đòn.",
    },
    skyward_boots = {
        Id = "skyward_boots", Name = "Chiến Hài Lướt Gió", Category = "Armor", Slot = "Greaves",
        Rarity = "Epic", LevelReq = 1, Icon = "Shield",
        Stats = { HP = 140, DEF = 16 }, Description = "Chiến hài gắn đá phong năng giúp di chuyển linh hoạt.",
    },
    aether_ring = {
        Id = "aether_ring", Name = "Nhẫn Tinh Cầu Aether", Category = "Armor", Slot = "Ring",
        Rarity = "Legendary", LevelReq = 1, Icon = "Gem",
        Stats = { ATK = 28, CRIT = 8 }, Description = "Chiếc nhẫn hội tụ dòng chảy Aether tăng mạnh tỉ lệ chí mạng.",
    },
    celestial_necklace = {
        Id = "celestial_necklace", Name = "Dây Chuyền Ánh Sao", Category = "Armor", Slot = "Offhand",
        Rarity = "Legendary", LevelReq = 1, Icon = "Gem",
        Stats = { HP = 220, CRIT = 10 }, Description = "Mặt dây chuyền chứa mảnh sao băng cổ đại (+220 HP, +20% Crit DMG).",
    },
    core_artifact = {
        Id = "core_artifact", Name = "Thánh Vật Core of Light", Category = "Armor", Slot = "Artifact",
        Rarity = "Mythic", LevelReq = 1, Icon = "Core",
        Stats = { ATK = 35, HP = 250, DEF = 20, CRIT = 5 }, Description = "Thánh vật cộng hưởng từ Core of Light (+35 ATK, +250 HP, +20 DEF).",
    },
    leviathan_shield = {
        Id = "leviathan_shield", Name = "Khiên Thần Leviathan", Category = "Armor", Slot = "Artifact",
        Rarity = "Mythic", LevelReq = 1, Icon = "Shield",
        Stats = { HP = 850, DEF = 85, ATK = 60, CRIT = 10 }, Description = "Khiên thần rèn từ vảy Thủy Tổ Leviathan (+850 HP, +85 DEF, +60 ATK).",
    },
    sovereign_cloak = {
        Id = "sovereign_cloak", Name = "Áo Choàng Hư Không Đế Vương", Category = "Armor", Slot = "Chest",
        Rarity = "Mythic", LevelReq = 1, Icon = "Shield",
        Stats = { HP = 750, DEF = 70, ATK = 55, CRIT = 12 }, Description = "Áo choàng tối thượng của Hư Không Vương Noxar (+750 HP, +70 DEF, +55 ATK).",
    },
    SunshardCore = {
        Id = "SunshardCore", Name = "Sunshard Core", Category = "Materials", Rarity = "Legendary",
        LevelReq = 1, Icon = "Core", Stats = {}, Description = "Tinh thể mặt trời rực cháy dùng để rèn thần khí.",
    },
    SkyIron = {
        Id = "SkyIron", Name = "Sky Iron", Category = "Materials", Rarity = "Rare",
        LevelReq = 1, Icon = "Gem", Stats = {}, Description = "Quặng sắt lơ lửng thu thập từ các đảo cổ.",
    },
    CelestialFeather = {
        Id = "CelestialFeather", Name = "Celestial Feather", Category = "Materials", Rarity = "Epic",
        LevelReq = 1, Icon = "Gem", Stats = {}, Description = "Lông vũ phát sáng dùng trong chế tác giáp trụ.",
    },
    CoreEssence = {
        Id = "CoreEssence", Name = "Core Essence", Category = "Materials", Rarity = "Mythic",
        LevelReq = 1, Icon = "Core", Stats = {}, Description = "Tinh chất lõi năng lượng thuần khiết từ Boss.",
    },
}

-- Kael's Celestial Forge Recipes (Section 04.G)
RarityConfig.Recipes = {
    {
        Id = "craft_dawnbringer",
        OutputItemId = "Dawnbringer",
        OutputCount = 1,
        Name = "Dawnbringer",
        Category = "Weapon",
        LevelReq = 10,
        GoldCost = 500,
        CoreShardCost = 10,
        Materials = {
            { ItemId = "DawnbringerBlueprint", Count = 1 },
            { ItemId = "CoreOfLight", Count = 1 },
            { ItemId = "upgrade_material", Count = 5 },
        },
        Description = "Bind the Core of Light into the legendary solar greatsword.",
    },
    {
        Id = "craft_stormfang",
        OutputItemId = "Stormfang",
        OutputCount = 1,
        Name = "Stormfang",
        Category = "Weapon",
        LevelReq = 20,
        GoldCost = 1200,
        CoreShardCost = 25,
        Materials = {
            { ItemId = "SkyCrystal", Count = 10 },
            { ItemId = "upgrade_material", Count = 8 },
        },
        Description = "Synthesize high-frequency twin daggers infused with Frozen Cyber lightning.",
    },
    {
        Id = "craft_eternal_frost",
        OutputItemId = "EternalFrost",
        OutputCount = 1,
        Name = "Eternal Frost",
        Category = "Weapon",
        LevelReq = 20,
        GoldCost = 1200,
        CoreShardCost = 25,
        Materials = {
            { ItemId = "SkyCrystal", Count = 12 },
            { ItemId = "upgrade_material", Count = 8 },
        },
        Description = "Channel sub-zero resonance into a legendary Arcane Mage staff.",
    },
    {
        Id = "craft_celestial_plate",
        OutputItemId = "CelestialPlate",
        OutputCount = 1,
        Name = "Celestial Aegis Plate",
        Category = "Armor",
        LevelReq = 15,
        GoldCost = 800,
        CoreShardCost = 15,
        Materials = {
            { ItemId = "SkyCrystal", Count = 6 },
            { ItemId = "upgrade_material", Count = 5 },
        },
        Description = "Forge obsidian-sapphire heavy armor for frontline survival.",
    },
    {
        Id = "craft_solar_band",
        OutputItemId = "SolarBand",
        OutputCount = 1,
        Name = "Solar Band",
        Category = "Accessory",
        LevelReq = 12,
        GoldCost = 600,
        CoreShardCost = 12,
        Materials = {
            { ItemId = "SkyCrystal", Count = 4 },
            { ItemId = "upgrade_material", Count = 3 },
        },
        Description = "Craft a champagne-gold ring that accelerates Energy recovery.",
    },
}

function RarityConfig.GetRarity(rarityId)
    return RarityConfig.Rarities[rarityId] or RarityConfig.Rarities.Common
end

function RarityConfig.GetItem(itemId)
    return RarityConfig.Items[itemId]
end

function RarityConfig.GetUpgradeCost(itemId, currentUpgrade)
    local item = RarityConfig.GetItem(itemId)
    local rarity = RarityConfig.GetRarity(item and item.Rarity or "Common")
    local nextLevel = (currentUpgrade or 0) + 1
    return {
        NextUpgrade = nextLevel,
        MaxUpgrade = rarity.MaxUpgrade,
        CanUpgrade = nextLevel <= rarity.MaxUpgrade,
        GoldCost = math.floor(120 * nextLevel * rarity.Tier),
        MaterialId = "upgrade_material",
        MaterialCount = math.max(1, math.floor(nextLevel * 0.8 + rarity.Tier * 0.5)),
    }
end

return RarityConfig
