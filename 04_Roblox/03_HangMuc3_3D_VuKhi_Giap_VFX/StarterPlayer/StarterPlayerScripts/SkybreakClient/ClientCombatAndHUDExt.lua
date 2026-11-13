-- SKYBREAK: Fragments of the Core — Modular Client Combat, 3D Aiming, 0ms Weapon Audio, Unified Skill/Utility HUD, Ship Pilot & Onboarding Beam
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/ClientCombatAndHUDExt.lua

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")
local LocalizationService = game:GetService("LocalizationService")
local Workspace = game:GetService("Workspace")
local ChoreoOk, CombatChoreo = pcall(function()
	return require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("SkybreakCombatChoreography"))
end)

local CombatExt = {}

local ctx = nil
local player = Players.LocalPlayer
local C = nil
local remotes = nil
local UI = nil
local AudioEngine = nil
local tempFX = nil

local latestSyncedState = nil
local bloxSkillCooldowns = {}
local utilityCooldowns = {}
local fruitIdLookup = {}

-- Rule 3: Complete Canonical + Legacy Alias Devil Fruit Lookup (all 12 Fruits)
local DEFAULT_CANONICAL_FRUITS = {
	galecore = "GaleCore", gale = "GaleCore", wind = "GaleCore",
	sandstonecore = "SandstoneCore", sandstone = "SandstoneCore", sand = "SandstoneCore", smoke = "SandstoneCore",
	solarflamecore = "SolarFlameCore", solarflame = "SolarFlameCore", flame = "SolarFlameCore", fire = "SolarFlameCore",
	glaciericecore = "GlacierIceCore", glacierice = "GlacierIceCore", ice = "GlacierIceCore", frost = "GlacierIceCore",
	celestiallightcore = "CelestialLightCore", celestiallight = "CelestialLightCore", light = "CelestialLightCore",
	starforgedmagmacore = "StarforgedMagmaCore", starforgedmagma = "StarforgedMagmaCore", magma = "StarforgedMagmaCore",
	thunderrumblecore = "ThunderRumbleCore", thunderrumble = "ThunderRumbleCore", rumble = "ThunderRumbleCore", thunder = "ThunderRumbleCore",
	astralgravitycore = "AstralGravityCore", astralgravity = "AstralGravityCore", gravity = "AstralGravityCore",
	dimensionalportalcore = "DimensionalPortalCore", dimensionalportal = "DimensionalPortalCore", portal = "DimensionalPortalCore",
	solartitancore = "SolarTitanCore", solartitan = "SolarTitanCore", buddha = "SolarTitanCore", quake = "SolarTitanCore", starlightquakecore = "SolarTitanCore",
	aetherflowcore = "AetherflowCore", aetherflow = "AetherflowCore", sweetdoughcore = "AetherflowCore", dough = "AetherflowCore", mochi = "AetherflowCore",
	abyssalsovereigncore = "AbyssalSovereignCore", dragon = "AbyssalSovereignCore", abyssal_dragon = "AbyssalSovereignCore",
}

local ELEMENT_HUD_PALETTES = {
	Sky = { Accent = Color3.fromRGB(252, 208, 92), Dark = Color3.fromRGB(28, 24, 14), Badge = Color3.fromRGB(218, 152, 28) },
	Frost = { Accent = Color3.fromRGB(86, 214, 255), Dark = Color3.fromRGB(12, 24, 38), Badge = Color3.fromRGB(32, 148, 224) },
	Lightning = { Accent = Color3.fromRGB(116, 184, 255), Dark = Color3.fromRGB(16, 20, 42), Badge = Color3.fromRGB(78, 118, 246) },
	Flame = { Accent = Color3.fromRGB(255, 132, 56), Dark = Color3.fromRGB(36, 16, 12), Badge = Color3.fromRGB(228, 78, 28) },
	Magma = { Accent = Color3.fromRGB(255, 96, 52), Dark = Color3.fromRGB(38, 14, 12), Badge = Color3.fromRGB(214, 58, 28) },
	Light = { Accent = Color3.fromRGB(255, 236, 124), Dark = Color3.fromRGB(30, 26, 14), Badge = Color3.fromRGB(228, 178, 36) },
	Gravity = { Accent = Color3.fromRGB(186, 112, 255), Dark = Color3.fromRGB(24, 14, 40), Badge = Color3.fromRGB(132, 58, 218) },
	Portal = { Accent = Color3.fromRGB(92, 226, 255), Dark = Color3.fromRGB(12, 26, 40), Badge = Color3.fromRGB(34, 154, 224) },
	Jade = { Accent = Color3.fromRGB(72, 236, 164), Dark = Color3.fromRGB(12, 32, 24), Badge = Color3.fromRGB(28, 172, 112) },
	Celestial = { Accent = Color3.fromRGB(255, 226, 118), Dark = Color3.fromRGB(28, 24, 16), Badge = Color3.fromRGB(224, 168, 38) },
	Void = { Accent = Color3.fromRGB(196, 108, 255), Dark = Color3.fromRGB(24, 12, 38), Badge = Color3.fromRGB(138, 48, 216) },
}

for k, v in pairs(DEFAULT_CANONICAL_FRUITS) do
	fruitIdLookup[k] = v
end

local STARTER_ITEM_NAMES = {
	starter_sword = { vi = "Kiếm Skyborn", en = "Skyborn Sword" },
	starter_daggers = { vi = "Song Đao Skyborn", en = "Skyborn Twin Daggers" },
	starter_staff = { vi = "Trượng Arcane", en = "Arcane Staff" },
	dawnbringer_sword = { vi = "Thánh Kiếm Dawnbringer", en = "Dawnbringer" },
	stormfang_daggers = { vi = "Song Đao Stormfang", en = "Stormfang Twinblades" },
	astral_staff = { vi = "Quyền Trượng Chronostaff", en = "Chronostaff" },
	aether_flintlock = { vi = "Súng Kíp Aether", en = "Aether Flintlock" },
	skyborn_combat = { vi = "Võ Thuật Skyborn", en = "Skyborn Combat" },
}

local function getLang()
	local lp = player or Players.LocalPlayer
	local attr = lp and lp:GetAttribute("Language")
	if type(attr) == "string" then
		local low = string.lower(attr)
		if low == "en" or low == "vi" then
			return low
		end
	end
	local ok, locId = pcall(function()
		return LocalizationService.RobloxLocaleId
	end)
	if ok and type(locId) == "string" and string.sub(string.lower(locId), 1, 2) == "vi" then
		return "vi"
	end
	return "vi"
end

local function pickLang(viText, enText)
	if getLang() == "en" then
		return enText
	end
	return viText
end

local function isTouchMobile()
	local lp = player or Players.LocalPlayer
	local cam = Workspace.CurrentCamera
	return (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)
		or (lp ~= nil and lp:GetAttribute("ForceMobileUI") == true)
		or (cam ~= nil and cam.ViewportSize.X < 840)
end

local function hasNonAsciiChars(str)
	return type(str) == "string" and string.find(str, "[\194-\255]") ~= nil
end

local function localizeBilingualText(raw, fallbackVi, fallbackEn)
	local lang = getLang()
	local fallback = (lang == "en") and (fallbackEn or fallbackVi or "") or (fallbackVi or fallbackEn or "")
	if type(raw) ~= "string" or raw == "" then
		return fallback
	end
	local left, right = raw:match("^(.-)%s*•%s*(.+)$")
	if not left then
		left, right = raw:match("^(.-)%s+%-%s+(.+)$")
	end
	if left and right then
		local leftVi = hasNonAsciiChars(left)
		local rightVi = hasNonAsciiChars(right)
		if leftVi and not rightVi then
			return (lang == "en") and right or left
		elseif rightVi and not leftVi then
			return (lang == "en") and left or right
		elseif not leftVi and not rightVi then
			if lang == "vi" and fallbackVi and fallbackVi ~= "" then
				return fallbackVi
			end
			return left
		end
		return (lang == "en") and right or left
	end
	if lang == "en" and hasNonAsciiChars(raw) and fallbackEn and fallbackEn ~= "" then
		return fallbackEn
	elseif lang == "vi" and not hasNonAsciiChars(raw) and fallbackVi and fallbackVi ~= "" then
		return fallbackVi
	end
	return raw
end

local function localizeItemDisplayName(itemId, rawName, fallbackVi, fallbackEn)
	local mapped = itemId and STARTER_ITEM_NAMES[tostring(itemId)]
	local fbVi = (mapped and mapped.vi) or fallbackVi
	local fbEn = (mapped and mapped.en) or fallbackEn
	return localizeBilingualText(rawName, fbVi, fbEn)
end

local function normalizeVolumeMul(raw, defaultMul)
	local v = tonumber(raw)
	if v == nil then
		return defaultMul or 1.0
	end
	if v > 1.0 then
		v = v / 100.0
	end
	return math.clamp(v, 0, 1.0)
end

-- ============================================================================
-- 1. IMMEDIATE 0ms DUAL-LAYER WEAPON & M1 DSP AUDIO SYNTHESIZER
-- Uses universally cached core engine transients sculpted with EQ/Pitch/Distortion
-- so Slot 1 (Martial), Slot 2 (Elemental), Slot 3 (Sword), and Slot 4 (Gun) play
-- at 0ms with distinct character and NEVER suffer a 550ms unloaded-asset delay.
-- ============================================================================
local CORE_TRANSIENTS = {
	BladeSlash = "rbxassetid://12222216",
	BladeLunge = "rbxassetid://12222208",
	SteelRing = "rbxassetid://12222225",
	MartialThud = "rbxassetid://12222084",
	AirWhip = "rbxassetid://12222152",
	AuraSwoosh = "rbxassetid://12222200",
	LaserPulse = "rbxassetid://12221976",
	HeavyBoom = "rbxassetid://12222030",
	MechClick = "rbxassetid://12221967",
}

local weaponSynthPool = {}
local weaponSynthCursor = 0
local WEAPON_POOL_SIZE = 10
local lastActorWeaponSFXAt = {}
local lastLocalWeaponSFXClock = -10
local localComboCounter = 0
local lastLocalComboAt = -10

local function getSoundGroup()
	if AudioEngine and AudioEngine.AudioGroup then
		return AudioEngine.AudioGroup
	end
	return SoundService:FindFirstChild("SkybreakAudioEngine")
end

local function isMuted()
	local lp = player or Players.LocalPlayer
	if lp and (lp:GetAttribute("MuteSFX") == true or lp:GetAttribute("MuteAudio") == true or lp:GetAttribute("AudioMuted") == true) then
		return true
	end
	local masterMul = normalizeVolumeMul(lp and lp:GetAttribute("MasterVolume"), 1.0)
	local sfxMul = normalizeVolumeMul(lp and lp:GetAttribute("SFXVolume"), 1.0)
	if (masterMul * sfxMul) <= 0.0005 then
		return true
	end
	local sg = getSoundGroup()
	if sg and sg.Volume <= 0.001 then
		return true
	end
	return false
end

local function refreshWeaponSynthPoolVolumes()
	local lp = player or Players.LocalPlayer
	local muted = isMuted()
	local volGain = muted and 0 or (normalizeVolumeMul(lp and lp:GetAttribute("MasterVolume"), 1.0) * normalizeVolumeMul(lp and lp:GetAttribute("SFXVolume"), 1.0))
	for _, node in ipairs(weaponSynthPool) do
		if node then
			if node.LayerA and node.LayerA.Parent and node.LayerA.IsPlaying then
				node.LayerA.Volume = math.clamp((tonumber(node.BaseVolA) or 0.5) * volGain, 0, 2.0)
			end
			if node.LayerB and node.LayerB.Parent and node.LayerB.IsPlaying then
				node.LayerB.Volume = math.clamp((tonumber(node.BaseVolB) or 0.45) * volGain, 0, 2.0)
			end
		end
	end
end

local function ensureWeaponSynthPool()
	if #weaponSynthPool > 0 then
		return
	end
	local folder = Workspace:FindFirstChild("SkybreakWeaponAudioPool")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "SkybreakWeaponAudioPool"
		folder.Parent = Workspace
	end
	local sg = getSoundGroup()
	local preloadList = {}

	for i = 1, WEAPON_POOL_SIZE do
		local emitter = Instance.new("Part")
		emitter.Name = "WeaponSFXNode_" .. tostring(i)
		emitter.Size = Vector3.new(0.2, 0.2, 0.2)
		emitter.Anchored = true
		emitter.CanCollide = false
		emitter.CanQuery = false
		emitter.CanTouch = false
		emitter.CastShadow = false
		emitter.Transparency = 1
		emitter.Position = Vector3.new(0, -3200, 0)
		emitter.Parent = folder

		local sA = Instance.new("Sound")
		sA.Name = "LayerA"
		sA.RollOffMode = Enum.RollOffMode.InverseTapered
		sA.RollOffMinDistance = 12
		sA.RollOffMaxDistance = 170
		sA.SoundGroup = sg
		sA.Parent = emitter

		local eqA = Instance.new("EqualizerSoundEffect")
		eqA.Parent = sA
		local distA = Instance.new("DistortionSoundEffect")
		distA.Enabled = false
		distA.Parent = sA

		local sB = Instance.new("Sound")
		sB.Name = "LayerB"
		sB.RollOffMode = Enum.RollOffMode.InverseTapered
		sB.RollOffMinDistance = 12
		sB.RollOffMaxDistance = 170
		sB.SoundGroup = sg
		sB.Parent = emitter

		local eqB = Instance.new("EqualizerSoundEffect")
		eqB.Parent = sB
		local revB = Instance.new("ReverbSoundEffect")
		revB.DecayTime = 0.75
		revB.Density = 0.7
		revB.Diffusion = 0.8
		revB.DryLevel = 0
		revB.WetLevel = -12
		revB.Enabled = false
		revB.Parent = sB

		weaponSynthPool[i] = {
			Part = emitter,
			LayerA = sA,
			EQA = eqA,
			DistA = distA,
			LayerB = sB,
			EQB = eqB,
			RevB = revB,
		}
	end

	for _, id in pairs(CORE_TRANSIENTS) do
		local pre = Instance.new("Sound")
		pre.SoundId = id
		table.insert(preloadList, pre)
	end
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync(preloadList)
		end)
		for _, pre in ipairs(preloadList) do
			pre:Destroy()
		end
	end)
end

function CombatExt.WasLocalWeaponSFXRecent(windowSec)
	return (os.clock() - lastLocalWeaponSFXClock) <= (tonumber(windowSec) or 0.48)
end

function CombatExt.NextLocalComboIndex()
	local now = os.clock()
	if (now - lastLocalComboAt) > 1.35 then
		localComboCounter = 1
	else
		localComboCounter = (localComboCounter % 4) + 1
	end
	lastLocalComboAt = now
	return localComboCounter
end

function CombatExt.PlayWeaponSFX(slot, isHeavy, combo, element, worldPos, actorKey)
	if ChoreoOk and CombatChoreo and player and player.Character then
		local chNow = player.Character
		local stunnedNow = (ctx and ctx.IsClientStunned and ctx.IsClientStunned(chNow)) == true
		if not stunnedNow and chNow:GetAttribute("SkyShipPilot") ~= true then
			if actorKey == "local" then
				local curSlot, itemId = CombatExt.ResolveActiveCombatLoadout()
				if not (curSlot == 2 and (itemId == "" or itemId == "None")) then
					CombatChoreo.TriggerLocalM1(player, slot or curSlot, itemId, combo, isHeavy)
				end
			elseif actorKey == "local_skill" then
				local curSlot, itemId = CombatExt.ResolveActiveCombatLoadout()
				local skKey = string.upper(tostring(chNow:GetAttribute("LastClientSkillKey") or ""))
				if skKey ~= "" and not (skKey == "F" and ctx and ctx.IsCurrentSlotTrueFlightF and ctx.IsCurrentSlotTrueFlightF()) then
					CombatChoreo.TriggerLocalSkill(player, slot or curSlot, itemId, skKey)
				end
			end
		end
	end
	if isMuted() then
		return
	end
	local now = os.clock()
	local dedupKey = tostring(actorKey or "local")
	if (now - (lastActorWeaponSFXAt[dedupKey] or -10)) < 0.11 then
		return
	end
	lastActorWeaponSFXAt[dedupKey] = now
	if dedupKey == "local" or (player and dedupKey == tostring(player.UserId)) then
		lastLocalWeaponSFXClock = now
	end

	ensureWeaponSynthPool()
	if #weaponSynthPool == 0 then
		return
	end
	weaponSynthCursor = (weaponSynthCursor % #weaponSynthPool) + 1
	local node = weaponSynthPool[weaponSynthCursor]
	if not node or not node.Part or not node.Part.Parent then
		weaponSynthPool = {}
		ensureWeaponSynthPool()
		node = weaponSynthPool[1]
		if not node then return end
	end

	local ch = player and player.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local cam = Workspace.CurrentCamera
	local pos = (typeof(worldPos) == "Vector3" and worldPos)
		or (hrp and hrp.Position)
		or (cam and cam.CFrame.Position)
		or Vector3.zero
	node.Part.Position = pos

	local sg = getSoundGroup()
	if sg then
		node.LayerA.SoundGroup = sg
		node.LayerB.SoundGroup = sg
	end

	local sIdx = math.clamp(tonumber(slot) or 1, 1, 4)
	local cmb = math.clamp(tonumber(combo) or 1, 1, 4)
	local jitter = (math.random() - 0.5) * 0.05
	local el = string.lower(tostring(element or ""))

	if node.LayerA.IsPlaying then node.LayerA:Stop() end
	if node.LayerB.IsPlaying then node.LayerB:Stop() end

	if sIdx == 1 then
		-- Slot 1: Martial Arts Punch / Kick Impact (crisp air-whip + low-end body thud)
		node.LayerA.SoundId = CORE_TRANSIENTS.AirWhip
		node.LayerA.Volume = isHeavy and 0.62 or 0.48
		node.LayerA.PlaybackSpeed = (isHeavy and 1.06 or (1.30 + cmb * 0.07)) + jitter
		node.EQA.LowGain = 2
		node.EQA.MidGain = 5
		node.EQA.HighGain = -2
		node.DistA.Level = isHeavy and 0.20 or 0.08
		node.DistA.Enabled = true

		node.LayerB.SoundId = isHeavy and CORE_TRANSIENTS.HeavyBoom or CORE_TRANSIENTS.MartialThud
		node.LayerB.Volume = isHeavy and 0.68 or 0.56
		node.LayerB.PlaybackSpeed = (isHeavy and 1.38 or (0.96 + cmb * 0.05)) + jitter
		node.EQB.LowGain = 8
		node.EQB.MidGain = 2
		node.EQB.HighGain = -5
		node.RevB.Enabled = isHeavy == true
		node.RevB.WetLevel = -14
	elseif sIdx == 2 then
		-- Slot 2: Elemental Devil Fruit Cast (element-sculpted harmonic + aura surge)
		if el:find("flame") or el:find("fire") or el:find("magma") or el:find("solar") then
			node.LayerA.SoundId = CORE_TRANSIENTS.HeavyBoom
			node.LayerA.Volume = isHeavy and 0.64 or 0.50
			node.LayerA.PlaybackSpeed = (isHeavy and 1.15 or 1.46) + jitter
			node.EQA.LowGain = 6
			node.EQA.MidGain = 3
			node.EQA.HighGain = -1
			node.DistA.Level = 0.16
			node.DistA.Enabled = true

			node.LayerB.SoundId = CORE_TRANSIENTS.AuraSwoosh
			node.LayerB.Volume = 0.48
			node.LayerB.PlaybackSpeed = 0.92 + cmb * 0.05 + jitter
			node.EQB.LowGain = 3
			node.EQB.MidGain = 2
			node.EQB.HighGain = 3
			node.RevB.Enabled = true
			node.RevB.WetLevel = -10
		elseif el:find("frost") or el:find("ice") or el:find("light") or el:find("celestial") then
			node.LayerA.SoundId = CORE_TRANSIENTS.SteelRing
			node.LayerA.Volume = 0.46
			node.LayerA.PlaybackSpeed = 1.52 + cmb * 0.06 + jitter
			node.EQA.LowGain = -4
			node.EQA.MidGain = 4
			node.EQA.HighGain = 8
			node.DistA.Enabled = false

			node.LayerB.SoundId = CORE_TRANSIENTS.LaserPulse
			node.LayerB.Volume = 0.42
			node.LayerB.PlaybackSpeed = 1.34 + jitter
			node.EQB.LowGain = -2
			node.EQB.MidGain = 3
			node.EQB.HighGain = 7
			node.RevB.Enabled = true
			node.RevB.WetLevel = -8
		elseif el:find("lightning") or el:find("thunder") or el:find("rumble") then
			node.LayerA.SoundId = CORE_TRANSIENTS.LaserPulse
			node.LayerA.Volume = 0.56
			node.LayerA.PlaybackSpeed = 1.44 + cmb * 0.06 + jitter
			node.EQA.LowGain = 1
			node.EQA.MidGain = 5
			node.EQA.HighGain = 7
			node.DistA.Level = 0.24
			node.DistA.Enabled = true

			node.LayerB.SoundId = CORE_TRANSIENTS.HeavyBoom
			node.LayerB.Volume = 0.44
			node.LayerB.PlaybackSpeed = 1.72 + jitter
			node.EQB.LowGain = 5
			node.EQB.MidGain = 2
			node.EQB.HighGain = 4
			node.RevB.Enabled = true
			node.RevB.WetLevel = -11
		else
			-- Void / Gravity / Portal / Gale / Dough / Dragon elemental surge
			node.LayerA.SoundId = CORE_TRANSIENTS.AuraSwoosh
			node.LayerA.Volume = 0.56
			node.LayerA.PlaybackSpeed = (isHeavy and 0.72 or (0.86 + cmb * 0.06)) + jitter
			node.EQA.LowGain = 6
			node.EQA.MidGain = 2
			node.EQA.HighGain = 3
			node.DistA.Enabled = false

			node.LayerB.SoundId = CORE_TRANSIENTS.LaserPulse
			node.LayerB.Volume = 0.38
			node.LayerB.PlaybackSpeed = 0.84 + cmb * 0.05 + jitter
			node.EQB.LowGain = 4
			node.EQB.MidGain = 3
			node.EQB.HighGain = 4
			node.RevB.Enabled = true
			node.RevB.WetLevel = -9
		end
	elseif sIdx == 3 then
		-- Slot 3: Metallic Sword Slash (razor blade transient + steel harmonic ring)
		node.LayerA.SoundId = (cmb % 2 == 0) and CORE_TRANSIENTS.BladeLunge or CORE_TRANSIENTS.BladeSlash
		node.LayerA.Volume = isHeavy and 0.68 or 0.54
		node.LayerA.PlaybackSpeed = (isHeavy and 0.86 or (1.06 + cmb * 0.07)) + jitter
		node.EQA.LowGain = isHeavy and 3 or -1
		node.EQA.MidGain = 3
		node.EQA.HighGain = 7
		node.DistA.Enabled = false

		node.LayerB.SoundId = CORE_TRANSIENTS.SteelRing
		node.LayerB.Volume = isHeavy and 0.36 or 0.24
		node.LayerB.PlaybackSpeed = (isHeavy and 1.12 or (1.36 + cmb * 0.06)) + jitter
		node.EQB.LowGain = -4
		node.EQB.MidGain = 2
		node.EQB.HighGain = 8
		node.RevB.Enabled = true
		node.RevB.WetLevel = -12
	else
		-- Slot 4: Crisp Gunshot / Laser Blast (high-voltage energy crack + muzzle punch)
		node.LayerA.SoundId = CORE_TRANSIENTS.LaserPulse
		node.LayerA.Volume = isHeavy and 0.68 or 0.56
		node.LayerA.PlaybackSpeed = (isHeavy and 0.90 or (1.28 + (cmb % 2) * 0.08)) + jitter
		node.EQA.LowGain = 1
		node.EQA.MidGain = 5
		node.EQA.HighGain = 6
		node.DistA.Level = 0.22
		node.DistA.Enabled = true

		node.LayerB.SoundId = CORE_TRANSIENTS.HeavyBoom
		node.LayerB.Volume = isHeavy and 0.62 or 0.44
		node.LayerB.PlaybackSpeed = (isHeavy and 1.18 or 1.78) + jitter
		node.EQB.LowGain = 7
		node.EQB.MidGain = 2
		node.EQB.HighGain = -2
		node.RevB.Enabled = isHeavy == true
		node.RevB.WetLevel = -13
	end

	local lpVol = player or Players.LocalPlayer
	local masterMul = normalizeVolumeMul(lpVol and lpVol:GetAttribute("MasterVolume"), 1.0)
	local sfxMul = normalizeVolumeMul(lpVol and lpVol:GetAttribute("SFXVolume"), 1.0)
	local volGain = masterMul * sfxMul
	node.BaseVolA = node.LayerA.Volume
	node.BaseVolB = node.LayerB.Volume
	node.LayerA.Volume = math.clamp(node.LayerA.Volume * volGain, 0, 2.0)
	node.LayerB.Volume = math.clamp(node.LayerB.Volume * volGain, 0, 2.0)

	node.LayerA.TimePosition = 0
	node.LayerB.TimePosition = 0
	node.LayerA:Play()
	node.LayerB:Play()
end

-- ============================================================================
-- 2. 3D CURSOR / LOCK-ON AIMING RAYCAST (240 STUDS)
-- ============================================================================
local aimRayParams = RaycastParams.new()
aimRayParams.FilterType = Enum.RaycastFilterType.Exclude
aimRayParams.IgnoreWater = true

local function isPartInEnemyOrPlayer(inst, selfChar)
	if not inst then return false end
	local fEnemies = Workspace:FindFirstChild("ActiveEnemies")
	if fEnemies and inst:IsDescendantOf(fEnemies) then return true end
	local fBosses = Workspace:FindFirstChild("ActiveBosses")
	if fBosses and inst:IsDescendantOf(fBosses) then return true end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character and plr.Character ~= selfChar and inst:IsDescendantOf(plr.Character) then
			return true
		end
	end
	return false
end

function CombatExt.Compute3DAimPayload()
	local lp = player or Players.LocalPlayer
	local ch = lp and lp.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local cam = Workspace.CurrentCamera
	local origin = (hrp and (hrp.Position + Vector3.new(0, 1.5, 0)))
		or (cam and cam.CFrame.Position)
		or Vector3.zero
	local fallbackDir = (hrp and hrp.CFrame.LookVector)
		or (cam and cam.CFrame.LookVector)
		or Vector3.new(0, 0, -1)

	-- 1. Priority: Active Lock-On Target center
	local lockPos = ch and ch:GetAttribute("LockTargetPos")
	if typeof(lockPos) == "Vector3" then
		local delta = lockPos - origin
		local dirUnit = (delta.Magnitude > 0.05) and delta.Unit or fallbackDir
		return {
			AimOrigin = origin,
			AimDir = dirUnit,
			TargetPos = lockPos,
			aimOrigin = origin,
			aimDir = dirUnit,
			targetPos = lockPos,
			Direction = dirUnit,
		}
	end

	-- 2. Otherwise cast 240-stud Camera Ray through PC Mouse or Mobile/Gamepad/OTS Viewport Center
	if not cam then
		local hitPos = origin + fallbackDir * 120
		return {
			AimOrigin = origin,
			AimDir = fallbackDir,
			TargetPos = hitPos,
			aimOrigin = origin,
			aimDir = fallbackDir,
			targetPos = hitPos,
			Direction = fallbackDir,
		}
	end

	local vp = cam.ViewportSize
	local useCenter = isTouchMobile()
		or UserInputService.GamepadEnabled
		or (UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter)
		or (lp and lp:GetAttribute("SkybreakOTSActive") == true)

	local unitRay
	if useCenter then
		unitRay = cam:ViewportPointToRay(vp.X * 0.5, vp.Y * 0.47)
	else
		local mLoc = UserInputService:GetMouseLocation()
		unitRay = cam:ScreenPointToRay(mLoc.X, mLoc.Y)
	end

	local excl = {}
	if ch then table.insert(excl, ch) end
	if tempFX then table.insert(excl, tempFX) end
	for _, fn in ipairs({
		"TempFX", "SkybreakVFXDebris", "SkybreakSeaPlanes", "SkybreakLivingTownNPCs",
		"SkybreakWeaponAudioPool", "SkybreakAudioPool",
	}) do
		local f = Workspace:FindFirstChild(fn)
		if f then table.insert(excl, f) end
	end

	local maxDist = 240
	local hitPos = unitRay.Origin + unitRay.Direction * maxDist
	local curOrigin = unitRay.Origin
	local remDist = maxDist

	for _ = 1, 4 do
		aimRayParams.FilterDescendantsInstances = excl
		local res = Workspace:Raycast(curOrigin, unitRay.Direction * remDist, aimRayParams)
		if not res then
			break
		end
		local inst = res.Instance
		if inst and not inst.CanCollide and not isPartInEnemyOrPlayer(inst, ch) then
			table.insert(excl, inst)
			local step = (res.Position - curOrigin).Magnitude + 0.05
			curOrigin = res.Position + unitRay.Direction * 0.05
			remDist = remDist - step
			if remDist <= 1 then
				break
			end
		else
			hitPos = res.Position
			break
		end
	end

	local delta = hitPos - origin
	local dirUnit = (delta.Magnitude > 0.05) and delta.Unit or unitRay.Direction.Unit
	return {
		AimOrigin = origin,
		AimDir = dirUnit,
		TargetPos = hitPos,
		aimOrigin = origin,
		aimDir = dirUnit,
		targetPos = hitPos,
		Direction = dirUnit,
	}
end

function CombatExt.AttachAimPayload(tbl)
	local out = type(tbl) == "table" and tbl or {}
	local aim = CombatExt.Compute3DAimPayload()
	out.AimOrigin = aim.AimOrigin
	out.AimDir = aim.AimDir
	out.TargetPos = aim.TargetPos
	out.aimOrigin = aim.aimOrigin
	out.aimDir = aim.aimDir
	out.targetPos = aim.targetPos
	if out.direction == nil then
		out.direction = aim.AimDir
	end
	return out
end

function CombatExt.IsInspectModalOpen()
	local pgui = player and player:FindFirstChild("PlayerGui")
	local ov = pgui and pgui:FindFirstChild("SkybreakWorldOverlayGui")
	if ov then
		local inspectModal = ov:FindFirstChild("InspectCardModal")
		if inspectModal and inspectModal:IsA("GuiObject") and inspectModal.Visible then
			return true
		end
		local mvpModal = ov:FindFirstChild("MVPSummaryModal")
		if mvpModal and mvpModal:IsA("GuiObject") and mvpModal.Visible then
			return true
		end
	end
	return false
end

-- ============================================================================
-- 3. ACTIVE LOADOUT & BLOX FRUITS SKILL + SECONDARY UTILITY STRIP HUD
-- ============================================================================
function CombatExt.ResolveActiveCombatLoadout()
	local ch = player and player.Character
	local rawTier = tonumber((ch and ch:GetAttribute("DragonFormTier")) or (player and player:GetAttribute("DragonFormTier"))) or 0
	local tf = tostring((ch and ch:GetAttribute("FruitTransform")) or (player and player:GetAttribute("FruitTransform")) or "")
	local dragonTier = 0
	if rawTier >= 2 or tf == "AbyssalSovereign" or tf == "DragonFull" then
		dragonTier = 2
	elseif rawTier == 1 or tf == "AbyssalDragonHybrid" or tf == "DragonHybrid" then
		dragonTier = 1
	end

	if C and C.AetherFruits and C.AetherFruits.AbyssalSovereignCore and type(C.GetDragonFormMoves) == "function" then
		local dFruit = C.AetherFruits.AbyssalSovereignCore
		dFruit.HumanMoves = dFruit.HumanMoves or dFruit.Moves
		if dragonTier >= 1 then
			local activeMoves = C.GetDragonFormMoves(dragonTier)
			if activeMoves then
				dFruit.Moves = activeMoves
			end
		elseif dFruit.HumanMoves then
			dFruit.Moves = dFruit.HumanMoves
		end
	end

	local curSlot = tonumber((ch and ch:GetAttribute("ActiveSlot")) or (player and player:GetAttribute("ActiveSlot")) or (latestSyncedState and latestSyncedState.ActiveSlot)) or 1
	local rawFruit = tostring((ch and ch:GetAttribute("EquippedFruit")) or (player and player:GetAttribute("EquippedFruit")) or (latestSyncedState and (latestSyncedState.EquippedFruit or latestSyncedState.FruitId)) or "")
	rawFruit = rawFruit:match("^([^|]+)") or rawFruit
	local fruitId = (rawFruit ~= "" and rawFruit ~= "None") and (fruitIdLookup[string.lower(rawFruit)] or (C and C.AetherFruits and C.AetherFruits[rawFruit] and rawFruit)) or nil
	if dragonTier >= 1 then
		fruitId = "AbyssalSovereignCore"
		curSlot = 2
	end

	local masteryTable = (latestSyncedState and type(latestSyncedState.Mastery) == "table" and latestSyncedState.Mastery) or {}

	if curSlot == 2 then
		local fDef = fruitId and C and C.AetherFruits and C.AetherFruits[fruitId] or nil
		if fDef then
			local moves = fDef.HumanMoves or fDef.Moves
			local headerName = localizeItemDisplayName(fDef.Id, fDef.Name, "Lõi Aether", "Aether Core")
			if fDef.Id == "AbyssalSovereignCore" then
				if dragonTier >= 2 then
					moves = fDef.Form2Moves or moves
					headerName = pickLang("Thái Cổ Long Hoàng • Dạng 2", "Abyssal Dragon Sovereign • Form 2")
				elseif dragonTier == 1 then
					moves = fDef.Form1Moves or moves
					headerName = pickLang("Bán Long Nhân • Dạng 1", "Abyssal Dragon Hybrid • Form 1")
				else
					headerName = pickLang("Lõi Long Đế Vực Thẳm", "Abyssal Sovereign Core")
				end
			end
			local mas = tonumber(masteryTable[fDef.Id] or (player and player:GetAttribute("FruitMastery_" .. tostring(fDef.Id))) or masteryTable.Fruit or (player and player:GetAttribute("FruitMastery"))) or 1
			return curSlot, fDef.Id, headerName, fDef.Element or "Void", mas, moves or {}
		end
		return 2, "None", pickLang("Chưa Ăn Lõi", "Empty Aether Core"), "Sky", 1, {}
	elseif curSlot == 1 then
		local rawStyle = tostring((ch and ch:GetAttribute("FightingStyle")) or (player and (player:GetAttribute("FightingStyle") or player:GetAttribute("EquippedStyle"))) or (latestSyncedState and latestSyncedState.FightingStyle) or "skyborn_combat")
		local sDef = (C and C.FightingStyles and (C.FightingStyles[rawStyle] or C.FightingStyles.skyborn_combat))
		if sDef then
			local mas = tonumber(masteryTable[sDef.Id] or masteryTable.Melee or (player and player:GetAttribute("MeleeMastery"))) or 1
			local sTitle = localizeItemDisplayName(sDef.Id, sDef.Name, "Võ Thuật Skyborn", "Skyborn Combat")
			return curSlot, sDef.Id, sTitle, sDef.Element or "Sky", mas, sDef.Moves or {}
		end
		return 1, rawStyle, pickLang("Võ Thuật Skyborn", "Skyborn Combat"), "Sky", 1, {}
	elseif curSlot == 3 then
		local eqWep = tostring((latestSyncedState and latestSyncedState.Equipment and latestSyncedState.Equipment.Weapon) or (ch and ch:GetAttribute("EquippedWeapon")) or (player and player:GetAttribute("EquippedWeapon")) or "starter_sword")
		local wDef = (C and C.Swords and (C.Swords[eqWep] or C.Swords[string.lower(eqWep)] or C.Swords.starter_sword))
		if wDef then
			local mas = tonumber(masteryTable[wDef.Id] or masteryTable.Sword or (player and player:GetAttribute("SwordMastery"))) or 1
			local wTitle = localizeItemDisplayName(wDef.Id, wDef.Name, "Kiếm Skyborn", "Skyborn Sword")
			return curSlot, wDef.Id, wTitle, wDef.Element or "Sky", mas, wDef.Moves or {}
		end
		return 3, eqWep, pickLang("Kiếm Skyborn", "Skyborn Sword"), "Sky", 1, {}
	elseif curSlot == 4 then
		local eqGun = tostring((latestSyncedState and latestSyncedState.Equipment and (latestSyncedState.Equipment.Offhand or latestSyncedState.Equipment.Gun)) or (player and player:GetAttribute("EquippedGun")) or "aether_flintlock")
		local gDef = (C and C.Guns and (C.Guns[eqGun] or C.Guns[string.lower(eqGun)] or C.Guns.aether_flintlock))
		if gDef then
			local mas = tonumber(masteryTable[gDef.Id] or masteryTable.Gun or (player and player:GetAttribute("GunMastery"))) or 1
			local gTitle = localizeItemDisplayName(gDef.Id, gDef.Name, "Súng Kíp Aether", "Aether Flintlock")
			return curSlot, gDef.Id, gTitle, gDef.Element or "Sky", mas, gDef.Moves or {}
		end
		return 4, eqGun, pickLang("Súng Kíp Aether", "Aether Flintlock"), "Sky", 1, {}
	end

	return 1, "skyborn_combat", pickLang("Võ Thuật Skyborn", "Skyborn Combat"), "Sky", 1, (C and C.FightingStyles and C.FightingStyles.skyborn_combat and C.FightingStyles.skyborn_combat.Moves) or {}
end

function CombatExt.CanClientCastSkillKey(moveKey)
	local k = string.upper(tostring(moveKey or ""))
	if k ~= "Z" and k ~= "X" and k ~= "C" and k ~= "V" and k ~= "F" then return false end
	if ctx and ctx.IsClientStunned and ctx.IsClientStunned(player and player.Character) then return false end
	local curSlot, itemId, _, _, curMas, moves = CombatExt.ResolveActiveCombatLoadout()
	local mv = moves and moves[k]
	if not mv then return false end
	if curMas < (tonumber(mv.Mastery) or 1) then return false end
	local cdId = tostring(curSlot) .. "_" .. tostring(itemId) .. "_" .. k
	local existing = bloxSkillCooldowns[cdId]
	if existing and existing.End and (existing.End - os.clock()) > 0.05 then return false end
	local energy = (ctx and ctx.GetSyncedEnergy and ctx.GetSyncedEnergy(player and player.Character)) or 100
	if energy < (tonumber(mv.Cost) or 0) then return false end
	return true
end

function CombatExt.TriggerBloxSkillCooldown(moveKey, customDuration)
	local k = string.upper(tostring(moveKey or ""))
	if k ~= "Z" and k ~= "X" and k ~= "C" and k ~= "V" and k ~= "F" then return end
	if not customDuration and ctx and ctx.IsClientStunned and ctx.IsClientStunned(player and player.Character) then return end
	local curSlot, itemId, _, _, curMas, moves = CombatExt.ResolveActiveCombatLoadout()
	local mv = moves and moves[k]
	if not mv then return end
	local reqMas = tonumber(mv.Mastery) or 1
	if curMas < reqMas then return end
	local energy = (ctx and ctx.GetSyncedEnergy and ctx.GetSyncedEnergy(player and player.Character)) or 100
	if not customDuration and energy < (tonumber(mv.Cost) or 0) then return end
	local cd = tonumber(customDuration) or tonumber(mv.Cooldown) or 6.0
	if cd <= 0 then return end
	local cdId = tostring(curSlot) .. "_" .. tostring(itemId) .. "_" .. k
	local now = os.clock()
	local existing = bloxSkillCooldowns[cdId]
	if existing and existing.End > now + 0.15 and not customDuration then
		return
	end
	bloxSkillCooldowns[cdId] = {
		Start = now,
		Duration = cd,
		End = now + cd,
	}
end

function CombatExt.TriggerUtilityCooldown(utilId, durationSec)
	local dur = tonumber(durationSec) or 2.0
	if dur <= 0 then return end
	local now = os.clock()
	utilityCooldowns[tostring(utilId)] = {
		Start = now,
		Duration = dur,
		End = now + dur,
	}
end

-- ============================================================================
-- 4. SHIP PILOT VERTICAL CONTROLS & ON-SCREEN SHIP PILOT HUD
-- ============================================================================
local lastSentShipDir = 0
local lastSentShipAt = 0

function CombatExt.IsSeatedInSkyShip()
	local ch = player and player.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	local seat = hum and hum.SeatPart
	if not seat or not seat.Parent then
		return false, false, nil, nil
	end
	local mdl = seat:FindFirstAncestorOfClass("Model")
	local activeShips = Workspace:FindFirstChild("ActiveShips")
	local isShip = (activeShips and seat:IsDescendantOf(activeShips))
		or (mdl ~= nil and (mdl:GetAttribute("ShipId") ~= nil or mdl.Name:find("SkyShip", 1, true) ~= nil))
		or seat.Name == "HelmSeat"
		or seat.Name:find("CrewSeat", 1, true) ~= nil
	if not isShip then
		return false, false, nil, nil
	end
	local isPilot = seat:IsA("VehicleSeat") or seat.Name == "HelmSeat"
	return true, isPilot, mdl, seat
end

function CombatExt.FireSeatedShipCannon(aimPayload)
	local seated, _, shipMdl = CombatExt.IsSeatedInSkyShip()
	if not seated then
		return false
	end
	local aim = aimPayload or CombatExt.Compute3DAimPayload()
	local shipPos = (shipMdl and shipMdl.PrimaryPart and shipMdl.PrimaryPart.Position) or aim.AimOrigin
	CombatExt.PlayWeaponSFX(4, true, 1, "Flame", shipPos, "ship_cannon_local")
	if remotes then
		local uiReq = remotes:FindFirstChild("UIRequest")
		if uiReq and uiReq:IsA("RemoteEvent") then
			uiReq:FireServer("FireShipCannon", {
				side = "Both",
				aimPos = aim.TargetPos,
				AimDir = aim.AimDir,
				verticalDir = lastSentShipDir,
			})
			return true
		end
	end
	local shared = ReplicatedStorage:FindFirstChild("SkybreakShared")
	local sRem = shared and shared:FindFirstChild("Remotes")
	local sReq = sRem and sRem:FindFirstChild("UIRequest")
	if sReq and sReq:IsA("RemoteEvent") then
		sReq:FireServer("FireShipCannon", {
			side = "Both",
			aimPos = aim.TargetPos,
			AimDir = aim.AimDir,
			verticalDir = lastSentShipDir,
		})
		return true
	end
	return false
end

-- ============================================================================
-- 5. FIRST-MINUTE LYRA ONBOARDING & DYNAMIC QUEST WAYPOINT 3D BEAM
-- ============================================================================
local talkedToLyraLatch = false
local wpFolder = nil
local wpTargetPart = nil
local wpTargetAtt = nil
local wpRingPart = nil
local wpPlayerAtt = nil
local wpPlayerAttParent = nil
local wpBeam = nil
local wpBill = nil
local wpLabel = nil
local wpStroke = nil
local cachedTargetPos = nil
local cachedTargetLabel = nil
local cachedTargetIsGold = true
local nextTargetScanAt = 0

function CombatExt.NotifyInteracted(interactableId)
	if tostring(interactableId or "") == "Lyra" then
		talkedToLyraLatch = true
		nextTargetScanAt = 0
	end
end

local function destroyWaypointRig()
	if wpPlayerAtt then
		pcall(function() wpPlayerAtt:Destroy() end)
		wpPlayerAtt = nil
		wpPlayerAttParent = nil
	end
	if wpFolder then
		pcall(function() wpFolder:Destroy() end)
		wpFolder = nil
	end
	wpTargetPart = nil
	wpTargetAtt = nil
	wpRingPart = nil
	wpBeam = nil
	wpBill = nil
	wpLabel = nil
	wpStroke = nil
end

local function ensureWaypointRig(hrp)
	local tfx = tempFX or Workspace:FindFirstChild("TempFX")
	if not tfx or not hrp or not hrp.Parent then
		return false
	end

	if not wpFolder or not wpFolder.Parent then
		local old = tfx:FindFirstChild("SkybreakOnboardingWaypoint")
		if old then old:Destroy() end

		wpFolder = Instance.new("Folder")
		wpFolder.Name = "SkybreakOnboardingWaypoint"
		wpFolder.Parent = tfx

		wpTargetPart = Instance.new("Part")
		wpTargetPart.Name = "WaypointAnchor"
		wpTargetPart.Size = Vector3.new(0.6, 0.6, 0.6)
		wpTargetPart.Anchored = true
		wpTargetPart.CanCollide = false
		wpTargetPart.CanQuery = false
		wpTargetPart.CanTouch = false
		wpTargetPart.CastShadow = false
		wpTargetPart.Transparency = 1
		wpTargetPart.Parent = wpFolder

		wpTargetAtt = Instance.new("Attachment")
		wpTargetAtt.Name = "TargetAtt"
		wpTargetAtt.Parent = wpTargetPart

		wpRingPart = Instance.new("Part")
		wpRingPart.Name = "WaypointHalo"
		wpRingPart.Shape = Enum.PartType.Cylinder
		wpRingPart.Size = Vector3.new(0.18, 6.5, 6.5)
		wpRingPart.Anchored = true
		wpRingPart.CanCollide = false
		wpRingPart.CanQuery = false
		wpRingPart.CanTouch = false
		wpRingPart.CastShadow = false
		wpRingPart.Material = Enum.Material.Neon
		wpRingPart.Color = Color3.fromRGB(255, 214, 92)
		wpRingPart.Transparency = 0.35
		wpRingPart.Parent = wpFolder

		wpBill = Instance.new("BillboardGui")
		wpBill.Name = "WaypointBillboard"
		wpBill.Size = UDim2.fromOffset(252, 32)
		wpBill.StudsOffset = Vector3.new(0, 4.6, 0)
		wpBill.AlwaysOnTop = true
		wpBill.MaxDistance = 2400
		wpBill.Active = false
		wpBill.Parent = wpTargetPart

		local pill = Instance.new("Frame")
		pill.Name = "Pill"
		pill.Size = UDim2.fromScale(1, 1)
		pill.BackgroundColor3 = Color3.fromRGB(10, 16, 30)
		pill.BackgroundTransparency = 0.08
		pill.BorderSizePixel = 0
		pill.Parent = wpBill
		local pc = Instance.new("UICorner")
		pc.CornerRadius = UDim.new(1, 0)
		pc.Parent = pill

		wpStroke = Instance.new("UIStroke")
		wpStroke.Color = Color3.fromRGB(255, 214, 92)
		wpStroke.Thickness = 1.6
		wpStroke.Transparency = 0.08
		wpStroke.Parent = pill

		wpLabel = Instance.new("TextLabel")
		wpLabel.Name = "MarkerText"
		wpLabel.Position = UDim2.fromOffset(10, 0)
		wpLabel.Size = UDim2.new(1, -20, 1, 0)
		wpLabel.BackgroundTransparency = 1
		wpLabel.Font = Enum.Font.GothamBold
		wpLabel.TextSize = 11
		wpLabel.TextColor3 = Color3.fromRGB(255, 244, 198)
		wpLabel.TextStrokeTransparency = 0.25
		wpLabel.TextTruncate = Enum.TextTruncate.AtEnd
		wpLabel.Text = pickLang("Gặp Chỉ Huy Lyra [E] • 24m", "Meet Cmdr. Lyra [E] • 24m")
		wpLabel.Parent = pill

		wpBeam = Instance.new("Beam")
		wpBeam.Name = "GuideBeam"
		wpBeam.FaceCamera = true
		wpBeam.Segments = 24
		wpBeam.Width0 = 0.38
		wpBeam.Width1 = 0.58
		wpBeam.LightEmission = 0.9
		wpBeam.LightInfluence = 0
		wpBeam.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0.0, 0.55),
			NumberSequenceKeypoint.new(0.25, 0.15),
			NumberSequenceKeypoint.new(0.85, 0.12),
			NumberSequenceKeypoint.new(1.0, 0.45),
		})
		wpBeam.Color = ColorSequence.new(Color3.fromRGB(255, 218, 98), Color3.fromRGB(88, 228, 255))
		wpBeam.Attachment1 = wpTargetAtt
		wpBeam.Parent = wpFolder
	end

	if not wpPlayerAtt or not wpPlayerAtt.Parent or wpPlayerAttParent ~= hrp then
		if wpPlayerAtt then
			pcall(function() wpPlayerAtt:Destroy() end)
		end
		wpPlayerAtt = Instance.new("Attachment")
		wpPlayerAtt.Name = "SkybreakGuideOriginAtt"
		wpPlayerAtt.Position = Vector3.new(0, -1.1, 0)
		wpPlayerAtt.Parent = hrp
		wpPlayerAttParent = hrp
		if wpBeam then
			wpBeam.Attachment0 = wpPlayerAtt
		end
	end

	return true
end

local function findInteractableWorldPos(targetId, fromPos)
	local bestPos = nil
	local bestDist = math.huge
	local function checkContainer(container)
		if not container then return end
		for _, d in ipairs(container:GetDescendants()) do
			if d:IsA("BasePart") and d:GetAttribute("InteractableId") == targetId then
				local dist = (d.Position - fromPos).Magnitude
				if dist < bestDist then
					bestDist = dist
					bestPos = d.Position
				end
			elseif d:IsA("Model") and (d:GetAttribute("NPCId") == targetId or d.Name == targetId or (targetId == "Lyra" and d.Name == "Lyra_SkyHubCommander")) then
				local p = d.PrimaryPart or d:FindFirstChild("Body") or d:FindFirstChildWhichIsA("BasePart")
				if p then
					local dist = (p.Position - fromPos).Magnitude
					if dist < bestDist then
						bestDist = dist
						bestPos = p.Position
					end
					if tonumber(d:GetAttribute("NPCTalkAt")) and tonumber(d:GetAttribute("NPCTalkAt")) > 0 and targetId == "Lyra" then
						talkedToLyraLatch = true
					end
				end
			end
		end
	end
	checkContainer(Workspace:FindFirstChild("WorldObjects"))
	checkContainer(Workspace:FindFirstChild("SkyHub"))
	checkContainer(Workspace:FindFirstChild("GoldenSky"))
	if not bestPos then
		for _, d in ipairs(Workspace:GetChildren()) do
			if d:IsA("Model") or d:IsA("Folder") then
				if d.Name ~= "TempFX" and d.Name ~= "ActiveEnemies" and d.Name ~= "SkybreakLivingTownNPCs" then
					local direct = d:FindFirstChild(targetId, true)
					if direct then
						local p = direct:IsA("BasePart") and direct or (direct:IsA("Model") and (direct.PrimaryPart or direct:FindFirstChildWhichIsA("BasePart"))) or nil
						if p then
							bestPos = p.Position
							break
						end
					end
				end
			end
		end
	end
	return bestPos
end

local function findAliveEnemyWorldPos(enemyId, fromPos)
	local bestPos = nil
	local bestDist = math.huge
	local targetLow = string.lower(tostring(enemyId or ""))
	for _, fn in ipairs({ "ActiveBosses", "ActiveEnemies" }) do
		local f = Workspace:FindFirstChild(fn)
		if f then
			for _, m in ipairs(f:GetChildren()) do
				if m:IsA("Model") and m:GetAttribute("EnemyDead") ~= true then
					local hum = m:FindFirstChildOfClass("Humanoid")
					local hpAttr = tonumber(m:GetAttribute("HP") or m:GetAttribute("Health"))
					local alive = (hum == nil or hum.Health > 0) and (hpAttr == nil or hpAttr > 0)
					if alive then
						local eid = tostring(m:GetAttribute("EnemyId") or m.Name or "")
						local eidLow = string.lower(eid)
						if eid == enemyId or eidLow == targetLow or eidLow:find(targetLow, 1, true) ~= nil then
							local part = m.PrimaryPart or m:FindFirstChild("Body") or m:FindFirstChild("HumanoidRootPart") or m:FindFirstChildWhichIsA("BasePart")
							if part then
								local dist = (part.Position - fromPos).Magnitude
								if dist < bestDist then
									bestDist = dist
									bestPos = part.Position
								end
							end
						end
					end
				end
			end
		end
	end
	return bestPos
end

local function localizeQuestObjectiveLabel(obj)
	local lang = getLang()
	if type(obj) ~= "table" then
		return (lang == "en") and "Quest Objective" or "Mục Tiêu Nhiệm Vụ"
	end
	if lang == "en" then
		if type(obj.LabelEn) == "string" and obj.LabelEn ~= "" then
			return obj.LabelEn
		end
		local raw = type(obj.Label) == "string" and obj.Label or ""
		if raw ~= "" then
			local tr = raw
				:gsub("^Đánh bại Boss%s+", "Defeat Boss ")
				:gsub("^Hạ gục Boss%s+", "Defeat Boss ")
				:gsub("^Đánh bại%s+", "Defeat ")
				:gsub("^Hạ gục%s+", "Defeat ")
				:gsub("^Tiêu diệt%s+", "Defeat ")
				:gsub("^Cứu người dân%s+", "Rescue Citizen ")
				:gsub("^Bật Công [tT]ắc%s+", "Activate Switch ")
			if not hasNonAsciiChars(tr) then
				return tr
			end
		end
		if type(obj.Target) == "string" and obj.Target ~= "" and not hasNonAsciiChars(obj.Target) then
			if obj.Kind == "Interact" then
				return "Quest Objective"
			end
			local enDef = C and C.Enemies and C.Enemies[obj.Target]
			if enDef and type(enDef.Name) == "string" and enDef.Name ~= "" then
				return "Defeat " .. localizeBilingualText(enDef.Name, obj.Target, obj.Target)
			end
		end
		return "Quest Objective"
	end
	if type(obj.Label) == "string" and obj.Label ~= "" then
		return obj.Label
	end
	return "Mục Tiêu Nhiệm Vụ"
end

local function resolveActiveQuestTarget(fromPos)
	local st = latestSyncedState or (UI and UI.State) or {}
	local lv = tonumber(st.Level or (player and player:GetAttribute("Level"))) or 1
	local qIdx = tonumber(st.QuestIndex or (player and player:GetAttribute("QuestIndex"))) or 1
	local qList = C and C.Quests
	local qDef = (type(qList) == "table" and qList[qIdx]) or nil
	if not qDef then
		return nil, nil, true
	end

	local progTbl = (type(st.QuestProgress) == "table" and st.QuestProgress) or {}
	local firstProg = tonumber(progTbl[1] or progTbl["1"]) or 0

	if qIdx > 1 or firstProg > 0 or lv >= 20 then
		talkedToLyraLatch = true
	end

	-- First-Minute Lv.1 Onboarding: Point straight to Commander Lyra [E] before first kill/dialogue!
	if qIdx == 1 and firstProg == 0 and not talkedToLyraLatch then
		local lyraPos = findInteractableWorldPos("Lyra", fromPos)
		if lyraPos then
			if (lyraPos - fromPos).Magnitude <= 9.5 then
				talkedToLyraLatch = true
			else
				return lyraPos, pickLang("Gặp Chỉ Huy Lyra [E]", "Meet Cmdr. Lyra [E]"), true
			end
		end
	end

	-- Otherwise point dynamically to the active quest's next incomplete objective!
	local curRealm = tostring((player and player:GetAttribute("CurrentRealm")) or st.CurrentRealm or "GoldenSky")
	if curRealm == "SkyHub" or curRealm == "" then
		curRealm = "GoldenSky"
	end
	if qDef.Realm and qDef.Realm ~= curRealm then
		local portalId = (qDef.Realm == "FrozenCyber" and "FrozenPortal")
			or (qDef.Realm == "ShadowRealm" and "ShadowPortal")
			or "WorldGate"
		local portalPos = findInteractableWorldPos(portalId, fromPos) or findInteractableWorldPos("Lyra", fromPos)
		if portalPos then
			return portalPos, pickLang("Cổng Dịch Chuyển -> ", "Realm Gate -> ") .. tostring(qDef.Realm), true
		end
	end

	local objectives = type(qDef.Objectives) == "table" and qDef.Objectives or {}
	for idx, obj in ipairs(objectives) do
		local done = tonumber(progTbl[idx] or progTbl[tostring(idx)] or progTbl[obj.Target]) or 0
		local need = tonumber(obj.Count) or 1
		if done < need then
			local labelBase = localizeQuestObjectiveLabel(obj)
			if need > 1 then
				labelBase = string.format("%s (%d/%d)", labelBase, done, need)
			end
			if obj.Kind == "Interact" then
				local iPos = findInteractableWorldPos(tostring(obj.Target), fromPos)
				if iPos then
					return iPos, labelBase .. " [E]", true
				end
			else
				local ePos = findAliveEnemyWorldPos(tostring(obj.Target), fromPos)
				if ePos then
					return ePos, labelBase, false
				end
			end
		end
	end

	return nil, nil, false
end

local STATION_NPC_CANDIDATES = {
	Kael = { "Kael", "NPC_PermafrostQuartermaster", "NPC_UmbralSwordmaster", "NPC_EmberforgeSmith" },
	Zioles = { "Zioles", "Zioles_AetherGachaShrine", "Zioles_IslandShrine" },
	DrVega = { "DrVega", "NPC_AetherShrineKeeper", "NPC_RaidLabScientist" },
}

local function resolveCustomStationWaypoint(fromPos, now)
	if not player then
		return nil, nil, false
	end
	local untilAt = tonumber(player:GetAttribute("CustomWaypointUntil")) or 0
	if untilAt <= now then
		return nil, nil, false
	end
	local targetId = tostring(player:GetAttribute("CustomWaypointTargetId") or "")
	local fallbackPos = player:GetAttribute("CustomWaypointPos")
	local label = tostring(player:GetAttribute("CustomWaypointLabel") or "")
	local bestPos = nil
	local bestDist = math.huge
	local candidates = STATION_NPC_CANDIDATES[targetId] or (targetId ~= "" and { targetId } or {})
	for _, cid in ipairs(candidates) do
		local p = findInteractableWorldPos(cid, fromPos)
		if p then
			local d = (p - fromPos).Magnitude
			if d < bestDist then
				bestDist = d
				bestPos = p
			end
		end
	end
	if not bestPos and typeof(fallbackPos) == "Vector3" then
		bestPos = fallbackPos
	end
	if not bestPos or label == "" then
		return nil, nil, false
	end
	if (bestPos - fromPos).Magnitude <= 11.5 then
		pcall(function()
			player:SetAttribute("CustomWaypointUntil", 0)
		end)
		return nil, nil, false
	end
	return bestPos, label, true
end

local function stepWaypointBeam(now)
	local ch = player and player.Character
	local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	local photoOn = player and player:GetAttribute("SkybreakPhotoMode") == true
	if not hrp or not hum or hum.Health <= 0 or photoOn then
		destroyWaypointRig()
		return
	end

	if now >= nextTargetScanAt then
		nextTargetScanAt = now + 0.45
		local customPos, customLbl, customGold = resolveCustomStationWaypoint(hrp.Position, now)
		if customPos and customLbl then
			cachedTargetPos, cachedTargetLabel, cachedTargetIsGold = customPos, customLbl, customGold
		else
			cachedTargetPos, cachedTargetLabel, cachedTargetIsGold = resolveActiveQuestTarget(hrp.Position)
		end
	end

	if not cachedTargetPos or not cachedTargetLabel then
		if wpBeam then wpBeam.Enabled = false end
		if wpBill then wpBill.Enabled = false end
		if wpRingPart then wpRingPart.Transparency = 1 end
		return
	end

	if not ensureWaypointRig(hrp) then
		return
	end

	local distStuds = (cachedTargetPos - hrp.Position).Magnitude
	local distMeters = math.max(1, math.floor(distStuds * 0.35 + 0.5))
	local bob = math.sin(now * 3.2) * 0.45
	local pulse = 6.0 + math.sin(now * 4.0) * 0.85

	wpTargetPart.Position = cachedTargetPos + Vector3.new(0, 1.4 + bob, 0)
	wpRingPart.Size = Vector3.new(0.16, pulse, pulse)
	wpRingPart.CFrame = CFrame.new(cachedTargetPos.X, cachedTargetPos.Y - 1.6, cachedTargetPos.Z) * CFrame.Angles(0, 0, math.rad(90))
	wpRingPart.Transparency = (distStuds < 7) and 0.72 or 0.32

	local cGold = Color3.fromRGB(255, 214, 92)
	local cCyan = Color3.fromRGB(72, 228, 255)
	local primaryCol = cachedTargetIsGold and cGold or cCyan
	wpRingPart.Color = primaryCol
	if wpStroke then wpStroke.Color = primaryCol end
	if wpLabel then
		wpLabel.TextColor3 = cachedTargetIsGold and Color3.fromRGB(255, 242, 192) or Color3.fromRGB(214, 248, 255)
		wpLabel.Text = string.format("%s • %dm", cachedTargetLabel, distMeters)
	end
	if wpBeam then
		wpBeam.Color = ColorSequence.new(cGold, primaryCol)
		wpBeam.Enabled = distStuds > 5.5 and distStuds < 3200
	end
	if wpBill then
		wpBill.Enabled = distStuds < 3200
	end
end

-- ============================================================================
-- 6. UNIFIED BLOX FRUITS SKILL STACK + SECONDARY UTILITY STRIP + MOBILE HEAVY + SHIP HUD
-- ============================================================================
function CombatExt.SyncState(st)
	if type(st) == "table" then
		latestSyncedState = st
	end
end

function CombatExt.NotifyCombatFX(fx)
	if type(fx) ~= "table" or not player then return end
	local actorId = tonumber(fx.Actor or fx.actor or fx.Owner or fx.userId)
	if ChoreoOk and CombatChoreo then
		local actorPlr = (actorId and Players:GetPlayerByUserId(actorId)) or (actorId == nil and player or nil)
		local actorChar = (typeof(fx.Character) == "Instance" and fx.Character:IsA("Model") and fx.Character)
			or (actorPlr and actorPlr.Character)
			or nil
		if actorChar then
			CombatChoreo.TriggerFromCombatFX(actorChar, actorPlr, fx)
		end
	end
	if actorId == nil or actorId == player.UserId then
		local k = fx.MoveKey or fx.key or (type(fx.Action) == "string" and fx.Action:match("_([ZXCVF])$"))
		if k then
			CombatExt.TriggerBloxSkillCooldown(k, tonumber(fx.Cooldown))
		end
		local act = tostring(fx.Action or fx.action or fx.skillId or "")
		if act == "ConquerorHaki" or act == "ConquerorBurst" then
			CombatExt.TriggerUtilityCooldown("ConquerorBurst", tonumber(fx.Cooldown) or 28)
		elseif act == "CelestialAegis" or act == "ThunderJudgement" or act == "AstralCataclysm" then
			CombatExt.TriggerUtilityCooldown("Ultimate", tonumber(fx.Cooldown) or 45)
		elseif act == "Dodge" or act == "Dash" or tostring(fx.Kind or "") == "Dodge" then
			CombatExt.TriggerUtilityCooldown("Dodge", tonumber(fx.Cooldown) or 1.35)
		end
	end
end

function CombatExt.Init(initCtx)
	ctx = initCtx or {}
	player = ctx.Player or Players.LocalPlayer
	C = ctx.Config
	remotes = ctx.Remotes
	UI = ctx.UI
	AudioEngine = ctx.Audio
	tempFX = ctx.TempFX

	if ctx.CanonicalFruitMap then
		for k, v in pairs(ctx.CanonicalFruitMap) do
			fruitIdLookup[string.lower(tostring(k))] = v
		end
	end
	if C and C.AetherFruits then
		for k, v in pairs(C.AetherFruits) do
			fruitIdLookup[string.lower(tostring(k))] = k
			if v.Name then
				fruitIdLookup[string.lower(tostring(v.Name))] = k
			end
		end
	end

	ensureWeaponSynthPool()

	local function bindCharSkillAttr(ch)
		if not ch or ch:GetAttribute("_BloxSkillBound") then return end
		ch:SetAttribute("_BloxSkillBound", true)
		ch:GetAttributeChangedSignal("LastClientSkillAt"):Connect(function()
			local k = ch:GetAttribute("LastClientSkillKey")
			if k then
				CombatExt.TriggerBloxSkillCooldown(k)
			end
		end)
	end
	if player then
		player.CharacterAdded:Connect(function(ch)
			destroyWaypointRig()
			nextTargetScanAt = 0
			bindCharSkillAttr(ch)
		end)
		if player.Character then
			bindCharSkillAttr(player.Character)
		end
		for _, volAttr in ipairs({ "SFXVolume", "MasterVolume", "MuteSFX", "MuteAudio", "AudioMuted" }) do
			player:GetAttributeChangedSignal(volAttr):Connect(refreshWeaponSynthPoolVolumes)
		end
		player:GetAttributeChangedSignal("CustomWaypointUntil"):Connect(function()
			nextTargetScanAt = 0
		end)
		if ChoreoOk and CombatChoreo then
			player:GetAttributeChangedSignal("ActiveSlot"):Connect(function()
				if player.Character then
					CombatChoreo.CancelCharacter(player.Character)
				end
			end)
			player:GetAttributeChangedSignal("SkybreakFlightActive"):Connect(function()
				if player:GetAttribute("SkybreakFlightActive") == true and player.Character then
					CombatChoreo.CancelCharacter(player.Character)
				end
			end)
		end
	end

	-- Build Unified BloxFruitsSkillHUD + Compact Secondary Utility Strip + Mobile SkyShip & 3D Flight Touch Controls
	task.spawn(function()
		local KEY_ORDER = { "Z", "X", "C", "V", "F" }
		local stackGui = nil
		local container = nil
		local containerScale = nil
		local containerLayout = nil
		local utilRow = nil
		local utilLayout = nil
		local headerCard = nil
		local headerTitle = nil
		local headerMasText = nil
		local headerMasFill = nil
		local headerStroke = nil
		local shipPilotPill = nil
		local shipPilotScale = nil
		local shipPilotLabel = nil
		local shipTouchRow = nil
		local shipUpBtn = nil
		local shipDownBtn = nil
		local shipFireBtn = nil
		local mobileFlightPill = nil
		local mobileFlightScale = nil
		local flightUpBtn = nil
		local flightDownBtn = nil
		local mobileHeavyBtnRef = nil
		local rowRefs = {}
		local utilRefs = {}

		local mobileShipUpHeld = false
		local mobileShipDownHeld = false
		local mobileShipUpInput = nil
		local mobileShipDownInput = nil

		local mobileFlightUpHeld = false
		local mobileFlightDownHeld = false
		local mobileFlightUpInput = nil
		local mobileFlightDownInput = nil

		-- IP-Clean Bilingual Utility Labels (PUBLISH_PLAN D1)
		local UTIL_DEFS = {
			{ Id = "Ultimate", Key = "R", LabelVi = "Chiêu", LabelEn = "Ult", Accent = Color3.fromRGB(252, 204, 84) },
			{ Id = "ActivateRaceV4", Key = "Y", LabelVi = "Thăng", LabelEn = "Ascend", Accent = Color3.fromRGB(204, 122, 255) },
			{ Id = "ToggleAura", Key = "J", LabelVi = "Giáp Ý", LabelEn = "Armor", Accent = Color3.fromRGB(252, 92, 118) },
			{ Id = "ToggleInstinct", Key = "U", LabelVi = "Thấu Ý", LabelEn = "Sense", Accent = Color3.fromRGB(84, 204, 255) },
			{ Id = "ConquerorBurst", Key = "H", LabelVi = "Bá Ý", LabelEn = "Sov.", Accent = Color3.fromRGB(255, 124, 92) },
			{ Id = "Dodge", Key = "Q", LabelVi = "Thuấn", LabelEn = "Dash", Accent = Color3.fromRGB(72, 232, 248) },
			{ Id = "UsePotion", Key = "`", LabelVi = "Thuốc", LabelEn = "Heal", Accent = Color3.fromRGB(82, 238, 152) },
		}

		local function isPointerHoldInput(input)
			return input ~= nil and (
				input.UserInputType == Enum.UserInputType.Touch
				or input.UserInputType == Enum.UserInputType.MouseButton1
			)
		end

		UserInputService.InputEnded:Connect(function(input)
			if input == mobileShipUpInput then
				mobileShipUpHeld = false
				mobileShipUpInput = nil
			end
			if input == mobileShipDownInput then
				mobileShipDownHeld = false
				mobileShipDownInput = nil
			end
			if input == mobileFlightUpInput then
				mobileFlightUpHeld = false
				mobileFlightUpInput = nil
			end
			if input == mobileFlightDownInput then
				mobileFlightDownHeld = false
				mobileFlightDownInput = nil
			end
		end)

		local function computeMobileCenterSafeScale(baseWidth, skyUI)
			local cam = Workspace.CurrentCamera
			local vpX = (cam and cam.ViewportSize.X > 0 and cam.ViewportSize.X) or 800
			local leftSafeX = 148
			local rightSafeX = vpX - 148
			local touchArc = skyUI and skyUI:FindFirstChild("MobileTouchArc", true)
			if touchArc and touchArc:IsA("GuiObject") and touchArc.Visible and touchArc.AbsolutePosition.X > 180 then
				rightSafeX = math.min(rightSafeX, touchArc.AbsolutePosition.X - 8)
			end
			local halfSpan = math.min((vpX * 0.5) - leftSafeX, rightSafeX - (vpX * 0.5))
			if halfSpan <= 40 then
				return 0.72
			end
			return math.clamp((halfSpan * 2) / math.max(1, baseWidth), 0.72, 1.0)
		end

		local function ensureMobileHeavyButton(skyUI)
			if not skyUI then return end
			local touchArc = skyUI:FindFirstChild("MobileTouchArc", true)
			if not touchArc or not touchArc:IsA("GuiObject") then return end
			local existingBtn = touchArc:FindFirstChild("MobileHeavyAttackBtn")
			if existingBtn and existingBtn:IsA("TextButton") then
				mobileHeavyBtnRef = existingBtn
				existingBtn.Text = pickLang("MẠNH", "HEAVY")
				return
			end

			local hvyBtn = Instance.new("TextButton")
			hvyBtn.Name = "MobileHeavyAttackBtn"
			hvyBtn.AnchorPoint = Vector2.new(1, 1)
			hvyBtn.Position = UDim2.new(1, -4, 1, -92)
			hvyBtn.Size = UDim2.fromOffset(52, 34)
			hvyBtn.BackgroundColor3 = Color3.fromRGB(188, 36, 68)
			hvyBtn.BorderSizePixel = 0
			hvyBtn.AutoButtonColor = true
			hvyBtn.Font = Enum.Font.GothamBlack
			hvyBtn.TextSize = 10
			hvyBtn.TextColor3 = Color3.fromRGB(255, 244, 214)
			hvyBtn.Text = pickLang("MẠNH", "HEAVY")
			hvyBtn.ZIndex = 12
			hvyBtn.Parent = touchArc
			mobileHeavyBtnRef = hvyBtn

			local hc = Instance.new("UICorner")
			hc.CornerRadius = UDim.new(1, 0)
			hc.Parent = hvyBtn

			local hs = Instance.new("UIStroke")
			hs.Color = Color3.fromRGB(255, 214, 112)
			hs.Thickness = 1.6
			hs.Parent = hvyBtn

			hvyBtn.Activated:Connect(function()
				if UI and UI.BlocksCombat and UI.BlocksCombat() then return end
				if ctx and ctx.Send then
					ctx.Send("Heavy")
				end
			end)
		end

		local function makeTouchActionBtn(parent, name, textStr, widthPx, bgCol, strokeCol, orderIdx)
			local btn = Instance.new("TextButton")
			btn.Name = name
			btn.Size = UDim2.fromOffset(widthPx, 28)
			btn.BackgroundColor3 = bgCol
			btn.BackgroundTransparency = 0.04
			btn.BorderSizePixel = 0
			btn.AutoButtonColor = true
			btn.Font = Enum.Font.GothamBlack
			btn.TextSize = 11
			btn.TextColor3 = Color3.fromRGB(246, 250, 255)
			btn.Text = textStr
			btn.LayoutOrder = orderIdx
			btn.ZIndex = 6
			btn.Parent = parent

			local bc = Instance.new("UICorner")
			bc.CornerRadius = UDim.new(1, 0)
			bc.Parent = btn

			local bs = Instance.new("UIStroke")
			bs.Color = strokeCol
			bs.Thickness = 1.4
			bs.Transparency = 0.1
			bs.Parent = btn

			return btn, bs
		end

		local function buildBloxFruitsSkillHUD()
			local pgui = player and player:WaitForChild("PlayerGui", 10)
			if not pgui then return nil end
			local existing = pgui:FindFirstChild("BloxFruitsSkillHUD")
			if existing then
				existing:Destroy()
			end

			stackGui = Instance.new("ScreenGui")
			stackGui.Name = "BloxFruitsSkillHUD"
			stackGui.ResetOnSpawn = false
			stackGui.IgnoreGuiInset = false
			stackGui.DisplayOrder = 18
			stackGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
			stackGui.Parent = pgui

			-- Ship Pilot On-Screen Control Bar (Desktop prompt + Mobile 3-Button Touch Controls)
			shipPilotPill = Instance.new("Frame")
			shipPilotPill.Name = "SkyShipPilotHUD"
			shipPilotPill.AnchorPoint = Vector2.new(0.5, 1)
			shipPilotPill.Position = UDim2.new(0.5, 0, 1, -60)
			shipPilotPill.Size = UDim2.fromOffset(556, 30)
			shipPilotPill.BackgroundColor3 = Color3.fromRGB(9, 15, 28)
			shipPilotPill.BackgroundTransparency = 0.06
			shipPilotPill.BorderSizePixel = 0
			shipPilotPill.Visible = false
			shipPilotPill.Parent = stackGui

			shipPilotScale = Instance.new("UIScale")
			shipPilotScale.Name = "MobileSafeScale"
			shipPilotScale.Scale = 1.0
			shipPilotScale.Parent = shipPilotPill

			local spCorner = Instance.new("UICorner")
			spCorner.CornerRadius = UDim.new(1, 0)
			spCorner.Parent = shipPilotPill
			local spStroke = Instance.new("UIStroke")
			spStroke.Color = Color3.fromRGB(92, 224, 255)
			spStroke.Thickness = 1.5
			spStroke.Parent = shipPilotPill

			shipPilotLabel = Instance.new("TextLabel")
			shipPilotLabel.Name = "DesktopPromptLabel"
			shipPilotLabel.Size = UDim2.fromScale(1, 1)
			shipPilotLabel.BackgroundTransparency = 1
			shipPilotLabel.Font = Enum.Font.GothamBold
			shipPilotLabel.TextSize = 11
			shipPilotLabel.TextColor3 = Color3.fromRGB(232, 248, 255)
			shipPilotLabel.Text = pickLang(
				"[WASD] Lái Tàu  •  [R / C] Nâng / Hạ Độ Cao  •  [Click] Bắn Pháo  •  [Space] Rời Tàu",
				"[WASD] Steer Ship  •  [R / C] Altitude Up / Down  •  [Click] Fire Cannons  •  [Space] Exit"
			)
			shipPilotLabel.Parent = shipPilotPill

			shipTouchRow = Instance.new("Frame")
			shipTouchRow.Name = "MobileShipTouchControls"
			shipTouchRow.Size = UDim2.fromScale(1, 1)
			shipTouchRow.BackgroundTransparency = 1
			shipTouchRow.Visible = false
			shipTouchRow.Parent = shipPilotPill

			local stLayout = Instance.new("UIListLayout")
			stLayout.FillDirection = Enum.FillDirection.Horizontal
			stLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			stLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			stLayout.SortOrder = Enum.SortOrder.LayoutOrder
			stLayout.Padding = UDim.new(0, 6)
			stLayout.Parent = shipTouchRow

			shipUpBtn = makeTouchActionBtn(
				shipTouchRow, "ShipUpBtn", pickLang("NÂNG", "UP"), 88,
				Color3.fromRGB(16, 44, 76), Color3.fromRGB(92, 224, 255), 1
			)
			shipDownBtn = makeTouchActionBtn(
				shipTouchRow, "ShipDownBtn", pickLang("HẠ", "DOWN"), 88,
				Color3.fromRGB(16, 34, 62), Color3.fromRGB(122, 194, 255), 2
			)
			shipFireBtn = makeTouchActionBtn(
				shipTouchRow, "ShipFireBtn", pickLang("PHÁO", "FIRE"), 96,
				Color3.fromRGB(192, 40, 70), Color3.fromRGB(255, 214, 108), 3
			)

			shipUpBtn.InputBegan:Connect(function(input)
				if isPointerHoldInput(input) then
					mobileShipUpHeld = true
					mobileShipUpInput = input
				end
			end)
			shipUpBtn.InputEnded:Connect(function(input)
				if input == mobileShipUpInput or isPointerHoldInput(input) then
					mobileShipUpHeld = false
					mobileShipUpInput = nil
				end
			end)
			shipDownBtn.InputBegan:Connect(function(input)
				if isPointerHoldInput(input) then
					mobileShipDownHeld = true
					mobileShipDownInput = input
				end
			end)
			shipDownBtn.InputEnded:Connect(function(input)
				if input == mobileShipDownInput or isPointerHoldInput(input) then
					mobileShipDownHeld = false
					mobileShipDownInput = nil
				end
			end)
			shipFireBtn.Activated:Connect(function()
				if UI and UI.BlocksCombat and UI.BlocksCombat() then return end
				CombatExt.FireSeatedShipCannon()
			end)

			-- Mobile 3D Flight Altitude Touch Pill (visible ONLY on Mobile while SkybreakFlightActive == true)
			mobileFlightPill = Instance.new("Frame")
			mobileFlightPill.Name = "MobileFlightAltitudePill"
			mobileFlightPill.AnchorPoint = Vector2.new(0.5, 1)
			mobileFlightPill.Position = UDim2.new(0.5, 0, 1, -114)
			mobileFlightPill.Size = UDim2.fromOffset(224, 36)
			mobileFlightPill.BackgroundColor3 = Color3.fromRGB(9, 15, 28)
			mobileFlightPill.BackgroundTransparency = 0.06
			mobileFlightPill.BorderSizePixel = 0
			mobileFlightPill.Visible = false
			mobileFlightPill.Parent = stackGui

			mobileFlightScale = Instance.new("UIScale")
			mobileFlightScale.Name = "MobileSafeScale"
			mobileFlightScale.Scale = 1.0
			mobileFlightScale.Parent = mobileFlightPill

			local mfCorner = Instance.new("UICorner")
			mfCorner.CornerRadius = UDim.new(1, 0)
			mfCorner.Parent = mobileFlightPill
			local mfStroke = Instance.new("UIStroke")
			mfStroke.Color = Color3.fromRGB(92, 224, 255)
			mfStroke.Thickness = 1.5
			mfStroke.Parent = mobileFlightPill

			local mfLayout = Instance.new("UIListLayout")
			mfLayout.FillDirection = Enum.FillDirection.Horizontal
			mfLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			mfLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			mfLayout.SortOrder = Enum.SortOrder.LayoutOrder
			mfLayout.Padding = UDim.new(0, 6)
			mfLayout.Parent = mobileFlightPill

			flightUpBtn = makeTouchActionBtn(
				mobileFlightPill, "FlightUpBtn", pickLang("BAY LÊN", "UP"), 102,
				Color3.fromRGB(16, 48, 82), Color3.fromRGB(92, 228, 255), 1
			)
			flightDownBtn = makeTouchActionBtn(
				mobileFlightPill, "FlightDownBtn", pickLang("HẠ XUỐNG", "DOWN"), 102,
				Color3.fromRGB(18, 34, 62), Color3.fromRGB(252, 208, 92), 2
			)

			flightUpBtn.InputBegan:Connect(function(input)
				if isPointerHoldInput(input) then
					mobileFlightUpHeld = true
					mobileFlightUpInput = input
				end
			end)
			flightUpBtn.InputEnded:Connect(function(input)
				if input == mobileFlightUpInput or isPointerHoldInput(input) then
					mobileFlightUpHeld = false
					mobileFlightUpInput = nil
				end
			end)
			flightDownBtn.InputBegan:Connect(function(input)
				if isPointerHoldInput(input) then
					mobileFlightDownHeld = true
					mobileFlightDownInput = input
				end
			end)
			flightDownBtn.InputEnded:Connect(function(input)
				if input == mobileFlightDownInput or isPointerHoldInput(input) then
					mobileFlightDownHeld = false
					mobileFlightDownInput = nil
				end
			end)

			container = Instance.new("Frame")
			container.Name = "BottomRightSkillStack"
			container.AnchorPoint = Vector2.new(1, 1)
			container.Position = UDim2.new(1, -16, 1, -14)
			container.Size = UDim2.fromOffset(312, 266)
			container.BackgroundTransparency = 1
			container.Parent = stackGui

			containerScale = Instance.new("UIScale")
			containerScale.Name = "ResponsiveStackScale"
			containerScale.Scale = 1.0
			containerScale.Parent = container

			containerLayout = Instance.new("UIListLayout")
			containerLayout.FillDirection = Enum.FillDirection.Vertical
			containerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
			containerLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
			containerLayout.SortOrder = Enum.SortOrder.LayoutOrder
			containerLayout.Padding = UDim.new(0, 5)
			containerLayout.Parent = container

			-- Compact Secondary Utility Strip (LayoutOrder = -1):
			-- Class Ult [R], Ascend [Y], Armor [J], Sense [U], Sov. [H], Dash [Q], Heal [`]
			utilRow = Instance.new("Frame")
			utilRow.Name = "SecondaryUtilityStrip"
			utilRow.Size = UDim2.fromOffset(312, 28)
			utilRow.BackgroundTransparency = 1
			utilRow.LayoutOrder = -1
			utilRow.Parent = container

			utilLayout = Instance.new("UIListLayout")
			utilLayout.FillDirection = Enum.FillDirection.Horizontal
			utilLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
			utilLayout.VerticalAlignment = Enum.VerticalAlignment.Center
			utilLayout.SortOrder = Enum.SortOrder.LayoutOrder
			utilLayout.Padding = UDim.new(0, 4)
			utilLayout.Parent = utilRow

			table.clear(utilRefs)
			for uIdx, ud in ipairs(UTIL_DEFS) do
				local uBtn = Instance.new("TextButton")
				uBtn.Name = "UtilPill_" .. ud.Id
				uBtn.Size = UDim2.fromOffset(41, 26)
				uBtn.BackgroundColor3 = Color3.fromRGB(12, 18, 32)
				uBtn.BackgroundTransparency = 0.06
				uBtn.BorderSizePixel = 0
				uBtn.Text = ""
				uBtn.AutoButtonColor = false
				uBtn.ClipsDescendants = true
				uBtn.LayoutOrder = uIdx
				uBtn.Parent = utilRow

				local uc = Instance.new("UICorner")
				uc.CornerRadius = UDim.new(0, 6)
				uc.Parent = uBtn

				local us = Instance.new("UIStroke")
				us.Color = ud.Accent
				us.Thickness = 1.2
				us.Transparency = 0.25
				us.Parent = uBtn

				local cdSweep = Instance.new("Frame")
				cdSweep.Name = "CDSweep"
				cdSweep.AnchorPoint = Vector2.new(0, 1)
				cdSweep.Position = UDim2.fromScale(0, 1)
				cdSweep.Size = UDim2.fromScale(1, 0)
				cdSweep.BackgroundColor3 = Color3.fromRGB(238, 64, 88)
				cdSweep.BackgroundTransparency = 0.35
				cdSweep.BorderSizePixel = 0
				cdSweep.ZIndex = 2
				cdSweep.Parent = uBtn

				local kTop = Instance.new("TextLabel")
				kTop.Name = "KeyText"
				kTop.Position = UDim2.fromOffset(0, 1)
				kTop.Size = UDim2.new(1, 0, 0, 12)
				kTop.BackgroundTransparency = 1
				kTop.Font = Enum.Font.GothamBlack
				kTop.TextSize = 9
				kTop.TextColor3 = ud.Accent
				kTop.Text = "[" .. ud.Key .. "]"
				kTop.ZIndex = 4
				kTop.Parent = uBtn

				local capBot = Instance.new("TextLabel")
				capBot.Name = "CapText"
				capBot.Position = UDim2.fromOffset(1, 12)
				capBot.Size = UDim2.new(1, -2, 0, 13)
				capBot.BackgroundTransparency = 1
				capBot.Font = Enum.Font.GothamBold
				capBot.TextSize = 8
				capBot.TextColor3 = Color3.fromRGB(234, 242, 255)
				capBot.TextTruncate = Enum.TextTruncate.AtEnd
				capBot.Text = pickLang(ud.LabelVi, ud.LabelEn)
				capBot.ZIndex = 4
				capBot.Parent = uBtn

				uBtn.Activated:Connect(function()
					if UI and UI.BlocksCombat and UI.BlocksCombat() then return end
					if ud.Id == "ActivateRaceV4" and player and player.Character then
						pcall(function()
							player.Character:SetAttribute("NativeRaceV4Toggled", true)
						end)
					end
					if ctx and ctx.Send then
						ctx.Send(ud.Id)
					end
				end)

				utilRefs[ud.Id] = {
					Def = ud,
					Button = uBtn,
					Stroke = us,
					CDSweep = cdSweep,
					KeyLabel = kTop,
					CapLabel = capBot,
				}
			end

			-- Header Card: Equipped Fruit / Weapon Name + Mastery Bar (LayoutOrder = 0)
			headerCard = Instance.new("Frame")
			headerCard.Name = "MasteryHeaderCard"
			headerCard.Size = UDim2.fromOffset(312, 40)
			headerCard.BackgroundColor3 = Color3.fromRGB(11, 16, 28)
			headerCard.BackgroundTransparency = 0.06
			headerCard.BorderSizePixel = 0
			headerCard.LayoutOrder = 0
			headerCard.Parent = container

			local hCorner = Instance.new("UICorner")
			hCorner.CornerRadius = UDim.new(0, 8)
			hCorner.Parent = headerCard

			headerStroke = Instance.new("UIStroke")
			headerStroke.Color = Color3.fromRGB(252, 208, 92)
			headerStroke.Thickness = 1.6
			headerStroke.Transparency = 0.08
			headerStroke.Parent = headerCard

			headerTitle = Instance.new("TextLabel")
			headerTitle.Name = "WeaponTitle"
			headerTitle.Position = UDim2.fromOffset(10, 3)
			headerTitle.Size = UDim2.new(1, -110, 0, 18)
			headerTitle.BackgroundTransparency = 1
			headerTitle.Font = Enum.Font.GothamBlack
			headerTitle.TextSize = 12
			headerTitle.TextColor3 = Color3.fromRGB(255, 246, 214)
			headerTitle.TextXAlignment = Enum.TextXAlignment.Left
			headerTitle.TextTruncate = Enum.TextTruncate.AtEnd
			headerTitle.Text = pickLang("Lõi Aether", "Aether Core")
			headerTitle.Parent = headerCard

			headerMasText = Instance.new("TextLabel")
			headerMasText.Name = "MasteryLevelText"
			headerMasText.AnchorPoint = Vector2.new(1, 0)
			headerMasText.Position = UDim2.new(1, -10, 0, 3)
			headerMasText.Size = UDim2.fromOffset(96, 18)
			headerMasText.BackgroundTransparency = 1
			headerMasText.Font = Enum.Font.GothamBold
			headerMasText.TextSize = 11
			headerMasText.TextColor3 = Color3.fromRGB(255, 218, 108)
			headerMasText.TextXAlignment = Enum.TextXAlignment.Right
			headerMasText.Text = "Mastery 1"
			headerMasText.Parent = headerCard

			local barBg = Instance.new("Frame")
			barBg.Name = "MasteryBarBg"
			barBg.Position = UDim2.fromOffset(10, 25)
			barBg.Size = UDim2.new(1, -20, 0, 8)
			barBg.BackgroundColor3 = Color3.fromRGB(22, 30, 48)
			barBg.BorderSizePixel = 0
			barBg.Parent = headerCard
			local barCorner = Instance.new("UICorner")
			barCorner.CornerRadius = UDim.new(1, 0)
			barCorner.Parent = barBg

			headerMasFill = Instance.new("Frame")
			headerMasFill.Name = "MasteryBarFill"
			headerMasFill.Size = UDim2.fromScale(0.35, 1)
			headerMasFill.BackgroundColor3 = Color3.fromRGB(252, 208, 92)
			headerMasFill.BorderSizePixel = 0
			headerMasFill.Parent = barBg
			local fillCorner = Instance.new("UICorner")
			fillCorner.CornerRadius = UDim.new(1, 0)
			fillCorner.Parent = headerMasFill

			table.clear(rowRefs)
			for idx, k in ipairs(KEY_ORDER) do
				local rowBtn = Instance.new("TextButton")
				rowBtn.Name = "BloxSkillRow_" .. k
				rowBtn.Size = UDim2.fromOffset(312, 33)
				rowBtn.BackgroundColor3 = Color3.fromRGB(14, 20, 34)
				rowBtn.BackgroundTransparency = 0.06
				rowBtn.BorderSizePixel = 0
				rowBtn.Text = ""
				rowBtn.AutoButtonColor = false
				rowBtn.ClipsDescendants = true
				rowBtn.LayoutOrder = idx
				rowBtn.Parent = container

				local rCorner = Instance.new("UICorner")
				rCorner.CornerRadius = UDim.new(0, 7)
				rCorner.Parent = rowBtn

				local rStroke = Instance.new("UIStroke")
				rStroke.Color = Color3.fromRGB(88, 118, 168)
				rStroke.Thickness = 1.4
				rStroke.Transparency = 0.14
				rStroke.Parent = rowBtn

				local cdFill = Instance.new("Frame")
				cdFill.Name = "CooldownFill"
				cdFill.Size = UDim2.fromScale(0, 1)
				cdFill.Position = UDim2.fromScale(0, 0)
				cdFill.BackgroundColor3 = Color3.fromRGB(238, 64, 88)
				cdFill.BackgroundTransparency = 0.32
				cdFill.BorderSizePixel = 0
				cdFill.ZIndex = 2
				cdFill.Parent = rowBtn

				local keyBadge = Instance.new("Frame")
				keyBadge.Name = "KeyBadge"
				keyBadge.AnchorPoint = Vector2.new(0, 0.5)
				keyBadge.Position = UDim2.new(0, 5, 0.5, 0)
				keyBadge.Size = UDim2.fromOffset(28, 24)
				keyBadge.BackgroundColor3 = Color3.fromRGB(218, 152, 28)
				keyBadge.BorderSizePixel = 0
				keyBadge.ZIndex = 4
				keyBadge.Parent = rowBtn
				local kbCorner = Instance.new("UICorner")
				kbCorner.CornerRadius = UDim.new(0, 5)
				kbCorner.Parent = keyBadge

				local keyLbl = Instance.new("TextLabel")
				keyLbl.Size = UDim2.fromScale(1, 1)
				keyLbl.BackgroundTransparency = 1
				keyLbl.Font = Enum.Font.GothamBlack
				keyLbl.TextSize = 13
				keyLbl.TextColor3 = Color3.fromRGB(255, 255, 255)
				keyLbl.TextStrokeTransparency = 0.25
				keyLbl.Text = k
				keyLbl.ZIndex = 5
				keyLbl.Parent = keyBadge

				local skillNameLbl = Instance.new("TextLabel")
				skillNameLbl.Name = "SkillName"
				skillNameLbl.Position = UDim2.fromOffset(40, 0)
				skillNameLbl.Size = UDim2.new(1, -124, 1, 0)
				skillNameLbl.BackgroundTransparency = 1
				skillNameLbl.Font = Enum.Font.GothamBold
				skillNameLbl.TextSize = 12
				skillNameLbl.TextColor3 = Color3.fromRGB(244, 248, 255)
				skillNameLbl.TextStrokeTransparency = 0.35
				skillNameLbl.TextXAlignment = Enum.TextXAlignment.Left
				skillNameLbl.TextTruncate = Enum.TextTruncate.AtEnd
				skillNameLbl.Text = pickLang("Kỹ Năng [" .. k .. "]", "Skill [" .. k .. "]")
				skillNameLbl.ZIndex = 4
				skillNameLbl.Parent = rowBtn

				local masBadge = Instance.new("Frame")
				masBadge.Name = "MasteryBadge"
				masBadge.AnchorPoint = Vector2.new(1, 0.5)
				masBadge.Position = UDim2.new(1, -6, 0.5, 0)
				masBadge.Size = UDim2.fromOffset(74, 21)
				masBadge.BackgroundColor3 = Color3.fromRGB(18, 28, 46)
				masBadge.BorderSizePixel = 0
				masBadge.ZIndex = 4
				masBadge.Parent = rowBtn
				local mbCorner = Instance.new("UICorner")
				mbCorner.CornerRadius = UDim.new(0, 5)
				mbCorner.Parent = masBadge

				local masLbl = Instance.new("TextLabel")
				masLbl.Name = "MasText"
				masLbl.Size = UDim2.fromScale(1, 1)
				masLbl.BackgroundTransparency = 1
				masLbl.Font = Enum.Font.GothamBold
				masLbl.TextSize = 10
				masLbl.TextColor3 = Color3.fromRGB(255, 218, 108)
				masLbl.Text = "Mas. 1"
				masLbl.ZIndex = 5
				masLbl.Parent = masBadge

				rowBtn.Activated:Connect(function()
					if UI and UI.BlocksCombat and UI.BlocksCombat() then return end
					if k == "F" and ctx and ctx.IsCurrentSlotTrueFlightF and ctx.IsCurrentSlotTrueFlightF() then
						if ctx.HasUnlockedFruitFMastery and ctx.HasUnlockedFruitFMastery() and player.Character then
							player.Character:SetAttribute("LastClientSkillKey", "F")
							player.Character:SetAttribute("LastClientSkillAt", os.clock())
						end
						local tog = player:FindFirstChild("SkybreakToggleFlight")
						if tog and tog:IsA("BindableEvent") then
							tog:Fire()
						end
					elseif ctx and ctx.FireSlotMove then
						ctx.FireSlotMove(k)
					end
				end)

				rowRefs[k] = {
					Button = rowBtn,
					Stroke = rStroke,
					CDFill = cdFill,
					KeyBadge = keyBadge,
					KeyLabel = keyLbl,
					NameLabel = skillNameLbl,
					MasBadge = masBadge,
					MasLabel = masLbl,
				}
			end
			return stackGui
		end

		local function alignLoadoutHotbarZeroOverlap(skyUI, isMobileTouch)
			if not skyUI then return end
			local loadout1To4 = skyUI:FindFirstChild("LoadoutHotbar1To4", true)
			if not loadout1To4 or not loadout1To4:IsA("GuiObject") then return end
			local quickDock = skyUI:FindFirstChild("QuickNavDock", true)
			local rootFrame = loadout1To4.Parent
			if not rootFrame or not rootFrame:IsA("GuiObject") then return end

			local lScale = loadout1To4:FindFirstChild("ZeroOverlapScale")
			if not lScale then
				lScale = Instance.new("UIScale")
				lScale.Name = "ZeroOverlapScale"
				lScale.Parent = loadout1To4
			end

			local rootScale = 1
			local pScale = rootFrame:FindFirstChildOfClass("UIScale")
			if pScale and pScale.Scale > 0.1 then
				rootScale = pScale.Scale
			end

			local parentW = rootFrame.AbsoluteSize.X
			if parentW < 300 then
				local cam = Workspace.CurrentCamera
				parentW = ((cam and cam.ViewportSize.X) or 1366) / rootScale
			end

			local baseW = loadout1To4.Size.X.Offset
			if baseW <= 0 then baseW = isMobileTouch and 330 or 616 end

			if isMobileTouch then
				-- On Mobile: SecondaryUtilityStrip sits at center (0.5, 0, 1, -78), so place LoadoutHotbar1To4
				-- in the bottom-center lane (y = -14) between QuickNavDock/Thumbstick and MobileTouchArc/JumpButton!
				local leftLimit = math.ceil(156 / rootScale)
				if quickDock and quickDock:IsA("GuiObject") and quickDock.Visible then
					local qRight = quickDock.Position.X.Offset + quickDock.Size.X.Offset
					leftLimit = math.max(leftLimit, qRight + 8)
				end
				local rightLimit = parentW - math.ceil(156 / rootScale)
				local touchArc = skyUI:FindFirstChild("MobileTouchArc", true)
				if touchArc and touchArc:IsA("GuiObject") and touchArc.Visible then
					local arcLeftLocal = (touchArc.AbsolutePosition.X - rootFrame.AbsolutePosition.X) / rootScale
					if arcLeftLocal > 120 then
						rightLimit = math.min(rightLimit, arcLeftLocal - 8)
					end
				end
				local availMobileW = rightLimit - leftLimit
				if availMobileW >= 180 then
					lScale.Scale = math.clamp((availMobileW - 4) / baseW, 0.58, 0.96)
					local centerLocalX = math.floor((leftLimit + rightLimit) * 0.5)
					loadout1To4.AnchorPoint = Vector2.new(0.5, 1)
					loadout1To4.Position = UDim2.new(0, centerLocalX, 1, -14)
				else
					lScale.Scale = 0.64
					loadout1To4.AnchorPoint = Vector2.new(0.5, 1)
					loadout1To4.Position = UDim2.new(0.5, 0, 1, -14)
				end
				return
			end

			-- On Desktop (including 1366x768!): fit strictly in the lane between QuickNavDock.Right + 12px and BottomRightSkillStack.Left - 12px!
			local leftEdge = 470
			if quickDock and quickDock:IsA("GuiObject") and quickDock.Visible then
				local qRight = quickDock.Position.X.Offset + quickDock.Size.X.Offset
				leftEdge = math.max(leftEdge, qRight + 12)
			end
			local rightStackLocalW = math.ceil(336 / rootScale)
			local rightEdge = parentW - rightStackLocalW
			local availW = rightEdge - leftEdge

			if availW >= 420 then
				local fitScale = math.clamp((availW - 6) / baseW, 0.70, 1.0)
				lScale.Scale = fitScale
				local centerLocalX = math.floor((leftEdge + rightEdge) * 0.5)
				loadout1To4.AnchorPoint = Vector2.new(0.5, 1)
				loadout1To4.Position = UDim2.new(0, centerLocalX, 1, -14)
			else
				local topAvailW = math.max(260, rightEdge - 16)
				lScale.Scale = math.clamp((topAvailW - 6) / baseW, 0.68, 1.0)
				loadout1To4.AnchorPoint = Vector2.new(0, 1)
				loadout1To4.Position = UDim2.new(0, 12, 1, -74)
			end
		end

		local function stepShipPilotControls(now, hudBlocked, isMobileNow, skyUI)
			local seated, isPilot, _, seat = CombatExt.IsSeatedInSkyShip()
			local photoOn = player and player:GetAttribute("SkybreakPhotoMode") == true
			local showShipHud = seated and not hudBlocked and not photoOn

			if not showShipHud or not isPilot then
				mobileShipUpHeld = false
				mobileShipDownHeld = false
				mobileShipUpInput = nil
				mobileShipDownInput = nil
			end

			if shipPilotPill then
				shipPilotPill.Visible = showShipHud
				if showShipHud then
					if isMobileNow then
						local pillW = isPilot and 296 or 116
						shipPilotPill.Position = UDim2.new(0.5, 0, 1, -114)
						shipPilotPill.Size = UDim2.fromOffset(pillW, 36)
						if shipPilotScale then
							shipPilotScale.Scale = computeMobileCenterSafeScale(pillW, skyUI)
						end
						if shipPilotLabel then shipPilotLabel.Visible = false end
						if shipTouchRow then shipTouchRow.Visible = true end
						if shipUpBtn then
							shipUpBtn.Visible = isPilot
							shipUpBtn.Text = pickLang("NÂNG", "UP")
							shipUpBtn.BackgroundColor3 = mobileShipUpHeld and Color3.fromRGB(36, 98, 158) or Color3.fromRGB(16, 44, 76)
						end
						if shipDownBtn then
							shipDownBtn.Visible = isPilot
							shipDownBtn.Text = pickLang("HẠ", "DOWN")
							shipDownBtn.BackgroundColor3 = mobileShipDownHeld and Color3.fromRGB(36, 82, 138) or Color3.fromRGB(16, 34, 62)
						end
						if shipFireBtn then
							shipFireBtn.Visible = true
							shipFireBtn.Text = pickLang("PHÁO", "FIRE")
						end
					else
						shipPilotPill.Position = UDim2.new(0.5, 0, 1, -60)
						shipPilotPill.Size = UDim2.fromOffset(556, 30)
						if shipPilotScale then shipPilotScale.Scale = 1.0 end
						if shipTouchRow then shipTouchRow.Visible = false end
						if shipPilotLabel then
							shipPilotLabel.Visible = true
							shipPilotLabel.Text = isPilot
								and pickLang(
									"[WASD] Lái Tàu  •  [R / C] Nâng / Hạ Độ Cao  •  [Click] Bắn Pháo  •  [Space] Rời Tàu",
									"[WASD] Steer Ship  •  [R / C] Altitude Up / Down  •  [Click] Fire Cannons  •  [Space] Exit"
								)
								or pickLang(
									"THỦY THỦ ĐOÀN  •  [Click] Khai Hỏa Đại Bác Mạn Tàu  •  [Space] Rời Tàu",
									"SHIP CREW  •  [Click] Fire Broadside Cannons  •  [Space] Exit"
								)
						end
					end
				end
			end

			local wantDir = 0
			if seated and isPilot and not hudBlocked then
				local keyAllowed = not UserInputService:GetFocusedTextBox()
				local upHeld = mobileShipUpHeld or (keyAllowed and UserInputService:IsKeyDown(Enum.KeyCode.R))
				local downHeld = mobileShipDownHeld or (keyAllowed and UserInputService:IsKeyDown(Enum.KeyCode.C))
				if upHeld and not downHeld then
					wantDir = 1
				elseif downHeld and not upHeld then
					wantDir = -1
				end
			end

			if seat then
				pcall(function()
					seat:SetAttribute("VerticalInput", wantDir)
				end)
			end

			if wantDir ~= lastSentShipDir or (wantDir ~= 0 and (now - lastSentShipAt) >= 0.22) then
				lastSentShipDir = wantDir
				lastSentShipAt = now
				if remotes and remotes:FindFirstChild("AbilityRequest") then
					remotes.AbilityRequest:FireServer({
						Action = "ShipAltitude",
						action = "ShipAltitude",
						skillId = "ShipAltitude",
						Dir = wantDir,
						dir = wantDir,
						verticalDir = wantDir,
					})
				end
			end

			return seated
		end

		local function stepMobileFlightControls(hudBlocked, isMobileNow, seatedInShip, skyUI)
			local ch = player and player.Character
			local photoOn = player and player:GetAttribute("SkybreakPhotoMode") == true
			if ch and ch:GetAttribute("SkybreakFlightActive") == true and player and player:GetAttribute("SkybreakFlightActive") == false then
				ch:SetAttribute("SkybreakFlightActive", false)
			end
			local charFlying = (ch ~= nil and ch:GetAttribute("SkybreakFlightActive") == true)
			local showFlightHud = isMobileNow and charFlying and not hudBlocked and not photoOn and not seatedInShip

			if not showFlightHud then
				mobileFlightUpHeld = false
				mobileFlightDownHeld = false
				mobileFlightUpInput = nil
				mobileFlightDownInput = nil
				if mobileFlightPill then
					mobileFlightPill.Visible = false
				end
				if ch and ch:GetAttribute("MobileFlightVertical") ~= nil and ch:GetAttribute("MobileFlightVertical") ~= 0 then
					ch:SetAttribute("MobileFlightVertical", 0)
				end
				if player and player:GetAttribute("MobileFlightVertical") ~= nil and player:GetAttribute("MobileFlightVertical") ~= 0 then
					player:SetAttribute("MobileFlightVertical", 0)
				end
				return
			end

			if mobileFlightPill then
				local interactPrompt = skyUI and skyUI:FindFirstChild("ContextInteractPrompt", true)
				local shiftUp = (interactPrompt and interactPrompt:IsA("GuiObject") and interactPrompt.Visible) and -152 or -114
				mobileFlightPill.Position = UDim2.new(0.5, 0, 1, shiftUp)
				if mobileFlightScale then
					mobileFlightScale.Scale = computeMobileCenterSafeScale(224, skyUI)
				end
				mobileFlightPill.Visible = true
			end
			if flightUpBtn then
				flightUpBtn.Text = pickLang("BAY LÊN", "UP")
				flightUpBtn.BackgroundColor3 = mobileFlightUpHeld and Color3.fromRGB(34, 102, 168) or Color3.fromRGB(16, 48, 82)
			end
			if flightDownBtn then
				flightDownBtn.Text = pickLang("HẠ XUỐNG", "DOWN")
				flightDownBtn.BackgroundColor3 = mobileFlightDownHeld and Color3.fromRGB(84, 68, 28) or Color3.fromRGB(18, 34, 62)
			end

			local fDir = 0
			if mobileFlightUpHeld and not mobileFlightDownHeld then
				fDir = 1
			elseif mobileFlightDownHeld and not mobileFlightUpHeld then
				fDir = -1
			end

			if ch:GetAttribute("MobileFlightVertical") ~= fDir then
				ch:SetAttribute("MobileFlightVertical", fDir)
			end
			if player and player:GetAttribute("MobileFlightVertical") ~= fDir then
				player:SetAttribute("MobileFlightVertical", fDir)
			end
		end

		local function stepUtilityStrip(now, isMobileNow)
			local ch = player and player.Character
			local nowSrv = Workspace:GetServerTimeNow()
			local st = latestSyncedState or (UI and UI.State) or {}
			local pLv = tonumber(st.Level or (player and player:GetAttribute("Level"))) or 1

			local auraOn = (ch and ch:GetAttribute("HakiAura") == true)
				or (player and (player:GetAttribute("HakiAura") == true or player:GetAttribute("AuraActive") == true))
			local kenOn = (ch and ch:GetAttribute("HakiInstinct") == true)
				or (player and (player:GetAttribute("HakiInstinct") == true or player:GetAttribute("InstinctActive") == true))
			local conqEnd = tonumber((ch and ch:GetAttribute("ConquerorActiveUntil")) or (player and player:GetAttribute("ConquerorActiveUntil"))) or 0
			local conqActive = (conqEnd - nowSrv) > 0.2
			local v4End = tonumber((ch and ch:GetAttribute("RaceV4ActiveUntil")) or (player and player:GetAttribute("RaceV4ActiveUntil"))) or 0
			local v4Race = tostring((ch and ch:GetAttribute("RaceV4")) or (player and player:GetAttribute("RaceV4")) or "")
			local v4On = (v4Race ~= "" and v4Race ~= "None")
				or (ch and ch:GetAttribute("RaceV4Active") == true)
				or (player and player:GetAttribute("RaceV4Active") == true)
				or ((v4End - nowSrv) > 0.3)

			local potions = tonumber(st.Potions or (st.Inventory and st.Inventory.HealthPotion) or (player and player:GetAttribute("Potions")))

			for id, ref in pairs(utilRefs) do
				local cdEntry = utilityCooldowns[id]
				local rem = (cdEntry and cdEntry.End and (cdEntry.End - now)) or 0
				local dur = math.max(0.1, (cdEntry and cdEntry.Duration) or 1)
				local isOn = (id == "ToggleAura" and auraOn)
					or (id == "ToggleInstinct" and kenOn)
					or (id == "ConquerorBurst" and conqActive)
					or (id == "ActivateRaceV4" and v4On)
				local isLocked = (id == "Ultimate" and pLv < 20)

				if id == "UsePotion" and potions ~= nil then
					local cnt = math.max(0, math.floor(potions))
					ref.KeyLabel.Text = isMobileNow and ("x" .. tostring(cnt)) or ("[`] x" .. tostring(cnt))
				else
					ref.KeyLabel.Text = "[" .. ref.Def.Key .. "]"
				end

				if isLocked then
					ref.Button.BackgroundColor3 = Color3.fromRGB(20, 16, 22)
					ref.Stroke.Color = Color3.fromRGB(98, 64, 76)
					ref.Stroke.Thickness = 1.1
					ref.Stroke.Transparency = 0.35
					ref.CDSweep.Size = UDim2.fromScale(1, 0)
					ref.CapLabel.Text = "Lv.20"
					ref.CapLabel.TextColor3 = Color3.fromRGB(156, 144, 164)
				elseif isOn then
					ref.Button.BackgroundColor3 = Color3.fromRGB(28, 34, 20)
					ref.Stroke.Color = Color3.fromRGB(255, 226, 108)
					ref.Stroke.Thickness = 1.8
					ref.Stroke.Transparency = 0.0
					ref.CDSweep.Size = UDim2.fromScale(1, 0)
					ref.CapLabel.Text = pickLang("BẬT", "ON")
					ref.CapLabel.TextColor3 = Color3.fromRGB(255, 238, 148)
				elseif rem > 0.05 then
					ref.Button.BackgroundColor3 = Color3.fromRGB(16, 14, 24)
					ref.Stroke.Color = Color3.fromRGB(238, 68, 92)
					ref.Stroke.Thickness = 1.2
					ref.Stroke.Transparency = 0.15
					ref.CDSweep.Size = UDim2.fromScale(1, math.clamp(rem / dur, 0, 1))
					ref.CapLabel.Text = (rem >= 10) and string.format("%ds", math.ceil(rem)) or string.format("%.1fs", rem)
					ref.CapLabel.TextColor3 = Color3.fromRGB(255, 214, 222)
				else
					ref.Button.BackgroundColor3 = Color3.fromRGB(12, 18, 32)
					ref.Stroke.Color = ref.Def.Accent
					ref.Stroke.Thickness = 1.2
					ref.Stroke.Transparency = 0.22
					ref.CDSweep.Size = UDim2.fromScale(1, 0)
					ref.CapLabel.Text = pickLang(ref.Def.LabelVi, ref.Def.LabelEn)
					ref.CapLabel.TextColor3 = Color3.fromRGB(234, 242, 255)
				end
			end
		end

		local function stepBloxFruitsSkillHUD()
			if not stackGui or not stackGui.Parent then
				if not buildBloxFruitsSkillHUD() then return end
			end

			local now = os.clock()
			local hudBlocked = (UI and UI.BlocksCombat and UI.BlocksCombat()) == true
			local pgui = player and player:FindFirstChild("PlayerGui")
			local skyUI = pgui and pgui:FindFirstChild("SkybreakUI")
			local isMobileNow = isTouchMobile()

			local seatedInShip = stepShipPilotControls(now, hudBlocked, isMobileNow, skyUI)
			stepMobileFlightControls(hudBlocked, isMobileNow, seatedInShip, skyUI)
			stepWaypointBeam(now)

			if skyUI then
				ensureMobileHeavyButton(skyUI)
				alignLoadoutHotbarZeroOverlap(skyUI, isMobileNow)
			end

			stackGui.Enabled = true
			local photoOn = player and player:GetAttribute("SkybreakPhotoMode") == true
			local hudVisible = not hudBlocked and not photoOn
			container.Visible = hudVisible
			if not hudVisible then return end

			if isMobileNow then
				-- Mobile Mode: hide 5-row desktop vertical skill stack + MasteryHeaderCard, relocate SecondaryUtilityStrip
				-- to a compact mobile-safe horizontal pill bar (AnchorPoint = 0.5, 1, Position = 0.5, 0, 1, -78)
				if headerCard then headerCard.Visible = false end
				for _, k in ipairs(KEY_ORDER) do
					local ref = rowRefs[k]
					if ref then ref.Button.Visible = false end
				end
				container.AnchorPoint = Vector2.new(0.5, 1)
				container.Position = UDim2.new(0.5, 0, 1, -78)
				container.Size = UDim2.fromOffset(312, 28)
				if containerScale then
					containerScale.Scale = computeMobileCenterSafeScale(312, skyUI)
				end
				if containerLayout then
					containerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
				end
				if utilLayout then
					utilLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
				end
				stepUtilityStrip(now, true)
				return
			end

			-- Desktop Mode: restore full bottom-right skill stack + MasteryHeaderCard + SecondaryUtilityStrip
			if skyUI then
				local oldHotbar = skyUI:FindFirstChild("AbilityHotbar", true)
				if oldHotbar and oldHotbar:IsA("GuiObject") then
					oldHotbar.Visible = false
				end
			end

			container.AnchorPoint = Vector2.new(1, 1)
			container.Position = UDim2.new(1, -16, 1, -14)
			container.Size = UDim2.fromOffset(312, 266)
			if containerScale then
				containerScale.Scale = 1.0
			end
			if containerLayout then
				containerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
			end
			if utilLayout then
				utilLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
			end
			if headerCard then
				headerCard.Visible = true
			end

			stepUtilityStrip(now, false)

			local curSlot, itemId, headerName, element, curMas, moves = CombatExt.ResolveActiveCombatLoadout()
			local pal = ELEMENT_HUD_PALETTES[tostring(element)] or ELEMENT_HUD_PALETTES.Sky

			headerStroke.Color = pal.Accent
			headerTitle.Text = (headerName and tostring(headerName) ~= "") and tostring(headerName) or pickLang("Lõi Aether", "Aether Core")
			headerMasText.Text = string.format("Mastery %d", math.floor(curMas))
			headerMasText.TextColor3 = pal.Accent
			headerMasFill.BackgroundColor3 = pal.Accent
			local masProgress = math.clamp((curMas % 100) / 100, 0.08, 1.0)
			if curMas >= 600 then masProgress = 1.0 end
			headerMasFill.Size = UDim2.fromScale(masProgress, 1)

			local flyingNow = (player and player:GetAttribute("SkybreakFlightActive") == true)
				or (player and player.Character and player.Character:GetAttribute("SkybreakFlightActive") == true)

			for _, k in ipairs(KEY_ORDER) do
				local ref = rowRefs[k]
				local mv = moves and moves[k]
				if ref then
					if mv then
						ref.Button.Visible = true
						local cleanTitle = localizeBilingualText(mv.Name, "Kỹ Năng " .. k, "Skill " .. k)
						if k == "F" and flyingNow and ctx and ctx.IsCurrentSlotTrueFlightF and ctx.IsCurrentSlotTrueFlightF() then
							cleanTitle = pickLang("Hạ Cánh", "Land Flight")
						end
						ref.NameLabel.Text = cleanTitle

						local reqMas = tonumber(mv.Mastery) or 1
						local unlocked = (curMas >= reqMas)
						local cdId = tostring(curSlot) .. "_" .. tostring(itemId) .. "_" .. k
						local cdEntry = bloxSkillCooldowns[cdId]
						local rem = (cdEntry and cdEntry.End and (cdEntry.End - now)) or 0

						if not unlocked then
							ref.NameLabel.Size = UDim2.new(1, -146, 1, 0)
							ref.MasBadge.Size = UDim2.fromOffset(96, 21)
							ref.MasLabel.TextSize = 9
							ref.Button.BackgroundColor3 = Color3.fromRGB(22, 16, 22)
							ref.KeyBadge.BackgroundColor3 = Color3.fromRGB(64, 52, 62)
							ref.Stroke.Color = Color3.fromRGB(110, 62, 72)
							ref.NameLabel.TextColor3 = Color3.fromRGB(150, 142, 156)
							ref.CDFill.Size = UDim2.fromScale(0, 1)
							ref.MasBadge.BackgroundColor3 = Color3.fromRGB(68, 22, 32)
							ref.MasLabel.TextColor3 = Color3.fromRGB(255, 138, 148)
							ref.MasLabel.Text = string.format(pickLang("Mở ở Mas. %d", "Unlocks Mas. %d"), reqMas)
						elseif rem > 0.05 then
							ref.NameLabel.Size = UDim2.new(1, -124, 1, 0)
							ref.MasBadge.Size = UDim2.fromOffset(74, 21)
							ref.MasLabel.TextSize = 10
							local dur = math.max(0.1, tonumber(cdEntry.Duration) or tonumber(mv.Cooldown) or 6)
							local frac = math.clamp(rem / dur, 0, 1)
							ref.Button.BackgroundColor3 = pal.Dark
							ref.KeyBadge.BackgroundColor3 = Color3.fromRGB(84, 34, 48)
							ref.Stroke.Color = Color3.fromRGB(238, 68, 92)
							ref.NameLabel.TextColor3 = Color3.fromRGB(224, 214, 220)
							ref.CDFill.Size = UDim2.fromScale(frac, 1)
							ref.MasBadge.BackgroundColor3 = Color3.fromRGB(128, 26, 44)
							ref.MasLabel.TextColor3 = Color3.fromRGB(255, 228, 232)
							ref.MasLabel.Text = string.format("%.1fs", rem)
						else
							ref.NameLabel.Size = UDim2.new(1, -124, 1, 0)
							ref.MasBadge.Size = UDim2.fromOffset(74, 21)
							ref.MasLabel.TextSize = 10
							ref.Button.BackgroundColor3 = Color3.fromRGB(14, 20, 34)
							ref.KeyBadge.BackgroundColor3 = pal.Badge
							ref.Stroke.Color = pal.Accent
							ref.NameLabel.TextColor3 = Color3.fromRGB(248, 250, 255)
							ref.CDFill.Size = UDim2.fromScale(0, 1)
							ref.MasBadge.BackgroundColor3 = Color3.fromRGB(18, 28, 46)
							ref.MasLabel.TextColor3 = pal.Accent
							ref.MasLabel.Text = string.format("Mas. %d", reqMas)
						end
					else
						ref.Button.Visible = false
					end
				end
			end
		end

		local function refreshAllBilingualLabels()
			nextTargetScanAt = 0
			if mobileHeavyBtnRef and mobileHeavyBtnRef.Parent then
				mobileHeavyBtnRef.Text = pickLang("MẠNH", "HEAVY")
			end
			if shipUpBtn then shipUpBtn.Text = pickLang("NÂNG", "UP") end
			if shipDownBtn then shipDownBtn.Text = pickLang("HẠ", "DOWN") end
			if shipFireBtn then shipFireBtn.Text = pickLang("PHÁO", "FIRE") end
			if flightUpBtn then flightUpBtn.Text = pickLang("BAY LÊN", "UP") end
			if flightDownBtn then flightDownBtn.Text = pickLang("HẠ XUỐNG", "DOWN") end
			if headerTitle and (headerTitle.Text == "Lõi Aether" or headerTitle.Text == "Aether Core") then
				headerTitle.Text = pickLang("Lõi Aether", "Aether Core")
			end
			pcall(stepBloxFruitsSkillHUD)
		end

		buildBloxFruitsSkillHUD()
		if player then
			player:GetAttributeChangedSignal("Language"):Connect(refreshAllBilingualLabels)
			player:GetAttributeChangedSignal("ForceMobileUI"):Connect(function()
				pcall(stepBloxFruitsSkillHUD)
			end)
		end
		RunService.RenderStepped:Connect(function()
			pcall(stepBloxFruitsSkillHUD)
		end)
	end)
end

return CombatExt
