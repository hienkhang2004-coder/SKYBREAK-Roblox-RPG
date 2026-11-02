-- SkybreakExpansion3DAndVFX.lua
-- Pass 13 High-Detail 3D Expansion Melee Weapons (Sheet 25), Ranged Guns & Bows (Sheet 26),
-- 7-Slot Modular Wearable 3D Armor Sets (Sheet 27), 3D Boss Relics (Sheet 28),
-- and Bespoke Anti-Glare 60-FPS Weapon/Gun/Armor Combat & Ambient VFX.

local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local TweenService = game:GetService('TweenService')
local Debris = game:GetService('Debris')

local M = {}

local PAL = {
    Obsidian = Color3.fromRGB(22, 18, 32),
    Slate = Color3.fromRGB(42, 48, 66),
    HotWhite = Color3.fromRGB(244, 248, 255),
    Gold = Color3.fromRGB(244, 193, 78),
    Solar = Color3.fromRGB(255, 148, 42),
    Cyan = Color3.fromRGB(56, 224, 252),
    Ice = Color3.fromRGB(145, 238, 255),
    Emerald = Color3.fromRGB(52, 211, 153),
    Jade = Color3.fromRGB(167, 243, 208),
    Magma = Color3.fromRGB(249, 115, 22),
    Crimson = Color3.fromRGB(244, 63, 94),
    Violet = Color3.fromRGB(182, 92, 252),
    Chrono = Color3.fromRGB(192, 132, 252),
    Walnut = Color3.fromRGB(108, 64, 38),
    Ivory = Color3.fromRGB(238, 234, 222),
}

local EXPANSION_SWORD_IDS = {
    sunshard_halberd = true,
    cyber_katana_mk2 = true,
    sylvaris_thornblade = true,
    ignivar_magma_breaker = true,
    nerith_abyssal_trident = true,
    aion_chrono_scythe = true,
    architect_severance = true,
    eternal_frost_staff = true,
}

local EXPANSION_GUN_IDS = {
    sylvaris_thornbow = true,
    ignivar_hellcannon = true,
    aion_chrono_pistols = true,
    veyr_singularity_cannon = true,
    kabucha_wind = true,
    aether_flintlock = true,
    bizarre_rifle_cyber = true,
}

function M.IsExpansionSword(swordId)
    local id = string.lower(tostring(swordId or ''))
    return EXPANSION_SWORD_IDS[id] == true
end

function M.IsExpansionGun(gunId)
    local id = string.lower(tostring(gunId or ''))
    return EXPANSION_GUN_IDS[id] == true
end

function M.IsDualGun(gunId)
    local id = string.lower(tostring(gunId or ''))
    return id == 'aion_chrono_pistols' or id:find('chrono_pistol') ~= nil
end

local function makePart(parent, name, size, color, shape, transparency, className, material, reflectance)
    local p = Instance.new(className or 'Part')
    p.Name = name
    if not className or className == 'Part' then
        p.Shape = shape or Enum.PartType.Block
    end
    p.Size = size
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.Reflectance = reflectance or 0
    p.Transparency = transparency or 0
    p.Anchored = true
    p.CanCollide = false
    p.CanQuery = false
    p.CanTouch = false
    p.Massless = true
    p.CastShadow = false
    p.Parent = parent
    return p
end

local function addSafePointLight(parent, color, brightness, range)
    local pl = Instance.new('PointLight')
    pl.Name = 'AntiGlareEquipLight'
    pl.Color = color
    pl.Brightness = math.clamp(brightness or 0.95, 0.1, 1.35)
    pl.Range = math.clamp(range or 9, 2, 14)
    pl.Shadows = false
    pl.Parent = parent
    return pl
end

local function addAmbientMotes(parent, name, c1, c2, rate, size0, speedRange, accel, lowFX)
    local pe = Instance.new('ParticleEmitter')
    pe.Name = name or 'ElementalAmbientMotes'
    pe.Color = ColorSequence.new(c1, c2 or PAL.HotWhite)
    pe.LightEmission = 0.72 -- Strictly <= 0.78 anti-glare budget
    pe.LightInfluence = 0.25
    pe.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, size0 or 0.16),
        NumberSequenceKeypoint.new(0.65, (size0 or 0.16) * 0.65),
        NumberSequenceKeypoint.new(1, 0),
    })
    pe.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.24),
        NumberSequenceKeypoint.new(0.7, 0.55),
        NumberSequenceKeypoint.new(1, 1.0),
    })
    pe.Lifetime = NumberRange.new(0.45, 0.95)
    pe.Rate = lowFX and math.max(2, math.floor((rate or 10) * 0.35)) or (rate or 10)
    pe.Speed = speedRange or NumberRange.new(0.8, 2.2)
    pe.Acceleration = accel or Vector3.new(0, 1.5, 0)
    pe.SpreadAngle = Vector2.new(160, 160)
    pe.Enabled = not lowFX
    pe.Parent = parent
    return pe
end

local function addRelPart(list, part, relCF, animRole, phase)
    table.insert(list, {
        Part = part,
        RelCF = relCF or CFrame.identity,
        OrigTrans = part.Transparency,
        AnimRole = animRole,
        Phase = phase or 0,
    })
    return part
end

-- ============================================================================
-- 1. PASS 13 EXPANSION MELEE WEAPONS (SHEET 25) & RANGED GUNS/BOWS (SHEET 26)
-- ============================================================================
function M.BuildExpansionWeaponModel(assetName, rawItemId, isLeftHand, lowFX)
    local id = string.lower(tostring(rawItemId or assetName or ''))
    id = id:gsub('^expsword_', ''):gsub('^expgun_', '')
    local model = Instance.new('Model')
    model.Name = tostring(assetName or id)
    model:SetAttribute('ExpansionPass13', true)

    local root = makePart(model, 'RootPart', Vector3.new(0.16, 0.16, 0.16), PAL.Gold, Enum.PartType.Block, 1)
    model.PrimaryPart = root

    local relParts = {}
    local isGun = EXPANSION_GUN_IDS[id] == true
    local boxSpanY = 4.8

    -- ------------------------------------------------------------------------
    -- A. 8 EXPANSION MELEE WEAPONS (Aligned along +Y blade axis from grip at 0,0,0)
    -- ------------------------------------------------------------------------
    if id == 'sunshard_halberd' then
        boxSpanY = 5.6
        -- Fluted gold & ivory polearm shaft
        addRelPart(relParts, makePart(model, 'HalberdShaft', Vector3.new(5.2, 0.16, 0.16), PAL.Ivory, Enum.PartType.Cylinder, 0, 'Part', Enum.Material.Metal, 0.12), CFrame.new(0, 1.65, 0) * CFrame.Angles(0, 0, math.pi * 0.5))
        for i = -1, 3 do
            addRelPart(relParts, makePart(model, 'ShaftGoldRing_' .. i, Vector3.new(0.14, 0.22, 0.22), PAL.Gold, Enum.PartType.Cylinder, 0, 'Part', Enum.Material.Metal, 0.18), CFrame.new(0, i * 0.85, 0) * CFrame.Angles(0, 0, math.pi * 0.5))
        end
        -- Pommel sun-ring
        addRelPart(relParts, makePart(model, 'HalberdPommelRing', Vector3.new(0.10, 0.48, 0.48), PAL.Gold, Enum.PartType.Cylinder, 0, 'Part', Enum.Material.Metal, 0.18), CFrame.new(0, -1.05, 0) * CFrame.Angles(0, math.pi * 0.5, 0))
        -- Solar Crossguard & Diamond Sun-Core
        local core = addRelPart(relParts, makePart(model, 'SolarSunCore', Vector3.new(0.38, 0.52, 0.26), PAL.Solar, Enum.PartType.Block, 0.04, 'Part', Enum.Material.Neon, 0), CFrame.new(0, 3.35, 0) * CFrame.Angles(0, 0, math.pi * 0.25), 'PulseGlow', 0)
        addSafePointLight(core, PAL.Gold, 1.05, 9)
        addAmbientMotes(core, 'SunshardMotes', PAL.Gold, PAL.Solar, 9, 0.15, NumberRange.new(0.8, 2.0), Vector3.new(0, 1.8, 0), lowFX)
        -- Spinning Solar Halo around Halberd head
        addRelPart(relParts, makePart(model, 'SolarHalberdHalo', Vector3.new(0.08, 1.38, 1.38), PAL.Gold, Enum.PartType.Cylinder, 0.18, 'Part', Enum.Material.ForceField, 0), CFrame.new(0, 3.55, 0) * CFrame.Angles(0, math.pi * 0.5, 0), 'SpinZ', 0)
        -- Main Spear Tip + Twin Crescent Halberd Axes
        addRelPart(relParts, makePart(model, 'HalberdSpearTip', Vector3.new(0.14, 1.65, 0.34), PAL.Gold, Enum.PartType.Block, 0, 'WedgePart', Enum.Material.Metal, 0.18), CFrame.new(0, 4.45, 0))
        addRelPart(relParts, makePart(model, 'HalberdSpearEdge', Vector3.new(0.08, 1.50, 0.20), PAL.HotWhite, Enum.PartType.Block, 0.05, 'WedgePart', Enum.Material.Neon, 0), CFrame.new(0, 4.48, -0.08))
        for _, sgn in ipairs({ -1, 1 }) do
            local scaleW = sgn > 0 and 0.88 or 0.58
            addRelPart(relParts, makePart(model, 'CrescentWing_' .. sgn, Vector3.new(0.12, 1.42, scaleW), PAL.Gold, Enum.PartType.Block, 0, 'WedgePart', Enum.Material.Metal, 0.16), CFrame.new(0, 3.55, -sgn * (scaleW * 0.48)) * CFrame.Angles(0, sgn > 0 and 0 or math.pi, 0))
            addRelPart(relParts, makePart(model, 'CrescentEdge_' .. sgn, Vector3.new(0.07, 1.32, scaleW * 0.45), PAL.Solar, Enum.PartType.Block, 0.06, 'WedgePart', Enum.Material.Neon, 0), CFrame.new(0, 3.55, -sgn * (scaleW * 0.78)) * CFrame.Angles(0, sgn > 0 and 0 or math.pi, 0))
        end

    elseif id == 'cyber_katana_mk2' then
        boxSpanY = 4.9
        -- Tactical carbon-weave tsuka hilt + cyan grip diamonds
        addRelPart(relParts, makePart(model, 'KatanaTsuka', Vector3.new(0.14, 1.25, 0.22), PAL.Obsidian, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.08), CFrame.new(0, -0.25, 0))
        for i = 1, 4 do
            addRelPart(relParts, makePart(model, 'TsukaDiamond_' .. i, Vector3.new(0.16, 0.12, 0.12), PAL.Cyan, Enum.PartType.Block, 0.04, 'Part', Enum.Material.Neon, 0), CFrame.new(0, -0.72 + i * 0.22, 0) * CFrame.Angles(0.78, 0, 0))
        end
        -- Hexagonal Cyber Tsuba Guard + Power Conduit
        local tsuba = addRelPart(relParts, makePart(model, 'KatanaHexTsuba', Vector3.new(0.14, 0.58, 0.58), PAL.Slate, Enum.PartType.Cylinder, 0, 'Part', Enum.Material.Metal, 0.16), CFrame.new(0, 0.42, 0) * CFrame.Angles(0, 0, math.pi * 0.5))
        local tsubaRim = addRelPart(relParts, makePart(model, 'KatanaTsubaGlow', Vector3.new(0.10, 0.64, 0.64), PAL.Cyan, Enum.PartType.Cylinder, 0.12, 'Part', Enum.Material.Neon, 0), CFrame.new(0, 0.42, 0) * CFrame.Angles(0, 0, math.pi * 0.5), 'PulseGlow', 0)
        addSafePointLight(tsubaRim, PAL.Cyan, 1.0, 9)
        addAmbientMotes(tsuba, 'QuantumBladeSparks', PAL.Cyan, PAL.Violet, 10, 0.13, NumberRange.new(1.0, 2.4), Vector3.new(0, 2.2, 0), lowFX)
        -- Dark Titanium Spine + High-Frequency Cyan Plasma Edge (3 slightly curved segments)
        for seg = 1, 3 do
            local yPos = 0.55 + (seg - 0.5) * 1.28
            local pitch = -0.035 * seg
            local zOff = -0.02 * seg * seg
            addRelPart(relParts, makePart(model, 'KatanaSpine_' .. seg, Vector3.new(0.08, 1.32, 0.18), PAL.Obsidian, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.18), CFrame.new(0, yPos, zOff + 0.05) * CFrame.Angles(pitch, 0, 0))
            addRelPart(relParts, makePart(model, 'KatanaPlasmaEdge_' .. seg, Vector3.new(0.05, 1.32, 0.12), PAL.Cyan, Enum.PartType.Block, 0.04, 'WedgePart', Enum.Material.Neon, 0), CFrame.new(0, yPos, zOff - 0.08) * CFrame.Angles(pitch, 0, 0))
        end

    elseif id == 'sylvaris_thornblade' then
        boxSpanY = 5.2
        -- Living Heartwood Hilt & Golden Root Pommel
        addRelPart(relParts, makePart(model, 'SylvarisGrip', Vector3.new(1.25, 0.18, 0.18), PAL.Walnut, Enum.PartType.Cylinder, 0, 'Part', Enum.Material.SmoothPlastic, 0.04), CFrame.new(0, -0.25, 0) * CFrame.Angles(0, 0, math.pi * 0.5))
        addRelPart(relParts, makePart(model, 'SylvarisPommelGem', Vector3.new(0.28, 0.28, 0.28), PAL.Emerald, Enum.PartType.Ball, 0.04, 'Part', Enum.Material.Neon, 0), CFrame.new(0, -0.92, 0))
        -- Golden Stag-Antler Crossguard + Heartwood Core
        local guardCore = addRelPart(relParts, makePart(model, 'SylvarisHeartGem', Vector3.new(0.32, 0.42, 0.32), PAL.Emerald, Enum.PartType.Ball, 0.04, 'Part', Enum.Material.Neon, 0), CFrame.new(0, 0.48, 0), 'PulseGlow', 0)
        addSafePointLight(guardCore, PAL.Emerald, 1.05, 9)
        addAmbientMotes(guardCore, 'SylvarisLeafMotes', PAL.Emerald, PAL.Jade, 10, 0.16, NumberRange.new(0.7, 1.8), Vector3.new(0, 1.4, 0), lowFX)
        for _, sgn in ipairs({ -1, 1 }) do
            addRelPart(relParts, makePart(model, 'AntlerGuard_' .. sgn, Vector3.new(0.14, 0.85, 0.22), PAL.Gold, Enum.PartType.Block, 0, 'WedgePart', Enum.Material.Metal, 0.16), CFrame.new(0, 0.62, -sgn * 0.48) * CFrame.Angles(sgn * 0.65, 0, 0))
        end
        -- Living Wood Spine + Sculpted Emerald Crystal Greatsaber Blade
        addRelPart(relParts, makePart(model, 'HeartwoodSpine', Vector3.new(0.14, 3.65, 0.24), PAL.Walnut, Enum.PartType.Block, 0, 'Part', Enum.Material.SmoothPlastic, 0.04), CFrame.new(0, 2.35, 0.08))
        addRelPart(relParts, makePart(model, 'EmeraldCrystalBlade', Vector3.new(0.10, 3.85, 0.42), PAL.Emerald, Enum.PartType.Block, 0.08, 'WedgePart', Enum.Material.Glass, 0.12), CFrame.new(0, 2.45, -0.16))
        addRelPart(relParts, makePart(model, 'JadeCoreVein', Vector3.new(0.06, 3.55, 0.14), PAL.Jade, Enum.PartType.Block, 0.04, 'Part', Enum.Material.Neon, 0), CFrame.new(0, 2.38, -0.04))

    elseif id == 'ignivar_magma_breaker' then
        boxSpanY = 5.5
        -- Heavy Brass & Obsidian Hilt
        addRelPart(relParts, makePart(model, 'MagmaHilt', Vector3.new(1.35, 0.22, 0.22), PAL.Obsidian, Enum.PartType.Cylinder, 0, 'Part', Enum.Material.Metal, 0.10), CFrame.new(0, -0.30, 0) * CFrame.Angles(0, 0, math.pi * 0.5))
        -- Twin Dragon-Horn Furnace Guard
        local furnace = addRelPart(relParts, makePart(model, 'IgnivarFurnaceCore', Vector3.new(0.38, 0.48, 0.56), PAL.Magma, Enum.PartType.Block, 0.04, 'Part', Enum.Material.Neon, 0), CFrame.new(0, 0.55, 0), 'PulseGlow', 0)
        addSafePointLight(furnace, PAL.Magma, 1.12, 10)
        addAmbientMotes(furnace, 'MagmaBreakerEmbers', PAL.Magma, PAL.Gold, 12, 0.17, NumberRange.new(1.0, 2.6), Vector3.new(0, 2.8, 0), lowFX)
        for _, sgn in ipairs({ -1, 1 }) do
            addRelPart(relParts, makePart(model, 'DragonGuardHorn_' .. sgn, Vector3.new(0.24, 0.92, 0.32), PAL.Gold, Enum.PartType.Block, 0, 'WedgePart', Enum.Material.Metal, 0.15), CFrame.new(0, 0.68, -sgn * 0.56) * CFrame.Angles(sgn * 0.72, 0, 0))
        end
        -- Colossal Tectonic Obsidian Slab + 4 Glowing Molten Magma Fissures
        addRelPart(relParts, makePart(model, 'ObsidianSlabLeft', Vector3.new(0.22, 3.85, 0.38), PAL.Obsidian, Enum.PartType.Block, 0, 'WedgePart', Enum.Material.Slate, 0), CFrame.new(0, 2.65, -0.24))
        addRelPart(relParts, makePart(model, 'ObsidianSlabRight', Vector3.new(0.22, 3.85, 0.38), PAL.Obsidian, Enum.PartType.Block, 0, 'WedgePart', Enum.Material.Slate, 0), CFrame.new(0, 2.65, 0.24) * CFrame.Angles(0, math.pi, 0))
        addRelPart(relParts, makePart(model, 'MoltenMagmaCoreChannel', Vector3.new(0.16, 3.95, 0.28), PAL.Magma, Enum.PartType.Block, 0.04, 'Part', Enum.Material.Neon, 0), CFrame.new(0, 2.68, 0), 'PulseGlow', 0.8)
        for i = 1, 4 do
            local sgn = (i % 2 == 0) and 1 or -1
            addRelPart(relParts, makePart(model, 'MagmaTooth_' .. i, Vector3.new(0.14, 0.42, 0.28), PAL.Solar, Enum.PartType.Block, 0.04, 'WedgePart', Enum.Material.Neon, 0), CFrame.new(0, 1.15 + i * 0.72, sgn * 0.36) * CFrame.Angles(0, sgn > 0 and math.pi or 0, 0))
        end

    elseif id == 'nerith_abyssal_trident' then
        boxSpanY = 5.7
        -- Spiral Abyssal Coral & Gold Shaft
        addRelPart(relParts, makePart(model, 'TridentShaft', Vector3.new(5.1, 0.16, 0.16), Color3.fromRGB(22, 58, 88), Enum.PartType.Cylinder, 0, 'Part', Enum.Material.Metal, 0.14), CFrame.new(0, 1.55, 0) * CFrame.Angles(0, 0, math.pi * 0.5))
        -- Sea-Dragon Pearl Collar + Orbiting Water Ring
        local pearl = addRelPart(relParts, makePart(model, 'AbyssalPearlCore', Vector3.new(0.42, 0.42, 0.42), PAL.Cyan, Enum.PartType.Ball, 0.04, 'Part', Enum.Material.Neon, 0), CFrame.new(0, 3.35, 0), 'PulseGlow', 0)
        addSafePointLight(pearl, PAL.Cyan, 1.05, 9)
        addAmbientMotes(pearl, 'AbyssalTideMotes', PAL.Cyan, PAL.Ice, 10, 0.15, NumberRange.new(0.8, 2.0), Vector3.new(0, 1.8, 0), lowFX)
        addRelPart(relParts, makePart(model, 'TridentWaterHalo', Vector3.new(0.08, 1.28, 1.28), PAL.Cyan, Enum.PartType.Cylinder, 0.22, 'Part', Enum.Material.ForceField, 0), CFrame.new(0, 3.35, 0) * CFrame.Angles(0.35, 0, math.pi * 0.5), 'SpinY', 0)
        -- 3 Bioluminescent Serrated Prongs
        addRelPart(relParts, makePart(model, 'TridentCrossBar', Vector3.new(0.18, 0.22, 1.26), PAL.Gold, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.18), CFrame.new(0, 3.42, 0))
        for p = -1, 1 do
            local h = (p == 0) and 1.95 or 1.55
            local col = (p == 0) and PAL.Cyan or PAL.Gold
            addRelPart(relParts, makePart(model, 'TridentProng_' .. p, Vector3.new(0.12, h, 0.22), col, Enum.PartType.Block, 0.04, 'WedgePart', Enum.Material.Neon, 0), CFrame.new(0, 3.45 + h * 0.5, p * 0.52) * CFrame.Angles(-p * 0.08, 0, 0))
        end

    elseif id == 'aion_chrono_scythe' then
        boxSpanY = 5.6
        -- Curved Nebula & Gold Scythe Snath
        addRelPart(relParts, makePart(model, 'ChronoScytheShaft', Vector3.new(5.2, 0.16, 0.16), Color3.fromRGB(36, 26, 68), Enum.PartType.Cylinder, 0, 'Part', Enum.Material.Metal, 0.14), CFrame.new(0, 1.65, 0) * CFrame.Angles(0, 0, math.pi * 0.5))
        -- Spinning Golden Clockwork Astrolabe Collar + Counter-Rotating Clock Hands!
        local clockWheel = addRelPart(relParts, makePart(model, 'ScytheAstrolabeWheel', Vector3.new(0.10, 1.45, 1.45), PAL.Gold, Enum.PartType.Cylinder, 0.08, 'Part', Enum.Material.Metal, 0.20), CFrame.new(0, 3.85, 0) * CFrame.Angles(0, math.pi * 0.5, 0), 'SpinX', 0)
        addRelPart(relParts, makePart(model, 'ScytheClockHandHour', Vector3.new(0.12, 0.58, 0.08), PAL.Cyan, Enum.PartType.Block, 0.04, 'Part', Enum.Material.Neon, 0), CFrame.new(0, 3.85, 0), 'SpinXFast', 0)
        addSafePointLight(clockWheel, PAL.Chrono, 1.08, 10)
        addAmbientMotes(clockWheel, 'ChronoSandMotes', PAL.Chrono, PAL.Gold, 10, 0.15, NumberRange.new(0.7, 1.8), Vector3.new(0, 1.4, 0), lowFX)
        -- Giant Crescent Astral Scythe Blade (Sweeping forward along -Z)
        addRelPart(relParts, makePart(model, 'ChronoCrescentSpine', Vector3.new(0.14, 0.34, 2.35), PAL.Gold, Enum.PartType.Block, 0, 'WedgePart', Enum.Material.Metal, 0.18), CFrame.new(0, 4.02, -1.05) * CFrame.Angles(0.22, 0, 0))
        addRelPart(relParts, makePart(model, 'ChronoCrescentEdge', Vector3.new(0.08, 0.28, 2.55), PAL.Chrono, Enum.PartType.Block, 0.05, 'WedgePart', Enum.Material.Neon, 0), CFrame.new(0, 3.82, -1.18) * CFrame.Angles(0.28, 0, math.pi))

    elseif id == 'architect_severance' then
        boxSpanY = 5.5
        -- Sovereign Obsidian & Gold Hilt
        addRelPart(relParts, makePart(model, 'SeveranceHilt', Vector3.new(1.30, 0.18, 0.18), PAL.Obsidian, Enum.PartType.Cylinder, 0, 'Part', Enum.Material.Metal, 0.14), CFrame.new(0, -0.28, 0) * CFrame.Angles(0, 0, math.pi * 0.5))
        addRelPart(relParts, makePart(model, 'SeveranceCrossguard', Vector3.new(0.20, 0.28, 1.32), PAL.Gold, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.20), CFrame.new(0, 0.45, 0))
        -- Suspended Black-Hole Singularity Core + Counter-Rotating Accretion Rings
        local bhCore = addRelPart(relParts, makePart(model, 'SingularityBladeCore', Vector3.new(0.46, 0.46, 0.46), PAL.Obsidian, Enum.PartType.Ball, 0.02, 'Part', Enum.Material.SmoothPlastic, 0), CFrame.new(0, 1.85, 0), 'BobY', 0)
        local accRing = addRelPart(relParts, makePart(model, 'SingularityAccretionRing', Vector3.new(0.08, 1.15, 1.15), PAL.Crimson, Enum.PartType.Cylinder, 0.12, 'Part', Enum.Material.Neon, 0), CFrame.new(0, 1.85, 0) * CFrame.Angles(0.45, 0, math.pi * 0.5), 'SpinY', 0)
        addSafePointLight(accRing, PAL.Crimson, 1.15, 10)
        addAmbientMotes(accRing, 'SingularityBladeSparks', PAL.Crimson, PAL.Gold, 11, 0.16, NumberRange.new(0.9, 2.3), Vector3.new(0, 2.0, 0), lowFX)
        -- Split Twin Reality Blades flanking the singularity gap
        for _, sgn in ipairs({ -1, 1 }) do
            addRelPart(relParts, makePart(model, 'SplitRealityBlade_' .. sgn, Vector3.new(0.10, 3.85, 0.24), PAL.Obsidian, Enum.PartType.Block, 0, 'WedgePart', Enum.Material.Metal, 0.18), CFrame.new(0, 2.55, sgn * 0.28) * CFrame.Angles(0, sgn > 0 and math.pi or 0, 0))
            addRelPart(relParts, makePart(model, 'SplitCrimsonEdge_' .. sgn, Vector3.new(0.06, 3.75, 0.12), sgn > 0 and PAL.Crimson or PAL.Gold, Enum.PartType.Block, 0.04, 'WedgePart', Enum.Material.Neon, 0), CFrame.new(0, 2.55, sgn * 0.40) * CFrame.Angles(0, sgn > 0 and math.pi or 0, 0))
        end

    elseif id == 'eternal_frost_staff' then
        boxSpanY = 5.6
        -- Silver-White Cryo-Chrono Archmage Shaft
        addRelPart(relParts, makePart(model, 'FrostStaffShaft', Vector3.new(5.0, 0.15, 0.15), PAL.Ivory, Enum.PartType.Cylinder, 0, 'Part', Enum.Material.Metal, 0.16), CFrame.new(0, 1.50, 0) * CFrame.Angles(0, 0, math.pi * 0.5))
        -- Levitating Sapphire Diamond Core + 2 Counter-Rotating Glacial Armillary Rings
        local frostCore = addRelPart(relParts, makePart(model, 'EternalFrostCore', Vector3.new(0.42, 0.62, 0.42), PAL.Cyan, Enum.PartType.Block, 0.06, 'Part', Enum.Material.Neon, 0), CFrame.new(0, 4.15, 0) * CFrame.Angles(0.78, 0, 0.78), 'SpinY', 0)
        addRelPart(relParts, makePart(model, 'GlacialArmillaryA', Vector3.new(0.08, 1.38, 1.38), PAL.Gold, Enum.PartType.Cylinder, 0.12, 'Part', Enum.Material.Metal, 0.20), CFrame.new(0, 4.15, 0) * CFrame.Angles(0.52, 0, math.pi * 0.5), 'SpinX', 0)
        addRelPart(relParts, makePart(model, 'GlacialArmillaryB', Vector3.new(0.08, 1.12, 1.12), PAL.Ice, Enum.PartType.Cylinder, 0.16, 'Part', Enum.Material.Neon, 0), CFrame.new(0, 4.15, 0) * CFrame.Angles(-0.52, 0, 0), 'SpinZ', 1.2)
        addSafePointLight(frostCore, PAL.Cyan, 1.05, 9)
        addAmbientMotes(frostCore, 'EternalFrostMotes', PAL.Ice, PAL.HotWhite, 10, 0.15, NumberRange.new(0.7, 1.8), Vector3.new(0, -1.2, 0), lowFX)
        -- 4 Levitating Icicle Crown Spires
        for i = 1, 4 do
            local ang = (i - 1) * (math.pi * 0.5)
            addRelPart(relParts, makePart(model, 'IcicleCrown_' .. i, Vector3.new(0.12, 0.68, 0.16), PAL.Ice, Enum.PartType.Block, 0.10, 'WedgePart', Enum.Material.Glass, 0.10), CFrame.new(math.cos(ang) * 0.58, 4.65, math.sin(ang) * 0.58) * CFrame.Angles(0, -ang, 0), 'BobY', i * 0.8)
        end

    -- ------------------------------------------------------------------------
    -- B. 7 EXPANSION RANGED GUNS & BOWS (SHEET 26)
    --    Aim axis in _RightGunRot is +Y (barrel points along +Y, Up is -Z)
    -- ------------------------------------------------------------------------
    elseif id == 'sylvaris_thornbow' then
        boxSpanY = 4.6
        -- Golden Antler Riser Grip
        addRelPart(relParts, makePart(model, 'BowAntlerRiser', Vector3.new(0.20, 0.55, 0.92), PAL.Gold, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.18), CFrame.new(0, 0.15, 0))
        -- Upper & Lower Living Heartwood Limbs (spanning along Z so bow stands vertically when aimed!)
        for _, sgn in ipairs({ -1, 1 }) do
            addRelPart(relParts, makePart(model, 'BowHeartwoodLimb_' .. sgn, Vector3.new(0.16, 0.85, 1.75), PAL.Walnut, Enum.PartType.Block, 0, 'WedgePart', Enum.Material.SmoothPlastic, 0.04), CFrame.new(0, -0.10, sgn * 1.18) * CFrame.Angles(sgn * 0.28, 0, 0))
            for f = 1, 3 do
                addRelPart(relParts, makePart(model, 'BowEmeraldFeather_' .. sgn .. '_' .. f, Vector3.new(0.10, 0.42, 0.22), f % 2 == 0 and PAL.Jade or PAL.Emerald, Enum.PartType.Block, 0.04, 'WedgePart', Enum.Material.Neon, 0), CFrame.new(0, 0.18 - f * 0.12, sgn * (0.68 + f * 0.36)) * CFrame.Angles(sgn * 0.35, 0, 0))
            end
        end
        -- Taut Cyan-Emerald Energy Bowstring + Nocked Spirit Arrow + Spinning Wind Rings
        addRelPart(relParts, makePart(model, 'BowEnergyString', Vector3.new(0.05, 0.05, 3.65), PAL.Jade, Enum.PartType.Block, 0.10, 'Part', Enum.Material.Neon, 0), CFrame.new(0, -0.52, 0))
        local arrowShaft = addRelPart(relParts, makePart(model, 'SpiritArrowShaft', Vector3.new(0.08, 2.35, 0.08), PAL.Emerald, Enum.PartType.Block, 0.04, 'Part', Enum.Material.Neon, 0), CFrame.new(0, 0.65, 0))
        local arrowHead = addRelPart(relParts, makePart(model, 'SpiritArrowHead', Vector3.new(0.16, 0.48, 0.26), PAL.Cyan, Enum.PartType.Block, 0.04, 'WedgePart', Enum.Material.Neon, 0), CFrame.new(0, 1.95, 0), 'PulseGlow', 0)
        addRelPart(relParts, makePart(model, 'ArrowWindRing1', Vector3.new(0.06, 0.68, 0.68), PAL.Emerald, Enum.PartType.Cylinder, 0.22, 'Part', Enum.Material.ForceField, 0), CFrame.new(0, 1.65, 0) * CFrame.Angles(0, 0, math.pi * 0.5), 'SpinY', 0)
        addRelPart(relParts, makePart(model, 'ArrowWindRing2', Vector3.new(0.06, 0.48, 0.48), PAL.Jade, Enum.PartType.Cylinder, 0.22, 'Part', Enum.Material.ForceField, 0), CFrame.new(0, 1.92, 0) * CFrame.Angles(0, 0, math.pi * 0.5), 'SpinY', 1.5)
        addSafePointLight(arrowHead, PAL.Emerald, 1.0, 9)
        addAmbientMotes(arrowShaft, 'SpiritBowMotes', PAL.Emerald, PAL.Jade, 9, 0.14, NumberRange.new(0.6, 1.6), Vector3.new(0, 1.4, 0), lowFX)

    elseif id == 'ignivar_hellcannon' then
        boxSpanY = 4.4
        -- Heavy Volcanic Siege Barrel + 3 Brass Reinforcing Bands
        addRelPart(relParts, makePart(model, 'HellcannonBarrel', Vector3.new(2.65, 0.72, 0.72), PAL.Obsidian, Enum.PartType.Cylinder, 0, 'Part', Enum.Material.Metal, 0.14), CFrame.new(0, 1.05, 0) * CFrame.Angles(0, 0, math.pi * 0.5))
        for b = 1, 3 do
            addRelPart(relParts, makePart(model, 'BrassBand_' .. b, Vector3.new(0.18, 0.80, 0.80), PAL.Gold, Enum.PartType.Cylinder, 0, 'Part', Enum.Material.Metal, 0.20), CFrame.new(0, 0.05 + b * 0.68, 0) * CFrame.Angles(0, 0, math.pi * 0.5))
        end
        -- Underslung Molten Magma Reservoir Drum
        addRelPart(relParts, makePart(model, 'MagmaReservoirDrum', Vector3.new(0.95, 0.52, 0.52), PAL.Magma, Enum.PartType.Cylinder, 0.04, 'Part', Enum.Material.Neon, 0), CFrame.new(0, 0.75, 0.42) * CFrame.Angles(0, 0, math.pi * 0.5), 'PulseGlow', 0)
        -- Twin Dorsal Brass Exhaust Chimneys + Rising Steam/Ember Emitters
        for _, sgn in ipairs({ -1, 1 }) do
            local stack = addRelPart(relParts, makePart(model, 'ExhaustChimney_' .. sgn, Vector3.new(0.52, 0.18, 0.18), PAL.Gold, Enum.PartType.Cylinder, 0, 'Part', Enum.Material.Metal, 0.18), CFrame.new(sgn * 0.22, 0.62, -0.46) * CFrame.Angles(0.25, 0, 0))
            addAmbientMotes(stack, 'ChimneySteamEmbers', PAL.Magma, PAL.Gold, 7, 0.18, NumberRange.new(1.2, 2.6), Vector3.new(0, 3.2, 0), lowFX)
        end
        -- Dragon-Maw Muzzle Crown + 4 Ivory Fangs + Glowing Furnace Grate Core
        addRelPart(relParts, makePart(model, 'DragonMawCrown', Vector3.new(0.32, 0.88, 0.88), PAL.Gold, Enum.PartType.Cylinder, 0, 'Part', Enum.Material.Metal, 0.20), CFrame.new(0, 2.38, 0) * CFrame.Angles(0, 0, math.pi * 0.5))
        local mawCore = addRelPart(relParts, makePart(model, 'DragonMawFurnace', Vector3.new(0.18, 0.62, 0.62), PAL.Solar, Enum.PartType.Cylinder, 0.04, 'Part', Enum.Material.Neon, 0), CFrame.new(0, 2.48, 0) * CFrame.Angles(0, 0, math.pi * 0.5), 'PulseGlow', 0.5)
        addSafePointLight(mawCore, PAL.Magma, 1.15, 10)
        for f = 1, 4 do
            local ang = (f - 0.5) * (math.pi * 0.5)
            addRelPart(relParts, makePart(model, 'DragonFang_' .. f, Vector3.new(0.12, 0.34, 0.14), PAL.Ivory, Enum.PartType.Block, 0, 'WedgePart', Enum.Material.SmoothPlastic, 0.04), CFrame.new(math.cos(ang) * 0.30, 2.62, math.sin(ang) * 0.30) * CFrame.Angles(0, -ang, 0))
        end

    elseif id == 'aion_chrono_pistols' then
        boxSpanY = 2.6
        -- Ornate Gold & Deep Violet Filigree Grip
        addRelPart(relParts, makePart(model, 'ChronoPistolGrip', Vector3.new(0.20, 0.72, 0.32), Color3.fromRGB(48, 28, 86), Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.14), CFrame.new(0, -0.18, 0.22) * CFrame.Angles(0.38, 0, 0))
        addRelPart(relParts, makePart(model, 'ChronoGripPommel', Vector3.new(0.22, 0.22, 0.22), PAL.Gold, Enum.PartType.Ball, 0, 'Part', Enum.Material.Metal, 0.20), CFrame.new(0, -0.48, 0.38))
        -- Deep Violet Void-Metal Frame & Octagonal Barrel + Gold Dorsal Rib
        addRelPart(relParts, makePart(model, 'ChronoPistolBarrel', Vector3.new(0.22, 1.68, 0.28), Color3.fromRGB(44, 26, 82), Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.15), CFrame.new(0, 0.88, -0.06))
        addRelPart(relParts, makePart(model, 'ChronoGoldRib', Vector3.new(0.12, 1.72, 0.10), PAL.Gold, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.20), CFrame.new(0, 0.90, -0.22))
        -- Revolving Golden Astrolabe Cylinder + 6 Glowing Cyan/Magenta Phase Chambers!
        local cylColor = isLeftHand and PAL.Cyan or PAL.Chrono
        local cyl = addRelPart(relParts, makePart(model, 'AstrolabeRevolverCylinder', Vector3.new(0.46, 0.44, 0.44), PAL.Gold, Enum.PartType.Cylinder, 0, 'Part', Enum.Material.Metal, 0.20), CFrame.new(0, 0.36, -0.04) * CFrame.Angles(0, 0, math.pi * 0.5), 'SpinY', isLeftHand and 1.5 or 0)
        addRelPart(relParts, makePart(model, 'AstrolabeChamberGlow', Vector3.new(0.48, 0.34, 0.34), cylColor, Enum.PartType.Cylinder, 0.06, 'Part', Enum.Material.Neon, 0), CFrame.new(0, 0.36, -0.04) * CFrame.Angles(0, 0, math.pi * 0.5), 'PulseGlow', 0)
        -- Floating Golden Clock-Ring Halo at Muzzle
        local muzRing = addRelPart(relParts, makePart(model, 'ChronoMuzzleHalo', Vector3.new(0.06, 0.56, 0.56), PAL.Gold, Enum.PartType.Cylinder, 0.14, 'Part', Enum.Material.Neon, 0), CFrame.new(0, 1.78, -0.06) * CFrame.Angles(0, 0, math.pi * 0.5), 'SpinY', 0)
        addSafePointLight(cyl, cylColor, 0.95, 8)
        addAmbientMotes(muzRing, 'ChronoPistolMotes', cylColor, PAL.Gold, 6, 0.12, NumberRange.new(0.5, 1.4), Vector3.new(0, 1.2, 0), lowFX)

    elseif id == 'veyr_singularity_cannon' then
        boxSpanY = 4.8
        -- Sovereign Obsidian & Gold Receiver + Grip
        addRelPart(relParts, makePart(model, 'SingularityReceiver', Vector3.new(0.44, 1.25, 0.62), PAL.Obsidian, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.16), CFrame.new(0, 0.22, 0.08))
        -- Split Upper & Lower Magnetic Accelerator Rails (White-Gold + Crimson + Obsidian)
        for _, sgn in ipairs({ -1, 1 }) do
            addRelPart(relParts, makePart(model, 'MagneticRailOuter_' .. sgn, Vector3.new(0.32, 2.85, 0.20), PAL.Ivory, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.18), CFrame.new(0, 1.95, sgn * 0.32))
            addRelPart(relParts, makePart(model, 'MagneticRailGold_' .. sgn, Vector3.new(0.36, 2.75, 0.08), PAL.Gold, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.22), CFrame.new(0, 1.92, sgn * 0.44))
            addRelPart(relParts, makePart(model, 'MagneticRailCrimson_' .. sgn, Vector3.new(0.18, 2.65, 0.08), PAL.Crimson, Enum.PartType.Block, 0.04, 'Part', Enum.Material.Neon, 0), CFrame.new(0, 1.92, sgn * 0.20))
        end
        -- 4 Forward-Pointing Energy Chevrons (>>>) along the rails
        for c = 1, 4 do
            addRelPart(relParts, makePart(model, 'RailChevron_' .. c, Vector3.new(0.38, 0.18, 0.46), c % 2 == 0 and PAL.Gold or PAL.Crimson, Enum.PartType.Block, 0.06, 'Part', Enum.Material.Neon, 0), CFrame.new(0, 0.85 + c * 0.52, 0), 'PulseGlow', c * 0.6)
        end
        -- Suspended Black-Hole Singularity Core + 2 Counter-Rotating Accretion Rings in the open rail gap!
        local bh = addRelPart(relParts, makePart(model, 'RailSingularityCore', Vector3.new(0.42, 0.42, 0.42), PAL.Obsidian, Enum.PartType.Ball, 0.02, 'Part', Enum.Material.SmoothPlastic, 0), CFrame.new(0, 2.05, 0), 'BobY', 0)
        local ringA = addRelPart(relParts, makePart(model, 'RailAccretionRingA', Vector3.new(0.06, 0.82, 0.82), PAL.Crimson, Enum.PartType.Cylinder, 0.12, 'Part', Enum.Material.Neon, 0), CFrame.new(0, 2.05, 0) * CFrame.Angles(0.42, 0, math.pi * 0.5), 'SpinY', 0)
        addRelPart(relParts, makePart(model, 'RailAccretionRingB', Vector3.new(0.06, 0.68, 0.68), PAL.Gold, Enum.PartType.Cylinder, 0.14, 'Part', Enum.Material.Neon, 0), CFrame.new(0, 2.05, 0) * CFrame.Angles(-0.42, 0, 0), 'SpinZ', 1.2)
        addSafePointLight(ringA, PAL.Crimson, 1.15, 10)
        addAmbientMotes(bh, 'SingularityRailSparks', PAL.Crimson, PAL.Gold, 11, 0.15, NumberRange.new(0.8, 2.2), Vector3.new(0, 1.8, 0), lowFX)

    elseif id == 'kabucha_wind' then
        boxSpanY = 4.2
        -- Walnut & Gold Slingshot Handle + Y-Fork Arms + 3 Wind Wings
        addRelPart(relParts, makePart(model, 'KabuchaShaft', Vector3.new(1.85, 0.18, 0.18), PAL.Walnut, Enum.PartType.Cylinder, 0, 'Part', Enum.Material.SmoothPlastic, 0.04), CFrame.new(0, 0.15, 0) * CFrame.Angles(0, 0, math.pi * 0.5))
        for _, sgn in ipairs({ -1, 1 }) do
            addRelPart(relParts, makePart(model, 'KabuchaForkArm_' .. sgn, Vector3.new(0.18, 1.15, 0.22), PAL.Gold, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.18), CFrame.new(0, 1.38, sgn * 0.42) * CFrame.Angles(sgn * 0.36, 0, 0))
            addRelPart(relParts, makePart(model, 'KabuchaWindWing_' .. sgn, Vector3.new(0.10, 0.68, 0.34), PAL.Emerald, Enum.PartType.Block, 0.04, 'WedgePart', Enum.Material.Neon, 0), CFrame.new(0, 1.45, sgn * 0.76) * CFrame.Angles(sgn * 0.48, 0, 0))
        end
        -- Suspended Tempest Wind Orb + 2 Spinning Armillary Rings between the Y-forks!
        local windOrb = addRelPart(relParts, makePart(model, 'TempestWindOrb', Vector3.new(0.46, 0.46, 0.46), PAL.Cyan, Enum.PartType.Ball, 0.08, 'Part', Enum.Material.Neon, 0), CFrame.new(0, 1.68, 0), 'BobY', 0)
        addRelPart(relParts, makePart(model, 'TempestArmillary1', Vector3.new(0.06, 0.84, 0.84), PAL.Gold, Enum.PartType.Cylinder, 0.14, 'Part', Enum.Material.Metal, 0.20), CFrame.new(0, 1.68, 0) * CFrame.Angles(0.45, 0, math.pi * 0.5), 'SpinY', 0)
        addRelPart(relParts, makePart(model, 'TempestArmillary2', Vector3.new(0.06, 0.72, 0.72), PAL.Emerald, Enum.PartType.Cylinder, 0.16, 'Part', Enum.Material.Neon, 0), CFrame.new(0, 1.68, 0) * CFrame.Angles(-0.45, 0, 0), 'SpinZ', 1.1)
        addSafePointLight(windOrb, PAL.Emerald, 1.0, 9)
        addAmbientMotes(windOrb, 'KabuchaWindMotes', PAL.Emerald, PAL.Cyan, 9, 0.14, NumberRange.new(0.8, 2.0), Vector3.new(0, 1.8, 0), lowFX)

    elseif id == 'aether_flintlock' then
        boxSpanY = 3.2
        -- Curved Walnut Duelist Stock + Baroque Gold Scroll Sideplates + Pommel Cap
        addRelPart(relParts, makePart(model, 'FlintlockWalnutStock', Vector3.new(0.22, 0.88, 0.34), PAL.Walnut, Enum.PartType.Block, 0, 'Part', Enum.Material.SmoothPlastic, 0.04), CFrame.new(0, -0.15, 0.22) * CFrame.Angles(0.42, 0, 0))
        addRelPart(relParts, makePart(model, 'FlintlockGoldScrollPlate', Vector3.new(0.26, 0.75, 0.24), PAL.Gold, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.20), CFrame.new(0, 0.42, 0.04))
        -- S-Curved Flintlock Hammer Clamping a Glowing Cyan Aether Crystal
        local hammerGem = addRelPart(relParts, makePart(model, 'FlintlockHammerCrystal', Vector3.new(0.14, 0.32, 0.22), PAL.Cyan, Enum.PartType.Block, 0.04, 'WedgePart', Enum.Material.Neon, 0), CFrame.new(0, 0.38, -0.24) * CFrame.Angles(-0.35, 0, 0), 'PulseGlow', 0)
        -- Octagonal Barrel + Glowing Cyan Crystal-Vein Inlays + Fluted Gold Muzzle Crown
        addRelPart(relParts, makePart(model, 'FlintlockOctBarrel', Vector3.new(0.22, 1.95, 0.24), PAL.Slate, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.16), CFrame.new(0, 1.18, -0.06))
        addRelPart(relParts, makePart(model, 'FlintlockCrystalVein', Vector3.new(0.24, 1.65, 0.08), PAL.Cyan, Enum.PartType.Block, 0.04, 'Part', Enum.Material.Neon, 0), CFrame.new(0, 1.22, -0.06), 'PulseGlow', 0.4)
        addRelPart(relParts, makePart(model, 'FlintlockMuzzleCrown', Vector3.new(0.24, 0.34, 0.34), PAL.Gold, Enum.PartType.Cylinder, 0, 'Part', Enum.Material.Metal, 0.20), CFrame.new(0, 2.18, -0.06) * CFrame.Angles(0, 0, math.pi * 0.5))
        addSafePointLight(hammerGem, PAL.Cyan, 0.95, 8)
        addAmbientMotes(hammerGem, 'AetherFlintlockSparks', PAL.Cyan, PAL.Gold, 7, 0.13, NumberRange.new(0.6, 1.6), Vector3.new(0, 1.4, 0), lowFX)

    else -- bizarre_rifle_cyber
        boxSpanY = 4.6
        -- White & Cobalt Cryo-Tech Chassis + Thumbhole Stock + Underslung Cryo-Capacitor
        addRelPart(relParts, makePart(model, 'CyberRifleChassis', Vector3.new(0.28, 2.85, 0.38), PAL.Ivory, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.14), CFrame.new(0, 1.15, 0.04))
        addRelPart(relParts, makePart(model, 'CyberCryoMagazine', Vector3.new(0.24, 0.68, 0.32), PAL.Cyan, Enum.PartType.Block, 0.06, 'Part', Enum.Material.Neon, 0), CFrame.new(0, 0.72, 0.32) * CFrame.Angles(0.22, 0, 0))
        -- Holographic HUD Scope with Dual Glowing Cyan Lenses
        addRelPart(relParts, makePart(model, 'CyberHoloScopeBody', Vector3.new(0.82, 0.24, 0.24), PAL.Slate, Enum.PartType.Cylinder, 0, 'Part', Enum.Material.Metal, 0.16), CFrame.new(0, 0.88, -0.28) * CFrame.Angles(0, 0, math.pi * 0.5))
        addRelPart(relParts, makePart(model, 'CyberHoloLens', Vector3.new(0.86, 0.18, 0.18), PAL.Cyan, Enum.PartType.Cylinder, 0.08, 'Part', Enum.Material.Neon, 0), CFrame.new(0, 0.88, -0.28) * CFrame.Angles(0, 0, math.pi * 0.5))
        -- 5 Sequential Pulsing Cyan Plasma Induction Coils along the Barrel!
        local lastCoil
        for c = 1, 5 do
            lastCoil = addRelPart(relParts, makePart(model, 'PlasmaInductionCoil_' .. c, Vector3.new(0.14, 0.46, 0.46), c % 2 == 0 and PAL.Violet or PAL.Cyan, Enum.PartType.Cylinder, 0.06, 'Part', Enum.Material.Neon, 0), CFrame.new(0, 0.85 + c * 0.42, 0.02) * CFrame.Angles(0, 0, math.pi * 0.5), 'SequentialPulse', c * 0.45)
        end
        if lastCoil then
            addSafePointLight(lastCoil, PAL.Cyan, 1.05, 9)
            addAmbientMotes(lastCoil, 'CyberRiflePlasmaMotes', PAL.Cyan, PAL.Violet, 9, 0.14, NumberRange.new(0.8, 2.0), Vector3.new(0, 1.8, 0), lowFX)
        end
    end

    -- Position all relative parts initially around RootPart
    for _, rp in ipairs(relParts) do
        rp.Part.CFrame = root.CFrame * rp.RelCF
    end

    local entry = {
        Model = model,
        AssetName = tostring(assetName or id),
        ItemId = id,
        IsGun = isGun,
        IsExpansionCustom = true,
        HorizontalBarrel = false,
        BoxSize = Vector3.new(1.2, boxSpanY, 1.2),
        MeshParts = relParts,
        Visible = true,
    }
    return entry
end

function M.PivotExpansionWeapon(entry, targetCF, now)
    if not entry or not entry.Model or not entry.Model.PrimaryPart then
        return
    end
    entry.Model.PrimaryPart.CFrame = targetCF
    local t = now or os.clock()
    for _, rp in ipairs(entry.MeshParts) do
        local p = rp.Part
        if p and p.Parent then
            local animCF = rp.RelCF
            local role = rp.AnimRole
            if role == 'SpinY' then
                animCF = animCF * CFrame.Angles(0, t * 3.4 + (rp.Phase or 0), 0)
            elseif role == 'SpinX' then
                animCF = animCF * CFrame.Angles(t * 2.8 + (rp.Phase or 0), 0, 0)
            elseif role == 'SpinXFast' then
                animCF = animCF * CFrame.Angles(-t * 6.5, 0, 0)
            elseif role == 'SpinZ' then
                animCF = animCF * CFrame.Angles(0, 0, t * 3.1 + (rp.Phase or 0))
            elseif role == 'BobY' then
                animCF = animCF * CFrame.new(0, math.sin(t * 3.8 + (rp.Phase or 0)) * 0.08, 0)
            elseif role == 'PulseGlow' or role == 'SequentialPulse' then
                local wave = 0.5 + 0.5 * math.sin(t * 5.2 - (rp.Phase or 0))
                if entry.Visible then
                    p.Transparency = math.clamp((rp.OrigTrans or 0.04) + (1 - wave) * 0.18, 0, 0.65)
                end
            end
            p.CFrame = targetCF * animCF
        end
    end
end

-- ============================================================================
-- 2. PASS 13 7-SLOT MODULAR 3D ARMOR SETS (SHEET 27) & 3D BOSS RELICS (SHEET 28)
-- ============================================================================
function M.BuildModularArmorSet3D(folder, data, helmTheme, chestTheme, gauntTheme, greaveTheme, flags, lowFX)
    if not folder or not data then
        return
    end
    data.AnimCoreParts = data.AnimCoreParts or {}
    data.RelicParts = data.RelicParts or {}

    -- SLOT 2 & 3 & 5 & 7: 2-Tiered Curved Pauldrons L/R, Anatomical Cuirass + Bespoke Chest Core,
    --                     360° Wrap-Around Hip Tassets (Front/Side/Back), and Pleated 3D Back Mantle + Halos
    if flags.WantChest then
        local k = chestTheme.Kind
        -- 03_Chestplate_Cuirass: Sculpted Left/Right Pectoral Plates + Abdominal Lames
        for _, side in ipairs({ -1, 1 }) do
            local pec = makePart(folder, 'Slot03_PectoralPlate_' .. side, Vector3.new(0.84, 0.58, 0.24), chestTheme.Metal, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.18)
            table.insert(data.TorsoParts, {
                Part = pec,
                Offset = CFrame.new(side * 0.46, 0.42, -0.48) * CFrame.Angles(0.08, -side * 0.16, 0),
            })
            local ribTrim = makePart(folder, 'Slot03_RibGoldTrim_' .. side, Vector3.new(0.76, 0.10, 0.22), chestTheme.Trim, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.22)
            table.insert(data.TorsoParts, {
                Part = ribTrim,
                Offset = CFrame.new(side * 0.48, 0.06, -0.49) * CFrame.Angles(0, -side * 0.14, side * 0.18),
            })
        end
        for lame = 1, 2 do
            local ab = makePart(folder, 'Slot03_AbdominalLame_' .. lame, Vector3.new(1.56 - lame * 0.12, 0.22, 0.96), chestTheme.Metal, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.16)
            table.insert(data.TorsoParts, {
                Part = ab,
                Offset = CFrame.new(0, -0.08 - lame * 0.20, -0.04),
            })
        end

        -- Bespoke Set-Specific 3D Chest Centerpiece (Aureon Sun-Star, Cryon Hex Reactor + Dorsal Jets,
        -- Noxar Void Orb, Sylvaris/Ignivar Molten Lava Veins, Nerith/Aion Clockwork Astrolabe, Veyr Diamond Core)
        if k == 'nerith' or k == 'aion' then
            local astroWheel = makePart(folder, 'Slot03_ChronoAstrolabeWheel', Vector3.new(0.10, 0.82, 0.82), PAL.Gold, Enum.PartType.Cylinder, 0, 'Part', Enum.Material.Metal, 0.22)
            local astroHand = makePart(folder, 'Slot03_ChronoClockHand', Vector3.new(0.12, 0.36, 0.08), PAL.Cyan, Enum.PartType.Block, 0.04, 'Part', Enum.Material.Neon, 0)
            table.insert(data.AnimCoreParts, { Part = astroWheel, BaseOffset = CFrame.new(0, 0.34, -0.54) * CFrame.Angles(0, math.pi * 0.5, 0), Mode = 'SpinX' })
            table.insert(data.AnimCoreParts, { Part = astroHand, BaseOffset = CFrame.new(0, 0.34, -0.56), Mode = 'SpinZ' })
        elseif k == 'veyr' then
            local veyrDiamond = makePart(folder, 'Slot03_VeyrSingularityDiamond', Vector3.new(0.36, 0.52, 0.24), PAL.Crimson, Enum.PartType.Block, 0.04, 'Part', Enum.Material.Neon, 0)
            local veyrHalo = makePart(folder, 'Slot03_VeyrChestRing', Vector3.new(0.08, 0.86, 0.86), PAL.Gold, Enum.PartType.Cylinder, 0.12, 'Part', Enum.Material.Neon, 0)
            table.insert(data.AnimCoreParts, { Part = veyrDiamond, BaseOffset = CFrame.new(0, 0.34, -0.56) * CFrame.Angles(0, 0, math.pi * 0.25), Mode = 'Bob' })
            table.insert(data.AnimCoreParts, { Part = veyrHalo, BaseOffset = CFrame.new(0, 0.34, -0.54) * CFrame.Angles(0, math.pi * 0.5, 0), Mode = 'SpinX' })
            -- Floating Genesis Double Halo + 4 Orbiting Ruby Singularity Crystals behind shoulders!
            local backHalo = makePart(folder, 'Slot07_VeyrGenesisBackHalo', Vector3.new(0.10, 2.35, 2.35), PAL.Gold, Enum.PartType.Cylinder, 0.14, 'Part', Enum.Material.Neon, 0)
            table.insert(data.HaloParts, { Part = backHalo, BaseOffset = CFrame.new(0, 0.55, 0.62) * CFrame.Angles(0, math.pi * 0.5, 0), SpinAxis = 'Bob', Phase = 0 })
            for c = 1, 4 do
                local ang = (c - 0.5) * (math.pi * 0.5)
                local ruby = makePart(folder, 'Slot07_VeyrOrbitRuby_' .. c, Vector3.new(0.18, 0.38, 0.18), PAL.Crimson, Enum.PartType.Block, 0.04, 'WedgePart', Enum.Material.Neon, 0)
                table.insert(data.HaloParts, {
                    Part = ruby,
                    BaseOffset = CFrame.new(math.cos(ang) * 1.35, 0.55 + math.sin(ang) * 0.85, 0.58) * CFrame.Angles(0, 0, -ang),
                    SpinAxis = 'Bob',
                    Phase = c * 1.1,
                })
            end
        elseif k == 'ignivar' or k == 'sylvaris' then
            for v = -1, 1, 2 do
                local vein = makePart(folder, 'Slot03_MoltenLavaVein_' .. v, Vector3.new(0.58, 0.10, 0.16), PAL.Magma, Enum.PartType.Block, 0.04, 'Part', Enum.Material.Neon, 0)
                table.insert(data.TorsoParts, {
                    Part = vein,
                    Offset = CFrame.new(v * 0.42, 0.24, -0.53) * CFrame.Angles(0, 0, -v * 0.38),
                })
            end
        elseif k == 'cryon' then
            -- 4 Dorsal Cyber-Reactor Jet Thruster Fins on Back
            for _, sgn in ipairs({ -1, 1 }) do
                for tier = 1, 2 do
                    local fin = makePart(folder, 'Slot07_CryonJetFin_' .. sgn .. '_' .. tier, Vector3.new(0.14, 0.92 - tier * 0.16, 0.42), tier == 1 and chestTheme.Metal or PAL.Cyan, Enum.PartType.Block, 0.04, 'WedgePart', tier == 1 and Enum.Material.Metal or Enum.Material.Neon, 0.14)
                    table.insert(data.TorsoParts, {
                        Part = fin,
                        Offset = CFrame.new(sgn * (0.58 + tier * 0.24), 0.52 - tier * 0.18, 0.58) * CFrame.Angles(0.28, sgn * 0.35, -sgn * (0.42 + tier * 0.15)),
                    })
                end
            end
        end

        -- 02_Pauldrons_LR: 2-Tiered Curved 3D Shoulder Domes + Thick Sculpted Wing Plates
        for _, side in ipairs({ -1, 1 }) do
            local lowerLame = makePart(folder, 'Slot02_PauldronLowerLame_' .. side, Vector3.new(0.78, 0.28, 0.92), chestTheme.Metal, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.16)
            local goldRim = makePart(folder, 'Slot02_PauldronGoldRim_' .. side, Vector3.new(0.88, 0.12, 1.02), chestTheme.Trim, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.22)
            local outerWing = makePart(folder, 'Slot02_PauldronSculptWing_' .. side, Vector3.new(0.22, 0.48, 0.88), chestTheme.Trim, Enum.PartType.Block, 0, 'WedgePart', Enum.Material.Metal, 0.18)
            table.insert(data.TorsoParts, {
                Part = lowerLame,
                Offset = CFrame.new(side * 1.24, 0.64, 0.02) * CFrame.Angles(0, 0, -side * 0.34),
            })
            table.insert(data.TorsoParts, {
                Part = goldRim,
                Offset = CFrame.new(side * 1.20, 0.76, 0.02) * CFrame.Angles(0, 0, -side * 0.26),
            })
            table.insert(data.TorsoParts, {
                Part = outerWing,
                Offset = CFrame.new(side * 1.46, 0.98, 0.06) * CFrame.Angles(0, side > 0 and math.pi * 0.5 or -math.pi * 0.5, -side * 0.38),
            })
        end

        -- 05_Belt_And_Tassets: Centerpiece Buckle + 360° Wrap-Around Hip Tassets (Front, Side, Back)
        local buckle = makePart(folder, 'Slot05_WarBeltBuckle', Vector3.new(0.42, 0.34, 0.22), chestTheme.Trim, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.22)
        local buckleGem = makePart(folder, 'Slot05_WarBeltGem', Vector3.new(0.22, 0.22, 0.24), chestTheme.Accent, Enum.PartType.Ball, 0.04, 'Part', Enum.Material.Neon, 0)
        table.insert(data.TorsoParts, { Part = buckle, Offset = CFrame.new(0, -0.46, -0.54) })
        table.insert(data.TorsoParts, { Part = buckleGem, Offset = CFrame.new(0, -0.46, -0.56) })

        for _, side in ipairs({ -1, 1 }) do
            -- Front Tasset Plates
            local frontTasset = makePart(folder, 'Slot05_FrontTasset_' .. side, Vector3.new(0.56, 0.68, 0.14), chestTheme.Metal, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.16)
            table.insert(data.TorsoParts, {
                Part = frontTasset,
                Offset = CFrame.new(side * 0.52, -0.82, -0.48) * CFrame.Angles(-0.14, 0, -side * 0.10),
            })
            -- 360° Side Hip Tasset Plates (Upper + Lower Lame)
            local sideTasset1 = makePart(folder, 'Slot05_SideHipTasset1_' .. side, Vector3.new(0.16, 0.64, 0.86), chestTheme.Metal, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.16)
            local sideTasset2 = makePart(folder, 'Slot05_SideHipTasset2_' .. side, Vector3.new(0.14, 0.48, 0.76), chestTheme.Trim, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.20)
            table.insert(data.TorsoParts, {
                Part = sideTasset1,
                Offset = CFrame.new(side * 0.98, -0.78, 0) * CFrame.Angles(0, 0, -side * 0.18),
            })
            table.insert(data.TorsoParts, {
                Part = sideTasset2,
                Offset = CFrame.new(side * 1.04, -1.12, 0) * CFrame.Angles(0, 0, -side * 0.24),
            })
        end
        -- Back Waist Guard Plate
        local backTasset = makePart(folder, 'Slot05_BackWaistTasset', Vector3.new(1.38, 0.62, 0.14), chestTheme.Metal, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.16)
        table.insert(data.TorsoParts, {
            Part = backTasset,
            Offset = CFrame.new(0, -0.82, 0.52) * CFrame.Angles(0.16, 0, 0),
        })

        -- Ambient Armor Elemental Mote Emitter on Torso
        local auraAnchor = makePart(folder, 'ArmorElementalAuraNode', Vector3.new(0.2, 0.2, 0.2), chestTheme.Accent, Enum.PartType.Ball, 1)
        addAmbientMotes(auraAnchor, 'ArmorSetAmbientMotes', chestTheme.Accent, chestTheme.Trim, 8, 0.15, NumberRange.new(0.6, 1.8), Vector3.new(0, 1.5, 0), lowFX)
        table.insert(data.TorsoParts, { Part = auraAnchor, Offset = CFrame.new(0, 0.25, 0) })
    end

    -- SLOT 4 (`04_Gauntlets_LR`): Elbow Guard + Hand Plate + 4 Articulated Armored Finger Claws per Hand!
    if flags.WantGauntlets then
        for _, side in ipairs({ -1, 1 }) do
            local handPlate = makePart(folder, 'Slot04_HandGuardPlate_' .. side, Vector3.new(0.48, 0.34, 0.52), gauntTheme.Trim, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.20)
            table.insert(data.ArmParts, {
                Part = handPlate,
                Side = side,
                Offset = CFrame.new(0, -0.22, 0),
            })
            for f = 1, 4 do
                local zOff = -0.18 + (f - 1) * 0.12
                local claw = makePart(folder, 'Slot04_FingerClaw_' .. side .. '_' .. f, Vector3.new(0.10, 0.26, 0.09), f % 2 == 0 and gauntTheme.Accent or gauntTheme.Trim, Enum.PartType.Block, 0.02, 'WedgePart', Enum.Material.Neon, 0)
                table.insert(data.ArmParts, {
                    Part = claw,
                    Side = side,
                    Offset = CFrame.new(side * 0.22, -0.44, zOff) * CFrame.Angles(0, 0, -side * 0.18),
                })
            end
        end
    end

    -- SLOT 6 (`06_Greaves_And_Boots_LR`): Winged Knee Cop (Poleyn) + Outer Side Greave Plate + Armored Sabaton Boot!
    if flags.WantGreaves then
        for _, side in ipairs({ -1, 1 }) do
            local kneeCop = makePart(folder, 'Slot06_KneePoleyn_' .. side, Vector3.new(0.54, 0.36, 0.32), greaveTheme.Trim, Enum.PartType.Block, 0, 'WedgePart', Enum.Material.Metal, 0.20)
            local sideGreave = makePart(folder, 'Slot06_GreaveSidePlate_' .. side, Vector3.new(0.16, 0.84, 0.56), greaveTheme.Metal, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.16)
            local sabatonBoot = makePart(folder, 'Slot06_SabatonBoot_' .. side, Vector3.new(0.62, 0.32, 0.88), greaveTheme.Metal, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.18)
            local sabatonToe = makePart(folder, 'Slot06_SabatonToeCap_' .. side, Vector3.new(0.58, 0.26, 0.38), greaveTheme.Trim, Enum.PartType.Block, 0, 'WedgePart', Enum.Material.Metal, 0.22)
            table.insert(data.LegParts, {
                Part = kneeCop,
                Side = side,
                Offset = CFrame.new(0, 0.48, -0.28),
            })
            table.insert(data.LegParts, {
                Part = sideGreave,
                Side = side,
                Offset = CFrame.new(side * 0.32, 0.04, 0),
            })
            table.insert(data.LegParts, {
                Part = sabatonBoot,
                Side = side,
                Offset = CFrame.new(0, -0.46, -0.12),
            })
            table.insert(data.LegParts, {
                Part = sabatonToe,
                Side = side,
                Offset = CFrame.new(0, -0.48, -0.58),
            })
        end
    end

    -- SLOT 8 (`08_BossRelics_3D`): Floating 3D Boss Relic / Ring / Artifact from Sheet 28
    if flags.RelicToken and flags.RelicToken ~= '' then
        local rTheme = resolveRelicColors(flags.RelicToken)
        local relicCore = makePart(folder, 'Slot08_BossRelicCore', Vector3.new(0.36, 0.36, 0.36), rTheme.Primary, Enum.PartType.Ball, 0.04, 'Part', Enum.Material.Neon, 0)
        local relicRing = makePart(folder, 'Slot08_BossRelicHalo', Vector3.new(0.08, 0.72, 0.72), rTheme.Secondary, Enum.PartType.Cylinder, 0.12, 'Part', Enum.Material.Metal, 0.22)
        addAmbientMotes(relicCore, 'BossRelicMotes', rTheme.Primary, rTheme.Secondary, 6, 0.12, NumberRange.new(0.5, 1.4), Vector3.new(0, 1.2, 0), lowFX)
        table.insert(data.RelicParts, {
            Core = relicCore,
            Ring = relicRing,
            BaseOffset = CFrame.new(-1.45, 1.35, -0.25),
        })
    end
end

function resolveRelicColors(tokenStr)
    local t = string.lower(tostring(tokenStr or ''))
    if t:find('veyr') or t:find('genesis') then
        return { Primary = PAL.Crimson, Secondary = PAL.Gold }
    elseif t:find('ignivar') or t:find('molten') then
        return { Primary = PAL.Magma, Secondary = PAL.Gold }
    elseif t:find('sylvaris') or t:find('life') then
        return { Primary = PAL.Emerald, Secondary = PAL.Gold }
    elseif t:find('nerith') or t:find('leviathan') then
        return { Primary = PAL.Cyan, Secondary = PAL.Gold }
    elseif t:find('noxar') or t:find('eclipse') then
        return { Primary = PAL.Violet, Secondary = PAL.Crimson }
    elseif t:find('cryon') or t:find('frost') then
        return { Primary = PAL.Cyan, Secondary = PAL.Ice }
    end
    return { Primary = PAL.Gold, Secondary = PAL.Solar }
end

function M.StepModularArmorSet3D(fx, torsoCF, scaleRatio, now)
    if not fx then
        return
    end
    if fx.AnimCoreParts then
        for _, item in ipairs(fx.AnimCoreParts) do
            if item.Part and item.Part.Parent then
                local off = item.BaseOffset
                if item.Mode == 'SpinX' then
                    item.Part.CFrame = torsoCF * CFrame.new(off.Position * scaleRatio) * off.Rotation * CFrame.Angles(now * 2.4, 0, 0)
                elseif item.Mode == 'SpinZ' then
                    item.Part.CFrame = torsoCF * CFrame.new(off.Position * scaleRatio) * off.Rotation * CFrame.Angles(0, 0, -now * 4.8)
                else
                    local bob = math.sin(now * 3.4) * 0.05 * scaleRatio
                    item.Part.CFrame = torsoCF * CFrame.new(off.Position * scaleRatio + Vector3.new(0, bob, 0)) * off.Rotation
                end
            end
        end
    end
    if fx.RelicParts then
        for _, rel in ipairs(fx.RelicParts) do
            if rel.Core and rel.Core.Parent then
                local bob = math.sin(now * 2.8) * 0.14 * scaleRatio
                local orbitX = math.cos(now * 1.6) * 0.12 * scaleRatio
                local centerCF = torsoCF * CFrame.new(rel.BaseOffset.Position * scaleRatio + Vector3.new(orbitX, bob, 0))
                rel.Core.CFrame = centerCF * CFrame.Angles(now * 1.8, now * 2.2, 0)
                if rel.Ring and rel.Ring.Parent then
                    rel.Ring.CFrame = centerCF * CFrame.Angles(now * 2.6, math.pi * 0.5, now * 1.9)
                end
            end
        end
    end
end

-- ============================================================================
-- 3. BESPOKE EXPANSION WEAPON, GUN & BOW COMBAT VFX ("VFX THẬT ĐẸP")
-- ============================================================================
local EXPANSION_WEAPON_VFX_PROFILES = {
    sunshard_halberd = { Primary = PAL.Gold, Secondary = PAL.Solar, Accent = PAL.HotWhite, Element = 'Light', Style = 'SolarHalberd' },
    cyber_katana_mk2 = { Primary = PAL.Cyan, Secondary = PAL.Violet, Accent = PAL.HotWhite, Element = 'Thunder', Style = 'QuantumKatana' },
    sylvaris_thornblade = { Primary = PAL.Emerald, Secondary = PAL.Jade, Accent = PAL.Gold, Element = 'Wind', Style = 'VerdantSaber' },
    ignivar_magma_breaker = { Primary = PAL.Magma, Secondary = PAL.Solar, Accent = PAL.Obsidian, Element = 'Magma', Style = 'MagmaBreaker' },
    nerith_abyssal_trident = { Primary = PAL.Cyan, Secondary = PAL.Ice, Accent = PAL.Gold, Element = 'Ice', Style = 'AbyssalTrident' },
    aion_chrono_scythe = { Primary = PAL.Chrono, Secondary = PAL.Gold, Accent = PAL.Cyan, Element = 'Gravity', Style = 'ChronoScythe' },
    architect_severance = { Primary = PAL.Crimson, Secondary = PAL.Gold, Accent = PAL.Obsidian, Element = 'Gravity', Style = 'ArchitectSeverance' },
    eternal_frost_staff = { Primary = PAL.Ice, Secondary = PAL.Cyan, Accent = PAL.Gold, Element = 'Ice', Style = 'EternalFrostStaff' },
}

local EXPANSION_GUN_VFX_PROFILES = {
    sylvaris_thornbow = { Primary = PAL.Emerald, Secondary = PAL.Jade, Accent = PAL.Gold, Element = 'Wind', Style = 'SpiritLongbow' },
    ignivar_hellcannon = { Primary = PAL.Magma, Secondary = PAL.Solar, Accent = PAL.Obsidian, Element = 'Magma', Style = 'HellfireCannon' },
    aion_chrono_pistols = { Primary = PAL.Chrono, Secondary = PAL.Gold, Accent = PAL.Cyan, Element = 'Gravity', Style = 'DualChronoPistols' },
    veyr_singularity_cannon = { Primary = PAL.Crimson, Secondary = PAL.Gold, Accent = PAL.Obsidian, Element = 'Gravity', Style = 'SingularityCannon' },
    kabucha_wind = { Primary = PAL.Emerald, Secondary = PAL.Cyan, Accent = PAL.Gold, Element = 'Wind', Style = 'TempestKabucha' },
    aether_flintlock = { Primary = PAL.Cyan, Secondary = PAL.Gold, Accent = PAL.HotWhite, Element = 'Light', Style = 'AetherFlintlock' },
    bizarre_rifle_cyber = { Primary = PAL.Cyan, Secondary = PAL.Violet, Accent = PAL.Ice, Element = 'Ice', Style = 'CyberPulseRifle' },
}

local function animateOver(duration, stepFn, doneFn)
    local startT = os.clock()
    local conn
    conn = RunService.RenderStepped:Connect(function()
        local a = math.clamp((os.clock() - startT) / math.max(0.01, duration), 0, 1)
        stepFn(a)
        if a >= 1 then
            if conn then
                conn:Disconnect()
            end
            if doneFn then
                doneFn()
            end
        end
    end)
end

local function resolveEquippedId(actorChar, attrName)
    if actorChar then
        local v = tostring(actorChar:GetAttribute(attrName) or '')
        if v ~= '' then
            return string.lower(v)
        end
    end
    local lp = Players.LocalPlayer
    if lp and (not actorChar or actorChar == lp.Character) then
        local v = tostring(lp:GetAttribute(attrName) or '')
        if v ~= '' then
            return string.lower(v)
        end
    end
    return ''
end

function M.GetSwordVFXProfile(actorChar, rawSwordId)
    local sid = string.lower(tostring(rawSwordId or ''))
    if sid == '' then
        sid = resolveEquippedId(actorChar, 'EquippedSword')
    end
    return EXPANSION_WEAPON_VFX_PROFILES[sid], sid
end

function M.GetGunVFXProfile(actorChar, rawGunId)
    local gid = string.lower(tostring(rawGunId or ''))
    if gid == '' then
        gid = resolveEquippedId(actorChar, 'EquippedGun')
    end
    return EXPANSION_GUN_VFX_PROFILES[gid], gid
end

function M.SpawnExpansionM1Extra(Lib, folder, actorChar, startPos, dst, lookDir, combo, isFinisher, sc)
    local prof, sid = M.GetSwordVFXProfile(actorChar, nil)
    if not prof then
        return nil
    end

    local mid = startPos:Lerp(dst, 0.55)
    if prof.Style == 'ChronoScythe' then
        -- Spinning Golden Clockwork Astrolabe Slash Ring + Time Echo Afterimage Slash!
        local clockRing = Lib.MakePart('ChronoM1ClockRing', Enum.PartType.Cylinder, Vector3.new(0.10, 4.2 * sc, 4.2 * sc), CFrame.new(mid) * CFrame.Angles(0, 0, math.pi * 0.5), PAL.Gold, 0.14, Enum.Material.ForceField, folder)
        TweenService:Create(clockRing, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = Vector3.new(0.05, 8.8 * sc, 8.8 * sc),
            CFrame = clockRing.CFrame * CFrame.Angles(1.8, 0, 0),
            Transparency = 1,
        }):Play()
        Debris:AddItem(clockRing, 0.32)
    elseif prof.Style == 'ArchitectSeverance' then
        -- Reality-Rift Black-Hole Micro-Implosion along the slash arc
        local voidOrb = Lib.MakePart('SeveranceM1VoidCore', Enum.PartType.Ball, Vector3.new(1.8, 1.8, 1.8) * sc, CFrame.new(dst), PAL.Obsidian, 0.08, Enum.Material.SmoothPlastic, folder)
        local acc = Lib.MakePart('SeveranceM1Accretion', Enum.PartType.Cylinder, Vector3.new(0.10, 3.2 * sc, 3.2 * sc), CFrame.new(dst) * CFrame.Angles(0.45, 0, math.pi * 0.5), PAL.Crimson, 0.12, Enum.Material.ForceField, folder)
        TweenService:Create(voidOrb, TweenInfo.new(0.24), { Size = Vector3.new(0.15, 0.15, 0.15), Transparency = 1 }):Play()
        TweenService:Create(acc, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = Vector3.new(0.04, 7.6 * sc, 7.6 * sc), Transparency = 1 }):Play()
        Debris:AddItem(voidOrb, 0.28)
        Debris:AddItem(acc, 0.32)
        if isFinisher then
            Lib.SpawnJaggedLightning(startPos + Vector3.new(0, 0.6, 0), dst, 5, 1.1 * sc, 0.24 * sc, PAL.Gold, PAL.Crimson, 0.28, folder)
        end
    elseif prof.Style == 'MagmaBreaker' and isFinisher then
        local gPos = Lib.FindGround(dst)
        Lib.SpawnShatterCrater(gPos, PAL.Magma, PAL.Gold, PAL.Obsidian, 6.5 * sc, 6, 0.42, folder)
    elseif prof.Style == 'QuantumKatana' then
        Lib.SpawnJaggedLightning(startPos + lookDir * 1.2, dst, 5, 0.85 * sc, 0.20 * sc, PAL.HotWhite, PAL.Cyan, 0.22, folder)
    end
    return prof, sid
end

function M.SpawnExpansionGunShot(Lib, Overhaul, folder, actorChar, startPos, dst, lookDir, sc, isLocal, fx)
    local prof, gid = M.GetGunVFXProfile(actorChar, type(fx) == 'table' and (fx.GunId or fx.WeaponId or fx.activeId) or nil)
    if not prof then
        return false
    end

    local muzzlePos = startPos + lookDir * 2.0 + Vector3.new(0, 0.5, 0)
    local aimCF = Lib.SafeLookAt(muzzlePos, dst, lookDir)
    local dist = math.max(1, (dst - muzzlePos).Magnitude)
    local mid = (muzzlePos + dst) * 0.5

    if prof.Style == 'SpiritLongbow' then
        -- Sylvaris Spirit Longbow: Emerald Wind-Tunnel Sonic Rings + Giant Spirit Arrow + Verdant Root Burst
        Lib.Emit('Combat', 'Gun_RailBurst', aimCF, sc, PAL.Emerald, PAL.Gold)
        for r = 1, 3 do
            local ringPos = muzzlePos:Lerp(dst, (r - 1) * 0.32)
            Lib.SpawnShockRing(ringPos, Lib.SafeLookAt(ringPos, dst, lookDir) * CFrame.Angles(math.pi * 0.5, 0, 0), (r % 2 == 1) and PAL.Emerald or PAL.Jade, 1.0 * sc, (4.8 + r * 1.4) * sc, 0.18, 0.28, Enum.Material.ForceField, folder)
        end
        local arrow = Lib.MakePart('SylvarisSpiritArrowProj', Enum.PartType.Wedge, Vector3.new(0.45 * sc, 0.45 * sc, 3.8 * sc), aimCF, PAL.Emerald, 0.06, Enum.Material.ForceField, folder)
        Lib.AttachRibbonTrail(arrow, PAL.HotWhite, PAL.Emerald, PAL.Gold, 1.05 * sc, 0.24)
        animateOver(0.16, function(a)
            if arrow.Parent then
                arrow.CFrame = Lib.SafeLookAt(muzzlePos:Lerp(dst, a), dst + lookDir, lookDir) * CFrame.Angles(0, 0, a * 9.4)
            end
        end, function()
            Lib.SpawnShockRing(dst, nil, PAL.Emerald, 1.4 * sc, 9.2 * sc, 0.22, 0.34, Enum.Material.ForceField, folder)
            Lib.SpawnShockRing(dst + Vector3.new(0, 0.4, 0), nil, PAL.Gold, 1.0 * sc, 6.4 * sc, 0.16, 0.28, Enum.Material.ForceField, folder)
        end)
        Debris:AddItem(arrow, 0.42)

    elseif prof.Style == 'HellfireCannon' then
        -- Ignivar Hellfire Cannon: Dragon-Maw Fireball Mortar + Magma Crater Explosion
        Lib.Emit('Combat', 'Gun_RailBurst', aimCF, sc * 1.25, PAL.Magma, PAL.Gold)
        Lib.SpawnShockRing(muzzlePos, aimCF * CFrame.Angles(math.pi * 0.5, 0, 0), PAL.Magma, 1.2 * sc, 6.8 * sc, 0.22, 0.26, Enum.Material.ForceField, folder)
        local shell = Lib.MakePart('IgnivarHellfireShell', Enum.PartType.Ball, Vector3.new(1.35, 1.35, 1.35) * sc, CFrame.new(muzzlePos), PAL.Magma, 0.06, Enum.Material.ForceField, folder)
        local core = Lib.MakePart('IgnivarShellCore', Enum.PartType.Ball, Vector3.new(0.82, 0.82, 0.82) * sc, CFrame.new(muzzlePos), PAL.Obsidian, 0.08, Enum.Material.SmoothPlastic, folder)
        Lib.AttachRibbonTrail(shell, PAL.Gold, PAL.Magma, PAL.Obsidian, 1.35 * sc, 0.28)
        animateOver(0.18, function(a)
            local arcLift = math.sin(a * math.pi) * math.min(3.2, dist * 0.12)
            local p = muzzlePos:Lerp(dst, a) + Vector3.new(0, arcLift, 0)
            if shell.Parent then shell.CFrame = CFrame.new(p) end
            if core.Parent then core.CFrame = CFrame.new(p) end
        end, function()
            Overhaul.SpawnStage3Aftermath(dst, { Primary = PAL.Magma, Secondary = PAL.Gold, Accent = PAL.Obsidian, Element = 'Magma' }, 9, sc * 0.95, false, isLocal)
        end)
        Debris:AddItem(shell, 0.46)
        Debris:AddItem(core, 0.22)

    elseif prof.Style == 'DualChronoPistols' then
        -- Aion Dual Chrono Pistols: Dual Left+Right Astrolabe Muzzle Rings + Time-Echo Twin Phase Bolts!
        local rightVec = aimCF.RightVector
        for idx, side in ipairs({ 1, -1 }) do
            task.delay((idx - 1) * 0.055, function()
                local mPos = muzzlePos + rightVec * (side * 0.85)
                local mCF = Lib.SafeLookAt(mPos, dst, lookDir)
                local col = (side > 0) and PAL.Chrono or PAL.Cyan
                Lib.Emit('Combat', 'Gun_RailBurst', mCF, sc * 0.95, col, PAL.Gold)
                local clockMuz = Lib.MakePart('ChronoPistolMuzzleClock_' .. side, Enum.PartType.Cylinder, Vector3.new(0.08, 2.2 * sc, 2.2 * sc), mCF * CFrame.Angles(0, math.pi * 0.5, 0), PAL.Gold, 0.12, Enum.Material.ForceField, folder)
                TweenService:Create(clockMuz, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    Size = Vector3.new(0.04, 5.2 * sc, 5.2 * sc),
                    Transparency = 1,
                }):Play()
                Debris:AddItem(clockMuz, 0.28)

                local beam = Lib.MakePart('ChronoPhaseBeam_' .. side, Enum.PartType.Cylinder, Vector3.new(dist, 0.36 * sc, 0.36 * sc), Lib.SafeLookAt((mPos + dst) * 0.5, dst, lookDir) * CFrame.Angles(0, math.pi * 0.5, 0), col, 0.08, Enum.Material.ForceField, folder)
                TweenService:Create(beam, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                    Size = Vector3.new(dist, 1.15 * sc, 1.15 * sc),
                    Transparency = 1,
                }):Play()
                Debris:AddItem(beam, 0.26)

                if idx == 2 then
                    Lib.SpawnShockRing(dst, nil, PAL.Gold, 1.2 * sc, 8.8 * sc, 0.20, 0.30, Enum.Material.ForceField, folder)
                    Lib.SpawnShockRing(dst, CFrame.new(dst) * CFrame.Angles(0.65, 0.4, 0), PAL.Chrono, 1.0 * sc, 6.8 * sc, 0.16, 0.26, Enum.Material.ForceField, folder)
                end
            end)
        end

    elseif prof.Style == 'SingularityCannon' then
        -- Veyr Singularity Rail-Cannon: Crimson-Gold-Obsidian Hyper Rail-Beam + Black-Hole Implosion Sphere!
        Lib.Emit('Combat', 'Gun_RailBurst', aimCF, sc * 1.3, PAL.Crimson, PAL.Gold)
        local beamCF = Lib.SafeLookAt(mid, dst, lookDir) * CFrame.Angles(0, math.pi * 0.5, 0)
        local outer = Lib.MakePart('VeyrSingularityRailOuter', Enum.PartType.Cylinder, Vector3.new(dist, 0.85 * sc, 0.85 * sc), beamCF, PAL.Crimson, 0.10, Enum.Material.ForceField, folder)
        local darkCore = Lib.MakePart('VeyrSingularityRailVoid', Enum.PartType.Cylinder, Vector3.new(dist, 0.38 * sc, 0.38 * sc), beamCF, PAL.Obsidian, 0.06, Enum.Material.SmoothPlastic, folder)
        TweenService:Create(outer, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = Vector3.new(dist, 2.4 * sc, 2.4 * sc), Transparency = 1 }):Play()
        TweenService:Create(darkCore, TweenInfo.new(0.22), { Size = Vector3.new(dist, 0.05, 0.05), Transparency = 1 }):Play()
        Debris:AddItem(outer, 0.32)
        Debris:AddItem(darkCore, 0.26)
        Lib.SpawnJaggedLightning(muzzlePos, dst, 6, 0.95 * sc, 0.22 * sc, PAL.Gold, PAL.Crimson, 0.28, folder)

        -- Gravity-Well Black Hole at impact
        local bh = Lib.MakePart('VeyrShotBlackHole', Enum.PartType.Ball, Vector3.new(2.6, 2.6, 2.6) * sc, CFrame.new(dst), PAL.Obsidian, 0.06, Enum.Material.SmoothPlastic, folder)
        local acc = Lib.MakePart('VeyrShotAccretion', Enum.PartType.Cylinder, Vector3.new(0.14, 2.2 * sc, 2.2 * sc), CFrame.new(dst) * CFrame.Angles(0.38, 0, math.pi * 0.5), PAL.Gold, 0.10, Enum.Material.ForceField, folder)
        TweenService:Create(bh, TweenInfo.new(0.30, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Size = Vector3.new(0.2, 0.2, 0.2), Transparency = 1 }):Play()
        TweenService:Create(acc, TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = Vector3.new(0.05, 10.4 * sc, 10.4 * sc), Transparency = 1 }):Play()
        Debris:AddItem(bh, 0.34)
        Debris:AddItem(acc, 0.36)

    else
        -- Kabucha Wind / Aether Flintlock / Cyber Pulse Rifle: Bespoke Multi-Ring Elemental Rail Tracer
        Lib.Emit('Combat', 'Gun_RailBurst', aimCF, sc, prof.Primary, prof.Secondary)
        local beamCF = Lib.SafeLookAt(mid, dst, lookDir) * CFrame.Angles(0, math.pi * 0.5, 0)
        local rail = Lib.MakePart('ExpansionGunTracer', Enum.PartType.Cylinder, Vector3.new(dist, 0.52 * sc, 0.52 * sc), beamCF, prof.Primary, 0.08, Enum.Material.ForceField, folder)
        local core = Lib.MakePart('ExpansionGunCore', Enum.PartType.Cylinder, Vector3.new(dist, 0.22 * sc, 0.22 * sc), beamCF, prof.Secondary, 0.04, Enum.Material.SmoothPlastic, folder)
        TweenService:Create(rail, TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = Vector3.new(dist, 1.65 * sc, 1.65 * sc), Transparency = 1 }):Play()
        TweenService:Create(core, TweenInfo.new(0.18), { Size = Vector3.new(dist, 0.04, 0.04), Transparency = 1 }):Play()
        Debris:AddItem(rail, 0.28)
        Debris:AddItem(core, 0.22)
        for i = 1, 3 do
            local p = muzzlePos:Lerp(dst, i / 3)
            Lib.SpawnShockRing(p, Lib.SafeLookAt(p, dst, lookDir) * CFrame.Angles(math.pi * 0.5, 0, 0), (i % 2 == 0) and prof.Secondary or prof.Primary, 0.9 * sc, 5.8 * sc, 0.18, 0.26, Enum.Material.ForceField, folder)
        end
    end

    if isLocal then
        Lib.EmitCameraTrauma(0.24, 1.6, lookDir)
    end
    return true
end

function M.SpawnExpansionSkillVFX(Lib, Overhaul, spawnSlashFn, folder, act, kind, moveKey, actorChar, startPos, dst, lookDir, sc, isAwakened, isLocal, fx)
    local activeSlot = tonumber((type(fx) == 'table' and (fx.Slot or fx.slot)) or (actorChar and actorChar:GetAttribute('ActiveSlot'))) or 3
    if activeSlot == 4 or kind == 'GunShot' then
        local gProf = M.GetGunVFXProfile(actorChar, type(fx) == 'table' and (fx.GunId or fx.WeaponId or fx.activeId) or nil)
        if gProf then
            Overhaul.SpawnStage1Sigil(Lib.SafeLookAt(startPos, dst, lookDir), gProf, sc, moveKey == 'X' or isAwakened)
            M.SpawnExpansionGunShot(Lib, Overhaul, folder, actorChar, startPos, dst, lookDir, sc * (moveKey == 'X' and 1.30 or 1.12), isLocal, fx)
            task.delay(0.16, function()
                Overhaul.SpawnStage3Aftermath(dst, gProf, moveKey == 'X' and 15 or 11, sc, moveKey == 'X' or isAwakened, isLocal)
            end)
            return true
        end
    end

    local sProf = M.GetSwordVFXProfile(actorChar, type(fx) == 'table' and (fx.SwordId or fx.WeaponId or fx.activeId) or nil)
    if not sProf then
        return false
    end

    local isHeavySkill = (moveKey == 'X' or moveKey == 'V' or isAwakened)
    Overhaul.SpawnStage1Sigil(Lib.SafeLookAt(startPos, dst, lookDir), sProf, sc * (isHeavySkill and 1.18 or 0.95), isHeavySkill)
    Lib.Emit('Combat', 'Sword_SlashWave', Lib.SafeLookAt(startPos + lookDir * 2.2, dst, lookDir), sc * 1.25, sProf.Primary, sProf.Secondary)

    if spawnSlashFn then
        spawnSlashFn(startPos + Vector3.new(0, 0.6, 0), dst, 0.38, sc * 1.22, sProf.Primary, sProf.Secondary, 0.32, folder)
        spawnSlashFn(startPos + Vector3.new(0, 0.6, 0), dst, -0.38, sc * 1.12, sProf.Secondary, sProf.Primary, 0.32, folder)
    end

    -- Bespoke Signature Finishers per Expansion Melee Weapon
    if sProf.Style == 'ChronoScythe' then
        -- Giant Golden Astrolabe Clock Arena + Delayed Time-Echo Rift Burst
        local gPos = Lib.FindGround(dst)
        local dial = Lib.MakePart('ChronoJudgmentDial', Enum.PartType.Cylinder, Vector3.new(0.16, 4.0 * sc, 4.0 * sc), CFrame.new(gPos + Vector3.new(0, 0.22, 0)) * CFrame.Angles(0, 0, math.pi * 0.5), PAL.Gold, 0.14, Enum.Material.ForceField, folder)
        TweenService:Create(dial, TweenInfo.new(0.48, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            Size = Vector3.new(0.06, 18.5 * sc, 18.5 * sc),
            CFrame = dial.CFrame * CFrame.Angles(2.4, 0, 0),
            Transparency = 1,
        }):Play()
        Debris:AddItem(dial, 0.52)
    elseif sProf.Style == 'ArchitectSeverance' then
        -- Descending Reality-Rift Singularity Sphere + Red-Gold Lightning Web
        local bh = Lib.MakePart('SeveranceSkillSingularity', Enum.PartType.Ball, Vector3.new(4.2, 4.2, 4.2) * sc, CFrame.new(dst + Vector3.new(0, 2.2, 0)), PAL.Obsidian, 0.06, Enum.Material.SmoothPlastic, folder)
        local halo = Lib.MakePart('SeveranceSkillHalo', Enum.PartType.Cylinder, Vector3.new(0.18, 8.8 * sc, 8.8 * sc), CFrame.new(dst + Vector3.new(0, 2.2, 0)) * CFrame.Angles(0.42, 0, math.pi * 0.5), PAL.Gold, 0.12, Enum.Material.ForceField, folder)
        TweenService:Create(bh, TweenInfo.new(0.38, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = Vector3.new(10.5, 10.5, 10.5) * sc, Transparency = 1 }):Play()
        TweenService:Create(halo, TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = Vector3.new(0.06, 18.0 * sc, 18.0 * sc), Transparency = 1 }):Play()
        Debris:AddItem(bh, 0.42)
        Debris:AddItem(halo, 0.46)
        for b = 1, 5 do
            local ang = (b - 1) * (math.pi * 0.4)
            Lib.SpawnJaggedLightning(dst + Vector3.new(0, 2.2, 0), dst + Vector3.new(math.cos(ang) * 9.5 * sc, 0.4, math.sin(ang) * 9.5 * sc), 5, 1.1 * sc, 0.26 * sc, PAL.Gold, PAL.Crimson, 0.36, folder)
        end
    elseif sProf.Style == 'MagmaBreaker' or sProf.Style == 'SolarHalberd' then
        local gPos = Lib.FindGround(dst)
        local col = Lib.MakePart('SolarMagmaPillar', Enum.PartType.Cylinder, Vector3.new(22 * sc, 3.6 * sc, 3.6 * sc), CFrame.new(gPos + Vector3.new(0, 11 * sc, 0)) * CFrame.Angles(0, 0, math.pi * 0.5), sProf.Primary, 0.14, Enum.Material.ForceField, folder)
        TweenService:Create(col, TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = Vector3.new(24 * sc, 11.5 * sc, 11.5 * sc), Transparency = 1 }):Play()
        Debris:AddItem(col, 0.46)
    end

    task.delay(0.24, function()
        Overhaul.SpawnStage3Aftermath(dst, sProf, isHeavySkill and 16 or 11, sc, isHeavySkill, isLocal)
    end)
    return true
end

return M
