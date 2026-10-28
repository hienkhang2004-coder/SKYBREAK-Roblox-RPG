-- Local PBR images retain the original Blender material values without asset uploads.
local Asset=game:GetService('AssetService')
local Http=game:GetService('HttpService')
local cache={}
local function srgb(x) return x<=.0031308 and x*12.92 or 1.055*x^(1/2.4)-.055 end
local function image4(r,g,b,a)
    local im=assert(Asset:CreateEditableImage({Size=Vector2.one}))
    local bytes=buffer.create(4)
    for i,n in ipairs({r,g,b,a or 1}) do buffer.writeu8(bytes,i-1,math.clamp(math.floor(n*255+.5),0,255)) end
    im:WritePixelsBuffer(Vector2.zero,Vector2.one,bytes);return im
end
local function apply(part)
    if not part:IsA('MeshPart') then return end
    local key=part:GetAttribute('SkybornMaterialJSON')
    if not key or part:FindFirstChild('SkybornPBR') then return end
    local mat=Http:JSONDecode(key)
    if mat.emission_strength>0 then return end
    if not cache[key] then
        local c=mat.color_linear
        local col=image4(srgb(c[1]),srgb(c[2]),srgb(c[3]),c[4])
        local rough=image4(mat.roughness,mat.roughness,mat.roughness)
        local metal=image4(mat.metalness,mat.metalness,mat.metalness)
        local sa=Asset:CreateSurfaceAppearanceAsync({ColorMap=Content.fromObject(col),RoughnessMap=Content.fromObject(rough),MetalnessMap=Content.fromObject(metal)})
        sa.Name='SkybornPBR';cache[key]={Surface=sa,Images={col,rough,metal}}
    end
    if part.Parent then
        cache[key].Surface:Clone().Parent=part
        part.Color=Color3.new(1,1,1);part.Material=Enum.Material.SmoothPlastic
        part:SetAttribute('SkybornPBRReady',true)
    end
end
workspace.DescendantAdded:Connect(function(o)
    if o:IsA('MeshPart') then
        o:GetAttributeChangedSignal('SkybornMaterialJSON'):Connect(function() task.spawn(apply,o) end)
        task.spawn(apply,o)
    end
end)
for _,part in workspace:GetDescendants() do task.spawn(apply,part) end
