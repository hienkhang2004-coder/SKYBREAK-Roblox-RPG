-- SKYBREAK: Fragments of the Core — Reactive Client UI Store
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Store.lua
-- Strictly separates server-authoritative PlayerSnapshot from local ViewState (Section 07).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local UIState = require(Shared:WaitForChild("Types"):WaitForChild("UIState"))
local RarityConfig = require(Shared:WaitForChild("Config"):WaitForChild("RarityConfig"))
local WorldConfig = require(Shared:WaitForChild("Config"):WaitForChild("WorldConfig"))
local I18n = require(script.Parent:WaitForChild("I18n"))

local initialSnapshot = UIState.CreateDefaultSnapshot(true)
if initialSnapshot.raid then
    initialSnapshot.raid.active = false
end

local Store = {
    Snapshot = initialSnapshot,
    View = UIState.CreateDefaultViewState(),
    LastServerSyncClock = os.clock(),
    HasReceivedInitialServerSync = false,
    SnapshotListeners = {},
    ViewListeners = {},
    ToastListeners = {},
    LootListeners = {},
    Session = {
        redeemedCodes = {},
        weaponStars = {
            Dawnbringer = 2,
            dawnbringer_sword = 2,
            cursed_dual_skyblades = 3,
            noxar_abyssal_greatsword = 3,
            cryon_frostblade = 2,
            saber_of_aureon = 2,
            soul_guitar_void = 3,
            cryo_railgun = 2,
        },
        weaponStarPity = {},
        statPresets = {
            [1] = { NameKey = "skills.preset_1", Saved = false, Stats = { Melee = 60, Defense = 40, Sword = 1, Gun = 1, Fruit = 1 } },
            [2] = { NameKey = "skills.preset_2", Saved = false, Stats = { Melee = 25, Defense = 35, Sword = 65, Gun = 1, Fruit = 1 } },
            [3] = { NameKey = "skills.preset_3", Saved = false, Stats = { Melee = 20, Defense = 35, Sword = 1, Gun = 1, Fruit = 70 } },
        },
        lastBossCombatAt = 0,
        lastBossHp = nil,
        raidSimulationActive = false,
        inventoryPreviewMode = "Weapon",
    },
}

local function notify(list, payload)
    for _, callback in ipairs(list) do
        task.spawn(callback, payload)
    end
end

local function formatComma(n)
    local num = math.floor(tonumber(n) or 0)
    local s = tostring(math.abs(num))
    return s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

function Store.GetSnapshot()
    return Store.Snapshot
end

function Store.GetView()
    return Store.View
end

function Store.RecordBossCombat()
    Store.Session.lastBossCombatAt = os.clock()
end

function Store.PushLoot(entry)
    if type(entry) ~= "table" or not entry.Title then
        return
    end
    notify(Store.LootListeners, entry)
end

function Store.GetWeaponStar(itemId)
    local id = tostring(itemId or "")
    local snap = Store.Snapshot
    if snap and snap.weaponStars and tonumber(snap.weaponStars[id]) then
        return math.clamp(math.floor(tonumber(snap.weaponStars[id])), 1, 5)
    end
    if snap and snap.inventory then
        for _, inv in ipairs(snap.inventory) do
            if inv.itemId == id and tonumber(inv.stars) then
                return math.clamp(math.floor(tonumber(inv.stars)), 1, 5)
            end
        end
    end
    if snap and not snap.isDemoMode then
        return 1
    end
    return math.clamp(tonumber(Store.Session.weaponStars[id]) or 1, 1, 5)
end

function Store.GetWeaponStarPity(itemId)
    local id = tostring(itemId or "")
    local snap = Store.Snapshot
    if snap and snap.starPity and tonumber(snap.starPity[id]) then
        return math.clamp(math.floor(tonumber(snap.starPity[id])), 0, 100)
    end
    if snap and not snap.isDemoMode then
        return 0
    end
    return math.clamp(tonumber(Store.Session.weaponStarPity[id]) or 0, 0, 100)
end

function Store.SetServerSnapshot(rawOrNormalized, currentRealmAttr)
    local prev = Store.Snapshot
    local hadFirstSync = Store.HasReceivedInitialServerSync
    local nextSnap = UIState.NormalizeServerState(rawOrNormalized, currentRealmAttr)

    -- Track boss HP drop to automatically refresh 15s boss combat visibility grace (#6)
    if nextSnap.raid and nextSnap.raid.active and tonumber(nextSnap.raid.bossHp) then
        local curBossHp = tonumber(nextSnap.raid.bossHp)
        if Store.Session.lastBossHp and curBossHp < Store.Session.lastBossHp then
            Store.Session.lastBossCombatAt = os.clock()
        end
        Store.Session.lastBossHp = curBossHp
    end

    -- Automatic LootFeed deltas (#95)
    if hadFirstSync and prev and not nextSnap.isDemoMode then
        local prevCur = prev.currency or prev.currencies or {}
        local nextCur = nextSnap.currency or nextSnap.currencies or {}
        local prevGold = tonumber(prevCur.gold) or 0
        local nextGold = tonumber(nextCur.gold) or 0
        if nextGold > prevGold then
            Store.PushLoot({
                Category = "Gold",
                Title = "+" .. formatComma(nextGold - prevGold) .. " Gold",
                Subtitle = I18n.Pick("Chiến lợi phẩm", "Battle Reward"),
            })
        end

        local prevShards = tonumber(prevCur.coreShards) or 0
        local nextShards = tonumber(nextCur.coreShards) or 0
        if nextShards > prevShards then
            Store.PushLoot({
                Category = "Shards",
                Title = "+" .. formatComma(nextShards - prevShards) .. " Core Shards",
                Subtitle = I18n.Pick("Tinh thể Aether", "Aether Fragments"),
            })
        end

        local prevLv = tonumber(prev.player and prev.player.level) or 1
        local nextLv = tonumber(nextSnap.player and nextSnap.player.level) or 1
        local prevExp = tonumber(prev.player and prev.player.exp) or 0
        local nextExp = tonumber(nextSnap.player and nextSnap.player.exp) or 0
        if nextLv > prevLv then
            Store.PushLoot({
                Category = "EXP",
                Title = "LEVEL UP! Lv." .. tostring(nextLv),
                Subtitle = I18n.Pick("+3 Điểm Chỉ Số", "+3 Stat Points"),
            })
        elseif nextExp > prevExp then
            Store.PushLoot({
                Category = "EXP",
                Title = "+" .. formatComma(nextExp - prevExp) .. " EXP",
            })
        end

        -- New inventory items
        local prevCounts = {}
        for _, entry in ipairs(prev.inventory or {}) do
            prevCounts[entry.itemId] = tonumber(entry.count) or 0
        end
        for _, entry in ipairs(nextSnap.inventory or {}) do
            local delta = (tonumber(entry.count) or 0) - (prevCounts[entry.itemId] or 0)
            if delta > 0 then
                local disp = I18n.GetItemDisplayName(entry.itemId, entry.name or entry.itemId)
                Store.PushLoot({
                    Category = "Item",
                    Title = "+" .. tostring(delta) .. " " .. disp,
                    Subtitle = I18n.Pick("Nhận vật phẩm mới", "Obtained Item"),
                })
            end
        end
    end

    Store.Snapshot = nextSnap
    Store.HasReceivedInitialServerSync = true
    Store.LastServerSyncClock = os.clock()

    if not nextSnap.isDemoMode then
        local x2Sec = tonumber(nextSnap.doubleExpSeconds) or 0
        Store.Session.doubleExpUntilClock = (x2Sec > 0) and (os.clock() + x2Sec) or 0
        if type(nextSnap.redeemedCodes) == "table" then
            Store.Session.redeemedCodes = Store.Session.redeemedCodes or {}
            for codeKey, isUsed in pairs(nextSnap.redeemedCodes) do
                if isUsed then
                    Store.Session.redeemedCodes[codeKey] = true
                end
            end
        end
        if type(nextSnap.statPresets) == "table" then
            for slotKey, savedTbl in pairs(nextSnap.statPresets) do
                local sIdx = tonumber(slotKey)
                if sIdx and sIdx >= 1 and sIdx <= 3 and type(savedTbl) == "table" then
                    Store.Session.statPresets[sIdx] = Store.Session.statPresets[sIdx] or {}
                    Store.Session.statPresets[sIdx].Saved = true
                    Store.Session.statPresets[sIdx].Stats = {
                        Melee = 1 + (tonumber(savedTbl.Melee) or 0),
                        Defense = 1 + (tonumber(savedTbl.Defense) or 0),
                        Sword = 1 + (tonumber(savedTbl.Sword) or 0),
                        Gun = 1 + (tonumber(savedTbl.Gun) or 0),
                        Fruit = 1 + (tonumber(savedTbl.Fruit) or 0),
                    }
                end
            end
        end
    end

    local hasSelected = false
    for _, entry in ipairs(Store.Snapshot.inventory) do
        if entry.itemId == Store.View.selectedItemId then
            hasSelected = true
            break
        end
    end
    if not hasSelected and #Store.Snapshot.inventory > 0 then
        Store.View.selectedItemId = Store.Snapshot.inventory[1].itemId
    end

    notify(Store.SnapshotListeners, Store.Snapshot)
end

-- Local UI state mutation only (never mutates server currency/EXP/inventory)
function Store.SetView(partial)
    if type(partial) ~= "table" then
        return
    end
    for k, v in pairs(partial) do
        if type(v) == "table" and type(Store.View[k]) == "table" and k ~= "backStack" then
            for subK, subV in pairs(v) do
                Store.View[k][subK] = subV
            end
        else
            Store.View[k] = v
        end
    end
    notify(Store.ViewListeners, Store.View)
end

function Store.ShowToast(message, kind, duration)
    notify(Store.ToastListeners, {
        message = tostring(message or ""),
        kind = kind or "info",
        duration = duration or 2.8,
        timestamp = os.clock(),
    })
end

function Store.OpenModal(modalProps)
    Store.SetView({
        modal = {
            visible = true,
            title = modalProps.title or "CONFIRM ACTION",
            content = modalProps.content or "",
            confirmLabel = modalProps.confirmLabel or "CONFIRM",
            cancelLabel = modalProps.cancelLabel or "CANCEL",
            variant = modalProps.variant or "primary",
            onConfirm = modalProps.onConfirm,
            onCancel = modalProps.onCancel,
        },
    })
end

function Store.CloseModal()
    if type(Store.View.modal) == "table" then
        Store.View.modal.onConfirm = nil
        Store.View.modal.onCancel = nil
    end
    Store.SetView({
        modal = {
            visible = false,
        },
    })
end

function Store.ApplyDemoPreviewAction(action, payload)
    payload = payload or {}
    local snap = Store.Snapshot

    if action == "EquipItem" then
        local itemId = payload.itemId
        local itemCfg = RarityConfig.GetItem(itemId)
        if not itemCfg or not itemCfg.Slot then
            Store.ShowToast(I18n.Pick("Vật phẩm này không thể trang bị.", "This item cannot be equipped."), "warning")
            return false
        end
        local owned = false
        for _, entry in ipairs(snap.inventory) do
            if entry.itemId == itemId and entry.count > 0 then
                owned = true
                break
            end
        end
        if not owned then
            Store.ShowToast(I18n.Pick("Chưa sở hữu vật phẩm này.", "Item not owned in inventory."), "error")
            return false
        end
        if itemCfg.ClassId and itemCfg.ClassId ~= snap.player.classId then
            local cls = WorldConfig.Classes[itemCfg.ClassId]
            Store.ShowToast(I18n.Pick("Yêu cầu Hệ Phái: ", "Requires Class: ") .. (cls and cls.Name or itemCfg.ClassId), "warning")
            return false
        end
        local currentInSlot = snap.equipped[itemCfg.Slot]
        if currentInSlot == itemId then
            snap.equipped[itemCfg.Slot] = nil
            for _, entry in ipairs(snap.inventory) do
                if entry.itemId == itemId then entry.equipped = false end
            end
            Store.ShowToast(I18n.Pick("Đã tháo ", "Unequipped ") .. itemCfg.Name, "info")
        else
            snap.equipped[itemCfg.Slot] = itemId
            for _, entry in ipairs(snap.inventory) do
                if entry.itemId == currentInSlot then entry.equipped = false end
                if entry.itemId == itemId then entry.equipped = true end
            end
            Store.ShowToast(I18n.Pick("Đã trang bị ", "Equipped ") .. itemCfg.Name, "success")
        end
        notify(Store.SnapshotListeners, snap)
        return true

    elseif action == "SelectClass" then
        local classId = payload.classId
        local gender = payload.gender or snap.player.gender
        local cls = WorldConfig.Classes[classId]
        if not cls then return false end
        if classId == "ArcaneMage" and gender == "Female" then
            Store.ShowToast(cls.FemaleLockReason or "Female Arcane Mage not yet available.", "warning")
            return false
        end
        snap.player.classId = classId
        snap.player.gender = gender
        Store.SetView({ selectedClassTab = classId })
        Store.ShowToast(I18n.Pick("Đã chọn hệ phái ", "Switched class to ") .. cls.Name .. " (" .. gender .. ")", "success")
        notify(Store.SnapshotListeners, snap)
        return true

    elseif action == "ToggleRaidPreview" then
        local raidId = payload.raidId or Store.View.selectedRaidId or "Veyr"
        local raidCfg = WorldConfig.Raids[raidId] or WorldConfig.Raids.Veyr
        if Store.Session.raidSimulationActive and snap.raid.active and snap.raid.bossId == raidId and not payload.forcePhase then
            snap.raid.active = false
            Store.Session.raidSimulationActive = false
            Store.ShowToast(I18n.Pick("Đã tắt mô phỏng Boss HUD.", "Closed Raid HUD simulation."), "info")
        else
            local phase = payload.forcePhase or 1
            local ratio = 1 - ((phase - 1) * (1 / math.max(1, raidCfg.MaxPhases)))
            Store.Session.raidSimulationActive = true
            snap.raid = {
                active = true,
                bossId = raidId,
                bossName = raidCfg.Name,
                phase = phase,
                maxPhases = raidCfg.MaxPhases,
                bossHp = math.floor(raidCfg.MaxHP * math.clamp(ratio, 0.12, 1)),
                bossMaxHp = raidCfg.MaxHP,
                breakGauge = phase == 2 and 65 or 28,
                shield = (raidId == "AureonSentinel" and phase == 2),
                stunned = false,
                purificationReady = (raidId == "Noxar" and phase == 4),
            }
            Store.ShowToast(I18n.Pick("Đang xem thử Boss HUD: ", "Raid Boss HUD preview: ") .. raidCfg.Name, "info")
        end
        notify(Store.SnapshotListeners, snap)
        return true

    elseif action == "ForgeRecipe" then
        local outId = tostring(payload.itemId or "")
        if outId == "" then
            for _, r in ipairs(RarityConfig.Recipes or {}) do
                if r.Id == payload.recipeId then
                    outId = r.OutputItemId
                    break
                end
            end
        end
        if outId == "" then
            return false
        end
        local foundEntry = nil
        for _, entry in ipairs(snap.inventory or {}) do
            if entry.itemId == outId then
                foundEntry = entry
                break
            end
        end
        local disp = I18n.GetItemDisplayName(outId, outId)
        if not foundEntry or (foundEntry.count or 0) <= 0 then
            table.insert(snap.inventory, {
                itemId = outId,
                count = 1,
                upgrade = 0,
                equipped = false,
            })
            Store.ShowToast(I18n.Pick("Rèn thử thành công: ", "Demo forged: ") .. disp, "success")
        else
            foundEntry.upgrade = math.min(15, (tonumber(foundEntry.upgrade) or 0) + 1)
            Store.ShowToast(I18n.Pick("Cường hóa thử thành công: ", "Demo enhanced: ") .. disp .. " +" .. tostring(foundEntry.upgrade), "success")
        end
        notify(Store.SnapshotListeners, snap)
        return true
    end

    return false
end

function Store.SubscribeSnapshot(callback)
    table.insert(Store.SnapshotListeners, callback)
    return function()
        for i, fn in ipairs(Store.SnapshotListeners) do
            if fn == callback then
                table.remove(Store.SnapshotListeners, i)
                break
            end
        end
    end
end

function Store.SubscribeView(callback)
    table.insert(Store.ViewListeners, callback)
    return function()
        for i, fn in ipairs(Store.ViewListeners) do
            if fn == callback then
                table.remove(Store.ViewListeners, i)
                break
            end
        end
    end
end

function Store.SubscribeToast(callback)
    table.insert(Store.ToastListeners, callback)
    return function()
        for i, fn in ipairs(Store.ToastListeners) do
            if fn == callback then
                table.remove(Store.ToastListeners, i)
                break
            end
        end
    end
end

function Store.SubscribeLoot(callback)
    table.insert(Store.LootListeners, callback)
    return function()
        for i, fn in ipairs(Store.LootListeners) do
            if fn == callback then
                table.remove(Store.LootListeners, i)
                break
            end
        end
    end
end

return Store
