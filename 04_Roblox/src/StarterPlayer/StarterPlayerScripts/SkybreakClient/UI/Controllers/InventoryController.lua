-- SKYBREAK: Fragments of the Core — Inventory, Equipment & 3D ViewportFrame Controller
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Controllers/InventoryController.lua
-- Handles filtering, sorting, server-validated equip requests, and leak-free ViewportFrame 3D preview (Section 10.4).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local RarityConfig = require(Shared:WaitForChild("Config"):WaitForChild("RarityConfig"))
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))

local Store = require(script.Parent.Parent:WaitForChild("Store"))
local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))

local InventoryController = {
    ActiveViewportModel = nil,
    ActiveViewportCamera = nil,
    CurrentYaw = math.rad(165),
}

function InventoryController.GetFilteredInventory()
    local snap = Store.GetSnapshot()
    local view = Store.GetView()
    local filter = view.inventoryFilter or "All"
    local sortMode = view.inventorySort or "Rarity"
    local query = string.lower(view.searchQuery or "")

    local results = {}
    for _, entry in ipairs(snap.inventory or {}) do
        if (entry.count or 0) > 0 then
            local cfg = RarityConfig.GetItem(entry.itemId)
            if cfg then
                local categoryMatch = (filter == "All")
                    or (filter == "Equipment" and cfg.Slot ~= nil)
                    or (filter == "Weapons" and cfg.Category == "Weapons")
                    or (filter == "Armor" and cfg.Category == "Armor")
                    or (filter == "Materials" and cfg.Category == "Materials")
                    or (filter == "Quest" and cfg.Category == "Quest")

                local searchMatch = (query == "")
                    or (string.find(string.lower(cfg.Name or ""), query, 1, true) ~= nil)
                    or (string.find(string.lower(cfg.VietnameseName or ""), query, 1, true) ~= nil)
                    or (string.find(string.lower(entry.itemId), query, 1, true) ~= nil)

                if categoryMatch and searchMatch then
                    table.insert(results, {
                        itemId = entry.itemId,
                        count = entry.count,
                        upgrade = entry.upgrade or 0,
                        equipped = (snap.equipped and snap.equipped[cfg.Slot or ""] == entry.itemId) or entry.equipped == true,
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
            if la ~= lb then return la > lb end
        elseif sortMode == "Name" then
            if a.config.Name ~= b.config.Name then
                return a.config.Name < b.config.Name
            end
        end
        if a.rarity.Tier ~= b.rarity.Tier then
            return a.rarity.Tier > b.rarity.Tier
        end
        return a.config.Name < b.config.Name
    end)

    return results
end

function InventoryController.RequestEquipToggle(itemId, currentlyEquipped)
    local snap = Store.GetSnapshot()
    local cfg = RarityConfig.GetItem(itemId)
    if not cfg or not cfg.Slot then
        Store.ShowToast("Selected item cannot be equipped.", "warning")
        return
    end

    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    if remotes and not snap.isDemoMode then
        -- Live server supports starter weapons via EquipmentRequest and extended slots via UICommand
        local equipRemote = remotes:FindFirstChild("EquipmentRequest")
        local uiCmd = remotes:FindFirstChild("UICommand")
        if cfg.Slot == "Weapon" and (itemId == "starter_sword" or itemId == "starter_daggers" or itemId == "starter_staff") and equipRemote then
            equipRemote:FireServer({
                action = currentlyEquipped and "Unequip" or "Equip",
                itemId = itemId,
            })
            Store.ShowToast(currentlyEquipped and ("Unequipping " .. cfg.Name .. "...") or ("Equipping " .. cfg.Name .. "..."), "info")
            return
        elseif uiCmd then
            uiCmd:FireServer({
                command = "EquipItem",
                itemId = itemId,
                slot = cfg.Slot,
                unequip = currentlyEquipped,
            })
            return
        end
    end

    Store.ApplyDemoPreviewAction("EquipItem", { itemId = itemId })
end

-- Build player's live 3D V5 Hero Rig (or Fruit Transformation Rig) with skeletal animation for Inventory ViewportFrame
function InventoryController.CloneCharacterForViewport()
    local player = Players.LocalPlayer
    local snap = Store.GetSnapshot()
    local classId = (player and player:GetAttribute("ClassId")) or (snap and snap.player and snap.player.classId) or "SkyGuardian"
    local gender = (player and player:GetAttribute("SkybornGender")) or (snap and snap.player and snap.player.gender) or "Male"
    local stage = (player and player:GetAttribute("OutfitStage")) or "SkyGuardian"
    local ch = player and player.Character
    local fTrans = ch and ch:GetAttribute("FruitTransform") or ""

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

    local okR, Renderer = pcall(function()
        return require(ReplicatedStorage:WaitForChild("DelegatedV5Renderer", 2))
    end)
    if okR and Renderer then
        local okB, built = pcall(Renderer.Build, assetName)
        if okB and built then
            pcall(function()
                built:PivotTo(CFrame.identity)
            end)
            local okC, clips = pcall(Renderer.Clips, assetName)
            if okC and type(clips) == "table" then
                local activeClip = clips.HeroicKata or clips.ElementalSurge or clips.Idle
                if activeClip then
                    pcall(Renderer.Pose, built, activeClip, os.clock())
                    local RunService = game:GetService("RunService")
                    if InventoryController.ActiveSpinConn then
                        InventoryController.ActiveSpinConn:Disconnect()
                    end
                    InventoryController.ActiveSpinConn = RunService.RenderStepped:Connect(function()
                        if not built or not built.Parent then
                            if InventoryController.ActiveSpinConn then
                                InventoryController.ActiveSpinConn:Disconnect()
                                InventoryController.ActiveSpinConn = nil
                            end
                            return
                        end
                        pcall(Renderer.Pose, built, activeClip, os.clock())
                    end)
                end
            end
            return built
        end
    end
    return nil
end

function InventoryController.MountViewportPreview(viewportFrame, fallbackContainer)
    InventoryController.CleanupViewport()
    if not viewportFrame then
        return false
    end

    for _, child in ipairs(viewportFrame:GetChildren()) do
        if child:IsA("WorldModel") or child:IsA("Camera") or child:IsA("Frame") then
            child:Destroy()
        end
    end

    local clone = InventoryController.CloneCharacterForViewport()
    if clone then
        local worldModel = UIFactory.Create("WorldModel", viewportFrame, {
            Name = "PreviewWorldModel",
        })
        clone.Parent = worldModel

        local cf, size = clone:GetBoundingBox()
        local target = cf.Position
        local distance = math.max(size.Y, size.X, 4) / (2 * math.tan(math.rad(19))) * 1.15

        local camera = UIFactory.Create("Camera", viewportFrame, {
            Name = "PreviewCamera",
            FieldOfView = 38,
        })
        viewportFrame.CurrentCamera = camera
        InventoryController.ActiveViewportModel = clone
        InventoryController.ActiveViewportCamera = camera
        InventoryController.ActiveTarget = target
        InventoryController.ActiveDistance = distance
        InventoryController.ActiveHeightOffset = size.Y * 0.08
        InventoryController.UpdateCameraRotation(0)
        return true
    end

    -- Fallback procedural silhouette crest when character model is not yet spawned
    local fallback = fallbackContainer or viewportFrame
    local silhouette = UIFactory.Create("Frame", fallback, {
        Name = "FallbackCrest",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.48),
        Size = UDim2.fromOffset(148, 190),
        BackgroundColor3 = Theme.Colors.BG_700,
        BackgroundTransparency = 0.25,
        BorderSizePixel = 0,
    })
    UIFactory.Corner(silhouette, Theme.Radius.Large)
    UIFactory.Stroke(silhouette, Theme.Colors.ACCENT_GOLD, 1.5, 0.25)

    local snap = Store.GetSnapshot()
    local classIcon = snap.player.classId == "ThunderStriker" and "Daggers"
        or (snap.player.classId == "ArcaneMage" and "Staff" or "Sword")

    UIFactory.Icon(silhouette, classIcon, UDim2.new(0.5, -32, 0.36, -32), 64, Theme.Colors.ACCENT_GOLD)
    UIFactory.Label(silhouette, {
        Name = "FallbackCaption",
        Text = "3D AVATAR PREVIEW\n(Spawns with Character)",
        Position = UDim2.new(0, 8, 1, -48),
        Size = UDim2.new(1, -16, 0, 40),
        TextSize = 11,
        TextColor = Theme.Colors.TEXT_SECONDARY,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
    })
    return false
end

function InventoryController.UpdateCameraRotation(deltaRadians)
    InventoryController.CurrentYaw += (deltaRadians or 0)
    local cam = InventoryController.ActiveViewportCamera
    local target = InventoryController.ActiveTarget
    local dist = InventoryController.ActiveDistance or 7
    local hOff = InventoryController.ActiveHeightOffset or 0.3
    if cam and target then
        local offset = Vector3.new(
            math.sin(InventoryController.CurrentYaw) * dist,
            hOff,
            math.cos(InventoryController.CurrentYaw) * dist
        )
        cam.CFrame = CFrame.lookAt(target + offset, target)
    end
end

function InventoryController.CleanupViewport()
    if InventoryController.ActiveSpinConn then
        InventoryController.ActiveSpinConn:Disconnect()
        InventoryController.ActiveSpinConn = nil
    end
    if InventoryController.ActiveViewportModel then
        pcall(function()
            InventoryController.ActiveViewportModel:Destroy()
        end)
        InventoryController.ActiveViewportModel = nil
    end
    if InventoryController.ActiveViewportCamera then
        pcall(function()
            InventoryController.ActiveViewportCamera:Destroy()
        end)
        InventoryController.ActiveViewportCamera = nil
    end
end

return InventoryController
