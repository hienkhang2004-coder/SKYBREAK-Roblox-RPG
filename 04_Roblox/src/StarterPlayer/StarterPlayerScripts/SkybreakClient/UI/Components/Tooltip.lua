-- SKYBREAK: Fragments of the Core — Boundary-Safe Item & Stat Comparison Tooltip
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Components/Tooltip.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local RarityConfig = require(Shared:WaitForChild("Config"):WaitForChild("RarityConfig"))
local WorldConfig = require(Shared:WaitForChild("Config"):WaitForChild("WorldConfig"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Responsive = require(script.Parent.Parent:WaitForChild("Responsive"))
local PremiumButton = require(script.Parent:WaitForChild("PremiumButton"))

local Tooltip = {}

function Tooltip.Create(parent, props)
    props = props or {}
    local colors = Theme.Colors

    local card = UIFactory.Create("Frame", parent, {
        Name = props.name or "ItemTooltip",
        Position = props.position or UDim2.fromOffset(0, 0),
        Size = props.size or UDim2.fromScale(1, 1),
        BackgroundColor3 = colors.BG_800,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        ZIndex = props.zIndex or 8,
    })
    UIFactory.Corner(card, Theme.Radius.Large)
    local stroke = UIFactory.Stroke(card, colors.STROKE_STEEL, 1.5, 0.2)
    UIFactory.Gradient(card, colors.BG_700, colors.BG_900, 90)

    local titleLabel = UIFactory.Label(card, {
        Name = "Title",
        Text = "Select an Item",
        Position = UDim2.fromOffset(16, 12),
        Size = UDim2.new(1, -130, 0, 24),
        TextSize = 18,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
        ZIndex = card.ZIndex + 2,
    })

    local rarityBadge = UIFactory.Badge(
        card,
        "COMMON",
        UDim2.new(1, -110, 0, 12),
        UDim2.fromOffset(94, 22),
        colors.STROKE_STEEL,
        colors.TEXT_PRIMARY
    )

    local metaLabel = UIFactory.Label(card, {
        Name = "Meta",
        Text = "Click any slot in the grid to inspect stats and actions.",
        Position = UDim2.fromOffset(16, 38),
        Size = UDim2.new(1, -32, 0, 18),
        TextSize = 12,
        TextColor = colors.TEXT_SECONDARY,
        Weight = "Medium",
        ZIndex = card.ZIndex + 2,
    })

    local statsLabel = UIFactory.Label(card, {
        Name = "StatsText",
        Text = "",
        Position = UDim2.fromOffset(16, 60),
        Size = UDim2.new(1, -180, 1, -72),
        TextSize = 13,
        TextColor = colors.TEXT_PRIMARY,
        YAlign = Enum.TextYAlignment.Top,
        RichText = true,
        ZIndex = card.ZIndex + 2,
    })

    local currentItemId = nil
    local isEquipped = false

    local equipBtn, equipApi = PremiumButton.Create(card, {
        name = "EquipActionButton",
        label = "EQUIP",
        variant = "primary",
        position = UDim2.new(1, -156, 1, -96),
        size = UDim2.fromOffset(140, 38),
        zIndex = card.ZIndex + 3,
        onActivated = function()
            if currentItemId and type(props.onEquipToggle) == "function" then
                props.onEquipToggle(currentItemId, isEquipped)
            end
        end,
    })

    local compareBtn, compareApi = PremiumButton.Create(card, {
        name = "CompareActionButton",
        label = "COMPARE",
        variant = "secondary",
        position = UDim2.new(1, -156, 1, -50),
        size = UDim2.fromOffset(140, 36),
        zIndex = card.ZIndex + 3,
        onActivated = function()
            if currentItemId and type(props.onCompareToggle) == "function" then
                props.onCompareToggle(currentItemId)
            end
        end,
    })

    local api = {
        Instance = card,
        EquipButton = equipBtn,
        CompareButton = compareBtn,
    }

    function api:ClampToScreen(anchorPosition, viewportSize)
        local absSize = card.AbsoluteSize
        local clamped = Responsive.ClampTooltipPosition(anchorPosition, absSize, viewportSize, 12)
        card.Position = UDim2.fromOffset(clamped.X, clamped.Y)
    end

    function api:Update(data)
        data = data or {}
        currentItemId = data.itemId
        local item = currentItemId and RarityConfig.GetItem(currentItemId) or nil
        if not item then
            titleLabel.Text = "SELECT AN ITEM"
            titleLabel.TextColor3 = colors.TEXT_PRIMARY
            metaLabel.Text = "Select an item slot to inspect stats, passive effects, and equipment requirements."
            statsLabel.Text = ""
            equipBtn.Visible = false
            compareBtn.Visible = false
            return
        end

        local rarity = RarityConfig.GetRarity(item.Rarity)
        local upgrade = tonumber(data.upgrade) or 0
        local count = tonumber(data.count) or 0
        isEquipped = data.equipped == true

        titleLabel.Text = item.Name .. (upgrade > 0 and (" +" .. upgrade) or "")
        titleLabel.TextColor3 = rarity.Color
        stroke.Color = rarity.Color

        local badgeText = rarityBadge:FindFirstChild("BadgeText")
        if badgeText then
            badgeText.Text = string.upper(rarity.DisplayName)
            badgeText.TextColor3 = rarity.Color
        end

        local classReqText = "All Classes"
        if item.ClassId and WorldConfig.Classes[item.ClassId] then
            classReqText = WorldConfig.Classes[item.ClassId].Name
        end
        metaLabel.Text = string.format(
            "%s  •  Lv. %d+  •  %s  •  Owned: %d",
            item.Slot or item.Category or "Item",
            item.LevelReq or 1,
            classReqText,
            count
        )

        local lines = {}
        if item.Stats and next(item.Stats) then
            local mult = 1 + (upgrade * (rarity.UpgradeMultiplier or 0.08))
            local statTokens = {}
            for k, v in pairs(item.Stats) do
                local scaled = math.floor(v * mult)
                local compareDelta = ""
                if data.compareItem and data.compareItem.Stats then
                    local baseOther = data.compareItem.Stats[k] or 0
                    local diff = scaled - baseOther
                    if diff > 0 then
                        compareDelta = string.format(" <font color='#5ED79E'>(+%d)</font>", diff)
                    elseif diff < 0 then
                        compareDelta = string.format(" <font color='#EF5262'>(%d)</font>", diff)
                    end
                end
                table.insert(statTokens, string.format("<b>%s</b> +%d%s", k, scaled, compareDelta))
            end
            table.sort(statTokens)
            table.insert(lines, table.concat(statTokens, "   •   "))
        end
        if item.Passive then
            table.insert(lines, "<font color='#E4B863'>" .. item.Passive .. "</font>")
        end
        if item.Description then
            table.insert(lines, item.Description)
        end

        statsLabel.Text = table.concat(lines, "\n")

        local canEquip = item.Slot ~= nil and count > 0
        equipBtn.Visible = canEquip
        compareBtn.Visible = canEquip
        if canEquip then
            equipApi:Update({
                label = isEquipped and "UNEQUIP" or "EQUIP",
                variant = isEquipped and "secondary" or "primary",
            })
            compareApi:Update({
                label = data.compareMode and "HIDE COMPARE" or "COMPARE",
                selected = data.compareMode == true,
            })
        end
    end

    function api:Destroy()
        equipApi:Destroy()
        compareApi:Destroy()
        if card and card.Parent then
            card:Destroy()
        end
    end

    return card, api
end

Tooltip.create = Tooltip.Create

return Tooltip
