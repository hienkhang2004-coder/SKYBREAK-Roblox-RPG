-- SKYBREAK: Fragments of the Core — Action-RPG Gameplay HUD Screen (1:1 Figma v2 Fidelity)
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/HUD.lua
-- Matches SKYBREAK_Figma_v2_01_ActionRPG_HUD.png 1:1:
--   * Top-Left Gold-Bracketed PlayerHUD (388x122) with Winged Live 3D Avatar Bust, * SKYGUARDIAN Pill & Glossy HP/AETHER/EXP Bars
--   * Always-Visible Currency & Haki Status Pills Row ([Gold], [Shards], [J] Haki • Ken) + Dynamic Active Buffs
--   * Middle-Left Collapsible QuestTracker with Golden Ribbon Header Banner ("NHẬT KÝ NHIỆM VỤ [L]")
--   * Top-Center BossHUD with Golden Crown Ribbon ("AUREON SENTINEL • LV. 150 | PHASE II")
--   * Top-Right 148x148 CelestialMinimap + Purple Aether Fruit Radar Pill + Gold Squad Pill Button [B]
--   * Right-Center Tilted -8 deg Gold Rank Square Combo Card ("34 COMBO HITS • +SÁT THƯƠNG AETHER")
--   * Bottom-Left Obsidian-Gold Quick Dock (9 tactile Icon-Over-Caption tiles with hotkey badges)
--   * Bottom-Center Action-RPG Combat Dock: 4 Loadout Pills (Glossy Champagne Gold active pill) + 8 Glossy Skill Cards flanking 45 deg Diamond Ultimate [R] + J/T Shoulder Mini-Orbs.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local WorldConfig = require(Shared:WaitForChild("Config"):WaitForChild("WorldConfig"))
local UIState = require(Shared:WaitForChild("Types"):WaitForChild("UIState"))
local UIAnimator = require(Shared:WaitForChild("UIAnimator"))
local MotionTokens = require(Shared:WaitForChild("MotionTokens"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Responsive = require(script.Parent.Parent:WaitForChild("Responsive"))
local Store = require(script.Parent.Parent:WaitForChild("Store"))
local ScreenRouter = require(script.Parent.Parent:WaitForChild("ScreenRouter"))
local I18n = require(script.Parent.Parent:WaitForChild("I18n"))

local PremiumPanel = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumPanel"))
local PremiumButton = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumButton"))
local StatBar = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("StatBar"))
local QuestTracker = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("QuestTracker"))
local SkillButton = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("SkillButton"))
local RaidPhase = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("RaidPhase"))
local CelestialMinimap = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("CelestialMinimap"))
local LiveAvatarPortrait = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("LiveAvatarPortrait"))
local HUDController = require(script.Parent.Parent:WaitForChild("Controllers"):WaitForChild("HUDController"))

local HUD = {
    Refs = {},
    Connections = {},
    BossVisibleLatch = false,
    ComboState = {
        Count = 0,
        LastHitClock = 0,
        WindowSec = 4.5,
    },
    DashState = {
        MaxCharges = 3,
        RechargeSec = 1.45,
        SpentClocks = {},
        LastConsumeClock = 0,
        CalloutUntil = 0,
    },
}

local function resolveClassBadgeMeta(level, classId, v4Active)
    local lv = tonumber(level) or 1
    local suffix = v4Active and " • V4" or ""
    if lv < 15 then
        return "* SKYBORN" .. suffix, Color3.fromRGB(214, 196, 148)
    elseif classId == "ThunderStriker" then
        return "* THUNDERSTRIKER" .. suffix, Color3.fromRGB(88, 206, 255)
    elseif classId == "ArcaneMage" then
        return "* ARCANEMAGE" .. suffix, Color3.fromRGB(204, 148, 255)
    end
    return "* SKYGUARDIAN" .. suffix, Theme.Colors.ACCENT_GOLD_BRIGHT
end

local function resolveComboRankMeta(comboCount)
    local c = tonumber(comboCount) or 0
    local bonusPct = math.min(35, math.max(4, math.floor(c * 0.55)))
    if c >= 35 then
        return "SS", Color3.fromRGB(251, 113, 133), I18n.Pick(string.format("+%d%% SÁT THƯƠNG AETHER", bonusPct), string.format("+%d%% AETHER DAMAGE", bonusPct))
    elseif c >= 23 then
        return "S", Color3.fromRGB(249, 209, 104), I18n.Pick(string.format("+%d%% SÁT THƯƠNG AETHER", bonusPct), string.format("+%d%% AETHER DAMAGE", bonusPct))
    elseif c >= 15 then
        return "A", Color3.fromRGB(192, 132, 252), I18n.Pick(string.format("+%d%% SÁT THƯƠNG AETHER", bonusPct), string.format("+%d%% AETHER DAMAGE", bonusPct))
    elseif c >= 9 then
        return "B", Color3.fromRGB(52, 211, 153), I18n.Pick(string.format("+%d%% SÁT THƯƠNG AETHER", bonusPct), string.format("+%d%% AETHER DAMAGE", bonusPct))
    elseif c >= 5 then
        return "C", Color3.fromRGB(56, 189, 248), I18n.Pick(string.format("+%d%% SÁT THƯƠNG AETHER", bonusPct), string.format("+%d%% AETHER DAMAGE", bonusPct))
    end
    return "D", Color3.fromRGB(148, 212, 255), I18n.Pick(string.format("+%d%% SÁT THƯƠNG AETHER", bonusPct), string.format("+%d%% AETHER DAMAGE", bonusPct))
end

local SLOT_ICONS = {
    [1] = "Fist",
    [2] = "Fruit",
    [3] = "Sword",
    [4] = "Gun",
}

local function formatTimer(sec)
    local s = math.max(0, math.floor(tonumber(sec) or 0))
    local m = math.floor(s / 60)
    local r = s % 60
    if m > 0 then
        return string.format("%d:%02d", m, r)
    end
    return string.format("%ds", r)
end

-- Builds the Centerpiece 45-Degree Diamond Ultimate [R] + Flanking J (Haki) & T (Race V4) Shoulder Mini-Orbs
local function buildDiamondUltimateCenterpiece(parent, props)
    local colors = Theme.Colors
    local baseZ = props.zIndex or 8

    local holder = UIFactory.Create("Frame", parent, {
        Name = "DiamondUltimateCenter",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(92, 82),
        BackgroundTransparency = 1,
        ClipsDescendants = false,
        ZIndex = baseZ,
    })

    -- Top-Left Shoulder Circular [J] Crimson Haki Mini-Orb (22x22)
    local jOrb = UIFactory.Create("TextButton", holder, {
        Name = "HakiShoulderOrb_J",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, -33, 0, 12),
        Size = UDim2.fromOffset(22, 22),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Text = "J",
        Font = Theme.Fonts.Bold,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(255, 250, 252),
        AutoButtonColor = false,
        ZIndex = baseZ + 6,
    })
    UIFactory.PillCorner(jOrb)
    local jOrbStroke = UIFactory.Stroke(jOrb, Color3.fromRGB(255, 180, 196), 1.5, 0.05)
    UIFactory.Gradient(jOrb, Color3.fromRGB(251, 58, 100), Color3.fromRGB(159, 18, 57), 90)
    jOrb.Activated:Connect(function()
        if type(props.onHaki) == "function" then
            props.onHaki()
        end
    end)

    -- Top-Right Shoulder Circular [T] Violet Race V4 Mini-Orb (22x22)
    local tOrb = UIFactory.Create("TextButton", holder, {
        Name = "RaceV4ShoulderOrb_T",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 33, 0, 12),
        Size = UDim2.fromOffset(22, 22),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Text = "T",
        Font = Theme.Fonts.Bold,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(252, 246, 255),
        AutoButtonColor = false,
        ZIndex = baseZ + 6,
    })
    UIFactory.PillCorner(tOrb)
    local tOrbStroke = UIFactory.Stroke(tOrb, Color3.fromRGB(233, 213, 255), 1.5, 0.05)
    UIFactory.Gradient(tOrb, Color3.fromRGB(192, 132, 252), Color3.fromRGB(109, 40, 217), 90)
    tOrb.Activated:Connect(function()
        if type(props.onV4) == "function" then
            props.onV4()
        end
    end)

    -- Main Interactive Hitbox + Scale Wrapper for 45-deg Rotated Diamond [R]
    local ultHitBtn = UIFactory.Create("TextButton", holder, {
        Name = "UltimateDiamondButton",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.47, 0),
        Size = UDim2.fromOffset(60, 60),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = baseZ + 3,
    })
    local uiScale = Instance.new("UIScale")
    uiScale.Scale = 1.0
    uiScale.Parent = ultHitBtn

    -- Outer 45-deg Champagne Gold Double-Bordered Diamond Frame (54x54)
    local outerDiamond = UIFactory.Create("Frame", ultHitBtn, {
        Name = "OuterGoldDiamond",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(54, 54),
        Rotation = 45,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Active = false,
        ZIndex = baseZ + 2,
    })
    UIFactory.Corner(outerDiamond, 10)
    local outerStroke = UIFactory.Stroke(outerDiamond, colors.ACCENT_GOLD_BRIGHT, 2.2, 0.02)
    UIFactory.Gradient(outerDiamond, Color3.fromRGB(252, 216, 112), Color3.fromRGB(184, 124, 28), 90)

    -- Inner 45-deg Vivid Violet-Rose Glossy Diamond Core (44x44)
    local innerDiamond = UIFactory.Create("Frame", ultHitBtn, {
        Name = "InnerMythicDiamond",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(44, 44),
        Rotation = 45,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Active = false,
        ZIndex = baseZ + 3,
    })
    UIFactory.Corner(innerDiamond, 8)
    UIFactory.Stroke(innerDiamond, Color3.fromRGB(255, 214, 240), 1.3, 0.16)
    local innerGrad = UIFactory.Gradient(innerDiamond, Color3.fromRGB(236, 104, 246), Color3.fromRGB(118, 38, 224), 135)

    local diamondGloss = UIFactory.Create("Frame", innerDiamond, {
        Name = "DiamondGloss",
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.new(1, -4, 0.45, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.76,
        BorderSizePixel = 0,
        Active = false,
        ZIndex = baseZ + 4,
    })
    UIFactory.Corner(diamondGloss, 6)

    -- Unrotated Royal Crown Vector Icon centered inside Diamond
    local crownIcon = UIFactory.Icon(
        ultHitBtn,
        "Crown",
        UDim2.new(0.5, -12, 0.5, -12),
        24,
        Color3.fromRGB(255, 252, 255)
    )
    crownIcon.ZIndex = baseZ + 5

    local cdLabel = UIFactory.Label(ultHitBtn, {
        Name = "UltCooldownText",
        Text = "",
        Size = UDim2.fromScale(1, 1),
        TextSize = 13,
        TextColor = Color3.fromRGB(168, 236, 255),
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Wrapped = false,
        ZIndex = baseZ + 6,
    })

    -- Top [R] Dark Obsidian Pill
    local rPill = UIFactory.Create("Frame", holder, {
        Name = "TopKeyPill_R",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0, -2),
        Size = UDim2.fromOffset(28, 15),
        BackgroundColor3 = Color3.fromRGB(9, 13, 24),
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        ZIndex = baseZ + 7,
    })
    UIFactory.Corner(rPill, 4)
    UIFactory.Stroke(rPill, colors.ACCENT_GOLD_BRIGHT, 1.2, 0.14)
    UIFactory.Label(rPill, {
        Name = "KeyTxt",
        Text = "[R]",
        Size = UDim2.fromScale(1, 1),
        TextSize = 9,
        TextColor = Color3.fromRGB(255, 244, 196),
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Wrapped = false,
        ZIndex = baseZ + 8,
    })

    -- Bottom "TUYỆT KỸ • 100%" Dark Obsidian-Gold Pill
    local botPill = UIFactory.Create("Frame", holder, {
        Name = "BottomUltPill",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.fromOffset(88, 16),
        BackgroundColor3 = Color3.fromRGB(9, 13, 24),
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        ZIndex = baseZ + 7,
    })
    UIFactory.PillCorner(botPill)
    UIFactory.Stroke(botPill, colors.ACCENT_GOLD_BRIGHT, 1.2, 0.16)
    local botLabel = UIFactory.Label(botPill, {
        Name = "UltCaption",
        Text = I18n.Pick("TUYỆT KỸ • 100%", "ULTIMATE • 100%"),
        Size = UDim2.fromScale(1, 1),
        TextSize = 8,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Wrapped = false,
        ZIndex = baseZ + 8,
    })

    local state = {
        locked = props.locked == true,
        cooldown = 0,
        maxCooldown = math.max(0.1, tonumber(props.maxCooldown) or 45),
    }

    ultHitBtn.MouseEnter:Connect(function()
        if not state.locked then
            UIAnimator.Tween(uiScale, { Scale = 1.07 }, MotionTokens.hoverFast.duration)
        end
    end)
    ultHitBtn.MouseLeave:Connect(function()
        UIAnimator.Tween(uiScale, { Scale = 1.0 }, MotionTokens.hoverFast.duration)
    end)
    ultHitBtn.Activated:Connect(function()
        if state.locked or state.cooldown > 0 then
            return
        end
        if type(props.onActivated) == "function" then
            props.onActivated()
        end
    end)

    local api = {
        Instance = holder,
        JOrbStroke = jOrbStroke,
        TOrbStroke = tOrbStroke,
    }

    function api:Update(newState)
        newState = newState or {}
        if newState.locked ~= nil then
            state.locked = newState.locked == true
        end
        if newState.cooldown ~= nil then
            state.cooldown = math.max(0, tonumber(newState.cooldown) or 0)
        end
        if newState.maxCooldown ~= nil then
            state.maxCooldown = math.max(0.1, tonumber(newState.maxCooldown) or 45)
        end

        if state.locked then
            crownIcon.Visible = false
            cdLabel.Text = tostring(newState.lockLabel or "Lv.20")
            cdLabel.TextSize = 10
            cdLabel.TextColor3 = colors.TEXT_MUTED
            innerGrad.Color = ColorSequence.new(Color3.fromRGB(40, 48, 72), Color3.fromRGB(18, 24, 38))
            outerStroke.Color = colors.STROKE_STEEL
            botLabel.Text = I18n.Pick("TUYỆT KỸ", "ULTIMATE")
        elseif state.cooldown > 0 then
            crownIcon.Visible = false
            cdLabel.Text = string.format("%.1fs", state.cooldown)
            cdLabel.TextSize = 12
            cdLabel.TextColor3 = Color3.fromRGB(142, 228, 255)
            innerGrad.Color = ColorSequence.new(Color3.fromRGB(48, 38, 86), Color3.fromRGB(20, 18, 44))
            outerStroke.Color = Color3.fromRGB(116, 134, 186)
            local pct = math.clamp(math.floor((1 - state.cooldown / state.maxCooldown) * 100), 0, 99)
            botLabel.Text = string.format("%s • %d%%", I18n.Pick("TUYỆT KỸ", "ULT"), pct)
        elseif newState.outOfEnergy then
            crownIcon.Visible = true
            cdLabel.Text = ""
            innerGrad.Color = ColorSequence.new(Color3.fromRGB(148, 56, 98), Color3.fromRGB(72, 24, 92))
            outerStroke.Color = colors.HP_RED
            botLabel.Text = I18n.Pick("THIẾU EN", "LOW EN")
        else
            crownIcon.Visible = true
            cdLabel.Text = ""
            innerGrad.Color = ColorSequence.new(Color3.fromRGB(238, 108, 248), Color3.fromRGB(118, 38, 224))
            outerStroke.Color = colors.ACCENT_GOLD_BRIGHT
            botLabel.Text = I18n.Pick("TUYỆT KỸ • 100%", "ULTIMATE • 100%")
        end
    end

    function api:Destroy()
        if holder and holder.Parent then
            holder:Destroy()
        end
    end

    api:Update(props)
    return holder, api
end

function HUD.Build(parent, responsiveState)
    HUD.Cleanup()
    local colors = Theme.Colors
    local snap = Store.GetSnapshot()
    local view = Store.GetView()
    local layoutOverride = view.settings and view.settings.layoutMode or "Auto"
    local viewportVec = responsiveState and responsiveState.Viewport
    local isMobile = (responsiveState and responsiveState.IsMobile == true)
        or Responsive.IsMobile(viewportVec, layoutOverride)
    local isPortrait = responsiveState and responsiveState.IsPortrait
    local player = Players.LocalPlayer

    local root = UIFactory.Create("Frame", parent, {
        Name = "CombatHUD",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 2,
    })

    -- 1. Top-Left Gold-Corner-Bracketed PlayerHUD Card (388 x 122) with Winged Live 3D Avatar Bust
    local vitalsCard = PremiumPanel.Create(root, {
        name = "PlayerHUD",
        variant = "gold",
        position = UDim2.fromOffset(16, 14),
        size = UDim2.fromOffset(isPortrait and 356 or 388, 122),
        transparency = 0.06,
        clipsDescendants = false,
    })

    local classCfg = WorldConfig.Classes[snap.player.classId] or WorldConfig.Classes.SkyGuardian

    local _, avatarPortraitApi = LiveAvatarPortrait.Create(vitalsCard, {
        name = "LiveAvatarPortrait",
        position = UDim2.fromOffset(13, 15),
        size = UDim2.fromOffset(78, 86),
        snapshot = snap,
        zIndex = 5,
    })
    local levelLabel = avatarPortraitApi.LevelLabel

    local playerNameLabel = UIFactory.Label(vitalsCard, {
        Name = "PlayerName",
        Text = (player and player.DisplayName) or "Skyborn",
        Position = UDim2.fromOffset(102, 9),
        Size = UDim2.new(1, -252, 0, 20),
        TextSize = 14,
        TextColor = colors.TEXT_PRIMARY,
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
    })

    local initTitleText, initTitleColor = resolveClassBadgeMeta(snap.player.level, snap.player.classId, false)
    local classTitlePill = UIFactory.Create("Frame", vitalsCard, {
        Name = "ClassTitlePill",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 9),
        Size = UDim2.fromOffset(140, 20),
        BackgroundColor3 = Color3.fromRGB(16, 30, 58),
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        ZIndex = 6,
    })
    UIFactory.PillCorner(classTitlePill)
    local classTitleStroke = UIFactory.Stroke(classTitlePill, initTitleColor, 1.3, 0.14)
    UIFactory.Gradient(classTitlePill, Color3.fromRGB(32, 64, 118), Color3.fromRGB(12, 22, 42), 90)

    local classTitleLabel = UIFactory.Label(classTitlePill, {
        Name = "ClassTitleText",
        Text = initTitleText,
        Position = UDim2.fromOffset(6, 0),
        Size = UDim2.new(1, -12, 1, 0),
        TextSize = 9,
        TextColor = initTitleColor,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = 7,
    })
    UIFactory.TextSizeConstraint(classTitleLabel, 7, 10)

    local _, hpBarApi = StatBar.Create(vitalsCard, {
        name = "HPBar",
        type = "HP",
        current = snap.vitals.hp,
        max = snap.vitals.maxHp,
        label = "HP",
        cornerRadius = 11,
        textSize = 12,
        position = UDim2.fromOffset(102, 34),
        size = UDim2.new(1, -112, 0, 23),
        scope = "HUD",
    })
    HUDController.BindHumanoidToBar(hpBarApi)

    local _, staminaBarApi = StatBar.Create(vitalsCard, {
        name = "StaminaBar",
        type = "Energy",
        current = snap.vitals.stamina,
        max = snap.vitals.maxStamina,
        label = "AETHER",
        cornerRadius = 10,
        textSize = 11,
        position = UDim2.fromOffset(102, 62),
        size = UDim2.new(1, -112, 0, 20),
        scope = "HUD",
    })

    local initExpPct = math.clamp(math.floor(((tonumber(snap.player.exp) or 0) / math.max(1, tonumber(snap.player.expToNext) or 100)) * 100), 0, 100)
    local _, xpBarApi = StatBar.Create(vitalsCard, {
        name = "XPBar",
        type = "EXP",
        current = snap.player.exp,
        max = snap.player.expToNext,
        cornerRadius = 9,
        customText = string.format("EXP %s / %s (%d%%)", UIFactory.FormatNumber(snap.player.exp), UIFactory.FormatNumber(snap.player.expToNext), initExpPct),
        position = UDim2.fromOffset(102, 87),
        size = UDim2.new(1, -112, 0, 17),
        textSize = 10,
        scope = "HUD",
    })

    -- 1B. Always-Visible Currency & Haki Status Pills Row Directly Below Vitals (16, 142) + Dynamic Active Buffs
    local statusPillsRow = UIFactory.Create("Frame", root, {
        Name = "CurrencyAndStatusRow",
        Position = UDim2.fromOffset(16, 142),
        Size = UDim2.fromOffset(580, 26),
        BackgroundTransparency = 1,
        ZIndex = 6,
    })
    UIFactory.ListLayout(statusPillsRow, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    local function makeHudStatusPill(name, iconKind, iconCol, strokeCol, initText, order, isClickable, onClick)
        local cls = isClickable and "TextButton" or "Frame"
        local pProps = {
            Name = name,
            Size = UDim2.fromOffset(0, 24),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = Color3.fromRGB(11, 17, 30),
            BackgroundTransparency = 0.04,
            BorderSizePixel = 0,
            LayoutOrder = order,
            ZIndex = 6,
        }
        if isClickable then
            pProps.Text = ""
            pProps.AutoButtonColor = false
        end
        local pill = UIFactory.Create(cls, statusPillsRow, pProps)
        UIFactory.Corner(pill, 7)
        local pStroke = UIFactory.Stroke(pill, strokeCol, 1.3, 0.14)
        UIFactory.Padding(pill, 0, 8, 0, 7)

        local inner = UIFactory.Create("Frame", pill, {
            Name = "Inner",
            Size = UDim2.fromOffset(0, 24),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            ZIndex = 7,
        })
        UIFactory.ListLayout(inner, Enum.FillDirection.Horizontal, 5, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
        local ic = UIFactory.Icon(inner, iconKind, UDim2.fromOffset(0, 0), 14, iconCol)
        ic.ZIndex = 7
        local lbl = UIFactory.Label(inner, {
            Name = "PillText",
            Text = initText,
            Size = UDim2.fromOffset(0, 24),
            TextSize = 11,
            TextColor = Color3.fromRGB(246, 249, 255),
            Bold = true,
            Wrapped = false,
            ZIndex = 7,
        })
        lbl.AutomaticSize = Enum.AutomaticSize.X
        if isClickable and type(onClick) == "function" then
            pill.Activated:Connect(onClick)
        end
        return pill, lbl, pStroke
    end

    local curGoldVal = tonumber((snap.currency and snap.currency.gold) or (snap.currencies and snap.currencies.gold)) or 0
    local curShardVal = tonumber((snap.currency and snap.currency.coreShards) or (snap.currencies and snap.currencies.coreShards)) or 0

    local _, hudGoldLabel = makeHudStatusPill(
        "HudGoldPill",
        "Gold",
        colors.ACCENT_GOLD_BRIGHT,
        colors.ACCENT_GOLD,
        UIFactory.FormatNumber(curGoldVal) .. " Gold",
        1,
        false
    )

    local _, hudShardLabel = makeHudStatusPill(
        "HudShardsPill",
        "CoreShards",
        colors.ACCENT_SAPPHIRE,
        colors.ACCENT_SAPPHIRE,
        UIFactory.FormatNumber(curShardVal) .. " Shards",
        2,
        false
    )

    local hudHakiPill, hudHakiLabel, hudHakiStroke = makeHudStatusPill(
        "HudHakiStatusPill",
        "Haki",
        colors.HP_RED,
        colors.HP_RED,
        "[J] Haki • Ken",
        3,
        true,
        function()
            HUDController.TriggerAction("ToggleAura")
        end
    )

    local buffDefs = {
        { id = "RaceV4", icon = "Wing", color = colors.ACCENT_GOLD_BRIGHT, order = 10 },
        { id = "DoubleExp", icon = "Sparkle", color = colors.SUCCESS, order = 11 },
        { id = "ShieldTransform", icon = "Shield", color = colors.VOID_PURPLE, order = 12 },
    }
    local buffPills = {}
    for _, bd in ipairs(buffDefs) do
        local pFrame, pLbl = makeHudStatusPill("Buff_" .. bd.id, bd.icon, bd.color, bd.color, "", bd.order, false)
        pFrame.Visible = false
        pLbl.TextColor3 = bd.color
        buffPills[bd.id] = { Frame = pFrame, Label = pLbl }
    end

    -- 2. Middle-Left Collapsible Quest Tracker with Golden Ribbon Header Banner (16, 176)
    local _, questTrackerApi = QuestTracker.Create(root, {
        name = "QuestTracker",
        position = UDim2.fromOffset(16, 176),
        size = UDim2.fromOffset(isPortrait and 316 or 314, 122),
        collapsed = view.questTrackerCollapsed,
        onToggleCollapse = function(isCol)
            Store.SetView({ questTrackerCollapsed = isCol })
        end,
        onOpenJournal = function()
            ScreenRouter.Navigate(UIState.Screens.QuestJournal)
        end,
    })
    questTrackerApi:Update({ activeQuest = snap.quest })

    -- 3. Top-Right Circular Celestial Minimap (148x148) + Sleek Purple Fruit Radar Pill & Gold Squad Pill Button
    local minimapApi = CelestialMinimap.Create(root, function()
        ScreenRouter.Navigate(UIState.Screens.WorldMap)
    end)
    if view.settings and view.settings.showMinimap == false then
        minimapApi.Instance.Visible = false
    end
    local internalFruitPill = minimapApi.Instance and minimapApi.Instance:FindFirstChild("NaturalFruitNotifierPill")
    if internalFruitPill and internalFruitPill:IsA("GuiObject") then
        -- Hide duplicate internal notifier pill because we render the always-clean Figma Purple Radar Pill below
        internalFruitPill.Size = UDim2.fromOffset(0, 0)
        internalFruitPill.ClipsDescendants = true
    end

    -- Purple Aether Fruit Radar Pill (y = 170)
    local fruitRadarPill = UIFactory.Create("TextButton", root, {
        Name = "AetherFruitRadarPill",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -16, 0, 170),
        Size = UDim2.fromOffset(186, 25),
        BackgroundColor3 = Color3.fromRGB(36, 18, 62),
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 12,
    })
    UIFactory.PillCorner(fruitRadarPill)
    local fruitRadarStroke = UIFactory.Stroke(fruitRadarPill, Color3.fromRGB(192, 132, 252), 1.4, 0.10)
    local frIcon = UIFactory.Icon(fruitRadarPill, "Fruit", UDim2.new(0, 8, 0.5, -7), 14, Color3.fromRGB(232, 180, 255))
    frIcon.ZIndex = 13
    local fruitRadarLabel = UIFactory.Label(fruitRadarPill, {
        Name = "RadarText",
        Text = I18n.Pick("Radar Aether: Quét Đảo", "Aether Radar: Scanning"),
        Position = UDim2.fromOffset(26, 0),
        Size = UDim2.new(1, -32, 1, 0),
        TextSize = 10,
        TextColor = Color3.fromRGB(244, 232, 255),
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = 13,
    })
    fruitRadarPill.Activated:Connect(function()
        ScreenRouter.Navigate(UIState.Screens.Fruits)
    end)

    -- Gold Squad Pill Button (y = 200) -> opens SocialRewards [B]
    local squadPillBtn = UIFactory.Create("TextButton", root, {
        Name = "SquadStatusPillBtn",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -16, 0, 200),
        Size = UDim2.fromOffset(172, 25),
        BackgroundColor3 = Color3.fromRGB(12, 19, 34),
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Visible = not isMobile,
        ZIndex = 12,
    })
    UIFactory.PillCorner(squadPillBtn)
    UIFactory.Stroke(squadPillBtn, colors.ACCENT_GOLD_BRIGHT, 1.4, 0.14)
    local sqIcon = UIFactory.Icon(squadPillBtn, "Shield", UDim2.new(0, 8, 0.5, -7), 14, colors.ACCENT_GOLD_BRIGHT)
    sqIcon.ZIndex = 13
    local companionTitle = UIFactory.Label(squadPillBtn, {
        Name = "CompanionTitle",
        Text = I18n.Pick("ĐỘI HÌNH: SOLO (1/4)", "SQUAD: SOLO (1/4)"),
        Position = UDim2.fromOffset(26, 0),
        Size = UDim2.new(1, -32, 1, 0),
        TextSize = 10,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = 13,
    })
    squadPillBtn.Activated:Connect(function()
        ScreenRouter.Navigate(UIState.Screens.SocialRewards)
    end)

    -- 4. Top-Center Proximity/Combat-Gated Boss HP Bar with Golden Crown Ribbon (#6)
    local _, bossBarApi = RaidPhase.Create(root, {
        name = "BossHUD",
        position = isPortrait and UDim2.new(0.5, 0, 0, 326) or UDim2.new(0.5, 0, 0, 22),
        size = UDim2.fromOffset(isPortrait and 486 or 528, 74),
        visible = false,
    })

    -- 4B. Dynamic Action-RPG Combo Card (Right-Center, Tilted -8 deg Glossy Gold Rank Square)
    local comboCard = PremiumPanel.Create(root, {
        name = "ComboRankCard",
        variant = "gold",
        anchorPoint = Vector2.new(1, 0.5),
        position = UDim2.new(1, -16, 0.42, 0),
        size = UDim2.fromOffset(216, 68),
        transparency = 0.06,
        clipsDescendants = false,
        visible = false,
        zIndex = 8,
    })

    local comboGradeBox = UIFactory.Create("Frame", comboCard, {
        Name = "RankGradeBox",
        Position = UDim2.fromOffset(10, 11),
        Size = UDim2.fromOffset(44, 44),
        Rotation = -8,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 9,
    })
    UIFactory.Corner(comboGradeBox, 9)
    local comboGradeStroke = UIFactory.Stroke(comboGradeBox, Color3.fromRGB(255, 242, 178), 1.8, 0.04)
    local comboGradeGrad = UIFactory.Gradient(comboGradeBox, Color3.fromRGB(252, 214, 104), Color3.fromRGB(196, 136, 32), 90)

    local comboGradeLabel = UIFactory.Label(comboGradeBox, {
        Name = "RankGrade",
        Text = "S",
        Size = UDim2.fromScale(1, 1),
        TextSize = 24,
        TextColor = Color3.fromRGB(14, 18, 30),
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Wrapped = false,
        ZIndex = 10,
    })

    local comboCountLabel = UIFactory.Label(comboCard, {
        Name = "ComboCount",
        Text = "2 COMBO HITS",
        Position = UDim2.fromOffset(64, 8),
        Size = UDim2.new(1, -72, 0, 22),
        TextSize = 15,
        TextColor = colors.TEXT_PRIMARY,
        Bold = true,
        RichText = true,
        Wrapped = false,
        ZIndex = 9,
    })

    local comboTitleLabel = UIFactory.Label(comboCard, {
        Name = "ComboTitle",
        Text = "+18% SÁT THƯƠNG AETHER",
        Position = UDim2.fromOffset(64, 30),
        Size = UDim2.new(1, -72, 0, 14),
        TextSize = 9,
        TextColor = Color3.fromRGB(92, 225, 255),
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = 9,
    })

    local comboTimerTrack = UIFactory.Create("Frame", comboCard, {
        Name = "ComboTimerTrack",
        Position = UDim2.fromOffset(64, 49),
        Size = UDim2.new(1, -76, 0, 6),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 9,
    })
    UIFactory.PillCorner(comboTimerTrack)

    local comboTimerFill = UIFactory.Create("Frame", comboTimerTrack, {
        Name = "ComboTimerFill",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = colors.ACCENT_GOLD_BRIGHT,
        BorderSizePixel = 0,
        ZIndex = 10,
    })
    UIFactory.PillCorner(comboTimerFill)
    for _, pct in ipairs({ 0.25, 0.50, 0.75 }) do
        UIFactory.Create("Frame", comboTimerTrack, {
            Name = "Seg_" .. tostring(math.floor(pct * 100)),
            Position = UDim2.fromScale(pct, 0),
            Size = UDim2.new(0, 2, 1, 0),
            BackgroundColor3 = colors.BG_800,
            BorderSizePixel = 0,
            ZIndex = 11,
        })
    end


    -- 4C. Center Tactical Ranged Aim Reticle (8-Segment Dashed Crimson Circle + 45-deg Gold Diamond + Crimson Dot)
    local aimReticle = UIFactory.Create("Frame", root, {
        Name = "CenterAimReticle",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.47),
        Size = UDim2.fromOffset(48, 48),
        BackgroundTransparency = 1,
        Active = false,
        ZIndex = 6,
    })
    local aimReticleScale = Instance.new("UIScale")
    aimReticleScale.Scale = 1.0
    aimReticleScale.Parent = aimReticle

    local aimDashSegments = {}
    for segIdx = 1, 8 do
        local angDeg = (segIdx - 1) * 45
        local angRad = math.rad(angDeg)
        local rPx = 20
        local arcSeg = UIFactory.Create("Frame", aimReticle, {
            Name = "CrimsonArc_" .. tostring(segIdx),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, math.cos(angRad) * rPx, 0.5, math.sin(angRad) * rPx),
            Size = UDim2.fromOffset(8, 2),
            Rotation = angDeg + 90,
            BackgroundColor3 = Color3.fromRGB(251, 55, 98),
            BackgroundTransparency = 0.08,
            BorderSizePixel = 0,
            Active = false,
            ZIndex = 7,
        })
        UIFactory.PillCorner(arcSeg)
        table.insert(aimDashSegments, arcSeg)
    end

    local aimDiamond = UIFactory.Create("Frame", aimReticle, {
        Name = "InnerGoldDiamond",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(18, 18),
        Rotation = 45,
        BackgroundTransparency = 1,
        Active = false,
        ZIndex = 7,
    })
    UIFactory.Corner(aimDiamond, 2)
    local aimDiamondStroke = UIFactory.Stroke(aimDiamond, Color3.fromRGB(253, 224, 71), 1.7, 0.05)

    local aimCoreDot = UIFactory.Create("Frame", aimReticle, {
        Name = "AimCoreDot",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(6, 6),
        BackgroundColor3 = Color3.fromRGB(251, 55, 98),
        BorderSizePixel = 0,
        Active = false,
        ZIndex = 8,
    })
    UIFactory.PillCorner(aimCoreDot)
    local aimCoreStroke = UIFactory.Stroke(aimCoreDot, Color3.fromRGB(10, 14, 24), 1.2, 0.15)

    local aimModePill = UIFactory.Create("Frame", aimReticle, {
        Name = "AimLockPill",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 1, 4),
        Size = UDim2.fromOffset(118, 16),
        BackgroundColor3 = Color3.fromRGB(9, 13, 24),
        BackgroundTransparency = 0.12,
        BorderSizePixel = 0,
        Visible = false,
        Active = false,
        ZIndex = 8,
    })
    UIFactory.PillCorner(aimModePill)
    local aimModeStroke = UIFactory.Stroke(aimModePill, Color3.fromRGB(251, 55, 98), 1.1, 0.15)
    local aimModeLabel = UIFactory.Label(aimModePill, {
        Name = "AimModeText",
        Text = "AIM",
        Size = UDim2.fromScale(1, 1),
        TextSize = 8,
        TextColor = Color3.fromRGB(254, 226, 138),
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = 9,
    })

    local function pulseAimReticle()
        aimReticleScale.Scale = 1.24
        UIAnimator.Tween(aimReticleScale, { Scale = 1.0 }, 0.16)
    end

    -- 4D. Curved 3-Segment Cyan Dash/Dodge Arc ("LƯỚT 2/3") + "NÉ HOÀN HẢO! +25 EN" Callout Pill (1:1 Screenshot 2)
    local dashCluster = UIFactory.Create("Frame", root, {
        Name = "DashDodgeCluster",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(isMobile and 0.34 or 0.37, isMobile and 0.56 or 0.61),
        Size = UDim2.fromOffset(110, 118),
        BackgroundTransparency = 1,
        ClipsDescendants = false,
        Active = false,
        ZIndex = 6,
    })

    -- Smooth Right-Curving 3-Segment Crescent Arc (Top = Charge 3, Mid = Charge 2, Bot = Charge 1)
    local dashArcBeads = { {}, {}, {} }
    local segAngles = {
        { -44, -37.5, -31, -24.5, -18 },
        { -12, -6, 0, 6, 12 },
        { 18, 24.5, 31, 37.5, 44 },
    }
    local arcRadius = 54
    local arcCenterX = -18
    for segIdx = 1, 3 do
        for bIdx, deg in ipairs(segAngles[segIdx]) do
            local rad = math.rad(deg)
            local bx = arcCenterX + math.cos(rad) * arcRadius
            local by = math.sin(rad) * arcRadius
            local bead = UIFactory.Create("Frame", dashCluster, {
                Name = string.format("DashArc_%d_%d", segIdx, bIdx),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, bx, 0.5, by),
                Size = UDim2.fromOffset(5, 10),
                Rotation = deg,
                BackgroundColor3 = Color3.fromRGB(56, 224, 255),
                BorderSizePixel = 0,
                Active = false,
                ZIndex = 7,
            })
            UIFactory.PillCorner(bead)
            table.insert(dashArcBeads[segIdx], bead)
        end
    end

    local dashCountPill = UIFactory.Create("Frame", dashCluster, {
        Name = "DashCountPill",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0.5, 42, 0.5, 6),
        Size = UDim2.fromOffset(64, 20),
        BackgroundColor3 = Color3.fromRGB(8, 16, 28),
        BackgroundTransparency = 0.06,
        BorderSizePixel = 0,
        Active = false,
        ZIndex = 8,
    })
    UIFactory.PillCorner(dashCountPill)
    local dashCountStroke = UIFactory.Stroke(dashCountPill, Color3.fromRGB(56, 189, 248), 1.2, 0.12)
    local dashCountLabel = UIFactory.Label(dashCountPill, {
        Name = "DashCountText",
        Text = I18n.Pick("LƯỚT 3/3", "DASH 3/3"),
        Size = UDim2.fromScale(1, 1),
        TextSize = 9,
        TextColor = Color3.fromRGB(224, 246, 255),
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Wrapped = false,
        ZIndex = 9,
    })

    local perfectDodgePill = UIFactory.Create("Frame", dashCluster, {
        Name = "PerfectDodgeCallout",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(0.5, 16, 0.5, 8),
        Size = UDim2.fromOffset(154, 26),
        BackgroundColor3 = Color3.fromRGB(7, 20, 36),
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        Visible = false,
        Active = false,
        ZIndex = 9,
    })
    UIFactory.PillCorner(perfectDodgePill)
    local perfectDodgeStroke = UIFactory.Stroke(perfectDodgePill, Color3.fromRGB(34, 211, 238), 1.5, 0.04)
    local perfectDodgeScale = Instance.new("UIScale")
    perfectDodgeScale.Scale = 1.0
    perfectDodgeScale.Parent = perfectDodgePill

    local pdSpark = UIFactory.Create("Frame", perfectDodgePill, {
        Name = "CyanSpark",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 11, 0.5, 0),
        Size = UDim2.fromOffset(7, 7),
        Rotation = 45,
        BackgroundColor3 = Color3.fromRGB(103, 232, 249),
        BorderSizePixel = 0,
        Active = false,
        ZIndex = 10,
    })
    UIFactory.Corner(pdSpark, 1)

    local perfectDodgeLabel = UIFactory.Label(perfectDodgePill, {
        Name = "CalloutText",
        Text = I18n.Pick("NÉ HOÀN HẢO! +25 EN", "PERFECT DODGE! +25 EN"),
        Position = UDim2.fromOffset(24, 0),
        Size = UDim2.new(1, -30, 1, 0),
        TextSize = 10,
        TextColor = Color3.fromRGB(125, 243, 255),
        Bold = true,
        XAlign = Enum.TextXAlignment.Left,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = 10,
    })

    local function pruneAndCountDashCharges(nowClock)
        local st = HUD.DashState
        local kept = {}
        for _, spentAt in ipairs(st.SpentClocks) do
            if (nowClock - spentAt) < st.RechargeSec then
                table.insert(kept, spentAt)
            end
        end
        st.SpentClocks = kept
        return math.clamp(st.MaxCharges - #kept, 0, st.MaxCharges)
    end

    local function isEnemyWithinDodgeRange()
        local ch = player and player.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if not hrp then
            return false
        end
        local pPos = hrp.Position
        for _, fn in ipairs({ "ActiveBosses", "ActiveEnemies" }) do
            local f = workspace:FindFirstChild(fn)
            if f then
                for _, m in ipairs(f:GetChildren()) do
                    local part = m:IsA("Model") and (m.PrimaryPart or m:FindFirstChild("Body") or m:FindFirstChildWhichIsA("BasePart")) or nil
                    if part and (part.Position - pPos).Magnitude <= 34 then
                        return true
                    end
                end
            end
        end
        return false
    end

    local function triggerDodgeFeedback(isPerfectExplicit, spendCharge)
        local now = os.clock()
        local st = HUD.DashState
        if spendCharge then
            if (now - st.LastConsumeClock) < 0.18 then
                return
            end
            st.LastConsumeClock = now
            pruneAndCountDashCharges(now)
            if #st.SpentClocks < st.MaxCharges then
                table.insert(st.SpentClocks, now)
            else
                st.SpentClocks[1] = now
            end
        end

        local kenActive = (player and (player:GetAttribute("InstinctActive") == true or player:GetAttribute("HakiInstinct") == true))
            or (player and player.Character and player.Character:GetAttribute("HakiInstinct") == true)
        local isPerfect = (isPerfectExplicit == true) or kenActive or isEnemyWithinDodgeRange()

        if isPerfect then
            perfectDodgeLabel.Text = I18n.Pick("NÉ HOÀN HẢO! +25 EN", "PERFECT DODGE! +25 EN")
            perfectDodgeStroke.Color = Color3.fromRGB(34, 211, 238)
            pdSpark.BackgroundColor3 = Color3.fromRGB(103, 232, 249)
        else
            perfectDodgeLabel.Text = I18n.Pick("LƯỚT NÉ AETHER!", "AETHER EVADE!")
            perfectDodgeStroke.Color = Color3.fromRGB(56, 189, 248)
            pdSpark.BackgroundColor3 = Color3.fromRGB(125, 211, 252)
        end

        st.CalloutUntil = now + 1.85
        perfectDodgePill.Visible = true
        perfectDodgeScale.Scale = 1.18
        UIAnimator.Tween(perfectDodgeScale, { Scale = 1.0 }, 0.18)
    end

    local function bindCharacterDashSignals(ch)
        if not ch then
            return
        end
        table.insert(HUD.Connections, ch:GetAttributeChangedSignal("LastDashAt"):Connect(function()
            local ts = tonumber(ch:GetAttribute("LastDashAt")) or 0
            if ts > 0 then
                triggerDodgeFeedback(false, true)
            end
        end))
    end
    if player then
        if player.Character then
            bindCharacterDashSignals(player.Character)
        end
        table.insert(HUD.Connections, player.CharacterAdded:Connect(bindCharacterDashSignals))
    end


    local function registerComboHit(explicitCount)
        local now = os.clock()
        if type(explicitCount) == "number" and explicitCount > 0 then
            HUD.ComboState.Count = math.floor(explicitCount)
        else
            if (now - HUD.ComboState.LastHitClock) <= HUD.ComboState.WindowSec then
                HUD.ComboState.Count = HUD.ComboState.Count + 1
            else
                HUD.ComboState.Count = 1
            end
        end
        HUD.ComboState.LastHitClock = now

        if HUD.ComboState.Count >= 2 then
            local rankGrade, rankCol, rankTitle = resolveComboRankMeta(HUD.ComboState.Count)
            comboCard.Visible = true
            comboGradeLabel.Text = rankGrade
            comboGradeStroke.Color = rankCol
            if rankGrade == "SS" then
                comboGradeGrad.Color = ColorSequence.new(Color3.fromRGB(255, 132, 158), Color3.fromRGB(186, 28, 92))
                comboGradeLabel.TextColor3 = Color3.fromRGB(255, 250, 252)
            elseif rankGrade == "S" then
                comboGradeGrad.Color = ColorSequence.new(Color3.fromRGB(252, 214, 104), Color3.fromRGB(196, 136, 32))
                comboGradeLabel.TextColor3 = Color3.fromRGB(14, 18, 30)
            elseif rankGrade == "A" then
                comboGradeGrad.Color = ColorSequence.new(Color3.fromRGB(216, 156, 255), Color3.fromRGB(118, 42, 212))
                comboGradeLabel.TextColor3 = Color3.fromRGB(255, 250, 255)
            else
                comboGradeGrad.Color = ColorSequence.new(Color3.fromRGB(84, 214, 255), Color3.fromRGB(24, 98, 206))
                comboGradeLabel.TextColor3 = Color3.fromRGB(250, 254, 255)
            end
            comboCountLabel.Text = string.format("<b>%d</b> <font size='11'>COMBO HITS</font>", HUD.ComboState.Count)
            comboTitleLabel.Text = rankTitle
            comboTimerFill.Size = UDim2.fromScale(1, 1)
            comboTimerFill.BackgroundColor3 = rankCol
        end
    end

    local function bindComboRemotes()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            for _, remoteName in ipairs({ "CombatFX", "CombatEvent" }) do
                local ev = remotes:FindFirstChild(remoteName)
                if ev and ev:IsA("RemoteEvent") then
                    table.insert(HUD.Connections, ev.OnClientEvent:Connect(function(payload, arg2)
                        if type(payload) == "table" then
                            local kind = tostring(payload.Kind or payload.kind or "")
                            local action = tostring(payload.Action or payload.action or payload.type or payload.fx or "")
                            local actorId = tonumber(payload.Actor or payload.Owner or payload.userId)
                            local isMine = (actorId == nil) or (player and actorId == player.UserId)

                            if kind == "InstinctDodge" or action == "InstinctDodge" or payload.Dodge == true or payload.LogiaDodge == true then
                                if isMine then
                                    triggerDodgeFeedback(true, false)
                                end
                            elseif kind == "Dodge" or action == "Dash" or action == "Dodge" or action == "FlashStep" then
                                if isMine then
                                    triggerDodgeFeedback(false, true)
                                end
                            elseif payload.comboCount or payload.combo then
                                registerComboHit(tonumber(payload.comboCount or payload.combo))
                                pulseAimReticle()
                            elseif kind == "DamageNumber" or kind == "Hit" or kind == "GunShot" or action == "Hit" or action == "Damage" or action == "SlashHit" or payload.damage or payload.amount or payload.Amount then
                                local rawTxt = string.upper(tostring(payload.Text or payload.text or payload.amount or payload.Amount or ""))
                                local isHealOrMiss = rawTxt:find("HP", 1, true) ~= nil or rawTxt:find("DODGE", 1, true) ~= nil or rawTxt:find("MISS", 1, true) ~= nil
                                if not isHealOrMiss and (payload.attacker == nil or payload.attacker == player) then
                                    registerComboHit(nil)
                                    pulseAimReticle()
                                end
                            end
                        elseif type(payload) == "string" then
                            local pLow = string.lower(payload)
                            if string.find(pLow, "hit", 1, true) or string.find(pLow, "damage", 1, true) or string.find(pLow, "combo", 1, true) then
                                registerComboHit(type(arg2) == "number" and arg2 or nil)
                                pulseAimReticle()
                            end
                        end
                    end))
                end
            end
        end

        if player then
            table.insert(HUD.Connections, player:GetAttributeChangedSignal("ComboCount"):Connect(function()
                local c = tonumber(player:GetAttribute("ComboCount")) or 0
                if c >= 2 then
                    registerComboHit(c)
                elseif c == 0 then
                    HUD.ComboState.Count = 0
                    comboCard.Visible = false
                end
            end))
        end
    end
    bindComboRemotes()

    -- 5. Contextual [E] INTERACT Prompt Pill above Combat Dock
    local interactBtn, interactApi = PremiumButton.Create(root, {
        name = "ContextInteractPrompt",
        text = "[E]  •  " .. tostring((view.interactPrompt and view.interactPrompt.label) or I18n.Pick("TƯƠNG TÁC", "INTERACT")),
        variant = "gold",
        icon = "Sparkle",
        anchorPoint = Vector2.new(0.5, 1),
        position = UDim2.new(0.5, 0, 1, isMobile and -116 or -138),
        size = UDim2.fromOffset(224, 34),
        textSize = 12,
        onActivated = function()
            HUDController.TriggerAction("Interact")
        end,
    })
    interactBtn.Visible = (view.interactPrompt and view.interactPrompt.visible) == true

    -- Responsive horizontal offset so Bottom-Left Quick Dock (x=12..458) NEVER collides with Bottom-Center Combat Dock (width 656)
    local vpW = (viewportVec and viewportVec.X) or 1920
    local combatOffsetX = isMobile and 0 or math.max(28, math.ceil(796 - vpW * 0.5))

    -- 6. Bottom-Left Obsidian-Gold Quick Dock (9 Tactile Vertical Icon-Over-Caption Tiles with Hotkey Badges)
    local quickNavDefs = {
        { key = "ESC", labelVi = "Menu",    labelEn = "Menu",   icon = "Settings", route = UIState.Screens.MainMenu,      style = "obsidian", mobileKeep = true },
        { key = "G",   labelVi = "Trái",    labelEn = "Fruit",  icon = "Fruit",    route = UIState.Screens.Fruits,        style = "gold",     mobileKeep = true },
        { key = "N",   labelVi = "Shop",    labelEn = "Shop",   icon = "Gold",     route = UIState.Screens.NPCShop,       style = "sapphire", mobileKeep = false },
        { key = "I",   labelVi = "Túi",     labelEn = "Bag",    icon = "Bag",      route = UIState.Screens.Inventory,     style = "obsidian", mobileKeep = true },
        { key = "K",   labelVi = "Kỹ Năng", labelEn = "Skills", icon = "Skill",    route = UIState.Screens.Skills,        style = "obsidian", mobileKeep = true },
        { key = "L",   labelVi = "Nhật Ký", labelEn = "Quests", icon = "Quest",    route = UIState.Screens.QuestJournal,  style = "obsidian", mobileKeep = false },
        { key = "F",   labelVi = "Rèn",     labelEn = "Forge",  icon = "Forge",    route = UIState.Screens.Forge,         style = "obsidian", mobileKeep = false },
        { key = "B",   labelVi = "Quà",     labelEn = "Gifts",  icon = "Gift",     route = UIState.Screens.SocialRewards, style = "obsidian", mobileKeep = true },
        { key = "P",   labelVi = "Raid",    labelEn = "Raid",   icon = "Raid",     route = UIState.Screens.RaidReady,     style = "crimson",  mobileKeep = true },
    }

    local activeQuickDefs = {}
    for _, qd in ipairs(quickNavDefs) do
        if (not isMobile) or qd.mobileKeep then
            table.insert(activeQuickDefs, qd)
        end
    end

    local qTileW = isMobile and 42 or 44
    local qGap = 4
    local quickDockW = (#activeQuickDefs * qTileW) + ((#activeQuickDefs - 1) * qGap) + 18

    local quickDock = PremiumPanel.Create(root, {
        name = "QuickNavDock",
        variant = "gold",
        anchorPoint = Vector2.new(0, 1),
        position = UDim2.new(0, 12, 1, -10),
        size = UDim2.fromOffset(quickDockW, 56),
        transparency = 0.06,
        zIndex = 6,
    })

    local quickTilesRow = UIFactory.Create("Frame", quickDock, {
        Name = "QuickTilesRow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, -14, 0, 44),
        BackgroundTransparency = 1,
        ZIndex = 7,
    })
    UIFactory.ListLayout(quickTilesRow, Enum.FillDirection.Horizontal, qGap, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)

    local QUICK_STYLES = {
        obsidian = {
            Top = Color3.fromRGB(22, 34, 58),
            Bottom = Color3.fromRGB(10, 16, 28),
            Border = Color3.fromRGB(84, 110, 152),
            Icon = Color3.fromRGB(228, 236, 252),
            Text = Color3.fromRGB(224, 232, 248),
        },
        gold = {
            Top = Color3.fromRGB(252, 212, 98),
            Bottom = Color3.fromRGB(186, 114, 20),
            Border = Color3.fromRGB(255, 244, 176),
            Icon = Color3.fromRGB(20, 18, 12),
            Text = Color3.fromRGB(20, 18, 12),
        },
        sapphire = {
            Top = Color3.fromRGB(56, 189, 248),
            Bottom = Color3.fromRGB(29, 78, 216),
            Border = Color3.fromRGB(162, 230, 255),
            Icon = Color3.fromRGB(250, 253, 255),
            Text = Color3.fromRGB(250, 253, 255),
        },
        crimson = {
            Top = Color3.fromRGB(251, 68, 106),
            Bottom = Color3.fromRGB(159, 18, 57),
            Border = Color3.fromRGB(255, 182, 200),
            Icon = Color3.fromRGB(255, 250, 252),
            Text = Color3.fromRGB(255, 250, 252),
        },
    }

    for idx, qd in ipairs(activeQuickDefs) do
        local st = QUICK_STYLES[qd.style] or QUICK_STYLES.obsidian
        local isAccent = (qd.style ~= "obsidian")

        local tile = UIFactory.Create("TextButton", quickTilesRow, {
            Name = "Nav_" .. qd.key,
            Size = UDim2.fromOffset(qTileW, 44),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 0.02,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = idx,
            ZIndex = 8,
        })
        UIFactory.Corner(tile, 8)
        local tileStroke = UIFactory.Stroke(tile, st.Border, isAccent and 1.6 or 1.2, isAccent and 0.04 or 0.24)
        UIFactory.Gradient(tile, st.Top, st.Bottom, 90)

        local tileScale = Instance.new("UIScale")
        tileScale.Scale = 1.0
        tileScale.Parent = tile

        if isAccent then
            local gloss = UIFactory.Create("Frame", tile, {
                Name = "TopGloss",
                Position = UDim2.fromOffset(2, 2),
                Size = UDim2.new(1, -4, 0.38, 0),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = 0.78,
                BorderSizePixel = 0,
                Active = false,
                ZIndex = 9,
            })
            UIFactory.Corner(gloss, 6)
        end

        local qIcon = UIFactory.Icon(
            tile,
            qd.icon,
            UDim2.new(0.5, -8, 0, 6),
            16,
            st.Icon
        )
        qIcon.ZIndex = 10

        local qCaption = UIFactory.Label(tile, {
            Name = "Caption",
            Text = I18n.Pick(qd.labelVi, qd.labelEn),
            Position = UDim2.new(0, 1, 1, -15),
            Size = UDim2.new(1, -2, 0, 13),
            TextSize = 8,
            TextColor = st.Text,
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            Truncate = Enum.TextTruncate.AtEnd,
            Wrapped = false,
            ZIndex = 10,
        })
        UIFactory.TextSizeConstraint(qCaption, 7, 9)

        if not isMobile then
            local keyW = (#qd.key >= 3) and 19 or 13
            local kBadge = UIFactory.Create("Frame", tile, {
                Name = "HotkeyBadge",
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -2, 0, 2),
                Size = UDim2.fromOffset(keyW, 11),
                BackgroundColor3 = Color3.fromRGB(8, 12, 22),
                BackgroundTransparency = 0.08,
                BorderSizePixel = 0,
                Active = false,
                ZIndex = 11,
            })
            UIFactory.Corner(kBadge, 3)
            UIFactory.Label(kBadge, {
                Name = "KeyText",
                Text = qd.key,
                Size = UDim2.fromScale(1, 1),
                TextSize = 7,
                TextColor = Color3.fromRGB(246, 232, 184),
                Bold = true,
                XAlign = Enum.TextXAlignment.Center,
                Wrapped = false,
                ZIndex = 12,
            })
        end

        tile.MouseEnter:Connect(function()
            UIAnimator.Tween(tileScale, { Scale = 1.06 }, MotionTokens.hoverFast.duration)
            tileStroke.Color = colors.ACCENT_GOLD_BRIGHT
        end)
        tile.MouseLeave:Connect(function()
            UIAnimator.Tween(tileScale, { Scale = 1.0 }, MotionTokens.hoverFast.duration)
            tileStroke.Color = st.Border
        end)
        tile.Activated:Connect(function()
            ScreenRouter.ToggleScreen(qd.route)
        end)
    end

    -- 7. Bottom-Center Loadout Hotbar [1]-[4] (Full Glossy Champagne Gold Pill for Active Slot)
    local activeSlotIdx = tonumber((player and player:GetAttribute("ActiveSlot")) or view.activeHotbarSlot) or 1

    local function resolveLoadoutSlotNames(snapshot)
        local eqWeapon = snapshot and snapshot.equipment and snapshot.equipment.Weapon
        local eqFruit = (snapshot and snapshot.fruits and (snapshot.fruits.equipped or snapshot.fruits.activeFruit))
            or (player and player:GetAttribute("EquippedFruit"))
        local eqStyle = (player and player:GetAttribute("EquippedStyle")) or I18n.Pick("Võ Thuật", "Martial")
        local eqGun = (player and player:GetAttribute("EquippedGun")) or I18n.Pick("Súng Aether", "Aether Gun")

        local fruitDisplay = I18n.Pick("Trái Aether", "Aether Fruit")
        if type(eqFruit) == "string" and eqFruit ~= "" and eqFruit ~= "None" then
            fruitDisplay = eqFruit
        end

        local weaponDisplay = I18n.Pick("Thiên Kiếm", "Skyblade")
        if type(eqWeapon) == "string" and eqWeapon ~= "" then
            local RarityConfig = require(Shared:WaitForChild("Config"):WaitForChild("RarityConfig"))
            local itemCfg = RarityConfig.Items[eqWeapon]
            weaponDisplay = (itemCfg and itemCfg.Name) or eqWeapon
        end

        return {
            [1] = tostring(eqStyle),
            [2] = tostring(fruitDisplay),
            [3] = tostring(weaponDisplay),
            [4] = tostring(eqGun),
        }
    end

    local slotNames = resolveLoadoutSlotNames(snap)
    local pillW = isMobile and 78 or 148
    local pillGap = isMobile and 6 or 8
    local loadoutTotalW = (4 * pillW) + (3 * pillGap)

    local loadoutBar = UIFactory.Create("Frame", root, {
        Name = "LoadoutHotbar1To4",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, combatOffsetX, 1, isMobile and -74 or -98),
        Size = UDim2.fromOffset(loadoutTotalW, 30),
        BackgroundTransparency = 1,
        ZIndex = 7,
    })
    UIFactory.ListLayout(loadoutBar, Enum.FillDirection.Horizontal, pillGap, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)

    local loadoutSlotRefs = {}
    local function applyLoadoutPillVisual(ref, isActive, slotLabelText)
        local cleanText = tostring(slotLabelText or "")
        if isActive then
            ref.Grad.Color = ColorSequence.new(Color3.fromRGB(251, 215, 110), Color3.fromRGB(198, 136, 32))
            ref.Stroke.Color = Color3.fromRGB(255, 243, 184)
            ref.Stroke.Thickness = 2.0
            ref.Stroke.Transparency = 0.0
            ref.Gloss.Visible = true
            ref.Scale.Scale = 1.04
            ref.KeyBox.BackgroundColor3 = Color3.fromRGB(14, 20, 34)
            ref.KeyLabel.TextColor3 = Color3.fromRGB(255, 232, 156)
            ref.NameLabel.TextColor3 = Color3.fromRGB(14, 18, 30)
            ref.NameLabel.Text = isMobile and string.upper(cleanText) or ("* " .. string.upper(cleanText))
        else
            ref.Grad.Color = ColorSequence.new(Color3.fromRGB(22, 34, 58), Color3.fromRGB(11, 18, 33))
            ref.Stroke.Color = colors.STROKE_STEEL
            ref.Stroke.Thickness = 1.2
            ref.Stroke.Transparency = 0.20
            ref.Gloss.Visible = false
            ref.Scale.Scale = 1.0
            ref.KeyBox.BackgroundColor3 = Color3.fromRGB(8, 13, 24)
            ref.KeyLabel.TextColor3 = Color3.fromRGB(168, 194, 232)
            ref.NameLabel.TextColor3 = Color3.fromRGB(218, 228, 246)
            ref.NameLabel.Text = cleanText
        end
    end

    for slotIdx = 1, 4 do
        local pillBtn = UIFactory.Create("TextButton", loadoutBar, {
            Name = "LoadoutSlot_" .. tostring(slotIdx),
            Size = UDim2.fromOffset(pillW, 28),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 0.02,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = slotIdx,
            ZIndex = 8,
        })
        UIFactory.PillCorner(pillBtn)
        local pStroke = UIFactory.Stroke(pillBtn, colors.STROKE_STEEL, 1.2, 0.2)
        local pGrad = UIFactory.Gradient(pillBtn, Color3.fromRGB(22, 34, 58), Color3.fromRGB(11, 18, 33), 90)

        local pScale = Instance.new("UIScale")
        pScale.Scale = 1.0
        pScale.Parent = pillBtn

        local pGloss = UIFactory.Create("Frame", pillBtn, {
            Name = "TopGloss",
            Position = UDim2.fromOffset(4, 2),
            Size = UDim2.new(1, -8, 0.42, 0),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 0.76,
            BorderSizePixel = 0,
            Visible = false,
            Active = false,
            ZIndex = 9,
        })
        UIFactory.PillCorner(pGloss)

        local keyBox = UIFactory.Create("Frame", pillBtn, {
            Name = "KeyBadge",
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 5, 0.5, 0),
            Size = UDim2.fromOffset(18, 18),
            BackgroundColor3 = Color3.fromRGB(8, 13, 24),
            BorderSizePixel = 0,
            Active = false,
            ZIndex = 10,
        })
        UIFactory.PillCorner(keyBox)
        local keyLbl = UIFactory.Label(keyBox, {
            Name = "KeyText",
            Text = tostring(slotIdx),
            Size = UDim2.fromScale(1, 1),
            TextSize = 10,
            TextColor = Color3.fromRGB(168, 194, 232),
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            Wrapped = false,
            ZIndex = 11,
        })

        local iconOffset = 27
        if not isMobile then
            local sIcon = UIFactory.Icon(
                pillBtn,
                SLOT_ICONS[slotIdx] or "Sword",
                UDim2.new(0, 27, 0.5, -7),
                14,
                Color3.fromRGB(236, 206, 128)
            )
            sIcon.ZIndex = 10
            iconOffset = 44
        end

        local nameLbl = UIFactory.Label(pillBtn, {
            Name = "SlotName",
            Text = slotNames[slotIdx],
            Position = UDim2.fromOffset(iconOffset, 0),
            Size = UDim2.new(1, -(iconOffset + 6), 1, 0),
            TextSize = isMobile and 9 or 10,
            TextColor = Color3.fromRGB(218, 228, 246),
            Bold = true,
            Truncate = Enum.TextTruncate.AtEnd,
            Wrapped = false,
            ZIndex = 10,
        })

        local ref = {
            Button = pillBtn,
            Stroke = pStroke,
            Grad = pGrad,
            Gloss = pGloss,
            Scale = pScale,
            KeyBox = keyBox,
            KeyLabel = keyLbl,
            NameLabel = nameLbl,
        }
        loadoutSlotRefs[slotIdx] = ref
        applyLoadoutPillVisual(ref, slotIdx == activeSlotIdx, slotNames[slotIdx])

        pillBtn.Activated:Connect(function()
            HUDController.SelectHotbarSlot(slotIdx)
        end)
    end

    -- 8. Combat Controls: Desktop 8 Glossy Skill Cards + Center 45 deg Diamond Ultimate [R] OR Mobile Right-Thumb Arc
    local skillsList = classCfg.Skills or {}
    local sk1 = skillsList[1] or { Id = "SkySlash", Name = "Thiên Trảm", LevelReq = 1, Cooldown = 5, EnergyCost = 15 }
    local sk2 = skillsList[2] or { Id = "GuardianShield", Name = "Khiên Thánh", LevelReq = 1, Cooldown = 10, EnergyCost = 20 }
    local sk3 = skillsList[4] or { Id = "JudgmentStrike", Name = "Phán Quyết", LevelReq = 10, Cooldown = 12, EnergyCost = 25 }
    local skUlt = skillsList[5] or { Id = "CelestialAegis", Name = "Thiên Giới", LevelReq = 20, Cooldown = 45, EnergyCost = 50 }

    local skillSlotApis = {}
    local diamondUltApi = nil

    if not isMobile then
        local abilityDock = PremiumPanel.Create(root, {
            name = "AbilityHotbar",
            variant = "gold",
            anchorPoint = Vector2.new(0.5, 1),
            position = UDim2.new(0.5, combatOffsetX, 1, -10),
            size = UDim2.fromOffset(656, 82),
            transparency = 0.06,
            clipsDescendants = false,
            zIndex = 6,
        })

        local leftWing = UIFactory.Create("Frame", abilityDock, {
            Name = "LeftSkillCards",
            Position = UDim2.fromOffset(12, 8),
            Size = UDim2.fromOffset(258, 66),
            BackgroundTransparency = 1,
            ZIndex = 7,
        })
        UIFactory.ListLayout(leftWing, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

        local rightWing = UIFactory.Create("Frame", abilityDock, {
            Name = "RightSkillCards",
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -12, 0, 8),
            Size = UDim2.fromOffset(258, 66),
            BackgroundTransparency = 1,
            ZIndex = 7,
        })
        UIFactory.ListLayout(rightWing, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)

        local leftCardDefs = {
            {
                slotKey = "Dodge",
                skillId = "Dodge",
                nameText = I18n.Pick("Lướt", "Dash"),
                keybind = "Q",
                palette = "cyan",
                icon = "Wing",
                levelReq = 1,
                maxCooldown = 2.0,
                energyCost = 10,
                onPress = function()
                    HUDController.TriggerAction("Dodge")
                end,
            },
            {
                slotKey = "Skill1",
                skillId = sk1.Id,
                nameText = sk1.Name,
                keybind = "Z",
                palette = "sapphire",
                icon = "Sword",
                levelReq = sk1.LevelReq or 1,
                maxCooldown = sk1.Cooldown or 5,
                energyCost = sk1.EnergyCost or 15,
                onPress = function()
                    local curSlot = tonumber((player and player:GetAttribute("ActiveSlot")) or Store.GetView().activeHotbarSlot) or 1
                    if curSlot == 2 or curSlot == 4 then
                        HUDController.TriggerAction("Z")
                    else
                        HUDController.TriggerAction("Skill1")
                    end
                end,
            },
            {
                slotKey = "Skill2",
                skillId = sk2.Id,
                nameText = sk2.Name,
                keybind = "X",
                palette = "sapphire",
                icon = "Shield",
                levelReq = sk2.LevelReq or 1,
                maxCooldown = sk2.Cooldown or 10,
                energyCost = sk2.EnergyCost or 20,
                onPress = function()
                    local curSlot = tonumber((player and player:GetAttribute("ActiveSlot")) or Store.GetView().activeHotbarSlot) or 1
                    if curSlot == 2 or curSlot == 4 then
                        HUDController.TriggerAction("X")
                    else
                        HUDController.TriggerAction("Skill2")
                    end
                end,
            },
            {
                slotKey = "Skill3",
                skillId = sk3.Id,
                nameText = sk3.Name,
                keybind = "C",
                palette = "gold",
                icon = "Bolt",
                levelReq = sk3.LevelReq or 10,
                maxCooldown = sk3.Cooldown or 12,
                energyCost = sk3.EnergyCost or 25,
                onPress = function()
                    local curSlot = tonumber((player and player:GetAttribute("ActiveSlot")) or Store.GetView().activeHotbarSlot) or 1
                    if curSlot == 2 or curSlot == 4 then
                        HUDController.TriggerAction("C")
                    else
                        HUDController.TriggerAction("Skill3")
                    end
                end,
            },
        }

        for idx, cd in ipairs(leftCardDefs) do
            local _, sApi = SkillButton.Create(leftWing, {
                name = "SkillCard_" .. cd.keybind,
                skillId = cd.skillId,
                nameText = cd.nameText,
                keybind = cd.keybind,
                palette = cd.palette,
                icon = cd.icon,
                size = UDim2.fromOffset(60, 66),
                layoutOrder = idx,
                locked = (snap.player.level or 1) < cd.levelReq,
                lockLabel = "Lv." .. tostring(cd.levelReq),
                maxCooldown = cd.maxCooldown,
                zIndex = 8,
                onActivated = cd.onPress,
            })
            skillSlotApis[cd.slotKey] = {
                Api = sApi,
                SkillId = cd.skillId,
                LevelReq = cd.levelReq,
                MaxCooldown = cd.maxCooldown,
                EnergyCost = cd.energyCost,
            }
        end

        -- Centerpiece 45-Degree Rotated Diamond Ultimate [R] + J & T Shoulder Mini-Orbs
        local _, ultCenterApi = buildDiamondUltimateCenterpiece(abilityDock, {
            locked = (snap.player.level or 1) < (skUlt.LevelReq or 20),
            lockLabel = "Lv." .. tostring(skUlt.LevelReq or 20),
            maxCooldown = skUlt.Cooldown or 45,
            zIndex = 8,
            onActivated = function()
                HUDController.TriggerAction("Ultimate")
            end,
            onHaki = function()
                HUDController.TriggerAction("ToggleAura")
            end,
            onV4 = function()
                HUDController.TriggerAction("ActivateRaceV4")
            end,
        })
        diamondUltApi = ultCenterApi
        skillSlotApis["Ultimate"] = {
            Api = ultCenterApi,
            SkillId = skUlt.Id,
            LevelReq = skUlt.LevelReq or 20,
            MaxCooldown = skUlt.Cooldown or 45,
            EnergyCost = skUlt.EnergyCost or 50,
        }

        local rightCardDefs = {
            {
                slotKey = "FruitV",
                skillId = "FruitAwakenV",
                nameText = I18n.Pick("Thức Tỉnh", "Awaken"),
                keybind = "V",
                keyTag = "[V] TRÁI",
                palette = "mythic",
                icon = "Flame",
                levelReq = 1,
                maxCooldown = 18,
                energyCost = 35,
                onPress = function()
                    HUDController.TriggerAction("V")
                end,
            },
            {
                slotKey = "SkillE",
                skillId = "AetherBurstE",
                nameText = I18n.Pick("Bùng Nổ", "Burst"),
                keybind = "E",
                palette = "gold",
                icon = "Flame",
                levelReq = 1,
                maxCooldown = 8,
                energyCost = 15,
                onPress = function()
                    local vState = Store.GetView()
                    if vState.interactPrompt and vState.interactPrompt.visible then
                        HUDController.TriggerAction("Interact")
                    else
                        HUDController.TriggerAction("C")
                    end
                end,
            },
            {
                slotKey = "FlightF",
                skillId = "SkyFlightF",
                nameText = I18n.Pick("Thiên Vũ", "Flight"),
                keybind = "F",
                palette = "cyan",
                icon = "Wing",
                levelReq = 1,
                maxCooldown = 6,
                energyCost = 12,
                onPress = function()
                    HUDController.TriggerAction("F")
                end,
            },
            {
                slotKey = "FlaskH",
                skillId = "AetherFlaskH",
                nameText = I18n.Pick("Bình EN", "Instinct"),
                keybind = "H",
                keyTag = "[H]",
                palette = "slate",
                icon = "Flask",
                levelReq = 1,
                maxCooldown = 12,
                energyCost = 0,
                onPress = function()
                    HUDController.TriggerAction("ToggleInstinct")
                end,
            },
        }

        for idx, cd in ipairs(rightCardDefs) do
            local _, sApi = SkillButton.Create(rightWing, {
                name = "SkillCard_" .. cd.keybind,
                skillId = cd.skillId,
                nameText = cd.nameText,
                keybind = cd.keybind,
                keyTag = cd.keyTag,
                palette = cd.palette,
                icon = cd.icon,
                size = UDim2.fromOffset(60, 66),
                layoutOrder = idx,
                locked = false,
                maxCooldown = cd.maxCooldown,
                zIndex = 8,
                onActivated = cd.onPress,
            })
            skillSlotApis[cd.slotKey] = {
                Api = sApi,
                SkillId = cd.skillId,
                LevelReq = cd.levelReq,
                MaxCooldown = cd.maxCooldown,
                EnergyCost = cd.energyCost,
            }
        end
    else
        -- Mobile Right-Thumb Combat Arc (#125)
        local touchArc = UIFactory.Create("Frame", root, {
            Name = "MobileTouchArc",
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -14, 1, -14),
            Size = UDim2.fromOffset(236, 224),
            BackgroundTransparency = 1,
            ZIndex = 8,
        })

        local m1Btn = UIFactory.Create("TextButton", touchArc, {
            Name = "PrimaryAttackBtn",
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -4, 1, -4),
            Size = UDim2.fromOffset(82, 82),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 9,
        })
        UIFactory.PillCorner(m1Btn)
        UIFactory.Stroke(m1Btn, colors.ACCENT_GOLD_BRIGHT, 2.2, 0.04)
        UIFactory.Gradient(m1Btn, Color3.fromRGB(252, 212, 98), Color3.fromRGB(186, 114, 20), 90)
        UIFactory.Icon(m1Btn, "Sword", UDim2.new(0.5, -15, 0.5, -18), 30, Color3.fromRGB(16, 20, 32)).ZIndex = 10
        UIFactory.Label(m1Btn, {
            Name = "M1Label",
            Text = I18n.Pick("ĐÁNH", "ATK"),
            Position = UDim2.new(0, 0, 1, -21),
            Size = UDim2.new(1, 0, 0, 16),
            TextSize = 10,
            TextColor = Color3.fromRGB(16, 20, 32),
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            ZIndex = 10,
        })
        m1Btn.Activated:Connect(function()
            HUDController.TriggerAttackInput(nil)
        end)

        local arcNodes = {
            { key = "Skill1", id = sk1.Id, name = sk1.Name, kb = "Z", pal = "sapphire", icon = "Sword", pos = UDim2.new(1, -98, 1, -10), req = sk1.LevelReq or 1, cd = sk1.Cooldown or 5, cost = sk1.EnergyCost or 15, act = "Skill1" },
            { key = "Skill2", id = sk2.Id, name = sk2.Name, kb = "X", pal = "sapphire", icon = "Shield", pos = UDim2.new(1, -88, 1, -80), req = sk2.LevelReq or 1, cd = sk2.Cooldown or 10, cost = sk2.EnergyCost or 20, act = "Skill2" },
            { key = "Skill3", id = sk3.Id, name = sk3.Name, kb = "C", pal = "gold", icon = "Bolt", pos = UDim2.new(1, -20, 1, -102), req = sk3.LevelReq or 10, cd = sk3.Cooldown or 12, cost = sk3.EnergyCost or 25, act = "Skill3" },
            { key = "Ultimate", id = skUlt.Id, name = skUlt.Name, kb = "R", pal = "mythic", icon = "Crown", pos = UDim2.new(1, -82, 1, -148), req = skUlt.LevelReq or 20, cd = skUlt.Cooldown or 45, cost = skUlt.EnergyCost or 50, act = "Ultimate" },
            { key = "Dodge", id = "Dodge", name = I18n.Pick("Lướt", "Dash"), kb = "Q", pal = "cyan", icon = "Wing", pos = UDim2.new(1, -162, 1, -14), req = 1, cd = 2.0, cost = 10, act = "Dodge" },
        }

        for _, an in ipairs(arcNodes) do
            local _, sApi = SkillButton.Create(touchArc, {
                name = "Arc_" .. an.key,
                skillId = an.id,
                nameText = an.name,
                keybind = an.kb,
                palette = an.pal,
                icon = an.icon,
                anchorPoint = Vector2.new(1, 1),
                position = an.pos,
                size = UDim2.fromOffset(54, 56),
                locked = (snap.player.level or 1) < an.req,
                lockLabel = "Lv." .. tostring(an.req),
                maxCooldown = an.cd,
                zIndex = 9,
                onActivated = function()
                    HUDController.TriggerAction(an.act)
                end,
            })
            skillSlotApis[an.key] = {
                Api = sApi,
                SkillId = an.id,
                LevelReq = an.req,
                MaxCooldown = an.cd,
                EnergyCost = an.cost,
            }
        end
    end

    HUD.Refs = {
        Root = root,
        AvatarPortraitApi = avatarPortraitApi,
        LevelLabel = levelLabel,
        PlayerNameLabel = playerNameLabel,
        ClassTitleLabel = classTitleLabel,
        ClassTitleStroke = classTitleStroke,
        HPBarApi = hpBarApi,
        StaminaBarApi = staminaBarApi,
        XPBarApi = xpBarApi,
        HudGoldLabel = hudGoldLabel,
        HudShardLabel = hudShardLabel,
        HudHakiPill = hudHakiPill,
        HudHakiLabel = hudHakiLabel,
        HudHakiStroke = hudHakiStroke,
        BuffPills = buffPills,
        QuestTrackerApi = questTrackerApi,
        MinimapApi = minimapApi,
        FruitRadarPill = fruitRadarPill,
        FruitRadarStroke = fruitRadarStroke,
        FruitRadarLabel = fruitRadarLabel,
        SquadPillBtn = squadPillBtn,
        CompanionTitle = companionTitle,
        BossBarApi = bossBarApi,
        ComboCard = comboCard,
        ComboTimerFill = comboTimerFill,
        AimReticle = aimReticle,
        AimDashSegments = aimDashSegments,
        AimDiamondStroke = aimDiamondStroke,
        AimCoreDot = aimCoreDot,
        AimCoreStroke = aimCoreStroke,
        AimModePill = aimModePill,
        AimModeStroke = aimModeStroke,
        AimModeLabel = aimModeLabel,
        DashCluster = dashCluster,
        DashArcBeads = dashArcBeads,
        DashCountPill = dashCountPill,
        DashCountStroke = dashCountStroke,
        DashCountLabel = dashCountLabel,
        PerfectDodgePill = perfectDodgePill,
        PruneAndCountDashCharges = pruneAndCountDashCharges,
        TriggerDodgeFeedback = triggerDodgeFeedback,
        InteractBtn = interactBtn,
        InteractApi = interactApi,
        LoadoutSlotRefs = loadoutSlotRefs,
        ApplyLoadoutPillVisual = applyLoadoutPillVisual,
        ResolveLoadoutSlotNames = resolveLoadoutSlotNames,
        SkillSlotApis = skillSlotApis,
        DiamondUltApi = diamondUltApi,
    }

    HUD.Update(snap, view)
    return root
end

function HUD.Update(snapshot, viewState)
    local refs = HUD.Refs
    if not refs or not refs.Root or not refs.Root.Parent then
        return
    end
    local colors = Theme.Colors
    local player = Players.LocalPlayer
    local snap = snapshot or Store.GetSnapshot()
    local view = viewState or Store.GetView()

    -- 1. Live 3D Avatar Portrait & Vitals
    if refs.AvatarPortraitApi then
        refs.AvatarPortraitApi:Update(snap)
    elseif refs.LevelLabel then
        refs.LevelLabel.Text = "Lv. " .. tostring(snap.player.level or 1)
    end

    local v4End = tonumber(player and player:GetAttribute("RaceV4ActiveUntil")) or 0
    local v4Rem = math.max(0, v4End - workspace:GetServerTimeNow())
    local titleTxt, titleCol = resolveClassBadgeMeta(snap.player.level, snap.player.classId, v4Rem > 0.4)
    if refs.ClassTitleLabel then
        refs.ClassTitleLabel.Text = titleTxt
        refs.ClassTitleLabel.TextColor3 = titleCol
    end
    if refs.ClassTitleStroke then
        refs.ClassTitleStroke.Color = titleCol
    end

    if refs.HPBarApi and (not player or not player.Character) then
        refs.HPBarApi:Update({
            current = snap.vitals.hp,
            max = snap.vitals.maxHp,
            customText = string.format("HP  %s / %s", UIFactory.FormatNumber(math.ceil(snap.vitals.hp or 100)), UIFactory.FormatNumber(math.ceil(snap.vitals.maxHp or 100))),
        })
    end

    if refs.StaminaBarApi then
        refs.StaminaBarApi:Update({
            current = snap.vitals.stamina,
            max = snap.vitals.maxStamina,
            customText = string.format("AETHER  %d / %d", math.floor(snap.vitals.stamina or 0), math.floor(snap.vitals.maxStamina or 100)),
        })
    end

    if refs.XPBarApi then
        local expCur = tonumber(snap.player.exp) or 0
        local expMax = math.max(1, tonumber(snap.player.expToNext) or 100)
        local expPct = math.clamp(math.floor((expCur / expMax) * 100), 0, 100)
        refs.XPBarApi:Update({
            current = expCur,
            max = expMax,
            customText = string.format("EXP %s / %s (%d%%)", UIFactory.FormatNumber(expCur), UIFactory.FormatNumber(expMax), expPct),
        })
    end

    -- 1B. Always-Visible Currencies, Haki Status Pill & Dynamic Buff Timers
    local curGold = tonumber((snap.currency and snap.currency.gold) or (snap.currencies and snap.currencies.gold)) or 0
    local curShards = tonumber((snap.currency and snap.currency.coreShards) or (snap.currencies and snap.currencies.coreShards)) or 0
    if refs.HudGoldLabel then
        refs.HudGoldLabel.Text = UIFactory.FormatNumber(curGold) .. " Gold"
    end
    if refs.HudShardLabel then
        refs.HudShardLabel.Text = UIFactory.FormatNumber(curShards) .. " Shards"
    end

    local auraOn = (player and player:GetAttribute("AuraActive") == true)
    local kenOn = (player and player:GetAttribute("InstinctActive") == true)
    if refs.HudHakiLabel and refs.HudHakiStroke then
        if auraOn and kenOn then
            refs.HudHakiLabel.Text = "[J] Haki • Vũ Trang + Ken"
            refs.HudHakiLabel.TextColor3 = Color3.fromRGB(255, 198, 210)
            refs.HudHakiStroke.Color = colors.ACCENT_GOLD_BRIGHT
        elseif auraOn then
            refs.HudHakiLabel.Text = "[J] Haki • Vũ Trang"
            refs.HudHakiLabel.TextColor3 = Color3.fromRGB(255, 186, 198)
            refs.HudHakiStroke.Color = colors.HP_RED
        elseif kenOn then
            refs.HudHakiLabel.Text = "[H] Haki • Quan Sát"
            refs.HudHakiLabel.TextColor3 = Color3.fromRGB(154, 232, 255)
            refs.HudHakiStroke.Color = colors.ACCENT_SAPPHIRE
        else
            refs.HudHakiLabel.Text = "[J] Haki • Ken"
            refs.HudHakiLabel.TextColor3 = Color3.fromRGB(244, 248, 255)
            refs.HudHakiStroke.Color = colors.HP_RED
        end
    end

    if refs.DiamondUltApi then
        if refs.DiamondUltApi.JOrbStroke then
            refs.DiamondUltApi.JOrbStroke.Color = auraOn and colors.ACCENT_GOLD_BRIGHT or Color3.fromRGB(255, 180, 196)
            refs.DiamondUltApi.JOrbStroke.Thickness = auraOn and 2.2 or 1.5
        end
        if refs.DiamondUltApi.TOrbStroke then
            refs.DiamondUltApi.TOrbStroke.Color = (v4Rem > 0.4) and colors.ACCENT_GOLD_BRIGHT or Color3.fromRGB(233, 213, 255)
            refs.DiamondUltApi.TOrbStroke.Thickness = (v4Rem > 0.4) and 2.2 or 1.5
        end
    end

    if refs.BuffPills then
        local nowSrv = workspace:GetServerTimeNow()
        local bV4 = refs.BuffPills.RaceV4
        if bV4 then
            bV4.Frame.Visible = v4Rem > 0.5
            if bV4.Frame.Visible then
                bV4.Label.Text = "V4 • " .. formatTimer(v4Rem)
            end
        end

        local dblEnd = tonumber(player and player:GetAttribute("DoubleExpUntil")) or 0
        local dblRem = math.max(0, dblEnd - nowSrv)
        local bExp = refs.BuffPills.DoubleExp
        if bExp then
            bExp.Frame.Visible = dblRem > 0.5
            if bExp.Frame.Visible then
                bExp.Label.Text = "2X EXP • " .. formatTimer(dblRem)
            end
        end

        local shOn = (player and (player:GetAttribute("FruitTransformed") == true or player:GetAttribute("ShieldActive") == true))
        local bSh = refs.BuffPills.ShieldTransform
        if bSh then
            bSh.Frame.Visible = shOn == true
            if bSh.Frame.Visible then
                bSh.Label.Text = I18n.Pick("Hóa Thân Aether", "Aether Form")
            end
        end
    end

    -- 2. Quest Tracker
    if refs.QuestTrackerApi then
        refs.QuestTrackerApi:Update({
            activeQuest = snap.quest,
            collapsed = view.questTrackerCollapsed,
        })
    end

    -- 3. Minimap, Purple Aether Fruit Radar Pill & Gold Squad Pill
    if refs.MinimapApi and refs.MinimapApi.Instance then
        local showMap = not (view.settings and view.settings.showMinimap == false)
        refs.MinimapApi.Instance.Visible = showMap
    end

    local char = player and player.Character
    local rootPart = char and (char.PrimaryPart or char:FindFirstChild("HumanoidRootPart"))
    local playerPos = (rootPart and rootPart:IsA("BasePart")) and rootPart.Position or nil

    if refs.FruitRadarLabel then
        local fruitPos = workspace:GetAttribute("NaturalFruitPos")
        local fruitName = tostring(workspace:GetAttribute("NaturalFruitName") or I18n.Pick("Trái Bão Tố", "Tempest Fruit"))
        if typeof(fruitPos) == "Vector3" and playerPos then
            local distMeters = math.max(1, math.floor((fruitPos - playerPos).Magnitude * 0.35))
            refs.FruitRadarLabel.Text = string.format("%s • %dm", fruitName, distMeters)
            if refs.FruitRadarStroke then
                refs.FruitRadarStroke.Color = Color3.fromRGB(232, 160, 255)
            end
        else
            local eqF = (snap.fruits and snap.fruits.equipped) or (player and player:GetAttribute("EquippedFruit"))
            if type(eqF) == "string" and eqF ~= "" and eqF ~= "None" then
                refs.FruitRadarLabel.Text = string.format("Radar: %s", eqF)
            else
                refs.FruitRadarLabel.Text = I18n.Pick("Radar Aether: Quét Đảo", "Aether Radar: Scanning")
            end
            if refs.FruitRadarStroke then
                refs.FruitRadarStroke.Color = Color3.fromRGB(192, 132, 252)
            end
        end
    end

    if refs.CompanionTitle then
        local pList = Players:GetPlayers()
        local count = math.clamp(#pList, 1, 4)
        if count <= 1 then
            refs.CompanionTitle.Text = I18n.Pick("ĐỘI HÌNH: SOLO (1/4)", "SQUAD: SOLO (1/4)")
        else
            refs.CompanionTitle.Text = I18n.Pick(
                string.format("ĐỘI HÌNH: TỔ ĐỘI (%d/4)", count),
                string.format("SQUAD: PARTY (%d/4)", count)
            )
        end
    end

    -- 4. Proximity & Combat-Gated BossHUD (#6)
    if refs.BossBarApi then
        local showBoss = false
        if playerPos then
            local bossModel, dist = CelestialMinimap.FindClosestLiveBoss(playerPos)
            local inCombat = (type(Store.IsInBossCombat) == "function") and Store.IsInBossCombat() or false
            if bossModel then
                if dist <= 95 or (inCombat and dist <= 145) or (HUD.BossVisibleLatch and dist <= 125) then
                    local bHum = bossModel:FindFirstChildOfClass("Humanoid")
                    if bHum and bHum.Health > 0 then
                        showBoss = true
                        HUD.BossVisibleLatch = true
                        local hpRatio = bHum.Health / math.max(1, bHum.MaxHealth)
                        local phaseNum = (hpRatio <= 0.35 and 3) or (hpRatio <= 0.70 and 2) or 1
                        local breakPct = tonumber(bossModel:GetAttribute("AetherBreakPct"))
                            or math.clamp(math.floor((1 - hpRatio) * 115) % 100, 12, 96)
                        refs.BossBarApi:Update({
                            visible = true,
                            bossName = tostring(bossModel:GetAttribute("DisplayName") or bossModel.Name),
                            bossLevel = tonumber(bossModel:GetAttribute("Level")) or 150,
                            phase = phaseNum,
                            hp = bHum.Health,
                            maxHp = bHum.MaxHealth,
                            breakPct = breakPct,
                        })
                    end
                end
            end
        end
        if not showBoss then
            HUD.BossVisibleLatch = false
            refs.BossBarApi:SetVisible(false)
        end
    end

    -- 4B. Combo Rank Card Decay
    if refs.ComboCard and refs.ComboCard.Visible then
        local elapsed = os.clock() - (HUD.ComboState.LastHitClock or 0)
        if elapsed >= HUD.ComboState.WindowSec then
            HUD.ComboState.Count = 0
            refs.ComboCard.Visible = false
        elseif refs.ComboTimerFill then
            local remRatio = math.clamp(1 - (elapsed / HUD.ComboState.WindowSec), 0, 1)
            refs.ComboTimerFill.Size = UDim2.fromScale(remRatio, 1)
        end
    end

    -- 4C. Center Tactical Ranged Aim Reticle & Lock-On State
    if refs.AimReticle then
        local curSlot = tonumber((player and player:GetAttribute("ActiveSlot")) or view.activeHotbarSlot) or 1
        local isRangedSlot = (curSlot == 4) or (curSlot == 2)
        local isOTS = (player and player:GetAttribute("SkybreakOTSActive") == true)
            or (UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter)
        local lockName = (type(view.lockTarget) == "string" and #view.lockTarget > 0) and view.lockTarget or nil
        local inActiveCombat = (refs.ComboCard and refs.ComboCard.Visible == true) or (HUD.BossVisibleLatch == true)
        local isHighAlert = isRangedSlot or isOTS or (lockName ~= nil) or inActiveCombat

        refs.AimReticle.Visible = not (player and player:GetAttribute("SkybreakPhotoMode") == true)
        local arcTrans = isHighAlert and 0.04 or 0.48
        local diamondTrans = isHighAlert and 0.04 or 0.45
        local arcCol = (lockName ~= nil) and Color3.fromRGB(251, 55, 98)
            or (curSlot == 4 and Color3.fromRGB(251, 55, 98) or Color3.fromRGB(244, 92, 124))

        for _, seg in ipairs(refs.AimDashSegments or {}) do
            seg.BackgroundTransparency = arcTrans
            seg.BackgroundColor3 = arcCol
        end
        if refs.AimDiamondStroke then
            refs.AimDiamondStroke.Transparency = diamondTrans
        end
        if refs.AimCoreDot then
            refs.AimCoreDot.BackgroundTransparency = isHighAlert and 0.0 or 0.35
        end
        if refs.AimCoreStroke then
            refs.AimCoreStroke.Transparency = isHighAlert and 0.10 or 0.50
        end
        if refs.AimModePill and refs.AimModeLabel then
            if lockName then
                refs.AimModePill.Visible = true
                refs.AimModeStroke.Color = Color3.fromRGB(251, 55, 98)
                refs.AimModeLabel.Text = "LOCK • " .. string.upper(lockName)
            elseif curSlot == 4 then
                refs.AimModePill.Visible = true
                refs.AimModeStroke.Color = Color3.fromRGB(253, 224, 71)
                refs.AimModeLabel.Text = I18n.Pick("AIM • TẦM XA", "RANGED AIM")
            else
                refs.AimModePill.Visible = false
            end
        end
    end

    -- 4D. Curved 3-Segment Cyan Dash/Dodge Arc ("LƯỚT X/3") & Perfect Dodge Callout Decay
    if refs.DashCluster and refs.PruneAndCountDashCharges then
        local now = os.clock()
        local availCharges = refs.PruneAndCountDashCharges(now)
        local maxCharges = HUD.DashState.MaxCharges
        local recentlyUsed = (now - (HUD.DashState.LastConsumeClock or 0)) < 3.6
        local inCombatOrUsed = recentlyUsed or (availCharges < maxCharges) or (refs.ComboCard and refs.ComboCard.Visible == true)

        if refs.DashCountLabel then
            refs.DashCountLabel.Text = string.format("%s %d/%d", I18n.Pick("LƯỚT", "DASH"), availCharges, maxCharges)
        end
        if refs.DashCountStroke then
            refs.DashCountStroke.Transparency = inCombatOrUsed and 0.06 or 0.32
        end
        if refs.DashCountPill then
            refs.DashCountPill.BackgroundTransparency = inCombatOrUsed and 0.05 or 0.24
        end

        -- Top-to-Bottom fill matching Screenshot 2 (2/3 = top 2 cyan segments lit, bottom 3rd segment dark obsidian)
        local activeCyan = Color3.fromRGB(56, 224, 255)
        local emptyDark = Color3.fromRGB(16, 24, 40)
        for segIdx = 1, 3 do
            local isFilled = (segIdx <= availCharges)
            local segColor = isFilled and activeCyan or emptyDark
            local segTrans = isFilled and (inCombatOrUsed and 0.02 or 0.24) or (inCombatOrUsed and 0.14 or 0.42)
            for _, bead in ipairs(refs.DashArcBeads[segIdx] or {}) do
                bead.BackgroundColor3 = segColor
                bead.BackgroundTransparency = segTrans
            end
        end

        if refs.PerfectDodgePill then
            refs.PerfectDodgePill.Visible = (now < (HUD.DashState.CalloutUntil or 0))
        end
    end

    -- 5. Contextual [E] Interact Prompt
    if refs.InteractBtn and refs.InteractApi then
        local prompt = view.interactPrompt
        local vis = (prompt and prompt.visible) == true
        refs.InteractBtn.Visible = vis
        if vis then
            refs.InteractApi:SetText("[E]  •  " .. tostring(prompt.label or I18n.Pick("TƯƠNG TÁC", "INTERACT")))
        end
    end

    -- 7. Loadout Hotbar [1]-[4] Active Champagne Gold Pill Update
    if refs.LoadoutSlotRefs and refs.ApplyLoadoutPillVisual and refs.ResolveLoadoutSlotNames then
        local curActive = tonumber((player and player:GetAttribute("ActiveSlot")) or view.activeHotbarSlot) or 1
        local names = refs.ResolveLoadoutSlotNames(snap)
        for idx = 1, 4 do
            local r = refs.LoadoutSlotRefs[idx]
            if r then
                refs.ApplyLoadoutPillVisual(r, idx == curActive, names[idx])
            end
        end
    end

    -- 8. Skill Cards & Diamond Ultimate Cooldowns / Level Locks / Energy Sufficiency
    if refs.SkillSlotApis then
        local pLv = tonumber(snap.player.level) or 1
        local curEnergy = tonumber(snap.vitals.stamina) or 100
        local cds = snap.cooldowns or {}
        local elapsedSync = math.max(0, os.clock() - (Store.LastServerSyncClock or os.clock()))

        for _, entry in pairs(refs.SkillSlotApis) do
            local rawCd = tonumber(cds[entry.SkillId]) or 0
            local remCd = math.max(0, rawCd - elapsedSync)
            entry.Api:Update({
                locked = pLv < (entry.LevelReq or 1),
                lockLabel = "Lv." .. tostring(entry.LevelReq or 1),
                cooldown = remCd,
                maxCooldown = entry.MaxCooldown,
                outOfEnergy = (entry.EnergyCost or 0) > curEnergy,
            })
        end
    end
end

function HUD.Cleanup()
    for _, conn in ipairs(HUD.Connections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(HUD.Connections)

    if HUD.Refs then
        if HUD.Refs.AvatarPortraitApi and type(HUD.Refs.AvatarPortraitApi.Destroy) == "function" then
            pcall(function()
                HUD.Refs.AvatarPortraitApi:Destroy()
            end)
        end
        if HUD.Refs.MinimapApi and type(HUD.Refs.MinimapApi.Destroy) == "function" then
            pcall(function()
                HUD.Refs.MinimapApi:Destroy()
            end)
        end
    end

    HUDController.Cleanup()
    HUD.Refs = {}
end

return HUD
