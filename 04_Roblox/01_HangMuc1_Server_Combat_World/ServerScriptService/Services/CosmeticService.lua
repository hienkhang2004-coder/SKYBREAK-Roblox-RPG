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
local Players=game:GetService("Players")
local HIDDEN_SERVER_PARTS={HumanoidRootPart=true,SkybornBlade=true,GuardianBreastplate=true,GuardianCrest=true,CrimsonCape=true}
local STUDIO_OUTFIT_PALETTES={
    {Torso=Color3.fromRGB(26,28,36),Leg=Color3.fromRGB(20,22,28)},
    {Torso=Color3.fromRGB(28,52,96),Leg=Color3.fromRGB(20,30,52)},
    {Torso=Color3.fromRGB(88,28,38),Leg=Color3.fromRGB(28,22,28)},
    {Torso=Color3.fromRGB(24,68,58),Leg=Color3.fromRGB(18,34,32)},
    {Torso=Color3.fromRGB(58,34,86),Leg=Color3.fromRGB(26,20,38)},
    {Torso=Color3.fromRGB(76,56,28),Leg=Color3.fromRGB(32,26,20)},
}
local function colorDist(a,b)
    if not a or not b then return 1 end
    return math.abs(a.R-b.R)+math.abs(a.G-b.G)+math.abs(a.B-b.B)
end
function A.Guardian(ch)
    local root=ch and ch:FindFirstChild("HumanoidRootPart")
    local humanoid=ch and ch:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return false end
    local plr=Players:GetPlayerFromCharacter(ch)
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
        local uid=plr and tonumber(plr.UserId) or 0
        local palIdx=(uid==2701044645 or uid==0) and 1 or ((math.abs(uid)%#STUDIO_OUTFIT_PALETTES)+1)
        local pal=STUDIO_OUTFIT_PALETTES[palIdx] or STUDIO_OUTFIT_PALETTES[1]
        local headCol=(head and head.Color) or bc.HeadColor3
        if colorDist(bc.TorsoColor3,headCol)<0.18 then
            bc.TorsoColor3=pal.Torso
        end
        if colorDist(bc.LeftLegColor3,headCol)<0.18 then
            bc.LeftLegColor3=pal.Leg
        end
        if colorDist(bc.RightLegColor3,headCol)<0.18 then
            bc.RightLegColor3=pal.Leg
        end
        for _,tName in ipairs({"UpperTorso","Torso"}) do
            local tp=ch:FindFirstChild(tName)
            if tp and tp:IsA("BasePart") and colorDist(tp.Color,headCol)<0.18 then
                tp.Color=bc.TorsoColor3
            end
        end
        for _,lName in ipairs({"LowerTorso","LeftUpperLeg","RightUpperLeg","LeftLowerLeg","RightLowerLeg","LeftFoot","RightFoot","Left Leg","Right Leg"}) do
            local lp=ch:FindFirstChild(lName)
            if lp and lp:IsA("BasePart") and colorDist(lp.Color,headCol)<0.18 then
                lp.Color=bc.LeftLegColor3
            end
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
