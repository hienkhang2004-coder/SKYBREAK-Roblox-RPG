-- SKYBREAK: Fragments of the Core — Server Inventory & Equipment Validation Service
-- Location: ServerScriptService/SkybreakServer/InventoryService.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local RarityConfig = require(Shared:WaitForChild("Config"):WaitForChild("RarityConfig"))

local Services = script.Parent.Parent:WaitForChild("Services")
local PlayerDataService = require(Services:WaitForChild("PlayerDataService"))
local GameService = require(Services:WaitForChild("GameService"))

local InventoryService = {}

local GUN_IDS = {
    aether_flintlock = true,
    solar_kabucha = true,
    cryo_railgun = true,
    soul_guitar_void = true,
    kabucha_wind = true,
    bizarre_rifle_cyber = true,
    sylvaris_thornbow = true,
    ignivar_hellcannon = true,
    aion_chrono_pistols = true,
    veyr_singularity_cannon = true,
}

local SLOT_MAP = {
    Helm = "Helmet",
    Gauntlets = "Gloves",
    Greaves = "Boots",
    Offhand = "Necklace",
}

local function isGunItem(itemId, itemCfg)
    if type(itemId) == "string" and GUN_IDS[itemId] then
        return true
    end
    if type(itemCfg) == "table" then
        if itemCfg.Slot == "Gun" or itemCfg.WeaponType == "Gun" or itemCfg.Icon == "Gun" then
            return true
        end
    end
    return false
end

function InventoryService.HandleEquip(player, payload)
    if type(payload) ~= "table" then
        return false, "Invalid request payload."
    end
    if not GameService.Rate(player, "UI_Equip", 0.15) then
        return false, "Action rate-limited."
    end

    local profile = PlayerDataService.Get(player)
    if not profile then
        return false, "Player profile not loaded."
    end

    local itemId = payload.itemId
    local unequip = payload.unequip == true
    if unequip then
        local eqCfg = type(itemId) == "string" and RarityConfig.GetItem(itemId) or nil
        local isGun = (payload.slot == "Gun")
            or isGunItem(itemId, eqCfg)
            or (type(itemId) == "string" and profile.EquippedGun == itemId)
        local targetSlot = payload.slot
            or (isGun and "Gun")
            or (eqCfg and (SLOT_MAP[eqCfg.Slot] or eqCfg.Slot))
            or "Weapon"
        GameService.Equipment(player, { action = "Unequip", itemId = itemId, slot = targetSlot })
        return true, "Unequipped item."
    end

    if type(itemId) ~= "string" or #itemId > 48 then
        return false, "Invalid item identifier."
    end

    local itemCfg = RarityConfig.GetItem(itemId)
    if not itemCfg or not itemCfg.Slot then
        return false, "Item is not equippable."
    end

    local ownedCount = tonumber(profile.Inventory and profile.Inventory[itemId]) or 0
    if ownedCount <= 0 then
        return false, "You do not own this item."
    end

    if isGunItem(itemId, itemCfg) then
        profile.Equipped = type(profile.Equipped) == "table" and profile.Equipped or {}
        profile.Equipped.Offhand = itemId
        profile.Equipped.Necklace = itemId
        GameService.Equipment(player, { action = "EquipGun", gunId = itemId })
        return true, "Equipped " .. (itemCfg.VietnameseName or itemCfg.Name or itemId)
    end
    local serverSlot = SLOT_MAP[itemCfg.Slot] or itemCfg.Slot
    GameService.Equipment(player, { action = "Equip", itemId = itemId, slot = serverSlot })
    return true, "Equipped " .. (itemCfg.VietnameseName or itemCfg.Name or itemId)
end

return InventoryService
