-- SKYBREAK: Fragments of the Core — Navigation & Modal Priority Router
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/ScreenRouter.lua
-- Single router managing active screens, back stack, Escape/Gamepad-B handling, and HUD visibility (Section 03).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local UIState = require(Shared:WaitForChild("Types"):WaitForChild("UIState"))

local Store = require(script.Parent:WaitForChild("Store"))
local Animations = require(script.Parent:WaitForChild("Animations"))

local ScreenRouter = {
    CurrentScreen = UIState.Screens.HUD,
    BackStack = {},
    RegisteredScreens = {},
    OnRouteChanged = nil,
}

function ScreenRouter.NormalizeRoute(route)
    if not route then
        return UIState.Screens.HUD
    end
    return UIState.LegacyPageMap[route] or route
end

function ScreenRouter.RegisterScreen(screenId, screenModule)
    ScreenRouter.RegisteredScreens[screenId] = screenModule
end

function ScreenRouter.Navigate(route, options)
    options = options or {}
    local target = ScreenRouter.NormalizeRoute(route)
    local previous = ScreenRouter.CurrentScreen

    if previous == target and not options.forceRebuild then
        return target
    end

    -- Cleanup active screen animations and resources (e.g. ViewportFrame connections)
    local prevModule = ScreenRouter.RegisteredScreens[previous]
    if prevModule and type(prevModule.Cleanup) == "function" then
        pcall(prevModule.Cleanup)
    end
    Animations.CleanupScope("Screen_" .. tostring(previous))

    if not options.replace and previous and previous ~= target then
        table.insert(ScreenRouter.BackStack, previous)
        if #ScreenRouter.BackStack > 12 then
            table.remove(ScreenRouter.BackStack, 1)
        end
    end

    ScreenRouter.CurrentScreen = target
    ScreenRouter.LastNavigateClock = os.clock()
    Store.SetView({
        currentScreen = target,
        backStack = ScreenRouter.BackStack,
    })

    if ScreenRouter.OnRouteChanged then
        ScreenRouter.OnRouteChanged(target, previous)
    end

    return target
end

function ScreenRouter.CloseAllToHUD()
    table.clear(ScreenRouter.BackStack)
    return ScreenRouter.Navigate(UIState.Screens.HUD, { replace = true, forceRebuild = true })
end

function ScreenRouter.ToggleScreen(route)
    if os.clock() - (ScreenRouter.LastNavigateClock or 0) < 0.06 then
        return ScreenRouter.CurrentScreen
    end
    local target = ScreenRouter.NormalizeRoute(route)
    if ScreenRouter.CurrentScreen == target then
        return ScreenRouter.Navigate(UIState.Screens.HUD, { replace = true })
    end
    return ScreenRouter.Navigate(target)
end

function ScreenRouter.Back()
    local view = Store.GetView()
    -- Priority 1: Dismiss active Confirmation Modal
    if view.modal and view.modal.visible then
        Store.CloseModal()
        return ScreenRouter.CurrentScreen
    end

    -- Priority 2: Dismiss contextual NPC Dialogue overlay
    if view.dialogue and view.dialogue.visible then
        Store.SetView({ dialogue = { visible = false } })
        return ScreenRouter.CurrentScreen
    end

    -- Priority 3: If in a full-screen sub-menu (including MainMenu), return to previous screen or HUD
    if ScreenRouter.CurrentScreen ~= UIState.Screens.HUD then
        local popped = table.remove(ScreenRouter.BackStack)
        local fallback = popped or UIState.Screens.HUD
        return ScreenRouter.Navigate(fallback, { replace = true })
    end

    -- Priority 4: If on HUD and Escape/Back pressed, open MainMenu / Pause
    if ScreenRouter.CurrentScreen == UIState.Screens.HUD then
        return ScreenRouter.Navigate(UIState.Screens.MainMenu)
    end

    return ScreenRouter.CurrentScreen
end

function ScreenRouter.BlocksCombat()
    local view = Store.GetView()
    if view.modal and view.modal.visible then
        return true
    end
    if view.dialogue and view.dialogue.visible then
        return true
    end
    return ScreenRouter.CurrentScreen ~= UIState.Screens.HUD
end

return ScreenRouter
