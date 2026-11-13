-- SkybreakSkillMechanicsService.lua
-- Authoritative Server Mechanical Execution Engine for SKYBREAK Stage 1:
-- 4-Slot M1 Archetypes (8 Martial Styles, 5 Melee Weapon Archetypes, 5 Gun Archetypes),
-- 20 Distinct Mechanical Skill Solvers across 12 Aether Cores (V1 + Awakened V2 + Dragon 3-Tier),
-- Persistent Ground Hazard Zones (max 3 per player), Cryo Shatter & Wall-Slam Synergies,
-- and Real Ground-Surface Raycast Metadata for Client Choreography & VFX.

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Mechanics = {}

local C, D, G, W, R, CombatData
local ensureExpansionProfile
local ensureRuntimeFields
local checkMoveMasteryUnlock
local getMasteryLevel
local addMasteryXP
local applyCryoFreeze
local applyBurnOrDoT
local pullEnemyToward
local isBossEnemy
local groundYAt
local clampAimRay
local ensureWorldFolder
local executePortalMoveC
local executeDragonFuryMoveV

local SharedBlueprints = nil
local SharedBlueprintsCheckedAt = 0

-- Active hazard zones per player (capped at MAX_HAZARDS_PER_PLAYER = 3)
local MAX_HAZARDS_PER_PLAYER = 3
local PlayerHazards = {}

-- Rule 3: Complete Canonical + Legacy Alias Map for all 12 Aether Cores
local CORE_ALIASES = {
	gale = "GaleCore",
	gale_core = "GaleCore",
	galecore = "GaleCore",
	sand = "SandstoneCore",
	smoke = "SandstoneCore",
	sandstone = "SandstoneCore",
	sandstone_core = "SandstoneCore",
	sandstonecore = "SandstoneCore",
	flame = "SolarFlameCore",
	solar_flame = "SolarFlameCore",
	solarflamecore = "SolarFlameCore",
	ice = "GlacierIceCore",
	frostbite = "GlacierIceCore",
	glacier_ice = "GlacierIceCore",
	glaciericecore = "GlacierIceCore",
	light = "CelestialLightCore",
	celestial_light = "CelestialLightCore",
	celestiallightcore = "CelestialLightCore",
	magma = "StarforgedMagmaCore",
	starforged_magma = "StarforgedMagmaCore",
	starforgedmagmacore = "StarforgedMagmaCore",
	rumble = "ThunderRumbleCore",
	thunder = "ThunderRumbleCore",
	thunder_rumble = "ThunderRumbleCore",
	thunderrumblecore = "ThunderRumbleCore",
	gravity = "AstralGravityCore",
	astral_gravity = "AstralGravityCore",
	astralgravitycore = "AstralGravityCore",
	portal = "DimensionalPortalCore",
	dimensional_portal = "DimensionalPortalCore",
	dimensionalportalcore = "DimensionalPortalCore",
	buddha = "SolarTitanCore",
	quake = "SolarTitanCore",
	starlight_quake = "SolarTitanCore",
	starlightquakecore = "SolarTitanCore",
	solar_titan = "SolarTitanCore",
	solartitancore = "SolarTitanCore",
	dough = "AetherflowCore",
	sweetdoughcore = "AetherflowCore",
	sweet_dough = "AetherflowCore",
	mochi = "AetherflowCore",
	aetherflow = "AetherflowCore",
	aetherflowcore = "AetherflowCore",
	dragon = "AbyssalSovereignCore",
	abyssal_dragon = "AbyssalSovereignCore",
	void_dragon = "AbyssalSovereignCore",
	abyssal_sovereign = "AbyssalSovereignCore",
	abyssalsovereigncore = "AbyssalSovereignCore",
}

local CANONICAL_CORES = {
	GaleCore = true,
	SandstoneCore = true,
	SolarFlameCore = true,
	GlacierIceCore = true,
	CelestialLightCore = true,
	StarforgedMagmaCore = true,
	ThunderRumbleCore = true,
	AstralGravityCore = true,
	DimensionalPortalCore = true,
	SolarTitanCore = true,
	AetherflowCore = true,
	AbyssalSovereignCore = true,
}

-- Rule 2: Explicit True-Flight Whitelist (ONLY these 6 Cores + Dragon Tier 2)
local TRUE_FLIGHT_CORES = {
	GaleCore = true,
	SandstoneCore = true,
	SolarFlameCore = true,
	CelestialLightCore = true,
	StarforgedMagmaCore = true,
	AstralGravityCore = true,
}

-- Weapon Archetype Lookup across Config.Swords & ArsenalExpansionConfig
local WEAPON_ARCHETYPE_MAP = {
	starter_sword = "Katana",
	dawnbringer_sword = "Katana",
	Dawnbringer = "Katana",
	saber_of_aureon = "Katana",
	cryon_frostblade = "Katana",
	EternalFrost = "Katana",
	yamo_voidblade = "Katana",
	iron_saber = "Katana",
	aether_katana = "Katana",
	sol_blade = "Katana",
	storm_katana = "Katana",
	Stormfang = "Katana",
	cyber_katana_mk2 = "Katana",
	sylvaris_thornblade = "Katana",
	noxar_greatsword = "Greatsword",
	noxar_abyssal_greatsword = "Greatsword",
	abyssal_greatsword = "Greatsword",
	dragon_cleaver = "Greatsword",
	ignivar_magma_breaker = "Greatsword",
	ArchitectsSeverance = "Greatsword",
	starter_daggers = "DualBlades",
	stormfang_daggers = "DualBlades",
	cursed_dual_skyblades = "DualBlades",
	dual_eclipse = "DualBlades",
	twin_fang_daggers = "DualBlades",
	starter_staff = "Spear",
	astral_staff = "Spear",
	sky_halberd = "Spear",
	tempest_trident = "Spear",
	sunshard_halberd = "Spear",
	nerith_abyssal_trident = "Spear",
	void_reaper_scythe = "Scythe",
	aion_chrono_scythe = "Scythe",
}

-- Gun Archetype Lookup across Config.Guns, CombatData.GunSpecs & ArsenalExpansionConfig
local GUN_ARCHETYPE_MAP = {
	aether_flintlock = "PistolRifle",
	aion_chrono_pistols = "PistolRifle",
	bizarre_rifle_cyber = "PistolRifle",
	cryo_railgun = "Railgun",
	magma_blaster = "Cannon",
	ignivar_hellcannon = "Cannon",
	veyr_singularity_cannon = "Cannon",
	soul_guitar_void = "VoidLyre",
	solar_kabucha = "Bow",
	storm_longbow = "Bow",
	kabucha_wind = "Bow",
	sylvaris_thornbow = "Bow",
}

local SHATTER_ELEMENTS = {
	Flame = true,
	Magma = true,
	Solar = true,
	Gravity = true,
	Titan = true,
	Earth = true,
	VoidMagma = true,
	Dragon = true,
}

local HAZARD_COLORS = {
	MagmaPool = Color3.fromRGB(255, 86, 24),
	SolarFlare = Color3.fromRGB(255, 178, 48),
	FrostSheet = Color3.fromRGB(115, 228, 255),
	StormCage = Color3.fromRGB(88, 194, 255),
	ChronoField = Color3.fromRGB(172, 122, 255),
	Quicksand = Color3.fromRGB(224, 186, 110),
	GravityWell = Color3.fromRGB(148, 86, 255),
}

local ELEMENT_COLORS = {
	Sky = Color3.fromRGB(120, 224, 255),
	Gale = Color3.fromRGB(126, 240, 214),
	Sand = Color3.fromRGB(230, 192, 118),
	Smoke = Color3.fromRGB(212, 198, 168),
	Flame = Color3.fromRGB(255, 124, 42),
	Ice = Color3.fromRGB(116, 228, 255),
	Cryo = Color3.fromRGB(116, 228, 255),
	Lightning = Color3.fromRGB(92, 196, 255),
	Storm = Color3.fromRGB(92, 196, 255),
	Light = Color3.fromRGB(255, 232, 116),
	Solar = Color3.fromRGB(255, 214, 92),
	Magma = Color3.fromRGB(255, 78, 28),
	Gravity = Color3.fromRGB(168, 96, 255),
	Portal = Color3.fromRGB(92, 168, 255),
	Chrono = Color3.fromRGB(176, 132, 255),
	Dough = Color3.fromRGB(255, 218, 142),
	Aether = Color3.fromRGB(118, 214, 255),
	Dragon = Color3.fromRGB(255, 102, 54),
	Void = Color3.fromRGB(196, 76, 255),
	Blood = Color3.fromRGB(244, 63, 94),
	Water = Color3.fromRGB(64, 182, 255),
}

local function getSharedBlueprints()
	if SharedBlueprints then
		return SharedBlueprints
	end
	if CombatData and type(CombatData.SkillBlueprints) == "table" then
		SharedBlueprints = CombatData.SkillBlueprints
		return SharedBlueprints
	end
	local now = os.clock()
	if now - SharedBlueprintsCheckedAt < 1.0 then
		return nil
	end
	SharedBlueprintsCheckedAt = now
	local ok, mod = pcall(function()
		local shared = ReplicatedStorage:FindFirstChild("Shared")
		local bpMod = shared and shared:FindFirstChild("SkybreakSkillBlueprints")
		if bpMod then
			return require(bpMod)
		end
		return nil
	end)
	if ok and type(mod) == "table" then
		SharedBlueprints = mod
	end
	return SharedBlueprints
end

local function getCharRoot(p)
	local ch = p and p.Character
	if not ch then
		return nil, nil, nil
	end
	local hrp = ch:FindFirstChild("HumanoidRootPart")
	local hum = ch:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then
		return nil, nil, nil
	end
	return hrp, hum, ch
end

function Mechanics.ResolveCoreId(rawId)
	local sbp = getSharedBlueprints()
	if sbp and type(sbp.ResolveCoreId) == "function" then
		local ok, res = pcall(sbp.ResolveCoreId, rawId)
		if ok and type(res) == "string" and res ~= "" then
			return res
		end
	end
	if CombatData and type(CombatData.ResolveFruitId) == "function" then
		local res = CombatData.ResolveFruitId(rawId)
		if type(res) == "string" and res ~= "" then
			return res
		end
	end
	if type(rawId) ~= "string" or rawId == "" then
		return ""
	end
	if CANONICAL_CORES[rawId] then
		return rawId
	end
	return CORE_ALIASES[string.lower(rawId)] or ""
end

function Mechanics.ResolveStyleId(rawId)
	local sbp = getSharedBlueprints()
	if sbp and type(sbp.ResolveStyleId) == "function" then
		local ok, res = pcall(sbp.ResolveStyleId, rawId)
		if ok and type(res) == "string" and res ~= "" then
			return res
		end
	end
	if CombatData and type(CombatData.ResolveStyleId) == "function" then
		return CombatData.ResolveStyleId(rawId)
	end
	return tostring(rawId or "skyborn_combat")
end

function Mechanics.ResolveWeaponArchetype(weaponId)
	local sbp = getSharedBlueprints()
	if sbp and type(sbp.ResolveWeaponArchetype) == "function" then
		local ok, res = pcall(sbp.ResolveWeaponArchetype, weaponId)
		if ok and type(res) == "string" and res ~= "" then
			return res
		end
	end
	local id = tostring(weaponId or "starter_sword")
	if WEAPON_ARCHETYPE_MAP[id] then
		return WEAPON_ARCHETYPE_MAP[id]
	end
	local low = string.lower(id)
	if string.find(low, "scythe", 1, true) then
		return "Scythe"
	elseif string.find(low, "halberd", 1, true) or string.find(low, "trident", 1, true) or string.find(low, "spear", 1, true) or string.find(low, "lance", 1, true) or string.find(low, "staff", 1, true) then
		return "Spear"
	elseif string.find(low, "dual", 1, true) or string.find(low, "twin", 1, true) or string.find(low, "dagger", 1, true) then
		return "DualBlades"
	elseif string.find(low, "great", 1, true) or string.find(low, "cleaver", 1, true) or string.find(low, "breaker", 1, true) or string.find(low, "severance", 1, true) then
		return "Greatsword"
	end
	return "Katana"
end

function Mechanics.ResolveGunArchetype(gunId)
	local sbp = getSharedBlueprints()
	if sbp and type(sbp.ResolveGunArchetype) == "function" then
		local ok, res = pcall(sbp.ResolveGunArchetype, gunId)
		if ok and type(res) == "string" and res ~= "" then
			return res
		end
	end
	local id = tostring(gunId or "aether_flintlock")
	if GUN_ARCHETYPE_MAP[id] then
		return GUN_ARCHETYPE_MAP[id]
	end
	local low = string.lower(id)
	if string.find(low, "railgun", 1, true) then
		return "Railgun"
	elseif string.find(low, "guitar", 1, true) or string.find(low, "lyre", 1, true) then
		return "VoidLyre"
	elseif string.find(low, "bow", 1, true) or string.find(low, "kabucha", 1, true) then
		return "Bow"
	elseif string.find(low, "cannon", 1, true) or string.find(low, "blaster", 1, true) then
		return "Cannon"
	end
	return "PistolRifle"
end

function Mechanics.IsTrueFlightCore(coreId, dragonTier)
	local cid = Mechanics.ResolveCoreId(coreId)
	local tier = tonumber(dragonTier) or 0
	local sbp = getSharedBlueprints()
	if sbp and type(sbp.IsTrueFlightCore) == "function" then
		local ok, res = pcall(sbp.IsTrueFlightCore, cid, tier)
		if ok and type(res) == "boolean" then
			return res
		end
	end
	if TRUE_FLIGHT_CORES[cid] == true then
		return true
	end
	if cid == "AbyssalSovereignCore" and tier >= 2 then
		return true
	end
	return false
end

-- ============================================================================
-- RAYCAST & GEOMETRY HELPERS
-- ============================================================================
local function makeWorldRayParams(p)
	local rp = RaycastParams.new()
	rp.FilterType = Enum.RaycastFilterType.Exclude
	local excl = {}
	if p and p.Character then
		table.insert(excl, p.Character)
	end
	local ae = workspace:FindFirstChild("ActiveEnemies")
	if ae then
		table.insert(excl, ae)
	end
	local ab = workspace:FindFirstChild("ActiveBosses")
	if ab then
		table.insert(excl, ab)
	end
	local tfx = workspace:FindFirstChild("TempFX")
	if tfx then
		table.insert(excl, tfx)
	end
	local sew = workspace:FindFirstChild("SkybreakExpansionWorld")
	if sew then
		table.insert(excl, sew)
	end
	rp.FilterDescendantsInstances = excl
	rp.RespectCanCollide = true
	return rp
end

local function sampleGroundSurface(pos, p)
	local rp = makeWorldRayParams(p)
	local hit = workspace:Raycast(pos + Vector3.new(0, 16, 0), Vector3.new(0, -56, 0), rp)
	if hit then
		local matName = (hit.Material and hit.Material.Name) or "Slate"
		local col = (hit.Instance and hit.Instance:IsA("BasePart") and hit.Instance.Color) or Color3.fromRGB(120, 130, 145)
		return hit.Position, matName, col
	end
	local fy = groundYAt and groundYAt(pos, pos.Y - 2.5) or (pos.Y - 2.5)
	return Vector3.new(pos.X, fy, pos.Z), "Slate", Color3.fromRGB(120, 130, 145)
end

local function computeSafeDashTarget(p, origin, dir, dashDist, allowVertical)
	local dist = math.clamp(tonumber(dashDist) or 26, 4, 62)
	local rp = makeWorldRayParams(p)
	local rayHit = workspace:Raycast(origin, dir * dist, rp)
	local rawTarget = rayHit and (rayHit.Position - dir * 2.8) or (origin + dir * dist)
	local gy = groundYAt and groundYAt(rawTarget, origin.Y - 3.2) or (origin.Y - 3.2)
	local desiredY
	if allowVertical and math.abs(dir.Y) > 0.22 then
		desiredY = math.clamp(rawTarget.Y, gy + 2.8, origin.Y + 36)
	else
		desiredY = math.clamp(gy + 3.0, origin.Y - 14, origin.Y + 18)
	end
	return Vector3.new(rawTarget.X, desiredY, rawTarget.Z)
end

function Mechanics.GetEnemiesAlongSegment(origin, endPos, width)
	local results = {}
	local seg = endPos - origin
	local segLen = seg.Magnitude
	local segDir = segLen > 0.05 and seg.Unit or Vector3.new(0, 0, -1)
	local effWidth = math.max(tonumber(width) or 8, 7.5)
	for _, e in ipairs((G and G.Enemies) or {}) do
		if e.Alive and e.Body and e.Model and e.Model.Parent then
			local ep = e.Body.Position
			local rel = ep - origin
			local proj = math.clamp(rel:Dot(segDir), 0, segLen)
			local closest = origin + segDir * proj
			local perpDist = (ep - closest).Magnitude
			local flatPerpDist = Vector3.new(ep.X - closest.X, 0, ep.Z - closest.Z).Magnitude
			local bodyRad = math.max(e.Body.Size.X, e.Body.Size.Z) * 0.5 + 3.5
			if perpDist <= (effWidth + bodyRad)
				or (flatPerpDist <= (effWidth + bodyRad) and math.abs(ep.Y - closest.Y) <= 22)
				or rel.Magnitude <= 13.5
			then
				table.insert(results, { Enemy = e, Dist = proj })
			end
		end
	end
	table.sort(results, function(a, b)
		return a.Dist < b.Dist
	end)
	return results
end

local function getEnemiesInRadius(centerPos, radius, originFallback, frontDir)
	local results = {}
	local rad = math.max(6, tonumber(radius) or 14)
	for _, e in ipairs((G and G.Enemies) or {}) do
		if e.Alive and e.Body and e.Model and e.Model.Parent then
			local ep = e.Body.Position
			local bodyRad = math.max(e.Body.Size.X, e.Body.Size.Z) * 0.5 + 2.5
			local d = (ep - centerPos).Magnitude
			local flatD = Vector3.new(ep.X - centerPos.X, 0, ep.Z - centerPos.Z).Magnitude
			local matched = (d <= rad + bodyRad) or (flatD <= rad + bodyRad and math.abs(ep.Y - centerPos.Y) <= 24)
			if not matched and originFallback and frontDir then
				local rel = ep - originFallback
				local along = rel:Dot(frontDir)
				if rel.Magnitude <= 12.0 or (along >= -2.0 and along <= 20.0 and (rel - frontDir * math.clamp(along, 0, 20.0)).Magnitude <= math.max(9.5, rad * 0.5)) then
					matched = true
				end
			end
			if matched then
				table.insert(results, { Enemy = e, Dist = d })
			end
		end
	end
	table.sort(results, function(a, b)
		return a.Dist < b.Dist
	end)
	return results
end

-- ============================================================================
-- PERSISTENT HAZARD ZONE ENGINE (Max 3 Active Zones per Player)
-- ============================================================================
local function destroyHazardEntry(z)
	if not z then
		return
	end
	z.Expired = true
	if z.Part and z.Part.Parent then
		pcall(function()
			z.Part:Destroy()
		end)
	end
	z.Part = nil
end

function Mechanics.CleanupPlayer(p)
	local list = PlayerHazards[p]
	if list then
		for _, z in ipairs(list) do
			destroyHazardEntry(z)
		end
		PlayerHazards[p] = nil
	end
end

function Mechanics.SpawnHazardZone(p, kind, centerPos, radius, duration, tickDmg, element)
	if not p or not p.Parent or not G then
		return nil
	end
	local hzKind = tostring(kind or "MagmaPool")
	local rad = math.clamp(tonumber(radius) or 12, 6, 36)
	local dur = math.clamp(tonumber(duration) or 3.2, 1.0, 8.0)
	local dmg = math.max(1, math.floor(tonumber(tickDmg) or 18))
	local elem = tostring(element or "Magma")

	local list = PlayerHazards[p]
	if not list then
		list = {}
		PlayerHazards[p] = list
	end
	while #list >= MAX_HAZARDS_PER_PLAYER do
		local oldest = table.remove(list, 1)
		destroyHazardEntry(oldest)
	end

	local fxFolder = ensureWorldFolder and ensureWorldFolder("CombatZones") or workspace:FindFirstChild("TempFX") or workspace
	local fy = (groundYAt and groundYAt(centerPos, centerPos.Y - 2.5) or (centerPos.Y - 2.5)) + 0.44
	local part = Instance.new("Part")
	part.Name = "Hazard_" .. hzKind
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(0.36, rad * 1.85, rad * 1.85)
	part.CFrame = CFrame.new(centerPos.X, fy, centerPos.Z) * CFrame.Angles(0, 0, math.pi * 0.5)
	part.Color = HAZARD_COLORS[hzKind] or ELEMENT_COLORS[elem] or Color3.fromRGB(255, 96, 36)
	part.Material = (hzKind == "FrostSheet" and Enum.Material.Glass) or Enum.Material.Neon
	part.Transparency = (hzKind == "FrostSheet" and 0.34) or 0.28
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = fxFolder
	Debris:AddItem(part, dur + 0.45)

	local now = os.clock()
	local interval = (hzKind == "StormCage" and 0.60) or 0.68
	local zone = {
		Owner = p,
		Kind = hzKind,
		Element = elem,
		Center = Vector3.new(centerPos.X, fy, centerPos.Z),
		Radius = rad,
		TickDmg = dmg,
		Interval = interval,
		NextTickAt = now + interval * 0.75,
		ExpiresAt = now + dur,
		Part = part,
		Expired = false,
	}
	table.insert(list, zone)
	return zone
end

function Mechanics.TickHazards(_dt)
	if not G then
		return
	end
	local now = os.clock()
	for p, list in pairs(PlayerHazards) do
		if not p or not p.Parent then
			Mechanics.CleanupPlayer(p)
		else
			local idx = 1
			while idx <= #list do
				local z = list[idx]
				if not z or z.Expired or now >= z.ExpiresAt then
					destroyHazardEntry(z)
					table.remove(list, idx)
				else
					if now >= z.NextTickAt then
						z.NextTickAt = now + z.Interval
						local isFinalTick = (z.NextTickAt >= z.ExpiresAt)
						for _, e in ipairs(G.Enemies or {}) do
							if e.Alive and e.Body and e.Model and e.Model.Parent then
								local ep = e.Body.Position
								local flatDist = Vector3.new(ep.X - z.Center.X, 0, ep.Z - z.Center.Z).Magnitude
								if flatDist <= z.Radius and math.abs(ep.Y - z.Center.Y) <= 20 then
									if z.Kind == "FrostSheet" then
										e.SlowedUntil = math.max(e.SlowedUntil or 0, now + 1.15)
										if isFinalTick and applyCryoFreeze then
											applyCryoFreeze(e, 1.25)
										end
									elseif z.Kind == "StormCage" then
										if pullEnemyToward then
											pullEnemyToward(e, z.Center, 4.5)
										end
										if not (isBossEnemy and isBossEnemy(e)) then
											e.StunnedUntil = math.max(e.StunnedUntil or 0, now + 0.32)
										end
									elseif z.Kind == "ChronoField" then
										e.SlowedUntil = math.max(e.SlowedUntil or 0, now + 1.45)
										if pullEnemyToward then
											pullEnemyToward(e, z.Center, 4.0)
										end
									elseif z.Kind == "Quicksand" or z.Kind == "GravityWell" then
										e.SlowedUntil = math.max(e.SlowedUntil or 0, now + 1.2)
										if pullEnemyToward then
											pullEnemyToward(e, z.Center, z.Kind == "GravityWell" and 8.5 or 6.5)
										end
									end
									G.Hit(p, e, z.TickDmg, 4, "Hazard_" .. z.Kind)
								end
							end
						end
					end
					idx += 1
				end
			end
			if #list == 0 then
				PlayerHazards[p] = nil
			end
		end
	end
end

-- ============================================================================
-- ELEMENTAL SYNERGIES: CRYO SHATTER + KNOCKBACK WALL-SLAM + UNIFIED HIT
-- ============================================================================
local function canTriggerCryoShatter(bp)
	if not bp then
		return false
	end
	if (tonumber(bp.ShatterBonusMult) or 0) > 1.0 then
		return true
	end
	if bp.FreezeDur and tonumber(bp.FreezeDur) > 0 then
		return false
	end
	if bp.Archetype == "GroundMonolithShatter" or bp.Archetype == "PoleVaultSlam" or bp.WeaponArchetype == "Greatsword" or bp.WeaponArchetype == "Cannon" then
		return true
	end
	return SHATTER_ELEMENTS[tostring(bp.Element or "")] == true
end

local function applyKnockbackAndWallSlam(p, e, baseHitDmg, pushDir, knockbackDist)
	if not e or not e.Alive or not e.Body or not e.Model or not e.Model.Parent then
		return
	end
	if (isBossEnemy and isBossEnemy(e)) or e.BossOwner or (e.Config and (e.Config.Speed or 10) <= 0) then
		return
	end
	local flat = Vector3.new(pushDir.X, 0, pushDir.Z)
	if flat.Magnitude < 0.05 then
		return
	end
	flat = flat.Unit
	local dist = math.clamp(tonumber(knockbackDist) or 12, 4, 22)
	local ep = e.Body.Position
	local rp = makeWorldRayParams(p)
	local wallHit = workspace:Raycast(ep, flat * dist, rp)

	if wallHit and wallHit.Instance and wallHit.Instance.CanCollide and math.abs(wallHit.Normal.Y) < 0.55 then
		local clampPos = wallHit.Position - flat * 2.2
		local fy = e.HomeFloorY or (groundYAt and groundYAt(clampPos, ep.Y - 2) or (ep.Y - 2))
		local targetPos = Vector3.new(clampPos.X, fy + math.max(2.2, e.Body.Size.Y * 0.5), clampPos.Z)
		local curRot = e.Body.CFrame - ep
		e.Model:PivotTo(CFrame.new(targetPos) * curRot)
		e.CachedGroundY = nil
		local now = os.clock()
		e.StunnedUntil = math.max(e.StunnedUntil or 0, now + 0.60)
		G.Hit(p, e, math.max(1, baseHitDmg * 0.25), 10, "WallSlam")
		if R and R.CombatFX then
			R.CombatFX:FireAllClients({
				Kind = "ElementalSynergy",
				SubKind = "WallSlam",
				Position = wallHit.Position,
				Direction = wallHit.Normal,
				Actor = p.UserId,
			})
		end
	else
		local step = dist * 0.58
		local np = ep + flat * step
		local fy = e.HomeFloorY or (groundYAt and groundYAt(np, ep.Y - 2) or (ep.Y - 2))
		if math.abs(fy - (ep.Y - math.max(2.2, e.Body.Size.Y * 0.5))) <= 12 then
			local targetPos = Vector3.new(np.X, fy + math.max(2.2, e.Body.Size.Y * 0.5), np.Z)
			local curRot = e.Body.CFrame - ep
			e.Model:PivotTo(CFrame.new(targetPos) * curRot)
			e.CachedGroundY = nil
		end
	end
end

local function applyMechanicalHit(p, e, rawDmg, brk, actionTag, bp, applyTerminalEffects, hitDir)
	if not p or not p.Parent or not e or not e.Alive or not e.Body or not e.Model or not e.Model.Parent then
		return 0
	end
	local now = os.clock()
	local dmg = math.max(1, tonumber(rawDmg) or 10)
	local breakAmt = math.max(1, math.floor(tonumber(brk) or 8))

	-- Cryo Shatter Synergy on currently frozen enemies
	if (e.FrozenUntil or 0) > now and canTriggerCryoShatter(bp) then
		local shatterMult = math.max(1.25, tonumber(bp and bp.ShatterBonusMult) or 1.35)
		dmg = dmg * shatterMult
		breakAmt = math.floor(breakAmt * 1.35 + 6)
		e.FrozenUntil = 0
		e.Model:SetAttribute("FrozenState", false)
		local hum = e.Model:FindFirstChildOfClass("Humanoid")
		if hum and e.OrigWalkSpeed then
			hum.WalkSpeed = e.OrigWalkSpeed
		end
		if R and R.CombatFX then
			R.CombatFX:FireAllClients({
				Kind = "ElementalSynergy",
				SubKind = "CryoShatter",
				Position = e.Body.Position,
				Element = (bp and bp.Element) or "Flame",
				Actor = p.UserId,
			})
		end
	end

	if bp and bp.ArmorShred then
		e.ArmorShredUntil = now + 4.0
	end

	local preHP = tonumber(e.HP) or 0
	G.Hit(p, e, dmg, breakAmt, actionTag)
	local dealt = math.max(0, preHP - (tonumber(e.HP) or 0))

	if applyTerminalEffects and e.Alive and bp then
		if bp.FreezeDur and tonumber(bp.FreezeDur) > 0 and applyCryoFreeze then
			applyCryoFreeze(e, tonumber(bp.FreezeDur))
		elseif bp.StunDur and tonumber(bp.StunDur) > 0 and not (isBossEnemy and isBossEnemy(e)) then
			local stDur = tonumber(bp.StunDur)
			e.StunnedUntil = math.max(e.StunnedUntil or 0, now + stDur)
			if bp.AcousticStun and e.Model then
				e.Model:SetAttribute("AcousticStun", true)
				task.delay(stDur, function()
					if e and e.Model and e.Model.Parent then
						e.Model:SetAttribute("AcousticStun", false)
					end
				end)
			end
		end
		if bp.SlowDur and tonumber(bp.SlowDur) > 0 then
			e.SlowedUntil = math.max(e.SlowedUntil or 0, now + tonumber(bp.SlowDur))
		end
		if bp.BurnTicks and tonumber(bp.BurnTicks) > 0 and applyBurnOrDoT then
			local bScale = tonumber(bp.BurnScale) or 0.15
			applyBurnOrDoT(p, e, math.max(1, dmg * bScale), math.floor(tonumber(bp.BurnTicks)), bp.Element or "Flame")
		end
		if bp.Knockback and tonumber(bp.Knockback) > 0 and hitDir then
			applyKnockbackAndWallSlam(p, e, dmg, hitDir, tonumber(bp.Knockback))
		end
	end

	return dealt
end

-- ============================================================================
-- BUILT-IN FALLBACK BLUEPRINT SYNTHESIZER (Merged Under SkybreakSkillBlueprints)
-- ============================================================================
local CORE_SKILL_DEFS = {
	GaleCore = {
		Element = "Gale",
		Z = { Archetype = "TravellingWave", PoseClip = "WindSlashCast", Range = 32, Radius = 11, Knockback = 15 },
		X = { Archetype = "VortexPullCage", PoseClip = "VortexRaise", Range = 26, Radius = 15, Hits = 4, PullStrength = 14, HazardKind = "StormCage", HazardDuration = 2.6 },
		C = { Archetype = "BlinkDelayedSlash", PoseClip = "JetstreamBlink", DashDist = 28, Range = 28, Radius = 11, ImpactDelaySec = 0.22, StunDur = 0.55 },
		V = { Archetype = "SkyfallSphere", PoseClip = "SkyCastRaise", Range = 34, Radius = 24, ImpactDelaySec = 0.36, ImpactGround = true, PullStrength = 16, StunDur = 1.0, IsUltimate = true },
		F = { Archetype = "MobilityDashHit", PoseClip = "SkyFlightBurst", Range = 18, Radius = 12 },
	},
	SandstoneCore = {
		Element = "Sand",
		Z = { Archetype = "TravellingWave", PoseClip = "GroundWaveSlash", Range = 30, Radius = 11, ImpactGround = true, SlowDur = 1.4 },
		X = { Archetype = "SandCoffinImplode", PoseClip = "CoffinClutch", Range = 26, Radius = 14, PullStrength = 15, ImpactDelaySec = 0.30, StunDur = 0.95 },
		C = { Archetype = "VortexPullCage", PoseClip = "SandstormSpin", Range = 26, Radius = 16, Hits = 4, PullStrength = 13, HazardKind = "Quicksand", HazardDuration = 3.2 },
		V = { Archetype = "GroundMonolithShatter", PoseClip = "GroundSlamDrop", Range = 32, Radius = 23, ImpactGround = true, StunDur = 1.1, HazardKind = "Quicksand", HazardDuration = 3.8, IsUltimate = true },
		F = { Archetype = "MobilityDashHit", PoseClip = "SandFlightStream", Range = 18, Radius = 12 },
	},
	SolarFlameCore = {
		Element = "Flame",
		Z = { Archetype = "SpreadVolley", PoseClip = "RapidPalmVolley", Range = 32, Radius = 11, Hits = 4, HitInterval = 0.08, BurnTicks = 2, ShatterBonusMult = 1.35 },
		X = { Archetype = "SkybeamPillars", PoseClip = "SkyCastRaise", Range = 26, Radius = 15, Hits = 5, ImpactGround = true, BurnTicks = 3, ShatterBonusMult = 1.38 },
		C = { Archetype = "DragRushSlam", PoseClip = "JetFistRush", DashDist = 26, Range = 26, Radius = 12, ImpactGround = true, BurnTicks = 3, Knockback = 13, ShatterBonusMult = 1.35 },
		V = { Archetype = "SkyfallSphere", PoseClip = "SolarEmperorRaise", Range = 36, Radius = 26, ImpactDelaySec = 0.42, ImpactGround = true, BurnTicks = 4, HazardKind = "SolarFlare", HazardDuration = 3.8, ShatterBonusMult = 1.45, IsUltimate = true },
		F = { Archetype = "MobilityDashHit", PoseClip = "SolarFlightJet", Range = 18, Radius = 12, BurnTicks = 2 },
	},
	GlacierIceCore = {
		Element = "Ice",
		Z = { Archetype = "MultiLaneSpikes", PoseClip = "GroundFrostSweep", Range = 30, Radius = 10, FreezeDur = 1.6, ImpactGround = true },
		X = { Archetype = "PiercingBeam", PoseClip = "FrostLanceThrust", Range = 38, Radius = 9.5, Hits = 2, FreezeDur = 1.8 },
		C = { Archetype = "VortexPullCage", PoseClip = "GlacialDomain", Range = 26, Radius = 16, Hits = 4, PullStrength = 11, FreezeDur = 1.7, HazardKind = "FrostSheet", HazardDuration = 3.5 },
		V = { Archetype = "SkybeamPillars", PoseClip = "AbsoluteZeroStomp", Range = 30, Radius = 24, Hits = 6, ImpactGround = true, FreezeDur = 2.4, HazardKind = "FrostSheet", HazardDuration = 4.2, IsUltimate = true },
		F = { Archetype = "MobilityDashHit", PoseClip = "FrostSkateDash", DashDist = 42, Range = 42, Radius = 10, FreezeDur = 1.2 },
	},
	ThunderRumbleCore = {
		Element = "Lightning",
		Z = { Archetype = "ChainLightning", PoseClip = "ThunderSnapCast", Range = 34, Radius = 12, ChainCount = 5, ChainRadius = 20, StunDur = 0.65 },
		X = { Archetype = "SkybeamPillars", PoseClip = "ElThorCall", Range = 32, Radius = 15, Hits = 5, ImpactGround = true, StunDur = 0.9 },
		C = { Archetype = "VortexPullCage", PoseClip = "StormCageBrace", Range = 26, Radius = 16, Hits = 4, PullStrength = 12, StunDur = 0.85, HazardKind = "StormCage", HazardDuration = 3.4 },
		V = { Archetype = "SkyfallSphere", PoseClip = "RaigoSkyRaise", Range = 36, Radius = 26, ImpactDelaySec = 0.44, ImpactGround = true, StunDur = 1.5, HazardKind = "StormCage", HazardDuration = 3.8, IsUltimate = true },
		F = { Archetype = "MobilityDashHit", PoseClip = "ThunderBlinkStep", DashDist = 48, Range = 48, Radius = 10.5, StunDur = 0.55 },
	},
	CelestialLightCore = {
		Element = "Light",
		Z = { Archetype = "PiercingBeam", PoseClip = "PhotonFingerBeam", Range = 44, Radius = 9.5, Hits = 1 },
		X = { Archetype = "SpreadVolley", PoseClip = "SacredJewelsBarrage", Range = 36, Radius = 15, Hits = 6, HitInterval = 0.07 },
		C = { Archetype = "ZigZagMirrorKick", PoseClip = "MirrorKickDash", DashDist = 30, Range = 30, Radius = 12, ChainCount = 5, StunDur = 0.75, ImpactGround = true },
		V = { Archetype = "SkybeamPillars", PoseClip = "CelestialJudgmentRaise", Range = 34, Radius = 25, Hits = 7, ImpactGround = true, StunDur = 1.0, IsUltimate = true },
		F = { Archetype = "MobilityDashHit", PoseClip = "LightStarFlight", Range = 20, Radius = 12 },
	},
	StarforgedMagmaCore = {
		Element = "Magma",
		Z = { Archetype = "GroundMonolithShatter", PoseClip = "MagmaFistPunch", Range = 28, Radius = 13, ImpactGround = true, BurnTicks = 3, HazardKind = "MagmaPool", HazardDuration = 3.2, ShatterBonusMult = 1.40 },
		X = { Archetype = "DragRushSlam", PoseClip = "MagmaHoundRush", DashDist = 24, Range = 24, Radius = 12, ImpactGround = true, BurnTicks = 3, HazardKind = "MagmaPool", HazardDuration = 3.2, ShatterBonusMult = 1.38 },
		C = { Archetype = "SkybeamPillars", PoseClip = "LavaGeyserStomp", Range = 28, Radius = 17, Hits = 5, ImpactGround = true, BurnTicks = 3, HazardKind = "MagmaPool", HazardDuration = 3.6, ShatterBonusMult = 1.40 },
		V = { Archetype = "MeteorShower", PoseClip = "VolcanicPlumeCall", Range = 36, Radius = 25, Hits = 6, ImpactGround = true, BurnTicks = 4, HazardKind = "MagmaPool", HazardDuration = 4.2, ShatterBonusMult = 1.45, IsUltimate = true },
		F = { Archetype = "MobilityDashHit", PoseClip = "MagmaJetFlight", Range = 18, Radius = 12, BurnTicks = 2 },
	},
	AstralGravityCore = {
		Element = "Gravity",
		Z = { Archetype = "TravellingWave", PoseClip = "GravityRepulsePalm", Range = 30, Radius = 13, Knockback = 19, ShatterBonusMult = 1.35 },
		X = { Archetype = "VortexPullCage", PoseClip = "SingularityCrush", Range = 28, Radius = 17, Hits = 4, PullStrength = 17, SlowDur = 1.6, HazardKind = "GravityWell", HazardDuration = 3.4 },
		C = { Archetype = "GroundMonolithShatter", PoseClip = "TectonicPress", Range = 28, Radius = 18, ImpactGround = true, StunDur = 1.0, ShatterBonusMult = 1.42 },
		V = { Archetype = "MeteorShower", PoseClip = "AstralMeteorSummon", Range = 38, Radius = 26, Hits = 6, PullStrength = 15, ImpactGround = true, StunDur = 1.2, ShatterBonusMult = 1.45, IsUltimate = true },
		F = { Archetype = "MobilityDashHit", PoseClip = "GravityBoulderHover", Range = 18, Radius = 12 },
	},
	DimensionalPortalCore = {
		Element = "Portal",
		Z = { Archetype = "BlinkDelayedSlash", PoseClip = "RiftBlinkSever", DashDist = 28, Range = 28, Radius = 11.5, ImpactDelaySec = 0.24, StunDur = 0.7 },
		X = { Archetype = "RiftPhaseEscape", PoseClip = "DimensionPhaseStep", DashDist = 18, Range = 20, Radius = 14, ImpactDelaySec = 0.28, StunDur = 0.65 },
		C = { Archetype = "PortalWorldGate", PoseClip = "WorldGateOpen", Range = 18, Radius = 12 },
		V = { Archetype = "VortexPullCage", PoseClip = "DimensionCollapse", Range = 30, Radius = 23, Hits = 5, PullStrength = 18, StunDur = 1.25, HazardKind = "ChronoField", HazardDuration = 3.8, IsUltimate = true },
		F = { Archetype = "MobilityDashHit", PoseClip = "PortalFlashWarp", DashDist = 50, Range = 50, Radius = 10.5 },
	},
	SolarTitanCore = {
		Element = "Solar",
		Z = { Archetype = "TransformToggle", PoseClip = "TitanShiftAscend", Range = 20, Radius = 16 },
		X = { Archetype = "PoleVaultSlam", PoseClip = "HeavenlyPalmLeap", DashDist = 20, Range = 24, Radius = 17, ImpactDelaySec = 0.20, ImpactGround = true, StunDur = 0.9, ShatterBonusMult = 1.40 },
		C = { Archetype = "SkybeamPillars", PoseClip = "JudgmentPillarRing", Range = 28, Radius = 19, Hits = 6, ImpactGround = true, StunDur = 0.85, ShatterBonusMult = 1.38 },
		V = { Archetype = "SkyfallSphere", PoseClip = "TwilightHaloBurst", Range = 32, Radius = 26, ImpactDelaySec = 0.36, ImpactGround = true, StunDur = 1.3, HazardKind = "SolarFlare", HazardDuration = 3.8, ShatterBonusMult = 1.45, IsUltimate = true },
		F = { Archetype = "MobilityDashHit", PoseClip = "TitanSeismicBound", DashDist = 38, Range = 38, Radius = 14, ImpactGround = true, ShatterBonusMult = 1.35 },
	},
	AetherflowCore = {
		Element = "Dough",
		Z = { Archetype = "TravellingWave", PoseClip = "GildedFistCannon", Range = 30, Radius = 12, Knockback = 16, ImpactGround = true, ShatterBonusMult = 1.35 },
		X = { Archetype = "MultiLaneSpikes", PoseClip = "PastrySpikeErupt", Range = 28, Radius = 12, ImpactGround = true, StunDur = 0.8 },
		C = { Archetype = "DragRushSlam", PoseClip = "ClotheslineWheelRoll", DashDist = 30, Range = 30, Radius = 13, ImpactGround = true, StunDur = 1.0, ShatterBonusMult = 1.38 },
		V = { Archetype = "SpreadVolley", PoseClip = "FusilladeRingGates", Range = 32, Radius = 22, Hits = 7, HitInterval = 0.08, StunDur = 1.2, ShatterBonusMult = 1.38, IsUltimate = true },
		F = { Archetype = "MobilityDashHit", PoseClip = "RollerDonutDash", DashDist = 44, Range = 44, Radius = 11.5, Knockback = 10 },
	},
	AbyssalSovereignCore = {
		Element = "Dragon",
		Z = { Archetype = "PiercingBeam", PoseClip = "DragonHeatBreath", Range = 42, Radius = 12, Hits = 3, HitInterval = 0.09, BurnTicks = 3, Knockback = 14, ShatterBonusMult = 1.40 },
		X = { Archetype = "DragRushSlam", PoseClip = "DraconicTalonDive", DashDist = 26, Range = 26, Radius = 14, ImpactGround = true, StunDur = 0.85, BurnTicks = 2, ShatterBonusMult = 1.38 },
		C = { Archetype = "MeteorShower", PoseClip = "DragonFireShower", Range = 36, Radius = 22, Hits = 6, ImpactGround = true, BurnTicks = 3, HazardKind = "MagmaPool", HazardDuration = 3.4, ShatterBonusMult = 1.42 },
		V = { Archetype = "TransformToggle", PoseClip = "DragonSovereignAscend", Range = 22, Radius = 18, IsUltimate = true },
		F = { Archetype = "MobilityDashHit", PoseClip = "WyrmWingRush", DashDist = 46, Range = 46, Radius = 12, BurnTicks = 2 },
	},
}

local STYLE_ARCHETYPE_DEFS = {
	skyborn_combat = { Z = "TravellingWave", X = "PoleVaultSlam", C = "SpreadVolley", V = "SkybeamPillars", F = "MobilityDashHit" },
	SkyStep = { Z = "DragRushSlam", X = "PoleVaultSlam", C = "ZigZagMirrorKick", V = "SkyfallSphere", F = "MobilityDashHit" },
	jade_dragon = { Z = "TravellingWave", X = "VortexPullCage", C = "GroundMonolithShatter", V = "MultiLaneSpikes", F = "MobilityDashHit" },
	thunder_talon = { Z = "ChainLightning", X = "BlinkDelayedSlash", C = "ZigZagMirrorKick", V = "SkybeamPillars", F = "MobilityDashHit" },
	solar_ashura = { Z = "DragRushSlam", X = "VortexPullCage", C = "PoleVaultSlam", V = "MeteorShower", F = "MobilityDashHit" },
	celestial_godhuman = { Z = "BlinkDelayedSlash", X = "SpreadVolley", C = "SkyfallSphere", V = "ZigZagMirrorKick", F = "MobilityDashHit" },
	SanguineVoidArt = { Z = "HarmonicSiphonWave", X = "SpreadVolley", C = "DragRushSlam", V = "HarmonicSiphonWave", F = "MobilityDashHit" },
	ChronoVoidPalm = { Z = "PiercingBeam", X = "RiftPhaseEscape", C = "VortexPullCage", V = "SkybeamPillars", F = "MobilityDashHit" },
}

local WEAPON_SKILL_DEFS = {
	Katana = {
		Z = { Archetype = "BlinkDelayedSlash", PoseClip = "KatanaIaiBlink", DashDist = 26, Range = 26, Radius = 10.5, ImpactDelaySec = 0.24, StunDur = 0.55 },
		X = { Archetype = "TravellingWave", PoseClip = "KatanaCrescentWave", Range = 32, Radius = 11.5, Knockback = 13 },
		C = { Archetype = "ZigZagMirrorKick", PoseClip = "KatanaTempestStep", DashDist = 26, Range = 26, Radius = 11.5, ChainCount = 4, StunDur = 0.65 },
		V = { Archetype = "BlinkDelayedSlash", PoseClip = "KatanaJudgmentCut", DashDist = 30, Range = 30, Radius = 16, ImpactDelaySec = 0.28, StunDur = 0.95, IsUltimate = true },
		F = { Archetype = "MobilityDashHit", PoseClip = "KatanaGaleStep", DashDist = 40, Range = 40, Radius = 9.5 },
	},
	Greatsword = {
		Z = { Archetype = "GroundMonolithShatter", PoseClip = "GreatswordEarthsplit", Range = 28, Radius = 14, ImpactGround = true, Knockback = 16, ShatterBonusMult = 1.42 },
		X = { Archetype = "DragRushSlam", PoseClip = "GreatswordColossusSpin", DashDist = 22, Range = 24, Radius = 15, ImpactGround = true, StunDur = 0.85, ShatterBonusMult = 1.40 },
		C = { Archetype = "PoleVaultSlam", PoseClip = "GreatswordCraterLeap", DashDist = 22, Range = 24, Radius = 16, ImpactDelaySec = 0.22, ImpactGround = true, StunDur = 0.9, ShatterBonusMult = 1.42 },
		V = { Archetype = "SkybeamPillars", PoseClip = "GreatswordCataclysm", Range = 30, Radius = 22, Hits = 5, ImpactGround = true, StunDur = 1.1, ShatterBonusMult = 1.45, IsUltimate = true },
		F = { Archetype = "MobilityDashHit", PoseClip = "GreatswordShoulderCharge", DashDist = 36, Range = 36, Radius = 11.5, Knockback = 14, ShatterBonusMult = 1.35 },
	},
	DualBlades = {
		Z = { Archetype = "BlinkDelayedSlash", PoseClip = "DualCrossBlitz", DashDist = 28, Range = 28, Radius = 11, ImpactDelaySec = 0.20, StunDur = 0.5 },
		X = { Archetype = "VortexPullCage", PoseClip = "DualBladeCyclone", Range = 22, Radius = 14, Hits = 5, PullStrength = 12 },
		C = { Archetype = "ZigZagMirrorKick", PoseClip = "DualPhantomDance", DashDist = 28, Range = 28, Radius = 11.5, ChainCount = 5, StunDur = 0.65 },
		V = { Archetype = "SpreadVolley", PoseClip = "DualEclipseFrenzy", Range = 26, Radius = 18, Hits = 7, HitInterval = 0.07, StunDur = 0.9, IsUltimate = true },
		F = { Archetype = "MobilityDashHit", PoseClip = "DualShadowDash", DashDist = 44, Range = 44, Radius = 9.5 },
	},
	Spear = {
		Z = { Archetype = "DragRushSlam", PoseClip = "SpearSkewerCharge", DashDist = 28, Range = 28, Radius = 10.5, ImpactGround = true, StunDur = 0.65 },
		X = { Archetype = "PoleVaultSlam", PoseClip = "SpearDragonDive", DashDist = 24, Range = 26, Radius = 15, ImpactDelaySec = 0.22, ImpactGround = true, StunDur = 0.85, ShatterBonusMult = 1.35 },
		C = { Archetype = "MultiLaneSpikes", PoseClip = "SpearTridentSurge", Range = 32, Radius = 11, ImpactGround = true },
		V = { Archetype = "SkybeamPillars", PoseClip = "SpearHeavenFall", Range = 32, Radius = 21, Hits = 6, ImpactGround = true, StunDur = 1.0, IsUltimate = true },
		F = { Archetype = "MobilityDashHit", PoseClip = "SpearVaultLunge", DashDist = 44, Range = 44, Radius = 9.5 },
	},
	Scythe = {
		Z = { Archetype = "HarmonicSiphonWave", PoseClip = "ScytheReapPull", Range = 30, Radius = 14, PullStrength = 14, LifestealPct = 0.12 },
		X = { Archetype = "BlinkDelayedSlash", PoseClip = "ScytheGuillotineBlink", DashDist = 28, Range = 28, Radius = 13, ImpactDelaySec = 0.25, StunDur = 0.75, LifestealPct = 0.10, HazardKind = "ChronoField", HazardDuration = 2.8 },
		C = { Archetype = "VortexPullCage", PoseClip = "ScytheSoulVortex", Range = 26, Radius = 16, Hits = 4, PullStrength = 15, HazardKind = "ChronoField", HazardDuration = 3.0 },
		V = { Archetype = "SkyfallSphere", PoseClip = "ScytheReaperEclipse", Range = 32, Radius = 23, ImpactDelaySec = 0.34, ImpactGround = true, StunDur = 1.15, LifestealPct = 0.14, IsUltimate = true },
		F = { Archetype = "MobilityDashHit", PoseClip = "ScytheWraithGlide", DashDist = 44, Range = 44, Radius = 10.5 },
	},
}

local GUN_SKILL_DEFS = {
	PistolRifle = {
		Z = { Archetype = "PiercingBeam", PoseClip = "GunDeadeyeSnap", Range = 88, Radius = 7.5 },
		X = { Archetype = "SpreadVolley", PoseClip = "GunFanBarrage", Range = 68, Radius = 12, Hits = 5, HitInterval = 0.07 },
		C = { Archetype = "RiftPhaseEscape", PoseClip = "GunBackstepVault", DashDist = 16, Range = 48, Radius = 11, StunDur = 0.5 },
		V = { Archetype = "SkybeamPillars", PoseClip = "GunOrbitalLock", Range = 64, Radius = 20, Hits = 6, ImpactGround = true, IsUltimate = true },
		F = { Archetype = "MobilityDashHit", PoseClip = "GunTacticalSlide", DashDist = 38, Range = 38, Radius = 9 },
	},
	Railgun = {
		Z = { Archetype = "PiercingBeam", PoseClip = "RailgunOverchargeBrace", Range = 115, Radius = 9.0, FreezeDur = 2.2 },
		X = { Archetype = "MultiLaneSpikes", PoseClip = "RailgunPrismSplit", Range = 72, Radius = 10.5, FreezeDur = 1.8, ImpactGround = true },
		C = { Archetype = "VortexPullCage", PoseClip = "RailgunCryoCell", Range = 54, Radius = 16, Hits = 4, PullStrength = 12, FreezeDur = 1.8, HazardKind = "FrostSheet", HazardDuration = 3.4 },
		V = { Archetype = "SkyfallSphere", PoseClip = "RailgunOrbitalZero", Range = 68, Radius = 24, ImpactDelaySec = 0.36, ImpactGround = true, FreezeDur = 2.6, HazardKind = "FrostSheet", HazardDuration = 4.0, IsUltimate = true },
		F = { Archetype = "MobilityDashHit", PoseClip = "RailgunThrusterStep", DashDist = 38, Range = 38, Radius = 9.5, FreezeDur = 1.1 },
	},
	Cannon = {
		Z = { Archetype = "TravellingWave", PoseClip = "CannonMortarBrace", Range = 64, Radius = 13, ImpactGround = true, Knockback = 16, BurnTicks = 3, ShatterBonusMult = 1.40 },
		X = { Archetype = "VortexPullCage", PoseClip = "CannonNapalmWell", Range = 52, Radius = 16, Hits = 4, PullStrength = 14, BurnTicks = 3, HazardKind = "MagmaPool", HazardDuration = 3.4, ShatterBonusMult = 1.38 },
		C = { Archetype = "SpreadVolley", PoseClip = "CannonSiegeSalvo", Range = 62, Radius = 15, Hits = 4, HitInterval = 0.10, ImpactGround = true, ShatterBonusMult = 1.35 },
		V = { Archetype = "MeteorShower", PoseClip = "CannonHellfireRain", Range = 66, Radius = 25, Hits = 6, ImpactGround = true, BurnTicks = 4, HazardKind = "MagmaPool", HazardDuration = 4.0, ShatterBonusMult = 1.45, IsUltimate = true },
		F = { Archetype = "MobilityDashHit", PoseClip = "CannonRecoilBlast", DashDist = 36, Range = 36, Radius = 11, Knockback = 14, ShatterBonusMult = 1.35 },
	},
	VoidLyre = {
		Z = { Archetype = "HarmonicSiphonWave", PoseClip = "GuitarPowerChord", Range = 56, Radius = 15, StunDur = 1.4, AcousticStun = true, LifestealPct = 0.16 },
		X = { Archetype = "VortexPullCage", PoseClip = "GuitarRequiemAmp", Range = 48, Radius = 17, Hits = 4, PullStrength = 14, StunDur = 1.3, AcousticStun = true, LifestealPct = 0.15, HazardKind = "ChronoField", HazardDuration = 3.2 },
		C = { Archetype = "ChainLightning", PoseClip = "GuitarResonanceRiff", Range = 58, Radius = 13, ChainCount = 5, ChainRadius = 22, StunDur = 1.1, AcousticStun = true, LifestealPct = 0.14 },
		V = { Archetype = "SkyfallSphere", PoseClip = "GuitarVoidSymphony", Range = 56, Radius = 25, ImpactDelaySec = 0.34, ImpactGround = true, StunDur = 1.6, AcousticStun = true, LifestealPct = 0.18, IsUltimate = true },
		F = { Archetype = "MobilityDashHit", PoseClip = "GuitarEchoGlide", DashDist = 40, Range = 40, Radius = 10.5, LifestealPct = 0.10 },
	},
	Bow = {
		Z = { Archetype = "MultiLaneSpikes", PoseClip = "BowSplitVolley", Range = 74, Radius = 10 },
		X = { Archetype = "PiercingBeam", PoseClip = "BowTempestSnipe", Range = 98, Radius = 8.5, Knockback = 15 },
		C = { Archetype = "VortexPullCage", PoseClip = "BowSnareArrow", Range = 58, Radius = 15, Hits = 4, PullStrength = 13, SlowDur = 1.6 },
		V = { Archetype = "MeteorShower", PoseClip = "BowArrowStormSky", Range = 68, Radius = 24, Hits = 7, ImpactGround = true, IsUltimate = true },
		F = { Archetype = "MobilityDashHit", PoseClip = "BowWindflipStep", DashDist = 42, Range = 42, Radius = 9.5 },
	},
}
GUN_SKILL_DEFS.AcousticGuitar = GUN_SKILL_DEFS.VoidLyre

local function normalizeBlueprint(ext, fallback)
	local out = {}
	if type(fallback) == "table" then
		for k, v in pairs(fallback) do
			out[k] = v
		end
	end
	if type(ext) == "table" then
		for k, v in pairs(ext) do
			if v ~= nil then
				out[k] = v
			end
		end
		out.BlueprintId = ext.BlueprintId or ext.Id or out.BlueprintId
		out.Archetype = ext.Archetype or ext.MechanicalArchetype or ext.Mechanic or out.Archetype
		out.WeaponArchetype = ext.WeaponArchetype or ext.SubArchetype or out.WeaponArchetype
		out.PoseClip = ext.PoseClip or ext.Pose or ext.AnimationPose or out.PoseClip
		out.Multiplier = tonumber(ext.Multiplier or ext.Mult) or out.Multiplier
		out.Cooldown = tonumber(ext.Cooldown) or out.Cooldown
		out.Cost = tonumber(ext.Cost or ext.EnergyCost) or out.Cost
		out.Range = tonumber(ext.Range) or out.Range
		out.Radius = tonumber(ext.Radius) or out.Radius
		out.Hits = tonumber(ext.Hits or ext.HitCount) or out.Hits
		out.HitInterval = tonumber(ext.HitInterval or ext.PulseInterval) or out.HitInterval
		out.DashDist = tonumber(ext.DashDist or ext.Dash or ext.DashDistance) or out.DashDist
		out.ChainCount = tonumber(ext.ChainCount or ext.MaxChains) or out.ChainCount
		out.ChainRadius = tonumber(ext.ChainRadius or ext.HopRadius) or out.ChainRadius
		out.ImpactDelaySec = tonumber(ext.ImpactDelaySec or ext.ImpactDelay or ext.DelaySec) or out.ImpactDelaySec
		out.PullStrength = tonumber(ext.PullStrength or (type(ext.Pull) == "number" and ext.Pull or nil)) or out.PullStrength
		out.StunDur = tonumber(ext.StunDur or ext.StunDuration) or out.StunDur
		out.FreezeDur = tonumber(ext.FreezeDur or ext.FreezeDuration) or out.FreezeDur
		out.BurnTicks = tonumber(ext.BurnTicks or ext.DoTTicks) or out.BurnTicks
		out.Knockback = tonumber(ext.Knockback or ext.KnockbackDist) or out.Knockback
		out.LifestealPct = tonumber(ext.LifestealPct or ext.SiphonPct) or out.LifestealPct
		out.ShatterBonusMult = tonumber(ext.ShatterBonusMult or ext.CryoShatterMult) or out.ShatterBonusMult
		out.HazardKind = ext.HazardKind or ext.Hazard or out.HazardKind
		out.HazardDuration = tonumber(ext.HazardDuration or ext.PoolDuration) or out.HazardDuration
	end
	return out
end

local function lookupConfigMove(cfgTbl, key)
	if type(cfgTbl) ~= "table" or type(cfgTbl.Moves) ~= "table" then
		return nil
	end
	if cfgTbl.Moves[key] then
		return cfgTbl.Moves[key]
	end
	for _, m in pairs(cfgTbl.Moves) do
		if type(m) == "table" and string.upper(tostring(m.Key or "")) == key then
			return m
		end
	end
	return nil
end

function Mechanics.GetSkillBlueprint(slot, itemId, moveKey, isAwakened, dragonTier)
	local key = string.upper(tostring(moveKey or "Z"))
	local tier = tonumber(dragonTier) or 0
	local awk = isAwakened == true
	local defaultMultByKey = { Z = 2.5, X = 3.1, C = 3.8, V = 5.0, F = 1.9 }
	local defaultCdByKey = { Z = 4.5, X = 6.5, C = 9.0, V = 13.5, F = 4.5 }
	local defaultCostByKey = { Z = 10, X = 14, C = 18, V = 24, F = 10 }

	local fb = {
		BlueprintId = string.format("Slot%d_%s_%s_%s", slot, tostring(itemId), key, awk and "V2" or ("T" .. tostring(tier))),
		Slot = slot,
		ItemId = tostring(itemId),
		MoveKey = key,
		Archetype = "TravellingWave",
		WeaponArchetype = tostring(itemId),
		PoseClip = "SkillCastForward",
		MoveName = tostring(itemId) .. " [" .. key .. "]",
		Element = "Sky",
		Multiplier = defaultMultByKey[key] or 2.8,
		Cooldown = defaultCdByKey[key] or 6.0,
		Cost = defaultCostByKey[key] or 12,
		Break = (key == "V" and 44) or (key == "C" and 34) or 26,
		Range = 28,
		Radius = 13,
		Hits = 1,
		HitInterval = 0.10,
		IsUltimate = (key == "V"),
	}

	if slot == 1 then
		local styleId = Mechanics.ResolveStyleId(itemId)
		local style = CombatData and CombatData.MartialStyles and (CombatData.MartialStyles[styleId] or CombatData.MartialStyles.skyborn_combat)
		local stMove = style and style.Moves and style.Moves[key]
		local archMap = STYLE_ARCHETYPE_DEFS[styleId] or STYLE_ARCHETYPE_DEFS.skyborn_combat
		fb.ItemId = styleId
		fb.WeaponArchetype = styleId
		fb.Archetype = (archMap and archMap[key]) or "TravellingWave"
		fb.PoseClip = "Martial_" .. styleId .. "_" .. key
		fb.Element = (style and style.Element) or "Sky"
		fb.Color = (style and style.Color) or ELEMENT_COLORS[fb.Element]
		if stMove then
			fb.MoveName = stMove.Name or fb.MoveName
			fb.Cooldown = tonumber(stMove.Cooldown) or fb.Cooldown
			fb.Cost = tonumber(stMove.Cost) or fb.Cost
			fb.Multiplier = tonumber(stMove.Multiplier) or fb.Multiplier
			fb.Range = tonumber(stMove.Range) or fb.Range
			fb.Radius = tonumber(stMove.Radius) or fb.Radius
			fb.Hits = tonumber(stMove.Hits) or fb.Hits
			fb.Break = tonumber(stMove.Break) or fb.Break
			fb.DashDist = tonumber(stMove.Dash) or fb.DashDist
			fb.StunDur = tonumber(stMove.StunDur) or fb.StunDur
			fb.BurnTicks = tonumber(stMove.BurnTicks) or fb.BurnTicks
			if stMove.Pull then
				fb.PullStrength = 14
			end
		elseif key == "F" then
			fb.MoveName = ((style and style.Name) or "Martial") .. " Rush Step"
			fb.Archetype = "MobilityDashHit"
			fb.DashDist = 38
			fb.Range = 38
			fb.Radius = 10
			fb.Cooldown = 4.2
			fb.Cost = 8
			fb.Multiplier = 1.85
		elseif key == "V" then
			fb.MoveName = ((style and style.Name) or "Martial") .. " Grand Finisher"
			fb.Cooldown = 13.0
			fb.Cost = 22
			fb.Multiplier = 4.6
			fb.Range = 30
			fb.Radius = 20
			fb.Hits = 4
			fb.StunDur = 1.0
		end
		if styleId == "SanguineVoidArt" or styleId == "sanguine_arts" then
			fb.LifestealPct = fb.LifestealPct or 0.16
		elseif (styleId == "ChronoVoidPalm" or styleId == "chronos_fist") and (key == "C" or key == "V") then
			fb.HazardKind = fb.HazardKind or "ChronoField"
			fb.HazardDuration = 3.0
		end
	elseif slot == 2 then
		local cid = Mechanics.ResolveCoreId(itemId)
		local fCfg = C and C.AetherFruits and C.AetherFruits[cid]
		if cid == "AbyssalSovereignCore" and fCfg then
			if tier >= 2 and type(fCfg.Form2Moves) == "table" then
				fCfg = { Element = fCfg.Element, Moves = fCfg.Form2Moves }
			elseif tier == 1 and type(fCfg.Form1Moves) == "table" then
				fCfg = { Element = fCfg.Element, Moves = fCfg.Form1Moves }
			end
		end
		local baseMove = lookupConfigMove(fCfg, key)
		local coreDef = CORE_SKILL_DEFS[cid] or CORE_SKILL_DEFS.GaleCore
		local defMove = coreDef[key] or {}
		fb.ItemId = cid
		fb.WeaponArchetype = cid
		fb.Element = (fCfg and fCfg.Element) or coreDef.Element or "Sky"
		fb.Color = ELEMENT_COLORS[fb.Element] or Color3.fromRGB(120, 224, 255)
		for k, v in pairs(defMove) do
			fb[k] = v
		end
		if baseMove then
			fb.MoveName = baseMove.Name or fb.MoveName
			fb.Cooldown = tonumber(baseMove.Cooldown) or fb.Cooldown
			fb.Cost = tonumber(baseMove.Cost) or fb.Cost
			fb.Multiplier = tonumber(baseMove.Multiplier or baseMove.Mult) or fb.Multiplier
			fb.Range = tonumber(baseMove.Range) or fb.Range
			fb.Break = tonumber(baseMove.Break) or fb.Break
		end
		if cid == "AbyssalSovereignCore" and tier > 0 then
			local tScale = (tier >= 2 and 1.38) or 1.18
			fb.Multiplier = fb.Multiplier * ((tier >= 2 and 1.28) or 1.14)
			fb.Range = math.min(62, fb.Range * tScale)
			fb.Radius = math.min(36, fb.Radius * tScale)
		end
		if awk and CombatData and CombatData.AwakenedFruitMoves and CombatData.AwakenedFruitMoves[cid] then
			local v2 = CombatData.AwakenedFruitMoves[cid][key]
			if v2 then
				fb.MoveName = v2.Name or fb.MoveName
				fb.Multiplier = fb.Multiplier * (tonumber(v2.MultBoost) or 1.32)
				fb.Radius = math.min(44, fb.Radius * (tonumber(v2.RadiusScale) or 1.32))
				fb.Range = math.min(60, fb.Range * 1.16)
				fb.Hits = math.max(fb.Hits or 1, tonumber(v2.Hits) or 1)
				fb.Break = math.ceil(fb.Break * 1.25)
				fb.FreezeDur = tonumber(v2.FreezeDur) or fb.FreezeDur
				fb.StunDur = tonumber(v2.StunDur) or fb.StunDur
				fb.PullStrength = tonumber(v2.PullStrength) or fb.PullStrength
				fb.BurnTicks = tonumber(v2.DoTTicks) or fb.BurnTicks
				if fb.Archetype == "ChainLightning" then
					fb.ChainCount = math.max(fb.ChainCount or 5, 7)
				end
				if v2.Mechanic == "MagmaPoolDoT" and not fb.HazardKind then
					fb.HazardKind = "MagmaPool"
					fb.HazardDuration = 3.5
				end
			end
		end
	elseif slot == 3 then
		local wArch = Mechanics.ResolveWeaponArchetype(itemId)
		local wCfg = C and ((C.Swords and C.Swords[itemId]) or (C.Items and C.Items[itemId]))
		local baseMove = lookupConfigMove(wCfg, key)
		local archDef = (WEAPON_SKILL_DEFS[wArch] and WEAPON_SKILL_DEFS[wArch][key]) or WEAPON_SKILL_DEFS.Katana[key]
		fb.WeaponArchetype = wArch
		fb.Element = (wCfg and wCfg.Element) or "Aether"
		if itemId == "EternalFrost" or itemId == "cryon_frostblade" then
			fb.Element = "Ice"
			fb.FreezeDur = fb.FreezeDur or 1.4
		elseif itemId == "Stormfang" or itemId == "storm_katana" or itemId == "stormfang_daggers" or itemId == "tempest_trident" then
			fb.Element = "Lightning"
		elseif itemId == "ignivar_magma_breaker" or itemId == "dragon_cleaver" or itemId == "sol_blade" or itemId == "sunshard_halberd" then
			fb.Element = "Flame"
			fb.BurnTicks = fb.BurnTicks or 2
		elseif itemId == "aion_chrono_scythe" or itemId == "void_reaper_scythe" or itemId == "noxar_greatsword" or itemId == "noxar_abyssal_greatsword" or itemId == "abyssal_greatsword" or itemId == "yamo_voidblade" then
			fb.Element = "Void"
		end
		fb.Color = ELEMENT_COLORS[fb.Element] or Color3.fromRGB(120, 214, 255)
		for k, v in pairs(archDef or {}) do
			fb[k] = v
		end
		if baseMove then
			fb.MoveName = baseMove.Name or fb.MoveName
			fb.Cooldown = tonumber(baseMove.Cooldown) or fb.Cooldown
			fb.Cost = tonumber(baseMove.Cost) or fb.Cost
			fb.Multiplier = tonumber(baseMove.Multiplier or baseMove.Mult) or fb.Multiplier
			fb.Range = tonumber(baseMove.Range) or fb.Range
			fb.Break = tonumber(baseMove.Break) or fb.Break
		else
			fb.MoveName = wArch .. " [" .. key .. "]"
		end
	else
		local gArch = Mechanics.ResolveGunArchetype(itemId)
		local gCfg = C and C.Guns and C.Guns[itemId]
		local gSpec = CombatData and CombatData.GunSpecs and CombatData.GunSpecs[itemId]
		local baseMove = lookupConfigMove(gCfg, key)
		local archDef = (GUN_SKILL_DEFS[gArch] and GUN_SKILL_DEFS[gArch][key]) or GUN_SKILL_DEFS.PistolRifle[key]
		fb.WeaponArchetype = gArch
		fb.Element = (gSpec and gSpec.Element) or (gCfg and gCfg.Element) or "Aether"
		fb.Color = (gSpec and gSpec.Color) or ELEMENT_COLORS[fb.Element] or Color3.fromRGB(120, 214, 255)
		for k, v in pairs(archDef or {}) do
			fb[k] = v
		end
		if baseMove then
			fb.MoveName = baseMove.Name or fb.MoveName
			fb.Cooldown = tonumber(baseMove.Cooldown) or fb.Cooldown
			fb.Cost = tonumber(baseMove.Cost) or fb.Cost
			fb.Multiplier = tonumber(baseMove.Multiplier or baseMove.Mult) or fb.Multiplier
			fb.Break = tonumber(baseMove.Break) or fb.Break
		else
			fb.MoveName = gArch .. " [" .. key .. "]"
		end
	end

	local sbp = getSharedBlueprints()
	if sbp and type(sbp.GetSkillBlueprint) == "function" then
		local ok, ext = pcall(sbp.GetSkillBlueprint, slot, fb.ItemId, key, awk, tier)
		if ok and type(ext) == "table" then
			return normalizeBlueprint(ext, fb)
		end
	end
	return fb
end

function Mechanics.GetM1Blueprint(slot, itemId, comboStep, dragonTier)
	local step = math.clamp(tonumber(comboStep) or 1, 1, 4)
	local tier = tonumber(dragonTier) or 0
	local fb = {
		BlueprintId = string.format("Slot%d_%s_M1_%d", slot, tostring(itemId), step),
		Slot = slot,
		ItemId = tostring(itemId),
		Combo = step,
		PoseClip = "M1_Beat_" .. tostring(step),
	}
	local sbp = getSharedBlueprints()
	if sbp and type(sbp.GetM1Blueprint) == "function" then
		local ok, ext = pcall(sbp.GetM1Blueprint, slot, itemId, step, tier)
		if ok and type(ext) == "table" then
			return normalizeBlueprint(ext, fb)
		end
	end
	return fb
end

-- ============================================================================
-- 4-SLOT M1 MECHANICAL EXECUTION (Martial Kata, 5 Melee Archetypes, 5 Gun Archetypes)
-- ============================================================================
function Mechanics.ExecuteM1(p, slot, payload)
	local hrp, hum, ch = getCharRoot(p)
	local rt = G and G.Runtime and G.Runtime[p]
	local profile = D and D.Get(p)
	if not hrp or not hum or not rt or not profile then
		return true
	end
	ensureExpansionProfile(profile)
	ensureRuntimeFields(p, rt, profile)

	local now = os.clock()
	if now < (tonumber(rt.StunnedUntil) or 0) then
		return true
	end

	if slot == 1 then
		local styleId = Mechanics.ResolveStyleId(profile.FightingStyle)
		local style = CombatData.MartialStyles[styleId] or CombatData.MartialStyles.skyborn_combat
		if now < (rt.NextStyleM1At or 0) then
			return true
		end
		if now - (rt.LastKataAt or 0) > 1.35 then
			rt.KataStep = 1
		else
			rt.KataStep = ((rt.KataStep or 0) % 4) + 1
		end
		rt.LastKataAt = now

		local step = rt.KataStep
		local kata = style.Kata[step] or style.Kata[1]
		local m1Bp = Mechanics.GetM1Blueprint(1, styleId, step, 0)
		rt.NextStyleM1At = now + (tonumber(m1Bp.Cadence) or kata.Cadence or 0.24)

		local reach = math.min(45, tonumber(m1Bp.Reach) or kata.Reach or 16)
		local origin, dir = clampAimRay(hrp, payload, reach)
		local endPos = hrp.Position + dir * reach
		if (kata.Dash and kata.Dash > 0) or (m1Bp.DashDist and m1Bp.DashDist > 0) then
			rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, now + 0.45)
		end

		local stats = G.Stats(p, 1)
		local baseAtk = (stats and stats.ATK) or 40
		local mLv = getMasteryLevel(profile, styleId)
		local masteryMult = 1 + (mLv - 1) * CombatData.MasteryConfig.SkillDamagePerLevel
		local dmg = baseAtk * (tonumber(m1Bp.Multiplier) or kata.Mult or 1.0) * masteryMult

		local hits = Mechanics.GetEnemiesAlongSegment(hrp.Position, endPos, (kata.Width or 9) * 0.6)
		local totalDealt = 0
		local hitCount = 0
		for _, rec in ipairs(hits) do
			local e = rec.Enemy
			hitCount += 1
			if kata.Pull and pullEnemyToward then
				pullEnemyToward(e, hrp.Position + dir * 4, 8)
			end
			local hitSpec = {
				Element = style.Element,
				ArmorShred = kata.ArmorShred,
				StunDur = kata.StunDur,
				BurnTicks = kata.BurnPct and 2 or nil,
				BurnScale = kata.BurnPct,
				Knockback = (step == 4 and 10) or nil,
			}
			-- Pass "Attack" so CombatRuntimeOverrides M1 energy regeneration triggers cleanly
			totalDealt += applyMechanicalHit(p, e, dmg, kata.Break or 6, "Attack", hitSpec, true, dir)
			if not kata.AoE and hitCount >= 3 then
				break
			end
		end

		if (styleId == "SanguineVoidArt" or styleId == "sanguine_arts") and totalDealt > 0 and hum.Health > 0 then
			hum.Health = math.min(hum.MaxHealth, hum.Health + math.max(1, math.floor(totalDealt * 0.06)))
		end
		if G.SocialEconomy and type(G.SocialEconomy.ApplyPvPHitCheck) == "function" then
			pcall(G.SocialEconomy.ApplyPvPHitCheck, p, hrp.Position + dir * (reach * 0.5), dir, reach * 0.75, dmg, "StyleKata_" .. styleId)
		end
		if hitCount > 0 then
			addMasteryXP(p, styleId, 8 + step * 2)
		end

		local _, gMat, gCol = sampleGroundSurface(endPos, p)
		if R and R.CombatFX then
			R.CombatFX:FireAllClients({
				Kind = "StyleMove",
				MoveType = "Kata",
				BlueprintId = m1Bp.BlueprintId,
				Archetype = "KataBeat",
				WeaponArchetype = styleId,
				PoseClip = m1Bp.PoseClip or ("Kata_" .. styleId .. "_" .. tostring(step)),
				Slot = 1,
				StyleId = styleId,
				ItemId = styleId,
				MoveKey = "M1",
				MoveName = kata.Name,
				Combo = step,
				Element = style.Element,
				Color = style.Color,
				Origin = origin,
				Position = hrp.Position + dir * (reach * 0.6),
				EndPos = endPos,
				Direction = dir,
				Look = dir,
				GroundMaterial = gMat,
				GroundColor = gCol,
				Actor = p.UserId,
			})
		end
		return true
	elseif slot == 3 then
		if now < (tonumber(rt.NextSwordM1At) or 0) then
			return true
		end
		if now - (tonumber(rt.LastSwordComboAt) or 0) > 1.30 then
			rt.SwordComboStep = 1
		else
			rt.SwordComboStep = ((tonumber(rt.SwordComboStep) or 0) % 4) + 1
		end
		local combo = rt.SwordComboStep
		rt.LastSwordComboAt = now
		rt.Combo = combo
		rt.LastAttack = now

		local swordId = tostring((profile.Equipped and profile.Equipped.Weapon) or profile.Weapon or "starter_sword")
		local swordCfg = (C and C.Swords and C.Swords[swordId]) or (C and C.Items and C.Items[swordId]) or {}
		local wArch = Mechanics.ResolveWeaponArchetype(swordId)
		local m1Bp = Mechanics.GetM1Blueprint(3, swordId, combo, 0)
		local tfActive = ch and tostring(ch:GetAttribute("FruitTransform") or "") ~= ""

		local baseCadence = (wArch == "DualBlades" and (combo == 4 and 0.28 or 0.22))
			or (wArch == "Greatsword" and (combo == 4 and 0.42 or 0.35))
			or (wArch == "Scythe" and (combo == 4 and 0.38 or 0.31))
			or (wArch == "Spear" and (combo == 4 and 0.36 or 0.28))
			or (combo == 4 and 0.34 or 0.27)
		rt.NextSwordM1At = now + (tonumber(m1Bp.Cadence) or baseCadence)

		local baseReach = (wArch == "Spear" and (combo == 4 and 26 or 23))
			or (wArch == "Greatsword" and (combo == 4 and 23 or 19.5))
			or (wArch == "Scythe" and (combo == 4 and 22.5 or 19.5))
			or (wArch == "DualBlades" and (combo == 4 and 19 or 16.5))
			or (combo == 4 and 22 or 18)
		local baseWidth = (wArch == "Spear" and 7.2)
			or (wArch == "Greatsword" and (combo == 4 and 14.0 or 11.5))
			or (wArch == "Scythe" and (combo == 4 and 14.5 or 12.0))
			or (combo == 4 and 11.5 or 9.0)

		local reach = baseReach * (tfActive and 1.9 or 1.0)
		local width = baseWidth * (tfActive and 1.5 or 1.0)
		local origin, dir = clampAimRay(hrp, payload, reach)
		local endPos = hrp.Position + dir * reach

		if wArch == "Spear" and combo == 4 then
			rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, now + 0.55)
		end

		local stats = G.Stats(p, 3)
		local baseAtk = (stats and stats.ATK) or 45
		local mLv = getMasteryLevel(profile, swordId)
		local masteryMult = 1 + (mLv - 1) * CombatData.MasteryConfig.SkillDamagePerLevel
		local comboMult = (wArch == "Greatsword" and ((combo == 4 and 1.62) or (1.06 + combo * 0.10)))
			or (combo == 4 and 1.45)
			or (0.96 + combo * 0.08)
		local totalDmg = baseAtk * comboMult * masteryMult
		local brk = (wArch == "Greatsword" and (combo == 4 and 20 or 12)) or ((combo == 4 and 14) or 8)
		local elem = tostring(swordCfg.Element or (swordId == "EternalFrost" and "Ice") or "Aether")

		local subBeats = 1
		local subInterval = 0.06
		if wArch == "Spear" and combo == 2 then
			subBeats = 3
			subInterval = 0.055
		elseif wArch == "DualBlades" then
			subBeats = 2
			subInterval = 0.06
		end

		local perBeatDmg = totalDmg / subBeats
		local perBeatBrk = math.max(4, math.ceil(brk / subBeats))

		for beat = 1, subBeats do
			local runBeat = function()
				if not p or not p.Parent then
					return
				end
				local curHrp, curHum = getCharRoot(p)
				local bOrigin = curHrp and curHrp.Position or hrp.Position
				local bEnd = bOrigin + dir * reach
				local hits = Mechanics.GetEnemiesAlongSegment(bOrigin, bEnd, width * 0.65)
				local hitCount = 0
				local dealtSum = 0
				for _, rec in ipairs(hits) do
					local e = rec.Enemy
					hitCount += 1
					if wArch == "Scythe" and combo == 3 and beat == subBeats and pullEnemyToward then
						pullEnemyToward(e, bOrigin + dir * 5, 7)
					end
					local hitSpec = {
						WeaponArchetype = wArch,
						Element = elem,
						StunDur = (combo == 4 and beat == subBeats) and 0.34 or nil,
						FreezeDur = ((swordId == "EternalFrost" or swordId == "cryon_frostblade") and combo == 4 and beat == subBeats) and 1.1 or nil,
						Knockback = (wArch == "Greatsword" and combo == 4 and beat == subBeats) and 12 or nil,
					}
					dealtSum += applyMechanicalHit(p, e, perBeatDmg, perBeatBrk, "Attack", hitSpec, beat == subBeats, dir)
					if combo ~= 4 and hitCount >= 4 then
						break
					end
				end
				if wArch == "Scythe" and dealtSum > 0 and curHum and curHum.Health > 0 then
					curHum.Health = math.min(curHum.MaxHealth, curHum.Health + math.max(1, math.floor(dealtSum * 0.04)))
				end
				if beat == subBeats and hitCount > 0 then
					addMasteryXP(p, swordId, 8 + combo * 2)
				end
			end
			if beat == 1 then
				runBeat()
			else
				task.delay((beat - 1) * subInterval, runBeat)
			end
		end

		if G.SocialEconomy and type(G.SocialEconomy.ApplyPvPHitCheck) == "function" then
			pcall(G.SocialEconomy.ApplyPvPHitCheck, p, hrp.Position + dir * (reach * 0.5), dir, reach * 0.75, totalDmg, "SwordComboM1_" .. swordId)
		end

		local poseClip = m1Bp.PoseClip
		if not poseClip or string.sub(poseClip, 1, 8) == "M1_Beat_" then
			poseClip = (wArch == "Spear" and combo == 2 and "SpearTriplePoke")
				or (wArch == "Spear" and combo == 4 and "SpearVaultPierce")
				or (wArch .. "_M1_" .. tostring(combo))
		end
		local _, gMat, gCol = sampleGroundSurface(endPos, p)
		local impactGround = (wArch == "Greatsword" and combo == 4)

		if R and R.CombatFX then
			R.CombatFX:FireAllClients({
				Kind = "Swing",
				Action = "Attack",
				BlueprintId = m1Bp.BlueprintId,
				Archetype = wArch .. "M1",
				WeaponArchetype = wArch,
				PoseClip = poseClip,
				Slot = 3,
				WeaponId = swordId,
				ItemId = swordId,
				MoveKey = "M1",
				Combo = combo,
				Hits = subBeats,
				Element = elem,
				Origin = origin,
				Position = hrp.Position + dir * (reach * 0.55),
				EndPos = endPos,
				Direction = dir,
				Look = dir,
				ImpactGround = impactGround,
				GroundMaterial = gMat,
				GroundColor = gCol,
				Actor = p.UserId,
			})
		end
		G.FireCombatEvent({
			kind = "Swing",
			action = "Attack",
			actor = p.UserId,
			combo = combo,
			classId = profile.ClassId,
			slot = 3,
			weaponId = swordId,
			weaponArchetype = wArch,
			element = elem,
			pos = hrp.Position,
			look = dir,
		})
		return true
	elseif slot == 4 then
		local gunId = tostring((profile.Equipped and profile.Equipped.Gun) or profile.EquippedGun or "aether_flintlock")
		local gArch = Mechanics.ResolveGunArchetype(gunId)
		local spec = (CombatData and CombatData.GunSpecs and CombatData.GunSpecs[gunId]) or (CombatData and CombatData.GunSpecs and CombatData.GunSpecs.aether_flintlock) or {}
		if now < (rt.Cooldowns.GunM1 or 0) then
			return true
		end
		local cd = tonumber(spec.Cooldown) or ((gArch == "Cannon" and 0.54) or (gArch == "Railgun" and 0.58) or (gArch == "Bow" and 0.40) or 0.42)
		rt.Cooldowns.GunM1 = now + cd
		rt.GunStep = ((tonumber(rt.GunStep) or 0) % 4) + 1
		local m1Bp = Mechanics.GetM1Blueprint(4, gunId, rt.GunStep, 0)

		local maxLen = (gArch == "Railgun" and 115) or (gArch == "Bow" and 92) or 85
		local origin, dir = clampAimRay(hrp, payload, maxLen)
		local rayEnd = origin + dir * maxLen

		local stats = G.Stats(p, 4)
		local baseAtk = (stats and stats.ATK) or 45
		local mLv = getMasteryLevel(profile, gunId)
		local mult = tonumber(spec.M1Multiplier) or ((gArch == "Cannon" and 1.52) or (gArch == "Railgun" and 1.60) or 1.35)
		local skillScale = (1 + (mLv - 1) * CombatData.MasteryConfig.SkillDamagePerLevel) * (1 + ((stats and stats.StarSkillDmgPct) or 0))
		local dmg = baseAtk * mult * skillScale
		local isLyre = (gArch == "VoidLyre" or gArch == "AcousticGuitar")
		local beamRad = tonumber(spec.BeamRadius) or ((gArch == "Cannon" and 7.5) or (isLyre and 8.5) or 6.0)
		local brk = tonumber(spec.Break) or 16
		local elem = tostring(spec.Element or "Aether")

		local candidates = Mechanics.GetEnemiesAlongSegment(origin, rayEnd, beamRad)
		local totalDealt = 0
		local hitCount = 0

		for _, rec in ipairs(candidates) do
			local e = rec.Enemy
			local hitSpec = {
				WeaponArchetype = gArch,
				Element = elem,
				StunDur = isLyre and (tonumber(spec.StunDuration) or 1.4) or nil,
				AcousticStun = isLyre,
				FreezeDur = tonumber(spec.FreezeDuration) or ((gArch == "Railgun") and 2.2 or nil),
				BurnTicks = spec.BurnTicks,
				ShatterBonusMult = (gArch == "Cannon") and 1.35 or nil,
			}
			totalDealt += applyMechanicalHit(p, e, dmg, brk, "Attack", hitSpec, true, dir)
			hitCount += 1

			if gArch == "Cannon" and e.Body then
				local splash = getEnemiesInRadius(e.Body.Position, 8.5)
				for _, srec in ipairs(splash) do
					if srec.Enemy ~= e then
						applyMechanicalHit(p, srec.Enemy, dmg * 0.45, math.ceil(brk * 0.5), "CannonSplash", hitSpec, true, dir)
					end
				end
			end

			local pierces = (spec.Piercing == true) or (gArch == "Railgun") or isLyre or (gArch == "Bow" and hitCount < 2)
			if not pierces then
				rayEnd = (e.Body and e.Body.Position) or rayEnd
				break
			end
		end

		if G.SocialEconomy and type(G.SocialEconomy.ApplyPvPHitCheck) == "function" then
			pcall(G.SocialEconomy.ApplyPvPHitCheck, p, origin + dir * (maxLen * 0.5), dir, maxLen * 0.55, dmg, "Gun_" .. gunId .. "_M1")
		end

		local healAmt = 0
		if isLyre and totalDealt > 0 and hum.Health > 0 then
			healAmt = math.max(1, math.floor(totalDealt * (tonumber(spec.LifestealPct) or 0.15)))
			hum.Health = math.min(hum.MaxHealth, hum.Health + healAmt)
		end
		if hitCount > 0 then
			addMasteryXP(p, gunId, 9 + hitCount * 3)
		end

		local _, gMat, gCol = sampleGroundSurface(rayEnd, p)
		if R and R.CombatFX then
			R.CombatFX:FireAllClients({
				Kind = "GunShot",
				SubKind = spec.SubKind or gArch,
				BlueprintId = m1Bp.BlueprintId,
				Archetype = gArch .. "Shot",
				WeaponArchetype = gArch,
				PoseClip = m1Bp.PoseClip or (gArch .. "_M1"),
				Slot = 4,
				WeaponId = gunId,
				ItemId = gunId,
				MoveKey = "M1",
				Combo = rt.GunStep,
				Element = elem,
				Color = spec.Color or ELEMENT_COLORS[elem],
				Origin = origin,
				EndPos = rayEnd,
				Position = rayEnd,
				Direction = dir,
				Look = dir,
				Length = (rayEnd - origin).Magnitude,
				PiercedCount = hitCount,
				HealAmount = healAmt,
				GroundMaterial = gMat,
				GroundColor = gCol,
				Actor = p.UserId,
			})
		end
		return true
	end

	return false
end

-- ============================================================================
-- CHARGED GREATSWORD / CLEAVER CRESCENT SLASH
-- ============================================================================
function Mechanics.ExecuteChargedWeaponSlash(p, payload)
	local hrp, hum = getCharRoot(p)
	local rt = G and G.Runtime and G.Runtime[p]
	local profile = D and D.Get(p)
	if not hrp or not hum or not rt or not profile then
		return false
	end
	ensureExpansionProfile(profile)
	local swordId = tostring((profile.Equipped and profile.Equipped.Weapon) or profile.Weapon or "")
	if (tonumber(profile.ActiveSlot) or 3) ~= 3 or not CombatData.IsChargedSlashWeapon(swordId) then
		return false
	end
	local now = os.clock()
	if now < (tonumber(rt.StunnedUntil) or 0) then
		return true
	end
	local spec = CombatData.ChargedCrescentSpec
	if now < (rt.Cooldowns.ChargedCrescentSlash or 0) then
		return true
	end
	local stamCost = tonumber(spec.StaminaCost) or 14
	if (rt.Stamina or 100) < stamCost then
		G.Notify(p, "Không đủ Stamina!")
		return true
	end
	rt.Stamina = math.max(0, (rt.Stamina or 100) - stamCost)
	rt.Cooldowns.ChargedCrescentSlash = now + spec.Cooldown
	rt.Cooldowns.Heavy = now + 1.4

	local rawRatio = type(payload) == "table" and (payload.ChargeRatio or payload.chargeRatio) or 1.0
	local ratio = math.clamp(tonumber(rawRatio) or 1.0, 0, 1)
	local mult = spec.MinMultiplier + (spec.MaxMultiplier - spec.MinMultiplier) * ratio
	local range = spec.MinRange + (spec.MaxRange - spec.MinRange) * ratio
	local radius = spec.MinRadius + (spec.MaxRadius - spec.MinRadius) * ratio
	local breakAdd = math.floor(spec.MinBreakGauge + (spec.MaxBreakGauge - spec.MinBreakGauge) * ratio + 0.5)

	local origin, dir, waveEnd = clampAimRay(hrp, payload, math.min(45, range))
	local stats = G.Stats(p, 3)
	local baseAtk = (stats and stats.ATK) or 60
	local mLv = getMasteryLevel(profile, swordId)
	local skillMult = (1 + (mLv - 1) * CombatData.MasteryConfig.SkillDamagePerLevel) * (1 + ((stats and stats.StarSkillDmgPct) or 0))
	local dmg = baseAtk * mult * skillMult

	local hitSpec = {
		Archetype = "TravellingWave",
		WeaponArchetype = Mechanics.ResolveWeaponArchetype(swordId),
		Element = "VoidMagma",
		BurnTicks = 2,
		BurnScale = 0.14,
		Knockback = 12 + ratio * 8,
		ShatterBonusMult = 1.42,
	}
	local hitList = Mechanics.GetEnemiesAlongSegment(hrp.Position, hrp.Position + dir * range, radius)
	for _, rec in ipairs(hitList) do
		applyMechanicalHit(p, rec.Enemy, dmg, breakAdd, "ChargedCrescentSlash", hitSpec, true, dir)
	end
	if G.SocialEconomy and type(G.SocialEconomy.ApplyPvPHitCheck) == "function" then
		pcall(G.SocialEconomy.ApplyPvPHitCheck, p, hrp.Position + dir * (range * 0.5), dir, math.max(radius, range * 0.55), dmg, "ChargedCrescentSlash")
	end
	if #hitList > 0 then
		addMasteryXP(p, swordId, 20 + #hitList * 4)
	end

	local _, gMat, gCol = sampleGroundSurface(waveEnd, p)
	if R and R.CombatFX then
		R.CombatFX:FireAllClients({
			Kind = "ChargedSlash",
			BlueprintId = "Slot3_" .. swordId .. "_ChargedSlash",
			Archetype = "TravellingWave",
			WeaponArchetype = hitSpec.WeaponArchetype,
			PoseClip = "GreatswordChargedCrescent",
			Slot = 3,
			WeaponId = swordId,
			ItemId = swordId,
			MoveKey = "Heavy",
			MoveName = spec.Name,
			ChargeRatio = ratio,
			Multiplier = mult,
			BreakAdded = breakAdd,
			Element = "VoidMagma",
			Origin = origin,
			Position = waveEnd,
			EndPos = waveEnd,
			Direction = dir,
			Look = dir,
			Range = range,
			Radius = radius,
			ImpactGround = true,
			GroundMaterial = gMat,
			GroundColor = gCol,
			Actor = p.UserId,
		})
	end
	G.Sync(p)
	return true
end

-- ============================================================================
-- 20 DISTINCT MECHANICAL SKILL ARCHETYPE SOLVERS
-- ============================================================================
function Mechanics.ExecuteSlotSkill(p, slot, rawKey, payload)
	local hrp, hum, ch = getCharRoot(p)
	local rt = G and G.Runtime and G.Runtime[p]
	local profile = D and D.Get(p)
	if not hrp or not hum or not ch or not rt or not profile then
		return true
	end
	ensureExpansionProfile(profile)
	ensureRuntimeFields(p, rt, profile)

	local key = string.upper(tostring(rawKey or "Z"))
	if key ~= "Z" and key ~= "X" and key ~= "C" and key ~= "V" and key ~= "F" then
		key = "Z"
	end

	local now = os.clock()
	if now < (tonumber(rt.StunnedUntil) or 0) then
		return true
	end

	local itemId
	local isAwakened = false
	local dragonTier = tonumber(rt.DragonFormTier) or 0
	if slot == 1 then
		itemId = Mechanics.ResolveStyleId(profile.FightingStyle)
	elseif slot == 2 then
		itemId = Mechanics.ResolveCoreId(profile.EquippedFruit)
		if itemId == "" then
			return false
		end
		profile.EquippedFruit = itemId
		isAwakened = profile.AwakenedFruits and (profile.AwakenedFruits[itemId] == true) or false
	elseif slot == 3 then
		itemId = tostring((profile.Equipped and profile.Equipped.Weapon) or profile.Weapon or "starter_sword")
		if key == "Z" and type(payload) == "table" and (payload.ChargeRatio or payload.chargeRatio) and CombatData.IsChargedSlashWeapon(itemId) then
			return Mechanics.ExecuteChargedWeaponSlash(p, payload)
		end
	else
		itemId = tostring((profile.Equipped and profile.Equipped.Gun) or profile.EquippedGun or "aether_flintlock")
	end

	-- Special Archetypes 18 & 19: Portal World Gate [C], Dragon Fury [V], SolarTitan [Z] 0-Energy Detransform
	if slot == 2 then
		if itemId == "DimensionalPortalCore" and key == "C" and executePortalMoveC then
			executePortalMoveC(p, payload)
			return true
		end
		if itemId == "AbyssalSovereignCore" and key == "V" and executeDragonFuryMoveV then
			executeDragonFuryMoveV(p, itemId)
			return true
		end
		if itemId == "SolarTitanCore" and key == "Z" then
			local curTf = tostring(ch:GetAttribute("FruitTransform") or p:GetAttribute("FruitTransform") or "")
			if curTf == "SolarTitan" then
				if now < (rt.Cooldowns.Slot_Z or 0) or now < (rt._SolarTitanToggleAt or 0) then
					return true
				end
				rt._SolarTitanToggleAt = now + 1.2
				rt.Cooldowns.Slot_Z = now + 1.2
				rt.Cooldowns.Z = now + 1.2
				p:SetAttribute("FruitTransform", "")
				ch:SetAttribute("FruitTransform", "")
				G.Notify(p, "SOLAR TITAN SHIFT: Thu hồi Kim Thân, trở về nhân dạng (0 Energy)! / Reverted to Human form!")
				G.Sync(p)
				return true
			end
		end
	end

	-- Rule 5c: Mastery Gate BEFORE Energy/Cooldown/Movement/VFX
	if not checkMoveMasteryUnlock(p, profile, itemId, key, slot) then
		return true
	end

	local bp = Mechanics.GetSkillBlueprint(slot, itemId, key, isAwakened, dragonTier)
	local cdKey = "Slot_" .. key
	local styleCdKey = (slot == 1) and ("Style_" .. itemId .. "_" .. key) or nil
	if now < (rt.Cooldowns[cdKey] or 0) or (styleCdKey and now < (rt.Cooldowns[styleCdKey] or 0)) then
		return true
	end

	local cost = math.max(0, tonumber(bp.Cost) or 12)
	local maxE = tonumber(rt.MaxEnergy) or 100
	if cost > 0 and (tonumber(rt.Energy) or maxE) < cost then
		G.Notify(p, "Không đủ Aether Energy để thi triển [" .. tostring(bp.MoveName or key) .. "]!")
		return true
	end

	local cdMult = 1.0
	if profile.RaceV4Active and profile.Race == "Ghoul" and CombatData.RaceV4Passives and CombatData.RaceV4Passives.Ghoul then
		cdMult = 1.0 - (tonumber(CombatData.RaceV4Passives.Ghoul.CooldownReductionPct) or 0.20)
	end
	local finalCd = math.max(0.8, (tonumber(bp.Cooldown) or 6.0) * cdMult)
	rt.Cooldowns[cdKey] = now + finalCd
	rt.Cooldowns[key] = now + finalCd
	if styleCdKey then
		rt.Cooldowns[styleCdKey] = now + finalCd
	end
	if cost > 0 then
		rt.Energy = math.max(0, (tonumber(rt.Energy) or maxE) - cost)
		rt.LastCastAt = now
	end

	-- Transformation scale bonus (SolarTitan / Sovereign Dragon)
	local curTf = tostring(ch:GetAttribute("FruitTransform") or p:GetAttribute("FruitTransform") or "")
	local tfScale = (curTf == "SolarTitan" and 1.45) or (curTf == "AbyssalSovereign" and 1.32) or 1.0
	local maxClampRange = (slot == 4) and 130 or 62
	local range = math.clamp((tonumber(bp.Range) or 28) * (slot == 4 and 1.0 or tfScale), 8, maxClampRange)
	local radius = math.clamp((tonumber(bp.Radius) or 13) * (slot == 4 and 1.0 or math.min(1.35, tfScale)), 6, 44)
	local origin, dir, targetCenter = clampAimRay(hrp, payload, range)

	local stats = G.Stats(p, slot)
	local baseAtk = (stats and stats.ATK) or 50
	local mLv = getMasteryLevel(profile, itemId)
	local skillScale = (1 + (mLv - 1) * CombatData.MasteryConfig.SkillDamagePerLevel) * (1 + ((stats and stats.StarSkillDmgPct) or 0))
	local totalDmg = baseAtk * (tonumber(bp.Multiplier) or 2.8) * skillScale
	local totalBreak = math.max(8, tonumber(bp.Break) or 28)
	local actionTag = string.format("Skill_S%d_%s_%s", slot, itemId, key)
	local arch = tostring(bp.Archetype or "TravellingWave")

	local chainNodes = nil
	local impactPoints = nil
	local fxPos = targetCenter
	local fxEndPos = origin + dir * range
	local impactGround = (bp.ImpactGround == true)
	local totalLifestealDealt = 0

	local function healCasterFromDealt(dealtAmt)
		local ls = tonumber(bp.LifestealPct) or 0
		if ls > 0 and dealtAmt > 0 and hum and hum.Parent and hum.Health > 0 then
			local heal = math.max(1, math.floor(dealtAmt * ls))
			hum.Health = math.min(hum.MaxHealth, hum.Health + heal)
			return heal
		end
		return 0
	end

	local function spawnConfiguredHazard(pos)
		if bp.HazardKind and bp.HazardKind ~= "" then
			Mechanics.SpawnHazardZone(
				p,
				bp.HazardKind,
				pos,
				math.max(9, radius * 0.78),
				tonumber(bp.HazardDuration) or 3.4,
				totalDmg * 0.16,
				bp.Element
			)
		end
	end

	-- ========================================================================
	-- ARCHETYPE DISPATCH (All 20 Distinct Mechanical Solvers)
	-- ========================================================================
	if arch == "TransformToggle" and slot == 2 and itemId == "SolarTitanCore" then
		p:SetAttribute("FruitTransform", "SolarTitan")
		ch:SetAttribute("FruitTransform", "SolarTitan")
		G.Notify(p, isAwakened
			and "AWAKENED SOLAR TITAN SHIFT: Hóa Đại Kim Thân Thức Tỉnh 3D (+58% Giáp, x2.5 Tầm Đánh)!"
			or "SOLAR TITAN SHIFT: Hóa Kim Thân Khổng Lồ 3D (+58% Giáp, x2.5 Tầm Đánh)!")
		fxPos = origin
		impactGround = true
		local burst = getEnemiesInRadius(origin, radius * 1.15)
		for _, rec in ipairs(burst) do
			applyMechanicalHit(p, rec.Enemy, totalDmg, totalBreak, actionTag, bp, true, (rec.Enemy.Body.Position - origin))
		end
		addMasteryXP(p, itemId, 20 + #burst * 3)

	elseif key == "F" and slot == 2 and Mechanics.IsTrueFlightCore(itemId, dragonTier) then
		-- Rule 2: True Flight Core [F] -> Extend JumpPadUntil without TeleportSnap so startFreeFlight() is seamless!
		local flightBoost = (mLv >= CombatData.MasteryConfig.FlightEnhancedLevel) and 1.35 or 1.0
		rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, now + (3.2 * flightBoost))
		fxPos = origin
		local launchHits = getEnemiesInRadius(origin, radius)
		for _, rec in ipairs(launchHits) do
			applyMechanicalHit(p, rec.Enemy, totalDmg * 0.75, math.ceil(totalBreak * 0.7), actionTag, bp, true, dir)
		end
		addMasteryXP(p, itemId, 16 + #launchHits * 3)

	elseif arch == "MobilityDashHit" or key == "F" then
		-- Rule 2: Non-Flight [F] Cores & Slots 1/3/4 [F] -> Instant 0ms Raycast-Safe Dash + Slash/Shock/Freeze along path
		local dashDist = tonumber(bp.DashDist) or ((slot == 2 and 44) or 40)
		local dashTarget = computeSafeDashTarget(p, origin, dir, dashDist, true)
		rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, now + 1.35)
		rt.InvincibleUntil = math.max(rt.InvincibleUntil or 0, now + 0.38)
		G.Teleport(p, dashTarget)
		fxPos = dashTarget
		fxEndPos = dashTarget
		local crossed = Mechanics.GetEnemiesAlongSegment(origin, dashTarget, radius)
		for _, rec in ipairs(crossed) do
			totalLifestealDealt += applyMechanicalHit(p, rec.Enemy, totalDmg, totalBreak, actionTag, bp, true, dir)
		end
		healCasterFromDealt(totalLifestealDealt)
		addMasteryXP(p, itemId, 16 + #crossed * 3)

	elseif arch == "ChainLightning" then
		chainNodes = { origin }
		local visited = {}
		local curPos = origin + dir * math.min(14, range * 0.45)
		local maxHops = math.clamp(math.floor(tonumber(bp.ChainCount) or 5), 2, 8)
		local hopRad = math.clamp(tonumber(bp.ChainRadius) or 22, 12, 34)
		local hopTargets = {}

		for hop = 1, maxHops do
			local bestE, bestDist = nil, (hop == 1 and (range + 8) or hopRad)
			for _, e in ipairs(G.Enemies or {}) do
				if e.Alive and e.Body and e.Model and e.Model.Parent and not visited[e] then
					local d = (e.Body.Position - (hop == 1 and (origin + dir * (range * 0.5)) or curPos)).Magnitude
					if d <= bestDist then
						bestDist = d
						bestE = e
					end
				end
			end
			if not bestE then
				break
			end
			visited[bestE] = true
			curPos = bestE.Body.Position
			table.insert(chainNodes, curPos)
			table.insert(hopTargets, bestE)
		end
		if #chainNodes == 1 then
			table.insert(chainNodes, fxEndPos)
		end
		fxPos = chainNodes[#chainNodes]

		local hopDmg = totalDmg * 0.82
		for idx, targetE in ipairs(hopTargets) do
			task.delay((idx - 1) * 0.06, function()
				if not p or not p.Parent then
					return
				end
				local dealt = applyMechanicalHit(p, targetE, hopDmg, math.ceil(totalBreak * 0.7), actionTag, bp, true, dir)
				healCasterFromDealt(dealt)
			end)
		end
		addMasteryXP(p, itemId, 18 + #hopTargets * 4)

	elseif arch == "BlinkDelayedSlash" then
		local dashDist = tonumber(bp.DashDist) or math.min(30, range)
		local dashTarget = computeSafeDashTarget(p, origin, dir, dashDist, true)
		rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, now + 1.25)
		rt.InvincibleUntil = math.max(rt.InvincibleUntil or 0, now + 0.40)
		G.Teleport(p, dashTarget)
		fxPos = dashTarget
		fxEndPos = dashTarget

		local crossed = Mechanics.GetEnemiesAlongSegment(origin, dashTarget, radius)
		for _, rec in ipairs(crossed) do
			totalLifestealDealt += applyMechanicalHit(p, rec.Enemy, totalDmg * 0.35, math.ceil(totalBreak * 0.35), actionTag, nil, false, dir)
		end
		healCasterFromDealt(totalLifestealDealt)

		local delaySec = math.clamp(tonumber(bp.ImpactDelaySec) or 0.24, 0.14, 0.45)
		task.delay(delaySec, function()
			if not p or not p.Parent then
				return
			end
			local popDealt = 0
			for _, rec in ipairs(crossed) do
				popDealt += applyMechanicalHit(p, rec.Enemy, totalDmg * 0.65, math.ceil(totalBreak * 0.65), actionTag .. "_Pop", bp, true, dir)
			end
			healCasterFromDealt(popDealt)
			spawnConfiguredHazard(dashTarget)
			if #crossed > 0 then
				addMasteryXP(p, itemId, 18 + #crossed * 4)
			end
		end)

	elseif arch == "TravellingWave" then
		local steps = 4
		local hitAlready = {}
		for s = 1, steps do
			local frac0 = (s - 1) / steps
			local frac1 = s / steps
			task.delay((s - 1) * 0.055, function()
				if not p or not p.Parent then
					return
				end
				local segA = origin + dir * (range * frac0)
				local segB = origin + dir * (range * frac1)
				local segHits = Mechanics.GetEnemiesAlongSegment(segA, segB, radius)
				local hitNow = 0
				for _, rec in ipairs(segHits) do
					if not hitAlready[rec.Enemy] then
						hitAlready[rec.Enemy] = true
						hitNow += 1
						applyMechanicalHit(p, rec.Enemy, totalDmg, totalBreak, actionTag, bp, true, dir)
					end
				end
				if s == steps then
					spawnConfiguredHazard(origin + dir * (range * 0.85))
					if next(hitAlready) ~= nil then
						addMasteryXP(p, itemId, 18 + hitNow * 4)
					end
				end
			end)
		end

	elseif arch == "MultiLaneSpikes" then
		impactPoints = {}
		local angles = { math.rad(-18), 0, math.rad(18) }
		local hitAlready = {}
		for _, ang in ipairs(angles) do
			local ca, sa = math.cos(ang), math.sin(ang)
			local laneDir = Vector3.new(dir.X * ca - dir.Z * sa, dir.Y, dir.X * sa + dir.Z * ca)
			if laneDir.Magnitude > 0.05 then
				laneDir = laneDir.Unit
			else
				laneDir = dir
			end
			local gp = sampleGroundSurface(origin + laneDir * range, p)
			table.insert(impactPoints, gp)
		end
		impactGround = true

		for step = 1, 3 do
			task.delay((step - 1) * 0.065, function()
				if not p or not p.Parent then
					return
				end
				local f0 = (step - 1) / 3
				local f1 = step / 3
				for _, ang in ipairs(angles) do
					local ca, sa = math.cos(ang), math.sin(ang)
					local laneDir = Vector3.new(dir.X * ca - dir.Z * sa, dir.Y, dir.X * sa + dir.Z * ca).Unit
					local segHits = Mechanics.GetEnemiesAlongSegment(origin + laneDir * (range * f0), origin + laneDir * (range * f1), radius * 0.78)
					for _, rec in ipairs(segHits) do
						if not hitAlready[rec.Enemy] then
							hitAlready[rec.Enemy] = true
							applyMechanicalHit(p, rec.Enemy, totalDmg, totalBreak, actionTag, bp, true, laneDir)
						end
					end
				end
				if step == 3 and next(hitAlready) ~= nil then
					addMasteryXP(p, itemId, 20)
				end
			end)
		end

	elseif arch == "SpreadVolley" then
		local pulses = math.clamp(math.floor(tonumber(bp.Hits) or 5), 2, 8)
		local interval = math.clamp(tonumber(bp.HitInterval) or 0.08, 0.05, 0.16)
		local perPulseDmg = totalDmg / pulses
		local perPulseBrk = math.max(4, math.ceil(totalBreak / pulses))
		for pulse = 1, pulses do
			task.delay((pulse - 1) * interval, function()
				if not p or not p.Parent then
					return
				end
				local curHrp = getCharRoot(p)
				local pOrig = curHrp and curHrp.Position or origin
				local pEnd = pOrig + dir * range
				local hits = Mechanics.GetEnemiesAlongSegment(pOrig, pEnd, radius)
				local pulseDealt = 0
				for _, rec in ipairs(hits) do
					pulseDealt += applyMechanicalHit(p, rec.Enemy, perPulseDmg, perPulseBrk, actionTag, bp, pulse == pulses, dir)
				end
				healCasterFromDealt(pulseDealt)
				if pulse == pulses and #hits > 0 then
					addMasteryXP(p, itemId, 18 + #hits * 3)
				end
			end)
		end

	elseif arch == "PiercingBeam" then
		local pulses = math.clamp(math.floor(tonumber(bp.Hits) or 1), 1, 5)
		local interval = math.clamp(tonumber(bp.HitInterval) or 0.08, 0.05, 0.15)
		local perPulseDmg = totalDmg / pulses
		local perPulseBrk = math.max(5, math.ceil(totalBreak / pulses))
		fxPos = fxEndPos
		for pulse = 1, pulses do
			local runBeam = function()
				if not p or not p.Parent then
					return
				end
				local hits = Mechanics.GetEnemiesAlongSegment(origin, fxEndPos, radius * 0.78)
				for _, rec in ipairs(hits) do
					applyMechanicalHit(p, rec.Enemy, perPulseDmg, perPulseBrk, actionTag, bp, pulse == pulses, dir)
				end
				if pulse == pulses and #hits > 0 then
					addMasteryXP(p, itemId, 18 + #hits * 3)
				end
			end
			if pulse == 1 then
				runBeam()
			else
				task.delay((pulse - 1) * interval, runBeam)
			end
		end

	elseif arch == "HarmonicSiphonWave" then
		local hits = Mechanics.GetEnemiesAlongSegment(origin, fxEndPos, radius)
		for _, rec in ipairs(hits) do
			if bp.PullStrength and pullEnemyToward then
				pullEnemyToward(rec.Enemy, origin + dir * 7, tonumber(bp.PullStrength) or 12)
			end
			totalLifestealDealt += applyMechanicalHit(p, rec.Enemy, totalDmg, totalBreak, actionTag, bp, true, dir)
		end
		healCasterFromDealt(totalLifestealDealt)
		if #hits > 0 then
			addMasteryXP(p, itemId, 18 + #hits * 4)
		end

	elseif arch == "VortexPullCage" then
		local pulses = math.clamp(math.floor(tonumber(bp.Hits) or 4), 2, 6)
		local perPulseDmg = totalDmg / pulses
		local perPulseBrk = math.max(4, math.ceil(totalBreak / pulses))
		local pullStr = (tonumber(bp.PullStrength) or 14) / math.max(1, pulses * 0.5)
		spawnConfiguredHazard(targetCenter)
		for pulse = 1, pulses do
			task.delay((pulse - 1) * 0.11, function()
				if not p or not p.Parent then
					return
				end
				local hits = getEnemiesInRadius(targetCenter, radius, origin, dir)
				local pulseDealt = 0
				for _, rec in ipairs(hits) do
					if pullEnemyToward then
						pullEnemyToward(rec.Enemy, targetCenter, pullStr)
					end
					pulseDealt += applyMechanicalHit(p, rec.Enemy, perPulseDmg, perPulseBrk, actionTag, bp, pulse == pulses, dir)
				end
				healCasterFromDealt(pulseDealt)
				if pulse == pulses and #hits > 0 then
					addMasteryXP(p, itemId, 20 + #hits * 3)
				end
			end)
		end

	elseif arch == "SandCoffinImplode" then
		local snared = getEnemiesInRadius(targetCenter, radius, origin, dir)
		for _, rec in ipairs(snared) do
			if pullEnemyToward then
				pullEnemyToward(rec.Enemy, targetCenter, tonumber(bp.PullStrength) or 15)
			end
			rec.Enemy.SlowedUntil = math.max(rec.Enemy.SlowedUntil or 0, now + 0.8)
			applyMechanicalHit(p, rec.Enemy, totalDmg * 0.28, math.ceil(totalBreak * 0.3), actionTag .. "_Bind", nil, false, dir)
		end
		local delaySec = math.clamp(tonumber(bp.ImpactDelaySec) or 0.30, 0.18, 0.45)
		task.delay(delaySec, function()
			if not p or not p.Parent then
				return
			end
			local crushHits = getEnemiesInRadius(targetCenter, radius * 1.05)
			for _, rec in ipairs(crushHits) do
				applyMechanicalHit(p, rec.Enemy, totalDmg * 0.72, math.ceil(totalBreak * 0.7), actionTag .. "_Crush", bp, true, dir)
			end
			spawnConfiguredHazard(targetCenter)
			if #crushHits > 0 then
				addMasteryXP(p, itemId, 20 + #crushHits * 4)
			end
		end)

	elseif arch == "DragRushSlam" then
		local dashDist = tonumber(bp.DashDist) or math.min(28, range)
		local dashTarget = computeSafeDashTarget(p, origin, dir, dashDist, false)
		rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, now + 1.25)
		rt.InvincibleUntil = math.max(rt.InvincibleUntil or 0, now + 0.32)
		G.Teleport(p, dashTarget)
		fxPos = dashTarget
		fxEndPos = dashTarget
		impactGround = true

		local caught = Mechanics.GetEnemiesAlongSegment(origin, dashTarget, radius)
		for _, rec in ipairs(caught) do
			if pullEnemyToward then
				pullEnemyToward(rec.Enemy, dashTarget + dir * 2.5, dashDist * 0.65)
			end
			totalLifestealDealt += applyMechanicalHit(p, rec.Enemy, totalDmg, totalBreak, actionTag, bp, true, dir)
		end
		healCasterFromDealt(totalLifestealDealt)
		spawnConfiguredHazard(dashTarget)
		if #caught > 0 then
			addMasteryXP(p, itemId, 18 + #caught * 4)
		end

	elseif arch == "PoleVaultSlam" then
		local dashDist = tonumber(bp.DashDist) or math.min(22, range)
		local slamTarget = computeSafeDashTarget(p, origin, dir, dashDist, false)
		rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, now + 1.55)
		rt.InvincibleUntil = math.max(rt.InvincibleUntil or 0, now + 0.35)
		fxPos = slamTarget
		fxEndPos = slamTarget
		impactGround = true

		local delaySec = math.clamp(tonumber(bp.ImpactDelaySec) or 0.20, 0.12, 0.35)
		task.delay(delaySec, function()
			if not p or not p.Parent then
				return
			end
			local _, curHum = getCharRoot(p)
			if curHum and curHum.Health > 0 and os.clock() >= (tonumber(rt.StunnedUntil) or 0) then
				G.Teleport(p, slamTarget)
			end
			local slamHits = getEnemiesInRadius(slamTarget, radius * 1.1)
			for _, rec in ipairs(slamHits) do
				applyMechanicalHit(p, rec.Enemy, totalDmg, totalBreak, actionTag, bp, true, dir)
			end
			spawnConfiguredHazard(slamTarget)
			if #slamHits > 0 then
				addMasteryXP(p, itemId, 18 + #slamHits * 4)
			end
		end)

	elseif arch == "ZigZagMirrorKick" then
		local dashDist = tonumber(bp.DashDist) or math.min(30, range)
		local finalTarget = computeSafeDashTarget(p, origin, dir, dashDist, true)
		local right = dir:Cross(Vector3.new(0, 1, 0))
		if right.Magnitude < 0.05 then
			right = Vector3.new(1, 0, 0)
		else
			right = right.Unit
		end
		chainNodes = { origin }
		local bounces = math.clamp(math.floor(tonumber(bp.ChainCount) or 5), 3, 6)
		for i = 1, bounces - 1 do
			local alpha = i / bounces
			local side = (i % 2 == 1) and 5.5 or -5.5
			local mid = origin:Lerp(finalTarget, alpha) + right * side + Vector3.new(0, (i % 2 == 1) and 3.5 or 1.0, 0)
			table.insert(chainNodes, mid)
		end
		table.insert(chainNodes, finalTarget)

		rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, now + 1.35)
		rt.InvincibleUntil = math.max(rt.InvincibleUntil or 0, now + 0.42)
		G.Teleport(p, finalTarget)
		fxPos = finalTarget
		fxEndPos = finalTarget
		impactGround = true

		local corridorHits = Mechanics.GetEnemiesAlongSegment(origin, finalTarget, radius * 1.15)
		for _, rec in ipairs(corridorHits) do
			applyMechanicalHit(p, rec.Enemy, totalDmg, totalBreak, actionTag, bp, true, dir)
		end
		if #corridorHits > 0 then
			addMasteryXP(p, itemId, 20 + #corridorHits * 4)
		end

	elseif arch == "RiftPhaseEscape" then
		local dashDist = tonumber(bp.DashDist) or 18
		local phaseTarget = computeSafeDashTarget(p, origin, dir, dashDist, true)
		rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, now + 1.3)
		rt.InvincibleUntil = math.max(rt.InvincibleUntil or 0, now + 0.80)
		G.Teleport(p, phaseTarget)
		fxPos = phaseTarget
		fxEndPos = phaseTarget

		task.delay(math.clamp(tonumber(bp.ImpactDelaySec) or 0.25, 0.14, 0.40), function()
			if not p or not p.Parent then
				return
			end
			local riftHits = getEnemiesInRadius(origin, radius)
			for _, rec in ipairs(riftHits) do
				applyMechanicalHit(p, rec.Enemy, totalDmg, totalBreak, actionTag, bp, true, dir)
			end
			if #riftHits > 0 then
				addMasteryXP(p, itemId, 18 + #riftHits * 4)
			end
		end)

	elseif arch == "SkyfallSphere" then
		rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, now + 1.65)
		local groundImpact = sampleGroundSurface(targetCenter, p)
		impactPoints = { groundImpact }
		fxPos = groundImpact
		impactGround = true

		local delaySec = math.clamp(tonumber(bp.ImpactDelaySec) or 0.38, 0.20, 0.55)
		task.delay(delaySec, function()
			if not p or not p.Parent then
				return
			end
			local sphereHits = getEnemiesInRadius(groundImpact, radius * 1.12, origin, dir)
			local dealtSum = 0
			for _, rec in ipairs(sphereHits) do
				if bp.PullStrength and pullEnemyToward then
					pullEnemyToward(rec.Enemy, groundImpact, tonumber(bp.PullStrength) or 14)
				end
				dealtSum += applyMechanicalHit(p, rec.Enemy, totalDmg, totalBreak, actionTag, bp, true, dir)
			end
			healCasterFromDealt(dealtSum)
			spawnConfiguredHazard(groundImpact)
			if #sphereHits > 0 then
				addMasteryXP(p, itemId, 24 + #sphereHits * 4)
			end
		end)

	elseif arch == "MeteorShower" then
		rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, now + 1.55)
		local count = math.clamp(math.floor(tonumber(bp.Hits) or 6), 3, 8)
		impactPoints = {}
		local centerGround = sampleGroundSurface(targetCenter, p)
		table.insert(impactPoints, centerGround)
		for i = 2, count do
			local ang = (i - 1) * 2.39996
			local ringR = math.min(radius * 0.65, 5 + (i % 3) * 4.5)
			local offset = Vector3.new(math.cos(ang) * ringR, 0, math.sin(ang) * ringR)
			local gp = sampleGroundSurface(targetCenter + offset, p)
			table.insert(impactPoints, gp)
		end
		fxPos = centerGround
		impactGround = true

		if bp.PullStrength and pullEnemyToward then
			local prePull = getEnemiesInRadius(centerGround, radius * 1.15)
			for _, rec in ipairs(prePull) do
				pullEnemyToward(rec.Enemy, centerGround, tonumber(bp.PullStrength) or 14)
			end
		end

		local perMeteorDmg = totalDmg / count
		local perMeteorBrk = math.max(5, math.ceil(totalBreak / count))
		for idx, pt in ipairs(impactPoints) do
			task.delay(0.14 + (idx - 1) * 0.085, function()
				if not p or not p.Parent then
					return
				end
				local mHits = getEnemiesInRadius(pt, math.max(10, radius * 0.68))
				for _, rec in ipairs(mHits) do
					applyMechanicalHit(p, rec.Enemy, perMeteorDmg, perMeteorBrk, actionTag, bp, idx == count, dir)
				end
				if idx == 1 or idx == count then
					spawnConfiguredHazard(pt)
				end
				if idx == count and #mHits > 0 then
					addMasteryXP(p, itemId, 24 + #mHits * 4)
				end
			end)
		end

	elseif arch == "SkybeamPillars" then
		local count = math.clamp(math.floor(tonumber(bp.Hits) or 6), 3, 8)
		impactPoints = {}
		local baseCenter = (key == "V") and origin or targetCenter
		for i = 1, count do
			local ang = ((i - 1) / count) * math.pi * 2
			local rDist = (i == 1 and key ~= "V") and 0 or math.max(6, radius * 0.55)
			local gp = sampleGroundSurface(baseCenter + Vector3.new(math.cos(ang) * rDist, 0, math.sin(ang) * rDist), p)
			table.insert(impactPoints, gp)
		end
		fxPos = baseCenter
		impactGround = true

		local perPillarDmg = totalDmg / math.max(1, math.ceil(count * 0.5))
		local hitCounts = {}
		for idx, pt in ipairs(impactPoints) do
			task.delay((idx - 1) * 0.055, function()
				if not p or not p.Parent then
					return
				end
				local pHits = getEnemiesInRadius(pt, math.max(9.5, radius * 0.58), origin, dir)
				for _, rec in ipairs(pHits) do
					local c = (hitCounts[rec.Enemy] or 0) + 1
					if c <= 3 then
						hitCounts[rec.Enemy] = c
						applyMechanicalHit(p, rec.Enemy, perPillarDmg * (c == 1 and 1.0 or 0.35), math.ceil(totalBreak * 0.4), actionTag, bp, idx == count or c == 1, dir)
					end
				end
				if idx == count then
					spawnConfiguredHazard(baseCenter)
					if next(hitCounts) ~= nil then
						addMasteryXP(p, itemId, 22)
					end
				end
			end)
		end

	else
		-- Archetype 17: GroundMonolithShatter (and safe fallback)
		local groundImpact = sampleGroundSurface(targetCenter, p)
		impactPoints = { groundImpact }
		fxPos = groundImpact
		impactGround = true
		local hits = Mechanics.GetEnemiesAlongSegment(origin, fxEndPos, radius)
		for _, rec in ipairs(hits) do
			applyMechanicalHit(p, rec.Enemy, totalDmg, totalBreak, actionTag, bp, true, dir)
		end
		spawnConfiguredHazard(groundImpact)
		if #hits > 0 then
			addMasteryXP(p, itemId, 20 + #hits * 4)
		end
	end

	-- Single-dispatch PvP hit check (respecting SafeZones & PvPEnabled)
	if G.SocialEconomy and type(G.SocialEconomy.ApplyPvPHitCheck) == "function" then
		pcall(G.SocialEconomy.ApplyPvPHitCheck, p, fxPos, dir, math.max(radius, range * 0.5), totalDmg * 0.55, actionTag)
	end

	-- Sample ground material & color for authentic dust/debris VFX
	local _, gMat, gCol = sampleGroundSurface(fxPos, p)

	-- Preserve exact legacy Kind per slot while enriching with full Stage 1/2 Blueprint & Choreography metadata
	local fxKind = (slot == 1 and "StyleMove")
		or (slot == 4 and "GunShot")
		or (slot == 2 and isAwakened and "FruitMove")
		or "Skill"

	if R and R.CombatFX then
		R.CombatFX:FireAllClients({
			Kind = fxKind,
			MoveType = (slot == 1 and "Technique") or nil,
			SubKind = (slot == 4 and bp.WeaponArchetype) or arch,
			BlueprintId = bp.BlueprintId,
			Archetype = arch,
			Mechanic = arch,
			WeaponArchetype = bp.WeaponArchetype,
			PoseClip = bp.PoseClip,
			Slot = slot,
			ItemId = itemId,
			FruitId = (slot == 2) and itemId or nil,
			StyleId = (slot == 1) and itemId or nil,
			WeaponId = (slot == 3 or slot == 4) and itemId or nil,
			Awakened = isAwakened,
			TransformTier = (slot == 2 and itemId == "AbyssalSovereignCore" and dragonTier) or (curTf == "SolarTitan" and 1) or 0,
			MoveKey = key,
			MoveName = bp.MoveName,
			Combo = 0,
			Hits = tonumber(bp.Hits) or 1,
			Element = bp.Element,
			Color = bp.Color or ELEMENT_COLORS[bp.Element],
			Origin = origin,
			Position = fxPos,
			EndPos = fxEndPos,
			DashEnd = (arch == "MobilityDashHit" or arch == "BlinkDelayedSlash" or arch == "DragRushSlam" or arch == "ZigZagMirrorKick") and fxPos or nil,
			Direction = dir,
			Look = dir,
			Range = range,
			Radius = radius,
			Length = (fxEndPos - origin).Magnitude,
			ChainNodes = chainNodes,
			ImpactPoints = impactPoints,
			ImpactGround = impactGround,
			GroundMaterial = gMat,
			GroundColor = gCol,
			HazardKind = bp.HazardKind,
			HazardDuration = bp.HazardDuration,
			IsUltimate = (bp.IsUltimate == true) or (key == "V"),
			Actor = p.UserId,
		})
	end

	G.FireCombatEvent({
		kind = "Skill",
		actor = p.UserId,
		key = key,
		move = bp.MoveName,
		slot = slot,
		archetype = arch,
		weaponArchetype = bp.WeaponArchetype,
		element = bp.Element,
		fruitId = (slot == 2) and itemId or nil,
		weaponId = (slot == 3 or slot == 4) and itemId or nil,
		pos = origin,
		target = fxPos,
		look = dir,
		radius = radius,
	})

	G.Sync(p)
	return true
end

function Mechanics.Init(deps)
	C = deps.Config
	D = deps.Data
	G = deps.Game
	W = deps.World
	R = deps.Remotes
	CombatData = deps.CombatData
	ensureExpansionProfile = deps.EnsureProfile
	ensureRuntimeFields = deps.EnsureRuntime
	checkMoveMasteryUnlock = deps.CheckMastery
	getMasteryLevel = deps.GetMasteryLevel
	addMasteryXP = deps.AddMasteryXP
	applyCryoFreeze = deps.ApplyCryoFreeze
	applyBurnOrDoT = deps.ApplyBurnOrDoT
	pullEnemyToward = deps.PullEnemyToward
	isBossEnemy = deps.IsBossEnemy
	groundYAt = deps.GroundYAt
	clampAimRay = deps.ClampAimRay
	ensureWorldFolder = deps.EnsureWorldFolder
	executePortalMoveC = deps.ExecutePortalMoveC
	executeDragonFuryMoveV = deps.ExecuteDragonFuryMoveV
end

return Mechanics
