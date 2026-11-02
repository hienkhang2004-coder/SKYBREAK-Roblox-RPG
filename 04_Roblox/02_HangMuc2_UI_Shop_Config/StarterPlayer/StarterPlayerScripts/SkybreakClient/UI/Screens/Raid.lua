-- SKYBREAK: Fragments of the Core — Co-Op Boss & Raid Encounter Command Screen ([P])
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/Raid.lua
-- Covers Tasks #6, #8, #10, #94

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local WorldConfig = require(Shared:WaitForChild("Config"):WaitForChild("WorldConfig"))
local UIState = require(Shared:WaitForChild("Types"):WaitForChild("UIState"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Store = require(script.Parent.Parent:WaitForChild("Store"))
local ScreenRouter = require(script.Parent.Parent:WaitForChild("ScreenRouter"))
local I18n = require(script.Parent.Parent:WaitForChild("I18n"))
local PremiumPanel = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumPanel"))
local PremiumButton = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumButton"))
local RaidPhase = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("RaidPhase"))
local PartyController = require(script.Parent.Parent:WaitForChild("Controllers"):WaitForChild("PartyController"))

local Raid = {
    Refs = {},
}

function Raid.Build(parent)
    Raid.Cleanup()
    local colors = Theme.Colors
    local snap = Store.GetSnapshot()
    local view = Store.GetView()
    local selectedRaidId = view.selectedRaidId or "Veyr"
    local raidCfg = WorldConfig.Raids[selectedRaidId] or WorldConfig.Raids.Veyr

    local root = UIFactory.Create("Frame", parent, {
        Name = "RaidScreen",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 2,
    })

    -- #10: Shared Top Header Bar with complete NavTabs
    local _, headerRefs = UIFactory.BuildScreenHeader(root, {
        ActiveScreen = UIState.Screens.Raid,
        Title = I18n.T("raid.title"),
        Snapshot = snap,
        OnNavigate = function(targetId)
            ScreenRouter.Navigate(targetId)
        end,
        OnClose = function()
            ScreenRouter.CloseAllToHUD()
        end,
    })

    -- Raid Selector Row (Aureon Sentinel / Noxar / Veyr)
    local selectorRow = UIFactory.Create("Frame", root, {
        Name = "RaidSelectorRow",
        Position = UDim2.fromOffset(16, 74),
        Size = UDim2.new(1, -32, 0, 44),
        BackgroundTransparency = 1,
    })
    UIFactory.GridLayout(selectorRow, UDim2.new(0.333, -7, 0, 42), UDim2.fromOffset(10, 6))

    for idx, rid in ipairs(WorldConfig.OrderedRaids) do
        local rCfg = WorldConfig.Raids[rid]
        local isSel = (rid == selectedRaidId)
        PremiumButton.Create(selectorRow, {
            name = "SelectRaid_" .. rid,
            icon = "Raid",
            label = string.format(
                "%s  (Lv.%d • %d Phases%s)",
                rCfg.Name,
                rCfg.LevelReq,
                rCfg.MaxPhases,
                rCfg.HasPurification and " + Purify" or ""
            ),
            variant = isSel and "gold" or "secondary",
            selected = isSel,
            textSize = 12,
            minTextSize = 10,
            layoutOrder = idx,
            onActivated = function()
                Store.SetView({ selectedRaidId = rid })
                ScreenRouter.Navigate(UIState.Screens.Raid, { forceRebuild = true, replace = true })
            end,
        })
    end

    -- Live RaidPhase Component Preview Banner (explicitly active inside Raid Command screen)
    local _, raidPreviewApi = RaidPhase.Create(root, {
        name = "RaidHeaderPreview",
        anchorPoint = Vector2.new(0, 0),
        position = UDim2.fromOffset(16, 126),
        size = UDim2.new(1, -32, 0, 110),
        bossName = raidCfg.Name .. "  •  " .. string.upper(raidCfg.Title),
        bossHp = raidCfg.MaxHP,
        bossMaxHp = raidCfg.MaxHP,
        visible = true,
    })
    raidPreviewApi:Update({
        active = true,
        bossName = raidCfg.Name .. "  •  " .. string.upper(raidCfg.Title),
        phase = 1,
        maxPhases = raidCfg.MaxPhases,
        phaseTitle = raidCfg.Phases[1] and raidCfg.Phases[1].Name or "PHASE 1",
        bossHp = raidCfg.MaxHP,
        bossMaxHp = raidCfg.MaxHP,
        breakGauge = 35,
        warningText = raidCfg.HasPurification
            and I18n.Pick("3 GIAI ĐOẠN CHIẾN ĐẤU + NGHI THỨC THANH TẨY LÕI CUỐI CÙNG", "3 COMBAT PHASES + FINAL CORE PURIFICATION RITUAL")
            or I18n.Pick("THANH MÁU BOSS TRÊN HUD CHỈ HIỆN KHI Ở GẦN <= 95M HOẶC ĐANG GIAO CHIẾN (#6)", "HUD BOSS BAR AUTO-GATES TO <= 95 STUDS OR ACTIVE RAID COMBAT"),
    })

    -- Left Column (54%): Phase Breakdown & Mechanics
    local phasesPanel = PremiumPanel.Create(root, {
        name = "PhasesBreakdown",
        title = I18n.Pick("CƠ CHẾ GIAI ĐOẠN & CẢNH BÁO ĐÒN BOSS", "PHASE MECHANICS & TELEGRAPHS"),
        subtitle = raidCfg.HasPurification
            and I18n.Pick("3 Giai đoạn chiến đấu + Thanh tẩy Lõi Hư Không", "3 Combat Phases followed by Core Purification Finisher")
            or (tostring(raidCfg.MaxPhases) .. " " .. I18n.Pick("Giai đoạn tiến hóa sức mạnh", "Escalating Ascension Phases")),
        position = UDim2.fromOffset(16, 246),
        size = UDim2.new(0.54, -12, 1, -260),
    })

    local phaseList = UIFactory.Create("ScrollingFrame", phasesPanel, {
        Name = "PhaseCards",
        Position = UDim2.fromOffset(14, 62),
        Size = UDim2.new(1, -28, 1, -124),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = colors.ACCENT_GOLD,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.fromOffset(0, 0),
    })
    UIFactory.ListLayout(phaseList, Enum.FillDirection.Vertical, 7, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top)

    for idx, pInfo in ipairs(raidCfg.Phases) do
        local pCard = UIFactory.Create("Frame", phaseList, {
            Name = "Phase_" .. idx,
            Size = UDim2.new(1, -4, 0, 64),
            BackgroundColor3 = colors.BG_900,
            BorderSizePixel = 0,
            LayoutOrder = idx,
        })
        UIFactory.Corner(pCard, Theme.Radius.Small)
        UIFactory.Stroke(pCard, pInfo.Threshold == "FINISHER" and colors.VOID_PURPLE or colors.STROKE_STEEL, 1.2, 0.3)

        UIFactory.Label(pCard, {
            Name = "Title",
            Text = string.format("PHASE %d: %s  (%s)", pInfo.Phase, pInfo.Name, pInfo.Threshold),
            Position = UDim2.fromOffset(12, 6),
            Size = UDim2.new(1, -134, 0, 18),
            TextSize = 12,
            TextColor = pInfo.Threshold == "FINISHER" and colors.VOID_PURPLE or colors.ACCENT_GOLD,
            Bold = true,
            Truncate = Enum.TextTruncate.AtEnd,
        })

        UIFactory.Label(pCard, {
            Name = "Mechanic",
            Text = pInfo.Mechanic,
            Position = UDim2.fromOffset(12, 26),
            Size = UDim2.new(1, -134, 0, 32),
            TextSize = 11,
            TextColor = colors.TEXT_SECONDARY,
            YAlign = Enum.TextYAlignment.Top,
        })

        PremiumButton.Create(pCard, {
            name = "SimPhase_" .. idx,
            label = I18n.Pick("XEM P" .. idx, "PREVIEW P" .. idx),
            variant = "secondary",
            position = UDim2.new(1, -114, 0.5, -16),
            size = UDim2.fromOffset(102, 32),
            textSize = 11,
            minTextSize = 9,
            onActivated = function()
                raidPreviewApi:Update({
                    active = true,
                    bossName = raidCfg.Name,
                    phase = math.min(idx, raidCfg.MaxPhases),
                    maxPhases = raidCfg.MaxPhases,
                    phaseTitle = pInfo.Name,
                    bossHp = math.floor(raidCfg.MaxHP * math.max(0.08, 1 - (idx - 1) * 0.28)),
                    bossMaxHp = raidCfg.MaxHP,
                    breakGauge = idx * 24,
                    purificationReady = (pInfo.Threshold == "FINISHER"),
                    shield = (selectedRaidId == "AureonSentinel" and idx == 2),
                })
            end,
        })
    end

    -- #6: Explicit Raid Simulation Preview Toggle (otherwise Boss HP bar stays proximity/combat gated!)
    local simOn = Store.Session.raidSimulationActive == true
    PremiumButton.Create(phasesPanel, {
        name = "ShowCombatHUDButton",
        label = simOn
            and I18n.Pick("TẮT MÔ PHỎNG THANH BOSS TRÊN HUD (CHẾ ĐỘ GẦN <=95M)", "DISABLE HUD BOSS PREVIEW (RETURN TO <=95M PROXIMITY)")
            or I18n.Pick("BẬT MÔ PHỎNG THANH MÁU BOSS TRÊN HUD", "PREVIEW BOSS BAR ON LIVE COMBAT HUD"),
        variant = simOn and "secondary" or "primary",
        position = UDim2.new(0, 14, 1, -52),
        size = UDim2.new(1, -28, 0, 40),
        textSize = 12,
        minTextSize = 9,
        onActivated = function()
            PartyController.SimulateBossPhase(selectedRaidId, nil)
            ScreenRouter.Navigate(UIState.Screens.HUD)
        end,
    })

    -- Right Column (46%): Celestial Anchors / Sanctuary Pillars & Raid Objectives
    local rightPanel = PremiumPanel.Create(root, {
        name = "AnchorsAndObjectives",
        variant = "gold",
        title = (#raidCfg.Anchors > 0)
            and I18n.Pick("TRỤ NEO THIÊN GIỚI & MỤC TIÊU RAID", "CELESTIAL ANCHORS & RAID OBJECTIVES")
            or I18n.Pick("TRỤ NĂNG LƯỢNG ĐẤU TRƯỜNG & MỤC TIÊU", "ARENA PYLONS & RAID OBJECTIVES"),
        subtitle = I18n.Pick("Bảo vệ các trụ dẫn truyền và phá giáp Boss đúng nhịp", "Protect critical conduits while maintaining party formation"),
        position = UDim2.new(0.54, 10, 0, 246),
        size = UDim2.new(0.46, -26, 1, -260),
    })

    local anchorsHolder = UIFactory.Create("Frame", rightPanel, {
        Name = "AnchorsGrid",
        Position = UDim2.fromOffset(14, 64),
        Size = UDim2.new(1, -28, 0, 148),
        BackgroundTransparency = 1,
    })
    UIFactory.GridLayout(anchorsHolder, UDim2.new(0.48, 0, 0, 64), UDim2.fromOffset(10, 10))

    local anchorList = #raidCfg.Anchors > 0 and raidCfg.Anchors or {
        { Id = "PylonWest", Name = "West Energy Pylon (-24)", Status = "Phase 2 Shield Conduit", Integrity = 100 },
        { Id = "PylonEast", Name = "East Energy Pylon (+24)", Status = "Phase 2 Shield Conduit", Integrity = 100 },
    }

    for idx, anc in ipairs(anchorList) do
        local aCard = UIFactory.Create("Frame", anchorsHolder, {
            Name = anc.Id,
            BackgroundColor3 = colors.BG_900,
            BorderSizePixel = 0,
            LayoutOrder = idx,
        })
        UIFactory.Corner(aCard, Theme.Radius.Small)
        local warn = anc.Integrity < 85
        UIFactory.Stroke(aCard, warn and colors.ACCENT_GOLD or colors.SUCCESS, 1.2, 0.25)

        UIFactory.Icon(aCard, "Anchor", UDim2.fromOffset(10, 12), 22, warn and colors.ACCENT_GOLD or colors.ACCENT_SAPPHIRE)
        UIFactory.Label(aCard, {
            Name = "AnchorName",
            Text = anc.Name,
            Position = UDim2.fromOffset(38, 8),
            Size = UDim2.new(1, -46, 0, 18),
            TextSize = 12,
            TextColor = colors.TEXT_PRIMARY,
            Bold = true,
            Truncate = Enum.TextTruncate.AtEnd,
        })
        UIFactory.Label(aCard, {
            Name = "AnchorStatus",
            Text = string.format("%s  •  %d%%", anc.Status, anc.Integrity),
            Position = UDim2.fromOffset(38, 30),
            Size = UDim2.new(1, -46, 0, 18),
            TextSize = 11,
            TextColor = warn and colors.ACCENT_GOLD or colors.SUCCESS,
            Bold = true,
            Truncate = Enum.TextTruncate.AtEnd,
        })
    end

    local objBullets = {}
    for _, o in ipairs(raidCfg.Objectives or {}) do
        table.insert(objBullets, "• " .. o)
    end

    UIFactory.Label(rightPanel, {
        Name = "ObjectivesText",
        Text = "<font color='#E4B863'><b>" .. I18n.Pick("DANH MỤC TÁC CHIẾN RAID", "RAID CHECKLIST") .. "</b></font>\n" .. table.concat(objBullets, "\n"),
        Position = UDim2.fromOffset(14, 222),
        Size = UDim2.new(1, -28, 1, -282),
        TextSize = 12,
        TextColor = colors.TEXT_PRIMARY,
        YAlign = Enum.TextYAlignment.Top,
        RichText = true,
    })

    PremiumButton.Create(rightPanel, {
        name = "TravelToBossRealm",
        icon = "Sword",
        label = I18n.Pick("DỊCH CHUYỂN & KHIÊU CHIẾN BOSS (" .. string.upper(selectedRaidId) .. ")", "WARP & START BOSS RUSH (" .. string.upper(selectedRaidId) .. ")"),
        variant = "gold",
        position = UDim2.new(0, 14, 1, -52),
        size = UDim2.new(1, -28, 0, 40),
        textSize = 12,
        minTextSize = 10,
        onActivated = function()
            Store.RecordBossCombat()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes and remotes:FindFirstChild("EquipmentRequest") then
                remotes.EquipmentRequest:FireServer({ action = "StartBossRush", bossId = selectedRaidId })
            else
                PartyController.RequestFastTravel(raidCfg.RealmId)
            end
            ScreenRouter.Navigate(UIState.Screens.HUD)
        end,
    })

    Raid.Refs = {
        Root = root,
        HeaderRefs = headerRefs,
    }
    return root
end

function Raid.Update()
    if Raid.Refs.HeaderRefs and Raid.Refs.HeaderRefs.UpdateCurrencies then
        Raid.Refs.HeaderRefs.UpdateCurrencies(Store.GetSnapshot())
    end
end

function Raid.Cleanup()
    Raid.Refs = {}
end

return Raid
