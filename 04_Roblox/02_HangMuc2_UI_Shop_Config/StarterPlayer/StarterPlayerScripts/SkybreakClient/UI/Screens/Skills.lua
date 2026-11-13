-- SKYBREAK: Fragments of the Core — Lv. 2550 Glossy Segmented Stats, 3-Slot Presets & Class Ascension Screen ([K])
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/Skills.lua
-- Visual Upgrade: Matches Figma Design File 3 (SKYBREAK_NPC_06 Panel 2) 1:1 with 5 Horizontal Glossy Segmented
-- Stat Cards (+1 / +10 / +MAX), Top-Right Gold Unspent Points Pill, Bottom Crimson Stat Refund & Gold Rainbow Haki
-- Buttons, 3-Slot Build Presets, and Right-Column 3-Class Switcher + Mastery Nodes.

local Players = game:GetService("Players")
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
        subVi = "+Sát Thương Võ & +Max Energy",
        subEn = "+Martial Damage & +Max Energy",
        gradTop = Color3.fromRGB(252, 211, 77),
        gradBottom = Color3.fromRGB(180, 83, 9),
        accent = Color3.fromRGB(252, 211, 77),
    },
    {
        key = "Defense",
        icon = "Shield",
        titleVi = "PHÒNG THỦ (DEFENSE)",
        titleEn = "DEFENSE & VITALITY",
        subVi = "+Máu (HP) & +Giáp (DEF)",
        subEn = "+Max HP & +Armor (DEF)",
        gradTop = Color3.fromRGB(251, 113, 133),
        gradBottom = Color3.fromRGB(225, 29, 72),
        accent = Color3.fromRGB(251, 113, 133),
    },
    {
        key = "Sword",
        icon = "Sword",
        titleVi = "KIẾM THUẬT (SWORD)",
        titleEn = "SWORD MASTERY",
        subVi = "+Sát Thương Kiếm (Slot 3)",
        subEn = "+Sword Damage (Slot 3)",
        gradTop = Color3.fromRGB(96, 165, 250),
        gradBottom = Color3.fromRGB(29, 78, 216),
        accent = Color3.fromRGB(96, 165, 250),
    },
    {
        key = "Gun",
        icon = "Gun",
        titleVi = "PHÁP KHÍ SÚNG (GUN)",
        titleEn = "ARCANE GUNNERY",
        subVi = "+Sát Thương Súng (Slot 4)",
        subEn = "+Gun Damage (Slot 4)",
        gradTop = Color3.fromRGB(56, 189, 248),
        gradBottom = Color3.fromRGB(2, 132, 199),
        accent = Color3.fromRGB(56, 189, 248),
    },
    {
        key = "Fruit",
        icon = "Fruit",
        titleVi = "LÕI AETHER (FRUIT)",
        titleEn = "AETHER CORE",
        subVi = "+Sát Thương Lõi Aether (Slot 2)",
        subEn = "+Aether Core Damage (Slot 2)",
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
    { Id = "Gold", ServerIds = { "solar_gold" }, Label = "GOLD", Color = Color3.fromRGB(244, 193, 78) },
    { Id = "Crimson", ServerIds = { "crimson_conqueror" }, Label = "RED", Color = Color3.fromRGB(244, 63, 94) },
    { Id = "Cyan", ServerIds = { "glacial_cyan", "cryo_cyan" }, Label = "CYAN", Color = Color3.fromRGB(56, 189, 248) },
    { Id = "Violet", ServerIds = { "abyssal_violet", "void_violet" }, Label = "VOID", Color = Color3.fromRGB(168, 85, 247) },
    { Id = "Emerald", ServerIds = { "verdant_emerald", "emerald_jade" }, Label = "JADE", Color = Color3.fromRGB(52, 211, 153) },
    { Id = "Rainbow", ServerIds = { "prismatic_aether", "pure_white", "sakura_pink" }, Label = "PRISM", Color = Color3.fromRGB(251, 113, 133) },
}

local HAKI_CANONICAL_FALLBACK = {
    Gold = "solar_gold",
    Crimson = "crimson_conqueror",
    Cyan = "glacial_cyan",
    Violet = "abyssal_violet",
    Emerald = "verdant_emerald",
    Rose = "prismatic_aether",
    Rainbow = "prismatic_aether",
}

local SharedCombatData = nil
local CoreSharedConfig = nil
pcall(function()
    local sh = ReplicatedStorage:FindFirstChild("Shared")
    local mod = sh and sh:FindFirstChild("SkybreakCombatData")
    if mod and mod:IsA("ModuleScript") then
        SharedCombatData = require(mod)
    end
    local cfgMod = sh and sh:FindFirstChild("Config")
    if cfgMod and cfgMod:IsA("ModuleScript") then
        CoreSharedConfig = require(cfgMod)
    end
end)

local function formatStatRefundButtonLabel(snap)
    local fState = (snap and snap.fruits) or {}
    local tokens = math.max(0, math.floor(tonumber((snap and snap.StatRefundTokens) or fState.statRefundTokens) or 0))
    local costShards = math.max(1, math.floor(tonumber(CoreSharedConfig and CoreSharedConfig.StatRefundCostShards) or 150))
    if tokens > 0 then
        return I18n.Pick(
            string.format("TẨY ĐIỂM (VÉ MIỄN PHÍ x%d)", tokens),
            string.format("REFUND STATS (FREE TOKEN x%d)", tokens)
        ), tokens, costShards
    end
    return I18n.Pick(
        string.format("TẨY TOÀN BỘ ĐIỂM (%d SHARDS)", costShards),
        string.format("REFUND ALL STATS (%d SHARDS)", costShards)
    ), 0, costShards
end

local function resolveHakiServerColorId(hc)
    if not hc then
        return "crimson_conqueror"
    end
    local catalog = SharedCombatData and SharedCombatData.HakiColors
    if type(catalog) == "table" and type(hc.ServerIds) == "table" then
        for _, cand in ipairs(hc.ServerIds) do
            if catalog[cand] ~= nil then
                return cand
            end
        end
    end
    return HAKI_CANONICAL_FALLBACK[hc.Id] or (hc.ServerIds and hc.ServerIds[1]) or tostring(hc.Id)
end

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
    local sharedRemotes = Shared:FindFirstChild("Remotes")
    if sharedRemotes and sharedRemotes:FindFirstChild("UIRequest") then
        sharedRemotes.UIRequest:FireServer(actionName, payload or {})
        return
    end
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes and remotes:FindFirstChild("UIRequest") then
        remotes.UIRequest:FireServer(actionName, payload or {})
    elseif sharedRemotes and sharedRemotes:FindFirstChild("UICommand") then
        sharedRemotes.UICommand:FireServer(actionName, payload or {})
    end
end

local function computeLiveBranchStats(snap)
    local s = (snap and snap.stats) or {}
    local v = (snap and snap.vitals) or {}
    local lv = math.max(1, tonumber(snap and snap.player and snap.player.level) or 1)
    local alloc = (snap and snap.fruits and snap.fruits.statAlloc) or {}
    local mPts = math.max(0, tonumber(alloc.Melee) or 1)
    local dPts = math.max(0, tonumber(alloc.Defense) or 1)
    local swPts = math.max(0, tonumber(alloc.Sword) or 1)
    local gPts = math.max(0, tonumber(alloc.Gun) or 1)
    local fPts = math.max(0, tonumber(alloc.Fruit) or 1)
    local baseB = math.max(12, math.floor(12 + 0.07 * (lv - 1)))

    local meleeAtk = math.max(1, math.floor(tonumber(s.meleeAtk) or (baseB + mPts * 0.22)))
    local swordAtk = math.max(1, math.floor(tonumber(s.swordAtk) or (baseB + swPts * 0.22)))
    local gunAtk = math.max(1, math.floor(tonumber(s.gunAtk) or (baseB + gPts * 0.22)))
    local fruitAtk = math.max(1, math.floor(tonumber(s.fruitAtk) or (baseB + fPts * 0.22)))
    local maxEn = math.max(100, math.floor(tonumber(s.maxEnergy or v.maxEnergy) or (100 + mPts * 0.45 + (lv - 1) * 0.04)))
    local maxHp = math.max(100, math.floor(tonumber(s.hp or v.maxHp) or (100 + dPts * 4.5)))
    local defVal = math.max(1, math.floor(tonumber(s.def) or (10 + dPts * 0.35)))
    return {
        MeleeATK = meleeAtk,
        SwordATK = swordAtk,
        GunATK = gunAtk,
        FruitATK = fruitAtk,
        MaxEnergy = maxEn,
        HP = maxHp,
        DEF = defVal,
    }
end

local function formatBranchPreviewLabel(statKey, curVal, bStats)
    local capSuffix = (curVal >= MAX_STAT) and " [MAX]" or ""
    if statKey == "Melee" then
        return string.format(
            "LV. %d/%d%s • %s %s | EN %s",
            curVal,
            MAX_STAT,
            capSuffix,
            I18n.Pick("Võ", "Melee"),
            UIFactory.FormatNumber(bStats.MeleeATK),
            UIFactory.FormatNumber(bStats.MaxEnergy)
        )
    elseif statKey == "Defense" then
        return string.format("LV. %d/%d%s • HP %s | DEF %s", curVal, MAX_STAT, capSuffix, UIFactory.FormatNumber(bStats.HP), UIFactory.FormatNumber(bStats.DEF))
    elseif statKey == "Sword" then
        return string.format("LV. %d/%d%s • %s %s", curVal, MAX_STAT, capSuffix, I18n.Pick("Kiếm", "Sword"), UIFactory.FormatNumber(bStats.SwordATK))
    elseif statKey == "Gun" then
        return string.format("LV. %d/%d%s • %s %s", curVal, MAX_STAT, capSuffix, I18n.Pick("Súng", "Gun"), UIFactory.FormatNumber(bStats.GunATK))
    else
        return string.format("LV. %d/%d%s • %s %s", curVal, MAX_STAT, capSuffix, I18n.Pick("Lõi", "Core"), UIFactory.FormatNumber(bStats.FruitATK))
    end
end

local function formatRaceEvolutionInfo(snap)
    local fState = (snap and snap.fruits) or {}
    local raceName = tostring(fState.race or "Skyborn")
    local v4Unlocked = (fState.raceV4Unlocked == true)
    local rTier = math.clamp(math.floor(tonumber(fState.raceTier) or (v4Unlocked and 4 or 1)), 1, 4)
    if v4Unlocked and rTier < 4 then
        rTier = 4
    end
    local headerTxt = I18n.Pick(
        string.format("HUYẾT MẠCH TỘC: %s • V%d", UIFactory.Upper(raceName), rTier),
        string.format("LINEAGE: %s • V%d", UIFactory.Upper(raceName), rTier)
    )
    local reqTxt, btnTxt, canEvolve = "", "", false
    local pLv = tonumber(snap and snap.player and snap.player.level) or 1
    local curGold = tonumber((snap and snap.currency and snap.currency.gold) or 0) or 0
    local curShards = tonumber((snap and snap.currency and snap.currency.coreShards) or 0) or 0

    if rTier == 1 then
        reqTxt = I18n.Pick(
            "V1 -> V2: Yêu cầu Lv.350+ & 250,000 Gold (+6% ATK, +8% DEF, +8% Tốc Chạy)",
            "V1 -> V2: Req Lv.350+ & 250,000 Gold (+6% ATK, +8% DEF, +8% Speed)"
        )
        btnTxt = I18n.Pick("TIẾN HÓA V1 -> V2", "EVOLVE V1 -> V2")
        canEvolve = (pLv >= 350 and curGold >= 250000)
    elseif rTier == 2 then
        reqTxt = I18n.Pick(
            "V2 -> V3: Yêu cầu Lv.850+, 750,000 Gold & 500 Shards (+12% ATK, +15% DEF, +14% Tốc Chạy)",
            "V2 -> V3: Req Lv.850+, 750K Gold & 500 Shards (+12% ATK, +15% DEF, +14% Speed)"
        )
        btnTxt = I18n.Pick("TIẾN HÓA V2 -> V3", "EVOLVE V2 -> V3")
        canEvolve = (pLv >= 850 and curGold >= 750000 and curShards >= 500)
    elseif rTier == 3 then
        reqTxt = I18n.Pick(
            "Đã đạt Tộc V3! Đạt Lv.1900+ & đến Đền Thăng Hoa (Sea 3) để mở Khảo Thí Tộc V4.",
            "Lineage V3 active! Reach Lv.1900+ & visit Temple of the Core (Sea 3) for V4 Trial."
        )
        btnTxt = I18n.Pick("ĐÃ ĐẠT TỘC V3", "V3 UNLOCKED")
        canEvolve = false
    else
        reqTxt = I18n.Pick(
            "Đã thức tỉnh Cảnh Giới Huyết Mạch Tộc V4 Tối Thượng (+30% Toàn Chỉ Số khi bật [Y])!",
            "Supreme Lineage V4 Awakened (+30% All Stats while [Y] Ascension is active)!"
        )
        btnTxt = I18n.Pick("TỘC V4 TỐI THƯỢNG", "MAX TIER V4")
        canEvolve = false
    end
    return headerTxt, reqTxt, btnTxt, rTier, canEvolve
end

local function applyHakiAuraColor(hc)
    if not hc then
        return
    end
    local mappedId = resolveHakiServerColorId(hc)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes and remotes:FindFirstChild("UIRequest") then
        remotes.UIRequest:FireServer("EquipHakiColor", { colorId = mappedId })
    elseif remotes and remotes:FindFirstChild("AppearanceRequest") then
        remotes.AppearanceRequest:FireServer({ action = "EquipHakiColor", colorId = mappedId })
    end
    local snap = Store.GetSnapshot()
    local unlockedMap = snap and snap.unlockedHakiColors
    if snap and snap.isDemoMode or (type(unlockedMap) == "table" and unlockedMap[mappedId] == true) or mappedId == "crimson_conqueror" then
        Store.ShowToast(
            I18n.Pick("Đã kích hoạt Sắc Màu Bá Ý: ", "Activated Sovereign Will Aura: ") .. hc.Label,
            "success",
            2.0
        )
    end
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

local ARSENAL_SLOT_SPECS = {
    { slot = 1, icon = "Fist", keys = { "Z", "X", "C" }, accent = Color3.fromRGB(252, 211, 77) },
    { slot = 2, icon = "Fruit", keys = { "Z", "X", "C", "V", "F" }, accent = Color3.fromRGB(232, 121, 249) },
    { slot = 3, icon = "Sword", keys = { "Z", "X" }, accent = Color3.fromRGB(96, 165, 250) },
    { slot = 4, icon = "Gun", keys = { "Z", "X" }, accent = Color3.fromRGB(56, 189, 248) },
}

local function buildArsenalSlotDisplay(slotIdx, snap)
    local p = Players.LocalPlayer
    local ch = p and p.Character
    local fState = (snap and snap.fruits) or {}
    local eqState = (snap and snap.equipped) or {}
    local rawId = ""

    if slotIdx == 1 then
        rawId = tostring(
            (p and (p:GetAttribute("FightingStyle") or p:GetAttribute("EquippedStyle")))
            or fState.fightingStyle
            or (snap and snap.equippedStyle)
            or "skyborn_combat"
        )
        rawId = I18n.ResolveCanonicalStyleId(rawId)
    elseif slotIdx == 2 then
        rawId = tostring((p and p:GetAttribute("EquippedFruit")) or fState.equippedFruit or "")
        rawId = I18n.ResolveCanonicalCoreId(rawId)
    elseif slotIdx == 3 then
        rawId = tostring((p and p:GetAttribute("EquippedSword")) or eqState.Weapon or "starter_sword")
        if rawId == "" then
            rawId = "starter_sword"
        end
    else
        rawId = tostring(
            (p and p:GetAttribute("EquippedGun"))
            or fState.equippedGun
            or eqState.EquippedGun
            or eqState.Gun
            or eqState.Offhand
            or "aether_flintlock"
        )
        if rawId == "" then
            rawId = "aether_flintlock"
        end
    end

    local ctx = {
        Awakened = (fState.awakened == true) or (p and p:GetAttribute("FruitAwakened") == true) or false,
        DragonFormTier = tonumber((ch and ch:GetAttribute("DragonFormTier")) or (p and p:GetAttribute("DragonFormTier")) or (snap and snap.raw and snap.raw.DragonFormTier)) or 0,
        FruitTransform = tostring((ch and ch:GetAttribute("FruitTransform")) or (p and p:GetAttribute("FruitTransform")) or ""),
    }

    local slotLabel = I18n.T("hud.slot." .. tostring(slotIdx))
    if slotIdx == 2 and rawId == "" then
        return {
            title = string.format("[%d] %s: %s", slotIdx, slotLabel, I18n.Pick("Chưa Trang Bị", "Unequipped")),
            badge = I18n.Pick("TRỐNG", "EMPTY"),
            movesText = I18n.Pick("Quay hoặc ăn Lõi Aether [G] để mở khóa cơ chế [Z][X][C][V][F].", "Roll or equip an Aether Core [G] to unlock [Z][X][C][V][F] mechanics."),
        }
    end

    local itemName = I18n.GetItemDisplayName(rawId, rawId)
    local slotArch = I18n.GetSlotArchetypeMeta(slotIdx, rawId, ctx)
    local specDef = ARSENAL_SLOT_SPECS[slotIdx]
    local moveParts = {}

    for _, k in ipairs(specDef.keys) do
        local mMeta = I18n.GetSkillMechanicsMeta(slotIdx, rawId, k, ctx)
        local tagList = {}
        for tIdx = 1, math.min(2, #mMeta.tags) do
            table.insert(tagList, "[" .. mMeta.tags[tIdx] .. "]")
        end
        local tagJoined = (#tagList > 0) and (" " .. table.concat(tagList, " ")) or ""
        table.insert(moveParts, string.format("[%s] %s%s", k, mMeta.archetypeLabel, tagJoined))
    end

    return {
        title = string.format("[%d] %s: %s", slotIdx, slotLabel, itemName),
        badge = UIFactory.Upper(slotArch.archetypeLabel),
        movesText = table.concat(moveParts, "  •  "),
    }
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
        ArsenalCards = {},
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
    local liveBranchStats = computeLiveBranchStats(snap)
    local barsContainer = UIFactory.Create("Frame", statsPanel, {
        Name = "FiveStatCardsContainer",
        Position = UDim2.fromOffset(14, 42),
        Size = UDim2.new(1, -28, 0, 344),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(barsContainer, Enum.FillDirection.Vertical, 6)

    for idx, st in ipairs(STAT_CATEGORIES) do
        local curVal = math.clamp(tonumber(statAlloc[st.key]) or 1, 1, MAX_STAT)
        local ratio = math.clamp(curVal / MAX_STAT, 0, 1)

        local sCard = UIFactory.Create("Frame", barsContainer, {
            Name = "StatCard_" .. st.key,
            Size = UDim2.new(1, 0, 0, 64),
            BackgroundColor3 = Color3.fromRGB(11, 17, 32),
            BorderSizePixel = 0,
            LayoutOrder = idx,
        })
        UIFactory.Corner(sCard, Theme.Radius.Medium)
        UIFactory.Stroke(sCard, st.accent, 1.3, 0.28)

        -- Left: Icon Crest + Bold Uppercase Title & Descriptive Subtitle
        local iconBox = UIFactory.Create("Frame", sCard, {
            Name = "StatCrest",
            Position = UDim2.fromOffset(10, 12),
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
            Position = UDim2.fromOffset(58, 9),
            Size = UDim2.fromOffset(192, 20),
            TextSize = 12,
            TextColor = st.accent,
            Bold = true,
            Truncate = Enum.TextTruncate.AtEnd,
        })

        UIFactory.Label(sCard, {
            Name = "StatSub",
            Text = I18n.GetLanguage() == "en" and st.subEn or st.subVi,
            Position = UDim2.fromOffset(58, 30),
            Size = UDim2.fromOffset(192, 24),
            TextSize = 10,
            TextColor = colors.TEXT_SECONDARY,
            Wrapped = true,
        })

        -- Center: Glossy Segmented Progress Bar with Centered Bold Live Branch Preview
        local barTrack = UIFactory.Create("Frame", sCard, {
            Name = "SegmentedTrack",
            Position = UDim2.fromOffset(256, 17),
            Size = UDim2.new(1, -468, 0, 30),
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
            Text = formatBranchPreviewLabel(st.key, curVal, liveBranchStats),
            Size = UDim2.fromScale(1, 1),
            TextSize = 11,
            TextColor = Color3.fromRGB(255, 255, 255),
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            Truncate = Enum.TextTruncate.AtEnd,
            Wrapped = false,
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

    -- Live Separated 5-Branch Combat Breakdown Strip (MeleeATK / SwordATK / GunATK / FruitATK / MaxEnergy)
    local breakdownBox = UIFactory.Create("Frame", statsPanel, {
        Name = "LiveBranchBreakdownBox",
        Position = UDim2.fromOffset(14, 392),
        Size = UDim2.new(1, -28, 0, 30),
        BackgroundColor3 = Color3.fromRGB(9, 14, 27),
        BorderSizePixel = 0,
    })
    UIFactory.Corner(breakdownBox, Theme.Radius.Small)
    UIFactory.Stroke(breakdownBox, colors.ACCENT_SAPPHIRE, 1.1, 0.28)

    refs.BranchBreakdownLabel = UIFactory.Label(breakdownBox, {
        Name = "BreakdownText",
        Text = string.format(
            "MeleeATK: %s  |  SwordATK: %s  |  GunATK: %s  |  FruitATK: %s  |  MaxEnergy: %s  |  HP: %s • DEF: %s",
            UIFactory.FormatNumber(liveBranchStats.MeleeATK),
            UIFactory.FormatNumber(liveBranchStats.SwordATK),
            UIFactory.FormatNumber(liveBranchStats.GunATK),
            UIFactory.FormatNumber(liveBranchStats.FruitATK),
            UIFactory.FormatNumber(liveBranchStats.MaxEnergy),
            UIFactory.FormatNumber(liveBranchStats.HP),
            UIFactory.FormatNumber(liveBranchStats.DEF)
        ),
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -20, 1, 0),
        TextSize = 11,
        TextColor = Color3.fromRGB(224, 242, 254),
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
    })
    UIFactory.TextSizeConstraint(refs.BranchBreakdownLabel, 8, 11)

    -- 3-Slot Build Presets Strip + 6-Color Haki Aura Swatches
    local presetStrip = UIFactory.Create("Frame", statsPanel, {
        Name = "StatPresetStrip",
        Position = UDim2.fromOffset(14, 427),
        Size = UDim2.new(1, -28, 0, 50),
        BackgroundTransparency = 1,
    })
    UIFactory.GridLayout(presetStrip, UDim2.new(0.333, -6, 0, 48), UDim2.fromOffset(8, 4))

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
        Position = UDim2.fromOffset(14, 482),
        Size = UDim2.new(1, -28, 0, 26),
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
            Text = I18n.Pick("Ý CHÍ: ", "WILL: ") .. hc.Label,
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

    -- Race Lineage Evolution Card (V1 -> V2 -> V3 -> V4) firing UIRequest:FireServer("EvolveRace", {})
    local initRaceHeader, initRaceReq, initRaceBtnTxt, initRaceTier, initCanEvolve = formatRaceEvolutionInfo(snap)
    local raceEvoCard = UIFactory.Create("Frame", statsPanel, {
        Name = "RaceEvolutionCard",
        Position = UDim2.fromOffset(14, 514),
        Size = UDim2.new(1, -28, 0, 56),
        BackgroundColor3 = Color3.fromRGB(12, 18, 36),
        BorderSizePixel = 0,
    })
    UIFactory.Corner(raceEvoCard, Theme.Radius.Medium)
    local raceEvoStroke = UIFactory.Stroke(
        raceEvoCard,
        initRaceTier >= 3 and colors.ACCENT_GOLD_BRIGHT or Color3.fromRGB(192, 132, 252),
        1.3,
        0.18
    )
    refs.RaceEvoStroke = raceEvoStroke

    UIFactory.Icon(raceEvoCard, "Wing", UDim2.fromOffset(12, 15), 26, colors.ACCENT_GOLD_BRIGHT)

    refs.RaceHeaderLabel = UIFactory.Label(raceEvoCard, {
        Name = "RaceHeaderText",
        Text = initRaceHeader,
        Position = UDim2.fromOffset(46, 6),
        Size = UDim2.new(1, -242, 0, 20),
        TextSize = 12,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
    })

    refs.RaceReqLabel = UIFactory.Label(raceEvoCard, {
        Name = "RaceReqText",
        Text = initRaceReq,
        Position = UDim2.fromOffset(46, 26),
        Size = UDim2.new(1, -242, 0, 24),
        TextSize = 10,
        TextColor = colors.TEXT_SECONDARY,
        Wrapped = true,
    })

    local _, evolveRaceBtnApi = PremiumButton.Create(raceEvoCard, {
        name = "EvolveRaceButton",
        icon = "Sparkle",
        label = initRaceBtnTxt,
        variant = initCanEvolve and "gold" or "primary",
        anchorPoint = Vector2.new(1, 0.5),
        position = UDim2.new(1, -10, 0.5, 0),
        size = UDim2.fromOffset(180, 36),
        textSize = 11,
        minTextSize = 8,
        onActivated = function()
            fireUIRequest("EvolveRace", {})
        end,
    })
    refs.EvolveRaceBtnApi = evolveRaceBtnApi

    -- Bottom Row: Crimson TẨY TOÀN BỘ ĐIỂM CHỈ SỐ + Gold ĐỔI MÀU BÁ Ý (HÀO QUANG THẤT SẮC)
    local bottomBar = UIFactory.Create("Frame", statsPanel, {
        Name = "BottomActionRow",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 14, 1, -10),
        Size = UDim2.new(1, -28, 0, 42),
        BackgroundTransparency = 1,
    })

    local initRefundLbl = formatStatRefundButtonLabel(snap)
    local _, refundStatsBtnApi = PremiumButton.Create(bottomBar, {
        name = "RefundAllStatsBtn",
        icon = "Flame",
        label = initRefundLbl,
        variant = "danger",
        position = UDim2.fromOffset(0, 0),
        size = UDim2.new(0.45, -5, 1, 0),
        textSize = 12,
        minTextSize = 9,
        onActivated = function()
            requestFullStatRefund()
        end,
    })
    refs.RefundStatsBtnApi = refundStatsBtnApi

    PremiumButton.Create(bottomBar, {
        name = "CycleRainbowHakiBtn",
        icon = "Crown",
        label = I18n.Pick("ĐỔI MÀU BÁ Ý (HÀO QUANG THẤT SẮC)", "CYCLE SOVEREIGN WILL (PRISMATIC AETHER)"),
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
            UIFactory.Upper(classCfg.Name),
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
            or (I18n.Pick("KÍCH HOẠT ", "ACTIVATE ") .. UIFactory.Upper(classCfg.Name)),
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

    -- Stage 1: Equipped 4-Slot Arsenal Archetypes & Mechanical Tag Breakdown (Slots [1]-[4])
    local arsenalHeaderBox = UIFactory.Create("Frame", scroll, {
        Name = "ArsenalSectionHeader",
        Size = UDim2.new(1, -6, 0, 24),
        BackgroundColor3 = Color3.fromRGB(16, 26, 48),
        BorderSizePixel = 0,
        LayoutOrder = 1,
    })
    UIFactory.Corner(arsenalHeaderBox, 6)
    UIFactory.Stroke(arsenalHeaderBox, colors.ACCENT_GOLD_BRIGHT, 1.1, 0.28)
    UIFactory.Label(arsenalHeaderBox, {
        Name = "ArsenalHeaderLabel",
        Text = I18n.T("skills.arsenal_header"),
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -20, 1, 0),
        TextSize = 10,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
    })

    for _, sSpec in ipairs(ARSENAL_SLOT_SPECS) do
        local info = buildArsenalSlotDisplay(sSpec.slot, snap)
        local aCard = UIFactory.Create("Frame", scroll, {
            Name = "ArsenalSlot_" .. tostring(sSpec.slot),
            Size = UDim2.new(1, -6, 0, (sSpec.slot == 2) and 74 or 62),
            BackgroundColor3 = Color3.fromRGB(12, 19, 36),
            BackgroundTransparency = 0.05,
            BorderSizePixel = 0,
            LayoutOrder = 1 + sSpec.slot,
        })
        UIFactory.Corner(aCard, Theme.Radius.Medium)
        UIFactory.Stroke(aCard, sSpec.accent, 1.2, 0.28)

        UIFactory.Icon(aCard, sSpec.icon, UDim2.fromOffset(10, 10), 22, sSpec.accent)

        local titleLbl = UIFactory.Label(aCard, {
            Name = "SlotTitle",
            Text = info.title,
            Position = UDim2.fromOffset(38, 6),
            Size = UDim2.new(1, -166, 0, 18),
            TextSize = 11,
            TextColor = colors.TEXT_PRIMARY,
            Bold = true,
            Truncate = Enum.TextTruncate.AtEnd,
        })

        local archPill = UIFactory.Create("Frame", aCard, {
            Name = "ArchetypeBadgePill",
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -8, 0, 5),
            Size = UDim2.fromOffset(120, 18),
            BackgroundColor3 = Color3.fromRGB(18, 28, 52),
            BorderSizePixel = 0,
        })
        UIFactory.PillCorner(archPill)
        UIFactory.Stroke(archPill, sSpec.accent, 1.1, 0.2)

        local archBadgeLbl = UIFactory.Label(archPill, {
            Name = "ArchetypeText",
            Text = info.badge,
            Position = UDim2.fromOffset(6, 0),
            Size = UDim2.new(1, -12, 1, 0),
            TextSize = 8,
            TextColor = sSpec.accent,
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            Truncate = Enum.TextTruncate.AtEnd,
        })

        local movesLbl = UIFactory.Label(aCard, {
            Name = "MovesTagSummary",
            Text = info.movesText,
            Position = UDim2.fromOffset(38, 25),
            Size = UDim2.new(1, -46, 1, -29),
            TextSize = 9,
            TextColor = colors.TEXT_SECONDARY,
            YAlign = Enum.TextYAlignment.Top,
            Wrapped = true,
        })

        refs.ArsenalCards[sSpec.slot] = {
            TitleLabel = titleLbl,
            BadgeLabel = archBadgeLbl,
            MovesLabel = movesLbl,
        }
    end

    local classTreeDivider = UIFactory.Create("Frame", scroll, {
        Name = "ClassTreeSectionHeader",
        Size = UDim2.new(1, -6, 0, 22),
        BackgroundColor3 = Color3.fromRGB(14, 22, 42),
        BorderSizePixel = 0,
        LayoutOrder = 9,
    })
    UIFactory.Corner(classTreeDivider, 6)
    UIFactory.Stroke(classTreeDivider, classCfg.AccentColor or colors.ACCENT_SAPPHIRE, 1, 0.35)
    UIFactory.Label(classTreeDivider, {
        Name = "ClassTreeHeaderLabel",
        Text = I18n.Pick("KỸ NĂNG HỆ PHÁI THĂNG HOA ([Q] [E] [R])", "CLASS ASCENSION SKILLS ([Q] [E] [R])"),
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -20, 1, 0),
        TextSize = 10,
        TextColor = classCfg.AccentColor or colors.ACCENT_SAPPHIRE,
        Bold = true,
    })

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
            LayoutOrder = 10 + idx,
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
            "[" .. sk.Keybind .. "] " .. UIFactory.Upper(sk.Type),
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
    local liveB = computeLiveBranchStats(snap)
    if refs.StatRows then
        for _, st in ipairs(STAT_CATEGORIES) do
            local rRef = refs.StatRows[st.key]
            if rRef then
                local curVal = math.clamp(tonumber(statAlloc[st.key]) or 1, 1, MAX_STAT)
                local ratio = math.clamp(curVal / MAX_STAT, 0, 1)
                if rRef.ValueLabel then
                    rRef.ValueLabel.Text = formatBranchPreviewLabel(st.key, curVal, liveB)
                end
                if rRef.BarFill then
                    rRef.BarFill.Size = UDim2.fromScale(math.max(0.03, ratio), 1)
                end
            end
        end
    end
    if refs.BranchBreakdownLabel then
        refs.BranchBreakdownLabel.Text = string.format(
            "MeleeATK: %s  |  SwordATK: %s  |  GunATK: %s  |  FruitATK: %s  |  MaxEnergy: %s  |  HP: %s • DEF: %s",
            UIFactory.FormatNumber(liveB.MeleeATK),
            UIFactory.FormatNumber(liveB.SwordATK),
            UIFactory.FormatNumber(liveB.GunATK),
            UIFactory.FormatNumber(liveB.FruitATK),
            UIFactory.FormatNumber(liveB.MaxEnergy),
            UIFactory.FormatNumber(liveB.HP),
            UIFactory.FormatNumber(liveB.DEF)
        )
    end
    if refs.RaceHeaderLabel and refs.RaceReqLabel then
        local rHead, rReq, rBtn, rTier = formatRaceEvolutionInfo(snap)
        refs.RaceHeaderLabel.Text = rHead
        refs.RaceReqLabel.Text = rReq
        if refs.EvolveRaceBtnApi then
            refs.EvolveRaceBtnApi:Update({ label = rBtn })
        end
        if refs.RaceEvoStroke then
            refs.RaceEvoStroke.Color = (rTier >= 3) and Theme.Colors.ACCENT_GOLD_BRIGHT or Color3.fromRGB(192, 132, 252)
        end
    end
    if refs.RefundStatsBtnApi then
        local refundLbl = formatStatRefundButtonLabel(snap)
        refs.RefundStatsBtnApi:Update({ label = refundLbl })
    end
    if refs.ArsenalCards then
        for slotIdx = 1, 4 do
            local cRef = refs.ArsenalCards[slotIdx]
            if cRef then
                local info = buildArsenalSlotDisplay(slotIdx, snap)
                cRef.TitleLabel.Text = info.title
                cRef.BadgeLabel.Text = info.badge
                cRef.MovesLabel.Text = info.movesText
            end
        end
    end
end

function Skills.Cleanup()
    Skills.Refs = {}
end

return Skills
