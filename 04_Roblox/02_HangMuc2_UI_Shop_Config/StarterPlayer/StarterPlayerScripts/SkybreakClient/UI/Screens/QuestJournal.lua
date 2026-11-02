-- SKYBREAK: Fragments of the Core — Quest Journal & Commander Lyra 3D Quick-Repeat Board ([L])
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/QuestJournal.lua
-- Matches Figma File 3 (SKYBREAK_NPC_05_Quests_Trading_Colosseum.png - NPC 9 Quick-Repeat Board) 1:1.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local UIState = require(Shared:WaitForChild("Types"):WaitForChild("UIState"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Store = require(script.Parent.Parent:WaitForChild("Store"))
local ScreenRouter = require(script.Parent.Parent:WaitForChild("ScreenRouter"))
local I18n = require(script.Parent.Parent:WaitForChild("I18n"))
local PremiumPanel = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumPanel"))
local PremiumButton = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumButton"))
local StatBar = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("StatBar"))
local QuestController = require(script.Parent.Parent:WaitForChild("Controllers"):WaitForChild("QuestController"))

local QuestJournal = {
    Refs = {},
    BustConn = nil,
}

local function buildCommanderLyra3DBust(parent, pos, size)
    local colors = Theme.Colors
    local frame = UIFactory.Create("Frame", parent, {
        Name = "Lyra3DBustCard",
        Position = pos,
        Size = size,
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
        ZIndex = 5,
    })
    UIFactory.Corner(frame, Theme.Radius.Medium)
    UIFactory.Stroke(frame, colors.ACCENT_GOLD_BRIGHT, 1.8, 0.08)
    UIFactory.Gradient(frame, Color3.fromRGB(36, 54, 88), colors.BG_900, 135)

    local aura = UIFactory.Create("Frame", frame, {
        Name = "RadialAura",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.45),
        Size = UDim2.fromOffset(72, 72),
        BackgroundColor3 = colors.ACCENT_GOLD,
        BackgroundTransparency = 0.78,
        BorderSizePixel = 0,
        ZIndex = 6,
    })
    UIFactory.PillCorner(aura)

    local vp = UIFactory.Create("ViewportFrame", frame, {
        Name = "LyraViewport",
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.new(1, -4, 1, -14),
        BackgroundTransparency = 1,
        Ambient = Color3.fromRGB(196, 208, 232),
        LightColor = Color3.fromRGB(255, 244, 214),
        LightDirection = Vector3.new(-0.4, -0.6, -0.85),
        ZIndex = 7,
    })
    local cam = Instance.new("Camera")
    cam.FieldOfView = 24
    cam.Parent = vp
    vp.CurrentCamera = cam

    local wm = Instance.new("WorldModel")
    wm.Parent = vp

    local m = Instance.new("Model")
    m.Name = "CommanderLyraBust"
    local function mkPart(name, sz, col, mat, cf)
        local p = Instance.new("Part")
        p.Name = name
        p.Size = sz
        p.Color = col
        p.Material = mat or Enum.Material.SmoothPlastic
        p.Anchored = true
        p.CanCollide = false
        p.CFrame = cf
        p.Parent = m
        return p
    end

    mkPart("Torso", Vector3.new(1.78, 1.72, 0.92), Color3.fromRGB(26, 52, 92), Enum.Material.SmoothPlastic, CFrame.new(0, 0, 0))
    mkPart("CoreGem", Vector3.new(0.42, 0.42, 0.14), Color3.fromRGB(88, 224, 255), Enum.Material.Neon, CFrame.new(0, 0.25, -0.46) * CFrame.Angles(0, 0, math.rad(45)))
    for _, side in ipairs({ -1, 1 }) do
        local pld = mkPart("Pauldron_" .. side, Vector3.new(0.76, 0.52, 1.04), colors.ACCENT_GOLD, Enum.Material.Metal, CFrame.new(side * 1.12, 0.58, 0) * CFrame.Angles(0, 0, math.rad(-side * 16)))
        pld.Reflectance = 0.25
    end
    local head = mkPart("Head", Vector3.new(1.16, 1.16, 1.16), Color3.fromRGB(242, 214, 190), Enum.Material.SmoothPlastic, CFrame.new(0, 1.56, 0))
    Instance.new("SpecialMesh", head).MeshType = Enum.MeshType.Head
    mkPart("Hair", Vector3.new(1.26, 0.58, 1.24), Color3.fromRGB(238, 244, 255), Enum.Material.SmoothPlastic, CFrame.new(0, 1.98, 0.08))
    for _, side in ipairs({ -1, 1 }) do
        mkPart("Eye_" .. side, Vector3.new(0.14, 0.08, 0.08), Color3.fromRGB(28, 42, 68), Enum.Material.SmoothPlastic, CFrame.new(side * 0.22, 1.62, -0.55))
        local wing = Instance.new("WedgePart")
        wing.Size = Vector3.new(0.14, 0.56, 0.28)
        wing.Color = colors.ACCENT_GOLD_BRIGHT
        wing.Material = Enum.Material.Neon
        wing.Anchored = true
        wing.CanCollide = false
        wing.CFrame = CFrame.new(side * 0.66, 2.02, -0.06) * CFrame.Angles(-0.15, 0, -side * 0.42)
        wing.Parent = m
    end
    m.Parent = wm

    local pill = UIFactory.Create("Frame", frame, {
        Name = "LiveTagPill",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -4),
        Size = UDim2.new(1, -10, 0, 18),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
        ZIndex = 9,
    })
    UIFactory.PillCorner(pill)
    UIFactory.Stroke(pill, colors.ACCENT_GOLD, 1.2, 0.15)
    UIFactory.Label(pill, {
        Name = "LiveTag",
        Text = "• 3D LIVE - CHỈ HUY",
        Size = UDim2.fromScale(1, 1),
        TextSize = 8,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Wrapped = false,
        ZIndex = 10,
    })

    local t0 = os.clock()
    local acc = 0
    local conn = RunService.RenderStepped:Connect(function(dt)
        if not frame.Parent then
            return
        end
        acc += dt
        if acc < 0.033 then
            return
        end
        acc = 0
        local t = os.clock() - t0
        local yaw = math.sin(t * 0.95) * 0.10
        local bob = math.sin(t * 2.1) * 0.035
        local focus = Vector3.new(0, 1.28 + bob * 0.4, 0)
        local cpos = focus + Vector3.new(math.sin(yaw) * 4.9, 0.14 + bob, -math.cos(yaw) * 4.9)
        cam.CFrame = CFrame.lookAt(cpos, focus)
    end)

    return frame, conn
end

local function formatRewardSummary(rewards)
    rewards = rewards or {}
    local parts = {}
    if (rewards.EXP or 0) > 0 then
        table.insert(parts, "+" .. UIFactory.FormatNumber(rewards.EXP) .. " EXP")
    end
    if (rewards.Gold or 0) > 0 then
        table.insert(parts, "+" .. UIFactory.FormatNumber(rewards.Gold) .. " Gold")
    end
    if (rewards.CoreShards or 0) > 0 then
        table.insert(parts, "+" .. UIFactory.FormatNumber(rewards.CoreShards) .. " Shards")
    end
    for _, itemReward in ipairs(rewards.Items or {}) do
        table.insert(parts, string.format("%s x%d", itemReward.Id, itemReward.Count or 1))
    end
    return #parts > 0 and table.concat(parts, " • ") or "+EXP • +Gold"
end

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

    local _, headerRefs = UIFactory.BuildScreenHeader(root, {
        ActiveScreen = UIState.Screens.QuestJournal,
        Title = I18n.T("quests.title"),
        Snapshot = snap,
        OnNavigate = function(targetId)
            ScreenRouter.Navigate(targetId)
        end,
        OnClose = function()
            ScreenRouter.CloseAllToHUD()
        end,
    })

    -- Left Panel (55% width): Commander Lyra 3D Quick-Repeat Board (Figma SKYBREAK_NPC_05 Left Panel)
    local listPanel = PremiumPanel.Create(root, {
        name = "QuestListPanel",
        variant = "gold",
        title = I18n.Pick("CHỈ HUY LYRA & BẢNG NHIỆM VỤ ĐẢO [L]", "COMMANDER LYRA & QUICK-REPEAT QUEST BOARD [L]"),
        position = UDim2.fromOffset(16, 74),
        size = UDim2.new(0.55, -12, 1, -88),
    })

    -- Top Hero Commander Lyra 3D Card
    local heroBox = UIFactory.Create("Frame", listPanel, {
        Name = "LyraHeroHeader",
        Position = UDim2.fromOffset(14, 48),
        Size = UDim2.new(1, -28, 0, 118),
        BackgroundColor3 = colors.BG_900,
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        ZIndex = 4,
    })
    UIFactory.Corner(heroBox, Theme.Radius.Medium)
    UIFactory.Stroke(heroBox, colors.ACCENT_GOLD, 1.4, 0.18)

    local _, bustConn = buildCommanderLyra3DBust(heroBox, UDim2.fromOffset(10, 8), UDim2.fromOffset(92, 102))
    QuestJournal.BustConn = bustConn

    UIFactory.Label(heroBox, {
        Name = "LyraTitle",
        Text = I18n.Pick("LYRA • CHỈ HUY TỐI CAO LIÊN MINH SKYBORN", "LYRA • SUPREME SKYBORN COMMANDER"),
        Position = UDim2.fromOffset(114, 8),
        Size = UDim2.new(1, -126, 0, 20),
        TextSize = 13,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = 5,
    })

    UIFactory.Label(heroBox, {
        Name = "LyraQuote",
        Text = I18n.Pick(
            "\"Hạt nhân Thiên Giới đang rạn nứt! Chọn nhiệm vụ bãi quái hoặc săn Boss để nhận EXP đột phá. Bật [Tự Lặp Nhiệm Vụ] để farm cực mượt!\"",
            "\"The Sky Core fractures! Pick an island patrol or Boss hunt for massive EXP & Gold. Toggle [1-Click Auto-Repeat] for seamless farming!\""
        ),
        Position = UDim2.fromOffset(114, 29),
        Size = UDim2.new(1, -126, 0, 36),
        TextSize = 11,
        TextColor = colors.TEXT_SECONDARY,
        YAlign = Enum.TextYAlignment.Top,
        ZIndex = 5,
    })

    local autoRepeatOn = Store.Session.autoRepeatQuest == true
    PremiumButton.Create(heroBox, {
        name = "TopAutoRepeatBtn",
        icon = "Bolt",
        label = autoRepeatOn
            and I18n.Pick("TỰ LẶP LẠI NHIỆM VỤ 1-CLICK: BẬT", "1-CLICK AUTO-REPEAT: ON")
            or I18n.Pick("TỰ LẶP LẠI NHIỆM VỤ 1-CLICK: TẮT", "1-CLICK AUTO-REPEAT: OFF"),
        variant = autoRepeatOn and "primary" or "secondary",
        selected = autoRepeatOn,
        position = UDim2.fromOffset(114, 72),
        size = UDim2.new(0.5, -66, 0, 36),
        textSize = 11,
        minTextSize = 8,
        zIndex = 6,
        onActivated = function()
            local nextVal = not (Store.Session.autoRepeatQuest == true)
            Store.Session.autoRepeatQuest = nextVal
            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes and remotes:FindFirstChild("UIRequest") then
                remotes.UIRequest:FireServer("SetAutoRepeatQuest", { enabled = nextVal, questId = selectedId })
            end
            Store.ShowToast(
                nextVal and I18n.Pick("Đã BẬT Tự Lặp Nhiệm Vụ 1-Click!", "Enabled 1-Click Auto-Repeat!")
                    or I18n.Pick("Đã TẮT Tự Lặp Nhiệm Vụ.", "Disabled Auto-Repeat."),
                "info",
                2.0
            )
            ScreenRouter.Navigate(UIState.Screens.QuestJournal, { forceRebuild = true, replace = true })
        end,
    })

    PremiumButton.Create(heroBox, {
        name = "TopCompassBtn",
        icon = "Compass",
        label = I18n.Pick("BẬT LA BÀN DẪN ĐƯỜNG 3D", "3D QUEST COMPASS"),
        variant = "gold",
        position = UDim2.new(0.5, 54, 0, 72),
        size = UDim2.new(0.5, -66, 0, 36),
        textSize = 11,
        minTextSize = 8,
        zIndex = 6,
        onActivated = function()
            QuestController.TrackQuest(selectedId)
            Store.ShowToast(I18n.Pick("Đã bật La Bàn Dẫn Đường 3D tới mục tiêu!", "3D Quest Compass locked onto target!"), "success", 2.0)
            ScreenRouter.Navigate(UIState.Screens.QuestJournal, { forceRebuild = true, replace = true })
        end,
    })

    -- Category Filter Pills
    local catTabs = UIFactory.Create("Frame", listPanel, {
        Name = "CategoryTabs",
        Position = UDim2.fromOffset(14, 174),
        Size = UDim2.new(1, -28, 0, 32),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(catTabs, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    local categories = {
        { id = "Main", label = I18n.Pick("CHÍNH TUYẾN", "MAIN STORY") },
        { id = "Side", label = I18n.Pick("BÃI QUÁI ĐẢO", "ISLAND PATROL") },
        { id = "Daily", label = I18n.Pick("HẰNG NGÀY", "DAILY") },
        { id = "BossHunt", label = I18n.Pick("SĂN BOSS", "BOSS HUNTS") },
    }
    for idx, cat in ipairs(categories) do
        local isAct = (activeCat == cat.id)
        PremiumButton.Create(catTabs, {
            name = "Cat_" .. cat.id,
            label = cat.label,
            variant = isAct and "gold" or "secondary",
            selected = isAct,
            size = UDim2.new(0.25, -5, 0, 30),
            textSize = 11,
            minTextSize = 9,
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

    -- Scrolling Tactile Quest Cards (Figma SKYBREAK_NPC_05 Card Style)
    local questScroll = UIFactory.Create("ScrollingFrame", listPanel, {
        Name = "QuestScroll",
        Position = UDim2.fromOffset(14, 214),
        Size = UDim2.new(1, -28, 1, -226),
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
        local isTracked = entry.isTracked == true
        local isLiveActive = (snap.quest and snap.quest.activeId == q.Id)

        local curProg, maxProg = 0, 1
        local firstObjText = q.Description or ""
        if isLiveActive and snap.quest.objectives and snap.quest.objectives[1] then
            local o = snap.quest.objectives[1]
            curProg = tonumber(o.current) or 0
            maxProg = math.max(1, tonumber(o.target) or 1)
            firstObjText = tostring(o.label or firstObjText)
        elseif q.Objectives and q.Objectives[1] then
            local o = q.Objectives[1]
            curProg = 0
            maxProg = math.max(1, tonumber(o.Target) or 1)
            firstObjText = tostring(o.Label or firstObjText)
        end
        local pct = math.clamp(math.floor((curProg / maxProg) * 100), 0, 100)

        local qCard = UIFactory.Create("TextButton", questScroll, {
            Name = "QuestItem_" .. q.Id,
            Size = UDim2.new(1, -8, 0, 102),
            BackgroundColor3 = colors.BG_900,
            BackgroundTransparency = 0.06,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = idx,
            ZIndex = 4,
        })
        UIFactory.Corner(qCard, Theme.Radius.Medium)
        UIFactory.Stroke(
            qCard,
            (isTracked or isSelected) and colors.ACCENT_GOLD or colors.STROKE_STEEL,
            (isTracked or isSelected) and 1.8 or 1.1,
            (isTracked or isSelected) and 0.08 or 0.35
        )
        UIFactory.Gradient(qCard, colors.BG_700, colors.BG_900, 90)

        UIFactory.Label(qCard, {
            Name = "QTitle",
            Text = string.format("%s • %s (LV. %d+)", q.Id, string.upper(q.Name), tonumber(q.LevelReq) or 1),
            Position = UDim2.fromOffset(12, 7),
            Size = UDim2.new(1, -24, 0, 18),
            TextSize = 12,
            TextColor = (isTracked or isSelected) and colors.ACCENT_GOLD_BRIGHT or colors.TEXT_PRIMARY,
            Bold = true,
            Truncate = Enum.TextTruncate.AtEnd,
            Wrapped = false,
            ZIndex = 5,
        })

        UIFactory.Label(qCard, {
            Name = "QTarget",
            Text = I18n.Pick("Mục tiêu: ", "Target: ") .. firstObjText,
            Position = UDim2.fromOffset(12, 26),
            Size = UDim2.new(1, -24, 0, 16),
            TextSize = 11,
            TextColor = colors.TEXT_PRIMARY,
            Truncate = Enum.TextTruncate.AtEnd,
            Wrapped = false,
            ZIndex = 5,
        })

        UIFactory.Label(qCard, {
            Name = "QReward",
            Text = I18n.Pick("Thưởng: ", "Reward: ") .. formatRewardSummary(q.Rewards),
            Position = UDim2.fromOffset(12, 43),
            Size = UDim2.new(1, -24, 0, 16),
            TextSize = 11,
            TextColor = colors.SUCCESS,
            Bold = true,
            Truncate = Enum.TextTruncate.AtEnd,
            Wrapped = false,
            ZIndex = 5,
        })

        StatBar.Create(qCard, {
            name = "QProgress",
            type = "Energy",
            current = curProg,
            max = maxProg,
            customText = I18n.Pick(
                string.format("TIẾN ĐỘ: %d / %d MỤC TIÊU (%d%%)", curProg, maxProg, pct),
                string.format("PROGRESS: %d / %d (%d%%)", curProg, maxProg, pct)
            ),
            position = UDim2.fromOffset(12, 66),
            size = UDim2.new(0.64, -18, 0, 26),
            textSize = 10,
            zIndex = 5,
        })

        PremiumButton.Create(qCard, {
            name = "QActionBtn",
            label = isTracked
                and I18n.Pick(string.format("ĐANG NHẬN (%d/%d)", curProg, maxProg), string.format("ACTIVE (%d/%d)", curProg, maxProg))
                or I18n.Pick("NHẬN NHIỆM VỤ", "ACCEPT QUEST"),
            variant = isTracked and "primary" or "gold",
            position = UDim2.new(0.64, 4, 0, 64),
            size = UDim2.new(0.36, -16, 0, 30),
            textSize = 11,
            minTextSize = 9,
            zIndex = 6,
            onActivated = function()
                Store.SetView({ selectedQuestId = q.Id })
                QuestController.TrackQuest(q.Id)
                ScreenRouter.Navigate(UIState.Screens.QuestJournal, { forceRebuild = true, replace = true })
            end,
        })

        qCard.Activated:Connect(function()
            Store.SetView({ selectedQuestId = q.Id })
            ScreenRouter.Navigate(UIState.Screens.QuestJournal, { forceRebuild = true, replace = true })
        end)
    end
    questScroll.CanvasSize = UDim2.fromOffset(0, #questsInCat * 110 + 14)

    -- Right Quest Inspector & Expedition Supply Panel (45% width)
    local detailPanel = PremiumPanel.Create(root, {
        name = "QuestJournal",
        variant = "gold",
        title = selectedQuestEntry and (selectedQuestEntry.config.Id .. " • " .. string.upper(selectedQuestEntry.config.Name)) or I18n.Pick("CHỌN NHIỆM VỤ", "SELECT A QUEST"),
        subtitle = selectedQuestEntry
            and string.format(
                "%s: %s  •  %s: Lv.%d",
                I18n.Pick("Khu vực", "Realm"),
                tostring(selectedQuestEntry.config.RealmId or "SkyHub"),
                I18n.Pick("Cấp khuyến nghị", "Recommended"),
                selectedQuestEntry.config.LevelReq or 1
            )
            or "",
        position = UDim2.new(0.55, 10, 0, 74),
        size = UDim2.new(0.45, -26, 1, -88),
    })

    local contentLbl = nil
    local trackBtnApi = nil
    local rewardLineText = ""

    if selectedQuestEntry then
        local q = selectedQuestEntry.config
        local objLines = {}
        local isLiveActive = (snap.quest and snap.quest.activeId == q.Id)
        if isLiveActive and snap.quest.objectives then
            for _, o in ipairs(snap.quest.objectives) do
                local done = (o.current or 0) >= (o.target or 1)
                table.insert(
                    objLines,
                    string.format(
                        "<font color='%s'><b>%s</b></font> %s   <b>%d / %d</b>",
                        done and "#5ED79E" or "#E4B863",
                        done and "[x]" or "[ ]",
                        o.label,
                        o.current or 0,
                        o.target or 1
                    )
                )
            end
        else
            for _, o in ipairs(q.Objectives or {}) do
                table.insert(objLines, string.format("<font color='#A8B9D1'><b>[ ]</b></font> %s   <b>0 / %d</b>", o.Label, o.Target or 1))
            end
        end

        rewardLineText = formatRewardSummary(q.Rewards)

        contentLbl = UIFactory.Label(detailPanel, {
            Name = "Content",
            Text = string.format(
                "%s\n\n<font color='#E4B863'><b>%s</b></font>\n%s\n\n<font color='#5ED79E'><b>%s</b></font>\n%s",
                q.Description or "",
                I18n.Pick("MỤC TIÊU NHIỆM VỤ", "OBJECTIVES"),
                table.concat(objLines, "\n"),
                I18n.Pick("PHẦN THƯỞNG HOÀN THÀNH (SERVER CẤP)", "COMPLETION REWARDS (SERVER GRANTED)"),
                rewardLineText
            ),
            Position = UDim2.fromOffset(18, 68),
            Size = UDim2.new(1, -36, 1, -246),
            TextSize = 13,
            TextColor = colors.TEXT_PRIMARY,
            YAlign = Enum.TextYAlignment.Top,
            RichText = true,
        })

        -- Expedition Supply Crate Box (from SKYBREAK_NPC_05 bottom-left card!)
        local supplyBox = UIFactory.Create("Frame", detailPanel, {
            Name = "ExpeditionSupplyCard",
            Position = UDim2.new(0, 16, 1, -168),
            Size = UDim2.new(1, -32, 0, 96),
            BackgroundColor3 = colors.BG_900,
            BorderSizePixel = 0,
            ZIndex = 4,
        })
        UIFactory.Corner(supplyBox, Theme.Radius.Medium)
        UIFactory.Stroke(supplyBox, colors.ACCENT_SAPPHIRE, 1.3, 0.25)

        UIFactory.Label(supplyBox, {
            Name = "SupplyTitle",
            Text = I18n.Pick("TIẾP TẾ ĐỒNG MINH VIỄN CHINH (MỖI NGÀY)", "ALLIED EXPEDITION SUPPLY CRATE"),
            Position = UDim2.fromOffset(12, 7),
            Size = UDim2.new(1, -24, 0, 18),
            TextSize = 12,
            TextColor = colors.ACCENT_GOLD_BRIGHT,
            Bold = true,
            Wrapped = false,
            ZIndex = 5,
        })
        UIFactory.Label(supplyBox, {
            Name = "SupplyReward",
            Text = I18n.Pick("Thưởng quân nhu: Điểm Danh + Gold + Core Shards + Hồi phục", "Supply Bonus: Daily Gold + Core Shards + Vitality"),
            Position = UDim2.fromOffset(12, 27),
            Size = UDim2.new(1, -24, 0, 16),
            TextSize = 11,
            TextColor = colors.SUCCESS,
            Bold = true,
            Wrapped = false,
            ZIndex = 5,
        })
        PremiumButton.Create(supplyBox, {
            name = "ClaimSupplyBtn",
            icon = "Gold",
            label = I18n.Pick("NHẬN TIẾP TẾ NGAY", "CLAIM SUPPLY CRATE"),
            variant = "gold",
            position = UDim2.fromOffset(12, 50),
            size = UDim2.new(1, -24, 0, 34),
            textSize = 11,
            minTextSize = 9,
            zIndex = 6,
            onActivated = function()
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if remotes and remotes:FindFirstChild("UIRequest") then
                    remotes.UIRequest:FireServer("ClaimDailyReward", {})
                end
                Store.ShowToast(I18n.Pick("Đã gửi yêu cầu nhận Quân Nhu Tiếp Tế!", "Requested Allied Expedition Supply!"), "success", 2.0)
            end,
        })

        local _, tApi = PremiumButton.Create(detailPanel, {
            name = "TrackQuestButton",
            icon = "Compass",
            label = selectedQuestEntry.isTracked
                and I18n.Pick("ĐANG THEO DÕI TRÊN HUD & MINIMAP", "CURRENTLY TRACKED ON HUD")
                or I18n.Pick("GHIM THEO DÕI LÊN HUD [L]", "TRACK QUEST ON HUD [L]"),
            variant = selectedQuestEntry.isTracked and "gold" or "primary",
            position = UDim2.new(0, 16, 1, -60),
            size = UDim2.new(0.56, -20, 0, 44),
            textSize = 12,
            minTextSize = 9,
            onActivated = function()
                QuestController.TrackQuest(q.Id)
                ScreenRouter.Navigate(UIState.Screens.QuestJournal, { forceRebuild = true, replace = true })
            end,
        })
        trackBtnApi = tApi

        PremiumButton.Create(detailPanel, {
            name = "DialoguePreviewButton",
            label = I18n.Pick("ĐỐI THOẠI 3D LYRA", "3D LYRA DIALOGUE"),
            variant = "secondary",
            position = UDim2.new(0.56, 4, 1, -60),
            size = UDim2.new(0.44, -20, 0, 44),
            textSize = 12,
            minTextSize = 9,
            onActivated = function()
                QuestController.OpenDialogue(
                    I18n.Pick("LYRA • CHỈ HUY SKY HUB", "LYRA • SKY HUB COMMANDER"),
                    q.Description,
                    I18n.Pick("Người Giữ Cổ Ngữ • " .. q.Id, "Lorekeeper of the Core • " .. q.Id),
                    q.Id
                )
            end,
        })
    end

    QuestJournal.Refs = {
        Root = root,
        HeaderRefs = headerRefs,
        ContentLabel = contentLbl,
        TrackBtnApi = trackBtnApi,
        SelectedQuestConfig = selectedQuestEntry and selectedQuestEntry.config or nil,
        RewardLineText = rewardLineText,
    }
    return root
end

function QuestJournal.Update(snap)
    snap = snap or Store.GetSnapshot()
    if QuestJournal.Refs.HeaderRefs and QuestJournal.Refs.HeaderRefs.UpdateCurrencies then
        QuestJournal.Refs.HeaderRefs.UpdateCurrencies(snap)
    end
    local q = QuestJournal.Refs.SelectedQuestConfig
    if q and QuestJournal.Refs.ContentLabel and QuestJournal.Refs.ContentLabel.Parent then
        local objLines = {}
        local isLiveActive = (snap and snap.quest and snap.quest.activeId == q.Id)
        if isLiveActive and snap.quest.objectives then
            for _, o in ipairs(snap.quest.objectives) do
                local done = (o.current or 0) >= (o.target or 1)
                table.insert(
                    objLines,
                    string.format(
                        "<font color='%s'><b>%s</b></font> %s   <b>%d / %d</b>",
                        done and "#5ED79E" or "#E4B863",
                        done and "[x]" or "[ ]",
                        o.label,
                        o.current or 0,
                        o.target or 1
                    )
                )
            end
        else
            for _, o in ipairs(q.Objectives or {}) do
                table.insert(objLines, string.format("<font color='#A8B9D1'><b>[ ]</b></font> %s   <b>0 / %d</b>", o.Label, o.Target or 1))
            end
        end
        QuestJournal.Refs.ContentLabel.Text = string.format(
            "%s\n\n<font color='#E4B863'><b>%s</b></font>\n%s\n\n<font color='#5ED79E'><b>%s</b></font>\n%s",
            q.Description or "",
            I18n.Pick("MỤC TIÊU NHIỆM VỤ", "OBJECTIVES"),
            table.concat(objLines, "\n"),
            I18n.Pick("PHẦN THƯỞNG HOÀN THÀNH (SERVER CẤP)", "COMPLETION REWARDS (SERVER GRANTED)"),
            QuestJournal.Refs.RewardLineText or ""
        )
        if QuestJournal.Refs.TrackBtnApi then
            QuestJournal.Refs.TrackBtnApi:Update({
                label = isLiveActive
                    and I18n.Pick("* ĐANG THEO DÕI TRÊN HUD & MINIMAP", "* CURRENTLY TRACKED ON HUD")
                    or I18n.Pick("GHIM THEO DÕI LÊN HUD [L]", "TRACK QUEST ON HUD [L]"),
                variant = isLiveActive and "gold" or "primary",
            })
        end
    end
end

function QuestJournal.Cleanup()
    if QuestJournal.BustConn then
        QuestJournal.BustConn:Disconnect()
        QuestJournal.BustConn = nil
    end
    QuestJournal.Refs = {}
end

return QuestJournal
