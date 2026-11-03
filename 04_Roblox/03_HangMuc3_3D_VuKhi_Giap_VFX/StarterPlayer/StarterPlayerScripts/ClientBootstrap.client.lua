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

local function safeLook(a,b,up)
	local d=b-a
	local m=d.Magnitude
	if m<1e-3 then return CFrame.new(a) end
	local u=d/m
	return CFrame.lookAt(a,b,up or (math.abs(u.Y)>0.99 and Vector3.zAxis or Vector3.yAxis))
end

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
local AudioEngine=require(script.Parent:WaitForChild("SkybreakAudioEngine"))
AudioEngine.Bind(UI,tempFX)
local AudioGroup=AudioEngine.AudioGroup
local playSFX=AudioEngine.PlaySFX
local updateBGM=AudioEngine.UpdateBGM
local ClientVFX=nil
do
	local vfxMod=script.Parent:FindFirstChild("SkybreakClientVFX")
	if vfxMod and vfxMod:IsA("ModuleScript") then
		local ok,ext=pcall(require,vfxMod)
		if ok and type(ext)=="table" then
			ClientVFX=ext
			if type(ext.Init)=="function" then
				local okI,errI=xpcall(function()
					ext.Init({Player=player,Config=C,Remotes=remotes,UI=UI,Audio=AudioEngine,TempFX=tempFX})
				end,debug.traceback)
				if not okI then warn("[SKYBREAK] SkybreakClientVFX.Init error:",errI) end
			end
		end
	end
end
task.spawn(function()
	for _,extName in ipairs({"SkybreakWorldClient"}) do
		local extMod=script.Parent:FindFirstChild(extName)
		if extMod and extMod:IsA("ModuleScript") then
			local ok,ext=pcall(require,extMod)
			if ok and type(ext)=="table" and type(ext.Init)=="function" then
				task.spawn(ext.Init,{Player=player,Config=C,Remotes=remotes,UI=UI,Audio=AudioEngine,TempFX=tempFX})
			elseif not ok then
				warn("[SKYBREAK] Failed loading "..extName..":",ext)
			end
		end
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
	if UI.LowFX or player:GetAttribute("LowFXMode")==true then return end
	local camEvt=tempFX:FindFirstChild("SkybreakCameraImpulse")
	if camEvt and camEvt:IsA("BindableEvent") then
		camEvt:Fire(math.clamp((intensity or 0.35)*0.65,0.08,0.85),fovDelta or 0)
		return
	end
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
	lbl.Text="[LOCKED]"
	lbl.Parent=bill

	model.Parent=tempFX
	lockReticle=model
	return model
end

local function toggleTargetLock()
	local cmdEvt=tempFX:FindFirstChild("SkybreakFlightCamCommand")
	if cmdEvt and cmdEvt:IsA("BindableEvent") then
		cmdEvt:Fire("ToggleLock")
		return
	end
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
		UI.Toast("[LOCK] Đã khóa mục tiêu: "..name)
	else
		destroyReticle()
		UI.SetLockTarget(nil)
		UI.Toast("[LOCK] Đã hủy khóa mục tiêu.")
	end
end

local function faceLockedTarget()
	local cmdEvt=tempFX:FindFirstChild("SkybreakFlightCamCommand")
	if cmdEvt and cmdEvt:IsA("BindableEvent") then
		cmdEvt:Fire("FaceLockedTarget")
		return
	end
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
		r.CFrame=safeLook(r.Position,flatTarget)
	end
end

-- ============================================================================
-- 2B. OBSERVATION HAKI (INSTINCT) CLIENT-SIDE VISION EFFECT ([U])
-- ============================================================================
local lastInstinctState=false
local function updateInstinctVision()
	if ClientVFX and type(ClientVFX.UpdateInstinctVision)=="function" then
		ClientVFX.UpdateInstinctVision()
		return
	end
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
local activeDashToken=0
local lastClientDashTime=0
local lastClientDodgeTime=0

local function spawnGeppoRing(footPos,isSkyborn,jumpIdx,rootCF)
	if ClientVFX and type(ClientVFX.SpawnGeppoVFX)=="function" then
		ClientVFX.SpawnGeppoVFX(footPos,isSkyborn,jumpIdx,rootCF)
		return
	end
end

local function spawnDashAfterimage(ch,accentColor)
	if ClientVFX and type(ClientVFX.SpawnDashVFX)=="function" then
		ClientVFX.SpawnDashVFX(ch,nil,accentColor,true)
		return
	end
end

local function spawnDashSonicRing(originCF,accentColor)
	if ClientVFX and type(ClientVFX.SpawnDashVFX)=="function" then
		ClientVFX.SpawnDashVFX(nil,originCF,accentColor,false)
		return
	end
end

local function performDashGlide(actorChar,actionName,dirVec,travelDist,duration)
	if not actorChar then return end
	local root=actorChar:FindFirstChild("HumanoidRootPart")
	local hum=actorChar:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health<=0 then return end

	local now=os.clock()
	local isLocal=(actorChar==player.Character)
	local act=tostring(actionName or "Dash")
	local dist=tonumber(travelDist) or (act=="FlashStep" and 58 or (act=="Dash" and 44 or 38))
	local dur=tonumber(duration) or (act=="FlashStep" and 0.34 or (act=="Dash" and 0.38 or 0.34))

	local moveDir=dirVec
	if typeof(moveDir)~="Vector3" or moveDir.Magnitude<0.05 then
		if hum.MoveDirection.Magnitude>0.05 then
			moveDir=hum.MoveDirection.Unit
		else
			local look=root.CFrame.LookVector
			moveDir=Vector3.new(look.X,0,look.Z)
			if moveDir.Magnitude<0.05 then moveDir=Vector3.new(0,0,-1) else moveDir=moveDir.Unit end
		end
	else
		moveDir=Vector3.new(moveDir.X,0,moveDir.Z)
		if moveDir.Magnitude<0.05 then
			moveDir=Vector3.new(root.CFrame.LookVector.X,0,root.CFrame.LookVector.Z).Unit
		else
			moveDir=moveDir.Unit
		end
	end

	actorChar:SetAttribute("LastDashAt",now)
	actorChar:SetAttribute("DashVariant",act)
	actorChar:SetAttribute("DashDuration",dur)

	local cid=tostring(actorChar:GetAttribute("ClassId") or player:GetAttribute("ClassId") or "SkyGuardian")
	local accentColor=(cid=="ThunderStriker" and Color3.fromRGB(110,235,255))
		or (cid=="ArcaneMage" and Color3.fromRGB(185,120,255))
		or Color3.fromRGB(255,218,98)

	spawnDashSonicRing(safeLook(root.Position,root.Position+moveDir),accentColor)
	spawnDashAfterimage(actorChar,accentColor)

	if not isLocal then return end

	activeDashToken+=1
	local myToken=activeDashToken
	local startClock=os.clock()
	local lastGhostAt=startClock
	local state=hum:GetState()
	local startedAirborne=(state==Enum.HumanoidStateType.Jumping or state==Enum.HumanoidStateType.Freefall)

    -- Face the glide direction smoothly if not back-dodging
	if hum.MoveDirection.Magnitude>0.05 or act~="Dodge" then
		root.CFrame=safeLook(root.Position,root.Position+moveDir)
	end

	local rayParams=RaycastParams.new()
	rayParams.FilterType=Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances={actorChar,tempFX}

	local baseSpeed=dist/math.max(0.18,dur)
	task.spawn(function()
		while activeDashToken==myToken and root.Parent and hum.Parent and hum.Health>0 do
			local elapsed=os.clock()-startClock
			if elapsed>=dur then break end
			local alpha=math.clamp(elapsed/dur,0,1)
            -- High initial burst (1.65x) that glides smoothly into a clean landing carry (0.55x)
			local speedCurve=baseSpeed*(1.62 - 1.08*(alpha*alpha))
			local stepCheck=workspace:Raycast(root.Position,moveDir*3.6,rayParams)
			if stepCheck and stepCheck.Instance and stepCheck.Instance.CanCollide then
				break
			end
			local curVy=root.AssemblyLinearVelocity.Y
			local glideVy=startedAirborne and math.max(curVy, (1-alpha)*11.5) or math.max(curVy,-2)
			root.AssemblyLinearVelocity=moveDir*speedCurve + Vector3.new(0,glideVy,0)

			local tNow=os.clock()
			if tNow-lastGhostAt>=0.075 then
				lastGhostAt=tNow
				spawnDashAfterimage(actorChar,accentColor)
			end
			Run.Heartbeat:Wait()
		end
		if activeDashToken==myToken and root.Parent then
			local endVel=root.AssemblyLinearVelocity
			local carry=moveDir*math.max(hum.WalkSpeed*1.15,24)
			root.AssemblyLinearVelocity=Vector3.new(carry.X,math.max(endVel.Y,-8),carry.Z)
		end
	end)
end

local function performCombatLunge(actorChar,isHeavy)
	if actorChar~=player.Character then return end
	local root=actorChar and actorChar:FindFirstChild("HumanoidRootPart")
	local hum=actorChar and actorChar:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health<=0 then return end
	local now=os.clock()
	local prevAt=tonumber(actorChar:GetAttribute("LastClientAttackAt")) or 0
	local curCombo=tonumber(actorChar:GetAttribute("LastClientAttackCombo")) or 0
	if now-prevAt>1.15 then
		curCombo=1
	else
		curCombo=(curCombo%3)+1
	end
	actorChar:SetAttribute("LastClientAttackCombo",curCombo)
	actorChar:SetAttribute("LastClientAttackHeavy",isHeavy==true)
	actorChar:SetAttribute("LastClientAttackAt",now)
	local look=root.CFrame.LookVector
	local flatLook=Vector3.new(look.X,0,look.Z)
	if flatLook.Magnitude<0.05 then return end
	flatLook=flatLook.Unit
	local lungeSpeed=isHeavy and 28 or 19
	local curVel=root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity=flatLook*lungeSpeed+Vector3.new(0,math.max(curVel.Y,isHeavy and 8 or 0),0)
end

local traversalStateConn=nil
local function bindCharacterTraversal(ch)
	if not ch then return end
	activeDashToken+=1
	airJumpCount=0
	if traversalStateConn then
		traversalStateConn:Disconnect()
		traversalStateConn=nil
	end
	local hum=ch:WaitForChild("Humanoid",5)
	if not hum then return end
	traversalStateConn=hum.StateChanged:Connect(function(oldState,newState)
		if newState==Enum.HumanoidStateType.Landed or newState==Enum.HumanoidStateType.Running or newState==Enum.HumanoidStateType.RunningNoPhysics then
			if oldState==Enum.HumanoidStateType.Freefall and airJumpCount>0 then
				local r=ch:FindFirstChild("HumanoidRootPart")
				playSFX("land_impact",r and r.Position or nil,0.05)
			end
			airJumpCount=0
			ch:SetAttribute("AirJumpIndex",0)
		end
	end)
end

if player.Character then
	task.spawn(bindCharacterTraversal,player.Character)
end
player.CharacterAdded:Connect(bindCharacterTraversal)

UIS.JumpRequest:Connect(function()
	if UI.BlocksCombat() or UIS:GetFocusedTextBox() or player:GetAttribute("SkybreakFlightActive")==true or player:GetAttribute("SkybreakPhotoMode")==true then return end
	local ch=player.Character
	local hum=ch and ch:FindFirstChildOfClass("Humanoid")
	local root=ch and ch:FindFirstChild("HumanoidRootPart")
	if not hum or not root or hum.Health<=0 then return end

	local state=hum:GetState()
	local isAirborne=(state==Enum.HumanoidStateType.Jumping or state==Enum.HumanoidStateType.Freefall)
	if not isAirborne then return end

	local now=os.clock()
	if now-lastAirJumpTime<0.20 then return end

	local race=tostring(ch:GetAttribute("Race") or player:GetAttribute("Race") or "Skyborn")
	local raceV4=tostring(ch:GetAttribute("RaceV4") or player:GetAttribute("RaceV4") or "")
	local maxAirJumps=(raceV4~="" and 12) or (race=="Skyborn" and 9) or 7
	if airJumpCount>=maxAirJumps then return end

	airJumpCount+=1
	lastAirJumpTime=now
	ch:SetAttribute("LastAirJumpAt",now)
	ch:SetAttribute("AirJumpIndex",airJumpCount)

	local vel=root.AssemblyLinearVelocity
	local moveDir=hum.MoveDirection
	local isFlipStep=(airJumpCount%3==0)
	local horizSpeed=math.max(30,hum.WalkSpeed*(isFlipStep and 1.42 or 1.32))
	local horizBoost=(moveDir.Magnitude>0.05) and (moveDir.Unit*horizSpeed) or Vector3.new(vel.X*0.92,0,vel.Z*0.92)
	local jumpVy=isFlipStep and 70 or 64
	root.AssemblyLinearVelocity=Vector3.new(horizBoost.X,jumpVy,horizBoost.Z)
	hum:ChangeState(Enum.HumanoidStateType.Jumping)

	spawnGeppoRing(root.Position-Vector3.new(0,2.75,0),race=="Skyborn" or raceV4~="",airJumpCount,root.CFrame)
	playSFX("geppo_step",root.Position,0.06)
	pcall(function()
		GuardianAnimator.Action(ch,"DoubleJump",airJumpCount)
	end)
end)

Run.RenderStepped:Connect(function()
    -- 1. Update Beast Transformation Camera Pull-back & Height Offset (delegated to SkybreakFlightAndCamera when active)
	local ch=player.Character
	local hum=ch and ch:FindFirstChildOfClass("Humanoid")
	if not tempFX:FindFirstChild("SkybreakFlightCamCommand") then
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
	end

    -- 2. Update Observation Haki (Instinct) Vision Effect
	updateInstinctVision()

    -- 2b. End-of-World 3D Portal Compass Guide (disabled for clean HUD/character view)
	local compass=tempFX:FindFirstChild("WorldGateCompass")
	if compass then
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
	local center=Vector3.new(er.Position.X,floorY+.50,er.Position.Z)
	local t=os.clock()
	if ring then
		ring.CFrame=CFrame.new(center)*CFrame.Angles(0,t*2.2,math.pi/2)
		local bill=ring:FindFirstChild("LockBill")
		local lbl=bill and bill:FindFirstChild("TargetText")
		if lbl then lbl.Text="[LOCKED] "..getEnemyDisplayName(lockedTarget) end
	end
	for i=1,4 do
		local chev=ret:FindFirstChild("Chevron"..i)
		if chev then
			local ang=t*2.6+(i-1)*(math.pi/2)
			local radius=4.2+math.sin(t*6)*.35
			local cPos=center+Vector3.new(math.cos(ang)*radius,.12,math.sin(ang)*radius)
			chev.CFrame=safeLook(cPos,center)
		end
	end
end)

-- ============================================================================
-- 3. 3D FLOATING DAMAGE NUMBERS (spawnDamagePopup)
-- ============================================================================
local function spawnDamagePopup(payload)
	if ClientVFX and type(ClientVFX.SpawnDamagePopup)=="function" then
		ClientVFX.SpawnDamagePopup(payload)
		return
	end
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
		mainLbl.Text="CRIT! "..cleanNum
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
	pl.Brightness=math.clamp(brightness or 1.25,0,1.45)
	pl.Range=math.clamp(range or 13,2,16)
	pl.Parent=node
	Tween:Create(pl,TweenInfo.new(dur or .45,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Brightness=0,Range=math.min(16,pl.Range*1.1)}):Play()
	Debris:AddItem(node,(dur or .45)+.05)
end

local function spawnCraterShards(pos,color,secondaryColor,count,radius,dur)
	local floorPos=pos-Vector3.new(0,2.2,0)
	for i=1,(count or 8) do
		local ang=(i-1)*(2*math.pi/(count or 8))
		local shardPos=floorPos+Vector3.new(math.cos(ang)*radius*0.45,0,math.sin(ang)*radius*0.45)
		local endPos=floorPos+Vector3.new(math.cos(ang)*radius,0.6,math.sin(ang)*radius)
		local shard=vfxPart("CraterShard"..i,Enum.PartType.Block,Vector3.new(0.85,1.8,1.35),safeLook(shardPos,endPos)*CFrame.Angles(0.45,0,0),i%2==0 and color or secondaryColor,0.12)
		Tween:Create(shard,TweenInfo.new(dur or 0.5,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
			CFrame=safeLook(endPos,endPos+Vector3.new(math.cos(ang),0,math.sin(ang)))*CFrame.Angles(0.75,0,0),
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
	pos=pos or data.Position or data.pos
	if ClientVFX and type(ClientVFX.SpawnSkillVFX)=="function" then
		ClientVFX.SpawnSkillVFX(action,pos,actorChar,data)
		return
	end
	local skillId=tostring(data.skillId or action)
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
        -- BESPOKE MULTI-STAGE ANIMATED 3D SKILL VFX FOR Z, X, C, V, F (Novice & All Slot Moves)
		local primary,secondary,accent=resolveElementPalette(data.element or data.Element,skillId)
		local moveKey=string.upper(tostring(data.key or data.moveKey or data.MoveKey or data.Key or ""))
		if moveKey=="" then
			moveKey=action:match("^Skill([ZXCVF])$") or action:match("^Fruit([ZXCVF])$") or ""
		end
		local startPos=typeof(data.startPos)=="Vector3" and data.startPos or pos
		local endPos=typeof(data.endPos)=="Vector3" and data.endPos or pos
		local lookDir=typeof(data.look)=="Vector3" and data.look.Magnitude>0.05 and data.look.Unit or lookCF.LookVector
		local baseCF=safeLook(startPos,startPos+lookDir)
		local activeId=tostring(data.activeId or data.FruitId or data.fruitId or "")
		local actorTF=actorChar and tostring(actorChar:GetAttribute("FruitTransform") or "") or ""
		local isVoidDragon=(activeId=="AbyssalSovereignCore")
			or (actorTF=="AbyssalSovereign" or actorTF=="AbyssalDragonHybrid")
			or skillId:find("Void Heat")~=nil
			or skillId:find("Abyssal Dragon")~=nil
			or skillId:find("Cataclysmic Meteor")~=nil
			or skillId:find("Imperial Sovereign")~=nil
			or skillId:find("Draconic Sky")~=nil

        -- =========================================================================
        -- TRÁI LONG VƯƠNG HƯ KHÔNG (ABYSSAL SOVEREIGN CORE • VOID DRAGON 3D)
        -- Bespoke Multi-Stage 3D Dragon VFX for [Z], [X], [C], [V], [F]
        -- =========================================================================
		if isVoidDragon and (moveKey=="Z" or moveKey=="X" or moveKey=="C" or moveKey=="V" or moveKey=="F") then
			local voidPurple=Color3.fromRGB(182,42,255)
			local dragonCrimson=Color3.fromRGB(255,45,148)
			local obsidianVoid=Color3.fromRGB(24,10,42)
			local dragonGold=Color3.fromRGB(255,212,92)

			if moveKey=="Z" then
                -- =====================================================================
                -- DRAGON [Z]: VOID HEAT WAVE BEAM • LONG TỨC HƯ KHÔNG (BOLO BREATH)
                -- 3D Abyssal Dragon Maw Sigil + 36m Piercing Bolo Breath Laser + 8 Helical Scale Rings + Terminal Black Hole
                -- =====================================================================
				local dFolder=Instance.new("Folder")
				dFolder.Name="VoidDragon_Z_BoloBreath"
				dFolder.Parent=tempFX
				local bDur=0.82
				Debris:AddItem(dFolder,bDur+0.15)

				local mawOrigin=baseCF*CFrame.new(0,1.45,-2.6)
                -- 3D Sculpted Void Dragon Head / Maw Assembly
				local upperSnout=vfxPart("DragonMawUpper",Enum.PartType.Block,Vector3.new(2.8,1.1,3.6),mawOrigin*CFrame.new(0,0.55,0)*CFrame.Angles(math.rad(-8),0,0),obsidianVoid,0.06,Enum.Material.Slate)
				local lowerJaw=vfxPart("DragonMawLower",Enum.PartType.Block,Vector3.new(2.4,0.75,3.2),mawOrigin*CFrame.new(0,-0.55,0.2)*CFrame.Angles(math.rad(12),0,0),obsidianVoid,0.06,Enum.Material.Slate)
				local hornL=vfxPart("DragonHornL",Enum.PartType.Block,Vector3.new(0.45,0.45,3.8),mawOrigin*CFrame.new(-1.35,1.35,1.2)*CFrame.Angles(math.rad(28),math.rad(-22),0),dragonCrimson,0.04)
				local hornR=vfxPart("DragonHornR",Enum.PartType.Block,Vector3.new(0.45,0.45,3.8),mawOrigin*CFrame.new(1.35,1.35,1.2)*CFrame.Angles(math.rad(28),math.rad(22),0),dragonCrimson,0.04)
				local eyeL=vfxPart("DragonEyeL",Enum.PartType.Ball,Vector3.new(0.58,0.42,0.72),mawOrigin*CFrame.new(-1.15,0.85,-0.5),dragonGold,0.02)
				local eyeR=vfxPart("DragonEyeR",Enum.PartType.Ball,Vector3.new(0.58,0.42,0.72),mawOrigin*CFrame.new(1.15,0.85,-0.5),dragonGold,0.02)
				local throatOrb=vfxPart("DragonGulletCore",Enum.PartType.Ball,Vector3.new(1.8,1.8,1.8),mawOrigin*CFrame.new(0,0,-0.8),dragonCrimson,0.02)
				local mawHalo=vfxPart("DragonMawHalo",Enum.PartType.Cylinder,Vector3.new(0.28,5.8,5.8),mawOrigin*CFrame.Angles(0,math.pi*0.5,0),voidPurple,0.12)
				upperSnout.Parent=dFolder lowerJaw.Parent=dFolder hornL.Parent=dFolder hornR.Parent=dFolder
				eyeL.Parent=dFolder eyeR.Parent=dFolder throatOrb.Parent=dFolder mawHalo.Parent=dFolder

                -- Open Dragon Jaws wide as Bolo Breath fires
				Tween:Create(upperSnout,TweenInfo.new(0.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
					CFrame=mawOrigin*CFrame.new(0,1.15,0)*CFrame.Angles(math.rad(22),0,0),
				}):Play()
				Tween:Create(lowerJaw,TweenInfo.new(0.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
					CFrame=mawOrigin*CFrame.new(0,-1.25,0.3)*CFrame.Angles(math.rad(-32),0,0),
				}):Play()
				Tween:Create(throatOrb,TweenInfo.new(0.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
					Size=Vector3.new(3.6,3.6,3.6),
				}):Play()

                -- Multi-layered 36-stud Bolo Breath Laser Core + Plasma Sheath
				local beamLen=36
				local beamCenterCF=mawOrigin*CFrame.new(0,0,-beamLen*0.5)*CFrame.Angles(0,math.pi*0.5,0)
				local innerLaser=vfxPart("BoloBreathCore",Enum.PartType.Cylinder,Vector3.new(beamLen,0.8,0.8),beamCenterCF,dragonCrimson,0.02)
				local outerPlasma=vfxPart("BoloBreathPlasma",Enum.PartType.Cylinder,Vector3.new(beamLen,1.6,1.6),beamCenterCF,voidPurple,0.16)
				local darkMantle=vfxPart("BoloBreathVoidMantle",Enum.PartType.Cylinder,Vector3.new(beamLen,2.4,2.4),beamCenterCF,obsidianVoid,0.32)
				innerLaser.Parent=dFolder outerPlasma.Parent=dFolder darkMantle.Parent=dFolder

				Tween:Create(innerLaser,TweenInfo.new(0.24,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=Vector3.new(beamLen,3.2,3.2)}):Play()
				Tween:Create(outerPlasma,TweenInfo.new(0.26,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=Vector3.new(beamLen,5.8,5.8)}):Play()
				Tween:Create(darkMantle,TweenInfo.new(0.28,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=Vector3.new(beamLen,7.6,7.6)}):Play()

				local helixRings={}
				for i=1,8 do
					local hr=vfxPart("BoloHelixRing"..i,Enum.PartType.Cylinder,Vector3.new(0.35,4.2,4.2),mawOrigin*CFrame.new(0,0,-i*4.2)*CFrame.Angles(0,math.pi*0.5,0),i%2==0 and dragonCrimson or voidPurple,0.10)
					hr.Parent=dFolder
					table.insert(helixRings,{Part=hr,Index=i})
				end

				local impactPos=(mawOrigin*CFrame.new(0,0,-beamLen)).Position
				spawnRingWave(startPos-Vector3.new(0,2.1,0),voidPurple,4,22,0.48)
				spawnFlashLight(mawOrigin.Position,dragonCrimson,6.0,32,0.65)
				spawnFlashLight(impactPos,voidPurple,6.5,38,0.75)

                -- Terminal Singularity Explosion at end of Bolo Breath
				task.delay(0.16,function()
					if not dFolder.Parent then return end
					local bhCore=vfxPart("BoloTerminalSingularity",Enum.PartType.Ball,Vector3.new(3.5,3.5,3.5),CFrame.new(impactPos),obsidianVoid,0.04)
					local bhShell=vfxPart("BoloTerminalShell",Enum.PartType.Ball,Vector3.new(5.5,5.5,5.5),CFrame.new(impactPos),dragonCrimson,0.16)
					bhCore.Parent=dFolder bhShell.Parent=dFolder
					Tween:Create(bhCore,TweenInfo.new(0.55,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(22,22,22),Transparency=1}):Play()
					Tween:Create(bhShell,TweenInfo.new(0.62,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(30,30,30),Transparency=1}):Play()
					spawnRingWave(impactPos-Vector3.new(0,2.0,0),dragonCrimson,5,34,0.58)
					spawnRingWave(impactPos-Vector3.new(0,1.4,0),voidPurple,4,26,0.48)
					spawnCraterShards(impactPos,voidPurple,dragonCrimson,10,18,0.58)
				end)

				local t0=os.clock()
				local connZ
				connZ=Run.RenderStepped:Connect(function()
					local elapsed=os.clock()-t0
					if elapsed>=bDur or not dFolder.Parent then
						if connZ then connZ:Disconnect() connZ=nil end
						return
					end
					local pRatio=elapsed/bDur
					local pulse=1+0.18*math.sin(elapsed*32)
					if mawHalo.Parent then
						mawHalo.CFrame=mawOrigin*CFrame.Angles(elapsed*10,math.pi*0.5,0)
						mawHalo.Size=Vector3.new(0.28,6.2*pulse,6.2*pulse)
					end
					if elapsed>0.52 then
						local fade=(elapsed-0.52)/0.30
						innerLaser.Size=Vector3.new(beamLen,3.2*(1-fade),3.2*(1-fade))
						outerPlasma.Size=Vector3.new(beamLen,5.8*(1-fade*0.7),5.8*(1-fade*0.7))
						innerLaser.Transparency=fade
						outerPlasma.Transparency=0.16+fade*0.84
						darkMantle.Transparency=0.32+fade*0.68
						upperSnout.Transparency=fade lowerJaw.Transparency=fade
						hornL.Transparency=fade hornR.Transparency=fade
						throatOrb.Transparency=fade
					end
					for _,item in ipairs(helixRings) do
						if item.Part and item.Part.Parent then
							local travel=((elapsed*42+(item.Index-1)*4.5)%beamLen)
							local rScale=(4.8+math.sin(elapsed*20+item.Index)*1.4)*(1-pRatio*0.35)
							item.Part.CFrame=mawOrigin*CFrame.new(0,0,-travel)*CFrame.Angles(elapsed*14+item.Index,math.pi*0.5,0)
							item.Part.Size=Vector3.new(0.32,rScale,rScale)
							item.Part.Transparency=math.clamp(pRatio*1.1,0.1,1)
						end
					end
				end)

				if actorChar==player.Character or not actorChar then
					shakeCamera(0.68,0.45,8)
				end
				return

			elseif moveKey=="X" then
                -- =====================================================================
                -- DRAGON [X]: ABYSSAL DRAGON TALONS • HẮC LONG TRẢO KÍCH
                -- Twin Colossal 4-Clawed 3D Dragon Talons Raking in X-Cross + 8 Spatial Void Rifts + 6 Dragon Fang Spires
                -- =====================================================================
				local xFolder=Instance.new("Folder")
				xFolder.Name="VoidDragon_X_Talons"
				xFolder.Parent=tempFX
				local xDur=0.78
				Debris:AddItem(xFolder,xDur+0.15)

				local midCF=safeLook(startPos,startPos+lookDir)*CFrame.new(0,0.8,-5.5)
                -- Build Left & Right Giant 4-Clawed 3D Dragon Talons
				for _,side in ipairs({-1,1}) do
					local startClawCF=baseCF*CFrame.new(side*5.2,2.8,-1.5)*CFrame.Angles(math.rad(-18),math.rad(-side*28),math.rad(side*38))
					local endClawCF=baseCF*CFrame.new(-side*3.6,0.2,-13.5)*CFrame.Angles(math.rad(24),math.rad(side*32),math.rad(-side*42))
					local palm=vfxPart("DragonTalonPalm_"..side,Enum.PartType.Block,Vector3.new(2.4,0.85,2.2),startClawCF,obsidianVoid,0.06,Enum.Material.Slate)
					palm.Parent=xFolder
					Tween:Create(palm,TweenInfo.new(0.34,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
						CFrame=endClawCF,
						Transparency=1,
					}):Play()

					for finger=1,4 do
						local fOff=(finger-2.5)*0.68
						local clawBlade=vfxPart("DragonClawBlade_"..side.."_"..finger,Enum.PartType.Block,Vector3.new(0.32,0.48,5.8),startClawCF*CFrame.new(fOff,0,-2.6),finger%2==0 and dragonCrimson or voidPurple,0.04)
						local clawCore=vfxPart("DragonClawCore_"..side.."_"..finger,Enum.PartType.Block,Vector3.new(0.18,0.28,6.4),startClawCF*CFrame.new(fOff,0,-2.9),obsidianVoid,0.02)
						clawBlade.Parent=xFolder clawCore.Parent=xFolder
						Tween:Create(clawBlade,TweenInfo.new(0.36,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
							CFrame=endClawCF*CFrame.new(fOff*1.4,0,-3.8),
							Size=Vector3.new(0.18,0.28,9.2),
							Transparency=1,
						}):Play()
						Tween:Create(clawCore,TweenInfo.new(0.36,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
							CFrame=endClawCF*CFrame.new(fOff*1.4,0,-4.2),
							Size=Vector3.new(0.10,0.16,9.8),
							Transparency=1,
						}):Play()
					end
				end

                -- 8 Suspended Spatial Void Rift Slash Gashes forming a glowing X-Cross
				for g=1,8 do
					local side=(g<=4) and -1 or 1
					local lane=((g-1)%4)-1.5
					local gCF=midCF*CFrame.Angles(0,0,math.rad(side*38))*CFrame.new(0,lane*0.95,-(g%2)*0.6)
					local gash=vfxPart("SpatialRiftGash_"..g,Enum.PartType.Block,Vector3.new(13.5,0.28,0.85),gCF,g%2==0 and dragonCrimson or voidPurple,0.04)
					local gashVoid=vfxPart("SpatialRiftCore_"..g,Enum.PartType.Block,Vector3.new(11.5,0.42,0.45),gCF,obsidianVoid,0.02)
					gash.Parent=xFolder gashVoid.Parent=xFolder
					Tween:Create(gash,TweenInfo.new(0.52,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
						Size=Vector3.new(20.5,0.12,1.8),
						CFrame=gCF*CFrame.new(0,0,-2.5),
						Transparency=1,
					}):Play()
					Tween:Create(gashVoid,TweenInfo.new(0.48,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
						Size=Vector3.new(17.5,0.18,0.9),
						CFrame=gCF*CFrame.new(0,0,-2.5),
						Transparency=1,
					}):Play()
				end

                -- 6 Erupting Dragon Fang Spires at endPos
				local impactCenter=endPos
				local floorY=impactCenter.Y-2.3
				for f=1,6 do
					local ang=(f-1)*(math.pi/3)
					local spirePos=Vector3.new(impactCenter.X+math.cos(ang)*5.2,floorY,impactCenter.Z+math.sin(ang)*5.2)
					local fang=vfxPart("DragonFangSpire_"..f,Enum.PartType.Block,Vector3.new(1.4,1.2,1.4),CFrame.new(spirePos)*CFrame.Angles(math.cos(ang)*0.28,ang,math.sin(ang)*0.28),f%2==0 and voidPurple or dragonCrimson,0.08)
					fang.Parent=xFolder
					Tween:Create(fang,TweenInfo.new(0.45,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
						Size=Vector3.new(1.8,9.5,1.8),
						CFrame=CFrame.new(spirePos+Vector3.new(0,4.2,0))*CFrame.Angles(math.cos(ang)*0.35,ang,math.sin(ang)*0.35),
						Transparency=1,
					}):Play()
				end

				spawnRingWave(Vector3.new(impactCenter.X,floorY,impactCenter.Z),dragonCrimson,4,28,0.52)
				spawnRingWave(Vector3.new(impactCenter.X,floorY+0.4,impactCenter.Z),voidPurple,3,22,0.42)
				spawnCraterShards(impactCenter,voidPurple,dragonCrimson,8,16,0.52)
				spawnFlashLight(impactCenter+Vector3.new(0,2,0),dragonCrimson,5.8,30,0.55)
				if actorChar==player.Character or not actorChar then
					shakeCamera(0.62,0.38,7)
				end
				return

			elseif moveKey=="C" then
                -- =====================================================================
                -- DRAGON [C]: CATACLYSMIC METEOR SHOWER • MƯA THIÊN THẠCH LONG TINH
                -- Live 12-Segment Coiling Serpentine Dragon Twister + Sky Stargate Portal + 10 Void Dragon Meteors
                -- =====================================================================
				local center=endPos
				local floorY=center.Y-2.3
				local cFolder=Instance.new("Folder")
				cFolder.Name="VoidDragon_C_MeteorTwister"
				cFolder.Parent=tempFX
				local cDur=1.05
				Debris:AddItem(cFolder,cDur+0.2)

                -- Overhead Dimensional Abyssal Stargate Ring (26 studs above target)
				local skyOrigin=center+Vector3.new(0,26,0)
				local skyPortal=vfxPart("AbyssalSkyPortal",Enum.PartType.Cylinder,Vector3.new(0.45,6,6),CFrame.new(skyOrigin)*CFrame.Angles(0,0,math.pi*0.5),voidPurple,0.12)
				local skyCore=vfxPart("AbyssalSkyCore",Enum.PartType.Cylinder,Vector3.new(0.55,4,4),CFrame.new(skyOrigin)*CFrame.Angles(0,0,math.pi*0.5),obsidianVoid,0.06)
				skyPortal.Parent=cFolder skyCore.Parent=cFolder
				Tween:Create(skyPortal,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=Vector3.new(0.45,30,30)}):Play()
				Tween:Create(skyCore,TweenInfo.new(0.35,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=Vector3.new(0.55,24,24)}):Play()

                -- Live 12-Segment Coiling Serpentine Dragon Twister on RenderStepped
				local serpentSegs={}
				for s=1,12 do
					local isHead=(s==1)
					local seg=vfxPart("SerpentTwisterSeg_"..s,isHead and Enum.PartType.Block or Enum.PartType.Ball,isHead and Vector3.new(2.2,1.6,3.2) or Vector3.new(1.85-s*0.08,1.85-s*0.08,2.4),CFrame.new(center),s%2==0 and dragonCrimson or voidPurple,0.06)
					seg.Parent=cFolder
					table.insert(serpentSegs,{Part=seg,Index=s})
				end

				local t0=os.clock()
				local connC
				connC=Run.RenderStepped:Connect(function()
					local elapsed=os.clock()-t0
					if elapsed>=cDur or not cFolder.Parent then
						if connC then connC:Disconnect() connC=nil end
						return
					end
					local pRatio=elapsed/cDur
					local fade=pRatio>0.72 and ((pRatio-0.72)/0.28) or 0
					for _,seg in ipairs(serpentSegs) do
						if seg.Part and seg.Part.Parent then
							local idx=seg.Index
							local ang=elapsed*14-idx*0.52
							local yH=floorY+1.2+((elapsed*20+(12-idx)*1.8)%22)
							local rad=(4.2+(yH-floorY)*0.28)*(1+pRatio*0.25)
							local posNow=Vector3.new(center.X+math.cos(ang)*rad,yH,center.Z+math.sin(ang)*rad)
							local nextAng=ang+0.35
							local posNext=Vector3.new(center.X+math.cos(nextAng)*rad,yH+0.6,center.Z+math.sin(nextAng)*rad)
							seg.Part.CFrame=safeLook(posNow,posNext)
							seg.Part.Transparency=0.06+fade*0.94
						end
					end
					if skyPortal.Parent and fade>0 then
						skyPortal.Transparency=0.12+fade*0.88
						skyCore.Transparency=0.06+fade*0.94
					end
				end)

                -- Rain down 10 Blazing Void Dragon Meteors from Sky Portal
				for m=1,10 do
					task.delay((m-1)*0.065,function()
						if not cFolder.Parent then return end
						local mAng=(m-1)*(2*math.pi/10)+0.3
						local mRad=(m%3)*4.2+2.5
						local startM=skyOrigin+Vector3.new(math.cos(mAng)*mRad*0.6,0,math.sin(mAng)*mRad*0.6)
						local endM=Vector3.new(center.X+math.cos(mAng)*mRad,floorY+0.6,center.Z+math.sin(mAng)*mRad)
						local mCore=vfxPart("VoidMeteorCore_"..m,Enum.PartType.Ball,Vector3.new(2.8,2.8,2.8),CFrame.new(startM),obsidianVoid,0.02)
						local mMantle=vfxPart("VoidMeteorMantle_"..m,Enum.PartType.Ball,Vector3.new(4.2,4.2,4.2),CFrame.new(startM),m%2==0 and dragonCrimson or voidPurple,0.16)
						local mTail=vfxPart("VoidMeteorTail_"..m,Enum.PartType.Cylinder,Vector3.new(9.5,1.4,1.4),safeLook(startM,endM)*CFrame.Angles(0,math.pi*0.5,0),dragonCrimson,0.14)
						mCore.Parent=cFolder mMantle.Parent=cFolder mTail.Parent=cFolder

						local fallTime=0.26
						Tween:Create(mCore,TweenInfo.new(fallTime,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=endM,Size=Vector3.new(4.8,4.8,4.8),Transparency=1}):Play()
						Tween:Create(mMantle,TweenInfo.new(fallTime,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=endM,Size=Vector3.new(7.5,7.5,7.5),Transparency=1}):Play()
						Tween:Create(mTail,TweenInfo.new(fallTime,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{CFrame=safeLook(endM,endM+(endM-startM))*CFrame.Angles(0,math.pi*0.5,0),Size=Vector3.new(14,0.3,0.3),Transparency=1}):Play()
						task.delay(fallTime-0.02,function()
							spawnRingWave(endM,m%2==0 and dragonCrimson or voidPurple,3,18,0.34)
							if m%3==1 then
								spawnCraterShards(endM+Vector3.new(0,2,0),voidPurple,dragonCrimson,6,10,0.36)
								spawnFlashLight(endM+Vector3.new(0,2,0),dragonCrimson,4.5,24,0.35)
							end
						end)
					end)
				end

				spawnRingWave(Vector3.new(center.X,floorY,center.Z),voidPurple,5,34,0.65)
				if actorChar==player.Character or not actorChar then
					shakeCamera(0.78,0.48,8)
				end
				return

			elseif moveKey=="V" then
                -- =====================================================================
                -- DRAGON [V]: IMPERIAL SOVEREIGN DRAGON 3D • HÓA THÂN THÁI CỔ LONG HOÀNG
                -- 16-Segment Ascending Coiling Sovereign Dragon + Conqueror Singularity Dome + 10 Abyssal Dragon Pillars
                -- =====================================================================
				local center=actorRoot and actorRoot.Position or startPos
				local floorY=center.Y-2.35
				local vFolder=Instance.new("Folder")
				vFolder.Name="VoidDragon_V_ImperialAscension"
				vFolder.Parent=tempFX
				local vDur=1.25
				Debris:AddItem(vFolder,vDur+0.2)

                -- 1. Floor Imperial Dragon Seal + Expanding Obsidian-Crimson Singularity Dome
				local sealRing=vfxPart("ImperialDragonSeal",Enum.PartType.Cylinder,Vector3.new(0.28,8,8),CFrame.new(center.X,floorY,center.Z)*CFrame.Angles(0,0,math.pi*0.5),dragonCrimson,0.10)
				local outerDome=vfxPart("ImperialSingularityDome",Enum.PartType.Ball,Vector3.new(6,6,6),CFrame.new(center),voidPurple,0.18)
				local innerObsidian=vfxPart("ImperialObsidianCore",Enum.PartType.Ball,Vector3.new(4,4,4),CFrame.new(center),obsidianVoid,0.08)
				sealRing.Parent=vFolder outerDome.Parent=vFolder innerObsidian.Parent=vFolder

				Tween:Create(sealRing,TweenInfo.new(0.55,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=Vector3.new(0.28,44,44),Transparency=1}):Play()
				Tween:Create(outerDome,TweenInfo.new(0.75,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(68,68,68),Transparency=1}):Play()
				Tween:Create(innerObsidian,TweenInfo.new(0.62,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(52,52,52),Transparency=1}):Play()

                -- 2. 16-Segment Ascending Coiling Sovereign Dragon Spirit + Horns + Crown
				local dragonCoil={}
				for s=1,16 do
					local isHead=(s==1)
					local seg=vfxPart("ImperialCoilSeg_"..s,isHead and Enum.PartType.Block or Enum.PartType.Ball,isHead and Vector3.new(3.2,2.4,4.5) or Vector3.new(2.6-s*0.10,2.6-s*0.10,3.2),CFrame.new(center),s%2==0 and dragonCrimson or voidPurple,0.04)
					seg.Parent=vFolder
					local hornL,hornR=nil,nil
					if isHead then
						hornL=vfxPart("ImperialCoilHornL",Enum.PartType.Block,Vector3.new(0.45,0.45,4.2),CFrame.new(center),dragonGold,0.02)
						hornR=vfxPart("ImperialCoilHornR",Enum.PartType.Block,Vector3.new(0.45,0.45,4.2),CFrame.new(center),dragonGold,0.02)
						hornL.Parent=vFolder hornR.Parent=vFolder
					end
					table.insert(dragonCoil,{Part=seg,HornL=hornL,HornR=hornR,Index=s})
				end

                -- 3. 10 Orbiting Abyssal Dragon Pillars & Conqueror Void Lightning Bolts
				local dragonPillars={}
				for p=1,10 do
					local pil=vfxPart("ImperialDragonPillar_"..p,Enum.PartType.Cylinder,Vector3.new(38,3.2,3.2),CFrame.new(center)*CFrame.Angles(0,0,math.pi*0.5),p%2==0 and dragonCrimson or voidPurple,0.10)
					pil.Parent=vFolder
					table.insert(dragonPillars,{Part=pil,Index=p})

					local bAng=(p-1)*(2*math.pi/10)
					local bolt=vfxPart("ImperialVoidBolt_"..p,Enum.PartType.Block,Vector3.new(0.65,0.65,16),CFrame.new(center)*CFrame.Angles(0,bAng,0)*CFrame.new(0,2.5,-8)*CFrame.Angles(0.28,(p%2==0 and 0.35 or -0.35),0),p%2==0 and dragonCrimson or dragonGold,0.04)
					bolt.Parent=vFolder
					Tween:Create(bolt,TweenInfo.new(0.62,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
						CFrame=CFrame.new(center)*CFrame.Angles(0,bAng+0.3,0)*CFrame.new(0,4.5,-30),
						Size=Vector3.new(0.2,0.2,24),
						Transparency=1,
					}):Play()
				end

				spawnRingWave(Vector3.new(center.X,floorY,center.Z),dragonCrimson,8,64,0.72)
				spawnRingWave(Vector3.new(center.X,floorY+0.5,center.Z),voidPurple,6,52,0.62)
				spawnRingWave(Vector3.new(center.X,floorY+1.0,center.Z),dragonGold,4,40,0.52)
				spawnCraterShards(center,voidPurple,dragonCrimson,12,26,0.68)
				spawnFlashLight(center+Vector3.new(0,4,0),dragonCrimson,7.5,48,0.75)

				local t0=os.clock()
				local connV
				connV=Run.RenderStepped:Connect(function()
					local elapsed=os.clock()-t0
					if elapsed>=vDur or not vFolder.Parent then
						if connV then connV:Disconnect() connV=nil end
						return
					end
					local pRatio=elapsed/vDur
					local fade=pRatio>0.68 and ((pRatio-0.68)/0.32) or 0
					for _,dc in ipairs(dragonCoil) do
						if dc.Part and dc.Part.Parent then
							local idx=dc.Index
							local ang=elapsed*12-idx*0.42
							local yH=floorY+1.5+elapsed*18-idx*1.05
							local rad=6.8+math.sin(elapsed*6+idx*0.3)*1.8+pRatio*4.5
							local posNow=Vector3.new(center.X+math.cos(ang)*rad,math.max(floorY+0.8,yH),center.Z+math.sin(ang)*rad)
							local nextAng=ang+0.35
							local posNext=Vector3.new(center.X+math.cos(nextAng)*rad,math.max(floorY+1.2,yH+0.9),center.Z+math.sin(nextAng)*rad)
							local headCF=safeLook(posNow,posNext)
							dc.Part.CFrame=headCF
							dc.Part.Transparency=0.04+fade*0.96
							if dc.HornL and dc.HornR then
								dc.HornL.CFrame=headCF*CFrame.new(-1.3,1.1,1.2)*CFrame.Angles(math.rad(28),math.rad(-20),0)
								dc.HornR.CFrame=headCF*CFrame.new(1.3,1.1,1.2)*CFrame.Angles(math.rad(28),math.rad(20),0)
								dc.HornL.Transparency=0.02+fade*0.98
								dc.HornR.Transparency=0.02+fade*0.98
							end
						end
					end
					for _,dp in ipairs(dragonPillars) do
						if dp.Part and dp.Part.Parent then
							local ang=elapsed*6.5+(dp.Index-1)*(2*math.pi/10)
							local rad=6.0+pRatio*18.5
							local px=center.X+math.cos(ang)*rad
							local pz=center.Z+math.sin(ang)*rad
							dp.Part.CFrame=CFrame.new(px,floorY+17,pz)*CFrame.Angles(0,0,math.pi*0.5)
							dp.Part.Size=Vector3.new(38,3.2*(1-pRatio*0.7),3.2*(1-pRatio*0.7))
							dp.Part.Transparency=0.10+pRatio*0.90
						end
					end
				end)

				if actorChar==player.Character or not actorChar then
					shakeCamera(1.15,0.58,11)
				end
				return

			elseif moveKey=="F" then
                -- =====================================================================
                -- DRAGON [F]: DRACONIC SKY SOAR • HẮC LONG DU VÂN
                -- 3D Serpentine Dragon Flight Spirit + Flapping Abyssal Wings + 8 Flame Cloud Rings
                -- =====================================================================
				local dashVec=endPos-startPos
				local dashDist=dashVec.Magnitude
				local dashDir=dashDist>0.5 and dashVec.Unit or lookDir
				local actualEnd=dashDist>0.5 and endPos or (startPos+dashDir*26)
				local totalDist=(actualEnd-startPos).Magnitude
				local pathCF=safeLook(startPos,actualEnd)

				local fFolder=Instance.new("Folder")
				fFolder.Name="VoidDragon_F_SkySoar"
				fFolder.Parent=tempFX
				local fDur=0.58
				Debris:AddItem(fFolder,fDur+0.15)

				spawnRingWave(startPos-Vector3.new(0,2.0,0),voidPurple,4,20,0.40)
				spawnFlashLight(startPos,dragonCrimson,5.0,26,0.42)

                -- 8 Flaming Abyssal Cloud Rings along the flight trajectory
				for i=1,8 do
					local alpha=i/8
					local stepCF=pathCF*CFrame.new(0,0,-totalDist*alpha)
					task.delay((i-1)*0.032,function()
						if not fFolder.Parent then return end
						local cloudRing=vfxPart("DragonCloudRing_"..i,Enum.PartType.Cylinder,Vector3.new(0.36,3.8,3.8),stepCF*CFrame.Angles(0,math.pi*0.5,0),i%2==0 and dragonCrimson or voidPurple,0.12)
						cloudRing.Parent=fFolder
						Tween:Create(cloudRing,TweenInfo.new(0.36,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
							Size=Vector3.new(0.12,11.5,11.5),
							Transparency=1,
						}):Play()
					end)
				end

                -- 10-Segment Serpentine Dragon Flight Avatar + Twin Flapping Abyssal Wings
				local soarSegs={}
				for s=1,10 do
					local seg=vfxPart("SoarDragonSeg_"..s,s==1 and Enum.PartType.Block or Enum.PartType.Ball,s==1 and Vector3.new(2.4,1.6,3.4) or Vector3.new(2.0-s*0.12,2.0-s*0.12,2.6),pathCF,s%2==0 and dragonCrimson or voidPurple,0.06)
					seg.Parent=fFolder
					table.insert(soarSegs,{Part=seg,Index=s})
				end
				local wingL=vfxPart("SoarDragonWingL",Enum.PartType.Block,Vector3.new(6.8,0.28,3.2),pathCF,dragonCrimson,0.08)
				local wingR=vfxPart("SoarDragonWingR",Enum.PartType.Block,Vector3.new(6.8,0.28,3.2),pathCF,dragonCrimson,0.08)
				wingL.Parent=fFolder wingR.Parent=fFolder

				local t0=os.clock()
				local connF
				connF=Run.RenderStepped:Connect(function()
					local elapsed=os.clock()-t0
					if elapsed>=fDur or not fFolder.Parent then
						if connF then connF:Disconnect() connF=nil end
						return
					end
					local pRatio=elapsed/fDur
					local fade=pRatio>0.65 and ((pRatio-0.65)/0.35) or 0
					for _,sg in ipairs(soarSegs) do
						if sg.Part and sg.Part.Parent then
							local idx=sg.Index
							local distAlong=math.clamp(pRatio*totalDist*1.15-(idx-1)*2.4,0,totalDist)
							local waveX=math.sin(elapsed*24-idx*0.65)*1.85
							local waveY=math.cos(elapsed*24-idx*0.65)*0.95
							local segCF=pathCF*CFrame.new(waveX,waveY,-distAlong)
							sg.Part.CFrame=segCF
							sg.Part.Transparency=0.06+fade*0.94
							if idx==2 then
								local flap=math.sin(elapsed*28)*0.45
								wingL.CFrame=segCF*CFrame.new(-3.6,0.4,0)*CFrame.Angles(0,math.rad(18),flap)
								wingR.CFrame=segCF*CFrame.new(3.6,0.4,0)*CFrame.Angles(0,math.rad(-18),-flap)
								wingL.Transparency=0.08+fade*0.92
								wingR.Transparency=0.08+fade*0.92
							end
						end
					end
				end)

				task.delay(0.24,function()
					spawnRingWave(actualEnd-Vector3.new(0,2.1,0),dragonCrimson,4,22,0.38)
					spawnFlashLight(actualEnd,voidPurple,5.2,28,0.38)
				end)
				if actorChar==player.Character or not actorChar then
					shakeCamera(0.45,0.28,5)
				end
				return
			end
		end

        -- =========================================================================
        -- BESPOKE MULTI-STAGE 3D VFX FOR ALL OTHER DEVIL FRUITS (SLOT 2)
        -- =========================================================================
		if activeId=="SolarFlameCore" and (moveKey=="Z" or moveKey=="X" or moveKey=="C" or moveKey=="V" or moveKey=="F") then
			local fOrange=Color3.fromRGB(255,96,32)
			local fGold=Color3.fromRGB(255,224,72)
			local fRed=Color3.fromRGB(210,24,38)
			if moveKey=="Z" then
                -- FIRE BULLETS: 6 Blazing Solar Fireballs rocketing in a spread fan
				for i=1,6 do
					local spread=(i-3.5)*0.12
					local dirCF=baseCF*CFrame.Angles(0,spread,0)
					local orb=vfxPart("FireBullet_"..i,Enum.PartType.Ball,Vector3.new(1.8,1.8,1.8),dirCF*CFrame.new(0,0.6,-2.5),i%2==0 and fOrange or fGold,0.04)
					local halo=vfxPart("FireBulletHalo_"..i,Enum.PartType.Ball,Vector3.new(2.8,2.8,2.8),orb.CFrame,fRed,0.22)
					local dest=(dirCF*CFrame.new(0,0.4,-26)).Position
					task.delay((i-1)*0.045,function()
						Tween:Create(orb,TweenInfo.new(0.32,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=dest,Size=Vector3.new(3.6,3.6,3.6),Transparency=1}):Play()
						Tween:Create(halo,TweenInfo.new(0.32,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=dest,Size=Vector3.new(6.5,6.5,6.5),Transparency=1}):Play()
						task.delay(0.28,function() spawnRingWave(dest-Vector3.new(0,2,0),fOrange,2,12,0.28) end)
					end)
					Debris:AddItem(orb,0.65) Debris:AddItem(halo,0.65)
				end
				spawnFlashLight(startPos,fOrange,4.8,24,0.4)
				return
			elseif moveKey=="X" then
                -- BLAZING BEAM (HỎA QUYỀN): Colossal 3D Flaming Fist + 30m Solar Prominence Beam
				local fist=vfxPart("ProminenceFist",Enum.PartType.Block,Vector3.new(4.8,4.8,6.5),baseCF*CFrame.new(0,0.8,-4),fOrange,0.04)
				local beam=vfxPart("ProminenceBeam",Enum.PartType.Cylinder,Vector3.new(30,3.8,3.8),baseCF*CFrame.new(0,0.8,-16)*CFrame.Angles(0,math.pi*0.5,0),fGold,0.08)
				local sheath=vfxPart("ProminenceSheath",Enum.PartType.Cylinder,Vector3.new(30,6.4,6.4),beam.CFrame,fRed,0.24)
				Tween:Create(fist,TweenInfo.new(0.42,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{CFrame=baseCF*CFrame.new(0,0.8,-30),Size=Vector3.new(8.5,8.5,10),Transparency=1}):Play()
				Tween:Create(beam,TweenInfo.new(0.48,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(32,0.5,0.5),Transparency=1}):Play()
				Tween:Create(sheath,TweenInfo.new(0.52,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(32,11,11),Transparency=1}):Play()
				Debris:AddItem(fist,0.48) Debris:AddItem(beam,0.52) Debris:AddItem(sheath,0.56)
				for rIdx=1,5 do
					spawnRingWave((baseCF*CFrame.new(0,-1.5,-rIdx*5.5)).Position,rIdx%2==0 and fGold or fOrange,3,16,0.42)
				end
				if actorChar==player.Character then shakeCamera(0.55,0.35,6) end
				return
			elseif moveKey=="C" then
                -- FLAME PILLAR: 34m Inferno Geyser Column + 6 Surrounding Flame Pillars
				local mainPillar=vfxPart("FlamePillarMain",Enum.PartType.Cylinder,Vector3.new(34,7.5,7.5),CFrame.new(startPos+Vector3.new(0,14,0))*CFrame.Angles(0,0,math.pi*0.5),fOrange,0.08)
				Tween:Create(mainPillar,TweenInfo.new(0.62,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(38,18,18),Transparency=1}):Play()
				Debris:AddItem(mainPillar,0.66)
				for i=1,6 do
					local ang=(i-1)*(math.pi/3)
					local subP=startPos+Vector3.new(math.cos(ang)*8.5,10,math.sin(ang)*8.5)
					local sub=vfxPart("FlamePillarSub_"..i,Enum.PartType.Cylinder,Vector3.new(24,3.2,3.2),CFrame.new(subP)*CFrame.Angles(0,0,math.pi*0.5),i%2==0 and fGold or fRed,0.12)
					Tween:Create(sub,TweenInfo.new(0.55,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(28,7.5,7.5),Transparency=1}):Play()
					Debris:AddItem(sub,0.6)
				end
				spawnRingWave(startPos-Vector3.new(0,2.2,0),fOrange,6,32,0.58)
				spawnCraterShards(startPos,fOrange,fGold,10,18,0.58)
				if actorChar==player.Character then shakeCamera(0.7,0.42,8) end
				return
			elseif moveKey=="V" then
                -- SOLAR EMPEROR (DAI ENKAI: ENTEI): Giant 20m Overhead Mini-Sun hurled into endPos!
				local sunOrigin=startPos+Vector3.new(0,18,0)
				local sunCore=vfxPart("SolarEmperorCore",Enum.PartType.Ball,Vector3.new(4,4,4),CFrame.new(sunOrigin),fGold,0.02)
				local sunMantle=vfxPart("SolarEmperorMantle",Enum.PartType.Ball,Vector3.new(6,6,6),CFrame.new(sunOrigin),fOrange,0.16)
				local sunCorona=vfxPart("SolarEmperorCorona",Enum.PartType.Cylinder,Vector3.new(0.4,8,8),CFrame.new(sunOrigin),fRed,0.14)
				Tween:Create(sunCore,TweenInfo.new(0.36,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=Vector3.new(16,16,16)}):Play()
				Tween:Create(sunMantle,TweenInfo.new(0.36,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=Vector3.new(21,21,21)}):Play()
				Tween:Create(sunCorona,TweenInfo.new(0.36,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=Vector3.new(0.4,28,28)}):Play()
				task.delay(0.38,function()
					if sunCore.Parent then
						Tween:Create(sunCore,TweenInfo.new(0.22,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=endPos,Size=Vector3.new(38,38,38),Transparency=1}):Play()
						Tween:Create(sunMantle,TweenInfo.new(0.26,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=endPos,Size=Vector3.new(52,52,52),Transparency=1}):Play()
						Tween:Create(sunCorona,TweenInfo.new(0.26),{Position=endPos,Size=Vector3.new(0.2,60,60),Transparency=1}):Play()
						task.delay(0.20,function()
							spawnRingWave(endPos-Vector3.new(0,2.2,0),fOrange,8,48,0.65)
							spawnRingWave(endPos-Vector3.new(0,1.5,0),fGold,6,38,0.55)
							spawnCraterShards(endPos,fOrange,fRed,12,24,0.65)
							spawnFlashLight(endPos,fGold,7.5,48,0.65)
							if actorChar==player.Character then shakeCamera(1.05,0.55,11) end
						end)
					end
				end)
				Debris:AddItem(sunCore,0.95) Debris:AddItem(sunMantle,0.95) Debris:AddItem(sunCorona,0.95)
				return
			end

		elseif activeId=="GlacierIceCore" and (moveKey=="Z" or moveKey=="X" or moveKey=="C" or moveKey=="V" or moveKey=="F") then
			local iCyan=Color3.fromRGB(82,238,255)
			local iWhite=Color3.fromRGB(220,252,255)
			local iDeep=Color3.fromRGB(28,112,232)
			if moveKey=="Z" then
                -- ICE SHARDS: 3 Diverging Lanes of 18 Erupting 3D Glacier Ice Spikes
				for lane=-1,1 do
					local laneCF=baseCF*CFrame.Angles(0,lane*0.22,0)
					for step=1,6 do
						task.delay((step-1)*0.04,function()
							local spCF=laneCF*CFrame.new(0,-2.0,-step*4.0)*CFrame.Angles(math.rad(-24),0,lane*0.15)
							local shard=vfxPart("IceShard_"..lane.."_"..step,Enum.PartType.Block,Vector3.new(1.1,1.2,1.1),spCF,step%2==0 and iCyan or iWhite,0.08,Enum.Material.Ice)
							Tween:Create(shard,TweenInfo.new(0.38,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
								Size=Vector3.new(1.4,6.2+step*0.4,1.4),
								CFrame=spCF*CFrame.new(0,2.6,0),
								Transparency=1,
							}):Play()
							Debris:AddItem(shard,0.44)
						end)
					end
				end
				spawnFlashLight(startPos,iCyan,4.5,24,0.4)
				return
			elseif moveKey=="X" then
                -- GLACIAL SURGE: Colossal 3D Iceberg Monolith + 8 Perimeter Frost Crystal Spires
				local center=endPos
				local floorY=center.Y-2.3
				local monolith=vfxPart("GlacialMonolith",Enum.PartType.Block,Vector3.new(6,2,6),CFrame.new(center.X,floorY,center.Z)*CFrame.Angles(0.15,0.4,0.12),iCyan,0.08,Enum.Material.Ice)
				Tween:Create(monolith,TweenInfo.new(0.48,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
					Size=Vector3.new(11,16,11),
					CFrame=CFrame.new(center.X,floorY+6.5,center.Z)*CFrame.Angles(0.18,0.8,0.15),
					Transparency=1,
				}):Play()
				Debris:AddItem(monolith,0.55)
				for i=1,8 do
					local ang=(i-1)*(math.pi*0.25)
					local p=Vector3.new(center.X+math.cos(ang)*8.5,floorY,center.Z+math.sin(ang)*8.5)
					local sp=vfxPart("GlacialSpire_"..i,Enum.PartType.Block,Vector3.new(1.6,1.5,1.6),CFrame.new(p)*CFrame.Angles(math.cos(ang)*0.3,ang,math.sin(ang)*0.3),i%2==0 and iWhite or iDeep,0.08)
					Tween:Create(sp,TweenInfo.new(0.45,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=Vector3.new(2.0,10.5,2.0),CFrame=CFrame.new(p+Vector3.new(0,4.5,0))*CFrame.Angles(math.cos(ang)*0.35,ang,math.sin(ang)*0.35),Transparency=1}):Play()
					Debris:AddItem(sp,0.50)
				end
				spawnRingWave(Vector3.new(center.X,floorY,center.Z),iCyan,4,28,0.5)
				return
			elseif moveKey=="C" then
                -- ICE BIRD (CRYO PHOENIX): Sculpted 3D Cryo Phoenix with flapping wings soaring 30m forward!
				local pFolder=Instance.new("Folder") pFolder.Name="CryoPhoenix3D" pFolder.Parent=tempFX
				local pDur=0.55 Debris:AddItem(pFolder,pDur+0.1)
				local body=vfxPart("PhoenixBody",Enum.PartType.Block,Vector3.new(2.2,1.6,5.2),baseCF,iCyan,0.04)
				local head=vfxPart("PhoenixHead",Enum.PartType.Ball,Vector3.new(1.8,1.8,2.4),baseCF,iWhite,0.02)
				local wingL=vfxPart("PhoenixWingL",Enum.PartType.Block,Vector3.new(7.5,0.28,3.4),baseCF,iCyan,0.08)
				local wingR=vfxPart("PhoenixWingR",Enum.PartType.Block,Vector3.new(7.5,0.28,3.4),baseCF,iCyan,0.08)
				body.Parent=pFolder head.Parent=pFolder wingL.Parent=pFolder wingR.Parent=pFolder
				local t0=os.clock()
				local connP
				connP=Run.RenderStepped:Connect(function()
					local el=os.clock()-t0
					if el>=pDur or not pFolder.Parent then
						if connP then connP:Disconnect() connP=nil end
						return
					end
					local frac=el/pDur
					local curCF=baseCF*CFrame.new(0,0.8,-frac*30)
					local flap=math.sin(el*32)*0.48
					body.CFrame=curCF
					head.CFrame=curCF*CFrame.new(0,0.5,-2.6)
					wingL.CFrame=curCF*CFrame.new(-4.0,0.3,0)*CFrame.Angles(0,math.rad(16),flap)
					wingR.CFrame=curCF*CFrame.new(4.0,0.3,0)*CFrame.Angles(0,math.rad(-16),-flap)
				end)
				task.delay(pDur-0.04,function()
					spawnRingWave(endPos-Vector3.new(0,2,0),iCyan,5,30,0.48)
					spawnCraterShards(endPos,iCyan,iWhite,10,16,0.48)
					spawnFlashLight(endPos,iCyan,6.0,32,0.48)
				end)
				return
			elseif moveKey=="V" then
                -- ABSOLUTE ZERO: 34m Permafrost Ice Sheet Floor + 12 Hexagonal Ice Pillars + Blizzard Dome
				local center=startPos
				local floorY=center.Y-2.35
				local sheet=vfxPart("AbsoluteZeroSheet",Enum.PartType.Cylinder,Vector3.new(0.35,6,6),CFrame.new(center.X,floorY,center.Z)*CFrame.Angles(0,0,math.pi*0.5),iCyan,0.12,Enum.Material.Ice)
				local dome=vfxPart("AbsoluteZeroDome",Enum.PartType.Ball,Vector3.new(6,6,6),CFrame.new(center),iWhite,0.22)
				Tween:Create(sheet,TweenInfo.new(0.55,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=Vector3.new(0.35,56,56),Transparency=1}):Play()
				Tween:Create(dome,TweenInfo.new(0.68,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(54,54,54),Transparency=1}):Play()
				Debris:AddItem(sheet,0.65) Debris:AddItem(dome,0.72)
				for i=1,12 do
					local ang=(i-1)*(math.pi/6)
					local rad=(i%2==0) and 14 or 22
					local p=Vector3.new(center.X+math.cos(ang)*rad,floorY,center.Z+math.sin(ang)*rad)
					local pil=vfxPart("PermafrostPillar_"..i,Enum.PartType.Block,Vector3.new(2.4,2.0,2.4),CFrame.new(p)*CFrame.Angles(math.cos(ang)*0.22,ang,math.sin(ang)*0.22),i%2==0 and iCyan or iWhite,0.06,Enum.Material.Ice)
					Tween:Create(pil,TweenInfo.new(0.62,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=Vector3.new(2.8,15.5,2.8),CFrame=CFrame.new(p+Vector3.new(0,7,0))*CFrame.Angles(math.cos(ang)*0.28,ang,math.sin(ang)*0.28),Transparency=1}):Play()
					Debris:AddItem(pil,0.68)
				end
				if actorChar==player.Character then shakeCamera(0.9,0.52,10) end
				return
			end

		elseif activeId=="CelestialLightCore" and (moveKey=="Z" or moveKey=="X" or moveKey=="C" or moveKey=="V" or moveKey=="F") then
			local lGold=Color3.fromRGB(255,238,108)
			local lWhite=Color3.fromRGB(255,255,220)
			local lAmber=Color3.fromRGB(255,182,42)
			if moveKey=="Z" then
                -- LIGHT RAY: 38m Blinding Golden Photon Laser + 8 Starburst Rings
				local laser=vfxPart("LightRayBeam",Enum.PartType.Cylinder,Vector3.new(38,2.2,2.2),baseCF*CFrame.new(0,0.6,-19)*CFrame.Angles(0,math.pi*0.5,0),lWhite,0.02)
				local aura=vfxPart("LightRayAura",Enum.PartType.Cylinder,Vector3.new(38,4.6,4.6),laser.CFrame,lGold,0.16)
				Tween:Create(laser,TweenInfo.new(0.38,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(38,0.2,0.2),Transparency=1}):Play()
				Tween:Create(aura,TweenInfo.new(0.42,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(38,8.5,8.5),Transparency=1}):Play()
				Debris:AddItem(laser,0.42) Debris:AddItem(aura,0.45)
				spawnRingWave(endPos-Vector3.new(0,2,0),lGold,4,26,0.42)
				spawnFlashLight(endPos,lGold,6.5,34,0.45)
				return
			elseif moveKey=="X" then
                -- BARRAGE OF LIGHT: 14 Golden Light Spears raining diagonally forward
				for i=1,14 do
					task.delay((i-1)*0.032,function()
						local ox=((i%5)-2)*2.6
						local oy=4.5+(i%3)*1.8
						local spStart=(baseCF*CFrame.new(ox,oy,2.0)).Position
						local spEnd=(baseCF*CFrame.new(ox*1.3,-1.8,-14-(i%4)*3.5)).Position
						local spear=vfxPart("LightSpear_"..i,Enum.PartType.Block,Vector3.new(0.38,0.38,6.8),safeLook(spStart,spEnd),i%2==0 and lGold or lWhite,0.04)
						Tween:Create(spear,TweenInfo.new(0.22,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{CFrame=safeLook(spEnd,spEnd+(spEnd-spStart)),Transparency=1}):Play()
						Debris:AddItem(spear,0.26)
						if i%3==0 then spawnRingWave(spEnd,lGold,2,12,0.26) end
					end)
				end
				return
			elseif moveKey=="C" then
                -- REFLECTION KICK (YATA NO KAGAMI): 5 Zig-Zag Golden Light Mirrors + Skybeam Kick
				local pts={
					startPos+Vector3.new(0,2,0),
					(baseCF*CFrame.new(-6,7,-5)).Position,
					(baseCF*CFrame.new(6,11,-10)).Position,
					(baseCF*CFrame.new(-4,14,-15)).Position,
					endPos+Vector3.new(0,12,0),
					endPos,
				}
				for i=1,#pts-1 do
					local p1,p2=pts[i],pts[i+1]
					local segLen=(p2-p1).Magnitude
					local mirror=vfxPart("YataMirror_"..i,Enum.PartType.Cylinder,Vector3.new(0.25,4.8,4.8),safeLook(p1,p2)*CFrame.Angles(0,math.pi*0.5,0),lGold,0.10)
					local beam=vfxPart("YataBeam_"..i,Enum.PartType.Block,Vector3.new(0.55,0.55,segLen),safeLook((p1+p2)*0.5,p2),lWhite,0.02)
					Tween:Create(mirror,TweenInfo.new(0.45),{Size=Vector3.new(0.1,8,8),Transparency=1}):Play()
					Tween:Create(beam,TweenInfo.new(0.42),{Size=Vector3.new(0.1,0.1,segLen),Transparency=1}):Play()
					Debris:AddItem(mirror,0.48) Debris:AddItem(beam,0.45)
				end
				spawnRingWave(endPos-Vector3.new(0,2,0),lGold,5,28,0.48)
				return
			elseif moveKey=="V" then
                -- SKYBEAM BARRAGE (WRATH OF AUREON): 12 Heaven-sent Golden Judgment Pillars
				local skyRing=vfxPart("AureonSkyHalo",Enum.PartType.Cylinder,Vector3.new(0.4,36,36),CFrame.new(startPos+Vector3.new(0,28,0))*CFrame.Angles(0,0,math.pi*0.5),lGold,0.12)
				Tween:Create(skyRing,TweenInfo.new(0.85),{Size=Vector3.new(0.2,52,52),Transparency=1}):Play()
				Debris:AddItem(skyRing,0.9)
				for i=1,12 do
					task.delay((i-1)*0.05,function()
						local ang=(i-1)*(math.pi/6)
						local rad=(i%3)*6.5+4.0
						local p=startPos+Vector3.new(math.cos(ang)*rad,0,math.sin(ang)*rad)
						local beam=vfxPart("HeavenSkybeam_"..i,Enum.PartType.Cylinder,Vector3.new(36,3.6,3.6),CFrame.new(p+Vector3.new(0,16,0))*CFrame.Angles(0,0,math.pi*0.5),i%2==0 and lGold or lWhite,0.06)
						Tween:Create(beam,TweenInfo.new(0.42,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(38,9.5,9.5),Transparency=1}):Play()
						Debris:AddItem(beam,0.46)
						spawnRingWave(p-Vector3.new(0,2.2,0),lGold,3,18,0.38)
					end)
				end
				if actorChar==player.Character then shakeCamera(0.95,0.52,10) end
				return
			end

		elseif activeId=="StarforgedMagmaCore" and (moveKey=="Z" or moveKey=="X" or moveKey=="C" or moveKey=="V" or moveKey=="F") then
			local mRed=Color3.fromRGB(235,36,18)
			local mOrange=Color3.fromRGB(255,138,24)
			local mRock=Color3.fromRGB(42,18,18)
			local function spawnLavaPool(p,rad,dur)
				local pool=vfxPart("MagmaLavaPool",Enum.PartType.Cylinder,Vector3.new(0.35,2,2),CFrame.new(p.X,p.Y-2.25,p.Z)*CFrame.Angles(0,0,math.pi*0.5),mRed,0.08,Enum.Material.Neon)
				Tween:Create(pool,TweenInfo.new(dur or 0.85,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(0.25,rad,rad),Transparency=1}):Play()
				Debris:AddItem(pool,(dur or 0.85)+0.05)
			end
			if moveKey=="Z" then
                -- MAGMA CLAP: Twin Colossal 3D Molten Hands clapping together + Lava Pool
				for _,side in ipairs({-1,1}) do
					local sCF=baseCF*CFrame.new(side*8.5,1.5,-8)*CFrame.Angles(0,math.rad(-side*35),0)
					local eCF=baseCF*CFrame.new(side*1.2,1.5,-10)
					local hand=vfxPart("MagmaClapHand_"..side,Enum.PartType.Block,Vector3.new(3.2,5.5,4.8),sCF,mRed,0.04)
					local crust=vfxPart("MagmaClapCrust_"..side,Enum.PartType.Block,Vector3.new(3.6,4.2,3.6),sCF,mRock,0.12,Enum.Material.Slate)
					Tween:Create(hand,TweenInfo.new(0.28,Enum.EasingStyle.Back,Enum.EasingDirection.In),{CFrame=eCF,Transparency=1}):Play()
					Tween:Create(crust,TweenInfo.new(0.28,Enum.EasingStyle.Back,Enum.EasingDirection.In),{CFrame=eCF,Transparency=1}):Play()
					Debris:AddItem(hand,0.34) Debris:AddItem(crust,0.34)
				end
				spawnLavaPool((baseCF*CFrame.new(0,0,-10)).Position,22,0.85)
				if actorChar==player.Character then shakeCamera(0.6,0.38,7) end
				return
			elseif moveKey=="X" or moveKey=="C" then
                -- HELLHOUND FANG / MAGMA FIST: Giant 3D Molten Hound Jaw / Fist + Lava Pools
				local fist=vfxPart("MagmaColossalFist",Enum.PartType.Block,Vector3.new(5.2,5.2,7.2),baseCF*CFrame.new(0,1.2,-3.5),mRed,0.04)
				local rock=vfxPart("MagmaFistCrust",Enum.PartType.Block,Vector3.new(5.8,3.6,5.2),fist.CFrame,mRock,0.08,Enum.Material.Slate)
				Tween:Create(fist,TweenInfo.new(0.38,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{CFrame=CFrame.new(endPos+Vector3.new(0,1,0))*baseCF.Rotation,Size=Vector3.new(8.5,8.5,10.5),Transparency=1}):Play()
				Tween:Create(rock,TweenInfo.new(0.38,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{CFrame=CFrame.new(endPos+Vector3.new(0,1,0))*baseCF.Rotation,Transparency=1}):Play()
				Debris:AddItem(fist,0.42) Debris:AddItem(rock,0.42)
				spawnLavaPool(endPos,26,0.95)
				spawnCraterShards(endPos,mRed,mOrange,10,16,0.55)
				return
			elseif moveKey=="V" then
                -- METEOR VOLCANO: 10 Molten Magma Fists erupting & raining down into a Sea of Lava
				spawnLavaPool(startPos,44,1.1)
				for i=1,10 do
					task.delay((i-1)*0.055,function()
						local ang=(i-1)*(2*math.pi/10)
						local rad=(i%3)*6.5+4.5
						local targetP=startPos+Vector3.new(math.cos(ang)*rad,0,math.sin(ang)*rad)
						local skyP=targetP+Vector3.new(0,26,0)
						local mFist=vfxPart("VolcanoMeteorFist_"..i,Enum.PartType.Ball,Vector3.new(4.6,4.6,4.6),CFrame.new(skyP),i%2==0 and mRed or mOrange,0.04)
						Tween:Create(mFist,TweenInfo.new(0.26,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=targetP,Size=Vector3.new(8.5,8.5,8.5),Transparency=1}):Play()
						Debris:AddItem(mFist,0.32)
						task.delay(0.24,function() spawnLavaPool(targetP,16,0.75) end)
					end)
				end
				if actorChar==player.Character then shakeCamera(1.0,0.55,11) end
				return
			end

		elseif activeId=="ThunderRumbleCore" and (moveKey=="Z" or moveKey=="X" or moveKey=="C" or moveKey=="V" or moveKey=="F") then
			local tBlue=Color3.fromRGB(58,192,255)
			local tViolet=Color3.fromRGB(178,88,255)
			local tBlack=Color3.fromRGB(18,16,38)
			if moveKey=="Z" or moveKey=="C" then
                -- RUMBLE DRAGON / HYPERION BEAM: 32m High-Voltage Rail Beam + 8 Zig-Zag Lightning Bolts
				local rail=vfxPart("RumbleRailBeam",Enum.PartType.Cylinder,Vector3.new(32,3.2,3.2),baseCF*CFrame.new(0,0.8,-16)*CFrame.Angles(0,math.pi*0.5,0),tBlue,0.04)
				Tween:Create(rail,TweenInfo.new(0.45,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(34,7.5,7.5),Transparency=1}):Play()
				Debris:AddItem(rail,0.48)
				for i=1,8 do
					local zig=vfxPart("RumbleZig_"..i,Enum.PartType.Block,Vector3.new(0.55,0.55,5.5),baseCF*CFrame.new((i%2==0 and 1.8 or -1.8),0.8,-i*3.8)*CFrame.Angles(0.2,(i%2==0 and 0.42 or -0.42),0),i%2==0 and tBlue or tViolet,0.02)
					Tween:Create(zig,TweenInfo.new(0.42),{Transparency=1}):Play()
					Debris:AddItem(zig,0.45)
				end
				spawnRingWave(endPos-Vector3.new(0,2,0),tBlue,4,26,0.45)
				return
			elseif moveKey=="X" then
                -- SKY THUNDER: Dark Thundercloud + Colossal 6m Sky Lightning Pillar
				local cloud=vfxPart("ThunderCloud",Enum.PartType.Cylinder,Vector3.new(1.8,22,22),CFrame.new(endPos+Vector3.new(0,26,0))*CFrame.Angles(0,0,math.pi*0.5),tBlack,0.12)
				local bolt=vfxPart("SkyThunderPillar",Enum.PartType.Cylinder,Vector3.new(32,6.5,6.5),CFrame.new(endPos+Vector3.new(0,14,0))*CFrame.Angles(0,0,math.pi*0.5),tBlue,0.04)
				Tween:Create(cloud,TweenInfo.new(0.65),{Transparency=1}):Play()
				Tween:Create(bolt,TweenInfo.new(0.52,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(34,15,15),Transparency=1}):Play()
				Debris:AddItem(cloud,0.7) Debris:AddItem(bolt,0.56)
				spawnRingWave(endPos-Vector3.new(0,2.2,0),tBlue,5,32,0.52)
				spawnCraterShards(endPos,tBlue,tViolet,10,18,0.52)
				if actorChar==player.Character then shakeCamera(0.75,0.45,8) end
				return
			elseif moveKey=="V" then
                -- THUNDERBALL DESTRUCTION (RAIGO SPHERE): Colossal 26m Black-Blue Storm Sphere descending from the sky!
				local skyPos=endPos+Vector3.new(0,24,0)
				local raigoCore=vfxPart("RaigoCore",Enum.PartType.Ball,Vector3.new(18,18,18),CFrame.new(skyPos),tBlack,0.04)
				local raigoShell=vfxPart("RaigoShell",Enum.PartType.Ball,Vector3.new(24,24,24),CFrame.new(skyPos),tBlue,0.18)
				Tween:Create(raigoCore,TweenInfo.new(0.42,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=endPos,Size=Vector3.new(44,44,44),Transparency=1}):Play()
				Tween:Create(raigoShell,TweenInfo.new(0.46,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=endPos,Size=Vector3.new(58,58,58),Transparency=1}):Play()
				Debris:AddItem(raigoCore,0.52) Debris:AddItem(raigoShell,0.55)
				task.delay(0.36,function()
					spawnRingWave(endPos-Vector3.new(0,2.2,0),tBlue,8,54,0.65)
					spawnRingWave(endPos-Vector3.new(0,1.5,0),tViolet,6,42,0.55)
					spawnCraterShards(endPos,tBlue,tViolet,12,26,0.65)
					spawnFlashLight(endPos,tBlue,8.0,52,0.65)
					if actorChar==player.Character then shakeCamera(1.15,0.58,12) end
				end)
				return
			end

		elseif activeId=="AstralGravityCore" and (moveKey=="Z" or moveKey=="X" or moveKey=="C" or moveKey=="V" or moveKey=="F") then
			local gPurple=Color3.fromRGB(158,52,255)
			local gMagenta=Color3.fromRGB(236,112,255)
			local gRock=Color3.fromRGB(52,28,74)
			if moveKey=="X" then
                -- GRAVITY CRUSH: 10x Heavy Gravity Descending Rings crushing enemies into the floor!
				local center=endPos
				local floorY=center.Y-2.3
				for i=1,6 do
					task.delay((i-1)*0.06,function()
						local ring=vfxPart("GravityCrushRing_"..i,Enum.PartType.Cylinder,Vector3.new(0.35,28,28),CFrame.new(center.X,floorY+14,center.Z)*CFrame.Angles(0,0,math.pi*0.5),i%2==0 and gPurple or gMagenta,0.12)
						Tween:Create(ring,TweenInfo.new(0.28,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{CFrame=CFrame.new(center.X,floorY+0.2,center.Z)*CFrame.Angles(0,0,math.pi*0.5),Size=Vector3.new(0.2,34,34),Transparency=1}):Play()
						Debris:AddItem(ring,0.32)
					end)
				end
				spawnCraterShards(center,gPurple,gRock,10,20,0.58)
				return
			elseif moveKey=="C" or moveKey=="V" then
                -- METEOR STRIKE / ASTRAL METEOR SHOWER: Cosmic Nebula Rift + Giant Flaming Asteroids!
				local count=(moveKey=="V") and 9 or 2
				local rift=vfxPart("CosmicMeteorRift",Enum.PartType.Cylinder,Vector3.new(0.5,34,34),CFrame.new(endPos+Vector3.new(0,28,0))*CFrame.Angles(0,0,math.pi*0.5),gPurple,0.12)
				Tween:Create(rift,TweenInfo.new(0.85),{Size=Vector3.new(0.2,48,48),Transparency=1}):Play()
				Debris:AddItem(rift,0.9)
				for m=1,count do
					task.delay((m-1)*0.07,function()
						local ang=(m-1)*(2*math.pi/count)
						local rad=(count>2) and ((m%3)*5.5+2.5) or ((m-1.5)*5.0)
						local mEnd=endPos+Vector3.new(math.cos(ang)*rad,-1.5,math.sin(ang)*rad)
						local mStart=mEnd+Vector3.new(-8,28,-8)
						local rock=vfxPart("AstralMeteorRock_"..m,Enum.PartType.Ball,Vector3.new(5.5,5.5,5.5),CFrame.new(mStart),gRock,0.02,Enum.Material.Slate)
						local aura=vfxPart("AstralMeteorAura_"..m,Enum.PartType.Ball,Vector3.new(7.5,7.5,7.5),CFrame.new(mStart),gPurple,0.18)
						Tween:Create(rock,TweenInfo.new(0.28,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=mEnd,Size=Vector3.new(9.5,9.5,9.5),Transparency=1}):Play()
						Tween:Create(aura,TweenInfo.new(0.28,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=mEnd,Size=Vector3.new(14,14,14),Transparency=1}):Play()
						Debris:AddItem(rock,0.34) Debris:AddItem(aura,0.34)
						task.delay(0.26,function()
							spawnRingWave(mEnd,gPurple,4,24,0.42)
							spawnCraterShards(mEnd+Vector3.new(0,2,0),gPurple,gMagenta,6,14,0.42)
						end)
					end)
				end
				if actorChar==player.Character then shakeCamera(0.95,0.52,10) end
				return
			end

		elseif activeId=="DimensionalPortalCore" and (moveKey=="Z" or moveKey=="X" or moveKey=="C" or moveKey=="V" or moveKey=="F") then
			local pCyan=Color3.fromRGB(64,242,255)
			local pViolet=Color3.fromRGB(168,72,255)
			local pDark=Color3.fromRGB(16,24,58)
			local function spawnStargate(cf,rad,dur)
				local outer=vfxPart("StargateOuter",Enum.PartType.Cylinder,Vector3.new(0.35,rad,rad),cf*CFrame.Angles(0,math.pi*0.5,0),pCyan,0.08)
				local inner=vfxPart("StargateInner",Enum.PartType.Cylinder,Vector3.new(0.45,rad*0.78,rad*0.78),cf*CFrame.Angles(0,math.pi*0.5,0),pDark,0.04)
				Tween:Create(outer,TweenInfo.new(dur or 0.55,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(0.15,rad*1.45,rad*1.45),Transparency=1}):Play()
				Tween:Create(inner,TweenInfo.new(dur or 0.55,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(0.2,rad*1.15,rad*1.15),Transparency=1}):Play()
				Debris:AddItem(outer,(dur or 0.55)+0.05) Debris:AddItem(inner,(dur or 0.55)+0.05)
			end
			if moveKey=="Z" or moveKey=="C" or moveKey=="F" then
				spawnStargate(baseCF,10,0.55)
				spawnStargate(safeLook(endPos,endPos+lookDir),12,0.62)
				for i=1,6 do
					local slashCF=baseCF:Lerp(safeLook(endPos,endPos+lookDir),i/6)*CFrame.Angles(0,0,i*0.65)
					local rift=vfxPart("PortalRiftSlash_"..i,Enum.PartType.Block,Vector3.new(12,0.28,0.8),slashCF,i%2==0 and pCyan or pViolet,0.06)
					Tween:Create(rift,TweenInfo.new(0.42),{Size=Vector3.new(18,0.1,1.6),Transparency=1}):Play()
					Debris:AddItem(rift,0.45)
				end
				return
			elseif moveKey=="V" then
                -- DIMENSIONAL RIFT (4D POCKET UNIVERSE): Colossal 36m Tesseract Cube / Dome + 12 Spatial Reality Slashes!
				local cube=vfxPart("PocketUniverseCube",Enum.PartType.Block,Vector3.new(8,8,8),CFrame.new(startPos)*CFrame.Angles(0.4,0.4,0.4),pDark,0.16)
				local dome=vfxPart("PocketUniverseDome",Enum.PartType.Ball,Vector3.new(10,10,10),CFrame.new(startPos),pCyan,0.22)
				Tween:Create(cube,TweenInfo.new(0.75,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(42,42,42),CFrame=CFrame.new(startPos)*CFrame.Angles(1.2,1.5,0.8),Transparency=1}):Play()
				Tween:Create(dome,TweenInfo.new(0.78,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(54,54,54),Transparency=1}):Play()
				Debris:AddItem(cube,0.8) Debris:AddItem(dome,0.82)
				for i=1,12 do
					local rCF=CFrame.new(startPos)*CFrame.Angles(math.sin(i)*1.4,i*0.52,math.cos(i)*1.4)
					local cut=vfxPart("RealitySlash_"..i,Enum.PartType.Block,Vector3.new(34,0.32,0.9),rCF,i%2==0 and pCyan or pViolet,0.04)
					Tween:Create(cut,TweenInfo.new(0.62,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(48,0.1,1.8),Transparency=1}):Play()
					Debris:AddItem(cut,0.65)
				end
				if actorChar==player.Character then shakeCamera(1.0,0.52,11) end
				return
			end

		elseif (activeId=="SolarTitanCore" or (actorChar and actorChar:GetAttribute("FruitTransform")=="SolarTitan")) and (moveKey=="Z" or moveKey=="X" or moveKey=="C" or moveKey=="V" or moveKey=="F") then
			local bGold=Color3.fromRGB(255,212,64)
			local bLight=Color3.fromRGB(255,248,182)
			local bAmber=Color3.fromRGB(238,142,28)
			if moveKey=="C" then
                -- SOLAR PALM (NHƯ LAI THẦN CHƯỞNG): Colossal 3D Golden Buddha Palm + 5 Fingers crushing forward!
				local palmCF=baseCF*CFrame.new(0,3.2,-4)*CFrame.Angles(math.rad(-15),0,0)
				local targetCF=safeLook(endPos+Vector3.new(0,1.5,0),endPos+Vector3.new(0,1.5,0)+lookDir)
				local palm=vfxPart("BuddhaSolarPalm",Enum.PartType.Block,Vector3.new(8.5,8.5,2.2),palmCF,bGold,0.04)
				local halo=vfxPart("BuddhaPalmHalo",Enum.PartType.Cylinder,Vector3.new(0.35,14,14),palmCF*CFrame.Angles(0,math.pi*0.5,0),bLight,0.12)
				Tween:Create(palm,TweenInfo.new(0.42,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{CFrame=targetCF,Size=Vector3.new(13,13,2.8),Transparency=1}):Play()
				Tween:Create(halo,TweenInfo.new(0.42,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{CFrame=targetCF*CFrame.Angles(0,math.pi*0.5,0),Size=Vector3.new(0.2,24,24),Transparency=1}):Play()
				Debris:AddItem(palm,0.46) Debris:AddItem(halo,0.46)
				for f=1,5 do
					local fOff=(f-3)*2.0
					local finger=vfxPart("BuddhaPalmFinger_"..f,Enum.PartType.Block,Vector3.new(1.5,4.8,1.8),palmCF*CFrame.new(fOff,6.2,0),bGold,0.04)
					Tween:Create(finger,TweenInfo.new(0.42,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{CFrame=targetCF*CFrame.new(fOff*1.45,9.0,0),Size=Vector3.new(2.1,6.5,2.1),Transparency=1}):Play()
					Debris:AddItem(finger,0.46)
				end
				spawnRingWave(endPos-Vector3.new(0,2,0),bGold,6,36,0.52)
				spawnCraterShards(endPos,bGold,bAmber,10,20,0.52)
				if actorChar==player.Character then shakeCamera(0.8,0.48,9) end
				return
			elseif moveKey=="Z" or moveKey=="X" or moveKey=="V" then
                -- LOTUS ENLIGHTENMENT / TWILIGHT OF THE GODS: 12 Golden Judgment Pillars + Dharma Wheel
				local center=(moveKey=="X") and endPos or startPos
				local floorY=center.Y-2.3
				local dharma=vfxPart("BuddhaDharmaWheel",Enum.PartType.Cylinder,Vector3.new(0.35,10,10),CFrame.new(center.X,floorY+0.2,center.Z)*CFrame.Angles(0,0,math.pi*0.5),bGold,0.08)
				local dome=vfxPart("BuddhaGoldenDome",Enum.PartType.Ball,Vector3.new(8,8,8),CFrame.new(center),bLight,0.18)
				Tween:Create(dharma,TweenInfo.new(0.65,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=Vector3.new(0.2,46,46),Transparency=1}):Play()
				Tween:Create(dome,TweenInfo.new(0.65,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(48,48,48),Transparency=1}):Play()
				Debris:AddItem(dharma,0.7) Debris:AddItem(dome,0.7)
				local pCount=(moveKey=="V") and 12 or 8
				for i=1,pCount do
					local ang=(i-1)*(2*math.pi/pCount)
					local rad=(moveKey=="V") and ((i%2==0) and 14 or 24) or 12
					local p=Vector3.new(center.X+math.cos(ang)*rad,floorY+16,center.Z+math.sin(ang)*rad)
					local pil=vfxPart("BuddhaPillar_"..i,Enum.PartType.Cylinder,Vector3.new(36,4.2,4.2),CFrame.new(p)*CFrame.Angles(0,0,math.pi*0.5),i%2==0 and bGold or bLight,0.08)
					Tween:Create(pil,TweenInfo.new(0.58,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(40,9.5,9.5),Transparency=1}):Play()
					Debris:AddItem(pil,0.62)
				end
				spawnRingWave(Vector3.new(center.X,floorY,center.Z),bGold,6,44,0.62)
				if actorChar==player.Character then shakeCamera(0.95,0.52,10) end
				return
			end

		elseif activeId=="AetherflowCore" and (moveKey=="Z" or moveKey=="X" or moveKey=="C" or moveKey=="V" or moveKey=="F") then
			local dCream=Color3.fromRGB(255,244,218)
			local dHakiRed=Color3.fromRGB(255,36,88)
			local dObsidian=Color3.fromRGB(22,12,28)
			if moveKey=="Z" then
                -- MISSILE JAB: Colossal Haki-Clad Crystal-Dough Fist Rocket + Dough Swirl Rings!
				local fist=vfxPart("AetherMissileFist",Enum.PartType.Block,Vector3.new(4.8,4.8,6.8),baseCF*CFrame.new(0,1.0,-3.5),dObsidian,0.02)
				local haki=vfxPart("AetherFistHaki",Enum.PartType.Block,Vector3.new(5.4,5.4,7.2),fist.CFrame,dHakiRed,0.16)
				local dough=vfxPart("AetherFistDoughRing",Enum.PartType.Cylinder,Vector3.new(0.5,8.5,8.5),baseCF*CFrame.new(0,1.0,-2.0)*CFrame.Angles(0,math.pi*0.5,0),dCream,0.06)
				Tween:Create(fist,TweenInfo.new(0.36,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{CFrame=CFrame.new(endPos)*baseCF.Rotation,Size=Vector3.new(7.5,7.5,9.5),Transparency=1}):Play()
				Tween:Create(haki,TweenInfo.new(0.36,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{CFrame=CFrame.new(endPos)*baseCF.Rotation,Size=Vector3.new(9.5,9.5,11),Transparency=1}):Play()
				Tween:Create(dough,TweenInfo.new(0.42),{Size=Vector3.new(0.2,18,18),Transparency=1}):Play()
				Debris:AddItem(fist,0.4) Debris:AddItem(haki,0.4) Debris:AddItem(dough,0.45)
				spawnRingWave(endPos-Vector3.new(0,2,0),dHakiRed,4,28,0.45)
				return
			elseif moveKey=="C" or moveKey=="F" then
                -- CARVED AETHER / ROLLER DONUT: Giant 3D Spiked Crystal-Dough Wheel rolling along the path!
				local donut=vfxPart("RollerDonutWheel",Enum.PartType.Cylinder,Vector3.new(2.8,11,11),baseCF*CFrame.Angles(0,math.pi*0.5,0),dCream,0.04)
				local core=vfxPart("RollerDonutHaki",Enum.PartType.Cylinder,Vector3.new(3.2,6.5,6.5),donut.CFrame,dHakiRed,0.10)
				Tween:Create(donut,TweenInfo.new(0.45,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{CFrame=CFrame.new(endPos)*baseCF.Rotation*CFrame.Angles(0,math.pi*0.5,0),Size=Vector3.new(3.2,15,15),Transparency=1}):Play()
				Tween:Create(core,TweenInfo.new(0.45,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{CFrame=CFrame.new(endPos)*baseCF.Rotation*CFrame.Angles(0,math.pi*0.5,0),Transparency=1}):Play()
				Debris:AddItem(donut,0.5) Debris:AddItem(core,0.5)
				spawnRingWave(endPos-Vector3.new(0,2,0),dHakiRed,5,30,0.48)
				spawnCraterShards(endPos,dCream,dHakiRed,10,18,0.48)
				return
			elseif moveKey=="V" then
                -- RESTLESS AETHER BARRAGE (VẠN QUYỀN DIỆT THẾ): 12 Dough Portals firing 20 Haki-Clad Fists!
				for pIdx=1,12 do
					local ang=(pIdx-6.5)*0.24
					local pPos=(baseCF*CFrame.Angles(0,ang,0)*CFrame.new(0,4.5+(pIdx%3)*2.4,4.0)).Position
					local pCF=safeLook(pPos,endPos)
					local portalRing=vfxPart("DoughBarragePortal_"..pIdx,Enum.PartType.Cylinder,Vector3.new(0.35,4.8,4.8),pCF*CFrame.Angles(0,math.pi*0.5,0),dCream,0.06)
					Tween:Create(portalRing,TweenInfo.new(0.75),{Size=Vector3.new(0.15,7.5,7.5),Transparency=1}):Play()
					Debris:AddItem(portalRing,0.8)
					task.delay((pIdx-1)*0.035,function()
						local fist=vfxPart("DoughBarrageFist_"..pIdx,Enum.PartType.Block,Vector3.new(2.8,2.8,4.5),pCF,pIdx%2==0 and dObsidian or dHakiRed,0.02)
						Tween:Create(fist,TweenInfo.new(0.24,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{CFrame=safeLook(endPos,endPos+(endPos-pPos)),Size=Vector3.new(4.2,4.2,6.5),Transparency=1}):Play()
						Debris:AddItem(fist,0.28)
					end)
				end
				task.delay(0.32,function()
					spawnRingWave(endPos-Vector3.new(0,2.2,0),dHakiRed,6,42,0.58)
					spawnCraterShards(endPos,dHakiRed,dCream,12,22,0.58)
					if actorChar==player.Character then shakeCamera(1.0,0.55,11) end
				end)
				return
			end

		elseif activeId=="SandstoneCore" and (moveKey=="X" or moveKey=="V") then
			local sGold=Color3.fromRGB(238,192,88)
			local sSand=Color3.fromRGB(198,148,64)
			if moveKey=="X" then
                -- SAND COFFIN (PYRAMID TOMB): 4 Golden Pyramid Walls closing around endPos and imploding!
				for i=1,4 do
					local ang=(i-1)*(math.pi*0.5)
					local wStart=endPos+Vector3.new(math.cos(ang)*8,2,math.sin(ang)*8)
					local wall=vfxPart("SandCoffinWall_"..i,Enum.PartType.Block,Vector3.new(7.5,9.5,1.2),safeLook(wStart,endPos)*CFrame.Angles(math.rad(22),0,0),i%2==0 and sGold or sSand,0.08,Enum.Material.Sand)
					Tween:Create(wall,TweenInfo.new(0.32,Enum.EasingStyle.Back,Enum.EasingDirection.In),{CFrame=safeLook(endPos+Vector3.new(math.cos(ang)*1.8,2,math.sin(ang)*1.8),endPos)*CFrame.Angles(math.rad(32),0,0),Transparency=1}):Play()
					Debris:AddItem(wall,0.45)
				end
				task.delay(0.30,function()
					spawnRingWave(endPos-Vector3.new(0,2,0),sGold,4,28,0.45)
					spawnCraterShards(endPos,sGold,sSand,10,16,0.45)
				end)
				return
			end
		end

		if moveKey=="Z" then
            -- =========================================================================
            -- CHIÊU [Z]: ĐỘT KÍCH SƠ KHAI / PHONG ĐAO XUNG KÍCH
            -- Travelling 3D Twin Crescent Wave Blades + Spiraling Wind Tunnel + Ground Furrows
            -- =========================================================================
			spawnRingWave(startPos-Vector3.new(0,2.1,0),primary,3.5,14,.32)
			spawnFlashLight(startPos,primary,4.2,24,.45)

            -- 3D Travelling Twin Crescent Wave Assembly flying 24 studs forward along baseCF
			local waveCenter=vfxPart("SkillZ_WaveMain",Enum.PartType.Block,Vector3.new(6.8,0.42,2.6),baseCF*CFrame.new(0,0.4,-2.5)*CFrame.Angles(0,0,math.rad(16)),primary,0.08)
			local waveWingL=vfxPart("SkillZ_WaveWingL",Enum.PartType.Block,Vector3.new(3.6,0.34,3.2),baseCF*CFrame.new(-3.2,0.1,-1.8)*CFrame.Angles(0,math.rad(24),math.rad(16)),secondary,0.12)
			local waveWingR=vfxPart("SkillZ_WaveWingR",Enum.PartType.Block,Vector3.new(3.6,0.34,3.2),baseCF*CFrame.new(3.2,-0.1,-1.8)*CFrame.Angles(0,math.rad(-24),math.rad(16)),secondary,0.12)
			local crossBlade=vfxPart("SkillZ_CrossBlade",Enum.PartType.Block,Vector3.new(6.2,0.32,2.1),baseCF*CFrame.new(0,0.4,-3.0)*CFrame.Angles(0,0,math.rad(-22)),accent,0.14)
			local spearCore=vfxPart("SkillZ_SpearCore",Enum.PartType.Cylinder,Vector3.new(10,1.2,1.2),baseCF*CFrame.new(0,0.4,-4.5)*CFrame.Angles(0,math.pi*0.5,0),secondary,0.10)

			local travelDist=24
			local travelDur=0.44
			Tween:Create(waveCenter,TweenInfo.new(travelDur,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
				CFrame=baseCF*CFrame.new(0,0.4,-travelDist)*CFrame.Angles(0,0,math.rad(16)),
				Size=Vector3.new(14.5,0.22,4.2),
				Transparency=1,
			}):Play()
			Tween:Create(waveWingL,TweenInfo.new(travelDur,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
				CFrame=baseCF*CFrame.new(-6.4,0.2,-(travelDist-1.5))*CFrame.Angles(0,math.rad(30),math.rad(16)),
				Size=Vector3.new(6.5,0.18,4.6),
				Transparency=1,
			}):Play()
			Tween:Create(waveWingR,TweenInfo.new(travelDur,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
				CFrame=baseCF*CFrame.new(6.4,-0.2,-(travelDist-1.5))*CFrame.Angles(0,math.rad(-30),math.rad(16)),
				Size=Vector3.new(6.5,0.18,4.6),
				Transparency=1,
			}):Play()
			Tween:Create(crossBlade,TweenInfo.new(travelDur,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
				CFrame=baseCF*CFrame.new(0,0.4,-(travelDist+1.2))*CFrame.Angles(0,0,math.rad(-22)),
				Size=Vector3.new(13.0,0.18,3.6),
				Transparency=1,
			}):Play()
			Tween:Create(spearCore,TweenInfo.new(travelDur,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
				CFrame=baseCF*CFrame.new(0,0.4,-(travelDist*0.65))*CFrame.Angles(0,math.pi*0.5,0),
				Size=Vector3.new(travelDist,0.3,0.3),
				Transparency=1,
			}):Play()
			Debris:AddItem(waveCenter,travelDur+0.05)
			Debris:AddItem(waveWingL,travelDur+0.05)
			Debris:AddItem(waveWingR,travelDur+0.05)
			Debris:AddItem(crossBlade,travelDur+0.05)
			Debris:AddItem(spearCore,travelDur+0.05)

            -- 6 Sequential Sonic Tunnel Rings & Ground Slash Furrows along flight path
			for i=1,6 do
				task.delay((i-1)*0.045,function()
					local stepPos=(baseCF*CFrame.new(0,0.3,-i*3.8)).Position
					local sonicRing=vfxPart("SkillZ_SonicRing"..i,Enum.PartType.Cylinder,Vector3.new(0.28,3.2,3.2),baseCF*CFrame.new(0,0.3,-i*3.8)*CFrame.Angles(0,math.pi*0.5,0),i%2==0 and primary or secondary,0.16)
					Tween:Create(sonicRing,TweenInfo.new(0.32,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
						Size=Vector3.new(0.10,9.5+i*0.8,9.5+i*0.8),
						Transparency=1,
					}):Play()
					Debris:AddItem(sonicRing,0.35)

					for side=-1,1,2 do
						local furrow=vfxPart("SkillZ_Furrow"..i.."_"..side,Enum.PartType.Block,Vector3.new(0.55,1.2,1.6),baseCF*CFrame.new(side*1.8,-1.8,-i*3.8)*CFrame.Angles(0.35,side*0.4,side*0.3),i%2==0 and primary or accent,0.14)
						Tween:Create(furrow,TweenInfo.new(0.36,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
							CFrame=baseCF*CFrame.new(side*4.2,-0.8,-i*3.8-1.2)*CFrame.Angles(0.75,side*0.6,side*0.5),
							Size=Vector3.new(0.2,0.4,0.6),
							Transparency=1,
						}):Play()
						Debris:AddItem(furrow,0.40)
					end
					if i==6 then
						spawnRingWave(stepPos-Vector3.new(0,2.2,0),secondary,3,16,0.35)
						spawnFlashLight(stepPos,secondary,3.8,20,0.35)
					end
				end)
			end
			if actorChar==player.Character or not actorChar then
				shakeCamera(0.38,0.26,4)
			end

		elseif moveKey=="X" then
            -- =========================================================================
            -- CHIÊU [X]: CHẤN ĐỊA XUNG THIÊN / LỐC XOÁY KHÔNG TRUNG
            -- Live Animated 3D Multi-Ring Rising Cyclone Vortex + 6 Orbiting Wind Blades + Spikes
            -- =========================================================================
			local center=endPos
			local floorY=center.Y-2.3
			spawnRingWave(Vector3.new(center.X,floorY,center.Z),primary,4,26,0.52)
			spawnRingWave(Vector3.new(center.X,floorY+0.4,center.Z),secondary,3,20,0.42)
			spawnCraterShards(center,primary,accent,8,15,0.55)
			spawnFlashLight(center+Vector3.new(0,4,0),primary,5.0,28,0.65)

			local vortexFolder=Instance.new("Folder")
			vortexFolder.Name="SkillX_CycloneVortex"
			vortexFolder.Parent=tempFX
			local vDur=0.72
			Debris:AddItem(vortexFolder,vDur+0.1)

			local coreCol=vfxPart("SkillX_CoreColumn",Enum.PartType.Cylinder,Vector3.new(22,3.2,3.2),CFrame.new(center+Vector3.new(0,8,0))*CFrame.Angles(0,0,math.pi*0.5),secondary,0.18)
			coreCol.Parent=vortexFolder
			Tween:Create(coreCol,TweenInfo.new(vDur,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
				Size=Vector3.new(28,9.5,9.5),
				Transparency=1,
			}):Play()

			local ringNodes={}
			for i=1,8 do
				local rPart=vfxPart("SkillX_VortexRing"..i,Enum.PartType.Cylinder,Vector3.new(0.32,3.0+i*1.4,3.0+i*1.4),CFrame.new(center.X,floorY+i*2.1,center.Z)*CFrame.Angles(0,0,math.pi*0.5),i%2==0 and primary or secondary,0.14)
				rPart.Parent=vortexFolder
				table.insert(ringNodes,{Part=rPart,Index=i})
			end

			local bladeNodes={}
			for b=1,6 do
				local bPart=vfxPart("SkillX_OrbitBlade"..b,Enum.PartType.Block,Vector3.new(0.35,1.2,4.8),CFrame.new(center),b%2==0 and primary or accent,0.08)
				bPart.Parent=vortexFolder
				table.insert(bladeNodes,{Part=bPart,Index=b})
			end

			local t0=os.clock()
			local connX
			connX=Run.RenderStepped:Connect(function()
				local elapsed=os.clock()-t0
				if elapsed>=vDur or not vortexFolder.Parent then
					if connX then connX:Disconnect() connX=nil end
					return
				end
				local pRatio=elapsed/vDur
				local fade=math.clamp(pRatio*1.15,0.12,1)
				for _,rn in ipairs(ringNodes) do
					if rn.Part and rn.Part.Parent then
						local idx=rn.Index
						local wobAng=elapsed*14+idx*0.85
						local rDiam=(3.2+idx*1.55)*(1+pRatio*0.55)
						local yH=floorY+idx*2.2+pRatio*4.5
						local ox=math.cos(wobAng)*(0.45+idx*0.08)
						local oz=math.sin(wobAng)*(0.45+idx*0.08)
						rn.Part.Size=Vector3.new(0.28*(1-pRatio*0.6),rDiam,rDiam)
						rn.Part.CFrame=CFrame.new(center.X+ox,yH,center.Z+oz)*CFrame.Angles(math.sin(wobAng)*0.14,wobAng,math.pi*0.5)
						rn.Part.Transparency=fade
					end
				end
				for _,bn in ipairs(bladeNodes) do
					if bn.Part and bn.Part.Parent then
						local idx=bn.Index
						local ang=elapsed*15+(idx-1)*(math.pi/3)
						local rad=(3.0+idx*0.65)*(1+pRatio*0.45)
						local yH=floorY+1.5+((idx-1)*2.2+elapsed*18)%16
						local bPos=Vector3.new(center.X+math.cos(ang)*rad,yH,center.Z+math.sin(ang)*rad)
						local tPos=bPos+Vector3.new(-math.sin(ang),0.45,math.cos(ang))
						bn.Part.CFrame=safeLook(bPos,tPos)*CFrame.Angles(0,0,math.rad(28))
						bn.Part.Transparency=fade*0.92
					end
				end
			end)

			if actorChar==player.Character or not actorChar then
				shakeCamera(0.52,0.36,6)
			end

		elseif moveKey=="C" then
            -- =========================================================================
            -- CHIÊU [C]: LIÊN HOÀN BÃO KIẾM / BÁCH QUYỀN NGHIỀN NÁT
            -- 6 Sequential Multi-Angle 3D Cross Slashes + 8 Converging Phantom Spirit Swords + Dome Finisher
            -- =========================================================================
			local targetCenter=(baseCF*CFrame.new(0,0.5,-6.5)).Position
			local slashAngles={
				CFrame.Angles(0,0,math.rad(32)),
				CFrame.Angles(0,0,math.rad(-34)),
				CFrame.Angles(math.rad(12),0,math.rad(4)),
				CFrame.Angles(0,0,math.rad(64)),
				CFrame.Angles(0,0,math.rad(-64)),
				CFrame.Angles(0,0,math.rad(90)),
			}

            -- Stage 1: 6 Rapid Cross-Cleave 3D Slashes
			for sIdx=1,6 do
				task.delay((sIdx-1)*0.07,function()
					local sRot=slashAngles[sIdx]
					local sCol=(sIdx%3==1 and primary) or (sIdx%3==2 and secondary) or accent
					local slashArc=vfxPart("SkillC_SlashArc"..sIdx,Enum.PartType.Block,Vector3.new(11.5,0.35,3.2),CFrame.new(targetCenter)*baseCF.Rotation*sRot,sCol,0.06)
					local slashInner=vfxPart("SkillC_SlashInner"..sIdx,Enum.PartType.Block,Vector3.new(9.5,0.22,1.8),CFrame.new(targetCenter)*baseCF.Rotation*sRot*CFrame.new(0,0,-0.8),secondary,0.04)
					Tween:Create(slashArc,TweenInfo.new(0.26,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
						Size=Vector3.new(18.5,0.14,5.4),
						CFrame=CFrame.new(targetCenter)*baseCF.Rotation*sRot*CFrame.new(0,0,-2.8),
						Transparency=1,
					}):Play()
					Tween:Create(slashInner,TweenInfo.new(0.24,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
						Size=Vector3.new(15.0,0.10,3.2),
						Transparency=1,
					}):Play()
					Debris:AddItem(slashArc,0.28)
					Debris:AddItem(slashInner,0.26)
					if sIdx%2==1 then
						spawnRingWave(targetCenter-Vector3.new(0,2.2,0),sCol,3,18,0.28)
					end
				end)
			end

            -- Stage 2: 8 Phantom Spirit Blades materializing in a high halo and lancing into targetCenter
			for pIdx=1,8 do
				local ang=(pIdx-1)*(math.pi*0.25)
				local spawnP=targetCenter+Vector3.new(math.cos(ang)*11.5,5.2+(pIdx%2)*1.6,math.sin(ang)*11.5)
				local aimCF=safeLook(spawnP,targetCenter)
				local blade=vfxPart("SkillC_PhantomBlade"..pIdx,Enum.PartType.Block,Vector3.new(0.42,0.85,5.6),aimCF,pIdx%2==0 and primary or secondary,0.08)
				local guard=vfxPart("SkillC_PhantomGuard"..pIdx,Enum.PartType.Block,Vector3.new(1.65,0.32,0.45),aimCF*CFrame.new(0,0,1.8),accent,0.08)
				task.delay(0.18+(pIdx-1)*0.03,function()
					if blade.Parent and guard.Parent then
						local pierceCF=safeLook(targetCenter+Vector3.new(math.cos(ang)*1.2,0.4,math.sin(ang)*1.2),targetCenter-Vector3.new(math.cos(ang),0.5,math.sin(ang)))
						Tween:Create(blade,TweenInfo.new(0.24,Enum.EasingStyle.Back,Enum.EasingDirection.In),{
							CFrame=pierceCF,
							Size=Vector3.new(0.22,0.45,7.2),
							Transparency=1,
						}):Play()
						Tween:Create(guard,TweenInfo.new(0.24,Enum.EasingStyle.Back,Enum.EasingDirection.In),{
							CFrame=pierceCF*CFrame.new(0,0,2.2),
							Transparency=1,
						}):Play()
					end
				end)
				Debris:AddItem(blade,0.68)
				Debris:AddItem(guard,0.68)
			end

            -- Stage 3: Finisher Gyroscopic Vortex Cage Detonation at t = 0.46s
			task.delay(0.46,function()
				local dome=vfxPart("SkillC_FinisherDome",Enum.PartType.Ball,Vector3.new(4,4,4),CFrame.new(targetCenter),primary,0.14)
				Tween:Create(dome,TweenInfo.new(0.42,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
					Size=Vector3.new(24,24,24),
					Transparency=1,
				}):Play()
				Debris:AddItem(dome,0.45)
				for g=1,3 do
					local gyro=vfxPart("SkillC_GyroRing"..g,Enum.PartType.Cylinder,Vector3.new(0.32,6,6),CFrame.new(targetCenter)*CFrame.Angles(g*1.05,g*0.8,0),g==1 and primary or (g==2 and secondary or accent),0.12)
					Tween:Create(gyro,TweenInfo.new(0.42,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
						Size=Vector3.new(0.12,26,26),
						CFrame=CFrame.new(targetCenter)*CFrame.Angles(g*1.05+1.8,g*0.8+1.8,0),
						Transparency=1,
					}):Play()
					Debris:AddItem(gyro,0.45)
				end
				spawnRingWave(targetCenter-Vector3.new(0,2.4,0),primary,5,28,0.45)
				spawnCraterShards(targetCenter,primary,secondary,8,16,0.45)
				spawnFlashLight(targetCenter,primary,5.5,30,0.45)
				if actorChar==player.Character or not actorChar then
					shakeCamera(0.65,0.42,7)
				end
			end)

		elseif moveKey=="V" then
            -- =========================================================================
            -- CHIÊU [V]: THIÊN PHẠT SƠ KHAI / ĐẠI CUỒNG PHONG TUYỆT KỸ
            -- Rotating Celestial Rune Array + Overhead Charging Supernova Sphere -> Skyfall Cataclysm & 8 Orbital Pillars
            -- =========================================================================
			local center=endPos
			local floorY=center.Y-2.35
			local vFolder=Instance.new("Folder")
			vFolder.Name="SkillV_Cataclysm"
			vFolder.Parent=tempFX
			local totalDur=1.12
			Debris:AddItem(vFolder,totalDur+0.15)

            -- Stage 1: Rotating 3D Celestial Magic Circle on Floor + Overhead Charging Spirit Sphere (0.0s -> 0.48s)
			local outerCircle=vfxPart("SkillV_OuterCircle",Enum.PartType.Cylinder,Vector3.new(0.24,6,6),CFrame.new(center.X,floorY,center.Z)*CFrame.Angles(0,0,math.pi*0.5),primary,0.16)
			outerCircle.Parent=vFolder
			Tween:Create(outerCircle,TweenInfo.new(0.42,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
				Size=Vector3.new(0.24,30,30),
			}):Play()

			local runeSpokes={}
			for i=1,8 do
				local spoke=vfxPart("SkillV_RuneSpoke"..i,Enum.PartType.Block,Vector3.new(0.38,0.18,26),CFrame.new(center.X,floorY+0.08,center.Z)*CFrame.Angles(0,(i-1)*(math.pi/8),0),i%2==0 and secondary or accent,0.14)
				spoke.Parent=vFolder
				table.insert(runeSpokes,spoke)
			end

			local chargeOrigin=center+Vector3.new(0,11.5,0)
			local sunCore=vfxPart("SkillV_SupernovaCore",Enum.PartType.Ball,Vector3.new(2.2,2.2,2.2),CFrame.new(chargeOrigin),secondary,0.04)
			local sunShell=vfxPart("SkillV_SupernovaShell",Enum.PartType.Ball,Vector3.new(3.4,3.4,3.4),CFrame.new(chargeOrigin),primary,0.22)
			local sunHalo1=vfxPart("SkillV_SupernovaHalo1",Enum.PartType.Cylinder,Vector3.new(0.28,4.5,4.5),CFrame.new(chargeOrigin),accent,0.12)
			local sunHalo2=vfxPart("SkillV_SupernovaHalo2",Enum.PartType.Cylinder,Vector3.new(0.28,4.5,4.5),CFrame.new(chargeOrigin),primary,0.12)
			sunCore.Parent=vFolder
			sunShell.Parent=vFolder
			sunHalo1.Parent=vFolder
			sunHalo2.Parent=vFolder

			Tween:Create(sunCore,TweenInfo.new(0.44,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=Vector3.new(7.5,7.5,7.5)}):Play()
			Tween:Create(sunShell,TweenInfo.new(0.44,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=Vector3.new(10.5,10.5,10.5)}):Play()
			Tween:Create(sunHalo1,TweenInfo.new(0.44,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=Vector3.new(0.32,14,14)}):Play()
			Tween:Create(sunHalo2,TweenInfo.new(0.44,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=Vector3.new(0.32,14,14)}):Play()
			spawnFlashLight(chargeOrigin,secondary,5.5,32,0.5)

			local orbitPillars={}
			local slammed=false
			local tStart=os.clock()

            -- Stage 2: At t = 0.46s (when character slams down), streak Supernova into ground & erupt 8 Orbital Sky Pillars!
			task.delay(0.46,function()
				if not vFolder.Parent then return end
				slammed=true
				Tween:Create(sunCore,TweenInfo.new(0.14,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{
					CFrame=CFrame.new(center),
					Size=Vector3.new(28,28,28),
					Transparency=1,
				}):Play()
				Tween:Create(sunShell,TweenInfo.new(0.28,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
					CFrame=CFrame.new(center),
					Size=Vector3.new(38,38,38),
					Transparency=1,
				}):Play()
				Tween:Create(sunHalo1,TweenInfo.new(0.28),{Transparency=1}):Play()
				Tween:Create(sunHalo2,TweenInfo.new(0.28),{Transparency=1}):Play()
				Tween:Create(outerCircle,TweenInfo.new(0.55),{Size=Vector3.new(0.1,42,42),Transparency=1}):Play()

				local mainBeam=vfxPart("SkillV_MainSkyBeam",Enum.PartType.Cylinder,Vector3.new(44,7,7),CFrame.new(center+Vector3.new(0,18,0))*CFrame.Angles(0,0,math.pi*0.5),primary,0.08)
				mainBeam.Parent=vFolder
				Tween:Create(mainBeam,TweenInfo.new(0.62,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
					Size=Vector3.new(48,18,18),
					Transparency=1,
				}):Play()

				for pIdx=1,8 do
					local pil=vfxPart("SkillV_OrbitalPillar"..pIdx,Enum.PartType.Cylinder,Vector3.new(34,2.8,2.8),CFrame.new(center)*CFrame.Angles(0,0,math.pi*0.5),pIdx%2==0 and primary or secondary,0.12)
					pil.Parent=vFolder
					table.insert(orbitPillars,{Part=pil,Index=pIdx})
				end

				spawnRingWave(Vector3.new(center.X,floorY,center.Z),primary,6,42,0.62)
				spawnRingWave(Vector3.new(center.X,floorY+0.5,center.Z),secondary,4,32,0.52)
				spawnRingWave(Vector3.new(center.X,floorY+1.0,center.Z),accent,3,24,0.42)
				spawnCraterShards(center,primary,secondary,12,22,0.62)
				spawnFlashLight(center+Vector3.new(0,3,0),primary,7.0,42,0.62)

				if actorChar==player.Character or not actorChar then
					shakeCamera(0.95,0.55,10)
				end
			end)

			local connV
			connV=Run.RenderStepped:Connect(function()
				local elapsed=os.clock()-tStart
				if elapsed>=totalDur or not vFolder.Parent then
					if connV then connV:Disconnect() connV=nil end
					return
				end
				for idx,sp in ipairs(runeSpokes) do
					if sp and sp.Parent then
						local ang=elapsed*3.2+(idx-1)*(math.pi/8)
						sp.CFrame=CFrame.new(center.X,floorY+0.08,center.Z)*CFrame.Angles(0,ang,0)
						if slammed then
							sp.Transparency=math.clamp((elapsed-0.46)/0.55,0.14,1)
						end
					end
				end
				if not slammed and sunHalo1.Parent and sunHalo2.Parent then
					sunHalo1.CFrame=CFrame.new(sunCore.Position)*CFrame.Angles(elapsed*10,elapsed*8,0)
					sunHalo2.CFrame=CFrame.new(sunCore.Position)*CFrame.Angles(-elapsed*9,0,elapsed*11)
				end
				if slammed then
					local sElapsed=elapsed-0.46
					local sRatio=math.clamp(sElapsed/0.62,0,1)
					for _,op in ipairs(orbitPillars) do
						if op.Part and op.Part.Parent then
							local ang=sElapsed*7.5+(op.Index-1)*(math.pi*0.25)
							local rad=4.5+sRatio*14.5
							local px=center.X+math.cos(ang)*rad
							local pz=center.Z+math.sin(ang)*rad
							op.Part.CFrame=CFrame.new(px,floorY+15,pz)*CFrame.Angles(0,0,math.pi*0.5)
							op.Part.Size=Vector3.new(34,2.8*(1-sRatio*0.65),2.8*(1-sRatio*0.65))
							op.Part.Transparency=0.12+sRatio*0.88
						end
					end
				end
			end)

		elseif moveKey=="F" then
            -- =========================================================================
            -- CHIÊU [F]: BỘ PHÁP CƯỠI GIÓ / PHI HÀNH XUNG KÍCH
            -- Takeoff Sonic Boom + 6 Sequential Slipstream Rings + Helical Wind Tunnel from startPos to endPos + Mach Cone
            -- =========================================================================
			local dashVec=endPos-startPos
			local dashDist=dashVec.Magnitude
			local dashDir=dashDist>0.5 and dashVec.Unit or lookDir
			local actualEnd=dashDist>0.5 and endPos or (startPos+dashDir*24)
			local totalDist=(actualEnd-startPos).Magnitude
			local pathCF=safeLook(startPos,actualEnd)

            -- 1. Takeoff Sonic Boom Ring + Flash
			local takeoffRing=vfxPart("SkillF_TakeoffRing",Enum.PartType.Cylinder,Vector3.new(0.35,3.5,3.5),pathCF*CFrame.Angles(0,math.pi*0.5,0),primary,0.12)
			Tween:Create(takeoffRing,TweenInfo.new(0.38,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
				Size=Vector3.new(0.10,15,15),
				Transparency=1,
			}):Play()
			Debris:AddItem(takeoffRing,0.42)
			spawnFlashLight(startPos,primary,4.5,24,0.4)

            -- 2. Central Jetstream Beam & 6 Sequential Sonic Slipstream Rings along Dash Path
			local midPath=(startPos+actualEnd)*0.5
			local jetStream=vfxPart("SkillF_JetstreamCore",Enum.PartType.Cylinder,Vector3.new(totalDist,2.6,2.6),safeLook(midPath,actualEnd)*CFrame.Angles(0,math.pi*0.5,0),secondary,0.18)
			Tween:Create(jetStream,TweenInfo.new(0.45,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
				Size=Vector3.new(totalDist,0.3,0.3),
				Transparency=1,
			}):Play()
			Debris:AddItem(jetStream,0.48)

			local ringSteps=6
			for i=1,ringSteps do
				local frac=i/ringSteps
				task.delay((i-1)*0.032,function()
					local rPos=startPos:Lerp(actualEnd,frac)
					local rCF=safeLook(rPos,rPos+dashDir)
					local sRing=vfxPart("SkillF_SlipstreamRing"..i,Enum.PartType.Cylinder,Vector3.new(0.28,3.2,3.2),rCF*CFrame.Angles(0,math.pi*0.5,0),i%2==0 and primary or secondary,0.14)
					Tween:Create(sRing,TweenInfo.new(0.36,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{
						Size=Vector3.new(0.10,11.5,11.5),
						Transparency=1,
					}):Play()
					Debris:AddItem(sRing,0.40)

                    -- Helical Wind Ribbon Pairs
					for h=1,2 do
						local hAng=frac*math.pi*4+(h-1)*math.pi
						local hOff=Vector3.new(math.cos(hAng)*2.2,math.sin(hAng)*2.2,-1.2)
						local hSeg=vfxPart("SkillF_HelixSeg"..i.."_"..h,Enum.PartType.Block,Vector3.new(0.28,0.28,4.6),rCF*CFrame.new(hOff)*CFrame.Angles(0,0,hAng),h==1 and primary or accent,0.12)
						Tween:Create(hSeg,TweenInfo.new(0.38,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
							CFrame=rCF*CFrame.new(hOff*1.6)*CFrame.Angles(0,0,hAng+0.6),
							Size=Vector3.new(0.08,0.08,5.8),
							Transparency=1,
						}):Play()
						Debris:AddItem(hSeg,0.42)
					end
				end)
			end

            -- 3. Live Character-Tracked Aerodynamic Mach Wind Cone & Landing Burst
			local fFolder=Instance.new("Folder")
			fFolder.Name="SkillF_MachShroud"
			fFolder.Parent=tempFX
			local machDur=0.52
			Debris:AddItem(fFolder,machDur+0.1)

			local machRing1=vfxPart("SkillF_MachRing1",Enum.PartType.Cylinder,Vector3.new(0.24,5.2,5.2),CFrame.new(actualEnd),primary,0.16)
			local machRing2=vfxPart("SkillF_MachRing2",Enum.PartType.Cylinder,Vector3.new(0.20,3.8,3.8),CFrame.new(actualEnd),secondary,0.18)
			machRing1.Parent=fFolder
			machRing2.Parent=fFolder

			local tF=os.clock()
			local connF
			connF=Run.RenderStepped:Connect(function()
				local elapsed=os.clock()-tF
				if elapsed>=machDur or not fFolder.Parent then
					if connF then connF:Disconnect() connF=nil end
					return
				end
				local pRatio=elapsed/machDur
				local curCF=(actorRoot and actorRoot.Parent) and actorRoot.CFrame or safeLook(actualEnd,actualEnd+dashDir)
				if machRing1.Parent then
					machRing1.CFrame=curCF*CFrame.new(0,0,1.2)*CFrame.Angles(0,math.pi*0.5,elapsed*18)
					machRing1.Size=Vector3.new(0.24,5.2+pRatio*4.0,5.2+pRatio*4.0)
					machRing1.Transparency=0.16+pRatio*0.84
				end
				if machRing2.Parent then
					machRing2.CFrame=curCF*CFrame.new(0,0,-1.2)*CFrame.Angles(0,math.pi*0.5,-elapsed*18)
					machRing2.Size=Vector3.new(0.20,3.8+pRatio*3.0,3.8+pRatio*3.0)
					machRing2.Transparency=0.18+pRatio*0.82
				end
			end)

			spawnRingWave(actualEnd-Vector3.new(0,2.2,0),secondary,3.5,18,0.40)
			spawnFlashLight(actualEnd,secondary,4.5,24,0.40)
			if actorChar==player.Character or not actorChar then
				shakeCamera(0.35,0.25,4)
			end

		else
            -- Fallback Elemental Blast for non-ZXCVF skills
			local isUltimate=skillId:find("Sovereign") or skillId:find("Titan") or skillId:find("Cataclysm") or skillId:find("Transform")
			local scaleMult=isUltimate and 1.55 or 1.0
			local pillar=vfxPart("ElementalPillar",Enum.PartType.Cylinder,Vector3.new(28*scaleMult,5*scaleMult,5*scaleMult),CFrame.new(pos+Vector3.new(0,10*scaleMult,0))*CFrame.Angles(0,0,math.pi/2),primary,.12)
			local core=vfxPart("ElementalBurstCore",Enum.PartType.Ball,Vector3.new(4*scaleMult,4*scaleMult,4*scaleMult),CFrame.new(pos),secondary,.08)
			Tween:Create(pillar,TweenInfo.new(.52,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(36*scaleMult,15*scaleMult,15*scaleMult),Transparency=1}):Play()
			Tween:Create(core,TweenInfo.new(.48,Enum.EasingStyle.Quart,Enum.EasingDirection.Out),{Size=Vector3.new(22*scaleMult,22*scaleMult,22*scaleMult),Transparency=1}):Play()
			Debris:AddItem(pillar,.56)
			Debris:AddItem(core,.52)
			spawnRingWave(pos-Vector3.new(0,2,0),primary,5*scaleMult,28*scaleMult,.52)
			spawnFlashLight(pos,primary,isUltimate and 6.0 or 4.2,28*scaleMult,.5)
			if actorChar==player.Character or not actorChar then
				shakeCamera(isUltimate and 0.95 or 0.48,isUltimate and 0.52 or 0.32,isUltimate and 10 or 5)
			end
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

    -- Tune Realm Lighting & Anti-Washout Crisp Horizon Settings (GoldenSky & All Realms)
	local isGolden = (realm == "GoldenSky" or realm == "SkyHub" or realm == "VerdantCrown" or realm == "ChronosBastion")
	if isGolden then
		Lighting.Brightness = 1.35
		Lighting.ExposureCompensation = -0.22
		Lighting.OutdoorAmbient = Color3.fromRGB(112, 120, 142)
		Lighting.Ambient = Color3.fromRGB(72, 78, 96)
	else
		Lighting.Brightness = math.min(Lighting.Brightness or 1.38, 1.40)
		Lighting.ExposureCompensation = math.min(Lighting.ExposureCompensation or -0.20, -0.20)
	end
	local atmo = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere", Lighting)
	atmo.Density = isGolden and 0.14 or 0.16
	atmo.Haze = math.min(atmo.Haze or 0.20, 0.20)
	atmo.Offset = 0.12
	atmo.Glare = math.min(atmo.Glare or 0.05, 0.06)
	Lighting.FogColor = atmo.Color
	Lighting.FogStart = (Lighting.FogStart and Lighting.FogStart >= 800 and Lighting.FogStart <= 1200) and Lighting.FogStart or 900
	Lighting.FogEnd = (Lighting.FogEnd and Lighting.FogEnd >= 8000 and Lighting.FogEnd <= 12000) and Lighting.FogEnd or 9500

	local bloom = Lighting:FindFirstChild("SkybreakBloom") or Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect", Lighting)
	bloom.Name = "SkybreakBloom"
	bloom.Enabled = true
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("BloomEffect") then
			child.Intensity = math.clamp(child.Intensity or 0.16, 0.03, 0.32)
			child.Threshold = math.max(child.Threshold or 1.55, 1.45)
			child.Size = 18
		end
	end

	local grade = Lighting:FindFirstChild("SkybreakGrade") or Instance.new("ColorCorrectionEffect", Lighting)
	grade.Name = "SkybreakGrade"
	grade.Enabled = true
	grade.Brightness = 0.01
	grade.Contrast = 0.08
	grade.Saturation = 0.12
	for _, child in ipairs(Lighting:GetChildren()) do
		if child:IsA("ColorCorrectionEffect") and child.Name ~= "InstinctVision" then
			child.Contrast = 0.08
			child.Saturation = 0.12
		end
	end

	local dof = Lighting:FindFirstChild("SkybreakDistanceDOF") or Instance.new("DepthOfFieldEffect", Lighting)
	dof.Name = "SkybreakDistanceDOF"
	dof.Enabled = true
	dof.FarIntensity = 0.04
	dof.FocusDistance = 380
	dof.InFocusRadius = 520
	dof.NearIntensity = 0
end
local applyRealmAtmosphere = updateRealmAtmosphere
local updateRealmLighting = updateRealmAtmosphere

player:GetAttributeChangedSignal("CurrentRealm"):Connect(updateRealmAtmosphere)
task.defer(updateRealmAtmosphere)

player:GetAttributeChangedSignal("OpenFruitShowcaseUI"):Connect(function()
	local val = tostring(player:GetAttribute("OpenFruitShowcaseUI") or "")
	if val == "" then return end
	local fruitName = val:match("^([^|]+)") or val
	playSFX("shrine_bless", nil, 0.03)
	pcall(function()
		UI.Show("Fruits")
		UI.Toast("[3D FRUIT] Đang cầm thử 3D: " .. fruitName .. "!")
	end)
end)

-- ============================================================================
-- 6. ACTION DISPATCHER & HOTKEY BINDINGS (1-4, Z-X-C-V-F, J, U, H, Y, G)
-- ============================================================================
local function fireSlotMove(keyLetter)
	if UI.BlocksCombat() or UIS:GetFocusedTextBox() then return end
	faceLockedTarget()
	if player.Character then
		player.Character:SetAttribute("LastClientSkillKey",tostring(keyLetter or "Z"))
		player.Character:SetAttribute("LastClientSkillAt",os.clock())
	end
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
			local showcaseFruitId=nearby:GetAttribute("ShowcaseFruitId")
			if showcaseFruitId then
				local showcaseName=tostring(nearby:GetAttribute("ShowcaseFruitName") or showcaseFruitId)
				playSFX("shrine_bless",nearby.Position,0.03)
				remotes.EquipmentRequest:FireServer({
					action="HoldFruit",
					fruitId=showcaseFruitId,
					forceHold=true,
					showcasePreview=true,
				})
				player:SetAttribute("ShowcaseFruitUntil",os.clock()+8)
				player:SetAttribute("HeldFruit",showcaseFruitId)
				if player.Character then
					player.Character:SetAttribute("HeldFruit",showcaseFruitId)
				end
				player:SetAttribute("SelectedPreviewFruit",showcaseFruitId)
				pcall(function()
					UI.Show("Fruits")
					UI.Toast("[3D FRUIT] Đang cầm thử 3D: "..showcaseName.."!")
				end)
				return
			end
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
	if action=="UsePotion" or action=="Potion" then
		remotes.EquipmentRequest:FireServer({action="UsePotion"})
		return
	end
	if action=="V" then
		faceLockedTarget()
		local ch=player.Character
		local hum=ch and ch:FindFirstChildOfClass("Humanoid")
		remotes.AbilityRequest:FireServer({action="SlotMove",key="V"})
		if hum and hum.Health<hum.MaxHealth then
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
		if skillId=="FlashStep" and player.Character then
			local root=player.Character:FindFirstChild("HumanoidRootPart")
			local hum=player.Character:FindFirstChildOfClass("Humanoid")
			local dir=(hum and hum.MoveDirection.Magnitude>0.05) and hum.MoveDirection.Unit or (root and root.CFrame.LookVector or Vector3.new(0,0,-1))
			performDashGlide(player.Character,"FlashStep",dir,58,0.34)
		end
		remotes.AbilityRequest:FireServer({skillId=skillId})
	else
		local ch=player.Character
		local root=ch and ch:FindFirstChild("HumanoidRootPart")
		local hum=ch and ch:FindFirstChildOfClass("Humanoid")
		if action=="Dash" or action=="Dodge" then
			local now=os.clock()
			local isDash=(action=="Dash")
			local cd=isDash and 0.85 or 1.35
			local lastT=isDash and lastClientDashTime or lastClientDodgeTime
			local dir=Vector3.new(0,0,-1)
			if hum and hum.MoveDirection.Magnitude>0.05 then
				dir=hum.MoveDirection.Unit
			elseif root then
				local lk=root.CFrame.LookVector
				local flatLk=Vector3.new(lk.X,0,lk.Z)
				if flatLk.Magnitude>0.05 then
					dir=isDash and flatLk.Unit or -flatLk.Unit
				end
			end
			if now-lastT>=cd then
				if isDash then lastClientDashTime=now else lastClientDodgeTime=now end
				performDashGlide(ch,action,dir,isDash and 44 or 38,isDash and 0.38 or 0.34)
			end
			remotes.CombatRequest:FireServer({action=action,direction=dir})
		else
			if action=="Attack" or action=="Heavy" then
				faceLockedTarget()
				performCombatLunge(ch,action=="Heavy")
			end
			remotes.CombatRequest:FireServer({action=action})
		end
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
		if o:IsA("ProximityPrompt") and o.Name~="InspectFruit3DPrompt" then o.Style=Enum.ProximityPromptStyle.Custom end
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
	if kc==Enum.KeyCode.Z then
		if not UI.BlocksCombat() then
			fireSlotMove("Z")
		end
	elseif kc==Enum.KeyCode.X then
		if not UI.BlocksCombat() then
			fireSlotMove("X")
		end
	elseif kc==Enum.KeyCode.C then
		if not UI.BlocksCombat() then
			fireSlotMove("C")
		end
	elseif kc==Enum.KeyCode.T then
		if not UI.BlocksCombat() then
			fireSlotMove("V")
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
			if player.Character then
				player.Character:SetAttribute("NativeRaceV4Toggled",true)
			end
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
				local shiftDown=UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)
				if shiftDown or UI.Page=="Quests" then
					if UI.Toggle then UI.Toggle("Quests") else UI.Show(UI.Page=="Quests" and "HUD" or "Quests") end
				elseif not UI.BlocksCombat() then
					remotes.EquipmentRequest:FireServer({action="ToggleAura"})
				end
			elseif name=="Forge" then
				local shiftDown=UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)
				if shiftDown or UI.Page=="Forge" then
					if UI.Toggle then UI.Toggle("Forge") else UI.Show(UI.Page=="Forge" and "HUD" or "Forge") end
				elseif not UI.BlocksCombat() then
					local slot=tonumber(player:GetAttribute("ActiveSlot")) or 1
					if slot~=2 and player:GetAttribute("SkybreakFlightActive")~=true then
						task.delay(0.25,function()
							if player:GetAttribute("SkybreakFlightActive")~=true and not UI.BlocksCombat() then
								faceLockedTarget()
								remotes.AbilityRequest:FireServer({action="SlotMove",key="F"})
							end
						end)
					end
				else
					if UI.Toggle then UI.Toggle("Forge") else UI.Show("Forge") end
				end
			elseif name=="Ultimate" then
				local shiftDown=UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)
				local cmdEvt=tempFX:FindFirstChild("SkybreakFlightCamCommand")
				if not shiftDown and cmdEvt and cmdEvt:IsA("BindableEvent") then
					cmdEvt:Fire("FlashStep")
				else
					send("Ultimate")
				end
			elseif name=="UsePotion" then
				local shiftDown=UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)
				if shiftDown then
					send("UsePotion")
				else
					send("V")
				end
			elseif name=="ToggleLock" then
				local shiftDown=UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)
				local cmdEvt=tempFX:FindFirstChild("SkybreakFlightCamCommand")
				if shiftDown and cmdEvt and cmdEvt:IsA("BindableEvent") then
					cmdEvt:Fire("UnlockAllCamera")
				else
					send("ToggleLock")
				end
			elseif PAGE_KEYS[name] then
				if UI.Toggle then
					UI.Toggle(name)
				else
					UI.Show(UI.Page==name and "HUD" or name)
				end
			else
				send(name)
			end
		end
		return Enum.ContextActionResult.Sink
	end,false,Enum.ContextActionPriority.High.Value,key)
end

remotes.StateUpdate.OnClientEvent:Connect(function(payload)
	if payload.TeleportSnap and typeof(payload.TeleportSnap)=="Vector3" then
		local ch=player.Character
		local r=ch and ch:FindFirstChild("HumanoidRootPart")
		local h=ch and ch:FindFirstChildOfClass("Humanoid")
		if r then
			r.Anchored=false
			r.CFrame=CFrame.new(payload.TeleportSnap)*r.CFrame.Rotation
			r.AssemblyLinearVelocity=Vector3.zero
			r.AssemblyAngularVelocity=Vector3.zero
		end
		if h then
			h.PlatformStand=false
			airJumpCount=0
		end
	end
	if payload.State then
		local st=payload.State
		st.Companions={}
		st.PartySize="Solo"
		if lastKnownLevel and st.Level and st.Level>lastKnownLevel then
			playSFX("level_up",nil,0.01)
			if ClientVFX and type(ClientVFX.SpawnProgressionVFX)=="function" then
				ClientVFX.SpawnProgressionVFX("LevelUp",player.Character)
			end
		end
		lastKnownLevel=st.Level or lastKnownLevel
		local qid=st.Quest and st.Quest.Id or nil
		if lastKnownQuestId and qid and qid~=lastKnownQuestId then
			playSFX("quest_complete",nil,0.01)
			if ClientVFX and type(ClientVFX.SpawnProgressionVFX)=="function" then
				ClientVFX.SpawnProgressionVFX("Quest",player.Character)
			end
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
			if ClientVFX and type(ClientVFX.SpawnProgressionVFX)=="function" then
				ClientVFX.SpawnProgressionVFX("Shrine",player.Character)
			end
		end
		UI.Message(payload.Message)
	end
end)

local function playCombatActionSFX(kind,action,pos,combo,element)
	local act=tostring(action or "")
	local el=tostring(element or "")
	if kind=="ChestOpened" then
		playSFX("chest_open",pos,0.04)
	elseif kind=="LootOrbPickup" then
		playSFX("coin_collect",pos,0.06)
	elseif kind=="ShipCannonBlast" then
		playSFX("ship_cannon",pos,0.05)
	elseif kind=="CloudGeyserRescue" then
		playSFX("cloud_geyser",pos,0.04)
	elseif kind=="DragonTransform" or act=="DragonTransform" then
		if (tonumber(combo) or 1)>0 then
			playSFX("boss_roar",pos,0.04)
		else
			playSFX("portal_warp",pos,0.05)
		end
	elseif kind=="InstinctDodge" or act=="InstinctDodge" or act=="InstinctToggle" then
		playSFX("haki_instinct",pos,0.04)
	elseif kind=="RaceV4Unlock" or act=="RaceV4Awaken" or act=="RaceV4Unlock" then
		playSFX("level_up",pos,0.03)
	elseif kind=="HakiStageUp" or act=="HakiStageUp" or act=="ConquerorHaki" or act=="ConquerorBurst" then
		playSFX("haki_conqueror",pos,0.03)
	elseif kind=="GunShot" or kind=="SeaBeastBeam" then
		playSFX("light_beam",pos,0.05)
	elseif act=="FlashStep" then
		playSFX("flash_step",pos,0.05)
	elseif kind=="Dodge" or act=="Dodge" or act=="Dash" then
		playSFX("dodge_dash",pos,0.06)
	elseif kind=="Shield" or act=="GuardianShield" or act=="ManaBarrier" then
		playSFX("skill_guardian_shield",pos,0.04)
	elseif kind=="PortalWarp" or act:find("Portal") or act:find("Dimensional") or el=="Portal" then
		playSFX("portal_warp",pos,0.05)
	elseif act:find("Gravity") or act:find("Meteor") or el=="Gravity" then
		playSFX("gravity_crush",pos,0.04)
	elseif act:find("Magma") or act:find("Volcan") or el=="Magma" then
		playSFX("magma_erupt",pos,0.05)
	elseif act:find("Flame") or act:find("Fire") or act:find("Solar") or el=="Flame" or el=="Fire" then
		playSFX("flame_burst",pos,0.05)
	elseif act:find("Light") or act:find("Lumen") or el=="Light" then
		playSFX("light_beam",pos,0.05)
	elseif act=="AstralCataclysm" or el=="Void" or act:find("Void") or act:find("Abyss") or act:find("Shadow") then
		playSFX("skill_void_rift",pos,0.04)
	elseif act=="ArcCut" or act=="StormBlitz" or act=="ThunderJudgement" or el=="Lightning" or act:find("Thunder") or act:find("Storm") then
		playSFX("skill_thunder_strike",pos,0.05)
	elseif act=="FrostBolt" or act=="ArcaneComet" or el=="Frost" or act:find("Frost") or act:find("Ice") or act:find("Cryo") then
		playSFX("skill_frost_shatter",pos,0.05)
	elseif act=="JudgmentStrike" or act=="CelestialAegis" then
		playSFX("skill_judgment_strike",pos,0.04)
	elseif act=="SkySlash" or kind=="ChargedSlash" then
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
	local actorId=fx.Actor or fx.Owner or fx.userId
	local actor=(type(actorId)=="number" and actorId>0) and Players:GetPlayerByUserId(actorId) or nil
	local actorChar=actor and actor.Character
	local pos=fx.Position or fx.pos or fx.Origin or fx.StartPos
	if typeof(pos)~="Vector3" then
		local fallbackCh=actorChar or ((actorId==nil or actorId==player.UserId) and player.Character or nil)
		local fallbackRoot=fallbackCh and fallbackCh:FindFirstChild("HumanoidRootPart")
		if fallbackRoot then pos=fallbackRoot.Position end
	end

	if kind=="DamageNumber" or kind=="Hit" or kind=="LogiaDodge" or kind=="ElementalReflex" or fx.LogiaDodge==true or fx.amount~=nil or fx.Amount~=nil or fx.Text~=nil then
		if (kind=="LogiaDodge" or kind=="ElementalReflex" or fx.LogiaDodge==true) and fx.Text==nil and fx.amount==nil then
			fx.Text="ELEMENTAL REFLEX"
		end
		spawnDamagePopup(fx)
	else
		local sfxArg=(fx.DragonFormTier~=nil) and fx.DragonFormTier or fx.Combo
		playCombatActionSFX(kind,action,pos,sfxArg,fx.element or fx.Element)
	end

	if actorChar then
		if kind=="Dodge" or action=="Dash" or action=="Dodge" or action=="FlashStep" then
			local lastDash=tonumber(actorChar:GetAttribute("LastDashAt")) or 0
			if os.clock()-lastDash>0.22 then
				performDashGlide(actorChar,action or "Dash",fx.Direction,fx.Travel,fx.Duration)
			end
		end
		local animAction=kind=="Shield" and "Shield" or action
		if animAction=="JudgmentStrike" or animAction=="ConquerorHaki" then animAction="Heavy"
		elseif animAction=="CelestialAegis" then animAction="SkySlash" end
		if animAction and not ((kind=="DragonTransform" or action=="DragonTransform") and tonumber(fx.DragonFormTier)==0) then
			GuardianAnimator.Action(actorChar,animAction,fx.Combo)
		end
	end

	if kind=="Shield" and typeof(pos)=="Vector3" then
		spawnSkillVFX(action or "GuardianShield",pos,actorChar,fx)
		for _,ally in ipairs(Players:GetPlayers()) do
			local ch=ally.Character
			local r=ch and ch:FindFirstChild("HumanoidRootPart")
			if r and (r.Position-pos).Magnitude<20 then
				if ally.UserId~=fx.Actor then GuardianAnimator.Action(ch,"Shield") end
				if ClientVFX and type(ClientVFX.SpawnShieldBubble)=="function" then
					ClientVFX.SpawnShieldBubble(ch,action=="ManaBarrier")
				end
			end
		end
		return
	end

	if kind=="BossBreak" and typeof(pos)=="Vector3" then
		spawnDamagePopup({Position=pos,Text=fx.Tag or "BREAK!",IsBreak=true,Crit=true,Element="Solar"})
		spawnSkillVFX("JudgmentStrike",pos,actorChar,fx)
		return
	end

	if typeof(pos)=="Vector3" and (kind=="Swing" or kind=="Dodge" or kind=="Skill" or kind=="Burst" or kind=="SlotMove" or kind=="FruitMove" or kind=="StyleMove" or kind=="ChargedSlash" or kind=="GunShot" or kind=="DragonTransform" or kind=="PortalWarp" or kind=="SeaBeastBeam" or kind=="HakiStageUp" or kind=="RaceV4Unlock" or kind=="ChestOpened" or kind=="LootOrbPickup" or kind=="ShipCannonBlast" or kind=="CloudGeyserRescue" or fx.skillId~=nil or fx.key~=nil or fx.MoveKey~=nil) then
		spawnSkillVFX(action or kind or "Attack",pos,actorChar,fx)
	end
end

remotes.CombatFX.OnClientEvent:Connect(handleCombatFX)
local combatEventRemote=remotes:FindFirstChild("CombatEvent")
if combatEventRemote and combatEventRemote:IsA("RemoteEvent") then
	combatEventRemote.OnClientEvent:Connect(handleCombatFX)
end

-- Client-side cleanup for JumpPads, AetherSkyRails, DummyFloorRing, and 3 AI Companions UI
task.spawn(function()
	local function purgeRemovedWorldClutter()
		for _, folderName in ipairs({"JumpPads", "AetherSkyRails", "ActiveCompanions"}) do
			local f = workspace:FindFirstChild(folderName)
			if f then
				f:ClearAllChildren()
			end
		end
		local activeEnemies = workspace:FindFirstChild("ActiveEnemies")
		if activeEnemies then
			for _, desc in ipairs(activeEnemies:GetDescendants()) do
				if desc:IsA("BasePart") and desc.Name == "DummyFloorRing" then
					desc.Transparency = 1
					desc.LocalTransparencyModifier = 1
					desc.CanCollide = false
					desc.CanQuery = false
					desc.CanTouch = false
				end
			end
		end
		local pgui = player:FindFirstChild("PlayerGui")
		if pgui then
			for _, desc in ipairs(pgui:GetDescendants()) do
				if desc:IsA("GuiObject") and (desc.Name == "CompanionTitle" or desc.Name == "ThreeAICompanionCards" or desc.Name:sub(1, 13) == "CompanionCard") then
					desc.Visible = false
				end
			end
		end
	end
	purgeRemovedWorldClutter()
	workspace.ChildAdded:Connect(function(ch)
		if ch.Name == "JumpPads" or ch.Name == "AetherSkyRails" or ch.Name == "ActiveCompanions" then
			task.defer(function()
				ch:ClearAllChildren()
			end)
			ch.ChildAdded:Connect(function(sub)
				task.defer(function()
					pcall(function() sub:Destroy() end)
				end)
			end)
		end
	end)
	while player.Parent do
		task.wait(1.5)
		purgeRemovedWorldClutter()
	end
end)
