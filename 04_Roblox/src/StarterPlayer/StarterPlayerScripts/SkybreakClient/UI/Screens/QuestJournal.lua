-- SKYBREAK: Fragments of the Core — Quest Journal Screen (Phase 4)
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/QuestJournal.lua
-- Categories: Main / Side / Daily / Boss Hunt. Synchronizes directly with HUD QuestTracker.

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
local QuestController = require(script.Parent.Parent:WaitForChild("Controllers"):WaitForChild("QuestController"))

local QuestJournal = {
    Refs = {},
}

function QuestJournal.Build(parent)
    QuestJournal.Cleanup()
    local colors = Theme.Colors
    local snap = Store.GetSnapshot()
    local view = Store.GetView()
    local activeCat = view.selectedQuestCategory or "Main"
    local selectedId = view.selectedQuestId or (snap.quest and snap.quest.activeId) or "Q01"

    local root = UIFactory.Create("Frame", parent, {
        Name = "QuestJournalScreen",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 2,
    })

    -- Header
    local header = PremiumPanel.Create(root, {
        name = "TopHeader",
        position = UDim2.fromOffset(20, 14),
        size = UDim2.new(1, -40, 0, 58),
    })
    UIFactory.Label(header, {
        Name = "Brand",
        Text = "SKY<font color='#F0F4FA'>BREAK</font>  •  QUEST JOURNAL & CHRONICLES",
        Position = UDim2.fromOffset(18, 0),
        Size = UDim2.fromOffset(520, 58),
        TextSize = 19,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
        RichText = true,
    })
    PremiumButton.Create(header, {
        name = "CloseButton",
        label = "BACK TO HUD [J]",
        variant = "secondary",
        position = UDim2.new(1, -172, 0, 10),
        size = UDim2.fromOffset(156, 38),
        textSize = 12,
        onActivated = function()
            ScreenRouter.Navigate(UIState.Screens.HUD)
        end,
    })

    -- Left Quest List Panel (42% width)
    local listPanel = PremiumPanel.Create(root, {
        name = "QuestListPanel",
        title = "QUEST ARCHIVE",
        position = UDim2.fromOffset(20, 84),
        size = UDim2.new(0.42, -16, 1, -102),
    })

    local catTabs = UIFactory.Create("Frame", listPanel, {
        Name = "CategoryTabs",
        Position = UDim2.fromOffset(14, 48),
        Size = UDim2.new(1, -28, 0, 34),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(catTabs, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    local categories = {
        { id = "Main", label = "MAIN STORY" },
        { id = "Side", label = "SIDE" },
        { id = "Daily", label = "DAILY" },
        { id = "BossHunt", label = "BOSS HUNTS" },
    }
    for idx, cat in ipairs(categories) do
        PremiumButton.Create(catTabs, {
            name = "Cat_" .. cat.id,
            label = cat.label,
            variant = (activeCat == cat.id) and "primary" or "secondary",
            selected = (activeCat == cat.id),
            size = UDim2.fromOffset(118, 32),
            textSize = 11,
            layoutOrder = idx,
            onActivated = function()
                local filtered = QuestController.GetQuestsByCategory(cat.id)
                local firstId = filtered[1] and filtered[1].config.Id or selectedId
                Store.SetView({
                    selectedQuestCategory = cat.id,
                    selectedQuestId = firstId,
                })
                ScreenRouter.Navigate(UIState.Screens.QuestJournal, { forceRebuild = true, replace = true })
            end,
        })
    end

    local questScroll = UIFactory.Create("ScrollingFrame", listPanel, {
        Name = "QuestScroll",
        Position = UDim2.fromOffset(14, 92),
        Size = UDim2.new(1, -28, 1, -106),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 5,
        ScrollBarImageColor3 = colors.ACCENT_SAPPHIRE,
    })
    UIFactory.ListLayout(questScroll, Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top)

    local questsInCat = QuestController.GetQuestsByCategory(activeCat)
    local selectedQuestEntry = questsInCat[1]

    for idx, entry in ipairs(questsInCat) do
        local q = entry.config
        if q.Id == selectedId then
            selectedQuestEntry = entry
        end
        local isSelected = (q.Id == selectedId)
        local badgeText = entry.isTracked and "TRACKING" or string.upper(entry.status)

        local btn, _ = PremiumButton.Create(questScroll, {
            name = "QuestItem_" .. q.Id,
            label = string.format("%s  •  %s  [%s]", q.Id, q.Name, badgeText),
            variant = isSelected and "primary" or "secondary",
            selected = isSelected,
            size = UDim2.new(1, -8, 0, 52),
            textSize = 13,
            layoutOrder = idx,
            onActivated = function()
                Store.SetView({ selectedQuestId = q.Id })
                ScreenRouter.Navigate(UIState.Screens.QuestJournal, { forceRebuild = true, replace = true })
            end,
        })
        btn.LayoutOrder = idx
    end
    questScroll.CanvasSize = UDim2.fromOffset(0, #questsInCat * 60 + 12)

    -- Right Quest Inspector Panel (58% width)
    local detailPanel = PremiumPanel.Create(root, {
        name = "QuestJournal",
        variant = "gold",
        title = selectedQuestEntry and (selectedQuestEntry.config.Id .. " • " .. string.upper(selectedQuestEntry.config.Name)) or "SELECT A QUEST",
        subtitle = selectedQuestEntry and string.format("Realm: %s  •  Recommended Level: %d", selectedQuestEntry.config.RealmId, selectedQuestEntry.config.LevelReq or 1) or "",
        position = UDim2.new(0.42, 16, 0, 84),
        size = UDim2.new(0.58, -36, 1, -102),
    })

    if selectedQuestEntry then
        local q = selectedQuestEntry.config
        local objLines = {}
        local isLiveActive = (snap.quest and snap.quest.activeId == q.Id)
        if isLiveActive and snap.quest.objectives then
            for _, o in ipairs(snap.quest.objectives) do
                local done = (o.current or 0) >= (o.target or 1)
                table.insert(objLines, string.format("%s %s   <b>%d / %d</b>", done and "✓" or "○", o.label, o.current or 0, o.target or 1))
            end
        else
            for _, o in ipairs(q.Objectives or {}) do
                table.insert(objLines, string.format("○ %s   <b>0 / %d</b>", o.Label, o.Target or 1))
            end
        end

        local rewards = q.Rewards or {}
        local rewardParts = {}
        if (rewards.EXP or 0) > 0 then
            table.insert(rewardParts, "+" .. UIFactory.FormatNumber(rewards.EXP) .. " EXP")
        end
        if (rewards.Gold or 0) > 0 then
            table.insert(rewardParts, "+" .. UIFactory.FormatNumber(rewards.Gold) .. " Gold")
        end
        if (rewards.CoreShards or 0) > 0 then
            table.insert(rewardParts, "+" .. UIFactory.FormatNumber(rewards.CoreShards) .. " Core Shards")
        end
        for _, itemReward in ipairs(rewards.Items or {}) do
            table.insert(rewardParts, string.format("%s x%d", itemReward.Id, itemReward.Count or 1))
        end

        UIFactory.Label(detailPanel, {
            Name = "Content",
            Text = string.format(
                "%s\n\n<font color='#E4B863'><b>OBJECTIVES</b></font>\n%s\n\n<font color='#40AAFF'><b>COMPLETION REWARDS (SERVER GRANTED)</b></font>\n%s",
                q.Description or "",
                table.concat(objLines, "\n"),
                table.concat(rewardParts, "   •   ")
            ),
            Position = UDim2.fromOffset(18, 72),
            Size = UDim2.new(1, -36, 1, -152),
            TextSize = 15,
            TextColor = colors.TEXT_PRIMARY,
            YAlign = Enum.TextYAlignment.Top,
            RichText = true,
        })

        PremiumButton.Create(detailPanel, {
            name = "TrackQuestButton",
            label = selectedQuestEntry.isTracked and "✓  CURRENTLY TRACKED ON HUD" or "TRACK QUEST ON HUD",
            variant = selectedQuestEntry.isTracked and "gold" or "primary",
            position = UDim2.new(0, 18, 1, -64),
            size = UDim2.new(0.54, -24, 0, 44),
            textSize = 13,
            onActivated = function()
                QuestController.TrackQuest(q.Id)
                ScreenRouter.Navigate(UIState.Screens.QuestJournal, { forceRebuild = true, replace = true })
            end,
        })

        PremiumButton.Create(detailPanel, {
            name = "DialoguePreviewButton",
            label = "LORE DIALOGUE",
            variant = "secondary",
            position = UDim2.new(0.54, 6, 1, -64),
            size = UDim2.new(0.46, -24, 0, 44),
            textSize = 13,
            onActivated = function()
                QuestController.OpenDialogue(
                    "LYRA • SKY HUB",
                    q.Description,
                    "Lorekeeper of the Core • " .. q.Id,
                    q.Id
                )
            end,
        })
    end

    QuestJournal.Refs = { Root = root }
    return root
end

function QuestJournal.Update() end

function QuestJournal.Cleanup()
    QuestJournal.Refs = {}
end

return QuestJournal
