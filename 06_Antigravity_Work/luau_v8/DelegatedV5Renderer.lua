-- Local original Blender geometry. Asset upload API is unavailable in this Studio build.
-- Compressed source inputs survive saving; ephemeral meshes are rebuilt per play session.
local Asset=game:GetService('AssetService')
local Run=game:GetService('RunService')
local Sources=game.ReplicatedStorage:WaitForChild('DelegatedV5Sources')
local M={Models={},Images={},Surfaces={},Contents={},Jobs={}}
local function v(a)return Vector3.new(a[1],a[2],a[3])end
local function cf(a)return CFrame.new(table.unpack(a))end
local function srgb(x)return x<=.0031308 and x*12.92 or 1.055*x^(1/2.4)-.055 end
local function snapshot(e)
    local status,content=Asset:CreateDataModelContentAsync(Content.fromObject(e))
    assert(status==Enum.CreateContentResult.Success,'V5 content: '..tostring(status))
    table.insert(M.Contents,content);return content
end
local function texture(name)
    if M.Images[name] then return M.Images[name] end
    local module=Sources.Textures:FindFirstChild(name)
    if not module then return nil end
    local ok,data=pcall(require,module)
    if not ok or type(data)~='table' or not data.pixels then
        local t={}
        for i=1,#module:GetChildren() do
            local sv=module:FindFirstChild(string.format('Data%03d',i))
            if sv then t[i]=sv.Value end
        end
        local e=game:GetService('EncodingService')
        local b=e:DecompressBuffer(e:Base64Decode(buffer.fromstring(table.concat(t))),Enum.CompressionAlgorithm.Zstd)
        local npx=math.floor(buffer.len(b)/4)
        local sq=math.floor(math.sqrt(npx)+0.5)
        local w=(sq*sq==npx) and sq or 768
        local h=math.max(1,math.floor(npx/w))
        data={width=w,height=h,pixels=b}
    end
    -- Runtime preview maps fit the shared client EditableImage budget. Original
    -- full-resolution pixels remain in saved source modules and Blender files.
    local cap=256
    local scale=math.min(1,cap/math.max(data.width,data.height))
    local width=math.max(1,math.floor(data.width*scale));local height=math.max(1,math.floor(data.height*scale))
    local pixels=data.pixels
    if width~=data.width or height~=data.height then
        pixels=buffer.create(width*height*4)
        for y=0,height-1 do
            for x=0,width-1 do
                local sx=math.min(data.width-1,math.floor((x+.5)*data.width/width))
                local sy=math.min(data.height-1,math.floor((y+.5)*data.height/height))
                buffer.copy(pixels,(y*width+x)*4,data.pixels,(sy*data.width+sx)*4,4)
            end
            if y%32==0 then task.wait()end
        end
    end
    local im=assert(Asset:CreateEditableImage({Size=Vector2.new(width,height)}),'Texture allocation '..name)
    im:WritePixelsBuffer(Vector2.zero,im.Size,pixels)
    data.pixels=nil;M.Images[name]=im;return im
end
local function surface(mat)
    if not mat.maps or not next(mat.maps) then return nil end
    local library=game.ReplicatedStorage:FindFirstChild('SKYBREAK_SurfaceAssets')
    if library then
        local keys={}for key in mat.maps do table.insert(keys,key)end;table.sort(keys)
        local parts={}for _,key in keys do table.insert(parts,key..'='..mat.maps[key])end
        local signature=table.concat(parts,'|')..'|E='..string.format('%.3f',mat.emission_strength or 0)
        for _,template in library:GetChildren()do
            if template:IsA('SurfaceAppearance')and template:GetAttribute('SourceSignature')==signature then return template:Clone()end
        end
        error('Missing cloud surface template: '..mat.name)
    end
    local key=game.HttpService:JSONEncode(mat.maps)..':'..tostring(mat.emission_strength)
    if M.Surfaces[key] then return M.Surfaces[key]:Clone() end
    local maps={}
    for slot,name in mat.maps do local im=texture(name);if im then maps[slot]=Content.fromObject(im) end end
    if not next(maps) then return nil end
    local sa=Asset:CreateSurfaceAppearanceAsync(maps)
    if maps.EmissiveMask then sa.EmissiveStrength=mat.emission_strength;sa.EmissiveTint=Color3.new(1,1,1)end
    M.Surfaces[key]=sa;return sa:Clone()
end
local STATIC_WORLD_MODELS={
    GoldenSky=true,FrozenCyber=true,ShadowRealm=true,
    WestGardenPirateBastion=true,SunshardSkySanctuary=true,
    CyberportCafeTradingHub=true,PermafrostGarrisonFortress=true,
    MicrochipAwakeningRaidLab=true,GlacialWreckageDangerSea=true,
    CastleOnTheVoidMansion=true,UmbralCrystalSanctumForest=true,
    TempleOfTheCoreRaceV4=true,MirageSkyIslandLeviathanAbyss=true,
    ZiolesGachaShrine=true,AetherShrinesAndRaidConsole=true,
    KaelWorkstation=true,AncientAetherFruitTrees=true,
    CelestialAetherGalleon=true,CyberEnforcerShip=true,LeviathanHunterShip=true,
    AetherFruitsCollection1=true,AetherFruitsCollection2=true,
    MythicalWeaponsSet=true,
}
local function build(name,progress)
    if M.Models[name] and M.Models[name].PrimaryPart and M.Models[name].PrimaryPart.Parent then return M.Models[name] end
    local isFruit=(name:sub(1,6)=='Fruit_' or name=='AetherFruitsCollection1' or name=='AetherFruitsCollection2')
    local isStatic=(STATIC_WORLD_MODELS[name]==true or isFruit)
    local folder=Sources:WaitForChild(name);local h=require(folder.Header)
    if type(h)=='string' then h=game.HttpService:JSONDecode(h) end
    local model=Instance.new('Model');model.Name=name;model:SetAttribute('BlenderHandoff',true)
    M.ActiveModel=model
    local root=Instance.new('Part');root.Name='RootPart';root.Transparency=1;root.Size=Vector3.one*.1
    root.Anchored=true;root.CanCollide=false;root.CanQuery=false;root.CanTouch=false;root.Parent=model;model.PrimaryPart=root
    local nodes={}
    if not isStatic then
        for _,b in h.bones do
            local bone=Instance.new('Bone');bone.Name=b.name;bone.CFrame=cf(b['local']);bone.Parent=b.parent and nodes[b.parent] or root;nodes[b.name]=bone
        end
    end
    for index=0,h.mesh_count-1 do
        if progress then progress(name,index+1,h.mesh_count) end
        local d=require(folder[string.format('Mesh%03d',index)])
        if type(d)=='string' then d=game.HttpService:JSONDecode(d) end
        local mat=d.material;local matNameLower=string.lower(tostring(mat and mat.name or ''))
        local meshNameStr=tostring(d.name or '')
        local isPureFXCage=(matNameLower:sub(1,4)=='mat_' and matNameLower:sub(-2)=='fx')
            or matNameLower:find('elementalfx') or matNameLower:find('holocyanfx') or matNameLower:find('brassgoldfx')
            or matNameLower:find('compassgoldfx') or matNameLower:find('tempestfx') or matNameLower:find('godhumangoldfx')
            or matNameLower:find('kicyanfx') or matNameLower:find('cosmicgoldfx') or matNameLower:find('aethervioletfx')
            or matNameLower:find('overdrivemagentafx') or matNameLower:find('plasmafx') or matNameLower:find('riftmagentafx')
            or matNameLower:find('soulfirefx') or matNameLower:find('mat_kael_fx_') or matNameLower:find('mat_lyra_fx_')
        local isHandRibbonFX=(matNameLower=='sg_solarenergy' or matNameLower=='mat-ts-lightning' or matNameLower=='mat-tsf-lightning')
        local isElemFX=(meshNameStr:sub(1,7)=='Elem3D_' or matNameLower:find('mat_elem')~=nil)
        local isOrbAura=(matNameLower:find('zioles_orb_')~=nil and matNameLower:find('aura')~=nil)
        if isPureFXCage or isHandRibbonFX or isOrbAura or (isElemFX and not isFruit) then
            continue
        end
        local meshStatic=(isStatic or d.role=='Environment')
        local stripVert={}
        local keepWings=(name=='AbyssalSovereignDragon' or name=='AbyssalDragonHybrid' or name=='SunshardTemplar' or name=='AbyssalDreadknight' or name=='Noxar' or name=='RaceV4WingsSet')
        if (not meshStatic) and #h.bones>0 and d.weights then
            for i,wlist in d.weights do
                local topBone,topW=nil,0
                for _,pair in wlist do
                    if pair[2]>topW then topBone=pair[1];topW=pair[2] end
                end
                if topBone and (topBone=='FX_GroundRing' or topBone=='FX_Orbit_01' or topBone=='FX_Orbit_02' or topBone=='FX_Aura_L' or topBone=='FX_Aura_R' or (topBone=='FX_Halo' and name~='AureonSentinel') or ((not keepWings) and topBone:sub(1,5)=='Wing_')) then
                    stripVert[i]=true
                end
            end
        end
        local validTriangles={}
        for i,t in d.triangles do
            local v1,v2,v3=t[1]+1,t[2]+1,t[3]+1
            if not (stripVert[v1] or stripVert[v2] or stripVert[v3]) then
                table.insert(validTriangles,i)
            end
        end
        if #validTriangles==0 then
            continue
        end
        local low=Vector3.new(math.huge,math.huge,math.huge);local high=-low
        for _,p in d.vertices do low=low:Min(v(p));high=high:Max(v(p)) end
        local center=(low+high)/2
        local posKeys={}
        local doSmooth=(not meshStatic)
        local smoothNormals=nil
        if doSmooth then
            for i,p in d.vertices do
                posKeys[i]=string.format('%d,%d,%d',math.floor(p[1]*500+.5),math.floor(p[2]*500+.5),math.floor(p[3]*500+.5))
            end
            smoothNormals={}
            for _,ti in validTriangles do
                local t=d.triangles[ti]
                local tn=d.normals[ti]
                if tn then
                    for j=1,3 do
                        local pk=posKeys[t[j]+1]
                        local nj=tn[j]
                        if pk and nj then
                            local cur=smoothNormals[pk]
                            if cur then
                                cur[1]=cur[1]+nj[1];cur[2]=cur[2]+nj[2];cur[3]=cur[3]+nj[3]
                            else
                                smoothNormals[pk]={nj[1],nj[2],nj[3]}
                            end
                        end
                    end
                end
            end
            for pk,sn in smoothNormals do
                local mag=math.sqrt(sn[1]*sn[1]+sn[2]*sn[2]+sn[3]*sn[3])
                if mag>1e-5 then sn[1]=sn[1]/mag;sn[2]=sn[2]/mag;sn[3]=sn[3]/mag else sn[1]=0;sn[2]=1;sn[3]=0 end
            end
        end
        local TRI_CAP=18000
        local batchIdx=0
        for batchStart=1,#validTriangles,TRI_CAP do
            batchIdx+=1
            local batchEnd=math.min(#validTriangles,batchStart+TRI_CAP-1)
            local usedVerts={}
            for bidx=batchStart,batchEnd do
                local t=d.triangles[validTriangles[bidx]]
                usedVerts[t[1]+1]=true;usedVerts[t[2]+1]=true;usedVerts[t[3]+1]=true
            end
            local e=assert(Asset:CreateEditableMesh(),'Mesh allocation '..d.name)
            M.ActiveEditable=e
            local bones={}
            if not meshStatic then
                for _,b in h.bones do bones[b.name]=e:AddBone({Name=b.name,CFrame=CFrame.new(-center)*cf(b.bind_world),Virtual=false,ParentId=b.parent and bones[b.parent] or nil})end
            end
            local ids={}
            local vAdded=0
            for i,p in d.vertices do
                if usedVerts[i] then
                    local id=e:AddVertex(v(p)-center);ids[i]=id
                    if (not meshStatic) and #h.bones>0 and d.weights and d.weights[i] then
                        local joints,weights={},{};for _,pair in d.weights[i] do if bones[pair[1]] then table.insert(joints,bones[pair[1]]);table.insert(weights,pair[2]) end end
                        if #joints>0 then e:SetVertexBones(id,joints);e:SetVertexBoneWeights(id,weights) end
                    end
                    vAdded+=1
                    if vAdded%4000==0 then task.wait() end
                end
            end
            local normals,uvlookup={},{}
            for bidx=batchStart,batchEnd do
                local ti=validTriangles[bidx]
                local t=d.triangles[ti]
                local face=e:AddTriangle(ids[t[1]+1],ids[t[2]+1],ids[t[3]+1]);local ns,uvs={},{}
                for j,normal in d.normals[ti] do
                    local nx,ny,nz=normal[1],normal[2],normal[3]
                    if smoothNormals then
                        local sn=smoothNormals[posKeys[t[j]+1]]
                        if sn then
                            local dot=nx*sn[1]+ny*sn[2]+nz*sn[3]
                            if dot>=0.35 then
                                nx=sn[1]*0.85+nx*0.15;ny=sn[2]*0.85+ny*0.15;nz=sn[3]*0.85+nz*0.15
                                local m=math.sqrt(nx*nx+ny*ny+nz*nz)
                                if m>1e-5 then nx=nx/m;ny=ny/m;nz=nz/m end
                            end
                        end
                    end
                    local key=string.format('%.3f,%.3f,%.3f',nx,ny,nz)
                    if not normals[key] then normals[key]=e:AddNormal(Vector3.new(nx,ny,nz))end;ns[j]=normals[key]
                    local uv=d.uvs and d.uvs[ti] and d.uvs[ti][j] or {.5,.5};key=table.concat(uv,',');if not uvlookup[key] then uvlookup[key]=e:AddUV(Vector2.new(uv[1],uv[2]))end;uvs[j]=uvlookup[key]
                end
                e:SetFaceNormals(face,ns);e:SetFaceUVs(face,uvs)
                if (bidx-batchStart+1)%4000==0 then task.wait() end
            end
            local part=Asset:CreateMeshPartAsync(snapshot(e),{CollisionFidelity=Enum.CollisionFidelity.Box})
            -- Release the mutable builder before allocating any image/surface data.
            e:Destroy();M.ActiveEditable=nil
            part.Name=batchIdx==1 and d.name or (d.name..'_'..tostring(batchIdx));part.CFrame=CFrame.new(center);part.Anchored=true;part.CanCollide=false;part.CanQuery=false;part.CanTouch=false;part.Massless=true
            local isHandOrElemFX=(isHandRibbonFX or isElemFX)
            part:SetAttribute('SourceTriangles',batchEnd-batchStart+1);part:SetAttribute('EquipmentRole',isHandOrElemFX and 'AuraFX' or d.role)
            part:SetAttribute('BlenderMaterial',d.material.name)
            local color=mat.color_linear
            local em=mat.emission_linear or {0,0,0,1}
            local emMax=math.max(em[1] or 0,em[2] or 0,em[3] or 0)
            local isNonEmissiveSurface=matNameLower:find('gold') or matNameLower:find('marble') or matNameLower:find('stone')
                or matNameLower:find('rock') or matNameLower:find('cliff') or matNameLower:find('leaf') or matNameLower:find('foliage')
                or matNameLower:find('tree') or matNameLower:find('grass') or matNameLower:find('wood') or matNameLower:find('roof')
                or matNameLower:find('wall') or matNameLower:find('floor') or matNameLower:find('tile') or matNameLower:find('pillar')
                or matNameLower:find('stair') or matNameLower:find('brick') or matNameLower:find('hull') or matNameLower:find('sail')
                or matNameLower:find('skin') or matNameLower:find('cloth') or matNameLower:find('hair') or matNameLower:find('leather')
                or matNameLower:find('brass') or matNameLower:find('bronze') or matNameLower:find('iron') or matNameLower:find('steel')
                or matNameLower:find('canopy') or matNameLower:find('bark') or matNameLower:find('sand') or matNameLower:find('snow')
                or matNameLower:find('banner') or matNameLower:find('trim') or matNameLower:find('plaza') or matNameLower:find('arch')
            local hasEmissiveKeyword=matNameLower:find('neon') or matNameLower:find('glow') or matNameLower:find('emissive')
                or matNameLower:find('portal') or matNameLower:find('crystal') or matNameLower:find('plasma') or matNameLower:find('laser')
                or matNameLower:find('energy') or matNameLower:find('halo') or matNameLower:find('aura') or matNameLower:find('beam')
                or matNameLower:find('flame') or matNameLower:find('fire') or matNameLower:find('voidfx') or matNameLower:find('rune')
                or matNameLower:find('visor') or matNameLower:find('coreglow') or matNameLower:find('sigil') or matNameLower:find('eyecore')
                or matNameLower:find('redeyes') or matNameLower:find('timecyan') or matNameLower:find('sapphire')
                or isHandOrElemFX
            local isTrueEmissive=isHandOrElemFX or ((not isNonEmissiveSurface) and hasEmissiveKeyword and ((mat.emission_strength or 0)>=1.8 and emMax>=0.2) and (#validTriangles<=1500))
            local cr,cg,cb=srgb(color[1]),srgb(color[2]),srgb(color[3])
            if matNameLower:find('zioles_orb_fire') then cr,cg,cb=0.92,0.38,0.16
            elseif matNameLower:find('zioles_orb_frost') then cr,cg,cb=0.32,0.74,0.94
            elseif matNameLower:find('zioles_orb_light') and not matNameLower:find('lightning') then cr,cg,cb=0.92,0.76,0.28
            elseif matNameLower:find('zioles_orb_lightning') then cr,cg,cb=0.32,0.64,0.95
            elseif matNameLower:find('zioles_orb_void') then cr,cg,cb=0.62,0.28,0.92
            elseif matNameLower:find('zioles_orb_wind') then cr,cg,cb=0.28,0.84,0.56
            elseif matNameLower:find('zioles_aetherfruit_core') then cr,cg,cb=0.56,0.26,0.88
            elseif matNameLower:find('zioles_aetherfruit_swirlgold') or matNameLower:find('zioles_starcore_gem') then cr,cg,cb=0.92,0.72,0.26
            elseif matNameLower:find('zioles_aetherfruit_swirlpink') then cr,cg,cb=0.88,0.34,0.68
            elseif matNameLower:find('zioles_coat_white') then cr,cg,cb=0.72,0.74,0.80
            elseif matNameLower:find('zioles_hair_silver') then cr,cg,cb=0.76,0.78,0.84
            end
            local peak=math.max(cr,cg,cb)
            local minC=math.min(cr,cg,cb)
            if not isHandOrElemFX then
                if d.role=='Environment' then
                    if peak>0.90 then
                        local tone=0.90+(peak-0.90)*0.30
                        local scale=tone/peak
                        cr=cr*scale;cg=cg*scale;cb=cb*scale
                    end
                else
                    local isEyeWhite=matNameLower:find('eyewhite') or matNameLower:find('sclera') or matNameLower:find('catchlight') or matNameLower:find('eye_white')
                    local isDarkEyeFeature=matNameLower:find('lash') or matNameLower:find('pupil') or matNameLower:find('brow') or matNameLower:find('eyesocket') or matNameLower:find('mouth')
                    if isEyeWhite then
                        cr=0.90;cg=0.92;cb=0.95
                    else
                        cr=cr*0.95;cg=cg*0.95;cb=cb*0.95
                        peak=math.max(cr,cg,cb)
                        if matNameLower:find('hair') and peak<0.24 then
                            cr=math.max(cr*0.85+0.14,0.16);cg=math.max(cg*0.85+0.15,0.17);cb=math.max(cb*0.85+0.18,0.20)
                        elseif (not isDarkEyeFeature) and peak<0.18 then
                            cr=0.14+cr*0.75;cg=0.15+cg*0.75;cb=0.17+cb*0.80
                        elseif peak>0.84 then
                            local tone=0.80+(peak-0.84)*0.30
                            local scale=tone/peak
                            cr=cr*scale;cg=cg*scale;cb=cb*scale
                        end
                    end
                end
            end
            part.Color=Color3.new(math.clamp(cr,0,1),math.clamp(cg,0,1),math.clamp(cb,0,1))
            local metalness=mat.metalness or mat.metallic or 0
            part.Material=metalness>.5 and Enum.Material.Metal or Enum.Material.SmoothPlastic
            if metalness>.5 then
                part.Reflectance=math.clamp((1-(mat.roughness or 0.45))*0.12,0.03,0.12)
            elseif matNameLower:find('hair') then
                part.Reflectance=0.04
            elseif matNameLower:find('skin') then
                part.Reflectance=0.01
            end
            if isHandOrElemFX then
                local er,eg,eb=srgb(em[1] or 0),srgb(em[2] or 0),srgb(em[3] or 0)
                local useEm=(math.max(er,eg,eb)>=math.max(cr,cg,cb))
                local fxR=(useEm and er or cr)*0.75
                local fxG=(useEm and eg or cg)*0.75
                local fxB=(useEm and eb or cb)*0.75
                part.Color=Color3.new(math.clamp(fxR,0,1),math.clamp(fxG,0,1),math.clamp(fxB,0,1))
                part.Material=Enum.Material.SmoothPlastic;part.Reflectance=0
            elseif (not mat.maps or not next(mat.maps)) and isTrueEmissive then
                local er,eg,eb=srgb(em[1] or 0),srgb(em[2] or 0),srgb(em[3] or 0)
                local eSat=math.max(er,eg,eb)-math.min(er,eg,eb)
                local cSat=math.max(cr,cg,cb)-math.min(cr,cg,cb)
                local nr,ng,nb
                if eSat>=0.16 then
                    nr,ng,nb=er*0.78,eg*0.78,eb*0.78
                elseif cSat>=0.16 then
                    nr,ng,nb=cr*0.78,cg*0.78,cb*0.78
                end
                if nr and ng and nb then
                    part.Color=Color3.new(math.clamp(nr,0,1),math.clamp(ng,0,1),math.clamp(nb,0,1))
                    part.Material=Enum.Material.SmoothPlastic;part.Reflectance=0
                end
            elseif mat.maps and next(mat.maps) then
                if Run:IsServer() then
                    part:SetAttribute('SKYBREAK_SurfaceJSON',game.HttpService:JSONEncode(mat))
                elseif Run:IsRunning() then
                    local sa=surface(mat);if sa then sa.Parent=part;part.Color=Color3.new(1,1,1)end
                end
            end
            part.Transparency=isHandOrElemFX and 0.80 or (1-color[4]*(mat.alpha or 1));part.Parent=model
            if (not meshStatic) and #h.bones>0 then local weld=Instance.new('WeldConstraint');weld.Part0=root;weld.Part1=part;weld.Parent=part end
            if index%4==0 then task.wait() end
        end
    end
    local ELEMENTAL_AURA_COLORS={
        Fruit_GaleCore=Color3.fromRGB(90,255,195),
        Fruit_SandstoneCore=Color3.fromRGB(255,200,95),
        Fruit_SolarFlameCore=Color3.fromRGB(255,115,30),
        Fruit_GlacierIceCore=Color3.fromRGB(85,225,255),
        Fruit_CelestialLightCore=Color3.fromRGB(255,235,110),
        Fruit_StarforgedMagmaCore=Color3.fromRGB(255,65,25),
        Fruit_ThunderRumbleCore=Color3.fromRGB(70,195,255),
        Fruit_AstralGravityCore=Color3.fromRGB(185,90,255),
        Fruit_DimensionalPortalCore=Color3.fromRGB(60,230,255),
        Fruit_SolarTitanCore=Color3.fromRGB(255,215,70),
        Fruit_AetherflowCore=Color3.fromRGB(95,240,255),
        Fruit_AbyssalSovereignCore=Color3.fromRGB(165,55,255),
        Male_ThunderStriker=Color3.fromRGB(55,200,255),
        Female_ThunderStriker=Color3.fromRGB(70,210,255),
        Male_FlameSovereign=Color3.fromRGB(255,95,25),
        Female_FlameSovereign=Color3.fromRGB(255,115,35),
        Male_FrostArchon=Color3.fromRGB(90,225,255),
        Female_FrostArchon=Color3.fromRGB(115,235,255),
        Male_VoidWalker=Color3.fromRGB(180,65,255),
        Female_VoidWalker=Color3.fromRGB(195,80,255),
        Male_GaleAssassin=Color3.fromRGB(75,255,185),
        Female_GaleAssassin=Color3.fromRGB(90,255,200),
        Male_SkyGuardian=Color3.fromRGB(255,215,65),
        Female_SkyGuardian=Color3.fromRGB(255,225,85),
        Male_CrimsonCorsair=Color3.fromRGB(255,45,70),
        Female_CrimsonCorsair=Color3.fromRGB(255,60,85),
        Male_ChronoWeaver=Color3.fromRGB(65,235,255),
        Female_ChronoWeaver=Color3.fromRGB(80,245,255),
        Male_JadeMonk=Color3.fromRGB(50,255,145),
        Female_JadeMonk=Color3.fromRGB(70,255,160),
        Male_StarforgedPaladin=Color3.fromRGB(255,200,60),
        Female_StarforgedPaladin=Color3.fromRGB(255,210,80),
        Male_CyberEnforcer=Color3.fromRGB(40,225,255),
        Female_CyberEnforcer=Color3.fromRGB(55,235,255),
        Male_AbyssalReaper=Color3.fromRGB(165,45,255),
        Female_AbyssalReaper=Color3.fromRGB(180,60,255),
        WindbanditInitiate=Color3.fromRGB(85,255,185),
        WindbanditCutthroat=Color3.fromRGB(70,255,175),
        DuneMercenary=Color3.fromRGB(255,195,85),
        DuneSniper=Color3.fromRGB(255,180,65),
        SkyMarineRecruit=Color3.fromRGB(65,200,255),
        SkyMarineCaptain=Color3.fromRGB(55,190,255),
        SolarCultist=Color3.fromRGB(255,115,25),
        SolarInquisitor=Color3.fromRGB(255,95,20),
        FrostboundRaider=Color3.fromRGB(90,225,255),
        GlacierBerserker=Color3.fromRGB(75,215,255),
        VoidboundAcolyte=Color3.fromRGB(175,60,255),
        AbyssalStalker=Color3.fromRGB(160,45,255),
        Kael=Color3.fromRGB(80,255,190),
        Lyra=Color3.fromRGB(90,235,255),
        Chronos=Color3.fromRGB(70,240,255),
        DrVega=Color3.fromRGB(55,230,255),
        SkyShipwright=Color3.fromRGB(255,185,65),
        AncientMonk=Color3.fromRGB(60,255,150),
        Zioles=Color3.fromRGB(190,75,255),
        PirateCaptainVance=Color3.fromRGB(255,50,70),
        SunshardTemplar=Color3.fromRGB(255,130,30),
        CryonPrime=Color3.fromRGB(80,225,255),
        AbyssalDreadknight=Color3.fromRGB(165,45,255),
        Noxar=Color3.fromRGB(185,55,255),
        AureonSentinel=Color3.fromRGB(255,215,65),
        SolarTitanBuddha=Color3.fromRGB(255,210,55),
        AbyssalDragonHybrid=Color3.fromRGB(170,45,255),
        SoulReaperRift=Color3.fromRGB(55,230,255),
        AbyssalSovereignDragon=Color3.fromRGB(175,50,255),
        AbyssalLeviathan=Color3.fromRGB(60,215,255),
        SkySeaBeast=Color3.fromRGB(65,235,215),
        TerrorSkyShark=Color3.fromRGB(155,55,255),
        CelestialAetherGalleon=Color3.fromRGB(255,215,75),
        AncientAetherFruitTrees=Color3.fromRGB(90,245,220),
        LeviathanHunterShip=Color3.fromRGB(65,220,255),
        CyberEnforcerShip=Color3.fromRGB(50,230,255),
        ZiolesGachaShrine=Color3.fromRGB(185,70,255),
        AetherShrinesAndRaidConsole=Color3.fromRGB(70,235,255),
        MythicalWeaponsSet=Color3.fromRGB(255,195,75),
        RaceV4WingsSet=Color3.fromRGB(115,225,255),
        AetherFruitsCollection1=Color3.fromRGB(255,215,75),
        AetherFruitsCollection2=Color3.fromRGB(175,65,255),
        SkyGuardian=Color3.fromRGB(255,105,30),
        SkyGuardianFemale=Color3.fromRGB(255,115,40),
        ThunderStriker=Color3.fromRGB(55,205,255),
        ThunderStrikerFemale=Color3.fromRGB(70,215,255),
        ArcaneMage=Color3.fromRGB(175,60,255),
        GoldenKnight=Color3.fromRGB(255,215,65),
        GoldenSky=Color3.fromRGB(255,215,65),
        LightArcher=Color3.fromRGB(255,225,85),
        FrozenCyber=Color3.fromRGB(75,225,255),
        Male_Adventurer=Color3.fromRGB(75,255,180),
        Female_Adventurer=Color3.fromRGB(85,255,190),
        Male_Novice=Color3.fromRGB(255,215,80),
        Female_Novice=Color3.fromRGB(255,220,90),
        SkyPirate=Color3.fromRGB(75,255,180),
        CorruptedGuard=Color3.fromRGB(190,45,245),
        SunshardRoyalGuard=Color3.fromRGB(255,215,70),
        CyberMercenary=Color3.fromRGB(50,225,255),
        OrderCyborg=Color3.fromRGB(70,205,255),
        OrderCyborgBoss=Color3.fromRGB(70,205,255),
        FrostAutomaton=Color3.fromRGB(80,230,255),
        GlacialSniper=Color3.fromRGB(85,235,255),
        CryoVanguard=Color3.fromRGB(70,220,255),
        ArcticCorsair=Color3.fromRGB(80,230,255),
        VoidRaider=Color3.fromRGB(175,55,255),
        VoidMarauder=Color3.fromRGB(190,45,245),
        ShadowSpecter=Color3.fromRGB(155,60,255),
        UmbralRanger=Color3.fromRGB(170,55,255),
        TrainingDrone=Color3.fromRGB(255,210,70),
        MechaDrone=Color3.fromRGB(60,225,255),
        ShipwrightNPC=Color3.fromRGB(255,185,65),
        AncientMonkNPC=Color3.fromRGB(60,255,150),
        ZiolesGachaNPC=Color3.fromRGB(190,75,255),
        VanceBoss=Color3.fromRGB(255,50,70)
    }
    local prof=h.ElementalShaderProfile
    local auraColor=ELEMENTAL_AURA_COLORS[name] or (isFruit and Color3.fromRGB(95,240,255) or Color3.fromRGB(95,225,255))
    local secColor=auraColor
    if prof and prof.PrimaryColor then
        auraColor=Color3.new(math.clamp(prof.PrimaryColor[1] or 0.4,0,1),math.clamp(prof.PrimaryColor[2] or 0.85,0,1),math.clamp(prof.PrimaryColor[3] or 1.0,0,1))
    end
    if prof and prof.SecondaryColor then
        secColor=Color3.new(math.clamp(prof.SecondaryColor[1] or 0.8,0,1),math.clamp(prof.SecondaryColor[2] or 0.9,0,1),math.clamp(prof.SecondaryColor[3] or 1.0,0,1))
    end
    model:SetAttribute('ElementType',(prof and prof.ElementType) or 'AETHER')
    model:SetAttribute('PulseFrequencyHz',(prof and prof.PulseFrequencyHz) or 2.5)
    model:SetAttribute('HarmonicScaleMin',(prof and prof.HarmonicScaleMin) or 0.96)
    model:SetAttribute('HarmonicScaleMax',(prof and prof.HarmonicScaleMax) or 1.12)
    model:SetAttribute('AwakeningClip',(prof and prof.AwakeningClip) or 'UltimateAwakening')
    model:SetAttribute('KataKeyframes',(prof and prof.KataKeyframes) or 10)
    model:SetAttribute('PrimaryColorRGB',auraColor)
    model:SetAttribute('SecondaryColorRGB',secColor)
    if isFruit and auraColor then
        local rootLight=Instance.new('PointLight')
        rootLight.Name='ElementalAuraLight'
        rootLight.Color=auraColor
        rootLight.Brightness=0.22
        rootLight.Range=4
        rootLight.Shadows=false
        rootLight.Parent=root
        local pe=Instance.new('ParticleEmitter')
        pe.Name='ElementalAuraParticles'
        pe.Color=ColorSequence.new(auraColor,secColor)
        pe.LightEmission=0.15
        pe.LightInfluence=0.85
        pe.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.14),NumberSequenceKeypoint.new(0.5,0.20),NumberSequenceKeypoint.new(1,0)})
        pe.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.68),NumberSequenceKeypoint.new(0.7,0.85),NumberSequenceKeypoint.new(1,1)})
        pe.Rate=3
        pe.Lifetime=NumberRange.new(0.6,1.0)
        pe.Speed=NumberRange.new(0.8,1.8)
        pe.SpreadAngle=Vector2.new(180,180)
        pe.Parent=root
    end
    model:SetAttribute('ImportStatus','BuiltLocally');model:SetAttribute('SourceTriangles',h.triangles)
    M.Models[name]=model;return model
end
local function clientBuild(name,progress)
    return build(name,progress)
end
local ALIAS={
    GaleCore='Fruit_GaleCore',
    SandstoneCore='Fruit_SandstoneCore',
    SolarFlameCore='Fruit_SolarFlameCore',
    GlacierIceCore='Fruit_GlacierIceCore',
    CelestialLightCore='Fruit_CelestialLightCore',
    StarforgedMagmaCore='Fruit_StarforgedMagmaCore',
    ThunderRumbleCore='Fruit_ThunderRumbleCore',
    AstralGravityCore='Fruit_AstralGravityCore',
    DimensionalPortalCore='Fruit_DimensionalPortalCore',
    SolarTitanCore='Fruit_SolarTitanCore',
    AetherflowCore='Fruit_AetherflowCore',
    AbyssalSovereignCore='Fruit_AbyssalSovereignCore',
    StarlightQuakeCore='Fruit_SolarTitanCore',
    Fruit_StarlightQuakeCore='Fruit_SolarTitanCore',
    GlacialPermafrostCore='Fruit_GlacierIceCore',
    Fruit_GlacialPermafrostCore='Fruit_GlacierIceCore',
    CrimsonMagmaCore='Fruit_StarforgedMagmaCore',
    Fruit_CrimsonMagmaCore='Fruit_StarforgedMagmaCore',
    LightningTempestCore='Fruit_ThunderRumbleCore',
    Fruit_LightningTempestCore='Fruit_ThunderRumbleCore',
    CyberPhoenixCore='Fruit_SolarFlameCore',
    Fruit_CyberPhoenixCore='Fruit_SolarFlameCore',
    VoidShadowCore='Fruit_AbyssalSovereignCore',
    Fruit_VoidShadowCore='Fruit_AbyssalSovereignCore',
}
function M.Build(name,progress)
    name=ALIAS[name]or name
    if M.Models[name]then return M.Models[name]end
    if M.Jobs[name]then
        while not M.Jobs[name].Done do task.wait()end
        assert(not M.Jobs[name].Error,M.Jobs[name].Error);return assert(M.Models[name])
    end
    local job={};M.Jobs[name]=job
    while M.Building do task.wait()end
    M.Building=true
    local ok,result=xpcall(function()
        return build(name,progress)
    end,debug.traceback)
    if M.ActiveEditable then M.ActiveEditable:Destroy();M.ActiveEditable=nil end
    if not ok and M.ActiveModel then M.ActiveModel:Destroy()end
    M.ActiveModel=nil;M.Building=false
    job.Done=true;if not ok then job.Error=result;error(result)end
    return result
end
local UPRIGHT_HUMANOID_ROT={
    HumanoidRootNode=CFrame.identity,
    Root=CFrame.identity,
    LowerTorso=CFrame.identity,
    Pelvis=CFrame.identity,
    UpperTorso=CFrame.fromOrientation(math.rad(-2),0,0),
    Spine=CFrame.fromOrientation(math.rad(-1),0,0),
    Chest=CFrame.fromOrientation(math.rad(-1),0,0),
    Head=CFrame.fromOrientation(math.rad(2),0,0),
    RightUpperLeg=CFrame.fromOrientation(math.rad(-3),math.rad(180),math.rad(176)),
    LeftUpperLeg=CFrame.fromOrientation(math.rad(-3),math.rad(180),math.rad(-176)),
    ['Thigh.R']=CFrame.fromOrientation(math.rad(-3),math.rad(180),math.rad(176)),
    ['Thigh.L']=CFrame.fromOrientation(math.rad(-3),math.rad(180),math.rad(-176)),
    RightLowerLeg=CFrame.fromOrientation(math.rad(6),0,0),
    LeftLowerLeg=CFrame.fromOrientation(math.rad(6),0,0),
    ['Shin.R']=CFrame.fromOrientation(math.rad(6),0,0),
    ['Shin.L']=CFrame.fromOrientation(math.rad(6),0,0),
    RightFoot=CFrame.fromOrientation(math.rad(78),0,0),
    LeftFoot=CFrame.fromOrientation(math.rad(78),0,0),
    ['Foot.R']=CFrame.fromOrientation(math.rad(78),0,0),
    ['Foot.L']=CFrame.fromOrientation(math.rad(78),0,0),
    RightUpperArm=CFrame.fromOrientation(math.rad(-6),math.rad(172),math.rad(158)),
    LeftUpperArm=CFrame.fromOrientation(math.rad(-6),math.rad(-172),math.rad(-158)),
    ['UpperArm.R']=CFrame.fromOrientation(math.rad(-6),math.rad(172),math.rad(158)),
    ['UpperArm.L']=CFrame.fromOrientation(math.rad(-6),math.rad(-172),math.rad(-158)),
    RightLowerArm=CFrame.fromOrientation(math.rad(14),0,0),
    LeftLowerArm=CFrame.fromOrientation(math.rad(14),0,0),
    ['Forearm.R']=CFrame.fromOrientation(math.rad(14),0,0),
    ['Forearm.L']=CFrame.fromOrientation(math.rad(14),0,0),
    RightHand=CFrame.identity,
    LeftHand=CFrame.identity,
    ['Hand.R']=CFrame.identity,
    ['Hand.L']=CFrame.identity,
}
function M.Clips(name,scale)
    name=ALIAS[name]or name
    local assetFolder=Sources:FindFirstChild(name)
    local clipMod=assetFolder and assetFolder:FindFirstChild('Clips')
    local uprightBase={}
    local dragonBase={}
    local isDragonRig=(name=='AbyssalSovereignDragon')
    if assetFolder and assetFolder:FindFirstChild('Header') then
        local okH,hdr=pcall(require,assetFolder.Header)
        if okH and type(hdr)=='string' then hdr=game.HttpService:JSONDecode(hdr) end
        if okH and type(hdr)=='table' and type(hdr.bones)=='table' then
            local hasHumanoidTorso=false
            for _,b in ipairs(hdr.bones) do
                if b.name=='LowerTorso' or b.name=='Pelvis' then hasHumanoidTorso=true break end
            end
            if hasHumanoidTorso then
                for _,b in ipairs(hdr.bones) do
                    local targetRot=UPRIGHT_HUMANOID_ROT[b.name]
                    if targetRot and b['local'] then
                        local rBind=cf(b['local']).Rotation
                        uprightBase[b.name]=rBind:Inverse()*targetRot
                    end
                end
            elseif isDragonRig then
                for _,b in ipairs(hdr.bones) do
                    if b.name=='Spine_01' and b['local'] then
                        dragonBase.Spine_01=cf(b['local']).Rotation:Inverse()*CFrame.fromOrientation(math.rad(86.5),math.pi,math.pi)
                    elseif b.name=='Spine_03' and b['local'] then
                        dragonBase.Spine_03=cf(b['local']).Rotation:Inverse()*CFrame.fromOrientation(math.rad(6.5),0,0)
                    end
                end
            end
        end
    end
    local sourceList
    if clipMod then
        local raw=require(clipMod)
        if type(raw)=='string' then raw=game.HttpService:JSONDecode(raw) end
        sourceList=raw.clips or raw
    else
        local gm=game.ReplicatedStorage:FindFirstChild('GuardianMotion')
        if not gm then return nil end
        sourceList={}
        for _,m in gm:GetChildren() do
            if m:IsA('ModuleScript') then sourceList[m.Name]=require(m) end
        end
    end
    local clips={}
    for longName,data in sourceList do
        local keyName=type(longName)=='string' and longName or (data.name or tostring(longName))
        local short=keyName:match('([^|]+)$')
            :gsub('^TS_',''):gsub('^TSF_',''):gsub('^SG_',''):gsub('^SGF_',''):gsub('^AM_','')
            :gsub('^AS_',''):gsub('^CP_',''):gsub('^NX_',''):gsub('^AL_',''):gsub('^SSB_',''):gsub('^TSS_','')
            :gsub('^ST_',''):gsub('^ADH_',''):gsub('^ASD_',''):gsub('^AF1_',''):gsub('^AF2_',''):gsub('^AFT_','')
            :gsub('^Aureon_',''):gsub('^Cryon_',''):gsub('^Noxar_',''):gsub('^'..name..'_','')
            :gsub('^LightArcher_',''):gsub('^GoldenKnight_',''):gsub('^TrainingDrone_','')
        local samples=data.Samples or data.samples
        local names=data.Names or data.names
        local isIdleClip=(short=='Idle' or short=='TalkIdle' or short=='CoilIdle' or short=='IdleFloat' or short=='SacredBreezeIdle' or short=='CombatReady')
        local fps=isIdleClip and (isDragonRig and 8 or 6) or (data.FPS or data.fps or 30)
        local loop=data.Loop~=nil and data.Loop or (data.loop==true)
        if samples and names then
            local frames={}
            local numSamples=#samples
            for i,sample in samples do
                local frame={}
                local phase=((i-1)/math.max(1,numSamples-1))*math.pi*2
                local sWave=math.sin(phase)
                local cWave=math.cos(phase)
                for j,a in sample do
                    local bname=names[j]
                    local x,y,z=a[1],a[2],a[3]
                    if bname=='HumanoidRootNode' and (short=='Dash' or short=='AirDash' or short=='FlashStep' or short=='Dash_FlashStep' or short=='DaggerCombo') then x=0;z=0 end
                    if bname=='HumanoidRootNode' and (short=='Jump' or short=='DoubleJump' or short=='Jump_Air') then y=0 end
                    if isDragonRig then
                        local baseRot=dragonBase[bname] or CFrame.identity
                        local isMove=(short=='Walk' or short=='Run' or short=='Swim' or short=='Dash' or short=='AirDash' or short=='FlashStep' or short=='Jump' or short=='DoubleJump' or short=='FallLoop')
                        local isAtk=(short=='Attack' or short=='Attack01' or short=='Attack02' or short=='Attack03' or short=='DaggerCombo' or short=='Heavy' or short=='Smash' or short=='BiteCrunch' or short=='ClawCombo')
                        local isSkill=(short=='Skill' or short=='Special' or short=='Ultimate' or short=='ElementalSurge' or short=='HeroicKata' or short=='UltimateAwakening' or short=='Roar' or short=='HydroBeam')
                        if isIdleClip then
                            if bname=='Wing_L' then
                                frame[j]=CFrame.Angles(math.rad(10*sWave),math.rad(-6*cWave),math.rad(8*sWave))
                            elseif bname=='Wing_R' then
                                frame[j]=CFrame.Angles(math.rad(10*sWave),math.rad(6*cWave),math.rad(-8*sWave))
                            elseif bname=='Leg_FL' or bname=='Leg_BR' then
                                frame[j]=CFrame.Angles(math.rad(4*sWave),0,0)
                            elseif bname=='Leg_FR' or bname=='Leg_BL' then
                                frame[j]=CFrame.Angles(math.rad(-4*sWave),0,0)
                            elseif bname=='Jaw' then
                                frame[j]=CFrame.Angles(math.rad(-5-4*sWave),0,0)
                            elseif bname:sub(1,6)=='Spine_' then
                                local seg=tonumber(bname:sub(7)) or 1
                                if seg>=5 then
                                    local tWave=math.sin(phase-seg*0.55)
                                    frame[j]=baseRot*CFrame.Angles(math.rad(3*tWave),0,math.rad(7*tWave))
                                else
                                    frame[j]=baseRot*CFrame.Angles(math.rad(2*sWave),0,0)
                                end
                            elseif bname=='Neck_01' or bname=='Neck_02' or bname=='Head' then
                                frame[j]=CFrame.Angles(math.rad(3*sWave),math.rad(2*cWave),0)
                            else
                                frame[j]=baseRot
                            end
                        elseif isMove then
                            if bname=='Wing_L' then
                                frame[j]=CFrame.Angles(math.rad(34*sWave),math.rad(-16*cWave),math.rad(24*sWave))
                            elseif bname=='Wing_R' then
                                frame[j]=CFrame.Angles(math.rad(34*sWave),math.rad(16*cWave),math.rad(-24*sWave))
                            elseif bname=='Leg_FL' or bname=='Leg_BR' then
                                frame[j]=CFrame.Angles(math.rad(28*sWave),0,0)
                            elseif bname=='Leg_FR' or bname=='Leg_BL' then
                                frame[j]=CFrame.Angles(math.rad(-28*sWave),0,0)
                            elseif bname=='Jaw' then
                                frame[j]=CFrame.Angles(math.rad(-10-6*sWave),0,0)
                            elseif bname:sub(1,6)=='Spine_' then
                                local seg=tonumber(bname:sub(7)) or 1
                                local tWave=math.sin(phase-seg*0.48)
                                local amp=(seg>=5) and 12 or 5
                                frame[j]=baseRot*CFrame.Angles(math.rad(4*tWave),0,math.rad(amp*tWave))
                            elseif bname=='Neck_01' or bname=='Neck_02' or bname=='Head' then
                                frame[j]=CFrame.Angles(math.rad(-8+6*sWave),math.rad(4*cWave),0)
                            elseif bname=='HumanoidRootNode' then
                                frame[j]=CFrame.new(0,math.sin(phase)*0.22*scale,0)*CFrame.Angles(math.rad(-6+4*sWave),0,0)
                            else
                                frame[j]=baseRot*CFrame.new(x*scale,y*scale,z*scale,a[4],a[5],a[6],a[7])
                            end
                        elseif isAtk or isSkill then
                            local intensity=isSkill and 1.25 or 1.0
                            if bname=='Wing_L' then
                                frame[j]=CFrame.Angles(math.rad(42*intensity*sWave),math.rad(-22*cWave),math.rad(30*sWave))
                            elseif bname=='Wing_R' then
                                frame[j]=CFrame.Angles(math.rad(42*intensity*sWave),math.rad(22*cWave),math.rad(-30*sWave))
                            elseif bname=='Leg_FL' then
                                frame[j]=CFrame.Angles(math.rad(-42*intensity*math.max(0,sWave)+18*cWave),0,math.rad(-12*sWave))
                            elseif bname=='Leg_FR' then
                                frame[j]=CFrame.Angles(math.rad(-42*intensity*math.max(0,-sWave)-18*cWave),0,math.rad(12*sWave))
                            elseif bname=='Leg_BL' or bname=='Leg_BR' then
                                frame[j]=CFrame.Angles(math.rad(20*sWave),0,0)
                            elseif bname=='Jaw' then
                                local roar=isSkill and (28+16*math.abs(sWave)) or (22+18*math.max(0,sWave))
                                frame[j]=CFrame.Angles(math.rad(-roar),0,0)
                            elseif bname:sub(1,6)=='Spine_' then
                                local seg=tonumber(bname:sub(7)) or 1
                                local tWave=math.sin(phase-seg*0.52)
                                if seg>=5 then
                                    frame[j]=baseRot*CFrame.Angles(math.rad(8*tWave),0,math.rad(18*intensity*tWave))
                                else
                                    frame[j]=baseRot*CFrame.Angles(math.rad(12*intensity*sWave),0,math.rad(6*cWave))
                                end
                            elseif bname=='Neck_01' or bname=='Neck_02' or bname=='Head' then
                                frame[j]=CFrame.Angles(math.rad(16*intensity*sWave),math.rad(10*cWave),0)
                            else
                                frame[j]=baseRot*CFrame.new(x*scale,y*scale,z*scale,a[4],a[5],a[6],a[7])
                            end
                        else
                            frame[j]=baseRot*CFrame.new(x*scale,y*scale,z*scale,a[4],a[5],a[6],a[7])
                        end
                    elseif isIdleClip then
                        local uBase=uprightBase[bname] or CFrame.identity
                        local isPlanted=(bname=='HumanoidRootNode' or bname=='Root' or bname=='LowerTorso' or bname=='Hips' or bname=='Pelvis'
                            or bname:find('Leg')~=nil or bname:find('Foot')~=nil or bname:find('Thigh')~=nil or bname:find('Shin')~=nil)
                        if isPlanted then
                            frame[j]=uBase
                        else
                            local rawCF=CFrame.new(0,math.clamp(y*scale*0.15,-0.04,0.04),0,a[4],a[5],a[6],a[7])
                            frame[j]=uBase*CFrame.identity:Lerp(rawCF,0.16)
                        end
                    else
                        frame[j]=CFrame.new(x*scale,y*scale,z*scale,a[4],a[5],a[6],a[7])
                    end
                end
                frames[i]=frame
            end
            clips[short]={Names=names,Frames=frames,FPS=fps,Loop=loop,Duration=isIdleClip and math.max(1.8,(#frames-1)/fps) or (data.Duration or data.duration or math.max(0.05,(#frames-1)/fps)),Times=nil}
        end
    end
    -- Populate universal canonical aliases across all 45 rigged assets
    clips.Idle=clips.Idle or clips.CoilIdle or clips.IdleFloat or clips.SacredBreezeIdle or clips.CombatReady or clips.Walk or clips.Run
    clips.Walk=clips.Walk or clips.PatrolWalk or clips.SwimSurge or clips.SoarFlight or clips.Run or clips.Idle
    clips.Run=clips.Run or clips.AggroCharge or clips.SwimSurge or clips.SoarFlight or clips.Walk or clips.Idle
    clips.Swim=clips.Swim or clips.SwimSurge or clips.SoarFlight or clips.Run or clips.Walk
    clips.Jump=clips.Jump or clips.Jump_Air or clips.DoubleJump or clips.JumpStrike or clips.SkyLeap or clips.AirAscend or clips.TitanLeap or clips.Idle
    clips.DoubleJump=clips.DoubleJump or clips.Jump or clips.Jump_Air or clips.SkyLeap
    clips.FallLoop=clips.FallLoop or clips.JumpLoop or clips.WingGlide or clips.Jump
    clips.Dash=clips.Dash or clips.Dash_FlashStep or clips.AirDash or clips.FlashStep or clips.JumpStrike or clips.SkyLeap or clips.Run
    clips.AirDash=clips.AirDash or clips.Dash or clips.Dash_FlashStep or clips.FlashStep
    clips.FlashStep=clips.FlashStep or clips.Dash_FlashStep or clips.Dash or clips.AirDash
    clips.Dodge=clips.Dodge or clips.Dash or clips.Guard_Block or clips.GuardStance
    clips.Attack=clips.Attack or clips.M1_Combo or clips.M1_SlashCombo or clips.ComboAttack or clips.DaggerCombo or clips.Attack01 or clips.GreatswordCombo or clips.FrostbladeCombo or clips.VoidSlash or clips.BiteCrunch or clips.ClawCombo or clips.BiteClaw or clips.PalmCombo or clips.FrostBolt or clips.SkySlash
    clips.Attack01=clips.Attack01 or clips.Attack
    clips.Attack02=clips.Attack02 or clips.Attack
    clips.Attack03=clips.Attack03 or clips.Attack
    clips.Attack1=clips.Attack1 or clips.Attack01
    clips.Attack2=clips.Attack2 or clips.Attack02
    clips.Attack3=clips.Attack3 or clips.Attack03
    clips.DaggerCombo=clips.DaggerCombo or clips.Attack
    clips.Heavy=clips.Heavy or clips.Skill_Z or clips.HeavySkill_Z or clips.HeavySlam or clips.HeavyDown or clips.TailTsunami or clips.DivineSlash or clips.GlacialSurge or clips.HeatwaveBreath or clips.SovereignBreath or clips.HeavenlyImpact or clips.ArcaneCircle or clips.Attack
    clips.Special=clips.Special or clips.Skill_X or clips.AreaSkill_X or clips.Skill1_ElementalSlash or clips.HyperBeamBreath or clips.WrathOfAureon or clips.AbsoluteZero or clips.Phase3Judgement or clips.ThunderJudgement or clips.CelestialAegis or clips.FrostNova or clips.Heavy
    clips.Ultimate=clips.Ultimate or clips.Skill_V_Ultimate or clips.Ultimate_Cataclysm or clips.ThunderJudgement or clips.CelestialAegis or clips.FrostNova or clips.WrathOfAureon or clips.AbsoluteZero or clips.Phase3Judgement or clips.CataclysmicStarshower or clips.TwilightOfTheGods or clips.Special
    clips.HitReact=clips.HitReact or clips.HitStagger or clips.Guard_Block or clips.GuardStance or clips.Skill_C or clips.Skill2_PhaseAwaken or clips.AbyssalRoarSlam or clips.PermafrostAvalanche or clips.AbyssalCombo or clips.DoubleJump or clips.Idle
    clips.Hit=clips.Hit or clips.HitReact
    clips.Death=clips.Death or clips.DefeatCollapse or clips.Skill_V_Ultimate or clips.Skill_C or clips.HitReact or clips.Idle
    clips.CombatReady=clips.CombatReady or clips.GuardStance or clips.Guard_Block or clips.ShieldLoop or clips.Idle
    clips.Wave=clips.Wave or clips.Interact_Greeting or clips.Victory_Pose or clips.Idle
    clips.Talk=clips.Talk or clips.Interact_Greeting or clips.Wave
    clips.TalkIdle=clips.TalkIdle or clips.Idle
    clips.Cast=clips.Cast or clips.Skill_Z or clips.FrostBolt or clips.Wave
    clips.Meditate=clips.Meditate or clips.Guard_Block or clips.Victory_Pose or clips.Idle
    clips.Hammer=clips.Hammer or clips.M1_Combo or clips.Attack
    clips.HammerWork=clips.HammerWork or clips.M1_Combo or clips.Attack
    clips.HammerStrike=clips.HammerStrike or clips.Skill_Z or clips.Heavy
    clips.InspectOre=clips.InspectOre or clips.Victory_Pose or clips.Wave
    clips.Roar=clips.Roar or clips.AbyssalRoarSlam or clips.BreachSpawn or clips.Heavy
    clips.HydroBeam=clips.HydroBeam or clips.HyperBeamBreath or clips.Special
    clips.DivineSlash=clips.DivineSlash or clips.GreatswordCombo or clips.Attack
    clips.Ascend=clips.Ascend or clips.AscendPhase2 or clips.CryoAwaken or clips.Phase2Awaken or clips.Skill2_PhaseAwaken or clips.Transform or clips.AscendTransform or clips.HakiAwaken or clips.Special
    clips.IceSlash=clips.IceSlash or clips.FrostbladeCombo or clips.Attack
    clips.Smash=clips.Smash or clips.GlacialSurge or clips.Heavy
    clips.VoidSlash=clips.VoidSlash or clips.AbyssalCombo or clips.Attack
    clips.HeavyDown=clips.HeavyDown or clips.VoidSlash or clips.Heavy
    clips.TS_Idle=clips.TS_Idle or clips.Idle
    clips.TS_Run=clips.TS_Run or clips.Run
    clips.TS_Jump=clips.TS_Jump or clips.Jump
    clips.TS_DoubleJump=clips.TS_DoubleJump or clips.DoubleJump
    clips.TS_Dash=clips.TS_Dash or clips.Dash
    clips.TS_AirDash=clips.TS_AirDash or clips.AirDash
    clips.TS_DaggerCombo=clips.TS_DaggerCombo or clips.DaggerCombo
    clips.GoldenKnight_Idle=clips.GoldenKnight_Idle or clips.Idle
    clips.GoldenKnight_Run=clips.GoldenKnight_Run or clips.Run
    clips.GoldenKnight_Attack=clips.GoldenKnight_Attack or clips.Attack
    clips.GoldenKnight_Heavy=clips.GoldenKnight_Heavy or clips.Heavy
    clips.Skill=clips.Skill or clips.Special or clips.Heavy or clips.Attack
    clips.Idle=clips.Idle or clips.WorldIdle_Loop or clips.ElementalPulse or clips.CombatReady or clips.TalkIdle or clips.TS_Idle
    clips.ElementalSurge=clips.ElementalSurge or clips.HeroicKata or clips.ElementalPulse or clips.Idle
    clips.HeroicKata=clips.HeroicKata or clips.ElementalSurge or clips.Idle
    clips.UltimateAwakening=clips.UltimateAwakening or clips.Ultimate or clips.CataclysmAwakening or clips.ElementalSurge or clips.Idle
    for _,kataKey in ipairs({'ElementalSurge','HeroicKata','UltimateAwakening','WorldIdle_Loop','ElementalPulse','PortalSurge','AstrolabeSpin','CrystalResonance','TempestSway','CataclysmAwakening'}) do
        if clips[kataKey] then
            clips[kataKey].IsElementalKata=true
        end
    end
    for _,loopKey in ipairs({'Idle','Walk','Run','Swim','FallLoop','JumpLoop','CombatReady','GuardStance','ShieldLoop','TalkIdle','TS_Idle','TS_Run','PatrolWalk','AggroCharge','SwimSurge','SoarFlight','ElementalSurge','HeroicKata','UltimateAwakening','WorldIdle_Loop','ElementalPulse','PortalSurge','AstrolabeSpin','CrystalResonance','TempestSway','CataclysmAwakening'}) do
        if clips[loopKey] then
            clips[loopKey].Loop=true
        end
    end
    return clips
end
local boneCache=setmetatable({},{__mode='k'})
local fxCache=setmetatable({},{__mode='k'})
local poseState=setmetatable({},{__mode='k'})
local function getModelBones(model,root)
    local map=boneCache[model]
    if map then return map end
    map={}
    for _,d in ipairs(root:GetDescendants()) do
        if d:IsA('Bone') then
            map[d.Name]=d
        end
    end
    boneCache[model]=map
    return map
end
local function getModelFX(model,root)
    local fx=fxCache[model]
    if fx then return fx end
    fx={parts={},partLights={},auraLight=root:FindFirstChild('ElementalAuraLight')}
    for _,ch in ipairs(model:GetChildren()) do
        if ch:IsA('MeshPart') and (ch.Name:sub(1,7)=='Elem3D_' or ch:GetAttribute('EquipmentRole')=='AuraFX') then
            table.insert(fx.parts,{part=ch,baseColor=ch.Color})
            local pl=ch:FindFirstChild('ElementalPartLight')
            if pl and pl:IsA('PointLight') then
                table.insert(fx.partLights,pl)
            end
        end
    end
    fxCache[model]=fx
    return fx
end
local function pulseElementalFX(model,root,clip,time)
    local fx=getModelFX(model,root)
    if not fx.auraLight and #fx.partLights==0 and #fx.parts==0 then return end
    local freq=model:GetAttribute('PulseFrequencyHz') or 2.5
    local sMin=model:GetAttribute('HarmonicScaleMin') or 0.96
    local sMax=model:GetAttribute('HarmonicScaleMax') or 1.12
    local pCol=model:GetAttribute('PrimaryColorRGB')
    local sCol=model:GetAttribute('SecondaryColorRGB')
    local wave=0.5+0.5*math.sin((time or 0)*freq*math.pi*2)
    local boost=(clip and clip.IsElementalKata) and 1.18 or 1.0
    local harmonic=(sMin+(sMax-sMin)*wave)*boost
    if fx.auraLight then
        fx.auraLight.Brightness=0.18*harmonic
        fx.auraLight.Range=5*harmonic
    end
    for _,pl in ipairs(fx.partLights) do
        pl.Brightness=0.15*harmonic
        pl.Range=4*harmonic
    end
    for idx,entry in ipairs(fx.parts) do
        local pt=entry.part
        if pt and pt.Parent then
            local phaseWave=0.5+0.5*math.sin((time or 0)*freq*math.pi*2+idx*0.45)
            pt.Transparency=math.clamp(0.78-0.06*phaseWave,0.70,0.88)
            if pCol and sCol then
                pt.Color=entry.baseColor:Lerp(sCol,0.18*phaseWave)
            end
        end
    end
end
function M.Pose(model,clip,time)
    if not model or not clip or not clip.Frames or #clip.Frames==0 then return end
    local root=model.PrimaryPart
    if not root then return end
    local bones=getModelBones(model,root)
    if not next(bones) then return end
    local st=poseState[model]
    local now=os.clock()
    if not st then
        st={clip=clip,switchAt=0}
        poseState[model]=st
    elseif st.clip~=clip then
        st.clip=clip
        st.switchAt=now
    end
    local blend=(st.switchAt>0 and (now-st.switchAt)<0.18) and math.clamp((now-st.switchAt)/0.18,0.22,1) or 1
    local numFrames=#clip.Frames
    if numFrames==1 then
        local f1=clip.Frames[1]
        if not f1 then return end
        for n,name in clip.Names do
            local bone=bones[name]
            if bone and f1[n] then
                bone.Transform=blend<1 and bone.Transform:Lerp(f1[n],blend) or f1[n]
            end
        end
        return
    end
    local f=clip.Loop and ((time*clip.FPS)%(numFrames-1)+1) or math.min(numFrames,time*clip.FPS+1)
    if f~=f then f=1 end
    local i=math.clamp(math.floor(f),1,numFrames)
    local j=math.clamp(i+1,1,numFrames)
    local alpha=math.clamp(f-i,0,1)
    local fi=clip.Frames[i];local fj=clip.Frames[j]
    if not fi or not fj then return end
    for n,name in clip.Names do
        local bone=bones[name]
        if bone and fi[n] and fj[n] then
            local target=fi[n]:Lerp(fj[n],alpha)
            bone.Transform=blend<1 and bone.Transform:Lerp(target,blend) or target
        end
    end
end
M.CanonicalClips={'Idle','Walk','Run','Attack','Skill','ElementalSurge','HeroicKata','UltimateAwakening'}
M.CrossfadeDuration=0.18
return M

