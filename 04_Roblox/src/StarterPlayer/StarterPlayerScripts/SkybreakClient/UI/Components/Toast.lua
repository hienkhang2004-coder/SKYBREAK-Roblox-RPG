-- SKYBREAK: Fragments of the Core — Non-Blocking Notification & Reward Toast
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Components/Toast.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Animations = require(script.Parent.Parent:WaitForChild("Animations"))

local Toast = {}

local KIND_COLORS = {
    info = Theme.Colors.ACCENT_SAPPHIRE,
    success = Theme.Colors.SUCCESS,
    warning = Theme.Colors.ACCENT_GOLD,
    error = Theme.Colors.HP_RED,
    reward = Theme.Colors.ACCENT_GOLD,
}

function Toast.Create(parent, props)
    props = props or {}
    local colors = Theme.Colors

    local holder = UIFactory.Create("Frame", parent, {
        Name = props.name or "ToastBanner",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = props.position or UDim2.new(0.5, 0, 0, 18),
        Size = props.size or UDim2.fromOffset(480, 48),
        BackgroundColor3 = colors.BG_800,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = props.zIndex or 50,
    })

    UIFactory.Corner(holder, Theme.Radius.Medium)
    local stroke = UIFactory.Stroke(holder, colors.ACCENT_GOLD, 1.5, 0.12)
    UIFactory.Gradient(holder, colors.BG_700, colors.BG_900, 90)

    local accentBar = UIFactory.Create("Frame", holder, {
        Name = "AccentStripe",
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(0, 5, 1, 0),
        BackgroundColor3 = colors.ACCENT_SAPPHIRE,
        BorderSizePixel = 0,
        ZIndex = holder.ZIndex + 1,
    })
    UIFactory.Corner(accentBar, 4)

    local textLabel = UIFactory.Label(holder, {
        Name = "ToastMessage",
        Text = "",
        Position = UDim2.fromOffset(18, 4),
        Size = UDim2.new(1, -30, 1, -8),
        TextSize = 14,
        TextColor = colors.TEXT_PRIMARY,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        ZIndex = holder.ZIndex + 2,
    })

    local latestToken = 0

    local api = {
        Instance = holder,
        TextLabel = textLabel,
    }

    function api:Show(message, kind, duration)
        latestToken += 1
        local myToken = latestToken
        local accent = KIND_COLORS[kind or "info"] or colors.ACCENT_SAPPHIRE

        stroke.Color = accent
        accentBar.BackgroundColor3 = accent
        textLabel.Text = tostring(message or "")
        holder.Visible = true

        local basePos = props.position or UDim2.new(0.5, 0, 0, 18)
        Animations.FadeInPanel(holder, basePos, Theme.Motion.Reward, "Toast")

        task.delay(duration or 2.8, function()
            if latestToken == myToken and holder and holder.Parent then
                holder.Visible = false
            end
        end)
    end

    function api:Update(state)
        if state and state.message then
            api:Show(state.message, state.kind, state.duration)
        end
    end

    function api:Destroy()
        Animations.CleanupScope("Toast")
        if holder and holder.Parent then
            holder:Destroy()
        end
    end

    return holder, api
end

Toast.create = Toast.Create

return Toast
