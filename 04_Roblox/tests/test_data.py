from pathlib import Path
import subprocess
import os
import tempfile
ROOT=Path(__file__).resolve().parents[1]
SRC=ROOT/'src'
config=(SRC/'ReplicatedStorage/Shared/Config.lua').read_text(encoding='utf-8')
data=(SRC/'ServerScriptService/Services/PlayerDataService.lua').read_text(encoding='utf-8')
prefix='''
local Vector3={new=function(x,y,z) return {X=x,Y=y,Z=z} end}
local C=(function()
'''
middle=r'''
end)()
local now=1000 local os={time=function() return now end}
local function copy(v) if type(v)~="table" then return v end local c={} for k,x in pairs(v) do c[k]=copy(x) end return c end
local task={wait=function(seconds) now+=seconds end,spawn=function() end}
local warn=function() end
local store={Rows={},Fails=0,Calls=0}
function store:UpdateAsync(key,fn)
 self.Calls+=1
 if self.Fails>0 then self.Fails-=1 error("simulated outage") end
 local record=fn(copy(self.Rows[key]))
 if record==nil then return nil end
 self.Rows[key]=copy(record) return copy(record)
end
local Players={}
local services={Players=Players,DataStoreService={GetDataStore=function() return store end},
 HttpService={GenerateGUID=function() return "test-guid" end},RunService={IsStudio=function() return false end}}
local game={JobId="test-job",ReplicatedStorage={Shared={Config="config"}},GetService=function(_,name) return services[name] end}
local require=function() return C end
local D=(function()
'''
tests=r'''
end)()
local count=0
local function check(condition,label) assert(condition,label) count+=1 print("PASS",label) end
local function player(id) return {UserId=id,Parent=Players,Kick=function(self,message) self.Kicked=message end} end
local p=player(1) local profile=D.Load(p)
check(profile and profile.Level==1 and profile.Inventory.starter_sword==1,"New profile created under session lock")
check(store.Rows.u_1.Owner=="test-job:test-guid","Load acquires ownership")
profile.Gold=99 check(store.Rows.u_1.Data.Gold==0,"Session mutation does not mutate persisted snapshot")
check(D.Save(p,false) and store.Rows.u_1.Data.Gold==99,"Save persists profile")
now+=45 check(D.Save(p,false) and store.Rows.u_1.Expires==now+C.LeaseSeconds,"Autosave renews lease")
D.Release(p)
check(D.Sessions[p]==nil and store.Rows.u_1.Owner==nil,"Release saves and unlocks")
local again=player(1) local loaded=D.Load(again)
check(loaded.Gold==99,"Rejoin restores saved Gold")
store.Rows.u_1.Owner="foreign-server"
check(not D.Save(again,false) and again.Kicked~=nil,"Ownership loss fails closed")
check(store.Rows.u_1.Owner=="foreign-server" and store.Rows.u_1.Data.Gold==99,"Stale server cannot overwrite foreign owner")
local blocked=player(1) check(D.Load(blocked)==nil and blocked.Kicked~=nil,"Concurrent live lease blocks load")
now+=C.LeaseSeconds+1
local recovered=player(1) check(D.Load(recovered).Gold==99,"Expired lease recovers without resetting data")
now+=C.LeaseSeconds+1
check(D.Get(recovered)==nil and recovered.Kicked~=nil,"Expired local lease blocks gameplay")
local offline=player(2) store.Fails=3
check(D.Load(offline)==nil and offline.Kicked~=nil and store.Rows.u_2==nil,"Load outage cannot write default profile")
local corrupt=player(3) store.Rows.u_3={Data={SchemaVersion=999},Owner=nil,Expires=0}
check(D.Load(corrupt)==nil and store.Rows.u_3.Data.SchemaVersion==999,"Unknown schema preserved and rejected")
local retryPlayer=player(4) store.Fails=2
check(D.Load(retryPlayer)~=nil,"Transient load failure recovers on third attempt")
local failedSave=player(5) D.Load(failedSave).Gold=123 store.Fails=3
check(not D.Save(failedSave,false) and store.Rows.u_5.Data.Gold==0,"Failed save does not claim persisted state")
check(D.Sessions[failedSave].SaveStatus=="Lỗi lưu — đang thử lại","Failed save exposed to HUD")
check(D.Save(failedSave,false) and store.Rows.u_5.Data.Gold==123,"Subsequent save recovers")
print("TOTAL",count,"PASS")
'''
target=Path(tempfile.gettempdir())/'skybreak_data_tests.luau'
target.write_text(prefix+config+middle+data+tests,encoding='utf-8')
result=subprocess.run([os.environ.get('LUAU_CLI','luau'),str(target)],capture_output=True,text=True,encoding='utf-8')
print(result.stdout)
print(result.stderr)
raise SystemExit(result.returncode)
