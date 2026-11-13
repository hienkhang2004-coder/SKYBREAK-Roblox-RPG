-- SKYBREAK: Fragments of the Core — Screen 9: Bilingual Settings, Working Low FX Mode & Giftcode Redemption ([O])
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/Settings.lua
-- Covers Tasks #8, #10, #91, #94, #100, #123

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

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
    InputConnections = {},
    OnLowFXChanged = nil,
    LowFXDescendantConn = nil,
    CachedOrigShadows = nil,
    _fpsGuardStarted = false,
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
    SKYBREAKLAUNCH = {
        RewardVi = "+10,000 Gold & Buff X2 EXP (30 Phút)",
        RewardEn = "+10,000 Gold & 2x EXP Boost (30m)",
        LootCategory = "Gift",
        GrantDoubleExpSec = 1800,
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

function Settings.ResolveDefaultGraphicsTier()
    return UserInputService.TouchEnabled and "Balanced" or "Ultra"
end

function Settings.NormalizeGraphicsTier(rawTier)
    local s = tostring(rawTier or "")
    if s == "Ultra" or s == "High" then
        return "Ultra"
    elseif s == "Balanced" or s == "Medium" then
        return "Balanced"
    elseif s == "Smooth" or s == "Low" then
        return "Smooth"
    end
    return nil
end

function Settings.GetActiveGraphicsTier(viewSettings)
    local lp = Players.LocalPlayer
    local fromPlayer = lp and Settings.NormalizeGraphicsTier(lp:GetAttribute("GraphicsTier")) or nil
    if fromPlayer then
        return fromPlayer
    end
    local fromWs = Settings.NormalizeGraphicsTier(workspace:GetAttribute("GraphicsTier"))
    if fromWs then
        return fromWs
    end
    local fromView = viewSettings and Settings.NormalizeGraphicsTier(viewSettings.graphicsTier or viewSettings.fxQuality) or nil
    if fromView then
        return fromView
    end
    if (lp and lp:GetAttribute("LowFXMode") == true) or (viewSettings and viewSettings.lowFX == true) then
        return "Smooth"
    end
    return Settings.ResolveDefaultGraphicsTier()
end

-- #123: Working Low FX Mode world-wide applier & exact 100% restorer
function Settings.ApplyLowFXWorld(enabled, skipTierSync)
    local isLow = (enabled == true)
    local lp = Players.LocalPlayer
    if lp then
        lp:SetAttribute("LowFXMode", isLow)
    end
    workspace:SetAttribute("LowFXMode", isLow)

    if not skipTierSync then
        local curTier = (lp and Settings.NormalizeGraphicsTier(lp:GetAttribute("GraphicsTier")))
            or Settings.NormalizeGraphicsTier(workspace:GetAttribute("GraphicsTier"))
        if isLow then
            if lp then
                pcall(function()
                    lp:SetAttribute("GraphicsTier", "Smooth")
                end)
            end
            pcall(function()
                workspace:SetAttribute("GraphicsTier", "Smooth")
            end)
        elseif curTier == nil or curTier == "Smooth" then
            local restored = Settings.ResolveDefaultGraphicsTier()
            if lp then
                pcall(function()
                    lp:SetAttribute("GraphicsTier", restored)
                end)
            end
            pcall(function()
                workspace:SetAttribute("GraphicsTier", restored)
            end)
        end
    end

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

-- Stage 1: 3-Tier Graphics & VFX Mode ("Ultra" | "Balanced" | "Smooth")
function Settings.ApplyGraphicsTier(rawTier)
    local tier = Settings.NormalizeGraphicsTier(rawTier) or Settings.ResolveDefaultGraphicsTier()
    local lp = Players.LocalPlayer
    if lp then
        pcall(function()
            lp:SetAttribute("GraphicsTier", tier)
        end)
    end
    pcall(function()
        workspace:SetAttribute("GraphicsTier", tier)
    end)
    Settings.ApplyLowFXWorld(tier == "Smooth", true)
    return tier
end

-- Initialize default audio, GraphicsTier & Auto Low-FX attributes + once-per-second FPS Guard monitor
function Settings.InitFPSGuard()
    if Settings._fpsGuardStarted then
        return
    end
    Settings._fpsGuardStarted = true

    local initPlr = Players.LocalPlayer
    local bootTier = (initPlr and Settings.NormalizeGraphicsTier(initPlr:GetAttribute("GraphicsTier")))
        or Settings.NormalizeGraphicsTier(workspace:GetAttribute("GraphicsTier"))
    if not bootTier then
        if initPlr and initPlr:GetAttribute("LowFXMode") == true then
            bootTier = "Smooth"
        else
            bootTier = Settings.ResolveDefaultGraphicsTier()
        end
    end
    pcall(function()
        workspace:SetAttribute("GraphicsTier", bootTier)
        if workspace:GetAttribute("LowFXMode") == nil then
            workspace:SetAttribute("LowFXMode", bootTier == "Smooth")
        end
    end)
    if initPlr then
        pcall(function()
            if initPlr:GetAttribute("GraphicsTier") == nil then
                initPlr:SetAttribute("GraphicsTier", bootTier)
            end
            if initPlr:GetAttribute("LowFXMode") == nil then
                initPlr:SetAttribute("LowFXMode", bootTier == "Smooth")
            end
            if initPlr:GetAttribute("MasterVolume") == nil then
                initPlr:SetAttribute("MasterVolume", 0.80)
            end
            if initPlr:GetAttribute("BGMVolume") == nil then
                initPlr:SetAttribute("BGMVolume", 0.80)
            end
            if initPlr:GetAttribute("SFXVolume") == nil then
                initPlr:SetAttribute("SFXVolume", 0.85)
            end
            if initPlr:GetAttribute("AutoLowFXGuard") == nil then
                initPlr:SetAttribute("AutoLowFXGuard", true)
            end
        end)
    end
    if bootTier == "Smooth" then
        Settings.ApplyLowFXWorld(true, true)
    end

    if not RunService:IsClient() then
        return
    end

    local clientStartClock = os.clock()
    local frameCount = 0
    local lastSampleClock = clientStartClock
    local lowFpsStreak = 0
    local lastAutoTriggerClock = -999
    local isWindowFocused = true

    UserInputService.WindowFocusReleased:Connect(function()
        isWindowFocused = false
        lowFpsStreak = 0
    end)
    UserInputService.WindowFocused:Connect(function()
        isWindowFocused = true
        lowFpsStreak = 0
        frameCount = 0
        lastSampleClock = os.clock()
    end)

    RunService.RenderStepped:Connect(function()
        frameCount += 1
    end)

    task.spawn(function()
        while true do
            task.wait(1.0)
            local now = os.clock()
            local dt = math.max(0.25, now - lastSampleClock)
            local avgFps = frameCount / dt
            frameCount = 0
            lastSampleClock = now

            -- Ignore first 12s after client start while world meshes stream in
            if (now - clientStartClock) < 12.0 or not isWindowFocused then
                lowFpsStreak = 0
            else
                local lp = Players.LocalPlayer
                local guardEnabled = (not lp) or (lp:GetAttribute("AutoLowFXGuard") ~= false)
                local alreadyLow = (lp ~= nil) and (lp:GetAttribute("LowFXMode") == true)

                if guardEnabled and (not alreadyLow) and avgFps < 28.0 then
                    lowFpsStreak += 1
                    if lowFpsStreak >= 5 and (now - lastAutoTriggerClock) >= 120.0 then
                        lastAutoTriggerClock = now
                        lowFpsStreak = 0
                        Settings.ApplyGraphicsTier("Smooth")
                        local curView = Store.GetView()
                        local nextSettings = table.clone((curView and curView.settings) or {})
                        nextSettings.graphicsTier = "Smooth"
                        nextSettings.lowFX = true
                        nextSettings.fxQuality = "Low"
                        Store.SetView({ settings = nextSettings })
                        Store.ShowToast(
                            I18n.Pick(
                                string.format("FPS tụt thấp (%.0f FPS): Đã tự động BẬT Low FX Mode để mượt máy! (Đổi tại Cài Đặt [O])", avgFps),
                                string.format("Low FPS (< 28, %.0f FPS): Auto-enabled Low FX Mode to protect frame rate! (Toggle in [O] Settings)", avgFps)
                            ),
                            "warning",
                            5.0
                        )
                    end
                else
                    lowFpsStreak = 0
                end
            end
        end
    end)
end

Settings.InitFPSGuard()

-- #100: Redeem Giftcode handler
local function redeemGiftcode(rawInput, codeBox)
    local cleaned = UIFactory.Upper((tostring(rawInput or ""):gsub("%s+", "")))
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
            I18n.SetLanguage("vi")
            local nextSettings = cloneCurrentSettings()
            nextSettings.language = "vi"
            Store.SetView({ settings = nextSettings })
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
            I18n.SetLanguage("en")
            local nextSettings = cloneCurrentSettings()
            nextSettings.language = "en"
            Store.SetView({ settings = nextSettings })
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

    -- 2. Stage 1: 3-Tier Graphics & VFX Mode Selector ("Ultra" | "Balanced" | "Smooth")
    local activeGraphicsTier = Settings.GetActiveGraphicsTier(s)
    isLowFX = (activeGraphicsTier == "Smooth")

    local GRAPHICS_TIERS = {
        {
            id = "Ultra",
            labelKey = "settings.gfx_ultra",
            descKey = "settings.gfx_desc_ultra",
            legacyFx = "High",
            variant = "gold",
        },
        {
            id = "Balanced",
            labelKey = "settings.gfx_balanced",
            descKey = "settings.gfx_desc_balanced",
            legacyFx = "Medium",
            variant = "primary",
        },
        {
            id = "Smooth",
            labelKey = "settings.gfx_smooth",
            descKey = "settings.gfx_desc_smooth",
            legacyFx = "Low",
            variant = "primary",
        },
    }

    local activeTierDef = GRAPHICS_TIERS[1]
    for _, td in ipairs(GRAPHICS_TIERS) do
        if td.id == activeGraphicsTier then
            activeTierDef = td
            break
        end
    end

    local gfxBox = UIFactory.Create("Frame", listLeft, {
        Name = "GraphicsTierBox",
        Size = UDim2.new(1, -4, 0, 92),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
        LayoutOrder = 2,
    })
    UIFactory.Corner(gfxBox, Theme.Radius.Medium)
    UIFactory.Stroke(
        gfxBox,
        activeGraphicsTier == "Ultra" and colors.ACCENT_GOLD or colors.ACCENT_SAPPHIRE,
        1.3,
        0.22
    )

    UIFactory.Label(gfxBox, {
        Name = "Title",
        Text = I18n.T("settings.gfx_title") .. "  •  " .. I18n.T(activeTierDef.labelKey),
        Position = UDim2.fromOffset(14, 6),
        Size = UDim2.new(1, -28, 0, 18),
        TextSize = 12,
        TextColor = activeGraphicsTier == "Ultra" and colors.ACCENT_GOLD_BRIGHT or colors.ACCENT_SAPPHIRE,
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
    })

    local gfxRow = UIFactory.Create("Frame", gfxBox, {
        Name = "GraphicsTierButtons",
        Position = UDim2.fromOffset(14, 27),
        Size = UDim2.new(1, -28, 0, 32),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(gfxRow, Enum.FillDirection.Horizontal, 6)

    for idx, td in ipairs(GRAPHICS_TIERS) do
        local isSel = (activeGraphicsTier == td.id)
        PremiumButton.Create(gfxRow, {
            name = "GfxTier_" .. td.id,
            label = I18n.T(td.labelKey),
            variant = isSel and td.variant or "secondary",
            selected = isSel,
            size = UDim2.new(0.333, -4, 1, 0),
            textSize = 11,
            minTextSize = 8,
            layoutOrder = idx,
            onActivated = function()
                local applied = Settings.ApplyGraphicsTier(td.id)
                local nextSettings = cloneCurrentSettings()
                nextSettings.graphicsTier = applied
                nextSettings.fxQuality = td.legacyFx
                nextSettings.lowFX = (applied == "Smooth")
                Store.SetView({ settings = nextSettings })
                Store.ShowToast(
                    I18n.Pick(
                        "Đồ họa & VFX: " .. I18n.T(td.labelKey),
                        "Graphics & VFX Mode: " .. I18n.T(td.labelKey)
                    ),
                    "success",
                    2.2
                )
            end,
        })
    end

    UIFactory.Label(gfxBox, {
        Name = "TierDesc",
        Text = I18n.T(activeTierDef.descKey),
        Position = UDim2.fromOffset(14, 63),
        Size = UDim2.new(1, -28, 0, 24),
        TextSize = 10,
        TextColor = colors.TEXT_SECONDARY,
        Truncate = Enum.TextTruncate.AtEnd,
    })

    -- 3. #123: Dedicated Working Low FX Mode Toggle (Synced with "Smooth" GraphicsTier)
    createToggleRow(
        3,
        I18n.Pick("Chế Độ Giảm Hiệu Ứng (Low FX Mode)", "Low FX Performance Mode"),
        I18n.Pick("Tắt bóng đổ GlobalShadows, giảm 65% hạt ParticleEmitter và đồng bộ cấp độ Mượt Nhẹ (Smooth).", "Disables GlobalShadows, scales ParticleEmitters to 35% & syncs Mobile Smooth tier."),
        isLowFX,
        function(nextVal)
            local targetTier = nextVal and "Smooth" or Settings.ResolveDefaultGraphicsTier()
            local applied = Settings.ApplyGraphicsTier(targetTier)
            local nextSettings = cloneCurrentSettings()
            nextSettings.graphicsTier = applied
            nextSettings.lowFX = (applied == "Smooth")
            nextSettings.fxQuality = (applied == "Ultra" and "High") or (applied == "Balanced" and "Medium") or "Low"
            Store.SetView({ settings = nextSettings })
            Store.ShowToast(
                nextVal
                    and I18n.Pick("Đã BẬT Chế Độ Low FX (Mượt Nhẹ • Giảm 65% hạt hiệu ứng)!", "Enabled Low FX Mode (Mobile Smooth • 35% Particle Rate)!")
                    or I18n.Pick("Đã TẮT Low FX Mode (Khôi phục chế độ " .. I18n.T(applied == "Ultra" and "settings.gfx_ultra" or "settings.gfx_balanced") .. ")!", "Disabled Low FX Mode (Restored " .. applied .. " tier)!"),
                "info",
                2.4
            )
        end
    )

    -- 4. Auto Low-FX FPS Guard Toggle (< 28 FPS for 5s)
    local autoGuardAttr = lp and lp:GetAttribute("AutoLowFXGuard")
    local isAutoLowFXGuard = (autoGuardAttr ~= nil) and (autoGuardAttr ~= false) or (s.autoLowFXGuard ~= false)
    createToggleRow(
        4,
        I18n.Pick("Tự gợi ý Low FX khi tụt FPS < 28", "Auto-Suggest Low FX (< 28 FPS)"),
        I18n.Pick("Tự động chuyển sang Mượt Nhẹ (Low FX) kèm thông báo khi FPS trung bình dưới 28 trong 5 giây.", "Automatically switches to Mobile Smooth (Low FX) if average FPS stays below 28 for 5s."),
        isAutoLowFXGuard,
        function(nextVal)
            if lp then
                lp:SetAttribute("AutoLowFXGuard", nextVal)
            end
            local nextSettings = cloneCurrentSettings()
            nextSettings.autoLowFXGuard = nextVal
            Store.SetView({ settings = nextSettings })
            Store.ShowToast(
                nextVal
                    and I18n.Pick("Đã BẬT bảo vệ khung hình Tự Động Low FX (< 28 FPS)!", "Enabled Auto Low-FX FPS Guard (< 28 FPS)!")
                    or I18n.Pick("Đã TẮT tự động bật Low FX khi tụt FPS.", "Disabled Auto Low-FX FPS Guard."),
                "info",
                2.2
            )
        end
    )

    -- 5. Show Celestial Minimap & Core Notifier Toggle (#92, #50)
    createToggleRow(
        5,
        I18n.Pick("Hiển Thị Minimap La Bàn & Radar Lõi Tự Nhiên", "Show Celestial Minimap & Core Radar"),
        I18n.Pick("Bật la bàn radar 148x148 góc phải trên HUD kèm định vị Boss, NPC và Lõi Aether.", "Displays the 148x148 circular compass radar and Natural Core Notifier on HUD."),
        s.showMinimap ~= false,
        function(nextVal)
            local nextSettings = cloneCurrentSettings()
            nextSettings.showMinimap = nextVal
            Store.SetView({ settings = nextSettings })
        end
    )

    -- 6. Reduced Motion Toggle
    createToggleRow(
        6,
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

    -- 7. Disable View Lock & Free Mouse Cursor Toggle (Prevents Shift-Lock / Action Cam / Lock-On Camera Pull)
    local camLockOff = (lp and lp:GetAttribute("DisableCameraLock") == true) or (s.disableCameraLock == true)
    createToggleRow(
        7,
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

    -- 8. Layout Override Selector (Auto / Desktop / Mobile Touch Arc #125)
    local layoutBox = UIFactory.Create("Frame", listLeft, {
        Name = "LayoutModeBox",
        Size = UDim2.new(1, -4, 0, 70),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
        LayoutOrder = 8,
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
            label = UIFactory.Upper(mode),
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

    -- Right Column: Giftcode Redemption (#100), UI Scale, 3-Channel Audio Mixer & Keybind Reference (#91)
    local rightCard = PremiumPanel.Create(root, {
        name = "AudioKeybindCard",
        variant = "gold",
        title = I18n.Pick("GIFTCODE, BỘ TRỘN ÂM THANH 3 KÊNH & PHÍM TẮT", "GIFTCODES, 3-CHANNEL AUDIO MIXER & KEYBINDS"),
        subtitle = I18n.Pick("Nhận quà Tân Thủ • Tổng / BGM / SFX riêng biệt • Tỉ lệ UI & Phím tắt", "Redeem Codes • Master / BGM / SFX Volume • UI Scale & Shortcuts"),
        position = isPortrait and UDim2.new(0, 16, 0.52, 36) or UDim2.new(0.5, 6, 0, 74),
        size = isPortrait and UDim2.new(1, -32, 0.48, -50) or UDim2.new(0.5, -22, 1, -88),
    })

    local listRight = UIFactory.Create("ScrollingFrame", rightCard, {
        Name = "RightList",
        Position = UDim2.fromOffset(16, 56),
        Size = UDim2.new(1, -32, 1, -68),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = colors.ACCENT_GOLD,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.fromOffset(0, 0),
    })
    UIFactory.ListLayout(listRight, Enum.FillDirection.Vertical, 7)

    -- #100: Giftcode Redemption Box
    local giftBox = UIFactory.Create("Frame", listRight, {
        Name = "GiftcodeRedemptionCard",
        Size = UDim2.new(1, -4, 0, 102),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
        LayoutOrder = 1,
    })
    UIFactory.Corner(giftBox, Theme.Radius.Medium)
    UIFactory.Stroke(giftBox, colors.ACCENT_GOLD, 1.4, 0.2)

    UIFactory.Icon(giftBox, "Gift", UDim2.fromOffset(12, 7), 17, colors.ACCENT_GOLD_BRIGHT)
    UIFactory.Label(giftBox, {
        Name = "GiftHeader",
        Text = I18n.Pick("NHẬP MÃ QUÀ TẶNG (GIFTCODE REDEMPTION)", "REDEEM CELESTIAL GIFTCODE"),
        Position = UDim2.fromOffset(35, 6),
        Size = UDim2.new(1, -46, 0, 19),
        TextSize = 12,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
    })

    local codeInput = UIFactory.Create("TextBox", giftBox, {
        Name = "GiftcodeInput",
        Position = UDim2.fromOffset(12, 29),
        Size = UDim2.new(1, -152, 0, 34),
        Text = "",
        PlaceholderText = I18n.Pick("Nhập mã Giftcode chính thức...", "Enter official Giftcode..."),
        Font = Theme.Fonts.Bold,
        TextSize = 12,
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
        position = UDim2.new(1, -132, 0, 29),
        size = UDim2.fromOffset(120, 34),
        textSize = 12,
        minTextSize = 10,
        onActivated = function()
            redeemGiftcode(codeInput.Text, codeInput)
        end,
    })

    UIFactory.Label(giftBox, {
        Name = "CommunityCodeHint",
        Text = I18n.Pick(
            "✦ Theo dõi Nhóm Roblox & Kênh Cộng Đồng SKYBREAK để nhận mã Giftcode sự kiện mới!",
            "✦ Join the official SKYBREAK Roblox Group & Community channels for event Giftcodes!"
        ),
        Position = UDim2.fromOffset(12, 69),
        Size = UDim2.new(1, -24, 0, 26),
        TextSize = 10,
        TextColor = colors.TEXT_SECONDARY,
        Wrapped = true,
    })

    -- UI Scale Multiplier Box
    local scaleCard = UIFactory.Create("Frame", listRight, {
        Name = "UIScaleCard",
        Size = UDim2.new(1, -4, 0, 62),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
        LayoutOrder = 2,
    })
    UIFactory.Corner(scaleCard, Theme.Radius.Medium)
    UIFactory.Stroke(scaleCard, colors.STROKE_STEEL, 1, 0.35)

    UIFactory.Label(scaleCard, {
        Name = "ScaleHeader",
        Text = I18n.Pick(
            string.format("TỈ LỆ PHÓNG ĐẠI GIAO DIỆN  •  Hiện tại: %d%%", math.floor((s.textScale or 1.0) * 100)),
            string.format("UI SCALE MULTIPLIER  •  Current: %d%%", math.floor((s.textScale or 1.0) * 100))
        ),
        Position = UDim2.fromOffset(12, 5),
        Size = UDim2.new(1, -24, 0, 17),
        TextSize = 11,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
    })

    local scaleRow = UIFactory.Create("Frame", scaleCard, {
        Name = "ScaleRow",
        Position = UDim2.fromOffset(12, 25),
        Size = UDim2.new(1, -24, 0, 30),
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

    -- 3-Channel Interactive Volume Mixer (Master / BGM / SFX: 0%..100% via [-]/[+], Draggable Bar & Preset Pills)
    local audioCard = UIFactory.Create("Frame", listRight, {
        Name = "AudioMixerCard",
        Size = UDim2.new(1, -4, 0, 206),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
        LayoutOrder = 3,
    })
    UIFactory.Corner(audioCard, Theme.Radius.Medium)
    UIFactory.Stroke(audioCard, colors.ACCENT_SAPPHIRE, 1.3, 0.22)

    UIFactory.Icon(audioCard, "Volume", UDim2.fromOffset(12, 6), 16, colors.ACCENT_SAPPHIRE)
    UIFactory.Label(audioCard, {
        Name = "AudioMixerHeader",
        Text = I18n.Pick("BỘ ĐIỀU KHIỂN ÂM LƯỢNG 3 KÊNH (KÉO THANH / [-][+] / MỨC NHANH)", "3-CHANNEL VOLUME MIXER (DRAG BAR / [-][+] / PRESETS)"),
        Position = UDim2.fromOffset(33, 5),
        Size = UDim2.new(1, -44, 0, 18),
        TextSize = 11,
        TextColor = colors.ACCENT_SAPPHIRE,
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
    })

    local function resolveInitialPct(attrKey, viewKey, defaultPct)
        if lp then
            if attrKey == "MasterVolume" and lp:GetAttribute("AudioMuted") == true then
                return 0
            end
            local rawAttr = tonumber(lp:GetAttribute(attrKey))
            if rawAttr ~= nil then
                if rawAttr > 1.5 then
                    return math.clamp(math.floor(rawAttr + 0.5), 0, 100)
                end
                return math.clamp(math.floor(rawAttr * 100 + 0.5), 0, 100)
            end
        end
        if tonumber(s[viewKey]) ~= nil then
            return math.clamp(math.floor(tonumber(s[viewKey]) + 0.5), 0, 100)
        end
        return defaultPct
    end

    local PRESET_LEVELS = { 0, 25, 50, 75, 100 }

    local function buildVolumeChannelRow(rowIndex, cfg)
        local curPct = resolveInitialPct(cfg.attrKey, cfg.viewKey, cfg.defaultPct)
        local yOffset = 26 + (rowIndex - 1) * 58

        local chBox = UIFactory.Create("Frame", audioCard, {
            Name = "Channel_" .. cfg.attrKey,
            Position = UDim2.fromOffset(10, yOffset),
            Size = UDim2.new(1, -20, 0, 54),
            BackgroundColor3 = colors.BG_800,
            BackgroundTransparency = 0.20,
            BorderSizePixel = 0,
        })
        UIFactory.Corner(chBox, Theme.Radius.Small)
        UIFactory.Stroke(chBox, cfg.accent, 1.0, 0.55)

        local titleLbl = UIFactory.Label(chBox, {
            Name = "ChannelLabel",
            Text = "",
            Position = UDim2.fromOffset(10, 3),
            Size = UDim2.new(1, -236, 0, 20),
            TextSize = 11,
            TextColor = colors.TEXT_PRIMARY,
            Bold = true,
            Truncate = Enum.TextTruncate.AtEnd,
        })

        local pillsWrap = UIFactory.Create("Frame", chBox, {
            Name = "PresetPills",
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -8, 0, 4),
            Size = UDim2.fromOffset(216, 18),
            BackgroundTransparency = 1,
        })
        UIFactory.ListLayout(pillsWrap, Enum.FillDirection.Horizontal, 4, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)

        local pillRefs = {}
        local applyChannelPct

        for pIdx, pVal in ipairs(PRESET_LEVELS) do
            local pillBtn = UIFactory.Create("TextButton", pillsWrap, {
                Name = "Preset_" .. pVal,
                Size = UDim2.fromOffset(40, 18),
                BackgroundColor3 = colors.BG_900,
                BorderSizePixel = 0,
                AutoButtonColor = true,
                Font = Theme.Fonts.Bold,
                TextSize = 9,
                TextColor3 = colors.TEXT_SECONDARY,
                Text = (pVal == 0) and I18n.Pick("TẮT", "0%") or (tostring(pVal) .. "%"),
                LayoutOrder = pIdx,
            })
            UIFactory.Corner(pillBtn, 4)
            local pStroke = UIFactory.Stroke(pillBtn, colors.STROKE_STEEL, 1, 0.45)
            pillBtn.Activated:Connect(function()
                applyChannelPct(pVal)
            end)
            pillRefs[pVal] = { Button = pillBtn, Stroke = pStroke }
        end

        local minusBtn = UIFactory.Create("TextButton", chBox, {
            Name = "StepMinus",
            Position = UDim2.fromOffset(8, 27),
            Size = UDim2.fromOffset(30, 22),
            BackgroundColor3 = colors.BG_900,
            BorderSizePixel = 0,
            AutoButtonColor = true,
            Font = Theme.Fonts.Bold,
            TextSize = 14,
            TextColor3 = cfg.accent,
            Text = "-",
        })
        UIFactory.Corner(minusBtn, 5)
        UIFactory.Stroke(minusBtn, cfg.accent, 1.1, 0.35)

        local plusBtn = UIFactory.Create("TextButton", chBox, {
            Name = "StepPlus",
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -8, 0, 27),
            Size = UDim2.fromOffset(30, 22),
            BackgroundColor3 = colors.BG_900,
            BorderSizePixel = 0,
            AutoButtonColor = true,
            Font = Theme.Fonts.Bold,
            TextSize = 14,
            TextColor3 = cfg.accent,
            Text = "+",
        })
        UIFactory.Corner(plusBtn, 5)
        UIFactory.Stroke(plusBtn, cfg.accent, 1.1, 0.35)

        local sliderHit = UIFactory.Create("TextButton", chBox, {
            Name = "SliderHitbox",
            Position = UDim2.fromOffset(46, 26),
            Size = UDim2.new(1, -92, 0, 24),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Text = "",
        })

        local track = UIFactory.Create("Frame", sliderHit, {
            Name = "Track",
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.fromScale(0, 0.5),
            Size = UDim2.new(1, 0, 0, 9),
            BackgroundColor3 = colors.BG_900,
            BorderSizePixel = 0,
        })
        UIFactory.PillCorner(track)
        UIFactory.Stroke(track, colors.STROKE_STEEL, 1, 0.40)

        local fill = UIFactory.Create("Frame", track, {
            Name = "Fill",
            Size = UDim2.fromScale(curPct / 100, 1),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
        })
        UIFactory.PillCorner(fill)
        UIFactory.Gradient(fill, cfg.gradTop, cfg.gradBot, 0)

        local knob = UIFactory.Create("Frame", track, {
            Name = "Knob",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(curPct / 100, 0.5),
            Size = UDim2.fromOffset(15, 15),
            BackgroundColor3 = Color3.fromRGB(248, 251, 255),
            BorderSizePixel = 0,
            ZIndex = track.ZIndex + 2,
        })
        UIFactory.PillCorner(knob)
        UIFactory.Stroke(knob, cfg.accent, 2.0, 0.05)

        local function refreshRowVisuals()
            local statusStr = (curPct <= 0)
                and I18n.Pick("TẮT (0%)", "MUTE (0%)")
                or (tostring(curPct) .. "%")
            titleLbl.Text = string.format("%s:  %s", cfg.label, statusStr)
            titleLbl.TextColor3 = (curPct <= 0) and colors.TEXT_MUTED or colors.TEXT_PRIMARY

            local ratio = math.clamp(curPct / 100, 0, 1)
            fill.Size = UDim2.fromScale(ratio, 1)
            knob.Position = UDim2.fromScale(ratio, 0.5)

            for pVal, pRef in pairs(pillRefs) do
                local active = (curPct == pVal)
                pRef.Button.BackgroundColor3 = active and cfg.accent or colors.BG_900
                pRef.Button.TextColor3 = active and colors.BG_900 or colors.TEXT_SECONDARY
                pRef.Stroke.Color = active and colors.ACCENT_GOLD_BRIGHT or colors.STROKE_STEEL
                pRef.Stroke.Transparency = active and 0.05 or 0.45
            end
        end

        applyChannelPct = function(nextPct)
            local clamped = math.clamp(math.floor((tonumber(nextPct) or 0) + 0.5), 0, 100)
            curPct = clamped
            local norm = clamped / 100
            if lp then
                lp:SetAttribute(cfg.attrKey, norm)
                if cfg.attrKey == "MasterVolume" then
                    lp:SetAttribute("AudioMuted", clamped <= 0)
                end
            end
            local viewObj = Store.GetView()
            if viewObj then
                viewObj.settings = viewObj.settings or {}
                viewObj.settings[cfg.viewKey] = clamped
            end
            refreshRowVisuals()
        end

        minusBtn.Activated:Connect(function()
            applyChannelPct(curPct - 5)
        end)
        plusBtn.Activated:Connect(function()
            applyChannelPct(curPct + 5)
        end)

        local isDragging = false
        local function updateFromInputX(screenX)
            local absX = sliderHit.AbsolutePosition.X
            local absW = math.max(1, sliderHit.AbsoluteSize.X)
            local alpha = math.clamp((screenX - absX) / absW, 0, 1)
            applyChannelPct(alpha * 100)
        end

        sliderHit.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isDragging = true
                updateFromInputX(input.Position.X)
            end
        end)

        table.insert(Settings.InputConnections, UserInputService.InputChanged:Connect(function(input)
            if not isDragging then
                return
            end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                updateFromInputX(input.Position.X)
            end
        end))

        table.insert(Settings.InputConnections, UserInputService.InputEnded:Connect(function(input)
            if isDragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                isDragging = false
            end
        end))

        -- Sync attribute on build so audio engine matches UI immediately
        applyChannelPct(curPct)
    end

    buildVolumeChannelRow(1, {
        attrKey = "MasterVolume",
        viewKey = "masterVolume",
        defaultPct = 80,
        label = I18n.Pick("Âm Lượng Tổng", "Master Volume"),
        accent = colors.ACCENT_GOLD_BRIGHT,
        gradTop = Color3.fromRGB(228, 184, 99),
        gradBot = Color3.fromRGB(255, 228, 138),
    })

    buildVolumeChannelRow(2, {
        attrKey = "BGMVolume",
        viewKey = "bgmVolume",
        defaultPct = 80,
        label = I18n.Pick("Nhạc Nền (BGM)", "BGM Volume"),
        accent = colors.ACCENT_SAPPHIRE,
        gradTop = Color3.fromRGB(36, 128, 232),
        gradBot = Color3.fromRGB(112, 214, 255),
    })

    buildVolumeChannelRow(3, {
        attrKey = "SFXVolume",
        viewKey = "sfxVolume",
        defaultPct = 85,
        label = I18n.Pick("Hiệu Ứng Chiêu (SFX)", "SFX Volume"),
        accent = colors.SUCCESS,
        gradTop = Color3.fromRGB(32, 182, 132),
        gradBot = Color3.fromRGB(122, 242, 192),
    })

    -- #91: Complete Updated Keybind Reference Card ([L] Quests, [J] Busoshoku Haki, [G] Devil Fruits)
    local keyCard = UIFactory.Create("Frame", listRight, {
        Name = "KeybindReference",
        Size = UDim2.new(1, -4, 0, 136),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
        LayoutOrder = 4,
    })
    UIFactory.Corner(keyCard, Theme.Radius.Medium)
    UIFactory.Stroke(keyCard, colors.STROKE_STEEL, 1, 0.35)

    UIFactory.Label(keyCard, {
        Name = "KeyHeader",
        Text = I18n.Pick("BẢNG PHÍM TẮT CHIẾN ĐẤU & ĐIỀU HƯỚNG CHUẨN", "KEYBOARD & GAMEPAD SHORTCUTS"),
        Position = UDim2.fromOffset(14, 6),
        Size = UDim2.new(1, -28, 0, 18),
        TextSize = 11,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
    })

    local keyLinesVi = {
        "• [Chuột Trái] Combo 4 đòn  |  [1]-[4] Đổi Võ / Lõi Aether / Kiếm / Súng",
        "• [Z] [X] [C] [V] [F] Bộ 5 chiêu thức  |  [LeftShift / Q] Thuấn Bộ  |  [Space x2] Bộ Không",
        "• [LeftCtrl] TẮT Khóa Góc Nhìn & Mở Khóa Chuột  |  [LeftAlt] Action Cam  |  [Tab] Khóa Mục Tiêu",
        "• [J] Giáp Ý Chí  |  [U] Thấu Ý  |  [H] Bá Ý  |  [Y] Thăng Hoa  |  [E] Tương Tác NPC (Shop/Rèn/Gacha/Raid)",
        "• [I] Túi  |  [K] Kỹ Năng  |  [G] Kho Lõi  |  [L] Nhật Ký  |  [M] Bản Đồ  |  [B] Tổ Đội & Quà  |  [O] Cài Đặt",
    }
    local keyLinesEn = {
        "• [LMB] 4-Hit Combo  |  [1]-[4] Switch Melee / Aether Core / Sword / Gun",
        "• [Z] [X] [C] [V] [F] Active Skills  |  [LeftShift / Q] Blink Dash  |  [Space x2] Sky Step",
        "• [LeftCtrl] UNLOCK View & Mouse Cursor  |  [LeftAlt] Action Cam  |  [Tab] Target Lock",
        "• [J] Will Armor  |  [U] Will Sense  |  [H] Sovereign Will  |  [Y] Ascension  |  [E] Talk NPC (Shop/Forge/Gacha)",
        "• [I] Bag  |  [K] Skills  |  [G] Core Vault  |  [L] Quests  |  [M] Map  |  [B] Party & Gifts  |  [O] Settings",
    }

    UIFactory.Label(keyCard, {
        Name = "KeyBody",
        Text = table.concat(curLang == "en" and keyLinesEn or keyLinesVi, "\n"),
        Position = UDim2.fromOffset(14, 26),
        Size = UDim2.new(1, -28, 1, -32),
        TextSize = 11,
        TextColor = colors.TEXT_SECONDARY,
        YAlign = Enum.TextYAlignment.Top,
    })

    Settings.Refs = {
        Root = root,
        HeaderRefs = headerRefs,
    }
    return root
end

function Settings.Update(snap)
    snap = snap or Store.GetSnapshot()
    if Settings.Refs.HeaderRefs and Settings.Refs.HeaderRefs.UpdateCurrencies then
        Settings.Refs.HeaderRefs.UpdateCurrencies(snap)
    end
end

function Settings.Cleanup()
    for _, conn in ipairs(Settings.InputConnections or {}) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    Settings.InputConnections = {}
    Settings.Refs = {}
end

return Settings
