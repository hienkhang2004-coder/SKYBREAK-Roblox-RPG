-- SKYBREAK: Fragments of the Core — Roblox GUI Primitive & Vector Icon Factory
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/UIFactory.lua
-- Rule: Pure presentation builder using real Roblox GUI instances and procedural geometric icons when UIAssets are empty.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local UIAssets = require(Shared:WaitForChild("Config"):WaitForChild("UIAssets"))

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
    return UIFactory.Create("UICorner", parent, {
        CornerRadius = UDim.new(0, radius or Theme.Radius.Medium),
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

function UIFactory.AspectRatio(parent, ratio)
    return UIFactory.Create("UIAspectRatioConstraint", parent, {
        AspectRatio = ratio or 1,
    })
end

function UIFactory.Label(parent, props)
    props = props or {}
    local weight = props.Weight or (props.Bold and "Bold" or "Regular")
    local font = Theme.Fonts.Regular
    if weight == "Bold" then
        font = Theme.Fonts.Bold
    elseif weight == "Medium" then
        font = Theme.Fonts.Medium
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
        BackgroundTransparency = isGold and 0.45 or 0.62,
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
        BackgroundColor3 = c:Lerp(Theme.Colors.BG_900, 0.72),
        BorderSizePixel = 0,
        ZIndex = 5,
    })
    UIFactory.Corner(badge, Theme.Radius.Small)
    UIFactory.Stroke(badge, c, 1, 0.25)
    UIFactory.Label(badge, {
        Name = "BadgeText",
        Text = text or "",
        Size = UDim2.fromScale(1, 1),
        TextSize = 11,
        TextColor = textColor or c,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Wrapped = false,
        ZIndex = 6,
    })
    return badge
end

-- Procedural geometric icon system (Zero external asset dependency, automatic upgrade if UIAssets populated)
function UIFactory.Icon(parent, kind, position, sizeOffset, color)
    local px = type(sizeOffset) == "number" and sizeOffset or 28
    local c = Theme.GetColor(color or Theme.Colors.ACCENT_SAPPHIRE)
    local holder = UIFactory.Create("Frame", parent, {
        Name = (kind or "Icon") .. "Holder",
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

    local function part(x, y, w, h, rot, fillCol, radius)
        local f = UIFactory.Create("Frame", holder, {
            Position = UDim2.fromScale(x, y),
            Size = UDim2.fromScale(w, h),
            Rotation = rot or 0,
            BackgroundColor3 = fillCol or c,
            BorderSizePixel = 0,
            ZIndex = 6,
        })
        if radius then
            UIFactory.Corner(f, radius)
        end
        return f
    end

    if kind == "Sword" then
        part(0.45, 0.08, 0.12, 0.64, 38, c, 2)
        part(0.24, 0.58, 0.46, 0.09, 38, Theme.Colors.ACCENT_GOLD, 2)
        part(0.24, 0.69, 0.11, 0.22, 38, Theme.Colors.TEXT_SECONDARY, 2)
    elseif kind == "Daggers" then
        part(0.32, 0.12, 0.10, 0.62, 28, c, 2)
        part(0.56, 0.12, 0.10, 0.62, -28, Theme.Colors.ACCENT_GOLD, 2)
        part(0.20, 0.58, 0.32, 0.07, 28, Theme.Colors.STROKE_STEEL, 2)
        part(0.48, 0.58, 0.32, 0.07, -28, Theme.Colors.STROKE_STEEL, 2)
    elseif kind == "Staff" then
        part(0.46, 0.22, 0.09, 0.68, 22, Theme.Colors.TEXT_SECONDARY, 2)
        local orb = part(0.42, 0.10, 0.28, 0.28, 45, c, 4)
        UIFactory.Stroke(orb, Theme.Colors.ACCENT_GOLD, 1.5, 0.1)
    elseif kind == "Shield" then
        local sh = part(0.20, 0.14, 0.60, 0.68, 0, c:Lerp(Theme.Colors.BG_900, 0.45), 6)
        UIFactory.Stroke(sh, c, 1.8, 0.1)
        part(0.46, 0.22, 0.08, 0.50, 0, Theme.Colors.ACCENT_GOLD, 2)
        part(0.28, 0.38, 0.44, 0.08, 0, Theme.Colors.ACCENT_GOLD, 2)
    elseif kind == "Bolt" then
        part(0.46, 0.10, 0.16, 0.46, 24, c, 2)
        part(0.36, 0.44, 0.16, 0.46, 24, Theme.Colors.ACCENT_GOLD, 2)
    elseif kind == "Frost" then
        part(0.46, 0.12, 0.08, 0.76, 0, c, 2)
        part(0.12, 0.46, 0.76, 0.08, 0, c, 2)
        part(0.28, 0.28, 0.44, 0.44, 45, c:Lerp(Theme.Colors.TEXT_PRIMARY, 0.35), 3)
    elseif kind == "Core" or kind == "Gem" or kind == "Void" then
        local outer = part(0.22, 0.22, 0.56, 0.56, 45, c:Lerp(Theme.Colors.BG_900, 0.35), 4)
        UIFactory.Stroke(outer, c, 1.8, 0.05)
        part(0.36, 0.36, 0.28, 0.28, 45, Theme.Colors.TEXT_PRIMARY, 2)
    elseif kind == "Gold" then
        local coin = part(0.18, 0.18, 0.64, 0.64, 0, Theme.Colors.ACCENT_GOLD, 99)
        UIFactory.Stroke(coin, Theme.Colors.TEXT_PRIMARY, 1.2, 0.25)
        part(0.42, 0.32, 0.16, 0.36, 0, Theme.Colors.BG_900, 2)
    elseif kind == "Bag" then
        local bag = part(0.18, 0.30, 0.64, 0.54, 0, c:Lerp(Theme.Colors.BG_800, 0.4), 6)
        UIFactory.Stroke(bag, c, 1.5, 0.15)
        local handle = part(0.34, 0.16, 0.32, 0.22, 0, Theme.Colors.BG_900, 4)
        UIFactory.Stroke(handle, c, 1.5, 0.15)
        part(0.44, 0.48, 0.12, 0.18, 0, Theme.Colors.ACCENT_GOLD, 2)
    elseif kind == "Anchor" then
        part(0.45, 0.16, 0.10, 0.66, 0, c, 2)
        part(0.26, 0.32, 0.48, 0.09, 0, Theme.Colors.ACCENT_GOLD, 2)
        local base = part(0.22, 0.62, 0.56, 0.20, 0, c, 6)
        base.BackgroundTransparency = 0.2
    else
        local glyphMap = {
            Quest = "!",
            Map = "◈",
            Forge = "⚒",
            Raid = "❖",
            Settings = "⚙",
            Lock = "🔒",
            Check = "✓",
            Close = "×",
            Star = "★",
            Heart = "♥",
        }
        UIFactory.Label(holder, {
            Name = "Glyph",
            Text = glyphMap[kind] or "✦",
            Size = UDim2.fromScale(1, 1),
            TextSize = math.max(12, math.floor(px * 0.68)),
            TextColor = c,
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            Wrapped = false,
            ZIndex = 6,
        })
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

return UIFactory
