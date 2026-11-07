-- SKYBREAK: Fragments of the Core — Co-op Party, 3D AI Companions, 7-Day Glossy Login, Giftcodes & Hologram Leaderboard ([B])
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/SocialRewards.lua
-- Visual Upgrade: Matches Figma Design File 3 (SKYBREAK_NPC_06 Panels 3 & 4) 1:1 with 3 Vertical 3D AI Companion
-- Bust Cards + Glossy Crimson HP 100% Bars, Crew Buff & Live 3D Player Inspector, 7 Vivid Glossy Rarity Day Tiles,
-- Giftcode Input + Gold CTA, and Hologram 3D Top Server Crown Leaderboard.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SkyShared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(SkyShared:WaitForChild("Config"):WaitForChild("Theme"))
local UIState = require(SkyShared:WaitForChild("Types"):WaitForChild("UIState"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Store = require(script.Parent.Parent:WaitForChild("Store"))
local ScreenRouter = require(script.Parent.Parent:WaitForChild("ScreenRouter"))
local I18n = require(script.Parent.Parent:WaitForChild("I18n"))
local PremiumPanel = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumPanel"))
local PremiumButton = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumButton"))
local ViewportOrbit = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("ViewportOrbit"))
local PartyController = require(script.Parent.Parent:WaitForChild("Controllers"):WaitForChild("PartyController"))
local InventoryController = require(script.Parent.Parent:WaitForChild("Controllers"):WaitForChild("InventoryController"))

local SocialRewards = {
    Refs = {},
    BustConnections = {},
    InspectOverlay = nil,
    InspectOrbit = nil,
}

local RARITY_PALETTE = {
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

local AI_COMPANIONS = {
    {
        Id = "Kairo",
        ShortTag = "• 3D AI - KAIRO",
        TitleVi = "Kairo • Vanguard",
        TitleEn = "Kairo • Vanguard",
        RoleVi = "AI TANK • Hút thù hận Boss",
        RoleEn = "AI TANK • Boss Aggro & Shield",
        UnlockLv = 3,
        Icon = "Shield",
        Archetype = "paladin",
        Color = Color3.fromRGB(252, 211, 77),
        ArmorColor = Color3.fromRGB(178, 124, 28),
    },
    {
        Id = "Lumen",
        ShortTag = "• 3D AI - LUMEN",
        TitleVi = "Lumen • Starweaver",
        TitleEn = "Lumen • Starweaver",
        RoleVi = "AI HEALER • Hồi HP Tổ đội",
        RoleEn = "AI HEALER • Squad HP Regen",
        UnlockLv = 6,
        Icon = "Star",
        Archetype = "healer",
        Color = Color3.fromRGB(52, 211, 153),
        ArmorColor = Color3.fromRGB(16, 118, 92),
    },
    {
        Id = "Nyx",
        ShortTag = "• 3D AI - NYX",
        TitleVi = "Nyx • Shadowblitz",
        TitleEn = "Nyx • Shadowblitz",
        RoleVi = "AI ASSASSIN • Bạo kích Lôi",
        RoleEn = "AI ASSASSIN • Lightning Crit",
        UnlockLv = 10,
        Icon = "Daggers",
        Archetype = "assassin",
        Color = Color3.fromRGB(192, 132, 252),
        ArmorColor = Color3.fromRGB(82, 34, 142),
    },
}

local DAILY_7_REWARDS = {
    { Day = 1, Rarity = "Rare", TitleVi = "+25K Gold", TitleEn = "+25K Gold", Icon = "Gold" },
    { Day = 2, Rarity = "Rare", TitleVi = "+150 Shards", TitleEn = "+150 Shards", Icon = "CoreShards" },
    { Day = 3, Rarity = "Epic", TitleVi = "Vé Gacha x1", TitleEn = "Gacha Ticket", Icon = "Fruit" },
    { Day = 4, Rarity = "Epic", TitleVi = "x2 EXP (30p)", TitleEn = "2x EXP (30m)", Icon = "Bolt" },
    { Day = 5, Rarity = "Legendary", TitleVi = "Cuộn Cổ Ngữ", TitleEn = "Rune Scroll", Icon = "Scroll" },
    { Day = 6, Rarity = "Legendary", TitleVi = "+500 Shards", TitleEn = "+500 Shards", Icon = "CoreShards" },
    { Day = 7, Rarity = "Mythic", TitleVi = "Hộp Lõi VIP", TitleEn = "VIP Core Box", Icon = "Crown" },
}

local QUICK_GIFTCODES = {
    "SKYBREAK2026",
    "AETHERV2",
    "SKYBREAKLAUNCH",
    "FREESTAT",
}

local function fireServerUI(cmd, payload)
    payload = type(payload) == "table" and payload or {}
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local uiReq = remotes and remotes:FindFirstChild("UIRequest")
    if uiReq and uiReq:IsA("RemoteEvent") then
        uiReq:FireServer(cmd, payload)
        return
    end
    local skyRems = SkyShared:FindFirstChild("Remotes")
    local reqAct = skyRems and skyRems:FindFirstChild("RequestUIAction")
    if reqAct and reqAct:IsA("RemoteEvent") then
        reqAct:FireServer(cmd, payload)
    end
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
    local fruit = plr:GetAttribute("EquippedFruit") or (isSelf and snap.fruits and snap.fruits.equippedFruit) or "SolarTitanCore"
    local helm = plr:GetAttribute("EquippedHelm") or "Skyguard Helm"
    local chest = plr:GetAttribute("EquippedChest") or "Aether Plate"
    local fac = plr:GetAttribute("Faction") or (isSelf and snap.fruits and snap.fruits.faction) or "Pirate"
    local bounty = tonumber(plr:GetAttribute("Bounty")) or (isSelf and snap.fruits and tonumber(snap.fruits.bounty)) or 2500000

    local msg = string.format(
        "[SOI TRANG BỊ 3D] %s • Lv.%s • %s (%s) • Vũ khí: %s • Lõi Aether: %s",
        tostring(plr.DisplayName or plr.Name),
        tostring(lv),
        tostring(cls),
        tostring(fac),
        tostring(wep ~= "" and wep or "Dawnbringer"),
        tostring(fruit)
    )
    Store.ShowToast(msg, "info", 3.6)

    if not rootForModal or not rootForModal.Parent then
        return
    end

    closeInspectOverlay()
    local colors = Theme.Colors
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
        size = UDim2.fromOffset(560, 360),
        zIndex = 52,
    })

    UIFactory.Label(modal, {
        Name = "ModalTitle",
        Text = I18n.Pick(
            "SOI TRANG BỊ 3D TRỰC TIẾP • " .. string.upper(tostring(plr.DisplayName or plr.Name)),
            "LIVE 3D LOADOUT INSPECTOR • " .. string.upper(tostring(plr.DisplayName or plr.Name))
        ),
        Position = UDim2.fromOffset(18, 12),
        Size = UDim2.new(1, -120, 0, 24),
        TextSize = 14,
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
        Position = UDim2.fromOffset(18, 46),
        Size = UDim2.fromOffset(216, 294),
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

    local infoFrame = UIFactory.Create("Frame", modal, {
        Name = "LoadoutDetails",
        Position = UDim2.fromOffset(248, 46),
        Size = UDim2.new(1, -266, 0, 294),
        BackgroundColor3 = Color3.fromRGB(10, 15, 28),
        BorderSizePixel = 0,
        ZIndex = 54,
    })
    UIFactory.Corner(infoFrame, Theme.Radius.Medium)
    UIFactory.Stroke(infoFrame, colors.ACCENT_GOLD, 1.2, 0.3)

    local rows = {
        { k = I18n.Pick("CẤP ĐỘ & PHE PHÁI", "LEVEL & FACTION"), v = string.format("Lv.%s  •  %s", tostring(lv), tostring(fac)), col = colors.ACCENT_GOLD_BRIGHT },
        { k = I18n.Pick("HỆ PHÁI CHIẾN ĐẤU", "3D HERO CLASS"), v = tostring(cls), col = colors.ACCENT_SAPPHIRE },
        { k = I18n.Pick("TIỀN THƯỞNG BOUNTY", "BOUNTY"), v = UIFactory.FormatNumber(bounty) .. " BTY", col = colors.SUCCESS },
        { k = I18n.Pick("LÕI AETHER 3D", "3D AETHER CORE"), v = tostring(fruit), col = Color3.fromRGB(232, 121, 249) },
        { k = I18n.Pick("DANH KIẾM / PHÁP KHÍ", "EQUIPPED WEAPON"), v = tostring(wep ~= "" and wep or "Dawnbringer"), col = colors.TEXT_PRIMARY },
        { k = I18n.Pick("BỘ THẦN GIÁP 3D", "3D ARMOR SET"), v = tostring(chest) .. " + " .. tostring(helm), col = colors.ACCENT_ICE or colors.TEXT_SECONDARY },
    }
    for rIdx, rInfo in ipairs(rows) do
        local y = 10 + (rIdx - 1) * 40
        UIFactory.Label(infoFrame, {
            Name = "Key_" .. rIdx,
            Text = rInfo.k,
            Position = UDim2.fromOffset(12, y),
            Size = UDim2.new(1, -24, 0, 15),
            TextSize = 9,
            TextColor = colors.TEXT_SECONDARY,
            Bold = true,
            ZIndex = 55,
        })
        UIFactory.Label(infoFrame, {
            Name = "Val_" .. rIdx,
            Text = rInfo.v,
            Position = UDim2.fromOffset(12, y + 15),
            Size = UDim2.new(1, -24, 0, 20),
            TextSize = 12,
            TextColor = rInfo.col,
            Bold = true,
            Truncate = Enum.TextTruncate.AtEnd,
            ZIndex = 55,
        })
    end

    PremiumButton.Create(infoFrame, {
        name = "ModalInviteBtn",
        icon = "Users",
        label = isSelf and I18n.Pick("ĐÂY LÀ NHÂN VẬT CỦA BẠN", "YOUR ACTIVE 3D HERO") or I18n.Pick("+ MỜI VÀO TỔ ĐỘI CO-OP", "+ INVITE TO CO-OP SQUAD"),
        variant = isSelf and "secondary" or "gold",
        disabled = isSelf,
        position = UDim2.new(0, 12, 1, -44),
        size = UDim2.new(1, -24, 0, 34),
        textSize = 11,
        zIndex = 56,
        onActivated = function()
            fireServerUI("InviteParty", { targetUserId = plr.UserId })
            Store.ShowToast(I18n.Pick("Đã gửi lời mời Tổ Đội tới ", "Sent Party Invite to ") .. tostring(plr.DisplayName), "success")
            closeInspectOverlay()
        end,
    })
end

-- Vivid 6-Rarity Glossy Day Tile helper matching SKYBREAK_NPC_06 Panel 4 1:1
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

    -- Top 40% white specular gloss sheen
    local sheen = UIFactory.Create("Frame", tile, {
        Name = "SpecularSheen",
        Size = UDim2.new(1, 0, 0.42, 0),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 0.83,
        BorderSizePixel = 0,
    })
    UIFactory.Corner(sheen, Theme.Radius.Medium)

    -- Soft circular center aura disc
    local aura = UIFactory.Create("Frame", tile, {
        Name = "CenterAura",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.46, 0),
        Size = UDim2.fromOffset(42, 42),
        BackgroundColor3 = pal.Stroke,
        BackgroundTransparency = 0.72,
        BorderSizePixel = 0,
    })
    UIFactory.PillCorner(aura)

    -- Top dark day badge ("NGÀY 1" .. "NGÀY 7")
    local topPill = UIFactory.Create("Frame", tile, {
        Name = "DayHeaderPill",
        Position = UDim2.fromOffset(4, 5),
        Size = UDim2.new(1, -8, 0, 17),
        BackgroundColor3 = Color3.fromRGB(8, 12, 22),
        BackgroundTransparency = 0.18,
        BorderSizePixel = 0,
    })
    UIFactory.PillCorner(topPill)
    UIFactory.Label(topPill, {
        Name = "DayText",
        Text = claimed
            and I18n.Pick("NGÀY " .. dDef.Day .. " [OK]", "DAY " .. dDef.Day .. " [OK]")
            or I18n.Pick("NGÀY " .. dDef.Day, "DAY " .. dDef.Day),
        Position = UDim2.fromOffset(3, 0),
        Size = UDim2.new(1, -6, 1, 0),
        TextSize = 9,
        TextColor = claimed and colors.SUCCESS or (isToday and colors.ACCENT_GOLD_BRIGHT or Color3.fromRGB(248, 250, 255)),
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Truncate = Enum.TextTruncate.AtEnd,
    })

    -- Crisp white geometric vector icon
    UIFactory.Icon(tile, dDef.Icon, UDim2.new(0.5, -14, 0.46, -13), 28, Color3.fromRGB(255, 255, 255))

    -- Bottom dark obsidian reward bar (#090D18)
    local bottomBar = UIFactory.Create("Frame", tile, {
        Name = "BottomRewardBar",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 0, 1, 0),
        Size = UDim2.new(1, 0, 0, 26),
        BackgroundColor3 = Color3.fromRGB(9, 13, 24),
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
    })
    local rLbl = UIFactory.Label(bottomBar, {
        Name = "RewardCaption",
        Text = I18n.GetLanguage() == "en" and dDef.TitleEn or dDef.TitleVi,
        Position = UDim2.fromOffset(3, 1),
        Size = UDim2.new(1, -6, 1, -2),
        TextSize = 9,
        TextColor = isToday and colors.ACCENT_GOLD_BRIGHT or pal.Text,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Wrapped = true,
    })
    rLbl.TextScaled = true
    UIFactory.TextSizeConstraint(rLbl, 7, 10)

    return tile
end

-- Sculpted Live 3D AI Companion Bust Viewport (Kairo Paladin / Lumen Healer / Nyx Assassin)
local function mountCompanion3DBust(parent, comp)
    local vp = UIFactory.Create("ViewportFrame", parent, {
        Name = "BustViewport_" .. comp.Id,
        Position = UDim2.fromOffset(8, 8),
        Size = UDim2.new(1, -16, 0, 114),
        BackgroundColor3 = Color3.fromRGB(13, 19, 36),
        BorderSizePixel = 0,
        Ambient = Color3.fromRGB(205, 214, 238),
        LightColor = Color3.fromRGB(255, 248, 232),
        LightDirection = Vector3.new(-0.5, -0.7, -1),
    })
    UIFactory.Corner(vp, Theme.Radius.Small)
    UIFactory.Stroke(vp, comp.Color, 1.3, 0.22)

    local aura = UIFactory.Create("Frame", vp, {
        Name = "RadialGlow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.48),
        Size = UDim2.fromOffset(74, 74),
        BackgroundColor3 = comp.Color,
        BackgroundTransparency = 0.80,
        BorderSizePixel = 0,
    })
    UIFactory.PillCorner(aura)

    local wm = Instance.new("WorldModel")
    wm.Parent = vp
    local cam = Instance.new("Camera")
    cam.FieldOfView = 32
    cam.Parent = vp
    vp.CurrentCamera = cam

    local mdl = Instance.new("Model")
    mdl.Name = "AI3D_" .. comp.Id

    local function part(name, shape, sz, cf, col, mat)
        local p = Instance.new("Part")
        p.Name = name
        p.Shape = shape
        p.Size = sz
        p.CFrame = cf
        p.Color = col
        p.Material = mat or Enum.Material.SmoothPlastic
        p.Anchored = true
        p.CanCollide = false
        p.Parent = mdl
        return p
    end

    local torso = part("Torso", Enum.PartType.Block, Vector3.new(2.0, 1.9, 1.05), CFrame.new(0, -0.35, 0), comp.ArmorColor, Enum.Material.Metal)
    mdl.PrimaryPart = torso
    part("ChestCore", Enum.PartType.Ball, Vector3.new(0.52, 0.52, 0.35), CFrame.new(0, 0.15, 0.48), comp.Color, Enum.Material.Neon)
    part("PauldronL", Enum.PartType.Ball, Vector3.new(0.86, 0.74, 0.96), CFrame.new(-1.16, 0.34, 0), comp.Color, Enum.Material.Metal)
    part("PauldronR", Enum.PartType.Ball, Vector3.new(0.86, 0.74, 0.96), CFrame.new(1.16, 0.34, 0), comp.Color, Enum.Material.Metal)
    part("Head", Enum.PartType.Ball, Vector3.new(1.18, 1.22, 1.18), CFrame.new(0, 1.24, 0.02), Color3.fromRGB(28, 34, 52))
    part("EyeL", Enum.PartType.Ball, Vector3.new(0.20, 0.10, 0.14), CFrame.new(-0.24, 1.26, 0.56), comp.Color, Enum.Material.Neon)
    part("EyeR", Enum.PartType.Ball, Vector3.new(0.20, 0.10, 0.14), CFrame.new(0.24, 1.26, 0.56), comp.Color, Enum.Material.Neon)

    if comp.Archetype == "paladin" then
        part("CrestHelm", Enum.PartType.Block, Vector3.new(0.22, 0.65, 1.25), CFrame.new(0, 1.88, -0.05), comp.Color, Enum.Material.Neon)
        part("HelmBrow", Enum.PartType.Block, Vector3.new(1.26, 0.24, 0.75), CFrame.new(0, 1.48, 0.32), comp.ArmorColor, Enum.Material.Metal)
    elseif comp.Archetype == "healer" then
        part("HaloRing", Enum.PartType.Cylinder, Vector3.new(0.10, 1.65, 1.65), CFrame.new(0, 2.02, -0.10) * CFrame.Angles(0, 0, math.rad(90)), comp.Color, Enum.Material.Neon)
        part("Circlet", Enum.PartType.Block, Vector3.new(1.24, 0.16, 1.22), CFrame.new(0, 1.56, 0.02), comp.Color, Enum.Material.Metal)
    else
        part("StealthHood", Enum.PartType.Ball, Vector3.new(1.42, 1.44, 1.38), CFrame.new(0, 1.30, -0.10), comp.ArmorColor)
        part("BladeHornL", Enum.PartType.Block, Vector3.new(0.12, 0.62, 0.22), CFrame.new(-0.56, 1.78, 0.10) * CFrame.Angles(0, 0, math.rad(18)), comp.Color, Enum.Material.Neon)
        part("BladeHornR", Enum.PartType.Block, Vector3.new(0.12, 0.62, 0.22), CFrame.new(0.56, 1.78, 0.10) * CFrame.Angles(0, 0, math.rad(-18)), comp.Color, Enum.Material.Neon)
    end

    mdl.Parent = wm
    local phase = (#SocialRewards.BustConnections) * 1.1
    local t0 = os.clock()
    local conn = RunService.RenderStepped:Connect(function()
        if not vp.Parent then
            return
        end
        local t = (os.clock() - t0) + phase
        local yaw = math.sin(t * 1.25) * 0.22
        local bob = math.sin(t * 2.2) * 0.05
        cam.CFrame = CFrame.lookAt(
            Vector3.new(math.sin(yaw) * 4.55, 1.12 + bob, math.cos(yaw) * 4.55),
            Vector3.new(0, 0.94, 0)
        )
    end)
    table.insert(SocialRewards.BustConnections, conn)

    -- Overlapping "• 3D AI - <NAME>" pill
    local tagPill = UIFactory.Create("Frame", parent, {
        Name = "LiveAIPill",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 111),
        Size = UDim2.new(1, -20, 0, 19),
        BackgroundColor3 = Color3.fromRGB(10, 14, 26),
        BorderSizePixel = 0,
        ZIndex = 5,
    })
    UIFactory.PillCorner(tagPill)
    UIFactory.Stroke(tagPill, comp.Color, 1.2, 0.15)
    UIFactory.Label(tagPill, {
        Name = "PillText",
        Text = comp.ShortTag,
        Size = UDim2.fromScale(1, 1),
        TextSize = 9,
        TextColor = comp.Color,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        ZIndex = 6,
    })
end

function SocialRewards.Build(parent, _responsiveState)
    SocialRewards.Cleanup()
    local colors = Theme.Colors
    local snap = Store.GetSnapshot()
    Store.Session.companionStates = Store.Session.companionStates or { Kairo = true, Lumen = true, Nyx = false }
    Store.Session.claimedLoginDays = Store.Session.claimedLoginDays or {}

    local root = UIFactory.Create("Frame", parent, {
        Name = "SocialRewardsScreen",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 2,
    })

    local _, headerRefs = UIFactory.BuildScreenHeader(root, {
        ActiveScreen = UIState.Screens.SocialRewards,
        Title = I18n.Pick("TỔ ĐỘI & ĐỒNG HÀNH AI • QUÀ 7 NGÀY & BXH [B]", "PARTY & 3D AI COMPANIONS • 7-DAY REWARDS & RANKINGS [B]"),
        Snapshot = snap,
        OnNavigate = function(targetId)
            ScreenRouter.Navigate(targetId)
        end,
        OnClose = function()
            ScreenRouter.CloseAllToHUD()
        end,
    })

    local playerLv = tonumber(snap.player and snap.player.level) or 1
    local bounty = tonumber(snap.fruits and snap.fruits.bounty) or 2500000

    -- ========================================================================
    -- LEFT COLUMN (48%): CO-OP PARTY, 3 VERTICAL 3D AI COMPANIONS & CREW
    -- Matches SKYBREAK_NPC_06 Panel 3 1:1
    -- ========================================================================
    local leftPanel = PremiumPanel.Create(root, {
        name = "PartyAndCompanionsPanel",
        variant = "gold",
        position = UDim2.fromOffset(16, 72),
        size = UDim2.new(0.48, -16, 1, -84),
    })

    UIFactory.Label(leftPanel, {
        Name = "LeftHeaderTitle",
        Text = I18n.Pick(
            "TỔ ĐỘI CO-OP 6 NGƯỜI • 3 ĐỒNG HÀNH AI • HẠM ĐỘI",
            "6-PLAYER CO-OP • 3 LIVE 3D AI COMPANIONS • CREW"
        ),
        Position = UDim2.fromOffset(14, 10),
        Size = UDim2.new(1, -216, 0, 22),
        TextSize = 12,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
    })

    -- Compact Party Mode Pills on Top-Right of Left Panel
    local partySize = (snap.party and snap.party.partySize) or "Squad"
    local modeStrip = UIFactory.Create("Frame", leftPanel, {
        Name = "PartySizeStrip",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 8),
        Size = UDim2.fromOffset(192, 26),
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
                if PartyController and type(PartyController.RequestPartySize) == "function" then
                    pcall(PartyController.RequestPartySize, pMode.Id)
                end
                fireServerUI("SetPartyMode", { mode = pMode.Id })
                if snap.party then
                    snap.party.partySize = pMode.Id
                end
                SocialRewards.Update(snap)
                ScreenRouter.Navigate(UIState.Screens.SocialRewards, { forceRebuild = true, replace = true })
            end,
        })
    end

    -- 3 Vertical 3D AI Companion Cards Side-by-Side (Kairo, Lumen, Nyx)
    local compRow = UIFactory.Create("Frame", leftPanel, {
        Name = "ThreeAICompanionCards",
        Visible = false,
        Position = UDim2.fromOffset(12, 40),
        Size = UDim2.new(1, -24, 0, 266),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(compRow, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)

    for idx, comp in ipairs(AI_COMPANIONS) do
        local isUnlocked = (playerLv >= comp.UnlockLv) or snap.isDemoMode
        local isActive = (Store.Session.companionStates[comp.Id] == true) and isUnlocked

        local card = UIFactory.Create("Frame", compRow, {
            Name = "CompanionCard_" .. comp.Id,
            Size = UDim2.new(0.333, -6, 1, 0),
            BackgroundColor3 = Color3.fromRGB(10, 15, 28),
            BorderSizePixel = 0,
            LayoutOrder = idx,
        })
        UIFactory.Corner(card, Theme.Radius.Medium)
        UIFactory.Stroke(card, isActive and comp.Color or colors.STROKE_STEEL, isActive and 1.8 or 1.2, 0.16)

        -- 1. Live 3D Sculpted Companion Bust + Overlapping "• 3D AI - <NAME>" Pill
        mountCompanion3DBust(card, comp)

        -- 2. Bold Companion Title & Role Subtitle
        UIFactory.Label(card, {
            Name = "CompName",
            Text = I18n.GetLanguage() == "en" and comp.TitleEn or comp.TitleVi,
            Position = UDim2.fromOffset(8, 134),
            Size = UDim2.new(1, -16, 0, 19),
            TextSize = 12,
            TextColor = colors.TEXT_PRIMARY,
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            Truncate = Enum.TextTruncate.AtEnd,
        })

        UIFactory.Label(card, {
            Name = "CompRole",
            Text = I18n.GetLanguage() == "en" and comp.RoleEn or comp.RoleVi,
            Position = UDim2.fromOffset(6, 153),
            Size = UDim2.new(1, -12, 0, 28),
            TextSize = 10,
            TextColor = comp.Color,
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            Wrapped = true,
        })

        -- 3. Glossy Crimson Segmented "HP 100%" Bar
        local hpTrack = UIFactory.Create("Frame", card, {
            Name = "CompanionHPBar",
            Position = UDim2.fromOffset(10, 187),
            Size = UDim2.new(1, -20, 0, 22),
            BackgroundColor3 = Color3.fromRGB(8, 12, 22),
            BorderSizePixel = 0,
            ClipsDescendants = true,
        })
        UIFactory.PillCorner(hpTrack)
        UIFactory.Stroke(hpTrack, Color3.fromRGB(244, 63, 94), 1.1, 0.25)

        local hpFill = UIFactory.Create("Frame", hpTrack, {
            Name = "Fill",
            Size = UDim2.fromScale(isUnlocked and 1 or 0.35, 1),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 3,
        })
        UIFactory.PillCorner(hpFill)
        local hpGrad = Instance.new("UIGradient")
        hpGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(251, 113, 133)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(225, 29, 72)),
        })
        hpGrad.Rotation = 90
        hpGrad.Parent = hpFill

        local hpSheen = UIFactory.Create("Frame", hpFill, {
            Name = "Gloss",
            Size = UDim2.new(1, 0, 0.45, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.78,
            BorderSizePixel = 0,
            ZIndex = 4,
        })
        UIFactory.PillCorner(hpSheen)

        for seg = 1, 4 do
            UIFactory.Create("Frame", hpTrack, {
                Name = "Seg_" .. seg,
                Position = UDim2.new(seg / 5, 0, 0, 0),
                Size = UDim2.new(0, 2, 1, 0),
                BackgroundColor3 = Color3.fromRGB(8, 12, 22),
                BackgroundTransparency = 0.38,
                BorderSizePixel = 0,
                ZIndex = 5,
            })
        end

        local hpLbl = UIFactory.Label(hpTrack, {
            Name = "HPText",
            Text = isUnlocked and "HP 100%" or ("LOCK LV." .. comp.UnlockLv),
            Size = UDim2.fromScale(1, 1),
            TextSize = 10,
            TextColor = Color3.fromRGB(255, 255, 255),
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            ZIndex = 6,
        })
        hpLbl.TextStrokeColor3 = Color3.fromRGB(10, 8, 16)
        hpLbl.TextStrokeTransparency = 0.18

        -- 4. Bottom Companion Summon / Active CTA
        PremiumButton.Create(card, {
            name = "ToggleComp_" .. comp.Id,
            label = not isUnlocked and ("MỞ Ở LV." .. comp.UnlockLv)
                or (isActive and I18n.Pick("ĐANG XUẤT CHIẾN", "DEPLOYED") or I18n.Pick("TRIỆU HỒI AI", "SUMMON AI")),
            variant = isActive and "primary" or "secondary",
            disabled = not isUnlocked,
            position = UDim2.new(0, 8, 1, -44),
            size = UDim2.new(1, -16, 0, 36),
            textSize = 10,
            minTextSize = 8,
            onActivated = function()
                Store.Session.companionStates[comp.Id] = not isActive
                if PartyController and type(PartyController.ToggleCompanion) == "function" then
                    pcall(PartyController.ToggleCompanion, comp.Id)
                end
                fireServerUI("ToggleCompanion", { companionId = comp.Id, active = not isActive })
                ScreenRouter.Navigate(UIState.Screens.SocialRewards, { forceRebuild = true, replace = true })
            end,
        })
    end

    -- Crew & Co-op Buff Banner + Live Online Players Scroll
    local crewBox = UIFactory.Create("Frame", leftPanel, {
        Name = "CrewAndSquadBox",
        Position = UDim2.fromOffset(12, 314),
        Size = UDim2.new(1, -24, 1, -378),
        BackgroundColor3 = Color3.fromRGB(10, 15, 28),
        BorderSizePixel = 0,
    })
    UIFactory.Corner(crewBox, Theme.Radius.Medium)
    UIFactory.Stroke(crewBox, colors.ACCENT_SAPPHIRE, 1.2, 0.30)

    local crewBanner = UIFactory.Create("Frame", crewBox, {
        Name = "CrewBuffBanner",
        Position = UDim2.fromOffset(8, 8),
        Size = UDim2.new(1, -16, 0, 52),
        BackgroundColor3 = Color3.fromRGB(15, 24, 46),
        BorderSizePixel = 0,
    })
    UIFactory.Corner(crewBanner, Theme.Radius.Small)
    UIFactory.Stroke(crewBanner, colors.ACCENT_GOLD, 1.1, 0.32)

    UIFactory.Icon(crewBanner, "Anchor", UDim2.fromOffset(10, 13), 26, colors.ACCENT_GOLD_BRIGHT)
    UIFactory.Label(crewBanner, {
        Name = "CrewTitle",
        Text = string.format(
            "HẠM ĐỘI BẦU TRỜI [THUNDER SOVEREIGNS]  •  BOUNTY: %s",
            UIFactory.FormatNumber(bounty)
        ),
        Position = UDim2.fromOffset(44, 6),
        Size = UDim2.new(1, -54, 0, 20),
        TextSize = 11,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
    })
    UIFactory.Label(crewBanner, {
        Name = "CrewBuffs",
        Text = I18n.Pick(
            "+15% EXP Tổ Đội  •  +15% Gold Raid  •  Soi Trang Bị 3D Trực Tiếp",
            "+15% Co-op EXP  •  +15% Raid Gold  •  Live 3D Loadout Inspect"
        ),
        Position = UDim2.fromOffset(44, 27),
        Size = UDim2.new(1, -54, 0, 18),
        TextSize = 10,
        TextColor = colors.ACCENT_SAPPHIRE,
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
    })

    local playerScroll = UIFactory.Create("ScrollingFrame", crewBox, {
        Name = "OnlinePlayersScroll",
        Position = UDim2.fromOffset(8, 66),
        Size = UDim2.new(1, -16, 1, -74),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = colors.ACCENT_SAPPHIRE,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.fromOffset(0, 0),
    })
    UIFactory.ListLayout(playerScroll, Enum.FillDirection.Vertical, 6)

    local onlineList = Players:GetPlayers()
    local primaryInspectTarget = onlineList[1] or Players.LocalPlayer
    for _, plr in ipairs(onlineList) do
        if plr ~= Players.LocalPlayer then
            primaryInspectTarget = plr
            break
        end
    end

    for idx, plr in ipairs(onlineList) do
        local isSelf = (plr == Players.LocalPlayer)
        local pRow = UIFactory.Create("Frame", playerScroll, {
            Name = "PlayerRow_" .. plr.UserId,
            Size = UDim2.new(1, -6, 0, 40),
            BackgroundColor3 = Color3.fromRGB(13, 20, 38),
            BorderSizePixel = 0,
            LayoutOrder = idx,
        })
        UIFactory.Corner(pRow, Theme.Radius.Small)
        UIFactory.Stroke(pRow, isSelf and colors.ACCENT_GOLD or colors.STROKE_STEEL, 1, 0.35)

        local pLv = plr:GetAttribute("Level") or (isSelf and playerLv) or 1
        local pFac = plr:GetAttribute("Faction") or (snap.fruits and snap.fruits.faction) or "Pirate"
        UIFactory.Label(pRow, {
            Name = "PName",
            Text = string.format("%s%s  •  Lv.%s  [%s]", tostring(plr.DisplayName or plr.Name), isSelf and " (BẠN)" or "", tostring(pLv), tostring(pFac)),
            Position = UDim2.fromOffset(10, 0),
            Size = UDim2.new(1, -196, 1, 0),
            TextSize = 11,
            TextColor = colors.TEXT_PRIMARY,
            Bold = true,
            Truncate = Enum.TextTruncate.AtEnd,
        })

        PremiumButton.Create(pRow, {
            name = "Inspect_" .. plr.UserId,
            label = I18n.Pick("SOI 3D", "3D VIEW"),
            variant = "primary",
            position = UDim2.new(1, -178, 0.5, -13),
            size = UDim2.fromOffset(82, 26),
            textSize = 9,
            minTextSize = 8,
            onActivated = function()
                inspectTargetPlayer(plr, root)
            end,
        })

        PremiumButton.Create(pRow, {
            name = "Invite_" .. plr.UserId,
            label = isSelf and "ONLINE" or I18n.Pick("+ MỜI", "+ INVITE"),
            variant = isSelf and "secondary" or "gold",
            disabled = isSelf,
            position = UDim2.new(1, -90, 0.5, -13),
            size = UDim2.fromOffset(82, 26),
            textSize = 9,
            minTextSize = 8,
            onActivated = function()
                fireServerUI("InviteParty", { targetUserId = plr.UserId })
                Store.ShowToast(I18n.Pick("Đã gửi lời mời Tổ Đội tới ", "Sent Party Invite to ") .. tostring(plr.DisplayName), "success")
            end,
        })
    end

    -- Bottom 3 Action Buttons Side-by-Side (matching SKYBREAK_NPC_06 Panel 3 1:1)
    local leftBottomBar = UIFactory.Create("Frame", leftPanel, {
        Name = "LeftBottomActions",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 12, 1, -12),
        Size = UDim2.new(1, -24, 0, 44),
        BackgroundTransparency = 1,
    })

    PremiumButton.Create(leftBottomBar, {
        name = "InviteCoopBtn",
        icon = "Users",
        label = I18n.Pick("+ MỜI TỔ ĐỘI CO-OP", "+ INVITE CO-OP"),
        variant = "gold",
        position = UDim2.fromOffset(0, 0),
        size = UDim2.new(0.32, -4, 1, 0),
        textSize = 10,
        minTextSize = 8,
        onActivated = function()
            local invitedCount = 0
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= Players.LocalPlayer then
                    invitedCount += 1
                    fireServerUI("InviteParty", { targetUserId = plr.UserId })
                end
            end
            if invitedCount > 0 then
                Store.ShowToast(I18n.Pick("Đã gửi lời mời Co-op tới " .. invitedCount .. " Chiến Binh trong Server!", "Invited " .. invitedCount .. " players to Co-op Squad!"), "success")
            else
                fireServerUI("InviteParty", {})
                Store.ShowToast(I18n.Pick("Đã phát tín hiệu chiêu mộ Tổ Đội Co-op trên kênh Server!", "Broadcasted Co-op Squad recruitment beacon!"), "info")
            end
        end,
    })

    PremiumButton.Create(leftBottomBar, {
        name = "Inspect3DPlayerBtn",
        icon = "Shield",
        label = I18n.Pick("SOI TRANG BỊ 3D NGƯỜI CHƠI", "INSPECT 3D LOADOUT"),
        variant = "primary",
        position = UDim2.new(0.32, 3, 0, 0),
        size = UDim2.new(0.36, -6, 1, 0),
        textSize = 10,
        minTextSize = 8,
        onActivated = function()
            inspectTargetPlayer(primaryInspectTarget or Players.LocalPlayer, root)
        end,
    })

    PremiumButton.Create(leftBottomBar, {
        name = "SummonSeaBeastBtn",
        icon = "Raid",
        label = I18n.Pick("TRIỆU HỒI THÚ TRỜI (10M)", "SUMMON SKY BEAST (10M)"),
        variant = "secondary",
        position = UDim2.new(0.68, 3, 0, 0),
        size = UDim2.new(0.32, -3, 1, 0),
        textSize = 10,
        minTextSize = 8,
        onActivated = function()
            fireServerUI("SummonSeaBeast", {})
            Store.ShowToast(I18n.Pick("Đã phát hiệu lệnh Triệu Hồi Thú Trời (10M Bounty)!", "Requested Crew Sky Beast Summon!"), "info")
        end,
    })

    -- ========================================================================
    -- RIGHT COLUMN (52%): 7-DAY GLOSSY REWARDS, GIFTCODE & HOLOGRAM LEADERBOARD
    -- Matches SKYBREAK_NPC_06 Panel 4 1:1
    -- ========================================================================
    local rightPanel = PremiumPanel.Create(root, {
        name = "RewardsAndLeaderboardPanel",
        variant = "gold",
        position = UDim2.new(0.48, 8, 0, 72),
        size = UDim2.new(0.52, -24, 1, -84),
    })

    local lp = Players.LocalPlayer
    local loginStreak = (lp and tonumber(lp:GetAttribute("LoginStreak"))) or 1
    local clampedStreak = math.clamp(loginStreak, 1, 7)

    UIFactory.Label(rightPanel, {
        Name = "RightHeaderTitle",
        Text = I18n.Pick(
            "ĐIỂM DANH 7 NGÀY • MÃ QUÀ GIFTCODE • BẢNG XẾP HẠNG TOP SERVER",
            "7-DAY LOGIN STREAK • GIFTCODES • HOLOGRAM TOP LEADERBOARD"
        ),
        Position = UDim2.fromOffset(14, 10),
        Size = UDim2.new(1, -174, 0, 22),
        TextSize = 12,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
    })

    local function claimTodayDailyGift()
        Store.Session.claimedLoginDays[clampedStreak] = true
        fireServerUI("ClaimDailyLogin", {})
        Store.ShowToast(
            I18n.Pick("Đã nhận Quà Điểm Danh Ngày " .. tostring(clampedStreak) .. "!", "Claimed Day " .. tostring(clampedStreak) .. " Login Reward!"),
            "success"
        )
        ScreenRouter.Navigate(UIState.Screens.SocialRewards, { forceRebuild = true, replace = true })
    end

    PremiumButton.Create(rightPanel, {
        name = "TopClaimDailyBtn",
        icon = "Gift",
        label = Store.Session.claimedLoginDays[clampedStreak]
            and I18n.Pick("ĐÃ NHẬN NGÀY " .. clampedStreak, "CLAIMED DAY " .. clampedStreak)
            or I18n.Pick("NHẬN NGÀY " .. clampedStreak, "CLAIM DAY " .. clampedStreak),
        variant = Store.Session.claimedLoginDays[clampedStreak] and "secondary" or "gold",
        position = UDim2.new(1, -152, 0, 8),
        size = UDim2.fromOffset(138, 26),
        textSize = 9,
        minTextSize = 8,
        onActivated = claimTodayDailyGift,
    })

    -- 7 Vivid Glossy Rarity Day Cards Side-by-Side (NGÀY 1 .. NGÀY 7)
    local streakGrid = UIFactory.Create("Frame", rightPanel, {
        Name = "Glossy7DayStrip",
        Position = UDim2.fromOffset(12, 38),
        Size = UDim2.new(1, -24, 0, 108),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(streakGrid, Enum.FillDirection.Horizontal, 6)

    for _, dDef in ipairs(DAILY_7_REWARDS) do
        local isToday = (dDef.Day == clampedStreak)
        local claimed = (Store.Session.claimedLoginDays[dDef.Day] == true) or (dDef.Day < loginStreak)
        local dayTile = makeGlossyDayCard(streakGrid, dDef, isToday, claimed)
        dayTile.Activated:Connect(claimTodayDailyGift)
    end

    -- Giftcode Input Row + Glossy Gold "NHẬP CODE NHẬN QUÀ NGAY!" CTA + Quick Chips
    local codeBox = UIFactory.Create("TextBox", rightPanel, {
        Name = "GiftcodeInput",
        Position = UDim2.fromOffset(12, 156),
        Size = UDim2.new(0.58, -16, 0, 40),
        Text = "",
        PlaceholderText = I18n.Pick("Nhập Giftcode: SKYBREAK2026...", "Enter Giftcode: SKYBREAK2026..."),
        Font = Theme.Fonts.Bold,
        TextSize = 12,
        TextColor3 = colors.TEXT_PRIMARY,
        PlaceholderColor3 = colors.TEXT_SECONDARY,
        BackgroundColor3 = Color3.fromRGB(9, 13, 24),
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    UIFactory.Corner(codeBox, Theme.Radius.Small)
    UIFactory.Stroke(codeBox, colors.ACCENT_GOLD, 1.3, 0.22)
    UIFactory.Padding(codeBox, 0, 12, 0, 12)

    local function submitGiftcode(rawCode)
        local clean = string.upper((tostring(rawCode or "")):gsub("%s+", ""))
        if clean == "" then
            Store.ShowToast(I18n.Pick("Hãy nhập hoặc bấm chọn 1 Mã Giftcode bên dưới!", "Enter or tap a Giftcode chip below!"), "warning")
            return
        end
        codeBox.Text = clean
        fireServerUI("RedeemCode", { code = clean })
        Store.ShowToast(I18n.Pick("Đang kích hoạt Mã Giftcode nhận quà: ", "Redeeming Giftcode: ") .. clean, "success")
    end

    PremiumButton.Create(rightPanel, {
        name = "RedeemGiftcodeBtn",
        icon = "Gift",
        label = I18n.Pick("NHẬP CODE NHẬN QUÀ NGAY!", "REDEEM GIFTCODE NOW!"),
        variant = "gold",
        position = UDim2.new(0.58, 2, 0, 156),
        size = UDim2.new(0.42, -14, 0, 40),
        textSize = 11,
        minTextSize = 9,
        onActivated = function()
            submitGiftcode(codeBox.Text)
        end,
    })

    local chipRow = UIFactory.Create("Frame", rightPanel, {
        Name = "QuickCodeChips",
        Position = UDim2.fromOffset(12, 202),
        Size = UDim2.new(1, -24, 0, 26),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(chipRow, Enum.FillDirection.Horizontal, 5)

    for idx, qCode in ipairs(QUICK_GIFTCODES) do
        PremiumButton.Create(chipRow, {
            name = "Chip_" .. qCode,
            label = qCode,
            variant = "secondary",
            size = UDim2.new(0.25, -4, 1, 0),
            textSize = 9,
            minTextSize = 7,
            layoutOrder = idx,
            onActivated = function()
                submitGiftcode(qCode)
            end,
        })
    end

    -- Hologram 3D Top Server Crown Leaderboard Box
    local holoBox = UIFactory.Create("Frame", rightPanel, {
        Name = "HologramLeaderboardBox",
        Position = UDim2.fromOffset(12, 236),
        Size = UDim2.new(1, -24, 1, -248),
        BackgroundColor3 = Color3.fromRGB(9, 14, 27),
        BorderSizePixel = 0,
    })
    UIFactory.Corner(holoBox, Theme.Radius.Medium)
    UIFactory.Stroke(holoBox, Color3.fromRGB(56, 189, 248), 1.3, 0.25)

    UIFactory.Icon(holoBox, "Trophy", UDim2.fromOffset(12, 8), 18, colors.ACCENT_GOLD_BRIGHT)
    UIFactory.Label(holoBox, {
        Name = "LeaderboardHeader",
        Text = I18n.Pick(
            "BẢNG XẾP HẠNG ĐÀI TƯỞNG NIỆM HOLOGRAM 3D",
            "3D HOLOGRAM MONUMENT SERVER LEADERBOARD"
        ),
        Position = UDim2.fromOffset(36, 7),
        Size = UDim2.new(1, -48, 0, 20),
        TextSize = 11,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
    })

    local lbScroll = UIFactory.Create("ScrollingFrame", holoBox, {
        Name = "LeaderboardScroll",
        Position = UDim2.fromOffset(10, 32),
        Size = UDim2.new(1, -20, 1, -40),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = colors.ACCENT_GOLD,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.fromOffset(0, 0),
    })
    UIFactory.ListLayout(lbScroll, Enum.FillDirection.Vertical, 6)

    local entries = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        local isSelf = (plr == Players.LocalPlayer)
        local lv = tonumber(plr:GetAttribute("Level")) or (isSelf and playerLv) or 1
        local bty = tonumber(plr:GetAttribute("Bounty")) or (isSelf and bounty) or 250000
        local eqFruit = tostring(plr:GetAttribute("EquippedFruit") or (isSelf and snap.fruits and snap.fruits.equippedFruit) or "SolarTitanCore")
        local eqWep = tostring(plr:GetAttribute("EquippedSword") or "Dawnbringer")
        table.insert(entries, {
            Name = tostring(plr.DisplayName or plr.Name) .. (isSelf and " (BẠN)" or ""),
            Level = lv,
            Bounty = bty,
            Title = tostring(plr:GetAttribute("ActiveTitle") or (lv >= 1500 and "Bá Vương Bầu Trời" or "Chiến Binh Skyborn")),
            Loadout = eqFruit .. " • " .. eqWep,
            IsSelf = isSelf,
            PlayerRef = plr,
        })
    end

    for _, npcLegend in ipairs({
        { Name = "Aureon Sovereign", Level = 2550, Bounty = 30000000, Title = "Thần Hộ Vệ Thái Dương", Loadout = "Abyssal Sovereign 3D • Song Kiếm Nguyệt Thực" },
        { Name = "Commander Lyra", Level = 2450, Bounty = 24800000, Title = "Tổng Chỉ Huy Thánh Vệ", Loadout = "Lõi Kim Thân 3D • Thiên Kiếm" },
        { Name = "Master Kael", Level = 2300, Bounty = 18500000, Title = "Đại Sư Rèn Thần Khí", Loadout = "Star Magma 3D • Thần Chùy" },
        { Name = "Admiral Cryon", Level = 1950, Bounty = 12400000, Title = "Đô Đốc Tuần Dương Băng", Loadout = "Glacier Ice 3D • Pháo Hạm" },
    }) do
        if #entries < 5 then
            table.insert(entries, npcLegend)
        end
    end

    table.sort(entries, function(a, b)
        if a.Bounty ~= b.Bounty then
            return a.Bounty > b.Bounty
        end
        return a.Level > b.Level
    end)

    for rank, e in ipairs(entries) do
        local rankColor = (rank == 1 and colors.ACCENT_GOLD_BRIGHT)
            or (rank == 2 and Color3.fromRGB(196, 218, 248))
            or (rank == 3 and Color3.fromRGB(242, 166, 98))
            or Color3.fromRGB(56, 189, 248)

        local row = UIFactory.Create("TextButton", lbScroll, {
            Name = "Rank_" .. rank,
            Size = UDim2.new(1, -6, 0, 52),
            BackgroundColor3 = e.IsSelf and Color3.fromRGB(18, 28, 52) or Color3.fromRGB(12, 18, 34),
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = (e.PlayerRef ~= nil),
            LayoutOrder = rank,
        })
        UIFactory.Corner(row, Theme.Radius.Small)
        UIFactory.Stroke(row, rankColor, e.IsSelf and 1.8 or 1.2, 0.20)

        -- Left Crown Vector Icon + "HẠNG #N" Badge
        local rankBox = UIFactory.Create("Frame", row, {
            Name = "RankCrownBadge",
            Position = UDim2.fromOffset(8, 8),
            Size = UDim2.fromOffset(86, 36),
            BackgroundColor3 = Color3.fromRGB(8, 12, 22),
            BorderSizePixel = 0,
        })
        UIFactory.Corner(rankBox, Theme.Radius.Small)
        UIFactory.Stroke(rankBox, rankColor, 1.2, 0.22)
        UIFactory.Icon(rankBox, "Crown", UDim2.fromOffset(7, 9), 18, rankColor)
        UIFactory.Label(rankBox, {
            Name = "RankNum",
            Text = I18n.Pick("HẠNG #" .. rank, "RANK #" .. rank),
            Position = UDim2.fromOffset(27, 0),
            Size = UDim2.new(1, -30, 1, 0),
            TextSize = 10,
            TextColor = rankColor,
            Bold = true,
            Truncate = Enum.TextTruncate.AtEnd,
        })

        UIFactory.Label(row, {
            Name = "NameAndTitle",
            Text = string.format("%s  •  %s", e.Name, e.Title),
            Position = UDim2.fromOffset(102, 7),
            Size = UDim2.new(1, -264, 0, 19),
            TextSize = 12,
            TextColor = (rank == 1) and colors.ACCENT_GOLD_BRIGHT or colors.TEXT_PRIMARY,
            Bold = true,
            Truncate = Enum.TextTruncate.AtEnd,
        })

        UIFactory.Label(row, {
            Name = "LoadoutSub",
            Text = tostring(e.Loadout or "Skyborn Arsenal 3D"),
            Position = UDim2.fromOffset(102, 27),
            Size = UDim2.new(1, -264, 0, 17),
            TextSize = 10,
            TextColor = colors.TEXT_SECONDARY,
            Truncate = Enum.TextTruncate.AtEnd,
        })

        UIFactory.Label(row, {
            Name = "BountyAndLv",
            Text = string.format("Bounty: %s\nLv.%d", UIFactory.FormatNumber(e.Bounty), e.Level),
            Position = UDim2.new(1, -156, 0, 6),
            Size = UDim2.fromOffset(146, 40),
            TextSize = 11,
            TextColor = Color3.fromRGB(56, 189, 248),
            Bold = true,
            XAlign = Enum.TextXAlignment.Right,
        })

        if e.PlayerRef then
            row.Activated:Connect(function()
                inspectTargetPlayer(e.PlayerRef, root)
            end)
        end
    end

    SocialRewards.Refs = {
        Root = root,
        HeaderRefs = headerRefs,
    }
    return root
end

function SocialRewards.Update(snap)
    snap = snap or Store.GetSnapshot()
    if SocialRewards.Refs.HeaderRefs and SocialRewards.Refs.HeaderRefs.UpdateCurrencies then
        SocialRewards.Refs.HeaderRefs.UpdateCurrencies(snap)
    end
end

function SocialRewards.Cleanup()
    closeInspectOverlay()
    for _, conn in ipairs(SocialRewards.BustConnections) do
        if conn then
            conn:Disconnect()
        end
    end
    SocialRewards.BustConnections = {}
    SocialRewards.Refs = {}
end

return SocialRewards
