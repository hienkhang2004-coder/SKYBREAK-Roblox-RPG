-- SKYBREAK: Fragments of the Core — Responsive Layout & Device Profile Utility
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Responsive.lua

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local Responsive = {}

Responsive.Profiles = {
    Desktop = "Desktop",
    Laptop = "Laptop",
    Tablet = "Tablet",
    PhoneLandscape = "PhoneLandscape",
    PhonePortrait = "PhonePortrait",
    Console = "Console",
}

function Responsive.IsMobile(viewportSize, layoutOverride)
    if layoutOverride == "Mobile" then
        return true
    elseif layoutOverride == "Desktop" then
        return false
    end
    if LocalPlayer and LocalPlayer:GetAttribute("ForceMobileUI") == true then
        return true
    end
    local size = viewportSize
    if not size then
        local cam = workspace.CurrentCamera
        size = (cam and cam.ViewportSize) or Vector2.new(1280, 720)
    end
    local w = math.max(320, size.X)
    local h = math.max(240, size.Y)
    local isPortrait = w < h * 0.92
    local touchDevice = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
    return touchDevice or (w < 820) or (w <= 920 and h <= 540) or isPortrait
end

function Responsive.GetState(viewportSize, layoutOverride, textScaleSetting)
    local size = viewportSize or Vector2.new(1280, 720)
    local w = math.max(320, size.X)
    local h = math.max(240, size.Y)
    local aspect = w / h
    local isPortrait = w < h * 0.92

    local gamepadEnabled = UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled
    local isMobile = Responsive.IsMobile(size, layoutOverride)

    local profile = Responsive.Profiles.Desktop
    if gamepadEnabled and layoutOverride == "Auto" then
        profile = Responsive.Profiles.Console
    elseif isPortrait then
        profile = Responsive.Profiles.PhonePortrait
    elseif isMobile and w < 960 then
        profile = Responsive.Profiles.PhoneLandscape
    elseif isMobile then
        profile = Responsive.Profiles.Tablet
    elseif w <= 1400 or h <= 800 then
        profile = Responsive.Profiles.Laptop
    end

    -- Reference canvas & scale clamping so fonts never shrink below readable sizes (Section 06.2)
    local refWidth = isPortrait and 760 or 1366
    local refHeight = isPortrait and 1220 or 768
    local rawScale = math.min(w / refWidth, h / refHeight)
    local uiScale = math.clamp(rawScale, 0.68, 1.25)

    local userTextScale = math.clamp(tonumber(textScaleSetting) or 1.0, 0.85, 1.25)

    return {
        Viewport = Vector2.new(w, h),
        Aspect = aspect,
        Profile = profile,
        IsPortrait = isPortrait,
        IsMobile = isMobile,
        IsCompact = isPortrait or w < 1024 or h < 640,
        TouchControls = isMobile,
        GamepadEnabled = gamepadEnabled,
        CanvasSize = UDim2.fromOffset(refWidth, refHeight),
        CanvasWidth = refWidth,
        CanvasHeight = refHeight,
        UIScale = uiScale,
        TextScale = userTextScale,
        CollapseSidebar = isPortrait or w < 900,
        MinButtonHeight = isMobile and 52 or 44,
    }
end

function Responsive.ClampTooltipPosition(anchorPos, tooltipSize, viewportSize, margin)
    margin = margin or 12
    local vw = viewportSize.X
    local vh = viewportSize.Y
    local tw = tooltipSize.X
    local th = tooltipSize.Y
    local x = math.clamp(anchorPos.X, margin, math.max(margin, vw - tw - margin))
    local y = math.clamp(anchorPos.Y, margin, math.max(margin, vh - th - margin))
    return Vector2.new(x, y)
end

return Responsive
