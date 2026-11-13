local E={}
-- Built-in engine skybox (always loadable, zero 403 unauthorized asset errors).
-- Realm-specific sky mood comes from Atmosphere Color/Decay/Haze/Glare + SkybreakWorldClient.stepAtmosphereAndWeather (Rule 8).
local DEFAULT_SKY={bk="rbxasset://textures/sky/sky512_bk.tex",dn="rbxasset://textures/sky/sky512_dn.tex",ft="rbxasset://textures/sky/sky512_ft.tex",lf="rbxasset://textures/sky/sky512_lf.tex",rt="rbxasset://textures/sky/sky512_rt.tex",up="rbxasset://textures/sky/sky512_up.tex"}
local goldenSky=DEFAULT_SKY
local frozenSky=DEFAULT_SKY
local shadowSky=DEFAULT_SKY
local failedSets={}
local function setFaces(sky,images)
 sky.SkyboxFt=images.ft sky.SkyboxBk=images.bk sky.SkyboxLf=images.lf sky.SkyboxRt=images.rt sky.SkyboxUp=images.up sky.SkyboxDn=images.dn
end
E.Skyboxes={
GoldenSky=goldenSky,
FrozenCyber=frozenSky,
ShadowRealm=shadowSky,
VerdantCrown=goldenSky,
EmberforgeWastes=shadowSky,
AbyssalTides=frozenSky,
ChronosBastion=goldenSky,
VeilsEnd=shadowSky,
}
local presets={
GoldenSky={Fog=Color3.fromRGB(185,222,255),Decay=Color3.fromRGB(245,215,175),Density=.12,Haze=.12,Offset=.10,Glare=.08,FogStart=1200,FogEnd=12000},
FrozenCyber={Fog=Color3.fromRGB(156,208,252),Decay=Color3.fromRGB(98,146,208),Density=.13,Haze=.14,Offset=.10,Glare=.08,FogStart=1100,FogEnd=11000},
ShadowRealm={Fog=Color3.fromRGB(156,98,176),Decay=Color3.fromRGB(96,54,116),Density=.14,Haze=.15,Offset=.10,Glare=.08,FogStart=1000,FogEnd=10500},
VerdantCrown={Fog=Color3.fromRGB(188,238,214),Decay=Color3.fromRGB(144,206,172),Density=.12,Haze=.12,Offset=.10,Glare=.08,FogStart=1200,FogEnd=12000},
EmberforgeWastes={Fog=Color3.fromRGB(228,158,132),Decay=Color3.fromRGB(168,98,74),Density=.14,Haze=.14,Offset=.10,Glare=.08,FogStart=1100,FogEnd=11000},
AbyssalTides={Fog=Color3.fromRGB(152,212,248),Decay=Color3.fromRGB(94,152,204),Density=.13,Haze=.14,Offset=.10,Glare=.08,FogStart=1100,FogEnd=11000},
ChronosBastion={Fog=Color3.fromRGB(214,208,246),Decay=Color3.fromRGB(172,158,214),Density=.12,Haze=.12,Offset=.10,Glare=.08,FogStart=1200,FogEnd=12000},
VeilsEnd={Fog=Color3.fromRGB(164,122,204),Decay=Color3.fromRGB(104,72,148),Density=.14,Haze=.15,Offset=.10,Glare=.08,FogStart=1000,FogEnd=10500},
}
function E.Apply(name)
 if name=="SkyHub" or name=="" or not name then name="GoldenSky" end
 local p=presets[name] or presets.GoldenSky local images=E.Skyboxes[name] or E.Skyboxes.GoldenSky
 local lighting=game:GetService("Lighting")
 for _,child in ipairs(lighting:GetChildren()) do
  if (child:IsA("BloomEffect") and child.Name~="SkybreakBloom" and child.Name~="SkybreakVFXBloom") or (child:IsA("ColorCorrectionEffect") and child.Name~="SkybreakGrade" and child.Name~="SkybreakColorGrade" and child.Name~="InstinctVision") or (child:IsA("DepthOfFieldEffect") and child.Name~="SkybreakDistanceDOF") or child:IsA("ColorGradingEffect") or (child:IsA("SunRaysEffect") and child.Name~="SkybreakSunRays") then
   if child:IsA("PostEffect") then child.Enabled=false end
   child:Destroy()
  end
 end
 local sky=lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky",lighting) sky.Name="SKYBREAK_RealmSky"
 setFaces(sky,failedSets[images] and DEFAULT_SKY or images)
 sky.CelestialBodiesShown=true sky.StarCount=1200
 -- Rule 8: Brightness, ExposureCompensation, Bloom, ClockTime & ColorGrade are owned solely by stepAtmosphereAndWeather in SkybreakWorldClient.client.lua
 lighting.EnvironmentDiffuseScale=.88 lighting.EnvironmentSpecularScale=.65 lighting.ShadowSoftness=.20
 lighting.FogColor=p.Fog lighting.FogStart=p.FogStart or 1200 lighting.FogEnd=p.FogEnd or 12000
 local atmosphere=lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere",lighting)
 atmosphere.Color=p.Fog atmosphere.Decay=p.Decay atmosphere.Density=p.Density or .12 atmosphere.Offset=p.Offset or .10 atmosphere.Haze=math.min(p.Haze or .12,.16) atmosphere.Glare=math.min(p.Glare or .08,.10)
 local dof=lighting:FindFirstChild("SkybreakDistanceDOF") or Instance.new("DepthOfFieldEffect",lighting)
 dof.Name="SkybreakDistanceDOF" dof.Enabled=true dof.FarIntensity=.03 dof.FocusDistance=420 dof.InFocusRadius=580 dof.NearIntensity=0
 local sunRays=lighting:FindFirstChild("SkybreakSunRays") or Instance.new("SunRaysEffect",lighting) sunRays.Name="SkybreakSunRays" sunRays.Enabled=true sunRays.Intensity=.08 sunRays.Spread=.65
 lighting:SetAttribute("SkybreakEnvironment",name)
 return name
end
-- Called by RealmEnvironment.client after PreloadAsync reports a failed face. Swaps the live
-- sky to DEFAULT_SKY if it currently shows that set (covers ClientBootstrap's direct Apply()).
function E.MarkSkyFailed(name)
 local set=E.Skyboxes[name] if not set or failedSets[set] then return end
 failedSets[set]=true
 local lighting=game:GetService("Lighting")
 local cur=lighting:GetAttribute("SkybreakEnvironment")
 local sky=lighting:FindFirstChild("SKYBREAK_RealmSky")
 if sky and sky:IsA("Sky") and cur and E.Skyboxes[cur]==set then setFaces(sky,DEFAULT_SKY) end
end
return E
