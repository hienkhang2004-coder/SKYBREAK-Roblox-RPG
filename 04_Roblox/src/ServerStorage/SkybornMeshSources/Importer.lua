-- Native import of evaluated Blender meshes. Staged only, never replaces a live prefab.
local Asset=game:GetService('AssetService')
local M={}
local function cf(a) return CFrame.new(table.unpack(a)) end
local function v(a) return Vector3.new(a[1],a[2],a[3]) end
local function baked(editable)
    local status,content=Asset:CreateDataModelContentAsync(Content.fromObject(editable))
    assert(status==Enum.CreateContentResult.Success,tostring(status))
    return content
end
local function srgb(x) return x<=.0031308 and x*12.92 or 1.055*x^(1/2.4)-.055 end
local function image4(r,g,b,a)
    local im=Asset:CreateEditableImage({Size=Vector2.one})
    local bytes=buffer.create(4)
    for i,n in ipairs({r,g,b,a or 1}) do buffer.writeu8(bytes,i-1,math.clamp(math.floor(n*255+.5),0,255)) end
    im:WritePixelsBuffer(Vector2.zero,Vector2.one,bytes)
    return im
end
function M.Begin(data)
    local storage=game:GetService('ServerStorage')
    local folder=storage:FindFirstChild('SkybornStaging')
    if not folder then folder=Instance.new('Folder');folder.Name='SkybornStaging';folder.Parent=storage end
    local name=data.gender..'_'..data.preset
    assert(not folder:FindFirstChild(name),'Staging model already exists: '..name)
    local model=Instance.new('Model');model.Name=name
    model:SetAttribute('SourceSHA256',data.source_sha256)
    model:SetAttribute('Gender',data.gender);model:SetAttribute('OutfitStage',data.preset)
    model:SetAttribute('ImportStatus','Building');model:SetAttribute('SourceHeight',data.height_m)
    local root=Instance.new('Part');root.Name='RootPart';root.Size=Vector3.one*.1
    root.Transparency=1;root.Anchored=true;root.CanCollide=false;root.CanQuery=false;root.CanTouch=false
    root.Parent=model;model.PrimaryPart=root;model.WorldPivot=CFrame.identity
    local nodes={}
    for _,b in data.bones do
        local bone=Instance.new('Bone');bone.Name=b.name;bone.CFrame=cf(b['local'])
        bone.Parent=b.parent and assert(nodes[b.parent],b.parent) or root;nodes[b.name]=bone
    end
    model.Parent=folder
    return name
end
function M.Mesh(name,data,bones)
    local model=assert(game.ServerStorage.SkybornStaging:FindFirstChild(name),name)
    assert(not model:FindFirstChild(data.name),'Duplicate mesh '..data.name)
    local low=Vector3.new(math.huge,math.huge,math.huge);local high=-low
    for _,xyz in data.vertices do local p=v(xyz);low=low:Min(p);high=high:Max(p) end
    local center=(low+high)/2
    local e=assert(Asset:CreateEditableMesh(),'EditableMesh allocation failed')
    local boneids={}
    for _,b in bones do
        boneids[b.name]=e:AddBone({Name=b.name,CFrame=CFrame.new(-center)*cf(b.bind_world),Virtual=false,ParentId=b.parent and boneids[b.parent] or nil})
    end
    local ids={}
    for i,xyz in data.vertices do
        local id=e:AddVertex(v(xyz)-center);ids[i]=id
        local joints,weights={},{}
        for _,pair in data.weights[i] do table.insert(joints,assert(boneids[pair[1]]));table.insert(weights,pair[2]) end
        e:SetVertexBones(id,joints);e:SetVertexBoneWeights(id,weights)
        if i%1000==0 then task.wait() end
    end
    local uv=e:AddUV(Vector2.new(.5,.5))
    local normals={}
    for i,t in data.triangles do
        local face=e:AddTriangle(ids[t[1]+1],ids[t[2]+1],ids[t[3]+1])
        local ns={}
        for j,xyz in data.normals[i] do
            local key=table.concat(xyz,',');local id=normals[key]
            if not id then id=e:AddNormal(v(xyz));normals[key]=id end;ns[j]=id
        end
        e:SetFaceNormals(face,ns);e:SetFaceUVs(face,{uv,uv,uv})
        if i%1000==0 then task.wait() end
    end
    local content=baked(e)
    local part=Asset:CreateMeshPartAsync(content,{CollisionFidelity=Enum.CollisionFidelity.Box})
    part.Name=data.name;part.CFrame=CFrame.new(center);part.Anchored=true
    part.CanCollide=false;part.CanTouch=false;part.CanQuery=false;part.Massless=true
    part:SetAttribute('SourceVertices',#data.vertices);part:SetAttribute('SourceTriangles',#data.triangles)
    part:SetAttribute('EquipmentRole',data.role);part:SetAttribute('BlenderMaterial',data.material.name)
    part:SetAttribute('SourceParts',table.concat(data.source_parts,';'))
    local mat=data.material;local color=mat.color_linear
    part:SetAttribute('SkybornMaterialJSON',game.HttpService:JSONEncode(mat))
    if mat.emission_strength>0 then
        local em=mat.emission_linear
        part.Color=Color3.new(srgb(em[1]),srgb(em[2]),srgb(em[3]));part.Material=Enum.Material.Neon
    elseif game:GetService('RunService'):IsRunning() then
        -- Persistent input values replicate; each client builds its local editable PBR maps.
        -- Map Content setters themselves are Studio-plugin-only.
        part.Color=Color3.new(srgb(color[1]),srgb(color[2]),srgb(color[3]))
        part.Material=mat.metalness>.5 and Enum.Material.Metal or Enum.Material.SmoothPlastic
    else
        M.Materials=M.Materials or {}
        local key=game:GetService('HttpService'):JSONEncode(mat)
        if not M.Materials[key] then
            local col=image4(srgb(color[1]),srgb(color[2]),srgb(color[3]),color[4])
            local rough=image4(mat.roughness,mat.roughness,mat.roughness)
            local metal=image4(mat.metalness,mat.metalness,mat.metalness)
            local sa=Asset:CreateSurfaceAppearanceAsync({ColorMap=Content.fromObject(col),RoughnessMap=Content.fromObject(rough),MetalnessMap=Content.fromObject(metal)})
            sa.ColorMapContent=baked(col);sa.RoughnessMapContent=baked(rough);sa.MetalnessMapContent=baked(metal)
            col:Destroy();rough:Destroy();metal:Destroy();M.Materials[key]=sa
        end
        M.Materials[key]:Clone().Parent=part;part.Color=Color3.new(1,1,1);part.Material=Enum.Material.SmoothPlastic
    end
    part.Transparency=1-color[4]*(mat.alpha or 1)
    part.Parent=model;e:Destroy()
    return {name=part.Name,skinned=part.HasSkinnedMesh,vertices=#ids,triangles=#data.triangles,size={part.Size.X,part.Size.Y,part.Size.Z},content=tostring(part.MeshContent)}
end
function M.Finish(name,expected)
    local model=assert(game.ServerStorage.SkybornStaging:FindFirstChild(name))
    local meshes,bones,vertices,triangles=0,0,0,0
    for _,o in model:GetDescendants() do
        if o:IsA('Bone') then bones+=1 end
        if o:IsA('MeshPart') then
            assert(o.HasSkinnedMesh,o.Name);meshes+=1;vertices+=o:GetAttribute('SourceVertices');triangles+=o:GetAttribute('SourceTriangles')
            local w=Instance.new('WeldConstraint');w.Part0=model.PrimaryPart;w.Part1=o;w.Parent=o
        end
    end
    assert(meshes==expected and bones==19,'Incomplete imported model')
    model:SetAttribute('ImportStatus','ImportedPendingVisualPersistenceQA')
    return {name=name,meshes=meshes,bones=bones,vertices=vertices,triangles=triangles}
end
return M
