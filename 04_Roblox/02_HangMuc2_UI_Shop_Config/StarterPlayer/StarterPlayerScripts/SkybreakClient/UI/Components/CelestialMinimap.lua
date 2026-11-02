--!strict
--[[
	CelestialMinimap.lua (#92, #50)
	148x148 Circular Celestial Minimap & Radar + Aether Natural Fruit Notifier.
	- Gold compass ring (N / E / S / W), zoom +/- buttons, click-to-open WorldMap [M]
	- Player directional arrow rotating with workspace.CurrentCamera.CFrame.LookVector
	- Nearby Sky Islands, Gold Diamond Quest target, Crimson Boss blips, Cyan NPC dots
	- Reads workspace:GetAttribute("NaturalFruitPos") & "NaturalFruitName" for pulsing
	  magenta/gold rim-clamped radar blip + "Trái Tự Nhiên: <Name> (124m)" pill.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SkybreakShared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(SkybreakShared:WaitForChild("Config"):WaitForChild("Theme"))
local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local I18n = require(script.Parent.Parent:WaitForChild("I18n"))

local LocalPlayer = Players.LocalPlayer

local SharedConfig: any = nil
task.spawn(function()
	local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
	local cfgMod = sharedFolder and sharedFolder:FindFirstChild("Config")
	if cfgMod and cfgMod:IsA("ModuleScript") then
		local ok, mod = pcall(require, cfgMod)
		if ok then
			SharedConfig = mod
		end
	end
end)

local CelestialMinimap = {}

local ZOOM_RANGES = { 160, 420, 1100, 3200 }
local DISC_SIZE = 148
local RADAR_RADIUS_PX = 60

local KNOWN_BOSS_KEYWORDS = {
	"aureon", "cryon", "noxar", "vance", "order", "seabeast", "reaper",
	"leviathan", "sovereign", "valen", "orion", "helios", "solarius",
	"kron", "boreas", "malakor", "zerath", "sylvaris", "ignivar", "nerith", "aion", "veyr",
}

local FALLBACK_ISLANDS = {
	{ Id = "SkyHub", Pos = Vector3.new(-317.4, 50.5, 527.8) },
	{ Id = "QuestCheckpoint", Pos = Vector3.new(-313.9, 50.5, 210.4) },
	{ Id = "ZiolesGachaShrine", Pos = Vector3.new(-560.0, 52.5, 996.0) },
	{ Id = "AetherShrines", Pos = Vector3.new(340.0, 52.5, 996.0) },
	{ Id = "WestGarden", Pos = Vector3.new(-2800.0, 50.5, -65.0) },
	{ Id = "LumenPlaza", Pos = Vector3.new(0.0, 50.5, 65.0) },
	{ Id = "SunshardSanctuary", Pos = Vector3.new(2800.0, 50.5, -55.0) },
	{ Id = "BossForecourt", Pos = Vector3.new(0.0, 50.5, -285.0) },
	{ Id = "FrozenCyber", Pos = Vector3.new(11620.5, 50.9, 534.8) },
	{ Id = "CyberportCafe", Pos = Vector3.new(9400.0, 50.9, 1785.0) },
	{ Id = "PermafrostGarrison", Pos = Vector3.new(9400.0, 50.9, -2055.0) },
	{ Id = "MicrochipRaidLab", Pos = Vector3.new(14600.0, 50.9, 1785.0) },
	{ Id = "GlacialWreckage", Pos = Vector3.new(14600.0, 50.9, -1812.0) },
	{ Id = "CryonArena", Pos = Vector3.new(12000.0, 50.9, -285.0) },
	{ Id = "ShadowRealm", Pos = Vector3.new(-12593.4, 50.9, 414.0) },
	{ Id = "CastleOnTheVoid", Pos = Vector3.new(-14600.0, 50.9, 2173.1) },
	{ Id = "UmbralSanctum", Pos = Vector3.new(-9400.0, 50.9, 1815.0) },
	{ Id = "TempleOfTheCore", Pos = Vector3.new(-14600.0, 50.9, -1785.0) },
	{ Id = "LeviathanAbyss", Pos = Vector3.new(-12000.0, 50.9, -3364.5) },
	{ Id = "NoxarArena", Pos = Vector3.new(-11672.2, 50.9, -110.0) },
	{ Id = "VerdantCrown", Pos = Vector3.new(0.0, 170.9, -8985.0) },
	{ Id = "EmberforgeWastes", Pos = Vector3.new(12000.0, 170.5, -9265.0) },
	{ Id = "AbyssalTides", Pos = Vector3.new(-12000.0, 170.9, -8964.5) },
	{ Id = "ChronosBastion", Pos = Vector3.new(0.0, 230.9, -13485.0) },
	{ Id = "VeilsEnd", Pos = Vector3.new(0.0, 310.9, -17626.9) },
}

local function getModelWorldPos(inst: Instance): Vector3?
	if inst:IsA("BasePart") then
		return inst.Position
	elseif inst:IsA("Model") then
		if inst.PrimaryPart then
			return inst.PrimaryPart.Position
		end
		local hrp = inst:FindFirstChild("HumanoidRootPart") or inst:FindFirstChildWhichIsA("BasePart")
		if hrp and hrp:IsA("BasePart") then
			return hrp.Position
		end
		local ok, piv = pcall(function()
			return inst:GetPivot()
		end)
		if ok and piv then
			return piv.Position
		end
	end
	return nil
end

function CelestialMinimap.IsAliveBossModel(inst: Instance): boolean
	if not inst:IsA("Model") then
		return false
	end
	if LocalPlayer and LocalPlayer.Character == inst then
		return false
	end
	if Players:GetPlayerFromCharacter(inst) ~= nil then
		return false
	end

	local isBossAttr = inst:GetAttribute("IsBoss") == true
		or inst:GetAttribute("Boss") == true
		or inst:GetAttribute("BossPhase") ~= nil
	local enemyId = tostring(inst:GetAttribute("EnemyId") or inst:GetAttribute("BossId") or "")
	if not isBossAttr and SharedConfig and SharedConfig.Enemies and enemyId ~= "" then
		local def = SharedConfig.Enemies[enemyId]
		if def and def.Boss then
			isBossAttr = true
		end
	end
	if not isBossAttr then
		local lowerName = string.lower(inst.Name .. " " .. enemyId)
		for _, kw in ipairs(KNOWN_BOSS_KEYWORDS) do
			if string.find(lowerName, kw, 1, true) then
				isBossAttr = true
				break
			end
		end
	end
	if not isBossAttr then
		return false
	end

	local hum = inst:FindFirstChildOfClass("Humanoid")
	if hum then
		return hum.Health > 0
	end
	local hpAttr = tonumber(inst:GetAttribute("HP") or inst:GetAttribute("Health"))
	if hpAttr ~= nil then
		return hpAttr > 0
	end
	return true
end

function CelestialMinimap.FindClosestLiveBoss(origin: Vector3): (Model?, number, Vector3?)
	local bestModel: Model? = nil
	local bestDist = math.huge
	local bestPos: Vector3? = nil

	local function checkChild(child: Instance)
		if CelestialMinimap.IsAliveBossModel(child) then
			local pos = getModelWorldPos(child)
			if pos then
				local d = (pos - origin).Magnitude
				if d < bestDist then
					bestDist = d
					bestModel = child :: Model
					bestPos = pos
				end
			end
		end
	end

	for _, folderName in ipairs({ "ActiveBosses", "ActiveEnemies", "Enemies" }) do
		local folder = workspace:FindFirstChild(folderName)
		if folder then
			for _, child in ipairs(folder:GetChildren()) do
				checkChild(child)
			end
		end
	end
	for _, child in ipairs(workspace:GetChildren()) do
		checkChild(child)
	end

	return bestModel, bestDist, bestPos
end

function CelestialMinimap.Create(parent: GuiObject, onOpenMap: (() -> ())?)
	local zoomIdx = 3 -- Default 1100 studs for Gameplay3x spans

	local wrapper = UIFactory.Create("Frame", parent, {
		Name = "CelestialMinimapContainer",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 12),
		Size = UDim2.fromOffset(176, 182),
		BackgroundTransparency = 1,
		ZIndex = 12,
	})

	-- Outer Gold Astral Ring (148x148)
	local outerRing = UIFactory.Create("Frame", wrapper, {
		Name = "CompassRing",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.fromOffset(DISC_SIZE, DISC_SIZE),
		BackgroundColor3 = Theme.Colors.BG_900,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		ZIndex = 13,
	})
	UIFactory.PillCorner(outerRing)
	UIFactory.Stroke(outerRing, Theme.Colors.ACCENT_GOLD, 2, 0.12)

	-- Inner Radar Disc
	local radarDisc = UIFactory.Create("Frame", outerRing, {
		Name = "RadarDisc",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(DISC_SIZE - 16, DISC_SIZE - 16),
		BackgroundColor3 = Color3.fromRGB(10, 18, 32),
		BackgroundTransparency = 0.10,
		BorderSizePixel = 0,
		ClipsDescendants = true,
		ZIndex = 14,
	})
	UIFactory.PillCorner(radarDisc)
	UIFactory.Stroke(radarDisc, Theme.Colors.STROKE_STEEL, 1, 0.35)

	local midRing = UIFactory.Create("Frame", radarDisc, {
		Name = "MidRangeRing",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(74, 74),
		BackgroundTransparency = 1,
		ZIndex = 15,
	})
	UIFactory.PillCorner(midRing)
	UIFactory.Stroke(midRing, Theme.Colors.ACCENT_GOLD, 1, 0.72)

	UIFactory.Create("Frame", radarDisc, {
		Name = "AxisH",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, -12, 0, 1),
		BackgroundColor3 = Theme.Colors.STROKE_STEEL,
		BackgroundTransparency = 0.72,
		BorderSizePixel = 0,
		ZIndex = 15,
	})
	UIFactory.Create("Frame", radarDisc, {
		Name = "AxisV",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 1, 1, -12),
		BackgroundColor3 = Theme.Colors.STROKE_STEEL,
		BackgroundTransparency = 0.72,
		BorderSizePixel = 0,
		ZIndex = 15,
	})

	-- Cardinal N / E / S / W markers on gold compass ring
	local cardinals = {
		{ Text = "N", Pos = UDim2.new(0.5, 0, 0, 1), Color = Theme.Colors.ACCENT_GOLD_BRIGHT },
		{ Text = "E", Pos = UDim2.new(1, -1, 0.5, 0), Color = Theme.Colors.TEXT_SECONDARY },
		{ Text = "S", Pos = UDim2.new(0.5, 0, 1, -1), Color = Theme.Colors.TEXT_SECONDARY },
		{ Text = "W", Pos = UDim2.new(0, 1, 0.5, 0), Color = Theme.Colors.TEXT_SECONDARY },
	}
	for _, c in ipairs(cardinals) do
		local badge = UIFactory.Create("Frame", outerRing, {
			Name = "Cardinal_" .. c.Text,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = c.Pos,
			Size = UDim2.fromOffset(16, 16),
			BackgroundColor3 = Theme.Colors.BG_800,
			BackgroundTransparency = 0.08,
			BorderSizePixel = 0,
			ZIndex = 19,
		})
		UIFactory.PillCorner(badge)
		UIFactory.Stroke(badge, Theme.Colors.ACCENT_GOLD, 1, 0.35)
		UIFactory.Label(badge, {
			Name = "Txt",
			Text = c.Text,
			TextSize = 10,
			TextColor = c.Color,
			Bold = true,
			XAlign = Enum.TextXAlignment.Center,
			Size = UDim2.fromScale(1, 1),
			Wrapped = false,
			ZIndex = 20,
		})
	end

	local islandLayer = UIFactory.Create("Frame", radarDisc, {
		Name = "IslandLayer",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 16,
	})
	local markerLayer = UIFactory.Create("Frame", radarDisc, {
		Name = "MarkerLayer",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 17,
	})

	local islandBlips: { Frame } = {}
	for i = 1, 20 do
		local isl = UIFactory.Create("Frame", islandLayer, {
			Name = "Isl_" .. i,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(18, 18),
			BackgroundColor3 = Color3.fromRGB(54, 92, 148),
			BackgroundTransparency = 0.50,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 16,
		})
		UIFactory.PillCorner(isl)
		UIFactory.Stroke(isl, Theme.Colors.ACCENT_GOLD, 1, 0.48)
		table.insert(islandBlips, isl)
	end

	local npcDots: { Frame } = {}
	for i = 1, 10 do
		local dot = UIFactory.Create("Frame", markerLayer, {
			Name = "NPC_" .. i,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(5, 5),
			BackgroundColor3 = Theme.Colors.ACCENT_ICE,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 17,
		})
		UIFactory.PillCorner(dot)
		table.insert(npcDots, dot)
	end

	local bossBlips: { Frame } = {}
	for i = 1, 6 do
		local b = UIFactory.Create("Frame", markerLayer, {
			Name = "Boss_" .. i,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromOffset(9, 9),
			BackgroundColor3 = Theme.Colors.HP_RED,
			BorderSizePixel = 0,
			Rotation = 45,
			Visible = false,
			ZIndex = 18,
		})
		UIFactory.Corner(b, 2)
		UIFactory.Stroke(b, Color3.fromRGB(255, 215, 215), 1, 0.15)
		table.insert(bossBlips, b)
	end

	-- Active Quest Gold Diamond Marker
	local questDiamond = UIFactory.Create("Frame", markerLayer, {
		Name = "QuestMarker",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(8, 8),
		BackgroundColor3 = Theme.Colors.ACCENT_GOLD_BRIGHT,
		BorderSizePixel = 0,
		Rotation = 45,
		Visible = true,
		ZIndex = 19,
	})
	UIFactory.Stroke(questDiamond, Color3.new(1, 1, 1), 1, 0.2)

	-- #50 Pulsing Magenta/Gold Natural Fruit Blip (clamped to rim)
	local fruitBlip = UIFactory.Create("Frame", outerRing, {
		Name = "NaturalFruitBlip",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(11, 11),
		BackgroundColor3 = Color3.fromRGB(245, 76, 255),
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 22,
	})
	UIFactory.PillCorner(fruitBlip)
	local fruitBlipStroke = UIFactory.Stroke(fruitBlip, Theme.Colors.ACCENT_GOLD_BRIGHT, 1.8, 0)

	-- Center Player Directional Arrow
	local playerArrowWrap = UIFactory.Create("Frame", radarDisc, {
		Name = "PlayerArrow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		ZIndex = 20,
	})
	local arrowTip = UIFactory.Create("Frame", playerArrowWrap, {
		Name = "Tip",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.36),
		Size = UDim2.fromOffset(7, 7),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Rotation = 45,
		ZIndex = 21,
	})
	UIFactory.Stroke(arrowTip, Theme.Colors.ACCENT_SAPPHIRE, 1.2, 0)
	local arrowCore = UIFactory.Create("Frame", playerArrowWrap, {
		Name = "Core",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.58),
		Size = UDim2.fromOffset(6, 6),
		BackgroundColor3 = Theme.Colors.ACCENT_SAPPHIRE,
		BorderSizePixel = 0,
		ZIndex = 22,
	})
	UIFactory.PillCorner(arrowCore)

	-- Click-to-open WorldMap [M]
	local clickBtn = UIFactory.Create("TextButton", outerRing, {
		Name = "OpenWorldMapHitbox",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 18,
	})
	clickBtn.Activated:Connect(function()
		if onOpenMap then
			onOpenMap()
		end
	end)

	-- Range & [M] badge at bottom of ring
	local rangePill = UIFactory.Create("Frame", outerRing, {
		Name = "RangeBadge",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, -2),
		Size = UDim2.fromOffset(48, 17),
		BackgroundColor3 = Theme.Colors.BG_800,
		BackgroundTransparency = 0.10,
		BorderSizePixel = 0,
		ZIndex = 21,
	})
	UIFactory.PillCorner(rangePill)
	UIFactory.Stroke(rangePill, Theme.Colors.ACCENT_GOLD, 1, 0.35)
	local rangeLabel = UIFactory.Label(rangePill, {
		Name = "RangeText",
		Text = tostring(ZOOM_RANGES[zoomIdx]) .. "m",
		TextSize = 10,
		TextColor = Theme.Colors.ACCENT_GOLD_BRIGHT,
		Bold = true,
		XAlign = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1),
		Wrapped = false,
		ZIndex = 22,
	})

	local mapKeyPill = UIFactory.Create("Frame", outerRing, {
		Name = "MapKeyBadge",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, 0, 1, -2),
		Size = UDim2.fromOffset(30, 17),
		BackgroundColor3 = Theme.Colors.BG_800,
		BackgroundTransparency = 0.10,
		BorderSizePixel = 0,
		ZIndex = 21,
	})
	UIFactory.PillCorner(mapKeyPill)
	UIFactory.Stroke(mapKeyPill, Theme.Colors.ACCENT_GOLD, 1, 0.25)
	UIFactory.Label(mapKeyPill, {
		Name = "KeyText",
		Text = "[M]",
		TextSize = 10,
		TextColor = Theme.Colors.ACCENT_GOLD_BRIGHT,
		Bold = true,
		XAlign = Enum.TextXAlignment.Center,
		Size = UDim2.fromScale(1, 1),
		Wrapped = false,
		ZIndex = 22,
	})

	-- Zoom +/- buttons on left rim
	local function makeZoomBtn(name: string, text: string, yOffset: number, delta: number)
		local btn = UIFactory.Create("TextButton", wrapper, {
			Name = name,
			Size = UDim2.fromOffset(22, 22),
			Position = UDim2.fromOffset(0, yOffset),
			BackgroundColor3 = Theme.Colors.BG_800,
			BackgroundTransparency = 0.08,
			BorderSizePixel = 0,
			Font = Theme.Fonts.Bold,
			Text = text,
			TextSize = 14,
			TextColor3 = Theme.Colors.ACCENT_GOLD_BRIGHT,
			AutoButtonColor = true,
			ZIndex = 23,
		})
		UIFactory.Corner(btn, Theme.Radius.Small)
		UIFactory.Stroke(btn, Theme.Colors.ACCENT_GOLD, 1, 0.25)
		btn.Activated:Connect(function()
			zoomIdx = math.clamp(zoomIdx + delta, 1, #ZOOM_RANGES)
			rangeLabel.Text = tostring(ZOOM_RANGES[zoomIdx]) .. "m"
		end)
	end
	makeZoomBtn("ZoomInBtn", "+", 36, -1)
	makeZoomBtn("ZoomOutBtn", "-", 64, 1)

	-- #50 Natural Fruit Notifier Pill underneath Minimap
	local fruitPill = UIFactory.Create("Frame", wrapper, {
		Name = "NaturalFruitNotifierPill",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, DISC_SIZE + 5),
		Size = UDim2.fromOffset(204, 24),
		BackgroundColor3 = Color3.fromRGB(32, 14, 46),
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
		Visible = false,
		ZIndex = 22,
	})
	UIFactory.PillCorner(fruitPill)
	local fruitPillStroke = UIFactory.Stroke(fruitPill, Color3.fromRGB(245, 76, 255), 1.3, 0.12)
	local fruitIcon = UIFactory.Icon(fruitPill, "Fruit", UDim2.new(0, 7, 0.5, 0), 13, Theme.Colors.ACCENT_GOLD_BRIGHT)
	fruitIcon.AnchorPoint = Vector2.new(0, 0.5)
	fruitIcon.ZIndex = 23

	local fruitPillLabel = UIFactory.Label(fruitPill, {
		Name = "FruitNotifierText",
		Text = "",
		TextSize = 11,
		TextColor = Theme.Colors.ACCENT_GOLD_BRIGHT,
		Bold = true,
		Position = UDim2.fromOffset(24, 0),
		Size = UDim2.new(1, -30, 1, 0),
		Wrapped = false,
		Truncate = Enum.TextTruncate.AtEnd,
		ZIndex = 23,
	})

	-- Throttled world scan state
	local cachedBossPositions: { Vector3 } = {}
	local cachedNpcPositions: { Vector3 } = {}
	local cachedQuestTarget: Vector3? = Vector3.new(-313.9, 50.5, 210.4)
	local lastScanAt = 0

	local function refreshWorldMarkers()
		table.clear(cachedBossPositions)
		table.clear(cachedNpcPositions)

		for _, folderName in ipairs({ "ActiveBosses", "ActiveEnemies", "Enemies" }) do
			local folder = workspace:FindFirstChild(folderName)
			if folder then
				for _, child in ipairs(folder:GetChildren()) do
					if CelestialMinimap.IsAliveBossModel(child) then
						local pos = getModelWorldPos(child)
						if pos then
							table.insert(cachedBossPositions, pos)
						end
					end
				end
			end
		end

		for _, child in ipairs(workspace:GetChildren()) do
			if CelestialMinimap.IsAliveBossModel(child) then
				local pos = getModelWorldPos(child)
				if pos then
					table.insert(cachedBossPositions, pos)
				end
			elseif child:GetAttribute("InteractableId") ~= nil
				or string.find(child.Name, "Lyra")
				or string.find(child.Name, "Kael")
				or string.find(child.Name, "Zioles")
			then
				local pos = getModelWorldPos(child)
				if pos and #cachedNpcPositions < 10 then
					table.insert(cachedNpcPositions, pos)
				end
			end
		end

		local npcsFolder = workspace:FindFirstChild("NPCs")
		if npcsFolder then
			for _, child in ipairs(npcsFolder:GetChildren()) do
				local pos = getModelWorldPos(child)
				if pos and #cachedNpcPositions < 10 then
					table.insert(cachedNpcPositions, pos)
				end
			end
		end

		local worldObjsFolder = workspace:FindFirstChild("SkybreakWorldObjects")
		if worldObjsFolder then
			for _, child in ipairs(worldObjsFolder:GetChildren()) do
				if child:GetAttribute("NPCId") ~= nil then
					local pos = getModelWorldPos(child)
					if pos and #cachedNpcPositions < 10 then
						table.insert(cachedNpcPositions, pos)
					end
				end
			end
		end

		local qPart = workspace:FindFirstChild("QuestCheckpoint")
		if qPart then
			local qPos = getModelWorldPos(qPart)
			if qPos then
				cachedQuestTarget = qPos
			end
		end
	end

	local function projectToRadar(origin: Vector3, target: Vector3, rangeStuds: number, maxPx: number, clampToRim: boolean): (number, number, boolean)
		local dx = target.X - origin.X
		local dz = target.Z - origin.Z
		local nx = dx / math.max(1, rangeStuds)
		local nz = dz / math.max(1, rangeStuds)
		local mag = math.sqrt(nx * nx + nz * nz)
		if mag > 1 then
			if not clampToRim then
				return 0, 0, false
			end
			nx /= mag
			nz /= mag
		end
		return nx * maxPx, nz * maxPx, true
	end

	local pulseClock = 0
	local destroyed = false
	local renderConn: RBXScriptConnection? = nil
	renderConn = RunService.RenderStepped:Connect(function(dt: number)
		if destroyed or not wrapper.Visible or not wrapper:IsDescendantOf(game) then
			return
		end
		local parentGui = wrapper.Parent
		if parentGui and parentGui:IsA("GuiObject") and not parentGui.Visible then
			return
		end
		pulseClock += dt
		local now = os.clock()
		if now - lastScanAt >= 0.45 then
			lastScanAt = now
			refreshWorldMarkers()
		end

		local cam = workspace.CurrentCamera
		local playerPos = Vector3.new(-317.4, 50.5, 527.8)
		if LocalPlayer and LocalPlayer.Character then
			local pp = LocalPlayer.Character.PrimaryPart or LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if pp and pp:IsA("BasePart") then
				playerPos = pp.Position
			end
		elseif cam then
			playerPos = cam.CFrame.Position
		end

		if cam then
			local look = cam.CFrame.LookVector
			local angleDeg = math.deg(math.atan2(look.X, -look.Z))
			playerArrowWrap.Rotation = angleDeg
		end

		local range = ZOOM_RANGES[zoomIdx]

		local islandsSource = (SharedConfig and SharedConfig.Islands) or FALLBACK_ISLANDS
		local islUsed = 0
		for _, isl in ipairs(islandsSource) do
			if islUsed >= #islandBlips then
				break
			end
			local pos: Vector3? = isl.Pos
			if typeof(pos) == "Vector3" and isl.Id ~= "GoldenSky" then
				local px, pz, vis = projectToRadar(playerPos, pos, range, RADAR_RADIUS_PX, false)
				if vis then
					islUsed += 1
					local blip = islandBlips[islUsed]
					local diam = math.clamp(math.floor((420 / range) * 16), 9, 26)
					blip.Size = UDim2.fromOffset(diam, diam)
					blip.Position = UDim2.new(0.5, math.floor(px), 0.5, math.floor(pz))
					blip.Visible = true
				end
			end
		end
		for i = islUsed + 1, #islandBlips do
			islandBlips[i].Visible = false
		end

		for i = 1, #npcDots do
			local pos = cachedNpcPositions[i]
			if pos then
				local px, pz, vis = projectToRadar(playerPos, pos, range, RADAR_RADIUS_PX - 4, false)
				npcDots[i].Visible = vis
				if vis then
					npcDots[i].Position = UDim2.new(0.5, math.floor(px), 0.5, math.floor(pz))
				end
			else
				npcDots[i].Visible = false
			end
		end

		for i = 1, #bossBlips do
			local pos = cachedBossPositions[i]
			if pos and (pos - playerPos).Magnitude <= range * 2.2 then
				local px, pz, vis = projectToRadar(playerPos, pos, range, RADAR_RADIUS_PX - 5, true)
				bossBlips[i].Visible = vis
				if vis then
					bossBlips[i].Position = UDim2.new(0.5, math.floor(px), 0.5, math.floor(pz))
				end
			else
				bossBlips[i].Visible = false
			end
		end

		if cachedQuestTarget then
			local px, pz, vis = projectToRadar(playerPos, cachedQuestTarget, range, RADAR_RADIUS_PX - 5, true)
			questDiamond.Visible = vis
			if vis then
				questDiamond.Position = UDim2.new(0.5, math.floor(px), 0.5, math.floor(pz))
			end
		else
			questDiamond.Visible = false
		end

		-- #50 Natural Fruit Notifier
		local fruitPosAttr = workspace:GetAttribute("NaturalFruitPos")
		local fruitNameAttr = workspace:GetAttribute("NaturalFruitName")
		if typeof(fruitPosAttr) == "Vector3" and type(fruitNameAttr) == "string" and fruitNameAttr ~= "" then
			local distMeters = math.max(1, math.floor((fruitPosAttr - playerPos).Magnitude + 0.5))
			local px, pz = projectToRadar(playerPos, fruitPosAttr, range, (DISC_SIZE * 0.5) - 9, true)
			local pulse = 0.5 + 0.5 * math.sin(pulseClock * 5.5)
			local sz = math.floor(10 + pulse * 4)

			fruitBlip.Visible = true
			fruitBlip.Size = UDim2.fromOffset(sz, sz)
			fruitBlip.Position = UDim2.new(0.5, math.floor(px), 0.5, math.floor(pz))
			fruitBlip.BackgroundColor3 = Color3.fromRGB(245, 76, 255):Lerp(Theme.Colors.ACCENT_GOLD_BRIGHT, pulse * 0.55)
			fruitBlipStroke.Transparency = 0.1 + (1 - pulse) * 0.35

			local localizedFruit = I18n.GetItemDisplayName(fruitNameAttr, fruitNameAttr)
			fruitPill.Visible = true
			fruitPillLabel.Text = I18n.T("hud.fruit_radar", localizedFruit, distMeters)
			fruitPillStroke.Color = Color3.fromRGB(245, 76, 255):Lerp(Theme.Colors.ACCENT_GOLD_BRIGHT, pulse * 0.5)
		else
			fruitBlip.Visible = false
			fruitPill.Visible = false
		end
	end)

	local api = {}
	api.Instance = wrapper

	function api:SetQuestTarget(pos: Vector3?)
		cachedQuestTarget = pos
	end

	function api:Destroy()
		if destroyed then
			return
		end
		destroyed = true
		if renderConn then
			renderConn:Disconnect()
			renderConn = nil
		end
		if wrapper.Parent then
			wrapper:Destroy()
		end
	end

	wrapper.Destroying:Once(function()
		if not destroyed then
			destroyed = true
			if renderConn then
				renderConn:Disconnect()
				renderConn = nil
			end
		end
	end)

	return api
end

return CelestialMinimap
