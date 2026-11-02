-- SKYBREAK: Fragments of the Core — Server Realm Fast Travel Validation Service
-- Location: ServerScriptService/SkybreakServer/TravelService.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local WorldConfig = require(Shared:WaitForChild("Config"):WaitForChild("WorldConfig"))
local RealmConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RealmConfig"))
local CoreConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Services = script.Parent.Parent:WaitForChild("Services")
local PlayerDataService = require(Services:WaitForChild("PlayerDataService"))
local GameService = require(Services:WaitForChild("GameService"))

local TravelService = {}

function TravelService.HandleFastTravel(player, payload)
    if type(payload) ~= "table" or type(payload.realmId) ~= "string" then
        return false, "Invalid travel request."
    end
    if not GameService.Rate(player, "UI_Travel", 1.0) then
        return false, "Please wait before traveling again."
    end

    local profile = PlayerDataService.Get(player)
    if not profile then
        return false, "Profile not loaded."
    end

    if (GameService.Boss and GameService.Boss.Party and GameService.Boss.Party[player])
        or player:GetAttribute("InTrade") == true
        or player:GetAttribute("InRaceTrial") == true
        or player:GetAttribute("RaidActive") == true
        or player:GetAttribute("InColosseum") == true
        or player:GetAttribute("ColosseumActive") == true
        or (tonumber(player:GetAttribute("SpireFloor")) or 0) > 0
    then
        return false, "Cannot Fast Travel during an active encounter or trade."
    end

    local realmId = payload.realmId
    if #realmId > 48 then
        return false, "Invalid destination ID."
    end
    if realmId == "SkyHub" or realmId == "GoldenSky" then
        player:SetAttribute("CurrentRealm", "GoldenSky")
        GameService.Teleport(player, CoreConfig.Spawn)
        GameService.Sync(player)
        return true, "Traveled to Golden Sky Hub."
    end

    local islandMeta = WorldConfig.IslandById and WorldConfig.IslandById[realmId]
    local realmMeta = WorldConfig.RealmById[realmId] or islandMeta
    if not realmMeta then
        return false, "Unknown realm."
    end

    local parentRealmId = (islandMeta and islandMeta.RealmId) or realmId
    local parentRealmMeta = WorldConfig.RealmById and WorldConfig.RealmById[parentRealmId]
    profile.UnlockedWorlds = profile.UnlockedWorlds or {}
    local minLv = tonumber(
        realmMeta.MinLevel
        or realmMeta.LevelReq
        or (islandMeta and (islandMeta.MinLevel or islandMeta.LevelReq))
        or (parentRealmMeta and (parentRealmMeta.MinLevel or parentRealmMeta.LevelReq))
    ) or 1
    local alreadyUnlocked = (profile.UnlockedWorlds[realmId] == true)
        or (profile.UnlockedWorlds[parentRealmId] == true)
        or (workspace:GetAttribute("EnableDevSandbox") == true)
    if not alreadyUnlocked and (tonumber(profile.Level) or 1) < minLv then
        return false, string.format("Requires Level %d to unlock %s.", minLv, tostring(realmMeta.Name or realmId))
    end
    profile.UnlockedWorlds[realmId] = true
    profile.UnlockedWorlds[parentRealmId] = true

    local ftNode = CoreConfig.FastTravel and CoreConfig.FastTravel[realmId]
    local realmCoords = RealmConfig[realmId] or RealmConfig[parentRealmId]
    local targetSpawn = (ftNode and ftNode.Pos) or (islandMeta and islandMeta.Pos) or (realmCoords and realmCoords.Spawn)
    if not targetSpawn then
        return false, realmMeta.Name .. " geometry is not loaded in this server instance."
    end

    player:SetAttribute("CurrentRealm", parentRealmId)
    GameService.Teleport(player, targetSpawn)
    GameService.Sync(player)
    return true, "Traveled to " .. realmMeta.Name .. "."
end

return TravelService
