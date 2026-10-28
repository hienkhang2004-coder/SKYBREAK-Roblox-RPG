local Renderer=require(game.ReplicatedStorage:WaitForChild('DelegatedV5Renderer'))
local sources=game.ReplicatedStorage.DelegatedV5Sources
local Run=game:GetService('RunService')
local C=require(game.ReplicatedStorage.Shared.Config)
local actors={};local templates={};local clips={};local pending={}
local function hide(model)
    for _,o in model:GetDescendants()do
        if o:IsA('BasePart')then o.LocalTransparencyModifier=1 end
        if o:IsA('Decal')then o.Transparency=1 end
    end
end
local function register(marker)
    if not marker:IsA('BasePart')then return end
    local id=marker:GetAttribute('InteractableId')
    if (id~='Lyra'and id~='Kael')or pending[marker]or actors[marker]or not sources:FindFirstChild(id)then return end
    pending[marker]=true
    local ok,err=xpcall(function()
        templates[id]=templates[id]or Renderer.Build(id)
        clips[id]=clips[id]or Renderer.Clips(id,2.6)
        if not marker.Parent then return end
        local visual=templates[id]:Clone();visual.Name=id..'_BlenderVisual';visual:ScaleTo(2.6)
        local floor=marker.Position-Vector3.new(0,3,0)
        local facing=CFrame.lookAt(floor,Vector3.new(C.Spawn.X,floor.Y,C.Spawn.Z))
        visual:PivotTo(facing);visual.Parent=marker.Parent
        local old=marker.Parent:FindFirstChild(id..'Character');if old then hide(old)end
        local connection=marker.Parent.ChildAdded:Connect(function(o)if o.Name==id..'Character'then hide(o)end end)
        local prop
        if id=='Kael'and sources:FindFirstChild('KaelWorkstation')then
            prop=Renderer.Build('KaelWorkstation'):Clone();prop.Name='Kael_Anvil';prop:ScaleTo(2.6);prop:PivotTo(facing);prop.Parent=marker.Parent
        end
        actors[marker]={Model=visual,Clips=clips[id],Default=id=='Kael'and'HammerWork'or'Idle',Name=id=='Kael'and'HammerWork'or'Idle',Start=os.clock(),Event=0,Connection=connection,Prop=prop}
        marker:SetAttribute('BlenderNPCReady',true)
    end,debug.traceback)
    pending[marker]=nil
    if not ok then warn('[SKYBREAK NPC]',id,err)end
end
for _,o in workspace:GetDescendants()do task.spawn(register,o)end
workspace.DescendantAdded:Connect(function(o)task.spawn(register,o)end)
local elapsed=0
Run.PreSimulation:Connect(function(dt)
    elapsed+=dt;if elapsed<1/30 then return end;elapsed=0
    local now=os.clock()
    for marker,s in actors do
        if not marker.Parent then s.Connection:Disconnect();s.Model:Destroy();if s.Prop then s.Prop:Destroy()end;actors[marker]=nil;continue end
        local event=marker:GetAttribute('NPCTalkAt')or 0
        if event~=s.Event then s.Event=event;s.Name='Talk';s.Start=now end
        if s.Name=='Talk'and now-s.Start>=s.Clips.Talk.Duration then s.Name=s.Default;s.Start=now end
        local clip=s.Clips[s.Name]
        if not clip.Loop and now-s.Start>=clip.Duration then s.Start=now end
        Renderer.Pose(s.Model,clip,now-s.Start)
    end
end)
