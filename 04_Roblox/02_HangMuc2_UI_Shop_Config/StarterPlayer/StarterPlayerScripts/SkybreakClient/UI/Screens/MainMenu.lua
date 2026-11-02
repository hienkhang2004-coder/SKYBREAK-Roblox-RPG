-- SKYBREAK: Fragments of the Core — Screen 10: 3-Class & 2-Faction Hero Command Main Menu
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/MainMenu.lua
-- Visual Upgrade: Matches Figma Design File 3 (SKYBREAK_NPC_06 Panel 1) 1:1 with Translucent Gold-Bracketed
-- Command Header, 3 Side-by-Side Hero Class Cards, 2 Glossy Faction Cards (Pirate Crimson / Marine Sapphire),
-- Bottom 6-Button Quick-Access Dock, and Live Background 3D Sky Hub Diorama Camera.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local WorldConfig = require(Shared:WaitForChild("Config"):WaitForChild("WorldConfig"))
local UIState = require(Shared:WaitForChild("Types"):WaitForChild("UIState"))
local AssetManifest = require(Shared:WaitForChild("AssetManifest"))
local SpritePlayer = require(Shared:WaitForChild("SpritePlayer"))
local UIAnimator = require(Shared:WaitForChild("UIAnimator"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Store = require(script.Parent.Parent:WaitForChild("Store"))
local ScreenRouter = require(script.Parent.Parent:WaitForChild("ScreenRouter"))
local Animations = require(script.Parent.Parent:WaitForChild("Animations"))
local I18n = require(script.Parent.Parent:WaitForChild("I18n"))
local PremiumPanel = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumPanel"))
local PremiumButton = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumButton"))
local ViewportOrbit = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("ViewportOrbit"))
local PartyController = require(script.Parent.Parent:WaitForChild("Controllers"):WaitForChild("PartyController"))
local InventoryController = require(script.Parent.Parent:WaitForChild("Controllers"):WaitForChild("InventoryController"))

local SKY_HUB_VISTA_PIVOT = Vector3.new(-92, 58, 153)

local CLASS_HERO_SPECS = {
    {
        Id = "SkyGuardian",
        Title = "SKY GUARDIAN",
        Icon = "Sword",
        Accent = Color3.fromRGB(252, 211, 77),
        AuraDark = Color3.fromRGB(120, 72, 14),
        RoleVi = "Hộ Vệ Thánh Quang • Công Thủ Toàn Diện",
        RoleEn = "Celestial Vanguard • Balanced Offense & Aegis",
        SpecVi = "Kiếm Thuật Thánh Quang • Khiên Hộ Mệnh • Hồi Phục Bền Bỉ",
        SpecEn = "Radiant Greatsword • Aether Bulwark • High Sustain",
        StatsVi = "CÔNG: 92  •  THỦ: 98  •  ĐỘ KHÓ: DỄ LÀM QUEN",
        StatsEn = "ATK: 92  •  DEF: 98  •  DIFFICULTY: BALANCED",
    },
    {
        Id = "ThunderStriker",
        Title = "THUNDER STRIKER",
        Icon = "Daggers",
        Accent = Color3.fromRGB(56, 189, 248),
        AuraDark = Color3.fromRGB(14, 74, 138),
        RoleVi = "Lôi Ảnh Thích Khách • Tốc Độ & Bạo Kích",
        RoleEn = "Lightning Assassin • Hyper-Speed & Critical Burst",
        SpecVi = "Song Đao Sấm Sét • Lướt Không Ảnh • Liên Kích Tốc Độ Cao",
        SpecEn = "Dual Storm Blades • Flash Step • High Crit Chains",
        StatsVi = "CÔNG: 98  •  TỐC: 99  •  ĐỘ KHÓ: CƠ ĐỘNG CAO",
        StatsEn = "ATK: 98  •  SPD: 99  •  DIFFICULTY: HIGH AGILITY",
    },
    {
        Id = "ArcaneMage",
        Title = "ARCANE MAGE",
        Icon = "Staff",
        Accent = Color3.fromRGB(192, 132, 252),
        AuraDark = Color3.fromRGB(78, 28, 138),
        RoleVi = "Pháp Sư Tinh Cầu • Sát Thương Phép AoE",
        RoleEn = "Astral Arcanist • Cataclysmic AoE Spellcraft",
        SpecVi = "Quyền Trượng Tinh Vân • Mưa Thiên Thạch • Cộng Hưởng Trái 3D",
        SpecEn = "Astral Scepter • Starfall AoE • 3D Fruit Synergy",
        StatsVi = "PHÉP: 99  •  DIỆN RỘNG: 97  •  ĐỘ KHÓ: PHÁP THUẬT",
        StatsEn = "MAG: 99  •  AOE: 97  •  DIFFICULTY: SPELLCASTER",
    },
}

local MainMenu = {
    Refs = {},
    CameraConn = nil,
    AncestryConn = nil,
    FallbackOrbit = nil,
    CameraCaptured = false,
}

-- Immediately restore standard gameplay Custom camera when closing MainMenu or entering world
local function restoreGameplayCamera()
    if MainMenu.CameraConn then
        MainMenu.CameraConn:Disconnect()
        MainMenu.CameraConn = nil
    end
    if MainMenu.AncestryConn then
        MainMenu.AncestryConn:Disconnect()
        MainMenu.AncestryConn = nil
    end
    if MainMenu.FallbackOrbit then
        MainMenu.FallbackOrbit:Destroy()
        MainMenu.FallbackOrbit = nil
    end
    if MainMenu.CameraCaptured then
        MainMenu.CameraCaptured = false
        local cam = workspace.CurrentCamera
        if cam then
            cam.CameraType = Enum.CameraType.Custom
            local lp = Players.LocalPlayer
            local ch = lp and lp.Character
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            if hum then
                cam.CameraSubject = hum
            end
        end
    end
end

-- Smooth orbital diorama camera around live LocalPlayer.Character or Sky Hub Plaza vista
local function startDioramaCamera(fallbackViewportHolder)
    restoreGameplayCamera()
    local t0 = os.clock()
    MainMenu.CameraCaptured = true

    MainMenu.CameraConn = RunService.RenderStepped:Connect(function()
        if ScreenRouter.CurrentScreen ~= UIState.Screens.MainMenu then
            restoreGameplayCamera()
            return
        end
        local cam = workspace.CurrentCamera
        if not cam then
            return
        end

        local elapsed = os.clock() - t0
        local lp = Players.LocalPlayer
        local ch = lp and lp.Character
        local hrp = ch and (ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart)

        if cam.CameraType ~= Enum.CameraType.Scriptable then
            cam.CameraType = Enum.CameraType.Scriptable
        end

        if hrp then
            if fallbackViewportHolder and fallbackViewportHolder.Visible then
                fallbackViewportHolder.Visible = false
            end
            local yaw = elapsed * 0.20
            local radius = 13.5
            local height = 3.8 + math.sin(elapsed * 0.55) * 0.45
            local charPos = hrp.Position
            local orbitOffset = Vector3.new(math.cos(yaw) * radius, height, math.sin(yaw) * radius)
            local camPos = charPos + orbitOffset
            local lookTarget = charPos + Vector3.new(0, 1.4, 0)
            cam.CFrame = CFrame.lookAt(camPos, lookTarget)
        else
            if fallbackViewportHolder and not fallbackViewportHolder.Visible then
                fallbackViewportHolder.Visible = true
            end
            local yaw = elapsed * 0.12
            local radius = 44
            local camPos = SKY_HUB_VISTA_PIVOT + Vector3.new(math.cos(yaw) * radius, 18 + math.sin(elapsed * 0.4) * 2.0, math.sin(yaw) * radius)
            cam.CFrame = CFrame.lookAt(camPos, SKY_HUB_VISTA_PIVOT + Vector3.new(0, 4, 0))
        end
    end)
end

local function fireFactionSelection(factionId)
    local skyRems = Shared:FindFirstChild("Remotes")
    local reqAct = skyRems and skyRems:FindFirstChild("RequestUIAction")
    if reqAct and reqAct:IsA("RemoteEvent") then
        reqAct:FireServer("SetFaction", { faction = factionId })
    end
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local uiReq = remotes and remotes:FindFirstChild("UIRequest")
    if uiReq and uiReq:IsA("RemoteEvent") and not reqAct then
        uiReq:FireServer("SetFaction", { faction = factionId })
    end
end

-- Gold L-corner brackets helper for the active hero class card
local function addCornerBrackets(card, color)
    local brackets = {}
    local corners = {
        { ax = 0, ay = 0, px = 5, py = 5, hx = 0, hy = 0 },
        { ax = 1, ay = 0, px = -5, py = 5, hx = 1, hy = 0 },
        { ax = 0, ay = 1, px = 5, py = -5, hx = 0, hy = 1 },
        { ax = 1, ay = 1, px = -5, py = -5, hx = 1, hy = 1 },
    }
    for idx, c in ipairs(corners) do
        local hBar = UIFactory.Create("Frame", card, {
            Name = "BracketH_" .. idx,
            AnchorPoint = Vector2.new(c.ax, c.ay),
            Position = UDim2.new(c.hx, c.px, c.hy, c.py),
            Size = UDim2.fromOffset(18, 2),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            ZIndex = 7,
        })
        local vBar = UIFactory.Create("Frame", card, {
            Name = "BracketV_" .. idx,
            AnchorPoint = Vector2.new(c.ax, c.ay),
            Position = UDim2.new(c.hx, c.px, c.hy, c.py),
            Size = UDim2.fromOffset(2, 18),
            BackgroundColor3 = color,
            BorderSizePixel = 0,
            ZIndex = 7,
        })
        table.insert(brackets, hBar)
        table.insert(brackets, vBar)
    end
    return brackets
end

function MainMenu.Build(parent, _responsiveState)
    MainMenu.Cleanup()
    local colors = Theme.Colors
    local snap = Store.GetSnapshot()
    local activeClassId = (snap.player and snap.player.classId) or "SkyGuardian"
    local curFaction = (Players.LocalPlayer and Players.LocalPlayer:GetAttribute("Faction"))
        or (snap.fruits and snap.fruits.faction)
        or "Pirate"

    local root = UIFactory.Create("Frame", parent, {
        Name = "MainMenu",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
    })

    MainMenu.AncestryConn = root.AncestryChanged:Connect(function(_, newParent)
        if not newParent then
            restoreGameplayCamera()
        end
    end)

    -- Fallback 3D Hero Showcase ViewportFrame (behind UI, visible only if Character hasn't spawned yet)
    local lp = Players.LocalPlayer
    local hasChar = (lp and lp.Character and (lp.Character:FindFirstChild("HumanoidRootPart") or lp.Character.PrimaryPart)) ~= nil
    local fallbackHolder = UIFactory.Create("ViewportFrame", root, {
        Name = "HeroFallbackShowcase3D",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.46, 0),
        Size = UDim2.fromOffset(420, 460),
        BackgroundTransparency = 1,
        Ambient = Color3.fromRGB(205, 218, 242),
        LightColor = Color3.fromRGB(255, 244, 216),
        LightDirection = Vector3.new(-0.6, -0.8, -0.8),
        Visible = not hasChar,
        ZIndex = 1,
    })
    if not hasChar then
        local fbOrbit = ViewportOrbit.Attach(fallbackHolder, {
            AutoSpinSpeed = 0.45,
            InitialYaw = math.rad(165),
            InitialPitch = math.rad(8),
            ShowHint = false,
            FieldOfView = 34,
        })
        MainMenu.FallbackOrbit = fbOrbit
        task.spawn(function()
            local heroModel, renderer, clip = InventoryController.CloneCharacterForViewport()
            if MainMenu.FallbackOrbit ~= fbOrbit then
                if heroModel then
                    heroModel:Destroy()
                end
                return
            end
            if heroModel then
                if renderer and clip and type(renderer.Pose) == "function" then
                    fbOrbit:SetCustomStep(function(_, _, mdl)
                        if mdl and mdl.Parent then
                            pcall(renderer.Pose, mdl, clip, os.clock())
                        end
                    end)
                end
                fbOrbit:SetModel(heroModel, { FitMultiplier = 1.12, InitialYaw = math.rad(165), ResetAngles = true })
            end
        end)
    end

    -- ========================================================================
    -- 1. TOP TRANSLUCENT GOLD-BRACKETED COMMAND HEADER
    -- Leaves right 168px clear so App.lua's FloatingResumeBtn never overlaps!
    -- ========================================================================
    local topHeader = PremiumPanel.Create(root, {
        name = "CommandTopHeader",
        variant = "gold",
        position = UDim2.fromOffset(20, 10),
        size = UDim2.new(1, -188, 0, 58),
        transparency = 0.14,
        zIndex = 4,
    })

    local logoBase = UIFactory.Create("Frame", topHeader, {
        Name = "LogoCrest",
        Position = UDim2.fromOffset(12, 9),
        Size = UDim2.fromOffset(40, 40),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
        ZIndex = 5,
    })
    UIFactory.PillCorner(logoBase)
    UIFactory.Stroke(logoBase, colors.ACCENT_GOLD, 1.8, 0.1)
    UIFactory.Icon(logoBase, "Star", UDim2.new(0.5, -13, 0.5, -13), 26, colors.ACCENT_GOLD_BRIGHT)

    local corePulseImage = UIFactory.Create("ImageLabel", logoBase, {
        Name = "CorePulse",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(38, 38),
        BackgroundTransparency = 1,
        ImageTransparency = 0.35,
        ZIndex = 6,
    })
    SpritePlayer.Play(corePulseImage, AssetManifest.CorePulseAtlas, 4, 4, 256, 256, 12, 16)

    local titleBanner = UIFactory.Label(topHeader, {
        Name = "TitleBanner",
        Text = I18n.Pick(
            "SKYBREAK • CHỌN PHE PHÁI & 3 HỆ PHÁI NHÂN VẬT 3D",
            "SKYBREAK • SELECT FACTION & 3 LIVE 3D HERO CLASSES"
        ),
        Position = UDim2.fromOffset(62, 7),
        Size = UDim2.new(1, -304, 0, 22),
        TextSize = 15,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
        ZIndex = 5,
    })
    if Animations.PulseGlow then
        Animations.PulseGlow(titleBanner, "Menu", "TextTransparency", 0.0, 0.12)
    end

    local statusLabel = UIFactory.Label(topHeader, {
        Name = "StatusText",
        Text = string.format(
            "%s: %s  •  Skyborn Lv.%d  •  %s  •  Gold: %s  •  DIORAMA 3D SKY HUB TRỰC TIẾP",
            I18n.Pick("TRẠNG THÁI", "STATUS"),
            snap.saveStatus or "Connected",
            (snap.player and snap.player.level) or 1,
            activeClassId,
            UIFactory.FormatNumber(snap.currency and snap.currency.gold or 0)
        ),
        Position = UDim2.fromOffset(62, 30),
        Size = UDim2.new(1, -304, 0, 18),
        TextSize = 11,
        TextColor = colors.ACCENT_ICE or colors.TEXT_SECONDARY,
        Truncate = Enum.TextTruncate.AtEnd,
        ZIndex = 5,
    })

    local playBtn = PremiumButton.Create(topHeader, {
        name = "EnterWorldButton",
        icon = "Sword",
        label = I18n.Pick("VÀO THẾ GIỚI NGAY [ESC]", "ENTER SKY REALM [ESC]"),
        variant = "gold",
        position = UDim2.new(1, -230, 0.5, -19),
        size = UDim2.fromOffset(218, 38),
        textSize = 12,
        minTextSize = 9,
        zIndex = 6,
        scope = "Menu",
        onActivated = function()
            restoreGameplayCamera()
            ScreenRouter.Navigate(UIState.Screens.HUD, { replace = true })
        end,
    })

    -- ========================================================================
    -- 2. CENTER 3 SIDE-BY-SIDE HERO CLASS CARDS (SKYBREAK_NPC_06 Panel 1 1:1)
    -- ========================================================================
    local classStage = UIFactory.Create("Frame", root, {
        Name = "HeroClassCardsStage",
        AnchorPoint = Vector2.new(0.5, 0),
        Position = UDim2.new(0.5, 0, 0, 78),
        Size = UDim2.new(1, -40, 1, -214),
        BackgroundTransparency = 1,
        ZIndex = 4,
    })
    UIFactory.ListLayout(classStage, Enum.FillDirection.Horizontal, 14, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)

    local classCardRefs = {}

    local function refreshClassCardVisuals(selectedId)
        activeClassId = selectedId
        for cid, cRef in pairs(classCardRefs) do
            local isSel = (cid == selectedId)
            cRef.Stroke.Color = isSel and colors.ACCENT_GOLD_BRIGHT or cRef.Spec.Accent
            cRef.Stroke.Thickness = isSel and 2.4 or 1.4
            cRef.Stroke.Transparency = isSel and 0.04 or 0.28
            cRef.Card.BackgroundTransparency = isSel and 0.12 or 0.20

            cRef.TopPillStroke.Color = isSel and colors.ACCENT_GOLD_BRIGHT or cRef.Spec.Accent
            cRef.TopPillLbl.Text = isSel
                and I18n.Pick("• ĐANG SỬ DỤNG • ACTIVE 3D RIG", "• EQUIPPED • ACTIVE 3D RIG")
                or I18n.Pick("HỆ PHÁI CHIẾN ĐẤU 3D", "3D COMBAT ARCHETYPE")
            cRef.TopPillLbl.TextColor3 = isSel and colors.ACCENT_GOLD_BRIGHT or cRef.Spec.Accent

            for _, br in ipairs(cRef.Brackets) do
                br.Visible = isSel
            end

            cRef.ButtonApi:Update({
                variant = isSel and "gold" or "secondary",
                selected = isSel,
                label = isSel
                    and I18n.Pick("ĐANG CHỌN • BẮT ĐẦU [ESC]", "SELECTED • PLAY NOW [ESC]")
                    or I18n.Pick("CHỌN HỆ PHÁI NÀY", "SELECT THIS CLASS"),
            })
        end
    end

    for idx, spec in ipairs(CLASS_HERO_SPECS) do
        local isSel = (spec.Id == activeClassId)
        local worldCls = WorldConfig.Classes and WorldConfig.Classes[spec.Id]

        local card = UIFactory.Create("Frame", classStage, {
            Name = "ClassCard_" .. spec.Id,
            Size = UDim2.new(0.333, -10, 1, 0),
            BackgroundColor3 = Color3.fromRGB(10, 15, 29),
            BackgroundTransparency = isSel and 0.12 or 0.20,
            BorderSizePixel = 0,
            LayoutOrder = idx,
            ZIndex = 4,
            ClipsDescendants = true,
        })
        UIFactory.Corner(card, Theme.Radius.Large)
        local cardStroke = UIFactory.Stroke(
            card,
            isSel and colors.ACCENT_GOLD_BRIGHT or spec.Accent,
            isSel and 2.4 or 1.4,
            isSel and 0.04 or 0.28
        )

        -- Subtle top glass specular highlight strip
        local topGloss = UIFactory.Create("Frame", card, {
            Name = "TopSpecularSheen",
            Size = UDim2.new(1, 0, 0.28, 0),
            BackgroundColor3 = spec.Accent,
            BackgroundTransparency = 0.91,
            BorderSizePixel = 0,
            ZIndex = 4,
        })
        UIFactory.Corner(topGloss, Theme.Radius.Large)

        local brackets = addCornerBrackets(card, colors.ACCENT_GOLD_BRIGHT)
        for _, br in ipairs(brackets) do
            br.Visible = isSel
        end

        -- Top Archetype Status Pill
        local topPill = UIFactory.Create("Frame", card, {
            Name = "ArchetypeStatusPill",
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 14),
            Size = UDim2.fromOffset(226, 24),
            BackgroundColor3 = Color3.fromRGB(8, 12, 22),
            BackgroundTransparency = 0.14,
            BorderSizePixel = 0,
            ZIndex = 5,
        })
        UIFactory.PillCorner(topPill)
        local topPillStroke = UIFactory.Stroke(topPill, isSel and colors.ACCENT_GOLD_BRIGHT or spec.Accent, 1.2, 0.2)
        local topPillLbl = UIFactory.Label(topPill, {
            Name = "StatusText",
            Text = isSel
                and I18n.Pick("• ĐANG SỬ DỤNG • ACTIVE 3D RIG", "• EQUIPPED • ACTIVE 3D RIG")
                or I18n.Pick("HỆ PHÁI CHIẾN ĐẤU 3D", "3D COMBAT ARCHETYPE"),
            Size = UDim2.fromScale(1, 1),
            TextSize = 10,
            TextColor = isSel and colors.ACCENT_GOLD_BRIGHT or spec.Accent,
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            ZIndex = 6,
        })

        -- Large Glowing Circular Aura Disc + Multi-Tone Class Weapon Emblem
        local emblemOuter = UIFactory.Create("Frame", card, {
            Name = "EmblemOuterAura",
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 48),
            Size = UDim2.fromOffset(162, 162),
            BackgroundColor3 = spec.Accent,
            BackgroundTransparency = 0.86,
            BorderSizePixel = 0,
            ZIndex = 5,
        })
        UIFactory.PillCorner(emblemOuter)
        UIFactory.Stroke(emblemOuter, spec.Accent, 1.2, 0.45)

        local emblemDisc = UIFactory.Create("Frame", emblemOuter, {
            Name = "EmblemCoreDisc",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(124, 124),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 6,
        })
        UIFactory.PillCorner(emblemDisc)
        local discGrad = Instance.new("UIGradient")
        discGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, spec.Accent),
            ColorSequenceKeypoint.new(1, spec.AuraDark),
        })
        discGrad.Rotation = 90
        discGrad.Parent = emblemDisc
        UIFactory.Stroke(emblemDisc, Color3.fromRGB(255, 255, 255), 1.8, 0.25)

        local discSheen = UIFactory.Create("Frame", emblemDisc, {
            Name = "DiscGloss",
            AnchorPoint = Vector2.new(0.5, 0),
            Position = UDim2.new(0.5, 0, 0, 4),
            Size = UDim2.fromOffset(96, 46),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.78,
            BorderSizePixel = 0,
            ZIndex = 7,
        })
        UIFactory.PillCorner(discSheen)

        -- Multi-tone Crisp Geometric Class Weapon Emblem (Shadow + Bright White Core)
        local shadowIcon = UIFactory.Icon(
            emblemDisc,
            spec.Icon,
            UDim2.new(0.5, -28, 0.5, -25),
            56,
            Color3.fromRGB(10, 14, 26)
        )
        if shadowIcon then
            shadowIcon.ZIndex = 7
        end
        local mainIcon = UIFactory.Icon(
            emblemDisc,
            spec.Icon,
            UDim2.new(0.5, -27, 0.5, -27),
            54,
            Color3.fromRGB(255, 255, 255)
        )
        if mainIcon then
            mainIcon.ZIndex = 8
        end

        -- Bold Uppercase Class Name & Role Subtitle
        UIFactory.Label(card, {
            Name = "ClassTitle",
            Text = spec.Title,
            Position = UDim2.fromOffset(16, 222),
            Size = UDim2.new(1, -32, 0, 28),
            TextSize = 22,
            TextColor = spec.Accent,
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            ZIndex = 6,
        })

        UIFactory.Label(card, {
            Name = "ClassRoleSubtitle",
            Text = I18n.GetLanguage() == "en" and spec.RoleEn or spec.RoleVi,
            Position = UDim2.fromOffset(16, 252),
            Size = UDim2.new(1, -32, 0, 20),
            TextSize = 13,
            TextColor = colors.TEXT_PRIMARY,
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            Truncate = Enum.TextTruncate.AtEnd,
            ZIndex = 6,
        })

        -- Specialty & Skill Summary Box
        local specBox = UIFactory.Create("Frame", card, {
            Name = "SpecialtyBox",
            Position = UDim2.fromOffset(16, 282),
            Size = UDim2.new(1, -32, 1, -356),
            BackgroundColor3 = Color3.fromRGB(8, 12, 23),
            BackgroundTransparency = 0.14,
            BorderSizePixel = 0,
            ZIndex = 5,
        })
        UIFactory.Corner(specBox, Theme.Radius.Medium)
        UIFactory.Stroke(specBox, spec.Accent, 1.0, 0.45)

        UIFactory.Label(specBox, {
            Name = "SpecialtyLine",
            Text = I18n.GetLanguage() == "en" and spec.SpecEn or spec.SpecVi,
            Position = UDim2.fromOffset(12, 10),
            Size = UDim2.new(1, -24, 0, 36),
            TextSize = 11,
            TextColor = colors.TEXT_SECONDARY,
            XAlign = Enum.TextXAlignment.Center,
            Wrapped = true,
            ZIndex = 6,
        })

        local skillHint = "[Q] • [E] • [R]  |  " .. (worldCls and worldCls.Name or spec.Title)
        UIFactory.Label(specBox, {
            Name = "StatsLine",
            Text = (I18n.GetLanguage() == "en" and spec.StatsEn or spec.StatsVi) .. "\n" .. skillHint,
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 10, 1, -8),
            Size = UDim2.new(1, -20, 0, 34),
            TextSize = 10,
            TextColor = spec.Accent,
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            Wrapped = true,
            ZIndex = 6,
        })

        -- Bottom Full-Width Tactile Class CTA Button
        local btnInst, btnApi = PremiumButton.Create(card, {
            name = "SelectClassBtn_" .. spec.Id,
            icon = spec.Icon,
            label = isSel
                and I18n.Pick("ĐANG CHỌN • BẮT ĐẦU [ESC]", "SELECTED • PLAY NOW [ESC]")
                or I18n.Pick("CHỌN HỆ PHÁI NÀY", "SELECT THIS CLASS"),
            variant = isSel and "gold" or "secondary",
            selected = isSel,
            position = UDim2.new(0, 16, 1, -60),
            size = UDim2.new(1, -32, 0, 46),
            textSize = 13,
            minTextSize = 10,
            zIndex = 6,
            scope = "Menu",
            onActivated = function()
                if activeClassId == spec.Id then
                    restoreGameplayCamera()
                    ScreenRouter.Navigate(UIState.Screens.HUD, { replace = true })
                else
                    PartyController.RequestClassOrGenderChange(spec.Id, (snap.player and snap.player.gender) or "Male")
                    if snap.player then
                        snap.player.classId = spec.Id
                    end
                    refreshClassCardVisuals(spec.Id)
                    Store.ShowToast(
                        I18n.Pick("Đã chọn Hệ Phái 3D: " .. spec.Title .. "!", "Selected 3D Class: " .. spec.Title .. "!"),
                        "success",
                        2.0
                    )
                end
            end,
        })

        local sc = btnInst and btnInst:FindFirstChildOfClass("UIScale")
        if sc and not UIAnimator.ReducedMotion then
            sc.Scale = 0.92
            task.delay((idx - 1) * 0.06, function()
                if sc and sc.Parent then
                    UIAnimator.Tween(sc, { Scale = 1.0 }, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                end
            end)
        end

        classCardRefs[spec.Id] = {
            Card = card,
            Stroke = cardStroke,
            TopPillStroke = topPillStroke,
            TopPillLbl = topPillLbl,
            Brackets = brackets,
            ButtonApi = btnApi,
            Spec = spec,
        }
    end

    -- ========================================================================
    -- 3. TWO BIG GLOSSY FACTION CARDS SIDE-BY-SIDE (SKY PIRATE vs AETHER MARINE)
    -- ========================================================================
    local factionBar = UIFactory.Create("Frame", root, {
        Name = "FactionCardsRow",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -66),
        Size = UDim2.new(1, -40, 0, 54),
        BackgroundTransparency = 1,
        ZIndex = 5,
    })

    local factionApis = {}
    local factionDefs = {
        {
            Id = "Pirate",
            Icon = "Skull",
            Variant = "danger",
            Pos = UDim2.fromOffset(0, 0),
            Vi = "PHE KHÔNG TẶC (SKY PIRATE • SĂN BOUNTY)",
            En = "SKY PIRATE FACTION (BOUNTY HUNTERS)",
        },
        {
            Id = "Marine",
            Icon = "Shield",
            Variant = "primary",
            Pos = UDim2.new(0.5, 7, 0, 0),
            Vi = "PHE THÁNH VỆ QUÂN (AETHER MARINE • BẮT TỘI PHẠM)",
            En = "AETHER MARINE FACTION (PEACEKEEPERS)",
        },
    }

    local function updateFactionLabels(selectedFac)
        curFaction = selectedFac
        for _, fDef in ipairs(factionDefs) do
            local api = factionApis[fDef.Id]
            if api then
                local isActiveF = (fDef.Id == selectedFac)
                local baseLbl = I18n.GetLanguage() == "en" and fDef.En or fDef.Vi
                api:Update({
                    variant = fDef.Variant,
                    selected = isActiveF,
                    label = isActiveF and ("[ĐANG CHỌN] " .. baseLbl) or baseLbl,
                })
            end
        end
    end

    for _, fDef in ipairs(factionDefs) do
        local isActiveF = (curFaction == fDef.Id)
        local baseLbl = I18n.GetLanguage() == "en" and fDef.En or fDef.Vi
        local _, fApi = PremiumButton.Create(factionBar, {
            name = "FactionCard_" .. fDef.Id,
            icon = fDef.Icon,
            label = isActiveF and ("[ĐANG CHỌN] " .. baseLbl) or baseLbl,
            variant = fDef.Variant,
            selected = isActiveF,
            position = fDef.Pos,
            size = UDim2.new(0.5, -7, 1, 0),
            textSize = 13,
            minTextSize = 10,
            zIndex = 5,
            scope = "Menu",
            onActivated = function()
                fireFactionSelection(fDef.Id)
                if snap.fruits then
                    snap.fruits.faction = fDef.Id
                end
                updateFactionLabels(fDef.Id)
                Store.ShowToast(
                    I18n.Pick("Đã gia nhập " .. baseLbl .. "!", "Joined " .. baseLbl .. "!"),
                    "success",
                    2.2
                )
            end,
        })
        factionApis[fDef.Id] = fApi
    end

    -- ========================================================================
    -- 4. BOTTOM 6-BUTTON QUICK-ACCESS DOCK STRIP
    -- ========================================================================
    local dockBar = UIFactory.Create("Frame", root, {
        Name = "BottomQuickAccessDock",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -12),
        Size = UDim2.new(1, -40, 0, 44),
        BackgroundTransparency = 1,
        ZIndex = 5,
    })
    UIFactory.ListLayout(dockBar, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)

    local dockItems = {
        { Name = "DockMap", Icon = "Map", Vi = "BẢN ĐỒ 20 ĐẢO [M]", En = "20-ISLAND MAP [M]", Screen = UIState.Screens.WorldMap, Variant = "primary" },
        { Name = "DockShops", Icon = "Gold", Vi = "11 CỬA HÀNG NPC 3D [N]", En = "11 3D NPC SHOPS [N]", Screen = UIState.Screens.NPCShop, Variant = "secondary" },
        { Name = "DockFruits", Icon = "Fruit", Vi = "KHO TRÁI GACHA [G]", En = "3D FRUIT GACHA [G]", Screen = UIState.Screens.Fruits, Variant = "secondary" },
        { Name = "DockInv", Icon = "Bag", Vi = "HÀNH TRANG 3D [I]", En = "3D INVENTORY [I]", Screen = UIState.Screens.Inventory, Variant = "secondary" },
        { Name = "DockSocial", Icon = "Crown", Vi = "TỔ ĐỘI & QUÀ 7 NGÀY [B]", En = "PARTY & 7-DAY GIFTS [B]", Screen = UIState.Screens.SocialRewards, Variant = "secondary" },
        { Name = "DockSettings", Icon = "Settings", Vi = "CÀI ĐẶT", En = "SETTINGS", Screen = UIState.Screens.Settings, Variant = "secondary" },
    }

    for dIdx, dItem in ipairs(dockItems) do
        PremiumButton.Create(dockBar, {
            name = dItem.Name,
            icon = dItem.Icon,
            label = I18n.GetLanguage() == "en" and dItem.En or dItem.Vi,
            variant = dItem.Variant,
            size = UDim2.new(1 / 6, -7, 1, 0),
            textSize = 11,
            minTextSize = 8,
            layoutOrder = dIdx,
            zIndex = 6,
            scope = "Menu",
            onActivated = function()
                restoreGameplayCamera()
                ScreenRouter.Navigate(dItem.Screen)
            end,
        })
    end

    local playScale = playBtn and playBtn:FindFirstChildOfClass("UIScale")
    if playScale and not UIAnimator.ReducedMotion then
        playScale.Scale = 0.92
        UIAnimator.Tween(playScale, { Scale = 1.0 }, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end

    startDioramaCamera(fallbackHolder)

    MainMenu.Refs = {
        Root = root,
        StatusLabel = statusLabel,
        RefreshClasses = refreshClassCardVisuals,
        RefreshFactions = updateFactionLabels,
        CorePulseImage = corePulseImage,
    }

    return root
end

function MainMenu.Update(snapshot)
    local refs = MainMenu.Refs
    if not refs or not refs.Root or not snapshot then
        return
    end
    local clsId = (snapshot.player and snapshot.player.classId) or "SkyGuardian"
    if refs.StatusLabel then
        refs.StatusLabel.Text = string.format(
            "%s: %s  •  Skyborn Lv.%d  •  %s  •  Gold: %s  •  DIORAMA 3D SKY HUB TRỰC TIẾP",
            I18n.Pick("TRẠNG THÁI", "STATUS"),
            snapshot.saveStatus or "Connected",
            (snapshot.player and snapshot.player.level) or 1,
            clsId,
            UIFactory.FormatNumber(snapshot.currency and snapshot.currency.gold or 0)
        )
    end
    if refs.RefreshClasses then
        refs.RefreshClasses(clsId)
    end
    if refs.RefreshFactions then
        local fac = (Players.LocalPlayer and Players.LocalPlayer:GetAttribute("Faction"))
            or (snapshot.fruits and snapshot.fruits.faction)
            or "Pirate"
        refs.RefreshFactions(fac)
    end
end

function MainMenu.Cleanup()
    restoreGameplayCamera()
    if MainMenu.Refs and MainMenu.Refs.CorePulseImage then
        SpritePlayer.Stop(MainMenu.Refs.CorePulseImage)
    end
    Animations.CleanupScope("Menu")
    MainMenu.Refs = {}
end

return MainMenu
