-- SKYBREAK: Fragments of the Core — Server Inventory & Equipment Validation Service
-- Location: ServerScriptService/SkybreakServer/InventoryService.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local RarityConfig = require(Shared:WaitForChild("Config"):WaitForChild("RarityConfig"))

local Services = script.Parent.Parent:WaitForChild("Services")
local PlayerDataService = require(Services:WaitForChild("PlayerDataService"))
local GameService = require(Services:WaitForChild("GameService"))

local InventoryService = {}

function InventoryService.HandleEquip(player, payload)
    if type(payload) ~= "table" then
        return false, "Invalid request payload."
    end
    if not GameService.Rate(player, "UI_Equip", 0.3) then
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
        GameService.Equipment(player, { action = "Unequip", itemId = itemId, slot = payload.slot or (eqCfg and eqCfg.Slot) or "Weapon" })
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

    if itemCfg.LevelReq and profile.Level < itemCfg.LevelReq then
        return false, string.format("Requires Level %d.", itemCfg.LevelReq)
    end

    if itemCfg.ClassId and itemCfg.ClassId ~= profile.ClassId then
        return false, "Item belongs to a different Class."
    end

    local slotMap = {
        Helm = "Helmet",
        Gauntlets = "Gloves",
        Greaves = "Boots",
        Offhand = "Necklace",
    }
    if itemId == "aether_flintlock" or itemId == "solar_kabucha" or itemId == "cryo_railgun" or itemId == "soul_guitar_void" then
        GameService.Equipment(player, { action = "EquipGun", gunId = itemId })
        return true, "Equipped " .. itemCfg.Name
    end
    local serverSlot = slotMap[itemCfg.Slot] or itemCfg.Slot
    GameService.Equipment(player, { action = "Equip", itemId = itemId, slot = serverSlot })
    return true, "Equipped " .. itemCfg.Name
end

return InventoryService
