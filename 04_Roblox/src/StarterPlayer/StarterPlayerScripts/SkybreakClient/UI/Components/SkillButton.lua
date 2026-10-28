-- SKYBREAK: Fragments of the Core — Combat Ability Hotbar Slot Component
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Components/SkillButton.lua
-- States: Ready, Cooldown, OutOfEnergy, Locked, UltimateReady (Section 07, Section 09, Section 11).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local AssetManifest = require(Shared:WaitForChild("AssetManifest"))
local SpritePlayer = require(Shared:WaitForChild("SpritePlayer"))
local UIAnimator = require(Shared:WaitForChild("UIAnimator"))
local MotionTokens = require(Shared:WaitForChild("MotionTokens"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))

local SkillButton = {}

function SkillButton.Create(parent, props)
    props = props or {}
    local colors = Theme.Colors
    local isUltimate = props.isUltimate == true
    local accent = props.accentColor and Theme.GetColor(props.accentColor)
        or (isUltimate and colors.ACCENT_GOLD or colors.ACCENT_SAPPHIRE)

    local btn = UIFactory.Create("TextButton", parent, {
        Name = props.name or ("Skill_" .. tostring(props.skillId or "Slot")),
        Position = props.position or UDim2.fromOffset(0, 0),
        Size = props.size or UDim2.fromOffset(82, 76),
        BackgroundColor3 = colors.BG_800,
        BackgroundTransparency = 0.06,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = props.layoutOrder or 0,
        ZIndex = props.zIndex or 6,
    })

    local uiScale = Instance.new("UIScale")
    uiScale.Name = "UIScale"
    uiScale.Scale = 1.0
    uiScale.Parent = btn

    UIFactory.Corner(btn, Theme.Radius.Medium)
    local stroke = UIFactory.Stroke(btn, accent, isUltimate and 2.0 or 1.5, 0.15)
    UIFactory.Gradient(btn, colors.BG_700, colors.BG_900, 90)

    -- Section 09 & Section 11: 4x4 Sprite Sheet Ultimate Ring FX when Ultimate is Ready
    local ultRing = nil
    if isUltimate then
        ultRing = UIFactory.Create("ImageLabel", btn, {
            Name = "UltimateRing",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.42, 0),
            Size = UDim2.fromOffset(58, 58),
            BackgroundTransparency = 1,
            Visible = true,
            ZIndex = btn.ZIndex + 1,
        })
    end

    UIFactory.Icon(
        btn,
        props.icon or "Sword",
        UDim2.new(0.5, -16, 0, 12),
        32,
        accent
    )

    -- Keybind pill top-left
    local keyLabel = UIFactory.Label(btn, {
        Name = "Key",
        Text = props.keybind or "1",
        Position = UDim2.fromOffset(6, 4),
        Size = UDim2.fromOffset(32, 16),
        TextSize = 11,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
        Wrapped = false,
        ZIndex = btn.ZIndex + 3,
    })

    -- Energy / Stamina cost top-right
    local costValue = tonumber(props.energyCost) or 0
    UIFactory.Label(btn, {
        Name = "Cost",
        Text = costValue > 0 and tostring(costValue) or "",
        Position = UDim2.new(1, -34, 0, 4),
        Size = UDim2.fromOffset(28, 16),
        TextSize = 11,
        TextColor = colors.ACCENT_SAPPHIRE,
        Bold = true,
        XAlign = Enum.TextXAlignment.Right,
        Wrapped = false,
        ZIndex = btn.ZIndex + 3,
    })

    -- Caption at bottom
    local captionLabel = UIFactory.Label(btn, {
        Name = "Caption",
        Text = props.label or props.skillId or "Skill",
        Position = UDim2.new(0, 4, 1, -20),
        Size = UDim2.new(1, -8, 0, 18),
        TextSize = 11,
        TextColor = colors.TEXT_PRIMARY,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = btn.ZIndex + 3,
    })

    -- Cooldown Dark Curtain Overlay
    local cdOverlay = UIFactory.Create("Frame", btn, {
        Name = "CooldownOverlay",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.fromScale(1, 0),
        BackgroundColor3 = colors.BG_900,
        BackgroundTransparency = 0.22,
        BorderSizePixel = 0,
        ZIndex = btn.ZIndex + 4,
    })
    UIFactory.Corner(cdOverlay, Theme.Radius.Medium)

    -- Cooldown / Lock Center Text
    local cdText = UIFactory.Label(btn, {
        Name = "Cooldown",
        Text = "",
        Position = UDim2.fromOffset(0, 8),
        Size = UDim2.new(1, 0, 0, 44),
        TextSize = 18,
        TextColor = colors.TEXT_PRIMARY,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Wrapped = false,
        ZIndex = btn.ZIndex + 5,
    })

    local state = {
        locked = props.locked == true,
        cooldown = 0,
        maxCooldown = math.max(0.1, tonumber(props.maxCooldown) or 6),
        outOfEnergy = false,
        ultAnimPlaying = false,
    }

    btn.MouseEnter:Connect(function()
        if not state.locked then
            UIAnimator.Tween(uiScale, { Scale = 1.05 }, MotionTokens.hoverFast.duration)
        end
    end)

    btn.MouseLeave:Connect(function()
        UIAnimator.Tween(uiScale, { Scale = 1.0 }, MotionTokens.hoverFast.duration)
    end)

    btn.InputBegan:Connect(function(input)
        if not state.locked and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            UIAnimator.Tween(uiScale, { Scale = 0.94 }, MotionTokens.press.duration)
        end
    end)

    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            UIAnimator.Tween(uiScale, { Scale = 1.0 }, MotionTokens.rebound.duration, MotionTokens.rebound.style, MotionTokens.rebound.direction)
        end
    end)

    btn.Activated:Connect(function()
        if state.locked or state.cooldown > 0 then
            return
        end
        if type(props.onActivated) == "function" then
            props.onActivated(props.skillId)
        end
    end)

    local api = {
        Instance = btn,
        CooldownLabel = cdText,
        CaptionLabel = captionLabel,
        KeyLabel = keyLabel,
        UltimateRing = ultRing,
    }

    function api:Update(newState)
        newState = newState or {}
        if newState.label ~= nil then
            captionLabel.Text = newState.label
        end
        if newState.locked ~= nil then
            state.locked = newState.locked == true
        end
        if newState.cooldown ~= nil then
            state.cooldown = math.max(0, tonumber(newState.cooldown) or 0)
        end
        if newState.maxCooldown ~= nil then
            state.maxCooldown = math.max(0.1, tonumber(newState.maxCooldown) or 6)
        end
        if newState.outOfEnergy ~= nil then
            state.outOfEnergy = newState.outOfEnergy == true
        end

        local ultReady = isUltimate and (not state.locked) and (state.cooldown <= 0) and (not state.outOfEnergy)
        if ultRing then
            ultRing.Visible = ultReady
            if ultReady and not state.ultAnimPlaying then
                state.ultAnimPlaying = true
                SpritePlayer.Play(ultRing, AssetManifest.UltimateAtlas, 4, 4, 256, 256, 16, 16)
            elseif not ultReady and state.ultAnimPlaying then
                state.ultAnimPlaying = false
                SpritePlayer.Stop(ultRing)
            end
        end

        if state.locked then
            cdOverlay.Size = UDim2.fromScale(1, 1)
            cdText.Text = newState.lockLabel or "🔒"
            cdText.TextColor3 = colors.TEXT_SECONDARY
            stroke.Color = colors.STROKE_STEEL
        elseif state.cooldown > 0 then
            local ratio = math.clamp(state.cooldown / state.maxCooldown, 0, 1)
            cdOverlay.Size = UDim2.fromScale(1, ratio)
            cdText.Text = string.format("%.1f", state.cooldown)
            cdText.TextColor3 = colors.TEXT_PRIMARY
            stroke.Color = colors.STROKE_STEEL
        elseif state.outOfEnergy then
            cdOverlay.Size = UDim2.fromScale(1, 0.35)
            cdText.Text = "LOW EN"
            cdText.TextColor3 = colors.HP_RED
            stroke.Color = colors.HP_RED
        else
            cdOverlay.Size = UDim2.fromScale(1, 0)
            cdText.Text = ""
            stroke.Color = isUltimate and colors.ACCENT_GOLD or accent
        end
    end

    function api:Destroy()
        if ultRing then
            SpritePlayer.Stop(ultRing)
        end
        if btn and btn.Parent then
            btn:Destroy()
        end
    end

    api:Update(props)
    return btn, api
end

SkillButton.create = SkillButton.Create

return SkillButton
