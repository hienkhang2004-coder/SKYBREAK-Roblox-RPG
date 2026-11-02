-- SKYBREAK: Fragments of the Core — Zioles 3D Gacha Shrine, 6-Rarity Permanent Vault & Separated 3D Fruits ([G])
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/Fruits.lua
-- Visual Upgrade: Matches Figma Design File 3 (SKYBREAK_NPC_01 Left Panel) 1:1 with Live 3D Zioles Bust,
-- Concentric 3D Rotating Fruit Stage, 6-Rarity Drop Rates + Mythic Pity Pill, Glossy 6-Rarity Tiles, and 3.2s Gacha Spin.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local UIState = require(Shared:WaitForChild("Types"):WaitForChild("UIState"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Store = require(script.Parent.Parent:WaitForChild("Store"))
local ScreenRouter = require(script.Parent.Parent:WaitForChild("ScreenRouter"))
local I18n = require(script.Parent.Parent:WaitForChild("I18n"))
local PremiumPanel = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumPanel"))
local PremiumButton = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumButton"))
local ViewportOrbit = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("ViewportOrbit"))

local Renderer = ViewportOrbit.GetRenderer()

local Fruits = {
    SelectedFruitId = nil,
    OrbitController = nil,
    ZiolesBustConn = nil,
    GachaConnection = nil,
    GachaOverlay = nil,
    GachaOrbit = nil,
    Refs = nil,
}

local RARITY_PALETTE = {
    Common = {
        Top = Color3.fromRGB(75, 94, 120),
        Bottom = Color3.fromRGB(30, 41, 59),
        Stroke = Color3.fromRGB(148, 168, 196),
        Text = Color3.fromRGB(196, 212, 232),
        Tag = "COMMON",
        Rate = "42.0%",
        LabelVi = "Common (Phổ Biến)",
        LabelEn = "Common",
    },
    Uncommon = {
        Top = Color3.fromRGB(22, 189, 136),
        Bottom = Color3.fromRGB(8, 92, 68),
        Stroke = Color3.fromRGB(110, 242, 190),
        Text = Color3.fromRGB(92, 236, 174),
        Tag = "UNCOMMON",
        Rate = "25.0%",
        LabelVi = "Uncommon (Tinh Anh)",
        LabelEn = "Uncommon",
    },
    Rare = {
        Top = Color3.fromRGB(56, 189, 248),
        Bottom = Color3.fromRGB(29, 78, 216),
        Stroke = Color3.fromRGB(147, 224, 255),
        Text = Color3.fromRGB(108, 206, 255),
        Tag = "RARE",
        Rate = "18.0%",
        LabelVi = "Rare (Hiếm)",
        LabelEn = "Rare",
    },
    Epic = {
        Top = Color3.fromRGB(192, 132, 252),
        Bottom = Color3.fromRGB(91, 33, 182),
        Stroke = Color3.fromRGB(228, 184, 255),
        Text = Color3.fromRGB(214, 158, 255),
        Tag = "EPIC",
        Rate = "9.0%",
        LabelVi = "Epic (Sử Thi)",
        LabelEn = "Epic",
    },
    Legendary = {
        Top = Color3.fromRGB(252, 211, 77),
        Bottom = Color3.fromRGB(180, 83, 9),
        Stroke = Color3.fromRGB(255, 242, 166),
        Text = Color3.fromRGB(255, 218, 92),
        Tag = "LEGEND",
        Rate = "4.5%",
        LabelVi = "Legendary (Huyền Thoại)",
        LabelEn = "Legendary",
    },
    Mythical = {
        Top = Color3.fromRGB(251, 113, 133),
        Bottom = Color3.fromRGB(147, 51, 234),
        Stroke = Color3.fromRGB(255, 182, 212),
        Text = Color3.fromRGB(255, 128, 164),
        Tag = "MYTHIC",
        Rate = "1.5%",
        LabelVi = "Mythic (Thần Thoại)",
        LabelEn = "Mythic",
    },
}
RARITY_PALETTE.Mythic = RARITY_PALETTE.Mythical

local RARITY_ORDER = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical" }

local RARITY_COLORS = {
    Common = RARITY_PALETTE.Common.Text,
    Uncommon = RARITY_PALETTE.Uncommon.Text,
    Rare = RARITY_PALETTE.Rare.Text,
    Epic = RARITY_PALETTE.Epic.Text,
    Legendary = RARITY_PALETTE.Legendary.Text,
    Mythical = RARITY_PALETTE.Mythical.Text,
    Mythic = RARITY_PALETTE.Mythical.Text,
}

local FRUIT_CATALOG = {
    {
        Id = "GaleCore",
        Asset = "Fruit_GaleCore",
        ShortVi = "Cuồng Phong",
        ShortEn = "Gale Core",
        NameVi = "Trái Cuồng Phong (Gale Core)",
        NameEn = "Gale Core Fruit",
        Rarity = "Common",
        Type = "Elemental (Logia)",
        Element = "Sky",
        Icon = "Wing",
        Color = Color3.fromRGB(165, 245, 215),
        DescVi = "Hóa thân thành gió lốc nguyên tố, miễn nhiễm đòn đánh thường và tạo lốc xoáy tốc độ cao.",
        DescEn = "Transform into elemental gale wind with Logia immunity and high-velocity cyclone slashes.",
        Moves = {
            { Key = "Z", Name = "Wind Cutter Slash", Mult = "1.9x ATK", Range = "24m", Cd = "3.0s" },
            { Key = "X", Name = "Cyclone Vortex Burst", Mult = "2.4x ATK", Range = "26m", Cd = "4.5s" },
            { Key = "C", Name = "Tempest Tornado Pillar", Mult = "3.1x ATK", Range = "30m", Cd = "6.5s" },
            { Key = "V", Name = "Sky Hurricane Cataclysm", Mult = "4.0x ATK", Range = "34m", Cd = "9.0s" },
            { Key = "F", Name = "Zephyr Jet Flight", Mult = "1.6x ATK", Range = "28m", Cd = "3.5s" },
        },
    },
    {
        Id = "SandstoneCore",
        Asset = "Fruit_SandstoneCore",
        ShortVi = "Sa Mạc Kim",
        ShortEn = "Sandstone",
        NameVi = "Trái Sa Mạc Hoàng Kim (Sandstone)",
        NameEn = "Golden Sandstone Core",
        Rarity = "Uncommon",
        Type = "Elemental (Logia)",
        Element = "Sky",
        Icon = "Fruit",
        Color = Color3.fromRGB(235, 195, 110),
        DescVi = "Điều khiển bão cát hoàng kim sa mạc, trói chân mục tiêu trong lốc cát.",
        DescEn = "Command golden desert sandstorms and snare targets inside quicksand vortices.",
        Moves = {
            { Key = "Z", Name = "Desert Blade Spada", Mult = "2.0x ATK", Range = "25m", Cd = "3.2s" },
            { Key = "X", Name = "Quicksand Tomb Trap", Mult = "2.6x ATK", Range = "26m", Cd = "4.8s" },
            { Key = "C", Name = "Sandstorm Sables", Mult = "3.3x ATK", Range = "30m", Cd = "6.5s" },
            { Key = "V", Name = "Imperial Desert Burial", Mult = "4.3x ATK", Range = "36m", Cd = "9.5s" },
            { Key = "F", Name = "Dune Whirlwind Flight", Mult = "1.6x ATK", Range = "28m", Cd = "3.8s" },
        },
    },
    {
        Id = "SolarFlameCore",
        Asset = "Fruit_SolarFlameCore",
        ShortVi = "Hỏa Dương",
        ShortEn = "Solar Flame",
        NameVi = "Trái Hỏa Dương (Solar Flame)",
        NameEn = "Solar Flame Core",
        Rarity = "Rare",
        Type = "Elemental (Logia)",
        Element = "Sky",
        Icon = "Flame",
        Color = Color3.fromRGB(255, 125, 45),
        DescVi = "Ngọn lửa mặt trời rực cháy thiêu rụi mọi kẻ địch với Hỏa Quyền và Đại Viêm Đế.",
        DescEn = "Blazing solar fire that incinerates foes with Fire Fist and Solar Emperor Nova.",
        Moves = {
            { Key = "Z", Name = "Fire Fist Hiken", Mult = "2.2x ATK", Range = "28m", Cd = "3.2s" },
            { Key = "X", Name = "Solar Flame Pillar", Mult = "2.9x ATK", Range = "30m", Cd = "4.8s" },
            { Key = "C", Name = "Cross Fire Barrage", Mult = "3.5x ATK", Range = "32m", Cd = "6.5s" },
            { Key = "V", Name = "Dai Enkai: Flame Emperor", Mult = "4.8x ATK", Range = "40m", Cd = "9.5s" },
            { Key = "F", Name = "Rocket Flame Jet", Mult = "1.7x ATK", Range = "28m", Cd = "3.5s" },
        },
    },
    {
        Id = "GlacierIceCore",
        Asset = "Fruit_GlacierIceCore",
        ShortVi = "Băng Hà",
        ShortEn = "Glacier Ice",
        NameVi = "Trái Băng Hà Vĩnh Cửu (Glacier Ice)",
        NameEn = "Glacier Ice Core",
        Rarity = "Rare",
        Type = "Elemental (Logia)",
        Element = "Frost",
        Icon = "Frost",
        Color = Color3.fromRGB(115, 235, 255),
        DescVi = "Đóng băng không gian với Kỷ Băng Hà Tuyệt Đối và lướt băng trên không trung.",
        DescEn = "Freeze battlefields solid with Absolute Zero Epoch and glide across sky ice.",
        Moves = {
            { Key = "Z", Name = "Ice Bird Surge", Mult = "2.3x ATK", Range = "28m", Cd = "3.5s" },
            { Key = "X", Name = "Glacial Surge Spears", Mult = "3.0x ATK", Range = "30m", Cd = "5.0s" },
            { Key = "C", Name = "Permafrost Tornado", Mult = "3.7x ATK", Range = "34m", Cd = "7.0s" },
            { Key = "V", Name = "Absolute Zero Epoch", Mult = "4.8x ATK", Range = "38m", Cd = "10.0s" },
            { Key = "F", Name = "Glacial Sky Skate", Mult = "1.7x ATK", Range = "28m", Cd = "4.0s" },
        },
    },
    {
        Id = "CelestialLightCore",
        Asset = "Fruit_CelestialLightCore",
        ShortVi = "Ánh Sáng",
        ShortEn = "Celestial Light",
        NameVi = "Trái Ánh Sáng Thiên Giới (Light)",
        NameEn = "Celestial Light Core",
        Rarity = "Epic",
        Type = "Elemental (Logia)",
        Element = "Sky",
        Icon = "Star",
        Color = Color3.fromRGB(255, 242, 135),
        DescVi = "Di chuyển và tung mưa quang năng ở vận tốc ánh sáng.",
        DescEn = "Travel at lightspeed and rain sacred photon spears from the firmament.",
        Moves = {
            { Key = "Z", Name = "Photon Spear Beam", Mult = "2.4x ATK", Range = "32m", Cd = "3.2s" },
            { Key = "X", Name = "Mirror Kick Barrage", Mult = "3.1x ATK", Range = "30m", Cd = "4.8s" },
            { Key = "C", Name = "Yasakani Sacred Jewels", Mult = "3.9x ATK", Range = "36m", Cd = "6.8s" },
            { Key = "V", Name = "Heavenly Judgement Ray", Mult = "5.0x ATK", Range = "42m", Cd = "9.5s" },
            { Key = "F", Name = "Lightspeed Starlight Flight", Mult = "1.9x ATK", Range = "32m", Cd = "3.2s" },
        },
    },
    {
        Id = "StarforgedMagmaCore",
        Asset = "Fruit_StarforgedMagmaCore",
        ShortVi = "Dung Nham",
        ShortEn = "Star Magma",
        NameVi = "Trái Dung Nham Tinh Cầu (Magma)",
        NameEn = "Starforged Magma Core",
        Rarity = "Epic",
        Type = "Elemental (Logia)",
        Element = "Sky",
        Icon = "Flame",
        Color = Color3.fromRGB(255, 82, 48),
        DescVi = "Sức sát thương nguyên tố cao nhất với mưa thiên thạch dung nham và Minh Cẩu.",
        DescEn = "Supreme elemental burn damage with volcanic meteor showers and Magma Hound.",
        Moves = {
            { Key = "Z", Name = "Magma Clap Eruption", Mult = "2.5x ATK", Range = "26m", Cd = "3.5s" },
            { Key = "X", Name = "Volcanic Meigo Hound", Mult = "3.2x ATK", Range = "30m", Cd = "5.0s" },
            { Key = "C", Name = "Meteor Volcano Shower", Mult = "4.0x ATK", Range = "34m", Cd = "7.0s" },
            { Key = "V", Name = "Great Starforged Hound", Mult = "5.2x ATK", Range = "38m", Cd = "10.0s" },
            { Key = "F", Name = "Magma Beast Flight", Mult = "1.8x ATK", Range = "28m", Cd = "4.0s" },
        },
    },
    {
        Id = "ThunderRumbleCore",
        Asset = "Fruit_ThunderRumbleCore",
        ShortVi = "Lôi Thần",
        ShortEn = "Thunder Rumble",
        NameVi = "Trái Lôi Thần (Thunder Rumble)",
        NameEn = "Thunder Rumble Core",
        Rarity = "Legendary",
        Type = "Elemental (Logia)",
        Element = "Lightning",
        Icon = "Lightning",
        Color = Color3.fromRGB(88, 210, 255),
        DescVi = "Triệu hồi Lôi Long và quả cầu sấm sét Raigo hủy diệt diện rộng.",
        DescEn = "Summon Thunder Dragons and colossal Raigo storm spheres across the sky.",
        Moves = {
            { Key = "Z", Name = "Thunderball Dragon", Mult = "2.5x ATK", Range = "30m", Cd = "3.5s" },
            { Key = "X", Name = "Sky Thunder Judgement", Mult = "3.2x ATK", Range = "32m", Cd = "5.0s" },
            { Key = "C", Name = "Ion Storm Barrage", Mult = "3.9x ATK", Range = "36m", Cd = "7.0s" },
            { Key = "V", Name = "Raigo Thundercloud Sphere", Mult = "5.2x ATK", Range = "42m", Cd = "10.0s" },
            { Key = "F", Name = "Lightning Flash Teleport", Mult = "1.9x ATK", Range = "28m", Cd = "4.0s" },
        },
    },
    {
        Id = "AstralGravityCore",
        Asset = "Fruit_AstralGravityCore",
        ShortVi = "Trọng Lực",
        ShortEn = "Astral Gravity",
        NameVi = "Trái Trọng Lực Tinh Vân (Gravity)",
        NameEn = "Astral Gravity Core",
        Rarity = "Legendary",
        Type = "Natural (Paramecia)",
        Element = "Void",
        Icon = "Void",
        Color = Color3.fromRGB(185, 110, 255),
        DescVi = "Bẻ cong trường trọng lực không gian và kéo thiên thạch từ tầng sao.",
        DescEn = "Warp gravitational wells to crush enemies and pull astral meteors from orbit.",
        Moves = {
            { Key = "Z", Name = "Gravitational Push", Mult = "2.5x ATK", Range = "28m", Cd = "3.5s" },
            { Key = "X", Name = "Singularity Crush Zone", Mult = "3.3x ATK", Range = "32m", Cd = "5.0s" },
            { Key = "C", Name = "Astral Meteor Summon", Mult = "4.0x ATK", Range = "36m", Cd = "7.0s" },
            { Key = "V", Name = "Cataclysmic Starfall", Mult = "5.2x ATK", Range = "42m", Cd = "10.0s" },
            { Key = "F", Name = "Boulder Gravity Surf", Mult = "1.8x ATK", Range = "28m", Cd = "4.0s" },
        },
    },
    {
        Id = "DimensionalPortalCore",
        Asset = "Fruit_DimensionalPortalCore",
        ShortVi = "Không Gian",
        ShortEn = "World Portal",
        NameVi = "Trái Không Gian (Dimensional Portal)",
        NameEn = "Dimensional Portal Core",
        Rarity = "Legendary",
        Type = "Natural (Paramecia)",
        Element = "Void",
        Icon = "Compass",
        Color = Color3.fromRGB(120, 165, 255),
        DescVi = "Mở cổng dịch chuyển tức thời xuyên chiều không gian ([C] dịch chuyển 40m).",
        DescEn = "Tear dimensional rifts for instant spatial warps ([C] 40m World Gate).",
        Moves = {
            { Key = "Z", Name = "Warp Strike", Mult = "2.4x ATK", Range = "28m", Cd = "3.5s" },
            { Key = "X", Name = "Parallel Dimension Step", Mult = "3.0x ATK", Range = "30m", Cd = "5.0s" },
            { Key = "C", Name = "World Gate Teleport (40m)", Mult = "3.5x ATK", Range = "40m", Cd = "6.0s" },
            { Key = "V", Name = "Quantum Rift Domain", Mult = "4.9x ATK", Range = "38m", Cd = "10.0s" },
            { Key = "F", Name = "Rift Portal Dash", Mult = "1.8x ATK", Range = "28m", Cd = "4.0s" },
        },
    },
    {
        Id = "SolarTitanCore",
        Asset = "Fruit_SolarTitanCore",
        ShortVi = "Kim Thân Phật",
        ShortEn = "Solar Buddha",
        NameVi = "Trái Kim Thân Phật Tổ (Solar Buddha)",
        NameEn = "Solar Titan Buddha Core",
        Rarity = "Mythical",
        Type = "Beast (Mythical Zoan)",
        Element = "Sky",
        Icon = "Crown",
        Color = Color3.fromRGB(255, 208, 68),
        DescVi = "Chiêu [Z] hóa Kim Thân Khổng Lồ 3D (+58% Giáp, x2.2 tầm đánh mọi vũ khí & võ thuật)!",
        DescEn = "[Z] awakens 3D Colossal Golden Titan form (+58% DEF, 2.2x melee & sword reach)!",
        Moves = {
            { Key = "Z", Name = "Solar Titan Shift (3D Colossal)", Mult = "2.4x ATK", Range = "28m", Cd = "3.5s" },
            { Key = "X", Name = "Heavenly Palm Impact", Mult = "3.1x ATK", Range = "30m", Cd = "5.0s" },
            { Key = "C", Name = "Dawn Pillar Nova", Mult = "3.8x ATK", Range = "34m", Cd = "7.0s" },
            { Key = "V", Name = "Twilight Retribution", Mult = "5.0x ATK", Range = "40m", Cd = "10.0s" },
            { Key = "F", Name = "Radiant Sky Leap", Mult = "1.8x ATK", Range = "28m", Cd = "4.0s" },
        },
    },
    {
        Id = "AetherflowCore",
        Asset = "Fruit_AetherflowCore",
        ShortVi = "Linh Mạch",
        ShortEn = "Aetherflow",
        NameVi = "Trái Linh Mạch Aether (Aetherflow)",
        NameEn = "Aetherflow Sovereign Core",
        Rarity = "Mythical",
        Type = "Natural (Paramecia)",
        Element = "Sky",
        Icon = "Core",
        Color = Color3.fromRGB(95, 245, 235),
        DescVi = "Điều khiển tơ linh mạch Aether sắc bén cắt đôi bầu trời.",
        DescEn = "Weave razor-sharp celestial Aether threads that cleave through sky islands.",
        Moves = {
            { Key = "Z", Name = "Aether Silk Barrage", Mult = "2.6x ATK", Range = "30m", Cd = "3.5s" },
            { Key = "X", Name = "Sovereign String Cage", Mult = "3.4x ATK", Range = "32m", Cd = "5.0s" },
            { Key = "C", Name = "Overheated Aether Whip", Mult = "4.1x ATK", Range = "36m", Cd = "7.0s" },
            { Key = "V", Name = "Sixteen Holy Aether Spears", Mult = "5.4x ATK", Range = "42m", Cd = "10.0s" },
            { Key = "F", Name = "Sky Cloud Thread Soar", Mult = "1.9x ATK", Range = "30m", Cd = "3.8s" },
        },
    },
    {
        Id = "AbyssalSovereignCore",
        Asset = "Fruit_AbyssalSovereignCore",
        ShortVi = "Hắc Long 3D",
        ShortEn = "Void Dragon",
        NameVi = "Trái Long Vương Hư Không (Void Dragon)",
        NameEn = "Abyssal Sovereign Dragon Core",
        Rarity = "Mythical",
        Type = "Beast (Mythical Zoan)",
        Element = "Void",
        Icon = "Fruit",
        Color = Color3.fromRGB(178, 88, 255),
        DescVi = "Chiêu [V] hóa Thái Cổ Long Hoàng 3D bay lượn và phun Hơi Thở Hư Không hủy diệt!",
        DescEn = "[V] transforms into a 3D Sovereign Void Dragon unleashing cataclysmic breath!",
        Moves = {
            { Key = "Z", Name = "Void Heat Wave Beam", Mult = "2.7x ATK", Range = "32m", Cd = "3.5s" },
            { Key = "X", Name = "Abyssal Dragon Talons", Mult = "3.4x ATK", Range = "32m", Cd = "5.0s" },
            { Key = "C", Name = "Cataclysmic Meteor Shower", Mult = "4.2x ATK", Range = "38m", Cd = "7.0s" },
            { Key = "V", Name = "Imperial Sovereign Dragon 3D", Mult = "5.5x ATK", Range = "44m", Cd = "10.0s" },
            { Key = "F", Name = "Draconic Sky Soar", Mult = "2.0x ATK", Range = "28m", Cd = "4.0s" },
        },
    },
}

local FRUIT_BY_ID = {}
for _, f in ipairs(FRUIT_CATALOG) do
    FRUIT_BY_ID[f.Id] = f
end

local function getFruitName(item)
    if not item then
        return "Gale Core"
    end
    return I18n.GetLanguage() == "en" and item.NameEn or item.NameVi
end

local function getFruitShortName(item)
    if not item then
        return "Gale"
    end
    return I18n.GetLanguage() == "en" and (item.ShortEn or item.NameEn) or (item.ShortVi or item.NameVi)
end

local function getFruitDesc(item)
    if not item then
        return ""
    end
    return I18n.GetLanguage() == "en" and item.DescEn or item.DescVi
end

local function fireEquipRemote(payload)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        if remotes:FindFirstChild("EquipmentRequest") then
            remotes.EquipmentRequest:FireServer(payload)
        elseif remotes:FindFirstChild("FruitAction") then
            remotes.FruitAction:FireServer(payload)
        end
    end
end

local function fireAbilityRemote(payload)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes and remotes:FindFirstChild("AbilityRequest") then
        remotes.AbilityRequest:FireServer(payload)
    end
end

-- Pre-warm common/signature fruits asynchronously after startup so first [G] open is instant
task.defer(function()
    task.wait(1.5)
    if not Renderer or type(Renderer.Build) ~= "function" then
        return
    end
    for _, asset in ipairs({ "Fruit_GaleCore", "Fruit_SolarTitanCore", "Fruit_AbyssalSovereignCore" }) do
        pcall(Renderer.Build, asset)
        task.wait(0.08)
    end
end)

local function cleanupGachaOverlay()
    if Fruits.GachaConnection then
        Fruits.GachaConnection:Disconnect()
        Fruits.GachaConnection = nil
    end
    if Fruits.GachaOrbit then
        Fruits.GachaOrbit:Destroy()
        Fruits.GachaOrbit = nil
    end
    if Fruits.GachaOverlay and Fruits.GachaOverlay.Parent then
        Fruits.GachaOverlay:Destroy()
    end
    Fruits.GachaOverlay = nil
end

function Fruits.Cleanup()
    cleanupGachaOverlay()
    if Fruits.ZiolesBustConn then
        Fruits.ZiolesBustConn:Disconnect()
        Fruits.ZiolesBustConn = nil
    end
    if Fruits.OrbitController then
        Fruits.OrbitController:Destroy()
        Fruits.OrbitController = nil
    end
    Fruits.Refs = nil
end

-- Vivid 6-Rarity Glossy Tile helper matching Figma File 3 1:1
local function makeGlossyRarityTile(parent, opts)
    opts = opts or {}
    local pal = RARITY_PALETTE[opts.rarity or "Common"] or RARITY_PALETTE.Common
    local tile = UIFactory.Create("TextButton", parent, {
        Name = opts.name or "GlossyFruitTile",
        Position = opts.position or UDim2.fromOffset(0, 0),
        Size = opts.size or UDim2.fromOffset(88, 84),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = true,
        LayoutOrder = opts.layoutOrder or 1,
        ClipsDescendants = true,
    })
    UIFactory.Corner(tile, Theme.Radius.Medium)

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, pal.Top),
        ColorSequenceKeypoint.new(1, pal.Bottom),
    })
    grad.Rotation = 90
    grad.Parent = tile

    local stroke = UIFactory.Stroke(tile, opts.strokeColor or pal.Stroke, opts.strokeThickness or 1.4, 0.08)

    -- Top 40% white specular gloss sheen
    local sheen = UIFactory.Create("Frame", tile, {
        Name = "SpecularSheen",
        Size = UDim2.new(1, 0, 0.42, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.84,
        BorderSizePixel = 0,
    })
    UIFactory.Corner(sheen, Theme.Radius.Medium)

    -- Center soft aura disc
    local aura = UIFactory.Create("Frame", tile, {
        Name = "CenterAura",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.44, 0),
        Size = UDim2.fromOffset(42, 42),
        BackgroundColor3 = pal.Stroke,
        BackgroundTransparency = 0.72,
        BorderSizePixel = 0,
    })
    UIFactory.PillCorner(aura)

    -- Top-left category/status pill
    local tagPill = UIFactory.Create("Frame", tile, {
        Name = "TopPill",
        Position = UDim2.fromOffset(5, 4),
        Size = UDim2.new(1, -10, 0, 15),
        BackgroundColor3 = Color3.fromRGB(8, 12, 22),
        BackgroundTransparency = 0.22,
        BorderSizePixel = 0,
    })
    UIFactory.PillCorner(tagPill)
    local tagLbl = UIFactory.Label(tagPill, {
        Name = "TagText",
        Text = opts.topTag or pal.Tag,
        Position = UDim2.fromOffset(4, 0),
        Size = UDim2.new(1, -8, 1, 0),
        TextSize = 8,
        TextColor = opts.topTagColor or Color3.fromRGB(246, 250, 255),
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Truncate = Enum.TextTruncate.AtEnd,
    })

    -- Crisp white geometric vector icon in center
    UIFactory.Icon(tile, opts.icon or "Fruit", UDim2.new(0.5, -13, 0.45, -12), 26, Color3.fromRGB(255, 255, 255))

    -- Bottom dark obsidian caption bar (#090D18)
    local bottomBar = UIFactory.Create("Frame", tile, {
        Name = "BottomBar",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 21),
        BackgroundColor3 = Color3.fromRGB(9, 13, 24),
        BackgroundTransparency = 0.06,
        BorderSizePixel = 0,
    })
    local bottomLbl = UIFactory.Label(bottomBar, {
        Name = "BottomCaption",
        Text = opts.bottomCaption or pal.Tag,
        Position = UDim2.fromOffset(4, 0),
        Size = UDim2.new(1, -8, 1, 0),
        TextSize = 9,
        TextColor = opts.bottomColor or pal.Text,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Truncate = Enum.TextTruncate.AtEnd,
    })

    return tile, stroke, tagLbl, bottomLbl
end

-- Live 3D Sculpted Zioles Bust Card (matching SKYBREAK_NPC_01 Left Panel 1:1)
local function mountZiolesBustCard(parent, position, size)
    local colors = Theme.Colors
    local accent = Color3.fromRGB(192, 132, 252)

    local card = UIFactory.Create("Frame", parent, {
        Name = "ZiolesBustCard",
        Position = position,
        Size = size,
        BackgroundColor3 = Color3.fromRGB(11, 16, 30),
        BorderSizePixel = 0,
    })
    UIFactory.Corner(card, Theme.Radius.Medium)
    UIFactory.Stroke(card, accent, 1.5, 0.14)

    -- Soft radial glow behind bust
    local aura = UIFactory.Create("Frame", card, {
        Name = "RadialAura",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.36, 0),
        Size = UDim2.fromOffset(78, 78),
        BackgroundColor3 = accent,
        BackgroundTransparency = 0.78,
        BorderSizePixel = 0,
    })
    UIFactory.PillCorner(aura)

    local vp = UIFactory.Create("ViewportFrame", card, {
        Name = "ZiolesBustViewport",
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.new(1, -12, 0, 108),
        BackgroundColor3 = Color3.fromRGB(14, 19, 36),
        BackgroundTransparency = 0.12,
        BorderSizePixel = 0,
        Ambient = Color3.fromRGB(205, 198, 240),
        LightColor = Color3.fromRGB(245, 226, 255),
        LightDirection = Vector3.new(-0.5, -0.7, -1),
    })
    UIFactory.Corner(vp, Theme.Radius.Small)
    UIFactory.Stroke(vp, accent, 1.1, 0.35)

    local wm = Instance.new("WorldModel")
    wm.Parent = vp
    local cam = Instance.new("Camera")
    cam.FieldOfView = 32
    cam.Parent = vp
    vp.CurrentCamera = cam

    -- Build sculpted 3D Zioles Mystic Hooded Sage Bust
    local bustModel = Instance.new("Model")
    bustModel.Name = "Zioles3DBust"

    local function addPart(name, shape, sz, cf, col, mat)
        local p = Instance.new("Part")
        p.Name = name
        p.Shape = shape
        p.Size = sz
        p.CFrame = cf
        p.Color = col
        p.Material = mat or Enum.Material.SmoothPlastic
        p.Anchored = true
        p.CanCollide = false
        p.Parent = bustModel
        return p
    end

    local rootPart = addPart("Torso", Enum.PartType.Block, Vector3.new(2.1, 2.0, 1.1), CFrame.new(0, -0.35, 0), Color3.fromRGB(48, 26, 86))
    bustModel.PrimaryPart = rootPart
    addPart("GoldTrim", Enum.PartType.Block, Vector3.new(1.5, 0.32, 1.18), CFrame.new(0, 0.42, 0), Color3.fromRGB(244, 196, 84), Enum.Material.Metal)
    addPart("LeftPauldron", Enum.PartType.Ball, Vector3.new(0.85, 0.72, 0.95), CFrame.new(-1.18, 0.32, 0), Color3.fromRGB(88, 42, 148))
    addPart("RightPauldron", Enum.PartType.Ball, Vector3.new(0.85, 0.72, 0.95), CFrame.new(1.18, 0.32, 0), Color3.fromRGB(88, 42, 148))
    addPart("Head", Enum.PartType.Ball, Vector3.new(1.18, 1.22, 1.18), CFrame.new(0, 1.24, 0.04), Color3.fromRGB(24, 18, 38))
    addPart("HoodOuter", Enum.PartType.Ball, Vector3.new(1.52, 1.54, 1.48), CFrame.new(0, 1.32, -0.10), Color3.fromRGB(68, 30, 124))
    addPart("EyeL", Enum.PartType.Ball, Vector3.new(0.18, 0.11, 0.14), CFrame.new(-0.24, 1.26, 0.56), Color3.fromRGB(216, 156, 255), Enum.Material.Neon)
    addPart("EyeR", Enum.PartType.Ball, Vector3.new(0.18, 0.11, 0.14), CFrame.new(0.24, 1.26, 0.56), Color3.fromRGB(216, 156, 255), Enum.Material.Neon)
    addPart("AetherOrb", Enum.PartType.Ball, Vector3.new(0.42, 0.42, 0.42), CFrame.new(0, 2.22, 0), Color3.fromRGB(252, 211, 77), Enum.Material.Neon)

    bustModel.Parent = wm
    cam.CFrame = CFrame.lookAt(Vector3.new(0.35, 1.15, 4.75), Vector3.new(0, 0.92, 0))

    if Fruits.ZiolesBustConn then
        Fruits.ZiolesBustConn:Disconnect()
    end
    local t0 = os.clock()
    Fruits.ZiolesBustConn = RunService.RenderStepped:Connect(function()
        if not vp.Parent then
            if Fruits.ZiolesBustConn then
                Fruits.ZiolesBustConn:Disconnect()
                Fruits.ZiolesBustConn = nil
            end
            return
        end
        local t = os.clock() - t0
        local yaw = math.sin(t * 1.15) * 0.22
        local bob = math.sin(t * 2.1) * 0.06
        cam.CFrame = CFrame.lookAt(
            Vector3.new(math.sin(yaw) * 4.7, 1.15 + bob, math.cos(yaw) * 4.7),
            Vector3.new(0, 0.92, 0)
        )
    end)

    -- Overlapping "• 3D LIVE - ZIOLES" pill
    local livePill = UIFactory.Create("Frame", card, {
        Name = "Live3DPill",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 102),
        Size = UDim2.new(1, -14, 0, 19),
        BackgroundColor3 = Color3.fromRGB(14, 18, 32),
        BorderSizePixel = 0,
        ZIndex = 4,
    })
    UIFactory.PillCorner(livePill)
    UIFactory.Stroke(livePill, accent, 1.2, 0.15)
    UIFactory.Label(livePill, {
        Name = "LiveText",
        Text = "• 3D LIVE - ZIOLES",
        Size = UDim2.fromScale(1, 1),
        TextSize = 9,
        TextColor = Color3.fromRGB(216, 174, 255),
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        ZIndex = 5,
    })

    UIFactory.Label(card, {
        Name = "VendorTitle",
        Text = "ZIOLES • GACHA 3D",
        Position = UDim2.fromOffset(4, 126),
        Size = UDim2.new(1, -8, 0, 18),
        TextSize = 10,
        TextColor = colors.TEXT_PRIMARY,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Truncate = Enum.TextTruncate.AtEnd,
    })

    local cdLabel = UIFactory.Label(card, {
        Name = "CooldownStatus",
        Text = I18n.Pick("Hồi quay kế: SẴN SÀNG", "Next roll: READY"),
        Position = UDim2.fromOffset(4, 145),
        Size = UDim2.new(1, -8, 0, 16),
        TextSize = 9,
        TextColor = colors.SUCCESS,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Truncate = Enum.TextTruncate.AtEnd,
    })

    return card, cdLabel
end

local function classifyFruitPartRole(matName, assetName)
    local m = tostring(matName or "")
    local a = tostring(assetName or "")
    if m:find("Ring") or m:find("PortalSilver") or m:find("HaloSolar") or (m:find("BrightGold") and a:find("CelestialLightCore")) then
        return "Ring"
    elseif m:find("SilverWing") or m:find("SilverShadow") or m:find("DemonWingRed") then
        return "Wing"
    elseif m:find("Ribbon") or m:find("PortalCyanEmit") or m:find("DropletGold") or m:find("FrostIceLight") or m:find("RumbleArcEmit") or m:find("BasaltRimHot") or m:find("CharredBasalt") then
        return "Orbit"
    end
    return "Core"
end

-- Interactive 3D ViewportOrbit with +0.45 rad/s turntable
local function mount3DFruitPreview(viewport, fruitInfo)
    if not Fruits.OrbitController or Fruits.OrbitController.Viewport ~= viewport then
        if Fruits.OrbitController then
            Fruits.OrbitController:Destroy()
        end
        Fruits.OrbitController = ViewportOrbit.Attach(viewport, {
            AutoSpinSpeed = 0.45,
            InitialYaw = math.rad(24),
            InitialPitch = math.rad(10),
            ShowHint = false,
            FieldOfView = 35,
            FitMultiplier = 1.12,
        })
    end

    local orbit = Fruits.OrbitController
    orbit:SetCustomStep(nil)

    ViewportOrbit.MountAssetAsync(orbit, fruitInfo.Asset, fruitInfo.Color, {
        FitMultiplier = 1.12,
        ResetAngles = false,
    }, function(built, resolvedName)
        if Fruits.OrbitController ~= orbit or not built or not built.Parent then
            return
        end
        local okBox, boxCF, size = pcall(function()
            return built:GetBoundingBox()
        end)
        if not okBox or not boxCF then
            return
        end
        local maxDim = math.max(size.X, size.Y, size.Z, 1.4)
        local subParts = {}
        local partIdx = 0
        for _, d in ipairs(built:GetDescendants()) do
            if d:IsA("MeshPart") then
                partIdx += 1
                table.insert(subParts, {
                    Part = d,
                    RelCF = boxCF:ToObjectSpace(d.CFrame),
                    Role = classifyFruitPartRole(d:GetAttribute("BlenderMaterial"), resolvedName),
                    Index = partIdx,
                })
            end
        end
        local activeClip = nil
        if Renderer and type(Renderer.Clips) == "function" then
            local okC, clips = pcall(Renderer.Clips, resolvedName)
            if okC and type(clips) == "table" then
                activeClip = clips.ElementalSurge or clips.UltimateAwakening or clips.Idle
            end
        end

        orbit:SetCustomStep(function(_, t, mdl)
            if mdl ~= built or not built.Parent then
                return
            end
            local bob = math.sin(t * 2.4) * (maxDim * 0.032)
            local baseCF = CFrame.new(0, bob, 0) * CFrame.Angles(math.sin(t * 1.6) * 0.04, 0, 0)
            if built.PrimaryPart then
                built.PrimaryPart.CFrame = baseCF
            end
            for _, entry in ipairs(subParts) do
                local part = entry.Part
                if part and part.Parent then
                    if entry.Role == "Ring" then
                        part.CFrame = baseCF
                            * CFrame.Angles(math.sin(t * 2.4 + entry.Index) * 0.14, t * 1.1, math.cos(t * 2.0) * 0.10)
                            * entry.RelCF
                    elseif entry.Role == "Wing" then
                        local side = entry.RelCF.Position.X >= 0 and 1 or -1
                        part.CFrame = baseCF
                            * CFrame.new(0, math.sin(t * 3.6) * 0.03, 0)
                            * CFrame.Angles(0, 0, math.sin(t * 3.6) * 0.08 * side)
                            * entry.RelCF
                    elseif entry.Role == "Orbit" then
                        part.CFrame = baseCF
                            * CFrame.new(0, math.sin(t * 3.1 + entry.Index * 0.9) * 0.035, 0)
                            * CFrame.Angles(0, math.sin(t * 1.8) * 0.08, 0)
                            * entry.RelCF
                    else
                        part.CFrame = baseCF * entry.RelCF
                    end
                end
            end
            if activeClip and Renderer and type(Renderer.Pose) == "function" then
                pcall(Renderer.Pose, built, activeClip, t)
            end
        end)
    end)
end

-- Wide Cooldown pill & dark-sapphire move card layout with zero clipping
local function populateMovesList(movesList, selectedFruit, equippedId, colors)
    for _, ch in ipairs(movesList:GetChildren()) do
        if ch:IsA("GuiObject") then
            ch:Destroy()
        end
    end
    for idx, mv in ipairs(selectedFruit.Moves) do
        local mvCard = UIFactory.Create("Frame", movesList, {
            Name = "Move_" .. mv.Key,
            Size = UDim2.new(1, 0, 0, 62),
            BackgroundColor3 = Color3.fromRGB(13, 22, 41),
            BorderSizePixel = 0,
            LayoutOrder = idx,
        })
        UIFactory.Corner(mvCard, Theme.Radius.Small)
        UIFactory.Stroke(mvCard, selectedFruit.Color, 1.2, 0.25)

        local keyBadge = UIFactory.Create("Frame", mvCard, {
            Name = "KeyBadge",
            Position = UDim2.fromOffset(8, 10),
            Size = UDim2.fromOffset(42, 42),
            BackgroundColor3 = Color3.fromRGB(9, 14, 26),
            BorderSizePixel = 0,
        })
        UIFactory.Corner(keyBadge, Theme.Radius.Small)
        UIFactory.Stroke(keyBadge, selectedFruit.Color, 1.5, 0.1)
        UIFactory.Label(keyBadge, {
            Name = "KeyText",
            Text = "[" .. mv.Key .. "]",
            Size = UDim2.fromScale(1, 1),
            TextSize = 14,
            TextColor = selectedFruit.Color,
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
        })

        UIFactory.Label(mvCard, {
            Name = "MoveName",
            Text = mv.Name,
            Position = UDim2.fromOffset(58, 7),
            Size = UDim2.new(1, -162, 0, 20),
            TextSize = 13,
            TextColor = colors.TEXT_PRIMARY,
            Bold = true,
            Truncate = Enum.TextTruncate.AtEnd,
        })

        UIFactory.Label(mvCard, {
            Name = "MoveStats",
            Text = I18n.Pick(
                string.format("ST: %s  •  Tầm: %s", mv.Mult, mv.Range),
                string.format("DMG: %s  •  Rng: %s", mv.Mult, mv.Range)
            ),
            Position = UDim2.fromOffset(58, 32),
            Size = UDim2.fromOffset(132, 20),
            TextSize = 11,
            TextColor = colors.ACCENT_SAPPHIRE,
            Bold = true,
        })

        local cdPill = UIFactory.Create("Frame", mvCard, {
            Name = "CooldownPill",
            Position = UDim2.fromOffset(194, 32),
            Size = UDim2.fromOffset(86, 20),
            BackgroundColor3 = Color3.fromRGB(9, 14, 26),
            BorderSizePixel = 0,
        })
        UIFactory.PillCorner(cdPill)
        UIFactory.Stroke(cdPill, colors.ACCENT_GOLD, 1, 0.32)
        local cdLbl = UIFactory.Label(cdPill, {
            Name = "CdText",
            Text = I18n.Pick("Hồi: " .. mv.Cd, "CD: " .. mv.Cd),
            Position = UDim2.fromOffset(5, 0),
            Size = UDim2.new(1, -10, 1, 0),
            TextSize = 10,
            TextColor = colors.ACCENT_GOLD,
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
        })
        cdLbl.TextScaled = true
        UIFactory.TextSizeConstraint(cdLbl, 8, 10)

        PremiumButton.Create(mvCard, {
            name = "Cast_" .. mv.Key,
            label = I18n.Pick("DÙNG [" .. mv.Key .. "]", "CAST [" .. mv.Key .. "]"),
            variant = "primary",
            position = UDim2.new(1, -96, 0.5, -17),
            size = UDim2.fromOffset(88, 34),
            textSize = 11,
            minTextSize = 9,
            onActivated = function()
                local curSnap = Store.GetSnapshot()
                local curEq = (curSnap.fruits and curSnap.fruits.equippedFruit) or equippedId
                if curEq ~= selectedFruit.Id then
                    fireEquipRemote({ action = "EatFruit", fruitId = selectedFruit.Id })
                end
                fireEquipRemote({ action = "SelectSlot", slot = 2 })
                local lp = Players.LocalPlayer
                if lp then
                    lp:SetAttribute("ActiveSlot", 2)
                end
                Store.SetView({ activeHotbarSlot = 2 })
                task.delay(0.08, function()
                    ScreenRouter.CloseAllToHUD()
                    fireAbilityRemote({ action = "SlotMove", key = mv.Key })
                end)
            end,
        })
    end
end

-- Zioles 3D Gacha Spin Presentation Overlay (3.2s easeOutQuart carousel + rarity aura shifts + burst)
local function launchZiolesGachaCarousel(root)
    cleanupGachaOverlay()
    local colors = Theme.Colors

    local beforeSnap = Store.GetSnapshot()
    local curGold = (beforeSnap and beforeSnap.currency and tonumber(beforeSnap.currency.gold)) or 0
    local curVouchers = (beforeSnap and beforeSnap.raw and tonumber(beforeSnap.raw.FreeFruitVouchers)) or 0
    if curGold < 25000 and curVouchers <= 0 and not (beforeSnap and beforeSnap.isDemoMode) then
        fireEquipRemote({ action = "RollFruit" })
        return
    end
    local prevHeld = beforeSnap and beforeSnap.fruits and beforeSnap.fruits.heldFruit or ""

    -- Fire authoritative server gacha roll immediately so server result arrives before 3.2s reveal
    fireEquipRemote({ action = "RollFruit" })

    local weightedPool = {
        "GaleCore", "SandstoneCore", "SolarFlameCore", "GlacierIceCore",
        "CelestialLightCore", "StarforgedMagmaCore", "ThunderRumbleCore",
        "AstralGravityCore", "DimensionalPortalCore", "SolarTitanCore",
        "AetherflowCore", "AbyssalSovereignCore",
    }
    local fallbackWinId = weightedPool[math.random(1, #weightedPool)]

    local backdrop = UIFactory.Create("TextButton", root, {
        Name = "ZiolesGachaModal",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(4, 8, 16),
        BackgroundTransparency = 0.20,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 60,
    })
    Fruits.GachaOverlay = backdrop

    local stage = PremiumPanel.Create(backdrop, {
        name = "GachaStage",
        variant = "gold",
        anchorPoint = Vector2.new(0.5, 0.5),
        position = UDim2.fromScale(0.5, 0.5),
        size = UDim2.fromOffset(580, 440),
        zIndex = 62,
    })

    local bannerTitle = UIFactory.Label(stage, {
        Name = "GachaTitle",
        Text = I18n.Pick("ĐÀI GACHA ZIOLES • ĐANG TRIỆU HỒI TRÁI AETHER 3D...", "ZIOLES GACHA SHRINE • SUMMONING 3D AETHER FRUIT..."),
        Position = UDim2.fromOffset(20, 14),
        Size = UDim2.new(1, -40, 0, 26),
        TextSize = 16,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        ZIndex = 64,
    })

    local rarityPill = UIFactory.Create("Frame", stage, {
        Name = "RarityAuraPill",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 44),
        Size = UDim2.fromOffset(240, 26),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
        ZIndex = 64,
    })
    UIFactory.PillCorner(rarityPill)
    local rarityStroke = UIFactory.Stroke(rarityPill, colors.ACCENT_SAPPHIRE, 1.5, 0.1)
    local rarityLabel = UIFactory.Label(rarityPill, {
        Name = "RarityText",
        Text = "COMMON -> MYTHIC",
        Size = UDim2.fromScale(1, 1),
        TextSize = 12,
        TextColor = colors.ACCENT_SAPPHIRE,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        ZIndex = 65,
    })

    local rayContainer = UIFactory.Create("Frame", stage, {
        Name = "BurstRays",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0, 206),
        Size = UDim2.fromOffset(310, 310),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 63,
    })
    local rays = {}
    for rIdx = 1, 8 do
        local ray = UIFactory.Create("Frame", rayContainer, {
            Name = "Ray_" .. rIdx,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(14, 290),
            Rotation = (rIdx - 1) * 22.5,
            BackgroundColor3 = colors.ACCENT_GOLD,
            BackgroundTransparency = 0.62,
            BorderSizePixel = 0,
            ZIndex = 63,
        })
        UIFactory.PillCorner(ray)
        table.insert(rays, ray)
    end

    local gachaViewport = UIFactory.Create("ViewportFrame", stage, {
        Name = "GachaViewport3D",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 82),
        Size = UDim2.fromOffset(320, 236),
        BackgroundColor3 = colors.BG_900,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Ambient = Color3.fromRGB(228, 232, 245),
        LightColor = Color3.fromRGB(255, 248, 224),
        LightDirection = Vector3.new(-0.5, -0.8, -1),
        ZIndex = 65,
    })
    UIFactory.Corner(gachaViewport, Theme.Radius.Large)
    local vpStroke = UIFactory.Stroke(gachaViewport, colors.ACCENT_GOLD, 2.2, 0.1)

    local gachaOrbit = ViewportOrbit.Attach(gachaViewport, {
        AutoSpinSpeed = 2.8,
        InitialYaw = math.rad(20),
        InitialPitch = math.rad(12),
        ShowHint = false,
        FieldOfView = 35,
    })
    Fruits.GachaOrbit = gachaOrbit

    local fruitNameLbl = UIFactory.Label(stage, {
        Name = "RolledFruitName",
        Text = "...",
        Position = UDim2.fromOffset(24, 326),
        Size = UDim2.new(1, -48, 0, 28),
        TextSize = 20,
        TextColor = colors.TEXT_PRIMARY,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        ZIndex = 65,
    })

    local subHintLbl = UIFactory.Label(stage, {
        Name = "RolledSubHint",
        Text = I18n.Pick("Đang kết tinh Linh Thạch Aether...", "Crystallizing Aether Core..."),
        Position = UDim2.fromOffset(24, 354),
        Size = UDim2.new(1, -48, 0, 20),
        TextSize = 12,
        TextColor = colors.TEXT_SECONDARY,
        XAlign = Enum.TextXAlignment.Center,
        ZIndex = 65,
    })

    local progTrack = UIFactory.Create("Frame", stage, {
        Name = "SpinProgressTrack",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 392),
        Size = UDim2.fromOffset(380, 8),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
        ZIndex = 65,
    })
    UIFactory.PillCorner(progTrack)
    local progFill = UIFactory.Create("Frame", progTrack, {
        Name = "Fill",
        Size = UDim2.fromScale(0, 1),
        BackgroundColor3 = colors.ACCENT_GOLD,
        BorderSizePixel = 0,
        ZIndex = 66,
    })
    UIFactory.PillCorner(progFill)

    local btnRow = UIFactory.Create("Frame", stage, {
        Name = "RevealActions",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -16),
        Size = UDim2.fromOffset(420, 42),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 66,
    })

    local wonFruitInfo = FRUIT_BY_ID[fallbackWinId] or FRUIT_CATALOG[1]

    PremiumButton.Create(btnRow, {
        name = "EatWonFruitBtn",
        label = I18n.Pick("ĂN / TRANG BỊ NGAY", "EAT / EQUIP NOW"),
        variant = "danger",
        position = UDim2.fromOffset(0, 0),
        size = UDim2.fromOffset(204, 40),
        textSize = 12,
        zIndex = 67,
        onActivated = function()
            Fruits.SelectedFruitId = wonFruitInfo.Id
            fireEquipRemote({ action = "EatFruit", fruitId = wonFruitInfo.Id })
            cleanupGachaOverlay()
            task.delay(0.12, function()
                Fruits.Update()
            end)
        end,
    })

    PremiumButton.Create(btnRow, {
        name = "ClaimCloseBtn",
        label = I18n.Pick("CẤT KHO & ĐÓNG", "STORE & CLOSE"),
        variant = "primary",
        position = UDim2.fromOffset(216, 0),
        size = UDim2.fromOffset(204, 40),
        textSize = 12,
        zIndex = 67,
        onActivated = function()
            Fruits.SelectedFruitId = wonFruitInfo.Id
            fireEquipRemote({ action = "StoreFruit", fruitId = wonFruitInfo.Id })
            cleanupGachaOverlay()
            Fruits.Update()
        end,
    })

    local totalSteps = 15
    local sequence = {}
    for i = 1, totalSteps - 1 do
        sequence[i] = FRUIT_CATALOG[((i * 3) % #FRUIT_CATALOG) + 1]
    end
    sequence[totalSteps] = wonFruitInfo

    local lastShownIndex = -1
    local landed = false
    local duration = 3.2
    local tStart = os.clock()

    local function showCarouselEntry(fInfo)
        local rCol = RARITY_COLORS[fInfo.Rarity] or fInfo.Color
        vpStroke.Color = rCol
        rarityStroke.Color = rCol
        rarityLabel.TextColor3 = rCol
        rarityLabel.Text = string.upper(fInfo.Rarity) .. "  •  " .. string.upper(fInfo.Element)
        fruitNameLbl.Text = getFruitName(fInfo)
        fruitNameLbl.TextColor3 = fInfo.Color
        progFill.BackgroundColor3 = rCol
        ViewportOrbit.MountAssetAsync(gachaOrbit, fInfo.Asset, fInfo.Color, {
            FitMultiplier = 1.06,
            ResetAngles = false,
        })
    end

    Fruits.GachaConnection = RunService.RenderStepped:Connect(function(dt)
        if not backdrop.Parent then
            cleanupGachaOverlay()
            return
        end
        local elapsed = os.clock() - tStart
        local t = math.clamp(elapsed / duration, 0, 1)
        local eased = 1 - ((1 - t) ^ 4)
        progFill.Size = UDim2.fromScale(t, 1)

        local liveSnap = Store.GetSnapshot()
        local liveHeld = liveSnap and liveSnap.fruits and liveSnap.fruits.heldFruit
        if type(liveHeld) == "string" and FRUIT_BY_ID[liveHeld] and (liveHeld ~= prevHeld or t > 0.55) then
            wonFruitInfo = FRUIT_BY_ID[liveHeld]
            sequence[totalSteps] = wonFruitInfo
        end

        local stepIdx = math.clamp(math.floor(eased * (totalSteps - 1)) + 1, 1, totalSteps)
        if stepIdx ~= lastShownIndex then
            lastShownIndex = stepIdx
            showCarouselEntry(sequence[stepIdx])
        end

        if t >= 1 and not landed then
            landed = true
            showCarouselEntry(wonFruitInfo)
            progTrack.Visible = false
            btnRow.Visible = true
            rayContainer.Visible = true

            local isMythicOrLeg = (wonFruitInfo.Rarity == "Mythical" or wonFruitInfo.Rarity == "Legendary")
            local burstColor = (wonFruitInfo.Rarity == "Mythical") and Color3.fromRGB(255, 84, 108) or colors.ACCENT_GOLD
            for i, ray in ipairs(rays) do
                ray.BackgroundColor3 = (i % 2 == 0) and colors.ACCENT_GOLD or burstColor
                ray.BackgroundTransparency = isMythicOrLeg and 0.48 or 0.68
            end

            bannerTitle.Text = I18n.Pick("* CHÚC MỪNG TRIỆU HỒI THÀNH CÔNG! *", "* CONGRATULATIONS! *")
            bannerTitle.TextColor3 = colors.ACCENT_GOLD_BRIGHT
            subHintLbl.Text = getFruitDesc(wonFruitInfo)
            Fruits.SelectedFruitId = wonFruitInfo.Id

            Store.PushLoot({
                Category = "Item",
                Title = getFruitName(wonFruitInfo),
                Subtitle = string.format("[%s] %s", string.upper(wonFruitInfo.Rarity), I18n.Pick("Gacha Zioles", "Zioles Gacha")),
                Color = RARITY_COLORS[wonFruitInfo.Rarity] or wonFruitInfo.Color,
            })
        elseif landed and rayContainer.Visible then
            rayContainer.Rotation = (rayContainer.Rotation + dt * 24) % 360
        end
    end)
end

function Fruits.Build(parent, _responsiveState)
    Fruits.Cleanup()

    local colors = Theme.Colors
    local snap = Store.GetSnapshot()
    local fState = snap.fruits or {}
    local equippedId = fState.equippedFruit or "GaleCore"
    if not FRUIT_BY_ID[equippedId] then
        equippedId = "SolarTitanCore"
    end
    local localPlr = Players.LocalPlayer
    local previewAttr = localPlr and localPlr:GetAttribute("SelectedPreviewFruit")
    if type(previewAttr) == "string" and FRUIT_BY_ID[previewAttr] then
        Fruits.SelectedFruitId = previewAttr
        localPlr:SetAttribute("SelectedPreviewFruit", nil)
    end
    if not Fruits.SelectedFruitId or not FRUIT_BY_ID[Fruits.SelectedFruitId] then
        Fruits.SelectedFruitId = equippedId
    end
    local selectedFruit = FRUIT_BY_ID[Fruits.SelectedFruitId] or FRUIT_CATALOG[1]

    local root = UIFactory.Create("Frame", parent, {
        Name = "FruitsScreen",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 10,
    })

    local refs = {
        Root = root,
        RenderedFruitId = selectedFruit.Id,
        HakiApis = {},
        SlotApis = {},
        FruitCards = {},
    }
    Fruits.Refs = refs

    local _, headerRefs = UIFactory.BuildScreenHeader(root, {
        ActiveScreen = UIState.Screens.Fruits,
        Title = I18n.T("fruits.title"),
        Snapshot = snap,
        OnNavigate = function(targetId)
            ScreenRouter.Navigate(targetId)
        end,
        OnClose = function()
            ScreenRouter.CloseAllToHUD()
        end,
    })
    refs.HeaderRefs = headerRefs

    -- ========================================================================
    -- LEFT PANEL (54%): ZIOLES 3D GACHA SHRINE, DROP RATES & 12-FRUIT GLOSSY VAULT
    -- Matches SKYBREAK_NPC_01 Left Panel 1:1
    -- ========================================================================
    local leftPanel = PremiumPanel.Create(root, {
        name = "ZiolesGachaShrinePanel",
        variant = "gold",
        position = UDim2.fromOffset(16, 72),
        size = UDim2.new(0.54, -18, 1, -84),
    })

    UIFactory.Label(leftPanel, {
        Name = "ShrineHeader",
        Text = I18n.Pick("ĐÀI TRIỆU HỒI TRÁI 3D ZIOLES • TỶ LỆ & PITY MINH BẠCH", "ZIOLES 3D GACHA SHRINE • TRANSPARENT ODDS & PITY"),
        Position = UDim2.fromOffset(14, 8),
        Size = UDim2.new(1, -186, 0, 22),
        TextSize = 13,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
    })

    PremiumButton.Create(leftPanel, {
        name = "OpenMirageShopBtn",
        icon = "Gold",
        label = I18n.Pick("KỆ MIRAGE 2H [N]", "MIRAGE 2H [N]"),
        variant = "secondary",
        position = UDim2.new(1, -162, 0, 6),
        size = UDim2.fromOffset(150, 26),
        textSize = 10,
        minTextSize = 8,
        onActivated = function()
            Store.SetView({ activeVendorMode = "MirageDealer" })
            ScreenRouter.Navigate(UIState.Screens.NPCShop, { forceRebuild = true })
        end,
    })

    -- Top Shrine Stage Box (3D Zioles Bust + Concentric 3D Rotating Fruit + 6-Rarity Drop Rates & Pity)
    local shrineStage = UIFactory.Create("Frame", leftPanel, {
        Name = "ShrineStageBox",
        Position = UDim2.fromOffset(12, 36),
        Size = UDim2.new(1, -24, 0, 184),
        BackgroundColor3 = Color3.fromRGB(9, 13, 25),
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
    })
    UIFactory.Corner(shrineStage, Theme.Radius.Medium)
    UIFactory.Stroke(shrineStage, Color3.fromRGB(78, 98, 152), 1.2, 0.35)

    -- 1. Left: Live 3D Zioles Bust Card
    local _, ziolesCdLbl = mountZiolesBustCard(shrineStage, UDim2.fromOffset(8, 8), UDim2.fromOffset(124, 168))
    refs.ZiolesCooldownLbl = ziolesCdLbl

    -- 2. Center: Large 3D Rotating Fruit Stage with Concentric Glowing Aura Rings
    local centerStage = UIFactory.Create("Frame", shrineStage, {
        Name = "FruitOrbitStage",
        Position = UDim2.fromOffset(140, 8),
        Size = UDim2.fromOffset(186, 168),
        BackgroundColor3 = Color3.fromRGB(12, 18, 34),
        BorderSizePixel = 0,
        ClipsDescendants = true,
    })
    UIFactory.Corner(centerStage, Theme.Radius.Medium)
    refs.ViewportStroke = UIFactory.Stroke(centerStage, selectedFruit.Color, 1.6, 0.16)

    -- Concentric glowing aura rings behind the 3D Fruit ViewportFrame
    local outerRing = UIFactory.Create("Frame", centerStage, {
        Name = "OuterAuraRing",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.45, 0),
        Size = UDim2.fromOffset(126, 126),
        BackgroundColor3 = selectedFruit.Color,
        BackgroundTransparency = 0.88,
        BorderSizePixel = 0,
    })
    UIFactory.PillCorner(outerRing)
    local outerRingStroke = UIFactory.Stroke(outerRing, selectedFruit.Color, 1.3, 0.35)
    refs.OuterRing = outerRing
    refs.OuterRingStroke = outerRingStroke

    local innerRing = UIFactory.Create("Frame", centerStage, {
        Name = "InnerAuraRing",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.45, 0),
        Size = UDim2.fromOffset(84, 84),
        BackgroundColor3 = selectedFruit.Color,
        BackgroundTransparency = 0.80,
        BorderSizePixel = 0,
    })
    UIFactory.PillCorner(innerRing)
    local innerRingStroke = UIFactory.Stroke(innerRing, selectedFruit.Color, 1.5, 0.18)
    refs.InnerRing = innerRing
    refs.InnerRingStroke = innerRingStroke

    local viewportBox = UIFactory.Create("ViewportFrame", centerStage, {
        Name = "FruitViewport3D",
        Position = UDim2.fromOffset(4, 2),
        Size = UDim2.new(1, -8, 1, -28),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Ambient = Color3.fromRGB(228, 232, 245),
        LightColor = Color3.fromRGB(255, 250, 238),
        LightDirection = Vector3.new(-0.5, -0.7, -1),
        ZIndex = 3,
    })
    refs.ViewportBox = viewportBox
    mount3DFruitPreview(viewportBox, selectedFruit)

    local orbitPill = UIFactory.Create("Frame", centerStage, {
        Name = "OrbitCaptionPill",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -5),
        Size = UDim2.new(1, -12, 0, 20),
        BackgroundColor3 = Color3.fromRGB(8, 12, 22),
        BorderSizePixel = 0,
        ZIndex = 4,
    })
    UIFactory.PillCorner(orbitPill)
    UIFactory.Stroke(orbitPill, colors.ACCENT_GOLD, 1.0, 0.32)
    refs.OrbitFruitCaption = UIFactory.Label(orbitPill, {
        Name = "OrbitCaptionText",
        Text = "* 3D: " .. string.upper(getFruitShortName(selectedFruit)),
        Position = UDim2.fromOffset(6, 0),
        Size = UDim2.new(1, -12, 1, 0),
        TextSize = 9,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Truncate = Enum.TextTruncate.AtEnd,
        ZIndex = 5,
    })

    -- 3. Right: Transparent 6-Rarity Drop-Rate Card + Mythic Pity Pill
    local rateCard = UIFactory.Create("Frame", shrineStage, {
        Name = "DropRateCard",
        Position = UDim2.fromOffset(334, 8),
        Size = UDim2.new(1, -342, 0, 168),
        BackgroundColor3 = Color3.fromRGB(13, 19, 36),
        BorderSizePixel = 0,
    })
    UIFactory.Corner(rateCard, Theme.Radius.Medium)
    UIFactory.Stroke(rateCard, Color3.fromRGB(88, 112, 168), 1.1, 0.35)

    UIFactory.Label(rateCard, {
        Name = "RateHeader",
        Text = I18n.Pick("TỶ LỆ TRIỆU HỒI MINH BẠCH (6 PHẨM)", "TRANSPARENT 6-TIER DROP RATES"),
        Position = UDim2.fromOffset(10, 5),
        Size = UDim2.new(1, -20, 0, 16),
        TextSize = 10,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
    })

    for rIdx, rKey in ipairs(RARITY_ORDER) do
        local pal = RARITY_PALETTE[rKey]
        local yPos = 22 + (rIdx - 1) * 19
        local dot = UIFactory.Create("Frame", rateCard, {
            Name = "Dot_" .. rKey,
            Position = UDim2.fromOffset(10, yPos + 5),
            Size = UDim2.fromOffset(7, 7),
            BackgroundColor3 = pal.Text,
            BorderSizePixel = 0,
        })
        UIFactory.PillCorner(dot)

        UIFactory.Label(rateCard, {
            Name = "Tier_" .. rKey,
            Text = I18n.GetLanguage() == "en" and pal.LabelEn or pal.LabelVi,
            Position = UDim2.fromOffset(22, yPos),
            Size = UDim2.new(1, -74, 0, 17),
            TextSize = 10,
            TextColor = pal.Text,
            Bold = (rIdx >= 4),
            Truncate = Enum.TextTruncate.AtEnd,
        })

        UIFactory.Label(rateCard, {
            Name = "Pct_" .. rKey,
            Text = pal.Rate,
            Position = UDim2.new(1, -54, 0, yPos),
            Size = UDim2.fromOffset(44, 17),
            TextSize = 10,
            TextColor = pal.Text,
            Bold = true,
            XAlign = Enum.TextXAlignment.Right,
        })
    end

    local pityCount = tonumber(fState.pityCount)
        or (snap.raw and tonumber(snap.raw.FruitPity))
        or (localPlr and tonumber(localPlr:GetAttribute("FruitPity")))
        or 18
    local pityPill = UIFactory.Create("Frame", rateCard, {
        Name = "MythicPityPill",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -6),
        Size = UDim2.new(1, -16, 0, 22),
        BackgroundColor3 = Color3.fromRGB(28, 22, 12),
        BorderSizePixel = 0,
    })
    UIFactory.PillCorner(pityPill)
    UIFactory.Stroke(pityPill, colors.ACCENT_GOLD_BRIGHT, 1.3, 0.15)
    refs.PityLabel = UIFactory.Label(pityPill, {
        Name = "PityText",
        Text = I18n.Pick(
            string.format("BẢO HIỂM PITY MYTHIC: %d / 50 LƯỢT", pityCount),
            string.format("MYTHIC PITY GUARANTEE: %d / 50 ROLLS", pityCount)
        ),
        Position = UDim2.fromOffset(8, 0),
        Size = UDim2.new(1, -16, 1, 0),
        TextSize = 9,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Truncate = Enum.TextTruncate.AtEnd,
    })

    -- Middle Section: 12 Vivid Glossy 6-Rarity Permanent Vault Fruit Tiles
    UIFactory.Label(leftPanel, {
        Name = "VaultHeader",
        Text = I18n.Pick("KHO VĨNH VIỄN 12 TRÁI AETHER 3D (CHỌN ĐỂ XEM 3D • ĂN • CẤT KHO):", "12 SEPARATED 3D FRUITS PERMANENT VAULT (SELECT FOR 3D • EAT • STORE):"),
        Position = UDim2.fromOffset(14, 225),
        Size = UDim2.new(1, -28, 0, 17),
        TextSize = 10,
        TextColor = colors.ACCENT_SAPPHIRE,
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
    })

    local vaultScroll = UIFactory.Create("ScrollingFrame", leftPanel, {
        Name = "GlossyFruitVaultScroll",
        Position = UDim2.fromOffset(12, 245),
        Size = UDim2.new(1, -24, 1, -396),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = colors.ACCENT_GOLD,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.fromOffset(0, 0),
    })
    UIFactory.GridLayout(vaultScroll, UDim2.new(0.25, -6, 0, 82), UDim2.fromOffset(7, 7))

    local stored = fState.storedFruits or {}
    for idx, item in ipairs(FRUIT_CATALOG) do
        local isSelected = (item.Id == selectedFruit.Id)
        local isEq = (item.Id == equippedId)
        local ownedCount = tonumber(stored[item.Id]) or 0
        local pal = RARITY_PALETTE[item.Rarity] or RARITY_PALETTE.Common

        local topBadge = isEq and I18n.Pick("ĐANG DÙNG", "EQUIPPED")
            or (ownedCount > 0 and ("KHO x" .. tostring(ownedCount)) or pal.Tag)
        local topBadgeCol = isEq and colors.ACCENT_GOLD_BRIGHT or Color3.fromRGB(246, 250, 255)

        local tile, stroke, tagLbl, bottomLbl = makeGlossyRarityTile(vaultScroll, {
            name = "FruitTile_" .. item.Id,
            rarity = item.Rarity,
            icon = item.Icon or "Fruit",
            topTag = topBadge,
            topTagColor = topBadgeCol,
            bottomCaption = getFruitShortName(item),
            bottomColor = isEq and colors.ACCENT_GOLD_BRIGHT or pal.Text,
            strokeColor = isEq and colors.ACCENT_GOLD_BRIGHT or (isSelected and Color3.fromRGB(255, 255, 255) or pal.Stroke),
            strokeThickness = (isEq or isSelected) and 2.2 or 1.3,
            layoutOrder = idx,
        })

        tile.Activated:Connect(function()
            if Fruits.SelectedFruitId ~= item.Id then
                Fruits.SelectedFruitId = item.Id
                Fruits.Update()
            end
        end)

        refs.FruitCards[item.Id] = {
            Tile = tile,
            Stroke = stroke,
            TagLbl = tagLbl,
            BottomLbl = bottomLbl,
            Info = item,
            Palette = pal,
        }
    end

    -- Selected Fruit Action Box (matching SKYBREAK_NPC_01 "THAO TÁC VỚI TRÁI ĐANG CHỌN")
    local actionBox = UIFactory.Create("Frame", leftPanel, {
        Name = "SelectedFruitActionBox",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 12, 1, -62),
        Size = UDim2.new(1, -24, 0, 82),
        BackgroundColor3 = Color3.fromRGB(10, 15, 28),
        BorderSizePixel = 0,
    })
    UIFactory.Corner(actionBox, Theme.Radius.Medium)
    UIFactory.Stroke(actionBox, Color3.fromRGB(78, 102, 156), 1.1, 0.35)

    local isAwakened = fState.awakenedFruits and fState.awakenedFruits[selectedFruit.Id] == true
    local masteryLv = (fState.mastery and fState.mastery[selectedFruit.Id]) or 1

    refs.SelectedFruitTitle = UIFactory.Label(actionBox, {
        Name = "SelectedFruitTitle",
        Text = string.format("%s  •  %s  •  Mastery Lv.%d%s", getFruitName(selectedFruit), selectedFruit.Rarity, masteryLv, isAwakened and " [V2]" or ""),
        Position = UDim2.fromOffset(10, 6),
        Size = UDim2.new(1, -184, 0, 22),
        TextSize = 12,
        TextColor = selectedFruit.Color,
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
    })

    local _, awakenApi = PremiumButton.Create(actionBox, {
        name = "AwakenFruitBtn",
        icon = "Bolt",
        label = isAwakened and I18n.Pick("ĐÃ THỨC TỈNH V2", "AWAKENED V2") or I18n.Pick("THỨC TỈNH V2 (500)", "AWAKEN V2 (500)"),
        variant = isAwakened and "gold" or "secondary",
        position = UDim2.new(1, -168, 0, 5),
        size = UDim2.fromOffset(160, 25),
        textSize = 9,
        minTextSize = 8,
        onActivated = function()
            local sel = FRUIT_BY_ID[Fruits.SelectedFruitId] or selectedFruit
            fireEquipRemote({ action = "AwakenFruit", fruitId = sel.Id })
            task.delay(0.15, function()
                Fruits.Update()
            end)
        end,
    })
    refs.AwakenFruitApi = awakenApi

    local actRow = UIFactory.Create("Frame", actionBox, {
        Name = "ActionButtonsRow",
        Position = UDim2.fromOffset(8, 35),
        Size = UDim2.new(1, -16, 0, 39),
        BackgroundTransparency = 1,
    })

    local _, eatApi = PremiumButton.Create(actRow, {
        name = "EatFruitBtn",
        icon = "Fruit",
        label = (equippedId == selectedFruit.Id)
            and I18n.Pick("ĐANG TRANG BỊ [SLOT 2]", "EQUIPPED [SLOT 2]")
            or I18n.Pick("ĂN NGAY (THAY TRÁI)", "EAT NOW (EQUIP)"),
        variant = (equippedId == selectedFruit.Id) and "gold" or "danger",
        position = UDim2.fromOffset(0, 0),
        size = UDim2.new(0.36, -4, 1, 0),
        textSize = 11,
        minTextSize = 9,
        onActivated = function()
            local sel = FRUIT_BY_ID[Fruits.SelectedFruitId] or selectedFruit
            fireEquipRemote({ action = "EatFruit", fruitId = sel.Id })
            task.delay(0.15, function()
                Fruits.Update()
            end)
        end,
    })
    refs.EatFruitApi = eatApi

    local _, storeApi = PremiumButton.Create(actRow, {
        name = "StorePermanentBtn",
        icon = "Bag",
        label = I18n.Pick("CẤT VÀO KHO VĨNH VIỄN", "STORE IN VAULT"),
        variant = "primary",
        position = UDim2.new(0.36, 2, 0, 0),
        size = UDim2.new(0.34, -4, 1, 0),
        textSize = 11,
        minTextSize = 9,
        onActivated = function()
            local sel = FRUIT_BY_ID[Fruits.SelectedFruitId] or selectedFruit
            fireEquipRemote({ action = "StoreFruit", fruitId = sel.Id })
            local curSnap = Store.GetSnapshot()
            if curSnap and curSnap.fruits and curSnap.fruits.heldFruit == sel.Id then
                fireEquipRemote({ action = "HoldFruit", fruitId = sel.Id })
            end
            Store.ShowToast(
                I18n.Pick("Đã cất " .. getFruitShortName(sel) .. " vào Kho Vĩnh Viễn!", "Stored " .. getFruitShortName(sel) .. " in Permanent Vault!"),
                "success",
                2.2
            )
            task.delay(0.15, function()
                Fruits.Update()
            end)
        end,
    })
    refs.StoreFruitApi = storeApi

    local _, holdApi = PremiumButton.Create(actRow, {
        name = "HoldFruitBtn",
        label = (fState.heldFruit == selectedFruit.Id)
            and I18n.Pick("ĐANG CẦM 3D TRÊN TAY", "HOLDING 3D MODEL")
            or I18n.Pick("CẦM TRÁI 3D TRÊN TAY", "HOLD 3D IN HAND"),
        variant = "secondary",
        position = UDim2.new(0.70, 2, 0, 0),
        size = UDim2.new(0.30, -2, 1, 0),
        textSize = 10,
        minTextSize = 8,
        onActivated = function()
            local sel = FRUIT_BY_ID[Fruits.SelectedFruitId] or selectedFruit
            fireEquipRemote({ action = "HoldFruit", fruitId = sel.Id, forceHold = true })
            task.delay(0.15, function()
                Fruits.Update()
            end)
        end,
    })
    refs.HoldFruitApi = holdApi

    -- Bottom Big Gacha Spin CTAs (Gold 25,000 Gold + Sapphire Free Voucher Roll)
    local gachaBar = UIFactory.Create("Frame", leftPanel, {
        Name = "BottomGachaCTABar",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 12, 1, -10),
        Size = UDim2.new(1, -24, 0, 44),
        BackgroundTransparency = 1,
    })

    PremiumButton.Create(gachaBar, {
        name = "RollGachaBtn",
        icon = "Star",
        label = I18n.Pick("TRIỆU HỒI GACHA (25,000 GOLD)", "SUMMON 3D GACHA (25,000 GOLD)"),
        variant = "gold",
        position = UDim2.fromOffset(0, 0),
        size = UDim2.new(0.56, -4, 1, 0),
        textSize = 12,
        minTextSize = 9,
        onActivated = function()
            launchZiolesGachaCarousel(root)
        end,
    })

    local freeVouchers = (snap.raw and tonumber(snap.raw.FreeFruitVouchers)) or 0
    local _, voucherBtnApi = PremiumButton.Create(gachaBar, {
        name = "FreeVoucherGachaBtn",
        icon = "Gift",
        label = I18n.Pick(
            string.format("DÙNG VÉ GACHA MIỄN PHÍ (%d VÉ)", freeVouchers),
            string.format("USE FREE GACHA VOUCHER (%d)", freeVouchers)
        ),
        variant = "primary",
        position = UDim2.new(0.56, 4, 0, 0),
        size = UDim2.new(0.44, -4, 1, 0),
        textSize = 11,
        minTextSize = 9,
        onActivated = function()
            launchZiolesGachaCarousel(root)
        end,
    })
    refs.VoucherBtnApi = voucherBtnApi

    -- ========================================================================
    -- RIGHT PANEL (46%): 5 FRUIT ABILITIES ([Z][X][C][V][F]), HAKI & HOTBAR SLOTS
    -- ========================================================================
    local rightPanel = PremiumPanel.Create(root, {
        name = "FruitCombatMasteryPanel",
        variant = "gold",
        position = UDim2.new(0.54, 6, 0, 72),
        size = UDim2.new(0.46, -22, 1, -84),
    })

    UIFactory.Label(rightPanel, {
        Name = "MovesHeader",
        Text = I18n.Pick("BỘ 5 KỸ NĂNG TRÁI AETHER ([Z] [X] [C] [V] [F])", "5 AETHER FRUIT ABILITIES ([Z] [X] [C] [V] [F])"),
        Position = UDim2.fromOffset(14, 10),
        Size = UDim2.new(1, -28, 0, 20),
        TextSize = 13,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
    })

    refs.FruitDesc = UIFactory.Label(rightPanel, {
        Name = "FruitDesc",
        Text = getFruitDesc(selectedFruit),
        Position = UDim2.fromOffset(14, 31),
        Size = UDim2.new(1, -28, 0, 28),
        TextSize = 11,
        TextColor = colors.TEXT_SECONDARY,
        Wrapped = true,
    })

    local movesList = UIFactory.Create("Frame", rightPanel, {
        Name = "MovesList",
        Position = UDim2.fromOffset(14, 63),
        Size = UDim2.new(1, -28, 1, -224),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(movesList, Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top)
    refs.MovesList = movesList
    populateMovesList(movesList, selectedFruit, equippedId, colors)

    -- Haki Ba Loai & Race V4 Toggle Box
    local hakiBox = UIFactory.Create("Frame", rightPanel, {
        Name = "HakiAndRaceV4Box",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 14, 1, -66),
        Size = UDim2.new(1, -28, 0, 88),
        BackgroundColor3 = Color3.fromRGB(10, 15, 28),
        BorderSizePixel = 0,
    })
    UIFactory.Corner(hakiBox, Theme.Radius.Medium)
    UIFactory.Stroke(hakiBox, Color3.fromRGB(76, 98, 148), 1.1, 0.35)

    UIFactory.Label(hakiBox, {
        Name = "HakiHeader",
        Text = I18n.Pick("HAKI BA LOẠI ([J] [U] [H]) & THỨC TỈNH TỘC V4 [Y]", "THREE HAKI ARTS ([J] [U] [H]) & RACE V4 [Y]"),
        Position = UDim2.fromOffset(10, 4),
        Size = UDim2.new(1, -20, 0, 16),
        TextSize = 10,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
    })

    local hakiRow = UIFactory.Create("Frame", hakiBox, {
        Name = "HakiButtons",
        Position = UDim2.fromOffset(8, 22),
        Size = UDim2.new(1, -16, 0, 60),
        BackgroundTransparency = 1,
    })
    UIFactory.GridLayout(hakiRow, UDim2.new(0.5, -4, 0, 27), UDim2.fromOffset(8, 5))

    local hakiActions = {
        {
            id = "Aura",
            active = fState.haki and fState.haki.Aura == true,
            label = (fState.haki and fState.haki.Aura)
                and I18n.Pick("HAKI VŨ TRANG: BẬT", "ARMAMENT HAKI: ON")
                or I18n.Pick("HAKI VŨ TRANG [J]", "ARMAMENT HAKI [J]"),
            act = "ToggleAura",
        },
        {
            id = "Instinct",
            active = fState.haki and fState.haki.Instinct == true,
            label = (fState.haki and fState.haki.Instinct)
                and I18n.Pick("HAKI QUAN SÁT: BẬT", "INSTINCT HAKI: ON")
                or I18n.Pick("HAKI QUAN SÁT [U]", "INSTINCT HAKI [U]"),
            act = "ToggleInstinct",
        },
        {
            id = "Conqueror",
            active = false,
            label = I18n.Pick("HAKI BÁ VƯƠNG [H]", "CONQUEROR HAKI [H]"),
            act = "ConquerorBurst",
        },
        {
            id = "RaceV4",
            active = fState.raceV4Active == true,
            label = fState.raceV4Active
                and I18n.Pick("TỘC V4 [" .. tostring(fState.race or "Skyborn") .. "]: BẬT", "RACE V4 [" .. tostring(fState.race or "Skyborn") .. "]: ON")
                or I18n.Pick("THỨC TỈNH TỘC V4 [Y]", "AWAKEN RACE V4 [Y]"),
            act = "ActivateRaceV4",
        },
    }
    for idx, hk in ipairs(hakiActions) do
        local _, hkApi = PremiumButton.Create(hakiRow, {
            name = hk.id,
            label = hk.label,
            variant = hk.active and "gold" or "secondary",
            selected = hk.active,
            layoutOrder = idx,
            textSize = 10,
            minTextSize = 8,
            onActivated = function()
                fireEquipRemote({ action = hk.act })
                task.delay(0.15, function()
                    Fruits.Update()
                end)
            end,
        })
        refs.HakiApis[hk.id] = hkApi
    end

    -- 4 Localized Hotbar Loadout Slots Strip ([1]-[4])
    local slotStrip = UIFactory.Create("Frame", rightPanel, {
        Name = "LoadoutSlotStrip",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 14, 1, -10),
        Size = UDim2.new(1, -28, 0, 48),
        BackgroundTransparency = 1,
    })
    UIFactory.GridLayout(slotStrip, UDim2.new(0.25, -5, 0, 46), UDim2.fromOffset(6, 6))

    for slIdx = 1, 4 do
        local catText, itemText = I18n.GetHotbarSlotSummary(slIdx, snap)
        local isSlotActive = ((fState.activeSlot or 1) == slIdx)
        local _, slApi = PremiumButton.Create(slotStrip, {
            name = "Slot_" .. slIdx,
            label = string.format("[%d] %s", slIdx, tostring(itemText or catText or "")),
            variant = isSlotActive and "gold" or "secondary",
            selected = isSlotActive,
            layoutOrder = slIdx,
            textSize = 10,
            minTextSize = 8,
            onActivated = function()
                fireEquipRemote({ action = "SelectSlot", slot = slIdx })
                task.delay(0.12, function()
                    Fruits.Update()
                end)
            end,
        })
        refs.SlotApis[slIdx] = slApi
    end

    return root
end

function Fruits.Update(snap)
    if ScreenRouter.CurrentScreen ~= UIState.Screens.Fruits then
        return
    end
    local refs = Fruits.Refs
    if not refs or not refs.Root or not refs.Root.Parent then
        return
    end

    local colors = Theme.Colors
    snap = snap or Store.GetSnapshot()
    local fState = snap.fruits or {}
    local equippedId = fState.equippedFruit or "GaleCore"
    if not FRUIT_BY_ID[equippedId] then
        equippedId = "SolarTitanCore"
    end
    local localPlr = Players.LocalPlayer
    local previewAttr = localPlr and localPlr:GetAttribute("SelectedPreviewFruit")
    if type(previewAttr) == "string" and FRUIT_BY_ID[previewAttr] then
        Fruits.SelectedFruitId = previewAttr
        localPlr:SetAttribute("SelectedPreviewFruit", nil)
    end
    if not Fruits.SelectedFruitId or not FRUIT_BY_ID[Fruits.SelectedFruitId] then
        Fruits.SelectedFruitId = equippedId
    end
    local selectedFruit = FRUIT_BY_ID[Fruits.SelectedFruitId] or FRUIT_CATALOG[1]

    if refs.HeaderRefs and refs.HeaderRefs.UpdateCurrencies then
        refs.HeaderRefs.UpdateCurrencies(snap)
    end

    if refs.RenderedFruitId ~= selectedFruit.Id then
        refs.RenderedFruitId = selectedFruit.Id
        if refs.FruitDesc then
            refs.FruitDesc.Text = getFruitDesc(selectedFruit)
        end
        if refs.ViewportStroke then
            refs.ViewportStroke.Color = selectedFruit.Color
        end
        if refs.OuterRing then
            refs.OuterRing.BackgroundColor3 = selectedFruit.Color
        end
        if refs.OuterRingStroke then
            refs.OuterRingStroke.Color = selectedFruit.Color
        end
        if refs.InnerRing then
            refs.InnerRing.BackgroundColor3 = selectedFruit.Color
        end
        if refs.InnerRingStroke then
            refs.InnerRingStroke.Color = selectedFruit.Color
        end
        if refs.OrbitFruitCaption then
            refs.OrbitFruitCaption.Text = "* 3D: " .. string.upper(getFruitShortName(selectedFruit))
        end
        if refs.ViewportBox then
            mount3DFruitPreview(refs.ViewportBox, selectedFruit)
        end
        if refs.MovesList then
            populateMovesList(refs.MovesList, selectedFruit, equippedId, colors)
        end
    end

    local isAwakened = fState.awakenedFruits and fState.awakenedFruits[selectedFruit.Id] == true
    local masteryLv = (fState.mastery and fState.mastery[selectedFruit.Id]) or 1
    if refs.SelectedFruitTitle then
        refs.SelectedFruitTitle.Text = string.format(
            "%s  •  %s  •  Mastery Lv.%d%s",
            getFruitName(selectedFruit),
            selectedFruit.Rarity,
            masteryLv,
            isAwakened and " [V2]" or ""
        )
        refs.SelectedFruitTitle.TextColor3 = selectedFruit.Color
    end
    if refs.PityLabel then
        local pityCount = tonumber(fState.pityCount)
            or (snap.raw and tonumber(snap.raw.FruitPity))
            or (localPlr and tonumber(localPlr:GetAttribute("FruitPity")))
            or 18
        refs.PityLabel.Text = I18n.Pick(
            string.format("BẢO HIỂM PITY MYTHIC: %d / 50 LƯỢT", pityCount),
            string.format("MYTHIC PITY GUARANTEE: %d / 50 ROLLS", pityCount)
        )
    end
    if refs.VoucherBtnApi then
        local freeVouchers = (snap.raw and tonumber(snap.raw.FreeFruitVouchers)) or 0
        refs.VoucherBtnApi:SetLabel(
            I18n.Pick(
                string.format("DÙNG VÉ GACHA MIỄN PHÍ (%d VÉ)", freeVouchers),
                string.format("USE FREE GACHA VOUCHER (%d)", freeVouchers)
            )
        )
    end
    if refs.EatFruitApi then
        local isEq = (equippedId == selectedFruit.Id)
        refs.EatFruitApi:Update({
            variant = isEq and "gold" or "danger",
            label = isEq
                and I18n.Pick("ĐANG TRANG BỊ [SLOT 2]", "EQUIPPED [SLOT 2]")
                or I18n.Pick("ĂN NGAY (THAY TRÁI)", "EAT NOW (EQUIP)"),
        })
    end
    if refs.HoldFruitApi then
        refs.HoldFruitApi:SetLabel(
            (fState.heldFruit == selectedFruit.Id)
                and I18n.Pick("ĐANG CẦM 3D TRÊN TAY", "HOLDING 3D MODEL")
                or I18n.Pick("CẦM TRÁI 3D TRÊN TAY", "HOLD 3D IN HAND")
        )
    end
    if refs.AwakenFruitApi then
        refs.AwakenFruitApi:Update({
            variant = isAwakened and "gold" or "secondary",
            label = isAwakened
                and I18n.Pick("ĐÃ THỨC TỈNH V2", "AWAKENED V2")
                or I18n.Pick("THỨC TỈNH V2 (500)", "AWAKEN V2 (500)"),
        })
    end

    if refs.HakiApis.Aura then
        local on = fState.haki and fState.haki.Aura == true
        refs.HakiApis.Aura:Update({
            variant = on and "gold" or "secondary",
            selected = on,
            label = on and I18n.Pick("HAKI VŨ TRANG: BẬT", "ARMAMENT HAKI: ON") or I18n.Pick("HAKI VŨ TRANG [J]", "ARMAMENT HAKI [J]"),
        })
    end
    if refs.HakiApis.Instinct then
        local on = fState.haki and fState.haki.Instinct == true
        refs.HakiApis.Instinct:Update({
            variant = on and "gold" or "secondary",
            selected = on,
            label = on and I18n.Pick("HAKI QUAN SÁT: BẬT", "INSTINCT HAKI: ON") or I18n.Pick("HAKI QUAN SÁT [U]", "INSTINCT HAKI [U]"),
        })
    end
    if refs.HakiApis.RaceV4 then
        local on = fState.raceV4Active == true
        refs.HakiApis.RaceV4:Update({
            variant = on and "gold" or "secondary",
            selected = on,
            label = on
                and I18n.Pick("TỘC V4 [" .. tostring(fState.race or "Skyborn") .. "]: BẬT", "RACE V4 [" .. tostring(fState.race or "Skyborn") .. "]: ON")
                or I18n.Pick("THỨC TỈNH TỘC V4 [Y]", "AWAKEN RACE V4 [Y]"),
        })
    end

    for sIdx = 1, 4 do
        local slApi = refs.SlotApis[sIdx]
        if slApi then
            local catText, itemText = I18n.GetHotbarSlotSummary(sIdx, snap)
            local isActive = ((fState.activeSlot or 1) == sIdx)
            slApi:Update({
                variant = isActive and "gold" or "secondary",
                selected = isActive,
                label = string.format("[%d] %s", sIdx, tostring(itemText or catText or "")),
            })
        end
    end

    local stored = fState.storedFruits or {}
    for fId, cRef in pairs(refs.FruitCards) do
        local isSelected = (fId == selectedFruit.Id)
        local isEq = (fId == equippedId)
        local ownedCount = tonumber(stored[fId]) or 0
        local pal = cRef.Palette or RARITY_PALETTE.Common
        if cRef.Stroke then
            cRef.Stroke.Color = isEq and colors.ACCENT_GOLD_BRIGHT or (isSelected and Color3.fromRGB(255, 255, 255) or pal.Stroke)
            cRef.Stroke.Thickness = (isEq or isSelected) and 2.2 or 1.3
        end
        if cRef.TagLbl then
            cRef.TagLbl.Text = isEq and I18n.Pick("ĐANG DÙNG", "EQUIPPED")
                or (ownedCount > 0 and ("KHO x" .. tostring(ownedCount)) or pal.Tag)
            cRef.TagLbl.TextColor3 = isEq and colors.ACCENT_GOLD_BRIGHT or Color3.fromRGB(246, 250, 255)
        end
        if cRef.BottomLbl then
            cRef.BottomLbl.TextColor3 = isEq and colors.ACCENT_GOLD_BRIGHT or pal.Text
        end
    end
end

return Fruits
