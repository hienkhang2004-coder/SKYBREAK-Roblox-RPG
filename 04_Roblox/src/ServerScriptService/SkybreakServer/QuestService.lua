-- SKYBREAK: Fragments of the Core — Server Quest Validation Service
-- Location: ServerScriptService/SkybreakServer/QuestService.lua

local Services = script.Parent.Parent:WaitForChild("Services")
local PlayerDataService = require(Services:WaitForChild("PlayerDataService"))
local GameService = require(Services:WaitForChild("GameService"))

local QuestService = {}

function QuestService.HandleTrackQuest(player, payload)
    if type(payload) ~= "table" or type(payload.questId) ~= "string" then
        return false, "Invalid quest ID."
    end
    if not GameService.Rate(player, "UI_Quest", 0.3) then
        return false, "Rate limited."
    end
    local profile = PlayerDataService.Get(player)
    if not profile then
        return false, "Profile unavailable."
    end
    GameService.Sync(player)
    return true, "Synced active quest state."
end

return QuestService
