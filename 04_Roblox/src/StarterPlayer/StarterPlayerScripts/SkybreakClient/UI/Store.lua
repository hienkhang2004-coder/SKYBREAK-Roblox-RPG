-- SKYBREAK: Fragments of the Core — Reactive Client UI Store
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Store.lua
-- Strictly separates server-authoritative PlayerSnapshot from local ViewState (Section 07).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local UIState = require(Shared:WaitForChild("Types"):WaitForChild("UIState"))
local RarityConfig = require(Shared:WaitForChild("Config"):WaitForChild("RarityConfig"))
local WorldConfig = require(Shared:WaitForChild("Config"):WaitForChild("WorldConfig"))

local Store = {
    Snapshot = UIState.CreateDefaultSnapshot(true),
    View = UIState.CreateDefaultViewState(),
    LastServerSyncClock = os.clock(),
    SnapshotListeners = {},
    ViewListeners = {},
    ToastListeners = {},
}

local function notify(list, payload)
    for _, callback in ipairs(list) do
        task.spawn(callback, payload)
    end
end

function Store.GetSnapshot()
    return Store.Snapshot
end

function Store.GetView()
    return Store.View
end

function Store.SetServerSnapshot(rawOrNormalized, currentRealmAttr)
    Store.Snapshot = UIState.NormalizeServerState(rawOrNormalized, currentRealmAttr)
    Store.LastServerSyncClock = os.clock()

    -- Ensure selectedItemId points to a valid owned or starter item
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
    Store.SetView({
        modal = {
            visible = false,
            onConfirm = nil,
            onCancel = nil,
        },
    })
end

-- Explicitly labeled Demo Mode preview mutations when no live server remote handles an expansion feature
-- Never runs silently if Snapshot.isDemoMode is false unless fallbackDemo is explicitly requested for unimplemented server features.
function Store.ApplyDemoPreviewAction(action, payload)
    payload = payload or {}
    local snap = Store.Snapshot

    if action == "EquipItem" then
        local itemId = payload.itemId
        local itemCfg = RarityConfig.GetItem(itemId)
        if not itemCfg or not itemCfg.Slot then
            Store.ShowToast("This item cannot be equipped.", "warning")
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
            Store.ShowToast("Cannot equip: Item not owned in inventory.", "error")
            return false
        end
        if itemCfg.ClassId and itemCfg.ClassId ~= snap.player.classId then
            local cls = WorldConfig.Classes[itemCfg.ClassId]
            Store.ShowToast("Requires Class: " .. (cls and cls.Name or itemCfg.ClassId), "warning")
            return false
        end
        local currentInSlot = snap.equipped[itemCfg.Slot]
        if currentInSlot == itemId then
            snap.equipped[itemCfg.Slot] = nil
            for _, entry in ipairs(snap.inventory) do
                if entry.itemId == itemId then entry.equipped = false end
            end
            Store.ShowToast("[DEMO] Unequipped " .. itemCfg.Name, "info")
        else
            snap.equipped[itemCfg.Slot] = itemId
            for _, entry in ipairs(snap.inventory) do
                if entry.itemId == currentInSlot then entry.equipped = false end
                if entry.itemId == itemId then entry.equipped = true end
            end
            Store.ShowToast("[DEMO] Equipped " .. itemCfg.Name, "success")
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
        Store.ShowToast("[DEMO] Switched preview class to " .. cls.Name .. " (" .. gender .. ")", "success")
        notify(Store.SnapshotListeners, snap)
        return true

    elseif action == "ToggleRaidPreview" then
        local raidId = payload.raidId or Store.View.selectedRaidId or "Veyr"
        local raidCfg = WorldConfig.Raids[raidId] or WorldConfig.Raids.Veyr
        if snap.raid.active and snap.raid.bossId == raidId and not payload.forcePhase then
            snap.raid.active = false
            Store.ShowToast("Closed Raid HUD simulation.", "info")
        else
            local phase = payload.forcePhase or 1
            local ratio = 1 - ((phase - 1) * (1 / math.max(1, raidCfg.MaxPhases)))
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
            Store.ShowToast("[DEMO] Raid Boss HUD active: " .. raidCfg.Name .. " (Phase " .. phase .. ")", "info")
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

return Store
