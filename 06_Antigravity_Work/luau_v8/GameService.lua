local Players=game:GetService("Players")
local Debris=game:GetService("Debris")
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")
local C=require(game.ReplicatedStorage.Shared.Config)
local D=require(script.Parent.PlayerDataService)
local W=require(script.Parent.WorldService)
local Cosmetics=require(script.Parent.CosmeticService)
local G={Runtime={},Enemies={},Boss=nil,Preparing=false,ResetAt=0,Chests={},Shrines={},JumpPads={},WorldPortals={}}
local R=game.ReplicatedStorage.Remotes
if not R:FindFirstChild("CombatEvent") then
	local ce=Instance.new("RemoteEvent")
	ce.Name="CombatEvent"
	ce.Parent=R
end

local BLENDER_ENEMIES={
	TrainingDrone=true, SkyPirate=true, CorruptedGuard=true, SunshardRoyalGuard=true, LightArcher=true, GoldenKnight=true, SunshardTemplar=true,
	FrostDrone=true, FrostAutomaton=true, CyberMercenary=true, CryoGuard=true, CryoVanguard=true, CyberArcher=true, GlacialMarksman=true, GlacialSniper=true, MechaDrone=true, ArcticCorsair=true, CryonPillar=true,
	VoidPirate=true, VoidMarauder=true, VoidRaider=true, AbyssalKnight=true, AbyssalDreadknight=true, ShadowArcher=true, UmbralBowman=true, UmbralRanger=true, ShadowSpecter=true, TerrorSkyShark=true, NoxarVoidFX=true,
	CryonPrime=true, Noxar=true, AureonSentinel=true,
	PirateCaptainVance=true, OrderCyborg=true, OrderCyborgBoss=true, SoulReaperRift=true,
	SkySeaBeast=true, AbyssalLeviathan=true, AbyssalDragonHybrid=true, AbyssalSovereignDragon=true,
	SkyHubWatchCommander=true, ShrineGuardianBoss=true, AetherArchonBoss=true, SolarHighPriestBoss=true,
	CyberSyndicateBoss=true, PermafrostWardenBoss=true, VoidCastellanBoss=true, UmbralArchfiendBoss=true,
	Sylvaris=true, Ignivar=true, Nerith=true, Aion=true, Veyr=true,
}

local FALLBACK_FRUITS={
	GaleCore={Id="GaleCore", Name="Trái Cuồng Phong (Gale Core)", Rarity="Common", Type="Elemental", Element="Sky", Logia=true, Color=Color3.fromRGB(165,245,215), Moves={
		Z={Name="Wind Cutter Slash", Mult=1.9, Range=24, Cooldown=3.0},
		X={Name="Cyclone Vortex Burst", Mult=2.4, Range=26, Cooldown=4.5},
		C={Name="Tempest Tornado Pillar", Mult=3.1, Range=30, Cooldown=6.5},
		V={Name="Sky Hurricane Cataclysm", Mult=4.0, Range=34, Cooldown=9.0},
		F={Name="Zephyr Jet Flight", Mult=1.6, Range=28, Cooldown=3.5},
	}},
	SandstoneCore={Id="SandstoneCore", Name="Trái Sa Mạc Hoàng Kim (Sandstone Core)", Rarity="Uncommon", Type="Elemental", Element="Sky", Logia=true, Color=Color3.fromRGB(235,195,110), Moves={
		Z={Name="Desert Blade Spada", Mult=2.0, Range=25, Cooldown=3.2},
		X={Name="Quicksand Tomb Trap", Mult=2.6, Range=26, Cooldown=4.8},
		C={Name="Sandstorm Sables", Mult=3.3, Range=30, Cooldown=6.5},
		V={Name="Imperial Desert Burial", Mult=4.3, Range=36, Cooldown=9.5},
		F={Name="Dune Whirlwind Flight", Mult=1.6, Range=28, Cooldown=3.8},
	}},
	SolarFlameCore={Id="SolarFlameCore", Name="Trái Hỏa Dương (Solar Flame Core)", Rarity="Rare", Type="Elemental", Element="Sky", Logia=true, Color=Color3.fromRGB(255,125,45), Moves={
		Z={Name="Fire Fist Hiken", Mult=2.2, Range=28, Cooldown=3.2},
		X={Name="Solar Flame Pillar", Mult=2.9, Range=30, Cooldown=4.8},
		C={Name="Cross Fire Barrage", Mult=3.5, Range=32, Cooldown=6.5},
		V={Name="Dai Enkai: Flame Emperor", Mult=4.8, Range=40, Cooldown=9.5},
		F={Name="Rocket Flame Jet", Mult=1.7, Range=28, Cooldown=3.5},
	}},
	GlacierIceCore={Id="GlacierIceCore", Name="Trái Băng Hà Vĩnh Cửu (Glacier Ice Core)", Rarity="Rare", Type="Elemental", Element="Frost", Logia=true, Color=Color3.fromRGB(115,235,255), Moves={
		Z={Name="Ice Bird Surge", Mult=2.3, Range=28, Cooldown=3.5},
		X={Name="Glacial Surge Spears", Mult=3.0, Range=30, Cooldown=5.0},
		C={Name="Permafrost Tornado", Mult=3.7, Range=34, Cooldown=7.0},
		V={Name="Absolute Zero Epoch", Mult=4.8, Range=38, Cooldown=10.0},
		F={Name="Glacial Sky Skate", Mult=1.7, Range=28, Cooldown=4.0},
	}},
	CelestialLightCore={Id="CelestialLightCore", Name="Trái Ánh Sáng Thiên Giới (Celestial Light Core)", Rarity="Epic", Type="Elemental", Element="Sky", Logia=true, Color=Color3.fromRGB(255,242,135), Moves={
		Z={Name="Photon Spear Beam", Mult=2.4, Range=32, Cooldown=3.2},
		X={Name="Mirror Kick Barrage", Mult=3.1, Range=30, Cooldown=4.8},
		C={Name="Yasakani Sacred Jewels", Mult=3.9, Range=36, Cooldown=6.8},
		V={Name="Heavenly Judgement Ray", Mult=5.0, Range=42, Cooldown=9.5},
		F={Name="Lightspeed Starlight Flight", Mult=1.9, Range=32, Cooldown=3.2},
	}},
	StarforgedMagmaCore={Id="StarforgedMagmaCore", Name="Trái Dung Nham Tinh Cầu (Starforged Magma Core)", Rarity="Epic", Type="Elemental", Element="Sky", Logia=true, Color=Color3.fromRGB(255,82,48), Moves={
		Z={Name="Magma Clap Eruption", Mult=2.5, Range=26, Cooldown=3.5},
		X={Name="Volcanic Meigo Hound", Mult=3.2, Range=30, Cooldown=5.0},
		C={Name="Meteor Volcano Shower", Mult=4.0, Range=34, Cooldown=7.0},
		V={Name="Great Starforged Hound", Mult=5.2, Range=38, Cooldown=10.0},
		F={Name="Magma Beast Flight", Mult=1.8, Range=28, Cooldown=4.0},
	}},
	ThunderRumbleCore={Id="ThunderRumbleCore", Name="Trái Lôi Thần (Thunder Rumble Core)", Rarity="Legendary", Type="Elemental", Element="Lightning", Logia=true, Color=Color3.fromRGB(88,210,255), Moves={
		Z={Name="Thunderball Dragon", Mult=2.5, Range=30, Cooldown=3.5},
		X={Name="Sky Thunder Judgement", Mult=3.2, Range=32, Cooldown=5.0},
		C={Name="Ion Storm Barrage", Mult=3.9, Range=36, Cooldown=7.0},
		V={Name="Raigo Thundercloud Sphere", Mult=5.2, Range=42, Cooldown=10.0},
		F={Name="Lightning Flash Teleport", Mult=1.9, Range=28, Cooldown=4.0},
	}},
	AstralGravityCore={Id="AstralGravityCore", Name="Trái Trọng Lực Tinh Vân (Astral Gravity Core)", Rarity="Legendary", Type="Natural", Element="Void", Logia=false, Color=Color3.fromRGB(185,110,255), Moves={
		Z={Name="Gravitational Push", Mult=2.5, Range=28, Cooldown=3.5},
		X={Name="Singularity Crush Zone", Mult=3.3, Range=32, Cooldown=5.0},
		C={Name="Astral Meteor Summon", Mult=4.0, Range=36, Cooldown=7.0},
		V={Name="Cataclysmic Starfall", Mult=5.2, Range=42, Cooldown=10.0},
		F={Name="Boulder Gravity Surf", Mult=1.8, Range=28, Cooldown=4.0},
	}},
	DimensionalPortalCore={Id="DimensionalPortalCore", Name="Trái Không Gian (Dimensional Portal Core)", Rarity="Legendary", Type="Natural", Element="Void", Logia=false, Color=Color3.fromRGB(120,165,255), Moves={
		Z={Name="Warp Strike", Mult=2.4, Range=28, Cooldown=3.5},
		X={Name="Parallel Dimension Step", Mult=3.0, Range=30, Cooldown=5.0},
		C={Name="World Gate Teleport", Mult=3.5, Range=40, Cooldown=6.0},
		V={Name="Quantum Rift Domain", Mult=4.9, Range=38, Cooldown=10.0},
		F={Name="Rift Portal Dash", Mult=1.8, Range=28, Cooldown=4.0},
	}},
	SolarTitanCore={Id="SolarTitanCore", Name="Trái Kim Thân Thái Dương (Solar Titan Buddha)", Rarity="Mythical", Type="Beast", Element="Sky", Logia=false, Color=Color3.fromRGB(255,208,68), Moves={
		Z={Name="Solar Titan Shift", Mult=2.4, Range=28, Cooldown=3.5},
		X={Name="Heavenly Palm Impact", Mult=3.1, Range=30, Cooldown=5.0},
		C={Name="Dawn Pillar Nova", Mult=3.8, Range=34, Cooldown=7.0},
		V={Name="Twilight Retribution", Mult=5.0, Range=40, Cooldown=10.0},
		F={Name="Radiant Sky Leap", Mult=1.8, Range=28, Cooldown=4.0},
	}},
	AetherflowCore={Id="AetherflowCore", Name="Trái Linh Mạch Aether (Aetherflow Core)", Rarity="Mythical", Type="Natural", Element="Sky", Logia=false, Color=Color3.fromRGB(95,245,235), Moves={
		Z={Name="Aether Silk Barrage", Mult=2.6, Range=30, Cooldown=3.5},
		X={Name="Sovereign String Cage", Mult=3.4, Range=32, Cooldown=5.0},
		C={Name="Overheated Aether Whip", Mult=4.1, Range=36, Cooldown=7.0},
		V={Name="Sixteen Holy Aether Spears", Mult=5.4, Range=42, Cooldown=10.0},
		F={Name="Sky Cloud Thread Soar", Mult=1.9, Range=30, Cooldown=3.8},
	}},
	AbyssalSovereignCore={Id="AbyssalSovereignCore", Name="Trái Long Vương Hư Không (Abyssal Sovereign Dragon)", Rarity="Mythical", Type="Beast", Element="Void", Logia=false, Color=Color3.fromRGB(178,88,255), Moves={
		Z={Name="Void Heat Wave Beam", Mult=2.7, Range=32, Cooldown=3.5},
		X={Name="Abyssal Dragon Talons", Mult=3.4, Range=32, Cooldown=5.0},
		C={Name="Cataclysmic Meteor Shower", Mult=4.2, Range=38, Cooldown=7.0},
		V={Name="Imperial Sovereign Transformation", Mult=5.5, Range=44, Cooldown=10.0},
		F={Name="Draconic Sky Soar", Mult=2.0, Range=28, Cooldown=4.0},
	}},
	LightningTempestCore={Id="ThunderRumbleCore", Name="Trái Lôi Thần (Thunder Rumble Core)", Rarity="Legendary", Type="Elemental", Element="Lightning", Logia=true, Color=Color3.fromRGB(88,210,255)},
	GlacialPermafrostCore={Id="GlacierIceCore", Name="Trái Băng Hà Vĩnh Cửu (Glacier Ice Core)", Rarity="Rare", Type="Elemental", Element="Frost", Logia=true, Color=Color3.fromRGB(115,235,255)},
	CrimsonMagmaCore={Id="StarforgedMagmaCore", Name="Trái Dung Nham Tinh Cầu (Starforged Magma Core)", Rarity="Epic", Type="Elemental", Element="Sky", Logia=true, Color=Color3.fromRGB(255,82,48)},
	StarlightQuakeCore={Id="SolarTitanCore", Name="Trái Kim Thân Thái Dương (Solar Titan Buddha)", Rarity="Mythical", Type="Beast", Element="Sky", Logia=false, Color=Color3.fromRGB(255,208,68)},
	CyberPhoenixCore={Id="SolarFlameCore", Name="Trái Hỏa Dương (Solar Flame Core)", Rarity="Rare", Type="Elemental", Element="Sky", Logia=true, Color=Color3.fromRGB(255,125,45)},
}

local FALLBACK_STYLES={
	SkybornCombat={Id="SkybornCombat", Name="Võ Thuật Skyborn (Skyborn Combat)", Element="Sky"},
	ElectricClaw={Id="ElectricClaw", Name="Lôi Trảo Cực Tốc (Electric Claw)", Element="Lightning"},
	GlacialKarate={Id="GlacialKarate", Name="Băng Hà Quyền (Glacial Sharkman Karate)", Element="Frost"},
	DragonTalon={Id="DragonTalon", Name="Long Trảo Hỏa (Dragon Talon)", Element="Sky"},
	GodhumanSkyborn={Id="GodhumanSkyborn", Name="Thần Quyền (Godhuman Skyborn)", Element="Sky"},
	SanguineVoidArt={Id="SanguineVoidArt", Name="Huyết Hư Không Quyền (Sanguine Void Art)", Element="Void"},
}

local FALLBACK_GUNS={
	soul_guitar_void={Id="soul_guitar_void", Name="Đàn Linh Hồn Hư Không (Soul Guitar)", Element="Void"},
	kabucha_wind={Id="kabucha_wind", Name="Ná Thần Phong (Kabucha)", Element="Sky"},
	bizarre_rifle_cyber={Id="bizarre_rifle_cyber", Name="Pháo Quang Tử Băng (Cyber Rifle)", Element="Frost"},
}

local FALLBACK_FAST_TRAVEL={
	SkyHub={Id="SkyHub", Name="Sea 1 • Đảo Khởi Đầu (Sky Hub Nexus)", Realm="GoldenSky", Pos=Vector3.new(-92,42,153)},
	GoldenSky={Id="GoldenSky", Name="Sea 1 • Bầu Trời Hoàng Kim (Golden Sky Hub)", Realm="GoldenSky", Pos=Vector3.new(-92,42,153)},
	ZiolesGachaShrine={Id="ZiolesGachaShrine", Name="Sea 1 • Điện Thờ Zioles Gacha (Zioles Shrine)", Realm="GoldenSky", Pos=Vector3.new(-220,42,272)},
	AetherShrines={Id="AetherShrines", Name="Sea 1 • Đài Điện Thờ Aether (Aether Shrine)", Realm="GoldenSky", Pos=Vector3.new(60,42,276)},
	WestGarden={Id="WestGarden", Name="Sea 1 • Pháo Đài Không Tặc Vườn Tây (West Garden Bastion)", Realm="GoldenSky", Pos=Vector3.new(-520,52,78)},
	LumenPlaza={Id="LumenPlaza", Name="Sea 1 • Quảng Trường Ánh Sáng (Lumen Plaza)", Realm="GoldenSky", Pos=Vector3.new(0,44,20)},
	SunshardSanctuary={Id="SunshardSanctuary", Name="Golden Sky • Thánh Địa Thái Dương (Sunshard Sanctuary)", Realm="GoldenSky", Pos=Vector3.new(540,92,-32)},
	BossForecourt={Id="BossForecourt", Name="Sea 1 • Tháp Phán Quyết (Aureon Citadel)", Realm="GoldenSky", Pos=Vector3.new(0,45,-42)},
	FrozenCyber={Id="FrozenCyber", Name="Sea 2 • Cảng Băng Giá (Cyberport Cafe Hub)", Realm="FrozenCyber", Pos=Vector3.new(2390,46,155)},
	CyberportCafe={Id="CyberportCafe", Name="Sea 2 • Quán Cà Phê Giao Dịch (Cyberport Café)", Realm="FrozenCyber", Pos=Vector3.new(2020,50,340)},
	PermafrostGarrison={Id="PermafrostGarrison", Name="Sea 2 • Pháo Đài Tuyết (Permafrost Garrison Fortress)", Realm="FrozenCyber", Pos=Vector3.new(1940,60,-180)},
	MicrochipRaidLab={Id="MicrochipRaidLab", Name="Frozen Cyber • Phòng Thí Nghiệm Đột Kích (Raid Lab)", Realm="FrozenCyber", Pos=Vector3.new(3040,72,152)},
	GlacialWreckage={Id="GlacialWreckage", Name="Frozen Cyber • Xác Tàu Băng Cổ Đại (Glacial Wreckage)", Realm="FrozenCyber", Pos=Vector3.new(2962,48,-422)},
	CryonArena={Id="CryonArena", Name="Sea 2 • Ngai Vàng Băng Đế (Cryon Citadel)", Realm="FrozenCyber", Pos=Vector3.new(2500,55,-72)},
	ShadowRealm={Id="ShadowRealm", Name="Sea 3 • Pháo Đài Hư Không (Shadow Realm Outpost)", Realm="ShadowRealm", Pos=Vector3.new(-2570,58,125)},
	CastleOnTheVoid={Id="CastleOnTheVoid", Name="Sea 3 • Dinh Thự Hư Không (Castle on the Void Mansion)", Realm="ShadowRealm", Pos=Vector3.new(-3160,60,280)},
	UmbralSanctum={Id="UmbralSanctum", Name="Sea 3 • Rừng Tinh Thể Đen (Umbral Crystal Sanctum)", Realm="ShadowRealm", Pos=Vector3.new(-1920,64,276)},
	TempleOfTheCore={Id="TempleOfTheCore", Name="Shadow Realm • Đền Thờ Thức Tỉnh Tộc V4 (Temple of the Core)", Realm="ShadowRealm", Pos=Vector3.new(-3160,100,-288)},
	LeviathanAbyss={Id="LeviathanAbyss", Name="Sea 3 • Đảo Ảo Ảnh & Vực Thẳm Leviathan (Mirage Abyss)", Realm="ShadowRealm", Pos=Vector3.new(-2540,72,-708)},
	NoxarArena={Id="NoxarArena", Name="Sea 3 • Ngai Vàng Hư Không (Noxar Throne)", Realm="ShadowRealm", Pos=Vector3.new(-2434,69,-29)},
	VerdantCrown={Id="VerdantCrown", Name="Realm 4 • Vương Miện Cổ Thụ (The Verdant Crown)", Realm="VerdantCrown", Pos=Vector3.new(0,124,-2364)},
	EmberforgeWastes={Id="EmberforgeWastes", Name="Realm 5 • Hoang Mạc Lò Rèn Lửa (Emberforge Wastes)", Realm="EmberforgeWastes", Pos=Vector3.new(2400,124,-2362)},
	AbyssalTides={Id="AbyssalTides", Name="Realm 6 • Thủy Triều Vực Sâu (Abyssal Tides)", Realm="AbyssalTides", Pos=Vector3.new(-2400,124,-2428)},
	ChronosBastion={Id="ChronosBastion", Name="Realm 7 • Pháo Đài Thời Gian (Chronos Bastion)", Realm="ChronosBastion", Pos=Vector3.new(0,184,-4168)},
	VeilsEnd={Id="VeilsEnd", Name="Realm 8 • Tận Cùng Bức Màn (The Veil's End)", Realm="VeilsEnd", Pos=Vector3.new(0,264,-5780)},
}

local FALLBACK_ENEMIES={
	SunshardRoyalGuard={Name="Sunshard Royal Guard", VisualAsset="SunshardRoyalGuard", Element="Sky", HP=185, ATK=17, Attack=17, DEF=8, Defense=8, XP=95, Gold=55, Range=7.5, Speed=11, Aggro=34, Leash=38, Drop="SunshardCore"},
	SunshardTemplar={Name="Sunshard Templar", VisualAsset="SunshardTemplar", Element="Sky", HP=320, ATK=20, Attack=20, DEF=10, Defense=10, XP=150, Gold=85, Range=8, Speed=11, Aggro=34, Leash=42, Drop="SunshardCore"},
	FrostAutomaton={Name="Frost Automaton", VisualAsset="FrostAutomaton", Element="Frost", HP=340, ATK=26, Attack=26, DEF=10, Defense=10, Speed=14, Range=6.5, Aggro=38, Leash=55, XP=95, Gold=85, Drop="SkyIron"},
	CyberMercenary={Name="Cyber Mercenary", VisualAsset="CyberMercenary", Element="Frost", HP=390, ATK=29, Attack=29, DEF=12, Defense=12, Speed=14, Range=24, Aggro=42, Leash=58, Ranged=true, XP=115, Gold=95, Drop="SkyIron"},
	CryoVanguard={Name="Cryo Vanguard", VisualAsset="CryoVanguard", Element="Frost", HP=520, ATK=34, Attack=34, DEF=16, Defense=16, Speed=14, Range=7, Aggro=40, Leash=60, XP=135, Gold=120, Drop="SunshardCore"},
	GlacialMarksman={Name="Glacial Sniper", VisualAsset="GlacialMarksman", Element="Frost", HP=400, ATK=32, Attack=32, DEF=12, Defense=12, Speed=13, Range=28, Aggro=45, Leash=60, Ranged=true, XP=125, Gold=110, Drop="CelestialFeather"},
	GlacialSniper={Name="Glacial Sniper", VisualAsset="GlacialSniper", Element="Frost", HP=400, ATK=32, Attack=32, DEF=12, Defense=12, Speed=13, Range=28, Aggro=45, Leash=60, Ranged=true, XP=125, Gold=110, Drop="CelestialFeather"},
	MechaDrone={Name="Mecha Security Drone", VisualAsset="MechaDrone", Element="Frost", HP=460, ATK=33, Attack=33, DEF=14, Defense=14, Speed=15, Range=7.5, Aggro=42, Leash=60, XP=140, Gold=125, Drop="SkyIron"},
	ArcticCorsair={Name="Arctic Corsair", VisualAsset="ArcticCorsair", Element="Frost", HP=480, ATK=35, Attack=35, DEF=14, Defense=14, Speed=15, Range=7.5, Aggro=42, Leash=60, XP=145, Gold=130, Drop="SkyIron"},
	VoidMarauder={Name="Void Marauder", VisualAsset="VoidMarauder", Element="Void", HP=640, ATK=42, Attack=42, DEF=18, Defense=18, Speed=16, Range=7, Aggro=40, Leash=55, XP=180, Gold=160, Drop="SunshardCore"},
	VoidRaider={Name="Void Raider", VisualAsset="VoidRaider", Element="Void", HP=680, ATK=44, Attack=44, DEF=19, Defense=19, Speed=16, Range=7.5, Aggro=40, Leash=55, XP=190, Gold=170, Drop="SunshardCore"},
	AbyssalDreadknight={Name="Abyssal Dreadknight", VisualAsset="AbyssalDreadknight", Element="Void", HP=920, ATK=52, Attack=52, DEF=24, Defense=24, Speed=14, Range=8, Aggro=42, Leash=65, Elite=true, XP=260, Gold=240, Drop="CoreEssence"},
	UmbralBowman={Name="Umbral Ranger", VisualAsset="UmbralBowman", Element="Void", HP=580, ATK=46, Attack=46, DEF=15, Defense=15, Speed=14, Range=28, Aggro=45, Leash=60, Ranged=true, XP=195, Gold=175, Drop="CelestialFeather"},
	UmbralRanger={Name="Umbral Ranger", VisualAsset="UmbralRanger", Element="Void", HP=580, ATK=46, Attack=46, DEF=15, Defense=15, Speed=14, Range=28, Aggro=45, Leash=60, Ranged=true, XP=195, Gold=175, Drop="CelestialFeather"},
	ShadowSpecter={Name="Shadow Specter", VisualAsset="ShadowSpecter", Element="Void", HP=760, ATK=48, Attack=48, DEF=17, Defense=17, Speed=17, Range=8, Aggro=44, Leash=60, XP=230, Gold=210, Drop="CelestialFeather"},
	TerrorSkyShark={Name="Terror Sky-Shark", VisualAsset="TerrorSkyShark", Element="Void", HP=1250, ATK=56, Attack=56, DEF=22, Defense=22, Speed=15, Range=11, Aggro=52, Leash=75, Elite=true, XP=380, Gold=340, Drop="CoreEssence"},
	PirateCaptainVance={Name="CAPTAIN VANCE • ĐÔ ĐỐC KHÔNG TẶC", VisualAsset="PirateCaptainVance", Element="Sky", HP=1800, ATK=28, Attack=28, DEF=14, Defense=14, XP=650, Gold=550, Range=14, Speed=12, Aggro=42, Leash=50, Boss=true, Drop="SunshardCore"},
	OrderCyborg={Name="ORDER • LÕI LƯỢNG TỬ TỐI THƯỢNG", VisualAsset="OrderCyborg", Element="Frost", HP=3800, ATK=36, Attack=36, DEF=18, Defense=18, XP=1100, Gold=950, Range=18, Speed=13, Aggro=50, Leash=60, Boss=true, Drop="CoreEssence"},
	OrderCyborgBoss={Name="ORDER • LÕI LƯỢNG TỬ TỐI THƯỢNG", VisualAsset="OrderCyborgBoss", Element="Frost", HP=3800, ATK=36, Attack=36, DEF=18, Defense=18, XP=1100, Gold=950, Range=18, Speed=13, Aggro=50, Leash=60, Boss=true, Drop="CoreEssence"},
	SoulReaperRift={Name="SOUL REAPER • TỬ THẦN HƯ KHÔNG", VisualAsset="SoulReaperRift", Element="Void", HP=5800, ATK=42, Attack=42, DEF=22, Defense=22, XP=2200, Gold=1600, Range=20, Speed=13, Aggro=55, Leash=65, Boss=true, Drop="CoreEssence"},
	SkySeaBeast={Name="THỦY QUÁI BIỂN MÂY (SKY SEA BEAST)", VisualAsset="SkySeaBeast", Element="Frost", HP=5200, ATK=42, Attack=42, DEF=20, Defense=20, XP=1800, Gold=2500, Range=24, Speed=10, Aggro=65, Leash=80, Boss=true, Drop="CoreEssence"},
	AbyssalLeviathan={Name="LEVIATHAN HƯ KHÔNG (ABYSSAL LEVIATHAN)", VisualAsset="AbyssalLeviathan", Element="Void", HP=7500, ATK=50, Attack=50, DEF=25, Defense=25, XP=3200, Gold=4500, Range=28, Speed=11, Aggro=75, Leash=90, Boss=true, Drop="CoreEssence"},
	AbyssalDragonHybrid={Name="ABYSSAL DRAGON HYBRID • LONG NHÂN HƯ KHÔNG", VisualAsset="AbyssalDragonHybrid", Element="Void", HP=6800, ATK=46, Attack=46, DEF=24, Defense=24, XP=2800, Gold=3500, Range=22, Speed=12, Aggro=65, Leash=80, Boss=true, Drop="CoreEssence"},
	AbyssalSovereignDragon={Name="ABYSSAL SOVEREIGN DRAGON • THÁI CỔ LONG HOÀNG", VisualAsset="AbyssalSovereignDragon", Element="Void", HP=9200, ATK=52, Attack=52, DEF=28, Defense=28, XP=4000, Gold=6000, Range=28, Speed=10, Aggro=75, Leash=90, Boss=true, Drop="CoreEssence"},
	SkyHubWatchCommander={Name="COMMANDER VALEN • THỦ VỆ SÂN TẬP", VisualAsset="SunshardRoyalGuard", Element="Sky", HP=850, ATK=18, Attack=18, DEF=10, Defense=10, XP=320, Gold=250, Range=11, Speed=11, Aggro=36, Leash=42, Boss=true, Drop="SunshardCore"},
	ShrineGuardianBoss={Name="SHRINE WARDEN ORION • HỘ VỆ ĐIỆN THỜ", VisualAsset="SunshardTemplar", Element="Sky", HP=1100, ATK=20, Attack=20, DEF=11, Defense=11, XP=380, Gold=300, Range=11, Speed=11, Aggro=36, Leash=42, Boss=true, Drop="SunshardCore"},
	AetherArchonBoss={Name="ARCHON HELIOS • LINH VỆ AETHER", VisualAsset="GoldenKnight", Element="Sky", HP=1250, ATK=22, Attack=22, DEF=12, Defense=12, XP=420, Gold=350, Range=12, Speed=11, Aggro=36, Leash=42, Boss=true, Drop="SunshardCore"},
	SolarHighPriestBoss={Name="HIGH PRIEST SOLARIUS • ĐẠI TƯ TẾ THÁI DƯƠNG", VisualAsset="SolarTitanBuddha", Element="Sky", HP=2600, ATK=32, Attack=32, DEF=16, Defense=16, XP=950, Gold=800, Range=16, Speed=11, Aggro=45, Leash=55, Boss=true, Drop="CoreEssence"},
	CyberSyndicateBoss={Name="OVERLORD KRON • TRÙM HẮC THỊ CYBERPORT", VisualAsset="CyberMercenary", Element="Frost", HP=3200, ATK=34, Attack=34, DEF=17, Defense=17, XP=1050, Gold=880, Range=18, Speed=13, Aggro=45, Leash=55, Boss=true, Drop="CoreEssence"},
	PermafrostWardenBoss={Name="GENERAL BOREAS • THỐNG LĨNH PHÁO ĐÀI BĂNG", VisualAsset="CryoVanguard", Element="Frost", HP=3500, ATK=35, Attack=35, DEF=18, Defense=18, XP=1150, Gold=920, Range=14, Speed=12, Aggro=45, Leash=55, Boss=true, Drop="CoreEssence"},
	VoidCastellanBoss={Name="LORD MALAKOR • LÃNH CHÚA DINH THỰ HƯ KHÔNG", VisualAsset="AbyssalDreadknight", Element="Void", HP=6200, ATK=44, Attack=44, DEF=23, Defense=23, XP=2400, Gold=1800, Range=16, Speed=13, Aggro=52, Leash=65, Boss=true, Drop="CoreEssence"},
	UmbralArchfiendBoss={Name="ARCHFIEND ZERATH • KIẾM MA TINH THỂ ĐEN", VisualAsset="AbyssalDragonHybrid", Element="Void", HP=6600, ATK=46, Attack=46, DEF=24, Defense=24, XP=2600, Gold=2100, Range=18, Speed=13, Aggro=52, Leash=65, Boss=true, Drop="CoreEssence"},
	Sylvaris={Name="SYLVARIS • ĐẠI CỔ THỤ HOÀNG", VisualAsset="AbyssalDragonHybrid", Element="Sky", HP=10500, ATK=56, Attack=56, DEF=26, Defense=26, XP=4200, Gold=5500, Range=22, Speed=12, Aggro=65, Leash=80, Boss=true, Drop="CoreEssence"},
	Ignivar={Name="IGNIVAR • TITAN LÒ RÈN LỬA", VisualAsset="SolarTitanBuddha", Element="Sky", HP=12500, ATK=62, Attack=62, DEF=28, Defense=28, XP=4800, Gold=6500, Range=24, Speed=12, Aggro=65, Leash=80, Boss=true, Drop="CoreEssence"},
	Nerith={Name="NERITH • THỦY HOÀNG VỰC SÂU", VisualAsset="AbyssalLeviathan", Element="Frost", HP=14500, ATK=68, Attack=68, DEF=30, Defense=30, XP=5500, Gold=7500, Range=28, Speed=11, Aggro=75, Leash=90, Boss=true, Drop="CoreEssence"},
	Aion={Name="AION • PHÁP VƯƠNG THỜI GIAN", VisualAsset="OrderCyborgBoss", Element="Sky", HP=16800, ATK=74, Attack=74, DEF=32, Defense=32, XP=6500, Gold=9000, Range=24, Speed=13, Aggro=70, Leash=85, Boss=true, Drop="CoreEssence"},
	Veyr={Name="VEYR • ĐẤNG KIẾN TẠO ĐẦU TIÊN", VisualAsset="AbyssalSovereignDragon", Element="Void", HP=22000, ATK=85, Attack=85, DEF=36, Defense=36, XP=9000, Gold=15000, Range=30, Speed=12, Aggro=80, Leash=95, Boss=true, Drop="CoreEssence"},
}

local RACE_ORDER={"Skyborn","Mink","Leviathan","Cyborg","Ghoul","Draco"}

local function getFruitCfg(fruitId)
	local tbl=C.AetherFruits or FALLBACK_FRUITS
	return (fruitId and (tbl[fruitId] or FALLBACK_FRUITS[fruitId])) or tbl.SolarTitanCore or FALLBACK_FRUITS.SolarTitanCore
end

local function getStyleCfg(styleId)
	local tbl=C.FightingStyles or FALLBACK_STYLES
	return (styleId and (tbl[styleId] or FALLBACK_STYLES[styleId])) or tbl.SkybornCombat or FALLBACK_STYLES.SkybornCombat
end

local function getGunCfg(gunId)
	local tbl=C.Guns or FALLBACK_GUNS
	return (gunId and (tbl[gunId] or FALLBACK_GUNS[gunId])) or tbl.soul_guitar_void or FALLBACK_GUNS.soul_guitar_void
end

local function ensureProfileFields(profile)
	if not profile then return end
	profile.StatPoints=profile.StatPoints or 0
	profile.StatAlloc=type(profile.StatAlloc)=="table" and profile.StatAlloc or {Melee=1,Defense=1,Sword=1,Gun=1,Fruit=1}
	for _,k in ipairs({"Melee","Defense","Sword","Gun","Fruit"}) do
		if type(profile.StatAlloc[k])~="number" or profile.StatAlloc[k]<1 then
			profile.StatAlloc[k]=1
		end
	end
	profile.ActiveSlot=math.clamp(tonumber(profile.ActiveSlot) or 3,1,4)
	profile.FightingStyle=profile.FightingStyle or "SkybornCombat"
	profile.UnlockedStyles=type(profile.UnlockedStyles)=="table" and profile.UnlockedStyles or {
		SkybornCombat=true, SkyStep=true,
	}
	profile.EquippedFruit=profile.EquippedFruit or "GaleCore"
	profile.StoredFruits=type(profile.StoredFruits)=="table" and profile.StoredFruits or {
		GaleCore=1, SolarFlameCore=1,
	}
	profile.AwakenedFruits=type(profile.AwakenedFruits)=="table" and profile.AwakenedFruits or {}
	profile.EquippedGun=profile.EquippedGun or "aether_flintlock"
	profile.Mastery=type(profile.Mastery)=="table" and profile.Mastery or {
		SkybornCombat=1, GaleCore=1, starter_sword=1, aether_flintlock=1,
	}
	profile.Haki=type(profile.Haki)=="table" and profile.Haki or {
		Aura=false, AuraStage=1, Instinct=false, InstinctDodges=4, ConquerorUnlocked=false,
	}
	if profile.Haki.InstinctDodges==nil then profile.Haki.InstinctDodges=4 end
	profile.Race=profile.Race or "Skyborn"
	profile.RaceTier=profile.RaceTier or 1
	profile.RaceV4Active=profile.RaceV4Active==true
	profile.AwakeningMeter=profile.AwakeningMeter or 0
	profile.Faction=profile.Faction or "Pirate"
	profile.Bounty=profile.Bounty or 0
	profile.Honor=profile.Honor or 0
	profile.Title=profile.Title or "Skyborn Novice"
	profile.UnlockedWorlds=type(profile.UnlockedWorlds)=="table" and profile.UnlockedWorlds or {}
	profile.UnlockedWorlds.SkyHub=true
	profile.UnlockedWorlds.GoldenSky=true
	local lv=tonumber(profile.Level) or 1
	profile.PartySize=profile.PartySize or "Solo"
	if lv<15 then
		profile.PartySize="Solo"
	elseif lv<30 and (profile.PartySize=="Trio" or profile.PartySize=="Raid 4" or profile.PartySize=="Squad") then
		profile.PartySize="Duo"
	elseif lv<50 and profile.PartySize=="Squad" then
		profile.PartySize="Trio"
	end
end

local COMPANION_LIST={
	{Id="Kairo", Name="Kairo • Vanguard", ClassId="SkyGuardian", VisualAsset="Male_SkyGuardian", Role="TANK", UnlockLevel=15, HP=1800, MaxHP=1800, ATK=42, Offset=Vector3.new(-10,0,-5)},
	{Id="Lumen", Name="Lumen • Starweaver", ClassId="ArcaneMage", VisualAsset="ArcaneMage", Role="HEALER", UnlockLevel=30, HP=1350, MaxHP=1350, ATK=48, Offset=Vector3.new(10,0,-5)},
	{Id="Nyx", Name="Nyx • Shadowblitz", ClassId="ThunderStriker", VisualAsset="ThunderStrikerFemale", Role="ASSASSIN", UnlockLevel=50, HP=1450, MaxHP=1450, ATK=55, Offset=Vector3.new(0,0,-9)},
}
local COMPANION_SPECS={}
for _,s in ipairs(COMPANION_LIST) do COMPANION_SPECS[s.Id]=s end

local function maxPartySizeForLevel(level)
	local lv=tonumber(level) or 1
	if lv>=50 then return "Squad"
	elseif lv>=30 then return "Trio"
	elseif lv>=15 then return "Duo"
	else return "Solo" end
end

local function getCompanionIds(partySize, level)
	local lv=tonumber(level) or 1
	local raw={}
	if partySize=="Solo" then raw={}
	elseif partySize=="Duo" then raw={"Kairo"}
	elseif partySize=="Trio" or partySize=="Raid 4" then raw={"Kairo","Lumen"}
	else raw={"Kairo","Lumen","Nyx"} end
	local out={}
	for _,id in ipairs(raw) do
		local spec=COMPANION_SPECS[id]
		if spec and lv>=(spec.UnlockLevel or 1) then
			table.insert(out,id)
		end
	end
	return out
end

local function root(player)
	local ch=player.Character local h=ch and ch:FindFirstChildOfClass("Humanoid")
	local r=ch and ch:FindFirstChild("HumanoidRootPart")
	if h and r and h.Health>0 then return r,h end
end
local function distance(a,b) return (a-b).Magnitude end
local function finiteVector(v)
	return typeof(v)=="Vector3" and v.X==v.X and v.Y==v.Y and v.Z==v.Z and math.abs(v.X)<1e6 and math.abs(v.Y)<1e6 and math.abs(v.Z)<1e6
end
local function safeGroundY(pos, refFloorY)
	local gy=W.GroundY(pos, refFloorY)
	if refFloorY then
		if math.abs(gy-refFloorY)>32.0 then
			return refFloorY
		end
		return gy
	end
	if math.abs(gy-pos.Y)>36 then
		return pos.Y-2.5
	end
	return gy
end

function G.FireCombatEvent(payload)
	if R:FindFirstChild("CombatEvent") then
		R.CombatEvent:FireAllClients(payload)
	end
	if payload.Position or payload.pos then
		local fxPayload=table.clone(payload)
		fxPayload.Kind=fxPayload.Kind or "Hit"
		fxPayload.Position=fxPayload.Position or fxPayload.pos
		if not fxPayload.Text and fxPayload.amount then
			fxPayload.Text=fxPayload.crit and (tostring(fxPayload.amount).."!") or tostring(fxPayload.amount)
		end
		R.CombatFX:FireAllClients(fxPayload)
	end
end

function G.Notify(p,text) R.StateUpdate:FireClient(p,{Message=text}) end
function G.SendDialogue(p,speaker,role,text,actionLabel,actionCommand)
	R.StateUpdate:FireClient(p,{
		Message=speaker..": "..text,
		Dialogue={
			speaker=speaker,
			role=role or "SKYBORN NPC",
			text=text,
			actionLabel=actionLabel,
			actionCommand=actionCommand,
		}
	})
end
function G.ResolveWorldOrderFromPos(pos)
	if not G.WorldPortals or typeof(pos)~="Vector3" then return 1 end
	local bestOrder,bestDist=1,math.huge
	for i=1,20 do
		local gate=G.WorldPortals[string.format("WorldGate_%02d",i)]
		local prevGate=G.WorldPortals[string.format("WorldGate_%02d",i==1 and 20 or (i-1))]
		if gate and gate.Pos then
			local exitPos=gate.Pos
			local entryPos=(prevGate and prevGate.TargetPos) or exitPos
			local midPos=(exitPos+entryPos)*0.5
			local d=math.min((pos-exitPos).Magnitude,(pos-entryPos).Magnitude,(pos-midPos).Magnitude)
			if d<bestDist then
				bestDist=d
				bestOrder=i
			end
		end
	end
	return bestOrder
end
function G.Teleport(p,pos,moveCompanions)
	local r=root(p) local rt=G.Runtime[p]
	if r then
		if W.SnapToOpenGround then
			pos=select(1,W.SnapToOpenGround(pos,pos.Y-3.0,3.2))
		end
		local oldPos=r.Position
		r.CFrame=CFrame.new(pos)*r.CFrame.Rotation
		r.AssemblyLinearVelocity=Vector3.zero
		if rt then
			rt.Safe=pos
			rt.MoveAt=os.clock()
			if moveCompanions~=false and (pos-oldPos).Magnitude>28 and rt.Companions then
				for _,comp in pairs(rt.Companions) do
					if comp.Root and comp.Root.Parent then
						local cpos=pos+comp.Spec.Offset
						local fy=safeGroundY(cpos,pos.Y-2.5)
						comp.Root.CFrame=CFrame.new(cpos.X,fy+2.5,cpos.Z)
						if comp.Model then comp.Model:SetAttribute("EnemyFloorY",fy) end
					end
				end
			end
		end
		if G.UpdatePlayerPortalCompass then
			local resolvedOrder=G.ResolveWorldOrderFromPos(pos)
			local profile=D.Get(p)
			if profile then profile.CurrentWorldOrder=resolvedOrder end
			G.UpdatePlayerPortalCompass(p,resolvedOrder)
		end
	end
end
local function clearLine(a,b)
	local params=RaycastParams.new() params.FilterType=Enum.RaycastFilterType.Exclude
	local ignore={workspace.ActiveEnemies,workspace.ActiveBosses}
	if workspace:FindFirstChild("ActiveCompanions") then table.insert(ignore,workspace.ActiveCompanions) end
	if workspace:FindFirstChild("TempFX") then table.insert(ignore,workspace.TempFX) end
	if workspace:FindFirstChild("SkybreakWorldObjects") then table.insert(ignore,workspace.SkybreakWorldObjects) end
	if workspace:FindFirstChild("JumpPads") then table.insert(ignore,workspace.JumpPads) end
	if W.Hub then table.insert(ignore,W.Hub) end
	for _,p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(ignore,p.Character) end end
	params.FilterDescendantsInstances=ignore params.RespectCanCollide=true
	return workspace:Raycast(a,b-a,params)==nil
end
function G.Stats(p)
	local profile=D.Get(p) if not profile then return end
	ensureProfileFields(profile)
	local s=C.Stats(profile.Level,profile.ClassId,profile.StatAlloc)
	s.CritRate=s.CritRate or 5
	s.CritDmg=s.CritDmg or 50
	s.Break=s.Break or 100
	local eq=profile.Equipped or {}
	local enhanceMult=1+0.06*(profile.WeaponEnhance or 0)
	for _,slot in ipairs(C.EquipSlots or {"Weapon","Helmet","Chest","Gloves","Boots","Ring","Necklace","Artifact"}) do
		local itemId=eq[slot] or (slot=="Weapon" and profile.Weapon or nil)
		local item=itemId and C.Items[itemId]
		if item then
			if slot=="Weapon" then
				s.ATK+=math.floor((item.ATK or 0)*enhanceMult)
			else
				s.ATK+=(item.ATK or 0)
			end
			s.HP+=(item.HP or 0)
			s.DEF+=(item.DEF or 0)
			s.CritRate+=(item.CritRate or 0)
			s.CritDmg+=(item.CritDmg or 0)
			s.Break+=(item.Break or 0)
		end
	end
	if p.Character and p.Character:GetAttribute("HakiAura") then
		s.ATK=math.floor(s.ATK*1.20)
		s.DEF=math.floor(s.DEF*1.15)
	end
	local rv4=p.Character and p.Character:GetAttribute("RaceV4")
	if (rv4 and rv4~="") or profile.RaceV4Active then
		s.ATK=math.floor(s.ATK*1.30)
		s.HP=math.floor(s.HP*1.30)
		s.DEF=math.floor(s.DEF*1.30)
	end
	local ft=p.Character and p.Character:GetAttribute("FruitTransform")
	if ft~=nil and ft~="" then
		s.DEF=math.floor(s.DEF*1.80)
	end
	return s
end

function G.SyncCompanions(p)
	local profile=D.Get(p)
	local rt=G.Runtime[p]
	if not profile or not rt then return end
	local folder=workspace:FindFirstChild("ActiveCompanions")
	if not folder then
		folder=Instance.new("Folder")
		folder.Name="ActiveCompanions"
		folder.Parent=workspace
	end
	ensureProfileFields(profile)
	rt.Companions=rt.Companions or {}
	local wantedIds=getCompanionIds(profile.PartySize or "Solo", profile.Level)
	local wantedSet={}
	for _,id in ipairs(wantedIds) do wantedSet[id]=true end
	for id,comp in pairs(rt.Companions) do
		if not wantedSet[id] then
			if comp.Model and comp.Model.Parent then comp.Model:Destroy() end
			rt.Companions[id]=nil
		end
	end
	local pr=root(p)
	local basePos=pr and pr.Position or C.Spawn
	for _,id in ipairs(wantedIds) do
		local spec=COMPANION_SPECS[id]
		local existing=rt.Companions[id]
		if spec and (not existing or not existing.Model or not existing.Model.Parent) then
			local m=Instance.new("Model")
			m.Name=p.Name.."_"..spec.Id
			local cpos=basePos+spec.Offset
			local fy=safeGroundY(cpos)
			local rp=Instance.new("Part")
			rp.Name="Root"
			rp.Size=Vector3.new(2,4,2)
			rp.Position=Vector3.new(cpos.X,fy+2.5,cpos.Z)
			rp.Anchored=true
			rp.CanCollide=false
			rp.CanQuery=false
			rp.CanTouch=false
			rp.Transparency=1
			rp.Parent=m
			m.PrimaryPart=rp

			local body=rp:Clone()
			body.Name="Body"
			body.Anchored=false
			body.Massless=true
			body.Parent=m
			local weld=Instance.new("WeldConstraint")
			weld.Part0=rp
			weld.Part1=body
			weld.Parent=body

			local bill=Instance.new("BillboardGui")
			bill.Name="CompanionTag"
			bill.Size=UDim2.fromOffset(180,42)
			bill.StudsOffset=Vector3.new(0,3.8,0)
			bill.AlwaysOnTop=false bill.MaxDistance=65
			bill.Parent=rp
			local lbl=Instance.new("TextLabel")
			lbl.Name="Label"
			lbl.Size=UDim2.fromScale(1,1)
			lbl.BackgroundTransparency=1
			lbl.Font=Enum.Font.GothamBold
			lbl.TextSize=14
			lbl.TextStrokeTransparency=0.25
			lbl.TextColor3=id=="Kairo" and Color3.fromRGB(255,214,102) or (id=="Lumen" and Color3.fromRGB(110,225,255) or Color3.fromRGB(214,130,255))
			lbl.Text=spec.Name.." • Lv."..tostring(profile.Level or 1)
			lbl.Parent=bill

			m:SetAttribute("OwnerUserId",p.UserId)
			m:SetAttribute("CompanionId",spec.Id)
			m:SetAttribute("VisualAsset",spec.VisualAsset)
			m:SetAttribute("EnemyId",spec.VisualAsset)
			m:SetAttribute("CompanionState","Idle")
			m:SetAttribute("CompanionClip","")
			m:SetAttribute("CompanionAttackNonce",0)
			m:SetAttribute("EnemyFloorY",fy)
			m.Parent=folder
			rt.Companions[id]={
				Id=spec.Id,
				Spec=spec,
				Model=m,
				Root=rp,
				Body=body,
				Label=lbl,
				NextAttack=0,
				NextHeal=0,
				Nonce=0,
			}
		elseif existing and existing.Label then
			existing.Label.Text=spec.Name.." • Lv."..tostring(profile.Level or 1)
		end
	end
end

function G.TickCompanions(dt)
	local now=os.clock()
	for p,rt in pairs(G.Runtime) do
		local pr,ph=root(p)
		local profile=D.Get(p)
		if pr and ph and profile then
			G.SyncCompanions(p)
			local nearest,nearestDist=nil,42
			for _,e in ipairs(G.Enemies) do
				if e.Alive and e.Model and e.Model.Parent and e.Body then
					local d=distance(pr.Position,e.Body.Position)
					if d<=nearestDist then
						nearestDist=d
						nearest=e
					end
				end
			end
			for id,comp in pairs(rt.Companions or {}) do
				if comp.Model and comp.Model.Parent and comp.Root then
					local refFloorY=pr.Position.Y-2.5
					if distance(comp.Root.Position,pr.Position)>85 then
						local cpos=pr.Position+comp.Spec.Offset
						local fy=safeGroundY(cpos,refFloorY)
						comp.CachedFY=fy
						comp.LastFYPos=cpos
						comp.Root.CFrame=CFrame.new(cpos.X,fy+2.5,cpos.Z)
						comp.Model:SetAttribute("EnemyFloorY",fy)
					end
					if nearest and nearest.Alive and nearest.Body then
						local stopRange=(id=="Lumen") and 16 or 6
						local delta=Vector3.new(nearest.Body.Position.X-comp.Root.Position.X,0,nearest.Body.Position.Z-comp.Root.Position.Z)
						local dist=delta.Magnitude
						local dir=dist>0.1 and delta.Unit or pr.CFrame.LookVector
						local threshold=comp.IsMoving and (stopRange+0.35) or (stopRange+1.2)
						if dist>threshold then
							comp.IsMoving=true
							local step=dir*math.min(dist-stopRange,20*dt)
							local np=comp.Root.Position+step
							local fy=comp.CachedFY
							if not fy or not comp.LastFYPos or (Vector3.new(np.X,0,np.Z)-Vector3.new(comp.LastFYPos.X,0,comp.LastFYPos.Z)).Magnitude>0.75 then
								fy=safeGroundY(np,refFloorY)
								comp.CachedFY=fy
								comp.LastFYPos=np
							end
							comp.Root.CFrame=CFrame.lookAt(Vector3.new(np.X,fy+2.5,np.Z),Vector3.new(nearest.Body.Position.X,fy+2.5,nearest.Body.Position.Z))
							comp.Model:SetAttribute("EnemyFloorY",fy)
							if comp.LastState~="Run" then comp.LastState="Run" comp.Model:SetAttribute("CompanionState","Run") end
						else
							comp.IsMoving=false
							local fy=comp.CachedFY or safeGroundY(comp.Root.Position,refFloorY)
							comp.CachedFY=fy
							comp.Root.CFrame=CFrame.lookAt(Vector3.new(comp.Root.Position.X,fy+2.5,comp.Root.Position.Z),Vector3.new(nearest.Body.Position.X,fy+2.5,nearest.Body.Position.Z))
							comp.Model:SetAttribute("EnemyFloorY",fy)
							if comp.LastState~="Idle" then comp.LastState="Idle" comp.Model:SetAttribute("CompanionState","Idle") end
							if now>=(comp.NextAttack or 0) then
								comp.NextAttack=now+1.8
								comp.Nonce=(comp.Nonce or 0)+1
								local clip=id=="Kairo" and "SkySlash" or (id=="Lumen" and "FrostBolt" or "TS_DaggerCombo")
								comp.Model:SetAttribute("CompanionClip",clip)
								comp.Model:SetAttribute("CompanionAttackNonce",comp.Nonce)
								comp.Model:SetAttribute("EnemyAttackClip",clip=="TS_DaggerCombo" and "DaggerCombo" or clip)
								comp.Model:SetAttribute("EnemyAttackDuration",0.9)
								comp.Model:SetAttribute("EnemyAttackAt",workspace:GetServerTimeNow())
								local rawDmg=comp.Spec.ATK*(1+(profile.Level or 1)*0.04)
								local isCrit=(id=="Nyx" and math.random()<0.35) or (math.random()<0.12)
								local finalDmg=math.max(1,math.floor(rawDmg*(isCrit and 1.5 or 1)*100/(100+(nearest.Config.DEF or nearest.Config.Defense or 0))))
								if nearest.Shield then finalDmg=math.max(1,math.floor(finalDmg*0.2)) end
								local brk=(id=="Nyx") and 12 or 5
								local elem=(id=="Lumen") and "Frost" or "Sky"
								nearest.HP=math.max(0,nearest.HP-finalDmg)
								local hit=nearest.Contributors[p] or {Damage=0}
								hit.Damage+=finalDmg
								hit.Time=now
								nearest.Contributors[p]=hit
								if now>nearest.ImmuneUntil and now>nearest.StunnedUntil then
									nearest.Break+=brk
									if nearest.Break>=100 then
										nearest.Break=0
										nearest.StunnedUntil=now+3
										nearest.ImmuneUntil=now+9
									end
								end
								nearest.Model:SetAttribute("EnemyHitAt",workspace:GetServerTimeNow())
								G.FireCombatEvent({
									kind="DamageNumber",
									pos=nearest.Body.Position,
									amount=finalDmg,
									crit=isCrit,
									breakDmg=brk,
									element=elem,
								})
								if nearest.HP<=0 then
									nearest.BodyPosition=nearest.Body.Position
									G.Kill(nearest)
								end
							end
						end
					else
						local goal=pr.Position+comp.Spec.Offset
						local delta=Vector3.new(goal.X-comp.Root.Position.X,0,goal.Z-comp.Root.Position.Z)
						local dist=delta.Magnitude
						local threshold=comp.IsMoving and 0.65 or 1.75
						if dist>threshold then
							comp.IsMoving=true
							local followSpd=math.clamp(dist*6.5,7.0,20.0)
							local step=delta.Unit*math.min(dist,followSpd*dt)
							local np=comp.Root.Position+step
							local fy=comp.CachedFY
							if not fy or not comp.LastFYPos or (Vector3.new(np.X,0,np.Z)-Vector3.new(comp.LastFYPos.X,0,comp.LastFYPos.Z)).Magnitude>0.75 then
								fy=safeGroundY(np,refFloorY)
								comp.CachedFY=fy
								comp.LastFYPos=np
							end
							comp.Root.CFrame=CFrame.lookAt(Vector3.new(np.X,fy+2.5,np.Z),Vector3.new(np.X+delta.Unit.X,fy+2.5,np.Z+delta.Unit.Z))
							comp.Model:SetAttribute("EnemyFloorY",fy)
							if comp.LastState~="Run" then comp.LastState="Run" comp.Model:SetAttribute("CompanionState","Run") end
						else
							comp.IsMoving=false
							if comp.LastState~="Idle" then comp.LastState="Idle" comp.Model:SetAttribute("CompanionState","Idle") end
						end
					end
					if id=="Lumen" and now>=(comp.NextHeal or 0) and ph.Health>0 and ph.Health<ph.MaxHealth*0.85 then
						comp.NextHeal=now+9
						local healAmt=math.max(40,math.floor(ph.MaxHealth*0.20))
						ph.Health=math.min(ph.MaxHealth,ph.Health+healAmt)
						G.FireCombatEvent({
							kind="DamageNumber",
							pos=pr.Position+Vector3.new(0,2,0),
							amount=healAmt,
							crit=false,
							breakDmg=0,
							element="Heal",
							Text="+"..tostring(healAmt).." HP",
						})
					end
				end
			end
		end
	end
end

local function findActiveBossForPlayer(p)
	local r=root(p)
	if G.Boss and G.Boss.Alive and G.Boss.Model and G.Boss.Model.Parent then
		if (G.Boss.Party and G.Boss.Party[p]) or (r and distance(r.Position,G.Boss.Body.Position)<=95) then
			return G.Boss
		end
	end
	if not r then return nil end
	local best,bestDist=nil,95
	for _,e in ipairs(G.Enemies) do
		if e.Alive and e.Model and e.Model.Parent and (e.Config and e.Config.Boss or e.Id=="AureonSentinel" or e.Id=="CryonPrime" or e.Id=="Noxar" or e.Id=="PirateCaptainVance" or e.Id=="OrderCyborgBoss" or e.Id=="SoulReaperRift" or e.Id=="SkySeaBeast" or e.Id=="AbyssalLeviathan") then
			local d=distance(r.Position,e.Body.Position)
			if d<=bestDist then
				bestDist=d
				best=e
			end
		end
	end
	return best
end
function G.Sync(p)
	local profile=D.Get(p) local rt=G.Runtime[p] if not profile or not rt then return end
	ensureProfileFields(profile)
	p:SetAttribute('ClassId',profile.ClassId)
	p:SetAttribute('WeaponEquipped',profile.Weapon~=nil)
	p:SetAttribute('EquippedSword',profile.Weapon or '')
	p:SetAttribute('EquippedGun',profile.EquippedGun or '')
	local heldFruitId = profile.HeldFruit or (profile.ActiveSlot == 2 and profile.EquippedFruit or '')
	p:SetAttribute('HeldFruit', heldFruitId)
	p:SetAttribute('SkybornGender',profile.Gender or 'Male')
	p:SetAttribute('OutfitStage',profile.Level>=8 and 'SkyGuardian' or(profile.Level>=4 and 'Adventurer' or 'Novice'))
	if p.Character then
		p.Character:SetAttribute('EquippedSword',profile.Weapon or '')
		p.Character:SetAttribute('EquippedGun',profile.EquippedGun or '')
		p.Character:SetAttribute('HeldFruit', heldFruitId)
	end
	local _,h=root(p) local s=G.Stats(p) local q=C.Quests[profile.QuestIndex]
	local objectives={}
	if q then for i,o in ipairs(q.Objectives) do table.insert(objectives,{Label=o.Label,Count=profile.Progress[tostring(i)] or 0,Goal=o.Count}) end end
	local cooldowns={} for k,t in pairs(rt.Cooldowns) do cooldowns[k]=math.max(0,t-os.clock()) end
	local boss=findActiveBossForPlayer(p)
	local b=boss and boss.Alive and {
		Name=boss.Config.Name,
		Id=boss.Id,
		HP=boss.HP,
		MaxHP=boss.MaxHP,
		Break=boss.Break,
		Phase=boss.Phase,
		Shield=boss.Shield,
		Stunned=os.clock()<boss.StunnedUntil,
		Warning=boss.Id=='Noxar' and (boss.Shield and 'VOID SINGULARITY — Phá hủy Hố Đen Hư Không!' or (boss.Phase>=2 and 'VOID ANNIHILATION — Noxar đang tụ hội hư không!' or nil))
			or (boss.Id=='CryonPrime' and (boss.Shield and 'GLACIAL AEGIS — Phá hủy 3 Cột Băng Vĩnh Cửu!' or (boss.Phase>=2 and 'ABSOLUTE ZERO — Bão băng cực đại!' or nil))
			or (boss.Shield and 'SOLAR AEGIS — Phá hai trụ năng lượng trước!' or nil))
	} or nil
	local activeIds=getCompanionIds(profile.PartySize or "Solo", profile.Level)
	local activeSet={}
	for _,cid in ipairs(activeIds) do activeSet[cid]=true end
	local companionsState={}
	local curLv=tonumber(profile.Level) or 1
	for _,spec in ipairs(COMPANION_LIST) do
		table.insert(companionsState,{
			Id=spec.Id,
			Name=spec.Name,
			Role=spec.Role,
			ClassId=spec.ClassId,
			UnlockLevel=spec.UnlockLevel or 1,
			Unlocked=curLv>=(spec.UnlockLevel or 1),
			HP=spec.HP,
			MaxHP=spec.MaxHP,
			ATK=math.floor(spec.ATK*(1+curLv*0.04)),
			Active=activeSet[spec.Id]==true,
		})
	end
	R.StateUpdate:FireClient(p,{State={
		Level=profile.Level,
		ClassId=profile.ClassId,
		Gender=profile.Gender or 'Male',
		OutfitStage=p:GetAttribute('OutfitStage') or (profile.Level>=8 and 'SkyGuardian' or(profile.Level>=4 and 'Adventurer' or 'Novice')),
		XP=profile.XP,
		RequiredXP=C.RequiredXP(profile.Level),
		Gold=profile.Gold,
		CoreShards=profile.CoreShards or 0,
		SkillPoints=profile.SkillPoints or 0,
		SkillLevels=profile.SkillLevels or {},
		StatPoints=profile.StatPoints or 0,
		StatAlloc=profile.StatAlloc,
		ActiveSlot=profile.ActiveSlot or 2,
		FightingStyle=profile.FightingStyle,
		UnlockedStyles=profile.UnlockedStyles,
		EquippedFruit=profile.EquippedFruit,
		HeldFruit=profile.HeldFruit or (profile.ActiveSlot==2 and profile.EquippedFruit or ''),
		StoredFruits=profile.StoredFruits,
		AwakenedFruits=profile.AwakenedFruits,
		EquippedGun=profile.EquippedGun,
		Mastery=profile.Mastery,
		Haki=profile.Haki,
		Race=profile.Race,
		RaceTier=profile.RaceTier or 4,
		RaceV4Active=profile.RaceV4Active==true,
		AwakeningMeter=profile.AwakeningMeter or 100,
		Faction=profile.Faction or "Pirate",
		Bounty=profile.Bounty or 2500000,
		Honor=profile.Honor or 2500000,
		Title=profile.Title or "Sky Emperor",
		WeaponEnhance=profile.WeaponEnhance or 0,
		Equipped=profile.Equipped or {},
		DailyClaimed=profile.DailyClaimed or 0,
		PartySize=profile.PartySize or "Solo",
		Companions=companionsState,
		Potions=profile.Potions or 0,
		HP=h and h.Health or 0,
		MaxHP=s.HP,
		ATK=s.ATK,
		DEF=s.DEF,
		CritRate=s.CritRate,
		CritDmg=s.CritDmg,
		Break=s.Break,
		Stamina=rt.Stamina,
		Energy=rt.Energy,
		Cooldowns=cooldowns,
		Inventory=profile.Inventory,
		Weapon=profile.Weapon,
		SaveStatus=D.Sessions[p] and D.Sessions[p].SaveStatus or "Studio",
		CurrentRealm=p:GetAttribute("CurrentRealm") or "GoldenSky",
		UnlockedWorlds=profile.UnlockedWorlds,
		CompletedQuests=profile.CompletedQuests or {},
		LastCompletedQuest=profile.LastCompletedQuest,
		Quest=q and {Name=q.Name,Id=q.Id,Text=q.Text,Realm=q.Realm or "GoldenSky",XP=q.XP,Gold=q.Gold,CoreShards=q.CoreShards or 100,Accepted=profile.Accepted,Level=q.Level,Objectives=objectives} or nil,
		Complete=profile.QuestIndex>#C.Quests,
		Boss=b,
		Shield=math.max(0,rt.ShieldUntil-os.clock())
	}})
end
function G.Reward(p,xp,gold,shards)
	local profile=D.Get(p) if not profile then return end
	ensureProfileFields(profile)
	profile.XP+=xp profile.Gold+=gold
	if shards and shards>0 then profile.CoreShards=(profile.CoreShards or 0)+shards end
	local previous=profile.Level
	while profile.Level<C.MaxLevel and profile.XP>=C.RequiredXP(profile.Level) do
		profile.XP-=C.RequiredXP(profile.Level) profile.Level+=1
	end
	if profile.Level==C.MaxLevel then profile.XP=0 end
	if previous~=profile.Level then
		local gained=profile.Level-previous
		profile.SkillPoints=(profile.SkillPoints or 0)+gained
		profile.StatPoints=(profile.StatPoints or 0)+gained*3
		profile.CoreShards=(profile.CoreShards or 0)+gained*25
		profile.Potions=math.max(profile.Potions or 0,4)
		local _,h=root(p) if h then h.MaxHealth=G.Stats(p).HP h.Health=h.MaxHealth end
		local unlockMsg=""
		if previous<50 and profile.Level>=50 then
			profile.PartySize="Squad"
			unlockMsg=" • ⚡ Mở khóa Đồng Hành [Nyx • Shadowblitz] (Đội hình Squad Lv.50)!"
		elseif previous<30 and profile.Level>=30 then
			if profile.PartySize=="Solo" or profile.PartySize=="Duo" then profile.PartySize="Trio" end
			unlockMsg=" • ✨ Mở khóa Đồng Hành [Lumen • Starweaver] (Đội hình Trio Lv.30)!"
		elseif previous<15 and profile.Level>=15 then
			if profile.PartySize=="Solo" then profile.PartySize="Duo" end
			unlockMsg=" • 🛡 Mở khóa Đồng Hành [Kairo • Vanguard] (Đội hình Duo Lv.15)!"
		end
		G.SyncCompanions(p)
		G.Notify(p,"Lên cấp "..profile.Level.."! (+"..gained.." Skill Point, +"..(gained*3).." Stat Points)"..unlockMsg)
	end
end
local QUEST_TARGET_ALIASES={
	SkyPirate={SkyPirate=true,PirateCaptainVance=true},
	CorruptedGuard={CorruptedGuard=true,SunshardRoyalGuard=true,SunshardTemplar=true,SkyHubWatchCommander=true,ShrineGuardianBoss=true,AetherArchonBoss=true},
	LightArcher={LightArcher=true,SunshardRoyalGuard=true,SunshardTemplar=true},
	GoldenKnight={GoldenKnight=true,SunshardTemplar=true,SolarHighPriestBoss=true,PirateCaptainVance=true},
	FrostDrone={FrostDrone=true,FrostAutomaton=true,MechaDrone=true,CyberMercenary=true},
	CryoGuard={CryoGuard=true,CryoVanguard=true,FrostAutomaton=true,ArcticCorsair=true},
	CyberArcher={CyberArcher=true,GlacialMarksman=true,GlacialSniper=true,CyberMercenary=true},
	OrderCyborg={OrderCyborg=true,OrderCyborgBoss=true,SkySeaBeast=true,CyberSyndicateBoss=true,PermafrostWardenBoss=true},
	VoidPirate={VoidPirate=true,VoidMarauder=true,VoidRaider=true,ShadowSpecter=true},
	AbyssalKnight={AbyssalKnight=true,AbyssalDreadknight=true,VoidCastellanBoss=true,UmbralArchfiendBoss=true},
	ShadowArcher={ShadowArcher=true,UmbralBowman=true,UmbralRanger=true,ShadowSpecter=true},
	AbyssalLeviathan={AbyssalLeviathan=true,SoulReaperRift=true,TerrorSkyShark=true,AbyssalDragonHybrid=true,AbyssalSovereignDragon=true},
}
local function matchesQuestTarget(objTarget,actualTarget)
	if objTarget==actualTarget then return true end
	local aliases=QUEST_TARGET_ALIASES[objTarget]
	return aliases~=nil and aliases[actualTarget]==true
end
function G.QuestEvent(p,kind,target)
	local profile=D.Get(p) if not profile then return end
	ensureProfileFields(profile)
	if not profile.Accepted and profile.QuestIndex<=#C.Quests then profile.Accepted=true end
	local q=C.Quests[profile.QuestIndex] if not q then return end
	for i,o in ipairs(q.Objectives) do
		if o.Kind==kind and matchesQuestTarget(o.Target,target) then
			local key=tostring(i)
			profile.Progress[key]=math.min(o.Count,(profile.Progress[key] or 0)+1)
		end
	end
	for i,o in ipairs(q.Objectives) do if (profile.Progress[tostring(i)] or 0)<o.Count then return end end
	if profile.CompletedQuests[q.Id] then return end
	profile.CompletedQuests[q.Id]=true profile.Accepted=false profile.Progress={} profile.QuestIndex+=1
	profile.LastCompletedQuest=q.Id
	profile.Inventory.SkyIron=(profile.Inventory.SkyIron or 0)+4
	profile.Inventory.SunshardCore=(profile.Inventory.SunshardCore or 0)+2
	profile.Equipped=profile.Equipped or {}
	if q.Id=="Q02" then
		profile.Inventory.skyward_boots=math.max(1,profile.Inventory.skyward_boots or 0)
		if not profile.Equipped.Boots then profile.Equipped.Boots="skyward_boots" end
	elseif q.Id=="Q03" then
		profile.Inventory.upgrade_material=(profile.Inventory.upgrade_material or 0)+3
		profile.Inventory.CelestialFeather=(profile.Inventory.CelestialFeather or 0)+2
		profile.Inventory.skyward_helm=math.max(1,profile.Inventory.skyward_helm or 0)
		if not profile.Equipped.Helmet then profile.Equipped.Helmet="skyward_helm" end
	elseif q.Id=="Q04" then
		profile.Inventory.BossKey=1
		profile.Inventory.skyward_gloves=math.max(1,profile.Inventory.skyward_gloves or 0)
		if not profile.Equipped.Gloves then profile.Equipped.Gloves="skyward_gloves" end
	elseif q.Id=="Q05" then
		profile.FirstClearBosses.AureonSentinel=true
		profile.Inventory.CoreOfLight=1
		profile.Inventory.DawnbringerBlueprint=1
		profile.Inventory.saber_of_aureon=math.max(1,profile.Inventory.saber_of_aureon or 0)
		profile.Inventory.CoreEssence=(profile.Inventory.CoreEssence or 0)+2
		profile.Inventory.upgrade_material=(profile.Inventory.upgrade_material or 0)+5
		profile.UnlockedWorlds.FrozenCyber=true
	elseif q.Id=="Q06" then
		profile.Inventory.skyward_chest=math.max(1,profile.Inventory.skyward_chest or 0)
		if not profile.Equipped.Chest then profile.Equipped.Chest="skyward_chest" end
	elseif q.Id=="Q07" then
		profile.Inventory.aether_ring=math.max(1,profile.Inventory.aether_ring or 0)
		if not profile.Equipped.Ring then profile.Equipped.Ring="aether_ring" end
	elseif q.Id=="Q08" then
		profile.FirstClearBosses.CryonPrime=true
		profile.Inventory.cryon_frostblade=math.max(1,profile.Inventory.cryon_frostblade or 0)
		profile.Inventory.CoreEssence=(profile.Inventory.CoreEssence or 0)+2
		profile.UnlockedWorlds.ShadowRealm=true
	elseif q.Id=="Q09" then
		profile.Inventory.celestial_necklace=math.max(1,profile.Inventory.celestial_necklace or 0)
		if not profile.Equipped.Necklace then profile.Equipped.Necklace="celestial_necklace" end
	elseif q.Id=="Q10" then
		profile.Inventory.leviathan_shield=math.max(1,profile.Inventory.leviathan_shield or 0)
		if not profile.Equipped.Artifact then profile.Equipped.Artifact="leviathan_shield" end
	elseif q.Id=="Q11" then
		profile.FirstClearBosses.Noxar=true
		profile.Inventory.cursed_dual_skyblades=math.max(1,profile.Inventory.cursed_dual_skyblades or 0)
		profile.Inventory.CoreEssence=(profile.Inventory.CoreEssence or 0)+3
		profile.UnlockedWorlds.VerdantCrown=true
		profile.UnlockedWorlds.EmberforgeWastes=true
	elseif q.Id=="Q12" then
		profile.UnlockedWorlds.AbyssalTides=true
		profile.UnlockedWorlds.ChronosBastion=true
	elseif q.Id=="Q13" then
		profile.UnlockedWorlds.VeilsEnd=true
	elseif q.Id=="Q14" then
		profile.FirstClearBosses.Veyr=true
		profile.Inventory.noxar_abyssal_greatsword=math.max(1,profile.Inventory.noxar_abyssal_greatsword or 0)
		profile.Inventory.sovereign_cloak=math.max(1,profile.Inventory.sovereign_cloak or 0)
	end
	G.Reward(p,q.XP,q.Gold,q.CoreShards or 100)
	local nextQ=C.Quests[profile.QuestIndex]
	if nextQ then profile.Accepted=true end
	G.Notify(p,q.Id=="Q05" and "Aureon: Khi các mảnh lõi hội tụ... Chương 1 hoàn tất! Đã mở khóa Frozen Cyber & nhiệm vụ Q06!" or ("Hoàn thành "..q.Id.." ("..q.Name..")! +"..q.Gold.." Gold, +"..(q.CoreShards or 100).." Core Shards"..(nextQ and (" • Tiếp theo: "..nextQ.Id.." "..nextQ.Name) or "")))
	task.spawn(D.Save,p,false)
end
local function eligible(p)
	local profile=D.Get(p)
	if not profile then return false end
	profile.Inventory.BossKey=1
	if profile.QuestIndex==5 then profile.Accepted=true end
	return true
end
function G.Rate(p,channel,interval)
	local rt=G.Runtime[p] if not rt or not D.Get(p) then return false end
	local now=os.clock() local last=rt.Requests[channel] or 0
	if now-last<interval then return false end rt.Requests[channel]=now return true
end

function G.ActivateShrine(p,shrine)
	local r,h=root(p)
	local rt=G.Runtime[p]
	local profile=D.Get(p)
	if not r or not h or not rt or not profile then return end
	p:SetAttribute("RespawnPos",shrine.Pos)
	p:SetAttribute("RespawnRealm",shrine.Realm)
	h.Health=h.MaxHealth
	rt.Stamina=100
	rt.Energy=100
	profile.Potions=math.max(profile.Potions or 0,4)
	G.FireCombatEvent({
		kind="DamageNumber",
		pos=r.Position+Vector3.new(0,2.5,0),
		amount=math.floor(h.MaxHealth),
		crit=true,
		breakDmg=0,
		element="Heal",
		Text="⛩ 100% HP & AETHER",
	})
	G.Notify(p,"⛩ Điện Thờ Aether ("..shrine.Realm.."): Đã lưu điểm hồi sinh & hồi phục 100% HP/Stamina!")
	G.Sync(p)
end


function G.UpdatePlayerPortalCompass(p,order)
	if not p or not G.WorldPortals then return end
	local wOrder=math.clamp(tonumber(order) or 1,1,20)
	local gateKey=string.format("WorldGate_%02d",wOrder)
	local nextGate=G.WorldPortals[gateKey] or G.WorldPortals.WorldGate_01
	p:SetAttribute("CurrentWorldOrder",wOrder)
	if nextGate then
		p:SetAttribute("NextWorldGateId",nextGate.Id)
		p:SetAttribute("NextWorldGatePos",nextGate.CenterPos)
		p:SetAttribute("NextWorldGateLabel",nextGate.StageLabel.." ➡ "..nextGate.TargetTitle)
	end
end

function G.EnterWorldPortal(p,gate)
	local r,h=root(p)
	local rt=G.Runtime[p]
	local profile=D.Get(p)
	if not r or not h or not rt or not profile or not gate then return end
	local now=os.clock()
	if now<(rt.PortalTouchCooldown or 0) then return end
	rt.PortalTouchCooldown=now+3.2
	ensureProfileFields(profile)
	profile.UnlockedWorlds=profile.UnlockedWorlds or {}
	if gate.TargetRealm then profile.UnlockedWorlds[gate.TargetRealm]=true end
	if gate.TargetWorldKey then profile.UnlockedWorlds[gate.TargetWorldKey]=true end
	profile.DiscoveredPortals=type(profile.DiscoveredPortals)=="table" and profile.DiscoveredPortals or {}
	local firstTime=not profile.DiscoveredPortals[gate.Id]
	if firstTime then
		profile.DiscoveredPortals[gate.Id]=true
		profile.Gold=(profile.Gold or 0)+300
		profile.CoreShards=(profile.CoreShards or 0)+75
	end
	profile.CurrentWorldOrder=gate.NextOrder or 1
	p:SetAttribute("CurrentRealm",gate.TargetRealm or "GoldenSky")
	p:SetAttribute("RespawnPos",gate.TargetPos)
	p:SetAttribute("RespawnRealm",gate.TargetRealm or "GoldenSky")
	G.UpdatePlayerPortalCompass(p,profile.CurrentWorldOrder)
	G.FireCombatEvent({
		kind="SkillVFX",
		skillId="WorldGateTeleport",
		element=gate.Element or "Sky",
		pos=r.Position,
		look=r.CFrame.LookVector,
		userId=p.UserId,
	})
	R.CombatFX:FireAllClients({Kind="Skill",Position=r.Position,Actor=p.UserId,Action="PortalSurge"})
	G.Teleport(p,gate.TargetPos,true)
	G.FireCombatEvent({
		kind="SkillVFX",
		skillId="WorldGateTeleport",
		element=gate.Element or "Sky",
		pos=gate.TargetPos,
		look=r.CFrame.LookVector,
		userId=p.UserId,
	})
	local bonusTxt=firstTime and " (+300 Gold, +75 Core Shards mở khóa cổng mới!)" or ""
	G.Notify(p,"🌀 CỔNG KHÔNG GIAN ["..gate.StageLabel.."]: Dịch chuyển tới "..gate.TargetTitle.."!"..bonusTxt)
	G.Sync(p)
end

function G.OpenChest(p,chestId)
	local chest=G.Chests[chestId]
	local r=root(p)
	local profile=D.Get(p)
	if not chest or not r or not profile then return end
	if distance(r.Position,chest.Part.Position)>18 then return end
	local now=os.clock()
	if now<(chest.OpenedUntil or 0) then
		G.Notify(p,"Rương Báu đang tích tụ Aether ("..math.ceil(chest.OpenedUntil-now).."s)!")
		return
	end
	chest.OpenedUntil=now+60
	chest.Part:SetAttribute("ChestOpened",true)
	if chest.Lid then chest.Lid.Transparency=0.6 end
	task.delay(60,function()
		if chest.Part and chest.Part.Parent then
			chest.Part:SetAttribute("ChestOpened",false)
			if chest.Lid then chest.Lid.Transparency=0 end
		end
	end)
	profile.Gold=(profile.Gold or 0)+400
	profile.CoreShards=(profile.CoreShards or 0)+100
	profile.Inventory.SunshardCore=(profile.Inventory.SunshardCore or 0)+2
	profile.Inventory.SkyIron=(profile.Inventory.SkyIron or 0)+3
	G.FireCombatEvent({
		kind="DamageNumber",
		pos=chest.Part.Position+Vector3.new(0,2.5,0),
		amount=400,
		crit=true,
		breakDmg=0,
		element="Gold",
		Text="+400 GOLD • +100 SHARDS",
	})
	G.Notify(p,"🎁 Kho Báu Skyborn: +400 Gold, +100 Core Shards, +2 Sunshard Core, +3 Sky Iron!")
	G.Sync(p)
end

function G.LaunchPlayer(p,startPos,targetPos,arcHeight,duration)
	local r,h=root(p)
	local rt=G.Runtime[p]
	if not r or not h or not rt then return end
	duration=duration or 1.1
	arcHeight=arcHeight or 20
	rt.JumpPadUntil=os.clock()+duration+0.5
	rt.InvincibleUntil=math.max(rt.InvincibleUntil or 0,os.clock()+duration+0.4)
	local character=p.Character
	local goal=targetPos+Vector3.new(0,3,0)
	local dir=Vector3.new(goal.X-startPos.X,0,goal.Z-startPos.Z)
	local look=dir.Magnitude>0.1 and dir.Unit or r.CFrame.LookVector
	R.CombatFX:FireAllClients({Kind="Dodge",Position=startPos,Actor=p.UserId,Action="Dash"})
	task.spawn(function()
		local t0=os.clock()
		while p.Character==character and r.Parent and h.Health>0 do
			RunService.Heartbeat:Wait()
			local alpha=math.clamp((os.clock()-t0)/duration,0,1)
			local flat=startPos:Lerp(goal,alpha)
			local lift=4*arcHeight*alpha*(1-alpha)
			local pos=Vector3.new(flat.X,flat.Y+lift,flat.Z)
			r.CFrame=CFrame.lookAt(pos,pos+look)
			r.AssemblyLinearVelocity=Vector3.zero
			rt.Safe=pos
			rt.MoveAt=os.clock()
			if alpha>=1 then break end
		end
	end)
end

function G.Interact(p,id)
	if type(id)~="string" or #id>40 or not G.Rate(p,"Interact",.25) then return end
	local r=root(p) local profile=D.Get(p)
	if not r or not profile then return end
	if G.WorldPortals and G.WorldPortals[id] then
		if distance(r.Position,G.WorldPortals[id].CenterPos)<=18 then
			G.EnterWorldPortal(p,G.WorldPortals[id])
		end
		return
	end
	if G.Chests[id] then
		G.OpenChest(p,id)
		return
	elseif id=="Chest" then
		for cid,c in pairs(G.Chests) do
			if distance(r.Position,c.Part.Position)<=16 then
				G.OpenChest(p,cid)
				return
			end
		end
	end
	if G.Shrines[id] then
		if distance(r.Position,G.Shrines[id].Pos)<=16 then
			G.ActivateShrine(p,G.Shrines[id])
		end
		return
	elseif id=="AetherShrine" then
		for _,sh in pairs(G.Shrines) do
			if distance(r.Position,sh.Pos)<=16 then
				G.ActivateShrine(p,sh)
				return
			end
		end
	end
	local object=W.Interactions[id]
	if not object and id:sub(1,14)~="FruitPedestal_" and id~="Zioles" and id~="ZiolesGachaNPC" and id~="AncientMonk" and id~="AncientMonkNPC" then return end
	if object and distance(r.Position,object.Position)>22 then return end
	if id=='Lyra'or id=='Kael'then object:SetAttribute('NPCTalkAt',workspace:GetServerTimeNow())end
	if id:sub(1,14)=="FruitPedestal_" then
		local fid=id:sub(15)
		local fcfg=getFruitCfg(fid)
		local fname=fcfg and fcfg.Name or fid
		profile.StoredFruits[fid]=(profile.StoredFruits[fid] or 0)+1
		profile.EquippedFruit=fid
		profile.ActiveSlot=2
		profile.HeldFruit=fid
		if p.Character then p.Character:SetAttribute("HeldFruit",fid) end
		G.SendDialogue(p,"Bệ Đá Trái Ác Quỷ",fcfg and fcfg.Rarity or "Mythical","Bạn đã thu thập & trang bị 3D ["..fname.."]! Bấm [G] để mở bảng Trái Ác Quỷ hoặc dùng chiêu [Z][X][C][V][F]!","Mở Bảng Trái Ác Quỷ [G]","OpenScreen:Fruits")
		G.Sync(p)
		return
	elseif id=="Zioles" or id=="ZiolesGachaNPC" then
		G.Equipment(p,{action="RollFruit"})
		local eqCfg=getFruitCfg(profile.EquippedFruit)
		G.SendDialogue(p,"Zioles • Aether Core Gacha","THƯƠNG NHÂN TRÁI ÁC QUỶ","Ta nắm giữ 12 Trái Ác Quỷ Thượng Cổ đã được tách riêng thành thực thể 3D! Ngươi vừa quay Gacha thành công — hãy mở bảng FRUITS [G] để ăn trái, cầm trái 3D trên tay hoặc thức tỉnh V2!","Mở Bảng Trái Ác Quỷ [G]","OpenScreen:Fruits")
		return
	elseif id=="AncientMonk" or id=="AncientMonkNPC" then
		local styleList=C.StyleOrder or {"SkybornCombat","ElectricClaw","GlacialKarate","DragonTalon","GodhumanSkyborn","SanguineVoidArt"}
		local curIdx=1
		for i,sid in ipairs(styleList) do
			if sid==profile.FightingStyle then curIdx=i break end
		end
		local nextStyle=styleList[(curIdx%#styleList)+1]
		G.Equipment(p,{action="SwitchFightingStyle",styleId=nextStyle})
		local stCfg=getStyleCfg(profile.FightingStyle)
		G.SendDialogue(p,"Đại Sư Cổ Tự","THẦN QUYỀN SƯ TỔ","Khí huyết của ngươi rất mạnh! Ta đã truyền thụ cho ngươi bộ võ ["..(stCfg and stCfg.Name or profile.FightingStyle).."]. Hãy bấm phím [1] để thi triển võ thuật!","Xem Kỹ Năng [K]","OpenScreen:Skills")
		return
	elseif id=="Lyra" then
		local q=C.Quests[profile.QuestIndex]
		if not q then
			G.SendDialogue(p,"Lyra • Chỉ Huy Skyborn","CHỈ HUY TỐI CAO","Ngươi đã chinh phục cả 8 cõi giới Skybreak! Danh hiệu Huyền Thoại Bầu Trời thuộc về ngươi.","Mở Bản Đồ Thế Giới [M]","OpenScreen:Map")
			return
		end
		profile.Accepted=true
		G.SendDialogue(p,"Lyra • Chỉ Huy Skyborn","NHIỆM VỤ ["..q.Id.."] "..q.Name,q.Text.." (Phần thưởng: +"..tostring(q.XP).." XP, +"..tostring(q.Gold).." Gold)","Xem Nhật Ký Nhiệm Vụ [J]","OpenScreen:Quests")
	elseif id=="Kael" then
		G.SendDialogue(p,"Kael • Đại Sư Rèn Thần Khí","LÒ RÈN HUYỀN THOẠI","Hãy dùng Sunshard Core và Sky Iron để chế tác Thần Khí Dawnbringer, Cursed Dual Skyblades và cường hóa vũ khí lên +15 phát sáng rực rỡ!","Mở Lò Rèn Thần Khí [H]","OpenScreen:Forge")
	elseif id=="FrozenPortal" then
		profile.UnlockedWorlds.FrozenCyber=true
		if not workspace:FindFirstChild('FrozenCyber') then G.Notify(p,'Frozen Cyber đang được chuẩn bị.')
		else
			p:SetAttribute('CurrentRealm','FrozenCyber')
			G.Teleport(p,require(game.ReplicatedStorage.Shared.RealmConfig).FrozenCyber.Spawn)
		end
	elseif id=='FrozenReturnHub' then p:SetAttribute('CurrentRealm','GoldenSky');G.Teleport(p,C.Spawn)
	elseif id=='ShadowPortal'then
		profile.UnlockedWorlds.ShadowRealm=true
		if not workspace:FindFirstChild('ShadowRealm')then return end
		p:SetAttribute('CurrentRealm','ShadowRealm')
		G.Teleport(p,require(game.ReplicatedStorage.Shared.RealmConfig).ShadowRealm.Spawn)
	elseif id=='ShadowReturnHub'then p:SetAttribute('CurrentRealm','GoldenSky');G.Teleport(p,C.Spawn)
	elseif id=="ReturnHub" or id=="LeaveArena" then G.Teleport(p,C.Spawn)
	elseif id=="ArenaGate" then
		if not eligible(p) then G.Notify(p,"Cần nhận Q05, đạt cấp 10 và có chìa khóa tháp.") return end
		if G.Boss or os.clock()<G.ResetAt then G.Notify(p,"Đấu trường đang có trận / đang hồi. Vui lòng chờ.") return end
		G.Teleport(p,C.ArenaEntry)
		if not G.Preparing then
			G.Preparing=true
			for _,other in ipairs(Players:GetPlayers()) do G.Notify(other,"Aureon bắt đầu sau 4 giây. Hãy tiến vào đấu trường!") end
			task.delay(4,function()
				G.Preparing=false local party={}
				for _,other in ipairs(Players:GetPlayers()) do
					local rr=root(other)
					if eligible(other) and rr and distance(rr.Position,C.Arena)<55 and #party<6 then table.insert(party,other) end
				end
				if #party>0 then G.StartBoss(party) end
			end)
		end
	else G.QuestEvent(p,"Interact",id) end
	G.Sync(p)
end
local SINGLETON_BOSSES={
	Noxar=true, CryonPrime=true, AureonSentinel=true, PirateCaptainVance=true, OrderCyborgBoss=true,
	SoulReaperRift=true, SkySeaBeast=true, AbyssalLeviathan=true, AbyssalSovereignDragon=true,
	SkyHubWatchCommander=true, ShrineGuardianBoss=true, AetherArchonBoss=true, SolarHighPriestBoss=true,
	CyberSyndicateBoss=true, PermafrostWardenBoss=true, VoidCastellanBoss=true, UmbralArchfiendBoss=true,
	Sylvaris=true, Ignivar=true, Nerith=true, Aion=true, Veyr=true,
}
function G.SpawnEnemy(id,pos,boss,noRespawn)
	local cfg=C.Enemies[id] or FALLBACK_ENEMIES[id] if not cfg then return end
	if SINGLETON_BOSSES[id] then
		for _,existing in ipairs(G.Enemies) do
			if existing.Id==id and existing.Alive and existing.Model and existing.Model.Parent then
				return existing
			end
		end
	end
	local folder=boss and workspace.ActiveBosses or workspace.ActiveEnemies
	local model=Instance.new("Model")
	model.Name=id
	model:SetAttribute("EnemyId",id)
	model:SetAttribute("VisualAsset",cfg.VisualAsset or id)
	model:SetAttribute("Element",cfg.Element or "Sky")
	local isSeaBeast=(id=="SkySeaBeast" or id=="AbyssalLeviathan")
	local size=id=="AureonSentinel" and Vector3.new(7,12,5)
		or (isSeaBeast and Vector3.new(9,16,9)
		or ((id=="EnergyPylon" or id=="CryonPillar") and Vector3.new(4,9,4)
		or (id=="NoxarVoidFX" and Vector3.new(6,6,6) or Vector3.new(4,5,3))))
	local col=cfg.Element=="Frost" and Color3.fromRGB(95,215,255)
		or (cfg.Element=="Void" and Color3.fromRGB(168,85,247) or Color3.fromRGB(199,153,61))
	local mat=(id=="EnergyPylon" or id=="CryonPillar" or id=="NoxarVoidFX") and Enum.Material.Neon or Enum.Material.Metal
	local body=W.Part(model,"Body",size,pos,col,mat)
	if id=="NoxarVoidFX" then body.Shape=Enum.PartType.Ball end
	body.CanCollide=true model.PrimaryPart=body
	local eye=W.Part(model,"Core",Vector3.new(size.X*.6,1,1),pos+Vector3.new(0,1,-size.Z/2),Color3.fromRGB(112,229,255),Enum.Material.Neon) eye.CanCollide=false
	if isSeaBeast then
		local scaleCol=id=="AbyssalLeviathan" and Color3.fromRGB(38,24,68) or Color3.fromRGB(24,65,98)
		local finCol=id=="AbyssalLeviathan" and Color3.fromRGB(195,95,255) or Color3.fromRGB(85,235,255)
		body.Color=scaleCol
		body.Material=Enum.Material.Granite
		for seg=1,4 do
			local segPart=W.Part(model,"SpineSeg_"..seg,Vector3.new(8-seg*1.1,12-seg*1.6,7-seg*0.8),pos+Vector3.new(0,-seg*1.5,seg*5.5),scaleCol,Enum.Material.Granite)
			segPart.CanCollide=false
			local fin=W.Part(model,"DorsalFin_"..seg,Vector3.new(1.2,6-seg*0.8,4.5),pos+Vector3.new(0,6-seg*1.2,seg*5.2),finCol,Enum.Material.Neon)
			fin.CanCollide=false
		end
		local head=W.Part(model,"LeviathanHead",Vector3.new(8.5,6.5,9.5),pos+Vector3.new(0,8.5,-3.5),scaleCol,Enum.Material.Metal)
		head.CanCollide=false
		local jaw=W.Part(model,"LeviathanJaw",Vector3.new(7.2,2.4,8.5),pos+Vector3.new(0,5.2,-4.2),finCol,Enum.Material.Neon)
		jaw.CanCollide=false
		for _,side in ipairs({-1,1}) do
			local horn=W.Part(model,"CrownHorn_"..side,Vector3.new(1.4,7.5,2.2),pos+Vector3.new(side*4.2,12.5,-1.5),finCol,Enum.Material.Neon)
			horn.CanCollide=false
			horn.CFrame*=CFrame.Angles(-0.35,0,side*0.42)
		end
		W.Ring(model,"SeaVortexRing",pos+Vector3.new(0,-5,0),14,finCol,20)
		local pl=Instance.new("PointLight")
		pl.Color=finCol
		pl.Brightness=3.5
		pl.Range=38
		pl.Parent=head
	elseif id=="AureonSentinel" or id=="GoldenKnight" or id=="AbyssalKnight" then
		body.Color=id=="AbyssalKnight" and Color3.fromRGB(68,42,108) or Color3.fromRGB(231,224,201)
		local factor=id=="AureonSentinel" and 1 or .5
		local function armor(name,s,offset,color,neon)
			local part=W.Part(model,name,s*factor,pos+offset*factor,color,neon and Enum.Material.Neon or Enum.Material.Metal) part.CanCollide=false return part
		end
		local g=id=="AbyssalKnight" and Color3.fromRGB(175,90,255) or Color3.fromRGB(234,184,66)
		local white=id=="AbyssalKnight" and Color3.fromRGB(48,36,68) or Color3.fromRGB(226,222,207)
		armor("Helmet",Vector3.new(4,4,4),Vector3.new(0,8,0),g)
		armor("Visor",Vector3.new(.6,2.6,.3),Vector3.new(0,8,-2.1),g,true)
		for _,side in ipairs({-1,1}) do
			armor("Pauldron",Vector3.new(4,3,5),Vector3.new(side*5,4,0),g)
			armor("Arm",Vector3.new(2.6,6,2.6),Vector3.new(side*5,0,0),white)
			armor("Leg",Vector3.new(2.5,5,3),Vector3.new(side*2,-7,0),white)
			if id=="AureonSentinel" then for n=1,3 do
				local wing=armor("HaloWing",Vector3.new(8,1.5,1),Vector3.new(side*(8+n),4+n*2,3),g)
				wing.CFrame*=CFrame.Angles(0,0,side*(.3+n*.12))
			end end
		end
		armor("EnergySword",Vector3.new(1.3,13,.5),Vector3.new(5,-6,-2),g,true)
		if id=="AureonSentinel" then W.Ring(model,"CrownHalo",pos+Vector3.new(0,12,0),5,g,20) end
	end
	local visualId=cfg.VisualAsset or id
	if id=="AureonSentinel" then Cosmetics.Boss(model,body)
	else pcall(Cosmetics.Enemy,model,body,visualId) end
	local halfH = math.max(2.2, size.Y * 0.5)
	local alignedPos, homeFloorY
	if W.SnapToOpenGround and id~="EnergyPylon" and id~="CryonPillar" and id~="NoxarVoidFX" then
		alignedPos, homeFloorY = W.SnapToOpenGround(pos, pos.Y - 2.5, halfH)
	else
		homeFloorY = safeGroundY(pos, pos.Y - 2.5)
		alignedPos = Vector3.new(pos.X, homeFloorY + halfH, pos.Z)
	end
	body.Position = alignedPos
	model:SetAttribute('EnemyFloorY', homeFloorY)
	if id=="Noxar" or id=="CryonPrime" or id=="AureonSentinel" or isSeaBeast then
		model:PivotTo(CFrame.lookAt(alignedPos,alignedPos+Vector3.new(0,0,1)))
	end
	local bar=W.Label(body,cfg.Name) model.Parent=folder
	local e={
		Id=id,
		Config=cfg,
		Model=model,
		Body=body,
		Root=body,
		Label=bar,
		Home=alignedPos,
		HomeFloorY=homeFloorY,
		HP=cfg.HP,
		MaxHP=cfg.HP,
		Alive=true,
		NextAttack=0,
		SpecialTimer=0,
		Contributors={},
		State="Idle",
		Respawn=(not boss) and (not noRespawn),
		NoRespawn=noRespawn==true,
		Break=0,
		StunnedUntil=0,
		ImmuneUntil=0,
		Phase=1,
		Shield=false,
	}
	table.insert(G.Enemies,e) return e
end
function G.StartBoss(party)
	local boss=G.SpawnEnemy("AureonSentinel",C.BossSpawn,true,true)
	local extra=#party-1
	local first=party[1] and D.Get(party[1])
	if first and first.PartySize=="Duo" then extra=math.max(extra,1)
	elseif first and (first.PartySize=="Trio" or first.PartySize=="Raid 4") then extra=math.max(extra,2)
	elseif first and (first.PartySize=="Squad" or first.PartySize=="Raid 6") then extra=math.max(extra,3) end
	boss.MaxHP=math.floor(boss.MaxHP*(1+.25*extra)) boss.HP=boss.MaxHP
	boss.Party={} for _,p in ipairs(party) do boss.Party[p]=true end
	boss.EmptySince=nil boss.State="Phase1" G.Boss=boss
	return boss
end
local function participant(e,p)
	if not e.Party then return true end
	return e.Party[p]==true
end
function G.Kill(e)
	if not e.Alive then return end e.Alive=false e.State="Dead"
	if BLENDER_ENEMIES[e.Id] then
		e.Model:SetAttribute('EnemyDead',true)
		e.Label.Visible=false
		for _,o in e.Model:GetDescendants()do if o:IsA('BasePart')then o.CanQuery=false;o.CanCollide=false;o.CanTouch=false end end
		Debris:AddItem(e.Model,2)
	else e.Model:Destroy()end
	local isBossOrElite=e.Config.Boss or e.Config.Elite or e.Id=="AureonSentinel" or e.Id=="CryonPrime" or e.Id=="Noxar" or e.Id=="GoldenKnight" or e.Id=="AbyssalKnight" or e.Id=="SkySeaBeast" or e.Id=="AbyssalLeviathan"
	for p,hit in pairs(e.Contributors) do
		local r=root(p)
		local prof=D.Get(p)
		if r and prof and os.clock()-hit.Time<45 and distance(r.Position,e.BodyPosition or e.Home)<95 and participant(e,p) then
			ensureProfileFields(prof)
			local shards=(e.Id=="CryonPrime" or e.Id=="Noxar" or e.Id=="AureonSentinel" or e.Id=="SkySeaBeast" or e.Id=="AbyssalLeviathan") and 120 or 12
			if e.Config.Drop then
				prof.Inventory[e.Config.Drop]=(prof.Inventory[e.Config.Drop] or 0)+1
			end
			if e.Id=="CryonPrime" or e.Id=="Noxar" or e.Id=="AureonSentinel" or e.Id=="SkySeaBeast" or e.Id=="AbyssalLeviathan" then
				prof.Inventory.SunshardCore=(prof.Inventory.SunshardCore or 0)+2
				prof.Inventory.CoreEssence=(prof.Inventory.CoreEssence or 0)+1
				prof.Inventory.SkyIron=(prof.Inventory.SkyIron or 0)+4
			else
				prof.Inventory.SkyIron=(prof.Inventory.SkyIron or 0)+1
			end
			if isBossOrElite then
				prof.Bounty=(prof.Bounty or 2500000)+15000
				prof.Honor=(prof.Honor or 2500000)+15000
				G.Notify(p,"🏴‍☠️ Chiến công hạ gục "..e.Config.Name..": +15,000 Bounty / Honor!")
			end
			G.Reward(p,e.Config.XP or 0,e.Config.Gold or 0,shards) G.QuestEvent(p,"Kill",e.Id)
		end
	end
	if e==G.Boss then
		G.Boss=nil G.ResetAt=os.clock()+10
		for _,pylon in ipairs(G.Enemies) do if pylon.BossOwner==e and pylon.Alive then pylon.Alive=false pylon.Model:Destroy() end end
	elseif e.Respawn and not e.NoRespawn then
		task.delay(10,function() G.SpawnEnemy(e.Id,e.Home,false,false) end)
	end
end
function G.Hit(p,e,damage,breakPower,action)
	if not e.Alive or not e.Model.Parent or not participant(e,p) then return end
	if e==G.Boss or e.BossOwner then
		local pr=root(p)
		if not pr or distance(pr.Position,C.Arena)>=65 then return end
	end
	if e.BossOwner and not participant(e.BossOwner,p) then return end
	if e.Shield then
		if e==G.Boss then
			G.Notify(p,"Phá hai trụ năng lượng trước!")
			return
		else
			damage=damage*0.2
		end
	end
	local def=e.Config.DEF or e.Config.Defense or 0
	local actual=math.max(1,math.floor(damage*100/(100+def)))
	local profile=D.Get(p);local rt=G.Runtime[p]
	local stats=G.Stats(p)
	if profile and profile.ClassId=='ThunderStriker' and rt and action=='Attack' then
		rt.StrikerStacks=(rt.StrikerTarget==e and os.clock()<(rt.StrikerUntil or 0))and math.min(5,(rt.StrikerStacks or 0)+1)or 1
		rt.StrikerTarget=e;rt.StrikerUntil=os.clock()+3
	end
	local isCrit=(math.random(1,100)<=((stats and stats.CritRate) or 10))
	if isCrit then
		actual=math.floor(actual*(1+((stats and stats.CritDmg) or 50)/100))
	end
	if profile and profile.Weapon=="dawnbringer_sword" and math.random()<0.15 then
		actual=math.floor(actual*1.35)
	end
	if e==G.Boss then
		if e.Phase==1 then actual=math.min(actual,e.HP-math.floor(e.MaxHP*.65))
		elseif e.Phase==2 then actual=math.min(actual,e.HP-math.floor(e.MaxHP*.30)) end
	end
	actual=math.max(0,actual) e.HP=math.max(0,e.HP-actual)
	if rt then rt.Energy=math.min(100,rt.Energy+6) end
	local hit=e.Contributors[p] or {Damage=0} hit.Damage+=actual hit.Time=os.clock() e.Contributors[p]=hit
	if os.clock()>e.ImmuneUntil and os.clock()>e.StunnedUntil then
		e.Break+=breakPower
		if e.Break>=100 then e.Break=0 e.StunnedUntil=os.clock()+3 e.ImmuneUntil=os.clock()+9 end
	end
	e.Model:SetAttribute('EnemyHitAt',workspace:GetServerTimeNow())
	local skillCfg=action and C.Actions[action]
	local elem=(skillCfg and skillCfg.Element) or (profile and profile.ClassId=="ArcaneMage" and "Frost") or (profile and profile.ClassId=="ThunderStriker" and "Lightning") or "Sky"
	G.FireCombatEvent({
		kind="DamageNumber",
		pos=e.Body.Position,
		amount=math.floor(actual),
		crit=isCrit,
		breakDmg=breakPower,
		element=elem,
	})
	if e==G.Boss and e.Phase==1 and e.HP<=e.MaxHP*.65 then
		e.Phase=2 e.State="Phase2" e.Shield=true
		for _,x in ipairs({-24,24}) do
			local pillar=G.SpawnEnemy("EnergyPylon",C.Arena+Vector3.new(x,2,0),true,true) pillar.BossOwner=e
		end
	elseif e==G.Boss and e.Phase==2 and e.HP<=e.MaxHP*.3 and not e.Shield then e.Phase=3 e.State="Phase3" end
	if e.HP<=0 then e.BodyPosition=e.Body.Position G.Kill(e) end
end
local function inArena(p)
	local r=root(p) return r and distance(r.Position,C.Arena)<65
end
function G.PlayerDamage(p,amount,attackerEnemy)
	local r,h=root(p) local rt=G.Runtime[p] local stats=G.Stats(p)
	if not r or not h or not rt or not stats or os.clock()<rt.InvincibleUntil then return end
	local profile=D.Get(p)
	if profile then
		ensureProfileFields(profile)
		if p.Character and p.Character:GetAttribute("HakiInstinct") and profile.Haki and (profile.Haki.InstinctDodges or 0)>0 then
			profile.Haki.InstinctDodges-=1
			G.FireCombatEvent({
				kind="DamageNumber",
				pos=r.Position+Vector3.new(0,2.5,0),
				amount=0,
				crit=false,
				element="Sky",
				Text="👁 NÉ HAKI! ("..tostring(profile.Haki.InstinctDodges).."/8)",
			})
			G.Sync(p)
			return
		end
		local fruitCfg=getFruitCfg(profile.EquippedFruit)
		local isBossOrElite=attackerEnemy and (attackerEnemy==G.Boss or attackerEnemy.Config.Boss or attackerEnemy.Config.Elite)
		local enemyLv=(attackerEnemy and attackerEnemy.Config.Level) or 1
		if fruitCfg and fruitCfg.Logia and not isBossOrElite and profile.Level>=(enemyLv+5) and math.random()<0.65 then
			G.FireCombatEvent({
				kind="DamageNumber",
				pos=r.Position+Vector3.new(0,2.5,0),
				amount=0,
				crit=false,
				element=fruitCfg.Element or "Sky",
				Text="⚡ LOGIA IMMUNE!",
			})
			return
		end
	end
	if p.Character and (p.Character:GetAttribute("FruitTransform") or "")~="" then
		amount=math.floor(amount*0.42)
	end
	local multiplier=os.clock()<rt.ShieldUntil and .35 or 1
	if profile and profile.ClassId=='SkyGuardian' and profile.Level>=10 then
		for _,ally in ipairs(Players:GetPlayers()) do local ar=root(ally)
			if ally~=p and ar and distance(r.Position,ar.Position)<18 then multiplier*=.9 break end
		end
	end
	h:TakeDamage(math.max(1,math.floor(amount*100/(100+stats.DEF)*multiplier))) rt.LastHurt=os.clock()
end

function G.SpawnTelegraph(centerPos,radius,duration,label,onDetonate)
	local tempFolder=workspace:FindFirstChild("TempFX")
	if not tempFolder then
		tempFolder=Instance.new("Folder")
		tempFolder.Name="TempFX"
		tempFolder.Parent=workspace
	end
	local gy=safeGroundY(centerPos)+0.15
	local m=Instance.new("Model")
	m.Name="TelegraphZone"
	m.Parent=tempFolder

	local ring=Instance.new("Part")
	ring.Name="OuterRing"
	ring.Shape=Enum.PartType.Cylinder
	ring.Size=Vector3.new(0.25,radius*2,radius*2)
	ring.CFrame=CFrame.new(centerPos.X,gy,centerPos.Z)*CFrame.Angles(0,0,math.pi/2)
	ring.Color=Color3.fromRGB(255,64,84)
	ring.Material=Enum.Material.Neon
	ring.Transparency=0.25
	ring.Anchored=true
	ring.CanCollide=false
	ring.CanQuery=false
	ring.CanTouch=false
	ring.Parent=m

	local inner=Instance.new("Part")
	inner.Name="InnerFill"
	inner.Shape=Enum.PartType.Cylinder
	inner.Size=Vector3.new(0.3,1,1)
	inner.CFrame=ring.CFrame
	inner.Color=Color3.fromRGB(255,32,64)
	inner.Material=Enum.Material.Neon
	inner.Transparency=0.45
	inner.Anchored=true
	inner.CanCollide=false
	inner.CanQuery=false
	inner.CanTouch=false
	inner.Parent=m

	if label and label~="" then
		local bill=Instance.new("BillboardGui")
		bill.Size=UDim2.fromOffset(220,42)
		bill.StudsOffset=Vector3.new(0,3.2,0)
		bill.AlwaysOnTop=false bill.MaxDistance=65
		bill.Parent=ring
		local tl=Instance.new("TextLabel")
		tl.Size=UDim2.fromScale(1,1)
		tl.BackgroundTransparency=1
		tl.Font=Enum.Font.GothamBlack
		tl.TextSize=16
		tl.TextColor3=Color3.fromRGB(255,95,110)
		tl.TextStrokeTransparency=0.2
		tl.Text=label
		tl.Parent=bill
	end

	TweenService:Create(inner,TweenInfo.new(duration,Enum.EasingStyle.Linear),{
		Size=Vector3.new(0.3,radius*2,radius*2),
		Transparency=0.12,
	}):Play()

	Debris:AddItem(m,duration+0.35)
	task.delay(duration,function()
		if m.Parent then m:Destroy() end
		if onDetonate then pcall(onDetonate) end
	end)
end

function G.Telegraph(e,pos,radius,delayTime,damage,label)
	G.SpawnTelegraph(pos,radius,delayTime,label or "⚠ DANGER",function()
		if not e.Alive or not e.Model.Parent or os.clock()<e.StunnedUntil then return end
		for _,p in ipairs(Players:GetPlayers()) do
			local r=root(p)
			if r and participant(e,p) and distance(Vector3.new(r.Position.X,pos.Y,r.Position.Z),pos)<=radius and clearLine(e.Body.Position,r.Position) then
				G.PlayerDamage(p,damage,e)
			end
		end
	end)
end
function G.Action(p,action)
	if type(action)~="string" or not C.Actions[action] or not G.Rate(p,"Action",.08) then return end
	local r=root(p) local rt=G.Runtime[p] local profile=D.Get(p) local cfg=C.Actions[action]
	if not r or not rt or not profile or not C.Classes[profile.ClassId] or (cfg.ClassId and cfg.ClassId~=profile.ClassId) then return end
	cfg=table.clone(cfg)
	local skillLv=(profile.SkillLevels and profile.SkillLevels[action]) or 1
	local skillScale=(1+0.12*skillLv-0.12)
	if cfg.Multiplier and action~="Attack" and action~="Heavy" then
		cfg.Multiplier=cfg.Multiplier*skillScale
	end
	local mage=profile.ClassId=='ArcaneMage'
	if mage and action=='Attack'then cfg.Range=34;cfg.Cooldown=.7 end
	if mage and action=='Heavy'then cfg.Range=16 end
	local striker=profile.ClassId=='ThunderStriker'
	local speed=1
	if striker and (action=='Attack' or action=='Heavy') then
		speed=1+((os.clock()<(rt.StrikerUntil or 0))and math.min(5,rt.StrikerStacks or 0)*.04 or 0)
		cfg.Cooldown=(action=='Attack'and .3 or 1.5)/speed
	end
	local now=os.clock()
	local evade=action=="Dodge" or action=="Dash" or action=='FlashStep'
	if now<rt.ActionUntil or now<(rt.Cooldowns[action] or 0) or (evade and now<(rt.EvadeUntil or 0)) or profile.Level<(cfg.Level or 1) or rt.Stamina<(cfg.Cost or 0) then return end
	local activeFruitTransform=tostring((p.Character and p.Character:GetAttribute("FruitTransform")) or "")
	if not evade and action~="GuardianShield" and action~='ManaBarrier' and not profile.Weapon and activeFruitTransform=="" and profile.ActiveSlot~=1 and profile.ActiveSlot~=2 then G.Notify(p,"Hãy trang bị vũ khí trong túi đồ (I).") return end
	if activeFruitTransform~="" and not evade then
		cfg.Range=(cfg.Range or 12)*2.0
		cfg.Multiplier=(cfg.Multiplier or 1)*1.35
	end
	rt.Cooldowns[action]=now+cfg.Cooldown rt.Stamina-=cfg.Cost or 0
	if evade then
		local _,h=root(p)
		local duration=(action=="Dash"or action=='FlashStep') and .42 or .30
		local travel=action=='FlashStep'and 20 or(action=="Dash" and 16 or 8)
		local move=h.MoveDirection
		local direction=Vector3.new(move.X,0,move.Z)
		if action=='FlashStep' then direction=r.CFrame.LookVector end
		if direction.Magnitude<.1 then direction=r.CFrame.LookVector end
		direction=Vector3.new(direction.X,0,direction.Z).Unit
		rt.InvincibleUntil=now+.32 rt.ActionUntil=now+duration rt.EvadeUntil=now+(action=='FlashStep'and .5 or cfg.Cooldown)
		rt.JumpPadUntil=math.max(rt.JumpPadUntil or 0, now+duration+0.75)
		R.CombatFX:FireAllClients({
			Kind="Dodge",
			Position=r.Position,
			Actor=p.UserId,
			Action=action,
			Direction=direction,
			Travel=travel,
			Duration=duration,
		})
		if action=='FlashStep' then
			local character=p.Character
			task.delay(duration,function()
				if p.Character==character then
					local rr=root(p) local stats=G.Stats(p)
					if rr and stats then
						for _,e in ipairs(G.Enemies) do
							if e.Alive and e.Model.Parent and distance(rr.Position,e.Body.Position)<=12 then
								G.Hit(p,e,stats.ATK*(cfg.Multiplier or 1.4),cfg.Break or 12,action)
							end
						end
					end
				end
			end)
		end
		return
	elseif action=="GuardianShield" or action=='ManaBarrier' then
		rt.ActionUntil=now+.3
		if action=='ManaBarrier' then rt.Stamina=math.min(100,rt.Stamina+25) end
		for _,ally in ipairs(Players:GetPlayers()) do local ar=root(ally) local art=G.Runtime[ally]
			if ar and art and (action~='ManaBarrier'or ally==p)and distance(ar.Position,r.Position)<20 then
				art.ShieldUntil=now+5
				ally.Character:SetAttribute("GuardianShieldUntil",workspace:GetServerTimeNow()+5)
			end
		end
		R.CombatFX:FireAllClients({Kind="Shield",Position=r.Position,Actor=p.UserId,Action=action}) return
	end
	if action=="CelestialAegis" then
		for _,ally in ipairs(Players:GetPlayers()) do
			local ar=root(ally) local art=G.Runtime[ally]
			if ar and art and distance(ar.Position,r.Position)<24 then
				art.ShieldUntil=now+6
				ally.Character:SetAttribute("GuardianShieldUntil",workspace:GetServerTimeNow()+6)
			end
		end
		R.CombatFX:FireAllClients({Kind="Shield",Position=r.Position,Actor=p.UserId,Action=action})
	elseif action=="StormBlitz" then
		rt.StrikerStacks=5
		rt.StrikerUntil=now+6
	end
	local combo=1
	if action=="Attack" then rt.Combo=(now-rt.LastAttack<1.2) and (rt.Combo%3+1) or 1 rt.LastAttack=now combo=rt.Combo end
	local duration=action=='ArcCut'and 1.6 or(striker and .52/speed or(action=="Heavy" and (34/30) or (action=="SkySlash" and (32/30) or (({18,20,24})[combo]/30))))
	if mage then duration=action=='Heavy'and 1.3 or 1.0 end
	local windup=duration*.45
	rt.ActionUntil=now+duration*.72
	local origin=r.Position local facing=r.CFrame.LookVector
	R.CombatFX:FireAllClients({Kind="Swing",Position=origin+facing*4,Actor=p.UserId,Action=action,Combo=combo})
	local character=p.Character
	local radialAoE=(action=="CelestialAegis" or action=="StormBlitz" or action=="ThunderJudgement" or action=="AstralCataclysm" or action=="ArcaneComet" or action=="JudgmentStrike")
	local function strike()
		local rr=root(p) local stats=G.Stats(p)
		if not rr or not stats or p.Character~=character or distance(rr.Position,origin)>16 then return end
		for _,e in ipairs(G.Enemies) do
			if e.Alive and e.Model.Parent then
				local delta=e.Body.Position-rr.Position
				if delta.Magnitude<=cfg.Range and (radialAoE or (mage and action=='Heavy') or delta.Magnitude<5 or facing:Dot(delta.Unit)>-0.05) and clearLine(rr.Position,e.Body.Position) then
					G.Hit(p,e,stats.ATK*(cfg.Multiplier or 1)*(combo==3 and 1.45 or 1),(cfg.Break or 10)*(combo==3 and 1.5 or 1),action)
				end
			end
		end
	end
	if action=='ArcCut' then for _,at in {.25,.7,1.15}do task.delay(at,strike)end else task.delay(windup,strike)end
end
function G.BuildSkyShip(pOrShipId,spawnPos,customShipId)
	local isPlayer=typeof(pOrShipId)=="Instance" and pOrShipId:IsA("Player")
	local p=isPlayer and pOrShipId or nil
	local r=p and root(p) or nil
	local basePos=spawnPos or (r and (r.Position+r.CFrame.LookVector*14+Vector3.new(0,2,0)) or Vector3.new(-108,40,148))
	local shipId=customShipId or (not isPlayer and tostring(pOrShipId or "CelestialBrigantine")) or nil
	if not shipId and p then
		local realm=p:GetAttribute("CurrentRealm") or "GoldenSky"
		if realm=="FrozenCyber" then
			shipId="CyberEnforcer"
		elseif realm=="ShadowRealm" then
			shipId="LeviathanHunterShip"
		else
			shipId="CelestialBrigantine"
		end
	end
	shipId=shipId or "CelestialBrigantine"

	local worldObjects=workspace:FindFirstChild("SkybreakWorldObjects") or workspace
	local modelName=p and ("SkyShip_"..p.Name) or ("SkyShip_"..shipId)
	local existing=worldObjects:FindFirstChild(modelName)
	if existing then existing:Destroy() end

	local ship=Instance.new("Model")
	ship.Name=modelName
	ship:SetAttribute("ShipId",shipId)
	ship.Parent=worldObjects

	local helm=nil
	local bannerTarget=nil
	local shipTitle="⛵ CELESTIAL AETHER GALLEON"
	local shipTitleColor=Color3.fromRGB(255,222,105)
	local shipVisualAsset="CelestialAetherGalleon"

	if shipId=="CyberEnforcer" then
		shipTitle="🚀 CYBER ENFORCER • VTOL CRYO GUNSHIP"
		shipTitleColor=Color3.fromRGB(92,240,255)
		shipVisualAsset="CyberEnforcerShip"
	elseif shipId=="LeviathanHunterShip" then
		shipTitle="🐉 LEVIATHAN HUNTER • VOID DREADNOUGHT"
		shipTitleColor=Color3.fromRGB(215,112,255)
		shipVisualAsset="LeviathanHunterShip"
	end

	-- Walkable invisible collision deck + helm anchor; 3D rigged ship is built by BlenderEnemies.client.lua via DelegatedV5Renderer!
	local hull=W.Part(ship,"Body",Vector3.new(14,2.2,32),basePos,shipTitleColor,Enum.Material.Metal)
	hull.Transparency=1
	ship.PrimaryPart=hull
	helm=W.Part(ship,"CaptainHelm",Vector3.new(2.2,3.4,2.2),basePos+Vector3.new(0,2.5,4.0),shipTitleColor,Enum.Material.Neon)
	helm.Transparency=0.85
	helm.CanCollide=true
	bannerTarget=helm
	ship:SetAttribute("NPCId",shipVisualAsset)
	ship:SetAttribute("VisualAsset",shipVisualAsset)
	ship:SetAttribute("ShowcaseScale",4.2)
	ship:SetAttribute("NPCFloorY",basePos.Y-1.2)

	bannerTarget=bannerTarget or ship.PrimaryPart
	local light=Instance.new("PointLight")
	light.Color=shipTitleColor
	light.Brightness=3.2
	light.Range=40
	light.Parent=bannerTarget

	local seat=Instance.new("Seat")
	seat.Name="PilotSeat"
	seat.Size=Vector3.new(2.4,1.2,2.4)
	seat.CFrame=CFrame.new(helm.Position+Vector3.new(0,-0.8,1.8))
	seat.Anchored=true
	seat.Transparency=1
	seat.Color=Color3.fromRGB(36,42,58)
	seat.Material=Enum.Material.SmoothPlastic
	seat.Parent=ship

	local bill=Instance.new("BillboardGui")
	bill.Size=UDim2.fromOffset(250,44)
	bill.StudsOffset=Vector3.new(0,11.5,0)
	bill.AlwaysOnTop=false bill.MaxDistance=65
	bill.Parent=bannerTarget
	local tl=Instance.new("TextLabel")
	tl.Size=UDim2.fromScale(1,1)
	tl.BackgroundTransparency=1
	tl.Font=Enum.Font.GothamBlack
	tl.TextSize=14
	tl.TextColor3=shipTitleColor
	tl.TextStrokeTransparency=0.2
	tl.Text=shipTitle..(p and (" • "..p.Name) or "")
	tl.Parent=bill

	local islandTargets={
		{Name="Sunshard Sanctuary", Realm="GoldenSky", Pos=Vector3.new(540,92,-32)},
		{Name="West Garden Bastion", Realm="GoldenSky", Pos=Vector3.new(-520,52,78)},
		{Name="Zioles Gacha Shrine", Realm="GoldenSky", Pos=Vector3.new(-220,42,272)},
		{Name="Cyberport Cafe", Realm="FrozenCyber", Pos=Vector3.new(2020,50,340)},
		{Name="Permafrost Garrison", Realm="FrozenCyber", Pos=Vector3.new(1940,60,-180)},
		{Name="Microchip Raid Lab", Realm="FrozenCyber", Pos=Vector3.new(3040,72,152)},
		{Name="Glacial Wreckage", Realm="FrozenCyber", Pos=Vector3.new(2962,48,-422)},
		{Name="Castle on the Void", Realm="ShadowRealm", Pos=Vector3.new(-3160,60,280)},
		{Name="Umbral Crystal Sanctum", Realm="ShadowRealm", Pos=Vector3.new(-1920,64,276)},
		{Name="Temple of the Core", Realm="ShadowRealm", Pos=Vector3.new(-3160,100,-288)},
		{Name="Leviathan Abyss (Mirage Island)", Realm="ShadowRealm", Pos=Vector3.new(-2540,72,-708)},
		{Name="Sky Hub", Realm="GoldenSky", Pos=C.Spawn},
	}
	local routeIdx=1
	local prompt=Instance.new("ProximityPrompt")
	prompt.ActionText="Lái Tàu Bay / Bay Tới Đảo Tiếp Theo"
	prompt.ObjectText=shipTitle
	prompt.MaxActivationDistance=16
	prompt.HoldDuration=0
	prompt.Parent=helm
	prompt.Triggered:Connect(function(plr)
		local pr=root(plr)
		if not pr then return end
		local dest=islandTargets[routeIdx]
		routeIdx=(routeIdx%#islandTargets)+1
		plr:SetAttribute("CurrentRealm",dest.Realm)
		local newBase=dest.Pos+Vector3.new(0,2,26)
		ship:SetAttribute("NPCFloorY",newBase.Y-1.2)
		ship:PivotTo(CFrame.new(newBase))
		G.Teleport(plr,dest.Pos)
		G.Notify(plr,"⛵ "..shipTitle.." đã đưa bạn vượt biển mây tới: "..dest.Name.."!")
		G.Sync(plr)
	end)

	return ship
end

function G.UseSlotMove(p,key)
	if not G.Rate(p,"SlotMove",.12) then return end
	local r,h=root(p) local rt=G.Runtime[p] local profile=D.Get(p)
	if not r or not h or not rt or not profile then return end
	ensureProfileFields(profile)
	key=string.upper(tostring(key or "Z"))
	if key~="Z" and key~="X" and key~="C" and key~="V" and key~="F" then key="Z" end

	local slot=math.clamp(tonumber(profile.ActiveSlot) or 2,1,4)
	local activeId="SolarTitanCore"
	local activeCfg=nil
	local element="Sky"
	if slot==1 then
		activeId=profile.FightingStyle or "SkybornCombat"
		activeCfg=getStyleCfg(activeId)
		element=(activeCfg and activeCfg.Element) or "Sky"
	elseif slot==2 then
		activeId=profile.EquippedFruit or "SolarTitanCore"
		activeCfg=getFruitCfg(activeId)
		element=(activeCfg and activeCfg.Element) or "Sky"
	elseif slot==3 then
		activeId=profile.Weapon or "dawnbringer_sword"
		activeCfg=(C.Swords and C.Swords[activeId]) or (C.Items and C.Items[activeId]) or {Name="Thần Kiếm Skyborn", Element="Sky"}
		element=activeCfg.Element or "Sky"
	else
		activeId=profile.EquippedGun or "soul_guitar_void"
		activeCfg=getGunCfg(activeId)
		element=(activeCfg and activeCfg.Element) or "Void"
	end

	local defaultByKey={
		Z={Name=activeId.."_Z", Mult=2.3, Range=24, Cooldown=3.2},
		X={Name=activeId.."_X", Mult=2.9, Range=28, Cooldown=4.8},
		C={Name=activeId.."_C", Mult=3.6, Range=32, Cooldown=6.5},
		V={Name=activeId.."_V", Mult=4.8, Range=38, Cooldown=9.5},
		F={Name=activeId.."_F", Mult=1.8, Range=28, Cooldown=4.0},
	}
	local moveSpec=defaultByKey[key]
	if activeCfg and type(activeCfg.Moves)=="table" then
		if activeCfg.Moves[key] then
			moveSpec=activeCfg.Moves[key]
		else
			for _,m in pairs(activeCfg.Moves) do
				if type(m)=="table" and string.upper(tostring(m.Key or ""))==key then
					moveSpec=m
					break
				end
			end
		end
	end

	local now=os.clock()
	local cdKey="Slot_"..key
	if now<(rt.Cooldowns[cdKey] or 0) then return end
	local cd=tonumber(moveSpec and moveSpec.Cooldown) or defaultByKey[key].Cooldown
	rt.Cooldowns[cdKey]=now+cd
	rt.Cooldowns[key]=now+cd

	local moveName=(moveSpec and (moveSpec.Name or moveSpec.Id)) or (activeId.."_"..key)
	local mult=tonumber(moveSpec and (moveSpec.Mult or moveSpec.Multiplier)) or defaultByKey[key].Mult
	local range=tonumber(moveSpec and moveSpec.Range) or defaultByKey[key].Range

	if slot==2 and profile.AwakenedFruits and profile.AwakenedFruits[activeId] then
		mult*=1.25
		range*=1.20
	end

	-- Special Transformation & Teleport Moves
	if slot==2 and activeId=="SolarTitanCore" and key=="Z" then
		local cur=(p.Character and p.Character:GetAttribute("FruitTransform")) or ""
		local nextState=(cur=="SolarTitan") and "" or "SolarTitan"
		if p.Character then p.Character:SetAttribute("FruitTransform",nextState) end
		G.Notify(p,"☀ SOLAR TITAN SHIFT: Hóa Kim Thân Khổng Lồ 3D (+58% Giáp, x2.5 Tầm Đánh)!")
	elseif slot==2 and activeId=="AbyssalSovereignCore" and key=="V" then
		local cur=(p.Character and p.Character:GetAttribute("FruitTransform")) or ""
		local nextState=(cur=="AbyssalSovereign") and "" or "AbyssalSovereign"
		if p.Character then p.Character:SetAttribute("FruitTransform",nextState) end
		G.Notify(p,"🐉 ABYSSAL SOVEREIGN: Hóa Long Vương Hư Không 3D!")
	elseif slot==2 and activeId=="DimensionalPortalCore" and key=="C" then
		local dir=r.CFrame.LookVector*40
		local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances={p.Character,workspace.ActiveEnemies,workspace.ActiveBosses} rp.RespectCanCollide=true
		local hit=workspace:Raycast(r.Position,dir,rp)
		local targetPos=hit and (hit.Position-r.CFrame.LookVector*3.5) or (r.Position+dir)
		targetPos=Vector3.new(targetPos.X,math.max(targetPos.Y,safeGroundY(targetPos)+3.2),targetPos.Z)
		G.Teleport(p,targetPos)
		G.Notify(p,"🌀 WORLD GATE RIFT: Dịch chuyển xuyên không gian 40m!")
	elseif key=="F" then
		rt.InvincibleUntil=math.max(rt.InvincibleUntil or 0,now+1.5)
		local dir=r.CFrame.LookVector*28
		local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances={p.Character,workspace.ActiveEnemies,workspace.ActiveBosses} rp.RespectCanCollide=true
		local hit=workspace:Raycast(r.Position,dir,rp)
		local dashTarget=hit and (hit.Position-r.CFrame.LookVector*3.2) or (r.Position+dir)
		local gy=safeGroundY(dashTarget)
		dashTarget=Vector3.new(dashTarget.X,math.clamp(gy+3.0,r.Position.Y-14,r.Position.Y+18),dashTarget.Z)
		G.Teleport(p,dashTarget)
	end

	local ft=p.Character and p.Character:GetAttribute("FruitTransform")
	if ft=="SolarTitan" or ft=="AbyssalSovereign" then
		range*=2.2
	end

	local stats=G.Stats(p)
	if stats then
		for _,e in ipairs(G.Enemies) do
			if e.Alive and e.Model and e.Model.Parent and e.Body then
				if distance(r.Position,e.Body.Position)<=range then
					G.Hit(p,e,stats.ATK*mult,24,moveName)
				end
			end
		end
	end

	profile.Mastery[activeId]=math.min(600,(profile.Mastery[activeId] or 1)+12)
	profile.AwakeningMeter=math.min(100,(profile.AwakeningMeter or 0)+10)

	local clipAct=(key=="V" and "UltimateAwakening") or ((key=="X" or key=="C") and "HeroicKata") or (key=="F" and "Dash") or "ElementalSurge"
	R.CombatFX:FireAllClients({Kind="Skill",Position=r.Position,Actor=p.UserId,Action=clipAct,key=key})

	G.FireCombatEvent({
		kind="SkillVFX",
		skillId=moveName,
		moveKey=key,
		slot=slot,
		element=element,
		pos=r.Position,
		look=r.CFrame.LookVector,
		userId=p.UserId,
	})
	G.Sync(p)
end

function G.Equipment(p,payload)
	if not G.Rate(p,"Equipment",.08) or type(payload)~="table" then return end
	local profile=D.Get(p) local rt=G.Runtime[p] local r,h=root(p)
	if not profile or not rt then return end
	ensureProfileFields(profile)
	profile.Equipped=profile.Equipped or {}
	profile.SkillLevels=profile.SkillLevels or {}
	local act=payload.action
	if act=="Unequip" then
		local slot=payload.slot or (payload.itemId and C.Items[payload.itemId] and C.Items[payload.itemId].Slot) or "Weapon"
		if slot=="Weapon" then
			profile.Weapon=nil
			profile.Equipped.Weapon=nil
		else
			profile.Equipped[slot]=nil
		end
		G.Notify(p,"Đã tháo trang bị ("..slot..").")
	elseif act=="Equip" then
		local itemId=payload.itemId
		local item=itemId and C.Items[itemId]
		if item and (profile.Inventory[itemId] or 0)>0 then
			local slot=payload.slot or item.Slot or "Weapon"
			if slot=="Weapon" then
				if item.ClassId and item.ClassId~=profile.ClassId then
					G.Notify(p,"Vũ khí này dành cho "..(C.Classes[item.ClassId] and C.Classes[item.ClassId].Name or item.ClassId).."!")
					return
				end
				profile.Weapon=itemId
				profile.Equipped.Weapon=itemId
				profile.Loadouts=profile.Loadouts or {}
				profile.Loadouts[profile.ClassId]=itemId
			else
				profile.Equipped[slot]=itemId
			end
			G.Notify(p,"Đã trang bị "..item.Name.."!")
		end
	elseif act=="ForgeCraft" then
		local itemId=payload.itemId or payload.recipeId
		local item=itemId and C.Items[itemId]
		local recipe=itemId and C.ForgeRecipes[itemId]
		if not item then return end
		local costGold=recipe and recipe.Gold or 300
		if (profile.Gold or 0)<costGold then
			G.Notify(p,"Không đủ Gold để chế tác "..item.Name.." (Cần "..costGold.." Gold)!")
			return
		end
		if recipe and recipe.Materials then
			for matId,reqCount in pairs(recipe.Materials) do
				if (profile.Inventory[matId] or 0)<reqCount then
					local matName=C.Items[matId] and C.Items[matId].Name or matId
					G.Notify(p,"Thiếu nguyên liệu: "..matName.." ("..(profile.Inventory[matId] or 0).."/"..reqCount..")!")
					return
				end
			end
			for matId,reqCount in pairs(recipe.Materials) do
				profile.Inventory[matId]=math.max(0,(profile.Inventory[matId] or 0)-reqCount)
			end
		end
		profile.Gold-=costGold
		profile.Inventory[itemId]=(profile.Inventory[itemId] or 0)+1
		if item.Slot=="Weapon" then
			if not item.ClassId or item.ClassId==profile.ClassId then
				profile.Weapon=itemId
				profile.Equipped.Weapon=itemId
				profile.Loadouts=profile.Loadouts or {}
				profile.Loadouts[profile.ClassId]=itemId
			else
				profile.Loadouts=profile.Loadouts or {}
				profile.Loadouts[item.ClassId]=itemId
			end
		elseif item.Slot and item.Slot~="Material" and item.Slot~="Quest" then
			profile.Equipped[item.Slot]=itemId
		end
		G.Notify(p,"Rèn thành công: "..item.Name.."!")
	elseif act=="ForgeEnhance" then
		local cur=profile.WeaponEnhance or 0
		if cur>=15 then
			G.Notify(p,"Vũ khí đã đạt cấp cường hóa tối đa (+15)!")
			return
		end
		if (profile.Gold or 0)<100 then
			G.Notify(p,"Cần 100 Gold để cường hóa vũ khí!")
			return
		end
		profile.Gold-=100
		if (profile.Inventory.SkyIron or 0)>0 then profile.Inventory.SkyIron-=1 end
		if (profile.Inventory.upgrade_material or 0)>0 then profile.Inventory.upgrade_material-=1 end
		profile.WeaponEnhance=math.min(15,cur+1)
		G.Notify(p,"Cường hóa vũ khí thành công: +"..profile.WeaponEnhance.." (+"..(profile.WeaponEnhance*6).."% Weapon ATK)!")
	elseif act=="UpgradeSkill" then
		local skillId=payload.skillId
		if not skillId or not C.Actions[skillId] then return end
		local cur=profile.SkillLevels[skillId] or 1
		if cur>=5 then
			G.Notify(p,(C.SkillNames[skillId] or skillId).." đã đạt cấp tối đa (Lv. 5)!")
			return
		end
		if (profile.SkillPoints or 0)<1 then
			G.Notify(p,"Không đủ Điểm Kỹ Năng (Skill Points)!")
			return
		end
		profile.SkillPoints-=1
		profile.SkillLevels[skillId]=cur+1
		G.Notify(p,"Nâng cấp "..(C.SkillNames[skillId] or skillId).." lên Lv. "..profile.SkillLevels[skillId].."!")
	elseif act=="ResetSkills" then
		local refund=0
		for k,lv in pairs(profile.SkillLevels) do
			if type(lv)=="number" and lv>1 then
				refund+=(lv-1)
			end
			profile.SkillLevels[k]=1
		end
		profile.SkillPoints=(profile.SkillPoints or 0)+refund
		G.Notify(p,"Đã đặt lại Kỹ Năng! Hoàn trả "..refund.." Skill Points.")
	elseif act=="FastTravel" then
		local nodeId=payload.nodeId or payload.id
		local node=nodeId and ((C.FastTravel and C.FastTravel[nodeId]) or FALLBACK_FAST_TRAVEL[nodeId])
		if not node or not r then return end
		if G.Boss and G.Boss.Party[p] then
			G.Notify(p,"Không thể dịch chuyển khi đang trong đấu trường Aureon!")
			return
		end
		profile.UnlockedWorlds=profile.UnlockedWorlds or {}
		profile.UnlockedWorlds.SkyHub=true
		profile.UnlockedWorlds.GoldenSky=true
		profile.UnlockedWorlds.FrozenCyber=true
		profile.UnlockedWorlds.ShadowRealm=true
		profile.UnlockedWorlds.VerdantCrown=true
		profile.UnlockedWorlds.EmberforgeWastes=true
		profile.UnlockedWorlds.AbyssalTides=true
		profile.UnlockedWorlds.ChronosBastion=true
		profile.UnlockedWorlds.VeilsEnd=true
		p:SetAttribute("CurrentRealm",node.Realm or "GoldenSky")
		G.Teleport(p,node.Pos)
		G.Notify(p,"Dịch chuyển: "..node.Name)
	elseif act=="ClaimDaily" then
		if (profile.DailyClaimed or 0)>=7 then
			G.Notify(p,"Bạn đã nhận trọn bộ quà điểm danh 7 Ngày!")
			return
		end
		profile.DailyClaimed=math.min(7,(profile.DailyClaimed or 0)+1)
		profile.Gold=(profile.Gold or 0)+500
		profile.CoreShards=(profile.CoreShards or 0)+100
		profile.Inventory.SunshardCore=(profile.Inventory.SunshardCore or 0)+2
		profile.Potions=(profile.Potions or 0)+1
		G.Notify(p,"Nhận quà Ngày "..profile.DailyClaimed..": +500 Gold, +100 Core Shards, +2 Sunshard Core!")
	elseif act=="SetPartySize" then
		local req=tostring(payload.size or payload.partySize or "Solo")
		local lv=tonumber(profile.Level) or 1
		if req=="Duo" and lv<15 then
			profile.PartySize="Solo"
			G.SyncCompanions(p)
			G.Notify(p,"🔒 Cần đạt Cấp 15 để mở khóa Đồng Hành đầu tiên [Kairo • Vanguard]!")
		elseif (req=="Trio" or req=="Raid 4") and lv<30 then
			profile.PartySize=maxPartySizeForLevel(lv)
			G.SyncCompanions(p)
			G.Notify(p,"🔒 Cần đạt Cấp 30 để mở khóa Pháp Sư Trị Liệu [Lumen • Starweaver]!")
		elseif (req=="Squad" or req=="Raid 6") and lv<50 then
			profile.PartySize=maxPartySizeForLevel(lv)
			G.SyncCompanions(p)
			G.Notify(p,"🔒 Cần đạt Cấp 50 để mở khóa Sát Thủ Lôi Tốc [Nyx • Shadowblitz]!")
		else
			profile.PartySize=req
			G.SyncCompanions(p)
			G.Notify(p,"Đội hình Đồng Hành AI: "..profile.PartySize)
		end
	elseif act=="StartBossRush" then
		local bossId=payload.bossId or "CryonPrime"
		if not r then return end
		profile.UnlockedWorlds=profile.UnlockedWorlds or {}
		profile.UnlockedWorlds.GoldenSky=true
		profile.UnlockedWorlds.FrozenCyber=true
		profile.UnlockedWorlds.ShadowRealm=true
		local targetBoss=nil
		if bossId=="AureonSentinel" then
			p:SetAttribute("CurrentRealm","GoldenSky")
			if not G.Boss or not G.Boss.Alive then
				targetBoss=G.StartBoss({p})
			else
				targetBoss=G.Boss
				targetBoss.Party[p]=true
			end
			G.Teleport(p,Vector3.new(0,51,-84))
		elseif bossId=="PirateCaptainVance" then
			p:SetAttribute("CurrentRealm","GoldenSky")
			for _,e in ipairs(G.Enemies) do
				if e.Id=="PirateCaptainVance" and e.Alive then targetBoss=e break end
			end
			if not targetBoss then
				targetBoss=G.SpawnEnemy("PirateCaptainVance",Vector3.new(-520,52,30),false,false)
			end
			G.Teleport(p,Vector3.new(-520,52,50))
		elseif bossId=="OrderCyborgBoss" then
			p:SetAttribute("CurrentRealm","FrozenCyber")
			for _,e in ipairs(G.Enemies) do
				if (e.Id=="OrderCyborgBoss" or e.Id=="OrderCyborg") and e.Alive then targetBoss=e break end
			end
			if not targetBoss then
				targetBoss=G.SpawnEnemy("OrderCyborgBoss",Vector3.new(3040,72,110),false,false)
			end
			G.Teleport(p,Vector3.new(3040,72,130))
		elseif bossId=="CryonPrime" then
			p:SetAttribute("CurrentRealm","FrozenCyber")
			for _,e in ipairs(G.Enemies) do
				if e.Id=="CryonPrime" and e.Alive then targetBoss=e break end
			end
			if not targetBoss then
				targetBoss=G.SpawnEnemy("CryonPrime",Vector3.new(2500,54,-104),false,false)
			end
			G.Teleport(p,C.FastTravel.CryonArena.Pos)
		elseif bossId=="SoulReaperRift" then
			p:SetAttribute("CurrentRealm","ShadowRealm")
			for _,e in ipairs(G.Enemies) do
				if e.Id=="SoulReaperRift" and e.Alive then targetBoss=e break end
			end
			if not targetBoss then
				targetBoss=G.SpawnEnemy("SoulReaperRift",Vector3.new(-3160,100,-330),false,false)
			end
			G.Teleport(p,Vector3.new(-3160,100,-310))
		elseif bossId=="AbyssalLeviathan" or bossId=="SkySeaBeast" then
			local isLev=(bossId=="AbyssalLeviathan")
			p:SetAttribute("CurrentRealm",isLev and "ShadowRealm" or "FrozenCyber")
			local spawnPos=isLev and Vector3.new(-2540,72,-700) or Vector3.new(2980,48,-460)
			for _,e in ipairs(G.Enemies) do
				if e.Id==bossId and e.Alive then targetBoss=e break end
			end
			if not targetBoss then
				targetBoss=G.SpawnEnemy(bossId,spawnPos,false,false)
			end
			G.Teleport(p,spawnPos+Vector3.new(0,2,22))
		elseif bossId=="Noxar" then
			p:SetAttribute("CurrentRealm","ShadowRealm")
			for _,e in ipairs(G.Enemies) do
				if e.Id=="Noxar" and e.Alive then targetBoss=e break end
			end
			if not targetBoss then
				targetBoss=G.SpawnEnemy("Noxar",Vector3.new(-2405,68,-55),false,false)
			end
			G.Teleport(p,C.FastTravel.NoxarArena.Pos)
		else
			local expansionBossArenas={
				Sylvaris={Realm="VerdantCrown", Spawn=Vector3.new(20.0,122.5,-2400.0), PlayerPos=Vector3.new(0.0,123.0,-2380.0)},
				Ignivar={Realm="EmberforgeWastes", Spawn=Vector3.new(2400.0,122.5,-2387.4), PlayerPos=Vector3.new(2400.0,123.0,-2405.0)},
				Nerith={Realm="AbyssalTides", Spawn=Vector3.new(-2400.0,122.5,-2378.0), PlayerPos=Vector3.new(-2400.0,123.0,-2360.0)},
				Aion={Realm="ChronosBastion", Spawn=Vector3.new(0.0,182.5,-4206.0), PlayerPos=Vector3.new(0.0,183.0,-4186.0)},
				Veyr={Realm="VeilsEnd", Spawn=Vector3.new(0.0,262.5,-5811.7), PlayerPos=Vector3.new(0.0,263.0,-5788.0)},
				AbyssalSovereignDragon={Realm="ShadowRealm", Spawn=Vector3.new(-2385.0,68.5,-68.0), PlayerPos=Vector3.new(-2405.0,68.5,-42.0)},
			}
			local bArena=expansionBossArenas[bossId]
			if bArena then
				profile.UnlockedWorlds[bArena.Realm]=true
				p:SetAttribute("CurrentRealm",bArena.Realm)
				for _,e in ipairs(G.Enemies) do
					if e.Id==bossId and e.Alive then targetBoss=e break end
				end
				if not targetBoss then
					targetBoss=G.SpawnEnemy(bossId,bArena.Spawn,false,false)
				end
				G.Teleport(p,bArena.PlayerPos)
			else
				for _,e in ipairs(G.Enemies) do
					if e.Id==bossId and e.Alive then
						targetBoss=e
						G.Teleport(p,e.Body.Position+Vector3.new(0,2,16))
						break
					end
				end
			end
		end
		if targetBoss then
			local baseHP=C.Enemies[targetBoss.Id] and C.Enemies[targetBoss.Id].HP or targetBoss.MaxHP
			targetBoss.MaxHP=math.floor(baseHP*1.5)
			targetBoss.HP=targetBoss.MaxHP
			targetBoss.Break=0
			targetBoss.Phase=1
			targetBoss.Shield=false
			targetBoss.Phase2Triggered=false
			targetBoss.Phase3Triggered=false
			if targetBoss.Model then
				targetBoss.Model:SetAttribute("BossPhase",1)
				targetBoss.Model:SetAttribute("EnemyAttackClip","UltimateAwakening")
				targetBoss.Model:SetAttribute("EnemyAttackAt",workspace:GetServerTimeNow())
			end
			G.Notify(p,"⚔ ABYSSAL REMATCH: "..targetBoss.Config.Name)
		end
	elseif act=="TriggerKataPose" then
		local clipName=tostring(payload.clip or "UltimateAwakening")
		if clipName~="HeroicKata" and clipName~="ElementalSurge" and clipName~="UltimateAwakening" then
			clipName="UltimateAwakening"
		end
		if r then
			R.CombatFX:FireAllClients({
				Kind="PoseKata",
				Position=r.Position,
				Actor=p.UserId,
				Action=clipName,
				Clip=clipName,
			})
		end
		G.Notify(p,"⚡ 3D MOTION KATA: Đang thi triển bộ chuyển động 12-Keyframe ["..clipName.."]!")
	elseif act=="UsePotion" then
		local now=os.clock()
		if now<(rt.Cooldowns.Potion or 0) then
			G.Notify(p,"Bình Hồi Phục đang hồi ("..math.ceil(rt.Cooldowns.Potion-now).."s)!")
			return
		end
		if (profile.Potions or 0)<=0 then
			G.Notify(p,"Đã hết Bình Hồi Phục!")
			return
		end
		if not h or not r then return end
		profile.Potions-=1
		rt.Cooldowns.Potion=now+6
		local heal=math.max(60,math.floor(h.MaxHealth*0.4))
		h.Health=math.min(h.MaxHealth,h.Health+heal)
		G.FireCombatEvent({
			kind="DamageNumber",
			pos=r.Position+Vector3.new(0,2,0),
			amount=heal,
			crit=false,
			breakDmg=0,
			element="Heal",
			Text="+"..tostring(heal).." HP",
		})
		G.Notify(p,"Đã dùng Bình Hồi Phục (+"..heal.." HP)!")
	elseif act=="ClaimQuestReward" or act=="AcceptQuest" then
		if profile.LastCompletedQuest then
			local cid=profile.LastCompletedQuest
			profile.LastCompletedQuest=nil
			profile.Gold=(profile.Gold or 0)+200
			profile.CoreShards=(profile.CoreShards or 0)+50
			profile.Potions=(profile.Potions or 0)+1
			G.Notify(p,"Nhận thưởng nhiệm vụ "..cid..": +200 Gold, +50 Core Shards, +1 Potion!")
		end
		local q=C.Quests[profile.QuestIndex]
		if q and not profile.Accepted then
			profile.Accepted=true
			G.Notify(p,"Đã nhận nhiệm vụ "..q.Id..": "..q.Name)
		end
	elseif act=="SelectSlot" then
		profile.ActiveSlot=math.clamp(tonumber(payload.slot) or 1,1,4)
		if profile.ActiveSlot==2 then
			profile.HeldFruit=profile.EquippedFruit or "GaleCore"
		elseif payload.clearHeldFruit then
			profile.HeldFruit=""
		end
	elseif act=="HoldFruit" then
		local fid=tostring(payload.fruitId or profile.EquippedFruit or "GaleCore")
		if profile.HeldFruit==fid and not payload.forceHold then
			profile.HeldFruit=""
			G.Notify(p,"Đã cất Trái Ác Quỷ 3D vào túi.")
		else
			profile.HeldFruit=fid
			local fcfg=getFruitCfg(fid)
			G.Notify(p,"✋ Đang cầm mô hình 3D ["..(fcfg and fcfg.Name or fid).."] trên tay!")
		end
	elseif act=="RollFruit" then
		local canonicalIds={
			"GaleCore","SandstoneCore","SolarFlameCore","GlacierIceCore","CelestialLightCore","StarforgedMagmaCore",
			"ThunderRumbleCore","AstralGravityCore","DimensionalPortalCore","SolarTitanCore","AetherflowCore","AbyssalSovereignCore"
		}
		local fruitId=canonicalIds[math.random(1,#canonicalIds)]
		local fruit=getFruitCfg(fruitId)
		if (profile.Gold or 0)>=25000 then
			profile.Gold-=25000
		end
		profile.StoredFruits[fruitId]=(profile.StoredFruits[fruitId] or 0)+1
		profile.HeldFruit=fruitId
		G.Notify(p,"🎲 GACHA TRÁI ÁC QUỶ: Bạn quay trúng ["..(fruit.Rarity or "Legendary").."] "..(fruit.Name or fruitId).." (Đã cầm trên tay 3D)!")
	elseif act=="EatFruit" then
		local fid=payload.fruitId or profile.EquippedFruit or "SolarTitanCore"
		local fruit=getFruitCfg(fid)
		profile.EquippedFruit=fid
		profile.ActiveSlot=2
		profile.HeldFruit=fid
		profile.StoredFruits[fid]=math.max(1,profile.StoredFruits[fid] or 1)
		if p.Character then p.Character:SetAttribute("FruitTransform","") end
		G.Notify(p,"🍎 Đã ăn & trang bị "..(fruit and fruit.Name or fid).."! Bấm [2] và dùng chiêu [Z][X][C][V][F]!")
	elseif act=="AwakenFruit" then
		local fid=payload.fruitId or profile.EquippedFruit or "SolarTitanCore"
		local fruit=getFruitCfg(fid)
		if (profile.CoreShards or 0)>=500 then
			profile.CoreShards-=500
		end
		profile.AwakenedFruits[fid]=true
		G.Notify(p,"⚡ THỨC TỈNH V2: Đã mở khóa kỹ năng Awakened V2 (+25% Sát Thương, +20% Tầm Đánh) cho "..(fruit and fruit.Name or fid).."!")
	elseif act=="SwitchFightingStyle" then
		local sid=payload.styleId or "SkybornCombat"
		local style=getStyleCfg(sid)
		profile.FightingStyle=sid
		profile.UnlockedStyles[sid]=true
		G.Notify(p,"🥊 Đã chuyển sang bộ võ: "..(style and style.Name or sid))
	elseif act=="EquipGun" then
		local gid=payload.gunId or "soul_guitar_void"
		local gun=getGunCfg(gid)
		profile.EquippedGun=gid
		G.Notify(p,"🔫 Đã trang bị Pháp Khí: "..(gun and gun.Name or gid))
	elseif act=="AddStat" then
		local stat=tostring(payload.stat or "Melee")
		if profile.StatAlloc[stat]~=nil then
			local amt=math.max(1,math.floor(tonumber(payload.amount) or 1))
			local avail=profile.StatPoints or 0
			local use=avail>0 and math.min(avail,amt) or amt
			if avail>0 then
				profile.StatPoints=avail-use
			end
			profile.StatAlloc[stat]=(profile.StatAlloc[stat] or 1)+use
		end
	elseif act=="RefundStats" then
		local refund=0
		for k,v in pairs(profile.StatAlloc) do
			if type(v)=="number" and v>1 then
				refund+=(v-1)
				profile.StatAlloc[k]=1
			end
		end
		profile.StatPoints=(profile.StatPoints or 0)+refund
		G.Notify(p,"🔄 Đã hoàn trả "..tostring(refund).." Điểm Chỉ Số (Stat Points)!")
	elseif act=="ToggleAura" then
		profile.Haki.Aura=not profile.Haki.Aura
		if p.Character then p.Character:SetAttribute("HakiAura",profile.Haki.Aura) end
		G.Notify(p,"⚔ Haki Vũ Trang (Busoshoku): "..(profile.Haki.Aura and "BẬT (+20% ATK, +15% DEF)" or "TẮT"))
	elseif act=="ToggleInstinct" then
		profile.Haki.Instinct=not profile.Haki.Instinct
		if p.Character then p.Character:SetAttribute("HakiInstinct",profile.Haki.Instinct) end
		G.Notify(p,"👁 Haki Quan Sát (Kenbunshoku): "..(profile.Haki.Instinct and "BẬT (Tự động né đòn)" or "TẮT"))
	elseif act=="ConquerorBurst" then
		if r then
			local stats=G.Stats(p)
			local dmg=((stats and stats.ATK) or 50)*3.5
			for _,e in ipairs(G.Enemies) do
				if e.Alive and e.Model and e.Model.Parent and e.Body and distance(r.Position,e.Body.Position)<=38 then
					if not e.Config.Boss and e~=G.Boss then
						e.StunnedUntil=os.clock()+4
					end
					G.Hit(p,e,dmg,45,"ConquerorHaki")
				end
			end
			G.FireCombatEvent({
				kind="SkillVFX",
				skillId="ConquerorHaki",
				element="Void",
				pos=r.Position,
				look=r.CFrame.LookVector,
				userId=p.UserId,
			})
			R.CombatFX:FireAllClients({Kind="Skill",Position=r.Position,Actor=p.UserId,Action="UltimateAwakening"})
			G.Notify(p,"👑 HAKI BÁ VƯƠNG: Chấn động không gian!")
		end
	elseif act=="ActivateRaceV4" then
		profile.RaceV4Active=not profile.RaceV4Active
		local raceName=profile.Race or "Skyborn"
		if p.Character then
			p.Character:SetAttribute("RaceV4",profile.RaceV4Active and raceName or "")
		end
		if r and profile.RaceV4Active then
			R.CombatFX:FireAllClients({Kind="Skill",Position=r.Position,Actor=p.UserId,Action="UltimateAwakening"})
		end
		if h then
			local s=G.Stats(p)
			if s then
				h.MaxHealth=s.HP
				h.Health=s.HP
			end
		end
		G.Notify(p,"✨ THỨC TỈNH CHỦNG TỘC V4 ["..raceName.."]: Toàn bộ chỉ số +30%!")
	elseif act=="RerollRace" then
		local curIdx=1
		for i,rname in ipairs(RACE_ORDER) do
			if rname==profile.Race then curIdx=i break end
		end
		profile.Race=RACE_ORDER[(curIdx%#RACE_ORDER)+1]
		if p.Character and profile.RaceV4Active then
			p.Character:SetAttribute("RaceV4",profile.Race)
		end
		G.Notify(p,"🧬 Đã thức tỉnh dòng máu mới: Chủng tộc "..profile.Race.." (V4)!")
	elseif act=="SetFaction" then
		profile.Faction=(payload.faction=="Marine") and "Marine" or "Pirate"
		G.Notify(p,"🏴‍☠️ Đã chọn phe: "..(profile.Faction=="Marine" and "Hải Quân Thiên Không (Sky Marines)" or "Hải Tặc Bầu Trời (Sky Pirates)").."!")
	elseif act=="SpawnSkyShip" then
		if r then
			G.BuildSkyShip(p,payload.dockPos or (r.Position+r.CFrame.LookVector*14),payload.shipId)
			G.Notify(p,"⛵ Đã triệu hồi Chiến Hạm Bay 3D (Sky Ship)!")
		end
	elseif act=="StartAwakeningRaid" then
		if r then
			p:SetAttribute("CurrentRealm","FrozenCyber")
			G.Teleport(p,Vector3.new(3040,72,152))
			G.SpawnEnemy("FrostDrone",Vector3.new(3028,70.5,136),false,true)
			G.SpawnEnemy("CryoGuard",Vector3.new(3040,70.5,124),false,true)
			G.SpawnEnemy("CyberArcher",Vector3.new(3052,70.5,136),false,true)
			G.SpawnEnemy("OrderCyborgBoss",Vector3.new(3040,70.5,134),false,true)
			profile.CoreShards=(profile.CoreShards or 0)+500
			local fid=profile.EquippedFruit or "SolarTitanCore"
			profile.AwakenedFruits[fid]=true
			G.Notify(p,"⚡ ĐỘT KÍCH THỨC TỈNH (ORDER CYBORG RAID) BẮT ĐẦU!")
		end
	elseif act=="SpawnSeaEvent" or act=="SummonLeviathan" then
		if r then
			local seaId=(act=="SummonLeviathan" or payload.bossId=="AbyssalLeviathan") and "AbyssalLeviathan"
				or ((payload.bossId=="SkySeaBeast") and "SkySeaBeast" or ((math.random()<0.5) and "SkySeaBeast" or "AbyssalLeviathan"))
			G.SpawnEnemy(seaId,r.Position+Vector3.new(0,2,-26),false,true)
			G.Notify(p,"🌊 SỰ KIỆN BIỂN MÂY: "..(seaId=="AbyssalLeviathan" and "Thủy Tổ Hư Không ABYSSAL LEVIATHAN" or "Thủy Quái SKY SEA BEAST").." đã trồi lên từ biển mây!")
		end
	end
	if h then
		local s=G.Stats(p)
		if s then
			local ratio=h.Health/math.max(1,h.MaxHealth)
			h.MaxHealth=s.HP
			h.Health=math.clamp(math.floor(s.HP*ratio),1,s.HP)
		end
	end
	local blade=p.Character and p.Character:FindFirstChild("SkybornBlade") if blade then blade.Transparency=1 end
	if p.Character then Cosmetics.Equip(p.Character,profile.Weapon~=nil) end
	G.Sync(p)
end
function G.ChooseAppearance(p,payload)
	if not G.Rate(p,'Appearance',.2)then return end
	if type(payload)=='string'then payload={Gender=payload}end
	if type(payload)~='table'then return end
	local profile=D.Get(p);local rt=G.Runtime[p];local r,h=root(p)
	if not profile or not rt or not r or not h then return end
	local class=payload.ClassId or profile.ClassId;local gender=payload.Gender or profile.Gender or'Male'
	if not C.Classes[class]or(gender~='Male'and gender~='Female')then return end
	if G.Boss and G.Boss.Party[p] then G.Notify(p,'Không thể đổi nhân vật khi đang đánh Boss Aureon!')return end
	local hp=h.Health/math.max(1,h.MaxHealth)
	profile.Loadouts=profile.Loadouts or{}
	profile.Equipped=profile.Equipped or{}
	if class~=profile.ClassId then
		if profile.Weapon then
			profile.Loadouts[profile.ClassId]=profile.Weapon
		end
		local weapon=profile.Loadouts[class]
		if not weapon or (profile.Inventory[weapon] or 0)<=0 then
			weapon=C.ClassWeapons[class]
			profile.Inventory[weapon]=math.max(1,profile.Inventory[weapon]or 0)
		end
		profile.Weapon=weapon
		profile.Equipped.Weapon=weapon
	end
	profile.ClassId=class;profile.Gender=gender
	h.MaxHealth=G.Stats(p).HP;h.Health=math.max(1,h.MaxHealth*hp);h.WalkSpeed=C.Classes[class].Speed
	local blade=p.Character and p.Character:FindFirstChild("SkybornBlade") if blade then blade.Transparency=1 end
	if p.Character then Cosmetics.Equip(p.Character,profile.Weapon~=nil) end
	G.Notify(p,"Đã chọn: "..C.Classes[class].Name.." • "..(gender=="Female" and "Nữ" or "Nam"))
	G.Sync(p)
end
G.Appearance=G.ChooseAppearance
local cachedSolidFolder=nil
local cachedSolidOverlap=nil
local function setEnemyMoving(e,isMoving)
	if e.LastMoving~=isMoving then
		e.LastMoving=isMoving
		if e.Model and e.Model.Parent then
			e.Model:SetAttribute("EnemyMoving",isMoving)
		end
	end
end
local function move(e,destination,dt,speedOverride)
	local spd=speedOverride or e.Config.Speed or 0
	if spd<=0 then setEnemyMoving(e,false) return false end
	local delta=Vector3.new(destination.X-e.Body.Position.X,0,destination.Z-e.Body.Position.Z)
	if delta.Magnitude<.15 then setEnemyMoving(e,false) return false end
	local step=delta.Unit*math.min(delta.Magnitude,spd*dt)
	if not clearLine(e.Body.Position,e.Body.Position+step*2) then setEnemyMoving(e,false) return false end
	local rawPos=e.Body.Position+step
	local refY=e.HomeFloorY or (e.Home.Y - math.max(2.2, e.Body.Size.Y * 0.5))
	local fy=e.CachedGroundY
	if not fy or not e.LastGroundCheckPos or (Vector3.new(rawPos.X,0,rawPos.Z)-Vector3.new(e.LastGroundCheckPos.X,0,e.LastGroundCheckPos.Z)).Magnitude>0.75 then
		if W.RaycastGround and not W.RaycastGround(rawPos, refY) then setEnemyMoving(e,false) return false end
		fy=safeGroundY(rawPos, refY)
		fy=math.clamp(fy, refY - 2.8, refY + 2.8)
		e.CachedGroundY=fy
		e.LastGroundCheckPos=rawPos
	end
	local position=Vector3.new(rawPos.X,fy+math.max(2.2,e.Body.Size.Y*0.5),rawPos.Z)
	local solidFolder=workspace:FindFirstChild("Solid3DObstacles")
	if solidFolder then
		if cachedSolidFolder~=solidFolder or not cachedSolidOverlap then
			cachedSolidFolder=solidFolder
			cachedSolidOverlap=OverlapParams.new()
			cachedSolidOverlap.FilterType=Enum.RaycastFilterType.Include
			cachedSolidOverlap.FilterDescendantsInstances={solidFolder}
		end
		local hits=workspace:GetPartBoundsInRadius(position,1.8,cachedSolidOverlap)
		if #hits>0 then setEnemyMoving(e,false) return false end
	end
	e.Model:PivotTo(CFrame.lookAt(position,position+delta.Unit))
	if e.LastAttrFloorY~=fy then
		e.LastAttrFloorY=fy
		e.Model:SetAttribute('EnemyFloorY',fy)
	end
	setEnemyMoving(e,true)
	return true
end
function G.TickEnemy(e,dt)
	if not e.Alive or not e.Model.Parent then return end
	local now=os.clock()
	if SINGLETON_BOSSES[e.Id] or e.Config.Boss then
		e.Phase=(e.HP>e.MaxHP*0.70) and 1 or ((e.HP>e.MaxHP*0.35) and 2 or 3)
	end
	if e.LastBossPhase~=e.Phase then
		e.LastBossPhase=e.Phase
		e.Model:SetAttribute("BossPhase",e.Phase)
	end
	local nextLabel=e.Config.Name.."  "..math.ceil(e.HP).." / "..e.MaxHP
	if e.LastLabelText~=nextLabel then
		e.LastLabelText=nextLabel
		e.Label.Text=nextLabel
	end
	if e.Id=="EnergyPylon" or e.Id=="CryonPillar" or e.Id=="NoxarVoidFX" then return end

	if e.Id=="CryonPrime" then
		if e.Phase>=2 and not e.Phase2Triggered then
			e.Phase2Triggered=true
			e.Shield=true
			e.Model:SetAttribute("EnemyAttackClip","UltimateAwakening")
			e.Model:SetAttribute("EnemyAttackDuration",1.6)
			e.Model:SetAttribute("EnemyAttackAt",workspace:GetServerTimeNow())
			e.Model:SetAttribute("CryonSummonAt",workspace:GetServerTimeNow())
			local pillarCoords={
				Vector3.new(2482,54,-94),
				Vector3.new(2518,54,-94),
				Vector3.new(2500,54,-120),
			}
			for _,ppos in ipairs(pillarCoords) do
				local pil=G.SpawnEnemy("CryonPillar",ppos,false,true)
				if pil then pil.BossOwner=e end
			end
			for _,plr in ipairs(Players:GetPlayers()) do
				local pr=root(plr)
				if pr and distance(pr.Position,e.Body.Position)<95 then
					G.Notify(plr,"❄ CRYON PRIME bật Khiên Băng! Hãy phá 3 Cột Băng Vĩnh Cửu!")
				end
			end
		end
		if e.Shield then
			local alivePillars=0
			for _,other in ipairs(G.Enemies) do
				if other.Id=="CryonPillar" and other.Alive then alivePillars+=1 end
			end
			if alivePillars==0 then
				e.Shield=false
				e.StunnedUntil=now+5
				e.ImmuneUntil=now+11
				for _,plr in ipairs(Players:GetPlayers()) do
					local pr=root(plr)
					if pr and distance(pr.Position,e.Body.Position)<95 then
						G.Notify(plr,"Các cột băng đã vỡ! Cryon Prime bị choáng!")
					end
				end
			end
		end
	elseif e.Id=="Noxar" then
		if e.Phase>=2 and not e.Phase2Triggered then
			e.Phase2Triggered=true
			e.Shield=true
			e.Model:SetAttribute("EnemyAttackClip","UltimateAwakening")
			e.Model:SetAttribute("EnemyAttackDuration",1.8)
			e.Model:SetAttribute("EnemyAttackAt",workspace:GetServerTimeNow())
			local vfx=G.SpawnEnemy("NoxarVoidFX",Vector3.new(-2405,68,-42),false,true)
			if vfx then vfx.BossOwner=e end
			G.SpawnEnemy("VoidPirate",Vector3.new(-2415,68,-45),false,true)
			for _,plr in ipairs(Players:GetPlayers()) do
				local pr=root(plr)
				if pr and distance(pr.Position,e.Body.Position)<95 then
					G.Notify(plr,"🟣 NOXAR triệu hồi Void Singularity! Phá hủy nó để phá khiên!")
				end
			end
		end
		if e.Shield then
			local aliveVoid=0
			for _,other in ipairs(G.Enemies) do
				if other.Id=="NoxarVoidFX" and other.Alive then aliveVoid+=1 end
			end
			if aliveVoid==0 then
				e.Shield=false
				e.StunnedUntil=now+5
				e.ImmuneUntil=now+11
				for _,plr in ipairs(Players:GetPlayers()) do
					local pr=root(plr)
					if pr and distance(pr.Position,e.Body.Position)<95 then
						G.Notify(plr,"Void Singularity đã bị phá hủy! Noxar bị choáng 5 giây!")
					end
				end
			end
		end
	end

	if e==G.Boss then
		local active=false for p in pairs(e.Party) do if inArena(p) and D.Get(p) then active=true break end end
		if not active then
			e.EmptySince=e.EmptySince or now
			if now-e.EmptySince>8 then
				e.Alive=false e.Model:Destroy() G.Boss=nil G.ResetAt=now+8
				for _,pillar in ipairs(G.Enemies) do if pillar.BossOwner==e and pillar.Alive then pillar.Alive=false pillar.Model:Destroy() end end
			end
			return
		else e.EmptySince=nil end
		if e.Shield then
			local remaining=0 for _,pillar in ipairs(G.Enemies) do if pillar.BossOwner==e and pillar.Alive then remaining+=1 end end
			if remaining==0 then e.Shield=false e.StunnedUntil=now+3 e.ImmuneUntil=now+9 end
		end
	end
	if now<e.StunnedUntil then e.State="Stunned" setEnemyMoving(e,false) return end
	if distance(e.Body.Position,e.Home)>e.Config.Leash then e.Returning=true end
	if e.Returning then
		e.State="ReturnToSpawn" move(e,e.Home,dt)
		if distance(e.Body.Position,e.Home)<2 then
			e.Returning=false e.HP=e.MaxHP e.Contributors={}
			setEnemyMoving(e,false)
		end
		return
	end
	local aggroRange=e.Config.Aggro or e.Config.Leash or 35
	local target=nil local closest=aggroRange
	for _,p in ipairs(Players:GetPlayers()) do
		local r=root(p)
		if r and D.Get(p) and participant(e,p) and (e~=G.Boss or inArena(p)) and distance(r.Position,e.Home)<e.Config.Leash then
			local d=distance(r.Position,e.Body.Position) if d<closest then closest=d target=p end
		end
	end
	if not target then
		e.State="Patrol"
		if (e.Config.Speed or 0)<=0 or e.Id=="TrainingDrone" or e.Id=="FrostDrone" or e.Config.Boss or e==G.Boss then
			setEnemyMoving(e,false)
			return
		end
		if now<(e.PatrolWaitUntil or 0) then
			setEnemyMoving(e,false)
			return
		end
		local dir=e.PatrolDir or 1
		local goal=e.Home+Vector3.new(dir*4.2,0,0)
		local dx=math.abs(goal.X-e.Body.Position.X)
		if dx<0.35 or not move(e,goal,dt,math.min((e.Config.Speed or 12)*0.55,7.5)) then
			e.PatrolDir=-dir
			e.PatrolWaitUntil=now+2.4
			setEnemyMoving(e,false)
		end
		return
	end
	local r=root(target) if not r then setEnemyMoving(e,false) return end

	if e.Id=="CryonPrime" then
		e.SpecialTimer=(e.SpecialTimer or 0)+dt
		if e.SpecialTimer>=7 then
			e.SpecialTimer=0
			e.RecoverUntil=now+2.2
			setEnemyMoving(e,false)
			if e.Phase==1 then
				e.Model:SetAttribute("EnemyAttackClip","HeroicKata")
				e.Model:SetAttribute("EnemyAttackDuration",2.0)
				e.Model:SetAttribute("EnemyAttackAt",workspace:GetServerTimeNow())
				G.Telegraph(e,e.Body.Position,18,2.0,(e.Config.ATK or 38)*1.3,"⚠ GLACIAL SMASH")
			else
				e.Model:SetAttribute("EnemyAttackClip","UltimateAwakening")
				e.Model:SetAttribute("EnemyAttackDuration",2.2)
				e.Model:SetAttribute("EnemyAttackAt",workspace:GetServerTimeNow())
				local tpos=r.Position
				G.Telegraph(e,tpos,16,2.2,(e.Config.ATK or 38)*1.45,"⚠ ABSOLUTE ZERO STORM")
				for _,off in ipairs({Vector3.new(-12,0,8),Vector3.new(12,0,8),Vector3.new(0,0,-12)}) do
					G.Telegraph(e,tpos+off,6.5,1.8,(e.Config.ATK or 38)*0.85,"❄ FROST SHARD")
				end
			end
			return
		end
	elseif e.Id=="Noxar" then
		e.SpecialTimer=(e.SpecialTimer or 0)+dt
		if e.SpecialTimer>=6.5 then
			e.SpecialTimer=0
			e.RecoverUntil=now+2.3
			setEnemyMoving(e,false)
			if e.Phase>=3 then
				e.Phase3Triggered=true
				e.Model:SetAttribute("EnemyAttackClip","UltimateAwakening")
				e.Model:SetAttribute("EnemyAttackDuration",2.4)
				e.Model:SetAttribute("EnemyAttackAt",workspace:GetServerTimeNow())
				e.Model:SetAttribute("NoxarPhaseFX","Phase3Judgement")
				e.Model:SetAttribute("NoxarFXAt",workspace:GetServerTimeNow())
				local tpos=r.Position
				G.Telegraph(e,tpos,16,2.1,(e.Config.ATK or 44)*1.5,"⚠ VOID ANNIHILATION")
				G.Telegraph(e,e.Home+Vector3.new(-14,0,10),12,2.4,(e.Config.ATK or 44)*1.2,"⚠ VOID ANNIHILATION")
				G.Telegraph(e,e.Home+Vector3.new(14,0,-10),12,2.4,(e.Config.ATK or 44)*1.2,"⚠ VOID ANNIHILATION")
			else
				e.Model:SetAttribute("EnemyAttackClip","HeroicKata")
				e.Model:SetAttribute("EnemyAttackDuration",2.0)
				e.Model:SetAttribute("EnemyAttackAt",workspace:GetServerTimeNow())
				G.Telegraph(e,r.Position,17,2.0,(e.Config.ATK or 44)*1.35,"⚠ VOID OBLITERATION")
			end
			return
		end
	end

	if now<(e.RecoverUntil or 0) then e.State="Recover" setEnemyMoving(e,false) return end
	if closest>e.Config.Range or not clearLine(e.Body.Position,r.Position) then e.State="Chase" move(e,r.Position,dt) return end
	if now<e.NextAttack then e.State="Recover" setEnemyMoving(e,false) return end
	e.State="Attack"
	setEnemyMoving(e,false)
	local isBoss=e==G.Boss local phase=isBoss and e.Phase or 1
	local windup=isBoss and (phase==3 and .6 or .95) or((e.Id=='CryonPrime'or e.Id=='Noxar')and 1.2 or .8)
	e.AttackNumber=(e.AttackNumber or 0)+1
	local cycleClip="Attack"
	if e.AttackNumber%5==0 then
		cycleClip="UltimateAwakening"
	elseif e.AttackNumber%4==0 then
		cycleClip="Heavy"
	elseif e.AttackNumber%3==0 then
		cycleClip="HeroicKata"
	elseif e.AttackNumber%2==0 then
		cycleClip="ElementalSurge"
	end
	e.Model:SetAttribute('EnemyAttackClip',cycleClip)
	e.Model:SetAttribute('EnemyAttackDuration',windup+.45)
	e.Model:SetAttribute('EnemyAttackAt',workspace:GetServerTimeNow())
	e.NextAttack=now+(isBoss and (phase==3 and 1.7 or 2.7) or 2.2) e.RecoverUntil=now+windup+.45
	local isRanged=(e.Id=="LightArcher" or e.Id=="CyberArcher" or e.Id=="ShadowArcher" or e.Config.Ranged)
	local attackPos=isRanged and r.Position or e.Body.Position
	local radius=isBoss and 15 or (isRanged and 5.5 or e.Config.Range)
	if e.Id=='CryonPrime' or e.Id=='Noxar' then radius=14 end
	if e.Id~="TrainingDrone" and e.Id~="FrostDrone" then pcall(Cosmetics.BossSwing,e.Model,windup) end
	G.Telegraph(e,Vector3.new(attackPos.X,safeGroundY(attackPos)+.1,attackPos.Z),radius,windup,e.Config.ATK or e.Config.Attack or 15,isBoss and "⚠ SOLAR CLEAVE" or "⚠ DANGER")
	if isBoss then
		e.AttackNumber=(e.AttackNumber or 0)+1
		if phase>=2 or e.AttackNumber%3==0 then
			local pos=Vector3.new(r.Position.X,safeGroundY(r.Position)+.1,r.Position.Z)
			G.Telegraph(e,pos,phase==3 and 9 or 7,windup+.35,(e.Config.ATK or 30)*.8,"⚠ SOLAR FLARE")
		end
	end
end

function G.EnsureWorld()
	if not workspace:FindFirstChild("ActiveCompanions") then
		local f=Instance.new("Folder")
		f.Name="ActiveCompanions"
		f.Parent=workspace
	end
	if not workspace:FindFirstChild("TempFX") then
		local f=Instance.new("Folder")
		f.Name="TempFX"
		f.Parent=workspace
	end
	local keepEditShowcase = {
		CryonPillar = true,
		NoxarVoidFX = true,
		AbyssalDragonHybrid = true,
		AbyssalSovereignDragon = true,
		Chronos = true,
		DrVega = true,
	}
	for _, folderName in ipairs({"HeroShowcase", "NPCs", "Ships", "ActiveEnemies", "ActiveBosses", "SkybreakWorldObjects"}) do
		local f = workspace:FindFirstChild(folderName)
		if f then
			for _, ch in ipairs(f:GetChildren()) do
				if ch:IsA("Model") and not ch:FindFirstChild("Body") and not keepEditShowcase[ch.Name] then
					ch:Destroy()
				end
			end
		end
	end
	local worldObjects=workspace:FindFirstChild("SkybreakWorldObjects")
	if not worldObjects then
		worldObjects=Instance.new("Folder")
		worldObjects.Name="SkybreakWorldObjects"
		worldObjects.Parent=workspace
	end

	local jpFolder=workspace:FindFirstChild("JumpPads")
	if jpFolder then jpFolder:Destroy() end
	jpFolder=Instance.new("Folder")
	jpFolder.Name="JumpPads"
	jpFolder.Parent=workspace

	-- 12 Skyborn Treasure Chests (Invisible trigger parts; zero blocky yellow/neon bricks)
	local chestCoords={
		-- Golden Sky (4)
		Vector3.new(-105,37,145), Vector3.new(-102,41,68), Vector3.new(28,41,18), Vector3.new(-28,51.5,-165),
		-- Frozen Cyber (4)
		Vector3.new(2376,41.3,150), Vector3.new(2420,45.3,62), Vector3.new(2528,47.3,15), Vector3.new(2650,65.2,-125),
		-- Shadow Realm (4)
		Vector3.new(-2585,54.4,115), Vector3.new(-2580,54.4,128), Vector3.new(-2472,58.5,42), Vector3.new(-2665,73,-95),
	}
	G.Chests={}
	for idx,cpos in ipairs(chestCoords) do
		local cid=string.format("Chest_%02d",idx)
		local base=W.Part(worldObjects,cid,Vector3.new(3.6,2.2,2.4),cpos,Color3.fromRGB(235,182,62),Enum.Material.SmoothPlastic)
		base.Transparency=1
		base.CanCollide=false
		base:SetAttribute("Interactable","Chest")
		base:SetAttribute("InteractableId",cid)
		base:SetAttribute("ChestId",cid)
		local lid=W.Part(worldObjects,cid.."_Glow",Vector3.new(3.8,0.45,2.6),cpos+Vector3.new(0,1.25,0),Color3.fromRGB(255,225,110),Enum.Material.SmoothPlastic)
		lid.Transparency=1
		lid.CanCollide=false
		local prompt=Instance.new("ProximityPrompt")
		prompt.ActionText="Mở Rương"
		prompt.ObjectText="Rương Báu Skyborn ("..cid..")"
		prompt.MaxActivationDistance=12
		prompt.HoldDuration=0
		prompt.Parent=base
		prompt.Triggered:Connect(function(p) G.Interact(p,cid) end)
		W.Interactions[cid]=base
		G.Chests[cid]={Id=cid,Part=base,Lid=lid,OpenedUntil=0}
	end

	-- 3 Regional Home Point Aether Shrines (Clean Interactive Triggers — 3D geometry is built natively via DelegatedV5Renderer)
	local shrineSpecs={
		{Id="Shrine_GoldenSky", Realm="GoldenSky", Pos=Vector3.new(-74,38,150), Glow=Color3.fromRGB(88,238,255)},
		{Id="Shrine_FrozenCyber", Realm="FrozenCyber", Pos=Vector3.new(2396,45,72), Glow=Color3.fromRGB(72,242,255)},
		{Id="Shrine_ShadowRealm", Realm="ShadowRealm", Pos=Vector3.new(-2562,55,132), Glow=Color3.fromRGB(245,48,118)},
	}
	G.Shrines={}
	for _,sh in ipairs(shrineSpecs) do
		local spos=sh.Pos
		local pillar=W.Part(worldObjects,sh.Id,Vector3.new(2.6,5.2,2.6),spos+Vector3.new(0,2.6,0),sh.Glow,Enum.Material.SmoothPlastic)
		pillar.Transparency=1
		pillar.CanCollide=false
		pillar:SetAttribute("Interactable","AetherShrine")
		pillar:SetAttribute("InteractableId",sh.Id)
		pillar:SetAttribute("ShrineRealm",sh.Realm)

		local bill=Instance.new("BillboardGui")
		bill.Size=UDim2.fromOffset(220,42)
		bill.StudsOffset=Vector3.new(0,4.5,0)
		bill.AlwaysOnTop=false bill.MaxDistance=45
		bill.Parent=pillar
		local tl=Instance.new("TextLabel")
		tl.Size=UDim2.fromScale(1,1)
		tl.BackgroundTransparency=1
		tl.Font=Enum.Font.GothamBold
		tl.TextSize=15
		tl.TextColor3=sh.Glow
		tl.TextStrokeTransparency=0.2
		tl.Text="⛩ Aether Shrine • "..sh.Realm.." [E]"
		tl.Parent=bill
		local prompt=Instance.new("ProximityPrompt")
		prompt.ActionText="Hồi Phục & Lưu Điểm Hồi Sinh"
		prompt.ObjectText="Điện Thờ Aether • "..sh.Realm
		prompt.MaxActivationDistance=13
		prompt.HoldDuration=0
		prompt.Parent=pillar
		prompt.Triggered:Connect(function(p) G.Interact(p,sh.Id) end)
		W.Interactions[sh.Id]=pillar
		G.Shrines[sh.Id]={Id=sh.Id,Realm=sh.Realm,Pos=sh.Pos,Part=pillar}
	end

	-- 6 Aether Jump Pads
	local padSpecs={
		{Name="Pad_SkyHub_WestGarden", Start=Vector3.new(-118,36.2,124), Target=Vector3.new(-91,43,76), Arc=18, Duration=1.05},
		{Name="Pad_WestGarden_LumenPlaza", Start=Vector3.new(-74,40.2,48), Target=Vector3.new(-32,43,18), Arc=18, Duration=1.05},
		{Name="Pad_LumenPlaza_TraversalRest", Start=Vector3.new(44,40.2,14), Target=Vector3.new(136,53,-94), Arc=32, Duration=1.55},
		{Name="Pad_FrozenSpawn_FrozenOutpost", Start=Vector3.new(2392,40.2,132), Target=Vector3.new(2404,47,76), Arc=18, Duration=1.05},
		{Name="Pad_FrozenOutpost_CrystalPlaza", Start=Vector3.new(2422,44.2,52), Target=Vector3.new(2472,49,16), Arc=20, Duration=1.15},
		{Name="Pad_ShadowSpawn_ShadowOutpost", Start=Vector3.new(-2552,53.6,102), Target=Vector3.new(-2495,61,48), Arc=20, Duration=1.15},
	}
	G.JumpPads={}
	for _,ps in ipairs(padSpecs) do
		local ring=Instance.new("Part")
		ring.Name=ps.Name
		ring.Shape=Enum.PartType.Cylinder
		ring.Size=Vector3.new(0.25,6.5,6.5)
		ring.CFrame=CFrame.new(ps.Start)*CFrame.Angles(0,0,math.pi/2)
		ring.Color=Color3.fromRGB(70,195,235)
		ring.Material=Enum.Material.SmoothPlastic
		ring.Transparency=0.45
		ring.Anchored=true
		ring.CanCollide=false
		ring.CanQuery=false
		ring.CanTouch=false
		ring:SetAttribute("TargetPos",ps.Target)
		ring.Parent=jpFolder

		local bill=Instance.new("BillboardGui")
		bill.Size=UDim2.fromOffset(170,36)
		bill.StudsOffset=Vector3.new(0,2.8,0)
		bill.AlwaysOnTop=false bill.MaxDistance=42
		bill.Parent=ring
		local tl=Instance.new("TextLabel")
		tl.Size=UDim2.fromScale(1,1)
		tl.BackgroundTransparency=1
		tl.Font=Enum.Font.GothamBlack
		tl.TextSize=13
		tl.TextColor3=Color3.fromRGB(105,240,255)
		tl.TextStrokeTransparency=0.25
		tl.Text="⚡ AETHER JUMP PAD"
		tl.Parent=bill

		table.insert(G.JumpPads,ps)
	end

	-- Interactive Shrine & Raid Console Triggers at the 12 Grand Sky Islands + 5 Expansion Realms (invisible Part triggers so 100% of Models in SkybreakWorldObjects are rigged 3D characters)
	local islandSpecs={
		{Id="ZiolesGachaShrine", Title="⛩ ZIOLES GACHA SHRINE • ĐIỆN THỜ TRIỆU HỒI TRÁI ÁC QUỶ", Realm="GoldenSky", Pos=Vector3.new(-220,38,264), GlowCol=Color3.fromRGB(110,235,255)},
		{Id="AetherShrines", Title="⛩ AETHER HOME SHRINE • ĐÀI ĐIỆN THỜ LƯU ĐIỂM HỒI SINH", Realm="GoldenSky", Pos=Vector3.new(60,38,254), GlowCol=Color3.fromRGB(88,238,255)},
		{Id="WestGardenPirateBastion", Title="🏴‍☠️ WEST GARDEN PIRATE BASTION • PHÁO ĐÀI VƯỜN TÂY", Realm="GoldenSky", Pos=Vector3.new(-520,48,52), GlowCol=Color3.fromRGB(255,205,82)},
		{Id="SunshardSanctuary", Title="☀ SUNSHARD SANCTUARY • THÁNH ĐỊA THÁI DƯƠNG", Realm="GoldenSky", Pos=Vector3.new(540,88,-24), GlowCol=Color3.fromRGB(255,218,95)},
		{Id="CyberportCafe", Title="☕ CYBERPORT CAFÉ • QUÁN CÀ PHÊ GIAO DỊCH SEA 2", Realm="FrozenCyber", Pos=Vector3.new(2020,46,350), GlowCol=Color3.fromRGB(88,238,255)},
		{Id="PermafrostGarrison", Title="❄ PERMAFROST GARRISON • PHÁO ĐÀI TUYẾT BĂNG", Realm="FrozenCyber", Pos=Vector3.new(1960,56,-170), GlowCol=Color3.fromRGB(115,242,255)},
		{Id="MicrochipRaidLab", Title="⚡ MICROCHIP RAID LAB • PHÒNG THÍ NGHIỆM THỨC TỈNH", Realm="FrozenCyber", Pos=Vector3.new(3040,68,132), GlowCol=Color3.fromRGB(95,240,255), IsRaidLab=true},
		{Id="GlacialWreckage", Title="🚢 GLACIAL WRECKAGE • XÁC TÀU BĂNG CỔ ĐẠI", Realm="FrozenCyber", Pos=Vector3.new(3005,44,-424), GlowCol=Color3.fromRGB(145,242,255)},
		{Id="CastleOnTheVoid", Title="🏰 CASTLE ON THE VOID • DINH THỰ HƯ KHÔNG", Realm="ShadowRealm", Pos=Vector3.new(-3160,56,271), GlowCol=Color3.fromRGB(225,110,255)},
		{Id="UmbralSanctum", Title="🌲 UMBRAL CRYSTAL SANCTUM • RỪNG TINH THỂ ĐEN", Realm="ShadowRealm", Pos=Vector3.new(-1920,60,260), GlowCol=Color3.fromRGB(245,95,255)},
		{Id="TempleOfTheCore", Title="🌌 TEMPLE OF THE CORE • ĐỀN THỜ TỘC V4", Realm="ShadowRealm", Pos=Vector3.new(-3160,96,-306), GlowCol=Color3.fromRGB(210,120,255)},
		{Id="LeviathanAbyss", Title="🌙 MIRAGE SKY ISLAND • VỰC THẲM LEVIATHAN", Realm="ShadowRealm", Pos=Vector3.new(-2540,68,-654), GlowCol=Color3.fromRGB(78,238,255)},
		{Id="VerdantCrown", Title="🌿 THE VERDANT CROWN • VƯƠNG MIỆN CỔ THỤ (REALM 4)", Realm="VerdantCrown", Pos=Vector3.new(0,120,-2380), GlowCol=Color3.fromRGB(95,242,155)},
		{Id="EmberforgeWastes", Title="🔥 EMBERFORGE WASTES • HOANG MẠC LÒ RÈN LỬA (REALM 5)", Realm="EmberforgeWastes", Pos=Vector3.new(2400,120,-2388), GlowCol=Color3.fromRGB(255,145,78)},
		{Id="AbyssalTides", Title="🌊 ABYSSAL TIDES • THỦY TRIỀU VỰC SÂU (REALM 6)", Realm="AbyssalTides", Pos=Vector3.new(-2400,120,-2374), GlowCol=Color3.fromRGB(68,215,245)},
		{Id="ChronosBastion", Title="⏳ CHRONOS BASTION • PHÁO ĐÀI THỜI GIAN (REALM 7)", Realm="ChronosBastion", Pos=Vector3.new(0,180,-4186), GlowCol=Color3.fromRGB(255,215,92)},
		{Id="VeilsEnd", Title="✨ THE VEIL'S END • TẬN CÙNG BỨC MÀN (REALM 8)", Realm="VeilsEnd", Pos=Vector3.new(0,260,-5788), GlowCol=Color3.fromRGB(215,115,255)},
	}
	for _,isl in ipairs(islandSpecs) do
		local ipos=W.SnapToOpenGround and select(1,W.SnapToOpenGround(isl.Pos,isl.Pos.Y,0)) or isl.Pos
		isl.Pos=ipos
		local consolePos=ipos+Vector3.new(0,3.5,0)
		local consolePillar=W.Part(worldObjects,isl.Id.."_Console",Vector3.new(2.8,5.5,2.8),consolePos,isl.GlowCol,Enum.Material.SmoothPlastic)
		consolePillar.Transparency=1
		consolePillar.CanCollide=false

		local cBill=Instance.new("BillboardGui")
		cBill.Size=UDim2.fromOffset(260,48)
		cBill.StudsOffset=Vector3.new(0,5.5,0)
		cBill.AlwaysOnTop=false cBill.MaxDistance=55
		cBill.Parent=consolePillar
		local cLbl=Instance.new("TextLabel")
		cLbl.Size=UDim2.fromScale(1,1)
		cLbl.BackgroundTransparency=1
		cLbl.Font=Enum.Font.GothamBlack
		cLbl.TextSize=14
		cLbl.TextColor3=isl.GlowCol
		cLbl.TextStrokeTransparency=0.2
		cLbl.Text=isl.Title
		cLbl.Parent=cBill

		local cPrompt=Instance.new("ProximityPrompt")
		cPrompt.MaxActivationDistance=15
		cPrompt.HoldDuration=0
		cPrompt.Parent=consolePillar
		if isl.IsRaidLab then
			cPrompt.ActionText="Khởi Động Awakening Raid (5-Chip Console)"
			cPrompt.ObjectText="Microchip Raid Console • Frozen Cyber"
			cPrompt.Triggered:Connect(function(p)
				G.Equipment(p,{action="StartAwakeningRaid"})
			end)
		else
			local shId="Shrine_"..isl.Id
			cPrompt.ActionText="Hồi Phục & Lưu Điểm Hồi Sinh"
			cPrompt.ObjectText="Điện Thờ • "..isl.Id
			local shSpec={Id=shId,Realm=isl.Realm,Pos=ipos,Part=consolePillar}
			G.Shrines[shId]=shSpec
			cPrompt.Triggered:Connect(function(p)
				G.ActivateShrine(p,shSpec)
			end)
		end
	end


	-- Sequential End-of-World 3D Progression Portals (World n -> World n+1 at the culmination/boss exit of every World!)
	local wpFolder=workspace:FindFirstChild("WorldPortals")
	if wpFolder then wpFolder:Destroy() end
	wpFolder=Instance.new("Folder")
	wpFolder.Name="WorldPortals"
	wpFolder.Parent=workspace

	local worldPortalSpecs={
		-- Sea 1: Golden Sky Odyssey (Worlds 1 -> 2 -> 3 -> 4 -> 5 -> Sea 2)
		{Id="WorldGate_01", Order=1, NextOrder=2, StageLabel="WORLD 1 → WORLD 2", Title="Cổng Cuối World 1 (Aureon Citadel Exit)", TargetTitle="World 2 • Zioles Gacha Shrine", TargetRealm="GoldenSky", TargetWorldKey="ZiolesGachaShrine", Element="Sky", Pos=Vector3.new(0.0,48.0,-118.0), TargetPos=Vector3.new(-220.0,41.0,264.0), Col=Color3.fromRGB(255,215,85)},
		{Id="WorldGate_02", Order=2, NextOrder=3, StageLabel="WORLD 2 → WORLD 3", Title="Cổng Cuối World 2 (Zioles Shrine Exit)", TargetTitle="World 3 • Aether Home Shrine", TargetRealm="GoldenSky", TargetWorldKey="AetherShrines", Element="Sky", Pos=Vector3.new(-220.0,38.0,252.0), TargetPos=Vector3.new(60.0,41.0,254.0), Col=Color3.fromRGB(95,238,255)},
		{Id="WorldGate_03", Order=3, NextOrder=4, StageLabel="WORLD 3 → WORLD 4", Title="Cổng Cuối World 3 (Aether Shrine Exit)", TargetTitle="World 4 • West Garden Pirate Bastion", TargetRealm="GoldenSky", TargetWorldKey="WestGarden", Element="Sky", Pos=Vector3.new(60.0,38.0,266.0), TargetPos=Vector3.new(-520.0,51.0,52.0), Col=Color3.fromRGB(255,205,82)},
		{Id="WorldGate_04", Order=4, NextOrder=5, StageLabel="WORLD 4 → WORLD 5", Title="Cổng Cuối World 4 (West Garden Exit)", TargetTitle="World 5 • Sunshard Sky Sanctuary", TargetRealm="GoldenSky", TargetWorldKey="SunshardSanctuary", Element="Sky", Pos=Vector3.new(-520.0,48.0,22.0), TargetPos=Vector3.new(540.0,91.0,-24.0), Col=Color3.fromRGB(255,222,95)},
		{Id="WorldGate_05", Order=5, NextOrder=6, StageLabel="WORLD 5 → WORLD 6 (SEA 2)", Title="Cổng Cuối World 5 (Sunshard Apex Exit)", TargetTitle="World 6 • Frozen Cyber Continent (Sea 2)", TargetRealm="FrozenCyber", TargetWorldKey="FrozenCyber", Element="Frost", Pos=Vector3.new(540.0,88.0,-64.0), TargetPos=Vector3.new(2390.0,43.5,155.0), Col=Color3.fromRGB(88,238,255)},
		-- Sea 2: Frozen Cyber Odyssey (Worlds 6 -> 7 -> 8 -> 9 -> 10 -> Sea 3)
		{Id="WorldGate_06", Order=6, NextOrder=7, StageLabel="WORLD 6 → WORLD 7", Title="Cổng Cuối World 6 (Cryon Citadel Exit)", TargetTitle="World 7 • Cyberport Café Trading Hub", TargetRealm="FrozenCyber", TargetWorldKey="CyberportCafe", Element="Frost", Pos=Vector3.new(2500.0,51.0,-118.0), TargetPos=Vector3.new(2020.0,49.0,350.0), Col=Color3.fromRGB(88,238,255)},
		{Id="WorldGate_07", Order=7, NextOrder=8, StageLabel="WORLD 7 → WORLD 8", Title="Cổng Cuối World 7 (Cyberport Exit)", TargetTitle="World 8 • Permafrost Garrison Fortress", TargetRealm="FrozenCyber", TargetWorldKey="PermafrostGarrison", Element="Frost", Pos=Vector3.new(2020.0,46.0,375.0), TargetPos=Vector3.new(1960.0,59.0,-170.0), Col=Color3.fromRGB(115,242,255)},
		{Id="WorldGate_08", Order=8, NextOrder=9, StageLabel="WORLD 8 → WORLD 9", Title="Cổng Cuối World 8 (Permafrost Exit)", TargetTitle="World 9 • Microchip Awakening Raid Lab", TargetRealm="FrozenCyber", TargetWorldKey="MicrochipRaidLab", Element="Frost", Pos=Vector3.new(1960.0,56.0,-195.0), TargetPos=Vector3.new(3040.0,71.0,132.0), Col=Color3.fromRGB(95,245,255)},
		{Id="WorldGate_09", Order=9, NextOrder=10, StageLabel="WORLD 9 → WORLD 10", Title="Cổng Cuối World 9 (Raid Lab Exit)", TargetTitle="World 10 • Glacial Wreckage Danger Sea", TargetRealm="FrozenCyber", TargetWorldKey="GlacialWreckage", Element="Frost", Pos=Vector3.new(3040.0,68.0,102.0), TargetPos=Vector3.new(2996.0,47.0,-414.0), Col=Color3.fromRGB(135,242,255)},
		{Id="WorldGate_10", Order=10, NextOrder=11, StageLabel="WORLD 10 → WORLD 11 (SEA 3)", Title="Cổng Cuối World 10 (Glacial Abyss Exit)", TargetTitle="World 11 • Shadow Realm Continent (Sea 3)", TargetRealm="ShadowRealm", TargetWorldKey="ShadowRealm", Element="Void", Pos=Vector3.new(3008.0,44.0,-460.0), TargetPos=Vector3.new(-2570.0,56.5,125.0), Col=Color3.fromRGB(215,95,255)},
		-- Sea 3: Shadow Realm Odyssey (Worlds 11 -> 12 -> 13 -> 14 -> 15 -> Realm 4)
		{Id="WorldGate_11", Order=11, NextOrder=12, StageLabel="WORLD 11 → WORLD 12", Title="Cổng Cuối World 11 (Noxar Throne Exit)", TargetTitle="World 12 • Castle on the Void Mansion", TargetRealm="ShadowRealm", TargetWorldKey="CastleOnTheVoid", Element="Void", Pos=Vector3.new(-2405.0,66.0,-72.0), TargetPos=Vector3.new(-3160.0,59.0,271.0), Col=Color3.fromRGB(225,110,255)},
		{Id="WorldGate_12", Order=12, NextOrder=13, StageLabel="WORLD 12 → WORLD 13", Title="Cổng Cuối World 12 (Castle Void Exit)", TargetTitle="World 13 • Umbral Crystal Sanctum", TargetRealm="ShadowRealm", TargetWorldKey="UmbralSanctum", Element="Void", Pos=Vector3.new(-3160.0,56.0,242.0), TargetPos=Vector3.new(-1920.0,63.0,260.0), Col=Color3.fromRGB(245,95,255)},
		{Id="WorldGate_13", Order=13, NextOrder=14, StageLabel="WORLD 13 → WORLD 14", Title="Cổng Cuối World 13 (Umbral Sanctum Exit)", TargetTitle="World 14 • Temple of the Core (Race V4)", TargetRealm="ShadowRealm", TargetWorldKey="TempleOfTheCore", Element="Void", Pos=Vector3.new(-1894.0,60.0,234.0), TargetPos=Vector3.new(-3160.0,99.0,-306.0), Col=Color3.fromRGB(210,120,255)},
		{Id="WorldGate_14", Order=14, NextOrder=15, StageLabel="WORLD 14 → WORLD 15", Title="Cổng Cuối World 14 (Temple Core Exit)", TargetTitle="World 15 • Mirage Sky Island (Leviathan Abyss)", TargetRealm="ShadowRealm", TargetWorldKey="LeviathanAbyss", Element="Void", Pos=Vector3.new(-3160.0,96.0,-340.0), TargetPos=Vector3.new(-2540.0,71.0,-654.0), Col=Color3.fromRGB(78,238,255)},
		{Id="WorldGate_15", Order=15, NextOrder=16, StageLabel="WORLD 15 → WORLD 16 (REALM 4)", Title="Cổng Cuối World 15 (Mirage Abyss Exit)", TargetTitle="World 16 • The Verdant Crown (Realm 4)", TargetRealm="VerdantCrown", TargetWorldKey="VerdantCrown", Element="Sky", Pos=Vector3.new(-2540.0,68.0,-668.0), TargetPos=Vector3.new(0.0,123.0,-2380.0), Col=Color3.fromRGB(95,242,155)},
		-- Expansion Realms 4-8 (Worlds 16 -> 17 -> 18 -> 19 -> 20 -> Ascension Loop to World 1)
		{Id="WorldGate_16", Order=16, NextOrder=17, StageLabel="WORLD 16 → WORLD 17 (REALM 5)", Title="Cổng Cuối World 16 (Verdant Crown Exit)", TargetTitle="World 17 • Emberforge Wastes (Realm 5)", TargetRealm="EmberforgeWastes", TargetWorldKey="EmberforgeWastes", Element="Sky", Pos=Vector3.new(26.0,120.0,-2406.0), TargetPos=Vector3.new(2400.0,123.0,-2388.0), Col=Color3.fromRGB(255,145,78)},
		{Id="WorldGate_17", Order=17, NextOrder=18, StageLabel="WORLD 17 → WORLD 18 (REALM 6)", Title="Cổng Cuối World 17 (Emberforge Exit)", TargetTitle="World 18 • Abyssal Tides (Realm 6)", TargetRealm="AbyssalTides", TargetWorldKey="AbyssalTides", Element="Frost", Pos=Vector3.new(2400.0,120.0,-2416.0), TargetPos=Vector3.new(-2400.0,123.0,-2374.0), Col=Color3.fromRGB(68,215,245)},
		{Id="WorldGate_18", Order=18, NextOrder=19, StageLabel="WORLD 18 → WORLD 19 (REALM 7)", Title="Cổng Cuối World 18 (Abyssal Tides Exit)", TargetTitle="World 19 • Chronos Bastion (Realm 7)", TargetRealm="ChronosBastion", TargetWorldKey="ChronosBastion", Element="Sky", Pos=Vector3.new(-2400.0,120.0,-2392.0), TargetPos=Vector3.new(0.0,183.0,-4186.0), Col=Color3.fromRGB(255,215,92)},
		{Id="WorldGate_19", Order=19, NextOrder=20, StageLabel="WORLD 19 → WORLD 20 (REALM 8)", Title="Cổng Cuối World 19 (Chronos Bastion Exit)", TargetTitle="World 20 • The Veil's End (Realm 8)", TargetRealm="VeilsEnd", TargetWorldKey="VeilsEnd", Element="Void", Pos=Vector3.new(0.0,180.0,-4220.0), TargetPos=Vector3.new(0.0,263.0,-5788.0), Col=Color3.fromRGB(215,115,255)},
		{Id="WorldGate_20", Order=20, NextOrder=1, StageLabel="WORLD 20 → WORLD 1 (ASCENSION)", Title="Cổng Tận Cùng Bức Màn (Veil's End Apex)", TargetTitle="World 1 • Golden Sky Hub (Luân Hồi Thiên Giới)", TargetRealm="GoldenSky", TargetWorldKey="GoldenSky", Element="Sky", Pos=Vector3.new(0.0,260.0,-5818.0), TargetPos=Vector3.new(-92.0,39.5,153.0), Col=Color3.fromRGB(255,232,125)},
		-- Direct Main Continent Sea Gates & Spawn Plaza Portals
		{Id="WorldGate_SkyHub_Plaza", Order=1, NextOrder=2, StageLabel="SKY HUB → WORLD 2", Title="Cổng Dịch Chuyển Sky Hub", TargetTitle="World 2 • Zioles Gacha Shrine", TargetRealm="GoldenSky", TargetWorldKey="ZiolesGachaShrine", Element="Sky", Pos=Vector3.new(-76.0,36.0,162.0), TargetPos=Vector3.new(-220.0,41.0,264.0), Col=Color3.fromRGB(255,215,85)},
		{Id="WorldGate_Sea2_Plaza", Order=6, NextOrder=7, StageLabel="SEA 2 HUB → WORLD 7", Title="Cổng Dịch Chuyển Frozen Cyber", TargetTitle="World 7 • Cyberport Café Trading Hub", TargetRealm="FrozenCyber", TargetWorldKey="CyberportCafe", Element="Frost", Pos=Vector3.new(2376.0,40.3,138.0), TargetPos=Vector3.new(2020.0,49.0,350.0), Col=Color3.fromRGB(88,238,255)},
		{Id="WorldGate_Sea3_Plaza", Order=11, NextOrder=12, StageLabel="SEA 3 HUB → WORLD 12", Title="Cổng Dịch Chuyển Shadow Realm", TargetTitle="World 12 • Castle on the Void Mansion", TargetRealm="ShadowRealm", TargetWorldKey="CastleOnTheVoid", Element="Void", Pos=Vector3.new(-2572.0,53.5,112.0), TargetPos=Vector3.new(-3160.0,59.0,271.0), Col=Color3.fromRGB(215,95,255)},
		{Id="WorldGate_Sea1_to_Sea2", Order=1, NextOrder=6, StageLabel="SEA 1 → SEA 2 GATE", Title="Cổng Bắc Aureon Citadel", TargetTitle="Sea 2 • Frozen Cyber Continent", TargetRealm="FrozenCyber", TargetWorldKey="FrozenCyber", Element="Frost", Pos=Vector3.new(16.0,48.0,-199.0), TargetPos=Vector3.new(2390.0,43.5,155.0), Col=Color3.fromRGB(88,238,255)},
		{Id="WorldGate_Sea2_to_Sea3", Order=6, NextOrder=11, StageLabel="SEA 2 → SEA 3 GATE", Title="Cổng Bắc Cryon Citadel", TargetTitle="Sea 3 • Shadow Realm Continent", TargetRealm="ShadowRealm", TargetWorldKey="ShadowRealm", Element="Void", Pos=Vector3.new(2620.0,68.0,-130.0), TargetPos=Vector3.new(-2570.0,56.5,125.0), Col=Color3.fromRGB(215,95,255)},
	}
	G.WorldPortals={}
	for _,wp in ipairs(worldPortalSpecs) do
		if W.SnapToOpenGround then
			wp.Pos=select(1,W.SnapToOpenGround(wp.Pos,wp.Pos.Y,0))
			wp.TargetPos=select(1,W.SnapToOpenGround(wp.TargetPos,wp.TargetPos.Y-3.0,3.0))
		end
		local gm=Instance.new("Model")
		gm.Name=wp.Id
		gm:SetAttribute("PortalId",wp.Id)
		gm:SetAttribute("StageLabel",wp.StageLabel)
		gm:SetAttribute("TargetTitle",wp.TargetTitle)
		gm:SetAttribute("TargetRealm",wp.TargetRealm)
		gm:SetAttribute("Element",wp.Element)
		gm:SetAttribute("Order",wp.Order)
		gm:SetAttribute("NextOrder",wp.NextOrder)
		gm:SetAttribute("FloorY",wp.Pos.Y)
		gm:SetAttribute("GlowColor",wp.Col)
		gm.Parent=wpFolder

		local centerPos=wp.Pos+Vector3.new(0,4.2,0)
		local core=W.Part(gm,"GateCore",Vector3.new(6.5,8.5,2.5),centerPos,wp.Col,Enum.Material.Neon)
		core.Transparency=1
		core.CanCollide=false
		core:SetAttribute("Interactable","WorldPortal")
		core:SetAttribute("InteractableId",wp.Id)
		gm.PrimaryPart=core

		local pBill=Instance.new("BillboardGui")
		pBill.Size=UDim2.fromOffset(290,54)
		pBill.StudsOffset=Vector3.new(0,6.8,0)
		pBill.AlwaysOnTop=false
		pBill.MaxDistance=75
		pBill.Parent=core
		local pLbl=Instance.new("TextLabel")
		pLbl.Size=UDim2.fromScale(1,1)
		pLbl.BackgroundTransparency=1
		pLbl.Font=Enum.Font.GothamBlack
		pLbl.TextSize=14
		pLbl.TextColor3=wp.Col
		pLbl.TextStrokeTransparency=0.18
		pLbl.Text="🌀 "..wp.StageLabel.."\n➡ "..wp.TargetTitle
		pLbl.Parent=pBill

		local pPrompt=Instance.new("ProximityPrompt")
		pPrompt.ActionText="Bước Vào Cổng Dịch Chuyển ("..wp.StageLabel..")"
		pPrompt.ObjectText=wp.Title.." ➡ "..wp.TargetTitle
		pPrompt.MaxActivationDistance=15
		pPrompt.HoldDuration=0
		pPrompt.RequiresLineOfSight=false
		pPrompt.Parent=core

		local gateSpec={
			Id=wp.Id,
			Order=wp.Order,
			NextOrder=wp.NextOrder,
			StageLabel=wp.StageLabel,
			Title=wp.Title,
			TargetTitle=wp.TargetTitle,
			TargetRealm=wp.TargetRealm,
			TargetWorldKey=wp.TargetWorldKey,
			Element=wp.Element,
			Pos=wp.Pos,
			CenterPos=centerPos,
			TargetPos=wp.TargetPos,
			Col=wp.Col,
			Part=core,
			Model=gm,
		}
		G.WorldPortals[wp.Id]=gateSpec
		W.Interactions[wp.Id]=core
		pPrompt.Triggered:Connect(function(p)
			G.EnterWorldPortal(p,gateSpec)
		end)
	end

	-- 3 Sky Shipwright Docks + Rigged 3D SkyShipwrightNPC + Rigged 3D Flagships
	local dockSpecs={
		{Id="Dock_GoldenSky", Realm="GoldenSky", Pos=Vector3.new(-110,38.2,158), FloorY=36.0, ShipPos=Vector3.new(-164,36,165), Col=Color3.fromRGB(238,190,72), ShipId="CelestialBrigantine"},
		{Id="Dock_FrozenCyber", Realm="FrozenCyber", Pos=Vector3.new(2368,42.5,160), FloorY=40.3, ShipPos=Vector3.new(2315,40,175), Col=Color3.fromRGB(92,228,255), ShipId="CyberEnforcer"},
		{Id="Dock_ShadowRealm", Realm="ShadowRealm", Pos=Vector3.new(-2588,55.5,128), FloorY=53.3, ShipPos=Vector3.new(-2642,52,132), Col=Color3.fromRGB(192,98,255), ShipId="LeviathanHunterShip"},
	}
	for _,dk in ipairs(dockSpecs) do
		local dm=Instance.new("Model")
		dm.Name=dk.Id
		dm.Parent=worldObjects
		local dpos=dk.Pos
		local npcBody=W.Part(dm,"Body",Vector3.new(2.2,4.6,1.8),dpos,dk.Col,Enum.Material.Metal)
		npcBody.Transparency=1
		npcBody.CanCollide=false
		dm.PrimaryPart=npcBody
		dm:SetAttribute("NPCId","SkyShipwrightNPC")
		dm:SetAttribute("VisualAsset","SkyShipwrightNPC")
		dm:SetAttribute("NPCFloorY",dk.FloorY)

		local dbill=Instance.new("BillboardGui")
		dbill.Size=UDim2.fromOffset(220,44)
		dbill.StudsOffset=Vector3.new(0,4.8,0)
		dbill.AlwaysOnTop=false dbill.MaxDistance=48
		dbill.Parent=npcBody
		local dtl=Instance.new("TextLabel")
		dtl.Size=UDim2.fromScale(1,1)
		dtl.BackgroundTransparency=1
		dtl.Font=Enum.Font.GothamBlack
		dtl.TextSize=14
		dtl.TextColor3=dk.Col
		dtl.TextStrokeTransparency=0.2
		dtl.Text="⛵ Sky Shipwright • Bến Tàu Bay"
		dtl.Parent=dbill

		local dprompt=Instance.new("ProximityPrompt")
		dprompt.ActionText="Triệu Hồi Tàu Bay 3D"
		dprompt.ObjectText="Sky Shipwright • Bến Tàu Bay"
		dprompt.MaxActivationDistance=15
		dprompt.HoldDuration=0
		dprompt.Parent=npcBody
		dprompt.RequiresLineOfSight=false
		dprompt.Style=Enum.ProximityPromptStyle.Default
		npcBody:SetAttribute("InteractableId",dk.Id)
		dprompt.Triggered:Connect(function(p)
			dm:SetAttribute("NPCTalkAt",os.clock())
			G.Equipment(p,{action="SpawnSkyShip",dockPos=dk.ShipPos,shipId=dk.ShipId})
			G.SendDialogue(p,"Sky Shipwright • Bến Tàu Bay","ĐẠI CÔNG TRÌNH SƯ TÀU BAY","Chiến hạm 3D ["..dk.ShipId.."] đã được triệu hồi tại bến cảng! Hãy bước lên ghế lái để điều khiển tàu bay vượt biển mây!","Mở Bản Đồ Dịch Chuyển [M]","OpenScreen:Map")
		end)

		-- Spawn Static Interactive Display Flagship (Rigged 3D Blender Ship)
		G.BuildSkyShip(dk.ShipId,dk.ShipPos,dk.ShipId)
	end

	-- Rigged 3D Lyra Commander NPC at Sky Hub
	do
		local lpos=Vector3.new(-76,38.2,140)
		local lm=Instance.new("Model")
		lm.Name="Lyra_SkyHubCommander"
		lm.Parent=worldObjects
		local lBody=W.Part(lm,"Body",Vector3.new(2.2,4.6,1.8),lpos,Color3.fromRGB(110,225,255),Enum.Material.Metal)
		lBody.Transparency=1
		lBody.CanCollide=false
		lm.PrimaryPart=lBody
		lm:SetAttribute("NPCId","Lyra")
		lm:SetAttribute("VisualAsset","Lyra")
		lm:SetAttribute("NPCFloorY",36.0)

		local lbill=Instance.new("BillboardGui")
		lbill.Size=UDim2.fromOffset(230,44)
		lbill.StudsOffset=Vector3.new(0,4.8,0)
		lbill.AlwaysOnTop=false lbill.MaxDistance=48
		lbill.Parent=lBody
		local ltl=Instance.new("TextLabel")
		ltl.Size=UDim2.fromScale(1,1)
		ltl.BackgroundTransparency=1
		ltl.Font=Enum.Font.GothamBlack
		ltl.TextSize=14
		ltl.TextColor3=Color3.fromRGB(115,235,255)
		ltl.TextStrokeTransparency=0.2
		ltl.Text="🧭 Lyra • Chỉ Huy Skyborn [E]"
		ltl.Parent=lbill

		local lprompt=Instance.new("ProximityPrompt")
		lprompt.ActionText="Nhận Nhiệm Vụ Cốt Truyện"
		lprompt.ObjectText="Lyra • Chỉ Huy Skyborn"
		lprompt.MaxActivationDistance=14
		lprompt.HoldDuration=0
		lprompt.Parent=lBody
		lprompt.RequiresLineOfSight=false
		lprompt.Style=Enum.ProximityPromptStyle.Default
		lBody:SetAttribute("InteractableId","Lyra")
		W.Interactions["Lyra"]=lBody
		lprompt.Triggered:Connect(function(p)
			lm:SetAttribute("NPCTalkAt",os.clock())
			G.Interact(p,"Lyra")
		end)
	end

	-- Rigged 3D Zioles Gacha Dealer NPC (both at Sky Hub & at ZiolesGachaShrine Island)
	for _,zSpec in ipairs({
		{Name="Zioles_AetherGachaShrine", Pos=Vector3.new(-106,38.2,142), FloorY=36.0},
		{Name="Zioles_IslandShrine", Pos=Vector3.new(-220,40.2,258), FloorY=38.0},
	}) do
		local zpos=zSpec.Pos
		local zm=Instance.new("Model")
		zm.Name=zSpec.Name
		zm.Parent=worldObjects
		local zBody=W.Part(zm,"Body",Vector3.new(2.2,4.6,1.8),zpos,Color3.fromRGB(185,95,255),Enum.Material.Metal)
		zBody.Transparency=1
		zBody.CanCollide=false
		zm.PrimaryPart=zBody
		zm:SetAttribute("NPCId","ZiolesGachaNPC")
		zm:SetAttribute("VisualAsset","ZiolesGachaNPC")
		zm:SetAttribute("NPCFloorY",zSpec.FloorY)

		local zbill=Instance.new("BillboardGui")
		zbill.Size=UDim2.fromOffset(250,48)
		zbill.StudsOffset=Vector3.new(0,4.8,0)
		zbill.AlwaysOnTop=false zbill.MaxDistance=48
		zbill.Parent=zBody
		local ztl=Instance.new("TextLabel")
		ztl.Size=UDim2.fromScale(1,1)
		ztl.BackgroundTransparency=1
		ztl.Font=Enum.Font.GothamBlack
		ztl.TextSize=14
		ztl.TextColor3=Color3.fromRGB(255,218,92)
		ztl.TextStrokeTransparency=0.2
		ztl.Text="🎲 Zioles • Aether Core Gacha"
		ztl.Parent=zbill

		local zprompt=Instance.new("ProximityPrompt")
		zprompt.ActionText="Random Trái Aether (Gacha)"
		zprompt.ObjectText="Zioles • Aether Core Gacha (25,000 Gold)"
		zprompt.MaxActivationDistance=14
		zprompt.HoldDuration=0
		zprompt.Parent=zBody
		zprompt.RequiresLineOfSight=false
		zprompt.Style=Enum.ProximityPromptStyle.Default
		zBody:SetAttribute("InteractableId","Zioles")
		W.Interactions[zSpec.Name]=zBody
		zprompt.Triggered:Connect(function(p)
			zm:SetAttribute("NPCTalkAt",os.clock())
			G.Interact(p,"Zioles")
		end)
	end

	-- Rigged 3D Ancient Monk • Celestial Godhuman Martial Arts Master (Sky Hub, Sunshard Sanctuary, Temple of the Core)
	for _,mSpec in ipairs({
		{Name="AncientMonk_GodhumanShrine", Pos=Vector3.new(-110,38.2,150), FloorY=36.0},
		{Name="AncientMonk_SunshardSanctuary", Pos=Vector3.new(522,90.2,-34), FloorY=88.0},
		{Name="AncientMonk_TempleOfTheCore", Pos=Vector3.new(-3178,98.2,-292), FloorY=96.0},
	}) do
		local mpos=mSpec.Pos
		local mm=Instance.new("Model")
		mm.Name=mSpec.Name
		mm.Parent=worldObjects
		local mBody=W.Part(mm,"Body",Vector3.new(2.2,4.6,1.8),mpos,Color3.fromRGB(255,218,88),Enum.Material.Metal)
		mBody.Transparency=1
		mBody.CanCollide=false
		mm.PrimaryPart=mBody
		mm:SetAttribute("NPCId","AncientMonkNPC")
		mm:SetAttribute("VisualAsset","AncientMonkNPC")
		mm:SetAttribute("NPCFloorY",mSpec.FloorY)

		local mbill=Instance.new("BillboardGui")
		mbill.Size=UDim2.fromOffset(250,46)
		mbill.StudsOffset=Vector3.new(0,4.8,0)
		mbill.AlwaysOnTop=false mbill.MaxDistance=48
		mbill.Parent=mBody
		local mtl=Instance.new("TextLabel")
		mtl.Size=UDim2.fromScale(1,1)
		mtl.BackgroundTransparency=1
		mtl.Font=Enum.Font.GothamBlack
		mtl.TextSize=14
		mtl.TextColor3=Color3.fromRGB(255,222,95)
		mtl.TextStrokeTransparency=0.2
		mtl.Text="🥋 Đại Sư Cổ Tự • Thần Quyền Sư Tổ"
		mtl.Parent=mbill

		local styleList=C.StyleOrder or {"SkybornCombat","ElectricClaw","GlacialKarate","DragonTalon","GodhumanSkyborn","SanguineVoidArt"}
		local mprompt=Instance.new("ProximityPrompt")
		mprompt.ActionText="Lĩnh Ngộ Võ Thuật / Đổi Thần Quyền"
		mprompt.ObjectText="Đại Sư Cổ Tự • Godhuman Master"
		mprompt.MaxActivationDistance=14
		mprompt.HoldDuration=0
		mprompt.Parent=mBody
		mprompt.RequiresLineOfSight=false
		mprompt.Style=Enum.ProximityPromptStyle.Default
		mBody:SetAttribute("InteractableId","AncientMonk")
		W.Interactions[mSpec.Name]=mBody
		mprompt.Triggered:Connect(function(p)
			mm:SetAttribute("NPCTalkAt",os.clock())
			G.Interact(p,"AncientMonk")
		end)
	end

	-- Rigged 3D Regional & Expansion World NPCs (Ensuring EVERY World Has Its Own Interactive 3D Rigged NPC)
	local regionalNPCs={
		{Name="NPC_AetherShrineKeeper", Asset="DrVega", Title="🔮 Dr. Vega • Học Giả Điện Thờ Aether", Pos=Vector3.new(60,40.2,257), FloorY=38.0, Col=Color3.fromRGB(95,235,255)},
		{Name="NPC_WestGardenScout", Asset="SkyShipwrightNPC", Title="🏴‍☠️ Thợ Săn Tiền Thưởng • West Garden Scout", Pos=Vector3.new(-511,50.0,49), FloorY=48.0, Col=Color3.fromRGB(255,205,82)},
		{Name="NPC_FrozenOutpostCommander", Asset="DrVega", Title="🧊 Dr. Vega • Chỉ Huy Tiền Đồn Băng", Pos=Vector3.new(2406,46.2,82), FloorY=44.0, Col=Color3.fromRGB(105,240,255)},
		{Name="NPC_CyberportBroker", Asset="ZiolesGachaNPC", Title="☕ Thương Nhân Cyberport • Giao Dịch Aether", Pos=Vector3.new(2012,48.2,352), FloorY=46.0, Col=Color3.fromRGB(88,238,255)},
		{Name="NPC_PermafrostQuartermaster", Asset="Kael", Title="🛡 Thiết Giáp Quân Nhu • Permafrost Warden", Pos=Vector3.new(1953,58.2,-173), FloorY=56.0, Col=Color3.fromRGB(125,242,255)},
		{Name="NPC_RaidLabScientist", Asset="DrVega", Title="🧬 Tiến Sĩ Dr. Vega • Chuyên Gia Thức Tỉnh Lõi", Pos=Vector3.new(3031,70.2,129), FloorY=68.0, Col=Color3.fromRGB(95,245,255)},
		{Name="NPC_GlacialExplorer", Asset="SkyShipwrightNPC", Title="🧭 Thuyền Trưởng Thám Hiểm • Glacial Navigator", Pos=Vector3.new(2996,46.2,-414), FloorY=44.0, Col=Color3.fromRGB(145,242,255)},
		{Name="NPC_ShadowVanguard", Asset="Chronos", Title="🟣 Chronos • Giám Hộ Hư Ảnh (Shadow Outpost)", Pos=Vector3.new(-2556,55.6,126), FloorY=53.4, Col=Color3.fromRGB(215,115,255)},
		{Name="NPC_CastleVoidSteward", Asset="Lyra", Title="🏰 Tổng Quản Hư Không • Void Citadel Steward", Pos=Vector3.new(-3168,58.2,268), FloorY=56.0, Col=Color3.fromRGB(225,110,255)},
		{Name="NPC_UmbralSwordmaster", Asset="Kael", Title="⚔ Kiếm Thánh Hắc Tinh • CDK Master Smith", Pos=Vector3.new(-1934,62.2,254), FloorY=60.0, Col=Color3.fromRGB(245,95,255)},
		{Name="NPC_MirageHunter", Asset="SkyShipwrightNPC", Title="🌊 Thợ Săn Thủy Tổ • Leviathan Hunter", Pos=Vector3.new(-2566,70.2,-664), FloorY=68.0, Col=Color3.fromRGB(78,238,255)},
		{Name="NPC_VerdantKeeper", Asset="AncientMonkNPC", Title="🌿 Đại Sư Cổ Thụ • Verdant Crown Keeper", Pos=Vector3.new(-14,122.2,-2386), FloorY=120.0, Col=Color3.fromRGB(95,242,155)},
		{Name="NPC_EmberforgeSmith", Asset="Kael", Title="🔥 Thợ Rèn Hỏa Tinh • Star-Forge Master", Pos=Vector3.new(2391,122.2,-2391), FloorY=120.0, Col=Color3.fromRGB(255,145,78)},
		{Name="NPC_AbyssalNavigator", Asset="SkyShipwrightNPC", Title="🌊 Hoa Tiêu Vực Thẳm • Abyssal Navigator", Pos=Vector3.new(-2426,122.2,-2384), FloorY=120.0, Col=Color3.fromRGB(68,215,245)},
		{Name="NPC_ChronosArchivist", Asset="Chronos", Title="⏳ Chronos • Đại Giám Hộ Thời Gian", Pos=Vector3.new(-10,182.2,-4190), FloorY=180.0, Col=Color3.fromRGB(255,215,92)},
		{Name="NPC_AstraelVanguard", Asset="Male_SkyGuardian", Title="✨ Astrael • Thủ Vệ Tận Cùng Bức Màn", Pos=Vector3.new(-8,262.2,-5792), FloorY=260.0, Col=Color3.fromRGB(215,115,255)},
		{Name="NPC_CryonCitadelSentinel", Asset="Lyra", Title="❄ Chỉ Huy Tiền Tuyến • Cryon Citadel Vanguard", Pos=Vector3.new(2492,48.5,-36), FloorY=46.3, Col=Color3.fromRGB(115,240,255)},
		{Name="NPC_NoxarThroneKeeper", Asset="Chronos", Title="🟣 Chronos • Hộ Pháp Ngai Vàng Hư Không", Pos=Vector3.new(-2444,68.2,-22), FloorY=66.0, Col=Color3.fromRGB(215,115,255)},
	}
	for _,rn in ipairs(regionalNPCs) do
		if W.SnapToOpenGround then
			local snappedPos,snappedFY=W.SnapToOpenGround(rn.Pos,rn.FloorY,2.2)
			rn.Pos=snappedPos
			rn.FloorY=snappedFY
		end
		local rm=Instance.new("Model")
		rm.Name=rn.Name
		rm.Parent=worldObjects
		local rBody=W.Part(rm,"Body",Vector3.new(2.2,4.6,1.8),rn.Pos,rn.Col,Enum.Material.Metal)
		rBody.Transparency=1
		rBody.CanCollide=false
		rm.PrimaryPart=rBody
		rm:SetAttribute("NPCId",rn.Asset)
		rm:SetAttribute("VisualAsset",rn.Asset)
		rm:SetAttribute("NPCFloorY",rn.FloorY)

		local rbill=Instance.new("BillboardGui")
		rbill.Size=UDim2.fromOffset(250,44)
		rbill.StudsOffset=Vector3.new(0,4.8,0)
		rbill.AlwaysOnTop=false rbill.MaxDistance=50
		rbill.Parent=rBody
		local rtl=Instance.new("TextLabel")
		rtl.Size=UDim2.fromScale(1,1)
		rtl.BackgroundTransparency=1
		rtl.Font=Enum.Font.GothamBlack
		rtl.TextSize=14
		rtl.TextColor3=rn.Col
		rtl.TextStrokeTransparency=0.2
		rtl.Text=rn.Title
		rtl.Parent=rbill

		local rprompt=Instance.new("ProximityPrompt")
		rprompt.ActionText="Trò Chuyện & Nhận Tiếp Tế"
		rprompt.ObjectText=rn.Title
		rprompt.MaxActivationDistance=14
		rprompt.HoldDuration=0
		rprompt.Parent=rBody
		rprompt.RequiresLineOfSight=false
		rprompt.Style=Enum.ProximityPromptStyle.Default
		rBody:SetAttribute("InteractableId",rn.Name)
		W.Interactions[rn.Name]=rBody
		rprompt.Triggered:Connect(function(p)
			rm:SetAttribute("NPCTalkAt",os.clock())
			local profile=D.Get(p)
			if profile then
				profile.Gold=(profile.Gold or 0)+500
				profile.CoreShards=(profile.CoreShards or 0)+50
				G.SendDialogue(p,rn.Title,"ĐỒNG MINH VIỄN CHINH","Chào chiến binh Skyborn! Ta đã tiếp tế cho ngươi +500 Gold và +50 Core Shards. Hãy kiểm tra Trái Ác Quỷ [G] hoặc Lò Rèn [H] trước khi khiêu chiến Boss đảo này!","Mở Trái Ác Quỷ [G]","OpenScreen:Fruits")
				G.Sync(p)
			end
		end)
	end

	-- Zone 1: Sky Hub Nexus — Clean Plaza (Hero Class & Fruit selection handled via UI [K] / [G] and Zioles Gacha NPC)
	local naturalFolder=Instance.new("Folder")
	naturalFolder.Name="NaturalFruits"
	naturalFolder.Parent=worldObjects
	local fruitTrees={}
	for idx,ft in ipairs(fruitTrees) do
		local tm=Instance.new("Model")
		tm.Name="AncientAetherTree_"..idx
		tm.Parent=worldObjects
		local tpos=ft.Pos
		local treeAnchor=W.Part(tm,"Body",Vector3.new(4,8,4),tpos,ft.Color,Enum.Material.Neon)
		treeAnchor.Transparency=1
		treeAnchor.CanCollide=true
		tm.PrimaryPart=treeAnchor
		tm:SetAttribute("NPCId","AncientAetherFruitTrees")
		tm:SetAttribute("VisualAsset","AncientAetherFruitTrees")
		tm:SetAttribute("ShowcaseScale",1.8)
		tm:SetAttribute("NPCFloorY",ft.FloorY)

		local fruitCfg=getFruitCfg(ft.FruitId)
		local fName=fruitCfg and fruitCfg.Name or ft.FruitId
		local fbill=Instance.new("BillboardGui")
		fbill.Size=UDim2.fromOffset(240,44)
		fbill.StudsOffset=Vector3.new(0,7.5,0)
		fbill.AlwaysOnTop=false fbill.MaxDistance=50
		fbill.Parent=treeAnchor
		local ftl=Instance.new("TextLabel")
		ftl.Size=UDim2.fromScale(1,1)
		ftl.BackgroundTransparency=1
		ftl.Font=Enum.Font.GothamBlack
		ftl.TextSize=14
		ftl.TextColor3=ft.Color
		ftl.TextStrokeTransparency=0.2
		ftl.Text="🌳 Cổ Thụ Trái Aether • "..fName
		ftl.Parent=fbill

		local collectedUntil=0
		local fprompt=Instance.new("ProximityPrompt")
		fprompt.ActionText="Nhặt Trái Aether"
		fprompt.ObjectText=fName
		fprompt.MaxActivationDistance=15
		fprompt.HoldDuration=0
		fprompt.Parent=treeAnchor
		fprompt.Triggered:Connect(function(p)
			local now=os.clock()
			if now<collectedUntil then
				G.Notify(p,"Cây Cổ Thụ đang kết tinh Trái Aether mới ("..math.ceil(collectedUntil-now).."s)!")
				return
			end
			local profile=D.Get(p)
			if not profile then return end
			ensureProfileFields(profile)
			collectedUntil=now+45
			profile.StoredFruits[ft.FruitId]=(profile.StoredFruits[ft.FruitId] or 0)+1
			G.Notify(p,"🍏 Bạn đã nhặt được Trái Năng Lượng: "..fName.."!")
			G.Sync(p)
		end)
	end
end

function G.Character(p,ch)
	local respawnPos=p:GetAttribute("RespawnPos")
	local respawnRealm=p:GetAttribute("RespawnRealm") or "GoldenSky"
	p:SetAttribute('CurrentRealm',typeof(respawnPos)=="Vector3" and respawnRealm or 'GoldenSky')
	local h=ch:WaitForChild("Humanoid",10) local r=ch:WaitForChild("HumanoidRootPart",10)
	local profile=D.Get(p)
	if not h or not r or not profile then return end
	ensureProfileFields(profile)
	ch:SetAttribute("HakiAura",profile.Haki and profile.Haki.Aura==true)
	ch:SetAttribute("HakiInstinct",profile.Haki and profile.Haki.Instinct==true)
	ch:SetAttribute("RaceV4",profile.RaceV4Active and (profile.Race or "Skyborn") or "")
	ch:SetAttribute("FruitTransform","")
	h.MaxHealth=G.Stats(p).HP h.Health=h.MaxHealth h.WalkSpeed=C.Classes[profile.ClassId].Speed h.BreakJointsOnDeath=false
	ch:SetAttribute("GuardianShieldUntil",0)
	local rt=G.Runtime[p] rt.Stamina=100 rt.ShieldUntil=0 rt.InvincibleUntil=os.clock()+2
	local spawnTarget=typeof(respawnPos)=="Vector3" and (respawnPos+Vector3.new(0,3,0)) or C.Spawn
	G.Teleport(p,spawnTarget)
	G.SyncCompanions(p)
	Cosmetics.Guardian(ch)
	local appearanceDeadline=os.clock()+8
	while p.Character==ch and not p:HasAppearanceLoaded() and os.clock()<appearanceDeadline do task.wait(.1) end
	if p.Character~=ch or not D.Get(p) then return end
	local hand=ch:FindFirstChild("RightHand") or ch:FindFirstChild("Right Arm") or ch:WaitForChild(h.RigType==Enum.HumanoidRigType.R15 and "RightHand" or "Right Arm",8)
	if hand then
		local blade=Instance.new("Part") blade.Name="SkybornBlade" blade.Size=Vector3.new(.45,4,.25) blade.Color=Color3.fromRGB(255,213,97) blade.Material=Enum.Material.Metal blade.CanCollide=false blade.CanTouch=false blade.Massless=true blade.Transparency=1 blade.CFrame=hand.CFrame*CFrame.new(0,-1.8,0) blade.Parent=ch
		local weld=Instance.new("WeldConstraint") weld.Part0=hand weld.Part1=blade weld.Parent=blade
	end
	local torso=ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso") or ch:WaitForChild(h.RigType==Enum.HumanoidRigType.R15 and "UpperTorso" or "Torso",8)
	if torso then
		local function costume(name,size,offset,color)
			local part=Instance.new("Part") part.Name=name part.Size=size part.Color=color part.Material=Enum.Material.SmoothPlastic part.CanCollide=false part.CanTouch=false part.Massless=true part.Transparency=1 part.CFrame=torso.CFrame*offset part.Parent=ch
			local weld=Instance.new("WeldConstraint") weld.Part0=torso weld.Part1=part weld.Parent=part
		end
		costume("GuardianBreastplate",Vector3.new(2.1,1.6,.35),CFrame.new(0,0,-.6),Color3.fromRGB(32,33,39))
		costume("GuardianCrest",Vector3.new(.25,1.35,.15),CFrame.new(0,0,-.84),Color3.fromRGB(230,180,64))
		costume("CrimsonCape",Vector3.new(2.1,3.2,.15),CFrame.new(0,-.75,.75)*CFrame.Angles(.15,0,0),Color3.fromRGB(132,28,40))
	end
	Cosmetics.Guardian(ch)
	if hand then Cosmetics.Weapon(ch,hand,D.Get(p).Weapon~=nil) end
end
function G.Join(p)
	p:SetAttribute('CurrentRealm','GoldenSky')
	local profile=D.Load(p) if not profile then return end
	ensureProfileFields(profile)
	G.Runtime[p]={Stamina=100,Energy=0,ShieldUntil=0,InvincibleUntil=0,ActionUntil=0,LastAttack=0,Combo=0,LastHurt=0,NextInstinctRegen=os.clock()+5,Requests={},Cooldowns={},Companions={},Safe=C.Spawn,MoveAt=os.clock()}
	G.UpdatePlayerPortalCompass(p,profile.CurrentWorldOrder or 1)
	p.CharacterAdded:Connect(function(ch) G.Character(p,ch) end)
	if p.Character then task.spawn(G.Character,p,p.Character) end
end
function G.Start()
	W.Build()
	G.EnsureWorld()
	D.Start()
	for _,obj in pairs(W.Interactions) do
		if obj:FindFirstChildOfClass("ProximityPrompt") and not G.Chests[obj.Name] and not G.Shrines[obj.Name] then
			obj.ProximityPrompt.Triggered:Connect(function(p) G.Interact(p,obj.Name) end)
		end
	end
	R.CombatRequest.OnServerEvent:Connect(function(p,payload)
		if type(payload)~="table" then return end
		if payload.action=="Attack" or payload.action=="Heavy" or payload.action=="Dodge" or payload.action=="Dash" then
			G.Action(p,payload.action)
		elseif payload.action=="UsePotion" then
			G.Equipment(p,payload)
		end
	end)
	R.AbilityRequest.OnServerEvent:Connect(function(p,payload)
		if type(payload)~="table" then return end
		local id=payload.skillId or payload.action
		if payload.action=="SlotMove" or payload.key or id=="Z" or id=="X" or id=="C" or id=="V" or id=="F" then
			G.UseSlotMove(p,payload.key or payload.skillId)
			return
		elseif payload.action=="ToggleAura" or id=="ToggleAura" then
			G.Equipment(p,{action="ToggleAura"})
			return
		elseif payload.action=="ToggleInstinct" or id=="ToggleInstinct" then
			G.Equipment(p,{action="ToggleInstinct"})
			return
		elseif payload.action=="ConquerorBurst" or id=="ConquerorBurst" then
			G.Equipment(p,{action="ConquerorBurst"})
			return
		elseif payload.action=="ActivateRaceV4" or id=="ActivateRaceV4" then
			G.Equipment(p,{action="ActivateRaceV4"})
			return
		end
		if id=="SkySlash" or id=="GuardianShield" or id=="JudgmentStrike" or id=="CelestialAegis"
			or id=="ArcCut" or id=="FlashStep" or id=="StormBlitz" or id=="ThunderJudgement"
			or id=="FrostBolt" or id=="ManaBarrier" or id=="ArcaneComet" or id=="AstralCataclysm" then
			G.Action(p,id)
		end
	end)
	R.InteractRequest.OnServerEvent:Connect(function(p,payload)
		if type(payload)=="table" then
			G.Interact(p,payload.interactableId or payload.chestId or payload.id)
		end
	end)
	R.EquipmentRequest.OnServerEvent:Connect(G.Equipment)
	R.AppearanceRequest.OnServerEvent:Connect(G.ChooseAppearance)
	Players.PlayerAdded:Connect(G.Join)
	Players.PlayerRemoving:Connect(function(p)
		local rt=G.Runtime[p]
		if rt then
			for _,comp in pairs(rt.Companions or {}) do
				if comp.Model and comp.Model.Parent then comp.Model:Destroy() end
			end
			G.Runtime[p]=nil
		end
		D.Release(p)
		for _,e in ipairs(G.Enemies) do e.Contributors[p]=nil if e.Party then e.Party[p]=nil end end
	end)
	for _,p in ipairs(Players:GetPlayers()) do task.spawn(G.Join,p) end

	-- Sea 1: Golden Sky (7 Worlds/Islands: SkyHub, ZiolesGachaShrine, AetherShrines, WestGarden, LumenPlaza, AureonCitadel, SunshardSanctuary)
	-- 1. SkyHub (Training Courtyard deckY = 40.0)
	for i=1,3 do G.SpawnEnemy("TrainingDrone",Vector3.new(-103+(i-1)*12,42.5,61),false) end
	for i=1,2 do G.SpawnEnemy("SkyPirate",Vector3.new(-98+(i-1)*14,42.5,48),false) end
	G.SpawnEnemy("SkyHubWatchCommander",Vector3.new(-91,42.5,56),false)
	-- 2. ZiolesGachaShrine (deckY = 38.0, verified flat plaza dx=±4.5, dz=-4.5..+4.9)
	G.SpawnEnemy("TrainingDrone",Vector3.new(-224.5,40.5,261.8),false)
	G.SpawnEnemy("TrainingDrone",Vector3.new(-215.5,40.5,261.8),false)
	G.SpawnEnemy("ShrineGuardianBoss",Vector3.new(-220.0,40.5,255.5),false)
	-- 3. AetherShrines (deckY = 38.0, verified flat plaza dx=±5.7, dz=±3.2..6.5)
	G.SpawnEnemy("CorruptedGuard",Vector3.new(54.3,40.5,256.8),false)
	G.SpawnEnemy("CorruptedGuard",Vector3.new(65.7,40.5,256.8),false)
	G.SpawnEnemy("AetherArchonBoss",Vector3.new(60.0,40.5,263.5),false)
	-- 4. WestGarden Pirate Bastion (deckY = 48.0, verified flat courtyard dx=±8.9, dz=±8.9)
	G.SpawnEnemy("SkyPirate",Vector3.new(-529.0,50.5,31.0),false)
	G.SpawnEnemy("SkyPirate",Vector3.new(-511.0,50.5,31.0),false)
	G.SpawnEnemy("SkyPirate",Vector3.new(-529.0,50.5,49.0),false)
	G.SpawnEnemy("PirateCaptainVance",Vector3.new(-520.0,50.5,28.0),false)
	-- 5. LumenPlaza (deckY = 40.0)
	for i=1,3 do G.SpawnEnemy("CorruptedGuard",Vector3.new(-20+(i-1)*20,42.5,8),false) end
	G.SpawnEnemy("SunshardRoyalGuard",Vector3.new(-14,42.5,14),false)
	G.SpawnEnemy("SunshardRoyalGuard",Vector3.new(14,42.5,14),false)
	G.SpawnEnemy("GoldenKnight",Vector3.new(0,42.5,-10),false)
	-- 6. BossForecourt & AureonCitadel (deckY = 40.0 / 48.0)
	for i=1,3 do G.SpawnEnemy("LightArcher",Vector3.new(-18+(i-1)*18,42.5,-27),false) end
	G.SpawnEnemy("AureonSentinel",Vector3.new(0,50.5,-104),false)
	-- 7. SunshardSanctuary (deckY = 88.0, verified flat plaza dx=±14, dz=±14..-19)
	G.SpawnEnemy("SunshardTemplar",Vector3.new(526.0,90.5,-26.0),false)
	G.SpawnEnemy("SunshardTemplar",Vector3.new(554.0,90.5,-26.0),false)
	G.SpawnEnemy("SunshardRoyalGuard",Vector3.new(526.0,90.5,-54.0),false)
	G.SpawnEnemy("SunshardRoyalGuard",Vector3.new(554.0,90.5,-54.0),false)
	G.SpawnEnemy("SolarHighPriestBoss",Vector3.new(540.0,90.5,-59.0),false)

	-- Sea 2: Frozen Cyber (5 Worlds/Islands: FrozenCyber/CryonArena, CyberportCafe, PermafrostGarrison, MicrochipRaidLab, GlacialWreckage)
	-- 8. FrozenCyber & CryonArena (deckY = 44.0 / 51.0)
	G.SpawnEnemy("FrostDrone",Vector3.new(2398,46.5,72),false)
	G.SpawnEnemy("FrostDrone",Vector3.new(2414,46.5,58),false)
	G.SpawnEnemy("OrderCyborg",Vector3.new(2406,46.5,52),false)
	G.SpawnEnemy("CryoGuard",Vector3.new(2486,47.5,12),false)
	G.SpawnEnemy("CryoGuard",Vector3.new(2514,47.5,12),false)
	G.SpawnEnemy("CyberArcher",Vector3.new(2488,47.5,-16),false)
	G.SpawnEnemy("CyberArcher",Vector3.new(2512,47.5,-16),false)
	G.SpawnEnemy("CryonPrime",Vector3.new(2500,53.5,-104),false)
	-- 9. CyberportCafe (deckY = 46.0, verified flat plaza dx=±7.8, dz=±7.8)
	G.SpawnEnemy("CyberMercenary",Vector3.new(2012.2,48.5,352.2),false)
	G.SpawnEnemy("CyberMercenary",Vector3.new(2027.8,48.5,352.2),false)
	G.SpawnEnemy("FrostAutomaton",Vector3.new(2012.2,48.5,367.8),false)
	G.SpawnEnemy("FrostAutomaton",Vector3.new(2027.8,48.5,367.8),false)
	G.SpawnEnemy("CyberSyndicateBoss",Vector3.new(2020.0,48.5,371.0),false)
	-- 10. PermafrostGarrison (deckY = 56.0, verified flat plaza dx=±7.1, dz=±7.1)
	G.SpawnEnemy("CryoGuard",Vector3.new(1952.9,58.5,-172.9),false)
	G.SpawnEnemy("CryoGuard",Vector3.new(1967.1,58.5,-172.9),false)
	G.SpawnEnemy("CyberArcher",Vector3.new(1952.9,58.5,-187.1),false)
	G.SpawnEnemy("CyberArcher",Vector3.new(1967.1,58.5,-187.1),false)
	G.SpawnEnemy("PermafrostWardenBoss",Vector3.new(1960.0,58.5,-190.0),false)
	-- 11. MicrochipRaidLab (deckY = 68.0, verified flat plaza dx=±9.2, dz=±9.2)
	G.SpawnEnemy("MechaDrone",Vector3.new(3030.8,70.5,129.2),false)
	G.SpawnEnemy("MechaDrone",Vector3.new(3049.2,70.5,129.2),false)
	G.SpawnEnemy("FrostAutomaton",Vector3.new(3030.8,70.5,110.8),false)
	G.SpawnEnemy("FrostAutomaton",Vector3.new(3049.2,70.5,110.8),false)
	G.SpawnEnemy("OrderCyborgBoss",Vector3.new(3040.0,70.5,107.0),false)
	-- 12. GlacialWreckage (deckY = 44.0, verified wide flat ice shelf dx=+16..+26, dz=-15..+26)
	G.SpawnEnemy("ArcticCorsair",Vector3.new(3005.0,46.5,-455.0),false)
	G.SpawnEnemy("ArcticCorsair",Vector3.new(3006.0,46.5,-424.0),false)
	G.SpawnEnemy("GlacialSniper",Vector3.new(2996.0,46.5,-414.0),false)
	G.SpawnEnemy("GlacialSniper",Vector3.new(2954.0,46.5,-424.0),false)
	G.SpawnEnemy("SkySeaBeast",Vector3.new(3008.0,46.5,-440.0),false)

	-- Sea 3: Shadow Realm (5 Worlds/Islands: ShadowRealm/NoxarArena, CastleOnTheVoid, UmbralSanctum, TempleOfTheCore, LeviathanAbyss)
	-- 13. ShadowRealm & NoxarArena (deckY = 53.4 / 66.0)
	G.SpawnEnemy("VoidPirate",Vector3.new(-2576,55.9,112),false)
	G.SpawnEnemy("VoidRaider",Vector3.new(-2562,55.9,112),false)
	G.SpawnEnemy("AbyssalKnight",Vector3.new(-2495,59.5,42),false)
	G.SpawnEnemy("ShadowArcher",Vector3.new(-2508,59.5,24),false)
	G.SpawnEnemy("UmbralBowman",Vector3.new(-2482,59.5,24),false)
	G.SpawnEnemy("AbyssalSovereignDragon",Vector3.new(-2385,68.5,-68),false)
	G.SpawnEnemy("Noxar",Vector3.new(-2405,68.5,-55),false)
	-- 14. CastleOnTheVoid (deckY = 56.0, verified flat plaza dx=±8.3, dz=±8.3)
	G.SpawnEnemy("VoidRaider",Vector3.new(-3168.3,58.5,268.3),false)
	G.SpawnEnemy("VoidRaider",Vector3.new(-3151.7,58.5,268.3),false)
	G.SpawnEnemy("AbyssalKnight",Vector3.new(-3168.3,58.5,251.7),false)
	G.SpawnEnemy("AbyssalKnight",Vector3.new(-3151.7,58.5,251.7),false)
	G.SpawnEnemy("VoidCastellanBoss",Vector3.new(-3160.0,58.5,248.3),false)
	-- 15. UmbralSanctum (deckY = 60.0, verified flat plaza dx=±14.2, dz=±14.2)
	G.SpawnEnemy("UmbralBowman",Vector3.new(-1934.2,62.5,254.2),false)
	G.SpawnEnemy("UmbralBowman",Vector3.new(-1905.8,62.5,254.2),false)
	G.SpawnEnemy("ShadowSpecter",Vector3.new(-1934.2,62.5,225.8),false)
	G.SpawnEnemy("ShadowSpecter",Vector3.new(-1905.8,62.5,225.8),false)
	G.SpawnEnemy("UmbralArchfiendBoss",Vector3.new(-1900.0,62.5,240.0),false)
	-- 16. TempleOfTheCore (deckY = 96.0, verified flat plaza dx=±10, dz=±8)
	G.SpawnEnemy("ShadowSpecter",Vector3.new(-3170.0,98.5,-312.0),false)
	G.SpawnEnemy("ShadowSpecter",Vector3.new(-3150.0,98.5,-312.0),false)
	G.SpawnEnemy("AbyssalDreadknight",Vector3.new(-3170.0,98.5,-324.0),false)
	G.SpawnEnemy("AbyssalDreadknight",Vector3.new(-3150.0,98.5,-324.0),false)
	G.SpawnEnemy("SoulReaperRift",Vector3.new(-3160.0,98.5,-326.0),false)
	-- 17. LeviathanAbyss (deckY = 68.0, verified flat terrace dx=-26..+26, dz=+16..+26)
	G.SpawnEnemy("ShadowSpecter",Vector3.new(-2566.0,70.5,-664.0),false)
	G.SpawnEnemy("ShadowSpecter",Vector3.new(-2514.0,70.5,-664.0),false)
	G.SpawnEnemy("TerrorSkyShark",Vector3.new(-2556.0,70.5,-654.0),false)
	G.SpawnEnemy("TerrorSkyShark",Vector3.new(-2524.0,70.5,-654.0),false)
	G.SpawnEnemy("AbyssalDragonHybrid",Vector3.new(-2552.0,70.5,-662.0),false)
	G.SpawnEnemy("AbyssalDragonHybrid",Vector3.new(-2528.0,70.5,-662.0),false)
	G.SpawnEnemy("AbyssalLeviathan",Vector3.new(-2540.0,70.5,-658.0),false)

	-- Expansion Realms 4-8 (5 Worlds: VerdantCrown, EmberforgeWastes, AbyssalTides, ChronosBastion, VeilsEnd)
	-- 18. VerdantCrown (deckY = 120.0, UmbralCrystalSanctumForest clone dx=±14.2, dz=±14.2)
	G.SpawnEnemy("UmbralBowman",Vector3.new(-14.2,122.5,-2385.8),false)
	G.SpawnEnemy("UmbralBowman",Vector3.new(14.2,122.5,-2385.8),false)
	G.SpawnEnemy("ShadowSpecter",Vector3.new(-14.2,122.5,-2414.2),false)
	G.SpawnEnemy("ShadowSpecter",Vector3.new(14.2,122.5,-2414.2),false)
	G.SpawnEnemy("Sylvaris",Vector3.new(20.0,122.5,-2400.0),false)
	-- 19. EmberforgeWastes (deckY = 120.0, WestGardenPirateBastion clone dx=±8.9, dz=±8.9)
	G.SpawnEnemy("SunshardTemplar",Vector3.new(2391.1,122.5,-2391.1),false)
	G.SpawnEnemy("SunshardTemplar",Vector3.new(2408.9,122.5,-2391.1),false)
	G.SpawnEnemy("GoldenKnight",Vector3.new(2391.1,122.5,-2408.9),false)
	G.SpawnEnemy("GoldenKnight",Vector3.new(2408.9,122.5,-2408.9),false)
	G.SpawnEnemy("Ignivar",Vector3.new(2400.0,122.5,-2387.4),false)
	-- 20. AbyssalTides (deckY = 120.0, MirageSkyIslandLeviathanAbyss clone dx=-26..+26, dz=+16..+26)
	G.SpawnEnemy("ArcticCorsair",Vector3.new(-2426.0,122.5,-2384.0),false)
	G.SpawnEnemy("ArcticCorsair",Vector3.new(-2374.0,122.5,-2384.0),false)
	G.SpawnEnemy("TerrorSkyShark",Vector3.new(-2416.0,122.5,-2374.0),false)
	G.SpawnEnemy("TerrorSkyShark",Vector3.new(-2384.0,122.5,-2374.0),false)
	G.SpawnEnemy("Nerith",Vector3.new(-2400.0,122.5,-2378.0),false)
	-- 21. ChronosBastion (deckY = 180.0, TempleOfTheCoreRaceV4 clone dx=±10, dz=±8)
	G.SpawnEnemy("MechaDrone",Vector3.new(-10.0,182.5,-4192.0),false)
	G.SpawnEnemy("MechaDrone",Vector3.new(10.0,182.5,-4192.0),false)
	G.SpawnEnemy("CryoVanguard",Vector3.new(-10.0,182.5,-4204.0),false)
	G.SpawnEnemy("CryoVanguard",Vector3.new(10.0,182.5,-4204.0),false)
	G.SpawnEnemy("Aion",Vector3.new(0.0,182.5,-4206.0),false)
	-- 22. VeilsEnd (deckY = 260.0, CastleOnTheVoidMansion clone dx=±8.3, dz=±8.3)
	G.SpawnEnemy("ShadowSpecter",Vector3.new(-8.3,262.5,-5791.7),false)
	G.SpawnEnemy("ShadowSpecter",Vector3.new(8.3,262.5,-5791.7),false)
	G.SpawnEnemy("AbyssalDreadknight",Vector3.new(-8.3,262.5,-5808.3),false)
	G.SpawnEnemy("AbyssalDreadknight",Vector3.new(8.3,262.5,-5808.3),false)
	G.SpawnEnemy("AbyssalDragonHybrid",Vector3.new(-11.7,262.5,-5800.0),false)
	G.SpawnEnemy("AbyssalDragonHybrid",Vector3.new(11.7,262.5,-5800.0),false)
	G.SpawnEnemy("Veyr",Vector3.new(0.0,262.5,-5811.7),false)

	task.spawn(function()
		local sync=0 local previous=os.clock()
		while true do
			task.wait(.04) local now=os.clock() local dt=math.min(now-previous,.25) previous=now sync+=dt
			local playerRoots={}
			for p in pairs(G.Runtime) do
				local pr=root(p)
				if pr then table.insert(playerRoots,pr.Position) end
			end
			for i=#G.Enemies,1,-1 do
				local e=G.Enemies[i]
				if not e.Alive or not e.Model.Parent then
					table.remove(G.Enemies,i)
				else
					local isNear=false
					local bpos=e.Body and e.Body.Position or e.Home
					for _,ppos in ipairs(playerRoots) do
						if (bpos-ppos).Magnitude<=220 then
							isNear=true
							break
						end
					end
					if isNear or e==G.Boss or e.Returning or e.State=="Chase" or e.State=="Attack" then
						local eDt=now-(e.LastTickAt or (now-dt))
						e.LastTickAt=now
						G.TickEnemy(e,math.min(eDt,.25))
					elseif now>=(e.NextFarTick or 0) then
						local eDt=now-(e.LastTickAt or (now-.4))
						e.LastTickAt=now
						e.NextFarTick=now+.4
						G.TickEnemy(e,math.min(eDt,.5))
					end
				end
			end
			G.TickCompanions(dt)
			for p,rt in pairs(G.Runtime) do
				local r,h=root(p) local profile=D.Get(p)
				if r and profile then
					ensureProfileFields(profile)
					if now>=(rt.NextInstinctRegen or 0) then
						rt.NextInstinctRegen=now+5
						if profile.Haki then
							profile.Haki.InstinctDodges=math.min(8,(profile.Haki.InstinctDodges or 8)+1)
						end
					end
					if now>=(rt.JumpPadUntil or 0) then
						local elapsed=now-rt.MoveAt local delta=r.Position-rt.Safe
						local horizontal=Vector3.new(delta.X,0,delta.Z).Magnitude
						if not finiteVector(r.Position) or horizontal>math.max(48,elapsed*140) then G.Teleport(p,rt.Safe)
						else rt.Safe=r.Position rt.MoveAt=now end
						if now>=(rt.NextVoidCheck or 0) then
							rt.NextVoidCheck=now+.2
							local gy=safeGroundY(r.Position,r.Position.Y-3.5)
							if math.abs(r.Position.Y-gy)<=10 and r.Position.Y>-10 then
								rt.LastGroundedPos=Vector3.new(r.Position.X,gy+3.5,r.Position.Z)
							elseif r.Position.Y<-15 or (rt.LastGroundedPos and r.Position.Y<(rt.LastGroundedPos.Y-65)) then
								local cpNode=C.FastTravel[profile.Checkpoint] or C.FastTravel.GoldenSky
								local rescue=rt.LastGroundedPos or (cpNode and cpNode.Pos) or C.Spawn
								G.Teleport(p,rescue)
								G.Notify(p,"Void Rescue: Đã đưa bạn trở lại mặt sàn đảo mây an toàn!")
							end
						end
					else
						rt.Safe=r.Position rt.MoveAt=now
					end
					if now>=(rt.JumpPadCooldown or 0) then
						for _,pad in ipairs(G.JumpPads) do
							if distance(r.Position,pad.Start)<=5.5 then
								rt.JumpPadCooldown=now+2.5
								G.LaunchPlayer(p,r.Position,pad.Target,pad.Arc,pad.Duration)
								break
							end
						end
					end
					if now>=(rt.ShrineTouchCooldown or 0) then
						for _,sh in pairs(G.Shrines) do
							if distance(r.Position,sh.Pos)<=8 then
								rt.ShrineTouchCooldown=now+12
								G.ActivateShrine(p,sh)
								break
							end
						end
					end
					if now>=(rt.PortalTouchCooldown or 0) and G.WorldPortals then
						for _,gate in pairs(G.WorldPortals) do
							if distance(r.Position,gate.CenterPos)<=4.6 then
								G.EnterWorldPortal(p,gate)
								break
							end
						end
					end
					rt.Stamina=math.min(100,rt.Stamina+17*dt)
					if now-rt.LastHurt>7 then h.Health=math.min(h.MaxHealth,h.Health+3*dt) end
				end
				if sync>=.3 then G.Sync(p) end
			end
			if sync>=.3 then sync=0 end
		end
	end)
	print("[SKYBREAK] Grand Sky Seas v11 initialized. Studio persistence:",C.StudioPersistence)
end
return G
