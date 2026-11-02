local Players = game:GetService('Players')
local Tween = game:GetService('TweenService')
local ContentProvider = game:GetService('ContentProvider')
local Environment = require(game.ReplicatedStorage.Shared:WaitForChild('RealmEnvironment'))

local player = Players.LocalPlayer
local gui = Instance.new('ScreenGui')
gui.Name = 'RealmTransition'
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 900
gui.Enabled = false
gui.Parent = player:WaitForChild('PlayerGui')

local mask = Instance.new('Frame')
mask.Size = UDim2.fromScale(1, 1)
mask.BackgroundColor3 = Color3.fromRGB(6, 11, 23)
mask.BackgroundTransparency = 1
mask.BorderSizePixel = 0
mask.Parent = gui

local generation = 0
local loaded = {}
local current = nil
local activeTween = nil

local function fadeOutMask(ticket)
    if activeTween then
        pcall(function()
            activeTween:Cancel()
        end)
    end
    local fadeOut = Tween:Create(mask, TweenInfo.new(0.35), { BackgroundTransparency = 1 })
    activeTween = fadeOut
    fadeOut:Play()
    fadeOut.Completed:Connect(function()
        if ticket == generation and mask.BackgroundTransparency >= 0.99 then
            gui.Enabled = false
        end
    end)
end

local function change(rawName, initial)
    local name = tostring(rawName or 'GoldenSky')
    if name == 'SkyHub' or name == '' then
        name = 'GoldenSky'
    end
    if not Environment.Skyboxes[name] then
        name = 'GoldenSky'
    end
    if name == current then
        -- Guarantee mask never stays stuck opaque if an A -> B -> A revert occurs mid-fade!
        if mask.BackgroundTransparency < 0.99 then
            generation += 1
            fadeOutMask(generation)
        end
        return
    end
    generation += 1
    local ticket = generation
    task.spawn(function()
        if not loaded[name] then
            local assets = {}
            for _, id in pairs(Environment.Skyboxes[name]) do
                table.insert(assets, id)
            end
            local ok, err = pcall(function()
                ContentProvider:PreloadAsync(assets)
            end)
            if not ok then
                warn('[SKYBREAK] Sky preload', name, err)
            end
            loaded[name] = ok
        end
        if ticket ~= generation then
            return
        end
        if not initial then
            if activeTween then
                pcall(function()
                    activeTween:Cancel()
                end)
            end
            gui.Enabled = true
            local fadeIn = Tween:Create(mask, TweenInfo.new(0.18), { BackgroundTransparency = 0 })
            activeTween = fadeIn
            fadeIn:Play()
            fadeIn.Completed:Wait()
        end
        if ticket ~= generation then
            return
        end
        Environment.Apply(name)
        current = name
        gui:SetAttribute('CurrentRealm', name)
        fadeOutMask(ticket)
    end)
end

player:GetAttributeChangedSignal('CurrentRealm'):Connect(function()
    change(player:GetAttribute('CurrentRealm') or 'GoldenSky', false)
end)
change(player:GetAttribute('CurrentRealm') or 'GoldenSky', true)
