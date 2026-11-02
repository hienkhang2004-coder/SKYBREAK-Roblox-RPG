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

local SkybreakServer = Services.Parent:WaitForChild("SkybreakServer")
local InventoryService = require(SkybreakServer:WaitForChild("InventoryService"))

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
-- 3. SCULPTED 3D NPC VENDOR STATIONS (Sea 1, Sea 2 & Sea 3)
-- ============================================================================
local function buildSculptedVendorNPC(stationModel, basePos, accentColor, vendorKind, visualAsset)
	local darkNavy = Color3.fromRGB(24, 34, 56)
	local goldTrim = Color3.fromRGB(232, 186, 82)
	local skinTone = Color3.fromRGB(238, 212, 188)

	-- Dais pedestal
	local dais = Instance.new("Part")
	dais.Name = "VendorDais"
	dais.Shape = Enum.PartType.Cylinder
	dais.Size = Vector3.new(0.64, 5.8, 5.8)
	dais.CFrame = CFrame.new(basePos + Vector3.new(0, 0.32, 0)) * CFrame.Angles(0, 0, math.pi * 0.5)
	dais.Color = darkNavy
	dais.Material = Enum.Material.Metal
	dais.Anchored = true
	dais.Parent = stationModel

	makeAnchoredPart(
		stationModel,
		"VendorAuraRing",
		Vector3.new(0.14, 6.3, 6.3),
		CFrame.new(basePos + Vector3.new(0, 0.66, 0)) * CFrame.Angles(0, 0, math.pi * 0.5),
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
	rootPart.Position = basePos + Vector3.new(0, 2.85, 0)
	rootPart.Color = darkNavy
	rootPart.Material = Enum.Material.Metal
	rootPart.Transparency = 1
	rootPart.Anchored = true
	rootPart.CanCollide = true
	rootPart.Parent = stationModel

	makeAnchoredPart(stationModel, "LowerTunic", Vector3.new(1.75, 1.85, 1.05), CFrame.new(basePos + Vector3.new(0, 1.55, 0)), darkNavy, Enum.Material.SmoothPlastic)
	makeAnchoredPart(stationModel, "UpperTorso", Vector3.new(1.85, 1.75, 1.02), CFrame.new(basePos + Vector3.new(0, 3.25, 0)), darkNavy, Enum.Material.Metal)
	makeAnchoredPart(stationModel, "ChestEmblem", Vector3.new(0.75, 0.75, 0.16), CFrame.new(basePos + Vector3.new(0, 3.35, -0.52)), accentColor, Enum.Material.Neon)
	makeAnchoredPart(stationModel, "VendorCape", Vector3.new(2.05, 2.95, 0.14), CFrame.new(basePos + Vector3.new(0, 2.45, 0.58)) * CFrame.Angles(math.rad(8), 0, 0), accentColor:Lerp(darkNavy, 0.52), Enum.Material.SmoothPlastic)

	for _, side in ipairs({ -1, 1 }) do
		makeAnchoredPart(
			stationModel,
			"Pauldron_" .. side,
			Vector3.new(0.72, 0.44, 1.08),
			CFrame.new(basePos + Vector3.new(side * 1.18, 3.98, 0)) * CFrame.Angles(0, 0, math.rad(-side * 16)),
			goldTrim,
			Enum.Material.Metal
		)
	end

	local head = makeAnchoredPart(stationModel, "Head", Vector3.new(1.22, 1.26, 1.22), CFrame.new(basePos + Vector3.new(0, 4.78, 0)), skinTone, Enum.Material.SmoothPlastic, Enum.PartType.Ball)
	makeAnchoredPart(
		stationModel,
		"HaloCrown",
		Vector3.new(0.12, 1.68, 1.68),
		CFrame.new(basePos + Vector3.new(0, 5.32, 0.12)) * CFrame.Angles(0, math.pi * 0.5, math.rad(16)),
		accentColor,
		Enum.Material.Neon,
		Enum.PartType.Cylinder
	)

	-- Signature 3D Shop Props beside the Vendor
	if vendorKind == "SwordDealer" then
		makeAnchoredPart(stationModel, "AnvilStand", Vector3.new(1.6, 1.2, 1.0), CFrame.new(basePos + Vector3.new(1.9, 1.24, -0.4)), darkNavy, Enum.Material.Metal)
		makeAnchoredPart(stationModel, "DisplayBladeA", Vector3.new(0.16, 3.2, 0.34), CFrame.new(basePos + Vector3.new(1.75, 2.95, -0.4)) * CFrame.Angles(0, 0, math.rad(-14)), accentColor, Enum.Material.Neon)
		makeAnchoredPart(stationModel, "DisplayBladeB", Vector3.new(0.16, 3.0, 0.32), CFrame.new(basePos + Vector3.new(2.12, 2.85, -0.4)) * CFrame.Angles(0, 0, math.rad(14)), goldTrim, Enum.Material.Neon)
	elseif vendorKind == "GunDealer" then
		makeAnchoredPart(stationModel, "OrdnanceCrate", Vector3.new(1.7, 1.25, 1.2), CFrame.new(basePos + Vector3.new(1.95, 1.26, -0.35)), darkNavy, Enum.Material.Metal)
		makeAnchoredPart(stationModel, "DisplayCannon", Vector3.new(2.2, 0.54, 0.54), CFrame.new(basePos + Vector3.new(1.95, 2.25, -0.35)) * CFrame.Angles(0, math.rad(65), math.rad(22)), accentColor, Enum.Material.Neon, Enum.PartType.Cylinder)
	elseif vendorKind == "TradingTable" then
		makeAnchoredPart(stationModel, "HoloTradeTable", Vector3.new(0.85, 3.4, 3.4), CFrame.new(basePos + Vector3.new(0, 1.15, -2.35)) * CFrame.Angles(0, 0, math.pi * 0.5), darkNavy, Enum.Material.Metal, Enum.PartType.Cylinder)
		makeAnchoredPart(stationModel, "HoloScaleGrid", Vector3.new(0.12, 2.8, 2.8), CFrame.new(basePos + Vector3.new(0, 1.62, -2.35)) * CFrame.Angles(0, 0, math.pi * 0.5), accentColor, Enum.Material.Neon, Enum.PartType.Cylinder, "Part", 0.2)
	elseif vendorKind == "ColosseumAndSpire" then
		for _, side in ipairs({ -1, 1 }) do
			makeAnchoredPart(stationModel, "SpirePillar_" .. side, Vector3.new(0.55, 4.8, 0.55), CFrame.new(basePos + Vector3.new(side * 2.15, 3.0, 0.45)), goldTrim, Enum.Material.Metal)
			makeAnchoredPart(stationModel, "SpireOrb_" .. side, Vector3.new(0.75, 0.75, 0.75), CFrame.new(basePos + Vector3.new(side * 2.15, 5.65, 0.45)), accentColor, Enum.Material.Neon, Enum.PartType.Ball)
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

	local rootPart, headPart = buildSculptedVendorNPC(m, base, spec.Color, spec.VendorMode, spec.VisualAsset)

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

	m.Parent = folder
	return m
end

local function buildAllVendorStations()
	local vendorFolder = ensureWorldSubfolder("VendorNPCs")
	vendorFolder:ClearAllChildren()

	local skyPos = C.Spawn or Vector3.new(-317.4, 50.5, 527.8)
	local cafePos = (C.FastTravel and C.FastTravel.CyberportCafe and C.FastTravel.CyberportCafe.Pos) or Vector3.new(9400, 50.9, 1785)
	local castlePos = (C.FastTravel and C.FastTravel.CastleOnTheVoid and C.FastTravel.CastleOnTheVoid.Pos) or Vector3.new(-14600, 50.9, 2173.1)

	local specs = {
		-- 1. Master Sword Dealers (Sea 1, Sea 2, Sea 3)
		{
			Id = "MasterSwordDealer_Sea1",
			Title = "Kiếm Sư Thương Nhân",
			RoleTag = "< CỬA HÀNG THẦN KIẾM 3D >",
			ActionText = "Giao Dịch Thần Kiếm 3D",
			VendorMode = "SwordDealer",
			VisualAsset = "GoldenKnight",
			Color = Color3.fromRGB(244, 193, 78),
			RawPos = skyPos + Vector3.new(-22, 0, -16),
			DialogueRole = "ĐẠI SƯ VŨ KHÍ CẬN CHIẾN",
			DialogueBody = "Ta rèn và tuyển chọn 18 thanh Thần Kiếm, Đại Đao, Kích và Lưỡi Hái Thời Không mạnh nhất 3 Biển! Hãy chọn vũ khí phù hợp với cấp độ của ngươi.",
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
			RawPos = cafePos + Vector3.new(-18, 0, -14),
			DialogueRole = "ĐẠI SƯ VŨ KHÍ CẬN CHIẾN",
			DialogueBody = "Ta rèn và tuyển chọn 18 thanh Thần Kiếm, Đại Đao, Kích và Lưỡi Hái Thời Không mạnh nhất 3 Biển! Hãy chọn vũ khí phù hợp với cấp độ của ngươi.",
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
			RawPos = castlePos + Vector3.new(-18, 0, -14),
			DialogueRole = "ĐẠI SƯ VŨ KHÍ CẬN CHIẾN",
			DialogueBody = "Ta rèn và tuyển chọn 18 thanh Thần Kiếm, Đại Đao, Kích và Lưỡi Hái Thời Không mạnh nhất 3 Biển! Hãy chọn vũ khí phù hợp với cấp độ của ngươi.",
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
			RawPos = skyPos + Vector3.new(-28, 0, -6),
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
			RawPos = cafePos + Vector3.new(18, 0, -14),
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
			RawPos = castlePos + Vector3.new(18, 0, -14),
			DialogueRole = "BẬC THẦY PHÁP KHÍ & XẠ KÍCH",
			DialogueBody = "Từ Súng Lục Aether, Cung Tinh Linh Sylvaris đến Pháo Kỳ Điểm Veyr — 10 Pháp Khí tầm xa và Bộ Thần Giáp 3D mạnh nhất đều có mặt tại xưởng của ta!",
			ButtonLabel = "Mở Xưởng Pháp Khí 3D",
		},

		-- 3. Phantom 4x4 Trading Tables & Collector (Sea 1, Sea 2)
		{
			Id = "PhantomTradingTable_Sea1",
			Title = "Bàn Giao Dịch Trái 4x4 & Nhà Sưu Tập",
			RoleTag = "< GIAO DỊCH CHỐNG LỪA ĐẢO <=40% >",
			ActionText = "Mở Bàn Giao Dịch Trái 4x4",
			VendorMode = "TradingTable",
			VisualAsset = "ZiolesGachaNPC",
			Color = Color3.fromRGB(192, 132, 252),
			RawPos = skyPos + Vector3.new(18, 0, -18),
			DialogueRole = "NHÀ SƯU TẬP ẢO ẢNH & BÀN TRAO ĐỔI 4X4",
			DialogueBody = "Đặt tối đa 4 Trái Ác Quỷ lên bàn cân chống lừa đảo (khóa nghiêm ngặt chênh lệch <= 40%), hoặc ký ngay các Khế Ước Thần Thoại công bằng với Nhà Sưu Tập!",
			ButtonLabel = "Mở Bàn Giao Dịch 4x4",
		},
		{
			Id = "PhantomTradingTable_Sea2",
			Title = "Bàn Giao Dịch Trái 4x4 & Nhà Sưu Tập",
			RoleTag = "< GIAO DỊCH CHỐNG LỪA ĐẢO <=40% >",
			ActionText = "Mở Bàn Giao Dịch Trái 4x4",
			VendorMode = "TradingTable",
			VisualAsset = "ZiolesGachaNPC",
			Color = Color3.fromRGB(192, 132, 252),
			RawPos = cafePos + Vector3.new(0, 0, 14),
			DialogueRole = "NHÀ SƯU TẬP ẢO ẢNH & BÀN TRAO ĐỔI 4X4",
			DialogueBody = "Đặt tối đa 4 Trái Ác Quỷ lên bàn cân chống lừa đảo (khóa nghiêm ngặt chênh lệch <= 40%), hoặc ký ngay các Khế Ước Thần Thoại công bằng với Nhà Sưu Tập!",
			ButtonLabel = "Mở Bàn Giao Dịch 4x4",
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
			RawPos = skyPos + Vector3.new(26, 0, -8),
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
			RawPos = cafePos + Vector3.new(-16, 0, 16),
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
	local expItem = ArsenalExpansionConfig.Items[itemId]
	if expItem then
		return tonumber(expItem.PriceGold) or 0, tonumber(expItem.PriceShards) or 0, nil
	end
	local rItem = RarityConfig.Items[itemId]
	if rItem then
		if rItem.PriceGold ~= nil or rItem.PriceShards ~= nil then
			return tonumber(rItem.PriceGold) or 0, tonumber(rItem.PriceShards) or 0, nil
		end
		local rar = RarityConfig.GetRarity(rItem.Rarity)
		local tier = (rar and rar.Tier) or 1
		if tier <= 1 then
			return 0, 0, nil
		end
		return tier * 15000, (tier >= 4 and tier * 30 or 0), nil
	end
	return nil, nil, nil
end

local function handleBuyVendorItem(player, payload)
	payload = type(payload) == "table" and payload or { itemId = payload }
	local itemId = tostring(payload.itemId or payload.id or payload.shipId or payload.styleId or payload.value or "")
	if itemId == "" then
		return false
	end

	local prof = D.Get(player)
	if not prof then
		return false
	end
	prof.Inventory = type(prof.Inventory) == "table" and prof.Inventory or {}
	prof.Equipped = type(prof.Equipped) == "table" and prof.Equipped or {}
	prof.Gold = tonumber(prof.Gold) or 0
	prof.CoreShards = tonumber(prof.CoreShards) or 0

	-- Case A: Buying / Spawning a Sky-Ship from ShipwrightFleet
	for _, shipEntry in ipairs(ArsenalExpansionConfig.VendorCatalogs.ShipwrightFleet or {}) do
		if shipEntry.Id == itemId or shipEntry.ShipId == itemId then
			prof.UnlockedShips = type(prof.UnlockedShips) == "table" and prof.UnlockedShips or { SkySloop = true }
			local shipKey = shipEntry.Id
			if not prof.UnlockedShips[shipKey] and (shipEntry.PriceGold or 0) > 0 then
				if prof.Gold < shipEntry.PriceGold then
					G.Notify(player, string.format("Cần %d Gold để đóng chiến hạm [%s]!", shipEntry.PriceGold, shipEntry.NameVi))
					return true
				end
				prof.Gold -= shipEntry.PriceGold
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
			if not prof.UnlockedStyles[sKey] then
				local needG = tonumber(stEntry.PriceGold) or 0
				local needS = tonumber(stEntry.PriceShards) or 0
				if prof.Gold < needG or prof.CoreShards < needS then
					G.Notify(player, string.format("Cần %d Gold & %d Core Shards để lĩnh ngộ [%s]!", needG, needS, stEntry.NameVi))
					return true
				end
				prof.Gold -= needG
				prof.CoreShards -= needS
				prof.UnlockedStyles[sKey] = true
			end
			local combatId = stEntry.FallbackCombatStyleId or stEntry.StyleId or sKey
			prof.UnlockedStyles[combatId] = true
			prof.FightingStyle = combatId
			prof.DisplayFightingStyle = sKey
			prof.ActiveSlot = 1
			player:SetAttribute("FightingStyle", combatId)
			if player.Character then
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
	if not itemDef and not cItem then
		G.Notify(player, "Không tìm thấy vật phẩm [" .. itemId .. "] trong danh mục cửa hàng!")
		return true
	end

	local costGold, costShards = resolveVendorPrice(itemId)
	costGold = tonumber(costGold) or 0
	costShards = tonumber(costShards) or 0

	local displayName = (itemDef and (itemDef.VietnameseName or itemDef.Name))
		or (cItem and cItem.Name)
		or itemId
	local isMaterial = (itemDef and (itemDef.Category == "Materials" or itemDef.Category == "Quest"))
		or (cItem and (cItem.Slot == "Material" or cItem.Slot == "Quest"))
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

	local payMode = tostring(payload.currency or payload.payWith or "")
	if payMode == "Shards" or payMode == "CoreShards" then
		local shardOnly = costShards > 0 and costShards or math.max(10, math.floor(costGold / 500))
		if prof.CoreShards < shardOnly then
			G.Notify(player, string.format("Cần %d Core Shards để sở hữu [%s]!", shardOnly, displayName))
			return true
		end
		prof.CoreShards -= shardOnly
	elseif payMode == "Gold" then
		if prof.Gold < costGold then
			G.Notify(player, string.format("Cần %d Gold để sở hữu [%s]!", costGold, displayName))
			return true
		end
		prof.Gold -= costGold
	else
		if costGold > 0 or costShards > 0 then
			if prof.Gold < costGold or prof.CoreShards < costShards then
				G.Notify(player, string.format("Cần %d Gold & %d Core Shards để mua [%s]!", costGold, costShards, displayName))
				return true
			end
			prof.Gold -= costGold
			prof.CoreShards -= costShards
		end
	end

	local qty = math.clamp(math.floor(tonumber(payload.quantity or payload.count) or 1), 1, 20)
	if not isMaterial then
		qty = 1
	end
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
	local cid = (CombatData.ResolveFruitId and CombatData.ResolveFruitId(id)) or tostring(id or "")
	if cid ~= "" and C.AetherFruits and C.AetherFruits[cid] then
		return tonumber(C.AetherFruits[cid].Price) or 100000, cid, true
	end
	if cid ~= "" and CombatData.FruitCatalog and CombatData.FruitCatalog[cid] then
		return tonumber(CombatData.FruitCatalog[cid].Value or CombatData.FruitCatalog[cid].Price) or 100000, cid, true
	end
	local rawId = tostring(id or "")
	local g, s = resolveVendorPrice(rawId)
	if g or s then
		return math.max(25000, (tonumber(g) or 0) + (tonumber(s) or 0) * 500), rawId, false
	end
	return 0, rawId, false
end

local function handleTradeWithCollector(player, payload)
	payload = type(payload) == "table" and payload or { offerId = payload }
	local prof = D.Get(player)
	if not prof then
		return false
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

	if not giveList and type(payload.giveFruits or payload.giveItems) == "table" then
		giveList = payload.giveFruits or payload.giveItems
		receiveList = payload.receiveFruits or payload.receiveItems
	end

	if type(giveList) ~= "table" or #giveList == 0 or #giveList > 4 then
		G.Notify(player, "Hãy chọn từ 1 đến 4 vật phẩm/Trái Ác Quỷ để giao dịch với Nhà Sưu Tập!")
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

	-- Auto-match a fair Collector fruit within <= 40% if receiveList wasn't explicitly specified
	if type(receiveList) ~= "table" or #receiveList == 0 then
		local bestFruitId = nil
		local bestDiff = math.huge
		for fid, fDef in pairs(C.AetherFruits or {}) do
			if not needCounts[fid] then
				local pVal = tonumber(fDef.Price) or 0
				local d = math.abs(pVal - giveValue)
				if pVal > 0 and d < bestDiff then
					bestDiff = d
					bestFruitId = fid
				end
			end
		end
		if bestFruitId then
			receiveList = { bestFruitId }
		end
	end

	if type(receiveList) ~= "table" or #receiveList == 0 or #receiveList > 4 then
		G.Notify(player, "Nhà Sưu Tập chưa tìm thấy vật phẩm đối ứng phù hợp!")
		return true
	end

	local receiveValue = 0
	local normalizedReceives = {}
	for _, raw in ipairs(receiveList) do
		local val, normId, isFruit = getTradeItemValue(raw)
		if val <= 0 or normId == "" then
			G.Notify(player, "Vật phẩm nhận không hợp lệ: " .. tostring(raw))
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

	-- Deduct player's offered items
	for normId, reqCount in pairs(needCounts) do
		if isFruitMap[normId] then
			local rem = math.max(0, (tonumber(prof.StoredFruits[normId]) or 0) - reqCount)
			prof.StoredFruits[normId] = rem > 0 and rem or nil
		else
			local rem = math.max(0, (tonumber(prof.Inventory[normId]) or 0) - reqCount)
			prof.Inventory[normId] = rem > 0 and rem or nil
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
			local iDef = ArsenalExpansionConfig.Items[rec.Id] or RarityConfig.Items[rec.Id]
			table.insert(receivedNames, (iDef and (iDef.VietnameseName or iDef.Name)) or rec.Id)
		end
	end

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
	local templePos = (C.FastTravel and C.FastTravel.TempleOfTheCore and C.FastTravel.TempleOfTheCore.Pos) or Vector3.new(-14600, 50.9, -1785)
	local fy = groundYAt(templePos + Vector3.new(0, 0, -12), templePos.Y - 4)
	local altarPos = Vector3.new(templePos.X, fy, templePos.Z - 12)

	local ch = player.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	if hrp and (hrp.Position - altarPos).Magnitude > 140 then
		player:SetAttribute("CurrentRealm", "ShadowRealm")
		G.Teleport(player, altarPos + Vector3.new(0, 3.2, 8))
	end

	local expMod = Services:FindFirstChild("SkybreakCombatExpansion")
	local okExp, expSvc = pcall(function()
		return expMod and require(expMod) or nil
	end)
	if okExp and expSvc and type(expSvc.StartTempleRaceV4Trial) == "function" then
		expSvc.StartTempleRaceV4Trial(player, altarPos)
		G.Sync(player)
		return true
	end

	-- Safe fallback if trial helper isn't bound yet
	prof.RaceV4Unlocked = true
	prof.RaceTier = 4
	prof.CoreGears = (tonumber(prof.CoreGears) or 0) + 1
	prof.AwakeningMeter = 100
	player:SetAttribute("RaceV4Unlocked", true)
	G.Notify(player, "ĐỀN THỜ LÕI CỔ ĐẠI: Đã kích hoạt Thức Tỉnh Tộc V4 [" .. tostring(prof.Race or "Skyborn") .. "] + 1 Core Gear!")
	G.Sync(player)
	return true
end

function VendorService.HandleUIRequest(player, cmd, payload)
	if type(cmd) ~= "string" then
		return false
	end
	if cmd == "BuyVendorItem" or cmd == "TradeWithCollector" or cmd == "SetFaction" or cmd == "StartTempleV4Trial" then
		local now = os.clock()
		local key = tostring(player.UserId) .. ":" .. cmd
		if cmdDebounce[key] and (now - cmdDebounce[key]) < 0.12 then
			return true
		end
		cmdDebounce[key] = now
	end

	if cmd == "BuyVendorItem" then
		return handleBuyVendorItem(player, payload)
	elseif cmd == "TradeWithCollector" then
		return handleTradeWithCollector(player, payload)
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
		local prefix = tostring(plr.UserId) .. ":"
		for k in pairs(cmdDebounce) do
			if string.sub(k, 1, #prefix) == prefix then
				cmdDebounce[k] = nil
			end
		end
	end)

	-- Also listen on legacy ReplicatedStorage.Remotes.UIRequest for our 4 new vendor commands
	local legacyRemotes = ReplicatedStorage:FindFirstChild("Remotes")
	local uiReq = legacyRemotes and legacyRemotes:FindFirstChild("UIRequest")
	if uiReq and uiReq:IsA("RemoteEvent") then
		uiReq.OnServerEvent:Connect(function(plr, cmdOrPayload, arg2)
			local cmd = type(cmdOrPayload) == "string" and cmdOrPayload
				or (type(cmdOrPayload) == "table" and (cmdOrPayload.command or cmdOrPayload.action or cmdOrPayload.cmd))
			if cmd == "BuyVendorItem" or cmd == "TradeWithCollector" or cmd == "SetFaction" or cmd == "StartTempleV4Trial" then
				local payload = type(cmdOrPayload) == "table" and cmdOrPayload
					or (type(arg2) == "table" and arg2 or { value = arg2 })
				VendorService.HandleUIRequest(plr, cmd, payload)
			end
		end)
	end
end

return VendorService
