local Players=game:GetService('Players')
local Tween=game:GetService('TweenService')
local ContentProvider=game:GetService('ContentProvider')
local Environment=require(game.ReplicatedStorage.Shared:WaitForChild('RealmEnvironment'))
local player=Players.LocalPlayer
local gui=Instance.new('ScreenGui');gui.Name='RealmTransition';gui.IgnoreGuiInset=true;gui.ResetOnSpawn=false;gui.DisplayOrder=900;gui.Parent=player:WaitForChild('PlayerGui')
local mask=Instance.new('Frame');mask.Size=UDim2.fromScale(1,1);mask.BackgroundColor3=Color3.fromRGB(6,11,23);mask.BackgroundTransparency=1;mask.BorderSizePixel=0;mask.Parent=gui
local generation=0;local loaded={};local current=nil
local function change(name,initial)
    if not Environment.Skyboxes[name] or name==current then return end
    generation+=1;local ticket=generation
    task.spawn(function()
        if not loaded[name] then
            local assets={};for _,id in Environment.Skyboxes[name]do table.insert(assets,id)end
            local ok,err=pcall(function()ContentProvider:PreloadAsync(assets)end)
            if not ok then warn('[SKYBREAK] Sky preload',name,err)end
            loaded[name]=ok
        end
        if ticket~=generation then return end
        if not initial then local fade=Tween:Create(mask,TweenInfo.new(.18),{BackgroundTransparency=0});fade:Play();fade.Completed:Wait()end
        if ticket~=generation then return end
        Environment.Apply(name);current=name
        gui:SetAttribute('CurrentRealm',name)
        Tween:Create(mask,TweenInfo.new(.35),{BackgroundTransparency=1}):Play()
    end)
end
player:GetAttributeChangedSignal('CurrentRealm'):Connect(function()change(player:GetAttribute('CurrentRealm')or'GoldenSky',false)end)
change(player:GetAttribute('CurrentRealm')or'GoldenSky',true)
