-- SKYBREAK: Fragments of the Core — Server Realm & Island Fast Travel Validation Service
-- Location: ServerScriptService/SkybreakServer/TravelService.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local WorldConfig = require(Shared:WaitForChild("Config"):WaitForChild("WorldConfig"))
local RealmConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RealmConfig"))
local CoreConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local Services = script.Parent.Parent:WaitForChild("Services")
local PlayerDataService = require(Services:WaitForChild("PlayerDataService"))
local GameService = require(Services:WaitForChild("GameService"))
local DevGate = require(Services:WaitForChild("DevGate"))

local TravelService = {}

local DEST_ALIASES = {
    QuestCheckpoint = "GoldenSky",
    GlacialDangerSea = "GlacialWreckage",
    UmbralCrystalForest = "UmbralSanctum",
    EmberforgeWestFoundry = "EmberWestFoundry",
    EmberforgeEastCaldera = "EmberEastCaldera",
    EmberforgeNorthCitadel = "EmberNorthCitadel",
}

local function extractDestinationId(payload)
    if type(payload) == "string" then
        return DEST_ALIASES[payload] or payload
    end
    if type(payload) ~= "table" then
        return nil
    end
    local raw = payload.islandId or payload.nodeId or payload.realmId or payload.id or payload.value
    if type(raw) ~= "string" or raw == "" or #raw > 48 then
        return nil
    end
    return DEST_ALIASES[raw] or raw
end

function TravelService.CanFastTravel(player, payload)
    local destId = extractDestinationId(payload)
    if not destId then
        return false, "Yêu cầu dịch chuyển không hợp lệ."
    end
    local profile = PlayerDataService.Get(player)
    if not profile then
        return false, "Dữ liệu nhân vật chưa sẵn sàng."
    end
    if (GameService.Boss and GameService.Boss.Party and GameService.Boss.Party[player])
        or player:GetAttribute("InTrade") == true
        or player:GetAttribute("InRaceTrial") == true
        or player:GetAttribute("RaidActive") == true
        or player:GetAttribute("InColosseum") == true
        or player:GetAttribute("ColosseumActive") == true
        or (tonumber(player:GetAttribute("SpireFloor")) or 0) > 0
    then
        return false, "Không thể Dịch Chuyển Nhanh khi đang giao tranh Boss, Đột Kích, Tháp hoặc Giao Dịch!"
    end

    profile.DiscoveredIslands = type(profile.DiscoveredIslands) == "table" and profile.DiscoveredIslands or { SkyHub = true, GoldenSky = true }
    profile.DiscoveredIslands.SkyHub = true
    profile.DiscoveredIslands.GoldenSky = true

    if destId == "SkyHub" or destId == "GoldenSky" then
        return true, nil, destId
    end

    local coreIsl = (CoreConfig.FastTravel and CoreConfig.FastTravel[destId]) or (CoreConfig.Islands and CoreConfig.Islands[destId])
    local islandMeta = WorldConfig.IslandById and WorldConfig.IslandById[destId]
    local realmMeta = WorldConfig.RealmById and WorldConfig.RealmById[destId]
    if not coreIsl and not islandMeta and not realmMeta then
        return false, "Không tìm thấy đảo hoặc cõi đích."
    end

    local parentRealmId = (coreIsl and coreIsl.Realm)
        or (islandMeta and islandMeta.RealmId)
        or (realmMeta and realmMeta.Id)
        or "GoldenSky"
    local sea = tonumber(coreIsl and coreIsl.Sea)
        or (parentRealmId == "GoldenSky" and 1)
        or (parentRealmId == "FrozenCyber" and 2)
        or (parentRealmId == "ShadowRealm" and 3)
        or 4
    local islMinLv = tonumber(
        (coreIsl and coreIsl.MinLevel)
        or (islandMeta and (islandMeta.MinLevel or islandMeta.LevelReq))
        or (realmMeta and (realmMeta.MinLevel or realmMeta.LevelReq))
    ) or 1

    local reqLv = 1
    if sea == 2 or parentRealmId == "FrozenCyber" then
        reqLv = 700
    elseif sea == 3 or parentRealmId == "ShadowRealm" then
        reqLv = 1500
    elseif sea >= 4 then
        reqLv = islMinLv
    end

    local isDev = DevGate.IsAllowed(player)
    local isDiscovered = (profile.DiscoveredIslands[destId] == true)
    local playerLv = tonumber(profile.Level) or 1

    if not isDev and (not isDiscovered or playerLv < reqLv) then
        local displayLv = math.max(reqLv, islMinLv)
        local lockMsg = string.format(
            "Hãy lái Tàu Bay khám phá đảo này trước hoặc đạt Lv. %d để mở khóa Dịch Chuyển Nhanh!",
            displayLv
        )
        return false, lockMsg, destId
    end

    return true, nil, destId, parentRealmId, coreIsl, islandMeta, realmMeta
end

function TravelService.HandleFastTravel(player, payload)
    if not GameService.Rate(player, "UI_Travel", 1.0) then
        return false, "Vui lòng chờ giây lát trước khi dịch chuyển tiếp."
    end

    local allowed, lockMsg, destId, parentRealmId, coreIsl, islandMeta, realmMeta = TravelService.CanFastTravel(player, payload)
    if not allowed then
        if lockMsg and GameService.Notify then
            GameService.Notify(player, lockMsg)
        end
        return false, lockMsg
    end

    local profile = PlayerDataService.Get(player)
    if destId == "SkyHub" or destId == "GoldenSky" then
        local hubPos = (destId == "GoldenSky" and CoreConfig.FastTravel and CoreConfig.FastTravel.GoldenSky and CoreConfig.FastTravel.GoldenSky.Pos)
            or CoreConfig.Spawn
        player:SetAttribute("CurrentRealm", "GoldenSky")
        player:SetAttribute("CurrentIsland", destId)
        GameService.Teleport(player, hubPos)
        GameService.Sync(player)
        return true, "Đã dịch chuyển tới " .. (destId == "GoldenSky" and "Bầu Trời Hoàng Kim" or "Sky Hub") .. "!"
    end

    parentRealmId = parentRealmId or "GoldenSky"
    if profile then
        profile.UnlockedWorlds = type(profile.UnlockedWorlds) == "table" and profile.UnlockedWorlds or {}
        profile.UnlockedWorlds[destId] = true
        profile.UnlockedWorlds[parentRealmId] = true
        profile.DiscoveredIslands[destId] = true
    end

    local realmCoords = RealmConfig[destId] or RealmConfig[parentRealmId]
    local targetSpawn = (coreIsl and coreIsl.Pos)
        or (islandMeta and islandMeta.Pos)
        or (realmCoords and realmCoords.Spawn)
    if not targetSpawn then
        local label = (islandMeta and (islandMeta.VietnameseName or islandMeta.Name))
            or (realmMeta and (realmMeta.VietnameseName or realmMeta.Name))
            or destId
        return false, tostring(label) .. " chưa sẵn sàng trong máy chủ này."
    end

    player:SetAttribute("CurrentRealm", parentRealmId)
    player:SetAttribute("CurrentIsland", destId)
    GameService.Teleport(player, targetSpawn)
    GameService.Sync(player)
    local destLabel = (islandMeta and (islandMeta.VietnameseName or islandMeta.Name))
        or (realmMeta and (realmMeta.VietnameseName or realmMeta.Name))
        or (coreIsl and coreIsl.Name)
        or destId
    return true, "Đã dịch chuyển tới " .. tostring(destLabel) .. "!"
end

return TravelService
