local E={}
local goldenSky={lf="rbxassetid://125580929564532",up="rbxassetid://127430124985900",bk="rbxassetid://134226231755373",ft="rbxassetid://93641632642731",rt="rbxassetid://139087821108688",dn="rbxassetid://94264818636230"}
local frozenSky={bk="rbxassetid://130166325051175",lf="rbxassetid://134595860932390",up="rbxassetid://76551248708701",dn="rbxassetid://73836580094387",ft="rbxassetid://121870448069569",rt="rbxassetid://88459308214078"}
local shadowSky={ft="rbxassetid://139181899969965",bk="rbxassetid://80772803029327",up="rbxassetid://137756491511210",lf="rbxassetid://111204609743343",dn="rbxassetid://70710544916823",rt="rbxassetid://100462189328496"}
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
GoldenSky={Clock=13.6,Brightness=1.95,Ambient=Color3.fromRGB(138,148,168),Outdoor=Color3.fromRGB(178,188,208),Fog=Color3.fromRGB(185,222,255),Decay=Color3.fromRGB(245,215,175),Density=.12,Haze=.12,Offset=.10,Glare=.08,FogStart=1200,FogEnd=12000,Tint=Color3.fromRGB(255,250,242),Contrast=.14,Bloom=.58},
FrozenCyber={Clock=13.2,Brightness=1.90,Ambient=Color3.fromRGB(122,148,186),Outdoor=Color3.fromRGB(158,192,232),Fog=Color3.fromRGB(156,208,252),Decay=Color3.fromRGB(98,146,208),Density=.13,Haze=.14,Offset=.10,Glare=.08,FogStart=1100,FogEnd=11000,Tint=Color3.fromRGB(238,248,255),Contrast=.14,Bloom=.58},
ShadowRealm={Clock=14.6,Brightness=1.82,Ambient=Color3.fromRGB(134,98,158),Outdoor=Color3.fromRGB(172,128,198),Fog=Color3.fromRGB(156,98,176),Decay=Color3.fromRGB(96,54,116),Density=.14,Haze=.15,Offset=.10,Glare=.08,FogStart=1000,FogEnd=10500,Tint=Color3.fromRGB(250,234,255),Contrast=.15,Bloom=.60},
VerdantCrown={Clock=13.5,Brightness=1.95,Ambient=Color3.fromRGB(124,164,142),Outdoor=Color3.fromRGB(168,208,184),Fog=Color3.fromRGB(188,238,214),Decay=Color3.fromRGB(144,206,172),Density=.12,Haze=.12,Offset=.10,Glare=.08,FogStart=1200,FogEnd=12000,Tint=Color3.fromRGB(244,255,246),Contrast=.14,Bloom=.58},
EmberforgeWastes={Clock=15.0,Brightness=1.90,Ambient=Color3.fromRGB(164,124,112),Outdoor=Color3.fromRGB(208,158,142),Fog=Color3.fromRGB(228,158,132),Decay=Color3.fromRGB(168,98,74),Density=.14,Haze=.14,Offset=.10,Glare=.08,FogStart=1100,FogEnd=11000,Tint=Color3.fromRGB(255,240,228),Contrast=.15,Bloom=.60},
AbyssalTides={Clock=13.4,Brightness=1.90,Ambient=Color3.fromRGB(114,154,184),Outdoor=Color3.fromRGB(152,194,226),Fog=Color3.fromRGB(152,212,248),Decay=Color3.fromRGB(94,152,204),Density=.13,Haze=.14,Offset=.10,Glare=.08,FogStart=1100,FogEnd=11000,Tint=Color3.fromRGB(236,250,255),Contrast=.14,Bloom=.58},
ChronosBastion={Clock=14.0,Brightness=1.92,Ambient=Color3.fromRGB(146,142,174),Outdoor=Color3.fromRGB(188,182,218),Fog=Color3.fromRGB(214,208,246),Decay=Color3.fromRGB(172,158,214),Density=.12,Haze=.12,Offset=.10,Glare=.08,FogStart=1200,FogEnd=12000,Tint=Color3.fromRGB(250,246,255),Contrast=.14,Bloom=.58},
VeilsEnd={Clock=14.8,Brightness=1.84,Ambient=Color3.fromRGB(138,108,168),Outdoor=Color3.fromRGB(178,142,212),Fog=Color3.fromRGB(164,122,204),Decay=Color3.fromRGB(104,72,148),Density=.14,Haze=.15,Offset=.10,Glare=.08,FogStart=1000,FogEnd=10500,Tint=Color3.fromRGB(246,232,255),Contrast=.15,Bloom=.60},
}
function E.Apply(name)
 if name=="SkyHub" or name=="" or not name then name="GoldenSky" end
 local p=presets[name] or presets.GoldenSky local images=E.Skyboxes[name] or E.Skyboxes.GoldenSky
 local lighting=game:GetService("Lighting")
 for _,child in ipairs(lighting:GetChildren()) do
  if (child:IsA("BloomEffect") and child.Name~="SkybreakBloom") or (child:IsA("ColorCorrectionEffect") and child.Name~="SkybreakGrade" and child.Name~="SkybreakColorGrade" and child.Name~="InstinctVision") or (child:IsA("DepthOfFieldEffect") and child.Name~="SkybreakDistanceDOF") or child:IsA("ColorGradingEffect") or (child:IsA("SunRaysEffect") and child.Name~="SkybreakSunRays") then
   if child:IsA("PostEffect") then child.Enabled=false end
   child:Destroy()
  end
 end
 local sky=lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky",lighting) sky.Name="SKYBREAK_RealmSky"
 sky.SkyboxFt=images.ft sky.SkyboxBk=images.bk sky.SkyboxLf=images.lf sky.SkyboxRt=images.rt sky.SkyboxUp=images.up sky.SkyboxDn=images.dn
 sky.CelestialBodiesShown=true sky.StarCount=1200
 lighting.ClockTime=p.Clock lighting.Brightness=p.Brightness lighting.Ambient=p.Ambient lighting.OutdoorAmbient=p.Outdoor
 lighting.EnvironmentDiffuseScale=.88 lighting.EnvironmentSpecularScale=.65 lighting.ExposureCompensation=.04 lighting.ShadowSoftness=.20
 lighting.FogColor=p.Fog lighting.FogStart=p.FogStart or 1200 lighting.FogEnd=p.FogEnd or 12000
 local atmosphere=lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere",lighting)
 atmosphere.Color=p.Fog atmosphere.Decay=p.Decay atmosphere.Density=p.Density or .12 atmosphere.Offset=p.Offset or .10 atmosphere.Haze=math.min(p.Haze or .12,.16) atmosphere.Glare=math.min(p.Glare or .08,.10)
 local dof=lighting:FindFirstChild("SkybreakDistanceDOF") or Instance.new("DepthOfFieldEffect",lighting)
 dof.Name="SkybreakDistanceDOF" dof.Enabled=true dof.FarIntensity=.03 dof.FocusDistance=420 dof.InFocusRadius=580 dof.NearIntensity=0
 local grade=lighting:FindFirstChild("SkybreakGrade") or Instance.new("ColorCorrectionEffect",lighting) grade.Name="SkybreakGrade" grade.Enabled=true grade.Brightness=.03 grade.TintColor=p.Tint grade.Contrast=p.Contrast or .14 grade.Saturation=.26
 local bloom=lighting:FindFirstChild("SkybreakBloom") or Instance.new("BloomEffect",lighting) bloom.Name="SkybreakBloom" bloom.Enabled=true bloom.Intensity=p.Bloom or .58 bloom.Size=28 bloom.Threshold=.88
 local sunRays=lighting:FindFirstChild("SkybreakSunRays") or Instance.new("SunRaysEffect",lighting) sunRays.Name="SkybreakSunRays" sunRays.Enabled=true sunRays.Intensity=.08 sunRays.Spread=.65
 lighting:SetAttribute("SkybreakEnvironment",name)
 return name
end
return E
