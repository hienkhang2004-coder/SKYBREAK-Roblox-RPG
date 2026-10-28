-- SKYBREAK: Fragments of the Core — Unified Modular UI Application Orchestrator
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/App.lua
-- Creates the canonical StarterGui/PlayerGui hierarchy:
-- SkybreakUI (ScreenGui) -> BackgroundLayer, HUDLayer, MenuLayer, ModalLayer, NotificationLayer (Section 05).

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local UIState = require(Shared:WaitForChild("Types"):WaitForChild("UIState"))
local PanelMotion = require(Shared:WaitForChild("PanelMotion"))

local UIFactory = require(script.Parent:WaitForChild("UIFactory"))
local Responsive = require(script.Parent:WaitForChild("Responsive"))
local Animations = require(script.Parent:WaitForChild("Animations"))
local Store = require(script.Parent:WaitForChild("Store"))
local ScreenRouter = require(script.Parent:WaitForChild("ScreenRouter"))

local Toast = require(script.Parent:WaitForChild("Components"):WaitForChild("Toast"))
local Modal = require(script.Parent:WaitForChild("Components"):WaitForChild("Modal"))

local MainMenu = require(script.Parent:WaitForChild("Screens"):WaitForChild("MainMenu"))
local HUD = require(script.Parent:WaitForChild("Screens"):WaitForChild("HUD"))
local Inventory = require(script.Parent:WaitForChild("Screens"):WaitForChild("Inventory"))
local Skills = require(script.Parent:WaitForChild("Screens"):WaitForChild("Skills"))
local Fruits = require(script.Parent:WaitForChild("Screens"):WaitForChild("Fruits"))
local WorldMap = require(script.Parent:WaitForChild("Screens"):WaitForChild("WorldMap"))
local QuestJournal = require(script.Parent:WaitForChild("Screens"):WaitForChild("QuestJournal"))
local Forge = require(script.Parent:WaitForChild("Screens"):WaitForChild("Forge"))
local Raid = require(script.Parent:WaitForChild("Screens"):WaitForChild("Raid"))
local Dialogue = require(script.Parent:WaitForChild("Screens"):WaitForChild("Dialogue"))
local Settings = require(script.Parent:WaitForChild("Screens"):WaitForChild("Settings"))

local HUDController = require(script.Parent:WaitForChild("Controllers"):WaitForChild("HUDController"))
local QuestController = require(script.Parent:WaitForChild("Controllers"):WaitForChild("QuestController"))

local App = {
    Initialized = false,
    Page = "HUD",
    Current = "HUD",
    LowFX = false,
    State = nil,
    ScreenGui = nil,
    Layers = {},
    ToastApi = nil,
    ModalApi = nil,
    DialogueApi = nil,
    Connections = {},
}

local SCREEN_MODULES = {
    [UIState.Screens.MainMenu] = MainMenu,
    [UIState.Screens.HUD] = HUD,
    [UIState.Screens.Inventory] = Inventory,
    [UIState.Screens.Skills] = Skills,
    [UIState.Screens.Fruits] = Fruits,
    [UIState.Screens.WorldMap] = WorldMap,
    [UIState.Screens.QuestJournal] = QuestJournal,
    [UIState.Screens.Forge] = Forge,
    [UIState.Screens.Raid] = Raid,
    [UIState.Screens.Settings] = Settings,
}

for id, mod in pairs(SCREEN_MODULES) do
    ScreenRouter.RegisterScreen(id, mod)
end

function App.GetResponsiveState()
    local gui = App.ScreenGui
    local absSize = (gui and gui.AbsoluteSize.X > 0) and gui.AbsoluteSize or Vector2.new(1366, 768)
    local view = Store.GetView()
    local s = view.settings or {}
    return Responsive.GetState(absSize, s.layoutMode or "Auto", s.textScale or 1.0)
end

function App.RebuildActiveScreen()
    if not App.ScreenGui then
        return
    end
    local resp = App.GetResponsiveState()
    local activeRoute = ScreenRouter.CurrentScreen

    local bgTint = App.Layers.BackgroundTint
    if bgTint then
        bgTint.BackgroundTransparency = (activeRoute == UIState.Screens.HUD) and 1
            or (activeRoute == UIState.Screens.MainMenu and 0.14 or 0.08)
    end

    local blur = Lighting:FindFirstChild("SkybreakMenuBlur")
        or UIFactory.Create("BlurEffect", Lighting, { Name = "SkybreakMenuBlur", Size = 0 })
    blur.Size = (activeRoute == UIState.Screens.HUD) and 0 or 12

    local hudCanvas = App.Layers.HUDCanvas
    local menuCanvas = App.Layers.MenuCanvas
    if hudCanvas and menuCanvas then
        hudCanvas.Size = resp.CanvasSize
        menuCanvas.Size = resp.CanvasSize
        if App.Layers.HUDScale then
            App.Layers.HUDScale.Scale = resp.UIScale
        end
        if App.Layers.MenuScale then
            App.Layers.MenuScale.Scale = resp.UIScale
        end
    end

    -- Clear previous menu screen children
    if menuCanvas then
        for _, child in ipairs(menuCanvas:GetChildren()) do
            if child:IsA("GuiObject") then
                child:Destroy()
            end
        end
    end
    if hudCanvas then
        for _, child in ipairs(hudCanvas:GetChildren()) do
            if child:IsA("GuiObject") then
                child:Destroy()
            end
        end
    end

    if activeRoute == UIState.Screens.HUD then
        App.Layers.HUDLayer.Visible = true
        App.Layers.MenuLayer.Visible = false
        HUD.Build(hudCanvas, resp)
    else
        App.Layers.HUDLayer.Visible = false
        App.Layers.MenuLayer.Visible = true
        local mod = SCREEN_MODULES[activeRoute] or MainMenu
        local builtFrame = mod.Build(menuCanvas, resp)
        if activeRoute == UIState.Screens.MainMenu or activeRoute == UIState.Screens.Forge or activeRoute == UIState.Screens.Settings then
            local closeBtn = UIFactory.Create("TextButton", menuCanvas, {
                Name = "FloatingResumeBtn",
                AnchorPoint = Vector2.new(1, 0),
                Position = UDim2.new(1, -12, 0, 8),
                Size = UDim2.fromOffset(146, 34),
                BackgroundColor3 = Theme.Colors.BG_800,
                BorderSizePixel = 0,
                Text = "✕ RESUME [ESC]",
                Font = Theme.Fonts.Bold,
                TextSize = 12,
                TextColor3 = Theme.Colors.ACCENT_GOLD,
                ZIndex = 40,
            })
            UIFactory.Corner(closeBtn, Theme.Radius.Small)
            UIFactory.Stroke(closeBtn, Theme.Colors.ACCENT_GOLD, 1.4, 0.15)
            closeBtn.Activated:Connect(function()
                ScreenRouter.CloseAllToHUD()
            end)
        end
        PanelMotion.Open(App.Layers.MenuLayer)
        Animations.FadeInPanel(builtFrame, builtFrame.Position, Theme.Motion.Open, "Screen_" .. tostring(activeRoute))
    end
end

function App.Init(onAction, onAttack)
    HUDController.SetCombatCallbacks(onAction, onAttack)
    if App.Initialized and App.ScreenGui and App.ScreenGui.Parent then
        return App
    end
    App.Initialized = true

    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    -- Prevent duplicate ScreenGuis on respawn or reload (Section 15 Rule 3)
    for _, existingName in ipairs({ "SkybreakUI", "SKYBREAK", "SkybreakPremiumUI" }) do
        local old = playerGui:FindFirstChild(existingName)
        if old then
            old:Destroy()
        end
    end

    local gui = UIFactory.Create("ScreenGui", playerGui, {
        Name = "SkybreakUI",
        ResetOnSpawn = false,
        DisplayOrder = 25,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
    })
    App.ScreenGui = gui

    -- 5 Canonical Layers (Section 05)
    local bgLayer = UIFactory.Create("Frame", gui, {
        Name = "BackgroundLayer",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 1,
    })
    local bgTint = UIFactory.Create("Frame", bgLayer, {
        Name = "Backdrop",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Theme.Colors.BG_900,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    })
    UIFactory.Gradient(bgTint, Color3.fromRGB(16, 32, 56), Theme.Colors.BG_900, 70)

    local hudLayer = UIFactory.Create("Frame", gui, {
        Name = "HUDLayer",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Visible = false,
        ZIndex = 5,
    })
    local hudCanvas = UIFactory.Create("Frame", hudLayer, {
        Name = "Canvas",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(1366, 768),
        BackgroundTransparency = 1,
    })
    local hudScale = UIFactory.Create("UIScale", hudCanvas, { Scale = 1 })

    local menuLayer = UIFactory.Create("CanvasGroup", gui, {
        Name = "MenuLayer",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        GroupTransparency = 0,
        Visible = true,
        ZIndex = 10,
    })
    local menuCanvas = UIFactory.Create("Frame", menuLayer, {
        Name = "Canvas",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(1366, 768),
        BackgroundTransparency = 1,
    })
    local menuScale = UIFactory.Create("UIScale", menuCanvas, { Scale = 1 })

    local modalLayer = UIFactory.Create("Frame", gui, {
        Name = "ModalLayer",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 30,
    })

    local notificationLayer = UIFactory.Create("Frame", gui, {
        Name = "NotificationLayer",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 50,
    })

    local _, dialogueApi = Dialogue.CreateOverlay(modalLayer)
    local _, modalApi = Modal.Create(modalLayer, { name = "ConfirmModal", visible = false })
    local _, toastApi = Toast.Create(notificationLayer, { name = "Toast" })

    App.Layers = {
        BackgroundLayer = bgLayer,
        BackgroundTint = bgTint,
        HUDLayer = hudLayer,
        HUDCanvas = hudCanvas,
        HUDScale = hudScale,
        MenuLayer = menuLayer,
        MenuCanvas = menuCanvas,
        MenuScale = menuScale,
        ModalLayer = modalLayer,
        NotificationLayer = notificationLayer,
    }
    App.DialogueApi = dialogueApi
    App.ModalApi = modalApi
    App.ToastApi = toastApi

    Settings.OnLowFXChanged = function(val)
        App.LowFX = val
    end

    ScreenRouter.OnRouteChanged = function(newRoute)
        App.Page = (newRoute == UIState.Screens.MainMenu and "Menu")
            or (newRoute == UIState.Screens.WorldMap and "Map")
            or (newRoute == UIState.Screens.QuestJournal and "Quests")
            or newRoute
        App.Current = App.Page
        App.RebuildActiveScreen()
    end

    Store.SubscribeSnapshot(function(snap)
        local activeRoute = ScreenRouter.CurrentScreen
        if activeRoute == UIState.Screens.HUD then
            HUD.Update(snap, Store.GetView())
        elseif activeRoute == UIState.Screens.MainMenu then
            MainMenu.Update(snap)
        elseif activeRoute == UIState.Screens.Inventory then
            Inventory.Update(snap)
        elseif activeRoute == UIState.Screens.Fruits then
            Fruits.Update()
        end
    end)

    Store.SubscribeView(function(view)
        if App.ModalApi then
            App.ModalApi:Update(view.modal)
        end
        if App.DialogueApi then
            App.DialogueApi:Update(view.dialogue)
        end
        if ScreenRouter.CurrentScreen == UIState.Screens.HUD then
            HUD.Update(Store.GetSnapshot(), view)
        elseif ScreenRouter.CurrentScreen == UIState.Screens.Forge then
            Forge.Update()
        elseif ScreenRouter.CurrentScreen == UIState.Screens.Settings then
            App.RebuildActiveScreen()
        end
    end)

    Store.SubscribeToast(function(toastPayload)
        if App.ToastApi then
            App.ToastApi:Show(toastPayload.message, toastPayload.kind, toastPayload.duration)
        end
    end)

    -- Viewport resize listener (debounced)
    local resizePending = false
    table.insert(App.Connections, gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if resizePending then
            return
        end
        resizePending = true
        task.delay(0.15, function()
            resizePending = false
            App.RebuildActiveScreen()
        end)
    end))

    -- External deterministic screen request bridge (used by tutorials, prompts, and automated tests)
    table.insert(App.Connections, gui:GetAttributeChangedSignal("RequestScreen"):Connect(function()
        local req = gui:GetAttribute("RequestScreen")
        if type(req) == "string" and #req > 0 then
            gui:SetAttribute("RequestScreen", "")
            if req == "HUD" or req == "Close" then
                ScreenRouter.CloseAllToHUD()
            else
                ScreenRouter.Navigate(req)
            end
        end
    end))

    -- Keyboard & Gamepad Navigation Shortcuts (Escape, G, I, K, M, J, O, F, P)
    table.insert(App.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if UserInputService:GetFocusedTextBox() then
            return
        end
        if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
            ScreenRouter.Back()
            return
        end
        local shiftDown = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
        local ctrlDown = UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl)
        if input.KeyCode == Enum.KeyCode.G then
            ScreenRouter.ToggleScreen(UIState.Screens.Fruits)
            return
        elseif input.KeyCode == Enum.KeyCode.K then
            ScreenRouter.ToggleScreen(UIState.Screens.Skills)
            return
        elseif input.KeyCode == Enum.KeyCode.I then
            ScreenRouter.ToggleScreen(UIState.Screens.Inventory)
            return
        elseif input.KeyCode == Enum.KeyCode.M then
            ScreenRouter.ToggleScreen(UIState.Screens.WorldMap)
            return
        elseif (input.KeyCode == Enum.KeyCode.J and not ctrlDown) or input.KeyCode == Enum.KeyCode.L then
            ScreenRouter.ToggleScreen(UIState.Screens.QuestJournal)
            return
        elseif input.KeyCode == Enum.KeyCode.O then
            ScreenRouter.ToggleScreen(UIState.Screens.Settings)
            return
        elseif input.KeyCode == Enum.KeyCode.F and not shiftDown then
            ScreenRouter.ToggleScreen(UIState.Screens.Forge)
            return
        elseif input.KeyCode == Enum.KeyCode.P then
            ScreenRouter.ToggleScreen(UIState.Screens.Raid)
            return
        end
        if processed then
            return
        end
        if input.KeyCode == Enum.KeyCode.Space then
            local v = Store.GetView()
            if v.dialogue and v.dialogue.visible then
                local cmd = v.dialogue.actionCommand
                QuestController.CloseDialogue()
                if type(cmd) == "string" and cmd:sub(1, 11) == "OpenScreen:" then
                    ScreenRouter.Navigate(cmd:sub(12))
                end
            end
        end
    end))

    -- Periodic cooldown & shield ticker for HUD
    task.spawn(function()
        while gui and gui.Parent do
            task.wait(0.1)
            if ScreenRouter.CurrentScreen == UIState.Screens.HUD then
                HUD.Update(Store.GetSnapshot(), Store.GetView())
            end
        end
    end)

    App.RebuildActiveScreen()
    return App
end

-- Backward-compatible methods used by ClientBootstrap.client.lua
function App.Show(page)
    ScreenRouter.Navigate(page)
end

function App.Build()
    App.RebuildActiveScreen()
end

function App.Render()
    local snap = Store.GetSnapshot()
    if ScreenRouter.CurrentScreen == UIState.Screens.HUD then
        HUD.Update(snap, Store.GetView())
    elseif ScreenRouter.CurrentScreen == UIState.Screens.MainMenu then
        MainMenu.Update(snap)
    elseif ScreenRouter.CurrentScreen == UIState.Screens.Inventory then
        Inventory.Update(snap)
    end
end

function App.SetInteract(text)
    Store.SetView({ interactPrompt = text })
end

function App.SetLockTarget(targetName)
    Store.SetView({ lockTarget = targetName })
end

function App.Toast(message, kind)
    if type(message) == "string" and #message > 0 then
        Store.ShowToast(message, kind or "info", 2.8)
    end
end

function App.CyclePartySize()
    ScreenRouter.ToggleScreen(UIState.Screens.Raid)
end

function App.BlocksCombat()
    return ScreenRouter.BlocksCombat()
end

function App.OpenDialogue(d)
    if type(d) == "table" then
        QuestController.OpenDialogue(d.speaker, d.text, d.role, d.questId, d.actionLabel, d.actionCommand)
    end
end

function App.Message(message)
    if type(message) ~= "string" then
        return
    end
    if string.sub(message, 1, 5) == "Lyra:" or string.sub(message, 1, 5) == "Kael:" then
        local speaker = string.sub(message, 1, 5) == "Kael:" and "KAEL • CELESTIAL FORGE" or "LYRA • SKY HUB"
        local role = string.sub(message, 1, 5) == "Kael:" and "Master Blacksmith" or "Lorekeeper of the Core"
        QuestController.OpenDialogue(speaker, message, role)
    else
        Store.ShowToast(message, "info", 3.5)
    end
end

function App.SetState(rawState)
    local previous = App.State
    App.State = rawState
    local player = Players.LocalPlayer
    local realmAttr = player and player:GetAttribute("CurrentRealm") or "GoldenSky"
    Store.SetServerSnapshot(rawState, realmAttr)

    if previous and (previous.ClassId ~= rawState.ClassId or previous.Gender ~= rawState.Gender) then
        App.RebuildActiveScreen()
    end
end

return App
