--!nonstrict
-- ============================================================================
-- SKYBREAK: CLIENT COMBAT VFX, HAKI, DRAGON FORMS & POOLED DAMAGE ENGINE
-- Owned by Wave 2 Client VFX Module (SkybreakClientVFX.lua)
-- Tasks: #12 (60 Bespoke Fruit VFX + 6 Katas + Awakened V2), #19 (Haki Visuals),
--        #32 (Logia Elemental Reflex), #43 (Dragon Hybrid/Full Sovereign + Fury HUD),
--        #68 (Hit-Stop, Knockback Trails & Impact Polish), #95 (40-Node Pooled Damage),
--        #122 (Enemy Hit-Flash & Aether Dissolve Death VFX)
-- Strict Anti-Glare Budget: PointLight.Brightness <= 1.45, Range <= 16,
--                           ParticleEmitter.LightEmission <= 0.78
-- ============================================================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local DragonSovereignVFX = require(script.Parent:WaitForChild("SkybreakClient"):WaitForChild("DragonSovereignVFX"))
local VFXStudioLibrary = require(script.Parent:WaitForChild("SkybreakClient"):WaitForChild("VFXStudioLibrary"))
local UniversalVFXOverhaul = require(script.Parent:WaitForChild("SkybreakClient"):WaitForChild("UniversalVFXOverhaul"))

local SkybreakClientVFX = {}
SkybreakClientVFX.__index = SkybreakClientVFX

local initialized = false
local localPlayer = Players.LocalPlayer
local Config = nil
local Remotes = nil
local UI = nil
local Audio = nil
local tempFX = nil

local activeConnections = {}
local charConnections = {}
local enemyConnections = {}

local MAX_LIGHT_BRIGHTNESS = 2.65
local MAX_LIGHT_RANGE = 22
local MAX_PARTICLE_EMISSION = 0.96
local PARK_POS = Vector3.new(0, -5200, 0)

local function isLowFX()
	if localPlayer and localPlayer:GetAttribute("LowFXMode") == true then
		return true
	end
	if Workspace:GetAttribute("LowFXMode") == true then
		return true
	end
	if UI and UI.LowFX == true then
		return true
	end
	return false
end

local function playSFX(id, pos, pitchJitter)
	if Audio and type(Audio.PlaySFX) == "function" then
		pcall(Audio.PlaySFX, id, pos, pitchJitter or 0.04)
	end
end

local function emitCameraTrauma(trauma, fovPunch, dirVec)
	if not localPlayer or isLowFX() then return end
	local camEvt = tempFX and tempFX:FindFirstChild("SkybreakCameraImpulse")
	if camEvt and camEvt:IsA("BindableEvent") then
		camEvt:Fire(trauma or 0.25, fovPunch or 0, dirVec)
	else
		localPlayer:SetAttribute("SkybreakTraumaPulse", tonumber(trauma) or 0.25)
		if fovPunch and fovPunch ~= 0 then
			localPlayer:SetAttribute("SkybreakFovPunch", tonumber(fovPunch) or 0)
		end
	end
end

local function ensureTempFolder(name)
	if not tempFX then
		tempFX = Workspace:FindFirstChild("TempFX")
		if not tempFX then
			tempFX = Instance.new("Folder")
			tempFX.Name = "TempFX"
			tempFX.Parent = Workspace
		end
	end
	local sub = tempFX:FindFirstChild(name)
	if not sub then
		sub = Instance.new("Folder")
		sub.Name = name
		sub.Parent = tempFX
	end
	return sub
end

-- ============================================================================
-- ANTI-GLARE 3D PRIMITIVE BUILDERS
-- ============================================================================
local function makePart(name, shape, size, cf, color, transparency, material, parent)
	local p = Instance.new("Part")
	p.Name = name or "VFXPart"
	p.Shape = shape or Enum.PartType.Block
	p.Size = size or Vector3.new(1, 1, 1)
	p.CFrame = cf or CFrame.new()
	p.Color = color or Color3.fromRGB(115, 225, 255)
	local mat = material or Enum.Material.Neon
	if mat == Enum.Material.ForceField then
		mat = Enum.Material.Neon
	end
	p.Material = mat
	p.Transparency = math.clamp(transparency or 0.16, 0, 1)
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	local nm = p.Name
	if (p.Shape == Enum.PartType.Block or p.Shape == Enum.PartType.Wedge)
		and mat == Enum.Material.Neon
		and not nm:find("Shard")
		and not nm:find("Boulder")
		and not nm:find("Slab")
		and not nm:find("Gate")
		and not nm:find("Rock")
	then
		local sm = Instance.new("SpecialMesh")
		sm.MeshType = Enum.MeshType.Sphere
		sm.Parent = p
	end
	p.Parent = parent or tempFX
	return p
end

local function makeSafeLight(parent, color, brightness, range, dur)
	if isLowFX() or not parent then return nil end
	local pl = Instance.new("PointLight")
	pl.Color = color or Color3.fromRGB(255, 220, 140)
	pl.Brightness = math.clamp(brightness or 1.85, 0, MAX_LIGHT_BRIGHTNESS)
	pl.Range = math.clamp(range or 15, 2, MAX_LIGHT_RANGE)
	pl.Shadows = false
	pl.Parent = parent
	if dur and dur > 0 then
		TweenService:Create(pl, TweenInfo.new(dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Brightness = 0,
			Range = math.min(MAX_LIGHT_RANGE, pl.Range * 1.15),
		}):Play()
	end
	return pl
end

local function makeBurstEmitter(parent, color1, color2, sizeStart, sizeEnd, lifetime, speedMin, speedMax, emitCount)
	if not parent then return nil end
	local att = Instance.new("Attachment")
	att.Parent = parent
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxassetid://243660364"
	pe.Color = ColorSequence.new(color1, color2 or color1)
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, sizeStart or 0.9),
		NumberSequenceKeypoint.new(0.55, ((sizeStart or 0.9) + (sizeEnd or 0.1)) * 0.5),
		NumberSequenceKeypoint.new(1, sizeEnd or 0),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.08),
		NumberSequenceKeypoint.new(0.7, 0.42),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.LightEmission = math.min(MAX_PARTICLE_EMISSION, 0.90)
	pe.LightInfluence = 0.08
	pe.Lifetime = NumberRange.new((lifetime or 0.45) * 0.7, lifetime or 0.45)
	pe.Speed = NumberRange.new(speedMin or 8, speedMax or 22)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Drag = 3.5
	pe.Rate = 0
	pe.Parent = att
	local count = emitCount or 12
	if isLowFX() then
		count = math.max(1, math.floor(count * 0.35 + 0.5))
	end
	pe:Emit(count)
	return pe
end

local function findGroundPos(origin, ignoreInst)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local filter = { tempFX }
	if ignoreInst then table.insert(filter, ignoreInst) end
	if localPlayer and localPlayer.Character then table.insert(filter, localPlayer.Character) end
	params.FilterDescendantsInstances = filter
	local hit = Workspace:Raycast(origin + Vector3.new(0, 4, 0), Vector3.new(0, -32, 0), params)
	if hit then
		return hit.Position
	end
	return origin - Vector3.new(0, 2.6, 0)
end

local function spawnShockRing(pos, normalCF, color, startR, endR, thickness, dur, mat)
	local baseCF = normalCF or CFrame.new(pos)
	local ring = makePart(
		"ShockRing",
		Enum.PartType.Cylinder,
		Vector3.new(thickness or 0.26, startR, startR),
		baseCF * CFrame.Angles(0, 0, math.pi * 0.5),
		color,
		0.18,
		mat or Enum.Material.ForceField
	)
	local d = dur or 0.42
	TweenService:Create(ring, TweenInfo.new(d, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = Vector3.new(math.max(0.08, (thickness or 0.26) * 0.35), endR, endR),
		Transparency = 1,
	}):Play()
	Debris:AddItem(ring, d + 0.05)
	return ring
end

local function spawnCraterRing(centerPos, primaryColor, rockColor, radius, shardCount, dur)
	local gPos = findGroundPos(centerPos)
	local count = shardCount or 8
	if isLowFX() then
		count = math.max(4, math.floor(count * 0.5))
	end
	local d = dur or 0.58
	spawnShockRing(gPos + Vector3.new(0, 0.12, 0), CFrame.new(gPos + Vector3.new(0, 0.12, 0)), primaryColor, radius * 0.35, radius * 1.45, 0.24, d * 0.85, Enum.Material.ForceField)
	for i = 1, count do
		local ang = (i - 1) * ((math.pi * 2) / count)
		local r0 = radius * 0.45
		local r1 = radius
		local p0 = gPos + Vector3.new(math.cos(ang) * r0, -0.15, math.sin(ang) * r0)
		local p1 = gPos + Vector3.new(math.cos(ang) * r1, 0.42, math.sin(ang) * r1)
		local shard = makePart(
			"CraterShard",
			Enum.PartType.Wedge,
			Vector3.new(1.15, 0.85, 1.65),
			CFrame.lookAt(p0, gPos + Vector3.new(0, 1.5, 0)) * CFrame.Angles(-0.38, 0, (i % 2 == 0 and 0.22 or -0.22)),
			(i % 3 == 0) and primaryColor or (rockColor or Color3.fromRGB(64, 70, 84)),
			0.08,
			(i % 3 == 0) and Enum.Material.Glass or Enum.Material.Slate
		)
		TweenService:Create(shard, TweenInfo.new(d, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			CFrame = CFrame.lookAt(p1, gPos + Vector3.new(0, 2.2, 0)) * CFrame.Angles(-0.55, 0, 0),
			Transparency = 1,
		}):Play()
		Debris:AddItem(shard, d + 0.06)
	end
end

local function spawnAwakenedCorona(centerCF, scale, dur)
	local d = dur or 0.55
	local gold = Color3.fromRGB(255, 214, 92)
	local cyan = Color3.fromRGB(88, 236, 255)
	for i = 1, 2 do
		local r = (4.8 + i * 1.8) * scale
		local halo = makePart(
			"AwakenedCorona",
			Enum.PartType.Cylinder,
			Vector3.new(0.18, r, r),
			centerCF * CFrame.Angles(i == 1 and 0.45 or -0.45, i * 0.8, math.pi * 0.5),
			i == 1 and gold or cyan,
			0.2,
			Enum.Material.ForceField
		)
		TweenService:Create(halo, TweenInfo.new(d, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = Vector3.new(0.08, r * 1.85, r * 1.85),
			CFrame = halo.CFrame * CFrame.Angles(0.9, 1.2, 0),
			Transparency = 1,
		}):Play()
		Debris:AddItem(halo, d + 0.05)
	end
end

-- ============================================================================
-- #95. POOLED FLOATING 3D DAMAGE NUMBERS (40-NODE RING BUFFER, ZERO GC CHURN)
-- ============================================================================
local POOL_SIZE = 40
local damagePool = {}
local damagePoolCursor = 0

local ELEMENT_TEXT_COLORS = {
	Flame = Color3.fromRGB(255, 136, 56),
	Fire = Color3.fromRGB(255, 136, 56),
	Solar = Color3.fromRGB(255, 186, 68),
	Magma = Color3.fromRGB(244, 88, 46),
	Frost = Color3.fromRGB(108, 232, 255),
	Ice = Color3.fromRGB(122, 236, 255),
	Lightning = Color3.fromRGB(96, 198, 255),
	Thunder = Color3.fromRGB(96, 198, 255),
	Wind = Color3.fromRGB(134, 252, 216),
	Gale = Color3.fromRGB(134, 252, 216),
	Quake = Color3.fromRGB(238, 198, 124),
	Sand = Color3.fromRGB(238, 198, 124),
	Light = Color3.fromRGB(255, 236, 122),
	Sky = Color3.fromRGB(255, 222, 106),
	Gravity = Color3.fromRGB(186, 124, 255),
	Portal = Color3.fromRGB(82, 218, 255),
	Void = Color3.fromRGB(192, 118, 255),
	Abyss = Color3.fromRGB(218, 152, 255),
	Dough = Color3.fromRGB(255, 226, 174),
	Heal = Color3.fromRGB(92, 242, 160),
}

local function formatCommaDamage(rawStr)
	local num = tonumber(rawStr)
	if not num then
		return rawStr
	end
	local s = tostring(math.floor(math.abs(num) + 0.5))
	local k
	while true do
		s, k = string.gsub(s, "^(%d+)(%d%d%d)", "%1,%2")
		if k == 0 then
			break
		end
	end
	return (num < 0 and "-" or "") .. s
end

local function initDamageNumberPool()
	local folder = ensureTempFolder("DamageNumberPool")
	if #damagePool >= POOL_SIZE then return end
	for i = #damagePool + 1, POOL_SIZE do
		local anchor = Instance.new("Part")
		anchor.Name = "DmgNode_" .. tostring(i)
		anchor.Size = Vector3.new(0.2, 0.2, 0.2)
		anchor.Position = PARK_POS
		anchor.Transparency = 1
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.CanQuery = false
		anchor.CanTouch = false
		anchor.CastShadow = false
		anchor.Parent = folder

		local bill = Instance.new("BillboardGui")
		bill.Name = "DmgBillboard"
		bill.Size = UDim2.fromOffset(250, 92)
		bill.AlwaysOnTop = true
		bill.Enabled = false
		bill.MaxDistance = 190
		bill.Parent = anchor

		local uiScale = Instance.new("UIScale")
		uiScale.Scale = 1
		uiScale.Parent = bill

		-- 1:1 Figma Golden Multi-Point Starburst Crest behind Critical Hits (Screenshot 2)
		local critBurst = Instance.new("Frame")
		critBurst.Name = "CritStarburst"
		critBurst.AnchorPoint = Vector2.new(0.5, 0.5)
		critBurst.Position = UDim2.new(0.28, 0, 0.44, 0)
		critBurst.Size = UDim2.fromOffset(56, 56)
		critBurst.BackgroundTransparency = 1
		critBurst.Visible = false
		critBurst.ZIndex = 1
		critBurst.Parent = bill

		local burstGlow = Instance.new("Frame")
		burstGlow.Name = "BurstGlow"
		burstGlow.AnchorPoint = Vector2.new(0.5, 0.5)
		burstGlow.Position = UDim2.fromScale(0.5, 0.5)
		burstGlow.Size = UDim2.fromOffset(48, 48)
		burstGlow.BackgroundColor3 = Color3.fromRGB(251, 191, 36)
		burstGlow.BackgroundTransparency = 0.62
		burstGlow.BorderSizePixel = 0
		burstGlow.ZIndex = 1
		burstGlow.Parent = critBurst
		local bgCr = Instance.new("UICorner")
		bgCr.CornerRadius = UDim.new(1, 0)
		bgCr.Parent = burstGlow

		local burstRays = { burstGlow }
		for rIdx, rotDeg in ipairs({ 0, 30, 60, 15, 45, 75 }) do
			local ray = Instance.new("Frame")
			ray.Name = "StarRay_" .. tostring(rIdx)
			ray.AnchorPoint = Vector2.new(0.5, 0.5)
			ray.Position = UDim2.fromScale(0.5, 0.5)
			ray.Size = (rIdx <= 3) and UDim2.fromOffset(44, 14) or UDim2.fromOffset(34, 10)
			ray.Rotation = rotDeg
			ray.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			ray.BackgroundTransparency = (rIdx <= 3) and 0.14 or 0.28
			ray.BorderSizePixel = 0
			ray.ZIndex = 2
			ray.Parent = critBurst
			local rCr = Instance.new("UICorner")
			rCr.CornerRadius = UDim.new(0, 3)
			rCr.Parent = ray
			local rGrad = Instance.new("UIGradient")
			rGrad.Color = ColorSequence.new(Color3.fromRGB(254, 240, 138), Color3.fromRGB(217, 119, 6))
			rGrad.Parent = ray
			table.insert(burstRays, ray)
		end

		-- Top "BAO KICH!" Header Row with Golden Lightning Bolt Icon
		local critHeader = Instance.new("Frame")
		critHeader.Name = "CritHeader"
		critHeader.Position = UDim2.fromOffset(0, 2)
		critHeader.Size = UDim2.new(1, 0, 0, 22)
		critHeader.BackgroundTransparency = 1
		critHeader.Visible = false
		critHeader.ZIndex = 4
		critHeader.Parent = bill

		local boltTop = Instance.new("Frame")
		boltTop.Name = "BoltTop"
		boltTop.AnchorPoint = Vector2.new(0.5, 0.5)
		boltTop.Position = UDim2.new(0.5, -44, 0.5, -2)
		boltTop.Size = UDim2.fromOffset(5, 9)
		boltTop.Rotation = 22
		boltTop.BackgroundColor3 = Color3.fromRGB(254, 240, 138)
		boltTop.BorderSizePixel = 0
		boltTop.ZIndex = 5
		boltTop.Parent = critHeader

		local boltBot = Instance.new("Frame")
		boltBot.Name = "BoltBot"
		boltBot.AnchorPoint = Vector2.new(0.5, 0.5)
		boltBot.Position = UDim2.new(0.5, -42, 0.5, 3)
		boltBot.Size = UDim2.fromOffset(4, 9)
		boltBot.Rotation = 22
		boltBot.BackgroundColor3 = Color3.fromRGB(245, 158, 11)
		boltBot.BorderSizePixel = 0
		boltBot.ZIndex = 5
		boltBot.Parent = critHeader

		local critTagLbl = Instance.new("TextLabel")
		critTagLbl.Name = "CritTagText"
		critTagLbl.Position = UDim2.fromOffset(10, 0)
		critTagLbl.Size = UDim2.new(1, -10, 1, 0)
		critTagLbl.BackgroundTransparency = 1
		critTagLbl.Font = Enum.Font.GothamBlack
		critTagLbl.TextSize = 14
		critTagLbl.TextColor3 = Color3.fromRGB(254, 240, 138)
		critTagLbl.Text = "BẠO KÍCH!"
		critTagLbl.ZIndex = 5
		critTagLbl.Parent = critHeader

		local critTagStroke = Instance.new("UIStroke")
		critTagStroke.Color = Color3.fromRGB(38, 18, 4)
		critTagStroke.Thickness = 1.8
		critTagStroke.Parent = critTagLbl

		local mainLbl = Instance.new("TextLabel")
		mainLbl.Name = "Main"
		mainLbl.Position = UDim2.fromOffset(0, 20)
		mainLbl.Size = UDim2.new(1, 0, 0, 46)
		mainLbl.BackgroundTransparency = 1
		mainLbl.Font = Enum.Font.GothamBlack
		mainLbl.TextSize = 22
		mainLbl.TextColor3 = Color3.fromRGB(248, 250, 252)
		mainLbl.Text = ""
		mainLbl.ZIndex = 4
		mainLbl.Parent = bill

		local mainGrad = Instance.new("UIGradient")
		mainGrad.Name = "MainGrad"
		mainGrad.Rotation = 90
		mainGrad.Enabled = false
		mainGrad.Color = ColorSequence.new(Color3.fromRGB(254, 243, 162), Color3.fromRGB(245, 158, 11))
		mainGrad.Parent = mainLbl

		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(10, 18, 30)
		stroke.Thickness = 2.0
		stroke.Parent = mainLbl

		local subLbl = Instance.new("TextLabel")
		subLbl.Name = "Sub"
		subLbl.Position = UDim2.fromOffset(0, 64)
		subLbl.Size = UDim2.new(1, 0, 0, 22)
		subLbl.BackgroundTransparency = 1
		subLbl.Font = Enum.Font.GothamBold
		subLbl.TextSize = 13
		subLbl.TextColor3 = Color3.fromRGB(205, 145, 255)
		subLbl.TextStrokeColor3 = Color3.fromRGB(10, 14, 24)
		subLbl.TextStrokeTransparency = 0.25
		subLbl.Text = ""
		subLbl.Visible = false
		subLbl.ZIndex = 4
		subLbl.Parent = bill

		damagePool[i] = {
			Anchor = anchor,
			Bill = bill,
			Scale = uiScale,
			CritBurst = critBurst,
			BurstRays = burstRays,
			CritHeader = critHeader,
			CritTagLbl = critTagLbl,
			CritTagStroke = critTagStroke,
			BoltTop = boltTop,
			BoltBot = boltBot,
			Main = mainLbl,
			MainGrad = mainGrad,
			Stroke = stroke,
			Sub = subLbl,
			Token = 0,
		}
	end
end

function SkybreakClientVFX.SpawnDamagePopup(payload)
	if type(payload) ~= "table" then return end
	if #damagePool < POOL_SIZE then
		initDamageNumberPool()
	end
	local basePos = payload.pos or payload.Position
	if typeof(basePos) ~= "Vector3" then return end
	local rawText = payload.Text or payload.text
	local amount = payload.amount or payload.Amount or rawText
	if amount == nil then return end

	local str = tostring(amount)
	local upper = str:upper()
	local elem = tostring(payload.element or payload.Element or "")
	local isLogia = (payload.LogiaDodge == true) or (payload.Kind == "LogiaDodge") or (payload.Kind == "ElementalReflex")
		or (upper:find("LOGIA") ~= nil) or (upper:find("REFLEX") ~= nil)
	local isDodge = isLogia or (payload.Dodge == true) or (upper:find("DODGE") ~= nil) or (upper:find("MISS") ~= nil) or (upper:find("INSTINCT") ~= nil)
	local isHeal = (elem == "Heal") or (upper:find("HP") ~= nil and str:find("%+") ~= nil)
	local isCrit = (not isDodge and not isHeal) and ((payload.crit == true) or (payload.Crit == true) or (str:find("!") ~= nil))
	local breakDmg = tonumber(payload.breakDmg or payload.BreakDmg) or 0

	if isDodge then
		playSFX("dodge_dash", basePos, 0.05)
	elseif isHeal then
		playSFX("potion_heal", basePos, 0.04)
	elseif breakDmg >= 35 then
		playSFX("hit_break", basePos, 0.05)
	elseif isCrit then
		playSFX("hit_crit", basePos, 0.05)
	else
		playSFX("hit_normal", basePos, 0.06)
	end

	-- Trigger #32 Logia Elemental Reflex, Heal Vitality Swirl, or #68 Hit-Impact Polish
	if isLogia then
		SkybreakClientVFX.SpawnLogiaReflex(basePos, payload.FruitId or payload.fruitId or elem, payload.TargetModel)
	elseif isHeal then
		UniversalVFXOverhaul.SpawnProgressionVFX("Heal", localPlayer and localPlayer.Character)
	elseif not isDodge then
		SkybreakClientVFX.TriggerImpactPolish(basePos, isCrit, breakDmg, payload.Direction or payload.KnockbackDir, payload.TargetModel)
	end

	damagePoolCursor = (damagePoolCursor % POOL_SIZE) + 1
	local node = damagePool[damagePoolCursor]
	if not node or not node.Anchor or not node.Anchor.Parent then
		initDamageNumberPool()
		node = damagePool[damagePoolCursor]
		if not node then return end
	end

	node.Token += 1
	local myToken = node.Token
	if node.ActiveTweens then
		for _, tw in ipairs(node.ActiveTweens) do
			pcall(function() tw:Cancel() end)
		end
		table.clear(node.ActiveTweens)
	else
		node.ActiveTweens = {}
	end

	local jitterX = (math.random() - 0.5) * 2.8
	local jitterZ = (math.random() - 0.5) * 2.8
	local startPos = basePos + Vector3.new(jitterX, 3.1, jitterZ)
	node.Anchor.Position = startPos
	node.Bill.Enabled = true
	node.Main.TextTransparency = 0
	node.Stroke.Transparency = 0

	local cleanNum = str:gsub("!", ""):gsub("%+", ""):gsub("HP", ""):gsub("%s+", "")
	local formattedNum = formatCommaDamage(cleanNum ~= "" and cleanNum or str)

	if node.CritBurst then
		node.CritBurst.Visible = false
		node.CritBurst.Rotation = math.random(-14, 14)
	end
	if node.CritHeader then
		node.CritHeader.Visible = false
	end
	if node.MainGrad then
		node.MainGrad.Enabled = false
	end

	if isLogia then
		node.Main.Text = "NÉ NGUYÊN TỐ!"
		node.Main.TextColor3 = ELEMENT_TEXT_COLORS[elem] or Color3.fromRGB(122, 238, 255)
		node.Main.TextSize = 21
		node.Stroke.Color = Color3.fromRGB(10, 24, 38)
		node.Stroke.Thickness = 2.0
		node.Scale.Scale = 1.24
	elseif isDodge then
		node.Main.Text = "NÉ ĐÒN!"
		node.Main.TextColor3 = Color3.fromRGB(103, 232, 249)
		node.Main.TextSize = 21
		node.Stroke.Color = Color3.fromRGB(8, 22, 36)
		node.Stroke.Thickness = 2.0
		node.Scale.Scale = 1.18
	elseif isHeal then
		node.Main.Text = "+" .. formattedNum .. " HP"
		node.Main.TextColor3 = ELEMENT_TEXT_COLORS.Heal
		node.Main.TextSize = 23
		node.Stroke.Color = Color3.fromRGB(8, 32, 18)
		node.Stroke.Thickness = 1.9
		node.Scale.Scale = 1.10
	elseif isCrit then
		if node.CritBurst then
			node.CritBurst.Visible = true
			for rIdx, ray in ipairs(node.BurstRays or {}) do
				ray.BackgroundTransparency = (rIdx == 1) and 0.62 or ((rIdx <= 4) and 0.14 or 0.28)
			end
		end
		if node.CritHeader then
			node.CritHeader.Visible = true
			node.CritTagLbl.TextTransparency = 0
			node.CritTagStroke.Transparency = 0
			node.BoltTop.BackgroundTransparency = 0
			node.BoltBot.BackgroundTransparency = 0
			node.CritTagLbl.Text = (payload.IsBreak == true) and "PHÁ GIÁP!" or "BẠO KÍCH!"
		end
		if node.MainGrad then
			node.MainGrad.Enabled = true
		end
		node.Main.Text = formattedNum
		node.Main.TextColor3 = Color3.fromRGB(255, 255, 255)
		node.Main.TextSize = 32
		node.Stroke.Color = Color3.fromRGB(54, 24, 4)
		node.Stroke.Thickness = 2.6
		node.Scale.Scale = 1.50
	else
		local elemColor = ELEMENT_TEXT_COLORS[elem]
		node.Main.Text = formattedNum
		node.Main.TextColor3 = elemColor or Color3.fromRGB(248, 250, 255)
		node.Main.TextSize = 22
		node.Stroke.Color = Color3.fromRGB(9, 14, 26)
		node.Stroke.Thickness = 2.0
		node.Scale.Scale = 1.05
	end

	if breakDmg > 0 then
		node.Sub.Visible = true
		node.Sub.TextTransparency = 0
		node.Sub.TextStrokeTransparency = 0.25
		node.Sub.Text = "+ " .. tostring(math.floor(breakDmg)) .. " BREAK"
	elseif elem ~= "" and ELEMENT_TEXT_COLORS[elem] and not isHeal and not isDodge then
		node.Sub.Visible = true
		node.Sub.TextTransparency = 0.1
		node.Sub.TextStrokeTransparency = 0.3
		node.Sub.TextColor3 = ELEMENT_TEXT_COLORS[elem]
		node.Sub.Text = elem:upper()
	else
		node.Sub.Visible = false
	end

	if node.Scale.Scale > 1.01 then
		local twScale = TweenService:Create(node.Scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 })
		table.insert(node.ActiveTweens, twScale)
		twScale:Play()
	end

	local riseOffset = isCrit and Vector3.new(0, 4.1, 0) or Vector3.new(0, 3.2, 0)
	local twRise = TweenService:Create(node.Anchor, TweenInfo.new(0.78, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Position = startPos + riseOffset,
	})
	table.insert(node.ActiveTweens, twRise)
	twRise:Play()

	task.delay(0.36, function()
		if node.Token ~= myToken then return end
		local twMain = TweenService:Create(node.Main, TweenInfo.new(0.40), { TextTransparency = 1 })
		local twStroke = TweenService:Create(node.Stroke, TweenInfo.new(0.40), { Transparency = 1 })
		table.insert(node.ActiveTweens, twMain)
		table.insert(node.ActiveTweens, twStroke)
		twMain:Play()
		twStroke:Play()
		if node.CritHeader and node.CritHeader.Visible then
			local twCT = TweenService:Create(node.CritTagLbl, TweenInfo.new(0.38), { TextTransparency = 1 })
			local twCS = TweenService:Create(node.CritTagStroke, TweenInfo.new(0.38), { Transparency = 1 })
			local twB1 = TweenService:Create(node.BoltTop, TweenInfo.new(0.38), { BackgroundTransparency = 1 })
			local twB2 = TweenService:Create(node.BoltBot, TweenInfo.new(0.38), { BackgroundTransparency = 1 })
			table.insert(node.ActiveTweens, twCT)
			table.insert(node.ActiveTweens, twCS)
			table.insert(node.ActiveTweens, twB1)
			table.insert(node.ActiveTweens, twB2)
			twCT:Play()
			twCS:Play()
			twB1:Play()
			twB2:Play()
		end
		if node.CritBurst and node.CritBurst.Visible then
			for _, ray in ipairs(node.BurstRays or {}) do
				local twRay = TweenService:Create(ray, TweenInfo.new(0.36), { BackgroundTransparency = 1 })
				table.insert(node.ActiveTweens, twRay)
				twRay:Play()
			end
		end
		if node.Sub.Visible then
			local twSub = TweenService:Create(node.Sub, TweenInfo.new(0.40), { TextTransparency = 1, TextStrokeTransparency = 1 })
			table.insert(node.ActiveTweens, twSub)
			twSub:Play()
		end
	end)

	task.delay(0.80, function()
		if node.Token ~= myToken then return end
		node.Bill.Enabled = false
		node.Anchor.Position = PARK_POS
	end)
end

-- ============================================================================
-- CANONICAL FRUIT PALETTE & ALIAS RESOLVER (ALL 12 FRUITS + ALIASES)
-- ============================================================================
local FRUIT_PROFILES = {
	GaleCore = {
		Primary = Color3.fromRGB(122, 246, 214),
		Secondary = Color3.fromRGB(214, 255, 244),
		Accent = Color3.fromRGB(72, 206, 184),
		Element = "Wind",
		Mat = Enum.Material.ForceField,
		ReflexShape = Enum.PartType.Cylinder,
	},
	SandstoneCore = {
		Primary = Color3.fromRGB(234, 196, 122),
		Secondary = Color3.fromRGB(142, 224, 246),
		Accent = Color3.fromRGB(178, 138, 76),
		Element = "Quake",
		Mat = Enum.Material.Glass,
		ReflexShape = Enum.PartType.Wedge,
	},
	SolarFlameCore = {
		Primary = Color3.fromRGB(255, 126, 44),
		Secondary = Color3.fromRGB(255, 208, 86),
		Accent = Color3.fromRGB(214, 58, 28),
		Element = "Flame",
		Mat = Enum.Material.ForceField,
		ReflexShape = Enum.PartType.Ball,
	},
	GlacierIceCore = {
		Primary = Color3.fromRGB(106, 226, 255),
		Secondary = Color3.fromRGB(214, 248, 255),
		Accent = Color3.fromRGB(54, 158, 226),
		Element = "Frost",
		Mat = Enum.Material.Glass,
		ReflexShape = Enum.PartType.Wedge,
	},
	CelestialLightCore = {
		Primary = Color3.fromRGB(255, 228, 98),
		Secondary = Color3.fromRGB(255, 246, 188),
		Accent = Color3.fromRGB(246, 182, 48),
		Element = "Light",
		Mat = Enum.Material.ForceField,
		ReflexShape = Enum.PartType.Block,
	},
	StarforgedMagmaCore = {
		Primary = Color3.fromRGB(232, 68, 34),
		Secondary = Color3.fromRGB(255, 154, 52),
		Accent = Color3.fromRGB(76, 32, 28),
		Element = "Magma",
		Mat = Enum.Material.SmoothPlastic,
		ReflexShape = Enum.PartType.Ball,
	},
	ThunderRumbleCore = {
		Primary = Color3.fromRGB(78, 192, 255),
		Secondary = Color3.fromRGB(176, 128, 255),
		Accent = Color3.fromRGB(212, 244, 255),
		Element = "Lightning",
		Mat = Enum.Material.ForceField,
		ReflexShape = Enum.PartType.Block,
	},
	AstralGravityCore = {
		Primary = Color3.fromRGB(158, 86, 248),
		Secondary = Color3.fromRGB(78, 42, 138),
		Accent = Color3.fromRGB(224, 176, 255),
		Element = "Gravity",
		Mat = Enum.Material.ForceField,
		ReflexShape = Enum.PartType.Ball,
	},
	DimensionalPortalCore = {
		Primary = Color3.fromRGB(58, 216, 255),
		Secondary = Color3.fromRGB(36, 92, 188),
		Accent = Color3.fromRGB(158, 248, 255),
		Element = "Portal",
		Mat = Enum.Material.ForceField,
		ReflexShape = Enum.PartType.Cylinder,
	},
	SolarTitanCore = {
		Primary = Color3.fromRGB(255, 206, 74),
		Secondary = Color3.fromRGB(255, 238, 156),
		Accent = Color3.fromRGB(218, 146, 36),
		Element = "Sky",
		Mat = Enum.Material.SmoothPlastic,
		ReflexShape = Enum.PartType.Cylinder,
	},
	AetherflowCore = {
		Primary = Color3.fromRGB(248, 222, 168),
		Secondary = Color3.fromRGB(255, 184, 112),
		Accent = Color3.fromRGB(196, 136, 78),
		Element = "Dough",
		Mat = Enum.Material.SmoothPlastic,
		ReflexShape = Enum.PartType.Ball,
	},
	AbyssalSovereignCore = {
		Primary = Color3.fromRGB(255, 46, 150),
		Secondary = Color3.fromRGB(168, 38, 255),
		Accent = Color3.fromRGB(20, 12, 36),
		Element = "Abyss",
		Mat = Enum.Material.ForceField,
		ReflexShape = Enum.PartType.Wedge,
	},
}

local FRUIT_ALIASES = {
	gale_core = "GaleCore",
	GaleCore = "GaleCore",
	Wind = "GaleCore",
	sandstone_quake = "SandstoneCore",
	SandstoneCore = "SandstoneCore",
	StarlightQuakeCore = "SandstoneCore",
	Quake = "SandstoneCore",
	solar_flame = "SolarFlameCore",
	SolarFlameCore = "SolarFlameCore",
	CyberPhoenixCore = "SolarFlameCore",
	Flame = "SolarFlameCore",
	Fire = "SolarFlameCore",
	glacier_ice = "GlacierIceCore",
	GlacierIceCore = "GlacierIceCore",
	GlacialPermafrostCore = "GlacierIceCore",
	Ice = "GlacierIceCore",
	Frost = "GlacierIceCore",
	celestial_light = "CelestialLightCore",
	CelestialLightCore = "CelestialLightCore",
	Light = "CelestialLightCore",
	starforged_magma = "StarforgedMagmaCore",
	StarforgedMagmaCore = "StarforgedMagmaCore",
	CrimsonMagmaCore = "StarforgedMagmaCore",
	Magma = "StarforgedMagmaCore",
	thunder_rumble = "ThunderRumbleCore",
	ThunderRumbleCore = "ThunderRumbleCore",
	LightningTempestCore = "ThunderRumbleCore",
	Lightning = "ThunderRumbleCore",
	Thunder = "ThunderRumbleCore",
	Rumble = "ThunderRumbleCore",
	astral_gravity = "AstralGravityCore",
	AstralGravityCore = "AstralGravityCore",
	Gravity = "AstralGravityCore",
	dimensional_portal = "DimensionalPortalCore",
	DimensionalPortalCore = "DimensionalPortalCore",
	Portal = "DimensionalPortalCore",
	solar_titan = "SolarTitanCore",
	SolarTitanCore = "SolarTitanCore",
	Buddha = "SolarTitanCore",
	aetherflow_dough = "AetherflowCore",
	AetherflowCore = "AetherflowCore",
	Dough = "AetherflowCore",
	abyssal_dragon = "AbyssalSovereignCore",
	AbyssalSovereignCore = "AbyssalSovereignCore",
	Dragon = "AbyssalSovereignCore",
}

local function resolveFruitKey(raw)
	local s = tostring(raw or "")
	if FRUIT_ALIASES[s] then return FRUIT_ALIASES[s] end
	local low = s:lower()
	if low:find("gale") or low:find("wind") then return "GaleCore" end
	if low:find("sand") or low:find("quake") then return "SandstoneCore" end
	if low:find("flame") or low:find("fire") or low:find("phoenix") then return "SolarFlameCore" end
	if low:find("ice") or low:find("glac") or low:find("frost") then return "GlacierIceCore" end
	if low:find("light") or low:find("lumen") then return "CelestialLightCore" end
	if low:find("magma") or low:find("lava") or low:find("volcan") then return "StarforgedMagmaCore" end
	if low:find("rumble") or low:find("thunder") or low:find("tempest") or low:find("volt") then return "ThunderRumbleCore" end
	if low:find("grav") or low:find("meteor") then return "AstralGravityCore" end
	if low:find("portal") or low:find("dimension") or low:find("rift") then return "DimensionalPortalCore" end
	if low:find("titan") or low:find("buddha") then return "SolarTitanCore" end
	if low:find("aetherflow") or low:find("dough") or low:find("mochi") then return "AetherflowCore" end
	if low:find("abyss") or low:find("sovereign") or low:find("dragon") then return "AbyssalSovereignCore" end
	return nil
end

-- ============================================================================
-- #32. LOGIA ELEMENTAL REFLEX DODGE VFX
-- ============================================================================
function SkybreakClientVFX.SpawnLogiaReflex(pos, rawFruitOrElem, targetModel)
	if typeof(pos) ~= "Vector3" then return end
	local fKey = resolveFruitKey(rawFruitOrElem)
		or resolveFruitKey(targetModel and targetModel:GetAttribute("EquippedFruit"))
		or resolveFruitKey(localPlayer and localPlayer:GetAttribute("EquippedFruit"))
		or "CelestialLightCore"
	local prof = FRUIT_PROFILES[fKey] or FRUIT_PROFILES.CelestialLightCore

	local model = targetModel
	if not model and localPlayer and localPlayer.Character then
		local r = localPlayer.Character:FindFirstChild("HumanoidRootPart")
		if r and (r.Position - pos).Magnitude < 9 then
			model = localPlayer.Character
		end
	end
	UniversalVFXOverhaul.SpawnLogiaReflex(pos, prof, model)
end

-- ============================================================================
-- #68. HIT-STOP (45-65ms), RADIAL IMPACT SPARK & KNOCKBACK TRAILS
-- ============================================================================
local lastHitStopAt = 0

function SkybreakClientVFX.TriggerImpactPolish(hitPos, isCrit, breakDmg, knockDir, targetModel)
	if typeof(hitPos) ~= "Vector3" then return end
	local now = os.clock()
	local heavyImpact = (breakDmg and breakDmg >= 35) or isCrit

	-- 1. Overhauled Multi-Axis Anime Impact Star-Cross + Guard-Break Shatter Prisms + VFX Studio Prefab + VibeGG 5-Step Hit Juice
	UniversalVFXOverhaul.SpawnHitImpact(hitPos, isCrit, breakDmg, knockDir, targetModel)

	-- 2. Crisp 45ms-65ms Local Hit-Stop Freeze-Frame (rate-limited so combos never stutter-lock)
	if heavyImpact and (now - lastHitStopAt >= 0.24) then
		lastHitStopAt = now
		local freezeDur = (breakDmg and breakDmg >= 35) and 0.062 or 0.048
		emitCameraTrauma((breakDmg and breakDmg >= 35) and 0.44 or 0.30, isCrit and 2.5 or 0, knockDir)
		local ch = localPlayer and localPlayer.Character
		if ch then
			ch:SetAttribute("HitStopUntil", now + freezeDur)
			local hum = ch:FindFirstChildOfClass("Humanoid")
			local animator = hum and hum:FindFirstChildOfClass("Animator")
			local pausedTracks = {}
			if animator then
				for _, tr in ipairs(animator:GetPlayingAnimationTracks()) do
					if tr.IsPlaying and tr.Speed > 0.08 then
						table.insert(pausedTracks, { Track = tr, Speed = tr.Speed })
						pcall(function() tr:AdjustSpeed(0.02) end)
					end
				end
			end
			task.delay(freezeDur, function()
				for _, item in ipairs(pausedTracks) do
					if item.Track and item.Track.IsPlaying then
						pcall(function() item.Track:AdjustSpeed(item.Speed) end)
					end
				end
			end)
		end
	end

	-- 3. Directional Knockback Wind & Dust Trail on Struck Target
	local kbDir = (typeof(knockDir) == "Vector3" and knockDir.Magnitude > 0.05) and knockDir.Unit or nil
	if not kbDir and localPlayer and localPlayer.Character then
		local r = localPlayer.Character:FindFirstChild("HumanoidRootPart")
		if r and (hitPos - r.Position).Magnitude > 0.4 then
			kbDir = Vector3.new(hitPos.X - r.Position.X, 0, hitPos.Z - r.Position.Z)
			kbDir = (kbDir.Magnitude > 0.1) and kbDir.Unit or r.CFrame.LookVector
		end
	end
	if heavyImpact and kbDir and not isLowFX() then
		for i = 1, 4 do
			task.delay((i - 1) * 0.035, function()
				local p = hitPos + kbDir * (i * 2.4)
				local puff = makePart(
					"KnockbackSlip",
					Enum.PartType.Cylinder,
					Vector3.new(0.18, 2.2 + i * 0.4, 2.2 + i * 0.4),
					CFrame.lookAt(p, p + kbDir) * CFrame.Angles(0, math.pi * 0.5, 0),
					Color3.fromRGB(215, 226, 238),
					0.34,
					Enum.Material.ForceField
				)
				TweenService:Create(puff, TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = Vector3.new(0.06, 5.2 + i * 0.6, 5.2 + i * 0.6),
					Transparency = 1,
				}):Play()
				Debris:AddItem(puff, 0.32)
			end)
		end
	end
end

-- ============================================================================
-- #122. DYNAMIC HIT-FLASH (85ms) & AETHER DISSOLVE DEATH VFX ON ALL ENEMIES
-- ============================================================================
local watchedEnemies = setmetatable({}, { __mode = "k" })

local function triggerEnemyHitFlash(enemyModel)
	if not enemyModel or not enemyModel.Parent then return end
	local hl = enemyModel:FindFirstChild("SkybreakHitFlash")
	if not hl then
		hl = Instance.new("Highlight")
		hl.Name = "SkybreakHitFlash"
		hl.Adornee = enemyModel
		hl.DepthMode = Enum.HighlightDepthMode.Occluded
		hl.FillColor = Color3.fromRGB(255, 236, 184)
		hl.OutlineColor = Color3.fromRGB(255, 198, 92)
		hl.Parent = enemyModel
	end
	hl.Enabled = true
	hl.FillTransparency = 0.25
	hl.OutlineTransparency = 0.15
	local token = (enemyModel:GetAttribute("_HitFlashTok") or 0) + 1
	enemyModel:SetAttribute("_HitFlashTok", token)
	TweenService:Create(hl, TweenInfo.new(0.085, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		FillTransparency = 1,
		OutlineTransparency = 1,
	}):Play()
	task.delay(0.095, function()
		if enemyModel and enemyModel.Parent and enemyModel:GetAttribute("_HitFlashTok") == token and hl and hl.Parent then
			hl.Enabled = false
		end
	end)
end

local function triggerEnemyDissolveDeath(enemyModel)
	if not enemyModel or not enemyModel.Parent or enemyModel:GetAttribute("_DissolvedVFX") then return end
	enemyModel:SetAttribute("_DissolvedVFX", true)
	for _, ch in ipairs(enemyModel:GetChildren()) do
		if ch.Name == "Telegraph" or ch.Name == "TelegraphRing" or ch.Name == "AttackTelegraph" then
			ch:Destroy()
		end
	end
	local isBoss = (enemyModel.Parent and enemyModel.Parent.Name == "ActiveBosses") or (enemyModel:GetAttribute("IsBoss") == true)
	UniversalVFXOverhaul.SpawnEnemyDeathDissolve(enemyModel, isBoss)
end

local function bindEnemyModel(m)
	if not m or not m:IsA("Model") or watchedEnemies[m] then return end
	if m.Name == "EnergyPylon" then return end
	watchedEnemies[m] = true

	local conns = {}
	local lastHP = tonumber(m:GetAttribute("HP"))
	table.insert(conns, m:GetAttributeChangedSignal("EnemyHitAt"):Connect(function()
		triggerEnemyHitFlash(m)
	end))
	table.insert(conns, m:GetAttributeChangedSignal("HP"):Connect(function()
		local hp = tonumber(m:GetAttribute("HP"))
		if hp and lastHP and hp < lastHP then
			triggerEnemyHitFlash(m)
		end
		lastHP = hp
		if hp and hp <= 0 then
			triggerEnemyDissolveDeath(m)
		elseif hp and hp > 0 then
			m:SetAttribute("_DissolvedVFX", nil)
		end
	end))
	table.insert(conns, m:GetAttributeChangedSignal("EnemyDead"):Connect(function()
		if m:GetAttribute("EnemyDead") == true then
			triggerEnemyDissolveDeath(m)
		else
			m:SetAttribute("_DissolvedVFX", nil)
		end
	end))
	local hum = m:FindFirstChildOfClass("Humanoid")
	if hum then
		local prevH = hum.Health
		table.insert(conns, hum.HealthChanged:Connect(function(newH)
			if newH < prevH then
				triggerEnemyHitFlash(m)
			end
			prevH = newH
			if newH <= 0 then
				triggerEnemyDissolveDeath(m)
			end
		end))
	end
	table.insert(conns, m.AncestryChanged:Connect(function(_, parent)
		if not parent then
			for _, c in ipairs(conns) do c:Disconnect() end
			enemyConnections[m] = nil
		end
	end))
	enemyConnections[m] = conns
end

local function watchEnemyFolders()
	for _, folderName in ipairs({ "ActiveEnemies", "ActiveBosses" }) do
		local function hookFolder(f)
			if not f then return end
			for _, child in ipairs(f:GetChildren()) do
				bindEnemyModel(child)
			end
			table.insert(activeConnections, f.ChildAdded:Connect(bindEnemyModel))
		end
		hookFolder(Workspace:FindFirstChild(folderName))
		table.insert(activeConnections, Workspace.ChildAdded:Connect(function(ch)
			if ch.Name == folderName then
				hookFolder(ch)
			end
		end))
	end
end

-- ============================================================================
-- #19. HAKI VISUALS: BUSOSHOKU (STAGES 0-5 + 6 COLORS), KENBUNSHOKU V2, HAOSHOKU
-- ============================================================================
local HAKI_AURA_COLORS = {
	CrimsonRed = Color3.fromRGB(236, 52, 68),
	Crimson = Color3.fromRGB(236, 52, 68),
	Red = Color3.fromRGB(236, 52, 68),
	ElectricCyan = Color3.fromRGB(64, 224, 255),
	Cyan = Color3.fromRGB(64, 224, 255),
	RoyalGold = Color3.fromRGB(255, 206, 72),
	Gold = Color3.fromRGB(255, 206, 72),
	AstralViolet = Color3.fromRGB(178, 96, 255),
	Violet = Color3.fromRGB(178, 96, 255),
	EmeraldJade = Color3.fromRGB(68, 236, 152),
	Emerald = Color3.fromRGB(68, 236, 152),
	Green = Color3.fromRGB(68, 236, 152),
	SolarWhite = Color3.fromRGB(238, 246, 255),
	White = Color3.fromRGB(238, 246, 255),
}

local HAKI_COLOR_BY_INDEX = {
	[1] = HAKI_AURA_COLORS.CrimsonRed,
	[2] = HAKI_AURA_COLORS.ElectricCyan,
	[3] = HAKI_AURA_COLORS.RoyalGold,
	[4] = HAKI_AURA_COLORS.AstralViolet,
	[5] = HAKI_AURA_COLORS.EmeraldJade,
	[6] = HAKI_AURA_COLORS.SolarWhite,
}

local function resolveHakiColor(ch)
	local rgb = (ch and ch:GetAttribute("HakiColorRGB")) or (localPlayer and localPlayer:GetAttribute("HakiColorRGB"))
	if typeof(rgb) == "Color3" then return rgb end
	if typeof(rgb) == "Vector3" then return Color3.fromRGB(rgb.X, rgb.Y, rgb.Z) end
	local key = (ch and (ch:GetAttribute("HakiColor") or ch:GetAttribute("HakiAuraColor")))
		or (localPlayer and (localPlayer:GetAttribute("HakiColor") or localPlayer:GetAttribute("HakiAuraColor")))
	if typeof(key) == "Color3" then return key end
	if type(key) == "number" and HAKI_COLOR_BY_INDEX[key] then return HAKI_COLOR_BY_INDEX[key] end
	local s = tostring(key or ""):gsub("%s+", "")
	if HAKI_AURA_COLORS[s] then return HAKI_AURA_COLORS[s] end
	return HAKI_AURA_COLORS.CrimsonRed
end

local STAGE_LIMBS = {
	[1] = { "RightHand", "LeftHand", "RightLowerArm", "LeftLowerArm", "Right Arm", "Left Arm" },
	[2] = { "RightHand", "LeftHand", "RightLowerArm", "LeftLowerArm", "RightUpperArm", "LeftUpperArm", "RightFoot", "LeftFoot", "Right Arm", "Left Arm" },
	[3] = { "RightHand", "LeftHand", "RightLowerArm", "LeftLowerArm", "RightUpperArm", "LeftUpperArm", "UpperTorso", "Torso", "RightLowerLeg", "LeftLowerLeg", "RightFoot", "LeftFoot", "Right Arm", "Left Arm" },
	[4] = { "RightHand", "LeftHand", "RightLowerArm", "LeftLowerArm", "RightUpperArm", "LeftUpperArm", "UpperTorso", "LowerTorso", "Torso", "RightUpperLeg", "LeftUpperLeg", "RightLowerLeg", "LeftLowerLeg", "RightFoot", "LeftFoot", "Right Arm", "Left Arm", "Right Leg", "Left Leg" },
	[5] = { "Head", "RightHand", "LeftHand", "RightLowerArm", "LeftLowerArm", "RightUpperArm", "LeftUpperArm", "UpperTorso", "LowerTorso", "Torso", "RightUpperLeg", "LeftUpperLeg", "RightLowerLeg", "LeftLowerLeg", "RightFoot", "LeftFoot", "Right Arm", "Left Arm", "Right Leg", "Left Leg" },
}

local function updateBusoshokuCoating(ch)
	if not ch or not ch.Parent then return end
	local auraOn = (ch:GetAttribute("HakiAura") == true) or (localPlayer and localPlayer:GetAttribute("HakiAura") == true)
	local rawStage = tonumber(ch:GetAttribute("HakiStage") or (localPlayer and localPlayer:GetAttribute("HakiStage"))) or (auraOn and 2 or 0)
	local stage = auraOn and math.clamp(math.max(1, rawStage), 1, 5) or 0
	local prevStage = tonumber(ch:GetAttribute("_PrevBusoStage")) or 0
	ch:SetAttribute("_PrevBusoStage", stage)

	local old = ch:FindFirstChild("SkybreakBusoCoating")
	if old then old:Destroy() end
	local oldHl = ch:FindFirstChild("SkybreakBusoOutline")
	if oldHl then oldHl:Destroy() end

	if stage <= 0 then return end
	local auraColor = resolveHakiColor(ch)
	if stage > prevStage then
		UniversalVFXOverhaul.SpawnBusoIgnite(ch, auraColor, stage)
	end

	local folder = Instance.new("Folder")
	folder.Name = "SkybreakBusoCoating"
	folder.Parent = ch

	local allowed = {}
	for _, n in ipairs(STAGE_LIMBS[stage] or STAGE_LIMBS[2]) do
		allowed[n] = true
	end

	for _, part in ipairs(ch:GetChildren()) do
		if part:IsA("BasePart") and allowed[part.Name] and part.Transparency < 0.95 then
			local sleeve = Instance.new("Part")
			sleeve.Name = "Buso_" .. part.Name
			sleeve.Size = part.Size + Vector3.new(0.055, 0.055, 0.055)
			sleeve.CFrame = part.CFrame
			sleeve.Color = Color3.fromRGB(16, 18, 24)
			sleeve.Material = Enum.Material.Metal
			sleeve.Reflectance = 0.22 + stage * 0.04
			sleeve.Transparency = math.clamp(0.32 - stage * 0.04, 0.10, 0.30)
			sleeve.CanCollide = false
			sleeve.CanQuery = false
			sleeve.CanTouch = false
			sleeve.Massless = true
			sleeve.CastShadow = false
			sleeve.Parent = folder

			local weld = Instance.new("WeldConstraint")
			weld.Part0 = part
			weld.Part1 = sleeve
			weld.Parent = sleeve

			if stage >= 4 and (part.Name == "RightHand" or part.Name == "LeftHand" or part.Name == "Right Arm") and not isLowFX() then
				local att = Instance.new("Attachment")
				att.Parent = sleeve
				local pe = Instance.new("ParticleEmitter")
				pe.Color = ColorSequence.new(auraColor, Color3.fromRGB(24, 24, 34))
				pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.26), NumberSequenceKeypoint.new(1, 0) })
				pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
				pe.LightEmission = 0.65
				pe.Lifetime = NumberRange.new(0.25, 0.45)
				pe.Rate = (stage >= 5) and 14 or 8
				pe.Speed = NumberRange.new(1.5, 4.2)
				pe.SpreadAngle = Vector2.new(180, 180)
				pe.Parent = att
			end
		end
	end

	-- Stage 3-5 Colored Conqueror-Rim Aura Outline
	if stage >= 3 then
		local hl = Instance.new("Highlight")
		hl.Name = "SkybreakBusoOutline"
		hl.Adornee = ch
		hl.DepthMode = Enum.HighlightDepthMode.Occluded
		hl.FillColor = Color3.fromRGB(14, 16, 22)
		hl.FillTransparency = (stage >= 5) and 0.68 or 0.84
		hl.OutlineColor = auraColor
		hl.OutlineTransparency = (stage >= 5) and 0.06 or 0.24
		hl.Parent = ch
	end
end

-- Kenbunshoku V2 Sapphire Screen-Edge Vignette + 120-Stud Enemy Level & Style Tags
local kenVignetteGui = nil
local lastKenActive = false
local lastKenPhoto = false
local nextKenScanAt = 0

local function ensureKenVignetteGui()
	local pgui = localPlayer and localPlayer:FindFirstChildOfClass("PlayerGui")
	if not pgui then return nil end
	if kenVignetteGui and kenVignetteGui.Parent then return kenVignetteGui end

	local sg = Instance.new("ScreenGui")
	sg.Name = "SkybreakKenVignetteGui"
	sg.IgnoreGuiInset = true
	sg.ResetOnSpawn = false
	sg.DisplayOrder = 4
	sg.Enabled = false
	sg.Parent = pgui

	local edges = {
		{ Pos = UDim2.fromScale(0, 0), Size = UDim2.new(1, 0, 0, 84), Rot = 90 },
		{ Pos = UDim2.new(0, 0, 1, -84), Size = UDim2.new(1, 0, 0, 84), Rot = 270 },
		{ Pos = UDim2.fromScale(0, 0), Size = UDim2.new(0, 96, 1, 0), Rot = 0 },
		{ Pos = UDim2.new(1, -96, 0, 0), Size = UDim2.new(0, 96, 1, 0), Rot = 180 },
	}
	for idx, spec in ipairs(edges) do
		local f = Instance.new("Frame")
		f.Name = "Edge" .. idx
		f.Position = spec.Pos
		f.Size = spec.Size
		f.BackgroundColor3 = Color3.fromRGB(34, 152, 245)
		f.BorderSizePixel = 0
		f.Active = false
		f.Parent = sg
		local grad = Instance.new("UIGradient")
		grad.Rotation = spec.Rot
		grad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.62),
			NumberSequenceKeypoint.new(0.55, 0.86),
			NumberSequenceKeypoint.new(1, 1),
		})
		grad.Parent = f
	end

	local badge = Instance.new("TextLabel")
	badge.Name = "KenStatus"
	badge.AnchorPoint = Vector2.new(0.5, 0)
	badge.Position = UDim2.new(0.5, 0, 0, 54)
	badge.Size = UDim2.fromOffset(270, 22)
	badge.BackgroundTransparency = 1
	badge.Font = Enum.Font.GothamBold
	badge.TextSize = 12
	badge.TextColor3 = Color3.fromRGB(142, 228, 255)
	badge.TextStrokeTransparency = 0.35
	badge.Text = "KENBUNSHOKU HAKI  |  SENSE 120m"
	badge.Parent = sg

	kenVignetteGui = sg
	return sg
end

local function getEnemyMetaSummary(m)
	local id = tostring(m:GetAttribute("EnemyId") or m.Name)
	local cfg = Config and Config.Enemies and Config.Enemies[id]
	local dispName = (cfg and cfg.Name) or id
	local lv = tonumber(m:GetAttribute("InspectLevel") or m:GetAttribute("Level")) or (cfg and cfg.Level) or 1
	local style = tostring(m:GetAttribute("InspectStyle") or m:GetAttribute("Element") or m:GetAttribute("FightingStyle") or (cfg and (cfg.Element or cfg.Realm)) or "Aether")
	local hp = tonumber(m:GetAttribute("InspectHP") or m:GetAttribute("HP"))
	local maxHp = tonumber(m:GetAttribute("InspectMaxHP") or m:GetAttribute("MaxHP")) or (cfg and cfg.HP)
	return dispName, lv, style, hp, maxHp
end

function SkybreakClientVFX.UpdateInstinctVision()
	local ch = localPlayer and localPlayer.Character
	local kenV2 = (ch and ch:GetAttribute("KenV2Active") == true) or (localPlayer and localPlayer:GetAttribute("KenV2Active") == true)
	local active = kenV2
		or (ch and ch:GetAttribute("HakiInstinct") == true)
		or (localPlayer and localPlayer:GetAttribute("HakiInstinct") == true)
	local photoOn = localPlayer and localPlayer:GetAttribute("SkybreakPhotoMode") == true

	local sg = ensureKenVignetteGui()
	if sg then
		sg.Enabled = (active == true) and not photoOn
		if active then
			local badge = sg:FindFirstChild("KenStatus")
			if badge and badge:IsA("TextLabel") then
				local dodges = tonumber((ch and ch:GetAttribute("InstinctDodges")) or (localPlayer and localPlayer:GetAttribute("InstinctDodges"))) or 8
				badge.Text = string.format("%s  |  DODGES %d/8  |  SENSE 120m", kenV2 and "KENBUNSHOKU V2" or "KENBUNSHOKU HAKI", math.clamp(math.floor(dodges), 0, 8))
			end
		end
	end

	local now = os.clock()
	if active == lastKenActive and photoOn == lastKenPhoto and now < nextKenScanAt then
		return
	end
	nextKenScanAt = now + 0.15
	lastKenPhoto = photoOn

	local cc = Lighting:FindFirstChild("InstinctVision")
	if active then
		if not cc then
			cc = Instance.new("ColorCorrectionEffect")
			cc.Name = "InstinctVision"
			cc.Parent = Lighting
		end
		cc.TintColor = Color3.fromRGB(205, 232, 255)
		cc.Contrast = 0.12
		cc.Saturation = 0.06
		cc.Enabled = true

		local myRoot = ch and ch:FindFirstChild("HumanoidRootPart")
		local myPos = myRoot and myRoot.Position
		for _, folderName in ipairs({ "ActiveEnemies", "ActiveBosses" }) do
			local f = Workspace:FindFirstChild(folderName)
			if f then
				for _, m in ipairs(f:GetChildren()) do
					if m:IsA("Model") and m.Name ~= "EnergyPylon" and not m:GetAttribute("EnemyDead") then
						local er = m:FindFirstChild("Body") or m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
						local inRange = (er and myPos) and ((er.Position - myPos).Magnitude <= 120) or false
						local hl = m:FindFirstChild("InstinctHighlight")
						local tag = er and er:FindFirstChild("KenV2InfoTag")
						if inRange then
							if not hl then
								hl = Instance.new("Highlight")
								hl.Name = "InstinctHighlight"
								hl.Adornee = m
								hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
								hl.FillColor = (folderName == "ActiveBosses") and Color3.fromRGB(255, 92, 118) or Color3.fromRGB(54, 198, 255)
								hl.FillTransparency = 0.58
								hl.OutlineColor = Color3.fromRGB(168, 240, 255)
								hl.OutlineTransparency = 0.08
								hl.Parent = m
							end
							hl.Enabled = true

							if er and not tag then
								tag = Instance.new("BillboardGui")
								tag.Name = "KenV2InfoTag"
								tag.Size = UDim2.fromOffset(230, 38)
								tag.StudsOffset = Vector3.new(0, 5.4, 0)
								tag.AlwaysOnTop = true
								tag.MaxDistance = 125
								tag.Parent = er

								local bg = Instance.new("Frame")
								bg.Size = UDim2.fromScale(1, 1)
								bg.BackgroundColor3 = Color3.fromRGB(10, 20, 34)
								bg.BackgroundTransparency = 0.24
								bg.BorderSizePixel = 0
								bg.Parent = tag
								local cr = Instance.new("UICorner")
								cr.CornerRadius = UDim.new(0, 6)
								cr.Parent = bg
								local st = Instance.new("UIStroke")
								st.Color = Color3.fromRGB(82, 212, 255)
								st.Thickness = 1.2
								st.Parent = bg

								local lbl = Instance.new("TextLabel")
								lbl.Name = "Meta"
								lbl.Size = UDim2.fromScale(1, 1)
								lbl.BackgroundTransparency = 1
								lbl.Font = Enum.Font.GothamBold
								lbl.TextSize = 11
								lbl.TextColor3 = Color3.fromRGB(220, 246, 255)
								lbl.Parent = bg
							end
							if tag then
								tag.Enabled = not photoOn
								local dispName, lv, style, hp, maxHp = getEnemyMetaSummary(m)
								local bg = tag:FindFirstChildOfClass("Frame")
								local lbl = bg and bg:FindFirstChild("Meta")
								if lbl then
									if kenV2 and hp and maxHp and maxHp > 0 then
										local pct = math.clamp(math.floor((hp / maxHp) * 100 + 0.5), 0, 100)
										lbl.Text = string.format("Lv.%d %s [%s] • %d%%", lv, dispName, style, pct)
									else
										lbl.Text = string.format("Lv.%d %s [%s]", lv, dispName, style)
									end
								end
							end
						else
							if hl then hl.Enabled = false end
							if tag then tag.Enabled = false end
						end
					end
				end
			end
		end
	elseif lastKenActive or (cc and cc.Enabled) then
		if cc then cc.Enabled = false end
		for _, folderName in ipairs({ "ActiveEnemies", "ActiveBosses" }) do
			local f = Workspace:FindFirstChild(folderName)
			if f then
				for _, m in ipairs(f:GetChildren()) do
					local hl = m:FindFirstChild("InstinctHighlight")
					if hl then hl:Destroy() end
					local tag = m:FindFirstChild("KenV2InfoTag", true)
					if tag then tag:Destroy() end
				end
			end
		end
	end
	lastKenActive = (active == true)
end

-- Haoshoku [H] Expanding Crimson-Black Conqueror Pressure Dome + Jagged 3D Lightning Arcs
function SkybreakClientVFX.SpawnHaoshokuBurst(centerPos, isLocalCaster)
	if typeof(centerPos) ~= "Vector3" then return end
	UniversalVFXOverhaul.SpawnHaoshokuConqueror(centerPos, isLocalCaster)
end

-- ============================================================================
-- #43. ABYSSAL SOVEREIGN DRAGON HYBRID (TIER 1), FULL SOVEREIGN (TIER 2) & FURY HUD
-- ============================================================================
local dragonFuryGui = nil
local dragonFuryFill = nil
local dragonFuryLabel = nil
local dragonTierBadge = nil
local activeDragonRig = nil
local activeDragonTier = 0

local function resolveDragonState(ch)
	local eq = (ch and ch:GetAttribute("EquippedFruit")) or (localPlayer and localPlayer:GetAttribute("EquippedFruit")) or ""
	local held = (ch and ch:GetAttribute("HeldFruit")) or (localPlayer and localPlayer:GetAttribute("HeldFruit")) or ""
	local tf = tostring((ch and ch:GetAttribute("FruitTransform")) or (localPlayer and localPlayer:GetAttribute("FruitTransform")) or "")
	local rawTier = tonumber((ch and ch:GetAttribute("DragonFormTier")) or (localPlayer and localPlayer:GetAttribute("DragonFormTier")))
	local tier = 0
	if rawTier and rawTier >= 2 then
		tier = 2
	elseif rawTier and rawTier == 1 then
		tier = 1
	elseif tf == "AbyssalSovereign" or tf == "DragonFull" then
		tier = 2
	elseif tf == "AbyssalDragonHybrid" or tf == "DragonHybrid" then
		tier = 1
	end
	local isDragonEquipped = (resolveFruitKey(eq) == "AbyssalSovereignCore")
		or (resolveFruitKey(held) == "AbyssalSovereignCore")
		or (tier > 0)
	local fury = tonumber(
		(ch and (ch:GetAttribute("FuryMeter") or ch:GetAttribute("DragonFury") or ch:GetAttribute("Fury") or ch:GetAttribute("AwakeningMeter")))
		or (localPlayer and (localPlayer:GetAttribute("FuryMeter") or localPlayer:GetAttribute("DragonFury") or localPlayer:GetAttribute("Fury") or localPlayer:GetAttribute("AwakeningMeter")))
	) or (tier == 2 and 100 or (tier == 1 and 65 or 40))
	return isDragonEquipped, tier, math.clamp(fury, 0, 100)
end

local function ensureDragonFuryHUD()
	local pgui = localPlayer and localPlayer:FindFirstChildOfClass("PlayerGui")
	if not pgui then return nil end
	if dragonFuryGui and dragonFuryGui.Parent then return dragonFuryGui end

	local sg = Instance.new("ScreenGui")
	sg.Name = "SkybreakDragonFuryGui"
	sg.IgnoreGuiInset = false
	sg.ResetOnSpawn = false
	sg.DisplayOrder = 18
	sg.Enabled = false
	sg.Parent = pgui

	local bar = Instance.new("Frame")
	bar.Name = "FuryContainer"
	bar.AnchorPoint = Vector2.new(0.5, 1)
	bar.Position = UDim2.new(0.5, 152, 1, -144)
	bar.Size = UDim2.fromOffset(236, 24)
	bar.BackgroundColor3 = Color3.fromRGB(14, 10, 24)
	bar.BackgroundTransparency = 0.14
	bar.BorderSizePixel = 0
	bar.Parent = sg

	local cr = Instance.new("UICorner")
	cr.CornerRadius = UDim.new(0, 6)
	cr.Parent = bar

	local st = Instance.new("UIStroke")
	st.Color = Color3.fromRGB(178, 104, 255)
	st.Thickness = 1.4
	st.Parent = bar

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.Position = UDim2.fromOffset(4, 4)
	track.Size = UDim2.new(1, -8, 1, -8)
	track.BackgroundColor3 = Color3.fromRGB(28, 18, 44)
	track.BorderSizePixel = 0
	track.ClipsDescendants = true
	track.Parent = bar
	local tcr = Instance.new("UICorner")
	tcr.CornerRadius = UDim.new(0, 4)
	tcr.Parent = track

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(0.4, 1)
	fill.BackgroundColor3 = Color3.fromRGB(168, 86, 252)
	fill.BorderSizePixel = 0
	fill.Parent = track
	local fcr = Instance.new("UICorner")
	fcr.CornerRadius = UDim.new(0, 4)
	fcr.Parent = fill
	local fgrad = Instance.new("UIGradient")
	fgrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(132, 62, 238)),
		ColorSequenceKeypoint.new(0.65, Color3.fromRGB(196, 108, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 206, 86)),
	})
	fgrad.Parent = fill

	local lbl = Instance.new("TextLabel")
	lbl.Name = "FuryText"
	lbl.Position = UDim2.fromOffset(10, 0)
	lbl.Size = UDim2.new(0.66, -10, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 11
	lbl.TextXAlignment = Enum.TextXAlignment.Left
	lbl.TextColor3 = Color3.fromRGB(244, 236, 255)
	lbl.TextStrokeTransparency = 0.25
	lbl.Text = "DRAGON FURY  40%"
	lbl.Parent = bar

	local badge = Instance.new("TextLabel")
	badge.Name = "TierBadge"
	badge.AnchorPoint = Vector2.new(1, 0.5)
	badge.Position = UDim2.new(1, -8, 0.5, 0)
	badge.Size = UDim2.fromOffset(74, 16)
	badge.BackgroundColor3 = Color3.fromRGB(48, 26, 78)
	badge.Font = Enum.Font.GothamBold
	badge.TextSize = 10
	badge.TextColor3 = Color3.fromRGB(255, 212, 98)
	badge.Text = "HUMAN"
	badge.Parent = bar
	local bcr = Instance.new("UICorner")
	bcr.CornerRadius = UDim.new(0, 4)
	bcr.Parent = badge

	dragonFuryGui = sg
	dragonFuryFill = fill
	dragonFuryLabel = lbl
	dragonTierBadge = badge
	return sg
end

local function clearDragonRig()
	if activeDragonRig then
		if activeDragonRig.Model and activeDragonRig.Model.Parent then
			activeDragonRig.Model:Destroy()
		end
		activeDragonRig = nil
	end
	activeDragonTier = 0
end

local function buildHybridDragonRig(ch)
	local head = ch:FindFirstChild("Head")
	local torso = ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso") or ch:FindFirstChild("HumanoidRootPart")
	if not torso then return nil end

	local model = Instance.new("Model")
	model.Name = "SkybreakDragonHybridRig"
	model.Parent = ch

	local voidCol = Color3.fromRGB(36, 20, 62)
	local goldCol = Color3.fromRGB(246, 194, 78)
	local glowCol = Color3.fromRGB(168, 86, 252)

	local function weldPart(base, sz, offsetCF, col, mat, shape)
		local p = Instance.new("Part")
		p.Size = sz
		p.CFrame = base.CFrame * offsetCF
		p.Color = col
		p.Material = mat or Enum.Material.SmoothPlastic
		p.Shape = shape or Enum.PartType.Block
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.Massless = true
		p.CastShadow = false
		p.Parent = model
		local w = Instance.new("WeldConstraint")
		w.Part0 = base
		w.Part1 = p
		w.Parent = p
		return p
	end

	-- Swept Draconic Horns + Crown Gem
	if head then
		for side = -1, 1, 2 do
			weldPart(head, Vector3.new(0.24, 0.95, 0.28), CFrame.new(side * 0.56, 0.72, 0.08) * CFrame.Angles(-0.52, 0, -side * 0.34), voidCol, Enum.Material.Metal)
			weldPart(head, Vector3.new(0.16, 0.75, 0.20), CFrame.new(side * 0.78, 1.32, 0.36) * CFrame.Angles(-0.78, 0, -side * 0.22), goldCol, Enum.Material.Metal)
		end
		weldPart(head, Vector3.new(0.22, 0.32, 0.14), CFrame.new(0, 0.52, -0.56), glowCol, Enum.Material.ForceField)
	end

	-- Twin Draconic Wing-Blades
	local wingBlades = {}
	for side = -1, 1, 2 do
		for rib = 1, 3 do
			local blade = weldPart(
				torso,
				Vector3.new(0.14, 0.42 + rib * 0.12, 2.2 + rib * 0.55),
				CFrame.new(side * (0.9 + rib * 0.52), 0.55 - rib * 0.16, 0.75 + rib * 0.28) * CFrame.Angles(0.25, side * (0.68 + rib * 0.14), side * 0.18),
				(rib == 2) and glowCol or voidCol,
				(rib == 2) and Enum.Material.ForceField or Enum.Material.SmoothPlastic
			)
			table.insert(wingBlades, blade)
		end
	end

	-- Articulated Draconic Tail + Orbiting Abyssal Ember Ring (animated in RenderStepped)
	local tailNodes = {}
	for i = 1, 5 do
		local seg = makePart(
			"HybridTail_" .. i,
			Enum.PartType.Block,
			Vector3.new(0.46 - i * 0.05, 0.42 - i * 0.05, 1.05),
			torso.CFrame,
			(i == 5) and goldCol or voidCol,
			0.06,
			(i == 5) and Enum.Material.Metal or Enum.Material.SmoothPlastic,
			model
		)
		table.insert(tailNodes, seg)
	end
	local emberRing = makePart("HybridEmberHalo", Enum.PartType.Cylinder, Vector3.new(0.14, 5.2, 5.2), torso.CFrame, glowCol, 0.32, Enum.Material.ForceField, model)

	return {
		Tier = 1,
		Model = model,
		Torso = torso,
		TailNodes = tailNodes,
		EmberRing = emberRing,
		Wings = wingBlades,
	}
end

local function buildFullSovereignDragonRig(ch)
	local root = ch:FindFirstChild("HumanoidRootPart")
	if not root then return nil end

	local model = Instance.new("Model")
	model.Name = "SkybreakFullSovereignDragon"
	model.Parent = ensureTempFolder("SovereignDragons")

	local voidScale = Color3.fromRGB(28, 16, 52)
	local royalGold = Color3.fromRGB(246, 196, 76)
	local abyssGlow = Color3.fromRGB(164, 82, 252)
	local cyanEye = Color3.fromRGB(94, 238, 255)

	-- Articulated Head Assembly (anchored parts updated cleanly as rigid offsets from headCF)
	local headOffsets = {}
	local function addHeadPiece(name, sz, offCF, col, mat, shape)
		local p = makePart(name, shape or Enum.PartType.Block, sz, root.CFrame * offCF, col, 0.04, mat or Enum.Material.SmoothPlastic, model)
		table.insert(headOffsets, { Part = p, Offset = offCF })
		return p
	end

	local headCore = addHeadPiece("DragonSkull", Vector3.new(3.2, 2.5, 3.8), CFrame.new(0, 0, 0), voidScale, Enum.Material.SmoothPlastic)
	makeSafeLight(headCore, abyssGlow, 1.25, 15, 0)
	addHeadPiece("UpperSnout", Vector3.new(2.3, 1.35, 3.4), CFrame.new(0, -0.15, -3.1), voidScale, Enum.Material.SmoothPlastic)
	addHeadPiece("LowerJaw", Vector3.new(2.0, 0.85, 2.9), CFrame.new(0, -1.05, -2.7) * CFrame.Angles(0.16, 0, 0), royalGold, Enum.Material.Metal)
	addHeadPiece("SovereignCrest", Vector3.new(0.45, 1.5, 2.4), CFrame.new(0, 1.65, 0.2) * CFrame.Angles(-0.32, 0, 0), royalGold, Enum.Material.Metal, Enum.PartType.Wedge)
	for side = -1, 1, 2 do
		addHeadPiece("Eye_" .. side, Vector3.new(0.32, 0.42, 0.78), CFrame.new(side * 1.52, 0.35, -1.35), cyanEye, Enum.Material.ForceField)
		addHeadPiece("HornBase_" .. side, Vector3.new(0.55, 2.8, 0.65), CFrame.new(side * 1.25, 1.85, 1.15) * CFrame.Angles(-0.75, 0, -side * 0.35), royalGold, Enum.Material.Metal)
		addHeadPiece("HornTip_" .. side, Vector3.new(0.34, 2.4, 0.42), CFrame.new(side * 1.75, 3.25, 2.85) * CFrame.Angles(-1.05, 0, -side * 0.22), abyssGlow, Enum.Material.ForceField)
		addHeadPiece("Whisker_" .. side, Vector3.new(0.18, 0.18, 2.8), CFrame.new(side * 1.35, -0.35, -4.1) * CFrame.Angles(0.15, side * 0.48, 0), royalGold, Enum.Material.Metal)
	end

	-- 8 Articulated Serpentine Spine Segments + Dorsal Spines + Sweeping Wings + 4 Clawed Limbs
	local spineSegments = {}
	for i = 1, 8 do
		local t = (i - 1) / 7
		local w = 3.1 - t * 1.9
		local h = 2.7 - t * 1.7
		local len = 3.9 - t * 0.7
		local seg = makePart("Spine_" .. i, Enum.PartType.Block, Vector3.new(w, h, len), root.CFrame, voidScale, 0.05, Enum.Material.SmoothPlastic, model)
		local belly = makePart("Belly_" .. i, Enum.PartType.Block, Vector3.new(w * 0.78, 0.38, len * 0.92), root.CFrame, royalGold, 0.06, Enum.Material.Metal, model)
		local fin = makePart("Dorsal_" .. i, Enum.PartType.Wedge, Vector3.new(0.36, 1.35 - t * 0.65, len * 0.68), root.CFrame, (i % 2 == 0) and abyssGlow or royalGold, 0.12, (i % 2 == 0) and Enum.Material.ForceField or Enum.Material.Metal, model)
		table.insert(spineSegments, {
			Core = seg,
			Belly = belly,
			Fin = fin,
			Height = h,
		})
	end

	local wings = {}
	for side = -1, 1, 2 do
		local inner = makePart("WingInner_" .. side, Enum.PartType.Wedge, Vector3.new(0.32, 3.6, 7.8), root.CFrame, voidScale, 0.08, Enum.Material.SmoothPlastic, model)
		local membrane = makePart("WingMembrane_" .. side, Enum.PartType.Block, Vector3.new(0.16, 4.4, 9.2), root.CFrame, abyssGlow, 0.28, Enum.Material.ForceField, model)
		table.insert(wings, { Side = side, Inner = inner, Membrane = membrane })
	end

	local claws = {}
	for idx, segIdx in ipairs({ 2, 2, 5, 5 }) do
		local side = (idx % 2 == 1) and -1 or 1
		local limb = makePart("ClawLimb_" .. idx, Enum.PartType.Block, Vector3.new(0.75, 2.3, 0.95), root.CFrame, royalGold, 0.06, Enum.Material.Metal, model)
		table.insert(claws, { SegIndex = segIdx, Side = side, Part = limb })
	end

	return {
		Tier = 2,
		Model = model,
		Root = root,
		HeadPieces = headOffsets,
		Segments = spineSegments,
		Wings = wings,
		Claws = claws,
		TrailHistory = {},
	}
end

local function stepDragonFormAndHUD(dt)
	local ch = localPlayer and localPlayer.Character
	local isEquipped, tier, fury = resolveDragonState(ch)
	local photoOn = localPlayer and localPlayer:GetAttribute("SkybreakPhotoMode") == true

	local hud = ensureDragonFuryHUD()
	if hud then
		hud.Enabled = isEquipped and not photoOn
		if hud.Enabled then
			dragonFuryFill.Size = UDim2.fromScale(1, 1)
			if tier == 2 then
				dragonFuryLabel.Text = "DẠNG 2: THÁI CỔ LONG HOÀNG"
				dragonTierBadge.Text = "BỘ SKILL 2"
				dragonTierBadge.TextColor3 = Color3.fromRGB(255, 218, 92)
			elseif tier == 1 then
				dragonFuryLabel.Text = "DẠNG 1: BÁN LONG NHÂN"
				dragonTierBadge.Text = "BỘ SKILL 1"
				dragonTierBadge.TextColor3 = Color3.fromRGB(255, 112, 148)
			else
				dragonFuryLabel.Text = "NHẤN [V]: ĐỔI 2 DẠNG RỒNG"
				dragonTierBadge.Text = "BỘ SKILL 1"
				dragonTierBadge.TextColor3 = Color3.fromRGB(168, 198, 232)
			end
		end
	end

	if not ch or not ch.Parent then
		if activeDragonRig then clearDragonRig() end
		activeDragonTier = 0
		return
	end

	-- Fire bespoke 3-Stage Sovereign Ascension / Detransform Dispersal VFX on live tier transitions!
	if tier ~= activeDragonTier then
		local rPart = ch:FindFirstChild("HumanoidRootPart")
		if rPart then
			local isAwk = (ch:GetAttribute("FruitAwakened") == true or ch:GetAttribute("Awakened") == true)
				or (localPlayer and (localPlayer:GetAttribute("FruitAwakened") == true or localPlayer:GetAttribute("Awakened") == true))
			if tier > 0 then
				DragonSovereignVFX.SpawnTransformAscension(ch, rPart.Position, tier, isAwk, true)
			elseif activeDragonTier > 0 then
				DragonSovereignVFX.SpawnTransformAscension(ch, rPart.Position, 0, isAwk, true)
			end
		end
	end

	if tier <= 0 then
		if activeDragonRig then clearDragonRig() end
		activeDragonTier = 0
		return
	end

	-- When true sculpted 3D Blender Dragon rigs exist in DelegatedV5Sources, DelegatedV5.client.lua
	-- renders & animates the 1:1 Blender EditableMesh rig; do not overlay blocky Part cubes on top!
	local v5Sources = ReplicatedStorage:FindFirstChild("DelegatedV5Sources")
	local targetV5Asset = (tier == 1) and "AbyssalDragonHybrid" or "AbyssalSovereignDragon"
	if v5Sources and v5Sources:FindFirstChild(targetV5Asset) then
		if activeDragonRig then clearDragonRig() end
		activeDragonTier = tier
		return
	end

	if activeDragonTier ~= tier or not activeDragonRig or not activeDragonRig.Model or not activeDragonRig.Model.Parent then
		clearDragonRig()
		if tier == 1 then
			activeDragonRig = buildHybridDragonRig(ch)
		elseif tier == 2 then
			activeDragonRig = buildFullSovereignDragonRig(ch)
		end
		activeDragonTier = tier
	end

	local now = os.clock()
	if activeDragonRig and activeDragonRig.Tier == 1 then
		local torso = activeDragonRig.Torso
		if torso and torso.Parent then
			local baseCF = torso.CFrame
			for i, seg in ipairs(activeDragonRig.TailNodes) do
				if seg and seg.Parent then
					local sway = math.sin(now * 4.4 - i * 0.65) * (0.28 * i)
					local drop = -0.75 - i * 0.28
					seg.CFrame = baseCF * CFrame.new(sway, drop, 0.75 + i * 0.86) * CFrame.Angles(-0.24, sway * 0.35, 0)
				end
			end
			if activeDragonRig.EmberRing and activeDragonRig.EmberRing.Parent then
				activeDragonRig.EmberRing.CFrame = baseCF * CFrame.new(0, 0.2, 0) * CFrame.Angles(0.32, now * 1.8, math.pi * 0.5)
			end
		end
	elseif activeDragonRig and activeDragonRig.Tier == 2 then
		local root = ch:FindFirstChild("HumanoidRootPart")
		if not root then return end
		local baseCF = root.CFrame
		local headBob = math.sin(now * 3.2) * 0.65
		local headSway = math.cos(now * 2.1) * 0.85
		local headCF = baseCF * CFrame.new(headSway, 5.2 + headBob, -4.6) * CFrame.Angles(math.sin(now * 3.2) * 0.08, -headSway * 0.12, 0)

		for _, hp in ipairs(activeDragonRig.HeadPieces) do
			if hp.Part and hp.Part.Parent then
				hp.Part.CFrame = headCF * hp.Offset
			end
		end

		local segCFs = {}
		for i, seg in ipairs(activeDragonRig.Segments) do
			local phase = now * 4.2 - i * 0.62
			local waveX = math.sin(phase) * (1.15 + i * 0.22)
			local waveY = math.cos(phase * 0.85) * (0.55 + i * 0.08)
			local zBack = -1.2 + i * 3.25
			local yaw = math.cos(phase) * 0.24
			local sCF = baseCF * CFrame.new(waveX, 4.4 - i * 0.22 + waveY, zBack) * CFrame.Angles(0, -yaw, -waveX * 0.06)
			segCFs[i] = sCF
			if seg.Core and seg.Core.Parent then seg.Core.CFrame = sCF end
			if seg.Belly and seg.Belly.Parent then seg.Belly.CFrame = sCF * CFrame.new(0, -seg.Height * 0.48, 0) end
			if seg.Fin and seg.Fin.Parent then seg.Fin.CFrame = sCF * CFrame.new(0, seg.Height * 0.62, 0) end
		end

		local chestCF = segCFs[2] or headCF
		local flap = math.sin(now * 5.0) * 0.38
		for _, w in ipairs(activeDragonRig.Wings) do
			local s = w.Side
			local wingCF = chestCF * CFrame.new(s * 2.4, 0.8, 0) * CFrame.Angles(0.15, s * 1.18, s * (0.25 + flap))
			if w.Inner and w.Inner.Parent then
				w.Inner.CFrame = wingCF * CFrame.new(0, 0.6, -3.6)
			end
			if w.Membrane and w.Membrane.Parent then
				w.Membrane.CFrame = wingCF * CFrame.new(0, -0.4, -5.2) * CFrame.Angles(0, s * 0.16, 0)
			end
		end

		for _, cl in ipairs(activeDragonRig.Claws) do
			local pCF = segCFs[cl.SegIndex] or chestCF
			if cl.Part and cl.Part.Parent then
				cl.Part.CFrame = pCF * CFrame.new(cl.Side * 2.1, -1.55, -0.4) * CFrame.Angles(0.35, 0, cl.Side * 0.24)
			end
		end
	end
end

-- ============================================================================
-- #12. 12 FRUITS x 5 MOVES = 60 BESPOKE MULTI-STAGE 3D SKILL VFX + 6 KATAS
-- Stage 1: Charge-Up Elemental Sigil & Telegraph
-- Stage 2: Bespoke 3D Projectile / Beam / Barrage / Domain / Construct
-- Stage 3: Impact Crater / Shockwave Ring & Clean Fade
-- Awakened V2: 1.35x Scale + Golden-Cyan Sovereign Corona Accents
-- ============================================================================

-- Explicit 60-Move Signature Catalog (12 Fruits x Z/X/C/V/F)
local FRUIT_MOVE_SPECS = {
	GaleCore = {
		Z = { Name = "Tempest Crescent", Archetype = "CrescentWave", Count = 3, Range = 30, Radius = 7 },
		X = { Name = "Cyclone Vortex", Archetype = "TornadoColumn", Count = 6, Range = 22, Radius = 11 },
		C = { Name = "Vacuum Blade Barrage", Archetype = "RapidBarrage", Count = 8, Range = 26, Radius = 8 },
		V = { Name = "Sovereign Hurricane", Archetype = "CataclysmDome", Count = 10, Range = 18, Radius = 24 },
		F = { Name = "Jetstream Slip", Archetype = "SlipstreamRush", Count = 6, Range = 26, Radius = 7 },
	},
	SandstoneCore = {
		Z = { Name = "Tectonic Fracture", Archetype = "AirCrackShatter", Count = 6, Range = 24, Radius = 10 },
		X = { Name = "Dune Obelisk Surge", Archetype = "GroundSpireLine", Count = 6, Range = 28, Radius = 9 },
		C = { Name = "Seismic Shock Sphere", Archetype = "TwinQuakeFist", Count = 2, Range = 20, Radius = 15 },
		V = { Name = "Continental Cataclysm", Archetype = "TectonicTsunami", Count = 10, Range = 24, Radius = 26 },
		F = { Name = "Sandstorm Surge", Archetype = "WhirlwindDash", Count = 6, Range = 24, Radius = 8 },
	},
	SolarFlameCore = {
		Z = { Name = "Fireflies Volley", Archetype = "HomingOrbs", Count = 6, Range = 30, Radius = 8 },
		X = { Name = "Blazing Pillar", Archetype = "EruptionPillar", Count = 5, Range = 22, Radius = 11 },
		C = { Name = "Flame Fist Lance", Archetype = "ColossalBeam", Count = 4, Range = 34, Radius = 9 },
		V = { Name = "Solar Emperor Sun", Archetype = "DescendingSun", Count = 8, Range = 22, Radius = 25 },
		F = { Name = "Rocket Thruster", Archetype = "SlipstreamRush", Count = 6, Range = 26, Radius = 7 },
	},
	GlacierIceCore = {
		Z = { Name = "Permafrost Spears", Archetype = "CrystalLanceFan", Count = 5, Range = 30, Radius = 8 },
		X = { Name = "Glacial Surge", Archetype = "GroundSpireLine", Count = 7, Range = 28, Radius = 10 },
		C = { Name = "Cryo Falcon", Archetype = "AvianConstruct", Count = 4, Range = 32, Radius = 10 },
		V = { Name = "Absolute Zero Epoch", Archetype = "FrostNovaDomain", Count = 12, Range = 20, Radius = 26 },
		F = { Name = "Glacier Skate", Archetype = "IceTrackDash", Count = 6, Range = 24, Radius = 7 },
	},
	CelestialLightCore = {
		Z = { Name = "Photon Ray", Archetype = "LaserBeam", Count = 3, Range = 38, Radius = 7 },
		X = { Name = "Sacred Mirror Barrage", Archetype = "MirrorVolley", Count = 9, Range = 30, Radius = 11 },
		C = { Name = "Lightspeed Judgment Kick", Archetype = "SkyDropPillar", Count = 4, Range = 26, Radius = 13 },
		V = { Name = "Astral Starfall", Archetype = "SkyRainBarrage", Count = 12, Range = 24, Radius = 24 },
		F = { Name = "Photon Zigzag", Archetype = "LightReflectDash", Count = 4, Range = 30, Radius = 6 },
	},
	StarforgedMagmaCore = {
		Z = { Name = "Molten Hound", Archetype = "BeastJaws", Count = 3, Range = 28, Radius = 9 },
		X = { Name = "Caldera Geyser", Archetype = "EruptionPillar", Count = 6, Range = 22, Radius = 12 },
		C = { Name = "Volcanic Fist Shower", Archetype = "RapidBarrage", Count = 7, Range = 28, Radius = 10 },
		V = { Name = "Starforged Meteor Rain", Archetype = "MeteorCataclysm", Count = 8, Range = 24, Radius = 25 },
		F = { Name = "Magma Jet Plume", Archetype = "SlipstreamRush", Count = 6, Range = 24, Radius = 8 },
	},
	ThunderRumbleCore = {
		Z = { Name = "Lightning Javelin", Archetype = "ZigzagBolt", Count = 5, Range = 36, Radius = 8 },
		X = { Name = "Thundercloud Strike", Archetype = "SkyDropPillar", Count = 5, Range = 26, Radius = 13 },
		C = { Name = "Storm Dragon Surge", Archetype = "SerpentRush", Count = 7, Range = 32, Radius = 10 },
		V = { Name = "Raigo Thunder Globe", Archetype = "DescendingSun", Count = 10, Range = 22, Radius = 27 },
		F = { Name = "Volt Blink", Archetype = "LightReflectDash", Count = 5, Range = 28, Radius = 7 },
	},
	AstralGravityCore = {
		Z = { Name = "Graviton Push", Archetype = "CrescentWave", Count = 4, Range = 28, Radius = 9 },
		X = { Name = "Singularity Well", Archetype = "GravityCrushZone", Count = 6, Range = 22, Radius = 14 },
		C = { Name = "Orbital Asteroid Call", Archetype = "MeteorCataclysm", Count = 4, Range = 24, Radius = 14 },
		V = { Name = "Planetary Devastation", Archetype = "MeteorCataclysm", Count = 9, Range = 26, Radius = 26 },
		F = { Name = "Boulder Glide", Archetype = "WhirlwindDash", Count = 5, Range = 24, Radius = 8 },
	},
	DimensionalPortalCore = {
		Z = { Name = "Spatial Sever", Archetype = "AirCrackShatter", Count = 5, Range = 28, Radius = 9 },
		X = { Name = "Warp Gate Assault", Archetype = "PortalRingStrike", Count = 4, Range = 28, Radius = 11 },
		C = { Name = "Tesseract Prison", Archetype = "CubeSanctuary", Count = 6, Range = 22, Radius = 13 },
		V = { Name = "Dimensional Collapse", Archetype = "CataclysmDome", Count = 10, Range = 20, Radius = 25 },
		F = { Name = "Rift Fold", Archetype = "PortalGateDash", Count = 3, Range = 28, Radius = 7 },
	},
	SolarTitanCore = {
		Z = { Name = "Golden Palm Impact", Archetype = "TwinQuakeFist", Count = 2, Range = 24, Radius = 11 },
		X = { Name = "Radiant Halo Slam", Archetype = "SkyDropPillar", Count = 5, Range = 20, Radius = 15 },
		C = { Name = "Celestial Judgment Beam", Archetype = "ColossalBeam", Count = 5, Range = 34, Radius = 11 },
		V = { Name = "Twilight Nirvana Domain", Archetype = "CataclysmDome", Count = 12, Range = 18, Radius = 27 },
		F = { Name = "Lotus Leap", Archetype = "WhirlwindDash", Count = 5, Range = 24, Radius = 9 },
	},
	AetherflowCore = {
		Z = { Name = "Fried Mochi Missile", Archetype = "ColossalBeam", Count = 3, Range = 30, Radius = 8 },
		X = { Name = "Sticky Tendril Snare", Archetype = "GroundSpireLine", Count = 6, Range = 26, Radius = 10 },
		C = { Name = "Carved Donut Spin", Archetype = "WheelRollSmash", Count = 7, Range = 28, Radius = 11 },
		V = { Name = "Aether Mirror Gatling", Archetype = "PortalFistBarrage", Count = 10, Range = 24, Radius = 24 },
		F = { Name = "Spiked Roller Dash", Archetype = "WheelRollSmash", Count = 6, Range = 26, Radius = 8 },
	},
	AbyssalSovereignCore = {
		Z = { Name = "Heatwave Dragon Breath", Archetype = "ColossalBeam", Count = 5, Range = 36, Radius = 10 },
		X = { Name = "Draconic Claw Dive", Archetype = "BeastJaws", Count = 4, Range = 28, Radius = 12 },
		C = { Name = "Infernal Twister Coils", Archetype = "TornadoColumn", Count = 8, Range = 24, Radius = 15 },
		V = { Name = "Sovereign Apocalypse", Archetype = "DescendingSun", Count = 12, Range = 26, Radius = 28 },
		F = { Name = "Soaring Sovereign Rush", Archetype = "SerpentRush", Count = 7, Range = 30, Radius = 9 },
	},
}

local STYLE_PROFILES = {
	skyborn_combat = { Primary = Color3.fromRGB(255, 214, 96), Secondary = Color3.fromRGB(255, 244, 186), Style = "PalmRings" },
	jade_dragon = { Primary = Color3.fromRGB(64, 238, 168), Secondary = Color3.fromRGB(196, 255, 224), Style = "WaterVortex" },
	thunder_talon = { Primary = Color3.fromRGB(84, 198, 255), Secondary = Color3.fromRGB(196, 128, 255), Style = "VoltClawSlashes" },
	solar_ashura = { Primary = Color3.fromRGB(255, 138, 52), Secondary = Color3.fromRGB(255, 224, 118), Style = "DraconicTalons" },
	celestial_godhuman = { Primary = Color3.fromRGB(255, 224, 108), Secondary = Color3.fromRGB(92, 236, 255), Style = "GodhumanPrism" },
	SkybornCombat = { Primary = Color3.fromRGB(255, 214, 96), Secondary = Color3.fromRGB(255, 244, 186), Style = "PalmRings" },
	SkyStep = { Primary = Color3.fromRGB(255, 138, 52), Secondary = Color3.fromRGB(255, 224, 118), Style = "BlazeKickArcs" },
	GlacialFist = { Primary = Color3.fromRGB(98, 226, 255), Secondary = Color3.fromRGB(214, 248, 255), Style = "WaterVortex" },
	GlacialKarate = { Primary = Color3.fromRGB(98, 226, 255), Secondary = Color3.fromRGB(214, 248, 255), Style = "WaterVortex" },
	ElectricClaw = { Primary = Color3.fromRGB(84, 198, 255), Secondary = Color3.fromRGB(196, 128, 255), Style = "VoltClawSlashes" },
	AbyssalTalon = { Primary = Color3.fromRGB(236, 68, 92), Secondary = Color3.fromRGB(162, 78, 252), Style = "DraconicTalons" },
	DragonTalon = { Primary = Color3.fromRGB(236, 68, 92), Secondary = Color3.fromRGB(255, 178, 72), Style = "DraconicTalons" },
	SanguineVoidArt = { Primary = Color3.fromRGB(224, 42, 78), Secondary = Color3.fromRGB(58, 18, 42), Style = "DraconicTalons" },
	CelestialGodhuman = { Primary = Color3.fromRGB(255, 224, 108), Secondary = Color3.fromRGB(92, 236, 255), Style = "GodhumanPrism" },
	GodhumanSkyborn = { Primary = Color3.fromRGB(255, 224, 108), Secondary = Color3.fromRGB(92, 236, 255), Style = "GodhumanPrism" },
}

-- Stage 1: Charge-Up Elemental Sigil & Floor Rune Telegraph
local function spawnStage1Sigil(originCF, prof, scale, isAwakened)
	local pos = originCF.Position
	local gPos = findGroundPos(pos)
	local sigil = makePart(
		"Stage1_Sigil",
		Enum.PartType.Cylinder,
		Vector3.new(0.14, 2.2 * scale, 2.2 * scale),
		CFrame.new(gPos + Vector3.new(0, 0.14, 0)) * CFrame.Angles(0, 0, math.pi * 0.5),
		prof.Primary,
		0.18,
		Enum.Material.ForceField
	)
	makeSafeLight(sigil, prof.Primary, 1.15, 12, 0.28)
	TweenService:Create(sigil, TweenInfo.new(0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.08, 7.2 * scale, 7.2 * scale),
		Transparency = 0.85,
	}):Play()
	Debris:AddItem(sigil, 0.30)

	local spokeCount = isLowFX() and 3 or 4
	for i = 1, spokeCount do
		local ang = (i - 1) * (math.pi / spokeCount)
		local bar = makePart(
			"SigilRune",
			Enum.PartType.Block,
			Vector3.new(0.18 * scale, 0.10, 5.4 * scale),
			CFrame.new(gPos + Vector3.new(0, 0.16, 0)) * CFrame.Angles(0, ang, 0),
			prof.Secondary,
			0.22,
			Enum.Material.SmoothPlastic
		)
		TweenService:Create(bar, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			CFrame = bar.CFrame * CFrame.Angles(0, 0.65, 0),
			Transparency = 1,
		}):Play()
		Debris:AddItem(bar, 0.32)
	end

	if isAwakened then
		spawnAwakenedCorona(originCF, scale, 0.46)
	end
end

-- Stage 3: Impact Crater, Shockwave Ring & Clean Fade
local function spawnStage3Aftermath(impactPos, prof, radius, scale, isAwakened, isLocal)
	local r = math.clamp((radius or 10) * scale, 5, 32)
	local gPos = findGroundPos(impactPos)
	spawnCraterRing(impactPos, prof.Primary, prof.Accent, r * 0.58, (r >= 18) and 10 or 7, 0.58)
	spawnShockRing(gPos + Vector3.new(0, 0.18, 0), nil, prof.Secondary, r * 0.25, r * 1.35, 0.26, 0.48, Enum.Material.ForceField)
	local flashNode = makePart("Stage3_CoreFade", Enum.PartType.Ball, Vector3.new(2.2, 2.2, 2.2) * scale, CFrame.new(impactPos), prof.Primary, 0.24, Enum.Material.ForceField)
	makeSafeLight(flashNode, prof.Primary, 1.35, math.min(MAX_LIGHT_RANGE, r), 0.42)
	makeBurstEmitter(flashNode, prof.Primary, prof.Secondary, 0.95 * scale, 0.08, 0.48, 10, 26, (r >= 18) and 18 or 11)
	TweenService:Create(flashNode, TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
		Size = Vector3.new(r * 0.95, r * 0.95, r * 0.95),
		Transparency = 1,
	}):Play()
	Debris:AddItem(flashNode, 0.46)

	if isAwakened then
		spawnAwakenedCorona(CFrame.new(impactPos), scale * 1.1, 0.52)
	end
	if isLocal then
		local trauma = (r >= 20) and 0.56 or ((r >= 12) and 0.36 or 0.24)
		local fov = (r >= 20) and 5.5 or 2.0
		emitCameraTrauma(trauma, fov)
	end
end

local function safeLookAt(fromPos, toPos, fallbackDir)
	local d = toPos - fromPos
	local dir = d.Magnitude > 1e-3 and d.Unit or ((fallbackDir and fallbackDir.Magnitude > 1e-3) and fallbackDir.Unit or Vector3.new(0, 0, -1))
	local up = math.abs(dir.Y) > 0.99 and Vector3.new(0, 0, 1) or Vector3.new(0, 1, 0)
	return CFrame.lookAt(fromPos, fromPos + dir, up)
end

-- Stage 2: Bespoke 3D Archetype Constructors (covers all 60 Fruit Moves uniquely via prof + spec)
local function executeFruitArchetype(arch, startPos, endPos, lookDir, prof, spec, scale, isAwakened, isLocal)
	lookDir = (lookDir and lookDir.Magnitude > 1e-3) and lookDir.Unit or Vector3.new(0, 0, -1)
	local dist = math.max(8, math.min(44, (endPos - startPos).Magnitude))
	if dist < 8.5 then
		endPos = startPos + lookDir * ((spec.Range or 24) * scale)
		dist = math.max(0.1, (endPos - startPos).Magnitude)
	end
	local pathCF = safeLookAt(startPos, endPos, lookDir)
	local count = spec.Count or 5
	if isLowFX() then count = math.max(2, math.ceil(count * 0.55)) end

	if arch == "CrescentWave" then
		for i = 1, count do
			local spread = (i - (count + 1) * 0.5) * 0.22
			local dir = (pathCF * CFrame.Angles(0, spread, 0)).LookVector
			local dst = startPos + dir * dist
			local blade = makePart("CrescentArc", Enum.PartType.Cylinder, Vector3.new(0.32 * scale, 6.2 * scale, 6.2 * scale), safeLookAt(startPos, dst, dir) * CFrame.Angles(0, math.pi * 0.5, (i % 2 == 0 and 0.35 or -0.35)), (i % 2 == 0) and prof.Secondary or prof.Primary, 0.16, prof.Mat)
			TweenService:Create(blade, TweenInfo.new(0.34, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				CFrame = safeLookAt(dst, dst + dir, dir) * CFrame.Angles(0, math.pi * 0.5, (i % 2 == 0 and 0.55 or -0.55)),
				Size = Vector3.new(0.18 * scale, 10.4 * scale, 10.4 * scale),
				Transparency = 0.92,
			}):Play()
			Debris:AddItem(blade, 0.38)
		end
		task.delay(0.28, function() spawnStage3Aftermath(endPos, prof, spec.Radius, scale, isAwakened, isLocal) end)

	elseif arch == "TornadoColumn" then
		local center = endPos
		local gPos = findGroundPos(center)
		for i = 1, count do
			local hFrac = i / count
			local rad = (3.0 + hFrac * 6.8) * scale
			local ring = makePart("VortexTier", Enum.PartType.Cylinder, Vector3.new(0.45 * scale, rad, rad), CFrame.new(gPos + Vector3.new(0, hFrac * 15 * scale, 0)) * CFrame.Angles(0.14, i * 0.6, math.pi * 0.5), (i % 2 == 0) and prof.Primary or prof.Secondary, 0.22, Enum.Material.ForceField)
			TweenService:Create(ring, TweenInfo.new(0.62, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				CFrame = ring.CFrame * CFrame.new(2.2, 0, 0) * CFrame.Angles(0, 2.6, 0),
				Size = Vector3.new(0.18, rad * 1.55, rad * 1.55),
				Transparency = 1,
			}):Play()
			Debris:AddItem(ring, 0.66)
		end
		spawnStage3Aftermath(center, prof, spec.Radius, scale, isAwakened, isLocal)

	elseif arch == "RapidBarrage" or arch == "HomingOrbs" or arch == "MirrorVolley" then
		for i = 1, count do
			task.delay((i - 1) * 0.038, function()
				local ang = (i - 1) * ((math.pi * 2) / count)
				local off = pathCF.RightVector * (math.cos(ang) * 2.6 * scale) + pathCF.UpVector * (math.sin(ang) * 1.8 * scale + 1.2)
				local p0 = startPos + off
				local p1 = endPos + off * 0.35
				local shape = (arch == "HomingOrbs") and Enum.PartType.Ball or Enum.PartType.Block
				local sz = (arch == "HomingOrbs") and Vector3.new(1.5, 1.5, 1.5) * scale or Vector3.new(0.65, 0.65, 3.8) * scale
				local proj = makePart("BarrageShot", shape, sz, safeLookAt(p0, p1, lookDir), (i % 2 == 0) and prof.Primary or prof.Secondary, 0.14, prof.Mat)
				TweenService:Create(proj, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					CFrame = safeLookAt(p1, p1 + lookDir, lookDir),
					Transparency = 0.6,
				}):Play()
				Debris:AddItem(proj, 0.27)
				if i == count then
					task.delay(0.22, function() spawnStage3Aftermath(endPos, prof, spec.Radius, scale, isAwakened, isLocal) end)
				end
			end)
		end

	elseif arch == "AirCrackShatter" then
		for side = -1, 1, 2 do
			local origin = startPos + pathCF.RightVector * (side * 2.2) + Vector3.new(0, 1.2, 0)
			local pane = makePart("FracturePane", Enum.PartType.Cylinder, Vector3.new(0.14, 7.2 * scale, 7.2 * scale), safeLookAt(origin, endPos, lookDir) * CFrame.Angles(0, math.pi * 0.5, 0), prof.Secondary, 0.25, Enum.Material.Glass)
			TweenService:Create(pane, TweenInfo.new(0.42, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = Vector3.new(0.06, 13.5 * scale, 13.5 * scale),
				Transparency = 1,
			}):Play()
			Debris:AddItem(pane, 0.45)
			for b = 1, 4 do
				local bAng = b * 1.57 + side * 0.4
				local crack = makePart("AirCrackLine", Enum.PartType.Block, Vector3.new(0.16, 0.16, 4.8 * scale), CFrame.new(origin) * CFrame.Angles(bAng, side * 0.6, bAng * 0.5), prof.Primary, 0.10, Enum.Material.SmoothPlastic)
				TweenService:Create(crack, TweenInfo.new(0.38), { Size = Vector3.new(0.04, 0.04, 8.2 * scale), Transparency = 1 }):Play()
				Debris:AddItem(crack, 0.42)
			end
		end
		spawnStage3Aftermath(endPos, prof, spec.Radius, scale, isAwakened, isLocal)

	elseif arch == "GroundSpireLine" or arch == "CrystalLanceFan" then
		for i = 1, count do
			task.delay((i - 1) * 0.042, function()
				local frac = i / count
				local p = startPos:Lerp(endPos, frac)
				local gPos = findGroundPos(p)
				local h = (4.2 + frac * 4.8) * scale
				local spire = makePart("ElementalSpire", Enum.PartType.Wedge, Vector3.new(1.8 * scale, h, 2.2 * scale), safeLookAt(gPos - Vector3.new(0, h * 0.5, 0), gPos + lookDir, lookDir) * CFrame.Angles(-0.22, 0, 0), (i % 2 == 0) and prof.Primary or prof.Secondary, 0.10, prof.Mat)
				TweenService:Create(spire, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					CFrame = safeLookAt(gPos + Vector3.new(0, h * 0.44, 0), gPos + Vector3.new(0, h * 0.44, 0) + lookDir, lookDir) * CFrame.Angles(-0.22, 0, 0),
				}):Play()
				task.delay(0.34, function()
					if spire and spire.Parent then
						TweenService:Create(spire, TweenInfo.new(0.22), { Transparency = 1 }):Play()
					end
				end)
				Debris:AddItem(spire, 0.60)
			end)
		end
		task.delay(0.26, function() spawnStage3Aftermath(endPos, prof, spec.Radius, scale, isAwakened, isLocal) end)

	elseif arch == "TwinQuakeFist" or arch == "BeastJaws" or arch == "AvianConstruct" then
		local mid = startPos + lookDir * 3.2
		local construct = makePart("ConstructCore", (arch == "TwinQuakeFist") and Enum.PartType.Ball or Enum.PartType.Wedge, Vector3.new(3.6, 2.8, 4.6) * scale, safeLookAt(mid, endPos, lookDir), prof.Primary, 0.12, prof.Mat)
		local wingL = makePart("ConstructFlankL", Enum.PartType.Wedge, Vector3.new(0.6, 2.2, 4.2) * scale, safeLookAt(mid, endPos, lookDir) * CFrame.new(-2.4 * scale, 0.3, 0.4) * CFrame.Angles(0, 0.45, 0), prof.Secondary, 0.16, Enum.Material.ForceField)
		local wingR = makePart("ConstructFlankR", Enum.PartType.Wedge, Vector3.new(0.6, 2.2, 4.2) * scale, safeLookAt(mid, endPos, lookDir) * CFrame.new(2.4 * scale, 0.3, 0.4) * CFrame.Angles(0, -0.45, 0), prof.Secondary, 0.16, Enum.Material.ForceField)
		for _, part in ipairs({ construct, wingL, wingR }) do
			local off = mid - part.Position
			TweenService:Create(part, TweenInfo.new(0.30, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				CFrame = safeLookAt(endPos - off, endPos - off + lookDir, lookDir),
				Transparency = 0.75,
			}):Play()
			Debris:AddItem(part, 0.34)
		end
		task.delay(0.28, function() spawnStage3Aftermath(endPos, prof, spec.Radius, scale, isAwakened, isLocal) end)

	elseif arch == "ColossalBeam" or arch == "LaserBeam" or arch == "ZigzagBolt" then
		local mid = (startPos + endPos) * 0.5
		local r = ((arch == "LaserBeam") and 1.55 or 3.1) * scale
		local beam = makePart("ElementalBeam", Enum.PartType.Cylinder, Vector3.new(dist, r, r), safeLookAt(mid, endPos, lookDir) * CFrame.Angles(0, math.pi * 0.5, 0), prof.Primary, 0.14, Enum.Material.ForceField)
		local inner = makePart("BeamCore", Enum.PartType.Cylinder, Vector3.new(dist, r * 0.52, r * 0.52), beam.CFrame, prof.Secondary, 0.08, Enum.Material.SmoothPlastic)
		TweenService:Create(beam, TweenInfo.new(0.38, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = Vector3.new(dist, r * 1.9, r * 1.9),
			Transparency = 1,
		}):Play()
		TweenService:Create(inner, TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = Vector3.new(dist, 0.12, 0.12),
			Transparency = 1,
		}):Play()
		Debris:AddItem(beam, 0.42)
		Debris:AddItem(inner, 0.36)
		if arch == "ZigzagBolt" then
			local prev = startPos
			for s = 1, count do
				local frac = s / count
				local jit = (s < count) and (pathCF.RightVector * ((s % 2 == 0 and 1.8 or -1.8) * scale) + Vector3.new(0, (s % 3 - 1) * 1.1, 0)) or Vector3.zero
				local nxt = startPos:Lerp(endPos, frac) + jit
				local segLen = math.max(0.05, (nxt - prev).Magnitude)
				local arc = makePart("ZigBolt", Enum.PartType.Block, Vector3.new(0.36 * scale, 0.36 * scale, segLen), safeLookAt((prev + nxt) * 0.5, nxt, lookDir), prof.Accent, 0.08, Enum.Material.SmoothPlastic)
				TweenService:Create(arc, TweenInfo.new(0.30), { Transparency = 1 }):Play()
				Debris:AddItem(arc, 0.34)
				prev = nxt
			end
		end
		spawnStage3Aftermath(endPos, prof, spec.Radius, scale, isAwakened, isLocal)

	elseif arch == "EruptionPillar" or arch == "SkyDropPillar" then
		local gPos = findGroundPos(endPos)
		local pillarH = 26 * scale
		local pillarR = 5.4 * scale
		local col = makePart("JudgmentPillar", Enum.PartType.Cylinder, Vector3.new(pillarH, pillarR * 0.35, pillarR * 0.35), CFrame.new(gPos + Vector3.new(0, pillarH * 0.5, 0)) * CFrame.Angles(0, 0, math.pi * 0.5), prof.Primary, 0.14, Enum.Material.ForceField)
		TweenService:Create(col, TweenInfo.new(0.46, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = Vector3.new(pillarH * 1.15, pillarR * 1.65, pillarR * 1.65),
			Transparency = 1,
		}):Play()
		Debris:AddItem(col, 0.50)
		spawnStage3Aftermath(endPos, prof, spec.Radius, scale, isAwakened, isLocal)

	elseif arch == "DescendingSun" or arch == "MeteorCataclysm" or arch == "SkyRainBarrage" then
		local dropCount = (arch == "DescendingSun") and 1 or math.min(count, isLowFX() and 3 or 6)
		for i = 1, dropCount do
			task.delay((i - 1) * 0.06, function()
				local ang = (i - 1) * ((math.pi * 2) / math.max(1, dropCount))
				local rad = (dropCount == 1) and 0 or (4.5 * scale)
				local dst = endPos + Vector3.new(math.cos(ang) * rad, 0, math.sin(ang) * rad)
				local skyOrigin = dst + Vector3.new(-4 * scale, 22 * scale, -3 * scale)
				local orbSz = ((dropCount == 1) and 9.5 or 3.8) * scale
				local orb = makePart("CataclysmSphere", Enum.PartType.Ball, Vector3.new(orbSz, orbSz, orbSz), CFrame.new(skyOrigin), prof.Primary, 0.08, (arch == "MeteorCataclysm") and Enum.Material.Slate or Enum.Material.ForceField)
				local shell = makePart("CataclysmShell", Enum.PartType.Ball, Vector3.new(orbSz * 1.24, orbSz * 1.24, orbSz * 1.24), CFrame.new(skyOrigin), prof.Secondary, 0.34, Enum.Material.ForceField)
				TweenService:Create(orb, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = dst }):Play()
				TweenService:Create(shell, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = dst }):Play()
				Debris:AddItem(orb, 0.36)
				Debris:AddItem(shell, 0.36)
				if i == dropCount then
					task.delay(0.31, function() spawnStage3Aftermath(endPos, prof, spec.Radius, scale, isAwakened, isLocal) end)
				end
			end)
		end

	elseif arch == "PortalRingStrike" or arch == "PortalGateDash" or arch == "PortalFistBarrage" then
		local g1 = makePart("WarpGateEntry", Enum.PartType.Cylinder, Vector3.new(0.28, 6.4 * scale, 6.4 * scale), safeLookAt(startPos + lookDir * 2, endPos, lookDir) * CFrame.Angles(0, math.pi * 0.5, 0), prof.Primary, 0.14, Enum.Material.ForceField)
		local g2 = makePart("WarpGateExit", Enum.PartType.Cylinder, Vector3.new(0.28, 6.4 * scale, 6.4 * scale), safeLookAt(endPos, endPos + lookDir, lookDir) * CFrame.Angles(0, math.pi * 0.5, 0), prof.Secondary, 0.14, Enum.Material.ForceField)
		TweenService:Create(g1, TweenInfo.new(0.45), { Size = Vector3.new(0.1, 9.2 * scale, 9.2 * scale), Transparency = 1 }):Play()
		TweenService:Create(g2, TweenInfo.new(0.45), { Size = Vector3.new(0.1, 9.2 * scale, 9.2 * scale), Transparency = 1 }):Play()
		Debris:AddItem(g1, 0.48)
		Debris:AddItem(g2, 0.48)
		if arch == "PortalFistBarrage" then
			for i = 1, count do
				task.delay((i - 1) * 0.035, function()
					local ang = i * 1.15
					local p0 = endPos + Vector3.new(math.cos(ang) * 7 * scale, 3 + (i % 3) * 1.4, math.sin(ang) * 7 * scale)
					local ring = makePart("MiniRift", Enum.PartType.Cylinder, Vector3.new(0.18, 2.8 * scale, 2.8 * scale), safeLookAt(p0, endPos, lookDir) * CFrame.Angles(0, math.pi * 0.5, 0), prof.Accent, 0.18, Enum.Material.ForceField)
					local fist = makePart("DoughFist", Enum.PartType.Ball, Vector3.new(1.8, 1.8, 2.6) * scale, safeLookAt(p0, endPos, lookDir), prof.Primary, 0.08, Enum.Material.SmoothPlastic)
					TweenService:Create(fist, TweenInfo.new(0.18), { CFrame = safeLookAt(endPos, endPos + (endPos - p0), lookDir), Transparency = 0.8 }):Play()
					TweenService:Create(ring, TweenInfo.new(0.26), { Transparency = 1 }):Play()
					Debris:AddItem(fist, 0.22)
					Debris:AddItem(ring, 0.28)
				end)
			end
		end
		task.delay(0.24, function() spawnStage3Aftermath(endPos, prof, spec.Radius, scale, isAwakened, isLocal) end)

	elseif arch == "CubeSanctuary" or arch == "GravityCrushZone" or arch == "FrostNovaDomain" or arch == "CataclysmDome" or arch == "TectonicTsunami" then
		local shape = (arch == "CubeSanctuary") and Enum.PartType.Block or Enum.PartType.Ball
		local r = (spec.Radius or 18) * scale
		local domain = makePart("DomainField", shape, Vector3.new(3, 3, 3), CFrame.new(endPos), prof.Primary, 0.30, (arch == "FrostNovaDomain") and Enum.Material.Glass or Enum.Material.ForceField)
		TweenService:Create(domain, TweenInfo.new(0.54, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = Vector3.new(r * 1.35, (arch == "GravityCrushZone") and 2.5 or r * 1.35, r * 1.35),
			CFrame = domain.CFrame * CFrame.Angles(0, 0.85, 0),
			Transparency = 1,
		}):Play()
		Debris:AddItem(domain, 0.58)
		spawnStage3Aftermath(endPos, prof, spec.Radius, scale, isAwakened, isLocal)

	else
		-- SlipstreamRush / WhirlwindDash / IceTrackDash / LightReflectDash / WheelRollSmash / SerpentRush
		for i = 1, count do
			local frac = i / count
			task.delay((i - 1) * 0.028, function()
				local p = startPos:Lerp(endPos, frac)
				local shape = (arch == "IceTrackDash") and Enum.PartType.Block or Enum.PartType.Cylinder
				local sz = (arch == "IceTrackDash") and Vector3.new(3.6 * scale, 0.45, 4.2 * scale)
					or Vector3.new(0.45 * scale, (3.6 + (arch == "WheelRollSmash" and 2.2 or 0)) * scale, (3.6 + (arch == "WheelRollSmash" and 2.2 or 0)) * scale)
				local cf = (arch == "IceTrackDash") and safeLookAt(findGroundPos(p) + Vector3.new(0, 0.18, 0), findGroundPos(p) + Vector3.new(0, 0.18, 0) + lookDir, lookDir)
					or (safeLookAt(p, p + lookDir, lookDir) * CFrame.Angles(0, (arch == "WheelRollSmash") and 0 or math.pi * 0.5, frac * 3.14))
				local seg = makePart("RushNode", shape, sz, cf, (i % 2 == 0) and prof.Primary or prof.Secondary, 0.16, prof.Mat)
				TweenService:Create(seg, TweenInfo.new(0.36, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					Size = (arch == "IceTrackDash") and Vector3.new(1.2, 0.1, 4.2 * scale) or Vector3.new(0.12, 8.2 * scale, 8.2 * scale),
					Transparency = 1,
				}):Play()
				Debris:AddItem(seg, 0.40)
			end)
		end
		task.delay(0.22, function() spawnStage3Aftermath(endPos, prof, spec.Radius, scale, isAwakened, isLocal) end)
	end
end

-- Martial Arts 6-Style Bespoke Kata Renderer
local function spawnMartialKataVFX(styleProf, moveKey, startPos, endPos, lookDir, scale, isLocal)
	lookDir = (lookDir and lookDir.Magnitude > 1e-3) and lookDir.Unit or Vector3.new(0, 0, -1)
	local prof = {
		Primary = styleProf.Primary,
		Secondary = styleProf.Secondary,
		Accent = Color3.fromRGB(48, 56, 74),
		Mat = Enum.Material.ForceField,
	}
	spawnStage1Sigil(safeLookAt(startPos, startPos + lookDir, lookDir), prof, scale * 0.85, false)
	local count = (moveKey == "V") and 9 or ((moveKey == "C") and 6 or 4)
	if isLowFX() then count = math.max(2, math.floor(count * 0.5)) end
	local dst = ((endPos - startPos).Magnitude > 3) and endPos or (startPos + lookDir * 18)

	for i = 1, count do
		task.delay((i - 1) * 0.032, function()
			local frac = i / count
			local p = startPos:Lerp(dst, frac)
			if styleProf.Style == "VoltClawSlashes" or styleProf.Style == "DraconicTalons" then
				for c = -1, 1 do
					local claw = makePart("ClawArc", Enum.PartType.Block, Vector3.new(0.18 * scale, 0.22 * scale, 5.4 * scale), safeLookAt(p, p + lookDir, lookDir) * CFrame.new(c * 0.75, 0.4, 0) * CFrame.Angles(0.22, 0, (i % 2 == 0 and 0.55 or -0.55)), (c == 0) and prof.Secondary or prof.Primary, 0.12, Enum.Material.ForceField)
					TweenService:Create(claw, TweenInfo.new(0.24), { Size = Vector3.new(0.05, 0.05, 8.2 * scale), Transparency = 1 }):Play()
					Debris:AddItem(claw, 0.28)
				end
			elseif styleProf.Style == "WaterVortex" then
				local ring = makePart("TideSpiral", Enum.PartType.Cylinder, Vector3.new(0.28, (3.2 + i * 0.8) * scale, (3.2 + i * 0.8) * scale), safeLookAt(p, p + lookDir, lookDir) * CFrame.Angles(0, math.pi * 0.5, i * 0.7), (i % 2 == 0) and prof.Primary or prof.Secondary, 0.18, Enum.Material.Glass)
				TweenService:Create(ring, TweenInfo.new(0.32), { Size = Vector3.new(0.08, 9.5 * scale, 9.5 * scale), Transparency = 1 }):Play()
				Debris:AddItem(ring, 0.36)
			else
				local wave = makePart("KataShock", Enum.PartType.Cylinder, Vector3.new(0.24, 3.8 * scale, 3.8 * scale), safeLookAt(p, p + lookDir, lookDir) * CFrame.Angles(0, math.pi * 0.5, 0), (i % 2 == 0) and prof.Secondary or prof.Primary, 0.14, Enum.Material.ForceField)
				TweenService:Create(wave, TweenInfo.new(0.30), { Size = Vector3.new(0.08, 8.8 * scale, 8.8 * scale), Transparency = 1 }):Play()
				Debris:AddItem(wave, 0.34)
			end
		end)
	end
	local rad = (moveKey == "V") and 18 or ((moveKey == "C") and 13 or 9)
	task.delay(0.20, function() spawnStage3Aftermath(dst, prof, rad, scale, moveKey == "V", isLocal) end)
end

function SkybreakClientVFX.SpawnGeppoVFX(footPos, isSkyborn, jumpIdx, rootCF)
	UniversalVFXOverhaul.SpawnGeppoStep(footPos, isSkyborn, jumpIdx, rootCF)
end

function SkybreakClientVFX.SpawnDashVFX(ch, originCF, accentColor, afterimageOnly)
	UniversalVFXOverhaul.SpawnDashSlipstream(ch, originCF, accentColor, afterimageOnly)
end

function SkybreakClientVFX.SpawnShieldBubble(targetChar, isArcane)
	UniversalVFXOverhaul.SpawnShieldBubble(targetChar, isArcane)
end

function SkybreakClientVFX.SpawnProgressionVFX(kind, ch)
	UniversalVFXOverhaul.SpawnProgressionVFX(kind, ch)
end

function SkybreakClientVFX.SpawnSkillVFX(action, pos, actorChar, fxData)
	local fx = type(fxData) == "table" and fxData or {}
	local act = tostring(action or fx.Action or fx.skillId or "Attack")
	local kind = tostring(fx.Kind or fx.kind or "")
	local actorUserId = fx.Actor or fx.Owner or fx.userId
	local isLocal = false
	if localPlayer then
		if actorChar ~= nil then
			isLocal = (actorChar == localPlayer.Character)
		elseif actorUserId ~= nil then
			isLocal = (actorUserId == localPlayer.UserId)
		else
			isLocal = true
		end
	end
	if typeof(pos) ~= "Vector3" then
		local fallbackCh = actorChar or (isLocal and localPlayer and localPlayer.Character)
		local fallbackRoot = fallbackCh and fallbackCh:FindFirstChild("HumanoidRootPart")
		pos = fallbackRoot and fallbackRoot.Position or nil
	end
	if typeof(pos) ~= "Vector3" then return end

	-- Route Logia Reflex, Instinct Dodge, Haoshoku, Haki Stage-Up, Race V4 Awakening & Sovereign Dragon Transformation directly
	if kind == "LogiaDodge" or kind == "ElementalReflex" or act == "LogiaDodge" then
		SkybreakClientVFX.SpawnLogiaReflex(pos, fx.FruitId or fx.element or fx.Element, actorChar)
		return
	end
	if kind == "InstinctDodge" or act == "InstinctDodge" or act == "InstinctToggle" then
		local ch = actorChar or (isLocal and localPlayer and localPlayer.Character)
		if act == "InstinctDodge" or kind == "InstinctDodge" then
			UniversalVFXOverhaul.SpawnDashSlipstream(ch, CFrame.new(pos), Color3.fromRGB(82, 212, 255), true)
		else
			SkybreakClientVFX.UpdateInstinctVision()
		end
		return
	end
	if act == "ConquerorHaki" or act == "ConquerorBurst" then
		SkybreakClientVFX.SpawnHaoshokuBurst(pos, isLocal)
		return
	end
	if kind == "HakiStageUp" or act == "HakiStageUp" then
		local ch = actorChar or (isLocal and localPlayer and localPlayer.Character)
		UniversalVFXOverhaul.SpawnBusoIgnite(ch, resolveHakiColor(ch), tonumber(fx.Stage) or 3)
		return
	end
	if kind == "RaceV4Unlock" or act == "RaceV4Awaken" or act == "RaceV4Unlock" then
		local ch = actorChar or (isLocal and localPlayer and localPlayer.Character)
		local rName = tostring(fx.Race or (ch and ch:GetAttribute("Race")) or (isLocal and localPlayer and localPlayer:GetAttribute("Race")) or "Skyborn")
		UniversalVFXOverhaul.SpawnRaceV4Awakening(ch, rName)
		return
	end
	if kind == "ChestOpened" or kind == "LootOrbPickup" or kind == "ShipCannonBlast" or kind == "CloudGeyserRescue" then
		UniversalVFXOverhaul.SpawnClassOrWeaponSkill(act, kind, "", actorChar, pos, fx.TargetPos or pos, Vector3.new(0, 0, -1), 1.0, false, isLocal, fx)
		return
	end

	local isAwakened = (fx.Awakened == true)
		or (actorChar and (actorChar:GetAttribute("FruitAwakened") == true or actorChar:GetAttribute("Awakened") == true))
		or (isLocal and localPlayer and (localPlayer:GetAttribute("FruitAwakened") == true or localPlayer:GetAttribute("Awakened") == true))
	if kind == "DragonTransform" or act == "DragonTransform" then
		local dTier = tonumber(fx.DragonFormTier) or 2
		if dTier > 0 then
			DragonSovereignVFX.SpawnTransformAscension(actorChar, pos, dTier, isAwakened, isLocal)
		else
			UniversalVFXOverhaul.SpawnDashSlipstream(actorChar, CFrame.new(pos), Color3.fromRGB(168, 92, 255), false)
		end
		return
	end

	local actorRoot = actorChar and actorChar:FindFirstChild("HumanoidRootPart")
	local startPos = (typeof(fx.StartPos) == "Vector3" and fx.StartPos)
		or (typeof(fx.Origin) == "Vector3" and fx.Origin)
		or (typeof(fx.EntryPos) == "Vector3" and fx.EntryPos)
		or (actorRoot and actorRoot.Position)
		or pos
	local endPos = (typeof(fx.EndPos) == "Vector3" and fx.EndPos)
		or (typeof(fx.ExitPos) == "Vector3" and fx.ExitPos)
		or (typeof(fx.TargetPos) == "Vector3" and fx.TargetPos)
		or pos
	local lookDir = (typeof(fx.Direction) == "Vector3" and fx.Direction.Magnitude > 0.05 and fx.Direction.Unit)
		or (((endPos - startPos).Magnitude > 0.4) and (endPos - startPos).Unit)
		or (actorRoot and actorRoot.CFrame.LookVector)
		or Vector3.new(0, 0, -1)

	local dragonAnchors = DragonSovereignVFX.ResolveDragonStateAndAnchors(actorChar, startPos, lookDir)

	-- Determine Move Key (Z, X, C, V, F, or M1) & Awakened V2 Multiplier (1.35x or RadiusScale)
	local moveKey = tostring(fx.key or fx.MoveKey or ""):upper()
	if moveKey == "" then
		local tail = act:match("_([ZXCVF])$") or act:match("^Skill([ZXCVF])$")
		if tail then moveKey = tail end
	end

	-- Basic M1 / Heavy Swing Slash Arc (including Martial Arts StyleMove M1 Kata punches!)
	local isStyleM1 = (kind == "StyleMove") and (moveKey == "M1" or tostring(fx.MoveType or "") == "Kata")
	if isStyleM1 or ((kind == "Swing" or act == "Attack" or act == "Heavy") and not fx.key and kind ~= "SlotMove") then
		local isHeavy = (act == "Heavy")
		local combo = tonumber(fx.Combo) or 1
		if dragonAnchors.Tier >= 1 then
			DragonSovereignVFX.SpawnDragonM1(actorChar, startPos, lookDir, combo, isHeavy, isAwakened, isLocal)
			return
		end
		local hakiOn = (actorChar and actorChar:GetAttribute("HakiAura") == true) or (isLocal and localPlayer and localPlayer:GetAttribute("HakiAura") == true)
		local styleProf = fx.StyleId and STYLE_PROFILES[tostring(fx.StyleId)] or nil
		local tintCol = (hakiOn and resolveHakiColor(actorChar)) or (styleProf and styleProf.Primary) or nil
		UniversalVFXOverhaul.SpawnMeleeCombo(actorChar, startPos, lookDir, combo, isHeavy, tintCol, isAwakened, isLocal)
		return
	end

	local radScale = tonumber(fx.RadiusScale)
	local scale = (radScale and radScale > 1.0) and math.clamp(radScale, 1.0, 1.65) or (isAwakened and 1.35 or 1.0)

	-- Explicit Class Skills, Slot 3 Swords, Slot 4 Guns, PortalWarp & SeaBeastBeam
	local activeSlot = tonumber(fx.Slot or fx.slot or (actorChar and actorChar:GetAttribute("ActiveSlot")) or (isLocal and localPlayer and localPlayer:GetAttribute("ActiveSlot"))) or 2
	local explicitFruitKey = resolveFruitKey(fx.FruitId or fx.fruitId or ((activeSlot == 2 or kind == "FruitMove") and fx.activeId or nil))
	if (kind == "GunShot" or kind == "ChargedSlash" or kind == "PortalWarp" or kind == "SeaBeastBeam" or kind == "Shield"
		or ((activeSlot == 3 or activeSlot == 4) and kind ~= "FruitMove" and kind ~= "StyleMove")
		or act == "SkySlash" or act == "GuardianShield" or act == "JudgmentStrike" or act == "CelestialAegis"
		or act == "ArcCut" or act == "StormBlitz" or act == "ThunderJudgement"
		or act == "FrostBolt" or act == "ManaBarrier" or act == "ArcaneComet" or act == "AstralCataclysm")
		and dragonAnchors.Tier == 0 and not explicitFruitKey then
		if UniversalVFXOverhaul.SpawnClassOrWeaponSkill(act, kind, moveKey, actorChar, startPos, endPos, lookDir, scale, isAwakened, isLocal, fx) then
			return
		end
	end

	-- Resolve Active Fruit / Martial Arts Style
	local rawFruit = explicitFruitKey or fx.FruitId or fx.fruitId or fx.activeId or (act:match("^([%w_]+)_[ZXCVF]$"))
		or ((activeSlot == 2) and ((actorChar and actorChar:GetAttribute("EquippedFruit")) or (isLocal and localPlayer and localPlayer:GetAttribute("EquippedFruit"))))
		or fx.element or fx.Element
	local fruitKey = resolveFruitKey(rawFruit)
	if not fruitKey and dragonAnchors.Tier >= 1 then
		fruitKey = "AbyssalSovereignCore"
	end

	-- Check Martial Arts Kata first if Slot 1 or explicit Fighting Style ID
	local rawStyle = fx.StyleId or (act:match("^([%w_]+)_[ZXCVF]$"))
		or ((activeSlot == 1) and ((actorChar and actorChar:GetAttribute("FightingStyle")) or (isLocal and localPlayer and localPlayer:GetAttribute("FightingStyle"))))
	if rawStyle and STYLE_PROFILES[tostring(rawStyle)] and (activeSlot == 1 or not fruitKey) and dragonAnchors.Tier == 0 then
		UniversalVFXOverhaul.SpawnMartialKata(STYLE_PROFILES[tostring(rawStyle)], (moveKey ~= "" and moveKey or "Z"), startPos, endPos, lookDir, scale, isAwakened, isLocal)
		return
	end

	-- Execute Bespoke Bone-Locked Sovereign Dragon & Hybrid Skill VFX Suite (Z, X, C, V, F)
	if fruitKey == "AbyssalSovereignCore" then
		local key = (moveKey == "Z" or moveKey == "X" or moveKey == "C" or moveKey == "V" or moveKey == "F") and moveKey or "Z"
		DragonSovereignVFX.DispatchMove(key, actorChar, startPos, endPos, lookDir, scale, isAwakened, isLocal, fx)
		return
	end

	-- Execute All 11 Non-Dragon Devil Fruits x 5 Moves (55 Bespoke Moves Across 16 Overhauled Archetypes)
	if fruitKey and FRUIT_PROFILES[fruitKey] then
		local prof = FRUIT_PROFILES[fruitKey]
		local key = (moveKey == "Z" or moveKey == "X" or moveKey == "C" or moveKey == "V" or moveKey == "F") and moveKey or "Z"
		local fruitTable = FRUIT_MOVE_SPECS[fruitKey] or FRUIT_MOVE_SPECS.SolarFlameCore
		local spec = fruitTable[key] or fruitTable.Z
		UniversalVFXOverhaul.ExecuteFruitArchetype(spec.Archetype, fruitKey, key, startPos, endPos, lookDir, prof, spec, scale, isAwakened, isLocal, actorChar)
		return
	end

	-- Fallback Class / Weapon / Elemental Skill VFX
	if UniversalVFXOverhaul.SpawnClassOrWeaponSkill(act, kind, moveKey, actorChar, startPos, endPos, lookDir, scale, isAwakened, isLocal, fx) then
		return
	end
	local fallbackFruit = (act:find("Thunder") or act:find("ArcCut") or act:find("Storm")) and "ThunderRumbleCore"
		or ((act:find("Frost") or act:find("Cryo")) and "GlacierIceCore")
		or ((act:find("Astral") or act:find("Arcane") or act:find("Void")) and "AstralGravityCore")
		or "SolarTitanCore"
	local prof = FRUIT_PROFILES[fallbackFruit]
	local key = (moveKey ~= "" and moveKey) or ((act:find("Aegis") or act:find("Judgement") or act:find("Cataclysm")) and "V" or "C")
	local spec = FRUIT_MOVE_SPECS[fallbackFruit][key] or FRUIT_MOVE_SPECS[fallbackFruit].C
	UniversalVFXOverhaul.ExecuteFruitArchetype(spec.Archetype, fallbackFruit, key, startPos, endPos, lookDir, prof, spec, scale, isAwakened, isLocal, actorChar)
end

-- ============================================================================
-- CHARACTER ATTRIBUTE WATCHERS & LIFECYCLE MANAGEMENT
-- ============================================================================
local function clearCharConnections()
	for _, c in ipairs(charConnections) do
		c:Disconnect()
	end
	table.clear(charConnections)
end

local function checkRaceV4Transition(ch)
	if not ch or not ch.Parent then return end
	local v4Val = ch:GetAttribute("RaceV4Active") or ch:GetAttribute("RaceV4") or (localPlayer and (localPlayer:GetAttribute("RaceV4Active") or localPlayer:GetAttribute("RaceV4")))
	local isActive = (v4Val == true) or (type(v4Val) == "string" and v4Val ~= "" and v4Val ~= "None")
	local wasActive = (ch:GetAttribute("_PrevRaceV4Active") == true)
	ch:SetAttribute("_PrevRaceV4Active", isActive)
	if isActive and not wasActive then
		local rName = tostring(ch:GetAttribute("Race") or (localPlayer and localPlayer:GetAttribute("Race")) or "Skyborn")
		UniversalVFXOverhaul.SpawnRaceV4Awakening(ch, rName)
	end
end

local function bindCharacter(ch)
	clearCharConnections()
	clearDragonRig()
	if not ch then return end

	task.defer(function()
		if ch and ch.Parent then
			updateBusoshokuCoating(ch)
			checkRaceV4Transition(ch)
		end
	end)

	for _, attr in ipairs({ "HakiAura", "HakiStage", "HakiColor", "HakiAuraColor", "HakiColorRGB" }) do
		table.insert(charConnections, ch:GetAttributeChangedSignal(attr):Connect(function()
			updateBusoshokuCoating(ch)
		end))
	end
	for _, attr in ipairs({ "RaceV4", "RaceV4Active" }) do
		table.insert(charConnections, ch:GetAttributeChangedSignal(attr):Connect(function()
			checkRaceV4Transition(ch)
		end))
	end
end

function SkybreakClientVFX.Init(ctx)
	if initialized then return SkybreakClientVFX end
	initialized = true

	if type(ctx) == "table" then
		localPlayer = ctx.Player or localPlayer
		Config = ctx.Config or Config
		Remotes = ctx.Remotes or Remotes
		UI = ctx.UI or UI
		Audio = ctx.Audio or Audio
		tempFX = ctx.TempFX or tempFX
	end
	if not Config then
		pcall(function()
			Config = require(game.ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
		end)
	end
	ensureTempFolder("DamageNumberPool")
	initDamageNumberPool()
	DragonSovereignVFX.EnsureDefaultPrefabs()
	VFXStudioLibrary.EnsureAllPrefabs()
	watchEnemyFolders()

	if tempFX then
		table.insert(activeConnections, tempFX.ChildAdded:Connect(function(child)
			if child:IsA("BasePart") then
				local n = child.Name
				if n:find("Telegraph") or n:find("Danger") or n:find("AoE") then
					UniversalVFXOverhaul.EnhanceBossTelegraph(child)
				end
			end
		end))
	end

	if localPlayer then
		if localPlayer.Character then
			bindCharacter(localPlayer.Character)
		end
		table.insert(activeConnections, localPlayer.CharacterAdded:Connect(bindCharacter))
		table.insert(activeConnections, localPlayer.CharacterRemoving:Connect(function()
			clearCharConnections()
			clearDragonRig()
		end))
		for _, attr in ipairs({ "HakiAura", "HakiStage", "HakiColor", "HakiAuraColor", "HakiColorRGB" }) do
			table.insert(activeConnections, localPlayer:GetAttributeChangedSignal(attr):Connect(function()
				if localPlayer.Character then
					updateBusoshokuCoating(localPlayer.Character)
				end
			end))
		end
		for _, attr in ipairs({ "RaceV4", "RaceV4Active" }) do
			table.insert(activeConnections, localPlayer:GetAttributeChangedSignal(attr):Connect(function()
				if localPlayer.Character then
					checkRaceV4Transition(localPlayer.Character)
				end
			end))
		end
	end

	stepDragonFormAndHUD(0)
	SkybreakClientVFX.UpdateInstinctVision()

	table.insert(activeConnections, RunService.Heartbeat:Connect(function(dt)
		stepDragonFormAndHUD(dt)
		SkybreakClientVFX.UpdateInstinctVision()
	end))

	return SkybreakClientVFX
end

return SkybreakClientVFX
