local W={Interactions={}}
local gold=Color3.fromRGB(238,187,73)
local stone=Color3.fromRGB(224,222,204)
function W.Part(parent,name,size,pos,color,material)
    local p=Instance.new("Part") p.Name=name p.Size=size p.Position=pos p.Anchored=true
    p.Color=color or stone p.Material=material or Enum.Material.SmoothPlastic p.TopSurface=Enum.SurfaceType.Smooth p.BottomSurface=Enum.SurfaceType.Smooth p.Parent=parent
    return p
end
function W.Label(part,text)
    local gui=Instance.new("BillboardGui") gui.Size=UDim2.fromOffset(220,48) gui.StudsOffset=Vector3.new(0,4,0) gui.AlwaysOnTop=false gui.MaxDistance=90 gui.Parent=part
    local label=Instance.new("TextLabel") label.Size=UDim2.fromScale(1,1) label.BackgroundTransparency=.3 label.BackgroundColor3=Color3.fromRGB(18,26,39) label.TextColor3=Color3.new(1,.9,.65) label.TextScaled=true label.Font=Enum.Font.GothamBold label.Text=text label.Parent=gui
    return label
end
function W.Ring(parent,name,center,radius,color,segments)
    for i=1,segments or 24 do
        local count=segments or 24 local a=(i-1)*math.pi*2/count local b=i*math.pi*2/count
        local from=center+Vector3.new(math.cos(a)*radius,0,math.sin(a)*radius)
        local to=center+Vector3.new(math.cos(b)*radius,0,math.sin(b)*radius)
        local p=W.Part(parent,name,Vector3.new(.35,.35,(to-from).Magnitude), (from+to)/2,color,Enum.Material.Neon)
        p.CFrame=CFrame.lookAt((from+to)/2,to) p.CanCollide=false p.CanQuery=false
    end
end
function W.Decorate()
    local hub=W.Hub local sky=W.Sky
    local blue=Color3.fromRGB(29,53,92)
    for _,z in ipairs({0,-110,-205,-290,-355,-440}) do
        for _,x in ipairs({-46,46}) do
            local falling=W.Part(sky,"Waterfall",Vector3.new(7,58,1),Vector3.new(x,-24,z),Color3.fromRGB(152,223,246),Enum.Material.Glass)
            falling.Transparency=.45 falling.CanCollide=false falling.CanQuery=false
        end
    end
    for i=1,12 do
        local x=(i%2==0 and 1 or -1)*(88+(i%3)*18) local z=-i*34
        local rock=Instance.new("WedgePart") rock.Name="DistantFloatingRock" rock.Size=Vector3.new(18,30,20) rock.Position=Vector3.new(x,-12+(i%3)*9,z) rock.Anchored=true rock.Color=Color3.fromRGB(107,115,128) rock.Material=Enum.Material.Slate rock.Parent=sky
        W.Part(sky,"SatelliteGarden",Vector3.new(22,3,24),rock.Position+Vector3.new(0,16,0),Color3.fromRGB(100,151,113),Enum.Material.Grass)
    end
    for _,z in ipairs({-32,-138,-230,-316}) do
        for _,x in ipairs({-18,18}) do
            W.Part(sky,"IvoryColumn",Vector3.new(3,13,3),Vector3.new(x,10,z),stone)
            W.Part(sky,"GoldenCapital",Vector3.new(5,1,5),Vector3.new(x,17,z),gold)
            local flag=W.Part(sky,"SkybornBanner",Vector3.new(3,7,.25),Vector3.new(x,12,z-2),blue) flag.CanCollide=false
            local crest=W.Part(sky,"BannerCrest",Vector3.new(.3,3,.3),Vector3.new(x,12,z-2.2),gold,Enum.Material.Neon) crest.CanCollide=false
        end
    end
    W.Ring(hub,"HubSigil",Vector3.new(0,3.8,-13),10,gold,24)
    local crystal=W.Part(hub,"SkyCoreCrystal",Vector3.new(2.8,6,2.8),Vector3.new(0,9,-13),Color3.fromRGB(104,219,255),Enum.Material.Neon)
    crystal.CFrame*=CFrame.Angles(0,math.pi/4,math.pi/5) crystal.CanCollide=false
    for _,y in ipairs({31,47,59}) do W.Ring(sky,"TowerHalo",Vector3.new(0,y,-440),y==47 and 34 or 26,gold,32) end
    W.Ring(sky,"ArenaSigil",Vector3.new(0,3.8,-440),38,gold,48)
    for _,x in ipairs({-44,44}) do
        for _,z in ipairs({-405,-470}) do
            W.Part(sky,"TowerSpire",Vector3.new(3,16,3),Vector3.new(x,45,z),gold,Enum.Material.Metal)
        end
    end
    if not game.Lighting:FindFirstChildOfClass("Atmosphere") then
        local atmosphere=Instance.new("Atmosphere") atmosphere.Density=.22 atmosphere.Offset=.1 atmosphere.Color=Color3.fromRGB(215,228,244) atmosphere.Decay=Color3.fromRGB(240,211,163) atmosphere.Parent=game.Lighting
    end
end
function W.Interactable(parent,id,pos,text)
    local p=W.Part(parent,id,Vector3.new(3,5,3),pos,gold,Enum.Material.Neon)
    p.CanCollide=false
    p:SetAttribute("InteractableId",id)
    local prompt=Instance.new("ProximityPrompt")
    prompt.ActionText="Nói chuyện / Tương tác"
    prompt.ObjectText=text
    prompt.MaxActivationDistance=18
    prompt.HoldDuration=0
    prompt.RequiresLineOfSight=false
    prompt.Style=Enum.ProximityPromptStyle.Default
    prompt.Parent=p
    W.Label(p,text) W.Interactions[id]=p return p
end
function W.Build()
    if game.ReplicatedStorage:FindFirstChild('DelegatedV5Sources') then return require(script.Parent.DelegatedWorldService).Build(W) end
    local existingHub=workspace:FindFirstChild("SkyHub") local existingSky=workspace:FindFirstChild("GoldenSky")
    if existingHub and existingSky and existingHub:GetAttribute("WorldVersion")==2 then
        W.Hub=existingHub W.Sky=existingSky W.Spawn=existingHub:FindFirstChild("SkybornSpawn")
        for _,root in ipairs({existingHub,existingSky}) do for _,o in ipairs(root:GetDescendants()) do
            local id=o:GetAttribute("InteractableId") if id and o:IsA("BasePart") then W.Interactions[id]=o end
        end end
        require(script.Parent.VisualWorldService).UpgradeBaked(existingHub,existingSky)
        return
    end
    local lighting=game:GetService("Lighting") lighting.ClockTime=15 lighting.Brightness=1.35 lighting.ExposureCompensation=-0.22 lighting.Ambient=Color3.fromRGB(135,145,163)
    local hub=workspace:FindFirstChild("SkyHub") or Instance.new("Model",workspace) hub.Name="SkyHub"
    local sky=workspace:FindFirstChild("GoldenSky") or Instance.new("Model",workspace) sky.Name="GoldenSky"
    W.Hub=hub W.Sky=sky
    for _,name in ipairs({"ActiveEnemies","ActiveBosses","SpawnPoints"}) do
        if not workspace:FindFirstChild(name) then local f=Instance.new("Folder",workspace) f.Name=name end
    end
    local function island(parent,name,z,sx,sz)
        W.Part(parent,name,Vector3.new(sx,6,sz),Vector3.new(0,0,z),stone)
        W.Part(parent,name.."Grass",Vector3.new(sx-3,.6,sz-3),Vector3.new(0,3.2,z),Color3.fromRGB(98,151,113),Enum.Material.Grass)
        W.Part(parent,name.."Rock",Vector3.new(sx*.72,17,sz*.7),Vector3.new(0,-10,z),Color3.fromRGB(91,105,115),Enum.Material.Slate)
        for _,x in ipairs({-sx/2,sx/2}) do W.Part(parent,"SafetyRail",Vector3.new(1,3,sz),Vector3.new(x,5,z),gold) end
    end
    island(hub,"SkyHubSpawn",0,100,90)
    island(sky,"TrainingGround",-110,100,100)
    island(sky,"BrokenBridgeQuestArea",-205,110,75)
    island(sky,"GoldenKnightArena",-290,110,80)
    island(sky,"LightTowerEntrance",-355,100,45)
    island(sky,"AureonBossArena",-440,115,110)
    local function bridge(z,length)
        W.Part(sky,"Bridge",Vector3.new(16,2,length),Vector3.new(0,3,z),gold)
        for _,x in ipairs({-8,8}) do W.Part(sky,"BridgeRail",Vector3.new(1,3,length),Vector3.new(x,5,z),stone) end
    end
    bridge(-53,22) bridge(-164,15) bridge(-247,17) bridge(-330,13) bridge(-382,14)
    local spawn=Instance.new("SpawnLocation") spawn.Name="SkybornSpawn" spawn.Size=Vector3.new(10,1,10) spawn.Position=Vector3.new(0,4,15) spawn.Anchored=true spawn.Neutral=true spawn.Duration=2 spawn.Color=gold spawn.Parent=hub W.Spawn=spawn
    W.Interactable(hub,"Lyra",Vector3.new(-14,6,-10),"Lyra • Nhiệm vụ")
    W.Interactable(hub,"Kael",Vector3.new(20,6,0),"Kael • Thợ rèn (sắp có)")
    W.Interactable(hub,"FrozenPortal",Vector3.new(32,7,-28),"Frozen Cyber • Chương sau")
    W.Interactable(sky,"ReturnHub",Vector3.new(37,6,-350),"Về Sky Hub")
    for i=1,3 do W.Interactable(sky,"Station"..i,Vector3.new(-36+(i-1)*36,6,-205),"Trạm năng lượng "..i) end
    for i=1,3 do W.Interactable(sky,"Citizen"..i,Vector3.new(-36+(i-1)*36,6,-280),"Người dân "..i) end
    for i=1,2 do W.Interactable(sky,"Switch"..i,Vector3.new(i==1 and -26 or 26,6,-350),"Công tắc tháp "..i) end
    W.Interactable(sky,"ArenaGate",Vector3.new(0,6,-377),"Aureon • Vào / bắt đầu trận")
    W.Interactable(sky,"LeaveArena",Vector3.new(43,6,-399),"Rời đấu trường")
    for _,x in ipairs({-44,44}) do
        for _,z in ipairs({-405,-470}) do
            W.Part(sky,"TowerPillar",Vector3.new(7,32,7),Vector3.new(x,19,z),stone)
            W.Part(sky,"TowerCrown",Vector3.new(10,3,10),Vector3.new(x,36,z),gold,Enum.Material.Neon)
        end
    end
    W.Label(W.Part(sky,"RouteSign",Vector3.new(1,1,1),Vector3.new(0,9,-80),gold),"GOLDEN SKY • Sân tập")
    W.Label(W.Part(sky,"TowerSign",Vector3.new(1,1,1),Vector3.new(0,12,-345),gold),"THÁP ÁNH SÁNG")
    for i=1,14 do
        local z=-25-(i-1)*24 local x=(i%2==0 and 1 or -1)*43
        W.Part(sky,"TreeTrunk",Vector3.new(2,7,2),Vector3.new(x,7,z),Color3.fromRGB(107,81,58))
        local crown=W.Part(sky,"TreeCrown",Vector3.new(10,10,10),Vector3.new(x,13,z),Color3.fromRGB(68,126,92)) crown.Shape=Enum.PartType.Ball crown.CanCollide=false
    end
    W.Decorate()
    require(script.Parent.VisualWorldService).Build(hub,sky)
end
return W
