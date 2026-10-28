local Players=game:GetService("Players")
local CAS=game:GetService("ContextActionService")
local UIS=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local Tween=game:GetService("TweenService")
local Debris=game:GetService("Debris")
local Lighting=game:GetService("Lighting")
local SoundService=game:GetService("SoundService")

local player=Players.LocalPlayer
local C=require(game.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local remotes=game.ReplicatedStorage:WaitForChild("Remotes")
for _,name in ipairs({"CombatRequest","AbilityRequest","InteractRequest","StateUpdate","EquipmentRequest","CombatFX"}) do
    remotes:WaitForChild(name)
end
local UI=require(script.Parent:WaitForChild("UI"):WaitForChild("Interface"))
local GuardianAnimator=require(script.Parent:WaitForChild("GuardianAnimator"))
GuardianAnimator.Init()

local tempFX=workspace:FindFirstChild("TempFX")
if not tempFX then
    tempFX=Instance.new("Folder")
    tempFX.Name="TempFX"
    tempFX.Parent=workspace
end

local held=nil
local heavySent=false
local attackToken=0
local fxCount=0
local nearby=nil
local lockedTarget=nil
local lockReticle=nil
local shakeToken=0
local currentShakeOffset=Vector3.zero
local lastTransformState=""

local DEFAULT_SKILLS={
    SkyGuardian={"SkySlash","GuardianShield","JudgmentStrike","CelestialAegis"},
    ThunderStriker={"ArcCut","FlashStep","StormBlitz","ThunderJudgement"},
    ArcaneMage={"FrostBolt","ManaBarrier","ArcaneComet","AstralCataclysm"},
}

local SKILL_SLOT_INDEX={
    Skill1=1,
    SkySlash=1,
    Skill2=2,
    GuardianShield=2,
    Skill3=3,
    Ultimate=4,
}

-- ============================================================================
-- 0. PROCEDURAL DSP SOUND FX & DYNAMIC BGM SYNTHESIZER ENGINE
-- ============================================================================
local AudioGroup=SoundService:FindFirstChild("SkybreakAudioEngine")
if not AudioGroup then
    AudioGroup=Instance.new("SoundGroup")
    AudioGroup.Name="SkybreakAudioEngine"
    AudioGroup.Volume=1
    AudioGroup.Parent=SoundService
end

local SFX_Specs={
    ui_hover={Id="rbxasset://sounds/skybreak/ui_hover.wav", Fallback="rbxasset://sounds/volume_slider.ogg", Vol=0.28, Speed=1.35},
    ui_click={Id="rbxasset://sounds/skybreak/ui_click.wav", Fallback="rbxasset://sounds/action_footsteps_plastic.mp3", Vol=0.45, Speed=1.25},
    ui_tab={Id="rbxasset://sounds/skybreak/ui_tab.wav", Fallback="rbxasset://sounds/action_jump.mp3", Vol=0.40, Speed=1.18},
    sword_swing_1={Id="rbxasset://sounds/skybreak/sword_swing_1.wav", Fallback="rbxasset://sounds/action_jump.mp3", Vol=0.55, Speed=1.05},
    sword_swing_2={Id="rbxasset://sounds/skybreak/sword_swing_2.wav", Fallback="rbxasset://sounds/action_jump.mp3", Vol=0.58, Speed=1.18},
    sword_swing_3={Id="rbxasset://sounds/skybreak/sword_swing_3.wav", Fallback="rbxasset://sounds/action_jump_land.mp3", Vol=0.65, Speed=1.28},
    heavy_cleave={Id="rbxasset://sounds/skybreak/heavy_cleave.wav", Fallback="rbxasset://sounds/impact_explosion_03.mp3", Vol=0.72, Speed=0.92, Reverb=0.35},
    dodge_dash={Id="rbxasset://sounds/skybreak/dodge_dash.wav", Fallback="rbxasset://sounds/action_falling.ogg", Vol=0.52, Speed=1.35},
    hit_normal={Id="rbxasset://sounds/skybreak/hit_normal.wav", Fallback="rbxasset://sounds/action_jump_land.mp3", Vol=0.58, Speed=1.10},
    hit_crit={Id="rbxasset://sounds/skybreak/hit_crit.wav", Fallback="rbxasset://sounds/impact_explosion_03.mp3", Vol=0.75, Speed=1.25, PitchOctave=1.25},
    hit_break={Id="rbxasset://sounds/skybreak/hit_break.wav", Fallback="rbxasset://sounds/impact_explosion_03.mp3", Vol=0.82, Speed=0.85, Reverb=0.5},
    skill_sky_slash={Id="rbxasset://sounds/skybreak/skill_sky_slash.wav", Fallback="rbxasset://sounds/impact_water.mp3", Vol=0.68, Speed=1.15, Reverb=0.35},
    skill_guardian_shield={Id="rbxasset://sounds/skybreak/skill_guardian_shield.wav", Fallback="rbxasset://sounds/volume_slider.ogg", Vol=0.68, Speed=0.88, Reverb=0.55},
    skill_judgment_strike={Id="rbxasset://sounds/skybreak/skill_judgment_strike.wav", Fallback="rbxasset://sounds/impact_explosion_03.mp3", Vol=0.80, Speed=0.95, Reverb=0.45},
    skill_thunder_strike={Id="rbxasset://sounds/skybreak/skill_thunder_strike.wav", Fallback="rbxasset://sounds/impact_explosion_03.mp3", Vol=0.76, Speed=1.28, Distortion=0.35},
    skill_frost_shatter={Id="rbxasset://sounds/skybreak/skill_frost_shatter.wav", Fallback="rbxasset://sounds/impact_water.mp3", Vol=0.72, Speed=1.32, Reverb=0.45},
    skill_void_rift={Id="rbxasset://sounds/skybreak/skill_void_rift.wav", Fallback="rbxasset://sounds/impact_explosion_03.mp3", Vol=0.82, Speed=0.74, Reverb=0.6, Distortion=0.25},
    boss_telegraph={Id="rbxasset://sounds/skybreak/boss_telegraph.wav", Fallback="rbxasset://sounds/volume_slider.ogg", Vol=0.62, Speed=0.95},
    boss_roar={Id="rbxasset://sounds/skybreak/boss_roar.wav", Fallback="rbxasset://sounds/impact_explosion_03.mp3", Vol=0.85, Speed=0.68, Reverb=0.6, Distortion=0.3},
    level_up={Id="rbxasset://sounds/skybreak/level_up.wav", Fallback="rbxasset://sounds/volume_slider.ogg", Vol=0.78, Speed=1.0, Reverb=0.45},
    quest_complete={Id="rbxasset://sounds/skybreak/quest_complete.wav", Fallback="rbxasset://sounds/volume_slider.ogg", Vol=0.78, Speed=1.0, Reverb=0.45},
    forge_anvil={Id="rbxasset://sounds/skybreak/forge_anvil.wav", Fallback="rbxasset://sounds/action_jump_land.mp3", Vol=0.76, Speed=1.05, Reverb=0.35},
    potion_heal={Id="rbxasset://sounds/skybreak/potion_heal.wav", Fallback="rbxasset://sounds/impact_water.mp3", Vol=0.65, Speed=1.22, Reverb=0.35},
    chest_open={Id="rbxasset://sounds/skybreak/chest_open.wav", Fallback="rbxasset://sounds/volume_slider.ogg", Vol=0.75, Speed=1.05, Reverb=0.4},
    shrine_bless={Id="rbxasset://sounds/skybreak/shrine_bless.wav", Fallback="rbxasset://sounds/volume_slider.ogg", Vol=0.75, Speed=0.95, Reverb=0.55},
}

local BGM_Specs={
    GoldenSky={Id="rbxasset://sounds/skybreak/bgm_goldensky.wav", Vol=0.32, Speed=1.0, Scale={1.0, 1.125, 1.25, 1.406, 1.5, 1.875}, Tempo=0.45},
    FrozenCyber={Id="rbxasset://sounds/skybreak/bgm_frozencyber.wav", Vol=0.32, Speed=1.0, Scale={0.9, 1.0, 1.08, 1.2, 1.35, 1.5}, Tempo=0.38},
    ShadowRealm={Id="rbxasset://sounds/skybreak/bgm_shadowrealm.wav", Vol=0.34, Speed=1.0, Scale={0.75, 0.8, 0.9, 1.0, 1.125, 1.2}, Tempo=0.52},
    BossBattle={Id="rbxasset://sounds/skybreak/bgm_boss_battle.wav", Vol=0.38, Speed=1.0, Scale={1.0, 1.06, 1.2, 1.33, 1.5, 1.6}, Tempo=0.22},
}

local lastSfxTime={}
local currentBgmTrack=""
local activeBgmSound=nil
local activeWindSound=nil

local function isAudioMuted()
    return UI and UI.Muted==true
end

local function playSFX(sfxName,worldPos,pitchJitter)
    if isAudioMuted() then return end
    local spec=SFX_Specs[sfxName] or SFX_Specs.ui_click
    local now=os.clock()
    local minGap=(sfxName=="ui_hover" and 0.04) or (sfxName:find("hit_") and 0.04) or 0.02
    if now-(lastSfxTime[sfxName] or 0)<minGap then return end
    lastSfxTime[sfxName]=now

    if typeof(worldPos)=="Vector3" then
        local r=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if r and (r.Position-worldPos).Magnitude>145 then return end
    end

    local host=AudioGroup
    local emitterPart=nil
    if typeof(worldPos)=="Vector3" then
        emitterPart=Instance.new("Part")
        emitterPart.Name="SFXNode_"..sfxName
        emitterPart.Size=Vector3.new(0.2,0.2,0.2)
        emitterPart.Position=worldPos
        emitterPart.Transparency=1
        emitterPart.Anchored=true
        emitterPart.CanCollide=false
        emitterPart.CanQuery=false
        emitterPart.CanTouch=false
        emitterPart.Parent=tempFX
        host=emitterPart
    end

    local s=Instance.new("Sound")
    s.Name="SFX_"..sfxName
    s.SoundId=spec.Id
    s.SoundGroup=AudioGroup
    s.Volume=spec.Vol or 0.55
    local jitter=pitchJitter and ((math.random()-0.5)*2*pitchJitter) or ((math.random()-0.5)*0.06)
    s.PlaybackSpeed=math.clamp((spec.Speed or 1.0)+jitter,0.4,2.4)
    if emitterPart then
        s.RollOffMode=Enum.RollOffMode.InverseTapered
        s.RollOffMinDistance=12
        s.RollOffMaxDistance=140
    end
    if spec.PitchOctave then
        local ps=Instance.new("PitchShiftSoundEffect")
        ps.Octave=spec.PitchOctave
        ps.Parent=s
    end
    if spec.Reverb then
        local rev=Instance.new("ReverbSoundEffect")
        rev.WetLevel= -6 + spec.Reverb*6
        rev.DecayTime=1.4 + spec.Reverb*1.5
        rev.Parent=s
    end
    if spec.Distortion then
        local dist=Instance.new("DistortionSoundEffect")
        dist.Level=spec.Distortion
        dist.Parent=s
    end
    s.Parent=host
    s:Play()

    -- Automatic fallback layer if custom WAV isn't loaded on another machine
    task.delay(0.05,function()
        if s.Parent and not s.IsLoaded and spec.Fallback then
            s.SoundId=spec.Fallback
            s:Play()
        end
    end)

    Debris:AddItem(emitterPart or s,2.2)
end

local function updateBGM(trackKey)
    if isAudioMuted() then
        if activeBgmSound then activeBgmSound.Volume=0 end
        if activeWindSound then activeWindSound.Volume=0 end
        return
    end
    if not activeWindSound or not activeWindSound.Parent then
        activeWindSound=Instance.new("Sound")
        activeWindSound.Name="SkybreakAmbientWind"
        activeWindSound.SoundId="rbxasset://sounds/skybreak/ambient_sky_wind.wav"
        activeWindSound.SoundGroup=AudioGroup
        activeWindSound.Looped=true
        activeWindSound.Volume=0.16
        activeWindSound.Parent=AudioGroup
        activeWindSound:Play()
    else
        activeWindSound.Volume=0.16
    end

    local spec=BGM_Specs[trackKey] or BGM_Specs.GoldenSky
    if currentBgmTrack==trackKey and activeBgmSound and activeBgmSound.Parent then
        activeBgmSound.Volume=spec.Vol
        if not activeBgmSound.IsPlaying then activeBgmSound:Play() end
        return
    end
    currentBgmTrack=trackKey

    if activeBgmSound and activeBgmSound.Parent then
        local old=activeBgmSound
        Tween:Create(old,TweenInfo.new(0.8,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Volume=0}):Play()
        Debris:AddItem(old,0.85)
    end

    local bgm=Instance.new("Sound")
    bgm.Name="SkybreakBGM_"..trackKey
    bgm.SoundId=spec.Id
    bgm.SoundGroup=AudioGroup
    bgm.Looped=true
    bgm.Volume=0
    bgm.PlaybackSpeed=spec.Speed or 1.0
    bgm.Parent=AudioGroup
    bgm:Play()
    Tween:Create(bgm,TweenInfo.new(1.1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Volume=spec.Vol}):Play()
    activeBgmSound=bgm
end

-- Procedural fallback BGM sequencer for remote online clients without local skybreak/*.wav
task.spawn(function()
    local step=1
    while player.Parent do
        local spec=BGM_Specs[currentBgmTrack] or BGM_Specs.GoldenSky
        if not isAudioMuted() and activeBgmSound and not activeBgmSound.IsLoaded then
            local scale=spec.Scale or {1.0, 1.25, 1.5}
            local ratio=scale[((step-1)%#scale)+1]
            local note=Instance.new("Sound")
            note.Name="SynthBGMNote"
            note.SoundId=(currentBgmTrack=="BossBattle") and "rbxasset://sounds/action_jump_land.mp3" or "rbxasset://sounds/volume_slider.ogg"
            note.SoundGroup=AudioGroup
            note.Volume=(currentBgmTrack=="BossBattle") and 0.22 or 0.16
            note.PlaybackSpeed=ratio
            local rev=Instance.new("ReverbSoundEffect")
            rev.WetLevel=2
            rev.DecayTime=2.6
            rev.Parent=note
            note.Parent=AudioGroup
            note:Play()
            Debris:AddItem(note,1.2)
            step+=1
        end
        task.wait(spec.Tempo or 0.45)
    end
end)

-- Automatically wire UI Hover & Click SFX to all buttons in PlayerGui
task.spawn(function()
    local pgui=player:WaitForChild("PlayerGui",10)
    if not pgui then return end
    local wired={}
    local function wireButton(inst)
        if inst:IsA("GuiButton") and not wired[inst] then
            wired[inst]=true
            inst.MouseEnter:Connect(function()
                playSFX("ui_hover",nil,0.03)
            end)
            inst.Activated:Connect(function()
                playSFX("ui_click",nil,0.04)
            end)
        end
    end
    for _,d in ipairs(pgui:GetDescendants()) do wireButton(d) end
    pgui.DescendantAdded:Connect(wireButton)
end)

-- Automatically play Boss Telegraph warning sound whenever TelegraphZone spawns
tempFX.ChildAdded:Connect(function(child)
    if child.Name=="TelegraphZone" then
        task.defer(function()
            local ring=child:FindFirstChild("OuterRing") or child:FindFirstChildWhichIsA("BasePart")
            playSFX("boss_telegraph",ring and ring.Position or nil,0.04)
        end)
    end
end)

-- ============================================================================
-- 1. CAMERA SHAKE, FOV PUNCH & BEAST TRANSFORMATION CAMERA RIG
-- ============================================================================
local function getTransformCameraSpec()
    local ch=player.Character
    local tf=tostring((ch and ch:GetAttribute("FruitTransform")) or player:GetAttribute("FruitTransform") or "")
    if tf=="SolarTitan" then
        -- +14 studs camera pull-back and +5 studs height offset
        return tf,14,Vector3.new(0,5,0)
    elseif tf=="AbyssalSovereign" then
        -- +8 studs camera pull-back and +2.5 studs height offset
        return tf,8,Vector3.new(0,2.5,0)
    end
    return "",0,Vector3.zero
end

local function shakeCamera(intensity,duration,fovDelta)
    if UI.LowFX then return end
    shakeToken+=1
    local myToken=shakeToken
    local cam=workspace.CurrentCamera
    if cam and fovDelta and fovDelta~=0 then
        cam.FieldOfView=math.clamp(70+fovDelta,60,96)
        Tween:Create(cam,TweenInfo.new(duration or .35,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{FieldOfView=70}):Play()
    end
    task.spawn(function()
        local start=os.clock()
        local dur=duration or .3
        local mag=intensity or .35
        while os.clock()-start<dur and shakeToken==myToken do
            local alpha=1-(os.clock()-start)/dur
            currentShakeOffset=Vector3.new((math.random()-.5)*2*mag*alpha,(math.random()-.5)*2*mag*alpha,0)
            Run.RenderStepped:Wait()
        end
        if shakeToken==myToken then
            currentShakeOffset=Vector3.zero
        end
    end)
end

-- ============================================================================
-- 2. TARGET LOCK-ON SYSTEM (TAB KEY) & 3D TARGET RETICLE
-- ============================================================================
local function getEnemyRoot(model)
    if not model or not model.Parent then return nil end
    if model:GetAttribute("EnemyDead") then return nil end
    local body=model:FindFirstChild("Body") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
    return body
end

local function getEnemyDisplayName(model)
    local id=model:GetAttribute("EnemyId") or model.Name
    local cfg=C.Enemies and C.Enemies[id]
    return (cfg and cfg.Name) or id
end

local function destroyReticle()
    if lockReticle then
        lockReticle:Destroy()
        lockReticle=nil
    end
end

local function ensureReticle()
    if lockReticle and lockReticle.Parent then return lockReticle end
    local model=Instance.new("Model")
    model.Name="TargetLockReticle"
    local ring=Instance.new("Part")
    ring.Name="Ring"
    ring.Shape=Enum.PartType.Cylinder
    ring.Size=Vector3.new(.18,7.5,7.5)
    ring.Color=Color3.fromRGB(255,68,92)
    ring.Material=Enum.Material.Neon
    ring.Transparency=.25
    ring.Anchored=true
    ring.CanCollide=false
    ring.CanQuery=false
    ring.CanTouch=false
    ring.Parent=model
    model.PrimaryPart=ring

    for i=1,4 do
        local chev=Instance.new("Part")
        chev.Name="Chevron"..i
        chev.Size=Vector3.new(.85,.22,1.6)
        chev.Color=Color3.fromRGB(255,214,94)
        chev.Material=Enum.Material.Neon
        chev.Anchored=true
        chev.CanCollide=false
        chev.CanQuery=false
        chev.CanTouch=false
        chev.Parent=model
    end

    local bill=Instance.new("BillboardGui")
    bill.Name="LockBill"
    bill.Size=UDim2.fromOffset(200,36)
    bill.StudsOffset=Vector3.new(0,6.5,0)
    bill.AlwaysOnTop=true
    bill.Parent=ring
    local lbl=Instance.new("TextLabel")
    lbl.Name="TargetText"
    lbl.Size=UDim2.fromScale(1,1)
    lbl.BackgroundTransparency=1
    lbl.Font=Enum.Font.GothamBold
    lbl.TextSize=15
    lbl.TextColor3=Color3.fromRGB(255,214,94)
    lbl.TextStrokeTransparency=.2
    lbl.Text="🎯 [LOCKED]"
    lbl.Parent=bill

    model.Parent=tempFX
    lockReticle=model
    return model
end

local function toggleTargetLock()
    local ch=player.Character
    local r=ch and ch:FindFirstChild("HumanoidRootPart")
    if not r then return end

    local candidates={}
    for _,folderName in ipairs({"ActiveBosses","ActiveEnemies"}) do
        local folder=workspace:FindFirstChild(folderName)
        if folder then
            for _,m in ipairs(folder:GetChildren()) do
                if m:IsA("Model") and m.Name~="EnergyPylon" then
                    local er=getEnemyRoot(m)
                    if er then
                        local d=(er.Position-r.Position).Magnitude
                        if d<=70 then
                            table.insert(candidates,{Model=m,Dist=d})
                        end
                    end
                end
            end
        end
    end
    table.sort(candidates,function(a,b) return a.Dist<b.Dist end)

    if #candidates==0 then
        lockedTarget=nil
        destroyReticle()
        UI.SetLockTarget(nil)
        return
    end

    if not lockedTarget then
        lockedTarget=candidates[1].Model
    else
        local foundIdx=nil
        for i,c in ipairs(candidates) do
            if c.Model==lockedTarget then foundIdx=i break end
        end
        if foundIdx and foundIdx<#candidates then
            lockedTarget=candidates[foundIdx+1].Model
        else
            lockedTarget=nil
        end
    end

    if lockedTarget then
        local name=getEnemyDisplayName(lockedTarget)
        UI.SetLockTarget(name)
        UI.Toast("🎯 Đã khóa mục tiêu: "..name)
    else
        destroyReticle()
        UI.SetLockTarget(nil)
        UI.Toast("🎯 Đã hủy khóa mục tiêu.")
    end
end

local function faceLockedTarget()
    if not lockedTarget then return end
    local er=getEnemyRoot(lockedTarget)
    local ch=player.Character
    local r=ch and ch:FindFirstChild("HumanoidRootPart")
    if not er or not r then
        lockedTarget=nil
        destroyReticle()
        UI.SetLockTarget(nil)
        return
    end
    local flatTarget=Vector3.new(er.Position.X,r.Position.Y,er.Position.Z)
    if (flatTarget-r.Position).Magnitude>.5 then
        r.CFrame=CFrame.lookAt(r.Position,flatTarget)
    end
end

-- ============================================================================
-- 2B. OBSERVATION HAKI (INSTINCT) CLIENT-SIDE VISION EFFECT ([U])
-- ============================================================================
local lastInstinctState=false
local function updateInstinctVision()
    local ch=player.Character
    local active=(ch and ch:GetAttribute("HakiInstinct")==true) or (player:GetAttribute("HakiInstinct")==true)

    local cc=Lighting:FindFirstChild("InstinctVision")
    if active then
        if not cc then
            cc=Instance.new("ColorCorrectionEffect")
            cc.Name="InstinctVision"
            cc.Parent=Lighting
        end
        cc.TintColor=Color3.fromRGB(185,225,255)
        cc.Contrast=0.18
        cc.Saturation=0.12
        cc.Enabled=true

        for _,folderName in ipairs({"ActiveEnemies","ActiveBosses"}) do
            local f=workspace:FindFirstChild(folderName)
            if f then
                for _,m in ipairs(f:GetChildren()) do
                    if m:IsA("Model") then
                        local hl=m:FindFirstChild("InstinctHighlight")
                        if not hl then
                            hl=Instance.new("Highlight")
                            hl.Name="InstinctHighlight"
                            hl.Adornee=m
                            hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                            hl.FillColor=Color3.fromRGB(48,215,255)
                            hl.FillTransparency=0.52
                            hl.OutlineColor=Color3.fromRGB(255,242,135)
                            hl.OutlineTransparency=0.02
                            hl.Parent=m
                        end
                        hl.Enabled=true
                    end
                end
            end
        end
    elseif lastInstinctState or (cc and cc.Enabled) then
        if cc then cc.Enabled=false end
        for _,folderName in ipairs({"ActiveEnemies","ActiveBosses"}) do
            local f=workspace:FindFirstChild(folderName)
            if f then
                for _,m in ipairs(f:GetChildren()) do
                    local hl=m:FindFirstChild("InstinctHighlight")
                    if hl then hl:Destroy() end
                end
            end
        end
    end
    lastInstinctState=active
end

-- ============================================================================
-- 2C. BLOX FRUITS TRAVERSAL: DOUBLE JUMP / MULTI AIR-JUMP (GEPPO) & AIR DASH
-- ============================================================================
local airJumpCount=0
local lastAirJumpTime=0
local lastAirDashTime=0

local function spawnGeppoRing(footPos,isSkyborn)
    local ringColor=isSkyborn and Color3.fromRGB(255,218,98) or Color3.fromRGB(215,242,255)
    local outer=Instance.new("Part")
    outer.Name="GeppoShockwaveRing"
    outer.Shape=Enum.PartType.Cylinder
    outer.Size=Vector3.new(0.22,2.4,2.4)
    outer.CFrame=CFrame.new(footPos)*CFrame.Angles(0,0,math.pi*0.5)
    outer.Color=ringColor
    outer.Material=Enum.Material.Neon
    outer.Transparency=0.12
    outer.Anchored=true
    outer.CanCollide=false
    outer.CanQuery=false
    outer.CanTouch=false
    outer.Parent=tempFX
    Tween:Create(outer,TweenInfo.new(0.32,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
        Size=Vector3.new(0.08,11.5,11.5),
        Transparency=1,
    }):Play()
    Debris:AddItem(outer,0.35)

    local inner=Instance.new("Part")
    inner.Name="GeppoAirPuff"
    inner.Shape=Enum.PartType.Ball
    inner.Size=Vector3.new(1.6,0.6,1.6)
    inner.CFrame=CFrame.new(footPos)
    inner.Color=Color3.fromRGB(255,255,255)
    inner.Material=Enum.Material.Neon
    inner.Transparency=0.25
    inner.Anchored=true
    inner.CanCollide=false
    inner.CanQuery=false
    inner.CanTouch=false
    inner.Parent=tempFX
    Tween:Create(inner,TweenInfo.new(0.26,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
        Size=Vector3.new(6.2,1.2,6.2),
        Transparency=1,
    }):Play()
    Debris:AddItem(inner,0.28)
end

local function bindCharacterTraversal(ch)
    if not ch then return end
    airJumpCount=0
    local hum=ch:WaitForChild("Humanoid",5)
    if not hum then return end
    hum.StateChanged:Connect(function(_,newState)
        if newState==Enum.HumanoidStateType.Landed or newState==Enum.HumanoidStateType.Running or newState==Enum.HumanoidStateType.RunningNoPhysics then
            airJumpCount=0
        end
    end)
end

if player.Character then
    task.spawn(bindCharacterTraversal,player.Character)
end
player.CharacterAdded:Connect(bindCharacterTraversal)

UIS.JumpRequest:Connect(function()
    if UI.BlocksCombat() or UIS:GetFocusedTextBox() then return end
    local ch=player.Character
    local hum=ch and ch:FindFirstChildOfClass("Humanoid")
    local root=ch and ch:FindFirstChild("HumanoidRootPart")
    if not hum or not root or hum.Health<=0 then return end

    local state=hum:GetState()
    local isAirborne=(state==Enum.HumanoidStateType.Jumping or state==Enum.HumanoidStateType.Freefall)
    if not isAirborne then return end

    local now=os.clock()
    if now-lastAirJumpTime<0.22 then return end

    local race=tostring(ch:GetAttribute("Race") or player:GetAttribute("Race") or "Skyborn")
    local raceV4=tostring(ch:GetAttribute("RaceV4") or player:GetAttribute("RaceV4") or "")
    local maxAirJumps=(raceV4~="" and 10) or (race=="Skyborn" and 8) or 6
    if airJumpCount>=maxAirJumps then return end

    airJumpCount+=1
    lastAirJumpTime=now
    ch:SetAttribute("LastAirJumpAt",now)
    ch:SetAttribute("AirJumpIndex",airJumpCount)

    local vel=root.AssemblyLinearVelocity
    local moveDir=hum.MoveDirection
    local horizBoost=(moveDir.Magnitude>0.05) and (moveDir.Unit*math.max(24,hum.WalkSpeed*1.18)) or Vector3.new(vel.X,0,vel.Z)
    root.AssemblyLinearVelocity=Vector3.new(horizBoost.X,58,horizBoost.Z)
    hum:ChangeState(Enum.HumanoidStateType.Jumping)

    spawnGeppoRing(root.Position-Vector3.new(0,2.8,0),race=="Skyborn" or raceV4~="")
    playSFX("dodge_dash",root.Position,0.06)
    pcall(function()
        GuardianAnimator.Action(ch,"DoubleJump",airJumpCount)
    end)
end)

Run.RenderStepped:Connect(function()
    -- 1. Update Beast Transformation Camera Pull-back & Height Offset
    local ch=player.Character
    local hum=ch and ch:FindFirstChildOfClass("Humanoid")
    local tf,pullBack,heightOff=getTransformCameraSpec()
    if hum then
        hum.CameraOffset=heightOff+currentShakeOffset
    end
    if tf~=lastTransformState then
        lastTransformState=tf
        player.CameraMaxZoomDistance=65
        if pullBack>0 then
            player.CameraMinZoomDistance=12+pullBack
        else
            player.CameraMinZoomDistance=0.5
        end
    end
    if pullBack>0 then
        local cam=workspace.CurrentCamera
        local r=ch and ch:FindFirstChild("HumanoidRootPart")
        if cam and r then
            local focusPos=r.Position+heightOff
            local camVec=cam.CFrame.Position-focusPos
            local minDist=12+pullBack
            if camVec.Magnitude>0.1 and camVec.Magnitude<minDist then
                cam.CFrame=CFrame.new(focusPos+camVec.Unit*minDist)*cam.CFrame.Rotation
            end
        end
    end

    -- 2. Update Observation Haki (Instinct) Vision Effect
    updateInstinctVision()

    -- 2b. End-of-World 3D Portal Compass Guide (World n -> World n+1)
    local nextGatePos=player:GetAttribute("NextWorldGatePos")
    local nextGateLabel=tostring(player:GetAttribute("NextWorldGateLabel") or "WORLD GATE")
    local rootPart=ch and ch:FindFirstChild("HumanoidRootPart")
    local compass=tempFX:FindFirstChild("WorldGateCompass")
    if typeof(nextGatePos)=="Vector3" and rootPart then
        local delta=nextGatePos-rootPart.Position
        local dist=delta.Magnitude
        if dist>=14 and dist<=650 then
            if not compass then
                compass=Instance.new("Part")
                compass.Name="WorldGateCompass"
                compass.Size=Vector3.new(0.45,0.22,1.15)
                compass.Color=Color3.fromRGB(95,238,255)
                compass.Material=Enum.Material.Neon
                compass.Transparency=0.22
                compass.Anchored=true
                compass.CanCollide=false
                compass.CanQuery=false
                compass.CanTouch=false
                compass.Parent=tempFX
                local cBill=Instance.new("BillboardGui")
                cBill.Name="CompassBill"
                cBill.Size=UDim2.fromOffset(260,36)
                cBill.StudsOffset=Vector3.new(0,1.4,0)
                cBill.AlwaysOnTop=true
                cBill.Parent=compass
                local cTxt=Instance.new("TextLabel")
                cTxt.Name="CompassText"
                cTxt.Size=UDim2.fromScale(1,1)
                cTxt.BackgroundTransparency=1
                cTxt.Font=Enum.Font.GothamBlack
                cTxt.TextSize=12
                cTxt.TextColor3=Color3.fromRGB(125,245,255)
                cTxt.TextStrokeTransparency=0.2
                cTxt.Parent=cBill
            end
            local flatDir=Vector3.new(delta.X,0,delta.Z)
            local dirUnit=flatDir.Magnitude>0.1 and flatDir.Unit or rootPart.CFrame.LookVector
            local bob=math.sin(os.clock()*3.5)*0.18
            local cPos=rootPart.Position+dirUnit*5.8+Vector3.new(0,1.6+bob,0)
            compass.CFrame=CFrame.lookAt(cPos,cPos+dirUnit)
            local cBill=compass:FindFirstChild("CompassBill")
            local cTxt=cBill and cBill:FindFirstChild("CompassText")
            if cTxt then
                cTxt.Text=string.format("🌀 %s (%dm)",nextGateLabel,math.floor(dist))
            end
        elseif compass then
            compass:Destroy()
        end
    elseif compass then
        compass:Destroy()
    end

    -- 3. Update Target Lock-On 3D Reticle
    if not lockedTarget then
        if lockReticle then destroyReticle() end
        return
    end
    local er=getEnemyRoot(lockedTarget)
    local r=ch and ch:FindFirstChild("HumanoidRootPart")
    if not er or not r or (er.Position-r.Position).Magnitude>85 then
        lockedTarget=nil
        destroyReticle()
        UI.SetLockTarget(nil)
        return
    end
    local ret=ensureReticle()
    local ring=ret:FindFirstChild("Ring")
    local floorY=lockedTarget:GetAttribute("EnemyFloorY") or (er.Position.Y-2.5)
    local center=Vector3.new(er.Position.X,floorY+.15,er.Position.Z)
    local t=os.clock()
    if ring then
        ring.CFrame=CFrame.new(center)*CFrame.Angles(0,t*2.2,math.pi/2)
        local bill=ring:FindFirstChild("LockBill")
        local lbl=bill and bill:FindFirstChild("TargetText")
        if lbl then lbl.Text="🎯 [LOCKED] "..getEnemyDisplayName(lockedTarget) end
    end
    for i=1,4 do
        local chev=ret:FindFirstChild("Chevron"..i)
        if chev then
            local ang=t*2.6+(i-1)*(math.pi/2)
            local radius=4.2+math.sin(t*6)*.35
            local cPos=center+Vector3.new(math.cos(ang)*radius,.15,math.sin(ang)*radius)
            chev.CFrame=CFrame.lookAt(cPos,center)
        end
    end
end)

-- ============================================================================
-- 3. 3D FLOATING DAMAGE NUMBERS (spawnDamagePopup)
-- ============================================================================
local function spawnDamagePopup(payload)
    if UI.LowFX then return end
    local basePos=payload.pos or payload.Position
    if typeof(basePos)~="Vector3" then return end
    local rawText=payload.Text or payload.text
    local amount=payload.amount or payload.Amount or rawText
    if not amount then return end

    local str=tostring(amount)
    local isHeal=(payload.element=="Heal" or payload.Element=="Heal" or str:find("HP")~=nil)
    local isCrit=(payload.crit==true or payload.Crit==true or str:find("!")~=nil)
    local cleanNum=str:gsub("!",""):gsub("%+",""):gsub("HP",""):gsub("%s+","")
    local breakDmg=payload.breakDmg or payload.BreakDmg or 0

    if isHeal then
        playSFX("potion_heal",basePos,0.04)
    elseif breakDmg and breakDmg>=35 then
        playSFX("hit_break",basePos,0.05)
    elseif isCrit then
        playSFX("hit_crit",basePos,0.05)
    else
        playSFX("hit_normal",basePos,0.06)
    end

    local anchor=Instance.new("Part")
    anchor.Name="DamagePopup"
    anchor.Size=Vector3.new(.2,.2,.2)
    anchor.Position=basePos+Vector3.new((math.random()-.5)*3,3.2,(math.random()-.5)*3)
    anchor.Transparency=1
    anchor.Anchored=true
    anchor.CanCollide=false
    anchor.CanQuery=false
    anchor.CanTouch=false
    anchor.Parent=tempFX

    local bill=Instance.new("BillboardGui")
    bill.Size=UDim2.fromOffset(220,75)
    bill.AlwaysOnTop=true
    bill.Parent=anchor

    local scale=Instance.new("UIScale")
    scale.Scale=isCrit and 1.42 or 1
    scale.Parent=bill
    if isCrit then
        Tween:Create(scale,TweenInfo.new(.18,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
    end

    local mainLbl=Instance.new("TextLabel")
    mainLbl.Size=UDim2.new(1,0,0,46)
    mainLbl.BackgroundTransparency=1
    mainLbl.Font=Enum.Font.GothamBold
    if isHeal then
        mainLbl.Text="+ "..cleanNum.." HP"
        mainLbl.TextColor3=Color3.fromRGB(92,242,160)
        mainLbl.TextSize=24
    elseif isCrit then
        mainLbl.Text="✦ "..cleanNum.." CRIT!"
        mainLbl.TextColor3=Color3.fromRGB(255,218,92)
        mainLbl.TextSize=28
    else
        mainLbl.Text=cleanNum
        mainLbl.TextColor3=Color3.fromRGB(240,248,255)
        mainLbl.TextSize=22
    end
    mainLbl.Parent=bill

    local stroke=Instance.new("UIStroke")
    stroke.Color=isCrit and Color3.fromRGB(140,75,10) or Color3.fromRGB(8,18,32)
    stroke.Thickness=isCrit and 2.4 or 1.8
    stroke.Parent=mainLbl

    local subLbl=nil
    if breakDmg and breakDmg>0 then
        subLbl=Instance.new("TextLabel")
        subLbl.Position=UDim2.fromOffset(0,42)
        subLbl.Size=UDim2.new(1,0,0,22)
        subLbl.BackgroundTransparency=1
        subLbl.Font=Enum.Font.GothamBold
        subLbl.Text="+ "..tostring(breakDmg).." BREAK"
        subLbl.TextColor3=Color3.fromRGB(205,140,255)
        subLbl.TextSize=14
        subLbl.TextStrokeTransparency=.3
        subLbl.Parent=bill
    end

    local targetPos=anchor.Position+Vector3.new(0,3.5,0)
    Tween:Create(anchor,TweenInfo.new(.85,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Position=targetPos}):Play()
    task.delay(.35,function()
        if mainLbl.Parent then
            Tween:Create(mainLbl,TweenInfo.new(.48),{TextTransparency=1}):Play()
            Tween:Create(stroke,TweenInfo.new(.48),{Transparency=1}):Play()
        end
        if subLbl and subLbl.Parent then
            Tween:Create(subLbl,TweenInfo.new(.48),{TextTransparency=1,TextStrokeTransparency=1}):Play()
        end
    end)
    Debris:AddItem(anchor,.88)
end

-- ============================================================================
-- 4. SPECTACULAR 3D MULTI-PART VFX FOR CLASS SKILLS, FRUIT MOVES & HAKI
-- ============================================================================
local function vfxPart(name,shape,size,cf,color,transparency,material)
    local p=Instance.new("Part")
    p.Name=name
    p.Shape=shape or Enum.PartType.Block
    p.Size=size
    p.CFrame=cf
    p.Color=color
    p.Material=material or Enum.Material.Neon
    p.Transparency=transparency or .25
    p.Anchored=true
    p.CanCollide=false
    p.CanQuery=false
    p.CanTouch=false
    p.Parent=tempFX
    return p
end

local function spawnRingWave(pos,color,startR,endR,dur)
    local ring=vfxPart("ShockRing",Enum.PartType.Cylinder,Vector3.new(.25,startR,startR),CFrame.new(pos)*CFrame.Angles(0,0,math.pi/2),color,.2)
    Tween:Create(ring,TweenInfo.new(dur or .45,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(.1,endR,endR),Transparency=1}):Play()
    Debris:AddItem(ring,(dur or .45)+.05)
end

local function spawnFlashLight(pos,color,brightness,range,dur)
    local node=vfxPart("VFXLightNode",Enum.PartType.Ball,Vector3.new(.2,.2,.2),CFrame.new(pos),color,1)
    local pl=Instance.new("PointLight")
    pl.Color=color
    pl.Brightness=brightness or 4
    pl.Range=range or 26
    pl.Parent=node
    Tween:Create(pl,TweenInfo.new(dur or .45,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Brightness=0,Range=(range or 26)*1.3}):Play()
    Debris:AddItem(node,(dur or .45)+.05)
end

local function spawnCraterShards(pos,color,secondaryColor,count,radius,dur)
    local floorPos=pos-Vector3.new(0,2.2,0)
    for i=1,(count or 8) do
        local ang=(i-1)*(2*math.pi/(count or 8))
        local shardPos=floorPos+Vector3.new(math.cos(ang)*radius*0.45,0,math.sin(ang)*radius*0.45)
        local endPos=floorPos+Vector3.new(math.cos(ang)*radius,0.6,math.sin(ang)*radius)
        local shard=vfxPart("CraterShard"..i,Enum.PartType.Block,Vector3.new(0.85,1.8,1.35),CFrame.lookAt(shardPos,endPos)*CFrame.Angles(0.45,0,0),i%2==0 and color or secondaryColor,0.12)
        Tween:Create(shard,TweenInfo.new(dur or 0.5,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
            CFrame=CFrame.lookAt(endPos,endPos+Vector3.new(math.cos(ang),0,math.sin(ang)))*CFrame.Angles(0.75,0,0),
            Size=Vector3.new(0.4,0.4,0.6),
            Transparency=1,
        }):Play()
        Debris:AddItem(shard,(dur or 0.5)+0.05)
    end
end

local function resolveElementPalette(element,action)
    local el=tostring(element or "")
    local act=tostring(action or "")
    if el=="Frost" or act:find("Frost") or act:find("Ice") or act:find("Glacial") or act:find("Blizzard") then
        return Color3.fromRGB(92,238,255),Color3.fromRGB(210,250,255),Color3.fromRGB(28,110,220)
    elseif el=="Lightning" or act:find("Thunder") or act:find("Storm") or act:find("Volt") or act:find("Arc") or act:find("Flash") then
        return Color3.fromRGB(68,195,255),Color3.fromRGB(195,120,255),Color3.fromRGB(220,248,255)
    elseif el=="Void" or act:find("Void") or act:find("Abyss") or act:find("Astral") or act:find("Shadow") or act:find("Dark") then
        return Color3.fromRGB(178,42,255),Color3.fromRGB(255,48,145),Color3.fromRGB(32,12,56)
    elseif el=="Flame" or el=="Fire" or act:find("Flame") or act:find("Fire") or act:find("Magma") or act:find("Dragon") then
        return Color3.fromRGB(255,95,42),Color3.fromRGB(255,215,75),Color3.fromRGB(165,24,38)
    else
        -- Default Sky / Solar Gold
        return Color3.fromRGB(255,216,92),Color3.fromRGB(255,248,185),Color3.fromRGB(98,228,255)
    end
end

local function spawnSkillVFX(actionOrData,pos,actorChar,extraData)
    local data=type(actionOrData)=="table" and actionOrData or (type(extraData)=="table" and extraData or {})
    local action=type(actionOrData)=="string" and actionOrData or tostring(data.skillId or data.Action or data.action or "Attack")
    local skillId=tostring(data.skillId or action)
    pos=pos or data.Position or data.pos
    if UI.LowFX or fxCount>=36 or typeof(pos)~="Vector3" then return end
    local r=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not r or (r.Position-pos).Magnitude>130 then return end
    fxCount+=1
    task.delay(.6,function() fxCount=math.max(0,fxCount-1) end)

    if not actorChar and data.Actor then
        local p=Players:GetPlayerByUserId(data.Actor)
        actorChar=p and p.Character
    end

    local gold=Color3.fromRGB(255,216,107)
    local cyan=Color3.fromRGB(104,232,255)
    local violet=Color3.fromRGB(185,95,255)
    local deepVoid=Color3.fromRGB(48,18,88)
    local hakiRed=Color3.fromRGB(255,32,78)
    local hakiBlack=Color3.fromRGB(16,10,22)

    local actorRoot=actorChar and actorChar:FindFirstChild("HumanoidRootPart")
    local lookCF=actorRoot and actorRoot.CFrame or CFrame.new(pos)

    -- CONQUEROR'S HAKI BURST ([H]): Massive expanding crimson-black Haki dome (radius -> 38 studs) + lightning rings + camera shake (1.2, 0.45)
    if skillId=="ConquerorHaki" or action=="ConquerorHaki" or action=="ConquerorBurst" then
        local center=actorRoot and actorRoot.Position or pos
        local outerDome=vfxPart("ConquerorHakiDome",Enum.PartType.Ball,Vector3.new(6,6,6),CFrame.new(center),hakiRed,.18)
        local innerCore=vfxPart("ConquerorObsidianCore",Enum.PartType.Ball,Vector3.new(4,4,4),CFrame.new(center),hakiBlack,.12)
        Tween:Create(outerDome,TweenInfo.new(.68,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(76,76,76),Transparency=1}):Play()
        Tween:Create(innerCore,TweenInfo.new(.58,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(62,62,62),Transparency=1}):Play()
        Debris:AddItem(outerDome,.72)
        Debris:AddItem(innerCore,.62)

        spawnRingWave(center-Vector3.new(0,2.3,0),hakiRed,8,76,.68)
        spawnRingWave(center-Vector3.new(0,1.8,0),hakiBlack,6,64,.58)
        spawnRingWave(center-Vector3.new(0,1.2,0),gold,4,48,.48)
        spawnFlashLight(center,hakiRed,6.5,48,.65)
        spawnCraterShards(center,hakiRed,hakiBlack,10,28,.65)

        for i=1,10 do
            local ang=(i-1)*(2*math.pi/10)
            local bolt=vfxPart("ConquerorBolt"..i,Enum.PartType.Block,Vector3.new(.55,.55,14),CFrame.new(center)*CFrame.Angles(0,ang,0)*CFrame.new(0,1.5,-8)*CFrame.Angles(0.25,(i%2==0 and 0.35 or -0.35),0),i%2==0 and hakiRed or hakiBlack,.06)
            Tween:Create(bolt,TweenInfo.new(.55,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
                CFrame=CFrame.new(center)*CFrame.Angles(0,ang+0.25,0)*CFrame.new(0,3.5,-28),
                Size=Vector3.new(.2,.2,22),
                Transparency=1,
            }):Play()
            Debris:AddItem(bolt,.6)
        end
        if actorChar==player.Character or not actorChar then
            shakeCamera(1.2,0.45,12)
        end
        return
    end

    if skillId=="WorldGateTeleport" or action=="WorldGateTeleport" or action=="PortalSurge" then
        local primary,secondary=resolveElementPalette(data.element or data.Element,"Portal")
        local vortex=vfxPart("StargateWarpPillar",Enum.PartType.Cylinder,Vector3.new(32,5,5),CFrame.new(pos+Vector3.new(0,12,0))*CFrame.Angles(0,0,math.pi/2),primary,.14)
        Tween:Create(vortex,TweenInfo.new(.55,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(38,16,16),Transparency=1}):Play()
        Debris:AddItem(vortex,.6)
        spawnRingWave(pos-Vector3.new(0,2,0),primary,6,32,.55)
        spawnRingWave(pos-Vector3.new(0,1.2,0),secondary,4,24,.45)
        spawnFlashLight(pos,primary,5.5,32,.55)
        if actorChar==player.Character or not actorChar then
            shakeCamera(.65,.38,7)
        end
        return
    end

    if action=="SkySlash" then
        local crescent=vfxPart("SkySlashArc",Enum.PartType.Block,Vector3.new(8,.35,3.5),lookCF*CFrame.new(0,0,-3),gold,.15)
        Tween:Create(crescent,TweenInfo.new(.38,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{CFrame=lookCF*CFrame.new(0,0,-15),Size=Vector3.new(14,.2,5),Transparency=1}):Play()
        Debris:AddItem(crescent,.4)
        spawnRingWave(pos-Vector3.new(0,2,0),gold,4,16,.38)
        spawnFlashLight(pos,gold,3.5,20,.35)

    elseif action=="GuardianShield" then
        local center=actorRoot and actorRoot.Position or pos
        spawnRingWave(center-Vector3.new(0,2.5,0),gold,6,22,.55)
        spawnRingWave(center-Vector3.new(0,2.3,0),cyan,4,18,.5)
        spawnFlashLight(center,gold,3.5,22,.5)

    elseif action=="JudgmentStrike" then
        local beam=vfxPart("JudgmentBeam",Enum.PartType.Cylinder,Vector3.new(36,6,6),CFrame.new(pos+Vector3.new(0,15,0))*CFrame.Angles(0,0,math.pi/2),gold,.12)
        Tween:Create(beam,TweenInfo.new(.5,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(38,14,14),Transparency=1}):Play()
        Debris:AddItem(beam,.55)
        spawnRingWave(pos-Vector3.new(0,2,0),gold,5,26,.5)
        spawnCraterShards(pos,gold,cyan,8,14,.5)
        spawnFlashLight(pos,gold,4.5,28,.5)
        if actorChar==player.Character then shakeCamera(.45,.35,5) end

    elseif action=="CelestialAegis" then
        local center=actorRoot and actorRoot.Position or pos
        local dome=vfxPart("AegisDome",Enum.PartType.Ball,Vector3.new(6,6,6),CFrame.new(center),gold,.2)
        Tween:Create(dome,TweenInfo.new(.65,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(34,34,34),Transparency=1}):Play()
        Debris:AddItem(dome,.7)
        spawnRingWave(center-Vector3.new(0,2.4,0),gold,8,38,.65)
        spawnCraterShards(center,gold,cyan,8,20,.6)
        spawnFlashLight(center,gold,5.5,34,.65)
        for i=1,6 do
            local ang=(i-1)*(math.pi/3)
            local sword=vfxPart("SpiritSword"..i,Enum.PartType.Block,Vector3.new(.6,7,1.2),CFrame.new(center+Vector3.new(math.cos(ang)*7,4,math.sin(ang)*7)),gold,.1)
            Tween:Create(sword,TweenInfo.new(.6,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{CFrame=CFrame.new(center+Vector3.new(math.cos(ang)*14,1,math.sin(ang)*14))*CFrame.Angles(.4,ang,0),Transparency=1}):Play()
            Debris:AddItem(sword,.65)
        end
        if actorChar==player.Character then shakeCamera(.8,.55,9) end

    elseif action=="ArcCut" then
        for _,tilt in ipairs({.65,-.65}) do
            local slash=vfxPart("ArcSlash",Enum.PartType.Block,Vector3.new(9,.28,1.6),lookCF*CFrame.new(0,0,-4)*CFrame.Angles(0,0,tilt),cyan,.1)
            Tween:Create(slash,TweenInfo.new(.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=Vector3.new(13,.15,2.4),CFrame=lookCF*CFrame.new(0,0,-9)*CFrame.Angles(0,0,tilt),Transparency=1}):Play()
            Debris:AddItem(slash,.34)
        end
        spawnFlashLight(pos,cyan,3.2,18,.3)

    elseif action=="FlashStep" then
        local origin=actorRoot and actorRoot.Position or pos
        local afterimage=vfxPart("FlashAfterimage",Enum.PartType.Cylinder,Vector3.new(7,2.8,2.8),CFrame.new(origin)*CFrame.Angles(0,0,math.pi/2),cyan,.25)
        Tween:Create(afterimage,TweenInfo.new(.38),{Size=Vector3.new(8,.4,.4),Transparency=1}):Play()
        Debris:AddItem(afterimage,.4)
        for s=1,4 do
            local bolt=vfxPart("BoltSeg"..s,Enum.PartType.Block,Vector3.new(.45,.45,5),lookCF*CFrame.new((s%2==0 and 1.2 or -1.2),0,-s*4.2)*CFrame.Angles(0,(s%2==0 and .35 or -.35),0),cyan,.1)
            Tween:Create(bolt,TweenInfo.new(.32),{Transparency=1}):Play()
            Debris:AddItem(bolt,.35)
        end

    elseif action=="StormBlitz" then
        local center=actorRoot and actorRoot.Position or pos
        local storm=vfxPart("StormDome",Enum.PartType.Ball,Vector3.new(5,5,5),CFrame.new(center),cyan,.28)
        Tween:Create(storm,TweenInfo.new(.5,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(26,26,26),Transparency=1}):Play()
        Debris:AddItem(storm,.55)
        spawnFlashLight(center,cyan,4.5,26,.5)
        for i=1,8 do
            local ang=(i-1)*(math.pi/4)
            local arc=vfxPart("StormArc"..i,Enum.PartType.Block,Vector3.new(.4,.4,10),CFrame.new(center)*CFrame.Angles(0,ang,0)*CFrame.new(0,0,-6),i%2==0 and cyan or violet,.12)
            Tween:Create(arc,TweenInfo.new(.42),{CFrame=CFrame.new(center)*CFrame.Angles(0,ang+.4,0)*CFrame.new(0,0,-13),Transparency=1}):Play()
            Debris:AddItem(arc,.45)
        end
        if actorChar==player.Character then shakeCamera(.45,.35,5) end

    elseif action=="ThunderJudgement" then
        local spear=vfxPart("ThunderSpear",Enum.PartType.Cylinder,Vector3.new(42,7,7),CFrame.new(pos+Vector3.new(0,18,0))*CFrame.Angles(0,0,math.pi/2),violet,.1)
        Tween:Create(spear,TweenInfo.new(.55,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(45,16,16),Transparency=1}):Play()
        Debris:AddItem(spear,.6)
        spawnRingWave(pos-Vector3.new(0,2,0),cyan,6,34,.55)
        spawnRingWave(pos-Vector3.new(0,1.5,0),violet,4,26,.45)
        spawnCraterShards(pos,cyan,violet,8,18,.55)
        spawnFlashLight(pos,violet,5.5,32,.55)
        if actorChar==player.Character then shakeCamera(.85,.55,9) end

    elseif action=="FrostBolt" then
        for i=-1,1 do
            local shard=vfxPart("IceSpire"..i,Enum.PartType.Block,Vector3.new(1.2,4.5,1.2),CFrame.new(pos+Vector3.new(i*2.2,1.5,0))*CFrame.Angles(.25,i*.4,.2),cyan,.15)
            Tween:Create(shard,TweenInfo.new(.42,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(1.8,7.5,1.8),Transparency=1}):Play()
            Debris:AddItem(shard,.45)
        end
        spawnRingWave(pos-Vector3.new(0,2,0),cyan,3,16,.4)
        spawnFlashLight(pos,cyan,3.5,20,.4)

    elseif action=="ManaBarrier" then
        local center=actorRoot and actorRoot.Position or pos
        local sphere=vfxPart("ManaSphere",Enum.PartType.Ball,Vector3.new(9,9,9),CFrame.new(center),violet,.35)
        Tween:Create(sphere,TweenInfo.new(.55),{Size=Vector3.new(15,15,15),Transparency=1}):Play()
        Debris:AddItem(sphere,.6)
        spawnRingWave(center-Vector3.new(0,2,0),violet,5,20,.5)

    elseif action=="ArcaneComet" then
        for i=1,3 do
            local offset=Vector3.new((i-2)*5,0,(i%2==0 and 3 or -3))
            local startP=pos+offset+Vector3.new(-8,26,-8)
            local endP=pos+offset
            local meteor=vfxPart("Comet"..i,Enum.PartType.Ball,Vector3.new(3.6,3.6,3.6),CFrame.new(startP),violet,.1)
            task.delay((i-1)*.08,function()
                if meteor.Parent then
                    Tween:Create(meteor,TweenInfo.new(.28,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=endP,Size=Vector3.new(6,6,6),Transparency=1}):Play()
                    task.delay(.26,function() spawnRingWave(endP-Vector3.new(0,2,0),violet,4,18,.35) end)
                end
            end)
            Debris:AddItem(meteor,.6)
        end
        spawnFlashLight(pos,violet,4.5,26,.5)
        if actorChar==player.Character then shakeCamera(.45,.35,5) end

    elseif action=="AstralCataclysm" then
        local core=vfxPart("BlackHoleCore",Enum.PartType.Ball,Vector3.new(4,4,4),CFrame.new(pos+Vector3.new(0,4,0)),deepVoid,.05)
        local halo=vfxPart("AccretionDisk",Enum.PartType.Cylinder,Vector3.new(.4,8,8),CFrame.new(pos+Vector3.new(0,4,0))*CFrame.Angles(.3,0,math.pi/2),violet,.15)
        Tween:Create(core,TweenInfo.new(.6,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=Vector3.new(22,22,22),Transparency=1}):Play()
        Tween:Create(halo,TweenInfo.new(.6,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(.2,38,38),Transparency=1}):Play()
        Debris:AddItem(core,.65)
        Debris:AddItem(halo,.65)
        spawnRingWave(pos-Vector3.new(0,2,0),cyan,8,36,.6)
        spawnCraterShards(pos,violet,cyan,8,20,.6)
        spawnFlashLight(pos,violet,6.0,36,.6)
        if actorChar==player.Character then shakeCamera(.9,.6,10) end

    elseif action~="Attack" and action~="Heavy" and action~="Dodge" and action~="Dash" then
        -- MULTI-LAYERED ELEMENTAL BLAST / BEAM / PILLAR FOR ALL Z/X/C/V/F SLOT MOVES (Fruits, Styles, Swords, Guns)
        local primary,secondary,accent=resolveElementPalette(data.element or data.Element,skillId)
        local moveKey=tostring(data.key or data.Key or "")
        local isUltimate=(moveKey=="V" or skillId:find("Sovereign") or skillId:find("Titan") or skillId:find("Cataclysm") or skillId:find("Transform"))
        local scaleMult=isUltimate and 1.55 or (moveKey=="C" and 1.25 or 1.0)

        -- 1. Rising Energy Pillar + Core Sphere
        local pillar=vfxPart("ElementalPillar",Enum.PartType.Cylinder,Vector3.new(28*scaleMult,5*scaleMult,5*scaleMult),CFrame.new(pos+Vector3.new(0,10*scaleMult,0))*CFrame.Angles(0,0,math.pi/2),primary,.12)
        local core=vfxPart("ElementalBurstCore",Enum.PartType.Ball,Vector3.new(4*scaleMult,4*scaleMult,4*scaleMult),CFrame.new(pos),secondary,.08)
        Tween:Create(pillar,TweenInfo.new(.52,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(36*scaleMult,15*scaleMult,15*scaleMult),Transparency=1}):Play()
        Tween:Create(core,TweenInfo.new(.48,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(22*scaleMult,22*scaleMult,22*scaleMult),Transparency=1}):Play()
        Debris:AddItem(pillar,.56)
        Debris:AddItem(core,.52)

        -- 2. Forward Spiralling Beam if directional (Z / X / F)
        if moveKey=="Z" or moveKey=="X" or moveKey=="F" or moveKey=="" then
            local beamCF=lookCF*CFrame.new(0,0,-10*scaleMult)*CFrame.Angles(0,math.pi/2,0)
            local beam=vfxPart("ElementalBeam",Enum.PartType.Cylinder,Vector3.new(20*scaleMult,3.2*scaleMult,3.2*scaleMult),beamCF,primary,.14)
            Tween:Create(beam,TweenInfo.new(.42,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(26*scaleMult,7.5*scaleMult,7.5*scaleMult),Transparency=1}):Play()
            Debris:AddItem(beam,.45)
        end

        -- 3. Multi-layered Shockwave Rings + Ground Crater Shards + PointLight
        spawnRingWave(pos-Vector3.new(0,2,0),primary,5*scaleMult,28*scaleMult,.52)
        spawnRingWave(pos-Vector3.new(0,1.4,0),secondary,3*scaleMult,20*scaleMult,.42)
        spawnCraterShards(pos,primary,accent,isUltimate and 10 or 6,16*scaleMult,.52)
        spawnFlashLight(pos,primary,isUltimate and 6.0 or 4.2,28*scaleMult,.5)

        if actorChar==player.Character or not actorChar then
            shakeCamera(isUltimate and 0.95 or 0.48,isUltimate and 0.52 or 0.32,isUltimate and 10 or 5)
        end
    else
        local orb=vfxPart("SwingOrb",Enum.PartType.Ball,Vector3.new(1.4,1.4,1.4),CFrame.new(pos),gold,.3)
        Tween:Create(orb,TweenInfo.new(.32),{Position=pos+Vector3.new(0,2.5,0),Size=Vector3.new(3.5,3.5,3.5),Transparency=1}):Play()
        Debris:AddItem(orb,.35)
    end
end

-- ============================================================================
-- 5. AAA NEXT-GEN REALM ATMOSPHERE, POST-PROCESSING & SOUNDSCAPE CONTROLLER
-- ============================================================================
local lastAtmosphereKey=""
local lastKnownLevel=nil
local lastKnownQuestId=nil
local lastKnownBossPhase=nil
local hasActiveBoss=false
local RealmEnvOk, RealmEnv = pcall(function()
    return require(game.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RealmEnvironment"))
end)
local function updateRealmAtmosphere()
    local realm=player:GetAttribute("CurrentRealm") or "GoldenSky"
    local hasBoss=hasActiveBoss or (UI.State and UI.State.Boss~=nil)
    local bgmKey=hasBoss and "BossBattle" or ((realm=="FrozenCyber" and "FrozenCyber") or ((realm=="GoldenSky" or realm=="SkyHub") and "GoldenSky") or "ShadowRealm")
    updateBGM(bgmKey)
    local key=realm.."/"..(hasBoss and "Boss" or "Normal")
    if key==lastAtmosphereKey then return end
    lastAtmosphereKey=key

    for _, name in ipairs({"SkybreakRealmCC", "SkybreakRealmBloom", "SkybreakSunRays"}) do
        local old = Lighting:FindFirstChild(name)
        if old then old:Destroy() end
    end

    if RealmEnvOk and RealmEnv and RealmEnv.Apply then
        pcall(function() RealmEnv.Apply(realm) end)
    end
end

player:GetAttributeChangedSignal("CurrentRealm"):Connect(updateRealmAtmosphere)
task.defer(updateRealmAtmosphere)

-- ============================================================================
-- 6. ACTION DISPATCHER & HOTKEY BINDINGS (1-4, Z-X-C-V-F, J, U, H, Y, G)
-- ============================================================================
local function fireSlotMove(keyLetter)
    if UI.BlocksCombat() or UIS:GetFocusedTextBox() then return end
    faceLockedTarget()
    remotes.AbilityRequest:FireServer({action="SlotMove",key=keyLetter})
end

local function send(action)
    if action=="ToggleLock" then
        toggleTargetLock()
        return
    end
    if action=="CycleParty" then
        UI.CyclePartySize()
        return
    end
    if action=="Fruits" then
        local cur=UI.Current or UI.Page
        UI.Show(cur=="Fruits" and "HUD" or "Fruits")
        return
    end
    if UI.BlocksCombat() or UIS:GetFocusedTextBox() then return end
    if action=="Interact" then
        if nearby then
            remotes.InteractRequest:FireServer({interactableId=nearby:GetAttribute("InteractableId")})
        end
        return
    end
    if action=="ToggleAura" then
        remotes.EquipmentRequest:FireServer({action="ToggleAura"})
        return
    end
    if action=="ToggleInstinct" then
        remotes.EquipmentRequest:FireServer({action="ToggleInstinct"})
        return
    end
    if action=="ConquerorBurst" then
        faceLockedTarget()
        remotes.EquipmentRequest:FireServer({action="ConquerorBurst"})
        return
    end
    if action=="ActivateRaceV4" then
        remotes.EquipmentRequest:FireServer({action="ActivateRaceV4"})
        return
    end
    if action=="Z" or action=="X" or action=="C" or action=="F" then
        fireSlotMove(action)
        return
    end
    if action=="SlotMoveZ" or action=="SlotMoveX" or action=="SlotMoveC" or action=="SlotMoveV" or action=="SlotMoveF" then
        fireSlotMove(action:sub(-1))
        return
    end
    if action=="UsePotion" or action=="Potion" or action=="V" then
        faceLockedTarget()
        local ch=player.Character
        local hum=ch and ch:FindFirstChildOfClass("Humanoid")
        local activeSlot=(UI.State and UI.State.ActiveSlot) or (ch and ch:GetAttribute("ActiveSlot")) or player:GetAttribute("ActiveSlot")
        -- Fire SlotMove("V") AND UsePotion (if hurt or using Potion button)
        remotes.AbilityRequest:FireServer({action="SlotMove",key="V"})
        if action=="UsePotion" or action=="Potion" or activeSlot~=2 or (hum and hum.Health<hum.MaxHealth) then
            remotes.EquipmentRequest:FireServer({action="UsePotion"})
        end
        return
    end
    if action=="Slot4" or action=="SelectSlot4" then
        remotes.EquipmentRequest:FireServer({action="SelectSlot",slot=4})
        return
    end
    local slot=SKILL_SLOT_INDEX[action]
    if slot then
        if slot>=1 and slot<=3 then
            remotes.EquipmentRequest:FireServer({action="SelectSlot",slot=slot})
        end
        faceLockedTarget()
        local cid=player:GetAttribute("ClassId") or "SkyGuardian"
        local skills=(C.ClassSkills and C.ClassSkills[cid]) or DEFAULT_SKILLS[cid] or DEFAULT_SKILLS.SkyGuardian
        local skillId=skills[slot] or (DEFAULT_SKILLS[cid] and DEFAULT_SKILLS[cid][slot]) or "SkySlash"
        remotes.AbilityRequest:FireServer({skillId=skillId})
    else
        if action=="Attack" or action=="Heavy" then faceLockedTarget() end
        remotes.CombatRequest:FireServer({action=action})
    end
end

local function beginAttack(input)
    if held or UI.BlocksCombat() then return end
    held=input
    heavySent=false
    attackToken+=1
    local token=attackToken
    task.delay(.4,function()
        if held and token==attackToken then
            heavySent=true
            send("Heavy")
        end
    end)
end

UI.Init(send,beginAttack)

task.spawn(function()
    local markers={}
    local function register(o)
        if o:IsA("BasePart") and o:GetAttribute("InteractableId") then markers[o]=true end
        if o:IsA("ProximityPrompt") then o.Style=Enum.ProximityPromptStyle.Custom end
        if o:IsA("ParticleEmitter") and o.Name=="SkybreakCloud" then o:Emit(8) end
    end
    for _,o in ipairs(workspace:GetDescendants()) do register(o) end
    workspace.DescendantAdded:Connect(register)
    while player.Parent do
        nearby=nil
        local best=12
        local r=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if r and not UI.BlocksCombat() then
            for marker in pairs(markers) do
                if not marker.Parent then
                    markers[marker]=nil
                else
                    local distance=(r.Position-marker.Position).Magnitude
                    if distance<best then
                        best=distance
                        nearby=marker
                    end
                end
            end
        end
        local prompt=nearby and nearby:FindFirstChildOfClass("ProximityPrompt")
        UI.SetInteract(prompt and prompt.ObjectText or nil)
        task.wait(.15)
    end
end)

UIS.InputBegan:Connect(function(input,processed)
    if UIS:GetFocusedTextBox() then return end
    if not processed and input.UserInputType==Enum.UserInputType.MouseButton1 then
        beginAttack(input)
        return
    end
    local kc=input.KeyCode
    if kc==Enum.KeyCode.G then
        local cur=UI.Current or UI.Page
        if cur=="Fruits" then
            UI.Show("HUD")
        else
            UI.Show("Fruits")
        end
    elseif kc==Enum.KeyCode.Z then
        if not UI.BlocksCombat() then
            faceLockedTarget()
            remotes.AbilityRequest:FireServer({action="SlotMove",key="Z"})
        end
    elseif kc==Enum.KeyCode.X then
        if not UI.BlocksCombat() then
            faceLockedTarget()
            remotes.AbilityRequest:FireServer({action="SlotMove",key="X"})
        end
    elseif kc==Enum.KeyCode.C then
        if not UI.BlocksCombat() then
            faceLockedTarget()
            remotes.AbilityRequest:FireServer({action="SlotMove",key="C"})
        end
    elseif kc==Enum.KeyCode.T then
        if not UI.BlocksCombat() then
            faceLockedTarget()
            remotes.AbilityRequest:FireServer({action="SlotMove",key="V"})
        end
    elseif kc==Enum.KeyCode.B then
        if not UI.BlocksCombat() then
            faceLockedTarget()
            remotes.AbilityRequest:FireServer({action="SlotMove",key="F"})
        end
    elseif kc==Enum.KeyCode.U then
        if not UI.BlocksCombat() then
            remotes.EquipmentRequest:FireServer({action="ToggleInstinct"})
        end
    elseif kc==Enum.KeyCode.H then
        if not UI.BlocksCombat() then
            faceLockedTarget()
            remotes.EquipmentRequest:FireServer({action="ConquerorBurst"})
        end
    elseif kc==Enum.KeyCode.Y then
        if not UI.BlocksCombat() then
            remotes.EquipmentRequest:FireServer({action="ActivateRaceV4"})
        end
    elseif kc==Enum.KeyCode.Four then
        if not UI.BlocksCombat() then
            remotes.EquipmentRequest:FireServer({action="SelectSlot",slot=4})
        end
    end
end)
UIS.InputEnded:Connect(function(input)
    if held==input then
        if not heavySent then send("Attack") end
        held=nil
        attackToken+=1
    end
end)
UIS.WindowFocusReleased:Connect(function()
    held=nil
    attackToken+=1
end)

local PAGE_KEYS={
    Inventory=true,
    Classes=true,
    Map=true,
    Settings=true,
}

local keys={
    Interact=Enum.KeyCode.E,
    Dodge=Enum.KeyCode.Q,
    Dash=Enum.KeyCode.LeftShift,
    Skill1=Enum.KeyCode.One,
    Skill2=Enum.KeyCode.Two,
    Skill3=Enum.KeyCode.Three,
    Ultimate=Enum.KeyCode.R,
    UsePotion=Enum.KeyCode.V,
    ToggleLock=Enum.KeyCode.Tab,
    CycleParty=Enum.KeyCode.P,
    Inventory=Enum.KeyCode.I,
    Classes=Enum.KeyCode.K,
    Map=Enum.KeyCode.M,
    Quests=Enum.KeyCode.J,
    Forge=Enum.KeyCode.F,
    Settings=Enum.KeyCode.O,
}

for name,key in pairs(keys) do
    CAS:BindActionAtPriority("Skybreak"..name,function(_,inputState)
        if UIS:GetFocusedTextBox() then return Enum.ContextActionResult.Pass end
        if inputState==Enum.UserInputState.Begin then
            if name=="Quests" then
                local ctrlDown=UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl)
                local shiftDown=UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)
                if shiftDown or UI.Page=="Quests" then
                    UI.Show(UI.Page=="Quests" and "HUD" or "Quests")
                elseif ctrlDown or UI.Page=="HUD" then
                    remotes.EquipmentRequest:FireServer({action="ToggleAura"})
                else
                    UI.Show("Quests")
                end
            elseif name=="Forge" then
                local shiftDown=UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)
                if shiftDown and not UI.BlocksCombat() then
                    faceLockedTarget()
                    remotes.AbilityRequest:FireServer({action="SlotMove",key="F"})
                else
                    UI.Show(UI.Page=="Forge" and "HUD" or "Forge")
                end
            elseif PAGE_KEYS[name] then
                UI.Show(UI.Page==name and "HUD" or name)
            else
                send(name)
            end
        end
        return Enum.ContextActionResult.Sink
    end,false,Enum.ContextActionPriority.High.Value,key)
end

remotes.StateUpdate.OnClientEvent:Connect(function(payload)
    if payload.State then
        local st=payload.State
        if lastKnownLevel and st.Level and st.Level>lastKnownLevel then
            playSFX("level_up",nil,0.01)
        end
        lastKnownLevel=st.Level or lastKnownLevel
        local qid=st.Quest and st.Quest.Id or nil
        if lastKnownQuestId and qid and qid~=lastKnownQuestId then
            playSFX("quest_complete",nil,0.01)
        end
        lastKnownQuestId=qid or lastKnownQuestId
        local b=st.Boss
        local nowBossActive=(b~=nil and ((b.HP and b.MaxHP and b.HP<b.MaxHP) or b.Id=="AureonSentinel" or b.Id=="CryonPrime" or b.Id=="Noxar"))
        local bPhase=b and b.Phase or nil
        if (nowBossActive and not hasActiveBoss) or (lastKnownBossPhase and bPhase and bPhase~=lastKnownBossPhase) then
            playSFX("boss_roar",nil,0.03)
        end
        hasActiveBoss=nowBossActive
        lastKnownBossPhase=bPhase
        UI.SetState(payload.State)
        updateRealmAtmosphere()
    end
    if payload.Message then
        local msg=tostring(payload.Message)
        if msg:find("Lên cấp") then
            playSFX("level_up",nil,0.01)
        elseif msg:find("Hoàn thành") then
            playSFX("quest_complete",nil,0.01)
        elseif msg:find("Rèn") or msg:find("Cường hóa") or msg:find("chế tác") then
            playSFX("forge_anvil",nil,0.03)
        elseif msg:find("Kho Báu") then
            playSFX("chest_open",nil,0.02)
        elseif msg:find("Điện Thờ") then
            playSFX("shrine_bless",nil,0.02)
        end
        UI.Message(payload.Message)
    end
end)

local function playCombatActionSFX(kind,action,pos,combo,element)
    local act=tostring(action or "")
    local el=tostring(element or "")
    if kind=="Dodge" or act=="Dodge" or act=="Dash" or act=="FlashStep" then
        playSFX("dodge_dash",pos,0.06)
    elseif kind=="Shield" or act=="GuardianShield" or act=="ManaBarrier" then
        playSFX("skill_guardian_shield",pos,0.04)
    elseif act=="ConquerorHaki" or act=="ConquerorBurst" or act=="AstralCataclysm" or el=="Void" or act:find("Void") or act:find("Abyss") then
        playSFX("skill_void_rift",pos,0.04)
    elseif act=="ArcCut" or act=="StormBlitz" or act=="ThunderJudgement" or el=="Lightning" or act:find("Thunder") or act:find("Storm") then
        playSFX("skill_thunder_strike",pos,0.05)
    elseif act=="FrostBolt" or act=="ArcaneComet" or el=="Frost" or act:find("Frost") or act:find("Ice") or act:find("Cryo") then
        playSFX("skill_frost_shatter",pos,0.05)
    elseif act=="JudgmentStrike" or act=="CelestialAegis" then
        playSFX("skill_judgment_strike",pos,0.04)
    elseif act=="SkySlash" then
        playSFX("skill_sky_slash",pos,0.04)
    elseif act=="Heavy" then
        playSFX("heavy_cleave",pos,0.05)
    elseif kind=="Swing" or act=="Attack" then
        local c=math.clamp(tonumber(combo) or 1,1,3)
        playSFX("sword_swing_"..tostring(c),pos,0.05)
    else
        playSFX("skill_sky_slash",pos,0.05)
    end
end

local function handleCombatFX(fx)
    if type(fx)~="table" then return end
    local kind=fx.Kind or fx.kind
    local action=fx.Action or fx.action or fx.skillId
    local pos=fx.Position or fx.pos

    if kind=="DamageNumber" or kind=="Hit" or fx.amount~=nil or fx.Amount~=nil or fx.Text~=nil then
        spawnDamagePopup(fx)
    else
        playCombatActionSFX(kind,action,pos,fx.Combo,fx.element or fx.Element)
    end

    local actor=fx.Actor and Players:GetPlayerByUserId(fx.Actor)
    local actorChar=actor and actor.Character

    if actorChar then
        local animAction=kind=="Shield" and "Shield" or action
        if animAction=="JudgmentStrike" or animAction=="ConquerorHaki" then animAction="Heavy"
        elseif animAction=="CelestialAegis" then animAction="SkySlash" end
        if animAction then
            GuardianAnimator.Action(actorChar,animAction,fx.Combo)
        end
    end

    if kind=="Swing" and actorChar then
        local joint=actorChar:FindFirstChild("RightShoulder",true) or actorChar:FindFirstChild("Right Shoulder",true)
        if joint and joint:IsA("Motor6D") and not actorChar:GetAttribute("BlenderGuardian") then
            if not joint:GetAttribute("SkybreakBaseC0") then joint:SetAttribute("SkybreakBaseC0",joint.C0) end
            local base=joint:GetAttribute("SkybreakBaseC0")
            local isHeavy=(action=="Heavy" or action=="JudgmentStrike" or action=="CelestialAegis")
            local offset=isHeavy and CFrame.Angles(-1.8,0,.3) or CFrame.Angles(-.8,0,fx.Combo==2 and .8 or -.8)
            local marker=(joint:GetAttribute("SwingSequence") or 0)+1
            joint:SetAttribute("SwingSequence",marker)
            Tween:Create(joint,TweenInfo.new(.12),{C0=base*offset}):Play()
            task.delay(isHeavy and .4 or .18,function()
                if joint.Parent and joint:GetAttribute("SwingSequence")==marker then
                    Tween:Create(joint,TweenInfo.new(.18),{C0=base}):Play()
                end
            end)
        end
    end

    if kind=="Shield" and typeof(pos)=="Vector3" then
        spawnSkillVFX(action or "GuardianShield",pos,actorChar,fx)
        for _,ally in ipairs(Players:GetPlayers()) do
            local ch=ally.Character
            local r=ch and ch:FindFirstChild("HumanoidRootPart")
            if r and (r.Position-pos).Magnitude<20 then
                if ally.UserId~=fx.Actor then GuardianAnimator.Action(ch,"Shield") end
                local bubble=Instance.new("Part")
                bubble.Name="GuardianShieldVisual"
                bubble.Shape=Enum.PartType.Ball
                bubble.Size=Vector3.new(8,8,8)
                bubble.Anchored=true
                bubble.CanCollide=false
                bubble.CanQuery=false
                bubble.CanTouch=false
                bubble.Material=Enum.Material.ForceField
                bubble.Color=action=="ManaBarrier" and Color3.fromRGB(165,92,255) or Color3.fromRGB(255,209,79)
                bubble.Transparency=.25
                bubble.Parent=tempFX
                task.spawn(function()
                    local untilTime=os.clock()+5
                    while bubble.Parent and r.Parent and os.clock()<untilTime do
                        bubble.CFrame=r.CFrame
                        task.wait(.03)
                    end
                    bubble:Destroy()
                end)
            end
        end
        return
    end

    if typeof(pos)=="Vector3" and (kind=="Swing" or kind=="Dodge" or kind=="Skill" or kind=="Burst" or kind=="SlotMove" or fx.skillId~=nil or fx.key~=nil) then
        spawnSkillVFX(action or "Attack",pos,actorChar,fx)
    end
end

remotes.CombatFX.OnClientEvent:Connect(handleCombatFX)
local combatEventRemote=remotes:FindFirstChild("CombatEvent")
if combatEventRemote and combatEventRemote:IsA("RemoteEvent") then
    combatEventRemote.OnClientEvent:Connect(handleCombatFX)
end
