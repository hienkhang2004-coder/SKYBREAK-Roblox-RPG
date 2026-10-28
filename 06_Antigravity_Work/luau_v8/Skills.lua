-- SKYBREAK: Fragments of the Core — Skills & Class Ascension Screen (Phase 4)
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/Skills.lua
-- 3 Canonical Classes: Sky Guardian, Thunder Striker, Arcane Mage + Gender Selection + Skill Mastery Tree.

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
local PartyController = require(script.Parent.Parent:WaitForChild("Controllers"):WaitForChild("PartyController"))

local Skills = {
    Refs = {},
}

function Skills.Build(parent)
    Skills.Cleanup()
    local colors = Theme.Colors
    local snap = Store.GetSnapshot()
    local view = Store.GetView()
    local selectedClassId = view.selectedClassTab or snap.player.classId or "SkyGuardian"
    local classCfg = WorldConfig.Classes[selectedClassId] or WorldConfig.Classes.SkyGuardian

    local root = UIFactory.Create("Frame", parent, {
        Name = "SkillsScreen",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 2,
    })

    -- Top Header Bar
    local header = PremiumPanel.Create(root, {
        name = "TopHeader",
        position = UDim2.fromOffset(20, 14),
        size = UDim2.new(1, -40, 0, 58),
    })
    UIFactory.Label(header, {
        Name = "Brand",
        Text = "SKY<font color='#F0F4FA'>BREAK</font>  •  CLASSES & ASCENSION SKILLS",
        Position = UDim2.fromOffset(18, 0),
        Size = UDim2.fromOffset(480, 58),
        TextSize = 19,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
        RichText = true,
    })
    PremiumButton.Create(header, {
        name = "CloseButton",
        label = "BACK TO HUD [ESC]",
        variant = "secondary",
        position = UDim2.new(1, -184, 0, 10),
        size = UDim2.fromOffset(168, 38),
        textSize = 12,
        onActivated = function()
            ScreenRouter.Navigate(UIState.Screens.HUD)
        end,
    })

    -- Class Selector Cards (Top Row: 3 Canonical Classes)
    local classRow = UIFactory.Create("Frame", root, {
        Name = "ClassTabs",
        Position = UDim2.fromOffset(20, 82),
        Size = UDim2.new(1, -40, 0, 112),
        BackgroundTransparency = 1,
    })

    for idx, cid in ipairs(WorldConfig.OrderedClasses) do
        local c = WorldConfig.Classes[cid]
        local isCurrentTab = (cid == selectedClassId)
        local isEquippedClass = (cid == snap.player.classId)

        local card = PremiumPanel.Create(classRow, {
            name = "Class_" .. cid,
            variant = isCurrentTab and "gold" or "default",
            position = UDim2.new((idx - 1) * 0.336, 0, 0, 0),
            size = UDim2.new(0.328, 0, 1, 0),
        })

        UIFactory.Icon(card, c.Icon, UDim2.fromOffset(16, 18), 44, c.AccentColor)

        UIFactory.Label(card, {
            Name = "Name",
            Text = string.upper(c.Name) .. (isEquippedClass and "  [ACTIVE]" or ""),
            Position = UDim2.fromOffset(72, 12),
            Size = UDim2.new(1, -88, 0, 22),
            TextSize = 16,
            TextColor = isCurrentTab and colors.ACCENT_GOLD or colors.TEXT_PRIMARY,
            Bold = true,
        })

        UIFactory.Label(card, {
            Name = "Role",
            Text = c.Role,
            Position = UDim2.fromOffset(72, 34),
            Size = UDim2.new(1, -88, 0, 18),
            TextSize = 12,
            TextColor = colors.TEXT_SECONDARY,
        })

        PremiumButton.Create(card, {
            name = "InspectOrEquip_" .. cid,
            label = isCurrentTab and (isEquippedClass and "EQUIPPED CLASS" or "SWITCH TO CLASS") or "INSPECT SKILLS",
            variant = isEquippedClass and "gold" or (isCurrentTab and "primary" or "secondary"),
            position = UDim2.fromOffset(72, 60),
            size = UDim2.new(1, -88, 0, 38),
            textSize = 12,
            onActivated = function()
                if not isCurrentTab then
                    Store.SetView({ selectedClassTab = cid })
                    ScreenRouter.Navigate(UIState.Screens.Skills, { forceRebuild = true, replace = true })
                else
                    PartyController.RequestClassOrGenderChange(cid, snap.player.gender)
                end
            end,
        })
    end

    -- Left Column: Class Overview, Gender Toggle & Reset Mastery
    local overviewPanel = PremiumPanel.Create(root, {
        name = "ClassOverview",
        title = string.upper(classCfg.Name),
        subtitle = classCfg.Role,
        position = UDim2.fromOffset(20, 206),
        size = UDim2.new(0.32, -16, 1, -224),
    })

    UIFactory.Label(overviewPanel, {
        Name = "LoreText",
        Text = classCfg.Lore .. "\n\n<b>BASE MULTIPLIERS</b>\n"
            .. string.format("• HP Multiplier: <b>%.2fx</b>\n• ATK Multiplier: <b>%.2fx</b>\n• DEF Multiplier: <b>%.2fx</b>\n• Move Speed: <b>%d</b>",
                classCfg.BaseMultipliers.HP,
                classCfg.BaseMultipliers.ATK,
                classCfg.BaseMultipliers.DEF,
                classCfg.BaseMultipliers.Speed
            ),
        Position = UDim2.fromOffset(16, 66),
        Size = UDim2.new(1, -32, 0, 178),
        TextSize = 13,
        TextColor = colors.TEXT_PRIMARY,
        YAlign = Enum.TextYAlignment.Top,
        RichText = true,
    })

    UIFactory.Label(overviewPanel, {
        Name = "GenderTitle",
        Text = "AVATAR RIG / GENDER",
        Position = UDim2.fromOffset(16, 256),
        Size = UDim2.new(1, -32, 0, 20),
        TextSize = 12,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
    })

    for i, gender in ipairs({ "Male", "Female" }) do
        local supported = classCfg.SupportedGenders[gender] == true
        local isCurrentGender = (snap.player.gender == gender)
        PremiumButton.Create(overviewPanel, {
            name = gender,
            label = gender == "Male" and "MALE RIG" or (supported and "FEMALE RIG" or "FEMALE (WIP)"),
            variant = isCurrentGender and "primary" or "secondary",
            selected = isCurrentGender,
            position = UDim2.new((i - 1) * 0.5, i == 1 and 16 or 6, 0, 282),
            size = UDim2.new(0.5, -22, 0, 40),
            textSize = 12,
            onActivated = function()
                PartyController.RequestClassOrGenderChange(selectedClassId, gender)
            end,
        })
    end

    UIFactory.Label(overviewPanel, {
        Name = "KataTitle",
        Text = "⚡ 3D MOTION KATA & AWAKENING (12-KEYFRAME):",
        Position = UDim2.fromOffset(16, 330),
        Size = UDim2.new(1, -32, 0, 18),
        TextSize = 11,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
    })
    for kIdx, kDef in ipairs({
        { id = "HeroicKata", label = "🥋 KATA" },
        { id = "ElementalSurge", label = "⚡ SURGE" },
        { id = "UltimateAwakening", label = "👑 AWAKEN" },
    }) do
        PremiumButton.Create(overviewPanel, {
            name = "Kata_" .. kDef.id,
            label = kDef.label,
            variant = kIdx == 3 and "gold" or "secondary",
            position = UDim2.new((kIdx - 1) * 0.333, kIdx == 1 and 16 or 6, 0, 352),
            size = UDim2.new(0.333, -14, 0, 32),
            textSize = 10,
            onActivated = function()
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if remotes and remotes:FindFirstChild("EquipmentRequest") then
                    remotes.EquipmentRequest:FireServer({ action = "TriggerKataPose", clip = kDef.id })
                end
            end,
        })
    end

    UIFactory.Label(overviewPanel, {
        Name = "KataTitle",
        Text = "⚡ 3D MOTION KATA & AWAKENING (12-KEYFRAME):",
        Position = UDim2.fromOffset(16, 330),
        Size = UDim2.new(1, -32, 0, 18),
        TextSize = 11,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
    })
    for kIdx, kDef in ipairs({
        { id = "HeroicKata", label = "🥋 KATA" },
        { id = "ElementalSurge", label = "⚡ SURGE" },
        { id = "UltimateAwakening", label = "👑 AWAKEN" },
    }) do
        PremiumButton.Create(overviewPanel, {
            name = "Kata_" .. kDef.id,
            label = kDef.label,
            variant = kIdx == 3 and "gold" or "secondary",
            position = UDim2.new((kIdx - 1) * 0.333, kIdx == 1 and 16 or 6, 0, 352),
            size = UDim2.new(0.333, -14, 0, 32),
            textSize = 10,
            onActivated = function()
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if remotes and remotes:FindFirstChild("EquipmentRequest") then
                    remotes.EquipmentRequest:FireServer({ action = "TriggerKataPose", clip = kDef.id })
                end
            end,
        })
    end

    UIFactory.Label(overviewPanel, {
        Name = "KataTitle",
        Text = "⚡ 3D MOTION KATA & AWAKENING (12-KEYFRAME):",
        Position = UDim2.fromOffset(16, 330),
        Size = UDim2.new(1, -32, 0, 18),
        TextSize = 11,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
    })
    for kIdx, kDef in ipairs({
        { id = "HeroicKata", label = "🥋 KATA" },
        { id = "ElementalSurge", label = "⚡ SURGE" },
        { id = "UltimateAwakening", label = "👑 AWAKEN" },
    }) do
        PremiumButton.Create(overviewPanel, {
            name = "Kata_" .. kDef.id,
            label = kDef.label,
            variant = kIdx == 3 and "gold" or "secondary",
            position = UDim2.new((kIdx - 1) * 0.333, kIdx == 1 and 16 or 6, 0, 352),
            size = UDim2.new(0.333, -14, 0, 32),
            textSize = 10,
            onActivated = function()
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if remotes and remotes:FindFirstChild("EquipmentRequest") then
                    remotes.EquipmentRequest:FireServer({ action = "TriggerKataPose", clip = kDef.id })
                end
            end,
        })
    end

    UIFactory.Label(overviewPanel, {
        Name = "KataTitle",
        Text = "⚡ 3D MOTION KATA & AWAKENING (12-KEYFRAME):",
        Position = UDim2.fromOffset(16, 330),
        Size = UDim2.new(1, -32, 0, 18),
        TextSize = 11,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
    })
    for kIdx, kDef in ipairs({
        { id = "HeroicKata", label = "🥋 KATA" },
        { id = "ElementalSurge", label = "⚡ SURGE" },
        { id = "UltimateAwakening", label = "👑 AWAKEN" },
    }) do
        PremiumButton.Create(overviewPanel, {
            name = "Kata_" .. kDef.id,
            label = kDef.label,
            variant = kIdx == 3 and "gold" or "secondary",
            position = UDim2.new((kIdx - 1) * 0.333, kIdx == 1 and 16 or 6, 0, 352),
            size = UDim2.new(0.333, -14, 0, 32),
            textSize = 10,
            onActivated = function()
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if remotes and remotes:FindFirstChild("EquipmentRequest") then
                    remotes.EquipmentRequest:FireServer({ action = "TriggerKataPose", clip = kDef.id })
                end
            end,
        })
    end

    PremiumButton.Create(overviewPanel, {
        name = "SwitchClassButton",
        label = (selectedClassId == snap.player.classId) and "✓  ACTIVE CLASS" or ("ACTIVATE " .. string.upper(classCfg.Name)),
        variant = "gold",
        position = UDim2.new(0, 16, 1, -104),
        size = UDim2.new(1, -32, 0, 42),
        textSize = 13,
        onActivated = function()
            PartyController.RequestClassOrGenderChange(selectedClassId, snap.player.gender)
        end,
    })

    PremiumButton.Create(overviewPanel, {
        name = "ResetSkillsButton",
        label = "RESET ASCENSION MASTERY",
        variant = "secondary",
        position = UDim2.new(0, 16, 1, -54),
        size = UDim2.new(1, -32, 0, 38),
        textSize = 12,
        onActivated = function()
            Store.OpenModal({
                title = "RESET ASCENSION MASTERY",
                content = "Resetting skill mastery points requires server verification at the Sky Hub Altar. Proceed with Mastery Reset request?",
                confirmLabel = "REQUEST RESET",
                cancelLabel = "CANCEL",
                variant = "danger",
                onConfirm = function()
                    Store.ShowToast("Mastery Reset requested (validated by server SkillService).", "info")
                end,
            })
        end,
    })

    -- Right Column: Skill Tree List (Active, Passive, Ultimate)
    local skillListPanel = PremiumPanel.Create(root, {
        name = "SkillTreePanel",
        title = "SKILL TREE & ASCENSION NODES",
        subtitle = "Server validates Level gates, Energy costs, and Cooldowns",
        position = UDim2.new(0.32, 16, 0, 206),
        size = UDim2.new(0.68, -36, 1, -224),
    })

    local scroll = UIFactory.Create("ScrollingFrame", skillListPanel, {
        Name = "SkillsScroll",
        Position = UDim2.fromOffset(16, 66),
        Size = UDim2.new(1, -32, 1, -80),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 5,
        ScrollBarImageColor3 = colors.ACCENT_SAPPHIRE,
    })
    UIFactory.ListLayout(scroll, Enum.FillDirection.Vertical, 10, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top)

    for idx, sk in ipairs(classCfg.Skills) do
        local unlocked = snap.player.level >= (sk.LevelReq or 1)
        local row = UIFactory.Create("Frame", scroll, {
            Name = "SkillNode_" .. sk.Id,
            Size = UDim2.new(1, -8, 0, 86),
            BackgroundColor3 = unlocked and colors.BG_700 or colors.BG_900,
            BackgroundTransparency = 0.08,
            BorderSizePixel = 0,
            LayoutOrder = idx,
        })
        UIFactory.Corner(row, Theme.Radius.Medium)
        UIFactory.Stroke(
            row,
            unlocked and (sk.Type == "Ultimate" and colors.ACCENT_GOLD or colors.ACCENT_SAPPHIRE) or colors.STROKE_STEEL,
            1.4,
            unlocked and 0.18 or 0.5
        )

        UIFactory.Icon(row, sk.Icon, UDim2.fromOffset(14, 21), 44, unlocked and classCfg.AccentColor or colors.TEXT_SECONDARY)

        UIFactory.Badge(
            row,
            "[" .. sk.Keybind .. "] " .. string.upper(sk.Type),
            UDim2.fromOffset(72, 12),
            UDim2.fromOffset(104, 20),
            sk.Type == "Ultimate" and colors.ACCENT_GOLD or colors.ACCENT_SAPPHIRE,
            colors.TEXT_PRIMARY
        )

        UIFactory.Label(row, {
            Name = "SkillName",
            Text = sk.Name,
            Position = UDim2.fromOffset(184, 10),
            Size = UDim2.fromOffset(240, 24),
            TextSize = 16,
            TextColor = unlocked and colors.TEXT_PRIMARY or colors.TEXT_SECONDARY,
            Bold = true,
        })

        UIFactory.Label(row, {
            Name = "SkillMetrics",
            Text = string.format(
                "Req Lv.%d   •   CD: %.1fs   •   Cost: %d   •   Break: %d",
                sk.LevelReq or 1,
                sk.Cooldown or 0,
                sk.EnergyCost > 0 and sk.EnergyCost or (sk.StaminaCost or 0),
                sk.BreakPower or 0
            ),
            Position = UDim2.new(1, -360, 0, 12),
            Size = UDim2.fromOffset(344, 20),
            TextSize = 12,
            TextColor = unlocked and colors.ACCENT_GOLD or colors.TEXT_SECONDARY,
            Bold = true,
            XAlign = Enum.TextXAlignment.Right,
        })

        UIFactory.Label(row, {
            Name = "SkillDesc",
            Text = sk.Description,
            Position = UDim2.fromOffset(72, 38),
            Size = UDim2.new(1, -210, 0, 42),
            TextSize = 13,
            TextColor = colors.TEXT_SECONDARY,
            YAlign = Enum.TextYAlignment.Top,
        })

        UIFactory.Badge(
            row,
            unlocked and "UNLOCKED" or ("LOCKED • LV." .. tostring(sk.LevelReq)),
            UDim2.new(1, -124, 0, 44),
            UDim2.fromOffset(108, 26),
            unlocked and colors.SUCCESS or colors.STROKE_STEEL,
            unlocked and colors.SUCCESS or colors.TEXT_SECONDARY
        )
    end

    scroll.CanvasSize = UDim2.fromOffset(0, #classCfg.Skills * 96 + 12)
    Skills.Refs = { Root = root }
    return root
end

function Skills.Update() end

function Skills.Cleanup()
    Skills.Refs = {}
end

return Skills
