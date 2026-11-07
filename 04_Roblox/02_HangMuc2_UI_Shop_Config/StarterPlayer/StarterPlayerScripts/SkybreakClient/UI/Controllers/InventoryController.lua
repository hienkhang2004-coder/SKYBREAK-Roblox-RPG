-- SKYBREAK: Fragments of the Core — Inventory, Paperdoll Equipment & 3D ViewportFrame Controller
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Controllers/InventoryController.lua
-- Handles filtering (including Accessories), sorting, Equip Best Loadout, server-validated equip requests,
-- Stat Diff computation (#97), and leak-free 3D Hero Paperdoll (with glowing 3D cyan rune rings) & 3D Weapon preview.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local RarityConfig = require(Shared:WaitForChild("Config"):WaitForChild("RarityConfig"))
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))

local Store = require(script.Parent.Parent:WaitForChild("Store"))
local I18n = require(script.Parent.Parent:WaitForChild("I18n"))
local ViewportOrbit = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("ViewportOrbit"))
local Tooltip = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("Tooltip"))

local InventoryController = {
    ActiveOrbit = nil,
    CurrentPreviewKey = nil,
}

function InventoryController.GetEquippedInfoForSlot(slotName, snap)
    snap = snap or Store.GetSnapshot()
    if not slotName or not snap then
        return nil, nil, 0, 1
    end
    local eqMap = snap.equipped or snap.equipment
    local eqId = eqMap and eqMap[slotName]
    if not eqId and slotName == "Weapon" then
        local p = Players.LocalPlayer
        local attrSword = p and p:GetAttribute("EquippedSword")
        if type(attrSword) == "string" and attrSword ~= "" then
            eqId = attrSword
        end
    elseif not eqId and slotName == "Gun" then
        local p = Players.LocalPlayer
        local attrGun = p and p:GetAttribute("EquippedGun")
        if type(attrGun) == "string" and attrGun ~= "" then
            eqId = attrGun
        end
    end
    if not eqId then
        return nil, nil, 0, 1
    end
    local eqCfg = RarityConfig.GetItem(eqId)
    local eqUpg = 0
    for _, entry in ipairs(snap.inventory or {}) do
        if entry.itemId == eqId then
            eqUpg = tonumber(entry.upgrade) or 0
            break
        end
    end
    local eqStars = Store.GetWeaponStar(eqId)
    return eqId, eqCfg, eqUpg, eqStars
end

function InventoryController.ComputePrimaryDiffDelta(itemId, itemCfg, upgrade, stars, isEquipped, snap)
    if isEquipped or not itemCfg or not itemCfg.Slot then
        return nil
    end
    local _, eqCfg, eqUpg, eqStars = InventoryController.GetEquippedInfoForSlot(itemCfg.Slot, snap)
    local diffs = Tooltip.ComputeStatDiffs(itemCfg, upgrade, stars, eqCfg, eqUpg, eqStars)
    if #diffs == 0 then
        return nil
    end
    for _, pref in ipairs({ "ATK", "DEF", "HP" }) do
        for _, d in ipairs(diffs) do
            if d.stat == pref and (d.value > 0 or d.equippedValue > 0) then
                return d.diff
            end
        end
    end
    return diffs[1].diff
end

function InventoryController.GetFilteredInventory()
    local snap = Store.GetSnapshot()
    local view = Store.GetView()
    local filter = view.inventoryFilter or "All"
    local sortMode = view.inventorySort or "Rarity"
    local query = string.lower(view.searchQuery or "")
    local eqMap = snap.equipped or snap.equipment or {}

    local results = {}
    for _, entry in ipairs(snap.inventory or {}) do
        if (entry.count or 0) > 0 then
            local cfg = RarityConfig.GetItem(entry.itemId)
            if cfg then
                local isAccessory = (cfg.Slot == "Offhand" or cfg.Slot == "Ring" or cfg.Slot == "Artifact" or cfg.Category == "Accessories")
                local categoryMatch = (filter == "All")
                    or (filter == "Equipment" and cfg.Slot ~= nil)
                    or (filter == "Weapons" and (cfg.Category == "Weapons" or cfg.Slot == "Weapon" or cfg.Slot == "Gun"))
                    or (filter == "Armor" and (cfg.Category == "Armor" or cfg.Slot == "Helm" or cfg.Slot == "Chest" or cfg.Slot == "Gauntlets" or cfg.Slot == "Greaves"))
                    or (filter == "Accessories" and isAccessory)
                    or (filter == "Materials" and cfg.Category == "Materials")
                    or (filter == "Quest" and cfg.Category == "Quest")

                local dispName = I18n.GetItemDisplayName(entry.itemId, cfg.Name)
                local searchMatch = (query == "")
                    or (string.find(string.lower(cfg.Name or ""), query, 1, true) ~= nil)
                    or (string.find(string.lower(dispName or ""), query, 1, true) ~= nil)
                    or (string.find(string.lower(cfg.VietnameseName or ""), query, 1, true) ~= nil)
                    or (string.find(string.lower(entry.itemId), query, 1, true) ~= nil)

                if categoryMatch and searchMatch then
                    local isEq = (eqMap[cfg.Slot or ""] == entry.itemId) or entry.equipped == true
                    local upg = tonumber(entry.upgrade) or 0
                    local stars = Store.GetWeaponStar(entry.itemId)
                    local diffDelta = InventoryController.ComputePrimaryDiffDelta(entry.itemId, cfg, upg, stars, isEq, snap)
                    table.insert(results, {
                        itemId = entry.itemId,
                        displayName = dispName,
                        count = entry.count,
                        upgrade = upg,
                        stars = (cfg.Slot == "Weapon" or cfg.Slot == "Gun") and stars or 0,
                        diffDelta = diffDelta,
                        equipped = isEq,
                        config = cfg,
                        rarity = RarityConfig.GetRarity(cfg.Rarity),
                    })
                end
            end
        end
    end

    table.sort(results, function(a, b)
        if sortMode == "Level" then
            local la = a.config.LevelReq or 1
            local lb = b.config.LevelReq or 1
            if la ~= lb then
                return la > lb
            end
        elseif sortMode == "Name" then
            local na = a.displayName or a.config.Name or a.itemId
            local nb = b.displayName or b.config.Name or b.itemId
            if na ~= nb then
                return na < nb
            end
        end
        if a.rarity.Tier ~= b.rarity.Tier then
            return a.rarity.Tier > b.rarity.Tier
        end
        return (a.displayName or a.config.Name) < (b.displayName or b.config.Name)
    end)

    return results
end

function InventoryController.RequestEquipToggle(itemId, currentlyEquipped, silentToast)
    local snap = Store.GetSnapshot()
    local cfg = RarityConfig.GetItem(itemId)
    if not cfg or not cfg.Slot then
        if not silentToast then
            Store.ShowToast(I18n.Pick("Vật phẩm này không thể trang bị.", "Selected item cannot be equipped."), "warning")
        end
        return false
    end

    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local skyRemotes = Shared:FindFirstChild("Remotes")
    local reqUIAction = skyRemotes and skyRemotes:FindFirstChild("RequestUIAction")
    if (remotes or reqUIAction) and not snap.isDemoMode then
        local equipRemote = remotes and remotes:FindFirstChild("EquipmentRequest")
        local uiCmd = remotes and remotes:FindFirstChild("UICommand")
        local isGun = (cfg.Slot == "Gun" or cfg.WeaponType == "Gun" or cfg.Icon == "Gun")

        if equipRemote then
            if isGun then
                equipRemote:FireServer({
                    action = currentlyEquipped and "Unequip" or "EquipGun",
                    gunId = itemId,
                    itemId = itemId,
                    slot = "Gun",
                })
            else
                local serverSlotMap = {
                    Helm = "Helmet",
                    Gauntlets = "Gloves",
                    Greaves = "Boots",
                    Offhand = "Necklace",
                }
                equipRemote:FireServer({
                    action = currentlyEquipped and "Unequip" or "Equip",
                    swordId = itemId,
                    itemId = itemId,
                    slot = serverSlotMap[cfg.Slot] or cfg.Slot,
                })
            end
        elseif reqUIAction and not currentlyEquipped then
            reqUIAction:FireServer("EquipItem", {
                itemId = itemId,
                slot = cfg.Slot,
            })
        elseif uiCmd then
            uiCmd:FireServer({
                command = "EquipItem",
                itemId = itemId,
                slot = cfg.Slot,
                unequip = currentlyEquipped,
            })
        end
        Store.ApplyDemoPreviewAction("EquipItem", { itemId = itemId })
        if not silentToast then
            local disp = I18n.GetItemDisplayName(itemId, cfg.Name)
            Store.ShowToast(
                currentlyEquipped and (I18n.Pick("Đang tháo ", "Unequipping ") .. disp .. "...")
                    or (I18n.Pick("Đã trang bị 3D ", "Equipped 3D ") .. disp .. "!"),
                "success"
            )
        end
        return true
    end

    Store.ApplyDemoPreviewAction("EquipItem", { itemId = itemId })
    return true
end

local function computeItemCombatScore(itemId, cfg, upgrade, stars)
    if not cfg then
        return 0
    end
    local rarity = RarityConfig.GetRarity(cfg.Rarity)
    local upg = tonumber(upgrade) or 0
    local st = math.max(1, tonumber(stars) or 1)
    local mult = (1 + upg * (rarity.UpgradeMultiplier or 0.08)) * (1 + (st - 1) * 0.06)
    local statScore = 0
    if type(cfg.Stats) == "table" then
        statScore = statScore
            + ((tonumber(cfg.Stats.ATK) or 0) * 3.4)
            + ((tonumber(cfg.Stats.DEF) or 0) * 2.5)
            + ((tonumber(cfg.Stats.HP) or 0) * 0.45)
            + ((tonumber(cfg.Stats.CRIT) or tonumber(cfg.Stats.CritRate) or 0) * 14)
            + ((tonumber(cfg.Stats.ENERGY) or 0) * 0.8)
    end
    return (rarity.Tier or 1) * 5000 + (statScore * mult)
end

function InventoryController.EquipBestLoadout()
    local snap = Store.GetSnapshot()
    local bestBySlot = {}

    for _, entry in ipairs(snap.inventory or {}) do
        if (entry.count or 0) > 0 then
            local cfg = RarityConfig.GetItem(entry.itemId)
            if cfg and cfg.Slot then
                local upg = tonumber(entry.upgrade) or 0
                local st = (cfg.Slot == "Weapon" or cfg.Slot == "Gun") and Store.GetWeaponStar(entry.itemId) or 1
                local score = computeItemCombatScore(entry.itemId, cfg, upg, st)
                local curBest = bestBySlot[cfg.Slot]
                if not curBest or score > curBest.score then
                    bestBySlot[cfg.Slot] = {
                        itemId = entry.itemId,
                        score = score,
                    }
                end
            end
        end
    end

    local eqMap = snap.equipped or snap.equipment or {}
    local equippedCount = 0
    for slotName, best in pairs(bestBySlot) do
        local curEqId = eqMap[slotName]
        local curScore = -1
        if curEqId then
            local curCfg = RarityConfig.GetItem(curEqId)
            local _, _, curUpg, curStars = InventoryController.GetEquippedInfoForSlot(slotName, snap)
            curScore = computeItemCombatScore(curEqId, curCfg, curUpg, curStars)
        end
        if curEqId ~= best.itemId and best.score > curScore then
            if InventoryController.RequestEquipToggle(best.itemId, false, true) then
                equippedCount = equippedCount + 1
            end
        end
    end

    if equippedCount > 0 then
        Store.ShowToast(
            I18n.Pick(
                string.format("Đã trang bị tối ưu %d món thần trang mạnh nhất!", equippedCount),
                string.format("Equipped %d optimal gear upgrades!", equippedCount)
            ),
            "success"
        )
    else
        Store.ShowToast(
            I18n.Pick("Bộ trang bị 3D hiện tại đã ở mức tối ưu nhất!", "Your current 3D loadout is already optimal!"),
            "info"
        )
    end
    return equippedCount
end

function InventoryController.CloneCharacterForViewport()
    local player = Players.LocalPlayer
    local snap = Store.GetSnapshot()
    local classId = (player and player:GetAttribute("ClassId")) or (snap and snap.player and snap.player.classId) or "SkyGuardian"
    local gender = (player and player:GetAttribute("SkybornGender")) or (snap and snap.player and snap.player.gender) or "Male"
    local stage = (player and player:GetAttribute("OutfitStage")) or "SkyGuardian"
    local ch = player and player.Character
    local fTrans = ch and ch:GetAttribute("FruitTransform") or ""

    if ch and fTrans == "" and (ch:FindFirstChild("HumanoidRootPart") or ch.PrimaryPart) then
        local prevArch = ch.Archivable
        ch.Archivable = true
        local okClone, clonedChar = pcall(function()
            return ch:Clone()
        end)
        ch.Archivable = prevArch
        if okClone and clonedChar then
            local refHRP = clonedChar:FindFirstChild("HumanoidRootPart") or clonedChar.PrimaryPart
            local refPos = refHRP and refHRP.Position or nil
            local visibleParts = 0
            for _, d in ipairs(clonedChar:GetDescendants()) do
                if d:IsA("Script") or d:IsA("LocalScript") or d:IsA("BillboardGui") or d:IsA("ProximityPrompt") or d:IsA("ForceField") then
                    d:Destroy()
                elseif d:IsA("BasePart") then
                    if (refPos and (d.Position - refPos).Magnitude > 14) or (d.Transparency >= 0.99 and d.Name ~= "HumanoidRootPart" and d.Name ~= "RootPart") then
                        d:Destroy()
                    else
                        d.Anchored = true
                        d.CanCollide = false
                        d.CanQuery = false
                        d.CanTouch = false
                        if d.Transparency < 0.85 and d.Name ~= "HumanoidRootPart" and d.Name ~= "RootPart" then
                            visibleParts += 1
                        end
                    end
                end
            end
            if visibleParts > 0 then
                return clonedChar, nil, nil
            end
            clonedChar:Destroy()
        end
    end

    local assetName = "Male_SkyGuardian"
    if fTrans == "SolarTitan" then
        assetName = "SolarTitanBuddha"
    elseif fTrans == "AbyssalSovereign" then
        assetName = "AbyssalSovereignDragon"
    elseif fTrans == "AbyssalDragonHybrid" then
        assetName = "AbyssalDragonHybrid"
    elseif classId == "ThunderStriker" then
        assetName = (gender == "Female") and "ThunderStrikerFemale" or "ThunderStriker"
    elseif classId == "ArcaneMage" then
        assetName = (gender == "Female") and "ArcaneMageFemale" or "ArcaneMage"
    else
        assetName = string.format("%s_%s", (gender == "Female") and "Female" or "Male", stage)
    end

    local renderer = ViewportOrbit.GetRenderer()
    if renderer and type(renderer.CloneModel) == "function" then
        local okB, built = pcall(renderer.CloneModel, assetName, 0)
        if okB and built then
            local activeClip = nil
            if type(renderer.Clips) == "function" then
                local okC, clips = pcall(renderer.Clips, assetName)
                if okC and type(clips) == "table" then
                    activeClip = clips.HeroicKata or clips.ElementalSurge or clips.Idle
                end
            end
            return built, renderer, activeClip
        end
    elseif renderer and type(renderer.Build) == "function" then
        local okB, tmpl = pcall(renderer.Build, assetName)
        if okB and tmpl then
            local built = tmpl:Clone()
            local activeClip = nil
            if type(renderer.Clips) == "function" then
                local okC, clips = pcall(renderer.Clips, assetName)
                if okC and type(clips) == "table" then
                    activeClip = clips.HeroicKata or clips.ElementalSurge or clips.Idle
                end
            end
            return built, renderer, activeClip
        end
    end

    if ch then
        local prevArch = ch.Archivable
        ch.Archivable = true
        local okClone, clonedChar = pcall(function()
            return ch:Clone()
        end)
        ch.Archivable = prevArch
        if okClone and clonedChar then
            return clonedChar, nil, nil
        end
    end
    return nil, nil, nil
end

local function attachHeroCyanRuneRings(worldModel, heroModel)
    if not worldModel or not heroModel then
        return nil
    end
    local okBox, boxCf, boxSize = pcall(function()
        return heroModel:GetBoundingBox()
    end)
    local footY = -2.4
    local baseSpan = 3.6
    if okBox and boxCf and boxSize then
        footY = boxCf.Position.Y - (boxSize.Y * 0.5) + 0.08
        baseSpan = math.clamp(math.max(boxSize.X, boxSize.Z) * 1.15, 3.0, 5.4)
    end

    local pedestal = Instance.new("Model")
    pedestal.Name = "HeroCyanRunePedestal"

    -- Outer glowing Cyan Aether ring
    local outerRing = Instance.new("Part")
    outerRing.Name = "OuterCyanRing"
    outerRing.Shape = Enum.PartType.Cylinder
    outerRing.Material = Enum.Material.Neon
    outerRing.Color = Color3.fromRGB(56, 214, 255)
    outerRing.Transparency = 0.28
    outerRing.Size = Vector3.new(0.05, baseSpan, baseSpan)
    outerRing.CFrame = CFrame.new(0, footY, 0) * CFrame.Angles(0, 0, math.rad(90))
    outerRing.Anchored = true
    outerRing.CanCollide = false
    outerRing.CanQuery = false
    outerRing.CanTouch = false
    outerRing.CastShadow = false
    outerRing.Parent = pedestal

    -- Dark obsidian core mask so outer ring reads as a sharp neon halo ring
    local outerVoid = Instance.new("Part")
    outerVoid.Name = "OuterVoidMask"
    outerVoid.Shape = Enum.PartType.Cylinder
    outerVoid.Material = Enum.Material.SmoothPlastic
    outerVoid.Color = Color3.fromRGB(10, 16, 30)
    outerVoid.Transparency = 0.14
    outerVoid.Size = Vector3.new(0.06, baseSpan * 0.87, baseSpan * 0.87)
    outerVoid.CFrame = CFrame.new(0, footY + 0.005, 0) * CFrame.Angles(0, 0, math.rad(90))
    outerVoid.Anchored = true
    outerVoid.CanCollide = false
    outerVoid.CanQuery = false
    outerVoid.CanTouch = false
    outerVoid.CastShadow = false
    outerVoid.Parent = pedestal

    -- Inner concentric Champagne-Cyan rune ring
    local innerSpan = baseSpan * 0.64
    local innerRing = Instance.new("Part")
    innerRing.Name = "InnerRuneRing"
    innerRing.Shape = Enum.PartType.Cylinder
    innerRing.Material = Enum.Material.Neon
    innerRing.Color = Color3.fromRGB(142, 236, 255)
    innerRing.Transparency = 0.24
    innerRing.Size = Vector3.new(0.07, innerSpan, innerSpan)
    innerRing.CFrame = CFrame.new(0, footY + 0.012, 0) * CFrame.Angles(0, 0, math.rad(90))
    innerRing.Anchored = true
    innerRing.CanCollide = false
    innerRing.CanQuery = false
    innerRing.CanTouch = false
    innerRing.CastShadow = false
    innerRing.Parent = pedestal

    local innerVoid = Instance.new("Part")
    innerVoid.Name = "InnerVoidMask"
    innerVoid.Shape = Enum.PartType.Cylinder
    innerVoid.Material = Enum.Material.SmoothPlastic
    innerVoid.Color = Color3.fromRGB(12, 20, 38)
    innerVoid.Transparency = 0.20
    innerVoid.Size = Vector3.new(0.08, innerSpan * 0.84, innerSpan * 0.84)
    innerVoid.CFrame = CFrame.new(0, footY + 0.016, 0) * CFrame.Angles(0, 0, math.rad(90))
    innerVoid.Anchored = true
    innerVoid.CanCollide = false
    innerVoid.CanQuery = false
    innerVoid.CanTouch = false
    innerVoid.CastShadow = false
    innerVoid.Parent = pedestal

    -- 4 Cardinal floating cyan-gold rune nodes around outer ring
    local nodeRadius = baseSpan * 0.48
    local runeNodes = {}
    for i = 1, 4 do
        local node = Instance.new("Part")
        node.Name = "RuneNode_" .. tostring(i)
        node.Material = Enum.Material.Neon
        node.Color = (i % 2 == 0) and Color3.fromRGB(250, 210, 108) or Color3.fromRGB(72, 224, 255)
        node.Transparency = 0.12
        node.Size = Vector3.new(0.16, 0.08, 0.16)
        local ang = (i - 1) * (math.pi * 0.5)
        node.CFrame = CFrame.new(math.cos(ang) * nodeRadius, footY + 0.06, math.sin(ang) * nodeRadius)
            * CFrame.Angles(0, ang + math.rad(45), 0)
        node.Anchored = true
        node.CanCollide = false
        node.CanQuery = false
        node.CanTouch = false
        node.CastShadow = false
        node.Parent = pedestal
        table.insert(runeNodes, node)
    end

    pedestal.Parent = worldModel
    return {
        Pedestal = pedestal,
        Nodes = runeNodes,
        FootY = footY,
        NodeRadius = nodeRadius,
    }
end

function InventoryController.MountViewportPreview(viewportFrame, selectedItemId)
    if not viewportFrame then
        return false
    end

    -- Default to Hero 3D Paperdoll mode so opening Inventory [I] showcases the full 3D Character Paperdoll!
    if Store.Session.inventoryPreviewMode == nil then
        Store.Session.inventoryPreviewMode = "Hero"
    end

    if not InventoryController.ActiveOrbit or InventoryController.ActiveOrbit.Viewport ~= viewportFrame then
        InventoryController.CleanupViewport()
        InventoryController.ActiveOrbit = ViewportOrbit.Attach(viewportFrame, {
            AutoSpinSpeed = 0.38,
            InitialYaw = math.rad(24),
            InitialPitch = math.rad(10),
            ShowHint = false,
            FieldOfView = 34,
        })
    end

    local orbit = InventoryController.ActiveOrbit
    local mode = Store.Session.inventoryPreviewMode or "Hero"
    local snap = Store.GetSnapshot()
    local eqMap = snap.equipped or snap.equipment or {}
    local targetId = selectedItemId or Store.GetView().selectedItemId or eqMap.Weapon or "sunshard_halberd"
    local resolvedAsset = ViewportOrbit.ResolveAssetName(tostring(targetId))
    local assetOrItemId = resolvedAsset or tostring(targetId)

    local previewKey = (mode == "Hero")
        and (
            "Hero:"
            .. tostring(snap.player and snap.player.classId or "SkyGuardian")
            .. ":" .. tostring(eqMap.Weapon or "")
            .. ":" .. tostring(eqMap.Offhand or "")
            .. ":" .. tostring(eqMap.Helm or "")
            .. ":" .. tostring(eqMap.Chest or "")
            .. ":" .. tostring(eqMap.Gauntlets or "")
            .. ":" .. tostring(eqMap.Greaves or "")
            .. ":" .. tostring(eqMap.Ring or "")
            .. ":" .. tostring(eqMap.Artifact or "")
        )
        or ("Weapon:" .. assetOrItemId)

    if InventoryController.CurrentPreviewKey == previewKey and orbit:GetActiveModel() ~= nil then
        return true
    end
    InventoryController.CurrentPreviewKey = previewKey

    if mode == "Weapon" and assetOrItemId ~= "" then
        local itemCfg = RarityConfig.GetItem(targetId)
        local rarity = itemCfg and RarityConfig.GetRarity(itemCfg.Rarity)
        local accent = (rarity and rarity.Color) or Theme.Colors.ACCENT_GOLD
        orbit:SetCustomStep(nil)
        ViewportOrbit.MountAssetAsync(orbit, assetOrItemId, accent, {
            FitMultiplier = 1.05,
            ResetAngles = false,
            UprightWeapon = resolvedAsset ~= nil and string.sub(resolvedAsset, 1, 4) == "Wep_",
        })
        return true
    end

    -- Hero 3D Paperdoll Rig + Concentric Cyan Rune Rings Pedestal
    task.spawn(function()
        local heroModel, renderer, activeClip = InventoryController.CloneCharacterForViewport()
        if InventoryController.ActiveOrbit ~= orbit or InventoryController.CurrentPreviewKey ~= previewKey then
            if heroModel then
                heroModel:Destroy()
            end
            return
        end
        if heroModel then
            if renderer and activeClip and type(renderer.Pose) == "function" then
                pcall(renderer.Pose, heroModel, activeClip, os.clock())
            end
            orbit:SetModel(heroModel, {
                FitMultiplier = 1.08,
                InitialYaw = math.rad(166),
                InitialPitch = math.rad(7),
                ResetAngles = true,
            })
            local ringState = attachHeroCyanRuneRings(orbit.WorldModel, heroModel)
            orbit:SetCustomStep(function(_, elapsed, mdl)
                if renderer and activeClip and type(renderer.Pose) == "function" and mdl and mdl.Parent then
                    pcall(renderer.Pose, mdl, activeClip, os.clock())
                end
                if ringState and ringState.Pedestal and ringState.Pedestal.Parent then
                    for idx, node in ipairs(ringState.Nodes) do
                        local ang = (idx - 1) * (math.pi * 0.5) + elapsed * 0.85
                        local bob = math.sin(elapsed * 2.4 + idx) * 0.03
                        node.CFrame = CFrame.new(
                            math.cos(ang) * ringState.NodeRadius,
                            ringState.FootY + 0.06 + bob,
                            math.sin(ang) * ringState.NodeRadius
                        ) * CFrame.Angles(0, ang + math.rad(45), 0)
                    end
                end
            end)
            return
        end
        local fallbackModel = ViewportOrbit.BuildFallback3DWeapon(tostring(targetId), Theme.Colors.ACCENT_GOLD)
        orbit:SetCustomStep(nil)
        orbit:SetModel(fallbackModel, { FitMultiplier = 1.1, ResetAngles = true })
    end)
    return true
end

function InventoryController.UpdateCameraRotation(_deltaRadians)
    if InventoryController.ActiveOrbit then
        InventoryController.ActiveOrbit:ResetView()
    end
end

function InventoryController.CleanupViewport()
    InventoryController.CurrentPreviewKey = nil
    if InventoryController.ActiveOrbit then
        InventoryController.ActiveOrbit:Destroy()
        InventoryController.ActiveOrbit = nil
    end
end

return InventoryController
