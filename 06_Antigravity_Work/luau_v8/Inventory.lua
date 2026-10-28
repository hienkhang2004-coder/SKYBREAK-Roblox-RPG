-- SKYBREAK: Fragments of the Core — Inventory & 8-Slot Equipment Screen (Phase 3)
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/Inventory.lua
-- Structure: Left 25% Player Stats, Center 35% 3D ViewportFrame + 8 Equipment Slots, Right 40% Filter/Search/ScrollingGrid/Tooltip.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local RarityConfig = require(Shared:WaitForChild("Config"):WaitForChild("RarityConfig"))
local WorldConfig = require(Shared:WaitForChild("Config"):WaitForChild("WorldConfig"))
local UIState = require(Shared:WaitForChild("Types"):WaitForChild("UIState"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Store = require(script.Parent.Parent:WaitForChild("Store"))
local ScreenRouter = require(script.Parent.Parent:WaitForChild("ScreenRouter"))
local PremiumPanel = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumPanel"))
local PremiumButton = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumButton"))
local ItemSlot = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("ItemSlot"))
local Tooltip = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("Tooltip"))
local InventoryController = require(script.Parent.Parent:WaitForChild("Controllers"):WaitForChild("InventoryController"))

local Inventory = {
    Refs = {},
}

local function buildSubScreenHeader(parent, activeScreenId, titleText)
    local colors = Theme.Colors
    local snap = Store.GetSnapshot()

    local header = PremiumPanel.Create(parent, {
        name = "TopHeader",
        position = UDim2.fromOffset(20, 14),
        size = UDim2.new(1, -40, 0, 58),
    })

    UIFactory.Label(header, {
        Name = "Brand",
        Text = "SKY<font color='#F0F4FA'>BREAK</font>  •  " .. titleText,
        Position = UDim2.fromOffset(18, 0),
        Size = UDim2.fromOffset(310, 58),
        TextSize = 19,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
        RichText = true,
    })

    local tabsHolder = UIFactory.Create("Frame", header, {
        Name = "NavTabs",
        Position = UDim2.fromOffset(332, 9),
        Size = UDim2.new(1, -620, 0, 40),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(tabsHolder, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    local tabs = {
        { id = UIState.Screens.Inventory, label = "INVENTORY" },
        { id = UIState.Screens.Skills, label = "SKILLS" },
        { id = UIState.Screens.WorldMap, label = "WORLD MAP" },
        { id = UIState.Screens.QuestJournal, label = "QUESTS" },
        { id = UIState.Screens.Forge, label = "FORGE" },
        { id = UIState.Screens.Raid, label = "RAID" },
        { id = UIState.Screens.Settings, label = "SETTINGS" },
    }
    for idx, tab in ipairs(tabs) do
        PremiumButton.Create(tabsHolder, {
            name = tab.id .. "Tab",
            label = tab.label,
            variant = activeScreenId == tab.id and "primary" or "secondary",
            selected = activeScreenId == tab.id,
            size = UDim2.fromOffset(92, 36),
            textSize = 11,
            layoutOrder = idx,
            onActivated = function()
                ScreenRouter.Navigate(tab.id)
            end,
        })
    end

    UIFactory.Label(header, {
        Name = "CurrencySummary",
        Text = string.format("GOLD %s  •  SHARDS %s", UIFactory.FormatNumber(snap.currency.gold), UIFactory.FormatNumber(snap.currency.coreShards)),
        Position = UDim2.new(1, -280, 0, 0),
        Size = UDim2.fromOffset(220, 58),
        TextSize = 12,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
        XAlign = Enum.TextXAlignment.Right,
    })

    PremiumButton.Create(header, {
        name = "CloseButton",
        label = "×",
        variant = "secondary",
        position = UDim2.new(1, -50, 0, 10),
        size = UDim2.fromOffset(38, 38),
        textSize = 20,
        onActivated = function()
            ScreenRouter.Navigate(UIState.Screens.HUD)
        end,
    })

    return header
end

function Inventory.Build(parent, responsiveState)
    Inventory.Cleanup()
    local colors = Theme.Colors
    local snap = Store.GetSnapshot()
    local view = Store.GetView()

    local root = UIFactory.Create("Frame", parent, {
        Name = "InventoryScreen",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 2,
    })

    buildSubScreenHeader(root, UIState.Screens.Inventory, "INVENTORY & EQUIPMENT")

    -- Column 1 (Left 25%): Player Combat Stats & Attributes
    local leftPanel = PremiumPanel.Create(root, {
        name = "PlayerStats",
        title = "CHARACTER ATTRIBUTES",
        subtitle = "Server-calculated class & gear stats",
        position = UDim2.fromOffset(20, 84),
        size = UDim2.new(0.24, -16, 1, -102),
    })

    local classCfg = WorldConfig.Classes[snap.player.classId] or WorldConfig.Classes.SkyGuardian
    local statsLabel = UIFactory.Label(leftPanel, {
        Name = "StatsBody",
        Text = "",
        Position = UDim2.fromOffset(16, 70),
        Size = UDim2.new(1, -32, 1, -140),
        TextSize = 14,
        TextColor = colors.TEXT_PRIMARY,
        YAlign = Enum.TextYAlignment.Top,
        RichText = true,
    })

    PremiumButton.Create(leftPanel, {
        name = "OpenForgeShortcut",
        label = "⚒  KAEL'S FORGE",
        variant = "gold",
        position = UDim2.new(0, 16, 1, -56),
        size = UDim2.new(1, -32, 0, 40),
        textSize = 13,
        onActivated = function()
            ScreenRouter.Navigate(UIState.Screens.Forge)
        end,
    })

    -- Column 2 (Center 34%): 3D ViewportFrame Avatar Preview + 8 Equipment Slots
    local centerPanel = PremiumPanel.Create(root, {
        name = "EquipmentPreview",
        title = "3D AVATAR & 8 EQUIPMENT SLOTS",
        subtitle = classCfg.Name .. "  •  " .. (snap.player.gender or "Male"),
        position = UDim2.new(0.24, 12, 0, 84),
        size = UDim2.new(0.35, -16, 1, -102),
    })

    local viewport = UIFactory.Create("ViewportFrame", centerPanel, {
        Name = "CharacterPreview",
        Position = UDim2.new(0.5, -110, 0, 72),
        Size = UDim2.fromOffset(220, 340),
        BackgroundColor3 = colors.BG_900,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        Ambient = Color3.fromRGB(185, 200, 224),
        LightColor = Color3.fromRGB(255, 236, 198),
        LightDirection = Vector3.new(-1, -1, -1),
    })
    UIFactory.Corner(viewport, Theme.Radius.Large)
    UIFactory.Stroke(viewport, colors.STROKE_STEEL, 1.2, 0.35)
    InventoryController.MountViewportPreview(viewport, viewport)

    -- Rotate Left / Right buttons for 3D Preview
    PremiumButton.Create(centerPanel, {
        name = "RotateLeft",
        label = "◄ ROTATE",
        variant = "secondary",
        position = UDim2.new(0.5, -110, 0, 420),
        size = UDim2.fromOffset(104, 34),
        textSize = 12,
        onActivated = function()
            InventoryController.UpdateCameraRotation(-math.rad(30))
        end,
    })
    PremiumButton.Create(centerPanel, {
        name = "RotateRight",
        label = "ROTATE ►",
        variant = "secondary",
        position = UDim2.new(0.5, 6, 0, 420),
        size = UDim2.fromOffset(104, 34),
        textSize = 12,
        onActivated = function()
            InventoryController.UpdateCameraRotation(math.rad(30))
        end,
    })

    -- 8 Canonical Equipment Slots (4 on left side of Viewport, 4 on right side)
    local equipSlotContainer = UIFactory.Create("Frame", centerPanel, {
        Name = "EquipmentSlots",
        Position = UDim2.fromOffset(12, 72),
        Size = UDim2.new(1, -24, 0, 384),
        BackgroundTransparency = 1,
    })

    -- Column 3 (Right 41%): Search, Filter Tabs, Scrolling Item Grid & Tooltip Detail
    local rightPanel = PremiumPanel.Create(root, {
        name = "InventoryGrid",
        title = "CELESTIAL STORAGE",
        position = UDim2.new(0.59, 4, 0, 84),
        size = UDim2.new(0.41, -24, 0.62, -54),
    })

    local filterHolder = UIFactory.Create("Frame", rightPanel, {
        Name = "FilterTabs",
        Position = UDim2.fromOffset(14, 48),
        Size = UDim2.new(1, -28, 0, 32),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(filterHolder, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    local filters = { "All", "Weapons", "Armor", "Materials", "Quest" }
    for idx, fName in ipairs(filters) do
        PremiumButton.Create(filterHolder, {
            name = "Filter_" .. fName,
            label = string.upper(fName),
            variant = (view.inventoryFilter == fName) and "primary" or "secondary",
            selected = (view.inventoryFilter == fName),
            size = UDim2.fromOffset(86, 30),
            textSize = 11,
            layoutOrder = idx,
            onActivated = function()
                Store.SetView({ inventoryFilter = fName })
                Inventory.RefreshGrid()
            end,
        })
    end

    local searchBox = UIFactory.Create("TextBox", rightPanel, {
        Name = "Search",
        Position = UDim2.fromOffset(14, 86),
        Size = UDim2.new(0.68, -18, 0, 32),
        Text = view.searchQuery or "",
        PlaceholderText = "Search items by name or rarity...",
        Font = Theme.Fonts.Regular,
        TextSize = 13,
        TextColor3 = colors.TEXT_PRIMARY,
        PlaceholderColor3 = colors.TEXT_SECONDARY,
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    UIFactory.Corner(searchBox, Theme.Radius.Small)
    UIFactory.Stroke(searchBox, colors.STROKE_STEEL, 1, 0.35)
    UIFactory.Padding(searchBox, 0, 10, 0, 10)

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        Store.SetView({ searchQuery = searchBox.Text })
        Inventory.RefreshGrid()
    end)

    -- Sort Selector Button
    local sortModes = { "Rarity", "Level", "Name" }
    local _, sortBtnApi = PremiumButton.Create(rightPanel, {
        name = "SortButton",
        label = "SORT: " .. string.upper(view.inventorySort or "Rarity"),
        variant = "secondary",
        position = UDim2.new(0.68, 4, 0, 86),
        size = UDim2.new(0.32, -18, 0, 32),
        textSize = 11,
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

    local gridScroll = UIFactory.Create("ScrollingFrame", rightPanel, {
        Name = "Slots",
        Position = UDim2.fromOffset(14, 126),
        Size = UDim2.new(1, -28, 1, -138),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 5,
        ScrollBarImageColor3 = colors.ACCENT_SAPPHIRE,
        CanvasSize = UDim2.fromOffset(0, 0),
    })

    -- Bottom-Right Item Tooltip & Compare Card
    local _, tooltipApi = Tooltip.Create(root, {
        name = "ItemTooltip",
        position = UDim2.new(0.59, 4, 0.62, 38),
        size = UDim2.new(0.41, -24, 0.38, -56),
        onEquipToggle = function(itemId, isEq)
            InventoryController.RequestEquipToggle(itemId, isEq)
        end,
        onCompareToggle = function()
            local v = Store.GetView()
            Store.SetView({ compareMode = not v.compareMode })
            Inventory.RefreshTooltip()
        end,
    })

    Inventory.Refs = {
        Root = root,
        StatsLabel = statsLabel,
        EquipSlotContainer = equipSlotContainer,
        GridScroll = gridScroll,
        SortBtnApi = sortBtnApi,
        TooltipApi = tooltipApi,
    }

    Inventory.RefreshAll()
    return root
end

function Inventory.RefreshStats()
    local refs = Inventory.Refs
    if not refs.StatsLabel then
        return
    end
    local snap = Store.GetSnapshot()
    local classCfg = WorldConfig.Classes[snap.player.classId] or WorldConfig.Classes.SkyGuardian
    local lvl = snap.player.level or 1
    local mult = classCfg.BaseMultipliers or { HP = 1, ATK = 1, DEF = 1, Speed = 18 }

    local totalHP = math.floor((120 + 18 * (lvl - 1)) * mult.HP)
    local totalATK = math.floor((12 + 2 * (lvl - 1)) * mult.ATK)
    local totalDEF = math.floor((4 + lvl - 1) * mult.DEF)
    local totalCRIT = 5

    for _, itemId in pairs(snap.equipped or {}) do
        local cfg = RarityConfig.GetItem(itemId)
        if cfg and cfg.Stats then
            totalHP += (cfg.Stats.HP or 0)
            totalATK += (cfg.Stats.ATK or 0)
            totalDEF += (cfg.Stats.DEF or 0)
            totalCRIT += (cfg.Stats.CRIT or 0)
        end
    end
    if not snap.isDemoMode then
        totalHP = snap.vitals.maxHp or totalHP
        totalATK = snap.player.atk or totalATK
        totalDEF = snap.player.def or totalDEF
        totalCRIT = snap.player.critRate or totalCRIT
    end

    refs.StatsLabel.Text = string.format(
        "<font color='#E4B863'><b>%s  •  Lv. %d</b></font>\n%s\n\n"
            .. "<b>MAX HP</b>         %s\n"
            .. "<b>ATTACK</b>         %s\n"
            .. "<b>DEFENSE</b>        %s\n"
            .. "<b>CRIT RATE</b>      %d%%\n"
            .. "<b>MOVE SPEED</b>     %d\n"
            .. "<b>MAX ENERGY</b>     %d\n\n"
            .. "<font color='#A8B9D1'><b>CURRENCIES</b></font>\n"
            .. "Gold: <b>%s</b>\nCore Shards: <b>%s</b>\nVoid Essence: <b>%s</b>",
        string.upper(classCfg.Name),
        lvl,
        classCfg.Role,
        UIFactory.FormatNumber(totalHP),
        UIFactory.FormatNumber(totalATK),
        UIFactory.FormatNumber(totalDEF),
        totalCRIT,
        mult.Speed or 18,
        snap.vitals.maxEnergy or 100,
        UIFactory.FormatNumber(snap.currency.gold),
        UIFactory.FormatNumber(snap.currency.coreShards),
        UIFactory.FormatNumber(snap.currency.voidEssence)
    )
end

function Inventory.RefreshEquipmentSlots()
    local refs = Inventory.Refs
    local holder = refs.EquipSlotContainer
    if not holder then
        return
    end
    for _, child in ipairs(holder:GetChildren()) do
        child:Destroy()
    end

    local snap = Store.GetSnapshot()
    local view = Store.GetView()

    for idx, slotDef in ipairs(RarityConfig.EquipmentSlots) do
        local isLeft = idx <= 4
        local row = ((idx - 1) % 4)
        local pos = isLeft and UDim2.fromOffset(4, row * 94) or UDim2.new(1, -86, 0, row * 94)
        local equippedItemId = snap.equipped and snap.equipped[slotDef.Id] or nil

        ItemSlot.Create(holder, {
            name = "EquipSlot_" .. slotDef.Id,
            itemId = equippedItemId,
            slotLabel = slotDef.Name,
            equipped = equippedItemId ~= nil,
            selected = equippedItemId ~= nil and view.selectedItemId == equippedItemId,
            position = pos,
            size = UDim2.fromOffset(82, 82),
            onSelect = function(clickedId)
                if clickedId then
                    Store.SetView({ selectedItemId = clickedId })
                    Inventory.RefreshAll()
                end
            end,
        })
    end
end

function Inventory.RefreshGrid()
    local refs = Inventory.Refs
    local scroll = refs.GridScroll
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
        refs.SortBtnApi:Update({ label = "SORT: " .. string.upper(view.inventorySort or "Rarity") })
    end

    local items = InventoryController.GetFilteredInventory()
    local cols = 5
    local cell = 84
    local gap = 8
    local totalSlots = math.max(#items, cols * 3)

    for i = 1, totalSlots do
        local entry = items[i]
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        ItemSlot.Create(scroll, {
            name = "Slot" .. i,
            itemId = entry and entry.itemId or nil,
            count = entry and entry.count or 0,
            upgrade = entry and entry.upgrade or 0,
            equipped = entry and entry.equipped or false,
            selected = entry and (view.selectedItemId == entry.itemId) or false,
            position = UDim2.fromOffset(col * (cell + gap), row * (cell + gap)),
            size = UDim2.fromOffset(cell, cell),
            onSelect = function(clickedId)
                if clickedId then
                    Store.SetView({ selectedItemId = clickedId })
                    Inventory.RefreshGrid()
                    Inventory.RefreshTooltip()
                end
            end,
        })
    end

    local rows = math.ceil(totalSlots / cols)
    scroll.CanvasSize = UDim2.fromOffset(0, rows * (cell + gap) + 8)
    Inventory.RefreshTooltip()
end

function Inventory.RefreshTooltip()
    local refs = Inventory.Refs
    if not refs.TooltipApi then
        return
    end
    local snap = Store.GetSnapshot()
    local view = Store.GetView()
    local selectedId = view.selectedItemId

    local foundEntry = nil
    for _, entry in ipairs(snap.inventory or {}) do
        if entry.itemId == selectedId then
            foundEntry = entry
            break
        end
    end

    local cfg = selectedId and RarityConfig.GetItem(selectedId) or nil
    local compareItem = nil
    if view.compareMode and cfg and cfg.Slot and snap.equipped then
        local eqId = snap.equipped[cfg.Slot]
        if eqId and eqId ~= selectedId then
            compareItem = RarityConfig.GetItem(eqId)
        end
    end

    refs.TooltipApi:Update({
        itemId = selectedId,
        count = foundEntry and foundEntry.count or 0,
        upgrade = foundEntry and foundEntry.upgrade or 0,
        equipped = (cfg and cfg.Slot and snap.equipped and snap.equipped[cfg.Slot] == selectedId) or (foundEntry and foundEntry.equipped == true),
        compareMode = view.compareMode == true,
        compareItem = compareItem,
    })
end

function Inventory.RefreshAll()
    Inventory.RefreshStats()
    Inventory.RefreshEquipmentSlots()
    Inventory.RefreshGrid()
end

function Inventory.Update()
    if Inventory.Refs.Root then
        Inventory.RefreshAll()
    end
end

function Inventory.Cleanup()
    InventoryController.CleanupViewport()
    Inventory.Refs = {}
end

return Inventory
