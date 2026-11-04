-- SKYBREAK: Fragments of the Core - Standalone World Atmosphere, Cloud Sea, Quest Beacon,
-- Animated Chests, Living Town NPCs, Nebula Transitions, Server Overlays & Studio Dev Sandbox
-- Tasks: #25, #26, #65, #77, #116, #117, #121, #128, #129

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ============================================================================
-- 0. BALANCED HDR BLOOM & LIGHTING LOCK FOR VFX STUDIO NEON & PARTICLES
-- ============================================================================
local lightingGuardBusy = false

local function enforceAntiGlareLock()
    if lightingGuardBusy then
        return
    end
    lightingGuardBusy = true
    if Lighting.Brightness > 2.25 then
        Lighting.Brightness = 1.95
    end
    if Lighting.ExposureCompensation > 0.14 or Lighting.ExposureCompensation < -0.12 then
        Lighting.ExposureCompensation = 0.04
    end
    local foundBloom = false
    local foundGrade = false
    for _, child in ipairs(Lighting:GetChildren()) do
        if child:IsA("BloomEffect") then
            foundBloom = true
            child.Enabled = true
            child.Intensity = math.clamp(child.Intensity, 0.48, 0.68)
            child.Threshold = math.clamp(child.Threshold, 0.86, 0.96)
            child.Size = math.clamp(child.Size, 26, 36)
        elseif child:IsA("ColorCorrectionEffect") and (child.Name == "SkybreakGrade" or child.Name == "SkybreakColorGrade") then
            foundGrade = true
            child.Enabled = true
            child.Saturation = math.clamp(math.max(child.Saturation, 0.26), 0.22, 0.34)
            child.Contrast = math.clamp(math.max(child.Contrast, 0.14), 0.10, 0.22)
        elseif child:IsA("Atmosphere") then
            if child.Glare > 0.10 then
                child.Glare = 0.08
            end
        end
    end
    if not foundBloom then
        local bl = Instance.new("BloomEffect")
        bl.Name = "SkybreakVFXBloom"
        bl.Enabled = true
        bl.Intensity = 0.58
        bl.Threshold = 0.88
        bl.Size = 28
        bl.Parent = Lighting
    end
    if not foundGrade then
        local gr = Instance.new("ColorCorrectionEffect")
        gr.Name = "SkybreakGrade"
        gr.Enabled = true
        gr.Brightness = 0.03
        gr.Contrast = 0.14
        gr.Saturation = 0.26
        gr.TintColor = Color3.fromRGB(255, 250, 242)
        gr.Parent = Lighting
    end
    lightingGuardBusy = false
end

enforceAntiGlareLock()
Lighting:GetPropertyChangedSignal("Brightness"):Connect(enforceAntiGlareLock)
Lighting:GetPropertyChangedSignal("ExposureCompensation"):Connect(enforceAntiGlareLock)
Lighting.ChildAdded:Connect(function(ch)
    if ch:IsA("BloomEffect") or ch:IsA("Atmosphere") then
        task.defer(enforceAntiGlareLock)
    end
end)

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")
local SharedFolder = ReplicatedStorage:WaitForChild("Shared")
local Config = require(SharedFolder:WaitForChild("Config"))
local CombatDataOk, CombatData = pcall(function()
    return require(SharedFolder:WaitForChild("SkybreakCombatData", 5))
end)
local AudioOk, AudioEngine = pcall(function()
    return require(script.Parent:WaitForChild("SkybreakAudioEngine", 5))
end)

local function playSFX(id, pos, jitter)
    if AudioOk and AudioEngine and type(AudioEngine.PlaySFX) == "function" then
        pcall(AudioEngine.PlaySFX, id, pos, jitter)
    end
end

local function ensureTempFX()
    local f = workspace:FindFirstChild("TempFX")
    if not f then
        f = Instance.new("Folder")
        f.Name = "TempFX"
        f.Parent = workspace
    end
    return f
end

local function isLowFX()
    if localPlayer and localPlayer:GetAttribute("LowFXMode") == true then
        return true
    end
    return workspace:GetAttribute("LowFXMode") == true
end

-- Sanitize any stray baked astral-plane emojis (>= 0x1F300) if present in legacy place instances
local function stripAstralEmojis(str)
    if type(str) ~= "string" or str == "" then
        return str, false
    end
    local changed = false
    local out = {}
    local ok = pcall(function()
        for _, cp in utf8.codes(str) do
            if cp >= 0x1F300 then
                changed = true
            else
                table.insert(out, utf8.char(cp))
            end
        end
    end)
    if ok and changed then
        local cleaned = table.concat(out):gsub("^%s+", "")
        return cleaned, true
    end
    return str, false
end

local function sanitizeInstanceEmojis(inst)
    if inst:IsA("ProximityPrompt") then
        local a, ca = stripAstralEmojis(inst.ActionText)
        if ca then
            inst.ActionText = a
        end
        local o, co = stripAstralEmojis(inst.ObjectText)
        if co then
            inst.ObjectText = o
        end
    elseif inst:IsA("TextLabel") or inst:IsA("TextButton") then
        local t, ct = stripAstralEmojis(inst.Text)
        if ct then
            inst.Text = t
        end
    end
end

task.spawn(function()
    for idx, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") or ((d:IsA("TextLabel") or d:IsA("TextButton")) and d:FindFirstAncestorWhichIsA("BillboardGui")) then
            sanitizeInstanceEmojis(d)
        end
        if idx % 250 == 0 then
            task.wait()
        end
    end
    for idx, d in ipairs(playerGui:GetDescendants()) do
        sanitizeInstanceEmojis(d)
        if idx % 200 == 0 then
            task.wait()
        end
    end
    workspace.DescendantAdded:Connect(function(d)
        if d:IsA("ProximityPrompt") or d:IsA("TextLabel") or d:IsA("TextButton") then
            task.defer(sanitizeInstanceEmojis, d)
        end
    end)
    playerGui.DescendantAdded:Connect(function(d)
        if d:IsA("TextLabel") or d:IsA("TextButton") then
            task.defer(sanitizeInstanceEmojis, d)
        end
    end)
end)

-- ============================================================================
-- 1. #25 SMOOTH ANTI-GLARE DAY / SUNSET / NEBULA NIGHT CYCLE & WEATHER PARTICLES
-- ~12-minute synchronized server cycle:
-- Binh Minh -> Ban Ngay -> Hoang Hon Vang Kim -> Dem Tinh Van
-- ============================================================================
local DAY_CYCLE_SECONDS = 720.0
local devTimeOffsetSec = 0

local TIME_KEYFRAMES = {
    {
        U = 0.00,
        Tag = "[BÌNH MINH]",
        Name = "Bình Minh",
        Clock = 7.20,
        Brightness = 1.65,
        Exposure = 0.02,
        Ambient = Color3.fromRGB(128, 124, 148),
        Outdoor = Color3.fromRGB(176, 164, 186),
        ShiftTop = Color3.fromRGB(255, 212, 176),
        AtmoColor = Color3.fromRGB(232, 212, 224),
        AtmoDecay = Color3.fromRGB(218, 174, 162),
        CloudUpper = Color3.fromRGB(242, 224, 228),
        CloudMid = Color3.fromRGB(196, 186, 218),
        CloudDeep = Color3.fromRGB(118, 146, 204),
    },
    {
        U = 0.26,
        Tag = "[BAN NGÀY]",
        Name = "Ban Ngày",
        Clock = 13.50,
        Brightness = 1.95,
        Exposure = 0.04,
        Ambient = Color3.fromRGB(138, 148, 168),
        Outdoor = Color3.fromRGB(182, 192, 214),
        ShiftTop = Color3.fromRGB(255, 248, 232),
        AtmoColor = Color3.fromRGB(185, 224, 255),
        AtmoDecay = Color3.fromRGB(235, 215, 185),
        CloudUpper = Color3.fromRGB(238, 246, 255),
        CloudMid = Color3.fromRGB(168, 208, 248),
        CloudDeep = Color3.fromRGB(78, 148, 224),
    },
    {
        U = 0.56,
        Tag = "[HOÀNG HÔN]",
        Name = "Hoàng Hôn Vàng Kim",
        Clock = 17.35,
        Brightness = 1.68,
        Exposure = 0.02,
        Ambient = Color3.fromRGB(142, 114, 126),
        Outdoor = Color3.fromRGB(192, 148, 132),
        ShiftTop = Color3.fromRGB(255, 192, 128),
        AtmoColor = Color3.fromRGB(242, 192, 158),
        AtmoDecay = Color3.fromRGB(198, 128, 116),
        CloudUpper = Color3.fromRGB(246, 204, 176),
        CloudMid = Color3.fromRGB(198, 154, 164),
        CloudDeep = Color3.fromRGB(112, 104, 158),
    },
    {
        U = 0.78,
        Tag = "[ĐÊM TINH VÂN]",
        Name = "Đêm Tinh Vân",
        Clock = 21.50,
        Brightness = 1.38,
        Exposure = 0.00,
        Ambient = Color3.fromRGB(96, 112, 156),
        Outdoor = Color3.fromRGB(132, 152, 204),
        ShiftTop = Color3.fromRGB(164, 188, 255),
        AtmoColor = Color3.fromRGB(122, 148, 212),
        AtmoDecay = Color3.fromRGB(82, 104, 168),
        CloudUpper = Color3.fromRGB(134, 162, 224),
        CloudMid = Color3.fromRGB(92, 124, 192),
        CloudDeep = Color3.fromRGB(54, 84, 152),
    },
}

local REALM_ATMOSPHERE_BIAS = {
    GoldenSky = { Tint = Color3.fromRGB(255, 242, 212), Sea = 1, Blend = 0.22 },
    VerdantCrown = { Tint = Color3.fromRGB(204, 248, 218), Sea = 1, Blend = 0.24 },
    ChronosBastion = { Tint = Color3.fromRGB(234, 224, 252), Sea = 1, Blend = 0.22 },
    FrozenCyber = { Tint = Color3.fromRGB(176, 228, 255), Sea = 2, Blend = 0.32 },
    AbyssalTides = { Tint = Color3.fromRGB(158, 222, 252), Sea = 2, Blend = 0.32 },
    ShadowRealm = { Tint = Color3.fromRGB(204, 142, 238), Sea = 3, Blend = 0.34 },
    EmberforgeWastes = { Tint = Color3.fromRGB(246, 164, 138), Sea = 3, Blend = 0.32 },
    VeilsEnd = { Tint = Color3.fromRGB(194, 146, 244), Sea = 3, Blend = 0.34 },
}

local function smoothAlpha(t)
    t = math.clamp(t, 0, 1)
    return t * t * (3 - 2 * t)
end

local function lerpClockTime(c1, c2, alpha)
    local diff = c2 - c1
    if diff < -12 then
        diff += 24
    elseif diff > 12 then
        diff -= 24
    end
    return (c1 + diff * alpha) % 24
end

local currentPhaseTag = "[BAN NGÀY]"
local currentCloudColors = {
    Upper = TIME_KEYFRAMES[2].CloudUpper,
    Mid = TIME_KEYFRAMES[2].CloudMid,
    Deep = TIME_KEYFRAMES[2].CloudDeep,
}

local function sampleTimeCycle()
    local extraOffset = tonumber(workspace:GetAttribute("DevClockOffset")) or 0
    local u = 0.26
    if devTimeOffsetSec ~= 0 or extraOffset ~= 0 then
        u = ((0.26 * DAY_CYCLE_SECONDS + devTimeOffsetSec + extraOffset) % DAY_CYCLE_SECONDS) / DAY_CYCLE_SECONDS
    end

    local k1 = TIME_KEYFRAMES[#TIME_KEYFRAMES]
    local k2 = TIME_KEYFRAMES[1]
    local span = (1.0 - k1.U) + k2.U
    local localU = (u >= k1.U) and (u - k1.U) or (u + (1.0 - k1.U))

    for i = 1, #TIME_KEYFRAMES do
        local a = TIME_KEYFRAMES[i]
        local b = TIME_KEYFRAMES[i + 1]
        if b and u >= a.U and u < b.U then
            k1 = a
            k2 = b
            span = b.U - a.U
            localU = u - a.U
            break
        end
    end

    local alpha = smoothAlpha(span > 0.0001 and (localU / span) or 0)
    local activePhase = (alpha < 0.5) and k1 or k2
    return {
        Tag = activePhase.Tag,
        Name = activePhase.Name,
        Clock = lerpClockTime(k1.Clock, k2.Clock, alpha),
        Brightness = k1.Brightness + (k2.Brightness - k1.Brightness) * alpha,
        Exposure = k1.Exposure + (k2.Exposure - k1.Exposure) * alpha,
        Ambient = k1.Ambient:Lerp(k2.Ambient, alpha),
        Outdoor = k1.Outdoor:Lerp(k2.Outdoor, alpha),
        ShiftTop = k1.ShiftTop:Lerp(k2.ShiftTop, alpha),
        AtmoColor = k1.AtmoColor:Lerp(k2.AtmoColor, alpha),
        AtmoDecay = k1.AtmoDecay:Lerp(k2.AtmoDecay, alpha),
        CloudUpper = k1.CloudUpper:Lerp(k2.CloudUpper, alpha),
        CloudMid = k1.CloudMid:Lerp(k2.CloudMid, alpha),
        CloudDeep = k1.CloudDeep:Lerp(k2.CloudDeep, alpha),
    }
end

local weatherBox = nil
local weatherEmitters = {}

local function ensureWeatherVolume()
    if weatherBox and weatherBox.Parent then
        return weatherBox
    end
    local tfx = ensureTempFX()
    weatherBox = tfx:FindFirstChild("SkybreakRegionalWeatherEmitter")
    if not weatherBox then
        weatherBox = Instance.new("Part")
        weatherBox.Name = "SkybreakRegionalWeatherEmitter"
        weatherBox.Size = Vector3.new(96, 36, 96)
        weatherBox.Transparency = 1
        weatherBox.Anchored = true
        weatherBox.CanCollide = false
        weatherBox.CanQuery = false
        weatherBox.CanTouch = false
        weatherBox.CastShadow = false
        weatherBox.Massless = true
        weatherBox.Parent = tfx
    end

    local function makeEmitter(name, colorSeq, sizeNum, lifetimeRange, speedRange, accelVec, lightEmit)
        local pe = weatherBox:FindFirstChild(name)
        if not pe then
            pe = Instance.new("ParticleEmitter")
            pe.Name = name
            pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
            pe.Color = colorSeq
            pe.Size = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(0.25, sizeNum),
                NumberSequenceKeypoint.new(0.8, sizeNum * 0.85),
                NumberSequenceKeypoint.new(1, 0),
            })
            pe.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.2, 0.32),
                NumberSequenceKeypoint.new(0.8, 0.42),
                NumberSequenceKeypoint.new(1, 1),
            })
            pe.Lifetime = lifetimeRange
            pe.Speed = speedRange
            pe.SpreadAngle = Vector2.new(180, 35)
            pe.Acceleration = accelVec
            pe.LightEmission = lightEmit
            pe.LightInfluence = 0.45
            pe.LockedToPart = false
            pe.Enabled = false
            pe.Rate = 0
            pe.Parent = weatherBox
        end
        return pe
    end

    weatherEmitters.Sea1 = makeEmitter(
        "AetherPollenEmitter",
        ColorSequence.new(Color3.fromRGB(245, 208, 118), Color3.fromRGB(238, 226, 174)),
        0.24,
        NumberRange.new(4.2, 6.5),
        NumberRange.new(0.8, 2.2),
        Vector3.new(0.4, 0.18, 0.25),
        0.30
    )
    weatherEmitters.Sea2 = makeEmitter(
        "CyberSnowEmitter",
        ColorSequence.new(Color3.fromRGB(164, 232, 255), Color3.fromRGB(215, 245, 255)),
        0.22,
        NumberRange.new(3.6, 5.4),
        NumberRange.new(2.2, 4.6),
        Vector3.new(-1.2, -2.6, 0.6),
        0.24
    )
    weatherEmitters.Sea3 = makeEmitter(
        "AbyssalEmberEmitter",
        ColorSequence.new(Color3.fromRGB(228, 66, 114), Color3.fromRGB(162, 82, 244)),
        0.25,
        NumberRange.new(3.4, 5.2),
        NumberRange.new(1.5, 3.4),
        Vector3.new(0.5, 2.4, -0.4),
        0.38
    )

    return weatherBox
end

local function stepAtmosphereAndWeather(camPos)
    local sample = sampleTimeCycle()
    local realm = tostring((localPlayer and localPlayer:GetAttribute("CurrentRealm")) or Lighting:GetAttribute("SkybreakEnvironment") or "GoldenSky")
    if realm == "SkyHub" or realm == "" then
        realm = "GoldenSky"
    end
    local rBias = REALM_ATMOSPHERE_BIAS[realm] or REALM_ATMOSPHERE_BIAS.GoldenSky
    local blend = rBias.Blend

    lightingGuardBusy = true
    Lighting.ClockTime = sample.Clock
    -- Vibrant sunlit HDR lighting & ColorCorrection for 3D World & VFX Studio
    Lighting.Brightness = math.clamp(sample.Brightness, 1.35, 2.15)
    Lighting.ExposureCompensation = math.clamp(sample.Exposure, -0.02, 0.08)
    Lighting.Ambient = sample.Ambient:Lerp(rBias.Tint, blend * 0.35)
    Lighting.OutdoorAmbient = sample.Outdoor:Lerp(rBias.Tint, blend * 0.45)
    Lighting.ColorShift_Top = sample.ShiftTop:Lerp(rBias.Tint, blend * 0.40)

    local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmo then
        atmo.Color = sample.AtmoColor:Lerp(rBias.Tint, blend * 0.55)
        atmo.Decay = sample.AtmoDecay:Lerp(rBias.Tint, blend * 0.45)
        atmo.Glare = math.min(atmo.Glare, 0.08)
        atmo.Haze = math.min(atmo.Haze, 0.16)
        Lighting.FogColor = atmo.Color
    end

    for _, child in ipairs(Lighting:GetChildren()) do
        if child:IsA("BloomEffect") then
            child.Enabled = true
            child.Intensity = math.clamp(child.Intensity, 0.52, 0.68)
            child.Threshold = math.clamp(child.Threshold, 0.86, 0.94)
            child.Size = math.clamp(child.Size, 26, 34)
        elseif child:IsA("ColorCorrectionEffect") and (child.Name == "SkybreakGrade" or child.Name == "SkybreakColorGrade") then
            child.Enabled = true
            child.Saturation = 0.26
            child.Contrast = 0.14
            child.Brightness = 0.03
        end
    end
    lightingGuardBusy = false

    currentPhaseTag = sample.Tag
    currentCloudColors.Upper = sample.CloudUpper:Lerp(rBias.Tint, blend * 0.30)
    currentCloudColors.Mid = sample.CloudMid:Lerp(rBias.Tint, blend * 0.32)
    currentCloudColors.Deep = sample.CloudDeep:Lerp(rBias.Tint, blend * 0.25)

    if Lighting:GetAttribute("SkybreakTimePhase") ~= sample.Tag then
        Lighting:SetAttribute("SkybreakTimePhase", sample.Tag)
    end

    local wVol = ensureWeatherVolume()
    if camPos then
        wVol.Position = camPos + Vector3.new(0, 10, 0)
    end
    local low = isLowFX()
    local activeSea = rBias.Sea or 1
    for seaIdx, key in ipairs({ "Sea1", "Sea2", "Sea3" }) do
        local pe = weatherEmitters[key]
        if pe then
            local shouldEnable = (not low) and (activeSea == seaIdx)
            pe.Enabled = shouldEnable
            pe.Rate = shouldEnable and ((seaIdx == 2 and 26) or 20) or 0
        end
    end
end

-- ============================================================================
-- 2. #121 DYNAMIC MULTI-LAYER CLOUD SEA BLANKET (Y < -15) & SKY-GEYSER RESCUE VFX
-- ============================================================================
local cloudSeaRoot = nil
local cloudUpperPads = {}
local cloudMidPads = {}
local cloudHorizonBanks = {}
local cloudMidSheets = {}
local cloudDeepSheets = {}
local CLOUD_TILE_OFFSETS = {
    Vector3.new(-860, 0, -860),
    Vector3.new(860, 0, -860),
    Vector3.new(-860, 0, 860),
    Vector3.new(860, 0, 860),
}

local UPPER_OFFSETS = {
    { x = -280, z = -240, r = 210, y = -18.0, t = 0.34, sx = 1.0, sz = 0.8 },
    { x = 220, z = -290, r = 240, y = -19.2, t = 0.36, sx = 0.9, sz = 1.1 },
    { x = -340, z = 190, r = 230, y = -18.6, t = 0.32, sx = 1.1, sz = 0.9 },
    { x = 290, z = 230, r = 250, y = -19.8, t = 0.35, sx = 0.85, sz = 1.05 },
    { x = -40, z = -30, r = 260, y = -20.4, t = 0.38, sx = 1.05, sz = 0.95 },
    { x = -540, z = -40, r = 290, y = -21.0, t = 0.34, sx = 1.0, sz = 1.0 },
    { x = 520, z = -20, r = 285, y = -21.2, t = 0.34, sx = 1.0, sz = 1.0 },
    { x = 20, z = 510, r = 300, y = -21.5, t = 0.35, sx = 1.1, sz = 0.9 },
}

local MID_OFFSETS = {
    { x = -420, z = -420, r = 380, y = -30.5, t = 0.24 },
    { x = 440, z = -390, r = 410, y = -31.2, t = 0.24 },
    { x = -410, z = 430, r = 395, y = -30.8, t = 0.22 },
    { x = 430, z = 410, r = 420, y = -31.5, t = 0.25 },
}

local function makeCloudPart(parent, name, size, shape, transparency)
    local p = Instance.new("Part")
    p.Name = name
    p.Shape = shape or Enum.PartType.Block
    p.Size = size
    p.Material = Enum.Material.SmoothPlastic
    p.Reflectance = 0
    p.Transparency = transparency
    p.Color = currentCloudColors.Upper
    p.Anchored = true
    p.CanCollide = false
    p.CanQuery = false
    p.CanTouch = false
    p.CastShadow = false
    p.Massless = true
    p.Parent = parent
    return p
end

local function ensureCloudSea()
    if cloudSeaRoot and cloudSeaRoot.Parent then
        return
    end
    local tfx = ensureTempFX()
    cloudSeaRoot = tfx:FindFirstChild("SkybreakCloudSeaBlanket")
    if cloudSeaRoot then
        cloudSeaRoot:Destroy()
    end
    cloudSeaRoot = Instance.new("Folder")
    cloudSeaRoot.Name = "SkybreakCloudSeaBlanket"
    cloudSeaRoot.Parent = tfx

    table.clear(cloudUpperPads)
    table.clear(cloudMidPads)
    table.clear(cloudHorizonBanks)
    table.clear(cloudMidSheets)
    table.clear(cloudDeepSheets)

    for idx, spec in ipairs(UPPER_OFFSETS) do
        local cyl = makeCloudPart(
            cloudSeaRoot,
            "CloudStratum1_" .. idx,
            Vector3.new(3.2, spec.r, spec.r),
            Enum.PartType.Cylinder,
            spec.t
        )
        cloudUpperPads[idx] = { Part = cyl, Spec = spec }
    end

    for idx, spec in ipairs(MID_OFFSETS) do
        local cyl = makeCloudPart(
            cloudSeaRoot,
            "CloudStratum2_Ridge_" .. idx,
            Vector3.new(4.4, spec.r, spec.r),
            Enum.PartType.Cylinder,
            spec.t
        )
        cloudMidPads[idx] = { Part = cyl, Spec = spec }
    end

    for tIdx = 1, #CLOUD_TILE_OFFSETS do
        cloudMidSheets[tIdx] = makeCloudPart(cloudSeaRoot, "CloudStratum2_SeaSheet_" .. tIdx, Vector3.new(1720, 2.6, 1720), Enum.PartType.Block, 0.16)
        cloudDeepSheets[tIdx] = makeCloudPart(cloudSeaRoot, "CloudStratum3_AbyssFloor_" .. tIdx, Vector3.new(1720, 4.0, 1720), Enum.PartType.Block, 0.02)
    end

    for i = 1, 8 do
        local bank = makeCloudPart(
            cloudSeaRoot,
            "HorizonCloudShelf_" .. i,
            Vector3.new(28, 760, 220),
            Enum.PartType.Cylinder,
            0.22
        )
        cloudHorizonBanks[i] = bank
    end
end

local function stepCloudSea(camPos, now)
    if not camPos then
        return
    end
    ensureCloudSea()

    local snapX = math.floor(camPos.X / 720 + 0.5) * 720
    local snapZ = math.floor(camPos.Z / 720 + 0.5) * 720
    local drift1X = math.sin(now * 0.055) * 65 + ((now * 3.4) % 720) - 360
    local drift1Z = math.cos(now * 0.042) * 48

    for idx, entry in ipairs(cloudUpperPads) do
        local sp = entry.Spec
        local wx = snapX + sp.x + drift1X * sp.sx
        local wz = snapZ + sp.z + drift1Z * sp.sz
        local wy = sp.y + math.sin(now * 0.45 + idx) * 0.65
        entry.Part.Color = currentCloudColors.Upper
        entry.Part.CFrame = CFrame.new(wx, wy, wz) * CFrame.Angles(0, 0, math.pi * 0.5)
    end

    local drift2X = math.cos(now * 0.032) * 52
    local drift2Z = math.sin(now * 0.028) * 52
    for idx, entry in ipairs(cloudMidPads) do
        local sp = entry.Spec
        entry.Part.Color = currentCloudColors.Mid
        entry.Part.CFrame = CFrame.new(snapX + sp.x + drift2X, sp.y, snapZ + sp.z + drift2Z) * CFrame.Angles(0, 0, math.pi * 0.5)
    end

    for tIdx, tileOff in ipairs(CLOUD_TILE_OFFSETS) do
        local ms = cloudMidSheets[tIdx]
        if ms then
            ms.Color = currentCloudColors.Mid
            ms.Position = Vector3.new(camPos.X + tileOff.X, -35.5, camPos.Z + tileOff.Z)
        end
        local ds = cloudDeepSheets[tIdx]
        if ds then
            ds.Color = currentCloudColors.Deep
            ds.Position = Vector3.new(camPos.X + tileOff.X, -58.0, camPos.Z + tileOff.Z)
        end
    end

    for i, bank in ipairs(cloudHorizonBanks) do
        local ang = (i - 1) * (math.pi * 2 / 8) + now * 0.004
        local bx = camPos.X + math.cos(ang) * 1280
        local bz = camPos.Z + math.sin(ang) * 1280
        bank.Color = currentCloudColors.Upper:Lerp(currentCloudColors.Mid, 0.35)
        bank.CFrame = CFrame.new(bx, -24.0, bz) * CFrame.Angles(0, -ang + math.pi * 0.5, math.pi * 0.5)
    end
end

local lastGeyserVFXAt = -10
local function spawnSkyGeyserVortex(originPos, targetRoot)
    local now = os.clock()
    if now - lastGeyserVFXAt < 1.2 then
        return
    end
    lastGeyserVFXAt = now

    local tfx = ensureTempFX()
    local vortexFolder = Instance.new("Folder")
    vortexFolder.Name = "SkyGeyserUpdraftVortex"
    vortexFolder.Parent = tfx

    local basePos = Vector3.new(originPos.X, math.min(originPos.Y, -14), originPos.Z)
    playSFX("cloud_geyser", originPos, 0.05)

    local column = makeCloudPart(vortexFolder, "GeyserCoreColumn", Vector3.new(62, 11.5, 11.5), Enum.PartType.Cylinder, 0.52)
    column.Material = Enum.Material.ForceField
    column.Color = Color3.fromRGB(92, 224, 248)
    column.CFrame = CFrame.new(basePos + Vector3.new(0, 31, 0)) * CFrame.Angles(0, 0, math.pi * 0.5)

    local rings = {}
    local ribbons = {}
    for i = 1, 4 do
        local ring = makeCloudPart(
            vortexFolder,
            "GeyserRing_" .. i,
            Vector3.new(0.85, 8.5 + i * 3.2, 8.5 + i * 3.2),
            Enum.PartType.Cylinder,
            0.35
        )
        ring.Color = (i % 2 == 0) and Color3.fromRGB(238, 194, 88) or Color3.fromRGB(88, 228, 250)
        rings[i] = ring
    end
    for i = 1, 6 do
        local rib = makeCloudPart(
            vortexFolder,
            "WindRibbon_" .. i,
            Vector3.new(0.32, 4.4, 0.65),
            Enum.PartType.Block,
            0.28
        )
        rib.Color = (i % 2 == 0) and Color3.fromRGB(116, 236, 255) or Color3.fromRGB(242, 206, 112)
        ribbons[i] = rib
    end

    local startAt = os.clock()
    local duration = 1.45
    local conn
    conn = RunService.Heartbeat:Connect(function()
        local elapsed = os.clock() - startAt
        if elapsed >= duration or not vortexFolder.Parent then
            conn:Disconnect()
            if vortexFolder.Parent then
                vortexFolder:Destroy()
            end
            return
        end
        local u = elapsed / duration
        local fade = u * u
        column.Transparency = 0.52 + 0.48 * fade
        local colRad = 11.5 + u * 6.5
        column.Size = Vector3.new(68, colRad, colRad)

        for i, ring in ipairs(rings) do
            local yRise = ((u * 54 + (i - 1) * 13) % 56)
            local spin = elapsed * (5.5 + i)
            ring.Transparency = 0.34 + 0.64 * fade
            ring.CFrame = CFrame.new(basePos + Vector3.new(0, yRise, 0))
                * CFrame.Angles(math.sin(spin) * 0.14, spin, math.pi * 0.5)
        end

        local followCenter = (targetRoot and targetRoot.Parent) and targetRoot.Position or (basePos + Vector3.new(0, u * 48, 0))
        for i, rib in ipairs(ribbons) do
            local ang = elapsed * 10.5 + (i - 1) * (math.pi * 2 / #ribbons)
            local rad = 3.4 + math.sin(elapsed * 6 + i) * 0.8
            local offset = Vector3.new(math.cos(ang) * rad, -2.2 + (i % 3) * 1.4, math.sin(ang) * rad)
            rib.Transparency = 0.25 + 0.72 * fade
            rib.CFrame = CFrame.new(followCenter + offset) * CFrame.Angles(0.35, -ang, 0.25)
        end
    end)
end

-- ============================================================================
-- 3. #26 3D QUEST WAYPOINT LIGHT PILLAR & ANIMATED TREASURE CHESTS + COIN BURST
-- ============================================================================
local waypointFolder = nil
local waypointBeam = nil
local waypointRing = nil
local waypointAnchor = nil
local waypointBill = nil
local waypointLabel = nil
local waypointFrame = nil
local waypointStroke = nil
local cachedFallbackBeaconPos = nil
local nextFallbackScanAt = 0

local function ensureQuestWaypoint()
    local tfx = workspace:FindFirstChild("TempFX")
    local existing = tfx and tfx:FindFirstChild("QuestWaypointBeacon")
    if existing then
        existing:Destroy()
    end
    waypointFolder = nil
    waypointBeam = nil
    waypointRing = nil
    waypointAnchor = nil
    waypointBill = nil
end

local function stepQuestWaypoint(_playerPos, _now)
    if waypointFolder and waypointFolder.Parent then
        waypointFolder:Destroy()
        waypointFolder = nil
    end
end

-- Animated 3D Ornate Treasure Chests & Magnetic Coin/Gem Burst (#26)
local trackedChests = {}
local activeChestBursts = {}

local function spawnChestCoinBurst(chestPos)
    local tfx = ensureTempFX()
    local burstFolder = Instance.new("Folder")
    burstFolder.Name = "ChestCoinGemBurst"
    burstFolder.Parent = tfx

    playSFX("chest_open", chestPos, 0.04)

    local count = isLowFX() and 8 or 12
    local items = {}
    for i = 1, count do
        local isGem = (i % 4 == 0)
        local p = makeCloudPart(
            burstFolder,
            isGem and ("CoreGem_" .. i) or ("GoldCoin_" .. i),
            isGem and Vector3.new(0.58, 0.86, 0.58) or Vector3.new(0.18, 0.88, 0.88),
            isGem and Enum.PartType.Block or Enum.PartType.Cylinder,
            0.04
        )
        p.Material = isGem and Enum.Material.Glass or Enum.Material.Metal
        p.Reflectance = isGem and 0.15 or 0.25
        p.Color = isGem
            and ((i % 8 == 0) and Color3.fromRGB(178, 96, 248) or Color3.fromRGB(88, 226, 250))
            or Color3.fromRGB(242, 196, 68)

        local ang = (i - 1) * (math.pi * 2 / count) + (math.random() - 0.5) * 0.35
        local spread = 2.8 + math.random() * 2.6
        local apex = chestPos + Vector3.new(math.cos(ang) * spread, 4.2 + math.random() * 2.4, math.sin(ang) * spread)
        items[i] = {
            Part = p,
            IsGem = isGem,
            Start = chestPos + Vector3.new(0, 1.1, 0),
            Apex = apex,
            SpinSpeed = 7 + math.random() * 6,
            Delay = (i - 1) * 0.022,
            Chimed = false,
        }
    end

    table.insert(activeChestBursts, {
        Folder = burstFolder,
        Items = items,
        BornAt = os.clock(),
    })
end

local function build3DChestAssembly(triggerPart)
    if trackedChests[triggerPart] then
        return
    end
    local chestVisualsRoot = ensureTempFX():FindFirstChild("SkybreakAnimatedChests")
    if not chestVisualsRoot then
        chestVisualsRoot = Instance.new("Folder")
        chestVisualsRoot.Name = "SkybreakAnimatedChests"
        chestVisualsRoot.Parent = ensureTempFX()
    end

    local cpos = triggerPart.Position
    local yaw = select(2, triggerPart.CFrame:ToEulerAnglesYXZ())
    local baseCF = CFrame.new(cpos.X, cpos.Y - 0.35, cpos.Z) * CFrame.Angles(0, yaw, 0)

    local mdl = Instance.new("Model")
    mdl.Name = "Animated3DChest_" .. triggerPart.Name
    mdl.Parent = chestVisualsRoot

    local function chestPart(name, size, color, mat, localCF)
        local p = makeCloudPart(mdl, name, size, Enum.PartType.Block, 0)
        p.Color = color
        p.Material = mat
        p.CFrame = baseCF * localCF
        return p
    end

    local obsidian = Color3.fromRGB(28, 34, 48)
    local gold = Color3.fromRGB(228, 182, 72)
    local aether = Color3.fromRGB(92, 224, 248)

    local body = chestPart("ChestBody", Vector3.new(3.4, 1.45, 2.2), obsidian, Enum.Material.Metal, CFrame.new(0, 0.72, 0))
    mdl.PrimaryPart = body
    chestPart("GoldTrimBottom", Vector3.new(3.54, 0.22, 2.34), gold, Enum.Material.Metal, CFrame.new(0, 0.12, 0))
    chestPart("GoldStrapLeft", Vector3.new(0.26, 1.50, 2.30), gold, Enum.Material.Metal, CFrame.new(-1.12, 0.74, 0))
    chestPart("GoldStrapRight", Vector3.new(0.26, 1.50, 2.30), gold, Enum.Material.Metal, CFrame.new(1.12, 0.74, 0))
    local coreGem = chestPart("CoreShardGlow", Vector3.new(2.6, 0.25, 1.5), aether, Enum.Material.SmoothPlastic, CFrame.new(0, 1.32, 0))
    coreGem.Transparency = 0.35

    -- Rear hinge at local (0, 1.45, 1.08); lid parts offset relative to hinge so pivoting 105 deg swings cleanly open!
    local hingeBaseCF = baseCF * CFrame.new(0, 1.45, 1.08)
    local lidParts = {
        { Part = chestPart("LidVault", Vector3.new(3.46, 0.74, 2.26), obsidian, Enum.Material.Metal, CFrame.identity), Offset = CFrame.new(0, 0.36, -1.08) },
        { Part = chestPart("LidCrownArch", Vector3.new(3.26, 0.34, 1.72), Color3.fromRGB(36, 44, 62), Enum.Material.Metal, CFrame.identity), Offset = CFrame.new(0, 0.80, -1.08) },
        { Part = chestPart("LidBandL", Vector3.new(0.28, 0.82, 2.34), gold, Enum.Material.Metal, CFrame.identity), Offset = CFrame.new(-1.12, 0.40, -1.08) },
        { Part = chestPart("LidBandR", Vector3.new(0.28, 0.82, 2.34), gold, Enum.Material.Metal, CFrame.identity), Offset = CFrame.new(1.12, 0.40, -1.08) },
        { Part = chestPart("LidClasp", Vector3.new(0.56, 0.62, 0.24), gold, Enum.Material.Metal, CFrame.identity), Offset = CFrame.new(0, 0.08, -2.22) },
        { Part = chestPart("LidLockGem", Vector3.new(0.28, 0.32, 0.28), aether, Enum.Material.SmoothPlastic, CFrame.identity), Offset = CFrame.new(0, 0.08, -2.26) },
    }
    for _, lp in ipairs(lidParts) do
        lp.Part.CFrame = hingeBaseCF * lp.Offset
    end

    local chestModel = (triggerPart.Parent and triggerPart.Parent:IsA("Model")) and triggerPart.Parent or nil
    -- Hide raw server placeholder chest blocks so they never Z-fight inside Animated3DChest
    triggerPart.LocalTransparencyModifier = 1
    if chestModel then
        for _, sub in ipairs(chestModel:GetChildren()) do
            if sub:IsA("BasePart") then
                sub.LocalTransparencyModifier = 1
            end
        end
    end

    local function isCurrentlyOpen()
        if triggerPart:GetAttribute("ChestOpened") == true or (chestModel and chestModel:GetAttribute("ChestOpened") == true) then
            return true
        end
        local untilTs = tonumber(triggerPart:GetAttribute("OpenedUntil"))
            or tonumber(chestModel and chestModel:GetAttribute("OpenedUntil"))
            or 0
        if untilTs > 0 and untilTs > workspace:GetServerTimeNow() then
            return true
        end
        return false
    end

    local initOpen = isCurrentlyOpen()
    local entry = {
        Trigger = triggerPart,
        ChestModel = chestModel,
        Model = mdl,
        HingeCF = hingeBaseCF,
        LidParts = lidParts,
        CoreGem = coreGem,
        IsOpenFn = isCurrentlyOpen,
        CurrentAngleDeg = initOpen and 105 or 0,
        TargetAngleDeg = initOpen and 105 or 0,
        WasOpen = initOpen,
        LastBurstAt = -10,
    }
    trackedChests[triggerPart] = entry

    local function onStateChanged()
        local openNow = isCurrentlyOpen()
        entry.TargetAngleDeg = openNow and 105 or 0
        if openNow and not entry.WasOpen then
            local tNow = os.clock()
            if tNow - entry.LastBurstAt > 1.0 then
                entry.LastBurstAt = tNow
                spawnChestCoinBurst(triggerPart.Position)
            end
        end
        entry.WasOpen = openNow
    end

    triggerPart:GetAttributeChangedSignal("ChestOpened"):Connect(onStateChanged)
    triggerPart:GetAttributeChangedSignal("OpenedUntil"):Connect(onStateChanged)
    if chestModel then
        chestModel:GetAttributeChangedSignal("ChestOpened"):Connect(onStateChanged)
        chestModel:GetAttributeChangedSignal("OpenedUntil"):Connect(onStateChanged)
    end
end

local function scanChestInstance(inst)
    if inst:IsA("BasePart") then
        if inst:GetAttribute("Interactable") == "Chest" or inst:GetAttribute("ChestId") ~= nil or (inst.Parent and inst.Parent.Name == "SkybreakChests") then
            build3DChestAssembly(inst)
        end
    elseif inst:IsA("Model") and inst.Parent and inst.Parent.Name == "SkybreakChests" then
        local bp = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
        if bp then
            build3DChestAssembly(bp)
        end
    end
end

task.spawn(function()
    for _, fName in ipairs({ "SkybreakChests", "SkybreakWorldObjects" }) do
        local f = workspace:FindFirstChild(fName)
        if f then
            for _, ch in ipairs(f:GetDescendants()) do
                scanChestInstance(ch)
            end
            f.DescendantAdded:Connect(scanChestInstance)
        end
    end
    workspace.ChildAdded:Connect(function(child)
        if child.Name == "SkybreakChests" or child.Name == "SkybreakWorldObjects" then
            for _, ch in ipairs(child:GetDescendants()) do
                scanChestInstance(ch)
            end
            child.DescendantAdded:Connect(scanChestInstance)
        end
    end)
end)

local function stepChestsAndCoinBursts(dt, now, playerTorsoPos)
    for trigger, entry in pairs(trackedChests) do
        if not trigger.Parent then
            if entry.Model then
                entry.Model:Destroy()
            end
            trackedChests[trigger] = nil
            continue
        end
        if entry.IsOpenFn and entry.WasOpen and not entry.IsOpenFn() then
            entry.WasOpen = false
            entry.TargetAngleDeg = 0
        end
        if math.abs(entry.CurrentAngleDeg - entry.TargetAngleDeg) > 0.15 then
            local alpha = 1 - math.exp(-11 * dt)
            entry.CurrentAngleDeg = entry.CurrentAngleDeg + (entry.TargetAngleDeg - entry.CurrentAngleDeg) * alpha
            -- Hinge sits at rear (+Z); positive X rotation lifts front (-Z) cleanly upward by 105 degrees!
            local pivotCF = entry.HingeCF * CFrame.Angles(math.rad(entry.CurrentAngleDeg), 0, 0)
            for _, lp in ipairs(entry.LidParts) do
                if lp.Part and lp.Part.Parent then
                    lp.Part.CFrame = pivotCF * lp.Offset
                end
            end
            if entry.CoreGem then
                entry.CoreGem.Transparency = (entry.TargetAngleDeg > 50) and 0.78 or 0.35
            end
        end
    end

    for idx = #activeChestBursts, 1, -1 do
        local burst = activeChestBursts[idx]
        local allDone = true
        local target = playerTorsoPos or (burst.Items[1] and burst.Items[1].Start + Vector3.new(0, 3, 0))
        for _, item in ipairs(burst.Items) do
            local t = (now - burst.BornAt) - item.Delay
            if t < 0 then
                allDone = false
            elseif t < 0.88 then
                allDone = false
                local pos
                if t < 0.30 then
                    local u = smoothAlpha(t / 0.30)
                    pos = item.Start:Lerp(item.Apex, u)
                else
                    local u = smoothAlpha((t - 0.30) / 0.58)
                    local ctrl = item.Apex + Vector3.new(0, 1.8, 0)
                    local inv = 1 - u
                    pos = (inv * inv) * item.Apex + (2 * inv * u) * ctrl + (u * u) * target
                    if u > 0.82 and not item.Chimed then
                        item.Chimed = true
                        playSFX("coin_collect", target, 0.08)
                    end
                end
                local spin = now * item.SpinSpeed
                if item.IsGem then
                    item.Part.CFrame = CFrame.new(pos) * CFrame.Angles(spin * 0.7, spin, 0.35)
                else
                    item.Part.CFrame = CFrame.new(pos) * CFrame.Angles(0, spin, math.pi * 0.5)
                end
            elseif item.Part.Transparency < 1 then
                item.Part.Transparency = 1
            end
        end
        if allDone or (now - burst.BornAt) > 1.35 then
            if burst.Folder and burst.Folder.Parent then
                burst.Folder:Destroy()
            end
            table.remove(activeChestBursts, idx)
        end
    end
end

-- ============================================================================
-- 4. #65 LIVING VILLAGERS, WATCH GUARDS & AMBIENT TOWN NPC CONTROLLER
-- Shared _G.SkybreakLivingNPCsStarted guard guarantees active even if BlenderNPCs is Disabled
-- ============================================================================
task.spawn(function()
    if _G.SkybreakLivingNPCsStarted or workspace:GetAttribute("SkybreakLivingNPCsActive") == true then
        return
    end
    local okRenderer, Renderer = pcall(function()
        return require(ReplicatedStorage:WaitForChild("DelegatedV5Renderer", 8))
    end)
    local Sources = ReplicatedStorage:FindFirstChild("DelegatedV5Sources")
    if type(_G.SkybreakStartLivingNPCs) == "function" then
        _G.SkybreakStartLivingNPCs()
        workspace:SetAttribute("SkybreakLivingNPCsActive", true)
        return
    end
    if _G.SkybreakLivingNPCsStarted or workspace:GetAttribute("SkybreakLivingNPCsActive") == true then
        return
    end
    _G.SkybreakLivingNPCsStarted = true
    workspace:SetAttribute("SkybreakLivingNPCsActive", true)

    local LORE_LINES = {
        Citizen = {
            "Mảnh Core Shards giữ cho các quần đảo lơ lửng trên biển mây Aether.",
            "Nghe nói Hải Tặc Bầu Trời của Vance đang tập kết ở West Garden!",
            "Rơi xuống biển mây đừng lo, mạch Sky-Geyser sẽ đẩy bạn bay ngược lên bến cảng.",
            "Đến Zioles Gacha Shrine thử vận may xem, biết đâu quay trúng Trái Thần Thoại!",
        },
        Guard = {
            "[CẢNH VỆ] Khu vực Sky Hub an toàn. Hãy cẩn thận khi vượt cổng sang Sea 2!",
            "[CẢNH VỆ] Thủy quái Abyssal Leviathan chỉ trồi lên ở vùng biển sâu Sea 3.",
            "[CẢNH VỆ] Đạt 10 Triệu Bounty sẽ triệu hồi được SkySeaBeast hộ vệ!",
            "[CẢNH VỆ] Chiến hạm Aether Galleon đã sẵn sàng tại bến cảng cho Sky Crew.",
        },
        Master = {
            "Luyện thành thục 4 đòn M1 Kata để khai mở tuyệt kỹ Celestial Godhuman!",
            "Đạt Mastery Lv.600 trên võ thuật và vũ khí sẽ mở khóa danh hiệu Đại Tông Sư.",
            "Kết hợp Busoshoku Haki Stage 5 và Kenbunshoku V2 để áp đảo mọi Boss!",
        },
        Merchant = {
            "Kael có thể nâng cấp Thần Khí lên 5 Sao và khắc phù phép tại lò rèn Aether.",
            "Mirage Fruit Stock làm mới mỗi giờ, hoặc ghé Cyberport Café giao dịch 4 ghế!",
            "Thu thập Microchip tại Raid Lab Sea 2 để Thức Tỉnh V2 toàn bộ chiêu Trái Ác Quỷ!",
        },
        Greet = {
            "Chào chiến binh Skyborn! Chúc hành trình thuận buồm xuôi gió.",
            "Gió Aether hôm nay rất thuận lợi để ra khơi chinh phục bầu trời!",
            "Cần hỗ trợ hãy nhấn [E] trò chuyện nhé, lữ khách!",
        },
    }

    local AMBIENT_SPAWN_SPECS = {
        { Name = "SkyHub_WatchGuard_West", Asset = "SunshardRoyalGuard", Role = "Guard", Label = "Thiết Giáp Cảnh Vệ • Sky Watch", Pos = Vector3.new(-334.0, 49.5, 542.0), Face = Vector3.new(-317.4, 49.5, 527.8) },
        { Name = "SkyHub_WatchGuard_Gate", Asset = "SunshardRoyalGuard", Role = "Guard", Label = "Thủ Vệ Cổng Không Gian • Gate Guard", Pos = Vector3.new(-296.0, 49.5, 550.0), Face = Vector3.new(-317.4, 49.5, 527.8) },
        { Name = "SkyHub_Villager_Aria", Asset = "Female_Adventurer", Role = "Citizen", Label = "Cư Dân Bầu Trời • Aria", Pos = Vector3.new(-308.0, 49.5, 515.0), Face = Vector3.new(-321.0, 49.5, 523.0) },
        { Name = "SkyHub_Villager_Toma", Asset = "Male_Novice", Role = "Citizen", Label = "Học Giả Aether • Toma", Pos = Vector3.new(-326.0, 49.5, 513.0), Face = Vector3.new(-314.0, 49.5, 523.0) },
        { Name = "Cyberport_Patron_Lin", Asset = "Female_Adventurer", Role = "Merchant", Label = "Thương Khách Café • Lin", Pos = Vector3.new(9376.0, 49.5, 1780.0), Face = Vector3.new(9400.0, 49.5, 1785.0) },
        { Name = "CastleVoid_Sentinel_Korr", Asset = "Male_SkyGuardian", Role = "Guard", Label = "Hộ Vệ Dinh Thự • Korr", Pos = Vector3.new(-14578.0, 49.5, 2160.0), Face = Vector3.new(-14600.0, 49.5, 2173.1) },
    }

    local tracked = {}
    local ambientTemplates = {}
    local ambientClips = {}

    local function classifyRole(inst)
        local n = (tostring(inst.Name) .. " " .. tostring(inst:GetAttribute("NPCId") or "") .. " " .. tostring(inst:GetAttribute("InteractableId") or "")):lower()
        if n:find("guard") or n:find("sentinel") or n:find("vanguard") or n:find("commander") or n:find("warden") then
            return "Guard"
        elseif n:find("master") or n:find("monk") or n:find("swordmaster") or n:find("dojo") then
            return "Master"
        elseif n:find("zioles") or n:find("kael") or n:find("mirage") or n:find("broker") or n:find("vega") or n:find("cafe") or n:find("shipwright") or n:find("smith") then
            return "Merchant"
        end
        return "Citizen"
    end

    local function makeBubble(adornee, role)
        local old = adornee:FindFirstChild("SkybreakLivingSpeech")
        if old then
            return old, old:FindFirstChild("BubbleFrame") and old.BubbleFrame:FindFirstChild("SpeechText")
        end
        local bill = Instance.new("BillboardGui")
        bill.Name = "SkybreakLivingSpeech"
        bill.Size = UDim2.fromOffset(250, 48)
        bill.StudsOffset = Vector3.new(0, 5.1, 0)
        bill.AlwaysOnTop = false
        bill.MaxDistance = 42
        bill.Enabled = false
        bill.Parent = adornee

        local frame = Instance.new("Frame")
        frame.Name = "BubbleFrame"
        frame.Size = UDim2.fromScale(1, 1)
        frame.BackgroundColor3 = Color3.fromRGB(10, 15, 26)
        frame.BackgroundTransparency = 0.14
        frame.BorderSizePixel = 0
        frame.Parent = bill

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 9)
        corner.Parent = frame

        local accent = (role == "Guard" and Color3.fromRGB(106, 214, 248))
            or (role == "Master" and Color3.fromRGB(244, 188, 84))
            or (role == "Merchant" and Color3.fromRGB(122, 236, 186))
            or Color3.fromRGB(224, 198, 132)

        local stroke = Instance.new("UIStroke")
        stroke.Color = accent
        stroke.Thickness = 1.3
        stroke.Transparency = 0.2
        stroke.Parent = frame

        local txt = Instance.new("TextLabel")
        txt.Name = "SpeechText"
        txt.Size = UDim2.new(1, -16, 1, -8)
        txt.Position = UDim2.fromOffset(8, 4)
        txt.BackgroundTransparency = 1
        txt.Font = Enum.Font.GothamMedium
        txt.TextSize = 11
        txt.TextWrapped = true
        txt.TextColor3 = Color3.fromRGB(238, 242, 250)
        txt.Text = ""
        txt.Parent = frame
        return bill, txt
    end

    local function registerEntry(keyInst, rootPart, rigModel, role, isSpawnedRig, assetName)
        if not keyInst or not rootPart or tracked[keyInst] then
            return
        end
        local bill, txt = makeBubble(rootPart, role)
        local neck = rigModel and rigModel:FindFirstChild("Neck", true)
        local waist = rigModel and rigModel:FindFirstChild("Waist", true)
        local rShoulder = rigModel and (rigModel:FindFirstChild("RightShoulder", true) or rigModel:FindFirstChild("Right Shoulder", true))
        local headBone = rigModel and rigModel:FindFirstChild("Head", true)
        if headBone and not headBone:IsA("Bone") then
            headBone = nil
        end
        local armBone = rigModel and rigModel:FindFirstChild("RightUpperArm", true)
        if armBone and not armBone:IsA("Bone") then
            armBone = nil
        end
        tracked[keyInst] = {
            Inst = keyInst,
            Root = rootPart,
            Rig = rigModel,
            Role = role,
            IsSpawnedRig = isSpawnedRig == true,
            AssetName = assetName,
            Billboard = bill,
            Label = txt,
            BaseCF = rootPart.CFrame,
            RigBasePivot = rigModel and rigModel:GetPivot() or rootPart.CFrame,
            Neck = (neck and neck:IsA("Motor6D")) and neck or nil,
            NeckC0 = (neck and neck:IsA("Motor6D")) and neck.C0 or nil,
            Waist = (waist and waist:IsA("Motor6D")) and waist or nil,
            WaistC0 = (waist and waist:IsA("Motor6D")) and waist.C0 or nil,
            RightShoulder = (rShoulder and rShoulder:IsA("Motor6D")) and rShoulder or nil,
            RightShoulderC0 = (rShoulder and rShoulder:IsA("Motor6D")) and rShoulder.C0 or nil,
            HeadBone = headBone,
            ArmBone = armBone,
            Yaw = 0,
            Phase = math.random() * math.pi * 2,
            LineIndex = math.random(1, 4),
            NextSpeechAt = os.clock() + math.random() * 7 + 1.5,
            SpeechHideAt = 0,
            LastGreetAt = -20,
            WaveUntil = 0,
            WasNear = false,
        }
    end

    local function scanCandidate(obj)
        if not obj or tracked[obj] then
            return
        end
        if obj:IsA("Model") then
            local mName = obj.Name
            if mName:match("^Citizen%d") or obj:GetAttribute("NPCId") or (obj.Parent and (obj.Parent.Name == "InteractiveNPCs" or obj.Parent.Name == "ActiveNPCs")) then
                if mName:find("AncientAetherFruitTrees") or mName:find("Ship") or mName:find("Galleon") then
                    return
                end
                local root = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Body") or obj:FindFirstChild("NPCPillar") or obj:FindFirstChildWhichIsA("BasePart")
                if root then
                    registerEntry(obj, root, obj, classifyRole(obj), false, nil)
                end
            end
        elseif obj:IsA("BasePart") then
            local id = tostring(obj:GetAttribute("InteractableId") or "")
            if id:match("^Citizen%d") then
                local charMdl = obj.Parent and obj.Parent:FindFirstChild(id .. "Character")
                registerEntry(obj, obj, charMdl, "Citizen", false, nil)
            end
        end
    end

    if okRenderer and Renderer and Sources then
        local townFolder = workspace:FindFirstChild("SkybreakLivingTownNPCs")
        if not townFolder then
            townFolder = Instance.new("Folder")
            townFolder.Name = "SkybreakLivingTownNPCs"
            townFolder.Parent = workspace
        end
        local function buildTownRayParams()
            local rp = RaycastParams.new()
            rp.FilterType = Enum.RaycastFilterType.Exclude
            local excl = { townFolder }
            for _, fn in ipairs({
                "ActiveNPCs", "ActiveEnemies", "SkybreakWorldObjects", "SkybreakWorld3DProps",
                "TempFX", "WorldPortals", "SkybreakSeaPlanes", "SkybreakVFXDebris",
                "SkybreakAtmosphereFX", "SkybreakTownLanterns", "SkybreakHarborBoats",
            }) do
                local f = workspace:FindFirstChild(fn)
                if f then
                    table.insert(excl, f)
                end
            end
            if localPlayer and localPlayer.Character then
                table.insert(excl, localPlayer.Character)
            end
            rp.FilterDescendantsInstances = excl
            return rp
        end
        local rayParams = buildTownRayParams()

        for _, spec in ipairs(AMBIENT_SPAWN_SPECS) do
            if not townFolder:FindFirstChild(spec.Name) and Sources:FindFirstChild(spec.Asset) then
                local okB, built = pcall(function()
                    ambientTemplates[spec.Asset] = ambientTemplates[spec.Asset] or Renderer.Build(spec.Asset)
                    ambientClips[spec.Asset] = ambientClips[spec.Asset] or Renderer.Clips(spec.Asset, 2.6)
                    return ambientTemplates[spec.Asset]
                end)
                if okB and built then
                    local hit = workspace:Raycast(spec.Pos + Vector3.new(0, 14, 0), Vector3.new(0, -32, 0), rayParams)
                    local floorY = hit and hit.Position.Y or (spec.Pos.Y - 4.0)
                    local groundPos = Vector3.new(spec.Pos.X, floorY, spec.Pos.Z)
                    local baseCF = CFrame.lookAt(groundPos, Vector3.new(spec.Face.X, floorY, spec.Face.Z))

                    local clone = built:Clone()
                    clone.Name = spec.Name
                    clone:ScaleTo(2.6)
                    for _, d in ipairs(clone:GetDescendants()) do
                        if d:IsA("BasePart") then
                            d.Anchored = true
                            d.CanCollide = false
                            d.CanQuery = false
                            d.CanTouch = false
                            d.CastShadow = false
                        end
                    end
                    clone:PivotTo(baseCF)
                    clone:SetAttribute("LivingTownNPC", true)
                    clone:SetAttribute("NPCRole", spec.Role)
                    clone.Parent = townFolder

                    if clone.PrimaryPart then
                        local nameBill = Instance.new("BillboardGui")
                        nameBill.Name = "TownNameTag"
                        nameBill.Size = UDim2.fromOffset(190, 22)
                        nameBill.StudsOffset = Vector3.new(0, 3.9, 0)
                        nameBill.AlwaysOnTop = false
                        nameBill.MaxDistance = 36
                        nameBill.Parent = clone.PrimaryPart

                        local nLbl = Instance.new("TextLabel")
                        nLbl.Size = UDim2.fromScale(1, 1)
                        nLbl.BackgroundTransparency = 1
                        nLbl.Font = Enum.Font.GothamBold
                        nLbl.TextSize = 11
                        nLbl.TextColor3 = (spec.Role == "Guard") and Color3.fromRGB(132, 224, 255) or Color3.fromRGB(242, 214, 138)
                        nLbl.TextStrokeTransparency = 0.25
                        nLbl.Text = spec.Label
                        nLbl.Parent = nameBill

                        registerEntry(clone, clone.PrimaryPart, clone, spec.Role, true, spec.Asset)
                        tracked[clone].BaseCF = baseCF
                        tracked[clone].RigBasePivot = baseCF
                        tracked[clone].SpecPos = spec.Pos
                        tracked[clone].SpecFace = spec.Face
                        tracked[clone].GroundSnapped = (hit ~= nil)
                    end
                end
                task.wait(0.05)
            end
        end
    end

    for _, desc in ipairs(workspace:GetDescendants()) do
        scanCandidate(desc)
    end
    workspace.DescendantAdded:Connect(function(desc)
        task.defer(scanCandidate, desc)
    end)

    RunService.Heartbeat:Connect(function(dt)
        dt = math.clamp(dt, 1 / 240, 0.12)
        local now = os.clock()
        local ch = localPlayer and localPlayer.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        local pPos = hrp and hrp.Position or nil

        for key, e in pairs(tracked) do
            if not e.Inst.Parent or not e.Root.Parent then
                tracked[key] = nil
                continue
            end
            local npcPos = e.Root.Position
            local dist = pPos and (pPos - npcPos).Magnitude or 999
            if dist > 480 then
                if e.Billboard.Enabled then
                    e.Billboard.Enabled = false
                end
                continue
            end

            if e.IsSpawnedRig and not e.GroundSnapped and e.SpecPos and dist <= 320 and now >= (e.NextGroundCheckAt or 0) then
                e.NextGroundCheckAt = now + 2.0
                local townF = workspace:FindFirstChild("SkybreakLivingTownNPCs")
                local rp = RaycastParams.new()
                rp.FilterType = Enum.RaycastFilterType.Exclude
                local excl = {}
                if townF then table.insert(excl, townF) end
                for _, fn in ipairs({
                    "ActiveNPCs", "ActiveEnemies", "SkybreakWorldObjects", "SkybreakWorld3DProps",
                    "TempFX", "WorldPortals", "SkybreakSeaPlanes", "SkybreakVFXDebris",
                }) do
                    local f = workspace:FindFirstChild(fn)
                    if f then table.insert(excl, f) end
                end
                if ch then table.insert(excl, ch) end
                rp.FilterDescendantsInstances = excl
                local hit = workspace:Raycast(e.SpecPos + Vector3.new(0, 14, 0), Vector3.new(0, -32, 0), rp)
                if hit then
                    local floorY = hit.Position.Y
                    local groundPos = Vector3.new(e.SpecPos.X, floorY, e.SpecPos.Z)
                    local newBaseCF = CFrame.lookAt(groundPos, Vector3.new(e.SpecFace.X, floorY, e.SpecFace.Z))
                    e.BaseCF = newBaseCF
                    e.RigBasePivot = newBaseCF
                    e.GroundSnapped = true
                end
            end

            local isNear = dist <= 18
            if isNear and not e.WasNear and (now - e.LastGreetAt) >= 14 then
                e.LastGreetAt = now
                e.WaveUntil = now + 1.85
                e.Inst:SetAttribute("NPCTalkAt", now)
                playSFX("npc_greet", npcPos, 0.04)
                local greets = LORE_LINES.Greet
                e.Label.Text = greets[math.random(1, #greets)]
                e.Billboard.Enabled = true
                e.SpeechHideAt = now + 4.8
                e.NextSpeechAt = now + 10.5
            elseif now >= e.NextSpeechAt and dist <= 44 then
                local pool = LORE_LINES[e.Role] or LORE_LINES.Citizen
                e.LineIndex = (e.LineIndex % #pool) + 1
                e.Label.Text = pool[e.LineIndex]
                e.Billboard.Enabled = true
                e.SpeechHideAt = now + 5.2
                e.NextSpeechAt = now + math.random(9, 14)
            elseif e.Billboard.Enabled and now >= e.SpeechHideAt then
                e.Billboard.Enabled = false
            end
            e.WasNear = isNear

            local targetYaw = 0
            if isNear and pPos and dist > 0.6 then
                local flatDelta = Vector3.new(pPos.X - npcPos.X, 0, pPos.Z - npcPos.Z)
                if flatDelta.Magnitude > 0.25 then
                    local refCF = e.IsSpawnedRig and e.BaseCF or CFrame.new(npcPos) * e.RigBasePivot.Rotation
                    local localDir = refCF:VectorToObjectSpace(flatDelta.Unit)
                    targetYaw = math.clamp(math.atan2(-localDir.X, -localDir.Z), -0.82, 0.82)
                end
            end
            if e.Yaw ~= e.Yaw then e.Yaw = 0 end
            e.Yaw = e.Yaw + (targetYaw - e.Yaw) * (1 - math.exp(-7.0 * dt))

            local breathe = math.sin(now * 2.15 + e.Phase) * 0.045
            local swayRoll = math.cos(now * 1.45 + e.Phase) * 0.018
            local waving = now < e.WaveUntil
            local waveAngle = waving and (0.95 + math.sin(now * 11.0) * 0.35) or 0

            if e.IsSpawnedRig and e.Rig and e.AssetName and okRenderer and Renderer then
                local clips = ambientClips[e.AssetName]
                if clips then
                    local clipName = (waving and clips.Wave and "Wave") or "Idle"
                    local clip = clips[clipName] or clips.Idle
                    if clip then
                        Renderer.Pose(e.Rig, clip, now + e.Phase)
                    end
                end
                e.Rig:PivotTo(e.BaseCF * CFrame.new(0, breathe * 0.5, 0) * CFrame.Angles(0, e.Yaw * 0.65, swayRoll))
                if e.HeadBone and e.HeadBone.Parent then
                    e.HeadBone.Transform = e.HeadBone.Transform * CFrame.Angles(0, e.Yaw * 0.45, 0)
                end
            elseif e.Neck and e.NeckC0 then
                e.Neck.C0 = e.NeckC0 * CFrame.Angles(breathe * 0.4, e.Yaw * 0.72, 0)
                if e.Waist and e.WaistC0 then
                    e.Waist.C0 = e.WaistC0 * CFrame.Angles(breathe * 0.3, e.Yaw * 0.28, swayRoll)
                end
                if e.RightShoulder and e.RightShoulderC0 then
                    e.RightShoulder.C0 = e.RightShoulderC0 * CFrame.Angles(waveAngle, 0, waveAngle * 0.35)
                end
            elseif e.Rig and e.Rig.Parent and e.Rig.Parent.Name == "InteractiveNPCs" then
                e.Rig:PivotTo(e.RigBasePivot * CFrame.new(0, breathe, 0) * CFrame.Angles(0, e.Yaw * 0.55, swayRoll))
            elseif e.HeadBone and e.HeadBone.Parent then
                e.HeadBone.Transform = e.HeadBone.Transform * CFrame.Angles(0, e.Yaw * 0.65, 0)
                if e.ArmBone and e.ArmBone.Parent and waving then
                    e.ArmBone.Transform = e.ArmBone.Transform * CFrame.Angles(waveAngle, 0, 0.25)
                end
            end
        end
    end)
end)

-- ============================================================================
-- 5. #128 DARK-GOLD NEBULA WIPE + #116 WORLDBANNER + #77 MVPSUMMARY + #117 INSPECTCARD
-- ============================================================================
local OBSIDIAN_BG = Color3.fromRGB(8, 12, 24)
local PANEL_BG = Color3.fromRGB(11, 16, 30)
local GOLD_ACCENT = Color3.fromRGB(232, 188, 82)
local CYAN_ACCENT = Color3.fromRGB(92, 220, 248)
local TEXT_LIGHT = Color3.fromRGB(240, 244, 252)
local TEXT_MUTED = Color3.fromRGB(164, 178, 204)

local function styleCard(frame, radius, strokeColor, strokeThick)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = frame
    local s = Instance.new("UIStroke")
    s.Color = strokeColor or GOLD_ACCENT
    s.Thickness = strokeThick or 1.5
    s.Transparency = 0.16
    s.Parent = frame
    return s
end

local function makeLabel(parent, name, pos, size, text, font, textSize, color, xAlign)
    local l = Instance.new("TextLabel")
    l.Name = name
    l.Position = pos
    l.Size = size
    l.BackgroundTransparency = 1
    l.Font = font or Enum.Font.GothamBold
    l.TextSize = textSize or 13
    l.TextColor3 = color or TEXT_LIGHT
    l.TextXAlignment = xAlign or Enum.TextXAlignment.Left
    l.TextTruncate = Enum.TextTruncate.AtEnd
    l.Text = text or ""
    l.Parent = parent
    return l
end

-- Dedicated Nebula Wipe GUI (DisplayOrder = 920 so it covers RealmTransition cleanly with ZERO white flash)
local nebulaGui = playerGui:FindFirstChild("SkybreakNebulaWipeGui") or Instance.new("ScreenGui")
nebulaGui.Name = "SkybreakNebulaWipeGui"
nebulaGui.IgnoreGuiInset = true
nebulaGui.ResetOnSpawn = false
nebulaGui.DisplayOrder = 920
nebulaGui.Parent = playerGui

local nebulaBackdrop = nebulaGui:FindFirstChild("NebulaBackdrop") or Instance.new("Frame")
nebulaBackdrop.Name = "NebulaBackdrop"
nebulaBackdrop.Size = UDim2.fromScale(1, 1)
nebulaBackdrop.BackgroundColor3 = OBSIDIAN_BG
nebulaBackdrop.BackgroundTransparency = 1
nebulaBackdrop.BorderSizePixel = 0
nebulaBackdrop.Visible = false
nebulaBackdrop.Parent = nebulaGui

local nebulaSweepBar = nebulaBackdrop:FindFirstChild("StarlightSweepBar") or Instance.new("Frame")
nebulaSweepBar.Name = "StarlightSweepBar"
nebulaSweepBar.Size = UDim2.new(0.28, 0, 1, 0)
nebulaSweepBar.Position = UDim2.fromScale(-0.32, 0)
nebulaSweepBar.BackgroundColor3 = GOLD_ACCENT
nebulaSweepBar.BackgroundTransparency = 0.25
nebulaSweepBar.BorderSizePixel = 0
nebulaSweepBar.Parent = nebulaBackdrop

if not nebulaSweepBar:FindFirstChildOfClass("UIGradient") then
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, OBSIDIAN_BG),
        ColorSequenceKeypoint.new(0.42, GOLD_ACCENT),
        ColorSequenceKeypoint.new(0.62, CYAN_ACCENT),
        ColorSequenceKeypoint.new(1, OBSIDIAN_BG),
    })
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.45, 0.18),
        NumberSequenceKeypoint.new(0.65, 0.24),
        NumberSequenceKeypoint.new(1, 1),
    })
    grad.Parent = nebulaSweepBar
end

if not nebulaBackdrop:FindFirstChild("ConstellationLayer") then
    local starLayer = Instance.new("Frame")
    starLayer.Name = "ConstellationLayer"
    starLayer.Size = UDim2.fromScale(1, 1)
    starLayer.BackgroundTransparency = 1
    starLayer.Parent = nebulaBackdrop
    local starCoords = {
        { 0.14, 0.22 }, { 0.24, 0.36 }, { 0.33, 0.28 }, { 0.48, 0.18 },
        { 0.62, 0.26 }, { 0.76, 0.34 }, { 0.85, 0.22 }, { 0.20, 0.72 },
        { 0.38, 0.78 }, { 0.54, 0.74 }, { 0.70, 0.80 }, { 0.84, 0.68 },
    }
    for idx, sc in ipairs(starCoords) do
        local dot = Instance.new("Frame")
        dot.Name = "Star_" .. idx
        dot.Size = UDim2.fromOffset((idx % 3 == 0) and 5 or 3, (idx % 3 == 0) and 5 or 3)
        dot.Position = UDim2.fromScale(sc[1], sc[2])
        dot.BackgroundColor3 = (idx % 2 == 0) and GOLD_ACCENT or CYAN_ACCENT
        dot.BackgroundTransparency = 0.25
        dot.BorderSizePixel = 0
        local dc = Instance.new("UICorner")
        dc.CornerRadius = UDim.new(1, 0)
        dc.Parent = dot
        dot.Parent = starLayer
    end
end

local nebulaTitleCard = nebulaBackdrop:FindFirstChild("DestinationCard") or Instance.new("Frame")
nebulaTitleCard.Name = "DestinationCard"
nebulaTitleCard.AnchorPoint = Vector2.new(0.5, 0.5)
nebulaTitleCard.Position = UDim2.fromScale(0.5, 0.5)
nebulaTitleCard.Size = UDim2.fromOffset(440, 78)
nebulaTitleCard.BackgroundColor3 = PANEL_BG
nebulaTitleCard.BackgroundTransparency = 0.08
nebulaTitleCard.BorderSizePixel = 0
nebulaTitleCard.Parent = nebulaBackdrop
if not nebulaTitleCard:FindFirstChildOfClass("UIStroke") then
    styleCard(nebulaTitleCard, 12, GOLD_ACCENT, 1.6)
end

local nebulaSubLbl = nebulaTitleCard:FindFirstChild("Sub") or makeLabel(
    nebulaTitleCard, "Sub", UDim2.fromOffset(16, 12), UDim2.new(1, -32, 0, 18),
    "DỊCH CHUYỂN KHÔNG GIAN • AETHER NEBULA GATE", Enum.Font.GothamBold, 11, GOLD_ACCENT, Enum.TextXAlignment.Center
)
local nebulaDestLbl = nebulaTitleCard:FindFirstChild("Dest") or makeLabel(
    nebulaTitleCard, "Dest", UDim2.fromOffset(16, 34), UDim2.new(1, -32, 0, 30),
    "SKY HUB NEXUS", Enum.Font.GothamBlack, 18, TEXT_LIGHT, Enum.TextXAlignment.Center
)

local function resolveNearestIslandTitle(destPos)
    if typeof(destPos) ~= "Vector3" then
        local realm = tostring((localPlayer and localPlayer:GetAttribute("CurrentRealm")) or "GoldenSky")
        return realm:upper()
    end
    local bestName = "ĐẠI HẢI TRÌNH BẦU TRỜI"
    local bestDist = math.huge
    if type(Config.Islands) == "table" then
        for _, isl in pairs(Config.Islands) do
            if type(isl) == "table" and typeof(isl.Pos) == "Vector3" then
                local d = (isl.Pos - destPos).Magnitude
                if d < bestDist then
                    bestDist = d
                    bestName = tostring(isl.Name or isl.Id or bestName)
                end
            end
        end
    end
    return bestName
end

local lastNebulaWipeAt = -10
local nebulaWipeToken = 0
local function playNebulaPortalWipe(destPos, explicitTitle)
    local now = os.clock()
    if now - lastNebulaWipeAt < 0.70 then
        return
    end
    lastNebulaWipeAt = now
    nebulaWipeToken += 1
    local token = nebulaWipeToken

    nebulaDestLbl.Text = (type(explicitTitle) == "string" and explicitTitle ~= "") and explicitTitle or resolveNearestIslandTitle(destPos)
    nebulaBackdrop.BackgroundColor3 = OBSIDIAN_BG
    nebulaBackdrop.Visible = true
    nebulaBackdrop.BackgroundTransparency = 0.92
    nebulaSweepBar.Position = UDim2.fromScale(-0.32, 0)
    playSFX("nebula_wipe", nil, 0.03)

    TweenService:Create(
        nebulaBackdrop,
        TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { BackgroundTransparency = 0.03 }
    ):Play()
    TweenService:Create(
        nebulaSweepBar,
        TweenInfo.new(0.62, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        { Position = UDim2.fromScale(1.06, 0) }
    ):Play()

    task.delay(0.32, function()
        if nebulaWipeToken ~= token then
            return
        end
        local fadeOut = TweenService:Create(
            nebulaBackdrop,
            TweenInfo.new(0.33, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { BackgroundTransparency = 1 }
        )
        fadeOut:Play()
        fadeOut.Completed:Connect(function()
            if nebulaWipeToken == token then
                nebulaBackdrop.Visible = false
            end
        end)
    end)
end

-- World Overlays GUI (WorldBanner #116, MVPSummary #77, InspectCard #117)
local overlayGui = playerGui:FindFirstChild("SkybreakWorldOverlayGui") or Instance.new("ScreenGui")
overlayGui.Name = "SkybreakWorldOverlayGui"
overlayGui.IgnoreGuiInset = true
overlayGui.ResetOnSpawn = false
overlayGui.DisplayOrder = 40
overlayGui.Parent = playerGui

-- 5A. Top-Center Luxury WorldBanner (#116)
local bannerCard = overlayGui:FindFirstChild("WorldBannerCard") or Instance.new("Frame")
bannerCard.Name = "WorldBannerCard"
bannerCard.AnchorPoint = Vector2.new(0.5, 0)
bannerCard.Position = UDim2.new(0.5, 0, 0, -96)
bannerCard.Size = UDim2.fromOffset(476, 72)
bannerCard.BackgroundColor3 = PANEL_BG
bannerCard.BackgroundTransparency = 0.08
bannerCard.BorderSizePixel = 0
bannerCard.Visible = false
bannerCard.Parent = overlayGui
local bannerStroke = bannerCard:FindFirstChildOfClass("UIStroke") or styleCard(bannerCard, 12, GOLD_ACCENT, 1.8)

local bannerTopTag = bannerCard:FindFirstChild("CategoryTag") or makeLabel(
    bannerCard, "CategoryTag", UDim2.fromOffset(18, 9), UDim2.new(1, -36, 0, 16),
    "[SỰ KIỆN THẾ GIỚI • SKYBREAK]", Enum.Font.GothamBold, 11, GOLD_ACCENT, Enum.TextXAlignment.Center
)
local bannerTitleLbl = bannerCard:FindFirstChild("BannerTitle") or makeLabel(
    bannerCard, "BannerTitle", UDim2.fromOffset(18, 26), UDim2.new(1, -36, 0, 22),
    "TRÁI THẦN THOẠI XUẤT HIỆN", Enum.Font.GothamBlack, 16, TEXT_LIGHT, Enum.TextXAlignment.Center
)
local bannerSubLbl = bannerCard:FindFirstChild("BannerSub") or makeLabel(
    bannerCard, "BannerSub", UDim2.fromOffset(18, 48), UDim2.new(1, -36, 0, 16),
    "Dò tìm tín hiệu Aether trên bản đồ ngay!", Enum.Font.GothamMedium, 12, TEXT_MUTED, Enum.TextXAlignment.Center
)

local bannerToken = 0
local function showWorldBanner(data)
    bannerToken += 1
    local token = bannerToken

    local title = "SỰ KIỆN BẦU TRỜI XUẤT HIỆN"
    local subtitle = "Kiểm tra la bàn và bản đồ để tham gia ngay!"
    local category = "[SỰ KIỆN THẾ GIỚI • SKYBREAK]"
    local accent = GOLD_ACCENT

    if type(data) == "string" then
        title = data
    elseif type(data) == "table" then
        title = tostring(data.Title or data.title or data.Headline or data.Message or title)
        subtitle = tostring(data.Subtitle or data.subtitle or data.Desc or data.Detail or subtitle)
        if data.Category or data.Tag then
            category = "[" .. tostring(data.Category or data.Tag):upper() .. "]"
        end
        if typeof(data.Color) == "Color3" then
            accent = data.Color
        elseif tostring(title):upper():find("LEVIATHAN") or tostring(title):upper():find("MIRAGE") then
            accent = CYAN_ACCENT
        end
    end

    title = select(1, stripAstralEmojis(title))
    subtitle = select(1, stripAstralEmojis(subtitle))
    category = select(1, stripAstralEmojis(category))

    bannerTopTag.Text = category
    bannerTopTag.TextColor3 = accent
    bannerTitleLbl.Text = title
    bannerSubLbl.Text = subtitle
    bannerStroke.Color = accent

    bannerCard.Visible = true
    bannerCard.Position = UDim2.new(0.5, 0, 0, -96)
    playSFX("world_banner", nil, 0.02)

    TweenService:Create(
        bannerCard,
        TweenInfo.new(0.36, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Position = UDim2.new(0.5, 0, 0, 22) }
    ):Play()

    task.delay(6.5, function()
        if bannerToken ~= token then
            return
        end
        local hideTw = TweenService:Create(
            bannerCard,
            TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
            { Position = UDim2.new(0.5, 0, 0, -96) }
        )
        hideTw:Play()
        hideTw.Completed:Connect(function()
            if bannerToken == token then
                bannerCard.Visible = false
            end
        end)
    end)
end

-- 5B. Right-Center Post-Boss MVPSummary (#77)
local mvpCard = overlayGui:FindFirstChild("MVPSummaryCard") or Instance.new("Frame")
mvpCard.Name = "MVPSummaryCard"
mvpCard.AnchorPoint = Vector2.new(1, 0.5)
mvpCard.Position = UDim2.new(1, -18, 0.5, 0)
mvpCard.Size = UDim2.fromOffset(312, 198)
mvpCard.BackgroundColor3 = PANEL_BG
mvpCard.BackgroundTransparency = 0.07
mvpCard.BorderSizePixel = 0
mvpCard.Visible = false
mvpCard.Parent = overlayGui
if not mvpCard:FindFirstChildOfClass("UIStroke") then
    styleCard(mvpCard, 11, GOLD_ACCENT, 1.5)
end

local mvpHeaderLbl = mvpCard:FindFirstChild("MVPHeader") or makeLabel(
    mvpCard, "MVPHeader", UDim2.fromOffset(14, 10), UDim2.new(1, -52, 0, 18),
    "BẢNG VINH DANH MVP", Enum.Font.GothamBlack, 14, GOLD_ACCENT
)
local mvpBossLbl = mvpCard:FindFirstChild("MVPBoss") or makeLabel(
    mvpCard, "MVPBoss", UDim2.fromOffset(14, 28), UDim2.new(1, -52, 0, 16),
    "Chiến Thắng Boss", Enum.Font.GothamMedium, 11, TEXT_MUTED
)

local mvpCloseBtn = mvpCard:FindFirstChild("CloseBtn")
if not mvpCloseBtn then
    mvpCloseBtn = Instance.new("TextButton")
    mvpCloseBtn.Name = "CloseBtn"
    mvpCloseBtn.Position = UDim2.new(1, -36, 0, 10)
    mvpCloseBtn.Size = UDim2.fromOffset(24, 24)
    mvpCloseBtn.BackgroundColor3 = Color3.fromRGB(24, 32, 52)
    mvpCloseBtn.Font = Enum.Font.GothamBold
    mvpCloseBtn.TextSize = 12
    mvpCloseBtn.TextColor3 = TEXT_LIGHT
    mvpCloseBtn.Text = "X"
    mvpCloseBtn.Parent = mvpCard
    styleCard(mvpCloseBtn, 6, GOLD_ACCENT, 1.0)
end

local mvpRows = {}
for i = 1, 3 do
    local rowName = "MVPRow_" .. i
    local r = mvpCard:FindFirstChild(rowName) or Instance.new("Frame")
    r.Name = rowName
    r.Position = UDim2.fromOffset(12, 50 + (i - 1) * 45)
    r.Size = UDim2.new(1, -24, 0, 40)
    r.BackgroundColor3 = Color3.fromRGB(16, 22, 40)
    r.BorderSizePixel = 0
    r.Parent = mvpCard
    if not r:FindFirstChildOfClass("UICorner") then
        local rc = Instance.new("UICorner")
        rc.CornerRadius = UDim.new(0, 7)
        rc.Parent = r
    end
    local rankColor = (i == 1 and GOLD_ACCENT) or (i == 2 and CYAN_ACCENT) or Color3.fromRGB(198, 154, 118)
    local nameL = r:FindFirstChild("NameLbl") or makeLabel(r, "NameLbl", UDim2.fromOffset(10, 4), UDim2.new(1, -88, 0, 16), "MVP #" .. i, Enum.Font.GothamBold, 12, rankColor)
    local pctL = r:FindFirstChild("PctLbl") or makeLabel(r, "PctLbl", UDim2.new(1, -78, 0, 4), UDim2.fromOffset(68, 16), "0.0%", Enum.Font.GothamBold, 12, TEXT_LIGHT, Enum.TextXAlignment.Right)
    local barBg = r:FindFirstChild("BarBg") or Instance.new("Frame")
    barBg.Name = "BarBg"
    barBg.Position = UDim2.fromOffset(10, 25)
    barBg.Size = UDim2.new(1, -20, 0, 7)
    barBg.BackgroundColor3 = Color3.fromRGB(8, 11, 20)
    barBg.BorderSizePixel = 0
    barBg.Parent = r
    if not barBg:FindFirstChildOfClass("UICorner") then
        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(1, 0)
        bc.Parent = barBg
    end
    local barFill = barBg:FindFirstChild("Fill") or Instance.new("Frame")
    barFill.Name = "Fill"
    barFill.Size = UDim2.fromScale(0, 1)
    barFill.BackgroundColor3 = rankColor
    barFill.BorderSizePixel = 0
    barFill.Parent = barBg
    if not barFill:FindFirstChildOfClass("UICorner") then
        local fc = Instance.new("UICorner")
        fc.CornerRadius = UDim.new(1, 0)
        fc.Parent = barFill
    end
    mvpRows[i] = { Row = r, Name = nameL, Pct = pctL, Fill = barFill }
end

local mvpToken = 0
mvpCloseBtn.MouseButton1Click:Connect(function()
    mvpToken += 1
    mvpCard.Visible = false
    playSFX("ui_click")
end)

local function showMVPSummary(data)
    if type(data) ~= "table" then
        return
    end
    mvpToken += 1
    local token = mvpToken

    local bossName = select(1, stripAstralEmojis(tostring(data.BossName or data.bossName or data.Boss or "Boss Raid")))
    mvpBossLbl.Text = "Mục tiêu: " .. bossName

    local list = data.Rankings or data.Entries or data.Top or data.MVP or data.Players or {}
    for i = 1, 3 do
        local entry = list[i]
        local slot = mvpRows[i]
        if entry then
            local pName = select(1, stripAstralEmojis(tostring(entry.Name or entry.DisplayName or entry.Player or ("Skyborn #" .. i))))
            local share = tonumber(entry.SharePct or entry.Percent or entry.Share or entry.DamagePct) or 0
            if share > 0 and share <= 1.0 then
                share = share * 100
            end
            share = math.clamp(share, 0, 100)
            slot.Row.Visible = true
            slot.Name.Text = string.format("MVP #%d • %s", i, pName)
            slot.Pct.Text = string.format("%.1f%%", share)
            slot.Fill.Size = UDim2.fromScale(math.clamp(share / 100, 0.03, 1), 1)
        else
            slot.Row.Visible = false
        end
    end

    mvpCard.Visible = true
    playSFX("quest_complete", nil, 0.02)

    task.delay(9.0, function()
        if mvpToken == token then
            mvpCard.Visible = false
        end
    end)
end

-- 5C. Player InspectCard Modal (#117)
local inspectCard = overlayGui:FindFirstChild("InspectCardModal") or Instance.new("Frame")
inspectCard.Name = "InspectCardModal"
inspectCard.AnchorPoint = Vector2.new(0.5, 0.5)
inspectCard.Position = UDim2.fromScale(0.5, 0.5)
inspectCard.Size = UDim2.fromOffset(424, 344)
inspectCard.BackgroundColor3 = PANEL_BG
inspectCard.BackgroundTransparency = 0.04
inspectCard.BorderSizePixel = 0
inspectCard.Visible = false
inspectCard.Parent = overlayGui
if not inspectCard:FindFirstChildOfClass("UIStroke") then
    styleCard(inspectCard, 12, GOLD_ACCENT, 1.7)
end

local inspectHeader = inspectCard:FindFirstChild("HeaderTitle") or makeLabel(
    inspectCard, "HeaderTitle", UDim2.fromOffset(18, 12), UDim2.new(1, -64, 0, 22),
    "HỒ SƠ CHIẾN BINH • INSPECT", Enum.Font.GothamBlack, 15, GOLD_ACCENT
)
local inspectNameLbl = inspectCard:FindFirstChild("PlayerNameLbl") or makeLabel(
    inspectCard, "PlayerNameLbl", UDim2.fromOffset(18, 36), UDim2.new(1, -36, 0, 20),
    "Skyborn", Enum.Font.GothamBold, 15, TEXT_LIGHT
)
local inspectMetaLbl = inspectCard:FindFirstChild("PlayerMetaLbl") or makeLabel(
    inspectCard, "PlayerMetaLbl", UDim2.fromOffset(18, 56), UDim2.new(1, -36, 0, 18),
    "Lv. 1  •  Bounty: 0  •  Crew: Solo", Enum.Font.GothamMedium, 12, CYAN_ACCENT
)

local inspectCloseBtn = inspectCard:FindFirstChild("CloseInspectBtn")
if not inspectCloseBtn then
    inspectCloseBtn = Instance.new("TextButton")
    inspectCloseBtn.Name = "CloseInspectBtn"
    inspectCloseBtn.Position = UDim2.new(1, -40, 0, 12)
    inspectCloseBtn.Size = UDim2.fromOffset(26, 26)
    inspectCloseBtn.BackgroundColor3 = Color3.fromRGB(24, 32, 52)
    inspectCloseBtn.Font = Enum.Font.GothamBold
    inspectCloseBtn.TextSize = 12
    inspectCloseBtn.TextColor3 = TEXT_LIGHT
    inspectCloseBtn.Text = "X"
    inspectCloseBtn.Parent = inspectCard
    styleCard(inspectCloseBtn, 6, GOLD_ACCENT, 1.0)
end
inspectCloseBtn.MouseButton1Click:Connect(function()
    inspectCard.Visible = false
    playSFX("ui_click")
end)

local inspectFields = {}
local FIELD_DEFS = {
    { Key = "Title", Label = "Danh Hiệu", X = 18, Y = 84 },
    { Key = "Race", Label = "Tộc Hệ & V4", X = 216, Y = 84 },
    { Key = "Style", Label = "Võ Thuật", X = 18, Y = 126 },
    { Key = "Fruit", Label = "Trái Ác Quỷ", X = 216, Y = 126 },
    { Key = "Sword", Label = "Thần Khí & Sao", X = 18, Y = 168 },
    { Key = "Haki", Label = "Haki & Phù Phép", X = 216, Y = 168 },
}
for _, fd in ipairs(FIELD_DEFS) do
    local boxName = "Field_" .. fd.Key
    local box = inspectCard:FindFirstChild(boxName) or Instance.new("Frame")
    box.Name = boxName
    box.Position = UDim2.fromOffset(fd.X, fd.Y)
    box.Size = UDim2.fromOffset(190, 36)
    box.BackgroundColor3 = Color3.fromRGB(16, 23, 42)
    box.BorderSizePixel = 0
    box.Parent = inspectCard
    if not box:FindFirstChildOfClass("UICorner") then
        local bc = Instance.new("UICorner")
        bc.CornerRadius = UDim.new(0, 7)
        bc.Parent = box
    end
    makeLabel(box, "Caption", UDim2.fromOffset(8, 3), UDim2.new(1, -16, 0, 13), fd.Label, Enum.Font.GothamMedium, 10, TEXT_MUTED)
    local valLbl = box:FindFirstChild("Val") or makeLabel(box, "Val", UDim2.fromOffset(8, 17), UDim2.new(1, -16, 0, 16), "-", Enum.Font.GothamBold, 11, TEXT_LIGHT)
    inspectFields[fd.Key] = valLbl
end

local STAT_BAR_DEFS = {
    { Key = "Melee", Label = "Melee", Color = Color3.fromRGB(244, 152, 74) },
    { Key = "Defense", Label = "Defense", Color = Color3.fromRGB(92, 224, 158) },
    { Key = "Sword", Label = "Sword", Color = GOLD_ACCENT },
    { Key = "Gun", Label = "Gun", Color = CYAN_ACCENT },
    { Key = "Fruit", Label = "Core Fruit", Color = Color3.fromRGB(196, 116, 250) },
}
local inspectStatBars = {}
for idx, sd in ipairs(STAT_BAR_DEFS) do
    local y = 214 + (idx - 1) * 23
    local rowName = "StatRadar_" .. sd.Key
    local row = inspectCard:FindFirstChild(rowName) or Instance.new("Frame")
    row.Name = rowName
    row.Position = UDim2.fromOffset(18, y)
    row.Size = UDim2.new(1, -36, 0, 19)
    row.BackgroundTransparency = 1
    row.Parent = inspectCard

    makeLabel(row, "StatName", UDim2.fromOffset(0, 1), UDim2.fromOffset(78, 16), sd.Label, Enum.Font.GothamBold, 11, sd.Color)
    local track = row:FindFirstChild("Track") or Instance.new("Frame")
    track.Name = "Track"
    track.Position = UDim2.fromOffset(82, 5)
    track.Size = UDim2.new(1, -138, 0, 8)
    track.BackgroundColor3 = Color3.fromRGB(12, 18, 34)
    track.BorderSizePixel = 0
    track.Parent = row
    if not track:FindFirstChildOfClass("UICorner") then
        local tc = Instance.new("UICorner")
        tc.CornerRadius = UDim.new(1, 0)
        tc.Parent = track
    end
    local fill = track:FindFirstChild("Fill") or Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.fromScale(0.1, 1)
    fill.BackgroundColor3 = sd.Color
    fill.BorderSizePixel = 0
    fill.Parent = track
    if not fill:FindFirstChildOfClass("UICorner") then
        local fc = Instance.new("UICorner")
        fc.CornerRadius = UDim.new(1, 0)
        fc.Parent = fill
    end
    local numLbl = row:FindFirstChild("Num") or makeLabel(row, "Num", UDim2.new(1, -52, 0, 1), UDim2.fromOffset(52, 16), "1", Enum.Font.GothamBold, 11, TEXT_LIGHT, Enum.TextXAlignment.Right)
    inspectStatBars[sd.Key] = { Fill = fill, Num = numLbl }
end

local lastKnownSelfState = nil

local function formatCommaInt(n)
    local s = tostring(math.max(0, math.floor(tonumber(n) or 0)))
    return s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

local function resolveTitleDisplay(titleId)
    local tid = tostring(titleId or "sky_rookie")
    if CombatDataOk and CombatData and CombatData.Titles and CombatData.Titles[tid] then
        return CombatData.Titles[tid].Name
    end
    return tid ~= "" and tid or "Tân Binh Bầu Trời"
end

local function resolveStyleDisplay(styleId)
    local sid = tostring(styleId or "SkybornCombat")
    if CombatDataOk and CombatData and CombatData.MartialStyles then
        if CombatData.MartialStyles[sid] then
            return CombatData.MartialStyles[sid].Name
        end
        for k, v in pairs(CombatData.MartialStyles) do
            if tostring(k):lower():gsub("_", "") == sid:lower():gsub("_", "") then
                return v.Name
            end
        end
    end
    return sid ~= "" and sid or "Võ Thuật Skyborn"
end

local function resolveFruitDisplay(fruitId)
    local fid = tostring(fruitId or "")
    if fid == "" or fid == "None" or fid == "Chua an" or fid == "Chưa ăn" then
        return ""
    end
    if Config.Fruits and Config.Fruits[fid] and Config.Fruits[fid].Name then
        return Config.Fruits[fid].Name
    end
    if CombatDataOk and CombatData and CombatData.FruitCatalog then
        local cid = CombatData.ResolveFruitId and CombatData.ResolveFruitId(fid) or fid
        if CombatData.FruitCatalog[cid] and CombatData.FruitCatalog[cid].Name then
            return CombatData.FruitCatalog[cid].Name
        end
    end
    return fid
end

local function resolveWeaponDisplay(weaponId)
    local wid = tostring(weaponId or "")
    if wid == "" or wid == "true" or wid == "false" or wid == "nil" then
        wid = "Dawnbringer"
    end
    if Config.Items and Config.Items[wid] and Config.Items[wid].Name then
        return Config.Items[wid].Name
    end
    if CombatDataOk and CombatData and CombatData.Swords and CombatData.Swords[wid] and CombatData.Swords[wid].Name then
        return CombatData.Swords[wid].Name
    end
    return wid
end

local function buildFallbackInspectFromPlayer(plr)
    local p = plr or localPlayer
    if not p then
        return nil
    end
    local st = (p == localPlayer and type(lastKnownSelfState) == "table") and lastKnownSelfState or {}
    local level = tonumber(p:GetAttribute("Level") or st.Level) or 1
    local bounty = tonumber(p:GetAttribute("Bounty") or st.Bounty) or 0
    local crew = tostring(p:GetAttribute("CrewName") or st.CrewName or "Solo Skyborn")
    local titleId = tostring(p:GetAttribute("Title") or p:GetAttribute("EquippedTitle") or st.Title or st.EquippedTitle or "sky_rookie")
    local titleName = resolveTitleDisplay(titleId)
    local race = tostring(p:GetAttribute("Race") or st.Race or "Skyborn")
    local v4 = (p:GetAttribute("RaceV4Unlocked") == true or p:GetAttribute("RaceV4Active") == true or st.RaceV4Unlocked == true) and " [V4]" or ""
    local styleId = tostring(p:GetAttribute("FightingStyle") or st.FightingStyle or "SkybornCombat")
    local styleName = resolveStyleDisplay(styleId)
    local fruitId = tostring(p:GetAttribute("EquippedFruit") or st.EquippedFruit or "")
    local fruitName = resolveFruitDisplay(fruitId)
    local masteryTbl = type(st.Mastery) == "table" and st.Mastery or {}
    local fruitMas = tonumber(p:GetAttribute("FruitMastery") or masteryTbl[fruitId] or st.FruitMastery) or 1
    local fruitV2 = (p:GetAttribute("FruitAwakened") == true or st.FruitAwakened == true) and " [V2]" or ""
    local rawSwordAttr = p:GetAttribute("EquippedSword")
    if type(rawSwordAttr) ~= "string" or rawSwordAttr == "" then
        rawSwordAttr = (p.Character and p.Character:GetAttribute("EquippedSword")) or st.Weapon or st.EquippedSword or "Dawnbringer"
    end
    local swordName = resolveWeaponDisplay(rawSwordAttr)
    local stars = tonumber(p:GetAttribute("EquippedWeaponStar") or p:GetAttribute("WeaponStars") or st.EquippedWeaponStar or st.WeaponStars) or 1
    local enh = tonumber(p:GetAttribute("WeaponEnhance") or st.WeaponEnhance) or 0
    local enchant = tostring(p:GetAttribute("WeaponEnchant") or st.WeaponEnchant or "")
    local hakiStage = tonumber(p:GetAttribute("HakiStage") or p:GetAttribute("BusoStage") or st.HakiStage or st.BusoStage) or 0

    local statsTbl = (type(st.StatAlloc) == "table" and st.StatAlloc) or (type(st.Stats) == "table" and st.Stats) or {}
    return {
        Name = p.DisplayName .. " (@" .. p.Name .. ")",
        Level = level,
        Bounty = bounty,
        Crew = crew ~= "" and crew or "Solo Skyborn",
        Title = titleName,
        Race = race .. v4,
        Style = styleName,
        Fruit = fruitName ~= "" and string.format("%s (Lv.%d%s)", fruitName, fruitMas, fruitV2) or "Chưa trang bị",
        Sword = string.format("%s%s (*%d)", swordName, enh > 0 and (" +" .. tostring(enh)) or "", stars),
        Haki = string.format("Buso Stg.%d%s", hakiStage, enchant ~= "" and (" • " .. enchant) or ""),
        Stats = {
            Melee = tonumber(p:GetAttribute("Stat_Melee") or statsTbl.Melee or statsTbl.ATK) or math.max(1, level),
            Defense = tonumber(p:GetAttribute("Stat_Defense") or statsTbl.Defense or statsTbl.DEF) or math.max(1, level),
            Sword = tonumber(p:GetAttribute("Stat_Sword") or statsTbl.Sword) or math.max(1, math.floor(level * 0.85)),
            Gun = tonumber(p:GetAttribute("Stat_Gun") or statsTbl.Gun) or math.max(1, math.floor(level * 0.45)),
            Fruit = tonumber(p:GetAttribute("Stat_Fruit") or statsTbl.Fruit or statsTbl.CoreFruit) or math.max(1, level),
        },
    }
end

local function showInspectCard(data)
    if type(data) ~= "table" then
        return
    end
    local dispTitle = (data.DisplayName and data.Name and data.DisplayName ~= data.Name)
        and (tostring(data.DisplayName) .. " (@" .. tostring(data.Name) .. ")")
        or tostring(data.Name or data.DisplayName or "Skyborn")
    inspectNameLbl.Text = select(1, stripAstralEmojis(dispTitle))
    local lv = tonumber(data.Level) or 1
    local bty = tonumber(data.Bounty) or 0
    local rawCrew = tostring(data.Crew or data.CrewName or "")
    local crew = select(1, stripAstralEmojis(rawCrew ~= "" and rawCrew or "Solo Skyborn"))
    inspectMetaLbl.Text = string.format("Lv. %d  •  Bounty: %s  •  Crew: %s", lv, formatCommaInt(bty), crew)

    local titleStr = resolveTitleDisplay(data.Title)
    local raceStr = tostring(data.Race or "Skyborn")
    if (data.RaceV4Unlocked == true or (tonumber(data.RaceTier) or 1) >= 4) and not raceStr:find("%[V4%]") then
        raceStr = raceStr .. " [V4]"
    end
    local styleStr = data.Style and tostring(data.Style) or resolveStyleDisplay(data.FightingStyle)

    local fruitStr = data.Fruit
    if not fruitStr then
        local fName = resolveFruitDisplay(data.EquippedFruit)
        if fName ~= "" then
            local fMas = tonumber(data.FruitMastery) or 1
            local fV2 = (data.FruitAwakened == true) and " [V2]" or ""
            fruitStr = string.format("%s (Lv.%d%s)", fName, fMas, fV2)
        else
            fruitStr = "Chưa trang bị"
        end
    end

    local swordStr = data.Sword
    if not swordStr then
        local wName = resolveWeaponDisplay(data.Weapon)
        local wStars = tonumber(data.WeaponStars) or 1
        local wEnh = tonumber(data.WeaponEnhance) or 0
        swordStr = string.format("%s%s (*%d)", wName, wEnh > 0 and (" +" .. tostring(wEnh)) or "", wStars)
    end

    local hakiStr = data.Haki
    if not hakiStr then
        local hStage = tonumber(data.HakiStage)
        local ench = tostring(data.WeaponEnchant or data.Enchant or "")
        local kenTag = (data.KenV2Unlocked == true) and " • Ken V2" or ""
        if hStage ~= nil then
            hakiStr = string.format("Buso Stg.%d%s%s", hStage, kenTag, ench ~= "" and (" • " .. ench) or "")
        else
            hakiStr = ench ~= "" and ench or "Buso Stg.0"
        end
    end

    inspectFields.Title.Text = select(1, stripAstralEmojis(tostring(titleStr)))
    inspectFields.Race.Text = select(1, stripAstralEmojis(raceStr))
    inspectFields.Style.Text = select(1, stripAstralEmojis(styleStr))
    inspectFields.Fruit.Text = select(1, stripAstralEmojis(tostring(fruitStr)))
    inspectFields.Sword.Text = select(1, stripAstralEmojis(tostring(swordStr)))
    inspectFields.Haki.Text = select(1, stripAstralEmojis(tostring(hakiStr)))

    local st = (type(data.Stats) == "table" and data.Stats) or (type(data.StatAlloc) == "table" and data.StatAlloc) or {}
    local maxCap = 2550
    for _, sd in ipairs(STAT_BAR_DEFS) do
        local val = math.max(1, math.floor(tonumber(st[sd.Key] or st[sd.Key:lower()]) or 1))
        local slot = inspectStatBars[sd.Key]
        slot.Num.Text = tostring(val)
        slot.Fill.Size = UDim2.fromScale(math.clamp(val / maxCap, 0.04, 1), 1)
    end

    inspectCard.Visible = true
    playSFX("ui_tab")
end

-- Click another player in workspace with Alt+Click or Right-Click inspect support (non-intrusive to M1 combat)
local function fireUIRequest(actionName, payload)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local uiReq = remotes and remotes:FindFirstChild("UIRequest")
    if uiReq and uiReq:IsA("RemoteEvent") then
        uiReq:FireServer(actionName, payload)
        return
    end
    local shared = ReplicatedStorage:FindFirstChild("SkybreakShared")
    local sRem = shared and shared:FindFirstChild("Remotes")
    local sReq = sRem and sRem:FindFirstChild("UIRequest")
    if sReq and sReq:IsA("RemoteEvent") then
        sReq:FireServer(actionName, payload)
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end
    if input.UserInputType == Enum.UserInputType.MouseButton1 and UserInputService:IsKeyDown(Enum.KeyCode.LeftAlt) then
        local cam = workspace.CurrentCamera
        if not cam then
            return
        end
        local mPos = UserInputService:GetMouseLocation()
        local ray = cam:ViewportPointToRay(mPos.X, mPos.Y)
        local hit = workspace:Raycast(ray.Origin, ray.Direction * 140)
        if hit and hit.Instance then
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr.Character and hit.Instance:IsDescendantOf(plr.Character) then
                    showInspectCard(buildFallbackInspectFromPlayer(plr))
                    fireUIRequest("InspectPlayer", { targetUserId = plr.UserId, targetName = plr.Name })
                    break
                end
            end
        end
    end
end)

-- ============================================================================
-- 6. #129 TOGGLEABLE STUDIO DEV SANDBOX BAR [F9] (Non-Overlapping Top-Left Lane)
-- PlayerHUD occupies (16,14) -> (368,140), so (382,14) is 100% clear of HP/Energy/EXP!
-- ============================================================================
local devPhasePillLabel = nil
if RunService:IsStudio() or workspace:GetAttribute("EnableDevSandbox") == true then
    local sandboxGui = playerGui:FindFirstChild("SkybreakDevSandboxGui") or Instance.new("ScreenGui")
    sandboxGui.Name = "SkybreakDevSandboxGui"
    sandboxGui.DisplayOrder = 45
    sandboxGui.ResetOnSpawn = false
    sandboxGui.IgnoreGuiInset = false
    sandboxGui.Parent = playerGui

    local togglePill = sandboxGui:FindFirstChild("DevSandboxToggleBtn") or Instance.new("TextButton")
    togglePill.Name = "DevSandboxToggleBtn"
    togglePill.Position = UDim2.fromOffset(446, 14)
    togglePill.Size = UDim2.fromOffset(172, 30)
    togglePill.BackgroundColor3 = PANEL_BG
    togglePill.BackgroundTransparency = 0.08
    togglePill.Font = Enum.Font.GothamBold
    togglePill.TextSize = 11
    togglePill.TextColor3 = GOLD_ACCENT
    togglePill.Text = "DEV SANDBOX [F9]"
    togglePill.Parent = sandboxGui
    if not togglePill:FindFirstChildOfClass("UIStroke") then
        styleCard(togglePill, 15, GOLD_ACCENT, 1.4)
    end
    devPhasePillLabel = togglePill

    local drawer = sandboxGui:FindFirstChild("DevSandboxDrawer") or Instance.new("Frame")
    drawer.Name = "DevSandboxDrawer"
    drawer.Position = UDim2.fromOffset(446, 50)
    drawer.Size = UDim2.fromOffset(360, 316)
    drawer.BackgroundColor3 = PANEL_BG
    drawer.BackgroundTransparency = 0.05
    drawer.BorderSizePixel = 0
    drawer.Visible = false
    drawer.Parent = sandboxGui
    if not drawer:FindFirstChildOfClass("UIStroke") then
        styleCard(drawer, 11, GOLD_ACCENT, 1.5)
    end

    makeLabel(
        drawer, "DrawerTitle", UDim2.fromOffset(12, 8), UDim2.new(1, -24, 0, 18),
        "SKYBREAK STUDIO SANDBOX • 1-CLICK QA", Enum.Font.GothamBlack, 12, GOLD_ACCENT
    )

    local ACTIONS = {
        { Label = "Full Fury & HP", Sub = "FullFuryHP" },
        { Label = "0s Cooldowns", Sub = "ZeroCooldowns" },
        { Label = "Unlock Full 100% Save", Sub = "UnlockFullSave" },
        { Label = "Spawn 3D Galleon Ship", Sub = "SpawnShip", Extra = { altSubAction = "SpawnGalleonShip", shipId = "CelestialAetherGalleon", shipMeshId = "CelestialAetherGalleon" } },
        { Label = "Spawn Boss Aureon", Sub = "SpawnBoss", Extra = { altSubAction = "SpawnBossAureon", bossId = "AureonSentinel", enemyId = "AureonSentinel" } },
        { Label = "Trigger Mirage Island", Sub = "TriggerMirage", Extra = { altSubAction = "TriggerMirageIsland" } },
        { Label = "Trigger Leviathan", Sub = "TriggerLeviathan" },
        { Label = "Inspect Self Card", Sub = "InspectSelf", LocalFn = function()
            showInspectCard(buildFallbackInspectFromPlayer(localPlayer))
        end },
        { Label = "Cycle Day/Sunset/Night", Sub = "CycleTime", Extra = { altSubAction = "CycleDayNight" }, LocalFn = function()
            devTimeOffsetSec = (devTimeOffsetSec + DAY_CYCLE_SECONDS * 0.25) % DAY_CYCLE_SECONDS
            local cam = workspace.CurrentCamera
            stepAtmosphereAndWeather(cam and cam.CFrame.Position or nil)
        end },
    }

    for idx, act in ipairs(ACTIONS) do
        local col = (idx - 1) % 2
        local row = math.floor((idx - 1) / 2)
        local btnName = "SandboxBtn_" .. act.Sub
        local btn = drawer:FindFirstChild(btnName) or Instance.new("TextButton")
        btn.Name = btnName
        btn.Position = UDim2.fromOffset(12 + col * 172, 32 + row * 38)
        btn.Size = UDim2.fromOffset(164, 32)
        btn.BackgroundColor3 = Color3.fromRGB(18, 25, 44)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 11
        btn.TextColor3 = TEXT_LIGHT
        btn.Text = act.Label
        btn.Parent = drawer
        if not btn:FindFirstChildOfClass("UIStroke") then
            styleCard(btn, 7, CYAN_ACCENT, 1.0)
        end
        btn.MouseButton1Click:Connect(function()
            playSFX("ui_click")
            if act.LocalFn then
                act.LocalFn()
            end
            local payload = { subAction = act.Sub, label = act.Label }
            if act.Extra then
                for k, v in pairs(act.Extra) do
                    payload[k] = v
                end
            end
            fireUIRequest("DevSandbox", payload)
        end)
    end

    makeLabel(
        drawer, "TeleportHeader", UDim2.fromOffset(12, 228), UDim2.new(1, -24, 0, 16),
        "QUICK TELEPORT • DỊCH CHUYỂN NHANH", Enum.Font.GothamBold, 10, GOLD_ACCENT
    )

    local TELEPORTS = {
        { Label = "Sky Hub", Id = "SkyHub", Pos = Vector3.new(-317.4, 50.5, 527.8) },
        { Label = "Cyberport Cafe", Id = "CyberportCafe", Pos = Vector3.new(9400.0, 50.9, 1785.0) },
        { Label = "Raid Lab", Id = "MicrochipRaidLab", Pos = Vector3.new(14600.0, 50.9, 1785.0) },
        { Label = "Castle Void", Id = "CastleOnTheVoid", Pos = Vector3.new(-14600.0, 50.9, 2173.1) },
    }
    for idx, tp in ipairs(TELEPORTS) do
        local col = (idx - 1) % 4
        local btnName = "QuickTP_" .. tp.Id
        local btn = drawer:FindFirstChild(btnName) or Instance.new("TextButton")
        btn.Name = btnName
        btn.Position = UDim2.fromOffset(12 + col * 85, 248)
        btn.Size = UDim2.fromOffset(81, 30)
        btn.BackgroundColor3 = Color3.fromRGB(22, 30, 52)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 10
        btn.TextColor3 = GOLD_ACCENT
        btn.Text = tp.Label
        btn.Parent = drawer
        if not btn:FindFirstChildOfClass("UIStroke") then
            styleCard(btn, 6, GOLD_ACCENT, 1.0)
        end
        btn.MouseButton1Click:Connect(function()
            playSFX("ui_click")
            playNebulaPortalWipe(tp.Pos, tp.Label:upper())
            fireUIRequest("DevSandbox", { subAction = "Teleport", islandId = tp.Id })
        end)
    end

    local statusHint = drawer:FindFirstChild("SandboxHint") or makeLabel(
        drawer, "SandboxHint", UDim2.fromOffset(12, 286), UDim2.new(1, -24, 0, 20),
        "Alt+Click người chơi bất kỳ để mở Hồ Sơ [Inspect]", Enum.Font.GothamMedium, 10, TEXT_MUTED
    )
    statusHint.TextXAlignment = Enum.TextXAlignment.Center

    local function toggleSandbox()
        drawer.Visible = not drawer.Visible
        playSFX("ui_tab")
    end

    togglePill.MouseButton1Click:Connect(toggleSandbox)
    UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == Enum.KeyCode.F9 then
            toggleSandbox()
        end
    end)
end

-- ============================================================================
-- 7. REMOTE EVENT HOOKS & MAIN RUNSERVICE.HEARTBEAT LOOP
-- ============================================================================
task.spawn(function()
    local remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
    if not remotes then
        return
    end

    local combatFX = remotes:FindFirstChild("CombatFX") or remotes:WaitForChild("CombatFX", 10)
    if combatFX and combatFX:IsA("RemoteEvent") then
        combatFX.OnClientEvent:Connect(function(fx)
            if type(fx) ~= "table" then
                return
            end
            local kind = tostring(fx.Kind or fx.kind or "")
            local action = tostring(fx.Action or fx.action or "")
            local pos = fx.Position or fx.pos

            if kind == "ChestOpened" then
                local cid = tostring(fx.ChestId or fx.chestId or "")
                local matchedAny = false
                for trigger, entry in pairs(trackedChests) do
                    local cModel = entry.ChestModel
                    if (cid ~= "" and (trigger.Name == cid or trigger:GetAttribute("ChestId") == cid or (cModel and cModel.Name == cid)))
                        or (typeof(pos) == "Vector3" and (trigger.Position - pos).Magnitude <= 8) then
                        matchedAny = true
                        entry.TargetAngleDeg = 105
                        entry.WasOpen = true
                        local tNow = os.clock()
                        if typeof(pos) == "Vector3" and (tNow - (entry.LastBurstAt or -10)) > 1.0 then
                            entry.LastBurstAt = tNow
                            spawnChestCoinBurst(pos)
                        end
                    end
                end
                if not matchedAny and typeof(pos) == "Vector3" then
                    spawnChestCoinBurst(pos)
                end
            elseif kind == "CloudGeyserRescue" or kind == "SkyGeyserRescue" or action == "CloudGeyserRescue" or action == "SkyGeyserRescue" then
                local ch = localPlayer and localPlayer.Character
                local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
                local isLocal = (fx.Actor == nil or (localPlayer and (fx.Actor == localPlayer.UserId or fx.UserId == localPlayer.UserId)))
                local vPos = (typeof(pos) == "Vector3" and pos) or (hrp and hrp.Position)
                if vPos then
                    spawnSkyGeyserVortex(vPos, isLocal and hrp or nil)
                end
            elseif kind == "PortalWarp" or action == "PortalSurge" then
                local isLocal = (localPlayer and (fx.Actor == localPlayer.UserId or fx.UserId == localPlayer.UserId))
                if isLocal then
                    playNebulaPortalWipe(fx.TargetPos or pos, fx.TargetTitle or fx.Destination)
                end
            elseif kind == "WorldBanner" then
                showWorldBanner(fx)
            elseif kind == "MVPSummary" then
                showMVPSummary(fx)
            end
        end)
    end

    local stateUpdate = remotes:FindFirstChild("StateUpdate") or remotes:WaitForChild("StateUpdate", 10)
    if stateUpdate and stateUpdate:IsA("RemoteEvent") then
        stateUpdate.OnClientEvent:Connect(function(payload)
            if type(payload) ~= "table" then
                return
            end
            if type(payload.State) == "table" then
                lastKnownSelfState = payload.State
            end
            if typeof(payload.TeleportSnap) == "Vector3" then
                local ch = localPlayer and localPlayer.Character
                local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
                if not hrp or (hrp.Position - payload.TeleportSnap).Magnitude > 200 then
                    playNebulaPortalWipe(payload.TeleportSnap, payload.DestinationTitle)
                end
            end
            if payload.WorldBanner or payload.ServerBanner or payload.GlobalEvent then
                showWorldBanner(payload.WorldBanner or payload.ServerBanner or payload.GlobalEvent)
            end
            if payload.MVPSummary or payload.BossMVP then
                showMVPSummary(payload.MVPSummary or payload.BossMVP)
            end
            if payload.InspectCard or payload.InspectProfile or payload.InspectedPlayer then
                showInspectCard(payload.InspectCard or payload.InspectProfile or payload.InspectedPlayer)
            end
        end)
    end
end)

local lastPlayerPos = nil
local lastCharacterRef = nil
local atmoAccum = 0

RunService.Heartbeat:Connect(function(dt)
    dt = math.clamp(dt, 1 / 240, 0.15)
    local now = os.clock()
    local cam = workspace.CurrentCamera
    local camPos = cam and cam.CFrame.Position or nil

    local ch = localPlayer and localPlayer.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    local playerPos = hrp and hrp.Position or nil

    -- Detect large-distance 1-frame island teleports (> 260 studs) and local Y < 10 cloud-sea updraft rescue
    if ch ~= lastCharacterRef then
        lastCharacterRef = ch
        lastPlayerPos = playerPos
    elseif playerPos then
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        local isFlying = (ch and ch:GetAttribute("SkybreakFlightActive") == true)
            or (localPlayer and localPlayer:GetAttribute("SkybreakFlightActive") == true)
        local isSeated = (hum and hum.Sit == true)
        if lastPlayerPos and (playerPos - lastPlayerPos).Magnitude > math.max(320, dt * 360) then
            playNebulaPortalWipe(playerPos)
        end
        if not isFlying and not isSeated and playerPos.Y < -18 and (not lastPlayerPos or lastPlayerPos.Y >= -18 or (now - lastGeyserVFXAt) > 2.6) then
            spawnSkyGeyserVortex(playerPos, hrp)
        end
        lastPlayerPos = playerPos
    else
        lastPlayerPos = nil
    end

    atmoAccum += dt
    if atmoAccum >= 0.08 then
        atmoAccum = 0
        stepAtmosphereAndWeather(camPos or playerPos)
        if devPhasePillLabel and devPhasePillLabel.Parent then
            devPhasePillLabel.Text = "DEV [F9] " .. currentPhaseTag
        end
    end

    stepCloudSea(camPos or playerPos, now)
    stepQuestWaypoint(playerPos, now)
    stepChestsAndCoinBursts(dt, now, playerPos)
end)
