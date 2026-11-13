-- SKYBREAK: Fragments of the Core - Wave 3 Social, Economy, Exploration, Co-op/PvP, Leaderboards & DevSandbox Service
-- Strictly UTF-8 LF, zero astral-plane emojis (>= 0x1F300).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local DevGate = require(script.Parent:WaitForChild("DevGate"))
local LiveOps = require(script.Parent:WaitForChild("SkybreakLiveOpsService"))
local Helpers = require(script.Parent:WaitForChild("GameExperienceHelpers"))

local SocialEconomy = {}
SocialEconomy._initialized = false

local G, D, W, C, R
local CombatData

local function applyGoldWithPass(p, prof, rawGold)
	local amt = math.max(0, math.floor(tonumber(rawGold) or 0))
	if amt <= 0 then
		return 0
	end
	local ownsGold = (prof and prof.OwnedGamePasses and prof.OwnedGamePasses.x2_gold == true)
		or (p and p:GetAttribute("OwnedPass_x2_gold") == true)
	return ownsGold and (amt * 2) or amt
end

local ALL_CANONICAL_FRUITS = {
	"GaleCore",
	"SandstoneCore",
	"SolarFlameCore",
	"GlacierIceCore",
	"CelestialLightCore",
	"StarforgedMagmaCore",
	"ThunderRumbleCore",
	"AstralGravityCore",
	"DimensionalPortalCore",
	"SolarTitanCore",
	"AetherflowCore",
	"AbyssalSovereignCore",
}

local MYTHICAL_FRUITS = {
	DimensionalPortalCore = true,
	SolarTitanCore = true,
	AetherflowCore = true,
	AbyssalSovereignCore = true,
	AstralGravityCore = true,
}

local ALL_FIGHTING_STYLES = {
	"skyborn_combat",
	"jade_dragon",
	"thunder_talon",
	"solar_ashura",
	"celestial_godhuman",
	"SkybornCombat",
	"SkyStep",
	"ElectricClaw",
	"GlacialKarate",
	"DragonTalon",
	"GodhumanSkyborn",
	"SanguineVoidArt",
	"ChronoVoidPalm",
}

local ALL_SWORDS_AND_GUNS = {
	"starter_sword",
	"starter_daggers",
	"starter_staff",
	"saber_of_aureon",
	"dawnbringer_sword",
	"cryon_frostblade",
	"cursed_dual_skyblades",
	"noxar_abyssal_greatsword",
	"yama_void_katana",
	"tushita_celestial_blade",
	"true_triple_skyblade",
	"pole_v2_thunder",
	"soul_cane_aether",
	"aether_flintlock",
	"kabucha_gale_slingshot",
	"serpent_bow_frost",
	"soul_guitar_void",
	"bizarre_rifle_cyber",
}

local ALL_HAKI_COLORS = {
	"crimson_conqueror",
	"solar_gold",
	"glacial_cyan",
	"void_amethyst",
	"emerald_gale",
	"starlight_white",
	"obsidian_eclipse",
	"rainbow_saviour",
}

local ENCHANT_DEFS = {
	{ Id = "Vampiric", Name = "Vampiric (Hút Máu 8%)", Desc = "Hồi phục HP bằng 8% sát thương gây ra trên mỗi đòn đánh." },
	{ Id = "ChronoHaste", Name = "ChronoHaste (-15% Hồi Chiêu)", Desc = "Giảm 15% thời gian hồi chiêu kỹ năng và tăng tốc độ ra đòn." },
	{ Id = "ChainVolt", Name = "ChainVolt (Lôi Điện Liên Hoàn)", Desc = "Phóng tia sét 35% sát thương lan sang 2 kẻ địch lân cận." },
	{ Id = "SolarCrit", Name = "SolarCrit (+12% Crit, +30% CritDMG)", Desc = "Tăng +12% Tỉ Lệ Chí Mạng và +30% Sát Thương Chí Mạng." },
	{ Id = "ArmorBreaker", Name = "ArmorBreaker (+22% Xuyên Giáp & Break)", Desc = "Xuyên thấu giáp, tăng +22% sát thương và +12 Break trên mỗi đòn." },
}

local ENCHANT_BY_ID = {}
for _, ed in ipairs(ENCHANT_DEFS) do
	ENCHANT_BY_ID[ed.Id] = ed
end

-- Master 21-Island Directory (Sea 1, Sea 2, Sea 3 & Realms 4-8)
local ISLAND_DIRECTORY = {
	{ Id = "SkyHub", Name = "Sky Hub Harbor", Realm = "GoldenSky", Pos = Vector3.new(-317.4, 50.5, 527.8) },
	{ Id = "GoldenSky", Name = "Aureon Lumen Plaza", Realm = "GoldenSky", Pos = Vector3.new(0, 50.5, 65) },
	{ Id = "ZiolesGachaShrine", Name = "Core Shrine", Realm = "GoldenSky", Pos = Vector3.new(-560, 52.5, 1028) },
	{ Id = "AetherShrines", Name = "Aether Home Shrine", Realm = "GoldenSky", Pos = Vector3.new(340, 52.5, 1024) },
	{ Id = "WestGarden", Name = "West Garden Pirate Bastion", Realm = "GoldenSky", Pos = Vector3.new(-2800, 50.5, -65) },
	{ Id = "SunshardSanctuary", Name = "Sunshard Sky Sanctuary", Realm = "GoldenSky", Pos = Vector3.new(2800, 50.5, -55) },
	{ Id = "FrozenCyber", Name = "Frozen Cyber Outpost", Realm = "FrozenCyber", Pos = Vector3.new(11620.5, 50.9, 534.8) },
	{ Id = "CyberportCafe", Name = "Trade Station Hub", Realm = "FrozenCyber", Pos = Vector3.new(9400, 50.9, 1785) },
	{ Id = "PermafrostGarrison", Name = "Permafrost Garrison", Realm = "FrozenCyber", Pos = Vector3.new(9400, 50.9, -2055) },
	{ Id = "MicrochipRaidLab", Name = "Microchip Awakening Raid Lab", Realm = "FrozenCyber", Pos = Vector3.new(14600, 50.9, 1785) },
	{ Id = "GlacialWreckage", Name = "Glacial Wreckage Danger Sea", Realm = "FrozenCyber", Pos = Vector3.new(14600, 50.9, -1812) },
	{ Id = "ShadowRealm", Name = "Shadow Realm Outpost", Realm = "ShadowRealm", Pos = Vector3.new(-12593.4, 50.9, 414) },
	{ Id = "CastleOnTheVoid", Name = "Void Bastion", Realm = "ShadowRealm", Pos = Vector3.new(-14600, 50.9, 2173.1) },
	{ Id = "UmbralSanctum", Name = "Umbral Crystal Sanctum", Realm = "ShadowRealm", Pos = Vector3.new(-9400, 50.9, 1815) },
	{ Id = "TempleOfTheCore", Name = "Ascension Shrine", Realm = "ShadowRealm", Pos = Vector3.new(-14600, 50.9, -1785) },
	{ Id = "LeviathanAbyss", Name = "Phantom Isle Outpost", Realm = "ShadowRealm", Pos = Vector3.new(-12000, 50.9, -3364.5) },
	{ Id = "VerdantCrown", Name = "The Verdant Crown", Realm = "VerdantCrown", Pos = Vector3.new(0, 170.9, -8985) },
	{ Id = "EmberforgeWastes", Name = "Emberforge Wastes", Realm = "EmberforgeWastes", Pos = Vector3.new(12000, 170.5, -9265) },
	{ Id = "AbyssalTides", Name = "Abyssal Tides", Realm = "AbyssalTides", Pos = Vector3.new(-12000, 170.9, -8964.5) },
	{ Id = "ChronosBastion", Name = "Chronos Bastion", Realm = "ChronosBastion", Pos = Vector3.new(0, 230.9, -13485) },
	{ Id = "VeilsEnd", Name = "The Veil's End", Realm = "VeilsEnd", Pos = Vector3.new(0, 310.9, -17626.9) },
}

local ISLAND_BY_ID = {}
for _, isl in ipairs(ISLAND_DIRECTORY) do
	ISLAND_BY_ID[isl.Id] = isl
	ISLAND_BY_ID[string.lower(isl.Id)] = isl
end
ISLAND_BY_ID.westgardenpiratebastion = ISLAND_BY_ID.WestGarden
ISLAND_BY_ID.sunshardskysanctuary = ISLAND_BY_ID.SunshardSanctuary
ISLAND_BY_ID.cyberportcafetradinghub = ISLAND_BY_ID.CyberportCafe
ISLAND_BY_ID.microchipawakeningraidlab = ISLAND_BY_ID.MicrochipRaidLab
ISLAND_BY_ID.glacialwreckagedangersea = ISLAND_BY_ID.GlacialWreckage
ISLAND_BY_ID.glacialdangersea = ISLAND_BY_ID.GlacialWreckage
ISLAND_BY_ID.castleonthevoidmansion = ISLAND_BY_ID.CastleOnTheVoid
ISLAND_BY_ID.umbralcrystalforest = ISLAND_BY_ID.UmbralSanctum
ISLAND_BY_ID.templeofthecoreracev4 = ISLAND_BY_ID.TempleOfTheCore

local SAFE_ZONES = {
	{ Name = "Sky Hub Sanctuary", Pos = Vector3.new(-317.4, 48, 527.8), Radius = 240 },
	{ Name = "Trade Station Safe Zone", Pos = Vector3.new(9400, 48, 1785), Radius = 220 },
	{ Name = "Void Bastion Safe Zone", Pos = Vector3.new(-14600, 48, 2173.1), Radius = 190 },
}

-- Viet hoa ho tro tieng Viet (string.upper chi doi chu ASCII: "Cảng" -> "CảNG").
local VI_UPPER_MAP = {}
do
	local lowerChars = "àáảãạăằắẳẵặâầấẩẫậèéẻẽẹêềếểễệìíỉĩịòóỏõọôồốổỗộơờớởỡợùúủũụưừứửữựỳýỷỹỵđ"
	local upperChars = "ÀÁẢÃẠĂẰẮẲẴẶÂẦẤẨẪẬÈÉẺẼẸÊỀẾỂỄỆÌÍỈĨỊÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢÙÚỦŨỤƯỪỨỬỮỰỲÝỶỸỴĐ"
	local ups = {}
	for _, cp in utf8.codes(upperChars) do
		table.insert(ups, utf8.char(cp))
	end
	local i = 0
	for _, cp in utf8.codes(lowerChars) do
		i += 1
		VI_UPPER_MAP[utf8.char(cp)] = ups[i]
	end
end
local function upperVi(text)
	return (string.gsub(string.upper(tostring(text or "")), utf8.charpattern, VI_UPPER_MAP))
end

local function root(p)
	local ch = p and p.Character
	if not ch then
		return nil, nil
	end
	local hrp = ch:FindFirstChild("HumanoidRootPart")
	local hum = ch:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then
		return nil, nil
	end
	return hrp, hum
end

local function dist(a, b)
	return (a - b).Magnitude
end

local function flatDist(a, b)
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function safeFloorY(pos, fallbackY)
	if W and W.RaycastGround then
		local hit = W.RaycastGround(pos + Vector3.new(0, 18, 0), fallbackY or (pos.Y - 3))
		if hit and hit.Position then
			return hit.Position.Y
		end
	end
	return fallbackY or pos.Y
end

local function getWorldObjects()
	local f = workspace:FindFirstChild("SkybreakWorldObjects")
	if not f then
		f = Instance.new("Folder")
		f.Name = "SkybreakWorldObjects"
		f.Parent = workspace
	end
	return f
end

local function getTempFX()
	local f = workspace:FindFirstChild("TempFX")
	if not f then
		f = Instance.new("Folder")
		f.Name = "TempFX"
		f.Parent = workspace
	end
	return f
end

local function countMapEntries(tbl)
	if type(tbl) ~= "table" then
		return 0
	end
	local n = 0
	for _, v in pairs(tbl) do
		if v then
			n += 1
		end
	end
	return n
end

-- ============================================================================
-- 38. #116 - SERVER-WIDE LUXURY ANNOUNCEMENT BANNER (WorldBanner)
-- ============================================================================
function SocialEconomy.BroadcastWorldBanner(title, subtitle, category)
	if R and R:FindFirstChild("StateUpdate") then
		R.StateUpdate:FireAllClients({
			WorldBanner = {
				Title = tostring(title or "THÔNG BÁO THẾ GIỚI"),
				Subtitle = tostring(subtitle or ""),
				Category = tostring(category or "Mythic"),
				Timestamp = workspace:GetServerTimeNow(),
			},
		})
	end
end

local function getSharedUIStateUpdatedRemote()
	local shared = ReplicatedStorage:FindFirstChild("SkybreakShared")
	local rems = shared and shared:FindFirstChild("Remotes")
	local ev = rems and rems:FindFirstChild("UIStateUpdated")
	if ev and ev:IsA("RemoteEvent") then
		return ev
	end
	return nil
end

local function ensureDiscoveredIslands(prof)
	if type(prof) ~= "table" then
		return { SkyHub = true, GoldenSky = true }
	end
	if type(prof.DiscoveredIslands) ~= "table" then
		prof.DiscoveredIslands = {}
	elseif #prof.DiscoveredIslands > 0 then
		local map = {}
		for k, v in pairs(prof.DiscoveredIslands) do
			if type(k) == "number" and type(v) == "string" then
				map[v] = true
			elseif v then
				map[tostring(k)] = true
			end
		end
		prof.DiscoveredIslands = map
	end
	prof.DiscoveredIslands.SkyHub = true
	prof.DiscoveredIslands.GoldenSky = true
	return prof.DiscoveredIslands
end

function SocialEconomy.CheckIslandDiscovery(p)
	if not p or p.Parent ~= Players then
		return false
	end
	local prof = D and D.Get(p)
	local pr = root(p)
	if not prof or not pr then
		return false
	end
	local discovered = ensureDiscoveredIslands(prof)
	local newlyFoundName = nil
	local newlyFoundAny = false

	local function checkList(list)
		for _, isl in ipairs(list or {}) do
			local iid = type(isl) == "table" and tostring(isl.Id or "") or ""
			local ipos = type(isl) == "table" and isl.Pos or nil
			if iid ~= "" and typeof(ipos) == "Vector3" and not discovered[iid] then
				if flatDist(pr.Position, ipos) <= 185 and math.abs(pr.Position.Y - ipos.Y) <= 95 then
					discovered[iid] = true
					newlyFoundAny = true
					newlyFoundName = newlyFoundName or tostring(isl.Name or iid)
				end
			end
		end
	end

	checkList(ISLAND_DIRECTORY)
	if C and type(C.Islands) == "table" then
		checkList(C.Islands)
	end

	if newlyFoundAny then
		if G and G.Notify and newlyFoundName then
			G.Notify(p, "Đã khám phá đảo mới: " .. newlyFoundName .. " — Mở khóa Dịch Chuyển Nhanh [M]!")
		end
		if D and D.Save then
			task.spawn(D.Save, p, false)
		end
		if SocialEconomy.PushSnapshotToPlayer then
			SocialEconomy.PushSnapshotToPlayer(p)
		end
		if G and G.Sync then
			G.Sync(p)
		end
		return true
	end
	return false
end

-- ============================================================================
-- 21. #62 - ISLAND HOME POINT CRYSTAL ANCHORS (SEA 1-3 & REALMS 4-8)
-- ============================================================================
local function buildHomePointCrystalAnchors()
	local folder = workspace:FindFirstChild("HomePointCrystals")
	if folder then
		folder:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = "HomePointCrystals"
	folder.Parent = workspace

	local anchorIslands = {
		{ Id = "SkyHub", Name = "Sky Hub", Realm = "GoldenSky", Pos = Vector3.new(-304.2, 46.5, 536.8) },
		{ Id = "GoldenSky", Name = "Aureon Lumen Plaza", Realm = "GoldenSky", Pos = Vector3.new(13.2, 46.5, 74.0) },
		{ Id = "ZiolesGachaShrine", Name = "Core Shrine", Realm = "GoldenSky", Pos = Vector3.new(-546.8, 48.5, 1037.0) },
		{ Id = "AetherShrines", Name = "Aether Home Shrine", Realm = "GoldenSky", Pos = Vector3.new(353.2, 48.5, 1033.0) },
		{ Id = "WestGarden", Name = "West Garden", Realm = "GoldenSky", Pos = Vector3.new(-2781.8, 46.5, -52.6) },
		{ Id = "SunshardSanctuary", Name = "Sunshard Sanctuary", Realm = "GoldenSky", Pos = Vector3.new(2818.2, 46.5, -42.6) },
		{ Id = "FrozenCyber", Name = "Frozen Cyber Dock", Realm = "FrozenCyber", Pos = Vector3.new(11633.7, 46.9, 543.8) },
		{ Id = "CyberportCafe", Name = "Trade Station", Realm = "FrozenCyber", Pos = Vector3.new(9409.5, 46.9, 1804.8) },
		{ Id = "PermafrostGarrison", Name = "Permafrost Garrison", Realm = "FrozenCyber", Pos = Vector3.new(9418.2, 46.9, -2042.6) },
		{ Id = "MicrochipRaidLab", Name = "Microchip Raid Lab", Realm = "FrozenCyber", Pos = Vector3.new(14618.2, 46.9, 1797.4) },
		{ Id = "GlacialWreckage", Name = "Glacial Wreckage", Realm = "FrozenCyber", Pos = Vector3.new(14618.2, 46.9, -1799.6) },
		{ Id = "ShadowRealm", Name = "Shadow Realm Dock", Realm = "ShadowRealm", Pos = Vector3.new(-12580.2, 46.9, 423.0) },
		{ Id = "CastleOnTheVoid", Name = "Void Bastion", Realm = "ShadowRealm", Pos = Vector3.new(-14595.9, 46.9, 2194.7) },
		{ Id = "UmbralSanctum", Name = "Umbral Sanctum", Realm = "ShadowRealm", Pos = Vector3.new(-9381.8, 46.9, 1827.4) },
		{ Id = "TempleOfTheCore", Name = "Ascension Shrine", Realm = "ShadowRealm", Pos = Vector3.new(-14581.8, 46.9, -1772.6) },
		{ Id = "LeviathanAbyss", Name = "Phantom Isle", Realm = "ShadowRealm", Pos = Vector3.new(-11981.8, 46.9, -3352.1) },
		{ Id = "VerdantCrown", Name = "Verdant Crown", Realm = "VerdantCrown", Pos = Vector3.new(-15.2, 166.9, -8980.0) },
		{ Id = "EmberforgeWastes", Name = "Emberforge Wastes", Realm = "EmberforgeWastes", Pos = Vector3.new(11984.8, 166.5, -9260.0) },
		{ Id = "AbyssalTides", Name = "Abyssal Tides", Realm = "AbyssalTides", Pos = Vector3.new(-12015.2, 166.9, -8959.5) },
		{ Id = "ChronosBastion", Name = "Chronos Bastion", Realm = "ChronosBastion", Pos = Vector3.new(-15.2, 226.9, -13480.0) },
		{ Id = "VeilsEnd", Name = "The Veil's End", Realm = "VeilsEnd", Pos = Vector3.new(-15.2, 306.9, -17621.9) },
	}

	for _, sp in ipairs(anchorIslands) do
		local fy = safeFloorY(sp.Pos, sp.Pos.Y)
		local cpos = Vector3.new(sp.Pos.X, fy, sp.Pos.Z)
		local m = Instance.new("Model")
		m.Name = "HomePointCrystal_" .. sp.Id
		m:SetAttribute("IslandId", sp.Id)
		m.Parent = folder

		local ped = W.Part(m, "ObeliskBase", Vector3.new(3.2, 1.0, 3.2), cpos + Vector3.new(0, 0.5, 0), Color3.fromRGB(44, 52, 72), Enum.Material.Slate)
		local crystal = W.Part(m, "CrystalShard", Vector3.new(1.5, 4.4, 1.5), cpos + Vector3.new(0, 3.1, 0), Color3.fromRGB(92, 236, 255), Enum.Material.Neon)
		crystal.Transparency = 0.35
		crystal.CanCollide = false
		m.PrimaryPart = ped

		local bill = Instance.new("BillboardGui")
		bill.Size = UDim2.fromScale(3.8, 0.72)
		bill.StudsOffset = Vector3.new(0, 3.8, 0)
		bill.AlwaysOnTop = false
		bill.MaxDistance = 48
		bill.Parent = crystal
		local tl = Instance.new("TextLabel")
		tl.Size = UDim2.fromScale(1, 1)
		tl.BackgroundTransparency = 1
		tl.Font = Enum.Font.GothamBlack
		tl.TextScaled = true
		tl.TextColor3 = Color3.fromRGB(112, 244, 255)
		tl.TextStrokeTransparency = 0.18
		tl.Text = "HOME POINT • " .. upperVi(sp.Name)
		tl.Parent = bill

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Lưu Điểm Hồi Sinh Home Point"
		prompt.ObjectText = "Home Point Crystal • " .. sp.Name
		prompt.MaxActivationDistance = 14
		prompt.HoldDuration = 0
		prompt.RequiresLineOfSight = false
		prompt.Parent = ped
		prompt.Triggered:Connect(function(plr)
			local prof = D.Get(plr)
			local rt = G.Runtime[plr]
			local _, h = root(plr)
			if not prof or not rt then
				return
			end
			local discovered = ensureDiscoveredIslands(prof)
			local wasNew = not discovered[sp.Id]
			discovered[sp.Id] = true
			if sp.Realm and sp.Realm ~= "" then
				discovered[sp.Realm] = true
			end
			prof.HomeIsland = sp.Id
			rt.CustomRespawnPos = cpos + Vector3.new(0, 3.2, 0)
			plr:SetAttribute("RespawnPos", cpos)
			plr:SetAttribute("RespawnRealm", sp.Realm)
			if h then
				h.Health = h.MaxHealth
			end
			rt.Stamina = 100
			if wasNew then
				G.Notify(plr, "Đã khám phá đảo mới: " .. sp.Name .. " — Mở khóa Dịch Chuyển Nhanh [M]!")
			end
			G.Notify(plr, "HOME POINT CRYSTAL: Đã lưu điểm hồi sinh tại [" .. sp.Name .. "] & hồi phục 100% HP!")
			if D and D.Save then
				task.spawn(D.Save, plr, false)
			end
			if SocialEconomy.PushSnapshotToPlayer then
				SocialEconomy.PushSnapshotToPlayer(plr)
			end
			G.Sync(plr)
		end)
	end
end

-- ============================================================================
-- 22. #67 - 30 COLLECTIBLE LORE TABLETS & CORE FRAGMENTS ACROSS SEA 1/2/3
-- ============================================================================
local LORE_SNIPPETS = {
	"Mảnh Lõi #01: Trước Ngày Vỡ Tan, Biệt Đội Skyborn canh giữ Lõi Thái Dương giữa tầng mây vĩnh cửu.",
	"Mảnh Lõi #02: Aureon Sentinel được đúc từ ánh sáng thuần khiết để phong ấn Khe Nứt Hư Không.",
	"Mảnh Lõi #03: Hiền Giả Lõi lưu giữ 12 Lõi Aether cổ đại kết tinh từ linh hồn các vì sao rơi.",
	"Mảnh Lõi #04: Điện Thờ Aether kết nối mạch năng lượng giữa 20 quần đảo trên Biển Mây.",
	"Mảnh Lõi #05: Hải Tặc West Garden từng tìm thấy bản vẽ Chiến Hạm Celestial Galleon đầu tiên.",
	"Mảnh Lõi #06: Thánh Địa Sunshard là nơi Kael rèn thành thần kiếm Dawnbringer huyền thoại.",
	"Mảnh Lõi #07: Khi Lõi Vỡ Tan, Lãnh Địa Frozen Cyber bị đóng băng trong bão tuyết lượng tử.",
	"Mảnh Lõi #08: Cryon Prime dựng 3 Cột Băng Vĩnh Cửu để giam cầm thời gian tại Pháo Đài Băng.",
	"Mảnh Lõi #09: Trạm Giao Thương trở thành trung tâm trao đổi tự do của cả Hải Quân lẫn Hải Tặc.",
	"Mảnh Lõi #10: Pháo Đài Permafrost cất giữ công thức cường hóa vũ khí +15 không bao giờ xịt.",
	"Mảnh Lõi #11: Dr. Vega phát minh Microchip Thức Tỉnh V2 tại Phòng Thí Nghiệm Tầng Trời 2.",
	"Mảnh Lõi #12: Dưới Xác Tàu Glacial Wreckage, bầy Cá Mập Trời Terror Sky-Shark rình rập mọi con thuyền.",
	"Mảnh Lõi #13: Vượt qua Danger Level 6, Đảo Hư Quang chỉ hiện ra cho kẻ mang dòng máu Thăng Hoa.",
	"Mảnh Lõi #14: Blue Resonance Gear là chìa khóa duy nhất mở phong ấn Sức Mạnh Thăng Hoa.",
	"Mảnh Lõi #15: Tầng Trời 3 Shadow Realm chìm trong hoàng hôn tím thẫm kể từ khi Noxar chiếm Ngai Vàng.",
	"Mảnh Lõi #16: 4 Trụ Ánh Sáng Thanh Tẩy là di vật cuối cùng có thể xóa tan Lõi Hư Không Noxar.",
	"Mảnh Lõi #17: Tại Pháo Đài Hư Không, 3 Ngọn Đuốc Linh Hồn vẫn đợi kẻ đủ can đảm gọi Void Harbinger.",
	"Mảnh Lõi #18: Rừng Tinh Thể Umbral ẩn chứa bi kịch của Kiếm Thánh rèn Song Kiếm Nguyệt Thực.",
	"Mảnh Lõi #19: Đền Thăng Hoa lưu giữ 6 Huyết Mạch Thượng Cổ của bầu trời.",
	"Mảnh Lõi #20: Thủy Xà Vực Thẳm mang trái tim bất diệt — chỉ dây cáp Harpoon mới kéo được về cảng.",
	"Mảnh Lõi #21: Vương Miện Cổ Thụ Verdant Crown mọc lên từ hạt giống sinh mệnh đầu tiên của Bầu Trời.",
	"Mảnh Lõi #22: Lò Rèn Lửa Emberforge dùng dung nham sao băng để tôi luyện Giáp Ý Chí Bậc 5.",
	"Mảnh Lõi #23: Thủy Triều Vực Sâu Abyssal Tides giao thoa giữa Biển Mây và Đại Dương Cổ Đại.",
	"Mảnh Lõi #24: Chronos Bastion là pháo đài nằm ngoài dòng chảy thời gian của Đại Giám Hộ Chronos.",
	"Mảnh Lõi #25: Tận Cùng Bức Màn Veil's End là nơi Veyr canh giữ mảnh Lõi Tối Thượng cuối cùng.",
	"Mảnh Lõi #26: Tháp Vô Tận Sky Spire gồm 50 tầng thử thách dành cho những Chiến Binh Vượt Giới Hạn.",
	"Mảnh Lõi #27: Người sở hữu Thấu Ý V2 có thể nhìn thấu đẳng cấp và sức mạnh của mọi đối thủ.",
	"Mảnh Lõi #28: Phù Phép Enchantment Scroll khắc cổ ngữ Vampiric và ChainVolt trực tiếp lên lưỡi kiếm.",
	"Mảnh Lõi #29: Khi 30 Bia Cổ Lore hội tụ, tri thức của Kiến Trúc Sư Bầu Trời sẽ thức tỉnh trọn vẹn.",
	"Mảnh Lõi #30: SKYBREAK — Những Mảnh Lõi Vỡ Tan nay đã sẵn sàng cho Chủ Nhân Mới của Thiên Giới!",
}

local LORE_TABLET_SPOTS = {
	[1] = Vector3.new(-322.0, 46.5, 547.3), -- SkyHub
	[2] = Vector3.new(-13.3, 46.5, 79.9), -- GoldenSky
	[3] = Vector3.new(-572.9, 48.5, 1043.3), -- ZiolesGachaShrine
	[4] = Vector3.new(345.5, 48.5, 1004.8), -- AetherShrines
	[5] = Vector3.new(-2819.8, 46.5, -62.2), -- WestGarden
	[6] = Vector3.new(2794.1, 46.5, -74.1), -- SunshardSanctuary
	[7] = Vector3.new(11619.2, 46.9, 514.8), -- FrozenCyber
	[8] = Vector3.new(9437.8, 46.9, 1781.4), -- CyberportCafe
	[9] = Vector3.new(9388.0, 46.9, -2071.0), -- PermafrostGarrison
	[10] = Vector3.new(14615.6, 46.9, 1772.5), -- MicrochipRaidLab
	[11] = Vector3.new(14580.5, 46.9, -1816.3), -- GlacialWreckage
	[12] = Vector3.new(-12576.9, 46.9, 402.7), -- ShadowRealm
	[13] = Vector3.new(-14638.0, 46.9, 2172.1), -- CastleOnTheVoid
	[14] = Vector3.new(-9418.5, 46.9, 1807.4), -- UmbralSanctum
	[15] = Vector3.new(-14625.9, 46.9, -1787.7), -- TempleOfTheCore
	[16] = Vector3.new(-11982.0, 46.9, -3373.2), -- LeviathanAbyss
	[17] = Vector3.new(6.1, 166.9, -9004.1), -- VerdantCrown
	[18] = Vector3.new(12005.5, 166.5, -9284.2), -- EmberforgeWastes
	[19] = Vector3.new(-12016.0, 166.9, -8976.5), -- AbyssalTides
	[20] = Vector3.new(25.6, 226.9, -13489.4), -- ChronosBastion
	[21] = Vector3.new(11.1, 306.9, -17643.5), -- VeilsEnd
	[22] = Vector3.new(-292.1, 46.5, 522.0), -- SkyHub
	[23] = Vector3.new(-20.0, 46.5, 64.8), -- GoldenSky
	[24] = Vector3.new(-590.7, 48.5, 1036.9), -- ZiolesGachaShrine
	[25] = Vector3.new(322.2, 48.5, 1014.8), -- AetherShrines
	[26] = Vector3.new(-2798.9, 46.5, -85.0), -- WestGarden
	[27] = Vector3.new(2810.5, 46.5, -72.0), -- SunshardSanctuary
	[28] = Vector3.new(11639.0, 46.9, 527.1), -- FrozenCyber
	[29] = Vector3.new(9379.1, 46.9, 1823.7), -- CyberportCafe
	[30] = Vector3.new(9406.6, 46.9, -2073.9), -- PermafrostGarrison
}

local function collectExistingClearancePoints()
	local pts = {}
	local function addContainer(container)
		if not container then
			return
		end
		for _, child in ipairs(container:GetChildren()) do
			if child:IsA("Model") then
				local okPiv, piv = pcall(child.GetPivot, child)
				if okPiv and piv then
					table.insert(pts, piv.Position)
				elseif child.PrimaryPart then
					table.insert(pts, child.PrimaryPart.Position)
				end
				local holo = child:FindFirstChild("HoloTradeTable")
				if holo and holo:IsA("BasePart") then
					table.insert(pts, holo.Position)
				end
			elseif child:IsA("BasePart") then
				table.insert(pts, child.Position)
			end
		end
	end

	for _, fname in ipairs({
		"HomePointCrystals",
		"SkybreakWorldObjects",
		"SkybreakChests",
		"QuickQuestBoards",
		"NPCs",
		"ActiveNPCs",
		"Shrines",
		"WorldPortals",
		"WorldObjects",
	}) do
		addContainer(workspace:FindFirstChild(fname))
	end
	local expWorld = workspace:FindFirstChild("SkybreakExpansionWorld")
	if expWorld then
		for _, sub in ipairs(expWorld:GetChildren()) do
			addContainer(sub)
		end
	end
	for _, vmPos in ipairs({
		Vector3.new(-331.7, 46.9, 520.7),
		Vector3.new(2780.3, 46.9, -64.7),
		Vector3.new(-574.3, 48.9, 1020.9),
		Vector3.new(9420.8, 47.3, 1777.9),
		Vector3.new(11606.2, 47.3, 527.7),
		Vector3.new(-14607.1, 47.3, 2152.3),
		Vector3.new(-12607.7, 47.3, 406.9),
		Vector3.new(8.9, 227.3, -13498.3),
	}) do
		table.insert(pts, vmPos)
	end
	return pts
end

local function isLoreCandidateClear(candPos, islPos, occupiedPts, minClearance)
	if flatDist(candPos, islPos) < 10.0 then
		return false
	end
	for _, pt in ipairs(occupiedPts) do
		if math.abs(pt.Y - candPos.Y) <= 18.0 and flatDist(candPos, pt) < minClearance then
			return false
		end
	end
	if W and type(W.IsBlockedByObstacle) == "function" and W.IsBlockedByObstacle(candPos + Vector3.new(0, 1.5, 0), 1.6) then
		return false
	end
	return true
end

local function resolveClearLorePos(isl, idx, occupiedPts)
	local pre = LORE_TABLET_SPOTS[idx]
	if pre then
		local pfy = safeFloorY(pre, isl.Pos.Y - 3)
		local pCand = Vector3.new(pre.X, pfy, pre.Z)
		if math.abs(pfy - isl.Pos.Y) <= 10.0 and isLoreCandidateClear(pCand, isl.Pos, occupiedPts, 15.2) then
			return pCand, pfy
		end
	end

	local radii = { 18, 24, 30, 36, 42, 48, 54, 62 }
	local angleSteps = 28
	local seedAng = idx * 1.15
	for _, rad in ipairs(radii) do
		for step = 0, angleSteps - 1 do
			local ang = seedAng + (2 * math.pi * step / angleSteps)
			local testXZ = Vector3.new(isl.Pos.X + math.cos(ang) * rad, isl.Pos.Y, isl.Pos.Z + math.sin(ang) * rad)
			local fy = safeFloorY(testXZ, -999)
			if fy > 10 and math.abs(fy - isl.Pos.Y) <= 10.0 then
				local cand = Vector3.new(testXZ.X, fy, testXZ.Z)
				if isLoreCandidateClear(cand, isl.Pos, occupiedPts, 15.2) then
					return cand, fy
				end
			end
		end
	end

	local fallback = pre or (isl.Pos + Vector3.new(22, 0, 0))
	local ffy = safeFloorY(fallback, isl.Pos.Y - 3)
	return Vector3.new(fallback.X, ffy, fallback.Z), ffy
end

local function build30LoreTablets()
	local folder = workspace:FindFirstChild("SkybreakLoreTablets")
	if folder then
		folder:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = "SkybreakLoreTablets"
	folder.Parent = workspace

	local occupiedPts = collectExistingClearancePoints()

	for idx = 1, 30 do
		local isl = ISLAND_DIRECTORY[((idx - 1) % #ISLAND_DIRECTORY) + 1]
		local rawPos, fy = resolveClearLorePos(isl, idx, occupiedPts)
		table.insert(occupiedPts, rawPos)
		local tId = string.format("LoreTablet_%02d", idx)

		local m = Instance.new("Model")
		m.Name = tId
		m:SetAttribute("LoreId", tId)
		m:SetAttribute("LoreIndex", idx)
		m.Parent = folder

		local lookTarget = Vector3.new(isl.Pos.X, fy + 0.35, isl.Pos.Z)
		local basePos = Vector3.new(rawPos.X, fy + 0.35, rawPos.Z)
		local slabPos = Vector3.new(rawPos.X, fy + 2.1, rawPos.Z)
		local base = W.Part(m, "TabletBase", Vector3.new(2.2, 0.7, 1.6), basePos, Color3.fromRGB(48, 56, 78), Enum.Material.Slate)
		local slab = W.Part(m, "LoreCrystal", Vector3.new(1.7, 3.0, 0.55), slabPos, Color3.fromRGB(95, 234, 255), Enum.Material.Neon)
		if flatDist(basePos, lookTarget) > 0.5 then
			base.CFrame = CFrame.lookAt(basePos, lookTarget)
			slab.CFrame = CFrame.lookAt(slabPos, Vector3.new(isl.Pos.X, slabPos.Y, isl.Pos.Z))
		end
		slab.Transparency = 0.35
		slab.CanCollide = false
		m.PrimaryPart = base

		local bill = Instance.new("BillboardGui")
		bill.Size = UDim2.fromScale(3.4, 0.65)
		bill.StudsOffset = Vector3.new(0, 2.8, 0)
		bill.AlwaysOnTop = false
		bill.MaxDistance = 42
		bill.Parent = slab
		local tl = Instance.new("TextLabel")
		tl.Size = UDim2.fromScale(1, 1)
		tl.BackgroundTransparency = 1
		tl.Font = Enum.Font.GothamBold
		tl.TextScaled = true
		tl.TextColor3 = Color3.fromRGB(255, 224, 118)
		tl.TextStrokeTransparency = 0.2
		tl.Text = string.format("BIA CỔ LORE #%02d/30", idx)
		tl.Parent = bill

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Đọc & Thu Thập Bia Cổ Lore"
		prompt.ObjectText = string.format("Lore Tablet #%02d • %s", idx, isl.Name)
		prompt.MaxActivationDistance = 13
		prompt.HoldDuration = 0
		prompt.RequiresLineOfSight = false
		prompt.Parent = base

		prompt.Triggered:Connect(function(plr)
			local prof = D.Get(plr)
			if not prof then
				return
			end
			prof.CollectedLore = type(prof.CollectedLore) == "table" and prof.CollectedLore or {}
			local snippet = LORE_SNIPPETS[idx] or LORE_SNIPPETS[1]
			if prof.CollectedLore[tId] then
				G.SendDialogue(plr, string.format("Bia Cổ Skybreak #%02d/30", idx), isl.Name, snippet .. " (Đã thu thập)", "Đóng", "")
				return
			end

			prof.CollectedLore[tId] = true
			local total = countMapEntries(prof.CollectedLore)
			local xpGain = math.max(1200, (prof.Level or 1) * 85)
			G.Reward(plr, xpGain, 1500, 150)
			SocialEconomy.AdvanceDailyTask(plr, "Explore", 1)

			local milestoneNote = ""
			if total == 10 then
				prof.CoreShards = (prof.CoreShards or 0) + 500
				prof.UnlockedTitles["skyborn_scholar"] = true
				milestoneNote = " • MỐC 10/30: +500 Shards & Danh hiệu [Học Giả Thiên Không]!"
			elseif total == 20 then
				prof.CoreShards = (prof.CoreShards or 0) + 1200
				prof.UnlockedTitles["core_archivist"] = true
				milestoneNote = " • MỐC 20/30: +1,200 Shards & Danh hiệu [Sử Quan Mảnh Lõi]!"
			elseif total == 30 then
				prof.CoreShards = (prof.CoreShards or 0) + 3000
				prof.UnlockedTitles["omniscient_chronicler"] = true
				prof.Title = "omniscient_chronicler"
				milestoneNote = " • HOÀN TẤT 30/30 BIA CỔ: +3,000 Shards & Danh hiệu [Đại Học Giả Toàn Tri]!"
				SocialEconomy.BroadcastWorldBanner(
					"ĐẠI HỌC GIẢ 30/30 BIA CỔ SKYBREAK!",
					plr.Name .. " đã giải mã trọn bộ 30 Bia Cổ Lore & Mảnh Lõi khắp 3 Đại Hải Trình!",
					"Lore30"
				)
			end

			G.SendDialogue(
				plr,
				string.format("Bia Cổ Skybreak #%02d/30 (Đã thu thập %d/30)", idx, total),
				"BÍ SỬ THIÊN GIỚI • " .. upperVi(isl.Name),
				snippet .. "\nPhần thưởng: +150 Core Shards, +1,500 Gold!" .. milestoneNote,
				"Tiếp Tục Thám Hiểm",
				""
			)
			SocialEconomy.CheckMilestones(plr, prof)
			G.Sync(plr)
		end)
	end
end

-- ============================================================================
-- 23. #68 - DESTRUCTIBLE 3D WORLD PROPS (CRATES, CRYSTALS, PILLARS - 45s)
-- ============================================================================
local DestructiblePropsList = {}

local function buildDestructibleWorldProps()
	local folder = workspace:FindFirstChild("DestructibleProps")
	if folder then
		folder:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = "DestructibleProps"
	folder.Parent = workspace
	DestructiblePropsList = {}

	local propSpots = {
		{ Kind = "Crate", Pos = Vector3.new(-308, 48.0, 224) },
		{ Kind = "Crystal", Pos = Vector3.new(-324, 48.0, 198) },
		{ Kind = "Pillar", Pos = Vector3.new(-30, 48.0, 50) },
		{ Kind = "Crate", Pos = Vector3.new(30, 48.0, 48) },
		{ Kind = "Crystal", Pos = Vector3.new(-24, 48.0, -295) },
		{ Kind = "Pillar", Pos = Vector3.new(24, 48.0, -295) },
		{ Kind = "Crystal", Pos = Vector3.new(-568, 50.0, 974) },
		{ Kind = "Crate", Pos = Vector3.new(-2786, 48.0, -76) },
		{ Kind = "Crystal", Pos = Vector3.new(2786, 48.0, -64) },
		{ Kind = "Crate", Pos = Vector3.new(11665, 48.4, 232) },
		{ Kind = "Crystal", Pos = Vector3.new(11982, 48.4, 64) },
		{ Kind = "Pillar", Pos = Vector3.new(12018, 48.4, 46) },
		{ Kind = "Crystal", Pos = Vector3.new(9388, 48.4, -2064) },
		{ Kind = "Crate", Pos = Vector3.new(14588, 48.4, 1775) },
		{ Kind = "Crate", Pos = Vector3.new(-12580, 48.4, 402) },
		{ Kind = "Crystal", Pos = Vector3.new(-11970, 48.4, 114) },
		{ Kind = "Pillar", Pos = Vector3.new(-14588, 48.4, 2162) },
		{ Kind = "Crystal", Pos = Vector3.new(-9388, 48.4, 1806) },
	}

	for idx, sp in ipairs(propSpots) do
		local fy = safeFloorY(sp.Pos, sp.Pos.Y - 1.5)
		local m = Instance.new("Model")
		m.Name = sp.Kind .. "Prop_" .. idx
		m:SetAttribute("PropKind", sp.Kind)
		m.Parent = folder

		local size = (sp.Kind == "Crate") and Vector3.new(2.8, 2.8, 2.8)
			or ((sp.Kind == "Crystal") and Vector3.new(2.2, 4.2, 2.2) or Vector3.new(2.4, 5.0, 2.4))
		local col = (sp.Kind == "Crate") and Color3.fromRGB(168, 118, 64)
			or ((sp.Kind == "Crystal") and Color3.fromRGB(88, 232, 255) or Color3.fromRGB(148, 152, 168))
		local mat = (sp.Kind == "Crate") and Enum.Material.WoodPlanks
			or ((sp.Kind == "Crystal") and Enum.Material.Neon or Enum.Material.Slate)

		local part = W.Part(m, "PropBody", size, Vector3.new(sp.Pos.X, fy + size.Y * 0.5, sp.Pos.Z), col, mat)
		if sp.Kind == "Crystal" then
			part.Transparency = 0.35
		end
		m.PrimaryPart = part

		table.insert(DestructiblePropsList, {
			Model = m,
			Part = part,
			Kind = sp.Kind,
			Color = col,
			BaseTransparency = (sp.Kind == "Crystal") and 0.35 or 0,
			Pos = part.Position,
			BrokenUntil = 0,
		})
	end
end

function SocialEconomy.OnCombatAoE(p, centerPos, radius)
	if not p or typeof(centerPos) ~= "Vector3" then
		return
	end
	local now = os.clock()
	local hitRadius = math.max(8, tonumber(radius) or 13)
	local prof = D.Get(p)
	local shatteredCount = 0

	for _, prop in ipairs(DestructiblePropsList) do
		if now >= prop.BrokenUntil and prop.Part and prop.Part.Parent and dist(centerPos, prop.Pos) <= hitRadius then
			prop.BrokenUntil = now + 45.0
			prop.Part.CanCollide = false
			prop.Part.Transparency = 1
			shatteredCount += 1

			for s = 1, 3 do
				local shard = Instance.new("Part")
				shard.Name = "PropShard"
				shard.Size = Vector3.new(0.8, 0.8, 0.8)
				shard.Position = prop.Pos + Vector3.new(math.random(-1, 1), 0.6 + s * 0.3, math.random(-1, 1))
				shard.Color = prop.Color
				shard.Material = Enum.Material.SmoothPlastic
				shard.CanCollide = false
				shard.Anchored = false
				shard.AssemblyLinearVelocity = Vector3.new(math.random(-12, 12), math.random(12, 22), math.random(-12, 12))
				shard.Parent = getTempFX()
				Debris:AddItem(shard, 1.1)
			end

			local propRef = prop
			task.delay(45.0, function()
				if propRef.Part and propRef.Part.Parent then
					propRef.Part.Transparency = propRef.BaseTransparency
					propRef.Part.CanCollide = true
				end
			end)
		end
	end

	if shatteredCount > 0 and prof then
		local goldGain = applyGoldWithPass(p, prof, shatteredCount * 140)
		prof.Gold = (prof.Gold or 0) + goldGain
		prof.Inventory = prof.Inventory or {}
		prof.Inventory.SkyIron = (prof.Inventory.SkyIron or 0) + shatteredCount
		G.FireCombatEvent({
			kind = "DamageNumber",
			pos = centerPos + Vector3.new(0, 2, 0),
			amount = goldGain,
			crit = false,
			element = "Sky",
			Text = "+" .. tostring(goldGain) .. " GOLD • +" .. tostring(shatteredCount) .. " SKY IRON",
		})
	end
end

-- ============================================================================
-- 24. #69 - AETHER SKY-RAILS LIGHT-RAIL GRINDING BETWEEN SKY ISLANDS
-- ============================================================================
local SkyRailRoutes = {}

local function sampleQuadraticBezier(p0, p1, p2, t)
	local u = 1 - t
	return (p0 * (u * u)) + (p1 * (2 * u * t)) + (p2 * (t * t))
end


-- ============================================================================
-- 25 & 26. #101 SMOOTH LV.1->2550 CURVE & #102 FAIR >=15% SHARED BOSS CREDIT
-- ============================================================================
function SocialEconomy.GetSmoothProgressionMultiplier(level)
	local _ = level
	return 1.0, 1.0
end

-- ============================================================================
-- 27. #103 - ENCHANTMENT SCROLLS (VAMPIRIC, CHRONOHASTE, CHAINVOLT, SOLARCRIT, ARMORBREAKER)
-- ============================================================================
function SocialEconomy.EnchantEquippedWeapon(p, targetWeaponId)
	local prof = D.Get(p)
	if not prof then
		return false
	end
	local weaponId = tostring(targetWeaponId or prof.Weapon or (prof.Equipped and prof.Equipped.Weapon) or "starter_sword")
	if weaponId == "" then
		G.Notify(p, "Hãy trang bị Vũ Khí trước khi Phù Phép Enchant!")
		return false
	end

	prof.Inventory = prof.Inventory or {}
	prof.WeaponEnchants = type(prof.WeaponEnchants) == "table" and prof.WeaponEnchants or {}

	local hasScroll = (prof.Inventory.EnchantScroll or 0) > 0
	if hasScroll then
		prof.Inventory.EnchantScroll -= 1
	elseif (prof.CoreShards or 0) >= 120 then
		prof.CoreShards -= 120
	else
		G.Notify(p, "Cần 1 Enchant Scroll (hoặc 120 Core Shards) để Phù Phép Vũ Khí!")
		return false
	end

	local curEnchant = prof.WeaponEnchants[weaponId]
	local pool = {}
	for _, ed in ipairs(ENCHANT_DEFS) do
		if ed.Id ~= curEnchant then
			table.insert(pool, ed)
		end
	end
	local chosen = (#pool > 0 and pool[math.random(1, #pool)]) or ENCHANT_DEFS[1]
	prof.WeaponEnchants[weaponId] = chosen.Id
	p:SetAttribute("LastWeaponEnchant", chosen.Id)
	local eqWid = tostring(prof.Weapon or (prof.Equipped and prof.Equipped.Weapon) or "starter_sword")
	if weaponId == eqWid then
		p:SetAttribute("ActiveWeaponEnchant", chosen.Id)
	end

	local wName = (C.Items[weaponId] and C.Items[weaponId].Name) or weaponId
	G.Notify(p, "PHÙ PHÉP THÀNH CÔNG: [" .. wName .. "] nhận được Enchant [" .. chosen.Name .. "]!")
	SocialEconomy.CheckMilestones(p, prof)
	G.Sync(p)
	return true
end

local function buildArcaneEnchanterPedestal()
	local worldObjects = getWorldObjects()
	local old = worldObjects:FindFirstChild("ArcaneEnchanterPedestal_SkyHub")
	if old then
		old:Destroy()
	end

	local raw = Vector3.new(-262.8, 46.5, 525.3)
	local fy = safeFloorY(raw, 46.5)
	local m = Instance.new("Model")
	m.Name = "ArcaneEnchanterPedestal_SkyHub"
	m.Parent = worldObjects

	local ped = W.Part(m, "EnchanterAltar", Vector3.new(3.6, 2.4, 3.6), Vector3.new(raw.X, fy + 1.2, raw.Z), Color3.fromRGB(46, 36, 72), Enum.Material.Marble)
	local rune = W.Part(m, "EnchantScrollOrb", Vector3.new(1.8, 1.8, 1.8), Vector3.new(raw.X, fy + 3.4, raw.Z), Color3.fromRGB(192, 108, 255), Enum.Material.Neon)
	rune.Shape = Enum.PartType.Ball
	rune.Transparency = 0.36
	rune.CanCollide = false
	m.PrimaryPart = ped

	local bill = Instance.new("BillboardGui")
	bill.Size = UDim2.fromScale(4.2, 0.8)
	bill.StudsOffset = Vector3.new(0, 3.4, 0)
	bill.AlwaysOnTop = false
	bill.MaxDistance = 48
	bill.Parent = rune
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamBlack
	tl.TextScaled = true
	tl.TextColor3 = Color3.fromRGB(218, 138, 255)
	tl.TextStrokeTransparency = 0.18
	tl.Text = "ĐÀI PHÙ PHÉP ENCHANT VŨ KHÍ [E]"
	tl.Parent = bill

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Mở Đài Phù Phép Cổ Ngữ 3D"
	prompt.ObjectText = "Arcane Enchanter • Vampiric / ChainVolt / SolarCrit"
	prompt.MaxActivationDistance = 14
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.Parent = ped
	prompt.Triggered:Connect(function(plr)
		G.SendDialogue(
			plr,
			"Pháp Sư Phù Phép Cổ Ngữ",
			"ĐÀI PHÙ PHÉP ENCHANT VŨ KHÍ",
			"Khắc ấn cổ ngữ Vampiric, ChainVolt, SolarCrit lên vũ khí 3D của ngươi bằng Cuộn Phù Phép hoặc Core Shards!",
			"Mở Đài Phù Phép Cổ Ngữ",
			"OpenScreen:NPCShop:Enchanter"
		)
	end)
end

-- ============================================================================
-- 28. #105 - 4-TIER 3D TREASURE CHESTS (BRONZE / SILVER / GOLDEN / VOID)
-- ============================================================================
local CHEST_TIERS = {
	[1] = { Name = "Rương Đồng (Tier 1)", Gold = 550, Shards = 35, ScrollChance = 0.15, BodyCol = Color3.fromRGB(168, 106, 58), TrimCol = Color3.fromRGB(214, 152, 92) },
	[2] = { Name = "Rương Bạc (Tier 2)", Gold = 1450, Shards = 75, ScrollChance = 0.30, BodyCol = Color3.fromRGB(172, 184, 204), TrimCol = Color3.fromRGB(110, 226, 255) },
	[3] = { Name = "Rương Hoàng Kim (Tier 3)", Gold = 3600, Shards = 150, ScrollChance = 0.55, BodyCol = Color3.fromRGB(238, 188, 62), TrimCol = Color3.fromRGB(255, 238, 132) },
	[4] = { Name = "Rương Hư Không (Tier 4)", Gold = 8500, Shards = 320, ScrollChance = 1.00, BodyCol = Color3.fromRGB(58, 34, 88), TrimCol = Color3.fromRGB(206, 96, 255) },
}

local function build4TierTreasureChests()
	local folder = workspace:FindFirstChild("SkybreakChests")
	if folder then
		folder:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = "SkybreakChests"
	folder.Parent = workspace

	local placements = {
		{ Pos = Vector3.new(-314.4, 47.5, 512.1), Tier = 1 },
		{ Pos = Vector3.new(-307.9, 47.5, 195.6), Tier = 1 },
		{ Pos = Vector3.new(8.9, 47.5, 51.7), Tier = 2 },
		{ Pos = Vector3.new(11.3, 48.6, -191.3), Tier = 3 },
		{ Pos = Vector3.new(-546.6, 49.5, 1019.2), Tier = 2 },
		{ Pos = Vector3.new(-2779.6, 47.5, -73.2), Tier = 2 },
		{ Pos = Vector3.new(2821.6, 47.5, -59.0), Tier = 3 },
		{ Pos = Vector3.new(11618.1, 47.9, 550.6), Tier = 2 },
		{ Pos = Vector3.new(11691.3, 47.9, 227.6), Tier = 2 },
		{ Pos = Vector3.new(12014.6, 47.9, 126.5), Tier = 3 },
		{ Pos = Vector3.new(9392.4, 47.9, 1805.6), Tier = 2 },
		{ Pos = Vector3.new(9378.1, 47.9, -2052.8), Tier = 3 },
		{ Pos = Vector3.new(14603.5, 47.9, 1806.7), Tier = 3 },
		{ Pos = Vector3.new(14582.0, 47.9, -1799.3), Tier = 4 },
		{ Pos = Vector3.new(-12593.8, 47.9, 398.0), Tier = 3 },
		{ Pos = Vector3.new(-12594.1, 47.9, 476.0), Tier = 3 },
		{ Pos = Vector3.new(-14613.6, 47.9, 2197.6), Tier = 4 },
		{ Pos = Vector3.new(-9412.0, 47.9, 1833.4), Tier = 3 },
		{ Pos = Vector3.new(-14617.3, 47.9, -1771.5), Tier = 4 },
		{ Pos = Vector3.new(-12016.5, 47.9, -3349.9), Tier = 4 },
	}

	for idx, cp in ipairs(placements) do
		local tier = cp.Tier
		local spec = CHEST_TIERS[tier]
		local fy = safeFloorY(cp.Pos, cp.Pos.Y - 1.2)
		local cpos = Vector3.new(cp.Pos.X, fy, cp.Pos.Z)
		local cid = string.format("SkyChest_T%d_%02d", tier, idx)

		local m = Instance.new("Model")
		m.Name = cid
		m:SetAttribute("ChestTier", tier)
		m:SetAttribute("OpenedUntil", 0)
		m.Parent = folder

		local box = W.Part(m, "ChestBox", Vector3.new(3.4, 1.8, 2.3), cpos + Vector3.new(0, 0.9, 0), spec.BodyCol, Enum.Material.Metal)
		local lid = W.Part(m, "ChestLid", Vector3.new(3.5, 0.7, 2.4), cpos + Vector3.new(0, 2.05, 0), spec.TrimCol, Enum.Material.Metal)
		local lock = W.Part(m, "ChestCoreLock", Vector3.new(0.65, 0.75, 0.35), cpos + Vector3.new(0, 1.65, -1.2), spec.TrimCol, Enum.Material.Neon)
		lock.Transparency = 0.35
		lock.CanCollide = false
		m.PrimaryPart = box

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Mở " .. spec.Name
		prompt.ObjectText = string.format("+%d Gold • +%d Shards", spec.Gold, spec.Shards)
		prompt.MaxActivationDistance = 13
		prompt.HoldDuration = 0
		prompt.RequiresLineOfSight = false
		prompt.Parent = box

		local openedUntil = 0
		prompt.Triggered:Connect(function(plr)
			local now = os.clock()
			if now < openedUntil then
				G.Notify(plr, spec.Name .. " đang kết tinh lại kho báu (" .. math.ceil(openedUntil - now) .. "s)!")
				return
			end
			local prof = D.Get(plr)
			if not prof then
				return
			end
			openedUntil = now + 55
			local serverEnds = workspace:GetServerTimeNow() + 55
			m:SetAttribute("OpenedUntil", serverEnds)
			box:SetAttribute("OpenedUntil", serverEnds)
			lid.Transparency = 0.65
			lock.Transparency = 0.9

			task.delay(55, function()
				if m.Parent then
					m:SetAttribute("OpenedUntil", 0)
					if box.Parent then
						box:SetAttribute("OpenedUntil", 0)
					end
					lid.Transparency = 0
					lock.Transparency = 0.35
				end
			end)

			local chestGold = applyGoldWithPass(plr, prof, spec.Gold)
			prof.Gold = (prof.Gold or 0) + chestGold
			prof.CoreShards = (prof.CoreShards or 0) + spec.Shards
			prof.Inventory = prof.Inventory or {}
			local gotScroll = (math.random() <= spec.ScrollChance)
			if gotScroll then
				prof.Inventory.EnchantScroll = (prof.Inventory.EnchantScroll or 0) + 1
			end

			if R and R:FindFirstChild("CombatFX") then
				R.CombatFX:FireAllClients({
					Kind = "ChestOpened",
					Position = box.Position,
					Tier = tier,
					Gold = chestGold,
					Actor = plr.UserId,
				})
			end

			SocialEconomy.AdvanceDailyTask(plr, "Explore", 1)
			G.Notify(plr, string.format("MỞ %s: +%d Gold, +%d Core Shards%s!", upperVi(spec.Name), chestGold, spec.Shards, gotScroll and ", +1 Enchant Scroll" or ""))
			G.Sync(plr)
		end)
	end
end


-- ============================================================================
-- 29. #106 - 7-DAY LOGIN STREAK & AUTO-REFRESHING DAILY TASKS
-- ============================================================================
local LOGIN_STREAK_REWARDS = {
	[1] = { Gold = 25000, Shards = 0, Label = "Ngày 1: +25,000 Gold", LabelEn = "Day 1: +25,000 Gold" },
	[2] = { Gold = 0, Shards = 150, Label = "Ngày 2: +150 Tinh Thạch", LabelEn = "Day 2: +150 Core Shards" },
	[3] = { Gold = 0, Shards = 0, FruitVoucher = 1, Label = "Ngày 3: +1 Vé Quay Lõi Miễn Phí", LabelEn = "Day 3: +1 Free Core Spin Voucher" },
	[4] = { Gold = 0, Shards = 0, DoubleExpSec = 1800, Label = "Ngày 4: +30 Phút x2 EXP", LabelEn = "Day 4: +30m 2x EXP" },
	[5] = { Gold = 0, Shards = 100, Scroll = 1, Label = "Ngày 5: +1 Bùa Cổ Ngữ & +100 Tinh Thạch", LabelEn = "Day 5: +1 Rune Scroll & +100 Shards" },
	[6] = { Gold = 0, Shards = 500, Label = "Ngày 6: +500 Tinh Thạch", LabelEn = "Day 6: +500 Core Shards" },
	[7] = { Gold = 0, Shards = 0, RarePlusCore = true, Label = "Ngày 7: Lõi Aether Hiếm+ Ngẫu Nhiên", LabelEn = "Day 7: Random Rare+ Aether Core" },
}

local function buildFreshDailyTaskList()
	return {
		{ Id = "Kill25", Kind = "Kill", Title = "Tiêu Diệt 25 Kẻ Địch", Progress = 0, Count = 25, Goal = 25, Gold = 2500, Shards = 120, Claimed = false },
		{ Id = "Boss1", Kind = "Boss", Title = "Hạ Gục 1 Boss Khu Vực", Progress = 0, Count = 1, Goal = 1, Gold = 5000, Shards = 250, Claimed = false },
		{ Id = "Explore2", Kind = "Explore", Title = "Mở 2 Rương Kho Báu hoặc Bia Cổ Ngữ", Progress = 0, Count = 2, Goal = 2, Gold = 2000, Shards = 110, Claimed = false },
	}
end

local function grantStreakTierReward(p, prof, dayTier, isAutoWelcome)
	local rw = LOGIN_STREAK_REWARDS[math.clamp(tonumber(dayTier) or 1, 1, 7)]
	if (rw.Gold or 0) > 0 then
		prof.Gold = (prof.Gold or 0) + applyGoldWithPass(p, prof, rw.Gold)
	end
	if (rw.Shards or 0) > 0 then
		prof.CoreShards = (prof.CoreShards or 0) + rw.Shards
	end
	prof.Inventory = prof.Inventory or {}
	if rw.Scroll then
		prof.Inventory.EnchantScroll = (prof.Inventory.EnchantScroll or 0) + rw.Scroll
	end
	if rw.FruitVoucher then
		prof.FreeFruitVouchers = (prof.FreeFruitVouchers or 0) + rw.FruitVoucher
	end
	if rw.DoubleExpSec then
		prof.DoubleExpRemainingSec = math.max(0, tonumber(prof.DoubleExpRemainingSec) or 0) + rw.DoubleExpSec
		prof.DoubleExpUntil = os.time() + prof.DoubleExpRemainingSec
		if p then
			p:SetAttribute("DoubleExpSeconds", prof.DoubleExpRemainingSec)
		end
	end
	local extraVi, extraEn = rw.Label, rw.LabelEn
	if rw.RarePlusCore then
		local rolled = (C.RollRarePlusFruit and C.RollRarePlusFruit()) or "SolarFlameCore"
		local canStore = Helpers.CanStoreCore(p, prof, rolled)
		if canStore then
			prof.StoredFruits = type(prof.StoredFruits) == "table" and prof.StoredFruits or {}
			prof.StoredFruits[rolled] = (tonumber(prof.StoredFruits[rolled]) or 0) + 1
			prof.HeldFruit = rolled
			LiveOps.AwardBadge(G, p, prof, "first_aether_core")
			local fName = (C.AetherFruits and C.AetherFruits[rolled] and C.AetherFruits[rolled].Name) or rolled
			extraVi = "Ngày 7: Nhận Lõi Aether Hiếm+ [" .. tostring(fName) .. "]"
			extraEn = "Day 7: Received Rare+ Core [" .. tostring(rolled) .. "]"
		else
			prof.FreeFruitVouchers = (tonumber(prof.FreeFruitVouchers) or 0) + 1
			extraVi = "Ngày 7: Kho Lõi đầy -> +1 Vé Quay Lõi Miễn Phí"
			extraEn = "Day 7: Core Storage full -> +1 Free Core Spin Voucher"
		end
	end
	if p and G and G.Notify then
		if isAutoWelcome then
			LiveOps.Notify(G, p, "QUÀ CHÀO MỪNG SKYBORN: " .. extraVi .. "!", "WELCOME GIFT: " .. extraEn .. "!")
		else
			LiveOps.Notify(G, p, "ĐIỂM DANH 7 NGÀY (" .. extraVi .. ")!", "7-DAY LOGIN (" .. extraEn .. ")!")
		end
	end
end

local function getProfileLastDailyClaimDay(prof)
	if type(prof) ~= "table" then
		return 0
	end
	return math.max(tonumber(prof.LastDailyClaimDay) or 0, tonumber(prof.DailyClaimedDay) or 0)
end

local function ensureDailyState(p, prof)
	if not prof then
		return
	end
	local today = math.floor(os.time() / 86400)
	local lastDay = tonumber(prof.LastLoginDay) or 0
	if lastDay <= 0 then
		prof.LoginStreak = 1
		prof.LastLoginDay = today
		prof.DailyClaimed = tonumber(prof.DailyClaimed) or 0
	elseif lastDay < today then
		if (today - lastDay) == 1 then
			prof.LoginStreak = ((tonumber(prof.LoginStreak) or 1) % 7) + 1
		else
			prof.LoginStreak = 1
		end
		prof.LastLoginDay = today
	end
	prof.LoginStreak = math.clamp(tonumber(prof.LoginStreak) or 1, 1, 7)

	local prevClaimed = getProfileLastDailyClaimDay(prof)
	if prevClaimed > 0 then
		prof.LastDailyClaimDay = prevClaimed
		prof.DailyClaimedDay = prevClaimed
	end

	if type(prof.DailyTasks) ~= "table" or tonumber(prof.DailyTasks.Day) ~= today or type(prof.DailyTasks.List) ~= "table" or #prof.DailyTasks.List < 3 then
		prof.DailyTasks = {
			Day = today,
			List = buildFreshDailyTaskList(),
			BonusClaimed = false,
		}
	else
		for _, item in ipairs(prof.DailyTasks.List) do
			if type(item) == "table" then
				local goal = math.max(1, math.floor(tonumber(item.Goal or item.Count) or 1))
				item.Goal = goal
				item.Count = goal
				item.Progress = math.clamp(math.floor(tonumber(item.Progress) or 0), 0, goal)
			end
		end
	end
end

function SocialEconomy.AdvanceDailyTask(p, kind, amount)
	local prof = D and D.Get(p)
	if not prof then
		return
	end
	ensureDailyState(p, prof)
	local inc = math.max(1, math.floor(tonumber(amount) or 1))
	local changed = false
	for _, taskItem in ipairs(prof.DailyTasks.List) do
		if taskItem.Kind == kind and not taskItem.Claimed then
			local goal = math.max(1, tonumber(taskItem.Goal or taskItem.Count) or 1)
			local prev = tonumber(taskItem.Progress) or 0
			local nextVal = math.min(goal, prev + inc)
			if nextVal ~= prev then
				taskItem.Progress = nextVal
				changed = true
				if nextVal >= goal and not taskItem.ReadyNotified then
					taskItem.ReadyNotified = true
					LiveOps.Notify(G, p, "NHIỆM VỤ HẰNG NGÀY HOÀN TẤT: [" .. taskItem.Title .. "]! Hãy nhận thưởng!", "DAILY TASK COMPLETE: [" .. taskItem.Title .. "]! Claim your reward!")
				end
			end
		end
	end
	if changed then
		if SocialEconomy.PushSnapshotToPlayer then
			SocialEconomy.PushSnapshotToPlayer(p)
		end
		G.Sync(p)
	end
end

function SocialEconomy.ClaimBountyReward(p, payload)
	local prof = D and D.Get(p)
	if not prof then
		return false
	end
	ensureDailyState(p, prof)
	local targetId = ""
	local targetIdx = nil
	if type(payload) == "table" then
		targetId = tostring(payload.bountyId or payload.taskId or payload.id or payload.kind or payload.value or "")
		targetIdx = tonumber(payload.index or payload.slot)
	elseif type(payload) == "number" then
		targetIdx = math.floor(payload)
	else
		targetId = tostring(payload or "")
	end

	local claimedAny = false
	local allDone = true
	for idx, taskItem in ipairs(prof.DailyTasks.List) do
		local goal = math.max(1, tonumber(taskItem.Goal or taskItem.Count) or 1)
		local matches = (targetId == "" or targetId == "All" or targetId == taskItem.Id or targetId == taskItem.Kind or (targetIdx ~= nil and targetIdx == idx) or targetId == ("Bounty_" .. idx))
		if matches and not taskItem.Claimed and (tonumber(taskItem.Progress) or 0) >= goal then
			taskItem.Claimed = true
			local gAmt = applyGoldWithPass(p, prof, tonumber(taskItem.Gold) or 2500)
			prof.Gold = (prof.Gold or 0) + gAmt
			prof.CoreShards = (prof.CoreShards or 0) + (tonumber(taskItem.Shards) or 120)
			claimedAny = true
			LiveOps.Notify(G, p, string.format("NHẬN THƯỞNG HẰNG NGÀY [%s]: +%d Gold, +%d Core Shards!", taskItem.Title, gAmt, taskItem.Shards), string.format("CLAIMED DAILY TASK [%s]: +%d Gold, +%d Core Shards!", taskItem.Id, gAmt, taskItem.Shards))
		end
		if not taskItem.Claimed then
			allDone = false
		end
	end

	if allDone and not prof.DailyTasks.BonusClaimed then
		prof.DailyTasks.BonusClaimed = true
		prof.Inventory = prof.Inventory or {}
		prof.Inventory.EnchantScroll = (prof.Inventory.EnchantScroll or 0) + 1
		prof.CoreShards = (prof.CoreShards or 0) + 200
		claimedAny = true
		LiveOps.Notify(G, p, "HOÀN TẤT TRỌN BỘ 3 NHIỆM VỤ HẰNG NGÀY: +1 Enchant Scroll & +200 Core Shards!", "ALL 3 DAILY TASKS COMPLETE: +1 Rune Scroll & +200 Core Shards!")
	end

	if not claimedAny then
		LiveOps.Notify(G, p, "Nhiệm vụ Hằng Ngày chưa hoàn tất hoặc đã nhận thưởng!", "Daily Task is incomplete or already claimed!")
		return false
	end
	if D and D.Save then
		task.spawn(D.Save, p, false)
	end
	if SocialEconomy.PushSnapshotToPlayer then
		SocialEconomy.PushSnapshotToPlayer(p)
	end
	G.Sync(p)
	return true
end

function SocialEconomy.ClaimDailyReward(p, payload)
	local prof = D and D.Get(p)
	if not prof then
		return false
	end
	ensureDailyState(p, prof)
	local today = math.floor(os.time() / 86400)
	local targetId = type(payload) == "table" and tostring(payload.bountyId or payload.taskId or payload.id or payload.kind or payload.value or "") or tostring(payload or "")
	local claimedDay = getProfileLastDailyClaimDay(prof)

	local claimedAnything = false
	if (targetId == "" or targetId == "Login" or targetId == "Streak" or targetId == "DailyLogin" or targetId == "All") and claimedDay ~= today then
		prof.LastDailyClaimDay = today
		prof.DailyClaimedDay = today
		prof.DailyClaimed = prof.LoginStreak
		grantStreakTierReward(p, prof, prof.LoginStreak, false)
		claimedAnything = true
	end

	local allDone = true
	for idx, taskItem in ipairs(prof.DailyTasks.List) do
		local goal = math.max(1, tonumber(taskItem.Goal or taskItem.Count) or 1)
		if (targetId == "" or targetId == "All" or targetId == taskItem.Id or targetId == taskItem.Kind or targetId == ("Bounty_" .. idx)) and not taskItem.Claimed and (tonumber(taskItem.Progress) or 0) >= goal then
			taskItem.Claimed = true
			local gAmt = applyGoldWithPass(p, prof, taskItem.Gold)
			prof.Gold = (prof.Gold or 0) + gAmt
			prof.CoreShards = (prof.CoreShards or 0) + taskItem.Shards
			claimedAnything = true
			LiveOps.Notify(G, p, string.format("NHẬN THƯỞNG DAILY [%s]: +%d Gold, +%d Core Shards!", taskItem.Title, gAmt, taskItem.Shards), string.format("CLAIMED DAILY [%s]: +%d Gold, +%d Core Shards!", taskItem.Id, gAmt, taskItem.Shards))
		end
		if not taskItem.Claimed then
			allDone = false
		end
	end

	if allDone and not prof.DailyTasks.BonusClaimed then
		prof.DailyTasks.BonusClaimed = true
		prof.Inventory = prof.Inventory or {}
		prof.Inventory.EnchantScroll = (prof.Inventory.EnchantScroll or 0) + 1
		prof.CoreShards = (prof.CoreShards or 0) + 200
		claimedAnything = true
		LiveOps.Notify(G, p, "HOÀN TẤT TRỌN BỘ 3 NHIỆM VỤ HẰNG NGÀY: +1 Enchant Scroll & +200 Core Shards!", "ALL 3 DAILY TASKS COMPLETE: +1 Rune Scroll & +200 Core Shards!")
	end

	if not claimedAnything then
		LiveOps.Notify(G, p, "Bạn đã nhận quà Điểm Danh hôm nay hoặc chưa hoàn tất Nhiệm Vụ Hằng Ngày!", "Today's Login Gift is already claimed or Daily Tasks are incomplete!")
		return false
	end
	if D and D.Save then
		task.spawn(D.Save, p, false)
	end
	if SocialEconomy.PushSnapshotToPlayer then
		SocialEconomy.PushSnapshotToPlayer(p)
	end
	G.Sync(p)
	return true
end

-- ============================================================================
-- 30. #107 - AUTO-REWARDING MILESTONES & ACHIEVEMENTS (16+ MILESTONES)
-- ============================================================================
local MILESTONE_DEFS = {
	{
		Id = "Lv100",
		Name = "Tân Binh Thiên Không (Lv.100)",
		Gold = 5000,
		Shards = 180,
		TitleId = "sky_vanguard",
		Check = function(prof) return (tonumber(prof.Level) or 1) >= 100 end,
	},
	{
		Id = "Lv700",
		Name = "Chinh Phục Tầng Mây Thứ Nhất (Lv.700)",
		Gold = 18000,
		Shards = 450,
		TitleId = "golden_conqueror",
		Check = function(prof) return (tonumber(prof.Level) or 1) >= 700 end,
	},
	{
		Id = "Lv1500",
		Name = "Bá Chủ Băng Giá Cyber (Lv.1500)",
		Gold = 45000,
		Shards = 900,
		TitleId = "cyber_overlord",
		Check = function(prof) return (tonumber(prof.Level) or 1) >= 1500 end,
	},
	{
		Id = "Lv2550",
		Name = "Đỉnh Cao Thiên Không Tối Thượng (Lv.2550)",
		Gold = 120000,
		Shards = 2500,
		TitleId = "skybreak_sovereign",
		Check = function(prof) return (tonumber(prof.Level) or 1) >= 2550 end,
	},
	{
		Id = "FirstAwakenedFruit",
		Name = "Lõi Thức Tỉnh V2 Đầu Tiên",
		Gold = 15000,
		Shards = 500,
		TitleId = "awakened_core",
		Check = function(prof) return countMapEntries(prof.AwakenedFruits) >= 1 end,
	},
	{
		Id = "First5StarSword",
		Name = "Thần Binh Ngũ Tinh (5-Star Weapon)",
		Gold = 25000,
		Shards = 650,
		TitleId = "starforged_master",
		Check = function(prof)
			for _, st in pairs(prof.WeaponStars or {}) do
				if (tonumber(st) or 0) >= 5 then
					return true
				end
			end
			return false
		end,
	},
	{
		Id = "FirstEnchant",
		Name = "Nghệ Nhân Phù Phép Cổ Ngữ",
		Gold = 8000,
		Shards = 220,
		TitleId = "arcane_enchanter",
		Check = function(prof) return countMapEntries(prof.WeaponEnchants) >= 1 end,
	},
	{
		Id = "Enhance15",
		Name = "Tuyệt Đỉnh Cường Hóa (+15)",
		Gold = 35000,
		Shards = 800,
		TitleId = "forge_grandmaster",
		Check = function(prof) return (tonumber(prof.WeaponEnhance) or 0) >= 15 end,
	},
	{
		Id = "Bounty3M",
		Name = "Danh Vọng Thiên Hà (3,000,000 Điểm Danh Vọng)",
		Gold = 14000,
		Shards = 350,
		TitleId = "warlord_of_clouds",
		Check = function(prof) return math.max(tonumber(prof.Bounty) or 0, tonumber(prof.Honor) or 0) >= 3000000 end,
	},
	{
		Id = "Bounty10M",
		Name = "Tứ Hoàng Biển Mây (10,000,000 Điểm Danh Vọng)",
		Gold = 65000,
		Shards = 1500,
		TitleId = "emperor_of_the_sky",
		Check = function(prof) return math.max(tonumber(prof.Bounty) or 0, tonumber(prof.Honor) or 0) >= 10000000 end,
	},
	{
		Id = "Lore10",
		Name = "Học Giả Thiên Không (10 Bia Cổ Ngữ)",
		Gold = 12000,
		Shards = 320,
		TitleId = "lore_seeker",
		Check = function(prof) return countMapEntries(prof.CollectedLore) >= 10 end,
	},
	{
		Id = "Lore30",
		Name = "Hiền Triết Lõi Sáng Thế (Trọn Bộ 30 Bia Cổ Ngữ)",
		Gold = 50000,
		Shards = 1400,
		TitleId = "chronicler_of_aether",
		Check = function(prof) return countMapEntries(prof.CollectedLore) >= 30 end,
	},
	{
		Id = "Spire10",
		Name = "Chinh Phục Tháp Vô Tận Tầng 10",
		Gold = 16000,
		Shards = 420,
		TitleId = "spire_challenger",
		Check = function(prof) return (tonumber(prof.HighestSpireFloor) or 0) >= 10 end,
	},
	{
		Id = "Spire50",
		Name = "Thiên Đỉnh Vô Cực (Tầng 50 Sky Spire)",
		Gold = 90000,
		Shards = 2200,
		TitleId = "apex_of_the_spire",
		Check = function(prof) return (tonumber(prof.HighestSpireFloor) or 0) >= 50 end,
	},
	{
		Id = "LeviathanSlayer",
		Name = "Thợ Săn Trái Tim Thủy Xà",
		Gold = 40000,
		Shards = 1100,
		TitleId = "leviathan_slayer",
		Check = function(prof) return (tonumber(prof.LeviathanHearts) or 0) >= 1 or (prof.Inventory and (tonumber(prof.Inventory.LeviathanHeart) or 0) >= 1) end,
	},
	{
		Id = "CrewFounder",
		Name = "Thuyền Trưởng Hạm Đội Sky Crew",
		Gold = 7500,
		Shards = 200,
		TitleId = "fleet_commander",
		Check = function(prof) return type(prof.CrewName) == "string" and #prof.CrewName >= 2 end,
	},
	{
		Id = "HakiStage5",
		Name = "Giáp Ý Chí Toàn Thân (Stage 5)",
		Gold = 28000,
		Shards = 750,
		TitleId = "haki_grandmaster",
		Check = function(prof) return (tonumber(prof.HakiStage) or 0) >= 5 end,
	},
}

function SocialEconomy.CheckMilestones(p, prof)
	prof = prof or (D and D.Get(p))
	if not prof then
		return false
	end
	prof.Achievements = type(prof.Achievements) == "table" and prof.Achievements or {}
	prof.UnlockedTitles = type(prof.UnlockedTitles) == "table" and prof.UnlockedTitles or { sky_rookie = true }

	local unlockedAny = false
	for _, m in ipairs(MILESTONE_DEFS) do
		if not prof.Achievements[m.Id] and m.Check(prof) then
			prof.Achievements[m.Id] = true
			local mGold = applyGoldWithPass(p, prof, m.Gold)
			prof.Gold = (prof.Gold or 0) + mGold
			prof.CoreShards = (prof.CoreShards or 0) + m.Shards
			if m.TitleId then
				prof.UnlockedTitles[m.TitleId] = true
			end
			unlockedAny = true
			if p then
				local tDisp = (CombatData and CombatData.Titles and m.TitleId and CombatData.Titles[m.TitleId] and CombatData.Titles[m.TitleId].Name) or tostring(m.TitleId)
				G.Notify(p, string.format("THÀNH TỰU MỚI [%s]: +%d Gold, +%d Core Shards & Danh Hiệu [%s]!", m.Name, mGold, m.Shards, tDisp))
				if R and R:FindFirstChild("StateUpdate") then
					R.StateUpdate:FireClient(p, {
						AchievementUnlocked = {
							Id = m.Id,
							Name = m.Name,
							Gold = mGold,
							Shards = m.Shards,
							TitleId = m.TitleId,
						},
					})
				end
			end
		end
	end
	return unlockedAny
end

-- ============================================================================
-- 31. #108 - WANDERING VOID MERCHANT (10-MINUTE ISLAND ROTATION)
-- ============================================================================
local VOID_MERCHANT_STOPS = {
	{ Id = "SkyHub", Name = "Sky Hub Plaza", Realm = "GoldenSky", Pos = Vector3.new(-331.7, 46.9, 520.7), LookAt = Vector3.new(-317.4, 46.9, 527.8) },
	{ Id = "SunshardSanctuary", Name = "Sunshard Sanctuary", Realm = "GoldenSky", Pos = Vector3.new(2780.3, 46.9, -64.7), LookAt = Vector3.new(2800.0, 46.9, -55.0) },
	{ Id = "ZiolesGachaShrine", Name = "Core Shrine", Realm = "GoldenSky", Pos = Vector3.new(-574.3, 48.9, 1020.9), LookAt = Vector3.new(-560.0, 48.9, 1028.0) },
	{ Id = "CyberportCafe", Name = "Trade Station", Realm = "FrozenCyber", Pos = Vector3.new(9420.8, 47.3, 1777.9), LookAt = Vector3.new(9400.0, 47.3, 1785.0) },
	{ Id = "FrozenOutpost", Name = "Frozen Outpost", Realm = "FrozenCyber", Pos = Vector3.new(11606.2, 47.3, 527.7), LookAt = Vector3.new(11620.5, 47.3, 534.8) },
	{ Id = "CastleOnTheVoid", Name = "Void Bastion", Realm = "ShadowRealm", Pos = Vector3.new(-14607.1, 47.3, 2152.3), LookAt = Vector3.new(-14600.0, 47.3, 2173.1) },
	{ Id = "ShadowCitadel", Name = "Shadow Citadel", Realm = "ShadowRealm", Pos = Vector3.new(-12607.7, 47.3, 406.9), LookAt = Vector3.new(-12593.4, 47.3, 414.0) },
	{ Id = "ChronosBastion", Name = "Chronos Bastion", Realm = "ChronosBastion", Pos = Vector3.new(8.9, 227.3, -13498.3), LookAt = Vector3.new(0.0, 227.3, -13485.0) },
}

local VOID_MERCHANT_STOCK = {
	EnchantScroll = { Id = "EnchantScroll", Name = "Enchant Scroll (Cuộn Phù Phép)", Shards = 95, Gold = 12000, Count = 1 },
	CoreEssence = { Id = "CoreEssence", Name = "Core Essence x2", Shards = 140, Gold = 18000, Count = 2 },
	SunshardCore = { Id = "SunshardCore", Name = "Sunshard Core x5", Shards = 110, Gold = 14000, Count = 5 },
	RandomFruitBox = { Id = "RandomFruitBox", Name = "Hộp Lõi Aether Bí Ẩn (Hiếm+)", Shards = 250, Gold = 150000, PriceGold = 150000, PriceShards = 250, DualCost = true, Count = 1 },
	aion_chrono_cloak = {
		Id = "aion_chrono_cloak",
		Name = "Áo Choàng Thời Không Aion (Aion Chrono Cloak)",
		Shards = 1500,
		Gold = 1250000,
		PriceGold = 1250000,
		PriceShards = 1500,
		DualCost = true,
		Count = 1,
	},
}
local VOID_STOCK_ORDER = { "EnchantScroll", "CoreEssence", "SunshardCore", "RandomFruitBox", "aion_chrono_cloak" }

local ActiveVoidMerchant = {
	Model = nil,
	StopIndex = 0,
	Stop = nil,
	ExpiresAt = 0,
	SpawnSerial = 0,
	BoxBuyers = {},
}

function SocialEconomy.BuyVoidMerchantItem(p, itemId, currency, autoEquip)
	local prof = D and D.Get(p)
	if not prof then
		return false
	end
	local rt = G and G.Runtime and G.Runtime[p]
	local now = os.clock()
	if rt then
		if now < (rt.Cooldowns.VoidMerchantBuy or 0) then
			return false
		end
		rt.Cooldowns.VoidMerchantBuy = now + 0.4
	end
	local mModel = ActiveVoidMerchant.Model
	if not mModel or not mModel.Parent or workspace:GetServerTimeNow() >= (tonumber(ActiveVoidMerchant.ExpiresAt) or 0) then
		LiveOps.Notify(G, p, "Thương Nhân Hư Không Chronos hiện chưa xuất hiện hoặc đã rời đi!", "Wandering Void Merchant Chronos is not currently active!")
		return false
	end
	local pr = root(p)
	local mPos = (mModel.PrimaryPart and mModel.PrimaryPart.Position) or mModel:GetPivot().Position
	if not pr or (pr.Position - mPos).Magnitude > 35 then
		LiveOps.Notify(G, p, "Hãy đến đứng gần Thương Nhân Hư Không Chronos (<= 35m) để giao dịch!", "Stand within 35 studs of Void Merchant Chronos to purchase!")
		return false
	end

	local reqKey = tostring(itemId or "EnchantScroll")
	local stock = VOID_MERCHANT_STOCK[reqKey]
	if not stock then
		LiveOps.Notify(G, p, "Vật phẩm [" .. reqKey .. "] không có trong sạp Thương Nhân Hư Không!", "Item [" .. reqKey .. "] is not sold by Chronos!")
		return false
	end

	local rolledBoxCore = nil
	if stock.Id == "RandomFruitBox" then
		ActiveVoidMerchant.BoxBuyers = ActiveVoidMerchant.BoxBuyers or {}
		if ActiveVoidMerchant.BoxBuyers[p.UserId] then
			LiveOps.Notify(G, p, "Mỗi đợt Chronos xuất hiện chỉ được mua tối đa 1 Hộp Lõi Aether Bí Ẩn!", "Limit 1 Mystery Aether Core Box per Chronos appearance!")
			return false
		end
		for _ = 1, 10 do
			local cand = (C.RollRarePlusFruit and C.RollRarePlusFruit()) or "SolarFlameCore"
			if Helpers.CanStoreCore(p, prof, cand) then
				rolledBoxCore = cand
				break
			end
		end
		if not rolledBoxCore then
			local maxCap = Helpers.GetMaxCoreStorage(p, prof)
			LiveOps.Notify(G, p, string.format("Kho Lõi Aether Hiếm+ đã đầy (%d/%d)! Không thể mua Hộp Bí Ẩn!", maxCap, maxCap), string.format("Rare+ Core Storage is full (%d/%d)! Cannot buy Mystery Box!", maxCap, maxCap))
			return false
		end
	end

	if stock.DualCost then
		local curGold = tonumber(prof.Gold) or 0
		local curShards = tonumber(prof.CoreShards) or 0
		if curGold < stock.Gold or curShards < stock.Shards then
			LiveOps.Notify(G, p, string.format("Cần đủ %d Gold VÀ %d Tinh Thạch để mua %s!", stock.Gold, stock.Shards, stock.Name), string.format("Requires %d Gold AND %d Core Shards to buy %s!", stock.Gold, stock.Shards, stock.Id))
			return false
		end
		prof.Gold = curGold - stock.Gold
		prof.CoreShards = curShards - stock.Shards
	else
		local payGold = (tostring(currency or "") == "Gold")
		if not payGold and (prof.CoreShards or 0) >= stock.Shards then
			prof.CoreShards -= stock.Shards
		elseif (prof.Gold or 0) >= stock.Gold then
			prof.Gold -= stock.Gold
		elseif (prof.CoreShards or 0) >= stock.Shards then
			prof.CoreShards -= stock.Shards
		else
			LiveOps.Notify(G, p, string.format("Cần %d Tinh Thạch (hoặc %d Gold) để mua %s!", stock.Shards, stock.Gold, stock.Name), string.format("Requires %d Core Shards (or %d Gold) to buy %s!", stock.Shards, stock.Gold, stock.Id))
			return false
		end
	end

	prof.Inventory = prof.Inventory or {}
	if stock.Id == "RandomFruitBox" then
		local fid = rolledBoxCore or "SolarFlameCore"
		ActiveVoidMerchant.BoxBuyers[p.UserId] = true
		prof.StoredFruits = prof.StoredFruits or {}
		prof.StoredFruits[fid] = (prof.StoredFruits[fid] or 0) + 1
		prof.HeldFruit = fid
		LiveOps.AwardBadge(G, p, prof, "first_aether_core")
		local fName = (C.AetherFruits and C.AetherFruits[fid] and C.AetherFruits[fid].Name) or (C.Fruits and C.Fruits[fid] and C.Fruits[fid].Name) or fid
		LiveOps.Notify(G, p, "THƯƠNG NHÂN HƯ KHÔNG: Mở Hộp Bí Ẩn nhận được Lõi Aether Hiếm+ [" .. fName .. "]!", "VOID MERCHANT: Mystery Box granted Rare+ Aether Core [" .. fid .. "]!")
		if MYTHICAL_FRUITS[fid] then
			SocialEconomy.BroadcastWorldBanner(
				"THƯƠNG NHÂN HƯ KHÔNG BAN PHƯỚC!",
				p.DisplayName .. " vừa mở Hộp Bí Ẩn trúng Lõi THẦN THOẠI [" .. fName .. "]!",
				"MythicalDrop"
			)
		end
	else
		prof.Inventory[stock.Id] = (prof.Inventory[stock.Id] or 0) + stock.Count
		if stock.Id == "aion_chrono_cloak" and autoEquip ~= false then
			pcall(function()
				local svcs = game:GetService("ServerScriptService"):FindFirstChild("Services")
				local vMod = svcs and svcs:FindFirstChild("SkybreakVendorAndArsenalService")
				if vMod then
					require(vMod).HandleEquipItem(p, { itemId = "aion_chrono_cloak" })
				end
			end)
		end
		LiveOps.Notify(G, p, "THƯƠNG NHÂN HƯ KHÔNG: Đã mua " .. stock.Name .. "!", "VOID MERCHANT: Purchased " .. stock.Id .. "!")
	end

	SocialEconomy.CheckMilestones(p, prof)
	G.Sync(p)
	return true
end

local function rotateVoidMerchant(announce)
	if ActiveVoidMerchant.Model and ActiveVoidMerchant.Model.Parent then
		ActiveVoidMerchant.Model:Destroy()
	end
	ActiveVoidMerchant.StopIndex = (ActiveVoidMerchant.StopIndex % #VOID_MERCHANT_STOPS) + 1
	local stop = VOID_MERCHANT_STOPS[ActiveVoidMerchant.StopIndex]
	local fy = safeFloorY(stop.Pos, stop.Pos.Y - 0.4)
	local pos = Vector3.new(stop.Pos.X, fy + 2.2, stop.Pos.Z)

	local worldObjects = getWorldObjects()
	local m = Instance.new("Model")
	m.Name = "WanderingVoidMerchant"
	m:SetAttribute("NPCId", "Chronos")
	m:SetAttribute("VisualAsset", "Chronos")
	m:SetAttribute("NPCFloorY", fy)
	m.Parent = worldObjects

	local body = W.Part(m, "Body", Vector3.new(2.2, 4.6, 1.8), pos, Color3.fromRGB(186, 102, 255), Enum.Material.Metal)
	local lookPos = stop.LookAt or C.Spawn or Vector3.new(-317.4, pos.Y, 527.8)
	if flatDist(pos, lookPos) > 0.5 then
		body.CFrame = CFrame.lookAt(pos, Vector3.new(lookPos.X, pos.Y, lookPos.Z))
	end
	body.Transparency = 1
	body.CanCollide = false
	local dais = W.Part(m, "VoidRiftPad", Vector3.new(0.36, 5.8, 5.8), Vector3.new(stop.Pos.X, fy + 0.45, stop.Pos.Z), Color3.fromRGB(172, 86, 255), Enum.Material.Neon)
	dais.Shape = Enum.PartType.Cylinder
	dais.CFrame = CFrame.new(stop.Pos.X, fy + 0.45, stop.Pos.Z) * CFrame.Angles(0, 0, math.pi / 2)
	dais.Transparency = 0.42
	dais.CanCollide = false
	m.PrimaryPart = body

	local bill = Instance.new("BillboardGui")
	bill.Size = UDim2.fromScale(4.6, 0.88)
	bill.StudsOffset = Vector3.new(0, 5.0, 0)
	bill.AlwaysOnTop = false
	bill.MaxDistance = 56
	bill.Parent = body
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamBlack
	tl.TextScaled = true
	tl.TextColor3 = Color3.fromRGB(218, 138, 255)
	tl.TextStrokeTransparency = 0.16
	tl.Text = "THƯƠNG NHÂN HƯ KHÔNG • VOID MERCHANT [E]"
	tl.Parent = bill

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Giao Dịch Hàng Hiếm Hư Không Chronos"
	prompt.ObjectText = "Enchant Scroll (95 Shards) • Hộp Lõi Hiếm+ (150kG + 250 Shards)"
	prompt.MaxActivationDistance = 15
	prompt.HoldDuration = 0
	prompt.RequiresLineOfSight = false
	prompt.Parent = body
	prompt.Triggered:Connect(function(plr)
		m:SetAttribute("NPCTalkAt", workspace:GetServerTimeNow())
		G.SendDialogue(
			plr,
			"Thương Nhân Hư Không Chronos",
			"THƯƠNG NHÂN DU HÀNH THỜI KHÔNG",
			"Ta mang tới Cuộn Phù Phép Cổ Ngữ, Hộp Lõi Aether Hiếm+ (giới hạn 1 hộp/đợt) và Thánh Vật Hư Không hiếm có! Hãy mở Cửa Hàng Chronos trước khi ta dịch chuyển.",
			"Mở Cửa Hàng Chronos",
			"OpenScreen:NPCShop:EnchanterAndChronos"
		)
	end)

	local expiresServer = workspace:GetServerTimeNow() + 600
	ActiveVoidMerchant.Model = m
	ActiveVoidMerchant.Stop = stop
	ActiveVoidMerchant.ExpiresAt = expiresServer
	ActiveVoidMerchant.SpawnSerial = (ActiveVoidMerchant.SpawnSerial or 0) + 1
	ActiveVoidMerchant.BoxBuyers = {}

	workspace:SetAttribute("VoidMerchantIsland", stop.Name)
	workspace:SetAttribute("VoidMerchantIslandId", stop.Id)
	workspace:SetAttribute("VoidMerchantPos", Vector3.new(stop.Pos.X, fy + 2.0, stop.Pos.Z))
	workspace:SetAttribute("VoidMerchantExpiresAt", expiresServer)

	if announce then
		SocialEconomy.BroadcastWorldBanner(
			"THƯƠNG NHÂN HƯ KHÔNG XUẤT HIỆN!",
			"Wandering Void Merchant đã mở cổng hàng hiếm tại [" .. stop.Name .. "] trong 10 phút!",
			"VoidMerchant"
		)
	end
end

-- ============================================================================
-- 32. #109 - QUICK REPEAT QUEST BOARDS & 3D ACTIVE QUEST COMPASS SYNC
-- ============================================================================
local QUEST_REALM_FALLBACK_POS = {
	GoldenSky = Vector3.new(-313.9, 50.5, 210.4),
	FrozenCyber = Vector3.new(11675.7, 50.9, 224.2),
	ShadowRealm = Vector3.new(-12593.4, 50.9, 414.0),
	VerdantCrown = Vector3.new(0, 170.9, -8985),
	EmberforgeWastes = Vector3.new(12000, 170.5, -9265),
	AbyssalTides = Vector3.new(-12000, 170.9, -8964.5),
	ChronosBastion = Vector3.new(0, 230.9, -13485),
	VeilsEnd = Vector3.new(0, 310.9, -17626.9),
}

function SocialEconomy.RepeatQuest(p, payload)
	local prof = D and D.Get(p)
	if not prof or not C or not C.Quests then
		return false
	end
	if G.EnsureProfileFields then
		G.EnsureProfileFields(prof)
	end

	if prof.LastCompletedQuest then
		local cid = prof.LastCompletedQuest
		prof.LastCompletedQuest = nil
		prof.Gold = (prof.Gold or 0) + 250
		prof.CoreShards = (prof.CoreShards or 0) + 60
		prof.Potions = (prof.Potions or 0) + 1
		G.Notify(p, "Đã nhận thưởng bổ sung nhiệm vụ " .. tostring(cid) .. ": +250 Gold, +60 Core Shards!")
	end

	local requestedIdx = type(payload) == "table" and tonumber(payload.questIndex) or nil
	local maxQ = #C.Quests
	if maxQ <= 0 then
		return false
	end

	if requestedIdx then
		-- Chi cho chon nhiem vu da mo khoa (<= nhiem vu cao nhat tung dat). Truoc day client gui questIndex=14
		-- la nhay thang toi nhiem vu cuoi o Lv1, bo qua toan bo cot truyen.
		local highest = math.max(tonumber(prof.HighestQuestIndex) or 1, tonumber(prof.QuestIndex) or 1)
		for qi, qq in ipairs(C.Quests) do
			if prof.CompletedQuests and prof.CompletedQuests[qq.Id] then
				highest = math.max(highest, qi + 1)
			end
		end
		highest = math.min(highest, maxQ)
		prof.HighestQuestIndex = highest
		local target = math.clamp(math.floor(requestedIdx), 1, maxQ)
		if target > highest then
			G.Notify(p, "Chưa mở khóa nhiệm vụ này! Hãy hoàn thành các nhiệm vụ trước.")
			return false
		end
		prof.QuestIndex = target
	elseif (tonumber(prof.QuestIndex) or 1) > maxQ then
		prof.QuestIndex = maxQ
	end

	local q = C.Quests[prof.QuestIndex]
	if not q then
		prof.QuestIndex = maxQ
		q = C.Quests[maxQ]
	end
	if q then
		if prof.CompletedQuests and prof.CompletedQuests[q.Id] then
			prof.CompletedQuests[q.Id] = nil
			prof.Progress = {}
		end
		prof.Accepted = true
		G.Notify(p, "NHẬN NHANH NHIỆM VỤ [" .. q.Id .. "]: " .. q.Name .. "!")
		G.Sync(p)
		return true
	end
	return false
end

local function updatePlayerQuestCompass(p)
	local prof = D and D.Get(p)
	local pr = root(p)
	if not prof or not pr or not C or not C.Quests then
		return
	end
	local qIdx = math.clamp(tonumber(prof.QuestIndex) or 1, 1, math.max(1, #C.Quests))
	local q = C.Quests[qIdx]
	if not q then
		p:SetAttribute("ActiveQuestTitle", "")
		return
	end

	local targetIds = {}
	for i, obj in ipairs(q.Objectives or {}) do
		local cur = tonumber(prof.Progress and prof.Progress[tostring(i)]) or 0
		if cur < (obj.Count or 1) and obj.Target then
			targetIds[obj.Target] = true
		end
	end

	local bestPos = nil
	local bestDist = math.huge
	for _, e in ipairs(G.Enemies or {}) do
		if e.Alive and e.Body and e.Model and e.Model.Parent then
			if targetIds[e.Id] or (next(targetIds) == nil and e.Config and e.Config.Realm == q.Realm) then
				local d = (e.Body.Position - pr.Position).Magnitude
				if d < bestDist then
					bestDist = d
					bestPos = e.Body.Position
				end
			end
		end
	end

	if not bestPos then
		bestPos = QUEST_REALM_FALLBACK_POS[q.Realm or "GoldenSky"] or C.Spawn
	end
	p:SetAttribute("ActiveQuestTitle", q.Id .. ": " .. q.Name)
	p:SetAttribute("ActiveQuestTargetPos", bestPos)
end

local function buildQuickQuestBoards()
	local folder = workspace:FindFirstChild("QuickQuestBoards")
	if folder then
		folder:Destroy()
	end
	folder = Instance.new("Folder")
	folder.Name = "QuickQuestBoards"
	folder.Parent = workspace

	local boardSpots = {
		{ Name = "SkyHub_FarmBoard", Pos = Vector3.new(-322.0, 47.5, 224.2), LookAt = Vector3.new(-313.9, 47.5, 210.4) },
		{ Name = "WestBastion_FarmBoard", Pos = Vector3.new(-2811.1, 47.5, -46.0), LookAt = Vector3.new(-2800.0, 47.5, -65.0) },
		{ Name = "Sunshard_FarmBoard", Pos = Vector3.new(2788.9, 47.5, -36.0), LookAt = Vector3.new(2800.0, 47.5, -55.0) },
		{ Name = "FrozenOutpost_FarmBoard", Pos = Vector3.new(11667.6, 47.9, 238.0), LookAt = Vector3.new(11675.7, 47.9, 224.2) },
		{ Name = "Permafrost_FarmBoard", Pos = Vector3.new(9386.5, 47.9, -2037.6), LookAt = Vector3.new(9400.0, 47.9, -2055.0) },
		{ Name = "ShadowCitadel_FarmBoard", Pos = Vector3.new(-12601.5, 47.9, 427.8), LookAt = Vector3.new(-12593.4, 47.9, 414.0) },
		{ Name = "CastleVoid_FarmBoard", Pos = Vector3.new(-14620.3, 47.9, 2164.6), LookAt = Vector3.new(-14600.0, 47.9, 2173.1) },
		{ Name = "Verdant_FarmBoard", Pos = Vector3.new(-9.7, 167.9, -8997.7), LookAt = Vector3.new(0.0, 167.9, -8985.0) },
		{ Name = "Emberforge_FarmBoard", Pos = Vector3.new(11990.3, 167.5, -9277.7), LookAt = Vector3.new(12000.0, 167.5, -9265.0) },
		{ Name = "Chronos_FarmBoard", Pos = Vector3.new(-9.7, 227.9, -13497.7), LookAt = Vector3.new(0.0, 227.9, -13485.0) },
	}

	for _, bs in ipairs(boardSpots) do
		local fy = safeFloorY(bs.Pos, bs.Pos.Y - 1.2)
		local m = Instance.new("Model")
		m.Name = bs.Name
		m.Parent = folder

		local postPos = Vector3.new(bs.Pos.X, fy + 2.1, bs.Pos.Z)
		local lookTarget = bs.LookAt and Vector3.new(bs.LookAt.X, postPos.Y, bs.LookAt.Z) or (postPos + Vector3.new(0, 0, -5))
		local fwd = (lookTarget - postPos)
		local fwdDir = (fwd.Magnitude > 0.2) and fwd.Unit or Vector3.new(0, 0, -1)

		local post = W.Part(m, "BoardPost", Vector3.new(3.6, 3.4, 0.55), postPos, Color3.fromRGB(36, 44, 62), Enum.Material.Metal)
		post.CFrame = CFrame.lookAt(postPos, postPos + fwdDir)
		local screenPos = Vector3.new(bs.Pos.X, fy + 2.3, bs.Pos.Z) + fwdDir * 0.32
		local screen = W.Part(m, "HoloScreen", Vector3.new(3.1, 2.2, 0.15), screenPos, Color3.fromRGB(92, 232, 255), Enum.Material.Neon)
		screen.CFrame = CFrame.lookAt(screenPos, screenPos + fwdDir)
		screen.Transparency = 0.42
		screen.CanCollide = false
		m.PrimaryPart = post

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Nhận / Lặp Lại Nhiệm Vụ Nhanh (1-Click)"
		prompt.ObjectText = "Bảng Nhiệm Vụ Bãi Farm • Quick Repeat Quest"
		prompt.MaxActivationDistance = 14
		prompt.HoldDuration = 0
		prompt.RequiresLineOfSight = false
		prompt.Parent = post
		prompt.Triggered:Connect(function(plr)
			SocialEconomy.RepeatQuest(plr)
		end)
	end
end

-- ============================================================================
-- 34. #111 - REAL 2-6 PLAYER CO-OP PARTY SYSTEM
-- ============================================================================
local Parties = {}
local PlayerPartyId = {}
local PendingPartyInvites = {} -- [player] = { PartyId = ..., LeaderName = ..., ExpiresAt = ... }
local NextPartySeq = 1

function SocialEconomy.GetPartyPlayers(p)
	local pid = p and PlayerPartyId[p]
	local party = pid and Parties[pid]
	if not party then
		return p and { p } or {}
	end
	local out = {}
	for _, member in ipairs(party.Members) do
		if member and member.Parent == Players then
			table.insert(out, member)
		end
	end
	if #out == 0 and p then
		return { p }
	end
	return out
end

function SocialEconomy.AreInSameParty(a, b)
	if not a or not b then
		return false
	end
	if a == b then
		return true
	end
	local pa = PlayerPartyId[a]
	return pa ~= nil and pa == PlayerPartyId[b]
end

local function syncPartyMembers(party)
	if not party then
		return
	end
	local defaultMode = (#party.Members <= 2) and "Duo" or "Squad"
	for _, m in ipairs(party.Members) do
		if m and m.Parent == Players then
			m:SetAttribute("PartyId", party.Id)
			local mp = D and D.Get(m)
			if mp and (mp.PartySize == nil or mp.PartySize == "Solo") then
				mp.PartySize = defaultMode
			end
			if SocialEconomy.PushSnapshotToPlayer then
				SocialEconomy.PushSnapshotToPlayer(m)
			end
			G.Sync(m)
		end
	end
end

local function removePlayerFromParty(p, reasonMsg)
	local pid = PlayerPartyId[p]
	if not pid then
		return false
	end
	PlayerPartyId[p] = nil
	if p and p.Parent == Players then
		p:SetAttribute("PartyId", "")
		local prof = D and D.Get(p)
		if prof then
			prof.PartySize = "Solo"
		end
	end
	local party = Parties[pid]
	if not party then
		return true
	end
	for i = #party.Members, 1, -1 do
		if party.Members[i] == p then
			table.remove(party.Members, i)
		end
	end
	if #party.Members == 0 then
		Parties[pid] = nil
	else
		if party.Leader == p then
			party.Leader = party.Members[1]
		end
		for _, m in ipairs(party.Members) do
			if reasonMsg and m.Parent == Players then
				G.Notify(m, reasonMsg)
			end
		end
		syncPartyMembers(party)
	end
	if p and p.Parent == Players then
		if SocialEconomy.PushSnapshotToPlayer then
			SocialEconomy.PushSnapshotToPlayer(p)
		end
		G.Sync(p)
	end
	return true
end

function SocialEconomy.HandlePartyAction(p, payload)
	payload = type(payload) == "table" and payload or {}
	local sub = tostring(payload.subAction or payload.mode or payload.partyAction or payload.value or "CreateParty")

	if sub == "CreateParty" or sub == "Create" then
		if PlayerPartyId[p] then
			G.Notify(p, "Bạn đang ở trong Tổ Đội Co-op (" .. PlayerPartyId[p] .. ")!")
			if SocialEconomy.PushSnapshotToPlayer then
				SocialEconomy.PushSnapshotToPlayer(p)
			end
			G.Sync(p)
			return true
		end
		local pid = string.format("PARTY_%02d", NextPartySeq)
		NextPartySeq += 1
		Parties[pid] = {
			Id = pid,
			Leader = p,
			Members = { p },
		}
		PlayerPartyId[p] = pid
		p:SetAttribute("PartyId", pid)
		local prof = D and D.Get(p)
		if prof and (prof.PartySize == nil or prof.PartySize == "Solo") then
			prof.PartySize = "Duo"
		end
		G.Notify(p, "ĐÃ TẠO TỔ ĐỘI CO-OP [" .. pid .. "] (Tối đa 6 Thành Viên • Chia sẻ +15% EXP & Boss Credit)!")
		if SocialEconomy.PushSnapshotToPlayer then
			SocialEconomy.PushSnapshotToPlayer(p)
		end
		G.Sync(p)
		return true

	elseif sub == "InviteParty" or sub == "Invite" then
		local pid = PlayerPartyId[p]
		if not pid then
			SocialEconomy.HandlePartyAction(p, { subAction = "CreateParty" })
			pid = PlayerPartyId[p]
		end
		local party = Parties[pid]
		if not party then
			return false
		end
		if #party.Members >= 6 then
			G.Notify(p, "Tổ Đội đã đầy (6/6 thành viên)!")
			return false
		end
		local targetId = tonumber(payload.targetUserId or payload.userId)
		local targetName = tostring(payload.targetName or payload.name or "")
		local targetPlr = nil
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= p and ((targetId and other.UserId == targetId) or (targetName ~= "" and (string.lower(other.Name) == string.lower(targetName) or string.lower(other.DisplayName) == string.lower(targetName)))) then
				targetPlr = other
				break
			end
		end
		if not targetPlr then
			for _, other in ipairs(Players:GetPlayers()) do
				if other ~= p and not PlayerPartyId[other] then
					targetPlr = other
					break
				end
			end
		end
		if not targetPlr then
			G.Notify(p, "Không tìm thấy người chơi khác trong server để mời vào Tổ Đội!")
			return false
		end
		PendingPartyInvites[targetPlr] = {
			PartyId = pid,
			LeaderId = p.UserId,
			LeaderName = p.DisplayName,
			ExpiresAt = os.clock() + 90,
		}
		G.Notify(p, "Đã gửi lời mời Tổ Đội Co-op tới " .. targetPlr.DisplayName .. "!")
		G.Notify(targetPlr, p.DisplayName .. " mời bạn gia nhập Tổ Đội Co-op [" .. pid .. "]!")
		if SocialEconomy.PushSnapshotToPlayer then
			SocialEconomy.PushSnapshotToPlayer(p)
			SocialEconomy.PushSnapshotToPlayer(targetPlr)
		end
		G.Sync(targetPlr)
		return true

	elseif sub == "Accept" or sub == "AcceptInvite" or sub == "JoinParty" or sub == "Join" then
		local inv = PendingPartyInvites[p]
		if inv and os.clock() > (inv.ExpiresAt or 0) then
			PendingPartyInvites[p] = nil
			inv = nil
		end
		local party = (inv and inv.PartyId and Parties[inv.PartyId]) or nil
		if not party then
			if PlayerPartyId[p] then
				G.Notify(p, "Bạn đang ở trong Tổ Đội [" .. tostring(PlayerPartyId[p]) .. "]!")
				return true
			end
			G.Notify(p, "Lời mời Tổ Đội đã hết hạn hoặc bạn chưa nhận lời mời Tổ Đội Co-op!")
			return false
		end
		if PlayerPartyId[p] == party.Id then
			PendingPartyInvites[p] = nil
			G.Notify(p, "Bạn đã ở trong Tổ Đội Co-op [" .. party.Id .. "]!")
			syncPartyMembers(party)
			return true
		end
		if #party.Members >= 6 then
			G.Notify(p, "Tổ Đội này đã đủ 6/6 thành viên!")
			return false
		end
		removePlayerFromParty(p)
		PendingPartyInvites[p] = nil
		table.insert(party.Members, p)
		PlayerPartyId[p] = party.Id
		local prof = D and D.Get(p)
		if prof then
			prof.PartySize = (#party.Members <= 2) and "Duo" or "Squad"
		end
		for _, m in ipairs(party.Members) do
			G.Notify(m, p.DisplayName .. " đã gia nhập Tổ Đội Co-op (" .. #party.Members .. "/6)!")
		end
		syncPartyMembers(party)
		return true

	elseif sub == "Decline" or sub == "DeclineInvite" or sub == "Reject" then
		local inv = PendingPartyInvites[p]
		PendingPartyInvites[p] = nil
		if inv and inv.LeaderId then
			local leaderPlr = Players:GetPlayerByUserId(inv.LeaderId)
			if leaderPlr and leaderPlr.Parent == Players then
				G.Notify(leaderPlr, p.DisplayName .. " đã từ chối lời mời vào Tổ Đội.")
			end
		end
		G.Notify(p, "Đã từ chối lời mời vào Tổ Đội.")
		if SocialEconomy.PushSnapshotToPlayer then
			SocialEconomy.PushSnapshotToPlayer(p)
		end
		G.Sync(p)
		return true

	elseif sub == "LeaveParty" or sub == "Leave" then
		if not PlayerPartyId[p] then
			local prof = D and D.Get(p)
			if prof then
				prof.PartySize = "Solo"
			end
			G.Notify(p, "Bạn hiện không ở trong Tổ Đội Co-op nào.")
			if SocialEconomy.PushSnapshotToPlayer then
				SocialEconomy.PushSnapshotToPlayer(p)
			end
			G.Sync(p)
			return false
		end
		removePlayerFromParty(p, p.DisplayName .. " đã rời khỏi Tổ Đội.")
		G.Notify(p, "Bạn đã rời khỏi Tổ Đội Co-op.")
		return true

	elseif sub == "KickMember" or sub == "Kick" then
		local pid = PlayerPartyId[p]
		local party = pid and Parties[pid]
		if not party or party.Leader ~= p then
			G.Notify(p, "Chỉ Đội Trưởng mới có quyền mời thành viên rời Tổ Đội!")
			return false
		end
		local kickUid = tonumber(payload.targetUserId or payload.userId)
		local kickName = tostring(payload.targetName or payload.name or "")
		for _, m in ipairs(party.Members) do
			if m ~= p and ((kickUid and m.UserId == kickUid) or (kickName ~= "" and (string.lower(m.Name) == string.lower(kickName) or string.lower(m.DisplayName) == string.lower(kickName)))) then
				removePlayerFromParty(m, m.DisplayName .. " đã được mời rời khỏi Tổ Đội.")
				G.Notify(m, "Bạn đã được mời rời khỏi Tổ Đội Co-op.")
				return true
			end
		end
		return false

	elseif sub == "SetMode" then
		local prof = D and D.Get(p)
		if prof then
			local rawMode = tostring(payload.partyMode or payload.partySize or payload.modeValue or payload.value or "Solo")
			local validModes = { Solo = "Solo", Duo = "Duo", Trio = "Trio", Squad = "Squad", Party = "Party" }
			local chosen = validModes[rawMode] or "Solo"
			local pid = PlayerPartyId[p]
			local party = pid and Parties[pid]
			if party and #party.Members > 1 and chosen == "Solo" then
				chosen = (#party.Members <= 2) and "Duo" or "Squad"
			end
			prof.PartySize = chosen
			G.Notify(p, "Chế độ Tổ Đội đã đặt thành: " .. tostring(prof.PartySize) .. "!")
			if SocialEconomy.PushSnapshotToPlayer then
				SocialEconomy.PushSnapshotToPlayer(p)
			end
			G.Sync(p)
			return true
		end
	end
	return false
end

-- ============================================================================
-- 35 & 36. #112 PVP FLAG / SAFE ZONES / 15-MIN SHIELD & #113 1V1 SKY COLOSSEUM
-- ============================================================================
local COLOSSEUM_CENTER = Vector3.new(0, 46.7, 166)
local COLOSSEUM_RADIUS = 32
local ActiveDuels = {} -- [player] = { Opponent = otherPlayerOrNil, IsPracticeAI = bool, AIEnemy = enemyTableOrNil, StartedAt = clock, DamageDealt = number }
local PvPFarmCooldown = {} -- ["uidA:uidB"] = expireClock
local ColosseumFarmCooldown = {} -- ["uidA:uidB"] = expireClock
local PracticeFarmCooldown = {} -- [userId] = expireClock
local CombatLogSettled = {} -- [player] = clock

local function isPositionInSafeZone(pos)
	-- Inside active Colosseum ring is NOT a safe zone for active duelists, handled before calling this
	for _, sz in ipairs(SAFE_ZONES) do
		if flatDist(pos, sz.Pos) <= sz.Radius and math.abs(pos.Y - sz.Pos.Y) <= 85 then
			return true, sz.Name
		end
	end
	return false, nil
end

local function areSameCrew(a, b)
	local ca = tostring(a:GetAttribute("CrewName") or "")
	local cb = tostring(b:GetAttribute("CrewName") or "")
	return ca ~= "" and ca == cb
end

local function areDuelingEachOther(a, b)
	local da = ActiveDuels[a]
	return da ~= nil and da.Opponent == b
end

local function restoreFullVitals(p)
	local _, h = root(p)
	local rt = G and G.Runtime[p]
	if h then
		local s = G.Stats(p)
		if s and s.HP then
			h.MaxHealth = s.HP
		end
		h.Health = h.MaxHealth
	end
	if rt then
		rt.Stamina = 100
		rt.Energy = rt.MaxEnergy or 100
	end
end

local function isBlockedFromColosseum(p)
	if not p or p.Parent ~= Players then
		return true
	end
	if p:GetAttribute("InTrade") == true or p:GetAttribute("RaidActive") == true or p:GetAttribute("InRaceTrial") == true then
		return true
	end
	if (tonumber(p:GetAttribute("PvPCombatUntil")) or 0) > os.time() then
		return true
	end
	if G and G.Boss and G.Boss.Party and G.Boss.Party[p] then
		return true
	end
	return false
end

local function setColosseumAttributes(p, active)
	if p and p.Parent == Players then
		p:SetAttribute("InColosseumDuel", active)
		p:SetAttribute("InColosseum", active)
		p:SetAttribute("ColosseumActive", active)
	end
end

local function finishColosseumDuel(winner, loser, reason)
	local dWin = winner and ActiveDuels[winner]
	local dLose = loser and ActiveDuels[loser]
	local wRoot = winner and root(winner)
	if winner then
		ActiveDuels[winner] = nil
		setColosseumAttributes(winner, false)
		restoreFullVitals(winner)
	end
	if loser then
		ActiveDuels[loser] = nil
		setColosseumAttributes(loser, false)
		restoreFullVitals(loser)
	end
	local ai = (dWin and dWin.AIEnemy) or (dLose and dLose.AIEnemy)
	if ai and ai.Alive then
		ai.Alive = false
		if ai.Model and ai.Model.Parent then
			ai.Model:Destroy()
		end
	end
	if winner and winner.Parent == Players then
		local now = os.clock()
		local elapsed = dWin and (now - (dWin.StartedAt or now)) or 0
		local dmgDealt = dWin and (tonumber(dWin.DamageDealt) or 0) or 0
		local inRing = wRoot ~= nil and flatDist(wRoot.Position, COLOSSEUM_CENTER) <= (COLOSSEUM_RADIUS + 14)
		local canReward = false
		if reason == "Knockout" and loser and elapsed >= 20 and dmgDealt >= 150 and inRing then
			local pairKey = tostring(winner.UserId) .. ":" .. tostring(loser.UserId)
			if now >= (ColosseumFarmCooldown[pairKey] or 0) then
				ColosseumFarmCooldown[pairKey] = now + 300
				canReward = true
			end
		elseif reason == "Defeated AI Champion" and elapsed >= 8 and dmgDealt > 0 and inRing then
			if now >= (PracticeFarmCooldown[winner.UserId] or 0) then
				PracticeFarmCooldown[winner.UserId] = now + 60
				canReward = true
			end
		end
		if canReward then
			local prof = D.Get(winner)
			local goldGain = 3500
			if prof then
				goldGain = applyGoldWithPass(winner, prof, 3500)
				prof.Gold = (prof.Gold or 0) + goldGain
				prof.CoreShards = (prof.CoreShards or 0) + 150
			end
			G.Notify(winner, string.format("CHIẾN THẮNG 1V1 SKY COLOSSEUM! (+%d Gold, +150 Core Shards, Đã hồi phục 100%% HP/Energy/Stamina)!", goldGain))
		else
			G.Notify(winner, "KẾT THÚC LUẬN VÕ 1V1 SKY COLOSSEUM (" .. tostring(reason or "0 Mất Điểm Danh Vọng") .. ")! Đã hồi phục 100% HP/Energy/Stamina!")
		end
		G.Sync(winner)
	end
	if loser and loser.Parent == Players then
		G.Notify(loser, "KẾT THÚC LUẬN VÕ 1V1 SKY COLOSSEUM (" .. tostring(reason or "0 Renown Loss") .. ")! Đã hồi phục 100% HP/Energy/Stamina!")
		G.Sync(loser)
	end
end

local function startPlayerColosseumDuel(pA, pB)
	if not pA or not pB or pA == pB or ActiveDuels[pA] or ActiveDuels[pB] or isBlockedFromColosseum(pA) or isBlockedFromColosseum(pB) then
		return false
	end
	local fy = safeFloorY(COLOSSEUM_CENTER, 46.5)
	G.Teleport(pA, Vector3.new(COLOSSEUM_CENTER.X - 12, fy + 3.2, COLOSSEUM_CENTER.Z), nil, true)
	G.Teleport(pB, Vector3.new(COLOSSEUM_CENTER.X + 12, fy + 3.2, COLOSSEUM_CENTER.Z), nil, true)
	restoreFullVitals(pA)
	restoreFullVitals(pB)

	local now = os.clock()
	ActiveDuels[pA] = { Opponent = pB, IsPracticeAI = false, StartedAt = now, DamageDealt = 0 }
	ActiveDuels[pB] = { Opponent = pA, IsPracticeAI = false, StartedAt = now, DamageDealt = 0 }
	setColosseumAttributes(pA, true)
	setColosseumAttributes(pB, true)

	G.Notify(pA, "1V1 SKY COLOSSEUM: Luận Võ Công Bằng với " .. pB.DisplayName .. " BẮT ĐẦU! (0 Mất Điểm Danh Vọng)")
	G.Notify(pB, "1V1 SKY COLOSSEUM: Luận Võ Công Bằng với " .. pA.DisplayName .. " BẮT ĐẦU! (0 Mất Điểm Danh Vọng)")
	return true
end

local function startSoloPracticeColosseumDuel(p)
	if ActiveDuels[p] then
		G.Notify(p, "Bạn đang ở trong trận Luận Võ 1v1 Sky Colosseum!")
		return false
	end
	if isBlockedFromColosseum(p) then
		G.Notify(p, "Không thể vào 1v1 Sky Colosseum khi đang Giao Tranh PvP, Giao Dịch, Raid hoặc Thử Thách!")
		return false
	end
	local fy = safeFloorY(COLOSSEUM_CENTER, 46.5)
	G.Teleport(p, Vector3.new(COLOSSEUM_CENTER.X - 11, fy + 3.2, COLOSSEUM_CENTER.Z), nil, true)
	restoreFullVitals(p)

	local aiPos = Vector3.new(COLOSSEUM_CENTER.X + 11, fy + 2.5, COLOSSEUM_CENTER.Z)
	local champ = G.SpawnEnemy("GoldenKnight", aiPos, false, true)
	if champ then
		local stats = G.Stats(p)
		champ.MaxHP = math.max(4500, math.floor(((stats and stats.HP) or 1200) * 3.2))
		champ.HP = champ.MaxHP
		champ.NoRespawn = true
		champ.ColosseumTarget = p
		if champ.Model then
			champ.Model.Name = "ColosseumChampionAI"
			champ.Model:SetAttribute("DisplayTitle", "Quán Quân Đấu Trường • Challenger Champion")
		end
	end

	ActiveDuels[p] = {
		Opponent = nil,
		IsPracticeAI = true,
		AIEnemy = champ,
		StartedAt = os.clock(),
		DamageDealt = 0,
	}
	setColosseumAttributes(p, true)
	G.Notify(p, "1V1 SKY COLOSSEUM (SOLO PRACTICE): Quán Quân Đấu Trường AI đã xuất hiện! Chiến thắng nhận +3,500 Gold & +150 Shards!")
	return true
end

local waitingChallenger = nil
local waitingAt = 0

local function queueColosseum1v1(plr)
	if not plr or plr.Parent ~= Players or ActiveDuels[plr] then
		return false
	end
	if isBlockedFromColosseum(plr) then
		G.Notify(plr, "Không thể vào 1v1 Sky Colosseum khi đang Giao Dịch, Raid hoặc Thử Thách!")
		return false
	end
	if waitingChallenger and waitingChallenger ~= plr and waitingChallenger.Parent == Players and (os.clock() - waitingAt) < 25 then
		local opp = waitingChallenger
		waitingChallenger = nil
		return startPlayerColosseumDuel(opp, plr)
	else
		waitingChallenger = plr
		waitingAt = os.clock()
		G.Notify(plr, "Đang ghép cặp 1v1 Sky Colosseum (4s -> tự động mở Đấu Trường AI Solo Practice nếu chưa có đối thủ)...")
		task.delay(4.0, function()
			if waitingChallenger == plr then
				waitingChallenger = nil
				if plr.Parent == Players and not ActiveDuels[plr] then
					startSoloPracticeColosseumDuel(plr)
				end
			end
		end)
		return true
	end
end

local function buildSkyColosseumDuelRing()
	local worldObjects = getWorldObjects()
	local old = worldObjects:FindFirstChild("SkyColosseumDuelRing")
	if old then
		old:Destroy()
	end

	local fy = safeFloorY(COLOSSEUM_CENTER, 46.5)
	local center = Vector3.new(COLOSSEUM_CENTER.X, fy, COLOSSEUM_CENTER.Z)
	local m = Instance.new("Model")
	m.Name = "SkyColosseumDuelRing"
	m.Parent = worldObjects

	W.Ring(m, "ColosseumBoundaryRing", center + Vector3.new(0, 0.48, 0), COLOSSEUM_RADIUS, Color3.fromRGB(255, 212, 88), 28)
	W.Ring(m, "ColosseumInnerRing", center + Vector3.new(0, 0.50, 0), 14, Color3.fromRGB(92, 232, 255), 20)

	local function makeDuelPad(padName, offset, col, labelText)
		local pad = Instance.new("Part")
		pad.Name = padName
		pad.Shape = Enum.PartType.Cylinder
		pad.Size = Vector3.new(0.40, 6.2, 6.2)
		pad.CFrame = CFrame.new(center + offset + Vector3.new(0, 0.45, 0)) * CFrame.Angles(0, 0, math.pi / 2)
		pad.Color = col
		pad.Material = Enum.Material.Neon
		pad.Transparency = 0.36
		pad.Anchored, pad.CanCollide, pad.CanQuery, pad.CanTouch = true, false, false, false
		pad.Parent = m

		local bill = Instance.new("BillboardGui")
		bill.Size = UDim2.fromScale(4.2, 0.78)
		bill.StudsOffset = Vector3.new(0, 3.8, 0)
		bill.AlwaysOnTop = false
		bill.MaxDistance = 48
		bill.Parent = pad
		local tl = Instance.new("TextLabel")
		tl.Size = UDim2.fromScale(1, 1)
		tl.BackgroundTransparency = 1
		tl.Font = Enum.Font.GothamBlack
		tl.TextScaled = true
		tl.TextColor3 = col
		tl.TextStrokeTransparency = 0.18
		tl.Text = labelText
		tl.Parent = bill

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Bước Vào Luận Võ 1v1 Công Bằng"
		prompt.ObjectText = "1v1 Sky Colosseum (0 Mất Điểm Danh Vọng • Hồi 100% HP)"
		prompt.MaxActivationDistance = 12
		prompt.HoldDuration = 0
		prompt.RequiresLineOfSight = false
		prompt.Parent = pad
		prompt.Triggered:Connect(function(plr)
			queueColosseum1v1(plr)
		end)
		return pad
	end

	local padA = makeDuelPad("DuelPad_A", Vector3.new(-12, 0, 0), Color3.fromRGB(92, 232, 255), "1V1 COLOSSEUM • DUEL PAD A [E]")
	makeDuelPad("DuelPad_B", Vector3.new(12, 0, 0), Color3.fromRGB(255, 206, 86), "1V1 COLOSSEUM • DUEL PAD B [E]")
	m.PrimaryPart = padA
end

function SocialEconomy.TogglePvP(p, forceState)
	local rt = G and G.Runtime[p]
	if not rt then
		return false
	end
	local now = os.clock()
	local nowUnix = os.time()
	local current = (p:GetAttribute("PvPEnabled") == true)
	local desired = (type(forceState) == "boolean") and forceState or (not current)
	local tagUnix = tonumber(p:GetAttribute("PvPCombatUntil")) or 0

	if not desired and (now < (rt.PvPCombatTagUntil or 0) or tagUnix > nowUnix) then
		local rem = math.max(math.ceil((rt.PvPCombatTagUntil or 0) - now), math.max(1, tagUnix - nowUnix))
		G.Notify(p, "Không thể tắt Cờ PvP khi đang giao tranh (" .. rem .. "s)!")
		return false
	end

	rt.PvPEnabled = desired
	p:SetAttribute("PvPEnabled", desired)
	if desired then
		p:SetAttribute("PvPShieldUntil", 0)
		G.Notify(p, "CỜ PVP: BẬT (Có thể giao đấu ngoài Vùng An Toàn Sky Hub / Trạm Giao Thương)!")
	else
		G.Notify(p, "CỜ PVP: TẮT (Chế độ Hòa Bình PvE)!")
	end
	G.Sync(p)
	return true
end

local function settleOpenWorldPvPKO(attacker, defender, isCombatLog)
	local dProf = defender and D and D.Get(defender)
	local drt = defender and G and G.Runtime[defender]
	if defender then
		defender:SetAttribute("PvPCombatUntil", 0)
		defender:SetAttribute("PvPShieldUntil", workspace:GetServerTimeNow() + 900)
		defender:SetAttribute("PvPEnabled", false)
	end
	if drt then
		drt.PvPEnabled = false
		drt.PvPCombatTagUntil = 0
		drt.LastPvPAttacker = nil
	end
	if not isCombatLog and defender and defender.Parent == Players then
		restoreFullVitals(defender)
		G.Teleport(defender, C.Spawn, nil, true)
	end

	local defRenown = dProf and math.max(0, tonumber(dProf.Bounty) or 0) or 250000
	local stake = math.clamp(math.floor(defRenown * 0.02), 2500, 25000)
	local pairKey = (attacker and defender) and (tostring(attacker.UserId) .. ":" .. tostring(defender.UserId)) or nil
	local canTransfer = (pairKey == nil) or (os.clock() >= (PvPFarmCooldown[pairKey] or 0))

	if dProf and (isCombatLog or canTransfer) then
		dProf.Bounty = math.max(0, (tonumber(dProf.Bounty) or 0) - stake)
	end
	if not isCombatLog and defender and defender.Parent == Players then
		local lossTxt = canTransfer and (" (-" .. tostring(stake) .. " Điểm Danh Vọng)") or ""
		G.Notify(defender, "BẠN ĐÃ THUA GIAO ĐẤU PVP" .. lossTxt .. ": Kích hoạt Khiên Bảo Vệ PvP 15 Phút & đưa về Sky Hub!")
		G.Sync(defender)
	end

	if attacker and attacker.Parent == Players and canTransfer then
		if pairKey then
			PvPFarmCooldown[pairKey] = os.clock() + 300
		end
		local aProf = D and D.Get(attacker)
		if aProf then
			aProf.Bounty = (tonumber(aProf.Bounty) or 0) + stake
			aProf.Honor = (tonumber(aProf.Honor) or 0) + stake
			SocialEconomy.CheckMilestones(attacker, aProf)
			LiveOps.RecordLeaderboardScore(attacker, "Renown", math.max(aProf.Bounty or 0, aProf.Honor or 0), false)
		end
		local modeLabel = isCombatLog and " (Đối thủ thoát giữa giao tranh)" or ""
		G.Notify(attacker, "CHIẾN THẮNG PVP trước " .. (defender and defender.DisplayName or "Đối Thủ") .. modeLabel .. ": +" .. tostring(stake) .. " Điểm Danh Vọng (Renown)!")
		G.Sync(attacker)
	end
end

local function canPvPDamage(attacker, defender)
	if not attacker or not defender or attacker == defender then
		return false
	end
	if attacker:GetAttribute("InTrade") == true or defender:GetAttribute("InTrade") == true then
		return false
	end
	if areDuelingEachOther(attacker, defender) then
		return true
	end
	if ActiveDuels[attacker] or ActiveDuels[defender] then
		return false
	end
	if SocialEconomy.AreInSameParty(attacker, defender) or areSameCrew(attacker, defender) then
		return false
	end
	if attacker:GetAttribute("PvPEnabled") ~= true or defender:GetAttribute("PvPEnabled") ~= true then
		return false
	end
	local nowServer = workspace:GetServerTimeNow()
	if (tonumber(attacker:GetAttribute("PvPShieldUntil")) or 0) > nowServer then
		return false
	end
	if (tonumber(defender:GetAttribute("PvPShieldUntil")) or 0) > nowServer then
		return false
	end
	if defender.Character and (tonumber(defender.Character:GetAttribute("SpawnShieldUntil")) or 0) > nowServer then
		return false
	end
	local drt = G and G.Runtime[defender]
	if drt and os.clock() < (drt.InvincibleUntil or 0) then
		return false
	end
	local ar = root(attacker)
	local dr = root(defender)
	if not ar or not dr then
		return false
	end
	local nowUnix = os.time()
	if isPositionInSafeZone(ar.Position) and (tonumber(attacker:GetAttribute("PvPCombatUntil")) or 0) <= nowUnix then
		return false
	end
	if isPositionInSafeZone(dr.Position) and (tonumber(defender:GetAttribute("PvPCombatUntil")) or 0) <= nowUnix then
		return false
	end
	return true
end

local function applyPlayerVsPlayerHitCheck(attacker, originPos, facing, range, rawDamage, skillName)
	local ar = root(attacker)
	if not ar then
		return
	end
	local now = os.clock()
	local art = G.Runtime[attacker]
	if art then
		art._LastPvPHitCastAt = now
	end
	local reach = math.clamp(tonumber(range) or 14, 8, 95)
	for _, defender in ipairs(Players:GetPlayers()) do
		if defender ~= attacker and canPvPDamage(attacker, defender) then
			local dr, dh = root(defender)
			if dr and dh and dh.Health > 0 then
				local delta = dr.Position - originPos
				if delta.Magnitude <= reach and (delta.Magnitude < 8 or not facing or facing:Dot(delta.Unit) > -0.35) then
					local drt = G.Runtime[defender]
					if drt then
						drt._LastPvPDmgAtBy = drt._LastPvPDmgAtBy or {}
						if (now - (drt._LastPvPDmgAtBy[attacker] or 0)) < 0.06 then
							continue
						end
						drt._LastPvPDmgAtBy[attacker] = now
					end

					local dProf = D and D.Get(defender)
					local dCh = defender.Character
					if ((dCh and dCh:GetAttribute("HakiInstinct")) or defender:GetAttribute("HakiInstinct")) and dProf and dProf.Haki and (tonumber(dProf.Haki.InstinctDodges) or 0) > 0 then
						dProf.Haki.InstinctDodges = math.max(0, (tonumber(dProf.Haki.InstinctDodges) or 0) - 1)
						defender:SetAttribute("InstinctDodges", dProf.Haki.InstinctDodges)
						if dCh then
							dCh:SetAttribute("InstinctDodges", dProf.Haki.InstinctDodges)
						end
						G.FireCombatEvent({
							kind = "DamageNumber",
							pos = dr.Position + Vector3.new(0, 2.5, 0),
							amount = 0,
							crit = false,
							element = "Sky",
							Text = "THẤU Ý NÉ! (" .. tostring(dProf.Haki.InstinctDodges) .. "/8)",
						})
						if R and R:FindFirstChild("CombatFX") then
							R.CombatFX:FireAllClients({
								Kind = "InstinctDodge",
								Action = "InstinctDodge",
								Position = dr.Position,
								DodgesLeft = dProf.Haki.InstinctDodges,
								MaxDodges = 8,
								Actor = defender.UserId,
							})
						end
						G.Sync(defender)
						continue
					end

					local defStats = G.Stats(defender)
					local defVal = (defStats and defStats.DEF) or 40
					local dmg = (tonumber(rawDamage) or 60) * 0.42 * (100 / (100 + defVal))
					local ft = tostring((dCh and dCh:GetAttribute("FruitTransform")) or defender:GetAttribute("FruitTransform") or "")
					local dTier = tonumber((dCh and dCh:GetAttribute("DragonFormTier")) or defender:GetAttribute("DragonFormTier")) or 0
					if ft ~= "" then
						dmg *= 0.42
					elseif dTier >= 2 then
						dmg *= 0.55
					elseif dTier == 1 then
						dmg *= 0.72
					end
					if defender:GetAttribute("RaceV4Active") == true or (dProf and dProf.RaceV4Active == true) then
						dmg *= 0.80
					end
					if (drt and now < (drt.ShieldUntil or 0)) or (dCh and (tonumber(dCh:GetAttribute("GuardianShieldUntil")) or 0) > workspace:GetServerTimeNow()) then
						dmg *= 0.35
					end
					dmg = math.max(8, math.floor(dmg))

					G.FireCombatEvent({
						kind = "DamageNumber",
						pos = dr.Position + Vector3.new(0, 2.2, 0),
						amount = dmg,
						crit = false,
						breakDmg = 0,
						element = "Lightning",
						Text = tostring(dmg) .. " PVP",
					})

					if areDuelingEachOther(attacker, defender) then
						if ActiveDuels[attacker] then
							ActiveDuels[attacker].DamageDealt = (ActiveDuels[attacker].DamageDealt or 0) + dmg
						end
						if dh.Health - dmg <= math.max(5, dh.MaxHealth * 0.04) then
							finishColosseumDuel(attacker, defender, "Knockout")
						else
							dh.Health = math.max(5, dh.Health - dmg)
						end
					else
						local tagUnix = os.time() + 30
						attacker:SetAttribute("PvPCombatUntil", tagUnix)
						defender:SetAttribute("PvPCombatUntil", tagUnix)
						if art then
							art.PvPCombatTagUntil = now + 30
						end
						if drt then
							drt.PvPCombatTagUntil = now + 30
							drt.LastPvPAttacker = attacker
							drt.LastPvPAttackedAt = now
						end
						if dh.Health - dmg <= 1 then
							settleOpenWorldPvPKO(attacker, defender, false)
						else
							dh.Health = math.max(1, dh.Health - dmg)
						end
					end
				end
			end
		end
	end
end

-- ============================================================================
-- 37. #114 - SKY CREW FLEET SYSTEM & LIVE SHIP BANNERS
-- ============================================================================
local Crews = {} -- [lowerName] = { Name, Tag, Color, CaptainUserId, Members = { [userId] = name } }
local PendingCrewInvites = {} -- [player] = { CrewKey = ..., CrewName = ..., Tag = ..., Color = ..., InviterName = ..., InviterId = ..., ExpiresAt = ... }

local function sanitizeText(raw, minLen, maxLen, fallback)
	local s = tostring(raw or ""):gsub("[%c]", ""):gsub("^%s+", ""):gsub("%s+$", "")
	if #s < minLen then
		return fallback
	end
	if #s > maxLen then
		s = string.sub(s, 1, maxLen)
	end
	return s
end

local function syncCrewOnlineMembers(crewKey)
	local crew = crewKey and Crews[crewKey]
	if not crew then
		return
	end
	for uid in pairs(crew.Members or {}) do
		local plr = Players:GetPlayerByUserId(tonumber(uid) or 0)
		if plr and plr.Parent == Players then
			if SocialEconomy.PushSnapshotToPlayer then
				SocialEconomy.PushSnapshotToPlayer(plr)
			end
			G.Sync(plr)
		end
	end
end

local function applyCrewAttributesToPlayer(p, prof)
	if not p or not prof then
		return
	end
	local cName = tostring(prof.CrewName or "")
	local cTag = tostring(prof.CrewTag or "")
	local cCol = tostring(prof.CrewColor or "255,215,90")
	p:SetAttribute("CrewName", cName)
	p:SetAttribute("CrewTag", cTag)
	p:SetAttribute("CrewColor", cCol)
	if p.Character then
		p.Character:SetAttribute("CrewName", cName)
		p.Character:SetAttribute("CrewTag", cTag)
		p.Character:SetAttribute("CrewColor", cCol)
	end
	if cName ~= "" then
		local key = string.lower(cName)
		Crews[key] = Crews[key] or {
			Name = cName,
			Tag = cTag ~= "" and cTag or "SKY",
			Color = cCol,
			CaptainUserId = p.UserId,
			Members = {},
		}
		Crews[key].Members[p.UserId] = p.DisplayName
	end
	if G and G.RefreshPlayerShipBanner then
		G.RefreshPlayerShipBanner(p)
	end
end

local function pruneCrewIfEmpty(crewKey)
	local c = crewKey and Crews[crewKey]
	if c and (type(c.Members) ~= "table" or next(c.Members) == nil) then
		Crews[crewKey] = nil
	end
end

function SocialEconomy.HandleCrewAction(p, payload)
	local prof = D and D.Get(p)
	if not prof then
		return false
	end
	payload = type(payload) == "table" and payload or {}
	local sub = tostring(payload.subAction or payload.mode or payload.crewAction or "CreateCrew")

	if sub == "CreateCrew" or sub == "Create" then
		local rawName = sanitizeText(payload.crewName or payload.name, 2, 24, p.DisplayName .. " Fleet")
		local rawTag = string.upper(sanitizeText(payload.crewTag or payload.tag, 2, 5, "SKY"):gsub("[^%w]", ""))
		if #rawTag < 2 then
			rawTag = "SKY"
		end
		local okName, filtName = LiveOps.FilterBroadcastText(p, rawName, 24)
		local okTag, filtTag = LiveOps.FilterBroadcastText(p, rawTag, 5)
		if not okName or not okTag or string.find(filtName, "#", 1, true) or string.find(filtTag, "#", 1, true) then
			G.Notify(p, "Tên hoặc Cờ hiệu Hạm Đội không hợp lệ qua bộ lọc ngôn từ an toàn!")
			return false
		end
		local name = sanitizeText(filtName, 2, 24, "")
		local tag = string.upper(sanitizeText(filtTag, 2, 5, ""):gsub("[^%w]", ""))
		if name == "" or #tag < 2 then
			G.Notify(p, "Tên Hạm Đội (2-24 ký tự) hoặc Cờ hiệu (2-5 ký tự chữ/số) chưa hợp lệ!")
			return false
		end
		local key = string.lower(name)
		local existingCrew = Crews[key]
		if existingCrew and existingCrew.CaptainUserId ~= p.UserId and next(existingCrew.Members or {}) ~= nil then
			G.Notify(p, "Tên Hạm Đội [" .. existingCrew.Name .. "] đã có Thuyền Trưởng khác sở hữu trong server!")
			return false
		end
		local oldName = tostring(prof.CrewName or "")
		local oldKey = string.lower(oldName)
		if oldName ~= "" and oldKey ~= key and Crews[oldKey] then
			Crews[oldKey].Members[p.UserId] = nil
			pruneCrewIfEmpty(oldKey)
		end
		local colorStr = sanitizeText(payload.crewColor or payload.color, 5, 15, "255,215,90")
		prof.CrewName = name
		prof.CrewTag = tag
		prof.CrewColor = colorStr
		Crews[key] = {
			Name = name,
			Tag = tag,
			Color = colorStr,
			CaptainUserId = p.UserId,
			Members = (existingCrew and existingCrew.Members) or {},
		}
		Crews[key].Members[p.UserId] = p.DisplayName
		applyCrewAttributesToPlayer(p, prof)
		SocialEconomy.CheckMilestones(p, prof)
		if D and D.Save then
			task.spawn(D.Save, p, false)
		end
		G.Notify(p, string.format("ĐÃ THÀNH LẬP HẠM ĐỘI SKY CREW: [%s] %s! Cờ hiệu đã treo lên Chiến Hạm 3D!", tag, name))
		syncCrewOnlineMembers(key)
		return true

	elseif sub == "InviteCrew" or sub == "Invite" then
		local curName = tostring(prof.CrewName or "")
		if curName == "" then
			G.Notify(p, "Hãy thành lập Hạm Đội Sky Crew trước khi mời thành viên!")
			return false
		end
		local key = string.lower(curName)
		local crew = Crews[key]
		if not crew then
			applyCrewAttributesToPlayer(p, prof)
			crew = Crews[key]
		end
		if not crew then
			return false
		end
		local targetId = tonumber(payload.targetUserId or payload.userId)
		local targetName = tostring(payload.targetName or payload.name or "")
		local targetPlr = nil
		for _, other in ipairs(Players:GetPlayers()) do
			if other ~= p and ((targetId and other.UserId == targetId) or (targetName ~= "" and (string.lower(other.Name) == string.lower(targetName) or string.lower(other.DisplayName) == string.lower(targetName)))) then
				targetPlr = other
				break
			end
		end
		if not targetPlr then
			for _, other in ipairs(Players:GetPlayers()) do
				if other ~= p and string.lower(tostring(other:GetAttribute("CrewName") or "")) ~= key then
					targetPlr = other
					break
				end
			end
		end
		if not targetPlr then
			G.Notify(p, "Không tìm thấy người chơi khác trong server để mời vào Hạm Đội!")
			return false
		end
		PendingCrewInvites[targetPlr] = {
			CrewKey = key,
			CrewName = crew.Name,
			Tag = crew.Tag,
			Color = crew.Color,
			InviterName = p.DisplayName,
			InviterId = p.UserId,
			ExpiresAt = os.clock() + 90,
		}
		G.Notify(p, "Đã gửi lời mời Hạm Đội [" .. crew.Tag .. "] " .. crew.Name .. " tới " .. targetPlr.DisplayName .. "!")
		G.Notify(targetPlr, p.DisplayName .. " mời bạn gia nhập Hạm Đội [" .. crew.Tag .. "] " .. crew.Name .. "!")
		if SocialEconomy.PushSnapshotToPlayer then
			SocialEconomy.PushSnapshotToPlayer(p)
			SocialEconomy.PushSnapshotToPlayer(targetPlr)
		end
		G.Sync(targetPlr)
		return true

	elseif sub == "Accept" or sub == "AcceptInvite" or sub == "JoinCrew" or sub == "Join" then
		local inv = PendingCrewInvites[p]
		if inv and os.clock() > (inv.ExpiresAt or 0) then
			PendingCrewInvites[p] = nil
			inv = nil
		end
		local crew = (inv and inv.CrewKey and Crews[inv.CrewKey]) or nil
		if not crew then
			G.Notify(p, "Lời mời Hạm Đội đã hết hạn hoặc bạn chưa nhận lời mời Hạm Đội!")
			return false
		end
		local oldName = tostring(prof.CrewName or "")
		local oldKey = string.lower(oldName)
		if oldName ~= "" and oldKey ~= string.lower(crew.Name) and Crews[oldKey] then
			Crews[oldKey].Members[p.UserId] = nil
			pruneCrewIfEmpty(oldKey)
			if Crews[oldKey] then
				syncCrewOnlineMembers(oldKey)
			end
		end
		PendingCrewInvites[p] = nil
		prof.CrewName = crew.Name
		prof.CrewTag = crew.Tag
		prof.CrewColor = crew.Color
		crew.Members[p.UserId] = p.DisplayName
		applyCrewAttributesToPlayer(p, prof)
		SocialEconomy.CheckMilestones(p, prof)
		if D and D.Save then
			task.spawn(D.Save, p, false)
		end
		G.Notify(p, string.format("Đã gia nhập Hạm Đội [%s] %s!", crew.Tag, crew.Name))
		syncCrewOnlineMembers(string.lower(crew.Name))
		return true

	elseif sub == "Decline" or sub == "DeclineInvite" or sub == "Reject" then
		local inv = PendingCrewInvites[p]
		PendingCrewInvites[p] = nil
		if inv and inv.InviterId then
			local invPlr = Players:GetPlayerByUserId(inv.InviterId)
			if invPlr and invPlr.Parent == Players then
				G.Notify(invPlr, p.DisplayName .. " đã từ chối lời mời gia nhập Hạm Đội.")
			end
		end
		G.Notify(p, "Đã từ chối lời mời gia nhập Hạm Đội.")
		if SocialEconomy.PushSnapshotToPlayer then
			SocialEconomy.PushSnapshotToPlayer(p)
		end
		G.Sync(p)
		return true

	elseif sub == "LeaveCrew" or sub == "Leave" then
		local oldName = tostring(prof.CrewName or "")
		local oldKey = string.lower(oldName)
		if oldName ~= "" and Crews[oldKey] then
			local c = Crews[oldKey]
			c.Members[p.UserId] = nil
			if c.CaptainUserId == p.UserId then
				local nextCap = nil
				for uid in pairs(c.Members) do
					nextCap = tonumber(uid)
					break
				end
				if nextCap then
					c.CaptainUserId = nextCap
				else
					Crews[oldKey] = nil
				end
			else
				pruneCrewIfEmpty(oldKey)
			end
		end
		prof.CrewName = ""
		prof.CrewTag = ""
		applyCrewAttributesToPlayer(p, prof)
		if D and D.Save then
			task.spawn(D.Save, p, false)
		end
		G.Notify(p, "Bạn đã rời khỏi Hạm Đội Sky Crew.")
		if oldKey ~= "" and Crews[oldKey] then
			syncCrewOnlineMembers(oldKey)
		end
		if SocialEconomy.PushSnapshotToPlayer then
			SocialEconomy.PushSnapshotToPlayer(p)
		end
		G.Sync(p)
		return true

	elseif sub == "KickMember" or sub == "Kick" then
		local curName = tostring(prof.CrewName or "")
		local key = string.lower(curName)
		local crew = curName ~= "" and Crews[key] or nil
		if not crew or crew.CaptainUserId ~= p.UserId then
			G.Notify(p, "Chỉ Thuyền Trưởng mới có quyền trục xuất thành viên khỏi Hạm Đội!")
			return false
		end
		local kickUid = tonumber(payload.targetUserId or payload.userId)
		local kickName = tostring(payload.targetName or payload.name or "")
		if not kickUid and kickName ~= "" then
			for uid, mName in pairs(crew.Members) do
				if tonumber(uid) ~= p.UserId and string.lower(tostring(mName)) == string.lower(kickName) then
					kickUid = tonumber(uid)
					break
				end
			end
		end
		if not kickUid or kickUid == p.UserId or not crew.Members[kickUid] then
			G.Notify(p, "Không tìm thấy thành viên cần mời rời Hạm Đội!")
			return false
		end
		local kickedLabel = tostring(crew.Members[kickUid])
		crew.Members[kickUid] = nil
		pruneCrewIfEmpty(key)
		local kickedPlr = Players:GetPlayerByUserId(kickUid)
		if kickedPlr and kickedPlr.Parent == Players then
			local kProf = D and D.Get(kickedPlr)
			if kProf then
				kProf.CrewName = ""
				kProf.CrewTag = ""
				applyCrewAttributesToPlayer(kickedPlr, kProf)
				if D and D.Save then
					task.spawn(D.Save, kickedPlr, false)
				end
			end
			G.Notify(kickedPlr, "Bạn đã được mời rời khỏi Hạm Đội [" .. crew.Tag .. "] " .. crew.Name .. ".")
			if SocialEconomy.PushSnapshotToPlayer then
				SocialEconomy.PushSnapshotToPlayer(kickedPlr)
			end
			G.Sync(kickedPlr)
		end
		G.Notify(p, "Đã mời " .. kickedLabel .. " rời khỏi Hạm Đội.")
		if Crews[key] then
			syncCrewOnlineMembers(key)
		end
		return true

	elseif sub == "UpdateColor" or sub == "SetColor" then
		local colorStr = sanitizeText(payload.crewColor or payload.color, 5, 15, "92,232,255")
		prof.CrewColor = colorStr
		local key = string.lower(tostring(prof.CrewName or ""))
		if Crews[key] then
			Crews[key].Color = colorStr
		end
		applyCrewAttributesToPlayer(p, prof)
		if D and D.Save then
			task.spawn(D.Save, p, false)
		end
		G.Notify(p, "Đã cập nhật màu cờ Hạm Đội Sky Crew!")
		if key ~= "" and Crews[key] then
			syncCrewOnlineMembers(key)
		else
			if SocialEconomy.PushSnapshotToPlayer then
				SocialEconomy.PushSnapshotToPlayer(p)
			end
			G.Sync(p)
		end
		return true
	end
	return false
end

-- ============================================================================
-- 39. #117 - INSPECT PLAYER CARD (FULL BUILD SNAPSHOT)
-- ============================================================================
function SocialEconomy.InspectPlayer(p, payload)
	payload = type(payload) == "table" and payload or {}
	local targetUid = tonumber(payload.targetUserId or payload.userId or payload.value) or p.UserId
	local targetPlr = Players:GetPlayerByUserId(targetUid) or p
	local prof = D and D.Get(targetPlr)
	if not prof then
		return false
	end

	local stats = G.Stats(targetPlr) or {}
	local weaponId = tostring(prof.Weapon or (prof.Equipped and prof.Equipped.Weapon) or "starter_sword")
	local weaponStars = (prof.WeaponStars and tonumber(prof.WeaponStars[weaponId])) or 1
	local weaponEnchant = (prof.WeaponEnchants and tostring(prof.WeaponEnchants[weaponId] or "")) or ""
	local fruitId = tostring(prof.EquippedFruit or "GaleCore")

	local card = {
		UserId = targetPlr.UserId,
		Name = targetPlr.Name,
		DisplayName = targetPlr.DisplayName,
		Level = tonumber(prof.Level) or 1,
		ClassId = tostring(prof.ClassId or "SkyGuardian"),
		Race = tostring(prof.Race or "Skyborn"),
		RaceTier = tonumber(prof.RaceTier) or 1,
		RaceV4Unlocked = prof.RaceV4Unlocked == true,
		Faction = tostring(prof.Faction or "Pirate"),
		Title = tostring(prof.Title or "sky_rookie"),
		Bounty = tonumber(prof.Bounty) or 0,
		Honor = tonumber(prof.Honor) or 0,
		CrewName = tostring(prof.CrewName or ""),
		CrewTag = tostring(prof.CrewTag or ""),
		CrewColor = tostring(prof.CrewColor or "255,215,90"),
		FightingStyle = tostring(prof.FightingStyle or "SkybornCombat"),
		EquippedFruit = fruitId,
		FruitMastery = (type(prof.Mastery) == "table" and tonumber(prof.Mastery[fruitId])) or 1,
		FruitAwakened = (prof.AwakenedFruits and prof.AwakenedFruits[fruitId] == true) or false,
		Weapon = weaponId,
		WeaponStars = weaponStars,
		WeaponEnhance = tonumber(prof.WeaponEnhance) or 0,
		WeaponEnchant = weaponEnchant,
		EquippedGun = tostring(prof.EquippedGun or "soul_guitar_void"),
		HakiStage = tonumber(prof.HakiStage) or 0,
		HakiColorId = tostring(prof.HakiColorId or "solar_gold"),
		KenV2Unlocked = prof.KenV2Unlocked == true,
		HighestSpireFloor = tonumber(prof.HighestSpireFloor) or 0,
		LeviathanHearts = tonumber(prof.LeviathanHearts) or 0,
		LoreCollected = countMapEntries(prof.CollectedLore),
		AchievementsUnlocked = countMapEntries(prof.Achievements),
		StatAlloc = prof.StatAlloc or {},
		CombatStats = {
			HP = stats.HP or 100,
			ATK = stats.ATK or 20,
			DEF = stats.DEF or 10,
			CritRate = stats.CritRate or 10,
			CritDmg = stats.CritDmg or 50,
		},
	}

	if R and R:FindFirstChild("StateUpdate") then
		R.StateUpdate:FireClient(p, { InspectCard = card })
	end
	return true
end

-- ============================================================================
-- 40. #120 - LIVE 3D HOLOGRAM LEADERBOARD MONUMENT AT SKY HUB PLAZA
-- ============================================================================
local TopBossDPSRecords = {} -- [userId] = { Name = displayName, BestDPS = number, TotalBossDmg = number, WindowDmg = number, WindowStart = clock }
local MAX_BOSS_DPS_RECORDS = 50
function SocialEconomy.GetTopBossDPSRecords()
	return TopBossDPSRecords
end
local LeaderboardLabels = {
	Level = {},
	Bounty = {},
	BossDPS = {},
}

local HALL_OF_FAME_LEGENDS = {
	{ Name = "Commander Lyra", Level = 2400, Bounty = 18500000, BossDPS = 48500 },
	{ Name = "Grand Monk Auron", Level = 2150, Bounty = 12400000, BossDPS = 36200 },
	{ Name = "Admiral Kairo", Level = 1650, Bounty = 7800000, BossDPS = 24800 },
	{ Name = "Starweaver Lumen", Level = 1100, Bounty = 4600000, BossDPS = 15400 },
	{ Name = "Shadowblitz Nyx", Level = 750, Bounty = 2900000, BossDPS = 9800 },
}

local function recordBossDamageForLeaderboard(p, dmgAmount)
	if not p or (tonumber(dmgAmount) or 0) <= 0 then
		return
	end
	local uid = p.UserId
	local now = os.clock()
	local rec = TopBossDPSRecords[uid]
	if not rec then
		local cnt = 0
		local worstUid, worstDps = nil, math.huge
		for k, v in pairs(TopBossDPSRecords) do
			cnt += 1
			local d = tonumber(v.BestDPS) or 0
			if not Players:GetPlayerByUserId(tonumber(k) or 0) and d < worstDps then
				worstUid, worstDps = k, d
			end
		end
		if cnt >= MAX_BOSS_DPS_RECORDS then
			if not worstUid then
				for k, v in pairs(TopBossDPSRecords) do
					local d = tonumber(v.BestDPS) or 0
					if d < worstDps then
						worstUid, worstDps = k, d
					end
				end
			end
			if worstUid ~= nil then
				TopBossDPSRecords[worstUid] = nil
			end
		end
		rec = {
			Name = p.DisplayName,
			BestDPS = 0,
			TotalBossDmg = 0,
			WindowDmg = 0,
			WindowStart = now,
		}
		TopBossDPSRecords[uid] = rec
	end
	rec.Name = p.DisplayName
	local prevBest = rec.BestDPS
	rec.TotalBossDmg += dmgAmount
	if (now - rec.WindowStart) > 5.0 then
		local prevDps = math.floor(rec.WindowDmg / math.max(1.0, math.min(5.0, now - rec.WindowStart)))
		if prevDps > rec.BestDPS then
			rec.BestDPS = prevDps
		end
		rec.WindowDmg = dmgAmount
		rec.WindowStart = now
	else
		rec.WindowDmg += dmgAmount
		local liveDps = math.floor(rec.WindowDmg / math.max(1.0, now - rec.WindowStart))
		if liveDps > rec.BestDPS then
			rec.BestDPS = liveDps
		end
	end
	if rec.BestDPS > prevBest then
		local prof = D and D.Get(p)
		if prof and rec.BestDPS > (tonumber(prof.HighestBossDPS) or 0) then
			prof.HighestBossDPS = rec.BestDPS
		end
		LiveOps.RecordLeaderboardScore(p, "BossDPS", rec.BestDPS, false)
	end
end

local function formatCompactNum(n)
	n = math.floor(tonumber(n) or 0)
	if n >= 1000000 then
		return string.format("%.2fM", n / 1000000)
	elseif n >= 10000 then
		return string.format("%.1fK", n / 1000)
	end
	return tostring(n)
end

local function updateLeaderboardMonument()
	local lvEntries = {}
	local bountyEntries = {}
	local dpsEntries = {}

	for _, plr in ipairs(Players:GetPlayers()) do
		local prof = D and D.Get(plr)
		if prof then
			local dName = plr.DisplayName
			local lv = tonumber(prof.Level) or 1
			local bty = math.max(tonumber(prof.Bounty) or 0, tonumber(prof.Honor) or 0)
			local rec = TopBossDPSRecords[plr.UserId]
			local bestDps = (rec and rec.BestDPS) or math.floor((tonumber(G.Stats(plr) and G.Stats(plr).ATK) or 25) * 1.8)
			table.insert(lvEntries, { Name = dName .. " [LIVE]", Value = lv })
			table.insert(bountyEntries, { Name = dName .. " [LIVE]", Value = bty })
			table.insert(dpsEntries, { Name = dName .. " [LIVE]", Value = bestDps })
		end
	end

	for _, leg in ipairs(HALL_OF_FAME_LEGENDS) do
		table.insert(lvEntries, { Name = leg.Name, Value = leg.Level })
		table.insert(bountyEntries, { Name = leg.Name, Value = leg.Bounty })
		table.insert(dpsEntries, { Name = leg.Name, Value = leg.BossDPS })
	end

	local function sortDesc(a, b)
		return a.Value > b.Value
	end
	table.sort(lvEntries, sortDesc)
	table.sort(bountyEntries, sortDesc)
	table.sort(dpsEntries, sortDesc)

	for i = 1, 5 do
		local lblL = LeaderboardLabels.Level[i]
		if lblL and lblL.Parent and lvEntries[i] then
			lblL.Text = string.format("#%d  %s  -  Lv.%d", i, lvEntries[i].Name, lvEntries[i].Value)
		end
		local lblB = LeaderboardLabels.Bounty[i]
		if lblB and lblB.Parent and bountyEntries[i] then
			lblB.Text = string.format("#%d  %s  -  %s", i, bountyEntries[i].Name, formatCompactNum(bountyEntries[i].Value))
		end
		local lblD = LeaderboardLabels.BossDPS[i]
		if lblD and lblD.Parent and dpsEntries[i] then
			lblD.Text = string.format("#%d  %s  -  %s DPS", i, dpsEntries[i].Name, formatCompactNum(dpsEntries[i].Value))
		end
	end
end

local function buildSkyHubLeaderboardMonument()
	local worldObjects = getWorldObjects()
	local old = worldObjects:FindFirstChild("SkyHubLeaderboardMonument")
	if old then
		old:Destroy()
	end

	local raw = Vector3.new(-308.0, 46.5, 557.1)
	local fy = safeFloorY(raw, 46.5)
	local basePos = Vector3.new(raw.X, fy, raw.Z)

	local m = Instance.new("Model")
	m.Name = "SkyHubLeaderboardMonument"
	m.Parent = worldObjects

	local dais = W.Part(m, "MonumentBase", Vector3.new(17.5, 1.2, 3.8), basePos + Vector3.new(0, 0.6, 0), Color3.fromRGB(34, 40, 56), Enum.Material.Marble)
	local trim = W.Part(m, "GoldTrim", Vector3.new(18.0, 0.25, 4.1), basePos + Vector3.new(0, 1.28, 0), Color3.fromRGB(242, 198, 78), Enum.Material.Metal)
	trim.CanCollide = false
	m.PrimaryPart = dais

	LeaderboardLabels = { Level = {}, Bounty = {}, BossDPS = {} }

	local boards = {
		{ Key = "Level", OffsetX = -5.6, Title = "TOP LEVEL", Accent = Color3.fromRGB(92, 236, 255) },
		{ Key = "Bounty", OffsetX = 0.0, Title = "TOP RENOWN", Accent = Color3.fromRGB(255, 212, 84) },
		{ Key = "BossDPS", OffsetX = 5.6, Title = "TOP BOSS DPS", Accent = Color3.fromRGB(214, 118, 255) },
	}

	for _, b in ipairs(boards) do
		local panel = W.Part(m, "HoloBoard_" .. b.Key, Vector3.new(5.1, 6.2, 0.28), basePos + Vector3.new(b.OffsetX, 4.6, 0), Color3.fromRGB(18, 24, 38), Enum.Material.Glass)
		panel.Transparency = 0.18
		panel.CanCollide = false

		for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
			local sg = Instance.new("SurfaceGui")
			sg.Name = "BoardGui_" .. tostring(face.Name)
			sg.Face = face
			sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
			sg.PixelsPerStud = 48
			sg.LightInfluence = 0
			sg.Brightness = 1.4
			sg.Parent = panel

			local bg = Instance.new("Frame")
			bg.Size = UDim2.fromScale(1, 1)
			bg.BackgroundColor3 = Color3.fromRGB(14, 18, 30)
			bg.BackgroundTransparency = 0.15
			bg.BorderSizePixel = 0
			bg.Parent = sg

			local stroke = Instance.new("UIStroke")
			stroke.Color = b.Accent
			stroke.Thickness = 3
			stroke.Parent = bg

			local header = Instance.new("TextLabel")
			header.Size = UDim2.new(1, -12, 0.18, 0)
			header.Position = UDim2.new(0, 6, 0.02, 0)
			header.BackgroundTransparency = 1
			header.Font = Enum.Font.GothamBlack
			header.TextScaled = true
			header.TextColor3 = b.Accent
			header.Text = "SKYBREAK • " .. b.Title
			header.Parent = bg

			for row = 1, 5 do
				local rl = Instance.new("TextLabel")
				rl.Size = UDim2.new(1, -16, 0.14, 0)
				rl.Position = UDim2.new(0, 8, 0.18 + (row - 1) * 0.155, 0)
				rl.BackgroundColor3 = (row == 1) and Color3.fromRGB(36, 44, 68) or Color3.fromRGB(22, 28, 44)
				rl.BackgroundTransparency = 0.25
				rl.BorderSizePixel = 0
				rl.Font = (row == 1) and Enum.Font.GothamBlack or Enum.Font.GothamBold
				rl.TextScaled = true
				rl.TextColor3 = (row == 1) and b.Accent or Color3.fromRGB(235, 242, 255)
				rl.TextXAlignment = Enum.TextXAlignment.Left
				rl.Text = "  #" .. row .. "  ---"
				rl.Parent = bg
				if face == Enum.NormalId.Front then
					LeaderboardLabels[b.Key][row] = rl
				else
					-- Mirror Front text changes onto Back automatically
					LeaderboardLabels[b.Key][row]:GetPropertyChangedSignal("Text"):Connect(function()
						rl.Text = LeaderboardLabels[b.Key][row].Text
					end)
				end
			end
		end
	end

	updateLeaderboardMonument()
end

-- ============================================================================
-- 41. #129 - STUDIO-ONLY DEV SANDBOX TESTING COMMAND HANDLER
-- ============================================================================
local DevTeleportCursor = {}

function SocialEconomy.HandleDevSandbox(p, payload)
	if not DevGate.IsAllowed(p) then
		return false
	end
	local prof = D and D.Get(p)
	local rt = G and G.Runtime[p]
	local pr, ph = root(p)
	if not prof or not rt then
		return false
	end
	payload = type(payload) == "table" and payload or { subCommand = payload }
	local sub = tostring(payload.subAction or payload.subCommand or payload.devAction or payload.mode or payload.cmd or payload.value or "FullFury")

	if sub == "FullFury" or sub == "FullFuryHP" then
		prof.AwakeningMeter = 100
		rt.FuryMeter = 100
		prof.RaceV4Unlocked = true
		prof.RaceTier = 4
		rt.Energy = 100
		rt.Stamina = 100
		if prof.Haki then
			prof.Haki.InstinctDodges = 8
		end
		if ph then
			local s = G.Stats(p)
			if s and s.HP then
				ph.MaxHealth = s.HP
			end
			ph.Health = ph.MaxHealth
		end
		G.Notify(p, "[DEV SANDBOX] Full Fury: 100% HP, Energy, Stamina, Ascension Fury & Will Sense Dodges!")
		G.Sync(p)
		return true

	elseif sub == "ZeroCooldowns" then
		rt.ZeroCooldowns = not (rt.ZeroCooldowns == true)
		rt.Cooldowns = {}
		p:SetAttribute("ZeroCooldowns", rt.ZeroCooldowns)
		G.Notify(p, "[DEV SANDBOX] Zero Cooldowns: " .. (rt.ZeroCooldowns and "BẬT (0s Cooldown mọi kỹ năng!)" or "TẮT"))
		G.Sync(p)
		return true

	elseif sub == "SpawnBoss" then
		local bossId = tostring(payload.bossId or "CryonPrime")
		if pr then
			local spawnPos = pr.Position + pr.CFrame.LookVector * 20 + Vector3.new(0, 2, 0)
			if bossId == "AureonSentinel" and (not G.Boss or not G.Boss.Alive) then
				G.StartBoss({ p })
				G.Teleport(p, Vector3.new(0, 50.5, -275))
			else
				G.SpawnEnemy(bossId, spawnPos, false, true)
			end
			G.Notify(p, "[DEV SANDBOX] Đã triệu hồi Boss [" .. bossId .. "]!")
		end
		return true

	elseif sub == "TeleportIsland" or sub == "Teleport" then
		local islId = tostring(payload.islandId or payload.id or "")
		local targetIsl = ISLAND_BY_ID[islId]
		if not targetIsl then
			local idx = ((DevTeleportCursor[p] or 0) % #ISLAND_DIRECTORY) + 1
			DevTeleportCursor[p] = idx
			targetIsl = ISLAND_DIRECTORY[idx]
		end
		if targetIsl then
			prof.UnlockedWorlds = prof.UnlockedWorlds or {}
			prof.UnlockedWorlds[targetIsl.Realm] = true
			p:SetAttribute("CurrentRealm", targetIsl.Realm)
			local fy = safeFloorY(targetIsl.Pos, targetIsl.Pos.Y - 1.5)
			G.Teleport(p, Vector3.new(targetIsl.Pos.X, fy + 3.5, targetIsl.Pos.Z))
			G.Notify(p, "[DEV SANDBOX] Teleport Island -> " .. targetIsl.Name .. " (" .. targetIsl.Realm .. ")!")
			G.Sync(p)
			return true
		end

	elseif sub == "UnlockAll" or sub == "UnlockFullSave" or sub == "GrantMaxTestKit" then
		prof.Level = C.MaxLevel or 2550
		prof.Mastery = prof.Mastery or {}
		for _, fid in ipairs(ALL_CANONICAL_FRUITS) do
			prof.Mastery[fid] = 600
		end
		for _, sid in ipairs(ALL_FIGHTING_STYLES) do
			prof.Mastery[sid] = 600
		end
		prof.XP = 0
		prof.Gold = math.max(prof.Gold or 0, 25000000)
		prof.CoreShards = math.max(prof.CoreShards or 0, 75000)
		prof.Bounty = math.max(prof.Bounty or 0, 12500000)
		prof.Honor = math.max(prof.Honor or 0, 12500000)
		prof.StatPoints = (prof.Level - 1) * 3
		prof.WeaponEnhance = 15
		prof.HakiStage = 5
		prof.KenV2Unlocked = true
		prof.RaceV4Unlocked = true
		prof.RaceTier = 4
		prof.PartySize = "Squad"

		prof.StoredFruits = prof.StoredFruits or {}
		prof.AwakenedFruits = prof.AwakenedFruits or {}
		for _, fid in ipairs(ALL_CANONICAL_FRUITS) do
			prof.StoredFruits[fid] = math.max(2, prof.StoredFruits[fid] or 0)
			prof.AwakenedFruits[fid] = true
		end
		prof.UnlockedStyles = prof.UnlockedStyles or {}
		for _, sid in ipairs(ALL_FIGHTING_STYLES) do
			prof.UnlockedStyles[sid] = true
		end
		prof.Inventory = prof.Inventory or {}
		prof.WeaponStars = prof.WeaponStars or {}
		for _, wid in ipairs(ALL_SWORDS_AND_GUNS) do
			prof.Inventory[wid] = math.max(1, prof.Inventory[wid] or 0)
			prof.WeaponStars[wid] = 5
		end
		prof.Inventory.EnchantScroll = math.max(20, prof.Inventory.EnchantScroll or 0)
		prof.Inventory.LeviathanHeart = math.max(3, prof.Inventory.LeviathanHeart or 0)
		prof.LeviathanHearts = math.max(3, prof.LeviathanHearts or 0)

		prof.UnlockedHakiColors = prof.UnlockedHakiColors or {}
		for _, cid in ipairs(ALL_HAKI_COLORS) do
			prof.UnlockedHakiColors[cid] = true
		end
		prof.UnlockedWorlds = type(prof.UnlockedWorlds) == "table" and prof.UnlockedWorlds or {}
		for _, isl in ipairs(ISLAND_DIRECTORY) do
			if type(isl.Realm) == "string" and isl.Realm ~= "" then
				prof.UnlockedWorlds[isl.Realm] = true
			end
			if type(isl.Id) == "string" and isl.Id ~= "" then
				prof.UnlockedWorlds[isl.Id] = true
			end
		end
		if G.EnsureProfileFields then
			G.EnsureProfileFields(prof)
		end
		G.SyncCompanions(p)
		SocialEconomy.CheckMilestones(p, prof)
		restoreFullVitals(p)
		G.Notify(p, "[DEV SANDBOX] UNLOCK ALL: Lv.2550, 12 Awakened Cores, 6 Styles, 5-Star +15 Weapons, Stage 5 Will Armor, Ascension & All Worlds!")
		G.Sync(p)
		return true

	elseif sub == "SpawnShip" then
		local shipId = tostring(payload.shipId or "CelestialAetherGalleon")
		if G.SpawnWarship then
			G.SpawnWarship(p, shipId)
		else
			G.BuildSkyShip(p, nil, shipId)
		end
		return true

	elseif sub == "TriggerMirage" then
		if G.SpawnMirageIsland then
			G.SpawnMirageIsland(p)
			return true
		end

	elseif sub == "TriggerLeviathan" then
		if G.SpawnSeaMonsterEvent then
			G.SpawnSeaMonsterEvent(p, "AbyssalLeviathan")
			return true
		elseif pr then
			G.SpawnEnemy("AbyssalLeviathan", pr.Position + Vector3.new(0, 2, -28), false, true)
			return true
		end

	elseif sub == "InspectSelf" then
		return SocialEconomy.InspectPlayer(p, { targetUserId = p.UserId })
	end

	return false
end

-- ============================================================================
-- LIVE SNAPSHOT HELPER FOR GAMESERVICE.SYNC & UISTATEUPDATED
-- ============================================================================
local LastAutoUIPushAt = {}

function SocialEconomy.GetSnapshotForPlayer(p)
	if not p or p.Parent ~= Players then
		return nil
	end
	local prof = D and D.Get(p)
	if not prof then
		return nil
	end
	ensureDailyState(p, prof)
	local discovered = ensureDiscoveredIslands(prof)
	local today = math.floor(os.time() / 86400)
	local claimedDay = getProfileLastDailyClaimDay(prof)
	local claimedToday = (claimedDay == today)

	local dailyBountiesList = {}
	for i, item in ipairs((prof.DailyTasks and prof.DailyTasks.List) or {}) do
		if type(item) == "table" then
			local goal = math.max(1, math.floor(tonumber(item.Goal or item.Count) or 1))
			table.insert(dailyBountiesList, {
				Id = tostring(item.Id or ("Bounty_" .. i)),
				Kind = tostring(item.Kind or "Kill"),
				Title = tostring(item.Title or ("Nhiệm Vụ Ngày #" .. i)),
				Progress = math.clamp(math.floor(tonumber(item.Progress) or 0), 0, goal),
				Count = goal,
				Goal = goal,
				Gold = math.max(0, math.floor(tonumber(item.Gold) or 2500)),
				Shards = math.max(0, math.floor(tonumber(item.Shards) or 120)),
				Claimed = (item.Claimed == true),
			})
		end
	end

	local streak = math.clamp(math.floor(tonumber(prof.LoginStreak) or 1), 1, 7)
	local dailyLogin = {
		Streak = streak,
		CanClaim = not claimedToday,
		ClaimedToday = claimedToday,
		DailyClaimed = tonumber(prof.DailyClaimed) or 0,
		LastDailyClaimDay = claimedDay,
		AllBonusClaimed = (prof.DailyTasks and prof.DailyTasks.BonusClaimed == true) or false,
		Tasks = dailyBountiesList,
	}

	-- PartyData (never reset active party to "Solo")
	local pid = PlayerPartyId[p]
	local party = pid and Parties[pid]
	local partyMembersList = {}
	if party then
		for _, m in ipairs(party.Members) do
			if m and m.Parent == Players then
				local mp = D and D.Get(m)
				local _, mh = root(m)
				table.insert(partyMembersList, {
					UserId = m.UserId,
					Name = m.Name,
					DisplayName = m.DisplayName,
					Level = (mp and tonumber(mp.Level)) or 1,
					ClassId = tostring((mp and mp.ClassId) or "SkyGuardian"),
					HP = mh and math.floor(mh.Health) or 100,
					MaxHP = mh and math.max(1, math.floor(mh.MaxHealth)) or 100,
					IsLeader = (party.Leader == m),
				})
			end
		end
	end
	local effectivePartySize = tostring(prof.PartySize or "Solo")
	if party and effectivePartySize == "Solo" then
		effectivePartySize = (#partyMembersList <= 2) and "Duo" or "Squad"
	end

	local now = os.clock()
	local pendingPartyInv = nil
	local pinv = PendingPartyInvites[p]
	if pinv then
		if now < (pinv.ExpiresAt or 0) and Parties[pinv.PartyId] then
			pendingPartyInv = {
				PartyId = pinv.PartyId,
				LeaderName = pinv.LeaderName,
				LeaderId = pinv.LeaderId,
			}
		else
			PendingPartyInvites[p] = nil
		end
	end

	local leaderUid = (party and party.Leader and party.Leader.UserId) or 0
	local partyData = {
		PartyId = pid or "",
		LeaderId = leaderUid,
		Mode = effectivePartySize,
		PartySize = effectivePartySize,
		MaxSize = 6,
		Members = partyMembersList,
		PendingInvite = pendingPartyInv,
		PendingInviteFrom = pendingPartyInv and pendingPartyInv.LeaderName or nil,
	}

	-- CrewData
	local crewName = tostring(prof.CrewName or "")
	local crewTag = tostring(prof.CrewTag or "")
	local crewColor = tostring(prof.CrewColor or "255,215,90")
	local crewKey = crewName ~= "" and string.lower(crewName) or ""
	local crew = crewKey ~= "" and Crews[crewKey] or nil
	if crewName ~= "" and not crew then
		applyCrewAttributesToPlayer(p, prof)
		crew = Crews[crewKey]
	end
	local captainUid = (crew and tonumber(crew.CaptainUserId)) or (crewName ~= "" and p.UserId or 0)
	local crewMembersList = {}
	local totalBounty = 0
	if crew and type(crew.Members) == "table" then
		for uid, mName in pairs(crew.Members) do
			local numUid = tonumber(uid) or 0
			local mPlr = numUid > 0 and Players:GetPlayerByUserId(numUid) or nil
			local mProf = mPlr and D and D.Get(mPlr) or nil
			local mBounty = mProf and math.max(tonumber(mProf.Bounty) or 0, tonumber(mProf.Honor) or 0) or 0
			totalBounty += mBounty
			local isCap = (numUid == captainUid)
			table.insert(crewMembersList, {
				UserId = numUid,
				Name = mPlr and mPlr.DisplayName or tostring(mName),
				DisplayName = mPlr and mPlr.DisplayName or tostring(mName),
				Role = isCap and "Captain" or "Member",
				IsCaptain = isCap,
				Bounty = mBounty,
			})
		end
		table.sort(crewMembersList, function(a, b)
			if a.IsCaptain ~= b.IsCaptain then
				return a.IsCaptain
			end
			return (a.Bounty or 0) > (b.Bounty or 0)
		end)
	end

	local pendingCrewInv = nil
	local cinv = PendingCrewInvites[p]
	if cinv then
		if now < (cinv.ExpiresAt or 0) and cinv.CrewKey and Crews[cinv.CrewKey] then
			pendingCrewInv = {
				CrewName = cinv.CrewName,
				Tag = cinv.Tag,
				Color = cinv.Color,
				InviterName = cinv.InviterName,
				InviterId = cinv.InviterId,
			}
		else
			PendingCrewInvites[p] = nil
		end
	end

	local crewData = {
		InCrew = (crewName ~= ""),
		CrewId = crewKey,
		Name = crewName,
		Tag = crewTag,
		Color = crewColor,
		TotalBounty = totalBounty,
		LeaderId = captainUid,
		Members = crewMembersList,
		PendingInvite = pendingCrewInv,
	}

	return {
		CrewData = crewData,
		PartyData = partyData,
		DailyLogin = dailyLogin,
		DailyBounties = dailyBountiesList,
		DailyTasks = dailyBountiesList,
		DiscoveredIslands = discovered,
		PartyId = pid or "",
		PartyLeaderId = leaderUid,
		PartyMembers = partyMembersList,
		PartySize = effectivePartySize,
		PendingPartyInvite = pendingPartyInv,
		CrewName = crewName,
		CrewTag = crewTag,
		CrewColor = crewColor,
		PendingCrewInvite = pendingCrewInv,
		LoginStreak = streak,
	}
end

function SocialEconomy.PushSnapshotToPlayer(p)
	if not p or p.Parent ~= Players then
		return nil
	end
	local snap = SocialEconomy.GetSnapshotForPlayer(p)
	if not snap then
		return nil
	end
	LastAutoUIPushAt[p] = os.clock()
	local uiEv = getSharedUIStateUpdatedRemote()
	if uiEv then
		uiEv:FireClient(p, snap)
	end
	return snap
end

-- ============================================================================
-- UNIFIED SOCIAL & ECONOMY UI REQUEST ROUTER
-- ============================================================================
local SOCIAL_ECONOMY_COMMANDS = {
	EnchantWeapon = true,
	RollWeaponEnchant = true,
	ClaimDailyReward = true,
	ClaimDaily = true,
	ClaimDailyLogin = true,
	ClaimBountyReward = true,
	ClaimDailyBounty = true,
	BuyVoidMerchant = true,
	BuyVoidMerchantItem = true,
	RepeatQuest = true,
	SetAutoRepeatQuest = true,
	PartyAction = true,
	InviteParty = true,
	SetPartyMode = true,
	TogglePvP = true,
	DuelAction = true,
	JoinColosseum1v1 = true,
	CrewAction = true,
	InspectPlayer = true,
	DevSandbox = true,
}

function SocialEconomy.HandleUIRequest(p, cmd, payload)
	payload = type(payload) == "table" and payload or { value = payload }
	if cmd == "EnchantWeapon" or cmd == "RollWeaponEnchant" then
		return SocialEconomy.EnchantEquippedWeapon(p, payload.weaponId or payload.itemId)
	elseif cmd == "ClaimBountyReward" or cmd == "ClaimDailyBounty" then
		return SocialEconomy.ClaimBountyReward(p, payload)
	elseif cmd == "ClaimDailyReward" or cmd == "ClaimDaily" or cmd == "ClaimDailyLogin" then
		return SocialEconomy.ClaimDailyReward(p, payload)
	elseif cmd == "BuyVoidMerchant" or cmd == "BuyVoidMerchantItem" then
		return SocialEconomy.BuyVoidMerchantItem(p, payload.itemId or payload.id, payload.currency, payload.autoEquip)
	elseif cmd == "RepeatQuest" or cmd == "SetAutoRepeatQuest" then
		return SocialEconomy.RepeatQuest(p, payload)
	elseif cmd == "PartyAction" then
		return SocialEconomy.HandlePartyAction(p, payload)
	elseif cmd == "InviteParty" then
		payload.subAction = "Invite"
		return SocialEconomy.HandlePartyAction(p, payload)
	elseif cmd == "SetPartyMode" then
		payload.subAction = "SetMode"
		return SocialEconomy.HandlePartyAction(p, payload)
	elseif cmd == "TogglePvP" then
		return SocialEconomy.TogglePvP(p, payload.enabled)
	elseif cmd == "DuelAction" or cmd == "JoinColosseum1v1" then
		local mode = tostring(payload.mode or payload.subAction or (cmd == "JoinColosseum1v1" and "Queue1v1" or "Practice"))
		if mode == "Leave" and ActiveDuels[p] then
			finishColosseumDuel(ActiveDuels[p].Opponent, p, "Forfeit")
			return true
		elseif mode == "Queue1v1" or mode == "Join1v1" or mode == "Matchmake" then
			return queueColosseum1v1(p)
		end
		return startSoloPracticeColosseumDuel(p)
	elseif cmd == "CrewAction" then
		return SocialEconomy.HandleCrewAction(p, payload)
	elseif cmd == "InspectPlayer" then
		return SocialEconomy.InspectPlayer(p, payload)
	elseif cmd == "DevSandbox" then
		return SocialEconomy.HandleDevSandbox(p, payload)
	end
	return false
end

-- ============================================================================
-- SERVICE INITIALIZATION & DETERMINISTIC GAME SERVICE HOOKS
-- ============================================================================
local function getEquippedEnchant(prof)
	if not prof or type(prof.WeaponEnchants) ~= "table" then
		return nil
	end
	local wid = tostring(prof.Weapon or (prof.Equipped and prof.Equipped.Weapon) or "")
	if wid == "" then
		return nil
	end
	return prof.WeaponEnchants[wid]
end

function SocialEconomy.Init(gameSvc, dataSvc, worldSvc, configSvc)
	if SocialEconomy._initialized then
		return
	end
	SocialEconomy._initialized = true

	G, D, W, C = gameSvc, dataSvc, worldSvc, configSvc
	local okCombatData, combatData = pcall(function()
		return require(game:GetService("ReplicatedStorage").Shared.SkybreakCombatData)
	end)
	if okCombatData then CombatData = combatData end
	R = ReplicatedStorage:WaitForChild("Remotes")

	SocialEconomy.ApplyPvPHitCheck = applyPlayerVsPlayerHitCheck
	G.SocialEconomy = SocialEconomy
	G.BroadcastWorldBanner = SocialEconomy.BroadcastWorldBanner
	G.GetPartyPlayers = SocialEconomy.GetPartyPlayers
	G.AreInSameParty = SocialEconomy.AreInSameParty
	G.OnCombatAoE = SocialEconomy.OnCombatAoE
	G.CheckMilestones = SocialEconomy.CheckMilestones
	G.AdvanceDailyTask = SocialEconomy.AdvanceDailyTask

	-- 1. Build 3D World Objects & Interactive Infrastructure (LoreTablets built last so clearance scan sees all objects)
	buildHomePointCrystalAnchors()
	buildDestructibleWorldProps()
	buildArcaneEnchanterPedestal()
	build4TierTreasureChests()
	buildQuickQuestBoards()
	buildSkyColosseumDuelRing()
	buildSkyHubLeaderboardMonument()
	rotateVoidMerchant(false)
	build30LoreTablets()

	-- 2. Hook G.Stats (#103 SolarCrit +12 CritRate, +30 CritDmg & ChronoHaste attribute)
	local origStats = G.Stats
	G.Stats = function(p)
		local s = origStats(p)
		if not s then
			return s
		end
		local prof = D.Get(p)
		local ench = getEquippedEnchant(prof)
		if ench == "SolarCrit" then
			s.CritRate = math.min(95, (s.CritRate or 10) + 12)
			s.CritDmg = (s.CritDmg or 50) + 30
		end
		p:SetAttribute("ActiveWeaponEnchant", ench or "")
		return s
	end

	-- 3. Hook G.Hit (#103 Vampiric 8% Lifesteal, ChainVolt 2-Target Arc, ArmorBreaker +22% Dmg/+12 Break & #120 Boss DPS Record)
	local origHit = G.Hit
	local inChainVolt = false
	G.Hit = function(p, e, damage, breakPower, action)
		if not e or not e.Alive then
			return origHit(p, e, damage, breakPower, action)
		end
		local prof = D.Get(p)
		local ench = getEquippedEnchant(prof)
		if ench == "ArmorBreaker" then
			damage = (tonumber(damage) or 0) * 1.22
			breakPower = (tonumber(breakPower) or 0) + 12
		end

		local hpBefore = tonumber(e.HP) or 0
		origHit(p, e, damage, breakPower, action)
		local dealt = math.max(0, hpBefore - (tonumber(e.HP) or 0))

		if dealt > 0 then
			if ActiveDuels[p] and ActiveDuels[p].AIEnemy == e then
				ActiveDuels[p].DamageDealt = (ActiveDuels[p].DamageDealt or 0) + dealt
			end
			local isDummy = (e.Id == "DPSTrainingDummy") or (e.IsDPSDummy == true) or (e.Config and e.Config.IsTrainingDummy == true)
			local isBoss = not isDummy and ((e == G.Boss) or (e.Config and e.Config.Boss) or e.Id == "CryonPrime" or e.Id == "Noxar" or e.Id == "AbyssalLeviathan" or e.Id == "SoulReaperRift")
			if isBoss then
				recordBossDamageForLeaderboard(p, dealt)
			end

			if ench == "Vampiric" then
				local _, ph = root(p)
				if ph and ph.Health > 0 and ph.Health < ph.MaxHealth then
					local heal = math.max(2, math.floor(dealt * 0.08))
					ph.Health = math.min(ph.MaxHealth, ph.Health + heal)
					if G.Runtime[p] and G.Runtime[p].HP then
						G.Runtime[p].HP = ph.Health
					end
				end
			elseif ench == "ChainVolt" and not inChainVolt and e.Body then
				inChainVolt = true
				local jumps = 0
				for _, other in ipairs(G.Enemies or {}) do
					if other ~= e and other.Alive and other.Body and other.Model and other.Model.Parent and other.Id ~= "DPSTrainingDummy" then
						if (other.Body.Position - e.Body.Position).Magnitude <= 18 then
							jumps += 1
							origHit(p, other, math.max(8, damage * 0.38), 4, "ChainVolt")
							if jumps >= 2 then
								break
							end
						end
					end
				end
				inChainVolt = false
			end
		end
	end

	-- 4. Hook G.Kill (#102 Fair >=15% MaxHP / Party <=160-stud Shared Boss Credit, #106 Daily Bounties, #113 Solo AI Duel Victory, #107 Milestones)
	local origKill = G.Kill
	G.Kill = function(e)
		if not e or not e.Alive then
			return origKill(e)
		end

		local deathPos = (e.Body and e.Body.Position) or e.Home
		local maxHP = math.max(1, tonumber(e.MaxHP) or 1)
		local isBossOrElite = (e == G.Boss)
			or (e.Config and (e.Config.Boss or e.Config.Elite))
			or (e.Model and e.Model:GetAttribute("IsBoss") == true)
			or e.Id == "CryonPrime"
			or e.Id == "Noxar"
			or e.Id == "AureonSentinel"
			or e.Id == "SkySeaBeast"
			or e.Id == "AbyssalLeviathan"
			or e.Id == "SoulReaperRift"
			or e.Id == "OrderCyborgBoss"
			or e.Id == "ShrineGuardianBoss"
			or e.Id == "AetherArchonBoss"
			or e.Id == "PirateCaptainVance"
			or e.Id == "SunshardHighPriest"
			or e.Id == "PermafrostWardenBoss"
			or e.Id == "UmbralArchfiendBoss"
			or e.Id == "SkyHubWatchCommander"
			or e.Id == "Sylvaris"
			or e.Id == "Ignivar"
			or e.Id == "Nerith"
			or e.Id == "Aion"
			or e.Id == "Veyr"

		-- Snapshot contributors BEFORE origKill runs so we know who origKill already rewarded (<95 studs) vs who qualifies via >=15% MaxHP or Co-op Party <=160 studs!
		local snapContribs = {}
		local origRewarded = {}
		local qualifiedParties = {}
		for plr, hit in pairs(e.Contributors or {}) do
			if plr and plr.Parent == Players then
				snapContribs[plr] = { Damage = hit.Damage or 0, Time = hit.Time or 0 }
				local pr = root(plr)
				local partOk = (not e.Party) or (e.Party[plr] == true)
				if pr and (os.clock() - (hit.Time or 0) < 45) and (pr.Position - deathPos).Magnitude < 95 and partOk then
					origRewarded[plr] = true
				end
				if (hit.Damage or 0) >= (maxHP * 0.15) or origRewarded[plr] then
					local pid = PlayerPartyId[plr]
					if pid then
						qualifiedParties[pid] = true
					end
				end
			end
		end

		-- Check if this enemy was a Solo Practice Colosseum AI Duelist
		local colosseumOwner = e.ColosseumTarget

		origKill(e)

		if colosseumOwner and ActiveDuels[colosseumOwner] and ActiveDuels[colosseumOwner].AIEnemy == e then
			finishColosseumDuel(colosseumOwner, nil, "Defeated AI Champion")
		end

		-- Grant Fair >=15% Damage OR Co-op Party <=160-stud Shared Boss/Mob Credit to anyone origKill missed!
		local eligibleAll = {}
		for plr in pairs(origRewarded) do
			eligibleAll[plr] = "orig"
		end
		for plr, hit in pairs(snapContribs) do
			if not eligibleAll[plr] and (hit.Damage >= maxHP * 0.15) then
				eligibleAll[plr] = "extra"
			end
		end
		for pid in pairs(qualifiedParties) do
			local party = Parties[pid]
			if party then
				for _, member in ipairs(party.Members) do
					if member and member.Parent == Players and not eligibleAll[member] then
						local mr = root(member)
						if mr and (mr.Position - deathPos).Magnitude <= 160 then
							eligibleAll[member] = "party"
						end
					end
				end
			end
		end

		for plr, mode in pairs(eligibleAll) do
			local prof = D.Get(plr)
			if prof then
				if mode ~= "orig" then
					local shards = isBossOrElite and 120 or 12
					prof.Inventory = prof.Inventory or {}
					if e.Config and e.Config.Drop then
						prof.Inventory[e.Config.Drop] = (prof.Inventory[e.Config.Drop] or 0) + 1
					end
					if isBossOrElite then
						prof.Inventory.SunshardCore = (prof.Inventory.SunshardCore or 0) + 2
						prof.Inventory.CoreEssence = (prof.Inventory.CoreEssence or 0) + 1
						prof.Bounty = (prof.Bounty or 2500000) + 15000
						prof.Honor = (prof.Honor or 2500000) + 15000
						G.Notify(plr, "CHIA SẺ CHIẾN CÔNG BOSS/CO-OP [" .. tostring(e.Config and e.Config.Name or e.Id) .. "]: Full EXP, Drop & +15,000 Điểm Danh Vọng (Renown)!")
					end
					G.Reward(plr, (e.Config and e.Config.XP) or 0, (e.Config and e.Config.Gold) or 0, shards)
					G.QuestEvent(plr, "Kill", e.Id)
				end

				SocialEconomy.AdvanceDailyTask(plr, "Kill", 1)
				if isBossOrElite then
					SocialEconomy.AdvanceDailyTask(plr, "Boss", 1)
				end
				SocialEconomy.CheckMilestones(plr, prof)
			end
		end
	end

	-- 5. Hook G.Reward (#101 Smooth Lv.1->2550 Progression Curve + #111 Co-op Party +15% Shared Bonus + #107 Milestones)
	local origReward = G.Reward
	local inPartyBonusShare = false
	G.Reward = function(p, xp, gold, shards, minTargetLevel)
		local prof = D.Get(p)
		if prof then
			local xpMult, goldMult = SocialEconomy.GetSmoothProgressionMultiplier(prof.Level)
			local partyPlayers = SocialEconomy.GetPartyPlayers(p)
			if #partyPlayers > 1 then
				xpMult *= 1.15
				goldMult *= 1.15
			end
			xp = math.floor((tonumber(xp) or 0) * xpMult)
			gold = math.floor((tonumber(gold) or 0) * goldMult)
		end

		origReward(p, xp, gold, shards, minTargetLevel)

		if prof then
			SocialEconomy.CheckMilestones(p, prof)
		end

		-- Share 35% ambient Co-op Party EXP/Gold with nearby party members within 160 studs on non-boss actions/quests
		if not inPartyBonusShare and p then
			local pr = root(p)
			local partyPlayers = SocialEconomy.GetPartyPlayers(p)
			if pr and #partyPlayers > 1 and (tonumber(xp) or 0) > 0 then
				inPartyBonusShare = true
				for _, ally in ipairs(partyPlayers) do
					if ally ~= p then
						local ar = root(ally)
						if ar and (ar.Position - pr.Position).Magnitude <= 160 then
							origReward(ally, math.max(1, math.floor(xp * 0.25)), math.max(1, math.floor((tonumber(gold) or 0) * 0.25)), 0)
						end
					end
				end
				inPartyBonusShare = false
			end
		end
	end

	-- 6. Hook G.Action & G.UseSlotMove (#68 Destructible Props AoE, #103 ChronoHaste -15% CD, #129 ZeroCooldowns, #112/#113 PvP & Colosseum Duel)
	local function postAbilityEffects(p, actionKey, approxRange, approxMult)
		local pr = root(p)
		local rt = G.Runtime[p]
		local prof = D.Get(p)
		if not pr or not rt then
			return
		end
		if rt.ZeroCooldowns then
			rt.Cooldowns = {}
			rt.ActionUntil = 0
		elseif getEquippedEnchant(prof) == "ChronoHaste" and actionKey and rt.Cooldowns[actionKey] then
			local rem = rt.Cooldowns[actionKey] - os.clock()
			if rem > 0 then
				rt.Cooldowns[actionKey] = os.clock() + rem * 0.85
			end
		end

		local look = pr.CFrame.LookVector
		local aoeCenter = pr.Position + look * 4.5
		SocialEconomy.OnCombatAoE(p, aoeCenter, math.max(10, approxRange or 12))

		if (os.clock() - (rt._LastPvPHitCastAt or 0)) > 0.08 then
			local stats = G.Stats(p)
			local rawDmg = ((stats and stats.ATK) or 45) * (approxMult or 1.25)
			applyPlayerVsPlayerHitCheck(p, pr.Position, look, approxRange or 14, rawDmg, tostring(actionKey or "Attack"))
		end
	end

	-- Dau vet "chieu da thuc su ra": cooldown/nhip M1 bi dat lai trong luc goi. Truoc day postAbilityEffects
	-- (sat thuong PvP + ChronoHaste -15% CD) chay ca khi chieu dang hoi => spam remote 15-20 lan/giay.
	local function castMarker(rt, keys)
		if not rt then
			return ""
		end
		local cds = type(rt.Cooldowns) == "table" and rt.Cooldowns or {}
		local parts = { tostring(rt.NextStyleM1At) }
		for _, k in ipairs(keys) do
			parts[#parts + 1] = tostring(cds[k])
		end
		return table.concat(parts, "|")
	end

	local origAction = G.Action
	G.Action = function(p, action, payload)
		local rt = G.Runtime[p]
		if rt and rt.ZeroCooldowns then
			rt.Cooldowns = {}
		end
		local actKeys = { tostring(action), "Attack", "Heavy", "GunM1", "ChargedCrescentSlash" }
		local before = castMarker(rt, actKeys)
		origAction(p, action, payload)
		if castMarker(G.Runtime[p], actKeys) == before then
			return
		end
		if action ~= "Dodge" and action ~= "Dash" and action ~= "FlashStep" then
			local cfg = C.Actions and C.Actions[action]
			postAbilityEffects(p, action, (cfg and cfg.Range) or 13, (cfg and cfg.Multiplier) or 1.1)
		end
	end

	local function resolveSlotMoveSpec(p, prof, k)
		local slot = math.clamp(tonumber(prof and prof.ActiveSlot) or 2, 1, 4)
		local activeCfg = nil
		if slot == 1 then
			local sid = tostring((prof and prof.FightingStyle) or "SkybornCombat")
			activeCfg = (C.FightingStyles and C.FightingStyles[sid]) or (CombatData and CombatData.Styles and CombatData.Styles[sid])
		elseif slot == 2 then
			local rawF = tostring((prof and prof.EquippedFruit) or "SolarTitanCore")
			local fid = (Helpers.ResolveFruitId(rawF) ~= "" and Helpers.ResolveFruitId(rawF)) or rawF
			activeCfg = (C.AetherFruits and C.AetherFruits[fid]) or (C.Fruits and C.Fruits[fid])
		elseif slot == 3 then
			local wid = tostring((prof and prof.Weapon) or "dawnbringer_sword")
			activeCfg = (C.Swords and C.Swords[wid]) or (C.Items and C.Items[wid])
		else
			local gid = tostring((prof and prof.EquippedGun) or "soul_guitar_void")
			activeCfg = (C.Guns and C.Guns[gid]) or (C.Items and C.Items[gid])
		end
		local spec = nil
		if activeCfg and type(activeCfg.Moves) == "table" then
			spec = activeCfg.Moves[k]
			if not spec then
				for _, m in pairs(activeCfg.Moves) do
					if type(m) == "table" and string.upper(tostring(m.Key or "")) == k then
						spec = m
						break
					end
				end
			end
		end
		local mult = tonumber(spec and (spec.Mult or spec.Multiplier)) or ((k == "V" and 2.4) or (k == "C" and 1.8) or (k == "X" and 1.45) or 1.2)
		local rng = tonumber(spec and spec.Range) or ((k == "V" and 34) or (k == "C" and 28) or (k == "X" and 24) or 20)
		local ft = p.Character and p.Character:GetAttribute("FruitTransform")
		if ft == "SolarTitan" or ft == "AbyssalSovereign" then
			rng = math.min(95, rng * 2.0)
		end
		return rng, mult
	end

	local origUseSlotMove = G.UseSlotMove
	G.UseSlotMove = function(p, key, payload)
		local rt = G.Runtime[p]
		if rt and rt.ZeroCooldowns then
			rt.Cooldowns = {}
		end
		local k = string.upper(tostring(key or "Z"))
		local before = castMarker(rt, { "Slot_" .. k })
		origUseSlotMove(p, key, payload)
		if castMarker(G.Runtime[p], { "Slot_" .. k }) == before then
			return
		end
		local rng, mult = resolveSlotMoveSpec(p, D.Get(p), k)
		postAbilityEffects(p, "Slot_" .. k, rng, mult)
	end

	-- 7. Hook G.Equipment (#116 WorldBanner on Mythical Roll, #106 ClaimDaily; ForgeEnhance handled by GameService C.GetForgeUpgradeCost)
	local origEquipment = G.Equipment
	G.Equipment = function(p, payload)
		if type(payload) == "table" then
			local act = payload.action
			local prof = D.Get(p)
			if act == "ClaimBountyReward" or act == "ClaimDailyBounty" then
				SocialEconomy.ClaimBountyReward(p, payload)
				return
			elseif act == "ClaimDaily" or act == "ClaimDailyReward" then
				SocialEconomy.ClaimDailyReward(p, payload)
				return
			elseif act == "RepeatQuest" then
				SocialEconomy.RepeatQuest(p, payload)
				return
			elseif act == "EnchantWeapon" then
				SocialEconomy.EnchantEquippedWeapon(p, payload.weaponId or payload.itemId)
				return
			end

			local prevMythCounts = nil
			if act == "RollFruit" and prof and prof.StoredFruits then
				prevMythCounts = {}
				for fid in pairs(MYTHICAL_FRUITS) do
					prevMythCounts[fid] = tonumber(prof.StoredFruits[fid]) or 0
				end
			end
			origEquipment(p, payload)

			if prof then
				if act == "RollFruit" then
					local rolled = tostring(prof.HeldFruit or "")
					local gainedMythical = false
					if rolled ~= "" and MYTHICAL_FRUITS[rolled] and prevMythCounts then
						gainedMythical = (tonumber(prof.StoredFruits and prof.StoredFruits[rolled]) or 0) > (prevMythCounts[rolled] or 0)
					end
					if gainedMythical then
						local fName = (C.AetherFruits and C.AetherFruits[rolled] and C.AetherFruits[rolled].Name)
							or (C.Fruits and C.Fruits[rolled] and C.Fruits[rolled].Name)
							or rolled
						SocialEconomy.BroadcastWorldBanner(
							"LÕI THẦN THOẠI XUẤT THẾ!",
							p.DisplayName .. " vừa cầu trúng Lõi MYTHICAL [" .. fName .. "] tại Điện Cầu Lõi!",
							"MythicalDrop"
						)
					end
				end
				SocialEconomy.CheckMilestones(p, prof)
			end
			return
		end
		return origEquipment(p, payload)
	end

	-- 8. Hook G.Interact (#116 WorldBanner when picking up a Mythical Fruit Pedestal)
	local origInteract = G.Interact
	G.Interact = function(p, id, extra)
		local prof = D.Get(p)
		local beforeCount = 0
		if prof and type(id) == "string" and string.sub(id, 1, 14) == "FruitPedestal_" then
			for fid in pairs(MYTHICAL_FRUITS) do
				beforeCount += (tonumber(prof.StoredFruits and prof.StoredFruits[fid]) or 0)
			end
		end
		origInteract(p, id, extra)
		if prof and type(id) == "string" and string.sub(id, 1, 14) == "FruitPedestal_" then
			local afterCount = 0
			local gainedFid = nil
			for fid in pairs(MYTHICAL_FRUITS) do
				local c = tonumber(prof.StoredFruits and prof.StoredFruits[fid]) or 0
				afterCount += c
				if c > 0 then
					gainedFid = fid
				end
			end
			if afterCount > beforeCount and gainedFid then
				local fName = (C.AetherFruits and C.AetherFruits[gainedFid] and C.AetherFruits[gainedFid].Name)
					or (C.Fruits and C.Fruits[gainedFid] and C.Fruits[gainedFid].Name)
					or gainedFid
				SocialEconomy.BroadcastWorldBanner(
					"LÕI MYTHICAL TRÊN ĐẢO ĐƯỢC TÌM THẤY!",
					p.DisplayName .. " vừa thu thập Lõi Thần Thoại [" .. fName .. "] ngoài thế giới!",
					"MythicalDrop"
				)
			end
		end
	end

	-- 9. Hook G.Character (#62 HomeIsland persistent respawn, #106 Daily Login init, #114 Crew Banner sync, Island Discovery)
	local origCharacter = G.Character
	G.Character = function(p, ch)
		local prof = D.Get(p)
		if prof then
			ensureDailyState(p, prof)
			ensureDiscoveredIslands(prof)
			if type(prof.HomeIsland) == "string" and prof.HomeIsland ~= "" and not p:GetAttribute("RespawnPos") then
				local homeIsl = ISLAND_BY_ID[prof.HomeIsland]
				if homeIsl then
					local fy = safeFloorY(homeIsl.Pos, homeIsl.Pos.Y - 1.5)
					local spawnPos = Vector3.new(homeIsl.Pos.X, fy + 2.5, homeIsl.Pos.Z)
					p:SetAttribute("RespawnPos", spawnPos)
					p:SetAttribute("RespawnRealm", homeIsl.Realm)
				end
			end
		end
		origCharacter(p, ch)
		local rt = G.Runtime[p]
		if prof and rt then
			if typeof(p:GetAttribute("RespawnPos")) == "Vector3" then
				rt.CustomRespawnPos = p:GetAttribute("RespawnPos")
			end
			applyCrewAttributesToPlayer(p, prof)
			SocialEconomy.CheckIslandDiscovery(p)
			SocialEconomy.CheckMilestones(p, prof)
			SocialEconomy.PushSnapshotToPlayer(p)
		end
	end

	-- Apply initial state to any players already in server
	for _, plr in ipairs(Players:GetPlayers()) do
		local prof = D.Get(plr)
		if prof then
			ensureDailyState(plr, prof)
			ensureDiscoveredIslands(prof)
			applyCrewAttributesToPlayer(plr, prof)
			SocialEconomy.CheckIslandDiscovery(plr)
			SocialEconomy.CheckMilestones(plr, prof)
			SocialEconomy.PushSnapshotToPlayer(plr)
		end
	end

	-- 10. Hook G.OnBeforeSync (Expose all Wave 3 Economy, Social, Party, Crew, PvP, Daily, Discovery & Achievement state)
	local prevBeforeSync = G.OnBeforeSync
	G.OnBeforeSync = function(p, profile, rt, stats, statePayload)
		if prevBeforeSync then
			prevBeforeSync(p, profile, rt, stats, statePayload)
		end
		local snap = SocialEconomy.GetSnapshotForPlayer(p)
		if snap then
			for k, v in pairs(snap) do
				statePayload[k] = v
			end
			local now = os.clock()
			if (now - (LastAutoUIPushAt[p] or 0)) >= 0.25 then
				LastAutoUIPushAt[p] = now
				local uiEv = getSharedUIStateUpdatedRemote()
				if uiEv then
					uiEv:FireClient(p, snap)
				end
			end
		end

		statePayload.EnhancePity = tonumber(profile.EnhancePity) or 0
		statePayload.WeaponEnchants = profile.WeaponEnchants or {}
		statePayload.HomeIsland = tostring(profile.HomeIsland or "SkyHub")
		statePayload.Achievements = profile.Achievements or {}
		statePayload.CollectedLore = profile.CollectedLore or {}
		statePayload.HighestSpireFloor = tonumber(profile.HighestSpireFloor) or 0
		statePayload.LeviathanHearts = tonumber(profile.LeviathanHearts) or 0
		statePayload.PvPEnabled = (p:GetAttribute("PvPEnabled") == true)
		statePayload.InSafeZone = (p:GetAttribute("InSafeZone") == true)
		statePayload.PvPShieldUntil = tonumber(p:GetAttribute("PvPShieldUntil")) or 0
		statePayload.PvPCombatUntil = tonumber(p:GetAttribute("PvPCombatUntil")) or 0
		statePayload.InColosseumDuel = (ActiveDuels[p] ~= nil)
		statePayload.VoidMerchantIsland = tostring(workspace:GetAttribute("VoidMerchantIsland") or "")
	end

	-- 11. Chain G.HandleUIRequest
	local prevHandleUI = G.HandleUIRequest
	G.HandleUIRequest = function(p, cmd, payload)
		if SOCIAL_ECONOMY_COMMANDS[cmd] then
			return SocialEconomy.HandleUIRequest(p, cmd, payload)
		end
		if prevHandleUI then
			return prevHandleUI(p, cmd, payload)
		end
		return false
	end

	-- 12. Player Disconnect Cleanup & Combat-Log Settlement (before D.Release)
	function SocialEconomy.OnBeforePlayerRelease(p, rtOverride)
		if not p or CombatLogSettled[p] then
			return
		end
		CombatLogSettled[p] = os.clock()
		local rt = rtOverride or (G and G.Runtime[p])
		local tagUnix = tonumber(p:GetAttribute("PvPCombatUntil")) or 0
		if not ActiveDuels[p] and (tagUnix > os.time() or (rt and os.clock() < (rt.PvPCombatTagUntil or 0))) then
			local lastAttacker = rt and rt.LastPvPAttacker or nil
			if lastAttacker and lastAttacker.Parent ~= Players then
				lastAttacker = nil
			end
			settleOpenWorldPvPKO(lastAttacker, p, true)
		end
		local prof = D and D.Get(p)
		local cName = prof and tostring(prof.CrewName or "") or tostring(p:GetAttribute("CrewName") or "")
		if cName ~= "" then
			local cKey = string.lower(cName)
			local c = Crews[cKey]
			if c and type(c.Members) == "table" then
				local anyOnline = false
				for uid in pairs(c.Members) do
					local numUid = tonumber(uid) or 0
					if numUid ~= p.UserId then
						local mPlr = Players:GetPlayerByUserId(numUid)
						if mPlr and mPlr.Parent == Players then
							anyOnline = true
							break
						end
					end
				end
				if not anyOnline then
					Crews[cKey] = nil
				end
			end
		end
	end

	Players.PlayerRemoving:Connect(function(p)
		SocialEconomy.OnBeforePlayerRelease(p, G and G.Runtime[p])
		CombatLogSettled[p] = nil
		local oldPid = PlayerPartyId[p]
		removePlayerFromParty(p, p.DisplayName .. " đã ngắt kết nối khỏi Tổ Đội.")
		PendingPartyInvites[p] = nil
		PendingCrewInvites[p] = nil
		LastAutoUIPushAt[p] = nil
		local now = os.clock()
		for invPlr, inv in pairs(PendingPartyInvites) do
			if invPlr.Parent ~= Players or now > (inv.ExpiresAt or 0) or (oldPid and inv.PartyId == oldPid and not Parties[oldPid]) then
				PendingPartyInvites[invPlr] = nil
			end
		end
		for invPlr, cinv in pairs(PendingCrewInvites) do
			if invPlr.Parent ~= Players or now > (cinv.ExpiresAt or 0) or (cinv.InviterId == p.UserId) then
				PendingCrewInvites[invPlr] = nil
			end
		end
		DevTeleportCursor[p] = nil
		if ActiveDuels[p] then
			finishColosseumDuel(ActiveDuels[p].Opponent, p, "Disconnect")
		end
	end)

	-- 13. Periodic World & Social Heartbeat (1s SafeZone/Compass/Discovery/Duel check, 5s Leaderboard, 10m Void Merchant)
	task.spawn(function()
		local nextLeaderboardAt = os.clock() + 5
		local nextMerchantRotateAt = os.clock() + 600
		while true do
			task.wait(1.0)
			local now = os.clock()
			local nowUnix = os.time()

			for _, plr in ipairs(Players:GetPlayers()) do
				local pr, ph = root(plr)
				local duel = ActiveDuels[plr]
				if duel and (not pr or not ph or ph.Health <= 1) then
					finishColosseumDuel(duel.Opponent, plr, "Knockout")
				elseif pr then
					local inSafe = false
					if not duel then
						if (tonumber(plr:GetAttribute("PvPCombatUntil")) or 0) <= nowUnix then
							inSafe = isPositionInSafeZone(pr.Position)
						end
					else
						-- Ring-out check for active 1v1 Sky Colosseum duelists
						if flatDist(pr.Position, COLOSSEUM_CENTER) > (COLOSSEUM_RADIUS + 8) then
							finishColosseumDuel(duel.Opponent, plr, "Ring Out")
						elseif duel.IsPracticeAI and duel.AIEnemy and (not duel.AIEnemy.Alive or not duel.AIEnemy.Model or not duel.AIEnemy.Model.Parent) then
							finishColosseumDuel(plr, nil, "Defeated AI Champion")
						end
					end
					if plr:GetAttribute("InSafeZone") ~= inSafe then
						plr:SetAttribute("InSafeZone", inSafe)
					end
					SocialEconomy.CheckIslandDiscovery(plr)
					updatePlayerQuestCompass(plr)
				end
			end

			if now >= nextLeaderboardAt then
				nextLeaderboardAt = now + 5
				updateLeaderboardMonument()
			end

			if now >= nextMerchantRotateAt then
				nextMerchantRotateAt = now + 600
				for k, expAt in pairs(PvPFarmCooldown) do
					if now >= expAt then
						PvPFarmCooldown[k] = nil
					end
				end
				for k, expAt in pairs(ColosseumFarmCooldown) do
					if now >= expAt then
						ColosseumFarmCooldown[k] = nil
					end
				end
				for k, expAt in pairs(PracticeFarmCooldown) do
					if now >= expAt then
						PracticeFarmCooldown[k] = nil
					end
				end
				rotateVoidMerchant(true)
			end
		end
	end)
end

return SocialEconomy
