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
    local keepServerVisible = (id == "EnergyPylon")
    for _,o in ipairs(model:GetDescendants()) do
        if o:IsA("BasePart") then
            o.Anchored=true o.CanCollide=(o==body) o.CanTouch=false o.CanQuery=(o==body)
            if not keepServerVisible and o.Name ~= "DummyFloorRing" then
                o.Transparency=1
            end
        end
    end
    if body then body.CanCollide=true body.CanQuery=true end
end
function A.Weapon(ch,hand,equipped)
    local blade=ch and ch:FindFirstChild("SkybornBlade")
    if blade then blade.Transparency=1 end
    A.Equip(ch,equipped)
end
local HIDDEN_SERVER_PARTS={HumanoidRootPart=true,SkybornBlade=true,GuardianBreastplate=true,GuardianCrest=true,CrimsonCape=true}
function A.Guardian(ch)
    local root=ch and ch:FindFirstChild("HumanoidRootPart")
    local humanoid=ch and ch:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return false end
    local isLocalUnpublished=(game.PlaceId==0)
    local head=ch:FindFirstChild("Head")
    if head and head:IsA("BasePart") and isLocalUnpublished then
        local sm=head:FindFirstChildOfClass("SpecialMesh")
        if sm and sm.MeshType==Enum.MeshType.FileMesh then
            sm.MeshType=Enum.MeshType.Head
            sm.MeshId=""
            sm.TextureId=""
            sm.Scale=Vector3.new(1.25,1.25,1.25)
        end
        local face=head:FindFirstChild("face") or head:FindFirstChildOfClass("Decal")
        if not face then
            face=Instance.new("Decal")
            face.Name="face"
            face.Face=Enum.NormalId.Front
            face.Texture="rbxasset://textures/face.png"
            face.Parent=head
        elseif face.Texture=="" or face.Texture:find("rbxassetid://") or face.Texture:find("roblox.com/asset") then
            face.Texture="rbxasset://textures/face.png"
        end
        face.Transparency=0
    end
    if isLocalUnpublished then
        for _,inst in ipairs(ch:GetChildren()) do
            if inst:IsA("Shirt") or inst:IsA("Pants") then
                inst:Destroy()
            end
        end
        local bc=ch:FindFirstChildOfClass("BodyColors")
        if not bc then
            bc=Instance.new("BodyColors")
            bc.Parent=ch
        end
        local torsoCol=Color3.fromRGB(26,28,36)
        local legCol=Color3.fromRGB(20,22,28)
        bc.TorsoColor3=torsoCol
        bc.LeftLegColor3=legCol
        bc.RightLegColor3=legCol
        for _,tName in ipairs({"UpperTorso","Torso"}) do
            local tp=ch:FindFirstChild(tName)
            if tp and tp:IsA("BasePart") then tp.Color=torsoCol end
        end
        for _,lName in ipairs({"LowerTorso","LeftUpperLeg","RightUpperLeg","LeftLowerLeg","RightLowerLeg","LeftFoot","RightFoot","Left Leg","Right Leg"}) do
            local lp=ch:FindFirstChild(lName)
            if lp and lp:IsA("BasePart") then lp.Color=legCol end
        end
    end
    for _,o in ipairs(ch:GetDescendants()) do
        if o:IsA("BasePart") and not o:FindFirstAncestor("SkyGuardianVisual") and not o:FindFirstAncestor("ThunderStrikerVisual") and not o:FindFirstAncestor("ArcaneMageVisual") then
            if HIDDEN_SERVER_PARTS[o.Name] then
                o.Transparency=1
            else
                o.Transparency=0
            end
        end
        if o:IsA("Decal") then
            local pp=o.Parent
            if not (pp and HIDDEN_SERVER_PARTS[pp.Name]) then
                o.Transparency=0
            end
        end
    end
    ch:SetAttribute("BlenderGuardian",true)
    ch:SetAttribute("SkybreakCosmeticsReady",true)
    return true
end
function A.Equip(ch,equipped)
    if not ch then return end
    for _,vName in ipairs({"SkyGuardianVisual","ThunderStrikerVisual","ArcaneMageVisual"}) do
        local body=ch:FindFirstChild(vName)
        if body then
            for _,o in ipairs(body:GetDescendants()) do
                if o:IsA("MeshPart") and o.Name:find("_Weapon_") then
                    o.Transparency=equipped and 0 or 1
                end
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
