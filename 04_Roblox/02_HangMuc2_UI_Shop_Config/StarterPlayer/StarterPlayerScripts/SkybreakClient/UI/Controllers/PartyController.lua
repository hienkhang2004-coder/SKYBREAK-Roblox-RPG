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

function PartyController.GetUIRequestRemote()
    local sharedRemotes = Shared:FindFirstChild("Remotes")
    if sharedRemotes then
        local r = sharedRemotes:FindFirstChild("UIRequest") or sharedRemotes:FindFirstChild("UICommand")
        if r then
            return r
        end
    end
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        return remotes:FindFirstChild("UIRequest") or remotes:FindFirstChild("UICommand")
    end
    return nil
end

function PartyController.FirePartyAction(payload)
    payload = type(payload) == "table" and payload or {}
    local rem = PartyController.GetUIRequestRemote()
    if rem then
        rem:FireServer("PartyAction", payload)
        return true
    end
    return false
end

function PartyController.CreateParty()
    PartyController.FirePartyAction({
        subAction = "CreateParty",
        mode = "CreateParty",
    })
end

function PartyController.InvitePlayer(targetUserId, targetName)
    PartyController.FirePartyAction({
        subAction = "Invite",
        mode = "InviteParty",
        targetUserId = tonumber(targetUserId) or nil,
        targetName = targetName and tostring(targetName) or nil,
    })
    if targetName and targetName ~= "" then
        Store.ShowToast(I18n.Pick("Đã gửi lời mời Tổ Đội tới " .. tostring(targetName) .. "!", "Sent Party invite to " .. tostring(targetName) .. "!"), "info")
    end
end

function PartyController.AcceptInvite(partyId, inviterId)
    local snap = Store.GetSnapshot()
    local pid = partyId or (snap.party and snap.party.pendingPartyId) or ""
    local invId = inviterId or (snap.party and snap.party.pendingInviterId) or nil
    if Store.MergedServerExtras then
        Store.MergedServerExtras.PendingPartyInvite = nil
        if type(Store.MergedServerExtras.PartyData) == "table" then
            Store.MergedServerExtras.PartyData.PendingInviteFrom = nil
            Store.MergedServerExtras.PartyData.PendingInvite = nil
        end
    end
    if snap.party then
        snap.party.pendingInviteFrom = nil
        snap.party.pendingPartyId = nil
    end
    PartyController.FirePartyAction({
        subAction = "Accept",
        mode = "JoinParty",
        partyAction = "JoinParty",
        partyId = pid,
        inviterId = invId,
    })
    Store.Notify()
end

function PartyController.DeclineInvite(partyId)
    local snap = Store.GetSnapshot()
    local pid = partyId or (snap.party and snap.party.pendingPartyId) or ""
    if Store.MergedServerExtras then
        Store.MergedServerExtras.PendingPartyInvite = nil
        if type(Store.MergedServerExtras.PartyData) == "table" then
            Store.MergedServerExtras.PartyData.PendingInviteFrom = nil
            Store.MergedServerExtras.PartyData.PendingInvite = nil
        end
    end
    if snap.party then
        snap.party.pendingInviteFrom = nil
        snap.party.pendingPartyId = nil
    end
    PartyController.FirePartyAction({
        subAction = "Decline",
        mode = "DeclineParty",
        partyAction = "Decline",
        partyId = pid,
    })
    Store.ShowToast(I18n.Pick("Đã từ chối lời mời Tổ Đội.", "Declined Party invitation."), "info")
    Store.Notify()
end

function PartyController.LeaveParty()
    if Store.MergedServerExtras then
        Store.MergedServerExtras.PartyId = ""
        Store.MergedServerExtras.PartyMembers = nil
        Store.MergedServerExtras.PartyData = nil
    end
    PartyController.FirePartyAction({
        subAction = "Leave",
        mode = "LeaveParty",
        partyAction = "LeaveParty",
    })
    Store.Notify()
end

function PartyController.IsIslandUnlockedForTravel(destId, snapshot)
    local snap = snapshot or Store.GetSnapshot()
    local id = tostring(destId or "")
    if id == "" then
        return false, 1, false, "Unknown"
    end
    local isl = (WorldConfig.FastTravel and WorldConfig.FastTravel[id])
        or (WorldConfig.IslandById and WorldConfig.IslandById[id])
        or (WorldConfig.RealmById and WorldConfig.RealmById[id])
    local name = (isl and (isl.NameVi or isl.Name)) or id
    local parentRealm = (isl and (isl.RealmId or isl.Realm)) or id
    local sea = tonumber(isl and isl.Sea) or 1
    local recLv = (isl and type(isl.RecommendedLevel) == "table" and tonumber(isl.RecommendedLevel[1])) or nil
    local rawMin = tonumber((isl and (isl.MinLevel or isl.UnlockLevel)) or recLv) or 1
    local realmFloor = (sea == 2 or parentRealm == "FrozenCyber") and 700
        or ((sea == 3 or parentRealm == "ShadowRealm") and 1500)
        or 1
    local minLv = math.max(realmFloor, rawMin)
    if id == "SkyHub" or id == "GoldenSky" then
        return true, 1, true, name
    end
    local disc = (snap.discoveredIslands and snap.discoveredIslands[id] == true)
        or (isl and isl.FastTravelUnlockedByDefault == true)
        or (snap.world and snap.world.unlocked and snap.world.unlocked[id] == true)
        or false
    local lvOk = (tonumber(snap.player and snap.player.level) or 1) >= minLv
    return (disc and lvOk), minLv, disc, name
end

function PartyController.RequestFastTravel(realmId)
    local snap = Store.GetSnapshot()
    local realm = (WorldConfig.FastTravel and WorldConfig.FastTravel[realmId])
        or (WorldConfig.IslandById and WorldConfig.IslandById[realmId])
        or WorldConfig.RealmById[realmId]
    if not realm then
        Store.ShowToast(I18n.Pick("Không tìm thấy đảo hoặc cõi đích.", "Unknown destination realm or island."), "error")
        return
    end

    local canTravel, minLv, isDiscovered, dispName = PartyController.IsIslandUnlockedForTravel(realmId, snap)
    if not canTravel then
        if not isDiscovered then
            Store.ShowToast(
                I18n.Pick(
                    string.format("Chưa khám phá [%s]! Hãy lái Tàu Bay tới đảo hoặc làm Nhiệm Vụ Chính (Lv. %d+) để mở Dịch Chuyển Nhanh.", dispName, minLv),
                    string.format("[%s] not yet discovered! Sail by Sky Ship or advance Main Quests (Lv. %d+) to unlock Fast Travel.", dispName, minLv)
                ),
                "warning"
            )
        else
            Store.ShowToast(
                I18n.Pick(
                    string.format("Cần đạt Lv. %d+ để Dịch Chuyển Nhanh tới [%s]!", minLv, dispName),
                    string.format("Requires Lv. %d+ to Fast Travel to [%s]!", minLv, dispName)
                ),
                "warning"
            )
        end
        return
    end

    if not snap.isDemoMode then
        local uiRem = PartyController.GetUIRequestRemote()
        if uiRem then
            uiRem:FireServer("FastTravel", {
                command = "FastTravel",
                islandId = realmId,
                nodeId = realmId,
                realmId = realmId,
            })
            if snap.world then
                snap.world.current = realm.RealmId or realm.Realm or realmId
            end
            Store.ShowToast(
                I18n.Pick("Đang dịch chuyển tới " .. dispName .. "...", "Fast Traveling to " .. dispName .. "..."),
                "info"
            )
            return
        end
    end

    snap.world.current = realm.RealmId or realm.Realm or realmId
    Store.ShowToast(
        I18n.Pick("[DEMO] Đã dịch chuyển tới " .. dispName, "[DEMO] Fast Travel preview: arrived at " .. dispName),
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
