-- SKYBREAK: Fragments of the Core - Authoritative Server UI Command Router
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

local sharedUIRequest = sharedRemotes:FindFirstChild("UIRequest") or Instance.new("RemoteEvent")
sharedUIRequest.Name = "UIRequest"
sharedUIRequest.Parent = sharedRemotes

local uiStateUpdatedEvent = sharedRemotes:FindFirstChild("UIStateUpdated") or Instance.new("RemoteEvent")
uiStateUpdatedEvent.Name = "UIStateUpdated"
uiStateUpdatedEvent.Parent = sharedRemotes

-- Mirror Remotes under ReplicatedStorage.Remotes for convenience
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

local EXPANSION_COMMANDS = {
	RedeemCode = true,
	AscendStar = true,
	UpgradeStar = true,
	UpgradeWeaponStar = true,
	ApplyStatPreset = true,
	SaveStatPreset = true,
	RefundStats = true,
	ResetStats = true,
	TeleportIsland = true,
	BuyMirageFruit = true,
	GetMirageStock = true,
	SelectFightingStyle = true,
	SwitchFightingStyle = true,
	LearnFightingStyle = true,
	EquipTitle = true,
	EquipHakiColor = true,
	RerollRace = true,
	SummonSeaBeast = true,
	DropHeldFruit = true,
	DropFruit = true,
	AwakenFruit = true,
	RollFruit = true,
	EatFruit = true,
	HoldFruit = true,
	-- Wave 3 World Events, Warships, Raids, Economy, Party, Crew, PvP & DevSandbox
	DevSandbox = true,
	SpawnShip = true,
	SpawnWarship = true,
	FireShipCannon = true,
	VoteRaidDifficulty = true,
	StartRaid = true,
	StartAwakeningRaid = true,
	EnterSkySpire = true,
	LeaveSkySpire = true,
	ResetDPSDummy = true,
	EnchantWeapon = true,
	ClaimDailyReward = true,
	ClaimDaily = true,
	BuyVoidMerchant = true,
	RepeatQuest = true,
	PartyAction = true,
	TogglePvP = true,
	DuelAction = true,
	CrewAction = true,
	InspectPlayer = true,
	-- Wave 4 3D Arsenal Expansion, NPC Vendors, 4x4 Collector Trading, Factions & Temple V4
	BuyVendorItem = true,
	TradeWithCollector = true,
	SetFaction = true,
	StartTempleV4Trial = true,
}

local function getVendorService()
	local mod = Services:FindFirstChild("SkybreakVendorAndArsenalService")
	if mod and mod:IsA("ModuleScript") then
		local ok, svc = pcall(require, mod)
		if ok and type(svc) == "table" then
			return svc
		end
	end
	return nil
end

local function dispatchExpansionCommand(player, cmd, payload)
	local vendorSvc = getVendorService()
	if vendorSvc and type(vendorSvc.HandleUIRequest) == "function" then
		local handled = vendorSvc.HandleUIRequest(player, cmd, payload)
		if handled == true then
			return true, nil
		end
	end
	if GameService.HandleUIRequest then
		local ok = GameService.HandleUIRequest(player, cmd, payload)
		if ok == true then
			return true, nil
		end
	end
	for _, svcName in ipairs({ "SkybreakVendorAndArsenalService", "SkybreakSocialEconomyService", "SkybreakWorldEventsService", "SkybreakCombatExpansion" }) do
		local expMod = Services:FindFirstChild(svcName)
		if expMod and expMod:IsA("ModuleScript") then
			local loaded, exp = pcall(require, expMod)
			if loaded and type(exp) == "table" and type(exp.HandleUIRequest) == "function" then
				local ok = exp.HandleUIRequest(player, cmd, payload)
				if ok then
					return true, nil
				end
			end
		end
	end
	return false, "Expansion service unavailable."
end

local function handleCommand(player, cmdOrPayload, arg2)
	local cmd = nil
	local payload = nil
	if type(cmdOrPayload) == "string" then
		cmd = cmdOrPayload
		payload = type(arg2) == "table" and arg2 or { value = arg2 }
	elseif type(cmdOrPayload) == "table" then
		cmd = cmdOrPayload.command or cmdOrPayload.action or cmdOrPayload.cmd
		payload = cmdOrPayload
	end
	if type(cmd) ~= "string" or cmd == "" or #cmd > 48 then
		return
	end

	local ok, message = false, nil

	if cmd == "OpenScreen" then
		return
	elseif cmd == "SelectSlot" then
		GameService.Equipment(player, { action = "SelectSlot", slot = payload and (payload.slot or payload.value) or 1 })
		return
	elseif EXPANSION_COMMANDS[cmd] then
		ok, message = dispatchExpansionCommand(player, cmd, payload)
	elseif cmd == "FastTravel" then
		local islId = payload and (payload.islandId or payload.nodeId or payload.id)
		if islId and GameService.HandleUIRequest then
			ok = GameService.HandleUIRequest(player, "TeleportIsland", payload)
		else
			ok, message = TravelService.HandleFastTravel(player, payload)
		end
	elseif cmd == "EquipItem" then
		local vendorSvc = getVendorService()
		if vendorSvc and type(vendorSvc.HandleEquipItem) == "function" then
			ok, message = vendorSvc.HandleEquipItem(player, payload)
		else
			ok, message = InventoryService.HandleEquip(player, payload)
		end
	elseif cmd == "SelectClass" then
		ok, message = SkillService.HandleClassSwitch(player, payload)
	elseif cmd == "TrackQuest" then
		ok, message = QuestService.HandleTrackQuest(player, payload)
	elseif cmd == "CraftRecipe" then
		ok, message = CraftingService.HandleCraft(player, payload)
	elseif cmd == "UpgradeItem" then
		ok, message = CraftingService.HandleUpgrade(player, payload)
	else
		ok, message = dispatchExpansionCommand(player, cmd, payload)
		if not ok and not message then
			message = "Unknown command."
		end
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
sharedUIRequest.OnServerEvent:Connect(handleCommand)

getSnapshotFn.OnServerInvoke = function(player)
	if GameService.Rate(player, "UI_Snapshot", 0.25) then
		GameService.Sync(player)
	end
	return nil
end
