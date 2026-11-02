-- SKYBREAK: Fragments of the Core — Design System & Tokens
-- Style: Celestial Obsidian / Sapphire / Champagne Gold (70% Dark Neutral / 20% Sapphire / 10% Gold)
-- Location: ReplicatedStorage/SkybreakShared/Config/Theme.lua

local Theme = {}

Theme.Colors = {
    -- Canonical Design Tokens (from SKYBREAK_PREMIUM_UI_UX_BUILD_GUIDE.md Section 02)
    BG_900 = Color3.fromRGB(8, 15, 29),          -- #080F1D Deepest Obsidian Background
    BG_800 = Color3.fromRGB(14, 25, 43),         -- #0E192B Dark Glass Panel
    BG_700 = Color3.fromRGB(19, 35, 57),         -- #132339 Elevated / Hover Panel
    SURFACE_GLASS = Color3.fromRGB(25, 46, 71),  -- #192E47 Translucent Glass Surface
    STROKE_STEEL = Color3.fromRGB(76, 104, 134), -- #4C6886 Fine Metallic Border
    TEXT_PRIMARY = Color3.fromRGB(240, 244, 250),-- #F0F4FA Primary Crisp Text
    TEXT_SECONDARY = Color3.fromRGB(168, 185, 209), -- #A8B9D1 Muted / Secondary Text
    ACCENT_SAPPHIRE = Color3.fromRGB(64, 170, 255), -- #40AAFF Primary CTA / Selected / Mana
    ACCENT_DEEP_BLUE = Color3.fromRGB(21, 78, 168), -- #154EA8 CTA Gradient Bottom
    ACCENT_ICE = Color3.fromHex("#9DE1FF"),      -- #9DE1FF Ice Blue Highlight
    ACCENT_GOLD = Color3.fromRGB(228, 184, 99),  -- #E4B863 Champagne Gold / Legendary / Title
    ACCENT_GOLD_BRIGHT = Color3.fromHex("#FFE29A"), -- #FFE29A Bright Gold Hover
    TEXT_MUTED = Color3.fromHex("#A9B5C7"),      -- #A9B5C7 Muted Text
    HP_RED = Color3.fromRGB(239, 82, 98),        -- #EF5262 Health / Danger / Warning
    DANGER = Color3.fromHex("#F26A70"),          -- #F26A70 Danger / Error
    SUCCESS = Color3.fromRGB(94, 215, 158),      -- #5ED79E Completed / Available / Valid
    VOID_PURPLE = Color3.fromRGB(180, 106, 250), -- #B46AFA Void / Epic / Boss Veyr / Break

    -- Semantic & Ergonomic Aliases (compatible with Section 10.1 production snippets)
    Background = Color3.fromRGB(8, 15, 29),
    Panel = Color3.fromRGB(14, 25, 43),
    PanelHover = Color3.fromRGB(19, 35, 57),
    Glass = Color3.fromRGB(25, 46, 71),
    Stroke = Color3.fromRGB(76, 104, 134),
    Text = Color3.fromRGB(240, 244, 250),
    Muted = Color3.fromRGB(168, 185, 209),
    Sapphire = Color3.fromRGB(64, 170, 255),
    DeepBlue = Color3.fromRGB(21, 78, 168),
    Gold = Color3.fromRGB(228, 184, 99),
    HP = Color3.fromRGB(239, 82, 98),
    Success = Color3.fromRGB(94, 215, 158),
    VoidPurple = Color3.fromRGB(180, 106, 250),
    Warning = Color3.fromRGB(245, 166, 66),
}

Theme.Fonts = {
    Regular = Enum.Font.Gotham,
    Medium = Enum.Font.GothamMedium,
    Bold = Enum.Font.GothamBold,
    Heading = Enum.Font.GothamBold,
    Title = Enum.Font.GothamBold,
    Lore = Enum.Font.GothamMedium,
}

Theme.TextSize = {
    Display = 34,
    Title = 26,
    Heading = 18,
    Body = 14,
    Caption = 12,
}

Theme.Typography = {
    Logo = { Size = 44, Font = Enum.Font.GothamBold },
    PageTitle = { Size = 26, Font = Enum.Font.GothamBold },
    PanelHeading = { Size = 18, Font = Enum.Font.GothamBold },
    Body = { Size = 15, Font = Enum.Font.Gotham },
    Label = { Size = 13, Font = Enum.Font.GothamMedium },
    Stat = { Size = 16, Font = Enum.Font.GothamBold },
    Caption = { Size = 12, Font = Enum.Font.GothamMedium },
}

Theme.Spacing = {
    XS = 4,
    S = 8,
    M = 12,
    L = 16,
    XL = 24,
    XXL = 32,
}

Theme.Radius = {
    Slot = 6,
    Small = 6,
    Medium = 10,
    Large = 12,
    Pill = 999,
}

Theme.Stroke = {
    Thin = 1,
    Default = 1.5,
    Thick = 2,
    AlphaDefault = 0.32,
    AlphaSubtle = 0.45,
    AlphaGold = 0.14,
    AlphaActive = 0.08,
}

Theme.Transparency = {
    Panel = 0.06,
    Elevated = 0.04,
    Glass = 0.18,
    ModalBackdrop = 0.32,
    HUDCard = 0.12,
}

Theme.Motion = {
    Hover = 0.14,
    Press = 0.08,
    Open = 0.22,
    HP = 0.22,
    Tooltip = 0.12,
    Reward = 0.18,
    BossPhase = 0.35,
}

Theme.Layout = {
    DesktopButtonHeight = 48,
    TouchButtonHeight = 54,
    MinTouchTarget = 44,
    PanelPadding = 16,
    CompactPadding = 10,
}

function Theme.GetColor(tokenOrColor)
    if typeof(tokenOrColor) == "Color3" then
        return tokenOrColor
    end
    return Theme.Colors[tokenOrColor] or Theme.Colors.TEXT_PRIMARY
end

return Theme
