-- SKYBREAK: Fragments of the Core — Screen 9: Settings & Accessibility (Section 11 & Section 14)
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/Settings.lua
-- Provides live toggles for Reduced Motion, FX Quality (Low / Medium / High), Minimap Visibility,
-- Text Scale (90% / 100% / 115%), Responsive Layout Override (Auto / Desktop / Mobile), and Volume controls.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Store = require(script.Parent.Parent:WaitForChild("Store"))
local Animations = require(script.Parent.Parent:WaitForChild("Animations"))
local PremiumPanel = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumPanel"))
local PremiumButton = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumButton"))

local Settings = {
    Refs = {},
}

function Settings.Build(parent, responsiveState)
    Settings.Cleanup()
    local colors = Theme.Colors
    local view = Store.GetView()
    local s = view.settings or {}
    local isPortrait = responsiveState and responsiveState.IsPortrait

    local root = UIFactory.Create("Frame", parent, {
        Name = "SettingsScreen",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
    })

    -- Left Column: Accessibility, Motion & HUD Display
    local leftCard = PremiumPanel.Create(root, {
        name = "AccessibilityCard",
        title = "ACCESSIBILITY, MOTION & VFX",
        subtitle = "Reduced Motion, FX Quality & Responsive Layout",
        position = UDim2.fromOffset(0, 0),
        size = isPortrait and UDim2.new(1, 0, 0.54, -8) or UDim2.new(0.5, -8, 1, 0),
    })

    local listLeft = UIFactory.Create("Frame", leftCard, {
        Name = "List",
        Position = UDim2.fromOffset(18, 62),
        Size = UDim2.new(1, -36, 1, -78),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(listLeft, Enum.FillDirection.Vertical, 10)

    local function createToggleRow(order, title, desc, isOn, onToggle)
        local row = UIFactory.Create("Frame", listLeft, {
            Name = "Toggle_" .. order,
            Size = UDim2.new(1, 0, 0, 62),
            BackgroundColor3 = colors.BG_900,
            BorderSizePixel = 0,
            LayoutOrder = order,
        })
        UIFactory.Corner(row, Theme.Radius.Medium)
        UIFactory.Stroke(row, isOn and colors.ACCENT_GOLD or colors.STROKE_STEEL, 1.2, 0.25)

        UIFactory.Label(row, {
            Name = "Title",
            Text = title,
            Position = UDim2.fromOffset(14, 8),
            Size = UDim2.new(1, -140, 0, 20),
            TextSize = 14,
            TextColor = colors.TEXT_PRIMARY,
            Bold = true,
        })

        UIFactory.Label(row, {
            Name = "Desc",
            Text = desc,
            Position = UDim2.fromOffset(14, 30),
            Size = UDim2.new(1, -140, 0, 26),
            TextSize = 11,
            TextColor = colors.TEXT_SECONDARY,
        })

        PremiumButton.Create(row, {
            name = "ToggleBtn",
            label = isOn and "ON" or "OFF",
            variant = isOn and "gold" or "secondary",
            selected = isOn,
            position = UDim2.new(1, -110, 0.5, -18),
            size = UDim2.fromOffset(96, 36),
            textSize = 13,
            onActivated = function()
                onToggle(not isOn)
            end,
        })
    end

    createToggleRow(
        1,
        "Reduced Motion",
        "Disables ambient breathing loops, sprite sheet animations, and switches tweens to instant updates.",
        s.reducedMotion == true,
        function(nextVal)
            Animations.SetReducedMotion(nextVal)
            local nextSettings = table.clone(s)
            nextSettings.reducedMotion = nextVal
            Store.SetView({ settings = nextSettings })
        end
    )

    -- FX Quality Selector (Low / Medium / High) — Section 11 & Section 14
    local fxQuality = s.fxQuality or (s.lowFX and "Low" or "High")
    local fxBox = UIFactory.Create("Frame", listLeft, {
        Name = "FXQualityBox",
        Size = UDim2.new(1, 0, 0, 74),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
        LayoutOrder = 2,
    })
    UIFactory.Corner(fxBox, Theme.Radius.Medium)
    UIFactory.Stroke(fxBox, colors.STROKE_STEEL, 1, 0.35)

    UIFactory.Label(fxBox, {
        Name = "Title",
        Text = "FX QUALITY TIER  •  Current: " .. string.upper(fxQuality),
        Position = UDim2.fromOffset(14, 8),
        Size = UDim2.new(1, -28, 0, 20),
        TextSize = 13,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
    })

    local fxRow = UIFactory.Create("Frame", fxBox, {
        Name = "FXButtons",
        Position = UDim2.fromOffset(14, 32),
        Size = UDim2.new(1, -28, 0, 34),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(fxRow, Enum.FillDirection.Horizontal, 8)

    for idx, tier in ipairs({ "Low", "Medium", "High" }) do
        PremiumButton.Create(fxRow, {
            name = "FX_" .. tier,
            label = string.upper(tier),
            variant = fxQuality == tier and "primary" or "secondary",
            selected = fxQuality == tier,
            size = UDim2.new(0.333, -6, 1, 0),
            textSize = 12,
            layoutOrder = idx,
            onActivated = function()
                local nextSettings = table.clone(s)
                nextSettings.fxQuality = tier
                nextSettings.lowFX = (tier == "Low")
                Store.SetView({ settings = nextSettings })
            end,
        })
    end

    createToggleRow(
        3,
        "Show Region Compass & Minimap",
        "Displays the top-right region compass and world map shortcut on the gameplay HUD.",
        s.showMinimap ~= false,
        function(nextVal)
            local nextSettings = table.clone(s)
            nextSettings.showMinimap = nextVal
            Store.SetView({ settings = nextSettings })
        end
    )

    -- Layout Override Selector (Auto / Desktop / Mobile)
    local layoutBox = UIFactory.Create("Frame", listLeft, {
        Name = "LayoutModeBox",
        Size = UDim2.new(1, 0, 0, 74),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
        LayoutOrder = 4,
    })
    UIFactory.Corner(layoutBox, Theme.Radius.Medium)
    UIFactory.Stroke(layoutBox, colors.STROKE_STEEL, 1, 0.35)

    UIFactory.Label(layoutBox, {
        Name = "Title",
        Text = "RESPONSIVE LAYOUT PROFILE (DESKTOP vs MOBILE)",
        Position = UDim2.fromOffset(14, 8),
        Size = UDim2.new(1, -28, 0, 20),
        TextSize = 13,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
    })

    local modeRow = UIFactory.Create("Frame", layoutBox, {
        Name = "ModeButtons",
        Position = UDim2.fromOffset(14, 32),
        Size = UDim2.new(1, -28, 0, 34),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(modeRow, Enum.FillDirection.Horizontal, 8)

    for idx, mode in ipairs({ "Auto", "Desktop", "Mobile" }) do
        local isSel = (s.layoutMode or "Auto") == mode
        PremiumButton.Create(modeRow, {
            name = "Mode_" .. mode,
            label = string.upper(mode),
            variant = isSel and "primary" or "secondary",
            selected = isSel,
            size = UDim2.new(0.333, -6, 1, 0),
            textSize = 12,
            layoutOrder = idx,
            onActivated = function()
                local nextSettings = table.clone(s)
                nextSettings.layoutMode = mode
                Store.SetView({ settings = nextSettings })
            end,
        })
    end

    -- Right Column: Audio, Text Scale & Keybind Reference
    local rightCard = PremiumPanel.Create(root, {
        name = "AudioKeybindCard",
        title = "AUDIO, TEXT SCALE & KEYBINDS",
        subtitle = "Sound Balance, UI Scale & PC/Gamepad Controls",
        position = isPortrait and UDim2.new(0, 0, 0.54, 8) or UDim2.new(0.5, 8, 0, 0),
        size = isPortrait and UDim2.new(1, 0, 0.46, -8) or UDim2.new(0.5, -8, 1, 0),
    })

    -- Text Scale Presets
    UIFactory.Label(rightCard, {
        Name = "ScaleHeader",
        Text = string.format("UI SCALE MULTIPLIER  •  Current: %d%%", math.floor((s.textScale or 1.0) * 100)),
        Position = UDim2.fromOffset(18, 62),
        Size = UDim2.new(1, -36, 0, 20),
        TextSize = 12,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
    })

    local scaleRow = UIFactory.Create("Frame", rightCard, {
        Name = "ScaleRow",
        Position = UDim2.fromOffset(18, 86),
        Size = UDim2.new(1, -36, 0, 38),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(scaleRow, Enum.FillDirection.Horizontal, 8)

    for idx, preset in ipairs({
        { label = "90% COMPACT", val = 0.90 },
        { label = "100% STANDARD", val = 1.00 },
        { label = "112% LARGE TEXT", val = 1.12 },
    }) do
        local isSel = math.abs((s.textScale or 1.0) - preset.val) < 0.02
        PremiumButton.Create(scaleRow, {
            name = "Scale_" .. idx,
            label = preset.label,
            variant = isSel and "primary" or "secondary",
            selected = isSel,
            size = UDim2.new(0.333, -6, 1, 0),
            textSize = 12,
            layoutOrder = idx,
            onActivated = function()
                local nextSettings = table.clone(s)
                nextSettings.textScale = preset.val
                Store.SetView({ settings = nextSettings })
            end,
        })
    end

    -- Volume Controls
    UIFactory.Label(rightCard, {
        Name = "VolHeader",
        Text = string.format("MASTER VOLUME: %d%%   •   COMBAT SFX: %d%%", s.masterVolume or 80, s.sfxVolume or 85),
        Position = UDim2.fromOffset(18, 138),
        Size = UDim2.new(1, -36, 0, 20),
        TextSize = 12,
        TextColor = colors.ACCENT_SAPPHIRE,
        Bold = true,
    })

    local volRow = UIFactory.Create("Frame", rightCard, {
        Name = "VolumeRow",
        Position = UDim2.fromOffset(18, 162),
        Size = UDim2.new(1, -36, 0, 38),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(volRow, Enum.FillDirection.Horizontal, 8)

    for idx, vol in ipairs({ 25, 50, 80, 100 }) do
        PremiumButton.Create(volRow, {
            name = "Vol_" .. vol,
            label = tostring(vol) .. "%",
            variant = (s.masterVolume == vol) and "primary" or "secondary",
            selected = (s.masterVolume == vol),
            size = UDim2.new(0.25, -6, 1, 0),
            textSize = 12,
            layoutOrder = idx,
            onActivated = function()
                local nextSettings = table.clone(s)
                nextSettings.masterVolume = vol
                nextSettings.sfxVolume = vol
                Store.SetView({ settings = nextSettings })
            end,
        })
    end

    -- Complete Keybind Reference Card
    local keyCard = UIFactory.Create("Frame", rightCard, {
        Name = "KeybindReference",
        Position = UDim2.fromOffset(18, 214),
        Size = UDim2.new(1, -36, 1, -230),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
    })
    UIFactory.Corner(keyCard, Theme.Radius.Medium)
    UIFactory.Stroke(keyCard, colors.STROKE_STEEL, 1, 0.35)

    UIFactory.Label(keyCard, {
        Name = "KeyHeader",
        Text = "KEYBOARD & GAMEPAD SHORTCUTS",
        Position = UDim2.fromOffset(14, 10),
        Size = UDim2.new(1, -28, 0, 20),
        TextSize = 12,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
    })

    UIFactory.Label(keyCard, {
        Name = "KeyBody",
        Text = table.concat({
            "• [LMB / RT]  Basic 3-Hit Combo  |  Hold 0.35s for Heavy Strike",
            "• [1] [2] [3]  Class Active Abilities   |   [R]  Celestial Ultimate",
            "• [Q]  Iframe Dodge   |   [Left Shift]  Sky Dash   |   [E]  Interact",
            "• [I]  Inventory   |   [K]  Skills   |   [M]  World Map   |   [J]  Quests",
            "• [F]  Forge Station   |   [P]  Raid Lobby   |   [ESC / Tab]  Back / Close",
        }, "\n"),
        Position = UDim2.fromOffset(14, 34),
        Size = UDim2.new(1, -28, 1, -44),
        TextSize = 12,
        TextColor = colors.TEXT_SECONDARY,
        YAlign = Enum.TextYAlignment.Top,
    })

    Settings.Refs = {
        Root = root,
    }
    return root
end

function Settings.Update()
    if Settings.Refs.Root and Settings.Refs.Root.Parent then
        local parent = Settings.Refs.Root.Parent
        Settings.Build(parent)
    end
end

function Settings.Cleanup()
    Settings.Refs = {}
end

return Settings
