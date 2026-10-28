-- SKYBREAK: Fragments of the Core — SkybreakServer PlayerDataService Facade
-- Location: ServerScriptService/SkybreakServer/PlayerDataService.lua
-- Re-exports the authoritative session-locked PlayerDataService so both service paths share identical state.

return require(script.Parent.Parent:WaitForChild("Services"):WaitForChild("PlayerDataService"))
