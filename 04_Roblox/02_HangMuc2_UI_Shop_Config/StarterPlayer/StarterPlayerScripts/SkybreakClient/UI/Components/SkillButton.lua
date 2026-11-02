-- SKYBREAK: Fragments of the Core — Vivid Glossy Tactile RPG Skill Card Component
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Components/SkillButton.lua
-- Matches SKYBREAK_Figma_v2_01_ActionRPG_HUD.png & SKYBREAK_Figma_v2_03_Design_System.png 1:1.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local AssetManifest = require(Shared:WaitForChild("AssetManifest"))
local SpritePlayer = require(Shared:WaitForChild("SpritePlayer"))
local UIAnimator = require(Shared:WaitForChild("UIAnimator"))
local MotionTokens = require(Shared:WaitForChild("MotionTokens"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))

local SkillButton = {}

local PALETTES = {
    sapphire = {
        Top = Color3.fromRGB(56, 189, 248),
        Bottom = Color3.fromRGB(29, 78, 216),
        Border = Color3.fromRGB(147, 224, 255),
    },
    cyan = {
        Top = Color3.fromRGB(34, 211, 238),
        Bottom = Color3.fromRGB(3, 105, 161),
        Border = Color3.fromRGB(165, 243, 252),
    },
    gold = {
        Top = Color3.fromRGB(250, 206, 88),
        Bottom = Color3.fromRGB(180, 83, 9),
        Border = Color3.fromRGB(255, 242, 166),
    },
    mythic = {
        Top = Color3.fromRGB(251, 113, 133),
        Bottom = Color3.fromRGB(147, 51, 234),
        Border = Color3.fromRGB(255, 190, 224),
    },
    slate = {
        Top = Color3.fromRGB(58, 76, 110),
        Bottom = Color3.fromRGB(20, 30, 50),
        Border = Color3.fromRGB(130, 156, 196),
    },
    crimson = {
        Top = Color3.fromRGB(251, 58, 100),
        Bottom = Color3.fromRGB(159, 18, 57),
        Border = Color3.fromRGB(255, 172, 192),
    },
}

local function formatKeyTag(rawKey, explicitTag)
    if type(explicitTag) == "string" and explicitTag ~= "" then
        return explicitTag
    end
    local k = tostring(rawKey or "1")
    if string.sub(k, 1, 1) == "[" then
        return k
    end
    return "[" .. k .. "]"
end

function SkillButton.Create(parent, props)
    props = props or {}
    local colors = Theme.Colors
    local isUltimate = props.isUltimate == true
    local paletteName = tostring(props.palette or (isUltimate and "gold" or "sapphire"))
    local pal = PALETTES[paletteName] or PALETTES.sapphire

    local btnSize = props.size or UDim2.fromOffset(64, 68)
    local isCompact = (btnSize.X.Offset > 0 and btnSize.X.Offset <= 68)

    -- Pure white BackgroundColor3 so UIGradient renders 100% vivid Figma colors
    local btn = UIFactory.Create("TextButton", parent, {
        Name = props.name or ("Skill_" .. tostring(props.skillId or "Slot")),
        AnchorPoint = props.anchorPoint or Vector2.zero,
        Position = props.position or UDim2.fromOffset(0, 0),
        Size = btnSize,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.02,
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

    local radius = isCompact and 9 or 10
    UIFactory.Corner(btn, radius)
    local stroke = UIFactory.Stroke(btn, pal.Border, isUltimate and 2.2 or 1.8, 0.04)
    local bgGrad = UIFactory.Gradient(btn, pal.Top, pal.Bottom, 90)

    -- Bottom 3px dark 3D bevel lip
    local bottomLip = UIFactory.Create("Frame", btn, {
        Name = "BottomBevelLip",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 2, 1, -1),
        Size = UDim2.new(1, -4, 0, 3),
        BackgroundColor3 = Color3.fromRGB(6, 10, 20),
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Active = false,
        ZIndex = btn.ZIndex + 1,
    })
    UIFactory.Corner(bottomLip, math.max(3, radius - 2))

    -- Top 40% curved glossy sheen
    local topGloss = UIFactory.Create("Frame", btn, {
        Name = "TopGloss",
        Position = UDim2.fromOffset(3, 2),
        Size = UDim2.new(1, -6, 0.40, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Active = false,
        ZIndex = btn.ZIndex + 1,
    })
    UIFactory.Corner(topGloss, math.max(3, radius - 2))
    UIFactory.Create("UIGradient", topGloss, {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.72),
            NumberSequenceKeypoint.new(0.65, 0.89),
            NumberSequenceKeypoint.new(1, 0.98),
        }),
    })

    -- Subtle radial glow disc behind central skill icon
    local auraDisc = UIFactory.Create("Frame", btn, {
        Name = "AuraDisc",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.44),
        Size = UDim2.fromOffset(isCompact and 30 or 34, isCompact and 30 or 34),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.84,
        BorderSizePixel = 0,
        Active = false,
        ZIndex = btn.ZIndex + 1,
    })
    UIFactory.PillCorner(auraDisc)

    local ultRing = nil
    if isUltimate then
        ultRing = UIFactory.Create("ImageLabel", btn, {
            Name = "UltimateRing",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, 0, 0.44, 0),
            Size = UDim2.fromOffset(54, 54),
            BackgroundTransparency = 1,
            Visible = true,
            ZIndex = btn.ZIndex + 2,
        })
    end

    local iconSz = isCompact and 25 or 28
    local centerIcon = UIFactory.Icon(
        btn,
        props.icon or "Sword",
        UDim2.new(0.5, -math.floor(iconSz * 0.5), 0.43, -math.floor(iconSz * 0.5)),
        iconSz,
        Color3.fromRGB(250, 252, 255)
    )
    centerIcon.ZIndex = btn.ZIndex + 3

    -- Top-left dark obsidian keybind pill ([Z], [X], [V] TRÁI, etc.)
    local keyPill = UIFactory.Create("Frame", btn, {
        Name = "KeyPill",
        Position = UDim2.fromOffset(4, 4),
        Size = UDim2.fromOffset(0, 14),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = Color3.fromRGB(9, 13, 24),
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        ZIndex = btn.ZIndex + 6,
    })
    UIFactory.Corner(keyPill, 4)
    UIFactory.Padding(keyPill, 0, 5, 0, 5)

    local keyLabel = UIFactory.Label(keyPill, {
        Name = "Key",
        Text = formatKeyTag(props.keybind, props.keyTag),
        Size = UDim2.fromOffset(0, 14),
        TextSize = 9,
        TextColor = Color3.fromRGB(246, 249, 255),
        Bold = true,
        Wrapped = false,
        ZIndex = btn.ZIndex + 7,
    })
    keyLabel.AutomaticSize = Enum.AutomaticSize.X

    local costValue = tonumber(props.energyCost) or 0
    if costValue > 0 and not isCompact then
        UIFactory.Label(btn, {
            Name = "Cost",
            Text = tostring(costValue),
            Position = UDim2.new(1, -28, 0, 4),
            Size = UDim2.fromOffset(24, 14),
            TextSize = 9,
            TextColor = Color3.fromRGB(232, 246, 255),
            Bold = true,
            XAlign = Enum.TextXAlignment.Right,
            Wrapped = false,
            ZIndex = btn.ZIndex + 6,
        })
    end

    -- Dark obsidian bottom caption pill (Trảm Không, Thiên Phạt, Thái Dương, etc.)
    local footerH = isCompact and 16 or 18
    local captionPill = UIFactory.Create("Frame", btn, {
        Name = "CaptionPill",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 3, 1, -3),
        Size = UDim2.new(1, -6, 0, footerH),
        BackgroundColor3 = Color3.fromRGB(9, 13, 24),
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        ZIndex = btn.ZIndex + 6,
    })
    UIFactory.Corner(captionPill, 5)

    local captionLabel = UIFactory.Label(captionPill, {
        Name = "Caption",
        Text = props.label or props.skillId or "Skill",
        Position = UDim2.fromOffset(3, 0),
        Size = UDim2.new(1, -6, 1, 0),
        TextSize = isCompact and 9 or 10,
        TextColor = Color3.fromRGB(248, 250, 255),
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = btn.ZIndex + 7,
    })

    -- Indigo-obsidian cooldown veil (matches [X] 2.4s in Figma HUD & Design System)
    local cdOverlay = UIFactory.Create("Frame", btn, {
        Name = "CooldownOverlay",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.fromScale(0, 1),
        Size = UDim2.fromScale(1, 0),
        BackgroundColor3 = Color3.fromRGB(16, 15, 38),
        BackgroundTransparency = 0.14,
        BorderSizePixel = 0,
        ZIndex = btn.ZIndex + 4,
    })
    UIFactory.Corner(cdOverlay, radius)

    local lockIcon = UIFactory.Icon(btn, "Lock", UDim2.new(0.5, -10, 0.43, -10), 20, colors.TEXT_SECONDARY)
    lockIcon.Visible = false
    lockIcon.ZIndex = btn.ZIndex + 5

    local cdText = UIFactory.Label(btn, {
        Name = "Cooldown",
        Text = "",
        Position = UDim2.fromOffset(0, 16),
        Size = UDim2.new(1, 0, 1, -(footerH + 18)),
        TextSize = isCompact and 14 or 15,
        TextColor = Color3.fromRGB(132, 224, 255),
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
        if newState.palette and PALETTES[newState.palette] then
            pal = PALETTES[newState.palette]
            bgGrad.Color = ColorSequence.new(pal.Top, pal.Bottom)
        end
        if newState.label ~= nil then
            captionLabel.Text = newState.label
        end
        if newState.keyTag ~= nil then
            keyLabel.Text = tostring(newState.keyTag)
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
            centerIcon.Visible = false
            local lbl = tostring(newState.lockLabel or "")
            if lbl ~= "" and lbl ~= "LOCK" then
                lockIcon.Visible = false
                cdText.Text = lbl
                cdText.TextSize = 11
            else
                lockIcon.Visible = true
                cdText.Text = ""
            end
            cdText.TextColor3 = colors.TEXT_SECONDARY
            captionLabel.TextColor3 = colors.TEXT_MUTED
            stroke.Color = Color3.fromRGB(68, 84, 114)
        elseif state.cooldown > 0 then
            lockIcon.Visible = false
            centerIcon.Visible = false
            local ratio = math.clamp(state.cooldown / state.maxCooldown, 0, 1)
            cdOverlay.Size = UDim2.fromScale(1, math.max(0.75, ratio))
            cdText.TextSize = isCompact and 14 or 15
            cdText.Text = string.format("%.1fs", state.cooldown)
            cdText.TextColor3 = Color3.fromRGB(132, 224, 255)
            captionLabel.TextColor3 = colors.TEXT_MUTED
            stroke.Color = Color3.fromRGB(76, 86, 136)
        elseif state.outOfEnergy then
            lockIcon.Visible = false
            centerIcon.Visible = true
            cdOverlay.Size = UDim2.fromScale(1, 0.42)
            cdText.TextSize = 10
            cdText.Text = "LOW EN"
            cdText.TextColor3 = colors.HP_RED
            captionLabel.TextColor3 = colors.TEXT_PRIMARY
            stroke.Color = colors.HP_RED
        else
            lockIcon.Visible = false
            centerIcon.Visible = true
            cdOverlay.Size = UDim2.fromScale(1, 0)
            cdText.Text = ""
            captionLabel.TextColor3 = Color3.fromRGB(248, 250, 255)
            stroke.Color = isUltimate and colors.ACCENT_GOLD_BRIGHT or pal.Border
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
