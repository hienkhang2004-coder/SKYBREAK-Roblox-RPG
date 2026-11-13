-- SkybreakWildCoreService.lua
-- Server-global 45-minute (2700s) random-island Wild Aether Core spawner (D-A7).
-- First spawn at 15-20m (900-1200s) server uptime; 20m (1200s) despawn;
-- weighted 12-Core roll; bilingual EN/VI rumor toast; <=28-stud proximity & GetMaxCoreStorage enforcement.

local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local WildCoreService = {}

local C, D, G, W, R, Helpers, CombatData
local started = false
local ActiveWildCore = nil -- { Model, Part, FruitId, IslandName, Position, SpawnedClock, ExpiresClock, Claimed }
local AlliedSeaBeasts = {} -- [Player] = SeaBeastRecord
local LastWaterPadPos = {} -- [Player] = Vector3
local WorldRoot = nil

local function ensureWorldFolder(name)
	if not WorldRoot or not WorldRoot.Parent then
		WorldRoot = workspace:FindFirstChild("SkybreakExpansionWorld")
		if not WorldRoot then
			WorldRoot = Instance.new("Folder")
			WorldRoot.Name = "SkybreakExpansionWorld"
			WorldRoot.Parent = workspace
		end
	end
	local sub = WorldRoot:FindFirstChild(name)
	if not sub then
		sub = Instance.new("Folder")
		sub.Name = name
		sub.Parent = WorldRoot
	end
	return sub
end

local RARITY_COLORS = {
	Common = Color3.fromRGB(168, 224, 255),
	Uncommon = Color3.fromRGB(110, 236, 168),
	Rare = Color3.fromRGB(92, 188, 255),
	Epic = Color3.fromRGB(196, 124, 255),
	Legendary = Color3.fromRGB(255, 168, 72),
	Mythic = Color3.fromRGB(255, 86, 128),
	Mythical = Color3.fromRGB(255, 86, 128),
}

local function getCharRoot(p)
	local ch = p and p.Character
	if not ch then
		return nil, nil
	end
	return ch:FindFirstChild("HumanoidRootPart"), ch:FindFirstChildOfClass("Humanoid")
end

local function getMaxCoreStorage(plr, prof)
	if Helpers and type(Helpers.GetMaxCoreStorage) == "function" then
		local ok, cap = pcall(Helpers.GetMaxCoreStorage, plr, prof)
		if ok and tonumber(cap) then
			return math.max(1, math.floor(tonumber(cap)))
		end
	end
	return math.max(1, math.floor(tonumber(prof and prof.MaxFruitStorage) or 1))
end

local function ensureDroppedFruitsFolder()
	local swo = workspace:FindFirstChild("SkybreakWorldObjects")
	if not swo then
		swo = Instance.new("Folder")
		swo.Name = "SkybreakWorldObjects"
		swo.Parent = workspace
	end
	local df = swo:FindFirstChild("DroppedFruits")
	if not df then
		df = Instance.new("Folder")
		df.Name = "DroppedFruits"
		df.Parent = swo
	end
	return df
end

local function collectSpawnableIslands()
	local list = {}
	local seen = {}
	local function push(id, isl)
		if type(isl) ~= "table" then
			return
		end
		local sid = tostring(isl.Id or id or "")
		if sid == "" or seen[sid] then
			return
		end
		local low = string.lower(sid)
		if string.find(low, "raid", 1, true) or string.find(low, "trial", 1, true) or string.find(low, "spire", 1, true) then
			return
		end
		local pos = isl.Pos or isl.Spawn
		if typeof(pos) ~= "Vector3" then
			return
		end
		seen[sid] = true
		table.insert(list, {
			Id = sid,
			Name = tostring(isl.Name or sid),
			Pos = pos,
		})
	end
	if C and type(C.Islands) == "table" then
		for idx, isl in ipairs(C.Islands) do
			push(idx, isl)
		end
	end
	if C and type(C.FastTravel) == "table" then
		for id, node in pairs(C.FastTravel) do
			push(id, node)
		end
	end
	if #list == 0 then
		table.insert(list, {
			Id = "SkyHub",
			Name = "Sky Hub",
			Pos = (C and C.Spawn) or Vector3.new(-317.4, 50.5, 527.8),
		})
	end
	return list
end

local function snapToIslandSurface(basePos)
	local candidate = basePos
	if W and type(W.SnapToOpenGround) == "function" then
		local ok, snapped = pcall(W.SnapToOpenGround, basePos, 6)
		if ok and typeof(snapped) == "Vector3" then
			candidate = snapped
		end
	end
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	local excl = {}
	for _, fn in ipairs({ "ActiveEnemies", "ActiveBosses", "TempFX", "DestructibleProps" }) do
		local f = workspace:FindFirstChild(fn)
		if f then
			table.insert(excl, f)
		end
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then
			table.insert(excl, plr.Character)
		end
	end
	rp.FilterDescendantsInstances = excl
	rp.RespectCanCollide = true

	local hit = workspace:Raycast(Vector3.new(candidate.X, candidate.Y + 85, candidate.Z), Vector3.new(0, -190, 0), rp)
	if hit and hit.Position then
		return Vector3.new(candidate.X, hit.Position.Y, candidate.Z)
	end
	return candidate
end

local function rollCanonicalWildCoreId()
	local rawId = nil
	if C and type(C.RollWeightedFruit) == "function" then
		local ok, picked = pcall(C.RollWeightedFruit)
		if ok and type(picked) == "string" and picked ~= "" then
			rawId = picked
		end
	end
	if not rawId and CombatData and type(CombatData.RollWeightedFruit) == "function" then
		rawId = CombatData.RollWeightedFruit()
	end
	local cid = (CombatData and CombatData.ResolveFruitId(rawId or "GaleCore")) or "GaleCore"
	if not (CombatData and CombatData.FruitCatalog and CombatData.FruitCatalog[cid]) then
		cid = "GaleCore"
	end
	return cid
end

local function clearActiveWildCore()
	if ActiveWildCore then
		local m = ActiveWildCore.Model
		ActiveWildCore = nil
		if m and m.Parent then
			m:Destroy()
		end
	end
	workspace:SetAttribute("WildCoreActive", false)
	workspace:SetAttribute("WildCoreEndsAt", 0)
end

local function grantClaimedCoreToPlayer(plr, cid, dropModel, isWildGlobal, ensureProfileFn)
	local prof = D and D.Get(plr)
	if not prof then
		return false
	end
	if type(ensureProfileFn) == "function" then
		ensureProfileFn(prof)
	end
	prof.StoredFruits = type(prof.StoredFruits) == "table" and prof.StoredFruits or {}
	local cat = CombatData and CombatData.FruitCatalog and CombatData.FruitCatalog[cid]
	if not cat then
		return false
	end

	local maxCap = getMaxCoreStorage(plr, prof)
	local curCount = tonumber(prof.StoredFruits[cid]) or 0
	if curCount >= maxCap then
		if G and G.Notify then
			G.Notify(
				plr,
				string.format(
					"Kho Lõi [%s] đã đầy (%d/%d)! Hãy mở rộng Sức Chứa Lõi hoặc giải phóng kho trước khi nhặt! / [%s] Core Storage is full (%d/%d)!",
					cat.Name,
					curCount,
					maxCap,
					cid,
					curCount,
					maxCap
				)
			)
		end
		return false
	end

	if isWildGlobal then
		if not ActiveWildCore or ActiveWildCore.Claimed or ActiveWildCore.Model ~= dropModel then
			return false
		end
		ActiveWildCore.Claimed = true
		clearActiveWildCore()
	else
		if not dropModel or not dropModel.Parent or dropModel:GetAttribute("Claimed") == true then
			return false
		end
		dropModel:SetAttribute("Claimed", true)
		dropModel:Destroy()
	end

	prof.StoredFruits[cid] = curCount + 1
	prof.HeldFruit = cid
	plr:SetAttribute("HeldFruit", cid)
	if plr.Character then
		plr.Character:SetAttribute("HeldFruit", cid)
	end

	if G and G.Notify then
		if isWildGlobal then
			G.Notify(
				plr,
				string.format(
					"THU THẬP LÕI HOANG DÃ: Bạn đã nhặt được [%s] (%d/%d Kho Lõi)! / Claimed Wild Aether Core [%s] (%d/%d Storage)!",
					cat.Name,
					curCount + 1,
					maxCap,
					cid,
					curCount + 1,
					maxCap
				)
			)
		else
			G.Notify(
				plr,
				string.format(
					"Đã nhặt Lõi Aether 3D: [%s] (%d/%d Kho Lõi)! / Picked up Aether Core [%s] (%d/%d)!",
					cat.Name,
					curCount + 1,
					maxCap,
					cid,
					curCount + 1,
					maxCap
				)
			)
		end
	end
	if G and G.Sync then
		G.Sync(plr)
	end
	return true
end

function WildCoreService.SpawnWildCoreNow(ensureProfileFn, isInTradeFn)
	clearActiveWildCore()

	local islands = collectSpawnableIslands()
	local chosenIsl = islands[math.random(1, #islands)]
	local angle = math.random() * math.pi * 2
	local radius = math.random(10, 26)
	local rawSpot = chosenIsl.Pos + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
	local groundPos = snapToIslandSurface(rawSpot)
	local corePos = groundPos + Vector3.new(0, 1.85, 0)

	local cid = rollCanonicalWildCoreId()
	local cat = CombatData.FruitCatalog[cid]
	local col = RARITY_COLORS[cat and cat.Rarity or "Common"] or Color3.fromRGB(130, 224, 255)

	local dropFolder = ensureDroppedFruitsFolder()
	local m = Instance.new("Model")
	m.Name = "WildAetherCore_" .. cid
	m:SetAttribute("FruitId", cid)
	m:SetAttribute("FruitRarity", cat and cat.Rarity or "Common")
	m:SetAttribute("IsWildCore", true)

	local ped = Instance.new("Part")
	ped.Name = "WildCorePedestal"
	ped.Shape = Enum.PartType.Cylinder
	ped.Size = Vector3.new(0.55, 3.2, 3.2)
	ped.CFrame = CFrame.new(groundPos + Vector3.new(0, 0.28, 0)) * CFrame.Angles(0, 0, math.pi * 0.5)
	ped.Color = Color3.fromRGB(42, 52, 74)
	ped.Material = Enum.Material.Slate
	ped.Anchored = true
	ped.CanCollide = false
	ped.CanQuery = false
	ped.Parent = m

	local orb = Instance.new("Part")
	orb.Name = "FruitOrb"
	orb.Size = Vector3.new(1.85, 2.15, 1.85)
	orb.CFrame = CFrame.new(corePos) * CFrame.Angles(math.rad(18), math.rad(35), math.rad(14))
	orb.Color = col
	orb.Material = Enum.Material.Neon
	orb.Transparency = 0.08
	orb.Anchored = true
	orb.CanCollide = false
	orb.Parent = m

	local shell = Instance.new("Part")
	shell.Name = "CrystalShell"
	shell.Shape = Enum.PartType.Ball
	shell.Size = Vector3.new(2.55, 2.55, 2.55)
	shell.CFrame = CFrame.new(corePos)
	shell.Color = col
	shell.Material = Enum.Material.Glass
	shell.Transparency = 0.58
	shell.Anchored = true
	shell.CanCollide = false
	shell.CanQuery = false
	shell.Parent = m

	local pl = Instance.new("PointLight")
	pl.Color = col
	pl.Brightness = 1.25
	pl.Range = 13
	pl.Parent = orb

	local bill = Instance.new("BillboardGui")
	bill.Size = UDim2.fromOffset(230, 38)
	bill.StudsOffset = Vector3.new(0, 2.6, 0)
	bill.MaxDistance = 65
	bill.LightInfluence = 0
	bill.Parent = orb

	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamBlack
	tl.TextSize = 12
	tl.TextColor3 = col
	tl.TextStrokeTransparency = 0.18
	tl.Text = string.format("[%s] %s", tostring(cat and cat.Rarity or "Core"), tostring(cat and cat.Name or cid))
	tl.Parent = bill

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Thu Thập Lõi Hoang Dã / Claim Wild Core"
	prompt.ObjectText = tostring(cat and cat.Name or cid)
	prompt.HoldDuration = 0.25
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = orb

	prompt.Triggered:Connect(function(picker)
		if not picker or picker.Parent ~= Players then
			return
		end
		if (type(isInTradeFn) == "function" and isInTradeFn(picker)) or picker:GetAttribute("InTrade") == true then
			return
		end
		local hrp, hum = getCharRoot(picker)
		if not hrp or not hum or hum.Health <= 0 then
			return
		end
		if (hrp.Position - orb.Position).Magnitude > 28 then
			return
		end
		grantClaimedCoreToPlayer(picker, cid, m, true, ensureProfileFn)
	end)

	m.PrimaryPart = orb
	m.Parent = dropFolder
	Debris:AddItem(m, 1205)

	local nowClock = os.clock()
	local endsServer = workspace:GetServerTimeNow() + 1200
	ActiveWildCore = {
		Model = m,
		Part = orb,
		FruitId = cid,
		IslandName = chosenIsl.Name,
		Position = corePos,
		SpawnedClock = nowClock,
		ExpiresClock = nowClock + 1200,
		Claimed = false,
	}
	workspace:SetAttribute("WildCoreActive", true)
	workspace:SetAttribute("WildCoreEndsAt", endsServer)

	local rumorMsg =
		"[TIN ĐỒN AETHER / AETHER RUMOR] Một Lõi Aether hoang dã vừa kết tinh tại một quần đảo trên bầu trời (biến mất sau 20 phút)! / A Wild Aether Core has materialized on a sky island (despawns in 20m)!"
	for _, plr in ipairs(Players:GetPlayers()) do
		if G and G.Notify then
			G.Notify(plr, rumorMsg)
		end
	end
	if R and R.WorldBanner then
		pcall(function()
			R.WorldBanner:FireAllClients({
				Title = "TIN ĐỒN LÕI AETHER / WILD AETHER CORE",
				Message = "Một Lõi Aether tự nhiên vừa kết tinh trên quần đảo bầu trời! (Tồn tại 20 phút / Despawns in 20m)",
				Kind = "WildCore",
			})
		end)
	end

	local spawnedRef = ActiveWildCore
	task.delay(1200, function()
		if ActiveWildCore == spawnedRef then
			clearActiveWildCore()
		end
	end)

	return ActiveWildCore
end

function WildCoreService.TryClaimWildCore(p, rawFruitId, ensureProfileFn, isInTradeFn)
	if not p or p.Parent ~= Players then
		return false
	end
	if (type(isInTradeFn) == "function" and isInTradeFn(p)) or p:GetAttribute("InTrade") == true then
		return false
	end
	local rt = G and G.Runtime and G.Runtime[p]
	local hrp, hum = getCharRoot(p)
	if not rt or not hrp or not hum or hum.Health <= 0 then
		return false
	end
	local now = os.clock()
	if now < (rt.NextWildFruitClaimAt or 0) then
		return false
	end

	local requestedCid = CombatData and CombatData.ResolveFruitId(tostring(rawFruitId or "")) or ""

	-- 1. Check active server-global 45-minute Wild Core within 28 studs
	if ActiveWildCore and not ActiveWildCore.Claimed and ActiveWildCore.Model and ActiveWildCore.Model.Parent and ActiveWildCore.Part then
		if (hrp.Position - ActiveWildCore.Part.Position).Magnitude <= 28 then
			if requestedCid == "" or requestedCid == ActiveWildCore.FruitId then
				rt.NextWildFruitClaimAt = now + 1.0
				return grantClaimedCoreToPlayer(p, ActiveWildCore.FruitId, ActiveWildCore.Model, true, ensureProfileFn)
			end
		end
	end

	-- 2. Check physical player-dropped Aether Cores in DroppedFruits folders within 25 studs
	local candidateFolders = {}
	local f1 = workspace:FindFirstChild("DroppedDevilFruits")
	local wo = workspace:FindFirstChild("WorldObjects")
	local f2 = wo and wo:FindFirstChild("DroppedDevilFruits")
	local swo = workspace:FindFirstChild("SkybreakWorldObjects")
	local f3 = swo and (swo:FindFirstChild("DroppedFruits") or swo:FindFirstChild("DroppedDevilFruits"))
	if f1 then table.insert(candidateFolders, f1) end
	if f2 then table.insert(candidateFolders, f2) end
	if f3 then table.insert(candidateFolders, f3) end

	for _, dropFolder in ipairs(candidateFolders) do
		for _, m in ipairs(dropFolder:GetChildren()) do
			if m:GetAttribute("Claimed") ~= true then
				local dropCid = CombatData and CombatData.ResolveFruitId(tostring(m:GetAttribute("FruitId") or "")) or ""
				if dropCid ~= "" and CombatData.FruitCatalog[dropCid] and (requestedCid == "" or dropCid == requestedCid) then
					local pp = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
					if pp and (pp.Position - hrp.Position).Magnitude <= 25 then
						rt.NextWildFruitClaimAt = now + 1.0
						local isWild = (m:GetAttribute("IsWildCore") == true)
						return grantClaimedCoreToPlayer(p, dropCid, m, isWild, ensureProfileFn)
					end
				end
			end
		end
	end

	if G and G.Notify then
		G.Notify(p, "Không có Lõi Aether tự nhiên nào trong bán kính thu thập gần bạn! / No Wild Aether Core nearby to claim!")
	end
	return false
end

function WildCoreService.SpawnSteppingPlatform(p, pos, mode)
	local lastPos = LastWaterPadPos[p]
	if lastPos and (Vector3.new(pos.X - lastPos.X, 0, pos.Z - lastPos.Z).Magnitude < 3.4) then
		return
	end
	LastWaterPadPos[p] = pos

	local padFolder = ensureWorldFolder("ElementalWaterPads")
	local pad = Instance.new("Part")
	pad.Name = (mode == "Ice") and "GlacierStepPad" or "MagmaBasaltPad"
	pad.Shape = Enum.PartType.Cylinder
	pad.Size = Vector3.new(1.1, 11.5, 11.5)
	pad.CFrame = CFrame.new(pos.X, pos.Y - 3.35, pos.Z) * CFrame.Angles(0, 0, math.pi * 0.5)
	if mode == "Ice" then
		pad.Color = Color3.fromRGB(132, 236, 255)
		pad.Material = Enum.Material.Ice
		pad.Transparency = 0.15
	else
		pad.Color = Color3.fromRGB(54, 42, 46)
		pad.Material = Enum.Material.Basalt
		pad.Transparency = 0
	end
	pad.Anchored = true
	pad.CanCollide = true
	pad.Parent = padFolder
	Debris:AddItem(pad, 6.5)
end

function WildCoreService.BuildWorldProps()
	local waterFolder = ensureWorldFolder("SeaWaterZones")
	waterFolder:ClearAllChildren()
	local basins = {
		{ Name = "SkyHubSeaBasin", Pos = Vector3.new(-428, 18.5, 565), Size = Vector3.new(320, 1.4, 320) },
		{ Name = "CyberportSeaBasin", Pos = Vector3.new(9400, 18.5, 2365), Size = Vector3.new(320, 1.4, 320) },
	}
	for _, b in ipairs(basins) do
		local p = Instance.new("Part")
		p.Name = b.Name
		p.Size = b.Size
		p.Position = b.Pos
		p.Color = Color3.fromRGB(32, 118, 185)
		p.Material = Enum.Material.Glass
		p.Transparency = 0.38
		p.Anchored = true
		p.CanCollide = true
		p:SetAttribute("IsSeaWaterZone", true)
		p.Parent = waterFolder
	end

	local npcFolder = ensureWorldFolder("InteractiveNPCs")
	npcFolder:ClearAllChildren()
	local worldObjects = workspace:FindFirstChild("SkybreakWorldObjects")
	if not worldObjects then
		worldObjects = Instance.new("Folder")
		worldObjects.Name = "SkybreakWorldObjects"
		worldObjects.Parent = workspace
	end
	local existingVega = worldObjects:FindFirstChild("DrVega_Alchemist")
	if existingVega then
		existingVega:Destroy()
	end

	local rawPos = Vector3.new(-263.6, 49.0, 508.2)
	local floorY = 46.5
	if W and W.SnapToOpenGround then
		rawPos, floorY = W.SnapToOpenGround(rawPos, floorY, 2.2)
	end
	local hubSpawn = (C and C.Spawn) or Vector3.new(-317.4, 50.5, 527.8)
	local flatLook = Vector3.new(hubSpawn.X, rawPos.Y, hubSpawn.Z)

	local nm = Instance.new("Model")
	nm.Name = "DrVega_Alchemist"
	nm.Parent = worldObjects

	local col = Color3.fromRGB(112, 242, 195)
	local body
	if W and W.Part then
		body = W.Part(nm, "Body", Vector3.new(2.2, 4.6, 1.8), rawPos, col, Enum.Material.Metal)
	else
		body = Instance.new("Part")
		body.Name = "Body"
		body.Size = Vector3.new(2.2, 4.6, 1.8)
		body.Position = rawPos
		body.Color = col
		body.Material = Enum.Material.Metal
		body.Anchored = true
		body.Parent = nm
	end
	body.Transparency = 1
	body.CanCollide = false
	if (flatLook - rawPos).Magnitude > 0.15 then
		body.CFrame = CFrame.lookAt(rawPos, flatLook)
	end
	nm.PrimaryPart = body
	nm:SetAttribute("NPCId", "DrVega")
	nm:SetAttribute("VisualAsset", "DrVega")
	nm:SetAttribute("NPCFloorY", floorY)

	local bill = Instance.new("BillboardGui")
	bill.Size = UDim2.fromScale(3.8, 0.68)
	bill.StudsOffset = Vector3.new(0, 4.8, 0)
	bill.AlwaysOnTop = false
	bill.MaxDistance = 44
	bill.Parent = body

	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamBlack
	tl.TextScaled = true
	tl.TextColor3 = col
	tl.TextStrokeTransparency = 0.2
	tl.Text = "Tiến Sĩ Dr. Vega • Huyết Thống & Raid [E]"
	tl.Parent = bill

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Tiến Hóa Tộc V2/V3 • Đổi Tộc • Raid"
	prompt.ObjectText = "Tiến Sĩ Dr. Vega • Lineage Alchemist"
	prompt.MaxActivationDistance = 14
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.Style = Enum.ProximityPromptStyle.Default
	prompt.Parent = body

	body:SetAttribute("InteractableId", "DrVega")
	body:SetAttribute("PromptBound", true)
	if W and W.Interactions then
		W.Interactions["DrVega_Alchemist"] = body
	end
	prompt.Triggered:Connect(function(plr)
		nm:SetAttribute("NPCTalkAt", workspace:GetServerTimeNow())
		if G and G.Interact then
			G.Interact(plr, "DrVega")
		end
	end)
end

function WildCoreService.SummonAlliedSeaBeast(p, ensureProfileFn, formatRenownFn)
	local profile = D and D.Get(p)
	local rt = G and G.Runtime and G.Runtime[p]
	local hrp = getCharRoot(p)
	if not profile or not rt or not hrp then
		return false
	end
	if type(ensureProfileFn) == "function" then
		ensureProfileFn(profile)
	end

	if (profile.Bounty or 0) < CombatData.SeaBeastSummonBounty and p:GetAttribute("BypassBountyLock") ~= true then
		local curRenown = (type(formatRenownFn) == "function" and formatRenownFn(profile.Bounty)) or tostring(profile.Bounty or 0)
		G.Notify(
			p,
			string.format(
				"Cần đạt >= 10,000,000 Điểm Danh Vọng (Renown) để Triệu Hồi Thú Trời Hộ Vệ (Hiện tại: %s)! / Requires >= 10,000,000 Renown (Current: %s)!",
				curRenown,
				curRenown
			)
		)
		return false
	end

	local existing = AlliedSeaBeasts[p]
	if existing and existing.Model and existing.Model.Parent then
		existing.Model:Destroy()
		AlliedSeaBeasts[p] = nil
		G.Notify(p, "Đã thu hồi Thú Trời Hộ Vệ (Sky Beast Guardian).")
		return true
	end

	local now = os.clock()
	if now < (rt.Cooldowns.SummonSeaBeast or 0) then
		G.Notify(p, string.format("Triệu Hồi Thú Trời đang hồi (%ds)!", math.ceil(rt.Cooldowns.SummonSeaBeast - now)))
		return false
	end
	rt.Cooldowns.SummonSeaBeast = now + 45

	local beastFolder = ensureWorldFolder("AlliedSeaBeasts")
	local m = Instance.new("Model")
	m.Name = "AlliedSkySeaBeast_" .. p.Name

	local spawnPos = hrp.Position + Vector3.new(12, 5.5, 10)
	local body = Instance.new("Part")
	body.Name = "BeastCore"
	body.Size = Vector3.new(6.2, 11.5, 6.2)
	body.Position = spawnPos
	body.Color = Color3.fromRGB(36, 138, 205)
	body.Material = Enum.Material.Metal
	body.Anchored = true
	body.CanCollide = false
	body.Parent = m

	local head = Instance.new("Part")
	head.Name = "BeastHead"
	head.Size = Vector3.new(6.8, 5.2, 8.2)
	head.Position = spawnPos + Vector3.new(0, 6.5, -2.5)
	head.Color = Color3.fromRGB(72, 224, 255)
	head.Material = Enum.Material.Neon
	head.Anchored = true
	head.CanCollide = false
	head.Parent = m

	for idx = 1, 2 do
		local side = (idx == 1) and -1 or 1
		local crest = Instance.new("Part")
		crest.Name = "FinCrest_" .. tostring(idx)
		crest.Size = Vector3.new(1.1, 5.4, 2.4)
		crest.CFrame = CFrame.new(spawnPos + Vector3.new(side * 3.4, 8.4, -1.2)) * CFrame.Angles(-0.3, 0, side * 0.42)
		crest.Color = Color3.fromRGB(115, 245, 255)
		crest.Material = Enum.Material.Neon
		crest.Anchored = true
		crest.CanCollide = false
		crest.Parent = m
	end

	local bill = Instance.new("BillboardGui")
	bill.Size = UDim2.fromOffset(220, 36)
	bill.StudsOffset = Vector3.new(0, 5.0, 0)
	bill.MaxDistance = 95
	bill.LightInfluence = 0
	bill.Parent = head

	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamBlack
	tl.TextSize = 13
	tl.TextColor3 = Color3.fromRGB(95, 236, 255)
	tl.TextStrokeTransparency = 0.2
	tl.Text = "SKY BEAST GUARDIAN - " .. (p.DisplayName or p.Name)
	tl.Parent = bill

	m.PrimaryPart = body
	m.Parent = beastFolder
	Debris:AddItem(m, CombatData.SeaBeastDuration + 0.5)

	AlliedSeaBeasts[p] = {
		Owner = p,
		Model = m,
		Body = body,
		Head = head,
		ExpiresAt = now + CombatData.SeaBeastDuration,
		NextBeamAt = now + 1.0,
	}
	G.Notify(p, "TRIỆU HỒI THÚ TRỜI HỘ VỆ (35s): Bắn tia Hydro-Aether Beam 380% ATK mỗi 3.5s!")
	return true
end

function WildCoreService.TickAlliedSeaBeasts(dt)
	local now = os.clock()
	for p, rec in pairs(AlliedSeaBeasts) do
		if not p or not p.Parent or not rec.Model or not rec.Model.Parent or now >= rec.ExpiresAt then
			if rec.Model and rec.Model.Parent then
				rec.Model:Destroy()
			end
			AlliedSeaBeasts[p] = nil
		else
			local hrp = getCharRoot(p)
			if hrp then
				local bob = math.sin(now * 2.4) * 1.2
				local goal = hrp.Position + Vector3.new(11, 5.2 + bob, 9)
				local cur = rec.Body.Position
				local nextPos = cur:Lerp(goal, math.min(1, dt * 5))
				local nearest, bestDist = nil, 90
				for _, e in ipairs((G and G.Enemies) or {}) do
					if e.Alive and e.Body then
						local d = (e.Body.Position - hrp.Position).Magnitude
						if d < bestDist then
							bestDist = d
							nearest = e
						end
					end
				end
				local lookTarget = (nearest and nearest.Body and nearest.Body.Position) or (nextPos + hrp.CFrame.LookVector * 12)
				local cf = CFrame.lookAt(nextPos, Vector3.new(lookTarget.X, nextPos.Y, lookTarget.Z))
				rec.Model:PivotTo(cf)

				if nearest and now >= rec.NextBeamAt then
					rec.NextBeamAt = now + CombatData.SeaBeastBeamInterval
					local st = G.Stats(p)
					local beamDmg = ((st and st.ATK) or 60) * CombatData.SeaBeastBeamAtkMultiplier
					local impactPos = nearest.Body.Position
					for _, e in ipairs(G.Enemies or {}) do
						if e.Alive and e.Body and (e.Body.Position - impactPos).Magnitude <= 20 then
							G.Hit(p, e, beamDmg, 24, "SkySeaBeastHydroBeam")
						end
					end
					if R and R.CombatFX then
						R.CombatFX:FireAllClients({
							Kind = "SeaBeastBeam",
							Origin = rec.Head.Position,
							EndPos = impactPos,
							Position = impactPos,
							Radius = 20,
							Owner = p.UserId,
						})
					end
				end
			end
		end
	end
end

function WildCoreService.CleanupPlayer(p)
	LastWaterPadPos[p] = nil
	local rec = AlliedSeaBeasts[p]
	if rec then
		if rec.Model and rec.Model.Parent then
			rec.Model:Destroy()
		end
		AlliedSeaBeasts[p] = nil
	end
end

function WildCoreService.Init(deps)
	C = deps.Config
	D = deps.Data
	G = deps.Game
	W = deps.World
	R = deps.Remotes
	Helpers = deps.Helpers
	CombatData = deps.CombatData

	pcall(WildCoreService.BuildWorldProps)

	if started then
		return
	end
	started = true

	task.spawn(function()
		-- First server-global Wild Core spawns 15-20 minutes (900-1200s) after server start
		local initialDelay = math.random(900, 1200)
		task.wait(initialDelay)
		while true do
			pcall(WildCoreService.SpawnWildCoreNow, deps.EnsureProfile, deps.IsInTrade)
			-- Subsequent spawns every 45 minutes (2700s)
			task.wait(2700)
		end
	end)
end

return WildCoreService
