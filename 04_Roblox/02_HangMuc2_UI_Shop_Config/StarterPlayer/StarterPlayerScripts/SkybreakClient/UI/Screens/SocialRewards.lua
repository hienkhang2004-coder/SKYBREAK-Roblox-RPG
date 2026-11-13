-- SKYBREAK: Fragments of the Core — Co-op Party, Live Sky Crew, 7-Day Login, Playtime Gifts, Daily Missions, Giftcodes, Cross-Server Leaderboards & Badges ([B])
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/SocialRewards.lua

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local SkyShared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(SkyShared:WaitForChild("Config"):WaitForChild("Theme"))
local UIState = require(SkyShared:WaitForChild("Types"):WaitForChild("UIState"))

local BadgeConfig = nil
pcall(function()
	local mod = SkyShared:FindFirstChild("BadgeConfig")
	if mod and mod:IsA("ModuleScript") then
		BadgeConfig = require(mod)
	end
end)

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Store = require(script.Parent.Parent:WaitForChild("Store"))
local ScreenRouter = require(script.Parent.Parent:WaitForChild("ScreenRouter"))
local I18n = require(script.Parent.Parent:WaitForChild("I18n"))
local Responsive = require(script.Parent.Parent:WaitForChild("Responsive"))
local PremiumPanel = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumPanel"))
local PremiumButton = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumButton"))
local ViewportOrbit = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("ViewportOrbit"))
local PartyController = require(script.Parent.Parent:WaitForChild("Controllers"):WaitForChild("PartyController"))
local InventoryController = require(script.Parent.Parent:WaitForChild("Controllers"):WaitForChild("InventoryController"))

local CLIENT_JOIN_CLOCK = os.clock()

local SocialRewards = {
	Refs = {},
	BustConnections = {},
	InspectOverlay = nil,
	InspectOrbit = nil,
	LastSig = nil,
	LastSeenStreak = nil,
	ActiveLbCategory = "Level",
	LastLbFetchClock = {},
	PlaytimeTickerToken = 0,
	PlaytimeTileRefs = {},
}

local RARITY_PALETTE = {
	Common = {
		Top = Color3.fromRGB(100, 116, 139),
		Bottom = Color3.fromRGB(30, 41, 59),
		Stroke = Color3.fromRGB(148, 163, 184),
		Text = Color3.fromRGB(203, 213, 225),
	},
	Uncommon = {
		Top = Color3.fromRGB(52, 211, 153),
		Bottom = Color3.fromRGB(6, 95, 70),
		Stroke = Color3.fromRGB(110, 231, 183),
		Text = Color3.fromRGB(167, 243, 208),
	},
	Rare = {
		Top = Color3.fromRGB(56, 189, 248),
		Bottom = Color3.fromRGB(29, 78, 216),
		Stroke = Color3.fromRGB(147, 224, 255),
		Text = Color3.fromRGB(125, 211, 252),
	},
	Epic = {
		Top = Color3.fromRGB(192, 132, 252),
		Bottom = Color3.fromRGB(91, 33, 182),
		Stroke = Color3.fromRGB(228, 184, 255),
		Text = Color3.fromRGB(216, 180, 254),
	},
	Legendary = {
		Top = Color3.fromRGB(252, 211, 77),
		Bottom = Color3.fromRGB(180, 83, 9),
		Stroke = Color3.fromRGB(255, 242, 166),
		Text = Color3.fromRGB(253, 224, 71),
	},
	Mythic = {
		Top = Color3.fromRGB(251, 113, 133),
		Bottom = Color3.fromRGB(147, 51, 234),
		Stroke = Color3.fromRGB(255, 182, 212),
		Text = Color3.fromRGB(255, 148, 182),
	},
}

local DAILY_7_REWARDS = {
	{ Day = 1, Rarity = "Rare", TitleVi = "+25K Vàng", TitleEn = "+25K Gold", Icon = "Gold" },
	{ Day = 2, Rarity = "Rare", TitleVi = "+150 Shards", TitleEn = "+150 Shards", Icon = "CoreShards" },
	{ Day = 3, Rarity = "Epic", TitleVi = "Vé Lõi x1", TitleEn = "Core Ticket", Icon = "Fruit" },
	{ Day = 4, Rarity = "Epic", TitleVi = "x2 EXP (30p)", TitleEn = "2x EXP (30m)", Icon = "Bolt" },
	{ Day = 5, Rarity = "Legendary", TitleVi = "Cổ Ngữ +100S", TitleEn = "Rune +100S", Icon = "Quest" },
	{ Day = 6, Rarity = "Legendary", TitleVi = "+500 Shards", TitleEn = "+500 Shards", Icon = "CoreShards" },
	{ Day = 7, Rarity = "Mythic", TitleVi = "Hộp Lõi VIP", TitleEn = "VIP Core Box", Icon = "Crown" },
}

local PLAYTIME_6_TIERS = {
	{ Index = 1, Minutes = 5, RequiredSec = 300, Rarity = "Rare", Icon = "Gold", TitleVi = "5 Phút", TitleEn = "5 Min", RewardVi = "+15K Vàng", RewardEn = "+15K Gold" },
	{ Index = 2, Minutes = 10, RequiredSec = 600, Rarity = "Rare", Icon = "CoreShards", TitleVi = "10 Phút", TitleEn = "10 Min", RewardVi = "+75 Shards", RewardEn = "+75 Shards" },
	{ Index = 3, Minutes = 20, RequiredSec = 1200, Rarity = "Epic", Icon = "Bolt", TitleVi = "20 Phút", TitleEn = "20 Min", RewardVi = "15p x2 EXP", RewardEn = "15m 2x EXP" },
	{ Index = 4, Minutes = 30, RequiredSec = 1800, Rarity = "Epic", Icon = "Quest", TitleVi = "30 Phút", TitleEn = "30 Min", RewardVi = "Cổ Ngữ +100S", RewardEn = "Rune +100S" },
	{ Index = 5, Minutes = 45, RequiredSec = 2700, Rarity = "Legendary", Icon = "Fruit", TitleVi = "45 Phút", TitleEn = "45 Min", RewardVi = "Vé Lõi x1", RewardEn = "Core Ticket" },
	{ Index = 6, Minutes = 60, RequiredSec = 3600, Rarity = "Mythic", Icon = "Crown", TitleVi = "60 Phút", TitleEn = "60 Min", RewardVi = "Lõi Hiếm+ 200S", RewardEn = "Rare+ Core" },
}

local FALLBACK_DAILY_MISSIONS = {
	{
		Id = "bounty_mobs",
		Title = "Tiêu diệt 25 Quái Thiên Giới",
		TitleEn = "Defeat 25 Skyrealm Enemies",
		Progress = 0,
		Count = 25,
		Gold = 35000,
		Shards = 40,
		Claimed = false,
	},
	{
		Id = "bounty_boss",
		Title = "Đánh bại 2 Boss Đảo / Đột Kích",
		TitleEn = "Defeat 2 Island / Raid Bosses",
		Progress = 0,
		Count = 2,
		Gold = 65000,
		Shards = 85,
		Claimed = false,
	},
	{
		Id = "bounty_quests",
		Title = "Hoàn thành 3 Nhiệm Vụ Đảo",
		TitleEn = "Complete 3 Island Quests",
		Progress = 0,
		Count = 3,
		Gold = 50000,
		Shards = 60,
		Claimed = false,
	},
}

local FALLBACK_BADGES = {
	{ Id = "welcome_skyborn", Rarity = "Rare", Icon = "Sword", TitleVi = "Tân Chiến Binh Bầu Trời", TitleEn = "Skyborn Initiate", DescVi = "Hoàn thành huấn luyện khởi đầu Q01 tại Sky Hub.", DescEn = "Arrive at Sky Hub and complete starter quest Q01." },
	{ Id = "first_aether_core", Rarity = "Epic", Icon = "Fruit", TitleVi = "Khế Ước Lõi Aether", TitleEn = "First Aether Core", DescVi = "Quay hoặc hấp thụ Lõi Aether đầu tiên tại Zioles.", DescEn = "Roll or attune your first Aether Core at Oracle Zioles." },
	{ Id = "aureon_slayer", Rarity = "Epic", Icon = "Shield", TitleVi = "Kẻ Phá Vỡ Hào Quang", TitleEn = "Warden of Dawnbreaker", DescVi = "Đánh bại Boss Aureon Sentinel tại Tầng Trời 1.", DescEn = "Vanquish Aureon Sentinel in the Sun Citadel Arena." },
	{ Id = "sea2_cyberport", Rarity = "Legendary", Icon = "Compass", TitleVi = "Lữ Khách Băng Thành", TitleEn = "Frozen Cyber Voyager", DescVi = "Đạt Cấp 700 và mở khóa Tầng Trời 2 • Frozen Cyber.", DescEn = "Reach Level 700 and unlock Sky 2 • Frozen Cyber." },
	{ Id = "cryon_slayer", Rarity = "Legendary", Icon = "Frost", TitleVi = "Chinh Phục Tuyệt Độ", TitleEn = "Sub-Zero Conqueror", DescVi = "Đánh bại Băng Đế Cryon Prime mở cổng Tầng Trời 3.", DescEn = "Defeat Cryon Prime and unseal Sky 3 • Shadow Realm." },
	{ Id = "awakened_core_v2", Rarity = "Legendary", Icon = "Bolt", TitleVi = "Thức Tỉnh Lõi Cực Hạn", TitleEn = "Awakened Core Sovereign", DescVi = "Vượt Đột Kích Giải Mã và Thức Tỉnh V2 một Lõi Aether.", DescEn = "Clear a Microchip Raid and awaken any Aether Core to V2." },
	{ Id = "leviathan_slayer", Rarity = "Mythic", Icon = "Crown", TitleVi = "Thợ Săn Thủy Xà Vực Thẳm", TitleEn = "Abyssal Leviathan Slayer", DescVi = "Hạ gục Đại Thủy Xà Vực Thẳm và kéo Trái Tim về cảng.", DescEn = "Slay the Abyssal Leviathan and tow its Heart to port." },
	{ Id = "apex_architect_2550", Rarity = "Mythic", Icon = "Core", TitleVi = "Đỉnh Cao Thiên Giới Lv.2550", TitleEn = "Apex Skyborn (Lv. 2550)", DescVi = "Đạt Cấp Tối Đa 2550 hoặc khuất phục Đấng Kiến Tạo Veyr.", DescEn = "Reach Max Level 2550 or defeat Veyr at Veil's End." },
}

local DAILY_MISSION_EN_BY_ID = {
	bounty_mobs = "Defeat %d Skyrealm Enemies",
	bounty_boss = "Defeat %d Island / Raid Bosses",
	bounty_quests = "Complete %d Island Quests",
	daily_mobs = "Defeat %d Skyrealm Enemies",
	daily_boss = "Defeat %d Island / Raid Bosses",
	daily_quests = "Complete %d Island Quests",
}

local function fireServerUI(cmd, payload)
	payload = type(payload) == "table" and payload or {}
	local skyRems = SkyShared:FindFirstChild("Remotes")
	local sharedReq = skyRems and (skyRems:FindFirstChild("UIRequest") or skyRems:FindFirstChild("UICommand"))
	if sharedReq and sharedReq:IsA("RemoteEvent") then
		sharedReq:FireServer(cmd, payload)
		return
	end
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	local uiReq = remotes and (remotes:FindFirstChild("UIRequest") or remotes:FindFirstChild("UICommand"))
	if uiReq and uiReq:IsA("RemoteEvent") then
		uiReq:FireServer(cmd, payload)
		return
	end
	local reqAct = skyRems and skyRems:FindFirstChild("RequestUIAction")
	if reqAct and reqAct:IsA("RemoteEvent") then
		reqAct:FireServer(cmd, payload)
	end
end

local function isPortraitCompact()
	local cam = Workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	return vp.Y > vp.X and vp.X < 680
end

local function getScaledCanvasSize()
	local cam = Workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local st = Responsive.GetState()
	local scale = math.max(0.5, tonumber(st and st.UIScale) or 1)
	return math.floor(vp.X / scale), math.floor(vp.Y / scale)
end

local function formatMmSs(sec)
	sec = math.max(0, math.floor(tonumber(sec) or 0))
	local m = math.floor(sec / 60)
	local s = sec % 60
	return string.format("%02d:%02d", m, s)
end

local function getLivePlaytimeElapsed(snap)
	local pt = type(snap and snap.PlaytimeGifts) == "table" and snap.PlaytimeGifts or nil
	if pt and (pt.ElapsedSec ~= nil or pt.SyncUnix ~= nil) then
		local base = math.max(0, tonumber(pt.ElapsedSec) or 0)
		local syncUnix = tonumber(pt.SyncUnix)
		if syncUnix and syncUnix > 0 then
			return base + math.max(0, os.time() - syncUnix)
		end
		return base
	end
	return math.max(0, math.floor(os.clock() - CLIENT_JOIN_CLOCK))
end

local function isPlaytimeTierClaimed(snap, idx)
	local pt = type(snap and snap.PlaytimeGifts) == "table" and snap.PlaytimeGifts or nil
	local claimed = pt and type(pt.Claimed) == "table" and pt.Claimed or nil
	if claimed and (claimed[idx] == true or claimed[tostring(idx)] == true) then
		return true
	end
	local opt = Store.Session and Store.Session.claimedPlaytimeTiers
	return type(opt) == "table" and opt[idx] == true
end

local function requestLeaderboardRefresh(category, forceNow)
	local cat = tostring(category or "Level")
	local now = os.clock()
	local last = tonumber(SocialRewards.LastLbFetchClock[cat]) or 0
	if not forceNow and last > 0 and (now - last) < 15 then
		return
	end
	SocialRewards.LastLbFetchClock[cat] = now
	fireServerUI("RequestGlobalLeaderboard", { category = cat })
end

local function localizeDailyMissionTitle(b)
	if I18n.GetLanguage() ~= "en" then
		return tostring(b.Title or b.TitleVi or b.Id or "Nhiệm Vụ Ngày")
	end
	if type(b.TitleEn) == "string" and b.TitleEn ~= "" then
		return b.TitleEn
	end
	local goal = math.max(1, tonumber(b.Count) or 1)
	local idKey = tostring(b.Id or "")
	if DAILY_MISSION_EN_BY_ID[idKey] then
		return string.format(DAILY_MISSION_EN_BY_ID[idKey], goal)
	end
	local raw = tostring(b.Title or idKey)
	local lower = string.lower(raw)
	if string.find(lower, "quái", 1, true) or string.find(lower, "mobs", 1, true) then
		return string.format("Defeat %d Skyrealm Enemies", goal)
	elseif string.find(lower, "boss", 1, true) then
		return string.format("Defeat %d Island / Raid Bosses", goal)
	elseif string.find(lower, "nhiệm vụ", 1, true) or string.find(lower, "quest", 1, true) then
		return string.format("Complete %d Island Quests", goal)
	end
	return raw
end

local function closeInspectOverlay()
	if SocialRewards.InspectOrbit then
		SocialRewards.InspectOrbit:Destroy()
		SocialRewards.InspectOrbit = nil
	end
	if SocialRewards.InspectOverlay and SocialRewards.InspectOverlay.Parent then
		SocialRewards.InspectOverlay:Destroy()
	end
	SocialRewards.InspectOverlay = nil
end

local function inspectTargetPlayer(plr, rootForModal)
	if not plr then
		return
	end
	local snap = Store.GetSnapshot()
	local isSelf = (plr == Players.LocalPlayer)
	local lv = plr:GetAttribute("Level")
		or (plr:FindFirstChild("leaderstats") and plr.leaderstats:FindFirstChild("Level") and plr.leaderstats.Level.Value)
		or (isSelf and snap.player and snap.player.level)
		or 1
	local cls = plr:GetAttribute("ClassId") or (isSelf and snap.player and snap.player.classId) or "SkyGuardian"
	local wep = plr:GetAttribute("EquippedSword") or plr:GetAttribute("EquippedWeapon") or "Dawnbringer"
	local fruit = plr:GetAttribute("EquippedFruit") or (isSelf and snap.fruits and snap.fruits.equippedFruit) or "GaleCore"
	local helm = plr:GetAttribute("EquippedHelm") or "Skyguard Helm"
	local chest = plr:GetAttribute("EquippedChest") or "Aether Plate"
	local fac = plr:GetAttribute("Faction") or (isSelf and snap.fruits and snap.fruits.faction) or "Pirate"
	local renown = tonumber(plr:GetAttribute("Bounty")) or (isSelf and snap.fruits and tonumber(snap.fruits.bounty)) or 0

	local msg = I18n.Pick(
		string.format(
			"[SOI TRANG BỊ 3D] %s • Lv.%s • %s (%s) • Vũ khí: %s • Lõi Aether: %s",
			tostring(plr.DisplayName or plr.Name),
			tostring(lv),
			tostring(cls),
			tostring(fac),
			tostring(wep ~= "" and wep or "Dawnbringer"),
			tostring(fruit)
		),
		string.format(
			"[3D INSPECT] %s • Lv.%s • %s (%s) • Weapon: %s • Aether Core: %s",
			tostring(plr.DisplayName or plr.Name),
			tostring(lv),
			tostring(cls),
			tostring(fac),
			tostring(wep ~= "" and wep or "Dawnbringer"),
			tostring(fruit)
		)
	)
	Store.ShowToast(msg, "info", 3.2)

	if not rootForModal or not rootForModal.Parent then
		return
	end

	closeInspectOverlay()
	local colors = Theme.Colors
	local canvasW, canvasH = getScaledCanvasSize()
	local modalW = math.clamp(canvasW - 24, 340, 560)
	local modalH = math.clamp(canvasH - 28, 320, 360)
	local vpW = modalW < 500 and 160 or 216
	local bodyH = modalH - 66

	local backdrop = UIFactory.Create("TextButton", rootForModal, {
		Name = "Inspect3DModal",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(4, 8, 16),
		BackgroundTransparency = 0.25,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		ZIndex = 50,
	})
	SocialRewards.InspectOverlay = backdrop

	local modal = PremiumPanel.Create(backdrop, {
		name = "Inspect3DCard",
		variant = "gold",
		anchorPoint = Vector2.new(0.5, 0.5),
		position = UDim2.fromScale(0.5, 0.5),
		size = UDim2.fromOffset(modalW, modalH),
		zIndex = 52,
	})

	UIFactory.Label(modal, {
		Name = "ModalTitle",
		Text = I18n.Pick(
			"SOI TRANG BỊ 3D TRỰC TIẾP • " .. UIFactory.Upper(tostring(plr.DisplayName or plr.Name)),
			"LIVE 3D LOADOUT INSPECTOR • " .. UIFactory.Upper(tostring(plr.DisplayName or plr.Name))
		),
		Position = UDim2.fromOffset(18, 12),
		Size = UDim2.new(1, -120, 0, 24),
		TextSize = 13,
		TextColor = colors.ACCENT_GOLD_BRIGHT,
		Bold = true,
		Truncate = Enum.TextTruncate.AtEnd,
		ZIndex = 54,
	})

	PremiumButton.Create(modal, {
		name = "CloseInspectBtn",
		label = I18n.Pick("ĐÓNG [X]", "CLOSE [X]"),
		variant = "danger",
		position = UDim2.new(1, -104, 0, 10),
		size = UDim2.fromOffset(88, 28),
		textSize = 10,
		zIndex = 54,
		onActivated = function()
			closeInspectOverlay()
		end,
	})

	local vp = UIFactory.Create("ViewportFrame", modal, {
		Name = "Player3DViewport",
		Position = UDim2.fromOffset(16, 46),
		Size = UDim2.fromOffset(vpW, bodyH),
		BackgroundColor3 = Color3.fromRGB(10, 15, 28),
		BorderSizePixel = 0,
		Ambient = Color3.fromRGB(210, 220, 240),
		LightColor = Color3.fromRGB(255, 246, 224),
		LightDirection = Vector3.new(-0.5, -0.7, -1),
		ZIndex = 54,
	})
	UIFactory.Corner(vp, Theme.Radius.Medium)
	UIFactory.Stroke(vp, colors.ACCENT_SAPPHIRE, 1.5, 0.18)

	local orbit = ViewportOrbit.Attach(vp, {
		AutoSpinSpeed = 0.55,
		InitialYaw = math.rad(165),
		InitialPitch = math.rad(8),
		ShowHint = false,
		FieldOfView = 34,
	})
	SocialRewards.InspectOrbit = orbit

	task.spawn(function()
		local clonedModel = nil
		if plr.Character then
			pcall(function()
				plr.Character.Archivable = true
				clonedModel = plr.Character:Clone()
			end)
		end
		if not clonedModel and InventoryController and type(InventoryController.CloneCharacterForViewport) == "function" then
			local okM, fallbackMdl = pcall(InventoryController.CloneCharacterForViewport)
			if okM then
				clonedModel = fallbackMdl
			end
		end
		if SocialRewards.InspectOrbit ~= orbit then
			if clonedModel then
				clonedModel:Destroy()
			end
			return
		end
		if clonedModel then
			for _, d in ipairs(clonedModel:GetDescendants()) do
				if d:IsA("LuaSourceContainer") then
					d:Destroy()
				elseif d:IsA("BasePart") then
					d.Anchored = true
					d.CanCollide = false
				end
			end
			orbit:SetModel(clonedModel, { FitMultiplier = 1.15, InitialYaw = math.rad(165), ResetAngles = true })
		end
	end)

	local infoX = vpW + 28
	local infoFrame = UIFactory.Create("Frame", modal, {
		Name = "LoadoutDetails",
		Position = UDim2.fromOffset(infoX, 46),
		Size = UDim2.new(1, -(infoX + 16), 0, bodyH),
		BackgroundColor3 = Color3.fromRGB(10, 15, 28),
		BorderSizePixel = 0,
		ZIndex = 54,
	})
	UIFactory.Corner(infoFrame, Theme.Radius.Medium)
	UIFactory.Stroke(infoFrame, colors.ACCENT_GOLD, 1.2, 0.3)

	local rows = {
		{ k = I18n.Pick("CẤP ĐỘ & PHE PHÁI", "LEVEL & FACTION"), v = string.format("Lv.%s  •  %s", tostring(lv), tostring(fac)), col = colors.ACCENT_GOLD_BRIGHT },
		{ k = I18n.Pick("HỆ PHÁI CHIẾN ĐẤU", "HERO CLASS"), v = tostring(cls), col = colors.ACCENT_SAPPHIRE },
		{ k = I18n.Pick("ĐIỂM DANH VỌNG", "SKYBORN RENOWN"), v = UIFactory.FormatNumber(renown) .. " RNW", col = colors.SUCCESS },
		{ k = I18n.Pick("LÕI AETHER 3D", "3D AETHER CORE"), v = (type(I18n.FruitName) == "function" and I18n.FruitName(tostring(fruit))) or I18n.GetItemDisplayName(tostring(fruit), tostring(fruit)), col = Color3.fromRGB(232, 121, 249) },
		{ k = I18n.Pick("THẦN KIẾM / PHÁP KHÍ", "EQUIPPED WEAPON"), v = tostring(wep ~= "" and wep or "Dawnbringer"), col = colors.TEXT_PRIMARY },
		{ k = I18n.Pick("BỘ THẦN GIÁP 3D", "3D ARMOR SET"), v = tostring(chest) .. " + " .. tostring(helm), col = colors.ACCENT_ICE or colors.TEXT_SECONDARY },
	}
	local rowStep = math.max(34, math.floor((bodyH - 54) / #rows))
	for rIdx, rInfo in ipairs(rows) do
		local y = 8 + (rIdx - 1) * rowStep
		UIFactory.Label(infoFrame, {
			Name = "Key_" .. rIdx,
			Text = rInfo.k,
			Position = UDim2.fromOffset(12, y),
			Size = UDim2.new(1, -24, 0, 14),
			TextSize = 9,
			TextColor = colors.TEXT_SECONDARY,
			Bold = true,
			ZIndex = 55,
		})
		UIFactory.Label(infoFrame, {
			Name = "Val_" .. rIdx,
			Text = rInfo.v,
			Position = UDim2.fromOffset(12, y + 14),
			Size = UDim2.new(1, -24, 0, 18),
			TextSize = 11,
			TextColor = rInfo.col,
			Bold = true,
			Truncate = Enum.TextTruncate.AtEnd,
			ZIndex = 55,
		})
	end

	PremiumButton.Create(infoFrame, {
		name = "ModalInviteBtn",
		icon = "Users",
		label = isSelf and I18n.Pick("ĐÂY LÀ NHÂN VẬT CỦA BẠN", "YOUR ACTIVE HERO") or I18n.Pick("+ MỜI VÀO TỔ ĐỘI CO-OP", "+ INVITE TO CO-OP SQUAD"),
		variant = isSelf and "secondary" or "gold",
		disabled = isSelf,
		position = UDim2.new(0, 10, 1, -40),
		size = UDim2.new(1, -20, 0, 32),
		textSize = 10,
		minTextSize = 8,
		zIndex = 56,
		onActivated = function()
			PartyController.InvitePlayer(plr)
			closeInspectOverlay()
		end,
	})
end

local function makeGlossyDayCard(parent, dDef, isToday, claimed)
	local colors = Theme.Colors
	local pal = RARITY_PALETTE[dDef.Rarity] or RARITY_PALETTE.Rare

	local tile = UIFactory.Create("TextButton", parent, {
		Name = "DayCard_" .. dDef.Day,
		Size = UDim2.new(1 / 7, -5, 1, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = true,
		LayoutOrder = dDef.Day,
		ClipsDescendants = true,
	})
	UIFactory.Corner(tile, Theme.Radius.Medium)

	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, pal.Top),
		ColorSequenceKeypoint.new(1, pal.Bottom),
	})
	grad.Rotation = 90
	grad.Parent = tile

	UIFactory.Stroke(
		tile,
		isToday and colors.ACCENT_GOLD_BRIGHT or (claimed and colors.SUCCESS or pal.Stroke),
		isToday and 2.3 or 1.4,
		0.06
	)

	local sheen = UIFactory.Create("Frame", tile, {
		Name = "SpecularSheen",
		Size = UDim2.new(1, 0, 0.42, 0),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BackgroundTransparency = 0.83,
		BorderSizePixel = 0,
	})
	UIFactory.Corner(sheen, Theme.Radius.Medium)

	local topPill = UIFactory.Create("Frame", tile, {
		Name = "DayHeaderPill",
		Position = UDim2.fromOffset(4, 4),
		Size = UDim2.new(1, -8, 0, 16),
		BackgroundColor3 = Color3.fromRGB(8, 12, 22),
		BackgroundTransparency = 0.18,
		BorderSizePixel = 0,
	})
	UIFactory.PillCorner(topPill)
	UIFactory.Label(topPill, {
		Name = "DayText",
		Text = claimed
			and I18n.Pick("NGÀY " .. dDef.Day .. " ✓", "DAY " .. dDef.Day .. " ✓")
			or I18n.Pick("NGÀY " .. dDef.Day, "DAY " .. dDef.Day),
		Position = UDim2.fromOffset(3, 0),
		Size = UDim2.new(1, -6, 1, 0),
		TextSize = 8,
		TextColor = claimed and colors.SUCCESS or (isToday and colors.ACCENT_GOLD_BRIGHT or Color3.fromRGB(248, 250, 255)),
		Bold = true,
		XAlign = Enum.TextXAlignment.Center,
		Truncate = Enum.TextTruncate.AtEnd,
	})

	UIFactory.Icon(tile, dDef.Icon, UDim2.new(0.5, -11, 0.46, -11), 22, Color3.fromRGB(255, 255, 255))

	local bottomBar = UIFactory.Create("Frame", tile, {
		Name = "BottomRewardBar",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 22),
		BackgroundColor3 = Color3.fromRGB(9, 13, 24),
		BackgroundTransparency = 0.05,
		BorderSizePixel = 0,
	})
	local rLbl = UIFactory.Label(bottomBar, {
		Name = "RewardCaption",
		Text = I18n.GetLanguage() == "en" and dDef.TitleEn or dDef.TitleVi,
		Position = UDim2.fromOffset(3, 1),
		Size = UDim2.new(1, -6, 1, -2),
		TextSize = 8,
		TextColor = isToday and colors.ACCENT_GOLD_BRIGHT or pal.Text,
		Bold = true,
		XAlign = Enum.TextXAlignment.Center,
		Wrapped = true,
	})
	rLbl.TextScaled = true
	UIFactory.TextSizeConstraint(rLbl, 7, 9)

	return tile
end

local function refreshPlaytimeTileVisuals(snap)
	snap = snap or Store.GetSnapshot()
	local colors = Theme.Colors
	local elapsed = getLivePlaytimeElapsed(snap)
	if SocialRewards.Refs and SocialRewards.Refs.PlaytimeHeaderSub and SocialRewards.Refs.PlaytimeHeaderSub.Parent then
		SocialRewards.Refs.PlaytimeHeaderSub.Text = I18n.Pick(
			"Đã online: " .. formatMmSs(elapsed),
			"Session: " .. formatMmSs(elapsed)
		)
	end
	for _, item in ipairs(SocialRewards.PlaytimeTileRefs or {}) do
		if item.Tile and item.Tile.Parent and item.StatusLabel and item.StatusLabel.Parent then
			local tDef = item.Def
			local claimed = isPlaytimeTierClaimed(snap, tDef.Index)
			local rem = math.max(0, tDef.RequiredSec - elapsed)
			local ready = (rem <= 0) and (not claimed)
			if claimed then
				item.StatusLabel.Text = I18n.Pick("ĐÃ NHẬN ✓", "CLAIMED ✓")
				item.StatusLabel.TextColor3 = colors.SUCCESS
				if item.Stroke then
					item.Stroke.Color = colors.SUCCESS
					item.Stroke.Thickness = 1.4
				end
			elseif ready then
				item.StatusLabel.Text = I18n.Pick("NHẬN QUÀ!", "CLAIM!")
				item.StatusLabel.TextColor3 = colors.ACCENT_GOLD_BRIGHT
				if item.Stroke then
					item.Stroke.Color = colors.ACCENT_GOLD_BRIGHT
					item.Stroke.Thickness = 2.1
				end
			else
				item.StatusLabel.Text = formatMmSs(rem)
				item.StatusLabel.TextColor3 = colors.TEXT_SECONDARY
				if item.Stroke then
					item.Stroke.Color = item.DefaultStrokeColor
					item.Stroke.Thickness = 1.2
				end
			end
		end
	end
end

local function computeSocialSignature(snap)
	local pt = type(snap.PlaytimeGifts) == "table" and snap.PlaytimeGifts or nil
	local ok, sig = pcall(function()
		return HttpService:JSONEncode({
			lang = I18n.GetLanguage(),
			portrait = isPortraitCompact(),
			lbCat = SocialRewards.ActiveLbCategory,
			crew = snap.crewData,
			party = snap.party,
			login = snap.dailyLogin,
			bounties = snap.dailyBounties,
			ptClaimed = pt and pt.Claimed or nil,
			friendBoost = snap.FriendBoostPct,
			badges = snap.UnlockedBadges,
			glb = snap.GlobalLeaderboards,
			lv = snap.player and snap.player.level or 1,
			rnw = snap.fruits and snap.fruits.bounty or 0,
		})
	end)
	return ok and sig or nil
end

local function renderColumns(body, snap, rootForModal)
	for _, ch in ipairs(body:GetChildren()) do
		ch:Destroy()
	end
	SocialRewards.PlaytimeTileRefs = {}

	local colors = Theme.Colors
	local lp = Players.LocalPlayer
	local portrait = isPortraitCompact()
	local playerLv = tonumber(snap.player and snap.player.level) or 1
	local playerRenown = tonumber(snap.fruits and snap.fruits.bounty) or 0
	local crew = snap.crewData or {}
	local inCrew = crew.InCrew == true and tostring(crew.Name or "") ~= ""
	local pendingCrewInvite = tostring(crew.PendingInvite or "")
	local party = snap.party or {}
	local partyMembers = type(party.members) == "table" and party.members or {}
	local inActiveParty = (#partyMembers > 1) or (tostring(party.partyId or "") ~= "")
	local pendingPartyFrom = tostring(party.pendingInviteFrom or "")
	local friendBoostPct = math.clamp(
		tonumber(snap.FriendBoostPct) or (lp and tonumber(lp:GetAttribute("FriendBoostPct"))) or 0,
		0,
		15
	)

	Store.Session.draftCrewName = Store.Session.draftCrewName or ""
	Store.Session.draftCrewTag = Store.Session.draftCrewTag or ""
	Store.Session.claimedLoginDays = Store.Session.claimedLoginDays or {}
	Store.Session.claimedPlaytimeTiers = Store.Session.claimedPlaytimeTiers or {}

	-- ========================================================================
	-- LEFT COLUMN: FRIEND EXP BOOST, LIVE CREW ROSTER (30 CAP) & CO-OP PARTY
	-- ========================================================================
	local leftPanel = PremiumPanel.Create(body, {
		name = "PartyAndCompanionsPanel",
		variant = "gold",
		position = UDim2.fromOffset(0, 0),
		size = portrait and UDim2.new(1, 0, 0.46, -4) or UDim2.new(0.47, -6, 1, 0),
	})

	UIFactory.Label(leftPanel, {
		Name = "LeftHeaderTitle",
		Text = I18n.Pick("HẠM ĐỘI (CREW) • TỔ ĐỘI CO-OP & BẠN BÈ", "SKY CREW • CO-OP PARTY & FRIENDS"),
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -204, 0, 22),
		TextSize = 11,
		TextColor = colors.ACCENT_GOLD_BRIGHT,
		Bold = true,
		Truncate = Enum.TextTruncate.AtEnd,
	})

	local partySize = party.partySize or (inActiveParty and "Squad" or "Solo")
	local modeStrip = UIFactory.Create("Frame", leftPanel, {
		Name = "PartySizeStrip",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 8),
		Size = UDim2.fromOffset(182, 26),
		BackgroundTransparency = 1,
	})
	UIFactory.ListLayout(modeStrip, Enum.FillDirection.Horizontal, 4)

	for idx, pMode in ipairs({
		{ Id = "Solo", Label = "SOLO" },
		{ Id = "Duo", Label = "DUO" },
		{ Id = "Squad", Label = "SQUAD" },
	}) do
		PremiumButton.Create(modeStrip, {
			name = "PartyMode_" .. pMode.Id,
			label = pMode.Label,
			variant = (partySize == pMode.Id) and "gold" or "secondary",
			selected = (partySize == pMode.Id),
			size = UDim2.new(0.333, -3, 1, 0),
			textSize = 9,
			minTextSize = 7,
			layoutOrder = idx,
			onActivated = function()
				PartyController.RequestPartySize(pMode.Id)
				renderColumns(body, Store.GetSnapshot(), rootForModal)
			end,
		})
	end

	local leftScroll = UIFactory.Create("ScrollingFrame", leftPanel, {
		Name = "SocialLeftScroll",
		Position = UDim2.fromOffset(12, 40),
		Size = UDim2.new(1, -24, 1, -94),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = colors.ACCENT_SAPPHIRE,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.fromOffset(0, 0),
	})
	UIFactory.ListLayout(leftScroll, Enum.FillDirection.Vertical, 7)

	-- 1) Incoming Party Invite Banner (if PendingInviteFrom present)
	if pendingPartyFrom ~= "" then
		local pInvCard = UIFactory.Create("Frame", leftScroll, {
			Name = "PartyInviteBanner",
			Size = UDim2.new(1, -4, 0, 56),
			BackgroundColor3 = Color3.fromRGB(16, 32, 58),
			BorderSizePixel = 0,
			LayoutOrder = 1,
		})
		UIFactory.Corner(pInvCard, Theme.Radius.Small)
		UIFactory.Stroke(pInvCard, colors.ACCENT_GOLD_BRIGHT, 1.5, 0.1)

		UIFactory.Label(pInvCard, {
			Name = "InviteTxt",
			Text = I18n.Pick("LỜI MỜI TỔ ĐỘI TỪ: " .. pendingPartyFrom, "PARTY INVITE FROM: " .. pendingPartyFrom),
			Position = UDim2.fromOffset(10, 6),
			Size = UDim2.new(1, -20, 0, 18),
			TextSize = 11,
			TextColor = colors.ACCENT_GOLD_BRIGHT,
			Bold = true,
			Truncate = Enum.TextTruncate.AtEnd,
		})

		PremiumButton.Create(pInvCard, {
			name = "AcceptPartyBtn",
			label = I18n.Pick("CHẤP NHẬN", "ACCEPT"),
			variant = "gold",
			position = UDim2.fromOffset(10, 26),
			size = UDim2.new(0.48, -12, 0, 24),
			textSize = 10,
			minTextSize = 8,
			onActivated = function()
				PartyController.AcceptInvite()
				renderColumns(body, Store.GetSnapshot(), rootForModal)
			end,
		})

		PremiumButton.Create(pInvCard, {
			name = "DeclinePartyBtn",
			label = I18n.Pick("TỪ CHỐI", "DECLINE"),
			variant = "danger",
			position = UDim2.new(0.52, 2, 0, 26),
			size = UDim2.new(0.48, -12, 0, 24),
			textSize = 10,
			minTextSize = 8,
			onActivated = function()
				PartyController.DeclineInvite()
				renderColumns(body, Store.GetSnapshot(), rootForModal)
			end,
		})
	end

	-- 2) Friend Co-op +5% EXP Boost Banner (SocialService:PromptGameInvite)
	local friendCard = UIFactory.Create("Frame", leftScroll, {
		Name = "FriendInviteBoostCard",
		Size = UDim2.new(1, -4, 0, 48),
		BackgroundColor3 = Color3.fromRGB(13, 24, 46),
		BorderSizePixel = 0,
		LayoutOrder = 2,
	})
	UIFactory.Corner(friendCard, Theme.Radius.Small)
	UIFactory.Stroke(
		friendCard,
		friendBoostPct > 0 and colors.SUCCESS or colors.ACCENT_SAPPHIRE,
		1.3,
		0.18
	)
	UIFactory.Icon(friendCard, "Heart", UDim2.fromOffset(9, 13), 20, friendBoostPct > 0 and colors.SUCCESS or colors.ACCENT_GOLD_BRIGHT)
	UIFactory.Label(friendCard, {
		Name = "FriendBoostTitle",
		Text = I18n.Pick(
			string.format("THƯỞNG BẠN BÈ: +%d%% EXP & THÔNG THẠO", friendBoostPct),
			string.format("FRIEND BOOST: +%d%% EXP & MASTERY", friendBoostPct)
		),
		Position = UDim2.fromOffset(34, 6),
		Size = UDim2.new(1, -168, 0, 18),
		TextSize = 10,
		TextColor = friendBoostPct > 0 and colors.SUCCESS or colors.ACCENT_GOLD_BRIGHT,
		Bold = true,
		Truncate = Enum.TextTruncate.AtEnd,
	})
	UIFactory.Label(friendCard, {
		Name = "FriendBoostSub",
		Text = I18n.Pick(
			"+5% EXP mỗi người bạn Roblox cùng Server (tối đa +15%)",
			"+5% EXP per Roblox friend in server (up to +15%)"
		),
		Position = UDim2.fromOffset(34, 24),
		Size = UDim2.new(1, -168, 0, 16),
		TextSize = 9,
		TextColor = colors.TEXT_SECONDARY,
		Truncate = Enum.TextTruncate.AtEnd,
	})
	PremiumButton.Create(friendCard, {
		name = "InviteRobloxFriendsBtn",
		icon = "Gift",
		label = I18n.Pick("+ MỜI BẠN (+5%)", "+ INVITE (+5%)"),
		variant = "gold",
		position = UDim2.new(1, -128, 0.5, -14),
		size = UDim2.fromOffset(120, 28),
		textSize = 9,
		minTextSize = 7,
		onActivated = function()
			if not lp then
				return
			end
			local okInvite = pcall(function()
				SocialService:PromptGameInvite(lp)
			end)
			if not okInvite then
				Store.ShowToast(
					I18n.Pick(
						"Hãy mở game trên ứng dụng Roblox để gửi lời mời bạn bè (+5% EXP/bạn)!",
						"Open in the Roblox app to invite friends (+5% EXP per friend)!"
					),
					"info"
				)
			end
		end,
	})

	-- 3) Live Crew Section (Real CrewData — Scrollable Roster up to 30 Members)
	if not inCrew then
		local crewCreateCard = UIFactory.Create("Frame", leftScroll, {
			Name = "CrewFoundingCard",
			Size = UDim2.new(1, -4, 0, pendingCrewInvite ~= "" and 168 or 122),
			BackgroundColor3 = Color3.fromRGB(11, 17, 32),
			BorderSizePixel = 0,
			LayoutOrder = 3,
		})
		UIFactory.Corner(crewCreateCard, Theme.Radius.Medium)
		UIFactory.Stroke(crewCreateCard, colors.ACCENT_GOLD, 1.3, 0.22)

		UIFactory.Icon(crewCreateCard, "Anchor", UDim2.fromOffset(10, 9), 20, colors.ACCENT_GOLD_BRIGHT)
		UIFactory.Label(crewCreateCard, {
			Name = "CrewHeader",
			Text = I18n.Pick("CHƯA GIA NHẬP HẠM ĐỘI • THÀNH LẬP SKY CREW MỚI", "NO ACTIVE CREW • FOUND A NEW SKY CREW"),
			Position = UDim2.fromOffset(36, 8),
			Size = UDim2.new(1, -46, 0, 18),
			TextSize = 11,
			TextColor = colors.ACCENT_GOLD_BRIGHT,
			Bold = true,
			Truncate = Enum.TextTruncate.AtEnd,
		})
		UIFactory.Label(crewCreateCard, {
			Name = "CrewSub",
			Text = I18n.Pick(
				"Nhập Tên Hạm Đội & Tag (3–4 ký tự) để treo cờ hiệu & cộng Danh Vọng Hạm Đội!",
				"Enter Crew Name & Tag (3-4 chars) to rally up to 30 allies & combine Crew Renown!"
			),
			Position = UDim2.fromOffset(36, 25),
			Size = UDim2.new(1, -46, 0, 15),
			TextSize = 9,
			TextColor = colors.TEXT_SECONDARY,
			Truncate = Enum.TextTruncate.AtEnd,
		})

		local yInputs = 46
		if pendingCrewInvite ~= "" then
			local cInvBar = UIFactory.Create("Frame", crewCreateCard, {
				Name = "CrewPendingInviteBar",
				Position = UDim2.fromOffset(10, 44),
				Size = UDim2.new(1, -20, 0, 38),
				BackgroundColor3 = Color3.fromRGB(20, 34, 62),
				BorderSizePixel = 0,
			})
			UIFactory.Corner(cInvBar, Theme.Radius.Small)
			UIFactory.Stroke(cInvBar, colors.SUCCESS, 1.2, 0.15)
			UIFactory.Label(cInvBar, {
				Name = "InvLbl",
				Text = I18n.Pick("Lời mời Hạm Đội: " .. pendingCrewInvite, "Crew Invite: " .. pendingCrewInvite),
				Position = UDim2.fromOffset(8, 0),
				Size = UDim2.new(1, -118, 1, 0),
				TextSize = 10,
				TextColor = colors.SUCCESS,
				Bold = true,
				Truncate = Enum.TextTruncate.AtEnd,
			})
			PremiumButton.Create(cInvBar, {
				name = "AcceptCrewInviteBtn",
				label = I18n.Pick("CHẤP NHẬN", "ACCEPT"),
				variant = "gold",
				position = UDim2.new(1, -106, 0.5, -13),
				size = UDim2.fromOffset(98, 26),
				textSize = 9,
				minTextSize = 8,
				onActivated = function()
					fireServerUI("CrewAction", {
						subAction = "Accept",
						mode = "JoinCrew",
						crewName = tostring(crew.PendingInviteCrew or pendingCrewInvite),
						name = tostring(crew.PendingInviteCrew or pendingCrewInvite),
					})
					Store.ShowToast(I18n.Pick("Đã chấp nhận lời mời gia nhập Hạm Đội!", "Accepted Crew invite!"), "success")
				end,
			})
			yInputs = 90
		end

		local crewNameBox = UIFactory.Create("TextBox", crewCreateCard, {
			Name = "CrewNameInput",
			Position = UDim2.fromOffset(10, yInputs),
			Size = UDim2.new(0.68, -14, 0, 32),
			Text = tostring(Store.Session.draftCrewName or ""),
			PlaceholderText = I18n.Pick("Tên Hạm Đội (VD: Thiên Long Đoàn)...", "Crew Name (e.g. Sky Vanguard)..."),
			Font = Theme.Fonts.Bold,
			TextSize = 11,
			TextColor3 = colors.TEXT_PRIMARY,
			PlaceholderColor3 = colors.TEXT_SECONDARY,
			BackgroundColor3 = Color3.fromRGB(8, 12, 22),
			BorderSizePixel = 0,
			ClearTextOnFocus = false,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		UIFactory.Corner(crewNameBox, Theme.Radius.Small)
		UIFactory.Stroke(crewNameBox, colors.ACCENT_SAPPHIRE, 1.1, 0.25)
		UIFactory.Padding(crewNameBox, 0, 8, 0, 8)
		crewNameBox:GetPropertyChangedSignal("Text"):Connect(function()
			Store.Session.draftCrewName = crewNameBox.Text
		end)

		local crewTagBox = UIFactory.Create("TextBox", crewCreateCard, {
			Name = "CrewTagInput",
			Position = UDim2.new(0.68, 2, 0, yInputs),
			Size = UDim2.new(0.32, -12, 0, 32),
			Text = tostring(Store.Session.draftCrewTag or ""),
			PlaceholderText = I18n.Pick("Tag (3-4 KT)", "Tag (3-4)"),
			Font = Theme.Fonts.Bold,
			TextSize = 11,
			TextColor3 = colors.ACCENT_GOLD_BRIGHT,
			PlaceholderColor3 = colors.TEXT_SECONDARY,
			BackgroundColor3 = Color3.fromRGB(8, 12, 22),
			BorderSizePixel = 0,
			ClearTextOnFocus = false,
			TextXAlignment = Enum.TextXAlignment.Center,
		})
		UIFactory.Corner(crewTagBox, Theme.Radius.Small)
		UIFactory.Stroke(crewTagBox, colors.ACCENT_GOLD, 1.1, 0.25)
		crewTagBox:GetPropertyChangedSignal("Text"):Connect(function()
			Store.Session.draftCrewTag = crewTagBox.Text
		end)

		PremiumButton.Create(crewCreateCard, {
			name = "CreateCrewBtn",
			icon = "Anchor",
			label = I18n.Pick("THÀNH LẬP HẠM ĐỘI", "CREATE SKY CREW"),
			variant = "gold",
			position = UDim2.fromOffset(10, yInputs + 38),
			size = UDim2.new(1, -20, 0, 32),
			textSize = 11,
			minTextSize = 9,
			onActivated = function()
				local rawName = (tostring(crewNameBox.Text or ""):gsub("^%s+", ""):gsub("%s+$", ""))
				local rawTag = UIFactory.Upper((tostring(crewTagBox.Text or ""):gsub("[^%w]", ""))):sub(1, 4)
				if #rawName < 2 then
					Store.ShowToast(I18n.Pick("Hãy nhập Tên Hạm Đội (tối thiểu 2 ký tự)!", "Enter a Crew Name (at least 2 characters)!"), "warning")
					return
				end
				if #rawTag < 3 then
					rawTag = (rawTag .. "SKY"):sub(1, 3)
				end
				fireServerUI("CrewAction", {
					subAction = "Create",
					mode = "CreateCrew",
					name = rawName,
					crewName = rawName,
					tag = rawTag,
					crewTag = rawTag,
				})
				Store.ShowToast(
					I18n.Pick(
						string.format("Đang thành lập Hạm Đội [%s] %s...", rawTag, rawName),
						string.format("Founding Sky Crew [%s] %s...", rawTag, rawName)
					),
					"success"
				)
			end,
		})
	else
		local crewMembers = type(crew.Members) == "table" and crew.Members or {}
		local shownCount = math.min(#crewMembers, 30)
		local rosterViewH = math.clamp(math.max(1, shownCount) * 24, 28, 120)
		local crewActiveCard = UIFactory.Create("Frame", leftScroll, {
			Name = "CrewLiveBanner",
			Size = UDim2.new(1, -4, 0, 56 + rosterViewH),
			BackgroundColor3 = Color3.fromRGB(14, 22, 42),
			BorderSizePixel = 0,
			LayoutOrder = 3,
		})
		UIFactory.Corner(crewActiveCard, Theme.Radius.Medium)
		UIFactory.Stroke(crewActiveCard, colors.ACCENT_GOLD, 1.4, 0.2)

		UIFactory.Icon(crewActiveCard, "Anchor", UDim2.fromOffset(10, 10), 24, colors.ACCENT_GOLD_BRIGHT)
		UIFactory.Label(crewActiveCard, {
			Name = "CrewLiveTitle",
			Text = string.format("[%s] %s", tostring(crew.Tag ~= "" and crew.Tag or "SKY"), tostring(crew.Name)),
			Position = UDim2.fromOffset(40, 7),
			Size = UDim2.new(1, -150, 0, 20),
			TextSize = 12,
			TextColor = colors.ACCENT_GOLD_BRIGHT,
			Bold = true,
			Truncate = Enum.TextTruncate.AtEnd,
		})
		local totalCrewRenown = tonumber(crew.TotalBounty) or playerRenown
		UIFactory.Label(crewActiveCard, {
			Name = "CrewLiveStats",
			Text = I18n.Pick(
				string.format("Tổng Danh Vọng: %s  •  Thành viên: %d/30", UIFactory.FormatNumber(totalCrewRenown), math.max(1, #crewMembers)),
				string.format("Total Renown: %s  •  Members: %d/30", UIFactory.FormatNumber(totalCrewRenown), math.max(1, #crewMembers))
			),
			Position = UDim2.fromOffset(40, 27),
			Size = UDim2.new(1, -150, 0, 16),
			TextSize = 10,
			TextColor = colors.ACCENT_SAPPHIRE,
			Bold = true,
			Truncate = Enum.TextTruncate.AtEnd,
		})

		PremiumButton.Create(crewActiveCard, {
			name = "LeaveCrewBtn",
			label = I18n.Pick("RỜI HẠM ĐỘI", "LEAVE CREW"),
			variant = "danger",
			position = UDim2.new(1, -104, 0, 10),
			size = UDim2.fromOffset(94, 28),
			textSize = 9,
			minTextSize = 8,
			onActivated = function()
				fireServerUI("CrewAction", { subAction = "Leave", mode = "LeaveCrew" })
				Store.ShowToast(I18n.Pick("Đã gửi yêu cầu rời Hạm Đội.", "Requested to leave Sky Crew."), "info")
			end,
		})

		local rosterScroll = UIFactory.Create("ScrollingFrame", crewActiveCard, {
			Name = "CrewRosterScroll",
			Position = UDim2.fromOffset(10, 48),
			Size = UDim2.new(1, -20, 0, rosterViewH),
			BackgroundColor3 = Color3.fromRGB(9, 15, 28),
			BackgroundTransparency = 0.25,
			BorderSizePixel = 0,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = colors.ACCENT_GOLD,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.fromOffset(0, 0),
		})
		UIFactory.Corner(rosterScroll, Theme.Radius.Small)
		UIFactory.Padding(rosterScroll, 3, 6, 3, 6)
		UIFactory.ListLayout(rosterScroll, Enum.FillDirection.Vertical, 2)

		for mIdx = 1, shownCount do
			local m = crewMembers[mIdx]
			UIFactory.Label(rosterScroll, {
				Name = "CrewMember_" .. mIdx,
				Text = string.format(
					"#%d  %s (%s) — %s RNW",
					mIdx,
					tostring(m.Name or m.DisplayName or "Member"),
					tostring(m.Role or "Member"),
					UIFactory.FormatNumber(tonumber(m.Bounty) or 0)
				),
				Size = UDim2.new(1, -6, 0, 20),
				TextSize = 10,
				TextColor = colors.TEXT_PRIMARY,
				Truncate = Enum.TextTruncate.AtEnd,
				LayoutOrder = mIdx,
			})
		end
	end

	-- 4) Live Party Status & Leave Party Strip
	local partyStatusCard = UIFactory.Create("Frame", leftScroll, {
		Name = "PartyStatusCard",
		Size = UDim2.new(1, -4, 0, 42),
		BackgroundColor3 = Color3.fromRGB(11, 18, 34),
		BorderSizePixel = 0,
		LayoutOrder = 4,
	})
	UIFactory.Corner(partyStatusCard, Theme.Radius.Small)
	UIFactory.Stroke(partyStatusCard, inActiveParty and colors.SUCCESS or colors.STROKE_STEEL, 1.1, 0.3)

	local memberNames = {}
	for _, pm in ipairs(partyMembers) do
		table.insert(memberNames, tostring(pm.name or pm.Name or "Ally"))
	end
	local partySummary = inActiveParty
		and I18n.Pick(
			string.format("TỔ ĐỘI HIỆN TẠI (%d/6): %s", #partyMembers, table.concat(memberNames, ", ")),
			string.format("ACTIVE PARTY (%d/6): %s", #partyMembers, table.concat(memberNames, ", "))
		)
		or I18n.Pick(
			"TỔ ĐỘI HIỆN TẠI: SOLO (Mời người chơi bên dưới để lập đội +EXP!)",
			"ACTIVE PARTY: SOLO (Invite players below for Co-op EXP!)"
		)

	UIFactory.Label(partyStatusCard, {
		Name = "PartySummaryText",
		Text = partySummary,
		Position = UDim2.fromOffset(10, 0),
		Size = UDim2.new(1, inActiveParty and -114 or -20, 1, 0),
		TextSize = 10,
		TextColor = inActiveParty and colors.SUCCESS or colors.TEXT_SECONDARY,
		Bold = true,
		Truncate = Enum.TextTruncate.AtEnd,
	})

	if inActiveParty then
		PremiumButton.Create(partyStatusCard, {
			name = "LeavePartyBtn",
			label = I18n.Pick("RỜI TỔ ĐỘI", "LEAVE PARTY"),
			variant = "danger",
			position = UDim2.new(1, -100, 0.5, -13),
			size = UDim2.fromOffset(92, 26),
			textSize = 9,
			minTextSize = 8,
			onActivated = function()
				PartyController.LeaveParty()
				renderColumns(body, Store.GetSnapshot(), rootForModal)
			end,
		})
	end

	-- 5) Online Players List (3D Inspect + Invite Party + Invite Crew)
	UIFactory.Label(leftScroll, {
		Name = "OnlineHeader",
		Text = I18n.Pick("CHIẾN BINH ĐANG ONLINE TRONG SERVER", "ONLINE PLAYERS IN SERVER"),
		Size = UDim2.new(1, -4, 0, 18),
		TextSize = 10,
		TextColor = colors.ACCENT_SAPPHIRE,
		Bold = true,
		LayoutOrder = 5,
	})

	local onlineList = Players:GetPlayers()
	local primaryInspectTarget = onlineList[1] or Players.LocalPlayer
	for _, plr in ipairs(onlineList) do
		if plr ~= Players.LocalPlayer then
			primaryInspectTarget = plr
			break
		end
	end

	local selfTag = I18n.Pick(" (BẠN)", " (YOU)")
	for idx, plr in ipairs(onlineList) do
		local isSelf = (plr == Players.LocalPlayer)
		local showCrewInvite = inCrew and (not isSelf)
		local pRow = UIFactory.Create("Frame", leftScroll, {
			Name = "PlayerRow_" .. plr.UserId,
			Size = UDim2.new(1, -4, 0, 38),
			BackgroundColor3 = Color3.fromRGB(13, 20, 38),
			BorderSizePixel = 0,
			LayoutOrder = 10 + idx,
		})
		UIFactory.Corner(pRow, Theme.Radius.Small)
		UIFactory.Stroke(pRow, isSelf and colors.ACCENT_GOLD or colors.STROKE_STEEL, 1, 0.35)

		local pLv = plr:GetAttribute("Level") or (isSelf and playerLv) or 1
		local pFac = plr:GetAttribute("Faction") or (snap.fruits and snap.fruits.faction) or "Pirate"
		local rightBtnsWidth = showCrewInvite and 236 or 158
		UIFactory.Label(pRow, {
			Name = "PName",
			Text = string.format("%s%s • Lv.%s [%s]", tostring(plr.DisplayName or plr.Name), isSelf and selfTag or "", tostring(pLv), tostring(pFac)),
			Position = UDim2.fromOffset(10, 0),
			Size = UDim2.new(1, -(rightBtnsWidth + 14), 1, 0),
			TextSize = 10,
			TextColor = colors.TEXT_PRIMARY,
			Bold = true,
			Truncate = Enum.TextTruncate.AtEnd,
		})

		PremiumButton.Create(pRow, {
			name = "Inspect_" .. plr.UserId,
			label = I18n.Pick("SOI 3D", "3D"),
			variant = "primary",
			position = UDim2.new(1, -rightBtnsWidth, 0.5, -13),
			size = UDim2.fromOffset(70, 26),
			textSize = 9,
			minTextSize = 7,
			onActivated = function()
				inspectTargetPlayer(plr, rootForModal)
			end,
		})

		PremiumButton.Create(pRow, {
			name = "InviteParty_" .. plr.UserId,
			label = isSelf and "ONLINE" or I18n.Pick("+ ĐỘI", "+ PARTY"),
			variant = isSelf and "secondary" or "gold",
			disabled = isSelf,
			position = UDim2.new(1, -(rightBtnsWidth - 75), 0.5, -13),
			size = UDim2.fromOffset(76, 26),
			textSize = 9,
			minTextSize = 7,
			onActivated = function()
				PartyController.InvitePlayer(plr)
			end,
		})

		if showCrewInvite then
			PremiumButton.Create(pRow, {
				name = "InviteCrew_" .. plr.UserId,
				label = I18n.Pick("+ CREW", "+ CREW"),
				variant = "secondary",
				position = UDim2.new(1, -80, 0.5, -13),
				size = UDim2.fromOffset(74, 26),
				textSize = 9,
				minTextSize = 7,
				onActivated = function()
					fireServerUI("CrewAction", {
						subAction = "Invite",
						targetName = plr.Name,
						targetUserId = plr.UserId,
					})
					Store.ShowToast(I18n.Pick("Đã mời vào Hạm Đội: ", "Sent Crew Invite to ") .. tostring(plr.DisplayName), "success")
				end,
			})
		end
	end

	-- Bottom 3 Action Buttons Side-by-Side
	local leftBottomBar = UIFactory.Create("Frame", leftPanel, {
		Name = "LeftBottomActions",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 12, 1, -8),
		Size = UDim2.new(1, -24, 0, 38),
		BackgroundTransparency = 1,
	})

	PremiumButton.Create(leftBottomBar, {
		name = "InviteCoopBtn",
		icon = "Users",
		label = I18n.Pick("+ MỜI TỔ ĐỘI", "+ INVITE ALL"),
		variant = "gold",
		position = UDim2.fromOffset(0, 0),
		size = UDim2.new(0.32, -4, 1, 0),
		textSize = 9,
		minTextSize = 7,
		onActivated = function()
			local invitedCount = 0
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= Players.LocalPlayer then
					invitedCount += 1
					PartyController.InvitePlayer(plr)
				end
			end
			if invitedCount == 0 then
				PartyController.CreateParty()
			end
		end,
	})

	PremiumButton.Create(leftBottomBar, {
		name = "Inspect3DPlayerBtn",
		icon = "Shield",
		label = I18n.Pick("SOI TRANG BỊ 3D", "INSPECT 3D"),
		variant = "primary",
		position = UDim2.new(0.32, 3, 0, 0),
		size = UDim2.new(0.34, -6, 1, 0),
		textSize = 9,
		minTextSize = 7,
		onActivated = function()
			inspectTargetPlayer(primaryInspectTarget or Players.LocalPlayer, rootForModal)
		end,
	})

	PremiumButton.Create(leftBottomBar, {
		name = "SummonSeaBeastBtn",
		icon = "Raid",
		label = I18n.Pick("THÚ TRỜI (10M)", "SKY BEAST (10M)"),
		variant = "secondary",
		position = UDim2.new(0.66, 3, 0, 0),
		size = UDim2.new(0.34, -3, 1, 0),
		textSize = 9,
		minTextSize = 7,
		onActivated = function()
			fireServerUI("SummonSeaBeast", {})
			Store.ShowToast(
				I18n.Pick(
					"Đã phát hiệu lệnh Triệu Hồi Thú Trời Hộ Vệ (yêu cầu 10M Danh Vọng)!",
					"Requested Guardian Sky Beast Summon (requires 10M Renown)!"
				),
				"info"
			)
		end,
	})

	-- ========================================================================
	-- RIGHT COLUMN: 7-DAY LOGIN, 6 PLAYTIME GIFTS, 3 DAILY MISSIONS,
	--               GIFTCODE BOX, GLOBAL LEADERBOARDS & 8 LAUNCH BADGES
	-- ========================================================================
	local rightPanel = PremiumPanel.Create(body, {
		name = "RewardsAndLeaderboardPanel",
		variant = "gold",
		position = portrait and UDim2.new(0, 0, 0.46, 4) or UDim2.new(0.47, 6, 0, 0),
		size = portrait and UDim2.new(1, 0, 0.54, -4) or UDim2.new(0.53, -6, 1, 0),
	})

	local dailyLogin = snap.dailyLogin or {}
	local loginStreak = tonumber(dailyLogin.Streak)
		or (lp and tonumber(lp:GetAttribute("LoginStreak")))
		or 1
	local clampedStreak = math.clamp(loginStreak, 1, 7)
	local serverCanClaim = (dailyLogin.CanClaim ~= false)
	if serverCanClaim and SocialRewards.LastSeenStreak ~= clampedStreak then
		SocialRewards.LastSeenStreak = clampedStreak
		Store.Session.claimedLoginDays[clampedStreak] = nil
	end
	local todayClaimed = (not serverCanClaim) or (Store.Session.claimedLoginDays[clampedStreak] == true)

	UIFactory.Label(rightPanel, {
		Name = "RightHeaderTitle",
		Text = I18n.Pick(
			"QUÀ ĐIỂM DANH • QUÀ ONLINE • NHIỆM VỤ • BXH LIÊN SERVER & HUY HIỆU",
			"LOGIN • PLAYTIME GIFTS • DAILY MISSIONS • GLOBAL RANKINGS & BADGES"
		),
		Position = UDim2.fromOffset(14, 10),
		Size = UDim2.new(1, -166, 0, 20),
		TextSize = 10,
		TextColor = colors.ACCENT_GOLD_BRIGHT,
		Bold = true,
		Truncate = Enum.TextTruncate.AtEnd,
	})

	local function claimDailyGiftForDay(reqDay)
		local dayNum = math.clamp(tonumber(reqDay) or clampedStreak, 1, 7)
		if dayNum > clampedStreak then
			Store.ShowToast(I18n.Pick("Hãy điểm danh lần lượt từng ngày để mở khóa mốc này!", "Log in on consecutive days to unlock this milestone!"), "warning")
			return
		end
		if todayClaimed and dayNum <= clampedStreak then
			Store.ShowToast(I18n.Pick("Bạn đã nhận quà Điểm Danh hôm nay rồi!", "Today's login reward has already been claimed!"), "info")
			return
		end
		Store.Session.claimedLoginDays[clampedStreak] = true
		fireServerUI("ClaimDailyReward", { day = clampedStreak, kind = "Login" })
		renderColumns(body, Store.GetSnapshot(), rootForModal)
	end

	PremiumButton.Create(rightPanel, {
		name = "TopClaimDailyBtn",
		icon = "Gift",
		label = todayClaimed
			and I18n.Pick("ĐÃ NHẬN NGÀY " .. clampedStreak, "CLAIMED DAY " .. clampedStreak)
			or I18n.Pick("NHẬN NGÀY " .. clampedStreak, "CLAIM DAY " .. clampedStreak),
		variant = todayClaimed and "secondary" or "gold",
		disabled = todayClaimed,
		position = UDim2.new(1, -148, 0, 7),
		size = UDim2.fromOffset(136, 25),
		textSize = 9,
		minTextSize = 7,
		onActivated = function()
			claimDailyGiftForDay(clampedStreak)
		end,
	})

	local rightScroll = UIFactory.Create("ScrollingFrame", rightPanel, {
		Name = "SocialRightScroll",
		Position = UDim2.fromOffset(10, 36),
		Size = UDim2.new(1, -20, 1, -44),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = colors.ACCENT_GOLD,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.fromOffset(0, 0),
	})
	UIFactory.ListLayout(rightScroll, Enum.FillDirection.Vertical, 8)

	-- 1) 7 Glossy Rarity Day Cards Side-by-Side
	local streakGrid = UIFactory.Create("Frame", rightScroll, {
		Name = "Glossy7DayStrip",
		Size = UDim2.new(1, -4, 0, 82),
		BackgroundTransparency = 1,
		LayoutOrder = 1,
	})
	UIFactory.ListLayout(streakGrid, Enum.FillDirection.Horizontal, 5)

	for _, dDef in ipairs(DAILY_7_REWARDS) do
		local isToday = (dDef.Day == clampedStreak)
		local claimed = (dDef.Day < clampedStreak) or (isToday and todayClaimed)
		local dayTile = makeGlossyDayCard(streakGrid, dDef, isToday, claimed)
		dayTile.Activated:Connect(function()
			claimDailyGiftForDay(dDef.Day)
		end)
	end

	-- 2) 6-Tier Session Playtime Gifts (5m, 10m, 20m, 30m, 45m, 60m)
	local playtimeBox = UIFactory.Create("Frame", rightScroll, {
		Name = "PlaytimeGiftsSection",
		Size = UDim2.new(1, -4, 0, 102),
		BackgroundColor3 = Color3.fromRGB(9, 14, 27),
		BorderSizePixel = 0,
		LayoutOrder = 2,
	})
	UIFactory.Corner(playtimeBox, Theme.Radius.Medium)
	UIFactory.Stroke(playtimeBox, colors.ACCENT_SAPPHIRE, 1.2, 0.22)

	UIFactory.Icon(playtimeBox, "Gift", UDim2.fromOffset(10, 5), 15, colors.ACCENT_GOLD_BRIGHT)
	UIFactory.Label(playtimeBox, {
		Name = "PlaytimeHeader",
		Text = I18n.Pick("6 QUÀ THỜI GIAN ONLINE (5P → 60P)", "6 SESSION PLAYTIME GIFTS (5M → 60M)"),
		Position = UDim2.fromOffset(30, 4),
		Size = UDim2.new(1, -160, 0, 16),
		TextSize = 10,
		TextColor = colors.ACCENT_GOLD_BRIGHT,
		Bold = true,
		Truncate = Enum.TextTruncate.AtEnd,
	})
	local ptSub = UIFactory.Label(playtimeBox, {
		Name = "PlaytimeHeaderSub",
		Text = "",
		Position = UDim2.new(1, -126, 0, 4),
		Size = UDim2.fromOffset(116, 16),
		TextSize = 9,
		TextColor = colors.ACCENT_SAPPHIRE,
		Bold = true,
		XAlign = Enum.TextXAlignment.Right,
		Truncate = Enum.TextTruncate.AtEnd,
	})
	SocialRewards.Refs.PlaytimeHeaderSub = ptSub

	local ptGrid = UIFactory.Create("Frame", playtimeBox, {
		Name = "PlaytimeTierGrid",
		Position = UDim2.fromOffset(8, 23),
		Size = UDim2.new(1, -16, 0, 73),
		BackgroundTransparency = 1,
	})
	UIFactory.ListLayout(ptGrid, Enum.FillDirection.Horizontal, 5)

	for _, tDef in ipairs(PLAYTIME_6_TIERS) do
		local pal = RARITY_PALETTE[tDef.Rarity] or RARITY_PALETTE.Rare
		local ptTile = UIFactory.Create("TextButton", ptGrid, {
			Name = "PlaytimeTier_" .. tDef.Index,
			Size = UDim2.new(1 / 6, -4, 1, 0),
			BackgroundColor3 = Color3.fromRGB(14, 22, 42),
			BorderSizePixel = 0,
			Text = "",
			AutoButtonColor = true,
			LayoutOrder = tDef.Index,
			ClipsDescendants = true,
		})
		UIFactory.Corner(ptTile, Theme.Radius.Small)
		local ptStroke = UIFactory.Stroke(ptTile, pal.Stroke, 1.2, 0.16)

		UIFactory.Label(ptTile, {
			Name = "MinTag",
			Text = I18n.GetLanguage() == "en" and tDef.TitleEn or tDef.TitleVi,
			Position = UDim2.fromOffset(2, 2),
			Size = UDim2.new(1, -4, 0, 13),
			TextSize = 8,
			TextColor = pal.Text,
			Bold = true,
			XAlign = Enum.TextXAlignment.Center,
			Truncate = Enum.TextTruncate.AtEnd,
		})

		UIFactory.Icon(ptTile, tDef.Icon, UDim2.new(0.5, -9, 0, 17), 18, Color3.fromRGB(255, 255, 255))

		local rCap = UIFactory.Label(ptTile, {
			Name = "RewardCap",
			Text = I18n.GetLanguage() == "en" and tDef.RewardEn or tDef.RewardVi,
			Position = UDim2.fromOffset(2, 37),
			Size = UDim2.new(1, -4, 0, 16),
			TextSize = 8,
			TextColor = colors.TEXT_PRIMARY,
			Bold = true,
			XAlign = Enum.TextXAlignment.Center,
			Wrapped = true,
		})
		rCap.TextScaled = true
		UIFactory.TextSizeConstraint(rCap, 6, 8)

		local statusLbl = UIFactory.Label(ptTile, {
			Name = "TimerStatus",
			Text = "--:--",
			Position = UDim2.new(0, 2, 1, -15),
			Size = UDim2.new(1, -4, 0, 14),
			TextSize = 8,
			TextColor = colors.TEXT_SECONDARY,
			Bold = true,
			XAlign = Enum.TextXAlignment.Center,
			Truncate = Enum.TextTruncate.AtEnd,
		})

		table.insert(SocialRewards.PlaytimeTileRefs, {
			Def = tDef,
			Tile = ptTile,
			Stroke = ptStroke,
			DefaultStrokeColor = pal.Stroke,
			StatusLabel = statusLbl,
		})

		ptTile.Activated:Connect(function()
			local curSnap = Store.GetSnapshot()
			if isPlaytimeTierClaimed(curSnap, tDef.Index) then
				Store.ShowToast(I18n.Pick("Bạn đã nhận mốc quà online này rồi!", "You already claimed this session gift!"), "info")
				return
			end
			local elapsedNow = getLivePlaytimeElapsed(curSnap)
			if elapsedNow < tDef.RequiredSec then
				local remSec = tDef.RequiredSec - elapsedNow
				Store.ShowToast(
					I18n.Pick(
						"Cần online thêm " .. formatMmSs(remSec) .. " để mở khóa mốc " .. tDef.TitleVi .. "!",
						"Stay online " .. formatMmSs(remSec) .. " longer to unlock the " .. tDef.TitleEn .. " gift!"
					),
					"warning"
				)
				return
			end
			Store.Session.claimedPlaytimeTiers[tDef.Index] = true
			fireServerUI("ClaimPlaytimeGift", { index = tDef.Index, tier = tDef.Index })
			refreshPlaytimeTileVisuals(curSnap)
		end)
	end
	refreshPlaytimeTileVisuals(snap)

	-- 3) 3 Daily Missions Section
	local missionsBox = UIFactory.Create("Frame", rightScroll, {
		Name = "DailyBountiesSection",
		Size = UDim2.new(1, -4, 0, 126),
		BackgroundColor3 = Color3.fromRGB(9, 14, 27),
		BorderSizePixel = 0,
		LayoutOrder = 3,
	})
	UIFactory.Corner(missionsBox, Theme.Radius.Medium)
	UIFactory.Stroke(missionsBox, colors.ACCENT_GOLD, 1.2, 0.25)

	UIFactory.Icon(missionsBox, "Sword", UDim2.fromOffset(10, 6), 15, colors.ACCENT_GOLD_BRIGHT)
	UIFactory.Label(missionsBox, {
		Name = "BountiesHeader",
		Text = I18n.Pick("3 NHIỆM VỤ NGÀY (LÀM MỚI MỖI NGÀY)", "3 DAILY MISSIONS (RESETS DAILY)"),
		Position = UDim2.fromOffset(30, 4),
		Size = UDim2.new(1, -40, 0, 18),
		TextSize = 10,
		TextColor = colors.ACCENT_GOLD_BRIGHT,
		Bold = true,
		Truncate = Enum.TextTruncate.AtEnd,
	})

	local missionList = (type(snap.dailyBounties) == "table" and #snap.dailyBounties > 0)
		and snap.dailyBounties
		or FALLBACK_DAILY_MISSIONS

	for bIdx = 1, math.min(3, #missionList) do
		local b = missionList[bIdx]
		local prog = math.max(0, tonumber(b.Progress) or 0)
		local goal = math.max(1, tonumber(b.Count) or 1)
		local isDone = prog >= goal
		local isClaimed = b.Claimed == true

		local bRow = UIFactory.Create("Frame", missionsBox, {
			Name = "MissionRow_" .. bIdx,
			Position = UDim2.fromOffset(8, 24 + (bIdx - 1) * 33),
			Size = UDim2.new(1, -16, 0, 30),
			BackgroundColor3 = Color3.fromRGB(13, 21, 38),
			BorderSizePixel = 0,
		})
		UIFactory.Corner(bRow, Theme.Radius.Small)
		UIFactory.Stroke(bRow, isClaimed and colors.SUCCESS or (isDone and colors.ACCENT_GOLD_BRIGHT or colors.STROKE_STEEL), 1, 0.3)

		local rewardStr = string.format(
			"+%s %s%s",
			UIFactory.FormatNumber(tonumber(b.Gold) or 25000),
			I18n.Pick("Vàng", "Gold"),
			(tonumber(b.Shards) or 0) > 0 and (" • +" .. UIFactory.FormatNumber(b.Shards) .. " Shards") or ""
		)

		UIFactory.Label(bRow, {
			Name = "BTitle",
			Text = string.format("%s  (%d/%d)", localizeDailyMissionTitle(b), math.min(prog, goal), goal),
			Position = UDim2.fromOffset(8, 1),
			Size = UDim2.new(1, -124, 0, 15),
			TextSize = 10,
			TextColor = isClaimed and colors.TEXT_SECONDARY or colors.TEXT_PRIMARY,
			Bold = true,
			Truncate = Enum.TextTruncate.AtEnd,
		})

		UIFactory.Label(bRow, {
			Name = "BReward",
			Text = rewardStr,
			Position = UDim2.fromOffset(8, 15),
			Size = UDim2.new(1, -124, 0, 13),
			TextSize = 9,
			TextColor = colors.SUCCESS,
			Bold = true,
			Truncate = Enum.TextTruncate.AtEnd,
		})

		local btnLbl = isClaimed
			and I18n.Pick("ĐÃ NHẬN ✓", "CLAIMED ✓")
			or (isDone and I18n.Pick("NHẬN THƯỞNG", "CLAIM") or string.format("%d / %d", prog, goal))

		PremiumButton.Create(bRow, {
			name = "ClaimMission_" .. bIdx,
			label = btnLbl,
			variant = isClaimed and "secondary" or (isDone and "gold" or "primary"),
			disabled = isClaimed or (not isDone),
			position = UDim2.new(1, -110, 0.5, -12),
			size = UDim2.fromOffset(104, 24),
			textSize = 9,
			minTextSize = 7,
			onActivated = function()
				fireServerUI("ClaimBountyReward", {
					bountyId = b.Id,
					taskId = b.Id,
					id = b.Id,
				})
				Store.ShowToast(I18n.Pick("Đang nhận thưởng Nhiệm Vụ Ngày!", "Claiming Daily Mission reward!"), "success")
			end,
		})
	end

	-- 4) Manual Promo Giftcode Box + Official Community Group Hint (Zero Spoiled Chips)
	local giftCard = UIFactory.Create("Frame", rightScroll, {
		Name = "GiftcodeSection",
		Size = UDim2.new(1, -4, 0, 56),
		BackgroundColor3 = Color3.fromRGB(9, 14, 27),
		BorderSizePixel = 0,
		LayoutOrder = 4,
	})
	UIFactory.Corner(giftCard, Theme.Radius.Medium)
	UIFactory.Stroke(giftCard, colors.ACCENT_GOLD, 1.1, 0.28)

	local codeBox = UIFactory.Create("TextBox", giftCard, {
		Name = "GiftcodeInput",
		Position = UDim2.fromOffset(8, 6),
		Size = UDim2.new(0.60, -12, 0, 30),
		Text = "",
		PlaceholderText = I18n.Pick("Nhập Mã Quà Tặng (Giftcode)...", "Enter Promo Giftcode..."),
		Font = Theme.Fonts.Bold,
		TextSize = 11,
		TextColor3 = colors.TEXT_PRIMARY,
		PlaceholderColor3 = colors.TEXT_SECONDARY,
		BackgroundColor3 = Color3.fromRGB(8, 12, 22),
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	UIFactory.Corner(codeBox, Theme.Radius.Small)
	UIFactory.Stroke(codeBox, colors.ACCENT_GOLD, 1.1, 0.24)
	UIFactory.Padding(codeBox, 0, 10, 0, 10)

	local function submitGiftcode(rawCode)
		local clean = UIFactory.Upper((tostring(rawCode or "")):gsub("%s+", ""))
		if clean == "" then
			Store.ShowToast(I18n.Pick("Hãy nhập Mã Giftcode vào ô trống trước khi kích hoạt!", "Enter a valid Giftcode in the box first!"), "warning")
			return
		end
		codeBox.Text = clean
		fireServerUI("RedeemCode", { code = clean })
		Store.ShowToast(I18n.Pick("Đang kích hoạt Mã Giftcode: ", "Redeeming Giftcode: ") .. clean, "success")
	end

	PremiumButton.Create(giftCard, {
		name = "RedeemGiftcodeBtn",
		icon = "Gift",
		label = I18n.Pick("KÍCH HOẠT MÃ", "REDEEM CODE"),
		variant = "gold",
		position = UDim2.new(0.60, 2, 0, 6),
		size = UDim2.new(0.40, -10, 0, 30),
		textSize = 10,
		minTextSize = 8,
		onActivated = function()
			submitGiftcode(codeBox.Text)
		end,
	})

	UIFactory.Label(giftCard, {
		Name = "GiftcodeHint",
		Text = I18n.Pick(
			"Theo dõi Nhóm Cộng Đồng Roblox chính thức của SKYBREAK để nhận Mã Giftcode sự kiện mới!",
			"Follow the official SKYBREAK Roblox Community Group for new event & milestone Giftcodes!"
		),
		Position = UDim2.fromOffset(10, 38),
		Size = UDim2.new(1, -20, 0, 15),
		TextSize = 8,
		TextColor = colors.TEXT_SECONDARY,
		Truncate = Enum.TextTruncate.AtEnd,
	})

	-- 5) Global Cross-Server OrderedDataStore Leaderboards (Level | Renown | BossDPS)
	local activeCat = SocialRewards.ActiveLbCategory or "Level"
	local glb = type(snap.GlobalLeaderboards) == "table" and snap.GlobalLeaderboards or {}
	local rawCatRows = type(glb[activeCat]) == "table" and glb[activeCat] or {}

	local onlineByUserId = {}
	for _, plr in ipairs(onlineList) do
		onlineByUserId[plr.UserId] = plr
	end

	local lbEntries = {}
	for idx, r in ipairs(rawCatRows) do
		local uid = tonumber(r.UserId) or 0
		local livePlr = uid > 0 and onlineByUserId[uid] or nil
		local isSelf = (livePlr ~= nil and livePlr == lp) or (lp ~= nil and uid > 0 and uid == lp.UserId)
		table.insert(lbEntries, {
			Rank = tonumber(r.Rank) or idx,
			UserId = uid,
			Name = tostring(r.DisplayName or r.Name or "Skyborn") .. (isSelf and selfTag or ""),
			Value = math.max(0, tonumber(r.Value or r.Score) or 0),
			IsSelf = isSelf,
			PlayerRef = livePlr,
		})
	end

	if #lbEntries == 0 and (activeCat == "Level" or activeCat == "Renown") then
		for _, plr in ipairs(onlineList) do
			local isSelf = (plr == lp)
			local val = 0
			if activeCat == "Level" then
				val = math.max(1, tonumber(plr:GetAttribute("Level")) or (isSelf and playerLv) or 1)
			else
				val = math.max(0, tonumber(plr:GetAttribute("Bounty")) or (isSelf and playerRenown) or 0)
			end
			table.insert(lbEntries, {
				Rank = 0,
				UserId = plr.UserId,
				Name = tostring(plr.DisplayName or plr.Name) .. (isSelf and selfTag or ""),
				Value = val,
				IsSelf = isSelf,
				PlayerRef = plr,
			})
		end
		table.sort(lbEntries, function(a, b)
			if a.Value ~= b.Value then
				return a.Value > b.Value
			end
			return a.Name < b.Name
		end)
		for idx, item in ipairs(lbEntries) do
			item.Rank = idx
		end
	end

	local holoBox = UIFactory.Create("Frame", rightScroll, {
		Name = "HologramLeaderboardBox",
		Size = UDim2.new(1, -4, 0, 224),
		BackgroundColor3 = Color3.fromRGB(9, 14, 27),
		BorderSizePixel = 0,
		LayoutOrder = 5,
	})
	UIFactory.Corner(holoBox, Theme.Radius.Medium)
	UIFactory.Stroke(holoBox, Color3.fromRGB(56, 189, 248), 1.3, 0.22)

	UIFactory.Icon(holoBox, "Crown", UDim2.fromOffset(10, 6), 16, colors.ACCENT_GOLD_BRIGHT)
	UIFactory.Label(holoBox, {
		Name = "LeaderboardHeader",
		Text = I18n.Pick("BẢNG XẾP HẠNG LIÊN MÁY CHỦ (TOP 20)", "GLOBAL CROSS-SERVER LEADERBOARD (TOP 20)"),
		Position = UDim2.fromOffset(30, 5),
		Size = UDim2.new(1, -42, 0, 18),
		TextSize = 10,
		TextColor = colors.ACCENT_GOLD_BRIGHT,
		Bold = true,
		Truncate = Enum.TextTruncate.AtEnd,
	})

	local catTabRow = UIFactory.Create("Frame", holoBox, {
		Name = "LeaderboardCategoryTabs",
		Position = UDim2.fromOffset(8, 25),
		Size = UDim2.new(1, -16, 0, 24),
		BackgroundTransparency = 1,
	})
	UIFactory.ListLayout(catTabRow, Enum.FillDirection.Horizontal, 5)

	for cIdx, catDef in ipairs({
		{ Id = "Level", LabelVi = "TOP CẤP ĐỘ", LabelEn = "TOP LEVEL" },
		{ Id = "Renown", LabelVi = "TOP DANH VỌNG", LabelEn = "TOP RENOWN" },
		{ Id = "BossDPS", LabelVi = "TOP DPS BOSS", LabelEn = "BOSS DPS" },
	}) do
		local isSel = (activeCat == catDef.Id)
		PremiumButton.Create(catTabRow, {
			name = "LbCat_" .. catDef.Id,
			label = I18n.GetLanguage() == "en" and catDef.LabelEn or catDef.LabelVi,
			variant = isSel and "gold" or "secondary",
			selected = isSel,
			size = UDim2.new(0.333, -4, 1, 0),
			textSize = 9,
			minTextSize = 7,
			layoutOrder = cIdx,
			onActivated = function()
				SocialRewards.ActiveLbCategory = catDef.Id
				requestLeaderboardRefresh(catDef.Id, false)
				SocialRewards.LastSig = computeSocialSignature(Store.GetSnapshot())
				renderColumns(body, Store.GetSnapshot(), rootForModal)
			end,
		})
	end

	local lbScroll = UIFactory.Create("ScrollingFrame", holoBox, {
		Name = "LeaderboardScroll",
		Position = UDim2.fromOffset(8, 54),
		Size = UDim2.new(1, -16, 1, -60),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = colors.ACCENT_GOLD,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.fromOffset(0, 0),
	})
	UIFactory.ListLayout(lbScroll, Enum.FillDirection.Vertical, 4)

	if #lbEntries == 0 then
		UIFactory.Label(lbScroll, {
			Name = "EmptyLeaderboardHint",
			Text = I18n.Pick(
				"Chưa có kỷ lục Sát Thương Boss trên máy chủ — Hãy khiêu chiến Boss Đảo để ghi danh #1!",
				"No Boss DPS records yet — Challenge an Island or Raid Boss to claim #1!"
			),
			Size = UDim2.new(1, -8, 0, 46),
			TextSize = 10,
			TextColor = colors.TEXT_SECONDARY,
			XAlign = Enum.TextXAlignment.Center,
			Wrapped = true,
		})
	else
		for rankIdx, e in ipairs(lbEntries) do
			local rank = e.Rank > 0 and e.Rank or rankIdx
			local rankColor = (rank == 1 and colors.ACCENT_GOLD_BRIGHT)
				or (rank == 2 and Color3.fromRGB(196, 218, 248))
				or (rank == 3 and Color3.fromRGB(242, 166, 98))
				or Color3.fromRGB(56, 189, 248)

			local row = UIFactory.Create("TextButton", lbScroll, {
				Name = "Rank_" .. rank,
				Size = UDim2.new(1, -6, 0, 36),
				BackgroundColor3 = e.IsSelf and Color3.fromRGB(18, 28, 52) or Color3.fromRGB(12, 18, 34),
				BorderSizePixel = 0,
				Text = "",
				AutoButtonColor = (e.PlayerRef ~= nil),
				LayoutOrder = rankIdx,
			})
			UIFactory.Corner(row, Theme.Radius.Small)
			UIFactory.Stroke(row, rankColor, e.IsSelf and 1.6 or 1.0, 0.24)

			local rankBox = UIFactory.Create("Frame", row, {
				Name = "RankCrownBadge",
				Position = UDim2.fromOffset(5, 5),
				Size = UDim2.fromOffset(64, 26),
				BackgroundColor3 = Color3.fromRGB(8, 12, 22),
				BorderSizePixel = 0,
			})
			UIFactory.Corner(rankBox, Theme.Radius.Small)
			UIFactory.Stroke(rankBox, rankColor, 1.0, 0.25)
			UIFactory.Icon(rankBox, "Crown", UDim2.fromOffset(5, 6), 14, rankColor)
			UIFactory.Label(rankBox, {
				Name = "RankNum",
				Text = "#" .. tostring(rank),
				Position = UDim2.fromOffset(22, 0),
				Size = UDim2.new(1, -24, 1, 0),
				TextSize = 10,
				TextColor = rankColor,
				Bold = true,
				Truncate = Enum.TextTruncate.AtEnd,
			})

			UIFactory.Label(row, {
				Name = "PlayerDisplay",
				Text = e.Name,
				Position = UDim2.fromOffset(76, 0),
				Size = UDim2.new(1, -196, 1, 0),
				TextSize = 10,
				TextColor = (rank == 1) and colors.ACCENT_GOLD_BRIGHT or colors.TEXT_PRIMARY,
				Bold = true,
				Truncate = Enum.TextTruncate.AtEnd,
			})

			local metricText = ""
			if activeCat == "Level" then
				metricText = "Lv." .. UIFactory.FormatNumber(e.Value)
			elseif activeCat == "Renown" then
				metricText = UIFactory.FormatNumber(e.Value) .. " RNW"
			else
				metricText = UIFactory.FormatNumber(e.Value) .. " DPS"
			end

			UIFactory.Label(row, {
				Name = "ScoreLabel",
				Text = metricText,
				Position = UDim2.new(1, -116, 0, 0),
				Size = UDim2.fromOffset(108, 36),
				TextSize = 10,
				TextColor = rankColor,
				Bold = true,
				XAlign = Enum.TextXAlignment.Right,
				Truncate = Enum.TextTruncate.AtEnd,
			})

			if e.PlayerRef then
				row.Activated:Connect(function()
					inspectTargetPlayer(e.PlayerRef, rootForModal)
				end)
			end
		end
	end

	-- 6) 8 Public-Launch Badges Showcase (BadgeConfig.Badges + UnlockedBadges)
	local badgeList = (BadgeConfig and type(BadgeConfig.Badges) == "table" and #BadgeConfig.Badges > 0)
		and BadgeConfig.Badges
		or FALLBACK_BADGES
	local unlockedMap = type(snap.UnlockedBadges) == "table" and snap.UnlockedBadges or {}
	local unlockedCount = 0
	for _, bDef in ipairs(badgeList) do
		local k = tostring(bDef.Id or bDef.Key or "")
		if k ~= "" and unlockedMap[k] == true then
			unlockedCount += 1
		end
	end

	local badgeRowsH = #badgeList * 42
	local badgesBox = UIFactory.Create("Frame", rightScroll, {
		Name = "LaunchBadgesSection",
		Size = UDim2.new(1, -4, 0, 32 + badgeRowsH),
		BackgroundColor3 = Color3.fromRGB(9, 14, 27),
		BorderSizePixel = 0,
		LayoutOrder = 6,
	})
	UIFactory.Corner(badgesBox, Theme.Radius.Medium)
	UIFactory.Stroke(badgesBox, colors.ACCENT_GOLD, 1.2, 0.25)

	UIFactory.Icon(badgesBox, "Star", UDim2.fromOffset(10, 6), 15, colors.ACCENT_GOLD_BRIGHT)
	UIFactory.Label(badgesBox, {
		Name = "BadgesHeader",
		Text = I18n.Pick(
			string.format("8 HUY HIỆU DANH GIÁ ROBLOX (%d/%d ĐÃ ĐẠT)", unlockedCount, #badgeList),
			string.format("8 OFFICIAL LAUNCH BADGES (%d/%d UNLOCKED)", unlockedCount, #badgeList)
		),
		Position = UDim2.fromOffset(30, 5),
		Size = UDim2.new(1, -40, 0, 18),
		TextSize = 10,
		TextColor = colors.ACCENT_GOLD_BRIGHT,
		Bold = true,
		Truncate = Enum.TextTruncate.AtEnd,
	})

	for idx, bDef in ipairs(badgeList) do
		local bKey = tostring(bDef.Id or bDef.Key or "")
		local isUnlocked = (bKey ~= "" and unlockedMap[bKey] == true)
		local pal = RARITY_PALETTE[bDef.Rarity] or RARITY_PALETTE.Rare

		local card = UIFactory.Create("Frame", badgesBox, {
			Name = "Badge_" .. bKey,
			Position = UDim2.fromOffset(8, 26 + (idx - 1) * 41),
			Size = UDim2.new(1, -16, 0, 37),
			BackgroundColor3 = isUnlocked and Color3.fromRGB(15, 25, 46) or Color3.fromRGB(11, 16, 30),
			BorderSizePixel = 0,
		})
		UIFactory.Corner(card, Theme.Radius.Small)
		UIFactory.Stroke(card, isUnlocked and colors.SUCCESS or pal.Stroke, isUnlocked and 1.4 or 1.0, isUnlocked and 0.15 or 0.45)

		UIFactory.Icon(
			card,
			tostring(bDef.Icon or "Star"),
			UDim2.fromOffset(8, 9),
			19,
			isUnlocked and pal.Text or colors.TEXT_SECONDARY
		)

		UIFactory.Label(card, {
			Name = "BadgeTitle",
			Text = I18n.GetLanguage() == "en" and tostring(bDef.TitleEn or bDef.NameEn or bKey) or tostring(bDef.TitleVi or bDef.NameVi or bKey),
			Position = UDim2.fromOffset(34, 3),
			Size = UDim2.new(1, -124, 0, 16),
			TextSize = 10,
			TextColor = isUnlocked and colors.ACCENT_GOLD_BRIGHT or colors.TEXT_PRIMARY,
			Bold = true,
			Truncate = Enum.TextTruncate.AtEnd,
		})

		UIFactory.Label(card, {
			Name = "BadgeDesc",
			Text = I18n.GetLanguage() == "en" and tostring(bDef.DescEn or "") or tostring(bDef.DescVi or ""),
			Position = UDim2.fromOffset(34, 19),
			Size = UDim2.new(1, -124, 0, 14),
			TextSize = 8,
			TextColor = colors.TEXT_SECONDARY,
			Truncate = Enum.TextTruncate.AtEnd,
		})

		UIFactory.Label(card, {
			Name = "BadgeState",
			Text = isUnlocked and I18n.Pick("ĐÃ ĐẠT ✓", "UNLOCKED ✓") or I18n.Pick("CHƯA MỞ", "LOCKED"),
			Position = UDim2.new(1, -86, 0, 0),
			Size = UDim2.fromOffset(78, 37),
			TextSize = 9,
			TextColor = isUnlocked and colors.SUCCESS or colors.TEXT_SECONDARY,
			Bold = true,
			XAlign = Enum.TextXAlignment.Right,
			Truncate = Enum.TextTruncate.AtEnd,
		})
	end
end

function SocialRewards.Build(parent, _responsiveState)
	SocialRewards.Cleanup()
	local snap = Store.GetSnapshot()

	local root = UIFactory.Create("Frame", parent, {
		Name = "SocialRewardsScreen",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 2,
	})

	local function headerTitleText()
		return I18n.Pick(
			"TỔ ĐỘI & HẠM ĐỘI • QUÀ ONLINE • BXH & HUY HIỆU [B]",
			"PARTY & CREW • PLAYTIME GIFTS • RANKINGS & BADGES [B]"
		)
	end

	local _, headerRefs = UIFactory.BuildScreenHeader(root, {
		ActiveScreen = UIState.Screens.SocialRewards,
		Title = headerTitleText(),
		Snapshot = snap,
		OnNavigate = function(targetId)
			ScreenRouter.Navigate(targetId)
		end,
		OnClose = function()
			ScreenRouter.CloseAllToHUD()
		end,
	})

	local body = UIFactory.Create("Frame", root, {
		Name = "SocialBody",
		Position = UDim2.fromOffset(16, 72),
		Size = UDim2.new(1, -32, 1, -84),
		BackgroundTransparency = 1,
	})

	SocialRewards.Refs = {
		Root = root,
		Body = body,
		HeaderRefs = headerRefs,
	}

	requestLeaderboardRefresh(SocialRewards.ActiveLbCategory or "Level", false)
	SocialRewards.LastSig = computeSocialSignature(snap)
	renderColumns(body, snap, root)

	-- Live 1s playtime gift countdown ticker (in-place label update, zero DOM churn)
	SocialRewards.PlaytimeTickerToken += 1
	local myToken = SocialRewards.PlaytimeTickerToken
	task.spawn(function()
		while SocialRewards.PlaytimeTickerToken == myToken and root.Parent do
			task.wait(1)
			if SocialRewards.PlaytimeTickerToken ~= myToken or not root.Parent then
				break
			end
			refreshPlaytimeTileVisuals(Store.GetSnapshot())
		end
	end)

	-- Language toggle & viewport orientation listeners
	local subscribeLang = I18n.OnLanguageChanged or I18n.OnChanged
	local unsubLang = (type(subscribeLang) == "function")
		and subscribeLang(function()
			if not root.Parent then
				return
			end
			if headerRefs and headerRefs.TitleLabel then
				headerRefs.TitleLabel.Text = headerTitleText()
			end
			local curSnap = Store.GetSnapshot()
			SocialRewards.LastSig = computeSocialSignature(curSnap)
			renderColumns(body, curSnap, root)
		end)
		or nil
	table.insert(SocialRewards.BustConnections, {
		Disconnect = function()
			if type(unsubLang) == "function" then
				unsubLang()
			end
		end,
	})

	local cam = Workspace.CurrentCamera
	if cam then
		table.insert(
			SocialRewards.BustConnections,
			cam:GetPropertyChangedSignal("ViewportSize"):Connect(function()
				if not root.Parent or SocialRewards.InspectOverlay ~= nil then
					return
				end
				local curSnap = Store.GetSnapshot()
				local sig = computeSocialSignature(curSnap)
				if sig and sig ~= SocialRewards.LastSig then
					SocialRewards.LastSig = sig
					renderColumns(body, curSnap, root)
				end
			end)
		)
	end

	return root
end

function SocialRewards.Update(snap)
	snap = snap or Store.GetSnapshot()
	if SocialRewards.Refs.HeaderRefs and SocialRewards.Refs.HeaderRefs.UpdateCurrencies then
		SocialRewards.Refs.HeaderRefs.UpdateCurrencies(snap)
	end
	if not SocialRewards.Refs.Body or not SocialRewards.Refs.Body.Parent then
		return
	end
	refreshPlaytimeTileVisuals(snap)
	if SocialRewards.InspectOverlay ~= nil or UserInputService:GetFocusedTextBox() ~= nil then
		return
	end
	local sig = computeSocialSignature(snap)
	if sig and sig ~= SocialRewards.LastSig then
		SocialRewards.LastSig = sig
		renderColumns(SocialRewards.Refs.Body, snap, SocialRewards.Refs.Root)
	end
end

function SocialRewards.Cleanup()
	SocialRewards.PlaytimeTickerToken += 1
	SocialRewards.PlaytimeTileRefs = {}
	closeInspectOverlay()
	for _, conn in ipairs(SocialRewards.BustConnections) do
		if conn and conn.Disconnect then
			conn:Disconnect()
		end
	end
	SocialRewards.BustConnections = {}
	SocialRewards.LastSig = nil
	SocialRewards.Refs = {}
end

return SocialRewards
