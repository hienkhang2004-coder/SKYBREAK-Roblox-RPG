-- SKYBREAK: Fragments of the Core — Quest Journal, Tracker & Dialogue Controller
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Controllers/QuestController.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local WorldConfig = require(Shared:WaitForChild("Config"):WaitForChild("WorldConfig"))

local Store = require(script.Parent.Parent:WaitForChild("Store"))

local QuestController = {}

function QuestController.GetQuestsByCategory(category)
    category = category or "Main"
    local snap = Store.GetSnapshot()
    local activeId = snap.quest and snap.quest.activeId
    local completedMap = (snap.quest and snap.quest.completedIds) or {}

    local list = {}
    for _, q in ipairs(WorldConfig.Quests) do
        if category == "All" or q.Category == category then
            local status = "Available"
            if completedMap[q.Id] then
                status = "Completed"
            elseif q.Id == activeId then
                status = snap.quest.accepted and "Active" or "ReadyToAccept"
            elseif snap.player.level < (q.LevelReq or 1) then
                status = "Locked"
            end
            table.insert(list, {
                config = q,
                status = status,
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
    for _, q in ipairs(WorldConfig.Quests) do
        if q.Id == questId then
            found = q
            break
        end
    end
    if not found then
        return
    end

    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes and not snap.isDemoMode then
        local uiCmd = remotes:FindFirstChild("UICommand")
        if uiCmd then
            uiCmd:FireServer({ command = "TrackQuest", questId = questId })
        end
    end

    -- Update local tracker display if in Demo Mode or previewing secondary quests
    if snap.isDemoMode or found.Category ~= "Main" then
        local objs = {}
        for i, o in ipairs(found.Objectives or {}) do
            table.insert(objs, {
                id = tostring(i),
                label = o.Label,
                current = i == 1 and 1 or 0,
                target = o.Target or 1,
            })
        end
        snap.quest = {
            activeId = found.Id,
            name = found.Name,
            text = found.Description,
            accepted = true,
            level = found.LevelReq,
            objectives = objs,
            completedIds = snap.quest and snap.quest.completedIds or {},
        }
        Store.SetView({ selectedQuestId = questId })
        Store.ShowToast("Tracking Quest: " .. found.Name, "success")
    else
        Store.ShowToast("Active Main Quest synced with server: " .. (snap.quest and snap.quest.name or found.Name), "info")
    end
end

function QuestController.OpenDialogue(speaker, text, role, questId, actionLabel, actionCommand)
    Store.SetView({
        dialogue = {
            visible = true,
            speaker = speaker or "LYRA • SKY HUB",
            role = role or "Lorekeeper of the Core",
            text = text or "",
            questId = questId,
            actionLabel = actionLabel,
            actionCommand = actionCommand,
        },
    })
end

function QuestController.CloseDialogue()
    Store.SetView({
        dialogue = {
            visible = false,
        },
    })
end

return QuestController
