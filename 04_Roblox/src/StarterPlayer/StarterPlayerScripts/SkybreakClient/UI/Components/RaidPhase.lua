-- SKYBREAK: Fragments of the Core — Boss & Raid Phase Indicator Component
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Components/RaidPhase.lua
-- Supports Aureon (3 phases + Pylon shield), Noxar (3 combat phases + Purification), and Veyr (4 phases + 4 Anchors).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local StatBar = require(script.Parent:WaitForChild("StatBar"))

local RaidPhase = {}

function RaidPhase.Create(parent, props)
    props = props or {}
    local colors = Theme.Colors

    local container = UIFactory.Create("Frame", parent, {
        Name = props.name or "BossHUD",
        AnchorPoint = props.anchorPoint or Vector2.new(0.5, 0),
        Position = props.position or UDim2.new(0.5, 0, 0, 16),
        Size = props.size or UDim2.fromOffset(580, 112),
        BackgroundColor3 = colors.BG_800,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Visible = props.visible ~= false,
        ZIndex = props.zIndex or 8,
    })

    UIFactory.Corner(container, Theme.Radius.Large)
    local stroke = UIFactory.Stroke(container, colors.HP_RED, 1.6, 0.16)
    UIFactory.Gradient(container, colors.BG_700, colors.BG_900, 90)

    local nameLabel = UIFactory.Label(container, {
        Name = "Name",
        Text = props.bossName or "AUREON SENTINEL",
        Position = UDim2.fromOffset(16, 8),
        Size = UDim2.new(0.62, -16, 0, 22),
        TextSize = 18,
        TextColor = colors.TEXT_PRIMARY,
        Bold = true,
        ZIndex = container.ZIndex + 2,
    })

    local phaseLabel = UIFactory.Label(container, {
        Name = "BossPhase",
        Text = "PHASE 1 / 3  •  SOLAR VIGIL",
        Position = UDim2.new(0.62, 0, 0, 8),
        Size = UDim2.new(0.38, -16, 0, 22),
        TextSize = 13,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
        XAlign = Enum.TextXAlignment.Right,
        ZIndex = container.ZIndex + 2,
    })

    local _, hpBarApi = StatBar.Create(container, {
        name = "HP",
        type = "BossHP",
        current = props.bossHp or 2200,
        max = props.bossMaxHp or 2200,
        position = UDim2.fromOffset(16, 36),
        size = UDim2.new(1, -32, 0, 26),
        zIndex = container.ZIndex + 2,
    })

    local _, breakBarApi = StatBar.Create(container, {
        name = "Break",
        type = "Break",
        current = props.breakGauge or 0,
        max = 100,
        customText = "BREAK GAUGE",
        position = UDim2.fromOffset(16, 68),
        size = UDim2.new(0.66, -16, 0, 16),
        textSize = 10,
        zIndex = container.ZIndex + 2,
    })

    local pipsHolder = UIFactory.Create("Frame", container, {
        Name = "PhasePips",
        Position = UDim2.new(0.68, 4, 0, 68),
        Size = UDim2.new(0.32, -20, 0, 16),
        BackgroundTransparency = 1,
        ZIndex = container.ZIndex + 2,
    })
    UIFactory.ListLayout(pipsHolder, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)

    local pips = {}
    for i = 1, 4 do
        local pip = UIFactory.Create("Frame", pipsHolder, {
            Name = "PhasePip_" .. i,
            Size = UDim2.fromOffset(26, 12),
            BackgroundColor3 = i == 1 and colors.ACCENT_GOLD or colors.BG_900,
            BorderSizePixel = 0,
            LayoutOrder = i,
            ZIndex = container.ZIndex + 3,
        })
        UIFactory.Corner(pip, 4)
        UIFactory.Stroke(pip, colors.ACCENT_GOLD, 1, 0.25)
        pips[i] = pip
    end

    local warningBanner = UIFactory.Create("Frame", container, {
        Name = "BossWarning",
        Position = UDim2.fromOffset(16, 88),
        Size = UDim2.new(1, -32, 0, 20),
        BackgroundColor3 = colors.HP_RED:Lerp(colors.BG_900, 0.65),
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = container.ZIndex + 3,
    })
    UIFactory.Corner(warningBanner, 4)
    local warningText = UIFactory.Label(warningBanner, {
        Name = "Text",
        Text = "ENERGY SHIELD ACTIVE — DESTROY BOTH ENERGY PYLONS!",
        Size = UDim2.fromScale(1, 1),
        TextSize = 12,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        ZIndex = container.ZIndex + 4,
    })

    local api = {
        Instance = container,
        NameLabel = nameLabel,
        PhaseLabel = phaseLabel,
        HPBar = hpBarApi,
        BreakBar = breakBarApi,
        WarningBanner = warningBanner,
        WarningText = warningText,
    }

    function api:Update(state)
        state = state or {}
        if state.active ~= nil then
            container.Visible = state.active == true
        end
        if not container.Visible then
            return
        end

        local phase = tonumber(state.phase) or 1
        local maxPhases = tonumber(state.maxPhases) or 3
        nameLabel.Text = state.bossName or "AUREON SENTINEL"

        local statusNote = state.phaseTitle or "COMBAT"
        if state.purificationReady then
            statusNote = "FINAL PURIFICATION RITUAL!"
            stroke.Color = colors.VOID_PURPLE
        elseif state.stunned then
            statusNote = "POSTURE BROKEN — STRIKE NOW!"
            stroke.Color = colors.SUCCESS
        elseif state.shield then
            statusNote = "AEGIS SHIELD ACTIVE"
            stroke.Color = colors.ACCENT_GOLD
        else
            stroke.Color = colors.HP_RED
        end

        phaseLabel.Text = string.format("PHASE %d / %d  •  %s", phase, maxPhases, statusNote)

        hpBarApi:Update({
            current = state.bossHp or state.HP or 0,
            max = state.bossMaxHp or state.MaxHP or 2200,
        })
        breakBarApi:Update({
            current = state.breakGauge or state.Break or 0,
            max = 100,
            customText = string.format("BREAK %d%%", math.floor(state.breakGauge or state.Break or 0)),
        })

        for i = 1, 4 do
            local pip = pips[i]
            pip.Visible = i <= maxPhases
            pip.BackgroundColor3 = i <= phase and colors.ACCENT_GOLD or colors.BG_900
        end

        warningBanner.Visible = (state.shield == true) or (state.purificationReady == true) or (state.warningText ~= nil)
        if state.purificationReady then
            warningText.Text = "NOXAR POSTURE COLLAPSED — CHANNEL CORE PURIFICATION!"
        elseif state.shield then
            warningText.Text = "PHÁ HAI TRỤ NĂNG LƯỢNG ĐỂ PHÁ KHIÊN BOSS!"
        elseif state.warningText then
            warningText.Text = state.warningText
        end
    end

    function api:Destroy()
        hpBarApi:Destroy()
        breakBarApi:Destroy()
        if container and container.Parent then
            container:Destroy()
        end
    end

    return container, api
end

RaidPhase.create = RaidPhase.Create

return RaidPhase
