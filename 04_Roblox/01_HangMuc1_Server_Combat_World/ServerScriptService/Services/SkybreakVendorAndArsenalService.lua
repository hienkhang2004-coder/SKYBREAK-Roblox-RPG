-- SKYBREAK: Fragments of the Core — 3D NPC Vendors, Arsenal Shop, 4x4 Collector Trading & Wearable Armor Sync Service
-- Location: ServerScriptService/Services/SkybreakVendorAndArsenalService.lua
-- Spawns sculpted 3D NPC Vendor Stations across Sea 1-3, syncs 3D wearable armor attributes,
-- and authoritatively handles BuyVendorItem, TradeWithCollector, SetFaction & StartTempleV4Trial.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local C = require(Shared:WaitForChild("Config"))
local CombatData = require(Shared:WaitForChild("SkybreakCombatData"))

local SkyShared = ReplicatedStorage:WaitForChild("SkybreakShared")
local SkyCfg = SkyShared:WaitForChild("Config")
local ArsenalExpansionConfig = require(SkyCfg:WaitForChild("ArsenalExpansionConfig"))
local RarityConfig = require(SkyCfg:WaitForChild("RarityConfig"))

local Services = script.Parent
local W = require(Services:WaitForChild("WorldService"))
local D = require(Services:WaitForChild("PlayerDataService"))
local G = require(Services:WaitForChild("GameService"))
local DevGate = require(Services:WaitForChild("DevGate"))
local Helpers = require(Services:WaitForChild("GameExperienceHelpers"))
local LiveOps = require(Services:WaitForChild("SkybreakLiveOpsService"))

local SkybreakServer = Services.Parent:WaitForChild("SkybreakServer")
local InventoryService = require(SkybreakServer:WaitForChild("InventoryService"))

local FRUIT_CANONICAL_ALIASES = {
	galecore = "GaleCore",
	gale = "GaleCore",
	aetherwindcore = "GaleCore",
	sandstonecore = "SandstoneCore",
	smoke = "SandstoneCore",
	smokecore = "SandstoneCore",
	solarflamecore = "SolarFlameCore",
	flame = "SolarFlameCore",
	flamecore = "SolarFlameCore",
	cyberphoenixcore = "SolarFlameCore",
	glaciericecore = "GlacierIceCore",
	ice = "GlacierIceCore",
	icecore = "GlacierIceCore",
	thunderrumblecore = "ThunderRumbleCore",
	rumble = "ThunderRumbleCore",
	rumblecore = "ThunderRumbleCore",
	celestiallightcore = "CelestialLightCore",
	light = "CelestialLightCore",
	lightcore = "CelestialLightCore",
	starforgedmagmacore = "StarforgedMagmaCore",
	magma = "StarforgedMagmaCore",
	magmacore = "StarforgedMagmaCore",
	magmaburstcore = "StarforgedMagmaCore",
	astralgravitycore = "AstralGravityCore",
	gravity = "AstralGravityCore",
	gravitycore = "AstralGravityCore",
	dimensionalportalcore = "DimensionalPortalCore",
	portal = "DimensionalPortalCore",
	portalcore = "DimensionalPortalCore",
	solartitancore = "SolarTitanCore",
	buddha = "SolarTitanCore",
	quake = "SolarTitanCore",
	quakecore = "SolarTitanCore",
	starlightquakecore = "SolarTitanCore",
	aetherflowcore = "AetherflowCore",
	sweetdoughcore = "AetherflowCore",
	dough = "AetherflowCore",
	doughcore = "AetherflowCore",
	abyssalsovereigncore = "AbyssalSovereignCore",
	dragon = "AbyssalSovereignCore",
	dragoncore = "AbyssalSovereignCore",
	abyssaldarkcore = "AbyssalSovereignCore",
}

local function resolveCanonicalFruitId(raw)
	if type(raw) ~= "string" or raw == "" then
		return ""
	end
	local clean = string.lower((string.gsub(raw, "%s+", "")))
	if FRUIT_CANONICAL_ALIASES[clean] then
		return FRUIT_CANONICAL_ALIASES[clean]
	end
	if D.NormalizeFruitId then
		local norm = D.NormalizeFruitId(raw)
		if norm ~= "" and C.AetherFruits and C.AetherFruits[norm] then
			return norm
		end
	end
	if CombatData.ResolveFruitId then
		local resolved = CombatData.ResolveFruitId(raw)
		if type(resolved) == "string" and resolved ~= "" then
			return resolved
		end
	end
	return raw
end

local VendorService = {}
local started = false
local cmdDebounce = {}

local function getUIStateUpdatedRemote()
	local rems = SkyShared:FindFirstChild("Remotes")
	local ev = rems and rems:FindFirstChild("UIStateUpdated")
	if ev and ev:IsA("RemoteEvent") then
		return ev
	end
	return nil
end

local function fireVendorModeHint(player, vendorMode)
	local ev = getUIStateUpdatedRemote()
	if ev then
		ev:FireClient(player, {
			OpenVendorMode = vendorMode,
			ActiveVendorMode = vendorMode,
		})
	end
end

local function ensureWorldSubfolder(name)
	local rootFolder = workspace:FindFirstChild("SkybreakExpansionWorld")
	if not rootFolder then
		rootFolder = Instance.new("Folder")
		rootFolder.Name = "SkybreakExpansionWorld"
		rootFolder.Parent = workspace
	end
	local sub = rootFolder:FindFirstChild(name)
	if not sub then
		sub = Instance.new("Folder")
		sub.Name = name
		sub.Parent = rootFolder
	end
	return sub
end

local function groundYAt(pos, fallbackY)
	local refY = fallbackY or (pos.Y - 2)
	if W and type(W.RaycastGround) == "function" then
		local hit = W.RaycastGround(pos, refY)
		if hit and hit.Position then
			return hit.Position.Y
		end
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.RespectCanCollide = true
	local exclude = {}
	for _, fname in ipairs({
		"SkybreakExpansionWorld",
		"WorldObjects",
		"ActiveEnemies",
		"ActiveBosses",
		"ActiveNPCs",
		"ActiveShips",
		"TempFX",
		"Solid3DObstacles",
	}) do
		local inst = workspace:FindFirstChild(fname)
		if inst then
			table.insert(exclude, inst)
		end
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then
			table.insert(exclude, plr.Character)
		end
	end
	params.FilterDescendantsInstances = exclude
	local hit = workspace:Raycast(Vector3.new(pos.X, refY + 90, pos.Z), Vector3.new(0, -200, 0), params)
	if hit and hit.Position.Y > 8 and math.abs(hit.Position.Y - refY) <= 45 then
		return hit.Position.Y
	end
	return refY
end

local function makeAnchoredPart(parent, name, size, cf, color, material, shape, className, transparency)
	local p = Instance.new(className or "Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Transparency = transparency or 0
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	if p:IsA("Part") and shape then
		p.Shape = shape
	end
	p.Parent = parent
	return p
end

-- ============================================================================
-- 1. LIVE 3D WEARABLE ARMOR & WEAPON ATTRIBUTE SYNC (Multiplayer + 0ms Local)
-- ============================================================================
function VendorService.NormalizeEquippedSlots(profile)
	if type(profile) ~= "table" then
		return {}
	end
	profile.Equipped = type(profile.Equipped) == "table" and profile.Equipped or {}
	local eq = profile.Equipped

	-- Bidirectional slot mirroring so both 8-slot UI (Helm/Gauntlets/Greaves/Offhand)
	-- and GameService.Stats (Helmet/Gloves/Boots/Necklace) read identical equipped items!
	local helm = eq.Helm or eq.Helmet
	if helm ~= nil then
		eq.Helm = helm
		eq.Helmet = helm
	end

	local gaunt = eq.Gauntlets or eq.Gloves
	if gaunt ~= nil then
		eq.Gauntlets = gaunt
		eq.Gloves = gaunt
	end

	local greaves = eq.Greaves or eq.Boots
	if greaves ~= nil then
		eq.Greaves = greaves
		eq.Boots = greaves
	end

	local off = eq.Offhand or eq.Necklace
	if off ~= nil then
		local itemCfg = ArsenalExpansionConfig.Items[off] or RarityConfig.Items[off]
		if not (itemCfg and (itemCfg.WeaponType == "Gun" or itemCfg.Icon == "Gun")) then
			eq.Offhand = off
			eq.Necklace = off
		end
	end

	if profile.Weapon and not eq.Weapon then
		eq.Weapon = profile.Weapon
	end
	return eq
end

function VendorService.SyncCharacterArmorAttributes(player, profile)
	if not player or not player.Parent then
		return
	end
	local prof = profile or D.Get(player)
	if type(prof) ~= "table" then
		return
	end
	local eq = VendorService.NormalizeEquippedSlots(prof)
	local ch = player.Character

	local attrs = {
		EquippedHelmet = tostring(eq.Helm or eq.Helmet or ""),
		EquippedHelm = tostring(eq.Helm or eq.Helmet or ""),
		EquippedChest = tostring(eq.Chest or eq.Armor or ""),
		EquippedArmor = tostring(eq.Chest or eq.Armor or ""),
		EquippedGauntlets = tostring(eq.Gauntlets or eq.Gloves or ""),
		EquippedGloves = tostring(eq.Gauntlets or eq.Gloves or ""),
		EquippedGreaves = tostring(eq.Greaves or eq.Boots or ""),
		EquippedBoots = tostring(eq.Greaves or eq.Boots or ""),
		EquippedRing = tostring(eq.Ring or ""),
		EquippedNecklace = tostring(eq.Necklace or eq.Offhand or ""),
		EquippedOffhand = tostring(prof.EquippedGun or eq.Offhand or ""),
		EquippedArtifact = tostring(eq.Artifact or ""),
		EquippedSword = tostring(prof.Weapon or eq.Weapon or ""),
		EquippedGun = tostring(prof.EquippedGun or ""),
		Faction = tostring(prof.Faction or "Pirate"),
	}

	for k, v in pairs(attrs) do
		if player:GetAttribute(k) ~= v then
			player:SetAttribute(k, v)
		end
		if ch and ch:GetAttribute(k) ~= v then
			ch:SetAttribute(k, v)
		end
	end

	local ev = getUIStateUpdatedRemote()
	if ev then
		local uiEquipped = {
			Helm = eq.Helm or eq.Helmet,
			Chest = eq.Chest,
			Gauntlets = eq.Gauntlets or eq.Gloves,
			Greaves = eq.Greaves or eq.Boots,
			Weapon = prof.Weapon or eq.Weapon,
			Offhand = prof.EquippedGun or eq.Offhand or eq.Necklace,
			Ring = eq.Ring,
			Artifact = eq.Artifact,
		}
		ev:FireClient(player, {
			Equipped = uiEquipped,
			ArmorSetInfo = ArsenalExpansionConfig.GetActiveArmorSetInfo(uiEquipped),
		})
	end
end

-- ============================================================================
-- 2. UNIFIED EQUIP HELPER (Supports Expansion Guns, Melee Weapons & 8-Slot Armor)
-- ============================================================================
function VendorService.HandleEquipItem(player, payload)
	if type(payload) ~= "table" then
		return false, "Invalid equip payload."
	end
	local itemId = tostring(payload.itemId or payload.id or payload.value or "")
	if itemId == "" then
		return false, "Missing item ID."
	end

	local prof = D.Get(player)
	if not prof then
		return false, "Profile loading."
	end
	prof.Inventory = type(prof.Inventory) == "table" and prof.Inventory or {}

	local rItem = ArsenalExpansionConfig.Items[itemId] or RarityConfig.Items[itemId]
	local cItem = C.Items[itemId]
	local isStyle = (C.FightingStyles and C.FightingStyles[itemId] ~= nil)
		or (CombatData.Styles and CombatData.Styles[itemId] ~= nil)
		or (CombatData.FightingStyles and CombatData.FightingStyles[itemId] ~= nil)
	if isStyle then
		prof.UnlockedStyles = type(prof.UnlockedStyles) == "table" and prof.UnlockedStyles or { skyborn_combat = true }
		if not prof.UnlockedStyles[itemId] and itemId ~= "SkybornCombat" and itemId ~= "skyborn_combat" then
			return false, LiveOps.Pick(player, "Bạn chưa lĩnh ngộ Võ Thuật này!", "You have not unlocked this Fighting Style yet!")
		end
		prof.UnlockedStyles[itemId] = true
		prof.FightingStyle = itemId
		prof.DisplayFightingStyle = itemId
		prof.ActiveSlot = 1
		player:SetAttribute("FightingStyle", itemId)
		if player.Character then
			player.Character:SetAttribute("FightingStyle", itemId)
		end
		G.Sync(player)
		return true, LiveOps.Pick(player, "Đã trang bị Võ Thuật: " .. itemId, "Equipped Fighting Style: " .. itemId)
	end
	local isGun = (rItem and (rItem.WeaponType == "Gun" or rItem.Icon == "Gun"))
		or (cItem and cItem.Slot == "Gun")
		or (C.Guns and C.Guns[itemId] ~= nil)

	if isGun then
		if (tonumber(prof.Inventory[itemId]) or 0) <= 0 then
			return false, "Bạn chưa sở hữu Pháp Khí này trong túi đồ."
		end
		prof.UnlockedGuns = type(prof.UnlockedGuns) == "table" and prof.UnlockedGuns or {}
		prof.UnlockedGuns[itemId] = true
		prof.EquippedGun = itemId
		G.Equipment(player, { action = "EquipGun", gunId = itemId })
		VendorService.SyncCharacterArmorAttributes(player, prof)
		return true, "Đã trang bị Pháp Khí: " .. tostring((rItem and (rItem.VietnameseName or rItem.Name)) or itemId)
	end

	local ok, msg = InventoryService.HandleEquip(player, payload)
	if ok then
		-- Ensure exact canonical slot & legacy slot are both populated
		prof.Equipped = type(prof.Equipped) == "table" and prof.Equipped or {}
		if rItem and rItem.Slot then
			if rItem.Slot == "Helm" then
				prof.Equipped.Helm = itemId
				prof.Equipped.Helmet = itemId
			elseif rItem.Slot == "Chest" then
				prof.Equipped.Chest = itemId
			elseif rItem.Slot == "Gauntlets" then
				prof.Equipped.Gauntlets = itemId
				prof.Equipped.Gloves = itemId
			elseif rItem.Slot == "Greaves" then
				prof.Equipped.Greaves = itemId
				prof.Equipped.Boots = itemId
			elseif rItem.Slot == "Ring" then
				prof.Equipped.Ring = itemId
			elseif rItem.Slot == "Artifact" then
				prof.Equipped.Artifact = itemId
			elseif rItem.Slot == "Offhand" then
				prof.Equipped.Offhand = itemId
				prof.Equipped.Necklace = itemId
			elseif rItem.Slot == "Weapon" then
				prof.Weapon = itemId
				prof.Equipped.Weapon = itemId
			end
		end
		VendorService.SyncCharacterArmorAttributes(player, prof)
		G.Sync(player)
	end
	return ok, msg
end

-- ============================================================================
-- 3. SCULPTED 3D NPC VENDOR STATIONS (Sea 1, Sea 2, Sea 3 & Realm 7)
-- ============================================================================
local onTradeTableSeatChanged = nil
local onTradeTablePromptTriggered = nil

local function buildSculptedVendorNPC(stationModel, basePos, lookTarget, accentColor, vendorKind, visualAsset)
	local darkNavy = Color3.fromRGB(24, 34, 56)
	local goldTrim = Color3.fromRGB(232, 186, 82)
	local skinTone = Color3.fromRGB(238, 212, 188)

	local flatLook = lookTarget and Vector3.new(lookTarget.X, basePos.Y, lookTarget.Z) or (basePos + Vector3.new(0, 0, -10))
	if (flatLook - basePos).Magnitude < 0.5 then
		flatLook = basePos + Vector3.new(0, 0, -10)
	end
	local baseCF = CFrame.lookAt(basePos, flatLook)

	-- Dais pedestal
	local dais = Instance.new("Part")
	dais.Name = "VendorDais"
	dais.Shape = Enum.PartType.Cylinder
	dais.Size = Vector3.new(0.64, 5.8, 5.8)
	dais.CFrame = baseCF * CFrame.new(0, 0.32, 0) * CFrame.Angles(0, 0, math.pi * 0.5)
	dais.Color = darkNavy
	dais.Material = Enum.Material.Metal
	dais.Anchored = true
	dais.Parent = stationModel

	makeAnchoredPart(
		stationModel,
		"VendorAuraRing",
		Vector3.new(0.14, 6.3, 6.3),
		baseCF * CFrame.new(0, 0.66, 0) * CFrame.Angles(0, 0, math.pi * 0.5),
		accentColor,
		Enum.Material.Neon,
		Enum.PartType.Cylinder,
		"Part",
		0.25
	)

	-- Sculpted 3D Vendor Guardian Figure (clonable by Dialogue.lua 3D Live Portrait)
	local rootPart = Instance.new("Part")
	rootPart.Name = "HumanoidRootPart"
	rootPart.Size = Vector3.new(2.0, 4.4, 1.4)
	rootPart.CFrame = baseCF * CFrame.new(0, 2.85, 0)
	rootPart.Color = darkNavy
	rootPart.Material = Enum.Material.Metal
	rootPart.Transparency = 1
	rootPart.Anchored = true
	rootPart.CanCollide = true
	rootPart.Parent = stationModel

	makeAnchoredPart(stationModel, "LowerTunic", Vector3.new(1.75, 1.85, 1.05), baseCF * CFrame.new(0, 1.55, 0), darkNavy, Enum.Material.SmoothPlastic)
	makeAnchoredPart(stationModel, "UpperTorso", Vector3.new(1.85, 1.75, 1.02), baseCF * CFrame.new(0, 3.25, 0), darkNavy, Enum.Material.Metal)
	makeAnchoredPart(stationModel, "ChestEmblem", Vector3.new(0.75, 0.75, 0.16), baseCF * CFrame.new(0, 3.35, -0.52), accentColor, Enum.Material.Neon)
	makeAnchoredPart(stationModel, "VendorCape", Vector3.new(2.05, 2.95, 0.14), baseCF * CFrame.new(0, 2.45, 0.58) * CFrame.Angles(math.rad(8), 0, 0), accentColor:Lerp(darkNavy, 0.52), Enum.Material.SmoothPlastic)

	for _, side in ipairs({ -1, 1 }) do
		makeAnchoredPart(
			stationModel,
			"Pauldron_" .. side,
			Vector3.new(0.72, 0.44, 1.08),
			baseCF * CFrame.new(side * 1.18, 3.98, 0) * CFrame.Angles(0, 0, math.rad(-side * 16)),
			goldTrim,
			Enum.Material.Metal
		)
	end

	local head = makeAnchoredPart(stationModel, "Head", Vector3.new(1.22, 1.26, 1.22), baseCF * CFrame.new(0, 4.78, 0), skinTone, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	makeAnchoredPart(
		stationModel,
		"HaloCrown",
		Vector3.new(0.12, 1.68, 1.68),
		baseCF * CFrame.new(0, 5.32, 0.12) * CFrame.Angles(0, math.pi * 0.5, math.rad(16)),
		accentColor,
		Enum.Material.Neon,
		Enum.PartType.Cylinder
	)

	-- Signature 3D Shop Props beside the Vendor
	if vendorKind == "SwordDealer" then
		makeAnchoredPart(stationModel, "AnvilStand", Vector3.new(1.6, 1.2, 1.0), baseCF * CFrame.new(1.9, 1.24, -0.4), darkNavy, Enum.Material.Metal)
		makeAnchoredPart(stationModel, "DisplayBladeA", Vector3.new(0.16, 3.2, 0.34), baseCF * CFrame.new(1.75, 2.95, -0.4) * CFrame.Angles(0, 0, math.rad(-14)), accentColor, Enum.Material.Neon)
		makeAnchoredPart(stationModel, "DisplayBladeB", Vector3.new(0.16, 3.0, 0.32), baseCF * CFrame.new(2.12, 2.85, -0.4) * CFrame.Angles(0, 0, math.rad(14)), goldTrim, Enum.Material.Neon)
	elseif vendorKind == "GunDealer" then
		makeAnchoredPart(stationModel, "OrdnanceCrate", Vector3.new(1.7, 1.25, 1.2), baseCF * CFrame.new(1.95, 1.26, -0.35), darkNavy, Enum.Material.Metal)
		makeAnchoredPart(stationModel, "DisplayCannon", Vector3.new(2.2, 0.54, 0.54), baseCF * CFrame.new(1.95, 2.25, -0.35) * CFrame.Angles(0, math.rad(65), math.rad(22)), accentColor, Enum.Material.Neon, Enum.PartType.Cylinder)
	elseif vendorKind == "TradingTable" then
		local tableCenterCF = baseCF * CFrame.new(0, 0, -5.2)
		local holoTable = makeAnchoredPart(stationModel, "HoloTradeTable", Vector3.new(1.05, 4.4, 4.4), tableCenterCF * CFrame.new(0, 1.15, 0) * CFrame.Angles(0, 0, math.pi * 0.5), darkNavy, Enum.Material.Metal, Enum.PartType.Cylinder)
		holoTable.CanCollide = true
		makeAnchoredPart(stationModel, "HoloScaleGrid", Vector3.new(0.14, 3.7, 3.7), tableCenterCF * CFrame.new(0, 1.72, 0) * CFrame.Angles(0, 0, math.pi * 0.5), accentColor, Enum.Material.Neon, Enum.PartType.Cylinder, "Part", 0.18)
		makeAnchoredPart(stationModel, "HoloCenterPrism", Vector3.new(0.65, 1.05, 0.65), tableCenterCF * CFrame.new(0, 2.55, 0) * CFrame.Angles(math.rad(35), math.rad(45), 0), goldTrim, Enum.Material.Neon)

		local seatOffsets = {
			Vector3.new(-2.85, 0.95, -1.55),
			Vector3.new(2.85, 0.95, -1.55),
			Vector3.new(-2.85, 0.95, 1.55),
			Vector3.new(2.85, 0.95, 1.55),
		}
		local seatsList = {}
		for sIdx, sOff in ipairs(seatOffsets) do
			local seatWorldPos = (tableCenterCF * CFrame.new(sOff)).Position
			local seatLookPos = Vector3.new(tableCenterCF.Position.X, seatWorldPos.Y, tableCenterCF.Position.Z)
			local seatCF = CFrame.lookAt(seatWorldPos, seatLookPos)
			local seat = Instance.new("Seat")
			seat.Name = "TradeSeat_" .. tostring(sIdx)
			seat.Size = Vector3.new(1.85, 0.46, 1.85)
			seat.CFrame = seatCF
			seat.Color = darkNavy
			seat.Material = Enum.Material.Metal
			seat.Anchored = true
			seat.CanCollide = true
			seat.Parent = stationModel
			makeAnchoredPart(stationModel, "SeatTrim_" .. tostring(sIdx), Vector3.new(1.92, 0.12, 1.92), seatCF * CFrame.new(0, 0.24, 0), accentColor, Enum.Material.Neon, nil, "Part", 0.28)
			makeAnchoredPart(stationModel, "SeatBack_" .. tostring(sIdx), Vector3.new(1.75, 1.25, 0.24), seatCF * CFrame.new(0, 0.72, 0.84), goldTrim, Enum.Material.Metal)
			table.insert(seatsList, seat)
		end
		for _, seat in ipairs(seatsList) do
			seat:GetPropertyChangedSignal("Occupant"):Connect(function()
				if type(onTradeTableSeatChanged) == "function" then
					onTradeTableSeatChanged(stationModel, seatsList, seat)
				end
			end)
		end

		local tablePrompt = Instance.new("ProximityPrompt")
		tablePrompt.Name = "PhantomTradeTablePrompt"
		tablePrompt.ActionText = "Giao Dịch (P2P / Collector)"
		tablePrompt.ObjectText = "Bàn Giao Dịch 4 Ghế • P2P & Collector"
		tablePrompt.KeyboardKeyCode = Enum.KeyCode.E
		tablePrompt.HoldDuration = 0
		tablePrompt.MaxActivationDistance = 12
		tablePrompt.RequiresLineOfSight = false
		tablePrompt.Parent = holoTable
		tablePrompt.Triggered:Connect(function(plr)
			if type(onTradeTablePromptTriggered) == "function" then
				onTradeTablePromptTriggered(plr, stationModel, seatsList)
			end
		end)
	elseif vendorKind == "ColosseumAndSpire" then
		for _, side in ipairs({ -1, 1 }) do
			makeAnchoredPart(stationModel, "SpirePillar_" .. side, Vector3.new(0.55, 4.8, 0.55), baseCF * CFrame.new(side * 2.15, 3.0, 0.45), goldTrim, Enum.Material.Metal)
			makeAnchoredPart(stationModel, "SpireOrb_" .. side, Vector3.new(0.75, 0.75, 0.75), baseCF * CFrame.new(side * 2.15, 5.65, 0.45), accentColor, Enum.Material.Neon, Enum.PartType.Ball)
		end
	end

	stationModel:SetAttribute("NPCId", stationModel.Name)
	stationModel:SetAttribute("VisualAsset", visualAsset or "GoldenKnight")
	stationModel:SetAttribute("VendorMode", vendorKind)
	stationModel:SetAttribute("NPCFloorY", basePos.Y)
	stationModel.PrimaryPart = rootPart
	return rootPart, head
end

local function spawnVendorStation(folder, spec)
	local old = folder:FindFirstChild(spec.Id)
	if old then
		old:Destroy()
	end

	local fy = groundYAt(spec.RawPos, spec.RawPos.Y - 2)
	local base = Vector3.new(spec.RawPos.X, fy, spec.RawPos.Z)

	local m = Instance.new("Model")
	m.Name = spec.Id

	local rootPart, headPart = buildSculptedVendorNPC(m, base, spec.LookAt, spec.Color, spec.VendorMode, spec.VisualAsset)

	local bill = Instance.new("BillboardGui")
	bill.Name = "VendorOverheadTag"
	bill.Size = UDim2.fromOffset(260, 48)
	bill.StudsOffset = Vector3.new(0, 2.35, 0)
	bill.MaxDistance = 80
	bill.LightInfluence = 0
	bill.Parent = headPart

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Name = "Title"
	titleLbl.Size = UDim2.new(1, 0, 0, 24)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Font = Enum.Font.GothamBlack
	titleLbl.TextSize = 14
	titleLbl.TextColor3 = spec.Color
	titleLbl.TextStrokeTransparency = 0.18
	titleLbl.Text = spec.Title
	titleLbl.Parent = bill

	local roleLbl = Instance.new("TextLabel")
	roleLbl.Name = "RoleTag"
	roleLbl.Size = UDim2.new(1, 0, 0, 18)
	roleLbl.Position = UDim2.fromOffset(0, 24)
	roleLbl.BackgroundTransparency = 1
	roleLbl.Font = Enum.Font.GothamBold
	roleLbl.TextSize = 11
	roleLbl.TextColor3 = Color3.fromRGB(232, 240, 252)
	roleLbl.TextStrokeTransparency = 0.22
	roleLbl.Text = spec.RoleTag
	roleLbl.Parent = bill

	if spec.VendorMode ~= "TradingTable" then
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "VendorShopPrompt"
		prompt.ActionText = spec.ActionText
		prompt.ObjectText = spec.Title .. " • " .. spec.RoleTag
		prompt.KeyboardKeyCode = Enum.KeyCode.E
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt.Parent = rootPart

		prompt.Triggered:Connect(function(plr)
			m:SetAttribute("NPCTalkAt", workspace:GetServerTimeNow())
			fireVendorModeHint(plr, spec.VendorMode)
			G.SendDialogue(
				plr,
				spec.Title,
				spec.DialogueRole,
				spec.DialogueBody,
				spec.ButtonLabel,
				"OpenScreen:NPCShop:" .. spec.VendorMode
			)
		end)
	end

	m.Parent = folder
	return m
end

local function buildAllVendorStations()
	local vendorFolder = ensureWorldSubfolder("VendorNPCs")
	vendorFolder:ClearAllChildren()

	local skyPos = C.Spawn or Vector3.new(-317.4, 50.5, 527.8)
	local cafePos = (C.FastTravel and C.FastTravel.CyberportCafe and C.FastTravel.CyberportCafe.Pos) or Vector3.new(9400, 50.9, 1785)
	local castlePos = (C.FastTravel and C.FastTravel.CastleOnTheVoid and C.FastTravel.CastleOnTheVoid.Pos) or Vector3.new(-14600, 50.9, 2173.1)
	local chronoPos = (C.FastTravel and C.FastTravel.ChronosBastion and C.FastTravel.ChronosBastion.Pos) or Vector3.new(0, 230.9, -13485)

	local specs = {
		-- 1. Master Sword Dealers (Sky 1, Sky 2, Sky 3 & Realm 7 Chronos Bastion)
		{
			Id = "MasterSwordDealer_Sea1",
			Title = "Kiếm Sư Thương Nhân",
			RoleTag = "< CỬA HÀNG THẦN KIẾM 3D >",
			ActionText = "Giao Dịch Thần Kiếm 3D",
			VendorMode = "SwordDealer",
			VisualAsset = "GoldenKnight",
			Color = Color3.fromRGB(244, 193, 78),
			RawPos = Vector3.new(-348, skyPos.Y, 540),
			LookAt = skyPos,
			DialogueRole = "ĐẠI SƯ VŨ KHÍ CẬN CHIẾN",
			DialogueBody = "Ta rèn và tuyển chọn 18 thanh Thần Kiếm, Đại Đao, Kích và Lưỡi Hái Thời Không mạnh nhất 3 Tầng Trời! Hãy chọn vũ khí phù hợp với cấp độ của ngươi.",
			ButtonLabel = "Mở Cửa Hàng Kiếm 3D",
		},
		{
			Id = "MasterSwordDealer_Sea2",
			Title = "Kiếm Sư Thương Nhân",
			RoleTag = "< CỬA HÀNG THẦN KIẾM 3D >",
			ActionText = "Giao Dịch Thần Kiếm 3D",
			VendorMode = "SwordDealer",
			VisualAsset = "GoldenKnight",
			Color = Color3.fromRGB(244, 193, 78),
			RawPos = Vector3.new(9374, cafePos.Y, 1764),
			LookAt = cafePos,
			DialogueRole = "ĐẠI SƯ VŨ KHÍ CẬN CHIẾN",
			DialogueBody = "Ta rèn và tuyển chọn 18 thanh Thần Kiếm, Đại Đao, Kích và Lưỡi Hái Thời Không mạnh nhất 3 Tầng Trời! Hãy chọn vũ khí phù hợp với cấp độ của ngươi.",
			ButtonLabel = "Mở Cửa Hàng Kiếm 3D",
		},
		{
			Id = "MasterSwordDealer_Sea3",
			Title = "Kiếm Sư Thương Nhân",
			RoleTag = "< CỬA HÀNG THẦN KIẾM 3D >",
			ActionText = "Giao Dịch Thần Kiếm 3D",
			VendorMode = "SwordDealer",
			VisualAsset = "GoldenKnight",
			Color = Color3.fromRGB(244, 193, 78),
			RawPos = Vector3.new(-14580, castlePos.Y, 2160),
			LookAt = castlePos,
			DialogueRole = "ĐẠI SƯ VŨ KHÍ CẬN CHIẾN",
			DialogueBody = "Ta rèn và tuyển chọn 18 thanh Thần Kiếm, Đại Đao, Kích và Lưỡi Hái Thời Không mạnh nhất 3 Tầng Trời! Hãy chọn vũ khí phù hợp với cấp độ của ngươi.",
			ButtonLabel = "Mở Cửa Hàng Kiếm 3D",
		},
		{
			Id = "MasterSwordDealer_Sea4",
			Title = "Kiếm Sư Thương Nhân",
			RoleTag = "< CỬA HÀNG THẦN KIẾM 3D >",
			ActionText = "Giao Dịch Thần Kiếm 3D",
			VendorMode = "SwordDealer",
			VisualAsset = "GoldenKnight",
			Color = Color3.fromRGB(244, 193, 78),
			RawPos = Vector3.new(22, chronoPos.Y, -13472),
			LookAt = chronoPos,
			DialogueRole = "ĐẠI SƯ VŨ KHÍ CẬN CHIẾN",
			DialogueBody = "Tại Pháo Đài Thời Gian Chronos, ta mở khóa những Thần Kiếm và Lưỡi Hái Thời Không tối thượng! Hãy chọn vũ khí xứng tầm của ngươi.",
			ButtonLabel = "Mở Cửa Hàng Kiếm 3D",
		},

		-- 2. Arcane Gunsmiths (Sea 1, Sea 2, Sea 3)
		{
			Id = "ArcaneGunsmith_Sea1",
			Title = "Xạ Thủ Chế Tác",
			RoleTag = "< XƯỞNG PHÁP KHÍ & SÚNG 3D >",
			ActionText = "Mở Xưởng Pháp Khí & Súng 3D",
			VendorMode = "GunDealer",
			VisualAsset = "LightArcher",
			Color = Color3.fromRGB(56, 189, 248),
			RawPos = Vector3.new(-324, skyPos.Y, 566),
			LookAt = skyPos,
			DialogueRole = "BẬC THẦY PHÁP KHÍ & XẠ KÍCH",
			DialogueBody = "Từ Súng Lục Aether, Cung Tinh Linh Sylvaris đến Pháo Kỳ Điểm Veyr — 10 Pháp Khí tầm xa và Bộ Thần Giáp 3D mạnh nhất đều có mặt tại xưởng của ta!",
			ButtonLabel = "Mở Xưởng Pháp Khí 3D",
		},
		{
			Id = "ArcaneGunsmith_Sea2",
			Title = "Xạ Thủ Chế Tác",
			RoleTag = "< XƯỞNG PHÁP KHÍ & SÚNG 3D >",
			ActionText = "Mở Xưởng Pháp Khí & Súng 3D",
			VendorMode = "GunDealer",
			VisualAsset = "LightArcher",
			Color = Color3.fromRGB(56, 189, 248),
			RawPos = Vector3.new(9396, cafePos.Y, 1756),
			LookAt = cafePos,
			DialogueRole = "BẬC THẦY PHÁP KHÍ & XẠ KÍCH",
			DialogueBody = "Từ Súng Lục Aether, Cung Tinh Linh Sylvaris đến Pháo Kỳ Điểm Veyr — 10 Pháp Khí tầm xa và Bộ Thần Giáp 3D mạnh nhất đều có mặt tại xưởng của ta!",
			ButtonLabel = "Mở Xưởng Pháp Khí 3D",
		},
		{
			Id = "ArcaneGunsmith_Sea3",
			Title = "Xạ Thủ Chế Tác",
			RoleTag = "< XƯỞNG PHÁP KHÍ & SÚNG 3D >",
			ActionText = "Mở Xưởng Pháp Khí & Súng 3D",
			VendorMode = "GunDealer",
			VisualAsset = "LightArcher",
			Color = Color3.fromRGB(56, 189, 248),
			RawPos = Vector3.new(-14624, castlePos.Y, 2184),
			LookAt = castlePos,
			DialogueRole = "BẬC THẦY PHÁP KHÍ & XẠ KÍCH",
			DialogueBody = "Từ Súng Lục Aether, Cung Tinh Linh Sylvaris đến Pháo Kỳ Điểm Veyr — 10 Pháp Khí tầm xa và Bộ Thần Giáp 3D mạnh nhất đều có mặt tại xưởng của ta!",
			ButtonLabel = "Mở Xưởng Pháp Khí 3D",
		},

		-- 3. 4-Seat Phantom P2P & Collector Trading Tables (Sky Hub, Cyberport Cafe & Castle on the Void)
		{
			Id = "PhantomTradingTable_Sea1",
			Title = "Bàn Giao Dịch 4 Ghế • P2P & Nhà Sưu Tập",
			RoleTag = "< GIAO DỊCH P2P & COLLECTOR <=40% >",
			ActionText = "Giao Dịch (P2P / Collector)",
			VendorMode = "TradingTable",
			VisualAsset = "ZiolesGachaNPC",
			Color = Color3.fromRGB(192, 132, 252),
			RawPos = Vector3.new(-352, skyPos.Y, 568),
			LookAt = skyPos,
			DialogueRole = "BÀN GIAO DỊCH P2P 4 GHẾ & NHÀ SƯU TẬP",
			DialogueBody = "Ngồi vào ghế cùng người chơi khác để Giao Dịch P2P trực tiếp (khóa an toàn chênh lệch <= 40%), hoặc đổi Lõi Aether công bằng với Nhà Sưu Tập!",
			ButtonLabel = "Mở Bàn Giao Dịch P2P / 4x4",
		},
		{
			Id = "PhantomTradingTable_Cafe",
			Title = "Bàn Giao Dịch 4 Ghế • P2P & Nhà Sưu Tập",
			RoleTag = "< GIAO DỊCH P2P & COLLECTOR <=40% >",
			ActionText = "Giao Dịch (P2P / Collector)",
			VendorMode = "TradingTable",
			VisualAsset = "ZiolesGachaNPC",
			Color = Color3.fromRGB(192, 132, 252),
			RawPos = Vector3.new(9424, cafePos.Y, 1756),
			LookAt = cafePos,
			DialogueRole = "BÀN GIAO DỊCH P2P 4 GHẾ & NHÀ SƯU TẬP",
			DialogueBody = "Ngồi vào ghế cùng người chơi khác để Giao Dịch P2P trực tiếp (khóa an toàn chênh lệch <= 40%), hoặc đổi Lõi Aether công bằng với Nhà Sưu Tập!",
			ButtonLabel = "Mở Bàn Giao Dịch P2P / 4x4",
		},
		{
			Id = "PhantomTradingTable_Sea2",
			Title = "Bàn Giao Dịch 4 Ghế • P2P & Nhà Sưu Tập",
			RoleTag = "< GIAO DỊCH P2P & COLLECTOR <=40% >",
			ActionText = "Giao Dịch (P2P / Collector)",
			VendorMode = "TradingTable",
			VisualAsset = "ZiolesGachaNPC",
			Color = Color3.fromRGB(192, 132, 252),
			RawPos = Vector3.new(-14576, castlePos.Y, 2188),
			LookAt = castlePos,
			DialogueRole = "BÀN GIAO DỊCH P2P 4 GHẾ & NHÀ SƯU TẬP",
			DialogueBody = "Ngồi vào ghế cùng người chơi khác để Giao Dịch P2P trực tiếp (khóa an toàn chênh lệch <= 40%), hoặc đổi Lõi Aether công bằng với Nhà Sưu Tập!",
			ButtonLabel = "Mở Bàn Giao Dịch P2P / 4x4",
		},

		-- 4. Colosseum & 50F Sky Spire Wardens (Sea 1, Sea 2)
		{
			Id = "ColosseumSpireWarden_Sea1",
			Title = "Quản Đấu Trường & Tháp 50 Tầng",
			RoleTag = "< LUẬN VÕ 1V1 & SKY SPIRE 50F >",
			ActionText = "Khiêu Chiến Đấu Trường & Tháp 50F",
			VendorMode = "ColosseumAndSpire",
			VisualAsset = "AncientMonkNPC",
			Color = Color3.fromRGB(244, 63, 94),
			RawPos = Vector3.new(-306, skyPos.Y, 484),
			LookAt = skyPos,
			DialogueRole = "CHỦ QUẢN ĐẤU TRƯỜNG & THÁP BẦU TRỜI",
			DialogueBody = "Chọn trận tuyến Hải Tặc Bầu Trời hoặc Hải Quân Thiên Không, luận võ 1v1 công bằng, hoặc chinh phục Tháp Bầu Trời 50 Tầng nhận Thánh Vật & Thần Giáp 3D!",
			ButtonLabel = "Mở Đấu Trường & Tháp 50F",
		},
		{
			Id = "ColosseumSpireWarden_Sea2",
			Title = "Quản Đấu Trường & Tháp 50 Tầng",
			RoleTag = "< LUẬN VÕ 1V1 & SKY SPIRE 50F >",
			ActionText = "Khiêu Chiến Đấu Trường & Tháp 50F",
			VendorMode = "ColosseumAndSpire",
			VisualAsset = "AncientMonkNPC",
			Color = Color3.fromRGB(244, 63, 94),
			RawPos = Vector3.new(9374, cafePos.Y, 1786),
			LookAt = cafePos,
			DialogueRole = "CHỦ QUẢN ĐẤU TRƯỜNG & THÁP BẦU TRỜI",
			DialogueBody = "Chọn trận tuyến Hải Tặc Bầu Trời hoặc Hải Quân Thiên Không, luận võ 1v1 công bằng, hoặc chinh phục Tháp Bầu Trời 50 Tầng nhận Thánh Vật & Thần Giáp 3D!",
			ButtonLabel = "Mở Đấu Trường & Tháp 50F",
		},
	}

	for _, spec in ipairs(specs) do
		spawnVendorStation(vendorFolder, spec)
	end
end

-- ============================================================================
-- 4. VENDOR & ARSENAL AUTHORITATIVE COMMAND HANDLERS
-- ============================================================================
local catalogPriceCache = nil
local function resolveVendorPrice(itemId)
	if not catalogPriceCache then
		catalogPriceCache = {}
		local vc = ArsenalExpansionConfig.VendorCatalogs or {}
		for _, listName in ipairs({ "SwordDealer", "GunDealer", "ArmorAndRelicVendor", "ShipwrightFleet", "MartialDojoStyles" }) do
			for _, entry in ipairs(vc[listName] or {}) do
				local key = entry.ItemId or entry.Id
				if key and not catalogPriceCache[key] then
					catalogPriceCache[key] = {
						Gold = tonumber(entry.PriceGold) or 0,
						Shards = tonumber(entry.PriceShards) or 0,
						Entry = entry,
					}
				end
			end
		end
	end
	if catalogPriceCache[itemId] then
		return catalogPriceCache[itemId].Gold, catalogPriceCache[itemId].Shards, catalogPriceCache[itemId].Entry
	end
	return nil, nil, nil
end

local function handleBuyVendorItem(player, payload)
	payload = type(payload) == "table" and payload or { itemId = payload }
	local itemId = tostring(payload.itemId or payload.id or payload.shipId or payload.styleId or payload.value or "")
	if itemId == "" or #itemId > 64 then
		return false
	end

	local prof = D.Get(player)
	if not prof then
		return false
	end
	-- Khong bat dung gan NPC: nut Shop (phim N) tren HUD mo cua hang o moi noi.
	-- Chong lam dung dua vao catalog, gia day du, LevelReq va RemoteGuard.
	local playerLevel = tonumber(prof.Level) or 1
	local function levelBlocked(entry, label)
		local need = entry and tonumber(entry.LevelReq) or nil
		if need and playerLevel < need then
			G.Notify(player, string.format("Cần đạt Level %d để mua [%s]!", need, tostring(label or itemId)))
			return true
		end
		return false
	end

	prof.Inventory = type(prof.Inventory) == "table" and prof.Inventory or {}
	prof.Equipped = type(prof.Equipped) == "table" and prof.Equipped or {}
	prof.Gold = tonumber(prof.Gold) or 0
	prof.CoreShards = tonumber(prof.CoreShards) or 0

	local rawQty = tonumber(payload.quantity or payload.count or payload.amount) or 1
	local qty = math.clamp(math.floor(rawQty), 1, 20)

	-- Case A: Buying / Spawning a Sky-Ship from ShipwrightFleet
	for _, shipEntry in ipairs(ArsenalExpansionConfig.VendorCatalogs.ShipwrightFleet or {}) do
		if shipEntry.Id == itemId or shipEntry.ShipId == itemId then
			prof.UnlockedShips = type(prof.UnlockedShips) == "table" and prof.UnlockedShips or { SkySloop = true }
			local shipKey = shipEntry.Id
			local shipPriceGold = tonumber(shipEntry.PriceGold) or 0
			local shipPriceShards = tonumber(shipEntry.PriceShards) or 0
			if not prof.UnlockedShips[shipKey] then
				if levelBlocked(shipEntry, shipEntry.NameVi) then
					return false
				end
				if shipPriceGold <= 0 and shipPriceShards <= 0 then
					G.Notify(player, "Chiến hạm này không có giá hợp lệ trong danh mục!")
					return false
				end
				if prof.Gold < shipPriceGold or prof.CoreShards < shipPriceShards then
					G.Notify(player, string.format("Cần %d Gold để đóng chiến hạm [%s]!", shipPriceGold, shipEntry.NameVi))
					return false
				end
				prof.Gold -= shipPriceGold
				prof.CoreShards -= shipPriceShards
			end
			prof.UnlockedShips[shipKey] = true
			if shipEntry.ShipId then
				prof.UnlockedShips[shipEntry.ShipId] = true
			end
			prof.ActiveShip = shipKey
			local weMod = Services:FindFirstChild("SkybreakWorldEventsService")
			local okWe, weSvc = pcall(function()
				return weMod and require(weMod) or nil
			end)
			if okWe and weSvc and type(weSvc.HandleUIRequest) == "function" then
				pcall(weSvc.HandleUIRequest, player, "SpawnWarship", { shipId = shipKey })
			else
				G.Equipment(player, { action = "SpawnSkyShip", shipId = shipEntry.ShipId or shipKey })
			end
			G.Notify(player, "Đã sở hữu & kích hoạt Chiến Hạm 3D: " .. shipEntry.NameVi .. "!")
			G.Sync(player)
			return true
		end
	end

	-- Case B: Learning / Equipping a Martial Dojo Style
	for _, stEntry in ipairs(ArsenalExpansionConfig.VendorCatalogs.MartialDojoStyles or {}) do
		if stEntry.Id == itemId or stEntry.StyleId == itemId then
			prof.UnlockedStyles = type(prof.UnlockedStyles) == "table" and prof.UnlockedStyles or { skyborn_combat = true }
			local sKey = stEntry.Id
			local preferredId = stEntry.StyleId or sKey
			if not prof.UnlockedStyles[sKey] and not prof.UnlockedStyles[preferredId] then
				if levelBlocked(stEntry, stEntry.NameVi) then
					return false
				end
				local needG = tonumber(stEntry.PriceGold) or 0
				local needS = tonumber(stEntry.PriceShards) or 0
				if needG <= 0 and needS <= 0 then
					G.Notify(player, "Võ thuật này không có giá hợp lệ trong danh mục!")
					return false
				end
				if prof.Gold < needG or prof.CoreShards < needS then
					G.Notify(player, string.format("Cần %d Gold & %d Core Shards để lĩnh ngộ [%s]!", needG, needS, stEntry.NameVi))
					return false
				end
				prof.Gold -= needG
				prof.CoreShards -= needS
				prof.UnlockedStyles[sKey] = true
			end
			local hasDirectStyle = (C.FightingStyles and C.FightingStyles[preferredId] ~= nil)
				or (CombatData and CombatData.Styles and CombatData.Styles[preferredId] ~= nil)
				or (CombatData and CombatData.FightingStyles and CombatData.FightingStyles[preferredId] ~= nil)
			local combatId = hasDirectStyle and preferredId or (stEntry.FallbackCombatStyleId or preferredId)
			prof.UnlockedStyles[sKey] = true
			prof.UnlockedStyles[preferredId] = true
			prof.UnlockedStyles[combatId] = true
			prof.FightingStyle = combatId
			prof.DisplayFightingStyle = sKey
			prof.ActiveSlot = 1
			if type(player.SetAttribute) == "function" then
				player:SetAttribute("FightingStyle", combatId)
			end
			if player.Character and type(player.Character.SetAttribute) == "function" then
				player.Character:SetAttribute("FightingStyle", combatId)
			end
			G.Notify(player, "Đã lĩnh ngộ & trang bị Võ Thuật: " .. stEntry.NameVi .. "!")
			G.Sync(player)
			return true
		end
	end

	-- Case C: Standard Arsenal Weapon, Arcane Gun, Wearable 3D Armor Piece, Relic, or Material
	local itemDef = ArsenalExpansionConfig.Items[itemId] or RarityConfig.Items[itemId]
	local cItem = C.Items[itemId]
	local costGold, costShards, catEntry = resolveVendorPrice(itemId)
	costGold = tonumber(costGold) or 0
	costShards = tonumber(costShards) or 0

	local displayName = (catEntry and (catEntry.NameVi or catEntry.Name))
		or (itemDef and (itemDef.VietnameseName or itemDef.Name))
		or (cItem and cItem.Name)
		or itemId
	local isMaterial = (itemDef and (itemDef.Category == "Materials" or itemDef.Category == "Quest"))
		or (cItem and (cItem.Slot == "Material" or cItem.Slot == "Quest"))
	if not isMaterial then
		qty = 1
	end
	local alreadyOwned = (tonumber(prof.Inventory[itemId]) or 0) > 0

	-- If already owned and non-stackable equipment, allow free re-equip without double-charging unless forceBuy
	if alreadyOwned and not isMaterial and payload.forceBuy ~= true then
		if payload.autoEquip ~= false then
			VendorService.HandleEquipItem(player, { itemId = itemId })
		end
		G.Notify(player, "Đã trang bị [" .. displayName .. "] từ Kho Đồ 3D!")
		G.Sync(player)
		return true
	end

	-- Strictly require the item to exist in a valid VendorCatalog with a positive price
	if not catEntry or (costGold <= 0 and costShards <= 0) then
		G.Notify(player, "Vật phẩm [" .. tostring(itemId) .. "] không được bán tại cửa hàng Thương Nhân!")
		return false
	end

	if levelBlocked(catEntry, displayName) then
		return false
	end

	local totalGold = costGold * qty
	local totalShards = costShards * qty
	if prof.Gold < totalGold or prof.CoreShards < totalShards then
		G.Notify(player, string.format("Cần %d Gold & %d Core Shards để mua x%d [%s]!", totalGold, totalShards, qty, displayName))
		return false
	end
	prof.Gold -= totalGold
	prof.CoreShards -= totalShards
	prof.Inventory[itemId] = (tonumber(prof.Inventory[itemId]) or 0) + qty

	local isGun = (itemDef and (itemDef.WeaponType == "Gun" or itemDef.Icon == "Gun"))
		or (cItem and cItem.Slot == "Gun")
	if isGun then
		prof.UnlockedGuns = type(prof.UnlockedGuns) == "table" and prof.UnlockedGuns or {}
		prof.UnlockedGuns[itemId] = true
	elseif (itemDef and itemDef.Slot == "Weapon") or (cItem and cItem.Slot == "Weapon") then
		prof.UnlockedWeapons = type(prof.UnlockedWeapons) == "table" and prof.UnlockedWeapons or {}
		prof.UnlockedWeapons[itemId] = true
	end

	if not isMaterial and payload.autoEquip ~= false then
		VendorService.HandleEquipItem(player, { itemId = itemId })
	else
		VendorService.SyncCharacterArmorAttributes(player, prof)
	end

	G.Notify(player, "Đã mua thành công: " .. displayName .. (not isMaterial and payload.autoEquip ~= false and " (Đã trang bị 3D)" or "") .. "!")
	G.Sync(player)
	return true
end

local function getTradeItemValue(id)
	local cid = resolveCanonicalFruitId(tostring(id or ""))
	if cid ~= "" and C.AetherFruits and C.AetherFruits[cid] then
		return tonumber(C.AetherFruits[cid].Price) or 100000, cid, true
	end
	if cid ~= "" and CombatData.FruitCatalog and CombatData.FruitCatalog[cid] then
		return tonumber(CombatData.FruitCatalog[cid].Value or CombatData.FruitCatalog[cid].Price) or 100000, cid, true
	end
	local rawId = tostring(id or "")
	-- Do khoi dau duoc PlayerDataService.hydrate phat lai toi thieu 1 moi lan Load => khong cho giao dich.
	if rawId == "starter_sword" or rawId == "starter_daggers" or rawId == "starter_staff" or rawId == "aether_flintlock" then
		return 0, rawId, false
	end
	local g, s = resolveVendorPrice(rawId)
	if g or s then
		-- Dinh gia theo gia that; san 25000 cu bien do 1.500 Gold thanh 25.000 gia tri giao dich.
		return (tonumber(g) or 0) + (tonumber(s) or 0) * 500, rawId, false
	end
	return 0, rawId, false
end

local function reconcileDepletedItem(prof, iid)
	if type(prof) ~= "table" or type(iid) ~= "string" or iid == "" then
		return
	end
	if (tonumber(prof.Inventory and prof.Inventory[iid]) or 0) > 0 then
		return
	end
	if type(prof.UnlockedWeapons) == "table" then
		prof.UnlockedWeapons[iid] = nil
	end
	if type(prof.UnlockedGuns) == "table" then
		prof.UnlockedGuns[iid] = nil
	end
	if prof.Weapon == iid then
		prof.Weapon = "starter_sword"
	end
	if prof.EquippedGun == iid then
		prof.EquippedGun = "aether_flintlock"
	end
	if type(prof.Equipped) == "table" then
		for slotKey, eqId in pairs(prof.Equipped) do
			if eqId == iid then
				if slotKey == "Weapon" then
					prof.Equipped[slotKey] = "starter_sword"
				elseif slotKey == "Gun" or slotKey == "Offhand" then
					prof.Equipped[slotKey] = "aether_flintlock"
				else
					prof.Equipped[slotKey] = nil
				end
			end
		end
	end
end

local function syncGrantedEquipmentUnlock(prof, iid)
	if type(prof) ~= "table" or type(iid) ~= "string" or iid == "" then
		return
	end
	local itemDef = ArsenalExpansionConfig.Items[iid] or RarityConfig.Items[iid]
	local cItem = C.Items[iid]
	local isGun = (itemDef and (itemDef.WeaponType == "Gun" or itemDef.Icon == "Gun"))
		or (cItem and cItem.Slot == "Gun")
		or (C.Guns and C.Guns[iid] ~= nil)
	if isGun then
		prof.UnlockedGuns = type(prof.UnlockedGuns) == "table" and prof.UnlockedGuns or {}
		prof.UnlockedGuns[iid] = true
	elseif (itemDef and itemDef.Slot == "Weapon") or (cItem and cItem.Slot == "Weapon") or (C.Swords and C.Swords[iid] ~= nil) then
		prof.UnlockedWeapons = type(prof.UnlockedWeapons) == "table" and prof.UnlockedWeapons or {}
		prof.UnlockedWeapons[iid] = true
	end
end

local function handleTradeWithCollector(player, payload)
	payload = type(payload) == "table" and payload or { offerId = payload }
	local prof = D.Get(player)
	if not prof then
		return false
	end
	if prof._ReadOnlyFallback == true or (D.Sessions and D.Sessions[player] and D.Sessions[player].ReadOnlyFallback == true) then
		G.Notify(player, "Không thể giao dịch khi dữ liệu đang ở chế độ Bảo Vệ (ReadOnly)!")
		return true
	end
	prof.StoredFruits = type(prof.StoredFruits) == "table" and prof.StoredFruits or {}
	prof.Inventory = type(prof.Inventory) == "table" and prof.Inventory or {}

	local giveList = nil
	local receiveList = nil
	local offerTitle = "Giao Dịch Nhà Sưu Tập 4x4"

	local offerId = tostring(payload.offerId or payload.tradeId or payload.id or "")
	if offerId ~= "" then
		for _, preset in ipairs(ArsenalExpansionConfig.VendorCatalogs.CollectorTrades or {}) do
			if preset.Id == offerId then
				giveList = preset.GiveItems
				receiveList = preset.ReceiveItems
				offerTitle = preset.NameVi or offerTitle
				break
			end
		end
	end

	local clientChosenReceive = false
	if not giveList and type(payload.giveFruits or payload.giveItems) == "table" then
		giveList = payload.giveFruits or payload.giveItems
		receiveList = payload.receiveFruits or payload.receiveItems
		clientChosenReceive = (type(receiveList) == "table")
	end

	if type(giveList) ~= "table" or #giveList == 0 or #giveList > 4 then
		G.Notify(player, "Hãy chọn từ 1 đến 4 vật phẩm/Lõi Aether để giao dịch với Nhà Sưu Tập!")
		return true
	end

	-- Count required items and compute total GiveValue
	local needCounts = {}
	local giveValue = 0
	local isFruitMap = {}
	for _, raw in ipairs(giveList) do
		local val, normId, isFruit = getTradeItemValue(raw)
		if val <= 0 or normId == "" then
			G.Notify(player, "Vật phẩm giao dịch không hợp lệ: " .. tostring(raw))
			return true
		end
		needCounts[normId] = (needCounts[normId] or 0) + 1
		isFruitMap[normId] = isFruit
		giveValue += val
	end

	-- Verify player owns every offered item
	for normId, reqCount in pairs(needCounts) do
		local owned = isFruitMap[normId]
			and (tonumber(prof.StoredFruits[normId]) or 0)
			or (tonumber(prof.Inventory[normId]) or 0)
		if owned < reqCount then
			local fName = (C.AetherFruits and C.AetherFruits[normId] and C.AetherFruits[normId].Name) or normId
			G.Notify(player, string.format("Bạn chưa đủ [%s] trong kho lưu trữ (%d/%d)!", fName, owned, reqCount))
			return true
		end
	end

	local maxAllowedReceiveValue = math.floor(giveValue * 1.05)

	-- Auto-match a fair Collector fruit within <= 40% and <= 105% of giveValue if receiveList wasn't explicitly specified
	if type(receiveList) ~= "table" or #receiveList == 0 then
		local bestFruitId = nil
		local bestDiff = math.huge
		for fid, fDef in pairs(C.AetherFruits or {}) do
			local canonFid = resolveCanonicalFruitId(fid)
			if not needCounts[canonFid] then
				local pVal = tonumber(fDef.Price) or 0
				local mVal = math.max(giveValue, pVal, 1)
				local dRatio = math.abs(giveValue - pVal) / mVal
				local d = math.abs(pVal - giveValue)
				if pVal > 0 and pVal <= maxAllowedReceiveValue and dRatio <= 0.4001 and d < bestDiff then
					bestDiff = d
					bestFruitId = canonFid
				end
			end
		end
		if bestFruitId then
			receiveList = { bestFruitId }
		end
	end

	if type(receiveList) ~= "table" or #receiveList == 0 or #receiveList > 4 then
		G.Notify(player, "Nhà Sưu Tập chưa tìm thấy vật phẩm đối ứng tương đương giá trị!")
		return true
	end

	local receiveValue = 0
	local normalizedReceives = {}
	for _, raw in ipairs(receiveList) do
		local val, normId, isFruit = getTradeItemValue(raw)
		-- Client tu chon do nhan: chi cho phep Loi Aether (khong cho lay do vendor bo qua LevelReq/Sea).
		if val <= 0 or normId == "" or (clientChosenReceive and not isFruit) then
			G.Notify(player, "Vật phẩm nhận không hợp lệ: " .. tostring(raw))
			return true
		end
		if needCounts[normId] then
			G.Notify(player, "Không thể đặt trùng cùng một Lõi/vật phẩm ở cả bên đưa và bên nhận!")
			return true
		end
		receiveValue += val
		table.insert(normalizedReceives, { Id = normId, IsFruit = isFruit })
	end

	local maxVal = math.max(giveValue, receiveValue, 1)
	local diffRatio = math.abs(giveValue - receiveValue) / maxVal
	if diffRatio > 0.4001 then
		G.Notify(
			player,
			string.format(
				"CHỐNG LỪA ĐẢO 40%%: Chênh lệch giá trị hiện tại là %.1f%% (> 40%%)! Giao dịch bị khóa an toàn.",
				diffRatio * 100
			)
		)
		return true
	end
	if receiveValue > maxAllowedReceiveValue then
		G.Notify(
			player,
			string.format(
				"Nhà Sưu Tập chỉ đổi vật phẩm giá trị tương đương (tối đa 105%% = %d Gold, hiện nhận %d Gold)!",
				maxAllowedReceiveValue,
				receiveValue
			)
		)
		return true
	end

	-- Verify Core Storage Cap before mutating inventory
	local maxCap = Helpers.GetMaxCoreStorage(player, prof)
	local recvFruitTally = {}
	for _, rec in ipairs(normalizedReceives) do
		if rec.IsFruit then
			recvFruitTally[rec.Id] = (recvFruitTally[rec.Id] or 0) + 1
		end
	end
	for fid, addCnt in pairs(recvFruitTally) do
		local curOwned = math.max(0, (tonumber(prof.StoredFruits[fid]) or 0) - (isFruitMap[fid] and (needCounts[fid] or 0) or 0))
		if curOwned + addCnt > maxCap then
			local fName = (C.AetherFruits and C.AetherFruits[fid] and C.AetherFruits[fid].Name) or fid
			LiveOps.Notify(
				G,
				player,
				string.format("Kho Lõi Aether đã đầy (%d/%d)! Không thể nhận thêm [%s]!", curOwned, maxCap, fName),
				string.format("Core Storage full (%d/%d)! Cannot store more [%s]!", curOwned, maxCap, fName)
			)
			return true
		end
	end

	-- Deduct player's offered items
	for normId, reqCount in pairs(needCounts) do
		if isFruitMap[normId] then
			local rem = math.max(0, (tonumber(prof.StoredFruits[normId]) or 0) - reqCount)
			prof.StoredFruits[normId] = rem > 0 and rem or nil
		else
			local rem = math.max(0, (tonumber(prof.Inventory[normId]) or 0) - reqCount)
			prof.Inventory[normId] = rem > 0 and rem or nil
			reconcileDepletedItem(prof, normId)
		end
	end

	-- Grant Collector's items
	local receivedNames = {}
	for _, rec in ipairs(normalizedReceives) do
		if rec.IsFruit then
			prof.StoredFruits[rec.Id] = (tonumber(prof.StoredFruits[rec.Id]) or 0) + 1
			local fDef = C.AetherFruits and C.AetherFruits[rec.Id]
			table.insert(receivedNames, (fDef and fDef.Name) or rec.Id)
		else
			prof.Inventory[rec.Id] = (tonumber(prof.Inventory[rec.Id]) or 0) + 1
			syncGrantedEquipmentUnlock(prof, rec.Id)
			local iDef = ArsenalExpansionConfig.Items[rec.Id] or RarityConfig.Items[rec.Id]
			table.insert(receivedNames, (iDef and (iDef.VietnameseName or iDef.Name)) or rec.Id)
		end
	end
	VendorService.SyncCharacterArmorAttributes(player, prof)

	task.spawn(D.Save, player, false)
	G.Notify(
		player,
		string.format(
			"GIAO DỊCH 4X4 THÀNH CÔNG [%s] (Chênh lệch %.1f%% <= 40%%): Nhận %s!",
			offerTitle,
			diffRatio * 100,
			table.concat(receivedNames, ", ")
		)
	)
	G.Sync(player)
	return true
end

-- ============================================================================
-- 4B. REAL 2-PLAYER P2P TRADING AT 4-SEAT PHANTOM TABLES (<=40% Anti-Scam)
-- ============================================================================
local activeP2PSessionsByPlayer = {}
local pendingP2PRequests = {} -- [targetPlayer] = { From = senderPlayer, At = os.clock() }
local nextP2PSessionSeq = 0

local function getItemDisplayLabel(normId, isFruit)
	if isFruit then
		local fDef = C.AetherFruits and C.AetherFruits[normId]
		return (fDef and fDef.Name) or normId
	end
	local iDef = ArsenalExpansionConfig.Items[normId] or RarityConfig.Items[normId] or C.Items[normId]
	return (iDef and (iDef.VietnameseName or iDef.Name)) or normId
end

local function findTargetPlayer(payload)
	if type(payload) ~= "table" then
		return nil
	end
	local uid = tonumber(payload.targetUserId or payload.userId or payload.partnerUserId or payload.targetId)
	if uid then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr.UserId == uid then
				return plr
			end
		end
	end
	local rawName = tostring(payload.targetName or payload.playerName or payload.target or "")
	if rawName ~= "" then
		local lower = string.lower(rawName)
		for _, plr in ipairs(Players:GetPlayers()) do
			if string.lower(plr.Name) == lower or string.lower(plr.DisplayName) == lower then
				return plr
			end
		end
	end
	return nil
end

local function computeSessionMetrics(session)
	local valA, valB = 0, 0
	for _, entry in ipairs(session.Offers[session.PlayerA] or {}) do
		valA += (tonumber(entry.Value) or 0)
	end
	for _, entry in ipairs(session.Offers[session.PlayerB] or {}) do
		valB += (tonumber(entry.Value) or 0)
	end
	local maxVal = math.max(valA, valB, 1)
	local diffRatio = (valA == 0 and valB == 0) and 0 or (math.abs(valA - valB) / maxVal)
	local diffPct = math.floor(diffRatio * 1000 + 0.5) / 10
	local isFair = (diffRatio <= 0.4001)
	local fairWarning = nil
	if not isFair and (valA > 0 or valB > 0) then
		fairWarning = string.format("Chênh lệch giá trị %.1f%% (> 40%%)! Cần cân bằng lại để khóa giao dịch.", diffPct)
	end
	return valA, valB, diffPct, isFair, fairWarning
end

local function getNearbyPlayersList(player)
	local list = {}
	local ch = player and player.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return list
	end
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			local och = other.Character
			local ohrp = och and och:FindFirstChild("HumanoidRootPart")
			local ohum = och and och:FindFirstChildOfClass("Humanoid")
			if ohrp then
				local dist = (ohrp.Position - hrp.Position).Magnitude
				if dist <= 65 then
					local seatPart = ohum and ohum.SeatPart
					local atTable = seatPart ~= nil and string.find(seatPart.Name, "TradeSeat_") ~= nil
					table.insert(list, {
						UserId = other.UserId,
						Name = other.Name,
						DisplayName = other.DisplayName,
						Distance = math.floor(dist + 0.5),
						SeatedAtTable = atTable,
						InTrade = activeP2PSessionsByPlayer[other] ~= nil,
					})
				end
			end
		end
	end
	table.sort(list, function(a, b)
		return a.Distance < b.Distance
	end)
	return list
end

local function buildP2PStateForPlayer(player, extraFields)
	local session = activeP2PSessionsByPlayer[player]
	local req = pendingP2PRequests[player]
	local pendingInfo = nil
	if req and req.From and req.From.Parent == Players and (os.clock() - (req.At or 0)) <= 60 then
		pendingInfo = {
			FromUserId = req.From.UserId,
			FromName = req.From.Name,
			FromDisplayName = req.From.DisplayName,
		}
	end
	if not session then
		local state = {
			Active = false,
			PendingInvite = pendingInfo,
			NearbyPlayers = getNearbyPlayersList(player),
		}
		if type(extraFields) == "table" then
			for k, v in pairs(extraFields) do
				state[k] = v
			end
		end
		return state
	end
	local partner = (session.PlayerA == player) and session.PlayerB or session.PlayerA
	local valA, valB, diffPct, isFair, fairWarning = computeSessionMetrics(session)
	local myVal = (session.PlayerA == player) and valA or valB
	local partnerVal = (session.PlayerA == player) and valB or valA
	local state = {
		Active = true,
		SessionId = session.Id,
		TableId = session.TableId,
		PartnerUserId = partner and partner.UserId or 0,
		PartnerName = partner and partner.Name or "",
		PartnerDisplayName = partner and partner.DisplayName or "",
		MyOffers = session.Offers[player] or {},
		PartnerOffers = (partner and session.Offers[partner]) or {},
		MyValue = myVal,
		PartnerValue = partnerVal,
		DiffPct = diffPct,
		IsFair = isFair,
		FairWarning = fairWarning,
		MyReady = session.Ready[player] == true,
		PartnerReady = (partner and session.Ready[partner] == true) or false,
		MyConfirmed = session.Confirmed[player] == true,
		PartnerConfirmed = (partner and session.Confirmed[partner] == true) or false,
		PendingInvite = pendingInfo,
		NearbyPlayers = getNearbyPlayersList(player),
	}
	if type(extraFields) == "table" then
		for k, v in pairs(extraFields) do
			state[k] = v
		end
	end
	return state
end

local function pushP2PState(player, extraFields, openShop)
	if not player or player.Parent ~= Players then
		return
	end
	local ev = getUIStateUpdatedRemote()
	if ev then
		local payload = {
			P2PTrade = buildP2PStateForPlayer(player, extraFields),
		}
		if openShop then
			payload.OpenVendorMode = "TradingTable"
			payload.ActiveVendorMode = "TradingTable"
		end
		ev:FireClient(player, payload)
	end
end

local function cancelP2PSession(session, reasonMsg, extraFields)
	if not session or session.Closed then
		return
	end
	session.Closed = true
	local pA, pB = session.PlayerA, session.PlayerB
	if pA then
		activeP2PSessionsByPlayer[pA] = nil
		pcall(function()
			pA:SetAttribute("InTrade", false)
		end)
	end
	if pB then
		activeP2PSessionsByPlayer[pB] = nil
		pcall(function()
			pB:SetAttribute("InTrade", false)
		end)
	end
	if pA and pA.Parent == Players then
		if reasonMsg then
			G.Notify(pA, reasonMsg)
		end
		pushP2PState(pA, extraFields or { Cancelled = true }, false)
	end
	if pB and pB.Parent == Players then
		if reasonMsg then
			G.Notify(pB, reasonMsg)
		end
		pushP2PState(pB, extraFields or { Cancelled = true }, false)
	end
end

local function arePlayersAtSameTradingTable(pA, pB)
	if not pA or not pB then
		return false, nil
	end
	local rA = pA.Character and pA.Character:FindFirstChild("HumanoidRootPart")
	local rB = pB.Character and pB.Character:FindFirstChild("HumanoidRootPart")
	if not rA or not rB then
		return false, nil
	end
	local vendorFolder = workspace:FindFirstChild("SkybreakExpansionWorld")
		and workspace.SkybreakExpansionWorld:FindFirstChild("VendorNPCs")
	if vendorFolder then
		for _, st in ipairs(vendorFolder:GetChildren()) do
			if st:GetAttribute("VendorMode") == "TradingTable" then
				local tbl = st:FindFirstChild("HoloTradeTable") or st.PrimaryPart
				if tbl and (rA.Position - tbl.Position).Magnitude <= 28 and (rB.Position - tbl.Position).Magnitude <= 28 then
					return true, st.Name
				end
			end
		end
	end
	for _, fb in ipairs({
		{ Id = "PhantomTradingTable_Cafe", Pos = Vector3.new(9424, 50.9, 1756) },
		{ Id = "PhantomTradingTable_Sea2", Pos = Vector3.new(-14576, 50.9, 2188) },
	}) do
		if (rA.Position - fb.Pos).Magnitude <= 28 and (rB.Position - fb.Pos).Magnitude <= 28 then
			return true, fb.Id
		end
	end
	return false, nil
end

local function checkP2PEligibility(pA, pB, notifyPlr)
	local profA, profB = D.Get(pA), D.Get(pB)
	if not profA or not profB then
		return false, nil
	end
	local lvA, lvB = tonumber(profA.Level) or 1, tonumber(profB.Level) or 1
	if lvA < 700 or lvB < 700 then
		if notifyPlr then
			LiveOps.Notify(
				G,
				notifyPlr,
				"BÀN GIAO DỊCH P2P: Cả 2 người chơi đều phải đạt tối thiểu Level 700 (Tầng Trời 2 - Cyberport Cafe)!",
				"P2P TRADING: Both players must reach Level 700+ (Sea 2 - Cyberport Cafe)!"
			)
		end
		return false, nil
	end
	local nowUnix = os.time()
	if (tonumber(pA:GetAttribute("PvPCombatUntil")) or 0) > nowUnix or (tonumber(pB:GetAttribute("PvPCombatUntil")) or 0) > nowUnix then
		if notifyPlr then
			LiveOps.Notify(G, notifyPlr, "Không thể Giao Dịch P2P khi đang trong trạng thái Giao Tranh PvP!", "Cannot P2P trade while PvP combat-tagged!")
		end
		return false, nil
	end
	local nearTbl, tblName = arePlayersAtSameTradingTable(pA, pB)
	if not nearTbl then
		if notifyPlr then
			LiveOps.Notify(
				G,
				notifyPlr,
				"Cả 2 người chơi phải đứng trong bán kính 28m quanh Bàn Giao Dịch Cyberport Cafe để giao dịch!",
				"Both players must stand within 28 studs of a Trading Table (Cyberport Cafe) to trade!"
			)
		end
		return false, nil
	end
	return true, tblName
end

local function startP2PSession(pA, pB, tableId, openUI)
	if not pA or not pB or pA == pB or pA.Parent ~= Players or pB.Parent ~= Players then
		return false
	end
	if activeP2PSessionsByPlayer[pA] or activeP2PSessionsByPlayer[pB] then
		return false
	end
	local profA, profB = D.Get(pA), D.Get(pB)
	if not profA or not profB then
		return false
	end
	if profA._ReadOnlyFallback == true or profB._ReadOnlyFallback == true then
		G.Notify(pA, "Không thể giao dịch P2P khi dữ liệu đang ở chế độ Bảo Vệ (ReadOnly)!")
		G.Notify(pB, "Không thể giao dịch P2P khi dữ liệu đang ở chế độ Bảo Vệ (ReadOnly)!")
		return false
	end
	local okElig, resolvedTableId = checkP2PEligibility(pA, pB, pA)
	if not okElig then
		return false
	end
	tableId = resolvedTableId or tableId

	pendingP2PRequests[pA] = nil
	pendingP2PRequests[pB] = nil
	nextP2PSessionSeq += 1
	local session = {
		Id = "P2P_" .. tostring(nextP2PSessionSeq),
		TableId = tableId or "DirectP2P",
		PlayerA = pA,
		PlayerB = pB,
		Offers = { [pA] = {}, [pB] = {} },
		Ready = { [pA] = false, [pB] = false },
		Confirmed = { [pA] = false, [pB] = false },
		StartedAt = os.clock(),
	}
	activeP2PSessionsByPlayer[pA] = session
	activeP2PSessionsByPlayer[pB] = session
	pA:SetAttribute("InTrade", true)
	pB:SetAttribute("InTrade", true)

	G.Notify(pA, "BÀN GIAO DỊCH P2P: Đã kết nối phiên trao đổi trực tiếp với " .. pB.DisplayName .. "!")
	G.Notify(pB, "BÀN GIAO DỊCH P2P: Đã kết nối phiên trao đổi trực tiếp với " .. pA.DisplayName .. "!")
	pushP2PState(pA, nil, openUI == true)
	pushP2PState(pB, nil, openUI == true)
	return true
end

onTradeTableSeatChanged = function(stationModel, seatsList, changedSeat)
	local seatedPlayers = {}
	for _, seat in ipairs(seatsList) do
		local occ = seat.Occupant
		local char = occ and occ.Parent
		local plr = char and Players:GetPlayerFromCharacter(char)
		if plr and plr.Parent == Players then
			table.insert(seatedPlayers, plr)
		end
	end
	if changedSeat and changedSeat.Occupant then
		local occPlr = Players:GetPlayerFromCharacter(changedSeat.Occupant.Parent)
		if occPlr and not activeP2PSessionsByPlayer[occPlr] then
			pushP2PState(occPlr, nil, true)
		end
	end
	if #seatedPlayers >= 2 then
		local p1, p2 = nil, nil
		for _, sp in ipairs(seatedPlayers) do
			if not activeP2PSessionsByPlayer[sp] then
				if not p1 then
					p1 = sp
				elseif sp ~= p1 then
					p2 = sp
					break
				end
			end
		end
		if p1 and p2 then
			startP2PSession(p1, p2, stationModel.Name, true)
		end
	end
end

onTradeTablePromptTriggered = function(plr, stationModel, seatsList)
	stationModel:SetAttribute("NPCTalkAt", workspace:GetServerTimeNow())
	-- Check if another free player is sitting at this table right now
	if not activeP2PSessionsByPlayer[plr] then
		for _, seat in ipairs(seatsList or {}) do
			local occ = seat.Occupant
			local other = occ and occ.Parent and Players:GetPlayerFromCharacter(occ.Parent)
			if other and other ~= plr and not activeP2PSessionsByPlayer[other] then
				startP2PSession(plr, other, stationModel.Name, true)
				return
			end
		end
	end
	pushP2PState(plr, nil, true)
	G.SendDialogue(
		plr,
		"Bàn Giao Dịch 4 Ghế • P2P & Nhà Sưu Tập",
		"GIAO DỊCH P2P TRỰC TIẾP & NHÀ SƯU TẬP 4X4",
		"Ngồi vào ghế cùng người chơi khác để tự động ghép đôi Giao Dịch P2P (chống lừa đảo <= 40%), gửi lời mời P2P, hoặc giao dịch trực tiếp với Nhà Sưu Tập!",
		"Mở Bàn Giao Dịch P2P / Collector",
		"OpenScreen:NPCShop:TradingTable"
	)
end

local function resetSessionLocks(session)
	session.Ready[session.PlayerA] = false
	session.Ready[session.PlayerB] = false
	session.Confirmed[session.PlayerA] = false
	session.Confirmed[session.PlayerB] = false
end

local function countOfferedById(offerList, normId, isFruit)
	local n = 0
	for _, item in ipairs(offerList) do
		if item.Id == normId and (item.IsFruit == true) == (isFruit == true) then
			n += 1
		end
	end
	return n
end

local function executeAtomicP2PSwap(session)
	local pA, pB = session.PlayerA, session.PlayerB
	if not pA or not pB or pA.Parent ~= Players or pB.Parent ~= Players then
		cancelP2PSession(session, "Giao dịch P2P đã hủy do người chơi rời máy chủ.")
		return false
	end
	local profA, profB = D.Get(pA), D.Get(pB)
	if not profA or not profB or profA._ReadOnlyFallback == true or profB._ReadOnlyFallback == true then
		cancelP2PSession(session, "Không thể hoàn tất giao dịch P2P do trạng thái hồ sơ thay đổi!")
		return false
	end
	local okElig = checkP2PEligibility(pA, pB, pA)
	if not okElig then
		cancelP2PSession(session, LiveOps.Pick(pA, "Giao dịch P2P bị hủy: cả hai phải đạt Lv.700+, đứng cạnh Bàn Giao Dịch (<=28m) và không trong PvP!", "P2P trade cancelled: both players must be Lv.700+, within 28m of the Trading Table, and out of PvP!"))
		return false
	end
	profA.StoredFruits = type(profA.StoredFruits) == "table" and profA.StoredFruits or {}
	profA.Inventory = type(profA.Inventory) == "table" and profA.Inventory or {}
	profB.StoredFruits = type(profB.StoredFruits) == "table" and profB.StoredFruits or {}
	profB.Inventory = type(profB.Inventory) == "table" and profB.Inventory or {}

	local offersA = session.Offers[pA] or {}
	local offersB = session.Offers[pB] or {}
	if #offersA == 0 and #offersB == 0 then
		G.Notify(pA, "Cần đặt ít nhất 1 vật phẩm hoặc Lõi Aether để giao dịch!")
		return true
	end

	local _, _, diffPct, isFair = computeSessionMetrics(session)
	if not isFair then
		resetSessionLocks(session)
		local msg = string.format("CHỐNG LỪA ĐẢO 40%%: Chênh lệch %.1f%% (> 40%%)! Khóa an toàn đã kích hoạt.", diffPct)
		G.Notify(pA, msg)
		G.Notify(pB, msg)
		pushP2PState(pA)
		pushP2PState(pB)
		return true
	end

	-- Aggregate required counts for atomic ownership verification
	local reqA_Fruits, reqA_Items = {}, {}
	for _, entry in ipairs(offersA) do
		if entry.IsFruit then
			reqA_Fruits[entry.Id] = (reqA_Fruits[entry.Id] or 0) + 1
		else
			reqA_Items[entry.Id] = (reqA_Items[entry.Id] or 0) + 1
		end
	end
	local reqB_Fruits, reqB_Items = {}, {}
	for _, entry in ipairs(offersB) do
		if entry.IsFruit then
			reqB_Fruits[entry.Id] = (reqB_Fruits[entry.Id] or 0) + 1
		else
			reqB_Items[entry.Id] = (reqB_Items[entry.Id] or 0) + 1
		end
	end

	for fid, cnt in pairs(reqA_Fruits) do
		if (tonumber(profA.StoredFruits[fid]) or 0) < cnt then
			cancelP2PSession(session, pA.DisplayName .. " không còn đủ [" .. getItemDisplayLabel(fid, true) .. "] trong kho!")
			return true
		end
	end
	for iid, cnt in pairs(reqA_Items) do
		if (tonumber(profA.Inventory[iid]) or 0) < cnt then
			cancelP2PSession(session, pA.DisplayName .. " không còn đủ [" .. getItemDisplayLabel(iid, false) .. "] trong túi đồ!")
			return true
		end
	end
	for fid, cnt in pairs(reqB_Fruits) do
		if (tonumber(profB.StoredFruits[fid]) or 0) < cnt then
			cancelP2PSession(session, pB.DisplayName .. " không còn đủ [" .. getItemDisplayLabel(fid, true) .. "] trong kho!")
			return true
		end
	end
	for iid, cnt in pairs(reqB_Items) do
		if (tonumber(profB.Inventory[iid]) or 0) < cnt then
			cancelP2PSession(session, pB.DisplayName .. " không còn đủ [" .. getItemDisplayLabel(iid, false) .. "] trong túi đồ!")
			return true
		end
	end

	-- Enforce Core Storage Cap for both receivers before any mutation
	local maxCapA = Helpers.GetMaxCoreStorage(pA, profA)
	local maxCapB = Helpers.GetMaxCoreStorage(pB, profB)
	for fid, cnt in pairs(reqA_Fruits) do
		local afterB = math.max(0, (tonumber(profB.StoredFruits[fid]) or 0) - (reqB_Fruits[fid] or 0)) + cnt
		if afterB > maxCapB then
			resetSessionLocks(session)
			local msg = string.format("%s đã đầy Kho Lõi Aether (%d/%d) cho [%s]!", pB.DisplayName, afterB - cnt, maxCapB, getItemDisplayLabel(fid, true))
			G.Notify(pA, msg)
			G.Notify(pB, msg)
			pushP2PState(pA)
			pushP2PState(pB)
			return true
		end
	end
	for fid, cnt in pairs(reqB_Fruits) do
		local afterA = math.max(0, (tonumber(profA.StoredFruits[fid]) or 0) - (reqA_Fruits[fid] or 0)) + cnt
		if afterA > maxCapA then
			resetSessionLocks(session)
			local msg = string.format("%s đã đầy Kho Lõi Aether (%d/%d) cho [%s]!", pA.DisplayName, afterA - cnt, maxCapA, getItemDisplayLabel(fid, true))
			G.Notify(pA, msg)
			G.Notify(pB, msg)
			pushP2PState(pA)
			pushP2PState(pB)
			return true
		end
	end

	-- Atomic Swap (zero yields between deduction and grant)
	for fid, cnt in pairs(reqA_Fruits) do
		local rem = math.max(0, (tonumber(profA.StoredFruits[fid]) or 0) - cnt)
		profA.StoredFruits[fid] = rem > 0 and rem or nil
		profB.StoredFruits[fid] = (tonumber(profB.StoredFruits[fid]) or 0) + cnt
	end
	for iid, cnt in pairs(reqA_Items) do
		local rem = math.max(0, (tonumber(profA.Inventory[iid]) or 0) - cnt)
		profA.Inventory[iid] = rem > 0 and rem or nil
		reconcileDepletedItem(profA, iid)
		profB.Inventory[iid] = (tonumber(profB.Inventory[iid]) or 0) + cnt
		syncGrantedEquipmentUnlock(profB, iid)
	end
	for fid, cnt in pairs(reqB_Fruits) do
		local rem = math.max(0, (tonumber(profB.StoredFruits[fid]) or 0) - cnt)
		profB.StoredFruits[fid] = rem > 0 and rem or nil
		profA.StoredFruits[fid] = (tonumber(profA.StoredFruits[fid]) or 0) + cnt
	end
	for iid, cnt in pairs(reqB_Items) do
		local rem = math.max(0, (tonumber(profB.Inventory[iid]) or 0) - cnt)
		profB.Inventory[iid] = rem > 0 and rem or nil
		reconcileDepletedItem(profB, iid)
		profA.Inventory[iid] = (tonumber(profA.Inventory[iid]) or 0) + cnt
		syncGrantedEquipmentUnlock(profA, iid)
	end

	session.Closed = true
	activeP2PSessionsByPlayer[pA] = nil
	activeP2PSessionsByPlayer[pB] = nil
	pA:SetAttribute("InTrade", false)
	pB:SetAttribute("InTrade", false)

	VendorService.SyncCharacterArmorAttributes(pA, profA)
	VendorService.SyncCharacterArmorAttributes(pB, profB)
	task.spawn(D.Save, pA, false)
	task.spawn(D.Save, pB, false)

	G.Notify(pA, string.format("GIAO DỊCH P2P THÀNH CÔNG với %s (Chênh lệch %.1f%% <= 40%%)!", pB.DisplayName, diffPct))
	G.Notify(pB, string.format("GIAO DỊCH P2P THÀNH CÔNG với %s (Chênh lệch %.1f%% <= 40%%)!", pA.DisplayName, diffPct))
	G.Sync(pA)
	G.Sync(pB)
	pushP2PState(pA, { Completed = true, LastResult = "Success" }, false)
	pushP2PState(pB, { Completed = true, LastResult = "Success" }, false)
	return true
end

local function handleP2PTradeAction(player, payload)
	payload = type(payload) == "table" and payload or { subAction = tostring(payload or "") }
	local sub = tostring(payload.subAction or payload.action or payload.mode or "GetState")
	local prof = D.Get(player)
	if not prof then
		return false
	end

	if sub == "GetState" or sub == "Refresh" or sub == "" then
		pushP2PState(player)
		return true
	end

	if sub == "Cancel" or sub == "Close" then
		local session = activeP2PSessionsByPlayer[player]
		if session then
			cancelP2PSession(session, player.DisplayName .. " đã hủy phiên Giao Dịch P2P.")
		else
			pendingP2PRequests[player] = nil
			pushP2PState(player, { Cancelled = true }, false)
		end
		return true
	end

	if sub == "Decline" or sub == "DeclineRequest" then
		local req = pendingP2PRequests[player]
		pendingP2PRequests[player] = nil
		if req and req.From and req.From.Parent == Players then
			G.Notify(req.From, player.DisplayName .. " đã từ chối lời mời Giao Dịch P2P.")
			pushP2PState(req.From)
		end
		pushP2PState(player)
		return true
	end

	if sub == "RequestTrade" or sub == "Invite" or sub == "StartWithPlayer" or sub == "Accept" or sub == "AcceptRequest" then
		if activeP2PSessionsByPlayer[player] then
			G.Notify(player, "Bạn đang ở trong một phiên Giao Dịch P2P!")
			pushP2PState(player)
			return true
		end
		local target = findTargetPlayer(payload)
		if not target and (sub == "Accept" or sub == "AcceptRequest") then
			local req = pendingP2PRequests[player]
			if req and req.From and req.From.Parent == Players then
				target = req.From
			end
		end
		if not target or target == player then
			G.Notify(player, "Không tìm thấy người chơi đối tác để giao dịch!")
			pushP2PState(player)
			return true
		end
		if activeP2PSessionsByPlayer[target] then
			G.Notify(player, target.DisplayName .. " hiện đang bận giao dịch với người khác!")
			return true
		end
		local okElig, tableId = checkP2PEligibility(player, target, player)
		if not okElig then
			pushP2PState(player)
			return true
		end

		local reqFromTarget = pendingP2PRequests[player]
		local hasMutualReq = reqFromTarget and reqFromTarget.From == target and (os.clock() - (reqFromTarget.At or 0)) <= 60
		if hasMutualReq or sub == "StartWithPlayer" then
			startP2PSession(target, player, tableId or "DirectP2P", true)
			return true
		end

		pendingP2PRequests[target] = { From = player, At = os.clock() }
		G.Notify(player, "Đã gửi lời mời Giao Dịch P2P tới " .. target.DisplayName .. "!")
		G.Notify(target, player.DisplayName .. " mời bạn Giao Dịch P2P! Mở Bàn Giao Dịch để Chấp Nhận.")
		pushP2PState(player)
		pushP2PState(target)
		return true
	end

	local session = activeP2PSessionsByPlayer[player]
	if not session then
		G.Notify(player, "Chưa có phiên Giao Dịch P2P nào đang hoạt động!")
		pushP2PState(player)
		return true
	end
	local partner = (session.PlayerA == player) and session.PlayerB or session.PlayerA

	if sub == "AddFruit" or sub == "AddItem" then
		local myOffers = session.Offers[player]
		if #myOffers >= 4 then
			G.Notify(player, "Mỗi bên chỉ có thể đặt tối đa 4 vật phẩm/Lõi Aether!")
			return true
		end
		local rawId = tostring(payload.itemId or payload.fruitId or payload.id or "")
		local val, normId, isFruit = getTradeItemValue(rawId)
		if sub == "AddFruit" and not isFruit then
			G.Notify(player, "Lõi Aether không hợp lệ: " .. rawId)
			return true
		end
		if val <= 0 or normId == "" then
			G.Notify(player, "Vật phẩm này không thể đưa lên bàn Giao Dịch P2P!")
			return true
		end
		prof.StoredFruits = type(prof.StoredFruits) == "table" and prof.StoredFruits or {}
		prof.Inventory = type(prof.Inventory) == "table" and prof.Inventory or {}
		local alreadyOffered = countOfferedById(myOffers, normId, isFruit)
		local owned = isFruit and (tonumber(prof.StoredFruits[normId]) or 0) or (tonumber(prof.Inventory[normId]) or 0)
		if owned < alreadyOffered + 1 then
			G.Notify(player, "Bạn không đủ [" .. getItemDisplayLabel(normId, isFruit) .. "] trong kho!")
			return true
		end
		table.insert(myOffers, {
			Id = normId,
			Name = getItemDisplayLabel(normId, isFruit),
			IsFruit = isFruit == true,
			Value = val,
		})
		resetSessionLocks(session)
		pushP2PState(player)
		pushP2PState(partner)
		return true
	elseif sub == "RemoveOffer" or sub == "RemoveItem" or sub == "RemoveFruit" or sub == "ClearOffer" then
		local myOffers = session.Offers[player]
		if sub == "ClearOffer" then
			table.clear(myOffers)
		else
			local slotIdx = tonumber(payload.slotIndex or payload.index)
			if slotIdx and myOffers[slotIdx] then
				table.remove(myOffers, slotIdx)
			else
				local rawId = tostring(payload.itemId or payload.fruitId or payload.id or "")
				local _, normId = getTradeItemValue(rawId)
				local targetId = (normId ~= "" and normId) or rawId
				for idx = #myOffers, 1, -1 do
					if myOffers[idx].Id == targetId or myOffers[idx].Id == rawId then
						table.remove(myOffers, idx)
						break
					end
				end
			end
		end
		resetSessionLocks(session)
		pushP2PState(player)
		pushP2PState(partner)
		return true
	elseif sub == "ToggleReady" or sub == "SetReady" or sub == "Ready" then
		local nextReady = (type(payload.ready) == "boolean") and payload.ready or (not session.Ready[player])
		if nextReady then
			local offersA = session.Offers[session.PlayerA] or {}
			local offersB = session.Offers[session.PlayerB] or {}
			if #offersA == 0 and #offersB == 0 then
				G.Notify(player, "Hãy đặt ít nhất 1 vật phẩm lên bàn trước khi Sẵn Sàng!")
				return true
			end
			local _, _, diffPct, isFair = computeSessionMetrics(session)
			if not isFair then
				G.Notify(player, string.format("CHỐNG LỪA ĐẢO 40%%: Chênh lệch %.1f%% (> 40%%) — hãy cân bằng giá trị trước!", diffPct))
				return true
			end
		else
			session.Confirmed[session.PlayerA] = false
			session.Confirmed[session.PlayerB] = false
		end
		session.Ready[player] = nextReady
		pushP2PState(player)
		pushP2PState(partner)
		return true
	elseif sub == "Confirm" or sub == "AcceptFinal" then
		if not (session.Ready[session.PlayerA] and session.Ready[session.PlayerB]) then
			G.Notify(player, "Cả hai người chơi cần nhấn [Sẵn Sàng] trước khi Xác Nhận Giao Dịch!")
			return true
		end
		local _, _, diffPct, isFair = computeSessionMetrics(session)
		if not isFair then
			resetSessionLocks(session)
			G.Notify(player, string.format("CHỐNG LỪA ĐẢO 40%%: Chênh lệch %.1f%% (> 40%%)!", diffPct))
			pushP2PState(player)
			pushP2PState(partner)
			return true
		end
		session.Confirmed[player] = true
		if session.Confirmed[session.PlayerA] and session.Confirmed[session.PlayerB] then
			return executeAtomicP2PSwap(session)
		end
		G.Notify(player, "Đã khóa xác nhận! Đang chờ đối phương xác nhận bước cuối...")
		if partner and partner.Parent == Players then
			G.Notify(partner, player.DisplayName .. " đã Xác Nhận giao dịch! Nhấn [Xác Nhận] để hoàn tất hoán đổi.")
		end
		pushP2PState(player)
		pushP2PState(partner)
		return true
	end

	return false
end

local function handleSetFaction(player, payload)
	payload = type(payload) == "table" and payload or { faction = payload }
	local prof = D.Get(player)
	if not prof then
		return false
	end
	local raw = tostring(payload.faction or payload.id or payload.value or "Pirate")
	local isMarine = (raw == "Marine" or raw == "Skyguard" or raw == "AetherGuardian" or raw == "SkyMarine" or raw == "Guardian")
	prof.Faction = isMarine and "Marine" or "Pirate"
	player:SetAttribute("Faction", prof.Faction)
	if player.Character then
		player.Character:SetAttribute("Faction", prof.Faction)
	end
	local ev = getUIStateUpdatedRemote()
	if ev then
		ev:FireClient(player, { Faction = prof.Faction })
	end
	G.Notify(
		player,
		"Đã gia nhập trận tuyến: "
			.. (prof.Faction == "Marine" and "Hải Quân Thiên Không (Aether Marines)" or "Hải Tặc Bầu Trời (Sky Pirates)")
			.. "!"
	)
	G.Sync(player)
	return true
end

local function handleStartTempleV4Trial(player)
	local prof = D.Get(player)
	if not prof then
		return false
	end
	if (tonumber(player:GetAttribute("PvPCombatUntil")) or 0) > os.time() then
		LiveOps.Notify(G, player, "Đang trong trạng thái Giao Tranh PvP! Không thể dịch chuyển vào Đền Thăng Hoa!", "Cannot enter the Ascension Temple while PvP combat-tagged!")
		return false
	end
	local isDev = DevGate.IsAllowed(player)
	local playerLv = tonumber(prof.Level) or 1
	if playerLv < 1900 and not isDev then
		LiveOps.Notify(G, player, "ĐỀN THĂNG HOA: Yêu cầu đạt tối thiểu Level 1900 để bước vào Thử Thách Thăng Hoa V4!", "ASCENSION TEMPLE: Requires Level 1900+ to start the Race V4 Trial!")
		return false
	end
	local raceTier = tonumber(prof.RaceTier) or 1
	if raceTier < 3 and not isDev then
		LiveOps.Notify(G, player, "ĐỀN THĂNG HOA: Bạn cần tiến hóa Huyết Thống lên Bậc V3 trước khi mở Thử Thách V4!", "ASCENSION TEMPLE: Evolve your Race to Tier V3 before challenging the V4 Trial!")
		return false
	end
	local hasBlueGear = (prof.BlueResonanceGearFound == true)
		or (prof.BlueGearFound == true)
		or (type(prof.Inventory) == "table" and (tonumber(prof.Inventory.BlueResonanceGear) or 0) > 0)
		or (prof.RaceV4Unlocked == true)
	if not hasBlueGear and not isDev then
		LiveOps.Notify(G, player, "ĐỀN THĂNG HOA: Bạn cần tìm thấy Bánh Răng Cộng Hưởng Xanh trên Đảo Ảo Ảnh trước khi mở Thử Thách V4!", "ASCENSION TEMPLE: Find the Blue Resonance Gear on Mirage Sky Island before unlocking the V4 Trial!")
		return false
	end
	local rt = G.Runtime and G.Runtime[player]
	if (rt and (rt.InRaid or rt.InDuel or rt.InTrial)) or (tonumber(player:GetAttribute("SpireFloor")) or 0) > 0 then
		G.Notify(player, "Không thể bước vào Đền Thăng Hoa khi đang ở trong phó bản/đấu trường!")
		return false
	end

	local expMod = Services:FindFirstChild("SkybreakCombatExpansion")
	local okExp, expSvc = pcall(function()
		return expMod and require(expMod) or nil
	end)
	if not (okExp and expSvc and type(expSvc.StartTempleRaceV4Trial) == "function") then
		G.Notify(player, "ĐỀN THĂNG HOA: Hệ thống Thử Thách đang khởi tạo, vui lòng thử lại sau giây lát!")
		return false
	end

	local templePos = (C.FastTravel and C.FastTravel.TempleOfTheCore and C.FastTravel.TempleOfTheCore.Pos) or Vector3.new(-14600, 50.9, -1785)
	local fy = groundYAt(templePos + Vector3.new(0, 0, -18), templePos.Y - 4)
	local altarPos = Vector3.new(templePos.X, fy, templePos.Z - 18)

	local ch = player.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if hrp and (hrp.Position - altarPos).Magnitude > 140 then
		player:SetAttribute("CurrentRealm", "ShadowRealm")
		G.Teleport(player, altarPos + Vector3.new(0, 3.2, 8))
	end

	expSvc.StartTempleRaceV4Trial(player, altarPos)
	G.Sync(player)
	return true
end

function VendorService.HandleUIRequest(player, cmd, payload)
	if type(cmd) ~= "string" then
		return false
	end
	if cmd == "BuyVendorItem" or cmd == "TradeWithCollector" or cmd == "P2PTradeAction" or cmd == "P2PTrade" or cmd == "SetFaction" or cmd == "StartTempleV4Trial" then
		local now = os.clock()
		local key = tostring(player.UserId) .. ":" .. cmd
		if cmdDebounce[key] and (now - cmdDebounce[key]) < 0.08 then
			return true
		end
		cmdDebounce[key] = now
	end

	if cmd == "BuyVendorItem" then
		return handleBuyVendorItem(player, payload)
	elseif cmd == "TradeWithCollector" then
		return handleTradeWithCollector(player, payload)
	elseif cmd == "P2PTradeAction" or cmd == "P2PTrade" then
		return handleP2PTradeAction(player, payload)
	elseif cmd == "SetFaction" then
		return handleSetFaction(player, payload)
	elseif cmd == "StartTempleV4Trial" then
		return handleStartTempleV4Trial(player)
	end
	return false
end

-- ============================================================================
-- 5. SERVICE LIFECYCLE BOOTSTRAP
-- ============================================================================
local function bindPlayerArmorSync(plr)
	task.defer(function()
		local prof = D.Get(plr)
		if prof then
			VendorService.SyncCharacterArmorAttributes(plr, prof)
		end
	end)
	plr.CharacterAdded:Connect(function()
		task.defer(function()
			local prof = D.Get(plr)
			if prof then
				VendorService.SyncCharacterArmorAttributes(plr, prof)
			end
		end)
	end)
end

function VendorService.Start()
	if started then
		return
	end
	started = true

	buildAllVendorStations()
	-- Re-snap vendor station floors once streamed island geometry settles
	task.delay(3.5, function()
		pcall(buildAllVendorStations)
	end)

	for _, plr in ipairs(Players:GetPlayers()) do
		bindPlayerArmorSync(plr)
	end
	Players.PlayerAdded:Connect(bindPlayerArmorSync)
	Players.PlayerRemoving:Connect(function(plr)
		local sess = activeP2PSessionsByPlayer[plr]
		if sess then
			cancelP2PSession(sess, plr.DisplayName .. " đã rời máy chủ — hủy phiên Giao Dịch P2P.")
		end
		pendingP2PRequests[plr] = nil
		for targetPlr, req in pairs(pendingP2PRequests) do
			if req.From == plr then
				pendingP2PRequests[targetPlr] = nil
			end
		end
		local prefix = tostring(plr.UserId) .. ":"
		for k in pairs(cmdDebounce) do
			if string.sub(k, 1, #prefix) == prefix then
				cmdDebounce[k] = nil
			end
		end
	end)
end

return VendorService
