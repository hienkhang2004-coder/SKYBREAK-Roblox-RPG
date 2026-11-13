-- Build original geometry once on the server, outside client EditableMesh caps (Dev/Studio only on live).
local RS=game:GetService('ReplicatedStorage')
local RunService=game:GetService('RunService')
local SSS=game:GetService('ServerScriptService')
local Services=SSS:WaitForChild('Services')
local DevGate=require(Services:WaitForChild('DevGate'))
local RemoteGuard=require(Services:WaitForChild('RemoteGuard'))
local Sources=RS:WaitForChild('DelegatedV5Sources')
local Renderer=require(RS:WaitForChild('DelegatedV5Renderer'))
local library=Instance.new('Folder');library.Name='SKYBREAK_NativeTemplates';library.Parent=RS
local remote=Instance.new('RemoteFunction');remote.Name='SKYBREAK_BuildNative'
local requests={}
remote.OnServerInvoke=function(player,name)
    if not DevGate.IsAllowed(player) then return {ok=false,error='Disabled on live server'}end
    if type(name)~='string'or #name==0 or #name>64 then return {ok=false,error='Invalid asset name'}end
    local cached=library:FindFirstChild(name)
    if cached then return {ok=true,descendants=#cached:GetDescendants()}end
    if not RemoteGuard.Allow(player, 'Native') then return {ok=false,error='Rate limit exceeded'}end
    local vspec=Renderer.VirtualSplitSpecs and Renderer.VirtualSplitSpecs[name]
    local source=Sources:FindFirstChild((vspec and vspec.source) or name)
    if not source or not source:IsA('Folder')or not source:FindFirstChild('Header')then return {ok=false,error='Unknown native asset'}end
    requests[player]=(requests[player]or 0)+1
    if requests[player]>2 then requests[player]-=1;return {ok=false,error='Too many concurrent native requests'}end
    local ok,descCount=xpcall(function()
        local template=Renderer.Build(name)
        local cnt=#template:GetDescendants()
        if RunService:IsStudio() then
            if template.Parent~=library then template.Parent=library end
        else
            template:Destroy()
        end
        return cnt
    end,debug.traceback)
    requests[player]=math.max(0,(requests[player]or 1)-1)
    if not ok then warn('[SKYBREAK Native]',name,descCount);return {ok=false,error='Native asset build failed'}end
    return {ok=true,descendants=descCount}
end
game:GetService('Players').PlayerRemoving:Connect(function(player)requests[player]=nil end)
remote.Parent=RS
