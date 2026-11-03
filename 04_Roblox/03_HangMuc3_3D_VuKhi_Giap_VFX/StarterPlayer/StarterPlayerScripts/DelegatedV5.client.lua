local Players = game:GetService('Players')
local Run = game:GetService('RunService')
local Renderer = require(game.ReplicatedStorage:WaitForChild('DelegatedV5Renderer'))
local Equipment3D = require(game.ReplicatedStorage:WaitForChild('Shared'):WaitForChild('Skybreak3DEquipment'))
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

local LEGACY_SERVER_PLACEHOLDERS = {
    HumanoidRootPart = true,
    SkybornBlade = true,
    GuardianBreastplate = true,
    GuardianCrest = true,
    CrimsonCape = true,
}

local FX_MANAGED_CONTAINERS = {
    WeaponAwakeningAura = true,
    FruitTransformFX = true,
    HakiAuraFX = true,
    RaceV4FX = true,
    RaceV4WingsFX = true,
    HeldFruit3D = true,
    EquippedWeapons3D = true,
    CharacterAccessories3D = true,
    SkyGuardianVisual = true,
    ArcaneMageVisual = true,
    ThunderStrikerVisual = true,
    LegacySkyGuardianVisual = true,
}

local function isInsideManagedFXContainer(inst, ch)
    local p = inst and inst.Parent
    while p and p ~= ch do
        if FX_MANAGED_CONTAINERS[p.Name] then
            return true
        end
        p = p.Parent
    end
    return false
end

local function restoreNativeAvatarVisibility(ch, allowFallbackFace)
    if not ch or not ch.Parent then
        return
    end
    for _, oldVisName in ipairs({ 'SkyGuardianVisual', 'ArcaneMageVisual', 'ThunderStrikerVisual', 'LegacySkyGuardianVisual', 'CharacterAccessories3D' }) do
        local oldVis = ch:FindFirstChild(oldVisName)
        if oldVis then
            oldVis:Destroy()
        end
    end
    for _, o in ipairs(ch:GetDescendants()) do
        if not isInsideManagedFXContainer(o, ch) then
            if o:IsA('BasePart') then
                if LEGACY_SERVER_PLACEHOLDERS[o.Name] or o:GetAttribute('EquipmentRole') == 'Weapon' then
                    if o.Transparency ~= 1 then
                        o.Transparency = 1
                    end
                    if o.LocalTransparencyModifier ~= 1 then
                        o.LocalTransparencyModifier = 1
                    end
                else
                    if o.Transparency ~= 0 then
                        o.Transparency = 0
                    end
                    if o.LocalTransparencyModifier ~= 0 then
                        o.LocalTransparencyModifier = 0
                    end
                end
            elseif o:IsA('Decal') or o:IsA('Texture') then
                if o.Transparency ~= 0 then
                    o.Transparency = 0
                end
            end
        end
    end
    local headPart = ch:FindFirstChild('Head')
    if headPart and headPart:IsA('BasePart') then
        local fallbackFace = headPart:FindFirstChild('SkybreakFallbackFace')
        local hasRealFace = false
        for _, child in ipairs(headPart:GetChildren()) do
            if (child:IsA('Decal') and child.Name ~= 'SkybreakFallbackFace' and child.Texture ~= '')
                or child:IsA('SurfaceAppearance') then
                hasRealFace = true
                break
            end
        end
        if hasRealFace then
            if fallbackFace then
                fallbackFace:Destroy()
            end
        elseif allowFallbackFace and not fallbackFace then
            local faceDecal = Instance.new('Decal')
            faceDecal.Name = 'SkybreakFallbackFace'
            faceDecal.Face = Enum.NormalId.Front
            faceDecal.Texture = 'rbxasset://textures/face.png'
            faceDecal.Transparency = 0
            faceDecal.Parent = headPart
        end
    end
end

local function setCharacterBaseVisibilityForBeast(s, hidden)
    if not s or not s.Visual or not s.Visual.Parent then
        return
    end
    local lowFX = Equipment3D.IsLowFX(s.Owner)
    if hidden then
        if s.IsNativeAvatar then
            for _, o in ipairs(s.Visual:GetDescendants()) do
                if not isInsideManagedFXContainer(o, s.Visual) then
                    if o:IsA('BasePart') then
                        o.LocalTransparencyModifier = 1
                    elseif o:IsA('Decal') then
                        o.Transparency = 1
                    end
                end
            end
        else
            for _, chPart in ipairs(s.Visual:GetChildren()) do
                if chPart:IsA('BasePart') then
                    chPart.LocalTransparencyModifier = 1
                end
            end
        end
        for _, chPart in ipairs(s.Visual:GetChildren()) do
            if chPart:IsA('Folder') and (chPart.Name == 'RaceV4FX' or chPart.Name == 'RaceV4WingsFX' or chPart.Name == 'CharacterAccessories3D') then
                for _, sub in ipairs(chPart:GetDescendants()) do
                    if sub:IsA('BasePart') and sub.LocalTransparencyModifier < 1 then
                        sub.LocalTransparencyModifier = 1
                    elseif (sub:IsA('Trail') or sub:IsA('PointLight')) and sub.Enabled then
                        sub.Enabled = false
                    end
                end
            end
        end
    else
        if s.IsNativeAvatar then
            restoreNativeAvatarVisibility(s.Visual)
        else
            for _, chPart in ipairs(s.Visual:GetChildren()) do
                if chPart:IsA('BasePart') then
                    if chPart:GetAttribute('EquipmentRole') == 'Weapon' then
                        chPart.LocalTransparencyModifier = 1
                        chPart.Transparency = 1
                    else
                        chPart.LocalTransparencyModifier = 0
                    end
                end
            end
        end
        for _, chPart in ipairs(s.Visual:GetChildren()) do
            if chPart:IsA('Folder') and (chPart.Name == 'RaceV4FX' or chPart.Name == 'RaceV4WingsFX' or chPart.Name == 'CharacterAccessories3D') then
                for _, sub in ipairs(chPart:GetDescendants()) do
                    if sub:IsA('BasePart') then
                        sub.LocalTransparencyModifier = 0
                    elseif sub:IsA('Trail') or sub:IsA('PointLight') then
                        sub.Enabled = not lowFX
                    end
                end
            end
        end
    end
end

local function findBone(visual, names)
    return Equipment3D.FindBone(visual, names)
end

local function getBoneWorldCF(s, bone, fallbackOffset)
    return Equipment3D.GetBoneWorldCF(s, bone, fallbackOffset)
end

local function setVisualScale(s, targetScale)
    if not s or not s.Visual or not s.Visual.Parent or not s.Root or not s.Root.Parent then
        return
    end
    if s.IsNativeAvatar then
        s.CurrentScale = 2.6
        return
    end
    if math.abs((s.CurrentScale or 2.6) - targetScale) < 0.01 then
        return
    end

    local savedFolders = {}
    for _, folderName in ipairs({ 'WeaponAwakeningAura', 'FruitTransformFX', 'HakiAuraFX', 'RaceV4FX', 'HeldFruit3D', 'EquippedWeapons3D', 'CharacterAccessories3D' }) do
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
    s._EquipBindReady = nil
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
    if s.IsNativeAvatar then
        return
    end

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

    local MYTHIC_WEAPONS = {
        cursed_dual_skyblades = true,
        CursedDualSkyblades = true,
        noxar_abyssal_greatsword = true,
        noxar_greatsword = true,
        abyssal_greatsword = true,
        ArchitectsSeverance = true,
        yamo_voidblade = true,
        dawnbringer_sword = true,
        Dawnbringer = true,
        saber_of_aureon = true,
        cryon_frostblade = true,
        EternalFrost = true,
        astral_staff = true,
        stormfang_daggers = true,
        Stormfang = true,
        soul_guitar_void = true,
        cryo_railgun = true,
    }
    local hasMythicWeapon = (MYTHIC_WEAPONS[swordId] == true or MYTHIC_WEAPONS[gunId] == true)
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
    local ticket = (s._TransformTicket or 0) + 1
    s._TransformTicket = ticket
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
        emitter.LightEmission = 0.72
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

        s.TransformFX = fxData

        -- Attach true sculpted 3D V5 SolarTitanBuddha form asynchronously so RenderStepped never yields
        task.spawn(function()
            local okTitan, titanTemplate = pcall(Renderer.Build, 'SolarTitanBuddha')
            if s._TransformTicket ~= ticket or s.TransformFX ~= fxData or not folder.Parent or not s.Root or not s.Root.Parent then
                return
            end
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
                setCharacterBaseVisibilityForBeast(s, true)
            else
                fxData.ChestCore = makeAuraPart(folder, 'SolarTitanChestCore', Vector3.new(1.15, 1.15, 0.45), sunWhite, Enum.PartType.Ball, 0.02)
                fxData.TabardFront = makeAuraPart(folder, 'SolarTitanTabard', Vector3.new(1.85, 2.85, 0.24), Color3.fromRGB(36, 92, 215), Enum.PartType.Block, 0.08, 'Part', Enum.Material.SmoothPlastic, 0.15)
                fxData.TabardTrim = makeAuraPart(folder, 'SolarTitanTabardTrim', Vector3.new(2.05, 0.36, 0.30), solarGold, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.34)
            end
        end)

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
        fireEmitter.LightEmission = 0.72
        fireEmitter.LightInfluence = 0.15
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

        s.TransformFX = fxData

        -- Attach true sculpted 3D V5 AbyssalSovereignDragon / AbyssalDragonHybrid form asynchronously so RenderStepped never yields
        local v5DragonAsset = mode == 'AbyssalDragonHybrid' and 'AbyssalDragonHybrid' or 'AbyssalSovereignDragon'
        local v5DragonScale = mode == 'AbyssalDragonHybrid' and 3.2 or 3.4
        task.spawn(function()
            local okDragon, dragonTemplate = pcall(Renderer.Build, v5DragonAsset)
            if s._TransformTicket ~= ticket or s.TransformFX ~= fxData or not folder.Parent or not s.Root or not s.Root.Parent then
                return
            end
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
                local introClip = fxData.V5Clips and (fxData.V5Clips.FruitV or fxData.V5Clips.Ascend)
                fxData.IntroStart = os.clock()
                fxData.IntroUntil = fxData.IntroStart + math.min(1.85, (introClip and introClip.Duration) or 1.35)

                -- Bind live 3D Dragon bones for Maw Breath Embers, Crown Halo Motes & Dynamic Wing/Tail Plasma Trails
                fxData.TorsoBone = findBone(dragonClone, { 'Spine_03', 'Spine_02', 'Spine_01', 'UpperTorso', 'FX_Vortex' }) or fxData.TorsoBone
                fxData.DragonMawBone = findBone(dragonClone, { 'FX_BreathCore', 'Jaw', 'Head' })
                fxData.DragonCrownBone = findBone(dragonClone, { 'FX_CrownHalo', 'Head' })
                fxData.DragonWingLBone = findBone(dragonClone, { 'WingForearm_L', 'Wing_L_03', 'Wing_L_02', 'Wing_L_01', 'Wing_L', 'DragonWing_L_02', 'DragonWing_L_01' })
                fxData.DragonWingRBone = findBone(dragonClone, { 'WingForearm_R', 'Wing_R_03', 'Wing_R_02', 'Wing_R_01', 'Wing_R', 'DragonWing_R_02', 'DragonWing_R_01' })
                fxData.DragonTailBone = findBone(dragonClone, { 'Spine_12', 'Spine_10', 'Tail_04', 'Tail_03', 'DragonTail_04' })

                local mawAnchor = makeAuraPart(folder, 'AbyssalMawAnchor', Vector3.new(0.3, 0.3, 0.3), dragonCrimson, Enum.PartType.Ball, 1)
                local mawLight = Instance.new('PointLight')
                mawLight.Name = 'AbyssalMawLight'
                mawLight.Color = dragonCrimson
                mawLight.Brightness = 0.55
                mawLight.Range = 11
                mawLight.Shadows = false
                mawLight.Parent = mawAnchor
                local mawEmbers = Instance.new('ParticleEmitter')
                mawEmbers.Name = 'AbyssalMawBreathEmbers'
                mawEmbers.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 216, 248)),
                    ColorSequenceKeypoint.new(0.45, dragonCrimson),
                    ColorSequenceKeypoint.new(1, obsidian),
                })
                mawEmbers.LightEmission = 0.72
                mawEmbers.LightInfluence = 0.15
                mawEmbers.Size = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.42),
                    NumberSequenceKeypoint.new(0.6, 0.22),
                    NumberSequenceKeypoint.new(1, 0),
                })
                mawEmbers.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.12),
                    NumberSequenceKeypoint.new(1, 1),
                })
                mawEmbers.Lifetime = NumberRange.new(0.28, 0.55)
                mawEmbers.Rate = 14
                mawEmbers.Speed = NumberRange.new(2.0, 5.5)
                mawEmbers.SpreadAngle = Vector2.new(95, 95)
                mawEmbers.Drag = 2.8
                mawEmbers.Parent = mawAnchor
                fxData.MawAnchor = mawAnchor
                fxData.MawLight = mawLight
                fxData.MawEmbers = mawEmbers

                local crownAnchor = makeAuraPart(folder, 'AbyssalCrownAnchor', Vector3.new(0.3, 0.3, 0.3), voidPurple, Enum.PartType.Ball, 1)
                local crownMotes = Instance.new('ParticleEmitter')
                crownMotes.Name = 'AbyssalCrownMotes'
                crownMotes.Color = ColorSequence.new(dragonCrimson, voidPurple)
                crownMotes.LightEmission = 0.70
                crownMotes.LightInfluence = 0.15
                crownMotes.Size = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.30),
                    NumberSequenceKeypoint.new(1, 0),
                })
                crownMotes.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.16),
                    NumberSequenceKeypoint.new(1, 1),
                })
                crownMotes.Lifetime = NumberRange.new(0.45, 0.85)
                crownMotes.Rate = 10
                crownMotes.Speed = NumberRange.new(1.2, 3.2)
                crownMotes.SpreadAngle = Vector2.new(180, 180)
                crownMotes.Parent = crownAnchor
                fxData.CrownAnchor = crownAnchor

                local function makeDragonBoneTrail(anchorName, width, c1, c2)
                    local host = makeAuraPart(folder, anchorName, Vector3.new(0.25, 0.25, 0.25), c1, Enum.PartType.Ball, 1)
                    local a0 = Instance.new('Attachment')
                    a0.Position = Vector3.new(0, width * 0.5, 0)
                    a0.Parent = host
                    local a1 = Instance.new('Attachment')
                    a1.Position = Vector3.new(0, -width * 0.5, 0)
                    a1.Parent = host
                    local tr = Instance.new('Trail')
                    tr.Attachment0 = a0
                    tr.Attachment1 = a1
                    tr.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, c1),
                        ColorSequenceKeypoint.new(0.55, c2),
                        ColorSequenceKeypoint.new(1, obsidian),
                    })
                    tr.Transparency = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 0.14),
                        NumberSequenceKeypoint.new(0.65, 0.45),
                        NumberSequenceKeypoint.new(1, 1),
                    })
                    tr.WidthScale = NumberSequence.new({
                        NumberSequenceKeypoint.new(0, 1),
                        NumberSequenceKeypoint.new(1, 0),
                    })
                    tr.LightEmission = 0.72
                    tr.LightInfluence = 0.15
                    tr.FaceCamera = true
                    tr.Lifetime = 0.26
                    tr.MinLength = 0.08
                    tr.Enabled = false
                    tr.Parent = host
                    return host, tr
                end

                local trailW = (mode == 'AbyssalDragonHybrid') and 1.15 or 1.85
                fxData.WingLHost, fxData.WingLTrail = makeDragonBoneTrail('AbyssalWingTrailL', trailW, dragonCrimson, voidPurple)
                fxData.WingRHost, fxData.WingRTrail = makeDragonBoneTrail('AbyssalWingTrailR', trailW, dragonCrimson, voidPurple)
                fxData.TailHost, fxData.TailTrail = makeDragonBoneTrail('AbyssalTailTrail', trailW * 0.75, voidPurple, dragonCrimson)

                setCharacterBaseVisibilityForBeast(s, true)
            else
                -- Fallback 3 Orbiting Abyssal Flame Orbs only when 3D V5 model is unavailable
                for i = 1, 3 do
                    local orb = makeAuraPart(folder, 'AbyssalDragonOrb_' .. i, Vector3.new(0.62, 0.62, 0.62), i % 2 == 0 and dragonCrimson or voidPurple, Enum.PartType.Ball, 0.08)
                    table.insert(fxData.Orbs, { Part = orb, Index = i, Count = 3 })
                end
            end
        end)
    else
        -- Restore default character scale (2.6) & human mesh/wing/accessory visibility (legacy baked weapon sub-meshes stay hidden for 3D Wep_*)
        setVisualScale(s, 2.6)
        setCharacterBaseVisibilityForBeast(s, false)
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
        setCharacterBaseVisibilityForBeast(s, true)
        if fx.V5Clips then
            local curKey = tostring(s.Name or 'Idle'):gsub('^TS_', '')
            local inTimedAction = now < (s.Until or 0)
            local isFlying = (s.Character and s.Character:GetAttribute('SkybreakFlightActive') == true)
                or (s.Owner and s.Owner:GetAttribute('SkybreakFlightActive') == true)
            local v5Clip = nil
            local clipStart = s.Start or 0
            local forceFlightLoop = false

            if (not inTimedAction) and fx.IntroUntil and now < fx.IntroUntil and (fx.V5Clips.FruitV or fx.V5Clips.Ascend) then
                v5Clip = fx.V5Clips.FruitV or fx.V5Clips.Ascend
                clipStart = fx.IntroStart or 0
            elseif (not inTimedAction) and isFlying and (fx.V5Clips.SoarFlight or fx.V5Clips.WingGlide or fx.V5Clips.FruitF or fx.V5Clips.FallLoop) then
                v5Clip = fx.V5Clips.SoarFlight or fx.V5Clips.WingGlide or fx.V5Clips.FruitF or fx.V5Clips.FallLoop
                clipStart = 0
                forceFlightLoop = true
            else
                v5Clip = fx.V5Clips[curKey]
                if not v5Clip then
                    if curKey == 'SkillZ' or curKey == 'FruitZ' or curKey == 'SkySlash' or curKey == 'FrostBolt' or curKey == 'ArcCut' then
                        v5Clip = fx.V5Clips.FruitZ or fx.V5Clips.ElementalSurge or fx.V5Clips.Attack
                    elseif curKey == 'SkillF' or curKey == 'FruitF' or curKey == 'Dash' or curKey == 'Dodge' or curKey == 'FlashStep' or curKey == 'AirDash' then
                        v5Clip = fx.V5Clips.FruitF or fx.V5Clips.AirDash or fx.V5Clips.Dash
                    elseif curKey == 'SkillX' or curKey == 'FruitX' or curKey == 'JudgmentStrike' or curKey == 'ArcaneCircle' or curKey == 'StormBlitz' then
                        v5Clip = fx.V5Clips.FruitX or fx.V5Clips.HeroicKata or fx.V5Clips.Heavy
                    elseif curKey == 'SkillC' or curKey == 'FruitC' or curKey == 'CelestialAegis' or curKey == 'FrostNova' or curKey == 'ThunderJudgement' or curKey == 'HakiAwaken' then
                        v5Clip = fx.V5Clips.FruitC or fx.V5Clips.UltimateAwakening or fx.V5Clips.Ultimate
                    elseif curKey == 'SkillV' or curKey == 'FruitV' then
                        v5Clip = fx.V5Clips.FruitV or fx.V5Clips.Ascend or fx.V5Clips.Ultimate
                    elseif curKey == 'DaggerCombo' or curKey:sub(1, 6) == 'Attack' then
                        v5Clip = fx.V5Clips.Attack
                    elseif curKey:sub(1, 10) == 'DoubleJump' then
                        v5Clip = fx.V5Clips.AirAscend or fx.V5Clips.DoubleJump or fx.V5Clips.SoarFlight or fx.V5Clips.Jump
                    elseif curKey == 'Land' then
                        v5Clip = fx.V5Clips.Land or fx.V5Clips.CoilIdle or fx.V5Clips.Idle
                    elseif curKey == 'Run' or curKey == 'Walk' then
                        v5Clip = fx.V5Clips.Run or fx.V5Clips.Walk or fx.V5Clips.SoarFlight or fx.V5Clips.Idle
                    elseif curKey == 'FallLoop' or curKey == 'JumpLoop' then
                        v5Clip = fx.V5Clips.FallLoop or fx.V5Clips.SoarFlight or fx.V5Clips.WingGlide or fx.V5Clips.Jump
                    else
                        v5Clip = fx.V5Clips.Idle
                    end
                end
            end

            if v5Clip then
                local useLoop = v5Clip.Loop or forceFlightLoop
                local elapsed
                if v5Clip.Loop then
                    elapsed = now
                elseif forceFlightLoop then
                    elapsed = now % math.max(0.25, v5Clip.Duration or 1.0)
                else
                    elapsed = math.max(0, now - clipStart)
                end
                Renderer.Pose(fx.V5Model, v5Clip, elapsed, { Start = useLoop and 0 or clipStart, BlendTime = 0.12 })
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

        -- Step live 3D Dragon Bone-Locked Maw Embers, Crown Halo Motes & Dynamic Wing/Tail Plasma Trails
        local inAction = (now < (s.Until or 0)) or (fx.IntroUntil and now < fx.IntroUntil)
        local isFlying = (s.Character and s.Character:GetAttribute('SkybreakFlightActive') == true)
            or (s.Owner and s.Owner:GetAttribute('SkybreakFlightActive') == true)
        local speed = s.Root and s.Root.AssemblyLinearVelocity.Magnitude or 0
        local trailsActive = isFlying or inAction or (speed > 13.5)

        local isHybridForm = (fx.SubMode == 'AbyssalDragonHybrid')
        if fx.MawAnchor then
            fx.MawAnchor.CFrame = getBoneWorldCF(s, fx.DragonMawBone, isHybridForm and CFrame.new(0, 2.6, -2.0) or CFrame.new(0, 3.6, -4.2))
            if fx.MawLight then
                fx.MawLight.Brightness = inAction and 1.15 or (0.52 + 0.14 * math.sin(now * 5.2))
            end
            if fx.MawEmbers then
                fx.MawEmbers.Rate = inAction and 36 or (isFlying and 22 or 12)
            end
        end
        if fx.CrownAnchor then
            fx.CrownAnchor.CFrame = getBoneWorldCF(s, fx.DragonCrownBone, isHybridForm and CFrame.new(0, 3.5, -0.8) or CFrame.new(0, 5.4, -2.8))
        end
        if fx.WingLHost then
            fx.WingLHost.CFrame = getBoneWorldCF(s, fx.DragonWingLBone, isHybridForm and CFrame.new(-3.2, 2.8, 0.5) or CFrame.new(-5.8, 4.4, -0.4))
            if fx.WingLTrail then fx.WingLTrail.Enabled = trailsActive end
        end
        if fx.WingRHost then
            fx.WingRHost.CFrame = getBoneWorldCF(s, fx.DragonWingRBone, isHybridForm and CFrame.new(3.2, 2.8, 0.5) or CFrame.new(5.8, 4.4, -0.4))
            if fx.WingRTrail then fx.WingRTrail.Enabled = trailsActive end
        end
        if fx.TailHost then
            fx.TailHost.CFrame = getBoneWorldCF(s, fx.DragonTailBone, isHybridForm and CFrame.new(0, 1.0, 3.4) or CFrame.new(0, 1.6, 5.5))
            if fx.TailTrail then fx.TailTrail.Enabled = trailsActive end
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

    local ch = s.Character
    local plr = s.Owner
    local rawRgb = (ch and ch:GetAttribute('HakiColorRGB')) or (plr and plr:GetAttribute('HakiColorRGB'))
    local hakiPrimary = typeof(rawRgb) == 'Color3' and rawRgb or Color3.fromRGB(255, 42, 95)
    local hakiMid = hakiPrimary:Lerp(Color3.fromRGB(255, 235, 245), 0.35)
    local hakiObsidian = Color3.fromRGB(18, 12, 24)
    local stage = math.clamp(tonumber((ch and ch:GetAttribute('HakiStage')) or (plr and plr:GetAttribute('HakiStage'))) or 1, 0, 5)
    s.HakiColorRGB = hakiPrimary
    s.HakiStage = stage

    local folder = Instance.new('Folder')
    folder.Name = 'HakiAuraFX'
    folder.Parent = s.Visual

    local hl = Instance.new('Highlight')
    hl.Name = 'BusoshokuHighlight'
    hl.Adornee = s.Visual
    hl.FillColor = hakiObsidian
    hl.FillTransparency = math.clamp(0.80 - stage * 0.03, 0.62, 0.80)
    hl.OutlineColor = hakiPrimary
    hl.OutlineTransparency = math.clamp(0.22 - stage * 0.03, 0.05, 0.22)
    hl.Parent = folder

    local rHandBone = findBone(s.Visual, { 'RightHand', 'RightLowerArm', 'RightArm', 'RightBlade' })
    local lHandBone = findBone(s.Visual, { 'LeftHand', 'LeftLowerArm', 'LeftArm', 'LeftBlade' })
    local nodeSpecs = {
        { Name = 'RightHandHaki', Bone = rHandBone, Fallback = CFrame.new(1.3, 0, -0.4), Side = 1 },
        { Name = 'LeftHandHaki', Bone = lHandBone, Fallback = CFrame.new(-1.3, 0, -0.4), Side = -1 },
    }
    if stage >= 4 then
        local rFootBone = findBone(s.Visual, { 'RightFoot', 'RightLowerLeg', 'RightLeg' })
        local lFootBone = findBone(s.Visual, { 'LeftFoot', 'LeftLowerLeg', 'LeftLeg' })
        table.insert(nodeSpecs, { Name = 'RightFootHaki', Bone = rFootBone, Fallback = CFrame.new(0.55, -2.1, 0), Side = 2 })
        table.insert(nodeSpecs, { Name = 'LeftFootHaki', Bone = lFootBone, Fallback = CFrame.new(-0.55, -2.1, 0), Side = -2 })
    end

    local boltCount = (stage >= 4 and 4) or (stage >= 2 and 3) or 2
    local handNodes = {}
    for _, entry in ipairs(nodeSpecs) do
        local node = makeAuraPart(folder, entry.Name, Vector3.new(0.42, 0.42, 0.42), hakiPrimary, Enum.PartType.Ball, 0.35)
        if math.abs(entry.Side) == 1 then
            local light = Instance.new('PointLight')
            light.Name = 'HakiHandLight'
            light.Color = hakiPrimary
            light.Brightness = math.clamp(0.22 + stage * 0.02, 0.22, 0.34)
            light.Range = 5
            light.Parent = node
        end

        local emitter = Instance.new('ParticleEmitter')
        emitter.Name = 'HakiLightningEmitter'
        emitter.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, hakiPrimary),
            ColorSequenceKeypoint.new(0.55, hakiMid),
            ColorSequenceKeypoint.new(1, hakiObsidian),
        })
        emitter.LightEmission = 0.72
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
        emitter.Rate = (workspace:GetAttribute('LowFXMode') == true) and 12 or (24 + stage * 4)
        emitter.Speed = NumberRange.new(1.8, 4.5)
        emitter.SpreadAngle = Vector2.new(180, 180)
        emitter.Parent = node

        local bolts = {}
        for b = 1, boltCount do
            local bolt = makeAuraPart(
                folder,
                entry.Name .. '_Bolt_' .. b,
                Vector3.new(0.09, 0.90 + stage * 0.04, 0.09),
                b % 2 == 0 and hakiObsidian or hakiPrimary,
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
-- 4. RACE V4 SKINNED 3D WINGS (character:GetAttribute("RaceV4") — Key [Y])
-- ============================================================================
local function buildRaceV4FX(s, raceName)
    Equipment3D.BuildRaceV4Wings(Renderer, s, raceName)
end

local function stepRaceV4FX(s, now)
    Equipment3D.StepRaceV4Wings(s, now)
end


local function classifyFruitPartRole(matName, assetName)
    local m = tostring(matName or '')
    local a = tostring(assetName or '')
    if m:find('Ring') or m:find('PortalSilver') or m:find('HaloSolar') or (m:find('BrightGold') and a:find('CelestialLightCore')) then
        return 'Ring'
    elseif m:find('SilverWing') or m:find('SilverShadow') or m:find('DemonWingRed') then
        return 'Wing'
    elseif m:find('Ribbon') or m:find('PortalCyanEmit') or m:find('DropletGold') or m:find('FrostIceLight') or m:find('RumbleArcEmit') or m:find('BasaltRimHot') or m:find('CharredBasalt') then
        return 'Orbit'
    end
    return 'Core'
end

local function buildHeldFruitFX(s, fruitId)
    if not s or not s.Model or not s.Model.Parent then
        return
    end
    local ticket = (s._HeldFruitTicket or 0) + 1
    s._HeldFruitTicket = ticket
    for _, ch in ipairs(s.Model:GetChildren()) do
        if ch.Name == 'HeldFruit3D' then
            ch:Destroy()
        end
    end
    s.HeldFruitModel = nil
    s.HeldFruitClips = nil
    s.HeldFruitParts = nil
    s._HeldFruitHiddenForBeast = false
    s.HeldFruitId = fruitId or ''
    if not fruitId or fruitId == '' then
        return
    end
    local rawAsset = fruitId:sub(1, 6) == 'Fruit_' and fruitId or ('Fruit_' .. fruitId)
    local assetName = (Renderer.Alias and (Renderer.Alias[fruitId] or Renderer.Alias[rawAsset])) or rawAsset
    task.spawn(function()
        local ok, template = pcall(Renderer.Build, assetName)
        if s._HeldFruitTicket ~= ticket or not s.Model or not s.Model.Parent or not ok or not template then
            return
        end
        local clone = template:Clone()
        clone.Name = 'HeldFruit3D'
        clone:ScaleTo(0.78)
        local firstMesh = nil
        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA('WeldConstraint') then
                d:Destroy()
            elseif d:IsA('BasePart') then
                d.Anchored = true
                d.CanCollide = false
                d.CanQuery = false
                d.CanTouch = false
                d.Massless = true
                if d:IsA('MeshPart') and not firstMesh then
                    firstMesh = d
                end
            end
        end
        if clone.PrimaryPart and firstMesh then
            clone.PrimaryPart.CFrame = firstMesh.CFrame
        end
        local boxCF = clone:GetBoundingBox()
        if clone.PrimaryPart then
            clone.PrimaryPart.CFrame = boxCF
        end
        local partsList = {}
        local partIdx = 0
        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA('MeshPart') then
                partIdx += 1
                table.insert(partsList, {
                    Part = d,
                    RelCF = boxCF:ToObjectSpace(d.CFrame),
                    Role = classifyFruitPartRole(d:GetAttribute('BlenderMaterial'), assetName),
                    Index = partIdx,
                })
            end
        end
        clone.Parent = s.Model
        s.HeldFruitModel = clone
        s.HeldFruitParts = partsList
        s.HeldFruitClips = getScaledClips(assetName, 0.78)
        s.HeldFruitHandBone = findBone(s.Model, { 'Hand_R', 'RightHand', 'Arm_R', 'Weapon_R' })
    end)
end

local function animateFruitSubParts(baseCF, partsList, now)
    if not partsList then
        return
    end
    for _, entry in ipairs(partsList) do
        local part = entry.Part
        if part and part.Parent then
            if entry.Role == 'Ring' then
                part.CFrame = baseCF
                    * CFrame.Angles(math.sin(now * 2.4 + entry.Index) * 0.14, now * 1.2, math.cos(now * 2.0) * 0.10)
                    * entry.RelCF
            elseif entry.Role == 'Wing' then
                local side = entry.RelCF.Position.X >= 0 and 1 or -1
                part.CFrame = baseCF
                    * CFrame.new(0, math.sin(now * 3.8) * 0.03, 0)
                    * CFrame.Angles(0, 0, math.sin(now * 3.8) * 0.08 * side)
                    * entry.RelCF
            elseif entry.Role == 'Orbit' then
                part.CFrame = baseCF
                    * CFrame.new(0, math.sin(now * 3.2 + entry.Index * 0.9) * 0.035, 0)
                    * CFrame.Angles(0, math.sin(now * 1.8) * 0.08, 0)
                    * entry.RelCF
            else
                part.CFrame = baseCF * entry.RelCF
            end
        end
    end
end

local function stepHeldFruitFX(s, now)
    if not s or not s.Root or not s.Root.Parent then
        return
    end
    local ch = s.Character
    local plr = s.Owner
    local activeSlot = tonumber((ch and ch:GetAttribute('ActiveSlot')) or (plr and plr:GetAttribute('ActiveSlot')))
    local m = s.HeldFruitModel
    local hasHeldFruit = (m ~= nil and m.Parent ~= nil)
    local isV5Transform = (s.TransformFX and s.TransformFX.V5Model and s.TransformFX.V5Model.Parent ~= nil)
    if s.WeaponParts and not isV5Transform then
        for _, part in ipairs(s.WeaponParts) do
            if part and part.Parent and part.LocalTransparencyModifier ~= 1 then
                part.LocalTransparencyModifier = 1
                part.Transparency = 1
            end
        end
    end
    if not hasHeldFruit then
        return
    end
    if isV5Transform then
        if not s._HeldFruitHiddenForBeast then
            s._HeldFruitHiddenForBeast = true
            for _, d in ipairs(m:GetDescendants()) do
                if d:IsA('BasePart') then
                    d.LocalTransparencyModifier = 1
                elseif d:IsA('PointLight') or d:IsA('ParticleEmitter') or d:IsA('Trail') then
                    d.Enabled = false
                end
            end
        end
        return
    elseif s._HeldFruitHiddenForBeast then
        s._HeldFruitHiddenForBeast = false
        local low = Equipment3D.IsLowFX(s.Owner)
        for _, d in ipairs(m:GetDescendants()) do
            if d:IsA('BasePart') then
                d.LocalTransparencyModifier = 0
            elseif d:IsA('PointLight') or d:IsA('ParticleEmitter') or d:IsA('Trail') then
                d.Enabled = not low
            end
        end
    end
    local bob = math.sin(now * 3.2) * 0.12
    local targetPos
    if activeSlot == 1 or activeSlot == 3 or activeSlot == 4 then
        targetPos = (s.Root.CFrame * CFrame.new(-1.85, 1.65 + bob, 0.45)).Position
    else
        local handCF = getBoneWorldCF(s, s.HeldFruitHandBone, CFrame.new(1.35, 0.35, -0.85))
        targetPos = handCF.Position + Vector3.new(0, 0.52 + bob, 0)
    end
    local baseCF = CFrame.new(targetPos) * CFrame.Angles(0, math.pi + now * 1.35, math.sin(now * 2.2) * 0.06)
    if m.PrimaryPart then
        m.PrimaryPart.CFrame = baseCF
    end
    animateFruitSubParts(baseCF, s.HeldFruitParts, now)
    if s.HeldFruitClips then
        local fClip = s.HeldFruitClips.ElementalSurge or s.HeldFruitClips.Idle
        if fClip then
            Renderer.Pose(m, fClip, now)
        end
    end
end

local world3DFruitOrbitConn = nil
local function spawnWorld3DDevilFruits()
    if world3DFruitOrbitConn then
        world3DFruitOrbitConn:Disconnect()
        world3DFruitOrbitConn = nil
    end

    local worldFolder = workspace:FindFirstChild('SkybreakWorld3DFruits')
    if not worldFolder then
        worldFolder = Instance.new('Folder')
        worldFolder.Name = 'SkybreakWorld3DFruits'
        worldFolder.Parent = workspace
    else
        worldFolder:ClearAllChildren()
    end

    local remotesFolder = game.ReplicatedStorage:WaitForChild('Remotes', 10)
    local equipRemote = remotesFolder and remotesFolder:FindFirstChild('EquipmentRequest')

    local function createFruitBillboard(adorneePart, titleText, rarityText, accentColor, studsOffset)
        local bill = Instance.new('BillboardGui')
        bill.Name = 'Fruit3DBillboard'
        bill.Adornee = adorneePart
        bill.Size = UDim2.fromOffset(230, 48)
        bill.StudsOffset = studsOffset or Vector3.new(0, 2.9, 0)
        bill.MaxDistance = 95
        bill.AlwaysOnTop = true
        bill.Parent = adorneePart

        local nameLbl = Instance.new('TextLabel')
        nameLbl.Name = 'FruitName'
        nameLbl.Size = UDim2.new(1, 0, 0, 24)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextSize = 14
        nameLbl.TextColor3 = accentColor or Color3.fromRGB(255, 224, 115)
        nameLbl.TextStrokeTransparency = 0.15
        nameLbl.Text = tostring(titleText)
        nameLbl.Parent = bill

        local rarLbl = Instance.new('TextLabel')
        rarLbl.Name = 'FruitRarity'
        rarLbl.Position = UDim2.fromOffset(0, 22)
        rarLbl.Size = UDim2.new(1, 0, 0, 20)
        rarLbl.BackgroundTransparency = 1
        rarLbl.Font = Enum.Font.GothamBold
        rarLbl.TextSize = 12
        rarLbl.TextColor3 = Color3.fromRGB(240, 248, 255)
        rarLbl.TextStrokeTransparency = 0.25
        rarLbl.Text = '[' .. tostring(rarityText) .. '] • 3D DEVIL FRUIT'
        rarLbl.Parent = bill
        return bill
    end

    local function buildScaled3DFruitModel(fruitAsset, scale, parentFolder)
        local okB, template = pcall(Renderer.Build, fruitAsset)
        if not okB or not template then
            return nil, nil
        end
        local clone = template:Clone()
        clone.Name = fruitAsset .. '_3D'
        pcall(function()
            clone:ScaleTo(scale)
        end)
        local firstMesh = nil
        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA('WeldConstraint') then
                d:Destroy()
            elseif d:IsA('BasePart') then
                d.Anchored = true
                d.CanCollide = false
                d.CanQuery = false
                d.CanTouch = false
                d.Massless = true
                if d:IsA('MeshPart') and not firstMesh then
                    firstMesh = d
                end
            end
        end
        if clone.PrimaryPart and firstMesh then
            clone.PrimaryPart.CFrame = firstMesh.CFrame
        end
        local boxCF = clone:GetBoundingBox()
        if clone.PrimaryPart then
            clone.PrimaryPart.CFrame = boxCF
        end
        local partsList = {}
        local pIdx = 0
        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA('MeshPart') then
                pIdx += 1
                table.insert(partsList, {
                    Part = d,
                    RelCF = boxCF:ToObjectSpace(d.CFrame),
                    Role = classifyFruitPartRole(d:GetAttribute('BlenderMaterial'), fruitAsset),
                    Index = pIdx,
                })
            end
        end
        clone.Parent = parentFolder
        return clone, partsList
    end

    -- 1. Zioles Gacha Shrine Orbiting 3D Devil Fruits (Vector3.new(-560.0, 53.0, 980.0), radius 7.5 studs, scale 0.72)
    local shrineOrbitCenter = Vector3.new(-560.0, 53.0, 980.0)
    local shrineModel = workspace:FindFirstChild('ZiolesGachaShrine', true)
        or (workspace:FindFirstChild('GrandSkyIslands') and workspace.GrandSkyIslands:FindFirstChild('ZiolesGachaShrine_ImportedArt'))
    if shrineModel and shrineModel:IsA('Model') then
        local piv = shrineModel:GetPivot().Position
        if (piv - shrineOrbitCenter).Magnitude > 60 then
            shrineOrbitCenter = piv + Vector3.new(0, 5.5, 0)
        end
    end

    local shrineFolder = Instance.new('Folder')
    shrineFolder.Name = 'ZiolesShrineOrbitFruits'
    shrineFolder.Parent = worldFolder

    local gachaRing = Instance.new('Part')
    gachaRing.Name = 'ZiolesGachaOrbitHalo'
    gachaRing.Shape = Enum.PartType.Cylinder
    gachaRing.Size = Vector3.new(0.14, 15.2, 15.2)
    gachaRing.CFrame = CFrame.new(shrineOrbitCenter - Vector3.new(0, 2.2, 0)) * CFrame.Angles(0, 0, math.pi * 0.5)
    gachaRing.Color = Color3.fromRGB(218, 174, 68)
    gachaRing.Material = Enum.Material.SmoothPlastic
    gachaRing.Transparency = 0.55
    gachaRing.Anchored = true
    gachaRing.CanCollide = false
    gachaRing.CanQuery = false
    gachaRing.CanTouch = false
    gachaRing.Parent = shrineFolder

    local SHRINE_ORBIT_FRUITS = {
        { Id = 'GaleCore', Asset = 'Fruit_GaleCore', Name = 'Trái Cuồng Phong', Rarity = 'COMMON', Color = Color3.fromRGB(145, 255, 215) },
        { Id = 'SolarFlameCore', Asset = 'Fruit_SolarFlameCore', Name = 'Trái Hỏa Dương', Rarity = 'RARE', Color = Color3.fromRGB(255, 132, 52) },
        { Id = 'GlacierIceCore', Asset = 'Fruit_GlacierIceCore', Name = 'Trái Băng Hà Vĩnh Cửu', Rarity = 'RARE', Color = Color3.fromRGB(115, 238, 255) },
        { Id = 'ThunderRumbleCore', Asset = 'Fruit_ThunderRumbleCore', Name = 'Trái Lôi Thần', Rarity = 'LEGENDARY', Color = Color3.fromRGB(88, 212, 255) },
        { Id = 'AstralGravityCore', Asset = 'Fruit_AstralGravityCore', Name = 'Trái Trọng Lực Tinh Vân', Rarity = 'LEGENDARY', Color = Color3.fromRGB(192, 118, 255) },
        { Id = 'AbyssalSovereignCore', Asset = 'Fruit_AbyssalSovereignCore', Name = 'Trái Long Vương Hư Không', Rarity = 'MYTHICAL', Color = Color3.fromRGB(215, 92, 255) },
    }

    local orbitingEntries = {}
    local orbitRadius = 7.5
    for idx, spec in ipairs(SHRINE_ORBIT_FRUITS) do
        local model, partsList = buildScaled3DFruitModel(spec.Asset, 0.72, shrineFolder)
        if model then
            local labelNode = Instance.new('Part')
            labelNode.Name = spec.Asset .. '_LabelNode'
            labelNode.Size = Vector3.new(0.4, 0.4, 0.4)
            labelNode.Transparency = 1
            labelNode.Anchored = true
            labelNode.CanCollide = false
            labelNode.CanQuery = false
            labelNode.CanTouch = false
            labelNode.Parent = shrineFolder

            local pl = Instance.new('PointLight')
            pl.Color = spec.Color
            pl.Brightness = 0.45
            pl.Range = 7
            pl.Parent = labelNode

            createFruitBillboard(labelNode, spec.Name, spec.Rarity, spec.Color, Vector3.new(0, 2.2, 0))

            local baseAngle = (idx - 1) * (2 * math.pi / #SHRINE_ORBIT_FRUITS)
            local initPos = shrineOrbitCenter + Vector3.new(math.cos(baseAngle) * orbitRadius, 0, math.sin(baseAngle) * orbitRadius)
            labelNode.Position = initPos
            local initCF = CFrame.new(initPos) * CFrame.Angles(0, math.pi, 0)
            if model.PrimaryPart then
                model.PrimaryPart.CFrame = initCF
            end
            animateFruitSubParts(initCF, partsList, 0)

            table.insert(orbitingEntries, {
                Model = model,
                Parts = partsList,
                Node = labelNode,
                Index = idx,
                BaseAngle = baseAngle,
            })
        end
        task.wait(0.05)
    end

    -- 2. Sky Hub Plaza Interactive 3D Devil Fruit Pedestal Display (Vector3.new(-315.4, 50.35, 514.0) on floor Y=46.5)
    local pedestalHubCenter = Vector3.new(-315.4, 50.35, 514.0)
    local hubFolder = Instance.new('Folder')
    hubFolder.Name = 'SkyHubAncientAetherFruitPedestals'
    hubFolder.Parent = worldFolder

    local PEDESTAL_FRUITS = {
        { Id = 'DimensionalPortalCore', Asset = 'Fruit_DimensionalPortalCore', Name = 'Trái Không Gian (Portal)', Rarity = 'LEGENDARY', Color = Color3.fromRGB(110, 215, 255), Offset = Vector3.new(-5.8, 0, 0) },
        { Id = 'SolarTitanCore', Asset = 'Fruit_SolarTitanCore', Name = 'Trái Kim Thân Phật Tổ (Buddha)', Rarity = 'MYTHICAL', Color = Color3.fromRGB(255, 216, 78), Offset = Vector3.new(0, 0.35, 0) },
        { Id = 'AetherflowCore', Asset = 'Fruit_AetherflowCore', Name = 'Trái Linh Mạch Aether (Aetherflow)', Rarity = 'MYTHICAL', Color = Color3.fromRGB(235, 115, 252), Offset = Vector3.new(5.8, 0, 0) },
    }

    local pedestalEntries = {}
    for idx, spec in ipairs(PEDESTAL_FRUITS) do
        local rawX = pedestalHubCenter.X + spec.Offset.X
        local rawZ = pedestalHubCenter.Z + spec.Offset.Z
        local hit = workspace:Raycast(Vector3.new(rawX, 90, rawZ), Vector3.new(0, -60, 0))
        local floorY = hit and hit.Position.Y or 46.5
        local pedPos = Vector3.new(rawX, floorY + 3.85 + spec.Offset.Y, rawZ)

        local pedBase = Instance.new('Part')
        pedBase.Name = 'AetherPedestalBase_' .. spec.Id
        pedBase.Shape = Enum.PartType.Cylinder
        pedBase.Size = Vector3.new(0.62, 3.8, 3.8)
        pedBase.CFrame = CFrame.new(pedPos.X, floorY + 0.31, pedPos.Z) * CFrame.Angles(0, 0, math.pi * 0.5)
        pedBase.Color = Color3.fromRGB(24, 22, 36)
        pedBase.Material = Enum.Material.Slate
        pedBase.Anchored = true
        pedBase.CanCollide = true
        pedBase.Parent = hubFolder

        local pedColumn = Instance.new('Part')
        pedColumn.Name = 'AetherPedestalColumn_' .. spec.Id
        pedColumn.Shape = Enum.PartType.Cylinder
        pedColumn.Size = Vector3.new(1.85, 2.15, 2.15)
        pedColumn.CFrame = CFrame.new(pedPos.X, floorY + 1.32, pedPos.Z) * CFrame.Angles(0, 0, math.pi * 0.5)
        pedColumn.Color = Color3.fromRGB(36, 44, 68)
        pedColumn.Material = Enum.Material.SmoothPlastic
        pedColumn.Reflectance = 0.06
        pedColumn.Anchored = true
        pedColumn.CanCollide = true
        pedColumn.Parent = hubFolder

        local pedCrown = Instance.new('Part')
        pedCrown.Name = 'AetherPedestalHalo_' .. spec.Id
        pedCrown.Shape = Enum.PartType.Cylinder
        pedCrown.Size = Vector3.new(0.22, 2.65, 2.65)
        pedCrown.CFrame = CFrame.new(pedPos.X, floorY + 2.32, pedPos.Z) * CFrame.Angles(0, 0, math.pi * 0.5)
        pedCrown.Color = Color3.fromRGB(196, 152, 58)
        pedCrown.Material = Enum.Material.SmoothPlastic
        pedCrown.Reflectance = 0.08
        pedCrown.Anchored = true
        pedCrown.CanCollide = false
        pedCrown.CanQuery = false
        pedCrown.CanTouch = false
        pedCrown.Parent = hubFolder

        local promptPart = Instance.new('Part')
        promptPart.Name = 'FruitPedestalPrompt_' .. spec.Id
        promptPart.Size = Vector3.new(2.6, 2.6, 2.6)
        promptPart.Position = pedPos
        promptPart.Transparency = 1
        promptPart.Anchored = true
        promptPart.CanCollide = false
        promptPart.CanTouch = false
        promptPart:SetAttribute('InteractableId', 'ShowcaseFruit_' .. spec.Id)
        promptPart:SetAttribute('ShowcaseFruitId', spec.Id)
        promptPart:SetAttribute('ShowcaseFruitName', spec.Name)
        promptPart.Parent = hubFolder

        local pl = Instance.new('PointLight')
        pl.Color = spec.Color
        pl.Brightness = 0.35
        pl.Range = 7
        pl.Parent = promptPart

        createFruitBillboard(promptPart, spec.Name, spec.Rarity, spec.Color, Vector3.new(0, 2.55, 0))

        local prompt = Instance.new('ProximityPrompt')
        prompt.Name = 'InspectFruit3DPrompt'
        prompt.ActionText = 'Ấn [E] Thử Cầm / Xem Trái Ác Quỷ 3D'
        prompt.ObjectText = 'Ấn [E] Thử Cầm / Xem Trái Ác Quỷ 3D — ' .. spec.Name
        prompt.KeyboardKeyCode = Enum.KeyCode.E
        prompt.HoldDuration = 0
        prompt.MaxActivationDistance = 14
        prompt.RequiresLineOfSight = false
        prompt.Parent = promptPart

        prompt.Triggered:Connect(function(triggerPlayer)
            if triggerPlayer and triggerPlayer ~= player then
                return
            end
            if equipRemote then
                equipRemote:FireServer({
                    action = 'HoldFruit',
                    fruitId = spec.Id,
                    forceHold = true,
                    showcasePreview = true,
                })
            end
            if player then
                player:SetAttribute('ShowcaseFruitUntil', os.clock() + 8)
                player:SetAttribute('HeldFruit', spec.Id)
                if player.Character then
                    player.Character:SetAttribute('HeldFruit', spec.Id)
                end
                player:SetAttribute('SelectedPreviewFruit', spec.Id)
                player:SetAttribute('OpenFruitShowcaseUI', spec.Name .. '|' .. tostring(os.clock()))
                local pgui = player:FindFirstChildOfClass('PlayerGui')
                local skyUI = pgui and pgui:FindFirstChild('SkybreakUI')
                if skyUI then
                    skyUI:SetAttribute('RequestScreen', '')
                    skyUI:SetAttribute('RequestScreen', 'Fruits')
                end
            end
        end)

        local model, partsList = buildScaled3DFruitModel(spec.Asset, 0.82, hubFolder)
        if model then
            local initCF = CFrame.new(pedPos) * CFrame.Angles(0, math.pi, 0)
            if model.PrimaryPart then
                model.PrimaryPart.CFrame = initCF
            end
            animateFruitSubParts(initCF, partsList, 0)
            table.insert(pedestalEntries, {
                Model = model,
                Parts = partsList,
                BasePos = pedPos,
                Halo = pedCrown,
                Index = idx,
            })
        end
        task.wait(0.05)
    end

    local t0 = os.clock()
    world3DFruitOrbitConn = Run.RenderStepped:Connect(function()
        if not worldFolder.Parent then
            if world3DFruitOrbitConn then
                world3DFruitOrbitConn:Disconnect()
                world3DFruitOrbitConn = nil
            end
            return
        end
        local cam = workspace.CurrentCamera
        local camPos = cam and cam.CFrame.Position or nil
        local elapsed = os.clock() - t0

        if not camPos or (camPos - shrineOrbitCenter).Magnitude <= 1650 then
            for _, item in ipairs(orbitingEntries) do
                if item.Model and item.Model.Parent then
                    local ang = item.BaseAngle + elapsed * 0.55
                    local bob = math.sin(elapsed * 2.2 + item.Index * 1.05) * 0.55
                    local worldPos = shrineOrbitCenter + Vector3.new(
                        math.cos(ang) * orbitRadius,
                        bob,
                        math.sin(ang) * orbitRadius
                    )
                    local baseCF = CFrame.new(worldPos) * CFrame.Angles(0, math.pi + elapsed * 1.25 + item.Index, 0)
                    if item.Model.PrimaryPart then
                        item.Model.PrimaryPart.CFrame = baseCF
                    end
                    animateFruitSubParts(baseCF, item.Parts, elapsed + item.Index * 0.4)
                    if item.Node and item.Node.Parent then
                        item.Node.Position = worldPos
                    end
                end
            end
        end

        if not camPos or (camPos - pedestalHubCenter).Magnitude <= 1650 then
            for _, item in ipairs(pedestalEntries) do
                if item.Model and item.Model.Parent then
                    local bob = math.sin(elapsed * 2.4 + item.Index * 1.2) * 0.38
                    local worldPos = item.BasePos + Vector3.new(0, bob, 0)
                    local baseCF = CFrame.new(worldPos) * CFrame.Angles(0, math.pi + elapsed * 1.15 + item.Index * 0.8, 0)
                    if item.Model.PrimaryPart then
                        item.Model.PrimaryPart.CFrame = baseCF
                    end
                    animateFruitSubParts(baseCF, item.Parts, elapsed + item.Index * 0.5)
                end
            end
        end
    end)
end
task.delay(1.8, spawnWorld3DDevilFruits)

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
    if gateModel.Name == 'WorldGate_Sea1_to_Sea2' or gateModel.Name == 'WorldGate_Sea2_to_Sea3' then
        worldGates3D[gateModel] = true
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
    makeAuraPart(vis, 'GateBaseDais', Vector3.new(11.5, 0.66, 4.8), darkStone, Enum.PartType.Block, 0.0, 'Part', Enum.Material.Slate, 0.05).CFrame =
        CFrame.new(core.Position.X, floorY + 0.33, core.Position.Z)
    makeAuraPart(vis, 'GateBaseRuneStrip', Vector3.new(10.2, 0.72, 3.6), col, Enum.PartType.Block, 0.12, 'Part', Enum.Material.Neon, 0).CFrame =
        CFrame.new(core.Position.X, floorY + 0.36, core.Position.Z)

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
    light.Brightness = 1.42
    light.Range = 16
    light.Parent = core

    local emitter = Instance.new('ParticleEmitter')
    emitter.Name = 'PortalVortexSparks'
    emitter.Color = ColorSequence.new(col, secCol)
    emitter.LightEmission = 0.75
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
        if type(g) ~= 'table' then
            continue
        end
        local dist = camPos and (g.Center - camPos).Magnitude or 0
        if g.Initialized then
            if dist > 2400 then
                continue
            elseif dist > 850 then
                if now < (g.NextStep or 0) then
                    continue
                end
                g.NextStep = now + 0.06
            end
        else
            g.Initialized = true
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

local REALM_ELEMENTAL_PALETTES = {
    VerdantCrown = {
        Crystal = Color3.fromRGB(76, 238, 138),
        CrystalAlt = Color3.fromRGB(192, 248, 96),
        Water = Color3.fromRGB(58, 212, 168),
        Foliage = Color3.fromRGB(46, 168, 92),
        FoliageAlt = Color3.fromRGB(82, 208, 118),
        Wood = Color3.fromRGB(106, 74, 46),
        Metal = Color3.fromRGB(208, 176, 82),
        Plaza = Color3.fromRGB(184, 206, 186),
        Cliff = Color3.fromRGB(108, 124, 106),
    },
    EmberforgeWastes = {
        Crystal = Color3.fromRGB(255, 112, 28),
        CrystalAlt = Color3.fromRGB(255, 182, 48),
        Water = Color3.fromRGB(248, 96, 22),
        Foliage = Color3.fromRGB(178, 76, 34),
        FoliageAlt = Color3.fromRGB(218, 108, 42),
        Wood = Color3.fromRGB(72, 46, 38),
        Metal = Color3.fromRGB(204, 114, 52),
        Plaza = Color3.fromRGB(122, 92, 82),
        Cliff = Color3.fromRGB(58, 40, 36),
    },
    AbyssalTides = {
        Crystal = Color3.fromRGB(38, 232, 218),
        CrystalAlt = Color3.fromRGB(236, 108, 182),
        Water = Color3.fromRGB(42, 176, 212),
        Foliage = Color3.fromRGB(44, 188, 168),
        FoliageAlt = Color3.fromRGB(224, 112, 164),
        Wood = Color3.fromRGB(64, 92, 108),
        Metal = Color3.fromRGB(206, 182, 104),
        Plaza = Color3.fromRGB(182, 222, 228),
        Cliff = Color3.fromRGB(34, 72, 96),
    },
    ChronosBastion = {
        Crystal = Color3.fromRGB(124, 214, 255),
        CrystalAlt = Color3.fromRGB(252, 206, 88),
        Water = Color3.fromRGB(142, 198, 248),
        Foliage = Color3.fromRGB(228, 192, 98),
        FoliageAlt = Color3.fromRGB(164, 136, 228),
        Wood = Color3.fromRGB(128, 112, 98),
        Metal = Color3.fromRGB(232, 184, 78),
        Plaza = Color3.fromRGB(222, 216, 236),
        Cliff = Color3.fromRGB(132, 128, 152),
    },
    VeilsEnd = {
        Crystal = Color3.fromRGB(184, 78, 252),
        CrystalAlt = Color3.fromRGB(244, 92, 212),
        Water = Color3.fromRGB(118, 56, 196),
        Foliage = Color3.fromRGB(142, 64, 198),
        FoliageAlt = Color3.fromRGB(196, 84, 232),
        Wood = Color3.fromRGB(54, 38, 72),
        Metal = Color3.fromRGB(192, 174, 224),
        Plaza = Color3.fromRGB(88, 68, 124),
        Cliff = Color3.fromRGB(36, 24, 58),
    },
}

local function applyRealmElementalTheme(model, realmName)
    local pal = REALM_ELEMENTAL_PALETTES[realmName]
    if not pal or not model then
        return
    end
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA('BasePart') and p.Name ~= 'RootPart' then
            for _, ch in ipairs(p:GetChildren()) do
                if ch:IsA('SurfaceAppearance') then
                    ch:Destroy()
                end
            end
            local rawMat = string.lower(tostring(p:GetAttribute('BlenderMaterial') or p.Name))
            local m = rawMat
                :gsub('umbralcrystalsanctumforest_', '')
                :gsub('westgardenpiratebastion_', '')
                :gsub('mirageskyislandleviathanabyss_', '')
                :gsub('templeofthecoreracev4_', '')
                :gsub('castleonthevoidmansion_', '')
                :gsub('sunshardskysanctuary_', '')
                :gsub('cyberportcafetradinghub_', '')
                :gsub('permafrostgarrisonfortress_', '')
                :gsub('microchipawakeningraidlab_', '')
                :gsub('glacialwreckagedangersea_', '')
            local isCrystal = m:find('crystal') or m:find('glow') or m:find('lumen') or m:find('neon')
                or m:find('portal') or m:find('elem') or m:find('core') or m:find('rune')
                or m:find('ember') or m:find('fire') or m:find('corona') or m:find('eclipse')
                or m:find('window') or m:find('sunglow') or m:find('sapphire')
            local isWater = m:find('water') or m:find('foam') or m:find('lake') or m:find('sea')
                or m:find('lava') or m:find('ice') or m:find('glacier')
            local isFoliage = m:find('foliage') or m:find('leaf') or m:find('canopy') or m:find('moss')
                or m:find('grass') or m:find('pine') or m:find('palm') or m:find('meadow')
                or m:find('cypress') or m:find('sakura')
            local isWood = m:find('bark') or m:find('wood') or m:find('timber') or m:find('trunk')
                or m:find('rope') or m:find('pier')
            local isMetal = m:find('gold') or m:find('bronze') or m:find('brass') or m:find('iron')
                or m:find('steel') or m:find('metal') or m:find('trim') or m:find('chain')
                or m:find('banner') or m:find('roof') or m:find('sail')
            local isPlaza = m:find('ivory') or m:find('marble') or m:find('limestone') or m:find('plaza')
                or m:find('slate') or m:find('stone') or m:find('wall') or m:find('plaster')
                or m:find('path') or m:find('road') or m:find('viaduct') or m:find('terrace')
                or m:find('plateau') or m:find('snow') or m:find('cream') or m:find('bone')
                or m:find('cutedges')

            if isCrystal then
                local useAlt = m:find('magenta') or m:find('pink') or m:find('violet') or m:find('gold') or m:find('warm') or m:find('sun')
                p.Color = useAlt and pal.CrystalAlt or pal.Crystal
                p.Material = Enum.Material.SmoothPlastic
                p.Reflectance = 0.04
            elseif isWater then
                p.Color = pal.Water
                p.Material = Enum.Material.SmoothPlastic
                p.Reflectance = 0.06
            elseif isFoliage then
                local useAlt = m:find('pink') or m:find('sakura') or m:find('lavender') or m:find('sunlit') or m:find('gold')
                p.Color = useAlt and pal.FoliageAlt or pal.Foliage
                p.Material = Enum.Material.SmoothPlastic
                p.Reflectance = 0
            elseif isWood then
                p.Color = pal.Wood
                p.Material = Enum.Material.SmoothPlastic
                p.Reflectance = 0
            elseif isMetal then
                p.Color = pal.Metal
                p.Material = Enum.Material.Metal
                p.Reflectance = 0.10
            elseif isPlaza then
                p.Color = pal.Plaza
                p.Material = Enum.Material.SmoothPlastic
                p.Reflectance = 0.02
            else
                p.Color = pal.Cliff
                p.Material = Enum.Material.SmoothPlastic
                p.Reflectance = 0
            end
        end
    end
end

local function boot()
    local worldsFolder = workspace:FindFirstChild('Worlds')
    local goldenSkyBase = nil
    if not (worldsFolder and worldsFolder:FindFirstChild('GoldenSky_3D')) then
        local map = Renderer.Build('GoldenSky', progress)
        if map then
            goldenSkyBase = map:Clone()
            goldenSkyBase.Name = 'GoldenSky_ImportedArt'
            goldenSkyBase:PivotTo(CFrame.new(0, 0, 0))
            goldenSkyBase.Parent = workspace
        end
    end
    workspace:SetAttribute('Sea1IslandsReady', true)

    local sources = game.ReplicatedStorage.DelegatedV5Sources
    local bossScale = 1.9
    local bossClips = nil
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
        WestGardenPirateBastion = 0.0,
        SunshardSkySanctuary = 0.0,
        CyberportCafeTradingHub = 0.0,
        PermafrostGarrisonFortress = 0.0,
        MicrochipAwakeningRaidLab = 0.0,
        GlacialWreckageDangerSea = 0.0,
        CastleOnTheVoidMansion = 0.0,
        UmbralCrystalSanctumForest = 0.0,
        TempleOfTheCoreRaceV4 = 0.0,
        MirageSkyIslandLeviathanAbyss = 0.0,
    }

    local function placeGrandIsland(entry)
        if not sources:FindFirstChild(entry.Asset) then
            return
        end
        local instName = (entry.Name or entry.Asset) .. '_ImportedArt'
        local existing = grandIslandsFolder:FindFirstChild(instName)
        if existing then
            existing:Destroy()
        end
        local okIsl, islModel = pcall(Renderer.Build, entry.Asset)
        if okIsl and islModel then
            local placed = islModel:Clone()
            placed.Name = instName
            placed:SetAttribute('IslandAsset', entry.Asset)
            placed:SetAttribute('Sea', entry.Sea)
            local deckOffY = entry.DeckOffsetY ~= nil and entry.DeckOffsetY or (DECK_OFFSET_Y[entry.Asset] or 0)
            placed:SetAttribute('DeckSurfaceY', entry.DeckY or entry.Origin.Y)
            placed:PivotTo(CFrame.new(entry.Origin - Vector3.new(0, deckOffY, 0)))
            placed.Parent = grandIslandsFolder
        else
            warn('[SKYBREAK Island Build]', entry.Asset, islModel)
        end
    end

    local portal, portalClips, shadowPortal, shadowPortalClip
    -- Stream Sea 1, Sea 2 & Sea 3 Gameplay3x Worlds + 5 Expansion Realms
    task.spawn(function()
        task.wait(0.35)

        local sea2And3Islands = {
            -- Sea 1 Islands (around Gameplay3x GoldenSky = 0, 0, 0)
            { Name = 'ZiolesGachaShrine', Asset = 'ZiolesGachaShrine', Origin = Vector3.new(-560.0, 48.5, 980.0), DeckY = 48.5, DeckOffsetY = 2.0, Sea = 1, StreamDist = 8500 },
            { Name = 'AetherShrineIsland', Asset = 'ZiolesGachaShrine', Origin = Vector3.new(340.0, 48.5, 980.0), DeckY = 48.5, DeckOffsetY = 2.0, Sea = 1, StreamDist = 8500 },
            { Name = 'WestGardenPirateBastion', Asset = 'WestGardenPirateBastion', Origin = Vector3.new(-2800.0, 0.0, 200.0), DeckY = 46.5, DeckOffsetY = 0.0, Sea = 1, StreamDist = 8500 },
            { Name = 'SunshardSkySanctuary', Asset = 'SunshardSkySanctuary', Origin = Vector3.new(2800.0, 0.0, -200.0), DeckY = 46.5, DeckOffsetY = 0.0, Sea = 1, StreamDist = 8500 },
            -- Sea 2 Gameplay3x Sub-Worlds (around FrozenCyber = 12000, 0, 0)
            { Name = 'CyberportCafeTradingHub', Asset = 'CyberportCafeTradingHub', Origin = Vector3.new(9400.0, 0.0, 1800.0), DeckY = 46.9, DeckOffsetY = 0.0, Sea = 2, StreamDist = 8500 },
            { Name = 'PermafrostGarrisonFortress', Asset = 'PermafrostGarrisonFortress', Origin = Vector3.new(9400.0, 0.0, -1800.0), DeckY = 46.9, DeckOffsetY = 0.0, Sea = 2, StreamDist = 8500 },
            { Name = 'MicrochipAwakeningRaidLab', Asset = 'MicrochipAwakeningRaidLab', Origin = Vector3.new(14600.0, 0.0, 1800.0), DeckY = 46.9, DeckOffsetY = 0.0, Sea = 2, StreamDist = 8500 },
            { Name = 'GlacialWreckageDangerSea', Asset = 'GlacialWreckageDangerSea', Origin = Vector3.new(14600.0, 0.0, -1800.0), DeckY = 46.9, DeckOffsetY = 0.0, Sea = 2, StreamDist = 8500 },
            -- Sea 3 Gameplay3x Sub-Worlds (around ShadowRealm = -12000, 0, 0)
            { Name = 'CastleOnTheVoidMansion', Asset = 'CastleOnTheVoidMansion', Origin = Vector3.new(-14600.0, 0.0, 1800.0), DeckY = 46.9, DeckOffsetY = 0.0, Sea = 3, StreamDist = 8500 },
            { Name = 'UmbralCrystalSanctumForest', Asset = 'UmbralCrystalSanctumForest', Origin = Vector3.new(-9400.0, 0.0, 1800.0), DeckY = 46.9, DeckOffsetY = 0.0, Sea = 3, StreamDist = 8500 },
            { Name = 'TempleOfTheCoreRaceV4', Asset = 'TempleOfTheCoreRaceV4', Origin = Vector3.new(-14600.0, 0.0, -1800.0), DeckY = 46.9, DeckOffsetY = 0.0, Sea = 3, StreamDist = 8500 },
            { Name = 'MirageSkyIslandLeviathanAbyss', Asset = 'MirageSkyIslandLeviathanAbyss', Origin = Vector3.new(-12000.0, 0.0, -3400.0), DeckY = 46.9, DeckOffsetY = 0.0, Sea = 3, StreamDist = 8500 },
        }
        local expansionRealms = {
            { Name = 'VerdantCrown', Asset = 'UmbralCrystalSanctumForest', Origin = Vector3.new(0.0, 120.0, -9000.0), DeckY = 166.9 },
            { Name = 'EmberforgeWastes', Asset = 'WestGardenPirateBastion', Origin = Vector3.new(12000.0, 120.0, -9000.0), DeckY = 166.5 },
            { Name = 'AbyssalTides', Asset = 'MirageSkyIslandLeviathanAbyss', Origin = Vector3.new(-12000.0, 120.0, -9000.0), DeckY = 166.9 },
            { Name = 'ChronosBastion', Asset = 'TempleOfTheCoreRaceV4', Origin = Vector3.new(0.0, 180.0, -13500.0), DeckY = 226.9 },
            { Name = 'VeilsEnd', Asset = 'CastleOnTheVoidMansion', Origin = Vector3.new(0.0, 260.0, -18000.0), DeckY = 306.9 },
        }
        workspace:SetAttribute('GrandSkyIslandsV8Ready', true)

        local frozenOrigin = require(game.ReplicatedStorage.Shared.RealmConfig).FrozenCyber.Origin
        local shadowOrigin = require(game.ReplicatedStorage.Shared.RealmConfig).ShadowRealm.Origin

        if sources:FindFirstChild('FrozenCyber') then
            local frozenBase = workspace:FindFirstChild('FrozenCyber_ImportedArt')
            if not (worldsFolder and worldsFolder:FindFirstChild('FrozenCyber_3D')) and not frozenBase then
                local okF, frozen = pcall(Renderer.Build, 'FrozenCyber', progress)
                if okF and frozen then
                    frozenBase = frozen:Clone()
                    frozenBase.Name = 'FrozenCyber_ImportedArt'
                    frozenBase:PivotTo(CFrame.new(frozenOrigin))
                    frozenBase.Parent = workspace
                end
            end
            task.wait(0.06)
            local okP, builtP = pcall(Renderer.Build, 'FrozenPortal', progress)
            if okP and builtP then
                portal = builtP:Clone()
                portal.Name = 'FrozenCyber_AnimatedPortal'
                portal.Parent = workspace
                Equipment3D.AlignSeaTransitionPortal(
                    portal,
                    Vector3.new(42.0, 46.5, -435.0),
                    'FrozenPortal',
                    '[E] Dịch Chuyển Sea 2 • Frozen Cyber',
                    '❄ Cổng Không Gian Sea 2 (Frozen Cyber)',
                    Color3.fromRGB(86, 238, 255)
                )
                local okC, c = pcall(Renderer.Clips, 'FrozenPortal', 1)
                if okC then portalClips = c end
            end
            task.wait(0.06)
        end

        if sources:FindFirstChild('ShadowRealm') then
            local shadowBase = workspace:FindFirstChild('ShadowRealm_ImportedArt')
            if not (worldsFolder and worldsFolder:FindFirstChild('ShadowRealm_3D')) and not shadowBase then
                local okS, shadow = pcall(Renderer.Build, 'ShadowRealm', progress)
                if okS and shadow then
                    shadowBase = shadow:Clone()
                    shadowBase.Name = 'ShadowRealm_ImportedArt'
                    shadowBase:PivotTo(CFrame.new(shadowOrigin))
                    shadowBase.Parent = workspace
                end
            end
            task.wait(0.06)
            local okSP, builtSP = pcall(Renderer.Build, 'ShadowPortal', progress)
            if okSP and builtSP then
                shadowPortal = builtSP:Clone()
                shadowPortal.Name = 'ShadowRealm_AnimatedGate'
                shadowPortal.Parent = workspace
                Equipment3D.AlignSeaTransitionPortal(
                    shadowPortal,
                    Vector3.new(12610.0, 46.9, -475.0),
                    'ShadowPortal',
                    'Dịch Chuyển Sea 3 • Shadow Realm',
                    'Cổng Không Gian Sea 3 (Shadow Realm)',
                    Color3.fromRGB(186, 72, 255)
                )
                local okGC, gateClips = pcall(Renderer.Clips, 'ShadowPortal', 1)
                if okGC and type(gateClips) == 'table' then
                    local _, clip = next(gateClips)
                    shadowPortalClip = clip
                end
            end
            task.wait(0.06)
        end

        task.spawn(Equipment3D.BootWorld, Renderer)

        for _, entry in ipairs(sea2And3Islands) do
            placeGrandIsland(entry)
            task.wait(0.06)
        end

        for _, exp in ipairs(expansionRealms) do
            if sources:FindFirstChild(exp.Asset) then
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
                    applyRealmElementalTheme(expClone, exp.Name)
                    local deckOffY = DECK_OFFSET_Y[exp.Asset] or 0
                    expClone:SetAttribute('DeckSurfaceY', exp.DeckY or exp.Origin.Y)
                    expClone:PivotTo(CFrame.new(exp.Origin - Vector3.new(0, deckOffY, 0)))
                    expClone.Parent = grandIslandsFolder
                end
                task.wait(0.06)
            end
        end
    end)

    local playerConnections = {}

    local function cleanupState(ch, s)
        if s then
            if s.HideConnection then
                s.HideConnection:Disconnect()
                s.HideConnection = nil
            end
            if s.Connections then
                for _, conn in ipairs(s.Connections) do
                    if conn then
                        conn:Disconnect()
                    end
                end
                table.clear(s.Connections)
            end
            s.TransformFX = nil
            if s.Model then
                if s.IsNativeAvatar or s.Model == ch then
                    for _, folderName in ipairs({ 'WeaponAwakeningAura', 'FruitTransformFX', 'HakiAuraFX', 'RaceV4FX', 'HeldFruit3D', 'EquippedWeapons3D', 'CharacterAccessories3D' }) do
                        local f = ch and ch:FindFirstChild(folderName)
                        if f then
                            pcall(function()
                                f:Destroy()
                            end)
                        end
                    end
                else
                    pcall(function()
                        s.Model:Destroy()
                    end)
                end
                s.Model = nil
                s.Visual = nil
            end
        end
        if ch then
            states[ch] = nil
            avatarTickets[ch] = nil
        end
    end

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
        local useCustomClassRig = (ch:GetAttribute('UseCustomClassRig') == true)
            or (owner and owner:GetAttribute('UseCustomClassRig') == true)
        local useNativeAvatar = not useCustomClassRig

        local template
        if not useNativeAvatar then
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
        end
        if ticket ~= avatarTickets[ch] or not ch.Parent then
            return
        end
        if states[ch] then
            cleanupState(ch, states[ch])
        end
        GuardianAnimator.Reset(ch)
        for _, oldVisName in ipairs({ 'SkyGuardianVisual', 'ArcaneMageVisual', 'ThunderStrikerVisual', 'LegacySkyGuardianVisual' }) do
            local oldVis = ch:FindFirstChild(oldVisName)
            if oldVis then
                oldVis:Destroy()
            end
        end

        local visual
        local weld = nil
        local hChildConnection = nil
        local chChildConnection = nil
        local classClips = nil
        local clipAssetName = nil

        if useNativeAvatar then
            visual = ch
            if not h:FindFirstChildOfClass('Animator') then
                local animInst = Instance.new('Animator')
                animInst.Parent = h
            end
            local animateScript = ch:FindFirstChild('Animate')
            if animateScript and animateScript:IsA('BaseScript') then
                animateScript.Disabled = false
            end
            restoreNativeAvatarVisibility(ch)
            if owner and not owner:HasAppearanceLoaded() then
                task.spawn(function()
                    local appDeadline = os.clock() + 8
                    while ch.Parent and owner.Parent and not owner:HasAppearanceLoaded() and os.clock() < appDeadline do
                        task.wait(0.15)
                    end
                    if ch.Parent and states[ch] and states[ch].IsNativeAvatar then
                        local isBeastNow = states[ch].TransformFX and states[ch].TransformFX.V5Model and states[ch].TransformFX.V5Model.Parent ~= nil
                        if not isBeastNow then
                            restoreNativeAvatarVisibility(ch)
                        end
                    end
                end)
            end
        else
            visual = template:Clone()
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
            weld = Instance.new('WeldConstraint')
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
            hChildConnection = h.ChildAdded:Connect(function(child)
                if child:IsA('Animator') then
                    task.defer(function()
                        if child.Parent then
                            child:Destroy()
                        end
                    end)
                end
            end)
            chChildConnection = ch.ChildAdded:Connect(function(child)
                if child.Name == 'Animate' and child:IsA('LocalScript') then
                    child.Enabled = false
                    task.defer(function()
                        if child.Parent then
                            child:Destroy()
                        end
                    end)
                end
            end)

            if class == 'ArcaneMage' then
                clipAssetName = 'ArcaneMage'
                classClips = getScaledClips('ArcaneMage', 2.6)
            elseif class == 'ThunderStriker' then
                clipAssetName = (gender == 'Female' and sources:FindFirstChild('ThunderStrikerFemale')) and 'ThunderStrikerFemale' or 'ThunderStriker'
                classClips = getScaledClips(clipAssetName, 2.6)
            elseif class == 'SkyGuardian' then
                local sgAsset = sources:FindFirstChild(gender .. '_' .. stage) and (gender .. '_' .. stage)
                    or ((gender == 'Female' and sources:FindFirstChild('Female_SkyGuardian')) and 'Female_SkyGuardian' or 'Male_SkyGuardian')
                clipAssetName = sgAsset
                if sources[sgAsset]:FindFirstChild('Clips') then
                    classClips = getScaledClips(sgAsset, 2.6)
                end
            end
        end

        local stateEntry = {
            Model = visual,
            Visual = visual,
            Weld = weld,
            IsNativeAvatar = useNativeAvatar,
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
            SpawnedAt = os.clock(),
            NativeRaceV4Toggled = (ch:GetAttribute('NativeRaceV4Toggled') == true),
        }

        local weaponParts = {}
        for _, part in visual:GetDescendants() do
            if part:IsA('BasePart') and part:GetAttribute('EquipmentRole') == 'Weapon' then
                table.insert(weaponParts, part)
            end
        end
        stateEntry.WeaponParts = weaponParts

        local function equip()
            for _, part in ipairs(weaponParts) do
                if part and part.Parent then
                    part.LocalTransparencyModifier = 1
                    part.Transparency = 1
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
        local hakiColorConnection = ch:GetAttributeChangedSignal('HakiColorRGB'):Connect(function()
            if stateEntry.HakiAura then
                buildHakiAuraFX(stateEntry, true)
            end
        end)
        local hakiStageConnection = ch:GetAttributeChangedSignal('HakiStage'):Connect(function()
            if stateEntry.HakiAura then
                buildHakiAuraFX(stateEntry, true)
            end
        end)
        local raceConnection = ch:GetAttributeChangedSignal('RaceV4'):Connect(function()
            local rv = tostring(ch:GetAttribute('RaceV4') or '')
            if rv ~= stateEntry.RaceV4 then
                buildRaceV4FX(stateEntry, rv)
            end
        end)

        local stateConns = {
            chEnhanceConnection,
            transformConnection,
            hakiConnection,
            hakiColorConnection,
            hakiStageConnection,
            raceConnection,
        }
        if hChildConnection then
            table.insert(stateConns, hChildConnection)
        end
        if chChildConnection then
            table.insert(stateConns, chChildConnection)
        end
        if equipmentConnection then
            table.insert(stateConns, equipmentConnection)
        end
        if enhanceConnection then
            table.insert(stateConns, enhanceConnection)
        end
        stateEntry.Connections = stateConns

        visual.Destroying:Once(function()
            for _, conn in ipairs(stateConns) do
                if conn then
                    conn:Disconnect()
                end
            end
            table.clear(stateConns)
        end)

        if useNativeAvatar then
            ch:SetAttribute('BlenderGuardian', false)
            local connection = ch.DescendantAdded:Connect(function(o)
                task.defer(function()
                    if not o or not o.Parent or not ch.Parent then
                        return
                    end
                    if isInsideManagedFXContainer(o, ch) then
                        return
                    end
                    local isBeastNow = stateEntry.TransformFX and stateEntry.TransformFX.V5Model and stateEntry.TransformFX.V5Model.Parent ~= nil
                    if o:IsA('BasePart') then
                        stateEntry._EquipBindReady = nil
                        if LEGACY_SERVER_PLACEHOLDERS[o.Name] or o:GetAttribute('EquipmentRole') == 'Weapon' then
                            o.Transparency = 1
                        elseif isBeastNow then
                            o.LocalTransparencyModifier = 1
                        else
                            o.Transparency = 0
                            o.LocalTransparencyModifier = 0
                        end
                    elseif o:IsA('Decal') then
                        o.Transparency = isBeastNow and 1 or 0
                    end
                end)
            end)
            stateEntry.HideConnection = connection
        else
            ch:SetAttribute('BlenderGuardian', (class == 'SkyGuardian') and (not classClips or not next(classClips)))
            hideLegacy(ch, visual)
            local connection = ch.DescendantAdded:Connect(function(o)
                if o:IsA('BasePart') and not o:IsDescendantOf(visual) then
                    o.Transparency = 1
                end
            end)
            stateEntry.HideConnection = connection
        end
        states[ch] = stateEntry

        ch:SetAttribute('V5Visual', useNativeAvatar and 'NativeAvatar' or class)
        ch:SetAttribute('V5VisualReady', true)
        ch:SetAttribute('V7AppearanceKey', (useNativeAvatar and 'NativeAvatar' or class) .. '/' .. gender .. '/' .. stage)
    end

    local function bindPlayer(p)
        if playerConnections[p] then
            return
        end
        local pConns = {}
        playerConnections[p] = pConns
        table.insert(pConns, p.CharacterAdded:Connect(function(ch)
            task.spawn(avatar, ch)
        end))
        table.insert(pConns, p.CharacterRemoving:Connect(function(ch)
            if states[ch] then
                cleanupState(ch, states[ch])
            else
                avatarTickets[ch] = nil
            end
        end))
        table.insert(pConns, p:GetAttributeChangedSignal('SkybornGender'):Connect(function()
            if p.Character then
                task.spawn(avatar, p.Character)
            end
        end))
        table.insert(pConns, p:GetAttributeChangedSignal('ClassId'):Connect(function()
            if p.Character then
                task.spawn(avatar, p.Character)
            end
        end))
        table.insert(pConns, p:GetAttributeChangedSignal('OutfitStage'):Connect(function()
            if p.Character then
                task.spawn(avatar, p.Character)
            end
        end))
        if p.Character then
            task.spawn(avatar, p.Character)
        end
    end

    for _, p in Players:GetPlayers() do
        bindPlayer(p)
    end
    Players.PlayerAdded:Connect(bindPlayer)
    Players.PlayerRemoving:Connect(function(p)
        local pConns = playerConnections[p]
        if pConns then
            for _, conn in ipairs(pConns) do
                conn:Disconnect()
            end
            playerConnections[p] = nil
        end
        for ch, s in pairs(states) do
            if s.Owner == p or ch == p.Character then
                cleanupState(ch, s)
            end
        end
    end)

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

    local cachedBossTemplate = nil
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
            local refPos = cam and cam.CFrame.Position or Vector3.new(-317.4, 50.5, 527.8)
            if (body.Position - refPos).Magnitude <= 2600 then
                break
            end
            task.wait(0.5)
        end
        if not model.Parent or not body.Parent or bosses[model] then
            return
        end
        if not cachedBossTemplate then
            cachedBossTemplate = Renderer.Build('AureonSentinel', progress)
            local _, bossSize = cachedBossTemplate:GetBoundingBox()
            bossScale = 22 / math.max(1, bossSize.Y)
            bossClips = Renderer.Clips('AureonSentinel', bossScale)
        end
        local visual = cachedBossTemplate:Clone()
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

    local function resolveSkillElementColors(element, skillId)
        local el = tostring(element or '')
        local sid = tostring(skillId or '')
        if el == 'Frost' or sid:find('Frost') or sid:find('Ice') or sid:find('Glacial') or sid:find('Rune') or sid:find('Arcane') then
            return Color3.fromRGB(92, 238, 255), Color3.fromRGB(215, 252, 255), Color3.fromRGB(36, 125, 235)
        elseif el == 'Lightning' or sid:find('Thunder') or sid:find('Storm') or sid:find('Twin') or sid:find('Flash') or sid:find('Spinning') then
            return Color3.fromRGB(68, 205, 255), Color3.fromRGB(195, 118, 255), Color3.fromRGB(228, 250, 255)
        elseif el == 'Void' or sid:find('Void') or sid:find('Abyss') or sid:find('Shadow') then
            return Color3.fromRGB(178, 42, 255), Color3.fromRGB(255, 48, 145), Color3.fromRGB(48, 16, 82)
        elseif el == 'Flame' or el == 'Fire' or sid:find('Flame') or sid:find('Fire') or sid:find('Magma') then
            return Color3.fromRGB(255, 98, 42), Color3.fromRGB(255, 218, 78), Color3.fromRGB(185, 32, 42)
        else
            return Color3.fromRGB(255, 216, 92), Color3.fromRGB(108, 238, 255), Color3.fromRGB(255, 248, 195)
        end
    end

    local function spawnCharacterSkillRigTrail(s, moveKey, fx)
        if not s or not s.Visual or not s.Visual.Parent or not s.Root or not s.Root.Parent then
            return
        end
        local TweenService = game:GetService('TweenService')
        local Debris = game:GetService('Debris')
        local tempFolder = workspace:FindFirstChild('TempFX')
        if not tempFolder then
            tempFolder = Instance.new('Folder')
            tempFolder.Name = 'TempFX'
            tempFolder.Parent = workspace
        end

        local primary, secondary, accent = resolveSkillElementColors(fx.element or fx.Element, fx.skillId or fx.Action)
        local activeRig = (s.TransformFX and s.TransformFX.V5Model and s.TransformFX.V5Model.Parent) and s.TransformFX.V5Model or s.Visual
        local fid = tostring(fx.activeId or fx.FruitId or fx.fruitId or '')
        if fid == 'AbyssalSovereignCore' or s.FruitTransform == 'AbyssalSovereign' or s.FruitTransform == 'AbyssalDragonHybrid' then
            primary, secondary, accent = Color3.fromRGB(255, 46, 150), Color3.fromRGB(168, 38, 255), Color3.fromRGB(20, 12, 36)
        elseif fid == 'GaleCore' then
            primary, secondary, accent = Color3.fromRGB(115, 255, 210), Color3.fromRGB(220, 255, 245), Color3.fromRGB(48, 205, 165)
        elseif fid == 'SandstoneCore' then
            primary, secondary, accent = Color3.fromRGB(238, 192, 92), Color3.fromRGB(255, 232, 152), Color3.fromRGB(168, 118, 42)
        elseif fid == 'SolarFlameCore' then
            primary, secondary, accent = Color3.fromRGB(255, 96, 36), Color3.fromRGB(255, 224, 72), Color3.fromRGB(210, 28, 38)
        elseif fid == 'GlacierIceCore' then
            primary, secondary, accent = Color3.fromRGB(82, 236, 255), Color3.fromRGB(220, 252, 255), Color3.fromRGB(28, 112, 232)
        elseif fid == 'CelestialLightCore' then
            primary, secondary, accent = Color3.fromRGB(255, 238, 112), Color3.fromRGB(255, 255, 215), Color3.fromRGB(255, 188, 42)
        elseif fid == 'StarforgedMagmaCore' then
            primary, secondary, accent = Color3.fromRGB(235, 38, 22), Color3.fromRGB(255, 142, 28), Color3.fromRGB(48, 18, 18)
        elseif fid == 'ThunderRumbleCore' then
            primary, secondary, accent = Color3.fromRGB(58, 188, 255), Color3.fromRGB(182, 92, 255), Color3.fromRGB(230, 248, 255)
        elseif fid == 'AstralGravityCore' then
            primary, secondary, accent = Color3.fromRGB(158, 52, 255), Color3.fromRGB(232, 118, 255), Color3.fromRGB(38, 14, 68)
        elseif fid == 'DimensionalPortalCore' then
            primary, secondary, accent = Color3.fromRGB(64, 242, 255), Color3.fromRGB(168, 72, 255), Color3.fromRGB(18, 32, 68)
        elseif fid == 'SolarTitanCore' or s.FruitTransform == 'SolarTitan' then
            primary, secondary, accent = Color3.fromRGB(255, 212, 64), Color3.fromRGB(255, 248, 178), Color3.fromRGB(235, 142, 28)
        elseif fid == 'AetherflowCore' then
            primary, secondary, accent = Color3.fromRGB(255, 242, 215), Color3.fromRGB(255, 38, 92), Color3.fromRGB(24, 14, 32)
        end
        local rHandBone = findBone(activeRig, { 'Paw_FR', 'Forearm_FR', 'RightHand', 'RightLowerArm', 'RightArm', 'RightBlade', 'Leg_FR', 'WingForearm_R', 'Wing_R_03', 'Wing_R_02', 'DragonWing_R_02' })
        local lHandBone = findBone(activeRig, { 'Paw_FL', 'Forearm_FL', 'LeftHand', 'LeftLowerArm', 'LeftArm', 'LeftBlade', 'Leg_FL', 'WingForearm_L', 'Wing_L_03', 'Wing_L_02', 'DragonWing_L_02' })
        local torsoBone = findBone(activeRig, { 'FX_BreathCore', 'FX_CrownHalo', 'Jaw', 'Head', 'UpperTorso', 'Spine_02', 'Spine', 'Torso', 'FX_Vortex' })

        local durMap = { Z = 0.68, X = 0.80, C = 0.94, V = 1.12, F = 0.72 }
        local duration = durMap[moveKey] or 0.75

        local trailFolder = Instance.new('Folder')
        trailFolder.Name = 'SkillRigTrail_' .. tostring(moveKey)
        trailFolder.Parent = tempFolder
        Debris:AddItem(trailFolder, duration + 0.45)

        local rOrb = makeAuraPart(trailFolder, 'RightHandSkillOrb', Vector3.new(0.85, 0.85, 0.85), primary, Enum.PartType.Ball, 0.12)
        local rRing = makeAuraPart(trailFolder, 'RightHandSkillRing', Vector3.new(0.14, 1.55, 1.55), secondary, Enum.PartType.Cylinder, 0.16)
        local lOrb = makeAuraPart(trailFolder, 'LeftHandSkillOrb', Vector3.new(0.75, 0.75, 0.75), secondary, Enum.PartType.Ball, 0.16)
        local lRing = makeAuraPart(trailFolder, 'LeftHandSkillRing', Vector3.new(0.12, 1.35, 1.35), accent, Enum.PartType.Cylinder, 0.20)

        local startAt = os.clock()
        local lastRibbonAt = 0
        local lastRPos = nil
        local lastLPos = nil
        local stepIdx = 0

        local conn
        conn = Run.RenderStepped:Connect(function()
            local now = os.clock()
            local elapsed = now - startAt
            if elapsed >= duration or not s.Visual or not s.Visual.Parent or not s.Root or not s.Root.Parent or not trailFolder.Parent then
                if conn then
                    conn:Disconnect()
                    conn = nil
                end
                if rOrb and rOrb.Parent then rOrb:Destroy() end
                if rRing and rRing.Parent then rRing:Destroy() end
                if lOrb and lOrb.Parent then lOrb:Destroy() end
                if lRing and lRing.Parent then lRing:Destroy() end
                return
            end

            local rCF = getBoneWorldCF(s, rHandBone, CFrame.new(1.3, 0.4, -0.9))
            local lCF = getBoneWorldCF(s, lHandBone, CFrame.new(-1.3, 0.4, -0.9))
            local tCF = getBoneWorldCF(s, torsoBone, CFrame.new(0, 0.8, 0))
            local spin = elapsed * 16

            -- Offset slightly toward weapon tip on right hand
            local rTipPos = (rCF * CFrame.new(0, 0, -1.25)).Position
            local lTipPos = (lCF * CFrame.new(0, 0, -0.95)).Position

            if rOrb and rOrb.Parent then
                local pulse = 0.85 + 0.35 * math.sin(elapsed * 22)
                rOrb.Size = Vector3.new(pulse, pulse, pulse)
                rOrb.CFrame = rCF
                rRing.CFrame = rCF * CFrame.Angles(spin, math.pi * 0.5, 0)
            end
            if lOrb and lOrb.Parent then
                local pulse = 0.72 + 0.28 * math.cos(elapsed * 22)
                lOrb.Size = Vector3.new(pulse, pulse, pulse)
                lOrb.CFrame = lCF
                lRing.CFrame = lCF * CFrame.Angles(-spin, math.pi * 0.5, 0)
            end

            if now - lastRibbonAt >= 0.032 then
                lastRibbonAt = now
                stepIdx += 1
                if lastRPos then
                    local segVec = rTipPos - lastRPos
                    local segLen = math.clamp(segVec.Magnitude, 0.45, 5.5)
                    local mid = (rTipPos + lastRPos) * 0.5
                    local look = segVec.Magnitude > 0.05 and CFrame.lookAt(mid, rTipPos) or rCF
                    local rib = makeAuraPart(
                        trailFolder,
                        'RSlashRibbon_' .. stepIdx,
                        Vector3.new(0.22, 0.55, segLen + 0.35),
                        stepIdx % 2 == 0 and primary or secondary,
                        Enum.PartType.Block,
                        0.12
                    )
                    rib.CFrame = look
                    TweenService:Create(rib, TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = Vector3.new(0.05, 1.15, segLen + 0.55),
                        Transparency = 1,
                    }):Play()
                    game:GetService('Debris'):AddItem(rib, 0.28)
                end
                if lastLPos and (moveKey == 'X' or moveKey == 'C' or moveKey == 'V' or moveKey == 'F') then
                    local segVecL = lTipPos - lastLPos
                    local segLenL = math.clamp(segVecL.Magnitude, 0.4, 5.0)
                    local midL = (lTipPos + lastLPos) * 0.5
                    local lookL = segVecL.Magnitude > 0.05 and CFrame.lookAt(midL, lTipPos) or lCF
                    local ribL = makeAuraPart(
                        trailFolder,
                        'LSlashRibbon_' .. stepIdx,
                        Vector3.new(0.18, 0.45, segLenL + 0.3),
                        stepIdx % 2 == 0 and secondary or accent,
                        Enum.PartType.Block,
                        0.16
                    )
                    ribL.CFrame = lookL
                    TweenService:Create(ribL, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = Vector3.new(0.04, 0.95, segLenL + 0.45),
                        Transparency = 1,
                    }):Play()
                    game:GetService('Debris'):AddItem(ribL, 0.26)
                end
                if moveKey == 'X' or moveKey == 'C' or moveKey == 'V' then
                    local orbitAng = elapsed * 18 + stepIdx * 1.1
                    local orbitR = (moveKey == 'V' and 3.4 or 2.4)
                    local oPos = tCF.Position + Vector3.new(math.cos(orbitAng) * orbitR, math.sin(elapsed * 10) * 1.2, math.sin(orbitAng) * orbitR)
                    local oTang = oPos + Vector3.new(-math.sin(orbitAng), 0.35, math.cos(orbitAng))
                    local wisp = makeAuraPart(trailFolder, 'BodyWisp_' .. stepIdx, Vector3.new(0.18, 0.26, 2.2), stepIdx % 2 == 0 and primary or accent, Enum.PartType.Block, 0.15)
                    wisp.CFrame = CFrame.lookAt(oPos, oTang)
                    TweenService:Create(wisp, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = Vector3.new(0.04, 0.08, 3.2),
                        Transparency = 1,
                    }):Play()
                    game:GetService('Debris'):AddItem(wisp, 0.30)
                end
                lastRPos = rTipPos
                lastLPos = lTipPos
            end
        end)
    end

    local function handleCombatClip(fx)
        if type(fx) ~= 'table' then
            return
        end
        local p = nil
        if fx.Actor then
            p = Players:GetPlayerByUserId(fx.Actor)
        elseif fx.userId then
            p = Players:GetPlayerByUserId(fx.userId)
        elseif fx.source then
            p = Players:FindFirstChild(tostring(fx.source))
        end
        local ch = p and p.Character
        local s = ch and states[ch]
        if not s then
            return
        end
        local action = tostring(fx.Action or fx.action or fx.skillId or fx.MoveName or '')
        local kind = tostring(fx.Kind or fx.kind or '')
        local moveKey = string.upper(tostring(fx.key or fx.moveKey or fx.MoveKey or ''))
        if moveKey == '' then
            moveKey = action:match('^Skill([ZXCVF])$') or action:match('^Fruit([ZXCVF])$') or action:match('_([ZXCVF])$') or ''
        end
        if kind == 'DragonTransform' then
            if (tonumber(fx.DragonFormTier) or 1) <= 0 then
                return
            end
            if moveKey == '' then
                moveKey = 'V'
            end
        end
        if (kind == 'StyleMove' or kind == 'GunShot') and moveKey == 'M1' then
            kind = 'Swing'
            if action == '' then
                action = 'Attack'
            end
            moveKey = ''
        elseif kind == 'ChargedSlash' and moveKey == '' then
            action = 'Heavy'
            kind = 'Swing'
        end

        if moveKey == 'Z' or moveKey == 'X' or moveKey == 'C' or moveKey == 'V' or moveKey == 'F' then
            task.spawn(spawnCharacterSkillRigTrail, s, moveKey, fx)
        end

        if not s.Clips or not next(s.Clips) then
            local nowAct = os.clock()
            local rawKind = tostring(fx.Kind or fx.kind or '')
            local slotNum = tonumber(fx.slot or fx.Slot or (ch and ch:GetAttribute('ActiveSlot')) or (p and p:GetAttribute('ActiveSlot'))) or 3
            local comboIdx = math.clamp(tonumber(fx.Combo or fx.combo) or 1, 1, 3)
            local targetName = 'Attack0' .. comboIdx
            local targetDur = 0.44
            if moveKey ~= '' then
                targetName = 'Skill' .. moveKey
                targetDur = moveKey == 'V' and 0.92 or (moveKey == 'C' and 0.78 or 0.64)
            elseif action == 'Heavy' or action == 'JudgmentStrike' or action == 'CelestialAegis' or rawKind == 'ChargedSlash' then
                targetName = 'Heavy'
                targetDur = 0.58
            elseif kind == 'Dodge' or action == 'Dash' or action == 'Dodge' or action == 'FlashStep' then
                targetName = 'Dash'
                targetDur = 0.44
            elseif rawKind == 'GunShot' or slotNum == 4 then
                targetName = 'GunShoot'
                targetDur = 0.36
            elseif rawKind == 'StyleMove' or slotNum == 1 then
                targetName = 'StyleAttack0' .. comboIdx
                targetDur = 0.42
            end
            if not (s.IsNativeAvatar and s.Name == targetName and (nowAct - (s.Start or 0)) < 0.18) then
                s.Name = targetName
                s.Start = nowAct
                s.Until = nowAct + targetDur
            end
            if not s.IsNativeAvatar and s.ClassId == 'SkyGuardian' then
                if action == 'Skill3' or action == 'JudgmentStrike' or action == 'ConquerorHaki' or moveKey == 'C' or moveKey == 'X' then
                    GuardianAnimator.Action(ch, 'Heavy', fx.Combo)
                elseif action == 'Ultimate' or action == 'CelestialAegis' or moveKey == 'V' or moveKey == 'Z' or kind == 'Skill' then
                    GuardianAnimator.Action(ch, 'SkySlash', fx.Combo)
                elseif kind == 'Swing' or action == 'Attack' or action == 'Heavy' then
                    GuardianAnimator.Action(ch, action == 'Heavy' and 'Heavy' or 'Attack', fx.Combo)
                elseif kind == 'Dodge' or action == 'Dodge' or action == 'Dash' or moveKey == 'F' then
                    GuardianAnimator.Action(ch, 'Dash', fx.Combo)
                end
            end
            return
        end

        -- Bespoke Devil Fruit Caster Clips (FruitZ..FruitF) & Novice/Weapon/Style Skill Clips (SkillZ..SkillF)
        if moveKey == 'Z' or moveKey == 'X' or moveKey == 'C' or moveKey == 'V' or moveKey == 'F' then
            local isFruitSlot = (tonumber(fx.slot) == 2)
                or (tonumber(fx.Slot) == 2)
                or (kind == 'FruitMove')
                or (kind == 'DragonTransform')
                or (fx.FruitId ~= nil)
                or (fx.fruitId ~= nil)
                or (action:sub(1, 5) == 'Fruit')
                or (s.FruitTransform ~= '')
            local preferredName = isFruitSlot and ('Fruit' .. moveKey) or ('Skill' .. moveKey)
            local fallbackName = 'Skill' .. moveKey
            local bespokeClip = s.Clips[preferredName] or s.Clips[fallbackName]
            local chosenName = s.Clips[preferredName] and preferredName or fallbackName
            if bespokeClip then
                local v5OverrideDur = nil
                if s.TransformFX and s.TransformFX.V5Clips and s.TransformFX.V5Clips[preferredName] then
                    v5OverrideDur = s.TransformFX.V5Clips[preferredName].Duration
                end
                s.Name = chosenName
                s.Start = os.clock()
                s.Until = s.Start + math.max(0.62, v5OverrideDur or bespokeClip.Duration or 0.85)
                return
            end
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
        elseif (action == 'ConquerorHaki' or action == 'RaceV4Awaken' or action == 'BeastTransform' or kind == 'DragonTransform') and s.Clips.UltimateAwakening then
            s.Name = 'UltimateAwakening'
            s.Start = os.clock()
            s.Until = s.Start + math.max(0.85, s.Clips.UltimateAwakening.Duration or 1.35)
            return
        end

        if s.ClassId == 'SkyGuardian' then
            local targetClip = nil
            local comboIdx = math.clamp(tonumber(fx.Combo) or 1, 1, 3)
            if kind == 'Shield' or action == 'Skill2' or action == 'GuardianShield' then
                targetClip = s.Clips.ShieldRaise and 'ShieldRaise' or 'ShieldLoop'
            elseif kind == 'Dodge' or action == 'Dodge' or action == 'Dash' or moveKey == 'F' then
                targetClip = action == 'Dash' and 'Dash' or 'Dodge'
            elseif moveKey == 'C' and (s.Clips.FruitC or s.Clips.SkillC or s.Clips.CelestialAegis) then
                targetClip = (s.FruitTransform ~= '' and s.Clips.FruitC and 'FruitC') or (s.Clips.SkillC and 'SkillC') or 'CelestialAegis'
            elseif action == 'JudgmentStrike' or action == 'Skill3' or moveKey == 'X' then
                targetClip = s.Clips.JudgmentStrike and 'JudgmentStrike' or 'Heavy'
            elseif action == 'CelestialAegis' or action == 'Ultimate' or moveKey == 'V' then
                targetClip = s.Clips.CelestialAegis and 'CelestialAegis' or 'UltimateAwakening'
            elseif action == 'ConquerorHaki' and s.Clips.HakiAwaken then
                targetClip = 'HakiAwaken'
            elseif action == 'Heavy' and s.Clips.Heavy then
                targetClip = 'Heavy'
            elseif kind == 'Skill' or action == 'Skill1' or action == 'SkySlash' or moveKey == 'Z' then
                targetClip = s.Clips.SkySlash and 'SkySlash' or 'Skill'
            elseif kind == 'Swing' or action == 'Attack' then
                local comboClip = string.format('Attack0%d', comboIdx)
                targetClip = (s.Clips[comboClip] and comboClip) or (s.Clips.Attack and 'Attack') or 'SkySlash'
            end
            if targetClip and s.Clips[targetClip] then
                s.Name = targetClip
                s.Start = os.clock()
                s.Until = s.Start + math.max(0.42, s.Clips[targetClip].Duration or 0.55)
            end
            return
        end

        if s.ClassId == 'ArcaneMage' then
            local targetClip = nil
            local comboIdx = math.clamp(tonumber(fx.Combo) or 1, 1, 3)
            if kind == 'Shield' or action == 'Skill2' or action == 'ManaBarrier' then
                targetClip = 'ManaBarrier'
            elseif kind == 'Dodge' or action == 'Dodge' or action == 'Dash' or moveKey == 'F' then
                targetClip = action == 'Dash' and 'Dash' or 'Dodge'
            elseif moveKey == 'C' and (s.Clips.FruitC or s.Clips.SkillC or s.Clips.FrostNova) then
                targetClip = (s.FruitTransform ~= '' and s.Clips.FruitC and 'FruitC') or (s.Clips.SkillC and 'SkillC') or 'FrostNova'
            elseif action == 'Heavy' or action == 'Skill3' or action == 'ArcaneComet' or moveKey == 'X' then
                targetClip = s.Clips.ArcaneCircle and 'ArcaneCircle' or 'FrostNova'
            elseif action == 'Ultimate' or action == 'AstralCataclysm' or action == 'ConquerorHaki' or moveKey == 'V' then
                targetClip = 'FrostNova'
            elseif kind == 'Skill' or action == 'Skill1' or action == 'FrostBolt' or moveKey == 'Z' then
                targetClip = 'FrostBolt'
            elseif kind == 'Swing' or action == 'Attack' then
                local comboClip = string.format('Attack0%d', comboIdx)
                targetClip = (s.Clips[comboClip] and comboClip) or 'FrostBolt'
            end
            if targetClip and s.Clips[targetClip] then
                s.Name = targetClip
                s.Start = os.clock()
                s.Until = s.Start + math.max(0.42, s.Clips[targetClip].Duration)
            end
            return
        end

        if s.ClassId == 'ThunderStriker' then
            local targetClip = nil
            local comboIdx = math.clamp(tonumber(fx.Combo) or 1, 1, 3)
            if action == 'FlashStep' and s.Clips.FlashStep then
                targetClip = 'FlashStep'
            elseif (kind == 'Dodge' or action == 'Dodge') and s.Clips.Dodge then
                targetClip = 'Dodge'
            elseif kind == 'Dodge' or action == 'Dodge' or action == 'Dash' or action == 'Skill2' or action == 'FlashStep' or moveKey == 'F' then
                targetClip = s.Clips.TS_Dash and 'TS_Dash' or 'Dash'
            elseif (action == 'ArcCut' or action == 'Skill1' or moveKey == 'Z') and s.Clips.ArcCut then
                targetClip = 'ArcCut'
            elseif moveKey == 'C' and (s.Clips.FruitC or s.Clips.SkillC or s.Clips.ThunderJudgement) then
                targetClip = (s.FruitTransform ~= '' and s.Clips.FruitC and 'FruitC') or (s.Clips.SkillC and 'SkillC') or 'ThunderJudgement'
            elseif (action == 'StormBlitz' or action == 'Skill3' or moveKey == 'X') and s.Clips.StormBlitz then
                targetClip = 'StormBlitz'
            elseif (action == 'ThunderJudgement' or action == 'Ultimate' or moveKey == 'V') and s.Clips.ThunderJudgement then
                targetClip = 'ThunderJudgement'
            elseif action == 'ConquerorHaki' and s.Clips.HakiAwaken then
                targetClip = 'HakiAwaken'
            elseif action == 'Heavy' and s.Clips.Heavy then
                targetClip = 'Heavy'
            elseif kind == 'Swing' or action == 'Attack' then
                local comboClip = string.format('Attack0%d', comboIdx)
                if s.Clips[comboClip] then
                    targetClip = comboClip
                end
            end
            if targetClip and s.Clips[targetClip] then
                s.Name = targetClip
                s.Start = os.clock()
                s.Until = s.Start + math.max(0.42, s.Clips[targetClip].Duration or 0.55)
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
                s.Until = os.clock() + (fullCombo and 1.35 or 0.55)
            end
        end
    end

    remotes.CombatFX.OnClientEvent:Connect(handleCombatClip)
    local combatEvent = remotes:FindFirstChild('CombatEvent')
    if combatEvent and combatEvent:IsA('RemoteEvent') then
        combatEvent.OnClientEvent:Connect(handleCombatClip)
    end

    local NATIVE_JOINT_ROLE_MAP = {
        Root = 'Root',
        RootJoint = 'Root',
        Waist = 'Waist',
        Neck = 'Neck',
        RightShoulder = 'RightShoulder',
        ['Right Shoulder'] = 'RightShoulder',
        RightElbow = 'RightElbow',
        RightWrist = 'RightWrist',
        LeftShoulder = 'LeftShoulder',
        ['Left Shoulder'] = 'LeftShoulder',
        LeftElbow = 'LeftElbow',
        LeftWrist = 'LeftWrist',
        RightHip = 'RightHip',
        ['Right Hip'] = 'RightHip',
        RightKnee = 'RightKnee',
        LeftHip = 'LeftHip',
        ['Left Hip'] = 'LeftHip',
        LeftKnee = 'LeftKnee',
    }

    local function ensureNativeJoints(s)
        local ch = s and s.Character
        if not ch or not ch.Parent then
            return nil
        end
        if s.NativeJoints and s.NativeJoints.RightShoulder and s.NativeJoints.RightShoulder.Joint and s.NativeJoints.RightShoulder.Joint.Parent then
            return s.NativeJoints
        end
        local joints = {}
        s.NativeJointOffsets = s.NativeJointOffsets or {}
        for _, d in ipairs(ch:GetDescendants()) do
            if d:IsA('Motor6D') and not isInsideManagedFXContainer(d, ch) then
                local role = NATIVE_JOINT_ROLE_MAP[d.Name]
                if role and not joints[role] then
                    if not d:GetAttribute('SkybreakOrigC0') then
                        d:SetAttribute('SkybreakOrigC0', d.C0)
                    end
                    local origC0 = d:GetAttribute('SkybreakOrigC0') or d.C0
                    joints[role] = {
                        Joint = d,
                        BaseC0 = origC0,
                    }
                    s.NativeJointOffsets[role] = s.NativeJointOffsets[role] or CFrame.identity
                end
            end
        end
        s.NativeJoints = joints
        return joints
    end

    local function stepNativeAvatarAnimation(s, dt, now)
        local ch = s.Character
        if not ch or not ch.Parent or not s.H or not s.Root then
            return
        end
        local animator = s.H:FindFirstChildOfClass('Animator')
        if not animator then
            animator = Instance.new('Animator')
            animator.Parent = s.H
        end
        local animScript = ch:FindFirstChild('Animate')
        if animScript and animScript:IsA('BaseScript') and animScript.Disabled then
            animScript.Disabled = false
        end

        local isBeastNow = s.TransformFX and s.TransformFX.V5Model and s.TransformFX.V5Model.Parent ~= nil
        if not isBeastNow then
            local age = now - (s.SpawnedAt or 0)
            local allowFallback = (age > 3.5) or (s.Owner ~= nil and s.Owner:HasAppearanceLoaded())
            if age < 10.0 or now >= (s.NextVisCheckAt or 0) then
                s.NextVisCheckAt = now + 0.2
                restoreNativeAvatarVisibility(ch, allowFallback)
            end
        end

        if ch:GetAttribute('NativeRaceV4Toggled') == true and not s.NativeRaceV4Toggled then
            s.NativeRaceV4Toggled = true
            local rv = tostring(ch:GetAttribute('RaceV4') or (s.Owner and s.Owner:GetAttribute('RaceV4')) or '')
            if rv ~= '' then
                buildRaceV4FX(s, rv)
            end
        end

        local mode = s.H:GetState()
        local vel = s.Root.AssemblyLinearVelocity
        local hSpeed = math.max(Vector3.new(vel.X, 0, vel.Z).Magnitude, s.H.MoveDirection.Magnitude * s.H.WalkSpeed)
        local airborne = (mode == Enum.HumanoidStateType.Jumping or mode == Enum.HumanoidStateType.Freefall)
        local activeSlot = tonumber(ch:GetAttribute('ActiveSlot') or ch:GetAttribute('EquippedSlot')
            or (s.Owner and (s.Owner:GetAttribute('ActiveSlot') or s.Owner:GetAttribute('EquippedSlot')))) or 3

        -- 1. Instant 0ms Client Input Detection (Attacks, Skills, Dash, Geppo Double-Jump)
        local lastClientAtk = tonumber(ch:GetAttribute('LastClientAttackAt')) or 0
        if lastClientAtk > (s.LastClientAttackAt or 0) then
            s.LastClientAttackAt = lastClientAtk
            local isHeavy = ch:GetAttribute('LastClientAttackHeavy') == true
            local comboIdx = math.clamp(tonumber(ch:GetAttribute('LastClientAttackCombo')) or 1, 1, 3)
            s.Start = now
            if isHeavy then
                s.Name = 'Heavy'
                s.Until = now + 0.56
            elseif activeSlot == 4 then
                s.Name = 'GunShoot'
                s.Until = now + 0.36
            elseif activeSlot == 1 then
                s.Name = 'StyleAttack0' .. comboIdx
                s.Until = now + 0.42
            else
                s.Name = 'Attack0' .. comboIdx
                s.Until = now + 0.44
            end
        end

        local lastClientSkill = tonumber(ch:GetAttribute('LastClientSkillAt')) or 0
        if lastClientSkill > (s.LastClientSkillAt or 0) then
            s.LastClientSkillAt = lastClientSkill
            local sKey = string.upper(tostring(ch:GetAttribute('LastClientSkillKey') or 'Z'))
            s.Name = 'Skill' .. sKey
            s.Start = now
            s.Until = now + (sKey == 'V' and 0.92 or (sKey == 'C' and 0.78 or 0.64))
        end

        local lastDashAt = tonumber(ch:GetAttribute('LastDashAt')) or 0
        if lastDashAt > (s.LastDashAt or 0) then
            s.LastDashAt = lastDashAt
            s.Name = 'Dash'
            s.Start = now
            s.Until = now + math.max(0.38, tonumber(ch:GetAttribute('DashDuration')) or 0.42)
        end

        local lastAirJump = tonumber(ch:GetAttribute('LastAirJumpAt')) or 0
        if lastAirJump > (s.LastAirJumpAt or 0) then
            s.LastAirJumpAt = lastAirJump
            local jumpIdx = math.max(1, tonumber(ch:GetAttribute('AirJumpIndex')) or ((s.AirJumpSeq or 0) + 1))
            s.AirJumpSeq = jumpIdx
            s.Name = (jumpIdx % 3 == 0) and 'DoubleJump_Flip' or 'DoubleJump'
            s.Start = now
            s.Until = now + 0.48
            Equipment3D.SpawnGeppoShockwave(s, jumpIdx)
        end

        if s.WasAirborne and not airborne then
            local fallDist = (s.AirPeakY or s.Root.Position.Y) - s.Root.Position.Y
            s.AirPeakY = s.Root.Position.Y
            if fallDist > 45 then
                Equipment3D.SpawnSuperheroHeavyLanding(s, fallDist)
            end
            s.AirJumpSeq = 0
        end
        s.WasAirborne = airborne
        if airborne then
            s.LastFallVy = math.min(tonumber(s.LastFallVy) or 0, vel.Y)
            s.AirPeakY = math.max(s.AirPeakY or s.Root.Position.Y, s.Root.Position.Y)
        else
            s.LastFallVy = 0
            s.AirPeakY = s.Root.Position.Y
        end
        s.LastCapeWind = math.clamp(hSpeed / 36 + (airborne and 0.32 or 0), 0, 1.35)

        if now >= (s.Until or 0) then
            s.Name = airborne and 'Jump' or (hSpeed > 1.5 and 'Run' or 'Idle')
        end
        ch:SetAttribute('V5CurrentClip', s.Name:gsub('^TS_', ''))

        -- 2. Compute Zero-Drift R15 / R6 Motor6D Pose Offsets
        local joints = ensureNativeJoints(s)
        if not joints then
            return
        end

        local hasNativeTracks = false
        local okTracks, tracks = pcall(function()
            return animator:GetPlayingAnimationTracks()
        end)
        if okTracks and type(tracks) == 'table' and #tracks > 0 then
            hasNativeTracks = true
        end

        local targets = {
            Root = CFrame.identity,
            Waist = CFrame.identity,
            Neck = CFrame.identity,
            RightShoulder = CFrame.identity,
            RightElbow = CFrame.identity,
            RightWrist = CFrame.identity,
            LeftShoulder = CFrame.identity,
            LeftElbow = CFrame.identity,
            LeftWrist = CFrame.identity,
            RightHip = CFrame.identity,
            RightKnee = CFrame.identity,
            LeftHip = CFrame.identity,
            LeftKnee = CFrame.identity,
        }

        local inAction = now < (s.Until or 0)
        if inAction then
            local dur = math.max(0.16, (s.Until or now) - (s.Start or now))
            local p = math.clamp((now - (s.Start or now)) / dur, 0, 1)
            local env = math.sin(p * math.pi)
            local strike = math.clamp((p - 0.14) / 0.38, 0, 1)
            local clip = s.Name

            if clip == 'Attack01' or clip == 'Attack' then
                -- Sword Combo 1: Diagonal Right-to-Left Cleave
                local yaw = math.rad(-26 + 64 * strike) * env
                local pitch = math.rad(124 - 98 * strike) * env
                local roll = math.rad(28 - 58 * strike) * env
                targets.Waist = CFrame.Angles(math.rad(-10) * env, yaw, 0)
                targets.RightShoulder = CFrame.Angles(pitch, math.rad(-14) * env, roll)
                targets.RightElbow = CFrame.Angles(math.rad(38 * (1 - strike * 0.75)) * env, 0, 0)
                targets.RightWrist = CFrame.Angles(math.rad(-24 * strike) * env, 0, 0)
                targets.LeftShoulder = CFrame.Angles(math.rad(-28) * env, 0, math.rad(-20) * env)
                targets.LeftElbow = CFrame.Angles(math.rad(26) * env, 0, 0)

            elseif clip == 'Attack02' then
                -- Sword Combo 2: Reverse Cross-Slash Left-to-Right
                local yaw = math.rad(32 - 70 * strike) * env
                local pitch = math.rad(86 - 18 * strike) * env
                local roll = math.rad(-36 + 76 * strike) * env
                targets.Waist = CFrame.Angles(math.rad(-8) * env, yaw, 0)
                targets.RightShoulder = CFrame.Angles(pitch, math.rad(22 - 52 * strike) * env, roll)
                targets.RightElbow = CFrame.Angles(math.rad(28 * (1 - strike * 0.7)) * env, 0, 0)
                targets.RightWrist = CFrame.Angles(math.rad(-18 * strike) * env, 0, 0)
                targets.LeftShoulder = CFrame.Angles(math.rad(68 - 42 * strike) * env, 0, math.rad(-26) * env)
                targets.LeftElbow = CFrame.Angles(math.rad(32) * env, 0, 0)

            elseif clip == 'Attack03' then
                -- Sword Combo 3: 360° Whirlwind Power Cleave
                local spinYaw = -p * math.pi * 2
                targets.Root = CFrame.Angles(math.rad(-12) * env, spinYaw, 0)
                targets.Waist = CFrame.Angles(math.rad(-8) * env, math.rad(18) * env, 0)
                targets.RightShoulder = CFrame.Angles(math.rad(92) * env, 0, math.rad(38) * env)
                targets.RightElbow = CFrame.Angles(math.rad(14) * env, 0, 0)
                targets.LeftShoulder = CFrame.Angles(math.rad(82) * env, 0, math.rad(-34) * env)
                targets.LeftElbow = CFrame.Angles(math.rad(22) * env, 0, 0)

            elseif clip == 'StyleAttack01' then
                -- Fighting Style Combo 1: Right Straight Martial Punch
                local punch = math.sin(math.clamp(p * 1.35, 0, 1) * math.pi)
                targets.Waist = CFrame.Angles(math.rad(-12) * punch, math.rad(40) * punch, 0)
                targets.RightShoulder = CFrame.Angles(math.rad(94) * punch, 0, math.rad(-8) * punch)
                targets.RightElbow = CFrame.Angles(math.rad(12) * (1 - punch), 0, 0)
                targets.LeftShoulder = CFrame.Angles(math.rad(72) * env, 0, math.rad(18) * env)
                targets.LeftElbow = CFrame.Angles(math.rad(64) * env, 0, 0)

            elseif clip == 'StyleAttack02' then
                -- Fighting Style Combo 2: Left Hook Martial Strike
                local hook = math.sin(math.clamp(p * 1.35, 0, 1) * math.pi)
                targets.Waist = CFrame.Angles(math.rad(-12) * hook, math.rad(-42) * hook, 0)
                targets.LeftShoulder = CFrame.Angles(math.rad(96) * hook, 0, math.rad(24) * hook)
                targets.LeftElbow = CFrame.Angles(math.rad(28) * hook, 0, 0)
                targets.RightShoulder = CFrame.Angles(math.rad(72) * env, 0, math.rad(-18) * env)
                targets.RightElbow = CFrame.Angles(math.rad(64) * env, 0, 0)

            elseif clip == 'StyleAttack03' then
                -- Fighting Style Combo 3: High Roundhouse Sky-Kick
                targets.Root = CFrame.Angles(math.rad(18) * env, math.rad(28) * env, 0)
                targets.Waist = CFrame.Angles(math.rad(-10) * env, math.rad(-24) * env, 0)
                targets.RightHip = CFrame.Angles(math.rad(106) * env, 0, math.rad(18) * env)
                targets.RightKnee = CFrame.Angles(math.rad(-16) * (1 - env), 0, 0)
                targets.LeftHip = CFrame.Angles(math.rad(-18) * env, 0, 0)
                targets.RightShoulder = CFrame.Angles(math.rad(68) * env, 0, math.rad(22) * env)
                targets.RightElbow = CFrame.Angles(math.rad(56) * env, 0, 0)
                targets.LeftShoulder = CFrame.Angles(math.rad(68) * env, 0, math.rad(-22) * env)
                targets.LeftElbow = CFrame.Angles(math.rad(56) * env, 0, 0)

            elseif clip == 'GunShoot' then
                -- Slot 4 Gun / Bow Aiming + Recoil Kick
                local recoil = math.sin(math.clamp((p - 0.08) / 0.45, 0, 1) * math.pi)
                targets.Waist = CFrame.Angles(math.rad(4 * recoil), math.rad(-18) * env, 0)
                targets.RightShoulder = CFrame.Angles(math.rad(90 + 20 * recoil) * env, math.rad(-12) * env, 0)
                targets.RightElbow = CFrame.Angles(math.rad(16 * recoil) * env, 0, 0)
                targets.LeftShoulder = CFrame.Angles(math.rad(48) * env, 0, math.rad(18) * env)
                targets.LeftElbow = CFrame.Angles(math.rad(36) * env, 0, 0)

            elseif clip == 'Heavy' then
                -- Heavy Attack / Charged Overhead Leap Slam
                local slam = math.clamp((p - 0.28) / 0.36, 0, 1)
                local armPitch = math.rad(148 - 122 * slam) * env
                targets.Root = CFrame.new(0, 0.42 * math.sin(math.clamp(p * 1.4, 0, 1) * math.pi), 0)
                    * CFrame.Angles(math.rad(14 - 36 * slam) * env, 0, 0)
                targets.Waist = CFrame.Angles(math.rad(10 - 28 * slam) * env, 0, 0)
                targets.RightShoulder = CFrame.Angles(armPitch, 0, math.rad(-16) * env)
                targets.RightElbow = CFrame.Angles(math.rad(24 * (1 - slam)) * env, 0, 0)
                targets.LeftShoulder = CFrame.Angles(armPitch, 0, math.rad(16) * env)
                targets.LeftElbow = CFrame.Angles(math.rad(24 * (1 - slam)) * env, 0, 0)

            elseif clip == 'Dash' then
                -- Aerodynamic Flash-Step / Dash Sprint Lean
                targets.Root = CFrame.Angles(math.rad(-26) * env, 0, 0)
                targets.Waist = CFrame.Angles(math.rad(-10) * env, 0, 0)
                targets.RightShoulder = CFrame.Angles(math.rad(-38) * env, 0, math.rad(18) * env)
                targets.RightElbow = CFrame.Angles(math.rad(28) * env, 0, 0)
                targets.LeftShoulder = CFrame.Angles(math.rad(-38) * env, 0, math.rad(-18) * env)
                targets.LeftElbow = CFrame.Angles(math.rad(28) * env, 0, 0)
                targets.RightHip = CFrame.Angles(math.rad(34) * env, 0, 0)
                targets.RightKnee = CFrame.Angles(math.rad(-42) * env, 0, 0)
                targets.LeftHip = CFrame.Angles(math.rad(-28) * env, 0, 0)
                targets.LeftKnee = CFrame.Angles(math.rad(-24) * env, 0, 0)

            elseif clip == 'DoubleJump_Flip' then
                -- Geppo 3rd Jump Somersault Flip
                targets.Root = CFrame.Angles(-p * math.pi * 2, 0, 0)
                targets.RightShoulder = CFrame.Angles(math.rad(65) * env, 0, math.rad(28) * env)
                targets.LeftShoulder = CFrame.Angles(math.rad(65) * env, 0, math.rad(-28) * env)
                targets.RightHip = CFrame.Angles(math.rad(58) * env, 0, 0)
                targets.RightKnee = CFrame.Angles(math.rad(-68) * env, 0, 0)
                targets.LeftHip = CFrame.Angles(math.rad(58) * env, 0, 0)
                targets.LeftKnee = CFrame.Angles(math.rad(-68) * env, 0, 0)

            elseif clip == 'DoubleJump' then
                -- Geppo Sky-Step Mid-Air Kick
                targets.Root = CFrame.Angles(math.rad(-10) * env, 0, 0)
                targets.RightShoulder = CFrame.Angles(math.rad(42) * env, 0, math.rad(24) * env)
                targets.LeftShoulder = CFrame.Angles(math.rad(42) * env, 0, math.rad(-24) * env)
                targets.RightHip = CFrame.Angles(math.rad(46) * env, 0, 0)
                targets.RightKnee = CFrame.Angles(math.rad(-54) * env, 0, 0)
                targets.LeftHip = CFrame.Angles(math.rad(-22) * env, 0, 0)
                targets.LeftKnee = CFrame.Angles(math.rad(-32) * env, 0, 0)

            elseif clip == 'SkillZ' or clip == 'FruitZ' then
                -- Skill [Z]: Elemental Wave Thrust / Crescent Cast
                local cast = math.clamp((p - 0.12) / 0.42, 0, 1)
                targets.Waist = CFrame.Angles(math.rad(-14) * env, math.rad(-28 + 62 * cast) * env, 0)
                targets.RightShoulder = CFrame.Angles(math.rad(108 - 22 * cast) * env, 0, math.rad(28 - 54 * cast) * env)
                targets.RightElbow = CFrame.Angles(math.rad(24 * (1 - cast)) * env, 0, 0)
                targets.LeftShoulder = CFrame.Angles(math.rad(45) * env, 0, math.rad(-24) * env)

            elseif clip == 'SkillX' or clip == 'FruitX' then
                -- Skill [X]: Twin-Arm Rising Cyclone Surge
                local rise = math.clamp(p * 1.45, 0, 1)
                targets.Root = CFrame.new(0, 0.28 * env, 0)
                targets.Waist = CFrame.Angles(math.rad(14 * rise) * env, 0, 0)
                targets.RightShoulder = CFrame.Angles(math.rad(28 + 106 * rise) * env, 0, math.rad(26) * env)
                targets.RightElbow = CFrame.Angles(math.rad(20) * env, 0, 0)
                targets.LeftShoulder = CFrame.Angles(math.rad(28 + 106 * rise) * env, 0, math.rad(-26) * env)
                targets.LeftElbow = CFrame.Angles(math.rad(20) * env, 0, 0)

            elseif clip == 'SkillC' or clip == 'FruitC' then
                -- Skill [C]: Rapid 720° Whirlwind Kata Barrage
                targets.Root = CFrame.Angles(math.rad(-10) * env, -p * math.pi * 4, 0)
                targets.RightShoulder = CFrame.Angles(math.rad(90) * env, 0, math.rad(42) * env)
                targets.LeftShoulder = CFrame.Angles(math.rad(90) * env, 0, math.rad(-42) * env)

            else
                -- Skill [V] / [F] / Awakening Ultimate Levitation Burst
                local burst = math.clamp((p - 0.35) / 0.35, 0, 1)
                targets.Root = CFrame.new(0, 0.58 * env, 0)
                targets.Waist = CFrame.Angles(math.rad(18 - 34 * burst) * env, 0, 0)
                targets.RightShoulder = CFrame.Angles(math.rad(136 - 42 * burst) * env, 0, math.rad(36) * env)
                targets.LeftShoulder = CFrame.Angles(math.rad(136 - 42 * burst) * env, 0, math.rad(-36) * env)
                targets.RightHip = CFrame.Angles(math.rad(-16) * env, 0, math.rad(10) * env)
                targets.RightKnee = CFrame.Angles(math.rad(-28) * env, 0, 0)
                targets.LeftHip = CFrame.Angles(math.rad(-16) * env, 0, math.rad(-10) * env)
                targets.LeftKnee = CFrame.Angles(math.rad(-28) * env, 0, 0)
            end
        else
            -- Locomotion Pose Layer (Fallback procedural R15/R6 locomotion when native tracks aren't active + Sword Carry Grip)
            if not hasNativeTracks then
                if airborne then
                    targets.Root = CFrame.Angles(math.rad(-8), 0, 0)
                    targets.RightShoulder = CFrame.Angles(math.rad(34), 0, math.rad(22))
                    targets.RightElbow = CFrame.Angles(math.rad(28), 0, 0)
                    targets.LeftShoulder = CFrame.Angles(math.rad(34), 0, math.rad(-22))
                    targets.LeftElbow = CFrame.Angles(math.rad(28), 0, 0)
                    targets.RightHip = CFrame.Angles(math.rad(28), 0, 0)
                    targets.RightKnee = CFrame.Angles(math.rad(-44), 0, 0)
                    targets.LeftHip = CFrame.Angles(math.rad(-16), 0, 0)
                    targets.LeftKnee = CFrame.Angles(math.rad(-32), 0, 0)
                elseif hSpeed > 1.5 then
                    local cyc = now * math.clamp(hSpeed * 0.55, 6.5, 13.5)
                    local sWave = math.sin(cyc)
                    local cWave = math.cos(cyc)
                    local stride = math.clamp(hSpeed / 22, 0.35, 1.0)
                    targets.Root = CFrame.new(0, math.abs(cWave) * 0.12 * stride, 0)
                        * CFrame.Angles(math.rad(-10 * stride), math.rad(-sWave * 6 * stride), 0)
                    targets.Waist = CFrame.Angles(0, math.rad(sWave * 8 * stride), 0)
                    targets.RightHip = CFrame.Angles(math.rad(-sWave * 46 * stride), 0, 0)
                    targets.RightKnee = CFrame.Angles(math.rad(-math.max(0, sWave) * 52 * stride - 8), 0, 0)
                    targets.LeftHip = CFrame.Angles(math.rad(sWave * 46 * stride), 0, 0)
                    targets.LeftKnee = CFrame.Angles(math.rad(-math.max(0, -sWave) * 52 * stride - 8), 0, 0)
                    targets.LeftShoulder = CFrame.Angles(math.rad(-sWave * 38 * stride), 0, math.rad(-8))
                    targets.LeftElbow = CFrame.Angles(math.rad(26 + math.max(0, -sWave) * 22 * stride), 0, 0)
                    if activeSlot == 3 then
                        targets.RightShoulder = CFrame.Angles(math.rad(18 + sWave * 12 * stride), 0, math.rad(12))
                        targets.RightElbow = CFrame.Angles(math.rad(24), 0, 0)
                    else
                        targets.RightShoulder = CFrame.Angles(math.rad(sWave * 38 * stride), 0, math.rad(8))
                        targets.RightElbow = CFrame.Angles(math.rad(26 + math.max(0, sWave) * 22 * stride), 0, 0)
                    end
                else
                    local br = math.sin(now * 2.4)
                    targets.Waist = CFrame.Angles(math.rad(br * 1.8), 0, 0)
                    targets.LeftShoulder = CFrame.Angles(math.rad(br * 2.2), 0, math.rad(-5))
                    if activeSlot == 3 then
                        targets.RightShoulder = CFrame.Angles(math.rad(16 + br * 2.0), 0, math.rad(10))
                        targets.RightElbow = CFrame.Angles(math.rad(20), 0, 0)
                    else
                        targets.RightShoulder = CFrame.Angles(math.rad(-br * 2.2), 0, math.rad(5))
                    end
                end
            elseif activeSlot == 3 and not airborne then
                -- Subtle sword-carry arm lift when native Animate tracks are playing so blade stays above ground
                targets.RightShoulder = CFrame.Angles(math.rad(14), 0, math.rad(8))
                targets.RightElbow = CFrame.Angles(math.rad(16), 0, 0)
            end
        end

        local blendSpeed = inAction and 22 or 14
        local alpha = 1 - math.exp(-blendSpeed * dt)
        for role, entry in pairs(joints) do
            local j = entry.Joint
            if j and j.Parent then
                local curOff = s.NativeJointOffsets[role] or CFrame.identity
                local goalOff = targets[role] or CFrame.identity
                local nextOff = curOff:Lerp(goalOff, alpha)
                s.NativeJointOffsets[role] = nextOff
                local baseC0 = entry.BaseC0
                j.C0 = CFrame.new(baseC0.Position + nextOff.Position) * nextOff.Rotation * baseC0.Rotation
            end
        end

        Equipment3D.ApplyHeadTargetLookAt(s, dt, now)
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
                if dist <= 1650 then
                    if dist <= 750 or now >= (w.NextStep or 0) then
                        w.NextStep = now + 0.06
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
            if not ch.Parent or not s.Model or not s.Model.Parent then
                cleanupState(ch, s)
                continue
            end

            if s.IsNativeAvatar then
                stepNativeAvatarAnimation(s, dt, now)
            else
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
            end

            -- 5. Monitor Blox Fruits Air-Jump / Geppo (Alternating Step L / Step R / Somersault Flip)
            if not s.IsNativeAvatar and s.Clips and next(s.Clips) then
                local mode = s.H:GetState()
                local vel = s.Root.AssemblyLinearVelocity
                local hSpeed = math.max(Vector3.new(vel.X, 0, vel.Z).Magnitude, s.H.MoveDirection.Magnitude * s.H.WalkSpeed)
                local airborne = (mode == Enum.HumanoidStateType.Jumping or mode == Enum.HumanoidStateType.Freefall)

                local lastAirJump = tonumber(ch:GetAttribute('LastAirJumpAt')) or 0
                if lastAirJump > (s.LastAirJumpAt or 0) then
                    s.LastAirJumpAt = lastAirJump
                    local jumpIdx = math.max(1, tonumber(ch:GetAttribute('AirJumpIndex')) or ((s.AirJumpSeq or 0) + 1))
                    s.AirJumpSeq = jumpIdx
                    local stepMod = jumpIdx % 3
                    local djClip
                    if stepMod == 1 and s.Clips.DoubleJump_L then
                        djClip = 'DoubleJump_L'
                    elseif stepMod == 2 and s.Clips.DoubleJump_R then
                        djClip = 'DoubleJump_R'
                    elseif stepMod == 0 and s.Clips.DoubleJump_Flip then
                        djClip = 'DoubleJump_Flip'
                    else
                        djClip = (s.ClassId == 'ThunderStriker' and (s.Clips.TS_DoubleJump and 'TS_DoubleJump' or (s.Clips.DoubleJump and 'DoubleJump' or 'TS_Jump')))
                            or (s.Clips.DoubleJump and 'DoubleJump' or 'Jump')
                    end
                    if s.Clips[djClip] then
                        s.Name = djClip
                        s.Start = now
                        s.Until = now + math.max(0.48, s.Clips[djClip].Duration or 0.54)
                        s.FastBlendUntil = now + 0.14
                        s.LandImpulse = 0.24
                    end
                    Equipment3D.SpawnGeppoShockwave(s, jumpIdx)
                end

                -- 5b. Instant Client-Side Dash / Dodge / FlashStep Trigger (Zero-Latency Glide Pose)
                local lastDashAt = tonumber(ch:GetAttribute('LastDashAt')) or 0
                if lastDashAt > (s.LastDashAt or 0) then
                    s.LastDashAt = lastDashAt
                    local dashVar = tostring(ch:GetAttribute('DashVariant') or 'Dash')
                    local chosenDash = dashVar
                    if dashVar == 'Dash' and airborne and s.Clips.AirDash then
                        chosenDash = (s.ClassId == 'ThunderStriker' and s.Clips.TS_AirDash) and 'TS_AirDash' or 'AirDash'
                    elseif dashVar == 'Dash' and s.ClassId == 'ThunderStriker' and s.Clips.TS_Dash then
                        chosenDash = 'TS_Dash'
                    end
                    if not s.Clips[chosenDash] then
                        chosenDash = s.Clips.Dash and 'Dash' or 'Dodge'
                    end
                    if s.Clips[chosenDash] then
                        s.Name = chosenDash
                        s.Start = now
                        s.Until = now + math.max(0.42, tonumber(ch:GetAttribute('DashDuration')) or s.Clips[chosenDash].Duration or 0.46)
                        s.FastBlendUntil = now + 0.12
                    end
                end

                -- 5c. Detect Airborne -> Grounded Landing Impact & Superhero Heavy Landing (> 45 studs)
                if s.WasAirborne and not airborne then
                    local fallDist = (s.AirPeakY or s.Root.Position.Y) - s.Root.Position.Y
                    local fallVel = tonumber(s.LastFallVy) or 0
                    s.AirPeakY = s.Root.Position.Y
                    if fallDist > 45 then
                        s.LandImpulse = -0.52
                        if s.Clips.Land then
                            s.Name = 'Land'
                            s.Start = now
                            s.Until = now + math.max(0.42, math.min(0.50, s.Clips.Land.Duration or 0.44))
                            s.FastBlendUntil = now + 0.08
                        end
                        Equipment3D.SpawnSuperheroHeavyLanding(s, fallDist)
                    elseif fallVel < -18 then
                        s.LandImpulse = math.clamp(fallVel / 95, -0.42, -0.16)
                        if now >= (s.Until or 0) and s.Clips.Land then
                            s.Name = 'Land'
                            s.Start = now
                            s.Until = now + math.min(0.32, s.Clips.Land.Duration or 0.34)
                            s.FastBlendUntil = now + 0.10
                        end
                    end
                    s.AirJumpSeq = 0
                end
                s.WasAirborne = airborne
                if airborne then
                    s.LastFallVy = math.min(tonumber(s.LastFallVy) or 0, vel.Y)
                    s.AirPeakY = math.max(s.AirPeakY or s.Root.Position.Y, s.Root.Position.Y)
                else
                    s.LastFallVy = 0
                    s.AirPeakY = s.Root.Position.Y
                end

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

                -- 5d. Compute Real-Time Secondary Procedural Motion (Aerodynamic Flight/Glide Pitch, Sprint Turn Banking Roll, Squash & Cape Wind)
                local look = s.Root.CFrame.LookVector
                local right = s.Root.CFrame.RightVector
                local flatVel = Vector3.new(vel.X, 0, vel.Z)
                local fwdSpeed = flatVel:Dot(look)
                local sideSpeed = flatVel:Dot(right)

                local prevLook = s.PrevLook or look
                local turnCrossY = prevLook:Cross(look).Y
                local yawRate = math.clamp(turnCrossY / math.max(dt, 1 / 120), -10, 10)
                s.PrevLook = look

                local isLocomotion = (s.Name == 'Run' or s.Name == 'TS_Run' or s.Name == 'Walk' or s.Name == 'Dash' or s.Name == 'AirDash' or s.Name == 'TS_Dash' or s.Name == 'TS_AirDash' or s.Name == 'FlashStep')
                local targetPitch = 0
                if airborne and hSpeed > 10 then
                    targetPitch = math.clamp(-fwdSpeed * 0.0042 + vel.Y * 0.0022, -0.26, 0.22)
                elseif isLocomotion then
                    targetPitch = math.clamp(-fwdSpeed * 0.0048, -0.24, 0.14)
                elseif airborne then
                    targetPitch = math.clamp(vel.Y * 0.0028, -0.18, 0.18)
                end
                local bankMult = airborne and 1.32 or 1.15
                local targetRoll = math.clamp((-yawRate * 0.038 - sideSpeed * 0.0044) * bankMult, -0.35, 0.35)

                s.DynPitch = (s.DynPitch or 0) + (targetPitch - (s.DynPitch or 0)) * math.min(1, dt * 12)
                s.DynRoll = (s.DynRoll or 0) + (targetRoll - (s.DynRoll or 0)) * math.min(1, dt * 12)
                s.LandImpulse = (s.LandImpulse or 0) * math.max(0, 1 - dt * 9)
                local capeWind = math.clamp(hSpeed / 36 + (airborne and 0.32 or 0), 0, 1.35)
                s.LastCapeWind = capeWind

                local activeClip = s.Clips[s.Name] or s.Clips[ s.Name:gsub('^TS_', '') ] or s.Clips.Idle
                Renderer.Pose(s.Model, activeClip, now - s.Start, {
                    Start = s.Start,
                    BlendTime = (now < (s.FastBlendUntil or 0)) and 0.055 or 0.11,
                    Pitch = s.DynPitch,
                    Roll = s.DynRoll,
                    SquashY = s.LandImpulse,
                    CapeWind = capeWind,
                })
                Equipment3D.ApplyHeadTargetLookAt(s, dt, now)
                ch:SetAttribute('V5CurrentClip', s.Name:gsub('^TS_', ''))
            end

            -- 0. Step Real Separated 3D Blender Weapons (Dual-Wield, Dynamic Trails & 0ms Slot Cache) & 3D Character Accessories
            Equipment3D.StepCharacterWeapons(Renderer, s, now)
            Equipment3D.StepCharacterAccessories(s, now, s.LastCapeWind or 0)

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
            if not owner.Parent or not s.Model or not s.Model.Parent or not s.Root or not s.Root.Parent then
                if s.Model and s.Model.Parent then
                    s.Model:Destroy()
                end
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
