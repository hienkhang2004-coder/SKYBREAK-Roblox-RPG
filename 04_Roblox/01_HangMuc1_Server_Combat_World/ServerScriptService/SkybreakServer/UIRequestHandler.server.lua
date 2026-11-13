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
local legacyUIRequest = legacyRemotes:FindFirstChild("UIRequest") or Instance.new("RemoteEvent")
legacyUIRequest.Name = "UIRequest"
legacyUIRequest.Parent = legacyRemotes

local InventoryService = require(script.Parent:WaitForChild("InventoryService"))
local SkillService = require(script.Parent:WaitForChild("SkillService"))
local QuestService = require(script.Parent:WaitForChild("QuestService"))
local TravelService = require(script.Parent:WaitForChild("TravelService"))
local CraftingService = require(script.Parent:WaitForChild("CraftingService"))

local Services = script.Parent.Parent:WaitForChild("Services")
local GameService = require(Services:WaitForChild("GameService"))
local RemoteGuard = require(Services:WaitForChild("RemoteGuard"))

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
	SetHakiColor = true,
	RerollRace = true,
	SummonSeaBeast = true,
	DropHeldFruit = true,
	DropFruit = true,
	StoreFruit = true,
	AwakenFruit = true,
	RollFruit = true,
	EatFruit = true,
	HoldFruit = true,
	-- Wave 3 World Events, Warships, Raids, Economy, Party, Crew, PvP & DevSandbox
	DevSandbox = true,
	SpawnShip = true,
	SpawnWarship = true,
	RepairShip = true,
	FireShipCannon = true,
	VoteRaidDifficulty = true,
	StartRaid = true,
	StartAwakeningRaid = true,
	StartMicrochipRaid = true,
	EnterSkySpire = true,
	LeaveSkySpire = true,
	ResetDPSDummy = true,
	EnchantWeapon = true,
	RollWeaponEnchant = true,
	ClaimDailyReward = true,
	ClaimDaily = true,
	ClaimDailyLogin = true,
	BuyVoidMerchant = true,
	BuyVoidMerchantItem = true,
	RepeatQuest = true,
	SetAutoRepeatQuest = true,
	PartyAction = true,
	InviteParty = true,
	SetPartyMode = true,
	TogglePvP = true,
	DuelAction = true,
	JoinColosseum1v1 = true,
	CrewAction = true,
	InspectPlayer = true,
	-- Wave 4 3D Arsenal Expansion, NPC Vendors, 4x4 Collector Trading, Factions & Temple V4
	BuyVendorItem = true,
	TradeWithCollector = true,
	SetFaction = true,
	StartTempleV4Trial = true,
	-- Wave 5 Race Evolution, P2P Trading, Bounty Claims, NPC Confirmations & Quest Acceptance
	EvolveRace = true,
	P2PTradeAction = true,
	ClaimBountyReward = true,
	ConfirmNPCAction = true,
	AcceptQuest = true,
	-- P2-01 Fair Utility & Cosmetic Monetization (Robux GamePasses & Developer Products)
	PromptGamePass = true,
	PromptDevProduct = true,
	RefreshGamePasses = true,
}

local HAKI_COLOR_UI_MAP = {
	Gold = "solar_gold",
	gold = "solar_gold",
	solar_gold = "solar_gold",
	Crimson = "crimson_conqueror",
	crimson = "crimson_conqueror",
	Rose = "crimson_conqueror",
	rose = "crimson_conqueror",
	crimson_conqueror = "crimson_conqueror",
	Cyan = "glacial_cyan",
	cyan = "glacial_cyan",
	glacial_cyan = "glacial_cyan",
	Violet = "abyssal_violet",
	violet = "abyssal_violet",
	abyssal_violet = "abyssal_violet",
	Emerald = "verdant_emerald",
	emerald = "verdant_emerald",
	verdant_emerald = "verdant_emerald",
	Rainbow = "prismatic_aether",
	rainbow = "prismatic_aether",
	prismatic_aether = "prismatic_aether",
}

local function normalizeCommandAlias(cmd, payload)
	local p = type(payload) == "table" and payload or {}
	if cmd == "RollWeaponEnchant" then
		return "EnchantWeapon", p
	elseif cmd == "BuyVoidMerchantItem" then
		return "BuyVoidMerchant", p
	elseif cmd == "ClaimDailyLogin" then
		return "ClaimDailyReward", p
	elseif cmd == "SetAutoRepeatQuest" then
		return "RepeatQuest", p
	elseif cmd == "JoinColosseum1v1" then
		local copy = {}
		for k, v in pairs(p) do
			copy[k] = v
		end
		if copy.subAction == nil and copy.mode == nil then
			copy.subAction = "Queue1v1"
			copy.mode = "Queue1v1"
		end
		return "DuelAction", copy
	elseif cmd == "InviteParty" then
		local copy = {}
		for k, v in pairs(p) do
			copy[k] = v
		end
		copy.subAction = "Invite"
		return "PartyAction", copy
	elseif cmd == "SetPartyMode" then
		local copy = {}
		for k, v in pairs(p) do
			copy[k] = v
		end
		copy.subAction = "SetMode"
		return "PartyAction", copy
	elseif cmd == "SetHakiColor" or cmd == "EquipHakiColor" then
		local rawColor = tostring(p.colorId or p.id or p.color or p.value or "")
		local mapped = HAKI_COLOR_UI_MAP[rawColor] or HAKI_COLOR_UI_MAP[string.lower(rawColor)] or rawColor
		local copy = {}
		for k, v in pairs(p) do
			copy[k] = v
		end
		if mapped ~= "" then
			copy.colorId = mapped
			copy.id = mapped
			copy.value = mapped
		end
		return "EquipHakiColor", copy
	end
	return cmd, p
end

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

local function getMonetizationService()
	local mod = Services:FindFirstChild("MonetizationService")
	if mod and mod:IsA("ModuleScript") then
		local ok, svc = pcall(require, mod)
		if ok and type(svc) == "table" then
			return svc
		end
	end
	return nil
end

local function dispatchExpansionCommand(player, cmd, payload)
	local monetizationSvc = getMonetizationService()
	if monetizationSvc and type(monetizationSvc.HandleUIRequest) == "function" then
		local handled = monetizationSvc.HandleUIRequest(player, cmd, payload)
		if handled == true then
			return true, nil
		end
	end
	local vendorSvc = getVendorService()
	if vendorSvc and type(vendorSvc.HandleUIRequest) == "function" then
		local handled = vendorSvc.HandleUIRequest(player, cmd, payload)
		if handled == true then
			return true, nil
		end
	end
	if type(GameService.HandleUIRequest) == "function" then
		local ok = GameService.HandleUIRequest(player, cmd, payload)
		if ok == true then
			return true, nil
		end
	end
	for _, svcName in ipairs({ "SkybreakSocialEconomyService", "SkybreakWorldEventsService", "SkybreakCombatExpansion" }) do
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
	local rawCmd = (type(cmdOrPayload) == "string" and cmdOrPayload)
		or (type(cmdOrPayload) == "table" and (cmdOrPayload.command or cmdOrPayload.action or cmdOrPayload.cmd))
		or nil
	local guardChannel = (rawCmd == "StatAllocate" or rawCmd == "AddStat") and "StatAllocate" or "UI"
	if not RemoteGuard.Allow(player, guardChannel) then
		return
	end
	local cmd = nil
	local payload = nil
	if type(cmdOrPayload) == "string" then
		cmd = cmdOrPayload
		payload = type(arg2) == "table" and arg2 or { value = arg2 }
	elseif type(cmdOrPayload) == "table" then
		cmd = cmdOrPayload.command or cmdOrPayload.action or cmdOrPayload.cmd
		payload = cmdOrPayload
	end
	if type(cmd) ~= "string" or cmd == "" or #cmd > 64 then
		return
	end
	if payload ~= nil and not RemoteGuard.ValidatePayload(payload, 4) then
		return
	end
	cmd, payload = normalizeCommandAlias(cmd, payload)

	local ok, message = false, nil

	if cmd == "OpenScreen" then
		return
	elseif cmd == "SelectSlot" then
		GameService.Equipment(player, { action = "SelectSlot", slot = payload and (payload.slot or payload.value) or 1 })
		return
	elseif EXPANSION_COMMANDS[cmd] then
		if cmd == "TeleportIsland" then
			local canTravel, lockMsg = TravelService.CanFastTravel(player, payload)
			if not canTravel then
				ok, message = false, lockMsg
			else
				ok, message = dispatchExpansionCommand(player, cmd, payload)
				if not ok then
					ok, message = TravelService.HandleFastTravel(player, payload)
				end
			end
		elseif cmd == "AcceptQuest" then
			ok, message = dispatchExpansionCommand(player, cmd, payload)
			if not ok then
				ok, message = QuestService.HandleAcceptQuest(player, payload)
			end
		else
			ok, message = dispatchExpansionCommand(player, cmd, payload)
		end
	elseif cmd == "FastTravel" then
		ok, message = TravelService.HandleFastTravel(player, payload)
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
legacyUIRequest.OnServerEvent:Connect(handleCommand)

getSnapshotFn.OnServerInvoke = function(player)
	if GameService.Rate(player, "UI_Snapshot", 0.25) then
		GameService.Sync(player)
	end
	return nil
end
