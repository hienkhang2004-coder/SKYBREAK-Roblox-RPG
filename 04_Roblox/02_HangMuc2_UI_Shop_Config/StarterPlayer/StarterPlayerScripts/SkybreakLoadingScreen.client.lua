--!strict
-- StarterPlayerScripts/SkybreakLoadingScreen.client.lua
-- Zero-dependency instant-mount cinematic loading screen for SKYBREAK: Fragments of the Core.
-- Tracks 4 real client readiness stages, exposes SKIP [SPACE] after 1.8s, caps max duration at 7.5s,
-- sets LocalPlayer:SetAttribute("SkybreakLoadingDone", true), fades out over 0.45s, and self-destructs cleanly.

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalizationService = game:GetService("LocalizationService")

local localPlayer = Players.LocalPlayer
if not localPlayer then
	return
end

if localPlayer:GetAttribute("SkybreakLoadingDone") == true then
	return
end
localPlayer:SetAttribute("SkybreakLoadingDone", false)

pcall(function()
	ReplicatedFirst:RemoveDefaultLoadingScreen()
end)

local playerGui = localPlayer:WaitForChild("PlayerGui")
local existingGui = playerGui:FindFirstChild("SkybreakLoadingGui")
if existingGui then
	existingGui:Destroy()
end

-- Palette (Obsidian-Sapphire-Gold matching SKYBREAK Theme)
local COL_SKY_TOP = Color3.fromRGB(6, 9, 19) -- #060913
local COL_SKY_MID = Color3.fromRGB(10, 16, 33)
local COL_SKY_BOT = Color3.fromRGB(14, 23, 46) -- #0E172E
local COL_GOLD = Color3.fromRGB(245, 196, 81)
local COL_GOLD_BRIGHT = Color3.fromRGB(255, 241, 196)
local COL_GOLD_DEEP = Color3.fromRGB(184, 134, 43)
local COL_CYAN = Color3.fromRGB(79, 209, 255)
local COL_TEXT_PRIMARY = Color3.fromRGB(244, 247, 255)
local COL_TEXT_SECOND = Color3.fromRGB(168, 184, 216)
local COL_TEXT_MUTED = Color3.fromRGB(118, 136, 172)
local COL_BAR_TRACK = Color3.fromRGB(15, 23, 44)
local COL_BTN_BG = Color3.fromRGB(16, 26, 50)
local COL_BTN_HOVER = Color3.fromRGB(26, 40, 74)

-- Language helper (zero external module dependency)
local function resolveLanguage(): string
	local attr = localPlayer:GetAttribute("Language")
	if type(attr) == "string" then
		local low = string.lower(attr)
		if string.sub(low, 1, 2) == "vi" then
			return "vi"
		elseif string.sub(low, 1, 2) == "en" then
			return "en"
		end
	end

	local okSys, sysLoc = pcall(function()
		return LocalizationService.SystemLocaleId
	end)
	if okSys and type(sysLoc) == "string" and string.sub(string.lower(sysLoc), 1, 2) == "vi" then
		return "vi"
	end

	local okRbx, rbxLoc = pcall(function()
		return LocalizationService.RobloxLocaleId
	end)
	if okRbx and type(rbxLoc) == "string" and string.sub(string.lower(rbxLoc), 1, 2) == "vi" then
		return "vi"
	end

	return "en"
end

local currentLang = resolveLanguage()

local STAGE_TEXT = {
	[1] = {
		vi = "Đang khởi tạo kết nối Thiên Giới...",
		en = "Initializing Skyrealm engine...",
	},
	[2] = {
		vi = "Đang đồng bộ tài nguyên & nguồn Lõi Aether...",
		en = "Syncing assets & Aether Core sources...",
	},
	[3] = {
		vi = "Đang kiến tạo quần đảo 3D & kiến trúc cổ đại...",
		en = "Constructing 3D sky islands & world geometry...",
	},
	[4] = {
		vi = "Đang triệu hồi Chiến Binh trên Đài Chân Mây...",
		en = "Summoning character into the Skyrealm...",
	},
	[5] = {
		vi = "Sẵn sàng khởi hành — Chào mừng đến với SKYBREAK!",
		en = "Ready to launch — Welcome to SKYBREAK!",
	},
}

local GAMEPLAY_TIPS = {
	{
		vi = "MẸO CHIẾN ĐẤU • Kết hợp lướt [Q] và Nhảy Đôi để né đòn diện rộng của Trùm Thiên Giới.",
		en = "COMBAT TIP • Chain [Q] Dash and Double Jump to evade wide-area Boss telegraphs.",
	},
	{
		vi = "LÕI AETHER • Tỷ lệ Cầu Lõi công khai minh bạch tại Đền Lõi — bậc Thần Thoại có bảo hiểm vận may.",
		en = "AETHER CORES • Full drop rates are disclosed at the Core Shrine with Mythic luck protection.",
	},
	{
		vi = "HỆ THỐNG BAY • Các Lõi Nguyên Tố cho phép bay tự do bằng phím [F] khi đang trang bị ở Ô 2.",
		en = "SKY FLIGHT • Elemental Aether Cores unlock 3D Free Flight via [F] while equipped in Slot 2.",
	},
	{
		vi = "HIỆU NĂNG • Mở [O] Cài Đặt để chỉnh riêng Âm Lượng Nhạc/Hiệu Ứng hoặc bật Chế Độ Giảm Hiệu Ứng.",
		en = "PERFORMANCE • Open [O] Settings to tune Master/BGM/SFX Volume or enable Low FX Mode.",
	},
	{
		vi = "KHÁM PHÁ • Dùng La Bàn Nhiệm Vụ và Cổng Dịch Chuyển để chu du qua các quần đảo lơ lửng.",
		en = "EXPLORATION • Follow the Quest Compass and Sky Portals to traverse floating island realms.",
	},
}

-- Instant GUI Mount
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SkybreakLoadingGui"
screenGui.DisplayOrder = 950
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local rootCanvas = Instance.new("CanvasGroup")
rootCanvas.Name = "RootCanvas"
rootCanvas.Size = UDim2.fromScale(1, 1)
rootCanvas.Position = UDim2.fromScale(0, 0)
rootCanvas.BackgroundColor3 = Color3.new(1, 1, 1)
rootCanvas.BorderSizePixel = 0
rootCanvas.GroupTransparency = 0
rootCanvas.Active = true
rootCanvas.Parent = screenGui

local skyGradient = Instance.new("UIGradient")
skyGradient.Rotation = 90
skyGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, COL_SKY_TOP),
	ColorSequenceKeypoint.new(0.55, COL_SKY_MID),
	ColorSequenceKeypoint.new(1, COL_SKY_BOT),
})
skyGradient.Parent = rootCanvas

-- Ambient celestial horizon glow
local horizonGlow = Instance.new("Frame")
horizonGlow.Name = "HorizonGlow"
horizonGlow.AnchorPoint = Vector2.new(0.5, 0.5)
horizonGlow.Position = UDim2.fromScale(0.5, 0.42)
horizonGlow.Size = UDim2.fromOffset(560, 560)
horizonGlow.BackgroundColor3 = COL_CYAN
horizonGlow.BackgroundTransparency = 0.93
horizonGlow.BorderSizePixel = 0
horizonGlow.ZIndex = 1
horizonGlow.Parent = rootCanvas

local horizonCorner = Instance.new("UICorner")
horizonCorner.CornerRadius = UDim.new(1, 0)
horizonCorner.Parent = horizonGlow

local goldHalo = Instance.new("Frame")
goldHalo.Name = "GoldHalo"
goldHalo.AnchorPoint = Vector2.new(0.5, 0.5)
goldHalo.Position = UDim2.fromScale(0.5, 0.36)
goldHalo.Size = UDim2.fromOffset(320, 320)
goldHalo.BackgroundColor3 = COL_GOLD
goldHalo.BackgroundTransparency = 0.94
goldHalo.BorderSizePixel = 0
goldHalo.ZIndex = 1
goldHalo.Parent = rootCanvas

local goldHaloCorner = Instance.new("UICorner")
goldHaloCorner.CornerRadius = UDim.new(1, 0)
goldHaloCorner.Parent = goldHalo

-- Outer architectural frame
local outerBorder = Instance.new("Frame")
outerBorder.Name = "ArchitecturalBorder"
outerBorder.AnchorPoint = Vector2.new(0.5, 0.5)
outerBorder.Position = UDim2.fromScale(0.5, 0.5)
outerBorder.Size = UDim2.new(1, -36, 1, -36)
outerBorder.BackgroundTransparency = 1
outerBorder.BorderSizePixel = 0
outerBorder.ZIndex = 2
outerBorder.Parent = rootCanvas

local outerStroke = Instance.new("UIStroke")
outerStroke.Color = COL_GOLD
outerStroke.Thickness = 1
outerStroke.Transparency = 0.78
outerStroke.Parent = outerBorder

local outerCorner = Instance.new("UICorner")
outerCorner.CornerRadius = UDim.new(0, 14)
outerCorner.Parent = outerBorder

-- 12 lightweight drifting golden-cyan star motes
type StarMote = {
	frame: Frame,
	baseX: number,
	y: number,
	speedY: number,
	swayAmp: number,
	swayFreq: number,
	phase: number,
	baseAlpha: number,
}

local moteLayer = Instance.new("Frame")
moteLayer.Name = "StarMoteLayer"
moteLayer.Size = UDim2.fromScale(1, 1)
moteLayer.BackgroundTransparency = 1
moteLayer.ClipsDescendants = true
moteLayer.ZIndex = 2
moteLayer.Parent = rootCanvas

local MOTES_PRESET = {
	{ x = 0.11, y = 0.82, sz = 4, spd = 0.026, amp = 0.012, freq = 1.1, ph = 0.2, gold = true },
	{ x = 0.19, y = 0.34, sz = 3, spd = 0.019, amp = 0.009, freq = 0.9, ph = 1.4, gold = false },
	{ x = 0.27, y = 0.68, sz = 5, spd = 0.022, amp = 0.014, freq = 1.3, ph = 2.1, gold = true },
	{ x = 0.35, y = 0.22, sz = 3, spd = 0.017, amp = 0.010, freq = 0.8, ph = 3.0, gold = false },
	{ x = 0.43, y = 0.88, sz = 4, spd = 0.029, amp = 0.011, freq = 1.2, ph = 0.8, gold = true },
	{ x = 0.51, y = 0.16, sz = 3, spd = 0.021, amp = 0.008, freq = 1.0, ph = 4.2, gold = false },
	{ x = 0.59, y = 0.74, sz = 5, spd = 0.024, amp = 0.013, freq = 1.1, ph = 1.9, gold = true },
	{ x = 0.67, y = 0.44, sz = 3, spd = 0.018, amp = 0.010, freq = 0.9, ph = 2.7, gold = false },
	{ x = 0.74, y = 0.85, sz = 4, spd = 0.027, amp = 0.012, freq = 1.4, ph = 3.6, gold = true },
	{ x = 0.81, y = 0.29, sz = 3, spd = 0.020, amp = 0.009, freq = 1.0, ph = 5.1, gold = false },
	{ x = 0.88, y = 0.63, sz = 5, spd = 0.023, amp = 0.013, freq = 1.2, ph = 0.5, gold = true },
	{ x = 0.93, y = 0.40, sz = 3, spd = 0.016, amp = 0.008, freq = 0.85, ph = 4.7, gold = false },
}

local starMotes: { StarMote } = {}
for i, cfg in ipairs(MOTES_PRESET) do
	local mote = Instance.new("Frame")
	mote.Name = "StarMote_" .. tostring(i)
	mote.AnchorPoint = Vector2.new(0.5, 0.5)
	mote.Position = UDim2.fromScale(cfg.x, cfg.y)
	mote.Size = UDim2.fromOffset(cfg.sz, cfg.sz)
	mote.Rotation = 45
	mote.BackgroundColor3 = if cfg.gold then COL_GOLD else COL_CYAN
	mote.BackgroundTransparency = if cfg.gold then 0.35 else 0.42
	mote.BorderSizePixel = 0
	mote.ZIndex = 2
	mote.Parent = moteLayer

	local mc = Instance.new("UICorner")
	mc.CornerRadius = UDim.new(0, 1)
	mc.Parent = mote

	table.insert(starMotes, {
		frame = mote,
		baseX = cfg.x,
		y = cfg.y,
		speedY = cfg.spd,
		swayAmp = cfg.amp,
		swayFreq = cfg.freq,
		phase = cfg.ph,
		baseAlpha = if cfg.gold then 0.35 else 0.42,
	})
end

-- Center stage container (responsive scale + UISizeConstraint)
local centerWrap = Instance.new("Frame")
centerWrap.Name = "CenterStage"
centerWrap.AnchorPoint = Vector2.new(0.5, 0.5)
centerWrap.Position = UDim2.fromScale(0.5, 0.48)
centerWrap.Size = UDim2.new(0.88, 0, 0, 420)
centerWrap.BackgroundTransparency = 1
centerWrap.ZIndex = 4
centerWrap.Parent = rootCanvas

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MaxSize = Vector2.new(640, 460)
sizeConstraint.MinSize = Vector2.new(280, 340)
sizeConstraint.Parent = centerWrap

-- Procedural Multi-Ring Golden Celestial Core Emblem
local emblemRoot = Instance.new("Frame")
emblemRoot.Name = "CelestialCoreEmblem"
emblemRoot.AnchorPoint = Vector2.new(0.5, 0)
emblemRoot.Position = UDim2.new(0.5, 0, 0, 6)
emblemRoot.Size = UDim2.fromOffset(132, 132)
emblemRoot.BackgroundTransparency = 1
emblemRoot.ZIndex = 5
emblemRoot.Parent = centerWrap

-- Outer celestial ring (rotates clockwise)
local outerRing = Instance.new("Frame")
outerRing.Name = "OuterCelestialRing"
outerRing.AnchorPoint = Vector2.new(0.5, 0.5)
outerRing.Position = UDim2.fromScale(0.5, 0.5)
outerRing.Size = UDim2.fromOffset(124, 124)
outerRing.BackgroundTransparency = 1
outerRing.ZIndex = 5
outerRing.Parent = emblemRoot

local outerRingCorner = Instance.new("UICorner")
outerRingCorner.CornerRadius = UDim.new(1, 0)
outerRingCorner.Parent = outerRing

local outerRingStroke = Instance.new("UIStroke")
outerRingStroke.Color = COL_GOLD
outerRingStroke.Thickness = 2
outerRingStroke.Transparency = 0.25
outerRingStroke.Parent = outerRing

local outerRingGrad = Instance.new("UIGradient")
outerRingGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, COL_GOLD_BRIGHT),
	ColorSequenceKeypoint.new(0.5, COL_GOLD),
	ColorSequenceKeypoint.new(1, COL_GOLD_DEEP),
})
outerRingGrad.Parent = outerRingStroke

local CARDINAL_POS = {
	Vector2.new(0.5, 0),
	Vector2.new(1, 0.5),
	Vector2.new(0.5, 1),
	Vector2.new(0, 0.5),
}
for i, pos in ipairs(CARDINAL_POS) do
	local stud = Instance.new("Frame")
	stud.Name = "CardinalStud_" .. tostring(i)
	stud.AnchorPoint = Vector2.new(0.5, 0.5)
	stud.Position = UDim2.fromScale(pos.X, pos.Y)
	stud.Size = UDim2.fromOffset(8, 8)
	stud.Rotation = 45
	stud.BackgroundColor3 = COL_GOLD_BRIGHT
	stud.BorderSizePixel = 0
	stud.ZIndex = 6
	stud.Parent = outerRing
end

-- Middle arcane sapphire-cyan ring (counter-rotates)
local midRing = Instance.new("Frame")
midRing.Name = "MiddleArcaneRing"
midRing.AnchorPoint = Vector2.new(0.5, 0.5)
midRing.Position = UDim2.fromScale(0.5, 0.5)
midRing.Size = UDim2.fromOffset(92, 92)
midRing.BackgroundTransparency = 1
midRing.ZIndex = 6
midRing.Parent = emblemRoot

local midRingCorner = Instance.new("UICorner")
midRingCorner.CornerRadius = UDim.new(1, 0)
midRingCorner.Parent = midRing

local midRingStroke = Instance.new("UIStroke")
midRingStroke.Color = COL_CYAN
midRingStroke.Thickness = 1.5
midRingStroke.Transparency = 0.32
midRingStroke.Parent = midRing

for i, pos in ipairs(CARDINAL_POS) do
	local node = Instance.new("Frame")
	node.Name = "ArcaneNode_" .. tostring(i)
	node.AnchorPoint = Vector2.new(0.5, 0.5)
	node.Position = UDim2.fromScale(pos.X, pos.Y)
	node.Size = UDim2.fromOffset(5, 5)
	node.Rotation = 45
	node.BackgroundColor3 = COL_CYAN
	node.BorderSizePixel = 0
	node.ZIndex = 7
	node.Parent = midRing
end

-- Inner octagram filigree squares
local innerFiligreeA = Instance.new("Frame")
innerFiligreeA.Name = "InnerFiligreeA"
innerFiligreeA.AnchorPoint = Vector2.new(0.5, 0.5)
innerFiligreeA.Position = UDim2.fromScale(0.5, 0.5)
innerFiligreeA.Size = UDim2.fromOffset(54, 54)
innerFiligreeA.Rotation = 45
innerFiligreeA.BackgroundColor3 = COL_SKY_MID
innerFiligreeA.BackgroundTransparency = 0.35
innerFiligreeA.BorderSizePixel = 0
innerFiligreeA.ZIndex = 7
innerFiligreeA.Parent = emblemRoot

local filStrokeA = Instance.new("UIStroke")
filStrokeA.Color = COL_GOLD
filStrokeA.Thickness = 1.5
filStrokeA.Transparency = 0.2
filStrokeA.Parent = innerFiligreeA

local innerFiligreeB = Instance.new("Frame")
innerFiligreeB.Name = "InnerFiligreeB"
innerFiligreeB.AnchorPoint = Vector2.new(0.5, 0.5)
innerFiligreeB.Position = UDim2.fromScale(0.5, 0.5)
innerFiligreeB.Size = UDim2.fromOffset(54, 54)
innerFiligreeB.Rotation = 0
innerFiligreeB.BackgroundTransparency = 1
innerFiligreeB.BorderSizePixel = 0
innerFiligreeB.ZIndex = 7
innerFiligreeB.Parent = emblemRoot

local filStrokeB = Instance.new("UIStroke")
filStrokeB.Color = COL_GOLD_DEEP
filStrokeB.Thickness = 1.2
filStrokeB.Transparency = 0.42
filStrokeB.Parent = innerFiligreeB

-- Radiant Celestial Core diamond at the center
local coreCrystal = Instance.new("Frame")
coreCrystal.Name = "CoreCrystal"
coreCrystal.AnchorPoint = Vector2.new(0.5, 0.5)
coreCrystal.Position = UDim2.fromScale(0.5, 0.5)
coreCrystal.Size = UDim2.fromOffset(26, 26)
coreCrystal.Rotation = 45
coreCrystal.BackgroundColor3 = Color3.new(1, 1, 1)
coreCrystal.BorderSizePixel = 0
coreCrystal.ZIndex = 8
coreCrystal.Parent = emblemRoot

local coreCorner = Instance.new("UICorner")
coreCorner.CornerRadius = UDim.new(0, 4)
coreCorner.Parent = coreCrystal

local coreGrad = Instance.new("UIGradient")
coreGrad.Rotation = -45
coreGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, COL_GOLD_BRIGHT),
	ColorSequenceKeypoint.new(0.6, COL_GOLD),
	ColorSequenceKeypoint.new(1, COL_CYAN),
})
coreGrad.Parent = coreCrystal

local coreScale = Instance.new("UIScale")
coreScale.Scale = 1
coreScale.Parent = coreCrystal

-- Title & Subtitle Typography
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "TitleLabel"
titleLabel.AnchorPoint = Vector2.new(0.5, 0)
titleLabel.Position = UDim2.new(0.5, 0, 0, 152)
titleLabel.Size = UDim2.new(1, 0, 0, 48)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.Text = "SKYBREAK"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.TextSize = 42
titleLabel.ZIndex = 6
titleLabel.Parent = centerWrap

local titleGrad = Instance.new("UIGradient")
titleGrad.Rotation = 90
titleGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 252, 240)),
	ColorSequenceKeypoint.new(0.62, COL_GOLD_BRIGHT),
	ColorSequenceKeypoint.new(1, COL_GOLD),
})
titleGrad.Parent = titleLabel

local titleStroke = Instance.new("UIStroke")
titleStroke.Color = Color3.fromRGB(4, 8, 18)
titleStroke.Thickness = 2
titleStroke.Transparency = 0.25
titleStroke.Parent = titleLabel

local subtitleRow = Instance.new("Frame")
subtitleRow.Name = "SubtitleRow"
subtitleRow.AnchorPoint = Vector2.new(0.5, 0)
subtitleRow.Position = UDim2.new(0.5, 0, 0, 202)
subtitleRow.Size = UDim2.new(1, 0, 0, 22)
subtitleRow.BackgroundTransparency = 1
subtitleRow.ZIndex = 6
subtitleRow.Parent = centerWrap

local leftRule = Instance.new("Frame")
leftRule.AnchorPoint = Vector2.new(1, 0.5)
leftRule.Position = UDim2.new(0.5, -128, 0.5, 0)
leftRule.Size = UDim2.fromOffset(64, 1)
leftRule.BackgroundColor3 = COL_GOLD
leftRule.BackgroundTransparency = 0.45
leftRule.BorderSizePixel = 0
leftRule.ZIndex = 6
leftRule.Parent = subtitleRow

local rightRule = Instance.new("Frame")
rightRule.AnchorPoint = Vector2.new(0, 0.5)
rightRule.Position = UDim2.new(0.5, 128, 0.5, 0)
rightRule.Size = UDim2.fromOffset(64, 1)
rightRule.BackgroundColor3 = COL_GOLD
rightRule.BackgroundTransparency = 0.45
rightRule.BorderSizePixel = 0
rightRule.ZIndex = 6
rightRule.Parent = subtitleRow

local subtitleLabel = Instance.new("TextLabel")
subtitleLabel.Name = "SubtitleLabel"
subtitleLabel.AnchorPoint = Vector2.new(0.5, 0.5)
subtitleLabel.Position = UDim2.fromScale(0.5, 0.5)
subtitleLabel.Size = UDim2.fromOffset(244, 20)
subtitleLabel.BackgroundTransparency = 1
subtitleLabel.Font = Enum.Font.GothamBold
subtitleLabel.Text = "FRAGMENTS OF THE CORE"
subtitleLabel.TextColor3 = COL_GOLD
subtitleLabel.TextSize = 13
subtitleLabel.ZIndex = 6
subtitleLabel.Parent = subtitleRow

-- Status & Percentage Header Row
local statusRow = Instance.new("Frame")
statusRow.Name = "StatusRow"
statusRow.AnchorPoint = Vector2.new(0.5, 0)
statusRow.Position = UDim2.new(0.5, 0, 0, 250)
statusRow.Size = UDim2.new(1, -24, 0, 22)
statusRow.BackgroundTransparency = 1
statusRow.ZIndex = 6
statusRow.Parent = centerWrap

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Position = UDim2.fromOffset(0, 0)
statusLabel.Size = UDim2.new(1, -68, 1, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Font = Enum.Font.GothamMedium
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextTruncate = Enum.TextTruncate.AtEnd
statusLabel.TextColor3 = COL_TEXT_SECOND
statusLabel.TextSize = 13
statusLabel.Text = STAGE_TEXT[1][currentLang]
statusLabel.ZIndex = 6
statusLabel.Parent = statusRow

local percentLabel = Instance.new("TextLabel")
percentLabel.Name = "PercentLabel"
percentLabel.AnchorPoint = Vector2.new(1, 0)
percentLabel.Position = UDim2.fromScale(1, 0)
percentLabel.Size = UDim2.fromOffset(64, 22)
percentLabel.BackgroundTransparency = 1
percentLabel.Font = Enum.Font.GothamBold
percentLabel.TextXAlignment = Enum.TextXAlignment.Right
percentLabel.TextColor3 = COL_GOLD_BRIGHT
percentLabel.TextSize = 14
percentLabel.Text = "0%"
percentLabel.ZIndex = 6
percentLabel.Parent = statusRow

-- Glossy Golden-Cyan Progress Bar
local barTrack = Instance.new("Frame")
barTrack.Name = "ProgressBarTrack"
barTrack.AnchorPoint = Vector2.new(0.5, 0)
barTrack.Position = UDim2.new(0.5, 0, 0, 278)
barTrack.Size = UDim2.new(1, -24, 0, 12)
barTrack.BackgroundColor3 = COL_BAR_TRACK
barTrack.BorderSizePixel = 0
barTrack.ClipsDescendants = true
barTrack.ZIndex = 6
barTrack.Parent = centerWrap

local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(1, 0)
trackCorner.Parent = barTrack

local trackStroke = Instance.new("UIStroke")
trackStroke.Color = COL_GOLD
trackStroke.Thickness = 1
trackStroke.Transparency = 0.62
trackStroke.Parent = barTrack

local barFill = Instance.new("Frame")
barFill.Name = "ProgressBarFill"
barFill.Size = UDim2.fromScale(0.02, 1)
barFill.BackgroundColor3 = Color3.new(1, 1, 1)
barFill.BorderSizePixel = 0
barFill.ZIndex = 7
barFill.Parent = barTrack

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = barFill

local fillGrad = Instance.new("UIGradient")
fillGrad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, COL_GOLD_DEEP),
	ColorSequenceKeypoint.new(0.48, COL_GOLD),
	ColorSequenceKeypoint.new(0.82, COL_GOLD_BRIGHT),
	ColorSequenceKeypoint.new(1, COL_CYAN),
})
fillGrad.Parent = barFill

-- Glossy top sheen inside progress fill
local barSheen = Instance.new("Frame")
barSheen.Name = "GlossSheen"
barSheen.Position = UDim2.fromOffset(0, 0)
barSheen.Size = UDim2.new(1, 0, 0.45, 0)
barSheen.BackgroundColor3 = Color3.new(1, 1, 1)
barSheen.BackgroundTransparency = 0.68
barSheen.BorderSizePixel = 0
barSheen.ZIndex = 8
barSheen.Parent = barFill

local sheenCorner = Instance.new("UICorner")
sheenCorner.CornerRadius = UDim.new(1, 0)
sheenCorner.Parent = barSheen

-- Rotating Bilingual Gameplay Tip Panel
local tipPanel = Instance.new("Frame")
tipPanel.Name = "TipPanel"
tipPanel.AnchorPoint = Vector2.new(0.5, 0)
tipPanel.Position = UDim2.new(0.5, 0, 0, 304)
tipPanel.Size = UDim2.new(1, -24, 0, 48)
tipPanel.BackgroundColor3 = Color3.fromRGB(11, 18, 36)
tipPanel.BackgroundTransparency = 0.35
tipPanel.BorderSizePixel = 0
tipPanel.ZIndex = 6
tipPanel.Parent = centerWrap

local tipCorner = Instance.new("UICorner")
tipCorner.CornerRadius = UDim.new(0, 8)
tipCorner.Parent = tipPanel

local tipStroke = Instance.new("UIStroke")
tipStroke.Color = COL_CYAN
tipStroke.Thickness = 1
tipStroke.Transparency = 0.80
tipStroke.Parent = tipPanel

local tipLabel = Instance.new("TextLabel")
tipLabel.Name = "TipLabel"
tipLabel.AnchorPoint = Vector2.new(0.5, 0.5)
tipLabel.Position = UDim2.fromScale(0.5, 0.5)
tipLabel.Size = UDim2.new(1, -24, 1, -10)
tipLabel.BackgroundTransparency = 1
tipLabel.Font = Enum.Font.Gotham
tipLabel.TextWrapped = true
tipLabel.TextColor3 = COL_TEXT_PRIMARY
tipLabel.TextTransparency = 0.12
tipLabel.TextSize = 12
tipLabel.Text = GAMEPLAY_TIPS[1][currentLang]
tipLabel.ZIndex = 7
tipLabel.Parent = tipPanel

local function getSkipButtonLabel(lang: string): string
	local isTouchOnly = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	if isTouchOnly then
		return if lang == "en" then "TAP TO SKIP" else "CHẠM ĐỂ BỎ QUA"
	end
	return if lang == "en" then "SKIP [SPACE]" else "BỎ QUA [SPACE]"
end

-- Crisp Skip Button (revealed after 1.8s)
local skipButton = Instance.new("TextButton")
skipButton.Name = "SkipButton"
skipButton.AnchorPoint = Vector2.new(0.5, 0)
skipButton.Position = UDim2.new(0.5, 0, 0, 368)
skipButton.Size = UDim2.fromOffset(214, 34)
skipButton.BackgroundColor3 = COL_BTN_BG
skipButton.BackgroundTransparency = 1
skipButton.BorderSizePixel = 0
skipButton.AutoButtonColor = false
skipButton.Font = Enum.Font.GothamBold
skipButton.TextSize = 12
skipButton.TextColor3 = COL_GOLD_BRIGHT
skipButton.TextTransparency = 1
skipButton.Text = getSkipButtonLabel(currentLang)
skipButton.Visible = false
skipButton.Active = false
skipButton.ZIndex = 8
skipButton.Parent = centerWrap

local skipCorner = Instance.new("UICorner")
skipCorner.CornerRadius = UDim.new(0, 8)
skipCorner.Parent = skipButton

local skipStroke = Instance.new("UIStroke")
skipStroke.Color = COL_GOLD
skipStroke.Thickness = 1.2
skipStroke.Transparency = 1
skipStroke.Parent = skipButton

-- Subtle bottom version/realm footer
local footerLabel = Instance.new("TextLabel")
footerLabel.Name = "FooterLabel"
footerLabel.AnchorPoint = Vector2.new(0.5, 1)
footerLabel.Position = UDim2.new(0.5, 0, 1, -16)
footerLabel.Size = UDim2.new(1, -48, 0, 18)
footerLabel.BackgroundTransparency = 1
footerLabel.Font = Enum.Font.GothamMedium
footerLabel.TextSize = 11
footerLabel.TextColor3 = COL_TEXT_MUTED
footerLabel.Text = "SKYBREAK • CELESTIAL ENGINE V5"
footerLabel.ZIndex = 4
footerLabel.Parent = rootCanvas

-- State & Connections
local connections: { RBXScriptConnection } = {}
local startClock = os.clock()
local peakQueueSize = math.max(ContentProvider.RequestQueueSize, 1)
local displayProgress = 0.02
local currentStageIndex = 1
local currentTipIndex = 1
local lastTipSwitch = startClock
local skipRevealed = false
local finishing = false

local function refreshLocalizedTexts()
	currentLang = resolveLanguage()
	local stageEntry = STAGE_TEXT[currentStageIndex] or STAGE_TEXT[1]
	statusLabel.Text = stageEntry[currentLang] or stageEntry.en
	local tipEntry = GAMEPLAY_TIPS[currentTipIndex] or GAMEPLAY_TIPS[1]
	tipLabel.Text = tipEntry[currentLang] or tipEntry.en
	skipButton.Text = getSkipButtonLabel(currentLang)
end

local function computeStageAndProgress(elapsed: number): (number, number, boolean)
	-- Stage 1 (0 - 30%): game:IsLoaded()
	if not game:IsLoaded() then
		local s1 = math.clamp(elapsed / 1.8, 0, 0.90) * 0.30
		return 1, s1, false
	end

	-- Stage 2 (30 - 65%): ContentProvider.RequestQueueSize draining + ReplicatedStorage.DelegatedV5Sources
	local queueNow = ContentProvider.RequestQueueSize
	if queueNow > peakQueueSize then
		peakQueueSize = queueNow
	end
	local queueDrainRatio = if queueNow <= 0
		then 1
		else math.clamp(1 - (queueNow / math.max(peakQueueSize, 1)), 0, 1)
	local hasV5Sources = ReplicatedStorage:FindFirstChild("DelegatedV5Sources") ~= nil
	local stage2Ready = (hasV5Sources and queueNow <= 2) or (elapsed >= 3.6 and (hasV5Sources or queueNow <= 4))
	if not stage2Ready then
		local sourcePart = if hasV5Sources then 0.45 else math.clamp(elapsed / 3.2, 0, 0.35)
		local s2 = 0.30 + (0.35 * math.clamp(queueDrainRatio * 0.55 + sourcePart, 0, 0.96))
		return 2, s2, false
	end

	-- Stage 3 (65 - 90%): SkybreakMeshLoadedCount & SkybreakWorldReady == true
	local worldReady = workspace:GetAttribute("SkybreakWorldReady") == true
	local meshLoaded = tonumber(workspace:GetAttribute("SkybreakMeshLoadedCount")) or 0
	if not worldReady then
		local meshCurve = 1 - math.exp(-math.max(meshLoaded, 0) / 10)
		local timeAssist = math.clamp((elapsed - 1.2) / 5.5, 0, 0.45)
		local s3Ratio = math.clamp(math.max(meshCurve, timeAssist), 0, 0.94)
		return 3, 0.65 + (0.25 * s3Ratio), false
	end

	-- Stage 4 (90 - 100%): LocalPlayer.Character & HumanoidRootPart present
	local character = localPlayer.Character
	local hrp = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not (character and hrp) then
		local charBonus = if character then 0.05 else math.clamp((elapsed - 2.0) * 0.015, 0, 0.04)
		return 4, 0.90 + charBonus, false
	end

	return 5, 1.0, true
end

local function disconnectAll()
	for _, conn in ipairs(connections) do
		if conn.Connected then
			conn:Disconnect()
		end
	end
	table.clear(connections)
end

local function finishLoading()
	if finishing then
		return
	end
	finishing = true

	currentStageIndex = 5
	displayProgress = 1
	barFill.Size = UDim2.fromScale(1, 1)
	percentLabel.Text = "100%"
	refreshLocalizedTexts()

	localPlayer:SetAttribute("SkybreakLoadingDone", true)
	disconnectAll()

	local fadeInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fadeTween = TweenService:Create(rootCanvas, fadeInfo, {
		GroupTransparency = 1,
	})
	fadeTween:Play()

	task.delay(0.47, function()
		if screenGui and screenGui.Parent then
			screenGui:Destroy()
		end
	end)
end

local function revealSkipButton()
	if skipRevealed or finishing then
		return
	end
	skipRevealed = true
	skipButton.Visible = true
	skipButton.Active = true
	local revealInfo = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(skipButton, revealInfo, {
		BackgroundTransparency = 0.18,
		TextTransparency = 0,
	}):Play()
	TweenService:Create(skipStroke, revealInfo, {
		Transparency = 0.30,
	}):Play()
end

-- Interactive Skip Button & Keyboard Shortcut
table.insert(connections, skipButton.MouseEnter:Connect(function()
	if not finishing and skipRevealed then
		skipButton.BackgroundColor3 = COL_BTN_HOVER
		skipStroke.Transparency = 0.05
	end
end))

table.insert(connections, skipButton.MouseLeave:Connect(function()
	if not finishing and skipRevealed then
		skipButton.BackgroundColor3 = COL_BTN_BG
		skipStroke.Transparency = 0.30
	end
end))

table.insert(connections, skipButton.Activated:Connect(function()
	if os.clock() - startClock >= 1.8 then
		finishLoading()
	end
end))

table.insert(connections, UserInputService.InputBegan:Connect(function(input: InputObject, _gameProcessed: boolean)
	if finishing then
		return
	end
	if os.clock() - startClock < 1.8 then
		return
	end
	if UserInputService:GetFocusedTextBox() ~= nil then
		return
	end
	if input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.Return then
		finishLoading()
	end
end))

table.insert(connections, localPlayer:GetAttributeChangedSignal("Language"):Connect(function()
	if not finishing then
		refreshLocalizedTexts()
	end
end))

-- Main RenderStepped animation & progress loop
table.insert(connections, RunService.RenderStepped:Connect(function(dt: number)
	if finishing then
		return
	end

	local now = os.clock()
	local elapsed = now - startClock

	-- Reveal SKIP [SPACE] button after 1.8s
	if not skipRevealed and elapsed >= 1.8 then
		revealSkipButton()
	end

	-- Graceful hard cap at 7.5s so Studio testing or slow streaming never traps the player
	if elapsed >= 7.5 then
		finishLoading()
		return
	end

	-- Rotate Celestial Core Emblem rings & pulse central crystal
	outerRing.Rotation = (elapsed * 16) % 360
	midRing.Rotation = -(elapsed * 26) % 360
	innerFiligreeA.Rotation = 45 + math.sin(elapsed * 1.4) * 6
	coreScale.Scale = 1 + math.sin(elapsed * 3.1) * 0.08

	-- Drift 12 lightweight star motes
	for _, m in ipairs(starMotes) do
		m.y = m.y - (m.speedY * dt)
		if m.y < -0.04 then
			m.y = 1.04
		end
		local xOffset = math.sin(elapsed * m.swayFreq + m.phase) * m.swayAmp
		local twinkle = math.sin(elapsed * 2.4 + m.phase) * 0.18
		m.frame.Position = UDim2.fromScale(m.baseX + xOffset, m.y)
		m.frame.BackgroundTransparency = math.clamp(m.baseAlpha + twinkle, 0.12, 0.85)
	end

	-- Rotate bilingual gameplay tips every 2.8s
	if now - lastTipSwitch >= 2.8 then
		lastTipSwitch = now
		currentTipIndex = (currentTipIndex % #GAMEPLAY_TIPS) + 1
		local tipEntry = GAMEPLAY_TIPS[currentTipIndex]
		tipLabel.Text = tipEntry[currentLang] or tipEntry.en
	end

	-- Multi-stage progress tracking (monotonic smooth glide)
	local stageIdx, targetProg, allDone = computeStageAndProgress(elapsed)
	if stageIdx ~= currentStageIndex then
		currentStageIndex = stageIdx
		local stageEntry = STAGE_TEXT[currentStageIndex] or STAGE_TEXT[1]
		statusLabel.Text = stageEntry[currentLang] or stageEntry.en
	end

	if targetProg > displayProgress then
		local stepSpeed = if allDone then 4.8 else 2.6
		displayProgress = math.min(targetProg, displayProgress + math.max(targetProg - displayProgress, 0.04) * dt * stepSpeed)
	end

	local clamped = math.clamp(displayProgress, 0.02, 1)
	barFill.Size = UDim2.fromScale(clamped, 1)
	local pctInt = math.clamp(math.floor(displayProgress * 100 + 0.5), 0, 100)
	percentLabel.Text = tostring(pctInt) .. "%"

	if allDone and displayProgress >= 0.992 then
		finishLoading()
	end
end))
