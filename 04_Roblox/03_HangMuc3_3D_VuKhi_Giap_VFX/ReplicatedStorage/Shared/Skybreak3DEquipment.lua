-- Skybreak3DEquipment.lua
-- Wave 1 Modular 3D Equipment, Dual-Wield Weapons, Dynamic Trails, 0ms Slot Cache,
-- Skinned Race V4 Wing Animator, 3D Character Accessories, World Aether Fruit Trees,
-- Wild Fruit Radar, Raid Console, Elemental Shrines, Kael Forge FX, Portals & Parkour VFX.

local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local UserInputService = game:GetService('UserInputService')
local TweenService = game:GetService('TweenService')
local Debris = game:GetService('Debris')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Expansion3D = require(ReplicatedStorage:WaitForChild('Shared'):WaitForChild('SkybreakExpansion3DAndVFX'))

local M = {}

local localPlayer = Players.LocalPlayer
local templateCache = {}
local buildingLocks = {}
local waitingCallbacks = {}

local function noopProgress() end

local function isLowFX(plr)
    local p = plr or localPlayer
    if p and p:GetAttribute('LowFXMode') == true then
        return true
    end
    return workspace:GetAttribute('LowFXMode') == true
end
M.IsLowFX = isLowFX

local R6_FALLBACK_PART_NAMES = {
    RightHand = 'Right Arm',
    Hand_R = 'Right Arm',
    RightLowerArm = 'Right Arm',
    LowerArm_R = 'Right Arm',
    RightArm = 'Right Arm',
    LeftHand = 'Left Arm',
    Hand_L = 'Left Arm',
    LeftLowerArm = 'Left Arm',
    LowerArm_L = 'Left Arm',
    LeftArm = 'Left Arm',
    UpperTorso = 'Torso',
    LowerTorso = 'Torso',
    Spine2 = 'Torso',
    Chest = 'Torso',
    Spine = 'Torso',
    RightLowerLeg = 'Right Leg',
    LowerLeg_R = 'Right Leg',
    RightShin = 'Right Leg',
    Shin_R = 'Right Leg',
    RightFoot = 'Right Leg',
    Foot_R = 'Right Leg',
    RightLeg = 'Right Leg',
    LeftLowerLeg = 'Left Leg',
    LowerLeg_L = 'Left Leg',
    LeftShin = 'Left Leg',
    Shin_L = 'Left Leg',
    LeftFoot = 'Left Leg',
    Foot_L = 'Left Leg',
    LeftLeg = 'Left Leg',
}

local function findBone(visual, names)
    if not visual then
        return nil
    end
    local root = visual.PrimaryPart
    if root then
        for _, name in ipairs(names) do
            local b = root:FindFirstChild(name, true)
            if b and b:IsA('Bone') then
                return b
            end
        end
    end
    for _, name in ipairs(names) do
        local p = visual:FindFirstChild(name)
        if p and p:IsA('BasePart') then
            return p
        end
        local r6Name = R6_FALLBACK_PART_NAMES[name]
        if r6Name then
            local p6 = visual:FindFirstChild(r6Name)
            if p6 and p6:IsA('BasePart') then
                return p6
            end
        end
    end
    return nil
end
M.FindBone = findBone

local function getBoneWorldCF(s, bone, fallbackOffset)
    if bone and bone.Parent then
        if bone:IsA('Bone') then
            return bone.TransformedWorldCFrame
        elseif bone:IsA('BasePart') then
            if bone.Name == 'Right Arm' or bone.Name == 'Left Arm' then
                return bone.CFrame * CFrame.new(0, -0.82, 0)
            end
            return bone.CFrame
        end
    end
    local ratio = (s and s.CurrentScale or 2.6) / 2.6
    if s and s.Root and s.Root.Parent then
        local off = fallbackOffset or CFrame.identity
        return s.Root.CFrame * CFrame.new(off.Position * ratio) * off.Rotation
    end
    return CFrame.identity
end
M.GetBoneWorldCF = getBoneWorldCF

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

local function ensureTempFolder()
    local f = workspace:FindFirstChild('TempFX')
    if not f then
        f = Instance.new('Folder')
        f.Name = 'TempFX'
        f.Parent = workspace
    end
    return f
end

local function ensureWorldPropsFolder()
    local f = workspace:FindFirstChild('SkybreakWorld3DProps')
    if not f then
        f = Instance.new('Folder')
        f.Name = 'SkybreakWorld3DProps'
        f.Parent = workspace
    end
    return f
end

local function ensureTemplateAsync(Renderer, assetName, callback)
    if not Renderer or type(assetName) ~= 'string' or assetName == '' then
        return
    end
    local cached = templateCache[assetName] or (Renderer.Models and Renderer.Models[assetName])
    if cached and cached.PrimaryPart and cached.PrimaryPart.Parent then
        templateCache[assetName] = cached
        if callback then
            callback(cached)
        end
        return
    end
    if callback then
        waitingCallbacks[assetName] = waitingCallbacks[assetName] or {}
        table.insert(waitingCallbacks[assetName], callback)
    end
    if buildingLocks[assetName] then
        return
    end
    buildingLocks[assetName] = true
    task.spawn(function()
        local ok, built = pcall(function()
            if Renderer.BuildPriority then
                return Renderer.BuildPriority(assetName, 0, noopProgress)
            end
            return Renderer.Build(assetName, noopProgress)
        end)
        buildingLocks[assetName] = nil
        if ok and built and built.PrimaryPart then
            templateCache[assetName] = built
            local list = waitingCallbacks[assetName]
            waitingCallbacks[assetName] = nil
            if list then
                for _, cb in ipairs(list) do
                    task.spawn(cb, built)
                end
            end
        else
            waitingCallbacks[assetName] = nil
        end
    end)
end

local function raycastSolidFloor(pos, fallbackY)
    local refY = fallbackY or pos.Y
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.RespectCanCollide = true
    local exclude = {}
    for _, folderName in ipairs({
        'Solid3DObstacles',
        'TempFX',
        'ActiveEnemies',
        'ActiveNPCs',
        'ActiveBosses',
        'ActiveShips',
        'WorldPortals',
        'DroppedDevilFruits',
        'PlayerCompanions',
        'SkybreakWorld3DFruits',
        'SkybreakWorld3DProps',
    }) do
        local inst = workspace:FindFirstChild(folderName)
        if inst then
            table.insert(exclude, inst)
        end
    end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr.Character then
            table.insert(exclude, plr.Character)
        end
    end
    params.FilterDescendantsInstances = exclude
    local origin = Vector3.new(pos.X, refY + 120, pos.Z)
    local hit = workspace:Raycast(origin, Vector3.new(0, -260, 0), params)
    if hit and hit.Position.Y > 8 and math.abs(hit.Position.Y - refY) <= 45 then
        return hit.Position.Y
    end
    return refY
end
M.RaycastSolidFloor = raycastSolidFloor

local function pivotBottomFlush(model, worldPos, yawRad)
    if not model then
        return
    end
    local rot = CFrame.Angles(0, yawRad or 0, 0)
    model:PivotTo(CFrame.new(worldPos) * rot)
    local boxCF, boxSize = model:GetBoundingBox()
    local bottomY = boxCF.Position.Y - boxSize.Y * 0.5
    local dy = worldPos.Y - bottomY
    local dx = worldPos.X - boxCF.Position.X
    local dz = worldPos.Z - boxCF.Position.Z
    local curPivot = model:GetPivot()
    model:PivotTo(CFrame.new(curPivot.Position + Vector3.new(dx, dy, dz)) * curPivot.Rotation)
end

local function createWorldPrompt(parentPart, actionText, objectText, maxDist, onTriggered)
    local prompt = Instance.new('ProximityPrompt')
    -- Named InspectFruit3DPrompt so ClientBootstrap keeps native 3D ProximityPrompt UI visible
    prompt.Name = 'InspectFruit3DPrompt'
    prompt.Style = Enum.ProximityPromptStyle.Default
    prompt.ActionText = actionText
    prompt.ObjectText = objectText or 'SKYBREAK'
    prompt.KeyboardKeyCode = Enum.KeyCode.E
    prompt.HoldDuration = 0
    prompt.MaxActivationDistance = maxDist or 14
    prompt.RequiresLineOfSight = false
    prompt.Parent = parentPart
    prompt:GetPropertyChangedSignal('Style'):Connect(function()
        if prompt.Style ~= Enum.ProximityPromptStyle.Default then
            prompt.Style = Enum.ProximityPromptStyle.Default
        end
    end)
    if onTriggered then
        prompt.Triggered:Connect(onTriggered)
    end
    return prompt
end

local function requestUIScreen(screenName)
    local p = localPlayer
    if not p then
        return
    end
    local pgui = p:FindFirstChildOfClass('PlayerGui')
    local skyUI = pgui and pgui:FindFirstChild('SkybreakUI')
    if skyUI then
        skyUI:SetAttribute('RequestScreen', '')
        skyUI:SetAttribute('RequestScreen', screenName)
    end
end

-- ============================================================================
-- 1. REAL 3D WEAPONS, DUAL-WIELD, DYNAMIC TRAILS & 0ms SLOT CACHE (#1,#34,#39,#40)
-- ============================================================================
local DUAL_SWORD_IDS = {
    cursed_dual_skyblades = true,
    CursedDualSkyblades = true,
    stormfang_daggers = true,
    Stormfang = true,
    starter_daggers = true,
}

local function resolveSwordAssets(Renderer, swordId, classId)
    local sid = tostring(swordId or '')
    if Expansion3D.IsExpansionSword(sid) then
        local cleanId = string.lower(sid)
        return {
            IsDual = false,
            RightAsset = 'ExpSword_' .. cleanId,
            LeftAsset = nil,
            SwordId = cleanId,
        }
    end
    if DUAL_SWORD_IDS[sid] or (sid == '' and classId == 'ThunderStriker') then
        return {
            IsDual = true,
            RightAsset = 'Wep_CursedBladeRight',
            LeftAsset = 'Wep_CursedBladeLeft',
            SwordId = sid ~= '' and sid or 'cursed_dual_skyblades',
        }
    end
    local mapped = (sid ~= '' and Renderer.GetWeaponAsset and Renderer.GetWeaponAsset(sid)) or nil
    if not mapped or mapped == 'Wep_CursedDualSkyblades' then
        if mapped == 'Wep_CursedDualSkyblades' then
            return {
                IsDual = true,
                RightAsset = 'Wep_CursedBladeRight',
                LeftAsset = 'Wep_CursedBladeLeft',
                SwordId = sid,
            }
        end
        if classId == 'ArcaneMage' then
            mapped = 'Wep_CryonFrostblade'
        else
            mapped = 'Wep_Dawnbringer'
        end
    end
    return {
        IsDual = false,
        RightAsset = mapped,
        LeftAsset = nil,
        SwordId = sid ~= '' and sid or 'dawnbringer_sword',
    }
end

local function resolveGunAsset(Renderer, gunId)
    local gid = tostring(gunId or '')
    if Expansion3D.IsExpansionGun(gid) then
        local cleanId = string.lower(gid)
        return 'ExpGun_' .. cleanId, cleanId
    end
    if gid ~= '' and Renderer.GetWeaponAsset then
        local mapped = Renderer.GetWeaponAsset(gid)
        if mapped == 'Wep_CryoRailgun' or mapped == 'Wep_SoulGuitarVoid' then
            return mapped, gid
        end
    end
    if gid:lower():find('rail') or gid:lower():find('rifle') or gid:lower():find('cannon') or gid:lower():find('cryo') then
        return 'Wep_CryoRailgun', (gid ~= '' and gid or 'cryo_railgun')
    end
    return 'Wep_SoulGuitarVoid', (gid ~= '' and gid or 'soul_guitar_void')
end

local function getWeaponTrailColors(assetName, itemId)
    local id = string.lower(tostring(itemId or ''))
    local a = tostring(assetName or '')
    if id:find('sylvaris') then
        return Color3.fromRGB(52, 211, 153), Color3.fromRGB(167, 243, 208)
    elseif id:find('ignivar') or id:find('magma') then
        return Color3.fromRGB(251, 113, 133), Color3.fromRGB(249, 115, 22)
    elseif id:find('nerith') or id:find('trident') then
        return Color3.fromRGB(34, 211, 238), Color3.fromRGB(165, 243, 252)
    elseif id:find('aion') or id:find('chrono') then
        return Color3.fromRGB(192, 132, 252), Color3.fromRGB(233, 213, 255)
    elseif id:find('veyr') or id:find('singularity') then
        return Color3.fromRGB(244, 63, 94), Color3.fromRGB(244, 193, 78)
    elseif id:find('cyber_katana') then
        return Color3.fromRGB(56, 189, 248), Color3.fromRGB(186, 230, 253)
    elseif a == 'Wep_Dawnbringer' or id:find('dawn') or id:find('aureon') or id:find('solar') or id:find('sunshard') then
        return Color3.fromRGB(255, 224, 92), Color3.fromRGB(255, 132, 38)
    elseif a == 'Wep_CryonFrostblade' or a == 'Wep_CryoRailgun' or id:find('cryo') or id:find('frost') or id:find('glacial') then
        return Color3.fromRGB(86, 238, 255), Color3.fromRGB(224, 252, 255)
    elseif a == 'Wep_CursedBladeRight' or a == 'Wep_CursedBladeLeft' or id:find('cursed') or id:find('stormfang') or id:find('yamo') then
        return Color3.fromRGB(255, 48, 112), Color3.fromRGB(178, 54, 255)
    elseif a == 'Wep_NoxarGreatsword' or a == 'Wep_SoulGuitarVoid' or id:find('noxar') or id:find('abyss') or id:find('void') or id:find('architect') then
        return Color3.fromRGB(172, 48, 255), Color3.fromRGB(255, 96, 42)
    end
    return Color3.fromRGB(102, 228, 255), Color3.fromRGB(255, 228, 132)
end

local function configureWeaponTrail(entry, itemId, enhanceLv, lowFX)
    if not entry or not entry.Model or not entry.Model.PrimaryPart or entry.IsGun then
        return
    end
    local root = entry.Model.PrimaryPart
    local c1, c2 = getWeaponTrailColors(entry.AssetName, itemId)
    local lv = math.clamp(tonumber(enhanceLv) or 0, 0, 15)

    local attBase = root:FindFirstChild('TrailBase')
    if not attBase then
        attBase = Instance.new('Attachment')
        attBase.Name = 'TrailBase'
        attBase.Parent = root
    end
    local attTip = root:FindFirstChild('TrailTip')
    if not attTip then
        attTip = Instance.new('Attachment')
        attTip.Name = 'TrailTip'
        attTip.Parent = root
    end

    local bladeSpan = math.max(1.8, entry.BoxSize.Y * 0.68)
    attBase.Position = Vector3.new(0, 0.35, 0)
    attTip.Position = Vector3.new(0, bladeSpan, 0)

    local trail = root:FindFirstChild('DynamicSwordTrail')
    if not trail then
        trail = Instance.new('Trail')
        trail.Name = 'DynamicSwordTrail'
        trail.Attachment0 = attBase
        trail.Attachment1 = attTip
        trail.FaceCamera = true
        trail.LightEmission = 0.65
        trail.LightInfluence = 0.2
        trail.MinLength = 0.04
        trail.Parent = root
    end

    local widthMult = 0.88
    local life = 0.18
    if lv >= 15 then
        widthMult = 1.42
        life = 0.32
        c2 = Color3.fromRGB(255, 236, 128)
    elseif lv >= 10 then
        widthMult = 1.24
        life = 0.27
    elseif lv >= 5 then
        widthMult = 1.06
        life = 0.22
    end
    if lowFX then
        life = life * 0.55
        widthMult = widthMult * 0.75
    end

    trail.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, c1),
        ColorSequenceKeypoint.new(0.65, c2),
        ColorSequenceKeypoint.new(1, c2),
    })
    trail.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.25),
        NumberSequenceKeypoint.new(0.55, 0.58),
        NumberSequenceKeypoint.new(1, 1.0),
    })
    trail.WidthScale = NumberSequence.new({
        NumberSequenceKeypoint.new(0, widthMult),
        NumberSequenceKeypoint.new(0.55, widthMult * 0.62),
        NumberSequenceKeypoint.new(1, 0.06),
    })
    trail.Lifetime = life
    entry.Trail = trail
    entry.TrailBase = attBase
    entry.TrailTip = attTip
    entry.TrailLevel = lv
    entry.TrailItem = itemId
end

local function computeBindBasis(s)
    if s._EquipBindReady and s.Visual and s.Visual.Parent then
        return
    end
    if not s or not s.Visual or not s.Visual.PrimaryPart then
        return
    end
    local rHand = findBone(s.Visual, { 'RightHand', 'Hand_R', 'RightLowerArm', 'LowerArm_R', 'RightArm' })
    local lHand = findBone(s.Visual, { 'LeftHand', 'Hand_L', 'LeftLowerArm', 'LowerArm_L', 'LeftArm' })
    local rFore = findBone(s.Visual, { 'RightLowerArm', 'LowerArm_R', 'RightArm' })
    local lFore = findBone(s.Visual, { 'LeftLowerArm', 'LowerArm_L', 'LeftArm' })
    local torso = findBone(s.Visual, { 'UpperTorso', 'Spine2', 'Chest', 'Spine', 'Torso' })
    local head = findBone(s.Visual, { 'Head', 'head', 'Neck', 'neck' })
    local rLeg = findBone(s.Visual, { 'RightLowerLeg', 'LowerLeg_R', 'RightShin', 'Shin_R', 'RightLeg' })
    local lLeg = findBone(s.Visual, { 'LeftLowerLeg', 'LowerLeg_L', 'LeftShin', 'Shin_L', 'LeftLeg' })

    s._EquipRHand = rHand
    s._EquipLHand = lHand
    s._EquipRFore = rFore
    s._EquipLFore = lFore
    s._EquipTorso = torso
    s._EquipHead = head
    s._EquipRLeg = rLeg
    s._EquipLLeg = lLeg

    if s.IsNativeAvatar or (rHand and rHand:IsA('BasePart')) or (torso and torso:IsA('BasePart')) then
        s._RightSwordRot = CFrame.Angles(-math.rad(80), 0, 0)
        s._LeftSwordRot = CFrame.Angles(-math.rad(80), 0, 0)
        s._RightGunRot = CFrame.Angles(-math.rad(90), 0, 0)
        s._LeftGunRot = CFrame.Angles(-math.rad(90), 0, 0)
        s._TorsoModelBasis = CFrame.identity
        s._HeadModelBasis = CFrame.identity
        s._RHandModelBasis = CFrame.identity
        s._LHandModelBasis = CFrame.identity
        s._RLegModelBasis = CFrame.identity
        s._LLegModelBasis = CFrame.identity
        s._EquipBindReady = true
        return
    end

    local modelPivot = s.Visual:GetPivot()
    local charFwd = modelPivot.LookVector
    local charUp = modelPivot.UpVector
    local charRight = modelPivot.RightVector

    local function buildHandRot(handBone, foreBone, isLeft, aimPureForward)
        if not handBone then
            return CFrame.Angles(-math.rad(75), 0, 0)
        end
        local bladeDir = aimPureForward and charFwd or (charFwd * 0.86 + charUp * 0.51).Unit
        local armDir = charRight * (isLeft and -1 or 1)
        if foreBone and foreBone ~= handBone then
            local delta = handBone.WorldCFrame.Position - foreBone.WorldCFrame.Position
            if delta.Magnitude > 0.02 then
                armDir = delta.Unit
            end
        end
        local sideVec = bladeDir:Cross(armDir)
        if sideVec.Magnitude < 0.05 then
            sideVec = bladeDir:Cross(charRight)
            if sideVec.Magnitude < 0.05 then
                sideVec = bladeDir:Cross(charUp)
            end
        end
        sideVec = sideVec.Magnitude > 1e-4 and sideVec.Unit or charRight
        local rawBack = sideVec:Cross(bladeDir)
        local backVec = rawBack.Magnitude > 1e-4 and rawBack.Unit or -charFwd
        local desiredWorld = CFrame.fromMatrix(Vector3.zero, sideVec, bladeDir, backVec)
        return handBone.WorldCFrame.Rotation:Inverse() * desiredWorld
    end

    s._RightSwordRot = buildHandRot(rHand, rFore, false, false)
    s._LeftSwordRot = buildHandRot(lHand, lFore, true, false)
    s._RightGunRot = buildHandRot(rHand, rFore, false, true)
    s._LeftGunRot = buildHandRot(lHand, lFore, true, true)

    if torso then
        local torsoInv = torso.WorldCFrame.Rotation:Inverse()
        local torsoLocalToWorld = torsoInv * modelPivot.Rotation
        s._TorsoModelBasis = torsoLocalToWorld
    else
        s._TorsoModelBasis = CFrame.identity
    end

    if head then
        s._HeadModelBasis = head.WorldCFrame.Rotation:Inverse() * modelPivot.Rotation
    else
        s._HeadModelBasis = CFrame.identity
    end
    s._RHandModelBasis = rHand and (rHand.WorldCFrame.Rotation:Inverse() * modelPivot.Rotation) or CFrame.identity
    s._LHandModelBasis = lHand and (lHand.WorldCFrame.Rotation:Inverse() * modelPivot.Rotation) or CFrame.identity
    s._RLegModelBasis = rLeg and (rLeg.WorldCFrame.Rotation:Inverse() * modelPivot.Rotation) or CFrame.identity
    s._LLegModelBasis = lLeg and (lLeg.WorldCFrame.Rotation:Inverse() * modelPivot.Rotation) or CFrame.identity

    s._EquipBindReady = true
end

local function setWeaponEntryVisible(entry, visible, trailActive, lowFX)
    if not entry then
        return
    end
    if entry.Visible ~= visible then
        entry.Visible = visible
        for _, mp in ipairs(entry.MeshParts) do
            if mp.Part and mp.Part.Parent then
                mp.Part.Transparency = visible and mp.OrigTrans or 1
                mp.Part.LocalTransparencyModifier = visible and 0 or 1
                for _, ch in ipairs(mp.Part:GetChildren()) do
                    if ch:IsA('ParticleEmitter') then
                        ch.Enabled = (visible == true) and not lowFX
                    elseif ch:IsA('PointLight') then
                        ch.Enabled = (visible == true)
                    end
                end
            end
        end
    end
    if entry.Trail then
        local wantTrail = (visible == true) and (trailActive == true) and not lowFX
        if entry.Trail.Enabled ~= wantTrail then
            entry.Trail.Enabled = wantTrail
        end
    end
end

local function pivotWeaponEntry(entry, targetCF, now)
    if not entry or not entry.Model then
        return
    end
    if entry.IsExpansionCustom then
        Expansion3D.PivotExpansionWeapon(entry, targetCF, now)
    else
        entry.Model:PivotTo(targetCF)
    end
end

local function ensureCachedWeapon(Renderer, s, cacheKey, assetName, isGun)
    if not s or not s.Visual or not s.Visual.Parent then
        return nil
    end
    s.WeaponCache = s.WeaponCache or {}
    local existing = s.WeaponCache[cacheKey]
    if existing then
        if existing.Model and existing.Model.Parent then
            return existing
        elseif existing.Building then
            return nil
        end
    end

    local folder = s.Visual:FindFirstChild('EquippedWeapons3D')
    if not folder then
        folder = Instance.new('Folder')
        folder.Name = 'EquippedWeapons3D'
        folder.Parent = s.Visual
    end

    -- 0ms synchronous build for Pass 13 Expansion Melee Weapons & Ranged Guns/Bows
    if assetName:sub(1, 9) == 'ExpSword_' or assetName:sub(1, 7) == 'ExpGun_' then
        local isLeft = (cacheKey:find('L_') ~= nil)
        local lowFX = isLowFX(s.Owner)
        local entry = Expansion3D.BuildExpansionWeaponModel(assetName, assetName, isLeft, lowFX)
        entry.CacheKey = cacheKey
        entry.Model.Name = cacheKey
        entry.Model.Parent = folder
        s.WeaponCache[cacheKey] = entry
        if not isGun then
            configureWeaponTrail(entry, entry.ItemId, s.EnhanceLevel or 0, lowFX)
        end
        return entry
    end

    local placeholder = { Building = true, AssetName = assetName, IsGun = isGun }
    s.WeaponCache[cacheKey] = placeholder

    ensureTemplateAsync(Renderer, assetName, function()
        if not s.Visual or not s.Visual.Parent or s.WeaponCache[cacheKey] ~= placeholder then
            return
        end
        local okC, clone = pcall(function()
            if Renderer.CloneModel then
                return Renderer.CloneModel(assetName, 0, noopProgress)
            end
            local tpl = templateCache[assetName] or Renderer.Build(assetName, noopProgress)
            return tpl and tpl:Clone() or nil
        end)
        if not okC or not clone or not clone.PrimaryPart then
            s.WeaponCache[cacheKey] = nil
            return
        end

        clone.Name = cacheKey
        local _, rawSize = clone:GetBoundingBox()
        local rawMax = math.max(rawSize.X, rawSize.Y, rawSize.Z, 0.5)
        local targetSpan = 4.65
        if assetName == 'Wep_NoxarGreatsword' then
            targetSpan = 5.55
        elseif assetName == 'Wep_CursedBladeLeft' or assetName == 'Wep_CursedBladeRight' then
            targetSpan = 4.35
        elseif assetName == 'Wep_CryoRailgun' then
            targetSpan = 4.25
        elseif assetName == 'Wep_SoulGuitarVoid' then
            targetSpan = 4.30
        end
        local scaleFactor = math.clamp(targetSpan / rawMax, 0.45, 3.6)
        pcall(function()
            clone:ScaleTo(scaleFactor)
        end)

        local meshParts = {}
        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA('WeldConstraint') then
                d:Destroy()
            elseif d:IsA('BasePart') then
                d.Anchored = true
                d.CanCollide = false
                d.CanQuery = false
                d.CanTouch = false
                d.Massless = true
                d.CastShadow = false
                if d:IsA('MeshPart') then
                    table.insert(meshParts, {
                        Part = d,
                        OrigTrans = d.Transparency,
                    })
                end
            end
        end

        local boxCF, boxSize = clone:GetBoundingBox()
        if assetName == 'Wep_CryoRailgun' then
            clone.PrimaryPart.CFrame = CFrame.new(boxCF.Position)
        else
            clone.PrimaryPart.CFrame = CFrame.new(boxCF.Position.X, boxCF.Position.Y - boxSize.Y * 0.28, boxCF.Position.Z)
        end

        local horizontalBarrel = (assetName == 'Wep_CryoRailgun') and (boxSize.X >= boxSize.Y)
        clone.Parent = folder

        local entry = {
            Model = clone,
            AssetName = assetName,
            CacheKey = cacheKey,
            IsGun = isGun == true,
            HorizontalBarrel = horizontalBarrel,
            BoxSize = boxSize,
            MeshParts = meshParts,
            Visible = true,
        }
        s.WeaponCache[cacheKey] = entry
        if not isGun then
            configureWeaponTrail(entry, assetName, s.EnhanceLevel or 0, isLowFX(s.Owner))
        end
    end)

    return nil
end

local function hideLegacyBakedWeaponParts(s)
    if not s or not s.WeaponParts then
        return
    end
    for _, part in ipairs(s.WeaponParts) do
        if part and part.Parent then
            if part.LocalTransparencyModifier ~= 1 then
                part.LocalTransparencyModifier = 1
            end
            if part.Transparency ~= 1 then
                part.Transparency = 1
            end
        end
    end
end

function M.StepCharacterWeapons(Renderer, s, now)
    if not s or not s.Visual or not s.Visual.Parent or not s.Root or not s.Root.Parent then
        return
    end
    computeBindBasis(s)
    hideLegacyBakedWeaponParts(s)

    local ch = s.Character
    local plr = s.Owner
    local lowFX = isLowFX(plr)
    local isBeastTransform = (s.TransformFX and s.TransformFX.V5Model and s.TransformFX.V5Model.Parent ~= nil)

    local activeSlot = tonumber((ch and (ch:GetAttribute('ActiveSlot') or ch:GetAttribute('EquippedSlot')))
        or (plr and (plr:GetAttribute('ActiveSlot') or plr:GetAttribute('EquippedSlot')))) or 3

    local swordId = tostring((ch and ch:GetAttribute('EquippedSword'))
        or (plr and plr:GetAttribute('EquippedSword')) or '')
    local gunId = tostring((ch and ch:GetAttribute('EquippedGun'))
        or (plr and plr:GetAttribute('EquippedGun')) or 'soul_guitar_void')
    local enhanceLv = tonumber((plr and plr:GetAttribute('WeaponEnhance'))
        or (ch and ch:GetAttribute('WeaponEnhance')) or s.EnhanceLevel) or 0

    local swordSpec = resolveSwordAssets(Renderer, swordId, s.ClassId)
    local gunAsset, resolvedGunId = resolveGunAsset(Renderer, gunId)
    local isDualGun = Expansion3D.IsDualGun(resolvedGunId)

    local rSwordKey = 'SwordR_' .. swordSpec.RightAsset
    local lSwordKey = swordSpec.IsDual and ('SwordL_' .. swordSpec.LeftAsset) or nil
    local gunKey = 'Gun_' .. gunAsset
    local lGunKey = isDualGun and ('GunL_' .. gunAsset) or nil

    local rSword = ensureCachedWeapon(Renderer, s, rSwordKey, swordSpec.RightAsset, false)
    local lSword = lSwordKey and ensureCachedWeapon(Renderer, s, lSwordKey, swordSpec.LeftAsset, false) or nil
    -- Pre-warm gun model(s) into WeaponCache so pressing [4] swaps in 0ms
    local gunEntry = ensureCachedWeapon(Renderer, s, gunKey, gunAsset, true)
    local lGunEntry = lGunKey and ensureCachedWeapon(Renderer, s, lGunKey, gunAsset, true) or nil

    -- Hide any stale cached weapons from previous sword/gun equips in 0ms (kept cached for instant swap back!)
    if s.WeaponCache then
        for key, entry in pairs(s.WeaponCache) do
            if not entry.Building and key ~= rSwordKey and key ~= lSwordKey and key ~= gunKey and key ~= lGunKey then
                setWeaponEntryVisible(entry, false, false, lowFX)
            end
        end
    end

    if isBeastTransform then
        setWeaponEntryVisible(rSword, false, false, lowFX)
        setWeaponEntryVisible(lSword, false, false, lowFX)
        setWeaponEntryVisible(gunEntry, false, false, lowFX)
        setWeaponEntryVisible(lGunEntry, false, false, lowFX)
        return
    end

    local scaleRatio = (s.CurrentScale or 2.6) / 2.6
    local rHandCF = getBoneWorldCF(s, s._EquipRHand, CFrame.new(1.25, 0.25, -0.55))
    local lHandCF = getBoneWorldCF(s, s._EquipLHand, CFrame.new(-1.25, 0.25, -0.55))
    local torsoCF = getBoneWorldCF(s, s._EquipTorso, CFrame.new(0, 0.85, 0))
    local torsoAligned = torsoCF * (s._TorsoModelBasis or CFrame.identity)

    local isSwinging = (now < (s.Until or 0))
    local velMag = s.Root.AssemblyLinearVelocity.Magnitude
    local trailActive = (activeSlot == 3) and (isSwinging or velMag > 14)

    if rSword and (rSword.TrailLevel ~= enhanceLv or rSword.TrailItem ~= swordSpec.SwordId) then
        configureWeaponTrail(rSword, swordSpec.SwordId, enhanceLv, lowFX)
    end
    if lSword and (lSword.TrailLevel ~= enhanceLv or lSword.TrailItem ~= swordSpec.SwordId) then
        configureWeaponTrail(lSword, swordSpec.SwordId, enhanceLv, lowFX)
    end

    -- SLOT [3] SWORD: Drawn in RightHand (+ LeftHand simultaneously for Cursed Dual Skyblades!)
    if activeSlot == 3 then
        if rSword and rSword.Model then
            setWeaponEntryVisible(rSword, true, trailActive, lowFX)
            local gripCF = rHandCF * (s._RightSwordRot or CFrame.identity) * CFrame.new(0, -0.12 * scaleRatio, 0)
            pivotWeaponEntry(rSword, gripCF, now)
        end
        if lSword and lSword.Model then
            setWeaponEntryVisible(lSword, true, trailActive, lowFX)
            local gripL = lHandCF * (s._LeftSwordRot or CFrame.identity) * CFrame.new(0, -0.12 * scaleRatio, 0)
            pivotWeaponEntry(lSword, gripL, now)
        end
        setWeaponEntryVisible(gunEntry, false, false, lowFX)
        setWeaponEntryVisible(lGunEntry, false, false, lowFX)
    else
        -- SLOTS [1] MELEE, [2] DEVIL FRUIT, [4] GUN: Sword(s) holster cleanly on UpperTorso back!
        if rSword and rSword.Model then
            setWeaponEntryVisible(rSword, true, false, lowFX)
            local tiltZ = swordSpec.IsDual and math.rad(32) or math.rad(34)
            local backOff = CFrame.new((swordSpec.IsDual and 0.35 or 0.15) * scaleRatio, 0.45 * scaleRatio, 0.68 * scaleRatio)
                * CFrame.Angles(0, math.pi, math.pi + tiltZ)
            pivotWeaponEntry(rSword, torsoAligned * backOff, now)
        end
        if lSword and lSword.Model then
            setWeaponEntryVisible(lSword, true, false, lowFX)
            local backOffL = CFrame.new(-0.35 * scaleRatio, 0.45 * scaleRatio, 0.74 * scaleRatio)
                * CFrame.Angles(0, math.pi, math.pi - math.rad(32))
            pivotWeaponEntry(lSword, torsoAligned * backOffL, now)
        end

        -- SLOT [4] GUN: Snap 3D Gun / Bow / Dual Chrono Pistols into RightHand (+ LeftHand) in 0ms!
        if activeSlot == 4 and gunEntry and gunEntry.Model then
            setWeaponEntryVisible(gunEntry, true, false, lowFX)
            local gunRot = s._RightGunRot or CFrame.identity
            local extraAlign
            if gunEntry.HorizontalBarrel then
                extraAlign = CFrame.Angles(0, 0, math.pi * 0.5) * CFrame.new(0.45 * scaleRatio, 0, 0)
            elseif resolvedGunId:find('guitar') or gunAsset == 'Wep_SoulGuitarVoid' then
                extraAlign = CFrame.Angles(math.rad(18), 0, -math.rad(22)) * CFrame.new(0, -0.15 * scaleRatio, 0)
            else
                extraAlign = CFrame.identity
            end
            pivotWeaponEntry(gunEntry, rHandCF * gunRot * extraAlign, now)
            if lGunEntry and lGunEntry.Model then
                setWeaponEntryVisible(lGunEntry, true, false, lowFX)
                local lGunRot = s._LeftGunRot or CFrame.identity
                pivotWeaponEntry(lGunEntry, lHandCF * lGunRot * extraAlign, now)
            end
        else
            setWeaponEntryVisible(gunEntry, false, false, lowFX)
            setWeaponEntryVisible(lGunEntry, false, false, lowFX)
        end
    end
end

-- ============================================================================
-- 2. REAL SKINNED 3D RACE V4 WINGS (Wing_Skyborn..Wing_Draco) (#2 Equip)
-- ============================================================================
local function classifyWingBone(bone)
    local name = bone.Name
    local low = string.lower(name)
    if low:find('_root') or low:sub(-4) == 'root' then
        return nil
    end
    local side = 0
    if name:sub(-2) == '_L' or low:find('_l_') or low:find('left') then
        side = -1
    elseif name:sub(-2) == '_R' or low:find('_r_') or low:find('right') then
        side = 1
    end
    local depth = 0
    local p = bone.Parent
    while p and p:IsA('Bone') do
        depth += 1
        p = p.Parent
    end
    local role = 'Wing'
    if low:find('halo') or low:find('ring') or low:find('crown') then
        role = 'Halo'
    elseif low:find('tail') or low:find('ribbon') then
        role = 'Ribbon'
    elseif low:find('chain') or low:find('shackle') then
        role = 'Chain'
    elseif low:find('flame') or low:find('jet') or low:find('thruster') then
        role = 'Jet'
    elseif low:find('fin') then
        role = 'Fin'
    elseif low:find('spine') or low:find('core') then
        role = 'Core'
    end
    return {
        Bone = bone,
        Role = role,
        Side = side ~= 0 and side or 1,
        HasSide = (side ~= 0),
        Depth = depth,
    }
end

function M.BuildRaceV4Wings(Renderer, s, raceName)
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

    computeBindBasis(s)
    local wingAsset = (Renderer.GetRaceWingAsset and Renderer.GetRaceWingAsset(raceName)) or 'Wing_Skyborn'

    local folder = Instance.new('Folder')
    folder.Name = 'RaceV4FX'
    folder:SetAttribute('RaceV4', raceName)
    folder:SetAttribute('WingAsset', wingAsset)
    folder.Parent = s.Visual

    local fxData = {
        Race = raceName,
        WingAsset = wingAsset,
        Folder = folder,
        TorsoBone = s._EquipTorso or findBone(s.Visual, { 'UpperTorso', 'Spine2', 'Spine', 'Torso' }),
        RigBones = {},
        WingModel = nil,
    }
    s.RaceFX = fxData

    ensureTemplateAsync(Renderer, wingAsset, function()
        if not s.Visual or not s.Visual.Parent or s.RaceFX ~= fxData or not folder.Parent then
            return
        end
        local okW, clone = pcall(function()
            if Renderer.CloneModel then
                return Renderer.CloneModel(wingAsset, 0, noopProgress)
            end
            local tpl = templateCache[wingAsset] or Renderer.Build(wingAsset, noopProgress)
            return tpl and tpl:Clone() or nil
        end)
        if not okW or not clone or not clone.PrimaryPart then
            return
        end

        clone.Name = wingAsset .. '_Skinned3D'
        local _, rawSize = clone:GetBoundingBox()
        local rawSpan = math.max(rawSize.X, rawSize.Y, 1.0)
        local targetWingSpan = 7.4
        pcall(function()
            clone:ScaleTo(math.clamp(targetWingSpan / rawSpan, 0.9, 2.8))
        end)

        -- Keep RootPart Anchored=true and skinned MeshParts Anchored=false + welded to RootPart
        -- so RootPart.CFrame moves the entire rig AND Bone.Transform deforms skinned vertices at 60 FPS!
        local rootPart = clone.PrimaryPart
        rootPart.Anchored = true
        rootPart.CanCollide = false
        rootPart.CanQuery = false
        rootPart.CanTouch = false
        for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA('BasePart') and d ~= rootPart then
                d.Anchored = false
                d.CanCollide = false
                d.CanQuery = false
                d.CanTouch = false
                d.Massless = true
                d.CastShadow = false
                if not d:FindFirstChildOfClass('WeldConstraint') then
                    local w = Instance.new('WeldConstraint')
                    w.Part0 = rootPart
                    w.Part1 = d
                    w.Parent = d
                end
            elseif d:IsA('Bone') then
                local info = classifyWingBone(d)
                if info then
                    table.insert(fxData.RigBones, info)
                end
            end
        end

        if not isLowFX(s.Owner) then
            local glowColors = {
                Wing_Skyborn = Color3.fromRGB(255, 224, 118),
                Wing_Mink = Color3.fromRGB(82, 238, 255),
                Wing_Leviathan = Color3.fromRGB(58, 178, 255),
                Wing_Cyborg = Color3.fromRGB(255, 76, 198),
                Wing_Ghoul = Color3.fromRGB(235, 42, 78),
                Wing_Draco = Color3.fromRGB(255, 112, 42),
            }
            local pl = Instance.new('PointLight')
            pl.Name = 'RaceV4WingLight'
            pl.Color = glowColors[wingAsset] or Color3.fromRGB(255, 224, 118)
            pl.Brightness = 0.75
            pl.Range = 9
            pl.Shadows = false
            pl.Parent = rootPart
        end

        clone.Parent = folder
        fxData.WingModel = clone
    end)
end

function M.StepRaceV4Wings(s, now)
    local fx = s and s.RaceFX
    if not fx or not fx.Folder or not fx.Folder.Parent or not s.Root or not s.Root.Parent then
        return
    end
    local wingModel = fx.WingModel
    if not wingModel or not wingModel.PrimaryPart or not wingModel.Parent then
        return
    end

    local isBeastTransform = (s.TransformFX and s.TransformFX.V5Model and s.TransformFX.V5Model.Parent ~= nil)
    if isBeastTransform then
        if not fx.HiddenForBeast then
            fx.HiddenForBeast = true
            for _, d in ipairs(fx.Folder:GetDescendants()) do
                if d:IsA('BasePart') then
                    d.LocalTransparencyModifier = 1
                elseif d:IsA('PointLight') or d:IsA('Trail') or d:IsA('ParticleEmitter') then
                    d.Enabled = false
                end
            end
        end
        return
    elseif fx.HiddenForBeast then
        fx.HiddenForBeast = false
        local low = isLowFX(s.Owner)
        for _, d in ipairs(fx.Folder:GetDescendants()) do
            if d:IsA('BasePart') then
                d.LocalTransparencyModifier = 0
            elseif d:IsA('PointLight') or d:IsA('Trail') or d:IsA('ParticleEmitter') then
                d.Enabled = not low
            end
        end
    end

    computeBindBasis(s)
    local scaleRatio = (s.CurrentScale or 2.6) / 2.6
    local torsoCF = getBoneWorldCF(s, fx.TorsoBone, CFrame.new(0, 0.9, 0))
    local torsoAligned = torsoCF * (s._TorsoModelBasis or CFrame.identity)

    local vel = s.Root.AssemblyLinearVelocity
    local speed = vel.Magnitude
    local mode = s.H and s.H:GetState() or Enum.HumanoidStateType.Running
    local airborne = (mode == Enum.HumanoidStateType.Jumping or mode == Enum.HumanoidStateType.Freefall)
    local isDashing = (now < (s.Until or 0)) and (tostring(s.Name):find('Dash') ~= nil or tostring(s.Name):find('Jump') ~= nil)

    local flapFreq = 2.5
    local flapAmp = 0.20
    local sweepBack = 0.10
    if isDashing then
        flapFreq = 8.4
        flapAmp = 0.42
        sweepBack = 0.34
    elseif airborne then
        flapFreq = 5.6
        flapAmp = 0.34
        sweepBack = 0.20
    elseif speed > 10 then
        flapFreq = 4.1
        flapAmp = 0.25
        sweepBack = 0.24
    end

    local breatheY = math.sin(now * 2.2) * 0.06 * scaleRatio
    -- Orient wing front outward from back (+Z behind character -> rotate Y by math.pi if front-authored)
    local backMountCF = torsoAligned * CFrame.new(0, (0.38 + breatheY) * scaleRatio, 0.56 * scaleRatio) * CFrame.Angles(0, math.pi, 0)
    wingModel.PrimaryPart.CFrame = backMountCF

    for i = 1, #fx.RigBones do
        local entry = fx.RigBones[i]
        local b = entry.Bone
        if b and b.Parent then
            local phase = now * flapFreq - entry.Depth * 0.48
            local side = entry.Side
            local role = entry.Role
            if role == 'Halo' then
                b.Transform = CFrame.new(0, math.sin(now * 2.6) * 0.08, 0) * CFrame.Angles(math.sin(now * 1.7) * 0.08, now * 1.85, 0)
            elseif role == 'Ribbon' then
                local wave = math.sin(now * (flapFreq * 1.25) - entry.Depth * 0.65 + side * 0.5) * (0.22 + sweepBack * 0.5)
                b.Transform = CFrame.Angles(sweepBack * 0.6 + wave * 0.5, side * wave, wave * 0.35)
            elseif role == 'Chain' then
                local swing = math.sin(now * 3.4 - entry.Depth * 0.55 + side * 0.8) * (0.16 + math.min(speed / 90, 0.22))
                b.Transform = CFrame.Angles(sweepBack * 0.7 + math.abs(swing) * 0.3, 0, side * swing)
            elseif role == 'Jet' then
                local pulse = math.sin(now * 16 + side) * (airborne and 0.14 or 0.06)
                b.Transform = CFrame.Angles(-sweepBack * 0.5 + pulse, side * (0.12 + pulse * 0.5), 0)
            elseif role == 'Fin' then
                local finWave = math.sin(phase) * (flapAmp * 1.1)
                b.Transform = CFrame.Angles(finWave * 0.35, side * (finWave + sweepBack * 0.4), -side * finWave * 0.45)
            elseif role == 'Core' then
                local undulate = math.sin(now * 3.2 - entry.Depth * 0.5) * 0.10
                b.Transform = CFrame.Angles(undulate, 0, math.cos(now * 2.4) * 0.06)
            else
                local flap = math.sin(phase) * flapAmp
                local tipFlex = (entry.Depth >= 2) and (math.cos(phase) * flapAmp * 0.35) or 0
                b.Transform = CFrame.Angles(
                    flap * 0.24 - sweepBack * 0.3,
                    side * (flap + sweepBack + tipFlex),
                    -side * flap * 0.38
                )
            end
        end
    end
end

-- ============================================================================
-- 3. VISIBLE 3D CHARACTER ACCESSORIES (#55)
-- ============================================================================
local function createClothRibbonTrail(parentPart, p0, p1, c1, c2, lowFX)
    local a0 = Instance.new('Attachment')
    a0.Name = 'ClothAtt0'
    a0.Position = p0
    a0.Parent = parentPart
    local a1 = Instance.new('Attachment')
    a1.Name = 'ClothAtt1'
    a1.Position = p1
    a1.Parent = parentPart
    local tr = Instance.new('Trail')
    tr.Name = 'ClothRibbonTrail'
    tr.Attachment0 = a0
    tr.Attachment1 = a1
    tr.FaceCamera = false
    tr.LightEmission = 0.2
    tr.LightInfluence = 0.75
    tr.Lifetime = lowFX and 0.14 or 0.26
    tr.MinLength = 0.05
    tr.Color = ColorSequence.new(c1, c2)
    tr.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.35),
        NumberSequenceKeypoint.new(0.65, 0.68),
        NumberSequenceKeypoint.new(1, 1.0),
    })
    tr.WidthScale = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1.0),
        NumberSequenceKeypoint.new(1, 0.35),
    })
    tr.Enabled = not lowFX
    tr.Parent = parentPart
    return tr
end

local function readAccessoryKey(ch, plr)
    local parts = {}
    for _, attr in ipairs({
        'EquippedAccessory',
        'EquippedArmor',
        'EquippedChest',
        'EquippedHelmet',
        'EquippedHelm',
        'EquippedGauntlets',
        'EquippedGloves',
        'EquippedGreaves',
        'EquippedBoots',
        'EquippedRing',
        'EquippedNecklace',
        'EquippedOffhand',
        'EquippedArtifact',
    }) do
        local v = tostring((ch and ch:GetAttribute(attr)) or (plr and plr:GetAttribute(attr)) or '')
        table.insert(parts, v)
    end
    return table.concat(parts, '|')
end

local function hasToken(keyLower, tokens)
    for _, t in ipairs(tokens) do
        if keyLower:find(t, 1, true) then
            return true
        end
    end
    return false
end

local function resolveArmorTheme(tokenStr)
    local t = string.lower(tostring(tokenStr or ''))
    if t:find('veyr') or t:find('architect') or t:find('singularity') or t:find('genesis') then
        return {
            Kind = 'veyr',
            Accent = Color3.fromRGB(244, 63, 94),
            Trim = Color3.fromRGB(244, 193, 78),
            Metal = Color3.fromRGB(30, 22, 43),
            Cloth = Color3.fromRGB(136, 19, 55),
        }
    elseif t:find('aion') or t:find('chrono') then
        return {
            Kind = 'aion',
            Accent = Color3.fromRGB(192, 132, 252),
            Trim = Color3.fromRGB(103, 232, 249),
            Metal = Color3.fromRGB(30, 32, 68),
            Cloth = Color3.fromRGB(59, 28, 112),
        }
    elseif t:find('nerith') or t:find('tidal') or t:find('leviathan') then
        return {
            Kind = 'nerith',
            Accent = Color3.fromRGB(34, 211, 238),
            Trim = Color3.fromRGB(165, 243, 252),
            Metal = Color3.fromRGB(20, 48, 74),
            Cloth = Color3.fromRGB(18, 74, 110),
        }
    elseif t:find('ignivar') or t:find('drake') or t:find('lava') or t:find('molten') then
        return {
            Kind = 'ignivar',
            Accent = Color3.fromRGB(249, 115, 22),
            Trim = Color3.fromRGB(251, 191, 36),
            Metal = Color3.fromRGB(48, 24, 24),
            Cloth = Color3.fromRGB(124, 34, 18),
        }
    elseif t:find('sylvaris') or t:find('antler') or t:find('root') then
        return {
            Kind = 'sylvaris',
            Accent = Color3.fromRGB(52, 211, 153),
            Trim = Color3.fromRGB(217, 249, 157),
            Metal = Color3.fromRGB(26, 54, 44),
            Cloth = Color3.fromRGB(20, 83, 58),
        }
    elseif t:find('noxar') or t:find('sovereign') or t:find('abyss') then
        return {
            Kind = 'noxar',
            Accent = Color3.fromRGB(168, 85, 247),
            Trim = Color3.fromRGB(224, 182, 74),
            Metal = Color3.fromRGB(32, 18, 46),
            Cloth = Color3.fromRGB(148, 28, 48),
        }
    elseif t:find('cryon') or t:find('cyber') or t:find('reactor') then
        return {
            Kind = 'cryon',
            Accent = Color3.fromRGB(34, 211, 238),
            Trim = Color3.fromRGB(224, 242, 254),
            Metal = Color3.fromRGB(30, 45, 68),
            Cloth = Color3.fromRGB(24, 58, 92),
        }
    elseif t:find('aureon') or t:find('sunplate') or t:find('halo') or t:find('solar') then
        return {
            Kind = 'aureon',
            Accent = Color3.fromRGB(244, 193, 78),
            Trim = Color3.fromRGB(255, 238, 168),
            Metal = Color3.fromRGB(238, 232, 214),
            Cloth = Color3.fromRGB(236, 240, 248),
        }
    elseif t:find('mirage') or t:find('phantom') then
        return {
            Kind = 'mirage',
            Accent = Color3.fromRGB(96, 165, 250),
            Trim = Color3.fromRGB(191, 219, 254),
            Metal = Color3.fromRGB(26, 36, 58),
            Cloth = Color3.fromRGB(30, 46, 78),
        }
    elseif t:find('azure') or t:find('skyward') then
        return {
            Kind = 'azure',
            Accent = Color3.fromRGB(56, 189, 248),
            Trim = Color3.fromRGB(224, 182, 74),
            Metal = Color3.fromRGB(30, 58, 95),
            Cloth = Color3.fromRGB(232, 236, 244),
        }
    end
    return {
        Kind = 'skyborn',
        Accent = Color3.fromRGB(96, 165, 250),
        Trim = Color3.fromRGB(224, 182, 74),
        Metal = Color3.fromRGB(43, 59, 84),
        Cloth = Color3.fromRGB(28, 44, 86),
    }
end

function M.BuildCharacterAccessories(s, rawKey)
    if not s or not s.Visual or not s.Visual.Parent then
        return
    end
    local old = s.Visual:FindFirstChild('CharacterAccessories3D')
    if old then
        old:Destroy()
    end
    s.AccessoryFX = nil
    s.AccessoryKey = rawKey or ''
    if s.AccessoryKey == '' or s.AccessoryKey:gsub('|', '') == '' then
        return
    end

    computeBindBasis(s)
    local keyLower = string.lower(s.AccessoryKey)
    local lowFX = isLowFX(s.Owner)
    local ch = s.Character
    local plr = s.Owner

    local function readAttrLower(names)
        for _, n in ipairs(names) do
            local v = tostring((ch and ch:GetAttribute(n)) or (plr and plr:GetAttribute(n)) or '')
            if v ~= '' then
                return string.lower(v)
            end
        end
        return ''
    end

    local helmToken = readAttrLower({ 'EquippedHelmet', 'EquippedHelm' })
    local chestToken = readAttrLower({ 'EquippedChest', 'EquippedArmor' })
    local gauntToken = readAttrLower({ 'EquippedGauntlets', 'EquippedGloves' })
    local greaveToken = readAttrLower({ 'EquippedGreaves', 'EquippedBoots' })
    local relicToken = readAttrLower({ 'EquippedArtifact', 'EquippedRing', 'EquippedNecklace' })

    local wantHelm = helmToken ~= '' or hasToken(keyLower, {
        'solar_crown', 'skyward_helm', 'skyhelm', 'core_artifact', 'coreshardartifact', 'vuong_mien', 'crown',
        'aureon_halo_helm', 'cryon_cyber_helm', 'noxar_horns', 'sylvaris_antler_crown', 'nerith_tidal_diadem',
        'veyr_architect_crown', 'mirage_phantom_hood', 'helm', 'diadem', 'hood',
    })
    local wantChest = chestToken ~= '' or hasToken(keyLower, {
        'sovereign_cloak', 'admiral_cape', 'skyward_chest', 'skyarmor', 'celestialplate', 'ao_choang', 'cloak', 'cape',
        'aureon_sunplate', 'cryon_reactor_plate', 'ignivar_drake_cuirass', 'aion_chrono_vestment',
        'veyr_singularity_armor', 'aion_chrono_cloak', 'cuirass', 'vestment', 'sunplate',
    })
    local wantGauntlets = gauntToken ~= '' or hasToken(keyLower, {
        'gauntlets', 'skyward_gloves', 'starlightgauntlets',
    })
    local wantGreaves = greaveToken ~= '' or hasToken(keyLower, {
        'greaves', 'skyward_boots', 'windstridergreaves',
    })
    local wantScarf = hasToken(keyLower, { 'aether_scarf', 'celestial_necklace', 'khan_choang', 'scarf' })
    local wantVisor = hasToken(keyLower, { 'cyborg_visor', 'kinh_cyborg', 'visor', 'cryon_cyber_helm' })
    local wantHorns = hasToken(keyLower, { 'noxar_horns', 'sung_noxar', 'horns' })
    local wantShield = hasToken(keyLower, { 'leviathan_shield', 'aureoncrestshield', 'shield' })
    local wantRelic = relicToken ~= '' or hasToken(keyLower, {
        'aureon_sun_ring', 'cryon_frost_reactor', 'noxar_eclipse_ring', 'sylvaris_life_amulet',
        'ignivar_molten_heart', 'nerith_leviathan_ring', 'veyr_genesis_core',
    })

    if not (wantHelm or wantChest or wantGauntlets or wantGreaves or wantScarf or wantVisor or wantHorns or wantShield or wantRelic) then
        return
    end

    local folder = Instance.new('Folder')
    folder.Name = 'CharacterAccessories3D'
    folder:SetAttribute('AccessoryKey', s.AccessoryKey)
    folder.Parent = s.Visual

    local data = {
        Folder = folder,
        HeadParts = {},
        HaloParts = {},
        TorsoParts = {},
        CloakPanels = {},
        ScarfTails = {},
        ShieldParts = {},
        ArmParts = {},
        LegParts = {},
    }

    local helmTheme = resolveArmorTheme(helmToken ~= '' and helmToken or keyLower)
    local chestTheme = resolveArmorTheme(chestToken ~= '' and chestToken or keyLower)
    local gauntTheme = resolveArmorTheme(gauntToken ~= '' and gauntToken or keyLower)
    local greaveTheme = resolveArmorTheme(greaveToken ~= '' and greaveToken or keyLower)
    local gold = Color3.fromRGB(224, 182, 74)

    -- 1. 3D Chest Cuirass, Theme Pauldrons & Wind-Reactive Draped Cloak (All 8 Armor Sets + Cloaks)
    if wantChest then
        local collar = makePart(folder, 'ArmorCollar', Vector3.new(1.95, 0.44, 0.96), chestTheme.Metal, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.12)
        table.insert(data.TorsoParts, { Part = collar, Offset = CFrame.new(0, 0.92, 0.12) })

        local cuirass = makePart(folder, 'ArmorBreastplate', Vector3.new(1.88, 1.48, 1.08), chestTheme.Metal, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.14)
        table.insert(data.TorsoParts, { Part = cuirass, Offset = CFrame.new(0, 0.18, -0.02) })

        local coreGem = makePart(folder, 'ArmorReactorCore', Vector3.new(0.24, 0.46, 0.46), chestTheme.Accent, Enum.PartType.Cylinder, 0.05, 'Part', Enum.Material.Neon, 0)
        table.insert(data.TorsoParts, {
            Part = coreGem,
            Offset = CFrame.new(0, 0.34, -0.50) * CFrame.Angles(0, math.pi * 0.5, 0),
        })

        local trimBelt = makePart(folder, 'ArmorWaistTrim', Vector3.new(1.94, 0.18, 1.12), chestTheme.Trim, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.18)
        table.insert(data.TorsoParts, { Part = trimBelt, Offset = CFrame.new(0, -0.46, -0.01) })

        for _, side in ipairs({ -1, 1 }) do
            local pauldron = makePart(folder, 'ArmorPauldron_' .. side, Vector3.new(0.84, 0.42, 0.98), chestTheme.Metal, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.15)
            table.insert(data.TorsoParts, {
                Part = pauldron,
                Offset = CFrame.new(side * 1.18, 0.88, 0.02) * CFrame.Angles(0, 0, -side * 0.22),
            })
            local crest = makePart(folder, 'ArmorPauldronCrest_' .. side, Vector3.new(0.18, 0.34, 0.82), chestTheme.Accent, Enum.PartType.Block, 0.04, 'WedgePart', Enum.Material.Neon, 0)
            table.insert(data.TorsoParts, {
                Part = crest,
                Offset = CFrame.new(side * 1.32, 1.10, 0.02) * CFrame.Angles(0, side > 0 and math.pi * 0.5 or -math.pi * 0.5, -side * 0.28),
            })
            local clasp = makePart(folder, 'ArmorClasp_' .. side, Vector3.new(0.24, 0.24, 0.16), chestTheme.Trim, Enum.PartType.Cylinder, 0, 'Part', Enum.Material.Metal, 0.14)
            table.insert(data.TorsoParts, {
                Part = clasp,
                Offset = CFrame.new(side * 0.72, 0.76, -0.52) * CFrame.Angles(0, math.pi * 0.5, 0),
            })
        end

        local panelHeights = { 1.15, 1.35, 1.45 }
        local panelWidths = { 2.15, 2.42, 2.68 }
        for idx = 1, 3 do
            local p = makePart(
                folder,
                'ArmorCloakPanel_' .. idx,
                Vector3.new(panelWidths[idx], panelHeights[idx], 0.12),
                chestTheme.Cloth,
                Enum.PartType.Block,
                0,
                'Part',
                Enum.Material.SmoothPlastic,
                0
            )
            local trim = nil
            if idx == 3 then
                trim = makePart(folder, 'ArmorCloakHem', Vector3.new(panelWidths[idx] + 0.04, 0.18, 0.14), chestTheme.Trim, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.10)
                createClothRibbonTrail(p, Vector3.new(-1.1, -0.65, 0), Vector3.new(-0.55, -0.65, 0), chestTheme.Accent, chestTheme.Trim, lowFX)
                createClothRibbonTrail(p, Vector3.new(0.55, -0.65, 0), Vector3.new(1.1, -0.65, 0), chestTheme.Accent, chestTheme.Trim, lowFX)
            end
            table.insert(data.CloakPanels, {
                Part = p,
                Trim = trim,
                Index = idx,
                Height = panelHeights[idx],
            })
        end
    end

    -- 2. 3D Theme Headgear (Halo Crown, Cyber Visor Helm, Antler Crown, Tidal Diadem, Phantom Hood, Architect Floating Crown)
    if wantHelm then
        local hKind = helmTheme.Kind
        if hKind == 'mirage' or helmToken:find('hood') then
            -- Phantom Hood Cowl
            local cowlTop = makePart(folder, 'PhantomHoodTop', Vector3.new(1.36, 0.92, 1.38), helmTheme.Cloth, Enum.PartType.Block, 0, 'Part', Enum.Material.SmoothPlastic, 0)
            local cowlBrim = makePart(folder, 'PhantomHoodBrim', Vector3.new(1.40, 0.24, 0.65), helmTheme.Trim, Enum.PartType.Block, 0, 'WedgePart', Enum.Material.SmoothPlastic, 0)
            local glowBrow = makePart(folder, 'PhantomHoodGlow', Vector3.new(0.92, 0.12, 0.16), helmTheme.Accent, Enum.PartType.Block, 0.08, 'Part', Enum.Material.Neon, 0)
            table.insert(data.HeadParts, { Part = cowlTop, Offset = CFrame.new(0, 0.34, 0.06) })
            table.insert(data.HeadParts, { Part = cowlBrim, Offset = CFrame.new(0, 0.66, -0.44) * CFrame.Angles(0.22, math.pi, 0) })
            table.insert(data.HeadParts, { Part = glowBrow, Offset = CFrame.new(0, 0.22, -0.56) })
        elseif hKind == 'sylvaris' then
            -- Emerald Antler Crown
            local circlet = makePart(folder, 'AntlerCirclet', Vector3.new(0.18, 1.24, 1.24), helmTheme.Trim, Enum.PartType.Cylinder, 0, 'Part', Enum.Material.Metal, 0.12)
            table.insert(data.HeadParts, { Part = circlet, Offset = CFrame.new(0, 0.56, 0) * CFrame.Angles(0, 0, math.pi * 0.5) })
            for _, side in ipairs({ -1, 1 }) do
                local mainBranch = makePart(folder, 'AntlerMain_' .. side, Vector3.new(0.14, 0.96, 0.18), helmTheme.Accent, Enum.PartType.Block, 0.04, 'WedgePart', Enum.Material.Neon, 0)
                local tine = makePart(folder, 'AntlerTine_' .. side, Vector3.new(0.10, 0.52, 0.14), helmTheme.Trim, Enum.PartType.Block, 0.04, 'WedgePart', Enum.Material.Neon, 0)
                local bOff = CFrame.new(side * 0.62, 0.86, -0.10) * CFrame.Angles(-0.18, 0, -side * 0.42)
                table.insert(data.HeadParts, { Part = mainBranch, Offset = bOff })
                table.insert(data.HeadParts, { Part = tine, Offset = bOff * CFrame.new(side * 0.16, 0.26, -0.16) * CFrame.Angles(0.42, 0, -side * 0.35) })
            end
        elseif hKind == 'cryon' or hKind == 'skyborn' then
            -- Armored Tactical Visor Helm
            local dome = makePart(folder, 'CyberHelmDome', Vector3.new(1.28, 0.68, 1.32), helmTheme.Metal, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.16)
            local crestFin = makePart(folder, 'CyberHelmCrest', Vector3.new(0.16, 0.34, 1.18), helmTheme.Accent, Enum.PartType.Block, 0.05, 'WedgePart', Enum.Material.Neon, 0)
            table.insert(data.HeadParts, { Part = dome, Offset = CFrame.new(0, 0.48, 0.04) })
            table.insert(data.HeadParts, { Part = crestFin, Offset = CFrame.new(0, 0.88, 0.02) })
            for _, side in ipairs({ -1, 1 }) do
                local earFin = makePart(folder, 'CyberHelmFin_' .. side, Vector3.new(0.12, 0.48, 0.32), helmTheme.Trim, Enum.PartType.Block, 0, 'WedgePart', Enum.Material.Metal, 0.14)
                table.insert(data.HeadParts, { Part = earFin, Offset = CFrame.new(side * 0.68, 0.36, 0.08) * CFrame.Angles(-0.24, 0, -side * 0.18) })
            end
        elseif hKind == 'nerith' or hKind == 'aion' then
            -- Tidal Diadem with Trident Crest
            local band = makePart(folder, 'TidalDiademBand', Vector3.new(0.18, 1.24, 1.24), helmTheme.Metal, Enum.PartType.Cylinder, 0, 'Part', Enum.Material.Metal, 0.15)
            local pearl = makePart(folder, 'TidalDiademPearl', Vector3.new(0.26, 0.26, 0.26), helmTheme.Accent, Enum.PartType.Ball, 0.02, 'Part', Enum.Material.Neon, 0)
            table.insert(data.HeadParts, { Part = band, Offset = CFrame.new(0, 0.58, 0) * CFrame.Angles(0, 0, math.pi * 0.5) })
            table.insert(data.HeadParts, { Part = pearl, Offset = CFrame.new(0, 0.72, -0.62) })
            for i = -1, 1 do
                local h = (i == 0) and 0.72 or 0.52
                local prong = makePart(folder, 'DiademProng_' .. i, Vector3.new(0.10, h, 0.16), i == 0 and helmTheme.Accent or helmTheme.Trim, Enum.PartType.Block, 0.04, 'WedgePart', Enum.Material.Neon, 0)
                table.insert(data.HeadParts, {
                    Part = prong,
                    Offset = CFrame.new(i * 0.28, 0.88 + h * 0.3, -0.56) * CFrame.Angles(-0.12, 0, -i * 0.22),
                })
            end
        elseif hKind == 'veyr' then
            -- Architect Floating Singularity Crown
            local floatRing = makePart(folder, 'ArchitectCrownRing', Vector3.new(0.12, 1.48, 1.48), helmTheme.Accent, Enum.PartType.Cylinder, 0.08, 'Part', Enum.Material.Neon, 0)
            table.insert(data.HaloParts, {
                Part = floatRing,
                BaseOffset = CFrame.new(0, 1.08, 0) * CFrame.Angles(0, 0, math.pi * 0.5),
                SpinAxis = 'Y',
            })
            for i = 1, 6 do
                local ang = (i - 1) * (math.pi / 3)
                local shard = makePart(folder, 'ArchitectCrownShard_' .. i, Vector3.new(0.12, 0.48, 0.18), i % 2 == 1 and helmTheme.Trim or helmTheme.Accent, Enum.PartType.Block, 0.02, 'WedgePart', Enum.Material.Neon, 0)
                table.insert(data.HaloParts, {
                    Part = shard,
                    BaseOffset = CFrame.new(math.sin(ang) * 0.72, 1.18, -math.cos(ang) * 0.72) * CFrame.Angles(-0.16, -ang, 0),
                    SpinAxis = 'Bob',
                    Phase = i * 0.9,
                })
            end
        elseif hKind ~= 'noxar' then
            -- Aureon Halo Crown / Azure Solar Crown
            local band = makePart(folder, 'SolarCrownBand', Vector3.new(0.22, 1.24, 1.24), helmTheme.Trim, Enum.PartType.Cylinder, 0, 'Part', Enum.Material.Metal, 0.14)
            table.insert(data.HeadParts, {
                Part = band,
                Offset = CFrame.new(0, 0.62, 0) * CFrame.Angles(0, 0, math.pi * 0.5),
            })
            for i = 1, 5 do
                local ang = (i - 3) * 0.46
                local spireH = (i == 3) and 0.68 or ((i == 2 or i == 4) and 0.50 or 0.36)
                local spire = makePart(
                    folder,
                    'SolarCrownSpire_' .. i,
                    Vector3.new(0.10, spireH, 0.20),
                    i == 3 and helmTheme.Accent or helmTheme.Trim,
                    Enum.PartType.Block,
                    0,
                    'WedgePart',
                    Enum.Material.Metal,
                    0.12
                )
                local r = 0.58
                table.insert(data.HeadParts, {
                    Part = spire,
                    Offset = CFrame.new(math.sin(ang) * r, 0.84 + spireH * 0.35, -math.cos(ang) * r)
                        * CFrame.Angles(-0.14, -ang, 0),
                })
            end
            if hKind == 'aureon' then
                local sunHalo = makePart(folder, 'AureonSunHalo', Vector3.new(0.10, 1.95, 1.95), helmTheme.Accent, Enum.PartType.Cylinder, 0.12, 'Part', Enum.Material.Neon, 0)
                table.insert(data.HaloParts, {
                    Part = sunHalo,
                    BaseOffset = CFrame.new(0, 0.72, 0.52) * CFrame.Angles(0, math.pi * 0.5, 0),
                    SpinAxis = 'Bob',
                    Phase = 0,
                })
            end
        end
    end

    -- 3. 3D Forearm Battle Gauntlets (LHand + RHand)
    if wantGauntlets then
        for _, side in ipairs({ -1, 1 }) do
            local cuff = makePart(folder, 'ArmorGauntletCuff_' .. side, Vector3.new(0.56, 0.76, 0.58), gauntTheme.Metal, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.16)
            local fin = makePart(folder, 'ArmorGauntletFin_' .. side, Vector3.new(0.12, 0.62, 0.28), gauntTheme.Accent, Enum.PartType.Block, 0.05, 'WedgePart', Enum.Material.Neon, 0)
            table.insert(data.ArmParts, {
                Part = cuff,
                Side = side,
                Offset = CFrame.new(0, 0.22, 0),
            })
            table.insert(data.ArmParts, {
                Part = fin,
                Side = side,
                Offset = CFrame.new(side * 0.30, 0.28, 0.04),
            })
        end
    end

    -- 4. 3D Winged / Armored Shin Greaves (LLeg + RLeg)
    if wantGreaves then
        for _, side in ipairs({ -1, 1 }) do
            local shin = makePart(folder, 'ArmorGreaveShin_' .. side, Vector3.new(0.60, 0.92, 0.64), greaveTheme.Metal, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.16)
            local wing = makePart(folder, 'ArmorGreaveWing_' .. side, Vector3.new(0.12, 0.56, 0.36), greaveTheme.Accent, Enum.PartType.Block, 0.05, 'WedgePart', Enum.Material.Neon, 0)
            table.insert(data.LegParts, {
                Part = shin,
                Side = side,
                Offset = CFrame.new(0, 0.05, -0.04),
            })
            table.insert(data.LegParts, {
                Part = wing,
                Side = side,
                Offset = CFrame.new(side * 0.34, 0.18, 0.10) * CFrame.Angles(-0.24, 0, 0),
            })
        end
    end

    -- 5. Khăn Choàng Aether (Aether Scarf)
    if wantScarf then
        local scarfCyan = Color3.fromRGB(76, 198, 238)
        local scarfLight = Color3.fromRGB(186, 240, 255)
        local cowl = makePart(folder, 'AetherScarfCowl', Vector3.new(0.36, 1.38, 1.38), scarfCyan, Enum.PartType.Cylinder, 0, 'Part', Enum.Material.SmoothPlastic, 0)
        table.insert(data.TorsoParts, {
            Part = cowl,
            Offset = CFrame.new(0, 1.02, -0.04) * CFrame.Angles(0.14, 0, math.pi * 0.5),
        })
        for _, side in ipairs({ -1, 1 }) do
            local tail = makePart(folder, 'AetherScarfTail_' .. side, Vector3.new(0.34, 1.85, 0.08), scarfCyan, Enum.PartType.Block, 0, 'Part', Enum.Material.SmoothPlastic, 0)
            createClothRibbonTrail(tail, Vector3.new(-0.14, -0.85, 0), Vector3.new(0.14, -0.85, 0), scarfCyan, scarfLight, lowFX)
            table.insert(data.ScarfTails, { Part = tail, Side = side })
        end
    end

    -- 6. Kính Cyborg (Cyborg Tactical Visor)
    if wantVisor then
        local lens = makePart(folder, 'CyborgVisorLens', Vector3.new(1.06, 0.24, 0.24), helmTheme.Accent, Enum.PartType.Block, 0.12, 'Part', Enum.Material.Neon, 0)
        local brow = makePart(folder, 'CyborgVisorFrame', Vector3.new(1.12, 0.08, 0.28), Color3.fromRGB(42, 48, 64), Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.10)
        table.insert(data.HeadParts, { Part = lens, Offset = CFrame.new(0, 0.14, -0.54) })
        table.insert(data.HeadParts, { Part = brow, Offset = CFrame.new(0, 0.27, -0.55) })
    end

    -- 7. Sừng Noxar (Noxar Abyssal Horns)
    if wantHorns or (wantHelm and helmTheme.Kind == 'noxar') then
        local obsidian = Color3.fromRGB(34, 24, 52)
        local violetTip = Color3.fromRGB(168, 85, 247)
        for _, side in ipairs({ -1, 1 }) do
            local hBase = makePart(folder, 'NoxarHornBase_' .. side, Vector3.new(0.22, 0.72, 0.26), obsidian, Enum.PartType.Block, 0, 'WedgePart', Enum.Material.SmoothPlastic, 0.04)
            local hTip = makePart(folder, 'NoxarHornTip_' .. side, Vector3.new(0.16, 0.78, 0.20), violetTip, Enum.PartType.Block, 0.04, 'WedgePart', Enum.Material.Neon, 0)
            local bOff = CFrame.new(side * 0.56, 0.62, -0.10) * CFrame.Angles(-0.26, 0, -side * 0.44)
            table.insert(data.HeadParts, { Part = hBase, Offset = bOff })
            table.insert(data.HeadParts, { Part = hTip, Offset = bOff * CFrame.new(0, 0.64, -0.12) * CFrame.Angles(0.36, 0, side * 0.18) })
        end
    end

    -- 8. Khiên Leviathan / Crest Shield (Mounted on Left Forearm)
    if wantShield then
        local rim = makePart(folder, 'LeviathanShieldRim', Vector3.new(0.18, 2.05, 1.65), gold, Enum.PartType.Block, 0, 'Part', Enum.Material.Metal, 0.10)
        local core = makePart(folder, 'LeviathanShieldCore', Vector3.new(0.22, 1.72, 1.34), Color3.fromRGB(34, 118, 212), Enum.PartType.Block, 0, 'Part', Enum.Material.SmoothPlastic, 0.06)
        table.insert(data.ShieldParts, { Rim = rim, Core = core })
    end

    -- 9. Pass 13 7-Slot Modular 3D Armor Upgrades & 3D Boss Relics (Sheet 27 & Sheet 28)
    Expansion3D.BuildModularArmorSet3D(folder, data, helmTheme, chestTheme, gauntTheme, greaveTheme, {
        WantHelm = wantHelm,
        WantChest = wantChest,
        WantGauntlets = wantGauntlets,
        WantGreaves = wantGreaves,
        RelicToken = wantRelic and (relicToken ~= '' and relicToken or keyLower) or '',
    }, lowFX)

    s.AccessoryFX = data
end

function M.StepCharacterAccessories(s, now, capeWind)
    if not s or not s.Visual or not s.Visual.Parent or not s.Root or not s.Root.Parent then
        return
    end
    local key = readAccessoryKey(s.Character, s.Owner)
    if key ~= (s.AccessoryKey or '') then
        M.BuildCharacterAccessories(s, key)
    end
    local fx = s.AccessoryFX
    if not fx or not fx.Folder or not fx.Folder.Parent then
        return
    end

    local isBeast = (s.TransformFX and s.TransformFX.V5Model and s.TransformFX.V5Model.Parent ~= nil)
    if isBeast then
        if not fx.HiddenForBeast then
            fx.HiddenForBeast = true
            for _, d in ipairs(fx.Folder:GetDescendants()) do
                if d:IsA('BasePart') then
                    d.LocalTransparencyModifier = 1
                elseif d:IsA('Trail') then
                    d.Enabled = false
                end
            end
        end
        return
    elseif fx.HiddenForBeast then
        fx.HiddenForBeast = false
        local low = isLowFX(s.Owner)
        for _, d in ipairs(fx.Folder:GetDescendants()) do
            if d:IsA('BasePart') then
                d.LocalTransparencyModifier = 0
            elseif d:IsA('Trail') then
                d.Enabled = not low
            end
        end
    end

    computeBindBasis(s)
    local scaleRatio = (s.CurrentScale or 2.6) / 2.6
    local wind = math.clamp(tonumber(capeWind) or 0, 0, 1.4)
    local torsoCF = getBoneWorldCF(s, s._EquipTorso, CFrame.new(0, 0.85, 0)) * (s._TorsoModelBasis or CFrame.identity)
    local headCF = getBoneWorldCF(s, s._EquipHead, CFrame.new(0, 2.25, 0)) * (s._HeadModelBasis or CFrame.identity)
    local lArmRaw = getBoneWorldCF(s, s._EquipLHand, CFrame.new(-1.25, 0.35, -0.35))
    local rArmRaw = getBoneWorldCF(s, s._EquipRHand, CFrame.new(1.25, 0.35, -0.35))
    local lArmCF = lArmRaw * (s._LHandModelBasis or CFrame.identity)
    local rArmCF = rArmRaw * (s._RHandModelBasis or CFrame.identity)
    local lLegCF = getBoneWorldCF(s, s._EquipLLeg, CFrame.new(-0.56, -1.55, 0)) * (s._LLegModelBasis or CFrame.identity)
    local rLegCF = getBoneWorldCF(s, s._EquipRLeg, CFrame.new(0.56, -1.55, 0)) * (s._RLegModelBasis or CFrame.identity)

    for _, item in ipairs(fx.TorsoParts) do
        local off = item.Offset
        item.Part.CFrame = torsoCF * CFrame.new(off.Position * scaleRatio) * off.Rotation
    end

    for _, item in ipairs(fx.HeadParts) do
        local off = item.Offset
        item.Part.CFrame = headCF * CFrame.new(off.Position * scaleRatio) * off.Rotation
    end

    if fx.HaloParts then
        for _, item in ipairs(fx.HaloParts) do
            local off = item.BaseOffset
            local bob = math.sin(now * 2.6 + (item.Phase or 0)) * 0.08 * scaleRatio
            if item.SpinAxis == 'Y' then
                item.Part.CFrame = headCF * CFrame.Angles(0, now * 1.4, 0) * CFrame.new(off.Position * scaleRatio + Vector3.new(0, bob, 0)) * off.Rotation
            else
                item.Part.CFrame = headCF * CFrame.new(off.Position * scaleRatio + Vector3.new(0, bob, 0)) * off.Rotation
            end
        end
    end

    if fx.ArmParts then
        for _, item in ipairs(fx.ArmParts) do
            local baseCF = item.Side < 0 and lArmCF or rArmCF
            local off = item.Offset
            item.Part.CFrame = baseCF * CFrame.new(off.Position * scaleRatio) * off.Rotation
        end
    end

    if fx.LegParts then
        for _, item in ipairs(fx.LegParts) do
            local baseCF = item.Side < 0 and lLegCF or rLegCF
            local off = item.Offset
            item.Part.CFrame = baseCF * CFrame.new(off.Position * scaleRatio) * off.Rotation
        end
    end

    -- Articulated 3-segment cloak chain billowing backwards with capeWind
    if #fx.CloakPanels > 0 then
        local anchorCF = torsoCF * CFrame.new(0, 0.84 * scaleRatio, 0.56 * scaleRatio)
        local basePitch = 0.16 + wind * 0.42
        for _, panel in ipairs(fx.CloakPanels) do
            local idx = panel.Index
            local flutter = math.sin(now * (3.2 + wind * 3.5) - idx * 0.75) * (0.04 + wind * 0.09)
            local segAngle = (idx == 1 and basePitch or (0.10 + wind * 0.18)) + flutter
            local h = panel.Height * scaleRatio
            anchorCF = anchorCF * CFrame.Angles(segAngle, 0, math.sin(now * 2.4 + idx) * 0.025 * (1 + wind))
            local centerCF = anchorCF * CFrame.new(0, -h * 0.5, 0)
            panel.Part.CFrame = centerCF
            if panel.Trim then
                panel.Trim.CFrame = centerCF * CFrame.new(0, -h * 0.45, 0)
            end
            anchorCF = anchorCF * CFrame.new(0, -h * 0.94, 0)
        end
    end

    for _, st in ipairs(fx.ScarfTails) do
        local flutter = math.sin(now * (4.2 + wind * 3.8) + st.Side * 0.9) * (0.10 + wind * 0.16)
        local pitch = 0.32 + wind * 0.62 + flutter
        local base = torsoCF * CFrame.new(st.Side * 0.44 * scaleRatio, 0.88 * scaleRatio, 0.50 * scaleRatio)
            * CFrame.Angles(pitch, st.Side * (0.14 + flutter * 0.4), -st.Side * 0.10)
        st.Part.CFrame = base * CFrame.new(0, -0.88 * scaleRatio, 0)
    end

    for _, sh in ipairs(fx.ShieldParts) do
        local shCF = lArmRaw * CFrame.new(-0.32 * scaleRatio, 0.15 * scaleRatio, 0)
        sh.Rim.CFrame = shCF
        sh.Core.CFrame = shCF * CFrame.new(-0.04 * scaleRatio, 0, 0)
    end

    Expansion3D.StepModularArmorSet3D(fx, torsoCF, scaleRatio, now)
end

-- ============================================================================
-- 4. HEAD TARGET LOOK-AT (#84) & SKY GEPPO / SUPERHERO HEAVY LANDING VFX (#81,#85)
-- ============================================================================
local function resolveCombatLookTarget(s, now)
    local ch = s.Character
    local plr = s.Owner
    if ch then
        local attrPos = ch:GetAttribute('LockTargetPos')
        if typeof(attrPos) == 'Vector3' then
            return attrPos
        end
    end
    -- Zero-modification bridge to ClientBootstrap's TargetLockReticle for LocalPlayer
    if plr == localPlayer then
        local temp = workspace:FindFirstChild('TempFX')
        local ret = temp and temp:FindFirstChild('TargetLockReticle')
        local ring = ret and ret:FindFirstChild('Ring')
        if ring and ring:IsA('BasePart') then
            return ring.Position + Vector3.new(0, 3.2, 0)
        end
    end
    if now >= (s._NextLookScanAt or 0) and s.Root and s.Root.Parent then
        s._NextLookScanAt = now + 0.18
        s._NearestLookPos = nil
        local bestDist = 85
        local rPos = s.Root.Position
        local rLook = s.Root.CFrame.LookVector
        for _, folderName in ipairs({ 'ActiveBosses', 'ActiveEnemies' }) do
            local f = workspace:FindFirstChild(folderName)
            if f then
                for _, m in ipairs(f:GetChildren()) do
                    local hp = tonumber(m:GetAttribute('HP'))
                    if hp == nil or hp > 0 then
                        local body = m:FindFirstChild('Body') or m.PrimaryPart
                        if body and body:IsA('BasePart') then
                            local delta = body.Position - rPos
                            local dist = delta.Magnitude
                            if dist > 2.5 and dist < bestDist and rLook:Dot(delta.Unit) > 0.22 then
                                bestDist = dist
                                s._NearestLookPos = body.Position + Vector3.new(0, 1.4, 0)
                            end
                        end
                    end
                end
            end
        end
    end
    return s._NearestLookPos
end

function M.ApplyHeadTargetLookAt(s, dt, now)
    if not s or not s.Visual or not s.Visual.Parent or not s.Root or not s.Root.Parent then
        return
    end
    computeBindBasis(s)
    local head = s._EquipHead
    if not head or not head.Parent then
        return
    end

    local targetPos = resolveCombatLookTarget(s, now)
    local goalYaw, goalPitch = 0, 0
    if targetPos then
        local headOrigin = s.Root.Position + Vector3.new(0, 2.3, 0)
        local rel = s.Root.CFrame:PointToObjectSpace(targetPos - headOrigin + s.Root.Position)
        local distXZ = math.sqrt(rel.X * rel.X + rel.Z * rel.Z)
        if distXZ > 1.0 and (rel.Magnitude <= 85) then
            -- In Roblox CFrame space, forward is -Z and right is +X
            local rawYaw = math.atan2(-rel.X, -rel.Z)
            local rawPitch = math.atan2(rel.Y, distXZ)
            if math.abs(rawYaw) <= math.rad(95) then
                goalYaw = math.clamp(rawYaw, -math.rad(42), math.rad(42))
                goalPitch = math.clamp(rawPitch, -math.rad(25), math.rad(25))
            end
        end
    end

    local alpha = math.min(1, (dt or (1 / 60)) * 10)
    s.HeadLookYaw = (s.HeadLookYaw or 0) + (goalYaw - (s.HeadLookYaw or 0)) * alpha
    s.HeadLookPitch = (s.HeadLookPitch or 0) + (goalPitch - (s.HeadLookPitch or 0)) * alpha

    if math.abs(s.HeadLookYaw) > 0.004 or math.abs(s.HeadLookPitch) > 0.004 then
        if head:IsA('Bone') then
            local basis = s._HeadModelBasis or CFrame.identity
            local lookRotModel = CFrame.fromEulerAnglesYXZ(s.HeadLookPitch, s.HeadLookYaw, 0)
            local localLookDelta = basis * lookRotModel * basis:Inverse()
            head.Transform = head.Transform * localLookDelta
        elseif head:IsA('BasePart') then
            local neck = head:FindFirstChild('Neck')
            if neck and neck:IsA('Motor6D') then
                neck.Transform = CFrame.fromEulerAnglesYXZ(s.HeadLookPitch * 0.65, s.HeadLookYaw * 0.75, 0)
            end
        end
    end
end

local function resolveCharacterElementColor(s)
    local ch = s and s.Character
    local plr = s and s.Owner
    if (ch and ch:GetAttribute('HakiAura') == true) or (plr and plr:GetAttribute('HakiAura') == true) then
        local rgb = (ch and ch:GetAttribute('HakiColorRGB')) or (plr and plr:GetAttribute('HakiColorRGB'))
        local primary = typeof(rgb) == 'Color3' and rgb or Color3.fromRGB(245, 48, 98)
        return primary, primary:Lerp(Color3.fromRGB(24, 14, 28), 0.72)
    end
    local tf = tostring((ch and ch:GetAttribute('FruitTransform')) or '')
    if tf == 'SolarTitan' then
        return Color3.fromRGB(255, 218, 86), Color3.fromRGB(255, 248, 195)
    elseif tf:find('Abyssal') then
        return Color3.fromRGB(176, 56, 255), Color3.fromRGB(255, 68, 148)
    end
    local sword = string.lower(tostring((ch and ch:GetAttribute('EquippedSword')) or (plr and plr:GetAttribute('EquippedSword')) or ''))
    if sword:find('cryo') or sword:find('frost') then
        return Color3.fromRGB(92, 236, 255), Color3.fromRGB(224, 252, 255)
    elseif sword:find('cursed') or sword:find('noxar') or sword:find('yamo') or sword:find('architect') or sword:find('abyss') or sword:find('stormfang') then
        return Color3.fromRGB(186, 66, 255), Color3.fromRGB(255, 68, 128)
    elseif sword:find('dawn') or sword:find('aureon') then
        return Color3.fromRGB(255, 218, 96), Color3.fromRGB(255, 246, 210)
    end
    return Color3.fromRGB(112, 232, 255), Color3.fromRGB(238, 250, 255)
end

function M.SpawnGeppoShockwave(s, jumpIdx)
    if not s or not s.Root or not s.Root.Parent then
        return
    end
    local lowFX = isLowFX(s.Owner)
    local temp = ensureTempFolder()
    local c1, c2 = resolveCharacterElementColor(s)
    local footPos = s.Root.Position - Vector3.new(0, (s.H and s.H.HipHeight or 2.2) + 0.45, 0)

    local ring = makePart(temp, 'SkyGeppoRing', Vector3.new(0.14, 2.2, 2.2), c1, Enum.PartType.Cylinder, 0.22, 'Part', Enum.Material.SmoothPlastic, 0.05)
    ring.CFrame = CFrame.new(footPos) * CFrame.Angles(0, 0, math.pi * 0.5)
    local targetDiam = (jumpIdx and jumpIdx % 3 == 0) and 10.6 or 8.4
    TweenService:Create(ring, TweenInfo.new(0.34, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(0.05, targetDiam, targetDiam),
        Transparency = 1,
    }):Play()
    Debris:AddItem(ring, 0.36)

    local innerDisc = makePart(temp, 'SkyGeppoDisc', Vector3.new(0.10, 1.4, 1.4), c2, Enum.PartType.Cylinder, 0.35, 'Part', Enum.Material.SmoothPlastic, 0)
    innerDisc.CFrame = ring.CFrame
    TweenService:Create(innerDisc, TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(0.04, targetDiam * 0.65, targetDiam * 0.65),
        Transparency = 1,
    }):Play()
    Debris:AddItem(innerDisc, 0.28)

    local puffCount = lowFX and 3 or 6
    for i = 1, puffCount do
        local ang = (i - 1) * (2 * math.pi / puffCount)
        local dir = Vector3.new(math.cos(ang), 0, math.sin(ang))
        local puff = makePart(temp, 'GeppoCloudPuff_' .. i, Vector3.new(0.85, 0.55, 0.85), Color3.fromRGB(238, 246, 255), Enum.PartType.Ball, 0.32, 'Part', Enum.Material.SmoothPlastic, 0)
        puff.Position = footPos + dir * 0.9
        TweenService:Create(puff, TweenInfo.new(0.36, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = footPos + dir * (targetDiam * 0.48) + Vector3.new(0, -0.35, 0),
            Size = Vector3.new(1.55, 0.28, 1.55),
            Transparency = 1,
        }):Play()
        Debris:AddItem(puff, 0.38)
    end
end

function M.SpawnSuperheroHeavyLanding(s, fallDist)
    if not s or not s.Root or not s.Root.Parent then
        return
    end
    local ch = s.Character
    if ch then
        ch:SetAttribute('HeavyLandAt', os.clock())
        ch:SetAttribute('LastHeavyLandFallDist', math.floor(fallDist or 45))
    end
    local lowFX = isLowFX(s.Owner)
    local temp = ensureTempFolder()
    local c1, c2 = resolveCharacterElementColor(s)
    local rawFootY = s.Root.Position.Y - (s.H and s.H.HipHeight or 2.2) - s.Root.Size.Y * 0.5
    local floorY = raycastSolidFloor(s.Root.Position, rawFootY)
    local impactPos = Vector3.new(s.Root.Position.X, floorY + 0.50, s.Root.Position.Z)
    local intensity = math.clamp((fallDist or 50) / 65, 1.0, 1.65)

    local shock = makePart(temp, 'SuperheroLandingShockwave', Vector3.new(0.22, 3.0, 3.0), c1, Enum.PartType.Cylinder, 0.18, 'Part', Enum.Material.SmoothPlastic, 0.06)
    shock.CFrame = CFrame.new(impactPos) * CFrame.Angles(0, 0, math.pi * 0.5)
    TweenService:Create(shock, TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = Vector3.new(0.06, 15.5 * intensity, 15.5 * intensity),
        Transparency = 1,
    }):Play()
    Debris:AddItem(shock, 0.45)

    local crater = makePart(temp, 'SuperheroLandingCraterRing', Vector3.new(0.16, 2.2, 2.2), c2, Enum.PartType.Cylinder, 0.28, 'Part', Enum.Material.Slate, 0)
    crater.CFrame = shock.CFrame
    TweenService:Create(crater, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(0.08, 9.2 * intensity, 9.2 * intensity),
        Transparency = 1,
    }):Play()
    Debris:AddItem(crater, 0.58)

    local chunkCount = lowFX and 4 or 8
    for i = 1, chunkCount do
        local ang = (i - 1) * (2 * math.pi / chunkCount) + 0.2
        local dir = Vector3.new(math.cos(ang), 0, math.sin(ang))
        local stone = makePart(
            temp,
            'LandingDebris_' .. i,
            Vector3.new(0.65, 0.42, 0.85),
            i % 2 == 0 and Color3.fromRGB(128, 134, 148) or Color3.fromRGB(168, 174, 186),
            Enum.PartType.Block,
            0.05,
            'Part',
            Enum.Material.Slate,
            0
        )
        stone.CFrame = CFrame.lookAt(impactPos + dir * 1.4, impactPos) * CFrame.Angles(math.rad(28), 0, math.rad(i * 19))
        TweenService:Create(stone, TweenInfo.new(0.46, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            CFrame = CFrame.lookAt(impactPos + dir * (5.8 * intensity) + Vector3.new(0, 0.55, 0), impactPos)
                * CFrame.Angles(math.rad(68), 0, math.rad(i * 37)),
            Size = Vector3.new(0.25, 0.18, 0.35),
            Transparency = 1,
        }):Play()
        Debris:AddItem(stone, 0.48)
    end
end

-- ============================================================================
-- 5. STATEUPDATE & ZERO-LATENCY [1]-[4] SLOT INPUT BRIDGE (#40 & #55)
-- ============================================================================
local localSlotPredictUntil = 0

local function canTriggerHotkeySlot()
    if UserInputService:GetFocusedTextBox() then
        return false
    end
    local p = localPlayer
    local pgui = p and p:FindFirstChildOfClass('PlayerGui')
    local skyUI = pgui and pgui:FindFirstChild('SkybreakUI')
    if skyUI then
        local curScreen = tostring(skyUI:GetAttribute('CurrentScreen') or 'HUD')
        if curScreen ~= '' and curScreen ~= 'HUD' then
            return false
        end
    end
    return true
end

function M.BindEquipmentSync()
    if M._SyncBound then
        return
    end
    M._SyncBound = true

    -- 0ms client-side prediction when pressing [1], [2], [3], [4]
    -- (Note: ClientBootstrap binds ContextActionService on 1-3, so gameProcessedEvent is true for 1-3!)
    local slotByKey = {
        [Enum.KeyCode.One] = 1,
        [Enum.KeyCode.Two] = 2,
        [Enum.KeyCode.Three] = 3,
        [Enum.KeyCode.Four] = 4,
    }
    UserInputService.InputBegan:Connect(function(input)
        local slot = slotByKey[input.KeyCode]
        if slot and canTriggerHotkeySlot() then
            localSlotPredictUntil = os.clock() + 0.38
            if localPlayer then
                localPlayer:SetAttribute('ActiveSlot', slot)
                if localPlayer.Character then
                    localPlayer.Character:SetAttribute('ActiveSlot', slot)
                end
            end
        end
    end)

    local remotes = ReplicatedStorage:WaitForChild('Remotes', 10)
    local stateUpdate = remotes and remotes:FindFirstChild('StateUpdate')
    if stateUpdate and stateUpdate:IsA('RemoteEvent') then
        stateUpdate.OnClientEvent:Connect(function(payload)
            local st = payload and payload.State
            if type(st) ~= 'table' or not localPlayer then
                return
            end
            local ch = localPlayer.Character
            local now = os.clock()

            if st.ActiveSlot ~= nil and now >= localSlotPredictUntil then
                local slot = math.clamp(tonumber(st.ActiveSlot) or 3, 1, 4)
                if localPlayer:GetAttribute('ActiveSlot') ~= slot then
                    localPlayer:SetAttribute('ActiveSlot', slot)
                end
                if ch and ch:GetAttribute('ActiveSlot') ~= slot then
                    ch:SetAttribute('ActiveSlot', slot)
                end
            end

            local eq = type(st.Equipped) == 'table' and st.Equipped or {}
            local sword = tostring(st.Weapon or eq.Weapon or st.EquippedSword or '')
            if localPlayer:GetAttribute('EquippedSword') ~= sword then
                localPlayer:SetAttribute('EquippedSword', sword)
            end
            if ch and ch:GetAttribute('EquippedSword') ~= sword then
                ch:SetAttribute('EquippedSword', sword)
            end

            if st.WeaponEnhance ~= nil then
                local wEnh = math.clamp(tonumber(st.WeaponEnhance) or 0, 0, 15)
                if localPlayer:GetAttribute('WeaponEnhance') ~= wEnh then
                    localPlayer:SetAttribute('WeaponEnhance', wEnh)
                end
                if ch and ch:GetAttribute('WeaponEnhance') ~= wEnh then
                    ch:SetAttribute('WeaponEnhance', wEnh)
                end
            end

            if st.EquippedGun ~= nil then
                local gun = tostring(st.EquippedGun or '')
                if localPlayer:GetAttribute('EquippedGun') ~= gun then
                    localPlayer:SetAttribute('EquippedGun', gun)
                end
                if ch and ch:GetAttribute('EquippedGun') ~= gun then
                    ch:SetAttribute('EquippedGun', gun)
                end
            end

            if st.HeldFruit ~= nil then
                local hf = tostring(st.HeldFruit or '')
                local previewUntil = tonumber(localPlayer:GetAttribute('ShowcaseFruitUntil')) or 0
                if hf ~= '' or now >= previewUntil then
                    if localPlayer:GetAttribute('HeldFruit') ~= hf then
                        localPlayer:SetAttribute('HeldFruit', hf)
                    end
                    if ch and ch:GetAttribute('HeldFruit') ~= hf then
                        ch:SetAttribute('HeldFruit', hf)
                    end
                end
            end

            local mapAttrs = {
                EquippedChest = tostring(eq.Chest or eq.Armor or ''),
                EquippedHelmet = tostring(eq.Helmet or eq.Helm or ''),
                EquippedHelm = tostring(eq.Helm or eq.Helmet or ''),
                EquippedGauntlets = tostring(eq.Gauntlets or eq.Gloves or ''),
                EquippedGreaves = tostring(eq.Greaves or eq.Boots or ''),
                EquippedRing = tostring(eq.Ring or ''),
                EquippedNecklace = tostring(eq.Necklace or eq.Offhand or ''),
                EquippedArtifact = tostring(eq.Artifact or eq.Offhand or ''),
                EquippedAccessory = tostring(eq.Accessory or st.EquippedAccessory or ''),
                EquippedArmor = tostring(eq.Armor or st.EquippedArmor or ''),
            }
            for attrName, val in pairs(mapAttrs) do
                if localPlayer:GetAttribute(attrName) ~= val then
                    localPlayer:SetAttribute(attrName, val)
                end
                if ch and ch:GetAttribute(attrName) ~= val then
                    ch:SetAttribute(attrName, val)
                end
            end
        end)
    end

    -- Also mirror SkybreakShared.Remotes.UIStateUpdated so Inventory/NPCShop equips reflect in 0ms
    task.spawn(function()
        local skyShared = ReplicatedStorage:WaitForChild('SkybreakShared', 10)
        local skyRemotes = skyShared and skyShared:FindFirstChild('Remotes')
        local uiUpdated = skyRemotes and skyRemotes:FindFirstChild('UIStateUpdated')
        if uiUpdated and uiUpdated:IsA('RemoteEvent') then
            uiUpdated.OnClientEvent:Connect(function(uiState)
                local eq = type(uiState) == 'table' and type(uiState.Equipped) == 'table' and uiState.Equipped or nil
                if not eq or not localPlayer then
                    return
                end
                local ch = localPlayer.Character
                local mapAttrs = {
                    EquippedChest = tostring(eq.Chest or eq.Armor or ''),
                    EquippedHelmet = tostring(eq.Helm or eq.Helmet or ''),
                    EquippedHelm = tostring(eq.Helm or eq.Helmet or ''),
                    EquippedGauntlets = tostring(eq.Gauntlets or eq.Gloves or ''),
                    EquippedGreaves = tostring(eq.Greaves or eq.Boots or ''),
                    EquippedRing = tostring(eq.Ring or ''),
                    EquippedNecklace = tostring(eq.Offhand or eq.Necklace or ''),
                    EquippedArtifact = tostring(eq.Artifact or ''),
                }
                for attrName, val in pairs(mapAttrs) do
                    if localPlayer:GetAttribute(attrName) ~= val then
                        localPlayer:SetAttribute(attrName, val)
                    end
                    if ch and ch:GetAttribute(attrName) ~= val then
                        ch:SetAttribute(attrName, val)
                    end
                end
            end)
        end
    end)
end

-- ============================================================================
-- 6. WORLD PROPS: AETHER TREES & WILD FRUITS (#4,#50), RAID CONSOLE & SHRINES (#5),
--    KAEL WORKSTATION FORGE FX, PORTALS & 4 AETHER JUMP STREAMS (#24,#64)
-- ============================================================================
local WILD_FRUIT_POOL = {
    { Id = 'SolarFlameCore', Asset = 'Fruit_SolarFlameCore', Name = 'Trái Hỏa Dương', Rarity = 'RARE', Color = Color3.fromRGB(255, 132, 52) },
    { Id = 'GlacierIceCore', Asset = 'Fruit_GlacierIceCore', Name = 'Trái Băng Hà Vĩnh Cửu', Rarity = 'RARE', Color = Color3.fromRGB(108, 236, 255) },
    { Id = 'CelestialLightCore', Asset = 'Fruit_CelestialLightCore', Name = 'Trái Thánh Quang', Rarity = 'LEGENDARY', Color = Color3.fromRGB(255, 236, 112) },
    { Id = 'ThunderRumbleCore', Asset = 'Fruit_ThunderRumbleCore', Name = 'Trái Lôi Thần', Rarity = 'LEGENDARY', Color = Color3.fromRGB(84, 208, 255) },
    { Id = 'DimensionalPortalCore', Asset = 'Fruit_DimensionalPortalCore', Name = 'Trái Không Gian', Rarity = 'LEGENDARY', Color = Color3.fromRGB(76, 238, 255) },
    { Id = 'SolarTitanCore', Asset = 'Fruit_SolarTitanCore', Name = 'Trái Kim Thân Phật Tổ', Rarity = 'MYTHICAL', Color = Color3.fromRGB(255, 214, 74) },
    { Id = 'AetherflowCore', Asset = 'Fruit_AetherflowCore', Name = 'Trái Linh Mạch Aether', Rarity = 'MYTHICAL', Color = Color3.fromRGB(236, 118, 252) },
    { Id = 'AbyssalSovereignCore', Asset = 'Fruit_AbyssalSovereignCore', Name = 'Trái Long Vương Hư Không', Rarity = 'MYTHICAL', Color = Color3.fromRGB(194, 82, 255) },
}

local AETHER_TREE_SPECS = {
    {
        Key = 'Sea1_SolarTree',
        Asset = 'Tree_SolarAether',
        Sea = 1,
        Pos = Vector3.new(105.0, 46.5, 58.0),
        PedestalOffset = Vector3.new(5.2, 0, 3.4),
        Color = Color3.fromRGB(255, 212, 86),
        CanopyFruits = {
            { Asset = 'Fruit_SolarFlameCore', Offset = Vector3.new(-3.8, 12.2, 1.8) },
            { Asset = 'Fruit_CelestialLightCore', Offset = Vector3.new(3.6, 13.0, -1.6) },
            { Asset = 'Fruit_SolarTitanCore', Offset = Vector3.new(0.4, 14.1, 3.4) },
        },
    },
    {
        Key = 'Sea2_CryoTree',
        Asset = 'Tree_CryoAether',
        Sea = 2,
        Pos = Vector3.new(12095.0, 46.9, 65.0),
        PedestalOffset = Vector3.new(-4.8, 0, 3.6),
        Color = Color3.fromRGB(92, 236, 255),
        CanopyFruits = {
            { Asset = 'Fruit_GlacierIceCore', Offset = Vector3.new(-3.6, 11.8, 1.6) },
            { Asset = 'Fruit_ThunderRumbleCore', Offset = Vector3.new(3.5, 12.6, -1.5) },
            { Asset = 'Fruit_DimensionalPortalCore', Offset = Vector3.new(0.2, 13.6, 3.2) },
        },
    },
    {
        Key = 'Sea3_VoidTree',
        Asset = 'Tree_VoidAether',
        Sea = 3,
        Pos = Vector3.new(-11892.0, 46.9, 165.0),
        PedestalOffset = Vector3.new(4.8, 0, -3.6),
        Color = Color3.fromRGB(186, 76, 255),
        CanopyFruits = {
            { Asset = 'Fruit_AbyssalSovereignCore', Offset = Vector3.new(-3.6, 12.0, 1.6) },
            { Asset = 'Fruit_AstralGravityCore', Offset = Vector3.new(3.4, 12.8, -1.8) },
            { Asset = 'Fruit_AetherflowCore', Offset = Vector3.new(0.3, 13.8, 3.1) },
        },
    },
}

local SHRINE_SPECS = {
    {
        Key = 'Shrine_SolarAether',
        Asset = 'Shrine_SolarAether',
        Title = 'Đền Nguyên Tố Thái Dương (Solar Aether Shrine)',
        Pos = Vector3.new(340.0, 48.5, 984.0),
        Color = Color3.fromRGB(255, 214, 88),
        TargetHeight = 12.5,
    },
    {
        Key = 'Shrine_CryoAether',
        Asset = 'Shrine_CryoAether',
        Title = 'Đền Nguyên Tố Băng Hà (Cryo Aether Shrine)',
        Pos = Vector3.new(14638.0, 46.9, 1765.0),
        Color = Color3.fromRGB(88, 236, 255),
        TargetHeight = 12.5,
    },
    {
        Key = 'Shrine_VoidAether',
        Asset = 'Shrine_VoidAether',
        Title = 'Đền Nguyên Tố Hư Không (Void Aether Shrine)',
        Pos = Vector3.new(-14568.0, 46.9, -1785.0),
        Color = Color3.fromRGB(184, 72, 255),
        TargetHeight = 12.5,
    },
}

local JUMP_STREAM_SPECS = {
    {
        Name = 'SkyHub_CitadelStream',
        Pos = Vector3.new(-278.0, 46.5, 492.0),
        Dir = Vector3.new(0.38, 0, -0.92),
        UpSpeed = 96,
        HorizSpeed = 34,
        Color = Color3.fromRGB(108, 236, 255),
    },
    {
        Name = 'LumenPlaza_NorthPortalStream',
        Pos = Vector3.new(18.0, 46.5, -120.0),
        Dir = Vector3.new(0.04, 0, -0.99),
        UpSpeed = 98,
        HorizSpeed = 38,
        Color = Color3.fromRGB(255, 218, 96),
    },
    {
        Name = 'SunshardSanctuary_SkyStream',
        Pos = Vector3.new(2785.0, 46.5, -70.0),
        Dir = Vector3.new(0.25, 0, -0.97),
        UpSpeed = 104,
        HorizSpeed = 28,
        Color = Color3.fromRGB(255, 208, 84),
    },
    {
        Name = 'MicrochipRaidLab_SkyStream',
        Pos = Vector3.new(14600.0, 46.9, 1805.0),
        Dir = Vector3.new(0, 0, -1),
        UpSpeed = 94,
        HorizSpeed = 26,
        Color = Color3.fromRGB(86, 238, 255),
    },
}

local function prepareStaticWorldClone(Renderer, assetName, targetHeight, parentFolder)
    local okC, clone = pcall(function()
        if Renderer.CloneModel then
            return Renderer.CloneModel(assetName, 0, noopProgress)
        end
        local tpl = templateCache[assetName] or Renderer.Build(assetName, noopProgress)
        return tpl and tpl:Clone() or nil
    end)
    if not okC or not clone then
        return nil
    end
    local _, rawSize = clone:GetBoundingBox()
    if targetHeight and rawSize.Y > 0.2 then
        local sf = math.clamp(targetHeight / rawSize.Y, 0.35, 4.2)
        pcall(function()
            clone:ScaleTo(sf)
        end)
    end
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
    clone.Parent = parentFolder
    return clone
end

function M.AlignSeaTransitionPortal(portalModel, targetPos, portalId, actionLabel, objectLabel, color)
    local props = ensureWorldPropsFolder()
    local floorY = raycastSolidFloor(targetPos, targetPos.Y)
    local snappedGround = Vector3.new(targetPos.X, floorY, targetPos.Z)

    if portalModel and portalModel.Parent then
        pivotBottomFlush(portalModel, snappedGround, 0)
    end

    local nodeName = 'PortalVortexNode_' .. portalId
    local oldNode = props:FindFirstChild(nodeName)
    if oldNode then
        oldNode:Destroy()
    end

    local hub = Instance.new('Folder')
    hub.Name = nodeName
    hub.Parent = props

    local centerPos = snappedGround + Vector3.new(0, 4.8, 0)
    local anchor = makePart(hub, 'PortalInteractCore', Vector3.new(1.2, 1.2, 1.2), color, Enum.PartType.Ball, 1)
    anchor.Position = centerPos
    anchor:SetAttribute('InteractableId', portalId)

    local vortexOuter = makePart(hub, 'PortalVortexRing', Vector3.new(0.24, 7.6, 7.6), color, Enum.PartType.Cylinder, 0.32, 'Part', Enum.Material.SmoothPlastic, 0.08)
    vortexOuter.CFrame = CFrame.new(centerPos) * CFrame.Angles(0, math.pi * 0.5, 0)

    local vortexInner = makePart(hub, 'PortalVortexDisc', Vector3.new(0.16, 5.4, 5.4), Color3.fromRGB(235, 248, 255), Enum.PartType.Cylinder, 0.52, 'Part', Enum.Material.ForceField, 0)
    vortexInner.CFrame = vortexOuter.CFrame

    local pl = Instance.new('PointLight')
    pl.Color = color
    pl.Brightness = 1.2
    pl.Range = 14
    pl.Shadows = false
    pl.Parent = anchor

    local wpFolder = workspace:FindFirstChild('WorldPortals')
    local hasServerSeaGate = wpFolder and (
        (portalId == 'FrozenPortal' and wpFolder:FindFirstChild('WorldGate_Sea1_to_Sea2') ~= nil)
        or (portalId == 'ShadowPortal' and wpFolder:FindFirstChild('WorldGate_Sea2_to_Sea3') ~= nil)
    )
    if not hasServerSeaGate then
        createWorldPrompt(anchor, actionLabel, objectLabel, 15, function()
            local remotes = ReplicatedStorage:FindFirstChild('Remotes')
            local interact = remotes and remotes:FindFirstChild('InteractRequest')
            if interact and interact:IsA('RemoteEvent') then
                interact:FireServer({ interactableId = portalId })
            end
        end)
    end

    M._PortalVortexNodes = M._PortalVortexNodes or {}
    M._PortalVortexNodes[portalId] = {
        Folder = hub,
        TargetPos = targetPos,
        PortalModel = portalModel,
        Anchor = anchor,
        Outer = vortexOuter,
        Inner = vortexInner,
        SnappedY = floorY,
    }
end

function M.BootWorld(Renderer)
    if M._WorldBooted then
        return
    end
    M._WorldBooted = true
    M.BindEquipmentSync()

    local props = ensureWorldPropsFolder()
    local canopyFruits = {}
    local treeEntries = {}
    local shrineEntries = {}
    local jumpStreams = {}
    local wildState = {
        CycleIndex = 1,
        TreeIndex = 1,
        ActiveModel = nil,
        Pedestal = nil,
        Ring = nil,
        PromptPart = nil,
        Pos = nil,
        Spec = nil,
        RespawnAt = 0,
    }
    local kaelForgeState = nil
    local raidConsoleState = nil

    -- 1. Build 4 Aether Jump Streams (#64)
    for idx, js in ipairs(JUMP_STREAM_SPECS) do
        local fy = raycastSolidFloor(js.Pos, js.Pos.Y)
        local basePos = Vector3.new(js.Pos.X, fy, js.Pos.Z)
        local f = Instance.new('Folder')
        f.Name = 'AetherJumpStream_' .. js.Name
        f.Parent = props

        local base = makePart(f, 'StreamPedestal', Vector3.new(0.58, 6.4, 6.4), Color3.fromRGB(36, 44, 62), Enum.PartType.Cylinder, 0, 'Part', Enum.Material.Metal, 0.08)
        base.CFrame = CFrame.new(basePos + Vector3.new(0, 0.29, 0)) * CFrame.Angles(0, 0, math.pi * 0.5)

        local core = makePart(f, 'StreamCoreDisc', Vector3.new(0.64, 4.8, 4.8), js.Color, Enum.PartType.Cylinder, 0.24, 'Part', Enum.Material.SmoothPlastic, 0.06)
        core.CFrame = CFrame.new(basePos + Vector3.new(0, 0.33, 0)) * CFrame.Angles(0, 0, math.pi * 0.5)

        local pl = Instance.new('PointLight')
        pl.Color = js.Color
        pl.Brightness = 0.95
        pl.Range = 11
        pl.Shadows = false
        pl.Parent = core

        local pe = Instance.new('ParticleEmitter')
        pe.Name = 'UpdraftStreamParticles'
        pe.Color = ColorSequence.new(js.Color, Color3.fromRGB(240, 250, 255))
        pe.LightEmission = 0.65
        pe.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.36),
            NumberSequenceKeypoint.new(1, 0.05),
        })
        pe.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.28),
            NumberSequenceKeypoint.new(1, 1.0),
        })
        pe.Lifetime = NumberRange.new(0.65, 1.15)
        pe.Rate = isLowFX(localPlayer) and 6 or 16
        pe.Speed = NumberRange.new(14, 24)
        pe.EmissionDirection = Enum.NormalId.Right
        pe.SpreadAngle = Vector2.new(12, 12)
        pe.Parent = core

        local rings = {}
        for r = 1, 3 do
            local ring = makePart(
                f,
                'WindRing_' .. r,
                Vector3.new(0.14, 5.2 - r * 0.55, 5.2 - r * 0.55),
                r % 2 == 1 and js.Color or Color3.fromRGB(235, 248, 255),
                Enum.PartType.Cylinder,
                0.36,
                'Part',
                Enum.Material.SmoothPlastic,
                0
            )
            ring.CFrame = CFrame.new(basePos + Vector3.new(0, 1.2 + r * 1.65, 0)) * CFrame.Angles(0, 0, math.pi * 0.5)
            table.insert(rings, ring)
        end

        table.insert(jumpStreams, {
            Spec = js,
            BasePos = basePos,
            BasePart = base,
            CorePart = core,
            Emitter = pe,
            Rings = rings,
            Phase = idx * 1.1,
            CooldownUntil = 0,
        })
    end

    -- 2. Spawn KaelWorkstation beside NPC Kael (-282, 49.0, 506) with Forge Fire, Embers, Sparks & [E] Forge Prompt (#24)
    task.spawn(function()
        local kaelWorkPos = Vector3.new(-276.0, 46.5, 506.0)
        local fy = raycastSolidFloor(kaelWorkPos, 46.5)
        local snappedPos = Vector3.new(kaelWorkPos.X, fy, kaelWorkPos.Z)

        local f = Instance.new('Folder')
        f.Name = 'KaelForgeWorkstation3D'
        f.Parent = props

        local stationModel = prepareStaticWorldClone(Renderer, 'KaelWorkstation', 4.6, f)
        if stationModel then
            pivotBottomFlush(stationModel, snappedPos, math.rad(-25))
        end

        local hearth = makePart(f, 'ForgeHearthNode', Vector3.new(0.8, 0.8, 0.8), Color3.fromRGB(255, 136, 42), Enum.PartType.Ball, 1)
        hearth.Position = snappedPos + Vector3.new(0, 2.35, 0)

        local forgeLight = Instance.new('PointLight')
        forgeLight.Name = 'ForgeHearthLight'
        forgeLight.Color = Color3.fromRGB(255, 146, 52)
        forgeLight.Brightness = 1.25 -- Strictly <= 1.4 anti-glare budget
        forgeLight.Range = 13        -- Strictly <= 14 anti-glare budget
        forgeLight.Shadows = false
        forgeLight.Parent = hearth

        local embers = Instance.new('ParticleEmitter')
        embers.Name = 'ForgeRisingEmbers'
        embers.Color = ColorSequence.new(Color3.fromRGB(255, 196, 76), Color3.fromRGB(255, 86, 28))
        embers.LightEmission = 0.75
        embers.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.16),
            NumberSequenceKeypoint.new(0.7, 0.09),
            NumberSequenceKeypoint.new(1, 0),
        })
        embers.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.18),
            NumberSequenceKeypoint.new(1, 1.0),
        })
        embers.Lifetime = NumberRange.new(0.8, 1.45)
        embers.Rate = isLowFX(localPlayer) and 5 or 14
        embers.Speed = NumberRange.new(2.2, 4.8)
        embers.Acceleration = Vector3.new(0, 2.4, 0)
        embers.SpreadAngle = Vector2.new(28, 28)
        embers.Parent = hearth

        local sparks = Instance.new('ParticleEmitter')
        sparks.Name = 'AnvilStrikeSparks'
        sparks.Color = ColorSequence.new(Color3.fromRGB(255, 238, 145), Color3.fromRGB(255, 128, 36))
        sparks.LightEmission = 0.75
        sparks.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.14),
            NumberSequenceKeypoint.new(1, 0),
        })
        sparks.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.08),
            NumberSequenceKeypoint.new(1, 1.0),
        })
        sparks.Lifetime = NumberRange.new(0.24, 0.48)
        sparks.Rate = 0
        sparks.Speed = NumberRange.new(6, 13)
        sparks.Acceleration = Vector3.new(0, -24, 0)
        sparks.SpreadAngle = Vector2.new(75, 75)
        sparks.Parent = hearth

        createWorldPrompt(hearth, 'Rèn Vũ Khí', 'Lò Rèn Thần Khí • Kael Forge', 13, function()
            requestUIScreen('Forge')
        end)

        kaelForgeState = {
            Model = stationModel,
            Hearth = hearth,
            Light = forgeLight,
            Embers = embers,
            Sparks = sparks,
            Pos = snappedPos,
            NextSparkAt = 0,
        }
    end)

    -- 3. Spawn 3 Ancient Aether Fruit Trees + Canopy 3D Fruits + Wild Pickable Devil Fruit (#4 & #50)
    task.spawn(function()
        for idx, tSpec in ipairs(AETHER_TREE_SPECS) do
            local fy = raycastSolidFloor(tSpec.Pos, tSpec.Pos.Y)
            local treeGround = Vector3.new(tSpec.Pos.X, fy, tSpec.Pos.Z)
            local tf = Instance.new('Folder')
            tf.Name = tSpec.Key
            tf.Parent = props

            local treeModel = prepareStaticWorldClone(Renderer, tSpec.Asset, 21.5, tf)
            if treeModel then
                pivotBottomFlush(treeModel, treeGround, (idx - 1) * 1.1)
                local treeBoxCF, treeBoxSize = treeModel:GetBoundingBox()
                local canopyBaseY = treeBoxCF.Position.Y + treeBoxSize.Y * 0.12

                for fIdx, cfSpec in ipairs(tSpec.CanopyFruits) do
                    local fModel = prepareStaticWorldClone(Renderer, cfSpec.Asset, 1.55, tf)
                    if fModel then
                        local hangPos = Vector3.new(
                            treeGround.X + cfSpec.Offset.X,
                            math.max(treeGround.Y + cfSpec.Offset.Y, canopyBaseY + (fIdx - 1) * 0.7),
                            treeGround.Z + cfSpec.Offset.Z
                        )
                        fModel:PivotTo(CFrame.new(hangPos))
                        table.insert(canopyFruits, {
                            Model = fModel,
                            RelOffset = hangPos - treeGround,
                            TreeIndex = idx,
                            Phase = idx * 1.7 + fIdx * 1.3,
                        })
                    end
                    task.wait(0.03)
                end

                table.insert(treeEntries, {
                    Spec = tSpec,
                    Folder = tf,
                    Model = treeModel,
                    GroundPos = treeGround,
                    NextResnapCheck = os.clock() + 2.5,
                })
            end
            task.wait(0.05)
        end

        -- Build Wild Pickable Devil Fruit Root Pedestal
        local pedFolder = Instance.new('Folder')
        pedFolder.Name = 'WildNaturalDevilFruitSpawn'
        pedFolder.Parent = props

        local pedBase = makePart(pedFolder, 'WildRootPedestal', Vector3.new(0.66, 3.4, 3.4), Color3.fromRGB(38, 34, 52), Enum.PartType.Cylinder, 0, 'Part', Enum.Material.Slate, 0)
        local pedRing = makePart(pedFolder, 'WildRootAuraRing', Vector3.new(0.16, 4.1, 4.1), Color3.fromRGB(255, 214, 86), Enum.PartType.Cylinder, 0.32, 'Part', Enum.Material.SmoothPlastic, 0.06)
        local promptNode = makePart(pedFolder, 'WildFruitPromptNode', Vector3.new(1, 1, 1), Color3.fromRGB(255, 214, 86), Enum.PartType.Ball, 1)

        local pedLight = Instance.new('PointLight')
        pedLight.Color = Color3.fromRGB(255, 214, 86)
        pedLight.Brightness = 0.95
        pedLight.Range = 10
        pedLight.Shadows = false
        pedLight.Parent = promptNode

        wildState.Pedestal = pedBase
        wildState.Ring = pedRing
        wildState.PromptPart = promptNode
        wildState.Light = pedLight
        wildState.Folder = pedFolder

        local function spawnWildFruitCycle()
            if wildState.ActiveModel and wildState.ActiveModel.Parent then
                wildState.ActiveModel:Destroy()
            end
            wildState.ActiveModel = nil

            -- Pick tree closest to LocalPlayer's current Sea/position so wild fruit radar is immediately playable
            local chosenTreeIdx = 1
            local r = localPlayer and localPlayer.Character and localPlayer.Character:FindFirstChild('HumanoidRootPart')
            if r and #treeEntries > 0 then
                local bestD = math.huge
                for tIdx, te in ipairs(treeEntries) do
                    local d = (te.GroundPos - r.Position).Magnitude
                    if d < bestD then
                        bestD = d
                        chosenTreeIdx = tIdx
                    end
                end
            end

            local te = treeEntries[chosenTreeIdx] or treeEntries[1]
            local baseTreePos = te and te.GroundPos or AETHER_TREE_SPECS[1].Pos
            local off = (te and te.Spec.PedestalOffset) or Vector3.new(5.2, 0, 3.4)
            local rawPedPos = baseTreePos + off
            local fy = raycastSolidFloor(rawPedPos, baseTreePos.Y)
            local pedPos = Vector3.new(rawPedPos.X, fy, rawPedPos.Z)

            local fSpec = WILD_FRUIT_POOL[((wildState.CycleIndex - 1) % #WILD_FRUIT_POOL) + 1]
            wildState.CycleIndex += 1
            wildState.TreeIndex = chosenTreeIdx
            wildState.Spec = fSpec
            wildState.Pos = pedPos + Vector3.new(0, 2.65, 0)
            wildState.RespawnAt = 0

            pedBase.Transparency = 0
            pedRing.Transparency = 0.32
            pedRing.Color = fSpec.Color
            pedLight.Color = fSpec.Color
            pedLight.Enabled = true
            pedBase.CFrame = CFrame.new(pedPos + Vector3.new(0, 0.33, 0)) * CFrame.Angles(0, 0, math.pi * 0.5)
            pedRing.CFrame = CFrame.new(pedPos + Vector3.new(0, 0.70, 0)) * CFrame.Angles(0, 0, math.pi * 0.5)
            promptNode.Position = wildState.Pos

            local fModel = prepareStaticWorldClone(Renderer, fSpec.Asset, 1.85, pedFolder)
            if fModel then
                fModel:PivotTo(CFrame.new(wildState.Pos))
                wildState.ActiveModel = fModel
            end

            local oldPr = promptNode:FindFirstChildOfClass('ProximityPrompt')
            if oldPr then
                oldPr:Destroy()
            end
            createWorldPrompt(
                promptNode,
                'Nhặt Trái Ác Quỷ Tự Nhiên',
                '[' .. fSpec.Rarity .. '] ' .. fSpec.Name,
                14,
                function()
                    if not wildState.Spec or wildState.RespawnAt > 0 then
                        return
                    end
                    local picked = wildState.Spec
                    local remotes = ReplicatedStorage:FindFirstChild('Remotes')
                    local fruitAction = remotes and remotes:FindFirstChild('FruitAction')
                    if fruitAction and fruitAction:IsA('RemoteEvent') then
                        fruitAction:FireServer('ClaimWildFruit', picked.Id)
                    else
                        local interact = remotes and remotes:FindFirstChild('InteractRequest')
                        if interact and interact:IsA('RemoteEvent') then
                            interact:FireServer({ interactableId = 'FruitPedestal_' .. picked.Id })
                        end
                    end
                    if localPlayer then
                        localPlayer:SetAttribute('HeldFruit', picked.Id)
                        if localPlayer.Character then
                            localPlayer.Character:SetAttribute('HeldFruit', picked.Id)
                        end
                    end

                    -- Pickup burst VFX & temporary clear until next wild spawn cycle
                    local burst = makePart(ensureTempFolder(), 'WildFruitClaimBurst', Vector3.new(0.2, 2.2, 2.2), picked.Color, Enum.PartType.Cylinder, 0.18)
                    burst.CFrame = CFrame.new(wildState.Pos) * CFrame.Angles(0, 0, math.pi * 0.5)
                    TweenService:Create(burst, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                        Size = Vector3.new(0.06, 11.5, 11.5),
                        Transparency = 1,
                    }):Play()
                    Debris:AddItem(burst, 0.48)

                    if wildState.ActiveModel and wildState.ActiveModel.Parent then
                        wildState.ActiveModel:Destroy()
                    end
                    wildState.ActiveModel = nil
                    wildState.Pos = nil
                    wildState.RespawnAt = os.clock() + 24
                    pedLight.Enabled = false
                    pedRing.Transparency = 1
                    local pr = promptNode:FindFirstChildOfClass('ProximityPrompt')
                    if pr then
                        pr.Enabled = false
                    end
                    workspace:SetAttribute('NaturalFruitPos', nil)
                    workspace:SetAttribute('NaturalFruitName', '')
                    workspace:SetAttribute('NaturalFruitId', '')
                    workspace:SetAttribute('NaturalFruitRarity', '')
                end
            )

            workspace:SetAttribute('NaturalFruitPos', wildState.Pos)
            workspace:SetAttribute('NaturalFruitName', fSpec.Name)
            workspace:SetAttribute('NaturalFruitId', fSpec.Id)
            workspace:SetAttribute('NaturalFruitRarity', fSpec.Rarity)
        end

        wildState.SpawnFn = spawnWildFruitCycle
        spawnWildFruitCycle()
    end)

    -- 4. Spawn 3D Raid Microchip Console & 3 Elemental Shrines (#5 World)
    task.spawn(function()
        local raidPos = Vector3.new(14600.0, 46.9, 1765.0)
        local rfy = raycastSolidFloor(raidPos, 46.9)
        local raidGround = Vector3.new(raidPos.X, rfy, raidPos.Z)

        local rf = Instance.new('Folder')
        rf.Name = 'RaidMicrochipConsole3D'
        rf.Parent = props

        local consoleModel = prepareStaticWorldClone(Renderer, 'Console_RaidMicrochip', 6.8, rf)
        if consoleModel then
            pivotBottomFlush(consoleModel, raidGround, 0)
        end

        local cNode = makePart(rf, 'RaidConsoleInteractNode', Vector3.new(1, 1, 1), Color3.fromRGB(78, 236, 255), Enum.PartType.Ball, 1)
        cNode.Position = raidGround + Vector3.new(0, 3.4, 0)

        local cRing = makePart(rf, 'RaidConsoleHoloRing', Vector3.new(0.20, 7.2, 7.2), Color3.fromRGB(78, 236, 255), Enum.PartType.Cylinder, 0.42, 'Part', Enum.Material.SmoothPlastic, 0.06)
        cRing.CFrame = CFrame.new(raidGround + Vector3.new(0, 0.48, 0)) * CFrame.Angles(0, 0, math.pi * 0.5)

        local cLight = Instance.new('PointLight')
        cLight.Color = Color3.fromRGB(78, 236, 255)
        cLight.Brightness = 1.05
        cLight.Range = 12
        cLight.Shadows = false
        cLight.Parent = cNode

        createWorldPrompt(cNode, 'Bàn Điều Khiển Raid Thức Tỉnh', 'Microchip Awakening Raid Lab', 15, function()
            requestUIScreen('Raid')
        end)

        raidConsoleState = {
            Model = consoleModel,
            Node = cNode,
            Ring = cRing,
            RawPos = raidPos,
            GroundY = rfy,
        }

        for _, shSpec in ipairs(SHRINE_SPECS) do
            local sfy = raycastSolidFloor(shSpec.Pos, shSpec.Pos.Y)
            local shGround = Vector3.new(shSpec.Pos.X, sfy, shSpec.Pos.Z)
            local sf = Instance.new('Folder')
            sf.Name = shSpec.Key
            sf.Parent = props

            local shModel = prepareStaticWorldClone(Renderer, shSpec.Asset, shSpec.TargetHeight, sf)
            if shModel then
                pivotBottomFlush(shModel, shGround, 0)
            end

            local sNode = makePart(sf, 'ShrinePromptNode', Vector3.new(1, 1, 1), shSpec.Color, Enum.PartType.Ball, 1)
            sNode.Position = shGround + Vector3.new(0, 3.6, 0)

            local sLight = Instance.new('PointLight')
            sLight.Color = shSpec.Color
            sLight.Brightness = 1.0
            sLight.Range = 12
            sLight.Shadows = false
            sLight.Parent = sNode

            local motes = Instance.new('ParticleEmitter')
            motes.Name = 'ShrineElementalMotes'
            motes.Color = ColorSequence.new(shSpec.Color, Color3.fromRGB(245, 250, 255))
            motes.LightEmission = 0.65
            motes.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.22),
                NumberSequenceKeypoint.new(1, 0),
            })
            motes.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0.25),
                NumberSequenceKeypoint.new(1, 1.0),
            })
            motes.Lifetime = NumberRange.new(1.2, 2.1)
            motes.Rate = isLowFX(localPlayer) and 3 or 9
            motes.Speed = NumberRange.new(1.2, 2.8)
            motes.SpreadAngle = Vector2.new(180, 180)
            motes.Parent = sNode

            createWorldPrompt(sNode, 'Cầu Nguyện Đền Nguyên Tố', shSpec.Title, 15, function()
                local remotes = ReplicatedStorage:FindFirstChild('Remotes')
                local interact = remotes and remotes:FindFirstChild('InteractRequest')
                if interact and interact:IsA('RemoteEvent') then
                    interact:FireServer({ interactableId = 'AetherShrine' })
                end
                local bless = makePart(ensureTempFolder(), 'ShrineBlessRing', Vector3.new(0.18, 2.6, 2.6), shSpec.Color, Enum.PartType.Cylinder, 0.20)
                bless.CFrame = CFrame.new(shGround + Vector3.new(0, 0.50, 0)) * CFrame.Angles(0, 0, math.pi * 0.5)
                TweenService:Create(bless, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Size = Vector3.new(0.06, 13.5, 13.5),
                    Transparency = 1,
                }):Play()
                Debris:AddItem(bless, 0.58)
            end)

            table.insert(shrineEntries, {
                Spec = shSpec,
                Model = shModel,
                Node = sNode,
                GroundY = sfy,
            })
            task.wait(0.05)
        end
    end)

    -- 5. Unified 60-FPS World Loop: Canopy Sway, Wild Fruit Bob & Radar Wisp, Jump Streams, Forge Sparks & Late Collider Re-Snap
    local radarWisp = nil
    local nextResnapTick = 0

    RunService.RenderStepped:Connect(function()
        local now = os.clock()
        local cam = workspace.CurrentCamera
        local camPos = cam and cam.CFrame.Position or nil
        local ch = localPlayer and localPlayer.Character
        local root = ch and ch:FindFirstChild('HumanoidRootPart')
        local hum = ch and ch:FindFirstChildOfClass('Humanoid')
        local lowFX = isLowFX(localPlayer)

        -- Periodic ground re-snap once streamed GrandSkyIslands colliders finish spawning
        if now >= nextResnapTick then
            nextResnapTick = now + 2.5
            for tIdx, te in ipairs(treeEntries) do
                local ny = raycastSolidFloor(te.Spec.Pos, te.Spec.Pos.Y)
                if math.abs(ny - te.GroundPos.Y) > 0.08 then
                    te.GroundPos = Vector3.new(te.Spec.Pos.X, ny, te.Spec.Pos.Z)
                    if te.Model and te.Model.Parent then
                        pivotBottomFlush(te.Model, te.GroundPos, (tIdx - 1) * 1.1)
                    end
                end
            end
            if raidConsoleState and raidConsoleState.Model and raidConsoleState.Model.Parent then
                local ny = raycastSolidFloor(raidConsoleState.RawPos, raidConsoleState.RawPos.Y)
                if math.abs(ny - raidConsoleState.GroundY) > 0.08 then
                    raidConsoleState.GroundY = ny
                    local g = Vector3.new(raidConsoleState.RawPos.X, ny, raidConsoleState.RawPos.Z)
                    pivotBottomFlush(raidConsoleState.Model, g, 0)
                    raidConsoleState.Node.Position = g + Vector3.new(0, 3.4, 0)
                    raidConsoleState.Ring.CFrame = CFrame.new(g + Vector3.new(0, 0.48, 0)) * CFrame.Angles(0, 0, math.pi * 0.5)
                end
            end
            for _, se in ipairs(shrineEntries) do
                local ny = raycastSolidFloor(se.Spec.Pos, se.Spec.Pos.Y)
                if math.abs(ny - se.GroundY) > 0.08 then
                    se.GroundY = ny
                    local g = Vector3.new(se.Spec.Pos.X, ny, se.Spec.Pos.Z)
                    if se.Model and se.Model.Parent then
                        pivotBottomFlush(se.Model, g, 0)
                    end
                    se.Node.Position = g + Vector3.new(0, 3.6, 0)
                end
            end
            if M._PortalVortexNodes then
                for _, pn in pairs(M._PortalVortexNodes) do
                    local ny = raycastSolidFloor(pn.TargetPos, pn.TargetPos.Y)
                    if math.abs(ny - pn.SnappedY) > 0.08 then
                        pn.SnappedY = ny
                        local g = Vector3.new(pn.TargetPos.X, ny, pn.TargetPos.Z)
                        if pn.PortalModel and pn.PortalModel.Parent then
                            pivotBottomFlush(pn.PortalModel, g, 0)
                        end
                        local c = g + Vector3.new(0, 4.8, 0)
                        pn.Anchor.Position = c
                        pn.Outer.CFrame = CFrame.new(c) * CFrame.Angles(0, math.pi * 0.5, 0)
                        pn.Inner.CFrame = pn.Outer.CFrame
                    end
                end
            end
        end

        -- Canopy Fruits gentle breeze sway (culled beyond 850 studs for Gameplay3x spans)
        for i = 1, #canopyFruits do
            local cfEntry = canopyFruits[i]
            local te = treeEntries[cfEntry.TreeIndex]
            if te and cfEntry.Model and cfEntry.Model.Parent then
                local baseP = te.GroundPos + cfEntry.RelOffset
                if not camPos or (baseP - camPos).Magnitude <= 850 then
                    local sway = math.sin(now * 2.1 + cfEntry.Phase) * 0.12
                    cfEntry.Model:PivotTo(CFrame.new(baseP + Vector3.new(0, sway, 0)) * CFrame.Angles(0, now * 0.75 + cfEntry.Phase, sway * 0.5))
                end
            end
        end

        -- Wild Natural Devil Fruit bobbing, respawn cycle & 1650-stud Aether Radar Wisp (#50)
        if wildState.RespawnAt > 0 and now >= wildState.RespawnAt and wildState.SpawnFn then
            wildState.SpawnFn()
        end
        if wildState.ActiveModel and wildState.ActiveModel.Parent and wildState.Pos then
            if not camPos or (wildState.Pos - camPos).Magnitude <= 950 then
                local bob = math.sin(now * 2.8) * 0.22
                wildState.ActiveModel:PivotTo(CFrame.new(wildState.Pos + Vector3.new(0, bob, 0)) * CFrame.Angles(0, now * 1.45, math.sin(now * 2.0) * 0.08))
            end
        end

        if wildState.Pos and root and not lowFX then
            local delta = wildState.Pos - root.Position
            local dist = delta.Magnitude
            if dist >= 10 and dist <= 1650 then
                if not radarWisp or not radarWisp.Parent then
                    radarWisp = makePart(
                        ensureTempFolder(),
                        'NaturalFruitRadarWisp',
                        Vector3.new(0.32, 0.24, 0.95),
                        Color3.fromRGB(255, 218, 88),
                        Enum.PartType.Block,
                        0.22,
                        'WedgePart',
                        Enum.Material.SmoothPlastic,
                        0.08
                    )
                end
                local dir = Vector3.new(delta.X, 0, delta.Z)
                local dirUnit = dir.Magnitude > 0.1 and dir.Unit or root.CFrame.LookVector
                local pulseFreq = 3.2 + (1 - math.clamp(dist / 1650, 0, 1)) * 5.0
                local bob = math.sin(now * pulseFreq) * 0.20
                local wPos = root.Position + dirUnit * 5.0 + Vector3.new(0, 2.35 + bob, 0)
                radarWisp.Color = (wildState.Spec and wildState.Spec.Color) or Color3.fromRGB(255, 218, 88)
                local wDiff = wildState.Pos - wPos
                local wDir = wDiff.Magnitude > 1e-3 and wDiff.Unit or dirUnit
                local wUp = math.abs(wDir.Y) > 0.99 and Vector3.new(0, 0, 1) or Vector3.new(0, 1, 0)
                radarWisp.CFrame = CFrame.lookAt(wPos, wPos + wDir, wUp)
            elseif radarWisp then
                radarWisp:Destroy()
                radarWisp = nil
            end
        elseif radarWisp then
            radarWisp:Destroy()
            radarWisp = nil
        end

        -- Kael Forge rhythmic anvil sparks (#24)
        if kaelForgeState and kaelForgeState.Sparks and now >= kaelForgeState.NextSparkAt then
            kaelForgeState.NextSparkAt = now + 1.55
            if not lowFX and (not camPos or (kaelForgeState.Pos - camPos).Magnitude <= 380) then
                kaelForgeState.Sparks:Emit(9)
            end
        end

        -- Portal vortex rotation (#24)
        if M._PortalVortexNodes then
            for _, pn in pairs(M._PortalVortexNodes) do
                if pn.Outer and pn.Outer.Parent and (not camPos or (pn.Anchor.Position - camPos).Magnitude <= 1450) then
                    local pulse = 5.2 + math.sin(now * 3.2) * 0.45
                    pn.Inner.Size = Vector3.new(0.16, pulse, pulse)
                    pn.Outer.CFrame = CFrame.new(pn.Anchor.Position) * CFrame.Angles(now * 1.6, math.pi * 0.5, 0)
                end
            end
        end

        -- 4 Aether Jump Streams animation & smooth aerial arc launch (#64)
        for i = 1, #jumpStreams do
            local js = jumpStreams[i]
            local distCam = camPos and (js.BasePos - camPos).Magnitude or 0
            if distCam <= 850 then
                for rIdx, ring in ipairs(js.Rings) do
                    if ring and ring.Parent then
                        local cycle = ((now * 1.35 + (rIdx - 1) * 0.33 + js.Phase) % 1)
                        local yLift = 0.75 + cycle * 5.4
                        local dScale = 5.4 - cycle * 1.9
                        ring.Size = Vector3.new(0.12, dScale, dScale)
                        ring.Transparency = 0.25 + cycle * 0.68
                        ring.CFrame = CFrame.new(js.BasePos + Vector3.new(0, yLift, 0)) * CFrame.Angles(0, now * 3.2, math.pi * 0.5)
                    end
                end
            end
            local canLaunch = root
                and hum
                and hum.Health > 0
                and not hum.Sit
                and now >= js.CooldownUntil
                and not (ch and ch:GetAttribute('SkybreakFlightActive') == true)
                and not (localPlayer and (localPlayer:GetAttribute('SkybreakFlightActive') == true or localPlayer:GetAttribute('InTrade') == true))
            if canLaunch then
                local flat = Vector3.new(root.Position.X - js.BasePos.X, 0, root.Position.Z - js.BasePos.Z)
                local dy = root.Position.Y - js.BasePos.Y
                if flat.Magnitude <= 4.4 and dy >= -1.5 and dy <= 7.0 then
                    js.CooldownUntil = now + 1.45
                    local dUnit = js.Spec.Dir.Magnitude > 0.05 and js.Spec.Dir.Unit or Vector3.zero
                    hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    -- Horizontal speed kept <= 38 studs/s so server anti-cheat speed validator never rubberbands
                    root.AssemblyLinearVelocity = Vector3.new(
                        dUnit.X * js.Spec.HorizSpeed,
                        js.Spec.UpSpeed,
                        dUnit.Z * js.Spec.HorizSpeed
                    )
                    ch:SetAttribute('AirJumpIndex', 3)
                    ch:SetAttribute('LastAirJumpAt', now)
                end
            end
        end
    end)
end

return M
