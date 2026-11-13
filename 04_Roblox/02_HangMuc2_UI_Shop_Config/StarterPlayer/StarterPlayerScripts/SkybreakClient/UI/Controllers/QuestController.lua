-- SKYBREAK: Fragments of the Core — Quest Journal, Tracker & Dialogue Controller
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Controllers/QuestController.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local WorldConfig = require(Shared:WaitForChild("Config"):WaitForChild("WorldConfig"))

local Store = require(script.Parent.Parent:WaitForChild("Store"))
local I18n = require(script.Parent.Parent:WaitForChild("I18n"))

local QuestController = {}

local function getUIRequestRemote()
    local sharedRemotes = Shared:FindFirstChild("Remotes")
    if sharedRemotes then
        local r = sharedRemotes:FindFirstChild("UIRequest") or sharedRemotes:FindFirstChild("UICommand")
        if r then
            return r
        end
    end
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        return remotes:FindFirstChild("UIRequest") or remotes:FindFirstChild("UICommand")
    end
    return nil
end

function QuestController.GetQuestsByCategory(category)
    category = category or "Main"
    local snap = Store.GetSnapshot()
    local activeId = snap.quest and snap.quest.activeId
    local completedMap = (snap.quest and snap.quest.completedIds) or {}
    local pLv = tonumber(snap.player and snap.player.level) or 1

    local activeNumeric = tonumber(type(activeId) == "string" and activeId:match("^Q(%d+)$") or nil)
    local allDone = (activeId == "COMPLETE_ALL")

    local list = {}
    for _, q in ipairs(WorldConfig.Quests or {}) do
        local qCat = q.Category or "Main"
        if category == "All" or qCat == category then
            local qLv = tonumber(q.LevelReq or q.Level) or 1
            local qNum = tonumber(type(q.Id) == "string" and q.Id:match("^Q(%d+)$") or nil)
            local isCompleted = (completedMap[q.Id] == true)
                or (qCat == "Main" and allDone)
                or (qCat == "Main" and qNum and activeNumeric and qNum < activeNumeric)

            local status = "Available"
            if isCompleted then
                status = "Completed"
            elseif q.Id == activeId then
                status = (snap.quest and snap.quest.accepted) and "Active" or "ReadyToAccept"
            elseif pLv < qLv then
                status = "Locked"
            end
            table.insert(list, {
                config = q,
                status = status,
                levelReq = qLv,
                isTracked = (q.Id == activeId),
            })
        end
    end
    return list
end

function QuestController.SelectQuest(questId)
    Store.SetView({ selectedQuestId = questId })
end

function QuestController.TrackQuest(questId)
    local snap = Store.GetSnapshot()
    local found = nil
    for _, q in ipairs(WorldConfig.Quests or {}) do
        if q.Id == questId then
            found = q
            break
        end
    end
    if not found then
        return
    end

    local qLv = tonumber(found.LevelReq or found.Level) or 1
    local pLv = tonumber(snap.player and snap.player.level) or 1
    local qDispTitle = I18n.QuestTitle(found, found.Title or found.Name or found.Id)
    if pLv < qLv and not snap.isDemoMode then
        Store.ShowToast(
            I18n.Pick(
                string.format("Cần đạt Lv. %d+ để nhận / theo dõi nhiệm vụ [%s]!", qLv, qDispTitle),
                string.format("Requires Lv. %d+ to track [%s]!", qLv, qDispTitle)
            ),
            "warning"
        )
        return
    end

    if not snap.isDemoMode then
        local rem = getUIRequestRemote()
        if rem then
            if snap.quest and snap.quest.activeId == questId and snap.quest.accepted == false then
                rem:FireServer("AcceptQuest", { questId = questId, id = questId })
            else
                rem:FireServer("TrackQuest", { command = "TrackQuest", questId = questId, id = questId })
            end
        end
    end

    local objs = {}
    for i, o in ipairs(found.Objectives or {}) do
        local tgt = math.max(1, tonumber(o.Target or o.Goal or o.Count) or 1)
        table.insert(objs, {
            id = tostring(i),
            label = I18n.QuestObjectiveLabel(found, o, i),
            labelEn = o.LabelEn,
            current = snap.isDemoMode and (i == 1 and 1 or 0) or 0,
            target = tgt,
        })
    end

    local qCat = found.Category or "Main"
    if snap.isDemoMode or qCat ~= "Main" or (snap.quest and snap.quest.activeId ~= questId) then
        snap.quest = {
            activeId = found.Id,
            name = qDispTitle,
            text = I18n.QuestDesc(found, found.Description or found.Text or ""),
            accepted = true,
            level = qLv,
            rewardGold = (found.Rewards and found.Rewards.Gold) or found.Gold or nil,
            objectives = objs,
            completedIds = snap.quest and snap.quest.completedIds or {},
        }
    end
    Store.SetView({ selectedQuestId = questId })
    Store.ShowToast(
        I18n.Pick("Đang theo dõi nhiệm vụ: ", "Tracking Quest: ") .. qDispTitle,
        "success"
    )
end

function QuestController.OpenDialogue(speaker, text, role, questId, actionLabel, actionCommand, choices)
    if Store.View and Store.View.dialogue then
        Store.View.dialogue.questId = nil
        Store.View.dialogue.actionLabel = nil
        Store.View.dialogue.actionCommand = nil
        Store.View.dialogue.choices = nil
    end
    Store.SetView({
        dialogue = {
            visible = true,
            speaker = speaker or "LYRA • SKY HUB",
            role = role or "Lorekeeper of the Core",
            text = text or "",
            questId = questId,
            actionLabel = actionLabel,
            actionCommand = actionCommand,
            choices = type(choices) == "table" and choices or nil,
        },
    })
end

function QuestController.CloseDialogue()
    if Store.View and Store.View.dialogue then
        Store.View.dialogue.questId = nil
        Store.View.dialogue.actionLabel = nil
        Store.View.dialogue.actionCommand = nil
        Store.View.dialogue.choices = nil
    end
    Store.SetView({
        dialogue = {
            visible = false,
        },
    })
end

return QuestController
