-- SKYBREAK: Fragments of the Core — Boss & Raid Phase Indicator with Golden Crown Ribbon Banner
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Components/RaidPhase.lua
-- Matches SKYBREAK_Figma_v2_01_ActionRPG_HUD.png 1:1 (#6 Proximity/Combat-Gated Boss HP Bar).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local I18n = require(script.Parent.Parent:WaitForChild("I18n"))
local Animations = require(script.Parent.Parent:WaitForChild("Animations"))

local RaidPhase = {}

local ROMAN_PHASES = { "I", "II", "III", "IV" }

function RaidPhase.Create(parent, props)
    props = props or {}
    local colors = Theme.Colors
    local baseZ = props.zIndex or 8
    local barWidth = (props.size and props.size.X.Offset > 0 and props.size.X.Offset) or 528

    -- Gold-Corner-Bracketed Obsidian Boss Frame (ClipsDescendants = false so Crown Ribbon overlaps top center!)
    local container = UIFactory.Create("Frame", parent, {
        Name = props.name or "BossHUD",
        AnchorPoint = props.anchorPoint or Vector2.new(0.5, 0),
        Position = props.position or UDim2.new(0.5, 0, 0, 22),
        Size = UDim2.fromOffset(barWidth, 74),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.06,
        BorderSizePixel = 0,
        ClipsDescendants = false,
        Visible = props.visible == true,
        ZIndex = baseZ,
    })
    UIFactory.Corner(container, 12)
    local stroke = UIFactory.Stroke(container, colors.ACCENT_GOLD, 1.6, 0.12)
    UIFactory.Gradient(container, Color3.fromRGB(20, 32, 56), Color3.fromRGB(9, 14, 28), 90)

    -- 4 Crisp Gold Corner Brackets matching Figma Boss Frame
    for idx, c in ipairs({
        { ax = 0, ay = 0, px = 4, py = 4 },
        { ax = 1, ay = 0, px = -4, py = 4 },
        { ax = 0, ay = 1, px = 4, py = -4 },
        { ax = 1, ay = 1, px = -4, py = -4 },
    }) do
        UIFactory.Create("Frame", container, {
            Name = "BossCornerH_" .. idx,
            AnchorPoint = Vector2.new(c.ax, c.ay),
            Position = UDim2.new(c.ax, c.px, c.ay, c.py),
            Size = UDim2.fromOffset(12, 2),
            BackgroundColor3 = colors.ACCENT_GOLD_BRIGHT,
            BackgroundTransparency = 0.14,
            BorderSizePixel = 0,
            ZIndex = baseZ + 2,
        })
        UIFactory.Create("Frame", container, {
            Name = "BossCornerV_" .. idx,
            AnchorPoint = Vector2.new(c.ax, c.ay),
            Position = UDim2.new(c.ax, c.px, c.ay, c.py),
            Size = UDim2.fromOffset(2, 12),
            BackgroundColor3 = colors.ACCENT_GOLD_BRIGHT,
            BackgroundTransparency = 0.14,
            BorderSizePixel = 0,
            ZIndex = baseZ + 2,
        })
    end

    -- Top Golden Crown Ribbon Banner overlapping top center ("AUREON SENTINEL • LV. 150 | PHASE II")
    local _, ribbonRefs = UIFactory.RibbonBanner(container, {
        name = "BossCrownRibbon",
        variant = "gold",
        icon = "Crown",
        iconSize = 15,
        title = (props.bossName or "AUREON SENTINEL") .. " • LV. 150",
        textSize = 11,
        badgeText = "PHASE I",
        badgeWidth = 64,
        anchorPoint = Vector2.new(0.5, 0.5),
        position = UDim2.new(0.5, 0, 0, 0),
        size = UDim2.fromOffset(math.min(346, barWidth - 64), 27),
        zIndex = baseZ + 6,
    })

    -- Row 1: Vivid Crimson-Orange Segmented Boss HP Bar
    local hpTrack = UIFactory.Create("Frame", container, {
        Name = "HP",
        Position = UDim2.fromOffset(16, 20),
        Size = UDim2.new(1, -32, 0, 23),
        BackgroundColor3 = Color3.fromRGB(9, 13, 24),
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        ZIndex = baseZ + 2,
    })
    UIFactory.PillCorner(hpTrack)
    UIFactory.Stroke(hpTrack, Color3.fromRGB(118, 52, 74), 1.2, 0.25)

    local hpInner = UIFactory.Create("Frame", hpTrack, {
        Name = "Track",
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.new(1, -4, 1, -4),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = baseZ + 2,
    })
    UIFactory.PillCorner(hpInner)

    local hpTrail = UIFactory.Create("Frame", hpInner, {
        Name = "TrailFill",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(255, 214, 128),
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        ZIndex = baseZ + 2,
    })
    UIFactory.PillCorner(hpTrail)

    local hpFill = UIFactory.Create("Frame", hpInner, {
        Name = "Fill",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = baseZ + 3,
    })
    UIFactory.PillCorner(hpFill)
    -- Signature Figma Crimson -> Solar Orange Horizontal Gradient
    UIFactory.Gradient(hpFill, Color3.fromRGB(251, 55, 98), Color3.fromRGB(249, 132, 34), 0)

    local hpGloss = UIFactory.Create("Frame", hpFill, {
        Name = "TopGloss",
        Size = UDim2.new(1, 0, 0.42, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.78,
        BorderSizePixel = 0,
        ZIndex = baseZ + 3,
    })
    UIFactory.PillCorner(hpGloss)

    for _, pct in ipairs({ 0.25, 0.50, 0.75 }) do
        UIFactory.Create("Frame", hpInner, {
            Name = "SegTick_" .. tostring(math.floor(pct * 100)),
            Position = UDim2.fromScale(pct, 0),
            Size = UDim2.new(0, 1, 1, 0),
            BackgroundColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 0.50,
            BorderSizePixel = 0,
            ZIndex = baseZ + 4,
        })
    end

    local roleLabel = UIFactory.Label(hpTrack, {
        Name = "BossRoleText",
        Text = I18n.Pick("THÁNH VỆ BẦU TRỜI", "CELESTIAL GUARDIAN"),
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(0.46, -12, 1, 0),
        TextSize = 11,
        TextColor = Color3.fromRGB(252, 250, 255),
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = baseZ + 5,
    })

    local hpValueLabel = UIFactory.Label(hpTrack, {
        Name = "HPValueText",
        Text = "180,000 / 180,000 (100%)",
        Position = UDim2.new(0.46, 0, 0, 0),
        Size = UDim2.new(0.54, -12, 1, 0),
        TextSize = 11,
        TextColor = Color3.fromRGB(255, 252, 255),
        Bold = true,
        XAlign = Enum.TextXAlignment.Right,
        Wrapped = false,
        ZIndex = baseZ + 5,
    })

    -- Row 2: Cyan-Sapphire Aether Break Gauge Bar
    local breakTrack = UIFactory.Create("Frame", container, {
        Name = "Break",
        Position = UDim2.fromOffset(16, 48),
        Size = UDim2.new(1, -32, 0, 15),
        BackgroundColor3 = Color3.fromRGB(8, 13, 25),
        BackgroundTransparency = 0.06,
        BorderSizePixel = 0,
        ZIndex = baseZ + 2,
    })
    UIFactory.PillCorner(breakTrack)
    UIFactory.Stroke(breakTrack, Color3.fromRGB(54, 108, 172), 1, 0.35)

    local breakFill = UIFactory.Create("Frame", breakTrack, {
        Name = "Fill",
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.new(0.45, -4, 1, -4),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = baseZ + 3,
    })
    UIFactory.PillCorner(breakFill)
    UIFactory.Gradient(breakFill, Color3.fromRGB(42, 158, 255), Color3.fromRGB(92, 232, 255), 0)

    local breakLabel = UIFactory.Label(breakTrack, {
        Name = "BreakValueText",
        Text = I18n.Pick("THANH PHÁ GIÁP AETHER • 0%", "AETHER BREAK GAUGE • 0%"),
        Size = UDim2.fromScale(1, 1),
        TextSize = 9,
        TextColor = Color3.fromRGB(240, 250, 255),
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Wrapped = false,
        ZIndex = baseZ + 4,
    })

    -- Floating Warning Banner directly underneath when Shield or Core Purification triggers
    local warningBanner = UIFactory.Create("Frame", container, {
        Name = "BossWarning",
        Position = UDim2.new(0, 16, 1, 4),
        Size = UDim2.new(1, -32, 0, 20),
        BackgroundColor3 = Color3.fromRGB(44, 14, 26),
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = baseZ + 4,
    })
    UIFactory.Corner(warningBanner, 5)
    UIFactory.Stroke(warningBanner, colors.ACCENT_GOLD_BRIGHT, 1.1, 0.22)

    local warningText = UIFactory.Label(warningBanner, {
        Name = "Text",
        Text = "",
        Size = UDim2.fromScale(1, 1),
        TextSize = 10,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Wrapped = false,
        ZIndex = baseZ + 5,
    })

    local hpBarProxy = {
        Instance = hpTrack,
        Update = function(_, s)
            local cur = math.max(0, tonumber(s.current) or 0)
            local mx = math.max(1, tonumber(s.max) or 1)
            local r = math.clamp(cur / mx, 0, 1)
            Animations.TweenBar(hpFill, r, Theme.Motion.HP, "HUD")
            Animations.TweenBar(hpTrail, r, Theme.Motion.HP * 1.65, "HUD")
            hpValueLabel.Text = string.format(
                "%s / %s (%d%%)",
                UIFactory.FormatNumber(math.ceil(cur)),
                UIFactory.FormatNumber(math.ceil(mx)),
                math.floor(r * 100 + 0.5)
            )
        end,
        Destroy = function() end,
    }

    local breakBarProxy = {
        Instance = breakTrack,
        Update = function(_, s)
            local cur = math.clamp(tonumber(s.current) or 0, 0, 100)
            local r = cur / 100
            breakFill.Size = UDim2.new(r, r > 0.02 and -4 or 0, 1, -4)
            breakLabel.Text = s.customText or string.format(
                "%s • %d%%",
                I18n.Pick("THANH PHÁ GIÁP AETHER", "AETHER BREAK GAUGE"),
                math.floor(cur + 0.5)
            )
        end,
        Destroy = function() end,
    }

    local api = {
        Instance = container,
        NameLabel = ribbonRefs.TitleLabel,
        PhaseLabel = roleLabel,
        HPBar = hpBarProxy,
        BreakBar = breakBarProxy,
        WarningBanner = warningBanner,
        WarningText = warningText,
    }

    function api:SetVisible(vis)
        if container then
            container.Visible = (vis == true)
        end
    end

    function api:Update(state)
        state = state or {}
        if state.active ~= nil then
            container.Visible = state.active == true
        elseif state.visible ~= nil then
            container.Visible = state.visible == true
        end
        if not container.Visible then
            return
        end

        local phase = math.clamp(tonumber(state.phase) or 1, 1, 4)
        local roman = ROMAN_PHASES[phase] or tostring(phase)
        local rawBossName = tostring(state.bossName or "AUREON SENTINEL")
        local bossLv = tonumber(state.bossLevel or state.level) or 150
        local ribbonTitle = rawBossName
        if not string.find(string.upper(rawBossName), "LV") then
            ribbonTitle = string.format("%s • LV. %d", rawBossName, bossLv)
        end
        ribbonRefs.SetTitle(ribbonTitle)
        ribbonRefs.SetBadge("PHASE " .. roman)

        local statusNote = state.phaseTitle or I18n.Pick("THÁNH VỆ BẦU TRỜI", "CELESTIAL GUARDIAN")
        if state.purificationReady then
            statusNote = I18n.Pick("THANH TẨY LÕI!", "CORE PURIFICATION!")
            stroke.Color = colors.VOID_PURPLE
        elseif state.stunned then
            statusNote = I18n.Pick("PHÁ GIÁP - TẤN CÔNG!", "POSTURE BROKEN!")
            stroke.Color = colors.SUCCESS
        elseif state.shield then
            statusNote = I18n.Pick("KHIÊN NĂNG LƯỢNG", "AEGIS SHIELD")
            stroke.Color = colors.ACCENT_GOLD_BRIGHT
        else
            stroke.Color = colors.ACCENT_GOLD
        end

        local distTag = ""
        if tonumber(state.distanceStuds) and tonumber(state.distanceStuds) < 999 then
            distTag = string.format(" • %dm", math.floor(tonumber(state.distanceStuds)))
        end
        roleLabel.Text = statusNote .. distTag

        hpBarProxy:Update({
            current = state.bossHp or state.HP or state.hp or 0,
            max = state.bossMaxHp or state.MaxHP or state.maxHp or 2200,
        })
        local brk = tonumber(state.breakGauge or state.Break or state.breakPct) or 0
        breakBarProxy:Update({
            current = brk,
            max = 100,
            customText = string.format(
                "%s • %d%%",
                I18n.Pick("THANH PHÁ GIÁP AETHER", "AETHER BREAK GAUGE"),
                math.floor(brk + 0.5)
            ),
        })

        warningBanner.Visible = (state.shield == true) or (state.purificationReady == true) or (state.warningText ~= nil)
        if state.purificationReady then
            warningText.Text = I18n.Pick("NOXAR SUY YẾU - KÍCH HOẠT THANH TẨY LÕI!", "NOXAR POSTURE COLLAPSED - CHANNEL CORE PURIFICATION!")
        elseif state.shield then
            warningText.Text = I18n.Pick("PHÁ HAI TRỤ NĂNG LƯỢNG ĐỂ PHÁ KHIÊN BOSS!", "DESTROY BOTH ENERGY PYLONS TO BREAK BOSS SHIELD!")
        elseif state.warningText then
            warningText.Text = state.warningText
        end
    end

    function api:Destroy()
        if container and container.Parent then
            container:Destroy()
        end
    end

    return container, api
end

RaidPhase.create = RaidPhase.Create

return RaidPhase
