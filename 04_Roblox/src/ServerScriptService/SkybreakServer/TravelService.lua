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

    if GameService.Boss and GameService.Boss.Party and GameService.Boss.Party[player] then
        return false, "Cannot Fast Travel during an active Boss Encounter."
    end

    local realmId = payload.realmId
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
    profile.UnlockedWorlds = profile.UnlockedWorlds or {}
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
