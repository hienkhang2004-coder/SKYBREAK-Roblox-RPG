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

    if profile.Level < (recipe.LevelReq or 1) then
        return false, string.format("Requires Level %d to forge %s.", recipe.LevelReq, recipe.Name)
    end
    if profile.Gold < (recipe.GoldCost or 0) then
        return false, string.format("Insufficient Gold (%d / %d).", profile.Gold, recipe.GoldCost)
    end

    for _, mat in ipairs(recipe.Materials) do
        local owned = tonumber(profile.Inventory[mat.ItemId]) or 0
        if owned < mat.Count then
            return false, string.format("Missing required material: %s (%d / %d).", mat.ItemId, owned, mat.Count)
        end
    end

    -- Only mutate persistent Inventory keys that are registered in CoreConfig.Items to preserve schema validation
    if not CoreConfig.Items[recipe.OutputItemId] then
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
    profile.Gold -= (recipe.GoldCost or 0)
    profile.Inventory[recipe.OutputItemId] = (profile.Inventory[recipe.OutputItemId] or 0) + (recipe.OutputCount or 1)

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

    local itemCfg = RarityConfig.GetItem(payload.itemId)
    if not itemCfg then
        return false, "Unknown item."
    end

    local cost = RarityConfig.GetUpgradeCost(payload.itemId, 0)
    if profile.Gold < cost.GoldCost then
        return false, string.format("Insufficient Gold (%d / %d).", profile.Gold, cost.GoldCost)
    end
    local matsOwned = tonumber(profile.Inventory.upgrade_material) or 0
    if matsOwned < cost.MaterialCount then
        return false, string.format("Need %d Luminous Alloy (upgrade_material).", cost.MaterialCount)
    end

    GameService.Notify(player, string.format("Kael: %s tempering validated.", itemCfg.Name))
    return true, "Upgrade materials verified by server."
end

return CraftingService
