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
local function hexRGB(h)
    h=h:gsub('#','')
    return {
        tonumber(h:sub(1,2),16)/255,
        tonumber(h:sub(3,4),16)/255,
        tonumber(h:sub(5,6),16)/255,
    }
end
local function rampStops(list)
    local out={}
    for i,s in ipairs(list) do out[i]={s[1],hexRGB(s[2])} end
    return out
end
local function pbrStops(dHex,mHex,lHex)
    return rampStops({{0.12,dHex},{0.50,mHex},{0.88,lHex}})
end
local FRUIT_SHADER_SPECS={
    -- Shared Gold & Silver Trim
    BrightGold={mode='METAL',stops=pbrStops('#9A5C0E','#EAA220','#FFE678'),scale=10.0,boost=1.05,refl=0.10},
    BrushedGold={mode='METAL',stops=pbrStops('#7E480A','#D0881C','#F6C850'),scale=10.0,boost=1.03,refl=0.08},
    SilverWing={mode='FRESNEL',stops=pbrStops('#7A8CA8','#D0DDF0','#FFFFFF'),scale=8.0,boost=1.04,refl=0.08},
    SilverShadow={mode='FRESNEL',stops=pbrStops('#4C5C78','#8498B8','#C2D4EC'),scale=8.0,boost=1.02,refl=0.06},
    -- Fruit 1: Gale / Tempest
    GaleVortexSphere={mode='VORTEX',stops=rampStops({{0.00,'#D8FFF4'},{0.18,'#28FFD0'},{0.38,'#04B888'},{0.58,'#027454'},{0.82,'#013226'}}),wave='DIAG',scale=4.2,weight=0.23,boost=1.08,refl=0.02},
    GaleFacetDark={mode='FRESNEL',stops=pbrStops('#023228','#067A5C','#18D0A0'),scale=5.0,boost=1.06,refl=0.06},
    GaleRibbonEmit={mode='PLASMA',stops=pbrStops('#069874','#20F0C0','#B0FFF4'),scale=5.2,boost=1.12,refl=0.0},
    -- Fruit 2: Quake / Sandstone
    QuakeCoreEmit={mode='PLASMA',stops=pbrStops('#D47C0A','#FFC22C','#FFF8A8'),scale=5.2,boost=1.14,refl=0.0},
    QuakeRockGold={mode='FRESNEL',stops=pbrStops('#623608','#BE7418','#F6BC42'),scale=6.5,boost=1.04,refl=0.06},
    QuakeRingStone={mode='FRESNEL',stops=pbrStops('#78460C','#D28C22','#FCD060'),scale=7.0,boost=1.05,refl=0.06},
    -- Fruit 3: Solar Flame
    FlameVortexCore={mode='VORTEX',stops=rampStops({{0.00,'#FFF698'},{0.20,'#FF9E10'},{0.42,'#F83C06'},{0.68,'#B01204'},{0.88,'#5E0400'}}),wave='DIAG',scale=4.5,weight=0.23,boost=1.10,refl=0.02},
    FlameCrimson={mode='PLASMA',stops=pbrStops('#680602','#C81808','#FF4212'),scale=6.2,boost=1.06,refl=0.02},
    FlameOrangeGold={mode='PLASMA',stops=pbrStops('#A42804','#F8640C','#FFCA2C'),scale=6.2,boost=1.08,refl=0.02},
    FlameYellowTip={mode='PLASMA',stops=pbrStops('#E05006','#FF9614','#FFEC68'),scale=5.5,boost=1.12,refl=0.0},
    -- Fruit 4: Glacier Ice
    FrostCrystalBody={mode='VORTEX',stops=rampStops({{0.00,'#98F6FF'},{0.22,'#42CCFF'},{0.52,'#0E66DE'},{0.84,'#04206E'}}),wave='DIAG',scale=4.6,weight=0.25,boost=1.08,refl=0.08},
    FrostSpikeCyan={mode='FRESNEL',stops=pbrStops('#0A42AC','#2492FF','#98F0FF'),scale=4.2,boost=1.08,refl=0.08},
    FrostIceLight={mode='PLASMA',stops=pbrStops('#187CF0','#52CCFF','#D4FCFF'),scale=5.0,boost=1.12,refl=0.02},
    FrostSnowCap={mode='FRESNEL',stops=pbrStops('#849EC6','#D4E6FC','#FFFFFF'),scale=8.0,boost=1.04,refl=0.05},
    -- Fruit 5: Celestial Light
    AstralCoreWhite={mode='PLASMA',stops=pbrStops('#F0A220','#FFE678','#FFFFF0'),scale=4.6,boost=1.16,refl=0.0},
    AstralStarRay={mode='FRESNEL',stops=pbrStops('#AA6814','#F4B236','#FFF6B4'),scale=4.8,boost=1.08,refl=0.08},
    AstralStarSide={mode='FRESNEL',stops=pbrStops('#864C0C','#D69024','#FCD672'),scale=4.8,boost=1.06,refl=0.08},
    -- Fruit 6: Starforged Magma
    MagmaLavaCore={mode='VORTEX',stops=rampStops({{0.00,'#FFF074'},{0.24,'#FF880C'},{0.50,'#EC2C04'},{0.76,'#920A00'},{0.92,'#400200'}}),wave='DIAG',scale=4.2,weight=0.24,boost=1.12,refl=0.02},
    CharredBasalt={mode='FRESNEL',stops=pbrStops('#0E080A','#221416','#402426'),scale=8.0,boost=1.0,refl=0.03},
    BasaltRimHot={mode='FRESNEL',stops=pbrStops('#2E100E','#842212','#EC4616'),scale=8.0,boost=1.10,refl=0.04},
    -- Fruit 7: Thunder Rumble
    CobaltCloud={mode='FRESNEL',stops=pbrStops('#0A2278','#1C4ED0','#4886FF'),scale=10.0,boost=1.06,refl=0.05},
    CobaltCloudLight={mode='FRESNEL',stops=pbrStops('#163CA8','#2C70F4','#78B8FF'),scale=10.0,boost=1.08,refl=0.06},
    RumbleArcEmit={mode='PLASMA',stops=pbrStops('#20B2FF','#84F4FF','#FFFFFF'),scale=5.2,boost=1.18,refl=0.0},
    -- Fruit 8: Astral Gravity
    GravityGalaxy={mode='VORTEX',stops=rampStops({{0.00,'#FFFFFF'},{0.14,'#EE9EFF'},{0.34,'#A842FF'},{0.58,'#5414B4'},{0.84,'#1C0844'}}),wave='HORIZ',scale=5.0,weight=0.25,boost=1.14,refl=0.02},
    GravityRingEmit={mode='PLASMA',stops=pbrStops('#922CF0','#E674FF','#FFF0FF'),scale=5.0,boost=1.16,refl=0.0},
    GravityRock={mode='FRESNEL',stops=pbrStops('#1A122C','#342650','#5C4484'),scale=10.0,boost=1.04,refl=0.05},
    -- Fruit 9: Dimensional Portal
    PortalVortex={mode='VORTEX',stops=rampStops({{0.00,'#120834'},{0.22,'#6420E4'},{0.42,'#C274FF'},{0.62,'#20A4FF'},{0.85,'#082058'}}),wave='DIAG',scale=5.2,weight=0.26,boost=1.14,refl=0.02},
    PortalSilver={mode='METAL',stops=pbrStops('#8298B4','#D2E2F6','#FFFFFF'),scale=12.0,boost=1.05,refl=0.12},
    PortalCyanEmit={mode='PLASMA',stops=pbrStops('#08A4FF','#48F0FF','#E2FFFF'),scale=5.0,boost=1.18,refl=0.0},
    -- Fruit 10: Solar Titan / Buddha
    SolarPearlCore={mode='VORTEX',stops=rampStops({{0.00,'#FFFFFF'},{0.26,'#FFF6A4'},{0.55,'#FFCA32'},{0.85,'#F0800C'}}),wave='VERT',scale=3.8,weight=0.20,boost=1.16,refl=0.02},
    LotusPearl={mode='FRESNEL',stops=pbrStops('#DFBC72','#FEF0CC','#FFFFFF'),scale=10.0,boost=1.06,refl=0.08},
    HaloSolarEmit={mode='PLASMA',stops=pbrStops('#F0A220','#FFE054','#FFFFE2'),scale=5.2,boost=1.16,refl=0.0},
    -- Fruit 11: Aetherflow / Dough
    DoughSwirlCore={mode='VORTEX',stops=rampStops({{0.00,'#FFFDF6'},{0.22,'#FF72EC'},{0.45,'#A220F0'},{0.68,'#FFF6E4'},{0.90,'#D230E0'}}),wave='SWIRL',scale=4.5,weight=0.26,boost=1.12,refl=0.02},
    MochiCream={mode='FRESNEL',stops=pbrStops('#DEC4B4','#FAF0E8','#FFFFFF'),scale=10.0,boost=1.05,refl=0.06},
    BerryGlazeEmit={mode='PLASMA',stops=pbrStops('#8416D4','#F232F0','#FFC4FF'),scale=5.8,boost=1.14,refl=0.0},
    DropletGold={mode='PLASMA',stops=pbrStops('#E09230','#FCE088','#FFFFF0'),scale=5.0,boost=1.12,refl=0.02},
    -- Fruit 12: Abyssal Sovereign / Kitsune
    DemonCoreEmit={mode='PLASMA',stops=pbrStops('#B8062E','#FF2058','#FFA4C4'),scale=5.5,boost=1.20,refl=0.0},
    DragonObsidian={mode='FRESNEL',stops=pbrStops('#0A0610','#1C102C','#3C205C'),scale=10.0,boost=1.02,refl=0.08},
    DragonScaleViol={mode='FRESNEL',stops=pbrStops('#180A26','#381656','#702898'),scale=10.0,boost=1.04,refl=0.08},
    DemonWingRed={mode='PLASMA',stops=pbrStops('#580618','#C81232','#FF3658'),scale=5.8,boost=1.08,refl=0.02},
    -- AncientAetherFruitTrees & ZiolesGachaShrine Orbs/Foliage
    SlateRock={mode='FRESNEL',stops=pbrStops('#2A2826','#4A4642','#6E6860'),scale=10.0,boost=1.0,refl=0.02},
    SandstoneAltar={mode='FRESNEL',stops=pbrStops('#6E5840','#9E8466','#C8B090'),scale=10.0,boost=1.0,refl=0.02},
    IvoryBark={mode='METAL',stops=pbrStops('#A89680','#DECDB8','#F8EFE2'),scale=10.0,boost=1.02,refl=0.03},
    SolarLeafDark={mode='FRESNEL',stops=pbrStops('#9E4804','#DC780A','#FFA818'),scale=7.0,boost=1.06,refl=0.04},
    SolarLeafMid={mode='FRESNEL',stops=pbrStops('#C46808','#F8A414','#FFD438'),scale=7.0,boost=1.08,refl=0.04},
    SolarLeafBright={mode='PLASMA',stops=pbrStops('#D87A08','#FFB81C','#FFEE68'),scale=5.0,boost=1.12,refl=0.0},
    SunGlow={mode='PLASMA',stops=pbrStops('#C86204','#FFA814','#FFE858'),scale=4.8,boost=1.14,refl=0.0},
    AmberCrystal={mode='PLASMA',stops=pbrStops('#B84C04','#FF9210','#FFE048'),scale=4.5,boost=1.12,refl=0.04},
    LeafGreen={mode='FRESNEL',stops=pbrStops('#185814','#329824','#68D842'),scale=8.0,boost=1.05,refl=0.03},
    CryoRock={mode='FRESNEL',stops=pbrStops('#1A2232','#2E3C54','#4A5E80'),scale=10.0,boost=1.0,refl=0.03},
    CryoBark={mode='METAL',stops=pbrStops('#1E283A','#364864','#587298'),scale=10.0,boost=1.02,refl=0.05},
    BrushedSteel={mode='METAL',stops=pbrStops('#384860','#6880A0','#9EB4D2'),scale=12.0,boost=1.04,refl=0.10},
    IceCrystalDark={mode='FRESNEL',stops=pbrStops('#08388C','#1678D8','#48B8FF'),scale=5.0,boost=1.08,refl=0.08},
    IceCrystalMid={mode='FRESNEL',stops=pbrStops('#0E58B8','#24A4F8','#78E2FF'),scale=5.0,boost=1.10,refl=0.08},
    CyanGlow={mode='PLASMA',stops=pbrStops('#0068D8','#18C8FF','#88F4FF'),scale=4.8,boost=1.14,refl=0.0},
    HoloCyan={mode='PLASMA',stops=pbrStops('#1498F8','#48E4FF','#C8FFFF'),scale=4.8,boost=1.16,refl=0.0},
    ObsidianBark={mode='METAL',stops=pbrStops('#0E0C16','#1E1A2C','#342C48'),scale=10.0,boost=1.02,refl=0.04},
    DarkIron={mode='METAL',stops=pbrStops('#12101A','#242034','#3E3856'),scale=12.0,boost=1.02,refl=0.08},
    AmethystDark={mode='FRESNEL',stops=pbrStops('#2E0658','#6412A8','#A828E8'),scale=5.5,boost=1.08,refl=0.08},
    AmethystMid={mode='FRESNEL',stops=pbrStops('#4A0A82','#9418D8','#DC48FF'),scale=5.5,boost=1.10,refl=0.08},
    MagentaGlow={mode='PLASMA',stops=pbrStops('#7808B8','#D818FF','#FF68F8'),scale=4.8,boost=1.14,refl=0.0},
    CrimsonLava={mode='PLASMA',stops=pbrStops('#880418','#E81038','#FF5878'),scale=4.8,boost=1.14,refl=0.0},
    PrismaticOrb={mode='VORTEX',stops=rampStops({{0.10,'#FFFCE0'},{0.24,'#38FAFF'},{0.38,'#00D8FF'},{0.52,'#FF2EC4'},{0.68,'#2474FF'},{0.84,'#6028FF'}}),wave='SWIRL',scale=4.2,weight=0.28,boost=1.16,refl=0.04},
    -- ZiolesGachaShrine Architecture & Gems
    TableSapphire={mode='METAL',stops=pbrStops('#0A2468','#1648B8','#2E78F0'),scale=8.0,boost=1.05,refl=0.08},
    SapphireGlass={mode='FRESNEL',stops=pbrStops('#0A3080','#1A62D4','#4CA8FF'),scale=6.0,boost=1.08,refl=0.10},
    PillarCrystal={mode='FRESNEL',stops=pbrStops('#1050BC','#2E92F8','#88E0FF'),scale=5.5,boost=1.10,refl=0.08},
    StarlightGold={mode='PLASMA',stops=pbrStops('#FFD458','#FFF2A8','#FFFFFF'),scale=5.0,boost=1.16,refl=0.02},
    MagentaGem={mode='PLASMA',stops=pbrStops('#8814D8','#E828FF','#FF88F4'),scale=5.2,boost=1.14,refl=0.04},
    -- MythicalWeaponsSet (Wep_*)
    WhiteEnamel={mode='FRESNEL',stops=pbrStops('#C8D2E2','#EEF4FC','#FFFFFF'),scale=8.0,boost=1.04,refl=0.06},
    SilverBlade={mode='METAL',stops=pbrStops('#A8B6CC','#E0EAF8','#FFFFFF'),scale=10.0,boost=1.06,refl=0.14},
    RoyalBlue={mode='FRESNEL',stops=pbrStops('#0A1C4E','#16388C','#2C5CC8'),scale=7.5,boost=1.05,refl=0.05},
    CobaltArmor={mode='METAL',stops=pbrStops('#081E58','#1642A8','#2C6CE0'),scale=9.0,boost=1.06,refl=0.08},
    FrostMetal={mode='METAL',stops=pbrStops('#121A2C','#223250','#3A527A'),scale=9.0,boost=1.04,refl=0.08},
    IceBladeDeep={mode='FRESNEL',stops=pbrStops('#062C78','#1462D4','#48A8FF'),scale=5.5,boost=1.08,refl=0.08},
    IceCrystal={mode='FRESNEL',stops=pbrStops('#0C4EB8','#2490F8','#78DCFF'),scale=5.0,boost=1.10,refl=0.08},
    CyanCore={mode='PLASMA',stops=pbrStops('#0078E8','#18C8FF','#88F4FF'),scale=4.8,boost=1.16,refl=0.0},
    CyanArc={mode='PLASMA',stops=pbrStops('#18A8FF','#58E8FF','#C8FFFF'),scale=5.0,boost=1.18,refl=0.0},
    SolarBlade={mode='PLASMA',stops=pbrStops('#D8820E','#FFBC28','#FFEE88'),scale=5.2,boost=1.14,refl=0.04},
    SunCore={mode='PLASMA',stops=pbrStops('#E48A10','#FFC832','#FFF498'),scale=4.8,boost=1.16,refl=0.0},
    VoidBlade={mode='METAL',stops=pbrStops('#10081E','#241442','#422472'),scale=9.0,boost=1.06,refl=0.08},
    PurpleNeon={mode='PLASMA',stops=pbrStops('#5C10C0','#9828FF','#D880FF'),scale=5.0,boost=1.16,refl=0.0},
    VolcanicRock={mode='FRESNEL',stops=pbrStops('#120E16','#221C28','#3A3044'),scale=8.5,boost=1.02,refl=0.03},
    Gunmetal={mode='METAL',stops=pbrStops('#12161E','#222A38','#384458'),scale=10.0,boost=1.04,refl=0.08},
    CrimsonCore={mode='PLASMA',stops=pbrStops('#980614','#F41428','#FF6070'),scale=5.0,boost=1.16,refl=0.0},
    LavaEdge={mode='PLASMA',stops=pbrStops('#B42004','#F8580C','#FFB028'),scale=5.2,boost=1.14,refl=0.02},
    LavaCore={mode='PLASMA',stops=pbrStops('#D83208','#FF7810','#FFD848'),scale=4.8,boost=1.16,refl=0.0},
    MagentaCore={mode='PLASMA',stops=pbrStops('#9C0A68','#F818A8','#FF78DC'),scale=5.0,boost=1.16,refl=0.0},
    BoneSkull={mode='FRESNEL',stops=pbrStops('#C8C2D6','#ECE8F6','#FFFFFF'),scale=7.5,boost=1.04,refl=0.04},
    -- RaceV4WingsSet (Wing_*)
    WhiteFeather={mode='FRESNEL',stops=pbrStops('#E8E0D4','#FAF6EC','#FFFFFF'),scale=7.5,boost=1.06,refl=0.04},
    WhiteMecha={mode='FRESNEL',stops=pbrStops('#C8D4E6','#EEF4FC','#FFFFFF'),scale=8.5,boost=1.05,refl=0.06},
    AzureMembrane={mode='FRESNEL',stops=pbrStops('#062A78','#1462D8','#48AEFF'),scale=6.0,boost=1.08,refl=0.06},
    ObsidianBone={mode='METAL',stops=pbrStops('#0C0810','#181020','#2A1C36'),scale=9.0,boost=1.04,refl=0.06},
    CrimsonMembrane={mode='PLASMA',stops=pbrStops('#0E0103','#52040C','#B40C1C'),scale=5.5,boost=1.10,refl=0.02},
    DracoMembrane={mode='PLASMA',stops=pbrStops('#1E0302','#6E0C08','#D01E12'),scale=5.5,boost=1.10,refl=0.02},
    RubyCrystal={mode='FRESNEL',stops=pbrStops('#58040C','#B80C1C','#FF384C'),scale=5.5,boost=1.10,refl=0.08},
    DragonGold={mode='METAL',stops=pbrStops('#9A6010','#DE9824','#FFCE58'),scale=10.0,boost=1.05,refl=0.08},
    FlameOuter={mode='PLASMA',stops=pbrStops('#A81404','#F43E08','#FF8818'),scale=5.2,boost=1.14,refl=0.0},
    FlameCore={mode='PLASMA',stops=pbrStops('#DE5806','#FFA418','#FFEE68'),scale=4.8,boost=1.16,refl=0.0},
    -- AetherShrinesAndRaidConsole
    WhiteMarble={mode='FRESNEL',stops=pbrStops('#B8B2A8','#E6E0D6','#FAF8F4'),scale=9.0,boost=1.03,refl=0.04},
    SolarCyanPool={mode='PLASMA',stops=pbrStops('#086898','#24C8E8','#98F8FF'),scale=5.0,boost=1.14,refl=0.04},
    CryoSteel={mode='METAL',stops=pbrStops('#182234','#2E3E58','#4C6488'),scale=10.0,boost=1.04,refl=0.08},
    CryoStone={mode='FRESNEL',stops=pbrStops('#243044','#3E506E','#627A9E'),scale=9.0,boost=1.02,refl=0.03},
    SnowWhite={mode='FRESNEL',stops=pbrStops('#98B0C8','#C8DCF0','#F0F8FF'),scale=8.0,boost=1.04,refl=0.04},
    ObsidianStone={mode='FRESNEL',stops=pbrStops('#0E0C16','#1E1A2C','#342C48'),scale=9.0,boost=1.02,refl=0.04},
    VoidAmethyst={mode='FRESNEL',stops=pbrStops('#2E0658','#6810A8','#B428F0'),scale=5.5,boost=1.10,refl=0.08},
    CrimsonGlow={mode='PLASMA',stops=pbrStops('#880418','#E81038','#FF5878'),scale=5.0,boost=1.14,refl=0.0},
    TechGunmetal={mode='METAL',stops=pbrStops('#141C2B','#24324A','#3C5072'),scale=10.0,boost=1.04,refl=0.08},
    BtnRed={mode='PLASMA',stops=pbrStops('#8E0808','#F01818','#FF6858'),scale=5.0,boost=1.14,refl=0.0},
    BtnBlue={mode='PLASMA',stops=pbrStops('#0848A8','#1894FF','#78D8FF'),scale=5.0,boost=1.14,refl=0.0},
    BtnGreen={mode='PLASMA',stops=pbrStops('#087824','#18DC48','#78FF98'),scale=5.0,boost=1.14,refl=0.0},
    BtnYellow={mode='PLASMA',stops=pbrStops('#A86204','#FFA814','#FFE868'),scale=5.0,boost=1.14,refl=0.0},
    BtnPurple={mode='PLASMA',stops=pbrStops('#580898','#B418FF','#E878FF'),scale=5.0,boost=1.14,refl=0.0},
    -- Ships (CelestialAetherGalleon, CyberEnforcerShip, LeviathanHunterShip)
    MahoganyWood={mode='FRESNEL',stops=pbrStops('#260E04','#54220B','#823B18'),scale=9.0,boost=1.02,refl=0.03},
    LightDeckWood={mode='FRESNEL',stops=pbrStops('#42200C','#6E3A1A','#98562C'),scale=9.0,boost=1.02,refl=0.02},
    WhiteCeramic={mode='FRESNEL',stops=pbrStops('#C2B6A4','#E6DCD0','#F8F2E8'),scale=8.5,boost=1.04,refl=0.05},
    CyanSail={mode='PLASMA',stops=pbrStops('#06328C','#14A8FF','#68ECFF'),scale=5.5,boost=1.12,refl=0.02},
    SailGold={mode='PLASMA',stops=pbrStops('#9E620C','#EEAC24','#FFD448'),scale=5.5,boost=1.10,refl=0.04},
    AmberGlow={mode='PLASMA',stops=pbrStops('#7A1800','#E85000','#FF9400'),scale=5.0,boost=1.14,refl=0.0},
    RoyalBlueArmor={mode='METAL',stops=pbrStops('#0B2058','#163B92','#285CC8'),scale=9.0,boost=1.05,refl=0.08},
    RoyalBlueCloth={mode='FRESNEL',stops=pbrStops('#0D2462','#1A42A2','#2C64D8'),scale=7.5,boost=1.04,refl=0.03},
    DarkGunmetal={mode='METAL',stops=pbrStops('#101420','#1C2232','#2E3850'),scale=10.0,boost=1.04,refl=0.08},
    CyanWing={mode='PLASMA',stops=pbrStops('#002B8C','#0074E8','#00ECFF'),scale=5.2,boost=1.14,refl=0.02},
    CyanPlasma={mode='PLASMA',stops=pbrStops('#0038A8','#00A2FF','#00EEFF'),scale=4.8,boost=1.16,refl=0.0},
    DeepCobaltCore={mode='PLASMA',stops=pbrStops('#001E78','#0058D8','#00C8FF'),scale=5.0,boost=1.14,refl=0.02},
    ObsidianArmor={mode='METAL',stops=pbrStops('#100E18','#1C1928','#2E2A40'),scale=10.0,boost=1.04,refl=0.08},
    DarkWood={mode='FRESNEL',stops=pbrStops('#1C100B','#341E15','#502E20'),scale=9.0,boost=1.02,refl=0.02},
    AntiqueGold={mode='METAL',stops=pbrStops('#8A5C16','#C88C28','#EEAC46'),scale=10.0,boost=1.04,refl=0.08},
    DragonIvory={mode='FRESNEL',stops=pbrStops('#B28232','#E6B85C','#FFF0B8'),scale=7.5,boost=1.04,refl=0.04},
    CrimsonSail={mode='FRESNEL',stops=pbrStops('#28030A','#5E0718','#940E28'),scale=7.5,boost=1.04,refl=0.03},
    PurpleBanner={mode='FRESNEL',stops=pbrStops('#260E28','#48184A','#6E246E'),scale=7.5,boost=1.04,refl=0.03},
    CrimsonSigil={mode='PLASMA',stops=pbrStops('#680412','#D40E28','#FF1E3A'),scale=5.0,boost=1.14,refl=0.0},
    VoidCrystal={mode='PLASMA',stops=pbrStops('#220262','#7C0CF0','#D848FF'),scale=5.0,boost=1.14,refl=0.04},
    VioletPlasma={mode='PLASMA',stops=pbrStops('#4800B8','#9800FF','#E018FF'),scale=4.8,boost=1.16,refl=0.0},
    MagentaMaw={mode='PLASMA',stops=pbrStops('#800058','#DF00A8','#FF18C8'),scale=4.8,boost=1.16,refl=0.0},
    -- Transformations (SolarTitanBuddha, AbyssalSovereignDragon, AbyssalDragonHybrid)
    WhiteArmor={mode='FRESNEL',stops=pbrStops('#D4CCBA','#EFE8D8','#FCF8F0'),scale=8.5,boost=1.04,refl=0.06},
    TitanSkin={mode='FRESNEL',stops=pbrStops('#CEBA9E','#EAD6BA','#F8E8D0'),scale=8.0,boost=1.03,refl=0.03},
    Gold={mode='METAL',stops=pbrStops('#A8741C','#DE9E2C','#F6C254'),scale=10.0,boost=1.05,refl=0.08},
    GoldenHair={mode='FRESNEL',stops=pbrStops('#C2861C','#F0B83C','#FFE074'),scale=7.5,boost=1.06,refl=0.04},
    SapphireGem={mode='FRESNEL',stops=pbrStops('#1042A8','#2472E8','#74B8FF'),scale=5.5,boost=1.08,refl=0.08},
    CyanEye={mode='PLASMA',stops=pbrStops('#0062C4','#00ACFA','#18D8FF'),scale=4.8,boost=1.16,refl=0.0},
    EyeDark={mode='FRESNEL',stops=pbrStops('#14100C','#241C14','#382C20'),scale=8.0,boost=1.0,refl=0.02},
    ObsidianScale={mode='METAL',stops=pbrStops('#0A0714','#1C1432','#402E68'),scale=9.5,boost=1.05,refl=0.08},
    ObsidianDark={mode='METAL',stops=pbrStops('#05030B','#120C22','#2A1D48'),scale=9.5,boost=1.04,refl=0.06},
    MagmaUndercoat={mode='PLASMA',stops=pbrStops('#0E0918','#E81268','#FF5814'),scale=5.2,boost=1.14,refl=0.02},
    MagmaObsidian={mode='PLASMA',stops=pbrStops('#0E0918','#E81268','#FF5814'),scale=5.2,boost=1.14,refl=0.02},
    SilverTrim={mode='METAL',stops=pbrStops('#2C2044','#584680','#A492D0'),scale=10.0,boost=1.05,refl=0.08},
    SilverFur={mode='FRESNEL',stops=pbrStops('#BAC4DC','#E6ECF8','#FFFFFF'),scale=7.5,boost=1.05,refl=0.04},
    SilverHair={mode='FRESNEL',stops=pbrStops('#BAC4DC','#E8EEF8','#FFFFFF'),scale=7.5,boost=1.05,refl=0.04},
    PaleSkin={mode='FRESNEL',stops=pbrStops('#DCAEA0','#F2CBB8','#FFE2D4'),scale=8.0,boost=1.03,refl=0.02},
    MagmaCrack={mode='PLASMA',stops=pbrStops('#580420','#D41450','#FF4C86'),scale=5.0,boost=1.16,refl=0.0},
    MoltenOrange={mode='PLASMA',stops=pbrStops('#6C0A04','#E2300A','#FF7424'),scale=5.0,boost=1.16,refl=0.0},
    CrimsonGem={mode='FRESNEL',stops=pbrStops('#880624','#E61244','#FF5482'),scale=5.5,boost=1.10,refl=0.08},
    MagentaCrystal={mode='FRESNEL',stops=pbrStops('#6808A8','#CC14A2','#FA4AD2'),scale=5.5,boost=1.10,refl=0.08},
    HotStarCore={mode='PLASMA',stops=pbrStops('#540438','#CC1484','#FF58B8'),scale=4.8,boost=1.16,refl=0.0},
    StarPinpoint={mode='PLASMA',stops=pbrStops('#982068','#F468C0','#FFD8F4'),scale=4.5,boost=1.18,refl=0.0},
    MawFire={mode='PLASMA',stops=pbrStops('#780818','#F22848','#FF8844'),scale=4.8,boost=1.16,refl=0.0},
    EyeBlaze={mode='PLASMA',stops=pbrStops('#880848','#FF1E88','#FF94D8'),scale=4.8,boost=1.16,refl=0.0},
    EyeGlow={mode='PLASMA',stops=pbrStops('#380220','#88084E','#E81C8C'),scale=5.0,boost=1.14,refl=0.0},
    VioletGem={mode='FRESNEL',stops=pbrStops('#480C94','#9418DE','#D65AFF'),scale=5.5,boost=1.10,refl=0.08},
    WingMembrane={mode='PLASMA',stops=pbrStops('#14020A','#780A30','#FF286E'),scale=5.2,boost=1.12,refl=0.02},
    -- Expansion Melee, Guns/Bows, Armor Sets & Crafting Relics (29 previously missing materials)
    AbyssalPurple={mode='PLASMA',stops=pbrStops('#1E0648','#6A14D8','#C854FF'),scale=5.2,boost=1.14,refl=0.04},
    BronzeForge={mode='METAL',stops=pbrStops('#4A2810','#9A5824','#E09448'),scale=9.5,boost=1.06,refl=0.12},
    DarkBark={mode='FRESNEL',stops=pbrStops('#180E08','#321E12','#543420'),scale=8.5,boost=1.04,refl=0.02},
    EmeraldCore={mode='PLASMA',stops=pbrStops('#044824','#0EC862','#54FF9E'),scale=4.8,boost=1.16,refl=0.04},
    EmeraldCrystal={mode='FRESNEL',stops=pbrStops('#06542C','#14B864','#64FFB0'),scale=5.5,boost=1.12,refl=0.08},
    EmeraldLeaf={mode='FRESNEL',stops=pbrStops('#0A421E','#1E8C42','#4CE078'),scale=6.5,boost=1.08,refl=0.03},
    LimeGlow={mode='PLASMA',stops=pbrStops('#186808','#4CE218','#A8FF4C'),scale=4.8,boost=1.18,refl=0.0},
    LivingWood={mode='FRESNEL',stops=pbrStops('#2A180C','#58341A','#8C562C'),scale=8.0,boost=1.05,refl=0.02},
    PearlOrb={mode='FRESNEL',stops=pbrStops('#A8B8D8','#E2ECFC','#FFFFFF'),scale=6.0,boost=1.08,refl=0.10},
    RoyalPurple={mode='FRESNEL',stops=pbrStops('#240A4E','#5818B8','#9E48FF'),scale=6.5,boost=1.08,refl=0.05},
    SylvanLeaf={mode='FRESNEL',stops=pbrStops('#0E4E22','#249E48','#5CF084'),scale=6.5,boost=1.08,refl=0.03},
    TealScale={mode='METAL',stops=pbrStops('#063844','#107E92','#38D8EC'),scale=8.5,boost=1.08,refl=0.10},
    VioletArc={mode='PLASMA',stops=pbrStops('#3A0888','#8E1EFF','#DF74FF'),scale=4.8,boost=1.16,refl=0.0},
    CrimsonArmor={mode='METAL',stops=pbrStops('#3E0610','#8E0E24','#DC2442'),scale=9.5,boost=1.08,refl=0.10},
    CrimsonCloth={mode='FRESNEL',stops=pbrStops('#34040C','#780A1E','#C41838'),scale=7.5,boost=1.06,refl=0.02},
    CosmicPurple={mode='PLASMA',stops=pbrStops('#16043A','#5210B4','#B244FF'),scale=5.0,boost=1.14,refl=0.04},
    DemonHorn={mode='FRESNEL',stops=pbrStops('#12080E','#2E1220','#5E2038'),scale=8.0,boost=1.05,refl=0.04},
    VoidCape={mode='FRESNEL',stops=pbrStops('#0C061C','#221048','#462088'),scale=7.5,boost=1.06,refl=0.02},
    VoidSingularity={mode='PLASMA',stops=pbrStops('#080218','#4808A8','#C438FF'),scale=4.6,boost=1.18,refl=0.0},
    AbyssalChamber={mode='METAL',stops=pbrStops('#100A24','#281854','#5634A8'),scale=9.0,boost=1.06,refl=0.08},
    AncientWood={mode='FRESNEL',stops=pbrStops('#24140A','#4C2C16','#7A4826'),scale=8.5,boost=1.04,refl=0.02},
    BoneTooth={mode='FRESNEL',stops=pbrStops('#9E8E72','#D8C8A8','#F8F0DC'),scale=7.5,boost=1.05,refl=0.04},
    ChronoGrip={mode='METAL',stops=pbrStops('#1E2434','#3E4A68','#6E82B0'),scale=9.0,boost=1.05,refl=0.06},
    ChronoStar={mode='PLASMA',stops=pbrStops('#0058B8','#00C4FF','#94F4FF'),scale=4.6,boost=1.18,refl=0.0},
    CloudPorcelain={mode='FRESNEL',stops=pbrStops('#B4C2DC','#E4ECF8','#FFFFFF'),scale=7.5,boost=1.06,refl=0.08},
    FlintlockWood={mode='FRESNEL',stops=pbrStops('#2C160A','#5C3016','#8E4C24'),scale=8.5,boost=1.05,refl=0.03},
    SteamSmoke={mode='PLASMA',stops=pbrStops('#586882','#9EB0CC','#E8F2FF'),scale=5.2,boost=1.08,refl=0.0},
    VoidBlack={mode='METAL',stops=pbrStops('#080612','#181230','#342662'),scale=9.5,boost=1.06,refl=0.08},
    ParchmentGold={mode='FRESNEL',stops=pbrStops('#9A7438','#D4AC64','#F6DC9E'),scale=7.5,boost=1.06,refl=0.03},
}
local WORLD_SHADER_CACHE={}
local function boostSaturationRGB(r,g,b,satMult,valMult)
    local maxC=math.max(r,g,b)
    local minC=math.min(r,g,b)
    local d=maxC-minC
    local h,s,v=0,maxC>1e-5 and (d/maxC) or 0,maxC
    if d>1e-5 then
        if maxC==r then h=((g-b)/d)%6
        elseif maxC==g then h=(b-r)/d+2
        else h=(r-g)/d+4 end
        h=h/6
    end
    s=math.clamp(s*satMult,0,1)
    v=math.clamp(v*valMult,0.04,1)
    local c=v*s
    local x=c*(1-math.abs((h*6)%2-1))
    local m=v-c
    local nr,ng,nb=0,0,0
    local hi=math.floor(h*6)%6
    if hi==0 then nr,ng,nb=c,x,0
    elseif hi==1 then nr,ng,nb=x,c,0
    elseif hi==2 then nr,ng,nb=0,c,x
    elseif hi==3 then nr,ng,nb=0,x,c
    elseif hi==4 then nr,ng,nb=x,0,c
    else nr,ng,nb=c,0,x end
    return math.clamp(nr+m,0,1),math.clamp(ng+m,0,1),math.clamp(nb+m,0,1)
end
local function makeWorldStops(r,g,b,satBoost,darkMul,midMul,lightMul,warmShift)
    local mr,mg,mb=boostSaturationRGB(r,g,b,satBoost or 1.45,midMul or 1.02)
    local dr,dg,db=boostSaturationRGB(r*0.88,g*0.92,b*1.06,(satBoost or 1.45)*1.12,darkMul or 0.56)
    local lr,lg,lb=boostSaturationRGB(math.min(1,r+(warmShift or 0.06)),math.min(1,g+(warmShift or 0.06)*0.75),b,(satBoost or 1.45)*0.88,lightMul or 1.28)
    return {
        {0.00,{dr,dg,db}},
        {0.50,{mr,mg,mb}},
        {1.00,{lr,lg,lb}},
    }
end
local function getWorldShaderSpec(matName,rawColor)
    if not matName or matName:sub(1,8)~='MAT_C3D_' then return nil end
    local cached=WORLD_SHADER_CACHE[matName]
    if cached then return cached end
    local ml=matName:lower()
    local rc=rawColor or {0.5,0.5,0.5,1}
    local r,g,b=rc[1] or 0.5,rc[2] or 0.5,rc[3] or 0.5
    local spec
    if ml:find('glow') or ml:find('neon') or ml:find('conduit') or ml:find('holo') or ml:find('beacon') or ml:find('magmacrack') or ml:find('core') or ml:find('crystal') or ml:find('prism') or ml:find('voidstar') or ml:find('abyssalwater') then
        local nr,ng,nb=boostSaturationRGB(r,g,b,1.65,1.22)
        if ml:find('solaraetherglow') or ml:find('amber') or ml:find('sun') then
            nr,ng,nb=1.00,0.78,0.22
        elseif ml:find('cryocrystal') or ml:find('conduit') or ml:find('holo') or ml:find('beacon') or ml:find('prism') then
            nr,ng,nb=0.18,0.88,1.00
        elseif ml:find('umbralglow') or ml:find('void') or ml:find('amethyst') then
            nr,ng,nb=0.72,0.28,1.00
        elseif ml:find('crimson') or ml:find('magma') then
            nr,ng,nb=1.00,0.28,0.22
        end
        spec={
            mode='PLASMA',
            stops=makeWorldStops(nr,ng,nb,1.35,0.58,0.98,1.22,0.08),
            scale=4.6,
            boost=1.12,
            mat=Enum.Material.Glass,
            refl=0.18,
            neon=false,
            lightColor=Color3.new(math.clamp(nr,0,1),math.clamp(ng,0,1),math.clamp(nb,0,1)),
        }
    elseif ml:find('turf') or ml:find('grass') or ml:find('moss') or ml:find('lawn') then
        if ml:find('emeraldturf') or ml:find('sunturft') or ml:find('gardenturf') or ml:find('forestmoss') then
            r,g,b=0.14,0.64,0.26
        end
        spec={
            mode='WORLD_TURF',
            stops=makeWorldStops(r,g,b,1.65,0.52,1.04,1.34,0.08),
            scale=4.2,
            boost=1.08,
            mat=Enum.Material.LeafyGrass,
            refl=0.0,
        }
    elseif ml:find('canopy') or ml:find('foliage') or ml:find('leaf') or ml:find('bush') or ml:find('hedge') or ml:find('vine') then
        spec={
            mode='WORLD_CANOPY',
            stops=makeWorldStops(r,g,b,1.60,0.48,1.05,1.36,0.09),
            scale=3.8,
            boost=1.10,
            mat=Enum.Material.Grass,
            refl=0.0,
        }
    elseif ml:find('gold') or ml:find('brass') or ml:find('bronze') or ml:find('copper') then
        if ml:find('gold') then r,g,b=0.88,0.66,0.18 end
        spec={
            mode='WORLD_METAL',
            stops=makeWorldStops(r,g,b,1.55,0.54,1.06,1.38,0.10),
            scale=7.5,
            boost=1.12,
            mat=Enum.Material.Metal,
            refl=0.22,
        }
    elseif ml:find('steel') or ml:find('iron') or ml:find('alloy') or ml:find('chrome') or ml:find('hull') and ml:find('W4') then
        spec={
            mode='WORLD_METAL',
            stops=makeWorldStops(r,g,b,1.35,0.52,0.98,1.28,0.04),
            scale=7.5,
            boost=1.06,
            mat=Enum.Material.Metal,
            refl=0.16,
        }
    elseif ml:find('cliff') or ml:find('canyon') or ml:find('mesa') or ml:find('crag') or ml:find('spire') then
        if ml:find('goldencliff') or ml:find('suncliff') then
            r,g,b=0.72,0.50,0.28
        end
        local isDarkVolcanic=ml:find('obsidian') or ml:find('basalt') or ml:find('void') or ml:find('umbral') or ml:find('abyss')
        local isIcy=ml:find('frost') or ml:find('glacier') or ml:find('ice') or ml:find('permafrost')
        spec={
            mode='WORLD_CLIFF',
            stops=makeWorldStops(r,g,b,1.58,0.44,0.96,1.32,0.07),
            scale=5.4,
            boost=1.06,
            mat=isIcy and Enum.Material.Glacier or (isDarkVolcanic and Enum.Material.Basalt or Enum.Material.Sandstone),
            refl=isIcy and 0.12 or 0.0,
        }
    elseif ml:find('water') or ml:find('sea') or ml:find('pool') or ml:find('fountain') then
        spec={
            mode='WORLD_WATER',
            stops=makeWorldStops(0.08,0.62,0.88,1.55,0.55,1.05,1.35,0.08),
            scale=4.5,
            boost=1.12,
            mat=Enum.Material.Glass,
            refl=0.28,
            trans=0.18,
        }
    elseif ml:find('ice') or ml:find('glacier') or ml:find('frost') then
        spec={
            mode='WORLD_CLIFF',
            stops=makeWorldStops(r,g,b,1.50,0.58,1.04,1.32,0.06),
            scale=5.0,
            boost=1.08,
            mat=Enum.Material.Glacier,
            refl=0.14,
        }
    elseif ml:find('snow') then
        spec={
            mode='WORLD_TURF',
            stops=makeWorldStops(0.78,0.88,0.98,1.25,0.74,1.00,1.16,0.04),
            scale=4.5,
            boost=1.04,
            mat=Enum.Material.Snow,
            refl=0.04,
        }
    elseif ml:find('wood') or ml:find('timber') or ml:find('plank') or ml:find('deck') or ml:find('trunk') or ml:find('bark') or ml:find('hull') then
        spec={
            mode='WORLD_CLIFF',
            stops=makeWorldStops(r,g,b,1.55,0.48,0.96,1.28,0.06),
            scale=6.5,
            boost=1.06,
            mat=(ml:find('plank') or ml:find('deck') or ml:find('hull')) and Enum.Material.WoodPlanks or Enum.Material.Wood,
            refl=0.0,
        }
    elseif ml:find('roof') or ml:find('tile') or ml:find('shingle') or ml:find('dome') then
        if ml:find('azuredome') then r,g,b=0.14,0.48,0.88 end
        spec={
            mode='WORLD_STONE',
            stops=makeWorldStops(r,g,b,1.62,0.52,1.04,1.34,0.07),
            scale=5.5,
            boost=1.08,
            mat=ml:find('dome') and Enum.Material.Marble or Enum.Material.RoofShingles,
            refl=ml:find('dome') and 0.10 or 0.02,
        }
    elseif ml:find('sail') or ml:find('banner') or ml:find('awning') or ml:find('canopycloth') or ml:find('tent') then
        spec={
            mode='WORLD_CANOPY',
            stops=makeWorldStops(r,g,b,1.58,0.56,1.04,1.30,0.06),
            scale=5.0,
            boost=1.08,
            mat=Enum.Material.Fabric,
            refl=0.0,
        }
    elseif ml:find('marble') or ml:find('alabaster') or ml:find('sanctum') or ml:find('pillar') or ml:find('column') or ml:find('arch') then
        if ml:find('alabaster') then r,g,b=0.84,0.78,0.66 end
        spec={
            mode='WORLD_STONE',
            stops=makeWorldStops(r,g,b,1.42,0.62,1.00,1.24,0.06),
            scale=5.2,
            boost=1.05,
            mat=Enum.Material.Marble,
            refl=0.06,
        }
    elseif ml:find('cobble') or ml:find('pave') or ml:find('road') or ml:find('path') or ml:find('plaza') or ml:find('stone') or ml:find('wall') or ml:find('bastion') or ml:find('fortress') then
        if ml:find('ceremonialstone') then r,g,b=0.72,0.62,0.46 end
        spec={
            mode='WORLD_STONE',
            stops=makeWorldStops(r,g,b,1.52,0.54,0.98,1.28,0.06),
            scale=5.0,
            boost=1.06,
            mat=(ml:find('cobble') or ml:find('path') or ml:find('road')) and Enum.Material.Cobblestone or Enum.Material.Limestone,
            refl=0.02,
        }
    else
        spec={
            mode='WORLD_STONE',
            stops=makeWorldStops(r,g,b,1.50,0.54,0.98,1.28,0.06),
            scale=5.0,
            boost=1.06,
            mat=Enum.Material.Slate,
            refl=0.02,
        }
    end
    WORLD_SHADER_CACHE[matName]=spec
    return spec
end
local function getFruitShaderSpec(matName,rawColor)
    if not matName then return nil end
    if FRUIT_SHADER_SPECS[matName] then return FRUIT_SHADER_SPECS[matName] end
    local short=matName:gsub('^MAT_[%w]+_','')
    if FRUIT_SHADER_SPECS[short] then return FRUIT_SHADER_SPECS[short] end
    return getWorldShaderSpec(matName,rawColor)
end
local function fbm3(x,y,z)
    local n=math.noise(x,y,z)*0.54
        +math.noise(x*2.07+17.3,y*2.07+31.7,z*2.07+11.9)*0.30
        +math.noise(x*4.13+53.1,y*4.13+19.4,z*4.13+41.2)*0.16
    return math.clamp(0.5+n*0.92,0,1)
end
local function evalRamp(stops,fac,boost)
    fac=math.clamp(fac,0,1)
    local c1,c2,t=stops[1][2],stops[#stops][2],0
    if fac<=stops[1][1] then
        c2=c1;t=0
    elseif fac>=stops[#stops][1] then
        c1=c2;t=0
    else
        for k=1,#stops-1 do
            local p0,p1=stops[k][1],stops[k+1][1]
            if fac>=p0 and fac<=p1 then
                c1=stops[k][2];c2=stops[k+1][2]
                t=(fac-p0)/math.max(1e-5,p1-p0)
                t=t*t*(3-2*t)
                break
            end
        end
    end
    local b=boost or 1.0
    local r=math.clamp((c1[1]+(c2[1]-c1[1])*t)*b,0,1)
    local g=math.clamp((c1[2]+(c2[2]-c1[2])*t)*b,0,1)
    local bl=math.clamp((c1[3]+(c2[3]-c1[3])*t)*b,0,1)
    return r,g,bl
end
local function evalFruitShader(spec,px,py,pz,nx,ny,nz,low,high,isGrid)
    local gx,gy,gz
    if isGrid and (high.X-low.X)>2.6 then
        local cx=px<-1.55 and -3.10 or (px>1.55 and 3.10 or 0.0)
        local cy=py>=0 and 1.15 or -1.15
        gx=math.clamp((px-(cx-0.82))/1.64,0,1)
        gy=math.clamp((py-(cy-0.88))/1.76,0,1)
        gz=math.clamp((pz-low.Z)/math.max(0.25,high.Z-low.Z),0,1)
    else
        gx=math.clamp((px-low.X)/math.max(0.12,high.X-low.X),0,1)
        gy=math.clamp((py-low.Y)/math.max(0.12,high.Y-low.Y),0,1)
        gz=math.clamp((pz-low.Z)/math.max(0.12,high.Z-low.Z),0,1)
    end
    local sc=spec.scale or 5.0
    local mode=spec.mode
    local fac=0.5
    if mode=='VORTEX' then
        local dx=gx-0.50
        local dy=gy-0.50
        local dz=math.min(gz,1.0-gz)-0.08
        local dist=math.sqrt(dx*dx+dy*dy+dz*dz*0.38)
        local turb=(fbm3(gx*sc*0.85,gy*sc*0.85,gz*sc*0.85)-0.5)*2.6
        local wmode=spec.wave or 'DIAG'
        local phase
        if wmode=='HORIZ' then
            phase=(gy*sc*2.2+dx*1.1+turb)*math.pi
        elseif wmode=='VERT' then
            phase=(gx*sc*2.2+dy*0.8+turb)*math.pi
        elseif wmode=='SWIRL' then
            local ang=math.atan2(dy,dx)
            phase=(dist*sc*2.4+ang*1.5+turb)*math.pi
        else
            phase=((gx*1.35+gy*0.75)*sc*2.0+turb)*math.pi
        end
        local wave=0.5+0.5*math.sin(phase)
        fac=dist*0.92+wave*(spec.weight or 0.24)
    elseif mode=='PLASMA' then
        local n1=fbm3(gx*sc,gy*sc,gz*sc)
        local cell=1.0-math.min(1.0,math.abs(math.noise(gx*sc*2.3+7.1,gy*sc*2.3+13.4,gz*sc*2.3+5.8))*1.85)
        local facing=0.35+0.65*math.max(math.abs(nz),math.abs(ny)*0.55)
        fac=n1*0.46+cell*0.26+facing*0.28
    elseif mode=='METAL' or mode=='WORLD_METAL' then
        local n1=fbm3(gx*sc,gy*sc,gz*sc)
        local wave=0.5+0.5*math.sin((gy*sc*2.4+n1*2.8)*math.pi)
        local specH=math.clamp(0.50+0.34*ny-0.26*nz+0.14*nx,0,1)
        fac=wave*0.32+n1*0.28+specH*0.40
    elseif mode=='WORLD_TURF' then
        local n1=fbm3(gx*sc*1.15,gy*sc*0.65,gz*sc*1.15)
        local dapple=0.5+0.5*math.sin((gx*sc*2.2+gz*sc*1.9+n1*2.4)*math.pi)
        local sun=math.clamp(0.45+0.38*ny+0.14*nx-0.12*nz,0,1)
        fac=n1*0.36+dapple*0.26+sun*0.38
    elseif mode=='WORLD_CANOPY' then
        local n1=fbm3(gx*sc,gy*sc,gz*sc)
        local crown=math.clamp(gy*0.72+0.28*math.max(0,ny),0,1)
        local sun=math.clamp(0.44+0.36*ny+0.18*nx-0.14*nz,0,1)
        fac=n1*0.34+crown*0.34+sun*0.32
    elseif mode=='WORLD_CLIFF' then
        local n1=fbm3(gx*sc*0.90,gy*sc*1.65,gz*sc*0.90)
        local strata=0.5+0.5*math.sin((gy*sc*3.6+n1*2.6)*math.pi)
        local heightGrad=math.clamp(0.18+gy*0.68,0,1)
        local slope=math.clamp(0.46+0.36*ny+0.14*nx-0.16*nz,0,1)
        fac=strata*0.30+heightGrad*0.34+slope*0.24+n1*0.12
    elseif mode=='WORLD_STONE' then
        local n1=fbm3(gx*sc,gy*sc,gz*sc)
        local vein=0.5+0.5*math.sin(((gx+gz)*sc*1.85+n1*2.5)*math.pi)
        local sun=math.clamp(0.48+0.34*ny+0.14*nx-0.14*nz,0,1)
        fac=n1*0.34+vein*0.26+sun*0.40
    elseif mode=='WORLD_WATER' then
        local n1=fbm3(gx*sc*1.3,gy*sc*0.5,gz*sc*1.3)
        local ripple=0.5+0.5*math.sin((gx*sc*3.0+gz*sc*2.6+n1*3.2)*math.pi)
        local fres=math.clamp(1.0-math.abs(ny),0,1)^1.2
        fac=n1*0.32+ripple*0.38+fres*0.30
    else
        local n1=fbm3(gx*sc,gy*sc,gz*sc)
        local fres=math.clamp(1.0-math.abs(nz),0,1)^1.35
        local facet=math.clamp(0.48+0.30*ny-0.24*nz+0.12*nx,0,1)
        fac=n1*0.42+fres*0.34+facet*0.24
    end
    return evalRamp(spec.stops,fac,spec.boost)
end
local TOP_ROW_FRUITS={
    Fruit_GaleCore=true,Fruit_SandstoneCore=true,Fruit_SolarFlameCore=true,
    Fruit_ThunderRumbleCore=true,Fruit_AstralGravityCore=true,Fruit_DimensionalPortalCore=true,
}
local BOTTOM_ROW_FRUITS={
    Fruit_GlacierIceCore=true,Fruit_CelestialLightCore=true,Fruit_StarforgedMagmaCore=true,
    Fruit_SolarTitanCore=true,Fruit_AetherflowCore=true,
}
local function isStrayFruitPart(modelName,meshName,matName)
    local short=tostring(matName or ''):gsub('^MAT_AetherFruitsCollection[12]_','')
    if modelName=='Fruit_GaleCore' and short=='FrostSnowCap' then return true end
    if modelName=='Fruit_GlacierIceCore' and short=='GaleVortexSphere' then return true end
    if modelName=='Fruit_SandstoneCore' and (short=='AstralCoreWhite' or meshName=='Fruit_SandstoneCore_Part01') then return true end
    if modelName=='Fruit_CelestialLightCore' and (short=='QuakeRockGold' or short=='QuakeCoreEmit') then return true end
    if modelName=='Fruit_SolarFlameCore' and short=='BasaltRimHot' then return true end
    if modelName=='Fruit_StarforgedMagmaCore' and short=='FlameOrangeGold' then return true end
    if modelName=='Fruit_ThunderRumbleCore' and short=='HaloSolarEmit' then return true end
    if modelName=='Fruit_SolarTitanCore' and (short=='CobaltCloudLight' or short=='CobaltCloud') then return true end
    if modelName=='Fruit_AstralGravityCore' and short=='BerryGlazeEmit' then return true end
    if modelName=='Fruit_AetherflowCore' and short=='GravityGalaxy' then return true end
    if modelName=='Fruit_DimensionalPortalCore' and (short=='DemonCoreEmit' or short=='DragonObsidian') then return true end
    return false
end
local VIRTUAL_SPLIT_SPECS={
    -- 8 Separated 3D Weapons from MythicalWeaponsSet (filtered by exact Blender front-view bone weights)
    Wep_CursedBladeLeft={source='MythicalWeaponsSet',bones={AbyssalSaber_Front=true},anchorGrip=true},
    Wep_CursedBladeRight={source='MythicalWeaponsSet',bones={CelestialSaber_Front=true},anchorGrip=true},
    Wep_CursedDualSkyblades={source='MythicalWeaponsSet',bones={AbyssalSaber_Front=true,CelestialSaber_Front=true},anchorGrip=true},
    Wep_CryonFrostblade={source='MythicalWeaponsSet',bones={FrostBlade_Front=true},anchorGrip=true},
    Wep_Dawnbringer={source='MythicalWeaponsSet',bones={SolarSword_Front=true},flipXY=true,anchorGrip=true},
    Wep_NoxarGreatsword={source='MythicalWeaponsSet',bones={MagmaSword_Front=true},flipXY=true,anchorGrip=true},
    Wep_SoulGuitarVoid={source='MythicalWeaponsSet',bones={SoulGuitar_Front=true},anchorGrip=true},
    Wep_CryoRailgun={source='MythicalWeaponsSet',bones={Railgun_Top=true}},
    -- 6 Separated 3D Race V4 Wings from RaceV4WingsSet (with real skinned wing/halo/chain/flame bones kept!)
    Wing_Skyborn={source='RaceV4WingsSet',bonePrefix='Angel_',rootBone='Angel_Root',origin=Vector3.new(3.05,4.50,0)},
    Wing_Mink={source='RaceV4WingsSet',bonePrefix='Azure_',rootBone='Azure_Root',origin=Vector3.new(0.00,4.50,0)},
    Wing_Leviathan={source='RaceV4WingsSet',bonePrefix='Levi_',rootBone='Levi_Root',origin=Vector3.new(-3.05,4.50,0)},
    Wing_Cyborg={source='RaceV4WingsSet',bonePrefix='Cyborg_',rootBone='Cyborg_Root',origin=Vector3.new(3.05,1.50,0)},
    Wing_Ghoul={source='RaceV4WingsSet',bonePrefix='Ghoul_',rootBone='Ghoul_Root',origin=Vector3.new(0.00,1.50,0)},
    Wing_Draco={source='RaceV4WingsSet',bonePrefix='Draco_',rootBone='Draco_Root',origin=Vector3.new(-3.05,1.50,0)},
    -- 3 Separated 3D Ancient Aether Fruit Trees from AncientAetherFruitTrees
    Tree_CryoAether={source='AncientAetherFruitTrees',minMesh=0,maxMesh=6,anchorBottom=true},
    Tree_SolarAether={source='AncientAetherFruitTrees',minMesh=7,maxMesh=17,anchorBottom=true},
    Tree_VoidAether={source='AncientAetherFruitTrees',minMesh=18,maxMesh=23,anchorBottom=true},
    -- 3 Separated 3D Elemental Shrines & 1 Raid Microchip Console from AetherShrinesAndRaidConsole
    Shrine_SolarAether={source='AetherShrinesAndRaidConsole',minMesh=0,maxMesh=16,maxX=0,minY=7.0,anchorBottom=true},
    Shrine_CryoAether={source='AetherShrinesAndRaidConsole',minMesh=0,maxMesh=16,minX=0,minY=7.0,anchorBottom=true},
    Shrine_VoidAether={source='AetherShrinesAndRaidConsole',minMesh=17,maxMesh=21,maxX=0,anchorBottom=true},
    Console_RaidMicrochip={source='AetherShrinesAndRaidConsole',minMesh=0,maxMesh=16,minX=0,maxY=7.0,anchorBottom=true},
}
M.VirtualSplitSpecs=VIRTUAL_SPLIT_SPECS
local function build(name,progress)
    if M.Models[name] and M.Models[name].PrimaryPart and M.Models[name].PrimaryPart.Parent then return M.Models[name] end
    local vspec=VIRTUAL_SPLIT_SPECS[name]
    local isFruit=(name:sub(1,6)=='Fruit_' or name=='AetherFruitsCollection1' or name=='AetherFruitsCollection2')
    local isStatic=(STATIC_WORLD_MODELS[name]==true or isFruit or (vspec~=nil and vspec.bonePrefix==nil))
    local folder=Sources:WaitForChild(vspec and vspec.source or name);local h=require(folder.Header)
    if type(h)=='string' then h=game.HttpService:JSONDecode(h) end
    local model=Instance.new('Model');model.Name=name;model:SetAttribute('BlenderHandoff',true)
    M.ActiveModel=model
    local root=Instance.new('Part');root.Name='RootPart';root.Transparency=1;root.Size=Vector3.one*.1
    root.Anchored=true;root.CanCollide=false;root.CanQuery=false;root.CanTouch=false;root.Parent=model;model.PrimaryPart=root
    local nodes={}
    if not isStatic then
        for _,b in h.bones do
            if (not vspec) or (vspec.bonePrefix and b.name:sub(1,#vspec.bonePrefix)==vspec.bonePrefix) then
                local bone=Instance.new('Bone');bone.Name=b.name
                local bcf=cf(b['local'])
                if vspec and b.name==vspec.rootBone and vspec.origin then
                    bcf=CFrame.new(-vspec.origin)*bcf
                    bone.Parent=root
                else
                    bone.Parent=(b.parent and nodes[b.parent]) or root
                end
                bone.CFrame=bcf;nodes[b.name]=bone
            end
        end
    end
    for index=0,h.mesh_count-1 do
        if progress then progress(name,index+1,h.mesh_count) end
        if vspec and ((vspec.minMesh and index<vspec.minMesh) or (vspec.maxMesh and index>vspec.maxMesh)) then
            continue
        end
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
        local isGridDivider=(matNameLower:find('griddivider')~=nil)
        if isPureFXCage or isHandRibbonFX or isOrbAura or isElemFX or isGridDivider or isStrayFruitPart(name,meshNameStr,mat and mat.name) then
            continue
        end
        local meshStatic=(isStatic or (d.role=='Environment' and not (vspec and vspec.bonePrefix)))
        local stripVert={}
        if TOP_ROW_FRUITS[name] then
            for i,p in d.vertices do
                if p[2]<0.44 then stripVert[i]=true end
            end
        elseif BOTTOM_ROW_FRUITS[name] then
            for i,p in d.vertices do
                if p[2]>2.32 then stripVert[i]=true end
            end
        end
        if vspec then
            if (vspec.bones or vspec.bonePrefix) and d.weights then
                local pfx=vspec.bonePrefix
                local pfxLen=pfx and #pfx or 0
                for i,wlist in d.weights do
                    local topBone,topW=nil,0
                    for _,pair in wlist do
                        if pair[2]>topW then topBone=pair[1];topW=pair[2] end
                    end
                    if vspec.bones and not (topBone and vspec.bones[topBone]) then
                        stripVert[i]=true
                    elseif pfx and not (topBone and topBone:sub(1,pfxLen)==pfx) then
                        stripVert[i]=true
                    end
                end
            end
            if vspec.minX or vspec.maxX or vspec.minY or vspec.maxY or vspec.minZ or vspec.maxZ then
                for i,p in d.vertices do
                    if (vspec.minX and p[1]<vspec.minX) or (vspec.maxX and p[1]>vspec.maxX)
                        or (vspec.minY and p[2]<vspec.minY) or (vspec.maxY and p[2]>vspec.maxY)
                        or (vspec.minZ and p[3]<vspec.minZ) or (vspec.maxZ and p[3]>vspec.maxZ) then
                        stripVert[i]=true
                    end
                end
            end
        end
        local keepWings=(name=='AbyssalSovereignDragon' or name=='AbyssalDragonHybrid' or name=='SunshardTemplar' or name=='AbyssalDreadknight' or name=='Noxar' or name=='RaceV4WingsSet' or (vspec and vspec.bonePrefix~=nil))
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
        local function xformPos(rawP)
            local vp=v(rawP)
            if name=='Fruit_DimensionalPortalCore' and vp.Y>2.00 then
                vp=Vector3.new(vp.X,vp.Y-0.18,vp.Z)
            end
            if vspec then
                if vspec.origin then vp=vp-vspec.origin end
                if vspec.flipXY then vp=Vector3.new(-vp.X,-vp.Y,vp.Z) end
            end
            return vp
        end
        local low=Vector3.new(math.huge,math.huge,math.huge);local high=-low
        local rawLow=Vector3.new(math.huge,math.huge,math.huge);local rawHigh=-rawLow
        for _,ti in validTriangles do
            local t=d.triangles[ti]
            for j=1,3 do
                local rawV=v(d.vertices[t[j]+1])
                rawLow=rawLow:Min(rawV);rawHigh=rawHigh:Max(rawV)
                local vp=xformPos(d.vertices[t[j]+1])
                low=low:Min(vp);high=high:Max(vp)
            end
        end
        local center=(low+high)/2
        local fruitSpec=getFruitShaderSpec(mat and mat.name,mat and mat.color_linear)
        local isCollectionGrid=(name=='AetherFruitsCollection1' or name=='AetherFruitsCollection2')
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
                for _,b in h.bones do
                    if (not vspec) or (vspec.bonePrefix and b.name:sub(1,#vspec.bonePrefix)==vspec.bonePrefix) then
                        local bwCF=cf(b.bind_world)
                        if vspec and vspec.origin then bwCF=CFrame.new(-vspec.origin)*bwCF end
                        bones[b.name]=e:AddBone({Name=b.name,CFrame=CFrame.new(-center)*bwCF,Virtual=false,ParentId=b.parent and bones[b.parent] or nil})
                    end
                end
            end
            local ids={}
            local vAdded=0
            for i,p in d.vertices do
                if usedVerts[i] then
                    local vp=xformPos(p)
                    local id=e:AddVertex(vp-center);ids[i]=id
                    if (not meshStatic) and #h.bones>0 and d.weights and d.weights[i] then
                        local joints,weights={},{};for _,pair in d.weights[i] do if bones[pair[1]] then table.insert(joints,bones[pair[1]]);table.insert(weights,pair[2]) end end
                        if #joints>0 then e:SetVertexBones(id,joints);e:SetVertexBoneWeights(id,weights) end
                    end
                    vAdded+=1
                    if vAdded%4000==0 then task.wait() end
                end
            end
            local normals,uvlookup,colorLookup,vertColors={},{},{},{}
            local useFacetNormals=fruitSpec and (fruitSpec.mode=='FRESNEL' or fruitSpec.mode=='METAL')
            for bidx=batchStart,batchEnd do
                local ti=validTriangles[bidx]
                local t=d.triangles[ti]
                local face=e:AddTriangle(ids[t[1]+1],ids[t[2]+1],ids[t[3]+1]);local ns,uvs,fcs={},{},fruitSpec and {} or nil
                for j,normal in d.normals[ti] do
                    local vi=t[j]+1
                    local rawNx,rawNy,rawNz=normal[1],normal[2],normal[3]
                    if smoothNormals then
                        local sn=smoothNormals[posKeys[vi]]
                        if sn then
                            local dot=rawNx*sn[1]+rawNy*sn[2]+rawNz*sn[3]
                            if dot>=0.35 then
                                rawNx=sn[1]*0.85+rawNx*0.15;rawNy=sn[2]*0.85+rawNy*0.15;rawNz=sn[3]*0.85+rawNz*0.15
                                local m=math.sqrt(rawNx*rawNx+rawNy*rawNy+rawNz*rawNz)
                                if m>1e-5 then rawNx=rawNx/m;rawNy=rawNy/m;rawNz=rawNz/m end
                            end
                        end
                    end
                    local nx,ny,nz=rawNx,rawNy,rawNz
                    if vspec and vspec.flipXY then nx=-nx;ny=-ny end
                    local key=string.format('%.3f,%.3f,%.3f',nx,ny,nz)
                    if not normals[key] then normals[key]=e:AddNormal(Vector3.new(nx,ny,nz))end;ns[j]=normals[key]
                    local uv=d.uvs and d.uvs[ti] and d.uvs[ti][j] or {.5,.5};key=table.concat(uv,',');if not uvlookup[key] then uvlookup[key]=e:AddUV(Vector2.new(uv[1],uv[2]))end;uvs[j]=uvlookup[key]
                    if fruitSpec then
                        local vkey=useFacetNormals and (tostring(vi)..':'..key) or vi
                        local cid=vertColors[vkey]
                        if not cid then
                            local vp=d.vertices[vi]
                            local r,g,b=evalFruitShader(fruitSpec,vp[1],vp[2],vp[3],rawNx,rawNy,rawNz,rawLow,rawHigh,isCollectionGrid)
                            local kr=math.floor(r*63+0.5)
                            local kg=math.floor(g*63+0.5)
                            local kb=math.floor(b*63+0.5)
                            local ckey=kr*4096+kg*64+kb
                            cid=colorLookup[ckey]
                            if not cid then
                                cid=e:AddColor(Color3.new(kr/63,kg/63,kb/63),1)
                                colorLookup[ckey]=cid
                            end
                            vertColors[vkey]=cid
                        end
                        fcs[j]=cid
                    end
                end
                e:SetFaceNormals(face,ns);e:SetFaceUVs(face,uvs)
                if fcs then e:SetFaceColors(face,fcs) end
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
            if fruitSpec then
                part.Color=fruitSpec.neon and (fruitSpec.neonColor or Color3.new(1,1,1)) or Color3.new(1,1,1)
                part.Material=fruitSpec.mat or Enum.Material.SmoothPlastic
                part.Reflectance=fruitSpec.refl or 0
                if fruitSpec.lightColor and batchIdx==1 then
                    local pl=Instance.new('PointLight')
                    pl.Name='WorldCrystalLight'
                    pl.Color=fruitSpec.lightColor
                    pl.Brightness=1.85
                    pl.Range=32
                    pl.Shadows=false
                    pl.Parent=part
                end
            else
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
            elseif matNameLower:sub(1,4)=='mat_' and math.abs((color[1] or 0)-0.58)<0.03 and math.abs((color[2] or 0)-0.58)<0.03 and math.abs((color[3] or 0)-0.58)<0.03 then
                if matNameLower:find('gold') or matNameLower:find('core_sun') then cr,cg,cb=0.86,0.68,0.24
                elseif matNameLower:find('bronze') then cr,cg,cb=0.58,0.42,0.22
                elseif matNameLower:find('marble_white') or matNameLower:find('dragon_bone') or matNameLower:find('moon_sacred') or matNameLower:find('snow') then cr,cg,cb=0.85,0.84,0.88
                elseif matNameLower:find('marble_cream') or matNameLower:find('stone_viaduct') or matNameLower:find('stone_road') then cr,cg,cb=0.76,0.72,0.66
                elseif matNameLower:find('cyan') or matNameLower:find('aqua') then cr,cg,cb=0.16,0.78,0.88
                elseif matNameLower:find('foam') or matNameLower:find('stone_ice') then cr,cg,cb=0.68,0.88,0.92
                elseif matNameLower:find('blue') or matNameLower:find('serpent_scale') then cr,cg,cb=0.18,0.46,0.82
                elseif matNameLower:find('violet') or matNameLower:find('lavender') or matNameLower:find('mystic') or matNameLower:find('celestial') then cr,cg,cb=0.56,0.42,0.84
                elseif matNameLower:find('pink') or matNameLower:find('magenta') or matNameLower:find('sakura') or matNameLower:find('serpent_fin') then cr,cg,cb=0.86,0.36,0.68
                elseif matNameLower:find('red') or matNameLower:find('crimson') then cr,cg,cb=0.78,0.18,0.24
                elseif matNameLower:find('orange') or matNameLower:find('magma') or matNameLower:find('lava') then cr,cg,cb=0.92,0.42,0.14
                elseif matNameLower:find('turquoise') then cr,cg,cb=0.14,0.76,0.68
                elseif matNameLower:find('moss') or matNameLower:find('grass') or matNameLower:find('emerald') then cr,cg,cb=0.22,0.68,0.38
                elseif matNameLower:find('pine') then cr,cg,cb=0.14,0.44,0.32
                elseif matNameLower:find('bark') or matNameLower:find('timber') then cr,cg,cb=0.38,0.26,0.18
                elseif matNameLower:find('indigo') then cr,cg,cb=0.22,0.20,0.36
                elseif matNameLower:find('obsidian') or matNameLower:find('cliff_dark') then cr,cg,cb=0.18,0.17,0.24
                elseif matNameLower:find('cliff_rock') then cr,cg,cb=0.36,0.37,0.42
                end
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
            end
            part.Transparency=isHandOrElemFX and 0.80 or ((fruitSpec and fruitSpec.trans) or (1-color[4]*(mat.alpha or 1)));part.Parent=model
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
    if name:sub(1,6)=='Fruit_' or (vspec and not vspec.bonePrefix) then
        local firstM=model:FindFirstChildWhichIsA('MeshPart')
        if firstM then root.CFrame=firstM.CFrame end
        local boxCF,boxSize=model:GetBoundingBox()
        if vspec and vspec.anchorBottom then
            root.CFrame=CFrame.new(boxCF.Position.X,boxCF.Position.Y-boxSize.Y*0.5,boxCF.Position.Z)
        elseif vspec and vspec.anchorGrip then
            root.CFrame=CFrame.new(boxCF.Position.X,boxCF.Position.Y-boxSize.Y*0.28,boxCF.Position.Z)
        else
            root.CFrame=CFrame.new(boxCF.Position)
        end
    end
    if name:sub(1,6)=='Fruit_' or vspec then
        for _,ch in ipairs(model:GetChildren()) do
            if ch:IsA('MeshPart') and not ch:FindFirstChildOfClass('WeldConstraint') then
                local weld=Instance.new('WeldConstraint');weld.Part0=root;weld.Part1=ch;weld.Parent=ch
            end
        end
    end
    if isFruit and auraColor then
        local rootLight=Instance.new('PointLight')
        rootLight.Name='ElementalAuraLight'
        rootLight.Color=auraColor
        rootLight.Brightness=0.25
        rootLight.Range=4.5
        rootLight.Shadows=false
        rootLight.Parent=root
        local pe=Instance.new('ParticleEmitter')
        pe.Name='ElementalAuraParticles'
        pe.Color=ColorSequence.new(auraColor,secColor)
        pe.LightEmission=0.45
        pe.LightInfluence=0.55
        pe.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,0.12),NumberSequenceKeypoint.new(0.5,0.18),NumberSequenceKeypoint.new(1,0)})
        pe.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.55),NumberSequenceKeypoint.new(0.7,0.80),NumberSequenceKeypoint.new(1,1)})
        pe.Rate=4
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
    -- Weapon IDs -> Separated 3D Blender Weapon Models
    starter_sword='Wep_Dawnbringer',
    dawnbringer_sword='Wep_Dawnbringer',
    Dawnbringer='Wep_Dawnbringer',
    saber_of_aureon='Wep_CursedBladeRight',
    starter_daggers='Wep_CursedBladeLeft',
    stormfang_daggers='Wep_CursedDualSkyblades',
    Stormfang='Wep_CursedDualSkyblades',
    cursed_dual_skyblades='Wep_CursedDualSkyblades',
    CursedDualSkyblades='Wep_CursedDualSkyblades',
    yamo_voidblade='Wep_CursedBladeLeft',
    starter_staff='Wep_CryonFrostblade',
    astral_staff='Wep_CryonFrostblade',
    EternalFrost='Wep_CryonFrostblade',
    cryon_frostblade='Wep_CryonFrostblade',
    noxar_abyssal_greatsword='Wep_NoxarGreatsword',
    noxar_greatsword='Wep_NoxarGreatsword',
    abyssal_greatsword='Wep_NoxarGreatsword',
    ArchitectsSeverance='Wep_NoxarGreatsword',
    aether_flintlock='Wep_CryoRailgun',
    solar_kabucha='Wep_CryoRailgun',
    kabucha_wind='Wep_CryoRailgun',
    cryo_railgun='Wep_CryoRailgun',
    bizarre_rifle_cyber='Wep_CryoRailgun',
    soul_guitar_void='Wep_SoulGuitarVoid',
}
M.Alias=ALIAS
function M.GetWeaponAsset(itemId)
    if not itemId then return 'Wep_Dawnbringer' end
    if VIRTUAL_SPLIT_SPECS[itemId] then return itemId end
    if ALIAS[itemId] and VIRTUAL_SPLIT_SPECS[ALIAS[itemId]] then return ALIAS[itemId] end
    local low=string.lower(tostring(itemId))
    if low:find('dual') or low:find('cdk') or low:find('stormfang') then return 'Wep_CursedDualSkyblades'
    elseif low:find('dagger') or low:find('yamo') then return 'Wep_CursedBladeLeft'
    elseif low:find('aureon') or low:find('celestial') then return 'Wep_CursedBladeRight'
    elseif low:find('frost') or low:find('cryon') or low:find('staff') then return 'Wep_CryonFrostblade'
    elseif low:find('noxar') or low:find('greatsword') or low:find('architect') or low:find('abyss') then return 'Wep_NoxarGreatsword'
    elseif low:find('guitar') then return 'Wep_SoulGuitarVoid'
    elseif low:find('railgun') or low:find('rifle') or low:find('flintlock') or low:find('kabucha') then return 'Wep_CryoRailgun'
    end
    return 'Wep_Dawnbringer'
end
function M.GetRaceWingAsset(raceName)
    local r=string.lower(tostring(raceName or 'Skyborn'))
    if r:find('mink') or r:find('azure') then return 'Wing_Mink'
    elseif r:find('levi') or r:find('shark') or r:find('fish') then return 'Wing_Leviathan'
    elseif r:find('cyborg') or r:find('mech') then return 'Wing_Cyborg'
    elseif r:find('ghoul') then return 'Wing_Ghoul'
    elseif r:find('draco') or r:find('dragon') then return 'Wing_Draco'
    end
    return 'Wing_Skyborn'
end
-- Task #29: Distance-Priority EditableMesh Build Queue & Instant Cached Clone
M.WaitQueue={}
function M.BuildPriority(name,priorityDist,progress)
    name=ALIAS[name]or name
    local cached=M.Models[name]
    if cached and cached.PrimaryPart and cached.PrimaryPart.Parent then return cached end
    local prio=tonumber(priorityDist) or 0
    if M.Jobs[name] and not M.Jobs[name].Done then
        if prio<(M.Jobs[name].Priority or math.huge) then
            M.Jobs[name].Priority=prio
        end
        while not M.Jobs[name].Done do task.wait()end
        assert(not M.Jobs[name].Error,M.Jobs[name].Error);return assert(M.Models[name])
    end
    local job={Name=name,Priority=prio,Ready=false,Done=false};M.Jobs[name]=job
    if M.Building then
        table.insert(M.WaitQueue,job)
        while M.Building or not job.Ready do task.wait() end
    end
    M.Building=true
    local ok,result=xpcall(function()
        return build(name,progress)
    end,debug.traceback)
    if M.ActiveEditable then M.ActiveEditable:Destroy();M.ActiveEditable=nil end
    if not ok and M.ActiveModel then M.ActiveModel:Destroy()end
    M.ActiveModel=nil;M.Building=false
    job.Done=true
    if #M.WaitQueue>0 then
        local bestIdx,bestPrio=1,math.huge
        for qi,qjob in ipairs(M.WaitQueue) do
            if (qjob.Priority or 0)<bestPrio then
                bestPrio=qjob.Priority or 0
                bestIdx=qi
            end
        end
        local nextJob=table.remove(M.WaitQueue,bestIdx)
        if nextJob then nextJob.Ready=true end
    end
    if not ok then job.Error=result;error(result)end
    return result
end
function M.Build(name,progress)
    return M.BuildPriority(name,50,progress)
end
function M.CloneModel(name,priorityDist,progress)
    local template=M.BuildPriority(name,priorityDist or 0,progress)
    return template and template:Clone() or nil
end
function M.Clips(name,scale)
    name=ALIAS[name]or name
    local assetFolder=Sources:FindFirstChild(name)
    local clipMod=assetFolder and assetFolder:FindFirstChild('Clips')
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
        local isIdleClip=(short=='Idle' or short=='TalkIdle' or short=='CoilIdle' or short=='IdleFloat' or short=='SacredBreezeIdle' or short=='CombatReady' or short=='Meditate')
        local rawFps=(data.FPS or data.fps or 30)
        local fps=(isIdleClip and samples and #samples<40) and 14 or rawFps
        local loop=data.Loop~=nil and data.Loop or (data.loop==true)
        if samples and names then
            local frames={}
            for i,sample in samples do
                local frame={}
                for j,a in sample do
                    local bname=names[j]
                    local x,y,z=a[1],a[2],a[3]
                    if bname=='HumanoidRootNode' and (short=='Dash' or short=='AirDash' or short=='FlashStep' or short=='Dash_FlashStep' or short=='DaggerCombo') then x=0;z=0 end
                    if bname=='HumanoidRootNode' and (short=='Jump' or short=='DoubleJump' or short=='Jump_Air' or short=='AirAscend') then y=0 end
                    frame[j]=CFrame.new(x*scale,y*scale,z*scale,a[4],a[5],a[6],a[7])
                end
                frames[i]=frame
            end
            clips[short]={Names=names,Frames=frames,FPS=fps,Loop=loop,Duration=data.Duration or data.duration or math.max(0.05,(#frames-1)/fps),Times=nil}
        end
    end
    -- Populate universal canonical aliases across all 45 rigged assets + 1:1 Blender Dragon & Hybrid actions
    clips.Idle=clips.Idle or clips.CoilIdle or clips.IdleFloat or clips.SacredBreezeIdle or clips.CombatReady or clips.Walk or clips.Run
    clips.Run=clips.Run or clips.AggroCharge or clips.SwimSurge or clips.SoarFlight or clips.Walk or clips.Idle
    clips.Walk=clips.Walk or clips.PatrolWalk or clips.Run or clips.SwimSurge or clips.SoarFlight or clips.Idle
    clips.SoarFlight=clips.SoarFlight or clips.WingGlide or clips.SwimSurge or clips.Swim or clips.Run
    clips.Swim=clips.Swim or clips.SwimSurge or clips.SoarFlight or clips.WingGlide or clips.Run or clips.Walk
    clips.Jump=clips.Jump or clips.Jump_Air or clips.AirAscend or clips.DoubleJump or clips.JumpStrike or clips.SkyLeap or clips.TitanLeap or clips.Idle
    clips.DoubleJump=clips.DoubleJump or clips.AirAscend or clips.Jump or clips.Jump_Air or clips.SkyLeap
    clips.FallLoop=clips.FallLoop or clips.SoarFlight or clips.WingGlide or clips.JumpLoop or clips.Jump
    clips.Dash=clips.Dash or clips.Dash_FlashStep or clips.AirDash or clips.FlashStep or clips.JumpStrike or clips.SkyLeap or clips.Run
    clips.AirDash=clips.AirDash or clips.Dash or clips.Dash_FlashStep or clips.FlashStep
    clips.FlashStep=clips.FlashStep or clips.Dash_FlashStep or clips.Dash or clips.AirDash
    clips.Dodge=clips.Dodge or clips.Dash or clips.Guard_Block or clips.GuardStance
    clips.Attack=clips.Attack or clips.BiteClaw or clips.ClawCombo or clips.M1_Combo or clips.M1_SlashCombo or clips.ComboAttack or clips.DaggerCombo or clips.Attack01 or clips.GreatswordCombo or clips.FrostbladeCombo or clips.VoidSlash or clips.BiteCrunch or clips.PalmCombo or clips.FrostBolt or clips.SkySlash
    clips.Attack01=clips.Attack01 or clips.Attack
    clips.Attack02=clips.Attack02 or clips.Attack
    clips.Attack03=clips.Attack03 or clips.Attack
    clips.Attack1=clips.Attack1 or clips.Attack01
    clips.Attack2=clips.Attack2 or clips.Attack02
    clips.Attack3=clips.Attack3 or clips.Attack03
    clips.DaggerCombo=clips.DaggerCombo or clips.Attack
    clips.Heavy=clips.Heavy or clips.SovereignBreath or clips.HeatwaveBreath or clips.Skill_Z or clips.HeavySkill_Z or clips.HeavySlam or clips.HeavyDown or clips.TailTsunami or clips.DivineSlash or clips.GlacialSurge or clips.HeavenlyImpact or clips.ArcaneCircle or clips.Attack
    clips.Special=clips.Special or clips.VoidTalons or clips.DragonicClaw or clips.Skill_X or clips.AreaSkill_X or clips.Skill1_ElementalSlash or clips.HyperBeamBreath or clips.WrathOfAureon or clips.AbsoluteZero or clips.Phase3Judgement or clips.ThunderJudgement or clips.CelestialAegis or clips.FrostNova or clips.Heavy
    clips.Ultimate=clips.Ultimate or clips.CataclysmicStarshower or clips.FireShower or clips.Skill_V_Ultimate or clips.Ultimate_Cataclysm or clips.ThunderJudgement or clips.CelestialAegis or clips.FrostNova or clips.WrathOfAureon or clips.AbsoluteZero or clips.Phase3Judgement or clips.TwilightOfTheGods or clips.Special
    clips.FruitZ=clips.FruitZ or clips.SovereignBreath or clips.HeatwaveBreath or clips.Heavy
    clips.FruitX=clips.FruitX or clips.VoidTalons or clips.DragonicClaw or clips.Special
    clips.FruitC=clips.FruitC or clips.CataclysmicStarshower or clips.FireShower or clips.Ultimate
    clips.FruitV=clips.FruitV or clips.AscendTransform or clips.Transform or clips.Ascend or clips.Ultimate
    clips.FruitF=clips.FruitF or clips.SoarFlight or clips.WingGlide or clips.AirDash or clips.Dash
    clips.SkillZ=clips.SkillZ or clips.FruitZ
    clips.SkillX=clips.SkillX or clips.FruitX
    clips.SkillC=clips.SkillC or clips.FruitC
    clips.SkillV=clips.SkillV or clips.FruitV
    clips.SkillF=clips.SkillF or clips.FruitF
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
    local function cloneKataFallback(c)
        return c and table.clone(c) or nil
    end
    clips.ElementalSurge=clips.ElementalSurge or cloneKataFallback(clips.HeroicKata or clips.ElementalPulse or clips.Idle)
    clips.HeroicKata=clips.HeroicKata or cloneKataFallback(clips.ElementalSurge or clips.Idle)
    clips.UltimateAwakening=clips.UltimateAwakening or cloneKataFallback(clips.Ultimate or clips.CataclysmAwakening or clips.ElementalSurge or clips.Idle)
    for _,kataKey in ipairs({'ElementalSurge','HeroicKata','UltimateAwakening','WorldIdle_Loop','ElementalPulse','PortalSurge','AstrolabeSpin','CrystalResonance','TempestSway','CataclysmAwakening'}) do
        if clips[kataKey] then
            clips[kataKey].IsElementalKata=true
        end
    end

    -- =========================================================================
    -- NEXT-GEN 30-FPS HUMANOID ACTION OVERHAUL SUITE (ALL CHARACTER ACTIONS)
    -- =========================================================================
    local refClip=clips.Idle or clips.Run or clips.Attack
    if refClip and refClip.Names then
        local bset={}
        for _,bn in ipairs(refClip.Names) do bset[bn]=true end
        local isHumanoidRig=(bset.LowerTorso and bset.UpperTorso and bset.RightUpperArm and bset.LeftUpperArm and bset.RightUpperLeg and bset.LeftUpperLeg)
        local isStaticBoss=(name=='AureonSentinel' or name=='CryonPrime' or name=='Noxar' or name=='SolarTitanBuddha' or name=='AbyssalDragonHybrid')
        if isHumanoidRig and not isStaticBoss then
            local bNames=refClip.Names
            local rad=math.rad
            local sin=math.sin
            local cos=math.cos
            local pi=math.pi
            local clamp=math.clamp
            local max=math.max

            local function sstep(u)
                u=clamp(u,0,1)
                return u*u*(3-2*u)
            end
            local function env(t,pts)
                for k=1,#pts-1 do
                    local p0,p1=pts[k],pts[k+1]
                    if t<=p1[1] then
                        local u=sstep((t-p0[1])/max(1e-5,p1[1]-p0[1]))
                        return p0[2]+(p1[2]-p0[2])*u
                    end
                end
                return pts[#pts][2]
            end

            local ALIAS_BONE={
                Root='HumanoidRootNode',
                Spine1='LowerTorso',
                Spine2='UpperTorso',
                Chest='UpperTorso',
                UpperArm_R='RightUpperArm',
                LowerArm_R='RightLowerArm',
                Hand_R='RightHand',
                UpperArm_L='LeftUpperArm',
                LowerArm_L='LeftLowerArm',
                Hand_L='LeftHand',
                UpperLeg_R='RightUpperLeg',
                LowerLeg_R='RightLowerLeg',
                Foot_R='RightFoot',
                UpperLeg_L='LeftUpperLeg',
                LowerLeg_L='LeftLowerLeg',
                Foot_L='LeftFoot',
            }

            local isStriker=(name:find('ThunderStriker')~=nil or name:find('Assassin')~=nil or name:find('Corsair')~=nil)
            local isMage=(name:find('ArcaneMage')~=nil or name:find('Archon')~=nil or name:find('Weaver')~=nil or name:find('Zioles')~=nil or name:find('Chronos')~=nil)

            local function buildClip(numFrames,fps,loop,isKata,poseFn)
                local frames={}
                for f=1,numFrames do
                    local t=(f-1)/max(1,numFrames-1)
                    local pmap={}
                    local function bp(bname,rx,ry,rz,px,py,pz)
                        local cfVal=CFrame.new((px or 0)*scale,(py or 0)*scale,(pz or 0)*scale)*CFrame.fromEulerAnglesXYZ(rad(rx or 0),rad(ry or 0),rad(rz or 0))
                        pmap[bname]=cfVal
                    end
                    -- Default FX bone harmonic motion
                    local ph=2*pi*t
                    local s,c=sin(ph),cos(ph)
                    bp('FX_Halo',0,0,-360*t,0,0.03*s,0)
                    bp('FX_GroundRing',0,-360*t,0,0,0,0)
                    bp('FX_Orbit_01',0,360*t,0,0.06*c,0.08*s,0.06*s)
                    bp('FX_Orbit_02',0,-360*t,0,-0.06*c,-0.08*s,-0.06*s)
                    bp('FX_Aura_L',8*s,12*c,0,0,0.04*s,0)
                    bp('FX_Aura_R',-8*s,-12*c,0,0,-0.04*s,0)

                    poseFn(t,bp,s,c,ph)

                    local frame={}
                    for idx,bname in ipairs(bNames) do
                        local canonical=ALIAS_BONE[bname] or bname
                        frame[idx]=pmap[bname] or pmap[canonical] or CFrame.identity
                    end
                    frames[f]=frame
                end
                return {
                    Names=bNames,
                    Frames=frames,
                    FPS=fps,
                    Loop=loop,
                    IsElementalKata=isKata or false,
                    Duration=max(0.05,(numFrames-1)/fps),
                }
            end

            -- 1. HEROIC COMBAT IDLE (Breathing, knee rhythm, class guard, cape wave)
            clips.Idle=buildClip(45,24,true,false,function(t,bp,s,c,ph)
                local s2=sin(ph*2)
                if isStriker then
                    bp('HumanoidRootNode',-8+2*s,14+3*c,0,0,-0.08+0.035*s,0)
                    bp('LowerTorso',-6+2*s,-10+3*c,2*s)
                    bp('UpperTorso',-10+3*s,16-4*c,-2*s)
                    bp('Head',14-2*s,-18+4*c,2*c)
                    bp('RightUpperArm',-18+5*s,22,-18-4*c)
                    bp('RightLowerArm',58+6*s,18,-12)
                    bp('RightHand',-12+8*c,14,0)
                    bp('LeftUpperArm',28-5*s,-26,16+4*c)
                    bp('LeftLowerArm',64-6*s,-22,12)
                    bp('LeftHand',10-8*c,-14,0)
                    bp('RightUpperLeg',28-3*s,4,-6)
                    bp('RightLowerLeg',-34+4*s,0,0)
                    bp('RightFoot',8,0,0)
                    bp('LeftUpperLeg',18-3*s,-4,6)
                    bp('LeftLowerLeg',-26+4*s,0,0)
                    bp('LeftFoot',8,0,0)
                elseif isMage then
                    bp('HumanoidRootNode',-3+2*s,8+3*c,0,0,0.06+0.05*s,0)
                    bp('LowerTorso',-2+2*s,-6+3*c,2.5*c)
                    bp('UpperTorso',-4+3*s,10-4*c,-2.5*c)
                    bp('Head',5-2*s,-8+3*c,2*s)
                    bp('RightUpperArm',34+6*s,18,12+4*c)
                    bp('RightLowerArm',46+8*c,14,-10)
                    bp('RightHand',8*s,12*c,0)
                    bp('LeftUpperArm',24-6*c,-22,-14-4*s)
                    bp('LeftLowerArm',54+10*s,-28,14)
                    bp('LeftHand',18*c,-16*s,12*s)
                    bp('RightUpperLeg',16+4*s,2,-3)
                    bp('RightLowerLeg',-24-5*s,0,0)
                    bp('RightFoot',-10,0,0)
                    bp('LeftUpperLeg',8-3*s,-2,3)
                    bp('LeftLowerLeg',-16+4*s,0,0)
                    bp('LeftFoot',-8,0,0)
                else
                    bp('HumanoidRootNode',-4+2*s,10+3*c,0,0,-0.03+0.035*s,0)
                    bp('LowerTorso',-3+2*s,-8+3*c,2.5*c)
                    bp('UpperTorso',-5+3*s,12-4*c,-2.5*c)
                    bp('Head',6-2*s,-10+4*c,2*s)
                    bp('RightUpperArm',18+5*s,16,14+3*c)
                    bp('RightLowerArm',42+6*c,20,-10)
                    bp('RightHand',6*s,10*c,0)
                    bp('LeftUpperArm',22-4*s,-18,-14-3*c)
                    bp('LeftLowerArm',48-5*c,-22,10)
                    bp('LeftHand',-6*s,-8*c,0)
                    bp('RightUpperLeg',18-3*s,3,-4)
                    bp('RightLowerLeg',-22+4*s,0,0)
                    bp('RightFoot',6,0,0)
                    bp('LeftUpperLeg',12-3*s,-3,4)
                    bp('LeftLowerLeg',-16+4*s,0,0)
                    bp('LeftFoot',6,0,0)
                end
                bp('Cape01',-14-6*s,5*c,4*s)
                bp('Cape02',-10-8*c,7*s,5*c)
                bp('Cape03',-8-10*s2,8*c,6*s)
            end)
            clips.TS_Idle=clips.Idle

            -- 2. CONFIDENT MARTIAL WALK (Full hip weight transfer & crisp stride)
            clips.Walk=buildClip(31,30,true,false,function(t,bp,s,c,ph)
                local bounce=math.abs(c)
                local rLift=max(0,s)
                local lLift=max(0,-s)
                bp('HumanoidRootNode',-6,0,2.5*c,0,0.045*bounce-0.02,0)
                bp('LowerTorso',-4,-10*s,4*c)
                bp('UpperTorso',-6,14*s,-4*c)
                bp('Head',8,-6*s,0)
                bp('RightUpperArm',-28*s+8,14*-s+8,10)
                bp('RightLowerArm',32+18*max(0,-s),12,-8)
                bp('LeftUpperArm',28*s+8,-14*s-8,-10)
                bp('LeftLowerArm',32+18*max(0,s),-12,8)
                bp('RightUpperLeg',38*s+4,2*s,-2)
                bp('RightLowerLeg',-12-38*lLift,0,0)
                bp('RightFoot',14*s-6*lLift,0,0)
                bp('LeftUpperLeg',-38*s+4,2*s,2)
                bp('LeftLowerLeg',-12-38*rLift,0,0)
                bp('LeftFoot',-14*s-6*rLift,0,0)
                bp('Cape01',-20-6*bounce,8*s,4*c)
                bp('Cape02',-16-8*s,10*c,5*s)
                bp('Cape03',-12-10*c,12*s,6*c)
            end)

            -- 3. HIGH-ENERGY ANIME SPRINT (Run & TS_Run)
            clips.Run=buildClip(21,30,true,false,function(t,bp,s,c,ph)
                local bounce=sin(ph*2)
                local rSwing=max(0,s)
                local lSwing=max(0,-s)
                if isStriker then
                    -- Iconic Assassin Swept-Back Dual-Dagger Sprint
                    bp('HumanoidRootNode',-22+2*bounce,0,4*s,0,0.065*math.abs(c)-0.04,0)
                    bp('LowerTorso',-8,-14*s,5*c)
                    bp('UpperTorso',-14,20*s,-5*c)
                    bp('Head',30,-10*s,0)
                    bp('RightUpperArm',-44+10*s,-14,24+6*c)
                    bp('RightLowerArm',34+10*c,18,-12)
                    bp('RightHand',-18,12,0)
                    bp('LeftUpperArm',-44-10*s,14,-24-6*c)
                    bp('LeftLowerArm',34-10*c,-18,12)
                    bp('LeftHand',-18,-12,0)
                else
                    -- Powerful Pumping Anime Combat Sprint
                    bp('HumanoidRootNode',-15+2*bounce,0,3.5*s,0,0.065*math.abs(c)-0.03,0)
                    bp('LowerTorso',-6,-14*s,5*c)
                    bp('UpperTorso',-12,22*s,-5*c)
                    bp('Head',22,-10*s,0)
                    bp('RightUpperArm',-46*s+12,24*lSwing-8,12)
                    bp('RightLowerArm',42+32*lSwing,18,-10)
                    bp('LeftUpperArm',46*s+12,-24*rSwing+8,-12)
                    bp('LeftLowerArm',42+32*rSwing,-18,10)
                end
                bp('RightUpperLeg',56*s+8,3*s,-2.5)
                bp('RightLowerLeg',-18-56*lSwing,0,0)
                bp('RightFoot',18*s-14*lSwing,0,0)
                bp('LeftUpperLeg',-56*s+8,3*s,2.5)
                bp('LeftLowerLeg',-18-56*rSwing,0,0)
                bp('LeftFoot',-18*s-14*rSwing,0,0)
                bp('Cape01',-42-8*math.abs(s),12*s,6*c)
                bp('Cape02',-28-12*c,14*c,8*s)
                bp('Cape03',-20-14*s,16*s,10*c)
            end)
            clips.TS_Run=clips.Run

            -- 4. EXPLOSIVE GROUND JUMP LAUNCH (Jump & TS_Jump)
            clips.Jump=buildClip(23,30,false,false,function(t,bp)
                local launch=env(t,{{0,0},{0.18,1},{0.68,0.88},{1,0.72}})
                local reach=env(t,{{0,0},{0.28,1},{0.75,0.85},{1,0.65}})
                bp('HumanoidRootNode',-10*launch,6*launch,0,0,0.12*launch,0)
                bp('LowerTorso',-6*launch,-8*launch,0)
                bp('UpperTorso',-8*launch+10*(1-launch),12*launch,0)
                bp('Head',14*launch,-6*launch,0)
                bp('RightUpperArm',58*reach,18*reach,-18*reach)
                bp('RightLowerArm',42*reach,18*reach,-10)
                bp('LeftUpperArm',54*reach,-18*reach,18*reach)
                bp('LeftLowerArm',44*reach,-18*reach,10)
                -- High Right Knee Drive + Straight Left Push-Off Leg
                bp('RightUpperLeg',74*launch,4,-5)
                bp('RightLowerLeg',-72*launch,0,0)
                bp('RightFoot',16*launch,0,0)
                bp('LeftUpperLeg',-38*launch,-3,4)
                bp('LeftLowerLeg',-14*launch-22*(1-launch),0,0)
                bp('LeftFoot',-28*launch,0,0)
                bp('Cape01',-46*launch,0,0)
                bp('Cape02',-32*launch,0,0)
                bp('Cape03',-24*launch,0,0)
            end)
            clips.TS_Jump=clips.Jump

            -- 5A. GEPPO SKY-WALK STEP 1: LEFT-FOOT MID-AIR STOMP (DoubleJump_L)
            clips.DoubleJump_L=buildClip(21,30,false,false,function(t,bp)
                -- Phase 1 (0..0.18): Quick mid-air leg gather; Phase 2 (0.18..0.52): Violent Left-Foot Downward Stomp + Right High Knee Drive!
                local gather=env(t,{{0,0},{0.15,1},{0.32,0},{1,0}})
                local stomp=env(t,{{0,0},{0.14,0},{0.34,1},{0.72,0.86},{1,0.55}})
                bp('HumanoidRootNode',-14*stomp+8*gather,-16*stomp,6*stomp,0,0.16*stomp-0.06*gather,-0.08*stomp)
                bp('LowerTorso',-8*stomp,-18*stomp,6*stomp)
                bp('UpperTorso',-12*stomp,28*stomp,-6*stomp)
                bp('Head',20*stomp,-14*stomp,0)
                -- Right arm punches skyward, Left arm sweeps down-back with the kick
                bp('RightUpperArm',82*stomp+20*gather,24*stomp,-16*stomp)
                bp('RightLowerArm',52*stomp+35*gather,20*stomp,-12)
                bp('LeftUpperArm',-38*stomp+32*gather,14*stomp,-28*stomp)
                bp('LeftLowerArm',36*stomp+45*gather,-16,10)
                -- Right Knee drives high to chest (+86 deg), Left Leg kicks straight down (-42 deg thigh, -6 deg knee, -34 deg pointed toe!)
                bp('RightUpperLeg',86*stomp+35*gather,6,-6)
                bp('RightLowerLeg',-84*stomp-55*gather,0,0)
                bp('RightFoot',20*stomp,0,0)
                bp('LeftUpperLeg',52*gather-42*stomp,-4,5)
                bp('LeftLowerLeg',-72*gather-6*stomp,0,0)
                bp('LeftFoot',14*gather-34*stomp,0,0)
                bp('Cape01',-58*stomp-20*gather,-12*stomp,0)
                bp('Cape02',-42*stomp,0,0)
                bp('Cape03',-30*stomp,0,0)
            end)

            -- 5B. GEPPO SKY-WALK STEP 2: RIGHT-FOOT MID-AIR STOMP (DoubleJump_R)
            clips.DoubleJump_R=buildClip(21,30,false,false,function(t,bp)
                -- Exact mirror: Quick Right-Leg gather -> Violent Right-Foot Downward Stomp + Left High Knee Drive!
                local gather=env(t,{{0,0},{0.15,1},{0.32,0},{1,0}})
                local stomp=env(t,{{0,0},{0.14,0},{0.34,1},{0.72,0.86},{1,0.55}})
                bp('HumanoidRootNode',-14*stomp+8*gather,16*stomp,-6*stomp,0,0.16*stomp-0.06*gather,-0.08*stomp)
                bp('LowerTorso',-8*stomp,18*stomp,-6*stomp)
                bp('UpperTorso',-12*stomp,-28*stomp,6*stomp)
                bp('Head',20*stomp,14*stomp,0)
                -- Left arm punches skyward, Right arm sweeps down-back with the kick
                bp('LeftUpperArm',82*stomp+20*gather,-24*stomp,16*stomp)
                bp('LeftLowerArm',52*stomp+35*gather,-20*stomp,12)
                bp('RightUpperArm',-38*stomp+32*gather,-14*stomp,28*stomp)
                bp('RightLowerArm',36*stomp+45*gather,16,-10)
                -- Left Knee drives high to chest (+86 deg), Right Leg kicks straight down (-42 deg thigh, -6 deg knee, -34 deg pointed toe!)
                bp('LeftUpperLeg',86*stomp+35*gather,-6,6)
                bp('LeftLowerLeg',-84*stomp-55*gather,0,0)
                bp('LeftFoot',20*stomp,0,0)
                bp('RightUpperLeg',52*gather-42*stomp,4,-5)
                bp('RightLowerLeg',-72*gather-6*stomp,0,0)
                bp('RightFoot',14*gather-34*stomp,0,0)
                bp('Cape01',-58*stomp-20*gather,12*stomp,0)
                bp('Cape02',-42*stomp,0,0)
                bp('Cape03',-30*stomp,0,0)
            end)

            -- 5C. GEPPO SKY-WALK STEP 3: 360-DEGREE ACROBATIC SOMERSAULT VAULT (DoubleJump_Flip)
            clips.DoubleJump_Flip=buildClip(23,30,false,false,function(t,bp)
                local flipProg=env(t,{{0,0},{0.72,1},{1,1}})
                local tuck=env(t,{{0,0},{0.18,1},{0.58,1},{0.82,0},{1,0}})
                local openStomp=env(t,{{0,0},{0.62,0},{0.82,1},{1,0.75}})
                bp('HumanoidRootNode',-360*flipProg-10*openStomp,0,0,0,0.22*tuck+0.12*openStomp,0)
                bp('LowerTorso',-22*tuck-6*openStomp,0,0)
                bp('UpperTorso',-28*tuck+12*openStomp,0,0)
                bp('Head',-18*tuck+18*openStomp,0,0)
                bp('RightUpperArm',78*tuck+64*openStomp,28*tuck-22*openStomp,-12*tuck-26*openStomp)
                bp('RightLowerArm',72*tuck+28*openStomp,20,-10)
                bp('LeftUpperArm',78*tuck+64*openStomp,-28*tuck+22*openStomp,12*tuck+26*openStomp)
                bp('LeftLowerArm',72*tuck+28*openStomp,-20,10)
                bp('RightUpperLeg',88*tuck+68*openStomp,4,-6)
                bp('RightLowerLeg',-94*tuck-64*openStomp,0,0)
                bp('RightFoot',18*tuck-20*openStomp,0,0)
                bp('LeftUpperLeg',88*tuck-36*openStomp,-4,6)
                bp('LeftLowerLeg',-94*tuck-12*openStomp,0,0)
                bp('LeftFoot',18*tuck-30*openStomp,0,0)
                bp('Cape01',-64*(tuck+openStomp),0,0)
                bp('Cape02',-44*(tuck+openStomp),0,0)
                bp('Cape03',-32*(tuck+openStomp),0,0)
            end)
            clips.DoubleJump=clips.DoubleJump_L
            clips.TS_DoubleJump=clips.DoubleJump_L

            -- 6A. DYNAMIC AERIAL SKYDIVER FLOAT (FallLoop)
            clips.FallLoop=buildClip(27,30,true,false,function(t,bp,s,c)
                bp('HumanoidRootNode',-12+3*s,4*c,3*s,0,0.05*s,0)
                bp('LowerTorso',-6+2*s,-6*c,3*s)
                bp('UpperTorso',-10+3*c,8*c,-3*s)
                bp('Head',18-3*s,-6*c,0)
                bp('RightUpperArm',42+10*s,-18,28+8*c)
                bp('RightLowerArm',36+8*c,14,-12)
                bp('LeftUpperArm',42-10*s,18,-28-8*c)
                bp('LeftLowerArm',36-8*c,-14,12)
                bp('RightUpperLeg',56+6*s,5,-6)
                bp('RightLowerLeg',-68-6*c,0,0)
                bp('RightFoot',-14+4*s,0,0)
                bp('LeftUpperLeg',-20-6*s,-5,6)
                bp('LeftLowerLeg',-38+6*c,0,0)
                bp('LeftFoot',-22-4*s,0,0)
                bp('Cape01',-58-8*s,10*c,6*s)
                bp('Cape02',-42-10*c,12*s,8*c)
                bp('Cape03',-32-12*s,14*c,10*s)
            end)
            clips.JumpLoop=clips.FallLoop

            -- 6B. SUPERHERO 3-POINT ATHLETIC LANDING CROUCH (Land)
            clips.Land=buildClip(17,30,false,false,function(t,bp)
                local impact=env(t,{{0,0.2},{0.25,1},{0.62,0.75},{1,0}})
                bp('HumanoidRootNode',-18*impact,12*impact,0,0,-0.24*impact,-0.06*impact)
                bp('LowerTorso',-14*impact,-12*impact,0)
                bp('UpperTorso',-22*impact,18*impact,0)
                bp('Head',26*impact,-12*impact,0)
                bp('RightUpperArm',-28*impact,-14*impact,24*impact)
                bp('RightLowerArm',44*impact,16,-10)
                bp('LeftUpperArm',52*impact,-18*impact,-16*impact)
                bp('LeftLowerArm',38*impact,-18,10)
                bp('RightUpperLeg',64*impact,6,-6)
                bp('RightLowerLeg',-76*impact,0,0)
                bp('RightFoot',18*impact,0,0)
                bp('LeftUpperLeg',38*impact,-6,6)
                bp('LeftLowerLeg',-58*impact,0,0)
                bp('LeftFoot',14*impact,0,0)
                bp('Cape01',-48*impact,0,0)
                bp('Cape02',-34*impact,0,0)
                bp('Cape03',-24*impact,0,0)
            end)

            -- 7A. SUPERSONIC JET-LUNGE DASH (Dash, AirDash, TS_Dash, FlashStep)
            clips.Dash=buildClip(21,30,false,false,function(t,bp)
                local burst=env(t,{{0,0},{0.16,1},{0.72,0.92},{1,0}})
                local slice=env(t,{{0,0},{0.22,1},{0.68,0.85},{1,0}})
                bp('HumanoidRootNode',-28*burst,14*burst,0,0,0.06*burst,-0.24*burst)
                bp('LowerTorso',-14*burst,-16*burst,0)
                bp('UpperTorso',-20*burst,26*burst,0)
                bp('Head',36*burst,-18*burst,0)
                bp('RightUpperArm',78*slice-24*(1-slice),26*slice,16*burst)
                bp('RightLowerArm',34*slice+20,18,-10)
                bp('LeftUpperArm',-52*burst,16*burst,-26*burst)
                bp('LeftLowerArm',46*burst,-20,12)
                -- High Front Left Knee + Streamlined Rear Right Leg
                bp('LeftUpperLeg',72*burst,-4,5)
                bp('LeftLowerLeg',-76*burst,0,0)
                bp('LeftFoot',16*burst,0,0)
                bp('RightUpperLeg',-52*burst,4,-5)
                bp('RightLowerLeg',-16*burst,0,0)
                bp('RightFoot',-32*burst,0,0)
                bp('Cape01',-66*burst,8*burst,0)
                bp('Cape02',-48*burst,0,0)
                bp('Cape03',-36*burst,0,0)
            end)
            clips.AirDash=clips.Dash
            clips.TS_Dash=clips.Dash
            clips.TS_AirDash=clips.Dash
            clips.FlashStep=clips.Dash

            -- 7B. EVASIVE SPIN-GUARD DODGE / BACKSTEP (Dodge, BackDash, SideDash)
            clips.Dodge=buildClip(17,30,false,false,function(t,bp)
                local ev=env(t,{{0,0},{0.20,1},{0.74,0.88},{1,0}})
                bp('HumanoidRootNode',-12*ev,-28*ev,8*ev,0,-0.20*ev,0.14*ev)
                bp('LowerTorso',-10*ev,-18*ev,6*ev)
                bp('UpperTorso',-16*ev,34*ev,-6*ev)
                bp('Head',22*ev,-16*ev,0)
                bp('LeftUpperArm',78*ev,-34*ev,16*ev)
                bp('LeftLowerArm',68*ev,-24*ev,12)
                bp('RightUpperArm',-32*ev,-18*ev,26*ev)
                bp('RightLowerArm',52*ev,18,-12)
                bp('RightUpperLeg',58*ev,8,-8)
                bp('RightLowerLeg',-68*ev,0,0)
                bp('RightFoot',16*ev,0,0)
                bp('LeftUpperLeg',-36*ev,-8,8)
                bp('LeftLowerLeg',-38*ev,0,0)
                bp('LeftFoot',-18*ev,0,0)
                bp('Cape01',-54*ev,-16*ev,0)
                bp('Cape02',-38*ev,0,0)
                bp('Cape03',-26*ev,0,0)
            end)
            clips.BackDash=clips.Dodge

            -- 8A. M1 COMBO 1: WIDE HORIZONTAL INWARD CLEAVE + FORWARD LUNGE (Attack01)
            clips.Attack01=buildClip(19,30,false,false,function(t,bp)
                local windup=env(t,{{0,0},{0.24,1},{0.44,0},{1,0}})
                local slash=env(t,{{0,0},{0.22,0},{0.46,1},{0.78,0.82},{1,0}})
                bp('HumanoidRootNode',-12*slash+6*windup,18*slash-16*windup,0,0,-0.08*slash,-0.22*slash+0.06*windup)
                bp('LowerTorso',-8*slash,-24*windup+28*slash,0)
                bp('UpperTorso',-14*slash,-34*windup+46*slash,4*slash)
                bp('Head',16*slash,22*windup-28*slash,0)
                bp('RightUpperArm',64*windup+94*slash,-42*windup+44*slash,24*windup+18*slash)
                bp('RightLowerArm',68*windup+18*slash,16,-10)
                bp('RightHand',-18*windup+26*slash,14*slash,0)
                bp('LeftUpperArm',28*windup-36*slash,-18*windup+16*slash,-18)
                bp('LeftLowerArm',48*windup+32*slash,-18,10)
                bp('RightUpperLeg',52*slash-16*windup,4,-5)
                bp('RightLowerLeg',-56*slash-22*windup,0,0)
                bp('RightFoot',16*slash,0,0)
                bp('LeftUpperLeg',-38*slash+22*windup,-4,5)
                bp('LeftLowerLeg',-20*slash-28*windup,0,0)
                bp('LeftFoot',-22*slash,0,0)
                bp('Cape01',-44*slash-18*windup,18*slash,0)
                bp('Cape02',-32*slash,12*slash,0)
                bp('Cape03',-24*slash,0,0)
            end)
            clips.Attack=clips.Attack01
            clips.Attack1=clips.Attack01

            -- 8B. M1 COMBO 2: RISING DIAGONAL REVERSE CROSS-SLASH + LEFT STEP (Attack02)
            clips.Attack02=buildClip(19,30,false,false,function(t,bp)
                local coil=env(t,{{0,0},{0.24,1},{0.44,0},{1,0}})
                local rip=env(t,{{0,0},{0.22,0},{0.46,1},{0.78,0.82},{1,0}})
                bp('HumanoidRootNode',-10*rip,-20*rip+14*coil,0,0,-0.06*rip,-0.22*rip+0.05*coil)
                bp('LowerTorso',-8*rip,26*coil-32*rip,0)
                bp('UpperTorso',-12*rip,38*coil-48*rip,-4*rip)
                bp('Head',14*rip,-24*coil+30*rip,0)
                bp('RightUpperArm',52*coil+106*rip,46*coil-46*rip,-16*coil+28*rip)
                bp('RightLowerArm',62*coil+16*rip,20,-10)
                bp('RightHand',16*coil-24*rip,-16*rip,0)
                bp('LeftUpperArm',38*coil+88*rip,-24*coil-34*rip,14*coil-20*rip)
                bp('LeftLowerArm',54*coil+22*rip,-18,10)
                bp('LeftUpperLeg',54*rip-14*coil,-4,5)
                bp('LeftLowerLeg',-58*rip-22*coil,0,0)
                bp('LeftFoot',16*rip,0,0)
                bp('RightUpperLeg',-38*rip+22*coil,4,-5)
                bp('RightLowerLeg',-22*rip-28*coil,0,0)
                bp('RightFoot',-22*rip,0,0)
                bp('Cape01',-46*rip-18*coil,-18*rip,0)
                bp('Cape02',-34*rip,-12*rip,0)
                bp('Cape03',-24*rip,0,0)
            end)
            clips.Attack2=clips.Attack02

            -- 8C. M1 COMBO 3: 360-DEGREE WHIRLWIND CLEAVE FINISHER (Attack03)
            clips.Attack03=buildClip(23,30,false,false,function(t,bp)
                local crouch=env(t,{{0,0},{0.20,1},{0.38,0},{1,0}})
                local spinProg=env(t,{{0,0},{0.18,0},{0.74,1},{1,1}})
                local cleave=env(t,{{0,0},{0.20,0},{0.48,1},{0.82,0.88},{1,0}})
                bp('HumanoidRootNode',-14*cleave-10*crouch,360*spinProg,0,0,0.18*cleave-0.14*crouch,-0.28*cleave)
                bp('LowerTorso',-10*cleave,-28*crouch+24*cleave,0)
                bp('UpperTorso',-16*cleave,-38*crouch+38*cleave,0)
                bp('Head',20*cleave,20*crouch-18*cleave,0)
                bp('RightUpperArm',54*crouch+102*cleave,-36*crouch+22*cleave,28*cleave)
                bp('RightLowerArm',64*crouch+14*cleave,16,-10)
                bp('LeftUpperArm',48*crouch+94*cleave,28*crouch-22*cleave,-28*cleave)
                bp('LeftLowerArm',58*crouch+18*cleave,-16,10)
                bp('RightUpperLeg',58*cleave+38*crouch,6,-8)
                bp('RightLowerLeg',-62*cleave-48*crouch,0,0)
                bp('RightFoot',18*cleave,0,0)
                bp('LeftUpperLeg',-36*cleave+28*crouch,-6,8)
                bp('LeftLowerLeg',-24*cleave-36*crouch,0,0)
                bp('LeftFoot',-24*cleave,0,0)
                bp('Cape01',-64*cleave,0,0)
                bp('Cape02',-48*cleave,0,0)
                bp('Cape03',-36*cleave,0,0)
            end)
            clips.Attack3=clips.Attack03

            -- 8D. TWIN-DAGGER LIGHTNING FLURRY (DaggerCombo & TS_DaggerCombo)
            clips.DaggerCombo=buildClip(35,30,false,false,function(t,bp,s,c)
                local s1=env(t,{{0,0},{0.18,1},{0.34,0},{1,0}})
                local s2=env(t,{{0,0},{0.28,0},{0.46,1},{0.64,0},{1,0}})
                local s3=env(t,{{0,0},{0.56,0},{0.78,1},{0.92,0.85},{1,0}})
                local spin=env(t,{{0,0},{0.54,0},{0.84,1},{1,1}})
                bp('HumanoidRootNode',-18*(s1+s2+s3),360*spin+28*s1-28*s2,0,0,0.16*s3-0.08*(s1+s2),-0.24*(s1+s2+s3))
                bp('LowerTorso',-12*(s1+s2+s3),32*s1-32*s2,0)
                bp('UpperTorso',-18*(s1+s2+s3),46*s1-46*s2+24*s3,0)
                bp('Head',24*(s1+s2+s3),-24*s1+24*s2,0)
                bp('RightUpperArm',98*s1-32*s2+108*s3,34*s1+28*s3,20)
                bp('RightLowerArm',22*s1+58*s2+18*s3,18,-10)
                bp('LeftUpperArm',-32*s1+98*s2+108*s3,-34*s2-28*s3,-20)
                bp('LeftLowerArm',58*s1+22*s2+18*s3,-18,10)
                bp('RightUpperLeg',54*(s1+s3)-32*s2,5,-6)
                bp('RightLowerLeg',-58*(s1+s3)-24*s2,0,0)
                bp('LeftUpperLeg',-34*(s1+s3)+54*s2,-5,6)
                bp('LeftLowerLeg',-24*(s1+s3)-58*s2,0,0)
                bp('Cape01',-58*(s1+s2+s3),16*(s1-s2),0)
                bp('Cape02',-42*(s1+s2+s3),0,0)
                bp('Cape03',-30*(s1+s2+s3),0,0)
            end)
            clips.TS_DaggerCombo=clips.DaggerCombo

            -- 9. LEAPING OVERHEAD METEOR CLEAVE (Heavy & JudgmentStrike)
            clips.Heavy=buildClip(29,30,false,false,function(t,bp)
                local leap=env(t,{{0,0},{0.32,1},{0.52,0},{1,0}})
                local slam=env(t,{{0,0},{0.34,0},{0.54,1},{0.84,0.88},{1,0}})
                bp('HumanoidRootNode',16*leap-24*slam,0,0,0,0.38*leap-0.22*slam,-0.28*slam)
                bp('LowerTorso',12*leap-18*slam,0,0)
                bp('UpperTorso',20*leap-28*slam,0,0)
                bp('Head',18*leap+26*slam,0,0)
                bp('RightUpperArm',134*leap+36*slam,38*leap+28*slam,22*leap-12*slam)
                bp('RightLowerArm',48*leap+18*slam,24,-10)
                bp('LeftUpperArm',132*leap+36*slam,-38*leap-28*slam,-22*leap+12*slam)
                bp('LeftLowerArm',48*leap+18*slam,-24,10)
                bp('RightUpperLeg',68*leap+58*slam,6,-6)
                bp('RightLowerLeg',-74*leap-66*slam,0,0)
                bp('RightFoot',16*slam-20*leap,0,0)
                bp('LeftUpperLeg',-32*leap-42*slam,-6,6)
                bp('LeftLowerLeg',-28*leap-24*slam,0,0)
                bp('LeftFoot',-26*(leap+slam),0,0)
                bp('Cape01',-64*(leap+slam),0,0)
                bp('Cape02',-46*(leap+slam),0,0)
                bp('Cape03',-34*(leap+slam),0,0)
            end)
            clips.JudgmentStrike=clips.Heavy

            -- 10A. SKILL [Z] & FRUIT [Z]: COILED MARTIAL GATHER -> EXPLOSIVE PIERCING BEAM / THRUST
            clips.SkillZ=buildClip(23,30,false,true,function(t,bp)
                local coil=env(t,{{0,0},{0.26,1},{0.44,0},{1,0}})
                local thrust=env(t,{{0,0},{0.24,0},{0.46,1},{0.84,0.90},{1,0}})
                bp('HumanoidRootNode',-16*thrust+6*coil,22*thrust-24*coil,0,0,-0.10*coil-0.06*thrust,-0.24*thrust+0.08*coil)
                bp('LowerTorso',-10*thrust,-28*coil+32*thrust,0)
                bp('UpperTorso',-16*thrust,-38*coil+46*thrust,0)
                bp('Head',22*thrust,26*coil-34*thrust,0)
                bp('RightUpperArm',34*coil+96*thrust,-38*coil+22*thrust,24*coil+12*thrust)
                bp('RightLowerArm',72*coil+12*thrust,18,-8)
                bp('LeftUpperArm',82*coil+76*thrust,-22*coil-18*thrust,-16*thrust)
                bp('LeftLowerArm',48*coil+24*thrust,-18,8)
                bp('RightUpperLeg',56*thrust+28*coil,5,-6)
                bp('RightLowerLeg',-62*thrust-38*coil,0,0)
                bp('LeftUpperLeg',-42*thrust+24*coil,-5,6)
                bp('LeftLowerLeg',-20*thrust-34*coil,0,0)
                bp('Cape01',-56*thrust-20*coil,16*thrust,0)
                bp('Cape02',-40*thrust,0,0)
                bp('Cape03',-28*thrust,0,0)
            end)
            clips.FruitZ=clips.SkillZ
            clips.SkySlash=clips.SkillZ
            clips.FrostBolt=clips.SkillZ
            clips.ArcCut=clips.SkillZ

            -- 10B. SKILL [X] & FRUIT [X]: LOW GROUND CHARGE -> SKYWARD TWIN-PILLAR ERUPTION
            clips.SkillX=buildClip(27,30,false,true,function(t,bp)
                local crouch=env(t,{{0,0},{0.28,1},{0.48,0},{1,0}})
                local erupt=env(t,{{0,0},{0.26,0},{0.50,1},{0.84,0.88},{1,0}})
                bp('HumanoidRootNode',-22*crouch+14*erupt,0,0,0,-0.26*crouch+0.34*erupt,-0.12*erupt)
                bp('LowerTorso',-16*crouch+12*erupt,0,0)
                bp('UpperTorso',-24*crouch+24*erupt,0,0)
                bp('Head',24*crouch+26*erupt,0,0)
                bp('RightUpperArm',42*crouch+128*erupt,28*crouch+18*erupt,-18*crouch+28*erupt)
                bp('RightLowerArm',68*crouch+22*erupt,18,-10)
                bp('LeftUpperArm',42*crouch+128*erupt,-28*crouch-18*erupt,18*crouch-28*erupt)
                bp('LeftLowerArm',68*crouch+22*erupt,-18,10)
                bp('RightUpperLeg',66*crouch+64*erupt,8,-8)
                bp('RightLowerLeg',-78*crouch-68*erupt,0,0)
                bp('LeftUpperLeg',58*crouch-28*erupt,-8,8)
                bp('LeftLowerLeg',-72*crouch-24*erupt,0,0)
                bp('Cape01',-62*(crouch+erupt),0,0)
                bp('Cape02',-44*(crouch+erupt),0,0)
                bp('Cape03',-32*(crouch+erupt),0,0)
            end)
            clips.FruitX=clips.SkillX
            clips.ArcaneCircle=clips.SkillX
            clips.StormBlitz=clips.SkillX

            -- 10C. SKILL [C] & FRUIT [C]: 720-DEGREE HURRICANE VORTEX BARRAGE
            clips.SkillC=buildClip(31,30,false,true,function(t,bp)
                local spinProg=env(t,{{0,0},{0.12,0},{0.82,1},{1,1}})
                local active=env(t,{{0,0},{0.18,1},{0.80,1},{1,0}})
                bp('HumanoidRootNode',-12*active,720*spinProg,0,0,0.32*active,-0.18*active)
                bp('LowerTorso',-8*active,24*active,0)
                bp('UpperTorso',-14*active,36*active,0)
                bp('Head',18*active,-20*active,0)
                bp('RightUpperArm',98*active,16*active,34*active)
                bp('RightLowerArm',18*active,14,-10)
                bp('LeftUpperArm',98*active,-16*active,-34*active)
                bp('LeftLowerArm',18*active,-14,10)
                bp('RightUpperLeg',68*active,12,-14)
                bp('RightLowerLeg',-58*active,0,0)
                bp('LeftUpperLeg',-32*active,-12,14)
                bp('LeftLowerLeg',-28*active,0,0)
                bp('Cape01',-68*active,0,0)
                bp('Cape02',-52*active,0,0)
                bp('Cape03',-38*active,0,0)
            end)
            clips.FruitC=clips.SkillC

            -- 10D. SKILL [V] & FRUIT [V] & ULTIMATES: ASCENSION LEVITATION -> GOD RELEASE -> CATACLYSM SLAM
            clips.SkillV=buildClip(37,30,false,true,function(t,bp)
                local charge=env(t,{{0,0},{0.18,1},{0.34,0},{1,0}})
                local release=env(t,{{0,0},{0.28,0},{0.46,1},{0.74,1},{0.88,0},{1,0}})
                local slam=env(t,{{0,0},{0.70,0},{0.84,1},{1,0}})
                bp('HumanoidRootNode',-14*charge+22*release-22*slam,0,0,0,0.32*charge+0.56*release-0.20*slam,-0.20*slam)
                bp('LowerTorso',-10*charge+14*release-16*slam,0,0)
                bp('UpperTorso',-18*charge+28*release-24*slam,0,0)
                bp('Head',-20*charge+32*release+24*slam,0,0)
                bp('RightUpperArm',78*charge+126*release+44*slam,46*charge-24*release+24*slam,-14*charge+38*release)
                bp('RightLowerArm',68*charge+22*release+20*slam,22,-10)
                bp('LeftUpperArm',78*charge+126*release+44*slam,-46*charge+24*release-24*slam,14*charge-38*release)
                bp('LeftLowerArm',68*charge+22*release+20*slam,-22,10)
                bp('RightUpperLeg',56*charge+62*release+58*slam,8,-10)
                bp('RightLowerLeg',-68*charge-72*release-64*slam,0,0)
                bp('LeftUpperLeg',56*charge-24*release-36*slam,-8,10)
                bp('LeftLowerLeg',-68*charge-28*release-24*slam,0,0)
                bp('Cape01',-66*(charge+release+slam),0,0)
                bp('Cape02',-48*(charge+release+slam),0,0)
                bp('Cape03',-36*(charge+release+slam),0,0)
            end)
            clips.FruitV=clips.SkillV
            clips.Ultimate=clips.SkillV
            clips.CelestialAegis=clips.SkillV
            clips.ThunderJudgement=clips.SkillV
            clips.FrostNova=clips.SkillV
            clips.UltimateAwakening=clips.SkillV
            clips.HakiAwaken=clips.SkillV
            clips.ElementalSurge=clips.SkillZ
            clips.HeroicKata=clips.SkillC

            -- 10E. SKILL [F] & FRUIT [F]: SUPERSONIC SKY-FLIGHT GLIDE
            clips.SkillF=buildClip(25,30,false,true,function(t,bp,s,c)
                local fly=env(t,{{0,0},{0.16,1},{0.82,1},{1,0}})
                bp('HumanoidRootNode',-34*fly,6*s*fly,8*c*fly,0,0.28*fly,-0.26*fly)
                bp('LowerTorso',-12*fly,-8*s*fly,0)
                bp('UpperTorso',-18*fly,12*s*fly,0)
                bp('Head',42*fly,-8*s*fly,0)
                bp('RightUpperArm',88*fly,16*fly,18*fly)
                bp('RightLowerArm',22*fly,14,-10)
                bp('LeftUpperArm',-48*fly,18*fly,-28*fly)
                bp('LeftLowerArm',36*fly,-16,10)
                bp('LeftUpperLeg',64*fly,-4,5)
                bp('LeftLowerLeg',-72*fly,0,0)
                bp('RightUpperLeg',-44*fly,4,-5)
                bp('RightLowerLeg',-18*fly,0,0)
                bp('RightFoot',-30*fly,0,0)
                bp('Cape01',-68*fly,10*s*fly,0)
                bp('Cape02',-50*fly,12*c*fly,0)
                bp('Cape03',-38*fly,14*s*fly,0)
            end)
            clips.FruitF=clips.SkillF

            -- 11. DEFENSIVE SHIELD / BARRIER GUARD (ShieldRaise, ShieldLoop, ManaBarrier)
            clips.ShieldRaise=buildClip(21,30,false,false,function(t,bp,s,c)
                local g=env(t,{{0,0},{0.22,1},{0.85,1},{1,0.85}})
                bp('HumanoidRootNode',-8*g,-16*g,0,0,-0.12*g,0.06*g)
                bp('LowerTorso',-6*g,-14*g,0)
                bp('UpperTorso',-10*g,26*g,0)
                bp('Head',14*g,-18*g,0)
                bp('LeftUpperArm',82*g,-36*g,16*g)
                bp('LeftLowerArm',64*g,-24*g,12)
                bp('RightUpperArm',28*g,18*g,22*g)
                bp('RightLowerArm',54*g,18,-10)
                bp('RightUpperLeg',44*g,8,-8)
                bp('RightLowerLeg',-52*g,0,0)
                bp('LeftUpperLeg',-26*g,-8,8)
                bp('LeftLowerLeg',-32*g,0,0)
                bp('Cape01',-32*g,0,0)
                bp('Cape02',-24*g,0,0)
                bp('Cape03',-18*g,0,0)
            end)
            clips.ShieldLoop=clips.ShieldRaise
            clips.ManaBarrier=clips.ShieldRaise

            -- 12. HIT REACT & DEATH
            clips.HitReact=buildClip(15,30,false,false,function(t,bp)
                local jolt=env(t,{{0,0},{0.22,1},{0.65,0.6},{1,0}})
                bp('HumanoidRootNode',18*jolt,-14*jolt,6*jolt,0,-0.08*jolt,0.16*jolt)
                bp('LowerTorso',14*jolt,-12*jolt,0)
                bp('UpperTorso',24*jolt,18*jolt,0)
                bp('Head',28*jolt,-16*jolt,0)
                bp('RightUpperArm',38*jolt,-24*jolt,32*jolt)
                bp('RightLowerArm',46*jolt,16,-10)
                bp('LeftUpperArm',38*jolt,24*jolt,-32*jolt)
                bp('LeftLowerArm',46*jolt,-16,10)
                bp('RightUpperLeg',28*jolt,4,-5)
                bp('RightLowerLeg',-36*jolt,0,0)
                bp('LeftUpperLeg',-22*jolt,-4,5)
                bp('LeftLowerLeg',-28*jolt,0,0)
                bp('Cape01',-48*jolt,0,0)
            end)
            clips.Hit=clips.HitReact
        end
    end

    for _,loopKey in ipairs({'Idle','Walk','Run','Swim','FallLoop','JumpLoop','CombatReady','GuardStance','ShieldLoop','TalkIdle','TS_Idle','TS_Run','PatrolWalk','AggroCharge','SwimSurge','SoarFlight','WingGlide','ElementalSurge','HeroicKata','UltimateAwakening','WorldIdle_Loop','ElementalPulse','PortalSurge','AstrolabeSpin','CrystalResonance','TempestSway','CataclysmAwakening'}) do
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
function M.Pose(model,clip,time,dynCtx)
    if not model or not clip or not clip.Frames or #clip.Frames==0 then return end
    local root=model.PrimaryPart
    if not root then return end
    local bones=getModelBones(model,root)
    if not next(bones) then return end
    local st=poseState[model]
    local now=os.clock()
    local playStart=dynCtx and dynCtx.Start or nil
    if not st then
        st={clip=clip,switchAt=0,lastStart=playStart,fromPose={}}
        poseState[model]=st
    elseif st.clip~=clip or (playStart and st.lastStart~=playStart) then
        local fp={}
        for bname,bone in pairs(bones) do
            fp[bname]=bone.Transform
        end
        st.clip=clip
        st.switchAt=now
        st.lastStart=playStart
        st.fromPose=fp
    end
    local blendDur=(dynCtx and dynCtx.BlendTime) or 0.12
    local elapsed=math.max(now-st.switchAt,(time and time>=0 and time<100) and time or 0)
    local rawT=(st.switchAt>0 and elapsed<blendDur) and math.clamp(elapsed/blendDur,0,1) or 1
    local blend=rawT<1 and (rawT*rawT*(3-2*rawT)) or 1
    local fromPose=st.fromPose
    local numFrames=#clip.Frames
    if numFrames==1 then
        local f1=clip.Frames[1]
        if not f1 then return end
        for n,name in clip.Names do
            local bone=bones[name]
            if bone and f1[n] then
                local fromCF=fromPose and fromPose[name]
                bone.Transform=(blend<1 and fromCF) and fromCF:Lerp(f1[n],blend) or f1[n]
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
    local hasDyn=(type(dynCtx)=='table')
    local dynRootCF=nil
    local dynCapePitch=0
    if hasDyn then
        local pitch=dynCtx.Pitch or 0
        local roll=dynCtx.Roll or 0
        local squashY=dynCtx.SquashY or 0
        dynCapePitch=dynCtx.CapeWind or 0
        if math.abs(pitch)>0.002 or math.abs(roll)>0.002 or math.abs(squashY)>0.002 then
            dynRootCF=CFrame.new(0,squashY,0)*CFrame.fromEulerAnglesXYZ(pitch,0,roll)
        end
    end
    for n,name in clip.Names do
        local bone=bones[name]
        if bone and fi[n] and fj[n] then
            local target=fi[n]:Lerp(fj[n],alpha)
            if dynRootCF and (name=='HumanoidRootNode' or name=='Root') then
                target=dynRootCF*target
            elseif dynCapePitch~=0 and (name=='Cape01' or name=='Cape02') then
                target=target*CFrame.Angles(dynCapePitch,0,0)
            end
            local fromCF=fromPose and fromPose[name]
            bone.Transform=(blend<1 and fromCF) and fromCF:Lerp(target,blend) or target
        end
    end
end
M.CanonicalClips={'Idle','Walk','Run','Attack','Skill','ElementalSurge','HeroicKata','UltimateAwakening'}
M.CrossfadeDuration=0.12
return M

