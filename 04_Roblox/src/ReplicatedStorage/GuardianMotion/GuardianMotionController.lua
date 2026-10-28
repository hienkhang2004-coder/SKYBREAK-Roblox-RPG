-- GuardianMotion 8-Clip & Harmonic Pulse Controller (SkyGuardian • FIRE)
-- Supports 8 canonical clips with 0.18s crossfade + Elem3D_* harmonic scale/glow modulation.
local RS = game:GetService("ReplicatedStorage")
local GM = {
    ModelName = "SkyGuardian",
    ElementType = "FIRE",
    CrossfadeDuration = 0.18,
    PulseFrequencyHz = 2.5,
    HarmonicScaleMin = 0.96,
    HarmonicScaleMax = 1.12,
    AwakeningBoost = 1.18,
    PrimaryColor = Color3.new(1.0, 0.1526, 0.0049),
    SecondaryColor = Color3.new(1.0, 0.8098, 0.1769),
    CanonicalClips = {
        "Idle",
        "Walk",
        "Run",
        "Attack",
        "Skill",
        "ElementalSurge",
        "HeroicKata",
        "UltimateAwakening",
    },
    AwakeningClips = {
        ElementalSurge = true,
        HeroicKata = true,
        UltimateAwakening = true,
    },
}

local fxCache = setmetatable({}, { __mode = "k" })

local function getFX(model)
    local cached = fxCache[model]
    if cached then return cached end
    local root = model.PrimaryPart
    cached = {
        parts = {},
        partLights = {},
        auraLight = root and root:FindFirstChild("ElementalAuraLight") or nil,
    }
    for _, ch in ipairs(model:GetChildren()) do
        if ch:IsA("MeshPart") and (string.sub(ch.Name, 1, 7) == "Elem3D_" or ch:GetAttribute("EquipmentRole") == "AuraFX") then
            table.insert(cached.parts, { part = ch, baseColor = ch.Color })
            local pl = ch:FindFirstChild("ElementalPartLight")
            if pl and pl:IsA("PointLight") then
                table.insert(cached.partLights, pl)
            end
        end
    end
    fxCache[model] = cached
    return cached
end

function GM.ModulateElementalPulse(model, clipName, timeSec)
    if not model then return end
    local fx = getFX(model)
    local freq = model:GetAttribute("PulseFrequencyHz") or GM.PulseFrequencyHz
    local sMin = model:GetAttribute("HarmonicScaleMin") or GM.HarmonicScaleMin
    local sMax = model:GetAttribute("HarmonicScaleMax") or GM.HarmonicScaleMax
    local pCol = model:GetAttribute("PrimaryColorRGB") or GM.PrimaryColor
    local sCol = model:GetAttribute("SecondaryColorRGB") or GM.SecondaryColor
    local wave = 0.5 + 0.5 * math.sin((timeSec or 0) * freq * math.pi * 2)
    local isAwakening = GM.AwakeningClips[tostring(clipName or "")] == true
    local boost = isAwakening and GM.AwakeningBoost or 1.0
    local harmonic = (sMin + (sMax - sMin) * wave) * boost

    if fx.auraLight then
        fx.auraLight.Brightness = 2.8 * harmonic
        fx.auraLight.Range = 15.0 * harmonic
    end
    for _, pl in ipairs(fx.partLights) do
        pl.Brightness = 2.6 * harmonic
        pl.Range = 11.0 * harmonic
    end
    for idx, entry in ipairs(fx.parts) do
        local pt = entry.part
        if pt and pt.Parent then
            local phaseWave = 0.5 + 0.5 * math.sin((timeSec or 0) * freq * math.pi * 2 + idx * 0.45)
            pt.Transparency = math.clamp(0.14 - 0.10 * phaseWave, 0.02, 0.22)
            if pCol and sCol then
                pt.Color = entry.baseColor:Lerp(sCol, 0.28 * phaseWave)
            end
        end
    end
end

function GM.Step(model, clipsTable, clipName, timeSec)
    if not model or not clipsTable then return end
    local resolvedName = clipName or "Idle"
    local clip = clipsTable[resolvedName] or clipsTable.Idle
    GM.ModulateElementalPulse(model, resolvedName, timeSec)
    local renMod = RS:FindFirstChild("DelegatedV5Renderer")
    if renMod and clip then
        local ren = require(renMod)
        ren.Pose(model, clip, timeSec or 0)
    end
end

return GM
