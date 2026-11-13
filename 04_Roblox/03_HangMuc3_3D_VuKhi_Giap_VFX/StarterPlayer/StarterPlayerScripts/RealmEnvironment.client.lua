local Players = game:GetService('Players')
local Lighting = game:GetService('Lighting')
local Tween = game:GetService('TweenService')
local ContentProvider = game:GetService('ContentProvider')
local Environment = require(game.ReplicatedStorage.Shared:WaitForChild('RealmEnvironment'))

local SKY_FACE_MAP = {
    { Prop = 'SkyboxBk', Short = 'bk' },
    { Prop = 'SkyboxDn', Short = 'dn' },
    { Prop = 'SkyboxFt', Short = 'ft' },
    { Prop = 'SkyboxLf', Short = 'lf' },
    { Prop = 'SkyboxRt', Short = 'rt' },
    { Prop = 'SkyboxUp', Short = 'up' },
}

local function enforceFutureRealmBaseline(realmName)
    Lighting.GlobalShadows = true
    Lighting.ShadowSoftness = 0.18
    Lighting.EnvironmentDiffuseScale = 1.0
    Lighting.EnvironmentSpecularScale = 1.0

    local sunRays = Lighting:FindFirstChild('SkybreakSunRays') or Lighting:FindFirstChildOfClass('SunRaysEffect')
    if not sunRays or not sunRays:IsA('SunRaysEffect') then
        sunRays = Instance.new('SunRaysEffect')
        sunRays.Name = 'SkybreakSunRays'
        sunRays.Parent = Lighting
    end
    sunRays.Enabled = true
    sunRays.Intensity = 0.14
    sunRays.Spread = 0.65

    local bloom = Lighting:FindFirstChild('SkybreakVFXBloom') or Lighting:FindFirstChildOfClass('BloomEffect')
    if not bloom or not bloom:IsA('BloomEffect') then
        bloom = Instance.new('BloomEffect')
        bloom.Name = 'SkybreakVFXBloom'
        bloom.Parent = Lighting
    end
    bloom.Enabled = true
    bloom.Intensity = 0.45
    bloom.Threshold = 1.15
    bloom.Size = 28

    pcall(function()
        local terrain = workspace.Terrain
        if terrain then
            local clouds = terrain:FindFirstChildOfClass('Clouds')
            if not clouds then
                clouds = Instance.new('Clouds')
                clouds.Name = 'SkybreakVolumetricClouds'
                clouds.Cover = 0.72
                clouds.Density = 0.78
                clouds.Color = Color3.fromRGB(244, 224, 198)
                clouds.Parent = terrain
            end
            clouds.Enabled = true
        end
    end)

    Lighting:SetAttribute('SkybreakEnvironment', realmName)
end

local function applyRealmSkyboxOnly(realmName)
    local faces = Environment.Skyboxes[realmName] or Environment.Skyboxes.GoldenSky
    local sky = Lighting:FindFirstChild('SKYBREAK_RealmSky')
    for _, ch in ipairs(Lighting:GetChildren()) do
        if ch:IsA('Sky') and ch ~= sky then
            ch:Destroy()
        end
    end
    if not sky or not sky:IsA('Sky') then
        if sky then sky:Destroy() end
        sky = Instance.new('Sky')
        sky.Name = 'SKYBREAK_RealmSky'
        sky.Parent = Lighting
    end
    sky.CelestialBodiesShown = true
    sky.SunAngularSize = 16
    sky.MoonAngularSize = 11
    sky.StarCount = 3200
    if faces then
        for _, entry in ipairs(SKY_FACE_MAP) do
            local assetId = faces[entry.Prop] or faces[entry.Short]
            if assetId then
                sky[entry.Prop] = assetId
            end
        end
    end
    enforceFutureRealmBaseline(realmName)
end

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
                if type(id) == 'string' and id:sub(1, 11) ~= 'rbxasset://' then
                    table.insert(assets, id)
                end
            end
            if #assets > 0 then
                local failedIds = {}
                local ok, err = pcall(function()
                    ContentProvider:PreloadAsync(assets, function(contentId, status)
                        if status ~= Enum.AssetFetchStatus.Success then
                            table.insert(failedIds, tostring(contentId))
                        end
                    end)
                end)
                if not ok then
                    warn('[SKYBREAK] Sky preload', name, err)
                end
                if #failedIds > 0 then
                    warn('[SKYBREAK] Sky faces failed for', name, table.concat(failedIds, ', '), '-> default sky')
                    if Environment.MarkSkyFailed then
                        Environment.MarkSkyFailed(name)
                    end
                end
                loaded[name] = ok
            else
                loaded[name] = true
            end
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
        applyRealmSkyboxOnly(name)
        current = name
        gui:SetAttribute('CurrentRealm', name)
        fadeOutMask(ticket)
    end)
end

player:GetAttributeChangedSignal('CurrentRealm'):Connect(function()
    change(player:GetAttribute('CurrentRealm') or 'GoldenSky', false)
end)
change(player:GetAttribute('CurrentRealm') or 'GoldenSky', true)
