-- Transient Play Mode QA only. Insert as a LocalScript in PlayerScripts.
local Players=game:GetService("Players")
local Run=game:GetService("RunService")
local Http=game:GetService("HttpService")
local p=Players.LocalPlayer
local animator=script.Parent:WaitForChild("GuardianAnimator")
while not animator:GetAttribute("PlaybackInitialized") do task.wait(.1) end
require(script.Parent.UI.Interface).Show("HUD")
local report={} local elapsed=0 local bound=nil local bones={} local shieldLegPoses={}
local connection=Run.PostSimulation:Connect(function(dt)
    local ch=p.Character
    if ch~=bound then
        bound=ch bones={}
    end
    local visual=ch and ch:FindFirstChild("SkyGuardianVisual")
    if visual and #bones==0 then
        for _,o in ipairs(visual:GetDescendants()) do if o:IsA("Bone") then table.insert(bones,o) end end
        table.sort(bones,function(a,b) return a.Name<b.Name end)
    end
    local name=ch and ch:GetAttribute("GuardianCurrentClip")
    if visual and name and #bones>0 then
        local row=report[name] or {Samples=0,Poses={}}
        row.Samples+=1 local pose={}
        for _,b in ipairs(bones) do table.insert(pose,tostring(b.Transform)) end
        row.Poses[table.concat(pose,"|")]=true report[name]=row
        if name=="ShieldLoop" and ch.Humanoid.MoveDirection.Magnitude>.1 then
            for _,b in ipairs(bones) do if b.Name=="RightUpperLeg" then shieldLegPoses[tostring(b.Transform)]=true end end
        end
    end
    elapsed+=dt
    if elapsed>.1 then
        elapsed=0 local result={}
        for name,row in pairs(report) do
            local count=0 for _ in pairs(row.Poses) do count+=1 end
            result[name]={Samples=row.Samples,UniquePoses=count}
        end
        script:SetAttribute("Report",Http:JSONEncode(result))
        local count=0 for _ in pairs(shieldLegPoses) do count+=1 end
        script:SetAttribute("ShieldRunPoses",count)
    end
end)
task.delay(120,function() connection:Disconnect() end)
-- Exercise the physical Humanoid, rather than invoking animation names directly.
task.wait(1)
local h=p.Character:WaitForChild("Humanoid")
local move=Run.PreSimulation:Connect(function() h:Move(Vector3.new(1,0,0),false) end)
task.wait(.6) h:ChangeState(Enum.HumanoidStateType.Jumping)
task.wait(1) move:Disconnect() h:Move(Vector3.zero,false)
script:SetAttribute("MovementFinished",true)
local deadline=os.clock()+35
while (p.Character:GetAttribute("GuardianShieldUntil") or 0)<=workspace:GetServerTimeNow() and os.clock()<deadline do task.wait(.1) end
if os.clock()<deadline then
    task.wait(.7)
    local shieldMove=Run.PreSimulation:Connect(function() h:Move(Vector3.new(0,0,-1),false) end)
    task.wait(1.2) shieldMove:Disconnect() h:Move(Vector3.zero,false)
end
