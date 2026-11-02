-- SKYBREAK: Fragments of the Core — Roblox GUI Primitive & Vector Icon Factory
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/UIFactory.lua
-- Rule: Pure presentation builder using real Roblox GUI instances and 100% procedural geometric vector icons (zero broken Unicode glyphs).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local RarityConfig = require(Shared:WaitForChild("Config"):WaitForChild("RarityConfig"))
local UIAssets = require(Shared:WaitForChild("Config"):WaitForChild("UIAssets"))
local UIState = require(Shared:WaitForChild("Types"):WaitForChild("UIState"))
local I18n = require(script.Parent:WaitForChild("I18n"))

local UIFactory = {}

function UIFactory.Create(className, parent, props)
    local inst = Instance.new(className)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            inst[k] = v
        end
    end
    if parent then
        inst.Parent = parent
    end
    return inst
end

function UIFactory.Corner(parent, radius)
    local r = radius
    if typeof(r) == "UDim" then
        return UIFactory.Create("UICorner", parent, {
            CornerRadius = r,
        })
    end
    return UIFactory.Create("UICorner", parent, {
        CornerRadius = UDim.new(0, tonumber(r) or Theme.Radius.Medium),
    })
end

function UIFactory.PillCorner(parent)
    return UIFactory.Create("UICorner", parent, {
        CornerRadius = UDim.new(0.5, 0),
    })
end

function UIFactory.Stroke(parent, color, thickness, transparency)
    return UIFactory.Create("UIStroke", parent, {
        Color = Theme.GetColor(color or Theme.Colors.STROKE_STEEL),
        Thickness = thickness or Theme.Stroke.Default,
        Transparency = transparency or Theme.Stroke.AlphaDefault,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

function UIFactory.Gradient(parent, topColor, bottomColor, rotation)
    return UIFactory.Create("UIGradient", parent, {
        Color = ColorSequence.new(
            Theme.GetColor(topColor or Theme.Colors.BG_700),
            Theme.GetColor(bottomColor or Theme.Colors.BG_900)
        ),
        Rotation = rotation or 90,
    })
end

function UIFactory.Padding(parent, top, right, bottom, left)
    local t = top or Theme.Spacing.M
    local r = right or t
    local b = bottom or t
    local l = left or r
    return UIFactory.Create("UIPadding", parent, {
        PaddingTop = UDim.new(0, t),
        PaddingRight = UDim.new(0, r),
        PaddingBottom = UDim.new(0, b),
        PaddingLeft = UDim.new(0, l),
    })
end

function UIFactory.ListLayout(parent, direction, padding, hAlign, vAlign)
    return UIFactory.Create("UIListLayout", parent, {
        FillDirection = direction or Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, padding or Theme.Spacing.S),
        HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left,
        VerticalAlignment = vAlign or Enum.VerticalAlignment.Top,
    })
end

function UIFactory.GridLayout(parent, cellSize, cellPadding, hAlign, vAlign)
    return UIFactory.Create("UIGridLayout", parent, {
        SortOrder = Enum.SortOrder.LayoutOrder,
        CellSize = cellSize or UDim2.fromOffset(84, 84),
        CellPadding = cellPadding or UDim2.fromOffset(8, 8),
        HorizontalAlignment = hAlign or Enum.HorizontalAlignment.Left,
        VerticalAlignment = vAlign or Enum.VerticalAlignment.Top,
    })
end

function UIFactory.SizeConstraint(parent, minSize, maxSize)
    return UIFactory.Create("UISizeConstraint", parent, {
        MinSize = minSize or Vector2.new(0, 0),
        MaxSize = maxSize or Vector2.new(math.huge, math.huge),
    })
end

function UIFactory.TextSizeConstraint(parent, minTextSize, maxTextSize)
    return UIFactory.Create("UITextSizeConstraint", parent, {
        MinTextSize = minTextSize or 11,
        MaxTextSize = maxTextSize or 15,
    })
end

function UIFactory.AspectRatio(parent, ratio)
    return UIFactory.Create("UIAspectRatioConstraint", parent, {
        AspectRatio = ratio or 1,
    })
end

function UIFactory.Label(parent, props)
    props = props or {}
    local weight = props.Weight or (props.Bold and "Bold" or "Regular")
    local font = props.Font or Theme.Fonts.Regular
    if not props.Font then
        if weight == "Bold" then
            font = Theme.Fonts.Bold
        elseif weight == "Medium" then
            font = Theme.Fonts.Medium
        end
    end

    return UIFactory.Create("TextLabel", parent, {
        Name = props.Name or "Label",
        Text = props.Text or "",
        Position = props.Position or UDim2.fromScale(0, 0),
        Size = props.Size or UDim2.fromScale(1, 1),
        AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
        BackgroundTransparency = 1,
        Font = font,
        TextSize = props.TextSize or Theme.Typography.Body.Size,
        TextColor3 = Theme.GetColor(props.TextColor or Theme.Colors.TEXT_PRIMARY),
        TextXAlignment = props.XAlign or Enum.TextXAlignment.Left,
        TextYAlignment = props.YAlign or Enum.TextYAlignment.Center,
        TextWrapped = props.Wrapped ~= false,
        TextScaled = props.TextScaled == true,
        TextTruncate = props.Truncate or Enum.TextTruncate.None,
        RichText = props.RichText == true,
        LayoutOrder = props.LayoutOrder or 0,
        ZIndex = props.ZIndex or 3,
    })
end

function UIFactory.Divider(parent, position, size, isGold)
    local line = UIFactory.Create("Frame", parent, {
        Name = "Divider",
        Position = position or UDim2.fromScale(0, 0),
        Size = size or UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = isGold and Theme.Colors.ACCENT_GOLD or Theme.Colors.STROKE_STEEL,
        BackgroundTransparency = isGold and 0.40 or 0.60,
        BorderSizePixel = 0,
        ZIndex = 3,
    })
    return line
end

function UIFactory.Badge(parent, text, position, size, color, textColor)
    local c = Theme.GetColor(color or Theme.Colors.ACCENT_SAPPHIRE)
    local badge = UIFactory.Create("Frame", parent, {
        Name = "Badge",
        Position = position or UDim2.fromOffset(0, 0),
        Size = size or UDim2.fromOffset(88, 22),
        BackgroundColor3 = Color3.fromRGB(9, 13, 24),
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        ZIndex = 5,
    })
    UIFactory.Corner(badge, Theme.Radius.Small)
    UIFactory.Stroke(badge, c, 1.2, 0.18)
    UIFactory.Label(badge, {
        Name = "BadgeText",
        Text = text or "",
        Size = UDim2.fromScale(1, 1),
        TextSize = 10,
        TextColor = textColor or c,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Wrapped = false,
        ZIndex = 6,
    })
    return badge
end

-- Crisp Geometric Diamond Star Pips Row (replaces Unicode star characters so zero tofu boxes render)
function UIFactory.StarPipsRow(parent, propsOrStars, maxStarsArg, extraProps)
    local props
    if type(propsOrStars) == "number" then
        props = type(extraProps) == "table" and table.clone(extraProps) or {}
        props.stars = propsOrStars
        props.maxStars = tonumber(maxStarsArg) or propsOrStars
    else
        props = propsOrStars or {}
    end
    local filled = math.clamp(math.floor(tonumber(props.stars or props.Stars) or 0), 0, 6)
    local total = math.clamp(math.floor(tonumber(props.maxStars or props.MaxStars) or filled), 0, 6)
    local pipSz = tonumber(props.pipSize or props.PipSize) or 5
    local gap = tonumber(props.gap or props.Gap) or 3
    local zIdx = tonumber(props.zIndex or props.ZIndex) or 8

    local row = UIFactory.Create("Frame", parent, {
        Name = props.name or props.Name or "StarPipsRow",
        AnchorPoint = props.anchorPoint or props.AnchorPoint or Vector2.new(0, 0),
        Position = props.position or props.Position or UDim2.fromOffset(0, 0),
        Size = props.size or props.Size or UDim2.fromOffset(math.max(8, total * (pipSz + gap)), pipSz + 4),
        BackgroundTransparency = 1,
        ZIndex = zIdx,
    })
    UIFactory.ListLayout(
        row,
        Enum.FillDirection.Horizontal,
        gap,
        props.hAlign or props.HAlign or Enum.HorizontalAlignment.Left,
        Enum.VerticalAlignment.Center
    )

    local goldFill = Color3.fromRGB(255, 218, 92)
    local goldRim = Color3.fromRGB(255, 246, 188)
    local emptyFill = Color3.fromRGB(44, 56, 78)

    for i = 1, total do
        local isOn = (i <= filled)
        local wrap = UIFactory.Create("Frame", row, {
            Name = "StarPip_" .. i,
            Size = UDim2.fromOffset(pipSz + 2, pipSz + 2),
            BackgroundTransparency = 1,
            LayoutOrder = i,
            ZIndex = zIdx,
        })
        local d1 = UIFactory.Create("Frame", wrap, {
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(pipSz, pipSz),
            Rotation = 45,
            BackgroundColor3 = isOn and goldFill or emptyFill,
            BorderSizePixel = 0,
            ZIndex = zIdx + 1,
        })
        UIFactory.Corner(d1, 1)
        if isOn then
            UIFactory.Stroke(d1, goldRim, 1, 0.15)
        end
    end

    return row
end

-- Applies the Vivid Glossy 6-Rarity Card Styling (Figma File 1 Section 3 & File 2 6-Layer Bevel Card)
function UIFactory.ApplyRarityCardStyle(frame, rarityId, opts)
    opts = opts or {}
    local rarity = RarityConfig.GetRarity(rarityId)
    local isSelected = (opts.selected == true) or (opts.Selected == true)
    local radius = tonumber(opts.cornerRadius or opts.CornerRadius) or 10
    local baseZ = frame.ZIndex

    frame.BackgroundColor3 = Color3.new(1, 1, 1)
    frame.BackgroundTransparency = tonumber(opts.transparency or opts.Transparency) or 0.02
    frame.BorderSizePixel = 0

    local corner = frame:FindFirstChildOfClass("UICorner") or UIFactory.Corner(frame, radius)
    corner.CornerRadius = UDim.new(0, radius)

    local grad = frame:FindFirstChild("RarityGradient")
    if not grad then
        grad = Instance.new("UIGradient")
        grad.Name = "RarityGradient"
        grad.Rotation = 90
        grad.Parent = frame
    end
    grad.Color = ColorSequence.new(
        rarity.CardTop or rarity.Color,
        rarity.CardBottom or rarity.BackgroundTint
    )

    local stroke = frame:FindFirstChildOfClass("UIStroke")
    if not stroke then
        stroke = UIFactory.Stroke(frame, rarity.BorderBright or rarity.Color, 2.0, 0.04)
    end
    stroke.Color = isSelected and Theme.Colors.ACCENT_GOLD_BRIGHT or (rarity.BorderBright or rarity.Color)
    stroke.Thickness = isSelected and 2.6 or (tonumber(opts.strokeThickness or opts.StrokeThickness) or 2.0)
    stroke.Transparency = isSelected and 0.0 or 0.06

    local bottomLip = frame:FindFirstChild("BottomBevelLip")
    if not bottomLip then
        bottomLip = UIFactory.Create("Frame", frame, {
            Name = "BottomBevelLip",
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 2, 1, -1),
            Size = UDim2.new(1, -4, 0, 3),
            BackgroundColor3 = Color3.fromRGB(6, 10, 20),
            BackgroundTransparency = 0.32,
            BorderSizePixel = 0,
            Active = false,
            ZIndex = baseZ + 1,
        })
        UIFactory.Corner(bottomLip, math.max(3, radius - 2))
    end

    local topBevel = frame:FindFirstChild("TopBevel")
    if not topBevel then
        topBevel = UIFactory.Create("Frame", frame, {
            Name = "TopBevel",
            Position = UDim2.fromOffset(3, 2),
            Size = UDim2.new(1, -6, 0.40, 0),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            Active = false,
            ZIndex = baseZ + 1,
        })
        UIFactory.Corner(topBevel, math.max(3, radius - 2))
        UIFactory.Create("UIGradient", topBevel, {
            Rotation = 90,
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.72),
                NumberSequenceKeypoint.new(0.65, 0.89),
                NumberSequenceKeypoint.new(1, 0.98),
            }),
        })
    end

    local auraDisc = frame:FindFirstChild("RadialAuraDisc")
    if opts.showAura ~= false then
        if not auraDisc then
            auraDisc = UIFactory.Create("Frame", frame, {
                Name = "RadialAuraDisc",
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = opts.auraPosition or UDim2.fromScale(0.5, 0.42),
                Size = opts.auraSize or UDim2.fromScale(0.60, 0.60),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = 0.84,
                BorderSizePixel = 0,
                Active = false,
                ZIndex = baseZ + 1,
            })
            UIFactory.AspectRatio(auraDisc, 1)
            UIFactory.PillCorner(auraDisc)
            UIFactory.Stroke(auraDisc, Color3.new(1, 1, 1), 1.2, 0.76)
        end
    end

    return {
        Rarity = rarity,
        Stroke = stroke,
        Gradient = grad,
        TopBevel = topBevel,
        AuraDisc = auraDisc,
        BottomLip = bottomLip,
    }
end

-- Signature Figma Golden or Sapphire Skewed Ribbon Header Banner
function UIFactory.RibbonBanner(parent, props)
    props = props or {}
    local variant = tostring(props.variant or "gold")
    local zIdx = tonumber(props.zIndex) or 8

    local topCol = Color3.fromRGB(246, 204, 96)    -- #F6CC60 Champagne Gold
    local botCol = Color3.fromRGB(184, 131, 40)    -- #B88328 Deep Amber Gold
    local rimCol = Color3.fromRGB(255, 242, 178)   -- #FFF2B2 Specular Rim
    local textCol = Color3.fromRGB(14, 18, 30)     -- Crisp Dark Ink on Gold
    local iconCol = Color3.fromRGB(24, 20, 12)
    local badgeTextCol = Color3.fromRGB(255, 232, 152)

    if variant == "sapphire" then
        topCol = Color3.fromRGB(68, 194, 255)
        botCol = Color3.fromRGB(29, 78, 216)
        rimCol = Color3.fromRGB(168, 236, 255)
        textCol = Color3.fromRGB(248, 252, 255)
        iconCol = Color3.fromRGB(248, 252, 255)
        badgeTextCol = Color3.fromRGB(168, 236, 255)
    elseif variant == "crimson" then
        topCol = Color3.fromRGB(251, 55, 98)
        botCol = Color3.fromRGB(159, 18, 57)
        rimCol = Color3.fromRGB(253, 164, 175)
        textCol = Color3.fromRGB(255, 250, 252)
        iconCol = Color3.fromRGB(255, 242, 178)
        badgeTextCol = Color3.fromRGB(255, 228, 234)
    end

    local banner = UIFactory.Create("Frame", parent, {
        Name = props.name or "RibbonBanner",
        AnchorPoint = props.anchorPoint or Vector2.new(0, 0),
        Position = props.position or UDim2.fromOffset(0, 0),
        Size = props.size or UDim2.fromOffset(264, 30),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        ZIndex = zIdx,
    })
    UIFactory.Corner(banner, props.cornerRadius or 6)
    local stroke = UIFactory.Stroke(banner, rimCol, 1.6, 0.04)
    UIFactory.Gradient(banner, topCol, botCol, 90)

    -- Glossy top half specular sheen
    local gloss = UIFactory.Create("Frame", banner, {
        Name = "RibbonTopGloss",
        Position = UDim2.fromOffset(2, 1),
        Size = UDim2.new(1, -4, 0.46, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Active = false,
        ZIndex = zIdx + 1,
    })
    UIFactory.Corner(gloss, 4)
    UIFactory.Create("UIGradient", gloss, {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.68),
            NumberSequenceKeypoint.new(1, 0.96),
        }),
    })

    -- Decorative angled right ribbon tail accent (gives the skewed Figma parallelogram silhouette)
    local rightSkew = UIFactory.Create("Frame", banner, {
        Name = "SkewTailAccent",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(1, -2, 0.5, 0),
        Size = UDim2.new(0, 12, 0.82, 0),
        Rotation = 16,
        BackgroundColor3 = topCol:Lerp(rimCol, 0.35),
        BorderSizePixel = 0,
        Active = false,
        ZIndex = zIdx,
    })
    UIFactory.Corner(rightSkew, 3)
    UIFactory.Stroke(rightSkew, rimCol, 1.3, 0.12)

    -- Left tiny diamond stud
    local leftStud = UIFactory.Create("Frame", banner, {
        Name = "LeftDiamondStud",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 8, 0.5, 0),
        Size = UDim2.fromOffset(5, 5),
        Rotation = 45,
        BackgroundColor3 = (variant == "gold") and Color3.fromRGB(88, 56, 12) or rimCol,
        BorderSizePixel = 0,
        ZIndex = zIdx + 2,
    })
    UIFactory.Corner(leftStud, 1)

    local leftOffset = 16
    local iconHolder = nil
    if props.icon then
        local icSz = tonumber(props.iconSize) or 16
        iconHolder = UIFactory.Icon(
            banner,
            props.icon,
            UDim2.new(0, 15, 0.5, -math.floor(icSz * 0.5)),
            icSz,
            props.iconColor or iconCol
        )
        iconHolder.ZIndex = zIdx + 2
        leftOffset = 15 + icSz + 6
    end

    local hasBadge = (props.badgeText ~= nil and tostring(props.badgeText) ~= "")
    local badgeW = tonumber(props.badgeWidth) or 42
    local rightPad = hasBadge and (badgeW + 16) or 14

    local titleLbl = UIFactory.Label(banner, {
        Name = "RibbonTitle",
        Text = tostring(props.title or props.text or ""),
        Position = UDim2.fromOffset(leftOffset, 0),
        Size = UDim2.new(1, -(leftOffset + rightPad), 1, 0),
        TextSize = tonumber(props.textSize) or 12,
        TextColor = props.textColor or textCol,
        Bold = true,
        XAlign = props.xAlign or Enum.TextXAlignment.Left,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = zIdx + 3,
    })

    local badgeObj = nil
    local badgeLbl = nil
    if hasBadge or props.reserveBadge then
        local bClass = (type(props.onBadgeActivated) == "function") and "TextButton" or "Frame"
        local bProps = {
            Name = "RibbonBadgePill",
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -8, 0.5, 0),
            Size = UDim2.fromOffset(badgeW, 20),
            BackgroundColor3 = Color3.fromRGB(12, 17, 29),
            BackgroundTransparency = 0.04,
            BorderSizePixel = 0,
            Visible = hasBadge,
            ZIndex = zIdx + 3,
        }
        if bClass == "TextButton" then
            bProps.Text = ""
            bProps.AutoButtonColor = false
        end
        badgeObj = UIFactory.Create(bClass, banner, bProps)
        UIFactory.Corner(badgeObj, 5)
        UIFactory.Stroke(badgeObj, rimCol, 1.1, 0.25)

        badgeLbl = UIFactory.Label(badgeObj, {
            Name = "BadgeText",
            Text = tostring(props.badgeText or ""),
            Size = UDim2.fromScale(1, 1),
            TextSize = 10,
            TextColor = badgeTextCol,
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            Wrapped = false,
            ZIndex = zIdx + 4,
        })

        if bClass == "TextButton" then
            badgeObj.Activated:Connect(function()
                props.onBadgeActivated()
            end)
        end
    end

    local refs = {
        Instance = banner,
        Stroke = stroke,
        TitleLabel = titleLbl,
        Badge = badgeObj,
        BadgeLabel = badgeLbl,
        Icon = iconHolder,
        SetTitle = function(newText)
            if titleLbl and titleLbl.Parent then
                titleLbl.Text = tostring(newText or "")
            end
        end,
        SetBadge = function(newBadgeText)
            if badgeObj and badgeLbl then
                local txt = tostring(newBadgeText or "")
                badgeObj.Visible = txt ~= ""
                badgeLbl.Text = txt
            end
        end,
    }
    return banner, refs
end

-- 100% Procedural Two-Tone Geometric Vector Icon System (Matches SKYBREAK_Figma_v2_03_Design_System.png)
function UIFactory.Icon(parent, kind, position, sizeOffset, color)
    local px = type(sizeOffset) == "number" and sizeOffset or 28
    local c = Theme.GetColor(color or Theme.Colors.ACCENT_SAPPHIRE)
    local gold = Theme.Colors.ACCENT_GOLD_BRIGHT
    local white = Color3.fromRGB(248, 250, 255)
    local dark = Theme.Colors.BG_900

    -- Secondary highlight: if primary color is already gold/white, pair with bright cyan/white contrast
    local isGoldish = (c.R > 0.78 and c.G > 0.62 and c.B < 0.55)
    local hi = isGoldish and white or gold

    local holder = UIFactory.Create("Frame", parent, {
        Name = tostring(kind or "Icon") .. "Holder",
        Position = position or UDim2.fromOffset(0, 0),
        Size = typeof(sizeOffset) == "UDim2" and sizeOffset or UDim2.fromOffset(px, px),
        BackgroundTransparency = 1,
        ZIndex = 5,
    })

    local uploadedAsset = UIAssets.GetIcon(kind)
    if uploadedAsset then
        UIFactory.Create("ImageLabel", holder, {
            Name = "UploadedIcon",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Image = uploadedAsset,
            ImageColor3 = c,
            ScaleType = Enum.ScaleType.Fit,
            ZIndex = 6,
        })
        return holder
    end

    local function part(x, y, w, h, rot, fillCol, radius, zDelta)
        local f = UIFactory.Create("Frame", holder, {
            Position = UDim2.fromScale(x, y),
            Size = UDim2.fromScale(w, h),
            Rotation = rot or 0,
            BackgroundColor3 = fillCol or c,
            BorderSizePixel = 0,
            ZIndex = 6 + (zDelta or 0),
        })
        if radius then
            if radius >= 90 then
                UIFactory.PillCorner(f)
            else
                UIFactory.Corner(f, radius)
            end
        end
        return f
    end

    if kind == "Sword" or kind == "Weapon" then
        -- Diagonal celestial blade + bright ridge + golden crossguard + pommel
        part(0.45, 0.08, 0.14, 0.62, 38, c, 2, 1)
        part(0.50, 0.12, 0.05, 0.50, 38, white, 2, 2)
        part(0.24, 0.57, 0.46, 0.10, 38, hi, 2, 2)
        part(0.22, 0.68, 0.11, 0.21, 38, hi:Lerp(dark, 0.25), 2, 1)
        part(0.16, 0.80, 0.12, 0.12, 45, hi, 2, 2)
    elseif kind == "Daggers" then
        part(0.30, 0.12, 0.11, 0.60, 28, c, 2, 1)
        part(0.56, 0.12, 0.11, 0.60, -28, hi, 2, 1)
        part(0.18, 0.57, 0.32, 0.08, 28, hi, 2, 2)
        part(0.50, 0.57, 0.32, 0.08, -28, c, 2, 2)
    elseif kind == "Staff" then
        part(0.45, 0.24, 0.09, 0.66, 26, hi, 2, 1)
        local orb = part(0.44, 0.08, 0.30, 0.30, 45, c, 4, 2)
        UIFactory.Stroke(orb, white, 1.3, 0.1)
        part(0.53, 0.17, 0.12, 0.12, 45, white, 2, 3)
    elseif kind == "Gun" then
        part(0.16, 0.28, 0.66, 0.18, 0, c, 2, 1)
        part(0.22, 0.32, 0.44, 0.06, 0, white, 2, 2)
        part(0.22, 0.45, 0.18, 0.35, -18, hi, 2, 1)
        part(0.68, 0.24, 0.16, 0.11, 0, hi, 2, 2)
    elseif kind == "Fist" then
        local fist = part(0.20, 0.24, 0.60, 0.52, 0, c:Lerp(dark, 0.35), 5, 1)
        UIFactory.Stroke(fist, c, 1.5, 0.05)
        part(0.26, 0.28, 0.13, 0.20, 0, hi, 2, 2)
        part(0.43, 0.28, 0.13, 0.20, 0, hi, 2, 2)
        part(0.60, 0.28, 0.13, 0.20, 0, hi, 2, 2)
    elseif kind == "Haki" then
        -- Target crosshair ring + 4 cardinal ticks + glowing core (Figma Design System Row 2 Col 4)
        local ring = part(0.20, 0.20, 0.60, 0.60, 0, dark, 99, 1)
        ring.BackgroundTransparency = 0.55
        UIFactory.Stroke(ring, c, 1.7, 0.05)
        part(0.46, 0.08, 0.08, 0.20, 0, c, 2, 2)
        part(0.46, 0.72, 0.08, 0.20, 0, c, 2, 2)
        part(0.08, 0.46, 0.20, 0.08, 0, c, 2, 2)
        part(0.72, 0.46, 0.20, 0.08, 0, c, 2, 2)
        part(0.38, 0.38, 0.24, 0.24, 0, hi, 99, 3)
    elseif kind == "Fruit" then
        local orb = part(0.18, 0.24, 0.64, 0.62, 0, c:Lerp(dark, 0.25), 99, 1)
        UIFactory.Stroke(orb, c, 1.6, 0.05)
        part(0.36, 0.42, 0.26, 0.26, 0, hi, 99, 2)
        part(0.46, 0.08, 0.09, 0.20, 18, hi, 2, 2)
        part(0.52, 0.12, 0.20, 0.10, -22, Theme.Colors.SUCCESS, 99, 2)
    elseif kind == "Shield" or kind == "Armor" then
        local sh = part(0.20, 0.14, 0.60, 0.68, 0, c:Lerp(dark, 0.45), 6, 1)
        UIFactory.Stroke(sh, c, 1.6, 0.06)
        part(0.46, 0.22, 0.08, 0.50, 0, hi, 2, 2)
        part(0.28, 0.38, 0.44, 0.08, 0, hi, 2, 2)
    elseif kind == "Bolt" or kind == "Lightning" then
        part(0.46, 0.08, 0.17, 0.48, 24, c, 2, 1)
        part(0.35, 0.43, 0.17, 0.48, 24, hi, 2, 2)
        part(0.38, 0.44, 0.26, 0.10, 0, white, 2, 3)
    elseif kind == "Frost" then
        part(0.46, 0.10, 0.08, 0.80, 0, c, 2, 1)
        part(0.10, 0.46, 0.80, 0.08, 0, c, 2, 1)
        part(0.46, 0.14, 0.07, 0.72, 45, hi, 2, 1)
        part(0.46, 0.14, 0.07, 0.72, -45, hi, 2, 1)
        part(0.34, 0.34, 0.32, 0.32, 45, white, 3, 2)
    elseif kind == "Crown" then
        -- Unmistakable 3-peak Royal Sovereign Crown (Figma Design System Row 3 Col 8 & [R] Ultimate)
        local base = part(0.16, 0.68, 0.68, 0.15, 0, c, 2, 2)
        UIFactory.Stroke(base, white, 1, 0.35)
        -- Left, Center (tall), Right crown peaks
        part(0.16, 0.34, 0.15, 0.40, -10, c, 2, 1)
        part(0.42, 0.20, 0.16, 0.52, 0, c, 2, 1)
        part(0.69, 0.34, 0.15, 0.40, 10, c, 2, 1)
        -- Crown jewels
        part(0.17, 0.24, 0.11, 0.11, 45, hi, 99, 3)
        part(0.44, 0.10, 0.12, 0.12, 45, white, 99, 3)
        part(0.72, 0.24, 0.11, 0.11, 45, hi, 99, 3)
        part(0.45, 0.70, 0.10, 0.10, 45, white, 1, 3)
    elseif kind == "Skill" or kind == "Sparkle" or kind == "Star" then
        -- 4-Point Celestial Aether Star (Figma Design System Row 2 Col 6)
        part(0.43, 0.12, 0.14, 0.76, 0, c, 99, 1)
        part(0.12, 0.43, 0.76, 0.14, 0, c, 99, 1)
        local core = part(0.30, 0.30, 0.40, 0.40, 45, hi, 3, 2)
        UIFactory.Stroke(core, white, 1, 0.25)
        part(0.41, 0.41, 0.18, 0.18, 45, white, 99, 3)
    elseif kind == "Core" or kind == "CoreShards" or kind == "CoreShard" or kind == "Gem" or kind == "Void" or kind == "VoidEssence" or kind == "Artifact" then
        local outer = part(0.20, 0.18, 0.60, 0.64, 45, c:Lerp(dark, 0.32), 4, 1)
        UIFactory.Stroke(outer, c, 1.6, 0.05)
        part(0.46, 0.18, 0.08, 0.64, 0, white, 2, 2)
        part(0.35, 0.35, 0.30, 0.30, 45, hi, 2, 3)
    elseif kind == "Gold" then
        local coin = part(0.16, 0.16, 0.68, 0.68, 0, Theme.Colors.ACCENT_GOLD, 99, 1)
        UIFactory.Stroke(coin, white, 1.3, 0.20)
        part(0.36, 0.36, 0.28, 0.28, 45, dark, 2, 2)
        part(0.42, 0.42, 0.16, 0.16, 45, white, 1, 3)
    elseif kind == "Bag" then
        local bag = part(0.18, 0.30, 0.64, 0.54, 0, c:Lerp(dark, 0.42), 6, 1)
        UIFactory.Stroke(bag, c, 1.5, 0.08)
        local handle = part(0.34, 0.15, 0.32, 0.20, 0, dark, 4, 0)
        handle.BackgroundTransparency = 1
        UIFactory.Stroke(handle, c, 1.4, 0.08)
        part(0.44, 0.48, 0.12, 0.18, 0, hi, 2, 2)
    elseif kind == "Flask" or kind == "Potion" then
        -- Energy Potion Flask for [H] Bình EN
        part(0.38, 0.12, 0.24, 0.12, 0, hi, 2, 2)
        local body = part(0.22, 0.26, 0.56, 0.58, 0, c:Lerp(dark, 0.35), 7, 1)
        UIFactory.Stroke(body, c, 1.5, 0.06)
        part(0.30, 0.48, 0.40, 0.28, 0, c, 4, 2)
        part(0.36, 0.34, 0.12, 0.12, 0, white, 99, 3)
    elseif kind == "Anchor" then
        part(0.45, 0.16, 0.10, 0.66, 0, c, 2, 1)
        part(0.26, 0.32, 0.48, 0.09, 0, hi, 2, 2)
        local base = part(0.22, 0.62, 0.56, 0.20, 0, c, 6, 1)
        base.BackgroundTransparency = 0.2
    elseif kind == "Forge" or kind == "Anvil" then
        part(0.22, 0.18, 0.54, 0.22, -22, c, 3, 2)
        part(0.44, 0.30, 0.11, 0.46, 18, hi, 2, 1)
        part(0.18, 0.72, 0.64, 0.14, 0, c, 3, 2)
    elseif kind == "Map" then
        local p1 = part(0.14, 0.20, 0.24, 0.60, 0, c:Lerp(dark, 0.45), 2, 1)
        local p2 = part(0.38, 0.16, 0.24, 0.60, 0, c:Lerp(dark, 0.30), 2, 2)
        local p3 = part(0.62, 0.20, 0.24, 0.60, 0, c:Lerp(dark, 0.45), 2, 1)
        UIFactory.Stroke(p1, c, 1.2, 0.1)
        UIFactory.Stroke(p2, hi, 1.2, 0.1)
        UIFactory.Stroke(p3, c, 1.2, 0.1)
    elseif kind == "Compass" then
        local ring = part(0.16, 0.16, 0.68, 0.68, 0, dark, 99, 1)
        ring.BackgroundTransparency = 0.35
        UIFactory.Stroke(ring, c, 1.5, 0.08)
        part(0.43, 0.24, 0.14, 0.30, 35, hi, 2, 2)
        part(0.43, 0.46, 0.14, 0.30, 35, c, 2, 2)
    elseif kind == "Quest" then
        local scroll = part(0.20, 0.14, 0.60, 0.72, 0, c:Lerp(dark, 0.55), 5, 1)
        UIFactory.Stroke(scroll, c, 1.5, 0.08)
        part(0.32, 0.32, 0.36, 0.08, 0, hi, 2, 2)
        part(0.32, 0.48, 0.36, 0.08, 0, white, 2, 2)
        part(0.32, 0.64, 0.24, 0.08, 0, c, 2, 2)
    elseif kind == "Raid" or kind == "Skull" then
        local cr = part(0.20, 0.16, 0.60, 0.52, 0, c:Lerp(dark, 0.32), 99, 1)
        UIFactory.Stroke(cr, c, 1.6, 0.05)
        part(0.32, 0.35, 0.13, 0.13, 0, hi, 99, 2)
        part(0.55, 0.35, 0.13, 0.13, 0, hi, 99, 2)
        part(0.34, 0.66, 0.32, 0.16, 0, c, 2, 2)
    elseif kind == "Settings" then
        part(0.44, 0.10, 0.12, 0.80, 0, c, 2, 1)
        part(0.10, 0.44, 0.80, 0.12, 0, c, 2, 1)
        part(0.44, 0.12, 0.12, 0.76, 45, c, 2, 1)
        part(0.44, 0.12, 0.12, 0.76, -45, c, 2, 1)
        local gear = part(0.24, 0.24, 0.52, 0.52, 0, c:Lerp(dark, 0.40), 99, 2)
        UIFactory.Stroke(gear, hi, 1.5, 0.08)
        part(0.38, 0.38, 0.24, 0.24, 0, dark, 99, 3)
    elseif kind == "Lock" then
        local arch = part(0.30, 0.16, 0.40, 0.34, 0, dark, 99, 1)
        arch.BackgroundTransparency = 1
        UIFactory.Stroke(arch, c, 1.6, 0.1)
        local body = part(0.22, 0.42, 0.56, 0.44, 0, c:Lerp(dark, 0.3), 4, 2)
        UIFactory.Stroke(body, c, 1.3, 0.1)
        part(0.45, 0.56, 0.10, 0.16, 0, hi, 2, 3)
    elseif kind == "Check" then
        part(0.20, 0.54, 0.24, 0.12, 42, c, 2, 1)
        part(0.36, 0.46, 0.46, 0.12, -46, c, 2, 1)
    elseif kind == "Close" then
        part(0.18, 0.44, 0.64, 0.12, 45, c, 2, 1)
        part(0.18, 0.44, 0.64, 0.12, -45, c, 2, 1)
    elseif kind == "Heart" then
        part(0.22, 0.24, 0.30, 0.30, 0, c, 99, 1)
        part(0.48, 0.24, 0.30, 0.30, 0, c, 99, 1)
        part(0.28, 0.36, 0.44, 0.44, 45, c, 2, 1)
    elseif kind == "Gift" then
        local box = part(0.20, 0.34, 0.60, 0.50, 0, c:Lerp(dark, 0.35), 4, 1)
        UIFactory.Stroke(box, c, 1.4, 0.1)
        part(0.45, 0.34, 0.10, 0.50, 0, hi, 1, 2)
        part(0.20, 0.52, 0.60, 0.10, 0, hi, 1, 2)
        part(0.32, 0.20, 0.36, 0.14, 0, hi, 99, 2)
    elseif kind == "Wing" then
        part(0.24, 0.26, 0.58, 0.15, -34, hi, 99, 2)
        part(0.18, 0.45, 0.54, 0.15, -24, c, 99, 1)
        part(0.30, 0.63, 0.44, 0.13, -14, white, 99, 2)
    elseif kind == "Flame" then
        local outer = part(0.24, 0.24, 0.52, 0.58, 45, c, 8, 1)
        UIFactory.Stroke(outer, hi, 1.2, 0.2)
        part(0.38, 0.10, 0.24, 0.38, 16, c, 99, 1)
        part(0.35, 0.42, 0.30, 0.34, 45, hi, 99, 2)
        part(0.41, 0.52, 0.18, 0.20, 45, white, 99, 3)
    elseif kind == "Ship" then
        local hull = part(0.14, 0.58, 0.72, 0.22, 0, c:Lerp(dark, 0.25), 4, 1)
        UIFactory.Stroke(hull, c, 1.3, 0.1)
        part(0.46, 0.16, 0.08, 0.44, 0, hi, 2, 1)
        part(0.26, 0.20, 0.44, 0.32, -10, c, 3, 2)
        part(0.50, 0.26, 0.28, 0.22, 14, hi, 3, 2)
    elseif kind == "Scroll" then
        local body = part(0.22, 0.18, 0.56, 0.64, 0, c:Lerp(dark, 0.45), 3, 1)
        UIFactory.Stroke(body, c, 1.3, 0.1)
        part(0.18, 0.14, 0.64, 0.11, 0, hi, 99, 2)
        part(0.18, 0.75, 0.64, 0.11, 0, hi, 99, 2)
        part(0.32, 0.38, 0.36, 0.08, 0, white, 2, 2)
        part(0.32, 0.54, 0.26, 0.08, 0, c, 2, 2)
    elseif kind == "Users" then
        part(0.24, 0.18, 0.26, 0.26, 0, c, 99, 1)
        part(0.14, 0.48, 0.46, 0.32, 0, c, 6, 1)
        part(0.56, 0.24, 0.22, 0.22, 0, hi, 99, 2)
        part(0.50, 0.52, 0.36, 0.26, 0, hi, 5, 2)
    elseif kind == "Trophy" then
        local cup = part(0.26, 0.16, 0.48, 0.38, 0, hi, 5, 2)
        UIFactory.Stroke(cup, white, 1.2, 0.25)
        part(0.16, 0.22, 0.12, 0.20, 0, c, 3, 1)
        part(0.72, 0.22, 0.12, 0.20, 0, c, 3, 1)
        part(0.45, 0.54, 0.10, 0.18, 0, hi, 2, 1)
        part(0.30, 0.72, 0.40, 0.12, 0, c, 3, 2)
    elseif kind == "Trade" then
        part(0.16, 0.30, 0.56, 0.11, 0, c, 2, 1)
        part(0.58, 0.22, 0.22, 0.11, 38, c, 2, 1)
        part(0.28, 0.58, 0.56, 0.11, 0, hi, 2, 2)
        part(0.20, 0.66, 0.22, 0.11, 38, hi, 2, 2)
    else
        local crest = part(0.24, 0.24, 0.52, 0.52, 45, c:Lerp(dark, 0.4), 3, 1)
        UIFactory.Stroke(crest, c, 1.5, 0.1)
        part(0.38, 0.38, 0.24, 0.24, 45, hi, 2, 2)
    end

    return holder
end

function UIFactory.FormatNumber(n)
    local num = math.floor(tonumber(n) or 0)
    local sign = num < 0 and "-" or ""
    local s = tostring(math.abs(num))
    local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
    return sign .. formatted
end

-- Shared Top Header Bar with Complete NavTabs + Glossy Gold/Sapphire/Crimson Pills (Figma File 2)
function UIFactory.BuildScreenHeader(parent, opts)
    opts = opts or {}
    local activeScreen = opts.ActiveScreen or ""
    local titleText = opts.Title or ""
    local snapshot = opts.Snapshot or {}
    local onNavigate = opts.OnNavigate

    local bar = UIFactory.Create("Frame", parent, {
        Name = "SharedTopHeaderBar",
        Position = opts.Position or UDim2.fromOffset(16, 10),
        Size = opts.Size or UDim2.new(1, -32, 0, 56),
        BackgroundColor3 = Theme.Colors.BG_800,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        ZIndex = 12,
    })
    UIFactory.Corner(bar, Theme.Radius.Large)
    UIFactory.Stroke(bar, Theme.Colors.ACCENT_GOLD, 1.5, 0.24)
    UIFactory.Gradient(bar, Color3.fromRGB(22, 34, 58), Theme.Colors.BG_900, 90)

    local titleLbl = UIFactory.Label(bar, {
        Name = "Title",
        Text = titleText,
        Position = UDim2.fromOffset(14, 0),
        Size = UDim2.fromOffset(238, 56),
        TextSize = 15,
        TextColor = Theme.Colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        Wrapped = false,
        Truncate = Enum.TextTruncate.AtEnd,
        ZIndex = 13,
    })
    UIFactory.TextSizeConstraint(titleLbl, 11, 16)

    local navTabs = UIFactory.Create("ScrollingFrame", bar, {
        Name = "NavTabs",
        Position = UDim2.fromOffset(256, 10),
        Size = UDim2.new(1, -576, 0, 36),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Colors.ACCENT_GOLD,
        ScrollingDirection = Enum.ScrollingDirection.X,
        AutomaticCanvasSize = Enum.AutomaticSize.X,
        CanvasSize = UDim2.fromOffset(0, 0),
        ZIndex = 13,
    })
    UIFactory.ListLayout(navTabs, Enum.FillDirection.Horizontal, 5, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    local tabs = {
        { Id = UIState.Screens.Fruits, Label = I18n.T("nav.fruits") },
        { Id = UIState.Screens.NPCShop, Label = I18n.Pick("SHOP NPC [N]", "NPC SHOPS [N]") },
        { Id = UIState.Screens.Inventory, Label = I18n.T("nav.inventory") },
        { Id = UIState.Screens.Skills, Label = I18n.T("nav.skills") },
        { Id = UIState.Screens.Forge, Label = I18n.T("nav.forge") },
        { Id = UIState.Screens.WorldMap, Label = I18n.T("nav.map") },
        { Id = UIState.Screens.QuestJournal, Label = I18n.T("nav.quests") },
        { Id = UIState.Screens.Raid, Label = I18n.T("nav.raid") },
        { Id = UIState.Screens.SocialRewards, Label = I18n.Pick("TỔ ĐỘI & QUÀ [B]", "PARTY & REWARDS [B]") },
        { Id = UIState.Screens.Settings, Label = I18n.T("nav.settings") },
    }

    for idx, tab in ipairs(tabs) do
        local isCurrent = (tab.Id == activeScreen)
        local btn = UIFactory.Create("TextButton", navTabs, {
            Name = "Nav_" .. tab.Id,
            Size = UDim2.fromOffset(0, 32),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = isCurrent and Color3.fromRGB(244, 193, 78) or Theme.Colors.BG_700,
            BackgroundTransparency = isCurrent and 0.02 or 0.20,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Font = Theme.Fonts.Bold,
            TextSize = 11,
            TextColor3 = isCurrent and Theme.Colors.BG_900 or Theme.Colors.TEXT_SECONDARY,
            Text = tab.Label,
            LayoutOrder = idx,
            ZIndex = 14,
        })
        UIFactory.Padding(btn, 0, 10, 0, 10)
        UIFactory.Corner(btn, Theme.Radius.Small)
        UIFactory.Stroke(
            btn,
            isCurrent and Theme.Colors.ACCENT_GOLD_BRIGHT or Theme.Colors.STROKE_STEEL,
            isCurrent and 1.5 or 1,
            isCurrent and 0.05 or 0.45
        )
        if isCurrent then
            UIFactory.Gradient(btn, Color3.fromRGB(252, 214, 104), Color3.fromRGB(196, 138, 36), 90)
        end

        if not isCurrent and type(onNavigate) == "function" then
            btn.Activated:Connect(function()
                onNavigate(tab.Id)
            end)
        end
    end

    -- Right-side Currency Summary + Glossy Crimson Close [ESC] Button
    local rightStrip = UIFactory.Create("Frame", bar, {
        Name = "RightStrip",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(308, 36),
        BackgroundTransparency = 1,
        ZIndex = 13,
    })
    UIFactory.ListLayout(rightStrip, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)

    local currencies = snapshot.currencies or snapshot.currency or {}
    local goldVal = tonumber(currencies.gold) or 0
    local shardVal = tonumber(currencies.coreShards) or 0

    local goldPill = UIFactory.Create("Frame", rightStrip, {
        Name = "GoldPill",
        Size = UDim2.fromOffset(102, 32),
        BackgroundColor3 = Theme.Colors.BG_900,
        BackgroundTransparency = 0.08,
        LayoutOrder = 1,
        ZIndex = 14,
    })
    UIFactory.Corner(goldPill, 7)
    UIFactory.Stroke(goldPill, Theme.Colors.ACCENT_GOLD_BRIGHT, 1.3, 0.18)
    UIFactory.Icon(goldPill, "Gold", UDim2.fromOffset(6, 8), 16, Theme.Colors.ACCENT_GOLD)
    local goldLbl = UIFactory.Label(goldPill, {
        Name = "GoldText",
        Text = UIFactory.FormatNumber(goldVal),
        Position = UDim2.fromOffset(25, 0),
        Size = UDim2.new(1, -29, 1, 0),
        TextSize = 11,
        TextColor = Theme.Colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        Wrapped = false,
        Truncate = Enum.TextTruncate.AtEnd,
        ZIndex = 15,
    })

    local shardPill = UIFactory.Create("Frame", rightStrip, {
        Name = "ShardsPill",
        Size = UDim2.fromOffset(92, 32),
        BackgroundColor3 = Theme.Colors.BG_900,
        BackgroundTransparency = 0.08,
        LayoutOrder = 2,
        ZIndex = 14,
    })
    UIFactory.Corner(shardPill, 7)
    UIFactory.Stroke(shardPill, Theme.Colors.ACCENT_SAPPHIRE, 1.3, 0.18)
    UIFactory.Icon(shardPill, "CoreShards", UDim2.fromOffset(6, 8), 16, Theme.Colors.ACCENT_SAPPHIRE)
    local shardLbl = UIFactory.Label(shardPill, {
        Name = "ShardText",
        Text = UIFactory.FormatNumber(shardVal),
        Position = UDim2.fromOffset(25, 0),
        Size = UDim2.new(1, -29, 1, 0),
        TextSize = 11,
        TextColor = Theme.Colors.ACCENT_ICE,
        Bold = true,
        Wrapped = false,
        Truncate = Enum.TextTruncate.AtEnd,
        ZIndex = 15,
    })

    local closeBtn = UIFactory.Create("TextButton", rightStrip, {
        Name = "CloseToHUDBtn",
        Size = UDim2.fromOffset(98, 32),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        AutoButtonColor = true,
        Font = Theme.Fonts.Bold,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(255, 250, 252),
        Text = I18n.T("nav.resume"),
        LayoutOrder = 3,
        ZIndex = 14,
    })
    UIFactory.Corner(closeBtn, 7)
    UIFactory.Stroke(closeBtn, Color3.fromRGB(255, 164, 180), 1.4, 0.10)
    UIFactory.Gradient(closeBtn, Color3.fromRGB(251, 55, 98), Color3.fromRGB(168, 22, 58), 90)
    if type(opts.OnClose) == "function" then
        closeBtn.Activated:Connect(function()
            opts.OnClose()
        end)
    elseif type(onNavigate) == "function" then
        closeBtn.Activated:Connect(function()
            onNavigate(UIState.Screens.HUD)
        end)
    end

    local headerRefs = {
        Bar = bar,
        TitleLabel = titleLbl,
        GoldLabel = goldLbl,
        ShardLabel = shardLbl,
        CloseButton = closeBtn,
        UpdateCurrencies = function(newSnap)
            local c = (newSnap and (newSnap.currencies or newSnap.currency)) or {}
            if goldLbl and goldLbl.Parent then
                goldLbl.Text = UIFactory.FormatNumber(tonumber(c.gold) or 0)
            end
            if shardLbl and shardLbl.Parent then
                shardLbl.Text = UIFactory.FormatNumber(tonumber(c.coreShards) or 0)
            end
        end,
    }
    return bar, headerRefs
end

return UIFactory
