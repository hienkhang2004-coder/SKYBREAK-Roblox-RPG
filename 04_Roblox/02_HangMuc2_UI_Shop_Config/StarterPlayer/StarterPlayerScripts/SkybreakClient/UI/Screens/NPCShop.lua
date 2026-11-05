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
local UIState = require(SkyShared:WaitForChild("Types"):WaitForChild("UIState"))
local VC = AEC.VendorCatalogs

local CoreShared = ReplicatedStorage:FindFirstChild("Shared")
local CoreConfig = CoreShared and CoreShared:FindFirstChild("Config") and require(CoreShared.Config) or {}

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Store = require(script.Parent.Parent:WaitForChild("Store"))
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

local NPCShop = { Refs = {}, Orbits = {}, BustConns = {}, TickerAlive = false }

local VENDOR_TABS = {
	{ "MirageDealer", "Fruit", "TRÁI 2H • MIRAGE", "2H MIRAGE STOCK" },
	{ "SwordDealer", "Sword", "KIẾM SƯ 3D", "3D SWORD DEALER" },
	{ "GunDealer", "Gun", "SÚNG & THẦN GIÁP", "GUNS & 3D ARMOR" },
	{ "MartialDojo", "Fist", "7 VÕ ĐƯỜNG", "7 MARTIAL DOJOS" },
	{ "EnchanterAndChronos", "CoreShards", "PHÙ PHÉP & CHỢ ĐEN", "ENCHANT & VOID" },
	{ "Shipwright", "Ship", "XƯỞNG TÀU 3D", "3D SHIPWRIGHT" },
	{ "DrVegaAndTempleV4", "Wing", "TỘC & ĐỀN V4", "RACE & V4 ALTAR" },
	{ "TradingTable", "Trade", "GIAO DỊCH 4X4", "4X4 FRUIT TRADE" },
	{ "ColosseumAndSpire", "Trophy", "ĐẤU TRƯỜNG & 50F", "ARENA & 50F SPIRE" },
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
	local ra = sr and sr:FindFirstChild("RequestUIAction")
	if ra and ra:IsA("RemoteEvent") then ra:FireServer(cmd, payload); return end
	local rem = ReplicatedStorage:FindFirstChild("Remotes")
	local ur = rem and rem:FindFirstChild("UIRequest")
	if ur and ur:IsA("RemoteEvent") then ur:FireServer(cmd, payload) end
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
	mkText(vpFrame, "MCap", "MÔ HÌNH 3D: " .. string.upper(tostring(sel and sel.st or sel and sel.t or "ASSET")), u2(0, 6, 1, -20), u2(1, -12, 0, 16), 9, GOLDB, true, TXC, false, 6)

	local rightBox = mkBox(heroCard, "HeroRight", u2o(346, 12), u2(1, -360, 0, 182), nil, nil, nil, nil, nil, 4)
	mkText(rightBox, "IT", string.upper(tostring(sel and sel.t or "")), u2o(0, 0), u2(1, 0, 0, 22), 16, selPal[3], true)
	mkText(rightBox, "IM", sel and sel.hsub or "", u2o(0, 21), u2(1, 0, 0, 16), 11, selPal[1]:Lerp(c3w, 0.25), true)

	for bIdx = 1, 2 do
		local bInfo = sel and sel.sb and sel.sb[bIdx]
		local sBox = mkBox(rightBox, "SB_" .. bIdx, u2o(0, 41 + (bIdx - 1) * 47), u2(1, 0, 0, 43), rgb(11, 22, 44), 8, SAPPH, 1.1, 0.35)
		sBox.BackgroundTransparency = 0.08
		mkText(sBox, "ST", bInfo and bInfo[1] or "[Z] Tuyệt Kỹ Vũ Khí 3D", u2o(10, 4), u2(1, -20, 0, 17), 11, rgb(92, 225, 255), true)
		mkText(sBox, "SD", bInfo and bInfo[2] or "", u2o(10, 21), u2(1, -20, 0, 18), 10, TEXT2, false)
	end

	if sel then
		mkBtn(rightBox, "HeroCTA", sel.hbtn or sel.cbtn or "MUA & TRANG BỊ", sel.hvar or "gold", u2o(0, 138), u2(1, 0, 0, 42),
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
		mkBtn(mCard, "CTA_" .. tostring(item.id), item.cbtn or "MUA NGAY", item.cvar or "gold", u2o(102, 56), u2(1, -112, 0, 36),
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

local MIRAGE_FRUITS = {
	{ "GaleCore", "Trái Phong Vũ (Gale)", "Gale Core Fruit", "Common", 35000, "Logia Gió • Miễn ST thường", "[Z] Phong Đao Trảm (1.9x ATK)", "[V] Cuồng Phong Lốc Xoáy" },
	{ "SolarFlameCore", "Trái Thái Dương Hỏa", "Solar Flame Core", "Rare", 450000, "Logia Lửa • Đại Viêm Đế", "[Z] Hỏa Quyền Hiken (2.2x ATK)", "[V] Đại Viêm Đế Mặt Trời" },
	{ "CelestialLightCore", "Trái Thánh Quang (Light)", "Celestial Light Core", "Epic", 1150000, "Logia Ánh Sáng • Farm số 1", "[Z] Mưa Giáo Ánh Sáng (2.4x ATK)", "[F] Phi Hành Tốc Độ Ánh Sáng" },
	{ "ThunderRumbleCore", "Trái Lôi Vũ (Rumble)", "Thunder Rumble Core", "Legendary", 2100000, "Logia Sấm Sét • Lôi Cầu Raigo", "[Z] Lôi Long Chấn Động (2.5x ATK)", "[V] Quả Cầu Sấm Sét Raigo" },
	{ "DimensionalPortalCore", "Trái Không Gian (Portal)", "Dimensional Portal Core", "Legendary", 2450000, "Paramecia • Cổng Dịch Chuyển 40m", "[C] Cổng Thế Giới Dịch Chuyển", "[V] Lãnh Địa Chiều Không Gian" },
	{ "SolarTitanCore", "Trái Kim Thân Thái Dương", "Solar Titan Buddha", "Mythic", 4200000, "Hóa Phật Khổng Lồ 3D (+58% Giáp)", "[Z] Hóa Kim Thân 3D (Tầm đánh x2.2)", "[V] Thiên Thủ Phán Quyết Hoàng Kim" },
	{ "AetherflowCore", "Trái Linh Thể Aether", "Aetherflow Core", "Mythic", 4600000, "Paramecia • Tơ Linh Mạch Sắc Bén", "[Z] Lồng Tơ Thánh Vương", "[V] Thập Lục Thánh Thương Aether" },
	{ "AbyssalSovereignCore", "Trái Hắc Long Đế Vương", "Abyssal Void Dragon", "Mythic", 8500000, "Hóa Rồng 3D Bay Cửu Thiên", "[Z] Long Tức Hư Không (2.7x ATK)", "[V] Hóa Thái Cổ Long Hoàng 3D" },
}

local function buildMirageTab(body, snap)
	local st = shopSt()
	st.mirageSub = st.mirageSub or "Regular"
	local seed = math.floor(os.time() / 7200)
	local items, selectedItem, selId = {}, nil, st.selectedMirageFruit or "SolarTitanCore"
	local isEn = I18n.GetLanguage() == "en"

	for idx, f in ipairs(MIRAGE_FRUITS) do
		local fid, nVi, nEn, rar, defP, subVi, skZ, skX = f[1], f[2], f[3], f[4], f[5], f[6], f[7], f[8]
		local fCfg = (CoreConfig.AetherFruits and CoreConfig.AetherFruits[fid]) or {}
		local price = tonumber(fCfg.Price) or defP
		local inStock = (st.mirageSub == "MirageVIP") or (idx <= 3) or (((idx + seed) % 2) == 0)
		local isEq = (snap.fruits and snap.fruits.equippedFruit == fid)
		local pTxt = fmt(price) .. " GOLD"
		local entry = {
			id = fid, t = isEn and nEn or nVi, st = fid, r = rar, top = "TRÁI 3D", bot = string.upper(rar) .. " V2", ic = "Fruit", a3d = "Fruit_" .. fid,
			hsub = string.upper(rar) .. " • 5 CHIÊU [Z][X][C][V][F] • " .. pTxt,
			csub = inStock and ((isEq and "• ĐANG TRANG BỊ TRÊN SLOT [2]") or ("• ĐANG CÒN HÀNG • " .. subVi)) or "• TẠM HẾT HÀNG (ĐỢI LÀM MỚI 2H)",
			scol = inStock and SUCC or DANG,
			sb = { { skZ, subVi .. " • Sẵn sàng thức tỉnh V2 tại Raid [P]." }, { skX, "Mua trực tiếp bằng Gold tại Thương Nhân Mirage không cần may rủi Gacha." } },
			cbtn = isEq and pick("ĐANG TRANG BỊ", "EQUIPPED") or (inStock and ("MUA & TRANG BỊ • " .. pTxt) or ("TẠM HẾT HÀNG (" .. pTxt .. ")")),
			cvar = isEq and "primary" or (inStock and "gold" or "secondary"),
			hbtn = "MUA & TRANG BỊ TRÁI 3D • " .. pTxt, hvar = inStock and "gold" or "secondary", dis = not inStock,
			sel = selFn(st, "selectedMirageFruit", fid),
			act = function()
				fireLegacyUIRequest("BuyMirageFruit", { fruitId = fid })
				Store.ShowToast(pick("Đang mua Trái 3D từ Thương Nhân Mirage: ", "Buying Mirage 3D Fruit: ") .. nVi, "success")
			end,
		}
		table.insert(items, entry)
		if fid == selId then selectedItem = entry end
	end

	renderHeroAndTwoColCatalog(body, {
		BustArchetype = "mage_hood", BustAccent = GOLDB, BustTag = "• 3D LIVE - MIRAGE",
		BustTitle = "THƯƠNG NHÂN MIRAGE", BustLocation = "Sky Hub • Đảo Bí Ẩn",
		SelectedItem = selectedItem or items[1], Items = items,
		FilterPills = {
			fPill(st, "mirageSub", "Regular", pick("KỆ HÀNG 2 GIỜ", "2H REGULAR STOCK"), 152, "gold"),
			fPill(st, "mirageSub", "MirageVIP", pick("KỆ ĐẢO BÍ ẨN MIRAGE (VIP x3)", "MIRAGE ISLAND VIP (x3)"), 214, "primary"),
			{ timerRef = "MirageTimerLabel", lbl = "LÀM MỚI: " .. formatClockCountdown(7200 - (os.time() % 7200)) },
			{ ic = "Fruit", lbl = pick("ĐÀI GACHA ZIOLES [G]", "ZIOLES GACHA [G]"), var = "primary", w = 186, fn = function() ScreenRouter.Navigate(UIState.Screens.Fruits) end },
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
	local topTag = isSword and "KIẾM 3D" or ((fm == "ARMOR_SETS") and "GIÁP 3D" or ((fm == "RELICS") and "THÁNH VẬT" or "SÚNG 3D"))
	local iconKind = isSword and "Sword" or ((fm == "ARMOR_SETS") and "Shield" or ((fm == "RELICS") and "CoreShards" or "Gun"))

	for _, entry in ipairs(rawCatalog) do
		local itemId = entry.ItemId
		local cfg = AEC.Items[itemId] or RarityConfig.GetItem(itemId) or {}
		local rarity = cfg.Rarity or "Rare"
		local accent = hexToColor(entry.AccentHex or cfg.AccentHex, getRarityStyle(rarity)[1])
		local owned, eq = getOwnedQty(snap, itemId) > 0, isItemEquipped(snap, itemId)
		local dispName = isEn and (cfg.Name or itemId) or (cfg.VietnameseName or cfg.Name or itemId)
		local lvReq = tonumber(entry.LevelReq or cfg.LevelReq) or 1
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
			local setUp = string.upper(tostring(aSet.NameVi or cfg.ArmorSetId))
			sb[1] = { "[2/4 BỘ " .. setUp .. "]", tostring(aSet.Bonus2Vi or "Tăng mạnh Sinh Lực & Sát Thương bộ giáp.") }
			sb[2] = { "[4/4 BỘ " .. setUp .. "]", tostring(aSet.Bonus4Vi or "Kích hoạt Hào Quang Thần Giáp 3D toàn diện.") }
		else
			local wepEntry = (CoreConfig.Swords and CoreConfig.Swords[itemId]) or (CoreConfig.Guns and CoreConfig.Guns[itemId])
			local zName = cfg.SkillZ or (wepEntry and wepEntry.Skills and wepEntry.Skills.Z and wepEntry.Skills.Z.Name) or "Trảm Kích Ánh Sáng Aether"
			local xName = cfg.SkillX or (wepEntry and wepEntry.Skills and wepEntry.Skills.X and wepEntry.Skills.X.Name) or "Tuyệt Kỹ Phá Giáp Hư Không"
			sb[1] = { string.format("[Z] %s (Mastery 150 • 3.8x ATK)", tostring(zName)), tostring(cfg.Description or "Đòn đánh nguyên tố tầm xa cuốn kẻ địch vào xoáy năng lượng 3D.") }
			sb[2] = { string.format("[X] %s (Mastery 300 • 5.1x ATK • Phá Giáp)", tostring(xName)), tostring(cfg.Passive or "Phóng xung kích xuyên thủng phòng ngự Boss và gây bạo kích diện rộng.") }
		end

		local asset3D = ViewportOrbit.ResolveAssetName(itemId) or itemId
		local cardEntry = {
			id = itemId, t = dispName, st = cfg.Name or dispName, r = rarity, ac = accent, top = topTag, ic = iconKind,
			rtag = (lvReq >= 2300) and "MỚI" or nil, rcol = rgb(225, 29, 72),
			a3d = asset3D, up = string.sub(tostring(asset3D), 1, 4) == "Wep_",
			hsub = string.format("%s • %s • %s • LV.%d (%s)", string.upper(rarity), mainStat, secStat, lvReq, seaStr),
			csub = string.format("%s • %s • Lv.%d %s", mainStat, eq and "Đang trang bị" or (owned and "Đã sở hữu" or secStat), lvReq, seaStr),
			sb = sb,
			cbtn = eq and pick("ĐANG TRANG BỊ", "EQUIPPED") or (owned and pick("TRANG BỊ NGAY", "EQUIP NOW") or ("MUA • " .. priceShort)),
			cvar = (eq or owned) and "primary" or ((not isSword and (rarity == "Mythic" or rarity == "Legendary")) and "primary" or "gold"),
			hbtn = eq and pick("ĐANG TRANG BỊ TRÊN NHÂN VẬT 3D", "CURRENTLY EQUIPPED ON 3D HERO")
				or (owned and ("TRANG BỊ NGAY • " .. string.upper(dispName)) or ("MỞ KHÓA & TRANG BỊ • " .. priceShort)),
			hvar = isSword and "gold" or "primary", cicon = isSword and "Sword" or iconKind,
			sel = selFn(st, selKey, itemId),
			act = function()
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
		BustTag = isSword and "• 3D LIVE - KIẾM SƯ" or "• 3D LIVE - XẠ THỦ",
		BustTitle = isSword and "KIẾM THÁNH HẮC TINH" or "XẠ THỦ VỆ TINH",
		BustLocation = isSword and "Sky Hub • Cyberport • Umbral" or "Xưởng Vũ Khí Tầm Xa",
		SelectedItem = selectedItem or items[#items] or items[1], Items = items,
		FilterPills = isSword and {
			fPill(st, "swordSeaFilter", "ALL", pick("TẤT CẢ KIẾM", "ALL SWORDS"), 156, "gold"),
			fPill(st, "swordSeaFilter", "Sea1", "SKY 1 • SƠ CẤP", 156, "gold"),
			fPill(st, "swordSeaFilter", "Sea2", "SKY 2 • CYBER", 156, "gold"),
			fPill(st, "swordSeaFilter", "Sea3", "SKY 3 • TUYỆT ĐỈNH", 172, "gold"),
		} or {
			fPill(st, "gunFilter", "ALL_GUNS", pick("TẤT CẢ SÚNG (10)", "ALL GUNS (10)"), 154, "primary"),
			fPill(st, "gunFilter", "GUN_SEA12", "SÚNG SKY 1-2", 136, "primary"),
			fPill(st, "gunFilter", "GUN_SEA3", "PHÁP KHÍ CUỐI GAME", 166, "primary"),
			fPill(st, "gunFilter", "ARMOR_SETS", pick("THẦN GIÁP 3D (8 BỘ)", "3D ARMOR (8 SETS)"), 172, "gold"),
			fPill(st, "gunFilter", "RELICS", pick("THÁNH VẬT & NHẪN", "RELICS & RINGS"), 158, "gold"),
		},
	})
end

local function buildMartialDojoTab(body, snap)
	local st = shopSt()
	st.martialSea = st.martialSea or "ALL"
	local activeStyle = tostring((snap.fruits and snap.fruits.fightingStyle) or "skyborn_combat")
	local selId, items, selectedItem = st.selectedStyleId or "celestial_godhuman", {}, nil
	local isEn = I18n.GetLanguage() == "en"

	for _, s in ipairs(VC.MartialDojoStyles or {}) do
		if st.martialSea == "ALL" or s.Sea == st.martialSea then
			local isEq = (activeStyle == s.Id or activeStyle == s.StyleId)
			local pGold, pShards = tonumber(s.PriceGold) or 0, tonumber(s.PriceShards) or 0
			local priceTxt = (pGold == 0 and pShards == 0) and "MIỄN PHÍ" or (fmt(pGold) .. " GOLD" .. (pShards > 0 and (" + " .. fmt(pShards) .. " SHARDS") or ""))
			local title = isEn and s.NameEn or s.NameVi
			local entry = {
				id = s.Id, t = title, st = s.NameEn or title, r = s.Rarity or "Legendary",
				ac = hexToColor(s.AccentHex, GOLD), top = "VÕ HỌC", ic = "Fist",
				rtag = ((s.LevelReq or 1) >= 2400) and "MỚI" or nil, a3d = s.Model3DKind or "Martial_Godhuman",
				hsub = string.format("%s • SƯ PHỤ: %s • LV.%d (%s)", string.upper(s.Rarity or "MYTHIC"), string.upper(tostring(s.MasterVi or "ĐẠI SƯ")), s.LevelReq or 1, tostring(s.Sea or "Sea1")),
				csub = tostring(s.MasterVi or "Sư Phụ Võ Đường") .. " • " .. priceTxt .. " • [Z][X][C]",
				sb = {
					{ "[Z] Đột Kích Khí Công • [X] Phá Toái Chấn Động", "Mở khóa Hộ Uyển Hào Quang 3D trên hai tay cùng chuỗi đòn đánh cận chiến tốc độ cao." },
					{ "[C] Tuyệt Kỹ Thần Quyền Tối Thượng (Slot [1] Melee)", "Yêu cầu: Lv." .. tostring(s.LevelReq or 1) .. " • Lệ phí bái sư: " .. priceTxt },
				},
				cbtn = isEq and pick("ĐANG TRANG BỊ", "EQUIPPED") or pick("LĨNH HỘI • " .. priceTxt, "LEARN • " .. priceTxt),
				cvar = isEq and "gold" or "primary",
				hbtn = isEq and "ĐANG TRANG BỊ TRÊN SLOT [1]" or ("LĨNH HỘI & TRANG BỊ VÕ HỌC [1] • " .. priceTxt),
				hvar = "gold", cicon = "Fist",
				sel = selFn(st, "selectedStyleId", s.Id),
				act = function() fireUIAction("BuyVendorItem", { styleId = s.Id }) end,
			}
			table.insert(items, entry)
			if s.Id == selId then selectedItem = entry end
		end
	end

	renderHeroAndTwoColCatalog(body, {
		BustArchetype = "monk_halo", BustAccent = SUCC, BustTag = "• 3D LIVE - ĐẠI SƯ",
		BustTitle = "ĐẠI SƯ CỔ TỰ", BustLocation = "7 Võ Đường Truyền Thụ", SelectedItem = selectedItem or items[1], Items = items,
		FilterPills = {
			fPill(st, "martialSea", "ALL", "TẤT CẢ 7 VÕ ĐƯỜNG", 172, "gold"),
			fPill(st, "martialSea", "Sea1", "SKY 1 • NHẬP MÔN", 156, "primary"),
			fPill(st, "martialSea", "Sea2", "SKY 2 • ĐỘT PHÁ", 156, "primary"),
			fPill(st, "martialSea", "Sea3", "SKY 3 • GODHUMAN & VOID", 198, "gold"),
		},
	})
end

local ENCHANTS = {
	{ "+ Vampiric (Hút Máu 8%)", "Hồi HP bằng 8% sát thương gây ra mỗi đòn đánh", rgb(251, 113, 133) },
	{ "+ ChronoHaste (-15% Hồi Chiêu)", "Giảm 15% CD kỹ năng & tăng tốc xuất chiêu", rgb(56, 189, 248) },
	{ "+ ChainVolt (Lôi Điện Liên Hoàn)", "Giật sét 35% sát thương lan sang 2 kẻ địch gần bên", rgb(96, 165, 250) },
	{ "+ SolarCrit (+12% Crit, +30% CritD)", "Cường hóa sát thương bạo kích ánh sáng thái dương", rgb(252, 211, 77) },
	{ "+ ArmorBreaker (+22% Xuyên Giáp)", "Xuyên giáp Boss & +12 điểm phá thanh Break Gauge", rgb(192, 132, 252) },
}

local function buildEnchanterAndChronosTab(body, snap)
	local eqWep = (snap.equipped and snap.equipped.Weapon) or "Dawnbringer"
	local wepCfg = AEC.Items[eqWep] or RarityConfig.GetItem(eqWep) or {}
	local wepName = tostring(wepCfg.VietnameseName or wepCfg.Name or eqWep)
	local scrollCount = getOwnedQty(snap, "EnchantScroll")
	local lp = Players.LocalPlayer
	local activeEnchant = tostring((lp and lp:GetAttribute("WeaponEnchant")) or "SolarCrit (+12% Crit, +30% CritD)")

	local leftPanel, rightPanel = mkSplitPanels(
		body, "EnchanterP", pick("NPC 6A: PHÁP SƯ PHÙ PHÉP CỔ NGỮ (KHẮC DÒNG VŨ KHÍ)", "NPC 6A: ARCANE ENCHANTER • WEAPON RUNES"),
		"ChronosP", pick("NPC 6B: THƯƠNG NHÂN HƯ KHÔNG CHRONOS (10 PHÚT)", "NPC 6B: CHRONOS WANDERING VOID MERCHANT")
	)

	makeGlossyRarityTile(leftPanel, wepCfg.Rarity or "Mythic", "VŨ KHÍ CHỌN", wepName, "Sword", u2o(108, 128), {
		Position = u2o(14, 52), RightTag = "CÓ SẴN", IconSize = 36, DiscSize = 54, SubCaption = "+380 ATK • 5 SAO",
	})
	mkText(leftPanel, "Plus", "+", u2o(124, 98), u2o(20, 28), 20, GOLDB, true, TXC)
	makeGlossyRarityTile(leftPanel, "Legendary", "120 SHARDS", "Cuộn Phù Phép", "Scroll", u2o(108, 128), {
		Position = u2o(146, 52), RightTag = "CÓ SẴN", IconSize = 36, DiscSize = 54, SubCaption = "Đang có: x" .. tostring(scrollCount),
	})

	local curBox = mkBox(leftPanel, "CurEnch", u2o(14, 188), u2o(240, 68), rgb(12, 20, 38), 8, GOLD, 1.3, 0.20)
	mkText(curBox, "CT", "PHÙ PHÉP HIỆN TẠI:", u2o(10, 6), u2(1, -20, 0, 16), 10, GOLDB, true)
	mkText(curBox, "CV", activeEnchant .. "\nChi phí khắc lại: 1 Cuộn hoặc 120 Shards", u2o(10, 24), u2(1, -20, 0, 38), 10, SUCC, true, nil, true)

	local oddsCol = mkBox(leftPanel, "Odds", u2o(264, 52), u2(1, -278, 0, 206))
	UIFactory.ListLayout(oddsCol, Enum.FillDirection.Vertical, 5)
	for idx, eRow in ipairs(ENCHANTS) do
		local rBox = mkBox(oddsCol, "E_" .. idx, nil, u2(1, 0, 0, 37), rgb(10, 16, 30), 6, eRow[3], 1, 0.35, nil, idx)
		mkText(rBox, "ET", eRow[1], u2o(8, 2), u2(1, -16, 0, 16), 10, eRow[3], true)
		mkText(rBox, "ED", eRow[2], u2o(8, 18), u2(1, -16, 0, 15), 9, TEXT2, false)
	end

	mkBtn(leftPanel, "RollEnch", pick("KHẮC LẠI PHÙ PHÉP (1 CUỘN CỔ NGỮ)", "ROLL ENCHANT (1 SCROLL)"), "gold", u2(0, 14, 1, -54), u2(0.52, -18, 0, 40),
		function() fireLegacyUIRequest("RollWeaponEnchant", { weaponId = eqWep }) end, { icon = "CoreShards" })
	mkBtn(leftPanel, "BuyScroll", pick("MUA CUỘN / KHẮC (120 SHARDS)", "BUY SCROLL (120 SHARDS)"), "primary", u2(0.52, 4, 1, -54), u2(0.48, -18, 0, 40),
		function() fireUIAction("BuyVendorItem", { itemId = "EnchantScroll", autoEquip = false }) end, { icon = "Scroll" })

	local timerPill = uiCreate("Frame", rightPanel, {
		Name = "ChronosTimer", AnchorPoint = v2(1, 0), Position = u2(1, -14, 0, 10),
		Size = u2o(148, 26), BackgroundColor3 = rgb(48, 18, 38), BorderSizePixel = 0, ZIndex = 6,
	})
	UIFactory.Corner(timerPill, 6)
	UIFactory.Stroke(timerPill, DANG, 1.2, 0.2)
	NPCShop.Refs.VoidTimerLabel = mkText(timerPill, "VT", "RỜI ĐẢO SAU: " .. formatClockCountdown(600 - (os.time() % 600)), nil, u2s(1, 1), 10, GOLDB, true, TXC, false, 7)

	mountVendorBustCard(rightPanel, {
		Position = u2o(14, 52), Size = u2o(104, 176), CardHeight = 136, ShowSubtitles = true,
		Archetype = "void_horns", Accent = VOIDP, Tag = "• 3D LIVE - CHRONOS", Title = "ĐẢO HIỆN TẠI:", Location = "CYBERPORT CAFE",
	})

	local voidWrap = mkBox(rightPanel, "VoidOffers", u2o(126, 52), u2(1, -140, 0, 184))
	UIFactory.ListLayout(voidWrap, Enum.FillDirection.Horizontal, 6)
	for idx, off in ipairs({
		{ "EnchantScroll", "Legendary", "CÒN 3/3", "Cuộn Phù Phép", "95 Shards (-20%)", "Scroll", "gold", "Shards" },
		{ "AwakeningMicrochip", "Mythic", "CÒN 1/1", "Chip Raid V2", "250 Shards", "Raid", "primary", "Shards" },
		{ "BlueResonanceGear", "Rare", "CÒN 2/2", "Bánh Răng V4", "500 Shards", "Settings", "gold", "Shards" },
		{ "aion_chrono_cloak", "Mythic", "CÒN 1/1", "Áo Choàng Aion", "1.25M + 1.5K S", "Crown", "primary", "" },
	}) do
		local col = mkBox(voidWrap, "VC_" .. idx, nil, u2(0.25, -5, 1, 0), nil, nil, nil, nil, nil, nil, idx)
		makeGlossyRarityTile(col, off[2], off[3], off[4], off[6], u2(1, 0, 0, 142), {
			Position = u2o(0, 0), RightTag = "CÓ SẴN", IconSize = 32, DiscSize = 46, SubCaption = off[5],
		})
		mkBtn(col, "BV_" .. idx, pick("ĐỔI NGAY", "REDEEM"), off[7], u2o(0, 148), u2(1, 0, 0, 34), function()
			fireUIAction("BuyVendorItem", { itemId = off[1], currency = off[8], autoEquip = (off[1] == "aion_chrono_cloak") })
			fireLegacyUIRequest("BuyVoidMerchantItem", { offerIndex = idx, itemId = off[1] })
		end, { ts = 10, minTs = 8 })
	end

	local loreBox = mkBox(rightPanel, "Lore", u2o(14, 246), u2(1, -28, 1, -260), rgb(10, 16, 30), 8, STEEL, 1, 0.4)
	mkText(loreBox, "LT", "CƠ CHẾ THƯƠNG NHÂN HƯ KHÔNG LƯU ĐỘNG (WORLD EVENT):\n• Mỗi 10 phút xuất hiện ngẫu nhiên tại 1 trong 20 đảo (có Thông Báo Toàn Máy Chủ màu Tím Thần Thoại).\n• Bán vật phẩm giới hạn bằng Core Shards rẻ hơn 20-35% so với giá gốc!", u2o(12, 8), u2(1, -24, 1, -16), 11, TEXT2, false, nil, true)
end

local function buildShipwrightTab(body, _snap)
	local st = shopSt()
	st.shipFilter = st.shipFilter or "ALL"
	local selId, items, selectedItem = st.selectedShipId or "LeviathanHunterShip", {}, nil
	local isEn = I18n.GetLanguage() == "en"

	for idx, sh in ipairs(VC.ShipwrightFleet or {}) do
		local isHeavy = (sh.Cannons or 2) >= 6
		if st.shipFilter == "ALL" or (st.shipFilter == "LIGHT" and not isHeavy) or (st.shipFilter == "HEAVY" and isHeavy) then
			local pGold = tonumber(sh.PriceGold) or 0
			local priceStr = (pGold == 0) and "MIỄN PHÍ • TRIỆU HỒI" or ("MỞ KHÓA • " .. fmt(pGold) .. " GOLD")
			local entry = {
				id = sh.Id, t = string.format("%d. %s", idx, isEn and sh.NameEn or sh.NameVi),
				st = sh.NameEn or sh.Id, r = sh.Rarity or "Legendary",
				ac = hexToColor(sh.AccentHex, GOLD), top = "TÀU 3D", ic = "Ship",
				a3d = sh.Model3DKind or ("Ship_" .. sh.Id),
				hsub = string.format("ĐỘ BỀN THÂN TÀU: %s HP • TỐC BAY: %d STUDS/S • %d ĐẠI BÁC", fmt(sh.HP or 6000), sh.Speed or 85, sh.Cannons or 4),
				csub = string.format("%s HP • Tốc độ %d • %d Đại Bác Aether%s", fmt(sh.HP or 2500), sh.Speed or 85, sh.Cannons or 2, sh.HasHarpoon and " + Móc Cáp Harpoon" or ""),
				sb = {
					{ string.format("Vũ Trang Hạm Đội: %d Đại Bác Aether 2 mạn%s", sh.Cannons or 4, sh.HasHarpoon and " + 1 Móc Cáp Thủy Tổ Harpoon" or ""), isEn and sh.DescEn or sh.DescVi },
					{ "Sức Chứa Tổ Đội & Hạm Đội Crew: 1 Thuyền Trưởng + 5 Pháo Thủ", "Chuyên dụng vượt vùng biển mây mù Danger Zone 6 và kéo Trái Tim Leviathan về cảng!" },
				},
				cbtn = priceStr, cvar = (sh.Rarity == "Mythic" or sh.Rarity == "Legendary") and "gold" or "primary",
				hbtn = "TRIỆU HỒI CHIẾN HẠM TẠI CẢNG NGAY (" .. ((pGold == 0) and "MIỄN PHÍ" or (fmt(pGold) .. " GOLD")) .. ")",
				hvar = "gold", cicon = "Ship",
				sel = selFn(st, "selectedShipId", sh.Id),
				act = function() fireUIAction("BuyVendorItem", { shipId = sh.Id }) end,
			}
			table.insert(items, entry)
			if sh.Id == selId then selectedItem = entry end
		end
	end

	renderHeroAndTwoColCatalog(body, {
		BustArchetype = "captain_tricorn", BustAccent = GOLDB, BustTag = "• 3D LIVE - ĐÓNG TÀU",
		BustTitle = "THỢ ĐÓNG TÀU CẢNG", BustLocation = "Bến Cảng Sky Shipwright", SelectedItem = selectedItem or items[1], Items = items,
		FilterPills = {
			fPill(st, "shipFilter", "ALL", "TẤT CẢ 4 CHIẾN HẠM 3D", 182, "gold"),
			fPill(st, "shipFilter", "LIGHT", "THUYỀN TÂN THỦ & TUẦN TIỄU", 204, "primary"),
			fPill(st, "shipFilter", "HEAVY", "ĐẠI CHIẾN HẠM & LEVIATHAN", 204, "gold"),
			{ ic = "Forge", lbl = "SỬA CHỮA 100% CHIẾN HẠM (500G)", var = "primary", w = 228, fn = function()
				fireLegacyUIRequest("RepairShip", {})
				Store.ShowToast(pick("Đã gửi lệnh sửa chữa 100% Chiến Hạm!", "Requested 100% Warship Hull Repair!"), "success")
			end },
		},
	})
end

local function buildDrVegaAndTempleV4Tab(body, snap)
	local curRace = tostring((snap.fruits and snap.fruits.race) or "Skyborn")
	local v4Unlocked = (snap.fruits and snap.fruits.raceV4Active == true) or (Players.LocalPlayer and Players.LocalPlayer:GetAttribute("RaceV4Unlocked") == true)

	local leftPanel, rightPanel = mkSplitPanels(
		body, "DrVegaP", pick("NPC 8A: TIẾN SĨ DR. VEGA • ĐỔI 6 TỘC & RAID V2", "NPC 8A: DR. VEGA • 6-RACE LAB & RAID V2"),
		"TempleV4P", pick("NPC 8B: TẾ ĐÀN ĐỀN THỜ LÕI • THỨC TỈNH CÁNH TỘC V4", "NPC 8B: TEMPLE OF THE CORE • RACE V4 WINGS")
	)

	mountVendorBustCard(leftPanel, {
		Position = u2o(14, 48), Size = u2o(96, 126), CardHeight = 122, ShowSubtitles = false,
		Archetype = "scientist_visor", Accent = rgb(45, 212, 191), Tag = "• 3D LIVE - DR. VEGA",
	})

	local raceGrid = mkBox(leftPanel, "RaceGrid", u2o(118, 48), u2(1, -132, 0, 126))
	UIFactory.GridLayout(raceGrid, u2(0.333, -5, 0, 59), u2o(6, 6))
	for idx, r in ipairs(VC.RaceRerollOdds or {}) do
		local accent = hexToColor(r.AccentHex, GOLD)
		local isCur = (string.lower(curRace):find(string.lower(r.Id), 1, true) ~= nil)
		local rBox = mkBox(raceGrid, "R_" .. r.Id, nil, nil, isCur and rgb(30, 24, 14) or rgb(11, 18, 32), 8, isCur and GOLDB or accent, isCur and 1.8 or 1.0, isCur and 0.05 or 0.35, nil, idx)
		UIFactory.Icon(rBox, "Wing", u2o(6, 8), 20, accent)
		mkText(rBox, "RN", r.Id, u2o(30, 6), u2(1, -34, 0, 16), 11, TEXT1, true)
		mkText(rBox, "RO", isCur and ("ĐANG SỞ HỮU • " .. tostring(r.ChancePercent) .. "%") or ("Tỷ lệ: " .. tostring(r.ChancePercent) .. "%"), u2o(8, 34), u2(1, -14, 0, 16), 9, isCur and GOLDB or GOLD, true)
	end

	mkBtn(leftPanel, "RerollRace", pick("ĐỔI TỘC HỆ NGẪU NHIÊN (300 CORE SHARDS)", "REROLL 6-RACE LINEAGE (300 SHARDS)"), "gold", u2o(14, 184), u2(1, -28, 0, 38),
		function() fireLegacyUIRequest("RerollRace", {}) end, { icon = "CoreShards" })

	local raidBox = mkBox(leftPanel, "RaidBox", u2o(14, 230), u2(1, -28, 1, -244), rgb(10, 18, 34), 10, SAPPH, 1.3, 0.25)
	makeGlossyRarityTile(raidBox, "Mythic", "VI MẠCH", "Chip Raid V2", "Settings", u2o(92, 114), { Position = u2o(10, 10), RightTag = "CÓ SẴN", SubCaption = "100K Gold / 1 Trái" })
	mkText(raidBox, "RT", "BẢNG ĐIỀU KHIỂN ĐỘT KÍCH THỨC TỈNH TRÁI V2 (1-4 NGƯỜI)", u2o(112, 10), u2(1, -122, 0, 18), 11, TEXT1, true)
	mkText(raidBox, "RD", "Chọn Raid Hệ: [Hỏa Dương] [Vĩnh Băng] [Thánh Quang] [Dung Nham] [Lôi Vũ] [Kim Thân]\nPhần thưởng vượt 5 Đảo Raid: +1,000 Core Shards & Mở Thức Tỉnh Chiêu V2!", u2o(112, 30), u2(1, -122, 0, 48), 10, SUCC, false, nil, true)
	mkBtn(raidBox, "BuyChip", pick("MUA CHIP RAID (100K GOLD)", "BUY CHIP (100K G)"), "gold", u2o(112, 86), u2(0.48, -62, 0, 36),
		function() fireUIAction("BuyVendorItem", { itemId = "AwakeningMicrochip", autoEquip = false }) end, { ts = 10, minTs = 8 })
	mkBtn(raidBox, "OpenRaid", pick("BẮT ĐẦU RAID V2 [P]", "START RAID V2 [P]"), "primary", u2(0.48, 56, 0, 86), u2(0.52, -66, 0, 36),
		function() ScreenRouter.Navigate(UIState.Screens.Raid) end, { icon = "Raid", ts = 10, minTs = 8 })

	local stepsRow = mkBox(rightPanel, "V4Steps", u2o(14, 48), u2(1, -28, 0, 146))
	UIFactory.ListLayout(stepsRow, Enum.FillDirection.Horizontal, 8)
	for sIdx, sd in ipairs({
		{ "Mythic", "BƯỚC 1", "BÁNH RĂNG XANH", "Tìm trên Đảo Mirage", "Settings" },
		{ "Epic", "BƯỚC 2", "CẦN GẠT CỔ ĐẠI", "Vượt ải 60s Trăng Tròn", "CoreShards" },
		{ "Legendary", "BƯỚC 3", "KHẢM BÁNH RĂNG", "Chọn Nhánh Đỏ / Xanh", "Star" },
		{ "Mythic", "BƯỚC 4", "CÁNH TỘC V4 3D", "Phím [Y] biến hình V4", "Wing" },
	}) do
		makeGlossyRarityTile(stepsRow, sd[1], sd[2], sd[3], sd[5], u2(0.25, -6, 1, 0), { LayoutOrder = sIdx, RightTag = "CÓ SẴN", IconSize = 34, DiscSize = 50, SubCaption = sd[4] })
	end

	local wingBox = mkBox(rightPanel, "V4Wings", u2o(14, 202), u2(1, -28, 1, -264), rgb(10, 16, 30), 10, GOLD, 1.3, 0.22)
	local vp = uiCreate("ViewportFrame", wingBox, { Name = "WingVP", Position = u2o(6, 6), Size = u2o(156, 108), BackgroundTransparency = 1 })
	local wingKey = "Wing_Skyborn"
	for _, wk in ipairs({ "Skyborn", "Mink", "Leviathan", "Cyborg", "Ghoul", "Draco" }) do
		if string.lower(curRace):find(string.lower(wk), 1, true) then wingKey = "Wing_" .. wk; break end
	end
	ViewportOrbit.MountAssetAsync(attachTrackedOrbit(vp), wingKey, GOLDB, { FitMultiplier = 1.08, ResetAngles = true })
	mkText(wingBox, "WI", string.format("NÂNG CẤP THIÊN PHÚ CÁNH TỘC V4 [%s]:\n• Mở khóa Đôi Cánh 3D phát sáng độc quyền theo Huyết Thống.\n• Hào quang Tộc V4 phản sát thương & +30%% toàn bộ chỉ số khi bật [Y]!", string.upper(wingKey)), u2o(170, 10), u2(1, -182, 1, -20), 11, TEXT1, false, nil, true)

	mkBtn(rightPanel, "StartV4", v4Unlocked and pick("ĐÃ THỨC TỈNH V4 • VÀO ẢI CORE GEAR", "V4 AWAKENED • ENTER GEAR TRIAL") or pick("KÉO CẦN GẠT BẮT ĐẦU ẢI CỔ ĐẠI (60S)", "PULL ANCIENT LEVER • START 60S TRIAL"),
		"gold", u2(0, 14, 1, -52), u2(0.52, -18, 0, 40), function() fireUIAction("StartTempleV4Trial", {}) end, { icon = "Flame" })
	mkBtn(rightPanel, "SocketV4", pick("KHẢM BÁNH RĂNG TỘC V4 [G]", "SOCKET V4 GEAR [G]"), "primary", u2(0.52, 4, 1, -52), u2(0.48, -18, 0, 40),
		function() ScreenRouter.Navigate(UIState.Screens.Fruits) end, { icon = "Wing" })
end

local function getFruitMeta(fid)
	for _, m in ipairs(MIRAGE_FRUITS) do
		if m[1] == fid then return m[2], m[4], m[5] end
	end
	local fCfg = CoreConfig.AetherFruits and CoreConfig.AetherFruits[fid]
	return tostring((fCfg and fCfg.Name) or fid), tostring((fCfg and fCfg.Rarity) or "Legendary"), tonumber(fCfg and fCfg.Price) or 1250000
end

local function buildTradingTableTab(body, snap)
	local st = shopSt()
	st.tradeOffer = type(st.tradeOffer) == "table" and st.tradeOffer or {}
	local pacts = VC.CollectorTrades or {}
	local selPactId, selPact = st.selectedPactId or (pacts[1] and pacts[1].Id), pacts[1]
	for _, p in ipairs(pacts) do if p.Id == selPactId then selPact = p; break end end

	local giveList = (#st.tradeOffer > 0) and st.tradeOffer or ((selPact and selPact.GiveItems) or {})
	local recvList = (selPact and selPact.ReceiveItems) or {}
	local giveVal, recvVal = 0, 0
	for _, fid in ipairs(giveList) do local _, _, pr = getFruitMeta(fid); giveVal += pr end
	for _, fid in ipairs(recvList) do local _, _, pr = getFruitMeta(fid); recvVal += pr end
	local diffPct = (math.abs(giveVal - recvVal) / math.max(giveVal, recvVal, 1)) * 100
	local isFair = diffPct <= 40.0
	local lpName = string.upper(tostring((Players.LocalPlayer and Players.LocalPlayer.Name) or "SKYBORN"))

	local sideA, sideB = mkSplitPanels(
		body, "SideA", string.format("BÊN A: %s (BẠN) • BÀN ĐẶT 4 Ô", lpName),
		"SideB", "BÊN B: NHÀ SƯU TẬP ẢO ẢNH (NPC / ĐỐI TÁC)", 60
	)
	local gridA = mkBox(sideA, "GridA", u2o(14, 48), u2(1, -28, 0, 198))
	UIFactory.GridLayout(gridA, u2(0.5, -6, 0, 94), u2o(10, 10))

	for i = 1, 4 do
		local fid = giveList[i]
		if fid then
			local fName, fRar, fPrice = getFruitMeta(fid)
			local wrap = uiCreate("TextButton", gridA, { Name = "SA_" .. i, BackgroundTransparency = 1, Text = "", LayoutOrder = i })
			makeGlossyRarityTile(wrap, fRar, "Ô " .. i, fName, "Fruit", u2s(1, 1), { Position = u2o(0, 0), RightTag = "CÓ SẴN", SubCaption = "Giá trị: " .. fmt(fPrice) })
			wrap.Activated:Connect(function() if #st.tradeOffer >= i then table.remove(st.tradeOffer, i); NPCShop.RebuildWorkspace() end end)
		else
			local emptySlot = uiCreate("TextButton", gridA, {
				Name = "EA_" .. i, BackgroundColor3 = rgb(10, 16, 30), BorderSizePixel = 0,
				Text = "+ THÊM VẬT PHẨM (Ô " .. i .. ")", Font = Theme.Fonts.Bold, TextSize = 11, TextColor3 = TEXT2, LayoutOrder = i,
			})
			UIFactory.Corner(emptySlot, 10)
			UIFactory.Stroke(emptySlot, STEEL, 1.2, 0.45)
			emptySlot.Activated:Connect(function()
				for sFid, qty in pairs((snap.fruits and snap.fruits.storedFruits) or {}) do
					if (tonumber(qty) or 0) > 0 and #st.tradeOffer < 4 then table.insert(st.tradeOffer, sFid); NPCShop.RebuildWorkspace(); return end
				end
				Store.ShowToast(pick("Chọn Khế Ước Mẫu bên phải hoặc cất thêm Trái vào Kho [G]!", "Pick a Collector Pact on the right or store Fruits in [G]!"), "info")
			end)
		end
	end
	mkText(sideA, "GiveVal", "TỔNG GIÁ TRỊ ĐƯA RA: " .. fmt(giveVal) .. " GOLD", u2(0, 14, 1, -30), u2(1, -28, 0, 22), 12, GOLDB, true, TXC)

	local gridB = mkBox(sideB, "GridB", u2o(14, 48), u2(1, -28, 0, 198))
	UIFactory.GridLayout(gridB, u2(0.5, -6, 0, 94), u2o(10, 10))
	for i = 1, 3 do
		local fid = recvList[i]
		if fid then
			local fName, fRar, fPrice = getFruitMeta(fid)
			local holder = mkBox(gridB, "SB_" .. i, nil, nil, nil, nil, nil, nil, nil, nil, i)
			makeGlossyRarityTile(holder, fRar, "Ô " .. i, fName, "Fruit", u2s(1, 1), { Position = u2o(0, 0), RightTag = "CÓ SẴN", SubCaption = "Giá trị: " .. fmt(fPrice) })
		else
			mkText(mkBox(gridB, "EB_" .. i, nil, nil, rgb(10, 16, 30), 10, STEEL, 1, 0.5, nil, i), "T", "Ô ĐỐI TÁC " .. i, nil, u2s(1, 1), 11, TEXT2, true, TXC)
		end
	end

	mountVendorBustCard(mkBox(gridB, "ColCell", nil, nil, nil, nil, nil, nil, nil, nil, 4), {
		Position = u2o(0, 0), Size = u2o(140, 92), CardHeight = 90, ShowSubtitles = false,
		Archetype = "collector_tophat", Accent = GOLDB, Tag = "• 3D NPC - SƯU TẬP",
	})

	local pactRow = mkBox(sideB, "Pacts", u2o(14, 254), u2(1, -28, 0, 32))
	UIFactory.ListLayout(pactRow, Enum.FillDirection.Horizontal, 6)
	for pIdx, pact in ipairs(pacts) do
		local isSel = (selPact and selPact.Id == pact.Id)
		mkBtn(pactRow, "Pact_" .. pIdx, "KHẾ ƯỚC #" .. pIdx, isSel and "gold" or "secondary", nil, u2(0.25, -5, 1, 0),
			function() st.selectedPactId = pact.Id; st.tradeOffer = {}; NPCShop.RebuildWorkspace() end, { selected = isSel, ts = 10, minTs = 8, order = pIdx })
	end
	mkText(sideB, "RecvVal", "TỔNG GIÁ TRỊ NHẬN VỀ: " .. fmt(recvVal) .. " GOLD", u2(0, 14, 1, -30), u2(1, -28, 0, 22), 12, SUCC, true, TXC)

	local meterBox = mkBox(body, "AntiScam", u2(0, 0, 1, -48), u2(0.56, -8, 0, 44), isFair and rgb(8, 56, 40) or rgb(64, 18, 28), 10, isFair and SUCC or DANG, 1.5, 0.12)
	mkText(meterBox, "MT", string.format("CHÊNH LỆCH GIÁ TRỊ: %.1f%% (%s)", diffPct, isFair and "<= 40% HỢP LỆ CHỐNG LỪA ĐẢO" or "> 40% ĐÃ KHÓA BẢO VỆ"), nil, u2s(1, 1), 12, isFair and SUCC or DANG, true, TXC)

	mkBtn(body, "ExecTrade", isFair and pick("XÁC NHẬN GIAO DỊCH (3S)", "CONFIRM TRADE (3S)") or pick("ĐÃ KHÓA (>40%)", "LOCKED (>40%)"),
		isFair and "gold" or "secondary", u2(0.56, 4, 1, -48), u2(0.28, -8, 0, 44), function()
			if #st.tradeOffer > 0 then fireUIAction("TradeWithCollector", { giveFruits = st.tradeOffer, receiveFruits = recvList })
			elseif selPact then fireUIAction("TradeWithCollector", { offerId = selPact.Id }) end
			Store.ShowToast(pick("Đã gửi xác nhận Bàn Giao Dịch 4x4!", "Submitted 4x4 Fruit Trade Pact!"), "success")
		end, { disabled = not isFair, ts = 12 })
	mkBtn(body, "ResetTrade", pick("HỦY BỎ", "CANCEL"), "danger", u2(0.84, 4, 1, -48), u2(0.16, -4, 0, 44),
		function() st.tradeOffer = {}; NPCShop.RebuildWorkspace() end, { ts = 12 })
end

local function buildColosseumAndSpireTab(body, snap)
	local bounty = tonumber(snap.fruits and snap.fruits.bounty) or 2500000
	local lp = Players.LocalPlayer
	local pvpOn = lp and lp:GetAttribute("PvPEnabled") == true
	local spireFloor = (lp and tonumber(lp:GetAttribute("SkySpireFloor"))) or 1

	local mainShell = PremiumPanel.Create(body, {
		name = "ArenaShell", variant = "gold",
		title = pick("NPC 11: QUẢN ĐẤU TRƯỜNG 1V1 SKY COLOSSEUM & THÁP VÔ TẬN 50 TẦNG", "NPC 11: 1V1 SKY COLOSSEUM & 50F ENDLESS SKY SPIRE"),
		position = u2o(0, 0), size = u2(1, 0, 1, 0),
	})

	mountVendorBustCard(mainShell, {
		Position = u2o(16, 54), Size = u2o(128, 224), CardHeight = 182, ShowSubtitles = true,
		Archetype = "valkyrie_crest", Accent = rgb(251, 113, 133), Tag = "• 3D LIVE - QUẢN ĐẤU", Title = "BOUNTY HIỆN TẠI:", Location = fmt(bounty),
	})

	local arenaCard = mkBox(mainShell, "Arena1v1", u2o(158, 54), u2(0.42, -90, 1, -138), rgb(16, 14, 28), 12, DANG, 1.5, 0.16)
	mkText(arenaCard, "AT", "ĐẤU TRƯỜNG LUẬN VÕ 1V1 CÔNG BẰNG", u2o(16, 12), u2(1, -32, 0, 22), 14, rgb(253, 164, 175), true)
	mkText(arenaCard, "AR", "• 0 Mất điểm Bounty • Tự hồi 100% HP & Hồi chiêu\n• Đấu với Người chơi khác hoặc Kiện Tướng AI\n• Thắng thưởng: +25,000 Bounty & Huy Hiệu Đấu Sĩ\n• Đạt 10,000,000 Bounty mở khóa Triệu Hồi Thủy Quái!", u2o(16, 40), u2(1, -32, 0, 94), 12, TEXT1, false, nil, true)
	mkBtn(arenaCard, "TogglePvP", pvpOn and "PVP: ĐANG BẬT (BẤM BẬT KHIÊN)" or "KHIÊN HÒA BÌNH: BẬT (BẤM MỞ PVP)", "secondary", u2(0, 16, 1, -96), u2(1, -32, 0, 36),
		function() fireLegacyUIRequest("TogglePvP", {}) end, { icon = "Shield" })
	mkBtn(arenaCard, "Join1v1", pick("GHI DANH LUẬN VÕ 1V1 NGAY", "JOIN 1V1 COLOSSEUM NOW"), "danger", u2(0, 16, 1, -52), u2(1, -32, 0, 40),
		function()
			fireLegacyUIRequest("JoinColosseum1v1", {})
			Store.ShowToast(pick("Đã ghi danh Đấu Trường Luận Võ 1v1!", "Joined 1v1 Colosseum queue!"), "success")
		end, { icon = "Sword", ts = 12 })

	local spireCard = mkBox(mainShell, "SkySpire", u2(0.42, 80, 0, 54), u2(0.58, -96, 1, -138), rgb(11, 20, 38), 12, SAPPH, 1.5, 0.16)
	mkText(spireCard, "ST", "THÁP VÔ TẬN ENDLESS SKY SPIRE (50F)", u2o(16, 12), u2(1, -32, 0, 22), 14, rgb(92, 225, 255), true)
	mkText(spireCard, "SI", string.format("• Kỷ lục hiện tại của bạn: Tầng %d / 50\n• Mỗi 5 tầng chạm trán Boss Cường Hóa & Rương Vàng\n• Quà Tầng 50: Danh Hiệu [Bá Chủ Tháp Trời] + Lõi Veyr + 1K Shards", spireFloor), u2o(16, 38), u2(1, -32, 0, 62), 12, TEXT1, false, nil, true)

	local msStrip = mkBox(spireCard, "Milestones", u2o(16, 102), u2(1, -32, 0, 68))
	UIFactory.ListLayout(msStrip, Enum.FillDirection.Horizontal, 6)
	for mIdx, ms in ipairs({
		{ "Rare", "TẦNG 10", "Cuộn Cổ Ngữ", "Scroll" },
		{ "Epic", "TẦNG 25", "Nhẫn Aureon", "CoreShards" },
		{ "Legendary", "TẦNG 40", "Mũ Mirage", "Shield" },
		{ "Mythic", "TẦNG 50", "Lõi Veyr 3D", "Crown" },
	}) do
		makeGlossyRarityTile(msStrip, ms[1], ms[2], ms[3], ms[4], u2(0.25, -5, 1, 0), { LayoutOrder = mIdx, IconSize = 22, DiscSize = 32 })
	end

	mkBtn(spireCard, "EnterSpire", string.format("LEO TIẾP TẦNG %d (1-6 NGƯỜI)", spireFloor), "primary", u2(0, 16, 1, -52), u2(1, -32, 0, 40),
		function()
			fireLegacyUIRequest("EnterSkySpire", { floor = spireFloor })
			Store.ShowToast(pick("Đang tiến vào Tháp Vô Tận Sky Spire!", "Entering 50F Endless Sky Spire!"), "info")
		end, { icon = "Trophy", ts = 12 })

	local wb = mkBox(mainShell, "WorldBanner", u2(0, 16, 1, -68), u2(1, -32, 0, 52), rgb(48, 20, 88), 10, GOLDB, 1.5, 0.14)
	UIFactory.Gradient(wb, rgb(68, 28, 120), rgb(34, 14, 66), 90)
	UIFactory.Icon(wb, "Bolt", u2o(14, 14), 24, GOLDB)
	mkText(wb, "WT", "[THÔNG BÁO THẾ GIỚI] ĐẢO BÍ ẨN MIRAGE & THỦY TỔ LEVIATHAN XUẤT HIỆN TẠI VÙNG BIỂN HƯ KHÔNG!", u2o(46, 0), u2(1, -58, 1, 0), 12, GOLDB, true)
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
}

function NPCShop.RebuildWorkspace()
	local refs = NPCShop.Refs
	local body = refs.Body
	if not body or not body.Parent then return end
	clearOrbitsAndBusts()
	refs.MirageTimerLabel, refs.VoidTimerLabel = nil, nil
	for _, ch in ipairs(body:GetChildren()) do ch:Destroy() end

	local snap = Store.GetSnapshot()
	local mode = Store.GetView().activeVendorMode or "SwordDealer"
	if refs.TabApis then
		for tabId, api in pairs(refs.TabApis) do
			api:Update({ variant = (tabId == mode) and "gold" or "secondary", selected = (tabId == mode) })
		end
	end

	if TAB_BUILDERS[mode] then TAB_BUILDERS[mode](body, snap)
	else buildArsenalVendorTab(body, snap, mode == "GunDealer" and "GunDealer" or "SwordDealer") end
end

function NPCShop.Build(parent, _responsiveState)
	NPCShop.Cleanup()
	local snap = Store.GetSnapshot()
	local activeMode = Store.GetView().activeVendorMode or "SwordDealer"
	local root = mkBox(parent, "NPCShopScreen", nil, u2s(1, 1), nil, nil, nil, nil, nil, 2)

	local _, headerRefs = UIFactory.BuildScreenHeader(root, {
		ActiveScreen = UIState.Screens.NPCShop,
		Title = pick("CỬA HÀNG THƯƠNG NHÂN 3D & GIAO DỊCH [N]", "3D NPC VENDORS & TRADING HUB [N]"),
		Snapshot = snap,
		OnNavigate = function(targetId) ScreenRouter.Navigate(targetId) end,
		OnClose = function() ScreenRouter.CloseAllToHUD() end,
	})

	local tabBar = uiCreate("ScrollingFrame", root, {
		Name = "VendorTabs", Position = u2o(16, 70), Size = u2(1, -32, 0, 38),
		BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
		ScrollingDirection = Enum.ScrollingDirection.X, AutomaticCanvasSize = Enum.AutomaticSize.X, CanvasSize = u2o(0, 0),
	})
	UIFactory.ListLayout(tabBar, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

	local tabApis, isEn = {}, I18n.GetLanguage() == "en"
	for idx, tDef in ipairs(VENDOR_TABS) do
		local id = tDef[1]
		local isSel = (activeMode == id)
		local _, api = mkBtn(tabBar, "Tab_" .. id, isEn and tDef[4] or tDef[3], isSel and "gold" or "secondary",
			nil, u2o(142, 34), function() Store.SetView({ activeVendorMode = id }); NPCShop.RebuildWorkspace() end,
			{ icon = tDef[2], selected = isSel, ts = 10, minTs = 8, order = idx })
		tabApis[id] = api
	end

	local body = mkBox(root, "VendorWorkspace", u2o(16, 114), u2(1, -32, 1, -128))
	NPCShop.Refs = { Root = root, HeaderRefs = headerRefs, TabApis = tabApis, Body = body }
	NPCShop.RebuildWorkspace()

	NPCShop.TickerAlive = true
	task.spawn(function()
		while NPCShop.TickerAlive and root.Parent do
			task.wait(1.0)
			if NPCShop.Refs.MirageTimerLabel and NPCShop.Refs.MirageTimerLabel.Parent then
				NPCShop.Refs.MirageTimerLabel.Text = "LÀM MỚI: " .. formatClockCountdown(7200 - (os.time() % 7200))
			end
			if NPCShop.Refs.VoidTimerLabel and NPCShop.Refs.VoidTimerLabel.Parent then
				NPCShop.Refs.VoidTimerLabel.Text = "RỜI ĐẢO SAU: " .. formatClockCountdown(600 - (os.time() % 600))
			end
		end
	end)
	return root
end

function NPCShop.Update(snap)
	snap = snap or Store.GetSnapshot()
	if NPCShop.Refs.HeaderRefs and NPCShop.Refs.HeaderRefs.UpdateCurrencies then
		NPCShop.Refs.HeaderRefs.UpdateCurrencies(snap)
	end
	if NPCShop.Refs.Root and NPCShop.Refs.Root.Parent then NPCShop.RebuildWorkspace() end
end

function NPCShop.Cleanup()
	NPCShop.TickerAlive = false
	clearOrbitsAndBusts()
	NPCShop.Refs = {}
end

return NPCShop
