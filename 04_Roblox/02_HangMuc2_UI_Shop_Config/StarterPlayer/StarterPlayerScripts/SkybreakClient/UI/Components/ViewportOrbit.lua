--!strict
--[[
	ViewportOrbit.lua (#9, #3)
	Reusable interactive 3D ViewportFrame orbit, pan-pitch, zoom & auto-turntable controller.
	- Idle auto-turntable (+0.45 rad/s)
	- Left-Click & Touch drag inside ViewportFrame: 360 deg yaw, -45..+55 deg pitch
	- Mouse-Wheel scroll zoom: 0.55x..1.75x fit radius
	- Hint caption: "Kéo để xoay 360° • Lăn chuột để Zoom"
	- Leak-free cleanup of RunService/Input connections and cloned 3D models.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(ReplicatedStorage:WaitForChild("SkybreakShared"):WaitForChild("Config"):WaitForChild("Theme"))
local RarityConfig = require(ReplicatedStorage:WaitForChild("SkybreakShared"):WaitForChild("Config"):WaitForChild("RarityConfig"))
local I18n = require(script.Parent.Parent:WaitForChild("I18n"))

local ViewportOrbit = {}

local CachedRenderer: any = nil

function ViewportOrbit.GetRenderer(): any
	if not CachedRenderer then
		local mod = ReplicatedStorage:FindFirstChild("DelegatedV5Renderer")
		if mod and mod:IsA("ModuleScript") then
			local ok, r = pcall(require, mod)
			if ok and r then
				CachedRenderer = r
			end
		end
	end
	return CachedRenderer
end

-- Explicit individual 3D Blender weapon/fruit resolver (never uses combined MythicalWeaponsSet)
local EXPLICIT_WEAPON_MAP: { [string]: string } = {
	starter_sword = "Wep_Dawnbringer",
	Dawnbringer = "Wep_Dawnbringer",
	dawnbringer_sword = "Wep_Dawnbringer",
	saber_of_aureon = "Wep_CursedBladeRight",
	starter_daggers = "Wep_CursedBladeLeft",
	Stormfang = "Wep_CursedDualSkyblades",
	stormfang_daggers = "Wep_CursedDualSkyblades",
	cursed_dual_skyblades = "Wep_CursedDualSkyblades",
	starter_staff = "Wep_CryonFrostblade",
	EternalFrost = "Wep_CryonFrostblade",
	astral_staff = "Wep_CryonFrostblade",
	cryon_frostblade = "Wep_CryonFrostblade",
	noxar_abyssal_greatsword = "Wep_NoxarGreatsword",
	ArchitectsSeverance = "Wep_NoxarGreatsword",
	soul_guitar_void = "Wep_SoulGuitarVoid",
	cryo_railgun = "Wep_CryoRailgun",
	solar_kabucha = "Wep_CryoRailgun",
	kabucha_wind = "Wep_CryoRailgun",
	bizarre_rifle_cyber = "Wep_CryoRailgun",
	aether_flintlock = "Wep_CryoRailgun",
}

local KNOWN_DEVIL_FRUITS: { [string]: boolean } = {
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

local DIRECT_BESPOKE_KINDS: { [string]: boolean } = {
	halberd = true,
	katana = true,
	greatsaber = true,
	warhammer = true,
	trident = true,
	scythe = true,
	bow = true,
	cannon = true,
	dualpistols = true,
	railcannon = true,
	Helm = true,
	Chest = true,
	Gauntlets = true,
	Greaves = true,
	Ring = true,
	Artifact = true,
	Materials = true,
}

local SHIP_IDS: { [string]: boolean } = {
	SkySloop = true,
	CyberEnforcerShip = true,
	CyberEnforcer = true,
	CelestialAetherGalleon = true,
	CelestialBrigantine = true,
	LeviathanHunterShip = true,
}

local MARTIAL_IDS: { [string]: boolean } = {
	skyborn_combat = true,
	SkybornCombat = true,
	SkyStep = true,
	jade_dragon = true,
	GlacialFist = true,
	thunder_talon = true,
	ElectricClaw = true,
	solar_ashura = true,
	AbyssalTalon = true,
	celestial_godhuman = true,
	CelestialGodhuman = true,
	ChronoVoidPalm = true,
	chrono_void_palm = true,
}

local function parseHexColor(hex: string?): Color3?
	if type(hex) ~= "string" then
		return nil
	end
	local clean = string.gsub(hex, "#", "")
	if #clean ~= 6 then
		return nil
	end
	local r = tonumber(string.sub(clean, 1, 2), 16)
	local g = tonumber(string.sub(clean, 3, 4), 16)
	local b = tonumber(string.sub(clean, 5, 6), 16)
	if r and g and b then
		return Color3.fromRGB(r, g, b)
	end
	return nil
end

function ViewportOrbit.ResolveAssetName(idOrAsset: string): string?
	local key = tostring(idOrAsset or "")
	if key == "" or key == "MythicalWeaponsSet" then
		return nil
	end
	if string.sub(key, 1, 4) == "Wep_" or string.sub(key, 1, 6) == "Fruit_" then
		return key
	end
	if EXPLICIT_WEAPON_MAP[key] then
		return EXPLICIT_WEAPON_MAP[key]
	end
	if DIRECT_BESPOKE_KINDS[key] or string.sub(key, 1, 5) == "Ship_" or string.sub(key, 1, 8) == "Martial_" or SHIP_IDS[key] or MARTIAL_IDS[key] then
		return nil
	end
	local itemDef = RarityConfig.Items and RarityConfig.Items[key]
	if itemDef and (itemDef.Model3DKind ~= nil or itemDef.Category == "Armor" or itemDef.Category == "Materials" or itemDef.Category == "Quest") then
		return nil
	end
	local renderer = ViewportOrbit.GetRenderer()
	if renderer then
		if type(renderer.Models) == "table" and renderer.Models[key] then
			return key
		end
		if type(renderer.FruitAssetMap) == "table" and renderer.FruitAssetMap[key] then
			return renderer.FruitAssetMap[key]
		end
		if type(renderer.Alias) == "table" and renderer.Alias[key] and renderer.Alias[key] ~= "MythicalWeaponsSet" then
			return renderer.Alias[key]
		end
		if type(renderer.GetWeaponAsset) == "function" and not itemDef then
			local wep = renderer.GetWeaponAsset(key)
			if type(wep) == "string" and wep ~= "" and wep ~= "MythicalWeaponsSet" then
				return wep
			end
		end
	end
	if KNOWN_DEVIL_FRUITS[key] or (not itemDef and string.sub(key, -4) == "Core") then
		return "Fruit_" .. key
	end
	return nil
end

function ViewportOrbit.SanitizeModelForViewport(model: Model)
	for _, desc in ipairs(model:GetDescendants()) do
		if desc:IsA("BasePart") then
			desc.Anchored = true
			desc.CanCollide = false
			desc.CanTouch = false
			desc.CanQuery = false
			desc.CastShadow = false
		elseif desc:IsA("Script") or desc:IsA("LocalScript") then
			desc:Destroy()
		end
	end
end

function ViewportOrbit.BuildFallback3DWeapon(itemId: string, accentColor: Color3?): Model
	local m = Instance.new("Model")
	m.Name = "Weapon3DFallback_" .. tostring(itemId)
	local col = accentColor or Theme.Colors.ACCENT_GOLD

	local blade = Instance.new("Part")
	blade.Name = "Blade"
	blade.Size = Vector3.new(0.24, 4.4, 0.72)
	blade.Color = col
	blade.Material = Enum.Material.Neon
	blade.Anchored = true
	blade.CanCollide = false
	blade.CFrame = CFrame.new(0, 0.7, 0)
	blade.Parent = m

	local core = Instance.new("Part")
	core.Name = "BladeSpine"
	core.Size = Vector3.new(0.30, 3.8, 0.32)
	core.Color = Color3.fromRGB(28, 34, 52)
	core.Material = Enum.Material.Metal
	core.Anchored = true
	core.CanCollide = false
	core.CFrame = CFrame.new(0, 0.5, 0)
	core.Parent = m

	local guard = Instance.new("Part")
	guard.Name = "Crossguard"
	guard.Size = Vector3.new(0.42, 0.36, 1.85)
	guard.Color = Theme.Colors.ACCENT_GOLD_BRIGHT
	guard.Material = Enum.Material.Metal
	guard.Anchored = true
	guard.CanCollide = false
	guard.CFrame = CFrame.new(0, -1.5, 0)
	guard.Parent = m

	local grip = Instance.new("Part")
	grip.Name = "Grip"
	grip.Size = Vector3.new(0.28, 1.15, 0.30)
	grip.Color = Color3.fromRGB(38, 28, 46)
	grip.Material = Enum.Material.SmoothPlastic
	grip.Anchored = true
	grip.CanCollide = false
	grip.CFrame = CFrame.new(0, -2.25, 0)
	grip.Parent = m

	m.PrimaryPart = blade
	return m
end

function ViewportOrbit.BuildFallback3DFruit(fruitId: string, accentColor: Color3?): Model
	local m = Instance.new("Model")
	m.Name = "Fruit3DFallback_" .. tostring(fruitId)
	local col = accentColor or Theme.Colors.VOID_PURPLE

	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(2.2, 2.2, 2.2)
	body.Color = col
	body.Material = Enum.Material.Neon
	body.Anchored = true
	body.CanCollide = false
	body.CFrame = CFrame.new(0, 0, 0)
	body.Parent = m

	local shell = Instance.new("Part")
	shell.Name = "SwirlShell"
	shell.Shape = Enum.PartType.Ball
	shell.Size = Vector3.new(2.45, 2.0, 2.45)
	shell.Color = col:Lerp(Color3.new(1, 1, 1), 0.32)
	shell.Transparency = 0.35
	shell.Material = Enum.Material.ForceField
	shell.Anchored = true
	shell.CanCollide = false
	shell.CFrame = CFrame.new(0, 0, 0)
	shell.Parent = m

	local ring = Instance.new("Part")
	ring.Name = "AuraRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.12, 3.4, 3.4)
	ring.Color = col:Lerp(Theme.Colors.ACCENT_GOLD_BRIGHT, 0.35)
	ring.Material = Enum.Material.Neon
	ring.Transparency = 0.25
	ring.Anchored = true
	ring.CanCollide = false
	ring.CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(72))
	ring.Parent = m

	local stem = Instance.new("Part")
	stem.Name = "CrownStem"
	stem.Size = Vector3.new(0.24, 0.75, 0.24)
	stem.Color = Theme.Colors.ACCENT_GOLD_BRIGHT
	stem.Material = Enum.Material.Metal
	stem.Anchored = true
	stem.CanCollide = false
	stem.CFrame = CFrame.new(0, 1.25, 0) * CFrame.Angles(0, 0, math.rad(16))
	stem.Parent = m

	m.PrimaryPart = body
	return m
end

local function addViewportPart(
	parent: Model,
	name: string,
	size: Vector3,
	cf: CFrame,
	color: Color3,
	mat: Enum.Material,
	shape: Enum.PartType?,
	className: string?,
	transparency: number?,
	reflectance: number?
): BasePart
	local inst = Instance.new(className or "Part") :: BasePart
	inst.Name = name
	inst.Size = size
	inst.CFrame = cf
	inst.Color = color
	inst.Material = mat
	inst.Transparency = transparency or 0
	inst.Reflectance = reflectance or 0
	inst.Anchored = true
	inst.CanCollide = false
	inst.CanTouch = false
	inst.CanQuery = false
	inst.CastShadow = false
	if inst:IsA("Part") and shape then
		inst.Shape = shape
	end
	inst.Parent = parent
	return inst
end

function ViewportOrbit.BuildBespoke3DArsenalModel(idOrAsset: string, accentColor: Color3?): Model?
	local key = tostring(idOrAsset or "")
	if key == "" then
		return nil
	end

	local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
	local expMod = sharedFolder and sharedFolder:FindFirstChild("SkybreakExpansion3DAndVFX")
	if expMod and expMod:IsA("ModuleScript") then
		local okExp, Expansion3D: any = pcall(require, expMod)
		if okExp and type(Expansion3D) == "table" then
			local cleanId = string.lower(key):gsub("^expsword_", ""):gsub("^expgun_", "")
			if (Expansion3D.IsExpansionSword and Expansion3D.IsExpansionSword(cleanId))
				or (Expansion3D.IsExpansionGun and Expansion3D.IsExpansionGun(cleanId))
			then
				local entry = Expansion3D.BuildExpansionWeaponModel(cleanId, cleanId, false, true)
				if entry and entry.Model then
					return entry.Model
				end
			end
		end
	end

	local itemDef: any = RarityConfig.Items and RarityConfig.Items[key] or nil
	local kind: string? = nil
	local resolvedAccent: Color3? = accentColor

	if not resolvedAccent and itemDef then
		resolvedAccent = parseHexColor(itemDef.AccentHex)
		if not resolvedAccent and itemDef.Rarity then
			local rar = RarityConfig.GetRarity(itemDef.Rarity)
			resolvedAccent = rar and rar.Color or nil
		end
	end

	if DIRECT_BESPOKE_KINDS[key] then
		kind = key
	elseif string.sub(key, 1, 5) == "Ship_" or SHIP_IDS[key] then
		kind = "Ship"
		if not resolvedAccent then
			if string.find(key, "Leviathan") then
				resolvedAccent = Color3.fromRGB(168, 85, 247)
			elseif string.find(key, "Galleon") or string.find(key, "Celestial") then
				resolvedAccent = Color3.fromRGB(244, 193, 78)
			elseif string.find(key, "Cyber") then
				resolvedAccent = Color3.fromRGB(56, 189, 248)
			else
				resolvedAccent = Color3.fromRGB(147, 197, 253)
			end
		end
	elseif string.sub(key, 1, 8) == "Martial_" or MARTIAL_IDS[key] then
		kind = "Martial"
		if not resolvedAccent then
			local low = string.lower(key)
			if string.find(low, "chrono") or string.find(low, "abyss") then
				resolvedAccent = Color3.fromRGB(192, 132, 252)
			elseif string.find(low, "jade") then
				resolvedAccent = Color3.fromRGB(52, 211, 153)
			elseif string.find(low, "thunder") or string.find(low, "electric") or string.find(low, "glacial") then
				resolvedAccent = Color3.fromRGB(56, 189, 248)
			elseif string.find(low, "ashura") or string.find(low, "step") then
				resolvedAccent = Color3.fromRGB(249, 115, 22)
			else
				resolvedAccent = Color3.fromRGB(244, 193, 78)
			end
		end
	elseif itemDef then
		if type(itemDef.Model3DKind) == "string" and itemDef.Model3DKind ~= "" then
			kind = itemDef.Model3DKind
		elseif itemDef.Slot == "Helm" or itemDef.Slot == "Helmet" then
			kind = "Helm"
		elseif itemDef.Slot == "Chest" then
			kind = "Chest"
		elseif itemDef.Slot == "Gauntlets" or itemDef.Slot == "Gloves" then
			kind = "Gauntlets"
		elseif itemDef.Slot == "Greaves" or itemDef.Slot == "Boots" then
			kind = "Greaves"
		elseif itemDef.Slot == "Ring" then
			kind = "Ring"
		elseif itemDef.Slot == "Artifact" or itemDef.Slot == "Offhand" then
			if itemDef.WeaponType == "Gun" or itemDef.Icon == "Gun" then
				kind = "railcannon"
			else
				kind = "Artifact"
			end
		elseif itemDef.Category == "Materials" or itemDef.Category == "Quest" then
			kind = "Materials"
		elseif itemDef.Slot == "Weapon" then
			kind = "greatsaber"
		end
	end

	if not kind then
		return nil
	end

	local col = resolvedAccent or Theme.Colors.ACCENT_GOLD
	local bright = col:Lerp(Color3.new(1, 1, 1), 0.35)
	local darkMetal = Color3.fromRGB(28, 36, 56)
	local steelMetal = Color3.fromRGB(64, 78, 108)
	local goldTrim = Theme.Colors.ACCENT_GOLD_BRIGHT

	local m = Instance.new("Model")
	m.Name = "Bespoke3D_" .. key
	local primary: BasePart? = nil

	if kind == "halberd" then
		primary = addViewportPart(m, "PoleShaft", Vector3.new(0.20, 5.8, 0.20), CFrame.new(0, 0, 0), darkMetal, Enum.Material.Metal, Enum.PartType.Block, "Part", 0, 0.25)
		addViewportPart(m, "GoldCollar", Vector3.new(0.32, 0.45, 0.32), CFrame.new(0, 1.55, 0), goldTrim, Enum.Material.Metal, Enum.PartType.Block, "Part", 0, 0.35)
		addViewportPart(m, "SpearTip", Vector3.new(0.18, 1.45, 0.36), CFrame.new(0, 2.85, 0), col, Enum.Material.Neon, nil, "WedgePart")
		addViewportPart(m, "AxeUpper", Vector3.new(0.16, 1.35, 1.15), CFrame.new(0, 1.95, 0.62), col, Enum.Material.Neon, nil, "WedgePart")
		addViewportPart(m, "AxeLower", Vector3.new(0.16, 1.10, 1.05), CFrame.new(0, 1.15, 0.56) * CFrame.Angles(math.pi, 0, 0), col, Enum.Material.Neon, nil, "WedgePart")
		addViewportPart(m, "BackSpike", Vector3.new(0.16, 0.55, 0.68), CFrame.new(0, 1.65, -0.42) * CFrame.Angles(0, math.pi, 0), goldTrim, Enum.Material.Metal, nil, "WedgePart", 0, 0.3)
		addViewportPart(m, "PommelGem", Vector3.new(0.34, 0.34, 0.34), CFrame.new(0, -2.95, 0), bright, Enum.Material.Neon, Enum.PartType.Ball)
	elseif kind == "katana" then
		primary = addViewportPart(m, "KatanaSpine", Vector3.new(0.14, 4.35, 0.24), CFrame.new(0, 0.85, -0.04) * CFrame.Angles(math.rad(-4), 0, 0), darkMetal, Enum.Material.Metal, Enum.PartType.Block, "Part", 0, 0.35)
		addViewportPart(m, "PlasmaEdge", Vector3.new(0.08, 4.42, 0.14), CFrame.new(0, 0.88, 0.10) * CFrame.Angles(math.rad(-4), 0, 0), col, Enum.Material.Neon)
		addViewportPart(m, "KatanaTip", Vector3.new(0.10, 0.65, 0.28), CFrame.new(0, 3.22, -0.10) * CFrame.Angles(math.rad(-4), 0, 0), bright, Enum.Material.Neon, nil, "WedgePart")
		addViewportPart(m, "TsubaGuard", Vector3.new(0.14, 0.72, 0.72), CFrame.new(0, -1.35, 0.08) * CFrame.Angles(0, 0, math.pi * 0.5), goldTrim, Enum.Material.Metal, Enum.PartType.Cylinder, "Part", 0, 0.3)
		addViewportPart(m, "TsukaGrip", Vector3.new(0.18, 1.35, 0.24), CFrame.new(0, -2.08, 0.12) * CFrame.Angles(math.rad(3), 0, 0), steelMetal, Enum.Material.SmoothPlastic)
		addViewportPart(m, "PommelRing", Vector3.new(0.24, 0.18, 0.30), CFrame.new(0, -2.80, 0.16), col, Enum.Material.Neon)
	elseif kind == "greatsaber" then
		primary = addViewportPart(m, "SaberCore", Vector3.new(0.24, 4.4, 0.54), CFrame.new(0, 0.8, 0), darkMetal, Enum.Material.Metal, Enum.PartType.Block, "Part", 0, 0.28)
		addViewportPart(m, "SaberEdgeFront", Vector3.new(0.14, 4.35, 0.26), CFrame.new(0, 0.8, 0.34), col, Enum.Material.Neon)
		addViewportPart(m, "SaberTip", Vector3.new(0.18, 0.95, 0.72), CFrame.new(0, 3.42, 0.08), bright, Enum.Material.Neon, nil, "WedgePart")
		addViewportPart(m, "SaberFuller", Vector3.new(0.28, 3.1, 0.14), CFrame.new(0, 0.45, 0), bright, Enum.Material.Neon)
		addViewportPart(m, "WingGuardL", Vector3.new(0.32, 0.36, 1.15), CFrame.new(0, -1.42, 0.52) * CFrame.Angles(math.rad(18), 0, 0), goldTrim, Enum.Material.Metal, Enum.PartType.Block, "Part", 0, 0.3)
		addViewportPart(m, "WingGuardR", Vector3.new(0.32, 0.36, 1.15), CFrame.new(0, -1.42, -0.52) * CFrame.Angles(math.rad(-18), 0, 0), goldTrim, Enum.Material.Metal, Enum.PartType.Block, "Part", 0, 0.3)
		addViewportPart(m, "Grip", Vector3.new(0.24, 1.25, 0.28), CFrame.new(0, -2.18, 0), darkMetal, Enum.Material.SmoothPlastic)
		addViewportPart(m, "Pommel", Vector3.new(0.38, 0.38, 0.38), CFrame.new(0, -2.92, 0), col, Enum.Material.Neon, Enum.PartType.Ball)
	elseif kind == "warhammer" then
		primary = addViewportPart(m, "HammerHaft", Vector3.new(0.26, 4.9, 0.26), CFrame.new(0, -0.25, 0), darkMetal, Enum.Material.Metal, Enum.PartType.Block, "Part", 0, 0.25)
		addViewportPart(m, "HammerHead", Vector3.new(1.35, 1.45, 2.35), CFrame.new(0, 1.85, 0), darkMetal, Enum.Material.Metal, Enum.PartType.Block, "Part", 0, 0.22)
		addViewportPart(m, "MagmaFaceF", Vector3.new(1.12, 1.18, 0.26), CFrame.new(0, 1.85, 1.18), col, Enum.Material.Neon)
		addViewportPart(m, "MagmaFaceB", Vector3.new(1.12, 1.18, 0.26), CFrame.new(0, 1.85, -1.18), col, Enum.Material.Neon)
		addViewportPart(m, "CoreVent", Vector3.new(1.42, 0.36, 1.45), CFrame.new(0, 1.85, 0), bright, Enum.Material.Neon)
		addViewportPart(m, "TopSpike", Vector3.new(0.28, 0.82, 0.36), CFrame.new(0, 2.95, 0), goldTrim, Enum.Material.Metal, nil, "WedgePart", 0, 0.3)
		addViewportPart(m, "PommelCap", Vector3.new(0.42, 0.35, 0.42), CFrame.new(0, -2.75, 0), goldTrim, Enum.Material.Metal)
	elseif kind == "trident" then
		primary = addViewportPart(m, "TridentShaft", Vector3.new(0.20, 5.4, 0.20), CFrame.new(0, -0.2, 0), steelMetal, Enum.Material.Metal, Enum.PartType.Block, "Part", 0, 0.3)
		addViewportPart(m, "CrossCrown", Vector3.new(0.26, 0.32, 1.85), CFrame.new(0, 1.65, 0), goldTrim, Enum.Material.Metal, Enum.PartType.Block, "Part", 0, 0.35)
		addViewportPart(m, "PearlCore", Vector3.new(0.46, 0.46, 0.46), CFrame.new(0, 1.68, 0), bright, Enum.Material.Neon, Enum.PartType.Ball)
		addViewportPart(m, "CenterProng", Vector3.new(0.16, 1.85, 0.28), CFrame.new(0, 2.72, 0), col, Enum.Material.Neon, nil, "WedgePart")
		addViewportPart(m, "OuterProngL", Vector3.new(0.14, 1.45, 0.24), CFrame.new(0, 2.42, 0.76) * CFrame.Angles(math.rad(-8), 0, 0), col, Enum.Material.Neon, nil, "WedgePart")
		addViewportPart(m, "OuterProngR", Vector3.new(0.14, 1.45, 0.24), CFrame.new(0, 2.42, -0.76) * CFrame.Angles(math.rad(8), math.pi, 0), col, Enum.Material.Neon, nil, "WedgePart")
	elseif kind == "scythe" then
		primary = addViewportPart(m, "ScytheShaft", Vector3.new(0.20, 5.5, 0.20), CFrame.new(0, -0.15, -0.35) * CFrame.Angles(math.rad(-6), 0, 0), darkMetal, Enum.Material.Metal, Enum.PartType.Block, "Part", 0, 0.28)
		addViewportPart(m, "ChronoDial", Vector3.new(0.18, 1.05, 1.05), CFrame.new(0, 2.25, -0.52) * CFrame.Angles(0, math.pi * 0.5, 0), goldTrim, Enum.Material.Neon, Enum.PartType.Cylinder)
		addViewportPart(m, "ReaperBlade1", Vector3.new(0.14, 0.58, 1.65), CFrame.new(0, 2.32, 0.35) * CFrame.Angles(math.rad(14), 0, 0), col, Enum.Material.Neon, nil, "WedgePart")
		addViewportPart(m, "ReaperBlade2", Vector3.new(0.12, 0.48, 1.55), CFrame.new(0, 1.88, 1.62) * CFrame.Angles(math.rad(42), 0, 0), bright, Enum.Material.Neon, nil, "WedgePart")
		addViewportPart(m, "BladeSpine", Vector3.new(0.18, 0.22, 2.35), CFrame.new(0, 2.35, 0.72) * CFrame.Angles(math.rad(22), 0, 0), darkMetal, Enum.Material.Metal)
		addViewportPart(m, "TailSpike", Vector3.new(0.16, 0.75, 0.24), CFrame.new(0, -2.95, -0.05) * CFrame.Angles(math.pi, 0, 0), col, Enum.Material.Neon, nil, "WedgePart")
	elseif kind == "bow" then
		primary = addViewportPart(m, "BowRiser", Vector3.new(0.24, 1.15, 0.32), CFrame.new(0, 0, 0.45), goldTrim, Enum.Material.Metal, Enum.PartType.Block, "Part", 0, 0.3)
		addViewportPart(m, "UpperLimb", Vector3.new(0.18, 2.05, 0.26), CFrame.new(0, 1.42, 0.08) * CFrame.Angles(math.rad(24), 0, 0), col, Enum.Material.Neon)
		addViewportPart(m, "LowerLimb", Vector3.new(0.18, 2.05, 0.26), CFrame.new(0, -1.42, 0.08) * CFrame.Angles(math.rad(-24), 0, 0), col, Enum.Material.Neon)
		addViewportPart(m, "BowString", Vector3.new(0.05, 4.35, 0.05), CFrame.new(0, 0, -0.42), bright, Enum.Material.Neon)
		addViewportPart(m, "SpiritArrow", Vector3.new(0.09, 0.09, 2.65), CFrame.new(0, 0, 0.38), bright, Enum.Material.Neon)
		addViewportPart(m, "ArrowHead", Vector3.new(0.16, 0.45, 0.24), CFrame.new(0, 0, 1.82) * CFrame.Angles(math.pi * 0.5, 0, 0), col, Enum.Material.Neon, nil, "WedgePart")
	elseif kind == "cannon" then
		primary = addViewportPart(m, "CannonBarrel", Vector3.new(3.4, 1.25, 1.25), CFrame.new(0, 0.25, 0) * CFrame.Angles(0, math.pi * 0.5, 0), darkMetal, Enum.Material.Metal, Enum.PartType.Cylinder, "Part", 0, 0.25)
		addViewportPart(m, "MuzzleRing", Vector3.new(0.32, 1.48, 1.48), CFrame.new(0, 0.25, 1.58) * CFrame.Angles(0, math.pi * 0.5, 0), goldTrim, Enum.Material.Metal, Enum.PartType.Cylinder, "Part", 0, 0.35)
		addViewportPart(m, "MoltenBore", Vector3.new(0.24, 0.92, 0.92), CFrame.new(0, 0.25, 1.66) * CFrame.Angles(0, math.pi * 0.5, 0), col, Enum.Material.Neon, Enum.PartType.Cylinder)
		addViewportPart(m, "BreechCore", Vector3.new(1.05, 1.05, 1.05), CFrame.new(0, 0.25, -1.75), bright, Enum.Material.Neon, Enum.PartType.Ball)
		addViewportPart(m, "CannonGrip", Vector3.new(0.36, 1.05, 0.48), CFrame.new(0, -0.75, -0.65) * CFrame.Angles(math.rad(-20), 0, 0), steelMetal, Enum.Material.Metal)
	elseif kind == "dualpistols" then
		primary = addViewportPart(m, "CenterAnchor", Vector3.new(0.2, 0.2, 0.2), CFrame.new(0, 0, 0), col, Enum.Material.SmoothPlastic, Enum.PartType.Ball, "Part", 1, 0)
		for _, side in ipairs({ -1, 1 }) do
			local baseCF = CFrame.new(side * 0.85, 0.15, 0) * CFrame.Angles(math.rad(-12), math.rad(-side * 16), math.rad(side * 10))
			addViewportPart(m, "Receiver_" .. side, Vector3.new(0.32, 0.48, 1.85), baseCF, darkMetal, Enum.Material.Metal, Enum.PartType.Block, "Part", 0, 0.28)
			addViewportPart(m, "NeonRail_" .. side, Vector3.new(0.18, 0.18, 1.92), baseCF * CFrame.new(0, 0.24, 0.05), col, Enum.Material.Neon)
			addViewportPart(m, "ChronoRing_" .. side, Vector3.new(0.10, 0.72, 0.72), baseCF * CFrame.new(0, 0.08, -0.15) * CFrame.Angles(0, math.pi * 0.5, 0), goldTrim, Enum.Material.Neon, Enum.PartType.Cylinder)
			addViewportPart(m, "PistolGrip_" .. side, Vector3.new(0.26, 0.95, 0.36), baseCF * CFrame.new(0, -0.58, -0.58) * CFrame.Angles(math.rad(-22), 0, 0), steelMetal, Enum.Material.SmoothPlastic)
		end
	elseif kind == "railcannon" then
		primary = addViewportPart(m, "RailChassis", Vector3.new(0.68, 0.72, 3.65), CFrame.new(0, 0.15, -0.2), darkMetal, Enum.Material.Metal, Enum.PartType.Block, "Part", 0, 0.3)
		addViewportPart(m, "UpperRail", Vector3.new(0.36, 0.22, 4.35), CFrame.new(0, 0.62, 0.25), steelMetal, Enum.Material.Metal, Enum.PartType.Block, "Part", 0, 0.35)
		addViewportPart(m, "LowerRail", Vector3.new(0.36, 0.22, 4.15), CFrame.new(0, -0.32, 0.15), steelMetal, Enum.Material.Metal, Enum.PartType.Block, "Part", 0, 0.35)
		addViewportPart(m, "SingularityCore", Vector3.new(0.28, 0.34, 4.20), CFrame.new(0, 0.16, 0.28), col, Enum.Material.Neon)
		addViewportPart(m, "HoloScope", Vector3.new(0.85, 0.34, 0.34), CFrame.new(0, 0.92, -0.45) * CFrame.Angles(0, math.pi * 0.5, 0), bright, Enum.Material.Neon, Enum.PartType.Cylinder)
		addViewportPart(m, "StockGrip", Vector3.new(0.32, 1.05, 0.44), CFrame.new(0, -0.68, -1.15) * CFrame.Angles(math.rad(-22), 0, 0), darkMetal, Enum.Material.SmoothPlastic)
	elseif kind == "Helm" then
		primary = addViewportPart(m, "HelmDome", Vector3.new(1.85, 1.65, 1.95), CFrame.new(0, 0.15, 0), darkMetal, Enum.Material.Metal, Enum.PartType.Block, "Part", 0, 0.28)
		addViewportPart(m, "VisorGlow", Vector3.new(1.52, 0.36, 0.25), CFrame.new(0, 0.12, 0.92), col, Enum.Material.Neon)
		addViewportPart(m, "CrownBand", Vector3.new(0.24, 2.08, 2.08), CFrame.new(0, 0.78, 0) * CFrame.Angles(0, 0, math.pi * 0.5), goldTrim, Enum.Material.Metal, Enum.PartType.Cylinder, "Part", 0, 0.35)
		for i = -2, 2 do
			local h = (i == 0) and 0.95 or (math.abs(i) == 1 and 0.68 or 0.48)
			local ang = i * 0.42
			addViewportPart(
				m,
				"CrownSpire_" .. i,
				Vector3.new(0.16, h, 0.26),
				CFrame.new(math.sin(ang) * 0.94, 1.05 + h * 0.4, math.cos(ang) * 0.94) * CFrame.Angles(0, ang, 0),
				i == 0 and col or goldTrim,
				i == 0 and Enum.Material.Neon or Enum.Material.Metal,
				nil,
				"WedgePart"
			)
		end
	elseif kind == "Chest" then
		primary = addViewportPart(m, "CuirassBody", Vector3.new(2.15, 2.35, 1.18), CFrame.new(0, 0.15, 0), darkMetal, Enum.Material.Metal, Enum.PartType.Block, "Part", 0, 0.28)
		addViewportPart(m, "ChestCore", Vector3.new(0.28, 0.72, 0.72), CFrame.new(0, 0.42, 0.52) * CFrame.Angles(0, math.pi * 0.5, 0), col, Enum.Material.Neon, Enum.PartType.Cylinder)
		addViewportPart(m, "WaistBelt", Vector3.new(2.24, 0.28, 1.24), CFrame.new(0, -0.82, 0), goldTrim, Enum.Material.Metal, Enum.PartType.Block, "Part", 0, 0.35)
		addViewportPart(m, "RoyalCape", Vector3.new(2.45, 2.85, 0.16), CFrame.new(0, -0.15, -0.68) * CFrame.Angles(math.rad(-8), 0, 0), col:Lerp(darkMetal, 0.45), Enum.Material.SmoothPlastic)
		for _, side in ipairs({ -1, 1 }) do
			addViewportPart(m, "Pauldron_" .. side, Vector3.new(0.95, 0.58, 1.28), CFrame.new(side * 1.42, 1.08, 0) * CFrame.Angles(0, 0, math.rad(-side * 18)), steelMetal, Enum.Material.Metal, Enum.PartType.Block, "Part", 0, 0.3)
			addViewportPart(m, "PauldronWing_" .. side, Vector3.new(0.22, 0.62, 1.05), CFrame.new(side * 1.68, 1.38, -0.05) * CFrame.Angles(0, 0, math.rad(-side * 24)), col, Enum.Material.Neon, nil, "WedgePart")
		end
	elseif kind == "Gauntlets" then
		primary = addViewportPart(m, "GauntletAnchor", Vector3.new(0.2, 0.2, 0.2), CFrame.new(0, 0, 0), col, Enum.Material.SmoothPlastic, Enum.PartType.Ball, "Part", 1, 0)
		for _, side in ipairs({ -1, 1 }) do
			local cf = CFrame.new(side * 0.92, 0, 0) * CFrame.Angles(math.rad(16), math.rad(-side * 12), math.rad(-side * 10))
			addViewportPart(m, "Forearm_" .. side, Vector3.new(0.82, 1.85, 0.86), cf, darkMetal, Enum.Material.Metal, Enum.PartType.Block, "Part", 0, 0.28)
			addViewportPart(m, "GoldCuff_" .. side, Vector3.new(0.90, 0.26, 0.92), cf * CFrame.new(0, -0.72, 0), goldTrim, Enum.Material.Metal, Enum.PartType.Block, "Part", 0, 0.35)
			addViewportPart(m, "EnergyFin_" .. side, Vector3.new(0.18, 1.42, 0.46), cf * CFrame.new(side * 0.48, 0.12, -0.08), col, Enum.Material.Neon, nil, "WedgePart")
		end
	elseif kind == "Greaves" then
		primary = addViewportPart(m, "GreavesAnchor", Vector3.new(0.2, 0.2, 0.2), CFrame.new(0, 0, 0), col, Enum.Material.SmoothPlastic, Enum.PartType.Ball, "Part", 1, 0)
		for _, side in ipairs({ -1, 1 }) do
			local cf = CFrame.new(side * 0.88, 0.15, 0) * CFrame.Angles(0, math.rad(-side * 10), 0)
			addViewportPart(m, "ShinGuard_" .. side, Vector3.new(0.78, 1.95, 0.84), cf, darkMetal, Enum.Material.Metal, Enum.PartType.Block, "Part", 0, 0.28)
			addViewportPart(m, "Sabaton_" .. side, Vector3.new(0.82, 0.56, 1.38), cf * CFrame.new(0, -0.82, 0.28), steelMetal, Enum.Material.Metal, Enum.PartType.Block, "Part", 0, 0.3)
			addViewportPart(m, "AnkleWing_" .. side, Vector3.new(0.16, 1.05, 0.68), cf * CFrame.new(side * 0.48, 0.18, -0.18) * CFrame.Angles(math.rad(-20), 0, 0), col, Enum.Material.Neon, nil, "WedgePart")
		end
	elseif kind == "Ring" then
		primary = addViewportPart(m, "SignetBand", Vector3.new(0.58, 2.35, 2.35), CFrame.new(0, -0.15, 0) * CFrame.Angles(0, math.pi * 0.5, 0), goldTrim, Enum.Material.Metal, Enum.PartType.Cylinder, "Part", 0, 0.42)
		addViewportPart(m, "RingInner", Vector3.new(0.64, 1.68, 1.68), CFrame.new(0, -0.15, 0) * CFrame.Angles(0, math.pi * 0.5, 0), Color3.fromRGB(14, 20, 34), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
		addViewportPart(m, "CrownBezel", Vector3.new(0.76, 0.42, 0.76), CFrame.new(0, 1.05, 0), goldTrim, Enum.Material.Metal, Enum.PartType.Block, "Part", 0, 0.35)
		addViewportPart(m, "SignetGem", Vector3.new(0.68, 0.68, 0.68), CFrame.new(0, 1.38, 0) * CFrame.Angles(math.rad(45), math.rad(45), 0), col, Enum.Material.Neon)
	elseif kind == "Artifact" or kind == "Materials" then
		local low = string.lower(key)
		if string.find(low, "gear") then
			primary = addViewportPart(m, "GearHub", Vector3.new(0.46, 2.15, 2.15), CFrame.new(0, 0, 0) * CFrame.Angles(0, math.pi * 0.5, 0), steelMetal, Enum.Material.Metal, Enum.PartType.Cylinder, "Part", 0, 0.32)
			addViewportPart(m, "GearCore", Vector3.new(0.54, 1.15, 1.15), CFrame.new(0, 0, 0) * CFrame.Angles(0, math.pi * 0.5, 0), col, Enum.Material.Neon, Enum.PartType.Cylinder)
			for i = 1, 8 do
				local ang = (i - 1) * (math.pi * 0.25)
				addViewportPart(m, "GearTooth_" .. i, Vector3.new(0.42, 0.42, 0.44), CFrame.new(math.cos(ang) * 1.18, math.sin(ang) * 1.18, 0) * CFrame.Angles(0, 0, ang), goldTrim, Enum.Material.Metal, Enum.PartType.Block, "Part", 0, 0.35)
			end
		elseif string.find(low, "microchip") then
			primary = addViewportPart(m, "SiliconBoard", Vector3.new(2.15, 2.15, 0.26), CFrame.new(0, 0, 0), darkMetal, Enum.Material.Metal, Enum.PartType.Block, "Part", 0, 0.25)
			addViewportPart(m, "QuantumDie", Vector3.new(1.18, 1.18, 0.36), CFrame.new(0, 0, 0.06), col, Enum.Material.Neon)
			for i = -2, 2 do
				addViewportPart(m, "PinH_" .. i, Vector3.new(2.55, 0.14, 0.14), CFrame.new(0, i * 0.38, 0), goldTrim, Enum.Material.Metal)
				addViewportPart(m, "PinV_" .. i, Vector3.new(0.14, 2.55, 0.14), CFrame.new(i * 0.38, 0, 0), goldTrim, Enum.Material.Metal)
			end
		elseif string.find(low, "scroll") then
			primary = addViewportPart(m, "ScrollBody", Vector3.new(2.35, 0.96, 0.96), CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(28)), Color3.fromRGB(238, 226, 196), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
			addViewportPart(m, "ScrollCapA", Vector3.new(0.28, 1.22, 1.22), CFrame.new(-1.05, -0.56, 0) * CFrame.Angles(0, 0, math.rad(28)), goldTrim, Enum.Material.Metal, Enum.PartType.Cylinder, "Part", 0, 0.35)
			addViewportPart(m, "ScrollCapB", Vector3.new(0.28, 1.22, 1.22), CFrame.new(1.05, 0.56, 0) * CFrame.Angles(0, 0, math.rad(28)), goldTrim, Enum.Material.Metal, Enum.PartType.Cylinder, "Part", 0, 0.35)
			addViewportPart(m, "RuneSeal", Vector3.new(0.14, 1.85, 1.85), CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(65), 0, 0), col, Enum.Material.Neon, Enum.PartType.Cylinder, "Part", 0.18, 0)
		else
			primary = addViewportPart(m, "RuneCrystal", Vector3.new(1.15, 2.45, 1.15), CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(45), 0), col, Enum.Material.Neon)
			addViewportPart(m, "OrbitRingA", Vector3.new(0.12, 2.95, 2.95), CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(35), 0, math.rad(25)), goldTrim, Enum.Material.Metal, Enum.PartType.Cylinder, "Part", 0, 0.35)
			addViewportPart(m, "OrbitRingB", Vector3.new(0.10, 2.65, 2.65), CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-42), math.rad(30), 0), bright, Enum.Material.Neon, Enum.PartType.Cylinder, "Part", 0.18, 0)
		end
	elseif kind == "Ship" then
		primary = addViewportPart(m, "ShipHull", Vector3.new(1.85, 0.95, 4.45), CFrame.new(0, -0.55, 0), darkMetal, Enum.Material.Metal, Enum.PartType.Block, "Part", 0, 0.22)
		addViewportPart(m, "ShipBow", Vector3.new(1.65, 0.88, 1.35), CFrame.new(0, -0.45, 2.75) * CFrame.Angles(0, math.pi, 0), goldTrim, Enum.Material.Metal, nil, "WedgePart", 0, 0.32)
		addViewportPart(m, "DeckTrim", Vector3.new(1.98, 0.18, 4.55), CFrame.new(0, -0.02, 0), goldTrim, Enum.Material.Metal)
		addViewportPart(m, "MainMast", Vector3.new(0.22, 3.35, 0.22), CFrame.new(0, 1.45, 0.15), steelMetal, Enum.Material.Metal)
		addViewportPart(m, "GlowingSail", Vector3.new(2.55, 1.95, 0.14), CFrame.new(0, 1.65, 0.28) * CFrame.Angles(math.rad(-8), 0, 0), col, Enum.Material.Neon, Enum.PartType.Block, "Part", 0.12, 0)
		addViewportPart(m, "HarpoonLauncher", Vector3.new(0.18, 0.18, 1.45), CFrame.new(0, 0.18, 2.95), bright, Enum.Material.Neon)
		for _, side in ipairs({ -1, 1 }) do
			for cIdx = -1, 1 do
				addViewportPart(m, "Broadside_" .. side .. "_" .. cIdx, Vector3.new(0.62, 0.24, 0.24), CFrame.new(side * 1.08, -0.25, cIdx * 1.15), steelMetal, Enum.Material.Metal, Enum.PartType.Cylinder)
			end
		end
	elseif kind == "Martial" then
		primary = addViewportPart(m, "MartialCore", Vector3.new(0.2, 0.2, 0.2), CFrame.new(0, 0, 0), col, Enum.Material.SmoothPlastic, Enum.PartType.Ball, "Part", 1, 0)
		addViewportPart(m, "AuraRingOuter", Vector3.new(0.12, 3.45, 3.45), CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(68), 0, math.rad(18)), col, Enum.Material.Neon, Enum.PartType.Cylinder, "Part", 0.18, 0)
		addViewportPart(m, "AuraRingInner", Vector3.new(0.10, 2.75, 2.75), CFrame.new(0, 0, 0) * CFrame.Angles(math.rad(-52), math.rad(24), 0), bright, Enum.Material.Neon, Enum.PartType.Cylinder, "Part", 0.22, 0)
		for _, side in ipairs({ -1, 1 }) do
			local cf = CFrame.new(side * 0.92, 0.05, 0.12) * CFrame.Angles(math.rad(24), math.rad(-side * 16), math.rad(-side * 12))
			addViewportPart(m, "AuraGauntlet_" .. side, Vector3.new(0.78, 1.55, 0.82), cf, darkMetal, Enum.Material.Metal, Enum.PartType.Block, "Part", 0, 0.3)
			addViewportPart(m, "DragonClaw_" .. side, Vector3.new(0.22, 0.95, 0.34), cf * CFrame.new(0, 0.95, 0.14), col, Enum.Material.Neon, nil, "WedgePart")
			addViewportPart(m, "KnuckleCrest_" .. side, Vector3.new(0.86, 0.32, 0.88), cf * CFrame.new(0, 0.45, 0), goldTrim, Enum.Material.Metal, Enum.PartType.Block, "Part", 0, 0.35)
		end
	end

	if not primary then
		m:Destroy()
		return nil
	end
	m.PrimaryPart = primary
	return m
end

function ViewportOrbit.CloneAssetModel(idOrAsset: string, accentColor: Color3?): (Model?, string)
	local resolved = ViewportOrbit.ResolveAssetName(idOrAsset)
	local renderer = ViewportOrbit.GetRenderer()
	if renderer and resolved and resolved ~= "" and resolved ~= "MythicalWeaponsSet" then
		if type(renderer.Models) == "table" and renderer.Models[resolved] then
			local okCached, cachedClone = pcall(function()
				return renderer.Models[resolved]:Clone()
			end)
			if okCached and cachedClone and cachedClone:IsA("Model") then
				ViewportOrbit.SanitizeModelForViewport(cachedClone)
				return cachedClone, resolved
			end
		end
		if type(renderer.CloneModel) == "function" then
			local ok, cloned = pcall(function()
				return renderer.CloneModel(resolved, 0)
			end)
			if ok and cloned and cloned:IsA("Model") then
				ViewportOrbit.SanitizeModelForViewport(cloned)
				return cloned, resolved
			end
		end
	end

	local bespoke = ViewportOrbit.BuildBespoke3DArsenalModel(idOrAsset, accentColor)
	if bespoke then
		return bespoke, tostring(idOrAsset)
	end

	local fallbackName = resolved or tostring(idOrAsset)
	if string.sub(fallbackName, 1, 6) == "Fruit_" or KNOWN_DEVIL_FRUITS[tostring(idOrAsset)] then
		return ViewportOrbit.BuildFallback3DFruit(tostring(idOrAsset), accentColor), fallbackName
	elseif string.sub(fallbackName, 1, 4) == "Wep_" then
		return ViewportOrbit.BuildFallback3DWeapon(tostring(idOrAsset), accentColor), fallbackName
	end
	return ViewportOrbit.BuildFallback3DWeapon(tostring(idOrAsset), accentColor), fallbackName
end

function ViewportOrbit.MountAssetAsync(orbitApi: any, idOrAsset: string, accentColor: Color3?, modelOpts: any?, onMounted: ((Model, string) -> ())?)
	if not orbitApi then
		return
	end
	local nextToken = (tonumber(orbitApi._mountToken) or 0) + 1
	orbitApi._mountToken = nextToken

	local resolved = ViewportOrbit.ResolveAssetName(idOrAsset)
	local renderer = ViewportOrbit.GetRenderer()
	if renderer and resolved and type(renderer.Models) == "table" and renderer.Models[resolved] then
		local okCached, cachedClone = pcall(function()
			return renderer.Models[resolved]:Clone()
		end)
		if okCached and cachedClone and cachedClone:IsA("Model") then
			ViewportOrbit.SanitizeModelForViewport(cachedClone)
			orbitApi:SetModel(cachedClone, modelOpts)
			if onMounted then
				onMounted(cachedClone, resolved)
			end
			return
		end
	end

	-- If no exact DelegatedV5Renderer mesh exists, mount Bespoke 3D Arsenal Model immediately in 0ms
	if not resolved then
		local bespoke = ViewportOrbit.BuildBespoke3DArsenalModel(idOrAsset, accentColor)
		if bespoke then
			orbitApi:SetModel(bespoke, modelOpts)
			if onMounted then
				onMounted(bespoke, tostring(idOrAsset))
			end
			return
		end
	end

	-- Mount lightweight instant silhouette first so UI frame never stalls while EditableMesh compiles
	local fbKey = resolved or tostring(idOrAsset)
	local isFruit = string.sub(fbKey, 1, 6) == "Fruit_" or KNOWN_DEVIL_FRUITS[tostring(idOrAsset)]
	local placeholder = isFruit and ViewportOrbit.BuildFallback3DFruit(tostring(idOrAsset), accentColor)
		or ViewportOrbit.BuildFallback3DWeapon(tostring(idOrAsset), accentColor)
	orbitApi:SetModel(placeholder, modelOpts)

	task.spawn(function()
		local built, resName = ViewportOrbit.CloneAssetModel(idOrAsset, accentColor)
		if built and not orbitApi._destroyed and orbitApi._mountToken == nextToken and orbitApi.Viewport and orbitApi.Viewport.Parent then
			orbitApi:SetModel(built, modelOpts)
			if onMounted then
				onMounted(built, resName)
			end
		elseif built then
			built:Destroy()
		end
	end)
end

export type OrbitOptions = {
	AutoSpinSpeed: number?,
	InitialYaw: number?,
	InitialPitch: number?,
	InitialZoom: number?,
	MinZoom: number?,
	MaxZoom: number?,
	ShowHint: boolean?,
	FieldOfView: number?,
	FitMultiplier: number?,
}

function ViewportOrbit.Attach(viewport: ViewportFrame, opts: OrbitOptions?)
	local cfg = opts or {}
	local autoSpinSpeed = if cfg.AutoSpinSpeed ~= nil then cfg.AutoSpinSpeed else 0.45
	local minPitch = math.rad(-45)
	local maxPitch = math.rad(55)
	local minZoom = cfg.MinZoom or 0.55
	local maxZoom = cfg.MaxZoom or 1.75

	viewport.Active = true
	viewport.Ambient = viewport.Ambient ~= Color3.new(0, 0, 0) and viewport.Ambient or Color3.fromRGB(168, 178, 210)
	viewport.LightColor = Color3.fromRGB(255, 244, 218)
	viewport.LightDirection = Vector3.new(-0.6, -0.8, -0.5)

	local camera = viewport.CurrentCamera
	if not camera then
		camera = Instance.new("Camera")
		camera.Name = "OrbitCamera"
		camera.Parent = viewport
		viewport.CurrentCamera = camera
	end
	camera.FieldOfView = cfg.FieldOfView or 36

	local worldModel = viewport:FindFirstChildOfClass("WorldModel")
	if not worldModel then
		worldModel = Instance.new("WorldModel")
		worldModel.Name = "OrbitWorld"
		worldModel.Parent = viewport
	end

	local hintLabel: TextLabel? = nil
	if cfg.ShowHint ~= false then
		local existing = viewport:FindFirstChild("OrbitHintCaption")
		if existing and existing:IsA("TextLabel") then
			hintLabel = existing
		else
			local lbl = Instance.new("TextLabel")
			lbl.Name = "OrbitHintCaption"
			lbl.AnchorPoint = Vector2.new(0.5, 1)
			lbl.Position = UDim2.new(0.5, 0, 1, -6)
			lbl.Size = UDim2.new(1, -16, 0, 18)
			lbl.BackgroundTransparency = 1
			lbl.Font = Theme.Fonts.Medium
			lbl.TextSize = 11
			lbl.TextColor3 = Theme.Colors.TEXT_MUTED
			lbl.TextStrokeTransparency = 0.65
			lbl.Text = I18n.T("orbit.hint")
			lbl.ZIndex = math.max(8, viewport.ZIndex + 4)
			lbl.Parent = viewport
			hintLabel = lbl
		end
	end

	local state = {
		yaw = cfg.InitialYaw or math.rad(22),
		pitch = math.clamp(cfg.InitialPitch or math.rad(12), minPitch, maxPitch),
		targetZoom = math.clamp(cfg.InitialZoom or 1.0, minZoom, maxZoom),
		currentZoom = math.clamp(cfg.InitialZoom or 1.0, minZoom, maxZoom),
		baseRadius = 6.5,
		focusPoint = Vector3.zero,
		dragging = false,
		lastPointer = Vector2.zero,
		idleResumeAt = 0,
		elapsed = 0,
		activeModel = nil :: Model?,
		customStep = nil :: ((number, number, Model?, WorldModel) -> ())?,
		connections = {} :: { RBXScriptConnection },
		unsubLang = nil :: (() -> ())?,
		destroyed = false,
	}

	if hintLabel then
		state.unsubLang = I18n.OnChanged(function()
			if hintLabel and hintLabel.Parent then
				hintLabel.Text = I18n.T("orbit.hint")
			end
		end)
	end

	local function updateCamera()
		if state.destroyed or not camera or not camera.Parent then
			return
		end
		local dist = math.max(1.2, state.baseRadius * state.currentZoom)
		local rot = CFrame.fromEulerAnglesYXZ(-state.pitch, state.yaw, 0)
		local camPos = state.focusPoint + (rot.LookVector * -dist)
		camera.CFrame = CFrame.lookAt(camPos, state.focusPoint)
	end

	table.insert(state.connections, viewport.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			state.dragging = true
			state.lastPointer = Vector2.new(input.Position.X, input.Position.Y)
			state.idleResumeAt = os.clock() + 1.25
		end
	end))

	table.insert(state.connections, viewport.InputChanged:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			local delta = -input.Position.Z * 0.14
			state.targetZoom = math.clamp(state.targetZoom + delta, minZoom, maxZoom)
			state.idleResumeAt = os.clock() + 0.8
		elseif state.dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local cur = Vector2.new(input.Position.X, input.Position.Y)
			local d = cur - state.lastPointer
			state.lastPointer = cur
			state.yaw = (state.yaw - d.X * 0.011) % (math.pi * 2)
			state.pitch = math.clamp(state.pitch + d.Y * 0.0085, minPitch, maxPitch)
			state.idleResumeAt = os.clock() + 1.25
		end
	end))

	table.insert(state.connections, UserInputService.InputChanged:Connect(function(input: InputObject)
		if not state.dragging then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			local cur = Vector2.new(input.Position.X, input.Position.Y)
			local d = cur - state.lastPointer
			if d.Magnitude > 0.01 then
				state.lastPointer = cur
				state.yaw = (state.yaw - d.X * 0.011) % (math.pi * 2)
				state.pitch = math.clamp(state.pitch + d.Y * 0.0085, minPitch, maxPitch)
				state.idleResumeAt = os.clock() + 1.25
			end
		end
	end))

	table.insert(state.connections, UserInputService.InputEnded:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			if state.dragging then
				state.dragging = false
				state.idleResumeAt = os.clock() + 1.1
			end
		end
	end))

	table.insert(state.connections, RunService.RenderStepped:Connect(function(dt: number)
		if state.destroyed then
			return
		end
		if not viewport:IsDescendantOf(game) then
			return
		end
		state.elapsed += dt
		if not state.dragging and os.clock() >= state.idleResumeAt and autoSpinSpeed ~= 0 then
			state.yaw = (state.yaw + dt * autoSpinSpeed) % (math.pi * 2)
		end
		state.currentZoom += (state.targetZoom - state.currentZoom) * math.min(1, dt * 12)
		if state.customStep then
			state.customStep(dt, state.elapsed, state.activeModel, worldModel)
		end
		updateCamera()
	end))

	local api = {}
	api.Viewport = viewport
	api.WorldModel = worldModel
	api.Camera = camera
	api._mountToken = 0
	api._destroyed = false

	function api:ClearModel()
		state.activeModel = nil
		for _, child in ipairs(worldModel:GetChildren()) do
			child:Destroy()
		end
	end

	function api:SetModel(model: Model?, modelOpts: {
		FitMultiplier: number?,
		FocusOffset: Vector3?,
		ResetAngles: boolean?,
		InitialYaw: number?,
		InitialPitch: number?,
		UprightWeapon: boolean?,
	}?)
		self:ClearModel()
		if not model then
			return
		end
		local mOpts = modelOpts or {}
		ViewportOrbit.SanitizeModelForViewport(model)
		model.Parent = worldModel

		local okBox, boxCf, boxSize = pcall(function()
			return model:GetBoundingBox()
		end)
		if okBox and boxCf and boxSize then
			local offsetToOrigin = -boxCf.Position
			pcall(function()
				model:PivotTo(model:GetPivot() + offsetToOrigin)
			end)
			if mOpts.UprightWeapon and boxSize.Z > boxSize.Y * 1.35 and boxSize.Z > boxSize.X * 1.35 then
				pcall(function()
					model:PivotTo(CFrame.Angles(math.rad(-68), math.rad(15), 0) * model:GetPivot())
				end)
				local ok2, cf2, sz2 = pcall(function()
					return model:GetBoundingBox()
				end)
				if ok2 and cf2 and sz2 then
					pcall(function()
						model:PivotTo(model:GetPivot() - cf2.Position)
					end)
					boxSize = sz2
				end
			end

			local maxDim = math.max(boxSize.X, boxSize.Y, boxSize.Z, 1.2)
			local halfFov = math.rad(camera.FieldOfView * 0.5)
			local fitDist = (maxDim * 0.56) / math.max(0.2, math.tan(halfFov))
			local fitMult = mOpts.FitMultiplier or cfg.FitMultiplier or 1.08
			state.baseRadius = math.clamp(fitDist * fitMult, 2.2, 48)
		else
			state.baseRadius = 6.5
		end

		state.focusPoint = mOpts.FocusOffset or Vector3.zero
		if mOpts.ResetAngles then
			state.yaw = mOpts.InitialYaw or cfg.InitialYaw or math.rad(24)
			state.pitch = math.clamp(mOpts.InitialPitch or cfg.InitialPitch or math.rad(12), minPitch, maxPitch)
			state.targetZoom = math.clamp(cfg.InitialZoom or 1.0, minZoom, maxZoom)
			state.currentZoom = state.targetZoom
		elseif mOpts.InitialYaw ~= nil then
			state.yaw = mOpts.InitialYaw
		end

		state.activeModel = model
		updateCamera()
	end

	function api:SetCustomStep(fn: ((number, number, Model?, WorldModel) -> ())?)
		state.customStep = fn
	end

	function api:GetActiveModel(): Model?
		return state.activeModel
	end

	function api:SetHintVisible(vis: boolean)
		if hintLabel then
			hintLabel.Visible = vis
		end
	end

	function api:ResetView()
		state.yaw = cfg.InitialYaw or math.rad(22)
		state.pitch = math.clamp(cfg.InitialPitch or math.rad(12), minPitch, maxPitch)
		state.targetZoom = 1.0
	end

	function api:Destroy()
		if state.destroyed then
			return
		end
		state.destroyed = true
		api._destroyed = true
		state.customStep = nil
		if state.unsubLang then
			state.unsubLang()
			state.unsubLang = nil
		end
		for _, conn in ipairs(state.connections) do
			conn:Disconnect()
		end
		table.clear(state.connections)
		self:ClearModel()
	end

	table.insert(state.connections, viewport.Destroying:Once(function()
		api:Destroy()
	end))

	updateCamera()
	return api
end

return ViewportOrbit
