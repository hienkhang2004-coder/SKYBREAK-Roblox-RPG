-- SKYBREAK: Fragments of the Core — ClientBootstrap Interface Bridge
-- Location: StarterPlayer/StarterPlayerScripts/UI/Interface.lua
-- Delegates all UI rendering and routing to the modular SkybreakClient/UI/App orchestrator
-- while preserving 100% API compatibility with ClientBootstrap.client.lua.

local SkybreakClient = script.Parent.Parent:WaitForChild("SkybreakClient")
local App = require(SkybreakClient:WaitForChild("UI"):WaitForChild("App"))

return App
