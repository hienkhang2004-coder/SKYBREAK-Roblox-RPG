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
GoldenSky={Clock=14.2,Brightness=1.35,Ambient=Color3.fromRGB(132,142,162),Outdoor=Color3.fromRGB(166,176,196),Fog=Color3.fromRGB(215,228,245),Decay=Color3.fromRGB(225,205,175),Density=.14,Haze=.20,Offset=.12,Glare=.06,FogStart=900,FogEnd=9800,Tint=Color3.fromRGB(255,250,242),Contrast=.05,Bloom=.03},
FrozenCyber={Clock=13.5,Brightness=1.42,Ambient=Color3.fromRGB(115,138,172),Outdoor=Color3.fromRGB(148,176,212),Fog=Color3.fromRGB(162,198,238),Decay=Color3.fromRGB(98,136,188),Density=.16,Haze=.20,Offset=.12,Glare=.08,FogStart=880,FogEnd=9500,Tint=Color3.fromRGB(235,246,255),Contrast=.05,Bloom=.03},
ShadowRealm={Clock=15.0,Brightness=1.38,Ambient=Color3.fromRGB(122,92,138),Outdoor=Color3.fromRGB(156,118,172),Fog=Color3.fromRGB(148,96,152),Decay=Color3.fromRGB(88,52,98),Density=.16,Haze=.20,Offset=.12,Glare=.07,FogStart=850,FogEnd=9200,Tint=Color3.fromRGB(248,232,255),Contrast=.05,Bloom=.03},
VerdantCrown={Clock=14.0,Brightness=1.40,Ambient=Color3.fromRGB(118,152,136),Outdoor=Color3.fromRGB(158,192,174),Fog=Color3.fromRGB(198,232,214),Decay=Color3.fromRGB(150,196,170),Density=.14,Haze=.20,Offset=.12,Glare=.06,FogStart=900,FogEnd=9800,Tint=Color3.fromRGB(242,255,246),Contrast=.04,Bloom=.03},
EmberforgeWastes={Clock=15.5,Brightness=1.42,Ambient=Color3.fromRGB(152,118,108),Outdoor=Color3.fromRGB(192,148,134),Fog=Color3.fromRGB(216,154,132),Decay=Color3.fromRGB(154,94,74),Density=.16,Haze=.20,Offset=.12,Glare=.08,FogStart=880,FogEnd=9500,Tint=Color3.fromRGB(255,238,226),Contrast=.05,Bloom=.03},
AbyssalTides={Clock=13.8,Brightness=1.40,Ambient=Color3.fromRGB(108,142,168),Outdoor=Color3.fromRGB(142,178,208),Fog=Color3.fromRGB(158,202,236),Decay=Color3.fromRGB(94,142,188),Density=.16,Haze=.20,Offset=.12,Glare=.07,FogStart=860,FogEnd=9400,Tint=Color3.fromRGB(232,248,255),Contrast=.05,Bloom=.03},
ChronosBastion={Clock=14.5,Brightness=1.40,Ambient=Color3.fromRGB(138,134,162),Outdoor=Color3.fromRGB(178,172,202),Fog=Color3.fromRGB(212,206,238),Decay=Color3.fromRGB(168,154,202),Density=.14,Haze=.20,Offset=.12,Glare=.06,FogStart=920,FogEnd=10000,Tint=Color3.fromRGB(248,244,255),Contrast=.04,Bloom=.03},
VeilsEnd={Clock=15.2,Brightness=1.38,Ambient=Color3.fromRGB(128,102,152),Outdoor=Color3.fromRGB(164,132,192),Fog=Color3.fromRGB(154,118,188),Decay=Color3.fromRGB(96,68,132),Density=.16,Haze=.20,Offset=.12,Glare=.08,FogStart=850,FogEnd=9200,Tint=Color3.fromRGB(244,230,255),Contrast=.05,Bloom=.03},
}
function E.Apply(name)
 if name=="SkyHub" or name=="" or not name then name="GoldenSky" end
 local p=presets[name] or presets.GoldenSky local images=E.Skyboxes[name] or E.Skyboxes.GoldenSky
 local lighting=game:GetService("Lighting")
 for _,child in ipairs(lighting:GetChildren()) do
  if (child:IsA("BloomEffect") and child.Name~="SkybreakBloom") or (child:IsA("ColorCorrectionEffect") and child.Name~="SkybreakGrade") or (child:IsA("DepthOfFieldEffect") and child.Name~="SkybreakDistanceDOF") or child:IsA("ColorGradingEffect") or child:IsA("SunRaysEffect") then
   if child:IsA("PostEffect") then child.Enabled=false end
   child:Destroy()
  end
 end
 local sky=lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky",lighting) sky.Name="SKYBREAK_RealmSky"
 sky.SkyboxFt=images.ft sky.SkyboxBk=images.bk sky.SkyboxLf=images.lf sky.SkyboxRt=images.rt sky.SkyboxUp=images.up sky.SkyboxDn=images.dn
 sky.CelestialBodiesShown=true sky.StarCount=0
 lighting.ClockTime=p.Clock lighting.Brightness=p.Brightness lighting.Ambient=p.Ambient lighting.OutdoorAmbient=p.Outdoor
 lighting.EnvironmentDiffuseScale=.68 lighting.EnvironmentSpecularScale=.42 lighting.ExposureCompensation=-.22 lighting.ShadowSoftness=.25
 lighting.FogColor=p.Fog lighting.FogStart=p.FogStart or 900 lighting.FogEnd=p.FogEnd or 9500
 local atmosphere=lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere",lighting)
 atmosphere.Color=p.Fog atmosphere.Decay=p.Decay atmosphere.Density=p.Density or .16 atmosphere.Offset=p.Offset or .12 atmosphere.Haze=math.min(p.Haze or .20,.20) atmosphere.Glare=math.min(p.Glare or .06,.08)
 local dof=lighting:FindFirstChild("SkybreakDistanceDOF") or Instance.new("DepthOfFieldEffect",lighting)
 dof.Name="SkybreakDistanceDOF" dof.Enabled=true dof.FarIntensity=.04 dof.FocusDistance=380 dof.InFocusRadius=520 dof.NearIntensity=0
 local grade=lighting:FindFirstChild("SkybreakGrade") or Instance.new("ColorCorrectionEffect",lighting) grade.Name="SkybreakGrade" grade.Brightness=.04 grade.TintColor=p.Tint grade.Contrast=p.Contrast grade.Saturation=.12
 local bloom=lighting:FindFirstChild("SkybreakBloom") or Instance.new("BloomEffect",lighting) bloom.Name="SkybreakBloom" bloom.Intensity=p.Bloom bloom.Size=18 bloom.Threshold=2.4
 lighting:SetAttribute("SkybreakEnvironment",name)
 return name
end
return E
