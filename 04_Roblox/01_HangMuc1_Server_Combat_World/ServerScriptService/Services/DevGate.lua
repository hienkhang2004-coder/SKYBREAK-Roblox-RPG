-- SKYBREAK: Fragments of the Core — Server-Authoritative Dev Sandbox Gate (P0-04)
-- Location: ServerScriptService/Services/DevGate.lua
-- Replaces legacy ReplicatedStorage EnableDevSandbox flag with strict server-only verification.

local RunService = game:GetService("RunService")

local DevGate = {}

-- Server-only whitelists (never exposed in ReplicatedStorage)
DevGate.AllowedTestPlaceIds = {
	-- Add staging/QA PlaceIds here when needed
}

DevGate.AllowedDevUserIds = {
	-- Add authorized developer UserIds here when needed
}

-- Internal test override flag for automated unit tests only
DevGate._TestOverride = false

function DevGate.IsAllowed(player)
	if DevGate._TestOverride == true then
		return true
	end
	local okStudio, isStudio = pcall(function()
		return RunService:IsStudio()
	end)
	if okStudio and isStudio == true then
		return true
	end
	local placeId = tonumber(game.PlaceId) or 0
	if DevGate.AllowedTestPlaceIds[placeId] == true and player ~= nil then
		local userId = tonumber(player.UserId) or 0
		if DevGate.AllowedDevUserIds[userId] == true then
			return true
		end
	end
	return false
end

DevGate.IsStudioOrDev = DevGate.IsAllowed

return DevGate
