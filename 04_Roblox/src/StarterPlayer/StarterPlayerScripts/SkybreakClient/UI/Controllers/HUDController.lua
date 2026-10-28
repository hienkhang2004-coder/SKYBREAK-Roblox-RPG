-- SKYBREAK: Fragments of the Core — HUD & Humanoid Binding Controller
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Controllers/HUDController.lua
-- Implements Section 10.3 real Humanoid HealthChanged binding with leak-free connection management.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local WorldConfig = require(Shared:WaitForChild("Config"):WaitForChild("WorldConfig"))

local Store = require(script.Parent.Parent:WaitForChild("Store"))
local Animations = require(script.Parent.Parent:WaitForChild("Animations"))

local HUDController = {
    HealthConnection = nil,
    MaxHealthConnection = nil,
    CharacterAddedConnection = nil,
    BoundHPBarApi = nil,
    ExternalActionCallback = nil,
    ExternalAttackCallback = nil,
}

function HUDController.SetCombatCallbacks(onAction, onAttack)
    HUDController.ExternalActionCallback = onAction
    HUDController.ExternalAttackCallback = onAttack
end

function HUDController.BindHumanoidToBar(hpBarApi)
    HUDController.BoundHPBarApi = hpBarApi
    local player = Players.LocalPlayer
    if not player then
        return
    end

    local function disconnectHealth()
        if HUDController.HealthConnection then
            HUDController.HealthConnection:Disconnect()
            HUDController.HealthConnection = nil
        end
        if HUDController.MaxHealthConnection then
            HUDController.MaxHealthConnection:Disconnect()
            HUDController.MaxHealthConnection = nil
        end
    end

    local function bindCharacter(character)
        disconnectHealth()
        if not character then
            return
        end
        task.spawn(function()
            local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 8)
            if not humanoid or player.Character ~= character then
                return
            end

            local function renderHealth()
                local hp = math.max(0, humanoid.Health)
                local maxHp = math.max(1, humanoid.MaxHealth)
                local snap = Store.GetSnapshot()
                snap.vitals.hp = hp
                snap.vitals.maxHp = maxHp
                if HUDController.BoundHPBarApi then
                    HUDController.BoundHPBarApi:Update({
                        current = hp,
                        max = maxHp,
                        customText = string.format("HP  %d / %d", math.ceil(hp), math.ceil(maxHp)),
                    })
                end
            end

            HUDController.HealthConnection = humanoid.HealthChanged:Connect(renderHealth)
            HUDController.MaxHealthConnection = humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(renderHealth)
            renderHealth()
        end)
    end

    if HUDController.CharacterAddedConnection then
        HUDController.CharacterAddedConnection:Disconnect()
    end
    HUDController.CharacterAddedConnection = player.CharacterAdded:Connect(bindCharacter)
    if player.Character then
        bindCharacter(player.Character)
    end
end

function HUDController.TriggerAction(actionName)
    local snap = Store.GetSnapshot()
    local classId = snap.player.classId or "SkyGuardian"
    local classCfg = WorldConfig.Classes[classId] or WorldConfig.Classes.SkyGuardian

    -- Map generic slot keys to class-specific server action IDs
    local resolvedAction = actionName
    if actionName == "Skill1" or actionName == "SkySlash" then
        resolvedAction = classCfg.Skills[1] and classCfg.Skills[1].Id or "SkySlash"
    elseif actionName == "Skill2" or actionName == "GuardianShield" then
        resolvedAction = classCfg.Skills[2] and classCfg.Skills[2].Id or "GuardianShield"
    elseif actionName == "Skill3" then
        resolvedAction = classCfg.Skills[4] and classCfg.Skills[4].Id or "JudgmentStrike"
    elseif actionName == "Ultimate" then
        resolvedAction = classCfg.Skills[5] and classCfg.Skills[5].Id or "CelestialAegis"
    end

    -- Check level lock for Skills 3 & Ultimate
    for _, sk in ipairs(classCfg.Skills) do
        if sk.Id == resolvedAction then
            if snap.player.level < (sk.LevelReq or 1) then
                Store.ShowToast(string.format("%s unlocks at Level %d.", sk.Name, sk.LevelReq), "warning")
                return
            end
            break
        end
    end

    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if actionName == "Z" or actionName == "X" or actionName == "C" or actionName == "V" or actionName == "F" then
        if remotes and remotes:FindFirstChild("AbilityRequest") then
            remotes.AbilityRequest:FireServer({ action = "SlotMove", key = actionName })
        end
        return
    end

    local serverSkillAlias = {
        TempestSpiral = "StormBlitz",
        Thunderfall = "ThunderJudgement",
    }
    local serverSkillId = serverSkillAlias[resolvedAction] or resolvedAction

    if type(HUDController.ExternalActionCallback) == "function" then
        -- Route through ClientBootstrap's existing server sender when available
        if resolvedAction == classCfg.Skills[1].Id then
            HUDController.ExternalActionCallback("SkySlash")
        elseif resolvedAction == classCfg.Skills[2].Id then
            HUDController.ExternalActionCallback("GuardianShield")
        elseif resolvedAction == "Dodge" or resolvedAction == "Dash" or resolvedAction == "Interact" then
            HUDController.ExternalActionCallback(resolvedAction)
        else
            if remotes and remotes:FindFirstChild("AbilityRequest") then
                remotes.AbilityRequest:FireServer({ skillId = serverSkillId, action = serverSkillId })
            end
            Store.ShowToast("Activated " .. resolvedAction .. "!", "info")
        end
        return
    end

    -- Direct Remote fallback or Demo Mode simulation
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes and not snap.isDemoMode then
        if resolvedAction == "Dodge" or resolvedAction == "Dash" or resolvedAction == "Attack" or resolvedAction == "Heavy" then
            local ev = remotes:FindFirstChild("CombatRequest")
            if ev then ev:FireServer({ action = resolvedAction }) end
        else
            local ev = remotes:FindFirstChild("AbilityRequest")
            if ev then ev:FireServer({ skillId = resolvedAction }) end
        end
    else
        snap.cooldowns[resolvedAction] = 5.0
        Store.LastServerSyncClock = os.clock()
        Store.ShowToast("[DEMO] Triggered ability: " .. tostring(resolvedAction), "info")
    end
end

function HUDController.TriggerAttackInput(inputObject)
    if type(HUDController.ExternalAttackCallback) == "function" then
        HUDController.ExternalAttackCallback(inputObject)
        return
    end
    HUDController.TriggerAction("Attack")
end

function HUDController.Cleanup()
    if HUDController.HealthConnection then
        HUDController.HealthConnection:Disconnect()
        HUDController.HealthConnection = nil
    end
    if HUDController.MaxHealthConnection then
        HUDController.MaxHealthConnection:Disconnect()
        HUDController.MaxHealthConnection = nil
    end
    HUDController.BoundHPBarApi = nil
    Animations.CleanupScope("HUD")
end

return HUDController
