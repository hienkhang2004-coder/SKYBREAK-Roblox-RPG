-- SKYBREAK: Fragments of the Core — Inventory & Equipment Item Slot Component
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Components/ItemSlot.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local RarityConfig = require(Shared:WaitForChild("Config"):WaitForChild("RarityConfig"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Animations = require(script.Parent.Parent:WaitForChild("Animations"))

local ItemSlot = {}

function ItemSlot.Create(parent, props)
    props = props or {}
    local itemId = props.itemId
    local itemCfg = itemId and RarityConfig.GetItem(itemId) or nil
    local rarityId = props.rarity or (itemCfg and itemCfg.Rarity) or "Common"
    local rarity = RarityConfig.GetRarity(rarityId)
    local isSelected = props.selected == true
    local isEquipped = props.equipped == true
    local count = tonumber(props.count) or 0
    local upgrade = tonumber(props.upgrade) or 0

    local slotBtn = UIFactory.Create("TextButton", parent, {
        Name = props.name or ("ItemSlot_" .. tostring(itemId or "Empty")),
        Position = props.position or UDim2.fromOffset(0, 0),
        Size = props.size or UDim2.fromOffset(86, 86),
        Text = "",
        BackgroundColor3 = itemCfg and rarity.BackgroundTint or Theme.Colors.BG_900,
        BackgroundTransparency = itemCfg and 0.08 or 0.25,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        LayoutOrder = props.layoutOrder or 0,
        ZIndex = props.zIndex or 5,
    })

    UIFactory.Corner(slotBtn, Theme.Radius.Slot)
    local stroke = UIFactory.Stroke(
        slotBtn,
        itemCfg and (isSelected and Theme.Colors.ACCENT_GOLD or rarity.Color) or Theme.Colors.STROKE_STEEL,
        isSelected and 2.4 or (itemCfg and 1.6 or 1),
        itemCfg and (isSelected and 0.02 or 0.18) or 0.52
    )

    if itemCfg then
        UIFactory.Icon(
            slotBtn,
            itemCfg.Icon or "Sword",
            UDim2.new(0.5, -18, 0.42, -18),
            36,
            rarity.Color
        )

        UIFactory.Label(slotBtn, {
            Name = "ItemName",
            Text = itemCfg.Name,
            Position = UDim2.new(0, 4, 1, -22),
            Size = UDim2.new(1, -8, 0, 18),
            TextSize = 11,
            TextColor = Theme.Colors.TEXT_PRIMARY,
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            Truncate = Enum.TextTruncate.AtEnd,
            Wrapped = false,
            ZIndex = slotBtn.ZIndex + 2,
        })

        if count > 1 then
            UIFactory.Label(slotBtn, {
                Name = "StackCount",
                Text = "x" .. tostring(count),
                Position = UDim2.new(0, 4, 0, 4),
                Size = UDim2.new(1, -8, 0, 16),
                TextSize = 12,
                TextColor = Theme.Colors.TEXT_PRIMARY,
                Bold = true,
                XAlign = Enum.TextXAlignment.Right,
                Wrapped = false,
                ZIndex = slotBtn.ZIndex + 3,
            })
        end

        if upgrade > 0 then
            UIFactory.Label(slotBtn, {
                Name = "UpgradeTier",
                Text = "+" .. tostring(upgrade),
                Position = UDim2.fromOffset(6, 4),
                Size = UDim2.fromOffset(32, 16),
                TextSize = 11,
                TextColor = Theme.Colors.ACCENT_GOLD,
                Bold = true,
                XAlign = Enum.TextXAlignment.Left,
                Wrapped = false,
                ZIndex = slotBtn.ZIndex + 3,
            })
        end

        if isEquipped then
            UIFactory.Badge(
                slotBtn,
                "EQ",
                UDim2.new(1, -30, 0, 4),
                UDim2.fromOffset(26, 16),
                Theme.Colors.ACCENT_GOLD,
                Theme.Colors.ACCENT_GOLD
            )
        end
    else
        UIFactory.Label(slotBtn, {
            Name = "EmptySlotLabel",
            Text = props.slotLabel or "+",
            Size = UDim2.fromScale(1, 1),
            TextSize = props.slotLabel and 10 or 24,
            TextColor = Theme.Colors.STROKE_STEEL,
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            ZIndex = slotBtn.ZIndex + 1,
        })
    end

    local connections = {}
    table.insert(connections, slotBtn.MouseEnter:Connect(function()
        Animations.Play(slotBtn, Theme.Motion.Hover, { BackgroundTransparency = 0 })
        stroke.Color = Theme.Colors.ACCENT_GOLD
    end))
    table.insert(connections, slotBtn.MouseLeave:Connect(function()
        Animations.Play(slotBtn, Theme.Motion.Hover, { BackgroundTransparency = itemCfg and 0.08 or 0.25 })
        stroke.Color = itemCfg and (isSelected and Theme.Colors.ACCENT_GOLD or rarity.Color) or Theme.Colors.STROKE_STEEL
    end))
    table.insert(connections, slotBtn.Activated:Connect(function()
        if type(props.onSelect) == "function" then
            props.onSelect(itemId, itemCfg)
        end
    end))

    local api = {
        Instance = slotBtn,
        Stroke = stroke,
        ItemId = itemId,
    }

    function api:Update(newState)
        newState = newState or {}
        if newState.selected ~= nil then
            isSelected = newState.selected == true
            stroke.Thickness = isSelected and 2.4 or 1.6
            stroke.Color = isSelected and Theme.Colors.ACCENT_GOLD or rarity.Color
        end
    end

    function api:Destroy()
        for _, c in ipairs(connections) do
            c:Disconnect()
        end
        table.clear(connections)
        if slotBtn and slotBtn.Parent then
            slotBtn:Destroy()
        end
    end

    return slotBtn, api
end

ItemSlot.create = ItemSlot.Create

return ItemSlot
