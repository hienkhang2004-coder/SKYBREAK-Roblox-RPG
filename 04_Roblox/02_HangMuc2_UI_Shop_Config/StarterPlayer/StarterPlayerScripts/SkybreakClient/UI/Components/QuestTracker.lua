-- SKYBREAK: Fragments of the Core — Collapsible HUD Quest Tracker with Golden Ribbon Banner
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Components/QuestTracker.lua
-- Matches SKYBREAK_Figma_v2_01_ActionRPG_HUD.png 1:1.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local I18n = require(script.Parent.Parent:WaitForChild("I18n"))

local QuestTracker = {}

local function formatCompactGold(goldNum)
    local n = tonumber(goldNum) or 0
    if n <= 0 then
        return "+1.2K G"
    elseif n >= 1000 then
        local k = n / 1000
        if math.abs(k - math.floor(k)) < 0.05 then
            return string.format("+%dK G", math.floor(k))
        end
        return string.format("+%.1fK G", k)
    end
    return string.format("+%d G", math.floor(n))
end

function QuestTracker.Create(parent, props)
    props = props or {}
    local colors = Theme.Colors
    local collapsed = props.collapsed == true
    local baseW = (props.size and props.size.X.Offset > 0 and props.size.X.Offset) or 314
    local baseH = 122
    local baseZ = props.zIndex or 5

    -- Outer wrapper with ClipsDescendants = false so the Golden Ribbon Banner sits cleanly atop the obsidian card
    local wrapper = UIFactory.Create("Frame", parent, {
        Name = props.name or "QuestTracker",
        Position = props.position or UDim2.fromOffset(16, 178),
        Size = UDim2.fromOffset(baseW, baseH),
        BackgroundTransparency = 1,
        ClipsDescendants = false,
        ZIndex = baseZ,
    })

    -- Obsidian Glass Card Body (starts at y = 14 so Golden Ribbon overlaps its top edge cleanly)
    local card = UIFactory.Create("Frame", wrapper, {
        Name = "QuestCardBody",
        Position = UDim2.fromOffset(0, 14),
        Size = UDim2.fromOffset(baseW, baseH - 14),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Visible = not collapsed,
        ZIndex = baseZ,
    })
    UIFactory.Corner(card, 11)
    UIFactory.Stroke(card, Color3.fromRGB(58, 102, 158), 1.5, 0.16)
    UIFactory.Gradient(card, Color3.fromRGB(18, 30, 54), Color3.fromRGB(9, 15, 29), 90)

    -- Subtle inner sapphire corner brackets matching Figma HUD Quest Card
    for idx, c in ipairs({
        { ax = 0, ay = 1, px = 4, py = -4 },
        { ax = 1, ay = 1, px = -4, py = -4 },
    }) do
        UIFactory.Create("Frame", card, {
            Name = "CornerH_" .. idx,
            AnchorPoint = Vector2.new(c.ax, c.ay),
            Position = UDim2.new(c.ax, c.px, c.ay, c.py),
            Size = UDim2.fromOffset(10, 2),
            BackgroundColor3 = Color3.fromRGB(86, 172, 248),
            BackgroundTransparency = 0.25,
            BorderSizePixel = 0,
            ZIndex = baseZ + 1,
        })
        UIFactory.Create("Frame", card, {
            Name = "CornerV_" .. idx,
            AnchorPoint = Vector2.new(c.ax, c.ay),
            Position = UDim2.new(c.ax, c.px, c.ay, c.py),
            Size = UDim2.fromOffset(2, 10),
            BackgroundColor3 = Color3.fromRGB(86, 172, 248),
            BackgroundTransparency = 0.25,
            BorderSizePixel = 0,
            ZIndex = baseZ + 1,
        })
    end

    -- Top Golden Ribbon Header Banner ("NHẬT KÝ NHIỆM VỤ" + dark "[L]" pill)
    local _, ribbonRefs = UIFactory.RibbonBanner(wrapper, {
        name = "GoldenQuestRibbon",
        variant = "gold",
        icon = "Quest",
        iconSize = 15,
        title = I18n.T("quest.tracker_header"),
        textSize = 11,
        badgeText = "[L]",
        badgeWidth = 32,
        onBadgeActivated = function()
            if type(props.onOpenJournal) == "function" then
                props.onOpenJournal()
            end
        end,
        position = UDim2.fromOffset(0, 0),
        size = UDim2.fromOffset(baseW - 38, 28),
        zIndex = baseZ + 4,
    })

    -- Collapse [-] / [+] button beside the Golden Ribbon Banner
    local collapseBtn = UIFactory.Create("TextButton", wrapper, {
        Name = "CollapseButton",
        Text = collapsed and "+" or "-",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -2, 0, 2),
        Size = UDim2.fromOffset(26, 24),
        BackgroundColor3 = Color3.fromRGB(14, 23, 42),
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        Font = Theme.Fonts.Bold,
        TextSize = 15,
        TextColor3 = colors.TEXT_PRIMARY,
        AutoButtonColor = false,
        ZIndex = baseZ + 5,
    })
    UIFactory.Corner(collapseBtn, 6)
    UIFactory.Stroke(collapseBtn, Color3.fromRGB(76, 114, 168), 1.3, 0.20)

    -- Quest Title Line (Champagne Gold bold)
    local questTitle = UIFactory.Label(card, {
        Name = "Name",
        Text = "Q01 • Lời Gọi Skyborn",
        Position = UDim2.fromOffset(12, 20),
        Size = UDim2.new(1, -24, 0, 20),
        TextSize = 13,
        TextColor = Color3.fromRGB(248, 209, 104),
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = baseZ + 2,
    })

    -- Gold Diamond Objective Bullet (Zero Unicode tofu!)
    local diamondBullet = UIFactory.Create("Frame", card, {
        Name = "ObjectiveDiamond",
        Position = UDim2.fromOffset(14, 47),
        Size = UDim2.fromOffset(6, 6),
        Rotation = 45,
        BackgroundColor3 = colors.ACCENT_GOLD_BRIGHT,
        BorderSizePixel = 0,
        ZIndex = baseZ + 2,
    })
    UIFactory.Corner(diamondBullet, 1)

    local objectivesLabel = UIFactory.Label(card, {
        Name = "Objectives",
        Text = "",
        Position = UDim2.fromOffset(26, 42),
        Size = UDim2.new(1, -38, 0, 32),
        TextSize = 11,
        TextColor = Color3.fromRGB(232, 240, 252),
        YAlign = Enum.TextYAlignment.Top,
        RichText = true,
        ZIndex = baseZ + 2,
    })

    -- Bottom Row: Glossy Sapphire Progress Bar ("2 / 3") + Gold Reward Pill ("+1.2K G")
    local progTrack = UIFactory.Create("Frame", card, {
        Name = "QuestProgressBar",
        Position = UDim2.new(0, 12, 1, -26),
        Size = UDim2.new(1, -86, 0, 16),
        BackgroundColor3 = Color3.fromRGB(8, 13, 25),
        BackgroundTransparency = 0.06,
        BorderSizePixel = 0,
        ZIndex = baseZ + 2,
    })
    UIFactory.PillCorner(progTrack)
    UIFactory.Stroke(progTrack, Color3.fromRGB(64, 114, 174), 1, 0.32)

    local progFill = UIFactory.Create("Frame", progTrack, {
        Name = "Fill",
        Size = UDim2.fromScale(0.66, 1),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = baseZ + 3,
    })
    UIFactory.PillCorner(progFill)
    UIFactory.Gradient(progFill, Color3.fromRGB(88, 208, 255), Color3.fromRGB(29, 98, 224), 0)

    local progText = UIFactory.Label(progTrack, {
        Name = "ProgressText",
        Text = "0 / 1",
        Size = UDim2.fromScale(1, 1),
        TextSize = 10,
        TextColor = Color3.fromRGB(248, 252, 255),
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Wrapped = false,
        ZIndex = baseZ + 4,
    })

    local rewardPill = UIFactory.Create("Frame", card, {
        Name = "RewardPill",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 1, -27),
        Size = UDim2.fromOffset(60, 18),
        BackgroundColor3 = Color3.fromRGB(16, 20, 32),
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        ZIndex = baseZ + 2,
    })
    UIFactory.Corner(rewardPill, 5)
    UIFactory.Stroke(rewardPill, colors.ACCENT_GOLD, 1.2, 0.18)

    local rewardText = UIFactory.Label(rewardPill, {
        Name = "RewardLabel",
        Text = "+1.2K G",
        Size = UDim2.fromScale(1, 1),
        TextSize = 10,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Wrapped = false,
        ZIndex = baseZ + 3,
    })

    local function applyCollapse()
        card.Visible = not collapsed
        collapseBtn.Text = collapsed and "+" or "-"
        wrapper.Size = UDim2.fromOffset(baseW, collapsed and 30 or baseH)
    end

    collapseBtn.Activated:Connect(function()
        collapsed = not collapsed
        applyCollapse()
        if type(props.onToggleCollapse) == "function" then
            props.onToggleCollapse(collapsed)
        end
    end)

    local api = {
        Instance = wrapper,
        QuestTitle = questTitle,
        ObjectivesLabel = objectivesLabel,
    }

    function api:Update(questState)
        questState = questState or {}
        ribbonRefs.SetTitle(I18n.T("quest.tracker_header"))
        if questState.collapsed ~= nil then
            collapsed = questState.collapsed == true
            applyCollapse()
        end

        local q = questState.activeQuest or questState
        if not q or not q.name then
            questTitle.Text = I18n.Pick("Chương I Hoàn Tất", "Chapter I Complete")
            objectivesLabel.Text = I18n.Pick(
                "Đã thu hồi Core of Light. Tiến tới cổng Frozen Cyber [M].",
                "Core of Light recovered. Proceed to Frozen Cyber [M]."
            )
            progFill.Size = UDim2.fromScale(1, 1)
            progText.Text = "DONE"
            rewardText.Text = "+MAX"
            return
        end

        questTitle.Text = (q.activeId and (q.activeId .. " • ") or "") .. tostring(q.name)
        rewardText.Text = formatCompactGold(q.rewardGold or (q.rewards and q.rewards.gold) or 1200)

        if q.accepted == false then
            objectivesLabel.Text = I18n.Pick(
                "Gặp Lyra tại Sky Hub để nhận nhiệm vụ này.",
                "Speak with Lyra at the Sky Hub to accept this quest."
            )
            progFill.Size = UDim2.fromScale(0, 1)
            progText.Text = "0 / 1"
            return
        end

        local objs = q.objectives or {}
        if #objs > 0 then
            local first = objs[1]
            local cur = tonumber(first.current or first.Count) or 0
            local tgt = math.max(1, tonumber(first.target or first.Goal) or 1)
            local ratio = math.clamp(cur / tgt, 0, 1)
            progFill.Size = UDim2.fromScale(ratio, 1)
            progText.Text = string.format("%d / %d", cur, tgt)

            local lines = {}
            for idx, obj in ipairs(objs) do
                if idx <= 2 then
                    local lbl = tostring(obj.label or obj.Label or "Objective")
                    if idx == 1 then
                        table.insert(lines, lbl)
                    else
                        local c2 = tonumber(obj.current or obj.Count) or 0
                        local t2 = math.max(1, tonumber(obj.target or obj.Goal) or 1)
                        table.insert(lines, string.format("%s (%d/%d)", lbl, c2, t2))
                    end
                end
            end
            objectivesLabel.Text = table.concat(lines, "\n")
        else
            objectivesLabel.Text = tostring(q.text or "")
            progFill.Size = UDim2.fromScale(0.5, 1)
            progText.Text = "1 / 1"
        end
    end

    function api:Destroy()
        if wrapper and wrapper.Parent then
            wrapper:Destroy()
        end
    end

    applyCollapse()
    return wrapper, api
end

QuestTracker.create = QuestTracker.Create

return QuestTracker
