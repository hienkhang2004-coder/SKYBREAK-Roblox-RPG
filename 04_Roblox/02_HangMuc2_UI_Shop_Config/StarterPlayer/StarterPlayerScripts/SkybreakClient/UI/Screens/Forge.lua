-- SKYBREAK: Fragments of the Core — Screen 6: Celestial Forge, Vivid 6-Rarity Synthesis & *1-*5 Star Ascension ([F])
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/Forge.lua
-- Matches SKYBREAK_3DBible_05_Paperdoll_And_Forge.png (Bottom Kael's 3D Forge & Star Breakthrough Workbench) 1:1:
--   * Left Panel: Vivid Glossy 6-Rarity Weapon Blueprint Cards with geometric diamond StarPipsRow
--   * Right Workbench: Interactive 3D Blender Weapon ViewportFrame + 3D Lightning-Hammer Strike FX +
--     Vivid Glossy Material Cards -> Output Weapon Card Synthesis Row + *1 -> *5 Star Breakthrough Tier Grid +
--     Dual Tactile Bottom CTA Buttons (Forge/Enhance 3D Weapon + Ascend Star *1 -> *5).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local RarityConfig = require(Shared:WaitForChild("Config"):WaitForChild("RarityConfig"))
local ArsenalExpansionConfig = require(Shared:WaitForChild("Config"):WaitForChild("ArsenalExpansionConfig"))
local UIState = require(Shared:WaitForChild("Types"):WaitForChild("UIState"))
local UIAnimator = require(Shared:WaitForChild("UIAnimator"))
local MotionTokens = require(Shared:WaitForChild("MotionTokens"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Store = require(script.Parent.Parent:WaitForChild("Store"))
local ScreenRouter = require(script.Parent.Parent:WaitForChild("ScreenRouter"))
local I18n = require(script.Parent.Parent:WaitForChild("I18n"))
local PremiumPanel = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumPanel"))
local PremiumButton = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumButton"))
local ItemSlot = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("ItemSlot"))
local ViewportOrbit = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("ViewportOrbit"))

local Forge = {
    Refs = {},
    OrbitController = nil,
    StrikeConn = nil,
    ActiveFXModels = {},
    PendingLock = false,
    LastResponsiveState = nil,
}

-- Canonical *1 -> *5 Star-Grade Bonus Tiers (aligned 1:1 with SkybreakCombatData.StarAscension)
local STAR_BONUSES = {
    [1] = { Crit = 0,  SkillDmg = 0,  ShardCost = 60,  GoldCost = 3500,  Rate = 85,  PityGain = 35, TagVi = "KHỞI NGUYÊN", TagEn = "BASE" },
    [2] = { Crit = 6,  SkillDmg = 12, ShardCost = 120, GoldCost = 7500,  Rate = 65,  PityGain = 40, TagVi = "TINH LUYỆN",  TagEn = "REFINED" },
    [3] = { Crit = 10, SkillDmg = 20, ShardCost = 220, GoldCost = 15000, Rate = 45,  PityGain = 50, TagVi = "THÁNH QUANG", TagEn = "RADIANT" },
    [4] = { Crit = 15, SkillDmg = 30, ShardCost = 400, GoldCost = 30000, Rate = 30,  PityGain = 55, TagVi = "THIÊN GIỚI",  TagEn = "CELESTIAL" },
    [5] = { Crit = 22, SkillDmg = 45, ShardCost = 0,   GoldCost = 0,     Rate = 100, PityGain = 0,  TagVi = "THẦN THOẠI",  TagEn = "SOVEREIGN" },
}

-- Signature separated 3D Blender weapons guaranteed in Forge Blueprints & Ascension Workbench
local SIGNATURE_ARSENAL = {
    {
        Id = "Forge_Dawnbringer_3D",
        OutputItemId = "Dawnbringer",
        NameVi = "Thần Kiếm Bình Minh (Dawnbringer)",
        NameEn = "Dawnbringer Celestial Blade",
        Type = "Craft",
        GoldCost = 500,
        SuccessRate = 1.0,
        ServerRemote = "ForgeRequest",
        Materials = {
            { ItemId = "SunshardCore", Count = 2 },
            { ItemId = "SkyIron", Count = 5 },
            { ItemId = "upgrade_material", Count = 3 },
        },
        FallbackRarity = "Legendary",
        FallbackStats = { ATK = 120, CRIT = 10 },
    },
    {
        Id = "Forge_CursedDualSkyblades",
        OutputItemId = "cursed_dual_skyblades",
        NameVi = "Song Kiếm Thiên Không (Cursed Dual Skyblades)",
        NameEn = "Cursed Dual Skyblades (CDK)",
        Type = "Craft",
        GoldCost = 5000,
        SuccessRate = 1.0,
        ServerRemote = "EquipmentRequest",
        Materials = {
            { ItemId = "SunshardCore", Count = 6 },
            { ItemId = "CelestialFeather", Count = 5 },
            { ItemId = "CoreEssence", Count = 3 },
        },
        FallbackRarity = "Mythic",
        FallbackStats = { ATK = 185, CRIT = 25 },
    },
    {
        Id = "Forge_CryonFrostblade",
        OutputItemId = "cryon_frostblade",
        NameVi = "Hàn Băng Thần Kiếm (Cryon Frostblade)",
        NameEn = "Cryon Frostblade",
        Type = "Craft",
        GoldCost = 1800,
        SuccessRate = 1.0,
        ServerRemote = "EquipmentRequest",
        Materials = {
            { ItemId = "SunshardCore", Count = 4 },
            { ItemId = "CelestialFeather", Count = 3 },
            { ItemId = "CoreEssence", Count = 2 },
        },
        FallbackRarity = "Legendary",
        FallbackStats = { ATK = 135, CRIT = 18 },
    },
    {
        Id = "Forge_NoxarGreatsword",
        OutputItemId = "noxar_abyssal_greatsword",
        NameVi = "Đại Đao Hư Không Noxar (Abyssal Greatsword)",
        NameEn = "Noxar's Abyssal Greatsword",
        Type = "Craft",
        GoldCost = 7500,
        SuccessRate = 1.0,
        ServerRemote = "EquipmentRequest",
        Materials = {
            { ItemId = "SunshardCore", Count = 8 },
            { ItemId = "CelestialFeather", Count = 6 },
            { ItemId = "CoreEssence", Count = 4 },
        },
        FallbackRarity = "Mythic",
        FallbackStats = { ATK = 210, CRIT = 28 },
    },
    {
        Id = "Forge_SaberOfAureon",
        OutputItemId = "saber_of_aureon",
        NameVi = "Thánh Kiếm Aureon (Saber of Aureon)",
        NameEn = "Saber of Aureon",
        Type = "Craft",
        GoldCost = 1200,
        SuccessRate = 1.0,
        ServerRemote = "EquipmentRequest",
        Materials = {
            { ItemId = "SunshardCore", Count = 3 },
            { ItemId = "SkyIron", Count = 6 },
            { ItemId = "CoreEssence", Count = 1 },
        },
        FallbackRarity = "Legendary",
        FallbackStats = { ATK = 115, CRIT = 16 },
    },
    {
        Id = "Forge_Stormfang",
        OutputItemId = "Stormfang",
        NameVi = "Song Đao Lôi Nha (Stormfang)",
        NameEn = "Stormfang Twin Blades",
        Type = "Craft",
        GoldCost = 1200,
        SuccessRate = 1.0,
        ServerRemote = "EquipmentRequest",
        Materials = {
            { ItemId = "SunshardCore", Count = 2 },
            { ItemId = "SkyIron", Count = 6 },
            { ItemId = "upgrade_material", Count = 4 },
        },
        FallbackRarity = "Legendary",
        FallbackStats = { ATK = 135, CRIT = 18 },
    },
    {
        Id = "Forge_SoulGuitarVoid",
        OutputItemId = "soul_guitar_void",
        NameVi = "Đàn Linh Hồn Hư Không (Soul Guitar)",
        NameEn = "Abyssal Soul Guitar",
        Type = "Craft",
        GoldCost = 6000,
        SuccessRate = 1.0,
        ServerRemote = "EquipmentRequest",
        Materials = {
            { ItemId = "SunshardCore", Count = 5 },
            { ItemId = "CelestialFeather", Count = 5 },
            { ItemId = "CoreEssence", Count = 3 },
        },
        FallbackRarity = "Mythic",
        FallbackStats = { ATK = 165, CRIT = 22 },
    },
    {
        Id = "Forge_CryoRailgun",
        OutputItemId = "cryo_railgun",
        NameVi = "Pháo Từ Trường Hàn Băng (Cryo Railgun)",
        NameEn = "Cryo Magnetic Railgun",
        Type = "Craft",
        GoldCost = 2400,
        SuccessRate = 1.0,
        ServerRemote = "EquipmentRequest",
        Materials = {
            { ItemId = "SunshardCore", Count = 3 },
            { ItemId = "SkyIron", Count = 6 },
            { ItemId = "CoreEssence", Count = 2 },
        },
        FallbackRarity = "Legendary",
        FallbackStats = { ATK = 125, CRIT = 18 },
    },
}

local function buildCombinedBlueprints()
    local list = {}
    local seenOutput = {}
    for _, baseRec in ipairs(RarityConfig.Recipes or RarityConfig.ForgeRecipes or {}) do
        table.insert(list, baseRec)
        if baseRec.OutputItemId then
            seenOutput[baseRec.OutputItemId] = true
        end
    end
    for _, sig in ipairs(SIGNATURE_ARSENAL) do
        if not seenOutput[sig.OutputItemId] then
            table.insert(list, sig)
            seenOutput[sig.OutputItemId] = true
        end
    end
    for _, expRec in ipairs(ArsenalExpansionConfig.ExpansionRecipes or {}) do
        if expRec.OutputItemId and not seenOutput[expRec.OutputItemId] then
            table.insert(list, expRec)
            seenOutput[expRec.OutputItemId] = true
        end
    end
    return list
end

local function resolveOutputItem(recipe)
    local outId = recipe and recipe.OutputItemId or "Dawnbringer"
    local cfg = RarityConfig.GetItem(outId)
    if cfg then
        return cfg
    end
    return {
        Id = outId,
        Name = I18n.GetItemDisplayName(outId, (I18n.GetLanguage() == "en" and recipe.NameEn) or recipe.NameVi or outId),
        Rarity = recipe and recipe.FallbackRarity or "Mythic",
        Icon = (tostring(outId):find("railgun") or tostring(outId):find("guitar")) and "Gun" or "Sword",
        Stats = (recipe and recipe.FallbackStats) or { ATK = 220, CRIT = 12 },
    }
end

local function getRecipeDisplayName(recipe, outItem)
    if recipe.NameVi or recipe.NameEn then
        return I18n.GetLanguage() == "en" and (recipe.NameEn or recipe.NameVi) or (recipe.NameVi or recipe.NameEn)
    end
    if outItem and outItem.Id then
        local loc = I18n.GetItemDisplayName(outItem.Id, recipe.Name or outItem.Name)
        if loc and loc ~= "" then
            return loc
        end
    end
    return tostring(recipe.Name or "Celestial Blueprint")
end

local function getOwnedCount(inventory, itemId, snap)
    for _, entry in ipairs(inventory or {}) do
        if entry.itemId == itemId then
            local upg = tonumber(entry.upgrade) or 0
            if snap and tonumber(snap.weaponEnhance) and (entry.count or 0) > 0 then
                local cfg = RarityConfig.GetItem(itemId)
                if not cfg or cfg.Category == "Weapons" or cfg.Slot == "Weapon" or cfg.Slot == "Offhand" then
                    upg = math.max(upg, tonumber(snap.weaponEnhance) or 0)
                end
            end
            return entry.count or 0, upg
        end
    end
    return 0, 0
end

local function computeAnvilActionState(snap, selectedRecipe, ownedCount, curUpgrade)
    local inv = snap and snap.inventory or {}
    local curGold = tonumber((snap and snap.currency and snap.currency.gold) or (snap and snap.currencies and snap.currencies.gold)) or 0
    local isOwned = (ownedCount or 0) > 0
    if not isOwned then
        local reqGold = tonumber(selectedRecipe and selectedRecipe.GoldCost) or 0
        local matsOk = true
        for _, mat in ipairs((selectedRecipe and selectedRecipe.Materials) or {}) do
            local mId = mat.ItemId or mat.itemId
            local reqC = mat.Count or mat.count or 1
            if getOwnedCount(inv, mId) < reqC then
                matsOk = false
                break
            end
        end
        local ready = (curGold >= reqGold) and matsOk
        return {
            ForgeAction = "ForgeCraft",
            IsOwned = false,
            IsMax = false,
            GoldCost = reqGold,
            Ready = ready,
            Label = ready
                and I18n.Pick("RÈN THẦN KHÍ 3D NGAY", "FORGE 3D WEAPON NOW")
                or I18n.Pick("THIẾU NGUYÊN LIỆU / VÀNG", "NEED MATERIALS / GOLD"),
        }
    end
    local upg = math.max(0, math.floor(tonumber(curUpgrade) or 0))
    if upg >= 15 then
        return {
            ForgeAction = "ForgeEnhance",
            IsOwned = true,
            IsMax = true,
            GoldCost = 0,
            Ready = false,
            Label = I18n.Pick("ĐÃ ĐẠT CƯỜNG HÓA +15 TỐI ĐA", "MAX ENHANCE (+15)"),
        }
    end
    local enhGold = (upg >= 10) and 250 or 100
    local enhMats = getOwnedCount(inv, "upgrade_material") + getOwnedCount(inv, "SkyIron")
    local ready = (curGold >= enhGold) and (enhMats >= 1)
    return {
        ForgeAction = "ForgeEnhance",
        IsOwned = true,
        IsMax = false,
        GoldCost = enhGold,
        Ready = ready,
        Label = ready
            and I18n.Pick(
                string.format("CƯỜNG HÓA (+%d -> +%d • %d G)", upg, upg + 1, enhGold),
                string.format("ENHANCE (+%d -> +%d • %d G)", upg, upg + 1, enhGold)
            )
            or I18n.Pick(
                string.format("CẦN %d G & ĐÁ RÈN (+%d -> +%d)", enhGold, upg, upg + 1),
                string.format("NEED %d G & MAT (+%d -> +%d)", enhGold, upg, upg + 1)
            ),
    }
end

local function clearActiveFX()
    if Forge.StrikeConn then
        Forge.StrikeConn:Disconnect()
        Forge.StrikeConn = nil
    end
    for _, fx in ipairs(Forge.ActiveFXModels) do
        if fx and fx.Parent then
            fx:Destroy()
        end
    end
    table.clear(Forge.ActiveFXModels)
end

-- 3D Lightning-Hammer Strike & Golden Spark Burst inside Forge 3D ViewportFrame
local function play3DLightningHammerStrike(accentColor)
    local orbit = Forge.OrbitController
    if not orbit or not orbit.WorldModel or not orbit.WorldModel.Parent then
        return
    end
    clearActiveFX()

    local worldModel = orbit.WorldModel
    local fxRoot = Instance.new("Model")
    fxRoot.Name = "ForgeHammerStrikeFX"
    fxRoot.Parent = worldModel
    table.insert(Forge.ActiveFXModels, fxRoot)

    local gold = Theme.Colors.ACCENT_GOLD_BRIGHT
    local cyan = accentColor or Theme.Colors.ACCENT_ICE

    local hammerHandle = Instance.new("Part")
    hammerHandle.Name = "HammerHandle"
    hammerHandle.Size = Vector3.new(0.22, 2.5, 0.22)
    hammerHandle.Color = Color3.fromRGB(48, 56, 78)
    hammerHandle.Material = Enum.Material.Metal
    hammerHandle.Anchored = true
    hammerHandle.CanCollide = false
    hammerHandle.Parent = fxRoot

    local hammerHead = Instance.new("Part")
    hammerHead.Name = "HammerHead"
    hammerHead.Size = Vector3.new(1.05, 0.78, 1.55)
    hammerHead.Color = gold
    hammerHead.Material = Enum.Material.Metal
    hammerHead.Reflectance = 0.35
    hammerHead.Anchored = true
    hammerHead.CanCollide = false
    hammerHead.Parent = fxRoot

    local hammerCore = Instance.new("Part")
    hammerCore.Name = "HammerRuneCore"
    hammerCore.Size = Vector3.new(1.12, 0.32, 0.72)
    hammerCore.Color = cyan
    hammerCore.Material = Enum.Material.Neon
    hammerCore.Anchored = true
    hammerCore.CanCollide = false
    hammerCore.Parent = fxRoot

    local bolt = Instance.new("Part")
    bolt.Name = "LightningBolt"
    bolt.Size = Vector3.new(0.18, 4.8, 0.18)
    bolt.Color = Color3.fromRGB(165, 232, 255)
    bolt.Material = Enum.Material.Neon
    bolt.Transparency = 1
    bolt.Anchored = true
    bolt.CanCollide = false
    bolt.Parent = fxRoot

    local ring = Instance.new("Part")
    ring.Name = "AnvilShockwaveRing"
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.10, 0.6, 0.6)
    ring.Color = gold
    ring.Material = Enum.Material.Neon
    ring.Transparency = 1
    ring.Anchored = true
    ring.CanCollide = false
    ring.Parent = fxRoot

    local sparks = {}
    for i = 1, 14 do
        local sp = Instance.new("Part")
        sp.Name = "GoldenSpark_" .. i
        sp.Size = Vector3.new(0.14, 0.14, 0.56)
        sp.Color = (i % 3 == 0) and cyan or gold
        sp.Material = Enum.Material.Neon
        sp.Transparency = 1
        sp.Anchored = true
        sp.CanCollide = false
        sp.Parent = fxRoot

        local angle = (i / 14) * math.pi * 2
        local elev = math.rad(14 + (i % 4) * 14)
        local dir = Vector3.new(
            math.cos(angle) * math.cos(elev),
            math.sin(elev),
            math.sin(angle) * math.cos(elev)
        ).Unit
        table.insert(sparks, { Part = sp, Dir = dir, Speed = 3.6 + (i % 3) * 1.1 })
    end

    local pivotOrigin = Vector3.new(1.55, 0.45, 0.35)
    local strikeDuration = 0.18
    local burstDuration = 0.48
    local t0 = os.clock()

    local function positionHammer(swingAngleRad, alphaTrans)
        local pivotCF = CFrame.new(pivotOrigin) * CFrame.Angles(0, math.rad(-18), swingAngleRad)
        local handleCF = pivotCF * CFrame.new(0, 1.15, 0)
        local headCF = pivotCF * CFrame.new(0, 2.35, 0)
        hammerHandle.CFrame = handleCF
        hammerHead.CFrame = headCF
        hammerCore.CFrame = headCF
        hammerHandle.Transparency = alphaTrans
        hammerHead.Transparency = alphaTrans
        hammerCore.Transparency = alphaTrans
    end

    positionHammer(math.rad(-25), 0)

    Forge.StrikeConn = RunService.RenderStepped:Connect(function()
        if not fxRoot.Parent then
            clearActiveFX()
            return
        end
        local elapsed = os.clock() - t0
        if elapsed <= strikeDuration then
            local u = math.clamp(elapsed / strikeDuration, 0, 1)
            local slam = u * u * u
            local angle = math.rad(-22) + (math.rad(88) * slam)
            positionHammer(angle, 0)
        elseif elapsed <= (strikeDuration + burstDuration) then
            local b = math.clamp((elapsed - strikeDuration) / burstDuration, 0, 1)
            local easeOut = 1 - ((1 - b) ^ 3)

            local reboundAngle = math.rad(66) - math.rad(36) * easeOut
            positionHammer(reboundAngle, math.clamp(b * 1.35, 0, 1))

            if b < 0.36 then
                bolt.Transparency = b / 0.36
                bolt.CFrame = CFrame.new(0, 1.6, 0) * CFrame.Angles(0, b * 8, math.rad(6))
            else
                bolt.Transparency = 1
            end

            local ringDiam = 0.8 + easeOut * 4.4
            ring.Size = Vector3.new(0.08, ringDiam, ringDiam)
            ring.CFrame = CFrame.new(0, 0.05, 0) * CFrame.Angles(0, 0, math.rad(90))
            ring.Transparency = 0.15 + b * 0.85

            for _, sp in ipairs(sparks) do
                local dist = 0.25 + easeOut * sp.Speed
                local pos = Vector3.new(0, 0.15 - (b * b * 0.7), 0) + sp.Dir * dist
                sp.Part.CFrame = CFrame.lookAt(pos, pos + sp.Dir)
                sp.Part.Transparency = b * 0.95
            end
        else
            clearActiveFX()
        end
    end)
end

local function rebuildSynthesisCardsRow(holder, selectedRecipe, outItem, snap, currentStars, currentUpgrade)
    if not holder then
        return
    end
    for _, ch in ipairs(holder:GetChildren()) do
        if ch:IsA("GuiObject") then
            ch:Destroy()
        end
    end

    local colors = Theme.Colors
    local inv = (snap and snap.inventory) or {}
    local order = 1

    for _, mat in ipairs((selectedRecipe and selectedRecipe.Materials) or {}) do
        local matId = mat.ItemId or mat.itemId
        local reqCount = mat.Count or mat.count or 1
        local have = getOwnedCount(inv, matId)
        local ok = have >= reqCount

        ItemSlot.Create(holder, {
            name = "MatCard_" .. tostring(matId),
            itemId = matId,
            slotHeaderTag = I18n.Pick("NG.LIỆU", "MAT"),
            rightTagText = string.format("%d/%d", have, reqCount),
            rightTagBg = ok and Color3.fromRGB(16, 132, 82) or Color3.fromRGB(172, 28, 62),
            rightTagColor = Color3.fromRGB(252, 254, 255),
            footerSubText = ok and I18n.Pick("ĐỦ NGUYÊN LIỆU", "READY") or I18n.Pick("THIẾU", "MISSING"),
            footerSubColor = ok and Color3.fromRGB(110, 244, 184) or Color3.fromRGB(255, 148, 168),
            size = UDim2.fromOffset(82, 94),
            layoutOrder = order,
            zIndex = 7,
        })
        order = order + 1
    end

    -- Vivid Legendary Gold Cost Card
    local reqGold = tonumber(selectedRecipe and selectedRecipe.GoldCost) or 0
    local curGold = tonumber((snap and snap.currency and snap.currency.gold) or (snap and snap.currencies and snap.currencies.gold)) or 0
    local goldOk = curGold >= reqGold

    local goldCard = UIFactory.Create("Frame", holder, {
        Name = "GoldRequirementCard",
        Size = UDim2.fromOffset(78, 94),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        LayoutOrder = order,
        ZIndex = 7,
    })
    order = order + 1
    UIFactory.ApplyRarityCardStyle(goldCard, "Legendary", {
        CornerRadius = 10,
        Selected = false,
    })

    local gTopPill = UIFactory.Create("Frame", goldCard, {
        Name = "GoldHeaderTag",
        Position = UDim2.fromOffset(4, 4),
        Size = UDim2.fromOffset(44, 13),
        BackgroundColor3 = Color3.fromRGB(9, 13, 24),
        BackgroundTransparency = 0.08,
        BorderSizePixel = 0,
        ZIndex = 10,
    })
    UIFactory.Corner(gTopPill, 4)
    UIFactory.Label(gTopPill, {
        Name = "Txt",
        Text = I18n.Pick("CHI PHÍ", "COST"),
        Size = UDim2.fromScale(1, 1),
        TextSize = 8,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Wrapped = false,
        ZIndex = 11,
    })

    local gIcon = UIFactory.Icon(goldCard, "Gold", UDim2.new(0.5, -16, 0.40, -16), 32, Color3.fromRGB(255, 250, 232))
    gIcon.ZIndex = 10

    local gFooter = UIFactory.Create("Frame", goldCard, {
        Name = "GoldFooter",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 4, 1, -4),
        Size = UDim2.new(1, -8, 0, 26),
        BackgroundColor3 = Color3.fromRGB(9, 13, 24),
        BackgroundTransparency = 0.10,
        BorderSizePixel = 0,
        ZIndex = 10,
    })
    UIFactory.Corner(gFooter, 6)
    UIFactory.Label(gFooter, {
        Name = "GoldAmt",
        Text = UIFactory.FormatNumber(reqGold) .. " G",
        Position = UDim2.fromOffset(2, 1),
        Size = UDim2.new(1, -4, 0, 13),
        TextSize = 9,
        TextColor = Color3.fromRGB(255, 244, 196),
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = 11,
    })
    UIFactory.Label(gFooter, {
        Name = "GoldStatus",
        Text = goldOk and I18n.Pick("ĐỦ VÀNG", "OK") or I18n.Pick("THIẾU", "LOW"),
        Position = UDim2.new(0, 2, 1, -12),
        Size = UDim2.new(1, -4, 0, 11),
        TextSize = 8,
        TextColor = goldOk and Color3.fromRGB(110, 244, 184) or Color3.fromRGB(255, 148, 168),
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Wrapped = false,
        ZIndex = 11,
    })

    -- Glowing Gold Synthesis Arrow Pill ("->")
    local arrowWrap = UIFactory.Create("Frame", holder, {
        Name = "SynthesisArrow",
        Size = UDim2.fromOffset(30, 30),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        LayoutOrder = order,
        ZIndex = 7,
    })
    order = order + 1
    UIFactory.PillCorner(arrowWrap)
    UIFactory.Stroke(arrowWrap, colors.ACCENT_GOLD_BRIGHT, 1.5, 0.06)
    UIFactory.Gradient(arrowWrap, Color3.fromRGB(252, 212, 98), Color3.fromRGB(184, 112, 18), 90)
    UIFactory.Label(arrowWrap, {
        Name = "ArrowTxt",
        Text = "->",
        Size = UDim2.fromScale(1, 1),
        TextSize = 13,
        TextColor = Color3.fromRGB(16, 18, 28),
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Wrapped = false,
        ZIndex = 8,
    })

    -- Vivid Glossy Output Celestial Weapon Card
    ItemSlot.Create(holder, {
        name = "OutputWeaponCard",
        itemId = outItem.Id,
        itemConfig = outItem,
        slotHeaderTag = I18n.Pick("THÀNH PHẨM", "OUTPUT"),
        rightTagText = string.format("*%d", math.clamp(tonumber(currentStars) or 1, 1, 5)),
        rightTagBg = Color3.fromRGB(22, 18, 42),
        rightTagColor = colors.ACCENT_GOLD_BRIGHT,
        upgrade = currentUpgrade,
        stars = currentStars,
        selected = true,
        showSubStat = true,
        size = UDim2.fromOffset(90, 98),
        layoutOrder = order,
        zIndex = 8,
    })
end

local function rebuildStarBreakthroughTiers(holder, currentStars)
    if not holder then
        return
    end
    for _, ch in ipairs(holder:GetChildren()) do
        if ch:IsA("GuiObject") then
            ch:Destroy()
        end
    end

    local colors = Theme.Colors
    local curS = math.clamp(math.floor(tonumber(currentStars) or 1), 1, 5)

    for tier = 1, 5 do
        local info = STAR_BONUSES[tier]
        local isCurrent = (tier == curS)
        local isUnlocked = (tier <= curS)
        local isNext = (tier == curS + 1)

        local card = UIFactory.Create("Frame", holder, {
            Name = "StarTier_" .. tostring(tier),
            Size = UDim2.new(0.2, -5, 1, 0),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            LayoutOrder = tier,
            ZIndex = 6,
        })
        UIFactory.Corner(card, 9)

        if tier == 5 and isUnlocked then
            UIFactory.Stroke(card, Color3.fromRGB(255, 198, 224), 1.8, 0.04)
            UIFactory.Gradient(card, Color3.fromRGB(128, 36, 118), Color3.fromRGB(36, 18, 62), 90)
        elseif isCurrent then
            UIFactory.Stroke(card, colors.ACCENT_GOLD_BRIGHT, 1.9, 0.02)
            UIFactory.Gradient(card, Color3.fromRGB(58, 46, 22), Color3.fromRGB(20, 22, 38), 90)
        elseif isNext then
            UIFactory.Stroke(card, Color3.fromRGB(92, 214, 255), 1.5, 0.10)
            UIFactory.Gradient(card, Color3.fromRGB(24, 44, 78), Color3.fromRGB(11, 18, 34), 90)
        elseif isUnlocked then
            UIFactory.Stroke(card, Color3.fromRGB(52, 211, 153), 1.3, 0.22)
            UIFactory.Gradient(card, Color3.fromRGB(18, 42, 42), Color3.fromRGB(10, 18, 28), 90)
        else
            UIFactory.Stroke(card, colors.STROKE_STEEL, 1.1, 0.35)
            UIFactory.Gradient(card, Color3.fromRGB(18, 26, 46), Color3.fromRGB(9, 14, 25), 90)
        end

        local pipsHolder = UIFactory.Create("Frame", card, {
            Name = "PipsWrap",
            Position = UDim2.fromOffset(4, 5),
            Size = UDim2.new(1, -8, 0, 12),
            BackgroundTransparency = 1,
            ZIndex = 7,
        })
        local pipRow = UIFactory.StarPipsRow(pipsHolder, tier, 5, {
            PipSize = 7,
            Gap = 3,
            ZIndex = 8,
        })
        pipRow.AnchorPoint = Vector2.new(0.5, 0.5)
        pipRow.Position = UDim2.fromScale(0.5, 0.5)

        UIFactory.Label(card, {
            Name = "TierTitle",
            Text = string.format("*%d • %s", tier, I18n.Pick(info.TagVi, info.TagEn)),
            Position = UDim2.fromOffset(4, 19),
            Size = UDim2.new(1, -8, 0, 13),
            TextSize = 9,
            TextColor = isCurrent and colors.ACCENT_GOLD_BRIGHT or (tier == 5 and Color3.fromRGB(255, 178, 214) or colors.TEXT_PRIMARY),
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            Truncate = Enum.TextTruncate.AtEnd,
            Wrapped = false,
            ZIndex = 7,
        })

        local bonusText = (tier == 1)
            and I18n.Pick("Chỉ số gốc 100%", "100% Base Stats")
            or I18n.Pick(
                string.format("+%d%% CRIT\n+%d%% ST CHIÊU", info.Crit, info.SkillDmg),
                string.format("+%d%% CRIT\n+%d%% SKILL DMG", info.Crit, info.SkillDmg)
            )

        UIFactory.Label(card, {
            Name = "BonusStats",
            Text = bonusText,
            Position = UDim2.fromOffset(4, 34),
            Size = UDim2.new(1, -8, 1, -54),
            TextSize = 9,
            TextColor = isUnlocked and Color3.fromRGB(236, 244, 255) or colors.TEXT_SECONDARY,
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            YAlign = Enum.TextYAlignment.Center,
            ZIndex = 7,
        })

        local prevInfo = STAR_BONUSES[math.max(1, tier - 1)]
        local statusTxt
        local statusCol
        if isCurrent then
            statusTxt = I18n.Pick("ĐANG KÍCH HOẠT", "ACTIVE TIER")
            statusCol = colors.ACCENT_GOLD_BRIGHT
        elseif isUnlocked then
            statusTxt = I18n.Pick("ĐÃ ĐỘT PHÁ", "UNLOCKED")
            statusCol = Color3.fromRGB(82, 232, 168)
        elseif isNext then
            statusTxt = string.format("%d Shards • %d%%", prevInfo.ShardCost, prevInfo.Rate)
            statusCol = Color3.fromRGB(132, 226, 255)
        else
            statusTxt = string.format("%d Shards", prevInfo.ShardCost)
            statusCol = colors.TEXT_MUTED
        end

        UIFactory.Label(card, {
            Name = "TierFooter",
            Text = statusTxt,
            AnchorPoint = Vector2.new(0, 1),
            Position = UDim2.new(0, 4, 1, -4),
            Size = UDim2.new(1, -8, 0, 13),
            TextSize = 8,
            TextColor = statusCol,
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            Truncate = Enum.TextTruncate.AtEnd,
            Wrapped = false,
            ZIndex = 7,
        })
    end
end

function Forge.Build(parent, responsiveState)
    Forge.Cleanup()
    responsiveState = responsiveState or Forge.LastResponsiveState
    Forge.LastResponsiveState = responsiveState
    local colors = Theme.Colors
    local snap = Store.GetSnapshot()
    local view = Store.GetView()
    local isPortrait = responsiveState and responsiveState.IsPortrait

    local root = UIFactory.Create("Frame", parent, {
        Name = "ForgeScreen",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 2,
    })

    -- Shared Top Screen Header with Currency Pills & Navigation Tabs
    local _, headerRefs = UIFactory.BuildScreenHeader(root, {
        ActiveScreen = UIState.Screens.Forge,
        Title = I18n.Pick("LÒ RÈN THẦN KHÍ KAEL & ĐỘT PHÁ SAO *1-*5 [F]", "KAEL'S 3D FORGE & STAR BREAKTHROUGH [F]"),
        Snapshot = snap,
        OnNavigate = function(targetId)
            ScreenRouter.Navigate(targetId)
        end,
        OnClose = function()
            ScreenRouter.CloseAllToHUD()
        end,
    })

    local recipes = buildCombinedBlueprints()
    local selectedRecipe = recipes[1]
    if view.selectedRecipeId then
        for _, r in ipairs(recipes) do
            if r.Id == view.selectedRecipeId then
                selectedRecipe = r
                break
            end
        end
    elseif view.selectedItemId then
        for _, r in ipairs(recipes) do
            if r.OutputItemId == view.selectedItemId then
                selectedRecipe = r
                Store.SetView({ selectedRecipeId = r.Id })
                break
            end
        end
    end

    -- =========================================================================
    -- LEFT PANEL (39%): Vivid Glossy 6-Rarity Weapon Blueprints List
    -- =========================================================================
    local recipeCard = PremiumPanel.Create(root, {
        name = "RecipeListPanel",
        variant = "gold",
        title = I18n.Pick("BẢN VẼ LÒ RÈN & THẦN KHÍ 3D", "3D CELESTIAL FORGE BLUEPRINTS"),
        subtitle = I18n.Pick("Chọn Thần Khí 3D để chế tác, cường hóa +15 & đột phá *1 -> *5", "Select a 3D weapon blueprint to craft, enhance +15 & ascend *1 -> *5"),
        position = UDim2.fromOffset(14, 72),
        size = isPortrait and UDim2.new(1, -28, 0.40, -44) or UDim2.new(0.39, -18, 1, -86),
        transparency = 0.04,
    })

    local recipeScroll = UIFactory.Create("ScrollingFrame", recipeCard, {
        Name = "RecipeScroll",
        Position = UDim2.fromOffset(12, 56),
        Size = UDim2.new(1, -24, 1, -68),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 5,
        ScrollBarImageColor3 = colors.ACCENT_GOLD_BRIGHT,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.fromOffset(0, 0),
        ZIndex = 5,
    })
    UIFactory.ListLayout(recipeScroll, Enum.FillDirection.Vertical, 7)

    local recipeRowRefs = {}
    for idx, recipe in ipairs(recipes) do
        local isSel = (recipe.Id == selectedRecipe.Id)
        local rOut = resolveOutputItem(recipe)
        local rInfo = RarityConfig.GetRarity(rOut.Rarity)
        local curStars = Store.GetWeaponStar(rOut.Id)
        local rOwned = getOwnedCount(snap.inventory, rOut.Id, snap)

        local row = UIFactory.Create("TextButton", recipeScroll, {
            Name = "Recipe_" .. tostring(recipe.Id),
            Size = UDim2.new(1, -6, 0, 74),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = idx,
            ZIndex = 6,
        })
        UIFactory.Corner(row, 10)
        UIFactory.Stroke(
            row,
            isSel and colors.ACCENT_GOLD_BRIGHT or (rInfo.BorderBright or rInfo.Color),
            isSel and 2.1 or 1.2,
            isSel and 0.02 or 0.30
        )
        UIFactory.Gradient(
            row,
            isSel and Color3.fromRGB(32, 48, 84) or Color3.fromRGB(18, 28, 50),
            isSel and Color3.fromRGB(14, 22, 42) or Color3.fromRGB(9, 14, 26),
            90
        )

        -- Left 56x58 Vivid Glossy Rarity Icon Tile
        local iconTile = UIFactory.Create("Frame", row, {
            Name = "RarityIconTile",
            Position = UDim2.fromOffset(8, 8),
            Size = UDim2.fromOffset(56, 58),
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderSizePixel = 0,
            Active = false,
            ZIndex = 7,
        })
        UIFactory.ApplyRarityCardStyle(iconTile, rInfo.Id, {
            CornerRadius = 9,
            Selected = isSel,
        })
        local tileIcon = UIFactory.Icon(
            iconTile,
            rOut.Icon or "Sword",
            UDim2.new(0.5, -15, 0.5, -15),
            30,
            Color3.fromRGB(255, 252, 244)
        )
        tileIcon.ZIndex = 10

        UIFactory.Label(row, {
            Name = "Title",
            Text = getRecipeDisplayName(recipe, rOut),
            Position = UDim2.fromOffset(74, 8),
            Size = UDim2.new(1, -154, 0, 20),
            TextSize = 12,
            TextColor = isSel and colors.ACCENT_GOLD_BRIGHT or colors.TEXT_PRIMARY,
            Bold = true,
            Truncate = Enum.TextTruncate.AtEnd,
            Wrapped = false,
            ZIndex = 7,
        })

        -- Top-Right Geometric Diamond Star Pips + *X Label
        local rowStarsWrap = UIFactory.Create("Frame", row, {
            Name = "RowStarsWrap",
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -10, 0, 10),
            Size = UDim2.fromOffset(68, 16),
            BackgroundTransparency = 1,
            ZIndex = 7,
        })
        local pipRow = UIFactory.StarPipsRow(rowStarsWrap, curStars, 5, {
            PipSize = 7,
            Gap = 3,
            ZIndex = 8,
        })
        pipRow.AnchorPoint = Vector2.new(1, 0.5)
        pipRow.Position = UDim2.new(1, 0, 0.5, 0)

        UIFactory.Label(row, {
            Name = "Sub",
            Text = string.format(
                "%s   •   %s Gold",
                string.upper(I18n.GetRarityLabel(rInfo.Id)),
                UIFactory.FormatNumber(recipe.GoldCost or 0)
            ),
            Position = UDim2.fromOffset(74, 30),
            Size = UDim2.new(1, -154, 0, 16),
            TextSize = 10,
            TextColor = rInfo.BorderBright or rInfo.Color,
            Bold = true,
            Truncate = Enum.TextTruncate.AtEnd,
            Wrapped = false,
            ZIndex = 7,
        })

        local ownTag = UIFactory.Label(row, {
            Name = "OwnStatus",
            Text = (rOwned > 0)
                and I18n.Pick(string.format("[ĐÃ SỞ HỮU • *%d]", curStars), string.format("[OWNED • *%d]", curStars))
                or I18n.Pick("[CHẾ TÁC 3D MỚI]", "[CRAFT 3D WEAPON]"),
            Position = UDim2.fromOffset(74, 48),
            Size = UDim2.new(1, -84, 0, 15),
            TextSize = 9,
            TextColor = (rOwned > 0) and Color3.fromRGB(82, 232, 168) or Color3.fromRGB(168, 194, 232),
            Bold = true,
            Truncate = Enum.TextTruncate.AtEnd,
            Wrapped = false,
            ZIndex = 7,
        })

        recipeRowRefs[rOut.Id] = recipeRowRefs[rOut.Id] or {}
        table.insert(recipeRowRefs[rOut.Id], {
            StarsWrap = rowStarsWrap,
            OwnTag = ownTag,
        })

        row.Activated:Connect(function()
            if view.selectedRecipeId ~= recipe.Id then
                Store.SetView({ selectedRecipeId = recipe.Id })
            end
        end)
    end

    -- =========================================================================
    -- RIGHT PANEL (61%): 3D Weapon Anvil + Vivid Material Cards Synthesis + *1->*5 Breakthrough Grid
    -- =========================================================================
    local outItem = resolveOutputItem(selectedRecipe)
    local rInfo = RarityConfig.GetRarity(outItem.Rarity)
    local ownedCount, currentUpgrade = getOwnedCount(snap.inventory, outItem.Id, snap)
    local currentStars = Store.GetWeaponStar(outItem.Id)
    local currentPity = Store.GetWeaponStarPity(outItem.Id)
    local dispTitle = getRecipeDisplayName(selectedRecipe, outItem)

    local anvilCard = PremiumPanel.Create(root, {
        name = "AnvilPanel",
        variant = "gold",
        title = string.upper(dispTitle),
        subtitle = selectedRecipe.Description or I18n.Pick("Bàn Rèn Thần Khí Kael • Xoay 360 & Đột Phá Sao *1 -> *5", "Kael's Celestial Anvil • 360 Orbit & *1 -> *5 Star Breakthrough"),
        position = isPortrait and UDim2.new(0, 14, 0.40, 34) or UDim2.new(0.39, 4, 0, 72),
        size = isPortrait and UDim2.new(1, -28, 0.60, -48) or UDim2.new(0.61, -18, 1, -86),
        transparency = 0.04,
    })

    -- 1. Top 3D Weapon Showcase Card (y = 52, height = 166)
    local previewBox = UIFactory.Create("Frame", anvilCard, {
        Name = "ForgePreview",
        Position = UDim2.fromOffset(14, 52),
        Size = UDim2.new(1, -28, 0, 166),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 5,
    })
    local previewScale = Instance.new("UIScale")
    previewScale.Name = "UIScale"
    previewScale.Scale = 1.0
    previewScale.Parent = previewBox

    UIFactory.Corner(previewBox, 11)
    UIFactory.Stroke(previewBox, rInfo.BorderBright or rInfo.Color, 1.6, 0.12)
    UIFactory.Gradient(previewBox, Color3.fromRGB(20, 32, 58), Color3.fromRGB(9, 14, 26), 90)

    local weaponViewport = UIFactory.Create("ViewportFrame", previewBox, {
        Name = "WeaponViewport",
        Position = UDim2.fromOffset(8, 8),
        Size = UDim2.fromOffset(244, 150),
        BackgroundColor3 = colors.BG_900,
        BackgroundTransparency = 0.08,
        Ambient = Color3.fromRGB(202, 216, 242),
        LightColor = Color3.fromRGB(255, 246, 218),
        LightDirection = Vector3.new(-0.7, -0.9, -0.8),
        ZIndex = 6,
    })
    UIFactory.Corner(weaponViewport, 9)
    UIFactory.Stroke(weaponViewport, rInfo.BorderBright or rInfo.Color, 1.3, 0.22)

    local vpHintPill = UIFactory.Create("Frame", weaponViewport, {
        Name = "ViewportHintPill",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, -5),
        Size = UDim2.fromOffset(186, 17),
        BackgroundColor3 = Color3.fromRGB(8, 13, 24),
        BackgroundTransparency = 0.10,
        BorderSizePixel = 0,
        ZIndex = 8,
    })
    UIFactory.PillCorner(vpHintPill)
    UIFactory.Stroke(vpHintPill, Color3.fromRGB(72, 212, 255), 1.1, 0.25)
    UIFactory.Label(vpHintPill, {
        Name = "HintTxt",
        Text = I18n.Pick("KÉO XOAY 360 • BÚA SẤM KAEL 3D", "DRAG 360 ORBIT • 3D ANVIL FX"),
        Size = UDim2.fromScale(1, 1),
        TextSize = 8,
        TextColor = Color3.fromRGB(168, 232, 255),
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Wrapped = false,
        ZIndex = 9,
    })

    local orbit = ViewportOrbit.Attach(weaponViewport, {
        AutoSpinSpeed = 0.45,
        InitialYaw = math.rad(28),
        InitialPitch = math.rad(12),
        ShowHint = false,
        FieldOfView = 35,
        FitMultiplier = 1.04,
    })
    Forge.OrbitController = orbit

    local resolvedWepAsset = ViewportOrbit.ResolveAssetName(outItem.Id) or outItem.Id
    ViewportOrbit.MountAssetAsync(orbit, resolvedWepAsset, rInfo.Color, {
        FitMultiplier = 1.04,
        ResetAngles = true,
        UprightWeapon = string.sub(tostring(resolvedWepAsset), 1, 4) == "Wep_",
    })

    local starBonus = STAR_BONUSES[currentStars] or STAR_BONUSES[1]
    local baseAtk = (outItem.Stats and outItem.Stats.ATK or 180) + (currentUpgrade * 6) + ((currentStars - 1) * 18)
    local baseCrit = (outItem.Stats and outItem.Stats.CRIT or 10) + starBonus.Crit

    local itemTitleLbl = UIFactory.Label(previewBox, {
        Name = "ItemTitle",
        Text = string.format("%s%s", I18n.GetItemDisplayName(outItem.Id, outItem.Name), currentUpgrade > 0 and (" +" .. currentUpgrade) or ""),
        Position = UDim2.fromOffset(264, 8),
        Size = UDim2.new(1, -276, 0, 22),
        TextSize = 15,
        TextColor = rInfo.BorderBright or rInfo.Color,
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = 6,
    })

    -- Geometric Gold Diamond Star Pips Row + [*X / *5] Badge
    local starHeaderRow = UIFactory.Create("Frame", previewBox, {
        Name = "StarHeaderRow",
        Position = UDim2.fromOffset(264, 32),
        Size = UDim2.new(1, -276, 0, 20),
        BackgroundTransparency = 1,
        ZIndex = 6,
    })
    local mainStarPipsHolder = UIFactory.Create("Frame", starHeaderRow, {
        Name = "MainStarPipsHolder",
        Position = UDim2.fromOffset(0, 2),
        Size = UDim2.fromOffset(92, 16),
        BackgroundTransparency = 1,
        ZIndex = 7,
    })
    UIFactory.StarPipsRow(mainStarPipsHolder, currentStars, 5, {
        PipSize = 10,
        Gap = 6,
        ZIndex = 8,
    })

    local starGradeBadgeLbl = UIFactory.Label(starHeaderRow, {
        Name = "StarGradeBadge",
        Text = string.format("[*%d / *5 • %s]", currentStars, I18n.Pick(starBonus.TagVi, starBonus.TagEn)),
        Position = UDim2.fromOffset(96, 0),
        Size = UDim2.new(1, -98, 1, 0),
        TextSize = 11,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = 7,
    })

    local statsPreviewLbl = UIFactory.Label(previewBox, {
        Name = "StatsPreview",
        Text = I18n.Pick(
            string.format(
                "ATK +%d   •   CRIT +%d%%   •   ST CHIÊU +%d%%\nSở hữu: x%d   •   Tỉ lệ rèn: %d%%   •   Mesh: %s",
                baseAtk,
                baseCrit,
                starBonus.SkillDmg,
                ownedCount,
                math.floor((selectedRecipe.SuccessRate or 1) * 100),
                tostring(resolvedWepAsset)
            ),
            string.format(
                "ATK +%d   •   CRIT +%d%%   •   SKILL DMG +%d%%\nOwned: x%d   •   Craft Rate: %d%%   •   Mesh: %s",
                baseAtk,
                baseCrit,
                starBonus.SkillDmg,
                ownedCount,
                math.floor((selectedRecipe.SuccessRate or 1) * 100),
                tostring(resolvedWepAsset)
            )
        ),
        Position = UDim2.fromOffset(264, 54),
        Size = UDim2.new(1, -276, 0, 36),
        TextSize = 11,
        TextColor = colors.TEXT_SECONDARY,
        Bold = true,
        ZIndex = 6,
    })

    -- Pity Blessing & Next Star Cost Sub-Card
    local starCard = UIFactory.Create("Frame", previewBox, {
        Name = "StarAscensionBox",
        Position = UDim2.fromOffset(264, 96),
        Size = UDim2.new(1, -276, 0, 60),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
        ZIndex = 6,
    })
    UIFactory.Corner(starCard, 8)
    UIFactory.Stroke(starCard, colors.ACCENT_GOLD_BRIGHT, 1.2, 0.25)

    local nextStars = math.min(5, currentStars + 1)
    local nextBonus = STAR_BONUSES[nextStars] or STAR_BONUSES[5]

    local starBonusLbl = UIFactory.Label(starCard, {
        Name = "StarBonusText",
        Text = (currentStars >= 5)
            and I18n.Pick("ĐÃ ĐẠT *5 TỐI ĐA: +22% CRIT • +45% ST KỸ NĂNG", "MAX *5 REACHED: +22% CRIT • +45% SKILL DMG")
            or I18n.Pick(
                string.format("Đột phá *%d -> *%d: +%d%% CRIT / +%d%% Chiêu (%d Shards + %s G)", currentStars, nextStars, nextBonus.Crit, nextBonus.SkillDmg, starBonus.ShardCost, UIFactory.FormatNumber(starBonus.GoldCost)),
                string.format("Ascend *%d -> *%d: +%d%% CRIT / +%d%% Skill (%d Shards + %s G)", currentStars, nextStars, nextBonus.Crit, nextBonus.SkillDmg, starBonus.ShardCost, UIFactory.FormatNumber(starBonus.GoldCost))
            ),
        Position = UDim2.fromOffset(10, 5),
        Size = UDim2.new(1, -20, 0, 16),
        TextSize = 10,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = 7,
    })

    local pityLbl = UIFactory.Label(starCard, {
        Name = "PityLabel",
        Text = I18n.Pick(
            string.format("Chúc Phúc Pity Aether: %d%% / 100%% (Tỉ lệ thành công: %d%%)", currentPity, starBonus.Rate),
            string.format("Aether Pity Blessing: %d%% / 100%% (Success Rate: %d%%)", currentPity, starBonus.Rate)
        ),
        Position = UDim2.fromOffset(10, 23),
        Size = UDim2.new(1, -20, 0, 14),
        TextSize = 9,
        TextColor = Color3.fromRGB(132, 226, 255),
        Bold = true,
        Truncate = Enum.TextTruncate.AtEnd,
        Wrapped = false,
        ZIndex = 7,
    })

    local pityTrack = UIFactory.Create("Frame", starCard, {
        Name = "PityBarTrack",
        Position = UDim2.fromOffset(10, 42),
        Size = UDim2.new(1, -20, 0, 8),
        BackgroundColor3 = Color3.fromRGB(8, 12, 22),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 7,
    })
    UIFactory.PillCorner(pityTrack)
    local pityFill = UIFactory.Create("Frame", pityTrack, {
        Name = "PityFill",
        Size = UDim2.fromScale(math.clamp(currentPity / 100, 0, 1), 1),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        ZIndex = 8,
    })
    UIFactory.PillCorner(pityFill)
    UIFactory.Gradient(pityFill, Color3.fromRGB(252, 214, 102), Color3.fromRGB(217, 119, 6), 0)

    -- 2. Middle Section (y = 224, height = 122): Vivid Glossy 6-Rarity Material Cards -> Output Weapon Card
    UIFactory.Label(anvilCard, {
        Name = "SynthesisHeader",
        Text = I18n.Pick("NGUYÊN LIỆU CHẾ TÁC 3D  ->  THÀNH PHẨM THẦN KHÍ", "3D FORGE INGREDIENTS  ->  CELESTIAL OUTPUT"),
        Position = UDim2.fromOffset(14, 223),
        Size = UDim2.new(1, -28, 0, 16),
        TextSize = 11,
        TextColor = colors.ACCENT_GOLD_BRIGHT,
        Bold = true,
        Wrapped = false,
        ZIndex = 6,
    })

    local synthesisRow = UIFactory.Create("Frame", anvilCard, {
        Name = "SynthesisCardsRow",
        Position = UDim2.fromOffset(14, 241),
        Size = UDim2.new(1, -28, 0, 102),
        BackgroundTransparency = 1,
        ZIndex = 6,
    })
    UIFactory.ListLayout(synthesisRow, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
    rebuildSynthesisCardsRow(synthesisRow, selectedRecipe, outItem, snap, currentStars, currentUpgrade)

    -- 3. Lower Section (y = 348): *1 -> *5 Star Breakthrough Tier Breakdown Cards
    UIFactory.Label(anvilCard, {
        Name = "BreakthroughHeader",
        Text = I18n.Pick("BẢNG ĐỘT PHÁ THĂNG SAO THẦN KHÍ (*1 -> *5)", "CELESTIAL STAR BREAKTHROUGH TIERS (*1 -> *5)"),
        Position = UDim2.fromOffset(14, 348),
        Size = UDim2.new(1, -28, 0, 16),
        TextSize = 11,
        TextColor = Color3.fromRGB(152, 226, 255),
        Bold = true,
        Wrapped = false,
        ZIndex = 6,
    })

    local tiersRow = UIFactory.Create("Frame", anvilCard, {
        Name = "StarTiersRow",
        Position = UDim2.fromOffset(14, 367),
        Size = UDim2.new(1, -28, 1, -427),
        BackgroundTransparency = 1,
        ZIndex = 6,
    })
    UIFactory.ListLayout(tiersRow, Enum.FillDirection.Horizontal, 6, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
    rebuildStarBreakthroughTiers(tiersRow, currentStars)

    -- 4. Bottom Dual Tactile CTA Row (Forge/Enhance 3D Weapon + Ascend Star *1 -> *5)
    local ctaRow = UIFactory.Create("Frame", anvilCard, {
        Name = "BottomCTARow",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 14, 1, -10),
        Size = UDim2.new(1, -28, 0, 42),
        BackgroundTransparency = 1,
        ZIndex = 7,
    })

    local anvilState = computeAnvilActionState(snap, selectedRecipe, ownedCount, currentUpgrade)
    local craftBtnApi
    local _
    _, craftBtnApi = PremiumButton.Create(ctaRow, {
        name = "CraftButton",
        icon = "Forge",
        label = anvilState.Label,
        variant = anvilState.IsMax and "secondary" or (anvilState.Ready and "gold" or "primary"),
        disabled = Forge.PendingLock or anvilState.IsMax,
        position = UDim2.fromOffset(0, 0),
        size = UDim2.new(0.56, -5, 1, 0),
        textSize = 12,
        minTextSize = 9,
        zIndex = 8,
        onActivated = function()
            if Forge.PendingLock then
                return
            end
            local liveSnap = Store.GetSnapshot()
            local liveOwned, liveUpg = getOwnedCount(liveSnap and liveSnap.inventory or {}, outItem.Id, liveSnap)
            local liveState = computeAnvilActionState(liveSnap, selectedRecipe, liveOwned, liveUpg)
            if liveState.IsMax then
                return
            end
            if liveSnap and not liveSnap.isDemoMode and not liveState.Ready then
                Store.ShowToast(liveState.Label, "warning", 2.6)
                return
            end

            Forge.PendingLock = true
            craftBtnApi:Update({
                label = I18n.Pick("BÚA SẤM KAEL ĐANG RÈN...", "STRIKING CELESTIAL ANVIL..."),
                disabled = true,
            })

            play3DLightningHammerStrike(rInfo.Color)
            if previewScale and previewScale.Parent then
                previewScale.Scale = 1.04
                UIAnimator.Tween(previewScale, { Scale = 1.0 }, MotionTokens.questComplete.duration, MotionTokens.questComplete.style, MotionTokens.questComplete.direction)
            end

            task.delay(0.42, function()
                Forge.PendingLock = false
                local afterSnap = Store.GetSnapshot()
                local afterOwned, afterUpg = getOwnedCount(afterSnap and afterSnap.inventory or {}, outItem.Id, afterSnap)
                local afterState = computeAnvilActionState(afterSnap, selectedRecipe, afterOwned, afterUpg)
                if craftBtnApi and anvilCard.Parent then
                    craftBtnApi:Update({
                        label = afterState.Label,
                        variant = afterState.IsMax and "secondary" or (afterState.Ready and "gold" or "primary"),
                        disabled = afterState.IsMax,
                    })
                end
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if remotes and afterSnap and not afterSnap.isDemoMode then
                    local forgeAct = liveState.ForgeAction
                    if selectedRecipe.ServerRemote == "ForgeRequest" and remotes:FindFirstChild("ForgeRequest") then
                        remotes.ForgeRequest:FireServer({
                            action = forgeAct,
                            itemId = outItem.Id,
                            recipeId = selectedRecipe.Id,
                        })
                        Store.ShowToast(
                            (forgeAct == "ForgeCraft")
                                and I18n.Pick("Đang rèn Thần Khí tại Đe Thiên Giới Kael...", "Forging weapon at Kael's Celestial Anvil...")
                                or I18n.Pick("Đang cường hóa Thần Khí tại Đe Thiên Giới Kael...", "Enhancing weapon at Kael's Celestial Anvil..."),
                            "info"
                        )
                        return
                    elseif remotes:FindFirstChild("EquipmentRequest") then
                        remotes.EquipmentRequest:FireServer({
                            action = forgeAct,
                            itemId = outItem.Id,
                            recipeId = selectedRecipe.Id,
                        })
                        Store.ShowToast(
                            I18n.Pick(
                                (forgeAct == "ForgeCraft" and "Đã gửi yêu cầu rèn " or "Đã gửi yêu cầu cường hóa ") .. I18n.GetItemDisplayName(outItem.Id, outItem.Name) .. "!",
                                (forgeAct == "ForgeCraft" and "Submitted craft order for " or "Submitted enhance order for ") .. I18n.GetItemDisplayName(outItem.Id, outItem.Name) .. "!"
                            ),
                            "success"
                        )
                        return
                    end
                end
                Store.ApplyDemoPreviewAction("ForgeRecipe", { recipeId = selectedRecipe.Id, itemId = outItem.Id })
            end)
        end,
    })

    local starBtnLabel = (currentStars >= 5)
        and I18n.Pick("ĐÃ ĐẠT *5 TỐI ĐA", "MAX *5 SOVEREIGN")
        or I18n.Pick(
            string.format("THĂNG CẤP SAO *%d -> *%d", currentStars, math.min(5, currentStars + 1)),
            string.format("ASCEND STAR *%d -> *%d", currentStars, math.min(5, currentStars + 1))
        )

    local _, starBtnApi = PremiumButton.Create(ctaRow, {
        name = "UpgradeStarBtn",
        icon = "Sparkle",
        label = starBtnLabel,
        variant = (currentStars >= 5) and "secondary" or "mythic",
        disabled = (currentStars >= 5),
        position = UDim2.new(0.56, 5, 0, 0),
        size = UDim2.new(0.44, -5, 1, 0),
        textSize = 12,
        minTextSize = 9,
        zIndex = 8,
        onActivated = function()
            local curSnap = Store.GetSnapshot()
            local curS = Store.GetWeaponStar(outItem.Id)
            if curS >= 5 then
                return
            end
            local tierInfo = STAR_BONUSES[curS] or STAR_BONUSES[1]
            local curCurrency = (curSnap and (curSnap.currency or curSnap.currencies)) or {}
            local curGold = tonumber(curCurrency.gold) or 0
            local curShards = tonumber(curCurrency.coreShards) or 0
            if curSnap and not curSnap.isDemoMode then
                local liveOwned = getOwnedCount(curSnap.inventory, outItem.Id, curSnap)
                if liveOwned <= 0 then
                    Store.ShowToast(
                        I18n.Pick("Hãy rèn sở hữu Thần Khí trước khi Đột Phá Sao!", "Forge this weapon first before Star Breakthrough!"),
                        "warning",
                        2.8
                    )
                    return
                end
                if curGold < tierInfo.GoldCost or curShards < tierInfo.ShardCost then
                    Store.ShowToast(
                        I18n.Pick(
                            string.format("Cần %s Gold & %d Core Shards để nâng lên *%d!", UIFactory.FormatNumber(tierInfo.GoldCost), tierInfo.ShardCost, curS + 1),
                            string.format("Requires %s Gold & %d Core Shards to ascend to *%d!", UIFactory.FormatNumber(tierInfo.GoldCost), tierInfo.ShardCost, curS + 1)
                        ),
                        "warning",
                        2.8
                    )
                    return
                end
            end

            play3DLightningHammerStrike(rInfo.Color)
            if previewScale and previewScale.Parent then
                previewScale.Scale = 1.035
                UIAnimator.Tween(previewScale, { Scale = 1.0 }, MotionTokens.questComplete.duration, MotionTokens.questComplete.style, MotionTokens.questComplete.direction)
            end

            local remotes = ReplicatedStorage:FindFirstChild("Remotes")
            if remotes and curSnap and not curSnap.isDemoMode then
                if remotes:FindFirstChild("UIRequest") then
                    remotes.UIRequest:FireServer("UpgradeWeaponStar", { itemId = outItem.Id, targetStar = curS + 1 })
                    return
                elseif remotes:FindFirstChild("EquipmentRequest") then
                    remotes.EquipmentRequest:FireServer({ action = "UpgradeWeaponStar", itemId = outItem.Id, targetStar = curS + 1 })
                    return
                end
            end

            local curP = Store.GetWeaponStarPity(outItem.Id)
            local rollSuccess = (curP >= 100) or (math.random(1, 100) <= tierInfo.Rate)
            if rollSuccess then
                local newS = math.min(5, curS + 1)
                Store.Session.weaponStars[outItem.Id] = newS
                Store.Session.weaponStarPity[outItem.Id] = 0
                local nb = STAR_BONUSES[newS] or STAR_BONUSES[5]
                Store.ShowToast(
                    I18n.Pick(
                        string.format("ĐỘT PHÁ THÀNH CÔNG! %s đạt *%d (+%d%% CRIT / +%d%% ST Chiêu)!", I18n.GetItemDisplayName(outItem.Id, outItem.Name), newS, nb.Crit, nb.SkillDmg),
                        string.format("STAR BREAKTHROUGH! %s reached *%d (+%d%% CRIT / +%d%% Skill DMG)!", I18n.GetItemDisplayName(outItem.Id, outItem.Name), newS, nb.Crit, nb.SkillDmg)
                    ),
                    "success",
                    3.2
                )
                Store.PushLoot({
                    Category = "Mastery",
                    Title = string.format("%s  *%d", I18n.GetItemDisplayName(outItem.Id, outItem.Name), newS),
                    Subtitle = string.format("+%d%% CRIT  •  +%d%% Skill DMG", nb.Crit, nb.SkillDmg),
                    Color = colors.ACCENT_GOLD_BRIGHT,
                })
            else
                local newP = math.min(100, curP + (tierInfo.PityGain or 35))
                Store.Session.weaponStarPity[outItem.Id] = newP
                Store.ShowToast(
                    I18n.Pick(
                        string.format("Tích tụ Tinh Hoa Aether! Chúc Phúc Pity tăng lên %d%%.", newP),
                        string.format("Aether Resonance accumulated! Pity Blessing increased to %d%%.", newP)
                    ),
                    "info",
                    2.4
                )
            end

            Forge.Update(curSnap)
        end,
    })

    Forge.Refs = {
        Root = root,
        HeaderRefs = headerRefs,
        SelectedRecipeId = selectedRecipe.Id,
        SelectedRecipe = selectedRecipe,
        OutItem = outItem,
        ResolvedWepAsset = resolvedWepAsset,
        WeaponViewport = weaponViewport,
        ItemTitleLbl = itemTitleLbl,
        MainStarPipsHolder = mainStarPipsHolder,
        StarGradeBadgeLbl = starGradeBadgeLbl,
        StatsPreviewLbl = statsPreviewLbl,
        StarBonusLbl = starBonusLbl,
        PityLbl = pityLbl,
        PityFill = pityFill,
        SynthesisRow = synthesisRow,
        TiersRow = tiersRow,
        RecipeRowRefs = recipeRowRefs,
        CraftBtnApi = craftBtnApi,
        StarBtnApi = starBtnApi,
    }
    return root
end

function Forge.Update(snap)
    snap = snap or Store.GetSnapshot()
    local view = Store.GetView()
    local refs = Forge.Refs
    if not refs or not refs.Root or not refs.Root.Parent then
        return
    end
    if refs.HeaderRefs and refs.HeaderRefs.UpdateCurrencies then
        refs.HeaderRefs.UpdateCurrencies(snap)
    end
    if view.selectedRecipeId and view.selectedRecipeId ~= refs.SelectedRecipeId then
        local parent = refs.Root.Parent
        refs.Root:Destroy()
        Forge.Build(parent, Forge.LastResponsiveState)
        return
    end

    if refs.RecipeRowRefs then
        for itemId, rowList in pairs(refs.RecipeRowRefs) do
            local st = Store.GetWeaponStar(itemId)
            local rOwned = getOwnedCount(snap and snap.inventory or {}, itemId, snap)
            for _, rRef in ipairs(rowList) do
                if rRef.StarsWrap and rRef.StarsWrap.Parent then
                    for _, ch in ipairs(rRef.StarsWrap:GetChildren()) do
                        ch:Destroy()
                    end
                    local pipRow = UIFactory.StarPipsRow(rRef.StarsWrap, st, 5, {
                        PipSize = 7,
                        Gap = 3,
                        ZIndex = 8,
                    })
                    pipRow.AnchorPoint = Vector2.new(1, 0.5)
                    pipRow.Position = UDim2.new(1, 0, 0.5, 0)
                end
                if rRef.OwnTag and rRef.OwnTag.Parent then
                    rRef.OwnTag.Text = (rOwned > 0)
                        and I18n.Pick(string.format("[ĐÃ SỞ HỮU • *%d]", st), string.format("[OWNED • *%d]", st))
                        or I18n.Pick("[CHẾ TÁC 3D MỚI]", "[CRAFT 3D WEAPON]")
                    rRef.OwnTag.TextColor3 = (rOwned > 0) and Color3.fromRGB(82, 232, 168) or Color3.fromRGB(168, 194, 232)
                end
            end
        end
    end

    local outItem = refs.OutItem
    local selectedRecipe = refs.SelectedRecipe
    if outItem and selectedRecipe then
        local ownedCount, curUpgrade = getOwnedCount(snap and snap.inventory or {}, outItem.Id, snap)
        local updatedS = Store.GetWeaponStar(outItem.Id)
        local updatedP = Store.GetWeaponStarPity(outItem.Id)
        local ub = STAR_BONUSES[updatedS] or STAR_BONUSES[1]
        local unb = STAR_BONUSES[math.min(5, updatedS + 1)] or STAR_BONUSES[5]

        if refs.ItemTitleLbl then
            refs.ItemTitleLbl.Text = string.format("%s%s", I18n.GetItemDisplayName(outItem.Id, outItem.Name), curUpgrade > 0 and (" +" .. curUpgrade) or "")
        end
        if refs.MainStarPipsHolder then
            for _, ch in ipairs(refs.MainStarPipsHolder:GetChildren()) do
                ch:Destroy()
            end
            UIFactory.StarPipsRow(refs.MainStarPipsHolder, updatedS, 5, {
                PipSize = 10,
                Gap = 6,
                ZIndex = 8,
            })
        end
        if refs.StarGradeBadgeLbl then
            refs.StarGradeBadgeLbl.Text = string.format("[*%d / *5 • %s]", updatedS, I18n.Pick(ub.TagVi, ub.TagEn))
        end
        if refs.PityLbl then
            refs.PityLbl.Text = I18n.Pick(
                string.format("Chúc Phúc Pity Aether: %d%% / 100%% (Tỉ lệ thành công: %d%%)", updatedP, ub.Rate),
                string.format("Aether Pity Blessing: %d%% / 100%% (Success Rate: %d%%)", updatedP, ub.Rate)
            )
        end
        if refs.PityFill then
            refs.PityFill.Size = UDim2.fromScale(math.clamp(updatedP / 100, 0, 1), 1)
        end
        if refs.StarBonusLbl then
            refs.StarBonusLbl.Text = (updatedS >= 5)
                and I18n.Pick("ĐÃ ĐẠT *5 TỐI ĐA: +22% CRIT • +45% ST KỸ NĂNG", "MAX *5 REACHED: +22% CRIT • +45% SKILL DMG")
                or I18n.Pick(
                    string.format("Đột phá *%d -> *%d: +%d%% CRIT / +%d%% Chiêu (%d Shards + %s G)", updatedS, updatedS + 1, unb.Crit, unb.SkillDmg, ub.ShardCost, UIFactory.FormatNumber(ub.GoldCost)),
                    string.format("Ascend *%d -> *%d: +%d%% CRIT / +%d%% Skill (%d Shards + %s G)", updatedS, updatedS + 1, unb.Crit, unb.SkillDmg, ub.ShardCost, UIFactory.FormatNumber(ub.GoldCost))
                )
        end
        if refs.StatsPreviewLbl then
            local newAtk = (outItem.Stats and outItem.Stats.ATK or 180) + (curUpgrade * 6) + ((updatedS - 1) * 18)
            local newCrit = (outItem.Stats and outItem.Stats.CRIT or 10) + ub.Crit
            local wepMesh = tostring(refs.ResolvedWepAsset or "Wep_Dawnbringer")
            refs.StatsPreviewLbl.Text = I18n.Pick(
                string.format("ATK +%d   •   CRIT +%d%%   •   ST CHIÊU +%d%%\nSở hữu: x%d   •   Tỉ lệ rèn: %d%%   •   Mesh: %s", newAtk, newCrit, ub.SkillDmg, ownedCount, math.floor((selectedRecipe.SuccessRate or 1) * 100), wepMesh),
                string.format("ATK +%d   •   CRIT +%d%%   •   SKILL DMG +%d%%\nOwned: x%d   •   Craft Rate: %d%%   •   Mesh: %s", newAtk, newCrit, ub.SkillDmg, ownedCount, math.floor((selectedRecipe.SuccessRate or 1) * 100), wepMesh)
            )
        end

        rebuildSynthesisCardsRow(refs.SynthesisRow, selectedRecipe, outItem, snap, updatedS, curUpgrade)
        rebuildStarBreakthroughTiers(refs.TiersRow, updatedS)

        if refs.StarBtnApi then
            refs.StarBtnApi:Update({
                variant = (updatedS >= 5) and "secondary" or "mythic",
                disabled = (updatedS >= 5),
                label = (updatedS >= 5)
                    and I18n.Pick("ĐÃ ĐẠT *5 TỐI ĐA", "MAX *5 SOVEREIGN")
                    or I18n.Pick(
                        string.format("THĂNG CẤP SAO *%d -> *%d", updatedS, math.min(5, updatedS + 1)),
                        string.format("ASCEND STAR *%d -> *%d", updatedS, math.min(5, updatedS + 1))
                    ),
            })
        end

        local anvilState = computeAnvilActionState(snap, selectedRecipe, ownedCount, curUpgrade)
        if refs.CraftBtnApi and not Forge.PendingLock then
            refs.CraftBtnApi:Update({
                label = anvilState.Label,
                variant = anvilState.IsMax and "secondary" or (anvilState.Ready and "gold" or "primary"),
                disabled = anvilState.IsMax,
            })
        end
    end
end

function Forge.Cleanup()
    clearActiveFX()
    if Forge.OrbitController then
        Forge.OrbitController:Destroy()
        Forge.OrbitController = nil
    end
    Forge.PendingLock = false
    Forge.Refs = {}
end

return Forge
