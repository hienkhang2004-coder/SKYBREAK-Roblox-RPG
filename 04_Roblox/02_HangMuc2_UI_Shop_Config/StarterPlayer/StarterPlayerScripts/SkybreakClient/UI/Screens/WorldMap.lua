-- SKYBREAK: Fragments of the Core — Full 20-Island Live World Map (Sea 1-3) & Bestiary Codex / Drop Rates ([M])
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/WorldMap.lua
-- Covers Tasks #8, #10, #61, #94, #99

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local WorldConfig = require(Shared:WaitForChild("Config"):WaitForChild("WorldConfig"))
local UIAssets = require(Shared:WaitForChild("Config"):WaitForChild("UIAssets"))
local UIState = require(Shared:WaitForChild("Types"):WaitForChild("UIState"))

local GameplayConfig = nil
pcall(function()
    local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
    if sharedFolder and sharedFolder:FindFirstChild("Config") then
        GameplayConfig = require(sharedFolder.Config)
    end
end)

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Store = require(script.Parent.Parent:WaitForChild("Store"))
local ScreenRouter = require(script.Parent.Parent:WaitForChild("ScreenRouter"))
local I18n = require(script.Parent.Parent:WaitForChild("I18n"))
local PremiumPanel = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumPanel"))
local PremiumButton = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumButton"))
local PartyController = require(script.Parent.Parent:WaitForChild("Controllers"):WaitForChild("PartyController"))

local WorldMap = {
    Refs = {},
    ActiveSeaFilter = "All", -- "All" | "Sea1" | "Sea2" | "Sea3" | "Realms8"
    InspectorTab = "Info",   -- "Info" | "Codex"
    CodexShowAll = false,
    SelectedIslandId = "SkyHub",
}

-- #61 & #99: All 20 Canonical Sky Islands across Sea 1 (8), Sea 2 (6), and Sea 3 (6) + Enemies & Exact % Drop Rates
local TWENTY_ISLANDS = {
    -- SEA 1 (8 Islands • Lv. 1 - 700)
    {
        Id = "SkyHub",
        Sea = "Sea1",
        SeaLabel = "SKY 1",
        NameVi = "Thánh Đô Sky Hub",
        NameEn = "Sky Hub Sanctuary",
        LevelRange = "Lv. 1+",
        Pos = Vector3.new(-317.4, 50.5, 527.8),
        MapPos = Vector2.new(0.18, 0.20),
        AllMapPos = Vector2.new(0.11, 0.22),
        Accent = Color3.fromRGB(244, 198, 96),
        DescVi = "Trung tâm an toàn của các Chiến Binh Bầu Trời: Chỉ Huy Lyra, Thợ Rèn Kael và Bến Phi Thuyền.",
        DescEn = "Central safe sanctuary hosting Commander Lyra, Master Blacksmith Kael, and Airship Docks.",
        BossKey = nil,
        Enemies = {
            { Name = "Training Drone", Level = 5, HP = 220, IsBoss = false, Drops = { { Item = "Sky Iron", Rate = "55%" } } },
        },
    },
    {
        Id = "GoldenSky",
        Sea = "Sea1",
        SeaLabel = "SKY 1",
        NameVi = "Đảo Thiên Khởi (Golden Sky)",
        NameEn = "Golden Sky Archipelago",
        LevelRange = "Lv. 1 - 150",
        Pos = Vector3.new(-313.9, 50.5, 210.4),
        MapPos = Vector2.new(0.42, 0.18),
        AllMapPos = Vector2.new(0.25, 0.16),
        Accent = Color3.fromRGB(238, 192, 88),
        DescVi = "Quần đảo mây vàng khởi nguyên nơi tân binh luyện kiếm và thu thập Thiết Tinh Không.",
        DescEn = "Sunlit floating islands where new Skyborn hone basic combos and mine Sky Iron.",
        BossKey = nil,
        Enemies = {
            { Name = "Training Drone", Level = 10, HP = 320, IsBoss = false, Drops = { { Item = "Sky Iron", Rate = "55%" } } },
            { Name = "Sky Pirate", Level = 45, HP = 980, IsBoss = false, Drops = { { Item = "Sky Iron", Rate = "55%" }, { Item = "Aether Flintlock", Rate = "12%" } } },
        },
    },
    {
        Id = "ZiolesGachaShrine",
        Sea = "Sea1",
        SeaLabel = "SKY 1",
        NameVi = "Đền Gacha Trái Ác Quỷ Zioles",
        NameEn = "Zioles Devil Fruit Shrine",
        LevelRange = "Lv. 50+",
        Pos = Vector3.new(-560, 52.5, 996),
        MapPos = Vector2.new(0.68, 0.20),
        AllMapPos = Vector2.new(0.11, 0.48),
        Accent = Color3.fromRGB(196, 112, 255),
        DescVi = "Đền cổ triệu hồi 12 Trái Ác Quỷ 3D Aether cùng Thương Nhân Bí Ẩn Zioles.",
        DescEn = "Mystic shrine where Zioles rolls all 12 separated 3D Aether Devil Fruits.",
        BossKey = nil,
        Enemies = {
            { Name = "Aether Wisp", Level = 60, HP = 1250, IsBoss = false, Drops = { { Item = "Core Shards x15", Rate = "45%" } } },
        },
    },
    {
        Id = "AetherShrines",
        Sea = "Sea1",
        SeaLabel = "SKY 1",
        NameVi = "Đền Thức Tỉnh Aether",
        NameEn = "Aether Awakening Shrines",
        LevelRange = "Lv. 100+",
        Pos = Vector3.new(340, 52.5, 996),
        MapPos = Vector2.new(0.84, 0.36),
        AllMapPos = Vector2.new(0.25, 0.42),
        Accent = Color3.fromRGB(96, 224, 255),
        DescVi = "Bệ cổ ngữ kích hoạt Thức Tỉnh Trái Ác Quỷ V2 và Haki Vũ Trang.",
        DescEn = "Ancient rune consoles channeling Devil Fruit V2 Awakening and Busoshoku Haki.",
        BossKey = nil,
        Enemies = {
            { Name = "Shrine Construct", Level = 120, HP = 2400, IsBoss = false, Drops = { { Item = "Sunshard Core", Rate = "35%" } } },
        },
    },
    {
        Id = "WestGarden",
        Sea = "Sea1",
        SeaLabel = "SKY 1",
        NameVi = "Pháo Đài Hải Tặc (West Garden)",
        NameEn = "West Garden Pirate Bastion",
        LevelRange = "Lv. 150 - 300",
        Pos = Vector3.new(-2800, 50.5, -65),
        MapPos = Vector2.new(0.20, 0.54),
        AllMapPos = Vector2.new(0.11, 0.76),
        Accent = Color3.fromRGB(108, 228, 168),
        DescVi = "Thành trì của băng Hải Tặc Bầu Trời chiếm giữ vườn treo cổ đại phía Tây.",
        DescEn = "Fortified western hanging gardens occupied by ruthless Sky Pirate fleets.",
        BossKey = "Vance",
        BossDisplay = "Corsair Commander Vance",
        Enemies = {
            { Name = "Sky Pirate", Level = 180, HP = 3400, IsBoss = false, Drops = { { Item = "Sky Iron", Rate = "55%" } } },
            { Name = "Corsair Commander Vance", Level = 275, HP = 18500, IsBoss = true, Drops = { { Item = "Stormfang", Rate = "9%" }, { Item = "Sunshard Core", Rate = "35%" } } },
        },
    },
    {
        Id = "LumenPlaza",
        Sea = "Sea1",
        SeaLabel = "SKY 1",
        NameVi = "Quảng Trường Hoàng Kim (Lumen)",
        NameEn = "Lumen Golden Plaza",
        LevelRange = "Lv. 300 - 450",
        Pos = Vector3.new(0, 50.5, 65),
        MapPos = Vector2.new(0.48, 0.52),
        AllMapPos = Vector2.new(0.25, 0.68),
        Accent = Color3.fromRGB(246, 206, 108),
        DescVi = "Quảng trường cẩm thạch trắng được canh giữ bởi Kỵ Binh Tha Hóa.",
        DescEn = "Marble colonnades patrolled by Corrupted Royal Guards of the fallen Spire.",
        BossKey = nil,
        Enemies = {
            { Name = "Corrupted Guard", Level = 380, HP = 6200, IsBoss = false, Drops = { { Item = "Sky Iron", Rate = "55%" }, { Item = "Sunshard Core", Rate = "35%" } } },
        },
    },
    {
        Id = "SunshardSanctuary",
        Sea = "Sea1",
        SeaLabel = "SKY 1",
        NameVi = "Thánh Địa Thái Dương (Sunshard)",
        NameEn = "Sunshard Sky Sanctuary",
        LevelRange = "Lv. 450 - 600",
        Pos = Vector3.new(2800, 50.5, -55),
        MapPos = Vector2.new(0.34, 0.82),
        AllMapPos = Vector2.new(0.37, 0.30),
        Accent = Color3.fromRGB(255, 172, 76),
        DescVi = "Đền thờ Mặt Trời rực sáng cung cấp Lõi Thái Dương để rèn Thần Kiếm Dawnbringer.",
        DescEn = "Radiant solar temple rich in Sunshard Cores required to forge Dawnbringer.",
        BossKey = nil,
        Enemies = {
            { Name = "Sunshard Royal Guard", Level = 525, HP = 9800, IsBoss = false, Drops = { { Item = "Sunshard Core", Rate = "35%" }, { Item = "Saber of Aureon", Rate = "8%" } } },
        },
    },
    {
        Id = "BossForecourt",
        Sea = "Sea1",
        SeaLabel = "SKY 1",
        NameVi = "Tháp Phán Quyết Aureon",
        NameEn = "Aureon Sentinel Forecourt",
        LevelRange = "Lv. 600 - 700",
        Pos = Vector3.new(0, 50.5, -285),
        MapPos = Vector2.new(0.74, 0.80),
        AllMapPos = Vector2.new(0.37, 0.72),
        Accent = Color3.fromRGB(255, 214, 72),
        DescVi = "Đỉnh Tháp Sky 1: Đánh bại Thần Hộ Vệ Aureon Sentinel để mở cổng tiến vào Sky 2!",
        DescEn = "Apex of Sky 1: Defeat Raid Boss Aureon Sentinel to unlock passage into Sky 2!",
        BossKey = "Aureon",
        BossDisplay = "Aureon Sentinel",
        RaidId = "AureonSentinel",
        Enemies = {
            { Name = "Sunshard Royal Guard", Level = 620, HP = 12400, IsBoss = false, Drops = { { Item = "Sunshard Core", Rate = "35%" } } },
            {
                Name = "Aureon Sentinel",
                Level = 700,
                HP = 65000,
                IsBoss = true,
                Drops = {
                    { Item = "Dawnbringer", Rate = "5%" },
                    { Item = "Saber of Aureon", Rate = "8%" },
                    { Item = "Sunshard Core", Rate = "35%" },
                    { Item = "Sky Iron", Rate = "55%" },
                },
            },
        },
    },

    -- SEA 2 (6 Islands • Lv. 700 - 1500)
    {
        Id = "FrozenCyber",
        Sea = "Sea2",
        SeaLabel = "SKY 2",
        NameVi = "Đảo Băng Tuyết Cơ Giới",
        NameEn = "Frozen CyberCitadel",
        LevelRange = "Lv. 700 - 875",
        Pos = Vector3.new(11620.5, 50.9, 534.8),
        MapPos = Vector2.new(0.22, 0.24),
        AllMapPos = Vector2.new(0.53, 0.18),
        Accent = Color3.fromRGB(88, 214, 255),
        DescVi = "Quần đảo băng vĩnh cửu kết hợp công nghệ lõi cơ giới tối tân của Sky 2.",
        DescEn = "Sub-zero cybernetic archipelago blending glacial spires with Aether tech.",
        BossKey = nil,
        Enemies = {
            { Name = "Cyber Mercenary", Level = 760, HP = 16500, IsBoss = false, Drops = { { Item = "Glacier Shard", Rate = "42%" } } },
            { Name = "Frost Automaton", Level = 840, HP = 21000, IsBoss = false, Drops = { { Item = "Glacier Shard", Rate = "42%" }, { Item = "Sky Iron", Rate = "55%" } } },
        },
    },
    {
        Id = "CyberportCafe",
        Sea = "Sea2",
        SeaLabel = "SKY 2",
        NameVi = "Quán Cafe Giao Dịch (Cyberport)",
        NameEn = "Cyberport Trading Cafe",
        LevelRange = "Lv. 700+",
        Pos = Vector3.new(9400, 50.9, 1785),
        MapPos = Vector2.new(0.56, 0.20),
        AllMapPos = Vector2.new(0.66, 0.22),
        Accent = Color3.fromRGB(116, 238, 255),
        DescVi = "Trung tâm giao dịch Trái Ác Quỷ, nhận nhiệm vụ Sky 2 và nâng cấp Haki.",
        DescEn = "Bustling Sky 2 safe hub for Devil Fruit trading, quests, and Haki mastery.",
        BossKey = nil,
        Enemies = {
            { Name = "Mecha Drone", Level = 720, HP = 14000, IsBoss = false, Drops = { { Item = "Core Microchip", Rate = "25%" } } },
        },
    },
    {
        Id = "PermafrostGarrison",
        Sea = "Sea2",
        SeaLabel = "SKY 2",
        NameVi = "Pháo Đài Băng Vĩnh Cửu",
        NameEn = "Permafrost Garrison Fortress",
        LevelRange = "Lv. 875 - 1100",
        Pos = Vector3.new(9400, 50.9, -2055),
        MapPos = Vector2.new(0.80, 0.34),
        AllMapPos = Vector2.new(0.53, 0.48),
        Accent = Color3.fromRGB(92, 186, 255),
        DescVi = "Thành lũy băng giá của Quân Đoàn Bắn Tỉa Hàn Băng.",
        DescEn = "Armored ice fortress defended by Glacial Snipers and Arctic Corsairs.",
        BossKey = nil,
        Enemies = {
            { Name = "Glacial Sniper", Level = 950, HP = 26000, IsBoss = false, Drops = { { Item = "Glacier Shard", Rate = "45%" } } },
            { Name = "Arctic Corsair", Level = 1050, HP = 31000, IsBoss = false, Drops = { { Item = "Eternal Frost", Rate = "7%" } } },
        },
    },
    {
        Id = "MicrochipRaidLab",
        Sea = "Sea2",
        SeaLabel = "SKY 2",
        NameVi = "Phòng Thí Nghiệm Thức Tỉnh V2",
        NameEn = "Microchip Awakening Raid Lab",
        LevelRange = "Lv. 1100 - 1250",
        Pos = Vector3.new(14600, 50.9, 1785),
        MapPos = Vector2.new(0.26, 0.66),
        AllMapPos = Vector2.new(0.66, 0.50),
        Accent = Color3.fromRGB(72, 245, 215),
        DescVi = "Phòng thí nghiệm bí mật chứa Boss Order Cyborg và Chip Thức Tỉnh Trái V2.",
        DescEn = "Secret raid lab housing Order Cyborg Boss and V2 Fruit Awakening chips.",
        BossKey = "OrderCyborg",
        BossDisplay = "Order Cyborg Boss",
        Enemies = {
            { Name = "Order Cyborg", Level = 1150, HP = 36000, IsBoss = false, Drops = { { Item = "Core Microchip", Rate = "30%" } } },
            {
                Name = "Order Cyborg Boss",
                Level = 1225,
                HP = 125000,
                IsBoss = true,
                Drops = {
                    { Item = "Cryo Railgun", Rate = "5%" },
                    { Item = "Core Essence", Rate = "100%" },
                },
            },
        },
    },
    {
        Id = "GlacialWreckage",
        Sea = "Sea2",
        SeaLabel = "SKY 2",
        NameVi = "Vùng Biển Băng Nguy Hiểm",
        NameEn = "Glacial Wreckage Danger Sea",
        LevelRange = "Lv. 1250 - 1375",
        Pos = Vector3.new(14600, 50.9, -1812),
        MapPos = Vector2.new(0.56, 0.78),
        AllMapPos = Vector2.new(0.53, 0.78),
        Accent = Color3.fromRGB(108, 198, 242),
        DescVi = "Nghĩa địa chiến hạm đóng băng nơi Tiên Phong Hàn Băng tuần tra.",
        DescEn = "Frozen airship graveyard patrolled by elite Cryo Vanguards.",
        BossKey = nil,
        Enemies = {
            { Name = "Cryo Vanguard", Level = 1325, HP = 44000, IsBoss = false, Drops = { { Item = "Glacier Shard", Rate = "48%" }, { Item = "Eternal Frost", Rate = "8%" } } },
        },
    },
    {
        Id = "CryonArena",
        Sea = "Sea2",
        SeaLabel = "SKY 2",
        NameVi = "Đấu Trường Băng Vương Cryon",
        NameEn = "Cryon Archon Raid Arena",
        LevelRange = "Lv. 1375 - 1500",
        Pos = Vector3.new(12000, 50.9, -285),
        MapPos = Vector2.new(0.82, 0.74),
        AllMapPos = Vector2.new(0.66, 0.78),
        Accent = Color3.fromRGB(132, 238, 255),
        DescVi = "Đỉnh cao Sky 2: Đánh bại Băng Vương Cryon để đoạt Hàn Băng Thần Kiếm và mở Sky 3!",
        DescEn = "Apex of Sky 2: Defeat Cryon Archon for Cryon Frostblade and unlock Sky 3!",
        BossKey = "Cryon",
        BossDisplay = "Cryon Archon",
        Enemies = {
            {
                Name = "Cryon Archon",
                Level = 1500,
                HP = 210000,
                IsBoss = true,
                Drops = {
                    { Item = "Cryon Frostblade", Rate = "6%" },
                    { Item = "Cryo Railgun", Rate = "5%" },
                    { Item = "Core Essence", Rate = "100%" },
                },
            },
        },
    },

    -- SEA 3 (6 Islands • Lv. 1500 - 2550)
    {
        Id = "ShadowRealm",
        Sea = "Sea3",
        SeaLabel = "SKY 3",
        NameVi = "Lãnh Địa Hư Không (Shadow Realm)",
        NameEn = "Shadow Realm Rift",
        LevelRange = "Lv. 1500 - 1750",
        Pos = Vector3.new(-12593.4, 50.9, 414),
        MapPos = Vector2.new(0.20, 0.24),
        AllMapPos = Vector2.new(0.80, 0.18),
        Accent = Color3.fromRGB(184, 102, 255),
        DescVi = "Quần đảo pha lê tím trôi dạt giữa khe nứt Hư Không của Sky 3.",
        DescEn = "Shattered obsidian islands drifting across the abyssal rift of Sky 3.",
        BossKey = nil,
        Enemies = {
            { Name = "Void Raider", Level = 1580, HP = 58000, IsBoss = false, Drops = { { Item = "Void Crystal", Rate = "45%" } } },
            { Name = "Void Marauder", Level = 1700, HP = 69000, IsBoss = false, Drops = { { Item = "Void Crystal", Rate = "50%" } } },
        },
    },
    {
        Id = "CastleOnTheVoid",
        Sea = "Sea3",
        SeaLabel = "SKY 3",
        NameVi = "Lâu Đài Trên Hư Không",
        NameEn = "Castle on the Void Hub",
        LevelRange = "Lv. 1500+",
        Pos = Vector3.new(-14600, 50.9, 2173.1),
        MapPos = Vector2.new(0.52, 0.20),
        AllMapPos = Vector2.new(0.91, 0.22),
        Accent = Color3.fromRGB(214, 136, 255),
        DescVi = "Thành trì trung tâm Sky 3 kết nối Cổng Dịch Chuyển tất cả Đảo và Đền Tộc V4.",
        DescEn = "Central Sky 3 citadel linking Fast Travel portals and Race V4 trials.",
        BossKey = nil,
        Enemies = {
            { Name = "Void Sentinel", Level = 1650, HP = 64000, IsBoss = false, Drops = { { Item = "Void Crystal", Rate = "48%" } } },
        },
    },
    {
        Id = "UmbralSanctum",
        Sea = "Sea3",
        SeaLabel = "SKY 3",
        NameVi = "Rừng Tinh Thể Hắc Ám (Umbral)",
        NameEn = "Umbral Crystal Sanctum",
        LevelRange = "Lv. 1750 - 2000",
        Pos = Vector3.new(-9400, 50.9, 1815),
        MapPos = Vector2.new(0.82, 0.30),
        AllMapPos = Vector2.new(0.80, 0.48),
        Accent = Color3.fromRGB(162, 92, 248),
        DescVi = "Khu rừng tinh thể phát sáng nơi Hồn Ma Hắc Ám ẩn hiện.",
        DescEn = "Bioluminescent crystal forest haunted by Shadow Specters and Umbral Rangers.",
        BossKey = nil,
        Enemies = {
            { Name = "Shadow Specter", Level = 1840, HP = 82000, IsBoss = false, Drops = { { Item = "Void Crystal", Rate = "50%" }, { Item = "Soul Guitar", Rate = "4%" } } },
            { Name = "Umbral Ranger", Level = 1960, HP = 94000, IsBoss = false, Drops = { { Item = "Void Crystal", Rate = "52%" } } },
        },
    },
    {
        Id = "TempleOfTheCore",
        Sea = "Sea3",
        SeaLabel = "SKY 3",
        NameVi = "Đền Cổ Thức Tỉnh Tộc V4",
        NameEn = "Temple of the Core (Race V4)",
        LevelRange = "Lv. 2000 - 2150",
        Pos = Vector3.new(-14600, 50.9, -1785),
        MapPos = Vector2.new(0.24, 0.72),
        AllMapPos = Vector2.new(0.91, 0.50),
        Accent = Color3.fromRGB(255, 204, 88),
        DescVi = "Thánh điện tối thượng mở khóa Đôi Cánh Thức Tỉnh Tộc V4 [Y] và Song Kiếm Thiên Không.",
        DescEn = "Sacred Trial Temple unlocking Race V4 Wings [Y] and Cursed Dual Skyblades.",
        BossKey = "Veyr",
        BossDisplay = "Architect Veyr",
        RaidId = "Veyr",
        Enemies = {
            {
                Name = "Architect Veyr",
                Level = 2150,
                HP = 340000,
                IsBoss = true,
                Drops = {
                    { Item = "Cursed Dual Skyblades", Rate = "2.5%" },
                    { Item = "Soul Guitar", Rate = "4%" },
                    { Item = "Core Essence", Rate = "100%" },
                },
            },
        },
    },
    {
        Id = "LeviathanAbyss",
        Sea = "Sea3",
        SeaLabel = "SKY 3",
        NameVi = "Vực Thẳm Hải Vương Leviathan",
        NameEn = "Mirage & Leviathan Abyss",
        LevelRange = "Lv. 2150 - 2375",
        Pos = Vector3.new(-12000, 50.9, -3364.5),
        MapPos = Vector2.new(0.54, 0.80),
        AllMapPos = Vector2.new(0.80, 0.78),
        Accent = Color3.fromRGB(78, 178, 255),
        DescVi = "Vùng biển mây bão tố nơi Thần Thú Hải Vương Leviathan trỗi dậy.",
        DescEn = "Storm-wracked cloud abyss where the colossal Abyssal Leviathan surfaces.",
        BossKey = "Leviathan",
        BossDisplay = "Abyssal Leviathan",
        Enemies = {
            {
                Name = "Abyssal Leviathan",
                Level = 2350,
                HP = 420000,
                IsBoss = true,
                Drops = {
                    { Item = "Leviathan Shield", Rate = "3%" },
                    { Item = "Soul Guitar", Rate = "4%" },
                    { Item = "Core Essence", Rate = "100%" },
                },
            },
        },
    },
    {
        Id = "NoxarArena",
        Sea = "Sea3",
        SeaLabel = "SKY 3",
        NameVi = "Điện Thờ Hư Không Đế Vương Noxar",
        NameEn = "Noxar Sovereign Abyssal Arena",
        LevelRange = "Lv. 2375 - 2550",
        Pos = Vector3.new(-11672.2, 50.9, -110),
        MapPos = Vector2.new(0.84, 0.74),
        AllMapPos = Vector2.new(0.91, 0.78),
        Accent = Color3.fromRGB(255, 84, 118),
        DescVi = "Đỉnh cao Lv.2550: Đối đầu Hư Không Đế Vương Noxar đoạt Đại Đao Hư Không & Song Kiếm CDK!",
        DescEn = "Lv.2550 Endgame Raid: Confront Sovereign Noxar for Noxar's Abyssal Greatsword & CDK!",
        BossKey = "Noxar",
        BossDisplay = "Sovereign Noxar",
        RaidId = "Noxar",
        Enemies = {
            {
                Name = "Sovereign Noxar",
                Level = 2550,
                HP = 550000,
                IsBoss = true,
                Drops = {
                    { Item = "Noxar's Abyssal Greatsword", Rate = "2%" },
                    { Item = "Cursed Dual Skyblades", Rate = "2.5%" },
                    { Item = "Core Essence", Rate = "100%" },
                },
            },
        },
    },
}

local ISLAND_BY_ID = {}
for _, isl in ipairs(TWENTY_ISLANDS) do
    ISLAND_BY_ID[isl.Id] = isl
end

-- Override coordinates from Shared.Config.Islands if present so 3D distances match live workspace 100%
if GameplayConfig and type(GameplayConfig.Islands) == "table" then
    for _, cfgIsl in ipairs(GameplayConfig.Islands) do
        local match = cfgIsl.Id and ISLAND_BY_ID[cfgIsl.Id]
        if match and typeof(cfgIsl.Center) == "Vector3" then
            match.Pos = cfgIsl.Center
        elseif match and typeof(cfgIsl.Pos) == "Vector3" then
            match.Pos = cfgIsl.Pos
        end
    end
end

local function getIslandName(isl)
    return I18n.GetLanguage() == "en" and isl.NameEn or isl.NameVi
end

local function getIslandDesc(isl)
    return I18n.GetLanguage() == "en" and isl.DescEn or isl.DescVi
end

-- #61: Project Gameplay3x live player world (X, Z) onto AstrolabeCanvas without center bunching
local SEA_BOUNDS_3X = {
    Sea1 = { minX = -3600, maxX = 3600, minZ = -1550, maxZ = 1250, allU0 = 0.07, allU1 = 0.40 },
    Sea2 = { minX = 8650, maxX = 15350, minZ = -2600, maxZ = 2450, allU0 = 0.48, allU1 = 0.69 },
    Sea3 = { minX = -15350, maxX = -8650, minZ = -4200, maxZ = 2450, allU0 = 0.77, allU1 = 0.94 },
}

local function projectGameplay3xGpsToCanvas(pos: Vector3, seaFilter: string): (boolean, number, number)
    if pos.Z <= -7500 then
        return false, 0.5, 0.5
    end
    local seaKey = "Sea1"
    if pos.X >= 5500 then
        seaKey = "Sea2"
    elseif pos.X <= -5500 then
        seaKey = "Sea3"
    end
    if seaFilter ~= "All" and seaFilter ~= seaKey then
        return false, 0.5, 0.5
    end
    local b = SEA_BOUNDS_3X[seaKey]
    local nx = math.clamp((pos.X - b.minX) / math.max(1, b.maxX - b.minX), 0, 1)
    local nz = math.clamp((pos.Z - b.minZ) / math.max(1, b.maxZ - b.minZ), 0, 1)
    -- Higher Z (south/shrines) -> top-to-bottom normalized v so islands spread naturally across canvas
    local v = math.clamp(0.14 + (1 - nz) * 0.74, 0.10, 0.90)
    if seaFilter == "All" then
        local u = math.clamp(b.allU0 + nx * (b.allU1 - b.allU0), b.allU0, b.allU1)
        return true, u, v
    end
    local u = math.clamp(0.10 + nx * 0.80, 0.08, 0.92)
    return true, u, v
end

-- #61: Detect live nearest island to LocalPlayer.Character ("BẠN ĐANG Ở ĐÂY")
local function detectCurrentIslandId(snap)
    local lp = Players.LocalPlayer
    local ch = lp and lp.Character
    local rootPart = ch and (ch.PrimaryPart or ch:FindFirstChild("HumanoidRootPart"))
    if rootPart then
        local pos = rootPart.Position
        local bestId = "SkyHub"
        local bestDist = math.huge
        for _, isl in ipairs(TWENTY_ISLANDS) do
            local d = (isl.Pos - pos).Magnitude
            if d < bestDist then
                bestDist = d
                bestId = isl.Id
            end
        end
        return bestId, math.floor(bestDist)
    end
    local curWorld = snap and snap.world and snap.world.current
    if curWorld and ISLAND_BY_ID[curWorld] then
        return curWorld, 0
    end
    return "SkyHub", 0
end

-- #61: Scan workspace for live Boss Alive / HP% / Respawning status
local function queryLiveBossStatus(bossKey)
    if not bossKey or bossKey == "" then
        return false, 0
    end
    local keyLow = string.lower(bossKey)
    local containers = {
        workspace:FindFirstChild("ActiveBosses"),
        workspace:FindFirstChild("ActiveEnemies"),
        workspace:FindFirstChild("Enemies"),
        workspace:FindFirstChild("Bosses"),
        workspace:FindFirstChild("NPCs"),
        workspace,
    }
    for _, folder in ipairs(containers) do
        if folder then
            for _, child in ipairs(folder:GetChildren()) do
                if child:IsA("Model") then
                    local enemyId = tostring(child:GetAttribute("EnemyId") or child:GetAttribute("BossId") or "")
                    local matchStr = string.lower(child.Name .. " " .. enemyId)
                    if string.find(matchStr, keyLow, 1, true) and child:GetAttribute("EnemyDead") ~= true then
                        local hum = child:FindFirstChildOfClass("Humanoid")
                        if hum and hum.Health > 0 then
                            local pct = math.clamp(math.floor((hum.Health / math.max(1, hum.MaxHealth)) * 100 + 0.5), 1, 100)
                            return true, pct
                        end
                        local hpAttr = tonumber(child:GetAttribute("HP"))
                        if hpAttr and hpAttr > 0 then
                            local maxHpAttr = tonumber(child:GetAttribute("MaxHP")) or hpAttr
                            local pct = math.clamp(math.floor((hpAttr / math.max(1, maxHpAttr)) * 100 + 0.5), 1, 100)
                            return true, pct
                        end
                    end
                end
            end
        end
    end
    return false, 0
end

local function requestIslandFastTravel(isl)
    if WorldConfig.RealmById[isl.Id] or (WorldConfig.IslandById and WorldConfig.IslandById[isl.Id]) then
        PartyController.RequestFastTravel(isl.Id)
        return
    end
    local snap = Store.GetSnapshot()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes and snap and not snap.isDemoMode then
        if remotes:FindFirstChild("EquipmentRequest") then
            remotes.EquipmentRequest:FireServer({ action = "FastTravel", nodeId = isl.Id, islandId = isl.Id })
        elseif remotes:FindFirstChild("UIRequest") then
            remotes.UIRequest:FireServer("FastTravel", { islandId = isl.Id, nodeId = isl.Id })
        elseif remotes:FindFirstChild("InteractRequest") then
            remotes.InteractRequest:FireServer("FastTravel", { islandId = isl.Id, nodeId = isl.Id })
        end
    end
    if snap and snap.world then
        snap.world.current = isl.Id
    end
    Store.ShowToast(
        I18n.Pick("Đang dịch chuyển nhanh tới " .. getIslandName(isl) .. "...", "Fast Traveling to " .. getIslandName(isl) .. "..."),
        "success",
        2.6
    )
end

function WorldMap.Build(parent)
    WorldMap.Cleanup()
    local colors = Theme.Colors
    local snap = Store.GetSnapshot()
    local view = Store.GetView()

    local hereIslandId = detectCurrentIslandId(snap)
    if view.selectedRealmId and ISLAND_BY_ID[view.selectedRealmId] then
        WorldMap.SelectedIslandId = view.selectedRealmId
    elseif not ISLAND_BY_ID[WorldMap.SelectedIslandId] then
        WorldMap.SelectedIslandId = hereIslandId
    end
    local selectedIsland = ISLAND_BY_ID[WorldMap.SelectedIslandId] or TWENTY_ISLANDS[1]

    local root = UIFactory.Create("Frame", parent, {
        Name = "WorldMapScreen",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 2,
    })

    -- #10: Shared Top Header Bar with complete NavTabs
    local _, headerRefs = UIFactory.BuildScreenHeader(root, {
        ActiveScreen = UIState.Screens.WorldMap,
        Title = I18n.T("map.title"),
        Snapshot = snap,
        OnNavigate = function(targetId)
            ScreenRouter.Navigate(targetId)
        end,
        OnClose = function()
            ScreenRouter.CloseAllToHUD()
        end,
    })

    -- Left Interactive 20-Island Astrolabe Map Panel (61% width)
    local mapPanel = PremiumPanel.Create(root, {
        name = "WorldMap",
        title = I18n.Pick("BẢN ĐỒ THIÊN GIỚI 20 ĐẢO (SKY 1 • SKY 2 • SKY 3)", "CELESTIAL 20-ISLAND WORLD MAP (SKY 1 - SKY 3)"),
        subtitle = I18n.Pick("Định vị trực tiếp • Trạng thái Boss Live • Dịch chuyển 1 chạm", "Live GPS Marker • Real-Time Boss Status • 1-Click Fast Travel"),
        position = UDim2.fromOffset(16, 74),
        size = UDim2.new(0.61, -12, 1, -88),
    })

    -- Sea Filter Tabs Bar (#61)
    local seaTabsRow = UIFactory.Create("Frame", mapPanel, {
        Name = "SeaFilterTabs",
        Position = UDim2.fromOffset(14, 54),
        Size = UDim2.new(1, -28, 0, 32),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(seaTabsRow, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    local seaFilters = {
        { id = "All", label = I18n.Pick("TẤT CẢ (20 ĐẢO)", "ALL (20 ISLANDS)"), w = 136 },
        { id = "Sea1", label = "SKY 1 (8 • LV.1-700)", w = 152 },
        { id = "Sea2", label = "SKY 2 (6 • LV.700-1500)", w = 164 },
        { id = "Sea3", label = "SKY 3 (6 • LV.1500-2550)", w = 168 },
    }
    for idx, sf in ipairs(seaFilters) do
        local isSel = (WorldMap.ActiveSeaFilter == sf.id)
        PremiumButton.Create(seaTabsRow, {
            name = "SeaTab_" .. sf.id,
            label = sf.label,
            variant = isSel and "gold" or "secondary",
            selected = isSel,
            size = UDim2.fromOffset(sf.w, 30),
            textSize = 11,
            minTextSize = 9,
            layoutOrder = idx,
            onActivated = function()
                WorldMap.ActiveSeaFilter = sf.id
                if sf.id ~= "All" and selectedIsland.Sea ~= sf.id then
                    for _, candidate in ipairs(TWENTY_ISLANDS) do
                        if candidate.Sea == sf.id then
                            WorldMap.SelectedIslandId = candidate.Id
                            Store.SetView({ selectedRealmId = candidate.Id })
                            break
                        end
                    end
                end
                ScreenRouter.Navigate(UIState.Screens.WorldMap, { forceRebuild = true, replace = true })
            end,
        })
    end

    local mapCanvas = UIFactory.Create("Frame", mapPanel, {
        Name = "AstrolabeCanvas",
        Position = UDim2.fromOffset(14, 92),
        Size = UDim2.new(1, -28, 1, -104),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    })
    UIFactory.Corner(mapCanvas, Theme.Radius.Medium)
    UIFactory.Stroke(mapCanvas, colors.STROKE_STEEL, 1, 0.38)
    UIFactory.Gradient(mapCanvas, Color3.fromRGB(14, 28, 52), colors.BG_900, 45)

    if UIAssets.IsValidAssetId(UIAssets.WorldMapBackground) then
        UIFactory.Create("ImageLabel", mapCanvas, {
            Name = "RealmIllustration",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Image = UIAssets.WorldMapBackground,
            ImageTransparency = 0.30,
            ScaleType = Enum.ScaleType.Crop,
            ZIndex = 2,
        })
    end

    -- Sea Zone Dividers in "All" 20-Island View, or Constellation Orbit Rings in single-Sea view
    if WorldMap.ActiveSeaFilter == "All" then
        for _, divX in ipairs({ 0.445, 0.73 }) do
            UIFactory.Create("Frame", mapCanvas, {
                Name = "SeaZoneDivider",
                Position = UDim2.new(divX, 0, 0, 12),
                Size = UDim2.new(0, 1, 1, -24),
                BackgroundColor3 = colors.STROKE_STEEL,
                BackgroundTransparency = 0.45,
                BorderSizePixel = 0,
                ZIndex = 2,
            })
        end
        for _, zHdr in ipairs({
            { txt = "SKY 1 • LV. 1 - 700", x = 0.22, col = colors.ACCENT_GOLD },
            { txt = "SKY 2 • LV. 700 - 1500", x = 0.59, col = colors.ACCENT_SAPPHIRE },
            { txt = "SKY 3 • LV. 1500 - 2550", x = 0.86, col = colors.VOID_PURPLE },
        }) do
            UIFactory.Label(mapCanvas, {
                Name = "ZoneTitle",
                AnchorPoint = Vector2.new(0.5, 0),
                Position = UDim2.new(zHdr.x, 0, 0, 6),
                Size = UDim2.fromOffset(180, 18),
                Text = zHdr.txt,
                TextSize = 11,
                TextColor = zHdr.col,
                Bold = true,
                XAlign = Enum.TextXAlignment.Center,
                ZIndex = 3,
            })
        end
    else
        for idx, ringScale in ipairs({ 0.42, 0.76 }) do
            local ring = UIFactory.Create("Frame", mapCanvas, {
                Name = "OrbitRing_" .. idx,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(0.5, 0.5),
                Size = UDim2.fromScale(ringScale, ringScale * 0.86),
                BackgroundTransparency = 1,
                ZIndex = 2,
            })
            UIFactory.PillCorner(ring)
            UIFactory.Stroke(ring, idx == 1 and colors.ACCENT_GOLD or colors.STROKE_STEEL, 1, 0.62)
        end
    end

    -- Render Island Nodes on Canvas
    local isCompactAll = (WorldMap.ActiveSeaFilter == "All")
    local nodeW = isCompactAll and 104 or 168
    local nodeH = isCompactAll and 54 or 68

    for _, isl in ipairs(TWENTY_ISLANDS) do
        if WorldMap.ActiveSeaFilter == "All" or isl.Sea == WorldMap.ActiveSeaFilter then
            local pos2D = isCompactAll and isl.AllMapPos or isl.MapPos
            local isHere = (isl.Id == hereIslandId)
            local isSelected = (isl.Id == selectedIsland.Id)
            local bossAlive = isl.BossKey and queryLiveBossStatus(isl.BossKey) or false

            local nodeBtn = UIFactory.Create("TextButton", mapCanvas, {
                Name = "IslandNode_" .. isl.Id,
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.fromScale(pos2D.X, pos2D.Y),
                Size = UDim2.fromOffset(nodeW, nodeH),
                BackgroundColor3 = isSelected and colors.BG_700 or colors.BG_800,
                BackgroundTransparency = 0.04,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                ZIndex = isSelected and 8 or 5,
            })
            UIFactory.Corner(nodeBtn, Theme.Radius.Small)
            UIFactory.Stroke(
                nodeBtn,
                isHere and colors.SUCCESS or (isSelected and colors.ACCENT_GOLD or isl.Accent),
                (isSelected or isHere) and 2.2 or 1.3,
                0.1
            )

            local titleLbl = UIFactory.Label(nodeBtn, {
                Name = "Name",
                Text = getIslandName(isl),
                Position = UDim2.fromOffset(6, 4),
                Size = UDim2.new(1, -12, 0, 18),
                TextSize = isCompactAll and 10 or 12,
                TextColor = isl.Accent,
                Bold = true,
                XAlign = Enum.TextXAlignment.Center,
                Truncate = Enum.TextTruncate.AtEnd,
                ZIndex = nodeBtn.ZIndex + 1,
            })
            titleLbl.TextScaled = true
            UIFactory.TextSizeConstraint(titleLbl, 8, isCompactAll and 10 or 12)

            UIFactory.Label(nodeBtn, {
                Name = "LvRange",
                Text = isl.LevelRange,
                Position = UDim2.fromOffset(6, 21),
                Size = UDim2.new(1, -12, 0, 15),
                TextSize = isCompactAll and 9 or 11,
                TextColor = colors.TEXT_PRIMARY,
                XAlign = Enum.TextXAlignment.Center,
                ZIndex = nodeBtn.ZIndex + 1,
            })

            local statusTxt = isHere
                and I18n.Pick("BẠN ĐANG Ở ĐÂY", "YOU ARE HERE")
                or (isl.BossKey and (bossAlive and I18n.Pick("BOSS ĐANG SỐNG", "BOSS ALIVE") or I18n.Pick("BOSS HỒI SINH", "BOSS RESPAWN")) or isl.SeaLabel)
            local statusCol = isHere
                and colors.SUCCESS
                or (bossAlive and colors.HP_RED or (isl.BossKey and colors.ACCENT_GOLD or colors.TEXT_SECONDARY))

            local stLbl = UIFactory.Label(nodeBtn, {
                Name = "StatusTag",
                Text = statusTxt,
                Position = UDim2.fromOffset(4, isCompactAll and 36 or 44),
                Size = UDim2.new(1, -8, 0, 15),
                TextSize = isCompactAll and 8 or 10,
                TextColor = statusCol,
                Bold = true,
                XAlign = Enum.TextXAlignment.Center,
                Truncate = Enum.TextTruncate.AtEnd,
                ZIndex = nodeBtn.ZIndex + 1,
            })
            stLbl.TextScaled = true
            UIFactory.TextSizeConstraint(stLbl, 7, isCompactAll and 9 or 10)

            nodeBtn.Activated:Connect(function()
                WorldMap.SelectedIslandId = isl.Id
                Store.SetView({ selectedRealmId = isl.Id })
                ScreenRouter.Navigate(UIState.Screens.WorldMap, { forceRebuild = true, replace = true })
            end)
        end
    end

    -- Live Pulsing Gameplay3x Player GPS Marker on AstrolabeCanvas (ZIndex = 12)
    local livePlayerMarker = UIFactory.Create("Frame", mapCanvas, {
        Name = "LivePlayerMarker",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.22, 0.30),
        Size = UDim2.fromOffset(22, 22),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 12,
    })
    local pulseRing = UIFactory.Create("Frame", livePlayerMarker, {
        Name = "PulseRing",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(20, 20),
        BackgroundColor3 = colors.SUCCESS,
        BackgroundTransparency = 0.55,
        BorderSizePixel = 0,
        ZIndex = 12,
    })
    UIFactory.PillCorner(pulseRing)
    UIFactory.Stroke(pulseRing, colors.SUCCESS, 1.6, 0.1)

    local coreDot = UIFactory.Create("Frame", livePlayerMarker, {
        Name = "CoreDot",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(9, 9),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = 13,
    })
    UIFactory.PillCorner(coreDot)
    UIFactory.Stroke(coreDot, colors.SUCCESS, 2.0, 0)

    UIFactory.Label(livePlayerMarker, {
        Name = "YouTag",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 0, -2),
        Size = UDim2.fromOffset(48, 13),
        Text = I18n.Pick("BẠN", "YOU"),
        TextSize = 9,
        TextColor = colors.SUCCESS,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        ZIndex = 13,
    })

    local activeFilterNow = WorldMap.ActiveSeaFilter
    local gpsConn = RunService.Heartbeat:Connect(function()
        if not livePlayerMarker.Parent then
            return
        end
        local lp = Players.LocalPlayer
        local ch = lp and lp.Character
        local rp = ch and (ch.PrimaryPart or ch:FindFirstChild("HumanoidRootPart"))
        local wpos = rp and rp.Position or Vector3.new(-317.4, 50.5, 527.8)
        local vis, u, v = projectGameplay3xGpsToCanvas(wpos, activeFilterNow)
        livePlayerMarker.Visible = vis
        if vis then
            livePlayerMarker.Position = UDim2.fromScale(u, v)
            local pulse = 16 + math.sin(os.clock() * 5.2) * 4.5
            pulseRing.Size = UDim2.fromOffset(pulse, pulse)
        end
    end)

    -- Right Inspector & Bestiary Codex Column (39% width) (#61 & #99)
    local detailPanel = PremiumPanel.Create(root, {
        name = "WorldDetail",
        variant = "gold",
        title = string.upper(getIslandName(selectedIsland)),
        subtitle = selectedIsland.SeaLabel .. "  •  " .. selectedIsland.LevelRange,
        position = UDim2.new(0.61, 10, 0, 74),
        size = UDim2.new(0.39, -26, 1, -88),
    })

    -- Top Drawer Tabs inside Inspector: [THÔNG TIN ĐẢO & BOSS] vs [CODEX / TỈ LỆ RỚT ĐỒ] (#99)
    local drawerTabs = UIFactory.Create("Frame", detailPanel, {
        Name = "InspectorTabs",
        Position = UDim2.fromOffset(16, 54),
        Size = UDim2.new(1, -32, 0, 34),
        BackgroundTransparency = 1,
    })

    PremiumButton.Create(drawerTabs, {
        name = "TabIslandInfo",
        icon = "Map",
        label = I18n.Pick("THÔNG TIN ĐẢO", "ISLAND & BOSS"),
        variant = (WorldMap.InspectorTab == "Info") and "primary" or "secondary",
        selected = (WorldMap.InspectorTab == "Info"),
        position = UDim2.fromOffset(0, 0),
        size = UDim2.new(0.48, -4, 1, 0),
        textSize = 11,
        minTextSize = 9,
        onActivated = function()
            WorldMap.InspectorTab = "Info"
            ScreenRouter.Navigate(UIState.Screens.WorldMap, { forceRebuild = true, replace = true })
        end,
    })

    PremiumButton.Create(drawerTabs, {
        name = "TabBestiaryCodex",
        icon = "Book",
        label = I18n.Pick("CODEX / TỈ LỆ RỚT ĐỒ", "CODEX & DROP RATES"),
        variant = (WorldMap.InspectorTab == "Codex") and "gold" or "secondary",
        selected = (WorldMap.InspectorTab == "Codex"),
        position = UDim2.new(0.48, 4, 0, 0),
        size = UDim2.new(0.52, -4, 1, 0),
        textSize = 11,
        minTextSize = 9,
        onActivated = function()
            WorldMap.InspectorTab = "Codex"
            ScreenRouter.Navigate(UIState.Screens.WorldMap, { forceRebuild = true, replace = true })
        end,
    })

    local function buildGlossyEnemyRow(parentScroll, en, isl, idxOrder)
        local tierKey = "Common"
        local iconKind = "Bolt"
        local topColor = Color3.fromRGB(75, 94, 122)
        local botColor = Color3.fromRGB(30, 41, 59)
        local rimColor = Color3.fromRGB(148, 168, 196)
        if en.IsBoss then
            tierKey = "MYTHIC"
            iconKind = "Crown"
            topColor = Color3.fromRGB(251, 113, 133)
            botColor = Color3.fromRGB(147, 51, 234)
            rimColor = Color3.fromRGB(255, 182, 212)
        elseif (tonumber(en.Level) or 1) >= 450 then
            tierKey = "EPIC"
            iconKind = "Shield"
            topColor = Color3.fromRGB(192, 132, 252)
            botColor = Color3.fromRGB(91, 33, 182)
            rimColor = Color3.fromRGB(228, 184, 255)
        elseif (tonumber(en.Level) or 1) >= 40 then
            tierKey = "RARE"
            iconKind = "Sword"
            topColor = Color3.fromRGB(56, 189, 248)
            botColor = Color3.fromRGB(29, 78, 216)
            rimColor = Color3.fromRGB(147, 224, 255)
        else
            tierKey = "COMMON"
        end

        local dropRows = math.max(1, math.ceil(#(en.Drops or {}) / 2))
        local cardH = math.max(76, 46 + dropRows * 24)
        local eCard = UIFactory.Create("Frame", parentScroll, {
            Name = "EnemyCard_" .. idxOrder,
            Size = UDim2.new(1, -6, 0, cardH),
            BackgroundColor3 = colors.BG_900,
            BackgroundTransparency = 0.06,
            BorderSizePixel = 0,
            LayoutOrder = idxOrder,
        })
        UIFactory.Corner(eCard, Theme.Radius.Medium)
        UIFactory.Stroke(eCard, en.IsBoss and colors.ACCENT_GOLD or colors.STROKE_STEEL, en.IsBoss and 1.6 or 1.1, 0.25)

        -- Left Glossy Rarity Thumbnail Tile (Figma SKYBREAK_Figma_v2_02_WorldMap_Atlas.png)
        local thumb = UIFactory.Create("Frame", eCard, {
            Name = "RarityTile",
            Position = UDim2.fromOffset(8, 8),
            Size = UDim2.fromOffset(58, 60),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = 4,
        })
        UIFactory.Corner(thumb, Theme.Radius.Small)
        UIFactory.Stroke(thumb, rimColor, 1.5, 0.1)
        UIFactory.Gradient(thumb, topColor, botColor, 90)

        local sheen = UIFactory.Create("Frame", thumb, {
            Name = "TopSheen",
            Position = UDim2.fromOffset(2, 2),
            Size = UDim2.new(1, -4, 0.38, 0),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 0.84,
            BorderSizePixel = 0,
            ZIndex = 5,
        })
        UIFactory.Corner(sheen, 4)

        local numPill = UIFactory.Create("Frame", thumb, {
            Name = "IdxPill",
            Position = UDim2.fromOffset(3, 3),
            Size = UDim2.fromOffset(22, 13),
            BackgroundColor3 = colors.BG_900,
            BackgroundTransparency = 0.15,
            BorderSizePixel = 0,
            ZIndex = 6,
        })
        UIFactory.Corner(numPill, 3)
        UIFactory.Label(numPill, {
            Text = "#" .. tostring(idxOrder),
            Size = UDim2.fromScale(1, 1),
            TextSize = 8,
            TextColor = colors.TEXT_PRIMARY,
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            Wrapped = false,
            ZIndex = 7,
        })

        local iconInst = UIFactory.Icon(thumb, iconKind, UDim2.new(0.5, -12, 0.42, -11), 24, Color3.new(1, 1, 1))
        iconInst.ZIndex = 6

        local tierFooter = UIFactory.Create("Frame", thumb, {
            Name = "TierFooter",
            Position = UDim2.new(0, 3, 1, -16),
            Size = UDim2.new(1, -6, 0, 13),
            BackgroundColor3 = colors.BG_900,
            BackgroundTransparency = 0.14,
            BorderSizePixel = 0,
            ZIndex = 6,
        })
        UIFactory.Corner(tierFooter, 3)
        UIFactory.Label(tierFooter, {
            Text = tierKey,
            Size = UDim2.fromScale(1, 1),
            TextSize = 8,
            TextColor = rimColor,
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            Wrapped = false,
            ZIndex = 7,
        })

        UIFactory.Label(eCard, {
            Name = "EnemyTitle",
            Text = (en.IsBoss and ("BOSS • " .. en.Name) or en.Name),
            Position = UDim2.fromOffset(76, 6),
            Size = UDim2.new(1, -86, 0, 18),
            TextSize = 13,
            TextColor = en.IsBoss and colors.ACCENT_GOLD_BRIGHT or colors.TEXT_PRIMARY,
            Bold = true,
            Truncate = Enum.TextTruncate.AtEnd,
            Wrapped = false,
        })

        UIFactory.Label(eCard, {
            Name = "EnemyStats",
            Text = string.format("Lv. %d • HP %s%s", en.Level, UIFactory.FormatNumber(en.HP), isl and (" • " .. isl.SeaLabel) or ""),
            Position = UDim2.fromOffset(76, 24),
            Size = UDim2.new(1, -86, 0, 15),
            TextSize = 10,
            TextColor = colors.TEXT_SECONDARY,
            Truncate = Enum.TextTruncate.AtEnd,
            Wrapped = false,
        })

        local dropsFrame = UIFactory.Create("Frame", eCard, {
            Name = "DropPills",
            Position = UDim2.fromOffset(76, 43),
            Size = UDim2.new(1, -84, 1, -49),
            BackgroundTransparency = 1,
        })
        UIFactory.GridLayout(dropsFrame, UDim2.new(0.5, -4, 0, 21), UDim2.fromOffset(6, 4))

        for dIdx, dr in ipairs(en.Drops or {}) do
            local rateNum = tonumber((tostring(dr.Rate):gsub("%%", ""))) or 10
            local pillCol = (rateNum <= 8) and Color3.fromRGB(251, 113, 133)
                or ((rateNum <= 25) and colors.ACCENT_GOLD_BRIGHT or colors.ACCENT_SAPPHIRE)

            local dPill = UIFactory.Create("Frame", dropsFrame, {
                Name = "Drop_" .. dIdx,
                BackgroundColor3 = colors.BG_800,
                BorderSizePixel = 0,
                LayoutOrder = dIdx,
            })
            UIFactory.Corner(dPill, 5)
            UIFactory.Stroke(dPill, pillCol, 1.1, 0.28)

            UIFactory.Label(dPill, {
                Name = "ItemTxt",
                Text = tostring(dr.Item),
                Position = UDim2.fromOffset(6, 0),
                Size = UDim2.new(1, -44, 1, 0),
                TextSize = 10,
                TextColor = colors.TEXT_PRIMARY,
                Bold = true,
                Truncate = Enum.TextTruncate.AtEnd,
                Wrapped = false,
            })
            UIFactory.Label(dPill, {
                Name = "RateTxt",
                Text = tostring(dr.Rate),
                Position = UDim2.new(1, -38, 0, 0),
                Size = UDim2.fromOffset(32, 21),
                TextSize = 10,
                TextColor = pillCol,
                Bold = true,
                XAlign = Enum.TextXAlignment.Right,
                Wrapped = false,
            })
        end
    end

    if WorldMap.InspectorTab == "Info" then
        local isHere = (selectedIsland.Id == hereIslandId)
        local bossAlive, bossHpPct = queryLiveBossStatus(selectedIsland.BossKey)

        -- Island Lore & GPS Summary Card (Figma Top Box)
        local liveStatusCard = UIFactory.Create("Frame", detailPanel, {
            Name = "LiveStatusCard",
            Position = UDim2.fromOffset(16, 94),
            Size = UDim2.new(1, -32, 0, 78),
            BackgroundColor3 = colors.BG_900,
            BorderSizePixel = 0,
        })
        UIFactory.Corner(liveStatusCard, Theme.Radius.Medium)
        UIFactory.Stroke(liveStatusCard, isHere and colors.SUCCESS or selectedIsland.Accent, 1.3, 0.2)

        local bossLineText = isHere
            and I18n.Pick("VỊ TRÍ HIỆN TẠI: BẠN ĐANG Ở ĐẢO NÀY", "GPS STATUS: YOU ARE CURRENTLY HERE")
            or (selectedIsland.SeaLabel .. " • " .. selectedIsland.LevelRange)
        local bossLineCol = isHere and colors.SUCCESS or colors.ACCENT_GOLD_BRIGHT
        if selectedIsland.BossKey and bossAlive then
            bossLineText = I18n.Pick(
                string.format("BOSS %s: ĐANG XUẤT HIỆN (HP %d%%)", string.upper(selectedIsland.BossDisplay or selectedIsland.BossKey), bossHpPct),
                string.format("BOSS %s: ALIVE IN WORKSPACE (HP %d%%)", string.upper(selectedIsland.BossDisplay or selectedIsland.BossKey), bossHpPct)
            )
            bossLineCol = colors.HP_RED
        end

        UIFactory.Label(liveStatusCard, {
            Name = "GpsLine",
            Text = bossLineText,
            Position = UDim2.fromOffset(12, 6),
            Size = UDim2.new(1, -24, 0, 18),
            TextSize = 11,
            TextColor = bossLineCol,
            Bold = true,
            Truncate = Enum.TextTruncate.AtEnd,
            Wrapped = false,
        })

        UIFactory.Label(liveStatusCard, {
            Name = "WorldInfo",
            Text = getIslandDesc(selectedIsland),
            Position = UDim2.fromOffset(12, 25),
            Size = UDim2.new(1, -24, 0, 48),
            TextSize = 11,
            TextColor = colors.TEXT_SECONDARY,
            YAlign = Enum.TextYAlignment.Top,
        })

        local infoEnemyScroll = UIFactory.Create("ScrollingFrame", detailPanel, {
            Name = "IslandEnemyPreviewScroll",
            Position = UDim2.fromOffset(16, 180),
            Size = UDim2.new(1, -32, 1, -286),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 5,
            ScrollBarImageColor3 = colors.ACCENT_GOLD,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.fromOffset(0, 0),
        })
        UIFactory.ListLayout(infoEnemyScroll, Enum.FillDirection.Vertical, 8)

        for idx, en in ipairs(selectedIsland.Enemies or {}) do
            buildGlossyEnemyRow(infoEnemyScroll, en, nil, idx)
        end
    else
        -- #99: CODEX / TỈ LỆ RỚT ĐỒ (Bestiary & Exact Percentage Drop Rates Drawer)
        local scopeRow = UIFactory.Create("Frame", detailPanel, {
            Name = "CodexScopeBar",
            Position = UDim2.fromOffset(16, 94),
            Size = UDim2.new(1, -32, 0, 28),
            BackgroundTransparency = 1,
        })

        PremiumButton.Create(scopeRow, {
            name = "CodexThisIsland",
            label = I18n.Pick("ĐẢO ĐANG CHỌN", "SELECTED ISLAND"),
            variant = (not WorldMap.CodexShowAll) and "primary" or "secondary",
            selected = (not WorldMap.CodexShowAll),
            position = UDim2.fromOffset(0, 0),
            size = UDim2.new(0.5, -4, 1, 0),
            textSize = 10,
            minTextSize = 8,
            onActivated = function()
                WorldMap.CodexShowAll = false
                ScreenRouter.Navigate(UIState.Screens.WorldMap, { forceRebuild = true, replace = true })
            end,
        })

        PremiumButton.Create(scopeRow, {
            name = "CodexAll20Islands",
            label = I18n.Pick("TOÀN BỘ 20 ĐẢO & BOSS", "ALL 20 ISLANDS & BOSSES"),
            variant = WorldMap.CodexShowAll and "gold" or "secondary",
            selected = WorldMap.CodexShowAll,
            position = UDim2.new(0.5, 4, 0, 0),
            size = UDim2.new(0.5, -4, 1, 0),
            textSize = 10,
            minTextSize = 8,
            onActivated = function()
                WorldMap.CodexShowAll = true
                ScreenRouter.Navigate(UIState.Screens.WorldMap, { forceRebuild = true, replace = true })
            end,
        })

        local codexScroll = UIFactory.Create("ScrollingFrame", detailPanel, {
            Name = "BestiaryCodexScroll",
            Position = UDim2.fromOffset(16, 128),
            Size = UDim2.new(1, -32, 1, -234),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 5,
            ScrollBarImageColor3 = colors.ACCENT_GOLD,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.fromOffset(0, 0),
        })
        UIFactory.ListLayout(codexScroll, Enum.FillDirection.Vertical, 8)

        local sourceIslands = WorldMap.CodexShowAll and TWENTY_ISLANDS or { selectedIsland }
        local entryOrder = 0
        for _, isl in ipairs(sourceIslands) do
            for _, en in ipairs(isl.Enemies or {}) do
                entryOrder += 1
                buildGlossyEnemyRow(codexScroll, en, WorldMap.CodexShowAll and isl or nil, entryOrder)
            end
        end
    end

    -- 2 Signature Bottom CTA Buttons from Figma SKYBREAK_Figma_v2_02_WorldMap_Atlas.png:
    -- 1) Glossy Gold Fast Travel
    -- 2) Glossy Sapphire Minimap Waypoint Compass
    PremiumButton.Create(detailPanel, {
        name = "FastTravelButton",
        icon = "Wing",
        label = I18n.Pick("DỊCH CHUYỂN TỨC THỜI ĐẾN " .. string.upper(getIslandName(selectedIsland)), "FAST TRAVEL TO " .. string.upper(getIslandName(selectedIsland))),
        variant = "gold",
        position = UDim2.new(0, 16, 1, -98),
        size = UDim2.new(1, -32, 0, 42),
        textSize = 12,
        minTextSize = 9,
        onActivated = function()
            requestIslandFastTravel(selectedIsland)
        end,
    })

    PremiumButton.Create(detailPanel, {
        name = "SetWaypointCompassButton",
        icon = "Compass",
        label = selectedIsland.RaidId
            and I18n.Pick("ĐẶT KIM CHỈ NAM & XEM CƠ CHẾ RAID [P]", "SET WAYPOINT & INSPECT RAID [P]")
            or I18n.Pick("ĐẶT KIM CHỈ NAM DẪN ĐƯỜNG TRÊN MINIMAP", "SET WAYPOINT COMPASS ON MINIMAP"),
        variant = "primary",
        position = UDim2.new(0, 16, 1, -50),
        size = UDim2.new(1, -32, 0, 38),
        textSize = 11,
        minTextSize = 9,
        onActivated = function()
            Store.Session.mapWaypointPos = selectedIsland.Pos
            Store.Session.mapWaypointName = getIslandName(selectedIsland)
            local lp = Players.LocalPlayer
            if lp then
                lp:SetAttribute("CustomWaypointPos", selectedIsland.Pos)
                lp:SetAttribute("CustomWaypointName", getIslandName(selectedIsland))
            end
            Store.ShowToast(
                I18n.Pick("Đã đặt Kim Chỉ Nam dẫn đường tới " .. getIslandName(selectedIsland) .. "!", "Minimap Waypoint locked onto " .. getIslandName(selectedIsland) .. "!"),
                "info",
                2.2
            )
            if selectedIsland.RaidId and WorldConfig.Raids[selectedIsland.RaidId] then
                Store.SetView({ selectedRaidId = selectedIsland.RaidId })
            end
        end,
    })

    WorldMap.Refs = {
        Root = root,
        HeaderRefs = headerRefs,
        LivePlayerMarker = livePlayerMarker,
        GpsConn = gpsConn,
    }
    return root
end

function WorldMap.Update(snap)
    if WorldMap.Refs.HeaderRefs and WorldMap.Refs.HeaderRefs.UpdateCurrencies then
        WorldMap.Refs.HeaderRefs.UpdateCurrencies(snap or Store.GetSnapshot())
    end
end

function WorldMap.Cleanup()
    if WorldMap.Refs and WorldMap.Refs.GpsConn then
        WorldMap.Refs.GpsConn:Disconnect()
    end
    WorldMap.Refs = {}
end

return WorldMap
