-- SKYBREAK: Fragments of the Core — Unified Modular UI Application Orchestrator
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/App.lua
-- Creates the canonical StarterGui/PlayerGui hierarchy:
-- SkybreakUI (ScreenGui) -> BackgroundLayer, HUDLayer, MenuLayer, ModalLayer, NotificationLayer (Section 05).

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local UIState = require(Shared:WaitForChild("Types"):WaitForChild("UIState"))
local PanelMotion = require(Shared:WaitForChild("PanelMotion"))

local UIFactory = require(script.Parent:WaitForChild("UIFactory"))
local Responsive = require(script.Parent:WaitForChild("Responsive"))
local Animations = require(script.Parent:WaitForChild("Animations"))
local Store = require(script.Parent:WaitForChild("Store"))
local ScreenRouter = require(script.Parent:WaitForChild("ScreenRouter"))
local I18n = require(script.Parent:WaitForChild("I18n"))

local Toast = require(script.Parent:WaitForChild("Components"):WaitForChild("Toast"))
local Modal = require(script.Parent:WaitForChild("Components"):WaitForChild("Modal"))
local LootFeed = require(script.Parent:WaitForChild("Components"):WaitForChild("LootFeed"))

local MainMenu = require(script.Parent:WaitForChild("Screens"):WaitForChild("MainMenu"))
local HUD = require(script.Parent:WaitForChild("Screens"):WaitForChild("HUD"))
local Inventory = require(script.Parent:WaitForChild("Screens"):WaitForChild("Inventory"))
local Skills = require(script.Parent:WaitForChild("Screens"):WaitForChild("Skills"))
local Fruits = require(script.Parent:WaitForChild("Screens"):WaitForChild("Fruits"))
local NPCShop = require(script.Parent:WaitForChild("Screens"):WaitForChild("NPCShop"))
local WorldMap = require(script.Parent:WaitForChild("Screens"):WaitForChild("WorldMap"))
local QuestJournal = require(script.Parent:WaitForChild("Screens"):WaitForChild("QuestJournal"))
local Forge = require(script.Parent:WaitForChild("Screens"):WaitForChild("Forge"))
local Raid = require(script.Parent:WaitForChild("Screens"):WaitForChild("Raid"))
local SocialRewards = require(script.Parent:WaitForChild("Screens"):WaitForChild("SocialRewards"))
local Dialogue = require(script.Parent:WaitForChild("Screens"):WaitForChild("Dialogue"))
local Settings = require(script.Parent:WaitForChild("Screens"):WaitForChild("Settings"))

local HUDController = require(script.Parent:WaitForChild("Controllers"):WaitForChild("HUDController"))
local QuestController = require(script.Parent:WaitForChild("Controllers"):WaitForChild("QuestController"))

local App = {
    Initialized = false,
    Page = "HUD",
    Current = "HUD",
    LastRenderedRoute = nil,
    LowFX = false,
    State = nil,
    ScreenGui = nil,
    Layers = {},
    ToastApi = nil,
    ModalApi = nil,
    DialogueApi = nil,
    OnboardingModal = nil,
    LastStructuredDialogueClock = 0,
    Connections = {},
}

local ORIGIN_CLASSES = {
    {
        id = "SkyGuardian",
        name = "Sky Guardian",
        roleVi = "Tank / Đại Kiếm Thánh Quang",
        roleEn = "Tank / Solar Greatsword",
        bonusVi = "+25% HP, +20% DEF",
        bonusEn = "+25% HP, +20% DEF",
        descVi = "Vệ Thần Bầu Trời khoác giáp thánh quang, vung đại kiếm chém sóng kiếm vàng và bật khiên Aegis bất hoại che chở đồng đội.",
        descEn = "Solar-armored vanguard wielding a radiant greatsword, golden shockwaves, and unbreakable Aegis shields.",
        accent = Color3.fromRGB(246, 198, 86),
        badgeVi = "TANK • ĐẠI KIẾM",
        badgeEn = "TANK • GREATSWORD",
    },
    {
        id = "ThunderStriker",
        name = "Thunder Striker",
        roleVi = "Sát Thủ Lôi Đình / Song Đao",
        roleEn = "Lightning Assassin / Twinblades",
        bonusVi = "+10% ATK, Tốc Chạy 22",
        bonusEn = "+10% ATK, 22 WalkSpeed",
        descVi = "Thích khách tốc độ chớp giật lướt xuyên chiến trường, liên hoàn song đao sấm sét dồn sát thương chí mạng cực nhanh.",
        descEn = "Hyper-mobile storm assassin dashing across battlefields to unleash rapid twinblade lightning crits.",
        accent = Color3.fromRGB(88, 214, 255),
        badgeVi = "SÁT THỦ • SONG ĐAO",
        badgeEn = "ASSASSIN • TWINBLADES",
    },
    {
        id = "ArcaneMage",
        name = "Arcane Mage",
        roleVi = "Pháp Sư Tinh Cầu / Tầm Xa AoE",
        roleEn = "Astral Battlemage / Ranged AoE",
        bonusVi = "+15% ATK, Phép Tầm Xa",
        bonusEn = "+15% ATK, Ranged Spellcraft",
        descVi = "Pháp sư điều khiển Tinh Cầu Aether phóng chùm tia năng lượng tầm xa và triệu hồi bão thiên thạch càn quét diện rộng.",
        descEn = "Master of Aether orbs firing long-range arcane beams and summoning devastating astral meteor storms.",
        accent = Color3.fromRGB(194, 128, 255),
        badgeVi = "PHÁP SƯ • TẦM XA AOE",
        badgeEn = "MAGE • RANGED AOE",
    },
}

local function fireSelectOriginClass(classId)
    local sharedRemotes = Shared:FindFirstChild("Remotes")
    local uiCmd = sharedRemotes and sharedRemotes:FindFirstChild("UICommand")
    if uiCmd and uiCmd:IsA("RemoteEvent") then
        uiCmd:FireServer("SelectClass", { classId = classId })
        return
    end
    local legacyRemotes = ReplicatedStorage:FindFirstChild("Remotes")
    local legacyCmd = legacyRemotes and legacyRemotes:FindFirstChild("UICommand")
    if legacyCmd and legacyCmd:IsA("RemoteEvent") then
        legacyCmd:FireServer("SelectClass", { classId = classId })
        return
    end
    local chooseApp = legacyRemotes and legacyRemotes:FindFirstChild("ChooseAppearance")
    if chooseApp and chooseApp:IsA("RemoteEvent") then
        chooseApp:FireServer({ ClassId = classId, Gender = "Male" })
    end
end

local function createOnboardingClassModal(parent)
    local backdrop = UIFactory.Create("TextButton", parent, {
        Name = "OnboardingClassModal",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(6, 10, 20),
        BackgroundTransparency = 0.18,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Modal = true,
        Visible = false,
        ZIndex = 38,
    })

    local card = UIFactory.Create("Frame", backdrop, {
        Name = "OriginClassCard",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(920, 468),
        BackgroundColor3 = Theme.Colors.BG_850,
        BackgroundTransparency = 0.03,
        BorderSizePixel = 0,
        ZIndex = 39,
    })
    local cardScale = UIFactory.Create("UIScale", card, { Scale = 1 })
    UIFactory.Corner(card, Theme.Radius.Large)
    UIFactory.Stroke(card, Theme.Colors.ACCENT_GOLD, 1.8, 0.12)
    UIFactory.Gradient(card, Color3.fromRGB(22, 34, 62), Color3.fromRGB(11, 17, 32), 90)

    local kickerLbl = UIFactory.Create("TextLabel", card, {
        Name = "Kicker",
        Position = UDim2.fromOffset(24, 14),
        Size = UDim2.new(1, -48, 0, 18),
        BackgroundTransparency = 1,
        Text = I18n.Pick("SKYBREAK: FRAGMENTS OF THE CORE • KHỞI ĐẦU HÀNH TRÌNH", "SKYBREAK: FRAGMENTS OF THE CORE • ORIGIN AWAKENING"),
        Font = Theme.Fonts.Bold,
        TextSize = 11,
        TextColor3 = Theme.Colors.ACCENT_SAPPHIRE,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 40,
    })

    local titleLbl = UIFactory.Create("TextLabel", card, {
        Name = "Title",
        Position = UDim2.fromOffset(24, 34),
        Size = UDim2.new(1, -48, 0, 30),
        BackgroundTransparency = 1,
        Text = I18n.Pick("CHỌN HỆ KHỞI ĐẦU", "CHOOSE YOUR ORIGIN CLASS"),
        Font = Theme.Fonts.Title,
        TextSize = 22,
        TextColor3 = Theme.Colors.ACCENT_GOLD,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 40,
    })
    UIFactory.TextSizeConstraint(titleLbl, 14, 24)
    titleLbl.TextScaled = true

    local subLbl = UIFactory.Create("TextLabel", card, {
        Name = "Subtitle",
        Position = UDim2.fromOffset(28, 66),
        Size = UDim2.new(1, -56, 0, 22),
        BackgroundTransparency = 1,
        Text = I18n.Pick(
            "Chọn phong cách chiến đấu khởi đầu của bạn (có thể đổi bất cứ lúc nào trong bảng Kỹ Năng [K]).",
            "Pick your starting combat path (you can freely switch anytime in Skills [K])."
        ),
        Font = Theme.Fonts.Body,
        TextSize = 12,
        TextWrapped = true,
        TextColor3 = Theme.Colors.TEXT_SECONDARY,
        TextXAlignment = Enum.TextXAlignment.Center,
        ZIndex = 40,
    })

    local row = UIFactory.Create("Frame", card, {
        Name = "ClassCardsRow",
        Position = UDim2.fromOffset(26, 98),
        Size = UDim2.new(1, -52, 0, 346),
        BackgroundTransparency = 1,
        ZIndex = 40,
    })
    local rowLayout = UIFactory.ListLayout(row, Enum.FillDirection.Horizontal, 16, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)

    local cardRefs = {}
    for _, cls in ipairs(ORIGIN_CLASSES) do
        local colCard = UIFactory.Create("Frame", row, {
            Name = "Class_" .. cls.id,
            Size = UDim2.fromOffset(278, 332),
            BackgroundColor3 = Theme.Colors.BG_800,
            BackgroundTransparency = 0.06,
            BorderSizePixel = 0,
            ZIndex = 41,
        })
        UIFactory.Corner(colCard, Theme.Radius.Medium)
        UIFactory.Stroke(colCard, cls.accent, 1.5, 0.18)
        UIFactory.Gradient(colCard, Color3.fromRGB(26, 38, 68), Color3.fromRGB(14, 20, 38), 90)

        local topBadge = UIFactory.Create("Frame", colCard, {
            Position = UDim2.fromOffset(14, 10),
            Size = UDim2.new(1, -28, 0, 22),
            BackgroundColor3 = cls.accent,
            BackgroundTransparency = 0.84,
            BorderSizePixel = 0,
            ZIndex = 42,
        })
        UIFactory.Corner(topBadge, Theme.Radius.Pill)
        UIFactory.Stroke(topBadge, cls.accent, 1, 0.35)
        local badgeLbl = UIFactory.Create("TextLabel", topBadge, {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = I18n.Pick(cls.badgeVi, cls.badgeEn),
            Font = Theme.Fonts.Bold,
            TextSize = 10,
            TextColor3 = cls.accent,
            ZIndex = 43,
        })

        local nameLbl = UIFactory.Create("TextLabel", colCard, {
            Position = UDim2.fromOffset(14, 38),
            Size = UDim2.new(1, -28, 0, 24),
            BackgroundTransparency = 1,
            Text = cls.name,
            Font = Theme.Fonts.Title,
            TextSize = 20,
            TextColor3 = Theme.Colors.TEXT_PRIMARY,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 42,
        })

        local roleLbl = UIFactory.Create("TextLabel", colCard, {
            Position = UDim2.fromOffset(14, 64),
            Size = UDim2.new(1, -28, 0, 18),
            BackgroundTransparency = 1,
            Text = I18n.Pick(cls.roleVi, cls.roleEn),
            Font = Theme.Fonts.SemiBold,
            TextSize = 12,
            TextColor3 = cls.accent,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 42,
        })

        local statBox = UIFactory.Create("Frame", colCard, {
            Position = UDim2.fromOffset(14, 88),
            Size = UDim2.new(1, -28, 0, 30),
            BackgroundColor3 = Color3.fromRGB(12, 19, 36),
            BackgroundTransparency = 0.15,
            BorderSizePixel = 0,
            ZIndex = 42,
        })
        UIFactory.Corner(statBox, Theme.Radius.Small)
        UIFactory.Stroke(statBox, cls.accent, 1, 0.55)
        local bonusLbl = UIFactory.Create("TextLabel", statBox, {
            Position = UDim2.fromOffset(10, 0),
            Size = UDim2.new(1, -20, 1, 0),
            BackgroundTransparency = 1,
            Text = "★  " .. I18n.Pick(cls.bonusVi, cls.bonusEn),
            Font = Theme.Fonts.Bold,
            TextSize = 11,
            TextColor3 = Theme.Colors.ACCENT_GOLD,
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 43,
        })

        local descLbl = UIFactory.Create("TextLabel", colCard, {
            Position = UDim2.fromOffset(14, 126),
            Size = UDim2.new(1, -28, 1, -184),
            BackgroundTransparency = 1,
            Text = I18n.Pick(cls.descVi, cls.descEn),
            Font = Theme.Fonts.Body,
            TextSize = 11,
            TextColor3 = Theme.Colors.TEXT_SECONDARY,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            ZIndex = 42,
        })

        local chooseBtn = UIFactory.Create("TextButton", colCard, {
            Name = "Choose_" .. cls.id,
            Position = UDim2.new(0, 14, 1, -48),
            Size = UDim2.new(1, -28, 0, 36),
            BackgroundColor3 = cls.accent,
            BackgroundTransparency = 0.12,
            BorderSizePixel = 0,
            Text = I18n.Pick("KHỞI ĐẦU VỚI ", "START AS ") .. string.upper(cls.name),
            Font = Theme.Fonts.Bold,
            TextSize = 12,
            TextColor3 = Color3.fromRGB(10, 16, 28),
            ZIndex = 43,
        })
        UIFactory.Corner(chooseBtn, Theme.Radius.Small)
        UIFactory.Stroke(chooseBtn, Color3.fromRGB(255, 255, 255), 1, 0.55)

        chooseBtn.Activated:Connect(function()
            backdrop.Visible = false
            Store.Session.onboardingModalVisible = false
            Store.MarkClassChosen(cls.id)
            fireSelectOriginClass(cls.id)
            Store.ShowToast(
                I18n.Pick(
                    "Chào mừng đến Sky Hub! Đi theo tia sáng vàng gặp Chỉ Huy Lyra [E] để nhận Nhiệm Vụ đầu tiên!",
                    "Welcome to Sky Hub! Follow the golden beam to Commander Lyra [E] for your first Quest!"
                ),
                "success",
                6.0
            )
        end)

        table.insert(cardRefs, {
            Cls = cls,
            Card = colCard,
            NameLbl = nameLbl,
            BadgeLbl = badgeLbl,
            RoleLbl = roleLbl,
            BonusLbl = bonusLbl,
            DescLbl = descLbl,
            ChooseBtn = chooseBtn,
            StatBox = statBox,
        })
    end

    local function applyModalLayoutAndLocale(uiScale)
        kickerLbl.Text = I18n.Pick("SKYBREAK: FRAGMENTS OF THE CORE • KHỞI ĐẦU HÀNH TRÌNH", "SKYBREAK: FRAGMENTS OF THE CORE • ORIGIN AWAKENING")
        titleLbl.Text = I18n.Pick("CHỌN HỆ KHỞI ĐẦU", "CHOOSE YOUR ORIGIN CLASS")
        subLbl.Text = I18n.Pick(
            "Chọn phong cách chiến đấu khởi đầu của bạn (có thể đổi bất cứ lúc nào trong bảng Kỹ Năng [K]).",
            "Pick your starting combat path (you can freely switch anytime in Skills [K])."
        )

        local cam = workspace.CurrentCamera
        local vp = (parent and parent:IsA("GuiBase2d") and parent.AbsoluteSize.X > 0 and parent.AbsoluteSize)
            or (cam and cam.ViewportSize)
            or Vector2.new(1280, 720)
        local isPortraitModal = vp.X < (vp.Y * 0.92)

        if isPortraitModal then
            card.Size = UDim2.fromOffset(420, 724)
            row.Position = UDim2.fromOffset(18, 96)
            row.Size = UDim2.new(1, -36, 0, 612)
            rowLayout.FillDirection = Enum.FillDirection.Vertical
            rowLayout.Padding = UDim.new(0, 10)
            for _, cr in ipairs(cardRefs) do
                cr.Card.Size = UDim2.new(1, 0, 0, 196)
                cr.NameLbl.TextSize = 17
                cr.DescLbl.Position = UDim2.fromOffset(14, 120)
                cr.DescLbl.Size = UDim2.new(1, -28, 0, 34)
                cr.ChooseBtn.Position = UDim2.new(0, 14, 1, -38)
                cr.ChooseBtn.Size = UDim2.new(1, -28, 0, 30)
            end
            local fit = math.min((vp.X - 16) / 420, (vp.Y - 16) / 724, 1.0)
            cardScale.Scale = math.clamp(fit, 0.45, 1.0)
        else
            card.Size = UDim2.fromOffset(920, 468)
            row.Position = UDim2.fromOffset(26, 98)
            row.Size = UDim2.new(1, -52, 0, 346)
            rowLayout.FillDirection = Enum.FillDirection.Horizontal
            rowLayout.Padding = UDim.new(0, 16)
            for _, cr in ipairs(cardRefs) do
                cr.Card.Size = UDim2.fromOffset(278, 332)
                cr.NameLbl.TextSize = 20
                cr.DescLbl.Position = UDim2.fromOffset(14, 126)
                cr.DescLbl.Size = UDim2.new(1, -28, 1, -184)
                cr.ChooseBtn.Position = UDim2.new(0, 14, 1, -48)
                cr.ChooseBtn.Size = UDim2.new(1, -28, 0, 36)
            end
            local fit = math.min((vp.X - 20) / 920, (vp.Y - 16) / 468, tonumber(uiScale) or 1.05)
            cardScale.Scale = math.clamp(fit, 0.45, 1.05)
        end

        for _, cr in ipairs(cardRefs) do
            cr.BadgeLbl.Text = I18n.Pick(cr.Cls.badgeVi, cr.Cls.badgeEn)
            cr.RoleLbl.Text = I18n.Pick(cr.Cls.roleVi, cr.Cls.roleEn)
            cr.BonusLbl.Text = "★  " .. I18n.Pick(cr.Cls.bonusVi, cr.Cls.bonusEn)
            cr.DescLbl.Text = I18n.Pick(cr.Cls.descVi, cr.Cls.descEn)
            cr.ChooseBtn.Text = I18n.Pick("KHỞI ĐẦU VỚI ", "START AS ") .. string.upper(cr.Cls.name)
        end
    end

    return {
        Backdrop = backdrop,
        Scale = cardScale,
        Sync = function(snap, uiScale)
            applyModalLayoutAndLocale(uiScale)
            local shouldShow = (snap ~= nil)
                and (not snap.isDemoMode)
                and (snap.player ~= nil)
                and (tonumber(snap.player.level) == 1)
                and (snap.player.classChosen == false)
                and (not Store.Session.localClassChosen)
            backdrop.Visible = shouldShow
            Store.Session.onboardingModalVisible = shouldShow
        end,
    }
end

local SCREEN_MODULES = {
    [UIState.Screens.MainMenu] = MainMenu,
    [UIState.Screens.HUD] = HUD,
    [UIState.Screens.Inventory] = Inventory,
    [UIState.Screens.Skills] = Skills,
    [UIState.Screens.Fruits] = Fruits,
    [UIState.Screens.NPCShop] = NPCShop,
    [UIState.Screens.WorldMap] = WorldMap,
    [UIState.Screens.QuestJournal] = QuestJournal,
    [UIState.Screens.Forge] = Forge,
    [UIState.Screens.Raid] = Raid,
    [UIState.Screens.SocialRewards] = SocialRewards,
    [UIState.Screens.Settings] = Settings,
}

for id, mod in pairs(SCREEN_MODULES) do
    ScreenRouter.RegisterScreen(id, mod)
end

function App.GetResponsiveState()
    local gui = App.ScreenGui
    local absSize = (gui and gui.AbsoluteSize.X > 0) and gui.AbsoluteSize or Vector2.new(1366, 768)
    local view = Store.GetView()
    local s = view.settings or {}
    return Responsive.GetState(absSize, s.layoutMode or "Auto", s.textScale or 1.0)
end

function App.RebuildActiveScreen(forceHUDRebuild)
    if not App.ScreenGui then
        return
    end
    local resp = App.GetResponsiveState()
    local activeRoute = ScreenRouter.CurrentScreen
    local prevRoute = App.LastRenderedRoute
    local routeChanged = (activeRoute ~= prevRoute)
    App.LastRenderedRoute = activeRoute

    local bgTint = App.Layers.BackgroundTint
    if bgTint then
        if activeRoute == UIState.Screens.HUD then
            bgTint.BackgroundTransparency = 1
        elseif activeRoute == UIState.Screens.MainMenu then
            -- #93: Semi-transparent framing so live 3D Character & Sky Hub Vista camera shines through
            bgTint.BackgroundTransparency = 0.72
        else
            bgTint.BackgroundTransparency = 0.08
        end
    end

    local blur = Lighting:FindFirstChild("SkybreakMenuBlur")
        or UIFactory.Create("BlurEffect", Lighting, { Name = "SkybreakMenuBlur", Size = 0 })
    if activeRoute == UIState.Screens.HUD or activeRoute == UIState.Screens.MainMenu then
        blur.Size = 0
    else
        blur.Size = 8
    end

    local hudCanvas = App.Layers.HUDCanvas
    local menuCanvas = App.Layers.MenuCanvas
    if hudCanvas and menuCanvas then
        hudCanvas.Size = resp.CanvasSize
        menuCanvas.Size = resp.CanvasSize
        if App.Layers.HUDScale then
            App.Layers.HUDScale.Scale = resp.UIScale
        end
        if App.Layers.MenuScale then
            App.Layers.MenuScale.Scale = resp.UIScale
        end
    end
    if App.OnboardingModal then
        App.OnboardingModal.Sync(Store.GetSnapshot(), resp.UIScale)
    end

    -- Clear previous menu screen children (cleanup active screen connections/orbits on in-place rebuilds)
    if menuCanvas then
        local hadMenuChildren = false
        for _, child in ipairs(menuCanvas:GetChildren()) do
            if child:IsA("GuiObject") then
                hadMenuChildren = true
                break
            end
        end
        if hadMenuChildren and prevRoute and prevRoute ~= UIState.Screens.HUD then
            local prevMod = SCREEN_MODULES[prevRoute]
            if prevMod and type(prevMod.Cleanup) == "function" then
                pcall(prevMod.Cleanup)
            end
            Animations.CleanupScope("Screen_" .. tostring(prevRoute))
        end
        for _, child in ipairs(menuCanvas:GetChildren()) do
            if child:IsA("GuiObject") then
                child:Destroy()
            end
        end
    end

    -- Keep HUD persistent in hudCanvas so closing any menu back to HUD is 0ms instant
    if hudCanvas then
        local hasHUD = false
        for _, child in ipairs(hudCanvas:GetChildren()) do
            if child:IsA("GuiObject") then
                if forceHUDRebuild then
                    if type(HUD.Cleanup) == "function" then
                        pcall(HUD.Cleanup)
                    end
                    child:Destroy()
                else
                    hasHUD = true
                end
            end
        end
        if not hasHUD then
            HUD.Build(hudCanvas, resp)
        end
    end

    if activeRoute == UIState.Screens.HUD then
        App.Layers.HUDLayer.Visible = true
        App.Layers.MenuLayer.Visible = false
        HUD.Update(Store.GetSnapshot(), Store.GetView())
    else
        App.Layers.HUDLayer.Visible = false
        App.Layers.MenuLayer.Visible = true
        local mod = SCREEN_MODULES[activeRoute] or MainMenu
        local builtFrame = mod.Build(menuCanvas, resp)
        if activeRoute == UIState.Screens.MainMenu then
            local closeBtn = UIFactory.Create("TextButton", menuCanvas, {
                Name = "FloatingResumeBtn",
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -16, 0, 12),
                Size = UDim2.fromOffset(148, 34),
                BackgroundColor3 = Theme.Colors.BG_800,
                BackgroundTransparency = 0.08,
                BorderSizePixel = 0,
                Text = "X  " .. I18n.T("nav.resume"),
                Font = Theme.Fonts.Bold,
                TextSize = 12,
                TextColor3 = Theme.Colors.ACCENT_GOLD,
                ZIndex = 40,
            })
            UIFactory.Corner(closeBtn, Theme.Radius.Small)
            UIFactory.Stroke(closeBtn, Theme.Colors.ACCENT_GOLD, 1.4, 0.15)
            closeBtn.Activated:Connect(function()
                ScreenRouter.CloseAllToHUD()
            end)
        end
        if routeChanged and builtFrame then
            PanelMotion.Open(App.Layers.MenuLayer)
            Animations.FadeInPanel(builtFrame, builtFrame.Position, Theme.Motion.Open, "Screen_" .. tostring(activeRoute))
        end
    end
end

function App.Init(onAction, onAttack)
    HUDController.SetCombatCallbacks(onAction, onAttack)
    if App.Initialized and App.ScreenGui and App.ScreenGui.Parent then
        return App
    end
    App.Initialized = true

    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    -- Prevent duplicate ScreenGuis on respawn or reload (Section 15 Rule 3)
    for _, existingName in ipairs({ "SkybreakUI", "SKYBREAK", "SkybreakPremiumUI" }) do
        local old = playerGui:FindFirstChild(existingName)
        if old then
            old:Destroy()
        end
    end

    local gui = UIFactory.Create("ScreenGui", playerGui, {
        Name = "SkybreakUI",
        ResetOnSpawn = false,
        DisplayOrder = 25,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
    })
    App.ScreenGui = gui

    -- 5 Canonical Layers (Section 05)
    local bgLayer = UIFactory.Create("Frame", gui, {
        Name = "BackgroundLayer",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 1,
    })
    local bgTint = UIFactory.Create("Frame", bgLayer, {
        Name = "Backdrop",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Theme.Colors.BG_900,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    })
    UIFactory.Gradient(bgTint, Color3.fromRGB(16, 32, 56), Theme.Colors.BG_900, 70)

    local hudLayer = UIFactory.Create("Frame", gui, {
        Name = "HUDLayer",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 5,
    })
    local hudCanvas = UIFactory.Create("Frame", hudLayer, {
        Name = "Canvas",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(1366, 768),
        BackgroundTransparency = 1,
    })
    local hudScale = UIFactory.Create("UIScale", hudCanvas, { Scale = 1 })

    -- Use Frame instead of CanvasGroup so 3D ViewportFrames inside menus render directly without offscreen texture compositing lag
    local menuLayer = UIFactory.Create("Frame", gui, {
        Name = "MenuLayer",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Visible = true,
        ZIndex = 10,
    })
    local menuCanvas = UIFactory.Create("Frame", menuLayer, {
        Name = "Canvas",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(1366, 768),
        BackgroundTransparency = 1,
    })
    local menuScale = UIFactory.Create("UIScale", menuCanvas, { Scale = 1 })

    local modalLayer = UIFactory.Create("Frame", gui, {
        Name = "ModalLayer",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 30,
    })

    local notificationLayer = UIFactory.Create("Frame", gui, {
        Name = "NotificationLayer",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 50,
    })

    local _, dialogueApi = Dialogue.CreateOverlay(modalLayer)
    local _, modalApi = Modal.Create(modalLayer, { name = "ConfirmModal", visible = false })
    local onboardingModal = createOnboardingClassModal(modalLayer)
    local _, toastApi = Toast.Create(notificationLayer, { name = "Toast" })
    LootFeed.Init(notificationLayer)

    App.Layers = {
        BackgroundLayer = bgLayer,
        BackgroundTint = bgTint,
        HUDLayer = hudLayer,
        HUDCanvas = hudCanvas,
        HUDScale = hudScale,
        MenuLayer = menuLayer,
        MenuCanvas = menuCanvas,
        MenuScale = menuScale,
        ModalLayer = modalLayer,
        NotificationLayer = notificationLayer,
    }
    App.DialogueApi = dialogueApi
    App.ModalApi = modalApi
    App.OnboardingModal = onboardingModal
    App.ToastApi = toastApi

    Settings.OnLowFXChanged = function(val)
        App.LowFX = val
    end

    if player and player:GetAttribute("LowFXMode") == true and type(Settings.ApplyLowFXWorld) == "function" then
        task.defer(Settings.ApplyLowFXWorld, true)
    end

    -- #94: Immediate UI refresh on bilingual Language switch
    I18n.OnChanged(function()
        App.RebuildActiveScreen(true)
        if App.DialogueApi then
            App.DialogueApi:Update(Store.GetView().dialogue)
        end
    end)

    ScreenRouter.OnRouteChanged = function(newRoute)
        App.Page = (newRoute == UIState.Screens.MainMenu and "Menu")
            or (newRoute == UIState.Screens.WorldMap and "Map")
            or (newRoute == UIState.Screens.QuestJournal and "Quests")
            or newRoute
        App.Current = App.Page
        App.RebuildActiveScreen()
    end

    Store.SubscribeSnapshot(function(snap)
        if App.OnboardingModal then
            local respNow = App.GetResponsiveState()
            App.OnboardingModal.Sync(snap, respNow.UIScale)
        end
        local activeRoute = ScreenRouter.CurrentScreen
        if activeRoute == UIState.Screens.HUD then
            HUD.Update(snap, Store.GetView())
        elseif activeRoute == UIState.Screens.MainMenu then
            MainMenu.Update(snap)
        elseif activeRoute == UIState.Screens.Inventory then
            Inventory.Update(snap)
        elseif activeRoute == UIState.Screens.Skills then
            Skills.Update(snap)
        elseif activeRoute == UIState.Screens.Fruits then
            Fruits.Update(snap)
        elseif activeRoute == UIState.Screens.NPCShop and type(NPCShop.Update) == "function" then
            NPCShop.Update(snap)
        elseif activeRoute == UIState.Screens.Forge and type(Forge.Update) == "function" then
            Forge.Update(snap)
        elseif activeRoute == UIState.Screens.WorldMap and type(WorldMap.Update) == "function" then
            WorldMap.Update(snap)
        elseif activeRoute == UIState.Screens.QuestJournal and type(QuestJournal.Update) == "function" then
            QuestJournal.Update(snap)
        elseif activeRoute == UIState.Screens.Raid and type(Raid.Update) == "function" then
            Raid.Update(snap)
        elseif activeRoute == UIState.Screens.SocialRewards and type(SocialRewards.Update) == "function" then
            SocialRewards.Update(snap)
        elseif activeRoute == UIState.Screens.Settings and type(Settings.Update) == "function" then
            Settings.Update(snap)
        end
    end)

    Store.SubscribeView(function(view)
        if App.ModalApi then
            App.ModalApi:Update(view.modal)
        end
        if App.DialogueApi then
            App.DialogueApi:Update(view.dialogue)
        end
        if ScreenRouter.CurrentScreen == UIState.Screens.HUD then
            HUD.Update(Store.GetSnapshot(), view)
        elseif ScreenRouter.CurrentScreen == UIState.Screens.Forge then
            Forge.Update()
        elseif ScreenRouter.CurrentScreen == UIState.Screens.Settings then
            App.RebuildActiveScreen()
        end
    end)

    Store.SubscribeToast(function(toastPayload)
        if App.ToastApi then
            App.ToastApi:Show(toastPayload.message, toastPayload.kind, toastPayload.duration)
        end
    end)

    Store.SubscribeLoot(function(lootEntry)
        LootFeed.Push(lootEntry)
    end)

    -- Viewport resize listener (debounced)
    local resizePending = false
    table.insert(App.Connections, gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if resizePending then
            return
        end
        resizePending = true
        task.delay(0.15, function()
            resizePending = false
            App.RebuildActiveScreen(true)
        end)
    end))

    -- External deterministic screen request bridge (supports all 11 screens including Dialogue)
    table.insert(App.Connections, gui:GetAttributeChangedSignal("RequestScreen"):Connect(function()
        local req = gui:GetAttribute("RequestScreen")
        if type(req) == "string" and #req > 0 then
            gui:SetAttribute("RequestScreen", "")
            if req == "HUD" or req == "Close" then
                QuestController.CloseDialogue()
                ScreenRouter.CloseAllToHUD()
            elseif req == "Dialogue" then
                ScreenRouter.CloseAllToHUD()
                QuestController.OpenDialogue(
                    I18n.Pick("LYRA • CHỈ HUY SKYBORN", "LYRA • SKYBORN COMMANDER"),
                    I18n.Pick(
                        "Chào mừng Chiến Binh Bầu Trời! Hãy trang bị Thần Khí, thức tỉnh Lõi Aether và tiến công Tháp Phán Quyết.",
                        "Welcome, Skyborn! Equip your Celestial Blade, awaken your Aether Core, and ascend the Aureon Spire."
                    ),
                    I18n.Pick("Người Giữ Cổ Ngữ • Sky Hub", "Lorekeeper of the Core • Sky Hub")
                )
            elseif req:sub(1, 8) == "NPCShop:" then
                local vMode = req:sub(9)
                QuestController.CloseDialogue()
                if #vMode > 0 then
                    Store.SetView({ activeVendorMode = vMode })
                end
                ScreenRouter.Navigate(UIState.Screens.NPCShop, { forceRebuild = true })
            elseif req:sub(1, 7) == "Fruits:" then
                local fMode = req:sub(8)
                QuestController.CloseDialogue()
                Store.SetView({ fruitsMode = (#fMode > 0 and fMode or "Vault") })
                ScreenRouter.Navigate(UIState.Screens.Fruits, { forceRebuild = true })
            else
                QuestController.CloseDialogue()
                if req == "Fruits" then
                    Store.SetView({ fruitsMode = "Vault" })
                end
                ScreenRouter.Navigate(req, req == "Fruits" and { forceRebuild = true } or nil)
            end
        end
    end))

    -- Keyboard & Gamepad Navigation Shortcuts (Escape, G, B, L, Space)
    -- #91: [L] universally opens/toggles QuestJournal; [J] is strictly Busoshoku Haki!
    -- World stations (NPCShop, Forge, Raid) open contextually via NPC [E] interaction.
    table.insert(App.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if UserInputService:GetFocusedTextBox() then
            return
        end
        local v = Store.GetView()
        local modalOpen = (v.modal and v.modal.visible) or (v.dialogue and v.dialogue.visible)
        if input.KeyCode == Enum.KeyCode.Escape then
            ScreenRouter.Back()
            return
        elseif input.KeyCode == Enum.KeyCode.ButtonB then
            if modalOpen or ScreenRouter.CurrentScreen ~= UIState.Screens.HUD then
                ScreenRouter.Back()
            end
            return
        end
        if modalOpen then
            if not processed and input.KeyCode == Enum.KeyCode.Space and v.dialogue and v.dialogue.visible then
                local cmd = v.dialogue.actionCommand
                QuestController.CloseDialogue()
                if type(Dialogue.DispatchActionCommand) == "function" then
                    Dialogue.DispatchActionCommand(cmd)
                elseif type(cmd) == "string" and cmd:sub(1, 11) == "OpenScreen:" then
                    ScreenRouter.Navigate(cmd:sub(12))
                end
            end
            return
        end
        if input.KeyCode == Enum.KeyCode.G then
            if ScreenRouter.CurrentScreen == UIState.Screens.Fruits and v.fruitsMode == "Gacha" then
                Store.SetView({ fruitsMode = "Vault" })
                ScreenRouter.Navigate(UIState.Screens.Fruits, { forceRebuild = true, replace = true })
            else
                Store.SetView({ fruitsMode = "Vault" })
                ScreenRouter.ToggleScreen(UIState.Screens.Fruits)
            end
            return
        elseif input.KeyCode == Enum.KeyCode.B then
            ScreenRouter.ToggleScreen(UIState.Screens.SocialRewards)
            return
        elseif input.KeyCode == Enum.KeyCode.L then
            ScreenRouter.ToggleScreen(UIState.Screens.QuestJournal)
            return
        end
    end))

    -- Periodic cooldown, buff countdown & proximity boss-bar ticker for HUD
    task.spawn(function()
        while gui and gui.Parent do
            task.wait(0.12)
            if ScreenRouter.CurrentScreen == UIState.Screens.HUD then
                HUD.Update(Store.GetSnapshot(), Store.GetView())
            end
        end
    end)

    App.RebuildActiveScreen(true)
    return App
end

-- Backward-compatible methods used by ClientBootstrap.client.lua
function App.Show(page)
    if os.clock() - (ScreenRouter.LastNavigateClock or 0) < 0.06 then
        return
    end
    if page == "Fruits" then
        Store.SetView({ fruitsMode = "Vault" })
    end
    ScreenRouter.Navigate(page)
end

function App.Toggle(page)
    if page == "Fruits" then
        Store.SetView({ fruitsMode = "Vault" })
    end
    return ScreenRouter.ToggleScreen(page)
end

function App.Build()
    App.RebuildActiveScreen()
end

function App.Render()
    local snap = Store.GetSnapshot()
    local activeRoute = ScreenRouter.CurrentScreen
    if activeRoute == UIState.Screens.HUD then
        HUD.Update(snap, Store.GetView())
    elseif activeRoute == UIState.Screens.MainMenu then
        MainMenu.Update(snap)
    elseif activeRoute == UIState.Screens.Inventory then
        Inventory.Update(snap)
    elseif activeRoute == UIState.Screens.Skills then
        Skills.Update(snap)
    elseif activeRoute == UIState.Screens.Fruits then
        Fruits.Update(snap)
    elseif activeRoute == UIState.Screens.NPCShop and type(NPCShop.Update) == "function" then
        NPCShop.Update(snap)
    elseif activeRoute == UIState.Screens.Forge and type(Forge.Update) == "function" then
        Forge.Update(snap)
    elseif activeRoute == UIState.Screens.WorldMap and type(WorldMap.Update) == "function" then
        WorldMap.Update(snap)
    elseif activeRoute == UIState.Screens.QuestJournal and type(QuestJournal.Update) == "function" then
        QuestJournal.Update(snap)
    elseif activeRoute == UIState.Screens.Raid and type(Raid.Update) == "function" then
        Raid.Update(snap)
    elseif activeRoute == UIState.Screens.SocialRewards and type(SocialRewards.Update) == "function" then
        SocialRewards.Update(snap)
    elseif activeRoute == UIState.Screens.Settings and type(Settings.Update) == "function" then
        Settings.Update(snap)
    end
end

function App.SetInteract(text)
    Store.SetView({ interactPrompt = text })
end

function App.SetLockTarget(targetName)
    Store.SetView({ lockTarget = targetName })
end

function App.Toast(message, kind)
    if type(message) == "string" and #message > 0 then
        Store.ShowToast(message, kind or "info", 2.8)
    end
end

function App.CyclePartySize()
    ScreenRouter.ToggleScreen(UIState.Screens.SocialRewards)
end

function App.BlocksCombat()
    return ScreenRouter.BlocksCombat()
end

function App.OpenDialogue(d)
    if type(d) == "table" then
        App.LastStructuredDialogueClock = os.clock()
        QuestController.OpenDialogue(
            d.speaker or d.Speaker,
            d.text or d.Text,
            d.role or d.Role,
            d.questId or d.QuestId,
            d.actionLabel or d.ActionLabel,
            d.actionCommand or d.ActionCommand,
            d.choices or d.Choices
        )
    end
end

function App.Message(message)
    if type(message) ~= "string" then
        return
    end
    if (os.clock() - (App.LastStructuredDialogueClock or 0)) < 0.08 then
        return
    end
    if string.sub(message, 1, 5) == "Lyra:" or string.sub(message, 1, 5) == "Kael:" or string.sub(message, 1, 7) == "Zioles:" then
        local isKael = string.sub(message, 1, 5) == "Kael:"
        local isZioles = string.sub(message, 1, 7) == "Zioles:"
        local speaker = isKael and "KAEL • CELESTIAL FORGE"
            or (isZioles and "HIỀN GIẢ AETHER • GACHA" or "LYRA • SKY HUB")
        local role = isKael and "Master Blacksmith"
            or (isZioles and "Aether Core Oracle" or "Lorekeeper of the Core")
        QuestController.OpenDialogue(speaker, message, role)
    else
        Store.ShowToast(message, "info", 3.5)
    end
end

function App.SetState(rawState)
    local previous = App.State
    App.State = rawState
    local player = Players.LocalPlayer
    local realmAttr = player and player:GetAttribute("CurrentRealm") or "GoldenSky"
    Store.SetServerSnapshot(rawState, realmAttr)

    if previous and type(rawState) == "table" and (previous.ClassId ~= rawState.ClassId or previous.Gender ~= rawState.Gender) then
        App.RebuildActiveScreen(true)
    end
end

return App
