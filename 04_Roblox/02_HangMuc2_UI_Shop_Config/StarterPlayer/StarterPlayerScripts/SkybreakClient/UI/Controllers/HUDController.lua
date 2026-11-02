-- SKYBREAK: Fragments of the Core — HUD & Humanoid Binding Controller
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Controllers/HUDController.lua
-- Implements Section 10.3 real Humanoid HealthChanged binding, Hotbar [1]-[4] switching (#10), and Mobile Touch Arc actions (#125).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local WorldConfig = require(Shared:WaitForChild("Config"):WaitForChild("WorldConfig"))

local Store = require(script.Parent.Parent:WaitForChild("Store"))
local CelestialMinimap = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("CelestialMinimap"))

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

            local lastHealth = humanoid.Health
            local function renderHealth()
                local hp = math.max(0, humanoid.Health)
                local maxHp = math.max(1, humanoid.MaxHealth)

                -- #6: If player took damage while within 130 studs of an alive boss, refresh 15s boss combat timer
                if hp < lastHealth then
                    local pp = character.PrimaryPart or character:FindFirstChild("HumanoidRootPart")
                    if pp and pp:IsA("BasePart") then
                        local bossModel, dist = CelestialMinimap.FindClosestLiveBoss(pp.Position)
                        if bossModel and dist <= 130 then
                            Store.RecordBossCombat()
                        end
                    end
                end
                lastHealth = hp

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

function HUDController.SelectHotbarSlot(slotIndex)
    local slot = math.clamp(tonumber(slotIndex) or 1, 1, 4)
    local player = Players.LocalPlayer
    if player then
        pcall(function()
            player:SetAttribute("ActiveSlot", slot)
        end)
    end
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local eq = remotes:FindFirstChild("EquipmentRequest")
        if eq then
            eq:FireServer({ action = "SelectSlot", slot = slot })
        end
    end
    Store.SetView({ activeHotbarSlot = slot })
end

function HUDController.TriggerAction(actionName)
    local snap = Store.GetSnapshot()
    local classId = snap.player.classId or "SkyGuardian"
    local classCfg = WorldConfig.Classes[classId] or WorldConfig.Classes.SkyGuardian
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")

    if actionName == "SelectSlot1" or actionName == "SelectSlot2" or actionName == "SelectSlot3" or actionName == "SelectSlot4" then
        HUDController.SelectHotbarSlot(tonumber(string.sub(actionName, -1)) or 1)
        return
    end

    if actionName == "ToggleAura" or actionName == "ToggleInstinct" or actionName == "ActivateRaceV4" or actionName == "ConquerorBurst" then
        if type(HUDController.ExternalActionCallback) == "function" then
            HUDController.ExternalActionCallback(actionName)
            return
        end
        if remotes and remotes:FindFirstChild("EquipmentRequest") then
            remotes.EquipmentRequest:FireServer({ action = actionName })
        end
        return
    end

    if actionName == "ToggleLock" then
        if type(HUDController.ExternalActionCallback) == "function" then
            HUDController.ExternalActionCallback("ToggleLock")
        end
        return
    end

    if actionName == "JumpGeppo" then
        local player = Players.LocalPlayer
        local ch = player and player.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.Jump = true
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        return
    end

    if actionName == "Z" or actionName == "X" or actionName == "C" or actionName == "V" or actionName == "F" then
        -- Refresh boss combat timer if using combat moves near a live boss (#6)
        local player = Players.LocalPlayer
        local ch = player and player.Character
        local pp = ch and (ch.PrimaryPart or ch:FindFirstChild("HumanoidRootPart"))
        if pp and pp:IsA("BasePart") then
            local bossModel, dist = CelestialMinimap.FindClosestLiveBoss(pp.Position)
            if bossModel and dist <= 115 then
                Store.RecordBossCombat()
            end
        end

        if type(HUDController.ExternalActionCallback) == "function" then
            HUDController.ExternalActionCallback("SlotMove" .. actionName)
            return
        end
        if remotes and remotes:FindFirstChild("AbilityRequest") then
            remotes.AbilityRequest:FireServer({ action = "SlotMove", key = actionName })
        end
        return
    end

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

    for _, sk in ipairs(classCfg.Skills) do
        if sk.Id == resolvedAction then
            if snap.player.level < (sk.LevelReq or 1) then
                Store.ShowToast(string.format("%s unlocks at Level %d.", sk.Name, sk.LevelReq), "warning")
                return
            end
            break
        end
    end

    local serverSkillAlias = {
        TempestSpiral = "StormBlitz",
        Thunderfall = "ThunderJudgement",
    }
    local serverSkillId = serverSkillAlias[resolvedAction] or resolvedAction

    if type(HUDController.ExternalActionCallback) == "function" then
        local sk1 = classCfg.Skills and classCfg.Skills[1]
        local sk2 = classCfg.Skills and classCfg.Skills[2]
        if sk1 and resolvedAction == sk1.Id then
            HUDController.ExternalActionCallback("SkySlash")
        elseif sk2 and resolvedAction == sk2.Id then
            HUDController.ExternalActionCallback("GuardianShield")
        elseif resolvedAction == "Dodge" or resolvedAction == "Dash" or resolvedAction == "Interact" or resolvedAction == "Attack" then
            HUDController.ExternalActionCallback(resolvedAction)
        else
            if remotes and remotes:FindFirstChild("AbilityRequest") then
                remotes.AbilityRequest:FireServer({ skillId = serverSkillId, action = serverSkillId })
            end
            Store.ShowToast("Activated " .. resolvedAction .. "!", "info")
        end
        return
    end

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
        Store.ShowToast("Activated: " .. tostring(resolvedAction), "info")
    end
end

function HUDController.TriggerAttackInput(inputObject)
    local player = Players.LocalPlayer
    local ch = player and player.Character
    local pp = ch and (ch.PrimaryPart or ch:FindFirstChild("HumanoidRootPart"))
    if pp and pp:IsA("BasePart") then
        local bossModel, dist = CelestialMinimap.FindClosestLiveBoss(pp.Position)
        if bossModel and dist <= 115 then
            Store.RecordBossCombat()
        end
    end

    if type(HUDController.ExternalAttackCallback) == "function" and inputObject then
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
    if HUDController.CharacterAddedConnection then
        HUDController.CharacterAddedConnection:Disconnect()
        HUDController.CharacterAddedConnection = nil
    end
    HUDController.BoundHPBarApi = nil
end

return HUDController
