local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

local REQUIRED_REMOTES = {
	"CombatRequest",
	"AbilityRequest",
	"InteractRequest",
	"StateUpdate",
	"EquipmentRequest",
	"CombatFX",
	"CombatEvent",
	"AppearanceRequest",
	"UIRequest",
	"UICommand",
	"FruitAction",
	"TradeAction",
	"StatAllocate",
	"TeleportIsland",
	"ForgeRequest",
}

for _, remoteName in ipairs(REQUIRED_REMOTES) do
	if not remotes:FindFirstChild(remoteName) then
		local ev = Instance.new("RemoteEvent")
		ev.Name = remoteName
		ev.Parent = remotes
	end
end

local ok, err = xpcall(function()
	require(ServerScriptService.Services.GameService).Start()
	local vendorMod = ServerScriptService.Services:FindFirstChild("SkybreakVendorAndArsenalService")
	if vendorMod then
		require(vendorMod).Start()
	end
end, debug.traceback)
if not ok then
	warn("[SKYBREAK SERVER BOOTSTRAP ERROR]", err)
end
