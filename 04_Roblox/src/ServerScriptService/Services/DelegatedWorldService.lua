local M={}

function M.Build(W)
    for _,name in {'SkyHub','GoldenSky','GrandSkyIslands_Collision','VerdantCrown','EmberforgeWastes','AbyssalTides','ChronosBastion','VeilsEnd'} do
        local old=workspace:FindFirstChild(name)
        if old then old:Destroy() end
    end
    local hub=Instance.new('Model');hub.Name='SkyHub';hub.Parent=workspace
    local sky=Instance.new('Model');sky.Name='GoldenSky';sky.Parent=workspace;hub:SetAttribute('WorldVersion',5)
    W.Hub=hub;W.Sky=sky;W.Interactions={}
    require(script.Parent.GoldenSkyCollision)(sky)
    for _,name in {'ActiveEnemies','ActiveBosses','SpawnPoints'} do
        if not workspace:FindFirstChild(name) then
            local f=Instance.new('Folder');f.Name=name;f.Parent=workspace
        end
    end
    local spawn=Instance.new('SpawnLocation');spawn.Name='SkybornSpawn';spawn.Size=Vector3.new(8,1,8);spawn.Position=Vector3.new(-92,36.6,153)
    spawn.Anchored=true;spawn.Transparency=1;spawn.CanCollide=false;spawn.Neutral=true;spawn.Duration=2;spawn.Parent=hub;W.Spawn=spawn
    local locations={
        Lyra={-78,39,145},Kael={-68,39,145},FrozenPortal={16,49,-199},ReturnHub={19,43,20},
        Station1={-18,43,17},Station2={0,43,23},Station3={18,43,17},
        Citizen1={-22,43,-4},Citizen2={0,43,-26},Citizen3={22,43,-4},
        Switch1={-24,43,-25},Switch2={24,43,-25},ArenaGate={0,43,-42},LeaveArena={29,49,-90},
    }
    local labels={
        Lyra='Lyra • Chỉ Huy Skyborn (Nhiệm Vụ)',
        Kael='Kael • Thợ Rèn Thần Khí (Forge)',
        FrozenPortal='Frozen Cyber • Sea 2',
        ReturnHub='Về Sky Hub',
        ArenaGate='Aureon • Vào / bắt đầu trận',
        LeaveArena='Rời đấu trường'
    }
    for id,pos in locations do
        local marker=W.Interactable((id=='Lyra' or id=='Kael') and hub or sky,id,Vector3.new(table.unpack(pos)),labels[id]or id)
        marker.Transparency=1
        if id=='Lyra' or id=='Kael' then
            for _,ch in ipairs(marker:GetChildren()) do
                if ch:IsA("BillboardGui") or ch:IsA("ProximityPrompt") then
                    ch:Destroy()
                end
            end
        end
    end
    local floors={sky.GoldenSky_Collision}

    local solid3D = nil
    if script.Parent:FindFirstChild('Solid3DWorldColliders') then
        local ok, mod = pcall(require, script.Parent.Solid3DWorldColliders)
        if ok and mod then
            solid3D = mod
            pcall(mod.Build)
        end
    end

    local islandColFolder = workspace:FindFirstChild("GrandSkyIslands_Collision")
    if not islandColFolder then
        islandColFolder = Instance.new("Folder")
        islandColFolder.Name = "GrandSkyIslands_Collision"
        islandColFolder.Parent = workspace
    end
    table.insert(floors, islandColFolder)

    if game.ReplicatedStorage.DelegatedV5Sources:FindFirstChild('FrozenCyber') then
        local origin=require(game.ReplicatedStorage.Shared.RealmConfig).FrozenCyber.Origin
        local oldF=workspace:FindFirstChild('FrozenCyber')
        if oldF then oldF:Destroy() end
        local frozen=Instance.new('Model');frozen.Name='FrozenCyber';frozen.Parent=workspace
        local collision=require(script.Parent.FrozenCyberCollision)(frozen)
        collision=collision or frozen.FrozenCyber_Collision
        for _,o in collision:GetDescendants() do if o:IsA('BasePart')then o.CFrame=CFrame.new(origin)*o.CFrame end end
        table.insert(floors,collision)
        local frHub=W.Interactable(frozen,'FrozenReturnHub',origin+Vector3.new(-101,43,150),'Về Golden Sky')
        if frHub then frHub.Transparency=1 end
        local shPortal=W.Interactable(frozen,'ShadowPortal',origin+Vector3.new(120,68,-130),'Shadow Realm • Sea 3')
        if shPortal then shPortal.Transparency=1 end
    end
    if game.ReplicatedStorage.DelegatedV5Sources:FindFirstChild('ShadowRealm')then
        local origin=require(game.ReplicatedStorage.Shared.RealmConfig).ShadowRealm.Origin
        local oldS=workspace:FindFirstChild('ShadowRealm')
        if oldS then oldS:Destroy() end
        local shadow=Instance.new('Model');shadow.Name='ShadowRealm';shadow.Parent=workspace
        require(script.Parent.ShadowRealmCollision)(shadow)
        local collision=shadow.ShadowRealm_Collision
        for _,o in collision:GetDescendants()do if o:IsA('BasePart')then o.CFrame=CFrame.new(origin)*o.CFrame end end
        table.insert(floors,collision)
        local shRet=W.Interactable(shadow,'ShadowReturnHub',origin+Vector3.new(-158,51,90),'Về Golden Sky')
        if shRet then shRet.Transparency=1 end
    end
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances=floors
    function W.RaycastGround(pos, refFloorY)
        local originY = (refFloorY or pos.Y) + 32
        return workspace:Raycast(Vector3.new(pos.X, originY, pos.Z),Vector3.new(0,-85,0),params)
    end
    function W.GroundY(pos, refFloorY)
        local hit = W.RaycastGround(pos, refFloorY)
        if hit then
            return hit.Position.Y
        end
        return refFloorY or (pos.Y - 2.5)
    end
    if solid3D and solid3D.SnapToOpenGround then
        W.SnapToOpenGround = solid3D.SnapToOpenGround
    else
        function W.SnapToOpenGround(pos, refFloorY, heightOffset)
            local gy = W.GroundY(pos, refFloorY)
            return Vector3.new(pos.X, gy + (heightOffset or 0), pos.Z), gy
        end
    end
    workspace:SetAttribute('WorldArtVersion',8)
end
return M
