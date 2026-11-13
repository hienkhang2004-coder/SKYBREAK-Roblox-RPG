-- SKYBREAK: Fragments of the Core — Modular Client UI Bootstrap
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/Main.client.lua
-- Initializes the modular SkybreakUI system and connects to server remotes when present.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIFolder = script.Parent:WaitForChild("UI")
local App = require(UIFolder:WaitForChild("App"))
local Store = require(UIFolder:WaitForChild("Store"))
local ScreenRouter = require(UIFolder:WaitForChild("ScreenRouter"))

-- Initialize the ScreenGui & modular router (Idempotent if already initialized by ClientBootstrap)
App.Init()

local PARTIAL_STATE_KEYS = {
    "CrewData",
    "PartyData",
    "DailyLogin",
    "DailyBounties",
    "DailyTasks",
    "P2PTrade",
    "DiscoveredIslands",
    "RaidChipsCleared",
    "MicrochipRaidsCleared",
    "HighestSpireFloor",
    "MaxEnergy",
    "ClassChosen",
    "MeleeATK",
    "SwordATK",
    "GunATK",
    "FruitATK",
    "RaceTier",
}

local lastTradeAutoOpenKey = ""

local function hasAnyPartialKey(tbl)
    if type(tbl) ~= "table" then
        return false
    end
    for _, k in ipairs(PARTIAL_STATE_KEYS) do
        if tbl[k] ~= nil then
            return true
        end
    end
    return false
end

local function maybeAutoOpenP2PTrade(p2p)
    if type(p2p) ~= "table" then
        return
    end
    if p2p.Active == true then
        local sessionKey = tostring(p2p.SessionId or p2p.PartnerName or "active")
        if lastTradeAutoOpenKey ~= sessionKey then
            lastTradeAutoOpenKey = sessionKey
            Store.SetView({ activeVendorMode = "TradingTable" })
            ScreenRouter.Navigate("NPCShop", { forceRebuild = true })
        end
    else
        lastTradeAutoOpenKey = ""
    end
end

-- Listen for optional SkybreakShared Remotes (UIStateUpdated / GetPlayerSnapshot)
task.spawn(function()
    local player = Players.LocalPlayer
    local shared = ReplicatedStorage:WaitForChild("SkybreakShared", 5)
    local sharedRemotes = shared and shared:FindFirstChild("Remotes")
    if sharedRemotes then
        local stateUpdated = sharedRemotes:FindFirstChild("UIStateUpdated")
        if stateUpdated and stateUpdated:IsA("RemoteEvent") then
            stateUpdated.OnClientEvent:Connect(function(payload)
                if type(payload) ~= "table" then
                    return
                end
                if payload.State then
                    App.SetState(payload.State)
                    if type(payload.State) == "table" and type(payload.State.P2PTrade) == "table" then
                        maybeAutoOpenP2PTrade(payload.State.P2PTrade)
                    end
                end
                if hasAnyPartialKey(payload) then
                    Store.MergePartialServerState(payload)
                    if type(payload.P2PTrade) == "table" then
                        maybeAutoOpenP2PTrade(payload.P2PTrade)
                    end
                end
                if type(payload.OpenVendorMode or payload.ActiveVendorMode) == "string" then
                    Store.SetView({ activeVendorMode = payload.OpenVendorMode or payload.ActiveVendorMode })
                end
                if type(payload.Equipped) == "table" then
                    local snap = Store.GetSnapshot()
                    if snap then
                        snap.equipped = payload.Equipped
                        App.Render()
                    end
                end
                if type(payload.Faction) == "string" then
                    local snap = Store.GetSnapshot()
                    if snap and snap.fruits then
                        snap.fruits.faction = payload.Faction
                        App.Render()
                    end
                end
                if type(payload.Dialogue) == "table" then
                    App.OpenDialogue(payload.Dialogue)
                elseif type(payload.Choices) == "table" and (payload.Speaker or payload.speaker or payload.Text or payload.text) then
                    App.OpenDialogue(payload)
                end
                if payload.Toast then
                    Store.ShowToast(payload.Toast.message or payload.Toast, payload.Toast.kind or "info")
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

    -- Also listen to ReplicatedStorage.Remotes (StateUpdate & TradeAction)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:WaitForChild("Remotes", 5)
    if remotes then
        local stateUpdate = remotes:FindFirstChild("StateUpdate")
        if stateUpdate and stateUpdate:IsA("RemoteEvent") then
            stateUpdate.OnClientEvent:Connect(function(payload)
                if type(payload) ~= "table" then
                    return
                end
                if type(payload.State) == "table" then
                    Store.CaptureServerExtras(payload.State)
                    if type(payload.State.P2PTrade) == "table" then
                        maybeAutoOpenP2PTrade(payload.State.P2PTrade)
                    end
                    if not App.State then
                        App.SetState(payload.State)
                    end
                end
                if hasAnyPartialKey(payload) then
                    Store.MergePartialServerState(payload)
                    if type(payload.P2PTrade) == "table" then
                        maybeAutoOpenP2PTrade(payload.P2PTrade)
                    end
                end
                if type(payload.Dialogue) == "table" then
                    App.OpenDialogue(payload.Dialogue)
                end
            end)
        end

        local tradeAction = remotes:FindFirstChild("TradeAction")
        if tradeAction and tradeAction:IsA("RemoteEvent") then
            tradeAction.OnClientEvent:Connect(function(tp)
                if type(tp) ~= "table" then
                    return
                end
                if tp.OfferA ~= nil or tp.OfferB ~= nil or tp.Kind ~= nil then
                    local myName = player and player.Name or ""
                    local myDisplay = player and player.DisplayName or ""
                    local isSideA = (tp.PlayerA == myDisplay) or (tp.PlayerA == myName) or (tp.IsNPCCollector == true)
                    local kind = tostring(tp.Kind or "TradeState")
                    local isActive = (kind ~= "TradeCompleted" and kind ~= "TradeCancelled")
                    local normalizedTrade = {
                        Active = isActive,
                        SessionId = tostring(tp.SessionId or ""),
                        PartnerName = tostring(isSideA and tp.PlayerB or tp.PlayerA or "Đối Phương"),
                        MyOffer = isSideA and (tp.OfferA or {}) or (tp.OfferB or {}),
                        PartnerOffer = isSideA and (tp.OfferB or {}) or (tp.OfferA or {}),
                        MyValue = isSideA and tonumber(tp.ValueA) or tonumber(tp.ValueB),
                        PartnerValue = isSideA and tonumber(tp.ValueB) or tonumber(tp.ValueA),
                        MyReady = isSideA and (tp.AcceptedA == true) or (tp.AcceptedB == true),
                        PartnerReady = isSideA and (tp.AcceptedB == true) or (tp.AcceptedA == true),
                        MyConfirmed = isSideA and (tp.AcceptedA == true) or (tp.AcceptedB == true),
                        PartnerConfirmed = isSideA and (tp.AcceptedB == true) or (tp.AcceptedA == true),
                        Countdown = tonumber(tp.Countdown) or 0,
                        IsNPCCollector = (tp.IsNPCCollector == true),
                        StatusText = tostring(tp.Message or ""),
                    }
                    Store.MergePartialServerState({ P2PTrade = normalizedTrade })
                    maybeAutoOpenP2PTrade(normalizedTrade)
                else
                    Store.MergePartialServerState({ P2PTrade = tp })
                    maybeAutoOpenP2PTrade(tp)
                end
            end)
        end
    end

    if player then
        player:GetAttributeChangedSignal("CurrentRealm"):Connect(function()
            local realm = player:GetAttribute("CurrentRealm")
            if realm then
                local snap = Store.GetSnapshot()
                if snap then
                    snap.world = snap.world or {}
                    snap.world.current = realm
                    App.Render()
                end
            end
        end)
    end
end)
