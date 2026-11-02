-- SKYBREAK: Fragments of the Core - 3D Spatial Audio Engine & Dynamic BGM Crossfader (#27)
-- Preserves full API compatibility: Audio.Bind, Audio.AudioGroup, Audio.PlaySFX, Audio.UpdateBGM

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

local Audio = {}

local AudioGroup = SoundService:FindFirstChild("SkybreakAudioEngine")
if not AudioGroup then
    AudioGroup = Instance.new("SoundGroup")
    AudioGroup.Name = "SkybreakAudioEngine"
    AudioGroup.Volume = 1
    AudioGroup.Parent = SoundService
end
Audio.AudioGroup = AudioGroup

Audio.SFX_Specs = {
    ui_hover = { Id = "rbxassetid://12221967", Fallback = "rbxassetid://12221967", Vol = 0.22, Speed = 1.45, IsUI = true },
    ui_click = { Id = "rbxassetid://12221967", Fallback = "rbxassetid://12221967", Vol = 0.42, Speed = 1.08, IsUI = true },
    ui_tab = { Id = "rbxassetid://9126283272", Fallback = "rbxassetid://12222200", Vol = 0.38, Speed = 1.22, IsUI = true },
    sword_swing_1 = { Id = "rbxassetid://9119747260", Fallback = "rbxassetid://12222216", Vol = 0.58, Speed = 1.06 },
    sword_swing_2 = { Id = "rbxassetid://9120742716", Fallback = "rbxassetid://12222200", Vol = 0.60, Speed = 1.14 },
    sword_swing_3 = { Id = "rbxassetid://9114465041", Fallback = "rbxassetid://12222225", Vol = 0.66, Speed = 1.18 },
    heavy_cleave = { Id = "rbxassetid://9116673678", Fallback = "rbxassetid://12222216", Vol = 0.74, Speed = 0.96, Reverb = 0.30 },
    dodge_dash = { Id = "rbxassetid://9126283592", Fallback = "rbxassetid://12222200", Vol = 0.54, Speed = 1.18 },
    geppo_step = { Id = "rbxassetid://9120008202", Fallback = "rbxassetid://9126283592", Vol = 0.56, Speed = 1.24 },
    flash_step = { Id = "rbxassetid://9116279560", Fallback = "rbxassetid://9126283592", Vol = 0.64, Speed = 1.15 },
    land_impact = { Id = "rbxassetid://9113525391", Fallback = "rbxassetid://9113564868", Vol = 0.48, Speed = 1.05 },
    hit_normal = { Id = "rbxassetid://9113564868", Fallback = "rbxassetid://12222216", Vol = 0.58, Speed = 1.08 },
    hit_crit = { Id = "rbxassetid://9116673944", Fallback = "rbxassetid://9116673678", Vol = 0.76, Speed = 1.15, PitchOctave = 1.15 },
    hit_break = { Id = "rbxassetid://9120369181", Fallback = "rbxassetid://9116673678", Vol = 0.82, Speed = 0.92, Reverb = 0.40 },
    skill_sky_slash = { Id = "rbxassetid://9114463219", Fallback = "rbxassetid://9120742716", Vol = 0.68, Speed = 1.12, Reverb = 0.32 },
    skill_guardian_shield = { Id = "rbxassetid://9114257451", Fallback = "rbxassetid://9125674114", Vol = 0.66, Speed = 1.0, Reverb = 0.45 },
    skill_judgment_strike = { Id = "rbxassetid://9120021539", Fallback = "rbxassetid://12222030", Vol = 0.80, Speed = 0.98, Reverb = 0.42 },
    skill_thunder_strike = { Id = "rbxassetid://9120021794", Fallback = "rbxassetid://9120021539", Vol = 0.78, Speed = 1.16 },
    skill_frost_shatter = { Id = "rbxassetid://9116394876", Fallback = "rbxassetid://9114369623", Vol = 0.72, Speed = 1.20, Reverb = 0.40 },
    skill_void_rift = { Id = "rbxassetid://9125484367", Fallback = "rbxassetid://9125484743", Vol = 0.84, Speed = 0.88, Reverb = 0.50 },
    flame_burst = { Id = "rbxassetid://9120009360", Fallback = "rbxassetid://9114463219", Vol = 0.76, Speed = 1.06, Reverb = 0.32 },
    magma_erupt = { Id = "rbxassetid://9112823552", Fallback = "rbxassetid://9120009360", Vol = 0.80, Speed = 0.94, Reverb = 0.42 },
    light_beam = { Id = "rbxassetid://9118792735", Fallback = "rbxassetid://9116279560", Vol = 0.72, Speed = 1.18, Reverb = 0.35 },
    gravity_crush = { Id = "rbxassetid://9113551901", Fallback = "rbxassetid://9125484367", Vol = 0.82, Speed = 0.90, Reverb = 0.48 },
    portal_warp = { Id = "rbxassetid://9114341891", Fallback = "rbxassetid://9114257451", Vol = 0.72, Speed = 1.08, Reverb = 0.42 },
    haki_conqueror = { Id = "rbxassetid://9113552058", Fallback = "rbxassetid://9125484367", Vol = 0.86, Speed = 0.86, Reverb = 0.55 },
    haki_instinct = { Id = "rbxassetid://9125644311", Fallback = "rbxassetid://9116394876", Vol = 0.64, Speed = 1.08, Reverb = 0.40 },
    boss_telegraph = { Id = "rbxassetid://9114024787", Fallback = "rbxassetid://9114024708", Vol = 0.60, Speed = 1.0 },
    boss_roar = { Id = "rbxassetid://9113980319", Fallback = "rbxassetid://9113980507", Vol = 0.85, Speed = 0.86, Reverb = 0.55 },
    level_up = { Id = "rbxassetid://1836473422", Fallback = "rbxassetid://1836473398", Vol = 0.76, Speed = 1.0, Reverb = 0.35 },
    quest_complete = { Id = "rbxassetid://112234886947497", Fallback = "rbxassetid://1836473422", Vol = 0.74, Speed = 1.0, Reverb = 0.35 },
    forge_anvil = { Id = "rbxassetid://9113447467", Fallback = "rbxassetid://9113447116", Vol = 0.76, Speed = 1.02, Reverb = 0.30 },
    potion_heal = { Id = "rbxassetid://9114369623", Fallback = "rbxassetid://9116394876", Vol = 0.66, Speed = 1.12, Reverb = 0.32 },
    chest_open = { Id = "rbxassetid://9114776898", Fallback = "rbxassetid://1836473422", Vol = 0.74, Speed = 1.05, Reverb = 0.35 },
    shrine_bless = { Id = "rbxassetid://9116394876", Fallback = "rbxassetid://9114369623", Vol = 0.74, Speed = 0.96, Reverb = 0.50 },
    cloud_geyser = { Id = "rbxassetid://9126283592", Fallback = "rbxassetid://9114341891", Vol = 0.76, Speed = 0.84, Reverb = 0.44 },
    coin_collect = { Id = "rbxassetid://9114369623", Fallback = "rbxassetid://12221967", Vol = 0.52, Speed = 1.38, Reverb = 0.22 },
    world_banner = { Id = "rbxassetid://9114257451", Fallback = "rbxassetid://1836473422", Vol = 0.68, Speed = 0.94, Reverb = 0.40, IsUI = true },
    nebula_wipe = { Id = "rbxassetid://9114341891", Fallback = "rbxassetid://9114257451", Vol = 0.62, Speed = 0.98, Reverb = 0.38, IsUI = true },
    npc_greet = { Id = "rbxassetid://9126283272", Fallback = "rbxassetid://12221967", Vol = 0.34, Speed = 1.12 },
    ship_cannon = { Id = "rbxassetid://9112823552", Fallback = "rbxassetid://9116673678", Vol = 0.82, Speed = 0.92, Reverb = 0.38 },
}

Audio.BGM_Specs = {
    GoldenSky = { Id = "rbxassetid://1846800656", Vol = 0.28, Speed = 1.0, WindSpeed = 0.85, HarmonicSpeed = 1.00 },
    FrozenCyber = { Id = "rbxassetid://9042466902", Vol = 0.28, Speed = 1.0, WindSpeed = 0.96, HarmonicSpeed = 1.12 },
    ShadowRealm = { Id = "rbxassetid://1840777443", Vol = 0.30, Speed = 1.0, WindSpeed = 0.74, HarmonicSpeed = 0.86 },
    VerdantCrown = { Id = "rbxassetid://9038472201", Vol = 0.28, Speed = 1.0, WindSpeed = 0.84, HarmonicSpeed = 1.04 },
    EmberforgeWastes = { Id = "rbxassetid://1843821342", Vol = 0.30, Speed = 1.0, WindSpeed = 0.78, HarmonicSpeed = 0.90 },
    AbyssalTides = { Id = "rbxassetid://1841333389", Vol = 0.28, Speed = 1.0, WindSpeed = 0.80, HarmonicSpeed = 0.94 },
    ChronosBastion = { Id = "rbxassetid://9047776050", Vol = 0.28, Speed = 1.0, WindSpeed = 0.88, HarmonicSpeed = 1.06 },
    VeilsEnd = { Id = "rbxassetid://9046506025", Vol = 0.32, Speed = 1.0, WindSpeed = 0.72, HarmonicSpeed = 0.82 },
    BossBattle = { Id = "rbxassetid://1846800615", Vol = 0.34, Speed = 1.05, WindSpeed = 0.92, HarmonicSpeed = 1.00 },
}

local BOSS_IDS = {
    AureonSentinel = true,
    CryonPrime = true,
    Noxar = true,
    AbyssalLeviathan = true,
    SkySeaBeast = true,
    PirateCaptainVance = true,
    VanceBoss = true,
    OrderCyborg = true,
    OrderCyborgBoss = true,
    SoulReaperRift = true,
    SkyHubWatchCommander = true,
    ShrineGuardianBoss = true,
    AetherArchonBoss = true,
    SolarHighPriestBoss = true,
    CyberSyndicateBoss = true,
    PermafrostWardenBoss = true,
    VoidCastellanBoss = true,
    UmbralArchfiendBoss = true,
    Sylvaris = true,
    Ignivar = true,
    Nerith = true,
    Aion = true,
    Veyr = true,
}

local SPATIAL_POOL_SIZE = 24
local UI_POOL_SIZE = 12
local SPATIAL_PARK_POS = Vector3.new(0, -5000, 0)
local BOSS_PROXIMITY_STUDS = 75
local BOSS_COMBAT_HOLD_SEC = 8.0
local BGM_CROSSFADE_SEC = 1.8

local lastSfxTime = {}
local currentBgmTrack = ""
local desiredExplorationTrack = "GoldenSky"
local activeBgmSound = nil
local activeWindSound = nil
local activeHarmonicSound = nil
local uiRef = nil
local tempFXRef = nil

local spatialPoolFolder = nil
local spatialPool = {}
local spatialCursor = 0

local uiSoundFolder = nil
local uiSoundPool = {}
local uiSoundCursor = 0

local bossCombatUntil = 0
local bossHitCache = setmetatable({}, { __mode = "k" })
local lastLocalHealth = nil

local function resolveTempFX()
    if tempFXRef and tempFXRef.Parent then
        return tempFXRef
    end
    local existing = workspace:FindFirstChild("TempFX")
    if not existing then
        existing = Instance.new("Folder")
        existing.Name = "TempFX"
        existing.Parent = workspace
    end
    tempFXRef = existing
    return existing
end

local function createSoundEffects(soundObj)
    local ps = Instance.new("PitchShiftSoundEffect")
    ps.Name = "PoolPitchShift"
    ps.Enabled = false
    ps.Octave = 1.0
    ps.Parent = soundObj

    local rev = Instance.new("ReverbSoundEffect")
    rev.Name = "PoolReverb"
    rev.Enabled = false
    rev.WetLevel = -3
    rev.DecayTime = 1.8
    rev.Parent = soundObj

    local dist = Instance.new("DistortionSoundEffect")
    dist.Name = "PoolDistortion"
    dist.Enabled = false
    dist.Level = 0.2
    dist.Parent = soundObj

    return ps, rev, dist
end

local function ensureSpatialPool()
    local rootFolder = resolveTempFX()
    if not spatialPoolFolder or not spatialPoolFolder.Parent then
        spatialPoolFolder = rootFolder:FindFirstChild("SpatialAudioPool")
        if not spatialPoolFolder then
            spatialPoolFolder = Instance.new("Folder")
            spatialPoolFolder.Name = "SpatialAudioPool"
            spatialPoolFolder.Parent = rootFolder
        end
    end
    if #spatialPool >= SPATIAL_POOL_SIZE and spatialPool[1] and spatialPool[1].Part and spatialPool[1].Part.Parent then
        return spatialPoolFolder
    end
    table.clear(spatialPool)
    for i = 1, SPATIAL_POOL_SIZE do
        local partName = string.format("SpatialEmitter_%02d", i)
        local p = spatialPoolFolder:FindFirstChild(partName)
        if not p then
            p = Instance.new("Part")
            p.Name = partName
            p.Size = Vector3.new(0.2, 0.2, 0.2)
            p.Position = SPATIAL_PARK_POS
            p.Transparency = 1
            p.Anchored = true
            p.CanCollide = false
            p.CanQuery = false
            p.CanTouch = false
            p.CastShadow = false
            p.Massless = true
            p.Parent = spatialPoolFolder
        end
        local att = p:FindFirstChild("EmitterAttachment")
        if not att then
            att = Instance.new("Attachment")
            att.Name = "EmitterAttachment"
            att.Parent = p
        end
        local snd = att:FindFirstChild("SpatialSound")
        local ps, rev, dist
        if not snd then
            snd = Instance.new("Sound")
            snd.Name = "SpatialSound"
            snd.SoundGroup = AudioGroup
            snd.RollOffMode = Enum.RollOffMode.InverseTapered
            snd.RollOffMinDistance = 10
            snd.RollOffMaxDistance = 165
            snd.Looped = false
            ps, rev, dist = createSoundEffects(snd)
            snd.Parent = att
        else
            snd.RollOffMode = Enum.RollOffMode.InverseTapered
            snd.RollOffMinDistance = 10
            snd.RollOffMaxDistance = 165
            ps = snd:FindFirstChild("PoolPitchShift")
            rev = snd:FindFirstChild("PoolReverb")
            dist = snd:FindFirstChild("PoolDistortion")
            if not ps or not rev or not dist then
                ps, rev, dist = createSoundEffects(snd)
            end
        end
        spatialPool[i] = {
            Index = i,
            Part = p,
            Attachment = att,
            Sound = snd,
            Pitch = ps,
            Reverb = rev,
            Distortion = dist,
            BusyUntil = 0,
            Token = 0,
        }
    end
    return spatialPoolFolder
end

local function ensureUIPool()
    if not uiSoundFolder or not uiSoundFolder.Parent then
        uiSoundFolder = AudioGroup:FindFirstChild("UISoundPool")
        if not uiSoundFolder then
            uiSoundFolder = Instance.new("Folder")
            uiSoundFolder.Name = "UISoundPool"
            uiSoundFolder.Parent = AudioGroup
        end
    end
    if #uiSoundPool >= UI_POOL_SIZE and uiSoundPool[1] and uiSoundPool[1].Sound and uiSoundPool[1].Sound.Parent then
        return uiSoundFolder
    end
    table.clear(uiSoundPool)
    for i = 1, UI_POOL_SIZE do
        local sName = string.format("UISound_%02d", i)
        local snd = uiSoundFolder:FindFirstChild(sName)
        local ps, rev, dist
        if not snd then
            snd = Instance.new("Sound")
            snd.Name = sName
            snd.SoundGroup = AudioGroup
            snd.Looped = false
            ps, rev, dist = createSoundEffects(snd)
            snd.Parent = uiSoundFolder
        else
            ps = snd:FindFirstChild("PoolPitchShift")
            rev = snd:FindFirstChild("PoolReverb")
            dist = snd:FindFirstChild("PoolDistortion")
            if not ps or not rev or not dist then
                ps, rev, dist = createSoundEffects(snd)
            end
        end
        uiSoundPool[i] = {
            Sound = snd,
            Pitch = ps,
            Reverb = rev,
            Distortion = dist,
            BusyUntil = 0,
            Token = 0,
        }
    end
    return uiSoundFolder
end

function Audio.Bind(uiModule, tempFXFolder)
    uiRef = uiModule
    if tempFXFolder then
        tempFXRef = tempFXFolder
    end
    ensureSpatialPool()
    ensureUIPool()
end

local function isAudioMuted()
    local lp = Players.LocalPlayer
    if lp and lp:GetAttribute("AudioMuted") == true then
        return true
    end
    local mVol = lp and tonumber(lp:GetAttribute("MasterVolume"))
    if mVol ~= nil and mVol <= 0 then
        return true
    end
    return uiRef and uiRef.Muted == true
end

local function normalizeVolumeMul(raw, defaultMul)
    local v = tonumber(raw)
    if v == nil then
        return defaultMul or 1.0
    end
    if v > 1.5 then
        v = v / 100.0
    end
    return math.clamp(v, 0, 1.5)
end

local function computeNaturalPitchAndVolume(spec, pitchJitter, isSpatial)
    local baseSpeed = spec.Speed or 1.0
    local baseVol = spec.Vol or 0.55

    -- Natural +/-4%..7% pitch variance for combat/spatial SFX so rapid M1 combos never sound robotic
    local sign = (math.random(0, 1) == 1) and 1 or -1
    local pct
    if spec.IsUI and not isSpatial then
        local maxUi = pitchJitter or 0.025
        pct = sign * (0.01 + math.random() * math.max(0.01, maxUi - 0.01))
    else
        local minJ = 0.04
        local maxJ = math.max(0.07, tonumber(pitchJitter) or 0.07)
        pct = sign * (minJ + math.random() * (maxJ - minJ))
    end
    local speed = math.clamp(baseSpeed * (1 + pct), 0.4, 2.4)

    -- Subtle +/-5% micro-volume variance
    local volMul = spec.IsUI and (0.98 + math.random() * 0.04) or (0.95 + math.random() * 0.10)
    return speed, baseVol * volMul
end

local function configureNodeEffects(node, spec)
    if node.Pitch then
        if spec.PitchOctave then
            node.Pitch.Octave = spec.PitchOctave
            node.Pitch.Enabled = true
        else
            node.Pitch.Enabled = false
        end
    end
    if node.Reverb then
        if spec.Reverb then
            node.Reverb.WetLevel = -6 + spec.Reverb * 6
            node.Reverb.DecayTime = 1.4 + spec.Reverb * 1.5
            node.Reverb.Enabled = true
        else
            node.Reverb.Enabled = false
        end
    end
    if node.Distortion then
        if spec.Distortion then
            node.Distortion.Level = spec.Distortion
            node.Distortion.Enabled = true
        else
            node.Distortion.Enabled = false
        end
    end
end

local function acquirePoolNode(pool, cursor, now)
    local count = #pool
    for offset = 1, count do
        local idx = ((cursor + offset - 1) % count) + 1
        local candidate = pool[idx]
        if candidate and (now >= candidate.BusyUntil or not candidate.Sound.IsPlaying) then
            return candidate, idx
        end
    end
    local nextIdx = (cursor % count) + 1
    return pool[nextIdx], nextIdx
end

function Audio.PlaySFX(sfxName, worldPos, pitchJitter)
    if isAudioMuted() then
        return
    end
    local key = tostring(sfxName or "ui_click")
    local spec = Audio.SFX_Specs[key] or Audio.SFX_Specs.ui_click
    local now = os.clock()
    local minGap = (key == "ui_hover" and 0.04) or (key:find("hit_") and 0.032) or 0.018
    if now - (lastSfxTime[key] or 0) < minGap then
        return
    end
    lastSfxTime[key] = now

    local player = Players.LocalPlayer
    local isSpatial = (typeof(worldPos) == "Vector3")
    if isSpatial then
        local listenerPos = nil
        local ch = player and player.Character
        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
        if hrp then
            listenerPos = hrp.Position
        elseif workspace.CurrentCamera then
            listenerPos = workspace.CurrentCamera.CFrame.Position
        end
        if listenerPos and (listenerPos - worldPos).Magnitude > 165 then
            return
        end
    end

    local masterMul = normalizeVolumeMul(player and player:GetAttribute("MasterVolume"), 1.0)
    local sfxMul = normalizeVolumeMul(player and player:GetAttribute("SFXVolume"), 1.0)
    local speed, jitteredVol = computeNaturalPitchAndVolume(spec, pitchJitter, isSpatial)
    local finalVolume = math.clamp(jitteredVol * masterMul * sfxMul, 0, 2.0)

    local node
    if isSpatial then
        ensureSpatialPool()
        node, spatialCursor = acquirePoolNode(spatialPool, spatialCursor, now)
        if not node or not node.Part or not node.Sound then
            return
        end
        node.Part.Position = worldPos
        node.Sound.RollOffMode = Enum.RollOffMode.InverseTapered
        node.Sound.RollOffMinDistance = 10
        node.Sound.RollOffMaxDistance = 165
    else
        ensureUIPool()
        node, uiSoundCursor = acquirePoolNode(uiSoundPool, uiSoundCursor, now)
        if not node or not node.Sound then
            return
        end
    end

    node.Token += 1
    local token = node.Token
    node.BusyUntil = now + 2.4

    local s = node.Sound
    if s.IsPlaying then
        s:Stop()
    end
    configureNodeEffects(node, spec)
    s.SoundId = spec.Id
    s.Volume = finalVolume
    s.PlaybackSpeed = speed
    s.TimePosition = 0
    s:Play()

    task.delay(0.55, function()
        if node.Token ~= token or not s.Parent or isAudioMuted() then
            return
        end
        if not s.IsLoaded and spec.Fallback and spec.Fallback ~= spec.Id then
            s.SoundId = spec.Fallback
            s:Play()
        end
    end)

    if isSpatial then
        task.delay(2.5, function()
            if node.Token == token and node.Part and node.Part.Parent and not s.IsPlaying then
                node.Part.Position = SPATIAL_PARK_POS
                node.BusyUntil = 0
            end
        end)
    end
end

local function resolveRealmExplorationTrack()
    local lp = Players.LocalPlayer
    local realm = lp and tostring(lp:GetAttribute("CurrentRealm") or "") or ""
    if realm == "SkyHub" or realm == "" then
        realm = "GoldenSky"
    end
    if Audio.BGM_Specs[realm] and realm ~= "BossBattle" then
        return realm
    end
    return desiredExplorationTrack or "GoldenSky"
end

local function isBossModel(mdl)
    if not mdl or not mdl:IsA("Model") then
        return false
    end
    if mdl:GetAttribute("EnemyDead") == true then
        return false
    end
    local hp = tonumber(mdl:GetAttribute("HP") or mdl:GetAttribute("Health"))
    if hp and hp <= 0 then
        return false
    end
    if mdl:GetAttribute("IsBoss") == true or mdl:GetAttribute("Boss") == true or mdl:GetAttribute("BossPhase") ~= nil then
        return true
    end
    local enemyId = tostring(mdl:GetAttribute("EnemyId") or mdl:GetAttribute("BossId") or mdl.Name)
    if BOSS_IDS[enemyId] then
        return true
    end
    if enemyId:find("Boss") or enemyId:find("Leviathan") or enemyId:find("Aureon") or enemyId:find("Cryon") or enemyId:find("Noxar") then
        return true
    end
    return false
end

local function scanBossProximityAndCombat(now)
    local lp = Players.LocalPlayer
    if not lp then
        return false
    end
    if lp:GetAttribute("RaidActive") == true then
        bossCombatUntil = math.max(bossCombatUntil, now + BOSS_COMBAT_HOLD_SEC)
        return true
    end
    local ch = lp.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if not hrp then
        lastLocalHealth = nil
        return now < bossCombatUntil
    end

    local curHealth = hum and hum.Health or nil
    local tookDamage = (lastLocalHealth ~= nil and curHealth ~= nil and curHealth < lastLocalHealth - 0.5)
    lastLocalHealth = curHealth

    local playerPos = hrp.Position
    local anyBossWithin75 = false
    local anyBossWithin115 = false

    for _, folderName in ipairs({ "ActiveEnemies", "ActiveBosses" }) do
        local f = workspace:FindFirstChild(folderName)
        if f then
            for _, child in ipairs(f:GetChildren()) do
                if isBossModel(child) then
                    local bPart = child.PrimaryPart or child:FindFirstChild("Body") or child:FindFirstChild("Root") or child:FindFirstChildWhichIsA("BasePart")
                    if bPart then
                        local dist = (bPart.Position - playerPos).Magnitude
                        if dist <= 115 then
                            anyBossWithin115 = true
                            local hitAt = tonumber(child:GetAttribute("EnemyHitAt")) or 0
                            local prevHit = bossHitCache[child]
                            if prevHit == nil then
                                bossHitCache[child] = hitAt
                            elseif hitAt ~= prevHit then
                                bossHitCache[child] = hitAt
                                bossCombatUntil = math.max(bossCombatUntil, now + BOSS_COMBAT_HOLD_SEC)
                            end
                        end
                        if dist <= BOSS_PROXIMITY_STUDS then
                            anyBossWithin75 = true
                            bossCombatUntil = math.max(bossCombatUntil, now + BOSS_COMBAT_HOLD_SEC)
                        end
                    end
                end
            end
        end
    end

    if tookDamage and anyBossWithin115 then
        bossCombatUntil = math.max(bossCombatUntil, now + BOSS_COMBAT_HOLD_SEC)
    end

    return anyBossWithin75 or (now < bossCombatUntil)
end

function Audio.NotifyBossCombat(holdSeconds)
    local dur = tonumber(holdSeconds) or BOSS_COMBAT_HOLD_SEC
    bossCombatUntil = math.max(bossCombatUntil, os.clock() + dur)
end

local function applyBgmCrossfade(targetTrack)
    if isAudioMuted() then
        if activeBgmSound then
            activeBgmSound.Volume = 0
        end
        if activeWindSound then
            activeWindSound.Volume = 0
        end
        if activeHarmonicSound then
            activeHarmonicSound.Volume = 0
        end
        return
    end

    local player = Players.LocalPlayer
    local masterMul = normalizeVolumeMul(player and player:GetAttribute("MasterVolume"), 1.0)
    local bgmMul = normalizeVolumeMul(player and player:GetAttribute("BGMVolume"), 1.0) * masterMul
    local spec = Audio.BGM_Specs[targetTrack] or Audio.BGM_Specs.GoldenSky

    -- Regional ambient wind & harmonic sky layer
    if not activeWindSound or not activeWindSound.Parent then
        activeWindSound = Instance.new("Sound")
        activeWindSound.Name = "SkybreakAmbientWind"
        activeWindSound.SoundId = "rbxassetid://9119462416"
        activeWindSound.SoundGroup = AudioGroup
        activeWindSound.Looped = true
        activeWindSound.Volume = 0.075 * bgmMul
        activeWindSound.PlaybackSpeed = spec.WindSpeed or 0.85
        activeWindSound.Parent = AudioGroup
        activeWindSound:Play()
    else
        TweenService:Create(
            activeWindSound,
            TweenInfo.new(BGM_CROSSFADE_SEC, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {
                Volume = ((targetTrack == "BossBattle") and 0.045 or 0.078) * bgmMul,
                PlaybackSpeed = spec.WindSpeed or 0.85,
            }
        ):Play()
    end

    if not activeHarmonicSound or not activeHarmonicSound.Parent then
        activeHarmonicSound = Instance.new("Sound")
        activeHarmonicSound.Name = "SkybreakRegionalHarmonic"
        activeHarmonicSound.SoundId = "rbxassetid://9114257451"
        activeHarmonicSound.SoundGroup = AudioGroup
        activeHarmonicSound.Looped = true
        activeHarmonicSound.Volume = ((targetTrack == "BossBattle") and 0.01 or 0.032) * bgmMul
        activeHarmonicSound.PlaybackSpeed = (spec.HarmonicSpeed or 1.0) * 0.65
        local rev = Instance.new("ReverbSoundEffect")
        rev.WetLevel = 0
        rev.DecayTime = 2.6
        rev.Parent = activeHarmonicSound
        activeHarmonicSound.Parent = AudioGroup
        activeHarmonicSound:Play()
    else
        TweenService:Create(
            activeHarmonicSound,
            TweenInfo.new(BGM_CROSSFADE_SEC, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {
                Volume = ((targetTrack == "BossBattle") and 0.008 or 0.032) * bgmMul,
                PlaybackSpeed = (spec.HarmonicSpeed or 1.0) * 0.65,
            }
        ):Play()
    end

    if currentBgmTrack == targetTrack and activeBgmSound and activeBgmSound.Parent then
        TweenService:Create(
            activeBgmSound,
            TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
            { Volume = spec.Vol * bgmMul }
        ):Play()
        if not activeBgmSound.IsPlaying then
            activeBgmSound:Play()
        end
        return
    end

    currentBgmTrack = targetTrack
    AudioGroup:SetAttribute("ActiveBGMTrack", targetTrack)

    if activeBgmSound and activeBgmSound.Parent then
        local old = activeBgmSound
        TweenService:Create(
            old,
            TweenInfo.new(BGM_CROSSFADE_SEC, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            { Volume = 0 }
        ):Play()
        Debris:AddItem(old, BGM_CROSSFADE_SEC + 0.15)
    end

    local bgm = Instance.new("Sound")
    bgm.Name = "SkybreakBGM_" .. targetTrack
    bgm.SoundId = spec.Id
    bgm.SoundGroup = AudioGroup
    bgm.Looped = true
    bgm.Volume = 0
    bgm.PlaybackSpeed = spec.Speed or 1.0
    bgm.Parent = AudioGroup
    bgm:Play()
    TweenService:Create(
        bgm,
        TweenInfo.new(BGM_CROSSFADE_SEC, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
        { Volume = spec.Vol * bgmMul }
    ):Play()
    activeBgmSound = bgm
end

function Audio.UpdateBGM(trackKey)
    local requested = tostring(trackKey or "")
    if requested ~= "" and requested ~= "BossBattle" and Audio.BGM_Specs[requested] then
        desiredExplorationTrack = requested
    else
        desiredExplorationTrack = resolveRealmExplorationTrack()
    end

    local now = os.clock()
    local inBossCombat = scanBossProximityAndCombat(now)
    local resolvedTrack = inBossCombat and "BossBattle" or desiredExplorationTrack
    applyBgmCrossfade(resolvedTrack)
end

-- Continuous Heartbeat monitor for smooth 75-stud Boss proximity & 8s post-combat BGM decay (#27)
local bgmPollAccum = 0
local wasAudioMuted = false
local lastAppliedBgmGain = -1
RunService.Heartbeat:Connect(function(dt)
    bgmPollAccum += dt
    if bgmPollAccum < 0.25 then
        return
    end
    bgmPollAccum = 0

    if isAudioMuted() then
        wasAudioMuted = true
        if activeBgmSound and activeBgmSound.Volume > 0 then
            activeBgmSound.Volume = 0
        end
        if activeWindSound and activeWindSound.Volume > 0 then
            activeWindSound.Volume = 0
        end
        if activeHarmonicSound and activeHarmonicSound.Volume > 0 then
            activeHarmonicSound.Volume = 0
        end
        return
    end

    local lp = Players.LocalPlayer
    local masterMul = normalizeVolumeMul(lp and lp:GetAttribute("MasterVolume"), 1.0)
    local bgmGain = normalizeVolumeMul(lp and lp:GetAttribute("BGMVolume"), 1.0) * masterMul

    desiredExplorationTrack = resolveRealmExplorationTrack()
    local inBoss = scanBossProximityAndCombat(os.clock())
    local target = inBoss and "BossBattle" or desiredExplorationTrack
    if wasAudioMuted or math.abs(bgmGain - lastAppliedBgmGain) > 0.005 or currentBgmTrack ~= target or not activeBgmSound or not activeBgmSound.Parent then
        wasAudioMuted = false
        lastAppliedBgmGain = bgmGain
        applyBgmCrossfade(target)
    end
end)

task.spawn(function()
    ensureSpatialPool()
    ensureUIPool()
    local ContentProvider = game:GetService("ContentProvider")
    local sfxFolder = AudioGroup:FindFirstChild("SFXLibrary")
    if not sfxFolder then
        sfxFolder = Instance.new("Folder")
        sfxFolder.Name = "SFXLibrary"
        sfxFolder.Parent = AudioGroup
    end
    local bgmFolder = AudioGroup:FindFirstChild("BGMLibrary")
    if not bgmFolder then
        bgmFolder = Instance.new("Folder")
        bgmFolder.Name = "BGMLibrary"
        bgmFolder.Parent = AudioGroup
    end
    local preloadList = {}
    for sfxName, spec in pairs(Audio.SFX_Specs) do
        local s = sfxFolder:FindFirstChild(sfxName) or Instance.new("Sound")
        s.Name = sfxName
        s.SoundId = spec.Id
        s.Volume = spec.Vol or 0.55
        s.PlaybackSpeed = spec.Speed or 1.0
        s.SoundGroup = AudioGroup
        s.Parent = sfxFolder
        table.insert(preloadList, s)
    end
    for bgmName, spec in pairs(Audio.BGM_Specs) do
        local s = bgmFolder:FindFirstChild(bgmName) or Instance.new("Sound")
        s.Name = bgmName
        s.SoundId = spec.Id
        s.Volume = spec.Vol or 0.28
        s.PlaybackSpeed = spec.Speed or 1.0
        s.Looped = true
        s.SoundGroup = AudioGroup
        s.Parent = bgmFolder
        table.insert(preloadList, s)
    end
    pcall(function()
        ContentProvider:PreloadAsync(preloadList)
    end)
end)

return Audio
