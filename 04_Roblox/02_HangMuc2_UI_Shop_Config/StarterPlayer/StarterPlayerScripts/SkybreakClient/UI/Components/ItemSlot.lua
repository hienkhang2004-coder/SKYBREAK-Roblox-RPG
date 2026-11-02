-- SKYBREAK: Fragments of the Core — 6-Layer Vivid Glossy Figblox/Figma Rarity Card Component
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Components/ItemSlot.lua
-- Matches SKYBREAK_Figma_v2_03_Design_System.png & SKYBREAK_3DBible_05_Paperdoll_And_Forge.png 1:1.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local RarityConfig = require(Shared:WaitForChild("Config"):WaitForChild("RarityConfig"))
local UIAnimator = require(Shared:WaitForChild("UIAnimator"))
local MotionTokens = require(Shared:WaitForChild("MotionTokens"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local I18n = require(script.Parent.Parent:WaitForChild("I18n"))

local ItemSlot = {}

local function formatPrimaryStatLine(itemCfg, upgrade, stars)
    if not itemCfg or type(itemCfg.Stats) ~= "table" then
        return nil
    end
    local rarity = RarityConfig.GetRarity(itemCfg.Rarity)
    local upg = math.max(0, tonumber(upgrade) or 0)
    local st = math.max(1, tonumber(stars) or 1)
    local mult = (1 + upg * (rarity.UpgradeMultiplier or 0.08)) * (1 + (st - 1) * 0.06)

    for _, key in ipairs({ "ATK", "HP", "DEF", "CRIT", "ENERGY" }) do
        local raw = tonumber(itemCfg.Stats[key])
        if raw and raw > 0 then
            local scaled = math.floor(raw * mult + 0.5)
            local suffix = (key == "CRIT") and "% CRIT" or (" " .. key)
            return "+" .. tostring(scaled) .. suffix
        end
    end
    return nil
end

function ItemSlot.Create(parent, props)
    props = props or {}
    local colors = Theme.Colors
    local itemId = props.itemId
    local itemCfg = props.customItem or (itemId and RarityConfig.GetItem(itemId)) or nil
    local rarityId = props.rarity or (itemCfg and itemCfg.Rarity) or "Common"
    local rarity = RarityConfig.GetRarity(rarityId)
    local isSelected = props.selected == true
    local isEquipped = props.equipped == true
    local count = tonumber(props.count) or 0
    local upgrade = tonumber(props.upgrade) or 0
    local stars = tonumber(props.stars) or 0
    local diffDelta = props.diffDelta

    local slotSize = props.size or UDim2.fromOffset(88, 96)
    local slotH = (slotSize.Y.Offset > 0) and slotSize.Y.Offset or 96
    local isTallCard = slotH >= 92
    local isCompactCard = slotH < 80

    local slotBtn = UIFactory.Create("TextButton", parent, {
        Name = props.name or ("ItemSlot_" .. tostring(itemId or "Empty")),
        AnchorPoint = props.anchorPoint or Vector2.zero,
        Position = props.position or UDim2.fromOffset(0, 0),
        Size = slotSize,
        Text = "",
        BackgroundColor3 = itemCfg and Color3.new(1, 1, 1) or Color3.fromRGB(11, 18, 34),
        BackgroundTransparency = itemCfg and 0.02 or 0.18,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        LayoutOrder = props.layoutOrder or 0,
        ZIndex = props.zIndex or 5,
    })

    local uiScale = Instance.new("UIScale")
    uiScale.Name = "UIScale"
    uiScale.Scale = 1.0
    uiScale.Parent = slotBtn

    local stroke
    if itemCfg then
        -- 6-Layer Vivid Glossy Figblox/Figma Rarity Card
        local styled = UIFactory.ApplyRarityCardStyle(slotBtn, rarityId, {
            selected = isSelected,
            cornerRadius = isCompactCard and 8 or 10,
            transparency = 0.02,
            auraPosition = UDim2.fromScale(0.5, isTallCard and 0.39 or 0.41),
            auraSize = UDim2.fromScale(isCompactCard and 0.52 or 0.56, isCompactCard and 0.52 or 0.56),
        })
        stroke = styled.Stroke

        local footerH = isTallCard and 28 or (isCompactCard and 22 or 24)
        local iconSize = isCompactCard and 28 or (isTallCard and 38 or 34)
        local iconCenterY = isTallCard and 0.38 or 0.39

        -- Layer 5: Crisp Two-Tone Bright White/Cream Central Vector Icon
        local iconHolder = UIFactory.Icon(
            slotBtn,
            props.icon or itemCfg.Icon or "Sword",
            UDim2.new(0.5, -math.floor(iconSize * 0.5), iconCenterY, -math.floor(iconSize * 0.5)),
            iconSize,
            Color3.fromRGB(250, 252, 255)
        )
        iconHolder.ZIndex = slotBtn.ZIndex + 3

        -- Top-Left Dark Obsidian Pill (Slot header, *Star/+Upgrade, LV. X, or Rarity Tag)
        local topLeftText = props.topLeftTag
        if not topLeftText or topLeftText == "" then
            if props.slotHeaderTag and props.slotHeaderTag ~= "" then
                topLeftText = tostring(props.slotHeaderTag)
            else
                local parts = {}
                if stars > 0 then
                    table.insert(parts, "*" .. tostring(stars))
                end
                if upgrade > 0 then
                    table.insert(parts, "+" .. tostring(upgrade))
                end
                if #parts > 0 then
                    topLeftText = table.concat(parts, " ")
                elseif tonumber(itemCfg.LevelReq) and tonumber(itemCfg.LevelReq) > 1 then
                    topLeftText = "LV." .. tostring(itemCfg.LevelReq)
                else
                    topLeftText = rarity.ShortTag or string.upper(rarity.Id or "COMMON")
                end
            end
        end

        if topLeftText and topLeftText ~= "" then
            local tlPill = UIFactory.Create("Frame", slotBtn, {
                Name = "TopLeftTagPill",
                Position = UDim2.fromOffset(4, 4),
                Size = UDim2.fromOffset(0, isCompactCard and 13 or 15),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = Color3.fromRGB(9, 13, 24),
                BackgroundTransparency = 0.10,
                BorderSizePixel = 0,
                ZIndex = slotBtn.ZIndex + 4,
            })
            UIFactory.Corner(tlPill, 4)
            UIFactory.Padding(tlPill, 0, 5, 0, 5)
            local tlText = UIFactory.Label(tlPill, {
                Name = "TagText",
                Text = topLeftText,
                Size = UDim2.fromOffset(0, isCompactCard and 13 or 15),
                TextSize = isCompactCard and 8 or 9,
                TextColor = (stars > 0 or upgrade > 0) and colors.ACCENT_GOLD_BRIGHT or Color3.fromRGB(238, 244, 255),
                Bold = true,
                Wrapped = false,
                ZIndex = slotBtn.ZIndex + 5,
            })
            tlText.AutomaticSize = Enum.AutomaticSize.X
        end

        -- Top-Right Dark Pill (Custom status tag, Stack count, EQ badge, or +StatDiff)
        local trText = nil
        local trTextCol = colors.TEXT_PRIMARY
        local trBgCol = Color3.fromRGB(9, 13, 24)
        local trStrokeCol = rarity.BorderBright or rarity.Color

        if props.topRightTag and props.topRightTag ~= "" then
            trText = tostring(props.topRightTag)
            trTextCol = props.topRightColor or Color3.fromRGB(110, 242, 190)
            trStrokeCol = trTextCol
        elseif isEquipped and not props.hideEquipBadge then
            trText = "EQ"
            trTextCol = colors.ACCENT_GOLD_BRIGHT
            trStrokeCol = colors.ACCENT_GOLD_BRIGHT
        elseif count > 1 then
            trText = "x" .. tostring(count)
            trTextCol = Color3.fromRGB(248, 252, 255)
            trStrokeCol = rarity.BorderBright or colors.STROKE_STEEL
        elseif type(diffDelta) == "number" then
            if diffDelta > 0 then
                trText = "+" .. tostring(diffDelta)
                trTextCol = Color3.fromRGB(94, 242, 162)
                trStrokeCol = Color3.fromRGB(52, 211, 153)
            elseif diffDelta < 0 then
                trText = tostring(diffDelta)
                trTextCol = Color3.fromRGB(255, 132, 148)
                trStrokeCol = colors.HP_RED
            else
                trText = "=0"
                trTextCol = colors.ACCENT_GOLD_BRIGHT
                trStrokeCol = colors.ACCENT_GOLD
            end
        end

        if trText then
            local trPill = UIFactory.Create("Frame", slotBtn, {
                Name = "TopRightPill",
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -4, 0, 4),
                Size = UDim2.fromOffset(0, isCompactCard and 13 or 15),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = trBgCol,
                BackgroundTransparency = 0.08,
                BorderSizePixel = 0,
                ZIndex = slotBtn.ZIndex + 4,
            })
            UIFactory.Corner(trPill, 4)
            UIFactory.Stroke(trPill, trStrokeCol, 1, 0.22)
            UIFactory.Padding(trPill, 0, 5, 0, 5)
            local trLbl = UIFactory.Label(trPill, {
                Name = "RightTagText",
                Text = trText,
                Size = UDim2.fromOffset(0, isCompactCard and 13 or 15),
                TextSize = isCompactCard and 8 or 9,
                TextColor = trTextCol,
                Bold = true,
                Wrapped = false,
                ZIndex = slotBtn.ZIndex + 5,
            })
            trLbl.AutomaticSize = Enum.AutomaticSize.X
        end

        -- Geometric Gold Diamond Star Pips Row directly above Obsidian Footer Bar (Zero Unicode tofu!)
        if props.hideStars ~= true then
            local visualStars = (stars > 0) and stars or math.clamp(math.floor((rarity.Tier or 1) + 0.5), 1, 5)
            UIFactory.StarPipsRow(slotBtn, {
                name = "RarityStarsRow",
                stars = visualStars,
                maxStars = visualStars,
                pipSize = isCompactCard and 3 or 4,
                gap = 2,
                position = UDim2.new(0, 6, 1, -(footerH + (isCompactCard and 10 or 12))),
                zIndex = slotBtn.ZIndex + 4,
            })
        end

        -- Layer 6: Dark Obsidian Footer Bar (#090D18, 0.12 transparency) with Bold Name + Optional Sub-Stat
        local footerBar = UIFactory.Create("Frame", slotBtn, {
            Name = "ObsidianFooterBar",
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 4, 1, -4),
            Size = UDim2.new(1, -8, 0, footerH),
            BackgroundColor3 = Color3.fromRGB(9, 13, 24),
            BackgroundTransparency = 0.12,
            BorderSizePixel = 0,
            ZIndex = slotBtn.ZIndex + 3,
        })
        UIFactory.Corner(footerBar, isCompactCard and 4 or 6)

        local dispName = props.customTitle or I18n.GetItemDisplayName(itemId, itemCfg.Name)
        local subLine = props.footerSubText
        if subLine == nil and (isTallCard or props.showSubStat == true) then
            subLine = formatPrimaryStatLine(itemCfg, upgrade, stars)
            if not subLine and isTallCard then
                subLine = I18n.GetRarityLabel(rarity.Id)
            end
        end

        if subLine and subLine ~= "" then
            UIFactory.Label(footerBar, {
                Name = "ItemName",
                Text = dispName,
                Position = UDim2.fromOffset(3, 1),
                Size = UDim2.new(1, -6, 0, isCompactCard and 11 or 14),
                TextSize = isCompactCard and 9 or 10,
                TextColor = Color3.fromRGB(248, 250, 255),
                Bold = true,
                XAlign = Enum.TextXAlignment.Center,
                Truncate = Enum.TextTruncate.AtEnd,
                Wrapped = false,
                ZIndex = slotBtn.ZIndex + 4,
            })
            UIFactory.Label(footerBar, {
                Name = "SubStat",
                Text = subLine,
                Position = UDim2.new(0, 3, 1, -(isCompactCard and 11 or 13)),
                Size = UDim2.new(1, -6, 0, isCompactCard and 10 or 12),
                TextSize = isCompactCard and 8 or 9,
                TextColor = props.footerSubColor or colors.ACCENT_GOLD_BRIGHT,
                Bold = true,
                XAlign = Enum.TextXAlignment.Center,
                Truncate = Enum.TextTruncate.AtEnd,
                Wrapped = false,
                ZIndex = slotBtn.ZIndex + 4,
            })
        else
            UIFactory.Label(footerBar, {
                Name = "ItemName",
                Text = dispName,
                Position = UDim2.fromOffset(3, 0),
                Size = UDim2.new(1, -6, 1, 0),
                TextSize = isCompactCard and 9 or 10,
                TextColor = Color3.fromRGB(248, 250, 255),
                Bold = true,
                XAlign = Enum.TextXAlignment.Center,
                Truncate = Enum.TextTruncate.AtEnd,
                Wrapped = false,
                ZIndex = slotBtn.ZIndex + 4,
            })
        end
    else
        -- Empty Recessed Obsidian Slot
        UIFactory.Corner(slotBtn, isCompactCard and 8 or 10)
        stroke = UIFactory.Stroke(slotBtn, colors.STROKE_STEEL, 1.3, 0.45)
        UIFactory.Gradient(slotBtn, Color3.fromRGB(16, 26, 46), Color3.fromRGB(8, 13, 25), 90)

        if props.slotHeaderTag and props.slotHeaderTag ~= "" then
            local tlPill = UIFactory.Create("Frame", slotBtn, {
                Name = "EmptyHeaderTag",
                Position = UDim2.fromOffset(4, 4),
                Size = UDim2.fromOffset(0, 13),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = Color3.fromRGB(9, 13, 24),
                BackgroundTransparency = 0.20,
                BorderSizePixel = 0,
                ZIndex = slotBtn.ZIndex + 2,
            })
            UIFactory.Corner(tlPill, 4)
            UIFactory.Padding(tlPill, 0, 5, 0, 5)
            local tlLbl = UIFactory.Label(tlPill, {
                Name = "TagText",
                Text = tostring(props.slotHeaderTag),
                Size = UDim2.fromOffset(0, 13),
                TextSize = 8,
                TextColor = colors.TEXT_MUTED,
                Bold = true,
                Wrapped = false,
                ZIndex = slotBtn.ZIndex + 3,
            })
            tlLbl.AutomaticSize = Enum.AutomaticSize.X
        end

        if props.slotIcon then
            local ghostIcon = UIFactory.Icon(
                slotBtn,
                props.slotIcon,
                UDim2.new(0.5, -13, 0.44, -13),
                26,
                Color3.fromRGB(58, 82, 118)
            )
            ghostIcon.ZIndex = slotBtn.ZIndex + 1
        end

        UIFactory.Label(slotBtn, {
            Name = "EmptySlotLabel",
            Text = props.slotLabel or "+",
            Position = props.slotIcon and UDim2.new(0, 4, 1, -20) or UDim2.fromScale(0, 0),
            Size = props.slotIcon and UDim2.new(1, -8, 0, 16) or UDim2.fromScale(1, 1),
            TextSize = props.slotLabel and 9 or 20,
            TextColor = Color3.fromRGB(88, 114, 152),
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            Truncate = Enum.TextTruncate.AtEnd,
            Wrapped = false,
            ZIndex = slotBtn.ZIndex + 2,
        })
    end

    local connections = {}
    table.insert(connections, slotBtn.MouseEnter:Connect(function()
        UIAnimator.Tween(uiScale, { Scale = 1.04 }, MotionTokens.hoverFast.duration)
        stroke.Color = colors.ACCENT_GOLD_BRIGHT
        stroke.Thickness = itemCfg and 2.6 or 1.6
        if type(props.onHover) == "function" then
            props.onHover(true, itemId, itemCfg)
        end
    end))

    table.insert(connections, slotBtn.MouseLeave:Connect(function()
        UIAnimator.Tween(uiScale, { Scale = 1.0 }, MotionTokens.hoverFast.duration)
        if itemCfg then
            stroke.Color = isSelected and colors.ACCENT_GOLD_BRIGHT or (rarity.BorderBright or rarity.Color)
            stroke.Thickness = isSelected and 2.6 or 2.0
        else
            stroke.Color = colors.STROKE_STEEL
            stroke.Thickness = 1.3
        end
        if type(props.onHover) == "function" then
            props.onHover(false, itemId, itemCfg)
        end
    end))

    table.insert(connections, slotBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            UIAnimator.Tween(uiScale, { Scale = 0.95 }, MotionTokens.press.duration)
        end
    end))

    table.insert(connections, slotBtn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            UIAnimator.Tween(uiScale, { Scale = 1.0 }, MotionTokens.rebound.duration, MotionTokens.rebound.style, MotionTokens.rebound.direction)
        end
    end))

    table.insert(connections, slotBtn.Activated:Connect(function()
        if type(props.onSelect) == "function" then
            props.onSelect(itemId, itemCfg)
        end
    end))

    local api = {
        Instance = slotBtn,
        Stroke = stroke,
        Scale = uiScale,
        ItemId = itemId,
    }

    function api:Update(newState)
        newState = newState or {}
        if newState.selected ~= nil then
            isSelected = newState.selected == true
            if itemCfg then
                stroke.Thickness = isSelected and 2.6 or 2.0
                stroke.Color = isSelected and colors.ACCENT_GOLD_BRIGHT or (rarity.BorderBright or rarity.Color)
            end
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
