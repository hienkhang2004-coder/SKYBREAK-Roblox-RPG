-- SKYBREAK: Fragments of the Core — Microchip Awakening Raid Lab & 50F Sky Spire Console ([P])
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/Raid.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local UIState = require(Shared:WaitForChild("Types"):WaitForChild("UIState"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Store = require(script.Parent.Parent:WaitForChild("Store"))
local ScreenRouter = require(script.Parent.Parent:WaitForChild("ScreenRouter"))
local I18n = require(script.Parent.Parent:WaitForChild("I18n"))
local PremiumPanel = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumPanel"))
local PremiumButton = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumButton"))
local RaidPhase = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("RaidPhase"))
local PartyController = require(script.Parent.Parent:WaitForChild("Controllers"):WaitForChild("PartyController"))

local Raid = {
	Refs = {},
	LastSig = nil,
}

local RAID_DIFFICULTIES = {
	{
		Id = "Normal",
		LabelVi = "NORMAL (THƯỜNG)",
		LabelEn = "NORMAL",
		Mult = "1.0x HP Quái",
		RewardVi = "+250 Core Shards • Mở khóa Thức Tỉnh V2",
		RewardEn = "+250 Core Shards • Unlocks V2 Awakening",
		Color = Color3.fromRGB(56, 189, 248),
	},
	{
		Id = "Hard",
		LabelVi = "HARD (KHÓ)",
		LabelEn = "HARD",
		Mult = "1.6x HP Quái",
		RewardVi = "+500 Core Shards • Mở khóa Thức Tỉnh V2",
		RewardEn = "+500 Core Shards • Unlocks V2 Awakening",
		Color = Color3.fromRGB(252, 211, 77),
	},
	{
		Id = "Nightmare",
		LabelVi = "NIGHTMARE (ÁC MỘNG)",
		LabelEn = "NIGHTMARE",
		Mult = "2.5x HP Quái",
		RewardVi = "+1,000 Core Shards + Awakening Microchip",
		RewardEn = "+1,000 Core Shards + Awakening Microchip",
		Color = Color3.fromRGB(251, 113, 133),
	},
}

local MICROCHIP_WAVES = {
	{ Wave = 1, TitleVi = "WAVE 1 • Tiên Phong Cơ Giới (Mecha Vanguard)", DescVi = "Tiêu diệt đội hình Mecha Drone tuần tra mở khóa lõi truyền dẫn." },
	{ Wave = 2, TitleVi = "WAVE 2 • Quân Đoàn Thiết Giáp (Cyber Enforcers)", DescVi = "Đánh tan 2 nhóm Lính Đánh Thuê Cyber & Hộ Vệ Năng Lượng." },
	{ Wave = 3, TitleVi = "WAVE 3 • Pháo Thủ Hàn Băng (Cryo Artillery)", DescVi = "Né tránh loạt đạn từ trường và hạ gục đội bắn tỉa tinh nhuệ." },
	{ Wave = 4, TitleVi = "WAVE 4 • Cận Vệ Lượng Tử (Quantum Order Guard)", DescVi = "Vượt qua đội cận vệ cường hóa trước cửa buồng Lõi Thức Tỉnh." },
	{ Wave = 5, TitleVi = "WAVE 5 • BOSS ORDER CYBORG (MỞ KHÓA V2!)", DescVi = "Hạ gục Boss Order Cyborg để nhận +Core Shards & +1 RaidChipsCleared (mở khóa Thức Tỉnh Lõi V2 tại phím [G])!" },
}

local SPIRE_MILESTONES = {
	{ Floor = 10, RarityCol = Color3.fromRGB(56, 189, 248), Title = "TẦNG 10 • TÂN TINH BẦU TRỜI", Reward = "+50,000 Gold • +100 Core Shards • Cuộn Cổ Ngữ" },
	{ Floor = 20, RarityCol = Color3.fromRGB(52, 211, 153), Title = "TẦNG 20 • KIẾM KHÁCH TẦNG MÂY", Reward = "+100,000 Gold • +200 Core Shards" },
	{ Floor = 30, RarityCol = Color3.fromRGB(192, 132, 252), Title = "TẦNG 30 • THỐNG LĨNH THIÊN THÁP", Reward = "+175,000 Gold • +350 Core Shards • Nhẫn Aureon" },
	{ Floor = 40, RarityCol = Color3.fromRGB(252, 211, 77), Title = "TẦNG 40 • HỘ VỆ TINH VÂN", Reward = "+275,000 Gold • +600 Core Shards • Mũ Hư Quang" },
	{ Floor = 50, RarityCol = Color3.fromRGB(251, 113, 133), Title = "TẦNG 50 • BÁ CHỦ SKY SPIRE", Reward = "+500,000 Gold • +1,000 Core Shards • Danh Hiệu [Bá Chủ Tháp Trời]" },
}

local function fireRaidCommand(cmd, payload)
	payload = type(payload) == "table" and payload or {}
	local skyRems = Shared:FindFirstChild("Remotes")
	local sharedReq = skyRems and (skyRems:FindFirstChild("UIRequest") or skyRems:FindFirstChild("UICommand"))
	if sharedReq and sharedReq:IsA("RemoteEvent") then
		sharedReq:FireServer(cmd, payload)
		return
	end
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local uiReq = remotes and (remotes:FindFirstChild("UIRequest") or remotes:FindFirstChild("UICommand"))
	if uiReq and uiReq:IsA("RemoteEvent") then
		uiReq:FireServer(cmd, payload)
	end
end

local function findSpareStoredFruit(snap)
	local stored = (snap and snap.fruits and snap.fruits.storedFruits) or {}
	local bestId, bestCount = nil, 0
	for fid, cnt in pairs(stored) do
		local n = tonumber(cnt) or 0
		if n > 0 and (not bestId or n > bestCount) then
			bestId = tostring(fid)
			bestCount = n
		end
	end
	return bestId, bestCount
end

local function buildMicrochipRaidTab(body, snap)
	local colors = Theme.Colors
	local lp = Players.LocalPlayer
	local selectedDiff = Store.Session.selectedRaidDifficulty
		or (lp and lp:GetAttribute("RaidDifficulty"))
		or workspace:GetAttribute("RaidDifficulty")
		or "Normal"
	if selectedDiff ~= "Normal" and selectedDiff ~= "Hard" and selectedDiff ~= "Nightmare" then
		selectedDiff = "Normal"
	end

	local chipsCleared = math.max(0, math.floor(tonumber(snap.raidChipsCleared) or 0))
	local v2Ready = chipsCleared >= 1
	local spareFruitId, spareFruitQty = findSpareStoredFruit(snap)
	local playerGold = tonumber(snap.currencies and snap.currencies.gold) or 0

	-- Top Status Banner (Live Raid Combat Bar if active, or Microchip Awakening V2 Status Banner)
	local activeRaidWave = tonumber(workspace:GetAttribute("RaidWave")) or 0
	if (snap.raid and snap.raid.active) or activeRaidWave > 0 then
		local _, raidPreviewApi = RaidPhase.Create(body, {
			name = "LiveRaidBanner",
			anchorPoint = Vector2.new(0, 0),
			position = UDim2.fromOffset(0, 0),
			size = UDim2.new(1, 0, 0, 96),
			bossName = (snap.raid and snap.raid.bossName ~= "" and snap.raid.bossName)
				or string.format("MICROCHIP AWAKENING RAID • WAVE %d / 5", math.max(1, activeRaidWave)),
			bossHp = (snap.raid and snap.raid.bossHp) or 100000,
			bossMaxHp = (snap.raid and snap.raid.bossMaxHp) or 100000,
			visible = true,
		})
		raidPreviewApi:Update({
			active = true,
			bossName = (snap.raid and snap.raid.bossName ~= "" and snap.raid.bossName)
				or string.format("MICROCHIP AWAKENING RAID • WAVE %d / 5", math.max(1, activeRaidWave)),
			phase = math.clamp(activeRaidWave > 0 and activeRaidWave or ((snap.raid and snap.raid.phase) or 1), 1, 5),
			maxPhases = 5,
			phaseTitle = "ĐỘ KHÓ: " .. UIFactory.Upper(selectedDiff),
			bossHp = (snap.raid and snap.raid.bossHp) or 100000,
			bossMaxHp = (snap.raid and snap.raid.bossMaxHp) or 100000,
			warningText = I18n.Pick("Vượt Wave 5 để mở khóa Thức Tỉnh Lõi V2 & nhận Core Shards!", "Clear Wave 5 to unlock Core V2 Awakening & Core Shards!"),
		})
	else
		local statusBanner = UIFactory.Create("Frame", body, {
			Name = "MicrochipStatusBanner",
			Position = UDim2.fromOffset(0, 0),
			Size = UDim2.new(1, 0, 0, 74),
			BackgroundColor3 = v2Ready and Color3.fromRGB(10, 44, 34) or Color3.fromRGB(14, 22, 42),
			BorderSizePixel = 0,
		})
		UIFactory.Corner(statusBanner, Theme.Radius.Medium)
		UIFactory.Stroke(statusBanner, v2Ready and colors.SUCCESS or colors.ACCENT_GOLD_BRIGHT, 1.5, 0.14)

		UIFactory.Icon(statusBanner, "Bolt", UDim2.fromOffset(14, 16), 28, v2Ready and colors.SUCCESS or colors.ACCENT_GOLD_BRIGHT)
		UIFactory.Label(statusBanner, {
			Name = "BannerTitle",
			Text = v2Ready
				and string.format("ĐÃ VƯỢT %d ẢI MICROCHIP RAID ✓  •  ĐÃ MỞ KHÓA ĐIỀU KIỆN THỨC TỈNH LÕI V2 [PHÍM G]!", chipsCleared)
				or "CHƯA VƯỢT ẢI MICROCHIP RAID (0 / 1)  •  VƯỢT WAVE 5 ĐỂ MỞ KHÓA THỨC TỈNH LÕI V2!",
			Position = UDim2.fromOffset(52, 10),
			Size = UDim2.new(1, -240, 0, 22),
			TextSize = 13,
			TextColor = v2Ready and colors.SUCCESS or colors.ACCENT_GOLD_BRIGHT,
			Bold = true,
			Truncate = Enum.TextTruncate.AtEnd,
		})
		UIFactory.Label(statusBanner, {
			Name = "BannerDesc",
			Text = I18n.Pick(
				"Mua Microchip (100,000 Gold hoặc đổi 1 Trái Dư trong Kho) để triệu hồi Tổ Đội vào Đấu Trường Đột Kích 5 Waves!",
				"Purchase a Microchip (100,000 Gold or 1 Spare Stored Core) to launch the 5-Wave Awakening Raid!"
			),
			Position = UDim2.fromOffset(52, 36),
			Size = UDim2.new(1, -240, 0, 22),
			TextSize = 11,
			TextColor = colors.TEXT_PRIMARY,
			Truncate = Enum.TextTruncate.AtEnd,
		})

		local countBadge = UIFactory.Create("Frame", statusBanner, {
			Name = "ChipsClearedBadge",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.fromOffset(172, 46),
			BackgroundColor3 = Color3.fromRGB(8, 12, 22),
			BorderSizePixel = 0,
		})
		UIFactory.Corner(countBadge, Theme.Radius.Small)
		UIFactory.Stroke(countBadge, v2Ready and colors.SUCCESS or colors.ACCENT_GOLD, 1.2, 0.2)
		UIFactory.Label(countBadge, {
			Name = "CountTxt",
			Text = string.format("RAID CHIPS CLEARED\n%d ẢI ĐÃ VƯỢT", chipsCleared),
			Size = UDim2.fromScale(1, 1),
			TextSize = 11,
			TextColor = v2Ready and colors.SUCCESS or colors.ACCENT_GOLD_BRIGHT,
			Bold = true,
			XAlign = Enum.TextXAlignment.Center,
		})
	end

	local topOffset = ((snap.raid and snap.raid.active) or activeRaidWave > 0) and 104 or 84

	-- Left Column (52%): Difficulty Selector & Microchip Activation Console
	local leftPanel = PremiumPanel.Create(body, {
		name = "MicrochipControlPanel",
		variant = "gold",
		title = I18n.Pick("BẢNG ĐIỀU KHIỂN MICROCHIP RAID (5 WAVES)", "MICROCHIP RAID LAUNCH CONSOLE (5 WAVES)"),
		subtitle = I18n.Pick("Chọn độ khó Raid & phương thức kích hoạt Microchip", "Vote Raid difficulty & activate Microchip"),
		position = UDim2.fromOffset(0, topOffset),
		size = UDim2.new(0.52, -6, 1, -topOffset),
	})

	local diffHolder = UIFactory.Create("Frame", leftPanel, {
		Name = "DifficultyCards",
		Position = UDim2.fromOffset(14, 58),
		Size = UDim2.new(1, -28, 0, 168),
		BackgroundTransparency = 1,
	})
	UIFactory.ListLayout(diffHolder, Enum.FillDirection.Vertical, 6)

	for idx, dSpec in ipairs(RAID_DIFFICULTIES) do
		local isSel = (selectedDiff == dSpec.Id)
		local card = UIFactory.Create("TextButton", diffHolder, {
			Name = "Diff_" .. dSpec.Id,
			Size = UDim2.new(1, 0, 0, 52),
			BackgroundColor3 = isSel and Color3.fromRGB(18, 30, 56) or colors.BG_900,
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = true,
			LayoutOrder = idx,
		})
		UIFactory.Corner(card, Theme.Radius.Small)
		UIFactory.Stroke(card, isSel and dSpec.Color or colors.STROKE_STEEL, isSel and 1.8 or 1.1, 0.2)

		UIFactory.Label(card, {
			Name = "DiffName",
			Text = string.format("%s  •  %s", I18n.GetLanguage() == "en" and dSpec.LabelEn or dSpec.LabelVi, dSpec.Mult),
			Position = UDim2.fromOffset(12, 6),
			Size = UDim2.new(1, -124, 0, 18),
			TextSize = 12,
			TextColor = dSpec.Color,
			Bold = true,
			Truncate = Enum.TextTruncate.AtEnd,
		})
		UIFactory.Label(card, {
			Name = "DiffReward",
			Text = I18n.GetLanguage() == "en" and dSpec.RewardEn or dSpec.RewardVi,
			Position = UDim2.fromOffset(12, 26),
			Size = UDim2.new(1, -124, 0, 18),
			TextSize = 10,
			TextColor = colors.TEXT_PRIMARY,
			Truncate = Enum.TextTruncate.AtEnd,
		})
		UIFactory.Label(card, {
			Name = "VoteTag",
			Text = isSel and I18n.Pick("ĐANG CHỌN ✓", "SELECTED ✓") or I18n.Pick("CHỌN ĐỘ KHÓ", "VOTE"),
			Position = UDim2.new(1, -108, 0, 0),
			Size = UDim2.fromOffset(96, 52),
			TextSize = 10,
			TextColor = isSel and colors.SUCCESS or colors.TEXT_SECONDARY,
			Bold = true,
			XAlign = Enum.TextXAlignment.Right,
		})

		card.Activated:Connect(function()
			Store.Session.selectedRaidDifficulty = dSpec.Id
			fireRaidCommand("VoteRaidDifficulty", { difficulty = dSpec.Id })
			ScreenRouter.Navigate(UIState.Screens.Raid, { forceRebuild = true, replace = true })
		end)
	end

	-- Action Buttons at Bottom of Left Panel
	PremiumButton.Create(leftPanel, {
		name = "StartRaidGoldBtn",
		icon = "Gold",
		label = I18n.Pick(
			string.format("MUA & KÍCH HOẠT MICROCHIP — 100,000 GOLD [%s]", UIFactory.Upper(selectedDiff)),
			string.format("BUY & START MICROCHIP RAID — 100,000 GOLD [%s]", UIFactory.Upper(selectedDiff))
		),
		variant = (playerGold >= 100000) and "gold" or "primary",
		position = UDim2.new(0, 14, 1, -98),
		size = UDim2.new(1, -28, 0, 40),
		textSize = 11,
		minTextSize = 8,
		onActivated = function()
			Store.RecordBossCombat()
			fireRaidCommand("StartMicrochipRaid", { difficulty = selectedDiff, payment = "Gold" })
			ScreenRouter.Navigate(UIState.Screens.HUD)
		end,
	})

	PremiumButton.Create(leftPanel, {
		name = "StartRaidFruitBtn",
		icon = "Fruit",
		label = spareFruitId
			and I18n.Pick(
				string.format("ĐỔI TRÁI DƯ (%s x%d) KÍCH HOẠT RAID", spareFruitId, spareFruitQty),
				string.format("EXCHANGE SPARE CORE (%s x%d) & START RAID", spareFruitId, spareFruitQty)
			)
			or I18n.Pick("ĐỔI TRÁI DƯ KÍCH HOẠT MICROCHIP (CHƯA CÓ TRÁI DƯ)", "EXCHANGE SPARE CORE (NONE IN VAULT)"),
		variant = spareFruitId and "primary" or "secondary",
		position = UDim2.new(0, 14, 1, -50),
		size = UDim2.new(1, -28, 0, 38),
		textSize = 11,
		minTextSize = 8,
		onActivated = function()
			Store.RecordBossCombat()
			fireRaidCommand("StartMicrochipRaid", {
				difficulty = selectedDiff,
				payment = "Fruit",
				fruitId = spareFruitId,
			})
			if spareFruitId then
				ScreenRouter.Navigate(UIState.Screens.HUD)
			end
		end,
	})

	-- Right Column (48%): 5 Waves Breakdown & Awakening Guide
	local rightPanel = PremiumPanel.Create(body, {
		name = "RaidWavesPanel",
		title = I18n.Pick("LỘ TRÌNH 5 WAVES & THỨC TỈNH LÕI V2", "5-WAVE BREAKDOWN & V2 CORE AWAKENING"),
		subtitle = I18n.Pick("Vượt Wave 5 để mở khóa Thức Tỉnh Lõi V2 (+25% Sát Thương, +20% Tầm Đánh)", "Clear Wave 5 to unlock V2 Core Awakening (+25% DMG, +20% Range)"),
		position = UDim2.new(0.52, 6, 0, topOffset),
		size = UDim2.new(0.48, -6, 1, -topOffset),
	})

	local waveScroll = UIFactory.Create("ScrollingFrame", rightPanel, {
		Name = "WaveListScroll",
		Position = UDim2.fromOffset(14, 58),
		Size = UDim2.new(1, -28, 1, -114),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = colors.ACCENT_GOLD,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.fromOffset(0, 0),
	})
	UIFactory.ListLayout(waveScroll, Enum.FillDirection.Vertical, 6)

	for _, w in ipairs(MICROCHIP_WAVES) do
		local isBossWave = (w.Wave == 5)
		local wCard = UIFactory.Create("Frame", waveScroll, {
			Name = "Wave_" .. w.Wave,
			Size = UDim2.new(1, -6, 0, 52),
			BackgroundColor3 = isBossWave and Color3.fromRGB(24, 18, 42) or colors.BG_900,
			BorderSizePixel = 0,
			LayoutOrder = w.Wave,
		})
		UIFactory.Corner(wCard, Theme.Radius.Small)
		UIFactory.Stroke(wCard, isBossWave and colors.ACCENT_GOLD_BRIGHT or colors.STROKE_STEEL, isBossWave and 1.5 or 1.0, 0.25)

		UIFactory.Label(wCard, {
			Name = "WTitle",
			Text = w.TitleVi,
			Position = UDim2.fromOffset(10, 5),
			Size = UDim2.new(1, -20, 0, 18),
			TextSize = 11,
			TextColor = isBossWave and colors.ACCENT_GOLD_BRIGHT or colors.ACCENT_SAPPHIRE,
			Bold = true,
			Truncate = Enum.TextTruncate.AtEnd,
		})
		UIFactory.Label(wCard, {
			Name = "WDesc",
			Text = w.DescVi,
			Position = UDim2.fromOffset(10, 24),
			Size = UDim2.new(1, -20, 0, 24),
			TextSize = 10,
			TextColor = colors.TEXT_SECONDARY,
			Wrapped = true,
		})
	end

	PremiumButton.Create(rightPanel, {
		name = "OpenFruitsAwakenBtn",
		icon = "Bolt",
		label = v2Ready
			and I18n.Pick("MỞ KHO LÕI [G] ĐỂ THỨC TỈNH V2 NGAY!", "OPEN CORES [G] TO AWAKEN V2 NOW!")
			or I18n.Pick("XEM TRẠNG THÁI THỨC TỈNH V2 TẠI [G]", "VIEW V2 AWAKENING STATUS IN [G]"),
		variant = v2Ready and "gold" or "secondary",
		position = UDim2.new(0, 14, 1, -48),
		size = UDim2.new(1, -28, 0, 38),
		textSize = 11,
		minTextSize = 9,
		onActivated = function()
			ScreenRouter.Navigate("Fruits:Vault")
		end,
	})
end

local function buildSkySpireTab(body, snap)
	local colors = Theme.Colors
	local lp = Players.LocalPlayer
	local activeFloor = (lp and tonumber(lp:GetAttribute("SpireFloor"))) or 0
	local highestFloor = math.max(
		1,
		tonumber(snap.highestSpireFloor)
			or (lp and tonumber(lp:GetAttribute("SkySpireFloor")))
			or activeFloor
			or 1
	)

	local leftPanel = PremiumPanel.Create(body, {
		name = "SkySpireControlPanel",
		variant = "gold",
		title = I18n.Pick("THÁP BẦU TRỜI VÔ TẬN (ENDLESS SKY SPIRE — 50 TẦNG)", "ENDLESS SKY SPIRE — 50 FLOORS"),
		subtitle = I18n.Pick("Khiêu chiến liên hoàn 50 tầng • Tích lũy Core Shards & Danh Hiệu Đỉnh Cao", "50-Floor Gauntlet • Earn Core Shards & Exclusive Sovereign Titles"),
		position = UDim2.fromOffset(0, 0),
		size = UDim2.new(0.50, -6, 1, 0),
	})

	local recordBox = UIFactory.Create("Frame", leftPanel, {
		Name = "SpireRecordCard",
		Position = UDim2.fromOffset(14, 62),
		Size = UDim2.new(1, -28, 0, 108),
		BackgroundColor3 = Color3.fromRGB(11, 20, 38),
		BorderSizePixel = 0,
	})
	UIFactory.Corner(recordBox, Theme.Radius.Medium)
	UIFactory.Stroke(recordBox, colors.ACCENT_SAPPHIRE, 1.4, 0.2)

	UIFactory.Icon(recordBox, "Trophy", UDim2.fromOffset(14, 16), 30, colors.ACCENT_GOLD_BRIGHT)
	UIFactory.Label(recordBox, {
		Name = "RecordTitle",
		Text = string.format("KỶ LỤC TẦNG CAO NHẤT: TẦNG %d / 50", math.min(50, highestFloor)),
		Position = UDim2.fromOffset(54, 12),
		Size = UDim2.new(1, -66, 0, 22),
		TextSize = 14,
		TextColor = colors.ACCENT_GOLD_BRIGHT,
		Bold = true,
		Truncate = Enum.TextTruncate.AtEnd,
	})
	UIFactory.Label(recordBox, {
		Name = "ActiveFloorStatus",
		Text = (activeFloor > 0)
			and string.format("TRẠNG THÁI HIỆN TẠI: ĐANG CHIẾN ĐẤU TẠI TẦNG %d / 50", activeFloor)
			or "TRẠNG THÁI HIỆN TẠI: ĐANG Ở NGOÀI THÁP (SẴN SÀNG KHIÊU CHIẾN)",
		Position = UDim2.fromOffset(54, 38),
		Size = UDim2.new(1, -66, 0, 18),
		TextSize = 11,
		TextColor = (activeFloor > 0) and colors.SUCCESS or colors.ACCENT_SAPPHIRE,
		Bold = true,
		Truncate = Enum.TextTruncate.AtEnd,
	})
	UIFactory.Label(recordBox, {
		Name = "SpireRules",
		Text = "• Cứ mỗi 5 tầng xuất hiện Boss Tinh Anh trấn ải.\n• Hỗ trợ Solo hoặc Tổ Đội Co-op lên đến 6 người chơi.",
		Position = UDim2.fromOffset(16, 62),
		Size = UDim2.new(1, -32, 0, 38),
		TextSize = 10,
		TextColor = colors.TEXT_SECONDARY,
		Wrapped = true,
	})

	PremiumButton.Create(leftPanel, {
		name = "EnterSkySpireBtn",
		icon = "Trophy",
		label = I18n.Pick(
			string.format("VÀO THÁP BẦU TRỜI (BẮT ĐẦU / LEO TIẾP TẦNG %d)", math.min(50, highestFloor)),
			string.format("ENTER SKY SPIRE (FLOOR %d)", math.min(50, highestFloor))
		),
		variant = "gold",
		position = UDim2.new(0, 14, 1, -104),
		size = UDim2.new(1, -28, 0, 44),
		textSize = 12,
		minTextSize = 9,
		onActivated = function()
			fireRaidCommand("EnterSkySpire", { floor = highestFloor })
			ScreenRouter.Navigate(UIState.Screens.HUD)
		end,
	})

	PremiumButton.Create(leftPanel, {
		name = "LeaveSkySpireBtn",
		icon = "Close",
		label = I18n.Pick("RỜI KHỎI THÁP BẦU TRỜI (LEAVE SKY SPIRE)", "LEAVE SKY SPIRE"),
		variant = (activeFloor > 0) and "danger" or "secondary",
		position = UDim2.new(0, 14, 1, -52),
		size = UDim2.new(1, -28, 0, 40),
		textSize = 11,
		minTextSize = 9,
		onActivated = function()
			fireRaidCommand("LeaveSkySpire", {})
			Store.ShowToast(I18n.Pick("Đã gửi yêu cầu rời khỏi Tháp Bầu Trời.", "Requested to leave Sky Spire."), "info")
		end,
	})

	-- Right Column (50%): 50-Floor Milestones
	local rightPanel = PremiumPanel.Create(body, {
		name = "SpireMilestonesPanel",
		title = I18n.Pick("MỐC PHẦN THƯỞNG ĐỈNH THÁP (TẦNG 10 -> 50)", "SKY SPIRE FLOOR MILESTONES (10F -> 50F)"),
		subtitle = I18n.Pick("Chinh phục tầng càng cao, phần thưởng Gold & Core Shards càng lớn", "Higher floors grant massive Gold, Core Shards & Endgame Gear"),
		position = UDim2.new(0.50, 6, 0, 0),
		size = UDim2.new(0.50, -6, 1, 0),
	})

	local msScroll = UIFactory.Create("ScrollingFrame", rightPanel, {
		Name = "MilestonesScroll",
		Position = UDim2.fromOffset(14, 58),
		Size = UDim2.new(1, -28, 1, -72),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = colors.ACCENT_SAPPHIRE,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.fromOffset(0, 0),
	})
	UIFactory.ListLayout(msScroll, Enum.FillDirection.Vertical, 7)

	for idx, ms in ipairs(SPIRE_MILESTONES) do
		local cleared = highestFloor > ms.Floor or (highestFloor >= 50 and ms.Floor == 50)
		local mCard = UIFactory.Create("Frame", msScroll, {
			Name = "Milestone_" .. ms.Floor,
			Size = UDim2.new(1, -6, 0, 56),
			BackgroundColor3 = cleared and Color3.fromRGB(12, 34, 28) or colors.BG_900,
			BorderSizePixel = 0,
			LayoutOrder = idx,
		})
		UIFactory.Corner(mCard, Theme.Radius.Small)
		UIFactory.Stroke(mCard, cleared and colors.SUCCESS or ms.RarityCol, 1.3, 0.22)

		UIFactory.Label(mCard, {
			Name = "MTitle",
			Text = ms.Title .. (cleared and "  [ĐÃ ĐẠT ✓]" or ""),
			Position = UDim2.fromOffset(12, 7),
			Size = UDim2.new(1, -24, 0, 18),
			TextSize = 12,
			TextColor = cleared and colors.SUCCESS or ms.RarityCol,
			Bold = true,
			Truncate = Enum.TextTruncate.AtEnd,
		})
		UIFactory.Label(mCard, {
			Name = "MReward",
			Text = ms.Reward,
			Position = UDim2.fromOffset(12, 28),
			Size = UDim2.new(1, -24, 0, 20),
			TextSize = 11,
			TextColor = colors.TEXT_PRIMARY,
			Truncate = Enum.TextTruncate.AtEnd,
		})
	end
end

function Raid.Build(parent)
	Raid.Cleanup()
	local snap = Store.GetSnapshot()
	local activeTab = Store.Session.activeRaidConsoleTab or "MicrochipRaid"
	if activeTab ~= "MicrochipRaid" and activeTab ~= "SkySpire" then
		activeTab = "MicrochipRaid"
	end

	local root = UIFactory.Create("Frame", parent, {
		Name = "RaidScreen",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 2,
	})

	local _, headerRefs = UIFactory.BuildScreenHeader(root, {
		ActiveScreen = UIState.Screens.Raid,
		ContextualNPCStation = true,
		StationBadgeText = I18n.Pick("TRẠM KHIÊU CHIẾN • RAID & THÁP", "RAID LAB & SKY SPIRE"),
		Title = I18n.Pick("PHÒNG THÍ NGHIỆM MICROCHIP RAID & THÁP BẦU TRỜI 50F", "MICROCHIP AWAKENING RAID & 50F SKY SPIRE"),
		Snapshot = snap,
		OnNavigate = function(targetId)
			ScreenRouter.Navigate(targetId)
		end,
		OnClose = function()
			ScreenRouter.CloseAllToHUD()
		end,
	})

	-- 2-Tab Selector Row: Tab 1 (Microchip Raid — 5 Waves) vs Tab 2 (Sky Spire — 50 Tầng)
	local tabBar = UIFactory.Create("Frame", root, {
		Name = "RaidConsoleTabs",
		Position = UDim2.fromOffset(16, 72),
		Size = UDim2.new(1, -32, 0, 40),
		BackgroundTransparency = 1,
	})

	PremiumButton.Create(tabBar, {
		name = "Tab_MicrochipRaid",
		icon = "Raid",
		label = I18n.Pick("PHÒNG THÍ NGHIỆM ĐỘT KÍCH (MICROCHIP RAID — 5 WAVES)", "MICROCHIP AWAKENING RAID LAB (5 WAVES)"),
		variant = (activeTab == "MicrochipRaid") and "gold" or "secondary",
		selected = (activeTab == "MicrochipRaid"),
		position = UDim2.fromOffset(0, 0),
		size = UDim2.new(0.52, -5, 1, 0),
		textSize = 11,
		minTextSize = 9,
		onActivated = function()
			Store.Session.activeRaidConsoleTab = "MicrochipRaid"
			ScreenRouter.Navigate(UIState.Screens.Raid, { forceRebuild = true, replace = true })
		end,
	})

	PremiumButton.Create(tabBar, {
		name = "Tab_SkySpire",
		icon = "Trophy",
		label = I18n.Pick("THÁP BẦU TRỜI VÔ TẬN (SKY SPIRE — 50 TẦNG)", "ENDLESS SKY SPIRE (50 FLOORS)"),
		variant = (activeTab == "SkySpire") and "gold" or "secondary",
		selected = (activeTab == "SkySpire"),
		position = UDim2.new(0.52, 5, 0, 0),
		size = UDim2.new(0.48, -5, 1, 0),
		textSize = 11,
		minTextSize = 9,
		onActivated = function()
			Store.Session.activeRaidConsoleTab = "SkySpire"
			ScreenRouter.Navigate(UIState.Screens.Raid, { forceRebuild = true, replace = true })
		end,
	})

	local body = UIFactory.Create("Frame", root, {
		Name = "RaidConsoleBody",
		Position = UDim2.fromOffset(16, 120),
		Size = UDim2.new(1, -32, 1, -134),
		BackgroundTransparency = 1,
	})

	if activeTab == "SkySpire" then
		buildSkySpireTab(body, snap)
	else
		buildMicrochipRaidTab(body, snap)
	end

	Raid.LastSig = string.format("%s|%d|%d", activeTab, tonumber(snap.raidChipsCleared) or 0, tonumber(snap.highestSpireFloor) or 1)
	Raid.Refs = {
		Root = root,
		Body = body,
		HeaderRefs = headerRefs,
	}
	return root
end

function Raid.Update(snap)
	snap = snap or Store.GetSnapshot()
	if Raid.Refs.HeaderRefs and Raid.Refs.HeaderRefs.UpdateCurrencies then
		Raid.Refs.HeaderRefs.UpdateCurrencies(snap)
	end
	if not Raid.Refs.Body or not Raid.Refs.Body.Parent then
		return
	end
	local activeTab = Store.Session.activeRaidConsoleTab or "MicrochipRaid"
	local sig = string.format("%s|%d|%d", activeTab, tonumber(snap.raidChipsCleared) or 0, tonumber(snap.highestSpireFloor) or 1)
	if sig ~= Raid.LastSig then
		Raid.LastSig = sig
		for _, ch in ipairs(Raid.Refs.Body:GetChildren()) do
			ch:Destroy()
		end
		if activeTab == "SkySpire" then
			buildSkySpireTab(Raid.Refs.Body, snap)
		else
			buildMicrochipRaidTab(Raid.Refs.Body, snap)
		end
	end
end

function Raid.Cleanup()
	Raid.LastSig = nil
	Raid.Refs = {}
end

return Raid
