-- SKYBREAK: Fragments of the Core — Unified 9-Tab 3D NPC Vendors, Hero Showcase & 4x4 Trading Hub ([N])
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/NPCShop.lua
-- Visual Upgrade: Matches Figma File 3 (SKYBREAK_NPC_01..05) 1:1 with glossy 6-rarity tiles & live 3D vendor busts.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SkyShared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(SkyShared:WaitForChild("Config"):WaitForChild("Theme"))
local RarityConfig = require(SkyShared:WaitForChild("Config"):WaitForChild("RarityConfig"))
local AEC = require(SkyShared:WaitForChild("Config"):WaitForChild("ArsenalExpansionConfig"))
local MonetizationConfig = require(SkyShared:WaitForChild("Config"):WaitForChild("MonetizationConfig"))
local UIState = require(SkyShared:WaitForChild("Types"):WaitForChild("UIState"))
local VC = AEC.VendorCatalogs

local CoreShared = ReplicatedStorage:FindFirstChild("Shared")
local CoreConfig = CoreShared and CoreShared:FindFirstChild("Config") and require(CoreShared.Config) or {}
local SharedCombatData = CoreShared and CoreShared:FindFirstChild("SkybreakCombatData") and require(CoreShared.SkybreakCombatData) or nil

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Store = require(script.Parent.Parent:WaitForChild("Store"))
local HttpService = game:GetService("HttpService")
local ScreenRouter = require(script.Parent.Parent:WaitForChild("ScreenRouter"))
local I18n = require(script.Parent.Parent:WaitForChild("I18n"))
local PremiumPanel = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumPanel"))
local PremiumButton = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumButton"))
local ViewportOrbit = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("ViewportOrbit"))

local u2, u2o, u2s = UDim2.new, UDim2.fromOffset, UDim2.fromScale
local v2, v3, cfNew, cfAng = Vector2.new, Vector3.new, CFrame.new, CFrame.Angles
local rgb, c3w = Color3.fromRGB, Color3.new(1, 1, 1)
local pick, fmt, uiCreate = I18n.Pick, UIFactory.FormatNumber, UIFactory.Create
local TXC, TXL = Enum.TextXAlignment.Center, Enum.TextXAlignment.Left
local TC = Theme.Colors
local GOLD, GOLDB, SAPPH = TC.ACCENT_GOLD, TC.ACCENT_GOLD_BRIGHT, TC.ACCENT_SAPPHIRE
local SUCC, DANG, VOIDP = TC.SUCCESS, TC.DANGER, TC.VOID_PURPLE
local TEXT1, TEXT2, STEEL = TC.TEXT_PRIMARY, TC.TEXT_SECONDARY, TC.STROKE_STEEL

local NPCShop = { Refs = {}, Orbits = {}, BustConns = {}, PassConns = {}, TickerAlive = false, LiveMirageStock = nil, LastMirageReqSeed = nil, MirageBound = false }

local VENDOR_TABS = {
	{ "MirageDealer", "Fruit", "LÕI 1H • HƯ QUANG", "1H PHANTOM STOCK" },
	{ "SwordDealer", "Sword", "KIẾM SƯ 3D", "3D SWORD DEALER" },
	{ "GunDealer", "Gun", "SÚNG & THẦN GIÁP", "GUNS & 3D ARMOR" },
	{ "MartialDojo", "Fist", "7 VÕ ĐƯỜNG", "7 MARTIAL DOJOS" },
	{ "EnchanterAndChronos", "CoreShards", "PHÙ PHÉP & CHỢ ĐEN", "ENCHANT & VOID" },
	{ "Shipwright", "Ship", "XƯỞNG TÀU 3D", "3D SHIPWRIGHT" },
	{ "DrVegaAndTempleV4", "Wing", "TỘC & ĐỀN THĂNG HOA", "RACE & ASCENSION" },
	{ "TradingTable", "Trade", "GIAO DỊCH 4X4", "4X4 CORE TRADE" },
	{ "ColosseumAndSpire", "Trophy", "ĐẤU TRƯỜNG & 50F", "ARENA & 50F SPIRE" },
	{ "RobuxPasses", "RobuxGem", "ĐẶC QUYỀN ROBUX", "ROBUX PASSES" },
}

local PALETTE = {
	Common = { rgb(75, 94, 120), rgb(30, 41, 59), rgb(148, 168, 196), "COMMON" },
	Uncommon = { rgb(22, 189, 136), rgb(8, 92, 68), rgb(110, 242, 190), "UNCOMMON" },
	Rare = { rgb(56, 189, 248), rgb(29, 78, 216), rgb(147, 224, 255), "RARE" },
	Epic = { rgb(192, 132, 252), rgb(91, 33, 182), rgb(228, 184, 255), "EPIC" },
	Legendary = { rgb(252, 211, 77), rgb(180, 83, 9), rgb(255, 242, 166), "LEGENDARY" },
	Mythic = { rgb(251, 113, 133), rgb(147, 51, 234), rgb(255, 182, 212), "MYTHIC" },
}
PALETTE.Mythical = PALETTE.Mythic

local function mkBox(parent, name, pos, size, bg, radius, strokeCol, strokeTh, strokeTr, z, order)
	local f = uiCreate("Frame", parent, {
		Name = name, Position = pos or u2o(0, 0), Size = size or u2s(1, 1),
		BackgroundColor3 = bg or rgb(10, 16, 30), BackgroundTransparency = bg and 0 or 1,
		BorderSizePixel = 0, ZIndex = z, LayoutOrder = order,
	})
	if radius then
		if radius >= 999 then UIFactory.PillCorner(f) else UIFactory.Corner(f, radius) end
	end
	if strokeCol then UIFactory.Stroke(f, strokeCol, strokeTh or 1.2, strokeTr or 0.25) end
	return f
end

local function mkText(parent, name, txt, pos, size, ts, col, bold, xAlign, wrap, z)
	return UIFactory.Label(parent, {
		Name = name, Text = tostring(txt or ""), Position = pos or u2o(0, 0), Size = size or u2s(1, 1),
		TextSize = ts or 11, TextColor = col or TEXT1, Bold = bold ~= false,
		XAlign = xAlign or TXL, YAlign = wrap and Enum.TextYAlignment.Top or Enum.TextYAlignment.Center,
		Truncate = wrap and Enum.TextTruncate.None or Enum.TextTruncate.AtEnd, Wrapped = wrap == true, ZIndex = z,
	})
end

local function mkBtn(parent, name, label, variant, pos, size, fn, opts)
	opts = opts or {}
	return PremiumButton.Create(parent, {
		name = name, icon = opts.icon, label = tostring(label or ""), variant = variant or "gold",
		selected = opts.selected, disabled = opts.disabled == true, position = pos, size = size,
		textSize = opts.ts or 11, minTextSize = opts.minTs or 9, layoutOrder = opts.order, onActivated = fn,
	})
end

local function mkSplitPanels(body, lName, lTitle, rName, rTitle, bottomPad)
	local hOff = bottomPad or 0
	local lp = PremiumPanel.Create(body, { name = lName, title = lTitle, position = u2o(0, 0), size = u2(0.49, -6, 1, -hOff) })
	local rp = PremiumPanel.Create(body, { name = rName, variant = "gold", title = rTitle, position = u2(0.49, 6, 0, 0), size = u2(0.51, -6, 1, -hOff) })
	return lp, rp
end

local function fPill(st, key, val, lbl, w, actVar)
	local act = (st[key] == val)
	return {
		lbl = lbl, act = act, var = act and (actVar or "gold") or "secondary", w = w or 160,
		fn = function() st[key] = val; NPCShop.RebuildWorkspace() end,
	}
end

local function selFn(st, key, val)
	return function(reb) st[key] = val; if reb then NPCShop.RebuildWorkspace() end end
end

local function getRarityStyle(rarityId)
	local key = tostring(rarityId or "Common")
	if PALETTE[key] then return PALETTE[key] end
	local low = string.lower(key)
	if low:find("myth") then return PALETTE.Mythic
	elseif low:find("legend") then return PALETTE.Legendary
	elseif low:find("epic") then return PALETTE.Epic
	elseif low:find("rare") then return PALETTE.Rare
	elseif low:find("uncommon") then return PALETTE.Uncommon end
	return PALETTE.Common
end

local function makeGlossyRarityTile(parent, rarityId, topTag, bottomTag, iconKind, sizeUDim2, opts)
	opts = opts or {}
	local pal = getRarityStyle(rarityId)
	local zB = opts.ZIndex or 4
	local tile = uiCreate("Frame", parent, {
		Name = opts.Name or "Tile", Position = opts.Position or u2o(8, 8),
		Size = sizeUDim2 or u2o(84, 86), AnchorPoint = opts.AnchorPoint or Vector2.zero,
		BackgroundColor3 = c3w, BorderSizePixel = 0, LayoutOrder = opts.LayoutOrder or 0, ZIndex = zB,
	})
	UIFactory.Corner(tile, opts.Radius or 10)
	UIFactory.Stroke(tile, pal[3], opts.Selected and 2.2 or 1.5, opts.Selected and 0.02 or 0.12)
	uiCreate("UIGradient", tile, { Color = ColorSequence.new(pal[1], pal[2]), Rotation = 90 })

	mkBox(tile, "Sheen", u2o(2, 2), u2(1, -4, 0.40, 0), c3w, 8, nil, nil, nil, zB + 1).BackgroundTransparency = 0.84

	local dSz = opts.DiscSize or 46
	local disc = uiCreate("Frame", tile, {
		Name = "Disc", AnchorPoint = v2(0.5, 0.5), Position = u2(0.5, 0, 0.45, 0),
		Size = u2o(dSz, dSz), BackgroundColor3 = pal[3], BackgroundTransparency = 0.78, BorderSizePixel = 0, ZIndex = zB + 1,
	})
	UIFactory.PillCorner(disc)
	UIFactory.Stroke(disc, c3w, 1, 0.65)

	local function badge(nm, txt, anc, pos, bgCol, tr)
		local p = uiCreate("Frame", tile, {
			Name = nm, AnchorPoint = anc, Position = pos, Size = u2o(0, 15), AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = bgCol, BackgroundTransparency = tr or 0, BorderSizePixel = 0, ZIndex = zB + 3,
		})
		UIFactory.Corner(p, 4)
		UIFactory.Padding(p, 0, 5, 0, 5)
		mkText(p, "T", txt, nil, u2o(0, 15), 8, c3w, true, nil, false, zB + 4).AutomaticSize = Enum.AutomaticSize.X
	end

	if topTag and #tostring(topTag) > 0 then badge("TopP", topTag, Vector2.zero, u2o(4, 4), rgb(9, 13, 24), 0.14) end
	if opts.RightTag and #tostring(opts.RightTag) > 0 then
		badge("RightP", opts.RightTag, v2(1, 0), u2(1, -4, 0, 4), (opts.RightColor or rgb(16, 185, 129)):Lerp(rgb(9, 13, 24), 0.35), 0)
	end

	local iPx = opts.IconSize or 30
	UIFactory.Icon(tile, iconKind or "Star", u2(0.5, -math.floor(iPx * 0.5), 0.45, -math.floor(iPx * 0.5)), iPx, c3w).ZIndex = zB + 3

	local bBar = uiCreate("Frame", tile, {
		Name = "BotBar", AnchorPoint = v2(0.5, 1), Position = u2(0.5, 0, 1, -4),
		Size = u2(1, -8, 0, opts.SubCaption and 28 or 18), BackgroundColor3 = rgb(9, 13, 24),
		BackgroundTransparency = 0.08, BorderSizePixel = 0, ZIndex = zB + 3,
	})
	UIFactory.Corner(bBar, 5)
	UIFactory.Stroke(bBar, pal[3], 1, 0.55)

	if opts.SubCaption then
		mkText(bBar, "MC", bottomTag or pal[4], u2o(3, 1), u2(1, -6, 0, 14), 9, c3w, true, TXC, false, zB + 4)
		mkText(bBar, "SC", opts.SubCaption, u2o(3, 14), u2(1, -6, 0, 12), 8, pal[3], true, TXC, false, zB + 4)
	else
		mkText(bBar, "RC", bottomTag or pal[4], u2o(3, 0), u2(1, -6, 1, 0), 9, pal[3], true, TXC, false, zB + 4)
	end
	return tile
end

local function hexToColor(hex, fallback)
	if type(hex) ~= "string" then return fallback or GOLD end
	local clean = hex:gsub("#", "")
	if #clean == 6 then
		local r, g, b = tonumber(clean:sub(1, 2), 16), tonumber(clean:sub(3, 4), 16), tonumber(clean:sub(5, 6), 16)
		if r and g and b then return rgb(r, g, b) end
	end
	return fallback or GOLD
end

local function fireUIAction(cmd, payload)
	payload = type(payload) == "table" and payload or {}
	local sr = SkyShared:FindFirstChild("Remotes")
	local sur = sr and (sr:FindFirstChild("UIRequest") or sr:FindFirstChild("UICommand"))
	if sur and sur:IsA("RemoteEvent") then sur:FireServer(cmd, payload); return end
	local rem = ReplicatedStorage:FindFirstChild("Remotes")
	local ur = rem and (rem:FindFirstChild("UIRequest") or rem:FindFirstChild("UICommand"))
	if ur and ur:IsA("RemoteEvent") then ur:FireServer(cmd, payload); return end
	local ra = sr and sr:FindFirstChild("RequestUIAction")
	if ra and ra:IsA("RemoteEvent") then ra:FireServer(cmd, payload) end
end

local function fireLegacyUIRequest(cmd, payload)
	payload = type(payload) == "table" and payload or {}
	local rem = ReplicatedStorage:FindFirstChild("Remotes")
	local ur = rem and rem:FindFirstChild("UIRequest")
	if ur and ur:IsA("RemoteEvent") then ur:FireServer(cmd, payload) else fireUIAction(cmd, payload) end
end

local function attachTrackedOrbit(vp)
	local orb = ViewportOrbit.Attach(vp, { AutoSpinSpeed = 0.52, InitialYaw = math.rad(28), InitialPitch = math.rad(12), ShowHint = false, FieldOfView = 34 })
	table.insert(NPCShop.Orbits, orb)
	return orb
end

local function getOwnedQty(snap, id)
	for _, inv in ipairs((snap and snap.inventory) or {}) do
		if inv.itemId == id then return tonumber(inv.count) or 0 end
	end
	return 0
end

local function isItemEquipped(snap, id)
	if not snap or not id then return false end
	for _, eqId in pairs(snap.equipped or {}) do if eqId == id then return true end end
	return snap.fruits and snap.fruits.equippedGun == id or false
end

local function formatClockCountdown(sec)
	local s = math.max(0, math.floor(tonumber(sec) or 0))
	local h, m, r = math.floor(s / 3600), math.floor((s % 3600) / 60), s % 60
	return h > 0 and string.format("%02d:%02d:%02d", h, m, r) or string.format("%02d:%02d", m, r)
end

local BUST_TORSOS = {
	samurai_kabuto = rgb(148, 86, 24), mage_hood = rgb(92, 38, 152), void_horns = rgb(92, 38, 152),
	monk_halo = rgb(20, 124, 98), valkyrie_crest = rgb(144, 34, 62), collector_tophat = rgb(78, 38, 126),
}

local function buildVendorBust3D(arch, accent)
	local m = Instance.new("Model")
	local tc = BUST_TORSOS[arch] or rgb(22, 96, 152)
	local MTL, NEON, CYL, BALL = Enum.Material.Metal, Enum.Material.Neon, Enum.PartType.Cylinder, Enum.PartType.Ball
	local function p(nm, sz, cf, col, mat, sh, cls)
		local i = Instance.new(cls or "Part")
		i.Name, i.Size, i.CFrame, i.Color, i.Material, i.Anchored, i.CanCollide = nm, sz, cf, col, mat or Enum.Material.SmoothPlastic, true, false
		if i:IsA("Part") and sh then i.Shape = sh end
		i.Parent = m
		return i
	end
	p("T", v3(1.74, 1.76, 0.94), cfNew(0, 0, 0), tc)
	p("C", v3(1.32, 0.22, 1.02), cfNew(0, 0.88, 0), accent, NEON)
	p("Cr", v3(0.42, 0.42, 1), cfNew(0, 0.34, 0) * cfAng(0, 0, math.rad(45)), accent, NEON)
	for _, s in ipairs({ -1, 1 }) do
		p("P" .. s, v3(0.72, 0.5, 1.04), cfNew(s * 1.06, 0.64, 0) * cfAng(0, 0, math.rad(-s * 18)), GOLD, MTL)
		p("E" .. s, v3(0.13, 0.14, 0.1), cfNew(s * 0.22, 1.64, -0.54), rgb(22, 26, 40), nil, BALL)
	end
	local head = p("Head", v3(1.2, 1.24, 1.18), cfNew(0, 1.62, 0), rgb(244, 212, 184), nil, BALL)
	if arch == "samurai_kabuto" then
		p("H", v3(0.42, 1.88, 1.88), cfNew(0, 2.18, 0) * cfAng(0, 0, math.rad(90)), rgb(218, 152, 36), MTL, CYL)
		for _, s in ipairs({ -1, 1 }) do p("W" .. s, v3(0.14, 0.62, 0.22), cfNew(s * 0.34, 2.4, -0.42) * cfAng(-0.15, 0, -s * 0.45), accent, NEON, nil, "WedgePart") end
	elseif arch == "tactical_goggles" or arch == "scientist_visor" then
		p("V", v3(1.12, 0.28, 0.28), cfNew(0, 1.66, -0.5), accent, NEON)
		p("Cp", v3(1.32, 0.44, 1.26), cfNew(0, 2.1, 0.04), tc:Lerp(Color3.new(), 0.28), MTL)
	elseif arch == "mage_hood" or arch == "void_horns" then
		p("Hd", v3(1.44, 1.34, 1.32), cfNew(0, 1.74, 0.16), tc:Lerp(accent, 0.22))
		p("Gm", v3(0.22, 0.22, 0.14), cfNew(0, 1.98, -0.52) * cfAng(0, 0, math.rad(45)), rgb(125, 236, 255), NEON)
	elseif arch == "captain_tricorn" then
		p("Br", v3(1.74, 0.2, 1.52), cfNew(0, 2.1, 0), rgb(26, 48, 86))
		p("Bg", v3(0.24, 0.24, 0.14), cfNew(0, 2.2, -0.72) * cfAng(0, 0, math.rad(45)), GOLDB, NEON)
	elseif arch == "collector_tophat" then
		p("Br", v3(0.14, 1.7, 1.7), cfNew(0, 2.08, 0) * cfAng(0, 0, math.rad(90)), rgb(68, 30, 108), nil, CYL)
		p("Tp", v3(0.72, 1.16, 1.16), cfNew(0, 2.46, 0) * cfAng(0, 0, math.rad(90)), rgb(96, 42, 148), nil, CYL)
	elseif arch == "valkyrie_crest" then
		for i = -2, 2 do p("S" .. i, v3(0.14, i == 0 and 0.6 or 0.4, 0.18), cfNew(i * 0.22, 2.28, -0.3) * cfAng(-0.1, 0, -i * 0.22), accent, NEON, nil, "WedgePart") end
	else
		p("Hl", v3(0.1, 1.66, 1.66), cfNew(0, 2.12, -0.12) * cfAng(0, math.rad(90), math.rad(16)), accent, NEON, CYL)
	end
	m.PrimaryPart = head
	return m
end

local function mountVendorBustCard(parent, spec)
	local accent = spec.Accent or GOLD
	local zB = spec.ZIndex or 5
	local holder = mkBox(parent, "BustWrap", spec.Position or u2o(14, 14), spec.Size or u2o(122, 176), nil, nil, nil, nil, nil, zB)
	local cardH = spec.ShowSubtitles and (spec.CardHeight or 140) or (spec.Size and spec.Size.Y.Offset or 150)
	local bustBox = mkBox(holder, "BustFrame", u2o(0, 0), u2(1, 0, 0, cardH), rgb(10, 16, 30), 10, accent, 1.8, 0.08, zB)
	UIFactory.Gradient(bustBox, accent:Lerp(rgb(16, 26, 48), 0.72), rgb(8, 12, 22), 90)

	local disc = uiCreate("Frame", bustBox, {
		Name = "Aura", AnchorPoint = v2(0.5, 0.5), Position = u2(0.5, 0, 0.45, 0),
		Size = u2o(82, 82), BackgroundColor3 = accent, BackgroundTransparency = 0.80, BorderSizePixel = 0, ZIndex = zB + 1,
	})
	UIFactory.PillCorner(disc)
	UIFactory.Stroke(disc, accent, 1.1, 0.45)

	local vp = uiCreate("ViewportFrame", bustBox, {
		Name = "BustVP", Position = u2o(3, 3), Size = u2(1, -6, 1, -18), BackgroundTransparency = 1,
		Ambient = rgb(194, 208, 238), LightColor = rgb(255, 246, 222), LightDirection = v3(-0.5, -0.65, -0.9), ZIndex = zB + 2,
	})
	local cam, wm = Instance.new("Camera"), Instance.new("WorldModel")
	cam.FieldOfView, cam.Parent, vp.CurrentCamera, wm.Parent = 28, vp, cam, vp
	buildVendorBust3D(spec.Archetype or "samurai_kabuto", accent).Parent = wm

	local focus, t0 = v3(0, 1.28, 0), os.clock()
	table.insert(NPCShop.BustConns, RunService.RenderStepped:Connect(function()
		if not vp.Parent then return end
		local t = os.clock() - t0
		local yaw, bob = math.sin(t * 0.95) * 0.14, math.sin(t * 2.1) * 0.04
		cam.CFrame = CFrame.lookAt(focus + v3(math.sin(yaw), 0, -math.cos(yaw)) * 5.0 + v3(0, 0.16 + bob, 0), focus + v3(0, bob * 0.5, 0))
	end))

	local pill = uiCreate("Frame", bustBox, {
		Name = "LivePill", AnchorPoint = v2(0.5, 1), Position = u2(0.5, 0, 1, 4),
		Size = u2(1, -8, 0, 19), BackgroundColor3 = rgb(8, 12, 22), BorderSizePixel = 0, ZIndex = zB + 4,
	})
	UIFactory.PillCorner(pill)
	UIFactory.Stroke(pill, accent, 1.2, 0.18)
	mkText(pill, "LT", spec.Tag or "• 3D LIVE", u2o(3, 0), u2(1, -6, 1, 0), 9, accent:Lerp(c3w, 0.45), true, TXC, false, zB + 5)

	if spec.ShowSubtitles then
		mkText(holder, "Sub1", spec.Title or "", u2o(0, cardH + 7), u2(1, 0, 0, 14), 10, accent:Lerp(c3w, 0.35), true, TXC, false, zB + 2)
		mkText(holder, "Sub2", spec.Location or "", u2o(0, cardH + 21), u2(1, 0, 0, 13), 9, TEXT2, false, TXC, false, zB + 2)
	end
	return holder
end

local function renderHeroAndTwoColCatalog(body, cfg)
	local sel = cfg.SelectedItem or cfg.Items[1]
	local selPal = getRarityStyle(sel and sel.r or "Legendary")
	local selAccent = (sel and sel.ac) or selPal[1]

	local heroCard = PremiumPanel.Create(body, { name = "HeroCard", variant = "gold", position = u2o(0, 0), size = u2(1, 0, 0, 206) })
	mountVendorBustCard(heroCard, {
		Position = u2o(14, 12), Size = u2o(122, 180), CardHeight = 144, ShowSubtitles = true,
		Archetype = cfg.BustArchetype, Accent = cfg.BustAccent or GOLD, Tag = cfg.BustTag, Title = cfg.BustTitle, Location = cfg.BustLocation,
	})

	local vpFrame = mkBox(heroCard, "Model3DBox", u2o(148, 14), u2o(184, 178), rgb(10, 15, 28), 10, selAccent, 1.8, 0.12, 4)
	UIFactory.Gradient(vpFrame, selAccent:Lerp(rgb(14, 22, 42), 0.80), rgb(7, 11, 20), 90)

	local vp = uiCreate("ViewportFrame", vpFrame, { Name = "HeroVP", Position = u2o(4, 4), Size = u2(1, -8, 1, -24), BackgroundTransparency = 1, ZIndex = 5 })
	if sel then
		ViewportOrbit.MountAssetAsync(attachTrackedOrbit(vp), sel.a3d, selAccent, { FitMultiplier = 1.08, ResetAngles = true, UprightWeapon = sel.up == true })
	end
	mkText(vpFrame, "MCap", pick("MÔ HÌNH 3D: ", "3D MODEL: ") .. UIFactory.Upper(tostring(sel and sel.st or sel and sel.t or "ASSET")), u2(0, 6, 1, -20), u2(1, -12, 0, 16), 9, GOLDB, true, TXC, false, 6)

	local rightBox = mkBox(heroCard, "HeroRight", u2o(346, 12), u2(1, -360, 0, 182), nil, nil, nil, nil, nil, 4)
	mkText(rightBox, "IT", UIFactory.Upper(tostring(sel and sel.t or "")), u2o(0, 0), u2(1, 0, 0, 22), 16, selPal[3], true)
	mkText(rightBox, "IM", sel and sel.hsub or "", u2o(0, 21), u2(1, 0, 0, 16), 11, selPal[1]:Lerp(c3w, 0.25), true)

	for bIdx = 1, 2 do
		local bInfo = sel and sel.sb and sel.sb[bIdx]
		local sBox = mkBox(rightBox, "SB_" .. bIdx, u2o(0, 41 + (bIdx - 1) * 47), u2(1, 0, 0, 43), rgb(11, 22, 44), 8, SAPPH, 1.1, 0.35)
		sBox.BackgroundTransparency = 0.08
		mkText(sBox, "ST", bInfo and bInfo[1] or pick("[Z] Tuyệt Kỹ Vũ Khí 3D", "[Z] 3D Weapon Skill"), u2o(10, 4), u2(1, -20, 0, 17), 11, rgb(92, 225, 255), true)
		mkText(sBox, "SD", bInfo and bInfo[2] or "", u2o(10, 21), u2(1, -20, 0, 18), 10, TEXT2, false)
	end

	if sel then
		mkBtn(rightBox, "HeroCTA", sel.hbtn or sel.cbtn or pick("MUA & TRANG BỊ", "BUY & EQUIP"), sel.hvar or "gold", u2o(0, 138), u2(1, 0, 0, 42),
			function() if sel.act then sel.act() end end, { icon = sel.cicon or "Gold", disabled = sel.dis, ts = 13, minTs = 10 })
	end

	local filterRow = mkBox(body, "FilterRow", u2o(0, 212), u2(1, 0, 0, 34))
	UIFactory.ListLayout(filterRow, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
	for fIdx, pill in ipairs(cfg.FilterPills or {}) do
		if pill.timerRef then
			local tBox = mkBox(filterRow, "TimerPill", nil, u2o(196, 32), rgb(36, 18, 64), 8, VOIDP, 1.3, 0.16, nil, fIdx)
			NPCShop.Refs[pill.timerRef] = mkText(tBox, "TT", pill.lbl, nil, u2s(1, 1), 11, GOLDB, true, TXC)
		else
			mkBtn(filterRow, "F_" .. fIdx, pill.lbl, pill.var or (pill.act and "gold" or "secondary"), nil, u2o(pill.w or 162, 32),
				pill.fn, { icon = pill.ic, selected = pill.act == true, order = fIdx })
		end
	end

	local gridScroll = uiCreate("ScrollingFrame", body, {
		Name = "MerchGrid", Position = u2o(0, 252), Size = u2(1, 0, 1, -252),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 5, ScrollBarImageColor3 = GOLD,
		AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = u2o(0, 0),
	})
	UIFactory.Padding(gridScroll, 2, 6, 8, 2)
	UIFactory.GridLayout(gridScroll, u2(0.5, -6, 0, 102), u2o(10, 10))

	for idx, item in ipairs(cfg.Items or {}) do
		local isSel = (sel and sel.id == item.id)
		local pal = getRarityStyle(item.r)
		local mCard = uiCreate("TextButton", gridScroll, {
			Name = "Card_" .. tostring(item.id), BackgroundColor3 = isSel and rgb(20, 34, 62) or rgb(11, 18, 34),
			BackgroundTransparency = 0.04, BorderSizePixel = 0, Text = "", AutoButtonColor = false, LayoutOrder = idx,
		})
		UIFactory.Corner(mCard, 10)
		UIFactory.Stroke(mCard, isSel and GOLDB or pal[3]:Lerp(STEEL, 0.45), isSel and 2.1 or 1.2, isSel and 0.04 or 0.30)

		makeGlossyRarityTile(mCard, item.r, item.top, item.bot or pal[4], item.ic, u2o(84, 86), {
			Position = u2o(8, 8), Selected = isSel, RightTag = item.rtag, RightColor = item.rcol,
		})
		mkText(mCard, "CT", item.t or "", u2o(102, 9), u2(1, -112, 0, 20), 13, TEXT1, true)
		mkText(mCard, "CS", item.csub or "", u2o(102, 30), u2(1, -112, 0, 17), 11, item.scol or rgb(92, 225, 255), true)
		mkBtn(mCard, "CTA_" .. tostring(item.id), item.cbtn or pick("MUA NGAY", "BUY NOW"), item.cvar or "gold", u2o(102, 56), u2(1, -112, 0, 36),
			function()
				if item.sel then item.sel(false) end
				if item.act then item.act() end
			end, { disabled = item.dis })
		mCard.Activated:Connect(function() if item.sel then item.sel(true) end end)
	end
end

local function shopSt()
	Store.Session.npcShopState = Store.Session.npcShopState or {}
	return Store.Session.npcShopState
end

local CANONICAL_FRUIT_MAP = {
	GaleCore = "GaleCore", Gale = "GaleCore",
	SandstoneCore = "SandstoneCore", Smoke = "SandstoneCore", Sand = "SandstoneCore",
	SolarFlameCore = "SolarFlameCore", Flame = "SolarFlameCore",
	GlacierIceCore = "GlacierIceCore", Ice = "GlacierIceCore",
	ThunderRumbleCore = "ThunderRumbleCore", Rumble = "ThunderRumbleCore",
	CelestialLightCore = "CelestialLightCore", Light = "CelestialLightCore",
	StarforgedMagmaCore = "StarforgedMagmaCore", Magma = "StarforgedMagmaCore",
	AstralGravityCore = "AstralGravityCore", Gravity = "AstralGravityCore",
	DimensionalPortalCore = "DimensionalPortalCore", Portal = "DimensionalPortalCore",
	SolarTitanCore = "SolarTitanCore", Buddha = "SolarTitanCore", Quake = "SolarTitanCore",
	AetherflowCore = "AetherflowCore", SweetDoughCore = "AetherflowCore", Dough = "AetherflowCore",
	AbyssalSovereignCore = "AbyssalSovereignCore", Dragon = "AbyssalSovereignCore",
}

local function normalizeFruitId(rawId)
	local s = tostring(rawId or "")
	return CANONICAL_FRUIT_MAP[s] or s
end

local MIRAGE_FRUITS = {
	{ "GaleCore", "Lõi Cuồng Phong (Gale)", "Gale Core", "Common", 75000, "Nguyên Tố Gió • Miễn ST thường", "[Z] Phong Đao Trảm", "[V] Đại Cuồng Phong", "Wind Elemental • Basic-hit Immunity", "[Z] Gale Blades", "[V] Skyborn Typhoon" },
	{ "SandstoneCore", "Lõi Sa Mạc Hoàng Kim", "Sandstone Core", "Uncommon", 420000, "Nguyên Tố Cát • Lốc Cát Trói Chân", "[Z] Sa Đao Trảm", "[V] Bão Cát Hoàng Kim", "Sand Elemental • Quicksand Snare", "[Z] Desert Blade", "[V] Sandstorm Wrath" },
	{ "SolarFlameCore", "Lõi Thái Dương Hỏa", "Solar Flame Core", "Rare", 550000, "Nguyên Tố Lửa • Đại Viêm Đế", "[Z] Hỏa Đạn Liên Hoàn", "[V] Thái Dương Viêm Đế", "Solar Elemental • Burn AoE Burst", "[Z] Fire Bullets", "[V] Solar Emperor" },
	{ "GlacierIceCore", "Lõi Vĩnh Băng", "Glacier Ice Core", "Rare", 750000, "Nguyên Tố Băng • Đóng Băng Diện Rộng", "[Z] Băng Tiêu Tam Liên", "[V] Tuyệt Độ Hàn Băng", "Frost Elemental • Wide Freeze Control", "[Z] Ice Shards", "[V] Absolute Zero" },
	{ "CelestialLightCore", "Lõi Thánh Quang (Light)", "Celestial Light Core", "Epic", 1100000, "Nguyên Tố Ánh Sáng • Bay Nhanh Nhất", "[Z] Tia Sáng Phán Quyết", "[F] Hóa Tia Sáng Phi Hành", "Light Elemental • Fastest Sky Flight", "[Z] Light Ray", "[F] Light Flight" },
	{ "ThunderRumbleCore", "Lõi Lôi Thần Cửu Thiên", "Thunder Core", "Epic", 2100000, "Nguyên Tố Sấm Sét • Lôi Cầu Cửu Thiên", "[Z] Lôi Long Phá", "[V] Quả Cầu Lôi Thần", "Lightning Elemental • Triple Dash & Stun", "[Z] Thunder Drake", "[V] Thunderball Destruction" },
	{ "StarforgedMagmaCore", "Lõi Dung Nham Tinh Cầu", "Starforged Magma Core", "Legendary", 1350000, "Nguyên Tố Dung Nham • Sát Thương Đốt Cao Nhất", "[Z] Dung Nham Thiết Chưởng", "[V] Mưa Sao Băng Dung Nham", "Magma Elemental • Highest Burn DPS", "[Z] Magma Clap", "[V] Meteor Volcano" },
	{ "AstralGravityCore", "Lõi Trọng Lực Tinh Vân", "Astral Gravity Core", "Legendary", 2300000, "Trọng Lực Không Gian • Mưa Thiên Thạch", "[Z] Xung Lực Đẩy", "[V] Mưa Thiên Thạch Vũ Trụ", "Cosmic Gravity • Meteor Pull AoE", "[Z] Gravity Push", "[V] Astral Meteor Shower" },
	{ "DimensionalPortalCore", "Lõi Khe Nứt Không Gian", "Rift Core", "Legendary", 2500000, "Không Gian • Cổng Dịch Chuyển Toàn Bản Đồ", "[C] Cổng Dịch Chuyển Thế Giới", "[V] Chiều Không Gian Thứ Tư", "Spatial Rift • World-Warp Mobility", "[C] World Warp", "[V] Dimensional Rift" },
	{ "SolarTitanCore", "Lõi Kim Thân Khổng Lồ", "Colossus Core", "Mythic", 2800000, "Hóa Kim Thân Khổng Lồ 3D (-55% ST Nhận)", "[Z] Hóa Kim Thân 3D", "[V] Hoàng Hôn Chư Thần", "3D Golden Colossus (-55% DMG Taken)", "[Z] Solar Titan Shift", "[V] Twilight of the Gods" },
	{ "AetherflowCore", "Lõi Linh Mạch Aether", "Aetherflow Core", "Mythic", 3400000, "Tinh Thể Đặc Biệt • Bách Quyền Aether", "[Z] Thiết Quyền Tinh Thể", "[V] Liên Hoàn Bách Quyền", "Special Crystal • Aether Barrage Combo", "[Z] Missile Jab", "[V] Restless Aether Barrage" },
	{ "AbyssalSovereignCore", "Lõi Long Đế Vực Thẳm", "Abyssal Sovereign Core", "Mythic", 5000000, "Song Long Biến Hình 3D (Bán Long & Long Hoàng)", "[Z] Thái Cổ Long Tức", "[V] Hóa Thái Cổ Long Hoàng 3D", "Dual 3D Dragon Forms (Hybrid & Sovereign)", "[Z] Sovereign Beam", "[V] Dragon Form Shift" },
}

local function ensureMirageListener()
	if NPCShop.MirageBound then return end
	local rem = ReplicatedStorage:FindFirstChild("Remotes")
	local fa = rem and rem:FindFirstChild("FruitAction")
	if fa and fa:IsA("RemoteEvent") then
		NPCShop.MirageBound = true
		fa.OnClientEvent:Connect(function(kind, data)
			if kind == "MirageStock" and type(data) == "table" then
				NPCShop.LiveMirageStock = data
				if NPCShop.Refs.Root and NPCShop.Refs.Root.Parent and Store.GetView().activeVendorMode == "MirageDealer" then
					NPCShop.RebuildWorkspace()
				end
			end
		end)
	end
end

local function buildMirageTab(body, snap)
	ensureMirageListener()
	local st = shopSt()
	if st.mirageSub ~= "ALL" and st.mirageSub ~= "INSTOCK" then
		st.mirageSub = "ALL"
	end
	local curHourSeed = math.floor(os.time() / 3600)
	if NPCShop.LastMirageReqSeed ~= curHourSeed then
		NPCShop.LastMirageReqSeed = curHourSeed
		fireLegacyUIRequest("GetMirageStock", {})
	end

	local liveStock = nil
	if NPCShop.LiveMirageStock and type(NPCShop.LiveMirageStock.Items) == "table" and NPCShop.LiveMirageStock.HourSeed == curHourSeed then
		liveStock = NPCShop.LiveMirageStock
	elseif snap and snap.mirageStock and type(snap.mirageStock.Items) == "table" then
		liveStock = snap.mirageStock
	elseif SharedCombatData and type(SharedCombatData.GetHourlyMirageStock) == "function" then
		local okM, gen = pcall(SharedCombatData.GetHourlyMirageStock, os.time())
		if okM and type(gen) == "table" then liveStock = gen end
	end

	local stockById = {}
	for _, sItem in ipairs((liveStock and liveStock.Items) or {}) do
		local sid = normalizeFruitId(sItem.Id)
		if sid ~= "" then stockById[sid] = sItem end
	end

	local items, selectedItem, selId = {}, nil, st.selectedMirageFruit or "SolarTitanCore"
	local isEn = I18n.GetLanguage() == "en"
	local eqFruit = normalizeFruitId(snap and snap.fruits and snap.fruits.equippedFruit or "")

	for _, f in ipairs(MIRAGE_FRUITS) do
		local fid, nVi, nEn, rar, defP = f[1], f[2], f[3], f[4], f[5]
		local subTxt = isEn and f[9] or f[6]
		local skZ = isEn and f[10] or f[7]
		local skX = isEn and f[11] or f[8]
		local sEntry = stockById[fid]
		local inStock = (sEntry ~= nil)
		if st.mirageSub == "ALL" or inStock then
			local fCfg = (CoreConfig.AetherFruits and CoreConfig.AetherFruits[fid]) or {}
			local price = tonumber((sEntry and sEntry.PriceGold) or fCfg.Price) or defP
			local isEq = (eqFruit ~= "" and eqFruit == fid)
			local pTxt = fmt(price) .. " GOLD"
			local entry = {
				id = fid, t = isEn and nEn or nVi, st = fid, r = rar,
				top = inStock and pick("CÒN HÀNG", "IN STOCK") or pick("HẾT HÀNG", "OUT"),
				bot = UIFactory.Upper(rar), ic = "Fruit", a3d = "Fruit_" .. fid,
				rtag = inStock and pick("TRÊN KỆ", "LIVE") or nil, rcol = rgb(16, 185, 129),
				hsub = UIFactory.Upper(rar) .. " • [Z][X][C][V][F] • " .. pTxt,
				csub = inStock
					and ((isEq and pick("• ĐANG TRANG BỊ TRÊN SLOT [2]", "• EQUIPPED ON SLOT [2]")) or ("• " .. pick("ĐANG MỞ BÁN • ", "IN STOCK • ") .. subTxt))
					or pick("• TẠM HẾT HÀNG (LÀM MỚI MỖI 1 GIỜ)", "• OUT OF STOCK (HOURLY ROTATION)"),
				scol = inStock and SUCC or DANG,
				sb = {
					{ skZ, subTxt .. pick(" • Sẵn sàng Lõi Thức Tỉnh tại Phòng Raid.", " • Ready for V2 Awakening at Raid Lab.") },
					{ skX, pick("Kệ hàng thực tế đồng bộ 100% với Máy Chủ mỗi 1 giờ.", "100% live server-synced 1-hour rotating Core stock.") },
				},
				cbtn = isEq and pick("ĐANG TRANG BỊ", "EQUIPPED")
					or (inStock and (pick("MUA & TRANG BỊ • ", "BUY & EQUIP • ") .. pTxt) or (pick("TẠM HẾT HÀNG (", "OUT OF STOCK (") .. pTxt .. ")")),
				cvar = isEq and "primary" or (inStock and "gold" or "secondary"),
				hbtn = inStock and (pick("MUA & TRANG BỊ LÕI 3D • ", "BUY & EQUIP 3D CORE • ") .. pTxt)
					or (pick("CHƯA CÓ TRÊN KỆ GIỜ NÀY (", "NOT IN CURRENT 1H STOCK (") .. pTxt .. ")"),
				hvar = inStock and "gold" or "secondary", dis = not inStock,
				sel = selFn(st, "selectedMirageFruit", fid),
				act = function()
					if not inStock then return end
					fireLegacyUIRequest("BuyMirageFruit", { fruitId = fid, equipNow = true })
				end,
			}
			table.insert(items, entry)
			if fid == selId then selectedItem = entry end
		end
	end

	renderHeroAndTwoColCatalog(body, {
		BustArchetype = "mage_hood", BustAccent = GOLDB, BustTag = pick("• 3D LIVE - HƯ QUANG", "• 3D LIVE - PHANTOM"),
		BustTitle = pick("THƯƠNG NHÂN HƯ QUANG", "PHANTOM DEALER"), BustLocation = pick("Sky Hub • Đảo Hư Quang", "Sky Hub • Phantom Isle"),
		SelectedItem = selectedItem or items[1], Items = items,
		FilterPills = {
			fPill(st, "mirageSub", "ALL", pick("TẤT CẢ 12 LÕI AETHER", "ALL 12 AETHER CORES"), 172, "gold"),
			fPill(st, "mirageSub", "INSTOCK", pick("ĐANG MỞ BÁN (KỆ 1H)", "IN STOCK NOW (1H)"), 184, "primary"),
			{ timerRef = "MirageTimerLabel", lbl = pick("LÀM MỚI: ", "REFRESH: ") .. formatClockCountdown(3600 - (os.time() % 3600)) },
			{ ic = "Fruit", lbl = pick("KHO LÕI CÁ NHÂN [G]", "PERSONAL CORES [G]"), var = "primary", w = 186, fn = function() ScreenRouter.Navigate("Fruits:Vault") end },
		},
	})
end

local function buildArsenalVendorTab(body, snap, mode)
	local st = shopSt()
	local isSword = (mode == "SwordDealer")
	st.swordSeaFilter, st.gunFilter = st.swordSeaFilter or "ALL", st.gunFilter or "ALL_GUNS"
	local fm = isSword and st.swordSeaFilter or st.gunFilter
	local isEn = I18n.GetLanguage() == "en"

	local rawCatalog = {}
	if isSword then
		for _, entry in ipairs(VC.SwordDealer or {}) do
			if fm == "ALL" or entry.Sea == fm then table.insert(rawCatalog, entry) end
		end
	elseif fm == "ARMOR_SETS" or fm == "RELICS" then
		for _, entry in ipairs(VC.ArmorAndRelicVendor or {}) do
			local cfg = AEC.Items[entry.ItemId] or RarityConfig.GetItem(entry.ItemId) or {}
			local slot = tostring(cfg.Slot or "")
			local isRelic = (slot == "Ring" or slot == "Artifact" or cfg.Category == "Materials" or cfg.Category == "Quest")
			if (fm == "RELICS" and isRelic) or (fm == "ARMOR_SETS" and not isRelic) then table.insert(rawCatalog, entry) end
		end
	else
		for _, entry in ipairs(VC.GunDealer or {}) do
			if fm == "ALL_GUNS" or (fm == "GUN_SEA12" and (entry.Sea == "Sea1" or entry.Sea == "Sea2")) or (fm == "GUN_SEA3" and entry.Sea == "Sea3") then
				table.insert(rawCatalog, entry)
			end
		end
	end
	if #rawCatalog == 0 then rawCatalog = isSword and (VC.SwordDealer or {}) or (VC.GunDealer or {}) end

	local selKey = isSword and "selSwordId" or ("selGunTab_" .. fm)
	local selId = st[selKey] or (rawCatalog[#rawCatalog] and rawCatalog[#rawCatalog].ItemId) or "Dawnbringer"
	local items, selectedItem = {}, nil
	local topTag = isSword and pick("KIẾM 3D", "3D SWORD")
		or ((fm == "ARMOR_SETS") and pick("GIÁP 3D", "3D ARMOR")
			or ((fm == "RELICS") and pick("THÁNH VẬT", "RELIC") or pick("SÚNG 3D", "3D GUN")))
	local iconKind = isSword and "Sword" or ((fm == "ARMOR_SETS") and "Shield" or ((fm == "RELICS") and "CoreShards" or "Gun"))

	for _, entry in ipairs(rawCatalog) do
		local itemId = entry.ItemId
		local cfg = AEC.Items[itemId] or RarityConfig.GetItem(itemId) or {}
		local rarity = cfg.Rarity or "Rare"
		local accent = hexToColor(entry.AccentHex or cfg.AccentHex, getRarityStyle(rarity)[1])
		local owned, eq = getOwnedQty(snap, itemId) > 0, isItemEquipped(snap, itemId)
		local dispName = isEn and (cfg.Name or itemId) or (cfg.VietnameseName or cfg.Name or itemId)
		local lvReq = tonumber(entry.LevelReq or cfg.LevelReq) or 1
		local lvLocked = (not owned) and ((tonumber(snap.player and snap.player.level) or 1) < lvReq)
		local seaStr = tostring(entry.Sea or cfg.Sea or "Sea1"):gsub("Sea", "Sky ")
		local stats = cfg.Stats or {}
		local mainStat = (tonumber(stats.ATK) and ("+" .. stats.ATK .. " ATK")) or (tonumber(stats.HP) and ("+" .. stats.HP .. " HP")) or "+45 ATK"
		local secStat = (tonumber(stats.CRIT) and ("+" .. stats.CRIT .. "% CRIT")) or (tonumber(stats.DEF) and ("+" .. stats.DEF .. " DEF")) or ("Lv." .. lvReq)
		local pGold, pShards = tonumber(entry.PriceGold) or 0, tonumber(entry.PriceShards) or 0
		local priceShort = (pGold == 0 and pShards == 0) and pick("MIỄN PHÍ", "FREE")
			or (pShards > 0 and (fmt(pGold) .. " GOLD + " .. fmt(pShards) .. " SHARDS") or (fmt(pGold) .. " GOLD"))

		local sb = {}
		if cfg.ArmorSetId and AEC.ArmorSetsById and AEC.ArmorSetsById[cfg.ArmorSetId] then
			local aSet = AEC.ArmorSetsById[cfg.ArmorSetId]
			local setUp = UIFactory.Upper(tostring((isEn and aSet.NameEn) or aSet.NameVi or cfg.ArmorSetId))
			sb[1] = {
				pick("[2/4 BỘ ", "[2/4 SET ") .. setUp .. "]",
				tostring((isEn and aSet.Bonus2En) or aSet.Bonus2Vi or pick("Tăng mạnh Sinh Lực & Sát Thương bộ giáp.", "Boosts Max HP & Set Damage.")),
			}
			sb[2] = {
				pick("[4/4 BỘ ", "[4/4 SET ") .. setUp .. "]",
				tostring((isEn and aSet.Bonus4En) or aSet.Bonus4Vi or pick("Kích hoạt Hào Quang Thần Giáp 3D toàn diện.", "Unlocks full 3D Resonance Armor Aura.")),
			}
		else
			local wepEntry = (CoreConfig.Swords and CoreConfig.Swords[itemId]) or (CoreConfig.Guns and CoreConfig.Guns[itemId])
			local zName = (isEn and cfg.SkillZEn) or cfg.SkillZ or (wepEntry and wepEntry.Skills and wepEntry.Skills.Z and wepEntry.Skills.Z.Name) or pick("Trảm Kích Ánh Sáng Aether", "Aether Arc Slash")
			local xName = (isEn and cfg.SkillXEn) or cfg.SkillX or (wepEntry and wepEntry.Skills and wepEntry.Skills.X and wepEntry.Skills.X.Name) or pick("Tuyệt Kỹ Phá Giáp Hư Không", "Void Armor-Break Burst")
			sb[1] = {
				string.format("[Z] %s (Mastery 150)", tostring(zName)),
				tostring((isEn and cfg.DescriptionEn) or cfg.Description or pick("Đòn đánh nguyên tố tầm xa cuốn kẻ địch vào xoáy năng lượng 3D.", "Long-range elemental strike pulling foes into an Aether vortex.")),
			}
			sb[2] = {
				string.format("[X] %s (Mastery 300)", tostring(xName)),
				tostring((isEn and cfg.PassiveEn) or cfg.Passive or pick("Phóng xung kích xuyên thủng phòng ngự Boss và gây bạo kích diện rộng.", "Pierces Boss guard and unleashes high-Break area damage.")),
			}
		end

		local asset3D = ViewportOrbit.ResolveAssetName(itemId) or itemId
		local cardEntry = {
			id = itemId, t = dispName, st = cfg.Name or dispName, r = rarity, ac = accent, top = topTag, ic = iconKind,
			rtag = (lvReq >= 2300) and pick("MỚI", "NEW") or nil, rcol = rgb(225, 29, 72),
			a3d = asset3D, up = string.sub(tostring(asset3D), 1, 4) == "Wep_",
			hsub = string.format("%s • %s • %s • LV.%d (%s)", UIFactory.Upper(rarity), mainStat, secStat, lvReq, seaStr),
			csub = string.format("%s • %s • Lv.%d %s", mainStat, eq and pick("Đang trang bị", "Equipped") or (owned and pick("Đã sở hữu", "Owned") or secStat), lvReq, seaStr),
			sb = sb,
			cbtn = eq and pick("ĐANG TRANG BỊ", "EQUIPPED") or (owned and pick("TRANG BỊ NGAY", "EQUIP NOW"))
				or (lvLocked and pick("CẦN LV." .. lvReq, "REQUIRES LV." .. lvReq) or (pick("MUA • ", "BUY • ") .. priceShort)),
			cvar = (eq or owned) and "primary" or (lvLocked and "secondary")
				or ((not isSword and (rarity == "Mythic" or rarity == "Legendary")) and "primary" or "gold"),
			hbtn = eq and pick("ĐANG TRANG BỊ TRÊN NHÂN VẬT 3D", "CURRENTLY EQUIPPED ON 3D HERO")
				or (owned and (pick("TRANG BỊ NGAY • ", "EQUIP NOW • ") .. UIFactory.Upper(dispName)))
				or (lvLocked and pick("CẦN ĐẠT LV." .. lvReq .. " ĐỂ MỞ KHÓA • " .. priceShort, "REACH LV." .. lvReq .. " TO UNLOCK • " .. priceShort))
				or (pick("MỞ KHÓA & TRANG BỊ • ", "UNLOCK & EQUIP • ") .. priceShort),
			hvar = lvLocked and "secondary" or (isSword and "gold" or "primary"), cicon = isSword and "Sword" or iconKind,
			sel = selFn(st, selKey, itemId),
			act = function()
				if lvLocked then
					Store.ShowToast(pick(string.format("Cần đạt Lv.%d để mua [%s]!", lvReq, dispName), string.format("Reach Lv.%d to buy [%s]!", lvReq, dispName)), "warning")
					return
				end
				fireUIAction("BuyVendorItem", { itemId = itemId, autoEquip = true })
				if snap.isDemoMode then Store.ApplyDemoPreviewAction("EquipItem", { itemId = itemId }) end
			end,
		}
		table.insert(items, cardEntry)
		if itemId == selId then selectedItem = cardEntry end
	end

	renderHeroAndTwoColCatalog(body, {
		BustArchetype = isSword and "samurai_kabuto" or "tactical_goggles",
		BustAccent = isSword and GOLDB or SAPPH,
		BustTag = isSword and pick("• 3D LIVE - KIẾM SƯ", "• 3D LIVE - BLADES") or pick("• 3D LIVE - XẠ THỦ", "• 3D LIVE - ARMORY"),
		BustTitle = isSword and pick("KIẾM THÁNH HẮC TINH", "MASTER BLADESMITH") or pick("XẠ THỦ VỆ TINH", "ARCANE GUNSMITH"),
		BustLocation = isSword and "Sky Hub • Cyberport • Umbral" or pick("Xưởng Vũ Khí Tầm Xa", "Ranged & Armor Foundry"),
		SelectedItem = selectedItem or items[#items] or items[1], Items = items,
		FilterPills = isSword and {
			fPill(st, "swordSeaFilter", "ALL", pick("TẤT CẢ KIẾM", "ALL SWORDS"), 156, "gold"),
			fPill(st, "swordSeaFilter", "Sea1", pick("SKY 1 • SƠ CẤP", "SKY 1 • STARTER"), 156, "gold"),
			fPill(st, "swordSeaFilter", "Sea2", "SKY 2 • CYBER", 156, "gold"),
			fPill(st, "swordSeaFilter", "Sea3", pick("SKY 3 • TUYỆT ĐỈNH", "SKY 3 • ENDGAME"), 172, "gold"),
		} or {
			fPill(st, "gunFilter", "ALL_GUNS", pick("TẤT CẢ SÚNG (10)", "ALL GUNS (10)"), 154, "primary"),
			fPill(st, "gunFilter", "GUN_SEA12", pick("SÚNG SKY 1-2", "SKY 1-2 GUNS"), 136, "primary"),
			fPill(st, "gunFilter", "GUN_SEA3", pick("PHÁP KHÍ CUỐI GAME", "ENDGAME CANNONS"), 166, "primary"),
			fPill(st, "gunFilter", "ARMOR_SETS", pick("THẦN GIÁP 3D (8 BỘ)", "3D ARMOR (8 SETS)"), 172, "gold"),
			fPill(st, "gunFilter", "RELICS", pick("THÁNH VẬT & NHẪN", "RELICS & RINGS"), 158, "gold"),
		},
	})
end

local function buildMartialDojoTab(body, snap)
	local st = shopSt()
	st.martialSea = st.martialSea or "ALL"
	local activeStyle = tostring((snap.fruits and snap.fruits.fightingStyle) or "skyborn_combat")
	local unlockedStyles = (snap and type(snap.unlockedStyles) == "table" and snap.unlockedStyles) or { skyborn_combat = true }
	local pLv = tonumber(snap and snap.player and snap.player.level) or 1
	local selId, items, selectedItem = st.selectedStyleId or "celestial_godhuman", {}, nil
	local isEn = I18n.GetLanguage() == "en"

	for _, s in ipairs(VC.MartialDojoStyles or {}) do
		if st.martialSea == "ALL" or s.Sea == st.martialSea then
			local isEq = (activeStyle == s.Id or activeStyle == s.StyleId or activeStyle == s.FallbackCombatStyleId)
			local isOwned = isEq or (unlockedStyles[s.Id] == true) or (s.StyleId ~= nil and unlockedStyles[s.StyleId] == true)
			local lvReq = tonumber(s.LevelReq) or 1
			local lvLocked = (not isOwned) and (pLv < lvReq)
			local pGold, pShards = tonumber(s.PriceGold) or 0, tonumber(s.PriceShards) or 0
			local priceTxt = (pGold == 0 and pShards == 0) and pick("MIỄN PHÍ", "FREE") or (fmt(pGold) .. " GOLD" .. (pShards > 0 and (" + " .. fmt(pShards) .. " SHARDS") or ""))
			local title = isEn and (s.NameEn or s.NameVi) or s.NameVi
			local masterTxt = isEn and tostring(s.MasterEn or "Grandmaster") or tostring(s.MasterVi or "Sư Phụ Võ Đường")
			local entry = {
				id = s.Id, t = title, st = s.NameEn or title, r = s.Rarity or "Legendary",
				ac = hexToColor(s.AccentHex, GOLD), top = pick("VÕ HỌC", "MARTIAL"), ic = "Fist",
				rtag = (lvReq >= 2400) and pick("MỚI", "NEW") or nil, a3d = s.Model3DKind or "Martial_Godhuman",
				hsub = string.format("%s • %s: %s • LV.%d (%s)", UIFactory.Upper(s.Rarity or "MYTHIC"), pick("SƯ PHỤ", "MASTER"), UIFactory.Upper(masterTxt), lvReq, tostring(s.Sea or "Sea1"):gsub("Sea", "Sky ")),
				csub = masterTxt .. " • " .. (isEq and pick("Đang trang bị", "Equipped") or (isOwned and pick("Đã lĩnh ngộ", "Learned") or priceTxt)) .. " • [Z][X][C]",
				sb = {
					{
						pick("[Z] Đột Kích Khí Công • [X] Phá Toái Chấn Động", "[Z] Chi Rush • [X] Shattering Strike"),
						pick("Mở khóa Hộ Uyển Hào Quang 3D trên hai tay cùng chuỗi đòn đánh cận chiến tốc độ cao.", "Unlocks 3D Aura Gauntlets with high-speed 4-hit M1 martial katas."),
					},
					{
						pick("[C] Tuyệt Kỹ Thần Quyền Tối Thượng (Slot [1] Melee)", "[C] Ultimate Martial Finisher (Slot [1] Melee)"),
						pick("Yêu cầu: Lv.", "Requires: Lv.") .. tostring(lvReq) .. pick(" • Lệ phí bái sư: ", " • Tuition: ") .. priceTxt,
					},
				},
				cbtn = isEq and pick("ĐANG TRANG BỊ", "EQUIPPED")
					or (isOwned and pick("TRANG BỊ NGAY", "EQUIP NOW"))
					or (lvLocked and pick("CẦN LV." .. lvReq, "REQUIRES LV." .. lvReq) or pick("LĨNH HỘI • " .. priceTxt, "LEARN • " .. priceTxt)),
				cvar = isEq and "gold" or (lvLocked and "secondary" or "primary"),
				hbtn = isEq and pick("ĐANG TRANG BỊ TRÊN SLOT [1]", "EQUIPPED ON SLOT [1]")
					or (isOwned and (pick("TRANG BỊ VÕ HỌC [1] • ", "EQUIP MARTIAL STYLE [1] • ") .. UIFactory.Upper(title)))
					or (lvLocked and pick("CẦN ĐẠT LV." .. lvReq .. " ĐỂ LĨNH HỘI • " .. priceTxt, "REACH LV." .. lvReq .. " TO LEARN • " .. priceTxt))
					or (pick("LĨNH HỘI & TRANG BỊ VÕ HỌC [1] • ", "LEARN & EQUIP STYLE [1] • ") .. priceTxt),
				hvar = lvLocked and "secondary" or "gold", cicon = "Fist",
				sel = selFn(st, "selectedStyleId", s.Id),
				act = function()
					if lvLocked then
						Store.ShowToast(pick(string.format("Cần đạt Lv.%d để lĩnh hội [%s]!", lvReq, title), string.format("Reach Lv.%d to learn [%s]!", lvReq, title)), "warning")
						return
					end
					fireUIAction("BuyVendorItem", { styleId = s.Id })
				end,
			}
			table.insert(items, entry)
			if s.Id == selId then selectedItem = entry end
		end
	end

	renderHeroAndTwoColCatalog(body, {
		BustArchetype = "monk_halo", BustAccent = SUCC, BustTag = pick("• 3D LIVE - ĐẠI SƯ", "• 3D LIVE - MASTER"),
		BustTitle = pick("ĐẠI SƯ CỔ TỰ", "ANCIENT GRANDMASTER"), BustLocation = pick("7 Võ Đường Truyền Thụ", "7 Martial Sanctums"), SelectedItem = selectedItem or items[1], Items = items,
		FilterPills = {
			fPill(st, "martialSea", "ALL", pick("TẤT CẢ 7 VÕ ĐƯỜNG", "ALL 7 MARTIAL DOJOS"), 172, "gold"),
			fPill(st, "martialSea", "Sea1", pick("SKY 1 • NHẬP MÔN", "SKY 1 • INITIATE"), 156, "primary"),
			fPill(st, "martialSea", "Sea2", pick("SKY 2 • ĐỘT PHÁ", "SKY 2 • BREAKTHROUGH"), 156, "primary"),
			fPill(st, "martialSea", "Sea3", "SKY 3 • ASCENDANT & VOID", 198, "gold"),
		},
	})
end

local RUNE_COLORS = {
	Vampiric = rgb(251, 113, 133),
	ChronoHaste = rgb(56, 189, 248),
	ChainVolt = rgb(96, 165, 250),
	SolarCrit = rgb(252, 211, 77),
	ArmorBreaker = rgb(192, 132, 252),
}

local FALLBACK_RUNE_ODDS = {
	{ Id = "Vampiric", NameVi = "Hấp Huyết", NameEn = "Vampiric", ChancePct = 20.0, RerollPct = 25.0, DescVi = "Hồi 4% máu theo sát thương gây ra", DescEn = "Heal 4% of damage dealt" },
	{ Id = "ChronoHaste", NameVi = "Gia Tốc", NameEn = "Chrono Haste", ChancePct = 20.0, RerollPct = 25.0, DescVi = "Giảm 15% hồi chiêu kỹ năng", DescEn = "-15% skill cooldowns" },
	{ Id = "ChainVolt", NameVi = "Lôi Liên Xích", NameEn = "Chain Volt", ChancePct = 20.0, RerollPct = 25.0, DescVi = "25% phóng lôi xích lan sang mục tiêu gần", DescEn = "25% chance to arc chain lightning" },
	{ Id = "SolarCrit", NameVi = "Nhật Bạo", NameEn = "Solar Crit", ChancePct = 20.0, RerollPct = 25.0, DescVi = "+10% Tỷ lệ Chí mạng & +20% Sát thương Chí mạng", DescEn = "+10% Crit Rate & +20% Crit DMG" },
	{ Id = "ArmorBreaker", NameVi = "Phá Giáp", NameEn = "Armor Breaker", ChancePct = 20.0, RerollPct = 25.0, DescVi = "Xuyên 18% DEF và +25% Break", DescEn = "Ignore 18% DEF & +25% Break" },
}

local function buildEnchanterAndChronosTab(body, snap)
	local isEn = I18n.GetLanguage() == "en"
	local eqWep = (snap.equipped and snap.equipped.Weapon) or "Dawnbringer"
	local wepCfg = AEC.Items[eqWep] or RarityConfig.GetItem(eqWep) or {}
	local wepName = tostring(isEn and (wepCfg.Name or eqWep) or (wepCfg.VietnameseName or wepCfg.Name or eqWep))
	local scrollCount = getOwnedQty(snap, "EnchantScroll")
	local lp = Players.LocalPlayer
	local activeEnchant = tostring((lp and lp:GetAttribute("WeaponEnchant")) or pick("Chưa khắc Phù Phép", "No Rune Inscribed"))
	local paidRestricted = (snap and snap.PaidRandomRestricted == true) or (lp and lp:GetAttribute("PaidRandomRestricted") == true)

	local leftPanel, rightPanel = mkSplitPanels(
		body, "EnchanterP", pick("NPC 6A: PHÁP SƯ PHÙ PHÉP CỔ NGỮ (KHẮC DÒNG VŨ KHÍ)", "NPC 6A: ARCANE ENCHANTER • WEAPON RUNES"),
		"ChronosP", pick("NPC 6B: THƯƠNG NHÂN HƯ KHÔNG CHRONOS (10 PHÚT)", "NPC 6B: CHRONOS WANDERING VOID MERCHANT")
	)

	makeGlossyRarityTile(leftPanel, wepCfg.Rarity or "Mythic", pick("VŨ KHÍ CHỌN", "SELECTED"), wepName, "Sword", u2o(108, 128), {
		Position = u2o(14, 52), RightTag = pick("CÓ SẴN", "READY"), IconSize = 36, DiscSize = 54, SubCaption = pick("Vũ khí trang bị", "Equipped Weapon"),
	})
	mkText(leftPanel, "Plus", "+", u2o(124, 98), u2o(20, 28), 20, GOLDB, true, TXC)
	makeGlossyRarityTile(leftPanel, "Legendary", "120 SHARDS", pick("Cuộn Phù Phép", "Enchant Scroll"), "Scroll", u2o(108, 128), {
		Position = u2o(146, 52), RightTag = pick("CÓ SẴN", "OWNED"), IconSize = 36, DiscSize = 54, SubCaption = pick("Đang có: x", "Owned: x") .. tostring(scrollCount),
	})

	local curBox = mkBox(leftPanel, "CurEnch", u2o(14, 188), u2o(240, 68), rgb(12, 20, 38), 8, GOLD, 1.3, 0.20)
	mkText(curBox, "CT", pick("PHÙ PHÉP HIỆN TẠI:", "ACTIVE WEAPON RUNE:"), u2o(10, 6), u2(1, -20, 0, 16), 10, GOLDB, true)
	local policySub = paidRestricted
		and pick("Tuân thủ vùng: Chỉ dùng Cuộn / Shards cày trong game", "Regional Policy: Earned Scrolls/Shards only")
		or pick("Chi phí khắc lại: 1 Cuộn hoặc 45K G + 100 Shards", "Reroll cost: 1 Scroll or 45K G + 100 Shards")
	mkText(curBox, "CV", activeEnchant .. "\n" .. policySub, u2o(10, 24), u2(1, -20, 0, 38), 10, SUCC, true, nil, true)

	local runeTable = (CoreConfig and type(CoreConfig.RuneOddsTable) == "table" and #CoreConfig.RuneOddsTable > 0) and CoreConfig.RuneOddsTable or FALLBACK_RUNE_ODDS
	local oddsCol = mkBox(leftPanel, "Odds", u2o(264, 52), u2(1, -278, 0, 206))
	UIFactory.ListLayout(oddsCol, Enum.FillDirection.Vertical, 5)
	for idx, rDef in ipairs(runeTable) do
		local rCol = RUNE_COLORS[rDef.Id] or GOLDB
		local pct = tonumber(rDef.ChancePct or rDef.Percent) or 20.0
		local rerollPct = tonumber(rDef.RerollPct) or 25.0
		local rName = isEn and (rDef.NameEn or rDef.Id) or (rDef.NameVi or rDef.Id)
		local rDesc = isEn and (rDef.DescEn or "") or (rDef.DescVi or "")
		local oddsTag = isEn
			and string.format("+ %s  [%.0f%% • Reroll %.0f%%]", rName, pct, rerollPct)
			or string.format("+ %s (%s)  [%.0f%% • Khắc lại %.0f%%]", tostring(rDef.Id), rName, pct, rerollPct)
		local rBox = mkBox(oddsCol, "E_" .. idx, nil, u2(1, 0, 0, 37), rgb(10, 16, 30), 6, rCol, 1, 0.35, nil, idx)
		mkText(rBox, "ET", oddsTag, u2o(8, 2), u2(1, -16, 0, 16), 10, rCol, true)
		mkText(rBox, "ED", rDesc, u2o(8, 18), u2(1, -16, 0, 15), 9, TEXT2, false)
	end

	mkBtn(leftPanel, "RollEnch", pick("KHẮC LẠI PHÙ PHÉP (1 CUỘN / 45K G + 100S)", "ROLL ENCHANT (1 SCROLL / 45K G + 100S)"), "gold", u2(0, 14, 1, -54), u2(0.52, -18, 0, 40),
		function() fireLegacyUIRequest("EnchantWeapon", { weaponId = eqWep }) end, { icon = "CoreShards" })
	mkBtn(leftPanel, "BuyScroll", pick("MUA CUỘN CỔ NGỮ (120 SHARDS)", "BUY SCROLL (120 SHARDS)"), "primary", u2(0.52, 4, 1, -54), u2(0.48, -18, 0, 40),
		function() fireUIAction("BuyVendorItem", { itemId = "EnchantScroll", autoEquip = false }) end, { icon = "Scroll" })

	local timerPill = uiCreate("Frame", rightPanel, {
		Name = "ChronosTimer", AnchorPoint = v2(1, 0), Position = u2(1, -14, 0, 10),
		Size = u2o(148, 26), BackgroundColor3 = rgb(48, 18, 38), BorderSizePixel = 0, ZIndex = 6,
	})
	UIFactory.Corner(timerPill, 6)
	UIFactory.Stroke(timerPill, DANG, 1.2, 0.2)
	NPCShop.Refs.VoidTimerLabel = mkText(timerPill, "VT", pick("RỜI ĐẢO SAU: ", "WARPS IN: ") .. formatClockCountdown(600 - (os.time() % 600)), nil, u2s(1, 1), 10, GOLDB, true, TXC, false, 7)

	mountVendorBustCard(rightPanel, {
		Position = u2o(14, 52), Size = u2o(104, 176), CardHeight = 136, ShowSubtitles = true,
		Archetype = "void_horns", Accent = VOIDP, Tag = "• 3D LIVE - CHRONOS",
		Title = pick("ĐẢO HIỆN TẠI:", "ACTIVE ISLAND:"), Location = pick("TRẠM GIAO THƯƠNG", "TRADE STATION"),
	})

	local voidWrap = mkBox(rightPanel, "VoidOffers", u2o(126, 52), u2(1, -140, 0, 184))
	UIFactory.ListLayout(voidWrap, Enum.FillDirection.Horizontal, 6)
	for idx, off in ipairs({
		{ "EnchantScroll", "Legendary", pick("CÒN 3/3", "3/3 LEFT"), pick("Cuộn Phù Phép", "Enchant Scroll"), "95 Shards (-20%)", "Scroll", "gold", "Shards" },
		{ "CoreEssence", "Epic", pick("CÒN 2/2", "2/2 LEFT"), pick("Tinh Hoa Lõi x2", "Core Essence x2"), "140 Shards", "CoreShards", "primary", "Shards" },
		{ "RandomFruitBox", "Mythic", pick("HIẾM+", "RARE+"), pick("Hộp Lõi Bí Ẩn", "Mystery Core Box"), "150K G + 250S", "Fruit", "gold", "" },
		{ "aion_chrono_cloak", "Mythic", pick("CÒN 1/1", "1/1 LEFT"), pick("Áo Choàng Aion", "Aion Cloak"), "1.25M + 1.5K S", "Crown", "primary", "" },
	}) do
		local col = mkBox(voidWrap, "VC_" .. idx, nil, u2(0.25, -5, 1, 0), nil, nil, nil, nil, nil, nil, idx)
		makeGlossyRarityTile(col, off[2], off[3], off[4], off[6], u2(1, 0, 0, 142), {
			Position = u2o(0, 0), RightTag = pick("CÓ SẴN", "LIVE"), IconSize = 32, DiscSize = 46, SubCaption = off[5],
		})
		mkBtn(col, "BV_" .. idx, pick("ĐỔI NGAY", "REDEEM"), off[7], u2o(0, 148), u2(1, 0, 0, 34), function()
			fireLegacyUIRequest("BuyVoidMerchant", { offerIndex = idx, itemId = off[1], currency = off[8], autoEquip = (off[1] == "aion_chrono_cloak") })
		end, { ts = 10, minTs = 8 })
	end

	local loreBox = mkBox(rightPanel, "Lore", u2o(14, 246), u2(1, -28, 1, -260), rgb(10, 16, 30), 8, STEEL, 1, 0.4)
	mkText(
		loreBox,
		"LT",
		pick(
			"CƠ CHẾ THƯƠNG NHÂN HƯ KHÔNG LƯU ĐỘNG (WORLD EVENT):\n• Mỗi 10 phút xuất hiện tại đảo ngẫu nhiên • Hộp Lõi Bí Ẩn cam kết từ phẩm Rare trở lên!\n• Bán vật phẩm giới hạn bằng Core Shards & Gold rẻ hơn 20-35% giá gốc!",
			"CHRONOS WANDERING VOID MERCHANT (WORLD EVENT):\n• Spawns every 10 minutes across islands • Mystery Core Box guarantees Rare+ Aether Cores!\n• Offers limited Core Shard & Gold contraband at 20-35% below standard rates!"
		),
		u2o(12, 8), u2(1, -24, 1, -16), 11, TEXT2, false, nil, true
	)
end

local function buildShipwrightTab(body, snap)
	local st = shopSt()
	st.shipFilter = st.shipFilter or "ALL"
	local unlockedShips = (snap and type(snap.unlockedShips) == "table" and snap.unlockedShips) or { SkySloop = true }
	local pLv = tonumber(snap and snap.player and snap.player.level) or 1
	local selId, items, selectedItem = st.selectedShipId or "LeviathanHunterShip", {}, nil
	local isEn = I18n.GetLanguage() == "en"

	for idx, sh in ipairs(VC.ShipwrightFleet or {}) do
		local isHeavy = (sh.Cannons or 2) >= 6
		if st.shipFilter == "ALL" or (st.shipFilter == "LIGHT" and not isHeavy) or (st.shipFilter == "HEAVY" and isHeavy) then
			local pGold = tonumber(sh.PriceGold) or 0
			local lvReq = tonumber(sh.LevelReq) or 1
			local isOwned = (sh.Id == "SkySloop") or (pGold == 0) or (unlockedShips[sh.Id] == true) or (sh.ShipId ~= nil and unlockedShips[sh.ShipId] == true)
			local lvLocked = (not isOwned) and (pLv < lvReq)
			local priceStr = isOwned and pick("TRIỆU HỒI NGAY (ĐÃ SỞ HỮU)", "SUMMON NOW (OWNED)")
				or (lvLocked and pick("CẦN LV." .. lvReq, "REQUIRES LV." .. lvReq) or (pick("MỞ KHÓA • ", "UNLOCK • ") .. fmt(pGold) .. " GOLD"))
			local heroBtnStr = isOwned and pick("TRIỆU HỒI NGAY (ĐÃ SỞ HỮU)", "SUMMON NOW (OWNED)")
				or (lvLocked and pick("CẦN ĐẠT LV." .. lvReq .. " • " .. fmt(pGold) .. " GOLD", "REACH LV." .. lvReq .. " • " .. fmt(pGold) .. " GOLD"))
				or (pick("ĐÓNG & TRIỆU HỒI CHIẾN HẠM (", "BUILD & SUMMON WARSHIP (") .. fmt(pGold) .. " GOLD)")
			local dispName = isEn and (sh.NameEn or sh.Id) or (sh.NameVi or sh.Id)
			local entry = {
				id = sh.Id, t = string.format("%d. %s", idx, dispName),
				st = sh.NameEn or sh.Id, r = sh.Rarity or "Legendary",
				ac = hexToColor(sh.AccentHex, GOLD), top = isOwned and pick("ĐÃ SỞ HỮU", "OWNED") or pick("TÀU 3D", "3D SHIP"), ic = "Ship",
				a3d = sh.Model3DKind or ("Ship_" .. sh.Id),
				hsub = isEn
					and string.format("HULL: %s HP • SPEED: %d STUDS/S • %d CANNONS • LV.%d", fmt(sh.HP or 6000), sh.Speed or 85, sh.Cannons or 4, lvReq)
					or string.format("ĐỘ BỀN THÂN TÀU: %s HP • TỐC BAY: %d STUDS/S • %d ĐẠI BÁC • LV.%d", fmt(sh.HP or 6000), sh.Speed or 85, sh.Cannons or 4, lvReq),
				csub = isEn
					and string.format("%s HP • Speed %d • %d Aether Cannons%s", fmt(sh.HP or 2500), sh.Speed or 85, sh.Cannons or 2, sh.HasHarpoon and " + Harpoon" or "")
					or string.format("%s HP • Tốc độ %d • %d Đại Bác Aether%s", fmt(sh.HP or 2500), sh.Speed or 85, sh.Cannons or 2, sh.HasHarpoon and " + Móc Cáp Harpoon" or ""),
				sb = {
					{
						isEn
							and string.format("Fleet Armament: %d Broadside Aether Cannons%s", sh.Cannons or 4, sh.HasHarpoon and " + Abyssal Harpoon" or "")
							or string.format("Vũ Trang Hạm Đội: %d Đại Bác Aether 2 mạn%s", sh.Cannons or 4, sh.HasHarpoon and " + 1 Móc Cáp Thủy Tổ Harpoon" or ""),
						isEn and sh.DescEn or sh.DescVi,
					},
					{
						pick("Sức Chứa Tổ Đội & Hạm Đội Crew: 1 Thuyền Trưởng + 5 Pháo Thủ", "Crew Deck Capacity: 1 Captain + 5 Aether Gunners"),
						pick("Chuyên dụng vượt vùng biển mây mù Danger Zone 6 và kéo Trái Tim Thủy Xà Vực Thẳm về cảng!", "Built for Danger Zone 6 expeditions and towing the Abyss Serpent Heart back to port!"),
					},
				},
				cbtn = priceStr,
				cvar = isOwned and "primary" or (lvLocked and "secondary" or ((sh.Rarity == "Mythic" or sh.Rarity == "Legendary") and "gold" or "primary")),
				hbtn = heroBtnStr,
				hvar = lvLocked and "secondary" or "gold", cicon = "Ship",
				sel = selFn(st, "selectedShipId", sh.Id),
				act = function()
					if isOwned then
						fireLegacyUIRequest("SpawnShip", { shipId = sh.Id })
						return
					end
					if lvLocked then
						Store.ShowToast(pick(string.format("Cần đạt Lv.%d để đóng chiến hạm [%s]!", lvReq, dispName), string.format("Reach Lv.%d to unlock [%s]!", lvReq, dispName)), "warning")
						return
					end
					fireUIAction("BuyVendorItem", { shipId = sh.Id })
				end,
			}
			table.insert(items, entry)
			if sh.Id == selId then selectedItem = entry end
		end
	end

	renderHeroAndTwoColCatalog(body, {
		BustArchetype = "captain_tricorn", BustAccent = GOLDB, BustTag = pick("• 3D LIVE - ĐÓNG TÀU", "• 3D LIVE - DOCKS"),
		BustTitle = pick("THỢ ĐÓNG TÀU CẢNG", "MASTER SHIPWRIGHT"), BustLocation = pick("Bến Cảng Sky Shipwright", "Sky Shipwright Dockyard"), SelectedItem = selectedItem or items[1], Items = items,
		FilterPills = {
			fPill(st, "shipFilter", "ALL", pick("TẤT CẢ 4 CHIẾN HẠM 3D", "ALL 4 3D WARSHIPS"), 182, "gold"),
			fPill(st, "shipFilter", "LIGHT", pick("THUYỀN TÂN THỦ & TUẦN TIỄU", "SLOOP & PATROL CRAFT"), 204, "primary"),
			fPill(st, "shipFilter", "HEAVY", pick("ĐẠI CHIẾN HẠM & THỦY XÀ", "GALLEON & LEVIATHAN"), 204, "gold"),
			{ ic = "Forge", lbl = pick("SỬA CHỮA 100% CHIẾN HẠM (500G)", "REPAIR SHIP HULL 100% (500G)"), var = "primary", w = 228, fn = function()
				fireLegacyUIRequest("RepairShip", {})
			end },
		},
	})
end

local function buildDrVegaAndTempleV4Tab(body, snap)
	local isEn = I18n.GetLanguage() == "en"
	local curRace = tostring((snap.fruits and snap.fruits.race) or "Skyborn")
	local v4Unlocked = (snap.fruits and snap.fruits.raceV4Active == true) or (Players.LocalPlayer and Players.LocalPlayer:GetAttribute("RaceV4Unlocked") == true)

	local leftPanel, rightPanel = mkSplitPanels(
		body, "DrVegaP", pick("NPC 8A: HỌC GIẢ AETHER • ĐỔI 6 TỘC HỆ & ĐỘT KÍCH LÕI", "NPC 8A: AETHER SCHOLAR • 6-LINEAGE LAB & CORE RAID"),
		"TempleV4P", pick("NPC 8B: TẾ ĐÀN ĐỀN THĂNG HOA • THỨC TỈNH CÁNH THĂNG HOA", "NPC 8B: ASCENSION SHRINE • ASCENSION WINGS")
	)

	mountVendorBustCard(leftPanel, {
		Position = u2o(14, 48), Size = u2o(96, 126), CardHeight = 122, ShowSubtitles = false,
		Archetype = "scientist_visor", Accent = rgb(45, 212, 191), Tag = pick("• 3D LIVE - HỌC GIẢ", "• 3D LIVE - SCHOLAR"),
	})

	local raceGrid = mkBox(leftPanel, "RaceGrid", u2o(118, 48), u2(1, -132, 0, 126))
	UIFactory.GridLayout(raceGrid, u2(0.333, -5, 0, 59), u2o(6, 6))
	for idx, r in ipairs(VC.RaceRerollOdds or {}) do
		local accent = hexToColor(r.AccentHex, GOLD)
		local isCur = (string.lower(curRace):find(string.lower(r.Id), 1, true) ~= nil)
		local rBox = mkBox(raceGrid, "R_" .. r.Id, nil, nil, isCur and rgb(30, 24, 14) or rgb(11, 18, 32), 8, isCur and GOLDB or accent, isCur and 1.8 or 1.0, isCur and 0.05 or 0.35, nil, idx)
		UIFactory.Icon(rBox, "Wing", u2o(6, 8), 20, accent)
		mkText(rBox, "RN", (isEn and r.NameEn) or r.NameVi or r.Id, u2o(30, 6), u2(1, -34, 0, 16), 11, TEXT1, true)
		mkText(rBox, "RO", isCur and (pick("ĐANG SỞ HỮU • ", "ACTIVE • ") .. tostring(r.ChancePercent) .. "%") or (pick("Tỷ lệ: ", "Odds: ") .. tostring(r.ChancePercent) .. "%"), u2o(8, 34), u2(1, -14, 0, 16), 9, isCur and GOLDB or GOLD, true)
	end

	mkBtn(leftPanel, "RerollRace", pick("ĐỔI TỘC HỆ NGẪU NHIÊN (300 CORE SHARDS)", "REROLL 6-LINEAGE (300 SHARDS)"), "gold", u2o(14, 184), u2(1, -28, 0, 38),
		function() fireLegacyUIRequest("RerollRace", {}) end, { icon = "CoreShards" })

	local raidBox = mkBox(leftPanel, "RaidBox", u2o(14, 230), u2(1, -28, 1, -244), rgb(10, 18, 34), 10, SAPPH, 1.3, 0.25)
	makeGlossyRarityTile(raidBox, "Mythic", pick("VI MẠCH", "MICROCHIP"), pick("Chip Raid", "Raid Chip"), "Settings", u2o(92, 114), { Position = u2o(10, 10), RightTag = pick("CÓ SẴN", "READY"), SubCaption = pick("100K Gold / 1 Lõi", "100K Gold / 1 Core") })
	mkText(raidBox, "RT", pick("BẢNG ĐIỀU KHIỂN ĐỘT KÍCH LÕI THỨC TỈNH (1-4 NGƯỜI)", "AWAKENED CORE RAID CONSOLE (1-4 PLAYERS)"), u2o(112, 10), u2(1, -122, 0, 18), 11, TEXT1, true)
	mkText(raidBox, "RD", pick("Chọn Raid Hệ: [Hỏa Dương] [Vĩnh Băng] [Thánh Quang] [Dung Nham] [Lôi Thần] [Kim Thân]\nPhần thưởng vượt 5 Đảo Raid: +1,000 Core Shards & Mở Lõi Thức Tỉnh!", "Select Element Raid: [Solar] [Glacier] [Light] [Magma] [Thunder] [Titan]\n5-Island Clear Reward: +1,000 Core Shards & V2 Core Awakening!"), u2o(112, 30), u2(1, -122, 0, 48), 10, SUCC, false, nil, true)
	mkBtn(raidBox, "BuyChip", pick("MUA CHIP RAID (100K GOLD)", "BUY CHIP (100K G)"), "gold", u2o(112, 86), u2(0.48, -62, 0, 36),
		function() fireUIAction("BuyVendorItem", { itemId = "AwakeningMicrochip", autoEquip = false }) end, { ts = 10, minTs = 8 })
	mkBtn(raidBox, "OpenRaid", pick("BẮT ĐẦU ĐỘT KÍCH RAID", "START CORE RAID"), "primary", u2(0.48, 56, 0, 86), u2(0.52, -66, 0, 36),
		function() ScreenRouter.Navigate(UIState.Screens.Raid) end, { icon = "Raid", ts = 10, minTs = 8 })

	local stepsRow = mkBox(rightPanel, "V4Steps", u2o(14, 48), u2(1, -28, 0, 146))
	UIFactory.ListLayout(stepsRow, Enum.FillDirection.Horizontal, 8)
	for sIdx, sd in ipairs({
		{ "Mythic", pick("BƯỚC 1", "STEP 1"), pick("BÁNH RĂNG XANH", "BLUE GEAR"), pick("Tìm trên Đảo Hư Quang", "Find on Phantom Isle"), "Settings" },
		{ "Epic", pick("BƯỚC 2", "STEP 2"), pick("CẦN GẠT CỔ ĐẠI", "ANCIENT LEVER"), pick("Vượt ải 60s Trăng Tròn", "Clear 60s Full-Moon Trial"), "CoreShards" },
		{ "Legendary", pick("BƯỚC 3", "STEP 3"), pick("KHẢM BÁNH RĂNG", "SOCKET GEAR"), pick("Chọn Nhánh Đỏ / Xanh", "Pick Crimson / Sapphire"), "Star" },
		{ "Mythic", pick("BƯỚC 4", "STEP 4"), pick("CÁNH THĂNG HOA 3D", "3D ASCENSION"), pick("Phím [Y] biến hình Thăng Hoa", "Press [Y] to Awaken V4"), "Wing" },
	}) do
		makeGlossyRarityTile(stepsRow, sd[1], sd[2], sd[3], sd[5], u2(0.25, -6, 1, 0), { LayoutOrder = sIdx, RightTag = pick("CÓ SẴN", "READY"), IconSize = 34, DiscSize = 50, SubCaption = sd[4] })
	end

	local wingBox = mkBox(rightPanel, "V4Wings", u2o(14, 202), u2(1, -28, 1, -264), rgb(10, 16, 30), 10, GOLD, 1.3, 0.22)
	local vp = uiCreate("ViewportFrame", wingBox, { Name = "WingVP", Position = u2o(6, 6), Size = u2o(156, 108), BackgroundTransparency = 1 })
	local wingKey = "Wing_Skyborn"
	local wingLabel = pick("THIÊN TỘC SKYBORN", "SKYBORN CELESTIAL")
	for _, wSpec in ipairs({
		{ "Skyborn", "THIÊN TỘC SKYBORN", "SKYBORN CELESTIAL" },
		{ "Mink", "LINH VŨ AZUREFANG", "AZUREFANG SWIFT" },
		{ "Leviathan", "HẢI VƯƠNG TIDEBORN", "TIDEBORN SOVEREIGN" },
		{ "Cyborg", "CƠ GIỚI CYBORG", "CYBERNETIC CONSTRUCT" },
		{ "Ghoul", "DẠ ẢNH UMBRAL", "UMBRAL NIGHTWALKER" },
		{ "Draco", "CỔ LONG DRACO", "ANCIENT DRACO" },
	}) do
		if string.lower(curRace):find(string.lower(wSpec[1]), 1, true) then
			wingKey = "Wing_" .. wSpec[1]
			wingLabel = isEn and wSpec[3] or wSpec[2]
			break
		end
	end
	ViewportOrbit.MountAssetAsync(attachTrackedOrbit(vp), wingKey, GOLDB, { FitMultiplier = 1.08, ResetAngles = true })
	mkText(
		wingBox,
		"WI",
		isEn
			and string.format("ASCENSION WINGS BLESSING [%s]:\n• Unlocks bespoke glowing 3D Lineage Wings.\n• Ascension Aura reflects damage & boosts all stats by +30%% when pressing [Y]!", wingLabel)
			or string.format("NÂNG CẤP THIÊN PHÚ CÁNH THĂNG HOA [%s]:\n• Mở khóa Đôi Cánh 3D phát sáng độc quyền theo Huyết Thống.\n• Hào quang Thăng Hoa phản sát thương & +30%% toàn bộ chỉ số khi bật [Y]!", wingLabel),
		u2o(170, 10), u2(1, -182, 1, -20), 11, TEXT1, false, nil, true
	)

	mkBtn(rightPanel, "StartV4", v4Unlocked and pick("ĐÃ THĂNG HOA • VÀO ẢI CORE GEAR", "ASCENSION AWAKENED • ENTER GEAR TRIAL") or pick("KÉO CẦN GẠT BẮT ĐẦU ẢI CỔ ĐẠI (60S)", "PULL ANCIENT LEVER • START 60S TRIAL"),
		"gold", u2(0, 14, 1, -52), u2(0.52, -18, 0, 40), function() fireUIAction("StartTempleV4Trial", {}) end, { icon = "Flame" })
	mkBtn(rightPanel, "SocketV4", pick("KHẢM BÁNH RĂNG THĂNG HOA [G]", "SOCKET ASCENSION GEAR [G]"), "primary", u2(0.52, 4, 1, -52), u2(0.48, -18, 0, 40),
		function() ScreenRouter.Navigate("Fruits:Vault") end, { icon = "Wing" })
end

local function getFruitMeta(fid)
	local canonId = normalizeFruitId(fid)
	local fCfg = CoreConfig.AetherFruits and (CoreConfig.AetherFruits[canonId] or CoreConfig.AetherFruits[fid])
	for _, m in ipairs(MIRAGE_FRUITS) do
		if m[1] == canonId then
			local authPrice = tonumber(fCfg and fCfg.Price) or m[5]
			local authRarity = tostring((fCfg and fCfg.Rarity) or m[4])
			return m[2], authRarity, authPrice
		end
	end
	if fCfg then
		return tostring(fCfg.Name or canonId), tostring(fCfg.Rarity or "Legendary"), tonumber(fCfg.Price) or 1250000
	end
	local itemCfg = (AEC.Items and AEC.Items[canonId]) or RarityConfig.GetItem(canonId) or (CoreConfig.Items and CoreConfig.Items[canonId])
	if itemCfg then
		local pr = tonumber(itemCfg.PriceGold or itemCfg.Price) or 250000
		return tostring(itemCfg.VietnameseName or itemCfg.Name or canonId), tostring(itemCfg.Rarity or "Legendary"), pr
	end
	return tostring(canonId), "Legendary", 250000
end

local function renderCollectorSoloBoard(subBody, snap, st)
	st.tradeOffer = type(st.tradeOffer) == "table" and st.tradeOffer or {}
	local pacts = VC.CollectorTrades or {}
	local selPactId, selPact = st.selectedPactId or (pacts[1] and pacts[1].Id), pacts[1]
	for _, p in ipairs(pacts) do if p.Id == selPactId then selPact = p; break end end

	local giveList = (#st.tradeOffer > 0) and st.tradeOffer or ((selPact and selPact.GiveItems) or {})
	local recvList = (selPact and selPact.ReceiveItems) or {}
	local giveSet, recvSet, hasOverlap = {}, {}, false
	local giveVal, recvVal = 0, 0
	for _, fid in ipairs(recvList) do
		local norm = normalizeFruitId(fid)
		recvSet[norm] = true
		local _, _, pr = getFruitMeta(norm)
		recvVal += pr
	end
	for _, fid in ipairs(giveList) do
		local norm = normalizeFruitId(fid)
		giveSet[norm] = (giveSet[norm] or 0) + 1
		if recvSet[norm] then hasOverlap = true end
		local _, _, pr = getFruitMeta(norm)
		giveVal += pr
	end

	local maxRecvAllowed = math.floor(giveVal * 1.05)
	local withinCollectorCap = (giveVal > 0) and (recvVal <= maxRecvAllowed)
	local diffPct = (math.abs(giveVal - recvVal) / math.max(giveVal, recvVal, 1)) * 100
	local withinAntiScam = (giveVal > 0) and (diffPct <= 40.0)
	local isFair = (not hasOverlap) and withinCollectorCap and withinAntiScam
	local lpName = UIFactory.Upper(tostring((Players.LocalPlayer and Players.LocalPlayer.Name) or "SKYBORN"))

	local sideA, sideB = mkSplitPanels(
		subBody,
		"SideA",
		pick(string.format("BÊN A: %s (BẠN) • BÀN ĐẶT 4 Ô", lpName), string.format("SIDE A: %s (YOU) • 4 OFFER SLOTS", lpName)),
		"SideB",
		pick("BÊN B: NHÀ SƯU TẬP NPC (NHẬN <= 105% ĐƯA)", "SIDE B: NPC COLLECTOR (RECEIVE <= 105% OFFER)"),
		54
	)
	local gridA = mkBox(sideA, "GridA", u2o(14, 46), u2(1, -28, 0, 184))
	UIFactory.GridLayout(gridA, u2(0.5, -6, 0, 87), u2o(10, 8))

	for i = 1, 4 do
		local fid = giveList[i]
		if fid then
			local fName, fRar, fPrice = getFruitMeta(fid)
			local wrap = uiCreate("TextButton", gridA, { Name = "SA_" .. i, BackgroundTransparency = 1, Text = "", LayoutOrder = i })
			makeGlossyRarityTile(wrap, fRar, pick("Ô ", "SLOT ") .. i, fName, "Fruit", u2s(1, 1), { Position = u2o(0, 0), RightTag = pick("XÓA", "DEL"), SubCaption = pick("Giá trị: ", "Value: ") .. fmt(fPrice) })
			wrap.Activated:Connect(function() if #st.tradeOffer >= i then table.remove(st.tradeOffer, i); NPCShop.RebuildWorkspace() end end)
		else
			local emptySlot = uiCreate("TextButton", gridA, {
				Name = "EA_" .. i, BackgroundColor3 = rgb(10, 16, 30), BorderSizePixel = 0,
				Text = pick("+ THÊM LÕI KHO (Ô " .. i .. ")", "+ ADD VAULT CORE (SLOT " .. i .. ")"), Font = Theme.Fonts.Bold, TextSize = 11, TextColor3 = TEXT2, LayoutOrder = i,
			})
			UIFactory.Corner(emptySlot, 10)
			UIFactory.Stroke(emptySlot, STEEL, 1.2, 0.45)
			emptySlot.Activated:Connect(function()
				local storedMap = (snap and snap.fruits and snap.fruits.storedFruits) or {}
				local usedCounts = {}
				for _, curId in ipairs(st.tradeOffer) do
					local cNorm = normalizeFruitId(curId)
					usedCounts[cNorm] = (usedCounts[cNorm] or 0) + 1
				end
				for sFid, qty in pairs(storedMap) do
					local cNorm = normalizeFruitId(sFid)
					local avail = (tonumber(qty) or 0) - (usedCounts[cNorm] or 0)
					if avail > 0 and not recvSet[cNorm] and #st.tradeOffer < 4 then
						table.insert(st.tradeOffer, cNorm)
						NPCShop.RebuildWorkspace()
						return
					end
				end
				Store.ShowToast(pick("Không còn Lõi hợp lệ trong Kho (không trùng Lõi bên Nhận)!", "No eligible non-duplicate Cores in Vault!"), "warning")
			end)
		end
	end
	mkText(sideA, "GiveVal", pick("TỔNG ĐƯA: ", "OFFER VALUE: ") .. fmt(giveVal) .. " GOLD (" .. pick("TRẦN NHẬN 105%: ", "105% CAP: ") .. fmt(maxRecvAllowed) .. ")", u2(0, 14, 1, -28), u2(1, -28, 0, 20), 10, GOLDB, true, TXC)

	local gridB = mkBox(sideB, "GridB", u2o(14, 46), u2(1, -28, 0, 184))
	UIFactory.GridLayout(gridB, u2(0.5, -6, 0, 87), u2o(10, 8))
	for i = 1, 3 do
		local fid = recvList[i]
		if fid then
			local fName, fRar, fPrice = getFruitMeta(fid)
			local holder = mkBox(gridB, "SB_" .. i, nil, nil, nil, nil, nil, nil, nil, nil, i)
			makeGlossyRarityTile(holder, fRar, pick("Ô ", "SLOT ") .. i, fName, "Fruit", u2s(1, 1), { Position = u2o(0, 0), RightTag = pick("CÓ SẴN", "READY"), SubCaption = pick("Giá trị: ", "Value: ") .. fmt(fPrice) })
		else
			mkText(mkBox(gridB, "EB_" .. i, nil, nil, rgb(10, 16, 30), 10, STEEL, 1, 0.5, nil, i), "T", pick("Ô NPC ", "NPC SLOT ") .. i, nil, u2s(1, 1), 11, TEXT2, true, TXC)
		end
	end

	mountVendorBustCard(mkBox(gridB, "ColCell", nil, nil, nil, nil, nil, nil, nil, nil, 4), {
		Position = u2o(0, 0), Size = u2o(140, 86), CardHeight = 84, ShowSubtitles = false,
		Archetype = "collector_tophat", Accent = GOLDB, Tag = pick("• 3D NPC - SƯU TẬP", "• 3D NPC - COLLECTOR"),
	})

	local pactRow = mkBox(sideB, "Pacts", u2o(14, 236), u2(1, -28, 0, 30))
	UIFactory.ListLayout(pactRow, Enum.FillDirection.Horizontal, 6)
	for pIdx, pact in ipairs(pacts) do
		local isSel = (selPact and selPact.Id == pact.Id)
		mkBtn(pactRow, "Pact_" .. pIdx, pick("KHẾ ƯỚC #", "PACT #") .. pIdx, isSel and "gold" or "secondary", nil, u2(0.25, -5, 1, 0),
			function() st.selectedPactId = pact.Id; st.tradeOffer = {}; NPCShop.RebuildWorkspace() end, { selected = isSel, ts = 10, minTs = 8, order = pIdx })
	end
	mkText(sideB, "RecvVal", pick("TỔNG GIÁ TRỊ NHẬN VỀ: ", "RECEIVE VALUE: ") .. fmt(recvVal) .. " GOLD", u2(0, 14, 1, -28), u2(1, -28, 0, 20), 11, SUCC, true, TXC)

	local ruleMsg = isFair and pick(string.format("LỆCH %.1f%% • NHẬN <= 105%% ĐƯA • HỢP LỆ CHỐNG LỪA ĐẢO", diffPct), string.format("GAP %.1f%% • <= 105%% OFFER • ANTI-SCAM VALID", diffPct))
		or (hasOverlap and pick("KHÓA: TRÙNG LÕI Ở BÊN ĐƯA & BÊN NHẬN!", "LOCKED: DUPLICATE CORE ON BOTH SIDES!")
			or ((not withinCollectorCap) and pick(string.format("KHÓA: NHẬN VƯỢT 105%% ĐƯA (TỐI ĐA %s GOLD)", fmt(maxRecvAllowed)), string.format("LOCKED: EXCEEDS 105%% CAP (MAX %s GOLD)", fmt(maxRecvAllowed)))
				or pick(string.format("KHÓA: CHÊNH LỆCH %.1f%% (> 40%% BẢO VỆ)", diffPct), string.format("LOCKED: %.1f%% VALUE GAP (> 40%% GUARD)", diffPct))))
	local meterBox = mkBox(subBody, "AntiScam", u2(0, 0, 1, -44), u2(0.56, -8, 0, 42), isFair and rgb(8, 56, 40) or rgb(64, 18, 28), 10, isFair and SUCC or DANG, 1.5, 0.12)
	mkText(meterBox, "MT", ruleMsg, nil, u2s(1, 1), 10, isFair and SUCC or DANG, true, TXC)

	local lockBtnLbl = hasOverlap and pick("TRÙNG LÕI", "DUPLICATE")
		or ((not withinCollectorCap) and pick("VƯỢT 105% ĐƯA", "OVER 105% CAP") or pick("ĐÃ KHÓA (>40%)", "LOCKED (>40%)"))
	mkBtn(subBody, "ExecTrade", isFair and pick("XÁC NHẬN ĐỔI NPC", "CONFIRM NPC TRADE") or lockBtnLbl,
		isFair and "gold" or "secondary", u2(0.56, 4, 1, -44), u2(0.28, -8, 0, 42), function()
			if not isFair then return end
			if #st.tradeOffer > 0 then fireUIAction("TradeWithCollector", { giveFruits = st.tradeOffer, receiveFruits = recvList })
			elseif selPact then fireUIAction("TradeWithCollector", { offerId = selPact.Id }) end
		end, { disabled = not isFair, ts = 11 })
	mkBtn(subBody, "ResetTrade", pick("HỦY BỎ", "CLEAR"), "danger", u2(0.84, 4, 1, -44), u2(0.16, -4, 0, 42),
		function() st.tradeOffer = {}; NPCShop.RebuildWorkspace() end, { ts = 11 })
end

local function buildTradingTableTab(body, snap)
	local st = shopSt()
	local p2p = (snap and snap.p2pTrade) or {}
	local isP2PActive = (p2p.Active == true)
	local pendingFrom = tostring(p2p.PendingFrom or "")

	if isP2PActive or pendingFrom ~= "" then
		st.tradeMode = "P2P"
	elseif st.tradeMode ~= "P2P" and st.tradeMode ~= "Collector" then
		st.tradeMode = "P2P"
	end

	-- Top Sub-Mode Toggle Bar: [GIAO DỊCH P2P 2 NGƯỜI CHƠI] vs [NPC COLLECTOR (SOLO)]
	local modeBar = mkBox(body, "TradeModeToggleBar", u2o(0, 0), u2(1, 0, 0, 34))
	mkBtn(modeBar, "ModeP2PBtn",
		isP2PActive and pick("• ĐANG GIAO DỊCH P2P TRỰC TIẾP (2 NGƯỜI CHƠI)", "• LIVE 2-PLAYER P2P TRADE ACTIVE")
			or pick("GIAO DỊCH P2P 2 NGƯỜI CHƠI", "2-PLAYER LIVE P2P TRADE"),
		(st.tradeMode == "P2P") and "gold" or "secondary",
		u2o(0, 0), u2(0.52, -4, 1, 0),
		function()
			st.tradeMode = "P2P"
			fireUIAction("P2PTradeAction", { subAction = "Refresh" })
			NPCShop.RebuildWorkspace()
		end,
		{ icon = "Trade", selected = (st.tradeMode == "P2P"), ts = 11, minTs = 9 }
	)
	mkBtn(modeBar, "ModeCollectorBtn",
		pick("NHÀ SƯU TẬP NPC (GIAO DỊCH SOLO)", "NPC COLLECTOR (SOLO TRADE)"),
		(st.tradeMode == "Collector") and "gold" or "secondary",
		u2(0.52, 4, 0, 0), u2(0.48, -4, 1, 0),
		function()
			if isP2PActive then
				Store.ShowToast(pick("Hãy hoàn tất hoặc bấm [Hủy] phiên P2P hiện tại trước khi chuyển sang NPC!", "Finish or Cancel your active P2P trade first!"), "warning")
				return
			end
			st.tradeMode = "Collector"
			NPCShop.RebuildWorkspace()
		end,
		{ icon = "Crown", selected = (st.tradeMode == "Collector"), disabled = isP2PActive, ts = 11, minTs = 9 }
	)

	local subBody = mkBox(body, "TradeSubWorkspace", u2o(0, 40), u2(1, 0, 1, -40))

	if st.tradeMode == "Collector" and not isP2PActive then
		renderCollectorSoloBoard(subBody, snap, st)
		return
	end

	-- P2P LIVE ACTIVE 2-PLAYER BOARD
	if isP2PActive then
		local partnerLabel = tostring(p2p.PartnerName or "")
		if partnerLabel == "" then partnerLabel = pick("ĐỐI PHƯƠNG", "PARTNER") end
		local myOffer = type(p2p.MyOffer) == "table" and p2p.MyOffer or {}
		local partnerOffer = type(p2p.PartnerOffer) == "table" and p2p.PartnerOffer or {}

		-- Count items already placed in MyOffer so bag reflects remaining available stock
		local offeredFruitCount, offeredItemCount = {}, {}
		for _, off in ipairs(myOffer) do
			local oid = type(off) == "table" and tostring(off.Id or "") or tostring(off)
			local isFr = (type(off) ~= "table") or (off.IsFruit ~= false)
			if isFr then
				local nf = normalizeFruitId(oid)
				offeredFruitCount[nf] = (offeredFruitCount[nf] or 0) + 1
			else
				offeredItemCount[oid] = (offeredItemCount[oid] or 0) + 1
			end
		end

		-- Column 1 (34%): TÚI CỦA BẠN
		local bagPanel = PremiumPanel.Create(subBody, {
			name = "MyBagPanel",
			title = pick("TÚI CỦA BẠN (BẤM ĐỂ ĐẶT LÊN BÀN)", "YOUR BAG (CLICK TO OFFER)"),
			position = u2o(0, 0),
			size = u2(0.34, -6, 1, -50),
		})
		local bagScroll = uiCreate("ScrollingFrame", bagPanel, {
			Name = "BagScroll",
			Position = u2o(10, 44),
			Size = u2(1, -20, 1, -52),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = GOLD,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = u2o(0, 0),
		})
		UIFactory.ListLayout(bagScroll, Enum.FillDirection.Vertical, 6)

		local bagEntries = {}
		local storedFruits = (snap and snap.fruits and snap.fruits.storedFruits) or {}
		for fid, qty in pairs(storedFruits) do
			local normFid = normalizeFruitId(fid)
			local remQty = (tonumber(qty) or 0) - (offeredFruitCount[normFid] or 0)
			if remQty > 0 then
				local fName, fRar, fPrice = getFruitMeta(normFid)
				table.insert(bagEntries, {
					id = normFid, name = fName, rarity = fRar, value = fPrice, count = remQty, isFruit = true,
				})
			end
		end
		for _, inv in ipairs((snap and snap.inventory) or {}) do
			local iid = tostring(inv.itemId or "")
			local remQty = (tonumber(inv.count) or 0) - (offeredItemCount[iid] or 0)
			if iid ~= "" and remQty > 0 then
				local iName, iRar, iPrice = getFruitMeta(iid)
				table.insert(bagEntries, {
					id = iid, name = tostring(inv.name or iName), rarity = tostring(inv.rarity or iRar), value = iPrice, count = remQty, isFruit = false,
				})
			end
		end
		table.sort(bagEntries, function(a, b)
			if a.isFruit ~= b.isFruit then return a.isFruit end
			return (a.value or 0) > (b.value or 0)
		end)

		if #bagEntries == 0 then
			mkText(bagScroll, "EmptyBag", pick("Kho Lõi Vĩnh Viễn & Túi của bạn hiện không còn vật phẩm dư để đặt thêm.", "No extra Vault Cores or tradeable items remaining."),
				u2o(6, 8), u2(1, -12, 0, 54), 10, TEXT2, false, TXL, true)
		else
			for idx, entry in ipairs(bagEntries) do
				local pal = getRarityStyle(entry.rarity)
				local rowBtn = uiCreate("TextButton", bagScroll, {
					Name = "BagItem_" .. idx,
					Size = u2(1, -6, 0, 44),
					BackgroundColor3 = rgb(12, 19, 36),
					BorderSizePixel = 0,
					Text = "",
					AutoButtonColor = true,
					LayoutOrder = idx,
				})
				UIFactory.Corner(rowBtn, 8)
				UIFactory.Stroke(rowBtn, pal[3], 1.1, 0.25)
				mkText(rowBtn, "IName", string.format("%s  (x%d)", entry.name, entry.count), u2o(10, 4), u2(1, -86, 0, 18), 11, TEXT1, true)
				mkText(rowBtn, "IVal", string.format("%s • %s: %s", entry.isFruit and pick("LÕI AETHER", "3D CORE") or pick("VẬT PHẨM", "ITEM"), pick("Giá trị", "Value"), fmt(entry.value)), u2o(10, 22), u2(1, -86, 0, 16), 9, pal[3], true)
				mkText(rowBtn, "AddTag", pick("+ ĐẶT Ô", "+ ADD"), u2(1, -72, 0, 0), u2o(64, 44), 10, GOLDB, true, TXC)
				rowBtn.Activated:Connect(function()
					if #myOffer >= 4 then
						Store.ShowToast(pick("Bạn đã đặt tối đa 4 ô giao dịch!", "All 4 offer slots are full!"), "warning")
						return
					end
					fireUIAction("P2PTradeAction", {
						subAction = "AddItem",
						itemId = entry.id,
						fruitId = entry.isFruit and entry.id or nil,
						isFruit = entry.isFruit,
					})
				end)
			end
		end

		-- Column 2 (33%): Ô GIAO DỊCH CỦA BẠN (4 Ô)
		local myPanel = PremiumPanel.Create(subBody, {
			name = "MyOfferPanel",
			variant = "gold",
			title = pick("Ô GIAO DỊCH CỦA BẠN (4 Ô)", "YOUR OFFER SLOTS (4)"),
			position = u2(0.34, 2, 0, 0),
			size = u2(0.33, -4, 1, -50),
		})
		local myStateText = p2p.MyConfirmed and pick("TRẠNG THÁI: ĐÃ XÁC NHẬN ✓", "STATUS: CONFIRMED ✓")
			or (p2p.MyReady and pick("TRẠNG THÁI: ĐÃ SẴN SÀNG ✓", "STATUS: READY ✓")
				or pick("TRẠNG THÁI: ĐANG CHỌN ĐỒ...", "STATUS: SELECTING ITEMS..."))
		local myBadge = mkBox(myPanel, "MyReadyBadge", u2o(12, 42), u2(1, -24, 0, 24),
			(p2p.MyConfirmed or p2p.MyReady) and rgb(10, 52, 38) or rgb(16, 24, 44), 6,
			(p2p.MyConfirmed or p2p.MyReady) and SUCC or SAPPH, 1.2, 0.2)
		mkText(myBadge, "Txt", myStateText, nil, u2s(1, 1), 10, (p2p.MyConfirmed or p2p.MyReady) and SUCC or SAPPH, true, TXC)

		local myGrid = mkBox(myPanel, "MySlots4", u2o(12, 72), u2(1, -24, 1, -108))
		UIFactory.GridLayout(myGrid, u2(0.5, -5, 0.5, -5), u2o(8, 8))
		for i = 1, 4 do
			local off = myOffer[i]
			if off then
				local oid = type(off) == "table" and tostring(off.Id or "") or tostring(off)
				local fName, fRar, fPrice = getFruitMeta(oid)
				local dispName = (type(off) == "table" and off.Name) and tostring(off.Name) or fName
				local dispVal = (type(off) == "table" and tonumber(off.Value)) or fPrice
				local slotBtn = uiCreate("TextButton", myGrid, { Name = "MySlot_" .. i, BackgroundTransparency = 1, Text = "", LayoutOrder = i })
				makeGlossyRarityTile(slotBtn, fRar, pick("Ô ", "SLOT ") .. i, dispName, (type(off) == "table" and off.IsFruit == false) and "Sword" or "Fruit",
					u2s(1, 1), { Position = u2o(0, 0), RightTag = pick("GỠ", "DEL"), RightColor = DANG, SubCaption = fmt(dispVal) .. " G" })
				slotBtn.Activated:Connect(function()
					fireUIAction("P2PTradeAction", { subAction = "RemoveOffer", slotIndex = i, itemId = oid })
				end)
			else
				local empty = mkBox(myGrid, "MyEmpty_" .. i, nil, nil, rgb(10, 16, 30), 10, STEEL, 1.1, 0.45, nil, i)
				mkText(empty, "T", pick("Ô CỦA BẠN #" .. i .. "\n(Trống)", "YOUR SLOT #" .. i .. "\n(Empty)"), u2o(6, 0), u2(1, -12, 1, 0), 10, TEXT2, true, TXC, true)
			end
		end
		mkText(myPanel, "MyValTxt", pick("TỔNG CỦA BẠN: ", "YOUR TOTAL: ") .. fmt(tonumber(p2p.MyValue) or 0) .. " GOLD",
			u2(0, 12, 1, -28), u2(1, -24, 0, 22), 11, GOLDB, true, TXC)

		-- Column 3 (33%): Ô CỦA ĐỐI PHƯƠNG (<PartnerName>)
		local partnerPanel = PremiumPanel.Create(subBody, {
			name = "PartnerOfferPanel",
			variant = "gold",
			title = pick(string.format("Ô CỦA ĐỐI PHƯƠNG: %s", UIFactory.Upper(partnerLabel)), string.format("PARTNER OFFER: %s", UIFactory.Upper(partnerLabel))),
			position = u2(0.67, 2, 0, 0),
			size = u2(0.33, -2, 1, -50),
		})
		local ptStateText = p2p.PartnerConfirmed and pick("ĐỐI PHƯƠNG: ĐÃ XÁC NHẬN ✓", "PARTNER: CONFIRMED ✓")
			or (p2p.PartnerReady and pick("ĐỐI PHƯƠNG: ĐÃ SẴN SÀNG ✓", "PARTNER: READY ✓")
				or pick("ĐỐI PHƯƠNG: ĐANG CHỌN ĐỒ...", "PARTNER: SELECTING..."))
		local ptBadge = mkBox(partnerPanel, "PartnerReadyBadge", u2o(12, 42), u2(1, -24, 0, 24),
			(p2p.PartnerConfirmed or p2p.PartnerReady) and rgb(10, 52, 38) or rgb(24, 18, 38), 6,
			(p2p.PartnerConfirmed or p2p.PartnerReady) and SUCC or VOIDP, 1.2, 0.2)
		mkText(ptBadge, "Txt", ptStateText, nil, u2s(1, 1), 10, (p2p.PartnerConfirmed or p2p.PartnerReady) and SUCC or rgb(216, 180, 254), true, TXC)

		local ptGrid = mkBox(partnerPanel, "PartnerSlots4", u2o(12, 72), u2(1, -24, 1, -108))
		UIFactory.GridLayout(ptGrid, u2(0.5, -5, 0.5, -5), u2o(8, 8))
		for i = 1, 4 do
			local off = partnerOffer[i]
			if off then
				local oid = type(off) == "table" and tostring(off.Id or "") or tostring(off)
				local fName, fRar, fPrice = getFruitMeta(oid)
				local dispName = (type(off) == "table" and off.Name) and tostring(off.Name) or fName
				local dispVal = (type(off) == "table" and tonumber(off.Value)) or fPrice
				local holder = mkBox(ptGrid, "PtSlot_" .. i, nil, nil, nil, nil, nil, nil, nil, nil, i)
				makeGlossyRarityTile(holder, fRar, pick("Ô ", "SLOT ") .. i, dispName, (type(off) == "table" and off.IsFruit == false) and "Sword" or "Fruit",
					u2s(1, 1), { Position = u2o(0, 0), RightTag = pick("ĐỐI TÁC", "THEIRS"), SubCaption = fmt(dispVal) .. " G" })
			else
				local empty = mkBox(ptGrid, "PtEmpty_" .. i, nil, nil, rgb(10, 16, 30), 10, STEEL, 1.1, 0.45, nil, i)
				mkText(empty, "T", pick("Ô ĐỐI PHƯƠNG #" .. i .. "\n(Trống)", "PARTNER #" .. i .. "\n(Empty)"), u2o(6, 0), u2(1, -12, 1, 0), 10, TEXT2, true, TXC, true)
			end
		end
		mkText(partnerPanel, "PtValTxt", pick("TỔNG ĐỐI PHƯƠNG: ", "PARTNER TOTAL: ") .. fmt(tonumber(p2p.PartnerValue) or 0) .. " GOLD",
			u2(0, 12, 1, -28), u2(1, -24, 0, 22), 11, SUCC, true, TXC)

		-- Bottom Anti-Scam Meter + [Sẵn Sàng] + [Xác Nhận Giao Dịch] + [Hủy]
		local diffVal = tonumber(p2p.DiffPct) or 0
		local isFairP2P = (p2p.IsFair ~= false)
		local fairText = (#myOffer == 0 and #partnerOffer == 0)
			and pick("HÃY ĐẶT ÍT NHẤT 1 LÕI / VẬT PHẨM LÊN BÀN ĐỂ BẮT ĐẦU", "PLACE AT LEAST 1 ITEM TO BEGIN")
			or (isFairP2P
				and pick(string.format("AN TOÀN CHỐNG LỪA ĐẢO • CHÊNH LỆCH %.1f%% (<= 40%%)", diffVal), string.format("ANTI-SCAM SAFE • %.1f%% VALUE GAP (<= 40%%)", diffVal))
				or tostring(p2p.FairWarning or pick(string.format("CẢNH BÁO: CHÊNH LỆCH %.1f%% (> 40%% KHÓA BẢO VỆ)!", diffVal), string.format("WARNING: %.1f%% VALUE GAP (> 40%% GUARD LOCKED)!", diffVal))))

		local fairBox = mkBox(subBody, "P2PFairMeter", u2(0, 0, 1, -44), u2(0.42, -6, 0, 42),
			isFairP2P and rgb(8, 52, 38) or rgb(64, 18, 28), 10, isFairP2P and SUCC or DANG, 1.4, 0.15)
		mkText(fairBox, "Txt", fairText, u2o(8, 0), u2(1, -16, 1, 0), 10, isFairP2P and SUCC or DANG, true, TXC)

		mkBtn(subBody, "P2PReadyBtn",
			p2p.MyReady and pick("BỎ SẴN SÀNG", "UNREADY") or pick("SẴN SÀNG", "READY"),
			p2p.MyReady and "secondary" or "primary",
			u2(0.42, 2, 1, -44), u2(0.19, -4, 0, 42),
			function()
				fireUIAction("P2PTradeAction", { subAction = "ToggleReady" })
			end,
			{ selected = p2p.MyReady == true, ts = 11, minTs = 9 }
		)

		local canConfirm = (p2p.MyReady == true) and (p2p.PartnerReady == true) and isFairP2P and (not p2p.MyConfirmed)
		local confirmLbl = p2p.MyConfirmed
			and pick("ĐANG CHỜ ĐỐI PHƯƠNG...", "WAITING PARTNER...")
			or ((p2p.MyReady and p2p.PartnerReady) and pick("XÁC NHẬN GIAO DỊCH", "CONFIRM TRADE") or pick("CHỜ CẢ 2 SẴN SÀNG", "WAIT BOTH READY"))

		mkBtn(subBody, "P2PConfirmBtn", confirmLbl,
			canConfirm and "gold" or "secondary",
			u2(0.61, 2, 1, -44), u2(0.25, -4, 0, 42),
			function()
				fireUIAction("P2PTradeAction", { subAction = "Confirm" })
			end,
			{ disabled = not canConfirm, ts = 11, minTs = 8 }
		)

		mkBtn(subBody, "P2PCancelBtn", pick("HỦY", "CANCEL"), "danger",
			u2(0.86, 2, 1, -44), u2(0.14, -2, 0, 42),
			function()
				fireUIAction("P2PTradeAction", { subAction = "Cancel" })
			end,
			{ ts = 11, minTs = 9 }
		)
		return
	end

	-- P2P LOBBY MODE (No active session yet: Invite nearby/online players, accept incoming invite, or switch to NPC Collector)
	if os.clock() - (NPCShop.LastP2PRefreshAt or 0) > 3.0 then
		NPCShop.LastP2PRefreshAt = os.clock()
		fireUIAction("P2PTradeAction", { subAction = "Refresh" })
	end

	local lobbyLeft, lobbyRight = mkSplitPanels(
		subBody,
		"P2PInvitePanel", pick("MỜI GIAO DỊCH P2P (NGƯỜI CHƠI GẦN ĐÂY / ONLINE)", "INVITE PLAYER TO LIVE P2P TRADE"),
		"P2PGuidePanel", pick("BÀN GIAO DỊCH HOLO 4 Ô & CHỐNG LỪA ĐẢO", "4-SLOT HOLO TRADE & ANTI-SCAM"),
		0
	)

	local yStart = 46
	if pendingFrom ~= "" then
		local invBanner = mkBox(lobbyLeft, "IncomingP2PBanner", u2o(14, 46), u2(1, -28, 0, 62), rgb(20, 36, 64), 10, GOLDB, 1.5, 0.08)
		mkText(invBanner, "InvTitle", pick("LỜI MỜI GIAO DỊCH P2P TỪ: " .. pendingFrom, "P2P TRADE INVITE FROM: " .. pendingFrom),
			u2o(12, 6), u2(1, -24, 0, 20), 11, GOLDB, true)
		mkBtn(invBanner, "AcceptP2PBtn", pick("CHẤP NHẬN GIAO DỊCH", "ACCEPT P2P TRADE"), "gold",
			u2o(12, 30), u2(0.56, -16, 0, 26),
			function()
				fireUIAction("P2PTradeAction", {
					subAction = "Accept",
					targetUserId = p2p.PendingFromId,
					targetName = pendingFrom,
				})
			end,
			{ ts = 10, minTs = 8 }
		)
		mkBtn(invBanner, "DeclineP2PBtn", pick("TỪ CHỐI", "DECLINE"), "danger",
			u2(0.56, 4, 0, 30), u2(0.44, -16, 0, 26),
			function()
				fireUIAction("P2PTradeAction", { subAction = "Decline" })
			end,
			{ ts = 10, minTs = 8 }
		)
		yStart = 116
	end

	local plrScroll = uiCreate("ScrollingFrame", lobbyLeft, {
		Name = "NearbyPlayersScroll",
		Position = u2o(14, yStart),
		Size = u2(1, -28, 1, -(yStart + 56)),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = SAPPH,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = u2o(0, 0),
	})
	UIFactory.ListLayout(plrScroll, Enum.FillDirection.Vertical, 6)

	local candidateMap, candidates = {}, {}
	for _, nb in ipairs(type(p2p.NearbyPlayers) == "table" and p2p.NearbyPlayers or {}) do
		local uid = tonumber(nb.UserId or nb.userId)
		if uid and uid ~= (Players.LocalPlayer and Players.LocalPlayer.UserId) then
			candidateMap[uid] = true
			table.insert(candidates, {
				userId = uid,
				name = tostring(nb.Name or nb.DisplayName or ""),
				displayName = tostring(nb.DisplayName or nb.Name or "Player"),
				dist = tonumber(nb.Distance or nb.Dist),
				busy = nb.InTrade == true,
			})
		end
	end
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= Players.LocalPlayer and not candidateMap[plr.UserId] then
			local dist = nil
			local rA = Players.LocalPlayer and Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			local rB = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			if rA and rB then
				dist = math.floor((rA.Position - rB.Position).Magnitude)
			end
			table.insert(candidates, {
				userId = plr.UserId,
				name = plr.Name,
				displayName = plr.DisplayName or plr.Name,
				dist = dist,
				busy = plr:GetAttribute("InTrade") == true,
			})
		end
	end

	if #candidates == 0 then
		mkText(plrScroll, "SoloHint",
			pick("Hiện chưa có người chơi khác trong máy chủ để mời Giao Dịch P2P.\nBạn có thể chuyển sang tab [Nhà Sưu Tập NPC] để đổi Lõi Solo!",
				"No other players in this server right now.\nSwitch to [NPC Collector] to trade solo!"),
			u2o(8, 12), u2(1, -16, 0, 64), 11, TEXT2, false, TXL, true)
	else
		for idx, c in ipairs(candidates) do
			local row = mkBox(plrScroll, "Cand_" .. idx, nil, u2(1, -6, 0, 44), rgb(12, 19, 36), 8, STEEL, 1, 0.35, nil, idx)
			local distTag = c.dist and pick(string.format(" • Cách %dm", c.dist), string.format(" • %dm away", c.dist)) or ""
			mkText(row, "N", string.format("%s (@%s)%s", c.displayName, c.name, distTag), u2o(10, 0), u2(1, -162, 1, 0), 11, TEXT1, true)
			mkBtn(row, "Inv_" .. idx,
				c.busy and pick("ĐANG BẬN", "IN TRADE") or pick("MỜI GIAO DỊCH P2P", "INVITE P2P"),
				c.busy and "secondary" or "gold",
				u2(1, -148, 0.5, -14), u2o(138, 28),
				function()
					fireUIAction("P2PTradeAction", {
						subAction = "Invite",
						targetUserId = c.userId,
						targetName = c.name,
					})
					Store.ShowToast(pick("Đã gửi lời mời Giao Dịch P2P tới " .. c.displayName .. "!", "Sent P2P Trade invite to " .. c.displayName .. "!"), "success")
				end,
				{ disabled = c.busy, ts = 9, minTs = 8 }
			)
		end
	end

	mkBtn(lobbyLeft, "RefreshP2PBtn", pick("LÀM MỚI NGƯỜI CHƠI GẦN ĐÂY", "REFRESH NEARBY PLAYERS"), "primary",
		u2(0, 14, 1, -44), u2(1, -28, 0, 34),
		function()
			NPCShop.LastP2PRefreshAt = os.clock()
			fireUIAction("P2PTradeAction", { subAction = "Refresh" })
		end,
		{ ts = 10, minTs = 8 }
	)

	mountVendorBustCard(lobbyRight, {
		Position = u2o(16, 52), Size = u2o(124, 174), CardHeight = 140, ShowSubtitles = true,
		Archetype = "collector_tophat", Accent = GOLDB, Tag = pick("• BÀN P2P 4X4", "• 4X4 P2P TABLE"),
		Title = pick("GIAO DỊCH AN TOÀN", "SAFE P2P TRADE"), Location = pick("CHỐNG LỪA ĐẢO <= 40%", "<= 40% ANTI-SCAM"),
	})
	mkText(lobbyRight, "P2PRules",
		pick(
			"CƠ CHẾ GIAO DỊCH P2P 2 NGƯỜI CHƠI:\n\n• Yêu cầu Lv.700+ & đứng gần <= 28m tại Trạm Giao Thương Cyberport Cafe.\n• Mỗi người đặt tối đa 4 Lõi Aether Vĩnh Viễn hoặc Vật Phẩm.\n• Khóa Chống Lừa Đảo tự động chặn chênh lệch giá trị > 40%.\n• Cả 2 bấm [Sẵn Sàng] -> [Xác Nhận Giao Dịch] để hoán đổi nguyên tử!",
			"2-PLAYER LIVE P2P TRADING:\n\n• Requires Lv.700+ & within <= 28 studs inside Cyberport Cafe Trade Station.\n• Offer up to 4 Vault Cores or tradeable items each.\n• 40% Anti-Scam Value Guard protects both sides.\n• Both click [Ready] -> [Confirm Trade] for atomic swap!"
		),
		u2o(152, 52), u2(1, -166, 0, 184), 11, TEXT1, false, TXL, true
	)
	mkBtn(lobbyRight, "SwitchSoloCollectorBtn", pick("CHUYỂN SANG NHÀ SƯU TẬP NPC (SOLO)", "SWITCH TO SOLO NPC COLLECTOR"), "gold",
		u2(0, 16, 1, -44), u2(1, -32, 0, 34),
		function()
			st.tradeMode = "Collector"
			NPCShop.RebuildWorkspace()
		end,
		{ icon = "Crown", ts = 10, minTs = 8 }
	)
end

local function buildColosseumAndSpireTab(body, snap)
	local renown = tonumber((snap.currency and snap.currency.bounty) or (snap.fruits and snap.fruits.bounty)) or 0
	local lp = Players.LocalPlayer
	local pvpOn = lp and lp:GetAttribute("PvPEnabled") == true
	local spireFloor = (lp and tonumber(lp:GetAttribute("SkySpireFloor"))) or (tonumber(snap and snap.highestSpireFloor)) or 1

	local mainShell = PremiumPanel.Create(body, {
		name = "ArenaShell", variant = "gold",
		title = pick("NPC 11: QUẢN ĐẤU TRƯỜNG 1V1 SKY COLOSSEUM & THÁP VÔ TẬN 50 TẦNG", "NPC 11: 1V1 SKY COLOSSEUM & 50F ENDLESS SKY SPIRE"),
		position = u2o(0, 0), size = u2(1, 0, 1, 0),
	})

	mountVendorBustCard(mainShell, {
		Position = u2o(16, 54), Size = u2o(128, 224), CardHeight = 182, ShowSubtitles = true,
		Archetype = "valkyrie_crest", Accent = rgb(251, 113, 133), Tag = pick("• 3D LIVE - QUẢN ĐẤU", "• 3D LIVE - WARDEN"),
		Title = pick("DANH VỌNG HIỆN TẠI:", "CURRENT RENOWN:"), Location = fmt(renown),
	})

	local arenaCard = mkBox(mainShell, "Arena1v1", u2o(158, 54), u2(0.42, -90, 1, -138), rgb(16, 14, 28), 12, DANG, 1.5, 0.16)
	mkText(arenaCard, "AT", pick("ĐẤU TRƯỜNG LUẬN VÕ 1V1 CÔNG BẰNG", "FAIR-PLAY 1V1 SKY COLOSSEUM"), u2o(16, 12), u2(1, -32, 0, 22), 14, rgb(253, 164, 175), true)
	mkText(
		arenaCard,
		"AR",
		pick(
			"• 0 Mất Điểm Danh Vọng • Tự hồi 100% HP & Hồi chiêu\n• Đấu với Người chơi khác hoặc Kiện Tướng AI\n• Thắng thưởng: +25,000 Điểm Danh Vọng & Huy Hiệu Đấu Sĩ\n• Đạt 10,000,000 Danh Vọng mở khóa Triệu Hồi Thú Trời!",
			"• Zero Renown Loss • Auto 100% HP & Cooldown Reset\n• Duel live challengers or Champion AI\n• Victory Reward: +25,000 Renown & Gladiator Emblem\n• Reach 10,000,000 Renown to unlock Sky Beast Summon!"
		),
		u2o(16, 40), u2(1, -32, 0, 94), 12, TEXT1, false, nil, true
	)
	mkBtn(
		arenaCard,
		"TogglePvP",
		pvpOn and pick("PVP: ĐANG BẬT (BẤM BẬT KHIÊN)", "PVP: ACTIVE (CLICK FOR PEACE SHIELD)") or pick("KHIÊN HÒA BÌNH: BẬT (BẤM MỞ PVP)", "PEACE SHIELD: ON (CLICK TO ENABLE PVP)"),
		"secondary", u2(0, 16, 1, -96), u2(1, -32, 0, 36),
		function() fireLegacyUIRequest("TogglePvP", {}) end, { icon = "Shield" }
	)
	mkBtn(arenaCard, "Join1v1", pick("GHI DANH LUẬN VÕ 1V1 NGAY", "JOIN 1V1 COLOSSEUM NOW"), "danger", u2(0, 16, 1, -52), u2(1, -32, 0, 40),
		function()
			fireLegacyUIRequest("DuelAction", { subAction = "Queue1v1", mode = "Colosseum1v1" })
		end, { icon = "Sword", ts = 12 })

	local spireCard = mkBox(mainShell, "SkySpire", u2(0.42, 80, 0, 54), u2(0.58, -96, 1, -138), rgb(11, 20, 38), 12, SAPPH, 1.5, 0.16)
	mkText(spireCard, "ST", pick("THÁP VÔ TẬN ENDLESS SKY SPIRE (50F)", "ENDLESS SKY SPIRE GAUNTLET (50F)"), u2o(16, 12), u2(1, -32, 0, 22), 14, rgb(92, 225, 255), true)
	mkText(
		spireCard,
		"SI",
		pick(
			string.format("• Kỷ lục hiện tại của bạn: Tầng %d / 50\n• Mỗi 5 tầng chạm trán Boss Cường Hóa & Rương Vàng\n• Quà Tầng 50: Danh Hiệu [Bá Chủ Tháp Trời] + Lõi Veyr + 1K Shards", spireFloor),
			string.format("• Your Highest Record: Floor %d / 50\n• Empowered Boss & Golden Chest every 5 floors\n• Floor 50 Clear: [Sky Spire Sovereign] Title + Veyr Relic + 1K Shards", spireFloor)
		),
		u2o(16, 38), u2(1, -32, 0, 62), 12, TEXT1, false, nil, true
	)

	local msStrip = mkBox(spireCard, "Milestones", u2o(16, 102), u2(1, -32, 0, 68))
	UIFactory.ListLayout(msStrip, Enum.FillDirection.Horizontal, 6)
	for mIdx, ms in ipairs({
		{ "Rare", pick("TẦNG 10", "FLOOR 10"), pick("Cuộn Cổ Ngữ", "Enchant Scroll"), "Scroll" },
		{ "Epic", pick("TẦNG 25", "FLOOR 25"), pick("Nhẫn Aureon", "Aureon Ring"), "CoreShards" },
		{ "Legendary", pick("TẦNG 40", "FLOOR 40"), pick("Mũ Hư Quang", "Phantom Helm"), "Shield" },
		{ "Mythic", pick("TẦNG 50", "FLOOR 50"), pick("Thánh Vật Veyr", "Veyr Relic"), "Crown" },
	}) do
		makeGlossyRarityTile(msStrip, ms[1], ms[2], ms[3], ms[4], u2(0.25, -5, 1, 0), { LayoutOrder = mIdx, IconSize = 22, DiscSize = 32 })
	end

	mkBtn(
		spireCard,
		"EnterSpire",
		pick(string.format("LEO TIẾP TẦNG %d (1-6 NGƯỜI)", spireFloor), string.format("ENTER FLOOR %d (1-6 PLAYERS)", spireFloor)),
		"primary", u2(0, 16, 1, -52), u2(1, -32, 0, 40),
		function()
			fireLegacyUIRequest("EnterSkySpire", { floor = spireFloor })
			Store.ShowToast(pick("Đang tiến vào Tháp Vô Tận Sky Spire!", "Entering 50F Endless Sky Spire!"), "info")
		end, { icon = "Trophy", ts = 12 }
	)

	local wb = mkBox(mainShell, "WorldBanner", u2(0, 16, 1, -68), u2(1, -32, 0, 52), rgb(48, 20, 88), 10, GOLDB, 1.5, 0.14)
	UIFactory.Gradient(wb, rgb(68, 28, 120), rgb(34, 14, 66), 90)
	UIFactory.Icon(wb, "Bolt", u2o(14, 14), 24, GOLDB)
	mkText(
		wb,
		"WT",
		pick(
			"[THÔNG BÁO THẾ GIỚI] ĐẢO HƯ QUANG & THỦY XÀ VỰC THẲM XUẤT HIỆN TẠI VÙNG BIỂN HƯ KHÔNG!",
			"[WORLD EVENT] PHANTOM ISLE & ABYSSAL LEVIATHAN EMERGE IN THE SHADOW SEA!"
		),
		u2o(46, 0), u2(1, -58, 1, 0), 12, GOLDB, true
	)
end

local function isPassOwned(snap, passKey)
	local key = tostring(passKey or "")
	if snap and type(snap.ownedGamePasses) == "table" and snap.ownedGamePasses[key] == true then
		return true
	end
	local lp = Players.LocalPlayer
	if lp and lp:GetAttribute("OwnedPass_" .. key) == true then
		return true
	end
	return false
end

local function buildRobuxPassesTab(body, snap)
	local isEn = I18n.GetLanguage() == "en"
	local cam = workspace.CurrentCamera
	local vpW = cam and cam.ViewportSize.X or 1366
	local cols = (vpW < 520) and 1 or ((vpW < 980) and 2 or 5)
	local lp = Players.LocalPlayer
	local isDevGate = RunService:IsStudio() or (lp ~= nil and lp:GetAttribute("DevGateEnabled") == true)
	local paidRestricted = (snap and snap.PaidRandomRestricted == true)
		or (lp ~= nil and lp:GetAttribute("PaidRandomRestricted") == true)
	local comingSoonToast = pick(
		MonetizationConfig.ComingSoonToastVi or "Sắp mở bán trên Roblox Store",
		MonetizationConfig.ComingSoonToastEn or "Coming soon on Roblox Store"
	)
	local policyToast = pick(
		MonetizationConfig.PolicyRestrictedToastVi or "Gói Vàng tạm khóa tại khu vực của bạn theo chính sách vật phẩm ngẫu nhiên trả phí của Roblox.",
		MonetizationConfig.PolicyRestrictedToastEn or "Gold Pouches are unavailable in your region under Roblox paid random item regulations."
	)

	local shell = PremiumPanel.Create(body, {
		name = "RobuxPassesShell",
		variant = "gold",
		title = pick("ĐẶC QUYỀN ROBUX & TIỆN ÍCH CÔNG BẰNG (GAME PASSES & R$)", "ROBUX UTILITY & COSMETIC PASSES STORE"),
		position = u2o(0, 0),
		size = u2s(1, 1),
	})
	UIFactory.Stroke(shell, rgb(52, 211, 153), 1.8, 0.12)

	-- Fair-Play Commitment Banner (PUBLISH_PLAN Section 3.2 D2 & P2-01)
	local fairBanner = mkBox(shell, "FairPlayBanner", u2o(14, 48), u2(1, -28, 0, 40), rgb(9, 44, 34), 9, rgb(52, 211, 153), 1.5, 0.10, 5)
	UIFactory.Gradient(fairBanner, rgb(12, 62, 46), rgb(10, 28, 38), 90)
	UIFactory.Icon(fairBanner, "RobuxGem", u2o(12, 8), 24, rgb(110, 242, 190)).ZIndex = 6
	mkText(
		fairBanner,
		"FairPlayText",
		pick(
			"100% Công Bằng: Chỉ bán tiện ích & trang trí — Không bán Lõi Thần Thoại hay quay Gacha bằng Robux!",
			"100% Fair Play: Utility & Cosmetics only — No Mythic Cores or Robux Gacha!"
		),
		u2o(44, 0),
		u2(1, -184, 1, 0),
		12,
		rgb(188, 252, 224),
		true,
		TXL,
		true,
		6
	)
	mkBtn(
		fairBanner,
		"SyncPassesBtn",
		pick("LÀM MỚI PASS", "SYNC PASSES"),
		"secondary",
		u2(1, -134, 0.5, -14),
		u2o(124, 28),
		function()
			fireLegacyUIRequest("RefreshGamePasses", {})
		end,
		{ icon = "Sparkle", ts = 10, minTs = 8 }
	)

	local scroll = uiCreate("ScrollingFrame", shell, {
		Name = "RobuxCatalogScroll",
		Position = u2o(14, 96),
		Size = u2(1, -28, 1, -108),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = rgb(52, 211, 153),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = u2o(0, 0),
		ZIndex = 4,
	})
	UIFactory.ListLayout(scroll, Enum.FillDirection.Vertical, 10, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top)
	UIFactory.Padding(scroll, 2, 6, 8, 2)

	if paidRestricted then
		local polBanner = mkBox(scroll, "RegionalPolicyBanner", nil, u2(1, 0, 0, 34), rgb(44, 26, 18), 7, GOLDB, 1.2, 0.2, 5, 0)
		UIFactory.Icon(polBanner, "Shield", u2o(10, 8), 18, GOLDB).ZIndex = 6
		mkText(
			polBanner,
			"PolicyNote",
			policyToast,
			u2o(34, 2),
			u2(1, -44, 1, -4),
			10,
			GOLDB,
			true,
			TXL,
			true,
			6
		)
	end

	local passes = MonetizationConfig.GamePasses or {}
	local ownedTotal = 0
	for _, pass in ipairs(passes) do
		if isPassOwned(snap, pass.Key) then
			ownedTotal += 1
		end
	end

	-- TOP SECTION: 5 Permanent Game Passes
	local gpHeader = mkBox(scroll, "GamePassesHeader", nil, u2(1, 0, 0, 28), rgb(12, 28, 36), 7, GOLDB, 1.2, 0.28, 5, 1)
	UIFactory.Icon(gpHeader, "Crown", u2o(10, 5), 18, GOLDB).ZIndex = 6
	mkText(
		gpHeader,
		"Title",
		pick("5 ĐẶC QUYỀN VĨNH VIỄN (GAME PASSES)", "5 PERMANENT GAME PASSES"),
		u2o(34, 0),
		u2(1, -170, 1, 0),
		12,
		GOLDB,
		true,
		TXL,
		false,
		6
	)
	mkText(
		gpHeader,
		"OwnedCounter",
		string.format("%d / %d %s", ownedTotal, #passes, pick("ĐÃ SỞ HỮU", "OWNED")),
		u2(1, -158, 0, 0),
		u2o(148, 28),
		11,
		rgb(110, 242, 190),
		true,
		Enum.TextXAlignment.Right,
		false,
		6
	)

	local gpRows = math.max(1, math.ceil(#passes / cols))
	local gpCardH = 192
	local gpGridWrap = mkBox(scroll, "GamePassesGrid", nil, u2(1, 0, 0, gpRows * gpCardH + (gpRows - 1) * 8), nil, nil, nil, nil, nil, 5, 2)
	local gpGrid = uiCreate("UIGridLayout", gpGridWrap, {
		CellSize = u2(1 / cols, -7, 0, gpCardH),
		CellPadding = u2o(8, 8),
		FillDirectionMaxCells = cols,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	gpGrid.HorizontalAlignment = Enum.HorizontalAlignment.Left

	for idx, pass in ipairs(passes) do
		local owned = isPassOwned(snap, pass.Key)
		local configured = MonetizationConfig.IsConfigured == nil or MonetizationConfig.IsConfigured(pass)
		local comingSoon = (not owned) and (not configured) and (not isDevGate)
		local price = tonumber(pass.PriceRobux) or 0
		local strokeCol = owned and rgb(52, 211, 153) or GOLDB
		local card = mkBox(gpGridWrap, "Pass_" .. pass.Key, nil, u2o(200, gpCardH), rgb(11, 22, 34), 10, strokeCol, owned and 1.8 or 1.4, 0.12, 5, idx)
		UIFactory.Gradient(card, owned and rgb(12, 42, 34) or rgb(16, 28, 46), rgb(9, 15, 28), 90)

		makeGlossyRarityTile(
			card,
			pass.Rarity or "Legendary",
			owned and pick("VĨNH VIỄN", "OWNED") or ("R$ " .. tostring(price)),
			"PASS",
			pass.Icon or "Crown",
			u2o(62, 64),
			{ Position = u2o(10, 10), IconSize = 26, DiscSize = 36, Selected = owned, ZIndex = 6 }
		)

		local statusBadge = mkBox(
			card,
			"StatusBadge",
			u2(0, 80, 0, 10),
			u2(1, -90, 0, 18),
			owned and rgb(16, 122, 82) or rgb(46, 36, 14),
			5,
			owned and rgb(110, 242, 190) or GOLDB,
			1,
			0.25,
			6
		)
		mkText(
			statusBadge,
			"BadgeText",
			owned and pick("ĐÃ SỞ HỮU", "OWNED / ACTIVE")
				or (comingSoon and pick(string.format("SẮP MỞ BÁN • R$ %d", price), string.format("COMING SOON • R$ %d", price))
				or string.format("GAME PASS • R$ %d", price)),
			u2o(6, 0),
			u2(1, -12, 1, 0),
			9,
			owned and rgb(208, 255, 232) or GOLDB,
			true,
			TXL,
			false,
			7
		)

		mkText(
			card,
			"PassTitle",
			isEn and pass.NameEn or pass.NameVi,
			u2o(80, 31),
			u2(1, -90, 0, 38),
			12,
			TEXT1,
			true,
			TXL,
			true,
			6
		)
		mkText(
			card,
			"PassDesc",
			isEn and pass.DescEn or pass.DescVi,
			u2o(10, 80),
			u2(1, -20, 0, 58),
			10,
			TEXT2,
			false,
			TXL,
			true,
			6
		)

		local btnLabel = owned
			and pick("ĐÃ SỞ HỮU", "OWNED")
			or (comingSoon and string.format("%s (R$ %d)", pick("SẮP MỞ BÁN", "COMING SOON"), price)
			or string.format("%s (R$ %d)", pick("MUA", "BUY"), price))
		mkBtn(
			card,
			"BuyPass_" .. pass.Key,
			btnLabel,
			(owned or comingSoon) and "secondary" or "emerald",
			u2(0, 10, 1, -42),
			u2(1, -20, 0, 32),
			function()
				if owned then
					return
				end
				if comingSoon then
					Store.ShowToast(comingSoonToast, "info")
					return
				end
				fireLegacyUIRequest("PromptGamePass", { passKey = pass.Key })
			end,
			{ icon = owned and "Crown" or "RobuxGem", disabled = owned, ts = 11, minTs = 8 }
		)
	end

	-- BOTTOM SECTION: 5 Consumable Developer Products
	local prods = MonetizationConfig.DevProducts or {}
	local dpHeader = mkBox(scroll, "DevProductsHeader", nil, u2(1, 0, 0, 28), rgb(12, 30, 28), 7, rgb(52, 211, 153), 1.2, 0.28, 5, 3)
	UIFactory.Icon(dpHeader, "RobuxGem", u2o(10, 5), 18, rgb(110, 242, 190)).ZIndex = 6
	mkText(
		dpHeader,
		"Title",
		pick("5 GÓI TIỆN ÍCH TIÊU HAO (DEVELOPER PRODUCTS)", "5 CONSUMABLE DEVELOPER PRODUCTS"),
		u2o(34, 0),
		u2(1, -44, 1, 0),
		12,
		rgb(148, 248, 198),
		true,
		TXL,
		false,
		6
	)

	local dpRows = math.max(1, math.ceil(#prods / cols))
	local dpCardH = 180
	local dpGridWrap = mkBox(scroll, "DevProductsGrid", nil, u2(1, 0, 0, dpRows * dpCardH + (dpRows - 1) * 8), nil, nil, nil, nil, nil, 5, 4)
	local dpGrid = uiCreate("UIGridLayout", dpGridWrap, {
		CellSize = u2(1 / cols, -7, 0, dpCardH),
		CellPadding = u2o(8, 8),
		FillDirectionMaxCells = cols,
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	dpGrid.HorizontalAlignment = Enum.HorizontalAlignment.Left

	for idx, prod in ipairs(prods) do
		local price = tonumber(prod.PriceRobux) or 0
		local needsPolicy = MonetizationConfig.RequiresPaidRandomPolicyCheck ~= nil and MonetizationConfig.RequiresPaidRandomPolicyCheck(prod)
		local policyBlocked = needsPolicy and paidRestricted
		local configured = MonetizationConfig.IsConfigured == nil or MonetizationConfig.IsConfigured(prod)
		local comingSoon = (not policyBlocked) and (not configured) and (not isDevGate)
		local strokeCol = policyBlocked and GOLDB or rgb(52, 211, 153)
		local card = mkBox(dpGridWrap, "Prod_" .. prod.Key, nil, u2o(200, dpCardH), rgb(11, 20, 32), 10, strokeCol, 1.3, 0.22, 5, idx)
		UIFactory.Gradient(card, policyBlocked and rgb(36, 24, 18) or rgb(14, 32, 38), rgb(9, 15, 26), 90)

		makeGlossyRarityTile(
			card,
			prod.Rarity or "Epic",
			"R$ " .. tostring(price),
			pick("TIÊU HAO", "PACK"),
			prod.Icon or "Gold",
			u2o(58, 60),
			{ Position = u2o(10, 10), IconSize = 24, DiscSize = 34, ZIndex = 6 }
		)

		mkText(
			card,
			"PriceTag",
			policyBlocked and pick("CHÍNH SÁCH VÙNG", "REGIONAL POLICY")
				or (comingSoon and string.format("R$ %d • %s", price, pick("SẮP MỞ BÁN", "COMING SOON"))
				or string.format("R$ %d • %s", price, pick("NHẬN NGAY", "INSTANT"))),
			u2o(76, 10),
			u2(1, -86, 0, 16),
			10,
			policyBlocked and GOLDB or rgb(110, 242, 190),
			true,
			TXL,
			false,
			6
		)
		mkText(
			card,
			"ProdTitle",
			isEn and prod.NameEn or prod.NameVi,
			u2o(76, 28),
			u2(1, -86, 0, 38),
			12,
			TEXT1,
			true,
			TXL,
			true,
			6
		)
		mkText(
			card,
			"ProdDesc",
			isEn and (prod.DescEn or prod.NameEn) or (prod.DescVi or prod.NameVi),
			u2o(10, 76),
			u2(1, -20, 0, 52),
			10,
			TEXT2,
			false,
			TXL,
			true,
			6
		)

		local prodBtnLabel = policyBlocked and pick("HẠN CHẾ VÙNG", "REGION LOCKED")
			or (comingSoon and string.format("%s (R$ %d)", pick("SẮP MỞ BÁN", "COMING SOON"), price)
			or string.format("%s (R$ %d)", pick("MUA", "BUY"), price))
		mkBtn(
			card,
			"BuyProd_" .. prod.Key,
			prodBtnLabel,
			(policyBlocked or comingSoon) and "secondary" or "emerald",
			u2(0, 10, 1, -42),
			u2(1, -20, 0, 32),
			function()
				if policyBlocked then
					Store.ShowToast(policyToast, "warning")
					return
				end
				if comingSoon then
					Store.ShowToast(comingSoonToast, "info")
					return
				end
				fireLegacyUIRequest("PromptDevProduct", { productKey = prod.Key })
			end,
			{ icon = policyBlocked and "Shield" or "RobuxGem", ts = 11, minTs = 8 }
		)
	end
end

local function clearOrbitsAndBusts()
	for _, conn in ipairs(NPCShop.BustConns) do if conn then conn:Disconnect() end end
	table.clear(NPCShop.BustConns)
	for _, orb in ipairs(NPCShop.Orbits) do
		if orb and type(orb.Destroy) == "function" then pcall(function() orb:Destroy() end) end
	end
	table.clear(NPCShop.Orbits)
end

local TAB_BUILDERS = {
	MirageDealer = buildMirageTab,
	MartialDojo = buildMartialDojoTab,
	EnchanterAndChronos = buildEnchanterAndChronosTab,
	Shipwright = buildShipwrightTab,
	DrVegaAndTempleV4 = buildDrVegaAndTempleV4Tab,
	TradingTable = buildTradingTableTab,
	ColosseumAndSpire = buildColosseumAndSpireTab,
	RobuxPasses = buildRobuxPassesTab,
}

local VENDOR_HEADERS = {
	MirageDealer = { "KỆ LÕI HƯ QUANG • LÀM MỚI MỖI 1 GIỜ", "PHANTOM CORE STOCK • 1H ROTATION", "THƯƠNG NHÂN HƯ QUANG", "PHANTOM DEALER" },
	SwordDealer = { "CỬA HÀNG DANH KIẾM 3D", "3D MASTER SWORD DEALER", "KIẾM SƯ TRẤN ĐẢO", "SWORD DEALER" },
	GunDealer = { "XƯỞNG PHÁP KHÍ & 8 BỘ THẦN GIÁP 3D", "3D ARCANE GUNS & 8 ARMOR SETS", "XẠ THỦ & GIÁP SƯ", "GUN & ARMOR SMITH" },
	MartialDojo = { "VÕ ĐƯỜNG CỔ TỰ • 7 HỆ QUYỀN PHÁP", "ANCIENT DOJO • 7 MARTIAL ARTS", "TÔNG SƯ VÕ ĐƯỜNG", "MARTIAL GRANDMASTER" },
	EnchanterAndChronos = { "PHÙ PHÉP CỔ NGỮ & CHỢ ĐEN HƯ KHÔNG", "ARCANE ENCHANTER & VOID BLACK MARKET", "PHÁP SƯ & CHRONOS", "ENCHANTER & CHRONOS" },
	Shipwright = { "XƯỞNG ĐÓNG & TRIỆU HỒI CHIẾN HẠM BAY 3D", "3D SKY-SHIPWRIGHT DOCKYARD", "XƯỞNG CHIẾN HẠM", "SKY SHIPWRIGHT" },
	DrVegaAndTempleV4 = { "VIỆN HUYẾT THỐNG & ĐỀN THĂNG HOA TỘC V4", "6-LINEAGE LAB & V4 ASCENSION TEMPLE", "TIẾN SĨ DR. VEGA", "DR. VEGA & TEMPLE" },
	TradingTable = { "BÀN GIAO DỊCH LÕI AETHER 4X4", "4X4 AETHER CORE TRADING TABLE", "BÀN GIAO DỊCH 4X4", "TRADING TABLE" },
	ColosseumAndSpire = { "ĐẤU TRƯỜNG 1V1 & THÁP BẦU TRỜI 50 TẦNG", "1V1 COLOSSEUM & 50F SKY SPIRE", "QUẢN ĐẤU TRƯỜNG", "ARENA WARDEN" },
	RobuxPasses = { "CỬA HÀNG ĐẶC QUYỀN ROBUX & VẬT PHẨM", "ROBUX GAMEPASSES & BUNDLES STORE", "CỬA HÀNG ĐẶC QUYỀN", "PREMIUM STORE" },
}

local function resolveVendorHeader(mode)
	local spec = VENDOR_HEADERS[tostring(mode or "")] or VENDOR_HEADERS.SwordDealer
	local isEn = I18n.GetLanguage() == "en"
	return (isEn and spec[2] or spec[1]), (isEn and spec[4] or spec[3])
end

function NPCShop.RebuildWorkspace()
	local refs = NPCShop.Refs
	local body = refs.Body
	if not body or not body.Parent then return end
	clearOrbitsAndBusts()
	refs.MirageTimerLabel, refs.VoidTimerLabel = nil, nil
	for _, ch in ipairs(body:GetChildren()) do ch:Destroy() end

	local snap = Store.GetSnapshot()
	local mode = Store.GetView().activeVendorMode or "SwordDealer"
	if refs.HeaderRefs and refs.HeaderRefs.TitleLabel and refs.HeaderRefs.TitleLabel.Parent then
		local nextTitle = resolveVendorHeader(mode)
		refs.HeaderRefs.TitleLabel.Text = nextTitle
	end

	if TAB_BUILDERS[mode] then TAB_BUILDERS[mode](body, snap)
	else buildArsenalVendorTab(body, snap, mode == "GunDealer" and "GunDealer" or "SwordDealer") end
end

function NPCShop.Build(parent, _responsiveState)
	NPCShop.Cleanup()
	local snap = Store.GetSnapshot()
	if snap and snap.p2pTrade and snap.p2pTrade.Active == true then
		Store.SetView({ activeVendorMode = "TradingTable" })
	end
	local activeMode = Store.GetView().activeVendorMode or "SwordDealer"
	local root = mkBox(parent, "NPCShopScreen", nil, u2s(1, 1), nil, nil, nil, nil, nil, 2)
	local headerTitle, badgeTxt = resolveVendorHeader(activeMode)

	local _, headerRefs = UIFactory.BuildScreenHeader(root, {
		ActiveScreen = UIState.Screens.NPCShop,
		ContextualNPCStation = true,
		StationBadgeText = badgeTxt,
		Title = headerTitle,
		Snapshot = snap,
		OnNavigate = function(targetId) ScreenRouter.Navigate(targetId) end,
		OnClose = function() ScreenRouter.CloseAllToHUD() end,
	})

	-- Single-Vendor Contextual Workspace (hides multi-island 10-NPC switcher bar so players only see the active NPC / Robux store)
	local body = mkBox(root, "VendorWorkspace", u2o(16, 72), u2(1, -32, 1, -86))
	NPCShop.Refs = { Root = root, HeaderRefs = headerRefs, Body = body }
	NPCShop.RebuildWorkspace()

	local lp = Players.LocalPlayer
	if lp then
		for _, pass in ipairs(MonetizationConfig.GamePasses or {}) do
			local conn = lp:GetAttributeChangedSignal("OwnedPass_" .. pass.Key):Connect(function()
				NPCShop.LastSnapSig = nil
				if NPCShop.Refs.Root and NPCShop.Refs.Root.Parent then
					NPCShop.RebuildWorkspace()
				end
			end)
			table.insert(NPCShop.PassConns, conn)
		end
	end

	NPCShop.TickerAlive = true
	task.spawn(function()
		while NPCShop.TickerAlive and root.Parent do
			task.wait(1.0)
			if NPCShop.Refs.MirageTimerLabel and NPCShop.Refs.MirageTimerLabel.Parent then
				NPCShop.Refs.MirageTimerLabel.Text = pick("LÀM MỚI: ", "REFRESH: ") .. formatClockCountdown(3600 - (os.time() % 3600))
			end
			if NPCShop.Refs.VoidTimerLabel and NPCShop.Refs.VoidTimerLabel.Parent then
				NPCShop.Refs.VoidTimerLabel.Text = pick("RỜI ĐẢO SAU: ", "DEPARTS IN: ") .. formatClockCountdown(600 - (os.time() % 600))
			end
		end
	end)
	return root
end

-- Chu ky cac truong snapshot ma Shop hien thi. Server Sync ~0.3s/lan; truoc day moi lan deu xoa va dung lai
-- toan bo Shop (nut bi thay giua luc nhan chuot -> bam hut, Toast khong hien). Bo qua cac truong dong ho dem nguoc.
local function shopSignature(snap)
	local function dropTimers(t)
		if type(t) ~= "table" then return t end
		local o = {}
		for k, v in pairs(t) do
			local ks = tostring(k)
			if not (ks:find("Time") or ks:find("time") or ks:find("Seconds") or ks:find("Until") or ks:find("Remaining") or ks:find("Clock") or ks:find("Countdown")) then
				o[ks] = v
			end
		end
		return o
	end
	local lp = Players.LocalPlayer
	local attrPasses = {}
	local paidRestricted = snap and snap.PaidRandomRestricted == true or false
	if lp then
		for _, pass in ipairs(MonetizationConfig.GamePasses or {}) do
			if lp:GetAttribute("OwnedPass_" .. pass.Key) == true then
				attrPasses[pass.Key] = true
			end
		end
		if lp:GetAttribute("PaidRandomRestricted") == true then
			paidRestricted = true
		end
	end
	local ok, sig = pcall(function()
		return HttpService:JSONEncode({
			I18n.GetLanguage(),
			snap.player,
			snap.currency or snap.currencies,
			snap.inventory,
			snap.equipped,
			dropTimers(snap.fruits),
			snap.unlockedShips,
			snap.unlockedStyles,
			snap.p2pTrade,
			snap.highestSpireFloor,
			snap.ownedGamePasses,
			attrPasses,
			paidRestricted,
			snap.mirageStock and snap.mirageStock.HourSeed or nil,
			NPCShop.LiveMirageStock and NPCShop.LiveMirageStock.HourSeed or nil,
			snap.isDemoMode == true,
		})
	end)
	return ok and sig or nil
end

function NPCShop.Update(snap)
	snap = snap or Store.GetSnapshot()
	if NPCShop.Refs.HeaderRefs and NPCShop.Refs.HeaderRefs.UpdateCurrencies then
		NPCShop.Refs.HeaderRefs.UpdateCurrencies(snap)
	end
	if snap and snap.p2pTrade and snap.p2pTrade.Active == true and Store.GetView().activeVendorMode ~= "TradingTable" then
		Store.SetView({ activeVendorMode = "TradingTable" })
		NPCShop.LastSnapSig = nil
	end
	local sig = shopSignature(snap)
	if sig ~= nil and sig == NPCShop.LastSnapSig then return end
	NPCShop.LastSnapSig = sig
	if NPCShop.Refs.Root and NPCShop.Refs.Root.Parent then NPCShop.RebuildWorkspace() end
end

function NPCShop.Cleanup()
	NPCShop.LastSnapSig = nil
	NPCShop.TickerAlive = false
	for _, conn in ipairs(NPCShop.PassConns) do
		if conn then conn:Disconnect() end
	end
	table.clear(NPCShop.PassConns)
	clearOrbitsAndBusts()
	NPCShop.Refs = {}
end

return NPCShop
