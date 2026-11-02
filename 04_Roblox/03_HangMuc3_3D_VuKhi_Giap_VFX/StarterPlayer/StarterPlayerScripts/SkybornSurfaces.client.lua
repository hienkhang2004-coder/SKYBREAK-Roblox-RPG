-- Local PBR images retain the original Blender material values without asset uploads.
local Asset = game:GetService('AssetService')
local Http = game:GetService('HttpService')
local cache = {}
local pending = {}
local hooked = setmetatable({}, { __mode = 'k' })

local function srgb(x)
    x = tonumber(x) or 0
    return x <= 0.0031308 and x * 12.92 or 1.055 * x ^ (1 / 2.4) - 0.055
end

local function image4(r, g, b, a)
    local ok, im = pcall(function()
        return Asset:CreateEditableImage({ Size = Vector2.one })
    end)
    if not ok or not im then
        return nil
    end
    local bytes = buffer.create(4)
    for i, n in ipairs({ r, g, b, a or 1 }) do
        buffer.writeu8(bytes, i - 1, math.clamp(math.floor((tonumber(n) or 0) * 255 + 0.5), 0, 255))
    end
    im:WritePixelsBuffer(Vector2.zero, Vector2.one, bytes)
    return im
end

local function ensureMaterialEntry(key, mat)
    if cache[key] ~= nil then
        return cache[key] or nil
    end
    if pending[key] then
        local thread = coroutine.running()
        table.insert(pending[key], thread)
        coroutine.yield()
        return cache[key] or nil
    end
    pending[key] = {}

    local entry = false
    local c = type(mat.color_linear) == 'table' and mat.color_linear or { 1, 1, 1, 1 }
    local col = image4(srgb(c[1]), srgb(c[2]), srgb(c[3]), c[4])
    local roughVal = tonumber(mat.roughness) or 0.5
    local metalVal = tonumber(mat.metalness) or 0
    local rough = col and image4(roughVal, roughVal, roughVal) or nil
    local metal = rough and image4(metalVal, metalVal, metalVal) or nil
    if col and rough and metal then
        local okSA, sa = pcall(function()
            return Asset:CreateSurfaceAppearanceAsync({
                ColorMap = Content.fromObject(col),
                RoughnessMap = Content.fromObject(rough),
                MetalnessMap = Content.fromObject(metal),
            })
        end)
        if okSA and sa then
            sa.Name = 'SkybornPBR'
            entry = { Surface = sa, Images = { col, rough, metal } }
        end
    end

    cache[key] = entry
    local waiters = pending[key]
    pending[key] = nil
    if waiters then
        for _, th in ipairs(waiters) do
            task.spawn(th)
        end
    end
    return entry or nil
end

local function apply(part)
    if not part or not part:IsA('MeshPart') or not part.Parent then
        return
    end
    local key = part:GetAttribute('SkybornMaterialJSON')
    if type(key) ~= 'string' or key == '' or part:FindFirstChild('SkybornPBR') then
        return
    end
    local okMat, mat = pcall(Http.JSONDecode, Http, key)
    if not okMat or type(mat) ~= 'table' or (tonumber(mat.emission_strength) or 0) > 0 then
        return
    end
    local entry = ensureMaterialEntry(key, mat)
    if entry and entry.Surface and part.Parent and not part:FindFirstChild('SkybornPBR') then
        entry.Surface:Clone().Parent = part
        part.Color = Color3.new(1, 1, 1)
        part.Material = Enum.Material.SmoothPlastic
        part:SetAttribute('SkybornPBRReady', true)
    end
end

local function hookMeshPart(o)
    if not o:IsA('MeshPart') or hooked[o] then
        return
    end
    hooked[o] = true
    o:GetAttributeChangedSignal('SkybornMaterialJSON'):Connect(function()
        task.spawn(apply, o)
    end)
    if o:GetAttribute('SkybornMaterialJSON') then
        task.spawn(apply, o)
    end
end

workspace.DescendantAdded:Connect(hookMeshPart)
for _, part in ipairs(workspace:GetDescendants()) do
    if part:IsA('MeshPart') then
        hookMeshPart(part)
    end
end
