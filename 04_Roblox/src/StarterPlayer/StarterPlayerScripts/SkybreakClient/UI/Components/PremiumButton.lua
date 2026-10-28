-- SKYBREAK: Fragments of the Core — Reusable Premium Button Component
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Components/PremiumButton.lua
-- Supports 4 variants ("primary" | "secondary" | "gold" | "danger"), 5 interactive states
-- (Idle, Hover, Pressed,Selected, Disabled), UIScale + UIStroke micro-interactions (Section 07),
-- optional 9-slice ImageButton skinning, and automatic fallback to crisp UIGradient + UIStroke styling.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local UIAssets = require(Shared:WaitForChild("Config"):WaitForChild("UIAssets"))
local UIAnimator = require(Shared:WaitForChild("UIAnimator"))
local MotionTokens = require(Shared:WaitForChild("MotionTokens"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Animations = require(script.Parent.Parent:WaitForChild("Animations"))

local PremiumButton = {}

local VARIANT_STYLES = {
    primary = function(colors)
        return {
            bgTop = colors.ACCENT_SAPPHIRE,
            bgBottom = colors.ACCENT_DEEP_BLUE,
            hoverColor = Color3.fromRGB(76, 174, 250),
            pressColor = Color3.fromRGB(34, 96, 158),
            strokeColor = colors.ACCENT_ICE,
            textColor = colors.TEXT_PRIMARY,
            assetKey = "ButtonPrimary",
        }
    end,
    gold = function(colors)
        return {
            bgTop = colors.ACCENT_GOLD,
            bgBottom = Color3.fromRGB(168, 132, 68),
            hoverColor = colors.ACCENT_GOLD_BRIGHT,
            pressColor = Color3.fromRGB(145, 112, 54),
            strokeColor = colors.ACCENT_GOLD_BRIGHT,
            textColor = colors.BG_900,
            assetKey = "ButtonPrimary",
        }
    end,
    secondary = function(colors)
        return {
            bgTop = colors.BG_700,
            bgBottom = colors.BG_800,
            hoverColor = Color3.fromRGB(36, 58, 86),
            pressColor = colors.BG_900,
            strokeColor = colors.STROKE_STEEL,
            textColor = colors.TEXT_PRIMARY,
            assetKey = "ButtonSecondary",
        }
    end,
    danger = function(colors)
        return {
            bgTop = colors.HP_RED,
            bgBottom = Color3.fromRGB(148, 46, 54),
            hoverColor = colors.DANGER,
            pressColor = Color3.fromRGB(124, 36, 44),
            strokeColor = colors.DANGER,
            textColor = colors.TEXT_PRIMARY,
            assetKey = "ButtonDanger",
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
    local scope = props.scope or "Global"

    local btn = UIFactory.Create("TextButton", parent, {
        Name = props.name or "PremiumButton",
        Position = props.position or UDim2.fromOffset(0, 0),
        Size = props.size or UDim2.fromOffset(160, 42),
        AnchorPoint = props.anchorPoint or Vector2.zero,
        BackgroundColor3 = disabled and colors.BG_800 or (selected and style.hoverColor or style.bgTop),
        BackgroundTransparency = disabled and 0.35 or (props.transparency or 0.04),
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        LayoutOrder = props.layoutOrder or 0,
        ZIndex = props.zIndex or 3,
        Visible = props.visible ~= false,
    })

    -- Section 07: Child UIScale for hover (1.04), press (0.96), and Back Out rebound (1.0)
    local uiScale = Instance.new("UIScale")
    uiScale.Name = "UIScale"
    uiScale.Scale = 1.0
    uiScale.Parent = btn

    UIFactory.Corner(btn, props.cornerRadius or Theme.Radius.Medium)
    local stroke = UIFactory.Stroke(
        btn,
        selected and colors.ACCENT_GOLD or (disabled and colors.TEXT_MUTED or style.strokeColor),
        selected and 1.8 or 1.2,
        disabled and 0.65 or 0.35
    )

    local grad = UIFactory.Gradient(
        btn,
        disabled and colors.BG_800 or style.bgTop,
        disabled and colors.BG_900 or style.bgBottom,
        90
    )

    -- Optional 9-Slice Image Layer if custom asset ID is uploaded in UIAssets
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

    local textOffsetLeft = props.icon and 34 or 10
    if props.icon then
        UIFactory.Icon(
            btn,
            props.icon,
            UDim2.new(0, 10, 0.5, -10),
            20,
            disabled and colors.TEXT_MUTED or style.textColor
        )
    end

    local label = UIFactory.Label(btn, {
        Name = "Label",
        Text = props.label or props.text or "BUTTON",
        Position = UDim2.fromOffset(textOffsetLeft, 0),
        Size = UDim2.new(1, -(textOffsetLeft + 10), 1, 0),
        TextSize = props.textSize or Theme.TextSize.Body,
        TextColor = disabled and colors.TEXT_MUTED or style.textColor,
        Font = Theme.Fonts.Heading,
        Bold = true,
        XAlign = props.icon and Enum.TextXAlignment.Left or (props.xAlign or Enum.TextXAlignment.Center),
        YAlign = Enum.TextYAlignment.Center,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = btn.ZIndex + 2,
    })

    local isHovered = false
    local isDisabled = disabled
    local isSelected = selected

    local function syncVisuals(stateName)
        if isDisabled then
            btn.BackgroundColor3 = colors.BG_800
            label.TextColor3 = colors.TEXT_MUTED
            stroke.Color = colors.TEXT_MUTED
            stroke.Transparency = 0.65
            uiScale.Scale = 1.0
            return
        end

        local targetBg = isSelected and style.hoverColor or style.bgTop
        local targetStroke = isSelected and colors.ACCENT_GOLD or style.strokeColor
        local targetStrokeTrans = isSelected and 0.08 or 0.35

        if stateName == "Hover" then
            targetBg = style.hoverColor
            targetStroke = colors.ACCENT_GOLD_BRIGHT
            targetStrokeTrans = 0.05
            UIAnimator.Tween(
                uiScale,
                { Scale = 1.04 },
                MotionTokens.hoverFast.duration,
                MotionTokens.hoverFast.style,
                MotionTokens.hoverFast.direction
            )
        elseif stateName == "Pressed" then
            targetBg = style.pressColor
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
                { Scale = isHovered and 1.04 or 1.0 },
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

        UIAnimator.Tween(btn, { BackgroundColor3 = targetBg }, MotionTokens.hoverFast.duration)
        UIAnimator.Tween(stroke, {
            Color = targetStroke,
            Transparency = targetStrokeTrans,
        }, MotionTokens.hoverFast.duration)
        label.TextColor3 = style.textColor
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

    function api:Update(newProps)
        if not newProps then
            return
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
