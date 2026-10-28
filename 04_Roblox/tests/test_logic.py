"""Runs production Luau modules against small engine stubs; not a Studio playtest."""
from pathlib import Path
import subprocess
import os
import tempfile

ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/'src'
config=(SRC/'ReplicatedStorage/Shared/Config.lua').read_text(encoding='utf-8')
game_service=(SRC/'ServerScriptService/Services/GameService.lua').read_text(encoding='utf-8')
prefix=r'''
local V={} local mt={}
function V.new(x,y,z) return setmetatable({X=x,Y=y,Z=z},mt) end
mt.__sub=function(a,b) return V.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
mt.__add=function(a,b) return V.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
mt.__mul=function(a,b) return V.new(a.X*b,a.Y*b,a.Z*b) end
mt.__index=function(a,k)
 if k=="Magnitude" then return math.sqrt(a.X^2+a.Y^2+a.Z^2) end
 if k=="Unit" then return a*(1/a.Magnitude) end
 if k=="Dot" then return function(s,b) return s.X*b.X+s.Y*b.Y+s.Z*b.Z end end
end
local Vector3=V
local now=100
local os={clock=function() return now end}
local task={spawn=function() end,delay=function() end}
local C=(function()
'''
middle=r'''
end)()
local profiles={}
local D={Get=function(p) return profiles[p] end}
local W={}
local sent={}
local event={FireClient=function(_,p,payload) table.insert(sent,payload) end,FireAllClients=function() end}
local remotes={StateUpdate=event,CombatFX=event}
local players={GetPlayers=function() return {} end}
local game={ReplicatedStorage={Shared={Config="config"},Remotes=remotes},GetService=function(_,key) return key=="Players" and players or {} end}
local script={Parent={PlayerDataService="data",WorldService="world"}}
local require=function(key) if key=="config" then return C elseif key=="data" then return D else return W end end
local G=(function()
'''
tests=r'''
end)()
local checks=0
local function check(condition,label) assert(condition,label) checks+=1 print("PASS",label) end
local function profile()
 return {Level=1,XP=0,Gold=0,QuestIndex=1,Accepted=true,Progress={},CompletedQuests={},Inventory={starter_sword=1},ClassId="SkyGuardian",Weapon="starter_sword",FirstClearBosses={},UnlockedWorlds={GoldenSky=true}}
end
local p={} profiles[p]=profile()
G.QuestEvent(p,"Kill","AureonSentinel")
check(profiles[p].QuestIndex==1,"Boss kill cannot skip Q01")
for index,q in ipairs(C.Quests) do
 check(profiles[p].Level>=q.Level,"Level gate reachable for "..q.Id)
 profiles[p].Accepted=true
 for _,objective in ipairs(q.Objectives) do
  for i=1,objective.Count do G.QuestEvent(p,objective.Kind,objective.Target) end
 end
 check(profiles[p].QuestIndex==index+1,"Completes "..q.Id)
 local gold=profiles[p].Gold
 for _,objective in ipairs(q.Objectives) do G.QuestEvent(p,objective.Kind,objective.Target) end
 check(profiles[p].Gold==gold,"No duplicate reward "..q.Id)
end
check(profiles[p].Level==10 and profiles[p].XP==0,"MVP level cap")
check(profiles[p].Inventory.CoreOfLight==1 and profiles[p].Inventory.DawnbringerBlueprint==1,"First clear items")
check(profiles[p].UnlockedWorlds.FrozenCyber,"Frozen Cyber unlock")
G.Reward(p,1000000,0)
check(profiles[p].Level==10 and profiles[p].XP==0,"Huge XP cannot exceed level cap")
G.Runtime[p]={Requests={}}
check(G.Rate(p,"test",.3),"Initial rate-limited action allowed")
check(not G.Rate(p,"test",.3),"Immediate spam rejected")
now+=1 check(G.Rate(p,"test",.3),"Rate limit recovers")
local before=profiles[p].Gold
G.Action(p,"GrantGold") G.Action(p,{damage=math.huge}) G.Interact(p,string.rep("a",50))
check(profiles[p].Gold==before,"Invalid actions cannot grant Gold")
local r={Position=Vector3.new(0,8,-430)} local h={Health=100}
p.Character={FindFirstChild=function() return r end,FindFirstChildOfClass=function() return h end}
G.Runtime[p].Energy=0
local boss={Id="AureonSentinel",HP=2200,MaxHP=2200,Alive=true,Model={Parent=true},Config=C.Enemies.AureonSentinel,Contributors={},Body={Position=Vector3.new(0,10,-440)},Phase=1,Shield=false,Party={[p]=true},Break=0,ImmuneUntil=0,StunnedUntil=0}
G.Boss=boss
local pylons=0
G.SpawnEnemy=function() pylons+=1 return {} end
G.Hit(p,boss,1e6,10)
check(boss.Phase==2 and boss.Shield and pylons==2,"Boss phase 2 clamps HP and spawns exactly two pylons")
local hp=boss.HP G.Hit(p,boss,1000,10)
check(boss.HP==hp and pylons==2,"Shield blocks damage and repeat pylon spawn")
boss.Shield=false G.Hit(p,boss,1e6,10)
check(boss.Phase==3 and boss.HP==math.floor(boss.MaxHP*.3),"Boss enters phase 3 without skipping")
local other={} profiles[other]=profile() other.Character=p.Character G.Runtime[other]={Energy=0}
hp=boss.HP G.Hit(other,boss,1000,10)
check(boss.HP==hp,"Nonparty player cannot damage boss")
r.Position=Vector3.new(0,8,0) G.Hit(p,boss,1000,10)
check(boss.HP==hp,"Party member outside arena cannot damage boss")
local cold={} profiles[cold]=profile() profiles[cold].Accepted=false
G.QuestEvent(cold,"Kill","TrainingDrone")
check(next(profiles[cold].Progress)==nil,"Unaccepted quest cannot progress")
print("TOTAL",checks,"PASS")
'''
target=Path(tempfile.gettempdir())/'skybreak_logic_tests.luau'
target.write_text(prefix+config+middle+game_service+tests,encoding='utf-8')
result=subprocess.run([os.environ.get('LUAU_CLI','luau'),str(target)],capture_output=True,text=True,encoding='utf-8')
print(result.stdout)
print(result.stderr)
raise SystemExit(result.returncode)
