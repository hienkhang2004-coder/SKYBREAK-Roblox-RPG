-- SKYBREAK: Fragments of the Core — 3D Character Paperdoll, 8 Equipment Slots & Vivid 6-Rarity Inventory ([I])
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/Inventory.lua
-- Matches SKYBREAK_3DBible_05_Paperdoll_And_Forge.png (Top Paperdoll & Inventory Layout) 1:1:
--   * Left Gold-Framed Paperdoll Showcase: 3D Hero Rig standing on glowing 3D Cyan Rune Rings flanked by 4 Left + 4 Right Vivid Glossy Equipment Slots, plus Bottom Active 3D Armor Set Bonus & Combat Power Card
--   * Right Gold-Framed Arsenal Storage: Search Box + Emerald "TRANG BỊ TỐI ƯU" (Equip Best) CTA + Sort + Gold-Active Filter Pills + Vivid Glossy 6-Rarity Item Cards Grid + Bottom Detail & Stat-Diff Showcase Dock.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local RarityConfig = require(Shared:WaitForChild("Config"):WaitForChild("RarityConfig"))
local ArsenalExpansionConfig = require(Shared:WaitForChild("Config"):WaitForChild("ArsenalExpansionConfig"))
local WorldConfig = require(Shared:WaitForChild("Config"):WaitForChild("WorldConfig"))
local UIState = require(Shared:WaitForChild("Types"):WaitForChild("UIState"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Store = require(script.Parent.Parent:WaitForChild("Store"))
local ScreenRouter = require(script.Parent.Parent:WaitForChild("ScreenRouter"))
local I18n = require(script.Parent.Parent:WaitForChild("I18n"))
local PremiumPanel = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumPanel"))
local PremiumButton = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumButton"))
local ItemSlot = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("ItemSlot"))
local Tooltip = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("Tooltip"))
local InventoryController = require(script.Parent.Parent:WaitForChild("Controllers"):WaitForChild("InventoryController"))

local Inventory = {
    Refs = {},
    HoveredItemId = nil,
}

local PAPERDOLL_SLOTS = {
    -- Left Column (Armor)
    { Id = "Helm",      Side = "Left",  Row = 0, Icon = "Shield", TagVi = "MŨ GIÁP",   TagEn = "HELM" },
    { Id = "Chest",     Side = "Left",  Row = 1, Icon = "Shield", TagVi = "GIÁP NGỰC", TagEn = "CHEST" },
    { Id = "Gauntlets", Side = "Left",  Row = 2, Icon = "Fist",   TagVi = "HỘ UYỂN",   TagEn = "GAUNTLET" },
    { Id = "Greaves",   Side = "Left",  Row = 3, Icon = "Wing",   TagVi = "CHIẾN HÀI", TagEn = "GREAVES" },
    -- Right Column (Weapons & Relics)
    { Id = "Weapon",    Side = "Right", Row = 0, Icon = "Sword",  TagVi = "VŨ KHÍ",    TagEn = "WEAPON" },
    { Id = "Offhand",   Side = "Right", Row = 1, Icon = "Shield", TagVi = "PHÁP KHÍ",  TagEn = "OFFHAND" },
    { Id = "Ring",      Side = "Right", Row = 2, Icon = "Gem",    TagVi = "NHẪN",      TagEn = "RING" },
    { Id = "Artifact",  Side = "Right", Row = 3, Icon = "Core",   TagVi = "THÁNH VẬT", TagEn = "RELIC" },
}

local STAT_NAMES_VI = {
    ATK = "ATK",
    DEF = "DEF",
    HP = "HP",
    CRIT = "CRIT",
    CritRate = "CRIT",
    CritDmg = "CRIT DMG",
    ENERGY = "AETHER",
    SPEED = "SPD",
    SPD = "SPD",
    Break = "PHÁ GIÁP",
}

local function ensureDefaultSelectedItem(snap, view)
    if view.selectedItemId and RarityConfig.GetItem(view.selectedItemId) then
        return view.selectedItemId
    end
    local eqMap = snap.equipped or snap.equipment or {}
    if eqMap.Weapon and RarityConfig.GetItem(eqMap.Weapon) then
        Store.SetView({ selectedItemId = eqMap.Weapon })
        return eqMap.Weapon
    end
    for _, entry in ipairs(snap.inventory or {}) do
        if (entry.count or 0) > 0 and RarityConfig.GetItem(entry.itemId) then
            Store.SetView({ selectedItemId = entry.itemId })
            return entry.itemId
        end
    end
    return nil
end

function Inventory.Build(parent, _responsiveState)
    Inventory.Cleanup()
    local colors = Theme.Colors
    local snap = Store.GetSnapshot()
    local view = Store.GetView()

    if Store.Session.inventoryPreviewMode == nil then
        Store.Session.inventoryPreviewMode = "Hero"
    end
    ensureDefaultSelectedItem(snap, view)

    local root = UIFactory.Create("Frame", parent, {
        Name = "InventoryScreen",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 2,
    })

    -- Shared Top Screen Header with Currency Pills & Navigation Tabs
    local _, headerRefs = UIFactory.BuildScreenHeader(root, {
        ActiveScreen = UIState.Screens.Inventory,
        Title = I18n.Pick("KHO HÀNH TRANG & TRANG BỊ 3D [I]", "3D INVENTORY & PAPERDOLL [I]"),
        Snapshot = snap,
        OnNavigate = function(targetId)
            ScreenRouter.Navigate(targetId)
        end,
        OnClose = function()
            ScreenRouter.CloseAllToHUD()
        end,
    })

    -- =========================================================================
    -- LEFT PANEL (41%): 3D Hero Paperdoll + 8 Flanking Glossy Equipment Slots + Set Bonus Card
    -- =========================================================================
    local leftPanel = PremiumPanel.Create(root, {
        name = "PaperdollPanel",
        variant = "gold",
        title = I18n.Pick("MÔ HÌNH NHÂN VẬT 3D & 8 Ô TRANG BỊ", "3D PAPERDOLL & 8 EQUIPPED SLOTS"),
        position = UDim2.fromOffset(14, 72),
        size = UDim2.new(0.41, -18, 1, -86),
        transparency = 0.04,
    })

    -- Top-Right Compact 3D View Mode Switcher (NHÂN VẬT 3D / VŨ KHÍ 3D)
    local previewMode = Store.Session.inventoryPreviewMode or "Hero"
    local modeToggleHolder = UIFactory.Create("Frame", leftPanel, {
        Name = "PreviewModeSwitch",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 10),
        Size = UDim2.fromOffset(168, 24),
        BackgroundTransparency = 1,
        ZIndex = 8,
    })
    UIFactory.ListLayout(modeToggleHolder, Enum.FillDirection.Horizontal, 4, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)

    local _, heroModeApi = PremiumButton.Create(modeToggleHolder, {
        name = "Mode3DHero",
        label = I18n.Pick("NHÂN VẬT 3D", "3D HERO"),
        variant = (previewMode == "Hero") and "gold" or "secondary",
        selected = (previewMode == "Hero"),
        size = UDim2.fromOffset(82, 24),
        textSize = 9,
        minTextSize = 8,
        layoutOrder = 1,
        zIndex = 9,
    })

    local _, wepModeApi = PremiumButton.Create(modeToggleHolder, {
        name = "Mode3DWeapon",
        label = I18n.Pick("VŨ KHÍ 3D", "3D WEAPON"),
        variant = (previewMode == "Weapon") and "gold" or "secondary",
        selected = (previewMode == "Weapon"),
        size = UDim2.fromOffset(82, 24),
        textSize = 9,
        minTextSize = 8,
        layoutOrder = 2,
        zIndex = 9,
    })

    -- Paperdoll Stage Area (y = 46, height = 322 -> fits 4x76px equipment cards + 6px gaps cleanly!)
    local paperdollArena = UIFactory.Create("Frame", leftPanel, {
        Name = "PaperdollArena",
        Position = UDim2.fromOffset(12, 46),
        Size = UDim2.new(1, -24, 0, 322),
        BackgroundTransparency = 1,
        ZIndex = 5,
    })

    local stageBackdrop = UIFactory.Create("Frame", paperdollArena, {
        Name = "PaperdollStageBackdrop",
        Position = UDim2.fromOffset(82, 0),
        Size = UDim2.new(1, -164, 1, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 5,
    })
    UIFactory.Corner(stageBackdrop, 12)
    UIFactory.Stroke(stageBackdrop, Color3.fromRGB(72, 148, 218), 1.4, 0.22)
    UIFactory.Gradient(stageBackdrop, Color3.fromRGB(22, 40, 74), Color3.fromRGB(8, 13, 25), 90)

    -- Subtle glowing floor aura disc behind character feet
    local stageFloorGlow = UIFactory.Create("Frame", stageBackdrop, {
        Name = "FloorAuraGlow",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -26),
        Size = UDim2.fromOffset(168, 44),
        BackgroundColor3 = Color3.fromRGB(56, 212, 255),
        BackgroundTransparency = 0.82,
        BorderSizePixel = 0,
        ZIndex = 5,
    })
    UIFactory.PillCorner(stageFloorGlow)

    local viewport = UIFactory.Create("ViewportFrame", stageBackdrop, {
        Name = "CharacterPreview",
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.new(1, -4, 1, -4),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Ambient = Color3.fromRGB(205, 218, 242),
        LightColor = Color3.fromRGB(255, 245, 218),
        LightDirection = Vector3.new(-0.55, -0.75, -0.85),
        ZIndex = 6,
    })

    -- Bottom-Center Orbit/Zoom Hint Pill ("KÉO CHUỘT XOAY 360 • ZOOM")
    local orbitHintBtn = UIFactory.Create("TextButton", stageBackdrop, {
        Name = "OrbitZoomPill",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -7),
        Size = UDim2.fromOffset(172, 20),
        BackgroundColor3 = Color3.fromRGB(8, 13, 24),
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 8,
    })
    UIFactory.PillCorner(orbitHintBtn)
    UIFactory.Stroke(orbitHintBtn, Color3.fromRGB(72, 212, 255), 1.2, 0.20)
    local hintLbl = UIFactory.Label(orbitHintBtn, {
        Name = "HintText",
        Text = I18n.Pick("KÉO CHUỘT XOAY 360 • ZOOM", "DRAG 360 ORBIT • SCROLL ZOOM"),
        Position = UDim2.fromOffset(6, 0),
        Size = UDim2.new(1, -12, 1, 0),
        TextSize = 8,
        TextColor = Color3.fromRGB(168, 232, 255),
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = 9,
    })
    UIFactory.TextSizeConstraint(hintLbl, 7, 9)
    orbitHintBtn.Activated:Connect(function()
        InventoryController.UpdateCameraRotation(0)
    end)

    local equipSlotContainer = UIFactory.Create("Frame", paperdollArena, {
        Name = "EquipmentSlots",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 7,
    })

    -- Bottom Set Bonus & Combat Stats Card (directly under Paperdoll Stage)
    local setBonusCard = UIFactory.Create("Frame", leftPanel, {
        Name = "SetBonusAndStatsCard",
        Position = UDim2.fromOffset(12, 376),
        Size = UDim2.new(1, -24, 1, -388),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 5,
    })
    UIFactory.Corner(setBonusCard, 11)
    UIFactory.Stroke(setBonusCard, colors.ACCENT_GOLD_BRIGHT, 1.5, 0.14)
    UIFactory.Gradient(setBonusCard, Color3.fromRGB(20, 32, 58), Color3.fromRGB(10, 15, 28), 90)

    local setHeaderLabel = UIFactory.Label(setBonusCard, {
        Name = "SetHeader",
        Text = "",
        Position = UDim2.fromOffset(12, 7),
        Size = UDim2.new(1, -148, 0, 18),
        TextSize = 11,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = 6,
    })

    local combatPowerPill = UIFactory.Create("Frame", setBonusCard, {
        Name = "CombatPowerPill",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 6),
        Size = UDim2.fromOffset(132, 20),
        BackgroundColor3 = Color3.fromRGB(10, 26, 24),
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        ZIndex = 6,
    })
    UIFactory.PillCorner(combatPowerPill)
    UIFactory.Stroke(combatPowerPill, Color3.fromRGB(52, 211, 153), 1.2, 0.16)
    local combatPowerLabel = UIFactory.Label(combatPowerPill, {
        Name = "PowerText",
        Text = "CP 0",
        Position = UDim2.fromOffset(6, 0),
        Size = UDim2.new(1, -12, 1, 0),
        TextSize = 9,
        TextColor = Color3.fromRGB(110, 242, 184),
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = 7,
    })

    local statsSummaryStrip = UIFactory.Label(setBonusCard, {
        Name = "StatsSummaryStrip",
        Text = "",
        Position = UDim2.fromOffset(12, 28),
        Size = UDim2.new(1, -24, 0, 18),
        TextSize = 11,
        TextColor = colors.TEXT_PRIMARY,
        RichText = true,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = 6,
    })

    local setBonusBodyLabel = UIFactory.Label(setBonusCard, {
        Name = "SetBonusBody",
        Text = "",
        Position = UDim2.fromOffset(12, 48),
        Size = UDim2.new(1, -138, 1, -54),
        TextSize = 10,
        TextColor = colors.TEXT_SECONDARY,
        YAlign = Enum.TextYAlignment.Top,
        RichText = true,
        ZIndex = 6,
    })

    PremiumButton.Create(setBonusCard, {
        name = "OpenForgeShortcut",
        icon = "Forge",
        label = I18n.Pick("LÒ RÈN [F]", "FORGE [F]"),
        variant = "gold",
        anchorPoint = Vector2.new(1, 1),
        position = UDim2.new(1, -10, 1, -8),
        size = UDim2.fromOffset(118, 30),
        textSize = 10,
        minTextSize = 8,
        zIndex = 7,
        onActivated = function()
            ScreenRouter.Navigate(UIState.Screens.Forge)
        end,
    })

    -- =========================================================================
    -- RIGHT PANEL (59%): Search + Emerald "TRANG BỊ TỐI ƯU" + Filter Pills + Glossy Grid + Bottom Detail Dock
    -- =========================================================================
    local rightPanel = PremiumPanel.Create(root, {
        name = "InventoryGridPanel",
        variant = "gold",
        title = I18n.Pick("TÚI ĐỒ & KHO THẦN TRANG 3D", "3D ARSENAL & INVENTORY STORAGE"),
        position = UDim2.new(0.41, 4, 0, 72),
        size = UDim2.new(0.59, -18, 1, -86),
        transparency = 0.04,
    })

    -- Row 1 (y = 44): Search Input + Emerald "TRANG BỊ TỐI ƯU" CTA + Sort Button
    local searchFrame = UIFactory.Create("Frame", rightPanel, {
        Name = "SearchFrame",
        Position = UDim2.fromOffset(14, 44),
        Size = UDim2.new(1, -304, 0, 32),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
        ZIndex = 6,
    })
    UIFactory.Corner(searchFrame, 8)
    UIFactory.Stroke(searchFrame, colors.STROKE_STEEL, 1.3, 0.26)
    UIFactory.Icon(searchFrame, "Compass", UDim2.new(0, 8, 0.5, -7), 14, colors.ACCENT_SAPPHIRE).ZIndex = 7

    local searchBox = UIFactory.Create("TextBox", searchFrame, {
        Name = "Search",
        Position = UDim2.fromOffset(28, 0),
        Size = UDim2.new(1, -34, 1, 0),
        Text = view.searchQuery or "",
        PlaceholderText = I18n.Pick("Tìm trang bị, vũ khí, trái Aether...", "Search gear, weapons, Aether fruits..."),
        Font = Theme.Fonts.Medium,
        TextSize = 11,
        TextColor3 = colors.TEXT_PRIMARY,
        PlaceholderColor3 = colors.TEXT_MUTED,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 7,
    })

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        Store.SetView({ searchQuery = searchBox.Text })
        Inventory.RefreshGrid()
    end)

    PremiumButton.Create(rightPanel, {
        name = "EquipBestBtn",
        icon = "Sparkle",
        label = I18n.Pick("TRANG BỊ TỐI ƯU", "EQUIP BEST"),
        variant = "emerald",
        anchorPoint = Vector2.new(1, 0),
        position = UDim2.new(1, -138, 0, 44),
        size = UDim2.fromOffset(146, 32),
        textSize = 10,
        minTextSize = 8,
        zIndex = 6,
        onActivated = function()
            InventoryController.EquipBestLoadout()
            Inventory.RefreshAll()
        end,
    })

    local sortModes = { "Rarity", "Level", "Name" }
    local _, sortBtnApi = PremiumButton.Create(rightPanel, {
        name = "SortButton",
        label = I18n.Pick("XẾP: ", "SORT: ") .. I18n.GetSortLabel(view.inventorySort or "Rarity"),
        variant = "secondary",
        anchorPoint = Vector2.new(1, 0),
        position = UDim2.new(1, -14, 0, 44),
        size = UDim2.fromOffset(118, 32),
        textSize = 10,
        minTextSize = 8,
        zIndex = 6,
        onActivated = function()
            local cur = Store.GetView().inventorySort or "Rarity"
            local nextMode = "Rarity"
            for i, m in ipairs(sortModes) do
                if m == cur then
                    nextMode = sortModes[(i % #sortModes) + 1]
                    break
                end
            end
            Store.SetView({ inventorySort = nextMode })
            Inventory.RefreshGrid()
        end,
    })

    -- Row 2 (y = 82): Category Filter Pills (Active Tab = Glossy Gold)
    local filterHolder = UIFactory.Create("Frame", rightPanel, {
        Name = "FilterTabs",
        Position = UDim2.fromOffset(14, 82),
        Size = UDim2.new(1, -28, 0, 28),
        BackgroundTransparency = 1,
        ZIndex = 6,
    })
    UIFactory.ListLayout(filterHolder, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    local filterDefs = {
        { id = "All",         label = I18n.Pick("TẤT CẢ", "ALL"),        w = 78 },
        { id = "Weapons",     label = I18n.Pick("VŨ KHÍ", "WEAPONS"),    w = 82 },
        { id = "Armor",       label = I18n.Pick("GIÁP 3D", "3D ARMOR"),  w = 84 },
        { id = "Accessories", label = I18n.Pick("PHỤ KIỆN", "RELICS"),   w = 88 },
        { id = "Materials",   label = I18n.Pick("NGUYÊN LIỆU", "MATS"),  w = 98 },
        { id = "Quest",       label = I18n.Pick("NHIỆM VỤ", "QUEST"),    w = 84 },
    }
    local filterApis = {}
    for idx, fDef in ipairs(filterDefs) do
        local isSel = ((view.inventoryFilter or "All") == fDef.id)
        local _, fApi = PremiumButton.Create(filterHolder, {
            name = "Filter_" .. fDef.id,
            label = fDef.label,
            variant = isSel and "gold" or "secondary",
            selected = isSel,
            size = UDim2.fromOffset(fDef.w, 28),
            textSize = 10,
            minTextSize = 8,
            layoutOrder = idx,
            zIndex = 7,
            onActivated = function()
                Store.SetView({ inventoryFilter = fDef.id })
                for fid, api in pairs(filterApis) do
                    api:Update({
                        variant = (fid == fDef.id) and "gold" or "secondary",
                        selected = (fid == fDef.id),
                    })
                end
                Inventory.RefreshGrid()
            end,
        })
        filterApis[fDef.id] = fApi
    end

    -- Row 3 (y = 118): Scrolling Vivid Glossy 6-Rarity Item Cards Grid
    local gridScroll = UIFactory.Create("ScrollingFrame", rightPanel, {
        Name = "Slots",
        Position = UDim2.fromOffset(14, 118),
        Size = UDim2.new(1, -28, 1, -286),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 5,
        ScrollBarImageColor3 = colors.ACCENT_GOLD_BRIGHT,
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex = 5,
    })
    UIFactory.Padding(gridScroll, 4, 6, 8, 2)
    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.Name = "RarityCardGrid"
    gridLayout.CellSize = UDim2.fromOffset(92, 102)
    gridLayout.CellPadding = UDim2.fromOffset(8, 8)
    gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
    gridLayout.Parent = gridScroll

    -- Row 4 (Bottom Dock, height = 156): Selected Item Vivid Showcase, Stat-Diff & Action Buttons
    local detailDock = UIFactory.Create("Frame", rightPanel, {
        Name = "ItemDetailDock",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 14, 1, -12),
        Size = UDim2.new(1, -28, 0, 156),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 6,
    })
    UIFactory.Corner(detailDock, 12)
    local detailStroke = UIFactory.Stroke(detailDock, colors.ACCENT_GOLD_BRIGHT, 1.6, 0.10)
    UIFactory.Gradient(detailDock, Color3.fromRGB(22, 34, 62), Color3.fromRGB(9, 14, 26), 90)

    local detailPreviewHolder = UIFactory.Create("Frame", detailDock, {
        Name = "PreviewCardHolder",
        Position = UDim2.fromOffset(12, 12),
        Size = UDim2.fromOffset(96, 108),
        BackgroundTransparency = 1,
        ZIndex = 7,
    })

    local detailStarsHolder = UIFactory.Create("Frame", detailDock, {
        Name = "DetailStarsHolder",
        Position = UDim2.fromOffset(12, 126),
        Size = UDim2.fromOffset(96, 18),
        BackgroundTransparency = 1,
        ZIndex = 7,
    })

    local detailTitleLabel = UIFactory.Label(detailDock, {
        Name = "DetailTitle",
        Text = I18n.Pick("Chọn vật phẩm để xem chi tiết", "Select an item to inspect"),
        Position = UDim2.fromOffset(122, 10),
        Size = UDim2.new(1, -284, 0, 22),
        TextSize = 15,
        TextColor = colors.TEXT_PRIMARY,
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = 7,
    })

    local detailRarityBadge = UIFactory.Create("Frame", detailDock, {
        Name = "DetailRarityBadge",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 10),
        Size = UDim2.fromOffset(148, 22),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 7,
    })
    UIFactory.PillCorner(detailRarityBadge)
    local detailRarityStroke = UIFactory.Stroke(detailRarityBadge, colors.ACCENT_GOLD_BRIGHT, 1.4, 0.06)
    local detailRarityGrad = UIFactory.Gradient(detailRarityBadge, Color3.fromRGB(252, 211, 77), Color3.fromRGB(180, 83, 9), 90)
    local detailRarityText = UIFactory.Label(detailRarityBadge, {
        Name = "BadgeText",
        Text = "COMMON",
        Position = UDim2.fromOffset(6, 0),
        Size = UDim2.new(1, -12, 1, 0),
        TextSize = 10,
        TextColor = Color3.fromRGB(16, 18, 28),
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = 8,
    })

    local detailMetaLabel = UIFactory.Label(detailDock, {
        Name = "DetailMeta",
        Text = "",
        Position = UDim2.fromOffset(122, 33),
        Size = UDim2.new(1, -134, 0, 15),
        TextSize = 10,
        TextColor = colors.TEXT_SECONDARY,
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = 7,
    })

    local detailStatsLabel = UIFactory.Label(detailDock, {
        Name = "DetailStatsAndDiff",
        Text = "",
        Position = UDim2.fromOffset(122, 51),
        Size = UDim2.new(1, -134, 0, 20),
        TextSize = 11,
        TextColor = colors.TEXT_PRIMARY,
        RichText = true,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = 7,
    })

    local detailPassiveLabel = UIFactory.Label(detailDock, {
        Name = "DetailPassive",
        Text = "",
        Position = UDim2.fromOffset(122, 72),
        Size = UDim2.new(1, -134, 0, 34),
        TextSize = 10,
        TextColor = Color3.fromRGB(190, 206, 232),
        YAlign = Enum.TextYAlignment.Top,
        RichText = true,
        ZIndex = 7,
    })

    local detailActionsRow = UIFactory.Create("Frame", detailDock, {
        Name = "DetailActionsRow",
        Position = UDim2.fromOffset(122, 112),
        Size = UDim2.new(1, -134, 0, 32),
        BackgroundTransparency = 1,
        ZIndex = 7,
    })
    UIFactory.ListLayout(detailActionsRow, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    local equipActionBtn, equipActionApi = PremiumButton.Create(detailActionsRow, {
        name = "DetailEquipBtn",
        icon = "Sword",
        label = I18n.Pick("TRANG BỊ NGAY", "EQUIP ITEM"),
        variant = "primary",
        size = UDim2.fromOffset(146, 32),
        textSize = 11,
        minTextSize = 9,
        layoutOrder = 1,
        zIndex = 8,
        onActivated = function()
            local curId = Inventory.Refs and Inventory.Refs.CurrentInspectId
            if not curId then
                return
            end
            local curEq = Inventory.Refs.CurrentInspectEquipped == true
            InventoryController.RequestEquipToggle(curId, curEq)
            Inventory.RefreshAll()
        end,
    })

    local forgeActionBtn, _ = PremiumButton.Create(detailActionsRow, {
        name = "DetailForgeBtn",
        icon = "Forge",
        label = I18n.Pick("CƯỜNG HÓA & SAO [F]", "UPGRADE & STARS [F]"),
        variant = "gold",
        size = UDim2.fromOffset(162, 32),
        textSize = 10,
        minTextSize = 8,
        layoutOrder = 2,
        zIndex = 8,
        onActivated = function()
            ScreenRouter.Navigate(UIState.Screens.Forge)
        end,
    })

    local _, zoomToggleApi = PremiumButton.Create(detailActionsRow, {
        name = "Detail3DModeToggle",
        icon = "Sparkle",
        label = (previewMode == "Hero") and I18n.Pick("SOI VŨ KHÍ 3D", "3D WEAPON VIEW") or I18n.Pick("SOI NHÂN VẬT 3D", "3D HERO VIEW"),
        variant = "secondary",
        size = UDim2.fromOffset(132, 32),
        textSize = 10,
        minTextSize = 8,
        layoutOrder = 3,
        zIndex = 8,
    })

    local function setPreviewMode(nextMode)
        Store.Session.inventoryPreviewMode = nextMode
        heroModeApi:Update({
            variant = (nextMode == "Hero") and "gold" or "secondary",
            selected = (nextMode == "Hero"),
        })
        wepModeApi:Update({
            variant = (nextMode == "Weapon") and "gold" or "secondary",
            selected = (nextMode == "Weapon"),
        })
        zoomToggleApi:Update({
            label = (nextMode == "Hero") and I18n.Pick("SOI VŨ KHÍ 3D", "3D WEAPON VIEW") or I18n.Pick("SOI NHÂN VẬT 3D", "3D HERO VIEW"),
        })
        InventoryController.CurrentPreviewKey = nil
        InventoryController.MountViewportPreview(viewport, Inventory.HoveredItemId or Store.GetView().selectedItemId)
    end

    heroModeApi.Instance.Activated:Connect(function()
        setPreviewMode("Hero")
    end)
    wepModeApi.Instance.Activated:Connect(function()
        setPreviewMode("Weapon")
    end)
    zoomToggleApi.Instance.Activated:Connect(function()
        local curMode = Store.Session.inventoryPreviewMode or "Hero"
        setPreviewMode(curMode == "Hero" and "Weapon" or "Hero")
    end)

    Inventory.Refs = {
        Root = root,
        HeaderRefs = headerRefs,
        Viewport = viewport,
        EquipSlotContainer = equipSlotContainer,
        SetHeaderLabel = setHeaderLabel,
        CombatPowerLabel = combatPowerLabel,
        StatsSummaryStrip = statsSummaryStrip,
        SetBonusBodyLabel = setBonusBodyLabel,
        GridScroll = gridScroll,
        SortBtnApi = sortBtnApi,
        DetailStroke = detailStroke,
        DetailPreviewHolder = detailPreviewHolder,
        DetailStarsHolder = detailStarsHolder,
        DetailTitleLabel = detailTitleLabel,
        DetailRarityStroke = detailRarityStroke,
        DetailRarityGrad = detailRarityGrad,
        DetailRarityText = detailRarityText,
        DetailMetaLabel = detailMetaLabel,
        DetailStatsLabel = detailStatsLabel,
        DetailPassiveLabel = detailPassiveLabel,
        EquipActionBtn = equipActionBtn,
        EquipActionApi = equipActionApi,
        ForgeActionBtn = forgeActionBtn,
        CurrentInspectId = nil,
        CurrentInspectEquipped = false,
    }

    Inventory.RefreshAll()
    return root
end

function Inventory.RefreshStats()
    local refs = Inventory.Refs
    if not refs or not refs.SetHeaderLabel then
        return
    end
    local snap = Store.GetSnapshot()
    if refs.HeaderRefs and refs.HeaderRefs.UpdateCurrencies then
        refs.HeaderRefs.UpdateCurrencies(snap)
    end

    local classCfg = WorldConfig.Classes[snap.player.classId] or WorldConfig.Classes.SkyGuardian
    local lvl = tonumber(snap.player.level) or 1
    local mult = classCfg.BaseMultipliers or { HP = 1, ATK = 1, DEF = 1, Speed = 18 }

    local totalHP = math.floor((120 + 18 * (lvl - 1)) * (mult.HP or 1))
    local totalATK = math.floor((12 + 2 * (lvl - 1)) * (mult.ATK or 1))
    local totalDEF = math.floor((4 + lvl - 1) * (mult.DEF or 1))
    local totalCRIT = 5

    local eqMap = snap.equipped or snap.equipment or {}
    for _, itemId in pairs(eqMap) do
        local cfg = RarityConfig.GetItem(itemId)
        if cfg and cfg.Stats then
            totalHP = totalHP + (tonumber(cfg.Stats.HP) or 0)
            totalATK = totalATK + (tonumber(cfg.Stats.ATK) or 0)
            totalDEF = totalDEF + (tonumber(cfg.Stats.DEF) or 0)
            totalCRIT = totalCRIT + (tonumber(cfg.Stats.CRIT) or tonumber(cfg.Stats.CritRate) or 0)
        end
    end

    if not snap.isDemoMode then
        totalHP = tonumber(snap.vitals and snap.vitals.maxHp) or totalHP
        totalATK = tonumber(snap.player and snap.player.atk) or totalATK
        totalDEF = tonumber(snap.player and snap.player.def) or totalDEF
        totalCRIT = tonumber(snap.player and snap.player.critRate) or totalCRIT
    end

    local combatPower = math.floor(totalHP * 0.65 + totalATK * 14 + totalDEF * 11 + totalCRIT * 85 + lvl * 40)
    if refs.CombatPowerLabel then
        refs.CombatPowerLabel.Text = I18n.Pick("LỰC CHIẾN ", "POWER ") .. UIFactory.FormatNumber(combatPower)
    end

    if refs.StatsSummaryStrip then
        refs.StatsSummaryStrip.Text = string.format(
            "<font color='#34D399'><b>HP</b> %s</font>   •   <font color='#FBBF24'><b>ATK</b> %s</font>   •   <font color='#38BDF8'><b>DEF</b> %s</font>   •   <font color='#F472B6'><b>CRIT</b> %d%%</font>",
            UIFactory.FormatNumber(totalHP),
            UIFactory.FormatNumber(totalATK),
            UIFactory.FormatNumber(totalDEF),
            math.floor(totalCRIT)
        )
    end

    local setInfo = ArsenalExpansionConfig.GetActiveArmorSetInfo(eqMap)
    if setInfo and setInfo.BestSet then
        local bs = setInfo.BestSet
        local setName = tostring(I18n.GetLanguage() == "en" and bs.NameEn or bs.NameVi)
        refs.SetHeaderLabel.Text = string.format("* %s (%d/4)", string.upper(setName), bs.Count or 0)
        refs.SetBonusBodyLabel.Text = string.format(
            "<font color='%s'>• [2/4] %s</font>\n<font color='%s'>• [4/4] %s</font>",
            bs.Bonus2Active and "#34D399" or "#7C90B3",
            tostring(I18n.GetLanguage() == "en" and bs.Bonus2En or bs.Bonus2Vi),
            bs.Bonus4Active and "#FCD34D" or "#7C90B3",
            tostring(I18n.GetLanguage() == "en" and bs.Bonus4En or bs.Bonus4Vi)
        )
    else
        refs.SetHeaderLabel.Text = string.format("* %s • LV. %d", string.upper(classCfg.Name or "SKYGUARDIAN"), lvl)
        refs.SetBonusBodyLabel.Text = string.format(
            "<font color='#5CE1FF'><b>%s</b></font>\n%s",
            I18n.Pick("HÀO QUANG 8 BỘ THẦN GIÁP 3D (2/4 & 4/4)", "8 WEARABLE 3D ARMOR SETS (2/4 & 4/4)"),
            I18n.Pick("Mặc đủ 2 hoặc 4 mảnh cùng bộ để kích hoạt Nội Tại & Hào Quang 3D.", "Equip 2 or 4 matching armor pieces to unlock Set Bonus & 3D Aura.")
        )
    end
end

function Inventory.RefreshEquipmentSlots()
    local refs = Inventory.Refs
    local holder = refs and refs.EquipSlotContainer
    if not holder then
        return
    end
    for _, child in ipairs(holder:GetChildren()) do
        child:Destroy()
    end

    local snap = Store.GetSnapshot()
    local view = Store.GetView()
    local eqMap = snap.equipped or snap.equipment or {}

    local invLookup = {}
    for _, entry in ipairs(snap.inventory or {}) do
        invLookup[entry.itemId] = entry
    end

    for _, pSlot in ipairs(PAPERDOLL_SLOTS) do
        local isLeft = (pSlot.Side == "Left")
        local pos = isLeft
            and UDim2.fromOffset(0, pSlot.Row * 82)
            or UDim2.new(1, -74, 0, pSlot.Row * 82)

        local equippedItemId = eqMap[pSlot.Id]
        local invEntry = equippedItemId and invLookup[equippedItemId] or nil
        local upg = invEntry and (tonumber(invEntry.upgrade) or 0) or 0
        local stars = (equippedItemId and (pSlot.Id == "Weapon" or pSlot.Id == "Gun")) and Store.GetWeaponStar(equippedItemId) or 0
        local slotTag = I18n.Pick(pSlot.TagVi, pSlot.TagEn)

        ItemSlot.Create(holder, {
            name = "EquipSlot_" .. pSlot.Id,
            itemId = equippedItemId,
            slotLabel = slotTag,
            slotHeaderTag = slotTag,
            slotIcon = pSlot.Icon,
            upgrade = upg,
            stars = stars,
            showSubStat = true,
            hideEquipBadge = true,
            equipped = equippedItemId ~= nil,
            selected = (equippedItemId ~= nil and view.selectedItemId == equippedItemId),
            position = pos,
            size = UDim2.fromOffset(74, 76),
            zIndex = 8,
            onHover = function(isHovering, hoveredId)
                if isHovering and hoveredId then
                    Inventory.HoveredItemId = hoveredId
                    Inventory.RefreshTooltip(hoveredId)
                elseif not isHovering and Inventory.HoveredItemId == hoveredId then
                    Inventory.HoveredItemId = nil
                    Inventory.RefreshTooltip()
                end
            end,
            onSelect = function(clickedId)
                if clickedId then
                    Inventory.HoveredItemId = nil
                    Store.SetView({ selectedItemId = clickedId })
                    if refs.Viewport then
                        InventoryController.MountViewportPreview(refs.Viewport, clickedId)
                    end
                    Inventory.RefreshAll()
                end
            end,
        })
    end
end

function Inventory.RefreshGrid()
    local refs = Inventory.Refs
    local scroll = refs and refs.GridScroll
    if not scroll then
        return
    end
    for _, child in ipairs(scroll:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end

    local view = Store.GetView()
    if refs.SortBtnApi then
        refs.SortBtnApi:Update({
            label = I18n.Pick("XẾP: ", "SORT: ") .. I18n.GetSortLabel(view.inventorySort or "Rarity"),
        })
    end

    local items = InventoryController.GetFilteredInventory()
    local totalSlots = math.max(#items, 15)

    for i = 1, totalSlots do
        local entry = items[i]
        ItemSlot.Create(scroll, {
            name = string.format("Slot_%03d", i),
            itemId = entry and entry.itemId or nil,
            count = entry and entry.count or 0,
            upgrade = entry and entry.upgrade or 0,
            stars = entry and entry.stars or 0,
            diffDelta = entry and entry.diffDelta or nil,
            equipped = entry and entry.equipped or false,
            selected = entry and (view.selectedItemId == entry.itemId) or false,
            showSubStat = true,
            size = UDim2.fromOffset(92, 102),
            layoutOrder = i,
            zIndex = 6,
            onHover = function(isHovering, hoveredId)
                if isHovering and hoveredId then
                    Inventory.HoveredItemId = hoveredId
                    Inventory.RefreshTooltip(hoveredId)
                elseif not isHovering and Inventory.HoveredItemId == hoveredId then
                    Inventory.HoveredItemId = nil
                    Inventory.RefreshTooltip()
                end
            end,
            onSelect = function(clickedId)
                if clickedId then
                    Inventory.HoveredItemId = nil
                    Store.SetView({ selectedItemId = clickedId })
                    if refs.Viewport then
                        InventoryController.MountViewportPreview(refs.Viewport, clickedId)
                    end
                    Inventory.RefreshGrid()
                    Inventory.RefreshEquipmentSlots()
                end
            end,
        })
    end

    Inventory.RefreshTooltip()
end

function Inventory.RefreshTooltip(overrideItemId)
    local refs = Inventory.Refs
    if not refs or not refs.DetailTitleLabel then
        return
    end
    local colors = Theme.Colors
    local snap = Store.GetSnapshot()
    local view = Store.GetView()
    local inspectId = overrideItemId or Inventory.HoveredItemId or view.selectedItemId

    for _, ch in ipairs(refs.DetailPreviewHolder:GetChildren()) do
        ch:Destroy()
    end
    for _, ch in ipairs(refs.DetailStarsHolder:GetChildren()) do
        ch:Destroy()
    end

    local cfg = inspectId and RarityConfig.GetItem(inspectId) or nil
    if not cfg then
        refs.CurrentInspectId = nil
        refs.CurrentInspectEquipped = false
        ItemSlot.Create(refs.DetailPreviewHolder, {
            name = "EmptyDetailCard",
            size = UDim2.fromOffset(96, 108),
            slotIcon = "Bag",
            slotLabel = "---",
            zIndex = 8,
        })
        refs.DetailTitleLabel.Text = I18n.Pick("Chọn một trang bị hoặc thần khí để soi chi tiết", "Select an item card to inspect stats & 3D model")
        refs.DetailRarityText.Text = "---"
        refs.DetailMetaLabel.Text = I18n.Pick("Kéo mô hình 3D bên trái để xoay 360 độ", "Drag the 3D paperdoll on the left to orbit 360 deg")
        refs.DetailStatsLabel.Text = ""
        refs.DetailPassiveLabel.Text = ""
        refs.EquipActionBtn.Visible = false
        refs.ForgeActionBtn.Visible = false
        return
    end

    local foundEntry = nil
    for _, entry in ipairs(snap.inventory or {}) do
        if entry.itemId == inspectId then
            foundEntry = entry
            break
        end
    end

    local eqMap = snap.equipped or snap.equipment or {}
    local isEq = (cfg.Slot and eqMap[cfg.Slot] == inspectId) or (foundEntry and foundEntry.equipped == true)
    local upg = foundEntry and (tonumber(foundEntry.upgrade) or 0) or 0
    local isWeaponOrGun = (cfg.Slot == "Weapon" or cfg.Slot == "Gun")
    local stars = isWeaponOrGun and Store.GetWeaponStar(inspectId) or 0
    local rarity = RarityConfig.GetRarity(cfg.Rarity)

    refs.CurrentInspectId = inspectId
    refs.CurrentInspectEquipped = isEq == true

    -- Vivid Glossy 96x108 Preview Card on Left of Detail Dock
    ItemSlot.Create(refs.DetailPreviewHolder, {
        name = "SelectedShowcaseCard",
        itemId = inspectId,
        count = foundEntry and foundEntry.count or 1,
        upgrade = upg,
        stars = stars,
        equipped = isEq,
        selected = true,
        showSubStat = true,
        size = UDim2.fromOffset(96, 108),
        zIndex = 8,
    })

    if stars > 0 then
        local pipRow = UIFactory.StarPipsRow(refs.DetailStarsHolder, stars, 5, {
            PipSize = 9,
            Gap = 5,
            ZIndex = 9,
        })
        pipRow.AnchorPoint = Vector2.new(0.5, 0.5)
        pipRow.Position = UDim2.fromScale(0.5, 0.5)
    end

    local dispName = I18n.GetItemDisplayName(inspectId, cfg.Name)
    refs.DetailTitleLabel.Text = (upg > 0) and string.format("%s  +%d", dispName, upg) or dispName
    refs.DetailTitleLabel.TextColor3 = rarity.BorderBright or rarity.Color or colors.TEXT_PRIMARY
    refs.DetailStroke.Color = rarity.BorderBright or rarity.Color or colors.ACCENT_GOLD_BRIGHT

    -- Vivid Glossy Rarity Pill Badge
    refs.DetailRarityGrad.Color = ColorSequence.new(
        rarity.CardTop or rarity.Color,
        rarity.CardBottom or colors.BG_900
    )
    refs.DetailRarityStroke.Color = rarity.BorderBright or rarity.Color
    local starPrefix = (stars > 0) and string.format("*%d ", stars) or ""
    refs.DetailRarityText.Text = string.upper(starPrefix .. I18n.GetRarityLabel(rarity.Id))
    refs.DetailRarityText.TextColor3 = (rarity.Tier == 5) and Color3.fromRGB(18, 16, 12) or Color3.fromRGB(252, 254, 255)

    local slotTxt = cfg.Slot and I18n.GetSlotLabel(cfg.Slot) or I18n.Pick("Nguyên Liệu / Vật Phẩm", "Material / Item")
    local lvReq = tonumber(cfg.LevelReq) or 1
    local qty = foundEntry and tonumber(foundEntry.count) or 1
    refs.DetailMetaLabel.Text = string.format(
        "%s   •   Lv. %d+   •   %s: x%d",
        slotTxt,
        lvReq,
        I18n.Pick("Sở hữu", "Owned"),
        qty
    )

    -- Scaled Stats + Automatic Green/Red Stat-Diff Comparison vs Equipped Gear
    local eqId, eqCfg, eqUpg, eqStars = nil, nil, 0, 1
    if cfg.Slot and not isEq then
        eqId, eqCfg, eqUpg, eqStars = InventoryController.GetEquippedInfoForSlot(cfg.Slot, snap)
    end
    local diffs = Tooltip.ComputeStatDiffs(cfg, upg, math.max(1, stars), eqCfg, eqUpg, eqStars)

    local statChunks = {}
    local diffChunks = {}
    for _, d in ipairs(diffs) do
        local label = STAT_NAMES_VI[d.stat] or tostring(d.stat)
        if d.value ~= 0 then
            local suffix = (d.stat == "CRIT" or d.stat == "CritRate" or d.stat == "CritDmg") and "%" or ""
            table.insert(statChunks, string.format("<b>+%s%s %s</b>", UIFactory.FormatNumber(d.value), suffix, label))
        end
        if cfg.Slot and not isEq and d.diff ~= 0 then
            if d.diff > 0 then
                table.insert(diffChunks, string.format("<font color='#34D399'><b>+%s %s</b></font>", UIFactory.FormatNumber(d.diff), label))
            else
                table.insert(diffChunks, string.format("<font color='#FB7185'><b>%s %s</b></font>", tostring(d.diff), label))
            end
        end
    end

    local statLine = (#statChunks > 0) and table.concat(statChunks, "  •  ") or I18n.Pick("Nguyên liệu chế tạo & đột phá Thần Khí 3D", "3D Forge crafting & ascension material")
    if cfg.Slot and isEq then
        statLine = statLine .. string.format("   |   <font color='#34D399'><b>[%s]</b></font>", I18n.Pick("ĐANG TRANG BỊ", "EQUIPPED"))
    elseif #diffChunks > 0 then
        local vsName = eqCfg and I18n.GetItemDisplayName(eqId, eqCfg.Name) or I18n.Pick("Ô trống", "Empty slot")
        statLine = statLine .. string.format("   |   <font color='#94A8C8'>%s %s:</font> %s", I18n.Pick("So với", "Vs"), vsName, table.concat(diffChunks, " "))
    end
    refs.DetailStatsLabel.Text = statLine

    local loreText = tostring(cfg.Passive or cfg.Description or "")
    refs.DetailPassiveLabel.Text = loreText

    if cfg.Slot then
        refs.EquipActionBtn.Visible = true
        refs.EquipActionApi:Update({
            label = isEq and I18n.Pick("THÁO TRANG BỊ", "UNEQUIP") or I18n.Pick("TRANG BỊ NGAY", "EQUIP NOW"),
            variant = isEq and "secondary" or "primary",
        })
        refs.ForgeActionBtn.Visible = true
    else
        refs.EquipActionBtn.Visible = false
        refs.ForgeActionBtn.Visible = true
    end
end

function Inventory.RefreshAll()
    Inventory.RefreshStats()
    Inventory.RefreshEquipmentSlots()
    Inventory.RefreshGrid()
    if Inventory.Refs and Inventory.Refs.Viewport then
        InventoryController.MountViewportPreview(Inventory.Refs.Viewport, Store.GetView().selectedItemId)
    end
end

function Inventory.Update()
    if Inventory.Refs and Inventory.Refs.Root then
        Inventory.RefreshAll()
    end
end

function Inventory.Cleanup()
    Inventory.HoveredItemId = nil
    InventoryController.CleanupViewport()
    Inventory.Refs = {}
end

return Inventory
