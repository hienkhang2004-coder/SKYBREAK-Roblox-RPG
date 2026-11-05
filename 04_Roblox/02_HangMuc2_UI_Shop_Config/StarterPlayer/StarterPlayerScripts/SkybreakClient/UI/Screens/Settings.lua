-- SKYBREAK: Fragments of the Core — Screen 9: Bilingual Settings, Working Low FX Mode & Giftcode Redemption ([O])
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/Settings.lua
-- Covers Tasks #8, #10, #91, #94, #100, #123

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local UIState = require(Shared:WaitForChild("Types"):WaitForChild("UIState"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Store = require(script.Parent.Parent:WaitForChild("Store"))
local ScreenRouter = require(script.Parent.Parent:WaitForChild("ScreenRouter"))
local Animations = require(script.Parent.Parent:WaitForChild("Animations"))
local I18n = require(script.Parent.Parent:WaitForChild("I18n"))
local PremiumPanel = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumPanel"))
local PremiumButton = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumButton"))

local Settings = {
    Refs = {},
    OnLowFXChanged = nil,
    LowFXDescendantConn = nil,
    CachedOrigShadows = nil,
}

-- #100: Canonical Giftcode Rewards Catalog
local GIFTCODE_CATALOG = {
    SKYBREAK2026 = {
        RewardVi = "+25,000 Gold & Buff X2 EXP (15 Phút)",
        RewardEn = "+25,000 Gold & 2x EXP Boost (15m)",
        LootCategory = "Gift",
        GrantDoubleExpSec = 900,
    },
    AETHERV2 = {
        RewardVi = "+150 Tinh Thạch Aether (Core Shards)",
        RewardEn = "+150 Aether Core Shards",
        LootCategory = "Shards",
    },
    MYTHICFRUIT = {
        RewardVi = "+1 Trái Thần Thoại Lưu Kho & +1 Vé Quay 3D Zioles Miễn Phí",
        RewardEn = "+1 Stored Mythic Fruit & +1 Free Zioles 3D Fruit Voucher",
        LootCategory = "Gift",
    },
    FREESTAT = {
        RewardVi = "+1 Lượt Tẩy Toàn Bộ Điểm Chỉ Số Miễn Phí",
        RewardEn = "+1 Free Full Stat Refund Token",
        LootCategory = "Gift",
    },
}

local function applyFXScaleToInstance(inst, enabled)
    if inst:IsA("ParticleEmitter") then
        local orig = inst:GetAttribute("OrigRate")
        if orig == nil then
            orig = inst.Rate
            inst:SetAttribute("OrigRate", orig)
        end
        if enabled then
            inst.Rate = math.max(0, orig * 0.35)
        else
            inst.Rate = orig
        end
    elseif inst:IsA("Trail") then
        local origLifetime = inst:GetAttribute("OrigLifetime")
        if origLifetime == nil then
            origLifetime = tonumber(inst.Lifetime) or 0.25
            inst:SetAttribute("OrigLifetime", origLifetime)
        end
        if enabled then
            inst.Lifetime = math.max(0.04, origLifetime * 0.45)
        else
            inst.Lifetime = origLifetime
        end
    end
end

-- #123: Working Low FX Mode world-wide applier & exact 100% restorer
function Settings.ApplyLowFXWorld(enabled)
    local isLow = (enabled == true)
    local lp = Players.LocalPlayer
    if lp then
        lp:SetAttribute("LowFXMode", isLow)
    end
    workspace:SetAttribute("LowFXMode", isLow)

    if Settings.CachedOrigShadows == nil then
        Settings.CachedOrigShadows = Lighting.GlobalShadows
    end
    Lighting.GlobalShadows = (not isLow) and (Settings.CachedOrigShadows ~= false)

    for _, desc in ipairs(workspace:GetDescendants()) do
        if desc:IsA("ParticleEmitter") or desc:IsA("Trail") then
            pcall(applyFXScaleToInstance, desc, isLow)
        end
    end

    if Settings.LowFXDescendantConn then
        Settings.LowFXDescendantConn:Disconnect()
        Settings.LowFXDescendantConn = nil
    end
    if isLow then
        Settings.LowFXDescendantConn = workspace.DescendantAdded:Connect(function(desc)
            if desc:IsA("ParticleEmitter") or desc:IsA("Trail") then
                pcall(applyFXScaleToInstance, desc, true)
            end
        end)
    end

    if type(Settings.OnLowFXChanged) == "function" then
        pcall(Settings.OnLowFXChanged, isLow)
    end
end

-- #100: Redeem Giftcode handler
local function redeemGiftcode(rawInput, codeBox)
    local cleaned = string.upper((tostring(rawInput or ""):gsub("%s+", "")))
    if cleaned == "" then
        Store.ShowToast(
            I18n.Pick("Vui lòng nhập mã Giftcode trước khi nhấn Nhận Quà!", "Please enter a Giftcode before clicking Redeem!"),
            "warning",
            2.4
        )
        return
    end

    local snap = Store.GetSnapshot()
    Store.Session.redeemedCodes = Store.Session.redeemedCodes or {}
    local alreadyUsed = (snap and snap.redeemedCodes and snap.redeemedCodes[cleaned] == true)
        or (Store.Session.redeemedCodes[cleaned] == true)
    if alreadyUsed then
        Store.ShowToast(
            I18n.Pick("Mã [" .. cleaned .. "] đã được sử dụng trên tài khoản này!", "Code [" .. cleaned .. "] has already been redeemed!"),
            "warning",
            2.6
        )
        return
    end

    -- Forward single authoritative request to server when online
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes and snap and not snap.isDemoMode then
        if codeBox then
            codeBox.Text = ""
        end
        if remotes:FindFirstChild("UIRequest") then
            remotes.UIRequest:FireServer("RedeemCode", { code = cleaned })
            return
        elseif remotes:FindFirstChild("EquipmentRequest") then
            remotes.EquipmentRequest:FireServer({ action = "RedeemCode", code = cleaned })
            return
        end
    end

    -- Offline / Demo Mode local catalog fallback
    local rewardDef = GIFTCODE_CATALOG[cleaned]
    if not rewardDef then
        Store.ShowToast(
            I18n.Pick("Mã Giftcode [" .. cleaned .. "] không hợp lệ hoặc đã hết hạn!", "Invalid or expired Giftcode [" .. cleaned .. "]!"),
            "error",
            2.8
        )
        return
    end

    Store.Session.redeemedCodes[cleaned] = true
    if codeBox then
        codeBox.Text = ""
    end

    if rewardDef.GrantDoubleExpSec then
        local lp = Players.LocalPlayer
        if lp then
            local curSec = tonumber(lp:GetAttribute("DoubleExpSeconds")) or 0
            local newSec = curSec + rewardDef.GrantDoubleExpSec
            lp:SetAttribute("DoubleExpSeconds", newSec)
            Store.Session.doubleExpUntilClock = os.clock() + newSec
        end
    end

    local rewardText = I18n.GetLanguage() == "en" and rewardDef.RewardEn or rewardDef.RewardVi
    Store.ShowToast(
        I18n.Pick("NHẬN GIFTCODE [" .. cleaned .. "] THÀNH CÔNG: " .. rewardText, "REDEEMED [" .. cleaned .. "]: " .. rewardText),
        "success",
        3.5
    )
    Store.PushLoot({
        Category = rewardDef.LootCategory or "Gift",
        Title = rewardText,
        Subtitle = "GIFTCODE: " .. cleaned,
        Color = Theme.Colors.ACCENT_GOLD_BRIGHT,
    })
end

function Settings.Build(parent, responsiveState)
    Settings.Cleanup()
    local colors = Theme.Colors
    local snap = Store.GetSnapshot()
    local view = Store.GetView()
    local s = view.settings or {}
    local isPortrait = responsiveState and responsiveState.IsPortrait
    local lp = Players.LocalPlayer
    local isLowFX = (lp and lp:GetAttribute("LowFXMode") == true) or (s.lowFX == true) or (s.fxQuality == "Low")
    local curLang = I18n.GetLanguage()
    local function cloneCurrentSettings()
        return table.clone(Store.GetView().settings or {})
    end

    local root = UIFactory.Create("Frame", parent, {
        Name = "SettingsScreen",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
    })

    -- #10: Shared Top Header Bar with complete NavTabs
    local _, headerRefs = UIFactory.BuildScreenHeader(root, {
        ActiveScreen = UIState.Screens.Settings,
        Title = I18n.T("settings.title"),
        Snapshot = snap,
        OnNavigate = function(targetId)
            ScreenRouter.Navigate(targetId)
        end,
        OnClose = function()
            ScreenRouter.CloseAllToHUD()
        end,
    })

    -- Left Column: Bilingual Language (#94), Working Low FX (#123), Motion & Layout Profile
    local leftCard = PremiumPanel.Create(root, {
        name = "AccessibilityCard",
        title = I18n.Pick("NGÔN NGỮ, ĐỒ HỌA & GIAO DIỆN", "LANGUAGE, GRAPHICS & LAYOUT"),
        subtitle = I18n.Pick("Song ngữ Việt/Anh • Giảm hiệu ứng Low FX • Bố cục Mobile/PC", "Bilingual VI/EN • Real Low FX Mode • Responsive Layout"),
        position = UDim2.fromOffset(16, 74),
        size = isPortrait and UDim2.new(1, -32, 0.52, -46) or UDim2.new(0.5, -22, 1, -88),
    })

    local listLeft = UIFactory.Create("ScrollingFrame", leftCard, {
        Name = "List",
        Position = UDim2.fromOffset(16, 58),
        Size = UDim2.new(1, -32, 1, -70),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = colors.ACCENT_SAPPHIRE,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.fromOffset(0, 0),
    })
    UIFactory.ListLayout(listLeft, Enum.FillDirection.Vertical, 8)

    -- 1. #94: Bilingual Language Switcher (Tiếng Việt / English)
    local langBox = UIFactory.Create("Frame", listLeft, {
        Name = "LanguageSelectorBox",
        Size = UDim2.new(1, -4, 0, 72),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
        LayoutOrder = 1,
    })
    UIFactory.Corner(langBox, Theme.Radius.Medium)
    UIFactory.Stroke(langBox, colors.ACCENT_GOLD, 1.3, 0.22)

    UIFactory.Label(langBox, {
        Name = "Title",
        Text = I18n.Pick("NGÔN NGỮ HIỂN THỊ (LANGUAGE)  •  Đang chọn: TIẾNG VIỆT", "DISPLAY LANGUAGE  •  Active: ENGLISH"),
        Position = UDim2.fromOffset(14, 7),
        Size = UDim2.new(1, -28, 0, 20),
        TextSize = 12,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
    })

    local langRow = UIFactory.Create("Frame", langBox, {
        Name = "LangButtons",
        Position = UDim2.fromOffset(14, 32),
        Size = UDim2.new(1, -28, 0, 32),
        BackgroundTransparency = 1,
    })

    PremiumButton.Create(langRow, {
        name = "LangVI",
        label = "TIẾNG VIỆT (MẶC ĐỊNH)",
        variant = (curLang == "vi") and "gold" or "secondary",
        selected = (curLang == "vi"),
        position = UDim2.fromOffset(0, 0),
        size = UDim2.new(0.5, -5, 1, 0),
        textSize = 12,
        minTextSize = 10,
        onActivated = function()
            Store.SetView({ settings = { language = "vi" } })
            I18n.SetLanguage("vi")
            Store.ShowToast("Đã chuyển giao diện sang Tiếng Việt!", "success", 2.0)
        end,
    })

    PremiumButton.Create(langRow, {
        name = "LangEN",
        label = "ENGLISH",
        variant = (curLang == "en") and "gold" or "secondary",
        selected = (curLang == "en"),
        position = UDim2.new(0.5, 5, 0, 0),
        size = UDim2.new(0.5, -5, 1, 0),
        textSize = 12,
        minTextSize = 10,
        onActivated = function()
            Store.SetView({ settings = { language = "en" } })
            I18n.SetLanguage("en")
            Store.ShowToast("Switched UI language to English!", "success", 2.0)
        end,
    })

    local function createToggleRow(order, title, desc, isOn, onToggle)
        local row = UIFactory.Create("Frame", listLeft, {
            Name = "Toggle_" .. order,
            Size = UDim2.new(1, -4, 0, 62),
            BackgroundColor3 = colors.BG_900,
            BorderSizePixel = 0,
            LayoutOrder = order,
        })
        UIFactory.Corner(row, Theme.Radius.Medium)
        UIFactory.Stroke(row, isOn and colors.ACCENT_GOLD or colors.STROKE_STEEL, 1.2, 0.25)

        UIFactory.Label(row, {
            Name = "Title",
            Text = title,
            Position = UDim2.fromOffset(14, 8),
            Size = UDim2.new(1, -132, 0, 20),
            TextSize = 13,
            TextColor = colors.TEXT_PRIMARY,
            Bold = true,
            Truncate = Enum.TextTruncate.AtEnd,
        })

        UIFactory.Label(row, {
            Name = "Desc",
            Text = desc,
            Position = UDim2.fromOffset(14, 28),
            Size = UDim2.new(1, -132, 0, 28),
            TextSize = 11,
            TextColor = colors.TEXT_SECONDARY,
        })

        PremiumButton.Create(row, {
            name = "ToggleBtn",
            label = isOn and I18n.Pick("BẬT", "ON") or I18n.Pick("TẮT", "OFF"),
            variant = isOn and "gold" or "secondary",
            selected = isOn,
            position = UDim2.new(1, -108, 0.5, -17),
            size = UDim2.fromOffset(94, 34),
            textSize = 12,
            minTextSize = 10,
            onActivated = function()
                onToggle(not isOn)
            end,
        })
    end

    -- 2. #123: Dedicated Working Low FX Mode Toggle
    createToggleRow(
        2,
        I18n.Pick("Chế Độ Giảm Hiệu Ứng (Low FX Mode)", "Low FX Performance Mode"),
        I18n.Pick("Tắt bóng đổ GlobalShadows, giảm 65% hạt ParticleEmitter và rút ngắn vệt kiếm Trail để tăng FPS.", "Disables GlobalShadows, scales ParticleEmitters to 35% & shortens Trails for smooth FPS."),
        isLowFX,
        function(nextVal)
            Settings.ApplyLowFXWorld(nextVal)
            local nextSettings = cloneCurrentSettings()
            nextSettings.lowFX = nextVal
            nextSettings.fxQuality = nextVal and "Low" or "High"
            Store.SetView({ settings = nextSettings })
            Store.ShowToast(
                nextVal
                    and I18n.Pick("Đã BẬT Chế Độ Low FX (Tăng tốc FPS & Giảm 65% hạt hiệu ứng)!", "Enabled Low FX Mode (Shadows OFF & 35% Particle Rate)!")
                    or I18n.Pick("Đã TẮT Low FX Mode (Khôi phục 100% hiệu ứng ánh sáng & hạt)!", "Disabled Low FX Mode (Restored 100% Shadows & Particles)!"),
                "info",
                2.4
            )
        end
    )

    -- 3. FX Quality Tier Selector (Low / Medium / High)
    local fxQuality = isLowFX and "Low" or (s.fxQuality or "High")
    local fxBox = UIFactory.Create("Frame", listLeft, {
        Name = "FXQualityBox",
        Size = UDim2.new(1, -4, 0, 70),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
        LayoutOrder = 3,
    })
    UIFactory.Corner(fxBox, Theme.Radius.Medium)
    UIFactory.Stroke(fxBox, colors.STROKE_STEEL, 1, 0.35)

    UIFactory.Label(fxBox, {
        Name = "Title",
        Text = I18n.Pick("MỨC CHẤT LƯỢNG HIỆU ỨNG  •  Hiện tại: ", "FX QUALITY TIER  •  Current: ") .. string.upper(fxQuality),
        Position = UDim2.fromOffset(14, 7),
        Size = UDim2.new(1, -28, 0, 18),
        TextSize = 12,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
    })

    local fxRow = UIFactory.Create("Frame", fxBox, {
        Name = "FXButtons",
        Position = UDim2.fromOffset(14, 30),
        Size = UDim2.new(1, -28, 0, 32),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(fxRow, Enum.FillDirection.Horizontal, 8)

    for idx, tier in ipairs({ "Low", "Medium", "High" }) do
        PremiumButton.Create(fxRow, {
            name = "FX_" .. tier,
            label = string.upper(tier),
            variant = fxQuality == tier and "primary" or "secondary",
            selected = fxQuality == tier,
            size = UDim2.new(0.333, -6, 1, 0),
            textSize = 12,
            minTextSize = 10,
            layoutOrder = idx,
            onActivated = function()
                local lowOn = (tier == "Low")
                Settings.ApplyLowFXWorld(lowOn)
                local nextSettings = cloneCurrentSettings()
                nextSettings.fxQuality = tier
                nextSettings.lowFX = lowOn
                Store.SetView({ settings = nextSettings })
            end,
        })
    end

    -- 4. Show Celestial Minimap & Fruit Notifier Toggle (#92, #50)
    createToggleRow(
        4,
        I18n.Pick("Hiển Thị Minimap La Bàn & Radar Trái Tự Nhiên", "Show Celestial Minimap & Fruit Radar"),
        I18n.Pick("Bật la bàn radar 148x148 góc phải trên HUD kèm định vị Boss, NPC và Trái Ác Quỷ.", "Displays the 148x148 circular compass radar and Natural Fruit Notifier on HUD."),
        s.showMinimap ~= false,
        function(nextVal)
            local nextSettings = cloneCurrentSettings()
            nextSettings.showMinimap = nextVal
            Store.SetView({ settings = nextSettings })
        end
    )

    -- 5. Reduced Motion Toggle
    createToggleRow(
        5,
        I18n.Pick("Giảm Chuyển Động UI (Reduced Motion)", "Reduced UI Motion"),
        I18n.Pick("Tắt hiệu ứng nhịp thở và chuyển cảnh để thao tác tức thì.", "Switches UI transitions and ambient pulses to instant updates."),
        s.reducedMotion == true,
        function(nextVal)
            Animations.SetReducedMotion(nextVal)
            local nextSettings = cloneCurrentSettings()
            nextSettings.reducedMotion = nextVal
            Store.SetView({ settings = nextSettings })
        end
    )

    -- 6. Disable View Lock & Free Mouse Cursor Toggle (Prevents Shift-Lock / Action Cam / Lock-On Camera Pull)
    local lp = Players.LocalPlayer
    local camLockOff = (lp and lp:GetAttribute("DisableCameraLock") == true) or (s.disableCameraLock == true)
    createToggleRow(
        6,
        I18n.Pick("Tắt Khóa Góc Nhìn & Mở Khóa Chuột Tự Do", "Disable View Lock & Free Mouse Cursor"),
        I18n.Pick("Tắt hẳn khóa tâm chuột Action Cam / Shift-Lock & không kéo xoay góc nhìn camera (Phím mở khóa nhanh: LeftCtrl).", "Disables Action Cam / Shift-Lock cursor lock & stops Target Lock from rotating camera (Quick unlock: LeftCtrl)."),
        camLockOff,
        function(nextVal)
            if lp then
                lp:SetAttribute("DisableCameraLock", nextVal)
            end
            local tf = workspace:FindFirstChild("TempFX")
            local cmdEvt = tf and tf:FindFirstChild("SkybreakFlightCamCommand")
            if nextVal and cmdEvt and cmdEvt:IsA("BindableEvent") then
                cmdEvt:Fire("UnlockAllCamera")
            end
            local nextSettings = cloneCurrentSettings()
            nextSettings.disableCameraLock = nextVal
            Store.SetView({ settings = nextSettings })
            Store.ShowToast(
                nextVal
                    and I18n.Pick("Đã TẮT Khóa Góc Nhìn & Mở Khóa Chuột Tự Do!", "Disabled View Lock & Unlocked Free Mouse Cursor!")
                    or I18n.Pick("Đã cho phép dùng lại Action Cam [LeftAlt] & Lock-On [Tab]!", "Re-enabled Action Cam [LeftAlt] & Target Lock [Tab]!"),
                "info",
                2.4
            )
        end
    )

    -- 7. Layout Override Selector (Auto / Desktop / Mobile Touch Arc #125)
    local layoutBox = UIFactory.Create("Frame", listLeft, {
        Name = "LayoutModeBox",
        Size = UDim2.new(1, -4, 0, 70),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
        LayoutOrder = 7,
    })
    UIFactory.Corner(layoutBox, Theme.Radius.Medium)
    UIFactory.Stroke(layoutBox, colors.STROKE_STEEL, 1, 0.35)

    UIFactory.Label(layoutBox, {
        Name = "Title",
        Text = I18n.Pick("CHẾ ĐỘ BỐ CỤC (PC DESKTOP / VÒNG CUNG CẢM ỨNG MOBILE)", "RESPONSIVE LAYOUT (AUTO / DESKTOP / MOBILE ARC)"),
        Position = UDim2.fromOffset(14, 7),
        Size = UDim2.new(1, -28, 0, 18),
        TextSize = 12,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
    })

    local modeRow = UIFactory.Create("Frame", layoutBox, {
        Name = "ModeButtons",
        Position = UDim2.fromOffset(14, 30),
        Size = UDim2.new(1, -28, 0, 32),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(modeRow, Enum.FillDirection.Horizontal, 8)

    for idx, mode in ipairs({ "Auto", "Desktop", "Mobile" }) do
        local isSel = (s.layoutMode or "Auto") == mode
        PremiumButton.Create(modeRow, {
            name = "Mode_" .. mode,
            label = string.upper(mode),
            variant = isSel and "primary" or "secondary",
            selected = isSel,
            size = UDim2.new(0.333, -6, 1, 0),
            textSize = 12,
            minTextSize = 10,
            layoutOrder = idx,
            onActivated = function()
                local nextSettings = cloneCurrentSettings()
                nextSettings.layoutMode = mode
                Store.SetView({ settings = nextSettings })
            end,
        })
    end

    -- Right Column: Giftcode Redemption (#100), UI Scale, Audio & Updated Keybind Reference (#91)
    local rightCard = PremiumPanel.Create(root, {
        name = "AudioKeybindCard",
        variant = "gold",
        title = I18n.Pick("NHẬP GIFTCODE, TỈ LỆ UI & PHÍM TẮT", "GIFTCODE REDEMPTION, AUDIO & KEYBINDS"),
        subtitle = I18n.Pick("Nhận quà Tân Thủ • Chỉnh cỡ chữ • Bảng phím tắt chuẩn", "Redeem Rewards • UI Scale • Updated PC/Gamepad Controls"),
        position = isPortrait and UDim2.new(0, 16, 0.52, 36) or UDim2.new(0.5, 6, 0, 74),
        size = isPortrait and UDim2.new(1, -32, 0.48, -50) or UDim2.new(0.5, -22, 1, -88),
    })

    -- #100: Giftcode Redemption Box
    local giftBox = UIFactory.Create("Frame", rightCard, {
        Name = "GiftcodeRedemptionCard",
        Position = UDim2.fromOffset(16, 58),
        Size = UDim2.new(1, -32, 0, 108),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
    })
    UIFactory.Corner(giftBox, Theme.Radius.Medium)
    UIFactory.Stroke(giftBox, colors.ACCENT_GOLD, 1.4, 0.2)

    UIFactory.Icon(giftBox, "Gift", UDim2.fromOffset(12, 8), 18, colors.ACCENT_GOLD_BRIGHT)
    UIFactory.Label(giftBox, {
        Name = "GiftHeader",
        Text = I18n.Pick("NHẬP MÃ QUÀ TẶNG (GIFTCODE REDEMPTION)", "REDEEM CELESTIAL GIFTCODE"),
        Position = UDim2.fromOffset(36, 7),
        Size = UDim2.new(1, -48, 0, 20),
        TextSize = 12,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
    })

    local codeInput = UIFactory.Create("TextBox", giftBox, {
        Name = "GiftcodeInput",
        Position = UDim2.fromOffset(12, 32),
        Size = UDim2.new(1, -152, 0, 36),
        Text = "",
        PlaceholderText = I18n.Pick("Nhập mã (VD: SKYBREAK2026, AETHERV2)...", "Enter code (e.g. SKYBREAK2026, AETHERV2)..."),
        Font = Theme.Fonts.Bold,
        TextSize = 13,
        TextColor3 = colors.TEXT_PRIMARY,
        PlaceholderColor3 = colors.TEXT_SECONDARY,
        BackgroundColor3 = colors.BG_800,
        BorderSizePixel = 0,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
    })
    UIFactory.Corner(codeInput, Theme.Radius.Small)
    UIFactory.Stroke(codeInput, colors.ACCENT_SAPPHIRE, 1.1, 0.3)
    UIFactory.Padding(codeInput, 0, 10, 0, 10)

    PremiumButton.Create(giftBox, {
        name = "RedeemCodeBtn",
        label = I18n.Pick("NHẬN QUÀ", "REDEEM"),
        variant = "gold",
        position = UDim2.new(1, -132, 0, 32),
        size = UDim2.fromOffset(120, 36),
        textSize = 12,
        minTextSize = 10,
        onActivated = function()
            redeemGiftcode(codeInput.Text, codeInput)
        end,
    })

    -- Quick-tap active code chips for effortless testing & player convenience
    local chipRow = UIFactory.Create("Frame", giftBox, {
        Name = "ActiveCodeChips",
        Position = UDim2.fromOffset(12, 74),
        Size = UDim2.new(1, -24, 0, 26),
        BackgroundTransparency = 1,
    })
    UIFactory.GridLayout(chipRow, UDim2.new(0.25, -5, 0, 24), UDim2.fromOffset(6, 4))

    local chipApis = {}
    for cIdx, sampleCode in ipairs({ "SKYBREAK2026", "AETHERV2", "MYTHICFRUIT", "FREESTAT" }) do
        local used = (snap and snap.redeemedCodes and snap.redeemedCodes[sampleCode] == true)
            or (Store.Session.redeemedCodes and Store.Session.redeemedCodes[sampleCode] == true)
        local _, cApi = PremiumButton.Create(chipRow, {
            name = "Chip_" .. sampleCode,
            label = used and ("[x] " .. sampleCode) or sampleCode,
            variant = used and "secondary" or "primary",
            disabled = used,
            layoutOrder = cIdx,
            textSize = 9,
            minTextSize = 8,
            onActivated = function()
                codeInput.Text = sampleCode
                redeemGiftcode(sampleCode, codeInput)
                Settings.Update(Store.GetSnapshot())
            end,
        })
        chipApis[sampleCode] = cApi
    end

    -- Text Scale & Volume Controls
    UIFactory.Label(rightCard, {
        Name = "ScaleHeader",
        Text = I18n.Pick(
            string.format("TỈ LỆ PHÓNG ĐẠI GIAO DIỆN  •  Hiện tại: %d%%", math.floor((s.textScale or 1.0) * 100)),
            string.format("UI SCALE MULTIPLIER  •  Current: %d%%", math.floor((s.textScale or 1.0) * 100))
        ),
        Position = UDim2.fromOffset(16, 174),
        Size = UDim2.new(1, -32, 0, 18),
        TextSize = 12,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
    })

    local scaleRow = UIFactory.Create("Frame", rightCard, {
        Name = "ScaleRow",
        Position = UDim2.fromOffset(16, 196),
        Size = UDim2.new(1, -32, 0, 34),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(scaleRow, Enum.FillDirection.Horizontal, 8)

    for idx, preset in ipairs({
        { label = "90% COMPACT", val = 0.90 },
        { label = "100% STANDARD", val = 1.00 },
        { label = "112% LARGE", val = 1.12 },
    }) do
        local isSel = math.abs((s.textScale or 1.0) - preset.val) < 0.02
        PremiumButton.Create(scaleRow, {
            name = "Scale_" .. idx,
            label = preset.label,
            variant = isSel and "primary" or "secondary",
            selected = isSel,
            size = UDim2.new(0.333, -6, 1, 0),
            textSize = 11,
            minTextSize = 9,
            layoutOrder = idx,
            onActivated = function()
                local nextSettings = cloneCurrentSettings()
                nextSettings.textScale = preset.val
                Store.SetView({ settings = nextSettings })
            end,
        })
    end

    local curVolPct = tonumber(s.masterVolume)
    if curVolPct == nil then
        local attrV = lp and tonumber(lp:GetAttribute("MasterVolume"))
        curVolPct = attrV and math.floor(attrV * 100 + 0.5) or 80
    end
    local volHeaderLbl = UIFactory.Label(rightCard, {
        Name = "VolHeader",
        Text = string.format(
            "%s: %d%%   •   SFX / BGM: %d%%",
            I18n.Pick("ÂM LƯỢNG TỔNG", "MASTER VOLUME"),
            curVolPct,
            curVolPct
        ),
        Position = UDim2.fromOffset(16, 238),
        Size = UDim2.new(1, -32, 0, 18),
        TextSize = 12,
        TextColor = colors.ACCENT_SAPPHIRE,
        Bold = true,
    })

    local volRow = UIFactory.Create("Frame", rightCard, {
        Name = "VolumeRow",
        Position = UDim2.fromOffset(16, 260),
        Size = UDim2.new(1, -32, 0, 34),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(volRow, Enum.FillDirection.Horizontal, 6)

    local volApis = {}
    local function applyVolumePreset(volPct)
        local clamped = math.clamp(tonumber(volPct) or 80, 0, 100)
        if lp then
            lp:SetAttribute("AudioMuted", clamped <= 0)
            lp:SetAttribute("MasterVolume", clamped / 100)
            lp:SetAttribute("SFXVolume", 1.0)
            lp:SetAttribute("BGMVolume", 1.0)
        end
        local nextSettings = cloneCurrentSettings()
        nextSettings.masterVolume = clamped
        nextSettings.sfxVolume = clamped
        nextSettings.bgmVolume = clamped
        Store.SetView({ settings = nextSettings })
        volHeaderLbl.Text = string.format(
            "%s: %d%%   •   SFX / BGM: %d%%",
            I18n.Pick("ÂM LƯỢNG TỔNG", "MASTER VOLUME"),
            clamped,
            clamped
        )
        for presetVal, api in pairs(volApis) do
            local sel = (presetVal == clamped)
            api:Update({
                variant = sel and "primary" or "secondary",
                selected = sel,
            })
        end
    end

    for idx, vol in ipairs({ 0, 25, 50, 80, 100 }) do
        local isSel = (curVolPct == vol)
        local _, vApi = PremiumButton.Create(volRow, {
            name = "Vol_" .. vol,
            label = (vol == 0) and I18n.Pick("TẮT", "MUTE") or (tostring(vol) .. "%"),
            variant = isSel and "primary" or "secondary",
            selected = isSel,
            size = UDim2.new(0.20, -5, 1, 0),
            textSize = 11,
            minTextSize = 9,
            layoutOrder = idx,
            onActivated = function()
                applyVolumePreset(vol)
            end,
        })
        volApis[vol] = vApi
    end

    -- #91: Complete Updated Keybind Reference Card ([L] Quests, [J] Busoshoku Haki, [G] Devil Fruits)
    local keyCard = UIFactory.Create("Frame", rightCard, {
        Name = "KeybindReference",
        Position = UDim2.fromOffset(16, 304),
        Size = UDim2.new(1, -32, 1, -318),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
    })
    UIFactory.Corner(keyCard, Theme.Radius.Medium)
    UIFactory.Stroke(keyCard, colors.STROKE_STEEL, 1, 0.35)

    UIFactory.Label(keyCard, {
        Name = "KeyHeader",
        Text = I18n.Pick("BẢNG PHÍM TẮT CHIẾN ĐẤU & ĐIỀU HƯỚNG CHUẨN", "KEYBOARD & GAMEPAD SHORTCUTS"),
        Position = UDim2.fromOffset(14, 8),
        Size = UDim2.new(1, -28, 0, 18),
        TextSize = 12,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
    })

    local keyLinesVi = {
        "• [Chuột Trái] Combo 4 đòn  |  [1]-[4] Đổi Võ / Trái / Kiếm / Súng",
        "• [Z] [X] [C] [V] [F] Bộ 5 chiêu thức  |  [LeftShift / Q] Lướt  |  [Space x2] Geppo",
        "• [LeftCtrl] TẮT Khóa Góc Nhìn & Mở Khóa Chuột  |  [LeftAlt] Action Cam  |  [Tab] Khóa Mục Tiêu",
        "• [J] Haki Vũ Trang  |  [U] Haki Quan Sát  |  [H] Bá Vương  |  [Y] Tộc V4",
        "• [G] Trái 3D  |  [I] Túi  |  [K] Chỉ Số  |  [L] Nhật Ký  |  [M] Bản Đồ  |  [P] Raid  |  [O] Cài Đặt",
    }
    local keyLinesEn = {
        "• [LMB] 4-Hit Combo  |  [1]-[4] Switch Melee / Fruit / Sword / Gun",
        "• [Z] [X] [C] [V] [F] Active Skills  |  [LeftShift / Q] Dash  |  [Space x2] Geppo",
        "• [LeftCtrl] UNLOCK View & Mouse Cursor  |  [LeftAlt] Action Cam  |  [Tab] Target Lock",
        "• [J] Armament Haki  |  [U] Instinct Haki  |  [H] Conqueror  |  [Y] Race V4",
        "• [G] 3D Fruits  |  [I] Bag  |  [K] Stats  |  [L] Quests  |  [M] Map  |  [P] Raid  |  [O] Settings",
    }

    UIFactory.Label(keyCard, {
        Name = "KeyBody",
        Text = table.concat(curLang == "en" and keyLinesEn or keyLinesVi, "\n"),
        Position = UDim2.fromOffset(14, 30),
        Size = UDim2.new(1, -28, 1, -36),
        TextSize = 11,
        TextColor = colors.TEXT_SECONDARY,
        YAlign = Enum.TextYAlignment.Top,
    })

    Settings.Refs = {
        Root = root,
        HeaderRefs = headerRefs,
        ChipApis = chipApis,
    }
    return root
end

function Settings.Update(snap)
    snap = snap or Store.GetSnapshot()
    if Settings.Refs.HeaderRefs and Settings.Refs.HeaderRefs.UpdateCurrencies then
        Settings.Refs.HeaderRefs.UpdateCurrencies(snap)
    end
    if Settings.Refs.ChipApis then
        for code, cApi in pairs(Settings.Refs.ChipApis) do
            local used = (snap and snap.redeemedCodes and snap.redeemedCodes[code] == true)
                or (Store.Session.redeemedCodes and Store.Session.redeemedCodes[code] == true)
            cApi:Update({
                label = used and ("[x] " .. code) or code,
                variant = used and "secondary" or "primary",
                disabled = used,
            })
        end
    end
end

function Settings.Cleanup()
    Settings.Refs = {}
end

return Settings
