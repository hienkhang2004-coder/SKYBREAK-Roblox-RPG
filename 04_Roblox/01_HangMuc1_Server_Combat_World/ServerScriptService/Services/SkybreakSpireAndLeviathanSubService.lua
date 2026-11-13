-- SKYBREAK: Fragments of the Core - Instanced Sky Spire, Microchip Raid, Leviathan Hunt & Mirage Sub-Service
-- Extracted from SkybreakWorldEventsService (< 80,000 B). Strictly UTF-8 LF, zero astral-plane emojis (>= 0x1F300).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SubService = {}

local G, D, W, C
local DevGate
local ActiveWarships
local HARBOR_PORTS
local SAFE_HUB_CENTERS
local RAID_DIFFICULTIES

local root
local dist
local flatDist
local safeFloorY
local getWorldObjects
local getActiveShipsFolder
local broadcastWorldBanner
local broadcastMVPSummary
local resolveCanonicalFruitId
local getPartyGroup
local playerOwnsShip
local normalizeShipId
local findPilotedShipEntry
local spawnWarshipFn

local ActiveLeviathanHearts = {} -- array of heartEntries
local ActiveMirageEvent = nil
local ActiveRaidSessions = {} -- [sessionId] = raidSession
local PlayerRaidSession = {} -- [player] = raidSession
local UsedRaidSlots = {} -- [slotIndex] = raidSession
local RaidSeqCounter = 0
local ActiveSpireSessions = {} -- [player] = spireSession
local SpireSessionList = {} -- [sessionId] = spireSession
local UsedSpireSlots = {} -- [slotIndex] = spireSession
local SpireSeqCounter = 0

local RAID_BASE_ORIGIN = Vector3.new(14150, 480, 1770)
local SPIRE_BASE_CENTER = Vector3.new(-1800, 440, -1800)

local SPIRE_CV_RESET_KEYS = {
	"Slot_C",
	"Slot_V",
	"C",
	"V",
	"PortalWarpC",
	"JudgmentStrike",
	"StormBlitz",
	"ArcaneComet",
	"CelestialAegis",
	"ThunderJudgement",
	"AstralCataclysm",
}

local SHIP_PRIORITY_ORDER = {
	"LeviathanHunterShip",
	"CyberEnforcerShip",
	"CelestialAetherGalleon",
	"SkySloop",
}

local function notifyBilingual(plr, enMsg, viMsg)
	if not plr or not G or not G.Notify then
		return
	end
	local langAttr = string.lower(tostring(plr:GetAttribute("Language") or plr:GetAttribute("Locale") or ""))
	if langAttr == "" then
		local prof = D and D.Get and D.Get(plr) or nil
		if prof then
			langAttr = string.lower(tostring(prof.Language or prof.Locale or ""))
		end
	end
	if langAttr == "" then
		local okLoc, locId = pcall(function()
			return plr.LocaleId
		end)
		if okLoc and type(locId) == "string" then
			langAttr = string.lower(locId)
		end
	end
	if string.sub(langAttr, 1, 2) == "en" then
		G.Notify(plr, enMsg)
	elseif string.sub(langAttr, 1, 2) == "vi" then
		G.Notify(plr, viMsg)
	else
		G.Notify(plr, viMsg .. " • " .. enMsg)
	end
end

local function isPlayerInPvPCombat(plr)
	if not plr then
		return false
	end
	if (tonumber(plr:GetAttribute("PvPCombatUntil")) or 0) > os.time() then
		return true
	end
	local rt = G and G.Runtime and G.Runtime[plr]
	if rt and os.clock() < (tonumber(rt.PvPCombatTagUntil) or 0) then
		return true
	end
	return false
end

local function isPlayerInColosseum(plr)
	if not plr then
		return false
	end
	if plr:GetAttribute("ColosseumActive") == true
		or plr:GetAttribute("InColosseum") == true
		or plr:GetAttribute("InColosseumDuel") == true then
		return true
	end
	local rt = G and G.Runtime and G.Runtime[plr]
	if rt and rt.InDuel == true then
		return true
	end
	return false
end

local function isPartyLeaderOrSolo(p)
	if not p then
		return false, {}
	end
	local partyGroup = getPartyGroup and getPartyGroup(p) or { p }
	local soc = G and G.SocialEconomy
	if not soc then
		local mod = script.Parent:FindFirstChild("SkybreakSocialEconomyService")
		if mod and mod:IsA("ModuleScript") then
			local okS, m = pcall(require, mod)
			if okS and type(m) == "table" then
				soc = m
			end
		end
	end
	if type(soc) == "table" then
		if type(soc.GetPartyLeader) == "function" then
			local okL, ldr = pcall(soc.GetPartyLeader, p)
			if okL then
				if ldr == nil or ldr == 0 or ldr == "" then
					return true, { p }
				elseif ldr == p or ldr == p.UserId then
					return true, partyGroup
				else
					return false, partyGroup
				end
			end
		end
		if type(soc.IsPartyLeader) == "function" then
			local okI, res = pcall(soc.IsPartyLeader, p)
			if okI and type(res) == "boolean" then
				if res then
					return true, partyGroup
				elseif #partyGroup <= 1 then
					return true, { p }
				else
					return false, partyGroup
				end
			end
		end
		if type(soc.GetSnapshotForPlayer) == "function" then
			local okSnap, snap = pcall(soc.GetSnapshotForPlayer, p)
			if okSnap and type(snap) == "table" then
				local pid = tostring(snap.PartyId or "")
				local leaderUid = tonumber(snap.PartyLeaderId) or 0
				if pid == "" or leaderUid == 0 then
					return true, { p }
				elseif leaderUid == p.UserId then
					return true, partyGroup
				else
					return false, partyGroup
				end
			end
		end
	end
	if #partyGroup <= 1 then
		return true, { p }
	end
	if partyGroup[1] == p then
		return true, partyGroup
	end
	return false, partyGroup
end

local function resetSpireFloorCVCooldowns(plr)
	local rt = G and G.Runtime and G.Runtime[plr]
	if not rt or type(rt.Cooldowns) ~= "table" then
		return
	end
	for _, k in ipairs(SPIRE_CV_RESET_KEYS) do
		if rt.Cooldowns[k] ~= nil then
			rt.Cooldowns[k] = 0
		end
	end
	rt.Cooldowns.Slot_C = 0
	rt.Cooldowns.Slot_V = 0
	rt.Cooldowns.C = 0
	rt.Cooldowns.V = 0
	for k in pairs(rt.Cooldowns) do
		if type(k) == "string" and (string.sub(k, -2) == "_C" or string.sub(k, -2) == "_V") then
			rt.Cooldowns[k] = 0
		end
	end
end

local function tryAwardLiveOpsBadge(plr, prof, badgeKey)
	pcall(function()
		local liveOps = G and G.LiveOps or nil
		if not liveOps then
			local mod = script.Parent:FindFirstChild("SkybreakLiveOpsService")
			if mod and mod:IsA("ModuleScript") then
				liveOps = require(mod)
			end
		end
		if type(liveOps) == "table" and type(liveOps.AwardBadge) == "function" then
			liveOps.AwardBadge(plr, prof, badgeKey)
		end
	end)
end

local function destroySessionParts(partsList)
	for _, inst in ipairs(partsList or {}) do
		if inst and inst.Parent then
			inst:Destroy()
		end
	end
end

-- ============================================================================
-- 1. #21, #75, #66 - CLOUD-SEA MONSTERS, DANGER LEVEL 1-6 & LEVIATHAN HEART TOW
-- ============================================================================
local function resolveBestOwnedOrSkiffShipId(plr, prof)
	if prof then
		local activeId = prof.ActiveShip and normalizeShipId(prof.ActiveShip) or nil
		if activeId and playerOwnsShip(prof, activeId) then
			return activeId, false
		end
		for _, candidateId in ipairs(SHIP_PRIORITY_ORDER) do
			if playerOwnsShip(prof, candidateId) then
				return candidateId, false
			end
		end
	end
	if plr and DevGate and DevGate.IsAllowed(plr) then
		return "LeviathanHunterShip", false
	end
	-- Temporary Harpoon Skiff fallback (SkySloop hull with harpoon mount) when no ship is owned yet
	return nil, true
end

function SubService.SpawnLeviathanHeartRelic(deathPos, killerPlayer)
	local worldObjects = getWorldObjects()
	local heartPos = Vector3.new(deathPos.X, math.max(30, deathPos.Y + 1.5), deathPos.Z)

	local hm = Instance.new("Model")
	hm.Name = "LeviathanHeart"
	hm.Parent = worldObjects

	local core = W.Part(hm, "HeartCore", Vector3.new(4.6, 5.2, 4.6), heartPos, Color3.fromRGB(228, 48, 108), Enum.Material.Neon)
	core.Shape = Enum.PartType.Ball
	core.Transparency = 0.35
	core.CanCollide = false
	hm.PrimaryPart = core

	local cage = W.Part(hm, "AbyssalCage", Vector3.new(5.8, 1.2, 5.8), heartPos, Color3.fromRGB(82, 232, 255), Enum.Material.Metal)
	cage.Shape = Enum.PartType.Cylinder
	cage.CFrame = CFrame.new(heartPos) * CFrame.Angles(0, 0, math.pi / 2)
	cage.CanCollide = false

	local heartAtt = Instance.new("Attachment")
	heartAtt.Name = "HeartHarpoonAttachment"
	heartAtt.Parent = core

	local bill = Instance.new("BillboardGui")
	bill.Size = UDim2.fromScale(4.8, 0.92)
	bill.StudsOffset = Vector3.new(0, 4.8, 0)
	bill.AlwaysOnTop = true
	bill.MaxDistance = 160
	bill.Parent = core
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamBlack
	tl.TextScaled = true
	tl.TextColor3 = Color3.fromRGB(255, 110, 155)
	tl.TextStrokeTransparency = 0.15
	tl.Text = "TIM THỦY XÀ VỰC THẲM [E]"
	tl.Parent = bill

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Gắn Dây Cáp Kéo Tim Thủy Xà"
	prompt.ObjectText = "Abyss Serpent Heart • Thủy Xà Vực Thẳm"
	prompt.MaxActivationDistance = 30
	prompt.HoldDuration = 0.5
	prompt.RequiresLineOfSight = false
	prompt.Parent = core

	local heartEntry = {
		Model = hm,
		Core = core,
		Att = heartAtt,
		Prompt = prompt,
		Label = tl,
		TowedByPlayer = nil,
		TowedByShip = nil,
		Beam = nil,
		ExpiresAt = os.clock() + 600,
	}
	table.insert(ActiveLeviathanHearts, heartEntry)

	prompt.Triggered:Connect(function(plr)
		if heartEntry.TowedByShip and heartEntry.TowedByShip.Model and heartEntry.TowedByShip.Model.Parent then
			notifyBilingual(
				plr,
				"The Abyss Serpent Heart is already harpooned to a Warship!",
				"Tim Thủy Xà đã được móc cáp vào chiến hạm!"
			)
			return
		end

		-- D-A8 Fix: Allow ANY owned/piloted Warship nearby, or deploy player's owned Warship / temporary Harpoon Skiff!
		local shipEntry = ActiveWarships[plr]
		if not shipEntry or not shipEntry.Model or not shipEntry.Model.Parent or not shipEntry.Hull or dist(shipEntry.Hull.Position, core.Position) > 180 then
			local piloted = findPilotedShipEntry and findPilotedShipEntry(plr) or nil
			if piloted and piloted.Model and piloted.Model.Parent and piloted.Hull and dist(piloted.Hull.Position, core.Position) <= 180 then
				shipEntry = piloted
			else
				shipEntry = nil
			end
		end

		local spawnedTempSkiff = false
		if not shipEntry then
			local prof = D.Get(plr)
			local chosenShipId, isTempSkiff = resolveBestOwnedOrSkiffShipId(plr, prof)
			local spawnAt = core.Position + Vector3.new(0, 0, 26)
			local _, newEntry = spawnWarshipFn(plr, chosenShipId, spawnAt, false)
			if not newEntry then
				-- Guaranteed fallback: spawn temporary Harpoon Skiff (nil requestedShipId resolves to free SkySloop)
				_, newEntry = spawnWarshipFn(plr, nil, spawnAt, false)
				isTempSkiff = true
			end
			shipEntry = newEntry
			if shipEntry and (isTempSkiff or not (prof and playerOwnsShip(prof, "LeviathanHunterShip"))) and shipEntry.ShipId == "SkySloop" then
				spawnedTempSkiff = true
				shipEntry.IsTempHarpoonSkiff = true
				if shipEntry.Model then
					shipEntry.Model:SetAttribute("HarpoonSkiff", true)
				end
			end
		end

		if not shipEntry or not shipEntry.Model or not shipEntry.Hull then
			return
		end
		if not shipEntry.SternAtt or not shipEntry.SternAtt.Parent then
			local sternAtt = Instance.new("Attachment")
			sternAtt.Name = "SternHarpoonAttachment"
			sternAtt.Position = Vector3.new(0, 1.4, (shipEntry.Spec and shipEntry.Spec.HullSize.Z or 26) * 0.48)
			sternAtt.Parent = shipEntry.Hull
			shipEntry.SternAtt = sternAtt
		end

		if heartEntry.Beam and heartEntry.Beam.Parent then
			heartEntry.Beam:Destroy()
		end
		local beam = Instance.new("Beam")
		beam.Name = "LeviathanHarpoonCable"
		beam.Attachment0 = shipEntry.SternAtt
		beam.Attachment1 = heartAtt
		beam.Width0 = 0.65
		beam.Width1 = 0.65
		beam.FaceCamera = true
		beam.LightEmission = 0.6
		beam.Color = ColorSequence.new(Color3.fromRGB(88, 238, 255), Color3.fromRGB(255, 78, 138))
		beam.Transparency = NumberSequence.new(0.35)
		beam.Parent = hm

		heartEntry.TowedByPlayer = plr
		heartEntry.TowedByShip = shipEntry
		heartEntry.Beam = beam
		prompt.Enabled = false
		tl.Text = "ĐANG KÉO VỀ CẢNG SKY SHIPWRIGHT..."

		shipEntry.Model:SetAttribute("TowingLeviathanHeart", true)
		plr:SetAttribute("TowingLeviathanHeart", true)
		if spawnedTempSkiff then
			notifyBilingual(
				plr,
				"HARPOON SKIFF DEPLOYED! Board the skiff and tow the Leviathan Heart to any Sky Shipwright Port (within 55m)!",
				"ĐÃ HẠ THỦY XUỒNG LAO MÓC TẠM THỜI (HARPOON SKIFF)! Hãy lên tàu kéo Tim Thủy Xà về bất kỳ Cảng Sky Shipwright nào (trong 55m)!"
			)
		else
			notifyBilingual(
				plr,
				"HARPOON ATTACHED! Pilot your Warship and tow the Leviathan Heart to any Sky Shipwright Port (within 55m)!",
				"ĐÃ MÓC CÁP HARPOON! Hãy lái Chiến Hạm kéo Tim Thủy Xà về bất kỳ Cảng Sky Shipwright / Sky Hub Port (trong 55m) để nhận thưởng!"
			)
		end
	end)

	if killerPlayer then
		notifyBilingual(
			killerPlayer,
			"ABYSS SERPENT HEART surfaced! Press [E] to fire your Warship Harpoon (or summon a Harpoon Skiff) and tow it to Port!",
			"TIM THỦY XÀ VỰC THẲM đã trồi lên biển mây! Hãy bấm [E] để gắn cáp Harpoon vào Chiến Hạm và kéo về Cảng!"
		)
	end
end

local function detachLeviathanHeartTow(he)
	if not he then
		return
	end
	if he.TowedByShip and he.TowedByShip.Model and he.TowedByShip.Model.Parent then
		he.TowedByShip.Model:SetAttribute("TowingLeviathanHeart", false)
	end
	if he.TowedByPlayer and he.TowedByPlayer.Parent == Players then
		he.TowedByPlayer:SetAttribute("TowingLeviathanHeart", false)
	end
	if he.Beam and he.Beam.Parent then
		he.Beam:Destroy()
	end
	he.Beam = nil
	he.TowedByShip = nil
	he.TowedByPlayer = nil
	if he.Prompt and he.Prompt.Parent then
		he.Prompt.Enabled = true
	end
	if he.Label and he.Label.Parent then
		he.Label.Text = "TIM THỦY XÀ VỰC THẲM [E]"
	end
end

function SubService.TickLeviathanHearts(dt)
	local now = os.clock()
	for i = #ActiveLeviathanHearts, 1, -1 do
		local he = ActiveLeviathanHearts[i]
		if not he.Model or not he.Model.Parent or now >= he.ExpiresAt then
			detachLeviathanHeartTow(he)
			if he.Model and he.Model.Parent then
				he.Model:Destroy()
			end
			table.remove(ActiveLeviathanHearts, i)
		elseif he.TowedByShip and he.TowedByShip.Hull and he.TowedByShip.Hull.Parent and (not he.TowedByPlayer or he.TowedByPlayer.Parent == Players) then
			local hullCF = he.TowedByShip.Hull.CFrame
			local targetPos = (hullCF * CFrame.new(0, 1.2, he.TowedByShip.Spec.HullSize.Z * 0.5 + 18)).Position
			local nextPos = he.Core.Position:Lerp(targetPos, math.min(1, dt * 6.5))
			he.Model:PivotTo(CFrame.new(nextPos))

			-- Check port delivery within 55 studs of any SkyShipwright / Sky Hub Port!
			for _, port in ipairs(HARBOR_PORTS) do
				if dist(he.TowedByShip.Hull.Position, port.PedestalPos) <= 55 or dist(he.TowedByShip.Hull.Position, port.WaterPos) <= 42 then
					local owner = he.TowedByPlayer or he.TowedByShip.Owner
					detachLeviathanHeartTow(he)
					if owner and owner.Parent == Players then
						local prof = D.Get(owner)
						if prof then
							prof.LeviathanHearts = (prof.LeviathanHearts or 0) + 1
							prof.CoreShards = (prof.CoreShards or 0) + 500
							prof.Inventory = prof.Inventory or {}
							prof.Inventory.CoreEssence = (prof.Inventory.CoreEssence or 0) + 3
							prof.Inventory.leviathan_shield = math.max(1, prof.Inventory.leviathan_shield or 0)
							prof.UnlockedTitles = prof.UnlockedTitles or {}
							prof.UnlockedTitles.leviathan_slayer = true
							prof.UnlockedTitles.sea_king_slayer = true
							prof.UnlockedShips = prof.UnlockedShips or {}
							prof.UnlockedShips.LeviathanHunterShip = true
							G.Reward(owner, 95000, 35000, 0)
							tryAwardLiveOpsBadge(owner, prof, "leviathan_slayer")
							notifyBilingual(
								owner,
								"LEVIATHAN HEART DELIVERED: +1 Leviathan Heart, +500 Core Shards, +35,000 Gold, Leviathan Shield, Hunter Ship & [Leviathan Slayer] unlocked!",
								"GIAO TIM THỦY XÀ THÀNH CÔNG: +1 Tim Thủy Xà, +500 Core Shards, +35,000 Gold, Mở khóa Chiến Hạm Săn Thủy Xà, Khiên Thủy Xà & Danh hiệu [Thợ Săn Thủy Xà Vực Thẳm]!"
							)
							G.Sync(owner)
							if D.Save then
								task.spawn(D.Save, owner, false)
							end
						end
						broadcastWorldBanner(
							"TIM THỦY XÀ VỰC THẲM CẬP CẢNG!",
							owner.Name .. " đã kéo thành công Tim Thủy Xà Vực Thẳm về " .. port.Name .. "!",
							"Mythic"
						)
					end
					he.Model:Destroy()
					table.remove(ActiveLeviathanHearts, i)
					break
				end
			end
		elseif he.TowedByShip or he.TowedByPlayer then
			detachLeviathanHeartTow(he)
		end
	end
end

function SubService.SpawnSeaMonsterEvent(p, monsterId, customPos)
	local r = p and root(p) or nil
	local mId = tostring(monsterId or "SkySeaBeast")
	if mId ~= "AbyssalLeviathan" and mId ~= "SkySeaBeast" and mId ~= "TerrorSkyShark" then
		mId = "SkySeaBeast"
	end
	local shipEntry = p and ActiveWarships[p] or nil
	local anchorCF = (shipEntry and shipEntry.Hull and shipEntry.Hull.Parent) and shipEntry.Hull.CFrame or (r and r.CFrame or CFrame.new(-428, 44, 595))
	local spawnPos = customPos or (anchorCF.Position + anchorCF.LookVector * 38 + Vector3.new(0, 2, 0))

	local bossFlag = (mId == "AbyssalLeviathan" or mId == "SkySeaBeast")
	local mob = G.SpawnEnemy(mId, spawnPos, bossFlag, true)
	if mob and mob.Model then
		mob.Model:SetAttribute("VisualAsset", mId)
		mob.IsSeaEventMonster = true
		mob.Home = spawnPos
		mob.HomeFloorY = spawnPos.Y - 3
		mob.Model:PivotTo(CFrame.lookAt(spawnPos, anchorCF.Position))
		mob.Model:SetAttribute("EnemyFloorY", spawnPos.Y - 3)
	end

	if mId == "AbyssalLeviathan" then
		broadcastWorldBanner(
			"THỦY XÀ VỰC THẲM TRỒI LÊN!",
			"Vùng Biển Mây Nguy Hiểm (Danger 6) rung chuyển — Thủy Xà Vực Thẳm Lv.2350 đã xuất hiện!",
			"Leviathan"
		)
	elseif p then
		G.Notify(p, "SỰ KIỆN BIỂN MÂY: [" .. (C.Enemies[mId] and C.Enemies[mId].Name or mId) .. "] đã trồi lên từ biển mây!")
	end
	return mob
end

local function computePlayerDangerLevel(pos, rt)
	if flatDist(pos, Vector3.new(-12000, 46.9, -3560)) <= 850 then
		return 6
	elseif flatDist(pos, Vector3.new(14600, 46.9, -1992.7)) <= 850 then
		return rt and rt.SeatedInShip and 5 or 4
	end

	local minSafeRatio = math.huge
	local minHubDist = math.huge
	for _, hub in ipairs(SAFE_HUB_CENTERS) do
		local d = flatDist(pos, hub.Pos)
		minHubDist = math.min(minHubDist, d)
		minSafeRatio = math.min(minSafeRatio, d / hub.SafeRadius)
	end

	if minSafeRatio <= 1.0 then
		return 1
	end
	local bonus = (rt and rt.SeatedInShip) and 1 or 0
	if minHubDist > 3800 then
		return 6
	elseif minHubDist > 2600 then
		return math.min(6, 5 + bonus)
	elseif minHubDist > 1600 then
		return math.min(6, 4 + bonus)
	elseif minHubDist > 850 then
		return math.min(6, 3 + bonus)
	end
	return math.min(6, 2 + bonus)
end

function SubService.TickSeaDangerAndDynamicEncounters()
	local now = os.clock()
	for p, rt in pairs(G.Runtime) do
		local r = root(p)
		if r then
			local danger = computePlayerDangerLevel(r.Position, rt)
			if p:GetAttribute("SeaDangerLevel") ~= danger then
				p:SetAttribute("SeaDangerLevel", danger)
			end
			if danger >= 2 and rt.SeatedInShip and now >= (rt.NextSeaEncounterCheck or 0) then
				rt.NextSeaEncounterCheck = now + math.max(18, 44 - danger * 4)
				local roll = math.random()
				if danger >= 5 and roll < 0.22 and not ActiveMirageEvent then
					SubService.SpawnMirageIsland(p)
				elseif danger >= 5 and roll < 0.55 then
					SubService.SpawnSeaMonsterEvent(p, "AbyssalLeviathan")
				elseif danger >= 4 and roll < 0.65 then
					SubService.SpawnSeaMonsterEvent(p, "SkySeaBeast")
				elseif danger >= 2 and roll < 0.70 then
					SubService.SpawnSeaMonsterEvent(p, "TerrorSkyShark")
				end
			end
		end
	end
end

function SubService.TickOpenSeaMonsterAI(e, dt)
	if not e or not e.Alive or not e.Body or not e.Model then
		return false
	end
	if e.Id ~= "AbyssalLeviathan" and e.Id ~= "SkySeaBeast" and e.Id ~= "TerrorSkyShark" then
		return false
	end
	local now = os.clock()
	if now < (e.StunnedUntil or 0) then
		e.Model:SetAttribute("EnemyMoving", false)
		return true
	end

	local curPos = e.Body.Position
	local aggroR = math.max(240, tonumber(e.Config and e.Config.Aggro) or 160)
	local bestPos, bestPlr, bestShip, bestD = nil, nil, nil, aggroR

	for owner, shipEntry in pairs(ActiveWarships) do
		if shipEntry.Hull and shipEntry.Hull.Parent and shipEntry.Helm and shipEntry.Helm.Occupant then
			local d = dist(shipEntry.Hull.Position, curPos)
			if d < bestD then
				bestD = d
				bestPos = shipEntry.Hull.Position
				bestShip = shipEntry
				bestPlr = Players:GetPlayerFromCharacter(shipEntry.Helm.Occupant.Parent) or owner
			end
		end
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		local pr = root(plr)
		if pr then
			local d = dist(pr.Position, curPos)
			local engaged = (e.Contributors ~= nil and e.Contributors[plr] ~= nil)
			if d < bestD or (engaged and d < 360 and bestPos == nil) then
				bestD = d
				bestPos = pr.Position
				bestPlr = plr
				bestShip = ActiveWarships[plr]
			end
		end
	end

	local spd = math.max(22, tonumber(e.Config and e.Config.Speed) or 24)
	local atkRange = math.max(18, tonumber(e.Config and e.Config.Range) or 22)
	local goalPos
	if bestPos then
		local desiredY = math.clamp(bestPos.Y - 1.5, 40, 340) + math.sin(now * 2.1) * 1.4
		goalPos = Vector3.new(bestPos.X, desiredY, bestPos.Z)
	else
		local home = e.Home or curPos
		local orbitAng = now * 0.35 + (tonumber(e.Seed) or 0)
		goalPos = Vector3.new(home.X + math.cos(orbitAng) * 34, math.clamp(home.Y, 44, 340) + math.sin(now * 1.6) * 1.2, home.Z + math.sin(orbitAng) * 34)
		spd = spd * 0.55
	end

	local toGoal = goalPos - curPos
	local stopDist = bestPos and (atkRange * 0.72) or 2.0
	if toGoal.Magnitude > stopDist then
		local moveDir = toGoal.Unit
		local flatDir = Vector3.new(moveDir.X, 0, moveDir.Z)
		flatDir = flatDir.Magnitude > 0.05 and flatDir.Unit or Vector3.new(0, 0, -1)

		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		local ex = { e.Model, getActiveShipsFolder() }
		local tfx = workspace:FindFirstChild("TempFX")
		if tfx then
			table.insert(ex, tfx)
		end
		local ef = workspace:FindFirstChild("Enemies")
		if ef then
			table.insert(ex, ef)
		end
		rp.FilterDescendantsInstances = ex

		local cliffHit = workspace:Raycast(curPos, flatDir * 24, rp)
		if cliffHit and cliffHit.Instance and cliffHit.Instance.CanCollide and cliffHit.Normal.Y < 0.72 then
			local nFlat = Vector3.new(cliffHit.Normal.X, 0, cliffHit.Normal.Z)
			if nFlat.Magnitude > 0.05 then
				nFlat = nFlat.Unit
				local tangA = Vector3.new(-nFlat.Z, 0, nFlat.X)
				local tangB = -tangA
				local chosen = (tangA:Dot(flatDir) >= tangB:Dot(flatDir)) and tangA or tangB
				moveDir = (chosen * 0.88 + nFlat * 0.25 + Vector3.new(0, moveDir.Y * 0.5, 0)).Unit
				flatDir = Vector3.new(moveDir.X, 0, moveDir.Z).Unit
			end
		end

		local stepLen = math.min(toGoal.Magnitude - stopDist * 0.5, spd * dt)
		local nextPos = curPos + moveDir * math.max(0, stepLen)
		nextPos = Vector3.new(nextPos.X, math.clamp(nextPos.Y, 39, 340), nextPos.Z)
		e.Model:PivotTo(CFrame.lookAt(nextPos, nextPos + flatDir))
		e.Model:SetAttribute("EnemyFloorY", nextPos.Y - 3.0)
		e.Model:SetAttribute("EnemyMoving", true)
	else
		e.Model:SetAttribute("EnemyMoving", false)
		if bestPos then
			local look = Vector3.new(bestPos.X - curPos.X, 0, bestPos.Z - curPos.Z)
			if look.Magnitude > 0.1 then
				e.Model:PivotTo(CFrame.lookAt(curPos, curPos + look.Unit))
			end
		end
	end

	if bestPos and bestD <= (atkRange + 14) and now >= (e.NextAttack or 0) then
		e.NextAttack = now + 2.2
		local baseATK = tonumber(e.Config and e.Config.ATK) or 180
		e.Model:SetAttribute("EnemyAttackClip", "Attack")
		e.Model:SetAttribute("EnemyAttackDuration", 0.9)
		e.Model:SetAttribute("EnemyAttackAt", workspace:GetServerTimeNow())

		if bestPlr and bestPlr.Parent == Players then
			local pr = root(bestPlr)
			if pr and dist(pr.Position, e.Body.Position) <= (atkRange + 16) then
				G.PlayerDamage(bestPlr, baseATK, e)
			end
		end
		if bestShip and bestShip.Model and bestShip.Model.Parent and bestShip.Hull and dist(bestShip.Hull.Position, e.Body.Position) <= (atkRange + 24) then
			local hullDmg = math.max(120, math.floor(baseATK * 1.4))
			bestShip.HP = math.max(100, (tonumber(bestShip.HP) or bestShip.MaxHP or 1500) - hullDmg)
			bestShip.Model:SetAttribute("HP", bestShip.HP)
		end
	end
	return true
end

-- ============================================================================
-- 2. #63 - DYNAMIC 15-MINUTE MIRAGESKYISLAND EVENT (BLUE RESONANCE GEAR + DEALER)
-- ============================================================================
function SubService.GetActiveMirageEvent()
	return ActiveMirageEvent
end

function SubService.SpawnMirageIsland(nearPlayerOrPos)
	local worldObjects = getWorldObjects()
	if ActiveMirageEvent and ActiveMirageEvent.Model and ActiveMirageEvent.Model.Parent then
		ActiveMirageEvent.Model:Destroy()
	end

	local center = Vector3.new(-12000, 50.5, -2100)
	if typeof(nearPlayerOrPos) == "Vector3" then
		center = nearPlayerOrPos
	elseif typeof(nearPlayerOrPos) == "Instance" and nearPlayerOrPos:IsA("Player") then
		local pr = root(nearPlayerOrPos)
		if pr then
			local look = Vector3.new(pr.CFrame.LookVector.X, 0, pr.CFrame.LookVector.Z)
			look = look.Magnitude > 0.05 and look.Unit or Vector3.new(0, 0, -1)
			center = Vector3.new(pr.Position.X, math.max(50.5, pr.Position.Y + 6), pr.Position.Z) + look * 95
		end
	end

	local m = Instance.new("Model")
	m.Name = "MirageSkyIsland_Event"
	m.Parent = worldObjects

	local deck = Instance.new("Part")
	deck.Name = "MirageSanctuaryDeck"
	deck.Shape = Enum.PartType.Cylinder
	deck.Size = Vector3.new(3.6, 84, 84)
	deck.CFrame = CFrame.new(center.X, center.Y - 1.8, center.Z) * CFrame.Angles(0, 0, math.pi / 2)
	deck.Color = Color3.fromRGB(196, 234, 248)
	deck.Material = Enum.Material.Marble
	deck.Anchored, deck.CanCollide, deck.CanQuery, deck.CanTouch = true, true, true, false
	deck.Parent = m
	m.PrimaryPart = deck

	local gsiCol = workspace:FindFirstChild("GrandSkyIslands_Collision")
	if gsiCol then
		local oldCol = gsiCol:FindFirstChild("MirageSanctuaryCollider")
		if oldCol then
			oldCol:Destroy()
		end
		local col = deck:Clone()
		col.Name = "MirageSanctuaryCollider"
		col.Transparency = 1
		col.Parent = gsiCol
		m.Destroying:Once(function()
			if col and col.Parent then
				col:Destroy()
			end
		end)
	end

	local rim = Instance.new("Part")
	rim.Name = "MirageAuraRim"
	rim.Shape = Enum.PartType.Cylinder
	rim.Size = Vector3.new(0.8, 88, 88)
	rim.CFrame = CFrame.new(center.X, center.Y - 0.3, center.Z) * CFrame.Angles(0, 0, math.pi / 2)
	rim.Color = Color3.fromRGB(82, 232, 255)
	rim.Material = Enum.Material.Neon
	rim.Transparency = 0.42
	rim.Anchored, rim.CanCollide, rim.CanQuery, rim.CanTouch = true, false, false, false
	rim.Parent = m

	-- D-A7 Fix: Collectible 3D Blue Resonance Gear sets ONLY BlueResonanceGearFound = true (NEVER RaceTier = 4 / RaceV4Unlocked!)
	local gearPos = center + Vector3.new(-10, 3.2, -8)
	local gearPedestal = W.Part(m, "BlueGearPedestal", Vector3.new(3.8, 2.2, 3.8), center + Vector3.new(-10, 1.1, -8), Color3.fromRGB(36, 48, 72), Enum.Material.Slate)
	local gear = W.Part(m, "BlueResonanceGear", Vector3.new(0.8, 3.6, 3.6), gearPos, Color3.fromRGB(64, 224, 255), Enum.Material.Neon)
	gear.Shape = Enum.PartType.Cylinder
	gear.Transparency = 0.35
	gear.CanCollide = false

	local gBill = Instance.new("BillboardGui")
	gBill.Size = UDim2.fromScale(4.4, 0.82)
	gBill.StudsOffset = Vector3.new(0, 3.6, 0)
	gBill.AlwaysOnTop = true
	gBill.MaxDistance = 120
	gBill.Parent = gear
	local gLbl = Instance.new("TextLabel")
	gLbl.Size = UDim2.fromScale(1, 1)
	gLbl.BackgroundTransparency = 1
	gLbl.Font = Enum.Font.GothamBlack
	gLbl.TextScaled = true
	gLbl.TextColor3 = Color3.fromRGB(92, 240, 255)
	gLbl.TextStrokeTransparency = 0.18
	gLbl.Text = "BLUE RESONANCE GEAR [CỔ VẬT ĐỀN CỔ ĐẠI]"
	gLbl.Parent = gBill

	local claimedBy = {}
	local gPrompt = Instance.new("ProximityPrompt")
	gPrompt.ActionText = "Thu Thập Blue Resonance Gear"
	gPrompt.ObjectText = "Blue Resonance Gear • Ancient Temple Key"
	gPrompt.MaxActivationDistance = 16
	gPrompt.HoldDuration = 0.4
	gPrompt.RequiresLineOfSight = false
	gPrompt.Parent = gearPedestal
	gPrompt.Triggered:Connect(function(plr)
		local uid = plr and plr.UserId
		if not uid then
			return
		end
		if claimedBy[uid] then
			notifyBilingual(
				plr,
				"You already collected the Blue Resonance Gear on this Mirage Island! Head to the Ancient Temple (Lv. 1900 + Race V3).",
				"Bạn đã thu thập Blue Resonance Gear trên Đảo Hư Quang đợt này rồi! Hãy tới Đền Cổ Đại (Lv. 1900 + Tộc V3)."
			)
			return
		end
		local prof = D.Get(plr)
		if not prof or prof._ReadOnlyFallback == true then
			return
		end
		claimedBy[uid] = true
		prof.BlueResonanceGearFound = true
		prof.CoreGears = (tonumber(prof.CoreGears) or 0) + 1
		prof.CoreShards = (tonumber(prof.CoreShards) or 0) + 300
		plr:SetAttribute("BlueResonanceGearFound", true)
		notifyBilingual(
			plr,
			"BLUE RESONANCE GEAR FOUND (+300 Shards)! Bring it to the Ancient Temple (Lv. 1900 + Race V3) to unlock the V4 Ascension Trial!",
			"ĐÃ TÌM THẤY BLUE RESONANCE GEAR (+300 Shards)! Hãy mang tới Đền Cổ Đại • Ancient Temple (Lv. 1900 + Race V3) để mở Thử Thách Thăng Hoa V4!"
		)
		G.Sync(plr)
		if D.Save then
			task.spawn(D.Save, plr, false)
		end
	end)

	-- Physical 3D Mirage Stock Dealer NPC on the island
	local dealerPos = center + Vector3.new(12, 2.3, -6)
	local dealerModel = Instance.new("Model")
	dealerModel.Name = "NPC_MirageStockDealer"
	dealerModel.Parent = m
	local dBody = W.Part(dealerModel, "Body", Vector3.new(2.2, 4.6, 1.8), dealerPos, Color3.fromRGB(168, 108, 255), Enum.Material.Metal)
	dBody.Transparency = 1
	dBody.CanCollide = false
	dealerModel.PrimaryPart = dBody
	dealerModel:SetAttribute("NPCId", "ZiolesGachaNPC")
	dealerModel:SetAttribute("VisualAsset", "ZiolesGachaNPC")
	dealerModel:SetAttribute("NPCFloorY", center.Y)

	local dBill = Instance.new("BillboardGui")
	dBill.Size = UDim2.fromScale(4.6, 0.85)
	dBill.StudsOffset = Vector3.new(0, 4.8, 0)
	dBill.AlwaysOnTop = false
	dBill.MaxDistance = 75
	dBill.Parent = dBody
	local dLbl = Instance.new("TextLabel")
	dLbl.Size = UDim2.fromScale(1, 1)
	dLbl.BackgroundTransparency = 1
	dLbl.Font = Enum.Font.GothamBlack
	dLbl.TextScaled = true
	dLbl.TextColor3 = Color3.fromRGB(215, 138, 255)
	dLbl.TextStrokeTransparency = 0.18
	dLbl.Text = "THƯƠNG NHÂN HƯ QUANG • LÕI HIẾM [E]"
	dLbl.Parent = dBill

	local dPrompt = Instance.new("ProximityPrompt")
	dPrompt.ActionText = "Giao Dịch Kho Lõi Aether Hư Quang"
	dPrompt.ObjectText = "Thương Nhân Hư Quang • Đảo Hư Quang"
	dPrompt.MaxActivationDistance = 16
	dPrompt.HoldDuration = 0
	dPrompt.RequiresLineOfSight = false
	dPrompt.Parent = dBody
	dPrompt.Triggered:Connect(function(plr)
		G.Interact(plr, "MirageDealer")
		G.SendDialogue(
			plr,
			"Thương Nhân Hư Quang",
			"THƯƠNG NHÂN ĐẢO HƯ QUANG",
			"Chào mừng tới Đảo Hư Quang (Phantom Isle)! Kho Lõi Aether Thần Thoại của ta có tỉ lệ xuất hiện cao gấp đôi — hãy mở Cửa Hàng Hư Quang 3D!",
			"Mở Cửa Hàng Hư Quang 3D",
			"OpenScreen:NPCShop:MirageDealer"
		)
	end)

	local endsAt = workspace:GetServerTimeNow() + 900
	ActiveMirageEvent = {
		Model = m,
		Gear = gear,
		Dealer = dealerModel,
		Pedestal = gearPedestal,
		Pos = center,
		ExpiresClock = os.clock() + 900,
	}
	if G then
		G.ActiveMirageEvent = ActiveMirageEvent
	end
	workspace:SetAttribute("MirageIslandActive", true)
	workspace:SetAttribute("MirageIslandPos", center)
	workspace:SetAttribute("MirageIslandEndsAt", endsAt)

	broadcastWorldBanner(
		"ĐẢO HƯ QUANG XUẤT HIỆN!",
		"Đảo Hư Quang (Phantom Isle) đã hiện ra trong 15 phút! Tìm Blue Resonance Gear & Thương Nhân Hư Quang!",
		"Mirage"
	)
	return m, center
end

function SubService.TickMirageHeartbeat(clampedDt)
	if ActiveMirageEvent and ActiveMirageEvent.Gear and ActiveMirageEvent.Gear.Parent then
		ActiveMirageEvent.Gear.CFrame = ActiveMirageEvent.Gear.CFrame * CFrame.Angles(0, clampedDt * 1.9, 0)
	end
end

function SubService.TickMirageExpiry(now)
	if ActiveMirageEvent and now >= ActiveMirageEvent.ExpiresClock then
		if ActiveMirageEvent.Model and ActiveMirageEvent.Model.Parent then
			ActiveMirageEvent.Model:Destroy()
		end
		ActiveMirageEvent = nil
		if G then
			G.ActiveMirageEvent = nil
		end
		workspace:SetAttribute("MirageIslandActive", false)
	end
end

-- ============================================================================
-- 3. #22, #118 - PER-PARTY INSTANCED 5-WAVE MICROCHIP RAID + 2 REVIVES
-- ============================================================================
local function fireUIStateToPlayer(plr, patch)
	if not plr or plr.Parent ~= Players or type(patch) ~= "table" then
		return
	end
	local shared = ReplicatedStorage:FindFirstChild("SkybreakShared")
	local rem = shared and shared:FindFirstChild("Remotes")
	local ev = rem and rem:FindFirstChild("UIStateUpdated")
	if ev and ev:IsA("RemoteEvent") then
		ev:FireClient(plr, patch)
	end
end

local function allocateRaidSlot(session)
	local slotIndex = 1
	while UsedRaidSlots[slotIndex] ~= nil do
		slotIndex += 1
	end
	UsedRaidSlots[slotIndex] = session
	return slotIndex
end

local function buildInstancedRaidArena(slotIndex)
	local worldObjects = getWorldObjects()
	local colFolder = workspace:FindFirstChild("GrandSkyIslands_Collision") or worldObjects
	local slotOffset = Vector3.new(slotIndex * 450, 0, 0)

	local modelName = "MicrochipRaidInstance_Slot_" .. tostring(slotIndex)
	local oldM = worldObjects:FindFirstChild(modelName)
	if oldM then
		oldM:Destroy()
	end
	local rootM = Instance.new("Model")
	rootM.Name = modelName
	rootM.Parent = worldObjects

	local centers = {}
	local createdParts = { rootM }

	for idx = 1, 5 do
		local cpos = RAID_BASE_ORIGIN + slotOffset + Vector3.new(0, (idx - 1) * 8, -(idx - 1) * 38)
		centers[idx] = cpos
		local radius = (idx == 5) and 28 or 24

		local deck = Instance.new("Part")
		deck.Name = string.format("RaidWaveIsland_S%d_%d", slotIndex, idx)
		deck.Shape = Enum.PartType.Cylinder
		deck.Size = Vector3.new(3.6, radius * 2, radius * 2)
		deck.CFrame = CFrame.new(cpos.X, cpos.Y - 1.8, cpos.Z) * CFrame.Angles(0, 0, math.pi / 2)
		deck.Color = Color3.fromRGB(32, 44, 68)
		deck.Material = Enum.Material.Slate
		deck.Anchored, deck.CanCollide, deck.CanQuery, deck.CanTouch = true, true, true, false
		deck.Parent = colFolder
		table.insert(createdParts, deck)

		local ring = Instance.new("Part")
		ring.Name = "RaidWaveRune_" .. idx
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = Vector3.new(0.4, radius * 1.85, radius * 1.85)
		ring.CFrame = CFrame.new(cpos.X, cpos.Y - 0.05, cpos.Z) * CFrame.Angles(0, 0, math.pi / 2)
		ring.Color = (idx == 5) and Color3.fromRGB(255, 192, 78) or Color3.fromRGB(88, 236, 255)
		ring.Material = Enum.Material.Neon
		ring.Transparency = 0.46
		ring.Anchored, ring.CanCollide, ring.CanQuery, ring.CanTouch = true, false, false, false
		ring.Parent = rootM
	end

	for idx = 1, 4 do
		local p0 = centers[idx] + Vector3.new(0, -0.4, -15)
		local p1 = centers[idx + 1] + Vector3.new(0, -0.4, 15)
		local br = Instance.new("Part")
		br.Name = string.format("RaidLightBridge_S%d_%d", slotIndex, idx)
		br.Size = Vector3.new(14, 1.2, (p1 - p0).Magnitude + 6)
		br.CFrame = CFrame.lookAt((p0 + p1) * 0.5, p1)
		br.Color = Color3.fromRGB(82, 228, 255)
		br.Material = Enum.Material.Neon
		br.Transparency = 0.42
		br.Anchored, br.CanCollide, br.CanQuery, br.CanTouch = true, true, true, false
		br.Parent = colFolder
		table.insert(createdParts, br)
	end

	return centers, createdParts
end

function SubService.GetPlayerRaidSession(plr)
	return PlayerRaidSession[plr]
end

function SubService.GetActiveSpireSession(plr)
	return ActiveSpireSessions[plr]
end

function SubService.ConsumeRaidRevive(plr, session)
	if not plr or plr.Parent ~= Players or not session then
		return false
	end
	local left = tonumber(session.RevivesLeft and session.RevivesLeft[plr]) or 0
	if left <= 0 then
		return false
	end
	session.RevivesLeft[plr] = left - 1
	local livesRemaining = 1 + session.RevivesLeft[plr]
	plr:SetAttribute("RaidLivesLeft", livesRemaining)

	local rt = G.Runtime and G.Runtime[plr]
	local r, h = root(plr)
	local prof = D.Get(plr)
	if rt then
		rt.IsDowned = false
		rt.DownedUntil = 0
		rt.InvincibleUntil = os.clock() + 3.5
		rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, os.clock() + 3.5)
		if rt.ReviveBeacon and rt.ReviveBeacon.Parent then
			rt.ReviveBeacon:Destroy()
		end
		rt.ReviveBeacon = nil
	end
	plr:SetAttribute("Downed", false)
	if h then
		h.Health = h.MaxHealth
		local baseSpd = (prof and C.Classes[prof.ClassId] and C.Classes[prof.ClassId].Speed) or 18
		h.WalkSpeed = baseSpd
	end

	local cpos = (session.PlatformCenters and (session.PlatformCenters[session.Wave] or session.PlatformCenters[1])) or RAID_BASE_ORIGIN
	local respawnSpot = cpos + Vector3.new(0, 3.5, 16)
	G.Teleport(plr, respawnSpot)
	if r then
		G.FireCombatEvent({
			kind = "DamageNumber",
			pos = respawnSpot + Vector3.new(0, 2.5, 0),
			amount = h and math.floor(h.MaxHealth) or 1000,
			crit = true,
			element = "Heal",
			Text = string.format("RAID REVIVE! (%d LIVES)", livesRemaining),
		})
	end
	G.Notify(plr, string.format("[RAID HỒI SINH] Đã hồi sinh trở lại Đảo Wave %d/5 với 100%% HP! (Còn %d lượt hồi sinh)", session.Wave or 1, session.RevivesLeft[plr]))
	return true
end

local function spawnRaidWave(session, waveNum)
	session.Wave = waveNum
	session.WaveStartedAt = os.clock()
	session.AllMissingSince = nil
	session.Mobs = {}
	local centers = session.PlatformCenters
	local cpos = centers[waveNum] or centers[5]
	local diff = session.DifficultySpec

	local waveTemplates = {
		[1] = { "FrostDrone", "FrostDrone", "CryoGuard", "CyberArcher" },
		[2] = { "CryoGuard", "CryoGuard", "CyberArcher", "CyberArcher", "GoldenKnight" },
		[3] = { "GoldenKnight", "CryoGuard", "ShadowArcher", "ShadowArcher", "VoidPirate" },
		[4] = { "AbyssalKnight", "AbyssalKnight", "ShadowArcher", "OrderCyborg", "OrderCyborg" },
		[5] = { "CryoGuard", "AbyssalKnight", "OrderCyborgBoss" },
	}
	local list = waveTemplates[waveNum] or waveTemplates[5]
	for idx, mobId in ipairs(list) do
		local actualId = C.Enemies[mobId] and mobId or (mobId == "OrderCyborg" and "CryoGuard" or "FrostDrone")
		local isWaveBoss = (waveNum == 5 and actualId == "OrderCyborgBoss")
		local ang = (idx - 1) * (math.pi * 2 / #list)
		local rad = isWaveBoss and 0 or 14
		local mpos = cpos + Vector3.new(math.cos(ang) * rad, 2.8, math.sin(ang) * rad - 4)
		local mob = G.SpawnEnemy(actualId, mpos, isWaveBoss, true)
		if mob then
			mob.IsRaidDungeonMob = true
			mob.IsRaidBoss = isWaveBoss
			mob.RaidSession = session
			mob.Home = mpos
			mob.HomeFloorY = cpos.Y
			mob.MaxHP = math.max(500, math.floor(mob.MaxHP * diff.HPMult * (1 + (#session.Players - 1) * 0.2)))
			mob.HP = mob.MaxHP
			if mob.Config then
				mob.Config = table.clone(mob.Config)
				mob.Config.ATK = math.floor((mob.Config.ATK or 40) * diff.ATKMult)
			end
			if mob.Model then
				mob.Model:PivotTo(CFrame.new(mpos))
				mob.Model:SetAttribute("EnemyFloorY", cpos.Y)
			end
			table.insert(session.Mobs, mob)
		end
	end

	workspace:SetAttribute("RaidActive", true)
	workspace:SetAttribute("RaidWave", waveNum)
	workspace:SetAttribute("RaidDifficulty", diff.Id)
	for _, plr in ipairs(session.Players) do
		if plr.Parent == Players then
			plr:SetAttribute("RaidActive", true)
			plr:SetAttribute("RaidWave", waveNum)
			plr:SetAttribute("RaidDifficulty", diff.Id)
			local rt = G.Runtime[plr]
			if rt then
				rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, os.clock() + 3.0)
			end
			G.Teleport(plr, cpos + Vector3.new(0, 3.2, 18))
			G.Notify(plr, string.format("[RAID %s] WAVE %d/5 BẮT ĐẦU! Hạ gục toàn bộ quân đoàn trên Đảo #%d!", diff.Label, waveNum, waveNum))
		end
	end
end

function SubService.VoteRaidDifficulty(p, diffId)
	local clean = tostring(diffId or "Normal")
	if not RAID_DIFFICULTIES[clean] then
		clean = "Normal"
	end
	local rt = G.Runtime[p]
	if rt then
		rt.SelectedRaidDifficulty = clean
	end
	p:SetAttribute("RaidDifficulty", clean)
	workspace:SetAttribute("RaidDifficulty", clean)
	local spec = RAID_DIFFICULTIES[clean]
	G.Notify(p, string.format("ĐÃ CHỌN ĐỘ KHÓ RAID: [%s] (%.2fx HP, +%d Core Shards%s)!", spec.Label, spec.HPMult, spec.Shards, spec.Microchip and " + Awakening Microchip" or ""))
end

local endRaidSession

function SubService.StartMicrochipRaid(leader, requestedDiff)
	if not leader or leader.Parent ~= Players then
		return
	end
	if isPlayerInPvPCombat(leader) or isPlayerInColosseum(leader) then
		notifyBilingual(
			leader,
			"Cannot start Awakening Raid while in PvP combat or 1v1 Colosseum!",
			"Không thể bắt đầu Awakening Raid khi đang giao chiến PvP hoặc Đấu Trường 1v1!"
		)
		return
	end
	if leader:GetAttribute("InTrade") == true or (leader:GetAttribute("SpireFloor") or 0) > 0 or leader:GetAttribute("InTempleV4Trial") == true then
		G.Notify(leader, "Không thể bắt đầu Awakening Raid khi đang Giao Dịch, Thử Thách Thăng Hoa hoặc trong Sky Spire!")
		return
	end

	-- D-A8 Fix: Verify caller is Party Leader (or solo) before pulling party members!
	local isLeaderOrSolo, partyList = isPartyLeaderOrSolo(leader)
	if not isLeaderOrSolo then
		notifyBilingual(
			leader,
			"Only the Party Leader can start Awakening Raid for a party (or leave party to raid solo)!",
			"Chỉ Đội Trưởng mới có thể mở Awakening Raid cho Tổ Đội (hoặc rời đội để đi đơn)!"
		)
		return
	end

	local existingSession = PlayerRaidSession[leader]
	if existingSession then
		if os.clock() > (existingSession.EndsAt or 0) + 5 or #(existingSession.Players or {}) == 0 then
			pcall(endRaidSession, existingSession, false, nil)
		else
			G.Notify(leader, "Tổ đội của bạn đang ở trong Awakening Raid (Wave " .. tostring(existingSession.Wave) .. "/5)!")
			return
		end
	end

	local leaderProf = D.Get(leader)
	if not leaderProf or leaderProf._ReadOnlyFallback == true then
		G.Notify(leader, "Hồ sơ đang tạm khóa bảo vệ dữ liệu — chưa thể khởi động Awakening Raid!")
		return
	end
	local isDev = DevGate.IsAllowed(leader)
	local leaderLv = tonumber(leaderProf.Level) or 1
	if leaderLv < 700 and not isDev then
		G.Notify(leader, "Cần đạt ít nhất Lv.700 (Tầng Trời 2) để khởi động Microchip Awakening Raid!")
		return
	end
	leaderProf.Inventory = type(leaderProf.Inventory) == "table" and leaderProf.Inventory or {}
	local inv = leaderProf.Inventory
	local chipKey = ((tonumber(inv.AwakeningMicrochip) or 0) > 0 and "AwakeningMicrochip")
		or ((tonumber(inv.RaidMicrochip) or 0) > 0 and "RaidMicrochip")
		or nil
	if not chipKey and not isDev then
		G.Notify(leader, "Cần 1 Chip Lõi Thức Tỉnh [Awakening Microchip] (mua tại Học Giả Aether / Thương Nhân Hư Không) để mở Awakening Raid!")
		return
	end

	local rt = G.Runtime[leader]
	local diffKey = tostring(requestedDiff or (rt and rt.SelectedRaidDifficulty) or leader:GetAttribute("RaidDifficulty") or "Normal")
	local diffSpec = RAID_DIFFICULTIES[diffKey] or RAID_DIFFICULTIES.Normal

	local candidates = isLeaderOrSolo and partyList or { leader }
	local squad = {}
	local seen = {}
	for _, member in ipairs(candidates) do
		local mProf = member and D.Get(member)
		local mLv = tonumber(mProf and mProf.Level) or 1
		if member and member.Parent == Players and not seen[member] and #squad < 6
			and root(member) ~= nil
			and PlayerRaidSession[member] == nil
			and (mLv >= 700 or DevGate.IsAllowed(member))
			and not isPlayerInPvPCombat(member)
			and not isPlayerInColosseum(member)
			and member:GetAttribute("InTrade") ~= true
			and (member:GetAttribute("SpireFloor") or 0) == 0
			and member:GetAttribute("InTempleV4Trial") ~= true then
			seen[member] = true
			table.insert(squad, member)
		end
	end
	if not seen[leader] and root(leader) ~= nil and not isPlayerInPvPCombat(leader) and not isPlayerInColosseum(leader) then
		table.insert(squad, 1, leader)
	end
	if #squad == 0 then
		return
	end

	local consumedChip = false
	if chipKey then
		inv[chipKey] = math.max(0, (tonumber(inv[chipKey]) or 0) - 1)
		if inv[chipKey] == 0 then
			inv[chipKey] = nil
		end
		consumedChip = true
		G.Sync(leader)
	end

	local originMap = {}
	local revivesLeft = {}
	for _, plr in ipairs(squad) do
		local pr = root(plr)
		local mProf = D.Get(plr)
		local mLv = tonumber(mProf and mProf.Level) or 1
		local prevRealm = tostring(plr:GetAttribute("CurrentRealm") or "GoldenSky")
		local safeRealm = (mLv >= 1500 and prevRealm) or (mLv >= 700 and (prevRealm == "ShadowRealm" and "FrozenCyber" or prevRealm)) or "GoldenSky"
		local safePos = (mLv >= 700) and Vector3.new(14600, 50.9, 1785) or (C.Spawn or Vector3.new(-317.4, 50.5, 527.8))
		originMap[plr] = {
			Pos = (pr and safeRealm == prevRealm) and pr.Position or safePos,
			Realm = safeRealm,
		}
		revivesLeft[plr] = 2 -- 2 revives = 3 lives total!
		plr:SetAttribute("RaidLivesLeft", 3)
	end

	RaidSeqCounter += 1
	local session = {
		Id = "Raid_" .. tostring(RaidSeqCounter),
		Leader = leader,
		Players = squad,
		OriginMap = originMap,
		RevivesLeft = revivesLeft,
		DifficultySpec = diffSpec,
		Wave = 1,
		WaveStartedAt = os.clock(),
		EndsAt = os.clock() + 720, -- 12:00 countdown
		Mobs = {},
		DamageMap = {},
	}
	local slotIndex = allocateRaidSlot(session)
	local centers, createdParts = buildInstancedRaidArena(slotIndex)
	session.SlotIndex = slotIndex
	session.PlatformCenters = centers
	session.ArenaParts = createdParts
	ActiveRaidSessions[session.Id] = session

	for _, plr in ipairs(squad) do
		PlayerRaidSession[plr] = session
		plr:SetAttribute("CurrentRealm", "FrozenCyber")
	end
	local okWave, waveErr = pcall(spawnRaidWave, session, 1)
	if not okWave then
		warn("[SkybreakWorldEvents] spawnRaidWave error:", waveErr)
		if consumedChip and chipKey then
			inv[chipKey] = (tonumber(inv[chipKey]) or 0) + 1
			G.Sync(leader)
		end
		pcall(endRaidSession, session, false, "[RAID] Không thể khởi tạo Đấu Trường Raid — đã hoàn lại Chip!")
	end
end

local function clearPlayerRaidAttributes(plr)
	PlayerRaidSession[plr] = nil
	if plr and plr.Parent == Players then
		plr:SetAttribute("RaidActive", false)
		plr:SetAttribute("RaidWave", 0)
		plr:SetAttribute("RaidTimer", 0)
		plr:SetAttribute("RaidLivesLeft", 0)
	end
end

endRaidSession = function(session, victory, reasonMsg)
	if not session or session._ended then
		return
	end
	session._ended = true
	ActiveRaidSessions[session.Id] = nil
	if session.SlotIndex then
		UsedRaidSlots[session.SlotIndex] = nil
	end
	if next(ActiveRaidSessions) == nil then
		workspace:SetAttribute("RaidActive", false)
		workspace:SetAttribute("RaidWave", 0)
		workspace:SetAttribute("RaidTimer", 0)
	end

	for _, mob in ipairs(session.Mobs or {}) do
		if mob.Alive then
			mob.Alive = false
			if mob.Model and mob.Model.Parent then
				mob.Model:Destroy()
			end
		end
	end

	local diff = session.DifficultySpec
	if victory then
		for _, plr in ipairs(session.Players) do
			if plr.Parent == Players then
				local prof = D.Get(plr)
				if prof then
					prof.RaidChipsCleared = (tonumber(prof.RaidChipsCleared) or 0) + 1
					prof.MicrochipRaidsCleared = type(prof.MicrochipRaidsCleared) == "table" and prof.MicrochipRaidsCleared or {}
					local fid = resolveCanonicalFruitId(prof.EquippedFruit)
					if fid ~= "" then
						prof.MicrochipRaidsCleared[fid] = true
						prof.AwakenedFruits = type(prof.AwakenedFruits) == "table" and prof.AwakenedFruits or {}
						prof.AwakenedFruits[fid] = true
					end
					prof.UnlockedTitles = prof.UnlockedTitles or {}
					prof.UnlockedTitles.awakened_ascendant = true
					if diff.Microchip then
						prof.Inventory = prof.Inventory or {}
						prof.Inventory.AwakeningMicrochip = (prof.Inventory.AwakeningMicrochip or 0) + 1
					end
					G.Reward(plr, diff.XP, diff.Gold, diff.Shards)
					G.Notify(plr, string.format("CHIẾN THẮNG AWAKENING RAID [%s]! +%d Core Shards, +%d Gold%s!", diff.Label, diff.Shards, diff.Gold, fid ~= "" and (" & Mở Khóa Thức Tỉnh V2 [" .. fid .. "]") or ""))
					fireUIStateToPlayer(plr, {
						RaidChipsCleared = prof.RaidChipsCleared,
						MicrochipRaidsCleared = prof.MicrochipRaidsCleared,
					})
					G.Sync(plr)
					if D.Save then
						task.spawn(D.Save, plr, false)
					end
				end
			end
		end
		broadcastMVPSummary("Microchip Awakening Raid (" .. diff.Label .. ")", session.DamageMap, diff.HPMult)
		if diff.Id == "Mythic" then
			broadcastWorldBanner(
				"CHINH PHỤC MYTHIC AWAKENING RAID!",
				(session.Leader and session.Leader.Name or "Tổ Đội Skyborn") .. " đã vượt qua 5 Wave Mythic Raid và nhận Awakening Microchip!",
				"MythicRaid"
			)
		end
	end

	local centers = session.PlatformCenters
	local waveCenter = (centers and (centers[session.Wave] or centers[1])) or RAID_BASE_ORIGIN
	local arenaParts = session.ArenaParts
	session.ArenaParts = nil

	for _, plr in ipairs(session.Players) do
		if plr.Parent == Players then
			clearPlayerRaidAttributes(plr)
			if not victory and reasonMsg then
				G.Notify(plr, reasonMsg)
			end
			local orig = session.OriginMap and session.OriginMap[plr]
			task.delay(3.5, function()
				if plr.Parent == Players and PlayerRaidSession[plr] == nil then
					local pr = root(plr)
					if not pr or dist(pr.Position, waveCenter) <= 320 then
						local mProf = D.Get(plr)
						local mLv = tonumber(mProf and mProf.Level) or 1
						local destRealm = (orig and orig.Realm) or ((mLv >= 700) and "FrozenCyber" or "GoldenSky")
						local destPos = (orig and orig.Pos) or ((mLv >= 700) and Vector3.new(14600, 50.9, 1785) or (C.Spawn or Vector3.new(-317.4, 50.5, 527.8)))
						plr:SetAttribute("CurrentRealm", destRealm)
						local prt = G.Runtime[plr]
						if prt then
							prt.JumpPadUntil = math.max(prt.JumpPadUntil or 0, os.clock() + 2.5)
						end
						G.Teleport(plr, destPos)
						G.Sync(plr)
					end
				end
			end)
		end
	end

	task.delay(4.2, function()
		destroySessionParts(arenaParts)
	end)
end

function SubService.TickRaidDungeon()
	local now = os.clock()
	for _, session in pairs(ActiveRaidSessions) do
		local rem = math.max(0, math.ceil(session.EndsAt - now))
		workspace:SetAttribute("RaidTimer", rem)

		local centers = session.PlatformCenters
		local waveCenter = (centers and (centers[session.Wave] or centers[1])) or RAID_BASE_ORIGIN
		local graceElapsed = (now - (session.WaveStartedAt or 0)) > 4.5
		local activeSquad = {}
		local inArenaAliveCount = 0

		for _, plr in ipairs(session.Players) do
			if plr and plr.Parent == Players then
				local pr, ph = root(plr)
				local prt = G.Runtime[plr]
				local isDowned = prt and prt.IsDowned == true
				local revives = tonumber(session.RevivesLeft and session.RevivesLeft[plr]) or 0

				if pr and ph and ph.Health > 0 and not isDowned and graceElapsed and dist(pr.Position, waveCenter) > 235 then
					if revives > 0 then
						SubService.ConsumeRaidRevive(plr, session)
						plr:SetAttribute("RaidTimer", rem)
						table.insert(activeSquad, plr)
						inArenaAliveCount += 1
					else
						clearPlayerRaidAttributes(plr)
						G.Notify(plr, "[RAID] Bạn đã hết lượt hồi sinh và rời khỏi Đấu Trường Awakening Raid!")
						G.Sync(plr)
					end
				else
					plr:SetAttribute("RaidTimer", rem)
					table.insert(activeSquad, plr)
					if (pr and ph and (ph.Health > 0 or isDowned) and dist(pr.Position, waveCenter) <= 235) or revives > 0 then
						inArenaAliveCount += 1
					end
				end
			end
		end
		session.Players = activeSquad

		if #activeSquad == 0 then
			endRaidSession(session, false, "[RAID] Toàn bộ tổ đội đã hết lượt hồi sinh hoặc rời khỏi Đấu Trường Raid!")
		elseif inArenaAliveCount == 0 then
			session.AllMissingSince = session.AllMissingSince or now
			if (now - session.AllMissingSince) >= 8.0 then
				endRaidSession(session, false, "[RAID] Tổ đội đã thất bại trong Awakening Raid!")
			end
		else
			session.AllMissingSince = nil
			if rem <= 0 then
				endRaidSession(session, false, "[RAID] Hết thời gian 12:00! Hãy nâng cấp trang bị và thử lại!")
			else
				local aliveMobs = 0
				for _, mob in ipairs(session.Mobs) do
					if mob.Alive and mob.Model and mob.Model.Parent then
						aliveMobs += 1
					end
					for plr, hit in pairs(mob.Contributors or {}) do
						if not mob._raidCounted then
							mob._raidCounted = {}
						end
						local prevCounted = mob._raidCounted[plr] or 0
						local curDmg = (type(hit) == "table" and hit.Damage or 0)
						if curDmg > prevCounted then
							mob._raidCounted[plr] = curDmg
							local entry = session.DamageMap[plr] or { Damage = 0 }
							entry.Damage += (curDmg - prevCounted)
							session.DamageMap[plr] = entry
						end
					end
				end

				if aliveMobs == 0 then
					if session.Wave < 5 then
						spawnRaidWave(session, session.Wave + 1)
					else
						endRaidSession(session, true)
					end
				end
			end
		end
	end
end

function SubService.ResetAllRaidsOnError()
	for _, s in pairs(table.clone(ActiveRaidSessions)) do
		pcall(endRaidSession, s, false, "[RAID] Phiên Raid kết thúc do gián đoạn hệ thống.")
	end
	table.clear(ActiveRaidSessions)
	workspace:SetAttribute("RaidActive", false)
end

-- ============================================================================
-- 4. #80 - PER-PARTY INSTANCED 50-FLOOR ENDLESS SKY SPIRE TOWER AT SKY HUB
-- ============================================================================
local function allocateSpireSlot(session)
	local slotIndex = 1
	while UsedSpireSlots[slotIndex] ~= nil do
		slotIndex += 1
	end
	UsedSpireSlots[slotIndex] = session
	return slotIndex
end

local function destroySpireInstance(session)
	if not session or session._destroyed then
		return
	end
	session._destroyed = true
	SpireSessionList[session.Id] = nil
	if session.SlotIndex then
		UsedSpireSlots[session.SlotIndex] = nil
	end
	for _, m in ipairs(session.Mobs or {}) do
		if m.Alive then
			m.Alive = false
		end
		if m.Model and m.Model.Parent then
			m.Model:Destroy()
		end
	end
	destroySessionParts(session.ArenaParts)
	session.ArenaParts = nil
end

local function cleanupSpireSession(plr, teleportToHub)
	local session = ActiveSpireSessions[plr]
	ActiveSpireSessions[plr] = nil
	if session then
		local kept = {}
		for _, member in ipairs(session.Players or {}) do
			if member ~= plr and member.Parent == Players and ActiveSpireSessions[member] == session then
				table.insert(kept, member)
			end
		end
		session.Players = kept
		if #kept == 0 then
			destroySpireInstance(session)
		end
	end
	if plr and plr.Parent == Players then
		plr:SetAttribute("SpireFloor", 0)
		-- D-A8 Fix: Only teleport to Sky Hub if player actually had an active Spire session and is NOT in PvP combat!
		if teleportToHub and session ~= nil and not isPlayerInPvPCombat(plr) then
			local rt = G.Runtime[plr]
			if rt then
				rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, os.clock() + 2.5)
			end
			G.Teleport(plr, Vector3.new(-322, 50.5, 504))
			G.Notify(plr, "Đã trở về Quảng Trường Sky Hub!")
			G.Sync(plr)
		end
	end
end

function SubService.EnsureSkySpirePortalAndArena()
	local worldObjects = getWorldObjects()
	local old = worldObjects:FindFirstChild("SkySpirePortal_SkyHub")
	if old then
		old:Destroy()
	end

	local rawPos = Vector3.new(-326, 46.7, 478)
	local fy = safeFloorY(rawPos, 46.5)
	local pm = Instance.new("Model")
	pm.Name = "SkySpirePortal_SkyHub"
	pm.Parent = worldObjects

	local base = W.Part(pm, "SpireArchBase", Vector3.new(8.5, 1.0, 4.2), Vector3.new(rawPos.X, fy + 0.5, rawPos.Z), Color3.fromRGB(36, 32, 52), Enum.Material.Slate)
	W.Part(pm, "SpirePillarL", Vector3.new(1.6, 10.5, 1.8), Vector3.new(rawPos.X - 3.2, fy + 5.6, rawPos.Z), Color3.fromRGB(238, 192, 78), Enum.Material.Metal)
	W.Part(pm, "SpirePillarR", Vector3.new(1.6, 10.5, 1.8), Vector3.new(rawPos.X + 3.2, fy + 5.6, rawPos.Z), Color3.fromRGB(238, 192, 78), Enum.Material.Metal)
	W.Part(pm, "SpireCrown", Vector3.new(8.6, 1.6, 2.2), Vector3.new(rawPos.X, fy + 11.2, rawPos.Z), Color3.fromRGB(238, 192, 78), Enum.Material.Metal)
	local gateCore = W.Part(pm, "SpireVortex", Vector3.new(4.8, 9.2, 0.45), Vector3.new(rawPos.X, fy + 5.6, rawPos.Z), Color3.fromRGB(98, 232, 255), Enum.Material.Neon)
	gateCore.Transparency = 0.42
	gateCore.CanCollide = false
	pm.PrimaryPart = base

	local bill = Instance.new("BillboardGui")
	bill.Size = UDim2.fromScale(5.2, 1.0)
	bill.StudsOffset = Vector3.new(0, 7.6, 0)
	bill.AlwaysOnTop = false
	bill.MaxDistance = 68
	bill.Parent = gateCore
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamBlack
	tl.TextScaled = true
	tl.TextColor3 = Color3.fromRGB(255, 224, 110)
	tl.TextStrokeTransparency = 0.16
	tl.Text = "ENDLESS SKY SPIRE [TẦNG 1 -> 50]"
	tl.Parent = bill

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Khiêu Chiến Tháp Vô Tận Sky Spire"
	prompt.ObjectText = "Endless Sky Spire • 50 Tầng Thử Thách"
	prompt.MaxActivationDistance = 16
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.Parent = base
	prompt.Triggered:Connect(function(plr)
		SubService.EnterSkySpire(plr)
	end)
end

local function buildInstancedSpireArena(slotIndex)
	local worldObjects = getWorldObjects()
	local colFolder = workspace:FindFirstChild("GrandSkyIslands_Collision") or worldObjects
	local arenaCenter = SPIRE_BASE_CENTER + Vector3.new(slotIndex * 450, 0, 0)

	local modelName = "SkySpireInstance_Slot_" .. tostring(slotIndex)
	local oldM = worldObjects:FindFirstChild(modelName)
	if oldM then
		oldM:Destroy()
	end
	local instModel = Instance.new("Model")
	instModel.Name = modelName
	instModel.Parent = worldObjects

	local deck = Instance.new("Part")
	deck.Name = "SkySpireColosseumFloor_S" .. tostring(slotIndex)
	deck.Shape = Enum.PartType.Cylinder
	deck.Size = Vector3.new(3.6, 96, 96)
	deck.CFrame = CFrame.new(arenaCenter.X, arenaCenter.Y - 1.8, arenaCenter.Z) * CFrame.Angles(0, 0, math.pi / 2)
	deck.Color = Color3.fromRGB(228, 224, 214)
	deck.Material = Enum.Material.Marble
	deck.Anchored, deck.CanCollide, deck.CanQuery, deck.CanTouch = true, true, true, false
	deck.Parent = colFolder

	local rim = Instance.new("Part")
	rim.Name = "SkySpireRim"
	rim.Shape = Enum.PartType.Cylinder
	rim.Size = Vector3.new(0.45, 92, 92)
	rim.CFrame = CFrame.new(arenaCenter.X, arenaCenter.Y - 0.05, arenaCenter.Z) * CFrame.Angles(0, 0, math.pi / 2)
	rim.Color = Color3.fromRGB(98, 232, 255)
	rim.Material = Enum.Material.Neon
	rim.Transparency = 0.48
	rim.Anchored, rim.CanCollide, rim.CanQuery, rim.CanTouch = true, false, false, false
	rim.Parent = instModel

	local exitPad = W.Part(instModel, "SpireExitBeacon", Vector3.new(4.2, 1.0, 4.2), arenaCenter + Vector3.new(0, 0.5, 38), Color3.fromRGB(255, 198, 84), Enum.Material.Neon)
	exitPad.Transparency = 0.38
	local ep = Instance.new("ProximityPrompt")
	ep.ActionText = "Rời Tháp Sky Spire Về Sky Hub"
	ep.ObjectText = "Sky Spire Exit"
	ep.MaxActivationDistance = 14
	ep.HoldDuration = 0
	ep.RequiresLineOfSight = false
	ep.Parent = exitPad
	ep.Triggered:Connect(function(plr)
		SubService.LeaveSkySpire(plr)
	end)

	return arenaCenter, { instModel, deck }
end

local function spawnSpireFloorEnemies(session, floorNum)
	session.Floor = floorNum
	session.Mobs = {}
	local arenaCenter = session.ArenaCenter or SPIRE_BASE_CENTER
	local partyScale = 1 + math.max(0, #(session.Players or {}) - 1) * 0.22

	local isMilestoneBoss = (floorNum % 5 == 0)
	local hpScale = (1 + (floorNum - 1) * 0.28 + ((floorNum > 25) and (floorNum - 25) * 0.22 or 0)) * partyScale
	local atkScale = 1 + (floorNum - 1) * 0.08

	local pool = (floorNum <= 15) and { "SkyPirate", "CorruptedGuard", "LightArcher", "GoldenKnight" }
		or ((floorNum <= 35) and { "CryoGuard", "CyberArcher", "GoldenKnight", "AbyssalKnight" }
		or { "AbyssalKnight", "ShadowArcher", "VoidPirate", "GoldenKnight" })

	local count = isMilestoneBoss and 3 or math.min(5, 2 + math.floor(floorNum / 12))
	for i = 1, count do
		local ang = (i - 1) * (math.pi * 2 / count)
		local mpos = arenaCenter + Vector3.new(math.cos(ang) * 16, 2.6, math.sin(ang) * 16 - 4)
		local mobId = pool[((floorNum + i) % #pool) + 1]
		local mob = G.SpawnEnemy(mobId, mpos, false, true)
		if mob then
			mob.IsSpireMob = true
			mob.SpireSession = session
			mob.Home = mpos
			mob.HomeFloorY = arenaCenter.Y
			mob.MaxHP = math.floor(950 * hpScale)
			mob.HP = mob.MaxHP
			if mob.Config then
				mob.Config = table.clone(mob.Config)
				mob.Config.ATK = math.floor(24 * atkScale)
			end
			if mob.Model then
				mob.Model:PivotTo(CFrame.new(mpos))
				mob.Model:SetAttribute("EnemyFloorY", arenaCenter.Y)
			end
			table.insert(session.Mobs, mob)
		end
	end

	if isMilestoneBoss then
		local bossPool = { "PirateCaptainVance", "OrderCyborgBoss", "CryonPrime", "SoulReaperRift", "Noxar" }
		local bId = bossPool[math.clamp(math.ceil(floorNum / 10), 1, math.max(1, #bossPool))]
		if not C.Enemies[bId] then
			bId = "GoldenKnight"
		end
		local bpos = arenaCenter + Vector3.new(0, 3.0, -10)
		local bMob = G.SpawnEnemy(bId, bpos, true, true)
		if bMob then
			bMob.IsSpireMob = true
			bMob.IsSpireBoss = true
			bMob.SpireSession = session
			bMob.Home = bpos
			bMob.HomeFloorY = arenaCenter.Y
			bMob.MaxHP = math.floor(4200 * hpScale)
			bMob.HP = bMob.MaxHP
			if bMob.Config then
				bMob.Config = table.clone(bMob.Config)
				bMob.Config.ATK = math.floor(38 * atkScale)
			end
			if bMob.Model then
				bMob.Model:PivotTo(CFrame.new(bpos))
				bMob.Model:SetAttribute("EnemyFloorY", arenaCenter.Y)
			end
			table.insert(session.Mobs, bMob)
		end
	end

	for _, member in ipairs(session.Players or {}) do
		if member.Parent == Players then
			member:SetAttribute("SpireFloor", floorNum)
			G.Notify(member, string.format("[SKY SPIRE] TẦNG %d / 50%s!", floorNum, isMilestoneBoss and " • BOSS TẦNG MỐC" or ""))
		end
	end
end

function SubService.EnterSkySpire(p, requestedFloor)
	local prof = D.Get(p)
	local rt = G.Runtime[p]
	if not prof or not rt then
		return
	end
	if isPlayerInPvPCombat(p) or isPlayerInColosseum(p) then
		notifyBilingual(
			p,
			"Cannot enter Endless Sky Spire while in PvP combat or 1v1 Colosseum!",
			"Không thể vào Endless Sky Spire khi đang giao chiến PvP hoặc Đấu Trường 1v1!"
		)
		return
	end
	if p:GetAttribute("InTrade") == true or p:GetAttribute("RaidActive") == true or p:GetAttribute("InTempleV4Trial") == true then
		G.Notify(p, "Không thể vào Endless Sky Spire khi đang Giao Dịch, Thử Thách Thăng Hoa hoặc Raid!")
		return
	end
	if ActiveSpireSessions[p] ~= nil then
		G.Notify(p, "Bạn đang ở trong Endless Sky Spire (Tầng " .. tostring(ActiveSpireSessions[p].Floor or 1) .. "/50)!")
		return
	end

	-- D-A8 Fix: Verify caller is Party Leader (or solo) before pulling party members!
	local isLeaderOrSolo, partyList = isPartyLeaderOrSolo(p)
	if not isLeaderOrSolo then
		notifyBilingual(
			p,
			"Only the Party Leader can launch Endless Sky Spire for a party (or leave party to enter solo)!",
			"Chỉ Đội Trưởng mới có thể đưa Tổ Đội vào Endless Sky Spire (hoặc rời đội để đi đơn)!"
		)
		return
	end

	if not getWorldObjects():FindFirstChild("SkySpirePortal_SkyHub") then
		SubService.EnsureSkySpirePortalAndArena()
	end
	local maxUnlocked = math.clamp((prof.HighestSpireFloor or 0) + 1, 1, 50)
	local startFloor = requestedFloor and math.clamp(tonumber(requestedFloor) or maxUnlocked, 1, maxUnlocked) or maxUnlocked

	local candidates = isLeaderOrSolo and partyList or { p }
	local squad = {}
	local seen = {}
	for _, member in ipairs(candidates) do
		if member and member.Parent == Players and not seen[member] and #squad < 6 and root(member) ~= nil
			and not isPlayerInPvPCombat(member)
			and not isPlayerInColosseum(member)
			and ActiveSpireSessions[member] == nil
			and member:GetAttribute("InTrade") ~= true
			and member:GetAttribute("RaidActive") ~= true
			and member:GetAttribute("InTempleV4Trial") ~= true then
			seen[member] = true
			table.insert(squad, member)
		end
	end
	if not seen[p] and root(p) ~= nil and not isPlayerInPvPCombat(p) and not isPlayerInColosseum(p) then
		table.insert(squad, 1, p)
	end
	if #squad == 0 then
		return
	end

	SpireSeqCounter += 1
	local session = {
		Id = "Spire_" .. tostring(SpireSeqCounter),
		Leader = p,
		Players = squad,
		Floor = startFloor,
		Mobs = {},
	}
	local slotIndex = allocateSpireSlot(session)
	local arenaCenter, createdParts = buildInstancedSpireArena(slotIndex)
	session.SlotIndex = slotIndex
	session.ArenaCenter = arenaCenter
	session.ArenaParts = createdParts
	SpireSessionList[session.Id] = session

	for idx, member in ipairs(squad) do
		ActiveSpireSessions[member] = session
		local mrt = G.Runtime[member]
		if mrt then
			mrt.JumpPadUntil = math.max(mrt.JumpPadUntil or 0, os.clock() + 3.0)
		end
		local xOff = ((idx - 1) - (#squad - 1) * 0.5) * 4.5
		G.Teleport(member, arenaCenter + Vector3.new(xOff, 3.2, 24))
	end
	spawnSpireFloorEnemies(session, startFloor)
	for _, member in ipairs(squad) do
		G.Sync(member)
	end
end

function SubService.LeaveSkySpire(p)
	-- D-A8 Fix: Block 0ms SkyHub PvP escape when player is NOT in Spire OR is in PvP combat!
	if not p or ActiveSpireSessions[p] == nil then
		return false
	end
	if (tonumber(p:GetAttribute("PvPCombatUntil")) or 0) > os.time() or isPlayerInPvPCombat(p) then
		notifyBilingual(
			p,
			"Cannot leave Sky Spire while in PvP combat!",
			"Không thể rời Sky Spire khi đang trong trạng thái giao chiến PvP!"
		)
		return false
	end
	cleanupSpireSession(p, true)
	return true
end

function SubService.TickSkySpireSessions()
	for _, session in pairs(SpireSessionList) do
		local arenaCenter = session.ArenaCenter or SPIRE_BASE_CENTER
		local activePlayers = {}
		for _, p in ipairs(session.Players or {}) do
			if p.Parent ~= Players or ActiveSpireSessions[p] ~= session then
				ActiveSpireSessions[p] = nil
			else
				local pr = root(p)
				if not pr or dist(pr.Position, arenaCenter) > 155 then
					ActiveSpireSessions[p] = nil
					p:SetAttribute("SpireFloor", 0)
					G.Sync(p)
				else
					table.insert(activePlayers, p)
				end
			end
		end
		session.Players = activePlayers

		if #activePlayers == 0 then
			destroySpireInstance(session)
		else
			local alive = 0
			for _, m in ipairs(session.Mobs) do
				if m.Alive and m.Model and m.Model.Parent then
					alive += 1
				end
			end
			if alive == 0 then
				local cleared = session.Floor
				local advancingToNextFloor = (cleared < 50)
				if advancingToNextFloor then
					spawnSpireFloorEnemies(session, cleared + 1)
				end
				for _, p in ipairs(activePlayers) do
					local prof = D.Get(p)
					local _, ph = root(p)
					if prof then
						prof.HighestSpireFloor = math.max(prof.HighestSpireFloor or 0, cleared)
						prof.UnlockedTitles = prof.UnlockedTitles or {}
						local milestoneShards = (cleared % 5 == 0) and (cleared * 16) or 10
						local floorGold = 900 + cleared * 350
						local floorXP = 2400 + cleared * 1250
						if cleared == 10 then
							prof.UnlockedTitles.spire_challenger = true
						elseif cleared == 25 then
							prof.UnlockedTitles.spire_ascendant = true
						elseif cleared == 50 then
							prof.UnlockedTitles.sky_spire_sovereign = true
							prof.Title = "sky_spire_sovereign"
						end
						G.Reward(p, floorXP, floorGold, milestoneShards)
						if ph then
							ph.Health = math.min(ph.MaxHealth, ph.Health + math.floor(ph.MaxHealth * 0.25))
						end
						-- D-A8 Fix: Cleanly reset [C] and [V] ability cooldowns when advancing between Spire floors!
						if advancingToNextFloor then
							resetSpireFloorCVCooldowns(p)
						end
						G.Sync(p)
						if cleared % 5 == 0 and D.Save then
							task.spawn(D.Save, p, false)
						end
					end
				end
				if cleared == 50 and session.Leader then
					broadcastWorldBanner(
						"ĐỈNH CAO THÁP VÔ TẬN SKY SPIRE!",
						session.Leader.Name .. " đã chinh phục Tầng 50/50 Endless Sky Spire và đạt danh hiệu [Độc Tôn Đỉnh Tháp Vô Tận]!",
						"Spire50"
					)
				end
				if not advancingToNextFloor then
					local finishers = table.clone(activePlayers)
					for _, p in ipairs(finishers) do
						ActiveSpireSessions[p] = nil
						p:SetAttribute("SpireFloor", 0)
						G.Notify(p, "CHÚC MỪNG! Bạn đã hoàn tất Tầng 50/50 Endless Sky Spire!")
					end
					task.delay(3.5, function()
						for _, p in ipairs(finishers) do
							if p.Parent == Players then
								local rt = G.Runtime[p]
								if rt then
									rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, os.clock() + 2.5)
								end
								G.Teleport(p, Vector3.new(-322, 50.5, 504))
								G.Sync(p)
							end
						end
						destroySpireInstance(session)
					end)
					SpireSessionList[session.Id] = nil
				end
			end
		end
	end
end

function SubService.OnPlayerRemoving(p)
	for _, he in ipairs(ActiveLeviathanHearts) do
		if he.TowedByPlayer == p or (he.TowedByShip and he.TowedByShip.Owner == p) then
			detachLeviathanHeartTow(he)
		end
	end
	cleanupSpireSession(p, false)
	local pRaid = PlayerRaidSession[p]
	PlayerRaidSession[p] = nil
	if pRaid then
		if pRaid.DamageMap then
			pRaid.DamageMap[p] = nil
		end
		if pRaid.RevivesLeft then
			pRaid.RevivesLeft[p] = nil
		end
		local kept = {}
		for _, member in ipairs(pRaid.Players or {}) do
			if member ~= p and member.Parent == Players then
				table.insert(kept, member)
			end
		end
		pRaid.Players = kept
		if pRaid.Leader == p then
			pRaid.Leader = kept[1]
		end
		if #kept == 0 then
			endRaidSession(pRaid, false, nil)
		end
	end
end

function SubService.Init(ctx)
	G = ctx.G
	D = ctx.D
	W = ctx.W
	C = ctx.C
	DevGate = ctx.DevGate
	ActiveWarships = ctx.ActiveWarships
	HARBOR_PORTS = ctx.HARBOR_PORTS
	SAFE_HUB_CENTERS = ctx.SAFE_HUB_CENTERS
	RAID_DIFFICULTIES = ctx.RAID_DIFFICULTIES
	root = ctx.root
	dist = ctx.dist
	flatDist = ctx.flatDist
	safeFloorY = ctx.safeFloorY
	getWorldObjects = ctx.getWorldObjects
	getActiveShipsFolder = ctx.getActiveShipsFolder
	broadcastWorldBanner = ctx.broadcastWorldBanner
	broadcastMVPSummary = ctx.broadcastMVPSummary
	resolveCanonicalFruitId = ctx.resolveCanonicalFruitId
	getPartyGroup = ctx.getPartyGroup
	playerOwnsShip = ctx.playerOwnsShip
	normalizeShipId = ctx.normalizeShipId
	findPilotedShipEntry = ctx.findPilotedShipEntry
	spawnWarshipFn = ctx.SpawnWarship
end

return SubService
