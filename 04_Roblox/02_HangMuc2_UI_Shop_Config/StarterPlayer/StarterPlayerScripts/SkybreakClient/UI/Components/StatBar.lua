-- SKYBREAK: Fragments of the Core — Tweened Vitals & Progress Bar Component
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Components/StatBar.lua
-- Supports HP, Energy, Stamina, EXP, BossHP, Break Gauge with smooth width tweening.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Animations = require(script.Parent.Parent:WaitForChild("Animations"))

local StatBar = {}

local TYPE_COLORS = {
    HP = Theme.Colors.HP_RED,
    BossHP = Theme.Colors.HP_RED,
    Energy = Theme.Colors.ACCENT_SAPPHIRE,
    Stamina = Theme.Colors.ACCENT_SAPPHIRE,
    EXP = Theme.Colors.ACCENT_GOLD,
    Break = Theme.Colors.VOID_PURPLE,
    Success = Theme.Colors.SUCCESS,
}

function StatBar.Create(parent, props)
    props = props or {}
    local barType = props.type or "HP"
    local fillColor = props.color and Theme.GetColor(props.color)
        or TYPE_COLORS[barType]
        or Theme.Colors.ACCENT_SAPPHIRE

    local current = tonumber(props.current) or 100
    local maxVal = math.max(1, tonumber(props.max) or 100)
    local ratio = math.clamp(current / maxVal, 0, 1)

    local container = UIFactory.Create("Frame", parent, {
        Name = props.name or (barType .. "Bar"),
        Position = props.position or UDim2.fromOffset(0, 0),
        Size = props.size or UDim2.fromOffset(240, 26),
        BackgroundColor3 = Theme.Colors.BG_900,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        LayoutOrder = props.layoutOrder or 0,
        ZIndex = props.zIndex or 4,
    })

    UIFactory.Corner(container, props.cornerRadius or Theme.Radius.Small)
    UIFactory.Stroke(container, props.strokeColor or Theme.Colors.STROKE_STEEL, 1, 0.35)

    local inner = UIFactory.Create("Frame", container, {
        Name = "Track",
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.new(1, -4, 1, -4),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = container.ZIndex + 1,
    })
    UIFactory.Corner(inner, math.max(3, (props.cornerRadius or Theme.Radius.Small) - 2))

    -- Delayed Trail Fill (gives AAA RPG impact feedback when HP drops)
    local trailFill = UIFactory.Create("Frame", inner, {
        Name = "TrailFill",
        Size = UDim2.fromScale(ratio, 1),
        BackgroundColor3 = Theme.Colors.ACCENT_GOLD:Lerp(Theme.Colors.TEXT_PRIMARY, 0.35),
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        ZIndex = container.ZIndex + 1,
    })
    UIFactory.Corner(trailFill, 4)

    -- Primary Fill (named "Fill" to match Section 10.3 Humanoid binding specification)
    local fill = UIFactory.Create("Frame", inner, {
        Name = "Fill",
        Size = UDim2.fromScale(ratio, 1),
        BackgroundColor3 = fillColor,
        BorderSizePixel = 0,
        ZIndex = container.ZIndex + 2,
    })
    UIFactory.Corner(fill, 4)
    UIFactory.Gradient(fill, fillColor:Lerp(Color3.new(1, 1, 1), 0.14), fillColor:Lerp(Color3.new(0, 0, 0), 0.28), 90)

    local fillSpecular = UIFactory.Create("Frame", fill, {
        Name = "FillSpecular",
        Size = UDim2.new(1, 0, 0.38, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.80,
        BorderSizePixel = 0,
        ZIndex = container.ZIndex + 2,
    })
    UIFactory.Corner(fillSpecular, 3)

    for _, pct in ipairs({ 0.25, 0.50, 0.75 }) do
        UIFactory.Create("Frame", inner, {
            Name = "Tick_" .. tostring(math.floor(pct * 100)),
            Position = UDim2.fromScale(pct, 0),
            Size = UDim2.new(0, 1, 1, 0),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.55,
            BorderSizePixel = 0,
            ZIndex = container.ZIndex + 3,
        })
    end

    local function formatLabel(c, m, customText)
        if customText then
            return customText
        end
        local prefix = props.label and (props.label .. "  ") or ""
        return prefix .. UIFactory.FormatNumber(math.ceil(c)) .. " / " .. UIFactory.FormatNumber(math.ceil(m))
    end

    local valueLabel = UIFactory.Label(container, {
        Name = "Value",
        Text = formatLabel(current, maxVal, props.customText),
        Position = UDim2.fromOffset(8, 0),
        Size = UDim2.new(1, -16, 1, 0),
        TextSize = props.textSize or 13,
        TextColor = Theme.Colors.TEXT_PRIMARY,
        Bold = true,
        XAlign = props.textAlign or Enum.TextXAlignment.Center,
        Wrapped = false,
        ZIndex = container.ZIndex + 4,
    })

    local api = {
        Instance = container,
        Fill = fill,
        Trail = trailFill,
        Text = valueLabel,
        Current = current,
        Max = maxVal,
    }

    function api:Update(state)
        state = state or {}
        local newCurrent = tonumber(state.current or state.value) or api.Current
        local newMax = math.max(1, tonumber(state.max) or api.Max)
        api.Current = newCurrent
        api.Max = newMax

        local newRatio = math.clamp(newCurrent / newMax, 0, 1)
        Animations.TweenBar(fill, newRatio, Theme.Motion.HP, props.scope)
        Animations.TweenBar(trailFill, newRatio, Theme.Motion.HP * 1.65, props.scope)
        valueLabel.Text = formatLabel(newCurrent, newMax, state.customText or state.label)
    end

    function api:Destroy()
        if container and container.Parent then
            container:Destroy()
        end
    end

    return container, api
end

StatBar.create = StatBar.Create

return StatBar
