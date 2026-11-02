-- SKYBREAK: Fragments of the Core — Live 3D Roblox Avatar Bust Portrait + 4-Tier Winged Crest & VFX
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Components/LiveAvatarPortrait.lua
-- Matches SKYBREAK_Figma_v2_05_Live_Avatar_VFX.png & SKYBREAK_Figma_v2_01_ActionRPG_HUD.png 1:1:
--   * Top-left SAFE emerald pill + Top-right LIVE 3D cyan pill
--   * 2D Progressive Winged Crest Flanges (Tier 1 Steel -> Tier 2 Gold Wings -> Tier 3 Cyan Double Wings + Sparks -> Tier 4 Sovereign Crown + Astral Wings)
--   * Rotating Astrolabe Ring Backdrop + 3D Hollow Neon Rune Rings + Cloned LocalPlayer.Character Bust (FOV 22)
--   * Overlapping Obsidian-Gold Lv. XXX pill centered at bottom.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))

local LiveAvatarPortrait = {}

local CLASS_ACCENTS = {
    SkyGuardian = Color3.fromRGB(246, 198, 82),    -- Celestial Gold
    ThunderStriker = Color3.fromRGB(56, 189, 248), -- Electric Cyan
    ArcaneMage = Color3.fromRGB(192, 132, 252),    -- Astral Violet
}

local TIER1_STEEL = Color3.fromRGB(116, 136, 168)
local SOVEREIGN_VIOLET = Color3.fromRGB(198, 126, 255)

local function isGuiChainVisible(guiObj)
    local cur = guiObj
    while cur do
        if cur:IsA("GuiObject") and not cur.Visible then
            return false
        elseif cur:IsA("LayerCollector") and not cur.Enabled then
            return false
        end
        cur = cur.Parent
    end
    return true
end

local function computeClassTier(level, hakiActive, raceV4Active)
    local lv = tonumber(level) or 1
    if raceV4Active or lv >= 1500 then
        return 4
    elseif hakiActive or lv >= 700 then
        return 3
    elseif lv >= 15 then
        return 2
    end
    return 1
end

local function readEquippedSignature(snapshot, player)
    local eq = (snapshot and snapshot.equipped) or {}
    local parts = {
        tostring(eq.Helm or ""),
        tostring(eq.Chest or ""),
        tostring(eq.Artifact or ""),
        tostring(eq.Offhand or ""),
    }
    local ch = player and player.Character
    if ch then
        local accFolder = ch:FindFirstChild("CharacterAccessories3D", true)
        if accFolder then
            table.insert(parts, tostring(accFolder:GetAttribute("AccessoryKey") or "acc3d"))
            table.insert(parts, tostring(#accFolder:GetChildren()))
        end
    end
    return table.concat(parts, "|")
end

-- Hollow 12-segment 3D Neon Rune Ring
local function buildHollowNeonRing(parent, name, radius, thickness, color, transparency)
    local ringModel = Instance.new("Model")
    ringModel.Name = name
    local pivotPart = Instance.new("Part")
    pivotPart.Name = "Pivot"
    pivotPart.Size = Vector3.new(0.05, 0.05, 0.05)
    pivotPart.Transparency = 1
    pivotPart.Anchored = true
    pivotPart.CanCollide = false
    pivotPart.CanQuery = false
    pivotPart.CanTouch = false
    pivotPart.CFrame = CFrame.identity
    pivotPart.Parent = ringModel
    ringModel.PrimaryPart = pivotPart

    local segCount = 12
    local segLen = (2 * math.pi * radius / segCount) * 0.86
    for i = 1, segCount do
        local angle = ((i - 1) / segCount) * math.pi * 2
        local seg = Instance.new("Part")
        seg.Name = "RuneSeg_" .. i
        seg.Size = Vector3.new(segLen, thickness, thickness * 0.7)
        seg.Color = (i % 3 == 0) and color:Lerp(Color3.new(1, 1, 1), 0.38) or color
        seg.Material = Enum.Material.Neon
        seg.Transparency = transparency or 0.08
        seg.Anchored = true
        seg.CanCollide = false
        seg.CanQuery = false
        seg.CanTouch = false
        seg.CastShadow = false
        local px = math.cos(angle) * radius
        local py = math.sin(angle) * radius
        seg.CFrame = CFrame.new(px, py, 0) * CFrame.Angles(0, 0, angle + math.pi * 0.5)
        seg.Parent = ringModel
    end

    ringModel.Parent = parent
    return ringModel
end

-- Lightweight 3D wearable armor accents (helm/crown/pauldrons) when equipped in snapshot
local function attachSnapshotArmorAccents(bustModel, headPart, snapshot, accentColor, tier)
    local eq = (snapshot and snapshot.equipped) or {}
    if bustModel:FindFirstChild("CharacterAccessories3D", true) then
        return
    end
    if not headPart then
        return
    end

    local headCF = headPart.CFrame
    local gold = Theme.Colors.ACCENT_GOLD_BRIGHT
    local helmId = string.lower(tostring(eq.Helm or ""))
    local chestId = string.lower(tostring(eq.Chest or ""))

    if helmId ~= "" or tier >= 2 then
        if helmId:find("visor") or helmId:find("cyber") then
            local visor = Instance.new("Part")
            visor.Name = "EquippedVisor3D"
            visor.Size = Vector3.new(1.08, 0.24, 0.26)
            visor.Color = Color3.fromRGB(56, 224, 255)
            visor.Material = Enum.Material.Neon
            visor.Transparency = 0.10
            visor.Anchored = true
            visor.CanCollide = false
            visor.CFrame = headCF * CFrame.new(0, 0.10, -0.52)
            visor.Parent = bustModel
        elseif helmId:find("horn") or helmId:find("noxar") or helmId:find("abyss") then
            for _, side in ipairs({ -1, 1 }) do
                local horn = Instance.new("WedgePart")
                horn.Name = "EquippedHorn3D_" .. side
                horn.Size = Vector3.new(0.18, 0.72, 0.24)
                horn.Color = Color3.fromRGB(184, 96, 255)
                horn.Material = Enum.Material.Neon
                horn.Anchored = true
                horn.CanCollide = false
                horn.CFrame = headCF * CFrame.new(side * 0.52, 0.58, -0.10) * CFrame.Angles(-0.22, 0, -side * 0.38)
                horn.Parent = bustModel
            end
        elseif helmId ~= "" then
            local band = Instance.new("Part")
            band.Name = "EquippedHelmCrestBand"
            band.Size = Vector3.new(1.18, 0.16, 1.18)
            band.Color = gold
            band.Material = Enum.Material.Metal
            band.Reflectance = 0.28
            band.Anchored = true
            band.CanCollide = false
            band.CFrame = headCF * CFrame.new(0, 0.46, 0)
            band.Parent = bustModel

            local crest = Instance.new("WedgePart")
            crest.Name = "EquippedHelmCrestGem"
            crest.Size = Vector3.new(0.18, 0.48, 0.24)
            crest.Color = accentColor
            crest.Material = Enum.Material.Neon
            crest.Anchored = true
            crest.CanCollide = false
            crest.CFrame = headCF * CFrame.new(0, 0.68, -0.54) * CFrame.Angles(-0.15, 0, 0)
            crest.Parent = bustModel

            for _, side in ipairs({ -1, 1 }) do
                local wing = Instance.new("WedgePart")
                wing.Name = "HelmSideWing_" .. side
                wing.Size = Vector3.new(0.10, 0.44, 0.34)
                wing.Color = gold
                wing.Material = Enum.Material.Metal
                wing.Anchored = true
                wing.CanCollide = false
                wing.CFrame = headCF * CFrame.new(side * 0.64, 0.56, -0.08) * CFrame.Angles(0.18, 0, -side * 0.28)
                wing.Parent = bustModel
            end
        end
    end

    if chestId ~= "" then
        for _, side in ipairs({ -1, 1 }) do
            local pauldron = Instance.new("Part")
            pauldron.Name = "EquippedPauldron3D_" .. side
            pauldron.Size = Vector3.new(0.70, 0.38, 0.96)
            pauldron.Color = gold
            pauldron.Material = Enum.Material.Metal
            pauldron.Reflectance = 0.30
            pauldron.Anchored = true
            pauldron.CanCollide = false
            pauldron.CFrame = headCF * CFrame.new(side * 1.16, -0.90, 0.04) * CFrame.Angles(0, 0, math.rad(-side * 15))
            pauldron.Parent = bustModel
        end
    end
end

-- Heroic R15 Bust fallback when LocalPlayer.Character is not yet spawned
local function buildR15FallbackBust(accentColor, classId)
    local m = Instance.new("Model")
    m.Name = "FallbackR15Bust"

    local suitColor = Color3.fromRGB(28, 46, 78)
    if classId == "ThunderStriker" then
        suitColor = Color3.fromRGB(22, 42, 72)
    elseif classId == "ArcaneMage" then
        suitColor = Color3.fromRGB(44, 28, 72)
    end

    local torso = Instance.new("Part")
    torso.Name = "UpperTorso"
    torso.Size = Vector3.new(1.85, 1.75, 0.96)
    torso.Color = suitColor
    torso.Material = Enum.Material.SmoothPlastic
    torso.Anchored = true
    torso.CanCollide = false
    torso.CFrame = CFrame.new(0, 0, 0)
    torso.Parent = m

    local chestEmblem = Instance.new("Part")
    chestEmblem.Name = "CoreEmblem"
    chestEmblem.Size = Vector3.new(0.46, 0.46, 0.12)
    chestEmblem.Color = accentColor
    chestEmblem.Material = Enum.Material.Neon
    chestEmblem.Anchored = true
    chestEmblem.CanCollide = false
    chestEmblem.CFrame = CFrame.new(0, 0.24, -0.46) * CFrame.Angles(0, 0, math.rad(45))
    chestEmblem.Parent = m

    for _, side in ipairs({ -1, 1 }) do
        local arm = Instance.new("Part")
        arm.Name = (side == -1 and "LeftUpperArm" or "RightUpperArm")
        arm.Size = Vector3.new(0.82, 1.45, 0.86)
        arm.Color = suitColor:Lerp(Color3.new(1, 1, 1), 0.12)
        arm.Material = Enum.Material.SmoothPlastic
        arm.Anchored = true
        arm.CanCollide = false
        arm.CFrame = CFrame.new(side * 1.32, -0.08, 0) * CFrame.Angles(0, 0, math.rad(-side * 8))
        arm.Parent = m
    end

    local collar = Instance.new("Part")
    collar.Name = "Collar"
    collar.Size = Vector3.new(1.38, 0.24, 1.02)
    collar.Color = Theme.Colors.ACCENT_GOLD_BRIGHT
    collar.Material = Enum.Material.Metal
    collar.Reflectance = 0.25
    collar.Anchored = true
    collar.CanCollide = false
    collar.CFrame = CFrame.new(0, 0.92, 0)
    collar.Parent = m

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1.18, 1.18, 1.18)
    head.Color = Color3.fromRGB(244, 214, 188)
    head.Material = Enum.Material.SmoothPlastic
    head.Anchored = true
    head.CanCollide = false
    head.CFrame = CFrame.new(0, 1.62, 0)
    head.Parent = m
    Instance.new("SpecialMesh", head).MeshType = Enum.MeshType.Head

    for _, side in ipairs({ -1, 1 }) do
        local eye = Instance.new("Part")
        eye.Name = "HeroEye_" .. side
        eye.Size = Vector3.new(0.14, 0.09, 0.08)
        eye.Color = Color3.fromRGB(22, 30, 46)
        eye.Material = Enum.Material.SmoothPlastic
        eye.Anchored = true
        eye.CanCollide = false
        eye.CFrame = head.CFrame * CFrame.new(side * 0.22, 0.06, -0.55)
        eye.Parent = m
    end

    local hair = Instance.new("Part")
    hair.Name = "HeroHair"
    hair.Size = Vector3.new(1.26, 0.56, 1.26)
    hair.Color = Color3.fromRGB(36, 46, 68)
    hair.Material = Enum.Material.SmoothPlastic
    hair.Anchored = true
    hair.CanCollide = false
    hair.CFrame = head.CFrame * CFrame.new(0, 0.44, 0.06)
    hair.Parent = m

    m.PrimaryPart = head
    return m, head
end

local function isPortraitClutterName(n)
    local low = string.lower(tostring(n or ""))
    return low:find("_weapon", 1, true) ~= nil
        or low:find("mythicalweapons", 1, true) ~= nil
        or low:find("skybornblade", 1, true) ~= nil
        or low:find("fruit_", 1, true) ~= nil
        or low:find("haki_bolt", 1, true) ~= nil
        or low:find("handhaki", 1, true) ~= nil
        or low:find("foothaki", 1, true) ~= nil
        or low:find("runering", 1, true) ~= nil
        or low:find("innercelestial", 1, true) ~= nil
        or low:find("mythicspirit", 1, true) ~= nil
        or low:find("astralshard", 1, true) ~= nil
        or low:find("sunfirehaloray", 1, true) ~= nil
        or low:find("busocoating", 1, true) ~= nil
end

local function isFaceFeatureName(n)
    local low = string.lower(tostring(n or ""))
    return low:find("sculptedface", 1, true) ~= nil
        or low:find("eyecore", 1, true) ~= nil
        or low:find("sclera", 1, true) ~= nil
        or low:find("darklash", 1, true) ~= nil
        or low:find("mouthline", 1, true) ~= nil
        or low:find("catchlight", 1, true) ~= nil
end

local function cloneLocalPlayerBust()
    local lp = Players.LocalPlayer
    local ch = lp and lp.Character
    if not ch then
        return nil, nil, false
    end

    local rawHRP = ch:FindFirstChild("HumanoidRootPart")
    local rawHead = ch:FindFirstChild("Head")
    local rawRef = (rawHRP and rawHRP:IsA("BasePart") and rawHRP)
        or (rawHead and rawHead:IsA("BasePart") and rawHead)
    if not rawRef then
        return nil, nil, false
    end

    local prevArch = ch.Archivable
    ch.Archivable = true
    local ok, cloned = pcall(function()
        return ch:Clone()
    end)
    ch.Archivable = prevArch

    if not ok or not cloned or not cloned:IsA("Model") then
        return nil, nil, false
    end
    cloned.Name = "PortraitBustClone"

    local clonedHRP = cloned:FindFirstChild("HumanoidRootPart")
    local clonedHead = cloned:FindFirstChild("Head")
    local refPart = (clonedHRP and clonedHRP:IsA("BasePart") and clonedHRP)
        or (clonedHead and clonedHead:IsA("BasePart") and clonedHead)
        or cloned.PrimaryPart
        or cloned:FindFirstChildWhichIsA("BasePart")
    if not refPart then
        cloned:Destroy()
        return nil, nil, false
    end

    local refPos = refPart.Position
    local hasVisibleSkinnedMesh = false

    for _, desc in ipairs(cloned:GetDescendants()) do
        if desc:IsA("Script")
            or desc:IsA("LocalScript")
            or desc:IsA("ModuleScript")
            or desc:IsA("ProximityPrompt")
            or desc:IsA("BillboardGui")
            or desc:IsA("ParticleEmitter")
            or desc:IsA("Trail")
            or desc:IsA("Beam")
            or desc:IsA("ForceField")
            or desc:IsA("Sound")
            or desc:IsA("Highlight")
            or ((desc:IsA("Folder") or desc:IsA("Model")) and isPortraitClutterName(desc.Name))
        then
            desc:Destroy()
        elseif desc:IsA("Humanoid") then
            desc.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            desc.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
        elseif desc:IsA("BasePart") then
            if isPortraitClutterName(desc.Name) or (desc.Position - refPos).Magnitude > 11 then
                desc:Destroy()
            else
                desc.Anchored = true
                desc.CanCollide = false
                desc.CanQuery = false
                desc.CanTouch = false
                desc.CastShadow = false
                desc.LocalTransparencyModifier = 0
                local inSubModel = (desc.Parent ~= cloned) and (desc:FindFirstAncestorOfClass("Accessory") == nil)
                if (desc:IsA("MeshPart") or inSubModel) and desc.Transparency < 0.85 and desc.Name ~= "HumanoidRootPart" then
                    hasVisibleSkinnedMesh = true
                end
            end
        end
    end

    if not hasVisibleSkinnedMesh then
        for _, desc in ipairs(cloned:GetDescendants()) do
            if desc:IsA("BasePart") then
                local n = desc.Name
                if n == "HumanoidRootPart" or n:find("LowerLeg") or n:find("Foot") or n == "Left Leg" or n == "Right Leg" then
                    desc.Transparency = 1
                elseif n == "Head" or n == "UpperTorso" or n == "Torso" or n == "LeftUpperArm" or n == "RightUpperArm" or n == "Left Arm" or n == "Right Arm" or desc:FindFirstAncestorOfClass("Accessory") then
                    if desc.Transparency > 0.9 then
                        desc.Transparency = 0
                    end
                end
            end
        end
    end

    -- Align character horizontally so the hero's front (-Z in lookAt space) faces the camera at -Z
    local refCF = refPart.CFrame
    local flatLook = Vector3.new(refCF.LookVector.X, 0, refCF.LookVector.Z)
    if flatLook.Magnitude < 0.05 then
        flatLook = Vector3.new(0, 0, -1)
    else
        flatLook = flatLook.Unit
    end
    local alignOrigin = CFrame.lookAt(refCF.Position, refCF.Position + flatLook)
    local targetOrigin = CFrame.new(0, 0, 0)

    for _, desc in ipairs(cloned:GetDescendants()) do
        if desc:IsA("BasePart") then
            local rel = alignOrigin:ToObjectSpace(desc.CFrame)
            desc.CFrame = targetOrigin:ToWorldSpace(rel)
        end
    end

    -- Detect the TRUE visible 3D Face / Eyes position (handles taller 3D hero rigs like SkyGuardianVisual + standard R15)
    local faceSum = Vector3.zero
    local faceCount = 0
    local topBodyY = -math.huge

    for _, desc in ipairs(cloned:GetDescendants()) do
        if desc:IsA("BasePart") and desc.Transparency < 0.85 and desc.Name ~= "HumanoidRootPart" then
            if isFaceFeatureName(desc.Name) then
                faceSum += desc.Position
                faceCount += 1
            end
            if math.abs(desc.Position.X) < 1.35 and math.abs(desc.Position.Z) < 1.35 then
                local partTop = desc.Position.Y + (desc.Size.Y * 0.5)
                if partTop < 4.5 and partTop > topBodyY then
                    topBodyY = partTop
                end
            end
        end
    end

    local facePos
    if faceCount > 0 then
        local avg = faceSum / faceCount
        facePos = Vector3.new(0, avg.Y + 0.02, avg.Z)
    elseif hasVisibleSkinnedMesh and topBodyY > -100 then
        facePos = Vector3.new(0, topBodyY - 0.72, -0.35)
    elseif clonedHead and clonedHead:IsA("BasePart") then
        facePos = clonedHead.Position - Vector3.new(0, 0.04, 0)
    else
        facePos = Vector3.new(0, 1.62, 0)
    end

    local faceAnchor = Instance.new("Part")
    faceAnchor.Name = "PortraitFaceAnchor"
    faceAnchor.Size = Vector3.new(0.1, 0.1, 0.1)
    faceAnchor.Transparency = 1
    faceAnchor.Anchored = true
    faceAnchor.CanCollide = false
    faceAnchor.CanQuery = false
    faceAnchor.CanTouch = false
    faceAnchor.CFrame = CFrame.new(facePos)
    faceAnchor.Parent = cloned

    return cloned, faceAnchor, hasVisibleSkinnedMesh
end

function LiveAvatarPortrait.Create(parent, props)
    props = props or {}
    local colors = Theme.Colors
    local frameSize = props.size or UDim2.fromOffset(80, 88)
    local baseZ = props.zIndex or 5

    -- Outer non-clipped wrapper so 2D Winged Crest Flanges, SAFE/LIVE 3D badges & Lv. XXX pill overflow cleanly!
    local wrapper = UIFactory.Create("Frame", parent, {
        Name = props.name or "LiveAvatarPortrait",
        Position = props.position or UDim2.fromOffset(12, 10),
        Size = frameSize,
        BackgroundTransparency = 1,
        ClipsDescendants = false,
        ZIndex = baseZ,
    })

    -- Layer 1: Rotating 2D Astrolabe Ring Backdrop behind Crest (Tier 2+)
    local astrolabeBack = UIFactory.Create("Frame", wrapper, {
        Name = "AstrolabeBackdropRing",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.50),
        Size = UDim2.new(1, 14, 1, 8),
        BackgroundColor3 = Color3.fromRGB(16, 26, 46),
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = baseZ,
    })
    UIFactory.AspectRatio(astrolabeBack, 1)
    UIFactory.PillCorner(astrolabeBack)
    local astrolabeStroke = UIFactory.Stroke(astrolabeBack, colors.ACCENT_GOLD, 1.4, 0.38)

    local astrolabeTicks = {}
    for i = 1, 8 do
        local ang = ((i - 1) / 8) * math.pi * 2
        local tick = UIFactory.Create("Frame", astrolabeBack, {
            Name = "AstroTick_" .. i,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5 + math.cos(ang) * 0.47, 0.5 + math.sin(ang) * 0.47),
            Size = UDim2.fromOffset(4, 4),
            Rotation = 45,
            BackgroundColor3 = colors.ACCENT_GOLD_BRIGHT,
            BackgroundTransparency = 0.25,
            BorderSizePixel = 0,
            ZIndex = baseZ + 1,
        })
        table.insert(astrolabeTicks, tick)
    end

    -- Layer 2: 2D Progressive Winged Crest Flanges (Left & Right shoulders + Top Sovereign Crown)
    local crestWingsLayer = UIFactory.Create("Frame", wrapper, {
        Name = "CrestWingsLayer",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ClipsDescendants = false,
        ZIndex = baseZ + 1,
    })

    local wingParts = {
        Upper = {},
        Lower = {},
        Sparks = {},
    }
    for _, side in ipairs({ -1, 1 }) do
        local ax = (side == -1) and 0 or 1
        local upperWing = UIFactory.Create("Frame", crestWingsLayer, {
            Name = (side == -1 and "Left" or "Right") .. "UpperWing",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(ax, side * 3, 0.28, 0),
            Size = UDim2.fromOffset(12, 22),
            Rotation = side * 18,
            BackgroundColor3 = colors.ACCENT_GOLD,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = baseZ + 1,
        })
        UIFactory.Corner(upperWing, 3)
        local uwStroke = UIFactory.Stroke(upperWing, colors.ACCENT_GOLD_BRIGHT, 1.3, 0.08)
        table.insert(wingParts.Upper, { Frame = upperWing, Stroke = uwStroke })

        local lowerWing = UIFactory.Create("Frame", crestWingsLayer, {
            Name = (side == -1 and "Left" or "Right") .. "LowerWing",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(ax, side * 2, 0.54, 0),
            Size = UDim2.fromOffset(10, 18),
            Rotation = side * 12,
            BackgroundColor3 = CLASS_ACCENTS.ThunderStriker,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = baseZ + 1,
        })
        UIFactory.Corner(lowerWing, 3)
        local lwStroke = UIFactory.Stroke(lowerWing, Color3.new(1, 1, 1), 1.1, 0.18)
        table.insert(wingParts.Lower, { Frame = lowerWing, Stroke = lwStroke })
    end

    -- 4 Corner Spark / Astral Diamond Accents (Tier 3 & Tier 4)
    local sparkPositions = {
        { x = 0, y = 0.16, rot = 32 },
        { x = 1, y = 0.16, rot = -32 },
        { x = 0, y = 0.80, rot = -28 },
        { x = 1, y = 0.80, rot = 28 },
    }
    for idx, sp in ipairs(sparkPositions) do
        local spark = UIFactory.Create("Frame", crestWingsLayer, {
            Name = "CornerSpark_" .. idx,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.new(sp.x, (sp.x == 0 and -4 or 4), sp.y, 0),
            Size = UDim2.fromOffset(6, 6),
            Rotation = 45,
            BackgroundColor3 = colors.ACCENT_GOLD_BRIGHT,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = baseZ + 8,
        })
        UIFactory.Corner(spark, 1)
        UIFactory.Stroke(spark, Color3.new(1, 1, 1), 1, 0.15)
        table.insert(wingParts.Sparks, spark)
    end

    -- Top Sovereign Crown Chevron (Tier 4 / Race V4)
    local topCrownChevron = UIFactory.Create("Frame", crestWingsLayer, {
        Name = "SovereignTopChevron",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0, -2),
        Size = UDim2.fromOffset(14, 14),
        Rotation = 45,
        BackgroundColor3 = SOVEREIGN_VIOLET,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = baseZ + 7,
    })
    UIFactory.Corner(topCrownChevron, 3)
    UIFactory.Stroke(topCrownChevron, colors.ACCENT_GOLD_BRIGHT, 1.5, 0.05)

    -- Layer 3: Inner Portrait Crest Box
    local innerBox = UIFactory.Create("Frame", wrapper, {
        Name = "CrestInnerBox",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = baseZ + 2,
    })
    UIFactory.Corner(innerBox, 11)
    local borderStroke = UIFactory.Stroke(innerBox, TIER1_STEEL, 2.0, 0.06)
    local innerGrad = UIFactory.Gradient(innerBox, Color3.fromRGB(32, 54, 92), colors.BG_900, 135)

    -- 4 Golden/Accent Corner Brackets inside Crest Box (Tier 2+)
    local cornerBrackets = {}
    local cbDefs = {
        { ax = 0, ay = 0, px = 3, py = 3 },
        { ax = 1, ay = 0, px = -3, py = 3 },
        { ax = 0, ay = 1, px = 3, py = -3 },
        { ax = 1, ay = 1, px = -3, py = -3 },
    }
    for idx, cb in ipairs(cbDefs) do
        local bh = UIFactory.Create("Frame", wrapper, {
            Name = "CrestBracketH_" .. idx,
            AnchorPoint = Vector2.new(cb.ax, cb.ay),
            Position = UDim2.new(cb.ax, cb.px, cb.ay, cb.py),
            Size = UDim2.fromOffset(9, 2),
            BackgroundColor3 = colors.ACCENT_GOLD_BRIGHT,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = baseZ + 6,
        })
        local bv = UIFactory.Create("Frame", wrapper, {
            Name = "CrestBracketV_" .. idx,
            AnchorPoint = Vector2.new(cb.ax, cb.ay),
            Position = UDim2.new(cb.ax, cb.px, cb.ay, cb.py),
            Size = UDim2.fromOffset(2, 9),
            BackgroundColor3 = colors.ACCENT_GOLD_BRIGHT,
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = baseZ + 6,
        })
        table.insert(cornerBrackets, bh)
        table.insert(cornerBrackets, bv)
    end

    -- Radial Elemental Glow Disc behind 3D Bust
    local radialGlow = UIFactory.Create("Frame", innerBox, {
        Name = "RadialAuraBackdrop",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.46),
        Size = UDim2.new(0.86, 0, 0.86, 0),
        BackgroundColor3 = colors.ACCENT_SAPPHIRE,
        BackgroundTransparency = 0.78,
        BorderSizePixel = 0,
        ZIndex = baseZ + 3,
    })
    UIFactory.PillCorner(radialGlow)

    -- Layer 4: Live 3D Bust ViewportFrame (Front-Lit Face & Upper-Shoulders Hero Portrait)
    local viewport = UIFactory.Create("ViewportFrame", innerBox, {
        Name = "AvatarBustViewport",
        Position = UDim2.fromOffset(2, 2),
        Size = UDim2.new(1, -4, 1, -4),
        BackgroundTransparency = 1,
        Ambient = Color3.fromRGB(222, 230, 246),
        LightColor = Color3.fromRGB(255, 250, 235),
        LightDirection = Vector3.new(-0.22, -0.32, 0.92),
        ZIndex = baseZ + 4,
    })
    UIFactory.Corner(viewport, 9)

    local cam = Instance.new("Camera")
    cam.Name = "BustCamera"
    cam.FieldOfView = 22
    cam.Parent = viewport
    viewport.CurrentCamera = cam

    local worldModel = Instance.new("WorldModel")
    worldModel.Name = "BustWorld"
    worldModel.Parent = viewport

    -- Layer 5A: Top-Left SAFE Emerald Pill Badge ((-4, -5) in Figma HUD & VFX Bible)
    local safePill = UIFactory.Create("Frame", wrapper, {
        Name = "SafeBadgePill",
        AnchorPoint = Vector2.new(0, 0),
        Position = UDim2.fromOffset(-4, -5),
        Size = UDim2.fromOffset(40, 15),
        BackgroundColor3 = Color3.fromRGB(9, 14, 26),
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        ZIndex = baseZ + 9,
    })
    UIFactory.PillCorner(safePill)
    UIFactory.Stroke(safePill, Color3.fromRGB(34, 197, 94), 1.2, 0.10)

    local safeDot = UIFactory.Create("Frame", safePill, {
        Name = "EmeraldDot",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 5, 0.5, 0),
        Size = UDim2.fromOffset(5, 5),
        BackgroundColor3 = Color3.fromRGB(34, 224, 108),
        BorderSizePixel = 0,
        ZIndex = baseZ + 10,
    })
    UIFactory.PillCorner(safeDot)

    local safeLabel = UIFactory.Label(safePill, {
        Name = "SafeText",
        Text = "SAFE",
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -14, 1, 0),
        TextSize = 8,
        TextColor = Color3.fromRGB(236, 253, 245),
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Wrapped = false,
        ZIndex = baseZ + 10,
    })

    -- Layer 5B: Top-Right LIVE 3D Cyan Pill Badge ((4, -5) in Figma HUD & VFX Bible)
    local livePill = UIFactory.Create("Frame", wrapper, {
        Name = "Live3DBadgePill",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, 4, 0, -5),
        Size = UDim2.fromOffset(42, 15),
        BackgroundColor3 = Color3.fromRGB(9, 14, 26),
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        ZIndex = baseZ + 9,
    })
    UIFactory.PillCorner(livePill)
    UIFactory.Stroke(livePill, Color3.fromRGB(56, 189, 248), 1.2, 0.08)

    UIFactory.Label(livePill, {
        Name = "Live3DText",
        Text = "LIVE 3D",
        Size = UDim2.fromScale(1, 1),
        TextSize = 8,
        TextColor = Color3.fromRGB(125, 224, 255),
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Wrapped = false,
        ZIndex = baseZ + 10,
    })

    -- Layer 5C: Overlapping Obsidian-Gold Lv. XXX Pill Badge centered along bottom edge
    local levelPill = UIFactory.Create("Frame", wrapper, {
        Name = "LevelPill",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 1, 0),
        Size = UDim2.fromOffset(64, 20),
        BackgroundColor3 = Color3.fromRGB(9, 14, 26),
        BackgroundTransparency = 0.02,
        BorderSizePixel = 0,
        ZIndex = baseZ + 9,
    })
    UIFactory.PillCorner(levelPill)
    local levelPillStroke = UIFactory.Stroke(levelPill, colors.ACCENT_GOLD_BRIGHT, 1.5, 0.06)
    UIFactory.Gradient(levelPill, Color3.fromRGB(28, 42, 68), colors.BG_900, 90)

    local levelLabel = UIFactory.Label(levelPill, {
        Name = "Level",
        Text = "Lv. 1",
        Size = UDim2.fromScale(1, 1),
        TextSize = 11,
        TextColor = Color3.fromRGB(248, 250, 255),
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Wrapped = false,
        ZIndex = baseZ + 10,
    })

    local activeSig = ""
    local currentTier = 1
    local focusCenter = Vector3.new(0, 1.38, 0)
    local camDist = 4.62
    local ring1Model = nil
    local ring2Model = nil
    local crownModel = nil
    local orbitMotes = {}
    local connections = {}
    local lastSnapshot = nil
    local rebuildQueued = false

    local function sync2DCrestWings(tier, accent)
        local isTier2Plus = tier >= 2
        local isTier3Plus = tier >= 3
        local isTier4 = tier >= 4

        local primaryCol = (tier == 1 and TIER1_STEEL)
            or (tier == 2 and colors.ACCENT_GOLD)
            or (tier == 3 and accent)
            or SOVEREIGN_VIOLET
        local rimCol = isTier4 and colors.ACCENT_GOLD_BRIGHT
            or (tier == 2 and colors.ACCENT_GOLD_BRIGHT)
            or (tier == 3 and accent:Lerp(Color3.new(1, 1, 1), 0.35))
            or TIER1_STEEL

        astrolabeBack.Visible = isTier2Plus
        astrolabeStroke.Color = primaryCol
        for _, tk in ipairs(astrolabeTicks) do
            tk.BackgroundColor3 = rimCol
        end

        for _, w in ipairs(wingParts.Upper) do
            w.Frame.Visible = isTier2Plus
            w.Frame.BackgroundColor3 = primaryCol
            w.Stroke.Color = rimCol
        end
        for _, w in ipairs(wingParts.Lower) do
            w.Frame.Visible = isTier3Plus
            w.Frame.BackgroundColor3 = isTier4 and colors.ACCENT_GOLD or accent
            w.Stroke.Color = rimCol
        end
        for idx, sp in ipairs(wingParts.Sparks) do
            sp.Visible = isTier3Plus
            sp.BackgroundColor3 = (idx % 2 == 0) and colors.ACCENT_GOLD_BRIGHT or primaryCol
        end
        for _, br in ipairs(cornerBrackets) do
            br.Visible = isTier2Plus
            br.BackgroundColor3 = rimCol
        end
        topCrownChevron.Visible = isTier4

        if tier <= 1 then
            innerGrad.Color = ColorSequence.new(Color3.fromRGB(28, 38, 56), colors.BG_900)
        elseif tier == 2 then
            innerGrad.Color = ColorSequence.new(Color3.fromRGB(64, 52, 24), colors.BG_900)
        elseif tier == 3 then
            innerGrad.Color = ColorSequence.new(accent:Lerp(colors.BG_900, 0.55), colors.BG_900)
        else
            innerGrad.Color = ColorSequence.new(Color3.fromRGB(68, 34, 96), colors.BG_900)
        end
    end

    local function buildTierVFX(vfxParent, tier, accent)
        ring1Model = nil
        ring2Model = nil
        crownModel = nil
        table.clear(orbitMotes)

        sync2DCrestWings(tier, accent)

        if tier <= 1 then
            viewport.Ambient = Color3.fromRGB(204, 210, 224)
            viewport.LightColor = Color3.fromRGB(255, 242, 216)
            borderStroke.Color = TIER1_STEEL
            borderStroke.Thickness = 2.0
            radialGlow.BackgroundColor3 = TIER1_STEEL
            radialGlow.BackgroundTransparency = 0.86
            levelPillStroke.Color = TIER1_STEEL
            levelLabel.TextColor3 = Color3.fromRGB(238, 244, 255)
            return
        end

        local frameCol = (tier == 2 and colors.ACCENT_GOLD_BRIGHT)
            or (tier == 3 and accent)
            or SOVEREIGN_VIOLET

        viewport.Ambient = Color3.fromRGB(206, 220, 244)
        viewport.LightColor = Color3.fromRGB(255, 250, 232)
        borderStroke.Color = frameCol
        borderStroke.Thickness = tier >= 4 and 2.4 or 2.1
        radialGlow.BackgroundColor3 = frameCol
        radialGlow.BackgroundTransparency = tier >= 3 and 0.64 or 0.72
        levelPillStroke.Color = (tier == 3) and accent or colors.ACCENT_GOLD_BRIGHT
        levelLabel.TextColor3 = Color3.fromRGB(250, 252, 255)

        -- Tier 2+: Primary Glowing 3D Neon Halo Ring behind shoulders/head
        ring1Model = buildHollowNeonRing(vfxParent, "ClassHaloRing1", 1.28, 0.085, frameCol, 0.06)

        if tier >= 3 then
            local secondaryCol = (tier >= 4) and colors.ACCENT_GOLD_BRIGHT or accent:Lerp(colors.ACCENT_GOLD_BRIGHT, 0.45)
            ring2Model = buildHollowNeonRing(vfxParent, "ClassRuneRing2", 1.52, 0.065, secondaryCol, 0.10)

            local moteCount = (tier >= 4) and 4 or 3
            for i = 1, moteCount do
                local shard = Instance.new("Part")
                shard.Name = "ElementalMote_" .. i
                shard.Size = (tier >= 4) and Vector3.new(0.16, 0.30, 0.16) or Vector3.new(0.14, 0.22, 0.14)
                shard.Color = (i % 2 == 0) and colors.ACCENT_GOLD_BRIGHT or frameCol
                shard.Material = Enum.Material.Neon
                shard.Anchored = true
                shard.CanCollide = false
                shard.CanQuery = false
                shard.CanTouch = false
                shard.Parent = vfxParent
                table.insert(orbitMotes, {
                    Part = shard,
                    Phase = ((i - 1) / moteCount) * math.pi * 2,
                    Radius = (tier >= 4) and 1.42 or 1.32,
                })
            end
        end

        if tier >= 4 then
            local cm = Instance.new("Model")
            cm.Name = "SovereignCrownHalo"
            local cp = Instance.new("Part")
            cp.Name = "Pivot"
            cp.Size = Vector3.new(0.05, 0.05, 0.05)
            cp.Transparency = 1
            cp.Anchored = true
            cp.CanCollide = false
            cp.CFrame = CFrame.new(0, 2.36, 0.05)
            cp.Parent = cm
            cm.PrimaryPart = cp

            for i = 1, 5 do
                local ang = (i - 3) * 0.36
                local rayH = (i == 3) and 0.48 or ((i == 2 or i == 4) and 0.36 or 0.26)
                local ray = Instance.new("WedgePart")
                ray.Name = "SovereignRay_" .. i
                ray.Size = Vector3.new(0.09, rayH, 0.16)
                ray.Color = (i == 3) and SOVEREIGN_VIOLET or colors.ACCENT_GOLD_BRIGHT
                ray.Material = Enum.Material.Neon
                ray.Anchored = true
                ray.CanCollide = false
                ray.CFrame = CFrame.new(math.sin(ang) * 0.60, 2.34 + rayH * 0.35, 0.10) * CFrame.Angles(0, 0, -ang * 0.85)
                ray.Parent = cm
            end
            cm.Parent = vfxParent
            crownModel = cm
        end
    end

    local function rebuildBust(snapshot, force)
        snapshot = snapshot or lastSnapshot or {}
        lastSnapshot = snapshot
        local lp = Players.LocalPlayer
        local pData = snapshot.player or {}
        local fData = snapshot.fruits or {}
        local lv = tonumber(pData.level) or 1
        local classId = tostring(pData.classId or "SkyGuardian")
        local accent = CLASS_ACCENTS[classId] or CLASS_ACCENTS.SkyGuardian

        local ch = lp and lp.Character
        local hakiOn = (fData.haki and fData.haki.Aura == true)
            or (lp and (lp:GetAttribute("HakiAura") == true or lp:GetAttribute("BusoActive") == true))
            or (ch and ch:GetAttribute("HakiAura") == true)
        local v4On = (fData.raceV4Active == true)
            or (lp and (lp:GetAttribute("RaceV4Active") == true or tostring(lp:GetAttribute("RaceV4") or "") ~= ""))
            or (ch and (ch:GetAttribute("RaceV4Active") == true or tostring(ch:GetAttribute("RaceV4") or "") ~= ""))

        local tier = computeClassTier(lv, hakiOn, v4On)
        local eqSig = readEquippedSignature(snapshot, lp)
        local hasCharHead = (ch and ch:FindFirstChild("Head")) ~= nil
        local visualPartCount = 0
        if ch then
            for _, child in ipairs(ch:GetChildren()) do
                if child:IsA("Model") and not isPortraitClutterName(child.Name) then
                    for _, sub in ipairs(child:GetDescendants()) do
                        if sub:IsA("BasePart") and sub.Transparency < 0.85 then
                            visualPartCount += 1
                        end
                    end
                elseif child:IsA("Accessory") then
                    visualPartCount += 1
                end
            end
        end
        local newSig = string.format("%s|%d|%s|%d|%s", classId, tier, tostring(hasCharHead), visualPartCount, eqSig)

        levelLabel.Text = "Lv. " .. tostring(lv)

        if not force and newSig == activeSig then
            return
        end
        activeSig = newSig
        currentTier = tier

        worldModel:ClearAllChildren()

        local bust, headRef, isCustomHeroRig = cloneLocalPlayerBust()
        if not bust then
            bust, headRef = buildR15FallbackBust(accent, classId)
            isCustomHeroRig = false
        end
        bust.Parent = worldModel
        if not isCustomHeroRig then
            attachSnapshotArmorAccents(bust, headRef, snapshot, accent, tier)
        end

        local headPos = headRef and headRef.Position or Vector3.new(0, 1.62, 0)
        focusCenter = isCustomHeroRig and headPos or (headPos - Vector3.new(0, 0.08, 0))
        camDist = isCustomHeroRig and 3.95 or 3.85

        local vfxFolder = Instance.new("Folder")
        vfxFolder.Name = "ClassTierVFX"
        vfxFolder.Parent = worldModel
        buildTierVFX(vfxFolder, tier, accent)
        if crownModel and crownModel.PrimaryPart then
            crownModel:PivotTo(CFrame.new(focusCenter.X, headPos.Y + 0.86, headPos.Z + 0.10))
        end
    end

    local function queueRebuild()
        if rebuildQueued then
            return
        end
        rebuildQueued = true
        task.delay(0.25, function()
            rebuildQueued = false
            if wrapper and wrapper.Parent then
                rebuildBust(lastSnapshot, true)
            end
        end)
    end

    local lp = Players.LocalPlayer
    if lp then
        table.insert(connections, lp.CharacterAdded:Connect(function(newChar)
            queueRebuild()
            task.delay(1.1, function()
                if wrapper and wrapper.Parent and lp.Character == newChar then
                    rebuildBust(lastSnapshot, true)
                end
            end)
        end))
        table.insert(connections, lp.CharacterAppearanceLoaded:Connect(function()
            queueRebuild()
        end))
        for _, attrName in ipairs({ "HakiAura", "BusoActive", "RaceV4Active", "RaceV4", "ClassId", "EquippedHelmet", "EquippedChest" }) do
            table.insert(connections, lp:GetAttributeChangedSignal(attrName):Connect(queueRebuild))
        end
    end

    local t0 = os.clock()
    local stepAcc = 0
    local syncCheckAcc = 0
    table.insert(connections, RunService.RenderStepped:Connect(function(dt)
        if not wrapper.Parent or not isGuiChainVisible(wrapper) then
            return
        end
        stepAcc += dt
        syncCheckAcc += dt
        if syncCheckAcc >= 0.65 then
            syncCheckAcc = 0
            rebuildBust(lastSnapshot, false)
        end
        if stepAcc < 0.032 then
            return
        end
        stepAcc = 0

        local t = os.clock() - t0
        local breatheY = math.sin(t * 2.15) * 0.034
        local swayYaw = math.sin(t * 0.92) * 0.080
        local camDir = Vector3.new(math.sin(swayYaw), 0, -math.cos(swayYaw))
        local camPos = focusCenter + (camDir * camDist) + Vector3.new(0, 0.12 + breatheY, 0)
        cam.CFrame = CFrame.lookAt(camPos, focusCenter + Vector3.new(0, breatheY * 0.45, 0))

        if astrolabeBack.Visible then
            local rotSpeed = (currentTier >= 3) and 42 or 18
            astrolabeBack.Rotation = (t * rotSpeed) % 360
        end

        local ringOrigin = focusCenter + Vector3.new(0, 0.14, 0.50)
        if ring1Model and ring1Model.PrimaryPart then
            ring1Model:PivotTo(CFrame.new(ringOrigin) * CFrame.Angles(math.rad(10), 0, t * 0.85))
        end
        if ring2Model and ring2Model.PrimaryPart then
            ring2Model:PivotTo(CFrame.new(ringOrigin + Vector3.new(0, 0, 0.08)) * CFrame.Angles(math.rad(-14), math.rad(12), -t * 1.25))
        end
        if crownModel and crownModel.PrimaryPart then
            crownModel:PivotTo(CFrame.new(focusCenter.X, focusCenter.Y + 0.94 + math.sin(t * 2.8) * 0.04, focusCenter.Z + 0.14) * CFrame.Angles(0, math.sin(t * 1.4) * 0.08, 0))
        end
        for _, mote in ipairs(orbitMotes) do
            if mote.Part and mote.Part.Parent then
                local a = t * 1.65 + mote.Phase
                local mx = focusCenter.X + math.cos(a) * mote.Radius
                local my = focusCenter.Y + 0.14 + math.sin(a * 1.5) * 0.48
                local mz = focusCenter.Z + 0.34 + math.sin(a) * 0.36
                mote.Part.CFrame = CFrame.new(mx, my, mz) * CFrame.Angles(t * 2.1, a, math.rad(28))
            end
        end
        if currentTier >= 4 then
            local pulse = 0.5 + 0.5 * math.sin(t * 3.1)
            borderStroke.Color = SOVEREIGN_VIOLET:Lerp(colors.ACCENT_GOLD_BRIGHT, pulse * 0.55)
        end
    end))

    rebuildBust(props.snapshot, true)

    local api = {
        Instance = wrapper,
        LevelLabel = levelLabel,
        SafeLabel = safeLabel,
    }

    function api:Update(snapshot)
        if not wrapper or not wrapper.Parent then
            return
        end
        rebuildBust(snapshot, false)
    end

    function api:Destroy()
        for _, c in ipairs(connections) do
            c:Disconnect()
        end
        table.clear(connections)
        table.clear(orbitMotes)
        if wrapper and wrapper.Parent then
            wrapper:Destroy()
        end
    end

    return wrapper, api
end

return LiveAvatarPortrait
