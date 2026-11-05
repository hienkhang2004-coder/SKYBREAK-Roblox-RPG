local TweenService = game:GetService("TweenService")
local M={}

local function formatNumber(n)
    local s = tostring(math.max(0, math.floor(tonumber(n) or 0)))
    local k
    while true do
        s, k = string.gsub(s, "^(-?%d+)(%d%d%d)", "%1,%2")
        if k == 0 then break end
    end
    return s
end

local function installBillboardBuilders(W)
    function W.Label(part, text, accentColor, studsOffset, maxDist)
        local accent = accentColor or Color3.fromRGB(238, 190, 76)
        local gui = Instance.new("BillboardGui")
        gui.Name = "WorldSignBillboard"
        gui.Adornee = part
        -- 3D World-Space Studs so object nameplates scale naturally with distance
        gui.Size = UDim2.fromScale(3.6, 0.68)
        gui.StudsOffset = studsOffset or Vector3.new(0, 3.8, 0)
        gui.AlwaysOnTop = false
        gui.LightInfluence = 0
        gui.MaxDistance = maxDist or 44
        gui.Parent = part

        local card = Instance.new("Frame")
        card.Name = "Card"
        card.Size = UDim2.fromScale(1, 1)
        card.BackgroundColor3 = Color3.fromRGB(10, 16, 28)
        card.BackgroundTransparency = 0.14
        card.BorderSizePixel = 0
        card.Parent = gui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0.24, 0)
        corner.Parent = card

        local stroke = Instance.new("UIStroke")
        stroke.Color = accent
        stroke.Thickness = 1.2
        stroke.Transparency = 0.16
        stroke.Parent = card

        local grad = Instance.new("UIGradient")
        grad.Color = ColorSequence.new(Color3.fromRGB(22, 34, 54), Color3.fromRGB(10, 14, 24))
        grad.Rotation = 90
        grad.Parent = card

        local topBar = Instance.new("Frame")
        topBar.Name = "TopAccent"
        topBar.Position = UDim2.fromScale(0.08, 0)
        topBar.Size = UDim2.fromScale(0.84, 0.06)
        topBar.BackgroundColor3 = accent
        topBar.BackgroundTransparency = 0.2
        topBar.BorderSizePixel = 0
        topBar.Parent = card

        local label = Instance.new("TextLabel")
        label.Name = "NameLabel"
        label.Size = UDim2.fromScale(0.92, 0.78)
        label.Position = UDim2.fromScale(0.04, 0.11)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.fromRGB(255, 238, 185)
        label.TextScaled = true
        label.Font = Enum.Font.GothamBold
        label.Text = text
        label.Parent = card

        local ts = Instance.new("UIStroke")
        ts.Color = Color3.fromRGB(6, 10, 18)
        ts.Thickness = 1.2
        ts.Transparency = 0.1
        ts.Parent = label

        return label
    end

    function W.EnemyBar(part, cfg, isBossFlag)
        cfg = cfg or {}
        local isBoss = (isBossFlag == true) or (cfg.Boss == true)
        local isElite = (not isBoss) and ((cfg.Elite == true) or ((tonumber(cfg.HP) or 0) >= 850))

        -- 1:1 Figma v2 Floating Enemy Healthplate: Obsidian Card + Glowing Crimson/Gold Rim + Right Role Pill + Glossy Crimson HP Bar
        local accent = isBoss and Color3.fromRGB(255, 198, 66)
            or Color3.fromRGB(251, 55, 98)
        local pillBg = isBoss and Color3.fromRGB(58, 22, 18)
            or (isElite and Color3.fromRGB(54, 16, 28) or Color3.fromRGB(32, 16, 28))
        local nameCol = isBoss and Color3.fromRGB(255, 240, 178)
            or Color3.fromRGB(255, 242, 196)
        local hpStart = isBoss and Color3.fromRGB(225, 29, 72)
            or Color3.fromRGB(225, 29, 72)
        local hpEnd = isBoss and Color3.fromRGB(251, 146, 60)
            or Color3.fromRGB(251, 113, 133)

        local gui = Instance.new("BillboardGui")
        gui.Name = "EnemyHealthplate"
        gui.Adornee = part
        gui.Size = isBoss and UDim2.fromOffset(236, 54)
            or (isElite and UDim2.fromOffset(204, 46) or UDim2.fromOffset(186, 44))
        gui.StudsOffset = Vector3.new(0, isBoss and 8.2 or (isElite and 6.2 or 5.5), 0)
        gui.AlwaysOnTop = true
        gui.LightInfluence = 0
        gui.MaxDistance = isBoss and 150 or (isElite and 115 or 96)
        gui.Parent = part

        local card = Instance.new("Frame")
        card.Name = "Card"
        card.Size = UDim2.fromScale(1, 1)
        card.BackgroundColor3 = Color3.new(1, 1, 1)
        card.BackgroundTransparency = 0.06
        card.BorderSizePixel = 0
        card.Parent = gui

        local cardCorner = Instance.new("UICorner")
        cardCorner.CornerRadius = UDim.new(0, 10)
        cardCorner.Parent = card

        local cardStroke = Instance.new("UIStroke")
        cardStroke.Name = "OuterStroke"
        cardStroke.Color = accent
        cardStroke.Thickness = isBoss and 2.0 or 1.6
        cardStroke.Transparency = 0.06
        cardStroke.Parent = card

        local cardGrad = Instance.new("UIGradient")
        cardGrad.Color = ColorSequence.new(Color3.fromRGB(18, 22, 36), Color3.fromRGB(9, 12, 22))
        cardGrad.Rotation = 90
        cardGrad.Parent = card

        local lvNum = tonumber(cfg.Level) or 1
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
        nameLabel.Position = UDim2.fromScale(0.045, 0.09)
        nameLabel.Size = UDim2.fromScale(0.68, 0.37)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.TextColor3 = nameCol
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextScaled = true
        nameLabel.Text = string.format("%s • Lv.%d", tostring(cfg.Name or "Enemy"), lvNum)
        nameLabel.Parent = card

        local nameStroke = Instance.new("UIStroke")
        nameStroke.Color = Color3.fromRGB(6, 9, 16)
        nameStroke.Thickness = 1.2
        nameStroke.Transparency = 0.08
        nameStroke.Parent = nameLabel

        -- Top-Right Role Badge Pill ([BOSS] / [ELITE] / [MOB]) matching Figma Screenshot 2
        local levelBadge = Instance.new("Frame")
        levelBadge.Name = "LevelBadge"
        levelBadge.AnchorPoint = Vector2.new(1, 0)
        levelBadge.Position = UDim2.fromScale(0.96, 0.11)
        levelBadge.Size = UDim2.fromScale(0.22, 0.33)
        levelBadge.BackgroundColor3 = pillBg
        levelBadge.BorderSizePixel = 0
        levelBadge.Parent = card

        local pillCorner = Instance.new("UICorner")
        pillCorner.CornerRadius = UDim.new(0, 5)
        pillCorner.Parent = levelBadge

        local pillStroke = Instance.new("UIStroke")
        pillStroke.Color = accent
        pillStroke.Thickness = 1.1
        pillStroke.Transparency = 0.10
        pillStroke.Parent = levelBadge

        local levelLabel = Instance.new("TextLabel")
        levelLabel.Name = "LevelLabel"
        levelLabel.Position = UDim2.fromScale(0.06, 0.08)
        levelLabel.Size = UDim2.fromScale(0.88, 0.84)
        levelLabel.BackgroundTransparency = 1
        levelLabel.Font = Enum.Font.GothamBlack
        levelLabel.TextColor3 = isBoss and Color3.fromRGB(255, 224, 122) or Color3.fromRGB(255, 198, 212)
        levelLabel.TextScaled = true
        levelLabel.Text = isBoss and "BOSS" or (isElite and "ELITE" or "MOB")
        levelLabel.Parent = levelBadge

        local hpTrack = Instance.new("Frame")
        hpTrack.Name = "HPTrack"
        hpTrack.Position = UDim2.fromScale(0.04, 0.52)
        hpTrack.Size = UDim2.fromScale(0.92, 0.33)
        hpTrack.BackgroundColor3 = Color3.fromRGB(24, 10, 18)
        hpTrack.BackgroundTransparency = 0.04
        hpTrack.BorderSizePixel = 0
        hpTrack.Parent = card

        local trackCorner = Instance.new("UICorner")
        trackCorner.CornerRadius = UDim.new(1, 0)
        trackCorner.Parent = hpTrack

        local trackStroke = Instance.new("UIStroke")
        trackStroke.Name = "TrackStroke"
        trackStroke.Color = Color3.fromRGB(92, 28, 48)
        trackStroke.Thickness = 1.0
        trackStroke.Transparency = 0.18
        trackStroke.Parent = hpTrack

        local trailFill = Instance.new("Frame")
        trailFill.Name = "DamageTrailFill"
        trailFill.Size = UDim2.fromScale(1, 1)
        trailFill.BackgroundColor3 = Color3.fromRGB(255, 232, 172)
        trailFill.BorderSizePixel = 0
        trailFill.ZIndex = 2
        trailFill.Parent = hpTrack

        local trailCorner = Instance.new("UICorner")
        trailCorner.CornerRadius = UDim.new(1, 0)
        trailCorner.Parent = trailFill

        local hpFill = Instance.new("Frame")
        hpFill.Name = "HPFill"
        hpFill.Size = UDim2.fromScale(1, 1)
        hpFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        hpFill.BorderSizePixel = 0
        hpFill.ZIndex = 3
        hpFill.Parent = hpTrack

        local fillCorner = Instance.new("UICorner")
        fillCorner.CornerRadius = UDim.new(1, 0)
        fillCorner.Parent = hpFill

        local hpGrad = Instance.new("UIGradient")
        hpGrad.Name = "HPGradient"
        hpGrad.Color = ColorSequence.new(hpStart, hpEnd)
        hpGrad.Parent = hpFill

        local gloss = Instance.new("Frame")
        gloss.Name = "Gloss"
        gloss.Size = UDim2.fromScale(1, 0.45)
        gloss.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        gloss.BackgroundTransparency = 0.72
        gloss.BorderSizePixel = 0
        gloss.ZIndex = 4
        gloss.Parent = hpFill

        local glossCorner = Instance.new("UICorner")
        glossCorner.CornerRadius = UDim.new(1, 0)
        glossCorner.Parent = gloss

        local shieldOverlay = Instance.new("Frame")
        shieldOverlay.Name = "ShieldOverlay"
        shieldOverlay.Size = UDim2.fromScale(1, 1)
        shieldOverlay.BackgroundColor3 = Color3.fromRGB(85, 228, 255)
        shieldOverlay.BackgroundTransparency = 0.52
        shieldOverlay.BorderSizePixel = 0
        shieldOverlay.Visible = false
        shieldOverlay.ZIndex = 4
        shieldOverlay.Parent = hpTrack

        local shieldCorner = Instance.new("UICorner")
        shieldCorner.CornerRadius = UDim.new(1, 0)
        shieldCorner.Parent = shieldOverlay

        local maxHp = math.max(1, tonumber(cfg.HP) or 100)
        local hpVal = Instance.new("TextLabel")
        hpVal.Name = "HPValueLabel"
        hpVal.Position = UDim2.fromScale(0.03, 0.04)
        hpVal.Size = UDim2.fromScale(0.94, 0.92)
        hpVal.BackgroundTransparency = 1
        hpVal.ZIndex = 5
        hpVal.Font = Enum.Font.GothamBold
        hpVal.TextScaled = true
        hpVal.TextColor3 = Color3.fromRGB(255, 255, 255)
        hpVal.Text = string.format("%s / %s", formatNumber(maxHp), formatNumber(maxHp))
        hpVal.Parent = hpTrack

        local hpValStroke = Instance.new("UIStroke")
        hpValStroke.Color = Color3.fromRGB(6, 9, 16)
        hpValStroke.Thickness = 1.2
        hpValStroke.Transparency = 0.06
        hpValStroke.Parent = hpVal

        local breakTrack = Instance.new("Frame")
        breakTrack.Name = "BreakTrack"
        breakTrack.Position = UDim2.fromScale(0.03, 0.88)
        breakTrack.Size = UDim2.fromScale(0.94, 0.07)
        breakTrack.BackgroundColor3 = Color3.fromRGB(16, 22, 34)
        breakTrack.BorderSizePixel = 0
        breakTrack.Parent = card

        local btCorner = Instance.new("UICorner")
        btCorner.CornerRadius = UDim.new(1, 0)
        btCorner.Parent = breakTrack

        local breakFill = Instance.new("Frame")
        breakFill.Name = "BreakFill"
        breakFill.Size = UDim2.fromScale(0, 1)
        breakFill.BackgroundColor3 = Color3.fromRGB(82, 224, 255)
        breakFill.BorderSizePixel = 0
        breakFill.Parent = breakTrack

        local bfCorner = Instance.new("UICorner")
        bfCorner.CornerRadius = UDim.new(1, 0)
        bfCorner.Parent = breakFill

        return nameLabel
    end

    function W.UpdateEnemyBar(e)
        if not e or not e.Label or not e.Label.Parent then
            return
        end
        local card = e.Label.Parent
        local gui = card and card.Parent
        if not card or not gui then
            return
        end
        if not e.Alive then
            gui.Enabled = false
            return
        end

        local cfg = e.Config or {}
        local isBoss = (cfg.Boss == true) or (e.Id == "AureonSentinel" or e.Id == "CryonPrime" or e.Id == "Noxar" or e.Id == "Veyr")
        local isElite = (not isBoss) and ((cfg.Elite == true) or ((tonumber(e.MaxHP) or 0) >= 850))
        local hp = math.max(0, math.ceil(tonumber(e.HP) or 0))
        local maxHp = math.max(1, math.ceil(tonumber(e.MaxHP) or 1))
        local ratio = math.clamp(hp / maxHp, 0, 1)
        local pct = math.clamp(math.ceil(ratio * 100), 0, 100)
        local stunned = os.clock() < (tonumber(e.StunnedUntil) or 0)
        local shielded = (e.Shield == true)
        local brk = math.clamp((tonumber(e.Break) or 0) / 100, 0, 1)

        local stateKey = string.format("%d_%d_%d_%s_%s_%d", hp, maxHp, math.floor(brk * 100), tostring(shielded), tostring(stunned), tonumber(e.Phase) or 1)
        if e.LastPlateKey == stateKey then
            return
        end
        e.LastPlateKey = stateKey

        local lvNum = tonumber(cfg.Level) or 1
        local phaseSuffix = (isBoss and (tonumber(e.Phase) or 1) > 1) and (" • P" .. tostring(e.Phase)) or ""
        e.Label.Text = string.format("%s • Lv.%d%s", tostring(cfg.Name or e.Id), lvNum, phaseSuffix)

        local hpTrack = card:FindFirstChild("HPTrack")
        if hpTrack then
            local hpFill = hpTrack:FindFirstChild("HPFill")
            local trailFill = hpTrack:FindFirstChild("DamageTrailFill")
            local hpVal = hpTrack:FindFirstChild("HPValueLabel")
            local shieldOverlay = hpTrack:FindFirstChild("ShieldOverlay")

            if hpFill then
                hpFill.Size = UDim2.fromScale(ratio, 1)
                local grad = hpFill:FindFirstChild("HPGradient")
                if grad then
                    if shielded then
                        grad.Color = ColorSequence.new(Color3.fromRGB(58, 198, 255), Color3.fromRGB(156, 246, 255))
                    elseif isBoss then
                        grad.Color = ColorSequence.new(Color3.fromRGB(225, 29, 72), Color3.fromRGB(251, 146, 60))
                    else
                        grad.Color = ColorSequence.new(Color3.fromRGB(225, 29, 72), Color3.fromRGB(251, 113, 133))
                    end
                end
            end

            if trailFill then
                TweenService:Create(
                    trailFill,
                    TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                    { Size = UDim2.fromScale(ratio, 1) }
                ):Play()
            end

            if shieldOverlay then
                shieldOverlay.Visible = shielded
            end

            if hpVal then
                if shielded then
                    hpVal.Text = string.format("KHIÊN • %s / %s", formatNumber(hp), formatNumber(maxHp))
                elseif stunned then
                    hpVal.Text = string.format("CHOÁNG • %s / %s", formatNumber(hp), formatNumber(maxHp))
                else
                    hpVal.Text = string.format("%s / %s", formatNumber(hp), formatNumber(maxHp))
                end
            end
        end

        local breakTrack = card:FindFirstChild("BreakTrack")
        if breakTrack then
            local breakFill = breakTrack:FindFirstChild("BreakFill")
            if breakFill then
                if stunned then
                    breakFill.Size = UDim2.fromScale(1, 1)
                    breakFill.BackgroundColor3 = Color3.fromRGB(255, 214, 64)
                else
                    breakFill.Size = UDim2.fromScale(brk, 1)
                    breakFill.BackgroundColor3 = Color3.fromRGB(82, 224, 255)
                end
            end
        end
    end
end

local function make3DPart(parent, name, size, cf, color, mat, shape, canCollide, transparency)
    local p = Instance.new("Part")
    p.Name = name
    if shape then
        p.Shape = shape
    end
    p.Size = size
    p.CFrame = cf
    p.Anchored = true
    p.CanCollide = (canCollide == true)
    p.CanQuery = false
    p.CanTouch = false
    p.Color = color
    p.Material = mat or Enum.Material.SmoothPlastic
    p.Transparency = transparency or 0
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

local function buildAetherStation3D(parent, id, pos, floorY)
    local mdl = Instance.new("Model")
    mdl.Name = id .. "_3DModel"
    mdl.Parent = parent

    local ivory = Color3.fromRGB(234, 228, 212)
    local gold = Color3.fromRGB(238, 190, 74)
    local darkSlate = Color3.fromRGB(26, 36, 56)
    local cyanNeon = Color3.fromRGB(82, 232, 255)
    local coreWhite = Color3.fromRGB(210, 252, 255)

    -- 1. Stepped Marble & Gold Pedestal Base
    make3DPart(mdl, "BasePlinth", Vector3.new(0.72, 5.4, 5.4), CFrame.new(pos.X, floorY + 0.36, pos.Z) * CFrame.Angles(0, 0, math.pi / 2), ivory, Enum.Material.Marble, Enum.PartType.Cylinder, true)
    make3DPart(mdl, "GoldRuneRim", Vector3.new(0.78, 4.65, 4.65), CFrame.new(pos.X, floorY + 0.39, pos.Z) * CFrame.Angles(0, 0, math.pi / 2), cyanNeon, Enum.Material.Neon, Enum.PartType.Cylinder, false)
    make3DPart(mdl, "StepCollar", Vector3.new(0.55, 4.15, 4.15), CFrame.new(pos.X, floorY + 0.78, pos.Z) * CFrame.Angles(0, 0, math.pi / 2), gold, Enum.Material.Metal, Enum.PartType.Cylinder, true)
    make3DPart(mdl, "ConduitCoreColumn", Vector3.new(1.75, 2.25, 1.75), CFrame.new(pos.X, floorY + 1.85, pos.Z), darkSlate, Enum.Material.Metal, nil, true)
    make3DPart(mdl, "ColumnCap", Vector3.new(2.25, 0.32, 2.25), CFrame.new(pos.X, floorY + 2.95, pos.Z), gold, Enum.Material.Metal, nil, false)

    -- 2. Four Curved Golden-Steel Stabilizer Fins with Plasma Strips
    for i = 1, 4 do
        local ang = (i - 1) * (math.pi / 2) + (math.pi / 4)
        local dir = Vector3.new(math.cos(ang), 0, math.sin(ang))
        local finPos = Vector3.new(pos.X, floorY + 2.45, pos.Z) + dir * 1.55
        local finCF = CFrame.lookAt(finPos, Vector3.new(pos.X, floorY + 3.45, pos.Z)) * CFrame.Angles(math.rad(-18), 0, 0)
        make3DPart(mdl, "StabilizerFin_" .. i, Vector3.new(0.42, 2.85, 0.78), finCF, gold, Enum.Material.Metal, nil, false)
        make3DPart(mdl, "FinPlasma_" .. i, Vector3.new(0.18, 2.45, 0.24), finCF * CFrame.new(0, 0, -0.32), cyanNeon, Enum.Material.Neon, nil, false)
    end

    -- 3. Central Levitating Aether Core Crystal & Dual Gyro Rings
    local crystalCenter = Vector3.new(pos.X, floorY + 4.35, pos.Z)
    local crystalCF = CFrame.new(crystalCenter) * CFrame.Angles(math.rad(35), math.rad(45), math.rad(35))
    local corePart = make3DPart(mdl, "AetherCrystalOuter", Vector3.new(1.42, 2.35, 1.42), crystalCF, cyanNeon, Enum.Material.Neon, nil, false, 0.12)
    make3DPart(mdl, "AetherCrystalInner", Vector3.new(0.82, 1.65, 0.82), crystalCF, coreWhite, Enum.Material.Neon, nil, false)

    -- Dual Tilted Gyro Rings (8-segment octagonal rings for crisp 3D torus look)
    for rIdx, tilt in ipairs({ math.rad(32), math.rad(-32) }) do
        local ringCF = CFrame.new(crystalCenter) * CFrame.Angles(tilt, (rIdx - 1) * math.rad(45), math.rad(18))
        local segs = 12
        local radius = (rIdx == 1) and 1.85 or 1.52
        local col = (rIdx == 1) and gold or cyanNeon
        local mat = (rIdx == 1) and Enum.Material.Metal or Enum.Material.Neon
        for s = 1, segs do
            local a1 = (s - 1) * (2 * math.pi / segs)
            local a2 = s * (2 * math.pi / segs)
            local p1 = (ringCF * CFrame.new(math.cos(a1) * radius, 0, math.sin(a1) * radius)).Position
            local p2 = (ringCF * CFrame.new(math.cos(a2) * radius, 0, math.sin(a2) * radius)).Position
            local mid = (p1 + p2) * 0.5
            make3DPart(mdl, string.format("GyroRing_%d_%d", rIdx, s), Vector3.new(0.18, 0.18, (p2 - p1).Magnitude + 0.06), CFrame.lookAt(mid, p2), col, mat, nil, false)
        end
    end

    -- Top Celestial Finial Crown & Light
    make3DPart(mdl, "CrownFinial", Vector3.new(0.55, 0.55, 0.55), CFrame.new(pos.X, floorY + 6.05, pos.Z) * CFrame.Angles(math.rad(45), math.rad(45), 0), gold, Enum.Material.Neon, nil, false)
    local pt = Instance.new("PointLight")
    pt.Color = cyanNeon
    pt.Range = 14
    pt.Brightness = 1.35
    pt.Parent = corePart
    return mdl
end

local function buildSkybornCitizen3D(parent, activeNPCs, id, pos, floorY, marker)
    local dais = Instance.new("Model")
    dais.Name = id .. "_SanctuaryDais3D"
    dais.Parent = parent

    local ivory = Color3.fromRGB(236, 232, 218)
    local gold = Color3.fromRGB(238, 192, 78)
    local sapphire = Color3.fromRGB(88, 220, 255)
    local deepNavy = Color3.fromRGB(28, 46, 82)

    -- 1. 3D Skyborn Sanctuary Relief Pad on the Floor
    make3DPart(dais, "SanctuaryPad", Vector3.new(0.56, 4.2, 4.2), CFrame.new(pos.X, floorY + 0.28, pos.Z) * CFrame.Angles(0, 0, math.pi / 2), ivory, Enum.Material.Marble, Enum.PartType.Cylinder, false)
    make3DPart(dais, "SanctuaryGlowRing", Vector3.new(0.60, 3.65, 3.65), CFrame.new(pos.X, floorY + 0.30, pos.Z) * CFrame.Angles(0, 0, math.pi / 2), sapphire, Enum.Material.Neon, Enum.PartType.Cylinder, false)
    make3DPart(dais, "SanctuaryInnerDisc", Vector3.new(0.64, 3.1, 3.1), CFrame.new(pos.X, floorY + 0.32, pos.Z) * CFrame.Angles(0, 0, math.pi / 2), gold, Enum.Material.Metal, Enum.PartType.Cylinder, false)

    -- Orientation facing toward Lumen Plaza center (0, floorY, 0)
    local lookTarget = Vector3.new(0, floorY + 0.64, 0)
    if (Vector3.new(pos.X, 0, pos.Z)).Magnitude < 1 then
        lookTarget = Vector3.new(pos.X, floorY + 0.64, pos.Z + 10)
    end
    local baseCF = CFrame.lookAt(Vector3.new(pos.X, floorY + 0.64, pos.Z), lookTarget)

    -- Twin Rear Sanctuary Lantern Bollards
    for _, side in ipairs({ -1.35, 1.35 }) do
        local postCF = baseCF * CFrame.new(side, 1.15, 1.15)
        make3DPart(dais, "LanternPost_" .. tostring(side), Vector3.new(0.26, 2.3, 0.26), postCF, gold, Enum.Material.Metal, nil, false)
        make3DPart(dais, "LanternOrb_" .. tostring(side), Vector3.new(0.46, 0.46, 0.46), postCF * CFrame.new(0, 1.25, 0), sapphire, Enum.Material.Neon, Enum.PartType.Ball, false)
    end

    -- 2. Rigged 3D Blender Character + Sculpted 3D Citizen Figure inside ActiveNPCs
    local assetMap = {
        Citizen1 = { Asset = "Female_Adventurer", Robe = Color3.fromRGB(58, 128, 212), Hair = Color3.fromRGB(242, 212, 128) },
        Citizen2 = { Asset = "Male_Adventurer", Robe = Color3.fromRGB(42, 92, 168), Hair = Color3.fromRGB(68, 52, 42) },
        Citizen3 = { Asset = "Female_Novice", Robe = Color3.fromRGB(82, 168, 228), Hair = Color3.fromRGB(228, 238, 255) },
    }
    local spec = assetMap[id] or assetMap.Citizen1

    local npcModel = Instance.new("Model")
    npcModel.Name = id .. "_SkybornCitizen"
    npcModel:SetAttribute("NPCId", spec.Asset)
    npcModel:SetAttribute("VisualAsset", spec.Asset)
    npcModel:SetAttribute("NPCFloorY", floorY + 0.64)
    npcModel:SetAttribute("PreserveDaisY", true)
    npcModel:SetAttribute("ShowcaseScale", 2.45)

    local rootPart = make3DPart(npcModel, "Body", Vector3.new(1.8, 4.4, 1.4), baseCF * CFrame.new(0, 2.2, 0), deepNavy, Enum.Material.SmoothPlastic, nil, false, 1)
    npcModel.PrimaryPart = rootPart

    -- Sculpted 3D Citizen Figure (visible in Server/Edit view and before client rig swap)
    local skin = Color3.fromRGB(246, 214, 188)
    make3DPart(npcModel, "Legs", Vector3.new(1.05, 1.65, 0.72), baseCF * CFrame.new(0, 0.85, 0), deepNavy, Enum.Material.SmoothPlastic, nil, false)
    make3DPart(npcModel, "RobeSkirt", Vector3.new(1.42, 1.55, 1.05), baseCF * CFrame.new(0, 1.35, 0), ivory, Enum.Material.SmoothPlastic, nil, false)
    make3DPart(npcModel, "TorsoTunic", Vector3.new(1.38, 1.65, 0.86), baseCF * CFrame.new(0, 2.55, 0), spec.Robe, Enum.Material.SmoothPlastic, nil, false)
    make3DPart(npcModel, "GoldSash", Vector3.new(1.44, 0.32, 0.92), baseCF * CFrame.new(0, 1.95, 0), gold, Enum.Material.Metal, nil, false)
    make3DPart(npcModel, "ShoulderMantle", Vector3.new(1.86, 0.36, 1.02), baseCF * CFrame.new(0, 3.22, 0), gold, Enum.Material.Metal, nil, false)
    make3DPart(npcModel, "LeftArm", Vector3.new(0.44, 1.48, 0.44), baseCF * CFrame.new(-0.92, 2.48, -0.12) * CFrame.Angles(math.rad(18), 0, math.rad(10)), skin, Enum.Material.SmoothPlastic, nil, false)
    make3DPart(npcModel, "RightArm", Vector3.new(0.44, 1.48, 0.44), baseCF * CFrame.new(0.92, 2.48, -0.12) * CFrame.Angles(math.rad(18), 0, math.rad(-10)), skin, Enum.Material.SmoothPlastic, nil, false)
    make3DPart(npcModel, "Head", Vector3.new(1.05, 1.05, 1.05), baseCF * CFrame.new(0, 3.92, 0), skin, Enum.Material.SmoothPlastic, Enum.PartType.Ball, false)
    make3DPart(npcModel, "HairCrown", Vector3.new(1.14, 0.65, 1.14), baseCF * CFrame.new(0, 4.22, 0.06), spec.Hair, Enum.Material.SmoothPlastic, nil, false)
    make3DPart(npcModel, "SkybornHalo", Vector3.new(0.14, 1.35, 1.35), baseCF * CFrame.new(0, 4.78, 0) * CFrame.Angles(0, 0, math.pi / 2), sapphire, Enum.Material.Neon, Enum.PartType.Cylinder, false)

    npcModel.Parent = activeNPCs

    if marker then
        local prompt = marker:FindFirstChildOfClass("ProximityPrompt")
        if prompt then
            prompt.Triggered:Connect(function()
                npcModel:SetAttribute("NPCTalkAt", workspace:GetServerTimeNow())
            end)
        end
    end
    return dais, npcModel
end

local function buildTowerSwitch3D(parent, id, pos, floorY)
    local mdl = Instance.new("Model")
    mdl.Name = id .. "_3DModel"
    mdl.Parent = parent

    local ivory = Color3.fromRGB(228, 224, 210)
    local darkMetal = Color3.fromRGB(32, 42, 64)
    local gold = Color3.fromRGB(242, 196, 78)
    local solarNeon = Color3.fromRGB(255, 212, 84)
    local cyanNeon = Color3.fromRGB(88, 236, 255)

    -- Face toward the center of the Tower / Plaza
    local baseCF = CFrame.lookAt(Vector3.new(pos.X, floorY, pos.Z), Vector3.new(0, floorY, pos.Z))

    -- 1. Stepped Obsidian & Gold Runic Console Base
    make3DPart(mdl, "BaseFoundation", Vector3.new(3.8, 0.48, 3.2), baseCF * CFrame.new(0, 0.24, 0), ivory, Enum.Material.Marble, nil, true)
    make3DPart(mdl, "StepPlinth", Vector3.new(3.1, 0.52, 2.5), baseCF * CFrame.new(0, 0.74, 0), darkMetal, Enum.Material.Metal, nil, true)
    make3DPart(mdl, "GoldBaseTrim", Vector3.new(3.25, 0.16, 2.65), baseCF * CFrame.new(0, 0.52, 0), solarNeon, Enum.Material.Neon, nil, false)

    -- 2. Tilted Solar Astrolabe Control Desk & Mechanical Crystal Lever
    make3DPart(mdl, "ConsoleBody", Vector3.new(1.95, 2.15, 1.45), baseCF * CFrame.new(0, 1.95, 0), darkMetal, Enum.Material.Metal, nil, true)
    make3DPart(mdl, "ConsoleGoldFrame", Vector3.new(2.12, 1.95, 1.25), baseCF * CFrame.new(0, 1.95, 0), gold, Enum.Material.Metal, nil, false)

    local deskSlopeCF = baseCF * CFrame.new(0, 2.95, -0.12) * CFrame.Angles(math.rad(-32), 0, 0)
    make3DPart(mdl, "SlopedControlFace", Vector3.new(1.88, 0.28, 1.48), deskSlopeCF, darkMetal, Enum.Material.Metal, nil, false)
    make3DPart(mdl, "AstrolabeDial", Vector3.new(0.18, 1.12, 1.12), deskSlopeCF * CFrame.new(0, 0.14, 0) * CFrame.Angles(0, 0, math.pi / 2), solarNeon, Enum.Material.Neon, Enum.PartType.Cylinder, false)

    -- Fulcrum Gear & Angled Crystal Lever
    local leverPivotCF = deskSlopeCF * CFrame.new(0, 0.22, 0) * CFrame.Angles(math.rad(28), 0, 0)
    make3DPart(mdl, "LeverFulcrumDrum", Vector3.new(0.55, 0.55, 0.55), deskSlopeCF * CFrame.new(0, 0.18, 0) * CFrame.Angles(0, math.pi / 2, 0), gold, Enum.Material.Metal, Enum.PartType.Cylinder, false)
    make3DPart(mdl, "LeverShaft", Vector3.new(0.22, 1.55, 0.22), leverPivotCF * CFrame.new(0, 0.78, 0), gold, Enum.Material.Metal, nil, false)
    local handlePart = make3DPart(mdl, "LeverCrystalHandle", Vector3.new(1.22, 0.34, 0.34), leverPivotCF * CFrame.new(0, 1.56, 0), cyanNeon, Enum.Material.Neon, nil, false)
    make3DPart(mdl, "LeverHandleCaps", Vector3.new(1.42, 0.24, 0.24), leverPivotCF * CFrame.new(0, 1.56, 0), gold, Enum.Material.Metal, nil, false)

    -- 3. Twin Flanking Resonator Coils & Overhead Solar Ring
    for _, side in ipairs({ -1.25, 1.25 }) do
        local coilCF = baseCF * CFrame.new(side, 2.25, 0.25)
        make3DPart(mdl, "ResonatorPylon_" .. tostring(side), Vector3.new(0.38, 2.8, 0.38), coilCF, darkMetal, Enum.Material.Metal, nil, false)
        for r = 1, 3 do
            make3DPart(mdl, string.format("CoilRing_%s_%d", tostring(side), r), Vector3.new(0.16, 0.68, 0.68), coilCF * CFrame.new(0, -0.65 + (r - 1) * 0.65, 0) * CFrame.Angles(0, 0, math.pi / 2), solarNeon, Enum.Material.Neon, Enum.PartType.Cylinder, false)
        end
        make3DPart(mdl, "PylonTip_" .. tostring(side), Vector3.new(0.46, 0.46, 0.46), coilCF * CFrame.new(0, 1.62, 0), cyanNeon, Enum.Material.Neon, Enum.PartType.Ball, false)
    end

    local pt = Instance.new("PointLight")
    pt.Color = solarNeon
    pt.Range = 13
    pt.Brightness = 1.45
    pt.Parent = handlePart
    return mdl
end

local function buildWaypointBeacon3D(parent, id, pos, floorY, isArena)
    local mdl = Instance.new("Model")
    mdl.Name = id .. "_3DModel"
    mdl.Parent = parent

    local ivory = Color3.fromRGB(234, 228, 212)
    local gold = Color3.fromRGB(242, 196, 78)
    local glowCol = isArena and Color3.fromRGB(255, 198, 68) or Color3.fromRGB(88, 232, 255)

    make3DPart(mdl, "PadBase", Vector3.new(0.56, 5.2, 5.2), CFrame.new(pos.X, floorY + 0.28, pos.Z) * CFrame.Angles(0, 0, math.pi / 2), ivory, Enum.Material.Marble, Enum.PartType.Cylinder, false)
    make3DPart(mdl, "RuneRing", Vector3.new(0.62, 4.4, 4.4), CFrame.new(pos.X, floorY + 0.31, pos.Z) * CFrame.Angles(0, 0, math.pi / 2), glowCol, Enum.Material.Neon, Enum.PartType.Cylinder, false)
    make3DPart(mdl, "InnerCore", Vector3.new(0.66, 3.2, 3.2), CFrame.new(pos.X, floorY + 0.33, pos.Z) * CFrame.Angles(0, 0, math.pi / 2), gold, Enum.Material.Metal, Enum.PartType.Cylinder, false)

    for _, side in ipairs({ -2.15, 2.15 }) do
        make3DPart(mdl, "Obelisk_" .. tostring(side), Vector3.new(0.55, 3.6, 0.55), CFrame.new(pos.X + side, floorY + 1.9, pos.Z), gold, Enum.Material.Metal, nil, false)
        make3DPart(mdl, "ObeliskCrystal_" .. tostring(side), Vector3.new(0.62, 0.85, 0.62), CFrame.new(pos.X + side, floorY + 4.05, pos.Z) * CFrame.Angles(math.rad(45), math.rad(45), 0), glowCol, Enum.Material.Neon, nil, false)
    end
    return mdl
end

local EXPANSION_REALM_RETURN_SPECS = {
    VerdantCrown = { ReturnId = "VerdantReturnHub", DeckY = 166.9 },
    EmberforgeWastes = { ReturnId = "EmberReturnHub", DeckY = 166.5 },
    AbyssalTides = { ReturnId = "AbyssalReturnHub", DeckY = 166.9 },
    ChronosBastion = { ReturnId = "ChronosReturnHub", DeckY = 226.9 },
    VeilsEnd = { ReturnId = "VeilsReturnHub", DeckY = 306.9 },
}

function M.Build(W)
    installBillboardBuilders(W)
    for _,name in {'SkyHub','GoldenSky','GrandSkyIslands_Collision','VerdantCrown','EmberforgeWastes','AbyssalTides','ChronosBastion','VeilsEnd'} do
        local old=workspace:FindFirstChild(name)
        if old then old:Destroy() end
    end
    local hub=Instance.new('Model');hub.Name='SkyHub';hub.Parent=workspace
    local sky=Instance.new('Model');sky.Name='GoldenSky';sky.Parent=workspace;hub:SetAttribute('WorldVersion',5)
    W.Hub=hub;W.Sky=sky;W.Interactions={}
    require(script.Parent.GoldenSkyCollision)(sky)
    for _,name in {'ActiveEnemies','ActiveBosses','SpawnPoints','ActiveNPCs'} do
        if not workspace:FindFirstChild(name) then
            local f=Instance.new('Folder');f.Name=name;f.Parent=workspace
        end
    end
    local activeNPCs = workspace:FindFirstChild('ActiveNPCs')
    for _, oldCitizen in ipairs(activeNPCs:GetChildren()) do
        if string.find(oldCitizen.Name, "_SkybornCitizen") then
            oldCitizen:Destroy()
        end
    end

    local spawn=Instance.new('SpawnLocation');spawn.Name='SkybornSpawn';spawn.Size=Vector3.new(12,1,12);spawn.Position=Vector3.new(-317.4,47.5,527.8)
    spawn.Anchored=true;spawn.Transparency=1;spawn.CanCollide=false;spawn.Neutral=true;spawn.Duration=2;spawn.Parent=hub;W.Spawn=spawn
    local locations={
        Lyra={-298.0,49.0,506.0},Kael={-282.0,49.0,506.0},FrozenPortal={42.0,49.5,-435.0},ReturnHub={28.0,49.5,65.0},
        Station1={-72.0,49.5,55.0},Station2={0.0,49.5,95.0},Station3={72.0,49.5,55.0},
        Citizen1={-80.0,49.5,-18.0},Citizen2={0.0,49.5,-85.0},Citizen3={80.0,49.5,-18.0},
        Switch1={-78.0,49.5,-112.0},Switch2={78.0,49.5,-112.0},ArenaGate={0.0,49.5,-148.0},LeaveArena={54.0,49.5,-285.0},
    }
    local labels={
        Lyra='Lyra • Chỉ Huy Skyborn (Nhiệm Vụ)',
        Kael='Kael • Thợ Rèn Thần Khí (Forge)',
        FrozenPortal='Cổng Sky 2 • Frozen Cyber',
        ReturnHub='Đài Dịch Chuyển • Về Sky Hub',
        Station1='Trạm Năng Lượng Aether I',
        Station2='Trạm Năng Lượng Aether II',
        Station3='Trạm Năng Lượng Aether III',
        Citizen1='Cư Dân Bầu Trời • Elara',
        Citizen2='Cư Dân Bầu Trời • Orion',
        Citizen3='Cư Dân Bầu Trời • Sora',
        Switch1='Công Tắc Tháp Ánh Sáng • Tây',
        Switch2='Công Tắc Tháp Ánh Sáng • Đông',
        ArenaGate='Cổng Đấu Trường Aureon',
        LeaveArena='Rời Đấu Trường Aureon',
    }
    local promptSpecs={
        Station1={Action='Kích Hoạt Trạm Năng Lượng', Object='Trạm Năng Lượng Aether I (Lumen Plaza)', Offset=Vector3.new(0, 4.1, 0)},
        Station2={Action='Kích Hoạt Trạm Năng Lượng', Object='Trạm Năng Lượng Aether II (Lumen Plaza)', Offset=Vector3.new(0, 4.1, 0)},
        Station3={Action='Kích Hoạt Trạm Năng Lượng', Object='Trạm Năng Lượng Aether III (Lumen Plaza)', Offset=Vector3.new(0, 4.1, 0)},
        Citizen1={Action='Giải Cứu & Hộ Tống Cư Dân', Object='Cư Dân Bầu Trời • Elara', Offset=Vector3.new(0, 3.2, 0)},
        Citizen2={Action='Giải Cứu & Hộ Tống Cư Dân', Object='Cư Dân Bầu Trời • Orion', Offset=Vector3.new(0, 3.2, 0)},
        Citizen3={Action='Giải Cứu & Hộ Tống Cư Dân', Object='Cư Dân Bầu Trời • Sora', Offset=Vector3.new(0, 3.2, 0)},
        Switch1={Action='Gạt Công Tắc Mở Cổng Tháp', Object='Công Tắc Tháp Ánh Sáng • Tây', Offset=Vector3.new(0, 2.8, 0)},
        Switch2={Action='Gạt Công Tắc Mở Cổng Tháp', Object='Công Tắc Tháp Ánh Sáng • Đông', Offset=Vector3.new(0, 2.8, 0)},
        ReturnHub={Action='Dịch Chuyển Về Sky Hub', Object='Đài Dịch Chuyển • Sky Hub', Offset=Vector3.new(0, 2.8, 0)},
        ArenaGate={Action='Bước Vào Đấu Trường Boss Aureon', Object='Cổng Đấu Trường Aureon Sentinel', Offset=Vector3.new(0, 3.2, 0)},
        LeaveArena={Action='Rời Khỏi Đấu Trường', Object='Lối Ra Đấu Trường Aureon', Offset=Vector3.new(0, 2.8, 0)},
        FrozenPortal={Action='Dịch Chuyển Sang Sky 2', Object='Cổng Sky 2 • Frozen Cyber', Offset=Vector3.new(0, 4.2, 0)},
    }
    for id,pos in locations do
        local vpos = Vector3.new(table.unpack(pos))
        local marker=W.Interactable((id=='Lyra' or id=='Kael') and hub or sky,id,vpos,labels[id]or id)
        marker.Transparency=1
        if id=='Lyra' or id=='Kael' or id=='FrozenPortal' then
            for _,ch in ipairs(marker:GetChildren()) do
                if ch:IsA("BillboardGui") or ch:IsA("ProximityPrompt") then
                    ch:Destroy()
                end
            end
        else
            local pSpec = promptSpecs[id]
            if pSpec then
                local pr = marker:FindFirstChildOfClass("ProximityPrompt")
                if pr then
                    pr.ActionText = pSpec.Action
                    pr.ObjectText = pSpec.Object
                end
                local bg = marker:FindFirstChildOfClass("BillboardGui")
                if bg and pSpec.Offset then
                    bg.StudsOffset = pSpec.Offset
                end
            end
            local floorY = 46.5
            if string.sub(id, 1, 7) == 'Station' then
                buildAetherStation3D(sky, id, vpos, floorY)
            elseif string.sub(id, 1, 7) == 'Citizen' then
                buildSkybornCitizen3D(sky, activeNPCs, id, vpos, floorY, marker)
            elseif string.sub(id, 1, 6) == 'Switch' then
                buildTowerSwitch3D(sky, id, vpos, floorY)
            elseif id == 'ReturnHub' or id == 'ArenaGate' or id == 'LeaveArena' then
                buildWaypointBeacon3D(sky, id, vpos, floorY, id == 'ArenaGate')
            end
        end
    end
    local floors={sky.GoldenSky_Collision}

    if game.ReplicatedStorage.DelegatedV5Sources:FindFirstChild('FrozenCyber') then
        local origin=require(game.ReplicatedStorage.Shared.RealmConfig).FrozenCyber.Origin
        local oldF=workspace:FindFirstChild('FrozenCyber')
        if oldF then oldF:Destroy() end
        local frozen=Instance.new('Model');frozen.Name='FrozenCyber';frozen.Parent=workspace
        local collision=require(script.Parent.FrozenCyberCollision)(frozen)
        collision=collision or frozen.FrozenCyber_Collision
        for _,o in collision:GetDescendants() do
            if o:IsA('BasePart') and (o.Position - origin).Magnitude > 6000 then
                o.CFrame=CFrame.new(origin)*o.CFrame
            end
        end
        table.insert(floors,collision)
        local frHubPos = Vector3.new(11598.0, 49.9, 516.0)
        local frHub=W.Interactable(frozen,'FrozenReturnHub',frHubPos,'Đài Dịch Chuyển • Về Golden Sky')
        if frHub then frHub.Transparency=1 end
        buildWaypointBeacon3D(frozen, 'FrozenReturnHub', frHubPos, 46.9, false)
        local shPortalPos = Vector3.new(12610.0, 49.9, -475.0)
        local shPortal=W.Interactable(frozen,'ShadowPortal',shPortalPos,'Cổng Sky 3 • Shadow Realm')
        if shPortal then
            shPortal.Transparency=1
            for _,ch in ipairs(shPortal:GetChildren()) do
                if ch:IsA("BillboardGui") or ch:IsA("ProximityPrompt") then
                    ch:Destroy()
                end
            end
        end
    end
    if game.ReplicatedStorage.DelegatedV5Sources:FindFirstChild('ShadowRealm')then
        local origin=require(game.ReplicatedStorage.Shared.RealmConfig).ShadowRealm.Origin
        local oldS=workspace:FindFirstChild('ShadowRealm')
        if oldS then oldS:Destroy() end
        local shadow=Instance.new('Model');shadow.Name='ShadowRealm';shadow.Parent=workspace
        require(script.Parent.ShadowRealmCollision)(shadow)
        local collision=shadow.ShadowRealm_Collision
        for _,o in collision:GetDescendants()do
            if o:IsA('BasePart') and (o.Position - origin).Magnitude > 6000 then
                o.CFrame=CFrame.new(origin)*o.CFrame
            end
        end
        table.insert(floors,collision)
        local shRetPos = Vector3.new(-12568.0, 49.9, 395.0)
        local shRet=W.Interactable(shadow,'ShadowReturnHub',shRetPos,'Đài Dịch Chuyển • Về Golden Sky')
        if shRet then shRet.Transparency=1 end
        buildWaypointBeacon3D(shadow, 'ShadowReturnHub', shRetPos, 46.9, false)
    end

    local realmCfg = require(game.ReplicatedStorage.Shared.RealmConfig)
    for _, expName in ipairs({'VerdantCrown', 'EmberforgeWastes', 'AbyssalTides', 'ChronosBastion', 'VeilsEnd'}) do
        local spec = EXPANSION_REALM_RETURN_SPECS[expName]
        local rEntry = realmCfg[expName]
        if spec and rEntry then
            local oldExp = workspace:FindFirstChild(expName)
            if oldExp then oldExp:Destroy() end
            local expModel = Instance.new('Model')
            expModel.Name = expName
            expModel.Parent = workspace
            local colFolder = Instance.new('Folder')
            colFolder.Name = expName .. '_Collision'
            colFolder.Parent = expModel
            table.insert(floors, colFolder)

            local retPos = Vector3.new(rEntry.Spawn.X - 28, spec.DeckY + 3.0, rEntry.Spawn.Z - 24)
            local retMarker = W.Interactable(expModel, spec.ReturnId, retPos, 'Đài Dịch Chuyển • Về Golden Sky')
            if retMarker then retMarker.Transparency = 1 end
            buildWaypointBeacon3D(expModel, spec.ReturnId, retPos, spec.DeckY, false)
        end
    end

    -- Build Solid3DWorldColliders AFTER all 8 Realms exist so smooth stair ramps (#122) cover Realms 1-8
    local solid3D = nil
    if script.Parent:FindFirstChild('Solid3DWorldColliders') then
        local ok, mod = pcall(require, script.Parent.Solid3DWorldColliders)
        if ok and mod then
            solid3D = mod
            pcall(mod.Build)
        end
    end

    local islandColFolder = workspace:FindFirstChild("GrandSkyIslands_Collision")
    if not islandColFolder then
        islandColFolder = Instance.new("Folder")
        islandColFolder.Name = "GrandSkyIslands_Collision"
        islandColFolder.Parent = workspace
    end
    table.insert(floors, islandColFolder)

    -- Keep vertical Guardrail / Rail walls physically collidable while excluding them from ground raycasts,
    -- and filter by live collision Folders so dynamic Raid / Spire / Mirage / Colosseum platforms are raycastable!
    for _, f in ipairs(floors) do
        for _, o in ipairs(f:GetDescendants()) do
            if o:IsA("BasePart") and (string.find(o.Name, "Guardrail") or string.find(o.Name, "_Rail")) then
                o.CanQuery = false
            end
        end
    end

    local params=RaycastParams.new()
    params.FilterType=Enum.RaycastFilterType.Include
    params.FilterDescendantsInstances=floors
    params.IgnoreWater=true

    function W.IsBlockedByObstacle(x, y, z, clear)
        if solid3D and solid3D.IsBlockedByMainBox and solid3D.IsBlockedByMainBox(x, y, z, clear or 3.5) then
            return true
        end
        return false
    end

    function W.RaycastGround(pos, refFloorY)
        local baseRef = refFloorY or pos.Y
        local originY = math.max(pos.Y, baseRef) + 220
        local hit = workspace:Raycast(Vector3.new(pos.X, originY, pos.Z), Vector3.new(0, -550, 0), params)
        if hit and hit.Instance and (not hit.Instance.CanCollide or string.find(hit.Instance.Name, "Guardrail") or string.find(hit.Instance.Name, "_Rail")) then
            return nil
        end
        return hit
    end

    function W.GroundY(pos, refFloorY)
        local hit = W.RaycastGround(pos, refFloorY)
        if hit then
            return hit.Position.Y
        end
        return refFloorY or (pos.Y - 2.5)
    end

    local function isSafeOpenSpot(x, z, refY)
        local hit = W.RaycastGround(Vector3.new(x, refY + 12, z), refY)
        if not hit or not hit.Instance or not hit.Instance.CanCollide or hit.Position.Y <= 12 then
            return false, nil
        end
        local fy = hit.Position.Y
        if W.IsBlockedByObstacle(x, fy, z, 3.8) then
            return false, nil
        end
        for _, off in ipairs({{3.2, 0}, {-3.2, 0}, {0, 3.2}, {0, -3.2}}) do
            local nh = W.RaycastGround(Vector3.new(x + off[1], fy + 8, z + off[2]), fy)
            if not nh or math.abs(nh.Position.Y - fy) > 3.5 then
                return false, nil
            end
        end
        return true, fy
    end

    function W.SnapToOpenGround(pos, refFloorY, heightOffset)
        local hOff = tonumber(heightOffset) or 0
        if solid3D and solid3D.SnapToOpenGround then
            local snappedPos, snappedFY, matchedIsland = solid3D.SnapToOpenGround(pos, refFloorY, hOff, 3.2)
            if matchedIsland then
                local hit = W.RaycastGround(snappedPos, snappedFY)
                if hit then
                    snappedFY = hit.Position.Y
                end
                return Vector3.new(snappedPos.X, snappedFY + hOff, snappedPos.Z), snappedFY
            end
        end

        local okSpot, spotFY = isSafeOpenSpot(pos.X, pos.Z, refFloorY or pos.Y)
        if okSpot and spotFY then
            return Vector3.new(pos.X, spotFY + hOff, pos.Z), spotFY
        end

        local hit = W.RaycastGround(pos, refFloorY)
        local targetPart = hit and hit.Instance or nil
        if not targetPart or not targetPart:IsA("BasePart") then
            local bestPart, bestD2 = nil, math.huge
            for _, f in ipairs(floors) do
                for _, o in ipairs(f:GetDescendants()) do
                    if o:IsA("BasePart") and o.CanCollide and o.CanQuery then
                        local isDeck = (o:IsA("Part") and o.Shape == Enum.PartType.Cylinder and o.Size.Y >= 18) or (o.Size.X >= 10 and o.Size.Z >= 10)
                        if isDeck then
                            local dx = pos.X - o.Position.X
                            local dz = pos.Z - o.Position.Z
                            local d2 = dx * dx + dz * dz
                            if d2 < bestD2 then
                                bestD2 = d2
                                bestPart = o
                            end
                        end
                    end
                end
            end
            targetPart = bestPart
        end

        if targetPart then
            local c = targetPart.Position
            local bestX, bestZ, bestFY, bestD2 = c.X, c.Z, c.Y + 1.0, math.huge
            local foundSafe = false
            -- Check candidate points in concentric rings around the deck center
            for _, r in ipairs({0, 5, 10, 15, 20}) do
                local steps = (r == 0) and 1 or 12
                for s = 1, steps do
                    local ang = (s - 1) * (2 * math.pi / steps)
                    local tx = c.X + math.cos(ang) * r
                    local tz = c.Z + math.sin(ang) * r
                    local d2 = (tx - pos.X)^2 + (tz - pos.Z)^2
                    if d2 < bestD2 then
                        local safe, fy = isSafeOpenSpot(tx, tz, c.Y)
                        if safe and fy then
                            bestD2 = d2
                            bestX, bestZ, bestFY = tx, tz, fy
                            foundSafe = true
                        end
                    end
                end
            end
            if not foundSafe then
                local ch = W.RaycastGround(Vector3.new(c.X, c.Y + 12, c.Z), c.Y)
                bestFY = ch and ch.Position.Y or (c.Y + 1.0)
            end
            return Vector3.new(bestX, bestFY + hOff, bestZ), bestFY
        end

        local spawnPos = (W.Spawn and W.Spawn.Position) or Vector3.new(-317.4, 50.5, 527.8)
        local gy = W.GroundY(spawnPos, 46.5)
        return Vector3.new(spawnPos.X, gy + hOff, spawnPos.Z), gy
    end
    workspace:SetAttribute('WorldArtVersion',8)
end
return M
