-- SKYBREAK: Fragments of the Core — Boss & Raid Encounter Screen (Phase 5)
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/Raid.lua
-- Canonical Bosses: Aureon Sentinel (3 phases + 2 Pylons), Noxar (3 combat phases + Purification), Veyr (4 phases + 4 Anchors).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local WorldConfig = require(Shared:WaitForChild("Config"):WaitForChild("WorldConfig"))
local UIState = require(Shared:WaitForChild("Types"):WaitForChild("UIState"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Store = require(script.Parent.Parent:WaitForChild("Store"))
local ScreenRouter = require(script.Parent.Parent:WaitForChild("ScreenRouter"))
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
    local view = Store.GetView()
    local selectedRaidId = view.selectedRaidId or "Veyr"
    local raidCfg = WorldConfig.Raids[selectedRaidId] or WorldConfig.Raids.Veyr

    local root = UIFactory.Create("Frame", parent, {
        Name = "RaidScreen",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 2,
    })

    -- Top Header
    local header = PremiumPanel.Create(root, {
        name = "TopHeader",
        position = UDim2.fromOffset(20, 14),
        size = UDim2.new(1, -40, 0, 58),
    })
    UIFactory.Label(header, {
        Name = "Brand",
        Text = "SKY<font color='#F0F4FA'>BREAK</font>  •  CO-OP RAID & BOSS COMMAND",
        Position = UDim2.fromOffset(18, 0),
        Size = UDim2.fromOffset(520, 58),
        TextSize = 19,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
        RichText = true,
    })
    PremiumButton.Create(header, {
        name = "CloseButton",
        label = "BACK TO HUD [P]",
        variant = "secondary",
        position = UDim2.new(1, -172, 0, 10),
        size = UDim2.fromOffset(156, 38),
        textSize = 12,
        onActivated = function()
            ScreenRouter.Navigate(UIState.Screens.HUD)
        end,
    })

    -- Raid Selector Row (Aureon Sentinel / Noxar / Veyr)
    local selectorRow = UIFactory.Create("Frame", root, {
        Name = "RaidSelectorRow",
        Position = UDim2.fromOffset(20, 82),
        Size = UDim2.new(1, -40, 0, 48),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(selectorRow, Enum.FillDirection.Horizontal, 10, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    for idx, rid in ipairs(WorldConfig.OrderedRaids) do
        local rCfg = WorldConfig.Raids[rid]
        local isSel = (rid == selectedRaidId)
        PremiumButton.Create(selectorRow, {
            name = "SelectRaid_" .. rid,
            label = string.format("%s  (Lv.%d • %d Phases%s)", rCfg.Name, rCfg.LevelReq, rCfg.MaxPhases, rCfg.HasPurification and " + Purification" or ""),
            variant = isSel and "gold" or "secondary",
            selected = isSel,
            size = UDim2.fromOffset(416, 44),
            textSize = 13,
            layoutOrder = idx,
            onActivated = function()
                Store.SetView({ selectedRaidId = rid })
                ScreenRouter.Navigate(UIState.Screens.Raid, { forceRebuild = true, replace = true })
            end,
        })
    end

    -- Live RaidPhase Component Preview Banner
    local _, raidPreviewApi = RaidPhase.Create(root, {
        name = "RaidHeaderPreview",
        anchorPoint = Vector2.new(0, 0),
        position = UDim2.fromOffset(20, 140),
        size = UDim2.new(1, -40, 0, 114),
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
            and "3 COMBAT PHASES + FINAL CORE PURIFICATION RITUAL"
            or "CO-OP RAID (1–6 PLAYERS) • NON-INTRUSIVE COMBAT TELEGRAPHS",
    })

    -- Left Column (54%): Phase Breakdown & Mechanics
    local phasesPanel = PremiumPanel.Create(root, {
        name = "PhasesBreakdown",
        title = "PHASE MECHANICS & TELEGRAPHS",
        subtitle = raidCfg.HasPurification and "3 Combat Phases followed by Core Purification Finisher" or (tostring(raidCfg.MaxPhases) .. " Escalating Ascension Phases"),
        position = UDim2.fromOffset(20, 266),
        size = UDim2.new(0.54, -16, 1, -284),
    })

    local phaseList = UIFactory.Create("Frame", phasesPanel, {
        Name = "PhaseCards",
        Position = UDim2.fromOffset(16, 66),
        Size = UDim2.new(1, -32, 1, -134),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(phaseList, Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top)

    for idx, pInfo in ipairs(raidCfg.Phases) do
        local pCard = UIFactory.Create("Frame", phaseList, {
            Name = "Phase_" .. idx,
            Size = UDim2.new(1, 0, 0, 68),
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
            Size = UDim2.new(1, -140, 0, 20),
            TextSize = 13,
            TextColor = pInfo.Threshold == "FINISHER" and colors.VOID_PURPLE or colors.ACCENT_GOLD,
            Bold = true,
        })

        UIFactory.Label(pCard, {
            Name = "Mechanic",
            Text = pInfo.Mechanic,
            Position = UDim2.fromOffset(12, 28),
            Size = UDim2.new(1, -140, 0, 34),
            TextSize = 12,
            TextColor = colors.TEXT_SECONDARY,
            YAlign = Enum.TextYAlignment.Top,
        })

        PremiumButton.Create(pCard, {
            name = "SimPhase_" .. idx,
            label = "PREVIEW P" .. idx,
            variant = "secondary",
            position = UDim2.new(1, -118, 0.5, -17),
            size = UDim2.fromOffset(106, 34),
            textSize = 11,
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

    PremiumButton.Create(phasesPanel, {
        name = "ShowCombatHUDButton",
        label = "▶  TEST BOSS BAR ON LIVE COMBAT HUD",
        variant = "primary",
        position = UDim2.new(0, 16, 1, -54),
        size = UDim2.new(1, -32, 0, 42),
        textSize = 13,
        onActivated = function()
            PartyController.SimulateBossPhase(selectedRaidId, 1)
            ScreenRouter.Navigate(UIState.Screens.HUD)
        end,
    })

    -- Right Column (46%): 4 Celestial Anchors / Sanctuary Pillars & Raid Objectives
    local rightPanel = PremiumPanel.Create(root, {
        name = "AnchorsAndObjectives",
        variant = "gold",
        title = (#raidCfg.Anchors > 0) and "CELESTIAL ANCHORS & RAID OBJECTIVES" or "ARENA PYLONS & RAID OBJECTIVES",
        subtitle = "Protect critical conduits while maintaining party formation",
        position = UDim2.new(0.54, 14, 0, 266),
        size = UDim2.new(0.46, -34, 1, -284),
    })

    local anchorsHolder = UIFactory.Create("Frame", rightPanel, {
        Name = "AnchorsGrid",
        Position = UDim2.fromOffset(16, 68),
        Size = UDim2.new(1, -32, 0, 156),
        BackgroundTransparency = 1,
    })
    UIFactory.GridLayout(anchorsHolder, UDim2.new(0.48, 0, 0, 68), UDim2.fromOffset(10, 10))

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

        UIFactory.Icon(aCard, "Anchor", UDim2.fromOffset(10, 12), 24, warn and colors.ACCENT_GOLD or colors.ACCENT_SAPPHIRE)
        UIFactory.Label(aCard, {
            Name = "AnchorName",
            Text = anc.Name,
            Position = UDim2.fromOffset(40, 8),
            Size = UDim2.new(1, -48, 0, 20),
            TextSize = 12,
            TextColor = colors.TEXT_PRIMARY,
            Bold = true,
        })
        UIFactory.Label(aCard, {
            Name = "AnchorStatus",
            Text = string.format("%s  •  %d%%", anc.Status, anc.Integrity),
            Position = UDim2.fromOffset(40, 32),
            Size = UDim2.new(1, -48, 0, 20),
            TextSize = 11,
            TextColor = warn and colors.ACCENT_GOLD or colors.SUCCESS,
            Bold = true,
        })
    end

    local objBullets = {}
    for _, o in ipairs(raidCfg.Objectives or {}) do
        table.insert(objBullets, "• " .. o)
    end

    UIFactory.Label(rightPanel, {
        Name = "ObjectivesText",
        Text = "<font color='#E4B863'><b>RAID CHECKLIST</b></font>\n" .. table.concat(objBullets, "\n"),
        Position = UDim2.fromOffset(16, 236),
        Size = UDim2.new(1, -32, 1, -304),
        TextSize = 13,
        TextColor = colors.TEXT_PRIMARY,
        YAlign = Enum.TextYAlignment.Top,
        RichText = true,
    })

    PremiumButton.Create(rightPanel, {
        name = "TravelToBossRealm",
        label = "⚔ WARP & START BOSS RUSH (" .. string.upper(selectedRaidId) .. ")",
        variant = "gold",
        position = UDim2.new(0, 16, 1, -54),
        size = UDim2.new(1, -32, 0, 42),
        textSize = 13,
        onActivated = function()
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes and remotes:FindFirstChild("EquipmentRequest") then
                remotes.EquipmentRequest:FireServer({ action = "StartBossRush", bossId = selectedRaidId })
            else
                PartyController.RequestFastTravel(raidCfg.RealmId)
            end
            ScreenRouter.Navigate(UIState.Screens.HUD)
        end,
    })

    Raid.Refs = { Root = root }
    return root
end

function Raid.Update() end

function Raid.Cleanup()
    Raid.Refs = {}
end

return Raid
