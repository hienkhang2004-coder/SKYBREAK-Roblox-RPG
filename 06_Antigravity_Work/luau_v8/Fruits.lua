-- SKYBREAK: Fragments of the Core — Separated 3D Devil Fruits & Awakening Screen ([G])
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/Fruits.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local UIState = require(Shared:WaitForChild("Types"):WaitForChild("UIState"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Store = require(script.Parent.Parent:WaitForChild("Store"))
local ScreenRouter = require(script.Parent.Parent:WaitForChild("ScreenRouter"))
local PremiumPanel = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumPanel"))
local PremiumButton = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumButton"))
local HUDController = require(script.Parent.Parent:WaitForChild("Controllers"):WaitForChild("HUDController"))

local Renderer = nil
pcall(function()
    Renderer = require(ReplicatedStorage:WaitForChild("DelegatedV5Renderer", 3))
end)

local Fruits = {
    SelectedFruitId = nil,
    SpinConnection = nil,
}

local FRUIT_CATALOG = {
    {
        Id = "GaleCore",
        Asset = "Fruit_GaleCore",
        Name = "Trái Cuồng Phong (Gale Core)",
        Rarity = "Common",
        Type = "Elemental (Logia)",
        Element = "Sky",
        Color = Color3.fromRGB(165, 245, 215),
        Desc = "Hóa thân thành gió lốc nguyên tố, miễn nhiễm đòn đánh thường và tạo lốc xoáy tốc độ cao.",
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
        Name = "Trái Sa Mạc Hoàng Kim (Sandstone)",
        Rarity = "Uncommon",
        Type = "Elemental (Logia)",
        Element = "Sky",
        Color = Color3.fromRGB(235, 195, 110),
        Desc = "Điều khiển bão cát hoàng kim sa mạc, trói chân mục tiêu trong lốc cát.",
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
        Name = "Trái Hỏa Dương (Solar Flame)",
        Rarity = "Rare",
        Type = "Elemental (Logia)",
        Element = "Sky",
        Color = Color3.fromRGB(255, 125, 45),
        Desc = "Ngọn lửa mặt trời rực cháy thiêu rụi mọi kẻ địch với Hỏa Quyền và Đại Viêm Đế.",
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
        Name = "Trái Băng Hà Vĩnh Cửu (Glacier Ice)",
        Rarity = "Rare",
        Type = "Elemental (Logia)",
        Element = "Frost",
        Color = Color3.fromRGB(115, 235, 255),
        Desc = "Đóng băng không gian với Kỷ Băng Hà Tuyệt Đối và lướt băng trên không trung.",
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
        Name = "Trái Ánh Sáng Thiên Giới (Light)",
        Rarity = "Epic",
        Type = "Elemental (Logia)",
        Element = "Sky",
        Color = Color3.fromRGB(255, 242, 135),
        Desc = "Di chuyển và tung mưa quang năng ở vận tốc ánh sáng.",
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
        Name = "Trái Dung Nham Tinh Cầu (Magma)",
        Rarity = "Epic",
        Type = "Elemental (Logia)",
        Element = "Sky",
        Color = Color3.fromRGB(255, 82, 48),
        Desc = "Sức sát thương nguyên tố cao nhất với mưa thiên thạch dung nham và Minh Cẩu.",
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
        Name = "Trái Lôi Thần (Thunder Rumble)",
        Rarity = "Legendary",
        Type = "Elemental (Logia)",
        Element = "Lightning",
        Color = Color3.fromRGB(88, 210, 255),
        Desc = "Triệu hồi Lôi Long và quả cầu sấm sét Raigo hủy diệt diện rộng.",
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
        Name = "Trái Trọng Lực Tinh Vân (Gravity)",
        Rarity = "Legendary",
        Type = "Natural (Paramecia)",
        Element = "Void",
        Color = Color3.fromRGB(185, 110, 255),
        Desc = "Bẻ cong trường trọng lực không gian và kéo thiên thạch từ tầng sao.",
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
        Name = "Trái Không Gian (Dimensional Portal)",
        Rarity = "Legendary",
        Type = "Natural (Paramecia)",
        Element = "Void",
        Color = Color3.fromRGB(120, 165, 255),
        Desc = "Mở cổng dịch chuyển tức thời xuyên chiều không gian ([C] dịch chuyển 40m).",
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
        Name = "Trái Kim Thân Phật Tổ (Solar Buddha)",
        Rarity = "Mythical",
        Type = "Beast (Mythical Zoan)",
        Element = "Sky",
        Color = Color3.fromRGB(255, 208, 68),
        Desc = "Chiêu [Z] hóa Kim Thân Khổng Lồ 3D (+58% Giáp, x2.2 tầm đánh mọi vũ khí & võ thuật)!",
        Moves = {
            { Key = "Z", Name = "Solar Titan Shift (Hóa Khổng Lồ 3D)", Mult = "2.4x ATK", Range = "28m", Cd = "3.5s" },
            { Key = "X", Name = "Heavenly Palm Impact", Mult = "3.1x ATK", Range = "30m", Cd = "5.0s" },
            { Key = "C", Name = "Dawn Pillar Nova", Mult = "3.8x ATK", Range = "34m", Cd = "7.0s" },
            { Key = "V", Name = "Twilight Retribution", Mult = "5.0x ATK", Range = "40m", Cd = "10.0s" },
            { Key = "F", Name = "Radiant Sky Leap", Mult = "1.8x ATK", Range = "28m", Cd = "4.0s" },
        },
    },
    {
        Id = "AetherflowCore",
        Asset = "Fruit_AetherflowCore",
        Name = "Trái Linh Mạch Aether (Aetherflow)",
        Rarity = "Mythical",
        Type = "Natural (Paramecia)",
        Element = "Sky",
        Color = Color3.fromRGB(95, 245, 235),
        Desc = "Điều khiển tơ linh mạch Aether sắc bén cắt đôi bầu trời.",
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
        Name = "Trái Long Vương Hư Không (Void Dragon)",
        Rarity = "Mythical",
        Type = "Beast (Mythical Zoan)",
        Element = "Void",
        Color = Color3.fromRGB(178, 88, 255),
        Desc = "Chiêu [V] hóa Thái Cổ Long Hoàng 3D bay lượn và phun Hơi Thở Hư Không hủy diệt!",
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

local function fireEquipRemote(payload)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes and remotes:FindFirstChild("EquipmentRequest") then
        remotes.EquipmentRequest:FireServer(payload)
    end
end

local function fireAbilityRemote(payload)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes and remotes:FindFirstChild("AbilityRequest") then
        remotes.AbilityRequest:FireServer(payload)
    end
end

local function mount3DFruitPreview(viewport, fruitInfo)
    if Fruits.SpinConnection then
        Fruits.SpinConnection:Disconnect()
        Fruits.SpinConnection = nil
    end
    for _, ch in ipairs(viewport:GetChildren()) do
        ch:Destroy()
    end

    local worldModel = Instance.new("WorldModel")
    worldModel.Parent = viewport

    local cam = Instance.new("Camera")
    cam.FieldOfView = 38
    cam.Parent = viewport
    viewport.CurrentCamera = cam

    task.spawn(function()
        local built, clips = nil, nil
        if Renderer then
            local ok, res = pcall(Renderer.Build, fruitInfo.Asset)
            if ok and res then
                built = res
            end
            local okC, resC = pcall(Renderer.Clips, fruitInfo.Asset)
            if okC and type(resC) == "table" then
                clips = resC
            end
        end
        if not viewport or not viewport.Parent then
            if built then built:Destroy() end
            return
        end
        if built then
            built.Parent = worldModel
            local cf, size = built:GetBoundingBox()
            local maxDim = math.max(size.X, size.Y, size.Z, 1.5)
            local dist = maxDim * 1.65
            local t0 = os.clock()
            local activeClip = clips and (clips.ElementalSurge or clips.UltimateAwakening or clips.Idle) or nil
            Fruits.SpinConnection = RunService.RenderStepped:Connect(function()
                if not viewport.Parent or not built.Parent then
                    if Fruits.SpinConnection then
                        Fruits.SpinConnection:Disconnect()
                        Fruits.SpinConnection = nil
                    end
                    return
                end
                local t = os.clock() - t0
                local bob = math.sin(t * 2.4) * 0.12
                built:PivotTo(CFrame.new(0, -size.Y * 0.42 + bob, 0) * CFrame.Angles(0, t * 1.15, 0))
                if activeClip and Renderer and Renderer.Pose then
                    pcall(Renderer.Pose, built, activeClip, t)
                end
                cam.CFrame = CFrame.lookAt(Vector3.new(0, 0.35, dist), Vector3.new(0, 0, 0))
            end)
        end
    end)
end

function Fruits.Build(parent, _responsiveState)
    if Fruits.SpinConnection then
        Fruits.SpinConnection:Disconnect()
        Fruits.SpinConnection = nil
    end

    local colors = Theme.Colors
    local snap = Store.GetSnapshot()
    local fState = snap.fruits or {}
    local equippedId = fState.equippedFruit or "GaleCore"
    if not FRUIT_BY_ID[equippedId] then
        equippedId = "SolarTitanCore"
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

    -- Top Bar
    local topBar = PremiumPanel.Create(root, {
        name = "TopHeader",
        position = UDim2.fromOffset(18, 12),
        size = UDim2.new(1, -36, 0, 52),
    })

    UIFactory.Label(topBar, {
        Name = "ScreenTitle",
        Text = "🍎 HỆ THỐNG TRÁI ÁC QUỶ 3D • 12 TRÁI ĐÃ TÁCH RIÊNG [G]",
        Position = UDim2.fromOffset(16, 0),
        Size = UDim2.fromOffset(460, 52),
        TextSize = 16,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
    })

    UIFactory.Label(topBar, {
        Name = "CurrencySummary",
        Text = string.format(
            "🪙 %s Gold   •   💎 %s Core Shards   •   Đang dùng: %s",
            UIFactory.FormatNumber(snap.currency.gold),
            UIFactory.FormatNumber(snap.currency.coreShards),
            (FRUIT_BY_ID[equippedId] and FRUIT_BY_ID[equippedId].Name or equippedId)
        ),
        Position = UDim2.new(1, -620, 0, 0),
        Size = UDim2.fromOffset(470, 52),
        TextSize = 13,
        TextColor = colors.TEXT_PRIMARY,
        Bold = true,
        XAlign = Enum.TextXAlignment.Right,
    })

    PremiumButton.Create(topBar, {
        name = "CloseBtn",
        label = "✕ ĐÓNG [ESC]",
        variant = "secondary",
        position = UDim2.new(1, -138, 0.5, -18),
        size = UDim2.fromOffset(124, 36),
        textSize = 12,
        onActivated = function()
            ScreenRouter.CloseAllToHUD()
        end,
    })

    -- Left Column: 3D Separated Devil Fruit Viewport & Actions
    local leftCol = PremiumPanel.Create(root, {
        name = "FruitPreviewPanel",
        variant = "gold",
        position = UDim2.fromOffset(18, 74),
        size = UDim2.new(0.31, -18, 1, -90),
    })

    UIFactory.Label(leftCol, {
        Name = "SelectedFruitTitle",
        Text = selectedFruit.Name,
        Position = UDim2.fromOffset(14, 10),
        Size = UDim2.new(1, -28, 0, 24),
        TextSize = 15,
        TextColor = selectedFruit.Color,
        Bold = true,
    })

    local isAwakened = fState.awakenedFruits and fState.awakenedFruits[selectedFruit.Id] == true
    local masteryLv = (fState.mastery and fState.mastery[selectedFruit.Id]) or 1
    UIFactory.Label(leftCol, {
        Name = "SelectedFruitMeta",
        Text = string.format("%s  •  %s  •  Mastery Lv.%d  %s", selectedFruit.Rarity, selectedFruit.Type, masteryLv, isAwakened and "⚡ [AWAKENED V2]" or ""),
        Position = UDim2.fromOffset(14, 34),
        Size = UDim2.new(1, -28, 0, 18),
        TextSize = 12,
        TextColor = colors.ACCENT_SAPPHIRE,
        Bold = true,
    })

    local viewportBox = UIFactory.Create("ViewportFrame", leftCol, {
        Name = "FruitViewport3D",
        Position = UDim2.fromOffset(14, 56),
        Size = UDim2.new(1, -28, 0, 196),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
        Ambient = Color3.fromRGB(190, 205, 235),
        LightColor = Color3.fromRGB(255, 245, 220),
        LightDirection = Vector3.new(-1, -1, -1),
    })
    UIFactory.Corner(viewportBox, Theme.Radius.Medium)
    UIFactory.Stroke(viewportBox, selectedFruit.Color, 1.8, 0.15)
    mount3DFruitPreview(viewportBox, selectedFruit)

    UIFactory.Label(leftCol, {
        Name = "FruitDesc",
        Text = selectedFruit.Desc,
        Position = UDim2.fromOffset(14, 258),
        Size = UDim2.new(1, -28, 0, 42),
        TextSize = 12,
        TextColor = colors.TEXT_SECONDARY,
        Wrapped = true,
    })

    -- Action Buttons for Selected Fruit
    PremiumButton.Create(leftCol, {
        name = "EatFruitBtn",
        label = (equippedId == selectedFruit.Id) and "✓ ĐANG TRANG BỊ (BẤM ĐỂ KÍCH HOẠT SLOT [2])" or "🍎 ĂN / TRANG BỊ TRÁI NÀY NGAY",
        variant = "gold",
        position = UDim2.fromOffset(14, 306),
        size = UDim2.new(1, -28, 0, 40),
        textSize = 13,
        onActivated = function()
            fireEquipRemote({ action = "EatFruit", fruitId = selectedFruit.Id })
            task.delay(0.15, function()
                Fruits.Update()
            end)
        end,
    })

    PremiumButton.Create(leftCol, {
        name = "HoldFruitBtn",
        label = (fState.heldFruit == selectedFruit.Id) and "✋ ĐANG CẦM 3D TRÊN TAY (BẤM ĐỂ CẤT)" or "✋ CẦM MÔ HÌNH TRÁI 3D TRÊN TAY",
        variant = "primary",
        position = UDim2.fromOffset(14, 352),
        size = UDim2.new(0.5, -18, 0, 38),
        textSize = 11,
        onActivated = function()
            fireEquipRemote({ action = "HoldFruit", fruitId = selectedFruit.Id })
            task.delay(0.15, function()
                Fruits.Update()
            end)
        end,
    })

    PremiumButton.Create(leftCol, {
        name = "AwakenFruitBtn",
        label = isAwakened and "⚡ ĐÃ THỨC TỈNH V2" or "⚡ THỨC TỈNH V2 (500💎)",
        variant = "secondary",
        position = UDim2.new(0.5, 4, 0, 352),
        size = UDim2.new(0.5, -18, 0, 38),
        textSize = 11,
        onActivated = function()
            fireEquipRemote({ action = "AwakenFruit", fruitId = selectedFruit.Id })
            task.delay(0.15, function()
                Fruits.Update()
            end)
        end,
    })

    PremiumButton.Create(leftCol, {
        name = "RollGachaBtn",
        label = "🎲 QUAY GACHA TRÁI ÁC QUỶ ZIOLES (25,000 Gold)",
        variant = "primary",
        position = UDim2.fromOffset(14, 396),
        size = UDim2.new(1, -28, 0, 40),
        textSize = 12,
        onActivated = function()
            fireEquipRemote({ action = "RollFruit" })
            task.delay(0.2, function()
                local latest = Store.GetSnapshot()
                if latest and latest.fruits and latest.fruits.heldFruit and latest.fruits.heldFruit ~= "" then
                    Fruits.SelectedFruitId = latest.fruits.heldFruit
                end
                Fruits.Update()
            end)
        end,
    })

    -- Haki & Race V4 Strip inside Left Panel bottom
    UIFactory.Label(leftCol, {
        Name = "HakiHeader",
        Text = "⚡ HAKI BA LOẠI & THỨC TỈNH TỘC V4",
        Position = UDim2.fromOffset(14, 444),
        Size = UDim2.new(1, -28, 0, 20),
        TextSize = 12,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
    })

    local hakiRow = UIFactory.Create("Frame", leftCol, {
        Name = "HakiButtons",
        Position = UDim2.fromOffset(14, 468),
        Size = UDim2.new(1, -28, 0, 76),
        BackgroundTransparency = 1,
    })
    UIFactory.GridLayout(hakiRow, UDim2.new(0.5, -6, 0, 34), UDim2.fromOffset(8, 6))

    local hakiActions = {
        { id = "Aura", label = (fState.haki and fState.haki.Aura) and "⚔ HAKI VŨ TRANG: BẬT" or "⚔ HAKI VŨ TRANG [J]", act = "ToggleAura" },
        { id = "Instinct", label = (fState.haki and fState.haki.Instinct) and "👁 HAKI QUAN SÁT: BẬT" or "👁 HAKI QUAN SÁT [U]", act = "ToggleInstinct" },
        { id = "Conqueror", label = "👑 HAKI BÁ VƯƠNG [H]", act = "ConquerorBurst" },
        { id = "RaceV4", label = fState.raceV4Active and ("🪽 TỘC V4 [" .. tostring(fState.race) .. "]: BẬT") or "🪽 THỨC TỈNH TỘC V4 [Y]", act = "ActivateRaceV4" },
    }
    for idx, hk in ipairs(hakiActions) do
        PremiumButton.Create(hakiRow, {
            name = hk.id,
            label = hk.label,
            variant = "secondary",
            layoutOrder = idx,
            textSize = 11,
            onActivated = function()
                fireEquipRemote({ action = hk.act })
                task.delay(0.15, function()
                    Fruits.Update()
                end)
            end,
        })
    end

    -- Center Column: 5 Active Moves ([Z][X][C][V][F]) + Blox-Fruits 4 Slots
    local centerCol = PremiumPanel.Create(root, {
        name = "FruitMovesPanel",
        position = UDim2.new(0.31, 8, 0, 74),
        size = UDim2.new(0.33, -12, 1, -90),
    })

    UIFactory.Label(centerCol, {
        Name = "MovesHeader",
        Text = "🔥 BỘ 5 KỸ NĂNG TRÁI ÁC QUỶ ([Z] [X] [C] [V] [F])",
        Position = UDim2.fromOffset(14, 12),
        Size = UDim2.new(1, -28, 0, 24),
        TextSize = 15,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
    })

    local movesList = UIFactory.Create("Frame", centerCol, {
        Name = "MovesList",
        Position = UDim2.fromOffset(14, 44),
        Size = UDim2.new(1, -28, 1, -130),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(movesList, Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Top)

    for idx, mv in ipairs(selectedFruit.Moves) do
        local mvCard = UIFactory.Create("Frame", movesList, {
            Name = "Move_" .. mv.Key,
            Size = UDim2.new(1, 0, 0, 72),
            BackgroundColor3 = colors.BG_900,
            BorderSizePixel = 0,
            LayoutOrder = idx,
        })
        UIFactory.Corner(mvCard, Theme.Radius.Small)
        UIFactory.Stroke(mvCard, selectedFruit.Color, 1.2, 0.25)

        local keyBadge = UIFactory.Create("Frame", mvCard, {
            Name = "KeyBadge",
            Position = UDim2.fromOffset(10, 12),
            Size = UDim2.fromOffset(46, 46),
            BackgroundColor3 = colors.BG_800,
            BorderSizePixel = 0,
        })
        UIFactory.Corner(keyBadge, Theme.Radius.Small)
        UIFactory.Stroke(keyBadge, selectedFruit.Color, 1.5, 0.1)
        UIFactory.Label(keyBadge, {
            Name = "KeyText",
            Text = "[" .. mv.Key .. "]",
            Size = UDim2.fromScale(1, 1),
            TextSize = 16,
            TextColor = selectedFruit.Color,
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
        })

        UIFactory.Label(mvCard, {
            Name = "MoveName",
            Text = mv.Name,
            Position = UDim2.fromOffset(66, 10),
            Size = UDim2.new(1, -180, 0, 24),
            TextSize = 14,
            TextColor = colors.TEXT_PRIMARY,
            Bold = true,
        })

        UIFactory.Label(mvCard, {
            Name = "MoveStats",
            Text = string.format("Sát thương: %s   •   Tầm: %s   •   Hồi: %s", mv.Mult, mv.Range, mv.Cd),
            Position = UDim2.fromOffset(66, 36),
            Size = UDim2.new(1, -180, 0, 20),
            TextSize = 11,
            TextColor = colors.ACCENT_SAPPHIRE,
            Bold = true,
        })

        PremiumButton.Create(mvCard, {
            name = "Cast_" .. mv.Key,
            label = "THI TRIỂN [" .. mv.Key .. "]",
            variant = "primary",
            position = UDim2.new(1, -112, 0.5, -18),
            size = UDim2.fromOffset(102, 36),
            textSize = 11,
            onActivated = function()
                if equippedId ~= selectedFruit.Id then
                    fireEquipRemote({ action = "EatFruit", fruitId = selectedFruit.Id })
                else
                    fireEquipRemote({ action = "SelectSlot", slot = 2 })
                end
                task.delay(0.08, function()
                    ScreenRouter.CloseAllToHUD()
                    fireAbilityRemote({ action = "SlotMove", key = mv.Key })
                end)
            end,
        })
    end

    -- 4 Loadout Slots Strip at bottom of Center Column
    local slotStrip = UIFactory.Create("Frame", centerCol, {
        Name = "LoadoutSlotStrip",
        Position = UDim2.new(0, 14, 1, -74),
        Size = UDim2.new(1, -28, 0, 62),
        BackgroundTransparency = 1,
    })
    UIFactory.GridLayout(slotStrip, UDim2.new(0.25, -6, 0, 54), UDim2.fromOffset(6, 6))

    local slotsInfo = {
        { slot = 1, label = "[1] VÕ: " .. tostring(fState.fightingStyle or "SkybornCombat") },
        { slot = 2, label = "[2] TRÁI: " .. tostring(selectedFruit.Id) },
        { slot = 3, label = "[3] KIẾM: " .. tostring(snap.equipped.Weapon or "starter_sword") },
        { slot = 4, label = "[4] SÚNG: " .. tostring(fState.equippedGun or "aether_flintlock") },
    }
    for _, sl in ipairs(slotsInfo) do
        PremiumButton.Create(slotStrip, {
            name = "Slot_" .. sl.slot,
            label = sl.label,
            variant = (fState.activeSlot == sl.slot) and "gold" or "secondary",
            layoutOrder = sl.slot,
            textSize = 10,
            onActivated = function()
                fireEquipRemote({ action = "SelectSlot", slot = sl.slot })
                task.delay(0.12, function()
                    Fruits.Update()
                end)
            end,
        })
    end

    -- Right Column: All 12 Separated 3D Devil Fruits Grid
    local rightCol = PremiumPanel.Create(root, {
        name = "AllFruitsGridPanel",
        position = UDim2.new(0.64, 4, 0, 74),
        size = UDim2.new(0.36, -22, 1, -90),
    })

    UIFactory.Label(rightCol, {
        Name = "CatalogHeader",
        Text = "🍇 KHO 12 TRÁI ÁC QUỶ 3D ĐÃ TÁCH RIÊNG (CHỌN ĐỂ ĂN / CẦM 3D)",
        Position = UDim2.fromOffset(14, 12),
        Size = UDim2.new(1, -28, 0, 24),
        TextSize = 14,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
    })

    local scroll = UIFactory.Create("ScrollingFrame", rightCol, {
        Name = "FruitScroll",
        Position = UDim2.fromOffset(14, 44),
        Size = UDim2.new(1, -28, 1, -56),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 5,
        ScrollBarImageColor3 = colors.ACCENT_GOLD,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.fromOffset(0, 0),
    })
    UIFactory.GridLayout(scroll, UDim2.new(0.5, -6, 0, 94), UDim2.fromOffset(8, 8))

    local stored = fState.storedFruits or {}
    for idx, item in ipairs(FRUIT_CATALOG) do
        local isSelected = (item.Id == selectedFruit.Id)
        local isEq = (item.Id == equippedId)
        local ownedCount = tonumber(stored[item.Id]) or 0

        local card = UIFactory.Create("TextButton", scroll, {
            Name = item.Id,
            BackgroundColor3 = isSelected and colors.BG_800 or colors.BG_900,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = true,
            LayoutOrder = idx,
        })
        UIFactory.Corner(card, Theme.Radius.Small)
        UIFactory.Stroke(card, isEq and colors.ACCENT_GOLD or (isSelected and item.Color or colors.BORDER_MUTED), isEq and 2.0 or 1.2, 0.1)

        UIFactory.Label(card, {
            Name = "Title",
            Text = item.Name,
            Position = UDim2.fromOffset(10, 6),
            Size = UDim2.new(1, -20, 0, 20),
            TextSize = 12,
            TextColor = item.Color,
            Bold = true,
        })

        UIFactory.Label(card, {
            Name = "RarityType",
            Text = item.Rarity .. " • " .. item.Type,
            Position = UDim2.fromOffset(10, 26),
            Size = UDim2.new(1, -20, 0, 16),
            TextSize = 10,
            TextColor = colors.TEXT_SECONDARY,
            Bold = true,
        })

        UIFactory.Label(card, {
            Name = "Status",
            Text = isEq and "★ ĐANG TRANG BỊ" or (ownedCount > 0 and ("Trong kho: x" .. tostring(ownedCount)) or "Sẵn sàng trang bị"),
            Position = UDim2.fromOffset(10, 44),
            Size = UDim2.new(1, -20, 0, 16),
            TextSize = 10,
            TextColor = isEq and colors.ACCENT_GOLD or colors.ACCENT_SAPPHIRE,
            Bold = true,
        })

        PremiumButton.Create(card, {
            name = "QuickEat_" .. item.Id,
            label = isEq and "ĐANG DÙNG" or "🍎 ĂN NGAY",
            variant = isEq and "gold" or "primary",
            position = UDim2.fromOffset(8, 62),
            size = UDim2.new(0.54, -10, 0, 26),
            textSize = 10,
            onActivated = function()
                Fruits.SelectedFruitId = item.Id
                fireEquipRemote({ action = "EatFruit", fruitId = item.Id })
                task.delay(0.15, function()
                    Fruits.Update()
                end)
            end,
        })

        PremiumButton.Create(card, {
            name = "QuickHold_" .. item.Id,
            label = "✋ CẦM 3D",
            variant = "secondary",
            position = UDim2.new(0.54, 2, 0, 62),
            size = UDim2.new(0.46, -10, 0, 26),
            textSize = 10,
            onActivated = function()
                Fruits.SelectedFruitId = item.Id
                fireEquipRemote({ action = "HoldFruit", fruitId = item.Id, forceHold = true })
                task.delay(0.15, function()
                    Fruits.Update()
                end)
            end,
        })

        card.Activated:Connect(function()
            Fruits.SelectedFruitId = item.Id
            Fruits.Update()
        end)
    end

    return root
end

function Fruits.Update()
    local App = require(script.Parent.Parent:WaitForChild("App"))
    if ScreenRouter.CurrentScreen == UIState.Screens.Fruits then
        App.RebuildActiveScreen()
    end
end

return Fruits
