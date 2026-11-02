-- SKYBREAK: Fragments of the Core — Motion & Micro-Interaction Controller
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Animations.lua
-- Respects Reduced Motion accessibility setting and prevents tween leaks when closing screens.

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local UIAnimator = require(Shared:WaitForChild("UIAnimator"))
local SpritePlayer = require(Shared:WaitForChild("SpritePlayer"))

local Animations = {
    ReducedMotion = false,
    ActiveTweens = {},
}

function Animations.SetReducedMotion(enabled)
    Animations.ReducedMotion = enabled == true
    UIAnimator.ReducedMotion = enabled == true
    if Animations.ReducedMotion then
        Animations.CleanupScope("Ambient")
        SpritePlayer.StopAll()
    end
end

function Animations.Play(instance, duration, goal, easingStyle, easingDirection, scope)
    if not instance then
        return nil
    end
    if Animations.ReducedMotion or (duration or 0) <= 0 then
        for prop, val in pairs(goal) do
            pcall(function()
                instance[prop] = val
            end)
        end
        return nil
    end

    local info = TweenInfo.new(
        duration or Theme.Motion.Hover,
        easingStyle or Enum.EasingStyle.Quad,
        easingDirection or Enum.EasingDirection.Out
    )
    local ok, tween = pcall(function()
        return TweenService:Create(instance, info, goal)
    end)
    if not ok or not tween then
        for prop, val in pairs(goal) do
            pcall(function()
                instance[prop] = val
            end)
        end
        return nil
    end

    if scope then
        local bucket = Animations.ActiveTweens[scope]
        if not bucket then
            bucket = {}
            Animations.ActiveTweens[scope] = bucket
        end
        table.insert(bucket, tween)
        tween.Completed:Once(function()
            local currentBucket = Animations.ActiveTweens[scope]
            if currentBucket then
                local idx = table.find(currentBucket, tween)
                if idx then
                    table.remove(currentBucket, idx)
                end
            end
        end)
    end

    tween:Play()
    return tween
end

function Animations.TweenBar(fillFrame, ratio, duration, scope)
    local clamped = math.clamp(tonumber(ratio) or 0, 0, 1)
    return Animations.Play(
        fillFrame,
        duration or Theme.Motion.HP,
        { Size = UDim2.fromScale(clamped, 1) },
        Enum.EasingStyle.Quint,
        Enum.EasingDirection.Out,
        scope
    )
end

function Animations.FadeInPanel(frame, targetPos, duration, scope)
    if not frame then
        return
    end
    targetPos = targetPos or frame.Position
    if Animations.ReducedMotion then
        frame.Position = targetPos
        return
    end
    frame.Position = UDim2.new(
        targetPos.X.Scale,
        targetPos.X.Offset,
        targetPos.Y.Scale,
        targetPos.Y.Offset + 14
    )
    Animations.Play(
        frame,
        duration or Theme.Motion.Open,
        { Position = targetPos },
        Enum.EasingStyle.Quart,
        Enum.EasingDirection.Out,
        scope
    )
end

function Animations.Tween(instance, presetOrDuration, goal, scope)
    local dur = type(presetOrDuration) == "number" and presetOrDuration or Theme.Motion.Hover
    return Animations.Play(instance, dur, goal, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, scope)
end

function Animations.PulseGlow(instance, scope, propName, minVal, maxVal)
    if not instance or Animations.ReducedMotion then
        return nil
    end
    propName = propName or "BackgroundTransparency"
    local info = TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
    local ok, tween = pcall(function()
        return TweenService:Create(instance, info, { [propName] = maxVal or 0.5 })
    end)
    if ok and tween then
        local targetScope = scope or "Ambient"
        Animations.ActiveTweens[targetScope] = Animations.ActiveTweens[targetScope] or {}
        table.insert(Animations.ActiveTweens[targetScope], tween)
        tween:Play()
        return tween
    end
    return nil
end

function Animations.CleanupScope(scope)
    local list = Animations.ActiveTweens[scope]
    if not list then
        return
    end
    for _, tween in ipairs(list) do
        pcall(function()
            tween:Cancel()
        end)
    end
    Animations.ActiveTweens[scope] = nil
end

function Animations.CleanupAll()
    for scope in pairs(Animations.ActiveTweens) do
        Animations.CleanupScope(scope)
    end
end

return Animations
