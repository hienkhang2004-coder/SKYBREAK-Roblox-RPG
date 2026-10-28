-- SKYBREAK: Fragments of the Core — Gameplay HUD Screen (Phase 2)
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/HUD.lua
-- Layout: Top-left Player Vitals (Humanoid bound), Mid-left QuestTracker, Top-right Compass & Quick Menu,
-- Top-center RaidPhase Boss Bar (when active), Bottom-center PC Hotbar / Bottom-right Mobile Touch Arc.

local Players = game:GetService("Players")
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
local StatBar = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("StatBar"))
local QuestTracker = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("QuestTracker"))
local SkillButton = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("SkillButton"))
local RaidPhase = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("RaidPhase"))
local HUDController = require(script.Parent.Parent:WaitForChild("Controllers"):WaitForChild("HUDController"))

local HUD = {
    Refs = {},
}

function HUD.Build(parent, responsiveState)
    HUD.Cleanup()
    local colors = Theme.Colors
    local snap = Store.GetSnapshot()
    local view = Store.GetView()
    local isMobile = responsiveState and (responsiveState.TouchControls or responsiveState.IsPortrait)
    local isPortrait = responsiveState and responsiveState.IsPortrait
    local player = Players.LocalPlayer

    local root = UIFactory.Create("Frame", parent, {
        Name = "CombatHUD",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 2,
    })

    -- 1. Top-Left Player Vitals Card
    local vitalsCard = PremiumPanel.Create(root, {
        name = "PlayerHUD",
        position = UDim2.fromOffset(18, 16),
        size = UDim2.fromOffset(isPortrait and 360 or 354, 128),
        transparency = Theme.Transparency.HUDCard,
    })

    local classCfg = WorldConfig.Classes[snap.player.classId] or WorldConfig.Classes.SkyGuardian

    local portraitFrame = UIFactory.Create("Frame", vitalsCard, {
        Name = "ClassCrest",
        Position = UDim2.fromOffset(12, 12),
        Size = UDim2.fromOffset(76, 76),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
    })
    UIFactory.Corner(portraitFrame, Theme.Radius.Medium)
    UIFactory.Stroke(portraitFrame, classCfg.AccentColor or colors.ACCENT_GOLD, 1.6, 0.15)
    UIFactory.Icon(portraitFrame, classCfg.Icon or "Sword", UDim2.new(0.5, -22, 0.5, -22), 44, classCfg.AccentColor)

    local levelLabel = UIFactory.Label(vitalsCard, {
        Name = "Level",
        Text = "Lv. " .. tostring(snap.player.level),
        Position = UDim2.fromOffset(12, 92),
        Size = UDim2.fromOffset(76, 22),
        TextSize = 15,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
    })

    local tierTag = (snap.player.level or 1) < 5 and "NOVICE (SƠ KHAI)" or ((snap.player.level or 1) < 15 and "ADVENTURER" or string.upper(classCfg.Name))
    local playerNameLabel = UIFactory.Label(vitalsCard, {
        Name = "PlayerName",
        Text = ((player and player.DisplayName) or "Skyborn") .. "  •  " .. tierTag,
        Position = UDim2.fromOffset(100, 10),
        Size = UDim2.new(1, -112, 0, 22),
        TextSize = 13,
        TextColor = colors.TEXT_PRIMARY,
        Bold = true,
    })

    local _, hpBarApi = StatBar.Create(vitalsCard, {
        name = "HPBar",
        type = "HP",
        current = snap.vitals.hp,
        max = snap.vitals.maxHp,
        label = "HP",
        position = UDim2.fromOffset(100, 36),
        size = UDim2.new(1, -112, 0, 26),
        scope = "HUD",
    })
    HUDController.BindHumanoidToBar(hpBarApi)

    local _, staminaBarApi = StatBar.Create(vitalsCard, {
        name = "StaminaBar",
        type = "Energy",
        current = snap.vitals.stamina,
        max = snap.vitals.maxStamina,
        label = "EN",
        position = UDim2.fromOffset(100, 68),
        size = UDim2.new(1, -112, 0, 22),
        scope = "HUD",
    })

    local _, xpBarApi = StatBar.Create(vitalsCard, {
        name = "XPBar",
        type = "EXP",
        current = snap.player.exp,
        max = snap.player.expToNext,
        customText = string.format("EXP %s / %s", UIFactory.FormatNumber(snap.player.exp), UIFactory.FormatNumber(snap.player.expToNext)),
        position = UDim2.fromOffset(100, 96),
        size = UDim2.new(1, -112, 0, 18),
        textSize = 11,
        scope = "HUD",
    })

    local shieldLabel = UIFactory.Label(root, {
        Name = "ShieldStatus",
        Text = snap.vitals.shieldRemaining > 0 and string.format("🛡 AEGIS BARRIER • %ds", math.ceil(snap.vitals.shieldRemaining)) or "",
        Position = UDim2.fromOffset(22, 148),
        Size = UDim2.fromOffset(340, 22),
        TextSize = 14,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
    })

    -- 2. Middle-Left Collapsible Quest Tracker
    local _, questTrackerApi = QuestTracker.Create(root, {
        name = "QuestTracker",
        position = UDim2.fromOffset(18, 174),
        size = UDim2.fromOffset(isPortrait and 330 or 318, 172),
        collapsed = view.questTrackerCollapsed,
        onToggleCollapse = function(isCol)
            Store.SetView({ questTrackerCollapsed = isCol })
        end,
        onOpenJournal = function()
            ScreenRouter.Navigate(UIState.Screens.QuestJournal)
        end,
    })
    questTrackerApi:Update({ activeQuest = snap.quest })

    -- 3. Top-Right Region Compass & Quick Navigation Bar
    local compassCard = PremiumPanel.Create(root, {
        name = "Compass",
        position = UDim2.new(1, -248, 0, 16),
        size = UDim2.fromOffset(230, 118),
        transparency = Theme.Transparency.HUDCard,
        visible = view.settings.showMinimap ~= false,
    })

    local currentRealmCfg = WorldConfig.RealmById[snap.world.current] or WorldConfig.RealmById.GoldenSky
    local curWorldOrder = (player and player:GetAttribute("CurrentWorldOrder")) or 1
    local realmTitle = UIFactory.Label(compassCard, {
        Name = "CompassTitle",
        Text = string.format("◈  %s (W%d/20)", string.upper(currentRealmCfg.Name), curWorldOrder),
        Position = UDim2.fromOffset(10, 6),
        Size = UDim2.new(1, -20, 0, 20),
        TextSize = 13,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
    })

    local nextGateLbl = (player and player:GetAttribute("NextWorldGateLabel")) or "WORLD 1 ➡ WORLD 2"
    local portalCompassLabel = UIFactory.Label(compassCard, {
        Name = "Directions",
        Text = "🌀 " .. tostring(nextGateLbl),
        Position = UDim2.fromOffset(10, 26),
        Size = UDim2.new(1, -20, 0, 34),
        TextSize = 11,
        TextColor = colors.ACCENT_SAPPHIRE,
        Bold = true,
        Wrapped = true,
        XAlign = Enum.TextXAlignment.Center,
    })

    PremiumButton.Create(compassCard, {
        name = "OpenMap",
        label = "WORLD MAP [M]",
        variant = "secondary",
        position = UDim2.fromOffset(12, 66),
        size = UDim2.new(1, -24, 0, 38),
        textSize = 13,
        onActivated = function()
            ScreenRouter.Navigate(UIState.Screens.WorldMap)
        end,
    })

    -- 3B. Top-Right Companion Squad Progression Card (Solo Lv.1 -> Kairo Lv.15 -> Lumen Lv.30 -> Nyx Lv.50)
    local companionCard = PremiumPanel.Create(root, {
        name = "CompanionSquadCard",
        position = UDim2.new(1, -248, 0, 140),
        size = UDim2.fromOffset(230, 86),
        transparency = Theme.Transparency.HUDCard,
    })

    local companionTitle = UIFactory.Label(companionCard, {
        Name = "CompanionTitle",
        Text = "🛡 ĐỒNG HÀNH: SOLO (SƠ KHAI)",
        Position = UDim2.fromOffset(10, 6),
        Size = UDim2.new(1, -20, 0, 18),
        TextSize = 11,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
    })

    local companionSub = UIFactory.Label(companionCard, {
        Name = "CompanionRoster",
        Text = "🔒Kairo(Lv15) • 🔒Lumen(Lv30) • 🔒Nyx(Lv50)",
        Position = UDim2.fromOffset(10, 24),
        Size = UDim2.new(1, -20, 0, 18),
        TextSize = 10,
        TextColor = colors.TEXT_SECONDARY,
        Bold = true,
    })

    local partyBtnRow = UIFactory.Create("Frame", companionCard, {
        Name = "PartySizeButtons",
        Position = UDim2.fromOffset(8, 46),
        Size = UDim2.new(1, -16, 0, 32),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(partyBtnRow, Enum.FillDirection.Horizontal, 4, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)

    local partySizeDefs = {
        { id = "Solo", label = "SOLO", reqLv = 1 },
        { id = "Duo", label = "DUO (Lv15)", reqLv = 15 },
        { id = "Trio", label = "TRIO (Lv30)", reqLv = 30 },
        { id = "Squad", label = "SQUAD (Lv50)", reqLv = 50 },
    }
    local partySizeApis = {}
    local curPartySize = (snap.party and snap.party.partySize) or "Solo"
    for idx, ps in ipairs(partySizeDefs) do
        local _, pApi = PremiumButton.Create(partyBtnRow, {
            name = "Party_" .. ps.id,
            label = ps.label,
            variant = (curPartySize == ps.id) and "gold" or "secondary",
            size = UDim2.fromOffset(ps.id == "Squad" and 58 or 50, 28),
            textSize = 9,
            layoutOrder = idx,
            onActivated = function()
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if remotes and remotes:FindFirstChild("EquipmentRequest") then
                    remotes.EquipmentRequest:FireServer({ action = "SetPartySize", size = ps.id })
                end
            end,
        })
        partySizeApis[ps.id] = pApi
    end

    -- Quick Navigation Strip (Bottom-Left — compact so it never overlaps AbilityHotbar)
    local quickNav = UIFactory.Create("Frame", root, {
        Name = "QuickNavStrip",
        Position = UDim2.new(0, 14, 1, -50),
        Size = UDim2.fromOffset(isPortrait and 460 or 496, 36),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(quickNav, Enum.FillDirection.Horizontal, 4, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    local navItems = {
        { id = "Menu", label = "☰ MENU", route = UIState.Screens.MainMenu, width = 62 },
        { id = "Fruits", label = "🍎 FRUITS [G]", route = UIState.Screens.Fruits, isGold = true, width = 88 },
        { id = "Inventory", label = "BAG [I]", route = UIState.Screens.Inventory, width = 58 },
        { id = "Skills", label = "SKILLS [K]", route = UIState.Screens.Skills, width = 68 },
        { id = "Quests", label = "QUESTS [J]", route = UIState.Screens.QuestJournal, width = 70 },
        { id = "Forge", label = "FORGE [F]", route = UIState.Screens.Forge, width = 64 },
        { id = "Raid", label = "RAID [P]", route = UIState.Screens.Raid, width = 58 },
    }
    for idx, nav in ipairs(navItems) do
        PremiumButton.Create(quickNav, {
            name = nav.id,
            label = nav.label,
            variant = nav.isGold and "gold" or "secondary",
            size = UDim2.fromOffset(isPortrait and 60 or (nav.width or 66), 34),
            textSize = 10,
            layoutOrder = idx,
            onActivated = function()
                ScreenRouter.Navigate(nav.route)
            end,
        })
    end

    -- Blox-Fruits Loadout Slots ([1]-[4]) & Devil Fruit Moves ([Z][X][C][V][F]) Strip above Hotbar
    local fruitMovesBar = UIFactory.Create("Frame", root, {
        Name = "FruitLoadoutMovesStrip",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 108, 1, -96),
        Size = UDim2.fromOffset(540, 32),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(fruitMovesBar, Enum.FillDirection.Horizontal, 4, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)

    local eqFruitId = (snap.fruits and snap.fruits.equippedFruit) or "GaleCore"
    local activeSlotNum = (snap.fruits and snap.fruits.activeSlot) or 2
    local fruitMoveDefs = {
        { id = "Slot1", label = "[1] Võ", isSlot = 1, w = 56 },
        { id = "Slot2", label = "🍎 [2] " .. tostring(eqFruitId):gsub("Core", ""), isSlot = 2, w = 108 },
        { id = "Slot3", label = "[3] Kiếm", isSlot = 3, w = 62 },
        { id = "Slot4", label = "[4] Súng", isSlot = 4, w = 62 },
        { id = "MoveZ", label = "[Z]", moveKey = "Z", w = 38 },
        { id = "MoveX", label = "[X]", moveKey = "X", w = 38 },
        { id = "MoveC", label = "[C]", moveKey = "C", w = 38 },
        { id = "MoveV", label = "[V]", moveKey = "V", w = 38 },
        { id = "MoveF", label = "[F]", moveKey = "F", w = 38 },
    }
    local fruitSlotApis = {}
    for idx, fm in ipairs(fruitMoveDefs) do
        local _, fApi = PremiumButton.Create(fruitMovesBar, {
            name = fm.id,
            label = fm.label,
            variant = (fm.isSlot == activeSlotNum) and "gold" or (fm.moveKey and "primary" or "secondary"),
            size = UDim2.fromOffset(fm.w or 42, 30),
            textSize = 10,
            layoutOrder = idx,
            onActivated = function()
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if fm.isSlot then
                    if remotes and remotes:FindFirstChild("EquipmentRequest") then
                        remotes.EquipmentRequest:FireServer({ action = "SelectSlot", slot = fm.isSlot })
                    end
                elseif fm.moveKey then
                    HUDController.TriggerAction(fm.moveKey)
                end
            end,
        })
        if fm.isSlot then
            fruitSlotApis[fm.isSlot] = fApi
        end
    end

    -- 4. Top-Center Boss / Raid Phase Bar (only visible during encounter or raid preview)
    local _, bossBarApi = RaidPhase.Create(root, {
        name = "BossHUD",
        position = isPortrait and UDim2.new(0.5, 0, 0, 356) or UDim2.new(0.5, 0, 0, 16),
        size = UDim2.fromOffset(isPortrait and 520 or 540, 112),
        visible = snap.raid and snap.raid.active == true,
    })
    if snap.raid and snap.raid.active then
        bossBarApi:Update(snap.raid)
    end

    -- 5. Contextual [E] Interact Prompt
    local interactBtn, interactApi = PremiumButton.Create(root, {
        name = "Interact",
        label = view.interactPrompt and ("[E] • " .. view.interactPrompt) or "[E] • INTERACT",
        variant = "gold",
        anchorPoint = Vector2.new(0.5, 1),
        position = UDim2.new(0.5, 108, 1, -136),
        size = UDim2.fromOffset(330, 42),
        visible = view.interactPrompt ~= nil,
        onActivated = function()
            HUDController.TriggerAction("Interact")
        end,
    })

    -- 6. Ability Hotbar (PC Bottom-Center vs Mobile Right-Thumb Cluster)
    local skills = classCfg.Skills or {}
    local sk1 = skills[1] or { Id = "SkySlash", Name = "Sky Slash", Keybind = "1", Icon = "Sword", LevelReq = 1, Cooldown = 6 }
    local sk2 = skills[2] or { Id = "GuardianShield", Name = "Guardian Shield", Keybind = "2", Icon = "Shield", LevelReq = 5, Cooldown = 16 }
    local sk3 = skills[4] or { Id = "JudgmentStrike", Name = "Judgment Strike", Keybind = "3", Icon = "Bolt", LevelReq = 12, Cooldown = 12, EnergyCost = 25 }
    local skUlt = skills[5] or { Id = "CelestialAegis", Name = "Celestial Aegis", Keybind = "R", Icon = "Core", LevelReq = 20, Cooldown = 45, EnergyCost = 100 }

    local hotbarDefinitions = {
        { action = "Skill1", cfg = sk1 },
        { action = "Skill2", cfg = sk2 },
        { action = "Skill3", cfg = sk3 },
        {
            action = "Dodge",
            cfg = { Id = "Dodge", Name = "Dodge", Keybind = "Q", Icon = "Bolt", LevelReq = 1, Cooldown = 1.2, EnergyCost = 30 },
        },
        {
            action = "Ultimate",
            cfg = skUlt,
            isUltimate = true,
        },
    }

    local hotbarHolder = UIFactory.Create("Frame", root, {
        Name = "AbilityHotbar",
        AnchorPoint = isMobile and Vector2.new(1, 1) or Vector2.new(0.5, 1),
        Position = isMobile and UDim2.new(1, -140, 1, -18) or UDim2.new(0.5, 108, 1, -12),
        Size = UDim2.fromOffset(440, 78),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(hotbarHolder, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)

    local skillSlotApis = {}
    for idx, slot in ipairs(hotbarDefinitions) do
        local _, api = SkillButton.Create(hotbarHolder, {
            name = slot.action,
            skillId = slot.cfg.Id,
            label = slot.cfg.Name,
            keybind = slot.cfg.Keybind,
            icon = slot.cfg.Icon,
            energyCost = slot.cfg.EnergyCost or slot.cfg.StaminaCost or 0,
            maxCooldown = slot.cfg.Cooldown or 6,
            isUltimate = slot.isUltimate,
            locked = snap.player.level < (slot.cfg.LevelReq or 1),
            layoutOrder = idx,
            size = UDim2.fromOffset(82, 74),
            onActivated = function()
                HUDController.TriggerAction(slot.action)
            end,
        })
        skillSlotApis[slot.action] = {
            Api = api,
            Config = slot.cfg,
        }
    end

    -- Right-Side Combat Strike & Dash Cluster (Touch-friendly & PC clickable)
    local strikeBtn = UIFactory.Create("TextButton", root, {
        Name = "Attack",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -22, 1, -22),
        Size = UDim2.fromOffset(96, 96),
        BackgroundColor3 = colors.ACCENT_DEEP_BLUE,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 7,
    })
    UIFactory.PillCorner(strikeBtn)
    UIFactory.Stroke(strikeBtn, colors.ACCENT_GOLD, 2.2, 0.08)
    UIFactory.Gradient(strikeBtn, colors.ACCENT_SAPPHIRE, colors.ACCENT_DEEP_BLUE, 90)
    UIFactory.Icon(strikeBtn, classCfg.Icon or "Sword", UDim2.new(0.5, -22, 0.36, -22), 44, colors.TEXT_PRIMARY)
    UIFactory.Label(strikeBtn, {
        Name = "Caption",
        Text = "STRIKE / HOLD",
        Position = UDim2.new(0, 6, 1, -24),
        Size = UDim2.new(1, -12, 0, 18),
        TextSize = 10,
        TextColor = colors.TEXT_PRIMARY,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        ZIndex = 8,
    })
    strikeBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            HUDController.TriggerAttackInput(input)
        end
    end)

    local _, dashApi = PremiumButton.Create(root, {
        name = "Dash",
        label = "DASH • SHIFT",
        variant = "secondary",
        anchorPoint = Vector2.new(1, 1),
        position = UDim2.new(1, -22, 1, -126),
        size = UDim2.fromOffset(96, 40),
        textSize = 11,
        onActivated = function()
            HUDController.TriggerAction("Dash")
        end,
    })

    HUD.Refs = {
        Root = root,
        LevelLabel = levelLabel,
        PlayerNameLabel = playerNameLabel,
        FruitSlotApis = fruitSlotApis,
        HPBarApi = hpBarApi,
        StaminaBarApi = staminaBarApi,
        XPBarApi = xpBarApi,
        ShieldLabel = shieldLabel,
        QuestTrackerApi = questTrackerApi,
        RealmTitle = realmTitle,
        PortalCompassLabel = portalCompassLabel,
        CompassCard = compassCard,
        CompanionCard = companionCard,
        CompanionTitle = companionTitle,
        CompanionSub = companionSub,
        PartySizeApis = partySizeApis,
        BossBarApi = bossBarApi,
        InteractBtn = interactBtn,
        InteractApi = interactApi,
        SkillSlotApis = skillSlotApis,
        DashApi = dashApi,
    }

    HUD.Update(snap, view)
    return root
end

function HUD.Update(snapshot, viewState)
    local refs = HUD.Refs
    if not refs.Root or not snapshot then
        return
    end
    viewState = viewState or Store.GetView()

    if refs.LevelLabel then
        refs.LevelLabel.Text = "Lv. " .. tostring(snapshot.player.level)
    end
    if refs.PlayerNameLabel then
        local player = Players.LocalPlayer
        local classCfg = WorldConfig.Classes[snapshot.player.classId] or WorldConfig.Classes.SkyGuardian
        local lv = tonumber(snapshot.player.level) or 1
        local tierTag = lv < 5 and "NOVICE (SƠ KHAI)" or (lv < 15 and "ADVENTURER" or string.upper(classCfg.Name))
        refs.PlayerNameLabel.Text = ((player and player.DisplayName) or "Skyborn") .. "  •  " .. tierTag
    end
    if refs.FruitSlotApis and snapshot.fruits then
        local eqF = tostring(snapshot.fruits.equippedFruit or "GaleCore"):gsub("Core", "")
        local actSlot = tonumber(snapshot.fruits.activeSlot) or 2
        if refs.FruitSlotApis[2] then
            refs.FruitSlotApis[2]:Update({ label = "🍎 [2] " .. eqF })
        end
        for sIdx, sApi in pairs(refs.FruitSlotApis) do
            if sApi and sApi.SetVariant then
                sApi:SetVariant(sIdx == actSlot and "gold" or "secondary")
            end
        end
    end
    if refs.HPBarApi then
        refs.HPBarApi:Update({
            current = snapshot.vitals.hp,
            max = snapshot.vitals.maxHp,
        })
    end
    if refs.StaminaBarApi then
        refs.StaminaBarApi:Update({
            current = snapshot.vitals.stamina,
            max = snapshot.vitals.maxStamina,
        })
    end
    if refs.XPBarApi then
        refs.XPBarApi:Update({
            current = snapshot.player.exp,
            max = snapshot.player.expToNext,
            customText = string.format("EXP %s / %s", UIFactory.FormatNumber(snapshot.player.exp), UIFactory.FormatNumber(snapshot.player.expToNext)),
        })
    end
    if refs.ShieldLabel then
        local sh = tonumber(snapshot.vitals.shieldRemaining) or 0
        refs.ShieldLabel.Text = sh > 0 and string.format("🛡 AEGIS BARRIER • %ds", math.ceil(sh)) or ""
    end
    if refs.QuestTrackerApi then
        refs.QuestTrackerApi:Update({
            activeQuest = snapshot.quest,
            collapsed = viewState.questTrackerCollapsed,
        })
    end
    if refs.RealmTitle and snapshot.world then
        local player = Players.LocalPlayer
        local wOrder = (player and player:GetAttribute("CurrentWorldOrder")) or 1
        local realmCfg = WorldConfig.RealmById[snapshot.world.current] or WorldConfig.RealmById.GoldenSky
        refs.RealmTitle.Text = string.format("◈  %s (W%d/20)", string.upper(realmCfg.Name), wOrder)
        if refs.PortalCompassLabel then
            local gateLbl = (player and player:GetAttribute("NextWorldGateLabel")) or "WORLD 1 ➡ WORLD 2"
            refs.PortalCompassLabel.Text = "🌀 " .. tostring(gateLbl)
        end
    end
    if refs.CompassCard and viewState.settings then
        refs.CompassCard.Visible = viewState.settings.showMinimap ~= false
    end
    if refs.CompanionTitle and refs.CompanionSub then
        local lv = tonumber(snapshot.player and snapshot.player.level) or 1
        local pSize = (snapshot.party and snapshot.party.partySize) or (lv < 15 and "Solo" or "Duo")
        local activeCount = (pSize == "Solo" and 0) or (pSize == "Duo" and (lv >= 15 and 1 or 0)) or (pSize == "Trio" and (lv >= 30 and 2 or (lv >= 15 and 1 or 0))) or (lv >= 50 and 3 or (lv >= 30 and 2 or (lv >= 15 and 1 or 0)))
        refs.CompanionTitle.Text = string.format("🛡 ĐỒNG HÀNH: %s (%d/3)", string.upper(pSize), activeCount)
        local kTag = lv >= 15 and "✓Kairo" or "🔒Kairo(Lv15)"
        local lTag = lv >= 30 and "✓Lumen" or "🔒Lumen(Lv30)"
        local nTag = lv >= 50 and "✓Nyx" or "🔒Nyx(Lv50)"
        refs.CompanionSub.Text = kTag .. " • " .. lTag .. " • " .. nTag
        if refs.PartySizeApis then
            for psId, psApi in pairs(refs.PartySizeApis) do
                if psApi and psApi.SetVariant then
                    psApi:SetVariant(psId == pSize and "gold" or "secondary")
                end
            end
        end
    end
    if refs.BossBarApi then
        refs.BossBarApi:Update(snapshot.raid or { active = false })
    end
    if refs.InteractBtn and refs.InteractApi then
        local prompt = viewState.interactPrompt
        refs.InteractBtn.Visible = prompt ~= nil
        if prompt then
            refs.InteractApi:Update({ label = "[E] • " .. tostring(prompt) })
        end
    end

    -- Cooldowns & Level Locks
    local elapsed = math.max(0, os.clock() - (Store.LastServerSyncClock or os.clock()))
    if refs.SkillSlotApis then
        for _, slot in pairs(refs.SkillSlotApis) do
            local cfg = slot.Config
            local locked = snapshot.player.level < (cfg.LevelReq or 1)
            local rawCd = snapshot.cooldowns and (snapshot.cooldowns[cfg.Id] or 0) or 0
            local remainingCd = math.max(0, rawCd - elapsed)
            slot.Api:Update({
                locked = locked,
                lockLabel = locked and ("Lv." .. tostring(cfg.LevelReq)) or nil,
                cooldown = remainingCd,
                maxCooldown = cfg.Cooldown or 6,
                outOfEnergy = (cfg.StaminaCost and snapshot.vitals.stamina < cfg.StaminaCost) or false,
            })
        end
    end
    if refs.DashApi and snapshot.cooldowns then
        local dashCd = math.max(0, (snapshot.cooldowns.Dash or 0) - elapsed)
        refs.DashApi:Update({
            label = dashCd > 0 and string.format("DASH %.1fs", dashCd) or "DASH • SHIFT",
        })
    end
end

function HUD.Cleanup()
    HUDController.Cleanup()
    HUD.Refs = {}
end

return HUD
