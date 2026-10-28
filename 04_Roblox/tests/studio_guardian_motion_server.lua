-- Transient Play Mode QA only; never placed under src or published.
local G=require(game.ServerScriptService.Services.GameService)
local D=require(game.ServerScriptService.Services.PlayerDataService)
local Http=game:GetService("HttpService")
local p=game.Players:GetPlayers()[1]
local profile=D.Get(p) assert(profile,"Profile must finish loading before QA")
profile.Level=5 profile.Weapon="starter_sword"
local rt=G.Runtime[p] rt.InvincibleUntil=0 G.Sync(p)
task.wait(3)
local results={Actions={}}
for _,action in ipairs({"Attack","Attack","Attack","Heavy","SkySlash","Dodge","Dash","GuardianShield"}) do
    local r=p.Character.HumanoidRootPart local before=r.Position
    local previousCooldown=rt.Cooldowns[action]
    G.Action(p,action)
    local accepted=rt.Cooldowns[action]~=previousCooldown
    if action=="GuardianShield" then
        results.ShieldActive=(p.Character:GetAttribute("GuardianShieldUntil") or 0)>workspace:GetServerTimeNow()
    end
    task.wait(action=="GuardianShield" and 5.8 or (action=="Attack" and 1.05 or 1.4))
    table.insert(results.Actions,{Action=action,Accepted=accepted,Combo=rt.Combo,Travel=(r.Position-before).Magnitude})
end
results.ShieldExpired=(p.Character:GetAttribute("GuardianShieldUntil") or 0)<=workspace:GetServerTimeNow()
local health=p.Character.Humanoid.Health G.PlayerDamage(p,20)
results.DamageApplied=p.Character.Humanoid.Health<health
task.wait(1)
-- A temporary isolated platform tests actual movement sweeps against wall/edge.
local fixture=Instance.new("Folder") fixture.Name="GuardianEvadeQAFixture" fixture.Parent=workspace
local function part(name,size,pos)
    local o=Instance.new("Part") o.Name=name o.Size=size o.Position=pos o.Anchored=true o.Parent=fixture return o
end
part("Floor",Vector3.new(40,1,40),Vector3.new(140,20,120))
local wall=part("Wall",Vector3.new(30,12,1),Vector3.new(140,25,112))
local r=p.Character.HumanoidRootPart
G.Teleport(p,Vector3.new(140,24,120)) r.CFrame=CFrame.lookAt(r.Position,r.Position+Vector3.new(0,0,-1))
task.wait(.3) rt.Stamina=100 rt.EvadeUntil=0 rt.ActionUntil=0 rt.Cooldowns.Dash=0
G.Action(p,"Dash") task.wait(.8)
results.Wall={StoppedBeforeWall=r.Position.Z>114,PositionZ=r.Position.Z}
wall:Destroy()
G.Teleport(p,Vector3.new(140,24,104)) r.CFrame=CFrame.lookAt(r.Position,r.Position+Vector3.new(0,0,-1))
task.wait(.3) rt.Stamina=100 rt.EvadeUntil=0 rt.ActionUntil=0 rt.Cooldowns.Dash=0
G.Action(p,"Dash") task.wait(.8)
results.Edge={StoppedOnFloor=r.Position.Z>=100,PositionZ=r.Position.Z}
G.Teleport(p,Vector3.new(0,9,0)) fixture:Destroy()
p.Character.Humanoid.Health=0 task.wait(2)
script:SetAttribute("Report",Http:JSONEncode(results))
