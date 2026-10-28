local Players = game:GetService('Players')
local Run = game:GetService('RunService')
local Renderer = require(game.ReplicatedStorage:WaitForChild('DelegatedV5Renderer'))
local player = Players.LocalPlayer

local function progress()
end

local states = {}
local bosses = {}
local avatarTickets = {}
local localEnhanceCache = 0
local clipScaleCache = {}

local function hideLegacy(root, except)
    for _, o in root:GetDescendants() do
        if not except or not o:IsDescendantOf(except) then
            -- Roblox's camera transparency controller rewrites the modifier on
            -- character parts every frame. Hide replaced geometry locally with
            -- Transparency so stale saved mesh placeholders cannot reappear.
            if o:IsA('BasePart') then
                o.Transparency = 1
            end
            if o:IsA('Decal') then
                o.Transparency = 1
            end
        end
    end
end

local function enrichClips(clips)
    if not clips then
        return {}
    end
    if clips.Idle and not clips.TS_Idle then
        clips.TS_Idle = clips.Idle
    end
    if clips.Run and not clips.TS_Run then
        clips.TS_Run = clips.Run
    end
    if clips.Jump and not clips.TS_Jump then
        clips.TS_Jump = clips.Jump
    end
    if clips.DoubleJump and not clips.TS_DoubleJump then
        clips.TS_DoubleJump = clips.DoubleJump
    elseif clips.TS_DoubleJump and not clips.DoubleJump then
        clips.DoubleJump = clips.TS_DoubleJump
    end
    if clips.AirDash and not clips.TS_AirDash then
        clips.TS_AirDash = clips.AirDash
    elseif clips.TS_AirDash and not clips.AirDash then
        clips.AirDash = clips.TS_AirDash
    end
    if clips.Dash and not clips.TS_Dash then
        clips.TS_Dash = clips.Dash
    end
    if clips.DaggerCombo and not clips.TS_DaggerCombo then
        clips.TS_DaggerCombo = clips.DaggerCombo
    elseif clips.Attack and not clips.TS_DaggerCombo then
        clips.TS_DaggerCombo = clips.Attack
    end
    -- Wave 14-18 12-Keyframe Canonical Awakening & Kata Clips
    if clips.ElementalSurge then
        clips.TS_ElementalSurge = clips.TS_ElementalSurge or clips.ElementalSurge
        clips.SkySlash = clips.SkySlash or clips.ElementalSurge
        clips.FrostBolt = clips.FrostBolt or clips.ElementalSurge
        clips.ArcCut = clips.ArcCut or clips.ElementalSurge
        clips.TS_Dash = clips.TS_Dash or clips.ElementalSurge
        clips.Dash = clips.Dash or clips.ElementalSurge
        clips.ShieldRaise = clips.ShieldRaise or clips.ElementalSurge
        clips.ManaBarrier = clips.ManaBarrier or clips.ElementalSurge
    end
    if clips.HeroicKata then
        clips.TS_HeroicKata = clips.TS_HeroicKata or clips.HeroicKata
        clips.JudgmentStrike = clips.JudgmentStrike or clips.HeroicKata
        clips.ArcaneCircle = clips.ArcaneCircle or clips.HeroicKata
        clips.StormBlitz = clips.StormBlitz or clips.HeroicKata
    end
    if clips.UltimateAwakening then
        clips.TS_UltimateAwakening = clips.TS_UltimateAwakening or clips.UltimateAwakening
        clips.CelestialAegis = clips.CelestialAegis or clips.UltimateAwakening
        clips.FrostNova = clips.FrostNova or clips.UltimateAwakening
        clips.ThunderJudgement = clips.ThunderJudgement or clips.UltimateAwakening
        clips.HakiAwaken = clips.HakiAwaken or clips.UltimateAwakening
        clips.Ultimate = clips.Ultimate or clips.UltimateAwakening
    end
    return clips
end

local function getScaledClips(assetName, scale)
    if not assetName then
        return nil
    end
    local key = assetName .. '_' .. string.format('%.2f', scale)
    if not clipScaleCache[key] then
        local ok, loaded = pcall(Renderer.Clips, assetName, scale)
        if ok and loaded then
            clipScaleCache[key] = enrichClips(loaded)
        end
    end
    return clipScaleCache[key]
end

local function getAuraColors(level)
    if level >= 15 then
        return Color3.fromRGB(255, 215, 94), Color3.fromRGB(110, 235, 255), 'MythicSunfire'
    elseif level >= 10 then
        return Color3.fromRGB(185, 103, 255), Color3.fromRGB(255, 214, 102), 'AstralSovereign'
    elseif level >= 5 then
        return Color3.fromRGB(56, 182, 255), Color3.fromRGB(135, 235, 255), 'AzureTempest'
    else
        return Color3.fromRGB(104, 219, 255), Color3.fromRGB(190, 244, 255), 'SkyShimmer'
    end
end

local function makeAuraPart(parent, name, size, color, shape, transparency, className, material, reflectance)
    local p = Instance.new(className or 'Part')
    p.Name = name
    if not className or className == 'Part' then
        p.Shape = shape or Enum.PartType.Block
    end
    p.Size = size
    p.Color = color
    p.Material = (material and material ~= Enum.Material.Neon) and material or Enum.Material.SmoothPlastic
    p.Reflectance = reflectance or 0
    p.Transparency = math.max(transparency or 0.55, 0.45)
    p.Anchored = true
    p.CanCollide = false
    p.CanQuery = false
    p.CanTouch = false
    p.Massless = true
    p.Parent = parent
    return p
end

local function findBone(visual, names)
    local root = visual and visual.PrimaryPart
    if not root then
        return nil
    end
    for _, name in ipairs(names) do
        local b = root:FindFirstChild(name, true)
        if b and b:IsA('Bone') then
            return b
        end
    end
    return nil
end

local function getBoneWorldCF(s, bone, fallbackOffset)
    if bone and bone.Parent then
        return bone.TransformedWorldCFrame
    end
    local ratio = (s.CurrentScale or 2.6) / 2.6
    if s.Root and s.Root.Parent then
        local off = fallbackOffset or CFrame.identity
        return s.Root.CFrame * CFrame.new(off.Position * ratio) * off.Rotation
    end
    return CFrame.identity
end

local function setVisualScale(s, targetScale)
    if not s or not s.Visual or not s.Visual.Parent or not s.Root or not s.Root.Parent then
        return
    end
    if math.abs((s.CurrentScale or 2.6) - targetScale) < 0.01 then
        return
    end

    local savedFolders = {}
    for _, folderName in ipairs({ 'WeaponAwakeningAura', 'FruitTransformFX', 'HakiAuraFX', 'RaceV4FX', 'HeldFruit3D' }) do
        local f = s.Visual:FindFirstChild(folderName)
        if f then
            f.Parent = nil
            table.insert(savedFolders, f)
        end
    end

    if s.Weld then
        s.Weld.Enabled = false
    end
    s.Visual:ScaleTo(targetScale)
    local floor = s.Root.Position.Y - s.H.HipHeight - s.Root.Size.Y / 2
    s.Visual:PivotTo(CFrame.new(s.Root.Position.X, floor, s.Root.Position.Z) * s.Root.CFrame.Rotation)
    if s.Weld then
        s.Weld.Part0 = s.Root
        s.Weld.Part1 = s.Visual.PrimaryPart
        s.Weld.Enabled = true
    end

    for _, f in ipairs(savedFolders) do
        f.Parent = s.Visual
    end

    s.CurrentScale = targetScale
    if s.ClipAssetName then
        local scaled = getScaledClips(s.ClipAssetName, targetScale)
        if scaled then
            s.Clips = scaled
        end
    end
end

-- ============================================================================
-- 1. WEAPON AWAKENING AURA (+1 .. +15)
-- ============================================================================
local function buildWeaponAwakeningAura(s)
    if not s or not s.Model or not s.Model.Parent then
        return
    end
    local oldAura = s.Model:FindFirstChild('WeaponAwakeningAura')
    if oldAura then
        oldAura:Destroy()
    end
    s.Aura = nil

    local owner = s.Owner
    local ch = s.Character
    local equipped = not owner or owner:GetAttribute('WeaponEquipped') ~= false
    local level = tonumber(owner and owner:GetAttribute('WeaponEnhance'))
        or tonumber(ch and ch:GetAttribute('WeaponEnhance'))
        or (owner == player and localEnhanceCache or 0)
        or 0
    local swordId = tostring((ch and ch:GetAttribute('EquippedSword')) or (owner and owner:GetAttribute('EquippedSword')) or '')
    local gunId = tostring((ch and ch:GetAttribute('EquippedGun')) or (owner and owner:GetAttribute('EquippedGun')) or '')
    s.EnhanceLevel = level
    s.EquippedSword = swordId
    s.EquippedGun = gunId

    for _, part in s.Model:GetDescendants() do
        if part:IsA('BasePart') and part:GetAttribute('EquipmentRole') == 'Weapon' then
            local oldEmitter = part:FindFirstChild('AwakeningWeaponEmitter')
            if oldEmitter then
                oldEmitter:Destroy()
            end
            local oldLight = part:FindFirstChild('AwakeningWeaponLight')
            if oldLight then
                oldLight:Destroy()
            end
            local oldBox = part:FindFirstChild('AwakeningWeaponEdge')
            if oldBox then
                oldBox:Destroy()
            end
        end
    end

    local hasMythicWeapon = (swordId == 'cursed_dual_skyblades' or swordId == 'noxar_abyssal_greatsword' or swordId == 'dawnbringer_sword' or swordId == 'saber_of_aureon' or swordId == 'cryon_frostblade' or gunId == 'soul_guitar_void' or gunId == 'cryo_railgun')
    if (level < 1 and not hasMythicWeapon) or not equipped then
        return
    end

    local primary, secondary, tierName = getAuraColors(math.max(level, 1))
    local folder = Instance.new('Folder')
    folder.Name = 'WeaponAwakeningAura'
    folder:SetAttribute('EnhanceLevel', level)
    folder:SetAttribute('Tier', tierName)
    folder:SetAttribute('EquippedSword', swordId)
    folder:SetAttribute('EquippedGun', gunId)
    folder.Parent = s.Model

    -- Attach subtle spark emitters to weapon parts at high enhancement
    if level >= 5 then
        for _, part in s.Model:GetDescendants() do
            if part:IsA('BasePart') and part:GetAttribute('EquipmentRole') == 'Weapon' then
                local emitter = Instance.new('ParticleEmitter')
                emitter.Name = 'AwakeningWeaponEmitter'
                emitter.Color = ColorSequence.new(primary, secondary)
                emitter.LightEmission = 0.2
                emitter.LightInfluence = 0.8
                emitter.Size = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.10),
                    NumberSequenceKeypoint.new(0.6, 0.06),
                    NumberSequenceKeypoint.new(1, 0),
                })
                emitter.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.65),
                    NumberSequenceKeypoint.new(1, 1),
                })
                emitter.Lifetime = NumberRange.new(0.35, 0.65)
                emitter.Rate = math.clamp(3 + math.floor(level * 0.5), 4, 12)
                emitter.Speed = NumberRange.new(0.6, 1.5)
                emitter.SpreadAngle = Vector2.new(180, 180)
                emitter.Parent = part
            end
        end
    end

    local rHandBone = findBone(s.Visual, { 'RightHand', 'RightLowerArm', 'RightArm', 'RightBlade' })
    local lHandBone = findBone(s.Visual, { 'LeftHand', 'LeftLowerArm', 'LeftArm', 'LeftBlade' })
    local torsoBone = findBone(s.Visual, { 'UpperTorso', 'Spine', 'Torso' })

    local auraData = {
        Folder = folder,
        Level = level,
        Primary = primary,
        Secondary = secondary,
        OuterRingNodes = {},
        InnerRingNodes = {},
        Shards = {},
        SpiritBlades = {},
        HaloNodes = {},
        WeaponAttachments = {},
    }

    local function attachWeaponPart(bone, fallbackCF, name, size, color, offsetCF, className, mat, refl, trans)
        local p = makeAuraPart(folder, name, size, color, Enum.PartType.Block, trans or 0.04, className or 'Part', mat or Enum.Material.Neon, refl or 0)
        table.insert(auraData.WeaponAttachments, {
            Part = p,
            Bone = bone,
            Fallback = fallbackCF,
            Offset = offsetCF,
        })
        return p
    end

    -- Sculpted 3D Blender weapons are built directly into the character visual (no primitive WedgePart/Part bricks)

    -- +5 .. +15: Rotating Floor Rune Ring
    if level >= 5 then
        local segCount = 8
        local radius = 2.85
        local segLen = 2 * radius * math.sin(math.pi / segCount) + 0.12
        for i = 1, segCount do
            local seg = makeAuraPart(folder, 'RuneRingSeg_' .. i, Vector3.new(0.14, 0.06, segLen), primary, Enum.PartType.Block, 0.18)
            local node = makeAuraPart(folder, 'RuneRingDiamond_' .. i, Vector3.new(0.28, 0.10, 0.28), secondary, Enum.PartType.Block, 0.1)
            table.insert(auraData.OuterRingNodes, { Seg = seg, Node = node, Index = i, Count = segCount, Radius = radius })
        end
    end

    -- +10 .. +15: Counter-Rotating Inner Celestial Ring + Floating Crystal Shards
    if level >= 10 then
        local segCount = 6
        local radius = 1.95
        local segLen = 2 * radius * math.sin(math.pi / segCount) + 0.1
        for i = 1, segCount do
            local seg = makeAuraPart(folder, 'InnerCelestialSeg_' .. i, Vector3.new(0.11, 0.06, segLen), secondary, Enum.PartType.Block, 0.16)
            table.insert(auraData.InnerRingNodes, { Seg = seg, Index = i, Count = segCount, Radius = radius })
        end

        local shardCount = 4
        for i = 1, shardCount do
            local shard = makeAuraPart(
                folder,
                'AstralShard_' .. i,
                Vector3.new(0.24, 0.72, 0.24),
                i % 2 == 0 and secondary or primary,
                Enum.PartType.Block,
                0.08
            )
            table.insert(auraData.Shards, { Part = shard, Index = i, Count = shardCount })
        end
    end

    -- +15 (MAX): Mythic Celestial Sunfire Crown Halo + 4 Orbiting Radiant Spirit Blades
    if level >= 15 then
        local rayCount = 8
        for i = 1, rayCount do
            local ray = makeAuraPart(
                folder,
                'SunfireHaloRay_' .. i,
                Vector3.new(0.14, 0.52, 0.10),
                i % 2 == 0 and secondary or primary,
                Enum.PartType.Block,
                0.06
            )
            table.insert(auraData.HaloNodes, { Part = ray, Index = i, Count = rayCount })
        end

        local bladeCount = 4
        for i = 1, bladeCount do
            local blade = makeAuraPart(
                folder,
                'MythicSpiritBlade_' .. i,
                Vector3.new(0.12, 1.85, 0.32),
                i % 2 == 0 and secondary or primary,
                Enum.PartType.Block,
                0.05
            )
            local core = makeAuraPart(
                folder,
                'MythicSpiritCore_' .. i,
                Vector3.new(0.18, 0.45, 0.42),
                Color3.fromRGB(255, 248, 215),
                Enum.PartType.Block,
                0.02
            )
            table.insert(auraData.SpiritBlades, { Blade = blade, Core = core, Index = i, Count = bladeCount })
        end
    end

    s.Aura = auraData
end

local function stepWeaponAwakeningAura(s, now)
    local aura = s.Aura
    if not aura or not aura.Folder or not aura.Folder.Parent or not s.Root or not s.Root.Parent then
        return
    end
    local scaleRatio = (s.CurrentScale or 2.6) / 2.6
    local rootCF = s.Root.CFrame
    local floorY = s.Root.Position.Y - s.H.HipHeight - s.Root.Size.Y * 0.5 + 0.08
    local centerFloor = Vector3.new(rootCF.Position.X, floorY, rootCF.Position.Z)

    -- 3D Equipped Mythic/Legendary Sword & Gun Attachments
    if aura.WeaponAttachments then
        for _, wAtt in ipairs(aura.WeaponAttachments) do
            if wAtt.Part and wAtt.Part.Parent then
                local boneCF = getBoneWorldCF(s, wAtt.Bone, wAtt.Fallback)
                wAtt.Part.CFrame = boneCF * wAtt.Offset
            end
        end
    end

    -- Outer Floor Rune Ring
    for _, item in aura.OuterRingNodes do
        local r = item.Radius * scaleRatio
        local ang = now * 1.15 + (item.Index - 1) * (2 * math.pi / item.Count)
        local p = centerFloor + Vector3.new(math.cos(ang) * r, 0, math.sin(ang) * r)
        item.Seg.CFrame = CFrame.lookAt(p, centerFloor) * CFrame.Angles(0, math.pi * 0.5, 0)
        local np = centerFloor + Vector3.new(math.cos(ang + math.pi / item.Count) * (r + 0.14 * scaleRatio), 0.03, math.sin(ang + math.pi / item.Count) * (r + 0.14 * scaleRatio))
        item.Node.CFrame = CFrame.new(np) * CFrame.Angles(0, -ang + math.pi * 0.25, 0)
    end

    -- Counter-Rotating Inner Celestial Ring
    for _, item in aura.InnerRingNodes do
        local r = item.Radius * scaleRatio
        local ang = -now * 1.75 + (item.Index - 1) * (2 * math.pi / item.Count)
        local bob = math.sin(now * 2.4 + item.Index) * 0.08
        local p = centerFloor + Vector3.new(math.cos(ang) * r, 0.12 + bob, math.sin(ang) * r)
        item.Seg.CFrame = CFrame.lookAt(p, centerFloor + Vector3.new(0, 0.12 + bob, 0)) * CFrame.Angles(0, math.pi * 0.5, 0)
    end

    -- Orbiting Crystal Shards (+10..+15)
    for _, item in aura.Shards do
        local ang = now * 2.1 + (item.Index - 1) * (2 * math.pi / item.Count)
        local yOff = (2.2 + math.sin(now * 3.2 + item.Index * 1.5) * 0.35) * scaleRatio
        local pos = centerFloor + Vector3.new(math.cos(ang) * 2.25 * scaleRatio, yOff, math.sin(ang) * 2.25 * scaleRatio)
        item.Part.CFrame = CFrame.new(pos) * CFrame.Angles(0.35, -ang, math.pi * 0.25)
    end

    -- +15 Sunfire Back Crown Halo & 4 Orbiting Radiant Spirit Blades
    if #aura.HaloNodes > 0 then
        local haloCenter = rootCF * CFrame.new(0, 1.35 * scaleRatio, 1.15 * scaleRatio)
        for _, item in aura.HaloNodes do
            local ang = now * 1.6 + (item.Index - 1) * (2 * math.pi / item.Count)
            local r = (1.25 + math.sin(now * 4 + item.Index) * 0.05) * scaleRatio
            local offset = CFrame.Angles(0, 0, ang) * CFrame.new(0, r, 0)
            item.Part.CFrame = haloCenter * offset
        end
    end

    for _, item in aura.SpiritBlades do
        local ang = -now * 2.6 + (item.Index - 1) * (2 * math.pi / item.Count)
        local yOff = (2.8 + math.cos(now * 3.0 + item.Index) * 0.45) * scaleRatio
        local orbitPos = centerFloor + Vector3.new(math.cos(ang) * 2.95 * scaleRatio, yOff, math.sin(ang) * 2.95 * scaleRatio)
        local bladeCF = CFrame.lookAt(orbitPos, centerFloor + Vector3.new(0, yOff, 0)) * CFrame.Angles(math.rad(18), 0, math.rad(12))
        item.Blade.CFrame = bladeCF
        item.Core.CFrame = bladeCF * CFrame.new(0, -0.45, 0)
    end
end

-- ============================================================================
-- 2. 3D BEAST FRUIT TRANSFORMATIONS (SolarTitan & AbyssalSovereign)
-- ============================================================================
local function buildFruitTransformFX(s, mode)
    if not s or not s.Visual or not s.Visual.Parent then
        return
    end
    local oldFX = s.Visual:FindFirstChild('FruitTransformFX')
    if oldFX then
        oldFX:Destroy()
    end
    s.TransformFX = nil
    s.FruitTransform = mode or ''

    if mode == 'SolarTitan' then
        -- Buddha Core Transformation: Golden Solar Titan (scale = 2.6 * 2.15 = 5.59)
        setVisualScale(s, 2.6 * 2.15)

        local folder = Instance.new('Folder')
        folder.Name = 'FruitTransformFX'
        folder:SetAttribute('TransformId', 'SolarTitan')
        folder.Parent = s.Visual

        local hl = Instance.new('Highlight')
        hl.Name = 'SolarTitanHighlight'
        hl.Adornee = s.Visual
        hl.FillColor = Color3.fromRGB(255, 215, 65)
        hl.FillTransparency = 0.90
        hl.OutlineColor = Color3.fromRGB(255, 248, 175)
        hl.OutlineTransparency = 0.55
        hl.Parent = folder

        local solarGold = Color3.fromRGB(255, 215, 65)
        local sunWhite = Color3.fromRGB(255, 248, 175)
        local sunAmber = Color3.fromRGB(255, 172, 42)

        local fxData = {
            Mode = 'SolarTitan',
            Folder = folder,
            Spears = {},
            HaloSegments = {},
            HaloRays = {},
            LotusPetals = {},
            HeadBone = findBone(s.Visual, { 'Head', 'head' }),
            TorsoBone = findBone(s.Visual, { 'UpperTorso', 'Spine', 'Torso' }),
        }

        local centerAnchor = makeAuraPart(folder, 'SolarCoreAnchor', Vector3.new(0.4, 0.4, 0.4), solarGold, Enum.PartType.Ball, 1)
        local light = Instance.new('PointLight')
        light.Name = 'SolarTitanLight'
        light.Color = solarGold
        light.Brightness = 0.35
        light.Range = 8
        light.Parent = centerAnchor

        local emitter = Instance.new('ParticleEmitter')
        emitter.Name = 'SolarTitanEmbers'
        emitter.Color = ColorSequence.new(solarGold, sunWhite)
        emitter.LightEmission = 1
        emitter.LightInfluence = 0
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.42),
            NumberSequenceKeypoint.new(0.6, 0.24),
            NumberSequenceKeypoint.new(1, 0),
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.08),
            NumberSequenceKeypoint.new(1, 1),
        })
        emitter.Lifetime = NumberRange.new(0.7, 1.35)
        emitter.Rate = 48
        emitter.Speed = NumberRange.new(2.5, 6.5)
        emitter.SpreadAngle = Vector2.new(180, 180)
        emitter.Parent = centerAnchor
        fxData.CoreAnchor = centerAnchor

        -- 6 Orbiting Golden Solar Spears / Pillars (Multi-part sculpted)
        local spearCount = 6
        for i = 1, spearCount do
            local shaft = makeAuraPart(folder, 'SolarSpearShaft_' .. i, Vector3.new(0.34, 5.8, 0.34), solarGold, Enum.PartType.Block, 0.06)
            local tip = makeAuraPart(folder, 'SolarSpearTip_' .. i, Vector3.new(0.48, 1.65, 0.56), sunWhite, Enum.PartType.Block, 0.02, 'WedgePart')
            local pommel = makeAuraPart(folder, 'SolarSpearRing_' .. i, Vector3.new(0.24, 1.35, 1.35), sunAmber, Enum.PartType.Cylinder, 0.1)
            table.insert(fxData.Spears, {
                Shaft = shaft,
                Tip = tip,
                Ring = pommel,
                Index = i,
                Count = spearCount,
            })
        end

        -- Giant Overhead Solar Halo rotating above the Titan's head
        local haloSegCount = 12
        local haloRadius = 3.85
        local haloSegLen = 2 * haloRadius * math.sin(math.pi / haloSegCount) + 0.18
        for i = 1, haloSegCount do
            local seg = makeAuraPart(folder, 'SolarHaloSeg_' .. i, Vector3.new(0.28, 0.24, haloSegLen), solarGold, Enum.PartType.Block, 0.05)
            table.insert(fxData.HaloSegments, { Part = seg, Index = i, Count = haloSegCount, Radius = haloRadius })
        end

        local rayCount = 8
        for i = 1, rayCount do
            local ray = makeAuraPart(folder, 'SolarHaloSpoke_' .. i, Vector3.new(0.24, 1.75, 0.42), i % 2 == 0 and sunWhite or sunAmber, Enum.PartType.Block, 0.04, 'WedgePart')
            table.insert(fxData.HaloRays, { Part = ray, Index = i, Count = rayCount, Radius = haloRadius + 0.85 })
        end

        -- Golden Dharma Lotus Ring at the Titan's feet
        local petalCount = 10
        for i = 1, petalCount do
            local petal = makeAuraPart(folder, 'SolarLotusPetal_' .. i, Vector3.new(0.28, 1.35, 0.85), i % 2 == 0 and solarGold or sunAmber, Enum.PartType.Block, 0.14, 'WedgePart')
            table.insert(fxData.LotusPetals, { Part = petal, Index = i, Count = petalCount, Radius = 5.4 })
        end

        -- Attach true sculpted 3D V5 SolarTitanBuddha form (Wave 18/19 Overhaul)
        local okTitan, titanTemplate = pcall(Renderer.Build, 'SolarTitanBuddha')
        if okTitan and titanTemplate then
            local titanClone = titanTemplate:Clone()
            titanClone.Name = 'SolarTitanBuddha_3DForm'
            titanClone:ScaleTo(3.6)
            local floor = s.Root.Position.Y - s.H.HipHeight - s.Root.Size.Y * 0.5
            titanClone:PivotTo(CFrame.new(s.Root.Position.X, floor, s.Root.Position.Z) * s.Root.CFrame.Rotation)
            for _, d in ipairs(titanClone:GetDescendants()) do
                if d:IsA('BasePart') then
                    d.Anchored = false
                    d.CanCollide = false
                    d.CanQuery = false
                    d.CanTouch = false
                    d.Massless = true
                end
            end
            if titanClone.PrimaryPart then
                local rootWeld = Instance.new('WeldConstraint')
                rootWeld.Part0 = s.Root
                rootWeld.Part1 = titanClone.PrimaryPart
                rootWeld.Parent = titanClone.PrimaryPart
            end
            titanClone.Parent = folder
            hl.Adornee = titanClone
            fxData.V5Model = titanClone
            fxData.V5Clips = getScaledClips('SolarTitanBuddha', 3.6)
            for _, chPart in ipairs(s.Visual:GetChildren()) do
                if chPart:IsA('BasePart') then
                    chPart.LocalTransparencyModifier = 1
                end
            end
        else
            fxData.ChestCore = makeAuraPart(folder, 'SolarTitanChestCore', Vector3.new(1.15, 1.15, 0.45), sunWhite, Enum.PartType.Ball, 0.02)
            fxData.TabardFront = makeAuraPart(folder, 'SolarTitanTabard', Vector3.new(1.85, 2.85, 0.24), Color3.fromRGB(36, 92, 215), Enum.PartType.Block, 0.08, 'Part', Enum.Material.SmoothPlastic, 0.15)
            fxData.TabardTrim = makeAuraPart(folder, 'SolarTitanTabardTrim', Vector3.new(2.05, 0.36, 0.30), solarGold, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.34)
        end

        s.TransformFX = fxData

    elseif mode == 'AbyssalSovereign' or mode == 'AbyssalDragonHybrid' then
        -- Void Dragon Core Transformation: Abyssal Sovereign / Hybrid
        setVisualScale(s, 2.6)

        local folder = Instance.new('Folder')
        folder.Name = 'FruitTransformFX'
        folder:SetAttribute('TransformId', mode)
        folder.Parent = s.Visual

        local hl = Instance.new('Highlight')
        hl.Name = 'AbyssalDragonHighlight'
        hl.Adornee = s.Visual
        hl.FillColor = Color3.fromRGB(168, 35, 255)
        hl.FillTransparency = 0.92
        hl.OutlineColor = Color3.fromRGB(255, 55, 145)
        hl.OutlineTransparency = 0.60
        hl.Parent = folder

        local voidPurple = Color3.fromRGB(168, 35, 255)
        local dragonCrimson = Color3.fromRGB(255, 55, 145)
        local obsidian = Color3.fromRGB(22, 12, 36)

        local fxData = {
            Mode = 'AbyssalSovereign',
            SubMode = mode,
            Folder = folder,
            Wings = {},
            Horns = {},
            Orbs = {},
            TailSegments = {},
            HeadBone = findBone(s.Visual, { 'Head', 'head' }),
            TorsoBone = findBone(s.Visual, { 'UpperTorso', 'Spine', 'Torso' }),
        }

        -- Swirling purple-crimson fire emitter + Abyssal PointLight tracked to UpperTorso
        local torsoAnchor = makeAuraPart(folder, 'AbyssalTorsoAnchor', Vector3.new(0.35, 0.35, 0.35), voidPurple, Enum.PartType.Ball, 1)
        local light = Instance.new('PointLight')
        light.Name = 'AbyssalDragonLight'
        light.Color = voidPurple
        light.Brightness = 0.35
        light.Range = 8
        light.Parent = torsoAnchor

        local fireEmitter = Instance.new('ParticleEmitter')
        fireEmitter.Name = 'AbyssalDragonFire'
        fireEmitter.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, dragonCrimson),
            ColorSequenceKeypoint.new(0.5, voidPurple),
            ColorSequenceKeypoint.new(1, obsidian),
        })
        fireEmitter.LightEmission = 0.9
        fireEmitter.LightInfluence = 0
        fireEmitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.48),
            NumberSequenceKeypoint.new(0.55, 0.32),
            NumberSequenceKeypoint.new(1, 0),
        })
        fireEmitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.12),
            NumberSequenceKeypoint.new(1, 1),
        })
        fireEmitter.Lifetime = NumberRange.new(0.55, 1.15)
        fireEmitter.Rate = 40
        fireEmitter.Speed = NumberRange.new(2.2, 5.6)
        fireEmitter.SpreadAngle = Vector2.new(180, 180)
        fireEmitter.Parent = torsoAnchor
        fxData.TorsoAnchor = torsoAnchor

        -- 3 Orbiting Abyssal Flame Orbs
        for i = 1, 3 do
            local orb = makeAuraPart(folder, 'AbyssalDragonOrb_' .. i, Vector3.new(0.62, 0.62, 0.62), i % 2 == 0 and dragonCrimson or voidPurple, Enum.PartType.Ball, 0.08)
            table.insert(fxData.Orbs, { Part = orb, Index = i, Count = 3 })
        end

        -- Attach true sculpted 3D V5 AbyssalSovereignDragon / AbyssalDragonHybrid form (Wave 18/19 Overhaul)
        local v5DragonAsset = mode == 'AbyssalDragonHybrid' and 'AbyssalDragonHybrid' or 'AbyssalSovereignDragon'
        local v5DragonScale = mode == 'AbyssalDragonHybrid' and 3.2 or 3.4
        local okDragon, dragonTemplate = pcall(Renderer.Build, v5DragonAsset)
        if okDragon and dragonTemplate then
            local dragonClone = dragonTemplate:Clone()
            dragonClone.Name = v5DragonAsset .. '_3DForm'
            dragonClone:ScaleTo(v5DragonScale)
            local floor = s.Root.Position.Y - s.H.HipHeight - s.Root.Size.Y * 0.5
            dragonClone:PivotTo(CFrame.new(s.Root.Position.X, floor, s.Root.Position.Z) * s.Root.CFrame.Rotation)
            for _, d in ipairs(dragonClone:GetDescendants()) do
                if d:IsA('BasePart') then
                    d.Anchored = false
                    d.CanCollide = false
                    d.CanQuery = false
                    d.CanTouch = false
                    d.Massless = true
                end
            end
            if dragonClone.PrimaryPart then
                local rootWeld = Instance.new('WeldConstraint')
                rootWeld.Part0 = s.Root
                rootWeld.Part1 = dragonClone.PrimaryPart
                rootWeld.Parent = dragonClone.PrimaryPart
            end
            dragonClone.Parent = folder
            hl.Adornee = dragonClone
            fxData.V5Model = dragonClone
            fxData.V5Clips = getScaledClips(v5DragonAsset, v5DragonScale)
            for _, chPart in ipairs(s.Visual:GetChildren()) do
                if chPart:IsA('BasePart') then
                    chPart.LocalTransparencyModifier = 1
                end
            end
        end

        s.TransformFX = fxData
    else
        -- Restore default character scale (2.6) & human mesh visibility
        setVisualScale(s, 2.6)
        local equipped = not s.Owner or s.Owner:GetAttribute('WeaponEquipped') ~= false
        for _, chPart in ipairs(s.Visual:GetChildren()) do
            if chPart:IsA('BasePart') then
                if chPart:GetAttribute('EquipmentRole') == 'Weapon' then
                    chPart.LocalTransparencyModifier = equipped and 0 or 1
                else
                    chPart.LocalTransparencyModifier = 0
                end
            end
        end
    end
end

local function stepFruitTransformFX(s, now)
    local fx = s.TransformFX
    if not fx or not fx.Folder or not fx.Folder.Parent or not s.Root or not s.Root.Parent then
        return
    end
    local rootCF = s.Root.CFrame
    local floorY = s.Root.Position.Y - s.H.HipHeight - s.Root.Size.Y * 0.5 + 0.1
    local centerFloor = Vector3.new(rootCF.Position.X, floorY, rootCF.Position.Z)

    -- Step true sculpted 3D V5 Beast Transformation rig (SolarTitanBuddha / AbyssalSovereignDragon / AbyssalDragonHybrid)
    if fx.V5Model and fx.V5Model.Parent then
        for _, chPart in ipairs(s.Visual:GetChildren()) do
            if chPart:IsA('BasePart') and chPart.LocalTransparencyModifier < 1 then
                chPart.LocalTransparencyModifier = 1
            end
        end
        if fx.V5Clips then
            local curKey = tostring(s.Name or 'Idle'):gsub('^TS_', '')
            local v5Clip = fx.V5Clips[curKey]
            if not v5Clip then
                if curKey == 'SkySlash' or curKey == 'FrostBolt' or curKey == 'ArcCut' or curKey == 'Dash' then
                    v5Clip = fx.V5Clips.ElementalSurge or fx.V5Clips.Attack
                elseif curKey == 'JudgmentStrike' or curKey == 'ArcaneCircle' or curKey == 'StormBlitz' then
                    v5Clip = fx.V5Clips.HeroicKata or fx.V5Clips.Heavy
                elseif curKey == 'CelestialAegis' or curKey == 'FrostNova' or curKey == 'ThunderJudgement' or curKey == 'HakiAwaken' then
                    v5Clip = fx.V5Clips.UltimateAwakening or fx.V5Clips.Heavy
                elseif curKey == 'DaggerCombo' then
                    v5Clip = fx.V5Clips.Attack
                elseif curKey == 'Run' or curKey == 'Walk' then
                    v5Clip = fx.V5Clips.Run or fx.V5Clips.Swim or fx.V5Clips.Idle
                else
                    v5Clip = fx.V5Clips.Idle
                end
            end
            if v5Clip then
                Renderer.Pose(fx.V5Model, v5Clip, now - (s.Start or 0))
            end
        end
    end

    if fx.Mode == 'SolarTitan' then
        local torsoCF = getBoneWorldCF(s, fx.TorsoBone, CFrame.new(0, 1.2, 0))
        local headCF = getBoneWorldCF(s, fx.HeadBone, CFrame.new(0, 3.2, 0))

        if fx.CoreAnchor then
            fx.CoreAnchor.CFrame = torsoCF
        end
        if fx.ChestCore then
            fx.ChestCore.CFrame = torsoCF * CFrame.new(0, 0.35, -1.05)
        end
        if fx.TabardFront then
            fx.TabardFront.CFrame = torsoCF * CFrame.new(0, -2.15, -0.95)
        end
        if fx.TabardTrim then
            fx.TabardTrim.CFrame = torsoCF * CFrame.new(0, -0.75, -1.02)
        end

        -- 6 Orbiting Golden Solar Spears/Pillars
        for _, sp in ipairs(fx.Spears) do
            local ang = now * 1.65 + (sp.Index - 1) * (2 * math.pi / sp.Count)
            local bob = math.sin(now * 2.8 + sp.Index) * 0.65
            local orbitPos = torsoCF.Position + Vector3.new(math.cos(ang) * 6.4, 0.8 + bob, math.sin(ang) * 6.4)
            local spearCF = CFrame.lookAt(orbitPos, torsoCF.Position + Vector3.new(0, 0.8 + bob, 0)) * CFrame.Angles(math.rad(10), 0, 0)
            sp.Shaft.CFrame = spearCF
            sp.Tip.CFrame = spearCF * CFrame.new(0, 3.65, 0)
            sp.Ring.CFrame = spearCF * CFrame.new(0, -2.2, 0) * CFrame.Angles(0, 0, math.pi * 0.5)
        end

        -- Giant Overhead Solar Halo rotating above Titan's head
        local haloCenter = CFrame.new(headCF.Position + Vector3.new(0, 3.2, 0)) * CFrame.Angles(math.rad(16), now * 1.25, 0)
        for _, seg in ipairs(fx.HaloSegments) do
            local ang = (seg.Index - 1) * (2 * math.pi / seg.Count)
            local pos = haloCenter * CFrame.new(math.cos(ang) * seg.Radius, 0, math.sin(ang) * seg.Radius)
            seg.Part.CFrame = CFrame.lookAt(pos.Position, haloCenter.Position) * CFrame.Angles(0, math.pi * 0.5, 0)
        end
        for _, ray in ipairs(fx.HaloRays) do
            local ang = (ray.Index - 1) * (2 * math.pi / ray.Count)
            local pos = haloCenter * CFrame.new(math.cos(ang) * ray.Radius, 0, math.sin(ang) * ray.Radius)
            ray.Part.CFrame = CFrame.lookAt(haloCenter.Position, pos.Position) * CFrame.Angles(math.pi * 0.5, 0, 0)
        end

        -- Golden Dharma Lotus Ring on floor
        for _, petal in ipairs(fx.LotusPetals) do
            local ang = -now * 0.95 + (petal.Index - 1) * (2 * math.pi / petal.Count)
            local pPos = centerFloor + Vector3.new(math.cos(ang) * petal.Radius, 0.45, math.sin(ang) * petal.Radius)
            petal.Part.CFrame = CFrame.lookAt(centerFloor + Vector3.new(0, 0.45, 0), pPos) * CFrame.Angles(math.rad(35), 0, 0)
        end

    elseif fx.Mode == 'AbyssalSovereign' then
        local torsoCF = getBoneWorldCF(s, fx.TorsoBone, CFrame.new(0, 1.0, 0))
        local headCF = getBoneWorldCF(s, fx.HeadBone, CFrame.new(0, 2.6, 0))

        if fx.TorsoAnchor then
            fx.TorsoAnchor.CFrame = torsoCF
        end

        -- 6 Articulated 3D Void Dragon Wing Blades tracked to UpperTorso bone
        local flap = math.sin(now * 4.2) * 0.24
        for _, w in ipairs(fx.Wings) do
            local sDir = w.Side
            local tier = w.Tier
            local baseOffset = CFrame.new(sDir * (0.95 + tier * 0.55), 0.95 - tier * 0.45, 1.15)
                * CFrame.Angles(-0.22 + flap * 0.35, sDir * (0.35 + flap), -sDir * (0.52 + tier * 0.28 + flap * 0.45))
            local wingWorldCF = torsoCF * baseOffset
            w.Blade.CFrame = wingWorldCF
            w.Spine.CFrame = wingWorldCF * CFrame.new(0, 0, 0.28)
        end

        -- 2 Dragon Horns tracked to Head bone
        for _, h in ipairs(fx.Horns) do
            local sDir = h.Side
            local baseCF = headCF * CFrame.new(sDir * 0.65, 0.78, -0.12) * CFrame.Angles(-0.28, 0, -sDir * 0.38)
            h.Base.CFrame = baseCF
            h.Tip.CFrame = baseCF * CFrame.new(0, 1.35, -0.22) * CFrame.Angles(0.32, 0, -sDir * 0.12)
        end

        -- Articulated 4-Segment Dragon Tail
        if fx.TailSegments then
            for _, tSeg in ipairs(fx.TailSegments) do
                local idx = tSeg.Index
                local sway = math.sin(now * 3.8 - idx * 0.55) * (0.22 * idx)
                local tailCF = torsoCF * CFrame.new(sway, -0.95 - idx * 0.65, 0.95 + idx * 0.85)
                    * CFrame.Angles(0.65 + idx * 0.18, sway * 0.45, 0)
                tSeg.Part.CFrame = tailCF
            end
        end

        -- Orbiting Abyssal Orbs
        for _, orb in ipairs(fx.Orbs) do
            local ang = now * 2.4 + (orb.Index - 1) * (2 * math.pi / orb.Count)
            local yOff = math.sin(now * 3.5 + orb.Index) * 0.85
            orb.Part.CFrame = CFrame.new(torsoCF.Position + Vector3.new(math.cos(ang) * 3.8, yOff, math.sin(ang) * 3.8))
        end
    end
end

-- ============================================================================
-- 3. FULL-BODY BUSOSHOKU HAKI AURA (character:GetAttribute("HakiAura") — Key [J])
-- ============================================================================
local function buildHakiAuraFX(s, enabled)
    if not s or not s.Visual or not s.Visual.Parent then
        return
    end
    local oldFX = s.Visual:FindFirstChild('HakiAuraFX')
    if oldFX then
        oldFX:Destroy()
    end
    s.HakiFX = nil
    s.HakiAura = enabled == true

    if not s.HakiAura then
        return
    end

    local folder = Instance.new('Folder')
    folder.Name = 'HakiAuraFX'
    folder.Parent = s.Visual

    local hl = Instance.new('Highlight')
    hl.Name = 'BusoshokuHighlight'
    hl.Adornee = s.Visual
    hl.FillColor = Color3.fromRGB(18, 12, 24)
    hl.FillTransparency = 0.72
    hl.OutlineColor = Color3.fromRGB(255, 42, 95)
    hl.OutlineTransparency = 0.1
    hl.Parent = folder

    local hakiCrimson = Color3.fromRGB(255, 42, 95)
    local hakiObsidian = Color3.fromRGB(18, 12, 24)

    local rHandBone = findBone(s.Visual, { 'RightHand', 'RightLowerArm', 'RightArm', 'RightBlade' })
    local lHandBone = findBone(s.Visual, { 'LeftHand', 'LeftLowerArm', 'LeftArm', 'LeftBlade' })

    local handNodes = {}
    for _, entry in ipairs({
        { Name = 'RightHandHaki', Bone = rHandBone, Fallback = CFrame.new(1.3, 0, -0.4), Side = 1 },
        { Name = 'LeftHandHaki', Bone = lHandBone, Fallback = CFrame.new(-1.3, 0, -0.4), Side = -1 },
    }) do
        local node = makeAuraPart(folder, entry.Name, Vector3.new(0.42, 0.42, 0.42), hakiCrimson, Enum.PartType.Ball, 0.35)
        local light = Instance.new('PointLight')
        light.Name = 'HakiHandLight'
        light.Color = hakiCrimson
        light.Brightness = 0.25
        light.Range = 5
        light.Parent = node

        local emitter = Instance.new('ParticleEmitter')
        emitter.Name = 'HakiLightningEmitter'
        emitter.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, hakiCrimson),
            ColorSequenceKeypoint.new(0.55, Color3.fromRGB(255, 110, 145)),
            ColorSequenceKeypoint.new(1, hakiObsidian),
        })
        emitter.LightEmission = 1
        emitter.LightInfluence = 0
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.28),
            NumberSequenceKeypoint.new(0.5, 0.16),
            NumberSequenceKeypoint.new(1, 0),
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.05),
            NumberSequenceKeypoint.new(1, 1),
        })
        emitter.Lifetime = NumberRange.new(0.22, 0.48)
        emitter.Rate = 36
        emitter.Speed = NumberRange.new(1.8, 4.5)
        emitter.SpreadAngle = Vector2.new(180, 180)
        emitter.Parent = node

        local bolts = {}
        for b = 1, 3 do
            local bolt = makeAuraPart(
                folder,
                entry.Name .. '_Bolt_' .. b,
                Vector3.new(0.09, 0.95, 0.09),
                b % 2 == 0 and hakiObsidian or hakiCrimson,
                Enum.PartType.Block,
                0.08
            )
            table.insert(bolts, bolt)
        end

        table.insert(handNodes, {
            Node = node,
            Bone = entry.Bone,
            Fallback = entry.Fallback,
            Side = entry.Side,
            Bolts = bolts,
        })
    end

    s.HakiFX = {
        Folder = folder,
        Highlight = hl,
        HandNodes = handNodes,
    }
end

local function stepHakiAuraFX(s, now)
    local fx = s.HakiFX
    if not fx or not fx.Folder or not fx.Folder.Parent or not s.Root or not s.Root.Parent then
        return
    end
    for _, hNode in ipairs(fx.HandNodes) do
        local handCF = getBoneWorldCF(s, hNode.Bone, hNode.Fallback)
        hNode.Node.CFrame = handCF
        for idx, bolt in ipairs(hNode.Bolts) do
            local ang = now * 14 + idx * 2.1 + hNode.Side
            local jitter = CFrame.new(math.cos(ang) * 0.35, math.sin(ang * 1.3) * 0.35, math.sin(ang) * 0.35)
                * CFrame.Angles(math.sin(now * 18 + idx) * 1.4, ang, math.cos(now * 16 + idx) * 1.4)
            bolt.CFrame = handCF * jitter
        end
    end
end

-- ============================================================================
-- 4. RACE V4 FULL-GEAR 3D WINGS & COSMETICS (character:GetAttribute("RaceV4") — Key [Y])
-- ============================================================================
local function buildRaceV4FX(s, raceName)
    if not s or not s.Visual or not s.Visual.Parent then
        return
    end
    local oldFX = s.Visual:FindFirstChild('RaceV4FX')
    if oldFX then
        oldFX:Destroy()
    end
    s.RaceFX = nil
    s.RaceV4 = raceName or ''

    if type(raceName) ~= 'string' or raceName == '' then
        return
    end

    local folder = Instance.new('Folder')
    folder.Name = 'RaceV4FX'
    folder:SetAttribute('RaceV4', raceName)
    folder.Parent = s.Visual

    local headBone = findBone(s.Visual, { 'Head', 'head' })
    local torsoBone = findBone(s.Visual, { 'UpperTorso', 'Spine', 'Torso' })
    local lFootBone = findBone(s.Visual, { 'LeftFoot', 'LeftLowerLeg', 'LeftLeg' })
    local rFootBone = findBone(s.Visual, { 'RightFoot', 'RightLowerLeg', 'RightLeg' })

    local fxData = {
        Race = raceName,
        Folder = folder,
        HeadBone = headBone,
        TorsoBone = torsoBone,
        LFootBone = lFootBone,
        RFootBone = rFootBone,
        TorsoParts = {},
        HeadParts = {},
        FootParts = {},
        OrbitParts = {},
    }

    if raceName == 'Skyborn' then
        -- 6 Radiant golden-white Angel Feather Wing blades + Halo
        local gold = Color3.fromRGB(255, 224, 115)
        local white = Color3.fromRGB(255, 252, 240)
        for i = 1, 6 do
            local side = (i <= 3) and -1 or 1
            local tier = ((i - 1) % 3) + 1
            local feather = makeAuraPart(
                folder,
                'SkybornAngelWing_' .. i,
                Vector3.new(0.16, 2.85 - tier * 0.32, 0.62 - tier * 0.06),
                tier % 2 == 1 and white or gold,
                Enum.PartType.Block,
                0.06,
                'WedgePart'
            )
            table.insert(fxData.TorsoParts, {
                Part = feather,
                Side = side,
                Tier = tier,
                FlapSpeed = 3.6,
                BaseOffset = CFrame.new(side * (0.65 + tier * 0.34), 0.78 - tier * 0.32, 0.76),
                BaseAngles = Vector3.new(-0.18, side * 0.28, -side * (0.46 + tier * 0.24)),
            })
        end
        local haloSegs = 8
        local haloR = 1.15
        local segLen = 2 * haloR * math.sin(math.pi / haloSegs) + 0.08
        for i = 1, haloSegs do
            local seg = makeAuraPart(folder, 'SkybornHaloSeg_' .. i, Vector3.new(0.14, 0.12, segLen), gold, Enum.PartType.Block, 0.04)
            table.insert(fxData.HeadParts, { Part = seg, Index = i, Count = haloSegs, Radius = haloR, IsHalo = true })
        end

    elseif raceName == 'Mink' then
        -- 25_race_v4_awakening_wings_sheet.png: 6 Cyan Lightning Bolt Wings + Beast Ears + Speed Tail + Foot Whirlwinds
        local cyan = Color3.fromRGB(72, 242, 255)
        local electric = Color3.fromRGB(195, 252, 255)
        for i = 1, 6 do
            local side = (i <= 3) and -1 or 1
            local tier = ((i - 1) % 3) + 1
            local boltWing = makeAuraPart(
                folder,
                'MinkStormWing_' .. i,
                Vector3.new(0.16, 2.75 - tier * 0.28, 0.56 - tier * 0.05),
                tier % 2 == 1 and cyan or electric,
                Enum.PartType.Block,
                0.05,
                'WedgePart'
            )
            table.insert(fxData.TorsoParts, {
                Part = boltWing,
                Side = side,
                Tier = tier,
                FlapSpeed = 5.2,
                BaseOffset = CFrame.new(side * (0.68 + tier * 0.34), 0.78 - tier * 0.32, 0.76),
                BaseAngles = Vector3.new(-0.18, side * 0.28, -side * (0.48 + tier * 0.24)),
            })
        end
        for _, side in ipairs({ -1, 1 }) do
            local ear = makeAuraPart(folder, 'MinkBeastEar_' .. (side < 0 and 'L' or 'R'), Vector3.new(0.18, 0.85, 0.28), electric, Enum.PartType.Block, 0.04, 'WedgePart')
            table.insert(fxData.HeadParts, {
                Part = ear,
                Offset = CFrame.new(side * 0.42, 0.62, 0) * CFrame.Angles(-0.15, 0, -side * 0.22),
            })
        end
        for i = 1, 3 do
            local tailSeg = makeAuraPart(
                folder,
                'MinkLightningTail_' .. i,
                Vector3.new(0.24 - i * 0.03, 1.15, 0.34 - i * 0.04),
                i % 2 == 1 and cyan or electric,
                Enum.PartType.Block,
                0.08,
                'WedgePart'
            )
            table.insert(fxData.TorsoParts, {
                Part = tailSeg,
                Side = 1,
                Tier = i,
                FlapSpeed = 6.5,
                BaseOffset = CFrame.new(0, -0.55 + i * 0.35, 0.85 + i * 0.45),
                BaseAngles = Vector3.new(0.65 + i * 0.22, 0, 0),
            })
        end
        for _, fEntry in ipairs({
            { Name = 'LeftFootWhirlwind', Bone = lFootBone, Fallback = CFrame.new(-0.6, -2.5, 0) },
            { Name = 'RightFootWhirlwind', Bone = rFootBone, Fallback = CFrame.new(0.6, -2.5, 0) },
        }) do
            for rIdx = 1, 2 do
                local ring = makeAuraPart(
                    folder,
                    fEntry.Name .. '_' .. rIdx,
                    Vector3.new(0.12, 1.45 + rIdx * 0.45, 1.45 + rIdx * 0.45),
                    rIdx == 1 and cyan or electric,
                    Enum.PartType.Cylinder,
                    0.18
                )
                table.insert(fxData.FootParts, {
                    Part = ring,
                    Bone = fEntry.Bone,
                    Fallback = fEntry.Fallback,
                    Layer = rIdx,
                })
            end
        end

    elseif raceName == 'Leviathan' then
        -- 25_race_v4_awakening_wings_sheet.png: 6 Bioluminescent Aqua-Sapphire Hydro-Fin Wings + Dorsal Fins + Orbiting Water Shields
        local sapphire = Color3.fromRGB(36, 142, 255)
        local aqua = Color3.fromRGB(98, 232, 255)
        for i = 1, 6 do
            local side = (i <= 3) and -1 or 1
            local tier = ((i - 1) % 3) + 1
            local hydroWing = makeAuraPart(
                folder,
                'LeviathanHydroWing_' .. i,
                Vector3.new(0.16, 2.80 - tier * 0.28, 0.65 - tier * 0.06),
                tier % 2 == 1 and aqua or sapphire,
                Enum.PartType.Block,
                0.06,
                'WedgePart'
            )
            table.insert(fxData.TorsoParts, {
                Part = hydroWing,
                Side = side,
                Tier = tier,
                FlapSpeed = 3.2,
                BaseOffset = CFrame.new(side * (0.68 + tier * 0.34), 0.78 - tier * 0.32, 0.76),
                BaseAngles = Vector3.new(-0.18, side * 0.28, -side * (0.46 + tier * 0.24)),
            })
        end
        for i = 1, 4 do
            local fin = makeAuraPart(
                folder,
                'LeviathanDorsalFin_' .. i,
                Vector3.new(0.18, 1.55 - i * 0.18, 0.65),
                i % 2 == 1 and sapphire or aqua,
                Enum.PartType.Block,
                0.08,
                'WedgePart'
            )
            table.insert(fxData.TorsoParts, {
                Part = fin,
                Side = 1,
                Tier = i,
                FlapSpeed = 2.5,
                BaseOffset = CFrame.new(0, 0.95 - i * 0.48, 0.88 + i * 0.08),
                BaseAngles = Vector3.new(-0.42, 0, 0),
            })
        end
        for i = 1, 4 do
            local shield = makeAuraPart(
                folder,
                'LeviathanWaterShield_' .. i,
                Vector3.new(0.18, 1.65, 1.15),
                i % 2 == 0 and aqua or sapphire,
                Enum.PartType.Block,
                0.18
            )
            table.insert(fxData.OrbitParts, { Part = shield, Index = i, Count = 4, Radius = 2.85 })
        end

    elseif raceName == 'Cyborg' then
        -- Neon magenta-cyan Mecha Jet Wings
        local magenta = Color3.fromRGB(255, 58, 195)
        local cyan = Color3.fromRGB(68, 242, 255)
        for i = 1, 6 do
            local side = (i <= 3) and -1 or 1
            local tier = ((i - 1) % 3) + 1
            local wing = makeAuraPart(
                folder,
                'CyborgMechaWing_' .. i,
                Vector3.new(0.18, 2.75 - tier * 0.30, 0.56),
                tier % 2 == 1 and cyan or magenta,
                Enum.PartType.Block,
                0.05,
                'WedgePart'
            )
            table.insert(fxData.TorsoParts, {
                Part = wing,
                Side = side,
                Tier = tier,
                FlapSpeed = 1.8,
                BaseOffset = CFrame.new(side * (0.72 + tier * 0.34), 0.72 - tier * 0.34, 0.78),
                BaseAngles = Vector3.new(-0.15, side * 0.25, -side * (0.55 + tier * 0.25)),
            })
        end
        local visor = makeAuraPart(folder, 'CyborgVisor', Vector3.new(0.92, 0.20, 0.28), magenta, Enum.PartType.Block, 0.05)
        table.insert(fxData.HeadParts, { Part = visor, Offset = CFrame.new(0, 0.08, -0.48) })

    elseif raceName == 'Ghoul' then
        -- Crimson-black Demon Horns & Bat Wing blades
        local crimson = Color3.fromRGB(235, 28, 68)
        local darkObsidian = Color3.fromRGB(24, 14, 28)
        for i = 1, 6 do
            local side = (i <= 3) and -1 or 1
            local tier = ((i - 1) % 3) + 1
            local batBlade = makeAuraPart(
                folder,
                'GhoulBatWing_' .. i,
                Vector3.new(0.18, 2.65 - tier * 0.28, 0.65),
                tier % 2 == 1 and crimson or darkObsidian,
                Enum.PartType.Block,
                0.06,
                'WedgePart'
            )
            table.insert(fxData.TorsoParts, {
                Part = batBlade,
                Side = side,
                Tier = tier,
                FlapSpeed = 4.2,
                BaseOffset = CFrame.new(side * (0.68 + tier * 0.32), 0.75 - tier * 0.32, 0.75),
                BaseAngles = Vector3.new(-0.22, side * 0.32, -side * (0.48 + tier * 0.28)),
            })
        end
        for _, side in ipairs({ -1, 1 }) do
            local horn = makeAuraPart(
                folder,
                'GhoulDemonHorn_' .. (side < 0 and 'L' or 'R'),
                Vector3.new(0.22, 1.25, 0.34),
                crimson,
                Enum.PartType.Block,
                0.05,
                'WedgePart'
            )
            table.insert(fxData.HeadParts, {
                Part = horn,
                Offset = CFrame.new(side * 0.46, 0.65, -0.10) * CFrame.Angles(-0.25, 0, -side * 0.35),
            })
        end

    elseif raceName == 'Draco' then
        -- Fiery gold-crimson Dragon Wings & Crown Horns
        local fireCrimson = Color3.fromRGB(255, 68, 42)
        local solarGold = Color3.fromRGB(255, 212, 68)
        for i = 1, 6 do
            local side = (i <= 3) and -1 or 1
            local tier = ((i - 1) % 3) + 1
            local dracoWing = makeAuraPart(
                folder,
                'DracoWingBlade_' .. i,
                Vector3.new(0.20, 3.05 - tier * 0.32, 0.72),
                tier % 2 == 1 and fireCrimson or solarGold,
                Enum.PartType.Block,
                0.05,
                'WedgePart'
            )
            table.insert(fxData.TorsoParts, {
                Part = dracoWing,
                Side = side,
                Tier = tier,
                FlapSpeed = 3.8,
                BaseOffset = CFrame.new(side * (0.72 + tier * 0.38), 0.85 - tier * 0.34, 0.82),
                BaseAngles = Vector3.new(-0.20, side * 0.32, -side * (0.46 + tier * 0.26)),
            })
        end
        for _, side in ipairs({ -1, 0, 1 }) do
            local horn = makeAuraPart(
                folder,
                'DracoCrownHorn_' .. tostring(side),
                Vector3.new(0.22, side == 0 and 1.45 or 1.25, 0.36),
                side == 0 and solarGold or fireCrimson,
                Enum.PartType.Block,
                0.04,
                'WedgePart'
            )
            table.insert(fxData.HeadParts, {
                Part = horn,
                Offset = CFrame.new(side * 0.45, 0.72, -0.14) * CFrame.Angles(-0.28, 0, -side * 0.32),
            })
        end
    end

    -- Attach true sculpted 3D V5 RaceV4WingsSet (Wave 18/19 Overhaul)
    local okWings, wingsTemplate = pcall(Renderer.Build, 'RaceV4WingsSet')
    if okWings and wingsTemplate then
        local wingsClone = wingsTemplate:Clone()
        wingsClone.Name = 'RaceV4WingsSet_3D'
        wingsClone:ScaleTo(1.35)
        for _, d in ipairs(wingsClone:GetDescendants()) do
            if d:IsA('WeldConstraint') then
                d:Destroy()
            elseif d:IsA('BasePart') then
                d.Anchored = true
                d.CanCollide = false
                d.CanQuery = false
                d.CanTouch = false
                d.Massless = true
            end
        end
        wingsClone.Parent = folder
        fxData.V5WingsModel = wingsClone
        fxData.V5WingsClips = getScaledClips('RaceV4WingsSet', 1.35)
    end

    s.RaceFX = fxData
end

local function stepRaceV4FX(s, now)
    local fx = s.RaceFX
    if not fx or not fx.Folder or not fx.Folder.Parent or not s.Root or not s.Root.Parent then
        return
    end
    local torsoCF = getBoneWorldCF(s, fx.TorsoBone, CFrame.new(0, 0.8, 0))
    local headCF = getBoneWorldCF(s, fx.HeadBone, CFrame.new(0, 2.3, 0))

    -- Step true sculpted 3D V5 RaceV4WingsSet rig
    if fx.V5WingsModel and fx.V5WingsModel.Parent then
        fx.V5WingsModel:PivotTo(torsoCF * CFrame.new(0, 0.25, 0.65))
        if fx.V5WingsClips then
            local wingClip = fx.V5WingsClips.UltimateAwakening or fx.V5WingsClips.HeroicKata or fx.V5WingsClips.Idle
            if wingClip then
                Renderer.Pose(fx.V5WingsModel, wingClip, now)
            end
        end
    end

    for _, item in ipairs(fx.TorsoParts) do
        local flap = math.sin(now * (item.FlapSpeed or 3.5) + item.Tier * 0.4) * 0.16
        local ang = item.BaseAngles
        local dynamicAngles = CFrame.Angles(ang.X + flap * 0.25, ang.Y + item.Side * flap, ang.Z - item.Side * flap * 0.35)
        item.Part.CFrame = torsoCF * item.BaseOffset * dynamicAngles
    end

    for _, item in ipairs(fx.HeadParts) do
        if item.IsHalo then
            local haloCenter = CFrame.new(headCF.Position + Vector3.new(0, 1.25, 0)) * CFrame.Angles(0, now * 1.8, 0)
            local ang = (item.Index - 1) * (2 * math.pi / item.Count)
            local p = haloCenter * CFrame.new(math.cos(ang) * item.Radius, 0, math.sin(ang) * item.Radius)
            item.Part.CFrame = CFrame.lookAt(p.Position, haloCenter.Position) * CFrame.Angles(0, math.pi * 0.5, 0)
        else
            item.Part.CFrame = headCF * item.Offset
        end
    end

    for _, item in ipairs(fx.FootParts) do
        local footCF = getBoneWorldCF(s, item.Bone, item.Fallback)
        item.Part.CFrame = CFrame.new(footCF.Position) * CFrame.Angles(0, now * (item.Layer == 1 and 8 or -8), math.pi * 0.5)
    end

    for _, item in ipairs(fx.OrbitParts) do
        local ang = now * 2.2 + (item.Index - 1) * (2 * math.pi / item.Count)
        local bob = math.sin(now * 3.0 + item.Index) * 0.35
        local pos = torsoCF.Position + Vector3.new(math.cos(ang) * item.Radius, bob, math.sin(ang) * item.Radius)
        item.Part.CFrame = CFrame.lookAt(pos, torsoCF.Position + Vector3.new(0, bob, 0))
    end
end


local function buildHeldFruitFX(s, fruitId)
    if not s or not s.Model or not s.Model.Parent then
        return
    end
    local old = s.Model:FindFirstChild('HeldFruit3D')
    if old then
        old:Destroy()
    end
    s.HeldFruitModel = nil
    s.HeldFruitClips = nil
    s.HeldFruitId = fruitId or ''
    if not fruitId or fruitId == '' then
        return
    end
    local assetName = fruitId:sub(1, 6) == 'Fruit_' and fruitId or ('Fruit_' .. fruitId)
    local ok, template = pcall(Renderer.Build, assetName)
    if not ok or not template then
        return
    end
    local clone = template:Clone()
    clone.Name = 'HeldFruit3D'
    clone:ScaleTo(0.85)
    for _, d in ipairs(clone:GetDescendants()) do
        if d:IsA('WeldConstraint') then
            d:Destroy()
        elseif d:IsA('BasePart') then
            d.Anchored = true
            d.CanCollide = false
            d.CanQuery = false
            d.CanTouch = false
            d.Massless = true
        end
    end
    clone.Parent = s.Model
    s.HeldFruitModel = clone
    s.HeldFruitClips = getScaledClips(assetName, 0.85)
    s.HeldFruitHandBone = findBone(s.Model, { 'Hand_R', 'RightHand', 'Arm_R', 'Weapon_R' })
end

local function stepHeldFruitFX(s, now)
    local m = s.HeldFruitModel
    if not m or not m.Parent or not s.Root or not s.Root.Parent then
        return
    end
    local handCF = getBoneWorldCF(s, s.HeldFruitHandBone, CFrame.new(1.35, 0.35, -0.85))
    local bob = math.sin(now * 3.2) * 0.12
    local spin = CFrame.Angles(0, now * 1.8, 0)
    m:PivotTo(CFrame.new(handCF.Position + Vector3.new(0, 0.45 + bob, 0)) * spin)
    if s.HeldFruitClips then
        local fClip = s.HeldFruitClips.ElementalSurge or s.HeldFruitClips.Idle
        if fClip then
            Renderer.Pose(m, fClip, now)
        end
    end
end

-- ============================================================================
-- 5. MAIN BOOTSTRAP & CHARACTER RIG / ANIMATION / VFX LOOP
-- ============================================================================

local animatedWorlds = {}
local worldGates3D = {}

local function registerAnimatedWorld(model, assetName, scale, originPos)
    return
end

local function build3DWorldGate(gateModel)
    if not gateModel or not gateModel:IsA('Model') or worldGates3D[gateModel] then
        return
    end
    local core = gateModel.PrimaryPart or gateModel:WaitForChild('GateCore', 5)
    if not core then
        return
    end
    local col = gateModel:GetAttribute('GlowColor') or Color3.fromRGB(95, 235, 255)
    local elem = tostring(gateModel:GetAttribute('Element') or 'Sky')
    local secCol = elem == 'Void' and Color3.fromRGB(255, 95, 210)
        or (elem == 'Frost' and Color3.fromRGB(165, 248, 255) or Color3.fromRGB(255, 238, 135))
    local darkStone = elem == 'Void' and Color3.fromRGB(28, 18, 42)
        or (elem == 'Frost' and Color3.fromRGB(24, 38, 56) or Color3.fromRGB(48, 42, 34))

    local oldVis = gateModel:FindFirstChild('WorldGate3DVisual')
    if oldVis then
        oldVis:Destroy()
    end
    local vis = Instance.new('Folder')
    vis.Name = 'WorldGate3DVisual'
    vis.Parent = gateModel

    local floorY = tonumber(gateModel:GetAttribute('FloorY')) or (core.Position.Y - 4.2)
    local center = Vector3.new(core.Position.X, floorY + 5.2, core.Position.Z)

    -- Base Dais Platform
    makeAuraPart(vis, 'GateBaseDais', Vector3.new(11.5, 0.55, 4.8), darkStone, Enum.PartType.Block, 0.0, 'Part', Enum.Material.Slate, 0.05).CFrame =
        CFrame.new(core.Position.X, floorY + 0.28, core.Position.Z)
    makeAuraPart(vis, 'GateBaseRuneStrip', Vector3.new(10.2, 0.62, 3.6), col, Enum.PartType.Block, 0.12, 'Part', Enum.Material.Neon, 0).CFrame =
        CFrame.new(core.Position.X, floorY + 0.30, core.Position.Z)

    -- Twin Flanking Obelisks + Levitating Apex Crystals
    local crystals = {}
    for _, side in ipairs({ -1, 1 }) do
        local ox = core.Position.X + side * 5.2
        local oz = core.Position.Z
        makeAuraPart(vis, 'ObeliskPillar_' .. side, Vector3.new(1.35, 7.6, 1.35), darkStone, Enum.PartType.Block, 0.0, 'Part', Enum.Material.Granite, 0.05).CFrame =
            CFrame.new(ox, floorY + 3.8, oz)
        makeAuraPart(vis, 'ObeliskVein_' .. side, Vector3.new(0.42, 7.2, 1.42), col, Enum.PartType.Block, 0.08, 'Part', Enum.Material.Neon, 0).CFrame =
            CFrame.new(ox, floorY + 3.8, oz)
        local crys = makeAuraPart(vis, 'ApexCrystal_' .. side, Vector3.new(1.05, 2.1, 1.05), secCol, Enum.PartType.Block, 0.05, 'Part', Enum.Material.Neon, 0.1)
        table.insert(crystals, { Part = crys, BasePos = Vector3.new(ox, floorY + 9.1, oz), Side = side })
    end

    -- 12-Segment Outer Stargate Ring + Runic Nodes
    local outerNodes = {}
    local outerCount = 12
    local outerRadius = 4.6
    local outerSegLen = 2 * outerRadius * math.sin(math.pi / outerCount) + 0.25
    for i = 1, outerCount do
        local seg = makeAuraPart(vis, 'OuterArchSeg_' .. i, Vector3.new(0.55, outerSegLen, 0.65), darkStone, Enum.PartType.Block, 0.0, 'Part', Enum.Material.Metal, 0.15)
        local rune = makeAuraPart(vis, 'OuterRuneCrystal_' .. i, Vector3.new(0.32, 0.75, 0.82), i % 2 == 0 and col or secCol, Enum.PartType.Block, 0.05, 'Part', Enum.Material.Neon, 0)
        table.insert(outerNodes, { Seg = seg, Rune = rune, Index = i, Count = outerCount, Radius = outerRadius })
    end

    -- 8-Segment Counter-Rotating Inner Vortex Ring
    local innerNodes = {}
    local innerCount = 8
    local innerRadius = 3.35
    local innerSegLen = 2 * innerRadius * math.sin(math.pi / innerCount) + 0.18
    for i = 1, innerCount do
        local seg = makeAuraPart(vis, 'InnerVortexRing_' .. i, Vector3.new(0.28, innerSegLen, 0.36), i % 2 == 0 and secCol or col, Enum.PartType.Block, 0.08, 'Part', Enum.Material.Neon, 0)
        table.insert(innerNodes, { Seg = seg, Index = i, Count = innerCount, Radius = innerRadius })
    end

    -- Swirling Event Horizon Vortex Disc
    local vortex = makeAuraPart(vis, 'EventHorizonVortex', Vector3.new(0.35, 6.4, 6.4), col, Enum.PartType.Cylinder, 0.28, 'Part', Enum.Material.ForceField, 0)
    vortex.CFrame = CFrame.new(center) * CFrame.Angles(0, math.pi * 0.5, 0)
    local innerGlow = makeAuraPart(vis, 'EventHorizonCore', Vector3.new(0.42, 4.2, 4.2), secCol, Enum.PartType.Cylinder, 0.38, 'Part', Enum.Material.Neon, 0)
    innerGlow.CFrame = vortex.CFrame

    local light = Instance.new('PointLight')
    light.Name = 'PortalGateLight'
    light.Color = col
    light.Brightness = 3.6
    light.Range = 36
    light.Parent = core

    local emitter = Instance.new('ParticleEmitter')
    emitter.Name = 'PortalVortexSparks'
    emitter.Color = ColorSequence.new(col, secCol)
    emitter.LightEmission = 1
    emitter.LightInfluence = 0
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.28),
        NumberSequenceKeypoint.new(0.7, 0.16),
        NumberSequenceKeypoint.new(1, 0),
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(1, 1),
    })
    emitter.Lifetime = NumberRange.new(0.6, 1.2)
    emitter.Rate = 28
    emitter.Speed = NumberRange.new(1.5, 4.2)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Parent = core

    worldGates3D[gateModel] = {
        Model = gateModel,
        Center = center,
        OuterNodes = outerNodes,
        InnerNodes = innerNodes,
        Crystals = crystals,
        Vortex = vortex,
        InnerGlow = innerGlow,
        Light = light,
    }
end

local function stepWorldGates3D(now, camPos)
    for gateModel, g in pairs(worldGates3D) do
        if not gateModel.Parent then
            worldGates3D[gateModel] = nil
            continue
        end
        if camPos and (g.Center - camPos).Magnitude > 480 then
            continue
        end
        local c = g.Center
        for _, n in ipairs(g.OuterNodes) do
            local ang = (n.Index / n.Count) * math.pi * 2 + now * 0.85
            local pos = c + Vector3.new(math.cos(ang) * n.Radius, math.sin(ang) * n.Radius, 0)
            local cf = CFrame.new(pos) * CFrame.Angles(0, 0, ang)
            if n.Seg and n.Seg.Parent then
                n.Seg.CFrame = cf
            end
            if n.Rune and n.Rune.Parent then
                n.Rune.CFrame = cf * CFrame.new(0.22, 0, 0)
            end
        end
        for _, n in ipairs(g.InnerNodes) do
            local ang = (n.Index / n.Count) * math.pi * 2 - now * 1.65
            local pos = c + Vector3.new(math.cos(ang) * n.Radius, math.sin(ang) * n.Radius, 0)
            if n.Seg and n.Seg.Parent then
                n.Seg.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, ang)
            end
        end
        for _, cr in ipairs(g.Crystals) do
            if cr.Part and cr.Part.Parent then
                local bob = math.sin(now * 2.6 + cr.Side) * 0.45
                cr.Part.CFrame = CFrame.new(cr.BasePos + Vector3.new(0, bob, 0)) * CFrame.Angles(0.25, now * 1.9 * cr.Side, 0.25)
            end
        end
        if g.InnerGlow and g.InnerGlow.Parent then
            local pulse = 4.0 + math.sin(now * 3.4) * 0.55
            g.InnerGlow.Size = Vector3.new(0.42, pulse, pulse)
        end
    end
end

local function boot()
    local worldsFolder = workspace:FindFirstChild('Worlds')
    if not (worldsFolder and worldsFolder:FindFirstChild('GoldenSky_3D')) then
        local map = Renderer.Build('GoldenSky', progress)
        map.Name = 'GoldenSky_ImportedArt'
        map.Parent = workspace
    end
    workspace:SetAttribute('Sea1IslandsReady', true)

    local sources = game.ReplicatedStorage.DelegatedV5Sources
    local strikerClips = enrichClips(Renderer.Clips('ThunderStriker', 2.6))
    local femaleClips = sources:FindFirstChild('ThunderStrikerFemale') and enrichClips(Renderer.Clips('ThunderStrikerFemale', 2.6)) or strikerClips
    clipScaleCache['ThunderStriker_2.60'] = strikerClips
    if sources:FindFirstChild('ThunderStrikerFemale') then
        clipScaleCache['ThunderStrikerFemale_2.60'] = femaleClips
    end

    local bossScale = 1.9
    local bossClips = Renderer.Clips('AureonSentinel', bossScale)
    local GuardianAnimator = require(script.Parent.GuardianAnimator)

    local grandIslandsFolder = workspace:FindFirstChild('GrandSkyIslands')
    if not grandIslandsFolder then
        grandIslandsFolder = Instance.new('Folder')
        grandIslandsFolder.Name = 'GrandSkyIslands'
        grandIslandsFolder.Parent = workspace
    end

    local DECK_OFFSET_Y = {
        ZiolesGachaShrine = 2.0,
        AetherShrinesAndRaidConsole = 1.0,
        WestGardenPirateBastion = 22.6,
        SunshardSkySanctuary = 20.5,
        CyberportCafeTradingHub = 24.0,
        PermafrostGarrisonFortress = 23.5,
        MicrochipAwakeningRaidLab = 19.5,
        GlacialWreckageDangerSea = 32.0,
        CastleOnTheVoidMansion = 27.5,
        UmbralCrystalSanctumForest = 16.5,
        TempleOfTheCoreRaceV4 = 28.5,
        MirageSkyIslandLeviathanAbyss = 23.5,
    }

    local function placeGrandIsland(entry)
        if not sources:FindFirstChild(entry.Asset) then
            return
        end
        local existing = grandIslandsFolder:FindFirstChild(entry.Asset .. '_ImportedArt')
        if existing then
            existing:Destroy()
        end
        local okIsl, islModel = pcall(Renderer.Build, entry.Asset)
        if okIsl and islModel then
            local placed = islModel:Clone()
            placed.Name = entry.Asset .. '_ImportedArt'
            placed:SetAttribute('IslandAsset', entry.Asset)
            placed:SetAttribute('Sea', entry.Sea)
            local deckOffY = DECK_OFFSET_Y[entry.Asset] or 0
            placed:SetAttribute('DeckSurfaceY', entry.Origin.Y)
            placed:PivotTo(CFrame.new(entry.Origin - Vector3.new(0, deckOffY, 0)))
            placed.Parent = grandIslandsFolder
        else
            warn('[SKYBREAK Island Build]', entry.Asset, islModel)
        end
    end

    local portal, portalClips, shadowPortal, shadowPortalClip
    -- Stream Sea 1, Sea 2 & Sea 3 Macro-Worlds + 5 Expansion Realms on demand by distance
    task.spawn(function()
        task.wait(1.2)
        local sea2And3Islands = {
            -- Sea 1 Islands (streamed when within 520 studs)
            { Asset = 'ZiolesGachaShrine', Origin = Vector3.new(-220, 38, 260), Sea = 1, StreamDist = 480 },
            { Asset = 'AetherShrinesAndRaidConsole', Origin = Vector3.new(60, 38, 260), Sea = 1, StreamDist = 480 },
            { Asset = 'WestGardenPirateBastion', Origin = Vector3.new(-520, 48, 40), Sea = 1, StreamDist = 460 },
            { Asset = 'SunshardSkySanctuary', Origin = Vector3.new(540, 88, -40), Sea = 1, StreamDist = 460 },
            -- Sea 2 3x Macro-Worlds (zero AABB overlap, GAP >= 180 studs)
            { Asset = 'CyberportCafeTradingHub', Origin = Vector3.new(2020, 46, 360), Sea = 2, StreamDist = 650 },
            { Asset = 'PermafrostGarrisonFortress', Origin = Vector3.new(1960, 56, -180), Sea = 2, StreamDist = 650 },
            { Asset = 'MicrochipAwakeningRaidLab', Origin = Vector3.new(3040, 68, 120), Sea = 2, StreamDist = 650 },
            { Asset = 'GlacialWreckageDangerSea', Origin = Vector3.new(2980, 44, -440), Sea = 2, StreamDist = 650 },
            -- Sea 3 3x Macro-Worlds (zero AABB overlap, GAP >= 180 studs)
            { Asset = 'CastleOnTheVoidMansion', Origin = Vector3.new(-3160, 56, 260), Sea = 3, StreamDist = 650 },
            { Asset = 'UmbralCrystalSanctumForest', Origin = Vector3.new(-1920, 60, 240), Sea = 3, StreamDist = 650 },
            { Asset = 'TempleOfTheCoreRaceV4', Origin = Vector3.new(-3160, 96, -320), Sea = 3, StreamDist = 650 },
            { Asset = 'MirageSkyIslandLeviathanAbyss', Origin = Vector3.new(-2540, 68, -680), Sea = 3, StreamDist = 650 },
        }
        local expansionRealms = {
            { Name = 'VerdantCrown', Asset = 'UmbralCrystalSanctumForest', Origin = Vector3.new(0, 120, -2400) },
            { Name = 'EmberforgeWastes', Asset = 'WestGardenPirateBastion', Origin = Vector3.new(2400, 120, -2400) },
            { Name = 'AbyssalTides', Asset = 'MirageSkyIslandLeviathanAbyss', Origin = Vector3.new(-2400, 120, -2400) },
            { Name = 'ChronosBastion', Asset = 'TempleOfTheCoreRaceV4', Origin = Vector3.new(0, 180, -4200) },
            { Name = 'VeilsEnd', Asset = 'CastleOnTheVoidMansion', Origin = Vector3.new(0, 260, -5800) },
        }
        workspace:SetAttribute('GrandSkyIslandsV8Ready', true)

        local builtSeaIsl = {}
        local builtExp = {}
        local builtFrozen = false
        local builtShadow = false
        local frozenOrigin = require(game.ReplicatedStorage.Shared.RealmConfig).FrozenCyber.Origin
        local shadowOrigin = require(game.ReplicatedStorage.Shared.RealmConfig).ShadowRealm.Origin

        while true do
            local cam = workspace.CurrentCamera
            local chRoot = player.Character and player.Character:FindFirstChild('HumanoidRootPart')
            local refPos = (chRoot and chRoot.Position) or (cam and cam.CFrame.Position) or Vector3.new(-92, 42, 152)
            for idx, entry in ipairs(sea2And3Islands) do
                local maxD = entry.StreamDist or 650
                if not builtSeaIsl[idx] and (entry.Origin - refPos).Magnitude <= maxD then
                    builtSeaIsl[idx] = true
                    placeGrandIsland(entry)
                    task.wait(0.15)
                end
            end
            for idx, exp in ipairs(expansionRealms) do
                if not builtExp[idx] and (exp.Origin - refPos).Magnitude <= 650 and sources:FindFirstChild(exp.Asset) then
                    builtExp[idx] = true
                    local okExp, baseModel = pcall(Renderer.Build, exp.Asset)
                    if okExp and baseModel then
                        local oldExp = grandIslandsFolder:FindFirstChild(exp.Name .. '_ImportedArt')
                        if oldExp then
                            oldExp:Destroy()
                        end
                        local expClone = baseModel:Clone()
                        expClone.Name = exp.Name .. '_ImportedArt'
                        expClone:SetAttribute('IslandAsset', exp.Asset)
                        expClone:SetAttribute('Realm', exp.Name)
                        local deckOffY = DECK_OFFSET_Y[exp.Asset] or 0
                        expClone:SetAttribute('DeckSurfaceY', exp.Origin.Y)
                        expClone:PivotTo(CFrame.new(exp.Origin - Vector3.new(0, deckOffY, 0)))
                        expClone.Parent = grandIslandsFolder
                    end
                    task.wait(0.15)
                end
            end
            if not builtFrozen and (frozenOrigin - refPos).Magnitude <= 750 and sources:FindFirstChild('FrozenCyber') then
                builtFrozen = true
                if not (worldsFolder and worldsFolder:FindFirstChild('FrozenCyber_3D')) then
                    local okF, frozen = pcall(Renderer.Build, 'FrozenCyber', progress)
                    if okF and frozen then
                        frozen.Name = 'FrozenCyber_ImportedArt'
                        frozen:PivotTo(CFrame.new(frozenOrigin))
                        frozen.Parent = workspace
                    end
                end
                local okP, builtP = pcall(Renderer.Build, 'FrozenPortal', progress)
                if okP and builtP then
                    portal = builtP
                    portal:PivotTo(CFrame.new(frozenOrigin))
                    portal.Name = 'FrozenCyber_AnimatedPortal'
                    portal.Parent = workspace
                    local okC, c = pcall(Renderer.Clips, 'FrozenPortal', 1)
                    if okC then portalClips = c end
                end
            end
            if not builtShadow and (shadowOrigin - refPos).Magnitude <= 750 and sources:FindFirstChild('ShadowRealm') then
                builtShadow = true
                if not (worldsFolder and worldsFolder:FindFirstChild('ShadowRealm_3D')) then
                    local okS, shadow = pcall(Renderer.Build, 'ShadowRealm', progress)
                    if okS and shadow then
                        shadow.Name = 'ShadowRealm_ImportedArt'
                        shadow:PivotTo(CFrame.new(shadowOrigin))
                        shadow.Parent = workspace
                    end
                end
                local okSP, builtSP = pcall(Renderer.Build, 'ShadowPortal', progress)
                if okSP and builtSP then
                    shadowPortal = builtSP
                    shadowPortal.Name = 'ShadowRealm_AnimatedGate'
                    shadowPortal:PivotTo(CFrame.new(shadowOrigin))
                    shadowPortal.Parent = workspace
                    local okGC, gateClips = pcall(Renderer.Clips, 'ShadowPortal', 1)
                    if okGC and type(gateClips) == 'table' then
                        local _, clip = next(gateClips)
                        shadowPortalClip = clip
                    end
                end
            end
            task.wait(0.25)
        end
    end)

    local function avatar(ch)
        avatarTickets[ch] = (avatarTickets[ch] or 0) + 1
        local ticket = avatarTickets[ch]
        local root = ch:WaitForChild('HumanoidRootPart', 10)
        local h = ch:WaitForChild('Humanoid', 10)
        if not root or not h then
            return
        end
        local deadline = os.clock() + 12
        while ch.Parent and not ch:GetAttribute('SkybreakCosmeticsReady') and os.clock() < deadline do
            task.wait(0.1)
        end
        local owner = Players:GetPlayerFromCharacter(ch)
        local gender = owner and owner:GetAttribute('SkybornGender') or 'Male'
        local class = owner and owner:GetAttribute('ClassId') or 'SkyGuardian'
        local stage = owner and owner:GetAttribute('OutfitStage') or 'Novice'
        local template
        if class == 'SkyGuardian' then
            local target = sources:FindFirstChild(gender .. '_' .. stage) and (gender .. '_' .. stage) or (gender .. '_SkyGuardian')
            assert(sources:FindFirstChild(target), 'Missing Guardian appearance ' .. target)
            template = Renderer.Build(target)
        elseif class == 'ArcaneMage' then
            template = Renderer.Build('ArcaneMage', progress)
        else
            local tsTarget = (gender == 'Female' and sources:FindFirstChild('ThunderStrikerFemale')) and 'ThunderStrikerFemale' or 'ThunderStriker'
            template = Renderer.Build(tsTarget, progress)
        end
        if ticket ~= avatarTickets[ch] or not ch.Parent then
            return
        end
        if states[ch] then
            states[ch].HideConnection:Disconnect()
            states[ch].Model:Destroy()
            states[ch] = nil
        end
        GuardianAnimator.Reset(ch)
        local old = ch:FindFirstChild('SkyGuardianVisual')
        if old then
            old.Name = 'LegacySkyGuardianVisual'
        end

        local visual = template:Clone()
        visual.Name = class == 'SkyGuardian' and 'SkyGuardianVisual'
            or (class == 'ArcaneMage' and 'ArcaneMageVisual' or 'ThunderStrikerVisual')
        visual:ScaleTo(2.6)
        local floor = root.Position.Y - h.HipHeight - root.Size.Y / 2
        visual:PivotTo(CFrame.new(root.Position.X, floor, root.Position.Z) * root.CFrame.Rotation)
        for _, o in visual:GetDescendants() do
            if o:IsA('BasePart') then
                o.Anchored = false
                o.Massless = true
            end
        end
        local weld = Instance.new('WeldConstraint')
        weld.Part0 = root
        weld.Part1 = visual.PrimaryPart
        weld.Parent = visual.PrimaryPart
        visual.Parent = ch

        -- Prevent Roblox's default R15 Animate/Animator from driving our custom Blender Bone hierarchy
        local animateScript = ch:FindFirstChild('Animate')
        if animateScript then
            animateScript.Enabled = false
            animateScript:Destroy()
        end
        for _, child in ipairs(h:GetChildren()) do
            if child:IsA('Animator') then
                child:Destroy()
            end
        end
        h.ChildAdded:Connect(function(child)
            if child:IsA('Animator') then
                task.defer(function()
                    if child.Parent then
                        child:Destroy()
                    end
                end)
            end
        end)
        ch.ChildAdded:Connect(function(child)
            if child.Name == 'Animate' and child:IsA('LocalScript') then
                child.Enabled = false
                task.defer(function()
                    if child.Parent then
                        child:Destroy()
                    end
                end)
            end
        end)

        local classClips
        local clipAssetName = nil
        if class == 'ArcaneMage' then
            clipAssetName = 'ArcaneMage'
            classClips = getScaledClips('ArcaneMage', 2.6)
        elseif class == 'ThunderStriker' then
            clipAssetName = (gender == 'Female' and sources:FindFirstChild('ThunderStrikerFemale')) and 'ThunderStrikerFemale' or 'ThunderStriker'
            classClips = gender == 'Female' and femaleClips or strikerClips
        elseif class == 'SkyGuardian' then
            local sgAsset = sources:FindFirstChild(gender .. '_' .. stage) and (gender .. '_' .. stage)
                or ((gender == 'Female' and sources:FindFirstChild('Female_SkyGuardian')) and 'Female_SkyGuardian' or 'Male_SkyGuardian')
            clipAssetName = sgAsset
            if sources[sgAsset]:FindFirstChild('Clips') then
                classClips = getScaledClips(sgAsset, 2.6)
            end
        end

        local stateEntry = {
            Model = visual,
            Visual = visual,
            Weld = weld,
            Root = root,
            H = h,
            Owner = owner,
            Character = ch,
            ClassId = class,
            ClipAssetName = clipAssetName,
            CurrentScale = 2.6,
            Name = class == 'ThunderStriker' and 'TS_Idle' or 'Idle',
            Start = os.clock(),
            Until = 0,
            Clips = classClips,
            PreviousHealth = h.Health,
            EnhanceLevel = 0,
            FruitTransform = '',
            HakiAura = false,
            RaceV4 = '',
        }

        local function equip()
            local equipped = not owner or owner:GetAttribute('WeaponEquipped') ~= false
            for _, part in visual:GetDescendants() do
                if part:IsA('BasePart') and part:GetAttribute('EquipmentRole') == 'Weapon' then
                    part.LocalTransparencyModifier = equipped and 0 or 1
                end
            end
            buildWeaponAwakeningAura(stateEntry)
        end
        equip()

        -- Initialize Beast Transformation, Busoshoku Haki & Race V4 if already active on character
        local initTransform = tostring(ch:GetAttribute('FruitTransform') or (owner and owner:GetAttribute('FruitTransform')) or '')
        if initTransform ~= '' then
            buildFruitTransformFX(stateEntry, initTransform)
        end
        local initHaki = (ch:GetAttribute('HakiAura') == true) or (owner and owner:GetAttribute('HakiAura') == true)
        if initHaki then
            buildHakiAuraFX(stateEntry, true)
        end
        local initRaceV4 = tostring(ch:GetAttribute('RaceV4') or (owner and owner:GetAttribute('RaceV4')) or '')
        if initRaceV4 ~= '' then
            buildRaceV4FX(stateEntry, initRaceV4)
        end

        local equipmentConnection = owner and owner:GetAttributeChangedSignal('WeaponEquipped'):Connect(equip)
        local enhanceConnection = owner and owner:GetAttributeChangedSignal('WeaponEnhance'):Connect(function()
            buildWeaponAwakeningAura(stateEntry)
        end)
        local chEnhanceConnection = ch:GetAttributeChangedSignal('WeaponEnhance'):Connect(function()
            buildWeaponAwakeningAura(stateEntry)
        end)
        local transformConnection = ch:GetAttributeChangedSignal('FruitTransform'):Connect(function()
            local tf = tostring(ch:GetAttribute('FruitTransform') or '')
            if tf ~= stateEntry.FruitTransform then
                buildFruitTransformFX(stateEntry, tf)
            end
        end)
        local hakiConnection = ch:GetAttributeChangedSignal('HakiAura'):Connect(function()
            local hk = ch:GetAttribute('HakiAura') == true
            if hk ~= stateEntry.HakiAura then
                buildHakiAuraFX(stateEntry, hk)
            end
        end)
        local raceConnection = ch:GetAttributeChangedSignal('RaceV4'):Connect(function()
            local rv = tostring(ch:GetAttribute('RaceV4') or '')
            if rv ~= stateEntry.RaceV4 then
                buildRaceV4FX(stateEntry, rv)
            end
        end)

        visual.Destroying:Once(function()
            if equipmentConnection then
                equipmentConnection:Disconnect()
            end
            if enhanceConnection then
                enhanceConnection:Disconnect()
            end
            if chEnhanceConnection then
                chEnhanceConnection:Disconnect()
            end
            if transformConnection then
                transformConnection:Disconnect()
            end
            if hakiConnection then
                hakiConnection:Disconnect()
            end
            if raceConnection then
                raceConnection:Disconnect()
            end
        end)

        ch:SetAttribute('BlenderGuardian', (class == 'SkyGuardian') and (not classClips or not next(classClips)))
        hideLegacy(ch, visual)
        local connection = ch.DescendantAdded:Connect(function(o)
            if o:IsA('BasePart') and not o:IsDescendantOf(visual) then
                o.Transparency = 1
            end
        end)
        stateEntry.HideConnection = connection
        states[ch] = stateEntry

        ch:SetAttribute('V5Visual', class)
        ch:SetAttribute('V5VisualReady', true)
        ch:SetAttribute('V7AppearanceKey', class .. '/' .. gender .. '/' .. stage)
    end

    local function bindPlayer(p)
        p.CharacterAdded:Connect(function(ch)
            task.spawn(avatar, ch)
        end)
        p:GetAttributeChangedSignal('SkybornGender'):Connect(function()
            if p.Character then
                task.spawn(avatar, p.Character)
            end
        end)
        p:GetAttributeChangedSignal('ClassId'):Connect(function()
            if p.Character then
                task.spawn(avatar, p.Character)
            end
        end)
        p:GetAttributeChangedSignal('OutfitStage'):Connect(function()
            if p.Character then
                task.spawn(avatar, p.Character)
            end
        end)
        if p.Character then
            task.spawn(avatar, p.Character)
        end
    end

    for _, p in Players:GetPlayers() do
        bindPlayer(p)
    end
    Players.PlayerAdded:Connect(bindPlayer)

    local remotes = game.ReplicatedStorage:WaitForChild('Remotes')
    local stateUpdate = remotes:FindFirstChild('StateUpdate')
    if stateUpdate then
        stateUpdate.OnClientEvent:Connect(function(payload)
            if payload and payload.State then
                local st = payload.State
                if st.WeaponEnhance ~= nil then
                    local newLv = tonumber(st.WeaponEnhance) or 0
                    if newLv ~= localEnhanceCache then
                        localEnhanceCache = newLv
                        player:SetAttribute('WeaponEnhance', newLv)
                        if player.Character and states[player.Character] then
                            buildWeaponAwakeningAura(states[player.Character])
                        end
                    end
                end
            end
        end)
    end

    local function boss(model)
        if model.Name ~= 'AureonSentinel' or bosses[model] then
            return
        end
        local body = model:WaitForChild('Body', 5)
        if not body then
            return
        end
        while model.Parent and body.Parent do
            local cam = workspace.CurrentCamera
            local refPos = cam and cam.CFrame.Position or Vector3.new(-92, 42, 152)
            if (body.Position - refPos).Magnitude <= 300 then
                break
            end
            task.wait(0.5)
        end
        if not model.Parent or not body.Parent or bosses[model] then
            return
        end
        local bossTemplate = Renderer.Build('AureonSentinel', progress)
        local _, bossSize = bossTemplate:GetBoundingBox()
        bossScale = 22 / math.max(1, bossSize.Y)
        bossClips = Renderer.Clips('AureonSentinel', bossScale)
        local visual = bossTemplate:Clone()
        visual.Name = 'AureonBlenderV5'
        visual:ScaleTo(bossScale)
        visual.Parent = model
        hideLegacy(model, visual)
        bosses[model] = { Model = visual, Root = body, Name = 'Idle', Start = os.clock(), Phase = 1, Event = 0 }
        model:SetAttribute('V5VisualReady', true)
    end


    task.spawn(function()
        local wpFolder = workspace:FindFirstChild('WorldPortals') or workspace:WaitForChild('WorldPortals', 12)
        if wpFolder then
            for _, gm in ipairs(wpFolder:GetChildren()) do
                task.spawn(build3DWorldGate, gm)
            end
            wpFolder.ChildAdded:Connect(function(gm)
                task.spawn(build3DWorldGate, gm)
            end)
        end
    end)

    local active = workspace:WaitForChild('ActiveBosses')
    active.ChildAdded:Connect(function(model)
        task.spawn(boss, model)
    end)
    for _, model in active:GetChildren() do
        task.spawn(boss, model)
    end

    local function handleCombatClip(fx)
        if type(fx) ~= 'table' then
            return
        end
        local p = nil
        if fx.Actor then
            p = Players:GetPlayerByUserId(fx.Actor)
        elseif fx.source then
            p = Players:FindFirstChild(tostring(fx.source))
        end
        local ch = p and p.Character
        local s = ch and states[ch]
        if not s then
            return
        end
        local action = tostring(fx.Action or fx.action or fx.skillId or '')
        local kind = tostring(fx.Kind or fx.kind or '')

        if s.ClassId == 'SkyGuardian' and (not s.Clips or not next(s.Clips)) then
            if action == 'Skill3' or action == 'JudgmentStrike' or action == 'ConquerorHaki' or fx.key == 'C' or fx.key == 'X' then
                GuardianAnimator.Action(ch, 'Heavy', fx.Combo)
            elseif action == 'Ultimate' or action == 'CelestialAegis' or fx.key == 'V' or fx.key == 'Z' or kind == 'Skill' then
                GuardianAnimator.Action(ch, 'SkySlash', fx.Combo)
            elseif kind == 'Swing' or action == 'Attack' or action == 'Heavy' then
                GuardianAnimator.Action(ch, action == 'Heavy' and 'Heavy' or 'Attack', fx.Combo)
            elseif kind == 'Dodge' or action == 'Dodge' or action == 'Dash' or fx.key == 'F' then
                GuardianAnimator.Action(ch, 'Dash', fx.Combo)
            end
            return
        end

        if not s.Clips or not next(s.Clips) then
            return
        end

        -- Wave 14-20 Universal 12-KF Canonical Awakening & Kata Clip Override
        if action == 'ElementalSurge' or action == 'HeroicKata' or action == 'UltimateAwakening' then
            local directClip = s.Clips[action]
            if directClip then
                s.Name = action
                s.Start = os.clock()
                s.Until = s.Start + math.max(0.65, directClip.Duration or 1.2)
                return
            end
        elseif (action == 'ConquerorHaki' or action == 'RaceV4Awaken' or action == 'BeastTransform') and s.Clips.UltimateAwakening then
            s.Name = 'UltimateAwakening'
            s.Start = os.clock()
            s.Until = s.Start + math.max(0.85, s.Clips.UltimateAwakening.Duration or 1.35)
            return
        end

        if s.ClassId == 'SkyGuardian' then
            local targetClip = nil
            if kind == 'Shield' or action == 'Skill2' or action == 'GuardianShield' then
                targetClip = s.Clips.ShieldRaise and 'ShieldRaise' or 'ShieldLoop'
            elseif kind == 'Dodge' or action == 'Dodge' or action == 'Dash' or fx.key == 'F' then
                targetClip = action == 'Dash' and 'Dash' or 'Dodge'
            elseif action == 'JudgmentStrike' or action == 'Skill3' or fx.key == 'C' or fx.key == 'X' then
                targetClip = s.Clips.JudgmentStrike and 'JudgmentStrike' or 'Heavy'
            elseif action == 'CelestialAegis' or action == 'Ultimate' or fx.key == 'V' then
                targetClip = s.Clips.CelestialAegis and 'CelestialAegis' or 'Ultimate'
            elseif action == 'ConquerorHaki' and s.Clips.HakiAwaken then
                targetClip = 'HakiAwaken'
            elseif action == 'Heavy' and s.Clips.Heavy then
                targetClip = 'Heavy'
            elseif kind == 'Swing' or kind == 'Skill' or action == 'Attack' or action == 'Skill1' or action == 'SkySlash' or fx.key == 'Z' then
                targetClip = s.Clips.SkySlash and 'SkySlash' or 'Attack'
            end
            if targetClip and s.Clips[targetClip] then
                s.Name = targetClip
                s.Start = os.clock()
                s.Until = s.Start + math.max(0.45, s.Clips[targetClip].Duration or 0.55)
            end
            return
        end

        if s.ClassId == 'ArcaneMage' then
            local targetClip = nil
            if kind == 'Shield' or action == 'Skill2' or action == 'ManaBarrier' then
                targetClip = 'ManaBarrier'
            elseif kind == 'Dodge' or action == 'Dodge' or action == 'Dash' or fx.key == 'F' then
                targetClip = action == 'Dash' and 'Dash' or 'Dodge'
            elseif action == 'Heavy' or action == 'Skill3' or action == 'ArcaneComet' or fx.key == 'C' or fx.key == 'X' then
                targetClip = s.Clips.ArcaneCircle and 'ArcaneCircle' or 'FrostNova'
            elseif action == 'Ultimate' or action == 'AstralCataclysm' or action == 'ConquerorHaki' or fx.key == 'V' then
                targetClip = 'FrostNova'
            elseif kind == 'Swing' or kind == 'Skill' or action == 'Attack' or action == 'Skill1' or action == 'FrostBolt' or fx.key == 'Z' then
                targetClip = 'FrostBolt'
            end
            if targetClip and s.Clips[targetClip] then
                s.Name = targetClip
                s.Start = os.clock()
                s.Until = s.Start + math.max(0.45, s.Clips[targetClip].Duration)
            end
            return
        end

        if s.ClassId == 'ThunderStriker' then
            local targetClip = nil
            if action == 'FlashStep' and s.Clips.FlashStep then
                targetClip = 'FlashStep'
            elseif (kind == 'Dodge' or action == 'Dodge') and s.Clips.Dodge then
                targetClip = 'Dodge'
            elseif kind == 'Dodge' or action == 'Dodge' or action == 'Dash' or action == 'Skill2' or action == 'FlashStep' or fx.key == 'F' then
                targetClip = s.Clips.TS_Dash and 'TS_Dash' or 'Dash'
            elseif (action == 'ArcCut' or action == 'Skill1' or fx.key == 'Z') and s.Clips.ArcCut then
                targetClip = 'ArcCut'
            elseif (action == 'StormBlitz' or action == 'Skill3' or fx.key == 'C' or fx.key == 'X') and s.Clips.StormBlitz then
                targetClip = 'StormBlitz'
            elseif (action == 'ThunderJudgement' or action == 'Ultimate' or fx.key == 'V') and s.Clips.ThunderJudgement then
                targetClip = 'ThunderJudgement'
            elseif action == 'ConquerorHaki' and s.Clips.HakiAwaken then
                targetClip = 'HakiAwaken'
            elseif action == 'Heavy' and s.Clips.Heavy then
                targetClip = 'Heavy'
            end
            if targetClip and s.Clips[targetClip] then
                s.Name = targetClip
                s.Start = os.clock()
                s.Until = s.Start + math.max(0.45, s.Clips[targetClip].Duration or 0.55)
            elseif kind == 'Swing'
                or kind == 'Skill'
                or action == 'Attack'
                or action == 'Heavy'
                or action == 'Skill1'
                or action == 'Skill3'
                or action == 'Ultimate'
                or action == 'ArcCut'
                or action == 'StormBlitz'
                or action == 'ThunderJudgement'
                or action == 'ConquerorHaki'
            then
                local fullCombo = (action == 'ArcCut' or action == 'StormBlitz' or action == 'ThunderJudgement' or action == 'Skill1' or action == 'Skill3' or action == 'Ultimate' or kind == 'Skill')
                local offset = action == 'Heavy' and 1.1 or ((math.clamp(fx.Combo or 1, 1, 3) - 1) * 0.55)
                s.Name = s.Clips.TS_DaggerCombo and 'TS_DaggerCombo' or 'DaggerCombo'
                s.Start = os.clock() - (fullCombo and 0 or offset)
                s.Until = os.clock() + (fullCombo and 1.8 or 0.60)
            end
        end
    end

    remotes.CombatFX.OnClientEvent:Connect(handleCombatClip)
    local combatEvent = remotes:FindFirstChild('CombatEvent')
    if combatEvent and combatEvent:IsA('RemoteEvent') then
        combatEvent.OnClientEvent:Connect(handleCombatClip)
    end

    Run.RenderStepped:Connect(function(dt)
        dt = math.clamp(dt or (1 / 60), 1 / 240, 0.15)
        local now = os.clock()
        local cam = workspace.CurrentCamera
        local camPos = cam and cam.CFrame.Position or nil

        if portal and portalClips then
            local pClip = portalClips.PortalSurge or portalClips.WorldIdle_Loop or portalClips.FC_PortalIdle_Loop_4s_Export or portalClips.FC_PortalIdle_Loop_4s
            if pClip then
                Renderer.Pose(portal, pClip, now)
            end
        end
        if shadowPortal and shadowPortalClip then
            Renderer.Pose(shadowPortal, shadowPortalClip, now)
        end

        -- Step all 20 Animated 3D Worlds, Grand Sky Islands, Shrines & Expansion Realms (Wave 19 10-Bone World Rigs)
        for _, w in ipairs(animatedWorlds) do
            if w.Model and w.Model.Parent and w.Clip then
                local dist = camPos and (w.Origin - camPos).Magnitude or 0
                if dist <= 1100 then
                    if dist <= 380 or now >= (w.NextStep or 0) then
                        w.NextStep = now + 0.04
                        local activeWorldClip = w.Clip
                        if w.Clips and w.Model:GetAttribute('WorldSurgeActive') then
                            activeWorldClip = w.Clips.CataclysmAwakening or w.Clips.PortalSurge or w.Clip
                        end
                        Renderer.Pose(w.Model, activeWorldClip, now + w.Phase)
                    end
                end
            end
        end

        -- Step all 22 End-of-World 3D Stargate Portals (WorldGate_01..WorldGate_20 + Realm Portals)
        stepWorldGates3D(now, camPos)

        for ch, s in states do
            if not ch.Parent or not s.Model.Parent then
                s.HideConnection:Disconnect()
                states[ch] = nil
                avatarTickets[ch] = nil
                continue
            end

            if s.H then
                local animInst = s.H:FindFirstChildOfClass('Animator')
                if animInst then
                    for _, tr in ipairs(s.H:GetPlayingAnimationTracks()) do
                        pcall(function() tr:Stop(0) end)
                    end
                    animInst:Destroy()
                end
            end
            local animScript = ch:FindFirstChild('Animate')
            if animScript and animScript:IsA('BaseScript') then
                animScript.Disabled = true
                animScript:Destroy()
            end

            if s.Clips and next(s.Clips) then
                -- 5. Monitor Blox Fruits Air-Jump / Geppo (DoubleJump)
                local lastAirJump = tonumber(ch:GetAttribute('LastAirJumpAt')) or 0
                if lastAirJump > (s.LastAirJumpAt or 0) then
                    s.LastAirJumpAt = lastAirJump
                    local djClip = (s.ClassId == 'ThunderStriker' and (s.Clips.TS_DoubleJump and 'TS_DoubleJump' or (s.Clips.DoubleJump and 'DoubleJump' or 'TS_Jump')))
                        or (s.Clips.DoubleJump and 'DoubleJump' or 'Jump')
                    if s.Clips[djClip] then
                        s.Name = djClip
                        s.Start = now
                        s.Until = now + math.max(0.42, s.Clips[djClip].Duration or 0.5)
                    end
                end

                local mode = s.H:GetState()
                local vel = s.Root.AssemblyLinearVelocity
                local hSpeed = math.max(Vector3.new(vel.X, 0, vel.Z).Magnitude, s.H.MoveDirection.Magnitude * s.H.WalkSpeed)
                local airborne = (mode == Enum.HumanoidStateType.Jumping or mode == Enum.HumanoidStateType.Freefall)

                local desired
                if s.ClassId == 'ThunderStriker' then
                    if s.H.Health <= 0 and s.Clips.Death then
                        if s.Name ~= 'Death' then
                            s.Name = 'Death'
                            s.Start = now
                            s.Until = math.huge
                        end
                        desired = 'Death'
                    elseif s.H.Health < s.PreviousHealth and s.Clips.HitReact then
                        s.Name = 'HitReact'
                        s.Start = now
                        s.Until = now + s.Clips.HitReact.Duration
                        desired = 'HitReact'
                    elseif mode == Enum.HumanoidStateType.Freefall and s.Clips.FallLoop then
                        desired = 'FallLoop'
                    elseif airborne then
                        desired = s.Clips.TS_Jump and 'TS_Jump' or 'Jump'
                    elseif hSpeed > 1.2 or s.H.MoveDirection.Magnitude > 0.1 then
                        desired = s.Clips.TS_Run and 'TS_Run' or 'Run'
                    else
                        desired = s.Clips.TS_Idle and 'TS_Idle' or 'Idle'
                    end
                    s.PreviousHealth = s.H.Health
                else
                    if s.H.Health <= 0 then
                        if s.Name ~= 'Death' then
                            s.Name = 'Death'
                            s.Start = now
                            s.Until = math.huge
                        end
                        desired = 'Death'
                    elseif s.H.Health < s.PreviousHealth and s.Clips.HitReact then
                        s.Name = 'HitReact'
                        s.Start = now
                        s.Until = now + s.Clips.HitReact.Duration
                        desired = 'HitReact'
                    elseif mode == Enum.HumanoidStateType.Jumping then
                        desired = 'Jump'
                    elseif mode == Enum.HumanoidStateType.Freefall then
                        desired = s.Clips.FallLoop and 'FallLoop' or 'Jump'
                    elseif s.H.MoveDirection.Magnitude > 0.45 or hSpeed > 6.5 then
                        desired = 'Run'
                    elseif s.H.MoveDirection.Magnitude > 0.05 or hSpeed > 1.5 then
                        desired = (s.H.MoveDirection.Magnitude > 0 and s.H.MoveDirection.Magnitude <= 0.45 and s.Clips.Walk) and 'Walk' or 'Run'
                    else
                        desired = 'Idle'
                    end
                    s.PreviousHealth = s.H.Health
                end

                if now >= s.Until and desired and desired ~= s.Name then
                    s.Name = desired
                    s.Start = now
                end
                local activeClip = s.Clips[s.Name] or s.Clips[ s.Name:gsub('^TS_', '') ] or s.Clips.Idle
                Renderer.Pose(s.Model, activeClip, now - s.Start)
                ch:SetAttribute('V5CurrentClip', s.Name:gsub('^TS_', ''))
            end

            -- 1. Monitor Weapon Awakening Aura (+1..+15) & Equipped Mythic Sword/Gun
            local currentEnhance = tonumber(s.Owner and s.Owner:GetAttribute('WeaponEnhance'))
                or tonumber(ch:GetAttribute('WeaponEnhance'))
                or (s.Owner == player and localEnhanceCache or 0)
                or 0
            local currentSword = tostring(ch:GetAttribute('EquippedSword') or (s.Owner and s.Owner:GetAttribute('EquippedSword')) or '')
            local currentGun = tostring(ch:GetAttribute('EquippedGun') or (s.Owner and s.Owner:GetAttribute('EquippedGun')) or '')
            if currentEnhance ~= s.EnhanceLevel or currentSword ~= (s.EquippedSword or '') or currentGun ~= (s.EquippedGun or '') then
                buildWeaponAwakeningAura(s)
            end
            stepWeaponAwakeningAura(s, now)

            -- 2. Monitor Beast Fruit Transformations (SolarTitan / AbyssalSovereign)
            local currentTransform = tostring(ch:GetAttribute('FruitTransform') or (s.Owner and s.Owner:GetAttribute('FruitTransform')) or '')
            if currentTransform ~= s.FruitTransform then
                buildFruitTransformFX(s, currentTransform)
            end
            stepFruitTransformFX(s, now)

            -- 3. Monitor Full-Body Busoshoku Haki Aura ([J])
            local currentHaki = (ch:GetAttribute('HakiAura') == true) or (s.Owner and s.Owner:GetAttribute('HakiAura') == true)
            if currentHaki ~= s.HakiAura then
                buildHakiAuraFX(s, currentHaki)
            end
            stepHakiAuraFX(s, now)

            -- 4. Monitor Race V4 3D Wings & Cosmetics ([Y])
            local currentRaceV4 = tostring(ch:GetAttribute('RaceV4') or (s.Owner and s.Owner:GetAttribute('RaceV4')) or '')
            if currentRaceV4 ~= s.RaceV4 then
                buildRaceV4FX(s, currentRaceV4)
            end
            stepRaceV4FX(s, now)

            -- 4b. Monitor Separated 3D Devil Fruit Held in Right Hand
            local currentHeldFruit = tostring(ch:GetAttribute('HeldFruit') or (s.Owner and s.Owner:GetAttribute('HeldFruit')) or '')
            if currentHeldFruit ~= (s.HeldFruitId or '') then
                buildHeldFruitFX(s, currentHeldFruit)
            end
            stepHeldFruitFX(s, now)
        end
        for owner, s in bosses do
            if not owner.Parent then
                s.Model:Destroy()
                bosses[owner] = nil
                continue
            end
            local event = owner:GetAttribute('V5SwingAt') or owner:GetAttribute('EnemyAttackAt') or 0
            local phase = owner:GetAttribute('BossPhase') or 1
            if event ~= s.Event then
                s.Event = event
                local reqClip = tostring(owner:GetAttribute('EnemyAttackClip') or '')
                if reqClip ~= '' and bossClips[reqClip] then
                    s.Name = reqClip
                else
                    s.Name = bossClips.DivineSlash and 'DivineSlash' or (bossClips.HeroicKata and 'HeroicKata' or 'Attack')
                end
                s.Start = now
            elseif phase ~= s.Phase then
                s.Phase = phase
                s.Name = bossClips.UltimateAwakening and 'UltimateAwakening' or (bossClips.Ascend and 'Ascend' or 'Heavy')
                s.Start = now
            else
                local curBossClip = bossClips[s.Name] or bossClips.Idle
                if curBossClip and (now - s.Start >= (curBossClip.Duration or 1.5)) then
                    s.Name = 'Idle'
                    s.Start = now
                end
            end
            local targetPos = s.Root.Position - Vector3.new(0, 6, 0)
            local targetRot = s.Root.CFrame.Rotation
            if not s.SmoothPos or (targetPos - s.SmoothPos).Magnitude > 24 then
                s.SmoothPos = targetPos
                s.SmoothRot = targetRot
            else
                local alpha = 1 - math.exp(-16 * dt)
                s.SmoothPos = s.SmoothPos:Lerp(targetPos, alpha)
                s.SmoothRot = s.SmoothRot:Lerp(targetRot, alpha)
            end
            s.Model:PivotTo(CFrame.new(s.SmoothPos) * s.SmoothRot)
            local activeBossClip = bossClips[s.Name] or bossClips.Idle
            if activeBossClip then
                Renderer.Pose(s.Model, activeBossClip, now - s.Start)
            end
        end
    end)

    workspace:SetAttribute('DelegatedV5Ready', true)
    print('[SKYBREAK] V12 GoldenSky / Beast Transformations / Busoshoku Haki / Race V4 Wings ready')
end

local ok, err = xpcall(boot, debug.traceback)
if not ok then
    warn('[SKYBREAK V5]', err)
    workspace:SetAttribute('DelegatedV5Error', tostring(err))
end
