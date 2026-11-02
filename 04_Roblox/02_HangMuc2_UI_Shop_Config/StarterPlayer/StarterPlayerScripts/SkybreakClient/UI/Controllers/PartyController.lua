-- SKYBREAK: Fragments of the Core — Class, Forge, World Travel & Raid Controller
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Controllers/PartyController.lua
-- All resource/travel/class actions request server validation first; never grants client-side Gold/EXP.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local WorldConfig = require(Shared:WaitForChild("Config"):WaitForChild("WorldConfig"))
local RarityConfig = require(Shared:WaitForChild("Config"):WaitForChild("RarityConfig"))

local Store = require(script.Parent.Parent:WaitForChild("Store"))
local I18n = require(script.Parent.Parent:WaitForChild("I18n"))

local PartyController = {}

function PartyController.RequestClassOrGenderChange(classId, gender)
    local snap = Store.GetSnapshot()
    local targetClass = classId or snap.player.classId
    local targetGender = gender or snap.player.gender

    local cls = WorldConfig.Classes[targetClass]
    if not cls then
        Store.ShowToast(I18n.Pick("Hệ phái không hợp lệ.", "Invalid Class selection."), "error")
        return
    end
    if targetClass == "ArcaneMage" and targetGender == "Female" then
        Store.ShowToast(
            I18n.Pick(
                cls.FemaleLockReason or "Arcane Mage nữ chưa có model; hiện chọn bản nam.",
                "Female Arcane Mage model is not yet available; using Male variant."
            ),
            "warning"
        )
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
            Store.ShowToast(
                I18n.Pick("Đã gửi yêu cầu đổi Hệ Phái / Ngoại Hình lên máy chủ...", "Requested Class / Appearance switch from server..."),
                "info"
            )
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
        Store.ShowToast(I18n.Pick("Không tìm thấy đảo hoặc cõi đích.", "Unknown destination realm or island."), "error")
        return
    end

    local isUnlocked = (realmId == "SkyHub")
        or (realmId == "GoldenSky")
        or (realm.FastTravelUnlockedByDefault == true)
        or (WorldConfig.IslandById and WorldConfig.IslandById[realmId] ~= nil)
        or (snap.world and snap.world.unlocked and snap.world.unlocked[realmId] == true)

    if not isUnlocked then
        Store.ShowToast(
            I18n.Pick(
                string.format("%s đang khóa. %s", realm.Name, realm.UnlockConditionText or "Hãy hoàn thành chương trước."),
                string.format("%s is locked. %s", realm.Name, realm.UnlockConditionText or "Complete prior chapter first.")
            ),
            "warning"
        )
        return
    end

    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes and not snap.isDemoMode then
        local eqRemote = remotes:FindFirstChild("EquipmentRequest")
        local uiCmd = remotes:FindFirstChild("UICommand")
        if eqRemote then
            eqRemote:FireServer({
                action = "FastTravel",
                nodeId = realmId,
                islandId = realmId,
            })
        elseif uiCmd then
            uiCmd:FireServer({
                command = "FastTravel",
                realmId = realmId,
            })
        end
        if eqRemote or uiCmd then
            if snap.world then
                snap.world.current = realm.RealmId or realmId
            end
            Store.ShowToast(
                I18n.Pick("Đang dịch chuyển tới " .. realm.Name .. "...", "Fast Traveling to " .. realm.Name .. "..."),
                "info"
            )
            return
        end
    end

    snap.world.current = realm.RealmId or realmId
    Store.ShowToast(
        I18n.Pick("[DEMO] Đã dịch chuyển tới " .. realm.Name, "[DEMO] Fast Travel preview: arrived at " .. realm.Name),
        "success"
    )
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
        Store.ShowToast(I18n.Pick("Công thức rèn không hợp lệ.", "Invalid recipe selected."), "error")
        return
    end

    local recipeDisp = I18n.GetItemDisplayName(recipe.OutputItemId, recipe.Name)
    -- Client pre-check for clear user feedback (Server still re-validates everything!)
    if snap.player.level < (recipe.LevelReq or 1) then
        Store.ShowToast(
            I18n.Pick(
                string.format("Cần Cấp %d để rèn %s.", recipe.LevelReq, recipeDisp),
                string.format("Requires Level %d to craft %s.", recipe.LevelReq, recipeDisp)
            ),
            "warning"
        )
        return
    end
    local curGold = snap.currency and snap.currency.gold or 0
    if curGold < (recipe.GoldCost or 0) then
        Store.ShowToast(
            I18n.Pick(
                string.format("Không đủ Vàng (%d / %d).", curGold, recipe.GoldCost),
                string.format("Insufficient Gold (%d / %d required).", curGold, recipe.GoldCost)
            ),
            "error"
        )
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
            local matDisp = I18n.GetItemDisplayName(mat.ItemId, matCfg and matCfg.Name or mat.ItemId)
            Store.ShowToast(
                I18n.Pick(
                    string.format("Thiếu nguyên liệu: %s (%d / %d).", matDisp, have, mat.Count),
                    string.format("Missing material: %s (%d / %d).", matDisp, have, mat.Count)
                ),
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
            Store.ShowToast(
                I18n.Pick("Đang gửi lệnh rèn tới Lò Rèn Kael...", "Submitting craft order to Kael's Forge..."),
                "info"
            )
            return
        end
    end

    Store.ShowToast(
        I18n.Pick(
            "[DEMO] Đủ điều kiện rèn (" .. recipeDisp .. "). Cần máy chủ xác thực nguyên liệu.",
            "[DEMO] Craft validated (" .. recipeDisp .. "). Server authority required to consume materials."
        ),
        "success"
    )
end

function PartyController.RequestUpgradeItem(itemId)
    local snap = Store.GetSnapshot()
    local itemCfg = RarityConfig.GetItem(itemId)
    if not itemCfg then
        Store.ShowToast(
            I18n.Pick("Hãy chọn trang bị hợp lệ để cường hóa.", "Select a valid equipment piece to upgrade."),
            "warning"
        )
        return
    end

    local itemDisp = I18n.GetItemDisplayName(itemId, itemCfg.Name)
    local currentUpgrade = 0
    for _, entry in ipairs(snap.inventory) do
        if entry.itemId == itemId then
            currentUpgrade = entry.upgrade or 0
            break
        end
    end

    local costInfo = RarityConfig.GetUpgradeCost(itemId, currentUpgrade)
    if not costInfo.CanUpgrade then
        Store.ShowToast(
            I18n.Pick(itemDisp .. " đã đạt cấp cường hóa tối đa!", itemDisp .. " has reached maximum upgrade tier!"),
            "warning"
        )
        return
    end
    local curGold = snap.currency and snap.currency.gold or 0
    if curGold < costInfo.GoldCost then
        Store.ShowToast(
            I18n.Pick(
                string.format("Không đủ Vàng (%d / %d).", curGold, costInfo.GoldCost),
                string.format("Insufficient Gold (%d / %d).", curGold, costInfo.GoldCost)
            ),
            "error"
        )
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
            Store.ShowToast(
                I18n.Pick(
                    "Đang yêu cầu cường hóa +" .. costInfo.NextUpgrade .. " từ máy chủ...",
                    "Requesting upgrade +" .. costInfo.NextUpgrade .. " from server..."
                ),
                "info"
            )
            return
        end
    end

    Store.ShowToast(
        I18n.Pick(
            string.format("[DEMO] Xem trước cường hóa +%d cho %s.", costInfo.NextUpgrade, itemDisp),
            string.format("[DEMO] Upgrade +%d preview for %s (Server validates material consumption).", costInfo.NextUpgrade, itemDisp)
        ),
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
