-- SKYBREAK: Fragments of the Core — Upgraded Theme Bridge
-- Location: StarterPlayer/StarterPlayerScripts/UI/Theme.lua
-- Bridges legacy T.* helper calls with the canonical Celestial Obsidian / Sapphire / Champagne Gold tokens.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SharedTheme = require(ReplicatedStorage:WaitForChild("SkybreakShared"):WaitForChild("Config"):WaitForChild("Theme"))

local T = {}
T.Tokens = SharedTheme

T.Color = {
    Ink = SharedTheme.Colors.BG_900,
    Panel = SharedTheme.Colors.BG_800,
    PanelHover = SharedTheme.Colors.BG_700,
    Glass = SharedTheme.Colors.SURFACE_GLASS,
    Blue = SharedTheme.Colors.ACCENT_DEEP_BLUE,
    Cyan = SharedTheme.Colors.ACCENT_SAPPHIRE,
    Gold = SharedTheme.Colors.ACCENT_GOLD,
    White = SharedTheme.Colors.TEXT_PRIMARY,
    Muted = SharedTheme.Colors.TEXT_SECONDARY,
    Red = SharedTheme.Colors.HP_RED,
    Line = SharedTheme.Colors.STROKE_STEEL,
    Purple = SharedTheme.Colors.VOID_PURPLE,
    Green = SharedTheme.Colors.SUCCESS,
}

function T.New(class, parent, props)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do
        o[k] = v
    end
    o.Parent = parent
    return o
end

function T.Corner(o, r)
    T.New("UICorner", o, { CornerRadius = UDim.new(0, r or SharedTheme.Radius.Medium) })
end

function T.Stroke(o, color, width, transparency)
    return T.New("UIStroke", o, {
        Color = color or T.Color.Line,
        Thickness = width or 1.5,
        Transparency = transparency or SharedTheme.Stroke.AlphaDefault,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    })
end

function T.Gradient(o, top, bottom)
    if o:IsA("TextButton") then
        local bg = T.New("Frame", o, {
            Name = "ButtonSurface",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            ZIndex = math.max(0, o.ZIndex - 1),
        })
        T.Corner(bg, 8)
        o.BackgroundTransparency = 1
        o = bg
    end
    T.New("UIGradient", o, { Color = ColorSequence.new(top, bottom), Rotation = 90 })
end

function T.Panel(parent, name, x, y, w, h, accent)
    local o = T.New("Frame", parent, {
        Name = name,
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(w, h),
        BackgroundColor3 = T.Color.Panel,
        BackgroundTransparency = SharedTheme.Transparency.Panel,
        BorderSizePixel = 0,
    })
    T.Corner(o, SharedTheme.Radius.Large)
    T.Stroke(o, accent or T.Color.Line, 1.4, SharedTheme.Stroke.AlphaDefault)
    T.Gradient(o, T.Color.PanelHover, T.Color.Ink)
    return o
end

function T.Text(parent, name, value, x, y, w, h, size, color, bold)
    return T.New("TextLabel", parent, {
        Name = name,
        Text = value,
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(w, h),
        BackgroundTransparency = 1,
        TextSize = size or 16,
        TextColor3 = color or T.Color.White,
        Font = bold and Enum.Font.GothamBold or Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextWrapped = true,
    })
end

function T.Button(parent, name, value, x, y, w, h, callback, primary)
    local o = T.New("TextButton", parent, {
        Name = name,
        Text = "",
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(w, h),
        BackgroundColor3 = primary and T.Color.Blue or T.Color.Panel,
        TextColor3 = T.Color.White,
        TextSize = 16,
        Font = Enum.Font.GothamBold,
        BorderSizePixel = 0,
        AutoButtonColor = true,
    })
    T.Corner(o, 8)
    T.Stroke(o, primary and T.Color.Gold or T.Color.Line, primary and 1.8 or 1.2, primary and 0.12 or 0.32)
    T.Gradient(
        o,
        primary and T.Color.Cyan or T.Color.PanelHover,
        primary and T.Color.Blue or T.Color.Ink
    )
    local caption = T.Text(o, "ButtonLabel", value, 0, 0, w, h, 16, T.Color.White, true)
    caption.TextXAlignment = Enum.TextXAlignment.Center
    caption.ZIndex = o.ZIndex + 2
    if callback then
        o.Activated:Connect(callback)
    end
    return o
end

function T.SetButton(button, value)
    local caption = button:FindFirstChild("ButtonLabel")
    if caption then
        caption.Text = value
    else
        button.Text = value
    end
end

function T.Bar(parent, name, x, y, w, h, color)
    local bg = T.Panel(parent, name, x, y, w, h)
    local inner = T.New("Frame", bg, {
        Position = UDim2.fromOffset(3, 3),
        Size = UDim2.new(1, -6, 1, -6),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        BorderSizePixel = 0,
    })
    T.Corner(inner, 4)
    local fill = T.New("Frame", inner, {
        Name = "Fill",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
    })
    T.Corner(fill, 4)
    T.Gradient(fill, color, color:Lerp(Color3.new(0, 0, 0), 0.35))
    local label = T.Text(bg, "Value", "", 4, 1, w - 8, h - 2, 14, nil, true)
    label.TextXAlignment = Enum.TextXAlignment.Center
    return { Fill = fill, Text = label }
end

function T.SetBar(bar, value, max, label)
    bar.Fill.Size = UDim2.fromScale(math.clamp(value / math.max(1, max), 0, 1), 1)
    bar.Text.Text = label or (math.ceil(value) .. " / " .. math.ceil(max))
end

function T.Icon(parent, kind, x, y, size, color)
    local holder = T.New("Frame", parent, {
        Name = kind .. "Icon",
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(size, size),
        BackgroundTransparency = 1,
    })
    local c = color or T.Color.Cyan
    local function rect(px, py, w, h, rot, col)
        return T.New("Frame", holder, {
            Position = UDim2.fromScale(px, py),
            Size = UDim2.fromScale(w, h),
            Rotation = rot or 0,
            BackgroundColor3 = col or c,
            BorderSizePixel = 0,
        })
    end
    if kind == "Sword" then
        rect(0.45, 0.1, 0.13, 0.65, 38)
        rect(0.22, 0.62, 0.5, 0.09, 38, T.Color.Gold)
        rect(0.25, 0.72, 0.1, 0.23, 38, T.Color.Muted)
    elseif kind == "Shield" then
        local s = rect(0.22, 0.15, 0.58, 0.65, 0)
        T.Corner(s, size * 0.15)
        T.Stroke(s, T.Color.White, 1.5)
        rect(0.47, 0.2, 0.06, 0.5, 0, T.Color.White)
    elseif kind == "Gem" then
        local gem = rect(0.23, 0.23, 0.52, 0.52, 45)
        T.Stroke(gem, T.Color.White, 1.5)
        rect(0.48, 0.24, 0.025, 0.5, 0, T.Color.White)
    elseif kind == "Bag" then
        local b = rect(0.18, 0.31, 0.64, 0.52, 0)
        T.Corner(b, 5)
        local h = rect(0.35, 0.17, 0.3, 0.3, 0)
        T.Corner(h, 5)
        T.Stroke(h, T.Color.White, 2)
        h.BackgroundTransparency = 1
        rect(0.45, 0.49, 0.1, 0.17, 0, T.Color.Ink)
    elseif kind == "Plus" then
        rect(0.44, 0.17, 0.15, 0.68, 0)
        rect(0.17, 0.44, 0.68, 0.15, 0)
    elseif kind == "Bolt" then
        rect(0.47, 0.12, 0.16, 0.43, 25)
        rect(0.35, 0.45, 0.16, 0.43, 25)
    else
        local v = T.Text(
            holder,
            "Glyph",
            kind == "Quest" and "!" or (kind == "Dodge" and "»" or "✦"),
            0,
            0,
            size,
            size,
            math.floor(size * 0.75),
            c,
            true
        )
        v.TextXAlignment = Enum.TextXAlignment.Center
    end
    return holder
end

function T.Number(n)
    local s = tostring(math.floor(n or 0))
    local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    return formatted:gsub("^,", "")
end

return T
