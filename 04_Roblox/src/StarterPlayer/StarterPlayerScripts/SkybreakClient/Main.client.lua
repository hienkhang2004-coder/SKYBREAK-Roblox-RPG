-- SKYBREAK: Fragments of the Core — Modular Client UI Bootstrap
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/Main.client.lua
-- Initializes the modular SkybreakUI system and connects to server remotes when present.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIFolder = script.Parent:WaitForChild("UI")
local App = require(UIFolder:WaitForChild("App"))
local Store = require(UIFolder:WaitForChild("Store"))

-- Initialize the ScreenGui & modular router (Idempotent if already initialized by ClientBootstrap)
App.Init()

-- Listen for optional SkybreakShared Remotes (UIStateUpdated / GetPlayerSnapshot)
task.spawn(function()
    local shared = ReplicatedStorage:WaitForChild("SkybreakShared", 5)
    local sharedRemotes = shared and shared:FindFirstChild("Remotes")
    if sharedRemotes then
        local stateUpdated = sharedRemotes:FindFirstChild("UIStateUpdated")
        if stateUpdated and stateUpdated:IsA("RemoteEvent") then
            stateUpdated.OnClientEvent:Connect(function(payload)
                if type(payload) == "table" then
                    if payload.State then
                        App.SetState(payload.State)
                    end
                    if payload.Toast then
                        Store.ShowToast(payload.Toast.message or payload.Toast, payload.Toast.kind or "info")
                    end
                end
            end)
        end

        local getSnapshot = sharedRemotes:FindFirstChild("GetPlayerSnapshot")
        if getSnapshot and getSnapshot:IsA("RemoteFunction") then
            local ok, snapshot = pcall(function()
                return getSnapshot:InvokeServer()
            end)
            if ok and type(snapshot) == "table" then
                App.SetState(snapshot)
            end
        end
    end

    -- Also listen to legacy ReplicatedStorage.Remotes.StateUpdate if ClientBootstrap hasn't already
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        local stateUpdate = remotes:FindFirstChild("StateUpdate")
        if stateUpdate and stateUpdate:IsA("RemoteEvent") then
            stateUpdate.OnClientEvent:Connect(function(payload)
                if type(payload) == "table" and payload.State and not App.State then
                    App.SetState(payload.State)
                end
            end)
        end
    end

    local player = Players.LocalPlayer
    if player then
        player:GetAttributeChangedSignal("CurrentRealm"):Connect(function()
            local realm = player:GetAttribute("CurrentRealm")
            if realm then
                local snap = Store.GetSnapshot()
                snap.world.current = realm
                App.Render()
            end
        end)
    end
end)
