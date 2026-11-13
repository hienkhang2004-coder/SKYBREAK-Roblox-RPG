-- SKYBREAK: Fragments of the Core — Server Class & Skill Validation Service
-- Location: ServerScriptService/SkybreakServer/SkillService.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local WorldConfig = require(Shared:WaitForChild("Config"):WaitForChild("WorldConfig"))

local Services = script.Parent.Parent:WaitForChild("Services")
local PlayerDataService = require(Services:WaitForChild("PlayerDataService"))
local GameService = require(Services:WaitForChild("GameService"))

local SkillService = {}

function SkillService.ValidateSkillUnlock(player, skillId)
    if type(skillId) ~= "string" or #skillId > 40 then
        return false, "Invalid skill ID."
    end
    local profile = PlayerDataService.Get(player)
    if not profile then
        return false, "Profile unavailable."
    end
    local classCfg = WorldConfig.Classes[profile.ClassId]
    if not classCfg then
        return false, "Invalid class."
    end
    for _, sk in ipairs(classCfg.Skills) do
        if sk.Id == skillId then
            if profile.Level < (sk.LevelReq or 1) then
                return false, string.format("%s requires Level %d.", sk.Name, sk.LevelReq)
            end
            return true, sk.Name .. " is unlocked."
        end
    end
    return false, "Skill does not belong to current class."
end

function SkillService.HandleClassSwitch(player, payload)
    if type(payload) ~= "table" then
        return false, nil
    end
    local profile = PlayerDataService.Get(player)
    if not profile then
        return false, "Profile unavailable."
    end
    local reqClass = payload.classId or payload.ClassId or payload.value or profile.ClassId
    if type(reqClass) ~= "string" or not WorldConfig.Classes[reqClass] then
        return false, "Hệ phái không hợp lệ."
    end
    if GameService.Boss and GameService.Boss.Party and GameService.Boss.Party[player] then
        return false, "Không thể đổi Hệ Phái khi đang đánh Boss."
    end
    local reqGender = payload.gender or payload.Gender or profile.Gender or "Male"
    GameService.ChooseAppearance(player, {
        ClassId = reqClass,
        Gender = reqGender,
    })
    profile.ClassChosen = true
    player:SetAttribute("ClassChosen", true)
    GameService.Sync(player)
    return true, nil
end

return SkillService
