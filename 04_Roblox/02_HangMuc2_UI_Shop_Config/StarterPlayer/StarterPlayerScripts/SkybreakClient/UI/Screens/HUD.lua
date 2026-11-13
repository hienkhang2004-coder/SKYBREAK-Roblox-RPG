-- SKYBREAK: Fragments of the Core — Action-RPG Gameplay HUD Screen (1:1 Figma v2 Fidelity)
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/HUD.lua
-- Matches SKYBREAK_Figma_v2_01_ActionRPG_HUD.png 1:1:
--   * Top-Left Gold-Bracketed PlayerHUD (388x122) with Winged Live 3D Avatar Bust, * SKYGUARDIAN Pill & Glossy HP/AETHER/EXP Bars
--   * Always-Visible Currency & Haki Status Pills Row ([Gold], [Shards], [J] Haki • Ken) + Dynamic Active Buffs
--   * Middle-Left Collapsible QuestTracker with Golden Ribbon Header Banner ("NHẬT KÝ NHIỆM VỤ [L]")
--   * Top-Center BossHUD with Golden Crown Ribbon ("AUREON SENTINEL • LV. 150 | PHASE II")
--   * Top-Right 148x148 CelestialMinimap + Purple Aether Fruit Radar Pill + Gold Squad Pill Button [B]
--   * Right-Center Tilted -8 deg Gold Rank Square Combo Card ("34 COMBO HITS • +SÁT THƯƠNG AETHER")
--   * Bottom-Left Obsidian-Gold Quick Dock (9 tactile Icon-Over-Caption tiles with hotkey badges)
--   * Bottom-Center Action-RPG Combat Dock: 4 Loadout Pills (Glossy Champagne Gold active pill) + 8 Glossy Skill Cards flanking 45 deg Diamond Ultimate [R] + J/T Shoulder Mini-Orbs.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local WorldConfig = require(Shared:WaitForChild("Config"):WaitForChild("WorldConfig"))
local UIState = require(Shared:WaitForChild("Types"):WaitForChild("UIState"))
local UIAnimator = require(Shared:WaitForChild("UIAnimator"))
local MotionTokens = require(Shared:WaitForChild("MotionTokens"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Responsive = require(script.Parent.Parent:WaitForChild("Responsive"))
local Store = require(script.Parent.Parent:WaitForChild("Store"))
local ScreenRouter = require(script.Parent.Parent:WaitForChild("ScreenRouter"))
local I18n = require(script.Parent.Parent:WaitForChild("I18n"))

local PremiumPanel = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumPanel"))
local PremiumButton = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumButton"))
local StatBar = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("StatBar"))
local QuestTracker = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("QuestTracker"))
local SkillButton = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("SkillButton"))
local RaidPhase = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("RaidPhase"))
local CelestialMinimap = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("CelestialMinimap"))
local LiveAvatarPortrait = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("LiveAvatarPortrait"))
local HUDController = require(script.Parent.Parent:WaitForChild("Controllers"):WaitForChild("HUDController"))
local PartyController = require(script.Parent.Parent:WaitForChild("Controllers"):WaitForChild("PartyController"))

local HUD = {
    Refs = {},
    Connections = {},
    BossVisibleLatch = false,
    ConquerorUntil = 0,
    ComboState = {
        Count = 0,
        LastHitClock = 0,
        WindowSec = 4.5,
    },
    DashState = {
        MaxCharges = 3,
        RechargeSec = 1.45,
        SpentClocks = {},
        LastConsumeClock = 0,
        CalloutUntil = 0,
    },
}

local CachedCoreConfig = nil
local CachedCombatData = nil

local function getSharedCoreConfig()
    if CachedCoreConfig ~= nil then
        return CachedCoreConfig or nil
    end
    local sh = ReplicatedStorage:FindFirstChild("Shared")
    local cfgMod = sh and sh:FindFirstChild("Config")
    if cfgMod and cfgMod:IsA("ModuleScript") then
        local ok, res = pcall(require, cfgMod)
        if ok and type(res) == "table" then
            CachedCoreConfig = res
            return res
        end
    end
    CachedCoreConfig = false
    return nil
end

local function getSharedCombatData()
    if CachedCombatData ~= nil then
        return CachedCombatData or nil
    end
    local sh = ReplicatedStorage:FindFirstChild("Shared")
    local cdMod = sh and sh:FindFirstChild("SkybreakCombatData")
    if cdMod and cdMod:IsA("ModuleScript") then
        local ok, res = pcall(require, cdMod)
        if ok and type(res) == "table" then
            CachedCombatData = res
            return res
        end
    end
    CachedCombatData = false
    return nil
end

-- Rule 3: Full 12 Canonical Aether Core IDs + Legacy Aliases (never fallback "" to "GaleCore")
local CANONICAL_FRUIT_MAP = {
    GaleCore = "GaleCore",
    Gale = "GaleCore",
    galecore = "GaleCore",
    gale = "GaleCore",

    SandstoneCore = "SandstoneCore",
    Sandstone = "SandstoneCore",
    Smoke = "SandstoneCore",
    Sand = "SandstoneCore",
    sandstonecore = "SandstoneCore",
    sandstone = "SandstoneCore",
    smoke = "SandstoneCore",
    sand = "SandstoneCore",

    SolarFlameCore = "SolarFlameCore",
    SolarFlame = "SolarFlameCore",
    Flame = "SolarFlameCore",
    solarflamecore = "SolarFlameCore",
    solarflame = "SolarFlameCore",
    flame = "SolarFlameCore",

    GlacierIceCore = "GlacierIceCore",
    GlacierIce = "GlacierIceCore",
    Ice = "GlacierIceCore",
    glaciericecore = "GlacierIceCore",
    glacierice = "GlacierIceCore",
    ice = "GlacierIceCore",

    ThunderRumbleCore = "ThunderRumbleCore",
    ThunderRumble = "ThunderRumbleCore",
    Rumble = "ThunderRumbleCore",
    thunderrumblecore = "ThunderRumbleCore",
    thunderrumble = "ThunderRumbleCore",
    rumble = "ThunderRumbleCore",

    CelestialLightCore = "CelestialLightCore",
    CelestialLight = "CelestialLightCore",
    Light = "CelestialLightCore",
    celestiallightcore = "CelestialLightCore",
    celestiallight = "CelestialLightCore",
    light = "CelestialLightCore",

    StarforgedMagmaCore = "StarforgedMagmaCore",
    StarforgedMagma = "StarforgedMagmaCore",
    Magma = "StarforgedMagmaCore",
    starforgedmagmacore = "StarforgedMagmaCore",
    starforgedmagma = "StarforgedMagmaCore",
    magma = "StarforgedMagmaCore",

    AstralGravityCore = "AstralGravityCore",
    AstralGravity = "AstralGravityCore",
    Gravity = "AstralGravityCore",
    astralgravitycore = "AstralGravityCore",
    astralgravity = "AstralGravityCore",
    gravity = "AstralGravityCore",

    DimensionalPortalCore = "DimensionalPortalCore",
    DimensionalPortal = "DimensionalPortalCore",
    Portal = "DimensionalPortalCore",
    dimensionalportalcore = "DimensionalPortalCore",
    dimensionalportal = "DimensionalPortalCore",
    portal = "DimensionalPortalCore",

    SolarTitanCore = "SolarTitanCore",
    SolarTitan = "SolarTitanCore",
    Buddha = "SolarTitanCore",
    Quake = "SolarTitanCore",
    solartitancore = "SolarTitanCore",
    solartitan = "SolarTitanCore",
    buddha = "SolarTitanCore",
    quake = "SolarTitanCore",

    AetherflowCore = "AetherflowCore",
    Aetherflow = "AetherflowCore",
    SweetDoughCore = "AetherflowCore",
    SweetDough = "AetherflowCore",
    Dough = "AetherflowCore",
    aetherflowcore = "AetherflowCore",
    aetherflow = "AetherflowCore",
    sweetdoughcore = "AetherflowCore",
    sweetdough = "AetherflowCore",
    dough = "AetherflowCore",

    AbyssalSovereignCore = "AbyssalSovereignCore",
    AbyssalSovereign = "AbyssalSovereignCore",
    Dragon = "AbyssalSovereignCore",
    abyssalsovereigncore = "AbyssalSovereignCore",
    abyssalsovereign = "AbyssalSovereignCore",
    dragon = "AbyssalSovereignCore",
}

local function normalizeFruitId(raw)
    if type(raw) ~= "string" or raw == "" or raw == "None" then
        return ""
    end
    return CANONICAL_FRUIT_MAP[raw] or CANONICAL_FRUIT_MAP[string.lower(raw)] or ""
end

-- Rule 2: Explicit 3D Free-Flight Whitelist (6 Flying Cores + AbyssalSovereignCore ONLY in Form 2)
local TRUE_FLIGHT_FRUITS = {
    GaleCore = true,
    SandstoneCore = true,
    SolarFlameCore = true,
    CelestialLightCore = true,
    StarforgedMagmaCore = true,
    AstralGravityCore = true,
}

local function canFruitUseFreeFlight(fruitKey, ch, player, snap)
    if fruitKey == "" then
        return false
    end
    if fruitKey == "AbyssalSovereignCore" then
        local tier = tonumber((ch and ch:GetAttribute("DragonFormTier")) or (player and player:GetAttribute("DragonFormTier")) or (snap and snap.raw and snap.raw.DragonFormTier)) or 0
        local tf = tostring((ch and ch:GetAttribute("FruitTransform")) or (player and player:GetAttribute("FruitTransform")) or "")
        return (tier >= 2) or (tf == "AbyssalSovereign") or (tf == "DragonFull")
    end
    return TRUE_FLIGHT_FRUITS[fruitKey] == true
end

local CANONICAL_STYLE_MAP = {
    skyborn_combat = "skyborn_combat",
    SkybornCombat = "skyborn_combat",
    SkyStep = "SkyStep",
    sky_step = "SkyStep",
    black_leg = "SkyStep",
    flame_step = "SkyStep",
    jade_dragon = "jade_dragon",
    JadeDragon = "jade_dragon",
    GlacialFist = "jade_dragon",
    GlacialKarate = "jade_dragon",
    thunder_talon = "thunder_talon",
    ThunderTalon = "thunder_talon",
    ElectricClaw = "thunder_talon",
    solar_ashura = "solar_ashura",
    SolarAshura = "solar_ashura",
    AbyssalTalon = "solar_ashura",
    DragonTalon = "solar_ashura",
    celestial_godhuman = "celestial_godhuman",
    CelestialGodhuman = "celestial_godhuman",
    GodhumanSkyborn = "celestial_godhuman",
    SanguineVoidArt = "SanguineVoidArt",
    sanguine_void_art = "SanguineVoidArt",
    ChronoVoidPalm = "ChronoVoidPalm",
    chrono_void_palm = "ChronoVoidPalm",
}

local MOVE_DEFAULT_THRESHOLDS = { Z = 1, F = 1, X = 50, C = 100, V = 200 }

local function resolveSlotItemAndMastery(slotIdx, snap, player)
    local masMap = (snap and snap.fruits and type(snap.fruits.mastery) == "table") and snap.fruits.mastery or {}
    local slot = math.clamp(tonumber(slotIdx) or 1, 1, 4)
    if slot == 1 then
        local rawStyle = tostring(
            (player and (player:GetAttribute("FightingStyle") or player:GetAttribute("EquippedStyle")))
            or (snap and snap.fruits and snap.fruits.fightingStyle)
            or (snap and snap.equippedStyle)
            or "skyborn_combat"
        )
        if rawStyle == "" then
            rawStyle = "skyborn_combat"
        end
        local cd = getSharedCombatData()
        local canonStyle = (cd and cd.ResolveStyleId and cd.ResolveStyleId(rawStyle))
            or CANONICAL_STYLE_MAP[rawStyle]
            or rawStyle
        local mas = tonumber(masMap[canonStyle] or masMap[rawStyle] or (player and player:GetAttribute("StyleMastery"))) or 1
        return canonStyle, math.max(1, math.floor(mas))
    elseif slot == 2 then
        local rawFruit = tostring(
            (player and player:GetAttribute("EquippedFruit"))
            or (snap and snap.fruits and snap.fruits.equippedFruit)
            or ""
        )
        local canonFruit = normalizeFruitId(rawFruit)
        if canonFruit == "" then
            return "", 1
        end
        local mas = tonumber(
            masMap[canonFruit]
            or masMap[rawFruit]
            or (player and player:GetAttribute("FruitMastery_" .. canonFruit))
            or (player and player:GetAttribute("FruitMastery"))
            or (snap and snap.raw and snap.raw.FruitMastery)
        ) or 1
        return canonFruit, math.max(1, math.floor(mas))
    elseif slot == 3 then
        local rawSword = tostring(
            (player and player:GetAttribute("EquippedSword"))
            or (snap and snap.equipped and snap.equipped.Weapon)
            or (snap and snap.equipment and snap.equipment.Weapon)
            or "starter_sword"
        )
        if rawSword == "" then
            rawSword = "starter_sword"
        end
        local mas = tonumber(masMap[rawSword] or (player and player:GetAttribute("WeaponMastery"))) or 1
        return rawSword, math.max(1, math.floor(mas))
    else
        local rawGun = tostring(
            (player and player:GetAttribute("EquippedGun"))
            or (snap and snap.fruits and snap.fruits.equippedGun)
            or (snap and snap.equipped and (snap.equipped.EquippedGun or snap.equipped.Gun or snap.equipped.Offhand))
            or "aether_flintlock"
        )
        if rawGun == "" then
            rawGun = "aether_flintlock"
        end
        local mas = tonumber(masMap[rawGun] or (player and player:GetAttribute("GunMastery"))) or 1
        return rawGun, math.max(1, math.floor(mas))
    end
end

local function cleanShortMoveLabel(rawName, fallbackName)
    if type(rawName) ~= "string" or rawName == "" then
        return fallbackName
    end
    local viPart = rawName:match("•%s*(.+)$") or rawName:match("%-%s*(.+)$")
    if I18n.IsEnglish() then
        local enPart = rawName:match("^(.-)%s*[•%-]")
        if enPart and #enPart > 0 then
            return enPart
        end
    elseif viPart and #viPart > 0 then
        return viPart
    end
    return rawName
end

local function resolveMoveSpecForSlot(slotIdx, itemId, moveKey, ch, player, snap, fallbackCd, fallbackCost, fallbackName)
    local key = string.upper(tostring(moveKey or "Z"))
    local cd = getSharedCombatData()
    local cfg = getSharedCoreConfig()
    local mCfg = (cd and cd.MasteryConfig) or {}
    local thresholds = mCfg.MoveUnlockThresholds or MOVE_DEFAULT_THRESHOLDS
    local reqMas = tonumber(thresholds[key]) or 1
    local mv = nil

    if slotIdx == 1 then
        local st = (cd and cd.MartialStyles and cd.MartialStyles[itemId])
            or (cfg and cfg.FightingStyles and cfg.FightingStyles[itemId])
        mv = st and st.Moves and st.Moves[key] or nil
    elseif slotIdx == 2 and itemId ~= "" then
        local cat = cd and cd.FruitCatalog and cd.FruitCatalog[itemId]
        if key == "V" and cat and cat.Rarity == "Mythic" then
            reqMas = tonumber(mCfg.MythicalVThreshold) or 250
        end
        local fDef = cfg and cfg.AetherFruits and cfg.AetherFruits[itemId]
        mv = fDef and fDef.Moves and fDef.Moves[key] or nil
        if itemId == "AbyssalSovereignCore" and fDef and type(fDef.Form2Moves) == "table" and fDef.Form2Moves[key] then
            local tier = tonumber((ch and ch:GetAttribute("DragonFormTier")) or (player and player:GetAttribute("DragonFormTier")) or (snap and snap.raw and snap.raw.DragonFormTier)) or 0
            local tf = tostring((ch and ch:GetAttribute("FruitTransform")) or (player and player:GetAttribute("FruitTransform")) or "")
            if tier >= 2 or tf == "AbyssalSovereign" or tf == "DragonFull" then
                mv = fDef.Form2Moves[key]
            end
        end
    elseif slotIdx == 3 then
        local wDef = cfg and ((cfg.Swords and cfg.Swords[itemId]) or (cfg.Weapons and cfg.Weapons[itemId]))
        mv = wDef and wDef.Moves and wDef.Moves[key] or nil
    elseif slotIdx == 4 then
        local gDef = cfg and cfg.Guns and cfg.Guns[itemId]
        mv = gDef and gDef.Moves and gDef.Moves[key] or nil
    end

    if mv and mv.Mastery ~= nil then
        reqMas = tonumber(mv.Mastery) or reqMas
    end
    local maxCd = tonumber(mv and mv.Cooldown) or fallbackCd or 5
    local cost = tonumber(mv and mv.Cost) or fallbackCost or 10
    local mName = cleanShortMoveLabel(mv and (mv.DisplayName or mv.Name), nil)
    if not mName or mName == "" then
        local ctx = {
            Awakened = (snap and snap.fruits and snap.fruits.awakened == true) or (player and player:GetAttribute("FruitAwakened") == true) or false,
            DragonFormTier = tonumber((ch and ch:GetAttribute("DragonFormTier")) or (player and player:GetAttribute("DragonFormTier")) or (snap and snap.raw and snap.raw.DragonFormTier)) or 0,
            FruitTransform = tostring((ch and ch:GetAttribute("FruitTransform")) or (player and player:GetAttribute("FruitTransform")) or ""),
        }
        local bpMeta = I18n.GetSkillMechanicsMeta(slotIdx, itemId, key, ctx)
        mName = bpMeta.moveName or fallbackName
    end
    return reqMas, maxCd, cost, mName
end

local function fireSharedFlightToggle(player, startWanted)
    local toggleEvt = player and player:FindFirstChild("SkybreakToggleFlight")
    if toggleEvt and toggleEvt:IsA("BindableEvent") then
        toggleEvt:Fire()
        return true
    end
    local tfx = workspace:FindFirstChild("TempFX")
    local cmd = tfx and tfx:FindFirstChild("SkybreakFlightCamCommand")
    if cmd and cmd:IsA("BindableEvent") then
        cmd:Fire(startWanted and "StartFlight" or "StopFlight")
        return true
    end
    return false
end

local function triggerFKeyOrFlight(player)
    local ch = player and player.Character
    local flyingNow = (player and player:GetAttribute("SkybreakFlightActive") == true)
        or (ch and ch:GetAttribute("SkybreakFlightActive") == true)
    if flyingNow then
        fireSharedFlightToggle(player, false)
        return
    end

    local snap = Store.GetSnapshot()
    local view = Store.GetView()
    local curSlot = tonumber((player and player:GetAttribute("ActiveSlot")) or view.activeHotbarSlot or (snap.fruits and snap.fruits.activeSlot)) or 1
    if curSlot == 2 then
        local fruitKey, curMas = resolveSlotItemAndMastery(2, snap, player)
        if canFruitUseFreeFlight(fruitKey, ch, player, snap) then
            local fMasReq, _, fCost = resolveMoveSpecForSlot(2, fruitKey, "F", ch, player, snap, 5, 8, nil)
            local curEn = tonumber((ch and ch:GetAttribute("Energy")) or (player and player:GetAttribute("Energy")) or (snap.vitals and snap.vitals.energy)) or 100
            if curMas >= fMasReq and curEn >= math.max(1, fCost) then
                if fireSharedFlightToggle(player, true) then
                    return
                end
            end
        end
    end

    -- 6 Non-Flying Cores + Slots 1/3/4 (or unequipped/locked): instant 0ms SlotMove("F")
    HUDController.TriggerAction("F")
end

local function resolveClassBadgeMeta(level, classId, v4Active)
    local lv = tonumber(level) or 1
    local suffix = v4Active and I18n.Pick(" • THĂNG HOA", " • ASCENSION") or ""
    if lv < 15 then
        return "* SKYBORN" .. suffix, Color3.fromRGB(214, 196, 148)
    elseif classId == "ThunderStriker" then
        return "* THUNDERSTRIKER" .. suffix, Color3.fromRGB(88, 206, 255)
    elseif classId == "ArcaneMage" then
        return "* ARCANEMAGE" .. suffix, Color3.fromRGB(204, 148, 255)
    end
    return "* SKYGUARDIAN" .. suffix, Theme.Colors.ACCENT_GOLD_BRIGHT
end

local function resolveComboRankMeta(comboCount)
    local c = tonumber(comboCount) or 0
    local bonusPct = math.min(35, math.max(4, math.floor(c * 0.55)))
    if c >= 35 then
        return "SS", Color3.fromRGB(251, 113, 133), I18n.Pick(string.format("+%d%% SÁT THƯƠNG AETHER", bonusPct), string.format("+%d%% AETHER DAMAGE", bonusPct))
    elseif c >= 23 then
        return "S", Color3.fromRGB(249, 209, 104), I18n.Pick(string.format("+%d%% SÁT THƯƠNG AETHER", bonusPct), string.format("+%d%% AETHER DAMAGE", bonusPct))
    elseif c >= 15 then
        return "A", Color3.fromRGB(192, 132, 252), I18n.Pick(string.format("+%d%% SÁT THƯƠNG AETHER", bonusPct), string.format("+%d%% AETHER DAMAGE", bonusPct))
    elseif c >= 9 then
        return "B", Color3.fromRGB(52, 211, 153), I18n.Pick(string.format("+%d%% SÁT THƯƠNG AETHER", bonusPct), string.format("+%d%% AETHER DAMAGE", bonusPct))
    elseif c >= 5 then
        return "C", Color3.fromRGB(56, 189, 248), I18n.Pick(string.format("+%d%% SÁT THƯƠNG AETHER", bonusPct), string.format("+%d%% AETHER DAMAGE", bonusPct))
    end
    return "D", Color3.fromRGB(148, 212, 255), I18n.Pick(string.format("+%d%% SÁT THƯƠNG AETHER", bonusPct), string.format("+%d%% AETHER DAMAGE", bonusPct))
end

local SLOT_ICONS = {
    [1] = "Fist",
    [2] = "Fruit",
    [3] = "Sword",
    [4] = "Gun",
}

local function formatTimer(sec)
    local s = math.max(0, math.floor(tonumber(sec) or 0))
    local m = math.floor(s / 60)
    local r = s % 60
    if m > 0 then
        return string.format("%d:%02d", m, r)
    end
    return string.format("%ds", r)
end

-- Builds the Centerpiece 45-Degree Diamond Ultimate [R] + Flanking J (Haki) & T (Race V4) Shoulder Mini-Orbs
local function buildDiamondUltimateCenterpiece(parent, props)
    local colors = Theme.Colors
    local baseZ = props.zIndex or 8

    local holder = UIFactory.Create("Frame", parent, {
        Name = "DiamondUltimateCenter",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(92, 82),
        BackgroundTransparency = 1,
        ClipsDescendants = false,
        ZIndex = baseZ,
    })

    -- Top-Left Shoulder Circular [J] Crimson Haki Mini-Orb (22x22)
    local jOrb = UIFactory.Create("TextButton", holder, {
        Name = "HakiShoulderOrb_J",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, -33, 0, 12),
        Size = UDim2.fromOffset(22, 22),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Text = "J",
        Font = Theme.Fonts.Bold,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(255, 250, 252),
        AutoButtonColor = false,
        ZIndex = baseZ + 6,
    })
    UIFactory.PillCorner(jOrb)
    local jOrbStroke = UIFactory.Stroke(jOrb, Color3.fromRGB(255, 180, 196), 1.5, 0.05)
    UIFactory.Gradient(jOrb, Color3.fromRGB(251, 58, 100), Color3.fromRGB(159, 18, 57), 90)
    jOrb.Activated:Connect(function()
        if type(props.onHaki) == "function" then
            props.onHaki()
        end
    end)

    -- Top-Right Shoulder Circular [Y] Violet Race V4 Mini-Orb (22x22)
    local tOrb = UIFactory.Create("TextButton", holder, {
        Name = "RaceV4ShoulderOrb_Y",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 33, 0, 12),
        Size = UDim2.fromOffset(22, 22),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Text = "Y",
        Font = Theme.Fonts.Bold,
        TextSize = 11,
        TextColor3 = Color3.fromRGB(252, 246, 255),
        AutoButtonColor = false,
        ZIndex = baseZ + 6,
    })
    UIFactory.PillCorner(tOrb)
    local tOrbStroke = UIFactory.Stroke(tOrb, Color3.fromRGB(233, 213, 255), 1.5, 0.05)
    UIFactory.Gradient(tOrb, Color3.fromRGB(192, 132, 252), Color3.fromRGB(109, 40, 217), 90)
    tOrb.Activated:Connect(function()
        if type(props.onV4) == "function" then
            props.onV4()
        end
    end)

    -- Main Interactive Hitbox + Scale Wrapper for 45-deg Rotated Diamond [R]
    local ultHitBtn = UIFactory.Create("TextButton", holder, {
        Name = "UltimateDiamondButton",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.47, 0),
        Size = UDim2.fromOffset(60, 60),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = baseZ + 3,
    })
    local uiScale = Instance.new("UIScale")
    uiScale.Scale = 1.0
    uiScale.Parent = ultHitBtn

    -- Outer 45-deg Champagne Gold Double-Bordered Diamond Frame (54x54)
    local outerDiamond = UIFactory.Create("Frame", ultHitBtn, {
        Name = "OuterGoldDiamond",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(54, 54),
        Rotation = 45,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Active = false,
        ZIndex = baseZ + 2,
    })
    UIFactory.Corner(outerDiamond, 10)
    local outerStroke = UIFactory.Stroke(outerDiamond, colors.ACCENT_GOLD_BRIGHT, 2.2, 0.02)
    UIFactory.Gradient(outerDiamond, Color3.fromRGB(252, 216, 112), Color3.fromRGB(184, 124, 28), 90)

    -- Inner 45-deg Vivid Violet-Rose Glossy Diamond Core (44x44)
    local innerDiamond = UIFactory.Create("Frame", ultHitBtn, {
        Name = "InnerMythicDiamond",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(44, 44),
        Rotation = 45,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Active = false,
        ZIndex = baseZ + 3,
    })
    UIFactory.Corner(innerDiamond, 8)
    UIFactory.Stroke(innerDiamond, Color3.fromRGB(255, 214, 240), 1.3, 0.16)
    local innerGrad = UIFactory.Gradient(innerDiamond, Color3.fromRGB(236, 104, 246), Color3.fromRGB(118, 38, 224), 135)

    local diamondGloss = UIFactory.Create("Frame", innerDiamond, {
        Name = "DiamondGloss",
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.new(1, -4, 0.45, 0),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = 0.76,
        BorderSizePixel = 0,
        Active = false,
        ZIndex = baseZ + 4,
    })
    UIFactory.Corner(diamondGloss, 6)

    -- Unrotated Royal Crown Vector Icon centered inside Diamond
    local crownIcon = UIFactory.Icon(
        ultHitBtn,
        "Crown",
        UDim2.new(0.5, -12, 0.5, -12),
        24,
        Color3.fromRGB(255, 252, 255)
    )
    crownIcon.ZIndex = baseZ + 5

    local cdLabel = UIFactory.Label(ultHitBtn, {
        Name = "UltCooldownText",
        Text = "",
        Size = UDim2.fromScale(1, 1),
        TextSize = 13,
        TextColor = Color3.fromRGB(168, 236, 255),
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Wrapped = false,
        ZIndex = baseZ + 6,
    })

    -- Top [R] Dark Obsidian Pill
    local rPill = UIFactory.Create("Frame", holder, {
        Name = "TopKeyPill_R",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0, -2),
        Size = UDim2.fromOffset(28, 15),
        BackgroundColor3 = Color3.fromRGB(9, 13, 24),
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        ZIndex = baseZ + 7,
    })
    UIFactory.Corner(rPill, 4)
    UIFactory.Stroke(rPill, colors.ACCENT_GOLD_BRIGHT, 1.2, 0.14)
    UIFactory.Label(rPill, {
        Name = "KeyTxt",
        Text = "[R]",
        Size = UDim2.fromScale(1, 1),
        TextSize = 9,
        TextColor = Color3.fromRGB(255, 244, 196),
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Wrapped = false,
        ZIndex = baseZ + 8,
    })

    -- Bottom "TUYỆT KỸ • 100%" Dark Obsidian-Gold Pill
    local botPill = UIFactory.Create("Frame", holder, {
        Name = "BottomUltPill",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.fromOffset(88, 16),
        BackgroundColor3 = Color3.fromRGB(9, 13, 24),
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        ZIndex = baseZ + 7,
    })
    UIFactory.PillCorner(botPill)
    UIFactory.Stroke(botPill, colors.ACCENT_GOLD_BRIGHT, 1.2, 0.16)
    local botLabel = UIFactory.Label(botPill, {
        Name = "UltCaption",
        Text = I18n.Pick("TUYỆT KỸ • 100%", "ULTIMATE • 100%"),
        Size = UDim2.fromScale(1, 1),
        TextSize = 8,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Wrapped = false,
        ZIndex = baseZ + 8,
    })

    local state = {
        locked = props.locked == true,
        cooldown = 0,
        maxCooldown = math.max(0.1, tonumber(props.maxCooldown) or 45),
    }

    ultHitBtn.MouseEnter:Connect(function()
        if not state.locked then
            UIAnimator.Tween(uiScale, { Scale = 1.07 }, MotionTokens.hoverFast.duration)
        end
    end)
    ultHitBtn.MouseLeave:Connect(function()
        UIAnimator.Tween(uiScale, { Scale = 1.0 }, MotionTokens.hoverFast.duration)
    end)
    ultHitBtn.Activated:Connect(function()
        if state.locked or state.cooldown > 0 then
            return
        end
        if type(props.onActivated) == "function" then
            props.onActivated()
        end
    end)

    local api = {
        Instance = holder,
        JOrbStroke = jOrbStroke,
        TOrbStroke = tOrbStroke,
    }

    function api:Update(newState)
        newState = newState or {}
        if newState.locked ~= nil then
            state.locked = newState.locked == true
        end
        if newState.cooldown ~= nil then
            state.cooldown = math.max(0, tonumber(newState.cooldown) or 0)
        end
        if newState.maxCooldown ~= nil then
            state.maxCooldown = math.max(0.1, tonumber(newState.maxCooldown) or 45)
        end

        if state.locked then
            crownIcon.Visible = false
            cdLabel.Text = tostring(newState.lockLabel or "Lv.20")
            cdLabel.TextSize = 10
            cdLabel.TextColor3 = colors.TEXT_MUTED
            innerGrad.Color = ColorSequence.new(Color3.fromRGB(40, 48, 72), Color3.fromRGB(18, 24, 38))
            outerStroke.Color = colors.STROKE_STEEL
            botLabel.Text = I18n.Pick("TUYỆT KỸ", "ULTIMATE")
        elseif state.cooldown > 0 then
            crownIcon.Visible = false
            cdLabel.Text = string.format("%.1fs", state.cooldown)
            cdLabel.TextSize = 12
            cdLabel.TextColor3 = Color3.fromRGB(142, 228, 255)
            innerGrad.Color = ColorSequence.new(Color3.fromRGB(48, 38, 86), Color3.fromRGB(20, 18, 44))
            outerStroke.Color = Color3.fromRGB(116, 134, 186)
            local pct = math.clamp(math.floor((1 - state.cooldown / state.maxCooldown) * 100), 0, 99)
            botLabel.Text = string.format("%s • %d%%", I18n.Pick("TUYỆT KỸ", "ULT"), pct)
        elseif newState.outOfEnergy then
            crownIcon.Visible = true
            cdLabel.Text = ""
            innerGrad.Color = ColorSequence.new(Color3.fromRGB(148, 56, 98), Color3.fromRGB(72, 24, 92))
            outerStroke.Color = colors.HP_RED
            botLabel.Text = I18n.Pick("THIẾU EN", "LOW EN")
        else
            crownIcon.Visible = true
            cdLabel.Text = ""
            innerGrad.Color = ColorSequence.new(Color3.fromRGB(238, 108, 248), Color3.fromRGB(118, 38, 224))
            outerStroke.Color = colors.ACCENT_GOLD_BRIGHT
            botLabel.Text = I18n.Pick("TUYỆT KỸ • 100%", "ULTIMATE • 100%")
        end
    end

    function api:Destroy()
        if holder and holder.Parent then
            holder:Destroy()
        end
    end

    api:Update(props)
    return holder, api
end

function HUD.Build(parent, responsiveState)
    HUD.Cleanup()
    local colors = Theme.Colors
    local snap = Store.GetSnapshot()
    local view = Store.GetView()
    local layoutOverride = view.settings and view.settings.layoutMode or "Auto"
    local viewportVec = responsiveState and responsiveState.Viewport
    local isMobile = (responsiveState and responsiveState.IsMobile == true)
        or Responsive.IsMobile(viewportVec, layoutOverride)
    local isPortrait = responsiveState and responsiveState.IsPortrait
    local player = Players.LocalPlayer

    local root = UIFactory.Create("Frame", parent, {
        Name = "CombatHUD",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 2,
    })

    -- 1. Top-Left Gold-Corner-Bracketed PlayerHUD Card (388 x 122) with Winged Live 3D Avatar Bust
    local vitalsCard = PremiumPanel.Create(root, {
        name = "PlayerHUD",
        variant = "gold",
        position = UDim2.fromOffset(16, 14),
        size = UDim2.fromOffset(isPortrait and 356 or 388, 122),
        transparency = 0.06,
        clipsDescendants = false,
    })

    local classCfg = WorldConfig.Classes[snap.player.classId] or WorldConfig.Classes.SkyGuardian

    local _, avatarPortraitApi = LiveAvatarPortrait.Create(vitalsCard, {
        name = "LiveAvatarPortrait",
        position = UDim2.fromOffset(13, 15),
        size = UDim2.fromOffset(78, 86),
        snapshot = snap,
        zIndex = 5,
    })
    local levelLabel = avatarPortraitApi.LevelLabel

    local playerNameLabel = UIFactory.Label(vitalsCard, {
        Name = "PlayerName",
        Text = (player and player.DisplayName) or "Skyborn",
        Position = UDim2.fromOffset(102, 9),
        Size = UDim2.new(1, -252, 0, 20),
        TextSize = 14,
        TextColor = colors.TEXT_PRIMARY,
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
    })

    local initTitleText, initTitleColor = resolveClassBadgeMeta(snap.player.level, snap.player.classId, false)
    local classTitlePill = UIFactory.Create("Frame", vitalsCard, {
        Name = "ClassTitlePill",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 9),
        Size = UDim2.fromOffset(140, 20),
        BackgroundColor3 = Color3.fromRGB(16, 30, 58),
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        ZIndex = 6,
    })
    UIFactory.PillCorner(classTitlePill)
    local classTitleStroke = UIFactory.Stroke(classTitlePill, initTitleColor, 1.3, 0.14)
    UIFactory.Gradient(classTitlePill, Color3.fromRGB(32, 64, 118), Color3.fromRGB(12, 22, 42), 90)

    local classTitleLabel = UIFactory.Label(classTitlePill, {
        Name = "ClassTitleText",
        Text = initTitleText,
        Position = UDim2.fromOffset(6, 0),
        Size = UDim2.new(1, -12, 1, 0),
        TextSize = 9,
        TextColor = initTitleColor,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = 7,
    })
    UIFactory.TextSizeConstraint(classTitleLabel, 7, 10)

    local _, hpBarApi = StatBar.Create(vitalsCard, {
        name = "HPBar",
        type = "HP",
        current = snap.vitals.hp,
        max = snap.vitals.maxHp,
        label = "HP",
        cornerRadius = 11,
        textSize = 12,
        position = UDim2.fromOffset(102, 34),
        size = UDim2.new(1, -112, 0, 23),
        scope = "HUD",
    })
    HUDController.BindHumanoidToBar(hpBarApi)

    local initMaxEnergy = math.max(
        100,
        math.floor(tonumber((player and player:GetAttribute("MaxEnergy")) or (snap.vitals and snap.vitals.maxEnergy) or (snap.raw and snap.raw.MaxEnergy)) or 100)
    )
    local _, staminaBarApi = StatBar.Create(vitalsCard, {
        name = "StaminaBar",
        type = "Energy",
        current = snap.vitals.energy or initMaxEnergy,
        max = initMaxEnergy,
        label = "AETHER",
        cornerRadius = 10,
        textSize = 11,
        position = UDim2.fromOffset(102, 62),
        size = UDim2.new(1, -112, 0, 20),
        scope = "HUD",
    })

    local initExpPct = math.clamp(math.floor(((tonumber(snap.player.exp) or 0) / math.max(1, tonumber(snap.player.expToNext) or 100)) * 100), 0, 100)
    local _, xpBarApi = StatBar.Create(vitalsCard, {
        name = "XPBar",
        type = "EXP",
        current = snap.player.exp,
        max = snap.player.expToNext,
        cornerRadius = 9,
        customText = string.format("EXP %s / %s (%d%%)", UIFactory.FormatNumber(snap.player.exp), UIFactory.FormatNumber(snap.player.expToNext), initExpPct),
        position = UDim2.fromOffset(102, 87),
        size = UDim2.new(1, -112, 0, 17),
        textSize = 10,
        scope = "HUD",
    })

    -- 1A. Dynamic Dragon Fury / Race V4 Awakening Meter Bar (visible when AbyssalSovereignCore or Race V4 is equipped/active)
    local furyAwakenTrack = UIFactory.Create("Frame", vitalsCard, {
        Name = "FuryAwakeningBar",
        Position = UDim2.fromOffset(102, 108),
        Size = UDim2.new(1, -112, 0, 14),
        BackgroundColor3 = Color3.fromRGB(9, 13, 25),
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 6,
    })
    UIFactory.PillCorner(furyAwakenTrack)
    local furyAwakenStroke = UIFactory.Stroke(furyAwakenTrack, Color3.fromRGB(251, 146, 60), 1.1, 0.16)

    local furyAwakenFill = UIFactory.Create("Frame", furyAwakenTrack, {
        Name = "Fill",
        Size = UDim2.fromScale(0, 1),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 7,
    })
    UIFactory.PillCorner(furyAwakenFill)
    local furyAwakenGrad = UIFactory.Gradient(furyAwakenFill, Color3.fromRGB(251, 191, 36), Color3.fromRGB(225, 29, 72), 0)

    local furyAwakenLabel = UIFactory.Label(furyAwakenTrack, {
        Name = "MeterText",
        Text = "DRAGON FURY • 0%",
        Size = UDim2.fromScale(1, 1),
        TextSize = 9,
        TextColor = Color3.fromRGB(255, 248, 230),
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Wrapped = false,
        ZIndex = 8,
    })

    -- 1B. Always-Visible Currency & Haki Status Pills Row Directly Below Vitals + Dynamic Active Buffs
    local statusPillsRow = UIFactory.Create("Frame", root, {
        Name = "CurrencyAndStatusRow",
        Position = UDim2.fromOffset(16, 142),
        Size = UDim2.fromOffset(820, 26),
        BackgroundTransparency = 1,
        ZIndex = 6,
    })
    UIFactory.ListLayout(statusPillsRow, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    local function makeHudStatusPill(name, iconKind, iconCol, strokeCol, initText, order, isClickable, onClick)
        local cls = isClickable and "TextButton" or "Frame"
        local pProps = {
            Name = name,
            Size = UDim2.fromOffset(0, 24),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = Color3.fromRGB(11, 17, 30),
            BackgroundTransparency = 0.04,
            BorderSizePixel = 0,
            LayoutOrder = order,
            ZIndex = 6,
        }
        if isClickable then
            pProps.Text = ""
            pProps.AutoButtonColor = false
        end
        local pill = UIFactory.Create(cls, statusPillsRow, pProps)
        UIFactory.Corner(pill, 7)
        local pStroke = UIFactory.Stroke(pill, strokeCol, 1.3, 0.14)
        UIFactory.Padding(pill, 0, 8, 0, 7)

        local inner = UIFactory.Create("Frame", pill, {
            Name = "Inner",
            Size = UDim2.fromOffset(0, 24),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            ZIndex = 7,
        })
        UIFactory.ListLayout(inner, Enum.FillDirection.Horizontal, 5, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
        local ic = UIFactory.Icon(inner, iconKind, UDim2.fromOffset(0, 0), 14, iconCol)
        ic.ZIndex = 7
        local lbl = UIFactory.Label(inner, {
            Name = "PillText",
            Text = initText,
            Size = UDim2.fromOffset(0, 24),
            TextSize = 11,
            TextColor = Color3.fromRGB(246, 249, 255),
            Bold = true,
            Wrapped = false,
            ZIndex = 7,
        })
        lbl.AutomaticSize = Enum.AutomaticSize.X
        if isClickable and type(onClick) == "function" then
            pill.Activated:Connect(onClick)
        end
        return pill, lbl, pStroke
    end

    local curGoldVal = tonumber((snap.currency and snap.currency.gold) or (snap.currencies and snap.currencies.gold)) or 0
    local curShardVal = tonumber((snap.currency and snap.currency.coreShards) or (snap.currencies and snap.currencies.coreShards)) or 0

    local _, hudGoldLabel = makeHudStatusPill(
        "HudGoldPill",
        "Gold",
        colors.ACCENT_GOLD_BRIGHT,
        colors.ACCENT_GOLD,
        UIFactory.FormatNumber(curGoldVal) .. " Gold",
        1,
        false
    )

    local _, hudShardLabel = makeHudStatusPill(
        "HudShardsPill",
        "CoreShards",
        colors.ACCENT_SAPPHIRE,
        colors.ACCENT_SAPPHIRE,
        UIFactory.FormatNumber(curShardVal) .. " Shards",
        2,
        false
    )

    local hudHakiPill, hudHakiLabel, hudHakiStroke = makeHudStatusPill(
        "HudHakiStatusPill",
        "Haki",
        colors.HP_RED,
        colors.HP_RED,
        I18n.Pick("[J] Thiết Giáp Ý • [U] Thấu Ý", "[J] Will Armor • [U] Will Sense"),
        3,
        true,
        function()
            HUDController.TriggerAction("ToggleAura")
        end
    )

    local _, hudPassLabel = makeHudStatusPill(
        "HudRobuxPassPill",
        "RobuxGem",
        Color3.fromRGB(52, 211, 153),
        Color3.fromRGB(52, 211, 153),
        "PASS • R$",
        4,
        true,
        function()
            ScreenRouter.Navigate("NPCShop:RobuxPasses")
        end
    )
    hudPassLabel.TextColor3 = Color3.fromRGB(168, 250, 210)

    local buffDefs = {
        { id = "Aura", icon = "Haki", color = Color3.fromRGB(255, 118, 146), order = 10 },
        { id = "Instinct", icon = "Compass", color = colors.ACCENT_SAPPHIRE, order = 11 },
        { id = "Conqueror", icon = "Crown", color = Color3.fromRGB(251, 92, 124), order = 12 },
        { id = "RaceV4", icon = "Wing", color = colors.ACCENT_GOLD_BRIGHT, order = 13 },
        { id = "ShieldTransform", icon = "Shield", color = colors.VOID_PURPLE, order = 14 },
        { id = "DoubleExp", icon = "Sparkle", color = colors.SUCCESS, order = 15 },
    }
    local buffPills = {}
    for _, bd in ipairs(buffDefs) do
        local pFrame, pLbl = makeHudStatusPill("Buff_" .. bd.id, bd.icon, bd.color, bd.color, "", bd.order, false)
        pFrame.Visible = false
        pLbl.TextColor3 = bd.color
        buffPills[bd.id] = { Frame = pFrame, Label = pLbl }
    end

    -- 2. Middle-Left Collapsible Quest Tracker with Golden Ribbon Header Banner (16, 176)
    local questTrackerFrame, questTrackerApi = QuestTracker.Create(root, {
        name = "QuestTracker",
        position = UDim2.fromOffset(16, 176),
        size = UDim2.fromOffset(isPortrait and 316 or 314, 122),
        collapsed = view.questTrackerCollapsed,
        onToggleCollapse = function(isCol)
            Store.SetView({ questTrackerCollapsed = isCol })
        end,
        onOpenJournal = function()
            ScreenRouter.Navigate(UIState.Screens.QuestJournal)
        end,
    })
    questTrackerApi:Update({ activeQuest = snap.quest })

    -- 3. Top-Right Circular Celestial Minimap (148x148) + Sleek Purple Fruit Radar Pill & Gold Squad Pill Button
    local minimapApi = CelestialMinimap.Create(root, function()
        ScreenRouter.Navigate(UIState.Screens.WorldMap)
    end)
    if view.settings and view.settings.showMinimap == false then
        minimapApi.Instance.Visible = false
    end
    local internalFruitPill = minimapApi.Instance and minimapApi.Instance:FindFirstChild("NaturalFruitNotifierPill")
    if internalFruitPill and internalFruitPill:IsA("GuiObject") then
        -- Hide duplicate internal notifier pill because we render the always-clean Figma Purple Radar Pill below
        internalFruitPill.Size = UDim2.fromOffset(0, 0)
        internalFruitPill.ClipsDescendants = true
    end

    -- Purple Aether Fruit Radar Pill (y = 170)
    local fruitRadarPill = UIFactory.Create("TextButton", root, {
        Name = "AetherFruitRadarPill",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -16, 0, 170),
        Size = UDim2.fromOffset(186, 25),
        BackgroundColor3 = Color3.fromRGB(36, 18, 62),
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 12,
    })
    UIFactory.PillCorner(fruitRadarPill)
    local fruitRadarStroke = UIFactory.Stroke(fruitRadarPill, Color3.fromRGB(192, 132, 252), 1.4, 0.10)
    local frIcon = UIFactory.Icon(fruitRadarPill, "Fruit", UDim2.new(0, 8, 0.5, -7), 14, Color3.fromRGB(232, 180, 255))
    frIcon.ZIndex = 13
    local fruitRadarLabel = UIFactory.Label(fruitRadarPill, {
        Name = "RadarText",
        Text = I18n.Pick("Radar Aether: Quét Đảo", "Aether Radar: Scanning"),
        Position = UDim2.fromOffset(26, 0),
        Size = UDim2.new(1, -32, 1, 0),
        TextSize = 10,
        TextColor = Color3.fromRGB(244, 232, 255),
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = 13,
    })
    fruitRadarPill.Activated:Connect(function()
        Store.SetView({ fruitsMode = "Vault" })
        ScreenRouter.Navigate("Fruits:Vault")
    end)

    -- Gold Squad Pill Button (y = 200) -> opens SocialRewards [B]
    local squadPillBtn = UIFactory.Create("TextButton", root, {
        Name = "SquadStatusPillBtn",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -16, 0, 200),
        Size = UDim2.fromOffset(172, 25),
        BackgroundColor3 = Color3.fromRGB(12, 19, 34),
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Visible = not isMobile,
        ZIndex = 12,
    })
    UIFactory.PillCorner(squadPillBtn)
    UIFactory.Stroke(squadPillBtn, colors.ACCENT_GOLD_BRIGHT, 1.4, 0.14)
    local sqIcon = UIFactory.Icon(squadPillBtn, "Shield", UDim2.new(0, 8, 0.5, -7), 14, colors.ACCENT_GOLD_BRIGHT)
    sqIcon.ZIndex = 13
    local companionTitle = UIFactory.Label(squadPillBtn, {
        Name = "CompanionTitle",
        Visible = true,
        Text = I18n.Pick("TỔ ĐỘI: SOLO • [B]", "PARTY: SOLO • [B]"),
        Position = UDim2.fromOffset(26, 0),
        Size = UDim2.new(1, -32, 1, 0),
        TextSize = 10,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = 13,
    })
    squadPillBtn.Activated:Connect(function()
        ScreenRouter.Navigate(UIState.Screens.SocialRewards)
    end)

    -- Interactive Pending Party Invite Banner (visible whenever snap.party.pendingInviteFrom is set)
    local partyInviteBanner = UIFactory.Create("Frame", root, {
        Name = "PartyInviteBanner",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -16, 0, isMobile and 202 or 230),
        Size = UDim2.fromOffset(238, 56),
        BackgroundColor3 = Color3.fromRGB(11, 20, 38),
        BackgroundTransparency = 0.03,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 14,
    })
    UIFactory.Corner(partyInviteBanner, 10)
    UIFactory.Stroke(partyInviteBanner, colors.ACCENT_GOLD_BRIGHT, 1.5, 0.08)
    UIFactory.Gradient(partyInviteBanner, Color3.fromRGB(22, 38, 68), Color3.fromRGB(10, 16, 30), 90)

    local partyInviteTitle = UIFactory.Label(partyInviteBanner, {
        Name = "InviteText",
        Text = "Lời mời Tổ Đội",
        Position = UDim2.fromOffset(10, 5),
        Size = UDim2.new(1, -20, 0, 18),
        TextSize = 10,
        TextColor = Color3.fromRGB(254, 240, 184),
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = 15,
    })

    local partyAcceptBtn = UIFactory.Create("TextButton", partyInviteBanner, {
        Name = "AcceptPartyBtn",
        Position = UDim2.fromOffset(10, 27),
        Size = UDim2.fromOffset(106, 22),
        BackgroundColor3 = Color3.fromRGB(22, 163, 74),
        BorderSizePixel = 0,
        Font = Theme.Fonts.Bold,
        TextSize = 10,
        TextColor3 = Color3.fromRGB(248, 255, 250),
        Text = I18n.Pick("CHẤP NHẬN", "ACCEPT"),
        AutoButtonColor = true,
        ZIndex = 15,
    })
    UIFactory.Corner(partyAcceptBtn, 6)
    UIFactory.Stroke(partyAcceptBtn, Color3.fromRGB(134, 239, 172), 1.1, 0.15)
    partyAcceptBtn.Activated:Connect(function()
        PartyController.AcceptInvite()
    end)

    local partyDeclineBtn = UIFactory.Create("TextButton", partyInviteBanner, {
        Name = "DeclinePartyBtn",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -10, 0, 27),
        Size = UDim2.fromOffset(102, 22),
        BackgroundColor3 = Color3.fromRGB(127, 29, 29),
        BorderSizePixel = 0,
        Font = Theme.Fonts.Bold,
        TextSize = 10,
        TextColor3 = Color3.fromRGB(254, 226, 226),
        Text = I18n.Pick("TỪ CHỐI", "DECLINE"),
        AutoButtonColor = true,
        ZIndex = 15,
    })
    UIFactory.Corner(partyDeclineBtn, 6)
    UIFactory.Stroke(partyDeclineBtn, Color3.fromRGB(252, 165, 165), 1.1, 0.2)
    partyDeclineBtn.Activated:Connect(function()
        PartyController.DeclineInvite()
    end)

    -- 4. Top-Center Proximity/Combat-Gated Boss HP Bar with Golden Crown Ribbon (#6)
    local _, bossBarApi = RaidPhase.Create(root, {
        name = "BossHUD",
        position = isPortrait and UDim2.new(0.5, 0, 0, 326) or UDim2.new(0.5, 0, 0, 22),
        size = UDim2.fromOffset(isPortrait and 486 or 528, 74),
        visible = false,
    })

    -- 4B. Dynamic Action-RPG Combo Card (Right-Center, Tilted -8 deg Glossy Gold Rank Square)
    local comboCard = PremiumPanel.Create(root, {
        name = "ComboRankCard",
        variant = "gold",
        anchorPoint = Vector2.new(1, 0.5),
        position = UDim2.new(1, -16, 0.42, 0),
        size = UDim2.fromOffset(216, 68),
        transparency = 0.06,
        clipsDescendants = false,
        visible = false,
        zIndex = 8,
    })

    local comboGradeBox = UIFactory.Create("Frame", comboCard, {
        Name = "RankGradeBox",
        Position = UDim2.fromOffset(10, 11),
        Size = UDim2.fromOffset(44, 44),
        Rotation = -8,
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 9,
    })
    UIFactory.Corner(comboGradeBox, 9)
    local comboGradeStroke = UIFactory.Stroke(comboGradeBox, Color3.fromRGB(255, 242, 178), 1.8, 0.04)
    local comboGradeGrad = UIFactory.Gradient(comboGradeBox, Color3.fromRGB(252, 214, 104), Color3.fromRGB(196, 136, 32), 90)

    local comboGradeLabel = UIFactory.Label(comboGradeBox, {
        Name = "RankGrade",
        Text = "S",
        Size = UDim2.fromScale(1, 1),
        TextSize = 24,
        TextColor = Color3.fromRGB(14, 18, 30),
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Wrapped = false,
        ZIndex = 10,
    })

    local comboCountLabel = UIFactory.Label(comboCard, {
        Name = "ComboCount",
        Text = "2 COMBO HITS",
        Position = UDim2.fromOffset(64, 8),
        Size = UDim2.new(1, -72, 0, 22),
        TextSize = 15,
        TextColor = colors.TEXT_PRIMARY,
        Bold = true,
        RichText = true,
        Wrapped = false,
        ZIndex = 9,
    })

    local comboTitleLabel = UIFactory.Label(comboCard, {
        Name = "ComboTitle",
        Text = "+18% SÁT THƯƠNG AETHER",
        Position = UDim2.fromOffset(64, 30),
        Size = UDim2.new(1, -72, 0, 14),
        TextSize = 9,
        TextColor = Color3.fromRGB(92, 225, 255),
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = 9,
    })

    local comboTimerTrack = UIFactory.Create("Frame", comboCard, {
        Name = "ComboTimerTrack",
        Position = UDim2.fromOffset(64, 49),
        Size = UDim2.new(1, -76, 0, 6),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 9,
    })
    UIFactory.PillCorner(comboTimerTrack)

    local comboTimerFill = UIFactory.Create("Frame", comboTimerTrack, {
        Name = "ComboTimerFill",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = colors.ACCENT_GOLD_BRIGHT,
        BorderSizePixel = 0,
        ZIndex = 10,
    })
    UIFactory.PillCorner(comboTimerFill)
    for _, pct in ipairs({ 0.25, 0.50, 0.75 }) do
        UIFactory.Create("Frame", comboTimerTrack, {
            Name = "Seg_" .. tostring(math.floor(pct * 100)),
            Position = UDim2.fromScale(pct, 0),
            Size = UDim2.new(0, 2, 1, 0),
            BackgroundColor3 = colors.BG_800,
            BorderSizePixel = 0,
            ZIndex = 11,
        })
    end


    -- 4C. Center Tactical Ranged Aim Reticle (8-Segment Dashed Crimson Circle + 45-deg Gold Diamond + Crimson Dot)
    local aimReticle = UIFactory.Create("Frame", root, {
        Name = "CenterAimReticle",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.47),
        Size = UDim2.fromOffset(48, 48),
        BackgroundTransparency = 1,
        Active = false,
        ZIndex = 6,
    })
    local aimReticleScale = Instance.new("UIScale")
    aimReticleScale.Scale = 1.0
    aimReticleScale.Parent = aimReticle

    local aimDashSegments = {}
    for segIdx = 1, 8 do
        local angDeg = (segIdx - 1) * 45
        local angRad = math.rad(angDeg)
        local rPx = 20
        local arcSeg = UIFactory.Create("Frame", aimReticle, {
            Name = "CrimsonArc_" .. tostring(segIdx),
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(0.5, math.cos(angRad) * rPx, 0.5, math.sin(angRad) * rPx),
            Size = UDim2.fromOffset(8, 2),
            Rotation = angDeg + 90,
            BackgroundColor3 = Color3.fromRGB(251, 55, 98),
            BackgroundTransparency = 0.08,
            BorderSizePixel = 0,
            Active = false,
            ZIndex = 7,
        })
        UIFactory.PillCorner(arcSeg)
        table.insert(aimDashSegments, arcSeg)
    end

    local aimDiamond = UIFactory.Create("Frame", aimReticle, {
        Name = "InnerGoldDiamond",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(18, 18),
        Rotation = 45,
        BackgroundTransparency = 1,
        Active = false,
        ZIndex = 7,
    })
    UIFactory.Corner(aimDiamond, 2)
    local aimDiamondStroke = UIFactory.Stroke(aimDiamond, Color3.fromRGB(253, 224, 71), 1.7, 0.05)

    local aimCoreDot = UIFactory.Create("Frame", aimReticle, {
        Name = "AimCoreDot",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(6, 6),
        BackgroundColor3 = Color3.fromRGB(251, 55, 98),
        BorderSizePixel = 0,
        Active = false,
        ZIndex = 8,
    })
    UIFactory.PillCorner(aimCoreDot)
    local aimCoreStroke = UIFactory.Stroke(aimCoreDot, Color3.fromRGB(10, 14, 24), 1.2, 0.15)

    local aimModePill = UIFactory.Create("Frame", aimReticle, {
        Name = "AimLockPill",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 1, 4),
        Size = UDim2.fromOffset(118, 16),
        BackgroundColor3 = Color3.fromRGB(9, 13, 24),
        BackgroundTransparency = 0.12,
        BorderSizePixel = 0,
        Visible = false,
        Active = false,
        ZIndex = 8,
    })
    UIFactory.PillCorner(aimModePill)
    local aimModeStroke = UIFactory.Stroke(aimModePill, Color3.fromRGB(251, 55, 98), 1.1, 0.15)
    local aimModeLabel = UIFactory.Label(aimModePill, {
        Name = "AimModeText",
        Text = "AIM",
        Size = UDim2.fromScale(1, 1),
        TextSize = 8,
        TextColor = Color3.fromRGB(254, 226, 138),
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = 9,
    })

    local function pulseAimReticle()
        aimReticleScale.Scale = 1.24
        UIAnimator.Tween(aimReticleScale, { Scale = 1.0 }, 0.16)
    end

    -- 4D. Curved 3-Segment Cyan Dash/Dodge Arc ("LƯỚT 2/3") — Touch/Mobile only; hidden on Desktop where [Q] + bottom-right HUD handles Dash
    local dashCluster = UIFactory.Create("Frame", root, {
        Name = "DashDodgeCluster",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(isMobile and 0.34 or 0.37, isMobile and 0.56 or 0.61),
        Size = UDim2.fromOffset(110, 118),
        BackgroundTransparency = 1,
        ClipsDescendants = false,
        Visible = UserInputService.TouchEnabled,
        Active = false,
        ZIndex = 6,
    })

    -- Smooth Right-Curving 3-Segment Crescent Arc (Top = Charge 3, Mid = Charge 2, Bot = Charge 1)
    local dashArcBeads = { {}, {}, {} }
    local segAngles = {
        { -44, -37.5, -31, -24.5, -18 },
        { -12, -6, 0, 6, 12 },
        { 18, 24.5, 31, 37.5, 44 },
    }
    local arcRadius = 54
    local arcCenterX = -18
    for segIdx = 1, 3 do
        for bIdx, deg in ipairs(segAngles[segIdx]) do
            local rad = math.rad(deg)
            local bx = arcCenterX + math.cos(rad) * arcRadius
            local by = math.sin(rad) * arcRadius
            local bead = UIFactory.Create("Frame", dashCluster, {
                Name = string.format("DashArc_%d_%d", segIdx, bIdx),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new(0.5, bx, 0.5, by),
                Size = UDim2.fromOffset(5, 10),
                Rotation = deg,
                BackgroundColor3 = Color3.fromRGB(56, 224, 255),
                BorderSizePixel = 0,
                Active = false,
                ZIndex = 7,
            })
            UIFactory.PillCorner(bead)
            table.insert(dashArcBeads[segIdx], bead)
        end
    end

    local dashCountPill = UIFactory.Create("Frame", dashCluster, {
        Name = "DashCountPill",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0.5, 42, 0.5, 6),
        Size = UDim2.fromOffset(64, 20),
        BackgroundColor3 = Color3.fromRGB(8, 16, 28),
        BackgroundTransparency = 0.06,
        BorderSizePixel = 0,
        Active = false,
        ZIndex = 8,
    })
    UIFactory.PillCorner(dashCountPill)
    local dashCountStroke = UIFactory.Stroke(dashCountPill, Color3.fromRGB(56, 189, 248), 1.2, 0.12)
    local dashCountLabel = UIFactory.Label(dashCountPill, {
        Name = "DashCountText",
        Text = I18n.Pick("LƯỚT 3/3", "DASH 3/3"),
        Size = UDim2.fromScale(1, 1),
        TextSize = 9,
        TextColor = Color3.fromRGB(224, 246, 255),
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Wrapped = false,
        ZIndex = 9,
    })

    local perfectDodgePill = UIFactory.Create("Frame", dashCluster, {
        Name = "PerfectDodgeCallout",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(0.5, 16, 0.5, 8),
        Size = UDim2.fromOffset(154, 26),
        BackgroundColor3 = Color3.fromRGB(7, 20, 36),
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        Visible = false,
        Active = false,
        ZIndex = 9,
    })
    UIFactory.PillCorner(perfectDodgePill)
    local perfectDodgeStroke = UIFactory.Stroke(perfectDodgePill, Color3.fromRGB(34, 211, 238), 1.5, 0.04)
    local perfectDodgeScale = Instance.new("UIScale")
    perfectDodgeScale.Scale = 1.0
    perfectDodgeScale.Parent = perfectDodgePill

    local pdSpark = UIFactory.Create("Frame", perfectDodgePill, {
        Name = "CyanSpark",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 11, 0.5, 0),
        Size = UDim2.fromOffset(7, 7),
        Rotation = 45,
        BackgroundColor3 = Color3.fromRGB(103, 232, 249),
        BorderSizePixel = 0,
        Active = false,
        ZIndex = 10,
    })
    UIFactory.Corner(pdSpark, 1)

    local perfectDodgeLabel = UIFactory.Label(perfectDodgePill, {
        Name = "CalloutText",
        Text = I18n.Pick("NÉ HOÀN HẢO! +25 EN", "PERFECT DODGE! +25 EN"),
        Position = UDim2.fromOffset(24, 0),
        Size = UDim2.new(1, -30, 1, 0),
        TextSize = 10,
        TextColor = Color3.fromRGB(125, 243, 255),
        Bold = true,
        XAlign = Enum.TextXAlignment.Left,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = 10,
    })

    local function pruneAndCountDashCharges(nowClock)
        local st = HUD.DashState
        local kept = {}
        for _, spentAt in ipairs(st.SpentClocks) do
            if (nowClock - spentAt) < st.RechargeSec then
                table.insert(kept, spentAt)
            end
        end
        st.SpentClocks = kept
        return math.clamp(st.MaxCharges - #kept, 0, st.MaxCharges)
    end

    local function isEnemyWithinDodgeRange()
        local ch = player and player.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if not hrp then
            return false
        end
        local pPos = hrp.Position
        for _, fn in ipairs({ "ActiveBosses", "ActiveEnemies" }) do
            local f = workspace:FindFirstChild(fn)
            if f then
                for _, m in ipairs(f:GetChildren()) do
                    local part = m:IsA("Model") and (m.PrimaryPart or m:FindFirstChild("Body") or m:FindFirstChildWhichIsA("BasePart")) or nil
                    if part and (part.Position - pPos).Magnitude <= 34 then
                        return true
                    end
                end
            end
        end
        return false
    end

    local function triggerDodgeFeedback(isPerfectExplicit, spendCharge)
        local now = os.clock()
        local st = HUD.DashState
        if spendCharge then
            if (now - st.LastConsumeClock) < 0.18 then
                return
            end
            st.LastConsumeClock = now
            pruneAndCountDashCharges(now)
            if #st.SpentClocks < st.MaxCharges then
                table.insert(st.SpentClocks, now)
            else
                st.SpentClocks[1] = now
            end
        end

        local kenActive = (player and (player:GetAttribute("InstinctActive") == true or player:GetAttribute("HakiInstinct") == true))
            or (player and player.Character and player.Character:GetAttribute("HakiInstinct") == true)
        local isPerfect = (isPerfectExplicit == true) or kenActive or isEnemyWithinDodgeRange()

        if isPerfect then
            perfectDodgeLabel.Text = I18n.Pick("NÉ HOÀN HẢO! +25 EN", "PERFECT DODGE! +25 EN")
            perfectDodgeStroke.Color = Color3.fromRGB(34, 211, 238)
            pdSpark.BackgroundColor3 = Color3.fromRGB(103, 232, 249)
        else
            perfectDodgeLabel.Text = I18n.Pick("LƯỚT NÉ AETHER!", "AETHER EVADE!")
            perfectDodgeStroke.Color = Color3.fromRGB(56, 189, 248)
            pdSpark.BackgroundColor3 = Color3.fromRGB(125, 211, 252)
        end

        st.CalloutUntil = now + 1.85
        perfectDodgePill.Visible = true
        perfectDodgeScale.Scale = 1.18
        UIAnimator.Tween(perfectDodgeScale, { Scale = 1.0 }, 0.18)
    end

    local function bindCharacterDashSignals(ch)
        if not ch then
            return
        end
        table.insert(HUD.Connections, ch:GetAttributeChangedSignal("LastDashAt"):Connect(function()
            local ts = tonumber(ch:GetAttribute("LastDashAt")) or 0
            if ts > 0 then
                triggerDodgeFeedback(false, true)
            end
        end))
    end
    if player then
        if player.Character then
            bindCharacterDashSignals(player.Character)
        end
        table.insert(HUD.Connections, player.CharacterAdded:Connect(bindCharacterDashSignals))
    end


    local function registerComboHit(explicitCount)
        local now = os.clock()
        if type(explicitCount) == "number" and explicitCount > 0 then
            HUD.ComboState.Count = math.floor(explicitCount)
        else
            if (now - HUD.ComboState.LastHitClock) <= HUD.ComboState.WindowSec then
                HUD.ComboState.Count = HUD.ComboState.Count + 1
            else
                HUD.ComboState.Count = 1
            end
        end
        HUD.ComboState.LastHitClock = now

        if HUD.ComboState.Count >= 2 then
            local rankGrade, rankCol, rankTitle = resolveComboRankMeta(HUD.ComboState.Count)
            comboCard.Visible = true
            comboGradeLabel.Text = rankGrade
            comboGradeStroke.Color = rankCol
            if rankGrade == "SS" then
                comboGradeGrad.Color = ColorSequence.new(Color3.fromRGB(255, 132, 158), Color3.fromRGB(186, 28, 92))
                comboGradeLabel.TextColor3 = Color3.fromRGB(255, 250, 252)
            elseif rankGrade == "S" then
                comboGradeGrad.Color = ColorSequence.new(Color3.fromRGB(252, 214, 104), Color3.fromRGB(196, 136, 32))
                comboGradeLabel.TextColor3 = Color3.fromRGB(14, 18, 30)
            elseif rankGrade == "A" then
                comboGradeGrad.Color = ColorSequence.new(Color3.fromRGB(216, 156, 255), Color3.fromRGB(118, 42, 212))
                comboGradeLabel.TextColor3 = Color3.fromRGB(255, 250, 255)
            else
                comboGradeGrad.Color = ColorSequence.new(Color3.fromRGB(84, 214, 255), Color3.fromRGB(24, 98, 206))
                comboGradeLabel.TextColor3 = Color3.fromRGB(250, 254, 255)
            end
            comboCountLabel.Text = string.format("<b>%d</b> <font size='11'>COMBO HITS</font>", HUD.ComboState.Count)
            comboTitleLabel.Text = rankTitle
            comboTimerFill.Size = UDim2.fromScale(1, 1)
            comboTimerFill.BackgroundColor3 = rankCol
        end
    end

    local function bindComboRemotes()
        local remotes = ReplicatedStorage:FindFirstChild("Remotes")
        if remotes then
            for _, remoteName in ipairs({ "CombatFX", "CombatEvent" }) do
                local ev = remotes:FindFirstChild(remoteName)
                if ev and ev:IsA("RemoteEvent") then
                    table.insert(HUD.Connections, ev.OnClientEvent:Connect(function(payload, arg2)
                        if type(payload) == "table" then
                            local kind = tostring(payload.Kind or payload.kind or "")
                            local action = tostring(payload.Action or payload.action or payload.type or payload.fx or "")
                            local skillId = tostring(payload.skillId or payload.SkillId or "")
                            local actorId = tonumber(payload.Actor or payload.Owner or payload.userId)
                            local isMine = (actorId == nil) or (player and actorId == player.UserId)

                            if (action == "ConquerorHaki" or action == "ConquerorBurst" or skillId == "ConquerorHaki") and isMine then
                                HUD.ConquerorUntil = workspace:GetServerTimeNow() + 4.0
                            end

                            if kind == "InstinctDodge" or action == "InstinctDodge" or payload.Dodge == true or payload.LogiaDodge == true then
                                if isMine then
                                    triggerDodgeFeedback(true, false)
                                end
                            elseif kind == "Dodge" or action == "Dash" or action == "Dodge" or action == "FlashStep" then
                                if isMine then
                                    triggerDodgeFeedback(false, true)
                                end
                            elseif payload.comboCount or payload.combo then
                                registerComboHit(tonumber(payload.comboCount or payload.combo))
                                pulseAimReticle()
                            elseif kind == "DamageNumber" or kind == "Hit" or kind == "GunShot" or action == "Hit" or action == "Damage" or action == "SlashHit" or payload.damage or payload.amount or payload.Amount then
                                local rawTxt = UIFactory.Upper(tostring(payload.Text or payload.text or payload.amount or payload.Amount or ""))
                                local isHealOrMiss = rawTxt:find("HP", 1, true) ~= nil or rawTxt:find("DODGE", 1, true) ~= nil or rawTxt:find("MISS", 1, true) ~= nil
                                if not isHealOrMiss and (payload.attacker == nil or payload.attacker == player) then
                                    registerComboHit(nil)
                                    pulseAimReticle()
                                end
                            end
                        elseif type(payload) == "string" then
                            local pLow = string.lower(payload)
                            if string.find(pLow, "hit", 1, true) or string.find(pLow, "damage", 1, true) or string.find(pLow, "combo", 1, true) then
                                registerComboHit(type(arg2) == "number" and arg2 or nil)
                                pulseAimReticle()
                            end
                        end
                    end))
                end
            end
        end

        if player then
            table.insert(HUD.Connections, player:GetAttributeChangedSignal("ComboCount"):Connect(function()
                local c = tonumber(player:GetAttribute("ComboCount")) or 0
                if c >= 2 then
                    registerComboHit(c)
                elseif c == 0 then
                    HUD.ComboState.Count = 0
                    comboCard.Visible = false
                end
            end))
        end
    end
    bindComboRemotes()

    -- 5. Contextual [E] INTERACT Prompt Pill above Combat Dock
    local interactBtn, interactApi = PremiumButton.Create(root, {
        name = "ContextInteractPrompt",
        text = "[E]  •  " .. tostring((view.interactPrompt and view.interactPrompt.label) or I18n.Pick("TƯƠNG TÁC", "INTERACT")),
        variant = "gold",
        icon = "Sparkle",
        anchorPoint = Vector2.new(0.5, 1),
        position = isPortrait and UDim2.new(0.5, 0, 1, -372) or UDim2.new(0.5, 0, 1, isMobile and -112 or -138),
        size = UDim2.fromOffset(224, 34),
        textSize = 12,
        onActivated = function()
            HUDController.TriggerAction("Interact")
        end,
    })
    interactBtn.Visible = (view.interactPrompt and view.interactPrompt.visible) == true

    -- Zero-overlap horizontal offset: Desktop QuickNavDock (x = 12..258) | Mobile shifts clear of Left Thumbstick & Right TouchArc
    local combatOffsetX = isMobile and 0 or 28
    local hudArcVp = viewportVec or Vector2.new(1366, 768)
    local hudArcScale = math.max(0.1, (responsiveState and responsiveState.UIScale) or 1)
    local hudJumpClearPx = (math.min(hudArcVp.X, hudArcVp.Y) <= 500) and 104 or 180
    local hudArcShiftX = math.ceil(hudJumpClearPx / hudArcScale)
    local hudCanvasW = (responsiveState and responsiveState.CanvasWidth) or math.floor(hudArcVp.X / hudArcScale)
    local touchArcLeftX = hudCanvasW - 14 - hudArcShiftX - 236
    local mobileSafeRightX = math.max(460, touchArcLeftX - 10)

    -- 6. Obsidian-Gold Quick Dock (Desktop: Bottom-Left 3x2 Grid | Mobile: Safe Center-Left Strip clear of Thumbstick + Map [M])
    local quickNavDefs = {
        { key = "ESC", labelVi = "Menu",    labelEn = "Menu",   icon = "Settings", route = UIState.Screens.MainMenu,      style = "obsidian", mobileKeep = true },
        { key = "I",   labelVi = "Túi",     labelEn = "Bag",    icon = "Bag",      route = UIState.Screens.Inventory,     style = "obsidian", mobileKeep = true },
        { key = "K",   labelVi = "Kỹ Năng", labelEn = "Skills", icon = "Skill",    route = UIState.Screens.Skills,        style = "obsidian", mobileKeep = true },
        { key = "G",   labelVi = "Kho Lõi", labelEn = "Cores",  icon = "Fruit",    route = UIState.Screens.Fruits,        style = "gold",     mobileKeep = true },
        { key = "M",   labelVi = "Bản Đồ",  labelEn = "Map",    icon = "Compass",  route = UIState.Screens.WorldMap,      style = "obsidian", mobileKeep = true, mobileOnly = true },
        { key = "L",   labelVi = "Nhật Ký", labelEn = "Quests", icon = "Quest",    route = UIState.Screens.QuestJournal,  style = "obsidian", mobileKeep = false },
        { key = "B",   labelVi = "Quà",     labelEn = "Gifts",  icon = "Gift",     route = UIState.Screens.SocialRewards, style = "sapphire", mobileKeep = true },
    }

    local activeQuickDefs = {}
    for _, qd in ipairs(quickNavDefs) do
        if isMobile then
            if qd.mobileKeep then
                table.insert(activeQuickDefs, qd)
            end
        elseif not qd.mobileOnly then
            table.insert(activeQuickDefs, qd)
        end
    end

    local qTileW = isMobile and 38 or 46
    local qTileH = isMobile and 40 or 42
    local qGap = 4
    local qCols = isMobile and #activeQuickDefs or 3
    local qRows = math.max(1, math.ceil(#activeQuickDefs / qCols))
    local quickDockW = (qCols * qTileW) + ((qCols - 1) * qGap) + (isMobile and 12 or 14)
    local quickDockH = (qRows * qTileH) + ((qRows - 1) * qGap) + (isMobile and 10 or 12)

    local quickDockAnchor = isPortrait and Vector2.new(0.5, 1) or (isMobile and Vector2.new(1, 1) or Vector2.new(0, 1))
    local quickDockPos = isPortrait
        and UDim2.new(0.5, 0, 1, -320)
        or (isMobile and UDim2.new(0, mobileSafeRightX, 1, -44) or UDim2.new(0, 12, 1, -10))

    local quickDock = PremiumPanel.Create(root, {
        name = "QuickNavDock",
        variant = "gold",
        anchorPoint = quickDockAnchor,
        position = quickDockPos,
        size = UDim2.fromOffset(quickDockW, quickDockH),
        transparency = 0.06,
        clipsDescendants = false,
        zIndex = 6,
    })

    -- Early-Game Onboarding Callout Pill ([K] Unspent Stat Points + [L] Auto-Repeat Quest tip)
    local statCalloutBtn = UIFactory.Create("TextButton", root, {
        Name = "StatOnboardingCallout",
        Position = UDim2.fromOffset(16, 304),
        Size = UDim2.fromOffset(314, 26),
        BackgroundColor3 = Color3.fromRGB(28, 22, 10),
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Visible = false,
        ZIndex = 7,
    })
    UIFactory.PillCorner(statCalloutBtn)
    UIFactory.Stroke(statCalloutBtn, colors.ACCENT_GOLD_BRIGHT, 1.4, 0.08)
    UIFactory.Gradient(statCalloutBtn, Color3.fromRGB(48, 36, 14), Color3.fromRGB(20, 16, 10), 90)
    local statCalloutLabel = UIFactory.Label(statCalloutBtn, {
        Name = "CalloutText",
        Text = "",
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -20, 1, 0),
        TextSize = 10,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = 8,
    })
    UIFactory.TextSizeConstraint(statCalloutLabel, 8, 10)
    statCalloutBtn.Activated:Connect(function()
        ScreenRouter.ToggleScreen(UIState.Screens.Skills)
    end)

    local quickTilesRow = UIFactory.Create("Frame", quickDock, {
        Name = "QuickTilesRow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.new(1, -10, 1, -10),
        BackgroundTransparency = 1,
        ClipsDescendants = false,
        ZIndex = 7,
    })
    if isMobile then
        UIFactory.ListLayout(quickTilesRow, Enum.FillDirection.Horizontal, qGap, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
    else
        local qGrid = Instance.new("UIGridLayout")
        qGrid.CellSize = UDim2.fromOffset(qTileW, qTileH)
        qGrid.CellPadding = UDim2.fromOffset(qGap, qGap)
        qGrid.FillDirectionMaxCells = qCols
        qGrid.HorizontalAlignment = Enum.HorizontalAlignment.Left
        qGrid.VerticalAlignment = Enum.VerticalAlignment.Center
        qGrid.SortOrder = Enum.SortOrder.LayoutOrder
        qGrid.Parent = quickTilesRow
    end

    local QUICK_STYLES = {
        obsidian = {
            Top = Color3.fromRGB(22, 34, 58),
            Bottom = Color3.fromRGB(10, 16, 28),
            Border = Color3.fromRGB(84, 110, 152),
            Icon = Color3.fromRGB(228, 236, 252),
            Text = Color3.fromRGB(224, 232, 248),
        },
        gold = {
            Top = Color3.fromRGB(252, 212, 98),
            Bottom = Color3.fromRGB(186, 114, 20),
            Border = Color3.fromRGB(255, 244, 176),
            Icon = Color3.fromRGB(20, 18, 12),
            Text = Color3.fromRGB(20, 18, 12),
        },
        sapphire = {
            Top = Color3.fromRGB(56, 189, 248),
            Bottom = Color3.fromRGB(29, 78, 216),
            Border = Color3.fromRGB(162, 230, 255),
            Icon = Color3.fromRGB(250, 253, 255),
            Text = Color3.fromRGB(250, 253, 255),
        },
        crimson = {
            Top = Color3.fromRGB(251, 68, 106),
            Bottom = Color3.fromRGB(159, 18, 57),
            Border = Color3.fromRGB(255, 182, 200),
            Icon = Color3.fromRGB(255, 250, 252),
            Text = Color3.fromRGB(255, 250, 252),
        },
    }

    local statPointsBadge = nil
    local statPointsBadgeLabel = nil
    local skillsNavTileStroke = nil

    for idx, qd in ipairs(activeQuickDefs) do
        local st = QUICK_STYLES[qd.style] or QUICK_STYLES.obsidian
        local isAccent = (qd.style ~= "obsidian")

        local tile = UIFactory.Create("TextButton", quickTilesRow, {
            Name = "Nav_" .. qd.key,
            Size = UDim2.fromOffset(qTileW, qTileH),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 0.02,
            BorderSizePixel = 0,
            ClipsDescendants = false,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = idx,
            ZIndex = 8,
        })
        UIFactory.Corner(tile, 8)
        local tileStroke = UIFactory.Stroke(tile, st.Border, isAccent and 1.6 or 1.2, isAccent and 0.04 or 0.24)
        UIFactory.Gradient(tile, st.Top, st.Bottom, 90)

        if qd.key == "K" then
            skillsNavTileStroke = tileStroke
            statPointsBadge = UIFactory.Create("Frame", tile, {
                Name = "StatPointsBadge",
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.fromOffset(-4, -5),
                Size = UDim2.fromOffset(26, 15),
                AutomaticSize = Enum.AutomaticSize.X,
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                Visible = false,
                Active = false,
                ZIndex = 15,
            })
            UIFactory.PillCorner(statPointsBadge)
            UIFactory.Padding(statPointsBadge, 0, 5, 0, 5)
            UIFactory.Stroke(statPointsBadge, Color3.fromRGB(255, 240, 154), 1.4, 0.0)
            UIFactory.Gradient(statPointsBadge, Color3.fromRGB(251, 55, 98), Color3.fromRGB(217, 119, 6), 45)
            statPointsBadgeLabel = UIFactory.Label(statPointsBadge, {
                Name = "BadgeCount",
                Text = "+3",
                Size = UDim2.fromOffset(0, 15),
                TextSize = 9,
                TextColor = Color3.fromRGB(255, 252, 235),
                Bold = true,
                XAlign = Enum.TextXAlignment.Center,
                Wrapped = false,
                ZIndex = 16,
            })
            statPointsBadgeLabel.AutomaticSize = Enum.AutomaticSize.X
        end

        local tileScale = Instance.new("UIScale")
        tileScale.Scale = 1.0
        tileScale.Parent = tile

        if isAccent then
            local gloss = UIFactory.Create("Frame", tile, {
                Name = "TopGloss",
                Position = UDim2.fromOffset(2, 2),
                Size = UDim2.new(1, -4, 0.38, 0),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = 0.78,
                BorderSizePixel = 0,
                Active = false,
                ZIndex = 9,
            })
            UIFactory.Corner(gloss, 6)
        end

        local qIcon = UIFactory.Icon(
            tile,
            qd.icon,
            UDim2.new(0.5, -8, 0, 6),
            16,
            st.Icon
        )
        qIcon.ZIndex = 10

        local qCaption = UIFactory.Label(tile, {
            Name = "Caption",
            Text = I18n.Pick(qd.labelVi, qd.labelEn),
            Position = UDim2.new(0, 1, 1, -15),
            Size = UDim2.new(1, -2, 0, 13),
            TextSize = 8,
            TextColor = st.Text,
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            Truncate = Enum.TextTruncate.AtEnd,
            Wrapped = false,
            ZIndex = 10,
        })
        UIFactory.TextSizeConstraint(qCaption, 7, 9)

        if not isMobile then
            local keyW = (#qd.key >= 3) and 19 or 13
            local kBadge = UIFactory.Create("Frame", tile, {
                Name = "HotkeyBadge",
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -2, 0, 2),
                Size = UDim2.fromOffset(keyW, 11),
                BackgroundColor3 = Color3.fromRGB(8, 12, 22),
                BackgroundTransparency = 0.08,
                BorderSizePixel = 0,
                Active = false,
                ZIndex = 11,
            })
            UIFactory.Corner(kBadge, 3)
            UIFactory.Label(kBadge, {
                Name = "KeyText",
                Text = qd.key,
                Size = UDim2.fromScale(1, 1),
                TextSize = 7,
                TextColor = Color3.fromRGB(246, 232, 184),
                Bold = true,
                XAlign = Enum.TextXAlignment.Center,
                Wrapped = false,
                ZIndex = 12,
            })
        end

        tile.MouseEnter:Connect(function()
            UIAnimator.Tween(tileScale, { Scale = 1.06 }, MotionTokens.hoverFast.duration)
            tileStroke.Color = colors.ACCENT_GOLD_BRIGHT
        end)
        tile.MouseLeave:Connect(function()
            UIAnimator.Tween(tileScale, { Scale = 1.0 }, MotionTokens.hoverFast.duration)
            tileStroke.Color = st.Border
        end)
        tile.Activated:Connect(function()
            if qd.route == UIState.Screens.Fruits then
                Store.SetView({ fruitsMode = "Vault" })
            end
            ScreenRouter.ToggleScreen(qd.route)
        end)
    end

    -- 7. Bottom-Center Loadout Hotbar [1]-[4] (Full Glossy Champagne Gold Pill for Active Slot)
    local activeSlotIdx = tonumber((player and player:GetAttribute("ActiveSlot")) or view.activeHotbarSlot) or 1

    local function resolveLoadoutSlotNames(snapshot)
        local names = {}
        for sIdx = 1, 4 do
            local _, itemText = I18n.GetHotbarSlotSummary(sIdx, snapshot)
            names[sIdx] = tostring(itemText or "")
        end
        return names
    end

    local slotNames = resolveLoadoutSlotNames(snap)
    local pillW = isMobile and 64 or 136
    local pillGap = isMobile and 5 or 8
    local loadoutTotalW = (4 * pillW) + (3 * pillGap)
    local loadoutAnchor = isPortrait and Vector2.new(0.5, 1) or (isMobile and Vector2.new(1, 1) or Vector2.new(0.5, 1))
    local loadoutPos = isPortrait
        and UDim2.new(0.5, 0, 1, -284)
        or (isMobile and UDim2.new(0, mobileSafeRightX, 1, -10) or UDim2.new(0.5, combatOffsetX, 1, -98))

    local loadoutBar = UIFactory.Create("Frame", root, {
        Name = "LoadoutHotbar1To4",
        AnchorPoint = loadoutAnchor,
        Position = loadoutPos,
        Size = UDim2.fromOffset(loadoutTotalW, 30),
        BackgroundTransparency = 1,
        ZIndex = 7,
    })
    UIFactory.ListLayout(loadoutBar, Enum.FillDirection.Horizontal, pillGap, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)

    local loadoutSlotRefs = {}
    local function applyLoadoutPillVisual(ref, isActive, slotLabelText)
        local cleanText = tostring(slotLabelText or "")
        if isActive then
            ref.Grad.Color = ColorSequence.new(Color3.fromRGB(251, 215, 110), Color3.fromRGB(198, 136, 32))
            ref.Stroke.Color = Color3.fromRGB(255, 243, 184)
            ref.Stroke.Thickness = 2.0
            ref.Stroke.Transparency = 0.0
            ref.Gloss.Visible = true
            ref.Scale.Scale = 1.04
            ref.KeyBox.BackgroundColor3 = Color3.fromRGB(14, 20, 34)
            ref.KeyLabel.TextColor3 = Color3.fromRGB(255, 232, 156)
            ref.NameLabel.TextColor3 = Color3.fromRGB(14, 18, 30)
            ref.NameLabel.Text = isMobile and UIFactory.Upper(cleanText) or ("* " .. UIFactory.Upper(cleanText))
        else
            ref.Grad.Color = ColorSequence.new(Color3.fromRGB(22, 34, 58), Color3.fromRGB(11, 18, 33))
            ref.Stroke.Color = colors.STROKE_STEEL
            ref.Stroke.Thickness = 1.2
            ref.Stroke.Transparency = 0.20
            ref.Gloss.Visible = false
            ref.Scale.Scale = 1.0
            ref.KeyBox.BackgroundColor3 = Color3.fromRGB(8, 13, 24)
            ref.KeyLabel.TextColor3 = Color3.fromRGB(168, 194, 232)
            ref.NameLabel.TextColor3 = Color3.fromRGB(218, 228, 246)
            ref.NameLabel.Text = cleanText
        end
    end

    for slotIdx = 1, 4 do
        local pillBtn = UIFactory.Create("TextButton", loadoutBar, {
            Name = "LoadoutSlot_" .. tostring(slotIdx),
            Size = UDim2.fromOffset(pillW, 28),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 0.02,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = slotIdx,
            ZIndex = 8,
        })
        UIFactory.PillCorner(pillBtn)
        local pStroke = UIFactory.Stroke(pillBtn, colors.STROKE_STEEL, 1.2, 0.2)
        local pGrad = UIFactory.Gradient(pillBtn, Color3.fromRGB(22, 34, 58), Color3.fromRGB(11, 18, 33), 90)

        local pScale = Instance.new("UIScale")
        pScale.Scale = 1.0
        pScale.Parent = pillBtn

        local pGloss = UIFactory.Create("Frame", pillBtn, {
            Name = "TopGloss",
            Position = UDim2.fromOffset(4, 2),
            Size = UDim2.new(1, -8, 0.42, 0),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BackgroundTransparency = 0.76,
            BorderSizePixel = 0,
            Visible = false,
            Active = false,
            ZIndex = 9,
        })
        UIFactory.PillCorner(pGloss)

        local keyBox = UIFactory.Create("Frame", pillBtn, {
            Name = "KeyBadge",
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 5, 0.5, 0),
            Size = UDim2.fromOffset(18, 18),
            BackgroundColor3 = Color3.fromRGB(8, 13, 24),
            BorderSizePixel = 0,
            Active = false,
            ZIndex = 10,
        })
        UIFactory.PillCorner(keyBox)
        local keyLbl = UIFactory.Label(keyBox, {
            Name = "KeyText",
            Text = tostring(slotIdx),
            Size = UDim2.fromScale(1, 1),
            TextSize = 10,
            TextColor = Color3.fromRGB(168, 194, 232),
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            Wrapped = false,
            ZIndex = 11,
        })

        local iconOffset = 27
        if not isMobile then
            local sIcon = UIFactory.Icon(
                pillBtn,
                SLOT_ICONS[slotIdx] or "Sword",
                UDim2.new(0, 27, 0.5, -7),
                14,
                Color3.fromRGB(236, 206, 128)
            )
            sIcon.ZIndex = 10
            iconOffset = 44
        end

        local nameLbl = UIFactory.Label(pillBtn, {
            Name = "SlotName",
            Text = slotNames[slotIdx],
            Position = UDim2.fromOffset(iconOffset, 0),
            Size = UDim2.new(1, -(iconOffset + 6), 1, 0),
            TextSize = isMobile and 9 or 10,
            TextColor = Color3.fromRGB(218, 228, 246),
            Bold = true,
            Truncate = Enum.TextTruncate.AtEnd,
            Wrapped = false,
            ZIndex = 10,
        })

        local ref = {
            Button = pillBtn,
            Stroke = pStroke,
            Grad = pGrad,
            Gloss = pGloss,
            Scale = pScale,
            KeyBox = keyBox,
            KeyLabel = keyLbl,
            NameLabel = nameLbl,
        }
        loadoutSlotRefs[slotIdx] = ref
        applyLoadoutPillVisual(ref, slotIdx == activeSlotIdx, slotNames[slotIdx])

        pillBtn.Activated:Connect(function()
            HUDController.SelectHotbarSlot(slotIdx)
        end)
    end

    -- Stage 1: Bilingual Skill Archetype & Mechanical Tag Hover Tooltip (Desktop) / Transient Slot Callout (Mobile)
    local mechTooltip = nil
    local mechTooltipTitle = nil
    local mechTooltipTags = nil
    local mobileArchCallout = nil
    local mobileArchLabel = nil

    local function buildCurrentBlueprintCtx()
        local curSnap = Store.GetSnapshot()
        local chNow = player and player.Character
        return {
            Awakened = (curSnap and curSnap.fruits and curSnap.fruits.awakened == true) or (player and player:GetAttribute("FruitAwakened") == true) or false,
            DragonFormTier = tonumber((chNow and chNow:GetAttribute("DragonFormTier")) or (player and player:GetAttribute("DragonFormTier")) or (curSnap and curSnap.raw and curSnap.raw.DragonFormTier)) or 0,
            FruitTransform = tostring((chNow and chNow:GetAttribute("FruitTransform")) or (player and player:GetAttribute("FruitTransform")) or ""),
        }, curSnap, chNow
    end

    if not isMobile then
        mechTooltip = UIFactory.Create("Frame", root, {
            Name = "SkillMechanicsTooltip",
            AnchorPoint = Vector2.new(0.5, 1),
            Position = UDim2.new(0.5, combatOffsetX, 1, -134),
            Size = UDim2.fromOffset(396, 40),
            BackgroundColor3 = Color3.fromRGB(9, 14, 26),
            BackgroundTransparency = 0.04,
            BorderSizePixel = 0,
            Visible = false,
            Active = false,
            ZIndex = 18,
        })
        UIFactory.Corner(mechTooltip, 8)
        UIFactory.Stroke(mechTooltip, colors.ACCENT_GOLD_BRIGHT, 1.3, 0.14)

        mechTooltipTitle = UIFactory.Label(mechTooltip, {
            Name = "Title",
            Text = "",
            Position = UDim2.fromOffset(10, 3),
            Size = UDim2.new(1, -20, 0, 17),
            TextSize = 10,
            TextColor = colors.ACCENT_GOLD_BRIGHT,
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            Truncate = Enum.TextTruncate.AtEnd,
            Wrapped = false,
            ZIndex = 19,
        })

        mechTooltipTags = UIFactory.Label(mechTooltip, {
            Name = "Tags",
            Text = "",
            Position = UDim2.fromOffset(10, 20),
            Size = UDim2.new(1, -20, 0, 16),
            TextSize = 9,
            TextColor = Color3.fromRGB(168, 236, 255),
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            Truncate = Enum.TextTruncate.AtEnd,
            Wrapped = false,
            ZIndex = 19,
        })

        for sIdx = 1, 4 do
            local pRef = loadoutSlotRefs[sIdx]
            if pRef and pRef.Button then
                pRef.Button.MouseEnter:Connect(function()
                    local ctxNow, curSnap = buildCurrentBlueprintCtx()
                    local itemId = resolveSlotItemAndMastery(sIdx, curSnap, player)
                    local slotCat, itemDisp = I18n.GetHotbarSlotSummary(sIdx, curSnap)
                    local archMeta = I18n.GetSlotArchetypeMeta(sIdx, itemId, ctxNow)
                    mechTooltipTitle.Text = string.format("[%d] %s: %s  •  %s", sIdx, slotCat, itemDisp, archMeta.archetypeLabel)
                    if sIdx == 2 and itemId == "" then
                        mechTooltipTags.Text = I18n.Pick("Mở [G] Lõi Aether để trang bị kỹ năng", "Open [G] Cores to equip an Aether Core")
                    else
                        local keys = (sIdx == 1 and { "Z", "X", "C" }) or (sIdx == 2 and { "Z", "X", "C", "V", "F" }) or { "Z", "X" }
                        local parts = {}
                        for _, mk in ipairs(keys) do
                            local mm = I18n.GetSkillMechanicsMeta(sIdx, itemId, mk, ctxNow)
                            if mm.primaryTag ~= "" then
                                table.insert(parts, string.format("[%s] %s", mk, mm.primaryTag))
                            end
                        end
                        mechTooltipTags.Text = table.concat(parts, "  •  ")
                    end
                    mechTooltip.Visible = true
                end)
                pRef.Button.MouseLeave:Connect(function()
                    mechTooltip.Visible = false
                end)
            end
        end
    else
        mobileArchCallout = UIFactory.Create("Frame", root, {
            Name = "MobileArchetypeCallout",
            AnchorPoint = loadoutAnchor,
            Position = loadoutPos - UDim2.fromOffset(0, 34),
            Size = UDim2.fromOffset(loadoutTotalW, 18),
            BackgroundColor3 = Color3.fromRGB(9, 14, 26),
            BackgroundTransparency = 0.08,
            BorderSizePixel = 0,
            Visible = false,
            Active = false,
            ZIndex = 12,
        })
        UIFactory.PillCorner(mobileArchCallout)
        UIFactory.Stroke(mobileArchCallout, colors.ACCENT_GOLD_BRIGHT, 1.1, 0.2)
        mobileArchLabel = UIFactory.Label(mobileArchCallout, {
            Name = "ArchText",
            Text = "",
            Position = UDim2.fromOffset(6, 0),
            Size = UDim2.new(1, -12, 1, 0),
            TextSize = 8,
            TextColor = colors.ACCENT_GOLD_BRIGHT,
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            Truncate = Enum.TextTruncate.AtEnd,
            Wrapped = false,
            ZIndex = 13,
        })
    end

    local function attachDesktopSkillTagAndHover(sApi, moveKey, fallbackLabel)
        if isMobile or not moveKey or not sApi or not sApi.Instance then
            return nil, nil
        end
        local tagPill = UIFactory.Create("Frame", sApi.Instance, {
            Name = "MechTagPill",
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -3, 0, 4),
            Size = UDim2.fromOffset(0, 13),
            AutomaticSize = Enum.AutomaticSize.X,
            BackgroundColor3 = Color3.fromRGB(8, 13, 24),
            BackgroundTransparency = 0.08,
            BorderSizePixel = 0,
            Active = false,
            ZIndex = sApi.Instance.ZIndex + 6,
        })
        UIFactory.Corner(tagPill, 4)
        UIFactory.Padding(tagPill, 0, 3, 0, 3)
        UIFactory.Stroke(tagPill, Color3.fromRGB(125, 224, 255), 1, 0.28)

        local tagLbl = UIFactory.Label(tagPill, {
            Name = "TagText",
            Text = "",
            Size = UDim2.fromOffset(0, 13),
            TextSize = 7,
            TextColor = Color3.fromRGB(186, 240, 255),
            Bold = true,
            Wrapped = false,
            ZIndex = sApi.Instance.ZIndex + 7,
        })
        tagLbl.AutomaticSize = Enum.AutomaticSize.X

        sApi.Instance.MouseEnter:Connect(function()
            if not mechTooltip then
                return
            end
            local ctxNow, curSnap, chNow = buildCurrentBlueprintCtx()
            local curView = Store.GetView()
            local slotNow = tonumber((player and player:GetAttribute("ActiveSlot")) or curView.activeHotbarSlot or (curSnap.fruits and curSnap.fruits.activeSlot)) or 1
            local itemNow = resolveSlotItemAndMastery(slotNow, curSnap, player)
            if slotNow == 2 and itemNow == "" then
                mechTooltip.Visible = false
                return
            end
            local _, _, _, mLabel = resolveMoveSpecForSlot(slotNow, itemNow, moveKey, chNow, player, curSnap, 5, 10, fallbackLabel)
            local mMeta = I18n.GetSkillMechanicsMeta(slotNow, itemNow, moveKey, ctxNow)
            local tagBadges = {}
            for _, t in ipairs(mMeta.tags) do
                table.insert(tagBadges, "[" .. t .. "]")
            end
            mechTooltipTitle.Text = string.format("[%s] %s  •  %s", moveKey, tostring(mLabel or moveKey), mMeta.archetypeLabel)
            mechTooltipTags.Text = (#tagBadges > 0) and table.concat(tagBadges, "  •  ") or mMeta.archetypeLabel
            mechTooltip.Visible = true
        end)
        sApi.Instance.MouseLeave:Connect(function()
            if mechTooltip then
                mechTooltip.Visible = false
            end
        end)
        return tagPill, tagLbl
    end

    -- 8. Combat Controls: Desktop 8 Glossy Skill Cards + Center 45 deg Diamond Ultimate [R] OR Mobile Right-Thumb Arc
    local skillsList = classCfg.Skills or {}
    local sk1 = skillsList[1] or { Id = "SkySlash", Name = "Thiên Trảm", LevelReq = 1, Cooldown = 5, EnergyCost = 15 }
    local sk2 = skillsList[2] or { Id = "GuardianShield", Name = "Khiên Thánh", LevelReq = 1, Cooldown = 10, EnergyCost = 20 }
    local sk3 = skillsList[4] or { Id = "JudgmentStrike", Name = "Phán Quyết", LevelReq = 10, Cooldown = 12, EnergyCost = 25 }
    local skUlt = skillsList[5] or { Id = "CelestialAegis", Name = "Thiên Giới", LevelReq = 20, Cooldown = 45, EnergyCost = 50 }

    local skillSlotApis = {}
    local diamondUltApi = nil
    local mobileWillRefs = {}
    local initActiveId, initMastery = resolveSlotItemAndMastery(activeSlotIdx, snap, player)
    local initChar = player and player.Character

    if not isMobile then
        local abilityDock = PremiumPanel.Create(root, {
            name = "AbilityHotbar",
            variant = "gold",
            anchorPoint = Vector2.new(0.5, 1),
            position = UDim2.new(0.5, combatOffsetX, 1, -10),
            size = UDim2.fromOffset(656, 82),
            transparency = 0.06,
            clipsDescendants = false,
            zIndex = 6,
        })

        local leftWing = UIFactory.Create("Frame", abilityDock, {
            Name = "LeftSkillCards",
            Position = UDim2.fromOffset(12, 8),
            Size = UDim2.fromOffset(258, 66),
            BackgroundTransparency = 1,
            ZIndex = 7,
        })
        UIFactory.ListLayout(leftWing, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

        local rightWing = UIFactory.Create("Frame", abilityDock, {
            Name = "RightSkillCards",
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -12, 0, 8),
            Size = UDim2.fromOffset(258, 66),
            BackgroundTransparency = 1,
            ZIndex = 7,
        })
        UIFactory.ListLayout(rightWing, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)

        local leftCardDefs = {
            {
                slotKey = "Dodge",
                skillId = "Dodge",
                nameText = I18n.Pick("Lướt", "Dash"),
                keybind = "Q",
                palette = "cyan",
                icon = "Wing",
                levelReq = 1,
                masteryReq = 1,
                maxCooldown = 2.0,
                energyCost = 10,
                onPress = function()
                    HUDController.TriggerAction("Dodge")
                end,
            },
            {
                slotKey = "MoveZ",
                moveKey = "Z",
                skillId = "Slot_Z",
                nameText = sk1.Name,
                keybind = "Z",
                palette = "sapphire",
                icon = "Sword",
                levelReq = 1,
                masteryReq = 1,
                maxCooldown = sk1.Cooldown or 5,
                energyCost = sk1.EnergyCost or 10,
                onPress = function()
                    HUDController.TriggerAction("Z")
                end,
            },
            {
                slotKey = "MoveX",
                moveKey = "X",
                skillId = "Slot_X",
                nameText = sk2.Name,
                keybind = "X",
                palette = "sapphire",
                icon = "Shield",
                levelReq = 1,
                masteryReq = 50,
                maxCooldown = sk2.Cooldown or 8,
                energyCost = sk2.EnergyCost or 15,
                onPress = function()
                    HUDController.TriggerAction("X")
                end,
            },
            {
                slotKey = "MoveC",
                moveKey = "C",
                skillId = "Slot_C",
                nameText = sk3.Name,
                keybind = "C",
                palette = "gold",
                icon = "Bolt",
                levelReq = 1,
                masteryReq = 100,
                maxCooldown = sk3.Cooldown or 11,
                energyCost = sk3.EnergyCost or 18,
                onPress = function()
                    HUDController.TriggerAction("C")
                end,
            },
        }

        for idx, cd in ipairs(leftCardDefs) do
            local mReq, mCd, mCost, mLabel = cd.masteryReq, cd.maxCooldown, cd.energyCost, cd.nameText
            if cd.moveKey then
                mReq, mCd, mCost, mLabel = resolveMoveSpecForSlot(activeSlotIdx, initActiveId, cd.moveKey, initChar, player, snap, cd.maxCooldown, cd.energyCost, cd.nameText)
            end
            local initLocked = cd.moveKey and (initMastery < mReq) or ((snap.player.level or 1) < (cd.levelReq or 1))
            local _, sApi = SkillButton.Create(leftWing, {
                name = "SkillCard_" .. cd.keybind,
                skillId = cd.skillId,
                nameText = mLabel,
                label = mLabel,
                keybind = cd.keybind,
                palette = cd.palette,
                icon = cd.icon,
                size = UDim2.fromOffset(60, 66),
                layoutOrder = idx,
                locked = initLocked,
                lockLabel = cd.moveKey and ("Mas. " .. tostring(mReq)) or ("Lv." .. tostring(cd.levelReq or 1)),
                masteryReq = mReq,
                maxCooldown = mCd,
                zIndex = 8,
                onActivated = cd.onPress,
            })
            local tagPill, tagLbl = attachDesktopSkillTagAndHover(sApi, cd.moveKey, mLabel)
            skillSlotApis[cd.slotKey] = {
                Api = sApi,
                MoveKey = cd.moveKey,
                SkillId = cd.skillId,
                BaseName = cd.nameText,
                LevelReq = cd.levelReq,
                MasteryReq = mReq,
                MaxCooldown = mCd,
                EnergyCost = mCost,
                TagPill = tagPill,
                TagLabel = tagLbl,
            }
        end

        -- Centerpiece 45-Degree Rotated Diamond Ultimate [R] + J & Y Shoulder Mini-Orbs
        local _, ultCenterApi = buildDiamondUltimateCenterpiece(abilityDock, {
            locked = (snap.player.level or 1) < (skUlt.LevelReq or 20),
            lockLabel = "Lv." .. tostring(skUlt.LevelReq or 20),
            maxCooldown = skUlt.Cooldown or 45,
            zIndex = 8,
            onActivated = function()
                HUDController.TriggerAction("Ultimate")
            end,
            onHaki = function()
                HUDController.TriggerAction("ToggleAura")
            end,
            onV4 = function()
                if player and player.Character then
                    pcall(function()
                        player.Character:SetAttribute("NativeRaceV4Toggled", true)
                    end)
                end
                HUDController.TriggerAction("ActivateRaceV4")
            end,
        })
        diamondUltApi = ultCenterApi
        skillSlotApis["Ultimate"] = {
            Api = ultCenterApi,
            SkillId = skUlt.Id,
            BaseName = skUlt.Name,
            LevelReq = skUlt.LevelReq or 20,
            MasteryReq = 1,
            MaxCooldown = skUlt.Cooldown or 45,
            EnergyCost = skUlt.EnergyCost or 50,
        }

        local rightCardDefs = {
            {
                slotKey = "FruitV",
                moveKey = "V",
                skillId = "Slot_V",
                nameText = I18n.Pick("Thức Tỉnh", "Awaken"),
                keybind = "V",
                keyTag = "[V]",
                palette = "mythic",
                icon = "Flame",
                levelReq = 1,
                masteryReq = 200,
                maxCooldown = 18,
                energyCost = 25,
                onPress = function()
                    HUDController.TriggerAction("V")
                end,
            },
            {
                slotKey = "SkillE",
                skillId = "AetherBurstE",
                nameText = I18n.Pick("Tương Tác", "Interact"),
                keybind = "E",
                palette = "gold",
                icon = "Flame",
                levelReq = 1,
                masteryReq = 1,
                maxCooldown = 8,
                energyCost = 0,
                onPress = function()
                    local vState = Store.GetView()
                    if vState.interactPrompt and vState.interactPrompt.visible then
                        HUDController.TriggerAction("Interact")
                    else
                        HUDController.TriggerAction("C")
                    end
                end,
            },
            {
                slotKey = "FlightF",
                moveKey = "F",
                skillId = "Slot_F",
                nameText = I18n.Pick("Thiên Vũ", "Flight"),
                keybind = "F",
                palette = "cyan",
                icon = "Wing",
                levelReq = 1,
                masteryReq = 1,
                maxCooldown = 6,
                energyCost = 10,
                onPress = function()
                    triggerFKeyOrFlight(player)
                end,
            },
            {
                slotKey = "InstinctU",
                skillId = "WillSenseU",
                nameText = I18n.Pick("Thấu Ý", "Will Sense"),
                keybind = "U",
                keyTag = "[U]",
                palette = "slate",
                icon = "Compass",
                levelReq = 1,
                masteryReq = 1,
                maxCooldown = 2,
                energyCost = 0,
                onPress = function()
                    HUDController.TriggerAction("ToggleInstinct")
                end,
            },
        }

        for idx, cd in ipairs(rightCardDefs) do
            local mReq, mCd, mCost, mLabel = cd.masteryReq, cd.maxCooldown, cd.energyCost, cd.nameText
            if cd.moveKey then
                mReq, mCd, mCost, mLabel = resolveMoveSpecForSlot(activeSlotIdx, initActiveId, cd.moveKey, initChar, player, snap, cd.maxCooldown, cd.energyCost, cd.nameText)
            end
            local initLocked = cd.moveKey and (initMastery < mReq) or false
            local _, sApi = SkillButton.Create(rightWing, {
                name = "SkillCard_" .. cd.keybind,
                skillId = cd.skillId,
                nameText = mLabel,
                label = mLabel,
                keybind = cd.keybind,
                keyTag = cd.keyTag,
                palette = cd.palette,
                icon = cd.icon,
                size = UDim2.fromOffset(60, 66),
                layoutOrder = idx,
                locked = initLocked,
                lockLabel = "Mas. " .. tostring(mReq or 1),
                masteryReq = mReq,
                maxCooldown = mCd,
                zIndex = 8,
                onActivated = cd.onPress,
            })
            local tagPill, tagLbl = attachDesktopSkillTagAndHover(sApi, cd.moveKey, mLabel)
            skillSlotApis[cd.slotKey] = {
                Api = sApi,
                MoveKey = cd.moveKey,
                SkillId = cd.skillId,
                BaseName = cd.nameText,
                LevelReq = cd.levelReq,
                MasteryReq = mReq,
                MaxCooldown = mCd,
                EnergyCost = mCost,
                TagPill = tagPill,
                TagLabel = tagLbl,
            }
        end
    else
        -- Mobile Right-Thumb Combat Arc (#125)
        -- Keep clear of Roblox's TouchGui JumpButton (bottom-right; 70px small / 120px large screens).
        -- SkybreakUI (DisplayOrder 25) sits above TouchGui, so overlapping buttons ate every jump tap.
        local arcVp = viewportVec or Vector2.new(1366, 768)
        local arcScale = math.max(0.1, (responsiveState and responsiveState.UIScale) or 1)
        local jumpClearPx = (math.min(arcVp.X, arcVp.Y) <= 500) and 104 or 180
        local arcShiftX = math.ceil(jumpClearPx / arcScale)
        local touchArc = UIFactory.Create("Frame", root, {
            Name = "MobileTouchArc",
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -14 - arcShiftX, 1, -14),
            Size = UDim2.fromOffset(236, 262),
            BackgroundTransparency = 1,
            ZIndex = 8,
        })

        -- B10: Compact 3-Button Mobile Will & Ascension Strip ([U] Thấu Ý, [H] Bá Ý, [Y] Thăng Hoa) above the Arc
        local mobileWillStrip = UIFactory.Create("Frame", touchArc, {
            Name = "MobileWillCombatStrip",
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -4, 0, 0),
            Size = UDim2.fromOffset(228, 28),
            BackgroundTransparency = 1,
            ZIndex = 9,
        })
        UIFactory.ListLayout(mobileWillStrip, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)

        local mobileWillDefs = {
            {
                id = "Instinct",
                action = "ToggleInstinct",
                labelVi = "[U] Thấu Ý",
                labelEn = "[U] Sense",
                topCol = Color3.fromRGB(28, 88, 178),
                botCol = Color3.fromRGB(14, 34, 76),
                borderCol = colors.ACCENT_SAPPHIRE,
            },
            {
                id = "Conqueror",
                action = "ConquerorBurst",
                labelVi = "[H] Bá Ý",
                labelEn = "[H] Conq",
                topCol = Color3.fromRGB(198, 36, 78),
                botCol = Color3.fromRGB(88, 14, 38),
                borderCol = Color3.fromRGB(255, 138, 162),
            },
            {
                id = "RaceV4",
                action = "ActivateRaceV4",
                labelVi = "[Y] Thăng Hoa",
                labelEn = "[Y] Ascend",
                topCol = Color3.fromRGB(162, 64, 224),
                botCol = Color3.fromRGB(68, 22, 118),
                borderCol = Color3.fromRGB(228, 184, 255),
            },
        }

        for wIdx, wd in ipairs(mobileWillDefs) do
            local wBtn = UIFactory.Create("TextButton", mobileWillStrip, {
                Name = "MobileWill_" .. wd.id,
                Size = UDim2.fromOffset(72, 28),
                BackgroundColor3 = Color3.new(1, 1, 1),
                BackgroundTransparency = 0.04,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                LayoutOrder = wIdx,
                ZIndex = 10,
            })
            UIFactory.PillCorner(wBtn)
            local wStroke = UIFactory.Stroke(wBtn, wd.borderCol, 1.4, 0.12)
            UIFactory.Gradient(wBtn, wd.topCol, wd.botCol, 90)
            local wLbl = UIFactory.Label(wBtn, {
                Name = "WillText",
                Text = I18n.Pick(wd.labelVi, wd.labelEn),
                Position = UDim2.fromOffset(4, 0),
                Size = UDim2.new(1, -8, 1, 0),
                TextSize = 9,
                TextColor = Color3.fromRGB(250, 252, 255),
                Bold = true,
                XAlign = Enum.TextXAlignment.Center,
                Truncate = Enum.TextTruncate.AtEnd,
                Wrapped = false,
                ZIndex = 11,
            })
            UIFactory.TextSizeConstraint(wLbl, 7, 9)
            wBtn.Activated:Connect(function()
                if wd.action == "ActivateRaceV4" and player and player.Character then
                    pcall(function()
                        player.Character:SetAttribute("NativeRaceV4Toggled", true)
                    end)
                end
                HUDController.TriggerAction(wd.action)
            end)
            mobileWillRefs[wd.id] = {
                Button = wBtn,
                Stroke = wStroke,
                Label = wLbl,
                DefaultBorder = wd.borderCol,
                BaseVi = wd.labelVi,
                BaseEn = wd.labelEn,
            }
        end

        local m1Btn = UIFactory.Create("TextButton", touchArc, {
            Name = "PrimaryAttackBtn",
            AnchorPoint = Vector2.new(1, 1),
            Position = UDim2.new(1, -4, 1, -4),
            Size = UDim2.fromOffset(82, 82),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 9,
        })
        UIFactory.PillCorner(m1Btn)
        UIFactory.Stroke(m1Btn, colors.ACCENT_GOLD_BRIGHT, 2.2, 0.04)
        UIFactory.Gradient(m1Btn, Color3.fromRGB(252, 212, 98), Color3.fromRGB(186, 114, 20), 90)
        UIFactory.Icon(m1Btn, "Sword", UDim2.new(0.5, -15, 0.5, -18), 30, Color3.fromRGB(16, 20, 32)).ZIndex = 10
        UIFactory.Label(m1Btn, {
            Name = "M1Label",
            Text = I18n.Pick("ĐÁNH", "ATK"),
            Position = UDim2.new(0, 0, 1, -21),
            Size = UDim2.new(1, 0, 0, 16),
            TextSize = 10,
            TextColor = Color3.fromRGB(16, 20, 32),
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            ZIndex = 10,
        })
        m1Btn.Activated:Connect(function()
            HUDController.TriggerAttackInput(nil)
        end)

        -- B7 & B8: Always send "Z", "X", "C", "V", "F" across all 4 Slots (1..4); instant 0ms F for non-flight!
        local arcNodes = {
            { key = "MoveZ", moveKey = "Z", id = "Slot_Z", name = sk1.Name, kb = "Z", pal = "sapphire", icon = "Sword", pos = UDim2.new(1, -98, 1, -10), req = 1, masReq = 1, cd = sk1.Cooldown or 5, cost = sk1.EnergyCost or 10, act = "Z" },
            { key = "MoveX", moveKey = "X", id = "Slot_X", name = sk2.Name, kb = "X", pal = "sapphire", icon = "Shield", pos = UDim2.new(1, -88, 1, -80), req = 1, masReq = 50, cd = sk2.Cooldown or 8, cost = sk2.EnergyCost or 15, act = "X" },
            { key = "MoveC", moveKey = "C", id = "Slot_C", name = sk3.Name, kb = "C", pal = "gold", icon = "Bolt", pos = UDim2.new(1, -20, 1, -102), req = 1, masReq = 100, cd = sk3.Cooldown or 11, cost = sk3.EnergyCost or 18, act = "C" },
            { key = "Ultimate", id = skUlt.Id, name = skUlt.Name, kb = "R", pal = "mythic", icon = "Crown", pos = UDim2.new(1, -82, 1, -148), req = skUlt.LevelReq or 20, masReq = 1, cd = skUlt.Cooldown or 45, cost = skUlt.EnergyCost or 50, act = "Ultimate" },
            { key = "Dodge", id = "Dodge", name = I18n.Pick("Lướt", "Dash"), kb = "Q", pal = "cyan", icon = "Wing", pos = UDim2.new(1, -162, 1, -14), req = 1, masReq = 1, cd = 2.0, cost = 10, act = "Dodge" },
            { key = "FruitV", moveKey = "V", id = "Slot_V", name = I18n.Pick("Thức Tỉnh", "Awaken"), kb = "V", pal = "mythic", icon = "Flame", pos = UDim2.new(1, -162, 1, -80), req = 1, masReq = 200, cd = 18, cost = 25, act = "V" },
            { key = "FlightF", moveKey = "F", id = "Slot_F", name = I18n.Pick("Thiên Vũ", "Flight"), kb = "F", pal = "cyan", icon = "Wing", pos = UDim2.new(1, -150, 1, -146), req = 1, masReq = 1, cd = 6, cost = 10, act = "FlightOrF" },
            { key = "LockTarget", id = "ToggleLock", name = I18n.Pick("Khóa", "Lock"), kb = "Tab", pal = "slate", icon = "Compass", pos = UDim2.new(1, -20, 1, -168), req = 1, masReq = 1, cd = 0, cost = 0, act = "ToggleLock" },
        }

        for _, an in ipairs(arcNodes) do
            local mReq, mCd, mCost, mLabel = an.masReq, an.cd, an.cost, an.name
            if an.moveKey then
                mReq, mCd, mCost, mLabel = resolveMoveSpecForSlot(activeSlotIdx, initActiveId, an.moveKey, initChar, player, snap, an.cd, an.cost, an.name)
            end
            local initLocked = an.moveKey and (initMastery < mReq) or ((snap.player.level or 1) < (an.req or 1))
            local _, sApi = SkillButton.Create(touchArc, {
                name = "Arc_" .. an.key,
                skillId = an.id,
                nameText = mLabel,
                label = mLabel,
                keybind = an.kb,
                palette = an.pal,
                icon = an.icon,
                anchorPoint = Vector2.new(1, 1),
                position = an.pos,
                size = UDim2.fromOffset(54, 56),
                locked = initLocked,
                lockLabel = an.moveKey and ("Mas. " .. tostring(mReq)) or ("Lv." .. tostring(an.req or 1)),
                masteryReq = mReq,
                maxCooldown = mCd,
                zIndex = 9,
                onActivated = function()
                    if an.act == "FlightOrF" then
                        triggerFKeyOrFlight(player)
                    else
                        HUDController.TriggerAction(an.act)
                    end
                end,
            })
            skillSlotApis[an.key] = {
                Api = sApi,
                MoveKey = an.moveKey,
                SkillId = an.id,
                BaseName = an.name,
                LevelReq = an.req,
                MasteryReq = mReq,
                MaxCooldown = mCd,
                EnergyCost = mCost,
            }
        end
    end

    HUD.Refs = {
        Root = root,
        VitalsCard = vitalsCard,
        IsPortrait = isPortrait == true,
        AvatarPortraitApi = avatarPortraitApi,
        LevelLabel = levelLabel,
        PlayerNameLabel = playerNameLabel,
        ClassTitleLabel = classTitleLabel,
        ClassTitleStroke = classTitleStroke,
        HPBarApi = hpBarApi,
        StaminaBarApi = staminaBarApi,
        XPBarApi = xpBarApi,
        FuryAwakenTrack = furyAwakenTrack,
        FuryAwakenFill = furyAwakenFill,
        FuryAwakenGrad = furyAwakenGrad,
        FuryAwakenStroke = furyAwakenStroke,
        FuryAwakenLabel = furyAwakenLabel,
        StatusPillsRow = statusPillsRow,
        QuestTrackerFrame = questTrackerFrame,
        HudGoldLabel = hudGoldLabel,
        HudShardLabel = hudShardLabel,
        HudHakiPill = hudHakiPill,
        HudHakiLabel = hudHakiLabel,
        HudHakiStroke = hudHakiStroke,
        BuffPills = buffPills,
        QuestTrackerApi = questTrackerApi,
        MinimapApi = minimapApi,
        FruitRadarPill = fruitRadarPill,
        FruitRadarStroke = fruitRadarStroke,
        FruitRadarLabel = fruitRadarLabel,
        SquadPillBtn = squadPillBtn,
        CompanionTitle = companionTitle,
        PartyInviteBanner = partyInviteBanner,
        PartyInviteTitle = partyInviteTitle,
        StatPointsBadge = statPointsBadge,
        StatPointsBadgeLabel = statPointsBadgeLabel,
        SkillsNavTileStroke = skillsNavTileStroke,
        StatOnboardingCallout = statCalloutBtn,
        StatOnboardingCalloutLabel = statCalloutLabel,
        BossBarApi = bossBarApi,
        ComboCard = comboCard,
        ComboTimerFill = comboTimerFill,
        AimReticle = aimReticle,
        AimDashSegments = aimDashSegments,
        AimDiamondStroke = aimDiamondStroke,
        AimCoreDot = aimCoreDot,
        AimCoreStroke = aimCoreStroke,
        AimModePill = aimModePill,
        AimModeStroke = aimModeStroke,
        AimModeLabel = aimModeLabel,
        DashCluster = dashCluster,
        DashArcBeads = dashArcBeads,
        DashCountPill = dashCountPill,
        DashCountStroke = dashCountStroke,
        DashCountLabel = dashCountLabel,
        PerfectDodgePill = perfectDodgePill,
        PruneAndCountDashCharges = pruneAndCountDashCharges,
        TriggerDodgeFeedback = triggerDodgeFeedback,
        InteractBtn = interactBtn,
        InteractApi = interactApi,
        LoadoutSlotRefs = loadoutSlotRefs,
        ApplyLoadoutPillVisual = applyLoadoutPillVisual,
        ResolveLoadoutSlotNames = resolveLoadoutSlotNames,
        SkillSlotApis = skillSlotApis,
        DiamondUltApi = diamondUltApi,
        MobileWillRefs = mobileWillRefs,
        MobileArchCallout = mobileArchCallout,
        MobileArchLabel = mobileArchLabel,
        LastMobileSlot = activeSlotIdx,
        MobileArchUntil = 0,
    }

    HUD.Update(snap, view)
    return root
end

function HUD.Update(snapshot, viewState)
    local refs = HUD.Refs
    if not refs or not refs.Root or not refs.Root.Parent then
        return
    end
    local colors = Theme.Colors
    local player = Players.LocalPlayer
    local snap = snapshot or Store.GetSnapshot()
    local view = viewState or Store.GetView()

    local char = player and player.Character
    local nowSrv = workspace:GetServerTimeNow()

    -- 1. Live 3D Avatar Portrait & Vitals
    if refs.AvatarPortraitApi then
        refs.AvatarPortraitApi:Update(snap)
    elseif refs.LevelLabel then
        refs.LevelLabel.Text = "Lv. " .. tostring(snap.player.level or 1)
    end

    local v4End = tonumber((char and char:GetAttribute("RaceV4ActiveUntil")) or (player and player:GetAttribute("RaceV4ActiveUntil"))) or 0
    local v4Rem = math.max(0, v4End - nowSrv)
    local v4RaceStr = tostring((char and char:GetAttribute("RaceV4")) or (player and player:GetAttribute("RaceV4")) or "")
    local v4On = (v4RaceStr ~= "" and v4RaceStr ~= "None")
        or (char and char:GetAttribute("RaceV4Active") == true)
        or (player and player:GetAttribute("RaceV4Active") == true)
        or (snap.fruits and snap.fruits.raceV4Active == true)
        or (v4Rem > 0.4)

    local titleTxt, titleCol = resolveClassBadgeMeta(snap.player.level, snap.player.classId, v4On)
    if refs.ClassTitleLabel then
        refs.ClassTitleLabel.Text = titleTxt
        refs.ClassTitleLabel.TextColor3 = titleCol
    end
    if refs.ClassTitleStroke then
        refs.ClassTitleStroke.Color = titleCol
    end

    if refs.HPBarApi and (not player or not player.Character) then
        refs.HPBarApi:Update({
            current = snap.vitals.hp,
            max = snap.vitals.maxHp,
            customText = string.format("HP  %s / %s", UIFactory.FormatNumber(math.ceil(snap.vitals.hp or 100)), UIFactory.FormatNumber(math.ceil(snap.vitals.maxHp or 100))),
        })
    end

    local dynMaxEnergy = math.max(
        100,
        math.floor(
            tonumber(
                (char and char:GetAttribute("MaxEnergy"))
                or (player and player:GetAttribute("MaxEnergy"))
                or (snap.vitals and snap.vitals.maxEnergy)
                or (snap.raw and snap.raw.MaxEnergy)
            ) or 100
        )
    )
    local dynCurEnergy = math.clamp(
        tonumber(
            (char and char:GetAttribute("Energy"))
            or (player and player:GetAttribute("Energy"))
            or (snap.vitals and snap.vitals.energy)
        ) or dynMaxEnergy,
        0,
        dynMaxEnergy
    )
    if refs.StaminaBarApi then
        refs.StaminaBarApi:Update({
            current = dynCurEnergy,
            max = dynMaxEnergy,
            customText = string.format("AETHER  %d / %d", math.floor(dynCurEnergy), math.floor(dynMaxEnergy)),
        })
    end

    if refs.XPBarApi then
        local expCur = tonumber(snap.player.exp) or 0
        local expMax = math.max(1, tonumber(snap.player.expToNext) or 100)
        local expPct = math.clamp(math.floor((expCur / expMax) * 100), 0, 100)
        refs.XPBarApi:Update({
            current = expCur,
            max = expMax,
            customText = string.format("EXP %s / %s (%d%%)", UIFactory.FormatNumber(expCur), UIFactory.FormatNumber(expMax), expPct),
        })
    end

    -- 1A. Dragon Fury / Race V4 Awakening Meter Bar + Unspent StatPoints Badge on [K]
    if refs.FuryAwakenTrack and refs.FuryAwakenFill and refs.FuryAwakenLabel then
        local eqFruitId = normalizeFruitId(
            (char and char:GetAttribute("EquippedFruit"))
            or (player and player:GetAttribute("EquippedFruit"))
            or (snap.fruits and snap.fruits.equippedFruit)
        )
        local isDragonFruit = (eqFruitId == "AbyssalSovereignCore")
        local drgForm = tonumber((char and char:GetAttribute("DragonFormTier")) or (player and player:GetAttribute("DragonFormTier")) or (snap.vitals and snap.vitals.dragonFormTier)) or 0
        local rawFury = tonumber(
            (char and (char:GetAttribute("FuryMeter") or char:GetAttribute("DragonFury")))
            or (player and (player:GetAttribute("FuryMeter") or player:GetAttribute("DragonFury")))
            or (snap.vitals and snap.vitals.furyMeter)
            or (snap.fruits and snap.fruits.furyMeter)
        )
        local rawAwk = tonumber(
            (char and char:GetAttribute("AwakeningMeter"))
            or (player and player:GetAttribute("AwakeningMeter"))
            or (snap.vitals and snap.vitals.awakeningMeter)
            or (snap.fruits and snap.fruits.awakeningMeter)
        ) or 0
        local v4Unlocked = (snap.fruits and (snap.fruits.raceV4Unlocked == true or (tonumber(snap.fruits.raceTier) or 1) >= 4))
            or (player and player:GetAttribute("RaceV4Unlocked") == true)
            or v4On

        local showSpecialBar = isDragonFruit or (drgForm > 0) or v4Unlocked or (rawAwk > 0 and v4On)
        refs.FuryAwakenTrack.Visible = showSpecialBar
        local vitalsBaseW = refs.IsPortrait and 356 or 388
        if refs.VitalsCard then
            refs.VitalsCard.Size = UDim2.fromOffset(vitalsBaseW, showSpecialBar and 130 or 122)
        end
        if refs.StatusPillsRow then
            refs.StatusPillsRow.Position = UDim2.fromOffset(16, showSpecialBar and 150 or 142)
        end
        if refs.QuestTrackerFrame then
            refs.QuestTrackerFrame.Position = UDim2.fromOffset(16, showSpecialBar and 184 or 176)
        end

        if showSpecialBar then
            if isDragonFruit or drgForm > 0 then
                local furyVal = math.clamp(rawFury or ((drgForm >= 2 and 100) or (drgForm == 1 and 65) or rawAwk), 0, 100)
                refs.FuryAwakenFill.Size = UDim2.fromScale(furyVal / 100, 1)
                if refs.FuryAwakenGrad then
                    refs.FuryAwakenGrad.Color = ColorSequence.new(Color3.fromRGB(251, 191, 36), Color3.fromRGB(225, 29, 72))
                end
                if refs.FuryAwakenStroke then
                    refs.FuryAwakenStroke.Color = (drgForm >= 2) and colors.ACCENT_GOLD_BRIGHT or Color3.fromRGB(251, 113, 133)
                end
                local tierTag = (drgForm >= 2 and I18n.Pick(" • FORM II LONG HOÀNG", " • FORM II SOVEREIGN"))
                    or (drgForm == 1 and I18n.Pick(" • FORM I BÁN LONG", " • FORM I HYBRID"))
                    or ""
                refs.FuryAwakenLabel.Text = string.format("%s %d%%%s", I18n.Pick("LONG NỘ", "DRAGON FURY"), math.floor(furyVal), tierTag)
            else
                local awkPct = v4On and (v4Rem > 0.4 and math.clamp((v4Rem / 35) * 100, 8, 100) or 100) or math.clamp(rawAwk, 0, 100)
                refs.FuryAwakenFill.Size = UDim2.fromScale(awkPct / 100, 1)
                if refs.FuryAwakenGrad then
                    refs.FuryAwakenGrad.Color = ColorSequence.new(Color3.fromRGB(192, 132, 252), Color3.fromRGB(56, 189, 248))
                end
                if refs.FuryAwakenStroke then
                    refs.FuryAwakenStroke.Color = v4On and colors.ACCENT_GOLD_BRIGHT or Color3.fromRGB(192, 132, 252)
                end
                refs.FuryAwakenLabel.Text = v4On
                    and ((v4Rem > 0.4)
                        and I18n.Pick(string.format("THĂNG HOA TỘC V4 [Y] • %ds", math.ceil(v4Rem)), string.format("ASCENSION V4 [Y] • %ds", math.ceil(v4Rem)))
                        or I18n.Pick("THĂNG HOA TỘC V4 [Y] • BẬT", "ASCENSION V4 [Y] • ACTIVE"))
                    or I18n.Pick(string.format("NĂNG LƯỢNG TỘC V4 [Y] • %d%%", math.floor(awkPct)), string.format("ASCENSION V4 METER [Y] • %d%%", math.floor(awkPct)))
            end
        end
    end

    if refs.StatPointsBadge and refs.StatPointsBadgeLabel then
        local sp = math.max(
            0,
            math.floor(
                tonumber(
                    (player and player:GetAttribute("StatPoints"))
                    or (snap.fruits and snap.fruits.statPoints)
                    or (snap.player and snap.player.statPoints)
                    or (snap.raw and snap.raw.StatPoints)
                ) or 0
            )
        )
        refs.StatPointsBadge.Visible = (sp > 0)
        if sp > 0 then
            refs.StatPointsBadgeLabel.Text = "+" .. (sp > 999 and "999+" or tostring(sp))
            if refs.SkillsNavTileStroke then
                refs.SkillsNavTileStroke.Color = colors.ACCENT_GOLD_BRIGHT
                refs.SkillsNavTileStroke.Thickness = 1.8
                refs.SkillsNavTileStroke.Transparency = 0.0
            end
        elseif refs.SkillsNavTileStroke then
            refs.SkillsNavTileStroke.Color = Color3.fromRGB(84, 110, 152)
            refs.SkillsNavTileStroke.Thickness = 1.2
            refs.SkillsNavTileStroke.Transparency = 0.24
        end
        if refs.StatOnboardingCallout and refs.StatOnboardingCalloutLabel then
            local pLv = tonumber(snap.player and snap.player.level) or 1
            local showCallout = (sp > 0) and (pLv <= 25)
            refs.StatOnboardingCallout.Visible = showCallout
            if showCallout then
                local qCollapsed = (view.questTrackerCollapsed == true)
                refs.StatOnboardingCallout.Position = UDim2.fromOffset(16, qCollapsed and 214 or 306)
                refs.StatOnboardingCalloutLabel.Text = I18n.Pick(
                    string.format("✦ Còn +%d Điểm Tiềm Năng! Bấm [K] cộng điểm • Tự lặp Q tại [L]", sp),
                    string.format("✦ +%d Stat Points! Open [K] to upgrade • Auto-Quest in [L]", sp)
                )
            end
        end
    end

    -- 1B. Always-Visible Currencies, Haki Status Pill & Dynamic Buff Timers (C8)
    local curGold = tonumber((snap.currency and snap.currency.gold) or (snap.currencies and snap.currencies.gold)) or 0
    local curShards = tonumber((snap.currency and snap.currency.coreShards) or (snap.currencies and snap.currencies.coreShards)) or 0
    if refs.HudGoldLabel then
        refs.HudGoldLabel.Text = UIFactory.FormatNumber(curGold) .. " Gold"
    end
    if refs.HudShardLabel then
        refs.HudShardLabel.Text = UIFactory.FormatNumber(curShards) .. " Shards"
    end

    local auraOn = (char and char:GetAttribute("HakiAura") == true)
        or (player and (player:GetAttribute("HakiAura") == true or player:GetAttribute("AuraActive") == true))
        or (snap.fruits and snap.fruits.haki and snap.fruits.haki.Aura == true)
    local kenOn = (char and char:GetAttribute("HakiInstinct") == true)
        or (player and (player:GetAttribute("HakiInstinct") == true or player:GetAttribute("InstinctActive") == true))
        or (snap.fruits and snap.fruits.haki and snap.fruits.haki.Instinct == true)
    local conqAttr = tonumber((char and char:GetAttribute("ConquerorActiveUntil")) or (player and player:GetAttribute("ConquerorActiveUntil"))) or 0
    local conqRem = math.max(0, math.max(conqAttr, HUD.ConquerorUntil or 0) - nowSrv)

    if refs.HudHakiLabel and refs.HudHakiStroke then
        if auraOn and kenOn then
            refs.HudHakiLabel.Text = I18n.Pick("[J] Thiết Giáp Ý • [U] Thấu Ý", "[J] Will Armor • [U] Will Sense")
            refs.HudHakiLabel.TextColor3 = Color3.fromRGB(255, 206, 218)
            refs.HudHakiStroke.Color = colors.ACCENT_GOLD_BRIGHT
        elseif auraOn then
            refs.HudHakiLabel.Text = I18n.Pick("[J] Thiết Giáp Ý: BẬT", "[J] Will Armor: ON")
            refs.HudHakiLabel.TextColor3 = Color3.fromRGB(255, 186, 198)
            refs.HudHakiStroke.Color = colors.HP_RED
        elseif kenOn then
            refs.HudHakiLabel.Text = I18n.Pick("[U] Thấu Ý: BẬT", "[U] Will Sense: ON")
            refs.HudHakiLabel.TextColor3 = Color3.fromRGB(154, 232, 255)
            refs.HudHakiStroke.Color = colors.ACCENT_SAPPHIRE
        else
            refs.HudHakiLabel.Text = I18n.Pick("[J] Thiết Giáp Ý • [U] Thấu Ý", "[J] Will Armor • [U] Will Sense")
            refs.HudHakiLabel.TextColor3 = Color3.fromRGB(244, 248, 255)
            refs.HudHakiStroke.Color = colors.HP_RED
        end
    end

    if refs.DiamondUltApi then
        if refs.DiamondUltApi.JOrbStroke then
            refs.DiamondUltApi.JOrbStroke.Color = auraOn and colors.ACCENT_GOLD_BRIGHT or Color3.fromRGB(255, 180, 196)
            refs.DiamondUltApi.JOrbStroke.Thickness = auraOn and 2.2 or 1.5
        end
        if refs.DiamondUltApi.TOrbStroke then
            refs.DiamondUltApi.TOrbStroke.Color = v4On and colors.ACCENT_GOLD_BRIGHT or Color3.fromRGB(233, 213, 255)
            refs.DiamondUltApi.TOrbStroke.Thickness = v4On and 2.2 or 1.5
        end
    end

    local tfStr = tostring((char and char:GetAttribute("FruitTransform")) or (player and player:GetAttribute("FruitTransform")) or "")
    local drgTier = tonumber((char and char:GetAttribute("DragonFormTier")) or (player and player:GetAttribute("DragonFormTier")) or (snap.raw and snap.raw.DragonFormTier)) or 0
    local shOn = (tfStr ~= "" and tfStr ~= "None")
        or (drgTier > 0)
        or (player and (player:GetAttribute("FruitTransformed") == true or player:GetAttribute("ShieldActive") == true))
        or (char and (char:GetAttribute("FruitTransformed") == true or char:GetAttribute("ShieldActive") == true))

    if refs.BuffPills then
        local bAura = refs.BuffPills.Aura
        if bAura then
            bAura.Frame.Visible = auraOn == true
            if bAura.Frame.Visible then
                bAura.Label.Text = I18n.Pick("[J] Thiết Giáp Ý", "[J] Will Armor")
            end
        end

        local bKen = refs.BuffPills.Instinct
        if bKen then
            bKen.Frame.Visible = kenOn == true
            if bKen.Frame.Visible then
                bKen.Label.Text = I18n.Pick("[U] Thấu Ý", "[U] Will Sense")
            end
        end

        local bConq = refs.BuffPills.Conqueror
        if bConq then
            bConq.Frame.Visible = conqRem > 0.2
            if bConq.Frame.Visible then
                bConq.Label.Text = I18n.Pick("[H] Bá Ý • ", "[H] Sovereign • ") .. formatTimer(math.ceil(conqRem))
            end
        end

        local bV4 = refs.BuffPills.RaceV4
        if bV4 then
            bV4.Frame.Visible = v4On == true
            if bV4.Frame.Visible then
                bV4.Label.Text = (v4Rem > 0.5)
                    and (I18n.Pick("[Y] Thăng Hoa • ", "[Y] Ascension • ") .. formatTimer(v4Rem))
                    or I18n.Pick("[Y] Thăng Hoa", "[Y] Ascension")
            end
        end

        local dblSecAttr = tonumber((player and player:GetAttribute("DoubleExpSeconds")) or (snap.raw and snap.raw.DoubleExpSeconds) or snap.doubleExpSeconds) or 0
        local dblEnd = tonumber(player and player:GetAttribute("DoubleExpUntil")) or 0
        local dblFromEnd = (dblEnd > 1e8) and math.max(0, dblEnd - os.time()) or math.max(0, dblEnd - nowSrv)
        local dblRem = math.max(dblSecAttr, dblFromEnd)
        local ownsExpPass = ((player and player:GetAttribute("OwnedPass_x2_exp") == true) or (snap.ownedGamePasses and snap.ownedGamePasses.x2_exp == true))
        local bExp = refs.BuffPills.DoubleExp
        if bExp then
            bExp.Frame.Visible = (dblRem > 0.5) or ownsExpPass
            if bExp.Frame.Visible then
                if ownsExpPass and dblRem > 0.5 then
                    bExp.Label.Text = "4X EXP • " .. formatTimer(dblRem)
                elseif dblRem > 0.5 then
                    bExp.Label.Text = "2X EXP • " .. formatTimer(dblRem)
                else
                    bExp.Label.Text = "2X EXP PASS"
                end
            end
        end

        local bSh = refs.BuffPills.ShieldTransform
        if bSh then
            bSh.Frame.Visible = shOn == true
            if bSh.Frame.Visible then
                if drgTier >= 2 or tfStr == "AbyssalSovereign" or tfStr == "DragonFull" then
                    bSh.Label.Text = I18n.Pick("Hóa Long Vương", "Sovereign Dragon")
                elseif drgTier == 1 or tfStr == "AbyssalDragonHybrid" or tfStr == "DragonHybrid" then
                    bSh.Label.Text = I18n.Pick("Bán Long Thể", "Hybrid Dragon")
                elseif tfStr == "SolarTitan" then
                    bSh.Label.Text = I18n.Pick("Kim Thân Thái Dương", "Colossus Form")
                else
                    bSh.Label.Text = I18n.Pick("Hóa Thân Aether", "Aether Form")
                end
            end
        end
    end

    if refs.MobileWillRefs then
        local cds = snap.cooldowns or {}
        local elapsedSync = math.max(0, os.clock() - (Store.LastServerSyncClock or os.clock()))
        local conqCd = math.max(0, (tonumber(cds.ConquerorBurst or cds.ConquerorHaki) or 0) - elapsedSync)

        local mKen = refs.MobileWillRefs.Instinct
        if mKen then
            mKen.Stroke.Color = kenOn and colors.ACCENT_GOLD_BRIGHT or mKen.DefaultBorder
            mKen.Stroke.Thickness = kenOn and 2.0 or 1.4
            mKen.Label.Text = kenOn and I18n.Pick("[U] BẬT", "[U] ON") or I18n.Pick(mKen.BaseVi, mKen.BaseEn)
        end
        local mConq = refs.MobileWillRefs.Conqueror
        if mConq then
            local conqActive = conqRem > 0.2
            mConq.Stroke.Color = conqActive and colors.ACCENT_GOLD_BRIGHT or mConq.DefaultBorder
            mConq.Stroke.Thickness = conqActive and 2.0 or 1.4
            mConq.Label.Text = (conqCd > 0.2 and not conqActive)
                and string.format("[H] %ds", math.ceil(conqCd))
                or I18n.Pick(mConq.BaseVi, mConq.BaseEn)
        end
        local mV4 = refs.MobileWillRefs.RaceV4
        if mV4 then
            mV4.Stroke.Color = v4On and colors.ACCENT_GOLD_BRIGHT or mV4.DefaultBorder
            mV4.Stroke.Thickness = v4On and 2.0 or 1.4
            mV4.Label.Text = v4On and I18n.Pick("[Y] BẬT", "[Y] ON") or I18n.Pick(mV4.BaseVi, mV4.BaseEn)
        end
    end

    -- 2. Quest Tracker
    if refs.QuestTrackerApi then
        refs.QuestTrackerApi:Update({
            activeQuest = snap.quest,
            collapsed = view.questTrackerCollapsed,
        })
    end

    -- 3. Minimap, Purple Aether Fruit Radar Pill & Gold Squad Pill
    if refs.MinimapApi and refs.MinimapApi.Instance then
        local showMap = not (view.settings and view.settings.showMinimap == false)
        refs.MinimapApi.Instance.Visible = showMap
    end

    local rootPart = char and (char.PrimaryPart or char:FindFirstChild("HumanoidRootPart"))
    local playerPos = (rootPart and rootPart:IsA("BasePart")) and rootPart.Position or nil

    if refs.FruitRadarLabel then
        local fruitPos = workspace:GetAttribute("NaturalFruitPos")
        local fruitName = tostring(workspace:GetAttribute("NaturalFruitName") or I18n.Pick("Lõi Bão Tố", "Tempest Core"))
        if typeof(fruitPos) == "Vector3" and playerPos then
            local distMeters = math.max(1, math.floor((fruitPos - playerPos).Magnitude * 0.35))
            refs.FruitRadarLabel.Text = string.format("%s • %dm", fruitName, distMeters)
            if refs.FruitRadarStroke then
                refs.FruitRadarStroke.Color = Color3.fromRGB(232, 160, 255)
            end
        else
            local eqF = normalizeFruitId((player and player:GetAttribute("EquippedFruit")) or (snap.fruits and snap.fruits.equippedFruit))
            if eqF ~= "" then
                refs.FruitRadarLabel.Text = string.format("Radar: %s", I18n.GetItemDisplayName(eqF, eqF))
            else
                refs.FruitRadarLabel.Text = I18n.Pick("Radar Aether: Quét Đảo", "Aether Radar: Scanning")
            end
            if refs.FruitRadarStroke then
                refs.FruitRadarStroke.Color = Color3.fromRGB(192, 132, 252)
            end
        end
    end

    if refs.CompanionTitle then
        local partyObj = snap.party or {}
        local pMembers = type(partyObj.members) == "table" and partyObj.members or {}
        local inParty = (tostring(partyObj.partyId or "") ~= "") or (#pMembers > 1)
        if not inParty then
            refs.CompanionTitle.Text = I18n.Pick("TỔ ĐỘI: SOLO • [B]", "PARTY: SOLO • [B]")
        else
            local count = math.clamp(#pMembers, 1, 6)
            refs.CompanionTitle.Text = I18n.Pick(
                string.format("TỔ ĐỘI: %d/6 • [B]", count),
                string.format("PARTY: %d/6 • [B]", count)
            )
        end
    end

    if refs.PartyInviteBanner and refs.PartyInviteTitle then
        local pendFrom = snap.party and snap.party.pendingInviteFrom
        local hasInvite = (type(pendFrom) == "string" and #pendFrom > 0)
        refs.PartyInviteBanner.Visible = hasInvite
        if hasInvite then
            refs.PartyInviteTitle.Text = I18n.Pick(
                "Lời mời Tổ Đội: " .. pendFrom,
                "Party Invite: " .. pendFrom
            )
        end
    end

    -- 4. Proximity & Combat-Gated BossHUD (#6)
    if refs.BossBarApi then
        local showBoss = false
        if playerPos then
            local bossModel, dist = CelestialMinimap.FindClosestLiveBoss(playerPos)
            local inCombat = (type(Store.IsInBossCombat) == "function") and Store.IsInBossCombat() or false
            if bossModel then
                if dist <= 95 or (inCombat and dist <= 145) or (HUD.BossVisibleLatch and dist <= 125) then
                    local bHum = bossModel:FindFirstChildOfClass("Humanoid")
                    if bHum and bHum.Health > 0 then
                        showBoss = true
                        HUD.BossVisibleLatch = true
                        local hpRatio = bHum.Health / math.max(1, bHum.MaxHealth)
                        local phaseNum = (hpRatio <= 0.35 and 3) or (hpRatio <= 0.70 and 2) or 1
                        local breakPct = tonumber(bossModel:GetAttribute("AetherBreakPct"))
                            or math.clamp(math.floor((1 - hpRatio) * 115) % 100, 12, 96)
                        refs.BossBarApi:Update({
                            visible = true,
                            bossName = tostring(bossModel:GetAttribute("DisplayName") or bossModel.Name),
                            bossLevel = tonumber(bossModel:GetAttribute("Level")) or 150,
                            phase = phaseNum,
                            hp = bHum.Health,
                            maxHp = bHum.MaxHealth,
                            breakPct = breakPct,
                        })
                    end
                end
            end
        end
        if not showBoss then
            HUD.BossVisibleLatch = false
            refs.BossBarApi:SetVisible(false)
        end
    end

    -- 4B. Combo Rank Card Decay
    if refs.ComboCard and refs.ComboCard.Visible then
        local elapsed = os.clock() - (HUD.ComboState.LastHitClock or 0)
        if elapsed >= HUD.ComboState.WindowSec then
            HUD.ComboState.Count = 0
            refs.ComboCard.Visible = false
        elseif refs.ComboTimerFill then
            local remRatio = math.clamp(1 - (elapsed / HUD.ComboState.WindowSec), 0, 1)
            refs.ComboTimerFill.Size = UDim2.fromScale(remRatio, 1)
        end
    end

    -- 4C. Center Tactical Ranged Aim Reticle & Lock-On State (Single Crosshair: hidden when OTS dynamic crosshair is visible)
    if refs.AimReticle then
        local pGui = player and player:FindFirstChild("PlayerGui")
        local overlayGui = pGui and pGui:FindFirstChild("SkybreakActionOverlayGui")
        local otsCh = overlayGui and overlayGui:FindFirstChild("OTSCrosshair")
        local otsActive = (otsCh ~= nil and otsCh:IsA("GuiObject") and otsCh.Visible == true)

        local curSlot = tonumber((player and player:GetAttribute("ActiveSlot")) or view.activeHotbarSlot) or 1
        local isRangedSlot = (curSlot == 4) or (curSlot == 2)
        local isOTS = (player and player:GetAttribute("SkybreakOTSActive") == true)
            or (UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter)
        local lockName = (type(view.lockTarget) == "string" and #view.lockTarget > 0) and view.lockTarget or nil
        local inActiveCombat = (refs.ComboCard and refs.ComboCard.Visible == true) or (HUD.BossVisibleLatch == true)
        local isHighAlert = isRangedSlot or isOTS or (lockName ~= nil) or inActiveCombat

        refs.AimReticle.Visible = (not otsActive) and not (player and player:GetAttribute("SkybreakPhotoMode") == true)
        local arcTrans = isHighAlert and 0.04 or 0.48
        local diamondTrans = isHighAlert and 0.04 or 0.45
        local arcCol = (lockName ~= nil) and Color3.fromRGB(251, 55, 98)
            or (curSlot == 4 and Color3.fromRGB(251, 55, 98) or Color3.fromRGB(244, 92, 124))

        for _, seg in ipairs(refs.AimDashSegments or {}) do
            seg.BackgroundTransparency = arcTrans
            seg.BackgroundColor3 = arcCol
        end
        if refs.AimDiamondStroke then
            refs.AimDiamondStroke.Transparency = diamondTrans
        end
        if refs.AimCoreDot then
            refs.AimCoreDot.BackgroundTransparency = isHighAlert and 0.0 or 0.35
        end
        if refs.AimCoreStroke then
            refs.AimCoreStroke.Transparency = isHighAlert and 0.10 or 0.50
        end
        if refs.AimModePill and refs.AimModeLabel then
            if lockName then
                refs.AimModePill.Visible = true
                refs.AimModeStroke.Color = Color3.fromRGB(251, 55, 98)
                refs.AimModeLabel.Text = "LOCK • " .. UIFactory.Upper(lockName)
            elseif curSlot == 4 then
                refs.AimModePill.Visible = true
                refs.AimModeStroke.Color = Color3.fromRGB(253, 224, 71)
                refs.AimModeLabel.Text = I18n.Pick("AIM • TẦM XA", "RANGED AIM")
            else
                refs.AimModePill.Visible = false
            end
        end
    end

    -- 4D. Curved 3-Segment Cyan Dash/Dodge Arc ("LƯỚT X/3") — Touch/Mobile only; hidden on Desktop
    if refs.DashCluster then
        refs.DashCluster.Visible = UserInputService.TouchEnabled
    end
    if refs.DashCluster and refs.DashCluster.Visible and refs.PruneAndCountDashCharges then
        local now = os.clock()
        local availCharges = refs.PruneAndCountDashCharges(now)
        local maxCharges = HUD.DashState.MaxCharges
        local recentlyUsed = (now - (HUD.DashState.LastConsumeClock or 0)) < 3.6
        local inCombatOrUsed = recentlyUsed or (availCharges < maxCharges) or (refs.ComboCard and refs.ComboCard.Visible == true)

        if refs.DashCountLabel then
            refs.DashCountLabel.Text = string.format("%s %d/%d", I18n.Pick("LƯỚT", "DASH"), availCharges, maxCharges)
        end
        if refs.DashCountStroke then
            refs.DashCountStroke.Transparency = inCombatOrUsed and 0.06 or 0.32
        end
        if refs.DashCountPill then
            refs.DashCountPill.BackgroundTransparency = inCombatOrUsed and 0.05 or 0.24
        end

        -- Top-to-Bottom fill matching Screenshot 2 (2/3 = top 2 cyan segments lit, bottom 3rd segment dark obsidian)
        local activeCyan = Color3.fromRGB(56, 224, 255)
        local emptyDark = Color3.fromRGB(16, 24, 40)
        for segIdx = 1, 3 do
            local isFilled = (segIdx <= availCharges)
            local segColor = isFilled and activeCyan or emptyDark
            local segTrans = isFilled and (inCombatOrUsed and 0.02 or 0.24) or (inCombatOrUsed and 0.14 or 0.42)
            for _, bead in ipairs(refs.DashArcBeads[segIdx] or {}) do
                bead.BackgroundColor3 = segColor
                bead.BackgroundTransparency = segTrans
            end
        end

        if refs.PerfectDodgePill then
            refs.PerfectDodgePill.Visible = (now < (HUD.DashState.CalloutUntil or 0))
        end
    end

    -- 5. Contextual [E] Interact Prompt
    if refs.InteractBtn and refs.InteractApi then
        local prompt = view.interactPrompt
        local vis = (prompt and prompt.visible) == true
        refs.InteractBtn.Visible = vis
        if vis then
            refs.InteractApi:SetText("[E]  •  " .. tostring(prompt.label or I18n.Pick("TƯƠNG TÁC", "INTERACT")))
        end
    end

    -- 7. Loadout Hotbar [1]-[4] Active Champagne Gold Pill Update
    local bpCtxNow = {
        Awakened = (snap.fruits and snap.fruits.awakened == true) or (player and player:GetAttribute("FruitAwakened") == true) or false,
        DragonFormTier = drgTier,
        FruitTransform = tfStr,
    }
    if refs.LoadoutSlotRefs and refs.ApplyLoadoutPillVisual and refs.ResolveLoadoutSlotNames then
        local curActive = tonumber((player and player:GetAttribute("ActiveSlot")) or view.activeHotbarSlot) or 1
        local names = refs.ResolveLoadoutSlotNames(snap)
        for idx = 1, 4 do
            local r = refs.LoadoutSlotRefs[idx]
            if r then
                refs.ApplyLoadoutPillVisual(r, idx == curActive, names[idx])
            end
        end
        if refs.MobileArchCallout and refs.MobileArchLabel then
            local nowClk = os.clock()
            if curActive ~= refs.LastMobileSlot then
                refs.LastMobileSlot = curActive
                local mItemId = resolveSlotItemAndMastery(curActive, snap, player)
                if curActive == 2 and mItemId == "" then
                    refs.MobileArchUntil = 0
                else
                    local sArch = I18n.GetSlotArchetypeMeta(curActive, mItemId, bpCtxNow)
                    local zMeta = I18n.GetSkillMechanicsMeta(curActive, mItemId, "Z", bpCtxNow)
                    local tagSuffix = (zMeta.primaryTag ~= "") and (" • " .. zMeta.primaryTag) or ""
                    refs.MobileArchLabel.Text = UIFactory.Upper(sArch.archetypeLabel) .. tagSuffix
                    refs.MobileArchUntil = nowClk + 2.2
                end
            end
            refs.MobileArchCallout.Visible = nowClk < (refs.MobileArchUntil or 0)
        end
    end

    -- 8. Skill Cards & Diamond Ultimate Cooldowns / Mastery & Level Locks / Energy Sufficiency (C8: Real Mastery, NO pLv fallback)
    if refs.SkillSlotApis then
        local pLv = tonumber(snap.player.level) or 1
        local curActiveSlot = tonumber((player and player:GetAttribute("ActiveSlot")) or view.activeHotbarSlot or (snap.fruits and snap.fruits.activeSlot)) or 1
        local activeItemId, curMastery = resolveSlotItemAndMastery(curActiveSlot, snap, player)
        local curEnergy = dynCurEnergy
        local cds = snap.cooldowns or {}
        local elapsedSync = math.max(0, os.clock() - (Store.LastServerSyncClock or os.clock()))
        local flyingNow = (player and player:GetAttribute("SkybreakFlightActive") == true)
            or (char and char:GetAttribute("SkybreakFlightActive") == true)

        for _, entry in pairs(refs.SkillSlotApis) do
            local moveKey = entry.MoveKey
            local rawCd = 0
            local lvReq = entry.LevelReq or 1
            local masReq = entry.MasteryReq or 1
            local maxCd = entry.MaxCooldown
            local enCost = entry.EnergyCost or 0
            local resolvedLabel = entry.BaseName

            if moveKey then
                rawCd = tonumber(cds["Slot_" .. moveKey] or cds[moveKey] or cds[entry.SkillId]) or 0
                masReq, maxCd, enCost, resolvedLabel = resolveMoveSpecForSlot(
                    curActiveSlot,
                    activeItemId,
                    moveKey,
                    char,
                    player,
                    snap,
                    entry.MaxCooldown,
                    entry.EnergyCost,
                    entry.BaseName
                )
                lvReq = 1
                if moveKey == "F" and flyingNow then
                    resolvedLabel = I18n.Pick("Hạ Cánh", "Land")
                    enCost = 0
                end
            else
                rawCd = tonumber(cds[entry.SkillId]) or 0
                masReq = 1
            end

            local remCd = math.max(0, rawCd - elapsedSync)
            local isMasLocked = (moveKey ~= nil) and (curMastery < masReq)
            local isLvLocked = pLv < lvReq
            local isLocked = isMasLocked or isLvLocked
            local lockText = isMasLocked and ("Mas. " .. tostring(masReq)) or ("Lv." .. tostring(lvReq))
            local captionText = isMasLocked
                and I18n.Pick("Mở ở Mastery " .. tostring(masReq), "Mas. " .. tostring(masReq))
                or resolvedLabel
            entry.Api:Update({
                locked = isLocked,
                lockLabel = lockText,
                masteryReq = masReq,
                label = captionText,
                cooldown = remCd,
                maxCooldown = maxCd,
                outOfEnergy = enCost > curEnergy,
            })

            if entry.TagPill and entry.TagLabel and moveKey then
                if isLocked or remCd > 0 or (curActiveSlot == 2 and activeItemId == "") then
                    entry.TagPill.Visible = false
                else
                    local mMeta = I18n.GetSkillMechanicsMeta(curActiveSlot, activeItemId, moveKey, bpCtxNow)
                    local pTag = mMeta.primaryTag or ""
                    if pTag ~= "" then
                        entry.TagLabel.Text = pTag
                        entry.TagPill.Visible = true
                    else
                        entry.TagPill.Visible = false
                    end
                end
            end
        end
    end
end

function HUD.Cleanup()
    for _, conn in ipairs(HUD.Connections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    table.clear(HUD.Connections)

    if HUD.Refs then
        if HUD.Refs.AvatarPortraitApi and type(HUD.Refs.AvatarPortraitApi.Destroy) == "function" then
            pcall(function()
                HUD.Refs.AvatarPortraitApi:Destroy()
            end)
        end
        if HUD.Refs.MinimapApi and type(HUD.Refs.MinimapApi.Destroy) == "function" then
            pcall(function()
                HUD.Refs.MinimapApi:Destroy()
            end)
        end
    end

    HUDController.Cleanup()
    HUD.Refs = {}
end

return HUD
