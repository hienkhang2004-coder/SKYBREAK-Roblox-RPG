-- Modular Static Fallback Tables & Initial World Enemy Spawn Manifest for GameService
local S = {}

S.BLENDER_ENEMIES = {
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

S.FALLBACK_FRUITS = {
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

S.FALLBACK_STYLES = {
	SkybornCombat={Id="SkybornCombat", Name="Võ Thuật Skyborn (Skyborn Combat)", Element="Sky"},
	ElectricClaw={Id="ElectricClaw", Name="Lôi Trảo Cực Tốc (Electric Claw)", Element="Lightning"},
	GlacialKarate={Id="GlacialKarate", Name="Băng Hà Quyền (Glacial Sharkman Karate)", Element="Frost"},
	DragonTalon={Id="DragonTalon", Name="Long Trảo Hỏa (Dragon Talon)", Element="Sky"},
	GodhumanSkyborn={Id="GodhumanSkyborn", Name="Thần Quyền (Godhuman Skyborn)", Element="Sky"},
	SanguineVoidArt={Id="SanguineVoidArt", Name="Huyết Hư Không Quyền (Sanguine Void Art)", Element="Void"},
}

S.FALLBACK_GUNS = {
	soul_guitar_void={Id="soul_guitar_void", Name="Đàn Linh Hồn Hư Không (Soul Guitar)", Element="Void"},
	kabucha_wind={Id="kabucha_wind", Name="Ná Thần Phong (Kabucha)", Element="Sky"},
	bizarre_rifle_cyber={Id="bizarre_rifle_cyber", Name="Pháo Quang Tử Băng (Cyber Rifle)", Element="Frost"},
}

S.FALLBACK_FAST_TRAVEL = {
	SkyHub={Id="SkyHub", Name="Sky 1 • Đảo Khởi Đầu (Sky Hub Nexus)", Realm="GoldenSky", Pos=Vector3.new(-317.4,50.5,527.8)},
	GoldenSky={Id="GoldenSky", Name="Sky 1 • Bầu Trời Hoàng Kim (Golden Sky Hub)", Realm="GoldenSky", Pos=Vector3.new(-313.9,50.5,210.4)},
	QuestCheckpoint={Id="QuestCheckpoint", Name="Sky 1 • Sân Tập Khởi Nguyên (Quest Checkpoint)", Realm="GoldenSky", Pos=Vector3.new(-313.9,50.5,210.4)},
	ZiolesGachaShrine={Id="ZiolesGachaShrine", Name="Sky 1 • Điện Thờ Zioles Gacha (Zioles Shrine)", Realm="GoldenSky", Pos=Vector3.new(-560,52.5,996)},
	AetherShrines={Id="AetherShrines", Name="Sky 1 • Đài Điện Thờ Aether (Aether Shrine)", Realm="GoldenSky", Pos=Vector3.new(340,52.5,996)},
	WestGarden={Id="WestGarden", Name="Sky 1 • Pháo Đài Không Tặc Vườn Tây (West Garden Bastion)", Realm="GoldenSky", Pos=Vector3.new(-2800,50.5,-65)},
	LumenPlaza={Id="LumenPlaza", Name="Sky 1 • Quảng Trường Ánh Sáng (Lumen Plaza)", Realm="GoldenSky", Pos=Vector3.new(0,50.5,65)},
	SunshardSanctuary={Id="SunshardSanctuary", Name="Golden Sky • Thánh Địa Thái Dương (Sunshard Sanctuary)", Realm="GoldenSky", Pos=Vector3.new(2800,50.5,-55)},
	BossForecourt={Id="BossForecourt", Name="Sky 1 • Tháp Phán Quyết (Aureon Citadel)", Realm="GoldenSky", Pos=Vector3.new(0,50.5,-285)},
	FrozenCyber={Id="FrozenCyber", Name="Sky 2 • Cảng Băng Giá (Cyberport Cafe Hub)", Realm="FrozenCyber", Pos=Vector3.new(11620.5,50.9,534.8)},
	CyberportCafe={Id="CyberportCafe", Name="Sky 2 • Quán Cà Phê Giao Dịch (Cyberport Café)", Realm="FrozenCyber", Pos=Vector3.new(9400,50.9,1785)},
	PermafrostGarrison={Id="PermafrostGarrison", Name="Sky 2 • Pháo Đài Tuyết (Permafrost Garrison Fortress)", Realm="FrozenCyber", Pos=Vector3.new(9400,50.9,-2055)},
	MicrochipRaidLab={Id="MicrochipRaidLab", Name="Frozen Cyber • Phòng Thí Nghiệm Đột Kích (Raid Lab)", Realm="FrozenCyber", Pos=Vector3.new(14600,50.9,1785)},
	GlacialWreckage={Id="GlacialWreckage", Name="Frozen Cyber • Xác Tàu Băng Cổ Đại (Glacial Wreckage)", Realm="FrozenCyber", Pos=Vector3.new(14600,50.9,-1812)},
	GlacialDangerSea={Id="GlacialDangerSea", Name="Frozen Cyber • Xác Tàu Băng Cổ Đại (Glacial Danger Sea)", Realm="FrozenCyber", Pos=Vector3.new(14600,50.9,-1812)},
	CryonArena={Id="CryonArena", Name="Sky 2 • Ngai Vàng Băng Đế (Cryon Citadel)", Realm="FrozenCyber", Pos=Vector3.new(12000,50.9,-285)},
	ShadowRealm={Id="ShadowRealm", Name="Sky 3 • Pháo Đài Hư Không (Shadow Realm Outpost)", Realm="ShadowRealm", Pos=Vector3.new(-12593.4,50.9,414)},
	CastleOnTheVoid={Id="CastleOnTheVoid", Name="Sky 3 • Dinh Thự Hư Không (Castle on the Void Mansion)", Realm="ShadowRealm", Pos=Vector3.new(-14600,50.9,2173.1)},
	UmbralSanctum={Id="UmbralSanctum", Name="Sky 3 • Rừng Tinh Thể Đen (Umbral Crystal Sanctum)", Realm="ShadowRealm", Pos=Vector3.new(-9400,50.9,1815)},
	UmbralCrystalForest={Id="UmbralCrystalForest", Name="Sky 3 • Rừng Tinh Thể Đen (Umbral Crystal Forest)", Realm="ShadowRealm", Pos=Vector3.new(-9400,50.9,1815)},
	TempleOfTheCore={Id="TempleOfTheCore", Name="Shadow Realm • Đền Thờ Thức Tỉnh Tộc V4 (Temple of the Core)", Realm="ShadowRealm", Pos=Vector3.new(-14600,50.9,-1785)},
	LeviathanAbyss={Id="LeviathanAbyss", Name="Sky 3 • Đảo Ảo Ảnh & Vực Thẳm Leviathan (Mirage Abyss)", Realm="ShadowRealm", Pos=Vector3.new(-12000,50.9,-3364.5)},
	NoxarArena={Id="NoxarArena", Name="Sky 3 • Ngai Vàng Hư Không (Noxar Throne)", Realm="ShadowRealm", Pos=Vector3.new(-11672.2,50.9,-110)},
	VerdantCrown={Id="VerdantCrown", Name="Realm 4 • Vương Miện Cổ Thụ (The Verdant Crown)", Realm="VerdantCrown", Pos=Vector3.new(0,170.9,-8985)},
	VerdantWestBough={Id="VerdantWestBough", Name="Realm 4B • Cánh Rừng Tây Cổ Thụ", Realm="VerdantCrown", Pos=Vector3.new(-504.3,170.9,-9110.7)},
	VerdantEastGrove={Id="VerdantEastGrove", Name="Realm 4C • Đảo Rừng Ngọc Bích", Realm="VerdantCrown", Pos=Vector3.new(504.3,170.9,-9110.7)},
	VerdantNorthSpire={Id="VerdantNorthSpire", Name="Realm 4D • Đỉnh Tháp Nhựa Aether", Realm="VerdantCrown", Pos=Vector3.new(0,170.9,-8544.9)},
	EmberforgeWastes={Id="EmberforgeWastes", Name="Realm 5 • Hoang Mạc Lò Rèn Lửa (Emberforge Wastes)", Realm="EmberforgeWastes", Pos=Vector3.new(12000,170.5,-9265)},
	EmberWestFoundry={Id="EmberWestFoundry", Name="Realm 5B • Xưởng Đúc Tây Hỏa", Realm="EmberforgeWastes", Pos=Vector3.new(11606.4,170.5,-9143.5)},
	EmberforgeWestFoundry={Id="EmberforgeWestFoundry", Name="Realm 5B • Xưởng Đúc Tây Hỏa", Realm="EmberforgeWastes", Pos=Vector3.new(11606.4,170.5,-9143.5)},
	EmberEastCaldera={Id="EmberEastCaldera", Name="Realm 5C • Miệng Núi Lửa Đông", Realm="EmberforgeWastes", Pos=Vector3.new(12393.6,170.5,-9143.5)},
	EmberforgeEastCaldera={Id="EmberforgeEastCaldera", Name="Realm 5C • Miệng Núi Lửa Đông", Realm="EmberforgeWastes", Pos=Vector3.new(12393.6,170.5,-9143.5)},
	EmberNorthCitadel={Id="EmberNorthCitadel", Name="Realm 5D • Pháo Đài Sao Nung", Realm="EmberforgeWastes", Pos=Vector3.new(11643.3,170.5,-8708.9)},
	EmberforgeNorthCitadel={Id="EmberforgeNorthCitadel", Name="Realm 5D • Pháo Đài Sao Nung", Realm="EmberforgeWastes", Pos=Vector3.new(11643.3,170.5,-8708.9)},
	AbyssalTides={Id="AbyssalTides", Name="Realm 6 • Thủy Triều Vực Sâu (Abyssal Tides)", Realm="AbyssalTides", Pos=Vector3.new(-12000,170.9,-8964.5)},
	AbyssalWestReef={Id="AbyssalWestReef", Name="Realm 6B • Rạn San Hô Phát Quang", Realm="AbyssalTides", Pos=Vector3.new(-12496.1,170.9,-9077.9)},
	AbyssalEastTrench={Id="AbyssalEastTrench", Name="Realm 6C • Vực Hải Lưu Ngược", Realm="AbyssalTides", Pos=Vector3.new(-11503.9,170.9,-9077.9)},
	AbyssalNorthSpire={Id="AbyssalNorthSpire", Name="Realm 6D • Cung Điện Thủy Triều", Realm="AbyssalTides", Pos=Vector3.new(-12000,170.9,-8561.3)},
	ChronosBastion={Id="ChronosBastion", Name="Realm 7 • Pháo Đài Thời Gian (Chronos Bastion)", Realm="ChronosBastion", Pos=Vector3.new(0,230.9,-13485)},
	ChronosWestDial={Id="ChronosWestDial", Name="Realm 7B • Vòng Tinh Cầu Quá Khứ", Realm="ChronosBastion", Pos=Vector3.new(-512.5,230.9,-13643.5)},
	ChronosEastDial={Id="ChronosEastDial", Name="Realm 7C • Vòng Tinh Cầu Tương Lai", Realm="ChronosBastion", Pos=Vector3.new(512.5,230.9,-13643.5)},
	ChronosNorthSpire={Id="ChronosNorthSpire", Name="Realm 7D • Tháp Niên Đại Vĩnh Hằng", Realm="ChronosBastion", Pos=Vector3.new(0,230.9,-13020.3)},
	VeilsEnd={Id="VeilsEnd", Name="Realm 8 • Tận Cùng Bức Màn (The Veil's End)", Realm="VeilsEnd", Pos=Vector3.new(0,310.9,-17626.9)},
	VeilsWestHorizon={Id="VeilsWestHorizon", Name="Realm 8B • Chân Trời Sự Kiện Tây", Realm="VeilsEnd", Pos=Vector3.new(-487.9,310.9,-18036.9)},
	VeilsEastHorizon={Id="VeilsEastHorizon", Name="Realm 8C • Tinh Vân Sụp Đổ Đông", Realm="VeilsEnd", Pos=Vector3.new(487.9,310.9,-18036.9)},
	VeilsNorthThrone={Id="VeilsNorthThrone", Name="Realm 8D • Ngai Vàng Đấng Kiến Tạo", Realm="VeilsEnd", Pos=Vector3.new(0,310.9,-18265)},
}

S.FALLBACK_ENEMIES = {
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
	Chronovex={Name="AION • PHÁP VƯƠNG THỜI GIAN", VisualAsset="OrderCyborgBoss", Element="Sky", HP=16800, ATK=74, Attack=74, DEF=32, Defense=32, XP=6500, Gold=9000, Range=24, Speed=13, Aggro=70, Leash=85, Boss=true, Drop="CoreEssence"},
	Veyr={Name="VEYR • ĐẤNG KIẾN TẠO ĐẦU TIÊN", VisualAsset="AbyssalSovereignDragon", Element="Void", HP=22000, ATK=85, Attack=85, DEF=36, Defense=36, XP=9000, Gold=15000, Range=30, Speed=12, Aggro=80, Leash=95, Boss=true, Drop="CoreEssence"},
	VeyrTheArchitect={Name="VEYR • ĐẤNG KIẾN TẠO ĐẦU TIÊN", VisualAsset="AbyssalSovereignDragon", Element="Void", HP=22000, ATK=85, Attack=85, DEF=36, Defense=36, XP=9000, Gold=15000, Range=30, Speed=12, Aggro=80, Leash=95, Boss=true, Drop="CoreEssence"},
	FrostSeaBeast={Name="THỦY QUÁI BIỂN MÂY (SKY SEA BEAST)", VisualAsset="SkySeaBeast", Element="Frost", HP=5200, ATK=42, Attack=42, DEF=20, Defense=20, XP=1800, Gold=2500, Range=24, Speed=10, Aggro=65, Leash=80, Boss=true, Drop="CoreEssence"},
}

function S.SpawnAllInitialEnemies(G)
	for i=1,3 do G.SpawnEnemy("TrainingDrone",Vector3.new(-328.9+(i-1)*15,49.5,222.4),false) end
	for i=1,2 do G.SpawnEnemy("SkyPirate",Vector3.new(-323.9+(i-1)*20,49.5,198.4),false) end
	G.SpawnEnemy("SkyHubWatchCommander",Vector3.new(-313.9,49.5,210.4),false)
	G.SpawnEnemy("TrainingDrone",Vector3.new(-566,51.0,982),false)
	G.SpawnEnemy("TrainingDrone",Vector3.new(-554,51.0,982),false)
	G.SpawnEnemy("ShrineGuardianBoss",Vector3.new(-560,51.0,972),false)
	G.SpawnEnemy("CorruptedGuard",Vector3.new(333,51.0,976),false)
	G.SpawnEnemy("CorruptedGuard",Vector3.new(347,51.0,976),false)
	G.SpawnEnemy("AetherArchonBoss",Vector3.new(340,51.0,983),false)
	G.SpawnEnemy("SkyPirate",Vector3.new(-2816,49.5,-80),false)
	G.SpawnEnemy("SkyPirate",Vector3.new(-2784,49.5,-80),false)
	G.SpawnEnemy("SkyPirate",Vector3.new(-3193.6,49.5,56.5),false)
	G.SpawnEnemy("SkyPirate",Vector3.new(-2406.4,49.5,56.5),false)
	G.SpawnEnemy("PirateCaptainVance",Vector3.new(-2800,49.5,-95),false)
	for i=1,3 do G.SpawnEnemy("CorruptedGuard",Vector3.new(-36+(i-1)*36,49.5,25),false) end
	G.SpawnEnemy("SunshardRoyalGuard",Vector3.new(-28,49.5,-18),false)
	G.SpawnEnemy("SunshardRoyalGuard",Vector3.new(28,49.5,-18),false)
	G.SpawnEnemy("GoldenKnight",Vector3.new(0,49.5,-52),false)
	for i=1,3 do G.SpawnEnemy("LightArcher",Vector3.new(-54+(i-1)*54,49.5,-96),false) end
	G.SpawnEnemy("CorruptedGuard",Vector3.new(554,49.5,-35),false)
	G.SpawnEnemy("LightArcher",Vector3.new(578,49.5,-35),false)
	G.SpawnEnemy("AureonSentinel",Vector3.new(0,50.5,-395),false)
	G.SpawnEnemy("SunshardTemplar",Vector3.new(2780,49.5,-450),false)
	G.SpawnEnemy("SunshardTemplar",Vector3.new(2820,49.5,-450),false)
	G.SpawnEnemy("SunshardTemplar",Vector3.new(2385.9,49.5,-163.1),false)
	G.SpawnEnemy("SunshardRoyalGuard",Vector3.new(2780,49.5,-490),false)
	G.SpawnEnemy("SunshardRoyalGuard",Vector3.new(2820,49.5,-490),false)
	G.SpawnEnemy("SunshardRoyalGuard",Vector3.new(3214.1,49.5,-163.1),false)
	G.SpawnEnemy("SolarHighPriestBoss",Vector3.new(2800,49.5,-475),false)

	task.spawn(function()
		task.wait()
		G.SpawnEnemy("FrostDrone",Vector3.new(11662,49.9,238),false)
		G.SpawnEnemy("FrostDrone",Vector3.new(11689,49.9,238),false)
		G.SpawnEnemy("OrderCyborg",Vector3.new(11675.7,49.9,212),false)
		G.SpawnEnemy("FrostAutomaton",Vector3.new(11662,49.9,212),false)
		G.SpawnEnemy("CryoVanguard",Vector3.new(11689,49.9,212),false)
		G.SpawnEnemy("CryoGuard",Vector3.new(11982,49.9,72),false)
		G.SpawnEnemy("CryoGuard",Vector3.new(12018,49.9,72),false)
		G.SpawnEnemy("CyberArcher",Vector3.new(11982,49.9,38),false)
		G.SpawnEnemy("CyberArcher",Vector3.new(12018,49.9,38),false)
		G.SpawnEnemy("FrostAutomaton",Vector3.new(12518,49.9,15),false)
		G.SpawnEnemy("CryoVanguard",Vector3.new(12544,49.9,15),false)
		G.SpawnEnemy("CryonPrime",Vector3.new(12000,50.5,-358.8),false)
		G.SpawnEnemy("CyberMercenary",Vector3.new(9906,50.5,1652),false)
		G.SpawnEnemy("CyberMercenary",Vector3.new(9934,50.5,1652),false)
		G.SpawnEnemy("FrostAutomaton",Vector3.new(8866,50.5,1664.7),false)
		G.SpawnEnemy("FrostAutomaton",Vector3.new(8892,50.5,1664.7),false)
		G.SpawnEnemy("CyberSyndicateBoss",Vector3.new(9920.7,50.5,1664.7),false)
		task.wait()
		G.SpawnEnemy("CryoGuard",Vector3.new(9384,50.5,-2068),false)
		G.SpawnEnemy("CryoGuard",Vector3.new(9416,50.5,-2068),false)
		G.SpawnEnemy("CryoVanguard",Vector3.new(9400,50.5,-1418.7),false)
		G.SpawnEnemy("CyberArcher",Vector3.new(9871.5,50.5,-1681.1),false)
		G.SpawnEnemy("CyberArcher",Vector3.new(8928.5,50.5,-1681.1),false)
		G.SpawnEnemy("PermafrostWardenBoss",Vector3.new(9400,50.5,-2085),false)
		G.SpawnEnemy("MechaDrone",Vector3.new(14584,50.5,1808),false)
		G.SpawnEnemy("MechaDrone",Vector3.new(14616,50.5,1808),false)
		G.SpawnEnemy("MechaDrone",Vector3.new(15046.9,50.5,1230.1),false)
		G.SpawnEnemy("MechaDrone",Vector3.new(14153.1,50.5,1230.1),false)
		G.SpawnEnemy("FrostAutomaton",Vector3.new(15046.9,50.5,2082.9),false)
		G.SpawnEnemy("FrostAutomaton",Vector3.new(14153.1,50.5,2082.9),false)
		G.SpawnEnemy("OrderCyborgBoss",Vector3.new(14600,50.5,1825),false)
		G.SpawnEnemy("ArcticCorsair",Vector3.new(14582,50.5,-1818),false)
		G.SpawnEnemy("ArcticCorsair",Vector3.new(14618,50.5,-1818),false)
		G.SpawnEnemy("GlacialSniper",Vector3.new(14112.1,50.5,-1894.3),false)
		G.SpawnEnemy("GlacialSniper",Vector3.new(15087.9,50.5,-1894.3),false)
		G.SpawnEnemy("SkySeaBeast",Vector3.new(14600,50.5,-1832),false)
		task.wait()
		G.SpawnEnemy("VoidPirate",Vector3.new(-12255,49.9,431.2),false)
		G.SpawnEnemy("VoidRaider",Vector3.new(-12228,49.9,431.2),false)
		G.SpawnEnemy("VoidMarauder",Vector3.new(-12241.5,49.9,416),false)
		G.SpawnEnemy("VoidMarauder",Vector3.new(-12241.5,49.9,446),false)
		G.SpawnEnemy("AbyssalKnight",Vector3.new(-11998,49.9,135),false)
		G.SpawnEnemy("AbyssalDreadknight",Vector3.new(-11968,49.9,135),false)
		G.SpawnEnemy("ShadowArcher",Vector3.new(-11998,49.9,106),false)
		G.SpawnEnemy("UmbralBowman",Vector3.new(-11968,49.9,106),false)
		G.SpawnEnemy("VoidMarauder",Vector3.new(-12470,49.9,45),false)
		G.SpawnEnemy("AbyssalDreadknight",Vector3.new(-12496,49.9,45),false)
		G.SpawnEnemy("AbyssalSovereignDragon",Vector3.new(-11635,50.8,-225),false)
		G.SpawnEnemy("Noxar",Vector3.new(-11672.2,50.8,-189.8),false)
		G.SpawnEnemy("VoidRaider",Vector3.new(-14618,50.5,1548),false)
		G.SpawnEnemy("VoidRaider",Vector3.new(-14582,50.5,1548),false)
		G.SpawnEnemy("AbyssalKnight",Vector3.new(-14618,50.5,1524),false)
		G.SpawnEnemy("AbyssalKnight",Vector3.new(-14582,50.5,1524),false)
		G.SpawnEnemy("VoidCastellanBoss",Vector3.new(-14600,50.5,1505),false)
		task.wait()
		G.SpawnEnemy("UmbralBowman",Vector3.new(-9418,50.5,1808),false)
		G.SpawnEnemy("UmbralBowman",Vector3.new(-9382,50.5,1808),false)
		G.SpawnEnemy("ShadowSpecter",Vector3.new(-9904.3,50.5,1689.3),false)
		G.SpawnEnemy("ShadowSpecter",Vector3.new(-8895.7,50.5,1689.3),false)
		G.SpawnEnemy("UmbralArchfiendBoss",Vector3.new(-9400,50.5,1795),false)
		G.SpawnEnemy("ShadowSpecter",Vector3.new(-14087.5,50.5,-1943.5),false)
		G.SpawnEnemy("ShadowSpecter",Vector3.new(-15112.5,50.5,-1943.5),false)
		G.SpawnEnemy("AbyssalDreadknight",Vector3.new(-14856.2,50.5,-2387.3),false)
		G.SpawnEnemy("AbyssalDreadknight",Vector3.new(-14343.8,50.5,-1499.7),false)
		G.SpawnEnemy("SoulReaperRift",Vector3.new(-14600,50.5,-1812),false)
		G.SpawnEnemy("ShadowSpecter",Vector3.new(-12018,50.5,-2961.3),false)
		G.SpawnEnemy("ShadowSpecter",Vector3.new(-11982,50.5,-2961.3),false)
		G.SpawnEnemy("TerrorSkyShark",Vector3.new(-12496.1,50.5,-3477.9),false)
		G.SpawnEnemy("TerrorSkyShark",Vector3.new(-11503.9,50.5,-3477.9),false)
		G.SpawnEnemy("AbyssalDragonHybrid",Vector3.new(-12020,50.5,-3366),false)
		G.SpawnEnemy("AbyssalDragonHybrid",Vector3.new(-11980,50.5,-3366),false)
		G.SpawnEnemy("AbyssalLeviathan",Vector3.new(-12000,50.5,-3378),false)
		task.wait()
		G.SpawnEnemy("UmbralBowman",Vector3.new(-14,170,-8975),false)
		G.SpawnEnemy("UmbralBowman",Vector3.new(14,170,-8975),false)
		G.SpawnEnemy("ShadowSpecter",Vector3.new(-14,170,-9000),false)
		G.SpawnEnemy("ShadowSpecter",Vector3.new(14,170,-9000),false)
		G.SpawnEnemy("UmbralBowman",Vector3.new(-516,170,-9110.7),false)
		G.SpawnEnemy("ShadowSpecter",Vector3.new(-492,170,-9110.7),false)
		G.SpawnEnemy("UmbralBowman",Vector3.new(492,170,-9110.7),false)
		G.SpawnEnemy("ShadowSpecter",Vector3.new(516,170,-9110.7),false)
		G.SpawnEnemy("ShadowSpecter",Vector3.new(0,170,-8544.9),false)
		G.SpawnEnemy("Sylvaris",Vector3.new(22,170,-8995),false)
		G.SpawnEnemy("SunshardTemplar",Vector3.new(11986,169.5,-9260),false)
		G.SpawnEnemy("SunshardTemplar",Vector3.new(12014,169.5,-9260),false)
		G.SpawnEnemy("GoldenKnight",Vector3.new(11986,169.5,-9285),false)
		G.SpawnEnemy("GoldenKnight",Vector3.new(12014,169.5,-9285),false)
		G.SpawnEnemy("SunshardTemplar",Vector3.new(11594,169.5,-9143.5),false)
		G.SpawnEnemy("GoldenKnight",Vector3.new(11618,169.5,-9143.5),false)
		G.SpawnEnemy("SunshardTemplar",Vector3.new(12382,169.5,-9143.5),false)
		G.SpawnEnemy("GoldenKnight",Vector3.new(12406,169.5,-9143.5),false)
		G.SpawnEnemy("GoldenKnight",Vector3.new(11643.3,169.5,-8708.9),false)
		G.SpawnEnemy("Ignivar",Vector3.new(12000,169.5,-9295),false)
		G.SpawnEnemy("ArcticCorsair",Vector3.new(-12016,170,-8956),false)
		G.SpawnEnemy("ArcticCorsair",Vector3.new(-11984,170,-8956),false)
		G.SpawnEnemy("TerrorSkyShark",Vector3.new(-12014,170,-8982),false)
		G.SpawnEnemy("TerrorSkyShark",Vector3.new(-11986,170,-8982),false)
		G.SpawnEnemy("ArcticCorsair",Vector3.new(-12508,170,-9077.9),false)
		G.SpawnEnemy("TerrorSkyShark",Vector3.new(-12484,170,-9077.9),false)
		G.SpawnEnemy("ArcticCorsair",Vector3.new(-11516,170,-9077.9),false)
		G.SpawnEnemy("TerrorSkyShark",Vector3.new(-11492,170,-9077.9),false)
		G.SpawnEnemy("TerrorSkyShark",Vector3.new(-12000,170,-8561.3),false)
		G.SpawnEnemy("Nerith",Vector3.new(-11980,170,-8974),false)
		G.SpawnEnemy("MechaDrone",Vector3.new(-14,230,-13480),false)
		G.SpawnEnemy("MechaDrone",Vector3.new(14,230,-13480),false)
		G.SpawnEnemy("CryoVanguard",Vector3.new(-14,230,-13502),false)
		G.SpawnEnemy("CryoVanguard",Vector3.new(14,230,-13502),false)
		G.SpawnEnemy("MechaDrone",Vector3.new(-524,230,-13643.5),false)
		G.SpawnEnemy("CryoVanguard",Vector3.new(-500,230,-13643.5),false)
		G.SpawnEnemy("MechaDrone",Vector3.new(500,230,-13643.5),false)
		G.SpawnEnemy("CryoVanguard",Vector3.new(524,230,-13643.5),false)
		G.SpawnEnemy("CryoVanguard",Vector3.new(0,230,-13020.3),false)
		G.SpawnEnemy("Aion",Vector3.new(0,230,-13512),false)
		G.SpawnEnemy("ShadowSpecter",Vector3.new(-14,310,-17635),false)
		G.SpawnEnemy("ShadowSpecter",Vector3.new(14,310,-17635),false)
		G.SpawnEnemy("AbyssalDreadknight",Vector3.new(-500,310,-18036.9),false)
		G.SpawnEnemy("AbyssalDragonHybrid",Vector3.new(-476,310,-18036.9),false)
		G.SpawnEnemy("AbyssalDreadknight",Vector3.new(476,310,-18036.9),false)
		G.SpawnEnemy("AbyssalDragonHybrid",Vector3.new(500,310,-18036.9),false)
		G.SpawnEnemy("AbyssalDreadknight",Vector3.new(-16,310,-18272),false)
		G.SpawnEnemy("AbyssalDreadknight",Vector3.new(16,310,-18272),false)
		G.SpawnEnemy("AbyssalDragonHybrid",Vector3.new(-20,310,-18286),false)
		G.SpawnEnemy("AbyssalDragonHybrid",Vector3.new(20,310,-18286),false)
		G.SpawnEnemy("Veyr",Vector3.new(0,310,-18295),false)
	end)
end

return S
