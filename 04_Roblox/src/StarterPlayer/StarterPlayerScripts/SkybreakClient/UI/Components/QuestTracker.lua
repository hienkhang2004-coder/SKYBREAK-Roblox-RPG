-- SKYBREAK: Fragments of the Core — Collapsible HUD Quest Tracker Component
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Components/QuestTracker.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))

local QuestTracker = {}

function QuestTracker.Create(parent, props)
    props = props or {}
    local colors = Theme.Colors
    local collapsed = props.collapsed == true

    local card = UIFactory.Create("Frame", parent, {
        Name = props.name or "QuestTracker",
        Position = props.position or UDim2.fromOffset(18, 172),
        Size = props.size or UDim2.fromOffset(310, 178),
        BackgroundColor3 = colors.BG_800,
        BackgroundTransparency = Theme.Transparency.HUDCard,
        BorderSizePixel = 0,
        ZIndex = props.zIndex or 4,
    })
    UIFactory.Corner(card, Theme.Radius.Medium)
    UIFactory.Stroke(card, colors.STROKE_STEEL, 1.2, 0.32)
    UIFactory.Gradient(card, colors.BG_700, colors.BG_900, 90)

    local headerBar = UIFactory.Create("Frame", card, {
        Name = "Header",
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundTransparency = 1,
        ZIndex = card.ZIndex + 1,
    })

    UIFactory.Icon(headerBar, "Quest", UDim2.fromOffset(10, 6), 22, colors.ACCENT_GOLD)

    UIFactory.Label(headerBar, {
        Name = "HeaderTitle",
        Text = "ACTIVE QUEST",
        Position = UDim2.fromOffset(36, 0),
        Size = UDim2.new(1, -110, 1, 0),
        TextSize = 12,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
        ZIndex = card.ZIndex + 2,
    })

    local journalBtn = UIFactory.Create("TextButton", headerBar, {
        Name = "OpenJournalButton",
        Text = "[J]",
        Position = UDim2.new(1, -68, 0, 5),
        Size = UDim2.fromOffset(30, 24),
        BackgroundColor3 = colors.BG_700,
        BorderSizePixel = 0,
        Font = Theme.Fonts.Bold,
        TextSize = 11,
        TextColor3 = colors.ACCENT_SAPPHIRE,
        AutoButtonColor = false,
        ZIndex = card.ZIndex + 3,
    })
    UIFactory.Corner(journalBtn, 4)

    local collapseBtn = UIFactory.Create("TextButton", headerBar, {
        Name = "CollapseButton",
        Text = collapsed and "+" or "−",
        Position = UDim2.new(1, -32, 0, 5),
        Size = UDim2.fromOffset(24, 24),
        BackgroundColor3 = colors.BG_700,
        BorderSizePixel = 0,
        Font = Theme.Fonts.Bold,
        TextSize = 15,
        TextColor3 = colors.TEXT_PRIMARY,
        AutoButtonColor = false,
        ZIndex = card.ZIndex + 3,
    })
    UIFactory.Corner(collapseBtn, 4)

    local body = UIFactory.Create("Frame", card, {
        Name = "Body",
        Position = UDim2.fromOffset(12, 36),
        Size = UDim2.new(1, -24, 1, -44),
        BackgroundTransparency = 1,
        Visible = not collapsed,
        ZIndex = card.ZIndex + 1,
    })

    local questTitle = UIFactory.Label(body, {
        Name = "Name",
        Text = "Q01 • Lời gọi Skyborn",
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.new(1, 0, 0, 24),
        TextSize = 15,
        TextColor = colors.TEXT_PRIMARY,
        Bold = true,
        ZIndex = card.ZIndex + 2,
    })

    local objectivesLabel = UIFactory.Label(body, {
        Name = "Objectives",
        Text = "",
        Position = UDim2.fromOffset(0, 28),
        Size = UDim2.new(1, 0, 1, -28),
        TextSize = 13,
        TextColor = colors.TEXT_SECONDARY,
        YAlign = Enum.TextYAlignment.Top,
        RichText = true,
        ZIndex = card.ZIndex + 2,
    })

    local function applyCollapse()
        body.Visible = not collapsed
        collapseBtn.Text = collapsed and "+" or "−"
        local baseW = (props.size and props.size.X.Offset) or 310
        local baseH = (props.size and props.size.Y.Offset) or 178
        card.Size = UDim2.fromOffset(baseW, collapsed and 36 or baseH)
    end

    collapseBtn.Activated:Connect(function()
        collapsed = not collapsed
        applyCollapse()
        if type(props.onToggleCollapse) == "function" then
            props.onToggleCollapse(collapsed)
        end
    end)

    journalBtn.Activated:Connect(function()
        if type(props.onOpenJournal) == "function" then
            props.onOpenJournal()
        end
    end)

    local api = {
        Instance = card,
        QuestTitle = questTitle,
        ObjectivesLabel = objectivesLabel,
    }

    function api:Update(questState)
        questState = questState or {}
        if questState.collapsed ~= nil then
            collapsed = questState.collapsed == true
            applyCollapse()
        end

        local q = questState.activeQuest or questState
        if not q or not q.name then
            questTitle.Text = "Chapter I Complete"
            objectivesLabel.Text = "Core of Light recovered. Proceed to the Frozen Cyber portal."
            return
        end

        questTitle.Text = (q.activeId and (q.activeId .. " • ") or "") .. tostring(q.name)
        if q.accepted == false then
            objectivesLabel.Text = "<font color='#E4B863'>Speak with Lyra at the Sky Hub to accept this quest.</font>"
            return
        end

        local lines = {}
        for _, obj in ipairs(q.objectives or {}) do
            local cur = tonumber(obj.current or obj.Count) or 0
            local tgt = math.max(1, tonumber(obj.target or obj.Goal) or 1)
            local done = cur >= tgt
            local prefix = done and "<font color='#5ED79E'>✓</font> " or "<font color='#40AAFF'>○</font> "
            table.insert(lines, string.format("%s%s  <b>%d / %d</b>", prefix, obj.label or obj.Label or "Objective", cur, tgt))
        end
        objectivesLabel.Text = #lines > 0 and table.concat(lines, "\n") or (q.text or "")
    end

    function api:Destroy()
        if card and card.Parent then
            card:Destroy()
        end
    end

    applyCollapse()
    return card, api
end

QuestTracker.create = QuestTracker.Create

return QuestTracker
