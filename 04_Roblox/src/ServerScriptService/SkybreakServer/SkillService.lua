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
        return false, "Invalid payload."
    end
    GameService.ChooseAppearance(player, {
        ClassId = payload.classId or payload.ClassId,
        Gender = payload.gender or payload.Gender,
    })
    return true, "Processed appearance/class request."
end

return SkillService
