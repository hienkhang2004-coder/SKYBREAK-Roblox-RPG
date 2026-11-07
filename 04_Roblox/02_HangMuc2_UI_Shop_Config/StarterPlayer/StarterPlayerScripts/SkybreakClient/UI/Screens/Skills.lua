-- SKYBREAK: Fragments of the Core — Lv. 2550 Glossy Segmented Stats, 3-Slot Presets & Class Ascension Screen ([K])
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/Skills.lua
-- Visual Upgrade: Matches Figma Design File 3 (SKYBREAK_NPC_06 Panel 2) 1:1 with 5 Horizontal Glossy Segmented
-- Stat Cards (+1 / +10 / +MAX), Top-Right Gold Unspent Points Pill, Bottom Crimson Stat Refund & Gold Rainbow Haki
-- Buttons, 3-Slot Build Presets, and Right-Column 3-Class Switcher + Mastery Nodes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local WorldConfig = require(Shared:WaitForChild("Config"):WaitForChild("WorldConfig"))
local UIState = require(Shared:WaitForChild("Types"):WaitForChild("UIState"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Store = require(script.Parent.Parent:WaitForChild("Store"))
local ScreenRouter = require(script.Parent.Parent:WaitForChild("ScreenRouter"))
local I18n = require(script.Parent.Parent:WaitForChild("I18n"))
local PremiumPanel = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumPanel"))
local PremiumButton = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumButton"))
local PartyController = require(script.Parent.Parent:WaitForChild("Controllers"):WaitForChild("PartyController"))

local MAX_LEVEL = 2550
local MAX_STAT = 2550

local STAT_CATEGORIES = {
    {
        key = "Melee",
        icon = "Fist",
        titleVi = "CẬN CHIẾN (MELEE)",
        titleEn = "MELEE COMBAT",
        subVi = "Tăng Năng Lượng EN & Sát thương Võ Thuật",
        subEn = "Boosts Max Energy & Martial Arts Damage",
        gradTop = Color3.fromRGB(252, 211, 77),
        gradBottom = Color3.fromRGB(180, 83, 9),
        accent = Color3.fromRGB(252, 211, 77),
    },
    {
        key = "Defense",
        icon = "Shield",
        titleVi = "PHÒNG THỦ (DEFENSE)",
        titleEn = "DEFENSE & VITALITY",
        subVi = "Tăng Sinh Lực Max HP & Giảm Sát Thương",
        subEn = "Boosts Max HP & Damage Reduction",
        gradTop = Color3.fromRGB(251, 113, 133),
        gradBottom = Color3.fromRGB(225, 29, 72),
        accent = Color3.fromRGB(251, 113, 133),
    },
    {
        key = "Sword",
        icon = "Sword",
        titleVi = "KIẾM THUẬT (SWORD)",
        titleEn = "SWORD MASTERY",
        subVi = "Tăng Sát thương Vũ Khí Cận Chiến Slot 3",
        subEn = "Boosts Slot 3 3D Blade & Dual Sword Damage",
        gradTop = Color3.fromRGB(96, 165, 250),
        gradBottom = Color3.fromRGB(29, 78, 216),
        accent = Color3.fromRGB(96, 165, 250),
    },
    {
        key = "Gun",
        icon = "Gun",
        titleVi = "PHÁP KHÍ SÚNG (GUN)",
        titleEn = "ARCANE GUNNERY",
        subVi = "Tăng Sát thương Súng & Pháp Khí Slot 4",
        subEn = "Boosts Slot 4 Arcane Firearms & Rifles",
        gradTop = Color3.fromRGB(56, 189, 248),
        gradBottom = Color3.fromRGB(2, 132, 199),
        accent = Color3.fromRGB(56, 189, 248),
    },
    {
        key = "Fruit",
        icon = "Fruit",
        titleVi = "LÕI AETHER (CORE)",
        titleEn = "AETHER CORE",
        subVi = "Tăng Sát thương toàn bộ 5 chiêu Lõi Aether",
        subEn = "Boosts all 5 [Z][X][C][V][F] 3D Aether Core Skills",
        gradTop = Color3.fromRGB(244, 63, 94),
        gradBottom = Color3.fromRGB(147, 51, 234),
        accent = Color3.fromRGB(232, 121, 249),
    },
}

local PRESET_DEFS = {
    [1] = {
        NameVi = "Cấu Hình 1: Võ Sĩ",
        NameEn = "Preset 1: Brawler",
        Weights = { Melee = 0.50, Defense = 0.50, Sword = 0, Gun = 0, Fruit = 0 },
    },
    [2] = {
        NameVi = "Cấu Hình 2: Kiếm Thánh",
        NameEn = "Preset 2: Swordmaster",
        Weights = { Melee = 0.20, Defense = 0.35, Sword = 0.45, Gun = 0, Fruit = 0 },
    },
    [3] = {
        NameVi = "Cấu Hình 3: Lõi Aether",
        NameEn = "Preset 3: Core Sovereign",
        Weights = { Melee = 0.18, Defense = 0.34, Sword = 0, Gun = 0, Fruit = 0.48 },
    },
}

local HAKI_COLORS = {
    { Id = "Gold", Label = "GOLD", Color = Color3.fromRGB(244, 193, 78) },
    { Id = "Crimson", Label = "RED", Color = Color3.fromRGB(244, 63, 94) },
    { Id = "Cyan", Label = "CYAN", Color = Color3.fromRGB(56, 189, 248) },
    { Id = "Violet", Label = "VOID", Color = Color3.fromRGB(168, 85, 247) },
    { Id = "Emerald", Label = "JADE", Color = Color3.fromRGB(52, 211, 153) },
    { Id = "Rose", Label = "ROSE", Color = Color3.fromRGB(251, 113, 133) },
}

local Skills = {
    Refs = {},
    HakiCycleIndex = 1,
}

local function fireEquipRemote(payload)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes then
        if remotes:FindFirstChild("EquipmentRequest") then
            remotes.EquipmentRequest:FireServer(payload)
        elseif payload and payload.action == "AddStat" and remotes:FindFirstChild("StatAllocate") then
            remotes.StatAllocate:FireServer(payload.stat, payload.amount)
        end
    end
end

local function fireUIRequest(actionName, payload)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes and remotes:FindFirstChild("UIRequest") then
        remotes.UIRequest:FireServer(actionName, payload or {})
    end
end

local function applyHakiAuraColor(hc)
    if not hc then
        return
    end
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes and remotes:FindFirstChild("UIRequest") then
        remotes.UIRequest:FireServer("SetHakiColor", { colorId = hc.Id })
    elseif remotes and remotes:FindFirstChild("AppearanceRequest") then
        remotes.AppearanceRequest:FireServer({ action = "SetHakiColor", colorId = hc.Id })
    end
    Store.ShowToast(
        I18n.Pick("Đã kích hoạt Sắc Màu Bá Ý: ", "Activated Sovereign Will Aura: ") .. hc.Id .. " (" .. hc.Label .. ")",
        "success",
        2.0
    )
end

local function allocateStatAmount(statKey, reqAmount)
    local snap = Store.GetSnapshot()
    local fState = snap.fruits or {}
    local curAlloc = fState.statAlloc or { Melee = 1, Defense = 1, Sword = 1, Gun = 1, Fruit = 1 }
    local curVal = math.clamp(tonumber(curAlloc[statKey]) or 1, 1, MAX_STAT)
    local unspent = tonumber(fState.statPoints) or 0
    local room = math.max(0, MAX_STAT - curVal)

    local sendAmt = reqAmount
    if reqAmount >= MAX_STAT then
        sendAmt = (unspent > 0) and math.min(unspent, math.max(1, room)) or math.max(1, room)
    else
        sendAmt = math.max(1, reqAmount)
    end

    fireEquipRemote({ action = "AddStat", stat = statKey, amount = sendAmt })

    if snap.isDemoMode and snap.fruits and unspent > 0 and room > 0 then
        local actual = math.min(sendAmt, unspent, room)
        snap.fruits.statAlloc = snap.fruits.statAlloc or {}
        snap.fruits.statAlloc[statKey] = curVal + actual
        snap.fruits.statPoints = math.max(0, unspent - actual)
        Skills.Update(snap)
    end
end

local function requestFullStatRefund()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes and remotes:FindFirstChild("UIRequest") then
        remotes.UIRequest:FireServer("RefundStats", {})
    else
        fireEquipRemote({ action = "RefundStats" })
    end

    local snap = Store.GetSnapshot()
    if snap.isDemoMode and snap.fruits then
        local curAlloc = snap.fruits.statAlloc or {}
        local refunded = 0
        for _, st in ipairs(STAT_CATEGORIES) do
            refunded += math.max(0, (tonumber(curAlloc[st.key]) or 1) - 1)
            curAlloc[st.key] = 1
        end
        snap.fruits.statAlloc = curAlloc
        snap.fruits.statPoints = (tonumber(snap.fruits.statPoints) or 0) + refunded
        Skills.Update(snap)
    end

    Store.ShowToast(
        I18n.Pick("Đã gửi yêu cầu Tẩy Toàn Bộ Điểm Chỉ Số!", "Requested full Stat Points Refund!"),
        "info",
        2.4
    )
end

-- Compute target stat allocation for a saved or default preset given player's total stat budget
local function applyStatPresetSlot(slotIdx)
    local snap = Store.GetSnapshot()
    local fState = snap.fruits or {}
    local curAlloc = fState.statAlloc or { Melee = 1, Defense = 1, Sword = 1, Gun = 1, Fruit = 1 }
    local unspent = tonumber(fState.statPoints) or 0

    local totalSpentAboveBase = 0
    for _, st in ipairs(STAT_CATEGORIES) do
        totalSpentAboveBase += math.max(0, (tonumber(curAlloc[st.key]) or 1) - 1)
    end
    local totalBudget = math.max(0, totalSpentAboveBase + unspent)

    local presetStore = Store.Session.statPresets[slotIdx]
    local pDef = PRESET_DEFS[slotIdx] or PRESET_DEFS[1]
    local targetAdd = { Melee = 0, Defense = 0, Sword = 0, Gun = 0, Fruit = 0 }

    local usedSavedWeights = false
    if presetStore and presetStore.Saved and type(presetStore.Stats) == "table" then
        local savedAbove = 0
        for _, st in ipairs(STAT_CATEGORIES) do
            savedAbove += math.max(0, (tonumber(presetStore.Stats[st.key]) or 1) - 1)
        end
        if savedAbove > 0 and totalBudget > 0 then
            usedSavedWeights = true
            for _, st in ipairs(STAT_CATEGORIES) do
                local w = math.max(0, (tonumber(presetStore.Stats[st.key]) or 1) - 1) / savedAbove
                targetAdd[st.key] = math.min(MAX_STAT - 1, math.floor(totalBudget * w))
            end
        end
    end
    if not usedSavedWeights then
        for _, st in ipairs(STAT_CATEGORIES) do
            local w = pDef.Weights[st.key] or 0
            targetAdd[st.key] = math.min(MAX_STAT - 1, math.floor(totalBudget * w))
        end
    end

    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes and remotes:FindFirstChild("UIRequest") then
        remotes.UIRequest:FireServer("ApplyStatPreset", { slot = slotIdx, stats = targetAdd })
    elseif remotes and remotes:FindFirstChild("EquipmentRequest") then
        remotes.EquipmentRequest:FireServer({ action = "RefundStats" })
        task.delay(0.08, function()
            for _, st in ipairs(STAT_CATEGORIES) do
                local addAmt = targetAdd[st.key] or 0
                if addAmt > 0 then
                    fireEquipRemote({ action = "AddStat", stat = st.key, amount = addAmt })
                end
            end
        end)
    end

    if snap.isDemoMode and snap.fruits then
        local used = 0
        snap.fruits.statAlloc = snap.fruits.statAlloc or {}
        for _, st in ipairs(STAT_CATEGORIES) do
            local addAmt = targetAdd[st.key] or 0
            snap.fruits.statAlloc[st.key] = 1 + addAmt
            used += addAmt
        end
        snap.fruits.statPoints = math.max(0, totalBudget - used)
        Skills.Update(snap)
    end

    local presetTitle = I18n.GetLanguage() == "en" and pDef.NameEn or pDef.NameVi
    Store.ShowToast(
        I18n.Pick("Đã nạp " .. presetTitle .. "!", "Loaded " .. presetTitle .. "!"),
        "success",
        2.5
    )
end

local function saveStatPresetSlot(slotIdx)
    local snap = Store.GetSnapshot()
    local fState = snap.fruits or {}
    local curAlloc = fState.statAlloc or { Melee = 1, Defense = 1, Sword = 1, Gun = 1, Fruit = 1 }
    local copied = {
        Melee = tonumber(curAlloc.Melee) or 1,
        Defense = tonumber(curAlloc.Defense) or 1,
        Sword = tonumber(curAlloc.Sword) or 1,
        Gun = tonumber(curAlloc.Gun) or 1,
        Fruit = tonumber(curAlloc.Fruit) or 1,
    }
    Store.Session.statPresets[slotIdx] = Store.Session.statPresets[slotIdx] or {}
    Store.Session.statPresets[slotIdx].Saved = true
    Store.Session.statPresets[slotIdx].Stats = copied
    fireUIRequest("SaveStatPreset", { slot = slotIdx, stats = copied })

    local pDef = PRESET_DEFS[slotIdx] or PRESET_DEFS[1]
    local presetTitle = I18n.GetLanguage() == "en" and pDef.NameEn or pDef.NameVi
    Store.ShowToast(
        I18n.Pick("Đã lưu điểm hiện tại vào " .. presetTitle .. "!", "Saved current stats into " .. presetTitle .. "!"),
        "success",
        2.4
    )
end

function Skills.Build(parent)
    Skills.Cleanup()
    local colors = Theme.Colors
    local snap = Store.GetSnapshot()
    local view = Store.GetView()
    local selectedClassId = view.selectedClassTab or snap.player.classId or "SkyGuardian"
    local classCfg = WorldConfig.Classes[selectedClassId] or WorldConfig.Classes.SkyGuardian
    local fState = snap.fruits or {}
    local statAlloc = fState.statAlloc or { Melee = 1, Defense = 1, Sword = 1, Gun = 1, Fruit = 1 }
    local statPoints = tonumber(fState.statPoints) or 0
    local curLevel = tonumber(snap.player.level) or 1

    local root = UIFactory.Create("Frame", parent, {
        Name = "SkillsScreen",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 2,
    })

    local refs = {
        Root = root,
        StatRows = {},
    }
    Skills.Refs = refs

    local _, headerRefs = UIFactory.BuildScreenHeader(root, {
        ActiveScreen = UIState.Screens.Skills,
        Title = I18n.T("skills.title"),
        Snapshot = snap,
        OnNavigate = function(targetId)
            ScreenRouter.Navigate(targetId)
        end,
        OnClose = function()
            ScreenRouter.CloseAllToHUD()
        end,
    })
    refs.HeaderRefs = headerRefs

    -- ========================================================================
    -- LEFT / MAIN PANEL (62%): 5 GLOSSY SEGMENTED STAT BARS (+1 / +10 / +MAX)
    -- Matches SKYBREAK_NPC_06 Panel 2 1:1
    -- ========================================================================
    local statsPanel = PremiumPanel.Create(root, {
        name = "SegmentedStatsMasterPanel",
        variant = "gold",
        position = UDim2.fromOffset(16, 72),
        size = UDim2.new(0.62, -18, 1, -84),
    })

    UIFactory.Label(statsPanel, {
        Name = "PanelHeaderTitle",
        Text = I18n.Pick(
            string.format("BẢNG CỘNG ĐIỂM CHỈ SỐ (5 NHÁNH MAX %d)  •  LV.%d", MAX_STAT, curLevel),
            string.format("STAT ALLOCATION (5 BRANCHES MAX %d)  •  LV.%d", MAX_STAT, curLevel)
        ),
        Position = UDim2.fromOffset(14, 10),
        Size = UDim2.new(1, -262, 0, 26),
        TextSize = 14,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
    })

    -- Top-Right Gold-Stroked Unspent Points Pill ("ĐIỂM CHƯA CỘNG: XXX ĐIỂM")
    local unspentPill = UIFactory.Create("Frame", statsPanel, {
        Name = "UnspentPointsPill",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 8),
        Size = UDim2.fromOffset(238, 30),
        BackgroundColor3 = Color3.fromRGB(28, 22, 10),
        BorderSizePixel = 0,
    })
    UIFactory.PillCorner(unspentPill)
    UIFactory.Stroke(unspentPill, colors.ACCENT_GOLD_BRIGHT, 1.6, 0.08)

    refs.StatPointsBanner = UIFactory.Label(unspentPill, {
        Name = "StatPointsBanner",
        Text = string.format(
            "%s: %s %s",
            I18n.Pick("ĐIỂM CHƯA CỘNG", "UNSPENT"),
            UIFactory.FormatNumber(statPoints),
            I18n.Pick("ĐIỂM", "PTS")
        ),
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -20, 1, 0),
        TextSize = 11,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Truncate = Enum.TextTruncate.AtEnd,
    })

    -- 5 Horizontal Glossy Segmented Stat Cards
    local barsContainer = UIFactory.Create("Frame", statsPanel, {
        Name = "FiveStatCardsContainer",
        Position = UDim2.fromOffset(14, 44),
        Size = UDim2.new(1, -28, 0, 378),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(barsContainer, Enum.FillDirection.Vertical, 7)

    for idx, st in ipairs(STAT_CATEGORIES) do
        local curVal = math.clamp(tonumber(statAlloc[st.key]) or 1, 1, MAX_STAT)
        local ratio = math.clamp(curVal / MAX_STAT, 0, 1)

        local sCard = UIFactory.Create("Frame", barsContainer, {
            Name = "StatCard_" .. st.key,
            Size = UDim2.new(1, 0, 0, 70),
            BackgroundColor3 = Color3.fromRGB(11, 17, 32),
            BorderSizePixel = 0,
            LayoutOrder = idx,
        })
        UIFactory.Corner(sCard, Theme.Radius.Medium)
        UIFactory.Stroke(sCard, st.accent, 1.3, 0.28)

        -- Left: Icon Crest + Bold Uppercase Title & Descriptive Subtitle
        local iconBox = UIFactory.Create("Frame", sCard, {
            Name = "StatCrest",
            Position = UDim2.fromOffset(10, 15),
            Size = UDim2.fromOffset(40, 40),
            BackgroundColor3 = Color3.fromRGB(16, 24, 44),
            BorderSizePixel = 0,
        })
        UIFactory.Corner(iconBox, Theme.Radius.Small)
        UIFactory.Stroke(iconBox, st.accent, 1.2, 0.25)
        UIFactory.Icon(iconBox, st.icon, UDim2.fromOffset(9, 9), 22, st.accent)

        UIFactory.Label(sCard, {
            Name = "StatTitle",
            Text = I18n.GetLanguage() == "en" and st.titleEn or st.titleVi,
            Position = UDim2.fromOffset(58, 12),
            Size = UDim2.fromOffset(192, 22),
            TextSize = 13,
            TextColor = st.accent,
            Bold = true,
            Truncate = Enum.TextTruncate.AtEnd,
        })

        UIFactory.Label(sCard, {
            Name = "StatSub",
            Text = I18n.GetLanguage() == "en" and st.subEn or st.subVi,
            Position = UDim2.fromOffset(58, 34),
            Size = UDim2.fromOffset(192, 24),
            TextSize = 10,
            TextColor = colors.TEXT_SECONDARY,
            Wrapped = true,
        })

        -- Center: Glossy Segmented Progress Bar with Centered Bold "LV. XXX / 2550"
        local barTrack = UIFactory.Create("Frame", sCard, {
            Name = "SegmentedTrack",
            Position = UDim2.fromOffset(256, 19),
            Size = UDim2.new(1, -468, 0, 32),
            BackgroundColor3 = Color3.fromRGB(6, 10, 20),
            BorderSizePixel = 0,
            ClipsDescendants = true,
        })
        UIFactory.PillCorner(barTrack)
        UIFactory.Stroke(barTrack, st.accent, 1.2, 0.35)

        local barFill = UIFactory.Create("Frame", barTrack, {
            Name = "GradientFill",
            Size = UDim2.fromScale(math.max(0.03, ratio), 1),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            ZIndex = 3,
        })
        UIFactory.PillCorner(barFill)

        local fillGrad = Instance.new("UIGradient")
        fillGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, st.gradTop),
            ColorSequenceKeypoint.new(1, st.gradBottom),
        })
        fillGrad.Rotation = 90
        fillGrad.Parent = barFill

        local fillSheen = UIFactory.Create("Frame", barFill, {
            Name = "TopGloss",
            Size = UDim2.new(1, 0, 0.44, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.78,
            BorderSizePixel = 0,
            ZIndex = 4,
        })
        UIFactory.PillCorner(fillSheen)

        -- 8 Vertical Segment Dividers across the bar track
        for seg = 1, 7 do
            UIFactory.Create("Frame", barTrack, {
                Name = "Seg_" .. seg,
                Position = UDim2.new(seg / 8, 0, 0, 0),
                Size = UDim2.new(0, 2, 1, 0),
                BackgroundColor3 = Color3.fromRGB(6, 10, 20),
                BackgroundTransparency = 0.35,
                BorderSizePixel = 0,
                ZIndex = 5,
            })
        end

        local valLbl = UIFactory.Label(barTrack, {
            Name = "LevelValueText",
            Text = string.format("LV. %d / %d%s", curVal, MAX_STAT, curVal >= MAX_STAT and " [MAX]" or ""),
            Size = UDim2.fromScale(1, 1),
            TextSize = 12,
            TextColor = Color3.fromRGB(255, 255, 255),
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            ZIndex = 6,
        })
        valLbl.TextStrokeColor3 = Color3.fromRGB(4, 8, 18)
        valLbl.TextStrokeTransparency = 0.16

        -- Right: Tactile Glossy +1, +10, +MAX Buttons
        local btnGroup = UIFactory.Create("Frame", sCard, {
            Name = "AllocButtons",
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -10, 0.5, 0),
            Size = UDim2.fromOffset(196, 36),
            BackgroundTransparency = 1,
        })

        PremiumButton.Create(btnGroup, {
            name = "Add1_" .. st.key,
            label = "+1",
            variant = "primary",
            position = UDim2.fromOffset(0, 0),
            size = UDim2.fromOffset(56, 36),
            textSize = 12,
            minTextSize = 10,
            onActivated = function()
                allocateStatAmount(st.key, 1)
            end,
        })

        PremiumButton.Create(btnGroup, {
            name = "Add10_" .. st.key,
            label = "+10",
            variant = "primary",
            position = UDim2.fromOffset(62, 0),
            size = UDim2.fromOffset(60, 36),
            textSize = 12,
            minTextSize = 10,
            onActivated = function()
                allocateStatAmount(st.key, 10)
            end,
        })

        PremiumButton.Create(btnGroup, {
            name = "AddMax_" .. st.key,
            label = "+MAX",
            variant = "gold",
            position = UDim2.fromOffset(128, 0),
            size = UDim2.fromOffset(68, 36),
            textSize = 12,
            minTextSize = 10,
            onActivated = function()
                allocateStatAmount(st.key, MAX_STAT)
            end,
        })

        refs.StatRows[st.key] = {
            ValueLabel = valLbl,
            BarFill = barFill,
        }
    end

    -- 3-Slot Build Presets Strip + 6-Color Haki Aura Swatches
    local presetStrip = UIFactory.Create("Frame", statsPanel, {
        Name = "StatPresetStrip",
        Position = UDim2.fromOffset(14, 430),
        Size = UDim2.new(1, -28, 0, 56),
        BackgroundTransparency = 1,
    })
    UIFactory.GridLayout(presetStrip, UDim2.new(0.333, -6, 0, 54), UDim2.fromOffset(8, 4))

    for pIdx = 1, 3 do
        local pDef = PRESET_DEFS[pIdx]
        local pBox = UIFactory.Create("Frame", presetStrip, {
            Name = "Preset_" .. pIdx,
            BackgroundColor3 = Color3.fromRGB(10, 15, 28),
            BorderSizePixel = 0,
            LayoutOrder = pIdx,
        })
        UIFactory.Corner(pBox, Theme.Radius.Small)
        UIFactory.Stroke(pBox, colors.ACCENT_SAPPHIRE, 1.1, 0.32)

        local pTitle = UIFactory.Label(pBox, {
            Name = "PresetTitle",
            Text = I18n.GetLanguage() == "en" and pDef.NameEn or pDef.NameVi,
            Position = UDim2.fromOffset(6, 3),
            Size = UDim2.new(1, -12, 0, 18),
            TextSize = 10,
            TextColor = colors.ACCENT_GOLD_BRIGHT,
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            Truncate = Enum.TextTruncate.AtEnd,
        })
        pTitle.TextScaled = true
        UIFactory.TextSizeConstraint(pTitle, 8, 10)

        PremiumButton.Create(pBox, {
            name = "SavePreset_" .. pIdx,
            label = I18n.Pick("LƯU", "SAVE"),
            variant = "secondary",
            position = UDim2.fromOffset(6, 24),
            size = UDim2.new(0.46, -8, 0, 24),
            textSize = 10,
            minTextSize = 8,
            onActivated = function()
                saveStatPresetSlot(pIdx)
            end,
        })

        PremiumButton.Create(pBox, {
            name = "LoadPreset_" .. pIdx,
            label = I18n.Pick("NẠP", "LOAD"),
            variant = "primary",
            position = UDim2.new(0.46, 4, 0, 24),
            size = UDim2.new(0.54, -10, 0, 24),
            textSize = 10,
            minTextSize = 8,
            onActivated = function()
                applyStatPresetSlot(pIdx)
            end,
        })
    end

    -- 6-Color Haki Swatch Strip (plus Studio Level Boost mini-pills in Studio only)
    local swatchRow = UIFactory.Create("Frame", statsPanel, {
        Name = "HakiSwatchesAndTools",
        Position = UDim2.fromOffset(14, 494),
        Size = UDim2.new(1, -28, 0, 28),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(swatchRow, Enum.FillDirection.Horizontal, 6)

    local isStudio = RunService:IsStudio()
    local swatchWidthScale = isStudio and (0.58 / 6) or (1 / 6)

    for cIdx, hc in ipairs(HAKI_COLORS) do
        local swBtn = UIFactory.Create("TextButton", swatchRow, {
            Name = "HakiColor_" .. hc.Id,
            Size = UDim2.new(swatchWidthScale, -5, 1, 0),
            BackgroundColor3 = hc.Color,
            BackgroundTransparency = 0.14,
            BorderSizePixel = 0,
            Text = "Ý CHÍ: " .. hc.Label,
            Font = Theme.Fonts.Bold,
            TextSize = 9,
            TextColor3 = Color3.fromRGB(10, 14, 24),
            AutoButtonColor = true,
            LayoutOrder = cIdx,
        })
        UIFactory.Corner(swBtn, Theme.Radius.Small)
        UIFactory.Stroke(swBtn, colors.TEXT_PRIMARY, 1.0, 0.35)
        swBtn.Activated:Connect(function()
            Skills.HakiCycleIndex = cIdx
            applyHakiAuraColor(hc)
        end)
    end

    if isStudio then
        for bIdx, bd in ipairs({
            { id = "Boost100", label = "+100 LV", payload = { action = "BoostLevel", addLevels = 100 }, variant = "secondary" },
            { id = "BoostMax", label = "MAX 2550", payload = { action = "BoostLevel", targetLevel = 2550 }, variant = "gold" },
        }) do
            PremiumButton.Create(swatchRow, {
                name = bd.id,
                label = bd.label,
                variant = bd.variant,
                size = UDim2.new(0.21, -6, 1, 0),
                layoutOrder = 10 + bIdx,
                textSize = 9,
                minTextSize = 8,
                onActivated = function()
                    fireEquipRemote(bd.payload)
                end,
            })
        end
    end

    -- Bottom Row: Crimson TẨY TOÀN BỘ ĐIỂM CHỈ SỐ + Gold ĐỔI MÀU BÁ Ý (RAINBOW SAVIOUR)
    local bottomBar = UIFactory.Create("Frame", statsPanel, {
        Name = "BottomActionRow",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 14, 1, -12),
        Size = UDim2.new(1, -28, 0, 46),
        BackgroundTransparency = 1,
    })

    PremiumButton.Create(bottomBar, {
        name = "RefundAllStatsBtn",
        icon = "Flame",
        label = I18n.Pick("TẨY TOÀN BỘ ĐIỂM CHỈ SỐ", "REFUND ALL STAT POINTS"),
        variant = "danger",
        position = UDim2.fromOffset(0, 0),
        size = UDim2.new(0.45, -5, 1, 0),
        textSize = 12,
        minTextSize = 9,
        onActivated = function()
            requestFullStatRefund()
        end,
    })

    PremiumButton.Create(bottomBar, {
        name = "CycleRainbowHakiBtn",
        icon = "Crown",
        label = I18n.Pick("ĐỔI MÀU BÁ Ý (RAINBOW SAVIOUR)", "CYCLE SOVEREIGN WILL (RAINBOW SAVIOUR)"),
        variant = "gold",
        position = UDim2.new(0.45, 5, 0, 0),
        size = UDim2.new(0.55, -5, 1, 0),
        textSize = 12,
        minTextSize = 9,
        onActivated = function()
            Skills.HakiCycleIndex = (Skills.HakiCycleIndex % #HAKI_COLORS) + 1
            applyHakiAuraColor(HAKI_COLORS[Skills.HakiCycleIndex])
        end,
    })

    -- ========================================================================
    -- RIGHT PANEL (38%): 3-CLASS SWITCHER, RIG/KATA CONTROLS & ASCENSION NODES
    -- ========================================================================
    local rightPanel = PremiumPanel.Create(root, {
        name = "ClassMasteryAndSkillTreePanel",
        variant = "gold",
        position = UDim2.new(0.62, 6, 0, 72),
        size = UDim2.new(0.38, -22, 1, -84),
    })

    UIFactory.Label(rightPanel, {
        Name = "ClassHeader",
        Text = I18n.Pick("HỆ PHÁI & CÂY KỸ NĂNG THĂNG HOA ([Q] [E] [R])", "CLASS ARCHETYPE & ASCENSION SKILL TREE"),
        Position = UDim2.fromOffset(14, 10),
        Size = UDim2.new(1, -28, 0, 20),
        TextSize = 13,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
    })

    -- Compact 3-Class Switcher Pills
    local classTabs = UIFactory.Create("Frame", rightPanel, {
        Name = "ClassSwitcherPills",
        Position = UDim2.fromOffset(14, 34),
        Size = UDim2.new(1, -28, 0, 34),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(classTabs, Enum.FillDirection.Horizontal, 6)

    for idx, cid in ipairs(WorldConfig.OrderedClasses or { "SkyGuardian", "ThunderStriker", "ArcaneMage" }) do
        local c = WorldConfig.Classes[cid]
        if c then
            local isCurrentTab = (cid == selectedClassId)
            local isEquippedClass = (cid == snap.player.classId)
            PremiumButton.Create(classTabs, {
                name = "ClassTab_" .. cid,
                icon = c.Icon or "Sword",
                label = isEquippedClass and ("[ON] " .. c.Name) or c.Name,
                variant = isCurrentTab and "gold" or "secondary",
                selected = isCurrentTab,
                size = UDim2.new(0.333, -4, 1, 0),
                textSize = 10,
                minTextSize = 8,
                layoutOrder = idx,
                onActivated = function()
                    Store.SetView({ selectedClassTab = cid })
                    ScreenRouter.Navigate(UIState.Screens.Skills, { forceRebuild = true, replace = true })
                end,
            })
        end
    end

    -- Class Multipliers, Rig Gender & 3D Kata Strip
    local classInfoBox = UIFactory.Create("Frame", rightPanel, {
        Name = "ClassRigControlBox",
        Position = UDim2.fromOffset(14, 74),
        Size = UDim2.new(1, -28, 0, 108),
        BackgroundColor3 = Color3.fromRGB(10, 15, 28),
        BorderSizePixel = 0,
    })
    UIFactory.Corner(classInfoBox, Theme.Radius.Medium)
    UIFactory.Stroke(classInfoBox, classCfg.AccentColor or colors.ACCENT_SAPPHIRE, 1.2, 0.3)

    UIFactory.Label(classInfoBox, {
        Name = "MultLine",
        Text = string.format(
            "%s  •  HP %.2fx  |  ATK %.2fx  |  DEF %.2fx  |  SPD %d",
            string.upper(classCfg.Name),
            classCfg.BaseMultipliers.HP,
            classCfg.BaseMultipliers.ATK,
            classCfg.BaseMultipliers.DEF,
            classCfg.BaseMultipliers.Speed
        ),
        Position = UDim2.fromOffset(10, 6),
        Size = UDim2.new(1, -20, 0, 18),
        TextSize = 10,
        TextColor = classCfg.AccentColor or colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
    })

    local rigRow = UIFactory.Create("Frame", classInfoBox, {
        Name = "GenderAndKataRow",
        Position = UDim2.fromOffset(10, 28),
        Size = UDim2.new(1, -20, 0, 30),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(rigRow, Enum.FillDirection.Horizontal, 5)

    for gIdx, gender in ipairs({ "Male", "Female" }) do
        local isCurG = (snap.player.gender == gender)
        PremiumButton.Create(rigRow, {
            name = "Gender_" .. gender,
            label = (gender == "Male") and I18n.Pick("NAM", "MALE") or I18n.Pick("NỮ", "FEMALE"),
            variant = isCurG and "primary" or "secondary",
            selected = isCurG,
            size = UDim2.new(0.19, -4, 1, 0),
            textSize = 9,
            minTextSize = 8,
            layoutOrder = gIdx,
            onActivated = function()
                PartyController.RequestClassOrGenderChange(selectedClassId, gender)
            end,
        })
    end

    for kIdx, kDef in ipairs({
        { id = "HeroicKata", label = "KATA" },
        { id = "ElementalSurge", label = "SURGE" },
        { id = "UltimateAwakening", label = "AWAKEN" },
    }) do
        PremiumButton.Create(rigRow, {
            name = "Kata_" .. kDef.id,
            label = kDef.label,
            variant = (kIdx == 3) and "gold" or "secondary",
            size = UDim2.new(0.206, -4, 1, 0),
            textSize = 9,
            minTextSize = 8,
            layoutOrder = 2 + kIdx,
            onActivated = function()
                fireEquipRemote({ action = "TriggerKataPose", clip = kDef.id })
            end,
        })
    end

    PremiumButton.Create(classInfoBox, {
        name = "SwitchClassButton",
        label = (selectedClassId == snap.player.classId)
            and I18n.Pick("ĐANG SỬ DỤNG HỆ PHÁI NÀY", "ACTIVE CLASS EQUIPPED")
            or (I18n.Pick("KÍCH HOẠT ", "ACTIVATE ") .. string.upper(classCfg.Name)),
        variant = (selectedClassId == snap.player.classId) and "gold" or "primary",
        position = UDim2.fromOffset(10, 66),
        size = UDim2.new(0.60, -12, 0, 32),
        textSize = 10,
        minTextSize = 8,
        onActivated = function()
            PartyController.RequestClassOrGenderChange(selectedClassId, snap.player.gender)
        end,
    })

    PremiumButton.Create(classInfoBox, {
        name = "ResetSkillsButton",
        label = I18n.Pick("ĐẶT LẠI KỸ NĂNG", "RESET SKILLS"),
        variant = "secondary",
        position = UDim2.new(0.60, 4, 0, 66),
        size = UDim2.new(0.40, -14, 0, 32),
        textSize = 10,
        minTextSize = 8,
        onActivated = function()
            fireEquipRemote({ action = "ResetSkills" })
        end,
    })

    -- Class Skills Mastery & Ascension Nodes Scroll
    local scroll = UIFactory.Create("ScrollingFrame", rightPanel, {
        Name = "SkillsScroll",
        Position = UDim2.fromOffset(14, 190),
        Size = UDim2.new(1, -28, 1, -202),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 5,
        ScrollBarImageColor3 = colors.ACCENT_SAPPHIRE,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.fromOffset(0, 0),
    })
    UIFactory.ListLayout(scroll, Enum.FillDirection.Vertical, 8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Top)

    local masByKey = { Z = 1, X = 50, C = 100, V = 200, F = 1, Q = 1, E = 50, R = 100 }
    local masTable = type(fState.mastery) == "table" and fState.mastery or {}
    local eqFruit = tostring(fState.equippedFruit or "SolarTitanCore")
    local eqStyle = tostring(fState.fightingStyle or "skyborn_combat")
    local curMastery = tonumber(masTable[selectedClassId] or masTable[eqStyle] or masTable[eqFruit]) or curLevel

    for idx, sk in ipairs(classCfg.Skills) do
        local masReq = tonumber(sk.MasteryReq) or masByKey[tostring(sk.Keybind or "")] or (sk.LevelReq or 1)
        local unlocked = (curLevel >= (sk.LevelReq or 1)) and (curMastery >= masReq)
        local row = UIFactory.Create("Frame", scroll, {
            Name = "SkillNode_" .. sk.Id,
            Size = UDim2.new(1, -6, 0, 82),
            BackgroundColor3 = unlocked and Color3.fromRGB(14, 22, 42) or colors.BG_900,
            BackgroundTransparency = 0.06,
            BorderSizePixel = 0,
            LayoutOrder = idx,
        })
        UIFactory.Corner(row, Theme.Radius.Medium)
        UIFactory.Stroke(
            row,
            unlocked and (sk.Type == "Ultimate" and colors.ACCENT_GOLD or colors.ACCENT_SAPPHIRE) or colors.STROKE_STEEL,
            1.3,
            unlocked and 0.18 or 0.5
        )

        UIFactory.Icon(row, sk.Icon, UDim2.fromOffset(12, 22), 36, unlocked and classCfg.AccentColor or colors.TEXT_SECONDARY)

        UIFactory.Badge(
            row,
            "[" .. sk.Keybind .. "] " .. string.upper(sk.Type),
            UDim2.fromOffset(58, 8),
            UDim2.fromOffset(92, 20),
            sk.Type == "Ultimate" and colors.ACCENT_GOLD or colors.ACCENT_SAPPHIRE,
            colors.TEXT_PRIMARY
        )

        UIFactory.Label(row, {
            Name = "SkillName",
            Text = sk.Name,
            Position = UDim2.fromOffset(156, 7),
            Size = UDim2.new(1, -270, 0, 22),
            TextSize = 12,
            TextColor = unlocked and colors.TEXT_PRIMARY or colors.TEXT_SECONDARY,
            Bold = true,
            Truncate = Enum.TextTruncate.AtEnd,
        })

        UIFactory.Label(row, {
            Name = "SkillMetrics",
            Text = string.format("Mas. %d • Lv.%d • CD %.1fs", masReq, sk.LevelReq or 1, sk.Cooldown or 0),
            Position = UDim2.new(1, -124, 0, 9),
            Size = UDim2.fromOffset(114, 18),
            TextSize = 10,
            TextColor = unlocked and colors.ACCENT_GOLD or colors.TEXT_SECONDARY,
            Bold = true,
            XAlign = Enum.TextXAlignment.Right,
        })

        UIFactory.Label(row, {
            Name = "SkillDesc",
            Text = unlocked and sk.Description or (I18n.Pick("Mở ở Mastery " .. tostring(masReq) .. " — ", "Unlocks at Mas. " .. tostring(masReq) .. " — ") .. tostring(sk.Description)),
            Position = UDim2.fromOffset(58, 32),
            Size = UDim2.new(1, -154, 0, 42),
            TextSize = 10,
            TextColor = colors.TEXT_SECONDARY,
            YAlign = Enum.TextYAlignment.Top,
            Wrapped = true,
        })

        UIFactory.Badge(
            row,
            unlocked and I18n.Pick("ĐÃ MỞ", "UNLOCKED") or ("Mas. " .. tostring(masReq)),
            UDim2.new(1, -90, 0, 44),
            UDim2.fromOffset(80, 22),
            unlocked and colors.SUCCESS or colors.STROKE_STEEL,
            unlocked and colors.SUCCESS or colors.TEXT_SECONDARY
        )
    end

    return root
end

function Skills.Update(snap)
    local refs = Skills.Refs
    if not refs or not refs.Root or not refs.Root.Parent then
        return
    end
    snap = snap or Store.GetSnapshot()
    if refs.HeaderRefs and refs.HeaderRefs.UpdateCurrencies then
        refs.HeaderRefs.UpdateCurrencies(snap)
    end
    local fState = snap.fruits or {}
    local statAlloc = fState.statAlloc or { Melee = 1, Defense = 1, Sword = 1, Gun = 1, Fruit = 1 }
    local statPoints = tonumber(fState.statPoints) or 0

    if refs.StatPointsBanner then
        refs.StatPointsBanner.Text = string.format(
            "%s: %s %s",
            I18n.Pick("ĐIỂM CHƯA CỘNG", "UNSPENT"),
            UIFactory.FormatNumber(statPoints),
            I18n.Pick("ĐIỂM", "PTS")
        )
    end
    if refs.StatRows then
        for _, st in ipairs(STAT_CATEGORIES) do
            local rRef = refs.StatRows[st.key]
            if rRef then
                local curVal = math.clamp(tonumber(statAlloc[st.key]) or 1, 1, MAX_STAT)
                local ratio = math.clamp(curVal / MAX_STAT, 0, 1)
                if rRef.ValueLabel then
                    rRef.ValueLabel.Text = string.format("LV. %d / %d%s", curVal, MAX_STAT, curVal >= MAX_STAT and " [MAX]" or "")
                end
                if rRef.BarFill then
                    rRef.BarFill.Size = UDim2.fromScale(math.max(0.03, ratio), 1)
                end
            end
        end
    end
end

function Skills.Cleanup()
    Skills.Refs = {}
end

return Skills
