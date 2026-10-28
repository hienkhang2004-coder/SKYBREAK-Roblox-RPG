-- SKYBREAK: Fragments of the Core — Authoritative Server UI Command Router
-- Location: ServerScriptService/SkybreakServer/UIRequestHandler.server.lua
-- Sets up ReplicatedStorage/SkybreakShared/Remotes and validates all client UI commands.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local sharedRemotes = Shared:FindFirstChild("Remotes") or Instance.new("Folder")
sharedRemotes.Name = "Remotes"
sharedRemotes.Parent = Shared

local getSnapshotFn = sharedRemotes:FindFirstChild("GetPlayerSnapshot") or Instance.new("RemoteFunction")
getSnapshotFn.Name = "GetPlayerSnapshot"
getSnapshotFn.Parent = sharedRemotes

local uiCommandEvent = sharedRemotes:FindFirstChild("UICommand") or Instance.new("RemoteEvent")
uiCommandEvent.Name = "UICommand"
uiCommandEvent.Parent = sharedRemotes

local uiStateUpdatedEvent = sharedRemotes:FindFirstChild("UIStateUpdated") or Instance.new("RemoteEvent")
uiStateUpdatedEvent.Name = "UIStateUpdated"
uiStateUpdatedEvent.Parent = sharedRemotes

-- Also mirror UICommand under ReplicatedStorage.Remotes for convenience
local legacyRemotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
legacyRemotes.Name = "Remotes"
legacyRemotes.Parent = ReplicatedStorage
local legacyUICmd = legacyRemotes:FindFirstChild("UICommand") or Instance.new("RemoteEvent")
legacyUICmd.Name = "UICommand"
legacyUICmd.Parent = legacyRemotes

local InventoryService = require(script.Parent:WaitForChild("InventoryService"))
local SkillService = require(script.Parent:WaitForChild("SkillService"))
local QuestService = require(script.Parent:WaitForChild("QuestService"))
local TravelService = require(script.Parent:WaitForChild("TravelService"))
local CraftingService = require(script.Parent:WaitForChild("CraftingService"))

local Services = script.Parent.Parent:WaitForChild("Services")
local GameService = require(Services:WaitForChild("GameService"))

local function handleCommand(player, payload)
    if type(payload) ~= "table" or type(payload.command) ~= "string" then
        return
    end
    local cmd = payload.command
    local ok, message = false, "Unknown command."

    if cmd == "EquipItem" then
        ok, message = InventoryService.HandleEquip(player, payload)
    elseif cmd == "SelectClass" then
        ok, message = SkillService.HandleClassSwitch(player, payload)
    elseif cmd == "TrackQuest" then
        ok, message = QuestService.HandleTrackQuest(player, payload)
    elseif cmd == "FastTravel" then
        ok, message = TravelService.HandleFastTravel(player, payload)
    elseif cmd == "CraftRecipe" then
        ok, message = CraftingService.HandleCraft(player, payload)
    elseif cmd == "UpgradeItem" then
        ok, message = CraftingService.HandleUpgrade(player, payload)
    end

    if message then
        uiStateUpdatedEvent:FireClient(player, {
            Toast = {
                message = message,
                kind = ok and "success" or "warning",
            },
        })
    end
end

uiCommandEvent.OnServerEvent:Connect(handleCommand)
legacyUICmd.OnServerEvent:Connect(handleCommand)

getSnapshotFn.OnServerInvoke = function(player)
    GameService.Sync(player)
    return nil
end
