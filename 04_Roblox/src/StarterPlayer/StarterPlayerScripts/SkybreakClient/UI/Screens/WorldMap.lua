-- SKYBREAK: Fragments of the Core — Interactive 8-Realm Celestial World Map (Phase 5)
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/WorldMap.lua
-- Canonical 8 Realms (Lv 1..100) + Central Sky Hub, interactive GUI markers, Boss & Objective Inspector, Fast Travel.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local WorldConfig = require(Shared:WaitForChild("Config"):WaitForChild("WorldConfig"))
local UIAssets = require(Shared:WaitForChild("Config"):WaitForChild("UIAssets"))
local UIState = require(Shared:WaitForChild("Types"):WaitForChild("UIState"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Store = require(script.Parent.Parent:WaitForChild("Store"))
local ScreenRouter = require(script.Parent.Parent:WaitForChild("ScreenRouter"))
local PremiumPanel = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumPanel"))
local PremiumButton = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumButton"))
local PartyController = require(script.Parent.Parent:WaitForChild("Controllers"):WaitForChild("PartyController"))

local WorldMap = {
    Refs = {},
}

function WorldMap.Build(parent)
    WorldMap.Cleanup()
    local colors = Theme.Colors
    local snap = Store.GetSnapshot()
    local view = Store.GetView()
    local selectedRealmId = view.selectedRealmId or snap.world.current or "GoldenSky"
    local selectedRealm = WorldConfig.RealmById[selectedRealmId] or WorldConfig.Realms[1]

    local root = UIFactory.Create("Frame", parent, {
        Name = "WorldMapScreen",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 2,
    })

    -- Top Header
    local header = PremiumPanel.Create(root, {
        name = "TopHeader",
        position = UDim2.fromOffset(20, 14),
        size = UDim2.new(1, -40, 0, 58),
    })
    UIFactory.Label(header, {
        Name = "Brand",
        Text = "SKY<font color='#F0F4FA'>BREAK</font>  •  CELESTIAL WORLD MAP (8 REALMS • LV. 1–100)",
        Position = UDim2.fromOffset(18, 0),
        Size = UDim2.fromOffset(620, 58),
        TextSize = 19,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
        RichText = true,
    })
    PremiumButton.Create(header, {
        name = "CloseButton",
        label = "BACK TO HUD [M]",
        variant = "secondary",
        position = UDim2.new(1, -172, 0, 10),
        size = UDim2.fromOffset(156, 38),
        textSize = 12,
        onActivated = function()
            ScreenRouter.Navigate(UIState.Screens.HUD)
        end,
    })

    -- Left Interactive Astrolabe Map Canvas (64% width)
    local mapPanel = PremiumPanel.Create(root, {
        name = "WorldMap",
        title = "THE SHATTERED FIRMAMENT",
        subtitle = "Central Sky Hub surrounded by the 8 Floating Realms",
        position = UDim2.fromOffset(20, 84),
        size = UDim2.new(0.64, -16, 1, -102),
    })

    local mapCanvas = UIFactory.Create("Frame", mapPanel, {
        Name = "AstrolabeCanvas",
        Position = UDim2.fromOffset(14, 64),
        Size = UDim2.new(1, -28, 1, -78),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    })
    UIFactory.Corner(mapCanvas, Theme.Radius.Medium)
    UIFactory.Stroke(mapCanvas, colors.STROKE_STEEL, 1, 0.38)
    UIFactory.Gradient(mapCanvas, Color3.fromRGB(14, 28, 52), colors.BG_900, 45)

    -- Optional clean map illustration background if uploaded in UIAssets
    if UIAssets.IsValidAssetId(UIAssets.WorldMapBackground) then
        UIFactory.Create("ImageLabel", mapCanvas, {
            Name = "RealmIllustration",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Image = UIAssets.WorldMapBackground,
            ImageTransparency = 0.28,
            ScaleType = Enum.ScaleType.Crop,
            ZIndex = 2,
        })
    end

    -- Procedural Constellation Orbit Rings
    for idx, ringScale in ipairs({ 0.42, 0.74 }) do
        local ring = UIFactory.Create("Frame", mapCanvas, {
            Name = "OrbitRing_" .. idx,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromScale(ringScale, ringScale * 0.88),
            BackgroundTransparency = 1,
            ZIndex = 2,
        })
        UIFactory.PillCorner(ring)
        UIFactory.Stroke(ring, idx == 1 and colors.ACCENT_GOLD or colors.STROKE_STEEL, 1, 0.65)
    end

    -- Central Sky Hub Interactive Node
    local hub = WorldConfig.Hub
    local hubSelected = (selectedRealmId == "SkyHub")
    local hubBtn = UIFactory.Create("TextButton", mapCanvas, {
        Name = "Node_SkyHub",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(hub.MapPosition.X, hub.MapPosition.Y),
        Size = UDim2.fromOffset(152, 62),
        BackgroundColor3 = hubSelected and colors.ACCENT_DEEP_BLUE or colors.BG_700,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 5,
    })
    UIFactory.Corner(hubBtn, Theme.Radius.Medium)
    UIFactory.Stroke(hubBtn, colors.ACCENT_GOLD, hubSelected and 2.4 or 1.6, 0.08)
    UIFactory.Label(hubBtn, {
        Name = "Title",
        Text = "✦ SKY HUB ✦\nSANCTUARY",
        Size = UDim2.fromScale(1, 1),
        TextSize = 13,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        ZIndex = 6,
    })
    hubBtn.Activated:Connect(function()
        Store.SetView({ selectedRealmId = "SkyHub" })
        ScreenRouter.Navigate(UIState.Screens.WorldMap, { forceRebuild = true, replace = true })
    end)

    -- 8 Canonical Realm Interactive Nodes
    for _, realm in ipairs(WorldConfig.Realms) do
        local isUnlocked = (realm.Id == "GoldenSky")
            or (realm.FastTravelUnlockedByDefault == true)
            or (snap.world and snap.world.unlocked and snap.world.unlocked[realm.Id] == true)
        local isCurrent = (snap.world and snap.world.current == realm.Id)
        local isSelected = (selectedRealmId == realm.Id)

        local nodeBtn = UIFactory.Create("TextButton", mapCanvas, {
            Name = "Realm_" .. realm.Id,
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(realm.MapPosition.X, realm.MapPosition.Y),
            Size = UDim2.fromOffset(162, 66),
            BackgroundColor3 = isSelected and colors.BG_700 or colors.BG_800,
            BackgroundTransparency = isUnlocked and 0.04 or 0.25,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
            ZIndex = 5,
        })
        UIFactory.Corner(nodeBtn, Theme.Radius.Medium)
        UIFactory.Stroke(
            nodeBtn,
            isSelected and colors.ACCENT_GOLD or (isUnlocked and realm.AccentColor or colors.STROKE_STEEL),
            isSelected and 2.4 or 1.4,
            isUnlocked and 0.12 or 0.52
        )

        UIFactory.Label(nodeBtn, {
            Name = "Name",
            Text = (isUnlocked and "" or "🔒 ") .. string.upper(realm.Name),
            Position = UDim2.fromOffset(8, 6),
            Size = UDim2.new(1, -16, 0, 20),
            TextSize = 12,
            TextColor = isUnlocked and realm.AccentColor or colors.TEXT_SECONDARY,
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            Wrapped = false,
            ZIndex = 6,
        })

        UIFactory.Label(nodeBtn, {
            Name = "LevelAndBoss",
            Text = realm.LevelRange .. " • " .. realm.BossName,
            Position = UDim2.fromOffset(6, 26),
            Size = UDim2.new(1, -12, 0, 18),
            TextSize = 11,
            TextColor = colors.TEXT_PRIMARY,
            XAlign = Enum.TextXAlignment.Center,
            Truncate = Enum.TextTruncate.AtEnd,
            Wrapped = false,
            ZIndex = 6,
        })

        UIFactory.Label(nodeBtn, {
            Name = "Status",
            Text = isCurrent and "● CURRENT REALM" or (isUnlocked and "UNLOCKED" or "LOCKED"),
            Position = UDim2.fromOffset(6, 44),
            Size = UDim2.new(1, -12, 0, 16),
            TextSize = 10,
            TextColor = isCurrent and colors.SUCCESS or (isUnlocked and colors.ACCENT_SAPPHIRE or colors.TEXT_SECONDARY),
            Bold = true,
            XAlign = Enum.TextXAlignment.Center,
            Wrapped = false,
            ZIndex = 6,
        })

        nodeBtn.Activated:Connect(function()
            Store.SetView({ selectedRealmId = realm.Id })
            ScreenRouter.Navigate(UIState.Screens.WorldMap, { forceRebuild = true, replace = true })
        end)
    end

    -- Right Inspector Column (36% width): Selected Realm Details, Boss Info, Objectives & Fast Travel
    local detailPanel = PremiumPanel.Create(root, {
        name = "WorldDetail",
        variant = "gold",
        title = string.upper(selectedRealm.Name),
        subtitle = (selectedRealm.LevelRange or "All Levels") .. (selectedRealm.Chapter and ("  •  " .. selectedRealm.Chapter) or ""),
        position = UDim2.new(0.64, 16, 0, 84),
        size = UDim2.new(0.36, -36, 1, -102),
    })

    local isSelectedUnlocked = (selectedRealm.Id == "SkyHub" or selectedRealm.Id == "GoldenSky")
        or (selectedRealm.FastTravelUnlockedByDefault == true)
        or (snap.world and snap.world.unlocked and snap.world.unlocked[selectedRealm.Id] == true)

    local bossText = selectedRealm.BossName
        and string.format("<font color='#E4B863'><b>REALM GUARDIAN BOSS</b></font>\n%s — <i>%s</i>\n\n", selectedRealm.BossName, selectedRealm.BossTitle or "")
        or "<font color='#E4B863'><b>SAFE SANCTUARY</b></font>\nNPCs: Lyra, Kael, Astrael\n\n"

    local objLines = {}
    for _, obj in ipairs(selectedRealm.Objectives or {}) do
        table.insert(objLines, "• " .. obj)
    end
    local objSection = #objLines > 0
        and ("<font color='#40AAFF'><b>REALM OBJECTIVES</b></font>\n" .. table.concat(objLines, "\n"))
        or ""

    local realmIslands = (WorldConfig.IslandsByRealm and WorldConfig.IslandsByRealm[selectedRealm.Id == "SkyHub" and "GoldenSky" or selectedRealm.Id]) or {}
    local infoHeightOffset = #realmIslands > 0 and -336 or -196

    UIFactory.Label(detailPanel, {
        Name = "WorldInfo",
        Text = (selectedRealm.Description or "") .. "\n\n" .. bossText .. objSection
            .. (not isSelectedUnlocked and ("\n\n<font color='#EF5262'><b>UNLOCK REQUIREMENT:</b>\n" .. (selectedRealm.UnlockConditionText or "Complete prior realm") .. "</font>") or ""),
        Position = UDim2.fromOffset(18, 70),
        Size = UDim2.new(1, -36, 1, infoHeightOffset),
        TextSize = 13,
        TextColor = colors.TEXT_PRIMARY,
        YAlign = Enum.TextYAlignment.Top,
        RichText = true,
    })

    if #realmIslands > 0 then
        UIFactory.Label(detailPanel, {
            Name = "IslandsHeader",
            Text = "✦ SUB-ISLANDS & 3D LANDMARKS (CLICK TO TELEPORT):",
            Position = UDim2.new(0, 18, 1, -258),
            Size = UDim2.new(1, -36, 0, 18),
            TextSize = 11,
            TextColor = colors.ACCENT_GOLD,
            Bold = true,
        })

        local islandScroll = UIFactory.Create("ScrollingFrame", detailPanel, {
            Name = "IslandsScroll",
            Position = UDim2.new(0, 18, 1, -236),
            Size = UDim2.new(1, -36, 0, 116),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 4,
            ScrollBarImageColor3 = colors.ACCENT_SAPPHIRE,
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            CanvasSize = UDim2.fromOffset(0, 0),
        })
        UIFactory.ListLayout(islandScroll, Enum.FillDirection.Vertical, 5)

        for idx, isl in ipairs(realmIslands) do
            local row = UIFactory.Create("TextButton", islandScroll, {
                Name = "IslandTeleport_" .. isl.Id,
                LayoutOrder = idx,
                Size = UDim2.new(1, -6, 0, 30),
                BackgroundColor3 = colors.BG_700,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
            })
            UIFactory.Corner(row, Theme.Radius.Small)
            UIFactory.Stroke(row, colors.ACCENT_SAPPHIRE, 1, 0.35)
            UIFactory.Label(row, {
                Name = "IslandName",
                Text = "⚡ " .. isl.Name .. "  <font color='#A8B9D1'>(" .. (isl.LevelRange or "") .. ")</font>",
                Position = UDim2.fromOffset(10, 0),
                Size = UDim2.new(1, -92, 1, 0),
                TextSize = 11,
                TextColor = colors.TEXT_PRIMARY,
                Bold = true,
                RichText = true,
                Wrapped = false,
                Truncate = Enum.TextTruncate.AtEnd,
            })
            UIFactory.Label(row, {
                Name = "GoTag",
                Text = "WARP →",
                Position = UDim2.new(1, -78, 0, 0),
                Size = UDim2.fromOffset(68, 30),
                TextSize = 11,
                TextColor = colors.ACCENT_GOLD,
                Bold = true,
                XAlign = Enum.TextXAlignment.Right,
            })
            row.Activated:Connect(function()
                PartyController.RequestFastTravel(isl.Id)
            end)
        end
    end

    if selectedRealm.BossId and WorldConfig.Raids[selectedRealm.BossId] then
        PremiumButton.Create(detailPanel, {
            name = "InspectBossRaid",
            label = "❖  INSPECT BOSS MECHANICS",
            variant = "secondary",
            position = UDim2.new(0, 18, 1, -112),
            size = UDim2.new(1, -36, 0, 40),
            textSize = 12,
            onActivated = function()
                Store.SetView({ selectedRaidId = selectedRealm.BossId })
                ScreenRouter.Navigate(UIState.Screens.Raid)
            end,
        })
    end

    PremiumButton.Create(detailPanel, {
        name = "FastTravelButton",
        label = isSelectedUnlocked and ("FAST TRAVEL TO " .. string.upper(selectedRealm.Name)) or "REALM LOCKED",
        variant = isSelectedUnlocked and "primary" or "secondary",
        disabled = not isSelectedUnlocked,
        position = UDim2.new(0, 18, 1, -62),
        size = UDim2.new(1, -36, 0, 46),
        textSize = 13,
        onActivated = function()
            PartyController.RequestFastTravel(selectedRealm.Id)
        end,
    })

    WorldMap.Refs = { Root = root }
    return root
end

function WorldMap.Update() end

function WorldMap.Cleanup()
    WorldMap.Refs = {}
end

return WorldMap
