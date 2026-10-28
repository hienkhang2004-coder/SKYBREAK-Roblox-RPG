-- SKYBREAK: Fragments of the Core — Class, Forge, World Travel & Raid Controller
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Controllers/PartyController.lua
-- All resource/travel/class actions request server validation first; never grants client-side Gold/EXP.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local WorldConfig = require(Shared:WaitForChild("Config"):WaitForChild("WorldConfig"))
local RarityConfig = require(Shared:WaitForChild("Config"):WaitForChild("RarityConfig"))

local Store = require(script.Parent.Parent:WaitForChild("Store"))

local PartyController = {}

function PartyController.RequestClassOrGenderChange(classId, gender)
    local snap = Store.GetSnapshot()
    local targetClass = classId or snap.player.classId
    local targetGender = gender or snap.player.gender

    local cls = WorldConfig.Classes[targetClass]
    if not cls then
        Store.ShowToast("Invalid Class selection.", "error")
        return
    end
    if targetClass == "ArcaneMage" and targetGender == "Female" then
        Store.ShowToast(cls.FemaleLockReason or "Arcane Mage nữ chưa có model; hiện chọn bản nam.", "warning")
        return
    end

    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes and not snap.isDemoMode then
        local appRemote = remotes:FindFirstChild("AppearanceRequest")
        if appRemote then
            appRemote:FireServer({
                ClassId = targetClass,
                Gender = targetGender,
            })
            Store.ShowToast("Requested Class / Appearance switch from server...", "info")
            return
        end
    end

    Store.ApplyDemoPreviewAction("SelectClass", {
        classId = targetClass,
        gender = targetGender,
    })
end

function PartyController.RequestFastTravel(realmId)
    local snap = Store.GetSnapshot()
    local realm = WorldConfig.RealmById[realmId] or (WorldConfig.IslandById and WorldConfig.IslandById[realmId])
    if not realm then
        Store.ShowToast("Unknown destination realm or island.", "error")
        return
    end

    local isUnlocked = (realmId == "SkyHub")
        or (realmId == "GoldenSky")
        or (realm.FastTravelUnlockedByDefault == true)
        or (WorldConfig.IslandById and WorldConfig.IslandById[realmId] ~= nil)
        or (snap.world and snap.world.unlocked and snap.world.unlocked[realmId] == true)

    if not isUnlocked then
        Store.ShowToast(
            string.format("%s is locked. %s", realm.Name, realm.UnlockConditionText or "Complete prior chapter first."),
            "warning"
        )
        return
    end

    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes and not snap.isDemoMode then
        local eqRemote = remotes:FindFirstChild("EquipmentRequest")
        if eqRemote then
            eqRemote:FireServer({
                action = "FastTravel",
                nodeId = realmId,
            })
        end
        local uiCmd = remotes:FindFirstChild("UICommand")
        if uiCmd then
            uiCmd:FireServer({
                command = "FastTravel",
                realmId = realmId,
            })
        end
        if eqRemote or uiCmd then
            snap.world.current = realm.RealmId or realmId
            Store.ShowToast("Fast Traveling to " .. realm.Name .. "...", "info")
            return
        end
    end

    snap.world.current = realm.RealmId or realmId
    Store.ShowToast("[DEMO] Fast Travel preview: arrived at " .. realm.Name, "success")
end

function PartyController.RequestForgeCraft(recipeId)
    local snap = Store.GetSnapshot()
    local recipe = nil
    for _, r in ipairs(RarityConfig.Recipes) do
        if r.Id == recipeId then
            recipe = r
            break
        end
    end
    if not recipe then
        Store.ShowToast("Invalid recipe selected.", "error")
        return
    end

    -- Client pre-check for clear user feedback (Server still re-validates everything!)
    if snap.player.level < (recipe.LevelReq or 1) then
        Store.ShowToast(string.format("Requires Level %d to craft %s.", recipe.LevelReq, recipe.Name), "warning")
        return
    end
    if snap.currency.gold < (recipe.GoldCost or 0) then
        Store.ShowToast(string.format("Insufficient Gold (%d / %d required).", snap.currency.gold, recipe.GoldCost), "error")
        return
    end

    local ownedCounts = {}
    for _, entry in ipairs(snap.inventory) do
        ownedCounts[entry.itemId] = entry.count or 0
    end
    for _, mat in ipairs(recipe.Materials) do
        local have = ownedCounts[mat.ItemId] or 0
        if have < mat.Count then
            local matCfg = RarityConfig.GetItem(mat.ItemId)
            Store.ShowToast(
                string.format("Missing material: %s (%d / %d).", matCfg and matCfg.Name or mat.ItemId, have, mat.Count),
                "error"
            )
            return
        end
    end

    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes and not snap.isDemoMode then
        local uiCmd = remotes:FindFirstChild("UICommand")
        if uiCmd then
            uiCmd:FireServer({
                command = "CraftRecipe",
                recipeId = recipeId,
            })
            Store.ShowToast("Submitting craft order to Kael's Forge...", "info")
            return
        end
    end

    Store.ShowToast("[DEMO] Craft validated (" .. recipe.Name .. "). Server authority required to consume materials.", "success")
end

function PartyController.RequestUpgradeItem(itemId)
    local snap = Store.GetSnapshot()
    local itemCfg = RarityConfig.GetItem(itemId)
    if not itemCfg then
        Store.ShowToast("Select a valid equipment piece to upgrade.", "warning")
        return
    end

    local currentUpgrade = 0
    for _, entry in ipairs(snap.inventory) do
        if entry.itemId == itemId then
            currentUpgrade = entry.upgrade or 0
            break
        end
    end

    local costInfo = RarityConfig.GetUpgradeCost(itemId, currentUpgrade)
    if not costInfo.CanUpgrade then
        Store.ShowToast(itemCfg.Name .. " has reached maximum upgrade tier!", "warning")
        return
    end
    if snap.currency.gold < costInfo.GoldCost then
        Store.ShowToast(string.format("Insufficient Gold (%d / %d).", snap.currency.gold, costInfo.GoldCost), "error")
        return
    end

    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes and not snap.isDemoMode then
        local uiCmd = remotes:FindFirstChild("UICommand")
        if uiCmd then
            uiCmd:FireServer({
                command = "UpgradeItem",
                itemId = itemId,
            })
            Store.ShowToast("Requesting upgrade +" .. costInfo.NextUpgrade .. " from server...", "info")
            return
        end
    end

    Store.ShowToast(
        string.format("[DEMO] Upgrade +%d preview for %s (Server validates material consumption).", costInfo.NextUpgrade, itemCfg.Name),
        "info"
    )
end

function PartyController.SimulateBossPhase(raidId, phaseNumber)
    Store.ApplyDemoPreviewAction("ToggleRaidPreview", {
        raidId = raidId,
        forcePhase = phaseNumber,
    })
end

return PartyController
