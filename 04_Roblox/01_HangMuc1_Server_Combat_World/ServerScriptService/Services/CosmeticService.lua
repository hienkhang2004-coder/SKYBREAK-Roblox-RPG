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
local CORE_AVATAR_LIMBS={
    Head=true,Torso=true,UpperTorso=true,LowerTorso=true,
    ["Left Arm"]=true,["Right Arm"]=true,["Left Leg"]=true,["Right Leg"]=true,
    LeftUpperArm=true,LeftLowerArm=true,LeftHand=true,
    RightUpperArm=true,RightLowerArm=true,RightHand=true,
    LeftUpperLeg=true,LeftLowerLeg=true,LeftFoot=true,
    RightUpperLeg=true,RightLowerLeg=true,RightFoot=true,
}
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
    local uid=plr and tonumber(plr.UserId) or 0
    local isStudioDummy=(game.PlaceId==0 and uid<=0)
    local head=ch:FindFirstChild("Head")
    local hasShirtOrPants=(ch:FindFirstChildOfClass("Shirt")~=nil or ch:FindFirstChildOfClass("Pants")~=nil)
    if isStudioDummy and not hasShirtOrPants then
        local bc=ch:FindFirstChildOfClass("BodyColors")
        if not bc then
            bc=Instance.new("BodyColors")
            bc.Parent=ch
        end
        local pal=STUDIO_OUTFIT_PALETTES[1]
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
    end
    for _,o in ipairs(ch:GetDescendants()) do
        if o:IsA("BasePart") and not o:FindFirstAncestor("SkyGuardianVisual") and not o:FindFirstAncestor("ThunderStrikerVisual") and not o:FindFirstAncestor("ArcaneMageVisual") then
            if HIDDEN_SERVER_PARTS[o.Name] then
                o.Transparency=1
            elseif CORE_AVATAR_LIMBS[o.Name]
                and o.Parent==ch
                and not o:FindFirstAncestorOfClass("Accessory")
                and not o:FindFirstAncestorOfClass("Accoutrement")
                and not o:FindFirstAncestorOfClass("Tool")
                and not o:FindFirstChildOfClass("WrapLayer")
                and not o:FindFirstChildOfClass("WrapTarget")
                and o.Transparency>=0.99 then
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
