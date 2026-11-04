--!nonstrict
-- ============================================================================
-- SKYBREAK: 3D ELEMENTAL FLIGHT, DYNAMIC COMBAT CAMERA, TRAVERSAL & SOCIAL
-- Owned by Wave 2 Client Flight & Camera Script (SkybreakFlightAndCamera.client.lua)
-- Tasks: #76 (Dynamic Combat Camera Juice), #77 (Shift-Lock OTS Action Cam),
--        #78 (Target Lock-On [Tab] & Head Look-At), #81 (6-DOF 3D Free Flight [F]),
--        #82 (36-Stud Flash Step [R] + 3 Afterimages), #83 (Ledge Mantle + Skydive),
--        #88 (Full Gamepad Support), #89 (6-Slice Emotes & Meditation Wheel [B]),
--        #97 (Cinematic Free-Cam Photo Mode [F8])
-- ============================================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CombatRequest = Remotes:WaitForChild("CombatRequest")
local AbilityRequest = Remotes:WaitForChild("AbilityRequest")
local EquipmentRequest = Remotes:WaitForChild("EquipmentRequest")
local CombatFX = Remotes:WaitForChild("CombatFX")

local AudioEngine = nil
pcall(function()
	AudioEngine = require(script.Parent:WaitForChild("SkybreakAudioEngine", 5))
end)

local UI = nil
pcall(function()
	UI = require(script.Parent:WaitForChild("UI", 5):WaitForChild("Interface", 5))
end)

local tempFX = Workspace:FindFirstChild("TempFX")
if not tempFX then
	tempFX = Instance.new("Folder")
	tempFX.Name = "TempFX"
	tempFX.Parent = Workspace
end

-- Shared BindableEvents for zero-coupling communication with ClientBootstrap & SkybreakClientVFX
local cameraImpulseEvent = tempFX:FindFirstChild("SkybreakCameraImpulse")
if not cameraImpulseEvent then
	cameraImpulseEvent = Instance.new("BindableEvent")
	cameraImpulseEvent.Name = "SkybreakCameraImpulse"
	cameraImpulseEvent.Parent = tempFX
end

local commandEvent = tempFX:FindFirstChild("SkybreakFlightCamCommand")
if not commandEvent then
	commandEvent = Instance.new("BindableEvent")
	commandEvent.Name = "SkybreakFlightCamCommand"
	commandEvent.Parent = tempFX
end

local function isLowFX()
	return (player and player:GetAttribute("LowFXMode") == true) or (Workspace:GetAttribute("LowFXMode") == true) or (UI and UI.LowFX == true) or false
end

local function safeLookAt(fromPos, toPos, fallbackDir)
	local delta = toPos - fromPos
	local dir
	if delta.Magnitude > 0.05 then
		dir = delta.Unit
	elseif typeof(fallbackDir) == "Vector3" and fallbackDir.Magnitude > 0.05 then
		dir = fallbackDir.Unit
	else
		dir = Vector3.new(0, 0, -1)
	end
	local upVec = (math.abs(dir.Y) > 0.995) and Vector3.new(0, 0, 1) or Vector3.new(0, 1, 0)
	return CFrame.lookAt(fromPos, fromPos + dir, upVec)
end

local function blocksCombat()
	if player:GetAttribute("SkybreakPhotoMode") == true then return true end
	if UI and type(UI.BlocksCombat) == "function" then
		local ok, res = pcall(UI.BlocksCombat)
		if ok and res then return true end
	end
	return false
end

local function playSFX(id, pos, jitter)
	if AudioEngine and type(AudioEngine.PlaySFX) == "function" then
		pcall(AudioEngine.PlaySFX, id, pos, jitter or 0.04)
	end
end

local function toast(msg)
	if UI and type(UI.Toast) == "function" then
		pcall(UI.Toast, msg)
	end
end

local function makeFXPart(name, shape, size, cf, color, transparency, mat, parent)
	local p = Instance.new("Part")
	p.Name = name or "FX"
	p.Shape = shape or Enum.PartType.Block
	p.Size = size or Vector3.new(1, 1, 1)
	p.CFrame = cf or CFrame.new()
	p.Color = color or Color3.fromRGB(115, 228, 255)
	p.Material = mat or Enum.Material.SmoothPlastic
	p.Transparency = math.clamp(transparency or 0.16, 0, 1)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Parent = parent or tempFX
	return p
end

local function safeLight(parent, color, brightness, range, dur)
	if isLowFX() or not parent then return nil end
	local pl = Instance.new("PointLight")
	pl.Color = color
	pl.Brightness = math.clamp(brightness or 1.15, 0, 1.45)
	pl.Range = math.clamp(range or 12, 2, 16)
	pl.Shadows = false
	pl.Parent = parent
	if dur and dur > 0 then
		TweenService:Create(pl, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Brightness = 0 }):Play()
	end
	return pl
end

-- ============================================================================
-- FRUIT RESOLVER & PER-FRUIT FLIGHT SPEED / VISUAL SPECS (#81)
-- ============================================================================
local FRUIT_SPECS = {
	CelestialLightCore = { Speed = 115, Primary = Color3.fromRGB(255, 232, 98), Secondary = Color3.fromRGB(255, 248, 192), Mode = "LightBeam" },
	GaleCore = { Speed = 88, Primary = Color3.fromRGB(122, 246, 214), Secondary = Color3.fromRGB(214, 255, 244), Mode = "WindCyclone" },
	AbyssalSovereignCore = { Speed = 88, Primary = Color3.fromRGB(255, 46, 150), Secondary = Color3.fromRGB(168, 38, 255), Mode = "DragonWings" },
	ThunderRumbleCore = { Speed = 88, Primary = Color3.fromRGB(82, 196, 255), Secondary = Color3.fromRGB(186, 132, 255), Mode = "LightningForm" },
	SolarFlameCore = { Speed = 76, Primary = Color3.fromRGB(255, 128, 44), Secondary = Color3.fromRGB(255, 212, 88), Mode = "FlameJets" },
	GlacierIceCore = { Speed = 76, Primary = Color3.fromRGB(108, 228, 255), Secondary = Color3.fromRGB(218, 248, 255), Mode = "IceSkyBridge" },
	DimensionalPortalCore = { Speed = 76, Primary = Color3.fromRGB(58, 216, 255), Secondary = Color3.fromRGB(42, 98, 196), Mode = "PortalRings" },
	AetherflowCore = { Speed = 76, Primary = Color3.fromRGB(248, 222, 168), Secondary = Color3.fromRGB(255, 184, 112), Mode = "DoughWheel" },
	StarforgedMagmaCore = { Speed = 64, Primary = Color3.fromRGB(232, 68, 34), Secondary = Color3.fromRGB(255, 156, 52), Mode = "MagmaHound" },
	AstralGravityCore = { Speed = 64, Primary = Color3.fromRGB(158, 86, 248), Secondary = Color3.fromRGB(86, 62, 118), Mode = "GravityBoulder" },
	SandstoneCore = { Speed = 64, Primary = Color3.fromRGB(234, 196, 122), Secondary = Color3.fromRGB(178, 138, 76), Mode = "SandWhirlwind" },
	SolarTitanCore = { Speed = 64, Primary = Color3.fromRGB(255, 208, 76), Secondary = Color3.fromRGB(255, 240, 164), Mode = "BuddhaLotus" },
}

local function resolveEquippedFruitKey()
	local ch = player.Character
	local raw = tostring((ch and ch:GetAttribute("EquippedFruit")) or player:GetAttribute("EquippedFruit") or (ch and ch:GetAttribute("HeldFruit")) or "")
	if FRUIT_SPECS[raw] then return raw end
	local low = raw:lower()
	if low:find("light") or low:find("lumen") then return "CelestialLightCore" end
	if low:find("gale") or low:find("wind") then return "GaleCore" end
	if low:find("abyss") or low:find("dragon") or low:find("sovereign") then return "AbyssalSovereignCore" end
	if low:find("rumble") or low:find("thunder") or low:find("tempest") then return "ThunderRumbleCore" end
	if low:find("flame") or low:find("fire") or low:find("phoenix") then return "SolarFlameCore" end
	if low:find("ice") or low:find("glac") or low:find("frost") then return "GlacierIceCore" end
	if low:find("portal") or low:find("dimension") then return "DimensionalPortalCore" end
	if low:find("aetherflow") or low:find("dough") then return "AetherflowCore" end
	if low:find("magma") or low:find("crimson") then return "StarforgedMagmaCore" end
	if low:find("grav") then return "AstralGravityCore" end
	if low:find("sand") or low:find("quake") then return "SandstoneCore" end
	if low:find("titan") or low:find("buddha") then return "SolarTitanCore" end
	return "GaleCore"
end

-- ============================================================================
-- OVERLAY SCREENGUI (OTS CROSSHAIR + GAMEPAD HINTS)
-- ============================================================================
local overlayGui = nil
local crosshairFrame = nil
local gamepadHintBar = nil

local function ensureOverlayGui()
	local pgui = player:FindFirstChildOfClass("PlayerGui")
	if not pgui then return nil end
	if overlayGui and overlayGui.Parent then return overlayGui end

	local sg = Instance.new("ScreenGui")
	sg.Name = "SkybreakActionOverlayGui"
	sg.IgnoreGuiInset = true
	sg.ResetOnSpawn = false
	sg.DisplayOrder = 16
	sg.Parent = pgui

	-- #77 Subtle Center Reticle for Shift-Lock Over-The-Shoulder Action Cam
	local ch = Instance.new("Frame")
	ch.Name = "OTSCrosshair"
	ch.AnchorPoint = Vector2.new(0.5, 0.5)
	ch.Position = UDim2.fromScale(0.5, 0.48)
	ch.Size = UDim2.fromOffset(18, 18)
	ch.BackgroundTransparency = 1
	ch.Visible = false
	ch.Parent = sg

	local dot = Instance.new("Frame")
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Position = UDim2.fromScale(0.5, 0.5)
	dot.Size = UDim2.fromOffset(5, 5)
	dot.BackgroundColor3 = Color3.fromRGB(240, 250, 255)
	dot.BorderSizePixel = 0
	dot.Parent = ch
	local dcr = Instance.new("UICorner")
	dcr.CornerRadius = UDim.new(1, 0)
	dcr.Parent = dot
	local dst = Instance.new("UIStroke")
	dst.Color = Color3.fromRGB(12, 24, 38)
	dst.Thickness = 1.4
	dst.Parent = dot

	local ring = Instance.new("Frame")
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromScale(0.5, 0.5)
	ring.Size = UDim2.fromOffset(16, 16)
	ring.BackgroundTransparency = 1
	ring.Parent = ch
	local rcr = Instance.new("UICorner")
	rcr.CornerRadius = UDim.new(1, 0)
	rcr.Parent = ring
	local rst = Instance.new("UIStroke")
	rst.Color = Color3.fromRGB(110, 228, 255)
	rst.Transparency = 0.35
	rst.Thickness = 1.2
	rst.Parent = ring

	-- #88 Dynamic Controller Glyph Hint Strip (auto-shown only when Gamepad is active)
	local gp = Instance.new("Frame")
	gp.Name = "GamepadHintStrip"
	gp.AnchorPoint = Vector2.new(0.5, 0)
	gp.Position = UDim2.new(0.5, 0, 0, 14)
	gp.Size = UDim2.fromOffset(540, 24)
	gp.BackgroundColor3 = Color3.fromRGB(10, 16, 28)
	gp.BackgroundTransparency = 0.24
	gp.BorderSizePixel = 0
	gp.Visible = false
	gp.Parent = sg
	local gpcr = Instance.new("UICorner")
	gpcr.CornerRadius = UDim.new(0, 6)
	gpcr.Parent = gp
	local gpst = Instance.new("UIStroke")
	gpst.Color = Color3.fromRGB(82, 206, 255)
	gpst.Thickness = 1.1
	gpst.Parent = gp

	local gplbl = Instance.new("TextLabel")
	gplbl.Size = UDim2.fromScale(1, 1)
	gplbl.BackgroundTransparency = 1
	gplbl.Font = Enum.Font.GothamBold
	gplbl.TextSize = 11
	gplbl.TextColor3 = Color3.fromRGB(224, 244, 255)
	gplbl.Text = "[X] Attack   [Y] Heavy   [B] Dash   [LB/RB] Slot 1-4   [RT+XYBA] Z/X/C/V   [R3] Lock   [D-Down] Soru"
	gplbl.Parent = gp

	overlayGui = sg
	crosshairFrame = ch
	gamepadHintBar = gp
	return sg
end

-- ============================================================================
-- #76, #77, #78. CAMERA JUICE, SHIFT-LOCK OTS CAM & TARGET LOCK-ON [TAB]
-- ============================================================================
local camTrauma = 0
local camPunchVec = Vector3.zero
local camPunchVel = Vector3.zero
local currentDynamicFOV = 70
local ultZoomOffset = 0
local currentPullBack = 0
local currentHeightOff = Vector3.zero
local otsActive = false
local currentOtsOffset = Vector3.zero

local lockedTarget = nil
local lockReticleModel = nil

local function addCameraTrauma(amount, fovPunch, dirVec)
	if isLowFX() then return end
	camTrauma = math.clamp(camTrauma + (tonumber(amount) or 0.25), 0, 1.0)
	if fovPunch and fovPunch ~= 0 then
		ultZoomOffset = math.clamp(ultZoomOffset + fovPunch, -10, 12)
	end
	if typeof(dirVec) == "Vector3" and dirVec.Magnitude > 0.01 then
		camPunchVel += dirVec.Unit * math.clamp((tonumber(amount) or 0.25) * 4.5, 0.5, 3.5)
	end
end

cameraImpulseEvent.Event:Connect(addCameraTrauma)
player:GetAttributeChangedSignal("SkybreakTraumaPulse"):Connect(function()
	local t = tonumber(player:GetAttribute("SkybreakTraumaPulse")) or 0
	if t > 0 then
		local f = tonumber(player:GetAttribute("SkybreakFovPunch")) or 0
		addCameraTrauma(t, f)
	end
end)

local function getEnemyRoot(model)
	if not model or not model.Parent then return nil end
	if model:GetAttribute("EnemyDead") == true then return nil end
	local hp = tonumber(model:GetAttribute("HP"))
	if hp and hp <= 0 then return nil end
	local hum = model:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health <= 0 then return nil end
	return model:FindFirstChild("Body") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
end

local function getEnemyDisplayName(model)
	local id = tostring(model:GetAttribute("EnemyId") or model.Name)
	local cfg = Config and Config.Enemies and Config.Enemies[id]
	return (cfg and cfg.Name) or id
end

local function destroyLockReticle()
	if lockReticleModel then
		lockReticleModel:Destroy()
		lockReticleModel = nil
	end
end

local function ensureLockReticle()
	if lockReticleModel and lockReticleModel.Parent then return lockReticleModel end
	local m = Instance.new("Model")
	m.Name = "SkybreakDiamondLockReticle"

	local outerRing = makeFXPart("OuterRing", Enum.PartType.Cylinder, Vector3.new(0.14, 7.6, 7.6), CFrame.new(), Color3.fromRGB(82, 232, 255), 0.24, Enum.Material.ForceField, m)
	makeFXPart("InnerRing", Enum.PartType.Cylinder, Vector3.new(0.16, 4.8, 4.8), CFrame.new(), Color3.fromRGB(255, 212, 86), 0.22, Enum.Material.ForceField, m)
	m.PrimaryPart = outerRing

	-- 4 Rotating Golden-Cyan 3D Diamond Prisms
	for i = 1, 4 do
		makeFXPart(
			"Diamond" .. i,
			Enum.PartType.Block,
			Vector3.new(0.72, 0.72, 0.24),
			CFrame.new(),
			(i % 2 == 0) and Color3.fromRGB(82, 232, 255) or Color3.fromRGB(255, 212, 86),
			0.10,
			Enum.Material.SmoothPlastic,
			m
		)
	end

	local bill = Instance.new("BillboardGui")
	bill.Name = "LockBill"
	bill.Size = UDim2.fromOffset(220, 34)
	bill.StudsOffset = Vector3.new(0, 6.2, 0)
	bill.AlwaysOnTop = true
	bill.Parent = outerRing

	local lbl = Instance.new("TextLabel")
	lbl.Name = "TargetText"
	lbl.Size = UDim2.fromScale(1, 1)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 14
	lbl.TextColor3 = Color3.fromRGB(255, 218, 96)
	lbl.TextStrokeColor3 = Color3.fromRGB(10, 18, 30)
	lbl.TextStrokeTransparency = 0.2
	lbl.Text = "[LOCKED]"
	lbl.Parent = bill

	m.Parent = tempFX
	lockReticleModel = m
	return m
end

local function clearTargetLock(silent)
	lockedTarget = nil
	destroyLockReticle()
	if player.Character then
		player.Character:SetAttribute("LockTargetPos", nil)
	end
	player:SetAttribute("SkybreakLockedName", nil)
	if UI and type(UI.SetLockTarget) == "function" then
		pcall(UI.SetLockTarget, nil)
	end
	if not silent then
		toast("[LOCK] Target unlocked")
	end
end

local function toggleTargetLock()
	local ch = player.Character
	local r = ch and ch:FindFirstChild("HumanoidRootPart")
	if not r then return end

	local candidates = {}
	for priority, folderName in ipairs({ "ActiveBosses", "ActiveEnemies" }) do
		local f = Workspace:FindFirstChild(folderName)
		if f then
			for _, m in ipairs(f:GetChildren()) do
				if m:IsA("Model") and m.Name ~= "EnergyPylon" then
					local er = getEnemyRoot(m)
					if er then
						local dist = (er.Position - r.Position).Magnitude
						if dist <= 85 then
							table.insert(candidates, { Model = m, Dist = dist, Priority = priority })
						end
					end
				end
			end
		end
	end
	table.sort(candidates, function(a, b)
		if a.Priority ~= b.Priority then return a.Priority < b.Priority end
		return a.Dist < b.Dist
	end)

	if #candidates == 0 then
		clearTargetLock(true)
		toast("[LOCK] No enemy within 85 studs")
		return
	end

	if not lockedTarget then
		lockedTarget = candidates[1].Model
	else
		local idx = nil
		for i, c in ipairs(candidates) do
			if c.Model == lockedTarget then idx = i break end
		end
		if idx and idx < #candidates then
			lockedTarget = candidates[idx + 1].Model
		else
			clearTargetLock(false)
			return
		end
	end

	if lockedTarget then
		local name = getEnemyDisplayName(lockedTarget)
		player:SetAttribute("SkybreakLockedName", name)
		if UI and type(UI.SetLockTarget) == "function" then
			pcall(UI.SetLockTarget, name)
		end
		playSFX("ui_click", r.Position, 0.04)
		toast("[LOCK] Locked: " .. name)
	end
end

local function faceLockedTarget()
	if not lockedTarget then return false end
	local er = getEnemyRoot(lockedTarget)
	local ch = player.Character
	local r = ch and ch:FindFirstChild("HumanoidRootPart")
	if not er or not r then
		clearTargetLock(true)
		return false
	end
	local flat = Vector3.new(er.Position.X, r.Position.Y, er.Position.Z)
	if (flat - r.Position).Magnitude > 0.5 then
		r.CFrame = CFrame.lookAt(r.Position, flat)
	end
	return true
end

local function getTargetTransformPullback(ch)
	local tf = tostring((ch and ch:GetAttribute("FruitTransform")) or player:GetAttribute("FruitTransform") or "")
	local tier = tonumber((ch and ch:GetAttribute("DragonFormTier")) or player:GetAttribute("DragonFormTier")) or 0
	if tier >= 2 or tf == "AbyssalSovereign" or tf == "DragonFull" then
		return 18, Vector3.new(0, 5.2, 0)
	elseif tf == "SolarTitan" then
		return 14, Vector3.new(0, 4.8, 0)
	elseif tier == 1 or tf == "AbyssalDragonHybrid" or tf == "DragonHybrid" then
		return 9, Vector3.new(0, 2.2, 0)
	end
	return 0, Vector3.zero
end

-- ============================================================================
-- #81. 6-DOF 3D ELEMENTAL FREE FLIGHT [F] + 12 BESPOKE 3D FLIGHT CONSTRUCTS
-- ============================================================================
local flightActive = false
local flightHoldStartedAt = 0
local flightFKeyHeld = false
local flightFolder = nil
local flightAttachment = nil
local flightLV = nil
local flightAO = nil
local flightRigData = nil
local lastGroundedY = 40
local lastKnownRootPos = nil
local lastPathSpawnPos = Vector3.zero
local savedLimbTransparencies = {}

local function restoreFlightTransparencies(ch)
	for part, origT in pairs(savedLimbTransparencies) do
		if part and part.Parent then
			part.Transparency = origT
		end
	end
	table.clear(savedLimbTransparencies)
	if ch then
		ch:SetAttribute("SkybreakFlightActive", false)
	end
end

local function buildBespokeFlightRig(ch, root, fruitKey, spec)
	local folder = Instance.new("Folder")
	folder.Name = "Skybreak3DFlightRig"
	folder.Parent = tempFX
	local data = { Mode = spec.Mode, Parts = {}, SpinAngle = 0 }

	if spec.Mode == "LightBeam" then
		-- Pure Golden Photon Beam Body + Star Prism Fins
		for _, p in ipairs(ch:GetChildren()) do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" and p.Transparency < 0.55 then
				savedLimbTransparencies[p] = p.Transparency
				p.Transparency = 0.58
			end
		end
		data.Core = makeFXPart("PhotonBody", Enum.PartType.Ball, Vector3.new(2.4, 2.4, 5.6), root.CFrame, spec.Primary, 0.14, Enum.Material.Neon, folder)
		data.Halo = makeFXPart("PhotonHalo", Enum.PartType.Cylinder, Vector3.new(0.18, 5.4, 5.4), root.CFrame, spec.Secondary, 0.20, Enum.Material.Neon, folder)
		safeLight(data.Core, spec.Primary, 1.35, 15, 0)

	elseif spec.Mode == "FlameJets" then
		-- Dual Solar Rocket Thruster Cones at Feet/Back
		data.JetL = makeFXPart("FlameThrusterL", Enum.PartType.Cylinder, Vector3.new(4.2, 1.45, 1.45), root.CFrame, spec.Primary, 0.14, Enum.Material.Neon, folder)
		data.JetR = makeFXPart("FlameThrusterR", Enum.PartType.Cylinder, Vector3.new(4.2, 1.45, 1.45), root.CFrame, spec.Primary, 0.14, Enum.Material.Neon, folder)
		data.CoreL = makeFXPart("FlameCoreL", Enum.PartType.Cylinder, Vector3.new(3.2, 0.72, 0.72), root.CFrame, spec.Secondary, 0.08, Enum.Material.Neon, folder)
		data.CoreR = makeFXPart("FlameCoreR", Enum.PartType.Cylinder, Vector3.new(3.2, 0.72, 0.72), root.CFrame, spec.Secondary, 0.08, Enum.Material.Neon, folder)
		safeLight(data.JetL, spec.Primary, 1.25, 14, 0)

	elseif spec.Mode == "IceSkyBridge" then
		-- Frost Skates + Live Ice Crystal Sky-Bridge Tiles spawned under feet!
		data.Skate = makeFXPart("CryoGlidePad", Enum.PartType.Block, Vector3.new(3.4, 0.35, 4.8), root.CFrame, spec.Primary, 0.14, Enum.Material.Glass, folder)
		lastPathSpawnPos = root.Position - Vector3.new(0, 10, 0)

	elseif spec.Mode == "GravityBoulder" then
		-- Levitating Craggy Asteroid Platform + Orbiting Graviton Rings under feet
		data.BoulderMain = makeFXPart("AsteroidDeck", Enum.PartType.Block, Vector3.new(5.2, 1.4, 5.8), root.CFrame, Color3.fromRGB(68, 58, 86), 0.04, Enum.Material.Slate, folder)
		data.BoulderUnder = makeFXPart("AsteroidKeel", Enum.PartType.Wedge, Vector3.new(3.8, 1.8, 4.4), root.CFrame, Color3.fromRGB(52, 44, 68), 0.04, Enum.Material.Slate, folder)
		data.GravRing = makeFXPart("GravitonOrbit", Enum.PartType.Cylinder, Vector3.new(0.16, 7.6, 7.6), root.CFrame, spec.Primary, 0.20, Enum.Material.Neon, folder)
		safeLight(data.GravRing, spec.Primary, 1.2, 14, 0)

	elseif spec.Mode == "PortalRings" then
		data.Gate = makeFXPart("DimensionalHarness", Enum.PartType.Cylinder, Vector3.new(0.22, 5.8, 5.8), root.CFrame, spec.Primary, 0.16, Enum.Material.Neon, folder)
		lastPathSpawnPos = root.Position - Vector3.new(0, 10, 0)

	elseif spec.Mode == "MagmaHound" then
		-- Volcanic Hound Sled Construct beneath player
		data.Body = makeFXPart("MagmaHoundBody", Enum.PartType.Block, Vector3.new(3.2, 1.5, 5.6), root.CFrame, Color3.fromRGB(64, 26, 24), 0.06, Enum.Material.Slate, folder)
		data.Snout = makeFXPart("MagmaHoundHead", Enum.PartType.Wedge, Vector3.new(2.6, 1.6, 2.8), root.CFrame, spec.Primary, 0.08, Enum.Material.Neon, folder)
		data.Core = makeFXPart("MagmaGlow", Enum.PartType.Cylinder, Vector3.new(4.8, 2.0, 2.0), root.CFrame, spec.Secondary, 0.20, Enum.Material.Neon, folder)
		safeLight(data.Snout, spec.Primary, 1.25, 14, 0)

	elseif spec.Mode == "LightningForm" then
		data.Sphere = makeFXPart("VoltShroud", Enum.PartType.Ball, Vector3.new(5.2, 5.2, 5.2), root.CFrame, spec.Primary, 0.34, Enum.Material.Neon, folder)
		data.Bolts = {}
		for i = 1, 4 do
			data.Bolts[i] = makeFXPart("VoltArc_" .. i, Enum.PartType.Block, Vector3.new(0.24, 0.24, 4.4), root.CFrame, (i % 2 == 0) and spec.Secondary or spec.Primary, 0.10, Enum.Material.Neon, folder)
		end
		safeLight(data.Sphere, spec.Primary, 1.25, 14, 0)

	elseif spec.Mode == "WindCyclone" or spec.Mode == "SandWhirlwind" then
		data.Rings = {}
		for i = 1, 4 do
			local r = 2.4 + i * 1.1
			data.Rings[i] = makeFXPart("CycloneRing_" .. i, Enum.PartType.Cylinder, Vector3.new(0.22, r, r), root.CFrame, (i % 2 == 0) and spec.Primary or spec.Secondary, 0.22, Enum.Material.Neon, folder)
		end

	elseif spec.Mode == "DoughWheel" then
		-- Spinning Spiked Roller Donut Wheel around character
		data.Rim = makeFXPart("DoughDonutRim", Enum.PartType.Cylinder, Vector3.new(1.5, 6.8, 6.8), root.CFrame, spec.Primary, 0.08, Enum.Material.SmoothPlastic, folder)
		data.Spikes = {}
		for i = 1, 8 do
			data.Spikes[i] = makeFXPart("DoughSpike_" .. i, Enum.PartType.Wedge, Vector3.new(0.65, 1.25, 0.85), root.CFrame, spec.Secondary, 0.06, Enum.Material.Neon, folder)
		end

	elseif spec.Mode == "BuddhaLotus" then
		-- Radiant Golden Levitation Lotus Pedestal under feet
		data.Base = makeFXPart("LotusCore", Enum.PartType.Cylinder, Vector3.new(0.42, 4.6, 4.6), root.CFrame, spec.Primary, 0.10, Enum.Material.Neon, folder)
		data.Petals = {}
		for i = 1, 8 do
			data.Petals[i] = makeFXPart("LotusPetal_" .. i, Enum.PartType.Wedge, Vector3.new(1.35, 0.85, 2.2), root.CFrame, (i % 2 == 0) and spec.Primary or spec.Secondary, 0.12, Enum.Material.Neon, folder)
		end
		safeLight(data.Base, spec.Primary, 1.25, 14, 0)

	else
		-- DragonWings: Only spawn wedge wings in human form; when transformed into 3D Blender Hybrid/Sovereign Dragon, keep only sleek slipstream halo!
		local tf = tostring((ch and ch:GetAttribute("FruitTransform")) or player:GetAttribute("FruitTransform") or "")
		local tier = tonumber((ch and ch:GetAttribute("DragonFormTier")) or player:GetAttribute("DragonFormTier")) or 0
		local is3DDragonForm = (tier >= 1 or tf == "AbyssalSovereign" or tf == "AbyssalDragonHybrid" or tf == "DragonFull" or tf == "DragonHybrid")
		if not is3DDragonForm then
			data.WingL = makeFXPart("SoarWingL", Enum.PartType.Wedge, Vector3.new(0.24, 3.2, 7.6), root.CFrame, spec.Primary, 0.16, Enum.Material.Neon, folder)
			data.WingR = makeFXPart("SoarWingR", Enum.PartType.Wedge, Vector3.new(0.24, 3.2, 7.6), root.CFrame, spec.Primary, 0.16, Enum.Material.Neon, folder)
		else
			data.OuterHalo = makeFXPart("DragonSovereignMachHalo", Enum.PartType.Cylinder, Vector3.new(0.24, 9.6, 9.6), root.CFrame, spec.Primary, 0.22, Enum.Material.Neon, folder)
			lastPathSpawnPos = root.Position - Vector3.new(0, 20, 0)
		end
		data.Halo = makeFXPart("DragonSlipHalo", Enum.PartType.Cylinder, Vector3.new(0.20, 6.2, 6.2), root.CFrame, spec.Secondary, 0.26, Enum.Material.Neon, folder)
	end

	return folder, data
end

local function stopFreeFlight(silent)
	if not flightActive then return end
	flightActive = false
	flightFKeyHeld = false
	player:SetAttribute("SkybreakFlightActive", false)

	if flightLV then flightLV:Destroy() flightLV = nil end
	if flightAO then flightAO:Destroy() flightAO = nil end
	if flightAttachment then flightAttachment:Destroy() flightAttachment = nil end
	if flightFolder then flightFolder:Destroy() flightFolder = nil end
	flightRigData = nil

	local ch = player.Character
	restoreFlightTransparencies(ch)
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.PlatformStand = false
	end

	pcall(function()
		AbilityRequest:FireServer({ action = "FreeFlight", active = false })
	end)
	if not silent then
		playSFX("dodge_dash", ch and ch:GetPivot().Position or nil, 0.05)
	end
end

local function startFreeFlight()
	if flightActive or blocksCombat() then return end
	local ch = player.Character
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 then return end

	flightActive = true
	player:SetAttribute("SkybreakFlightActive", true)
	ch:SetAttribute("SkybreakFlightActive", true)

	local fruitKey = resolveEquippedFruitKey()
	local spec = FRUIT_SPECS[fruitKey] or FRUIT_SPECS.GaleCore

	flightAttachment = Instance.new("Attachment")
	flightAttachment.Name = "SkybreakFlightAtt"
	flightAttachment.Parent = root

	flightLV = Instance.new("LinearVelocity")
	flightLV.Name = "SkybreakFlightVelocity"
	flightLV.Attachment0 = flightAttachment
	flightLV.MaxForce = 1e6
	flightLV.RelativeTo = Enum.ActuatorRelativeTo.World
	flightLV.VectorVelocity = Workspace.CurrentCamera.CFrame.LookVector * (spec.Speed * 0.65)
	flightLV.Parent = root

	flightAO = Instance.new("AlignOrientation")
	flightAO.Name = "SkybreakFlightAlign"
	flightAO.Attachment0 = flightAttachment
	flightAO.Mode = Enum.OrientationAlignmentMode.OneAttachment
	flightAO.MaxTorque = 1e6
	flightAO.Responsiveness = 26
	flightAO.CFrame = Workspace.CurrentCamera.CFrame
	flightAO.Parent = root

	flightFolder, flightRigData = buildBespokeFlightRig(ch, root, fruitKey, spec)

	-- Launch Sonic Ring
	local ring = makeFXPart("FlightTakeoffRing", Enum.PartType.Cylinder, Vector3.new(0.28, 3.2, 3.2), root.CFrame * CFrame.Angles(0, math.pi * 0.5, 0), spec.Primary, 0.16, Enum.Material.ForceField)
	TweenService:Create(ring, TweenInfo.new(0.38, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.08, 12.5, 12.5),
		Transparency = 1,
	}):Play()
	Debris:AddItem(ring, 0.42)

	playSFX("flash_step", root.Position, 0.05)
	pcall(function()
		AbilityRequest:FireServer({ action = "FreeFlight", active = true, fruitId = fruitKey })
	end)
end

local function stepFreeFlight(dt)
	local ch = player.Character
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")

	-- Track teleports & last grounded deck Y
	if root and hum then
		if lastKnownRootPos and (root.Position - lastKnownRootPos).Magnitude > 65 then
			lastGroundedY = root.Position.Y
			if flightActive then
				lastKnownRootPos = root.Position
				stopFreeFlight(true)
				return
			end
		end
		lastKnownRootPos = root.Position
		local st = hum:GetState()
		if st == Enum.HumanoidStateType.Running or st == Enum.HumanoidStateType.Landed then
			lastGroundedY = root.Position.Y
		end
	end

	-- Auto-engage if server explicitly sets FreeFlightUntil
	local serverFlightUntil = tonumber((ch and ch:GetAttribute("FreeFlightUntil")) or player:GetAttribute("FreeFlightUntil")) or 0
	if not flightActive and not blocksCombat() and serverFlightUntil > Workspace:GetServerTimeNow() + 0.15 then
		startFreeFlight()
	end

	if not flightActive then return end
	if not root or not hum or hum.Health <= 0 or not flightLV or not flightAO or blocksCombat() or player:GetAttribute("SkybreakPhotoMode") == true then
		stopFreeFlight(true)
		return
	end

	local cam = Workspace.CurrentCamera
	if not cam then return end
	local fruitKey = resolveEquippedFruitKey()
	local spec = FRUIT_SPECS[fruitKey] or FRUIT_SPECS.GaleCore

	-- 6-DOF Camera-Steered Flight Vector (defaults to cruising forward along Camera LookVector!)
	local camCF = cam.CFrame
	local fwd = 0
	local right = 0
	local up = 0
	if not UserInputService:GetFocusedTextBox() then
		if UserInputService:IsKeyDown(Enum.KeyCode.W) then fwd += 1 end
		if UserInputService:IsKeyDown(Enum.KeyCode.S) then fwd -= 1 end
		if UserInputService:IsKeyDown(Enum.KeyCode.D) then right += 1 end
		if UserInputService:IsKeyDown(Enum.KeyCode.A) then right -= 1 end
		if UserInputService:IsKeyDown(Enum.KeyCode.E) then up += 0.75 end
		if UserInputService:IsKeyDown(Enum.KeyCode.Q) then up -= 0.75 end
	end
	if fwd == 0 and right == 0 and up == 0 then
		-- When holding [F] without WASD, cruise smoothly toward camera aim!
		fwd = 1
	end

	local wishVec = camCF.LookVector * fwd + camCF.RightVector * right + Vector3.new(0, up, 0)
	local targetVel = (wishVec.Magnitude > 0.05) and (wishVec.Unit * spec.Speed) or Vector3.zero

	-- Safe Void-Floor Clamping (prevents diving into server Y < 10 bottom abyss while allowing free descent from high islands)
	local minSafeY = 14
	if root.Position.Y <= minSafeY and targetVel.Y < 0 then
		targetVel = Vector3.new(targetVel.X, math.clamp((minSafeY - root.Position.Y) * 2.5, 2, 32), targetVel.Z)
	end

	flightLV.VectorVelocity = flightLV.VectorVelocity:Lerp(targetVel, math.clamp(dt * 10, 0, 1))
	local lookDir = (flightLV.VectorVelocity.Magnitude > 4) and flightLV.VectorVelocity.Unit or camCF.LookVector
	local bankAngle = -right * 0.34
	flightAO.CFrame = safeLookAt(root.Position, root.Position + lookDir, camCF.LookVector) * CFrame.Angles(0, 0, bankAngle)

	-- Animate 12 Bespoke 3D Elemental Flight Constructs
	if not flightRigData then return end
	local now = os.clock()
	local rCF = root.CFrame
	local mode = flightRigData.Mode

	if mode == "LightBeam" then
		if flightRigData.Core then flightRigData.Core.CFrame = rCF end
		if flightRigData.Halo then flightRigData.Halo.CFrame = rCF * CFrame.Angles(0, math.pi * 0.5, now * 10) end

	elseif mode == "FlameJets" then
		local lCF = rCF * CFrame.new(-0.85, -2.2, 1.8) * CFrame.Angles(0, math.pi * 0.5, 0)
		local rtCF = rCF * CFrame.new(0.85, -2.2, 1.8) * CFrame.Angles(0, math.pi * 0.5, 0)
		if flightRigData.JetL then flightRigData.JetL.CFrame = lCF end
		if flightRigData.JetR then flightRigData.JetR.CFrame = rtCF end
		if flightRigData.CoreL then flightRigData.CoreL.CFrame = lCF end
		if flightRigData.CoreR then flightRigData.CoreR.CFrame = rtCF end

	elseif mode == "IceSkyBridge" then
		local footCF = CFrame.lookAt(root.Position - Vector3.new(0, 3.05, 0), root.Position - Vector3.new(0, 3.05, 0) + Vector3.new(lookDir.X, 0, lookDir.Z) + Vector3.new(0, 0, 0.001))
		if flightRigData.Skate then flightRigData.Skate.CFrame = footCF end
		if (root.Position - lastPathSpawnPos).Magnitude >= 3.6 then
			lastPathSpawnPos = root.Position
			local tile = makeFXPart("IceSkyBridgeTile", Enum.PartType.Block, Vector3.new(4.4, 0.42, 4.6), rCF * CFrame.new(0, -3.25, 0), spec.Primary, 0.14, Enum.Material.Glass)
			TweenService:Create(tile, TweenInfo.new(1.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
				Size = Vector3.new(2.2, 0.12, 3.2),
				Transparency = 1,
			}):Play()
			Debris:AddItem(tile, 1.40)
		end

	elseif mode == "GravityBoulder" then
		local bCF = CFrame.new(root.Position - Vector3.new(0, 3.55, 0)) * CFrame.Angles(0, now * 0.7, 0)
		if flightRigData.BoulderMain then flightRigData.BoulderMain.CFrame = bCF end
		if flightRigData.BoulderUnder then flightRigData.BoulderUnder.CFrame = bCF * CFrame.new(0, -1.45, 0) * CFrame.Angles(math.pi, 0, 0) end
		if flightRigData.GravRing then flightRigData.GravRing.CFrame = bCF * CFrame.Angles(0.24, now * 2.8, math.pi * 0.5) end

	elseif mode == "PortalRings" then
		if flightRigData.Gate then flightRigData.Gate.CFrame = rCF * CFrame.Angles(0, math.pi * 0.5, now * 5) end
		if (root.Position - lastPathSpawnPos).Magnitude >= 11 then
			lastPathSpawnPos = root.Position
			local gate = makeFXPart("WarpFlightRing", Enum.PartType.Cylinder, Vector3.new(0.24, 7.6, 7.6), rCF * CFrame.new(0, 0, -4.5) * CFrame.Angles(0, math.pi * 0.5, 0), spec.Primary, 0.16, Enum.Material.ForceField)
			TweenService:Create(gate, TweenInfo.new(0.65, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = Vector3.new(0.08, 12.2, 12.2),
				Transparency = 1,
			}):Play()
			Debris:AddItem(gate, 0.70)
		end

	elseif mode == "MagmaHound" then
		local mCF = rCF * CFrame.new(0, -2.85, 0)
		if flightRigData.Body then flightRigData.Body.CFrame = mCF end
		if flightRigData.Snout then flightRigData.Snout.CFrame = mCF * CFrame.new(0, 0.55, -3.4) end
		if flightRigData.Core then flightRigData.Core.CFrame = mCF * CFrame.Angles(0, math.pi * 0.5, 0) end

	elseif mode == "LightningForm" then
		if flightRigData.Sphere then flightRigData.Sphere.CFrame = rCF end
		for i, b in ipairs(flightRigData.Bolts or {}) do
			local ang = now * 11 + i * 1.57
			b.CFrame = rCF * CFrame.new(math.cos(ang) * 2.3, math.sin(ang * 1.3) * 1.6, 0) * CFrame.Angles(ang, ang * 0.5, 0)
		end

	elseif mode == "WindCyclone" or mode == "SandWhirlwind" then
		for i, ring in ipairs(flightRigData.Rings or {}) do
			ring.CFrame = rCF * CFrame.new(0, -2.6 + i * 1.15, 0) * CFrame.Angles(0.18, now * (5 + i), math.pi * 0.5)
		end

	elseif mode == "DoughWheel" then
		flightRigData.SpinAngle += dt * 12
		local wCF = rCF * CFrame.Angles(0, math.pi * 0.5, 0) * CFrame.Angles(flightRigData.SpinAngle, 0, 0)
		if flightRigData.Rim then flightRigData.Rim.CFrame = wCF end
		for i, sp in ipairs(flightRigData.Spikes or {}) do
			local ang = (i - 1) * (math.pi * 0.25) + flightRigData.SpinAngle
			sp.CFrame = rCF * CFrame.new(0, math.sin(ang) * 3.8, -math.cos(ang) * 3.8) * CFrame.Angles(-ang, 0, 0)
		end

	elseif mode == "BuddhaLotus" then
		local lCF = CFrame.new(root.Position - Vector3.new(0, 3.25, 0))
		if flightRigData.Base then flightRigData.Base.CFrame = lCF * CFrame.Angles(0, now * 1.4, math.pi * 0.5) end
		for i, pet in ipairs(flightRigData.Petals or {}) do
			local ang = now * 1.4 + (i - 1) * (math.pi * 0.25)
			local pPos = lCF.Position + Vector3.new(math.cos(ang) * 2.5, 0.2, math.sin(ang) * 2.5)
			pet.CFrame = CFrame.lookAt(pPos, lCF.Position) * CFrame.Angles(-0.42, 0, 0)
		end

	else
		local flap = math.sin(now * 6.5) * 0.34
		if flightRigData.WingL then
			flightRigData.WingL.CFrame = rCF * CFrame.new(-3.4, 0.6, 0.8) * CFrame.Angles(0.1, -1.25, -0.22 - flap)
		end
		if flightRigData.WingR then
			flightRigData.WingR.CFrame = rCF * CFrame.new(3.4, 0.6, 0.8) * CFrame.Angles(0.1, 1.25, 0.22 + flap)
		end
		if flightRigData.Halo then
			flightRigData.Halo.CFrame = rCF * CFrame.new(0, 0, 2.2) * CFrame.Angles(0, math.pi * 0.5, now * 6)
		end
		if flightRigData.OuterHalo then
			flightRigData.OuterHalo.CFrame = rCF * CFrame.new(0, 0.8, 3.6) * CFrame.Angles(0, math.pi * 0.5, -now * 4.5)
			if (root.Position - lastPathSpawnPos).Magnitude >= 14 then
				lastPathSpawnPos = root.Position
				local wake = makeFXPart("DragonSonicWake", Enum.PartType.Cylinder, Vector3.new(0.22, 6.8, 6.8), rCF * CFrame.new(0, 0.6, 3.2) * CFrame.Angles(0, math.pi * 0.5, 0), spec.Primary, 0.18, Enum.Material.ForceField)
				TweenService:Create(wake, TweenInfo.new(0.46, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					Size = Vector3.new(0.06, 15.5, 15.5),
					Transparency = 1,
				}):Play()
				Debris:AddItem(wake, 0.50)
			end
		end
	end
end

-- ============================================================================
-- #82. FLASH STEP / SORU [R] (4.5s COOLDOWN, 36-STUD BLINK + 3 3D AFTERIMAGES)
-- ============================================================================
local FLASH_STEP_COOLDOWN = 4.5
local FLASH_STEP_RANGE = 36
local lastFlashStepAt = -10

local function spawnEnergyAfterimage(ch, worldCF, accentColor, delayFade)
	if not ch then return end
	local ghostModel = Instance.new("Model")
	ghostModel.Name = "SoruAfterimage"
	ghostModel.Parent = tempFX

	local root = ch:FindFirstChild("HumanoidRootPart")
	local refCF = root and root.CFrame or worldCF

	for _, part in ipairs(ch:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and part.Transparency < 0.9 then
			local rel = refCF:ToObjectSpace(part.CFrame)
			local g = Instance.new("Part")
			g.Name = "Ghost_" .. part.Name
			g.Size = part.Size * 0.98
			g.CFrame = worldCF * rel
			g.Color = accentColor
			g.Material = Enum.Material.ForceField
			g.Transparency = 0.34
			g.Anchored = true
			g.CanCollide = false
			g.CanQuery = false
			g.CanTouch = false
			g.CastShadow = false
			g.Parent = ghostModel
			TweenService:Create(g, TweenInfo.new(0.42 + (delayFade or 0), Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Transparency = 1,
				Size = part.Size * 1.06,
			}):Play()
		end
	end
	Debris:AddItem(ghostModel, 0.50 + (delayFade or 0))
end

local function performFlashStep()
	if blocksCombat() or UserInputService:GetFocusedTextBox() then return false end
	local now = os.clock()
	local rem = FLASH_STEP_COOLDOWN - (now - lastFlashStepAt)
	if rem > 0 then
		toast(string.format("Flash Step [R]: %.1fs", rem))
		return false
	end

	local ch = player.Character
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	local cam = Workspace.CurrentCamera
	if not root or not hum or hum.Health <= 0 or not cam then return false end

	if flightActive then
		stopFreeFlight(true)
	end

	lastFlashStepAt = now
	player:SetAttribute("FlashStepCooldownUntil", Workspace:GetServerTimeNow() + FLASH_STEP_COOLDOWN)

	local origin = root.Position
	local aimDir = cam.CFrame.LookVector
	-- Bias slightly upward if aiming nearly level on ground so Soru never clips floor seams
	if aimDir.Y > -0.22 and aimDir.Y < 0.08 then
		aimDir = Vector3.new(aimDir.X, 0.06, aimDir.Z).Unit
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { ch, tempFX }

	local hit = Workspace:Raycast(origin, aimDir * FLASH_STEP_RANGE, params)
	local dest = origin + aimDir * FLASH_STEP_RANGE
	if hit then
		dest = hit.Position - aimDir * 2.4 + hit.Normal * 1.2
	end

	-- Prevent blinking below bottom void abyss (Y < 14) while allowing downward blinks from elevated cliffs/islands
	local minSafeY = 14
	if dest.Y < minSafeY then
		local groundCheck = Workspace:Raycast(Vector3.new(dest.X, math.max(origin.Y, minSafeY) + 8, dest.Z), Vector3.new(0, -36, 0), params)
		if groundCheck and groundCheck.Position.Y >= 10 then
			dest = groundCheck.Position + Vector3.new(0, 3.1, 0)
		else
			dest = Vector3.new(dest.X, minSafeY, dest.Z)
		end
	end

	local cid = tostring(ch:GetAttribute("ClassId") or player:GetAttribute("ClassId") or "SkyGuardian")
	local accent = (cid == "ThunderStriker" and Color3.fromRGB(92, 232, 255))
		or (cid == "ArcaneMage" and Color3.fromRGB(184, 118, 255))
		or Color3.fromRGB(255, 216, 92)

	local flatDir = Vector3.new(dest.X - origin.X, 0, dest.Z - origin.Z)
	local flatAim = Vector3.new(aimDir.X, 0, aimDir.Z)
	local flatRoot = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	local faceVec = (flatDir.Magnitude > 0.2 and flatDir.Unit)
		or (flatAim.Magnitude > 0.05 and flatAim.Unit)
		or (flatRoot.Magnitude > 0.05 and flatRoot.Unit)
		or Vector3.new(0, 0, -1)
	local rotCF = safeLookAt(Vector3.zero, faceVec, Vector3.new(0, 0, -1))

	-- Spawn 3 Fading 3D Energy Afterimage Silhouettes along the blink path!
	for i = 1, 3 do
		local frac = (i - 1) / 3
		local ghostPos = origin:Lerp(dest, frac)
		spawnEnergyAfterimage(ch, CFrame.new(ghostPos) * rotCF.Rotation, accent, i * 0.06)
	end

	-- Departure & Arrival Aether/Thunder Snap Rings + Streak Line
	local dist = (dest - origin).Magnitude
	if dist > 2 then
		local streak = makeFXPart("SoruBolt", Enum.PartType.Cylinder, Vector3.new(dist, 0.85, 0.85), safeLookAt((origin + dest) * 0.5, dest, faceVec) * CFrame.Angles(0, math.pi * 0.5, 0), accent, 0.16, Enum.Material.ForceField)
		TweenService:Create(streak, TweenInfo.new(0.26, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = Vector3.new(dist, 0.08, 0.08),
			Transparency = 1,
		}):Play()
		Debris:AddItem(streak, 0.30)
	end

	local snapRing = makeFXPart("SoruArrivalSnap", Enum.PartType.Cylinder, Vector3.new(0.24, 2.4, 2.4), CFrame.new(dest) * rotCF.Rotation * CFrame.Angles(0, math.pi * 0.5, 0), accent, 0.14, Enum.Material.ForceField)
	safeLight(snapRing, accent, 1.25, 13, 0.26)
	TweenService:Create(snapRing, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.08, 9.6, 9.6),
		Transparency = 1,
	}):Play()
	Debris:AddItem(snapRing, 0.32)

	root.CFrame = CFrame.new(dest) * rotCF.Rotation
	root.AssemblyLinearVelocity = faceVec * 22 + Vector3.new(0, math.max(0, root.AssemblyLinearVelocity.Y * 0.25), 0)

	playSFX("flash_step", dest, 0.04)
	addCameraTrauma(0.26, 3.2, faceVec)
	pcall(function()
		AbilityRequest:FireServer({ action = "FlashStep", targetPos = dest })
	end)
	return true
end

-- ============================================================================
-- #83. AUTOMATIC LEDGE MANTLE / VAULT + HIGH-ALTITUDE SKYDIVE POSE
-- ============================================================================
local isMantling = false
local lastMantleAt = 0
local skydiveTimer = 0
local skydiveActive = false
local skydiveFolder = nil
local skydiveAO = nil
local skydiveAtt = nil
local skydiveAttachments = {}

local function stopSkydive(landedOnGround, landPos)
	if not skydiveActive then return end
	skydiveActive = false
	skydiveTimer = 0
	if skydiveAO then skydiveAO:Destroy() skydiveAO = nil end
	if skydiveAtt then skydiveAtt:Destroy() skydiveAtt = nil end
	if skydiveFolder then skydiveFolder:Destroy() skydiveFolder = nil end
	for _, att in ipairs(skydiveAttachments) do
		if att and att.Parent then att:Destroy() end
	end
	table.clear(skydiveAttachments)
	local ch = player.Character
	if ch then
		ch:SetAttribute("SkydiveActive", false)
	end
	if landedOnGround and typeof(landPos) == "Vector3" then
		local dust = makeFXPart("SkydiveLandingRing", Enum.PartType.Cylinder, Vector3.new(0.26, 3.2, 3.2), CFrame.new(landPos + Vector3.new(0, 0.18, 0)) * CFrame.Angles(0, 0, math.pi * 0.5), Color3.fromRGB(224, 234, 246), 0.22, Enum.Material.ForceField)
		TweenService:Create(dust, TweenInfo.new(0.45, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.08, 17.5, 17.5),
			Transparency = 1,
		}):Play()
		Debris:AddItem(dust, 0.50)
		playSFX("land_impact", landPos, 0.05)
		addCameraTrauma(0.42, -3.0, Vector3.new(0, -1, 0))
	end
end

local function startSkydive(ch, root)
	if skydiveActive then return end
	skydiveActive = true
	ch:SetAttribute("SkydiveActive", true)

	skydiveAtt = Instance.new("Attachment")
	skydiveAtt.Name = "SkydiveAtt"
	skydiveAtt.Parent = root

	skydiveAO = Instance.new("AlignOrientation")
	skydiveAO.Attachment0 = skydiveAtt
	skydiveAO.Mode = Enum.OrientationAlignmentMode.OneAttachment
	skydiveAO.MaxTorque = 8e5
	skydiveAO.Responsiveness = 18
	skydiveAO.Parent = root

	skydiveFolder = Instance.new("Folder")
	skydiveFolder.Name = "SkybreakSkydiveTrails"
	skydiveFolder.Parent = tempFX

	if not isLowFX() then
		for _, limbName in ipairs({ "RightHand", "LeftHand", "RightFoot", "LeftFoot", "Right Arm", "Left Arm" }) do
			local limb = ch:FindFirstChild(limbName)
			if limb and limb:IsA("BasePart") then
				local a0 = Instance.new("Attachment")
				a0.Position = Vector3.new(0, 0.18, 0)
				a0.Parent = limb
				local a1 = Instance.new("Attachment")
				a1.Position = Vector3.new(0, -0.18, 0)
				a1.Parent = limb
				local tr = Instance.new("Trail")
				tr.Attachment0 = a0
				tr.Attachment1 = a1
				tr.Lifetime = 0.28
				tr.FaceCamera = true
				tr.LightEmission = 0.55
				tr.Color = ColorSequence.new(Color3.fromRGB(205, 242, 255), Color3.fromRGB(122, 216, 255))
				tr.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.30),
					NumberSequenceKeypoint.new(1, 1),
				})
				tr.WidthScale = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(1, 0),
				})
				tr.Parent = skydiveFolder
				table.insert(skydiveAttachments, a0)
				table.insert(skydiveAttachments, a1)
			end
		end
	end
end

local function stepMantleAndSkydive(dt)
	local ch = player.Character
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 or flightActive or player:GetAttribute("SkybreakPhotoMode") == true then
		if skydiveActive then stopSkydive(false) end
		return
	end

	local st = hum:GetState()
	local airborne = (st == Enum.HumanoidStateType.Jumping or st == Enum.HumanoidStateType.Freefall)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { ch, tempFX }

	-- 1. Automatic Ledge Mantle / Vault
	local now = os.clock()
	if airborne and not isMantling and (now - lastMantleAt > 0.55) and hum.MoveDirection.Magnitude > 0.22 then
		local moveFlat = Vector3.new(hum.MoveDirection.X, 0, hum.MoveDirection.Z)
		if moveFlat.Magnitude > 0.1 then
			local fwd = moveFlat.Unit
			local wallHit = Workspace:Raycast(root.Position + Vector3.new(0, 0.4, 0), fwd * 3.1, params)
			if wallHit and wallHit.Instance and wallHit.Instance.CanCollide and math.abs(wallHit.Normal.Y) < 0.38 then
				local probeTop = root.Position + fwd * 2.25 + Vector3.new(0, 4.8, 0)
				local topHit = Workspace:Raycast(probeTop, Vector3.new(0, -5.2, 0), params)
				if topHit and topHit.Instance and topHit.Instance.CanCollide and topHit.Normal.Y > 0.65 then
					local ledgeY = topHit.Position.Y
					local climbDelta = ledgeY - (root.Position.Y - 2.8)
					if climbDelta >= 1.2 and climbDelta <= 6.8 then
						local destPos = topHit.Position + Vector3.new(0, 3.05, 0)
						local headroom = Workspace:Raycast(destPos - Vector3.new(0, 1.5, 0), Vector3.new(0, 4.2, 0), params)
						if not headroom then
							isMantling = true
							lastMantleAt = now
							stopSkydive(false)

							-- Wind Vault Puff Ring
							local puff = makeFXPart("MantleVaultPuff", Enum.PartType.Cylinder, Vector3.new(0.22, 2.2, 2.2), CFrame.new(topHit.Position + Vector3.new(0, 0.16, 0)) * CFrame.Angles(0, 0, math.pi * 0.5), Color3.fromRGB(192, 240, 255), 0.24, Enum.Material.ForceField)
							TweenService:Create(puff, TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
								Size = Vector3.new(0.06, 7.4, 7.4),
								Transparency = 1,
							}):Play()
							Debris:AddItem(puff, 0.36)
							playSFX("geppo_step", topHit.Position, 0.05)

							local startPos = root.Position
							local rot = CFrame.lookAt(Vector3.zero, fwd)
							task.spawn(function()
								local t0 = os.clock()
								local dur = 0.24
								while root and root.Parent and (os.clock() - t0) < dur do
									local a = math.clamp((os.clock() - t0) / dur, 0, 1)
									local ease = 1 - (1 - a) * (1 - a)
									local arcY = math.sin(a * math.pi) * 1.45
									local p = startPos:Lerp(destPos, ease) + Vector3.new(0, arcY, 0)
									root.CFrame = CFrame.new(p) * rot.Rotation
									root.AssemblyLinearVelocity = fwd * 14
									RunService.RenderStepped:Wait()
								end
								if root and root.Parent then
									root.CFrame = CFrame.new(destPos) * rot.Rotation
									root.AssemblyLinearVelocity = fwd * 16
								end
								isMantling = false
							end)
							return
						end
					end
				end
			end
		end
	end

	-- 2. High-Altitude Cloud Skydive Pose & Landing Shockwave
	local vel = root.AssemblyLinearVelocity
	if st == Enum.HumanoidStateType.Freefall and vel.Y < -58 and not isMantling then
		local groundProbe = Workspace:Raycast(root.Position, Vector3.new(0, -26, 0), params)
		if not groundProbe then
			skydiveTimer += dt
			if skydiveTimer >= 0.65 then
				startSkydive(ch, root)
			end
		elseif skydiveActive and groundProbe.Distance < 6.5 then
			stopSkydive(true, groundProbe.Position)
		end
	else
		if skydiveActive then
			local gHit = Workspace:Raycast(root.Position, Vector3.new(0, -6.5, 0), params)
			stopSkydive(gHit ~= nil, gHit and gHit.Position or (root.Position - Vector3.new(0, 2.8, 0)))
		end
		skydiveTimer = 0
	end

	if skydiveActive and skydiveAO then
		local cam = Workspace.CurrentCamera
		local flatLook = cam and Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z) or Vector3.new(0, 0, -1)
		local fwd = (flatLook.Magnitude > 0.05) and flatLook.Unit or Vector3.new(0, 0, -1)
		-- Pitch character forward into sleek aerodynamic dive angle (-62 deg)
		skydiveAO.CFrame = CFrame.lookAt(root.Position, root.Position + fwd) * CFrame.Angles(-1.08, 0, 0)
	end
end

-- ============================================================================
-- #89. RADIAL 6-SLICE EMOTES & MEDITATION WHEEL [B]
-- ============================================================================
local EMOTE_SLICES = {
	{ Id = "Meditate", Title = "1. Sit & Meditate", Sub = "Levitate + Chakra Ring", Color = Color3.fromRGB(92, 232, 255) },
	{ Id = "ConquerorFlex", Title = "2. Conqueror Flex", Sub = "Crimson Sovereign Aura", Color = Color3.fromRGB(238, 68, 88) },
	{ Id = "SwordSalute", Title = "3. Sword Salute", Sub = "Skyborn Honor Crest", Color = Color3.fromRGB(255, 212, 88) },
	{ Id = "VictoryFloat", Title = "4. Victory Levitation", Sub = "Astral Champion Halo", Color = Color3.fromRGB(184, 118, 255) },
	{ Id = "BattleTaunt", Title = "5. Battle Taunt", Sub = "Challenger Shock Ring", Color = Color3.fromRGB(255, 148, 62) },
	{ Id = "Cancel", Title = "6. Cancel", Sub = "Resume Combat Stance", Color = Color3.fromRGB(156, 174, 196) },
}

local emoteWheelGui = nil
local emoteWheelOpen = false
local activeEmoteId = nil
local activeEmoteFolder = nil
local savedEmoteJoints = {}
local savedEmoteHipHeight = nil

local function stopActiveEmote()
	if not activeEmoteId then return end
	activeEmoteId = nil
	if activeEmoteFolder then
		activeEmoteFolder:Destroy()
		activeEmoteFolder = nil
	end
	for motor, origC0 in pairs(savedEmoteJoints) do
		if motor and motor.Parent then
			TweenService:Create(motor, TweenInfo.new(0.18), { C0 = origC0 }):Play()
		end
	end
	table.clear(savedEmoteJoints)
	local ch = player.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if hum and savedEmoteHipHeight ~= nil then
		hum.HipHeight = savedEmoteHipHeight
	end
	savedEmoteHipHeight = nil
	if ch then ch:SetAttribute("ActiveEmote", nil) end
end

local function startEmote(emoteId)
	stopActiveEmote()
	if not emoteId or emoteId == "Cancel" then return end
	local ch = player.Character
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not ch or not root or not hum or hum.Health <= 0 or flightActive then return end

	activeEmoteId = emoteId
	ch:SetAttribute("ActiveEmote", emoteId)
	savedEmoteHipHeight = hum.HipHeight

	activeEmoteFolder = Instance.new("Folder")
	activeEmoteFolder.Name = "SkybreakEmoteFX"
	activeEmoteFolder.Parent = tempFX

	local function poseJoint(jointName, offsetCF)
		local m = ch:FindFirstChild(jointName, true)
		if m and m:IsA("Motor6D") then
			savedEmoteJoints[m] = m.C0
			TweenService:Create(m, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				C0 = m.C0 * offsetCF,
			}):Play()
		end
	end

	if emoteId == "Meditate" then
		hum.HipHeight = savedEmoteHipHeight + 1.15
		poseJoint("RightHip", CFrame.Angles(1.15, -0.45, 0.35))
		poseJoint("LeftHip", CFrame.Angles(1.15, 0.45, -0.35))
		poseJoint("RightShoulder", CFrame.Angles(0.55, 0, -0.38))
		poseJoint("LeftShoulder", CFrame.Angles(0.55, 0, 0.38))
		makeFXPart("ChakraOuter", Enum.PartType.Cylinder, Vector3.new(0.14, 6.6, 6.6), root.CFrame, Color3.fromRGB(92, 232, 255), 0.22, Enum.Material.ForceField, activeEmoteFolder)
		makeFXPart("ChakraInner", Enum.PartType.Cylinder, Vector3.new(0.16, 4.2, 4.2), root.CFrame, Color3.fromRGB(255, 214, 92), 0.22, Enum.Material.ForceField, activeEmoteFolder)
		playSFX("shrine_bless", root.Position, 0.03)

	elseif emoteId == "ConquerorFlex" then
		poseJoint("RightShoulder", CFrame.Angles(1.45, 0, 0.65))
		poseJoint("LeftShoulder", CFrame.Angles(1.45, 0, -0.65))
		makeFXPart("ConqEmoteAura", Enum.PartType.Cylinder, Vector3.new(0.18, 7.2, 7.2), root.CFrame, Color3.fromRGB(236, 58, 78), 0.22, Enum.Material.ForceField, activeEmoteFolder)
		playSFX("haki_conqueror", root.Position, 0.04)

	elseif emoteId == "SwordSalute" then
		poseJoint("RightShoulder", CFrame.Angles(1.62, -0.35, -0.22))
		poseJoint("LeftShoulder", CFrame.Angles(-0.25, 0, -0.18))
		makeFXPart("HonorCrest", Enum.PartType.Cylinder, Vector3.new(0.14, 5.4, 5.4), root.CFrame, Color3.fromRGB(255, 214, 88), 0.22, Enum.Material.ForceField, activeEmoteFolder)
		playSFX("skill_sky_slash", root.Position, 0.04)

	elseif emoteId == "VictoryFloat" then
		hum.HipHeight = savedEmoteHipHeight + 1.85
		poseJoint("RightShoulder", CFrame.Angles(2.45, 0, 0.28))
		poseJoint("LeftShoulder", CFrame.Angles(0.35, 0, -0.32))
		makeFXPart("VictoryHalo1", Enum.PartType.Cylinder, Vector3.new(0.14, 5.8, 5.8), root.CFrame, Color3.fromRGB(184, 118, 255), 0.22, Enum.Material.ForceField, activeEmoteFolder)
		makeFXPart("VictoryHalo2", Enum.PartType.Cylinder, Vector3.new(0.14, 5.8, 5.8), root.CFrame, Color3.fromRGB(255, 214, 92), 0.22, Enum.Material.ForceField, activeEmoteFolder)
		playSFX("level_up", root.Position, 0.03)

	elseif emoteId == "BattleTaunt" then
		poseJoint("RightShoulder", CFrame.Angles(1.38, 0.25, 0.15))
		makeFXPart("TauntRing", Enum.PartType.Cylinder, Vector3.new(0.18, 6.2, 6.2), root.CFrame, Color3.fromRGB(255, 146, 58), 0.22, Enum.Material.ForceField, activeEmoteFolder)
		playSFX("heavy_cleave", root.Position, 0.05)
	end
end

local function stepActiveEmote()
	if not activeEmoteId then return end
	local ch = player.Character
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not root or not hum or hum.Health <= 0 or hum.MoveDirection.Magnitude > 0.08 or flightActive then
		stopActiveEmote()
		return
	end
	local st = hum:GetState()
	if st == Enum.HumanoidStateType.Jumping or st == Enum.HumanoidStateType.Freefall then
		stopActiveEmote()
		return
	end
	if activeEmoteFolder then
		local now = os.clock()
		if activeEmoteId == "Meditate" or activeEmoteId == "VictoryFloat" then
			local base = (savedEmoteHipHeight or 2) + ((activeEmoteId == "VictoryFloat") and 1.85 or 1.15)
			hum.HipHeight = base + math.sin(now * 2.4) * 0.28
		end
		for idx, p in ipairs(activeEmoteFolder:GetChildren()) do
			if p:IsA("BasePart") then
				if activeEmoteId == "VictoryFloat" then
					p.CFrame = CFrame.new(root.Position) * CFrame.Angles(0.55 * (idx == 1 and 1 or -1), now * 2.4 * (idx == 1 and 1 or -1), math.pi * 0.5)
				else
					p.CFrame = CFrame.new(root.Position - Vector3.new(0, 2.35, 0)) * CFrame.Angles(0, now * (1.8 + idx * 0.7), math.pi * 0.5)
				end
			end
		end
	end
end

local function setEmoteWheelVisible(vis)
	local pgui = player:FindFirstChildOfClass("PlayerGui")
	if not pgui then return end
	if not emoteWheelGui or not emoteWheelGui.Parent then
		local sg = Instance.new("ScreenGui")
		sg.Name = "SkybreakEmoteWheelGui"
		sg.IgnoreGuiInset = true
		sg.ResetOnSpawn = false
		sg.DisplayOrder = 32
		sg.Enabled = false
		sg.Parent = pgui

		local center = Instance.new("Frame")
		center.Name = "WheelRoot"
		center.AnchorPoint = Vector2.new(0.5, 0.5)
		center.Position = UDim2.fromScale(0.5, 0.5)
		center.Size = UDim2.fromOffset(420, 420)
		center.BackgroundTransparency = 1
		center.Parent = sg

		local hub = Instance.new("Frame")
		hub.AnchorPoint = Vector2.new(0.5, 0.5)
		hub.Position = UDim2.fromScale(0.5, 0.5)
		hub.Size = UDim2.fromOffset(116, 116)
		hub.BackgroundColor3 = Color3.fromRGB(12, 18, 30)
		hub.BackgroundTransparency = 0.12
		hub.Parent = center
		local hcr = Instance.new("UICorner")
		hcr.CornerRadius = UDim.new(1, 0)
		hcr.Parent = hub
		local hst = Instance.new("UIStroke")
		hst.Color = Color3.fromRGB(98, 224, 255)
		hst.Thickness = 1.6
		hst.Parent = hub

		local hlbl = Instance.new("TextLabel")
		hlbl.Size = UDim2.fromScale(1, 1)
		hlbl.BackgroundTransparency = 1
		hlbl.Font = Enum.Font.GothamBold
		hlbl.TextSize = 12
		hlbl.TextColor3 = Color3.fromRGB(228, 246, 255)
		hlbl.Text = "EMOTES [B]\n1 - 6"
		hlbl.Parent = hub

		-- 6 Radial Slice Cards arranged at 60-degree intervals
		for i, item in ipairs(EMOTE_SLICES) do
			local ang = -math.pi * 0.5 + (i - 1) * (math.pi / 3)
			local rx = math.cos(ang) * 142
			local ry = math.sin(ang) * 134
			local btn = Instance.new("TextButton")
			btn.Name = "Slice_" .. i
			btn.AnchorPoint = Vector2.new(0.5, 0.5)
			btn.Position = UDim2.new(0.5, rx, 0.5, ry)
			btn.Size = UDim2.fromOffset(146, 56)
			btn.BackgroundColor3 = Color3.fromRGB(16, 24, 40)
			btn.BackgroundTransparency = 0.10
			btn.AutoButtonColor = true
			btn.Text = ""
			btn.Parent = center

			local bcr = Instance.new("UICorner")
			bcr.CornerRadius = UDim.new(0, 10)
			bcr.Parent = btn
			local bst = Instance.new("UIStroke")
			bst.Color = item.Color
			bst.Thickness = 1.5
			bst.Parent = btn

			local t1 = Instance.new("TextLabel")
			t1.Position = UDim2.fromOffset(8, 7)
			t1.Size = UDim2.new(1, -16, 0, 20)
			t1.BackgroundTransparency = 1
			t1.Font = Enum.Font.GothamBold
			t1.TextSize = 12
			t1.TextColor3 = Color3.fromRGB(244, 250, 255)
			t1.Text = item.Title
			t1.Parent = btn

			local t2 = Instance.new("TextLabel")
			t2.Position = UDim2.fromOffset(8, 28)
			t2.Size = UDim2.new(1, -16, 0, 18)
			t2.BackgroundTransparency = 1
			t2.Font = Enum.Font.Gotham
			t2.TextSize = 10
			t2.TextColor3 = item.Color
			t2.Text = item.Sub
			t2.Parent = btn

			btn.Activated:Connect(function()
				setEmoteWheelVisible(false)
				startEmote(item.Id)
			end)
		end

		emoteWheelGui = sg
	end

	emoteWheelOpen = vis
	emoteWheelGui.Enabled = vis
	if vis then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		playSFX("ui_click", nil, 0.04)
	end
end

-- ============================================================================
-- #97. CINEMATIC PHOTO MODE [F8] (FREE-CAM DRONE, RULE-OF-THIRDS, CLEAN HUD RESTORE)
-- ============================================================================
local photoModeActive = false
local photoSavedGuis = {}
local photoSavedWalkSpeed = nil
local photoSavedJumpPower = nil
local photoSavedJumpHeight = nil
local photoGui = nil
local photoGridFrame = nil
local photoHintLabel = nil
local photoShowGrid = true
local photoShowHint = true
local photoCamPos = Vector3.zero
local photoYaw = 0
local photoPitch = 0
local photoFOV = 68

local function ensurePhotoModeGui()
	local pgui = player:FindFirstChildOfClass("PlayerGui")
	if not pgui then return nil end
	if photoGui and photoGui.Parent then return photoGui end

	local sg = Instance.new("ScreenGui")
	sg.Name = "SkybreakPhotoModeGui"
	sg.IgnoreGuiInset = true
	sg.ResetOnSpawn = false
	sg.DisplayOrder = 95
	sg.Enabled = false
	sg.Parent = pgui

	local grid = Instance.new("Frame")
	grid.Name = "RuleOfThirds"
	grid.Size = UDim2.fromScale(1, 1)
	grid.BackgroundTransparency = 1
	grid.Parent = sg

	for _, frac in ipairs({ 1 / 3, 2 / 3 }) do
		local vLine = Instance.new("Frame")
		vLine.Position = UDim2.fromScale(frac, 0)
		vLine.Size = UDim2.new(0, 1, 1, 0)
		vLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		vLine.BackgroundTransparency = 0.72
		vLine.BorderSizePixel = 0
		vLine.Parent = grid

		local hLine = Instance.new("Frame")
		hLine.Position = UDim2.fromScale(0, frac)
		hLine.Size = UDim2.new(1, 0, 0, 1)
		hLine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		hLine.BackgroundTransparency = 0.72
		hLine.BorderSizePixel = 0
		hLine.Parent = grid
	end

	local hint = Instance.new("TextLabel")
	hint.Name = "PhotoHint"
	hint.AnchorPoint = Vector2.new(0.5, 1)
	hint.Position = UDim2.new(0.5, 0, 1, -18)
	hint.Size = UDim2.fromOffset(580, 26)
	hint.BackgroundColor3 = Color3.fromRGB(10, 14, 24)
	hint.BackgroundTransparency = 0.32
	hint.Font = Enum.Font.GothamBold
	hint.TextSize = 11
	hint.TextColor3 = Color3.fromRGB(232, 246, 255)
	hint.Text = "PHOTO MODE  |  WASD + E/Q Move   Mouse Look   Wheel Zoom   [G] Grid   [H] Clean Shot   [F8/Esc] Exit"
	hint.Parent = sg
	local cr = Instance.new("UICorner")
	cr.CornerRadius = UDim.new(0, 6)
	cr.Parent = hint

	photoGui = sg
	photoGridFrame = grid
	photoHintLabel = hint
	return sg
end

local function setPhotoMode(enable)
	if enable == photoModeActive then return end
	local cam = Workspace.CurrentCamera
	local pgui = player:FindFirstChildOfClass("PlayerGui")
	if not cam or not pgui then return end

	if enable then
		if flightActive then stopFreeFlight(true) end
		if emoteWheelOpen then setEmoteWheelVisible(false) end
		photoModeActive = true
		player:SetAttribute("SkybreakPhotoMode", true)

		-- Record ONLY currently-enabled ScreenGuis so exit restores exact prior state!
		table.clear(photoSavedGuis)
		local pGuiOverlay = ensurePhotoModeGui()
		for _, child in ipairs(pgui:GetChildren()) do
			if child:IsA("ScreenGui") and child ~= pGuiOverlay and child.Enabled then
				table.insert(photoSavedGuis, child)
				child.Enabled = false
			end
		end

		local ch = player.Character
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		if hum then
			photoSavedWalkSpeed = hum.WalkSpeed
			photoSavedJumpPower = hum.JumpPower
			photoSavedJumpHeight = hum.JumpHeight
			hum.WalkSpeed = 0
			hum.JumpPower = 0
			hum.JumpHeight = 0
		end

		photoCamPos = cam.CFrame.Position
		local rx, ry, _ = cam.CFrame:ToOrientation()
		photoPitch = rx
		photoYaw = ry
		photoFOV = cam.FieldOfView
		cam.CameraType = Enum.CameraType.Scriptable
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

		if pGuiOverlay then
			pGuiOverlay.Enabled = true
			photoGridFrame.Visible = photoShowGrid
			photoHintLabel.Visible = photoShowHint
		end
	else
		photoModeActive = false
		player:SetAttribute("SkybreakPhotoMode", false)

		if photoGui then photoGui.Enabled = false end
		for _, sg in ipairs(photoSavedGuis) do
			if sg and sg.Parent then
				sg.Enabled = true
			end
		end
		table.clear(photoSavedGuis)

		local ch = player.Character
		local hum = ch and ch:FindFirstChildOfClass("Humanoid")
		if hum then
			if photoSavedWalkSpeed ~= nil then hum.WalkSpeed = photoSavedWalkSpeed end
			if photoSavedJumpPower ~= nil then hum.JumpPower = photoSavedJumpPower end
			if photoSavedJumpHeight ~= nil then hum.JumpHeight = photoSavedJumpHeight end
		end
		photoSavedWalkSpeed = nil
		photoSavedJumpPower = nil
		photoSavedJumpHeight = nil

		cam.CameraType = Enum.CameraType.Custom
		cam.FieldOfView = 70
		UserInputService.MouseBehavior = otsActive and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
	end
end

-- ============================================================================
-- #88. FULL GAMEPAD SUPPORT & INPUT ROUTING ([F], [R], [B], [F8], [Tab], [LeftAlt])
-- ============================================================================
local gamepadR2Held = false

local function updateInputTypeGlyphs(lastType)
	ensureOverlayGui()
	if not gamepadHintBar then return end
	local isGP = (lastType == Enum.UserInputType.Gamepad1 or lastType == Enum.UserInputType.Gamepad2)
	gamepadHintBar.Visible = isGP and not photoModeActive
end

UserInputService.LastInputTypeChanged:Connect(updateInputTypeGlyphs)
task.defer(function()
	updateInputTypeGlyphs(UserInputService:GetLastInputType())
end)

local function cycleHotbarSlot(delta)
	local cur = tonumber(player:GetAttribute("ActiveSlot")) or 1
	local nxt = ((cur - 1 + delta) % 4) + 1
	EquipmentRequest:FireServer({ action = "SelectSlot", slot = nxt })
end

-- ============================================================================
-- VIEW LOCK & MOUSE LOCK FIX: PREVENT LEFTSHIFT DASH COLLISION & 1-KEY UNLOCK
-- Rebinds Roblox built-in ShiftLock from LeftShift -> RightControl so pressing
-- LeftShift to Dash NEVER traps the cursor or locks camera rotation.
-- ============================================================================
local robloxCameras = nil
local mouseLockBoundKeys = nil

local function forceReleaseRobloxShiftLock()
	pcall(function()
		local mlc = robloxCameras and robloxCameras.activeMouseLockController
		if mlc and type(mlc.GetIsMouseLocked) == "function" and mlc:GetIsMouseLocked() then
			if type(mlc.OnMouseLockToggled) == "function" then
				mlc:OnMouseLockToggled()
			end
		end
		if robloxCameras and robloxCameras.activeCameraController and type(robloxCameras.activeCameraController.SetIsMouseLocked) == "function" then
			robloxCameras.activeCameraController:SetIsMouseLocked(false)
		end
	end)
end

local function syncRobloxShiftLockBoundKeys()
	if not mouseLockBoundKeys then return end
	if player:GetAttribute("DisableCameraLock") == true then
		mouseLockBoundKeys.Value = ""
		forceReleaseRobloxShiftLock()
	else
		mouseLockBoundKeys.Value = "RightControl"
	end
end

task.spawn(function()
	local ps = player:WaitForChild("PlayerScripts", 10)
	local pmInst = ps and ps:WaitForChild("PlayerModule", 8)
	if pmInst then
		local camMod = pmInst:FindFirstChild("CameraModule")
		local mlc = camMod and camMod:FindFirstChild("MouseLockController")
		local boundKeys = mlc and mlc:FindFirstChild("BoundKeys")
		if boundKeys and boundKeys:IsA("StringValue") then
			mouseLockBoundKeys = boundKeys
		end
		pcall(function()
			local pm = require(pmInst)
			if pm and type(pm.GetCameras) == "function" then
				robloxCameras = pm:GetCameras()
			end
		end)
		syncRobloxShiftLockBoundKeys()
	end
end)

local function unlockAllViewAndMouseLocks(silent)
	if photoModeActive then
		setPhotoMode(false)
	end
	otsActive = false
	player:SetAttribute("SkybreakOTSActive", false)
	if crosshairFrame then
		crosshairFrame.Visible = false
	end
	clearTargetLock(true)
	forceReleaseRobloxShiftLock()
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
	local cam = Workspace.CurrentCamera
	if cam and cam.CameraType == Enum.CameraType.Scriptable and not flightActive and not blocksCombat() then
		cam.CameraType = Enum.CameraType.Custom
	end
	if not silent then
		toast("[CAM] Đã TẮT Khóa Góc Nhìn & Mở Khóa Chuột tự do!")
	end
end

UserInputService.InputBegan:Connect(function(input, processed)
	if UserInputService:GetFocusedTextBox() then return end
	local kc = input.KeyCode
	local ut = input.UserInputType

	-- Instant Universal Unlock ([LeftControl], [Shift + Tab], or [RightControl] when OTS/DisableCameraLock is active)
	if kc == Enum.KeyCode.LeftControl then
		unlockAllViewAndMouseLocks(false)
		return
	end
	if kc == Enum.KeyCode.RightControl and (player:GetAttribute("DisableCameraLock") == true or otsActive) then
		unlockAllViewAndMouseLocks(false)
		return
	end
	if kc == Enum.KeyCode.Tab and (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)) then
		unlockAllViewAndMouseLocks(false)
		return
	end

	-- #97 Cinematic Photo Mode [F8] & Photo Controls
	if kc == Enum.KeyCode.F8 then
		setPhotoMode(not photoModeActive)
		return
	end
	if photoModeActive then
		if kc == Enum.KeyCode.Escape then
			setPhotoMode(false)
		elseif kc == Enum.KeyCode.G then
			photoShowGrid = not photoShowGrid
			if photoGridFrame then photoGridFrame.Visible = photoShowGrid end
		elseif kc == Enum.KeyCode.H then
			photoShowHint = not photoShowHint
			if photoHintLabel then photoHintLabel.Visible = photoShowHint end
		end
		return
	end

	-- #77 Shift-Lock Over-The-Shoulder Action Cam ([LeftAlt] or [MouseButton3])
	if kc == Enum.KeyCode.LeftAlt or ut == Enum.UserInputType.MouseButton3 then
		if player:GetAttribute("DisableCameraLock") == true and not otsActive then
			unlockAllViewAndMouseLocks(true)
			toast("[CAM] Đang bật 'Tắt Khóa Góc Nhìn' trong Cài Đặt [O]")
			return
		end
		otsActive = not otsActive
		player:SetAttribute("SkybreakOTSActive", otsActive)
		ensureOverlayGui()
		local hasHudReticle = player:FindFirstChild("PlayerGui")
			and player.PlayerGui:FindFirstChild("SkybreakUI")
			and player.PlayerGui.SkybreakUI:FindFirstChild("CenterAimReticle", true) ~= nil
		if crosshairFrame then crosshairFrame.Visible = otsActive and not hasHudReticle end
		if not otsActive then
			forceReleaseRobloxShiftLock()
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			UserInputService.MouseIconEnabled = true
		end
		toast(otsActive and "[CAM] Khóa Góc Nhìn Action Cam: BẬT (Nhấn LeftCtrl để mở khóa)" or "[CAM] Khóa Góc Nhìn Action Cam: TẮT")
		return
	end

	-- #89 Emotes & Meditation Wheel [B] (plus 1-6 quick-pick while open)
	if kc == Enum.KeyCode.B and not processed then
		if not blocksCombat() or emoteWheelOpen then
			setEmoteWheelVisible(not emoteWheelOpen)
			return
		end
	end
	if emoteWheelOpen then
		local numMap = {
			[Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3,
			[Enum.KeyCode.Four] = 4, [Enum.KeyCode.Five] = 5, [Enum.KeyCode.Six] = 6,
		}
		if numMap[kc] and EMOTE_SLICES[numMap[kc]] then
			setEmoteWheelVisible(false)
			startEmote(EMOTE_SLICES[numMap[kc]].Id)
			return
		elseif kc == Enum.KeyCode.Escape then
			setEmoteWheelVisible(false)
			return
		end
	end

	-- Flight Clean Exit on Space or M1 Attack
	if flightActive and (kc == Enum.KeyCode.Space or ut == Enum.UserInputType.MouseButton1 or kc == Enum.KeyCode.ButtonA or kc == Enum.KeyCode.ButtonX) then
		stopFreeFlight(false)
	end

	-- Cancel Emote immediately on any attack key
	if activeEmoteId and (ut == Enum.UserInputType.MouseButton1 or kc == Enum.KeyCode.Z or kc == Enum.KeyCode.X or kc == Enum.KeyCode.C or kc == Enum.KeyCode.V) then
		stopActiveEmote()
	end

	-- #81 [F] 3D Free Flight (Hold [F] on any slot or press/hold [F] on sustained-flight Slot 2 Fruits; Shift+F ignored so Forge UI works)
	if kc == Enum.KeyCode.F and not (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)) then
		if not blocksCombat() then
			if flightActive then
				stopFreeFlight(false)
				return
			end
			flightFKeyHeld = true
			flightHoldStartedAt = os.clock()
			local activeSlot = tonumber(player:GetAttribute("ActiveSlot")) or 1
			local fruitKey = resolveEquippedFruitKey()
			local INSTANT_F_SKILL_FRUITS = {
				ThunderRumbleCore = true,
				DimensionalPortalCore = true,
				GlacierIceCore = true,
				SweetDoughCore = true,
				SolarTitanCore = true,
			}
			if activeSlot == 2 and not INSTANT_F_SKILL_FRUITS[fruitKey] then
				-- Check Mastery requirement for F move before engaging instant Slot 2 flight
				local reqMastery = 10
				local styles = Config and Config.CombatStyles
				local styleDef = styles and styles[fruitKey]
				if styleDef and type(styleDef.Moves) == "table" and type(styleDef.Moves.F) == "table" then
					reqMastery = tonumber(styleDef.Moves.F.Mastery) or 10
				end
				local curMastery = tonumber(player:GetAttribute("FruitMastery_" .. tostring(fruitKey)))
					or tonumber(player:GetAttribute("FruitMastery"))
					or tonumber(player:GetAttribute("StyleMastery"))
					or 1
				if curMastery >= reqMastery then
					task.delay(0.08, function()
						if not flightActive and not blocksCombat() then
							startFreeFlight()
						end
					end)
				end
			else
				task.delay(0.30, function()
					if flightFKeyHeld and not flightActive and not blocksCombat() then
						startFreeFlight()
					end
				end)
			end
		end
	end

	-- #88 Gamepad Combat, Traversal & Skill Chord Bindings
	if kc == Enum.KeyCode.ButtonR2 then
		gamepadR2Held = true
		return
	end
	if blocksCombat() then return end

	if kc == Enum.KeyCode.ButtonR3 then
		toggleTargetLock()
	elseif kc == Enum.KeyCode.ButtonR1 then
		cycleHotbarSlot(1)
	elseif kc == Enum.KeyCode.ButtonL1 then
		cycleHotbarSlot(-1)
	elseif kc == Enum.KeyCode.DPadDown then
		performFlashStep()
	elseif kc == Enum.KeyCode.DPadLeft then
		EquipmentRequest:FireServer({ action = "ToggleAura" })
	elseif kc == Enum.KeyCode.DPadRight then
		EquipmentRequest:FireServer({ action = "ToggleInstinct" })
	elseif kc == Enum.KeyCode.DPadUp then
		if flightActive then stopFreeFlight(false) else startFreeFlight() end
	elseif gamepadR2Held then
		-- R2 + Face Buttons = Skill Moves [Z] [X] [C] [V]
		if kc == Enum.KeyCode.ButtonX then
			faceLockedTarget()
			AbilityRequest:FireServer({ action = "SlotMove", key = "Z" })
		elseif kc == Enum.KeyCode.ButtonY then
			faceLockedTarget()
			AbilityRequest:FireServer({ action = "SlotMove", key = "X" })
		elseif kc == Enum.KeyCode.ButtonB then
			faceLockedTarget()
			AbilityRequest:FireServer({ action = "SlotMove", key = "C" })
		elseif kc == Enum.KeyCode.ButtonA then
			faceLockedTarget()
			AbilityRequest:FireServer({ action = "SlotMove", key = "V" })
		end
	else
		if kc == Enum.KeyCode.ButtonX then
			stopActiveEmote()
			faceLockedTarget()
			CombatRequest:FireServer({ action = "Attack" })
		elseif kc == Enum.KeyCode.ButtonY then
			stopActiveEmote()
			faceLockedTarget()
			CombatRequest:FireServer({ action = "Heavy" })
		elseif kc == Enum.KeyCode.ButtonB and not processed then
			stopActiveEmote()
			local ch = player.Character
			local hum = ch and ch:FindFirstChildOfClass("Humanoid")
			local r = ch and ch:FindFirstChild("HumanoidRootPart")
			local dir = (hum and hum.MoveDirection.Magnitude > 0.05 and hum.MoveDirection.Unit) or (r and r.CFrame.LookVector) or Vector3.new(0, 0, -1)
			CombatRequest:FireServer({ action = "Dash", direction = dir })
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.ButtonR2 then
		gamepadR2Held = false
	elseif input.KeyCode == Enum.KeyCode.F then
		local heldDur = os.clock() - flightHoldStartedAt
		flightFKeyHeld = false
		-- If player held [F] (> 0.28s) for continuous hold-flight, releasing [F] exits flight cleanly;
		-- quick tap (< 0.28s) on Slot 2 toggles cruise flight until [F]/Space/M1!
		if flightActive and heldDur >= 0.28 then
			stopFreeFlight(false)
		end
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not photoModeActive then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		photoYaw -= input.Delta.X * 0.0032
		photoPitch = math.clamp(photoPitch - input.Delta.Y * 0.0032, -1.48, 1.48)
	elseif input.UserInputType == Enum.UserInputType.MouseWheel then
		photoFOV = math.clamp(photoFOV - input.Position.Z * 4.5, 25, 95)
	end
end)

-- Listen to CombatFX for Ultimate Zoom-Punch (#76)
CombatFX.OnClientEvent:Connect(function(fx)
	if type(fx) ~= "table" then return end
	local actorId = fx.Actor or fx.Owner or fx.userId
	if actorId ~= player.UserId then return end
	local key = tostring(fx.key or fx.MoveKey or ""):upper()
	local act = tostring(fx.Action or fx.action or fx.skillId or "")
	if key == "V" or act:find("Aegis") or act:find("Cataclysm") or act:find("Judgement") or act:find("Sovereign") or act:find("Conqueror") then
		-- Brief Ultimate Zoom-In -> Punch-Out -> Settle
		ultZoomOffset = -6.5
		task.delay(0.11, function()
			addCameraTrauma(0.55, 11.5)
		end)
	end
end)

-- Command bridge for ClientBootstrap & Settings UI (ToggleLock, UnlockAllCamera, FaceLockedTarget, FlashStep, StartFlight, StopFlight)
commandEvent.Event:Connect(function(cmd)
	if cmd == "ToggleLock" then
		toggleTargetLock()
	elseif cmd == "UnlockAllCamera" or cmd == "ClearAllLocks" then
		unlockAllViewAndMouseLocks(false)
	elseif cmd == "FaceLockedTarget" then
		faceLockedTarget()
	elseif cmd == "FlashStep" then
		performFlashStep()
	elseif cmd == "StartFlight" then
		startFreeFlight()
	elseif cmd == "StopFlight" then
		stopFreeFlight(false)
	end
end)

player:GetAttributeChangedSignal("DisableCameraLock"):Connect(function()
	syncRobloxShiftLockBoundKeys()
	if player:GetAttribute("DisableCameraLock") == true then
		unlockAllViewAndMouseLocks(true)
	end
end)

-- ============================================================================
-- MASTER CAMERA & TRAVERSAL RENDERSTEPPED PIPELINE (Camera.Value + 5)
-- ============================================================================
RunService:BindToRenderStep("SkybreakCombatCamera", Enum.RenderPriority.Camera.Value + 5, function(dt)
	local cam = Workspace.CurrentCamera
	if not cam then return end

	-- 1. Photo Mode Free-Cam Drone Override (#97)
	if photoModeActive then
		cam.CameraType = Enum.CameraType.Scriptable
		local rotCF = CFrame.fromOrientation(photoPitch, photoYaw, 0)
		local move = Vector3.zero
		if not UserInputService:GetFocusedTextBox() then
			if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += rotCF.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= rotCF.LookVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += rotCF.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= rotCF.RightVector end
			if UserInputService:IsKeyDown(Enum.KeyCode.E) then move += Vector3.new(0, 1, 0) end
			if UserInputService:IsKeyDown(Enum.KeyCode.Q) then move -= Vector3.new(0, 1, 0) end
		end
		local speed = (UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)) and 78 or 34
		if move.Magnitude > 0.01 then
			photoCamPos += move.Unit * speed * dt
		end
		cam.CFrame = CFrame.new(photoCamPos) * rotCF
		cam.FieldOfView = cam.FieldOfView + (photoFOV - cam.FieldOfView) * math.clamp(dt * 12, 0, 1)
		return
	end

	-- 2. Step Traversal Systems (#81 Flight, #83 Mantle/Skydive, #89 Emotes)
	stepFreeFlight(dt)
	stepMantleAndSkydive(dt)
	stepActiveEmote()

	local ch = player.Character
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if not ch or not root or not hum then return end

	-- 3. Update #78 Target Lock-On 3D Diamond Reticle + Head Look-At Attribute + Soft Camera Midpoint Bias
	local lockWorldPos = nil
	if lockedTarget then
		local er = getEnemyRoot(lockedTarget)
		if not er or (er.Position - root.Position).Magnitude > 85 then
			clearTargetLock(true)
		else
			lockWorldPos = er.Position
			ch:SetAttribute("LockTargetPos", lockWorldPos)
			local ret = ensureLockReticle()
			local floorY = tonumber(lockedTarget:GetAttribute("EnemyFloorY")) or (er.Position.Y - 2.5)
			local basePos = Vector3.new(er.Position.X, floorY + 0.16, er.Position.Z)
			local t = os.clock()
			local outer = ret:FindFirstChild("OuterRing")
			local inner = ret:FindFirstChild("InnerRing")
			if outer then
				outer.CFrame = CFrame.new(basePos) * CFrame.Angles(0, t * 2.1, math.pi * 0.5)
				local bill = outer:FindFirstChild("LockBill")
				local lbl = bill and bill:FindFirstChild("TargetText")
				if lbl then lbl.Text = "[LOCKED] " .. getEnemyDisplayName(lockedTarget) end
			end
			if inner then
				inner.CFrame = CFrame.new(basePos + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, -t * 3.0, math.pi * 0.5)
			end
			for i = 1, 4 do
				local d = ret:FindFirstChild("Diamond" .. i)
				if d then
					local ang = t * 2.5 + (i - 1) * (math.pi * 0.5)
					local rad = 4.3 + math.sin(t * 5.2) * 0.3
					local dp = er.Position + Vector3.new(math.cos(ang) * rad, math.sin(t * 4 + i) * 0.25, math.sin(ang) * rad)
					d.CFrame = CFrame.lookAt(dp, er.Position) * CFrame.Angles(0, 0, math.pi * 0.25)
				end
			end
		end
	else
		if ch:GetAttribute("LockTargetPos") ~= nil then
			ch:SetAttribute("LockTargetPos", nil)
		end
	end

	-- 4. #77 Over-The-Shoulder Shift-Lock Offset & Character Root Yaw Alignment
	local camLockDisabled = (player:GetAttribute("DisableCameraLock") == true)
	local uiBlocking = blocksCombat() or emoteWheelOpen
	if camLockDisabled and otsActive then
		otsActive = false
		player:SetAttribute("SkybreakOTSActive", false)
		forceReleaseRobloxShiftLock()
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
	if uiBlocking then
		forceReleaseRobloxShiftLock()
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end
	local allowOtsLock = otsActive and not camLockDisabled and not uiBlocking and cam.CameraType ~= Enum.CameraType.Scriptable
	if otsActive and not uiBlocking then
		UserInputService.MouseBehavior = allowOtsLock and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
	end
	if crosshairFrame then
		crosshairFrame.Visible = allowOtsLock
	end

	-- Yield CFrame/FOV control cleanly to Scriptable cameras (e.g. MainMenu orbital diorama)
	if cam.CameraType == Enum.CameraType.Scriptable then
		return
	end

	local targetOts = allowOtsLock and Vector3.new(2.4, 0.8, 0) or Vector3.zero
	currentOtsOffset = currentOtsOffset:Lerp(targetOts, math.clamp(dt * 12, 0, 1))

	if allowOtsLock and not flightActive and not skydiveActive and not isMantling and hum.Health > 0 then
		local flatCam = Vector3.new(cam.CFrame.LookVector.X, 0, cam.CFrame.LookVector.Z)
		if flatCam.Magnitude > 0.05 then
			local targetRot = CFrame.lookAt(root.Position, root.Position + flatCam.Unit)
			root.CFrame = root.CFrame:Lerp(targetRot, math.clamp(dt * 18, 0, 1))
		end
	end

	-- 5. #76 Beast Transformation Smooth Pull-Back (+14 Buddha, +9 Hybrid Dragon, +18 Full Sovereign Dragon)
	local targetPull, targetHeight = getTargetTransformPullback(ch)
	currentPullBack += (targetPull - currentPullBack) * math.clamp(dt * 7, 0, 1)
	currentHeightOff = currentHeightOff:Lerp(targetHeight, math.clamp(dt * 7, 0, 1))
	hum.CameraOffset = currentHeightOff + currentOtsOffset

	if currentPullBack > 0.25 then
		local focusPos = root.Position + currentHeightOff
		local camVec = cam.CFrame.Position - focusPos
		local minDist = 12 + currentPullBack
		if camVec.Magnitude > 0.1 and camVec.Magnitude < minDist then
			cam.CFrame = CFrame.new(focusPos + camVec.Unit * minDist) * cam.CFrame.Rotation
		end
	end

	-- Gentle additive Lock-On Camera Midpoint Bias (skipped when DisableCameraLock is enabled)
	if lockWorldPos and not allowOtsLock and not camLockDisabled then
		local midPoint = root.Position:Lerp(lockWorldPos, 0.36) + Vector3.new(0, 1.4, 0)
		local toMid = midPoint - cam.CFrame.Position
		if toMid.Magnitude > 2 then
			local desiredCF = CFrame.lookAt(cam.CFrame.Position, midPoint)
			cam.CFrame = cam.CFrame:Lerp(desiredCF, math.clamp(dt * 2.4, 0, 0.06))
		end
	end

	-- 6. #76 Velocity-Based Sprint/Flight FOV Warp (70 -> 82) + Ultimate Zoom-Punch
	local speed = root.AssemblyLinearVelocity.Magnitude
	local speedAlpha = math.clamp((speed - 22) / 78, 0, 1)
	local targetFOV = 70 + speedAlpha * 12 + ultZoomOffset
	ultZoomOffset += (0 - ultZoomOffset) * math.clamp(dt * 7.5, 0, 1)
	currentDynamicFOV += (targetFOV - currentDynamicFOV) * math.clamp(dt * 9, 0, 1)
	cam.FieldOfView = math.clamp(currentDynamicFOV, 58, 92)

	-- 7. #76 Spring-Damped Trauma Shake (trauma^2 + directional punch, strictly additive!)
	if camTrauma > 0.001 or camPunchVec.Magnitude > 0.001 then
		local shakeMag = camTrauma * camTrauma
		camTrauma = math.max(0, camTrauma - dt * 2.35)

		-- Underdamped spring for directional hit punch
		local springForce = -camPunchVec * 145 - camPunchVel * 18
		camPunchVel += springForce * dt
		camPunchVec += camPunchVel * dt

		local t = os.clock() * 34
		local nx = (math.sin(t * 1.13) + math.cos(t * 1.79) * 0.5) * 0.42 * shakeMag
		local ny = (math.cos(t * 1.31) + math.sin(t * 2.07) * 0.5) * 0.36 * shakeMag
		local roll = math.sin(t * 1.53) * 0.022 * shakeMag

		cam.CFrame = cam.CFrame * CFrame.new(nx + camPunchVec.X * 0.14, ny + camPunchVec.Y * 0.14, camPunchVec.Z * 0.14) * CFrame.Angles(0, 0, roll)
	end
end)

player.CharacterRemoving:Connect(function(ch)
	if photoModeActive then setPhotoMode(false) end
	if emoteWheelOpen then setEmoteWheelVisible(false) end
	isMantling = false
	lastKnownRootPos = nil
	stopFreeFlight(true)
	stopSkydive(false)
	stopActiveEmote()
	clearTargetLock(true)
end)

player.CharacterAdded:Connect(function(ch)
	isMantling = false
	lastKnownRootPos = nil
	local root = ch:WaitForChild("HumanoidRootPart", 5)
	if root then
		lastGroundedY = root.Position.Y
		lastKnownRootPos = root.Position
	end
end)
