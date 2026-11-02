-- SKYBREAK: Fragments of the Core — Boundary-Safe Item & Stat Comparison Tooltip
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Components/Tooltip.lua
-- Includes automatic Stat Comparison Diff Badges (▲ +ATK green, ▼ -DEF red, = +0 gold) (#97).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local RarityConfig = require(Shared:WaitForChild("Config"):WaitForChild("RarityConfig"))
local WorldConfig = require(Shared:WaitForChild("Config"):WaitForChild("WorldConfig"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Responsive = require(script.Parent.Parent:WaitForChild("Responsive"))
local I18n = require(script.Parent.Parent:WaitForChild("I18n"))
local PremiumButton = require(script.Parent:WaitForChild("PremiumButton"))

local Tooltip = {}

local STAT_ORDER = { "ATK", "DEF", "HP", "CritRate", "CritDmg", "Break", "SPD" }

local function computeScaledStats(itemCfg, upgradeLevel, stars)
    local out = {}
    if not itemCfg or type(itemCfg.Stats) ~= "table" then
        return out
    end
    local rarity = RarityConfig.GetRarity(itemCfg.Rarity)
    local upg = tonumber(upgradeLevel) or 0
    local st = math.max(1, tonumber(stars) or 1)
    local mult = (1 + upg * (rarity.UpgradeMultiplier or 0.08)) * (1 + (st - 1) * 0.06)
    for k, v in pairs(itemCfg.Stats) do
        out[k] = math.floor((tonumber(v) or 0) * mult + 0.5)
    end
    return out
end

function Tooltip.ComputeStatDiffs(itemCfg, upgrade, stars, equippedCfg, eqUpgrade, eqStars)
    local myStats = computeScaledStats(itemCfg, upgrade, stars)
    local eqStats = computeScaledStats(equippedCfg, eqUpgrade, eqStars)
    local seen = {}
    local keys = {}

    for _, k in ipairs(STAT_ORDER) do
        if myStats[k] ~= nil or eqStats[k] ~= nil then
            seen[k] = true
            table.insert(keys, k)
        end
    end
    for k in pairs(myStats) do
        if not seen[k] then
            seen[k] = true
            table.insert(keys, k)
        end
    end
    for k in pairs(eqStats) do
        if not seen[k] then
            seen[k] = true
            table.insert(keys, k)
        end
    end

    local diffs = {}
    for _, k in ipairs(keys) do
        local cur = myStats[k] or 0
        local base = eqStats[k] or 0
        table.insert(diffs, {
            stat = k,
            value = cur,
            equippedValue = base,
            diff = cur - base,
        })
    end
    return diffs
end

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
        Text = I18n.Pick("Chọn Vật Phẩm", "Select an Item"),
        Position = UDim2.fromOffset(16, 10),
        Size = UDim2.new(1, -130, 0, 22),
        TextSize = 16,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = card.ZIndex + 2,
    })

    local rarityBadge = UIFactory.Badge(
        card,
        "COMMON",
        UDim2.new(1, -110, 0, 10),
        UDim2.fromOffset(94, 22),
        colors.STROKE_STEEL,
        colors.TEXT_PRIMARY
    )

    local metaLabel = UIFactory.Label(card, {
        Name = "Meta",
        Text = "",
        Position = UDim2.fromOffset(16, 33),
        Size = UDim2.new(1, -172, 0, 16),
        TextSize = 11,
        TextColor = colors.TEXT_SECONDARY,
        Weight = "Medium",
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = card.ZIndex + 2,
    })

    -- #97 Dedicated Stat Comparison Diff Badges Strip
    local diffRow = UIFactory.Create("Frame", card, {
        Name = "StatDiffBadgesRow",
        Position = UDim2.fromOffset(16, 52),
        Size = UDim2.new(1, -176, 0, 22),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = card.ZIndex + 3,
    })
    UIFactory.ListLayout(diffRow, Enum.FillDirection.Horizontal, 5, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    local statsLabel = UIFactory.Label(card, {
        Name = "StatsText",
        Text = "",
        Position = UDim2.fromOffset(16, 76),
        Size = UDim2.new(1, -180, 1, -84),
        TextSize = 12,
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
        position = UDim2.new(1, -154, 1, -92),
        size = UDim2.fromOffset(138, 36),
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
        position = UDim2.new(1, -154, 1, -48),
        size = UDim2.fromOffset(138, 34),
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

        for _, ch in ipairs(diffRow:GetChildren()) do
            if not ch:IsA("UIListLayout") then
                ch:Destroy()
            end
        end

        if not item then
            titleLabel.Text = I18n.Pick("CHỌN VẬT PHẨM", "SELECT AN ITEM")
            titleLabel.TextColor3 = colors.TEXT_PRIMARY
            metaLabel.Text = I18n.Pick("Chọn một ô trang bị để xem chỉ số và so sánh.", "Select an item slot to inspect stats and compare gear.")
            diffRow.Visible = false
            statsLabel.Text = ""
            equipBtn.Visible = false
            compareBtn.Visible = false
            return
        end

        local rarity = RarityConfig.GetRarity(item.Rarity)
        local upgrade = tonumber(data.upgrade) or 0
        local stars = tonumber(data.stars) or 1
        local count = tonumber(data.count) or 0
        isEquipped = data.equipped == true

        local starSuffix = (item.Slot == "Weapon" or item.Slot == "Gun") and (" • *" .. tostring(stars)) or ""
        local dispName = I18n.GetItemDisplayName(currentItemId, item.Name)
        titleLabel.Text = dispName .. (upgrade > 0 and (" +" .. upgrade) or "") .. starSuffix
        titleLabel.TextColor3 = rarity.Color
        stroke.Color = rarity.Color

        local badgeText = rarityBadge:FindFirstChild("BadgeText")
        if badgeText then
            badgeText.Text = I18n.GetRarityLabel(rarity.Id or item.Rarity)
            badgeText.TextColor3 = rarity.Color
        end

        local classReqText = I18n.Pick("Mọi Hệ Phái", "All Classes")
        if item.ClassId and WorldConfig.Classes[item.ClassId] then
            classReqText = WorldConfig.Classes[item.ClassId].Name
        end
        metaLabel.Text = string.format(
            "%s  •  Lv. %d+  •  %s  •  x%d",
            I18n.GetSlotLabel(item.Slot or item.Category or "Item"),
            item.LevelReq or 1,
            classReqText,
            count
        )

        local compareTarget = data.compareItem or data.equippedInSlotItem
        local eqUpgrade = tonumber(data.equippedUpgrade) or 0
        local eqStars = tonumber(data.equippedStars) or 1
        local showDiffBadges = (not isEquipped) and (item.Slot ~= nil) and (compareTarget ~= nil or (item.Stats and next(item.Stats) ~= nil))

        local diffs = Tooltip.ComputeStatDiffs(item, upgrade, stars, compareTarget, eqUpgrade, eqStars)

        if showDiffBadges and #diffs > 0 then
            diffRow.Visible = true
            statsLabel.Position = UDim2.fromOffset(16, 78)
            statsLabel.Size = UDim2.new(1, -180, 1, -86)

            local vsTag = UIFactory.Label(diffRow, {
                Name = "VsTag",
                Text = I18n.T("inv.vs_equipped") .. ":",
                Size = UDim2.fromOffset(0, 20),
                TextSize = 10,
                TextColor = colors.TEXT_MUTED,
                Bold = true,
                Wrapped = false,
                LayoutOrder = 0,
                ZIndex = diffRow.ZIndex + 1,
            })
            vsTag.AutomaticSize = Enum.AutomaticSize.X

            for idx, d in ipairs(diffs) do
                if idx <= 4 then
                    local bCol = colors.ACCENT_GOLD
                    local bTxt = string.format("= +0 %s", d.stat)
                    if d.diff > 0 then
                        bCol = colors.SUCCESS
                        bTxt = string.format("▲ +%d %s", d.diff, d.stat)
                    elseif d.diff < 0 then
                        bCol = colors.HP_RED
                        bTxt = string.format("▼ %d %s", d.diff, d.stat)
                    end
                    local pill = UIFactory.Create("Frame", diffRow, {
                        Name = "Diff_" .. d.stat,
                        Size = UDim2.fromOffset(0, 20),
                        AutomaticSize = Enum.AutomaticSize.X,
                        BackgroundColor3 = bCol:Lerp(colors.BG_900, 0.78),
                        BorderSizePixel = 0,
                        LayoutOrder = idx,
                        ZIndex = diffRow.ZIndex + 1,
                    })
                    UIFactory.Corner(pill, 4)
                    UIFactory.Stroke(pill, bCol, 1, 0.25)
                    UIFactory.Padding(pill, 0, 6, 0, 6)
                    local lbl = UIFactory.Label(pill, {
                        Name = "Txt",
                        Text = bTxt,
                        Size = UDim2.fromOffset(0, 20),
                        TextSize = 11,
                        TextColor = bCol,
                        Bold = true,
                        Wrapped = false,
                        ZIndex = pill.ZIndex + 1,
                    })
                    lbl.AutomaticSize = Enum.AutomaticSize.X
                end
            end
        else
            diffRow.Visible = false
            statsLabel.Position = UDim2.fromOffset(16, 56)
            statsLabel.Size = UDim2.new(1, -180, 1, -64)
        end

        local lines = {}
        if #diffs > 0 then
            local statTokens = {}
            for _, d in ipairs(diffs) do
                local deltaRich = ""
                if showDiffBadges or ((not isEquipped) and data.compareMode) then
                    if d.diff > 0 then
                        deltaRich = string.format(" <font color='#5ED79E'>(▲ +%d)</font>", d.diff)
                    elseif d.diff < 0 then
                        deltaRich = string.format(" <font color='#EF5262'>(▼ %d)</font>", d.diff)
                    else
                        deltaRich = " <font color='#E4B863'>(= +0)</font>"
                    end
                end
                table.insert(statTokens, string.format("<b>%s</b> +%d%s", d.stat, d.value, deltaRich))
            end
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
                label = isEquipped and I18n.Pick("THÁO RA", "UNEQUIP") or I18n.Pick("TRANG BỊ", "EQUIP"),
                variant = isEquipped and "secondary" or "primary",
            })
            compareApi:Update({
                label = data.compareMode and I18n.Pick("ẨN SO SÁNH", "HIDE COMPARE") or I18n.Pick("SO SÁNH", "COMPARE"),
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
