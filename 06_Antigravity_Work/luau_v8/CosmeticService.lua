-- V8 Rigged EditableMesh Cosmetic Service (Zero legacy white MeshPart prefabs)
local A={}
function A.Boss(model,body)
    for _,o in ipairs(model:GetDescendants()) do
        if o:IsA("BasePart") then
            o.Anchored=true o.CanCollide=(o==body) o.CanTouch=false o.CanQuery=(o==body) o.Transparency=1
        end
    end
    if body then body.CanCollide=true body.CanQuery=true end
end
function A.Enemy(model,body,id)
    for _,o in ipairs(model:GetDescendants()) do
        if o:IsA("BasePart") then
            o.Anchored=true o.CanCollide=(o==body) o.CanTouch=false o.CanQuery=(o==body) o.Transparency=1
        end
    end
    if body then body.CanCollide=true body.CanQuery=true end
end
function A.Weapon(ch,hand,equipped)
    local blade=ch and ch:FindFirstChild("SkybornBlade")
    if blade then blade.Transparency=1 end
    A.Equip(ch,equipped)
end
function A.Guardian(ch)
    local root=ch and ch:FindFirstChild("HumanoidRootPart")
    local humanoid=ch and ch:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return false end
    for _,o in ipairs(ch:GetDescendants()) do
        if o:IsA("BasePart") and o.Name~="HumanoidRootPart" and not o:FindFirstAncestor("SkyGuardianVisual") and not o:FindFirstAncestor("ThunderStrikerVisual") and not o:FindFirstAncestor("ArcaneMageVisual") then
            o.Transparency=1
        end
        if o:IsA("Decal") then
            o.Transparency=1
        end
    end
    ch:SetAttribute("BlenderGuardian",true)
    ch:SetAttribute("SkybreakCosmeticsReady",true)
    return true
end
function A.Equip(ch,equipped)
    if not ch then return end
    local body=ch:FindFirstChild("SkyGuardianVisual")
    if body then
        for _,o in ipairs(body:GetDescendants()) do
            if o:IsA("MeshPart") and o.Name:find("_Weapon_") then
                o.Transparency=equipped and 0 or 1
            end
        end
    end
    local blade=ch:FindFirstChild("SkybornBlade")
    if blade then blade.Transparency=1 end
end
function A.BossSwing(model,windup)
    if model then
        model:SetAttribute("V5SwingAt",workspace:GetServerTimeNow())
    end
end
return A
