-- Restore original Blender geometry in the running DataModel.
-- Edit-time opaque Content is ephemeral and does not survive a Play boundary.
local M={Models={}}
function M.Build(name)
    if M.Models[name] and M.Models[name].Parent then return M.Models[name] end
    local storage=game:GetService('ServerStorage')
    local sources=storage:WaitForChild('SkybornMeshSources')
    local importer=require(sources.Importer)
    local source=assert(sources:FindFirstChild(name),'Missing Blender geometry source: '..name)
    local header=require(source.Header)
    local staging=storage:FindFirstChild('SkybornStaging')
    local old=staging and staging:FindFirstChild(name)
    if old then old:Destroy() end
    assert(importer.Begin(header)==name,'Preset identity mismatch')
    local chunks={}
    for _,child in source:GetChildren() do if child.Name~='Header' then table.insert(chunks,child) end end
    table.sort(chunks,function(a,b) return a.Name<b.Name end)
    for _,module in chunks do importer.Mesh(name,require(module),header.bones) end
    importer.Finish(name,#chunks)
    M.Models[name]=staging[name]
    return M.Models[name]
end
function M.Start()
    if game.ReplicatedStorage:FindFirstChild('DelegatedV5Sources') then return end
    local storage=game:GetService('ServerStorage')
    local restored=M.Build('Male_SkyGuardian')
    local current=storage.VisualPrefabs:FindFirstChild('BlenderGuardian')
    if current then current:Destroy() end
    local model=restored:Clone();model.Name='BlenderGuardian';model.Parent=storage.VisualPrefabs
    storage:SetAttribute('SkybornNativeReady',true)
end
return M
