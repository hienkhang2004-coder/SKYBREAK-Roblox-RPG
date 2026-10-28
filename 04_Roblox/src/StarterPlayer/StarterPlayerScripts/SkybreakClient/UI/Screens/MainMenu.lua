-- SKYBREAK: Fragments of the Core — Screen 1: Main Menu (Section 05, 07, 09, 11, 13)
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/MainMenu.lua
-- Features:
--   * LogoGroup with LogoBase + LogoGlow ambient breathing loop (2.4s Sine InOut)
--   * CorePulse 4x4 Sprite Sheet animation (SpritePlayer.Play)
--   * Staggered CTA entrance (0.05s per button) + PlayButton UIScale/UIStroke micro-interactions
--   * Realm Select & Live Character Class Selector

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local WorldConfig = require(Shared:WaitForChild("Config"):WaitForChild("WorldConfig"))
local UIState = require(Shared:WaitForChild("Types"):WaitForChild("UIState"))
local AssetManifest = require(Shared:WaitForChild("AssetManifest"))
local SpritePlayer = require(Shared:WaitForChild("SpritePlayer"))
local UIAnimator = require(Shared:WaitForChild("UIAnimator"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Store = require(script.Parent.Parent:WaitForChild("Store"))
local ScreenRouter = require(script.Parent.Parent:WaitForChild("ScreenRouter"))
local Animations = require(script.Parent.Parent:WaitForChild("Animations"))
local PremiumPanel = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumPanel"))
local PremiumButton = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumButton"))
local PartyController = require(script.Parent.Parent:WaitForChild("Controllers"):WaitForChild("PartyController"))

local MainMenu = {
    Refs = {},
}

function MainMenu.Build(parent, responsiveState)
    MainMenu.Cleanup()
    local colors = Theme.Colors
    local snap = Store.GetSnapshot()
    local isPortrait = responsiveState and responsiveState.IsPortrait

    local root = UIFactory.Create("Frame", parent, {
        Name = "MainMenu",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
    })

    -- Left Column: LogoGroup, Tagline, Save Status, Primary CTAs (Staggered Entrance)
    local leftCard = PremiumPanel.Create(root, {
        name = "HeroMenuCard",
        title = "CELESTIAL COMMAND",
        subtitle = "Fragments of the Core • Main Menu",
        position = UDim2.fromOffset(0, 0),
        size = isPortrait and UDim2.new(1, 0, 0.54, -8) or UDim2.new(0.45, -8, 1, 0),
    })

    -- LogoGroup (LogoBase + LogoGlow)
    local logoGroup = UIFactory.Create("Frame", leftCard, {
        Name = "LogoGroup",
        Position = UDim2.fromOffset(18, 56),
        Size = UDim2.new(1, -36, 0, 68),
        BackgroundTransparency = 1,
    })

    local logoGlow = UIFactory.Create("Frame", logoGroup, {
        Name = "LogoGlow",
        Position = UDim2.fromOffset(-4, -4),
        Size = UDim2.fromOffset(56, 56),
        BackgroundColor3 = colors.ACCENT_ICE or colors.ACCENT_SAPPHIRE,
        BackgroundTransparency = 0.65,
        BorderSizePixel = 0,
    })
    UIFactory.PillCorner(logoGlow)

    local logoBase = UIFactory.Create("Frame", logoGroup, {
        Name = "LogoBase",
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromOffset(48, 48),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
    })
    UIFactory.PillCorner(logoBase)
    UIFactory.Stroke(logoBase, colors.ACCENT_GOLD, 2.0, 0.1)
    UIFactory.Icon(logoBase, "Star", UDim2.new(0.5, -18, 0.5, -18), 36, colors.ACCENT_GOLD)

    local titleBanner = UIFactory.Label(logoGroup, {
        Name = "TitleBanner",
        Text = "SKYBREAK",
        Position = UDim2.fromOffset(62, -2),
        Size = UDim2.new(1, -66, 0, 38),
        TextSize = 32,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
    })
    if Animations.PulseGlow then
        Animations.PulseGlow(titleBanner, "Menu", "TextTransparency", 0.0, 0.14)
        Animations.PulseGlow(logoGlow, "Menu", "BackgroundTransparency", 0.48, 0.82)
    end

    UIFactory.Label(logoGroup, {
        Name = "LoreQuote",
        Text = "“When the sky shattered, the world did not end — it learned how to float.”",
        Position = UDim2.fromOffset(62, 36),
        Size = UDim2.new(1, -66, 0, 28),
        TextSize = 12,
        TextColor = colors.ACCENT_ICE or colors.TEXT_SECONDARY,
    })

    local statusPill = UIFactory.Create("Frame", leftCard, {
        Name = "StatusBanner",
        Position = UDim2.fromOffset(18, 130),
        Size = UDim2.new(1, -36, 0, 52),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
    })
    UIFactory.Corner(statusPill, Theme.Radius.Medium)
    UIFactory.Stroke(statusPill, colors.ACCENT_SAPPHIRE, 1, 0.35)

    local statusLabel = UIFactory.Label(statusPill, {
        Name = "StatusText",
        Text = string.format(
            "STATUS: %s\nSkyborn Lv.%d  •  Class: %s  •  Gold: %s",
            snap.saveStatus or "Connected",
            snap.player.level or 1,
            snap.player.classId or "SkyGuardian",
            UIFactory.FormatNumber(snap.currency and snap.currency.gold or 0)
        ),
        Position = UDim2.fromOffset(12, 4),
        Size = UDim2.new(1, -24, 1, -8),
        TextSize = 12,
        TextColor = colors.TEXT_SECONDARY,
    })

    -- ButtonColumn (PlayButton, ContinueButton, RealmSelect, SettingsButton)
    local buttonColumn = UIFactory.Create("Frame", leftCard, {
        Name = "ButtonColumn",
        Position = UDim2.fromOffset(18, 190),
        Size = UDim2.new(1, -36, 0, 148),
        BackgroundTransparency = 1,
    })

    local playBtn = PremiumButton.Create(buttonColumn, {
        name = "PlayButton",
        label = "▶  PLAY / CONTINUE SKY REALM [ESC]",
        variant = "gold",
        position = UDim2.fromOffset(0, 0),
        size = UDim2.new(1, 0, 0, 46),
        textSize = 15,
        scope = "Menu",
        onActivated = function()
            ScreenRouter.Navigate(UIState.Screens.HUD, { replace = true })
        end,
    })

    local mapBtn = PremiumButton.Create(buttonColumn, {
        name = "RealmSelectButton",
        label = "REALM SELECT (WORLD MAP)",
        variant = "primary",
        position = UDim2.fromOffset(0, 54),
        size = UDim2.new(0.5, -6, 0, 40),
        textSize = 12,
        scope = "Menu",
        onActivated = function()
            ScreenRouter.Navigate(UIState.Screens.WorldMap)
        end,
    })

    local raidBtn = PremiumButton.Create(buttonColumn, {
        name = "RaidLobbyButton",
        label = "CELESTIAL RAID LOBBY",
        variant = "primary",
        position = UDim2.new(0.5, 6, 0, 54),
        size = UDim2.new(0.5, -6, 0, 40),
        textSize = 12,
        scope = "Menu",
        onActivated = function()
            ScreenRouter.Navigate(UIState.Screens.Raid)
        end,
    })

    local settingsBtn = PremiumButton.Create(buttonColumn, {
        name = "SettingsButton",
        label = "⚙  SETTINGS & ACCESSIBILITY",
        variant = "secondary",
        position = UDim2.fromOffset(0, 102),
        size = UDim2.new(0.58, -6, 0, 38),
        textSize = 12,
        scope = "Menu",
        onActivated = function()
            ScreenRouter.Navigate(UIState.Screens.Settings)
        end,
    })

    local invBtn = PremiumButton.Create(buttonColumn, {
        name = "InventoryButton",
        label = "🎒 INVENTORY & FORGE",
        variant = "secondary",
        position = UDim2.new(0.58, 6, 0, 102),
        size = UDim2.new(0.42, -6, 0, 38),
        textSize = 12,
        scope = "Menu",
        onActivated = function()
            ScreenRouter.Navigate(UIState.Screens.Inventory)
        end,
    })

    -- Section 11: Staggered CTA entrance (0.05s per button)
    local ctaButtons = { playBtn, mapBtn, raidBtn, settingsBtn, invBtn }
    for idx, btnInstance in ipairs(ctaButtons) do
        local sc = btnInstance and btnInstance:FindFirstChildOfClass("UIScale")
        if sc and not UIAnimator.ReducedMotion then
            sc.Scale = 0.90
            task.delay((idx - 1) * 0.05, function()
                if sc and sc.Parent then
                    UIAnimator.Tween(sc, { Scale = 1.0 }, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                end
            end)
        end
    end

    -- Class Archetype Selector
    UIFactory.Label(leftCard, {
        Name = "ClassHeader",
        Text = "CHOOSE COMBAT ARCHETYPE",
        Position = UDim2.fromOffset(18, 344),
        Size = UDim2.new(1, -36, 0, 20),
        TextSize = 12,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
    })

    local classRow = UIFactory.Create("Frame", leftCard, {
        Name = "ClassSelectorRow",
        Position = UDim2.fromOffset(18, 368),
        Size = UDim2.new(1, -36, 0, 42),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(classRow, Enum.FillDirection.Horizontal, 8)

    local classBtns = {}
    local classList = WorldConfig.OrderedClasses or { "SkyGuardian", "ThunderStriker", "ArcaneMage" }
    for idx, classId in ipairs(classList) do
        local cfg = WorldConfig.Classes[classId]
        if cfg then
            local _, api = PremiumButton.Create(classRow, {
                name = "Select_" .. classId,
                label = cfg.Name,
                variant = snap.player.classId == classId and "primary" or "secondary",
                selected = snap.player.classId == classId,
                size = UDim2.new(0.333, -6, 1, 0),
                textSize = 12,
                layoutOrder = idx,
                scope = "Menu",
                onActivated = function()
                    PartyController.RequestClassOrGenderChange(classId, snap.player.gender or "Male")
                end,
            })
            classBtns[classId] = api
        end
    end

    -- Right Column: CorePulse 4x4 Sprite Sheet Hero FX + Realm Gateway Cards
    local rightCard = PremiumPanel.Create(root, {
        name = "RealmGatewayCard",
        title = "FLOATING ARCHIPELAGO • CORE PULSE & REALMS",
        subtitle = "Live 4x4 Sprite Sheet Core Pulse & Fast Travel Gateways",
        position = isPortrait and UDim2.new(0, 0, 0.54, 8) or UDim2.new(0.45, 8, 0, 0),
        size = isPortrait and UDim2.new(1, 0, 0.46, -8) or UDim2.new(0.55, -8, 1, 0),
    })

    -- Section 09 & Section 13: CorePulse 4x4 Sprite Sheet FX badge in top-right of RealmGatewayCard
    local corePulseBadge = UIFactory.Create("Frame", rightCard, {
        Name = "CorePulseContainer",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -18, 0, 8),
        Size = UDim2.fromOffset(48, 48),
        BackgroundTransparency = 1,
        ZIndex = 6,
    })

    local corePulseImage = UIFactory.Create("ImageLabel", corePulseBadge, {
        Name = "CorePulse",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(46, 46),
        BackgroundTransparency = 1,
        ZIndex = 7,
    })
    SpritePlayer.Play(corePulseImage, AssetManifest.CorePulseAtlas, 4, 4, 256, 256, 12, 16)

    local realmList = UIFactory.Create("ScrollingFrame", rightCard, {
        Name = "RealmList",
        Position = UDim2.fromOffset(16, 62),
        Size = UDim2.new(1, -32, 1, -78),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 5,
        ScrollBarImageColor3 = colors.ACCENT_SAPPHIRE,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.fromOffset(0, 0),
    })
    UIFactory.ListLayout(realmList, Enum.FillDirection.Vertical, 10)

    for idx, realm in ipairs(WorldConfig.Realms or {}) do
        local isCurrent = (snap.world and snap.world.current == realm.Id)
        local isUnlocked = (snap.world and snap.world.unlocked and snap.world.unlocked[realm.Id] == true) or realm.FastTravelUnlockedByDefault == true

        local card = UIFactory.Create("Frame", realmList, {
            Name = "Realm_" .. realm.Id,
            Size = UDim2.new(1, -6, 0, 102),
            BackgroundColor3 = colors.BG_900,
            BackgroundTransparency = 0.08,
            BorderSizePixel = 0,
            LayoutOrder = idx,
        })
        UIFactory.Corner(card, Theme.Radius.Medium)
        UIFactory.Stroke(card, isCurrent and colors.ACCENT_GOLD or (realm.AccentColor or colors.ACCENT_SAPPHIRE), isCurrent and 1.8 or 1.2, 0.2)

        UIFactory.Icon(card, "Map", UDim2.fromOffset(14, 16), 34, realm.AccentColor or colors.ACCENT_SAPPHIRE)

        UIFactory.Label(card, {
            Name = "Name",
            Text = string.format("%s  •  %s", string.upper(realm.Name or realm.Id), tostring(realm.LevelRange or "Lv. 1+")),
            Position = UDim2.fromOffset(60, 10),
            Size = UDim2.new(1, -190, 0, 22),
            TextSize = 15,
            TextColor = colors.TEXT_PRIMARY,
            Bold = true,
        })

        UIFactory.Label(card, {
            Name = "Sub",
            Text = tostring(realm.Chapter or realm.VietnameseName or "") .. " — " .. tostring(realm.Description or ""),
            Position = UDim2.fromOffset(60, 34),
            Size = UDim2.new(1, -190, 0, 56),
            TextSize = 12,
            TextColor = colors.TEXT_SECONDARY,
            YAlign = Enum.TextYAlignment.Top,
        })

        PremiumButton.Create(card, {
            name = "Enter_" .. realm.Id,
            label = isCurrent and "ACTIVE REALM" or (isUnlocked and "TRAVEL" or "LOCKED"),
            variant = isCurrent and "gold" or (isUnlocked and "primary" or "secondary"),
            disabled = not isUnlocked,
            position = UDim2.new(1, -122, 0.5, -19),
            size = UDim2.fromOffset(108, 38),
            textSize = 12,
            scope = "Menu",
            onActivated = function()
                Store.SetView({ selectedRealmId = realm.Id })
                ScreenRouter.Navigate(UIState.Screens.WorldMap)
            end,
        })
    end

    MainMenu.Refs = {
        Root = root,
        StatusLabel = statusLabel,
        ClassBtns = classBtns,
        CorePulseImage = corePulseImage,
    }

    return root
end

function MainMenu.Update(snapshot)
    local refs = MainMenu.Refs
    if not refs.Root or not snapshot then
        return
    end
    if refs.StatusLabel then
        refs.StatusLabel.Text = string.format(
            "STATUS: %s\nSkyborn Lv.%d  •  Class: %s  •  Gold: %s",
            snapshot.saveStatus or "Connected",
            snapshot.player.level or 1,
            snapshot.player.classId or "SkyGuardian",
            UIFactory.FormatNumber(snapshot.currency and snapshot.currency.gold or 0)
        )
    end
    if refs.ClassBtns then
        for classId, api in pairs(refs.ClassBtns) do
            api:SetSelected(snapshot.player.classId == classId)
        end
    end
end

function MainMenu.Cleanup()
    if MainMenu.Refs and MainMenu.Refs.CorePulseImage then
        SpritePlayer.Stop(MainMenu.Refs.CorePulseImage)
    end
    Animations.CleanupScope("Menu")
    MainMenu.Refs = {}
end

return MainMenu
