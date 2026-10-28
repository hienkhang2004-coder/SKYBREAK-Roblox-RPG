local V={}
local gold=Color3.fromRGB(218,175,77)
local ivory=Color3.fromRGB(226,215,185)
local blue=Color3.fromRGB(25,51,89)
local function part(parent,name,size,cf,color,material)
    local p=Instance.new("Part") p.Name=name p.Size=size p.CFrame=typeof(cf)=="CFrame" and cf or CFrame.new(cf) p.Color=color or ivory p.Material=material or Enum.Material.Limestone p.Anchored=true p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=parent return p
end
local function ghost(p) p.CanCollide=false p.CanTouch=false p.CanQuery=false return p end
local function cylinder(parent,name,pos,radius,height,color,material)
    local p=part(parent,name,Vector3.new(height,radius*2,radius*2),CFrame.new(pos)*CFrame.Angles(0,0,math.pi/2),color,material) p.Shape=Enum.PartType.Cylinder return p
end
local function ring(parent,name,center,radius,thickness,color)
    local count=64
    for i=1,count do
        local a=math.pi*2*(i-1)/count local b=math.pi*2*i/count
        local from=center+Vector3.new(math.cos(a)*radius,0,math.sin(a)*radius)
        local to=center+Vector3.new(math.cos(b)*radius,0,math.sin(b)*radius)
        ghost(part(parent,name,Vector3.new(thickness,thickness,(to-from).Magnitude+.12),CFrame.lookAt((from+to)/2,to),color,Enum.Material.Metal))
    end
end
local function column(parent,pos,height)
    local g=Instance.new("Model") g.Name="IvoryColumn" g.Parent=parent
    part(g,"Foot",Vector3.new(5,1,5),pos,ivory)
    part(g,"GoldenFoot",Vector3.new(4.4,.45,4.4),pos+Vector3.new(0,.7,0),gold,Enum.Material.Metal)
    cylinder(g,"Shaft",pos+Vector3.new(0,height/2+1,0),1.45,height,ivory)
    for i=1,8 do local a=i*math.pi/4
        ghost(part(g,"Flute",Vector3.new(.12,height-.6,.12),pos+Vector3.new(math.cos(a)*1.43,height/2+1,math.sin(a)*1.43),Color3.fromRGB(197,182,149)))
    end
    part(g,"Capital",Vector3.new(4.3,.6,4.3),pos+Vector3.new(0,height+1.3,0),gold,Enum.Material.Metal)
    part(g,"Crown",Vector3.new(5,1,5),pos+Vector3.new(0,height+2,0),ivory)
end
local function banner(parent,pos)
    part(parent,"BannerPole",Vector3.new(.3,15,.3),pos+Vector3.new(0,7.5,0),gold,Enum.Material.Metal)
    local cloth=ghost(part(parent,"AzureBanner",Vector3.new(3.2,7,.15),pos+Vector3.new(0,10,-.5),blue,Enum.Material.Fabric))
    for _,x in ipairs({-1.5,1.5}) do ghost(part(parent,"BannerGoldBorder",Vector3.new(.13,7,.17),cloth.Position+Vector3.new(x,0,-.1),gold,Enum.Material.Metal)) end
    local star=ghost(part(parent,"SunCrest",Vector3.new(1.25,1.25,.2),CFrame.new(cloth.Position+Vector3.new(0,0,-.2))*CFrame.Angles(0,0,math.pi/4),gold,Enum.Material.Metal))
end
local function tree(parent,pos,seed)
    local assets=game.ServerStorage:FindFirstChild("VisualPrefabs")
    if assets and assets:FindFirstChild("GardenTree") then
        local model=assets.GardenTree:Clone() model.Name="GardenTree" model.Parent=parent
        local _,size=model:GetBoundingBox() model:ScaleTo(model:GetScale()*13/size.Y)
        local cf,newSize=model:GetBoundingBox() local target=pos+Vector3.new(0,newSize.Y/2,0)
        model:PivotTo(CFrame.new(target-cf.Position)*model:GetPivot())
        for _,p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then p.Anchored=true p.CanCollide=false p.CanTouch=false end end
        return
    end
    local random=Random.new(seed)
    local trunk=part(parent,"TreeTrunk",Vector3.new(1.6,8,1.6),pos+Vector3.new(0,4,0),Color3.fromRGB(101,81,58),Enum.Material.Wood)
    for i=1,5 do
        local crown=ghost(part(parent,"LeafCluster",Vector3.new(7,4.5,7),pos+Vector3.new(random:NextNumber(-3,3),8+random:NextNumber(-1,3),random:NextNumber(-3,3)),Color3.fromRGB(78+seed%25,116+seed%30,65),Enum.Material.Grass)) crown.Shape=Enum.PartType.Ball
    end
end
function V.CreateNPC(marker,id)
    local name=id.."Character" if marker.Parent:FindFirstChild(name) then return end
    local description=Instance.new("HumanoidDescription")
    description.HeadColor=Color3.fromRGB(229,188,149) description.LeftArmColor=description.HeadColor description.RightArmColor=description.HeadColor
    description.TorsoColor=id=="Kael" and Color3.fromRGB(85,58,41) or Color3.fromRGB(44,73,108)
    description.LeftLegColor=Color3.fromRGB(42,46,55) description.RightLegColor=description.LeftLegColor
    local ok,model=pcall(function() return game:GetService("Players"):CreateHumanoidModelFromDescriptionAsync(description,Enum.HumanoidRigType.R15) end)
    description:Destroy()
    if not ok then warn("[SKYBREAK] NPC appearance could not load",id,model) return end
    model.Name=name model.Parent=marker.Parent model:PivotTo(CFrame.new(marker.Position+Vector3.new(0,.8,0)))
    -- Static NPC visuals must not let Humanoid re-enable torso collisions during simulation.
    local humanoid=model:FindFirstChildOfClass("Humanoid") if humanoid then humanoid:Destroy() end
    local root=model:FindFirstChild("HumanoidRootPart") if root then root.Anchored=true end
    for _,p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false p.CanTouch=false end end
    marker.Transparency=1
end
function V.PlaceAsset(name,parent,center,width,depth,top)
    local folder=game.ServerStorage:FindFirstChild("VisualPrefabs") local source=folder and folder:FindFirstChild(name)
    if name=="FloatingIsland" and folder and folder:FindFirstChild("BlenderFloatingCliff") then source=folder.BlenderFloatingCliff end
    if not source then return nil end
    local model=source:Clone() model.Name=name model.Parent=parent
    if name=="FloatingIsland" then model:SetAttribute("IslandTop",top) end
    if source.Name=="BlenderFloatingCliff" then model:SetAttribute("LimestoneRevision",3) end
    local _,oldSize=model:GetBoundingBox() model:ScaleTo(model:GetScale()*width/oldSize.X)
    local cf,size=model:GetBoundingBox()
    -- Transform the bounding-box center, preserving authored orientation and imported mesh data.
    local target=Vector3.new(center.X,top+(name=="CelestialCathedral" and size.Y/2 or -size.Y/2),center.Z)
    model:PivotTo(CFrame.new(target-cf.Position)*model:GetPivot())
    for _,p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then p.Anchored=true p.CanCollide=false p.CanTouch=false end end
    return model
end
local function bridge(parent,z,length)
    local model=Instance.new("Model") model.Name="ArchedGoldenBridge" model.Parent=parent
    part(model,"Walkway",Vector3.new(15,1,length),Vector3.new(0,3,z),ivory,Enum.Material.Limestone)
    for _,x in ipairs({-8,8}) do
        for i=0,8 do
            local a=i*math.pi/8 local b=(i+1)*math.pi/8
            if i<8 then
                local from=Vector3.new(x,-4+math.sin(a)*6,z-length/2+length*i/8)
                local to=Vector3.new(x,-4+math.sin(b)*6,z-length/2+length*(i+1)/8)
                ghost(part(model,"ArchStone",Vector3.new(1.4,2,(to-from).Magnitude+.1),CFrame.lookAt((from+to)/2,to),ivory))
            end
            part(model,"Baluster",Vector3.new(.7,3,.7),Vector3.new(x,5,z-length/2+length*i/8),ivory)
        end
        part(model,"GoldenHandrail",Vector3.new(1,.6,length+1),Vector3.new(x,6.7,z),gold,Enum.Material.Metal)
    end
end
function V.ScenicPass(hub,sky)
    if sky:FindFirstChild("CelestialSkyline") then return end
    local skyline=Instance.new("Model") skyline.Name="CelestialSkyline" skyline.Parent=sky
    -- Off-route architecture gives the playable spine the surrounding city seen in the concepts.
    for i,z in ipairs({-25,-130,-230,-330,-455}) do
        for _,side in ipairs({-1,1}) do
            local x=side*(112+(i%2)*22) local elevation=12+(i%3)*14
            local district=Instance.new("Model") district.Name="Sanctuary"..i..(side<0 and "West" or "East") district.Parent=skyline
            V.PlaceAsset("FloatingIsland",district,Vector3.new(x,0,z),92,92,elevation)
            V.PlaceAsset("CelestialCathedral",district,Vector3.new(x,0,z),50,50,elevation)
            for _,dx in ipairs({-30,30}) do tree(district,Vector3.new(x+dx,elevation,z+12),i*13+side) end
            for n=1,7 do
                local ribbon=ghost(part(district,"CascadingWater",Vector3.new(.9,85,.15),Vector3.new(x+side*41+n*.25,elevation-42,z+8+n*.6),Color3.fromRGB(204,234,247),Enum.Material.Glass)) ribbon.Transparency=.38 ribbon.CastShadow=false
            end
        end
    end
    local grand=V.PlaceAsset("CelestialCathedral",skyline,Vector3.new(0,0,-625),210,210,34)
    V.PlaceAsset("FloatingIsland",skyline,Vector3.new(0,0,-625),245,245,34)
    if grand then grand.Name="CitadelOfTheSun" end
    for i=1,18 do
        local angle=i*2.39996 local x=math.cos(angle)*(230+i*7) local z=-240+math.sin(angle)*350
        local top=30+(i%5)*25 local width=24+(i%4)*12
        local isle=V.PlaceAsset("FloatingIsland",skyline,Vector3.new(x,0,z),width,width,top)
        if isle and i%3==0 then V.PlaceAsset("CelestialCathedral",isle,Vector3.new(x,0,z),width*.6,width,top) end
    end
    local clouds=Instance.new("Model") clouds.Name="CloudSea" clouds.Parent=skyline
    for i=1,24 do
        local angle=i*2.39996 local radius=55+math.sqrt(i/24)*420
        local position=Vector3.new(math.cos(angle)*radius,-54-(i%5)*8,-250+math.sin(angle)*radius)
        local anchor=ghost(part(clouds,"CloudEmitter",Vector3.one,position,Color3.new(1,1,1))) anchor.Transparency=1 anchor.CastShadow=false
        local emitter=Instance.new("ParticleEmitter") emitter.Name="SkybreakCloud" emitter.Texture="rbxasset://textures/particles/smoke_main.dds"
        emitter.Color=ColorSequence.new(Color3.fromRGB(248,244,236)) emitter.LightEmission=.15 emitter.LightInfluence=.1
        emitter.Lifetime=NumberRange.new(70,90) emitter.Rate=.18 emitter.Speed=NumberRange.new(0,.3)
        emitter.Size=NumberSequence.new(110+(i%3)*25) emitter.Rotation=NumberRange.new(0,360) emitter.RotSpeed=NumberRange.new(-1,1)
        emitter.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.12,.5),NumberSequenceKeypoint.new(.8,.55),NumberSequenceKeypoint.new(1,1)}) emitter.Parent=anchor
    end
    local terrain=workspace:FindFirstChildOfClass("Terrain")
    if terrain and not terrain:FindFirstChildOfClass("Clouds") then local cloud=Instance.new("Clouds") cloud.Cover=.65 cloud.Density=.5 cloud.Color=Color3.fromRGB(248,241,227) cloud.Parent=terrain end
    local lighting=game:GetService("Lighting") lighting.ClockTime=16.3
    local atmosphere=lighting:FindFirstChildOfClass("Atmosphere")
    if atmosphere then atmosphere.Density=.3 atmosphere.Offset=.25 atmosphere.Haze=1.4 atmosphere.Glare=.25 atmosphere.Color=Color3.fromRGB(229,234,246) atmosphere.Decay=Color3.fromRGB(237,208,164) end
    for _,root in ipairs({hub,sky}) do for _,o in ipairs(root:GetDescendants()) do
        if o:IsA("BillboardGui") then o.MaxDistance=32 o.Size=UDim2.fromOffset(180,33) end
        if o:IsA("ProximityPrompt") then o.RequiresLineOfSight=false end
    end end
end
function V.UpgradeBaked(hub,sky)
    local prefabs=game.ServerStorage:FindFirstChild("VisualPrefabs")
    if prefabs then for _,id in ipairs({"Lyra","Kael"}) do
        local source=prefabs:FindFirstChild(id) local marker=hub:FindFirstChild(id) local existing=hub:FindFirstChild(id.."Character")
        if source and marker and (not existing or not existing:GetAttribute("TexturedNPC")) then
            if existing then existing:Destroy() end
            local model=source:Clone() model.Name=id.."Character" model.Parent=hub
            local cf,size=model:GetBoundingBox() model:ScaleTo(model:GetScale()*5.7/size.Y) cf,size=model:GetBoundingBox()
            local target=CFrame.new(marker.Position.X,3.8+size.Y/2,marker.Position.Z)*CFrame.Angles(0,math.pi,0)
            model:PivotTo(target*cf:Inverse()*model:GetPivot()) model:SetAttribute("TexturedNPC",true)
        end
    end end
    for _,root in ipairs({hub,sky}) do for _,model in ipairs(root:GetChildren()) do
        if model:IsA("Model") and model.Name:match("Character$") then
            local humanoid=model:FindFirstChildOfClass("Humanoid") if humanoid then humanoid:Destroy() end
            for _,o in ipairs(model:GetDescendants()) do if o:IsA("LuaSourceContainer") then o:Destroy() end end
            for _,p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then p.Anchored=true p.CanCollide=false p.CanTouch=false end end
        end
    end end
    V.ScenicPass(hub,sky)
    if prefabs and prefabs:FindFirstChild("BlenderFloatingCliff") then
        local replace={}
        for _,o in ipairs(sky:GetDescendants()) do if o:IsA("Model") and o.Name=="FloatingIsland" and o:GetAttribute("LimestoneRevision")~=3 then table.insert(replace,o) end end
        for _,old in ipairs(replace) do
            local parent=old.Parent
            for _,child in ipairs(old:GetChildren()) do if child.Name=="CelestialCathedral" then child.Parent=parent end end
            local cf,size=old:GetBoundingBox() local top=old:GetAttribute("IslandTop") or (cf.Position.Y+size.Y/2)
            old:Destroy() V.PlaceAsset("FloatingIsland",parent,Vector3.new(cf.Position.X,0,cf.Position.Z),size.X,size.Z,top)
        end
    end
    local art=sky:FindFirstChild("GoldenSkyArt") local assets=game.ServerStorage:FindFirstChild("VisualPrefabs")
    if not art or not assets or art:GetAttribute("DetailedArtPass") then return end
    if assets:FindFirstChild("GardenTree") then
        local positions={}
        for _,p in ipairs(art:GetDescendants()) do if p:IsA("BasePart") and p.Name=="TreeTrunk" and p.Transparency<1 then table.insert(positions,{Parent=p.Parent,Position=p.Position-Vector3.new(0,4,0)}) end end
        for _,p in ipairs(art:GetDescendants()) do if p:IsA("BasePart") and (p.Name=="TreeTrunk" or p.Name=="LeafCluster") then p:Destroy() end end
        for i,t in ipairs(positions) do tree(t.Parent,t.Position,i) if i%8==0 then task.wait() end end
    end
    local source=assets:FindFirstChild("AqueductBridge")
    if source then
        for _,native in ipairs(art:GetChildren()) do
            if native.Name=="ArchedGoldenBridge" then
                local walkway=native:FindFirstChild("Walkway")
                if walkway then
                    local model=source:Clone() model.Name="TexturedBridge" model.Parent=native
                    local cf,size=model:GetBoundingBox() model:ScaleTo(model:GetScale()*(walkway.Size.Z+4)/size.X)
                    cf,size=model:GetBoundingBox()
                    local target=CFrame.new(walkway.Position+Vector3.new(0,-3,0))*CFrame.Angles(0,math.pi/2,0)
                    model:PivotTo(target*cf:Inverse()*model:GetPivot())
                    for _,p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then p.Anchored=true p.CanCollide=false p.CanTouch=false end end
                    for _,p in ipairs(native:GetChildren()) do if p:IsA("BasePart") then p.Transparency=1 end end
                end
            end
        end
    end
    art:SetAttribute("DetailedArtPass",true)
end
function V.Build(hub,sky)
    if sky:FindFirstChild("GoldenSkyArt") then return end
    local art=Instance.new("Model") art.Name="GoldenSkyArt" art.Parent=sky
    -- Remove only primitive decoration from the P0 builder, retaining collision and interactions.
    for _,o in ipairs(sky:GetDescendants()) do
        if o:IsA("BasePart") and (o.Name=="TreeTrunk" or o.Name=="TreeCrown" or o.Name=="Waterfall" or o.Name=="Rock" or o.Name=="DistantFloatingRock" or o.Name=="SatelliteGarden" or o.Name=="TowerPillar" or o.Name=="TowerCrown" or o.Name=="TowerSpire" or o.Name=="TowerHalo") then o.Transparency=1 o.CanCollide=false end
    end
    for _,parent in ipairs({hub,sky}) do
        for _,o in ipairs(parent:GetChildren()) do
            if o:IsA("BasePart") and (o.Name:find("Grass") or o.Name:find("Rock")) then
                o.Transparency=1 o.CanCollide=false
            elseif o:IsA("BasePart") and o.Name=="SkybornSpawn" then o.Transparency=1 o.Duration=0 end
        end
    end
    local zones={{0,100,90},{-110,100,100},{-205,110,75},{-290,110,80},{-355,100,45},{-440,115,110}}
    for index,zone in ipairs(zones) do
        local z,sx,sz=table.unpack(zone)
        local group=Instance.new("Model") group.Name="IslandDistrict"..index group.Parent=art
        V.PlaceAsset("FloatingIsland",group,Vector3.new(0,0,z),math.max(sx,sz)*1.5,sz,2.7)
        for ix=-math.floor(sx/12/2),math.floor(sx/12/2) do for iz=-math.floor(sz/12/2),math.floor(sz/12/2) do
            local shade=(ix+iz)%3
            part(group,"LimestonePaver",Vector3.new(11.7,.35,11.7),Vector3.new(ix*12,3.48,z+iz*12),Color3.fromRGB(224+shade*3,211+shade*3,180+shade*3),Enum.Material.Limestone)
        end end
        for _,x in ipairs({-sx/2+5,sx/2-5}) do
            for _,offset in ipairs({-sz/2+10,sz/2-10}) do
                column(group,Vector3.new(x,4,z+offset),11)
                banner(group,Vector3.new(x+(x<0 and 5 or -5),3.8,z+offset))
            end
            for n=1,3 do tree(group,Vector3.new(x,3.7,z-sz*.3+n*sz*.15),index*10+n) end
            for n=1,6 do
                local waterfall=ghost(part(group,"WaterfallRibbon",Vector3.new(1.1,46+n%3*8,.15),CFrame.new(x+(x<0 and -5 or 5)+n*.23,-20,z+8+n*.8),Color3.fromRGB(184,223,238),Enum.Material.Glass)) waterfall.Transparency=.3
            end
        end
        task.wait()
    end
    for _,b in ipairs({{-53,22},{-164,15},{-247,17},{-330,13},{-382,14}}) do bridge(art,b[1],b[2]) end
    for _,data in ipairs({{-145,-115,4},{140,-200,-5},{-165,-305,20},{150,-415,6},{-200,-480,30},{195,-65,35}}) do
        local satellite=Instance.new("Model") satellite.Name="SatelliteSanctuary" satellite.Parent=art
        V.PlaceAsset("FloatingIsland",satellite,Vector3.new(data[1],0,data[2]),70,70,data[3])
        for _,x in ipairs({-18,18}) do column(satellite,Vector3.new(data[1]+x,data[3],data[2]),15) end
        tree(satellite,Vector3.new(data[1]-12,data[3],data[2]-15),math.floor(math.abs(data[1])))
    end
    local altar=Instance.new("Model") altar.Name="SkyHubSanctuary" altar.Parent=hub
    cylinder(altar,"OuterDais",Vector3.new(0,3.4,-14),16,.7,ivory)
    ring(altar,"SunInlay",Vector3.new(0,3.9,-14),14,.3,gold)
    ring(altar,"InnerInlay",Vector3.new(0,3.9,-14),10,.15,gold)
    local cathedral=V.PlaceAsset("CelestialCathedral",art,Vector3.new(0,0,-532),100,70,120)
    if cathedral then
        local cf,size=cathedral:GetBoundingBox()
        cathedral:PivotTo(CFrame.new(0,4-(cf.Position.Y-size.Y/2),0)*cathedral:GetPivot())
    end
    for _,x in ipairs({-33,33}) do
        column(art,Vector3.new(x,4,-409),24)
        banner(art,Vector3.new(x+(x<0 and 5 or -5),4,-409))
    end
    ring(art,"BossArenaInlay",Vector3.new(0,3.9,-440),37,.3,gold)
    local lighting=game:GetService("Lighting")
    lighting.ClockTime=15 lighting.Brightness=2 lighting.Ambient=Color3.fromRGB(125,132,150) lighting.OutdoorAmbient=Color3.fromRGB(148,155,169)
    local correction=lighting:FindFirstChild("SkybreakGrade") or Instance.new("ColorCorrectionEffect") correction.Name="SkybreakGrade" correction.Contrast=.08 correction.Saturation=.05 correction.TintColor=Color3.fromRGB(255,245,224) correction.Parent=lighting
    local bloom=lighting:FindFirstChild("SkybreakBloom") or Instance.new("BloomEffect") bloom.Name="SkybreakBloom" bloom.Intensity=.18 bloom.Size=16 bloom.Threshold=1.8 bloom.Parent=lighting
    local rays=lighting:FindFirstChild("SkybreakSunRays") or Instance.new("SunRaysEffect") rays.Name="SkybreakSunRays" rays.Intensity=.04 rays.Spread=.8 rays.Parent=lighting
    for _,o in ipairs({hub,sky}) do o:SetAttribute("WorldVersion",2) end
    for _,o in ipairs({hub,sky}) do for _,marker in ipairs(o:GetChildren()) do
        local id=marker:GetAttribute("InteractableId")
        if marker:IsA("BasePart") and id and (id=="Lyra" or id=="Kael" or id:match("^Citizen")) then V.CreateNPC(marker,id) task.wait() end
    end end
    V.UpgradeBaked(hub,sky)
end
return V
