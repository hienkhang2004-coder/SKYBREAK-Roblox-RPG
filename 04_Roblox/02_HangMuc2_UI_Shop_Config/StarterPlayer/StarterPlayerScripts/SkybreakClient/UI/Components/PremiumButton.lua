-- SKYBREAK: Fragments of the Core — Reusable Tactile 3D Glossy Button Component
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Components/PremiumButton.lua
-- Supports 6 variants ("primary" | "secondary" | "gold" | "danger" | "emerald" | "mythic"),
-- 5 interactive states, UIScale + UIStroke micro-interactions, top specular gloss sheen + bottom 3D bevel lip.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local UIAssets = require(Shared:WaitForChild("Config"):WaitForChild("UIAssets"))
local UIAnimator = require(Shared:WaitForChild("UIAnimator"))
local MotionTokens = require(Shared:WaitForChild("MotionTokens"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))

local PremiumButton = {}

local VARIANT_STYLES = {
    primary = function(colors)
        return {
            bgTop = Color3.fromRGB(76, 194, 255),
            bgBottom = Color3.fromRGB(26, 92, 220),
            hoverTop = Color3.fromRGB(108, 212, 255),
            hoverBottom = Color3.fromRGB(36, 114, 240),
            pressTop = Color3.fromRGB(38, 128, 206),
            pressBottom = Color3.fromRGB(18, 64, 168),
            strokeColor = Color3.fromRGB(168, 236, 255),
            textColor = Color3.fromRGB(250, 253, 255),
            assetKey = "ButtonPrimary",
        }
    end,
    gold = function(colors)
        return {
            bgTop = Color3.fromRGB(249, 209, 104),
            bgBottom = Color3.fromRGB(194, 136, 36),
            hoverTop = Color3.fromRGB(255, 224, 132),
            hoverBottom = Color3.fromRGB(214, 154, 46),
            pressTop = Color3.fromRGB(206, 162, 66),
            pressBottom = Color3.fromRGB(152, 102, 24),
            strokeColor = Color3.fromRGB(255, 242, 178),
            textColor = Color3.fromRGB(12, 17, 29),
            assetKey = "ButtonPrimary",
        }
    end,
    secondary = function(colors)
        return {
            bgTop = Color3.fromRGB(32, 48, 78),
            bgBottom = Color3.fromRGB(15, 24, 42),
            hoverTop = Color3.fromRGB(44, 66, 104),
            hoverBottom = Color3.fromRGB(20, 32, 56),
            pressTop = Color3.fromRGB(18, 28, 48),
            pressBottom = colors.BG_900,
            strokeColor = Color3.fromRGB(78, 108, 152),
            textColor = colors.TEXT_PRIMARY,
            assetKey = "ButtonSecondary",
        }
    end,
    danger = function(_colors)
        return {
            bgTop = Color3.fromRGB(251, 58, 100),
            bgBottom = Color3.fromRGB(178, 22, 60),
            hoverTop = Color3.fromRGB(255, 88, 124),
            hoverBottom = Color3.fromRGB(204, 32, 74),
            pressTop = Color3.fromRGB(198, 34, 72),
            pressBottom = Color3.fromRGB(136, 16, 46),
            strokeColor = Color3.fromRGB(255, 172, 192),
            textColor = Color3.fromRGB(255, 250, 252),
            assetKey = "ButtonDanger",
        }
    end,
    emerald = function(_colors)
        return {
            bgTop = Color3.fromRGB(36, 212, 106),
            bgBottom = Color3.fromRGB(18, 126, 60),
            hoverTop = Color3.fromRGB(64, 232, 130),
            hoverBottom = Color3.fromRGB(24, 150, 74),
            pressTop = Color3.fromRGB(24, 164, 80),
            pressBottom = Color3.fromRGB(12, 96, 46),
            strokeColor = Color3.fromRGB(148, 248, 190),
            textColor = Color3.fromRGB(248, 255, 251),
            assetKey = "ButtonPrimary",
        }
    end,
    mythic = function(_colors)
        return {
            bgTop = Color3.fromRGB(251, 113, 133),
            bgBottom = Color3.fromRGB(147, 51, 234),
            hoverTop = Color3.fromRGB(255, 138, 158),
            hoverBottom = Color3.fromRGB(168, 72, 248),
            pressTop = Color3.fromRGB(214, 82, 108),
            pressBottom = Color3.fromRGB(118, 36, 196),
            strokeColor = Color3.fromRGB(255, 190, 220),
            textColor = Color3.fromRGB(255, 250, 255),
            assetKey = "ButtonPrimary",
        }
    end,
}

function PremiumButton.Create(parent, props)
    props = props or {}
    local colors = Theme.Colors
    local variantName = props.variant or "primary"
    local styleBuilder = VARIANT_STYLES[variantName] or VARIANT_STYLES.primary
    local style = styleBuilder(colors)

    local disabled = props.disabled == true
    local selected = props.selected == true
    local radius = tonumber(props.cornerRadius) or Theme.Radius.Medium

    -- Keep BackgroundColor3 = white when enabled so UIGradient renders 100% pure Figma saturation
    local btn = UIFactory.Create("TextButton", parent, {
        Name = props.name or "PremiumButton",
        Position = props.position or UDim2.fromOffset(0, 0),
        Size = props.size or UDim2.fromOffset(160, 42),
        AnchorPoint = props.anchorPoint or Vector2.zero,
        BackgroundColor3 = disabled and colors.BG_800 or Color3.new(1, 1, 1),
        BackgroundTransparency = disabled and 0.32 or (props.transparency or 0.02),
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = props.layoutOrder or 0,
        ZIndex = props.zIndex or 3,
        Visible = props.visible ~= false,
    })

    local uiScale = Instance.new("UIScale")
    uiScale.Name = "UIScale"
    uiScale.Scale = 1.0
    uiScale.Parent = btn

    UIFactory.Corner(btn, radius)
    local stroke = UIFactory.Stroke(
        btn,
        selected and colors.ACCENT_GOLD_BRIGHT or (disabled and colors.TEXT_MUTED or style.strokeColor),
        selected and 2.0 or 1.4,
        disabled and 0.65 or 0.12
    )

    local grad = UIFactory.Gradient(
        btn,
        disabled and colors.BG_800 or (selected and style.hoverTop or style.bgTop),
        disabled and colors.BG_900 or (selected and style.hoverBottom or style.bgBottom),
        90
    )

    -- Tactile 2px bottom inner 3D shadow lip
    local bottomLip = UIFactory.Create("Frame", btn, {
        Name = "BottomBevelLip",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 3, 1, -1),
        Size = UDim2.new(1, -6, 0, 2),
        BackgroundColor3 = Color3.fromRGB(5, 8, 16),
        BackgroundTransparency = 0.50,
        BorderSizePixel = 0,
        Active = false,
        ZIndex = btn.ZIndex + 1,
    })
    UIFactory.Corner(bottomLip, math.max(2, radius - 2))

    -- Tactile curved top specular gloss sheen (Figma File 1 Section 2)
    local topGloss = UIFactory.Create("Frame", btn, {
        Name = "TopGloss",
        Position = UDim2.fromOffset(3, 2),
        Size = UDim2.new(1, -6, 0.45, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0,
        BorderSizePixel = 0,
        Active = false,
        ZIndex = btn.ZIndex + 1,
    })
    UIFactory.Corner(topGloss, math.max(3, radius - 2))
    UIFactory.Create("UIGradient", topGloss, {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.74),
            NumberSequenceKeypoint.new(0.65, 0.88),
            NumberSequenceKeypoint.new(1, 0.97),
        }),
    })

    local assetId = UIAssets.ButtonNineSlice
    if UIAssets.IsValidAssetId and UIAssets.IsValidAssetId(assetId) then
        local sliceRect = (UIAssets.NineSliceRects and UIAssets.NineSliceRects.Button) or Rect.new(12, 12, 52, 52)
        UIFactory.Create("ImageLabel", btn, {
            Name = "NineSliceSkin",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Image = assetId,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = sliceRect,
            SliceScale = 1,
            ZIndex = btn.ZIndex,
        })
    end

    local textOffsetLeft = props.icon and 32 or 10
    local iconHolder = nil
    local lastIconColor = disabled and colors.TEXT_MUTED or style.textColor
    if props.icon then
        iconHolder = UIFactory.Icon(
            btn,
            props.icon,
            UDim2.new(0, 9, 0.5, -9),
            18,
            lastIconColor
        )
        iconHolder.ZIndex = btn.ZIndex + 2
    end

    local function syncIconColor(targetCol)
        if not iconHolder or lastIconColor == targetCol then
            return
        end
        for _, desc in ipairs(iconHolder:GetDescendants()) do
            if desc:IsA("ImageLabel") then
                desc.ImageColor3 = targetCol
            elseif desc:IsA("Frame") and desc.BackgroundColor3 == lastIconColor then
                desc.BackgroundColor3 = targetCol
            elseif desc:IsA("UIStroke") and desc.Color == lastIconColor then
                desc.Color = targetCol
            end
        end
        lastIconColor = targetCol
    end

    local maxTextSz = props.textSize or Theme.TextSize.Body
    local minTextSz = props.minTextSize or math.min(10, maxTextSz)
    local useAutoFit = (props.constrainText ~= false)

    local label = UIFactory.Label(btn, {
        Name = "Label",
        Text = props.label or props.text or "BUTTON",
        Position = UDim2.fromOffset(textOffsetLeft, 2),
        Size = UDim2.new(1, -(textOffsetLeft + 10), 1, -4),
        TextSize = maxTextSz,
        TextColor = disabled and colors.TEXT_MUTED or style.textColor,
        Font = Theme.Fonts.Heading,
        Bold = true,
        XAlign = props.icon and Enum.TextXAlignment.Left or (props.xAlign or Enum.TextXAlignment.Center),
        YAlign = Enum.TextYAlignment.Center,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = btn.ZIndex + 2,
    })
    if useAutoFit then
        label.TextScaled = true
        UIFactory.TextSizeConstraint(label, minTextSz, maxTextSz)
    end

    local isHovered = false
    local isDisabled = disabled
    local isSelected = selected

    local function syncVisuals(stateName)
        if isDisabled then
            btn.BackgroundColor3 = colors.BG_800
            grad.Color = ColorSequence.new(colors.BG_800, colors.BG_900)
            label.TextColor3 = colors.TEXT_MUTED
            syncIconColor(colors.TEXT_MUTED)
            stroke.Color = colors.TEXT_MUTED
            stroke.Transparency = 0.65
            topGloss.Visible = false
            uiScale.Scale = 1.0
            return
        end

        topGloss.Visible = true
        btn.BackgroundColor3 = Color3.new(1, 1, 1)
        local cTop = isSelected and style.hoverTop or style.bgTop
        local cBot = isSelected and style.hoverBottom or style.bgBottom
        local targetStroke = isSelected and colors.ACCENT_GOLD_BRIGHT or style.strokeColor
        local targetStrokeTrans = isSelected and 0.02 or 0.12

        if stateName == "Hover" then
            cTop = style.hoverTop
            cBot = style.hoverBottom
            targetStroke = colors.ACCENT_GOLD_BRIGHT
            targetStrokeTrans = 0.0
            UIAnimator.Tween(
                uiScale,
                { Scale = 1.035 },
                MotionTokens.hoverFast.duration,
                MotionTokens.hoverFast.style,
                MotionTokens.hoverFast.direction
            )
        elseif stateName == "Pressed" then
            cTop = style.pressTop
            cBot = style.pressBottom
            targetStrokeTrans = 0.0
            UIAnimator.Tween(
                uiScale,
                { Scale = 0.96 },
                MotionTokens.press.duration,
                MotionTokens.press.style,
                MotionTokens.press.direction
            )
        elseif stateName == "Rebound" then
            UIAnimator.Tween(
                uiScale,
                { Scale = isHovered and 1.035 or 1.0 },
                MotionTokens.rebound.duration,
                MotionTokens.rebound.style,
                MotionTokens.rebound.direction
            )
        else
            UIAnimator.Tween(
                uiScale,
                { Scale = 1.0 },
                MotionTokens.hoverFast.duration,
                MotionTokens.hoverFast.style,
                MotionTokens.hoverFast.direction
            )
        end

        grad.Color = ColorSequence.new(cTop, cBot)
        UIAnimator.Tween(stroke, {
            Color = targetStroke,
            Transparency = targetStrokeTrans,
            Thickness = isSelected and 2.0 or 1.4,
        }, MotionTokens.hoverFast.duration)
        label.TextColor3 = style.textColor
        syncIconColor(style.textColor)
    end

    btn.MouseEnter:Connect(function()
        isHovered = true
        if not isDisabled then
            syncVisuals("Hover")
        end
        if type(props.onHover) == "function" then
            props.onHover(true, btn)
        end
    end)

    btn.MouseLeave:Connect(function()
        isHovered = false
        if not isDisabled then
            syncVisuals("Idle")
        end
        if type(props.onHover) == "function" then
            props.onHover(false, btn)
        end
    end)

    btn.InputBegan:Connect(function(input)
        if isDisabled then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            syncVisuals("Pressed")
        end
    end)

    btn.InputEnded:Connect(function(input)
        if isDisabled then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            syncVisuals("Rebound")
        end
    end)

    btn.Activated:Connect(function()
        if isDisabled then
            return
        end
        syncVisuals("Rebound")
        if type(props.onActivated) == "function" then
            props.onActivated()
        elseif type(props.onClick) == "function" then
            props.onClick()
        end
    end)

    local api = {
        Instance = btn,
        Label = label,
        Stroke = stroke,
        Gradient = grad,
        Scale = uiScale,
    }

    function api:SetLabel(newText)
        label.Text = tostring(newText or "")
    end

    function api:SetDisabled(flag)
        isDisabled = flag == true
        syncVisuals("Idle")
    end

    function api:SetSelected(flag)
        isSelected = flag == true
        syncVisuals(isHovered and "Hover" or "Idle")
    end

    function api:SetVariant(newVariantName)
        if type(newVariantName) == "string" and VARIANT_STYLES[newVariantName] then
            variantName = newVariantName
            styleBuilder = VARIANT_STYLES[variantName]
            style = styleBuilder(colors)
            syncVisuals(isHovered and "Hover" or "Idle")
        end
    end

    function api:Update(newProps)
        if not newProps then
            return
        end
        if newProps.variant ~= nil then
            api:SetVariant(newProps.variant)
        end
        if newProps.label ~= nil or newProps.text ~= nil then
            api:SetLabel(newProps.label or newProps.text)
        end
        if newProps.disabled ~= nil then
            api:SetDisabled(newProps.disabled)
        end
        if newProps.selected ~= nil then
            api:SetSelected(newProps.selected)
        end
        if newProps.visible ~= nil then
            btn.Visible = newProps.visible == true
        end
    end

    function api:Destroy()
        if btn and btn.Parent then
            btn:Destroy()
        end
    end

    return btn, api
end

PremiumButton.create = PremiumButton.Create

return PremiumButton
