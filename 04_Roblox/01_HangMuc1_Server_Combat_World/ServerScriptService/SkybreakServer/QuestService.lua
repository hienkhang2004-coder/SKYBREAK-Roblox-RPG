-- SKYBREAK: Fragments of the Core — Server Quest Validation & Progression Service
-- Location: ServerScriptService/SkybreakServer/QuestService.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldConfig = require(ReplicatedStorage:WaitForChild("SkybreakShared"):WaitForChild("Config"):WaitForChild("WorldConfig"))
local CoreConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Services = script.Parent.Parent:WaitForChild("Services")
local PlayerDataService = require(Services:WaitForChild("PlayerDataService"))
local GameService = require(Services:WaitForChild("GameService"))

local QuestService = {}

local function extractQuestId(payload)
    if type(payload) == "string" then
        return (#payload <= 32 and payload ~= "") and payload or nil
    end
    if type(payload) ~= "table" then
        return nil
    end
    local raw = payload.questId or payload.QuestId or payload.id or payload.value
    if type(raw) == "string" and raw ~= "" and #raw <= 32 then
        return raw
    end
    local idx = tonumber(payload.questIndex or payload.index)
    if idx and CoreConfig.Quests and CoreConfig.Quests[idx] then
        return CoreConfig.Quests[idx].Id
    end
    return nil
end

local function findMainQuestById(questId)
    if type(questId) ~= "string" or questId == "" then
        return nil, nil
    end
    for idx, cq in ipairs(CoreConfig.Quests or {}) do
        if cq.Id == questId then
            return cq, idx
        end
    end
    return nil, nil
end

local function findWorldQuestById(questId)
    if type(questId) ~= "string" or questId == "" then
        return nil
    end
    for _, wq in ipairs(WorldConfig.Quests or {}) do
        if wq.Id == questId then
            return wq
        end
    end
    return nil
end

function QuestService.HandleTrackQuest(player, payload)
    if not GameService.Rate(player, "UI_Quest", 0.25) then
        return false, nil
    end
    local profile = PlayerDataService.Get(player)
    if not profile then
        return false, nil
    end
    local questId = extractQuestId(payload)
    if not questId then
        return false, nil
    end

    local cq, mainIdx = findMainQuestById(questId)
    local wq = findWorldQuestById(questId)
    if not cq and not wq then
        return false, nil
    end

    local canonId = (cq and cq.Id) or (wq and wq.Id)
    profile.TrackedQuestId = canonId
    player:SetAttribute("TrackedQuestId", canonId)

    -- If player tracks an eligible Main quest Q01..Q30 while their current quest is unaccepted, sync active QuestIndex cleanly
    if cq and mainIdx and profile.Accepted == false then
        local reqLv = tonumber(cq.Level) or 1
        if (tonumber(profile.Level) or 1) >= reqLv then
            profile.QuestIndex = mainIdx
            profile.Progress = {}
        end
    end

    GameService.Sync(player)
    return true, nil
end

function QuestService.HandleAcceptQuest(player, payload)
    if not GameService.Rate(player, "UI_QuestAccept", 0.25) then
        return false, nil
    end
    local profile = PlayerDataService.Get(player)
    if not profile then
        return false, "Dữ liệu nhân vật chưa sẵn sàng."
    end

    local questId = extractQuestId(payload)
    local totalMain = #(CoreConfig.Quests or {})
    local playerLv = tonumber(profile.Level) or 1

    -- Default to current QuestIndex (or highest unlocked Q01..Q30 if finished) when no specific questId is passed
    if not questId and totalMain > 0 then
        local curIdx = math.clamp(tonumber(profile.QuestIndex) or 1, 1, totalMain + 1)
        if curIdx > totalMain then
            curIdx = totalMain
            for i = totalMain, 1, -1 do
                if playerLv >= (tonumber(CoreConfig.Quests[i].Level) or 1) then
                    curIdx = i
                    break
                end
            end
        end
        questId = CoreConfig.Quests[curIdx] and CoreConfig.Quests[curIdx].Id or "Q01"
    end

    local cq, mainIdx = findMainQuestById(questId)
    if cq and mainIdx then
        local reqLv = tonumber(cq.Level) or 1
        if playerLv < reqLv then
            local lockMsg = string.format("Cần đạt Lv. %d để nhận nhiệm vụ %s!", reqLv, tostring(cq.Name or cq.Id))
            if GameService.Notify then
                GameService.Notify(player, lockMsg)
            end
            return false, lockMsg
        end
        if profile.QuestIndex ~= mainIdx then
            profile.QuestIndex = mainIdx
            profile.Progress = {}
        elseif profile.Accepted == false then
            profile.Progress = type(profile.Progress) == "table" and profile.Progress or {}
        end
        profile.Accepted = true
        profile.TrackedQuestId = cq.Id
        player:SetAttribute("TrackedQuestId", cq.Id)
        GameService.Sync(player)
        local okMsg = "Đã nhận nhiệm vụ: " .. tostring(cq.Name or cq.Id)
        return true, okMsg
    end

    local wq = findWorldQuestById(questId)
    if wq then
        local reqLv = tonumber(wq.LevelReq) or 1
        if playerLv < reqLv then
            local lockMsg = string.format("Cần đạt Lv. %d để nhận nhiệm vụ %s!", reqLv, tostring(wq.VietnameseName or wq.Name or wq.Id))
            if GameService.Notify then
                GameService.Notify(player, lockMsg)
            end
            return false, lockMsg
        end
        profile.TrackedQuestId = wq.Id
        player:SetAttribute("TrackedQuestId", wq.Id)
        GameService.Sync(player)
        return true, "Đã theo dõi nhiệm vụ: " .. tostring(wq.VietnameseName or wq.Name or wq.Id)
    end

    return false, "Không tìm thấy nhiệm vụ yêu cầu."
end

return QuestService
