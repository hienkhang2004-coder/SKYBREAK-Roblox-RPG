-- SKYBREAK: Fragments of the Core - Wave 3 World Events, Multi-Phase Bosses, Companions, Warships & Raid/Spire Service
-- Strictly UTF-8 LF, zero astral-plane emojis (>= 0x1F300).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local WorldEvents = {}
WorldEvents._initialized = false

local G, D, W, C, R
local CombatData

local ActiveWarships = {} -- [player] = shipEntry
local ActiveLeviathanHearts = {} -- array of heartEntries
local ActiveRespawnHolograms = {} -- [bossKey] = holoEntry
local ActivePurifyingZones = {} -- array of { Pos, Radius, ExpiresAt, Model }
local ActiveRaidSession = nil
local ActiveSpireSessions = {} -- [player] = spireEntry
local ActiveMirageEvent = nil
local ActivePirateRaid = nil
local SoulRitualState = { Torches = { false, false, false }, Models = {}, RiftModel = nil, Boss = nil, ResetAt = 0 }
local DPSDummyEntry = nil

local ALL_CANONICAL_FRUITS = {
	"GaleCore",
	"SandstoneCore",
	"SolarFlameCore",
	"GlacierIceCore",
	"CelestialLightCore",
	"StarforgedMagmaCore",
	"ThunderRumbleCore",
	"AstralGravityCore",
	"DimensionalPortalCore",
	"SolarTitanCore",
	"AetherflowCore",
	"AbyssalSovereignCore",
}

local BOSS_IDS = {
	AureonSentinel = true,
	CryonPrime = true,
	Noxar = true,
	SoulReaperRift = true,
	PirateCaptainVance = true,
	OrderCyborgBoss = true,
	AbyssalLeviathan = true,
	SkySeaBeast = true,
	AbyssalSovereignDragon = true,
	SkyHubWatchCommander = true,
	ShrineGuardianBoss = true,
	AetherArchonBoss = true,
	SolarHighPriestBoss = true,
	CyberSyndicateBoss = true,
	PermafrostWardenBoss = true,
	VoidCastellanBoss = true,
	UmbralArchfiendBoss = true,
	Sylvaris = true,
	Ignivar = true,
	Nerith = true,
	Aion = true,
	Veyr = true,
}

local RANGED_SNIPER_IDS = {
	LightArcher = true,
	CyberArcher = true,
	ShadowArcher = true,
	GlacialMarksman = true,
	GlacialSniper = true,
	UmbralBowman = true,
	UmbralRanger = true,
}

local SHIELD_VANGUARD_IDS = {
	CorruptedGuard = true,
	GoldenKnight = true,
	CryoGuard = true,
	CryoVanguard = true,
	AbyssalKnight = true,
	AbyssalDreadknight = true,
	SunshardRoyalGuard = true,
	SunshardTemplar = true,
	FrostAutomaton = true,
}

local SAFE_HUB_CENTERS = {
	{ Name = "SkyHub", Pos = Vector3.new(-317.4, 48, 527.8), SafeRadius = 240 },
	{ Name = "GoldenSkyPlaza", Pos = Vector3.new(0, 48, 65), SafeRadius = 160 },
	{ Name = "ZiolesShrine", Pos = Vector3.new(-560, 50, 980), SafeRadius = 120 },
	{ Name = "AetherShrines", Pos = Vector3.new(340, 50, 980), SafeRadius = 120 },
	{ Name = "FrozenCyberHub", Pos = Vector3.new(11620.5, 48.5, 534.8), SafeRadius = 220 },
	{ Name = "CyberportCafe", Pos = Vector3.new(9400, 48, 1785), SafeRadius = 220 },
	{ Name = "ShadowRealmHub", Pos = Vector3.new(-12593.4, 48.5, 414), SafeRadius = 220 },
	{ Name = "CastleOnTheVoid", Pos = Vector3.new(-14600, 48, 2173.1), SafeRadius = 190 },
}

local SHIP_SPECS = {
	CelestialAetherGalleon = {
		MeshId = "CelestialAetherGalleon",
		DisplayName = "CELESTIAL AETHER GALLEON",
		Speed = 60,
		TurnSpeed = 1.35,
		CannonDamage = 3200,
		Accent = Color3.fromRGB(255, 214, 92),
		HullSize = Vector3.new(16, 2.4, 36),
	},
	CyberEnforcerShip = {
		MeshId = "CyberEnforcerShip",
		DisplayName = "CYBER ENFORCER GUNSHIP",
		Speed = 76,
		TurnSpeed = 1.55,
		CannonDamage = 4600,
		Accent = Color3.fromRGB(88, 238, 255),
		HullSize = Vector3.new(15, 2.4, 34),
	},
	LeviathanHunterShip = {
		MeshId = "LeviathanHunterShip",
		DisplayName = "LEVIATHAN HUNTER DREADNOUGHT",
		Speed = 92,
		TurnSpeed = 1.45,
		CannonDamage = 6500,
		Accent = Color3.fromRGB(205, 108, 255),
		HullSize = Vector3.new(18, 2.6, 40),
	},
}

local HARBOR_PORTS = {
	{ Id = "Port_SkyHub", Name = "Cảng Sky Hub", Realm = "GoldenSky", PedestalPos = Vector3.new(-366, 46.7, 548), WaterPos = Vector3.new(-428, 44.0, 565), DefaultShip = "CelestialAetherGalleon" },
	{ Id = "Port_FrozenCyber", Name = "Cảng Frozen Cyber", Realm = "FrozenCyber", PedestalPos = Vector3.new(11572, 47.1, 560), WaterPos = Vector3.new(11512, 44.0, 585), DefaultShip = "CyberEnforcerShip" },
	{ Id = "Port_Cyberport", Name = "Cảng Cyberport Cafe", Realm = "FrozenCyber", PedestalPos = Vector3.new(9400, 47.1, 2312), WaterPos = Vector3.new(9400, 44.0, 2365), DefaultShip = "CyberEnforcerShip" },
	{ Id = "Port_ShadowRealm", Name = "Cảng Shadow Realm", Realm = "ShadowRealm", PedestalPos = Vector3.new(-12658, 47.1, 446), WaterPos = Vector3.new(-12722, 44.0, 478), DefaultShip = "LeviathanHunterShip" },
}

local RAID_DIFFICULTIES = {
	Normal = { Id = "Normal", Label = "NORMAL", HPMult = 1.0, ATKMult = 1.0, Shards = 50, Gold = 12000, XP = 35000, Microchip = false },
	Hardcore = { Id = "Hardcore", Label = "HARDCORE", HPMult = 1.45, ATKMult = 1.22, Shards = 110, Gold = 26000, XP = 75000, Microchip = false },
	Mythic = { Id = "Mythic", Label = "MYTHIC", HPMult = 2.0, ATKMult = 1.42, Shards = 220, Gold = 55000, XP = 145000, Microchip = true },
}

local function root(p)
	local ch = p and p.Character
	if not ch then
		return nil, nil
	end
	local hrp = ch:FindFirstChild("HumanoidRootPart")
	local hum = ch:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then
		return nil, nil
	end
	return hrp, hum
end

local function dist(a, b)
	return (a - b).Magnitude
end

local function flatDist(a, b)
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function getTempFX()
	local f = workspace:FindFirstChild("TempFX")
	if not f then
		f = Instance.new("Folder")
		f.Name = "TempFX"
		f.Parent = workspace
	end
	return f
end

local function getWorldObjects()
	local f = workspace:FindFirstChild("SkybreakWorldObjects")
	if not f then
		f = Instance.new("Folder")
		f.Name = "SkybreakWorldObjects"
		f.Parent = workspace
	end
	return f
end

local function getActiveShipsFolder()
	local f = workspace:FindFirstChild("ActiveShips")
	if not f then
		f = Instance.new("Folder")
		f.Name = "ActiveShips"
		f.Parent = workspace
	end
	return f
end

local function safeFloorY(pos, fallbackY)
	if W and W.RaycastGround then
		local hit = W.RaycastGround(pos + Vector3.new(0, 6, 0), fallbackY or (pos.Y - 3))
		if hit and hit.Position then
			return hit.Position.Y
		end
	end
	return fallbackY or pos.Y
end

local function broadcastWorldBanner(title, subtitle, category)
	if G and G.BroadcastWorldBanner then
		G.BroadcastWorldBanner(title, subtitle, category)
		return
	end
	if R and R:FindFirstChild("StateUpdate") then
		R.StateUpdate:FireAllClients({
			WorldBanner = {
				Title = tostring(title or "SỰ KIỆN THẾ GIỚI"),
				Subtitle = tostring(subtitle or ""),
				Category = tostring(category or "Event"),
				Timestamp = workspace:GetServerTimeNow(),
			},
		})
	end
end

local function normalizeShipId(rawId)
	local s = tostring(rawId or "")
	if s == "CyberEnforcer" or s == "CyberEnforcerShip" then
		return "CyberEnforcerShip"
	elseif s == "LeviathanHunterShip" or s == "LeviathanHunter" then
		return "LeviathanHunterShip"
	end
	return "CelestialAetherGalleon"
end

local function isBossEnemy(e)
	if not e then
		return false
	end
	if e.IsDPSDummy or e.Id == "EnergyPylon" or e.Id == "CryonPillar" or e.Id == "NoxarVoidFX" then
		return false
	end
	return (e == G.Boss) or (e.Config and e.Config.Boss == true) or (BOSS_IDS[e.Id] == true) or (e.IsRaidBoss == true) or (e.IsSpireBoss == true)
end

local function getPartyGroup(leader)
	if G and G.GetPartyPlayers then
		local list = G.GetPartyPlayers(leader)
		if type(list) == "table" and #list > 0 then
			return list
		end
	end
	return { leader }
end

local function ensureExtraEnemiesInConfig()
	if not C or type(C.Enemies) ~= "table" then
		return
	end
	local extras = {
		TerrorSkyShark = {
			Name = "Terror Sky-Shark",
			VisualAsset = "TerrorSkyShark",
			Element = "Frost",
			Level = 1350,
			HP = 26000,
			ATK = 145,
			DEF = 35,
			Speed = 24,
			Range = 11,
			Aggro = 95,
			Leash = 180,
			XP = 18500,
			Gold = 4800,
			Elite = true,
		},
		SkySeaBeast = C.Enemies.SkySeaBeast or {
			Name = "Sky Sea Beast",
			VisualAsset = "SkySeaBeast",
			Element = "Frost",
			Level = 1650,
			HP = 68000,
			ATK = 210,
			DEF = 50,
			Speed = 16,
			Range = 22,
			Aggro = 120,
			Leash = 220,
			XP = 46000,
			Gold = 14000,
			Boss = true,
		},
		AbyssalLeviathan = C.Enemies.AbyssalLeviathan or {
			Name = "Abyssal Leviathan",
			VisualAsset = "AbyssalLeviathan",
			Element = "Void",
			Level = 2350,
			HP = 145000,
			ATK = 310,
			DEF = 70,
			Speed = 15,
			Range = 26,
			Aggro = 150,
			Leash = 260,
			XP = 125000,
			Gold = 36000,
			Boss = true,
		},
		SoulReaperRift = C.Enemies.SoulReaperRift or {
			Name = "Soul Reaper of the Rift",
			VisualAsset = "SoulReaperRift",
			Element = "Void",
			Level = 2050,
			HP = 115000,
			ATK = 275,
			DEF = 62,
			Speed = 19,
			Range = 16,
			Aggro = 95,
			Leash = 140,
			XP = 95000,
			Gold = 28000,
			Boss = true,
		},
		CryonPillar = C.Enemies.CryonPillar or {
			Name = "Cột Băng Vĩnh Cửu",
			VisualAsset = "CryonPillar",
			Element = "Frost",
			Level = 950,
			HP = 6500,
			ATK = 0,
			DEF = 15,
			Speed = 0,
			Range = 0,
			Aggro = 0,
			Leash = 999,
			XP = 800,
			Gold = 350,
		},
		EnergyPylon = C.Enemies.EnergyPylon or {
			Name = "Trụ Thái Dương Aureon",
			VisualAsset = "EnergyPylon",
			Element = "Sky",
			Level = 450,
			HP = 4200,
			ATK = 0,
			DEF = 10,
			Speed = 0,
			Range = 0,
			Aggro = 0,
			Leash = 999,
			XP = 500,
			Gold = 250,
		},
		NoxarVoidFX = C.Enemies.NoxarVoidFX or {
			Name = "Lõi Hư Không Noxar",
			VisualAsset = "NoxarVoidFX",
			Element = "Void",
			Level = 1800,
			HP = 12000,
			ATK = 0,
			DEF = 20,
			Speed = 0,
			Range = 0,
			Aggro = 0,
			Leash = 999,
			XP = 1500,
			Gold = 600,
		},
	}
	for id, spec in pairs(extras) do
		if not C.Enemies[id] then
			C.Enemies[id] = spec
		end
	end
end

-- ============================================================================
-- 1. #18 - 3D GROUND TELEGRAPHS (ANTI-GLARE >= 0.35) & MULTI-PHASE BOSS AI
-- ============================================================================
local function spawn3DTelegraphZone(centerPos, radius, duration, label, onDetonate, style, dirVec, accentColor)
	local tempFolder = getTempFX()
	local dur = math.clamp(tonumber(duration) or 1.25, 0.45, 3.5)
	local rad = math.max(3, tonumber(radius) or 10)
	local gy = safeFloorY(centerPos, centerPos.Y - 0.5) + 0.48
	local col = accentColor or Color3.fromRGB(255, 72, 92)
	local fillCol = accentColor and accentColor:Lerp(Color3.new(1, 1, 1), 0.18) or Color3.fromRGB(255, 115, 95)

	local m = Instance.new("Model")
	m.Name = "TelegraphZone"
	m:SetAttribute("TelegraphStyle", tostring(style or "Circle"))
	m.Parent = tempFolder

	if style == "Laser" or style == "Line" then
		local look = (typeof(dirVec) == "Vector3" and dirVec.Magnitude > 0.05) and Vector3.new(dirVec.X, 0, dirVec.Z).Unit or Vector3.new(0, 0, -1)
		local length = rad * 2.4
		local width = math.max(5.5, rad * 0.55)
		local mid = Vector3.new(centerPos.X, gy, centerPos.Z) + look * (length * 0.5)
		local baseCF = CFrame.lookAt(mid, mid + look)

		local outer = Instance.new("Part")
		outer.Name = "OuterRing"
		outer.Size = Vector3.new(width, 0.22, length)
		outer.CFrame = baseCF
		outer.Color = col
		outer.Material = Enum.Material.Neon
		outer.Transparency = 0.42
		outer.Anchored, outer.CanCollide, outer.CanQuery, outer.CanTouch, outer.CastShadow = true, false, false, false, false
		outer.Parent = m

		local inner = Instance.new("Part")
		inner.Name = "InnerFill"
		inner.Size = Vector3.new(0.6, 0.26, length)
		inner.CFrame = baseCF
		inner.Color = fillCol
		inner.Material = Enum.Material.Neon
		inner.Transparency = 0.55
		inner.Anchored, inner.CanCollide, inner.CanQuery, inner.CanTouch, inner.CastShadow = true, false, false, false, false
		inner.Parent = m

		TweenService:Create(inner, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = Vector3.new(width, 0.26, length),
			Transparency = 0.36,
		}):Play()
	else
		local baseCF = CFrame.new(centerPos.X, gy, centerPos.Z) * CFrame.Angles(0, 0, math.pi / 2)
		local outer = Instance.new("Part")
		outer.Name = "OuterRing"
		outer.Shape = Enum.PartType.Cylinder
		outer.Size = Vector3.new(0.22, rad * 2, rad * 2)
		outer.CFrame = baseCF
		outer.Color = col
		outer.Material = Enum.Material.Neon
		outer.Transparency = 0.40
		outer.Anchored, outer.CanCollide, outer.CanQuery, outer.CanTouch, outer.CastShadow = true, false, false, false, false
		outer.Parent = m

		local inner = Instance.new("Part")
		inner.Name = "InnerFill"
		inner.Shape = Enum.PartType.Cylinder
		inner.Size = Vector3.new(0.26, 1.2, 1.2)
		inner.CFrame = baseCF
		inner.Color = fillCol
		inner.Material = Enum.Material.Neon
		inner.Transparency = 0.58
		inner.Anchored, inner.CanCollide, inner.CanQuery, inner.CanTouch, inner.CastShadow = true, false, false, false, false
		inner.Parent = m

		TweenService:Create(inner, TweenInfo.new(dur, Enum.EasingStyle.Linear), {
			Size = Vector3.new(0.26, rad * 2, rad * 2),
			Transparency = 0.36,
		}):Play()

		if label and label ~= "" then
			local bill = Instance.new("BillboardGui")
			bill.Size = UDim2.fromScale(4.0, 0.72)
			bill.StudsOffset = Vector3.new(0, 3.0, 0)
			bill.AlwaysOnTop = false
			bill.MaxDistance = 68
			bill.Parent = outer
			local tl = Instance.new("TextLabel")
			tl.Size = UDim2.fromScale(1, 1)
			tl.BackgroundTransparency = 1
			tl.Font = Enum.Font.GothamBlack
			tl.TextScaled = true
			tl.TextColor3 = Color3.fromRGB(255, 195, 110)
			tl.TextStrokeTransparency = 0.2
			tl.Text = tostring(label)
			tl.Parent = bill
		end
	end

	Debris:AddItem(m, dur + 0.35)
	task.delay(dur, function()
		if m.Parent then
			m:Destroy()
		end
		if onDetonate then
			pcall(onDetonate)
		end
	end)
	return m
end

local function fireTelegraphAttack(e, centerPos, radius, windup, dmg, label, style, dirVec, col)
	local dur = math.clamp(tonumber(windup) or 1.25, 1.1, 1.6)
	local look = (typeof(dirVec) == "Vector3" and dirVec.Magnitude > 0.05) and Vector3.new(dirVec.X, 0, dirVec.Z).Unit or Vector3.new(0, 0, -1)
	spawn3DTelegraphZone(centerPos, radius, dur, label, function()
		if not e or not e.Alive or not e.Model or not e.Model.Parent or os.clock() < (e.StunnedUntil or 0) then
			return
		end
		for _, plr in ipairs(Players:GetPlayers()) do
			local pr = root(plr)
			if pr then
				if style == "Laser" or style == "Line" then
					local length = radius * 2.4
					local halfW = math.max(5.5, radius * 0.55) * 0.5 + 1.5
					local rel = Vector3.new(pr.Position.X - centerPos.X, 0, pr.Position.Z - centerPos.Z)
					local fwd = rel:Dot(look)
					local lat = (rel - look * fwd).Magnitude
					if fwd >= -1.5 and fwd <= length + 1.5 and lat <= halfW and math.abs(pr.Position.Y - centerPos.Y) <= 18 then
						G.PlayerDamage(plr, dmg, e)
					end
				else
					if flatDist(pr.Position, centerPos) <= radius and math.abs(pr.Position.Y - centerPos.Y) <= 18 then
						G.PlayerDamage(plr, dmg, e)
					end
				end
			end
		end
	end, style, look, col)
end

local function notifyNearbyPlayers(pos, range, msg)
	for _, plr in ipairs(Players:GetPlayers()) do
		local pr = root(plr)
		if pr and dist(pr.Position, pos) <= range then
			G.Notify(plr, msg)
		end
	end
end

local function triggerBossKneelBreak(e, durationSec, msg)
	if not e or not e.Alive then
		return
	end
	local now = os.clock()
	local dur = durationSec or 4.5
	e.Shield = false
	e.SolarAegis70 = false
	e.CryonShieldActive = false
	e.NoxarDomainShield = false
	e.Break = 0
	e.StunnedUntil = now + dur
	e.ImmuneUntil = now + dur + 6.0
	if e.Model then
		e.Model:SetAttribute("Shielded", false)
		e.Model:SetAttribute("BossBroken", true)
		task.delay(dur, function()
			if e.Model and e.Model.Parent then
				e.Model:SetAttribute("BossBroken", false)
			end
		end)
	end
	if W and W.UpdateEnemyBar then
		W.UpdateEnemyBar(e)
	end
	if msg and e.Body then
		notifyNearbyPlayers(e.Body.Position, 125, msg)
	end
end

-- ============================================================================
-- 2. #71 - AUREON SENTINEL TWIN SOLAR PYLONS (< 60% HP)
-- ============================================================================
local function spawnAureonTwinSolarPylons(e)
	if e.TwinSolarPylonsSpawned or not e.Body then
		return
	end
	e.TwinSolarPylonsSpawned = true
	e.SolarAegis70 = true
	e.Shield = true
	if e.Model then
		e.Model:SetAttribute("Shielded", true)
	end

	-- Remove any legacy untethered EnergyPylons owned by Aureon so exactly Twin SolarPylon_L & R exist
	for _, old in ipairs(G.Enemies) do
		if old.Id == "EnergyPylon" and old.BossOwner == e and not old.IsTwinSolarPylon and old.Alive then
			old.Alive = false
			if old.Model and old.Model.Parent then
				old.Model:Destroy()
			end
		end
	end

	local center = e.Home or e.Body.Position
	local specs = {
		{ Name = "SolarPylon_L", Offset = Vector3.new(-20, 0, 6) },
		{ Name = "SolarPylon_R", Offset = Vector3.new(20, 0, 6) },
	}
	e.TwinPylons = {}
	for _, sp in ipairs(specs) do
		local ppos = center + sp.Offset
		local fy = safeFloorY(ppos, center.Y - 2.5)
		local pylon = G.SpawnEnemy("EnergyPylon", Vector3.new(ppos.X, fy + 4.5, ppos.Z), false, true)
		if pylon and pylon.Model and pylon.Body then
			pylon.Model.Name = sp.Name
			pylon.IsTwinSolarPylon = true
			pylon.BossOwner = e
			pylon.MaxHP = math.max(2400, math.floor(e.MaxHP * 0.16))
			pylon.HP = pylon.MaxHP
			pylon.Body.Color = Color3.fromRGB(255, 212, 82)
			pylon.Body.Transparency = 0.25

			local att0 = Instance.new("Attachment")
			att0.Name = "SolarTetherAtt0"
			att0.Position = Vector3.new(0, 3.0, 0)
			att0.Parent = pylon.Body

			local att1 = Instance.new("Attachment")
			att1.Name = "SolarTetherAtt1_" .. sp.Name
			att1.Position = Vector3.new(0, 2.5, 0)
			att1.Parent = e.Body

			local beam = Instance.new("Beam")
			beam.Name = "SolarTetherBeam"
			beam.Attachment0 = att0
			beam.Attachment1 = att1
			beam.Width0 = 0.85
			beam.Width1 = 1.15
			beam.FaceCamera = true
			beam.LightEmission = 0.7
			beam.Color = ColorSequence.new(Color3.fromRGB(255, 224, 108), Color3.fromRGB(255, 168, 52))
			beam.Transparency = NumberSequence.new(0.35)
			beam.Parent = pylon.Model

			table.insert(e.TwinPylons, pylon)
		end
	end
	notifyNearbyPlayers(e.Body.Position, 120, "[BOSS] AUREON SENTINEL kích hoạt Khiên Thái Dương (Giảm 70% Sát Thương)! Phá hủy 2 Trụ Thái Dương để gây BREAK 100%!")
end

-- ============================================================================
-- 3. #72 - CRYON PRIME 3D CRYONPILLAR RESONANCE ARENA FREEZE (18s)
-- ============================================================================
local function spawnCryonResonancePillars(e, waveTag)
	if not e.Body then
		return
	end
	e.CryonShieldActive = true
	e.Shield = true
	e.CryonFreezeDeadline = os.clock() + 18.0
	e.NextCryonChillAt = os.clock() + 1.0
	if e.Model then
		e.Model:SetAttribute("Shielded", true)
	end

	-- Clear any leftover pillars before spawning the 3 resonance pillars
	for _, old in ipairs(G.Enemies) do
		if old.Id == "CryonPillar" and old.BossOwner == e and old.Alive then
			old.Alive = false
			if old.Model and old.Model.Parent then
				old.Model:Destroy()
			end
		end
	end

	local center = e.Home or e.Body.Position
	e.ActiveCryonPillars = {}
	for idx = 1, 3 do
		local ang = (idx - 1) * (math.pi * 2 / 3)
		local ppos = center + Vector3.new(math.cos(ang) * 18, 0, math.sin(ang) * 18)
		local fy = safeFloorY(ppos, center.Y - 2.5)
		local pil = G.SpawnEnemy("CryonPillar", Vector3.new(ppos.X, fy + 4.5, ppos.Z), false, true)
		if pil and pil.Model and pil.Body then
			pil.Model:SetAttribute("VisualAsset", "CryonPillar")
			pil.BossOwner = e
			pil.IsCryonResonance = true
			pil.MaxHP = math.max(3200, math.floor(e.MaxHP * 0.12))
			pil.HP = pil.MaxHP

			local frostRing = Instance.new("Part")
			frostRing.Name = "ResonanceFrostRing"
			frostRing.Shape = Enum.PartType.Cylinder
			frostRing.Size = Vector3.new(0.22, 22, 22)
			frostRing.CFrame = CFrame.new(ppos.X, fy + 0.48, ppos.Z) * CFrame.Angles(0, 0, math.pi / 2)
			frostRing.Color = Color3.fromRGB(92, 232, 255)
			frostRing.Material = Enum.Material.Neon
			frostRing.Transparency = 0.48
			frostRing.Anchored, frostRing.CanCollide, frostRing.CanQuery, frostRing.CanTouch = true, false, false, false
			frostRing.Parent = pil.Model

			table.insert(e.ActiveCryonPillars, pil)
		end
	end
	notifyNearbyPlayers(e.Body.Position, 120, "[BOSS] CRYON PRIME (" .. tostring(waveTag or "Phase 2") .. ") triệu hồi 3 Cột Băng Vĩnh Cửu! Phá hủy trong 18 giây trước khi Đóng Băng Tuyệt Đối!")
end

-- ============================================================================
-- 4. #73 - NOXAR VOID DOMAIN & 4 PURIFYING LIGHT PILLARS
-- ============================================================================
local function spawnNoxarDomainAndLightPillars(e)
	if not e.Body then
		return
	end
	e.NoxarDomainActive = true
	e.NoxarDomainShield = true
	e.Shield = true
	e.NextVoidDomainTick = os.clock() + 1.5
	if e.Model then
		e.Model:SetAttribute("Shielded", true)
	end

	local center = e.Home or e.Body.Position
	local fy = safeFloorY(center, center.Y - 2.5)
	local voidCore = G.SpawnEnemy("NoxarVoidFX", Vector3.new(center.X, fy + 4.0, center.Z + 10), false, true)
	if voidCore and voidCore.Model then
		voidCore.Model:SetAttribute("VisualAsset", "NoxarVoidFX")
		voidCore.BossOwner = e
		voidCore.MaxHP = math.max(6000, math.floor(e.MaxHP * 0.15))
		voidCore.HP = voidCore.MaxHP
		e.ActiveVoidCore = voidCore
	end

	if e.LightPillarModels then
		for _, lm in ipairs(e.LightPillarModels) do
			if lm and lm.Parent then
				lm:Destroy()
			end
		end
	end
	e.LightPillarModels = {}

	local worldObjects = getWorldObjects()
	local offsets = {
		Vector3.new(-22, 0, -18),
		Vector3.new(22, 0, -18),
		Vector3.new(-22, 0, 18),
		Vector3.new(22, 0, 18),
	}
	for idx, off in ipairs(offsets) do
		local lpos = center + off
		local lfy = safeFloorY(lpos, fy)
		local pm = Instance.new("Model")
		pm.Name = "PurifyingLightPillar_" .. idx
		pm.Parent = worldObjects

		local base = W.Part(pm, "BasePedestal", Vector3.new(3.6, 1.2, 3.6), Vector3.new(lpos.X, lfy + 0.6, lpos.Z), Color3.fromRGB(228, 222, 206), Enum.Material.Marble)
		local shaft = W.Part(pm, "LightShaft", Vector3.new(1.8, 7.2, 1.8), Vector3.new(lpos.X, lfy + 4.4, lpos.Z), Color3.fromRGB(255, 228, 128), Enum.Material.Neon)
		shaft.Transparency = 0.35
		shaft.CanCollide = false
		pm.PrimaryPart = base

		local bill = Instance.new("BillboardGui")
		bill.Size = UDim2.fromScale(3.6, 0.7)
		bill.StudsOffset = Vector3.new(0, 5.2, 0)
		bill.AlwaysOnTop = false
		bill.MaxDistance = 58
		bill.Parent = shaft
		local tl = Instance.new("TextLabel")
		tl.Size = UDim2.fromScale(1, 1)
		tl.BackgroundTransparency = 1
		tl.Font = Enum.Font.GothamBlack
		tl.TextScaled = true
		tl.TextColor3 = Color3.fromRGB(255, 234, 138)
		tl.TextStrokeTransparency = 0.2
		tl.Text = "TRỤ ÁNH SÁNG THANH TẨY [E]"
		tl.Parent = bill

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Thanh Tẩy Ánh Sáng (Xóa Void DoT)"
		prompt.ObjectText = "Purifying Light Pillar #" .. idx
		prompt.MaxActivationDistance = 14
		prompt.HoldDuration = 0
		prompt.RequiresLineOfSight = false
		prompt.Parent = base

		local cooldownUntil = 0
		prompt.Triggered:Connect(function(plr)
			local now = os.clock()
			if now < cooldownUntil then
				G.Notify(plr, "Trụ Ánh Sáng đang tích tụ năng lượng (" .. math.ceil(cooldownUntil - now) .. "s)!")
				return
			end
			cooldownUntil = now + 10
			local sanctCenter = Vector3.new(lpos.X, lfy + 0.48, lpos.Z)
			local sanct = Instance.new("Part")
			sanct.Name = "PurifyingSanctuaryAura"
			sanct.Shape = Enum.PartType.Cylinder
			sanct.Size = Vector3.new(0.28, 28, 28)
			sanct.CFrame = CFrame.new(sanctCenter) * CFrame.Angles(0, 0, math.pi / 2)
			sanct.Color = Color3.fromRGB(255, 232, 130)
			sanct.Material = Enum.Material.Neon
			sanct.Transparency = 0.52
			sanct.Anchored, sanct.CanCollide, sanct.CanQuery, sanct.CanTouch = true, false, false, false
			sanct.Parent = getTempFX()
			Debris:AddItem(sanct, 12.2)

			table.insert(ActivePurifyingZones, {
				Pos = sanctCenter,
				Radius = 14,
				ExpiresAt = now + 12.0,
				Model = sanct,
			})

			for _, ally in ipairs(Players:GetPlayers()) do
				local ar = root(ally)
				local art = G.Runtime[ally]
				if ar and dist(ar.Position, sanctCenter) <= 36 then
					ally:SetAttribute("VoidDoTStacks", 0)
					if art then
						art.VoidDoTStacks = 0
					end
					G.Notify(ally, "ÁNH SÁNG THANH TẨY: Đã xóa toàn bộ Void DoT & mở Vùng Thánh Địa An Toàn (14m, 12s)!")
				end
			end

			if e.ActiveVoidCore and e.ActiveVoidCore.Alive then
				e.ActiveVoidCore.HP = math.max(0, e.ActiveVoidCore.HP - math.floor(e.ActiveVoidCore.MaxHP * 0.36))
				if W and W.UpdateEnemyBar then
					W.UpdateEnemyBar(e.ActiveVoidCore)
				end
				if e.ActiveVoidCore.HP <= 0 then
					G.Kill(e.ActiveVoidCore)
				end
			end
		end)

		table.insert(e.LightPillarModels, pm)
	end

	notifyNearbyPlayers(e.Body.Position, 125, "[BOSS] NOXAR mở Lãnh Địa Hư Không (NoxarVoidFX)! Bấm [E] tại 4 Trụ Ánh Sáng Thanh Tẩy để xóa độc Hư Không & tạo Vùng An Toàn!")
end

-- ============================================================================
-- 5. #74 - SOULREAPERRIFT 3-TORCH SUMMON RITUAL AT CASTLE ON THE VOID
-- ============================================================================
local function buildSoulReaperRitualSet()
	local worldObjects = getWorldObjects()
	local existing = worldObjects:FindFirstChild("SoulReaperRitual_CastleVoid")
	if existing then
		existing:Destroy()
	end

	local rootModel = Instance.new("Model")
	rootModel.Name = "SoulReaperRitual_CastleVoid"
	rootModel.Parent = worldObjects

	local altarRaw = Vector3.new(-14600, 46.9, 2138)
	local altarFY = safeFloorY(altarRaw, 46.9)
	local altarPos = Vector3.new(altarRaw.X, altarFY, altarRaw.Z)

	local altarBase = W.Part(rootModel, "SoulAltar", Vector3.new(6.8, 2.2, 6.8), altarPos + Vector3.new(0, 1.1, 0), Color3.fromRGB(42, 30, 62), Enum.Material.Slate)
	local altarRune = W.Part(rootModel, "SoulAltarRune", Vector3.new(5.2, 0.3, 5.2), altarPos + Vector3.new(0, 2.3, 0), Color3.fromRGB(198, 92, 255), Enum.Material.Neon)
	altarRune.Transparency = 0.42
	altarRune.CanCollide = false
	rootModel.PrimaryPart = altarBase

	local aBill = Instance.new("BillboardGui")
	aBill.Size = UDim2.fromScale(4.6, 0.85)
	aBill.StudsOffset = Vector3.new(0, 4.6, 0)
	aBill.AlwaysOnTop = false
	aBill.MaxDistance = 64
	aBill.Parent = altarBase
	local aLbl = Instance.new("TextLabel")
	aLbl.Size = UDim2.fromScale(1, 1)
	aLbl.BackgroundTransparency = 1
	aLbl.Font = Enum.Font.GothamBlack
	aLbl.TextScaled = true
	aLbl.TextColor3 = Color3.fromRGB(220, 130, 255)
	aLbl.TextStrokeTransparency = 0.18
	aLbl.Text = "TẾ ĐÀN SOUL REAPER [0/3 ĐUỐC]"
	aLbl.Parent = aBill

	local torchOffsets = {
		Vector3.new(-15, 0, 8),
		Vector3.new(15, 0, 8),
		Vector3.new(0, 0, -14),
	}

	SoulRitualState.Torches = { false, false, false }
	SoulRitualState.Flames = {}

	local function refreshRitualUI()
		local litCount = 0
		for i = 1, 3 do
			if SoulRitualState.Torches[i] then
				litCount += 1
			end
			local fl = SoulRitualState.Flames[i]
			if fl and fl.Parent then
				fl.Transparency = SoulRitualState.Torches[i] and 0.35 or 0.92
				local pl = fl:FindFirstChildOfClass("PointLight")
				if pl then
					pl.Enabled = SoulRitualState.Torches[i]
				end
			end
		end
		if SoulRitualState.Boss and SoulRitualState.Boss.Alive and SoulRitualState.Boss.Model and SoulRitualState.Boss.Model.Parent then
			aLbl.Text = "SOUL REAPER RIFT ĐANG HIỆN THẾ!"
		else
			aLbl.Text = string.format("TẾ ĐÀN SOUL REAPER [%d/3 ĐUỐC]", litCount)
		end
		return litCount
	end

	for idx, off in ipairs(torchOffsets) do
		local tRaw = altarPos + off
		local tFY = safeFloorY(tRaw, altarFY)
		local tm = Instance.new("Model")
		tm.Name = "SoulTorch_" .. idx
		tm.Parent = rootModel

		local pedestal = W.Part(tm, "BrazierPedestal", Vector3.new(2.8, 3.8, 2.8), Vector3.new(tRaw.X, tFY + 1.9, tRaw.Z), Color3.fromRGB(52, 38, 76), Enum.Material.Slate)
		local rim = W.Part(tm, "BrazierRim", Vector3.new(3.4, 0.6, 3.4), Vector3.new(tRaw.X, tFY + 3.9, tRaw.Z), Color3.fromRGB(218, 175, 76), Enum.Material.Metal)
		local flame = W.Part(tm, "SoulFlame", Vector3.new(2.0, 2.8, 2.0), Vector3.new(tRaw.X, tFY + 5.2, tRaw.Z), Color3.fromRGB(195, 78, 255), Enum.Material.Neon)
		flame.Shape = Enum.PartType.Ball
		flame.Transparency = 0.92
		flame.CanCollide = false
		local pl = Instance.new("PointLight")
		pl.Color = Color3.fromRGB(205, 95, 255)
		pl.Range = 16
		pl.Brightness = 1.40
		pl.Enabled = false
		pl.Parent = flame
		SoulRitualState.Flames[idx] = flame

		local tBill = Instance.new("BillboardGui")
		tBill.Size = UDim2.fromScale(3.2, 0.62)
		tBill.StudsOffset = Vector3.new(0, 4.5, 0)
		tBill.AlwaysOnTop = false
		tBill.MaxDistance = 48
		tBill.Parent = pedestal
		local tLbl = Instance.new("TextLabel")
		tLbl.Size = UDim2.fromScale(1, 1)
		tLbl.BackgroundTransparency = 1
		tLbl.Font = Enum.Font.GothamBold
		tLbl.TextScaled = true
		tLbl.TextColor3 = Color3.fromRGB(224, 145, 255)
		tLbl.TextStrokeTransparency = 0.2
		tLbl.Text = "ĐUỐC LINH HỒN #" .. idx
		tLbl.Parent = tBill

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Thắp Đuốc Linh Hồn #" .. idx
		prompt.ObjectText = "Soul Torch #" .. idx .. " • Castle on the Void"
		prompt.MaxActivationDistance = 14
		prompt.HoldDuration = 0
		prompt.RequiresLineOfSight = false
		prompt.Parent = pedestal

		prompt.Triggered:Connect(function(plr)
			if SoulRitualState.Boss and (not SoulRitualState.Boss.Alive or not SoulRitualState.Boss.Model or not SoulRitualState.Boss.Model.Parent) then
				SoulRitualState.Boss = nil
				SoulRitualState.Torches = { false, false, false }
			end
			if SoulRitualState.Boss and SoulRitualState.Boss.Alive then
				G.Notify(plr, "Raid Boss Soul Reaper Rift đang ở ngay tại Tế Đàn!")
				return
			end
			if os.clock() < (SoulRitualState.ResetAt or 0) then
				G.Notify(plr, "Tế Đàn Hư Không đang hội tụ năng lượng (" .. math.ceil(SoulRitualState.ResetAt - os.clock()) .. "s)!")
				return
			end
			if SoulRitualState.Torches[idx] then
				G.Notify(plr, "Ngọn Đuốc Linh Hồn #" .. idx .. " đã được thắp sáng!")
				return
			end
			SoulRitualState.Torches[idx] = true
			local lit = refreshRitualUI()
			G.Notify(plr, string.format("Đã thắp sáng Đuốc Linh Hồn #%d (%d/3)!", idx, lit))

			if lit >= 3 then
				local rift = Instance.new("Part")
				rift.Name = "SoulReaperVoidRift"
				rift.Shape = Enum.PartType.Cylinder
				rift.Size = Vector3.new(0.45, 18, 18)
				rift.CFrame = CFrame.new(altarPos + Vector3.new(0, 9.5, -2)) * CFrame.Angles(0, math.pi / 2, 0)
				rift.Color = Color3.fromRGB(188, 68, 255)
				rift.Material = Enum.Material.Neon
				rift.Transparency = 0.42
				rift.Anchored, rift.CanCollide, rift.CanQuery, rift.CanTouch = true, false, false, false
				rift.Parent = getTempFX()
				Debris:AddItem(rift, 18)

				local boss = G.SpawnEnemy("SoulReaperRift", altarPos + Vector3.new(0, 3.0, -3), true, true)
				if boss and boss.Model then
					boss.Model:SetAttribute("VisualAsset", "SoulReaperRift")
					boss.IsRitualBoss = true
					SoulRitualState.Boss = boss
				end
				refreshRitualUI()
				broadcastWorldBanner(
					"NGHI THỨC HƯ KHÔNG HOÀN TẤT",
					plr.Name .. " đã thắp sáng 3 Đuốc Linh Hồn và triệu hồi Raid Boss Lv.2050 SOUL REAPER RIFT tại Castle on the Void!",
					"Boss"
				)
			end
		end)
	end

	local altarPrompt = Instance.new("ProximityPrompt")
	altarPrompt.ActionText = "Xem Trạng Thái Tế Đàn Soul Reaper"
	altarPrompt.ObjectText = "Soul Altar • Castle on the Void"
	altarPrompt.MaxActivationDistance = 14
	altarPrompt.HoldDuration = 0
	altarPrompt.RequiresLineOfSight = false
	altarPrompt.Parent = altarBase
	altarPrompt.Triggered:Connect(function(plr)
		local lit = refreshRitualUI()
		G.Notify(plr, string.format("Tế Đàn Hư Không: %d/3 Đuốc Linh Hồn đã thắp. Hãy thắp đủ 3 ngọn đuốc quanh Tế Đàn để triệu hồi Lv.2050 Soul Reaper Rift!", lit))
	end)

	SoulRitualState.RefreshUI = refreshRitualUI
end

-- ============================================================================
-- 6. #19 - 3-ROLE REGULAR ENEMY AI DIFFERENTIATION + SMOOTH REGEN LEASH (>95m)
-- ============================================================================
local function getRegularArchetype(e)
	if e.Archetype then
		return e.Archetype
	end
	local arch = "MeleeRusher"
	if RANGED_SNIPER_IDS[e.Id] or (e.Config and e.Config.Ranged) then
		arch = "RangedSniper"
	elseif SHIELD_VANGUARD_IDS[e.Id] then
		arch = "ShieldVanguard"
	end
	e.Archetype = arch
	if e.Model then
		e.Model:SetAttribute("EnemyArchetype", arch)
	end
	return arch
end

local function moveEnemySmooth(e, goalPos, speed, dt)
	if not e.Body or not e.Model then
		return
	end
	local cur = e.Body.Position
	local delta = Vector3.new(goalPos.X - cur.X, 0, goalPos.Z - cur.Z)
	if delta.Magnitude < 0.25 then
		e.Model:SetAttribute("EnemyMoving", false)
		return
	end
	local dir = delta.Unit
	local step = dir * math.min(delta.Magnitude, speed * dt)
	local raw = cur + step
	local refY = e.HomeFloorY or (e.Home.Y - math.max(2.2, e.Body.Size.Y * 0.5))
	local fy = safeFloorY(raw, refY)
	fy = math.clamp(fy, refY - 6.0, refY + 6.0)
	local nextPos = Vector3.new(raw.X, fy + math.max(2.2, e.Body.Size.Y * 0.5), raw.Z)
	e.Model:PivotTo(CFrame.lookAt(nextPos, nextPos + dir))
	e.Model:SetAttribute("EnemyFloorY", fy)
	e.Model:SetAttribute("EnemyMoving", true)
end

local function tickRegularArchetypeAndLeash(e, dt)
	if not e.Alive or not e.Body or not e.Model then
		return false
	end
	if e.IsDPSDummy or e.Id == "EnergyPylon" or e.Id == "CryonPillar" or e.Id == "NoxarVoidFX" then
		return true
	end
	if isBossEnemy(e) then
		return false
	end

	local now = os.clock()
	if now < (e.StunnedUntil or 0) then
		e.Model:SetAttribute("EnemyMoving", false)
		return true
	end

	-- Smooth regen leash back to e.Home if pulled > 95 studs
	if e.Config and (tonumber(e.Config.Leash) or 0) < 95 then
		e.Config = table.clone(e.Config)
		e.Config.Leash = 95
	end
	local homeDist = flatDist(e.Body.Position, e.Home)
	if homeDist > 95 then
		e.SmoothLeashing = true
		e.Returning = false
		e.Model:SetAttribute("Leashing", true)
	end
	if e.SmoothLeashing then
		e.HP = math.min(e.MaxHP, e.HP + e.MaxHP * 0.22 * dt)
		if W and W.UpdateEnemyBar then
			W.UpdateEnemyBar(e)
		end
		moveEnemySmooth(e, e.Home, 26, dt)
		if flatDist(e.Body.Position, e.Home) <= 3.5 then
			e.SmoothLeashing = false
			e.Returning = false
			e.HP = e.MaxHP
			e.Contributors = {}
			e.Model:SetAttribute("Leashing", false)
			e.Model:SetAttribute("EnemyMoving", false)
			if W and W.UpdateEnemyBar then
				W.UpdateEnemyBar(e)
			end
		end
		return true
	end

	local arch = getRegularArchetype(e)

	-- Find nearest aggro target (prefer Kairo companion taunt position/owner when Kairo taunted!)
	local aggroRadius = math.max(38, tonumber(e.Config and e.Config.Aggro) or 38)
	local bestPlr, bestPos, bestD = nil, nil, aggroRadius
	for _, plr in ipairs(Players:GetPlayers()) do
		local pr = root(plr)
		if pr and flatDist(pr.Position, e.Home) < 95 then
			local d = dist(pr.Position, e.Body.Position)
			if d < bestD then
				bestD = d
				bestPlr = plr
				bestPos = pr.Position
			end
		end
	end
	if not bestPlr or not bestPos then
		return false
	end

	if arch == "RangedSniper" then
		-- Maintain 22-34 stud spacing + thin red aim-laser Part telegraph before firing
		if bestD < 17 and now >= (e.RecoverUntil or 0) then
			local away = Vector3.new(e.Body.Position.X - bestPos.X, 0, e.Body.Position.Z - bestPos.Z)
			local dir = away.Magnitude > 0.1 and away.Unit or Vector3.new(0, 0, 1)
			local retreatGoal = e.Body.Position + dir * 8
			if flatDist(retreatGoal, e.Home) < 88 then
				moveEnemySmooth(e, retreatGoal, (e.Config.Speed or 14) * 0.95, dt)
				return true
			end
		elseif bestD > 34 and now >= (e.RecoverUntil or 0) then
			moveEnemySmooth(e, bestPos, e.Config.Speed or 14, dt)
			return true
		end

		e.Model:SetAttribute("EnemyMoving", false)
		local look = Vector3.new(bestPos.X - e.Body.Position.X, 0, bestPos.Z - e.Body.Position.Z)
		if look.Magnitude > 0.1 then
			e.Model:PivotTo(CFrame.lookAt(e.Body.Position, e.Body.Position + look.Unit))
		end

		if now >= (e.NextSniperShot or 0) then
			e.NextSniperShot = now + 2.8
			e.NextAttack = now + 2.8
			e.RecoverUntil = now + 1.15

			local startP = e.Body.Position + Vector3.new(0, 0.9, 0)
			local targetSnap = bestPos + Vector3.new(0, 0.5, 0)
			local beamVec = targetSnap - startP
			local beamLen = math.max(2, beamVec.Magnitude)
			local laser = Instance.new("Part")
			laser.Name = "SniperAimLaser"
			laser.Size = Vector3.new(0.18, 0.18, beamLen)
			laser.CFrame = CFrame.lookAt(startP + beamVec * 0.5, targetSnap)
			laser.Color = Color3.fromRGB(255, 48, 68)
			laser.Material = Enum.Material.Neon
			laser.Transparency = 0.38
			laser.Anchored, laser.CanCollide, laser.CanQuery, laser.CanTouch, laser.CastShadow = true, false, false, false, false
			laser.Parent = getTempFX()
			Debris:AddItem(laser, 0.88)

			e.Model:SetAttribute("EnemyAttackClip", "Attack")
			e.Model:SetAttribute("EnemyAttackDuration", 0.95)
			e.Model:SetAttribute("EnemyAttackAt", workspace:GetServerTimeNow())

			task.delay(0.85, function()
				if laser.Parent then
					laser:Destroy()
				end
				if not e.Alive or not e.Body or os.clock() < (e.StunnedUntil or 0) then
					return
				end
				local pr = root(bestPlr)
				if pr and dist(pr.Position, targetSnap) <= 7.5 then
					G.PlayerDamage(bestPlr, math.floor((e.Config.ATK or 20) * 1.18), e)
				end
			end)
		end
		return true
	elseif arch == "ShieldVanguard" then
		if now >= (e.NextGuardCycle or 0) then
			e.NextGuardCycle = now + 6.5
			e.FrontalGuardUntil = now + 3.8
			e.Model:SetAttribute("FrontalGuard", true)
			if not e.GuardShieldPart or not e.GuardShieldPart.Parent then
				local sp = Instance.new("Part")
				sp.Name = "VanguardDirectionalShield"
				sp.Size = Vector3.new(4.2, 4.6, 0.35)
				sp.Color = Color3.fromRGB(95, 224, 255)
				sp.Material = Enum.Material.Neon
				sp.Transparency = 0.48
				sp.CanCollide, sp.CanQuery, sp.CanTouch, sp.Massless = false, false, false, true
				sp.CFrame = e.Body.CFrame * CFrame.new(0, 0.2, -2.3)
				sp.Parent = e.Model
				local wc = Instance.new("WeldConstraint")
				wc.Part0 = e.Body
				wc.Part1 = sp
				wc.Parent = sp
				e.GuardShieldPart = sp
			end
			e.GuardShieldPart.Transparency = 0.48
		elseif e.FrontalGuardUntil and now >= e.FrontalGuardUntil and e.Model:GetAttribute("FrontalGuard") then
			e.Model:SetAttribute("FrontalGuard", false)
			if e.GuardShieldPart and e.GuardShieldPart.Parent then
				e.GuardShieldPart.Transparency = 1
			end
		end
		return false -- delegate chase & melee swing to base TickEnemy while directional shield is active
	else
		-- MeleeRusher flanking dash combo every 5.2s when 8..22 studs away
		if bestD >= 8 and bestD <= 22 and now >= (e.NextFlankRush or 0) then
			e.NextFlankRush = now + 5.2
			local toPlr = Vector3.new(bestPos.X - e.Body.Position.X, 0, bestPos.Z - e.Body.Position.Z)
			if toPlr.Magnitude > 0.5 then
				local fwd = toPlr.Unit
				local side = Vector3.new(-fwd.Z, 0, fwd.X) * ((math.random(0, 1) == 0) and 1 or -1)
				local flankGoal = bestPos - fwd * 3.5 + side * 3.2
				if flatDist(flankGoal, e.Home) < 88 then
					moveEnemySmooth(e, flankGoal, (e.Config.Speed or 15) * 2.4, math.min(0.25, dt * 3))
					e.Model:SetAttribute("EnemyAttackClip", "Heavy")
					e.Model:SetAttribute("EnemyAttackDuration", 0.85)
					e.Model:SetAttribute("EnemyAttackAt", workspace:GetServerTimeNow())
				end
			end
		end
		return false
	end
end

-- ============================================================================
-- 7. #20 - REAL COMBAT 3D AI COMPANIONS (KAIRO TANK, LUMEN HEALER, NYX ASSASSIN)
-- ============================================================================

local function reviveDownedPlayer(p, reviverName)
	local rt = G.Runtime[p]
	local r, h = root(p)
	local prof = D.Get(p)
	if not rt or not rt.IsDowned then
		return
	end
	rt.IsDowned = false
	rt.DownedUntil = 0
	p:SetAttribute("Downed", false)
	if rt.ReviveBeacon and rt.ReviveBeacon.Parent then
		rt.ReviveBeacon:Destroy()
	end
	rt.ReviveBeacon = nil
	if h then
		local restoreHP = math.max(50, math.floor(h.MaxHealth * 0.45))
		h.Health = math.max(h.Health, restoreHP)
		local baseSpd = (prof and C.Classes[prof.ClassId] and C.Classes[prof.ClassId].Speed) or 18
		h.WalkSpeed = baseSpd
	end
	rt.InvincibleUntil = os.clock() + 3.0
	if r then
		G.FireCombatEvent({
			kind = "DamageNumber",
			pos = r.Position + Vector3.new(0, 2.6, 0),
			amount = h and math.floor(h.MaxHealth * 0.45) or 450,
			crit = true,
			element = "Heal",
			Text = "HOI SINH 45% HP!",
		})
	end
	G.Notify(p, "CỨU VIỆN THÀNH CÔNG: [" .. tostring(reviverName or "Đồng Đội") .. "] đã cứu bạn dậy với 45% HP!")
end


-- ============================================================================
-- 8. #23 & #115 - DRIVABLE 3D BLENDER WARSHIPS + CREW SEATS + BROADSIDE CANNONS
-- ============================================================================
local function parseCrewColor3(str, fallback)
	if type(str) == "string" then
		local rStr, gStr, bStr = string.match(str, "(%d+)%s*,%s*(%d+)%s*,%s*(%d+)")
		if rStr and gStr and bStr then
			return Color3.fromRGB(math.clamp(tonumber(rStr) or 255, 0, 255), math.clamp(tonumber(gStr) or 210, 0, 255), math.clamp(tonumber(bStr) or 80, 0, 255))
		end
	end
	return fallback or Color3.fromRGB(255, 214, 92)
end

local function applyCrewBannerToShip(shipEntry, profile)
	if not shipEntry or not shipEntry.Model or not shipEntry.Model.Parent then
		return
	end
	local crewName = (profile and type(profile.CrewName) == "string" and profile.CrewName ~= "") and profile.CrewName or ""
	local crewTag = (profile and type(profile.CrewTag) == "string" and profile.CrewTag ~= "") and profile.CrewTag or ""
	local emblemCol = parseCrewColor3(profile and profile.CrewColor, shipEntry.Spec.Accent)

	shipEntry.Model:SetAttribute("CrewName", crewName)
	shipEntry.Model:SetAttribute("CrewTag", crewTag)
	shipEntry.Model:SetAttribute("CrewEmblemColor", emblemCol)

	if shipEntry.BannerLabel and shipEntry.BannerLabel.Parent then
		local ownerStr = shipEntry.Owner and shipEntry.Owner.Name or "Skyborn"
		if crewName ~= "" then
			local prefix = crewTag ~= "" and ("[" .. crewTag .. "] ") or ""
			shipEntry.BannerLabel.Text = prefix .. crewName .. " • " .. shipEntry.Spec.DisplayName
		else
			shipEntry.BannerLabel.Text = shipEntry.Spec.DisplayName .. " • [" .. ownerStr .. "]"
		end
		shipEntry.BannerLabel.TextColor3 = emblemCol
	end
	if shipEntry.SailEmblem and shipEntry.SailEmblem.Parent then
		shipEntry.SailEmblem.Color = emblemCol
	end
end

function WorldEvents.RefreshPlayerShipBanner(p)
	local entry = ActiveWarships[p]
	local prof = D.Get(p)
	if entry and prof then
		applyCrewBannerToShip(entry, prof)
	end
end

local function fireBroadsideCannon(p, shipEntry, side)
	if not shipEntry or not shipEntry.Model or not shipEntry.Model.Parent or not shipEntry.Hull then
		return
	end
	local now = os.clock()
	if now < (shipEntry.NextCannonAt or 0) then
		if p then
			G.Notify(p, string.format("Đại Bác Aether đang nạp năng lượng (%.1fs)!", shipEntry.NextCannonAt - now))
		end
		return
	end
	shipEntry.NextCannonAt = now + 1.45

	local hullCF = shipEntry.Hull.CFrame
	local sidesToFire = {}
	if side == "Port" then
		sidesToFire = { -1 }
	elseif side == "Starboard" then
		sidesToFire = { 1 }
	else
		sidesToFire = { -1, 1 }
	end

	local stats = p and G.Stats(p) or nil
	local baseDmg = shipEntry.Spec.CannonDamage or 3200
	local volleyDmg = math.clamp(math.max(baseDmg, math.floor(((stats and stats.ATK) or 100) * 4.2)), 2500, 6500)
	local col = shipEntry.Spec.Accent

	for _, sgn in ipairs(sidesToFire) do
		local muzzleCF = hullCF * CFrame.new(sgn * (shipEntry.Spec.HullSize.X * 0.55), 2.4, -2.0)
		local dir = (hullCF.RightVector * sgn + hullCF.LookVector * 0.18 - Vector3.new(0, 0.04, 0)).Unit
		local maxRange = 135
		local hitEnemy = nil
		local impactPos = muzzleCF.Position + dir * maxRange

		for _, e in ipairs(G.Enemies) do
			if e.Alive and e.Body and not e.IsDPSDummy then
				local toE = e.Body.Position - muzzleCF.Position
				local proj = toE:Dot(dir)
				if proj > 4 and proj <= maxRange then
					local perp = (toE - dir * proj).Magnitude
					if perp <= 22 then
						maxRange = proj
						impactPos = e.Body.Position
						hitEnemy = e
					end
				end
			end
		end

		local plasma = Instance.new("Part")
		plasma.Name = "BroadsidePlasmaOrb"
		plasma.Shape = Enum.PartType.Ball
		plasma.Size = Vector3.new(2.6, 2.6, 2.6)
		plasma.Position = muzzleCF.Position
		plasma.Color = col
		plasma.Material = Enum.Material.Neon
		plasma.Transparency = 0.35
		plasma.Anchored, plasma.CanCollide, plasma.CanQuery, plasma.CanTouch = true, false, false, false
		plasma.Parent = getTempFX()

		local travelT = math.clamp((impactPos - muzzleCF.Position).Magnitude / 240, 0.12, 0.52)
		TweenService:Create(plasma, TweenInfo.new(travelT, Enum.EasingStyle.Linear), { Position = impactPos }):Play()
		Debris:AddItem(plasma, travelT + 0.1)

		task.delay(travelT, function()
			local blast = Instance.new("Part")
			blast.Name = "CannonPlasmaBlast"
			blast.Shape = Enum.PartType.Ball
			blast.Size = Vector3.new(4, 4, 4)
			blast.Position = impactPos
			blast.Color = col
			blast.Material = Enum.Material.Neon
			blast.Transparency = 0.38
			blast.Anchored, blast.CanCollide, blast.CanQuery, blast.CanTouch = true, false, false, false
			blast.Parent = getTempFX()
			TweenService:Create(blast, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Size = Vector3.new(26, 26, 26),
				Transparency = 0.92,
			}):Play()
			Debris:AddItem(blast, 0.36)

			if R and R:FindFirstChild("CombatFX") then
				R.CombatFX:FireAllClients({
					Kind = "ShipCannonBlast",
					Position = impactPos,
					Actor = p and p.UserId or 0,
				})
			end

			local targets = {}
			for _, e in ipairs(G.Enemies) do
				if e.Alive and e.Body and not e.IsDPSDummy and dist(e.Body.Position, impactPos) <= 28 then
					table.insert(targets, e)
				end
			end
			if #targets == 0 and hitEnemy and hitEnemy.Alive and not hitEnemy.IsDPSDummy then
				table.insert(targets, hitEnemy)
			end
			if p then
				for _, e in ipairs(targets) do
					if e.Alive and e.Body then
						G.Hit(p, e, volleyDmg, 28, "Heavy")
						G.FireCombatEvent({
							kind = "DamageNumber",
							pos = e.Body.Position + Vector3.new(0, 3.6, 0),
							amount = volleyDmg,
							crit = true,
							breakDmg = 28,
							element = "Sky",
							Text = "CANNON!",
						})
					end
				end
			end
		end)
	end
end

local function findNearestPortForPos(pos)
	local best, bestD = HARBOR_PORTS[1], math.huge
	for _, port in ipairs(HARBOR_PORTS) do
		local d = dist(pos, port.PedestalPos)
		if d < bestD then
			bestD = d
			best = port
		end
	end
	return best, bestD
end

function WorldEvents.SpawnWarship(p, requestedShipId, customSpawnPos, autoBoard)
	local isPlr = typeof(p) == "Instance" and p:IsA("Player")
	local plr = isPlr and p or nil
	local prof = plr and D.Get(plr) or nil
	local r, h = plr and root(plr) or nil, nil
	if plr then
		r, h = root(plr)
	end

	local meshId = normalizeShipId(requestedShipId or (prof and prof.ActiveShip))
	if not requestedShipId and plr and not (prof and prof.ActiveShip and SHIP_SPECS[prof.ActiveShip]) then
		local realm = tostring(plr:GetAttribute("CurrentRealm") or "GoldenSky")
		if realm == "FrozenCyber" then
			meshId = "CyberEnforcerShip"
		elseif realm == "ShadowRealm" then
			meshId = "LeviathanHunterShip"
		end
	end

	local spec = SHIP_SPECS[meshId] or SHIP_SPECS.CelestialAetherGalleon
	if prof then
		prof.UnlockedShips = prof.UnlockedShips or {}
		prof.UnlockedShips[meshId] = true
		prof.ActiveShip = meshId
	end

	local spawnPos = customSpawnPos
	local spawnLook = Vector3.new(0, 0, 1)
	if not spawnPos then
		if r then
			local port, portDist = findNearestPortForPos(r.Position)
			if port and portDist <= 145 then
				spawnPos = port.WaterPos
				local away = Vector3.new(port.WaterPos.X - port.PedestalPos.X, 0, port.WaterPos.Z - port.PedestalPos.Z)
				if away.Magnitude > 0.5 then
					spawnLook = away.Unit
				end
			else
				spawnLook = Vector3.new(r.CFrame.LookVector.X, 0, r.CFrame.LookVector.Z)
				if spawnLook.Magnitude < 0.05 then
					spawnLook = Vector3.new(0, 0, -1)
				else
					spawnLook = spawnLook.Unit
				end
				spawnPos = Vector3.new(r.Position.X, math.max(28, r.Position.Y - 1.5), r.Position.Z) + spawnLook * 22
			end
		else
			spawnPos = HARBOR_PORTS[1].WaterPos
		end
	end

	if plr and ActiveWarships[plr] then
		local prev = ActiveWarships[plr]
		if prev.Model and prev.Model.Parent then
			prev.Model:Destroy()
		end
		ActiveWarships[plr] = nil
	end

	local shipsFolder = getActiveShipsFolder()
	local modelName = plr and ("Warship_" .. plr.Name) or ("Warship_" .. meshId)
	local old = shipsFolder:FindFirstChild(modelName)
	if old then
		old:Destroy()
	end

	local ship = Instance.new("Model")
	ship.Name = modelName
	ship:SetAttribute("ShipMeshId", spec.MeshId)
	ship:SetAttribute("ShipId", spec.MeshId)
	ship:SetAttribute("VisualAsset", spec.MeshId)
	ship:SetAttribute("NPCId", spec.MeshId)
	ship:SetAttribute("ShowcaseScale", 4.2)
	ship:SetAttribute("NPCFloorY", spawnPos.Y - 1.2)
	ship:SetAttribute("TowingLeviathanHeart", false)
	if plr then
		ship:SetAttribute("OwnerUserId", plr.UserId)
	end

	local baseCF = CFrame.lookAt(spawnPos, spawnPos + spawnLook)

	local hull = Instance.new("Part")
	hull.Name = "HullRoot"
	hull.Size = spec.HullSize
	hull.CFrame = baseCF
	hull.Color = spec.Accent
	hull.Material = Enum.Material.Metal
	hull.Transparency = 1
	hull.Anchored = true
	hull.CanCollide = true
	hull.CanQuery = true
	hull.CanTouch = false
	hull.TopSurface = Enum.SurfaceType.Smooth
	hull.Parent = ship
	ship.PrimaryPart = hull

	-- Also keep a thin welded "Body" alias part so any client watcher checking FindFirstChild("Body") sees it immediately!
	local bodyAlias = Instance.new("Part")
	bodyAlias.Name = "Body"
	bodyAlias.Size = Vector3.new(2, 2, 2)
	bodyAlias.CFrame = baseCF
	bodyAlias.Transparency = 1
	bodyAlias.Anchored = false
	bodyAlias.CanCollide, bodyAlias.CanQuery, bodyAlias.CanTouch, bodyAlias.Massless = false, false, false, true
	bodyAlias.Parent = ship
	local bw = Instance.new("WeldConstraint")
	bw.Part0 = hull
	bw.Part1 = bodyAlias
	bw.Parent = bodyAlias

	-- Real VehicleSeat (HelmSeat)
	local helm = Instance.new("VehicleSeat")
	helm.Name = "HelmSeat"
	helm.Size = Vector3.new(2.6, 1.2, 2.4)
	helm.CFrame = baseCF * CFrame.new(0, 1.85, 5.5)
	helm.MaxSpeed = spec.Speed
	helm.TurnSpeed = spec.TurnSpeed
	helm.Torque = 20
	helm.HeadsUpDisplay = false
	helm.Transparency = 0.65
	helm.Color = spec.Accent
	helm.Material = Enum.Material.Neon
	helm.Anchored = false
	helm.CanCollide = true
	helm.Massless = true
	helm.Parent = ship
	local hw = Instance.new("WeldConstraint")
	hw.Part0 = hull
	hw.Part1 = helm
	hw.Parent = helm

	local boardPrompt = Instance.new("ProximityPrompt")
	boardPrompt.ActionText = "Cầm Lái Chiến Hạm [WASD]"
	boardPrompt.ObjectText = spec.DisplayName
	boardPrompt.MaxActivationDistance = 22
	boardPrompt.HoldDuration = 0
	boardPrompt.RequiresLineOfSight = false
	boardPrompt.Parent = helm

	-- 2 Passenger CrewSeats (#115)
	local crewOffsets = {
		CFrame.new(-4.0, 1.85, 1.5),
		CFrame.new(4.0, 1.85, 1.5),
	}
	local crewSeats = {}
	for idx, coff in ipairs(crewOffsets) do
		local cs = Instance.new("Seat")
		cs.Name = "CrewSeat_" .. idx
		cs.Size = Vector3.new(2.2, 1.0, 2.2)
		cs.CFrame = baseCF * coff
		cs.Color = Color3.fromRGB(48, 56, 76)
		cs.Material = Enum.Material.Metal
		cs.Transparency = 0.65
		cs.Anchored = false
		cs.CanCollide = true
		cs.Massless = true
		cs.Parent = ship
		local cw = Instance.new("WeldConstraint")
		cw.Part0 = hull
		cw.Part1 = cs
		cw.Parent = cs
		table.insert(crewSeats, cs)
	end

	-- Crew Banner Emblem & Billboard
	local sailEmblem = Instance.new("Part")
	sailEmblem.Name = "CrewBannerEmblem"
	sailEmblem.Size = Vector3.new(5.2, 2.6, 0.25)
	sailEmblem.CFrame = baseCF * CFrame.new(0, 9.5, 2.0)
	sailEmblem.Color = spec.Accent
	sailEmblem.Material = Enum.Material.Neon
	sailEmblem.Transparency = 0.45
	sailEmblem.Anchored = false
	sailEmblem.CanCollide, sailEmblem.CanQuery, sailEmblem.CanTouch, sailEmblem.Massless = false, false, false, true
	sailEmblem.Parent = ship
	local sw = Instance.new("WeldConstraint")
	sw.Part0 = hull
	sw.Part1 = sailEmblem
	sw.Parent = sailEmblem

	local bill = Instance.new("BillboardGui")
	bill.Size = UDim2.fromScale(6.2, 1.1)
	bill.StudsOffset = Vector3.new(0, 13.5, 0)
	bill.AlwaysOnTop = false
	bill.MaxDistance = 120
	bill.Parent = hull
	local bLbl = Instance.new("TextLabel")
	bLbl.Size = UDim2.fromScale(1, 1)
	bLbl.BackgroundTransparency = 1
	bLbl.Font = Enum.Font.GothamBlack
	bLbl.TextScaled = true
	bLbl.TextColor3 = spec.Accent
	bLbl.TextStrokeTransparency = 0.18
	bLbl.Text = spec.DisplayName
	bLbl.Parent = bill

	-- Stern Harpoon Attachment for #75 Towing Leviathan Heart
	local sternAtt = Instance.new("Attachment")
	sternAtt.Name = "SternHarpoonAttachment"
	sternAtt.Position = Vector3.new(0, 2.0, spec.HullSize.Z * 0.48)
	sternAtt.Parent = hull

	local entry = {
		Owner = plr,
		ShipId = spec.MeshId,
		Spec = spec,
		Model = ship,
		Hull = hull,
		Helm = helm,
		CrewSeats = crewSeats,
		SailEmblem = sailEmblem,
		BannerLabel = bLbl,
		SternAtt = sternAtt,
		BaseY = spawnPos.Y,
		Yaw = math.atan2(-spawnLook.X, -spawnLook.Z),
		CurrentSpeed = 0,
		BankAngle = 0,
		BobTime = math.random() * 6.28,
		NextCannonAt = 0,
	}

	-- Port & Starboard Broadside Energy Cannons (#115)
	for _, cSpec in ipairs({
		{ Name = "BroadsideCannon_Port", Side = "Port", X = -(spec.HullSize.X * 0.46) },
		{ Name = "BroadsideCannon_Starboard", Side = "Starboard", X = (spec.HullSize.X * 0.46) },
	}) do
		local cannon = Instance.new("Part")
		cannon.Name = cSpec.Name
		cannon.Size = Vector3.new(2.2, 1.4, 1.6)
		cannon.CFrame = baseCF * CFrame.new(cSpec.X, 2.2, -2.0)
		cannon.Color = spec.Accent
		cannon.Material = Enum.Material.Metal
		cannon.Transparency = 0.42
		cannon.Anchored = false
		cannon.CanCollide = false
		cannon.Massless = true
		cannon.Parent = ship
		local cnw = Instance.new("WeldConstraint")
		cnw.Part0 = hull
		cnw.Part1 = cannon
		cnw.Parent = cannon

		local cPrompt = Instance.new("ProximityPrompt")
		cPrompt.ActionText = "Bắn Đại Bác Aether (" .. cSpec.Side .. ")"
		cPrompt.ObjectText = "Broadside Aether Cannon"
		cPrompt.MaxActivationDistance = 18
		cPrompt.HoldDuration = 0
		cPrompt.RequiresLineOfSight = false
		cPrompt.Parent = cannon
		cPrompt.Triggered:Connect(function(shooter)
			fireBroadsideCannon(shooter, entry, cSpec.Side)
		end)
	end

	boardPrompt.Triggered:Connect(function(rider)
		local _, rh = root(rider)
		if rh and not helm.Occupant then
			local rrt = G.Runtime[rider]
			if rrt then
				rrt.JumpPadUntil = math.max(rrt.JumpPadUntil or 0, os.clock() + 3.0)
			end
			helm:Sit(rh)
		end
	end)

	ship.Parent = shipsFolder
	applyCrewBannerToShip(entry, prof)

	if plr then
		ActiveWarships[plr] = entry
		if autoBoard and h then
			local rt = G.Runtime[plr]
			if rt then
				rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, os.clock() + 3.5)
				rt.Safe = helm.Position + Vector3.new(0, 2, 0)
				rt.MoveAt = os.clock()
			end
			task.defer(function()
				if helm.Parent and h.Parent and h.Health > 0 then
					helm:Sit(h)
				end
			end)
		end
		G.Notify(plr, "CHIẾN HẠM BAY 3D: Đã hạ thủy [" .. spec.DisplayName .. "]! Ngồi vào Ghế Lái [WASD] để lướt biển mây & bấm [E] khai hỏa Đại Bác Aether!")
	end

	return ship, entry
end

local function buildHarborShipwrights()
	local worldObjects = getWorldObjects()
	for _, port in ipairs(HARBOR_PORTS) do
		local pfy = safeFloorY(port.PedestalPos, port.PedestalPos.Y - 2.0)
		local npcPos = Vector3.new(port.PedestalPos.X, pfy + 2.3, port.PedestalPos.Z)

		local oldName = "SkyShipwright_" .. port.Id
		local old = worldObjects:FindFirstChild(oldName)
		if old then
			old:Destroy()
		end

		local m = Instance.new("Model")
		m.Name = oldName
		m.Parent = worldObjects

		local body = W.Part(m, "Body", Vector3.new(2.2, 4.6, 1.8), npcPos, Color3.fromRGB(95, 228, 255), Enum.Material.Metal)
		body.Transparency = 1
		body.CanCollide = false
		m.PrimaryPart = body
		m:SetAttribute("NPCId", "SkyShipwrightNPC")
		m:SetAttribute("VisualAsset", "SkyShipwrightNPC")
		m:SetAttribute("NPCFloorY", pfy)

		local pedestal = W.Part(m, "ShipSpawnerPedestal", Vector3.new(4.2, 1.1, 4.2), Vector3.new(npcPos.X - 3.6, pfy + 0.55, npcPos.Z), Color3.fromRGB(238, 192, 78), Enum.Material.Metal)
		local holoOrb = W.Part(m, "HoloShipCore", Vector3.new(1.8, 1.8, 1.8), Vector3.new(npcPos.X - 3.6, pfy + 2.2, npcPos.Z), Color3.fromRGB(88, 238, 255), Enum.Material.Neon)
		holoOrb.Shape = Enum.PartType.Ball
		holoOrb.Transparency = 0.42
		holoOrb.CanCollide = false

		local bill = Instance.new("BillboardGui")
		bill.Size = UDim2.fromScale(4.4, 0.82)
		bill.StudsOffset = Vector3.new(0, 4.9, 0)
		bill.AlwaysOnTop = false
		bill.MaxDistance = 54
		bill.Parent = body
		local tl = Instance.new("TextLabel")
		tl.Size = UDim2.fromScale(1, 1)
		tl.BackgroundTransparency = 1
		tl.Font = Enum.Font.GothamBlack
		tl.TextScaled = true
		tl.TextColor3 = Color3.fromRGB(110, 238, 255)
		tl.TextStrokeTransparency = 0.18
		tl.Text = "SKY SHIPWRIGHT • " .. string.upper(port.Name)
		tl.Parent = bill

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Mở Xưởng Chiến Hạm Bay 3D"
		prompt.ObjectText = "Sky Shipwright • " .. port.Name
		prompt.MaxActivationDistance = 16
		prompt.HoldDuration = 0
		prompt.RequiresLineOfSight = false
		prompt.Parent = pedestal
		prompt.Triggered:Connect(function(plr)
			G.SendDialogue(
				plr,
				"Thợ Đóng Tàu • Sky Shipwright",
				"XƯỞNG CHIẾN HẠM BAY 3D • " .. string.upper(port.Name),
				"Từ Thuyền Buồm Sky Sloop miễn phí đến Đại Chiến Hạm Aether Galleon và Thần Hạm Săn Leviathan gắn Lao Móc Thần — hãy chọn chiến hạm để hạ thủy!",
				"Mở Xưởng Chiến Hạm 3D",
				"OpenScreen:NPCShop:Shipwright"
			)
		end)
	end
end

local function tickActiveWarships(dt)
	local now = os.clock()
	for owner, entry in pairs(ActiveWarships) do
		local ship = entry.Model
		local hull = entry.Hull
		local helm = entry.Helm
		if not ship or not ship.Parent or not hull or not hull.Parent or not helm or not helm.Parent then
			ActiveWarships[owner] = nil
		else
			entry.BobTime = (entry.BobTime or 0) + dt * 1.6
			local throttle = math.clamp(helm.ThrottleFloat or 0, -1, 1)
			local steer = math.clamp(helm.SteerFloat or 0, -1, 1)
			local targetSpd = throttle * (entry.Spec.Speed or 65) * (throttle < 0 and 0.55 or 1.0)
			local accel = (math.abs(targetSpd) > math.abs(entry.CurrentSpeed)) and 42 or 54
			entry.CurrentSpeed += math.clamp(targetSpd - entry.CurrentSpeed, -accel * dt, accel * dt)

			if math.abs(entry.CurrentSpeed) > 0.25 or math.abs(steer) > 0.05 then
				local turnFactor = (entry.CurrentSpeed >= -1) and 1 or -1
				entry.Yaw = (entry.Yaw or 0) - steer * (entry.Spec.TurnSpeed or 1.4) * dt * turnFactor
			end
			local targetBank = -steer * math.clamp(math.abs(entry.CurrentSpeed) / 60, 0.25, 1.0) * 0.12
			entry.BankAngle = entry.BankAngle + (targetBank - entry.BankAngle) * math.min(1, dt * 6)
			local pitchAngle = math.clamp(entry.CurrentSpeed / 95, -0.05, 0.06)

			local rotCF = CFrame.Angles(0, entry.Yaw, 0) * CFrame.Angles(pitchAngle, 0, entry.BankAngle)
			local fwd = Vector3.new(rotCF.LookVector.X, 0, rotCF.LookVector.Z)
			if fwd.Magnitude > 0.01 then
				fwd = fwd.Unit
			else
				fwd = Vector3.new(0, 0, -1)
			end

			local nextPos = hull.Position + fwd * (entry.CurrentSpeed * dt)
			local bobY = (entry.BaseY or 35) + math.sin(entry.BobTime) * 0.35
			nextPos = Vector3.new(nextPos.X, bobY, nextPos.Z)

			-- Soft collision avoidance against island cliffs / Solid3DObstacles
			if W and W.IsBlockedByObstacle and math.abs(entry.CurrentSpeed) > 0.5 then
				local probe = nextPos + fwd * (entry.Spec.HullSize.Z * 0.52)
				if W.IsBlockedByObstacle(probe.X, probe.Y - 4, probe.Z, 5.0) then
					entry.CurrentSpeed = -entry.CurrentSpeed * 0.25
					nextPos = Vector3.new(hull.Position.X, bobY, hull.Position.Z)
				end
			end

			ship:PivotTo(CFrame.new(nextPos) * rotCF)
			ship:SetAttribute("NPCFloorY", bobY - 1.2)

			-- Refresh anti-cheat JumpPadUntil + SeatedInShip for pilot & crew!
			local seats = { helm, entry.CrewSeats[1], entry.CrewSeats[2] }
			for _, st in ipairs(seats) do
				local occ = st and st.Occupant
				if occ and occ.Parent then
					local occPlr = Players:GetPlayerFromCharacter(occ.Parent)
					if occPlr then
						local ort = G.Runtime[occPlr]
						local ohrp = occ.Parent:FindFirstChild("HumanoidRootPart")
						if ort and ohrp then
							ort.SeatedInShip = true
							ort.ActiveShipEntry = entry
							ort.JumpPadUntil = math.max(ort.JumpPadUntil or 0, now + 2.5)
							ort.Safe = ohrp.Position
							ort.MoveAt = now
						end
					end
				end
			end
		end
	end

	-- Clear SeatedInShip flag when player steps off seats
	for p, rt in pairs(G.Runtime) do
		if rt.SeatedInShip then
			local _, h = root(p)
			if not h or not h.SeatPart then
				rt.SeatedInShip = false
			end
		end
	end
end

-- ============================================================================
-- 9. #21, #75, #66 - CLOUD-SEA MONSTERS, DANGER LEVEL 1-6 & LEVIATHAN HEART TOW
-- ============================================================================
local function spawnLeviathanHeartRelic(deathPos, killerPlayer)
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
	tl.Text = "TIM THỦY TỔ LEVIATHAN [E]"
	tl.Parent = bill

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Gắn Dây Cáp Kéo Tim Leviathan"
	prompt.ObjectText = "Leviathan Heart • Thủy Tổ Hư Không"
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
			G.Notify(plr, "Tim Leviathan đã được móc cáp vào chiến hạm!")
			return
		end
		local shipEntry = ActiveWarships[plr]
		local pr = root(plr)
		if not shipEntry or not shipEntry.Model or not shipEntry.Model.Parent or (pr and dist(shipEntry.Hull.Position, core.Position) > 160) then
			local spawnAt = core.Position + Vector3.new(0, 0, 26)
			local _, newEntry = WorldEvents.SpawnWarship(plr, "LeviathanHunterShip", spawnAt, false)
			shipEntry = newEntry
		end
		if not shipEntry or not shipEntry.SternAtt then
			return
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
		G.Notify(plr, "ĐÃ MÓC CÁP HARPOON! Hãy lái Chiến Hạm kéo Tim Leviathan về bất kỳ Cảng Sky Shipwright / Sky Hub Port (trong 55m) để nhận thưởng Thủy Tổ!")
	end)

	if killerPlayer then
		G.Notify(killerPlayer, "TIM THỦY TỔ LEVIATHAN đã trồi lên biển mây! Hãy bấm [E] để gắn cáp Harpoon vào Chiến Hạm và kéo về Cảng!")
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
		he.Label.Text = "TIM THỦY TỔ LEVIATHAN [E]"
	end
end

local function tickLeviathanHearts(dt)
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
							G.Notify(owner, "GIAO TIM LEVIATHAN THÀNH CÔNG: +1 Leviathan Heart, +500 Core Shards, +35,000 Gold, Mở khóa Khiên Thủy Tổ & Danh hiệu [Thợ Săn Thủy Tổ Leviathan]!")
							G.Sync(owner)
							task.spawn(D.Save, owner, false)
						end
						broadcastWorldBanner(
							"TIM THỦY TỔ LEVIATHAN CẬP CẢNG!",
							owner.Name .. " đã kéo thành công Tim Thủy Tổ Leviathan về " .. port.Name .. "!",
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

function WorldEvents.SpawnSeaMonsterEvent(p, monsterId, customPos)
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
			"THỦY TỔ ABYSSAL LEVIATHAN TRỒI LÊN!",
			"Vùng Biển Mây Nguy Hiểm (Danger 6) rung chuyển — Abyssal Leviathan Lv.2350 đã xuất hiện!",
			"Leviathan"
		)
	elseif p then
		G.Notify(p, "SỰ KIỆN BIỂN MÂY: [" .. (C.Enemies[mId] and C.Enemies[mId].Name or mId) .. "] đã trồi lên từ biển mây!")
	end
	return mob
end

local function computePlayerDangerLevel(p, pos, rt)
	-- GlacialWreckageDangerSea (14600, 46.9, -1992.7) & LeviathanAbyss (-12000, 46.9, -3560)
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

local function tickSeaDangerAndDynamicEncounters()
	local now = os.clock()
	for p, rt in pairs(G.Runtime) do
		local r = root(p)
		if r then
			local danger = computePlayerDangerLevel(p, r.Position, rt)
			if p:GetAttribute("SeaDangerLevel") ~= danger then
				p:SetAttribute("SeaDangerLevel", danger)
			end
			if danger >= 2 and rt.SeatedInShip and now >= (rt.NextSeaEncounterCheck or 0) then
				rt.NextSeaEncounterCheck = now + math.max(18, 44 - danger * 4)
				local roll = math.random()
				if danger >= 5 and roll < 0.22 and not ActiveMirageEvent then
					WorldEvents.SpawnMirageIsland(p)
				elseif danger >= 5 and roll < 0.55 then
					WorldEvents.SpawnSeaMonsterEvent(p, "AbyssalLeviathan")
				elseif danger >= 4 and roll < 0.65 then
					WorldEvents.SpawnSeaMonsterEvent(p, "SkySeaBeast")
				elseif danger >= 2 and roll < 0.70 then
					WorldEvents.SpawnSeaMonsterEvent(p, "TerrorSkyShark")
				end
			end
		end
	end
end

-- ============================================================================
-- 10. #63 - DYNAMIC 15-MINUTE MIRAGESKYISLAND EVENT (BLUE GEAR V4 + DEALER)
-- ============================================================================
function WorldEvents.SpawnMirageIsland(nearPlayerOrPos)
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
		if oldCol then oldCol:Destroy() end
		local col = deck:Clone()
		col.Name = "MirageSanctuaryCollider"
		col.Transparency = 1
		col.Parent = gsiCol
		m.Destroying:Once(function()
			if col and col.Parent then col:Destroy() end
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

	-- Collectible 3D Blue Resonance Gear (CoreGears +1 / RaceV4Unlocked = true)
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
	gLbl.Text = "BLUE RESONANCE GEAR [RACE V4]"
	gLbl.Parent = gBill

	local claimedBy = {}
	local gPrompt = Instance.new("ProximityPrompt")
	gPrompt.ActionText = "Thu Thập Blue Resonance Gear [V4]"
	gPrompt.ObjectText = "Cổ Vật Thức Tỉnh Tộc V4 • Mirage Island"
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
			G.Notify(plr, "Bạn đã thu thập Blue Resonance Gear trên đảo Mirage đợt này rồi!")
			return
		end
		local prof = D.Get(plr)
		if not prof then
			return
		end
		claimedBy[uid] = true
		prof.CoreGears = (prof.CoreGears or 0) + 1
		prof.RaceV4Unlocked = true
		prof.RaceTier = 4
		prof.CoreShards = (prof.CoreShards or 0) + 300
		G.Notify(plr, "THỨC TỈNH CỔ ĐẠI: Thu thập Blue Resonance Gear (+1 CoreGear, +300 Shards) -> Đã MỞ KHÓA RACE V4!")
		G.Sync(plr)
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
	dLbl.Text = "MIRAGE STOCK DEALER • TRÁI HIẾM [E]"
	dLbl.Parent = dBill

	local dPrompt = Instance.new("ProximityPrompt")
	dPrompt.ActionText = "Giao Dịch Kho Trái Ác Quỷ Mirage"
	dPrompt.ObjectText = "Mirage Stock Dealer • Đảo Ảo Ảnh"
	dPrompt.MaxActivationDistance = 16
	dPrompt.HoldDuration = 0
	dPrompt.RequiresLineOfSight = false
	dPrompt.Parent = dBody
	dPrompt.Triggered:Connect(function(plr)
		G.Interact(plr, "MirageDealer")
		G.SendDialogue(
			plr,
			"Mirage Stock Dealer",
			"THƯƠNG NHÂN ĐẢO ẢO ẢNH",
			"Chào mừng tới Đảo Ảo Ảnh Mirage! Kho Trái Ác Quỷ Thần Thoại của ta có tỉ lệ xuất hiện cao gấp đôi — hãy mở Cửa Hàng Mirage 3D!",
			"Mở Cửa Hàng Mirage 3D",
			"OpenScreen:NPCShop:MirageDealer"
		)
	end)

	local endsAt = workspace:GetServerTimeNow() + 900
	ActiveMirageEvent = {
		Model = m,
		Gear = gear,
		Pos = center,
		ExpiresClock = os.clock() + 900,
	}
	workspace:SetAttribute("MirageIslandActive", true)
	workspace:SetAttribute("MirageIslandPos", center)
	workspace:SetAttribute("MirageIslandEndsAt", endsAt)

	broadcastWorldBanner(
		"ĐẢO ẢO ẢNH MIRAGE XUẤT HIỆN!",
		"Mirage Sky Island đã hiện ra trong 15 phút! Tìm Blue Resonance Gear (Race V4) & Mirage Stock Dealer!",
		"Mirage"
	)
	return m, center
end

-- ============================================================================
-- 11. #76 - PIRATE RAID SIEGE EVENT AT CASTLE ON THE VOID
-- ============================================================================
function WorldEvents.StartPirateRaidSiege(triggerPlayer)
	if ActivePirateRaid and os.clock() < ActivePirateRaid.ExpiresAt then
		local aliveAny = false
		for _, mob in ipairs(ActivePirateRaid.Mobs) do
			if mob.Alive then
				aliveAny = true
				break
			end
		end
		if aliveAny then
			if triggerPlayer then
				G.Notify(triggerPlayer, "Đợt Hải Tặc Công Thành tại Castle on the Void đang diễn ra!")
			end
			return
		end
	end

	local center = Vector3.new(-14600, 46.9, 2173.1)
	local fy = safeFloorY(center, 46.9)
	local mobs = {}

	for idx = 1, 8 do
		local ang = (idx - 1) * (math.pi * 2 / 8)
		local mpos = center + Vector3.new(math.cos(ang) * 20, 0, math.sin(ang) * 18)
		local mobId = (idx % 2 == 0) and "AbyssalKnight" or "VoidPirate"
		local mob = G.SpawnEnemy(mobId, Vector3.new(mpos.X, safeFloorY(mpos, fy) + 2.5, mpos.Z), false, true)
		if mob then
			mob.IsPirateRaidMob = true
			table.insert(mobs, mob)
		end
	end

	local cmdId = C.Enemies.VoidCastellanBoss and "VoidCastellanBoss" or "PirateCaptainVance"
	local commander = G.SpawnEnemy(cmdId, Vector3.new(center.X, fy + 3.0, center.Z), true, true)
	if commander then
		commander.IsPirateRaidCommander = true
		commander.MaxHP = math.max(58000, commander.MaxHP)
		commander.HP = commander.MaxHP
		table.insert(mobs, commander)
	end

	ActivePirateRaid = {
		Mobs = mobs,
		Commander = commander,
		ExpiresAt = os.clock() + 420,
	}

	broadcastWorldBanner(
		"HẢI TẶC CÔNG THÀNH CASTLE ON THE VOID!",
		"8 Hải Tặc Hư Không & Chỉ Huy Công Thành đang tấn công! Người kết liễu Chỉ Huy sẽ nhận chắc chắn 1 Trái Ác Quỷ 3D!",
		"PirateRaid"
	)
end

local function buildPirateRaidHornBeacon()
	local worldObjects = getWorldObjects()
	local old = worldObjects:FindFirstChild("PirateRaidHorn_CastleVoid")
	if old then
		old:Destroy()
	end
	local raw = Vector3.new(-14614, 46.9, 2180)
	local fy = safeFloorY(raw, 46.9)
	local m = Instance.new("Model")
	m.Name = "PirateRaidHorn_CastleVoid"
	m.Parent = worldObjects

	local ped = W.Part(m, "HornPedestal", Vector3.new(3.2, 3.6, 3.2), Vector3.new(raw.X, fy + 1.8, raw.Z), Color3.fromRGB(58, 42, 78), Enum.Material.Slate)
	local horn = W.Part(m, "SiegeHorn", Vector3.new(1.4, 2.6, 1.4), Vector3.new(raw.X, fy + 4.4, raw.Z), Color3.fromRGB(255, 195, 76), Enum.Material.Metal)
	m.PrimaryPart = ped

	local bill = Instance.new("BillboardGui")
	bill.Size = UDim2.fromScale(4.0, 0.75)
	bill.StudsOffset = Vector3.new(0, 4.6, 0)
	bill.AlwaysOnTop = false
	bill.MaxDistance = 56
	bill.Parent = ped
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamBlack
	tl.TextScaled = true
	tl.TextColor3 = Color3.fromRGB(255, 206, 92)
	tl.TextStrokeTransparency = 0.18
	tl.Text = "TÙ VÀ HẢI TẶC CÔNG THÀNH [E]"
	tl.Parent = bill

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Kích Hoạt Sự Kiện Pirate Raid"
	prompt.ObjectText = "Castle on the Void • Thưởng Trái Ác Quỷ 3D"
	prompt.MaxActivationDistance = 15
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.Parent = ped
	prompt.Triggered:Connect(function(plr)
		WorldEvents.StartPirateRaidSiege(plr)
	end)
end

-- ============================================================================
-- 12. #77, #78, #79 - MVP #1/#2/#3 SUMMARY, MAGNETIC LOOT ORBS & RESPAWN HOLO
-- ============================================================================
local function broadcastMVPSummary(bossName, contributorsMap, extraBonusMult)
	if not contributorsMap then
		return
	end
	local list = {}
	local totalDmg = 0
	for plr, entry in pairs(contributorsMap) do
		local dmg = type(entry) == "table" and (tonumber(entry.Damage) or 0) or (tonumber(entry) or 0)
		if typeof(plr) == "Instance" and plr:IsA("Player") and plr.Parent == Players and dmg > 0 then
			totalDmg += dmg
			table.insert(list, { Player = plr, Damage = math.floor(dmg) })
		end
	end
	if #list == 0 or totalDmg <= 0 then
		return
	end
	table.sort(list, function(a, b)
		return a.Damage > b.Damage
	end)

	local mult = tonumber(extraBonusMult) or 1.0
	local rankRewards = {
		{ Shards = math.floor(150 * mult), Gold = math.floor(15000 * mult), Label = "+150 Shards, +15,000 Gold" },
		{ Shards = math.floor(90 * mult), Gold = math.floor(9000 * mult), Label = "+90 Shards, +9,000 Gold" },
		{ Shards = math.floor(50 * mult), Gold = math.floor(5000 * mult), Label = "+50 Shards, +5,000 Gold" },
	}

	local entries = {}
	for rank = 1, math.min(3, #list) do
		local item = list[rank]
		local sharePct = math.clamp(math.floor((item.Damage / totalDmg) * 1000 + 0.5) / 10, 0.1, 100)
		local rw = rankRewards[rank]
		local prof = D.Get(item.Player)
		if prof and rw then
			prof.CoreShards = (prof.CoreShards or 0) + rw.Shards
			prof.Gold = (prof.Gold or 0) + rw.Gold
		end
		table.insert(entries, {
			Rank = rank,
			Name = item.Player.Name,
			UserId = item.Player.UserId,
			Damage = item.Damage,
			SharePct = sharePct,
			Reward = rw and string.format("+%d Shards • +%d Gold", rw.Shards, rw.Gold) or "+50 Shards",
		})
	end

	if R and R:FindFirstChild("StateUpdate") then
		R.StateUpdate:FireAllClients({
			MVPSummary = {
				BossName = tostring(bossName or "Raid Boss"),
				TotalDamage = math.floor(totalDmg),
				Entries = entries,
				Timestamp = workspace:GetServerTimeNow(),
			},
		})
	end
end

local function spawnMagneticLootOrbs(originPos, contributorsMap, isMythicTier)
	local recipients = {}
	for plr, hit in pairs(contributorsMap or {}) do
		local dmg = type(hit) == "table" and (tonumber(hit.Damage) or 0) or (tonumber(hit) or 0)
		if typeof(plr) == "Instance" and plr:IsA("Player") and plr.Parent == Players and dmg > 0 then
			table.insert(recipients, plr)
		end
	end
	if #recipients == 0 then
		return
	end

	local tempFX = getTempFX()
	local orbCount = isMythicTier and 5 or 4
	local floorY = safeFloorY(originPos, originPos.Y - 2.5)

	for i = 1, orbCount do
		local targetPlr = recipients[((i - 1) % #recipients) + 1]
		local isCrimson = isMythicTier and (i <= 2)
		local col = isCrimson and Color3.fromRGB(255, 58, 96) or Color3.fromRGB(255, 212, 78)
		local rarity = isCrimson and "Mythic" or "Legendary"
		local ang = (i - 1) * (math.pi * 2 / orbCount) + math.random() * 0.4
		local dropRadius = 5.5 + math.random() * 5.5
		local landPos = Vector3.new(originPos.X + math.cos(ang) * dropRadius, floorY + 1.4, originPos.Z + math.sin(ang) * dropRadius)

		local orbModel = Instance.new("Model")
		orbModel.Name = "LootOrb_" .. rarity
		orbModel.Parent = tempFX

		local sphere = Instance.new("Part")
		sphere.Name = "OrbCore"
		sphere.Shape = Enum.PartType.Ball
		sphere.Size = Vector3.new(1.7, 1.7, 1.7)
		sphere.Position = originPos + Vector3.new(0, 2.2, 0)
		sphere.Color = col
		sphere.Material = Enum.Material.Neon
		sphere.Transparency = 0.35
		sphere.Anchored, sphere.CanCollide, sphere.CanQuery, sphere.CanTouch = true, false, false, false
		sphere.Parent = orbModel
		orbModel.PrimaryPart = sphere

		local beamCyl = Instance.new("Part")
		beamCyl.Name = "LightPillar"
		beamCyl.Shape = Enum.PartType.Cylinder
		beamCyl.Size = Vector3.new(14.0, 0.75, 0.75)
		beamCyl.CFrame = CFrame.new(sphere.Position + Vector3.new(0, 7.0, 0)) * CFrame.Angles(0, 0, math.pi / 2)
		beamCyl.Color = col
		beamCyl.Material = Enum.Material.Neon
		beamCyl.Transparency = 0.55
		beamCyl.Anchored, beamCyl.CanCollide, beamCyl.CanQuery, beamCyl.CanTouch = true, false, false, false
		beamCyl.Parent = orbModel

		task.spawn(function()
			local arcDur = 0.42
			local t0 = os.clock()
			local startP = sphere.Position
			while orbModel.Parent and (os.clock() - t0) < arcDur do
				RunService.Heartbeat:Wait()
				local a = math.clamp((os.clock() - t0) / arcDur, 0, 1)
				local p = startP:Lerp(landPos, a) + Vector3.new(0, 4.5 * a * (1 - a), 0)
				sphere.Position = p
				beamCyl.CFrame = CFrame.new(p + Vector3.new(0, 7.0, 0)) * CFrame.Angles(0, 0, math.pi / 2)
			end

			local waitStart = os.clock()
			while orbModel.Parent and (os.clock() - waitStart) < 1.6 do
				RunService.Heartbeat:Wait()
				local pr = targetPlr and root(targetPlr) or nil
				if pr and dist(pr.Position, sphere.Position) <= 28 then
					break
				end
			end

			local magStart = os.clock()
			local fromP = sphere.Position
			while orbModel.Parent and (os.clock() - magStart) < 0.45 do
				RunService.Heartbeat:Wait()
				local pr = targetPlr and root(targetPlr) or nil
				if not pr then
					break
				end
				local a = math.clamp((os.clock() - magStart) / 0.45, 0, 1)
				local curved = fromP:Lerp(pr.Position + Vector3.new(0, 1.2, 0), a * a) + Vector3.new(0, math.sin(a * math.pi) * 2.4, 0)
				sphere.Position = curved
				beamCyl.CFrame = CFrame.new(curved + Vector3.new(0, 5.0 * (1 - a), 0)) * CFrame.Angles(0, 0, math.pi / 2)
				beamCyl.Transparency = 0.55 + 0.4 * a
			end

			if targetPlr and targetPlr.Parent == Players then
				local prof = D.Get(targetPlr)
				local pr = root(targetPlr)
				if prof then
					local bonusGold = isCrimson and 2800 or 1200
					local bonusShards = isCrimson and 35 or 15
					prof.Gold = (prof.Gold or 0) + bonusGold
					prof.CoreShards = (prof.CoreShards or 0) + bonusShards
					if R and R:FindFirstChild("CombatFX") and pr then
						R.CombatFX:FireAllClients({
							Kind = "LootOrbPickup",
							Position = pr.Position,
							Rarity = rarity,
							Gold = bonusGold,
							Shards = bonusShards,
							Actor = targetPlr.UserId,
						})
					end
				end
			end
			if orbModel.Parent then
				orbModel:Destroy()
			end
		end)
	end
end

local function spawnBossRespawnHologram(bossId, bossCfg, homePos, respawnDelaySec)
	local key = tostring(bossId) .. "_" .. string.format("%d_%d", math.floor(homePos.X), math.floor(homePos.Z))
	if ActiveRespawnHolograms[key] and ActiveRespawnHolograms[key].Model and ActiveRespawnHolograms[key].Model.Parent then
		ActiveRespawnHolograms[key].Model:Destroy()
	end

	local fy = safeFloorY(homePos, homePos.Y - 3)
	local m = Instance.new("Model")
	m.Name = "BossRespawnHologram_" .. tostring(bossId)
	m.Parent = getWorldObjects()

	local ring = Instance.new("Part")
	ring.Name = "HoloRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.28, 13, 13)
	ring.CFrame = CFrame.new(homePos.X, fy + 0.48, homePos.Z) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Color = Color3.fromRGB(82, 232, 255)
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.45
	ring.Anchored, ring.CanCollide, ring.CanQuery, ring.CanTouch = true, false, false, false
	ring.Parent = m
	m.PrimaryPart = ring

	local innerOrb = Instance.new("Part")
	innerOrb.Name = "HoloBeaconCore"
	innerOrb.Shape = Enum.PartType.Ball
	innerOrb.Size = Vector3.new(2.2, 2.2, 2.2)
	innerOrb.Position = Vector3.new(homePos.X, fy + 3.2, homePos.Z)
	innerOrb.Color = Color3.fromRGB(255, 214, 92)
	innerOrb.Material = Enum.Material.Neon
	innerOrb.Transparency = 0.42
	innerOrb.Anchored, innerOrb.CanCollide, innerOrb.CanQuery, innerOrb.CanTouch = true, false, false, false
	innerOrb.Parent = m

	local bill = Instance.new("BillboardGui")
	bill.Size = UDim2.fromScale(5.2, 1.15)
	bill.StudsOffset = Vector3.new(0, 4.4, 0)
	bill.AlwaysOnTop = false
	bill.MaxDistance = 85
	bill.Parent = innerOrb
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamBlack
	tl.TextScaled = true
	tl.TextColor3 = Color3.fromRGB(108, 240, 255)
	tl.TextStrokeTransparency = 0.16
	local bName = (bossCfg and bossCfg.Name) or tostring(bossId)
	local bLv = (bossCfg and bossCfg.Level) and (" [Lv." .. tostring(bossCfg.Level) .. "]") or ""
	tl.Text = bName .. bLv .. "\nHỒI SINH SAU: 01:00"
	tl.Parent = bill

	ActiveRespawnHolograms[key] = {
		Key = key,
		BossId = bossId,
		BossLabel = bName .. bLv,
		HomePos = homePos,
		Model = m,
		Ring = ring,
		Orb = innerOrb,
		Label = tl,
		RespawnAt = os.clock() + respawnDelaySec,
	}
end

local function tickBossRespawnHolograms(dt)
	local now = os.clock()
	for key, entry in pairs(ActiveRespawnHolograms) do
		local alreadyAlive = false
		for _, e in ipairs(G.Enemies) do
			if e.Id == entry.BossId and e.Alive and flatDist(e.Home, entry.HomePos) <= 45 then
				alreadyAlive = true
				break
			end
		end
		local rem = math.max(0, math.ceil(entry.RespawnAt - now))
		if alreadyAlive then
			if entry.Model and entry.Model.Parent then
				entry.Model:Destroy()
			end
			ActiveRespawnHolograms[key] = nil
		elseif rem <= 0 then
			if entry.Model and entry.Model.Parent then
				entry.Model:Destroy()
			end
			ActiveRespawnHolograms[key] = nil
			if entry.BossId ~= "AureonSentinel" or not G.Boss then
				G.SpawnEnemy(entry.BossId, entry.HomePos, false, false)
			end
		else
			if entry.Orb and entry.Orb.Parent then
				entry.Orb.CFrame = entry.Orb.CFrame * CFrame.Angles(0, dt * 1.8, 0)
			end
			if entry.Label and entry.Label.Parent then
				local mm = math.floor(rem / 60)
				local ss = rem % 60
				local txt = string.format("%s\nHOI SINH SAU: %02d:%02d", entry.BossLabel, mm, ss)
				if entry.LastTxt ~= txt then
					entry.LastTxt = txt
					entry.Label.Text = txt
				end
			end
		end
	end
end

-- ============================================================================
-- 13. #70 - DPS TRAINING DUMMY AT SKY HUB TRAINING COURTYARD
-- ============================================================================
local function buildDPSTrainingDummy()
	if DPSDummyEntry and DPSDummyEntry.Enemy and DPSDummyEntry.Enemy.Alive then
		return
	end
	local rawPos = Vector3.new(-288, 48.0, 486)
	local fy = safeFloorY(rawPos, 46.5)
	local spawnPos = Vector3.new(rawPos.X, fy + 2.6, rawPos.Z)

	local dummyCfg = {
		Name = "DPS Training Dummy",
		VisualAsset = "TrainingDrone",
		Element = "Sky",
		Level = 2550,
		HP = 10000000,
		ATK = 0,
		DEF = 0,
		Speed = 0,
		Range = 0,
		Aggro = 0,
		Leash = 999,
		XP = 0,
		Gold = 0,
	}
	C.Enemies.DPSTrainingDummy = dummyCfg

	local e = G.SpawnEnemy("DPSTrainingDummy", spawnPos, false, true)
	if not e or not e.Model or not e.Body then
		return
	end
	e.IsDPSDummy = true
	e.MaxHP = 10000000
	e.HP = 10000000
	e.Model.Name = "DPSTrainingDummy"
	e.Model:SetAttribute("IsDPSDummy", true)


	local bill = Instance.new("BillboardGui")
	bill.Name = "DPSMeterBillboard"
	bill.Size = UDim2.fromScale(6.2, 2.2)
	bill.StudsOffset = Vector3.new(0, 5.8, 0)
	bill.AlwaysOnTop = false
	bill.MaxDistance = 68
	bill.Parent = e.Body

	local card = Instance.new("Frame")
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = Color3.fromRGB(12, 16, 26)
	card.BackgroundTransparency = 0.2
	card.BorderSizePixel = 0
	card.Parent = bill
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.14, 0)
	corner.Parent = card
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 206, 86)
	stroke.Thickness = 1.6
	stroke.Parent = card

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.fromScale(0.92, 0.88)
	lbl.Position = UDim2.fromScale(0.04, 0.06)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextScaled = true
	lbl.TextColor3 = Color3.fromRGB(255, 236, 168)
	lbl.TextStrokeTransparency = 0.25
	lbl.Text = "DPS TRAINING DUMMY [10,000,000 HP]\nTỔNG DMG: 0 | DPS: 0\nCOMBO: 0 HITS | ĐÒN CUỐI: 0"
	lbl.Parent = card

	DPSDummyEntry = {
		Enemy = e,
		Label = lbl,
		TotalDamage = 0,
		ComboHits = 0,
		LastHit = 0,
		FirstHitAt = 0,
		LastHitAt = 0,
	}
end

local function updateDPSDummyOnHit(hitDmg)
	if not DPSDummyEntry or not DPSDummyEntry.Enemy then
		return
	end
	local now = os.clock()
	if DPSDummyEntry.TotalDamage == 0 or (now - DPSDummyEntry.LastHitAt) > 4.0 then
		DPSDummyEntry.TotalDamage = 0
		DPSDummyEntry.ComboHits = 0
		DPSDummyEntry.FirstHitAt = now
	end
	DPSDummyEntry.TotalDamage += hitDmg
	DPSDummyEntry.ComboHits += 1
	DPSDummyEntry.LastHit = hitDmg
	DPSDummyEntry.LastHitAt = now
	local elapsed = math.max(0.25, now - DPSDummyEntry.FirstHitAt)
	local dps = math.floor(DPSDummyEntry.TotalDamage / elapsed)

	local e = DPSDummyEntry.Enemy
	if e.HP < 1000000 then
		e.HP = e.MaxHP
	end
	if W and W.UpdateEnemyBar then
		W.UpdateEnemyBar(e)
	end
	if DPSDummyEntry.Label and DPSDummyEntry.Label.Parent then
		DPSDummyEntry.Label.Text = string.format(
			"DPS TRAINING DUMMY\nTỔNG DMG: %d | DPS: %d/s\nCOMBO: %d HITS | ĐÒN CUỐI: %d",
			math.floor(DPSDummyEntry.TotalDamage),
			dps,
			DPSDummyEntry.ComboHits,
			math.floor(DPSDummyEntry.LastHit)
		)
	end
end

local function tickDPSDummy()
	if not DPSDummyEntry or not DPSDummyEntry.Enemy then
		return
	end
	local now = os.clock()
	local e = DPSDummyEntry.Enemy
	if DPSDummyEntry.TotalDamage > 0 and (now - DPSDummyEntry.LastHitAt) >= 4.0 then
		DPSDummyEntry.TotalDamage = 0
		DPSDummyEntry.ComboHits = 0
		DPSDummyEntry.LastHit = 0
		e.HP = e.MaxHP
		if W and W.UpdateEnemyBar then
			W.UpdateEnemyBar(e)
		end
		if DPSDummyEntry.Label and DPSDummyEntry.Label.Parent then
			DPSDummyEntry.Label.Text = "DPS TRAINING DUMMY [10,000,000 HP]\nTỔNG DMG: 0 | DPS: 0\nCOMBO: 0 HITS | ĐÒN CUỐI: 0"
		end
	end
end

function WorldEvents.ResetDPSDummy(p)
	if not DPSDummyEntry or not DPSDummyEntry.Enemy or not DPSDummyEntry.Enemy.Alive then
		buildDPSTrainingDummy()
	end
	if DPSDummyEntry and DPSDummyEntry.Enemy then
		DPSDummyEntry.TotalDamage = 0
		DPSDummyEntry.ComboHits = 0
		DPSDummyEntry.LastHit = 0
		DPSDummyEntry.FirstHitAt = 0
		DPSDummyEntry.LastHitAt = 0
		DPSDummyEntry.Enemy.HP = DPSDummyEntry.Enemy.MaxHP
		if W and W.UpdateEnemyBar then
			W.UpdateEnemyBar(DPSDummyEntry.Enemy)
		end
		if DPSDummyEntry.Label and DPSDummyEntry.Label.Parent then
			DPSDummyEntry.Label.Text = "DPS TRAINING DUMMY [10,000,000 HP]\nTỔNG DMG: 0 | DPS: 0\nCOMBO: 0 HITS | ĐÒN CUỐI: 0"
		end
	end
	if p and G and G.Notify then
		G.Notify(p, "Đã đặt lại bảng đo sát thương DPS Training Dummy!")
	end
	return true
end

-- ============================================================================
-- 14. #22, #118, #119 - 5-WAVE TIMED MICROCHIP AWAKENING RAID + REVIVE BEACON
-- ============================================================================
local RAID_PLATFORM_CENTERS = {
	Vector3.new(14600, 96, 1770),
	Vector3.new(14600, 100, 1740),
	Vector3.new(14600, 104, 1710),
	Vector3.new(14600, 108, 1680),
	Vector3.new(14600, 112, 1650),
}

local function ensureRaidArenaPlatforms()
	local worldObjects = getWorldObjects()
	if worldObjects:FindFirstChild("MicrochipRaidArena_5Islands") then
		return
	end
	local rootM = Instance.new("Model")
	rootM.Name = "MicrochipRaidArena_5Islands"
	rootM.Parent = worldObjects

	local colFolder = workspace:FindFirstChild("GrandSkyIslands_Collision") or worldObjects

	for idx, cpos in ipairs(RAID_PLATFORM_CENTERS) do
		local radius = (idx == 5) and 24 or 20
		local deck = Instance.new("Part")
		deck.Name = "RaidWaveIsland_" .. idx
		deck.Shape = Enum.PartType.Cylinder
		deck.Size = Vector3.new(3.2, radius * 2, radius * 2)
		deck.CFrame = CFrame.new(cpos.X, cpos.Y - 1.6, cpos.Z) * CFrame.Angles(0, 0, math.pi / 2)
		deck.Color = Color3.fromRGB(32, 44, 68)
		deck.Material = Enum.Material.Slate
		deck.Anchored, deck.CanCollide, deck.CanQuery, deck.CanTouch = true, true, true, false
		deck.Parent = colFolder

		local ring = Instance.new("Part")
		ring.Name = "RaidWaveRune_" .. idx
		ring.Shape = Enum.PartType.Cylinder
		ring.Size = Vector3.new(0.4, radius * 1.85, radius * 1.85)
		ring.CFrame = CFrame.new(cpos.X, cpos.Y - 0.1, cpos.Z) * CFrame.Angles(0, 0, math.pi / 2)
		ring.Color = (idx == 5) and Color3.fromRGB(255, 192, 78) or Color3.fromRGB(88, 236, 255)
		ring.Material = Enum.Material.Neon
		ring.Transparency = 0.46
		ring.Anchored, ring.CanCollide, ring.CanQuery, ring.CanTouch = true, false, false, false
		ring.Parent = rootM

		if idx < 5 then
			local nxt = RAID_PLATFORM_CENTERS[idx + 1]
			local p0 = cpos + Vector3.new(0, -0.4, -13)
			local p1 = nxt + Vector3.new(0, -0.4, 13)
			local br = Instance.new("Part")
			br.Name = "RaidLightBridge_" .. idx
			br.Size = Vector3.new(12, 1.2, (p1 - p0).Magnitude + 4)
			br.CFrame = CFrame.lookAt((p0 + p1) * 0.5, p1)
			br.Color = Color3.fromRGB(82, 228, 255)
			br.Material = Enum.Material.Neon
			br.Transparency = 0.42
			br.Anchored, br.CanCollide, br.CanQuery, br.CanTouch = true, true, true, false
			br.Parent = colFolder
		end
	end
end

local function spawnRaidWave(session, waveNum)
	session.Wave = waveNum
	session.WaveStartedAt = os.clock()
	session.AllMissingSince = nil
	session.Mobs = {}
	local cpos = RAID_PLATFORM_CENTERS[waveNum] or RAID_PLATFORM_CENTERS[5]
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

function WorldEvents.VoteRaidDifficulty(p, diffId)
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

function WorldEvents.StartMicrochipRaid(leader, requestedDiff)
	if not leader or leader.Parent ~= Players then
		return
	end
	if leader:GetAttribute("InTrade") == true or leader:GetAttribute("ColosseumActive") == true or (leader:GetAttribute("SpireFloor") or 0) > 0 then
		G.Notify(leader, "Không thể bắt đầu Awakening Raid khi đang Giao Dịch, Đấu Trường hoặc trong Sky Spire!")
		return
	end
	if ActiveRaidSession then
		G.Notify(leader, "Microchip Awakening Raid đang diễn ra (Wave " .. tostring(ActiveRaidSession.Wave) .. "/5)!")
		return
	end
	ensureRaidArenaPlatforms()

	local rt = G.Runtime[leader]
	local diffKey = tostring(requestedDiff or (rt and rt.SelectedRaidDifficulty) or leader:GetAttribute("RaidDifficulty") or "Normal")
	local diffSpec = RAID_DIFFICULTIES[diffKey] or RAID_DIFFICULTIES.Normal

	local squad = {}
	local seen = {}
	for _, member in ipairs(getPartyGroup(leader)) do
		if member and member.Parent == Players and not seen[member] and #squad < 6
			and member:GetAttribute("InTrade") ~= true and member:GetAttribute("ColosseumActive") ~= true and (member:GetAttribute("SpireFloor") or 0) == 0 then
			seen[member] = true
			table.insert(squad, member)
		end
	end
	local lr = root(leader)
	if lr then
		for _, other in ipairs(Players:GetPlayers()) do
			local oroot = root(other)
			if not seen[other] and oroot and dist(oroot.Position, lr.Position) <= 45 and #squad < 6
				and other:GetAttribute("InTrade") ~= true and other:GetAttribute("ColosseumActive") ~= true and (other:GetAttribute("SpireFloor") or 0) == 0 then
				seen[other] = true
				table.insert(squad, other)
			end
		end
	end
	if #squad == 0 then
		table.insert(squad, leader)
	end

	ActiveRaidSession = {
		Leader = leader,
		Players = squad,
		DifficultySpec = diffSpec,
		Wave = 1,
		WaveStartedAt = os.clock(),
		EndsAt = os.clock() + 720, -- 12:00 countdown
		Mobs = {},
		DamageMap = {},
	}

	for _, plr in ipairs(squad) do
		plr:SetAttribute("CurrentRealm", "FrozenCyber")
	end
	spawnRaidWave(ActiveRaidSession, 1)
end

local function clearPlayerRaidAttributes(plr)
	if plr and plr.Parent == Players then
		plr:SetAttribute("RaidActive", false)
		plr:SetAttribute("RaidWave", 0)
		plr:SetAttribute("RaidTimer", 0)
	end
end

local function endRaidSession(victory, reasonMsg)
	local session = ActiveRaidSession
	if not session then
		return
	end
	ActiveRaidSession = nil
	workspace:SetAttribute("RaidActive", false)
	workspace:SetAttribute("RaidWave", 0)
	workspace:SetAttribute("RaidTimer", 0)

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
					local rawFid = prof.EquippedFruit or "SolarTitanCore"
					local fid = (CombatData and CombatData.ResolveFruitId and CombatData.ResolveFruitId(rawFid)) or rawFid
					prof.AwakenedFruits = prof.AwakenedFruits or {}
					prof.AwakenedFruits[fid] = true
					prof.UnlockedTitles = prof.UnlockedTitles or {}
					prof.UnlockedTitles.awakened_ascendant = true
					if diff.Microchip then
						prof.Inventory = prof.Inventory or {}
						prof.Inventory.AwakeningMicrochip = (prof.Inventory.AwakeningMicrochip or 0) + 1
					end
					G.Reward(plr, diff.XP, diff.Gold, diff.Shards)
					G.Notify(plr, string.format("CHIẾN THẮNG AWAKENING RAID [%s]! +%d Core Shards, +%d Gold & Thức Tỉnh V2 [%s]!", diff.Label, diff.Shards, diff.Gold, fid))
					G.Sync(plr)
					task.spawn(D.Save, plr, false)
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

	for _, plr in ipairs(session.Players) do
		if plr.Parent == Players then
			clearPlayerRaidAttributes(plr)
			if not victory and reasonMsg then
				G.Notify(plr, reasonMsg)
			end
			task.delay(4.0, function()
				if plr.Parent == Players then
					local pr = root(plr)
					local waveCenter = RAID_PLATFORM_CENTERS[session.Wave] or RAID_PLATFORM_CENTERS[1]
					if not pr or dist(pr.Position, waveCenter) <= 450 then
						local prt = G.Runtime[plr]
						if prt then
							prt.JumpPadUntil = math.max(prt.JumpPadUntil or 0, os.clock() + 2.5)
						end
						G.Teleport(plr, Vector3.new(14600, 50.9, 1785))
					end
				end
			end)
		end
	end
end

local function tickRaidDungeon()
	local session = ActiveRaidSession
	if not session then
		return
	end
	local now = os.clock()
	local rem = math.max(0, math.ceil(session.EndsAt - now))
	workspace:SetAttribute("RaidTimer", rem)

	local waveCenter = RAID_PLATFORM_CENTERS[session.Wave] or RAID_PLATFORM_CENTERS[1]
	local graceElapsed = (now - (session.WaveStartedAt or 0)) > 4.5
	local activeSquad = {}
	local inArenaAliveCount = 0

	for _, plr in ipairs(session.Players) do
		if plr and plr.Parent == Players then
			local pr, ph = root(plr)
			local prt = G.Runtime[plr]
			local isDowned = prt and prt.IsDowned == true
			if pr and ph and ph.Health > 0 and not isDowned and graceElapsed and dist(pr.Position, waveCenter) > 450 then
				-- Player died and respawned outside the Raid islands (e.g. at Sky Hub); release Raid lock!
				clearPlayerRaidAttributes(plr)
				G.Notify(plr, "[RAID] Bạn đã rời khỏi Đấu Trường Awakening Raid!")
				G.Sync(plr)
			else
				plr:SetAttribute("RaidTimer", rem)
				table.insert(activeSquad, plr)
				if pr and ph and (ph.Health > 0 or isDowned) and dist(pr.Position, waveCenter) <= 450 then
					inArenaAliveCount += 1
				end
			end
		end
	end
	session.Players = activeSquad

	if #activeSquad == 0 then
		endRaidSession(false, "[RAID] Toàn bộ tổ đội đã gục ngã hoặc rời khỏi Đấu Trường Raid!")
		return
	end
	if inArenaAliveCount == 0 then
		session.AllMissingSince = session.AllMissingSince or now
		if (now - session.AllMissingSince) >= 6.5 then
			endRaidSession(false, "[RAID] Tổ đội đã thất bại trong Awakening Raid!")
			return
		end
	else
		session.AllMissingSince = nil
	end

	if rem <= 0 then
		endRaidSession(false, "[RAID] Hết thời gian 12:00! Hãy nâng cấp trang bị và thử lại!")
		return
	end

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
			endRaidSession(true)
		end
	end
end

-- #119: Co-op Raid / Boss Revive Beacon
local function tryEnterCoopDownedState(p, r, h, rt, profile)
	local now = os.clock()
	if rt.IsDowned or now < (rt.ReviveCooldownUntil or 0) then
		return false
	end
	local inPartyOrSquad = (profile and profile.PartySize and profile.PartySize ~= "Solo")
	if not inPartyOrSquad and G.GetPartyPlayers then
		local grp = G.GetPartyPlayers(p)
		inPartyOrSquad = (type(grp) == "table" and #grp > 1)
	end
	if not inPartyOrSquad then
		return false
	end

	local inRaidOrBoss = (p:GetAttribute("RaidActive") == true) or (p:GetAttribute("SpireFloor") or 0) > 0
	if not inRaidOrBoss then
		for _, e in ipairs(G.Enemies) do
			if e.Alive and e.Body and isBossEnemy(e) and dist(r.Position, e.Body.Position) <= 115 then
				inRaidOrBoss = true
				break
			end
		end
	end
	if not inRaidOrBoss then
		return false
	end

	rt.IsDowned = true
	rt.DownedStartedAt = now
	rt.DownedUntil = now + 10.0
	rt.ReviveCooldownUntil = now + 42.0
	rt.InvincibleUntil = now + 10.5
	p:SetAttribute("Downed", true)
	h.Health = math.max(5, math.floor(h.MaxHealth * 0.03))
	h.WalkSpeed = 3

	local fy = safeFloorY(r.Position, r.Position.Y - 2.8)
	local bm = Instance.new("Model")
	bm.Name = "CoopReviveBeacon_" .. p.Name
	bm.Parent = getTempFX()

	local ring = Instance.new("Part")
	ring.Name = "BeaconRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.28, 9.0, 9.0)
	ring.CFrame = CFrame.new(r.Position.X, fy + 0.48, r.Position.Z) * CFrame.Angles(0, 0, math.pi / 2)
	ring.Color = Color3.fromRGB(255, 214, 82)
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.42
	ring.Anchored, ring.CanCollide, ring.CanQuery, ring.CanTouch = true, false, false, false
	ring.Parent = bm
	bm.PrimaryPart = ring

	local pillar = Instance.new("Part")
	pillar.Name = "BeaconPillar"
	pillar.Shape = Enum.PartType.Cylinder
	pillar.Size = Vector3.new(12.0, 2.2, 2.2)
	pillar.CFrame = CFrame.new(r.Position.X, fy + 6.0, r.Position.Z) * CFrame.Angles(0, 0, math.pi / 2)
	pillar.Color = Color3.fromRGB(255, 226, 118)
	pillar.Material = Enum.Material.Neon
	pillar.Transparency = 0.58
	pillar.Anchored, pillar.CanCollide, pillar.CanQuery, pillar.CanTouch = true, false, false, false
	pillar.Parent = bm

	local bill = Instance.new("BillboardGui")
	bill.Size = UDim2.fromScale(4.6, 0.9)
	bill.StudsOffset = Vector3.new(0, 4.8, 0)
	bill.AlwaysOnTop = true
	bill.MaxDistance = 85
	bill.Parent = ring
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamBlack
	tl.TextScaled = true
	tl.TextColor3 = Color3.fromRGB(255, 224, 102)
	tl.TextStrokeTransparency = 0.16
	tl.Text = p.Name .. " GỤC NGÃ! [E] CỨU ĐỒNG ĐỘI (10s)"
	tl.Parent = bill

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Cứu Đồng Đội (45% HP)"
	prompt.ObjectText = "Co-op Revive Beacon • " .. p.Name
	prompt.MaxActivationDistance = 15
	prompt.HoldDuration = 1.5
	prompt.RequiresLineOfSight = false
	prompt.Parent = ring
	prompt.Triggered:Connect(function(helper)
		if helper ~= p then
			reviveDownedPlayer(p, helper.Name)
		end
	end)

	rt.ReviveBeacon = bm
	G.Notify(p, "BẠN ĐANG TRONG TRẠNG THÁI GỤC NGÃ (10s)! Đồng đội có thể bấm [E] Cứu Đồng Đội (hoặc Lumen AI sẽ tự động hồi sinh sau 4s)!")

	task.delay(10.1, function()
		if rt.IsDowned and os.clock() >= (rt.DownedUntil or 0) then
			rt.IsDowned = false
			p:SetAttribute("Downed", false)
			if bm.Parent then
				bm:Destroy()
			end
			local _, hh = root(p)
			if hh then
				local baseSpd = (profile and C.Classes[profile.ClassId] and C.Classes[profile.ClassId].Speed) or 18
				hh.WalkSpeed = baseSpd
				hh.Health = hh.MaxHealth
			end
			local respawnPos = p:GetAttribute("RespawnPos")
			G.Teleport(p, typeof(respawnPos) == "Vector3" and (respawnPos + Vector3.new(0, 3, 0)) or C.Spawn)
			G.Notify(p, "Hết 10s Cứu Viện: Đã đưa bạn về Điểm Hồi Sinh an toàn!")
		end
	end)
	return true
end

-- ============================================================================
-- 15. #80 - 50-FLOOR ENDLESS SKY SPIRE TOWER AT SKY HUB
-- ============================================================================
local SPIRE_ARENA_CENTER = Vector3.new(-1080, 960, 1080)

local function cleanupSpireSession(plr, teleportToHub)
	local session = ActiveSpireSessions[plr]
	if session then
		for _, m in ipairs(session.Mobs or {}) do
			if m.Alive then
				m.Alive = false
			end
			if m.Model and m.Model.Parent then
				m.Model:Destroy()
			end
		end
		ActiveSpireSessions[plr] = nil
	end
	if plr and plr.Parent == Players then
		plr:SetAttribute("SpireFloor", 0)
		if teleportToHub then
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

local function ensureSkySpirePortalAndArena()
	local worldObjects = getWorldObjects()
	local colFolder = workspace:FindFirstChild("GrandSkyIslands_Collision") or worldObjects
	local old = worldObjects:FindFirstChild("SkySpirePortal_SkyHub")
	if old then
		old:Destroy()
	end

	-- Portal Archway at Sky Hub (-330, 46.7, 490)
	local rawPos = Vector3.new(-330, 46.7, 490)
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
		WorldEvents.EnterSkySpire(plr)
	end)
end

local function ensureSkySpireArenaDeck()
	local worldObjects = getWorldObjects()
	local colFolder = workspace:FindFirstChild("GrandSkyIslands_Collision") or worldObjects
	local pm = worldObjects:FindFirstChild("SkySpirePortal_SkyHub") or worldObjects
	if not colFolder:FindFirstChild("SkySpireColosseumFloor") then
		local deck = Instance.new("Part")
		deck.Name = "SkySpireColosseumFloor"
		deck.Shape = Enum.PartType.Cylinder
		deck.Size = Vector3.new(3.6, 92, 92)
		deck.CFrame = CFrame.new(SPIRE_ARENA_CENTER.X, SPIRE_ARENA_CENTER.Y - 1.8, SPIRE_ARENA_CENTER.Z) * CFrame.Angles(0, 0, math.pi / 2)
		deck.Color = Color3.fromRGB(228, 224, 214)
		deck.Material = Enum.Material.Marble
		deck.Anchored, deck.CanCollide, deck.CanQuery, deck.CanTouch = true, true, true, false
		deck.Parent = colFolder

		local exitPad = W.Part(pm, "SpireExitBeacon", Vector3.new(4.2, 1.0, 4.2), SPIRE_ARENA_CENTER + Vector3.new(0, 0.5, 38), Color3.fromRGB(255, 198, 84), Enum.Material.Neon)
		exitPad.Transparency = 0.38
		local ep = Instance.new("ProximityPrompt")
		ep.ActionText = "Rời Tháp Sky Spire Về Sky Hub"
		ep.ObjectText = "Sky Spire Exit"
		ep.MaxActivationDistance = 14
		ep.HoldDuration = 0
		ep.RequiresLineOfSight = false
		ep.Parent = exitPad
		ep.Triggered:Connect(function(plr)
			cleanupSpireSession(plr, true)
		end)
	end
end

local function spawnSpireFloorEnemies(p, session, floorNum)
	session.Floor = floorNum
	session.Mobs = {}
	p:SetAttribute("SpireFloor", floorNum)

	local isMilestoneBoss = (floorNum % 5 == 0)
	local hpScale = 1 + (floorNum - 1) * 0.28 + ((floorNum > 25) and (floorNum - 25) * 0.22 or 0)
	local atkScale = 1 + (floorNum - 1) * 0.08

	local pool = (floorNum <= 15) and { "SkyPirate", "CorruptedGuard", "LightArcher", "GoldenKnight" }
		or ((floorNum <= 35) and { "CryoGuard", "CyberArcher", "GoldenKnight", "AbyssalKnight" }
		or { "AbyssalKnight", "ShadowArcher", "VoidPirate", "GoldenKnight" })

	local count = isMilestoneBoss and 3 or math.min(5, 2 + math.floor(floorNum / 12))
	for i = 1, count do
		local ang = (i - 1) * (math.pi * 2 / count)
		local mpos = SPIRE_ARENA_CENTER + Vector3.new(math.cos(ang) * 16, 2.6, math.sin(ang) * 16 - 4)
		local mobId = pool[((floorNum + i) % #pool) + 1]
		local mob = G.SpawnEnemy(mobId, mpos, false, true)
		if mob then
			mob.IsSpireMob = true
			mob.Home = mpos
			mob.HomeFloorY = SPIRE_ARENA_CENTER.Y
			mob.MaxHP = math.floor(950 * hpScale)
			mob.HP = mob.MaxHP
			if mob.Config then
				mob.Config = table.clone(mob.Config)
				mob.Config.ATK = math.floor(24 * atkScale)
			end
			if mob.Model then
				mob.Model:PivotTo(CFrame.new(mpos))
				mob.Model:SetAttribute("EnemyFloorY", SPIRE_ARENA_CENTER.Y)
			end
			table.insert(session.Mobs, mob)
		end
	end

	if isMilestoneBoss then
		local bossPool = { "PirateCaptainVance", "OrderCyborgBoss", "CryonPrime", "SoulReaperRift", "Noxar" }
		local bId = bossPool[math.clamp(math.ceil(floorNum / 10), 1, #bossPool)]
		if not C.Enemies[bId] then
			bId = "GoldenKnight"
		end
		local bpos = SPIRE_ARENA_CENTER + Vector3.new(0, 3.0, -10)
		local bMob = G.SpawnEnemy(bId, bpos, true, true)
		if bMob then
			bMob.IsSpireMob = true
			bMob.IsSpireBoss = true
			bMob.Home = bpos
			bMob.HomeFloorY = SPIRE_ARENA_CENTER.Y
			bMob.MaxHP = math.floor(4200 * hpScale)
			bMob.HP = bMob.MaxHP
			if bMob.Config then
				bMob.Config = table.clone(bMob.Config)
				bMob.Config.ATK = math.floor(38 * atkScale)
			end
			if bMob.Model then
				bMob.Model:PivotTo(CFrame.new(bpos))
				bMob.Model:SetAttribute("EnemyFloorY", SPIRE_ARENA_CENTER.Y)
			end
			table.insert(session.Mobs, bMob)
		end
	end

	G.Notify(p, string.format("[SKY SPIRE] TẦNG %d / 50%s!", floorNum, isMilestoneBoss and " • BOSS TẦNG MỐC" or ""))
end

function WorldEvents.EnterSkySpire(p, requestedFloor)
	local prof = D.Get(p)
	local rt = G.Runtime[p]
	if not prof or not rt then
		return
	end
	if p:GetAttribute("InTrade") == true or p:GetAttribute("RaidActive") == true or p:GetAttribute("ColosseumActive") == true then
		G.Notify(p, "Không thể vào Endless Sky Spire khi đang Giao Dịch, Đấu Trường hoặc Raid!")
		return
	end
	ensureSkySpirePortalAndArena()
	ensureSkySpireArenaDeck()
	local maxUnlocked = math.clamp((prof.HighestSpireFloor or 0) + 1, 1, 50)
	local startFloor = requestedFloor and math.clamp(tonumber(requestedFloor) or maxUnlocked, 1, maxUnlocked) or maxUnlocked

	cleanupSpireSession(p, false)

	rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, os.clock() + 3.0)
	G.Teleport(p, SPIRE_ARENA_CENTER + Vector3.new(0, 3.2, 24))

	local session = {
		Player = p,
		Floor = startFloor,
		Mobs = {},
	}
	ActiveSpireSessions[p] = session
	spawnSpireFloorEnemies(p, session, startFloor)
	G.Sync(p)
end

function WorldEvents.LeaveSkySpire(p)
	cleanupSpireSession(p, true)
	return true
end

local function tickSkySpireSessions()
	for p, session in pairs(ActiveSpireSessions) do
		if p.Parent ~= Players then
			cleanupSpireSession(p, false)
		else
			local pr, ph = root(p)
			if not pr or dist(pr.Position, SPIRE_ARENA_CENTER) > 130 then
				cleanupSpireSession(p, false)
				G.Sync(p)
			else
				local alive = 0
				for _, m in ipairs(session.Mobs) do
					if m.Alive and m.Model and m.Model.Parent then
						alive += 1
					end
				end
				if alive == 0 then
					local prof = D.Get(p)
					local cleared = session.Floor
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
							broadcastWorldBanner(
								"ĐỈNH CAO THÁP VÔ TẬN SKY SPIRE!",
								p.Name .. " đã chinh phục Tầng 50/50 Endless Sky Spire và đạt danh hiệu [Độc Tôn Đỉnh Tháp Vô Tận]!",
								"Spire50"
							)
						end
						G.Reward(p, floorXP, floorGold, milestoneShards)
						if ph then
							ph.Health = math.min(ph.MaxHealth, ph.Health + math.floor(ph.MaxHealth * 0.25))
						end
						G.Sync(p)
						if cleared % 5 == 0 then
							task.spawn(D.Save, p, false)
						end
					end
					if cleared >= 50 then
						cleanupSpireSession(p, false)
						G.Notify(p, "CHÚC MỪNG! Bạn đã hoàn tất Tầng 50/50 Endless Sky Spire!")
						task.delay(3.5, function()
							if p.Parent == Players then
								local rt = G.Runtime[p]
								if rt then
									rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, os.clock() + 2.5)
								end
								G.Teleport(p, Vector3.new(-322, 50.5, 504))
							end
						end)
					else
						spawnSpireFloorEnemies(p, session, cleared + 1)
					end
				end
			end
		end
	end
end

-- ============================================================================
-- 16. #121 - SMOOTH SKY-GEYSER UPDRAFT RESCUE (G.OnVoidRescue)
-- ============================================================================
local function handleVoidRescue(p, r, rt, profile)
	if not p or not r or not rt then
		return false
	end
	local _, h = root(p)
	if rt.SeatedInShip or (h and h.SeatPart) then
		rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, os.clock() + 2.5)
		rt.Safe = r.Position
		rt.MoveAt = os.clock()
		return true
	end
	local now = os.clock()
	if now < (rt.VoidRescueActiveUntil or 0) then
		return true
	end
	rt.VoidRescueActiveUntil = now + 1.6

	local safePos = (G.FindSafeRescuePos and G.FindSafeRescuePos(p, r.Position, rt, profile)) or C.Spawn
	rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, now + 2.5)
	rt.InvincibleUntil = math.max(rt.InvincibleUntil or 0, now + 2.2)

	local geyser = Instance.new("Part")
	geyser.Name = "CloudGeyserUpdraft"
	geyser.Shape = Enum.PartType.Cylinder
	geyser.Size = Vector3.new(26, 9, 9)
	geyser.CFrame = CFrame.new(r.Position.X, math.max(-8, r.Position.Y) + 8, r.Position.Z) * CFrame.Angles(0, 0, math.pi / 2)
	geyser.Color = Color3.fromRGB(130, 240, 255)
	geyser.Material = Enum.Material.Neon
	geyser.Transparency = 0.48
	geyser.Anchored, geyser.CanCollide, geyser.CanQuery, geyser.CanTouch = true, false, false, false
	geyser.Parent = getTempFX()
	Debris:AddItem(geyser, 1.2)

	if R and R:FindFirstChild("CombatFX") then
		R.CombatFX:FireAllClients({
			Kind = "CloudGeyserRescue",
			Position = r.Position,
			TargetPos = safePos,
			Actor = p.UserId,
		})
	end

	local launchStart = Vector3.new(r.Position.X, math.max(-12, r.Position.Y), r.Position.Z)
	G.LaunchPlayer(p, launchStart, safePos, 38, 1.1)

	if now >= (rt.NextVoidNotify or 0) then
		rt.NextVoidNotify = now + 2.6
		G.Notify(p, "LUỒNG KHÍ MÂY AETHER: Mạch phun gió đã nâng bạn trở lại đảo mây an toàn!")
	end
	return true
end

-- ============================================================================
-- 17. UI REQUEST ROUTER & HOOK CHAINING INIT
-- ============================================================================
local WAVE3_WORLD_COMMANDS = {
	SpawnShip = true,
	SpawnWarship = true,
	FireShipCannon = true,
	VoteRaidDifficulty = true,
	StartRaid = true,
	StartAwakeningRaid = true,
	EnterSkySpire = true,
	LeaveSkySpire = true,
	ResetDPSDummy = true,
}

local WorldCmdDedup: { [Player]: { [string]: number } } = {}

local function restoreCryonChilledPlayers()
	for _, plr in ipairs(Players:GetPlayers()) do
		local _, ph = root(plr)
		local prof = D.Get(plr)
		local prt = G.Runtime and G.Runtime[plr]
		if ph and (not prt or not prt.IsDowned) then
			local baseSpd = (prof and C.Classes[prof.ClassId] and C.Classes[prof.ClassId].Speed) or 18
			if ph.WalkSpeed < baseSpd then
				ph.WalkSpeed = baseSpd
			end
		end
	end
end

function WorldEvents.HandleUIRequest(p, cmd, payload)
	if not p or type(cmd) ~= "string" or not WAVE3_WORLD_COMMANDS[cmd] then
		return false
	end
	local now = os.clock()
	local pMap = WorldCmdDedup[p]
	if not pMap then
		pMap = {}
		WorldCmdDedup[p] = pMap
	end
	local canonicalCmd = (cmd == "SpawnWarship" and "SpawnShip") or (cmd == "StartAwakeningRaid" and "StartRaid") or cmd
	if (now - (pMap[canonicalCmd] or 0)) < 0.25 then
		return true
	end
	pMap[canonicalCmd] = now

	payload = type(payload) == "table" and payload or { value = payload }
	if canonicalCmd == "SpawnShip" then
		WorldEvents.SpawnWarship(p, payload.shipId or payload.id or payload.value, payload.spawnPos, payload.autoBoard ~= false)
		G.Sync(p)
		return true
	elseif canonicalCmd == "FireShipCannon" then
		local entry = ActiveWarships[p] or (G.Runtime[p] and G.Runtime[p].ActiveShipEntry)
		if entry then
			fireBroadsideCannon(p, entry, tostring(payload.side or "Both"))
		else
			G.Notify(p, "Hãy triệu hồi hoặc lên Chiến Hạm 3D trước khi khai hỏa Đại Bác!")
		end
		return true
	elseif canonicalCmd == "VoteRaidDifficulty" then
		WorldEvents.VoteRaidDifficulty(p, payload.difficulty or payload.id or payload.value)
		return true
	elseif canonicalCmd == "StartRaid" then
		WorldEvents.StartMicrochipRaid(p, payload.difficulty)
		return true
	elseif canonicalCmd == "EnterSkySpire" then
		WorldEvents.EnterSkySpire(p, payload.floor)
		return true
	elseif canonicalCmd == "LeaveSkySpire" then
		return WorldEvents.LeaveSkySpire(p)
	elseif canonicalCmd == "ResetDPSDummy" then
		return WorldEvents.ResetDPSDummy(p)
	end
	return false
end

function WorldEvents.Init(gRef, dRef, wRef, cRef)
	if WorldEvents._initialized then
		return
	end
	WorldEvents._initialized = true

	G, D, W, C = gRef, dRef, wRef, cRef
	R = ReplicatedStorage:WaitForChild("Remotes")
	pcall(function()
		CombatData = require(ReplicatedStorage.Shared.SkybreakCombatData)
	end)

	ensureExtraEnemiesInConfig()
	getActiveShipsFolder()

	G.WorldEvents = WorldEvents
	G.SpawnTelegraph = spawn3DTelegraphZone
	G.BuildSkyShip = function(pOrShipId, spawnPos, customShipId)
		local isPlr = typeof(pOrShipId) == "Instance" and pOrShipId:IsA("Player")
		if isPlr then
			local ship = WorldEvents.SpawnWarship(pOrShipId, customShipId, spawnPos, false)
			return ship
		end
		local ship = WorldEvents.SpawnWarship(nil, customShipId or pOrShipId, spawnPos, false)
		return ship
	end
	G.SpawnWarship = WorldEvents.SpawnWarship
	G.SpawnMirageIsland = WorldEvents.SpawnMirageIsland
	G.SpawnSeaMonsterEvent = WorldEvents.SpawnSeaMonsterEvent
	G.RefreshPlayerShipBanner = WorldEvents.RefreshPlayerShipBanner
	G.OnVoidRescue = handleVoidRescue

	-- 1. Chain G.Hit (#71 Aureon 70% DR Twin Pylons, #19 ShieldVanguard 50% Frontal Guard & Guard Break, #70 DPS Dummy)
	local prevHit = G.Hit
	G.Hit = function(p, e, damage, breakPower, action)
		if not e or not e.Alive or not e.Model or not e.Model.Parent then
			return
		end
		local dmg = tonumber(damage) or 1
		local brk = tonumber(breakPower) or 8

		-- #73 Sanctuary ATK buff (+15% while standing in Purifying Light Sanctuary!)
		local pr = root(p)
		if pr and #ActivePurifyingZones > 0 then
			local now = os.clock()
			for _, zn in ipairs(ActivePurifyingZones) do
				if now < zn.ExpiresAt and flatDist(pr.Position, zn.Pos) <= zn.Radius then
					dmg = dmg * 1.15
					break
				end
			end
		end

		-- #19 ShieldVanguard directional frontal guard
		if e.Archetype == "ShieldVanguard" and e.FrontalGuardUntil and os.clock() < e.FrontalGuardUntil and e.Body and pr then
			local toPlayer = Vector3.new(pr.Position.X - e.Body.Position.X, 0, pr.Position.Z - e.Body.Position.Z)
			local isFrontal = toPlayer.Magnitude < 0.2 or (e.Body.CFrame.LookVector:Dot(toPlayer.Unit) > 0.1)
			if isFrontal then
				local isHeavyOrSkill = (action ~= nil and action ~= "Attack" and action ~= "Light" and action ~= "M1")
				if isHeavyOrSkill then
					e.FrontalGuardUntil = 0
					e.Model:SetAttribute("FrontalGuard", false)
					if e.GuardShieldPart and e.GuardShieldPart.Parent then
						e.GuardShieldPart.Transparency = 1
					end
					e.StunnedUntil = os.clock() + 2.2
					brk += 35
					dmg = dmg * 1.25
					G.FireCombatEvent({
						kind = "DamageNumber",
						pos = e.Body.Position + Vector3.new(0, 2.8, 0),
						amount = math.floor(dmg),
						crit = true,
						element = "Sky",
						Text = "GUARD BREAK!",
					})
				else
					dmg = dmg * 0.50
				end
			end
		end

		-- #70 DPS Training Dummy never dies & updates live 3D DPS meter
		if e.IsDPSDummy then
			local beforeHP = e.HP
			prevHit(p, e, dmg, 0, action)
			local dealt = math.max(1, beforeHP - e.HP)
			if e.HP <= 500000 then
				e.HP = e.MaxHP
			end
			updateDPSDummyOnHit(dealt)
			return
		end

		-- #71 Aureon Twin Solar Pylons: grant exact 70% DR (30% damage taken) instead of 100% immunity block!
		if e.Id == "AureonSentinel" and e.SolarAegis70 then
			dmg = dmg * 0.30
			local savedShield = e.Shield
			e.Shield = false
			prevHit(p, e, dmg, brk * 0.3, action)
			if e.Alive and e.SolarAegis70 then
				e.Shield = savedShield
			end
			return
		end

		prevHit(p, e, dmg, brk, action)

		-- Trigger #71 Twin Solar Pylons when Aureon drops <= 60% HP (or hits 65% G.Boss clamp)
		if e.Alive and e.Id == "AureonSentinel" and not e.TwinSolarPylonsSpawned then
			local threshold = (e == G.Boss) and 0.65 or 0.60
			if e.HP <= e.MaxHP * threshold then
				spawnAureonTwinSolarPylons(e)
			end
		end
	end

	-- 2. Chain G.PlayerDamage (#20 Kairo 15% MaxHP Barrier absorption + Taunt DR, #119 Co-op Raid Revive Beacon)
	local prevPlayerDamage = G.PlayerDamage
	G.PlayerDamage = function(p, amount, attackerEnemy)
		local r, h = root(p)
		local rt = G.Runtime[p]
		local prof = D.Get(p)
		if not r or not h or not rt or rt.IsDowned then
			return
		end
		local dmg = tonumber(amount) or 1

		-- Kairo Taunt reduces enemy damage to player by 20%
		if attackerEnemy and attackerEnemy.KairoTauntedUntil and os.clock() < attackerEnemy.KairoTauntedUntil then
			dmg = dmg * 0.80
		end

		-- Kairo 15% MaxHP Golden Barrier absorption
		if (rt.CompanionBarrierHP or 0) > 0 and os.clock() < (rt.CompanionBarrierUntil or 0) then
			local absorbed = math.min(rt.CompanionBarrierHP, math.floor(dmg))
			rt.CompanionBarrierHP -= absorbed
			dmg -= absorbed
			p:SetAttribute("KairoBarrierHP", rt.CompanionBarrierHP)
			if dmg <= 0 then
				G.FireCombatEvent({
					kind = "DamageNumber",
					pos = r.Position + Vector3.new(0, 2.5, 0),
					amount = 0,
					crit = false,
					element = "Sky",
					Text = "KAIRO SHIELD!",
				})
				return
			end
		end

		local preHP = h.Health
		prevPlayerDamage(p, dmg, attackerEnemy)
		if h.Parent and h.Health <= 1 and preHP > 1 then
			tryEnterCoopDownedState(p, r, h, rt, prof)
		end
	end

	-- 3. Chain G.Kill (#75 LeviathanHeart, #76 Pirate Raid Fruit Drop, #77 MVP Summary, #78 Magnetic Orbs, #79 Respawn Hologram, #74 Ritual Reset)
	local prevKill = G.Kill
	G.Kill = function(e)
		if not e or not e.Alive then
			return
		end
		local wasBoss = isBossEnemy(e)
		local wasElite = (e.Config and e.Config.Elite == true) or e.Id == "TerrorSkyShark" or e.Id == "GoldenKnight" or e.Id == "AbyssalKnight"
		local deathPos = (e.Body and e.Body.Position) or e.Home or Vector3.zero
		local contribsCopy = {}
		local topPlr, topTime, topDmg = nil, -1, -1
		for plr, hit in pairs(e.Contributors or {}) do
			local dVal = type(hit) == "table" and (hit.Damage or 0) or (tonumber(hit) or 0)
			local tVal = type(hit) == "table" and (hit.Time or 0) or 0
			contribsCopy[plr] = { Damage = dVal, Time = tVal }
			if typeof(plr) == "Instance" and plr:IsA("Player") and plr.Parent == Players then
				if tVal > topTime or (tVal == topTime and dVal > topDmg) then
					topTime = tVal
					topDmg = dVal
					topPlr = plr
				end
			end
		end

		prevKill(e)

		-- Restore chilled player WalkSpeed if CryonPrime died while CryonShieldActive was active
		if e.Id == "CryonPrime" then
			restoreCryonChilledPlayers()
		end

		-- Clean up Noxar light pillars if Noxar died
		if e.LightPillarModels then
			for _, lm in ipairs(e.LightPillarModels) do
				if lm and lm.Parent then
					lm:Destroy()
				end
			end
			e.LightPillarModels = nil
		end

		-- #74 SoulReaperRift ritual cooldown reset
		if e.IsRitualBoss then
			SoulRitualState.Boss = nil
			SoulRitualState.Torches = { false, false, false }
			SoulRitualState.ResetAt = os.clock() + 30
			if SoulRitualState.RefreshUI then
				pcall(SoulRitualState.RefreshUI)
			end
		end

		-- #75 Defeating AbyssalLeviathan spawns towable 3D LeviathanHeart!
		if e.Id == "AbyssalLeviathan" then
			spawnLeviathanHeartRelic(deathPos, topPlr)
		end

		-- #76 Pirate Raid Siege Commander awards guaranteed random 3D Devil Fruit!
		if e.IsPirateRaidCommander and topPlr and topPlr.Parent == Players then
			local wonFruit = ALL_CANONICAL_FRUITS[math.random(1, #ALL_CANONICAL_FRUITS)]
			local prof = D.Get(topPlr)
			if prof then
				prof.StoredFruits = prof.StoredFruits or {}
				prof.StoredFruits[wonFruit] = (prof.StoredFruits[wonFruit] or 0) + 1
				prof.HeldFruit = wonFruit
				local fName = (C.AetherFruits and C.AetherFruits[wonFruit] and C.AetherFruits[wonFruit].Name) or wonFruit
				G.Notify(topPlr, "CHIẾN LỢI PHẨM PIRATE RAID: Bạn kết liễu Chỉ Huy Hải Tặc và nhận được Trái Ác Quỷ 3D [" .. fName .. "]!")
				G.Sync(topPlr)
				broadcastWorldBanner(
					"CHIẾN THẮNG PIRATE RAID!",
					topPlr.Name .. " đã hạ gục Chỉ Huy Hải Tặc tại Castle on the Void và nhận Trái Ác Quỷ [" .. fName .. "]!",
					"Fruit"
				)
				if R and R:FindFirstChild("StateUpdate") then
					R.StateUpdate:FireAllClients({
						LootFeed = {
							Player = topPlr.Name,
							Item = fName,
							Rarity = "Legendary",
							Source = "Pirate Raid",
						},
					})
				end
			end
		end

		-- #77 MVP #1/#2/#3 Summary + #78 3D Magnetic Loot Orbs + #79 3D Boss Respawn Hologram
		if wasBoss then
			local isMythic = (e.Id == "AbyssalLeviathan" or e.Id == "SoulReaperRift" or e.Id == "Noxar" or e.Id == "Veyr" or e.IsRaidBoss)
			if not e.IsRaidDungeonMob and not e.IsSpireMob then
				broadcastMVPSummary((e.Config and e.Config.Name) or e.Id, contribsCopy, isMythic and 1.35 or 1.0)
			end
			spawnMagneticLootOrbs(deathPos, contribsCopy, isMythic)

			if not e.IsRaidDungeonMob and not e.IsSpireMob and not e.IsSeaEventMonster and not e.IsPirateRaidCommander and not e.IsRitualBoss then
				local respawnSec = (e == G.Boss) and 15 or 55
				spawnBossRespawnHologram(e.Id, e.Config, e.Home or deathPos, respawnSec)
			end
		elseif wasElite then
			spawnMagneticLootOrbs(deathPos, contribsCopy, false)
		end
	end

	-- 4. Chain G.TickEnemy (#18 Multi-Phase 65%/30% + 1.18x/1.32x + 3D Telegraphs, #71/#72/#73 Boss Mechanics, #19 3-Role Regular AI, #21 Sea Monsters)
	local prevTickEnemy = G.TickEnemy
	G.TickEnemy = function(e, dt)
		if not e or not e.Alive or not e.Model or not e.Model.Parent then
			return
		end
		local now = os.clock()

		if isBossEnemy(e) then
			local ratio = e.HP / math.max(1, e.MaxHP)
			local newPhase = (ratio >= 0.65) and 1 or ((ratio >= 0.30) and 2 or 3)
			if (e.Wave3Phase or 1) ~= newPhase then
				e.Wave3Phase = newPhase
				e.Phase = newPhase
				e.Model:SetAttribute("BossPhase", newPhase)
				if not e.BaseSpeed then
					e.BaseSpeed = (e.Config and e.Config.Speed) or 16
				end
				e.Config = table.clone(e.Config)
				e.Config.Speed = math.floor(e.BaseSpeed * ((newPhase == 3) and 1.32 or ((newPhase == 2) and 1.18 or 1.0)))

				if e.Body then
					local pLabel = (newPhase == 3) and "PHASE 3 CUỒNG NỘ (1.32x Tốc Độ & Tuyệt Kỹ Liên Hoàn)" or "PHASE 2 THỨC TỈNH (1.18x Tốc Độ & Cơ Chế Mới)"
					notifyNearbyPlayers(e.Body.Position, 125, "[BOSS] " .. tostring(e.Config.Name or e.Id) .. " chuyển sang " .. pLabel .. "!")
				end

				if e.Id == "CryonPrime" and newPhase >= 2 then
					spawnCryonResonancePillars(e, "Phase " .. tostring(newPhase))
				elseif e.Id == "Noxar" and newPhase >= 2 and not e.NoxarDomainActive then
					spawnNoxarDomainAndLightPillars(e)
				end
			elseif e.Model:GetAttribute("BossPhase") ~= newPhase then
				e.Model:SetAttribute("BossPhase", newPhase)
			end

			-- #71 Aureon Twin Solar Pylons check -> immediate 100% Break Kneel when both shatter!
			if e.Id == "AureonSentinel" and e.SolarAegis70 then
				local alivePylons = 0
				for _, py in ipairs(e.TwinPylons or {}) do
					if py.Alive and py.Model and py.Model.Parent then
						alivePylons += 1
					end
				end
				if alivePylons == 0 then
					triggerBossKneelBreak(e, 4.5, "[BREAK 100%] Hai Trụ Thái Dương đã vỡ tan! Aureon Sentinel quỳ gối choáng 4.5 giây!")
				end
			end

			-- #72 CryonPrime 18s Resonance Arena Freeze check
			if e.Id == "CryonPrime" and e.CryonShieldActive then
				local alivePillars = 0
				for _, cp in ipairs(e.ActiveCryonPillars or {}) do
					if cp.Alive and cp.Model and cp.Model.Parent then
						alivePillars += 1
					end
				end
				if alivePillars == 0 then
					restoreCryonChilledPlayers()
					triggerBossKneelBreak(e, 4.8, "[BREAK 100%] 3 Cột Băng Vĩnh Cửu đã vỡ vụn! Khiên Băng tan vỡ, Cryon Prime bị choáng!")
				elseif now >= (e.CryonFreezeDeadline or 0) then
					e.CryonShieldActive = false
					e.Shield = false
					e.Model:SetAttribute("Shielded", false)
					restoreCryonChilledPlayers()
					for _, cp in ipairs(e.ActiveCryonPillars or {}) do
						if cp.Alive then
							cp.Alive = false
							if cp.Model and cp.Model.Parent then
								cp.Model:Destroy()
							end
						end
					end
					if e.Body then
						fireTelegraphAttack(e, e.Body.Position, 30, 1.25, (e.Config.ATK or 65) * 1.65, "ABSOLUTE ZERO DETONATION", "Circle", nil, Color3.fromRGB(82, 232, 255))
					end
				elseif now >= (e.NextCryonChillAt or 0) and e.Body then
					e.NextCryonChillAt = now + 1.2
					for _, plr in ipairs(Players:GetPlayers()) do
						local pr, ph = root(plr)
						local prof = D.Get(plr)
						if pr and ph and dist(pr.Position, e.Body.Position) <= 52 then
							local baseSpd = (prof and C.Classes[prof.ClassId] and C.Classes[prof.ClassId].Speed) or 18
							ph.WalkSpeed = math.max(10, math.floor(baseSpd * 0.70))
							G.PlayerDamage(plr, math.max(6, math.floor((e.Config.ATK or 40) * 0.18)), e)
						end
					end
				end
			end

			-- #73 Noxar Void DoT outside Purifying Light Sanctuaries
			if e.Id == "Noxar" and e.NoxarDomainActive and e.Body then
				if e.NoxarDomainShield and (not e.ActiveVoidCore or not e.ActiveVoidCore.Alive) then
					triggerBossKneelBreak(e, 4.5, "[BREAK 100%] Lõi Hư Không NoxarVoidFX đã tan vỡ! Noxar bị choáng!")
				end
				if now >= (e.NextVoidDomainTick or 0) then
					e.NextVoidDomainTick = now + 1.6
					for _, plr in ipairs(Players:GetPlayers()) do
						local pr = root(plr)
						local prt = G.Runtime[plr]
						if pr and prt and dist(pr.Position, e.Body.Position) <= 65 then
							local inSafeSanctuary = false
							for _, zn in ipairs(ActivePurifyingZones) do
								if now < zn.ExpiresAt and flatDist(pr.Position, zn.Pos) <= zn.Radius then
									inSafeSanctuary = true
									break
								end
							end
							if not inSafeSanctuary then
								prt.VoidDoTStacks = math.min(6, (prt.VoidDoTStacks or 0) + 1)
								plr:SetAttribute("VoidDoTStacks", prt.VoidDoTStacks)
								G.PlayerDamage(plr, math.max(8, prt.VoidDoTStacks * 14), e)
							end
						end
					end
				end
			end

			-- #18 & #21 Boss / Sea Monster 3D Ground Telegraph Heavy Attacks (1.1s-1.6s windup)
			if e.Body and now >= (e.NextWave3BossPattern or 0) and now >= (e.StunnedUntil or 0) then
				local phase = e.Wave3Phase or 1
				local cd = (phase == 3) and 5.2 or ((phase == 2) and 6.4 or 7.8)
				e.NextWave3BossPattern = now + cd

				local nearestPlr, nearestPos, bestD = nil, nil, 130
				for _, plr in ipairs(Players:GetPlayers()) do
					local pr = root(plr)
					if pr then
						local d = dist(pr.Position, e.Body.Position)
						if d < bestD then
							bestD = d
							nearestPlr = plr
							nearestPos = pr.Position
						end
					end
				end

				if nearestPlr and nearestPos then
					local look = Vector3.new(nearestPos.X - e.Body.Position.X, 0, nearestPos.Z - e.Body.Position.Z)
					look = look.Magnitude > 0.1 and look.Unit or Vector3.new(0, 0, -1)
					local baseATK = (e.Config and e.Config.ATK) or 55
					local col = (e.Config and e.Config.Element == "Frost") and Color3.fromRGB(82, 232, 255)
						or ((e.Config and e.Config.Element == "Void") and Color3.fromRGB(198, 86, 255) or Color3.fromRGB(255, 196, 76))

					if e.Id == "AbyssalLeviathan" or e.Id == "SkySeaBeast" then
						fireTelegraphAttack(e, e.Body.Position, 22, 1.35, baseATK * 1.45, "HYDRO ABYSSAL BEAM", "Laser", look, col)
						if phase >= 2 then
							fireTelegraphAttack(e, nearestPos, 15, 1.45, baseATK * 1.25, "MAELSTROM SLAM", "Circle", nil, col)
						end
					else
						if phase == 1 then
							fireTelegraphAttack(e, nearestPos, 13, 1.35, baseATK * 1.25, "HEAVY AOE SLAM", "Circle", nil, col)
						elseif phase == 2 then
							fireTelegraphAttack(e, e.Body.Position, 18, 1.25, baseATK * 1.35, "AETHER CLEAVE BEAM", "Laser", look, col)
							fireTelegraphAttack(e, nearestPos, 12, 1.45, baseATK * 1.15, "RESONANCE BURST", "Circle", nil, col)
						else
							fireTelegraphAttack(e, e.Body.Position, 20, 1.15, baseATK * 1.50, "CATACLYSM LASER", "Laser", look, col)
							local perp = Vector3.new(-look.Z, 0, look.X)
							fireTelegraphAttack(e, nearestPos + perp * 9, 10, 1.30, baseATK * 1.20, "PHASE 3 RIFT", "Circle", nil, col)
							fireTelegraphAttack(e, nearestPos - perp * 9, 10, 1.30, baseATK * 1.20, "PHASE 3 RIFT", "Circle", nil, col)
						end
					end
				end
			end
		else
			if tickRegularArchetypeAndLeash(e, dt) then
				return
			end
		end

		prevTickEnemy(e, dt)
	end

	-- 6. Chain G.Equipment so StartAwakeningRaid & SpawnSkyShip route into Wave 3 systems
	local prevEquipment = G.Equipment
	G.Equipment = function(p, payload)
		if type(payload) == "table" then
			if payload.action == "StartAwakeningRaid" then
				WorldEvents.StartMicrochipRaid(p, payload.difficulty)
				return
			elseif payload.action == "SpawnSkyShip" then
				WorldEvents.SpawnWarship(p, payload.shipId, payload.dockPos, true)
				G.Sync(p)
				return
			elseif payload.action == "SpawnSeaEvent" or payload.action == "SummonLeviathan" then
				local mId = (payload.action == "SummonLeviathan" or payload.bossId == "AbyssalLeviathan") and "AbyssalLeviathan" or (payload.bossId or "SkySeaBeast")
				WorldEvents.SpawnSeaMonsterEvent(p, mId)
				return
			end
		end
		return prevEquipment(p, payload)
	end

	-- 7. Chain G.OnBeforeSync to expose Spire, LeviathanHearts, DangerLevel, Raid & Ship state
	local LEGACY_TITLE_MIGRATION = {
		["Spire Challenger"] = "spire_challenger",
		["Spire Ascendant"] = "spire_ascendant",
		["Sky Spire Sovereign"] = "sky_spire_sovereign",
		["Leviathan Slayer"] = "leviathan_slayer",
	}
	local prevBeforeSync = G.OnBeforeSync
	G.OnBeforeSync = function(p, profile, rt, s, statePayload)
		if type(profile.UnlockedTitles) == "table" then
			for oldKey, newKey in pairs(LEGACY_TITLE_MIGRATION) do
				if profile.UnlockedTitles[oldKey] then
					profile.UnlockedTitles[newKey] = true
					profile.UnlockedTitles[oldKey] = nil
				end
			end
		end
		if LEGACY_TITLE_MIGRATION[profile.Title] then
			profile.Title = LEGACY_TITLE_MIGRATION[profile.Title]
		end
		if prevBeforeSync then
			prevBeforeSync(p, profile, rt, s, statePayload)
		end
		statePayload.HighestSpireFloor = profile.HighestSpireFloor or 0
		statePayload.LeviathanHearts = profile.LeviathanHearts or 0
		statePayload.SeaDangerLevel = p:GetAttribute("SeaDangerLevel") or 1
		statePayload.RaidActive = p:GetAttribute("RaidActive") == true
		statePayload.RaidWave = p:GetAttribute("RaidWave") or 0
		statePayload.RaidTimer = p:GetAttribute("RaidTimer") or 0
		statePayload.RaidDifficulty = p:GetAttribute("RaidDifficulty") or "Normal"
		statePayload.SpireFloor = p:GetAttribute("SpireFloor") or 0
		statePayload.ActiveShip = normalizeShipId(profile.ActiveShip)
	end

	-- 8. Chain G.HandleUIRequest + listen on R.UIRequest for Wave 3 World commands
	local prevHandleUI = G.HandleUIRequest
	G.HandleUIRequest = function(p, cmd, payload)
		if prevHandleUI and prevHandleUI(p, cmd, payload) then
			return true
		end
		return WorldEvents.HandleUIRequest(p, cmd, payload)
	end
	if R:FindFirstChild("UIRequest") then
		R.UIRequest.OnServerEvent:Connect(function(p, cmd, payload)
			if type(cmd) == "table" then
				payload = cmd
				cmd = payload.command or payload.action or payload.cmd
			end
			if type(cmd) == "string" and WAVE3_WORLD_COMMANDS[cmd] then
				WorldEvents.HandleUIRequest(p, cmd, payload)
			end
		end)
	end

	Players.PlayerRemoving:Connect(function(p)
		WorldCmdDedup[p] = nil
		for _, he in ipairs(ActiveLeviathanHearts) do
			if he.TowedByPlayer == p or (he.TowedByShip and he.TowedByShip.Owner == p) then
				detachLeviathanHeartTow(he)
			end
		end
		if ActiveWarships[p] then
			if ActiveWarships[p].Model and ActiveWarships[p].Model.Parent then
				ActiveWarships[p].Model:Destroy()
			end
			ActiveWarships[p] = nil
		end
		cleanupSpireSession(p, false)
		if ActiveRaidSession then
			if ActiveRaidSession.DamageMap then
				ActiveRaidSession.DamageMap[p] = nil
			end
			local kept = {}
			for _, member in ipairs(ActiveRaidSession.Players or {}) do
				if member ~= p and member.Parent == Players then
					table.insert(kept, member)
				end
			end
			ActiveRaidSession.Players = kept
			if ActiveRaidSession.Leader == p then
				ActiveRaidSession.Leader = kept[1]
			end
			if #kept == 0 then
				endRaidSession(false, nil)
			end
		end
	end)

	-- Build 3D World Objects for Tasks #74, #76, #22, #80, #70, #23/#115
	pcall(buildSoulReaperRitualSet)
	pcall(buildPirateRaidHornBeacon)
	pcall(ensureRaidArenaPlatforms)
	pcall(ensureSkySpirePortalAndArena)
	pcall(buildDPSTrainingDummy)
	pcall(buildHarborShipwrights)

	-- Heartbeat physics loop for 3D Warships & Towed LeviathanHearts
	RunService.Heartbeat:Connect(function(dt)
		local clamped = math.min(0.1, dt)
		tickActiveWarships(clamped)
		tickLeviathanHearts(clamped)
		if ActiveMirageEvent and ActiveMirageEvent.Gear and ActiveMirageEvent.Gear.Parent then
			ActiveMirageEvent.Gear.CFrame = ActiveMirageEvent.Gear.CFrame * CFrame.Angles(0, clamped * 1.9, 0)
		end
	end)

	-- 1s Strategic World Event Loop (Sea Danger 1-6, Raid Timer, Spire Floors, Respawn Holograms, DPS Dummy, Scheduled Mirage & Pirate Raid)
	task.spawn(function()
		local nextAutoMirage = os.clock() + 1200
		local nextAutoPirateRaid = os.clock() + 840
		while true do
			task.wait(1.0)
			local now = os.clock()
			pcall(tickSeaDangerAndDynamicEncounters)
			pcall(tickRaidDungeon)
			pcall(tickSkySpireSessions)
			pcall(tickBossRespawnHolograms, 1.0)
			pcall(tickDPSDummy)
			if SoulRitualState.Boss and (not SoulRitualState.Boss.Alive or not SoulRitualState.Boss.Model or not SoulRitualState.Boss.Model.Parent) then
				SoulRitualState.Boss = nil
				SoulRitualState.Torches = { false, false, false }
				if SoulRitualState.RefreshUI then
					pcall(SoulRitualState.RefreshUI)
				end
			end

			-- Clean up expired Purifying Light Sanctuaries
			for i = #ActivePurifyingZones, 1, -1 do
				if now >= ActivePurifyingZones[i].ExpiresAt then
					table.remove(ActivePurifyingZones, i)
				end
			end

			-- Despawn MirageSkyIsland after 15 minutes
			if ActiveMirageEvent and now >= ActiveMirageEvent.ExpiresClock then
				if ActiveMirageEvent.Model and ActiveMirageEvent.Model.Parent then
					ActiveMirageEvent.Model:Destroy()
				end
				ActiveMirageEvent = nil
				workspace:SetAttribute("MirageIslandActive", false)
			end

			if now >= nextAutoMirage and not ActiveMirageEvent then
				local plrs = Players:GetPlayers()
				if #plrs > 0 then
					nextAutoMirage = now + 1200
					pcall(WorldEvents.SpawnMirageIsland, plrs[math.random(1, #plrs)])
				end
			end

			if now >= nextAutoPirateRaid then
				for _, plr in ipairs(Players:GetPlayers()) do
					if plr:GetAttribute("CurrentRealm") == "ShadowRealm" then
						nextAutoPirateRaid = now + 840
						pcall(WorldEvents.StartPirateRaidSiege, plr)
						break
					end
				end
			end
		end
	end)
end

return WorldEvents
