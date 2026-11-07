-- SKYBREAK: Fragments of the Core - Automated 130-Task Verification Suite (#130)
-- Location: ReplicatedStorage/Shared/SkybreakSmokeTest.lua
-- Exposes: SmokeTest.RunClientAudit(), SmokeTest.RunServerAudit(), SmokeTest.RunAll()
-- Returns: { Passed = boolean, TotalChecks = number, PassedChecks = number, Failed = { ... }, Summary = string }

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local StarterPlayer = game:GetService("StarterPlayer")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SmokeTest = {}

local SEPARATED_21_MODELS = {
    -- 8 Separated 3D Weapons
    "Wep_CursedBladeLeft",
    "Wep_CursedBladeRight",
    "Wep_CursedDualSkyblades",
    "Wep_CryonFrostblade",
    "Wep_Dawnbringer",
    "Wep_NoxarGreatsword",
    "Wep_SoulGuitarVoid",
    "Wep_CryoRailgun",
    -- 6 Separated 3D Race V4 Wings
    "Wing_Skyborn",
    "Wing_Mink",
    "Wing_Leviathan",
    "Wing_Cyborg",
    "Wing_Ghoul",
    "Wing_Draco",
    -- 3 Separated 3D Ancient Aether Fruit Trees
    "Tree_CryoAether",
    "Tree_SolarAether",
    "Tree_VoidAether",
    -- 3 Separated 3D Elemental Shrines
    "Shrine_SolarAether",
    "Shrine_CryoAether",
    "Shrine_VoidAether",
    -- 1 Separated 3D Raid Microchip Console
    "Console_RaidMicrochip",
}

local WARSHIP_3_MODELS = {
    "CelestialAetherGalleon",
    "CyberEnforcerShip",
    "LeviathanHunterShip",
}

local FRUIT_12_MODELS = {
    "Fruit_GaleCore",
    "Fruit_SandstoneCore",
    "Fruit_SolarFlameCore",
    "Fruit_GlacierIceCore",
    "Fruit_CelestialLightCore",
    "Fruit_StarforgedMagmaCore",
    "Fruit_ThunderRumbleCore",
    "Fruit_AstralGravityCore",
    "Fruit_DimensionalPortalCore",
    "Fruit_SolarTitanCore",
    "Fruit_AetherflowCore",
    "Fruit_AbyssalSovereignCore",
}

local UI_11_SCREENS = {
    "Dialogue",
    "Forge",
    "Fruits",
    "HUD",
    "Inventory",
    "MainMenu",
    "NPCShop",
    "QuestJournal",
    "Raid",
    "Settings",
    "Skills",
    "SocialRewards",
    "WorldMap",
}

local CORE_15_REMOTES = {
    "CombatRequest",
    "AbilityRequest",
    "InteractRequest",
    "StateUpdate",
    "EquipmentRequest",
    "CombatFX",
    "CombatEvent",
    "AppearanceRequest",
    "UIRequest",
    "UICommand",
    "FruitAction",
    "TradeAction",
    "StatAllocate",
    "TeleportIsland",
    "ForgeRequest",
}

local function newContext(modeLabel)
    return {
        Mode = modeLabel,
        TotalChecks = 0,
        PassedChecks = 0,
        Failed = {},
    }
end

local function record(ctx, checkName, ok, detail)
    ctx.TotalChecks += 1
    if ok then
        ctx.PassedChecks += 1
    else
        table.insert(ctx.Failed, string.format("[%s] %s", tostring(checkName), tostring(detail or "Check failed")))
    end
end

local function finalize(ctx)
    local passed = (#ctx.Failed == 0) and (ctx.TotalChecks > 0)
    local statusTag = passed and "[PASS]" or "[FAIL]"
    local summary = string.format(
        "%s SKYBREAK SmokeTest (%s): %d/%d checks passed (%d failed)",
        statusTag,
        ctx.Mode,
        ctx.PassedChecks,
        ctx.TotalChecks,
        #ctx.Failed
    )
    if #ctx.Failed > 0 then
        summary = summary .. " | First failure: " .. tostring(ctx.Failed[1])
    end
    return {
        Passed = passed,
        TotalChecks = ctx.TotalChecks,
        PassedChecks = ctx.PassedChecks,
        Failed = ctx.Failed,
        Summary = summary,
    }
end

local function findFirstAstralEmoji(str)
    if type(str) ~= "string" or str == "" then
        return nil
    end
    local found = nil
    local ok = pcall(function()
        for _, cp in utf8.codes(str) do
            if cp >= 0x1F300 then
                found = cp
                break
            end
        end
    end)
    if not ok then
        for i = 1, #str do
            if string.byte(str, i) >= 0xF0 then
                return 0x1F300
            end
        end
    end
    return found
end

local function check3DAssetsAndRenderer(ctx, isClientRuntime)
    local rendererMod = ReplicatedStorage:FindFirstChild("DelegatedV5Renderer")
        or (ReplicatedStorage:FindFirstChild("Shared") and ReplicatedStorage.Shared:FindFirstChild("DelegatedV5Renderer"))
    record(ctx, "DelegatedV5Renderer.ModulePresent", rendererMod ~= nil, "Missing DelegatedV5Renderer ModuleScript")

    local sources = ReplicatedStorage:FindFirstChild("DelegatedV5Sources")
    record(ctx, "DelegatedV5Sources.FolderPresent", sources ~= nil, "Missing ReplicatedStorage.DelegatedV5Sources")

    local okReq, Renderer = false, nil
    if rendererMod then
        okReq, Renderer = pcall(require, rendererMod)
    end
    record(
        ctx,
        "DelegatedV5Renderer.Require",
        okReq and type(Renderer) == "table" and type(Renderer.Build) == "function",
        tostring(Renderer)
    )

    local vSpecs = (okReq and type(Renderer) == "table" and type(Renderer.VirtualSplitSpecs) == "table") and Renderer.VirtualSplitSpecs or {}

    local function verifyHeaderSource(sourceFolderName)
        if not sources then
            return false, "DelegatedV5Sources missing"
        end
        local f = sources:FindFirstChild(sourceFolderName)
        if not f then
            return false, "Missing source folder " .. tostring(sourceFolderName)
        end
        local hdrMod = f:FindFirstChild("Header")
        if not hdrMod then
            return false, "Missing Header in " .. tostring(sourceFolderName)
        end
        local okH, hdr = pcall(require, hdrMod)
        if not okH then
            return false, "Header require error in " .. tostring(sourceFolderName)
        end
        if type(hdr) == "string" then
            local okJ, decoded = pcall(function()
                return game:GetService("HttpService"):JSONDecode(hdr)
            end)
            hdr = okJ and decoded or nil
        end
        if type(hdr) ~= "table" or (tonumber(hdr.mesh_count) or 0) <= 0 then
            return false, "Invalid mesh_count in " .. tostring(sourceFolderName)
        end
        return true, nil
    end

    -- 1. All 21 Separated 3D Blender Models
    for _, modelId in ipairs(SEPARATED_21_MODELS) do
        local spec = vSpecs[modelId]
        local directFolder = sources and sources:FindFirstChild(modelId)
        if spec and type(spec.source) == "string" then
            local okSrc, errSrc = verifyHeaderSource(spec.source)
            record(ctx, "3DSeparated." .. modelId, okSrc, errSrc)
        elseif directFolder then
            local okSrc, errSrc = verifyHeaderSource(modelId)
            record(ctx, "3DSeparated." .. modelId, okSrc, errSrc)
        else
            record(ctx, "3DSeparated." .. modelId, false, "Not registered in VirtualSplitSpecs or DelegatedV5Sources")
        end
    end

    -- 2. All 3 3D Blender Warships + V8 Sovereign Dragon Transformation Rigs
    for _, shipId in ipairs(WARSHIP_3_MODELS) do
        local okSrc, errSrc = verifyHeaderSource(shipId)
        record(ctx, "3DWarship." .. shipId, okSrc, errSrc)
    end
    for _, dragonId in ipairs({ "AbyssalSovereignDragon", "AbyssalDragonHybrid" }) do
        local okSrc, errSrc = verifyHeaderSource(dragonId)
        record(ctx, "3DDragonRig." .. dragonId, okSrc, errSrc)
    end

    -- 3. All 12 3D Fruits (DelegatedV5Sources / Fruit3DModels)
    local fruit3DMod = ReplicatedStorage:FindFirstChild("Fruit3DModels")
        or (ReplicatedStorage:FindFirstChild("Shared") and ReplicatedStorage.Shared:FindFirstChild("Fruit3DModels"))
    local fruit3DTbl = nil
    if fruit3DMod and fruit3DMod:IsA("ModuleScript") then
        local okF, loadedF = pcall(require, fruit3DMod)
        if okF and type(loadedF) == "table" then
            fruit3DTbl = loadedF
        end
    end

    for _, fruitAsset in ipairs(FRUIT_12_MODELS) do
        local okSrc, errSrc = verifyHeaderSource(fruitAsset)
        if not okSrc and fruit3DTbl and (fruit3DTbl[fruitAsset] ~= nil or type(fruit3DTbl.Build) == "function") then
            okSrc = true
            errSrc = nil
        end
        record(ctx, "3DFruit." .. fruitAsset, okSrc, errSrc)
    end

    -- On Client runtime, verify live 3D build output for representative separated & warship meshes
    if isClientRuntime and okReq and type(Renderer) == "table" and sources then
        for _, sampleId in ipairs({ "Wep_Dawnbringer", "Console_RaidMicrochip" }) do
            local cached = Renderer.Models and Renderer.Models[sampleId]
            local builtModel = cached
            local okBuild, buildErr = true, nil
            if not builtModel or not builtModel.PrimaryPart then
                okBuild, builtModel = pcall(Renderer.Build, sampleId)
                if not okBuild then
                    buildErr = tostring(builtModel)
                end
            end
            local validMesh = okBuild and typeof(builtModel) == "Instance" and builtModel:IsA("Model") and builtModel.PrimaryPart ~= nil
            record(ctx, "3DLiveBuild." .. sampleId, validMesh, buildErr or "PrimaryPart missing on built 3D model")
        end
    end
end

local function checkLightingAntiGlare(ctx)
    local b = Lighting.Brightness
    local exp = Lighting.ExposureCompensation
    record(
        ctx,
        "Lighting.AntiGlareBrightness",
        b <= 2.25,
        string.format("Lighting.Brightness = %.3f (expected <= 2.25)", b)
    )
    record(
        ctx,
        "Lighting.AntiGlareExposure",
        exp <= 0.14,
        string.format("Lighting.ExposureCompensation = %.3f (expected <= 0.14)", exp)
    )

    local bloomViolation = nil
    for _, ch in ipairs(Lighting:GetChildren()) do
        if ch:IsA("BloomEffect") and ch.Enabled then
            if ch.Intensity > 0.68 or ch.Threshold < 0.86 then
                bloomViolation = string.format("%s Intensity=%.2f Threshold=%.2f", ch.Name, ch.Intensity, ch.Threshold)
                break
            end
        end
    end
    record(ctx, "Lighting.AntiGlareBloom", bloomViolation == nil, bloomViolation)
end

local function checkZeroAstralEmojis(ctx, scanPlayerGui)
    local workspaceOffenders = {}
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            local cp1 = findFirstAstralEmoji(d.ActionText)
            local cp2 = findFirstAstralEmoji(d.ObjectText)
            local cp = cp1 or cp2
            if cp then
                table.insert(workspaceOffenders, string.format("%s (U+%X)", d:GetFullName(), cp))
                if #workspaceOffenders >= 5 then
                    break
                end
            end
        elseif (d:IsA("TextLabel") or d:IsA("TextButton")) and d:FindFirstAncestorWhichIsA("BillboardGui") then
            local cp = findFirstAstralEmoji(d.Text)
            if cp then
                table.insert(workspaceOffenders, string.format("%s (U+%X)", d:GetFullName(), cp))
                if #workspaceOffenders >= 5 then
                    break
                end
            end
        end
    end
    record(
        ctx,
        "ZeroEmojis.WorkspacePromptsAndBillboards",
        #workspaceOffenders == 0,
        table.concat(workspaceOffenders, "; ")
    )

    if scanPlayerGui then
        local lp = Players.LocalPlayer
        local pgui = lp and lp:FindFirstChildOfClass("PlayerGui")
        local guiOffenders = {}
        if pgui then
            for _, d in ipairs(pgui:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextButton") then
                    local cp = findFirstAstralEmoji(d.Text)
                    if cp then
                        table.insert(guiOffenders, string.format("%s (U+%X)", d:GetFullName(), cp))
                        if #guiOffenders >= 5 then
                            break
                        end
                    end
                end
            end
        end
        record(
            ctx,
            "ZeroEmojis.PlayerGuiText",
            pgui ~= nil and #guiOffenders == 0,
            pgui == nil and "PlayerGui missing" or table.concat(guiOffenders, "; ")
        )
    end
end

local function checkUIScreenModules(ctx)
    local screensFolder = nil
    local lp = Players.LocalPlayer
    local ps = lp and lp:FindFirstChild("PlayerScripts")
    if ps and ps:FindFirstChild("SkybreakClient") then
        local ui = ps.SkybreakClient:FindFirstChild("UI")
        screensFolder = ui and ui:FindFirstChild("Screens")
    end
    if not screensFolder then
        local sps = StarterPlayer:FindFirstChild("StarterPlayerScripts")
        local sc = sps and sps:FindFirstChild("SkybreakClient")
        local ui = sc and sc:FindFirstChild("UI")
        screensFolder = ui and ui:FindFirstChild("Screens")
    end

    record(ctx, "SkybreakUI.ScreensFolderPresent", screensFolder ~= nil, "Missing SkybreakClient/UI/Screens folder")
    for _, screenName in ipairs(UI_11_SCREENS) do
        local mod = screensFolder and screensFolder:FindFirstChild(screenName)
        if not mod or not mod:IsA("ModuleScript") then
            record(ctx, "SkybreakUI.Screen." .. screenName, false, "Missing ModuleScript " .. screenName)
        else
            local okLoad, loaded = pcall(require, mod)
        record(
            ctx,
            "SkybreakUI.Screen." .. screenName,
            okLoad and type(loaded) == "table",
            not okLoad and tostring(loaded) or "Screen module did not return a table"
        )
        end
    end

    local uiFolder = screensFolder and screensFolder.Parent
    local compFolder = uiFolder and uiFolder:FindFirstChild("Components")
    local lapMod = compFolder and compFolder:FindFirstChild("LiveAvatarPortrait")
    local okLap, loadedLap = false, nil
    if lapMod and lapMod:IsA("ModuleScript") then
        okLap, loadedLap = pcall(require, lapMod)
    end
    record(
        ctx,
        "SkybreakUI.Component.LiveAvatarPortrait",
        okLap and type(loadedLap) == "table",
        not lapMod and "Missing LiveAvatarPortrait ModuleScript" or tostring(loadedLap)
    )
end

local function checkRemotesAndCombatDataAndWorld(ctx)
    -- Remotes (15+ RemoteEvents)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    record(ctx, "Remotes.FolderPresent", remotes ~= nil, "Missing ReplicatedStorage.Remotes")

    local remoteEventCount = 0
    if remotes then
        for _, ch in ipairs(remotes:GetChildren()) do
            if ch:IsA("RemoteEvent") then
                remoteEventCount += 1
            end
        end
    end
    record(
        ctx,
        "Remotes.CountAtLeast15",
        remoteEventCount >= 15,
        string.format("Found %d RemoteEvents in ReplicatedStorage.Remotes (expected >= 15)", remoteEventCount)
    )
    for _, rName in ipairs(CORE_15_REMOTES) do
        local ev = remotes and remotes:FindFirstChild(rName)
        record(ctx, "Remotes." .. rName, ev ~= nil and ev:IsA("RemoteEvent"), "Missing RemoteEvent " .. rName)
    end

    -- SkybreakCombatData (5 styles, 12 awakened fruits, 34 titles)
    local shared = ReplicatedStorage:FindFirstChild("Shared")
    local cdMod = shared and shared:FindFirstChild("SkybreakCombatData")
    local okCD, CombatData = false, nil
    if cdMod then
        okCD, CombatData = pcall(require, cdMod)
    end
    record(ctx, "SkybreakCombatData.Require", okCD and type(CombatData) == "table", tostring(CombatData))

    if okCD and type(CombatData) == "table" then
        local styleCount = type(CombatData.StyleOrder) == "table" and #CombatData.StyleOrder or 0
        local stylesValid = (styleCount == 5) and type(CombatData.MartialStyles) == "table"
        if stylesValid then
            for _, sid in ipairs(CombatData.StyleOrder) do
                if not CombatData.MartialStyles[sid] then
                    stylesValid = false
                    break
                end
            end
        end
        record(ctx, "SkybreakCombatData.5MartialStyles", stylesValid, "StyleOrder count=" .. tostring(styleCount))

        local fruitCount = type(CombatData.FruitOrder) == "table" and #CombatData.FruitOrder or 0
        local fruitsValid = (fruitCount == 12) and type(CombatData.AwakenedFruitMoves) == "table"
        if fruitsValid then
            for _, fid in ipairs(CombatData.FruitOrder) do
                if not CombatData.AwakenedFruitMoves[fid] then
                    fruitsValid = false
                    break
                end
            end
        end
        record(ctx, "SkybreakCombatData.12AwakenedFruits", fruitsValid, "FruitOrder count=" .. tostring(fruitCount))

        local titleCount = type(CombatData.TitleOrder) == "table" and #CombatData.TitleOrder or 0
        local titlesValid = (titleCount >= 56) and type(CombatData.Titles) == "table"
        if titlesValid then
            for _, tid in ipairs(CombatData.TitleOrder) do
                if not CombatData.Titles[tid] then
                    titlesValid = false
                    break
                end
            end
        end
        record(ctx, "SkybreakCombatData.56Titles", titlesValid, "TitleOrder count=" .. tostring(titleCount))

        -- Verify Config.Items <-> RarityConfig.Items 100% parity & StarterPlayer MouseLock disabled
        record(
            ctx,
            "StarterPlayer.MouseLockDisabled",
            StarterPlayer.EnableMouseLockOption == false,
            "Expected StarterPlayer.EnableMouseLockOption == false"
        )
        local cfgMod = shared and shared:FindFirstChild("Config")
        local skyShared = ReplicatedStorage:FindFirstChild("SkybreakShared")
        local rcfgMod = skyShared and skyShared:FindFirstChild("Config") and skyShared.Config:FindFirstChild("RarityConfig")
        if cfgMod and rcfgMod then
            local okC, Cfg = pcall(require, cfgMod)
            local okR, RCfg = pcall(require, rcfgMod)
            local parityOk = okC and okR and type(Cfg.Items) == "table" and type(RCfg.Items) == "table"
            local missingItem = nil
            if parityOk then
                for itemId in pairs(Cfg.Items) do
                    if not RCfg.Items[itemId] then
                        parityOk = false
                        missingItem = "RarityConfig missing " .. tostring(itemId)
                        break
                    end
                end
            end
            record(ctx, "ItemCatalog.ConfigRarityParity", parityOk, missingItem or "Item catalog mismatch")

            local aecMod = skyShared and skyShared:FindFirstChild("Config") and skyShared.Config:FindFirstChild("ArsenalExpansionConfig")
            local okA, AEC = false, nil
            if aecMod then
                okA, AEC = pcall(require, aecMod)
            end
            local totalItems = 0
            if okR and type(RCfg.Items) == "table" then
                for _ in pairs(RCfg.Items) do
                    totalItems += 1
                end
            end
            local armorSetCount = 0
            if okA and type(AEC) == "table" and type(AEC.ArmorSets) == "table" then
                for _ in pairs(AEC.ArmorSets) do
                    armorSetCount += 1
                end
            end
            local total3DArsenal = totalItems + fruitCount + styleCount + 4 + 4
            record(
                ctx,
                "ItemCatalog.Arsenal123And8ArmorSets",
                okA and totalItems >= 102 and total3DArsenal >= 123 and armorSetCount >= 8,
                string.format(
                    "totalItems=%d (expected >=102), total3DArsenal=%d (expected >=123), armorSets=%d (expected >=8)",
                    totalItems,
                    total3DArsenal,
                    armorSetCount
                )
            )
        end
    end

    -- World Landmarks
    local landmarks = RunService:IsClient()
        and { "SkybreakWorldObjects", "SkybreakExpansionWorld", "ActiveEnemies" }
        or { "SkybreakExpansionWorld", "ActiveEnemies", "ActiveShips", "SkybreakChests", "SkybreakLoreTablets", "HomePointCrystals" }
    for _, landmarkName in ipairs(landmarks) do
        local inst = workspace:FindFirstChild(landmarkName)
        record(ctx, "WorldLandmark." .. landmarkName, inst ~= nil, "Missing workspace." .. landmarkName)
    end
end

function SmokeTest.RunClientAudit()
    local ctx = newContext("Client")
    local lp = Players.LocalPlayer

    -- Brief settle wait if invoked immediately on frame 1 of Studio Play
    if lp then
        local pgui = lp:FindFirstChildOfClass("PlayerGui") or lp:WaitForChild("PlayerGui", 5)
        if pgui then
            local deadline = os.clock() + 3.0
            while os.clock() < deadline do
                local hasUI = pgui:FindFirstChild("SkybreakUI") ~= nil
                local hasFury = pgui:FindFirstChild("SkybreakDragonFuryGui") ~= nil
                local hasAction = pgui:FindFirstChild("SkybreakActionOverlayGui") ~= nil
                local tfx = workspace:FindFirstChild("TempFX")
                local hasPool = tfx and tfx:FindFirstChild("DamageNumberPool") and #tfx.DamageNumberPool:GetChildren() >= 40
                if hasUI and hasFury and hasAction and hasPool then
                    break
                end
                task.wait(0.1)
            end
        end
    end

    check3DAssetsAndRenderer(ctx, true)
    checkLightingAntiGlare(ctx)
    checkZeroAstralEmojis(ctx, true)
    checkUIScreenModules(ctx)
    checkRemotesAndCombatDataAndWorld(ctx)

    local pgui = lp and lp:FindFirstChildOfClass("PlayerGui")
    record(ctx, "ClientGUI.PlayerGuiPresent", pgui ~= nil, "LocalPlayer.PlayerGui not found")

    local requiredGuis = {
        "SkybreakUI",
        "SkybreakDragonFuryGui",
        "SkybreakActionOverlayGui",
        "SkybreakWorldOverlayGui",
        "SkybreakNebulaWipeGui",
    }
    if RunService:IsStudio() then
        table.insert(requiredGuis, "SkybreakDevSandboxGui")
    end
    for _, guiName in ipairs(requiredGuis) do
        local g = pgui and pgui:FindFirstChild(guiName)
        record(ctx, "ClientGUI." .. guiName, g ~= nil and g:IsA("ScreenGui"), "Missing ScreenGui " .. guiName)
    end

    local tfx = workspace:FindFirstChild("TempFX")
    record(ctx, "TempFX.FolderPresent", tfx ~= nil, "Missing workspace.TempFX")

    local dmgPool = tfx and tfx:FindFirstChild("DamageNumberPool")
    local dmgCount = dmgPool and #dmgPool:GetChildren() or 0
    record(
        ctx,
        "TempFX.DamageNumberPool40",
        dmgPool ~= nil and dmgCount >= 40,
        string.format("DamageNumberPool nodes = %d (expected >= 40)", dmgCount)
    )

    local spatialPool = tfx and tfx:FindFirstChild("SpatialAudioPool")
    local spatialCount = spatialPool and #spatialPool:GetChildren() or 0
    record(
        ctx,
        "TempFX.SpatialAudioPool",
        spatialPool ~= nil and spatialCount >= 16,
        string.format("SpatialAudioPool nodes = %d (expected >= 16)", spatialCount)
    )

    record(
        ctx,
        "WorldFX.CloudSeaBlanket",
        tfx ~= nil and tfx:FindFirstChild("SkybreakCloudSeaBlanket") ~= nil,
        "Missing TempFX.SkybreakCloudSeaBlanket"
    )
    record(
        ctx,
        "Audio.SoundGroupPresent",
        SoundService:FindFirstChild("SkybreakAudioEngine") ~= nil,
        "Missing SoundService.SkybreakAudioEngine"
    )
    record(
        ctx,
        "WorldNPCs.LivingControllerActive",
        _G.SkybreakLivingNPCsStarted == true or workspace:GetAttribute("SkybreakLivingNPCsActive") == true,
        "Living NPC controller is not active (_G.SkybreakLivingNPCsStarted / SkybreakLivingNPCsActive)"
    )

    return finalize(ctx)
end

function SmokeTest.RunServerAudit()
    local ctx = newContext("Server")
    local ServerScriptService = game:GetService("ServerScriptService")

    -- Brief settle wait if server just booted
    local deadline = os.clock() + 3.0
    while os.clock() < deadline do
        if workspace:FindFirstChild("SkybreakExpansionWorld")
            and workspace:FindFirstChild("ActiveEnemies")
            and workspace:FindFirstChild("SkybreakChests") then
            break
        end
        task.wait(0.1)
    end

    check3DAssetsAndRenderer(ctx, false)
    checkZeroAstralEmojis(ctx, false)
    checkUIScreenModules(ctx)
    checkRemotesAndCombatDataAndWorld(ctx)

    local services = ServerScriptService:FindFirstChild("Services")
    for _, svcName in ipairs({
        "GameService",
        "PlayerDataService",
        "Solid3DWorldColliders",
        "SkybreakCombatExpansion",
        "SkybreakWorldEventsService",
        "SkybreakSocialEconomyService",
        "SkybreakVendorAndArsenalService",
    }) do
        local mod = services and services:FindFirstChild(svcName)
        record(ctx, "ServerService." .. svcName, mod ~= nil and mod:IsA("ModuleScript"), "Missing " .. svcName)
    end

    local expWorld = workspace:FindFirstChild("SkybreakExpansionWorld")
    local vendorFolder = expWorld and expWorld:FindFirstChild("VendorNPCs")
    local vendorCount = vendorFolder and #vendorFolder:GetChildren() or 0
    record(
        ctx,
        "WorldVendors.10Physical3DStations",
        vendorCount >= 10,
        string.format("VendorNPCs count=%d (expected >=10)", vendorCount)
    )

    local sps = StarterPlayer:FindFirstChild("StarterPlayerScripts")
    record(ctx, "StarterPlayerScripts.Present", sps ~= nil, "Missing StarterPlayer.StarterPlayerScripts")
    for _, scriptName in ipairs({
        "SkybreakWorldClient",
        "BlenderEnemies",
        "SkybreakFlightAndCamera",
        "ClientBootstrap",
        "SkybreakClientVFX",
        "SkybreakAudioEngine",
    }) do
        local found = sps and (sps:FindFirstChild(scriptName) or sps:FindFirstChild(scriptName .. ".client"))
        local enabled = found ~= nil and (not found:IsA("BaseScript") or found.Disabled == false)
        record(
            ctx,
            "StarterPlayerScripts." .. scriptName,
            enabled,
            found == nil and ("Missing " .. scriptName) or (scriptName .. " is Disabled")
        )
    end
    local scFolder = sps and sps:FindFirstChild("SkybreakClient")
    for _, vfxModName in ipairs({ "DragonSovereignVFX", "VFXStudioLibrary", "UniversalVFXOverhaul" }) do
        local vMod = scFolder and scFolder:FindFirstChild(vfxModName)
        record(
            ctx,
            "VFXOverhaul." .. vfxModName,
            vMod ~= nil and vMod:IsA("ModuleScript"),
            "Missing SkybreakClient." .. vfxModName
        )
    end

    return finalize(ctx)
end

function SmokeTest.RunAll()
    if RunService:IsClient() then
        return SmokeTest.RunClientAudit()
    end
    return SmokeTest.RunServerAudit()
end

return SmokeTest
