-- SKYBREAK: Fragments of the Core — Server Quest Validation Service
-- Location: ServerScriptService/SkybreakServer/QuestService.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldConfig = require(ReplicatedStorage:WaitForChild("SkybreakShared"):WaitForChild("Config"):WaitForChild("WorldConfig"))

local Services = script.Parent.Parent:WaitForChild("Services")
local PlayerDataService = require(Services:WaitForChild("PlayerDataService"))
local GameService = require(Services:WaitForChild("GameService"))

local QuestService = {}

function QuestService.HandleTrackQuest(player, payload)
    if type(payload) ~= "table" or type(payload.questId) ~= "string" or #payload.questId > 32 then
        return false, nil
    end
    if not GameService.Rate(player, "UI_Quest", 0.3) then
        return false, nil
    end
    local profile = PlayerDataService.Get(player)
    if not profile then
        return false, nil
    end
    local matched = nil
    for _, q in ipairs(WorldConfig.Quests or {}) do
        if q.Id == payload.questId then
            matched = q
            break
        end
    end
    if not matched then
        return false, nil
    end
    profile.TrackedQuestId = matched.Id
    player:SetAttribute("TrackedQuestId", matched.Id)
    if matched.Category == "Main" then
        GameService.Sync(player)
    end
    return true, nil
end

return QuestService
