-- SKYBREAK: Fragments of the Core — Server Crafting & Forge Validation Service
-- Location: ServerScriptService/SkybreakServer/CraftingService.lua
-- Verifies recipe existence, player level, gold, and owned materials on the server without trusting client state.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local RarityConfig = require(Shared:WaitForChild("Config"):WaitForChild("RarityConfig"))
local CoreConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Services = script.Parent.Parent:WaitForChild("Services")
local PlayerDataService = require(Services:WaitForChild("PlayerDataService"))
local GameService = require(Services:WaitForChild("GameService"))

local CraftingService = {}

function CraftingService.HandleCraft(player, payload)
    if type(payload) ~= "table" or type(payload.recipeId) ~= "string" then
        return false, "Invalid craft request."
    end
    if not GameService.Rate(player, "UI_Craft", 0.6) then
        return false, "Forge is cooling down."
    end

    local profile = PlayerDataService.Get(player)
    if not profile then
        return false, "Profile not loaded."
    end
    profile.Inventory = type(profile.Inventory) == "table" and profile.Inventory or {}

    local recipe = nil
    for _, r in ipairs(RarityConfig.Recipes) do
        if r.Id == payload.recipeId then
            recipe = r
            break
        end
    end
    if not recipe then
        return false, "Unknown Forge recipe."
    end

    local shardCost = tonumber(recipe.CoreShardCost) or 0
    if profile.Level < (recipe.LevelReq or 1) then
        return false, string.format("Requires Level %d to forge %s.", recipe.LevelReq, recipe.Name)
    end
    if (tonumber(profile.Gold) or 0) < (recipe.GoldCost or 0) then
        return false, string.format("Insufficient Gold (%d / %d).", tonumber(profile.Gold) or 0, recipe.GoldCost or 0)
    end
    if shardCost > 0 and (tonumber(profile.CoreShards) or 0) < shardCost then
        return false, string.format("Insufficient Core Shards (%d / %d).", tonumber(profile.CoreShards) or 0, shardCost)
    end

    local outCfg = CoreConfig.Items[recipe.OutputItemId]
    if outCfg and outCfg.Slot ~= "Material" and outCfg.Slot ~= "Quest" and (tonumber(profile.Inventory[recipe.OutputItemId]) or 0) > 0 then
        return false, string.format("You already own %s. Use Enhance (+1..+15) or Star Ascension instead.", recipe.Name)
    end

    for _, mat in ipairs(recipe.Materials) do
        local owned = tonumber(profile.Inventory[mat.ItemId]) or 0
        if owned < mat.Count then
            return false, string.format("Missing required material: %s (%d / %d).", mat.ItemId, owned, mat.Count)
        end
    end

    -- Only mutate persistent Inventory keys that are registered in CoreConfig.Items to preserve schema validation
    if not outCfg then
        GameService.Notify(
            player,
            string.format("Kael: Materials verified for %s! Expansion weapon unlocks in Chapter II.", recipe.Name)
        )
        return true, "Materials verified by Kael's Forge (Expansion blueprint preview)."
    end

    for _, mat in ipairs(recipe.Materials) do
        profile.Inventory[mat.ItemId] -= mat.Count
        if profile.Inventory[mat.ItemId] <= 0 then
            profile.Inventory[mat.ItemId] = nil
        end
    end
    profile.Gold = math.max(0, (tonumber(profile.Gold) or 0) - (recipe.GoldCost or 0))
    if shardCost > 0 then
        profile.CoreShards = math.max(0, (tonumber(profile.CoreShards) or 0) - shardCost)
    end
    profile.Inventory[recipe.OutputItemId] = (tonumber(profile.Inventory[recipe.OutputItemId]) or 0) + (recipe.OutputCount or 1)

    task.spawn(PlayerDataService.Save, player, false)
    GameService.Sync(player)
    return true, "Forged " .. recipe.Name .. "!"
end

function CraftingService.HandleUpgrade(player, payload)
    if type(payload) ~= "table" or type(payload.itemId) ~= "string" then
        return false, "Invalid upgrade request."
    end
    if not GameService.Rate(player, "UI_Upgrade", 0.5) then
        return false, "Please wait before upgrading again."
    end

    local profile = PlayerDataService.Get(player)
    if not profile then
        return false, "Profile not loaded."
    end
    profile.Inventory = type(profile.Inventory) == "table" and profile.Inventory or {}

    local itemId = payload.itemId
    local itemCfg = RarityConfig.GetItem(itemId) or CoreConfig.Items[itemId]
    if not itemCfg then
        return false, "Unknown item."
    end
    if (tonumber(profile.Inventory and profile.Inventory[itemId]) or 0) <= 0 and profile.Weapon ~= itemId and profile.EquippedGun ~= itemId then
        return false, "You must forge or own this item before enhancing it."
    end

    local prevEnh = tonumber(profile.WeaponEnhance) or 0
    if prevEnh >= 15 then
        return false, "Maximum enhance level (+15) already reached."
    end
    local reqGold = 100
    if (tonumber(profile.Gold) or 0) < reqGold then
        return false, string.format("Insufficient Gold (%d / %d).", tonumber(profile.Gold) or 0, reqGold)
    end
    local matsOwned = (tonumber(profile.Inventory.upgrade_material) or 0) + (tonumber(profile.Inventory.SkyIron) or 0)
    if matsOwned < 1 then
        return false, "Need 1 Luminous Alloy (upgrade_material) or Sky Iron to enhance."
    end

    GameService.Equipment(player, { action = "ForgeEnhance", itemId = itemId })
    task.spawn(PlayerDataService.Save, player, false)
    local afterEnh = tonumber(profile.WeaponEnhance) or prevEnh
    if afterEnh > prevEnh then
        return true, string.format("Enhanced %s to +%d!", itemCfg.Name or itemId, afterEnh)
    end
    return true, string.format("Enhance attempt recorded (Pity: %d%%/100%%).", tonumber(profile.EnhancePity) or 0)
end

return CraftingService
