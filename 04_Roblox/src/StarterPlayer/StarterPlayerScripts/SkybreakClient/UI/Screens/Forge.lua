-- SKYBREAK: Fragments of the Core — Screen 6: Forge / Upgrade / Socket Station (Section 10, 11, 12)
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/Forge.lua
-- Features:
--   * Live 3D Weapon ViewportFrame (WorldModel + PreviewCamera) with drag-to-rotate & auto-spin
--   * Pending anti-spam lock on Craft/Upgrade + server confirmation pulse animation
--   * Complete material checklist + server RemoteEvent integration

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local RarityConfig = require(Shared:WaitForChild("Config"):WaitForChild("RarityConfig"))
local UIAnimator = require(Shared:WaitForChild("UIAnimator"))
local MotionTokens = require(Shared:WaitForChild("MotionTokens"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Store = require(script.Parent.Parent:WaitForChild("Store"))
local PremiumPanel = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumPanel"))
local PremiumButton = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumButton"))

local Forge = {
    Refs = {},
    SpinConn = nil,
    DragConn = nil,
    EndConn = nil,
    PendingLock = false,
}

local function getOwnedCount(inventory, itemId)
    for _, entry in ipairs(inventory or {}) do
        if entry.itemId == itemId then
            return entry.count or 0, entry.upgrade or 0
        end
    end
    return 0, 0
end

-- Build an ornate AAA 3D Celestial Weapon Model inside WorldModel for the Forge ViewportFrame
local function build3DWeaponModel(worldModel, outputItem, rarityColor)
    local itemId = tostring(outputItem and outputItem.Id or "Dawnbringer")
    local model = Instance.new("Model")
    model.Name = "SKY_Weapon_" .. itemId

    local bladeColor = rarityColor or Color3.fromHex("#9DE1FF")
    local goldColor = Color3.fromHex("#D7B979")
    local iceColor = Color3.fromHex("#9DE1FF")
    local darkSteel = Color3.fromHex("#132136")

    -- Central Celestial Blade
    local blade = Instance.new("Part")
    blade.Name = "DawnbringerBlade"
    blade.Size = Vector3.new(0.46, 3.7, 0.14)
    blade.CFrame = CFrame.new(0, 0.72, 0)
    blade.Color = bladeColor
    blade.Material = Enum.Material.Neon
    blade.Anchored = true
    blade.CanCollide = false
    blade.Parent = model

    -- Inner Metallic Core Fuller
    local fuller = Instance.new("Part")
    fuller.Name = "BladeCore"
    fuller.Size = Vector3.new(0.22, 3.15, 0.20)
    fuller.CFrame = CFrame.new(0, 0.58, 0)
    fuller.Color = goldColor
    fuller.Material = Enum.Material.Metal
    fuller.Reflectance = 0.45
    fuller.Anchored = true
    fuller.CanCollide = false
    fuller.Parent = model

    -- Swept Winged Celestial Crossguard (Left & Right Articulated Wing Blades)
    for _, side in ipairs({ -1, 1 }) do
        for tier = 1, 3 do
            local wing = Instance.new("Part")
            wing.Name = string.format("CrossguardWing_%d_%d", side, tier)
            wing.Size = Vector3.new(0.85 - tier * 0.15, 0.18, 0.24)
            wing.CFrame = CFrame.new(side * (0.48 + tier * 0.22), -0.98 + tier * 0.08, 0)
                * CFrame.Angles(0, 0, math.rad(side * (24 - tier * 5)))
            wing.Color = (tier == 2) and iceColor or goldColor
            wing.Material = (tier == 2) and Enum.Material.Neon or Enum.Material.Metal
            wing.Reflectance = 0.35
            wing.Anchored = true
            wing.CanCollide = false
            wing.Parent = model
        end
    end

    -- Celestial Halo Ring around the Crossguard Core
    local halo = Instance.new("Part")
    halo.Shape = Enum.PartType.Cylinder
    halo.Name = "AstrolabeHalo"
    halo.Size = Vector3.new(0.12, 1.15, 1.15)
    halo.CFrame = CFrame.new(0, -0.98, 0) * CFrame.Angles(0, math.rad(90), 0)
    halo.Color = goldColor
    halo.Material = Enum.Material.Neon
    halo.Transparency = 0.25
    halo.Anchored = true
    halo.CanCollide = false
    halo.Parent = model

    -- Center Core Gem in Crossguard
    local gem = Instance.new("Part")
    gem.Shape = Enum.PartType.Ball
    gem.Name = "CoreGem"
    gem.Size = Vector3.new(0.48, 0.48, 0.48)
    gem.CFrame = CFrame.new(0, -0.98, 0)
    gem.Color = iceColor
    gem.Material = Enum.Material.Neon
    gem.Anchored = true
    gem.CanCollide = false
    gem.Parent = model

    -- Obsidian Grip & Pommel
    local grip = Instance.new("Part")
    grip.Name = "Grip"
    grip.Size = Vector3.new(0.24, 0.98, 0.24)
    grip.CFrame = CFrame.new(0, -1.65, 0)
    grip.Color = darkSteel
    grip.Material = Enum.Material.SmoothPlastic
    grip.Anchored = true
    grip.CanCollide = false
    grip.Parent = model

    local pommel = Instance.new("Part")
    pommel.Shape = Enum.PartType.Ball
    pommel.Name = "Pommel"
    pommel.Size = Vector3.new(0.42, 0.42, 0.42)
    pommel.CFrame = CFrame.new(0, -2.20, 0)
    pommel.Color = goldColor
    pommel.Material = Enum.Material.Metal
    pommel.Reflectance = 0.4
    pommel.Anchored = true
    pommel.CanCollide = false
    pommel.Parent = model

    model.PrimaryPart = blade
    model.Parent = worldModel
    return model
end

function Forge.Build(parent, responsiveState)
    Forge.Cleanup()
    local colors = Theme.Colors
    local snap = Store.GetSnapshot()
    local view = Store.GetView()
    local isPortrait = responsiveState and responsiveState.IsPortrait

    local root = UIFactory.Create("Frame", parent, {
        Name = "ForgeScreen",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
    })

    -- Left Column: Recipe & Upgrade Blueprint List
    local recipeCard = PremiumPanel.Create(root, {
        name = "RecipeListPanel",
        title = "CELESTIAL FORGE BLUEPRINTS",
        subtitle = "Craft Mythic Blades & Upgrade Equipped Gear",
        position = UDim2.fromOffset(0, 0),
        size = isPortrait and UDim2.new(1, 0, 0.44, -8) or UDim2.new(0.44, -8, 1, 0),
    })

    local recipeScroll = UIFactory.Create("ScrollingFrame", recipeCard, {
        Name = "RecipeScroll",
        Position = UDim2.fromOffset(14, 60),
        Size = UDim2.new(1, -28, 1, -74),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 5,
        ScrollBarImageColor3 = colors.ACCENT_SAPPHIRE,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.fromOffset(0, 0),
    })
    UIFactory.ListLayout(recipeScroll, Enum.FillDirection.Vertical, 8)

    local recipes = RarityConfig.Recipes or RarityConfig.ForgeRecipes or {}
    local selectedRecipe = recipes[1]
    for idx, recipe in ipairs(recipes) do
        if recipe.Id == view.selectedRecipeId then
            selectedRecipe = recipe
        end
        local isSel = (recipe.Id == (view.selectedRecipeId or (recipes[1] and recipes[1].Id)))
        local outItem = RarityConfig.GetItem(recipe.OutputItemId) or RarityConfig.Items.Dawnbringer
        local rInfo = RarityConfig.GetRarity(outItem.Rarity)

        local row = UIFactory.Create("TextButton", recipeScroll, {
            Name = "Recipe_" .. recipe.Id,
            Size = UDim2.new(1, -6, 0, 74),
            BackgroundColor3 = isSel and colors.BG_700 or colors.BG_900,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            LayoutOrder = idx,
        })
        UIFactory.Corner(row, Theme.Radius.Medium)
        UIFactory.Stroke(row, isSel and colors.ACCENT_GOLD or rInfo.Color, isSel and 1.8 or 1.2, 0.2)

        UIFactory.Icon(row, outItem.Icon or "Sword", UDim2.fromOffset(12, 16), 34, rInfo.Color)

        UIFactory.Label(row, {
            Name = "Title",
            Text = recipe.Name,
            Position = UDim2.fromOffset(58, 10),
            Size = UDim2.new(1, -70, 0, 22),
            TextSize = 14,
            TextColor = colors.TEXT_PRIMARY,
            Bold = true,
        })

        UIFactory.Label(row, {
            Name = "Sub",
            Text = string.format("%s  •  Gold Cost: %s", tostring(recipe.Category or recipe.Type or "Craft"), UIFactory.FormatNumber(recipe.GoldCost or 0)),
            Position = UDim2.fromOffset(58, 34),
            Size = UDim2.new(1, -70, 0, 20),
            TextSize = 12,
            TextColor = rInfo.Color,
            Bold = true,
        })

        row.Activated:Connect(function()
            Store.SetView({ selectedRecipeId = recipe.Id })
        end)
    end

    -- Right Column: Forge Anvil Workbench + 3D Rotating Weapon ViewportFrame
    local anvilCard = PremiumPanel.Create(root, {
        name = "AnvilPanel",
        title = string.upper(selectedRecipe.Name),
        subtitle = selectedRecipe.Description,
        position = isPortrait and UDim2.new(0, 0, 0.44, 8) or UDim2.new(0.44, 8, 0, 0),
        size = isPortrait and UDim2.new(1, 0, 0.56, -8) or UDim2.new(0.56, -8, 1, 0),
    })

    local outItem = RarityConfig.GetItem(selectedRecipe.OutputItemId)
    local rInfo = RarityConfig.GetRarity(outItem.Rarity)
    local ownedCount, currentUpgrade = getOwnedCount(snap.inventory, selectedRecipe.OutputItemId)

    -- Section 10 & Section 11: Live 3D Weapon ViewportFrame with WorldModel & PreviewCamera
    local previewBox = UIFactory.Create("Frame", anvilCard, {
        Name = "ForgePreview",
        Position = UDim2.fromOffset(18, 62),
        Size = UDim2.new(1, -36, 0, 128),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
    })
    local previewScale = Instance.new("UIScale")
    previewScale.Name = "UIScale"
    previewScale.Scale = 1.0
    previewScale.Parent = previewBox

    UIFactory.Corner(previewBox, Theme.Radius.Medium)
    UIFactory.Stroke(previewBox, rInfo.Color, 1.6, 0.15)

    local weaponViewport = UIFactory.Create("ViewportFrame", previewBox, {
        Name = "WeaponViewport",
        Position = UDim2.fromOffset(8, 6),
        Size = UDim2.fromOffset(132, 116),
        BackgroundColor3 = colors.BG_800,
        BackgroundTransparency = 0.2,
        Ambient = Color3.fromRGB(185, 205, 235),
        LightColor = Color3.fromRGB(255, 244, 214),
        LightDirection = Vector3.new(-1, -1, -1),
    })
    UIFactory.Corner(weaponViewport, Theme.Radius.Small)
    UIFactory.Stroke(weaponViewport, rInfo.Color, 1.0, 0.35)

    local worldModel = Instance.new("WorldModel")
    worldModel.Name = "WorldModel"
    worldModel.Parent = weaponViewport

    local previewCamera = Instance.new("Camera")
    previewCamera.Name = "PreviewCamera"
    previewCamera.FieldOfView = 36
    previewCamera.Parent = weaponViewport
    weaponViewport.CurrentCamera = previewCamera

    local v5Renderer = nil
    pcall(function()
        v5Renderer = require(ReplicatedStorage:WaitForChild("DelegatedV5Renderer", 2))
    end)
    local weaponModel, weaponClips, isV5Weapon = nil, nil, false
    if v5Renderer then
        local okW, builtW = pcall(v5Renderer.Build, "MythicalWeaponsSet")
        if okW and builtW then
            weaponModel = builtW
            weaponModel.Parent = worldModel
            isV5Weapon = true
            local okC, cRes = pcall(v5Renderer.Clips, "MythicalWeaponsSet")
            if okC and type(cRes) == "table" then
                weaponClips = cRes
            end
        end
    end
    if not weaponModel then
        weaponModel = build3DWeaponModel(worldModel, outItem, rInfo.Color)
    end
    local _, wSize = weaponModel:GetBoundingBox()
    local camDist = isV5Weapon and math.max(wSize.X, wSize.Y, wSize.Z, 3.0) * 1.35 or 5.8
    local yaw = math.rad(28)
    local dragging = false
    local lastX = 0

    local function updateWeaponCam()
        if weaponModel and weaponModel.Parent then
            if isV5Weapon then
                weaponModel:PivotTo(CFrame.new(0, -wSize.Y * 0.35, 0) * CFrame.Angles(0, yaw, 0))
                local activeClip = weaponClips and (weaponClips.ElementalSurge or weaponClips.Idle) or nil
                if activeClip and v5Renderer and v5Renderer.Pose then
                    pcall(v5Renderer.Pose, weaponModel, activeClip, os.clock())
                end
            else
                weaponModel:PivotTo(CFrame.Angles(math.rad(18), yaw, math.rad(-28)))
            end
        end
        previewCamera.CFrame = CFrame.lookAt(Vector3.new(0, 0.25, camDist), Vector3.new(0, 0, 0))
    end
    updateWeaponCam()

    weaponViewport.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            lastX = input.Position.X
        end
    end)

    Forge.EndConn = UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    Forge.DragConn = UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local dx = input.Position.X - lastX
            lastX = input.Position.X
            yaw += math.rad(dx * 0.65)
            updateWeaponCam()
        end
    end)

    Forge.SpinConn = RunService.RenderStepped:Connect(function(dt)
        if not weaponViewport.Parent or UIAnimator.ReducedMotion then
            return
        end
        if not dragging then
            yaw += dt * 0.85
            updateWeaponCam()
        end
    end)

    UIFactory.Label(previewBox, {
        Name = "ItemTitle",
        Text = string.format("%s  %s", outItem.Name, currentUpgrade > 0 and ("+" .. currentUpgrade) or ""),
        Position = UDim2.fromOffset(152, 12),
        Size = UDim2.new(1, -166, 0, 26),
        TextSize = 18,
        TextColor = rInfo.Color,
        Bold = true,
    })

    UIFactory.Label(previewBox, {
        Name = "StatsPreview",
        Text = string.format(
            "ATK +%d   •   CRIT +%d%%   •   OWNED: x%d\n3D Preview: Drag weapon to inspect  •  Success Rate: %d%%",
            (outItem.Stats and outItem.Stats.ATK or 0) + (currentUpgrade * 6),
            outItem.Stats and outItem.Stats.CRIT or 0,
            ownedCount,
            math.floor((selectedRecipe.SuccessRate or 1) * 100)
        ),
        Position = UDim2.fromOffset(152, 42),
        Size = UDim2.new(1, -166, 0, 44),
        TextSize = 12,
        TextColor = colors.TEXT_SECONDARY,
    })

    -- Core Shard Socket Badge
    UIFactory.Label(previewBox, {
        Name = "SocketInfo",
        Text = "◈ CELESTIAL SOCKET: Compatible with Core of Light & Void Essence Shards",
        Position = UDim2.fromOffset(152, 92),
        Size = UDim2.new(1, -166, 0, 22),
        TextSize = 11,
        TextColor = colors.ACCENT_ICE,
        Bold = true,
    })

    -- Material Requirements Header
    UIFactory.Label(anvilCard, {
        Name = "MatHeader",
        Text = "REQUIRED MATERIALS & CURRENCY",
        Position = UDim2.fromOffset(18, 200),
        Size = UDim2.new(1, -36, 0, 20),
        TextSize = 12,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
    })

    local matList = UIFactory.Create("Frame", anvilCard, {
        Name = "MaterialList",
        Position = UDim2.fromOffset(18, 224),
        Size = UDim2.new(1, -36, 0, 148),
        BackgroundTransparency = 1,
    })
    UIFactory.ListLayout(matList, Enum.FillDirection.Vertical, 6)

    local allSatisfied = (snap.currency.gold >= (selectedRecipe.GoldCost or 0))
    for idx, mat in ipairs(selectedRecipe.Materials or {}) do
        local matId = mat.ItemId or mat.itemId
        local reqCount = mat.Count or mat.count or 1
        local mCfg = RarityConfig.GetItem(matId) or { Name = tostring(matId) }
        local have = getOwnedCount(snap.inventory, matId)
        local ok = have >= reqCount
        if not ok then
            allSatisfied = false
        end

        local mRow = UIFactory.Create("Frame", matList, {
            Name = "Mat_" .. tostring(matId),
            Size = UDim2.new(1, 0, 0, 36),
            BackgroundColor3 = colors.BG_900,
            BorderSizePixel = 0,
            LayoutOrder = idx,
        })
        UIFactory.Corner(mRow, Theme.Radius.Small)
        UIFactory.Stroke(mRow, ok and colors.SUCCESS or colors.DANGER, 1, 0.35)

        UIFactory.Label(mRow, {
            Name = "Name",
            Text = mCfg.Name,
            Position = UDim2.fromOffset(12, 0),
            Size = UDim2.new(0.65, -12, 1, 0),
            TextSize = 13,
            TextColor = colors.TEXT_PRIMARY,
            Bold = true,
        })

        UIFactory.Label(mRow, {
            Name = "Count",
            Text = string.format("%d / %d", have, reqCount),
            Position = UDim2.new(0.65, 0, 0, 0),
            Size = UDim2.new(0.35, -12, 1, 0),
            TextSize = 13,
            TextColor = ok and colors.SUCCESS or colors.DANGER,
            Bold = true,
            XAlign = Enum.TextXAlignment.Right,
        })
    end

    -- Gold Check Row
    local goldOk = snap.currency.gold >= (selectedRecipe.GoldCost or 0)
    local gRow = UIFactory.Create("Frame", matList, {
        Name = "GoldRow",
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
        LayoutOrder = 99,
    })
    UIFactory.Corner(gRow, Theme.Radius.Small)
    UIFactory.Stroke(gRow, goldOk and colors.ACCENT_GOLD or colors.DANGER, 1, 0.35)

    UIFactory.Label(gRow, {
        Name = "GoldName",
        Text = "Gold Required",
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(0.6, -12, 1, 0),
        TextSize = 13,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
    })

    UIFactory.Label(gRow, {
        Name = "GoldCount",
        Text = string.format("%s / %s", UIFactory.FormatNumber(snap.currency.gold), UIFactory.FormatNumber(selectedRecipe.GoldCost)),
        Position = UDim2.new(0.6, 0, 0, 0),
        Size = UDim2.new(0.4, -12, 1, 0),
        TextSize = 13,
        TextColor = goldOk and colors.SUCCESS or colors.DANGER,
        Bold = true,
        XAlign = Enum.TextXAlignment.Right,
    })

    -- Craft / Upgrade Action Button with Pending Lock & Craft Pulse Animation
    local _, craftBtnApi = PremiumButton.Create(anvilCard, {
        name = "CraftButton",
        label = allSatisfied
            and (selectedRecipe.Type == "Craft" and "⚒  FORGE CELESTIAL WEAPON" or "⬆  UPGRADE WEAPON (+1)")
            or "INSUFFICIENT MATERIALS / GOLD",
        variant = allSatisfied and "gold" or "secondary",
        disabled = not allSatisfied or Forge.PendingLock,
        position = UDim2.new(0, 18, 1, -56),
        size = UDim2.new(1, -36, 0, 44),
        textSize = 14,
        onActivated = function()
            if Forge.PendingLock then
                return
            end
            Forge.PendingLock = true
            craftBtnApi:Update({
                label = "⏳ FORGING CELESTIAL ALLOY...",
                disabled = true,
            })

            -- Section 11: Craft pulse animation on ForgePreview
            if previewScale and previewScale.Parent then
                previewScale.Scale = 1.06
                UIAnimator.Tween(previewScale, { Scale = 1.0 }, MotionTokens.questComplete.duration, MotionTokens.questComplete.style, MotionTokens.questComplete.direction)
            end

            task.delay(0.28, function()
                Forge.PendingLock = false
                local remotes = ReplicatedStorage:FindFirstChild("Remotes")
                if remotes and not snap.isDemoMode then
                    if selectedRecipe.ServerRemote == "ForgeRequest" and remotes:FindFirstChild("ForgeRequest") then
                        remotes.ForgeRequest:FireServer()
                        Store.ShowToast("Forging Dawnbringer at the Celestial Anvil...", "info")
                        return
                    elseif selectedRecipe.ServerRemote == "EquipmentRequest" and remotes:FindFirstChild("EquipmentRequest") then
                        remotes.EquipmentRequest:FireServer({
                            action = "Upgrade",
                            itemId = selectedRecipe.OutputItemId,
                        })
                        Store.ShowToast("Upgrading " .. outItem.Name .. "...", "info")
                        return
                    end
                end
                Store.ApplyDemoPreviewAction("ForgeRecipe", { recipeId = selectedRecipe.Id })
            end)
        end,
    })

    Forge.Refs = {
        Root = root,
        WeaponViewport = weaponViewport,
        CraftBtnApi = craftBtnApi,
    }
    return root
end

function Forge.Update()
    if Forge.Refs.Root and Forge.Refs.Root.Parent then
        local parent = Forge.Refs.Root.Parent
        Forge.Build(parent)
    end
end

function Forge.Cleanup()
    if Forge.SpinConn then
        Forge.SpinConn:Disconnect()
        Forge.SpinConn = nil
    end
    if Forge.DragConn then
        Forge.DragConn:Disconnect()
        Forge.DragConn = nil
    end
    if Forge.EndConn then
        Forge.EndConn:Disconnect()
        Forge.EndConn = nil
    end
    Forge.PendingLock = false
    Forge.Refs = {}
end

return Forge
