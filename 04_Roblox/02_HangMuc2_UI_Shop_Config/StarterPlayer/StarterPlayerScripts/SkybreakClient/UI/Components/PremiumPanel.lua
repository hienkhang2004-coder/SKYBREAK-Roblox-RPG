-- SKYBREAK: Fragments of the Core — Reusable Obsidian Glass Panel Component
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Components/PremiumPanel.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local UIAssets = require(Shared:WaitForChild("Config"):WaitForChild("UIAssets"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))

local PremiumPanel = {}

function PremiumPanel.Create(parent, props)
    props = props or {}
    local colors = Theme.Colors
    local isGold = props.variant == "gold" or props.gold == true
    local isElevated = props.variant == "elevated" or props.elevated == true
    local accentColor = props.accentColor and Theme.GetColor(props.accentColor)
        or (isGold and colors.ACCENT_GOLD or colors.STROKE_STEEL)

    local frame = UIFactory.Create("Frame", parent, {
        Name = props.name or "PremiumPanel",
        Position = props.position or UDim2.fromScale(0, 0),
        Size = props.size or UDim2.fromOffset(320, 220),
        AnchorPoint = props.anchorPoint or Vector2.new(0, 0),
        BackgroundColor3 = isElevated and colors.BG_700 or colors.BG_800,
        BackgroundTransparency = props.transparency or Theme.Transparency.Panel,
        BorderSizePixel = 0,
        ClipsDescendants = props.clipsDescendants == true,
        LayoutOrder = props.layoutOrder or 0,
        Visible = props.visible ~= false,
        ZIndex = props.zIndex or 2,
    })

    UIFactory.Corner(frame, props.cornerRadius or Theme.Radius.Large)
    local stroke = UIFactory.Stroke(
        frame,
        accentColor,
        isGold and Theme.Stroke.Default or Theme.Stroke.Thin,
        isGold and Theme.Stroke.AlphaGold or Theme.Stroke.AlphaDefault
    )
    UIFactory.Gradient(
        frame,
        isElevated and colors.SURFACE_GLASS or colors.BG_700,
        colors.BG_900,
        props.gradientRotation or 90
    )

    -- Tactile 1px top inner specular highlight strip (Figma Files 1-3)
    UIFactory.Create("Frame", frame, {
        Name = "TopSpecular",
        Position = UDim2.fromOffset(12, 1),
        Size = UDim2.new(1, -24, 0, 1),
        BackgroundColor3 = isGold and colors.ACCENT_GOLD_BRIGHT or colors.ACCENT_ICE,
        BackgroundTransparency = 0.55,
        BorderSizePixel = 0,
        ZIndex = frame.ZIndex + 1,
    })

    if isGold then
        local corners = {
            { ax = 0, ay = 0, px = 3, py = 3 },
            { ax = 1, ay = 0, px = -3, py = 3 },
            { ax = 0, ay = 1, px = 3, py = -3 },
            { ax = 1, ay = 1, px = -3, py = -3 },
        }
        for idx, c in ipairs(corners) do
            UIFactory.Create("Frame", frame, {
                Name = "GoldBracketH_" .. idx,
                AnchorPoint = Vector2.new(c.ax, c.ay),
                Position = UDim2.new(c.ax, c.px, c.ay, c.py),
                Size = UDim2.fromOffset(10, 2),
                BackgroundColor3 = colors.ACCENT_GOLD_BRIGHT,
                BackgroundTransparency = 0.18,
                BorderSizePixel = 0,
                ZIndex = frame.ZIndex + 2,
            })
            UIFactory.Create("Frame", frame, {
                Name = "GoldBracketV_" .. idx,
                AnchorPoint = Vector2.new(c.ax, c.ay),
                Position = UDim2.new(c.ax, c.px, c.ay, c.py),
                Size = UDim2.fromOffset(2, 10),
                BackgroundColor3 = colors.ACCENT_GOLD_BRIGHT,
                BackgroundTransparency = 0.18,
                BorderSizePixel = 0,
                ZIndex = frame.ZIndex + 2,
            })
        end
    end

    if UIAssets.IsValidAssetId(UIAssets.PanelNineSlice) then
        UIFactory.Create("ImageLabel", frame, {
            Name = "NineSliceOverlay",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Image = UIAssets.PanelNineSlice,
            ImageTransparency = 0.25,
            ScaleType = Enum.ScaleType.Slice,
            SliceCenter = UIAssets.NineSliceRects.Panel,
            ZIndex = frame.ZIndex + 1,
        })
    end

    local titleLabel
    local subtitleLabel
    local closeButton

    if props.title then
        titleLabel = UIFactory.Label(frame, {
            Name = "PanelTitle",
            Text = props.title,
            Position = UDim2.fromOffset(16, 12),
            Size = UDim2.new(1, props.onClose and -68 or -32, 0, 24),
            TextSize = props.titleSize or Theme.Typography.PanelHeading.Size,
            TextColor = isGold and colors.ACCENT_GOLD or (props.titleColor or colors.TEXT_PRIMARY),
            Bold = true,
            ZIndex = frame.ZIndex + 2,
        })

        if props.subtitle then
            subtitleLabel = UIFactory.Label(frame, {
                Name = "PanelSubtitle",
                Text = props.subtitle,
                Position = UDim2.fromOffset(16, 36),
                Size = UDim2.new(1, -32, 0, 18),
                TextSize = Theme.Typography.Label.Size,
                TextColor = colors.TEXT_SECONDARY,
                Weight = "Medium",
                ZIndex = frame.ZIndex + 2,
            })
        end

        UIFactory.Divider(
            frame,
            UDim2.fromOffset(16, props.subtitle and 58 or 42),
            UDim2.new(1, -32, 0, 1),
            isGold
        )
    end

    if type(props.onClose) == "function" then
        closeButton = UIFactory.Create("TextButton", frame, {
            Name = "CloseButton",
            Text = "X",
            Position = UDim2.new(1, -46, 0, 10),
            Size = UDim2.fromOffset(34, 34),
            BackgroundColor3 = colors.BG_700,
            BorderSizePixel = 0,
            Font = Theme.Fonts.Bold,
            TextSize = 15,
            TextColor3 = colors.TEXT_PRIMARY,
            AutoButtonColor = false,
            ZIndex = frame.ZIndex + 4,
        })
        UIFactory.Corner(closeButton, Theme.Radius.Small)
        UIFactory.Stroke(closeButton, colors.STROKE_STEEL, 1, 0.35)
        closeButton.Activated:Connect(function()
            props.onClose()
        end)
    end

    local api = {
        Instance = frame,
        Stroke = stroke,
        TitleLabel = titleLabel,
        SubtitleLabel = subtitleLabel,
        CloseButton = closeButton,
    }

    function api:Update(newProps)
        newProps = newProps or {}
        if newProps.title and titleLabel then
            titleLabel.Text = newProps.title
        end
        if newProps.subtitle and subtitleLabel then
            subtitleLabel.Text = newProps.subtitle
        end
        if newProps.accentColor then
            stroke.Color = Theme.GetColor(newProps.accentColor)
        end
        if newProps.visible ~= nil then
            frame.Visible = newProps.visible
        end
    end

    function api:Destroy()
        if frame and frame.Parent then
            frame:Destroy()
        end
    end

    return frame, api
end

PremiumPanel.create = PremiumPanel.Create

return PremiumPanel
