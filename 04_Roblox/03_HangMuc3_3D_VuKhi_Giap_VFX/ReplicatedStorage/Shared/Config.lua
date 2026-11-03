local C = {}
C.MaxLevel = 2550
C.MaxStat = 2550
C.StatPointsPerLevel = 3
C.StudioPersistence = false -- Enable only in a published, isolated test experience.
C.StoreName = "SKYBREAK_P0_TEST_v1"
C.LeaseSeconds = 180
C.AutosaveSeconds = 45
C.Spawn = Vector3.new(-317.4, 50.5, 527.8)
C.Arena = Vector3.new(0, 49, -358.8)
C.ArenaEntry = Vector3.new(0, 50.5, -275)
C.BossSpawn = Vector3.new(0, 50.5, -395)
C.QuestCheckpoint = Vector3.new(-313.9, 50.5, 210.4)

C.GachaCostGold = 150000
C.GachaCostShards = 200
C.AwakeningCostShards = 1000
C.RaceRerollCostShards = 300
C.StatRefundCostShards = 150
C.HotbarSlots = {
    [1] = "FightingStyle",
    [2] = "AetherFruit",
    [3] = "Sword",
    [4] = "Gun",
}

C.RequiredXP = function(level)
    local lv = math.clamp(tonumber(level) or 1, 1, C.MaxLevel)
    return math.floor(65 + 14 * (lv - 1))
end

local islandList = {
    -- Sea 1: Golden Sky Archipelago (Lv. 1–700)
    {Id="SkyHub", Name="Sea 1 • Zone 1: Đảo Khởi Đầu (Sky Hub Nexus)", Realm="GoldenSky", Sea=1, Pos=Vector3.new(-317.4, 50.5, 527.8), Level="Lv. 1–75", MinLevel=1, MaxLevel=75, Order=1},
    {Id="GoldenSky", Name="Sea 1 • Zone 1: Bầu Trời Hoàng Kim (Golden Sky Hub)", Realm="GoldenSky", Sea=1, Pos=Vector3.new(-313.9, 50.5, 210.4), Level="Lv. 1–700", MinLevel=1, MaxLevel=700, Order=1},
    {Id="ZiolesGachaShrine", Name="Sea 1 • Zone 1B: Điện Thờ Zioles Gacha (Zioles Shrine)", Realm="GoldenSky", Sea=1, Pos=Vector3.new(-560, 52.5, 996), Level="Lv. 75–150", MinLevel=75, MaxLevel=150, Order=2},
    {Id="AetherShrines", Name="Sea 1 • Zone 1C: Đài Điện Thờ Aether (Aether Shrine)", Realm="GoldenSky", Sea=1, Pos=Vector3.new(340, 52.5, 996), Level="Lv. 150–250", MinLevel=150, MaxLevel=250, Order=2},
    {Id="WestGarden", Name="Sea 1 • Zone 2: Pháo Đài Không Tặc Vườn Tây (West Garden Bastion)", Realm="GoldenSky", Sea=1, Pos=Vector3.new(-2800, 50.5, -65), Level="Lv. 250–375", MinLevel=250, MaxLevel=375, Order=3},
    {Id="LumenPlaza", Name="Sea 1 • Zone 3: Quảng Trường Ánh Sáng (Lumen Plaza)", Realm="GoldenSky", Sea=1, Pos=Vector3.new(0, 50.5, 65), Level="Lv. 375–525", MinLevel=375, MaxLevel=525, Order=4},
    {Id="SunshardSanctuary", Name="Sea 1 • Zone 4: Đảo Đền Mây Nổi (Sunshard Sky Sanctuary)", Realm="GoldenSky", Sea=1, Pos=Vector3.new(2800, 50.5, -55), Level="Lv. 525–650", MinLevel=525, MaxLevel=650, Order=5},
    {Id="BossForecourt", Name="Sea 1 • Zone 5: Tháp Phán Quyết (Aureon Spire Citadel)", Realm="GoldenSky", Sea=1, Pos=Vector3.new(0, 50.5, -285), Level="Lv. 700 (Boss)", MinLevel=650, MaxLevel=700, Order=6},

    -- Sea 2: Frozen Cyber Expanse (Lv. 700–1500)
    {Id="FrozenCyber", Name="Sea 2 • Zone 6: Cảng Băng Giá (Cyberport Outpost)", Realm="FrozenCyber", Sea=2, Pos=Vector3.new(11620.5, 50.9, 534.8), Level="Lv. 700–850", MinLevel=700, MaxLevel=850, Order=7},
    {Id="CyberportCafe", Name="Sea 2 • Zone 6B: Quán Cà Phê Giao Dịch (Cyberport Café Island)", Realm="FrozenCyber", Sea=2, Pos=Vector3.new(9400, 50.9, 1785), Level="Lv. 850–975", MinLevel=850, MaxLevel=975, Order=8},
    {Id="PermafrostGarrison", Name="Sea 2 • Zone 7: Pháo Đài Tuyết (Permafrost Garrison Fortress)", Realm="FrozenCyber", Sea=2, Pos=Vector3.new(9400, 50.9, -2055), Level="Lv. 975–1150", MinLevel=975, MaxLevel=1150, Order=9},
    {Id="MicrochipRaidLab", Name="Sea 2 • Zone 8: Phòng Thí Nghiệm Đột Kích (Microchip Raid Lab)", Realm="FrozenCyber", Sea=2, Pos=Vector3.new(14600, 50.9, 1785), Level="Lv. 1150–1300", MinLevel=1150, MaxLevel=1300, Order=10},
    {Id="GlacialWreckage", Name="Sea 2 • Zone 9: Xác Tàu Băng Cổ Đại (Glacial Wreckage Sea)", Realm="FrozenCyber", Sea=2, Pos=Vector3.new(14600, 50.9, -1812), Level="Lv. 1300–1425", MinLevel=1300, MaxLevel=1425, Order=11},
    {Id="CryonArena", Name="Sea 2 • Zone 10: Ngai Vàng Băng Đế (Cryon Prime Citadel)", Realm="FrozenCyber", Sea=2, Pos=Vector3.new(12000, 50.9, -285), Level="Lv. 1500 (Boss)", MinLevel=1425, MaxLevel=1500, Order=12},

    -- Sea 3: Shadow Realm Abyss (Lv. 1500–2200)
    {Id="ShadowRealm", Name="Sea 3 • Zone 11: Pháo Đài Hư Không (Shadow Realm Outpost)", Realm="ShadowRealm", Sea=3, Pos=Vector3.new(-12593.4, 50.9, 414), Level="Lv. 1500–1650", MinLevel=1500, MaxLevel=1650, Order=13},
    {Id="CastleOnTheVoid", Name="Sea 3 • Zone 11B: Dinh Thự Hư Không (Castle on the Void Mansion)", Realm="ShadowRealm", Sea=3, Pos=Vector3.new(-14600, 50.9, 2173.1), Level="Lv. 1650–1775", MinLevel=1650, MaxLevel=1775, Order=14},
    {Id="UmbralSanctum", Name="Sea 3 • Zone 12: Rừng Tinh Thể Đen (Umbral Crystal Sanctum)", Realm="ShadowRealm", Sea=3, Pos=Vector3.new(-9400, 50.9, 1815), Level="Lv. 1775–1900", MinLevel=1775, MaxLevel=1900, Order=15},
    {Id="TempleOfTheCore", Name="Sea 3 • Zone 13: Đền Thờ Thức Tỉnh Tộc V4 (Temple of the Core)", Realm="ShadowRealm", Sea=3, Pos=Vector3.new(-14600, 50.9, -1785), Level="Lv. 1900–2025", MinLevel=1900, MaxLevel=2025, Order=16},
    {Id="LeviathanAbyss", Name="Sea 3 • Zone 14: Đảo Ảo Ảnh & Vực Thẳm Leviathan (Mirage Abyss)", Realm="ShadowRealm", Sea=3, Pos=Vector3.new(-12000, 50.9, -3364.5), Level="Lv. 2025–2125", MinLevel=2025, MaxLevel=2125, Order=17},
    {Id="NoxarArena", Name="Sea 3 • Zone 15: Ngai Vàng Hư Không (Noxar's Sovereign Throne)", Realm="ShadowRealm", Sea=3, Pos=Vector3.new(-11672.2, 50.9, -110), Level="Lv. 2200 (Boss)", MinLevel=2125, MaxLevel=2200, Order=18},

    -- Expansion Realms (Celestial World Map Realms 4–8 • Lv. 2200–2550 MAX)
    {Id="VerdantCrown", Name="Realm 4 • Vương Miện Cổ Thụ (The Verdant Crown)", Realm="VerdantCrown", Sea=4, Pos=Vector3.new(0, 170.9, -8985), Level="Lv. 2200–2270", MinLevel=2200, MaxLevel=2270, Order=19},
    {Id="VerdantWestBough", Name="Realm 4B • Cánh Rừng Tây Cổ Thụ (West Bough Canopy)", Realm="VerdantCrown", Sea=4, Pos=Vector3.new(-504.3, 170.9, -9110.7), Level="Lv. 2215–2240", MinLevel=2215, MaxLevel=2240, Order=19},
    {Id="VerdantEastGrove", Name="Realm 4C • Đảo Rừng Ngọc Bích (East Emerald Grove)", Realm="VerdantCrown", Sea=4, Pos=Vector3.new(504.3, 170.9, -9110.7), Level="Lv. 2235–2255", MinLevel=2235, MaxLevel=2255, Order=19},
    {Id="VerdantNorthSpire", Name="Realm 4D • Đỉnh Tháp Nhựa Aether (North World-Tree Spire)", Realm="VerdantCrown", Sea=4, Pos=Vector3.new(0, 170.9, -8544.9), Level="Lv. 2250–2270", MinLevel=2250, MaxLevel=2270, Order=19},

    {Id="EmberforgeWastes", Name="Realm 5 • Hoang Mạc Lò Rèn Lửa (Emberforge Wastes)", Realm="EmberforgeWastes", Sea=5, Pos=Vector3.new(12000, 170.5, -9265), Level="Lv. 2270–2340", MinLevel=2270, MaxLevel=2340, Order=20},
    {Id="EmberWestFoundry", Name="Realm 5B • Xưởng Đúc Tây Hỏa (West Slag Foundry)", Realm="EmberforgeWastes", Sea=5, Pos=Vector3.new(11606.4, 170.5, -9143.5), Level="Lv. 2285–2310", MinLevel=2285, MaxLevel=2310, Order=20},
    {Id="EmberEastCaldera", Name="Realm 5C • Miệng Núi Lửa Đông (East Magma Caldera)", Realm="EmberforgeWastes", Sea=5, Pos=Vector3.new(12393.6, 170.5, -9143.5), Level="Lv. 2305–2325", MinLevel=2305, MaxLevel=2325, Order=20},
    {Id="EmberNorthCitadel", Name="Realm 5D • Pháo Đài Sao Nung (North Star-Forge Citadel)", Realm="EmberforgeWastes", Sea=5, Pos=Vector3.new(11643.3, 170.5, -8708.9), Level="Lv. 2320–2340", MinLevel=2320, MaxLevel=2340, Order=20},

    {Id="AbyssalTides", Name="Realm 6 • Thủy Triều Vực Sâu (Abyssal Tides)", Realm="AbyssalTides", Sea=6, Pos=Vector3.new(-12000, 170.9, -8964.5), Level="Lv. 2340–2410", MinLevel=2340, MaxLevel=2410, Order=21},
    {Id="AbyssalWestReef", Name="Realm 6B • Rạn San Hô Phát Quang (West Bioluminescent Reef)", Realm="AbyssalTides", Sea=6, Pos=Vector3.new(-12496.1, 170.9, -9077.9), Level="Lv. 2355–2380", MinLevel=2355, MaxLevel=2380, Order=21},
    {Id="AbyssalEastTrench", Name="Realm 6C • Vực Hải Lưu Ngược (East Inverted Trench)", Realm="AbyssalTides", Sea=6, Pos=Vector3.new(-11503.9, 170.9, -9077.9), Level="Lv. 2375–2395", MinLevel=2375, MaxLevel=2395, Order=21},
    {Id="AbyssalNorthSpire", Name="Realm 6D • Cung Điện Thủy Triều (North Pelagic Spire)", Realm="AbyssalTides", Sea=6, Pos=Vector3.new(-12000, 170.9, -8561.3), Level="Lv. 2390–2410", MinLevel=2390, MaxLevel=2410, Order=21},

    {Id="ChronosBastion", Name="Realm 7 • Pháo Đài Thời Gian (Chronos Bastion)", Realm="ChronosBastion", Sea=7, Pos=Vector3.new(0, 230.9, -13485), Level="Lv. 2410–2480", MinLevel=2410, MaxLevel=2480, Order=22},
    {Id="ChronosWestDial", Name="Realm 7B • Vòng Tinh Cầu Quá Khứ (West Past Astrolabe)", Realm="ChronosBastion", Sea=7, Pos=Vector3.new(-512.5, 230.9, -13643.5), Level="Lv. 2425–2450", MinLevel=2425, MaxLevel=2450, Order=22},
    {Id="ChronosEastDial", Name="Realm 7C • Vòng Tinh Cầu Tương Lai (East Future Astrolabe)", Realm="ChronosBastion", Sea=7, Pos=Vector3.new(512.5, 230.9, -13643.5), Level="Lv. 2445–2465", MinLevel=2445, MaxLevel=2465, Order=22},
    {Id="ChronosNorthSpire", Name="Realm 7D • Tháp Niên Đại Vĩnh Hằng (North Horology Spire)", Realm="ChronosBastion", Sea=7, Pos=Vector3.new(0, 230.9, -13020.3), Level="Lv. 2460–2480", MinLevel=2460, MaxLevel=2480, Order=22},

    {Id="VeilsEnd", Name="Realm 8 • Tận Cùng Bức Màn (The Veil's End)", Realm="VeilsEnd", Sea=8, Pos=Vector3.new(0, 310.9, -17626.9), Level="Lv. 2480–2550 (MAX)", MinLevel=2480, MaxLevel=2550, Order=23},
    {Id="VeilsWestHorizon", Name="Realm 8B • Chân Trời Sự Kiện Tây (West Event Horizon)", Realm="VeilsEnd", Sea=8, Pos=Vector3.new(-487.9, 310.9, -18036.9), Level="Lv. 2495–2520", MinLevel=2495, MaxLevel=2520, Order=23},
    {Id="VeilsEastHorizon", Name="Realm 8C • Tinh Vân Sụp Đổ Đông (East Collapsing Nebula)", Realm="VeilsEnd", Sea=8, Pos=Vector3.new(487.9, 310.9, -18036.9), Level="Lv. 2515–2535", MinLevel=2515, MaxLevel=2535, Order=23},
    {Id="VeilsNorthThrone", Name="Realm 8D • Ngai Vàng Đấng Kiến Tạo (North Architect's Citadel)", Realm="VeilsEnd", Sea=8, Pos=Vector3.new(0, 310.9, -18265), Level="Lv. 2530–2550 (MAX)", MinLevel=2530, MaxLevel=2550, Order=23},
}

C.FastTravel = {}
C.FastTravelOrder = {}
for _, isl in ipairs(islandList) do
    C.FastTravel[isl.Id] = isl
    table.insert(C.FastTravelOrder, isl.Id)
end
C.FastTravel.QuestCheckpoint = C.FastTravel.GoldenSky
C.FastTravel.GlacialDangerSea = C.FastTravel.GlacialWreckage
C.FastTravel.UmbralCrystalForest = C.FastTravel.UmbralSanctum
C.FastTravel.EmberforgeWestFoundry = C.FastTravel.EmberWestFoundry
C.FastTravel.EmberforgeEastCaldera = C.FastTravel.EmberEastCaldera
C.FastTravel.EmberforgeNorthCitadel = C.FastTravel.EmberNorthCitadel
C.Islands = setmetatable(islandList, {
    __index = function(_, k)
        return C.FastTravel[k]
    end,
})

C.Classes = {
    SkyGuardian = {Name='Sky Guardian', Role='Tank / Vanguard', HP=1.25, ATK=0.95, DEF=1.2, Speed=18},
    ThunderStriker = {Name='Thunder Striker', Role='Melee Assassin / Burst', HP=0.9, ATK=1.1, DEF=0.9, Speed=22},
    ArcaneMage = {Name='Arcane Mage', Role='Ranged Spellcaster / AoE', HP=0.85, ATK=1.15, DEF=0.8, Speed=18},
}

C.ClassWeapons = {
    SkyGuardian = 'starter_sword',
    ThunderStriker = 'starter_daggers',
    ArcaneMage = 'starter_staff',
}

C.ClassSkills = {
    SkyGuardian = {'SkySlash', 'GuardianShield', 'JudgmentStrike', 'CelestialAegis'},
    ThunderStriker = {'ArcCut', 'FlashStep', 'StormBlitz', 'ThunderJudgement'},
    ArcaneMage = {'FrostBolt', 'ManaBarrier', 'ArcaneComet', 'AstralCataclysm'},
}

C.SkillNames = {
    SkySlash = 'Sky Slash',
    GuardianShield = 'Guardian Shield',
    JudgmentStrike = 'Judgment Strike',
    CelestialAegis = 'Celestial Aegis',
    ArcCut = 'Arc Cut',
    FlashStep = 'Flash Step',
    StormBlitz = 'Storm Blitz',
    ThunderJudgement = 'Thunder Judgement',
    FrostBolt = 'Frost Bolt',
    ManaBarrier = 'Mana Barrier',
    ArcaneComet = 'Arcane Comet',
    AstralCataclysm = 'Astral Cataclysm',
}

C.SkillDetails = {
    SkySlash = {Id='SkySlash', Name='Sky Slash', Key='1', Type='Active', Element='Sky', ClassId='SkyGuardian', Cooldown=6, Cost=10, Range=18, Multiplier=2.2, Break=22, Level=1, Desc='Chém vòng cung ánh sáng tầm trung, gây 220% sát thương ATK và phá giáp mạnh.'},
    GuardianShield = {Id='GuardianShield', Name='Guardian Shield', Key='2', Type='Defense', Element='Sky', ClassId='SkyGuardian', Cooldown=14, Cost=15, Range=20, Multiplier=0, Break=0, Level=1, Desc='Tạo khiên thánh quang cho bản thân và đồng đội xung quanh trong 5 giây, giảm 65% sát thương nhận vào.'},
    JudgmentStrike = {Id='JudgmentStrike', Name='Judgment Strike', Key='3', Type='Heavy Skill', Element='Sky', ClassId='SkyGuardian', Cooldown=10, Cost=18, Range=20, Multiplier=3.1, Break=35, Level=1, Desc='Giáng đòn phán xét từ trên cao xuống mục tiêu phía trước, gây 310% sát thương ATK và 35 Break.'},
    CelestialAegis = {Id='CelestialAegis', Name='Celestial Aegis', Key='R', Type='Ultimate', Element='Sky', ClassId='SkyGuardian', Cooldown=20, Cost=25, Range=24, Multiplier=4.5, Break=50, Level=1, Desc='Tuyệt kỹ Thiên Khiên: Bùng nổ thánh quang diện rộng gây 450% sát thương ATK và ban khiên bất diệt 6 giây.'},

    ArcCut = {Id='ArcCut', Name='Arc Cut', Key='1', Type='Combo Skill', Element='Lightning', ClassId='ThunderStriker', Cooldown=5, Cost=10, Range=12, Multiplier=0.95, Break=10, Level=1, Desc='Tung 3 nhát chém lôi điện cực nhanh liên tiếp, mỗi đòn gây 95% sát thương ATK.'},
    FlashStep = {Id='FlashStep', Name='Flash Step', Key='2', Type='Mobility', Element='Lightning', ClassId='ThunderStriker', Cooldown=8, Cost=15, Range=20, Multiplier=1.4, Break=12, Level=1, Desc='Lướt chớp nhoáng 20m qua không trung ở trạng thái vô địch ngắn, gây sát thương lôi điện trên đường lướt.'},
    StormBlitz = {Id='StormBlitz', Name='Storm Blitz', Key='3', Type='Burst Skill', Element='Lightning', ClassId='ThunderStriker', Cooldown=11, Cost=18, Range=16, Multiplier=3.3, Break=30, Level=1, Desc='Bão kiếm sấm sét càn quét xung quanh, gây 330% sát thương ATK và kích hoạt 5 tầng tốc đánh.'},
    ThunderJudgement = {Id='ThunderJudgement', Name='Thunder Judgement', Key='R', Type='Ultimate', Element='Lightning', ClassId='ThunderStriker', Cooldown=20, Cost=25, Range=24, Multiplier=4.8, Break=45, Level=1, Desc='Tuyệt kỹ Lôi Phạt: Triệu hồi thiên lôi giáng xuống toàn bộ kẻ địch trong bán kính 24m, gây 480% sát thương ATK.'},

    FrostBolt = {Id='FrostBolt', Name='Frost Bolt', Key='1', Type='Ranged Spell', Element='Frost', ClassId='ArcaneMage', Cooldown=5.5, Cost=12, Range=42, Multiplier=2.3, Break=22, Level=1, Desc='Bắn mũi tên băng tinh tầm xa 42m, gây 230% sát thương phép và làm suy yếu giáp kẻ địch.'},
    ManaBarrier = {Id='ManaBarrier', Name='Mana Barrier', Key='2', Type='Arcane Ward', Element='Frost', ClassId='ArcaneMage', Cooldown=14, Cost=15, Range=18, Multiplier=0, Break=0, Level=1, Desc='Kết giới ma lực bao bọc cơ thể trong 5 giây, hấp thụ 65% sát thương và hồi nhẹ Stamina.'},
    ArcaneComet = {Id='ArcaneComet', Name='Arcane Comet', Key='3', Type='AoE Spell', Element='Void', ClassId='ArcaneMage', Cooldown=11, Cost=20, Range=36, Multiplier=3.4, Break=32, Level=1, Desc='Triệu hồi sao chổi cổ ngữ rơi xuống mục tiêu tầm xa, gây 340% sát thương diện rộng.'},
    AstralCataclysm = {Id='AstralCataclysm', Name='Astral Cataclysm', Key='R', Type='Ultimate', Element='Void', ClassId='ArcaneMage', Cooldown=20, Cost=25, Range=38, Multiplier=5.0, Break=50, Level=1, Desc='Tuyệt kỹ Tinh Vân Đại Diệt: Nổ tung trường trọng lực hư không tầm xa, gây 500% sát thương phép cực đại.'},
}

C.Stats = function(level, classId, statAlloc)
    local lv = math.clamp(tonumber(level) or 1, 1, C.MaxLevel)
    local class = C.Classes[classId or 'SkyGuardian'] or C.Classes.SkyGuardian
    local baseCrit = classId == 'ThunderStriker' and 12 or (classId == 'ArcaneMage' and 8 or 5)
    local baseCritDmg = classId == 'ThunderStriker' and 60 or 50
    local alloc = type(statAlloc) == "table" and statAlloc or {}
    local defPts = math.clamp((tonumber(alloc.Defense) or 1) - 1, 0, C.MaxStat - 1)
    local offensePts = math.clamp(math.max(
        0,
        (tonumber(alloc.Melee) or 1) - 1,
        (tonumber(alloc.Sword) or 1) - 1,
        (tonumber(alloc.Gun) or 1) - 1,
        (tonumber(alloc.Fruit) or 1) - 1
    ), 0, C.MaxStat - 1)
    return {
        HP = math.floor((120 + 2.2 * (lv - 1) + 4.8 * defPts) * class.HP),
        ATK = math.floor((14 + 0.18 * (lv - 1) + 0.42 * offensePts) * class.ATK),
        DEF = math.floor((6 + 0.08 * (lv - 1) + 0.18 * defPts) * class.DEF),
        CritRate = baseCrit,
        CritDmg = baseCritDmg,
        Break = 100,
    }
end

C.Actions = {
    Attack = {Name='Attack', Cooldown=0.42, Range=10, Multiplier=1, Break=8},
    Heavy = {Name='Heavy Attack', Cooldown=1.8, Range=11, Multiplier=2.4, Break=28, Cost=20},
    Dodge = {Name='Dodge', Cooldown=1.2, Cost=25},
    Dash = {Name='Dash', Cooldown=1.2, Cost=25},

    SkySlash = C.SkillDetails.SkySlash,
    GuardianShield = C.SkillDetails.GuardianShield,
    JudgmentStrike = C.SkillDetails.JudgmentStrike,
    CelestialAegis = C.SkillDetails.CelestialAegis,

    ArcCut = C.SkillDetails.ArcCut,
    FlashStep = C.SkillDetails.FlashStep,
    StormBlitz = C.SkillDetails.StormBlitz,
    ThunderJudgement = C.SkillDetails.ThunderJudgement,

    FrostBolt = C.SkillDetails.FrostBolt,
    ManaBarrier = C.SkillDetails.ManaBarrier,
    ArcaneComet = C.SkillDetails.ArcaneComet,
    AstralCataclysm = C.SkillDetails.AstralCataclysm,
}

-- ============================================================================
-- 12 AETHER CORE FRUITS (BLOX FRUITS PARITY)
-- ============================================================================
C.FruitOrder = {
    "GaleCore",
    "SandstoneCore",
    "SolarFlameCore",
    "GlacierIceCore",
    "CelestialLightCore",
    "StarforgedMagmaCore",
    "ThunderRumbleCore",
    "AstralGravityCore",
    "DimensionalPortalCore",
    "SolarTitanCore",
    "AetherflowCore",
    "AbyssalSovereignCore",
}

C.AetherFruits = {
    GaleCore = {
        Id = "GaleCore",
        Name = "Trái Gió • Gale Core",
        Rarity = "Common",
        Type = "Elemental",
        Logia = true,
        Transform3D = nil,
        Price = 75000,
        Element = "Sky",
        Passive = "Cơ thể Gió (Logia): Miễn nhiễm sát thương thường từ kẻ địch cấp thấp hơn (trừ khi có Haki Vũ Trang).",
        Desc = "Trái Ác Quỷ hệ Nguyên Tố Gió cơ bản, cho phép phóng lưỡi đao gió và cưỡi lốc xoáy trên không.",
        Moves = {
            Z = {Key="Z", Name="Gale Blades • Phong Đao", AwakenedName="Tempest Cleaver • Cuồng Phong Đao", Mastery=1, Cooldown=4.5, Cost=8, Range=24, Multiplier=2.2, Break=20, Element="Sky", Desc="Phóng chuỗi lưỡi đao gió cắt xuyên mục tiêu phía trước."},
            X = {Key="X", Name="Cyclone Burst • Lốc Xoáy Không Trung", AwakenedName="Supercell Vortex • Siêu Bão Đẩy Lùi", Mastery=1, Cooldown=7.0, Cost=12, Range=22, Multiplier=2.6, Break=26, Element="Sky", Desc="Tạo cột lốc xoáy cuốn tung kẻ địch lên không trung."},
            C = {Key="C", Name="Tornado Crush • Bão Phong Nghiền Nát", AwakenedName="Eye of the Hurricane • Tâm Bão Hủy Diệt", Mastery=1, Cooldown=9.5, Cost=16, Range=26, Multiplier=3.1, Break=32, Element="Sky", Desc="Triệu hồi bão lớn giam cầm và gây sát thương liên hoàn."},
            V = {Key="V", Name="Skyborn Typhoon • Đại Cuồng Phong", AwakenedName="Cataclysmic Gale • Thiên Tai Gió Lốc", Mastery=1, Cooldown=14.0, Cost=22, Range=30, Multiplier=3.9, Break=42, Element="Sky", Desc="Giải phóng đại cuồng phong càn quét toàn bộ khu vực."},
            F = {Key="F", Name="Wind Ride • Cưỡi Gió", AwakenedName="Jetstream Flight • Phản Lực Không Lưu", Mastery=1, Cooldown=5.0, Cost=8, Range=26, Multiplier=1.4, Break=12, Element="Sky", Desc="Hóa thành luồng gió bay nhanh qua bầu trời."},
        },
    },
    SandstoneCore = {
        Id = "SandstoneCore",
        Name = "Trái Cát Vàng • Sandstone Core",
        Rarity = "Uncommon",
        Type = "Elemental",
        Logia = true,
        Transform3D = nil,
        Price = 420000,
        Element = "Sky",
        Passive = "Sa Mạc Hộ Thể (Logia): Hóa cát tránh đòn thường và làm khô cạn tốc độ di chuyển của kẻ địch.",
        Desc = "Điều khiển bão cát sa mạc cổ đại, trói chân mục tiêu trong quan tài cát và nghiền nát giáp.",
        Moves = {
            Z = {Key="Z", Name="Desert Blade • Sa Đao", AwakenedName="Dune Guillotine • Đoạn Đầu Đao Sa Mạc", Mastery=1, Cooldown=5, Cost=10, Range=25, Multiplier=2.3, Break=22, Element="Sky", Desc="Chém sóng cát sắc bén tầm trung gây chảy máu năng lượng."},
            X = {Key="X", Name="Sand Coffin • Quan Tài Cát", AwakenedName="Pyramid Tomb • Lăng Mộ Cổ Đại", Mastery=30, Cooldown=9, Cost=15, Range=22, Multiplier=2.8, Break=30, Element="Sky", Desc="Bóp nghẹt mục tiêu trong lồng cát vàng rồi kích nổ."},
            C = {Key="C", Name="Quicksand Vortex • Hố Cát Tử Thần", AwakenedName="Mirage Sinkhole • Tuyệt Địa Cát Lún", Mastery=60, Cooldown=12, Cost=18, Range=26, Multiplier=3.3, Break=35, Element="Sky", Desc="Tạo hố cát lún hút toàn bộ kẻ địch xung quanh vào tâm."},
            V = {Key="V", Name="Sandstorm Wrath • Bão Cát Hoàng Kim", AwakenedName="Pharaoh's Tempest • Cơn Thịnh Nộ Hoàng Gia", Mastery=100, Cooldown=17, Cost=25, Range=32, Multiplier=4.2, Break=45, Element="Sky", Desc="Triệu hồi đại bão cát mù mịt nghiền nát cả đấu trường."},
            F = {Key="F", Name="Sand Flight • Cát Lưu", AwakenedName="Golden Dust Dash • Hóa Bụi Vàng", Mastery=15, Cooldown=6, Cost=10, Range=24, Multiplier=1.3, Break=10, Element="Sky", Desc="Hóa thành cơn lốc cát lướt đi với tốc độ cao."},
        },
    },
    SolarFlameCore = {
        Id = "SolarFlameCore",
        Name = "Trái Lửa Mặt Trời • Solar Flame Core",
        Rarity = "Uncommon",
        Type = "Elemental",
        Logia = true,
        Transform3D = nil,
        Price = 550000,
        Element = "Sky",
        Passive = "Lửa Thái Dương (Logia): Miễn nhiễm đòn thường và để lại hiệu ứng Thiêu Đốt mặt trời trên mục tiêu.",
        Desc = "Ngọn lửa mặt trời rực cháy từ tháp Aureon, gây sát thương nổ diện rộng và đẩy lùi mạnh.",
        Moves = {
            Z = {Key="Z", Name="Fire Bullets • Hỏa Đạn Liên Hoàn", AwakenedName="Blue Flare Volley • Liên Châu Hỏa Lam", Mastery=1, Cooldown=5, Cost=10, Range=28, Multiplier=2.5, Break=24, Element="Sky", Desc="Bắn chùm đạn lửa mặt trời phát nổ khi chạm mục tiêu."},
            X = {Key="X", Name="Blazing Beam • Hỏa Quyền Xuyên Thấu", AwakenedName="Prominence Fist • Thái Dương Viêm Quyền", Mastery=35, Cooldown=8.5, Cost=15, Range=30, Multiplier=2.9, Break=28, Element="Sky", Desc="Phóng cột lửa khổng lồ đẩy lùi và thiêu rụi kẻ địch."},
            C = {Key="C", Name="Flame Pillar • Hỏa Trụ Xung Thiên", AwakenedName="Inferno Geyser • Cột Lửa Địa Ngục Lam", Mastery=70, Cooldown=11, Cost=18, Range=24, Multiplier=3.4, Break=36, Element="Sky", Desc="Dựng cột lửa xung thiên dưới chân, hất tung mọi kẻ địch xung quanh."},
            V = {Key="V", Name="Solar Emperor • Thái Dương Viêm Đế", AwakenedName="Supernova Sun • Siêu Tân Tinh Hủy Diệt", Mastery=120, Cooldown=18, Cost=26, Range=36, Multiplier=4.6, Break=50, Element="Sky", Desc="Tạo quả cầu mặt trời khổng lồ ném xuống chiến trường gây vụ nổ cực đại."},
            F = {Key="F", Name="Rocket Flight • Hỏa Tiễn Phi Hành", AwakenedName="Plasma Jet • Phản Lực Lửa Lam", Mastery=20, Cooldown=5.5, Cost=10, Range=26, Multiplier=1.4, Break=12, Element="Sky", Desc="Phóng đi như tên lửa rực cháy trên bầu trời."},
        },
    },
    GlacierIceCore = {
        Id = "GlacierIceCore",
        Name = "Trái Băng Vĩnh Cửu • Glacier Ice Core",
        Rarity = "Rare",
        Type = "Elemental",
        Logia = true,
        Transform3D = nil,
        Price = 750000,
        Element = "Frost",
        Passive = "Hàn Băng Tuyệt Đối (Logia): Miễn nhiễm đòn thường, có Đinh Ba Băng cận chiến và bước đi tạo đường băng.",
        Desc = "Tinh thể băng vĩnh cửu từ Frozen Cyber, chuyên làm choáng diện rộng để mở chuỗi combo.",
        Moves = {
            Z = {Key="Z", Name="Ice Shards • Băng Tiêu Tam Liên", AwakenedName="Hailstorm Lances • Mưa Thương Băng Giá", Mastery=1, Cooldown=5, Cost=10, Range=26, Multiplier=2.5, Break=25, Element="Frost", Desc="Phóng 3 luồng gai băng chạy dọc mặt đất đóng băng mục tiêu."},
            X = {Key="X", Name="Glacial Surge • Băng Sơn Trỗi Dậy", AwakenedName="Permafrost Avalanche • Tuyết Lở Vĩnh Cửu", Mastery=45, Cooldown=9, Cost=15, Range=24, Multiplier=3.0, Break=30, Element="Frost", Desc="Triệu hồi tảng băng khổng lồ hất tung và khóa cứng kẻ địch."},
            C = {Key="C", Name="Ice Bird • Băng Điểu Xung Kích", AwakenedName="Cryo Phoenix • Phượng Hoàng Băng Tinh", Mastery=90, Cooldown=12, Cost=18, Range=32, Multiplier=3.5, Break=36, Element="Frost", Desc="Phóng chim băng lao thẳng tới phát nổ thành sương giá."},
            V = {Key="V", Name="Absolute Zero • Tuyệt Độ Hàn Băng", AwakenedName="Glacial Epoch • Kỷ Băng Hà Tối Thượng", Mastery=140, Cooldown=18, Cost=26, Range=28, Multiplier=4.7, Break=52, Element="Frost", Desc="Đóng băng toàn bộ không gian xung quanh bằng bão tuyết vĩnh cửu."},
            F = {Key="F", Name="Ice Skate • Trượt Băng Tốc Độ", AwakenedName="Glacier Glide • Lướt Sóng Hàn Băng", Mastery=25, Cooldown=5.5, Cost=10, Range=26, Multiplier=1.4, Break=12, Element="Frost", Desc="Lướt cực nhanh trên đường băng tinh thể."},
        },
    },
    CelestialLightCore = {
        Id = "CelestialLightCore",
        Name = "Trái Ánh Sáng • Celestial Light Core",
        Rarity = "Rare",
        Type = "Elemental",
        Logia = true,
        Transform3D = nil,
        Price = 1100000,
        Element = "Sky",
        Passive = "Thánh Quang Tốc Độ (Logia): Miễn nhiễm đòn thường, tích hợp Thương Ánh Sáng cận chiến và tốc độ bay nhanh nhất.",
        Desc = "Trái Ánh Sáng huyền thoại giúp cày cấp siêu tốc, bắn mưa tia sáng tầm xa và dịch chuyển tức thời.",
        Moves = {
            Z = {Key="Z", Name="Light Ray • Tia Sáng Phán Quyết", AwakenedName="Divine Arrow • Mũi Tên Thần Quang", Mastery=1, Cooldown=4.8, Cost=10, Range=38, Multiplier=2.7, Break=26, Element="Sky", Desc="Bắn tia sáng tốc độ cực cao phát nổ đẩy lùi mục tiêu."},
            X = {Key="X", Name="Barrage of Light • Mưa Kiếm Ánh Sáng", AwakenedName="Judgement Starfall • Tinh Quang Liên Kích", Mastery=50, Cooldown=8.5, Cost=15, Range=30, Multiplier=3.2, Break=32, Element="Sky", Desc="Phóng hàng chục mũi thương ánh sáng liên hoàn về phía trước."},
            C = {Key="C", Name="Reflection Kick • Phản Quang Cước", AwakenedName="Lightspeed Strike • Bát Chỉ Kính Thiểm", Mastery=100, Cooldown=11, Cost=18, Range=28, Multiplier=3.7, Break=38, Element="Sky", Desc="Dịch chuyển zíc-zắc bằng gương ánh sáng rồi giáng đòn từ trên không."},
            V = {Key="V", Name="Skybeam Barrage • Đại Quang Vũ", AwakenedName="Wrath of Aureon • Thánh Quang Phán Quyết", Mastery=160, Cooldown=17, Cost=25, Range=36, Multiplier=4.9, Break=52, Element="Sky", Desc="Triệu hồi cơn mưa cột sáng khổng lồ từ bầu trời dội xuống."},
            F = {Key="F", Name="Light Flight • Hóa Tia Sáng", AwakenedName="Teleportation Beam • Quang Tốc Dịch Chuyển", Mastery=20, Cooldown=4.5, Cost=8, Range=34, Multiplier=1.6, Break=15, Element="Sky", Desc="Hóa thành tia sáng bay với vận tốc cực đại và đổi hướng linh hoạt."},
        },
    },
    StarforgedMagmaCore = {
        Id = "StarforgedMagmaCore",
        Name = "Trái Dung Nham • Starforged Magma Core",
        Rarity = "Rare",
        Type = "Elemental",
        Logia = true,
        Transform3D = nil,
        Price = 1350000,
        Element = "Sky",
        Passive = "Dung Nham Sao Băng (Logia): Miễn nhiễm đòn thường, bước đi trên biển mây và để lại hồ dung nham đốt cháy liên tục.",
        Desc = "Trái Dung Nham có sát thương đốt theo thời gian (DPS) cao bậc nhất để săn Thủy Quái và vượt Raid.",
        Moves = {
            Z = {Key="Z", Name="Magma Clap • Dung Nham Thiết Chưởng", AwakenedName="Volcanic Eruption • Đại Địa Dung Nham", Mastery=1, Cooldown=5.2, Cost=12, Range=24, Multiplier=2.9, Break=28, Element="Sky", Desc="Đập hai bàn tay dung nham khổng lồ tạo hồ lửa dưới đất."},
            X = {Key="X", Name="Magma Geyser • Suối Phun Núi Lửa", AwakenedName="Hellhound Fang • Nanh Chó Địa Ngục", Mastery=60, Cooldown=9, Cost=16, Range=26, Multiplier=3.4, Break=34, Element="Sky", Desc="Phóng nắm đấm dung nham ngoạm lấy mục tiêu và phun trào."},
            C = {Key="C", Name="Magma Fist • Cú Đấm Nham Thạch", AwakenedName="Starforged Boulder • Thiên Thạch Nóng Chảy", Mastery=115, Cooldown=11.5, Cost=18, Range=32, Multiplier=3.9, Break=40, Element="Sky", Desc="Bắn quả cầu dung nham khổng lồ nổ tung thành nhiều vũng lửa."},
            V = {Key="V", Name="Meteor Volcano • Mưa Sao Băng Dung Nham", AwakenedName="Apocalypse Cataclysm • Đại Hồng Thủy Nham Thạch", Mastery=180, Cooldown=18, Cost=28, Range=36, Multiplier=5.2, Break=55, Element="Sky", Desc="Mưa nắm đấm dung nham liên hoàn phủ kín mặt đất bằng hồ lửa."},
            F = {Key="F", Name="Magma Hound • Cưỡi Thú Dung Nham", AwakenedName="Volcanic Flight • Phi Thăng Nham Thạch", Mastery=30, Cooldown=6, Cost=10, Range=26, Multiplier=1.7, Break=16, Element="Sky", Desc="Cưỡi thú dung nham bay lượn và rải lửa dọc đường."},
        },
    },
    ThunderRumbleCore = {
        Id = "ThunderRumbleCore",
        Name = "Trái Lôi Đình • Thunder Rumble Core",
        Rarity = "Legendary",
        Type = "Elemental",
        Logia = true,
        Transform3D = nil,
        Price = 2100000,
        Element = "Lightning",
        Passive = "Lôi Thần Hộ Thể (Logia): Miễn nhiễm đòn thường, tích lũy 3 tầng Lôi Bộ và làm choáng diện rộng.",
        Desc = "Sức mạnh sấm sét tối thượng với 3 lần dịch chuyển chớp nhoáng và Quả Cầu Lôi Phạt khổng lồ.",
        Moves = {
            Z = {Key="Z", Name="Rumble Dragon • Lôi Long Phá", AwakenedName="Lightning Beast • Kỳ Lân Sấm Sét", Mastery=1, Cooldown=5.5, Cost=12, Range=32, Multiplier=2.9, Break=28, Element="Lightning", Desc="Phóng rồng sấm sét lao thẳng vào mục tiêu gây tê liệt."},
            X = {Key="X", Name="Sky Thunder • Thiên Lôi Giáng Thế", AwakenedName="Thunderstorm Pillar • Cột Sét Phán Quyết", Mastery=75, Cooldown=9.5, Cost=16, Range=30, Multiplier=3.5, Break=36, Element="Lightning", Desc="Giáng cột sét khổng lồ từ đám mây đen xuống vị trí chỉ định."},
            C = {Key="C", Name="StormJudgement • Lôi Phạt Liên Kích", AwakenedName="Hyperion Beam • Pháo Từ Trường Lôi Đế", Mastery=140, Cooldown=12, Cost=20, Range=34, Multiplier=4.0, Break=42, Element="Lightning", Desc="Bắn tia sét hội tụ xuyên thấu từ trên không trung."},
            V = {Key="V", Name="Thunderball Destruction • Quả Cầu Lôi Thần", AwakenedName="Raigo Sphere • Lôi Nghinh Diệt Thế", Mastery=210, Cooldown=19, Cost=30, Range=38, Multiplier=5.4, Break=58, Element="Lightning", Desc="Tạo đại cầu sấm sét khổng lồ rơi xuống làm tê liệt toàn bộ chiến trường."},
            F = {Key="F", Name="Lightning Dash • Lôi Bộ Tam Đoạn", AwakenedName="Thunder Flash • Thiểm Điện Không Gian", Mastery=40, Cooldown=4.5, Cost=10, Range=28, Multiplier=1.8, Break=18, Element="Lightning", Desc="Dịch chuyển tức thời như tia chớp kèm xung điện."},
        },
    },
    AstralGravityCore = {
        Id = "AstralGravityCore",
        Name = "Trái Trọng Lực • Astral Gravity Core",
        Rarity = "Legendary",
        Type = "Natural",
        Logia = false,
        Transform3D = nil,
        Price = 2300000,
        Element = "Void",
        Passive = "Trường Trọng Lực: Đè nặng không gian xung quanh, kéo kẻ địch về tâm vụ nổ thiên thạch.",
        Desc = "Bẻ cong lực hấp dẫn vũ trụ và triệu hồi mưa thiên thạch khổng lồ giáng xuống chiến trường.",
        Moves = {
            Z = {Key="Z", Name="Gravity Push • Xung Lực Đẩy", AwakenedName="Singularity Repulse • Sóng Xung Kích Vũ Trụ", Mastery=1, Cooldown=5.5, Cost=12, Range=26, Multiplier=2.8, Break=30, Element="Void", Desc="Phóng sóng trọng lực tím đẩy văng và làm choáng kẻ địch."},
            X = {Key="X", Name="Gravity Crush • Vùng Trọng Lực Đè Nén", AwakenedName="Zero-G Collapse • Sụp Đổ Trọng Trường", Mastery=80, Cooldown=10, Cost=16, Range=26, Multiplier=3.4, Break=38, Element="Void", Desc="Tạo trường trọng lực gấp 10 lần ép chặt kẻ địch xuống đất."},
            C = {Key="C", Name="Meteor Strike • Triệu Hồi Thiên Thạch", AwakenedName="Twin Starfall • Song Tinh Giáng Thế", Mastery=150, Cooldown=12.5, Cost=20, Range=36, Multiplier=4.1, Break=44, Element="Void", Desc="Kéo thiên thạch từ tầng khí quyển rơi thẳng vào mục tiêu."},
            V = {Key="V", Name="Astral Meteor Shower • Mưa Thiên Thạch Vũ Trụ", AwakenedName="Cosmic Extinction • Đại Tuyệt Chủng Tinh Vân", Mastery=225, Cooldown=19, Cost=30, Range=40, Multiplier=5.3, Break=56, Element="Void", Desc="Triệu hồi cơn mưa thiên thạch khổng lồ hủy diệt diện rộng."},
            F = {Key="F", Name="Boulder Ride • Cưỡi Đá Không Trung", AwakenedName="Orbital Levitation • Phi Thăng Quỹ Đạo", Mastery=45, Cooldown=6, Cost=10, Range=26, Multiplier=1.5, Break=15, Element="Void", Desc="Tách một khối đá dưới đất và bay lượn bằng trọng lực."},
        },
    },
    DimensionalPortalCore = {
        Id = "DimensionalPortalCore",
        Name = "Trái Không Gian • Dimensional Portal Core",
        Rarity = "Legendary",
        Type = "Natural",
        Logia = false,
        Transform3D = nil,
        Price = 2500000,
        Element = "Void",
        Passive = "Lữ Khách Chiều Không Gian: Cắt xuyên không gian, miễn nhiễm ngắn khi lướt qua cổng và mở cổng dịch chuyển toàn bản đồ.",
        Desc = "Vua cơ động và PvP với khả năng mở chiều không gian 4D và dịch chuyển tức thời tới mọi hòn đảo.",
        Moves = {
            Z = {Key="Z", Name="Portal Dash • Đột Kích Xuyên Không", AwakenedName="Rift Slash • Trảm Phá Chiều Không Gian", Mastery=1, Cooldown=5, Cost=12, Range=28, Multiplier=2.8, Break=28, Element="Void", Desc="Mở cổng không gian lao xuyên qua mục tiêu và tung liên hoàn trảm."},
            X = {Key="X", Name="Parallel Escape • Ẩn Thân Dị Giới", AwakenedName="Void Shift • Bước Nhảy Hư Không", Mastery=85, Cooldown=10, Cost=16, Range=26, Multiplier=3.2, Break=32, Element="Void", Desc="Bước vào khe nứt không gian vô địch rồi bất ngờ xuất hiện kích nổ."},
            C = {Key="C", Name="World Warp • Cổng Dịch Chuyển Thế Giới", AwakenedName="Nexus Gate • Đại Cổng Liên Hải", Mastery=160, Cooldown=12, Cost=20, Range=34, Multiplier=3.8, Break=38, Element="Void", Desc="Mở vòng tròn dịch chuyển không gian cuốn kẻ địch vào tâm bão."},
            V = {Key="V", Name="Dimensional Rift • Chiều Không Gian Thứ Tư", AwakenedName="Pocket Universe • Lãnh Địa Hư Không Tuyệt Đối", Mastery=240, Cooldown=20, Cost=30, Range=36, Multiplier=5.1, Break=54, Element="Void", Desc="Kéo toàn bộ kẻ địch xung quanh vào lãnh địa không gian riêng và trảm kích."},
            F = {Key="F", Name="Quantum Leap • Bước Nhảy Lượng Tử", AwakenedName="Flash Portal • Cổng Chớp Nhoáng", Mastery=50, Cooldown=4, Cost=8, Range=32, Multiplier=1.7, Break=16, Element="Void", Desc="Đặt hai cổng không gian liên tiếp để lướt tức thời."},
        },
    },
    SolarTitanCore = {
        Id = "SolarTitanCore",
        Name = "Trái Kim Thân (Buddha) • Solar Titan Core",
        Rarity = "Legendary",
        Type = "Beast",
        Logia = false,
        Transform3D = "SolarTitan",
        Price = 2800000,
        Element = "Sky",
        Passive = "Kim Thân Khổng Lồ (3D Transform): Hóa thân thành Đại Tượng Hoàng Kim cao gấp 2.4 lần, giảm 55% sát thương nhận vào và tăng tầm đánh cận chiến/kiếm gấp 3 lần!",
        Desc = "Trái Thần Phật Hoàng Kim số 1 để cày cấp và vượt Raid, sở hữu mô hình biến hình 3D Kim Thân hào quang rực sáng.",
        Moves = {
            Z = {Key="Z", Name="Transform: Solar Titan • Hóa Kim Thân Khổng Lồ", AwakenedName="Awakened Shift: Golden Colossus • Đại Kim Thân Thức Tỉnh", Mastery=1, Cooldown=4, Cost=10, Range=26, Multiplier=2.6, Break=35, Element="Sky", Desc="Biến hình 3D thành Kim Thân Hoàng Kim khổng lồ với vòng hào quang thánh quang, giảm 55% sát thương nhận vào!"},
            X = {Key="X", Name="Heavenly Impact • Thiên Địa Chấn Động", AwakenedName="Halo Shockwave • Hào Quang Chấn Thiên", Mastery=70, Cooldown=9, Cost=16, Range=28, Multiplier=3.4, Break=40, Element="Sky", Desc="Giậm mạnh tạo sóng xung kích ánh sáng vàng hất tung mọi kẻ địch."},
            C = {Key="C", Name="Solar Palm • Như Lai Thần Chưởng", AwakenedName="Light of Annihilation • Thánh Quang Diệt Độ", Mastery=140, Cooldown=12, Cost=20, Range=32, Multiplier=4.1, Break=45, Element="Sky", Desc="Phóng luồng chưởng lực ánh sáng khổng lồ xuyên thủng phòng tuyến."},
            V = {Key="V", Name="Twilight of the Gods • Hoàng Hôn Chư Thần", AwakenedName="Divine Retribution • Thiên Phạt Vạn Giới", Mastery=220, Cooldown=18, Cost=28, Range=38, Multiplier=5.5, Break=60, Element="Sky", Desc="Triệu hồi hàng chục cột trụ ánh sáng thần thánh nổ tung quanh bản thân."},
            F = {Key="F", Name="Titan Leap • Bước Nhảy Kim Thân", AwakenedName="Heavenward Stomp • Đạp Mây Giáng Thế", Mastery=35, Cooldown=6, Cost=10, Range=28, Multiplier=2.2, Break=25, Element="Sky", Desc="Nhảy vọt lên không trung rồi đáp xuống tạo chấn động lớn."},
        },
    },
    AetherflowCore = {
        Id = "AetherflowCore",
        Name = "Trái Tinh Thể (Dough) • Aetherflow Core",
        Rarity = "Mythical",
        Type = "Elemental",
        Logia = true,
        Transform3D = nil,
        Price = 3400000,
        Element = "Frost",
        Passive = "Tinh Thể Đặc Biệt (Special Logia): Miễn nhiễm đòn thường như Logia và cường hóa quyền cước bằng gai tinh thể Haki.",
        Desc = "Trái Thần Thoại Aetherflow (Dough V2) với chuỗi combo trói chân, đấm liên hoàn trên không và lăn bánh xe gai tinh thể.",
        Moves = {
            Z = {Key="Z", Name="Missile Jab • Thiết Quyền Tinh Thể", AwakenedName="Piercing Aether Fist • Đại Pháo Tinh Thể", Mastery=1, Cooldown=5.5, Cost=12, Range=30, Multiplier=3.1, Break=32, Element="Frost", Desc="Nén nắm đấm tinh thể khổng lồ bắn nổ mục tiêu tầm xa."},
            X = {Key="X", Name="Aether Spikes • Gai Tinh Thể Trỗi Dậy", AwakenedName="Pastry River • Dòng Chảy Tinh Thể Không Gian", Mastery=90, Cooldown=9.5, Cost=16, Range=28, Multiplier=3.7, Break=38, Element="Frost", Desc="Triệu hồi gai tinh thể từ mặt đất cuốn kẻ địch lên không rồi đập mạnh."},
            C = {Key="C", Name="Carved Aether • Vòng Xoáy Nghiền Nát", AwakenedName="Piercing Clothesline • Bánh Xe Gai Hủy Diệt", Mastery=175, Cooldown=12, Cost=20, Range=30, Multiplier=4.3, Break=46, Element="Frost", Desc="Hóa thành bánh xe gai tinh thể cuốn theo mục tiêu rồi chokeslam xuống đất."},
            V = {Key="V", Name="Restless Aether Barrage • Liên Hoàn Bách Quyền", AwakenedName="Aether Fist Fusillade • Vạn Quyền Diệt Thế", Mastery=260, Cooldown=19, Cost=30, Range=36, Multiplier=5.7, Break=62, Element="Frost", Desc="Mở hàng chục cổng không gian tung mưa nắm đấm bọc Haki cực đại."},
            F = {Key="F", Name="Roller Donut • Bánh Xe Tốc Độ", AwakenedName="Scorching Spin • Vòng Quay Tinh Thể", Mastery=50, Cooldown=5.5, Cost=10, Range=28, Multiplier=1.9, Break=20, Element="Frost", Desc="Hóa thành vòng tròn tinh thể lăn cực nhanh qua địa hình và trên biển."},
        },
    },
    AbyssalSovereignCore = {
        Id = "AbyssalSovereignCore",
        Name = "Trái Long Vương Hư Không • Abyssal Sovereign Core",
        Rarity = "Mythical",
        Type = "Beast",
        Logia = false,
        Transform3D = "AbyssalSovereign",
        Price = 5000000,
        Element = "Void",
        Passive = "Song Long Biến Hình (2 Dạng & 2 Bộ Kỹ Năng): [Dạng 1 - Bán Long Nhân] thiên về cận chiến tốc độ & Hỏa Long Trảo; [Dạng 2 - Thái Cổ Long Hoàng] hóa Rồng Khổng Lồ 3D bay lượn hủy diệt diện rộng!",
        Desc = "Trái Thần Thoại tối thượng sở hữu 2 Dạng Rồng 3D riêng biệt (Bán Long Nhân & Thái Cổ Long Hoàng) với 2 bộ kỹ năng hoàn toàn khác nhau.",
        Form1Moves = {
            Z = {Key="Z", Name="Draconic Fireball Volley • Hỏa Long Liên Đạn", ShortName="Hỏa Long Đạn", AwakenedName="Crimson Fireball Volley • Hỏa Long Liên Đạn", Mastery=1, Cooldown=4.5, Cost=10, Range=32, Multiplier=3.2, Break=32, Hits=3, Mechanic="HybridFireballVolley", Element="Void", Desc="[Dạng 1 • Bán Long] Bắn liên hoàn 3 quả cầu lửa rồng đỏ thẫm phát nổ liên tiếp vào mục tiêu."},
            X = {Key="X", Name="Hybrid Talon Rend • Bán Long Đột Trảo", ShortName="Bán Long Trảo", AwakenedName="Abyssal Claw Slam • Bán Long Đột Trảo", Mastery=1, Cooldown=7.5, Cost=14, Range=24, Multiplier=3.8, Break=40, Hits=2, Mechanic="HybridTalonRend", Element="Void", Desc="[Dạng 1 • Bán Long] Lao vút 20m chộp cổ mục tiêu bằng song trảo Bán Long rồi quật nổ hắc hỏa."},
            C = {Key="C", Name="Draconic Inferno Vortex • Cuồng Long Lốc Xoáy", ShortName="Cuồng Long Xoáy", AwakenedName="Hybrid Blade Cyclone • Cuồng Long Lốc Xoáy", Mastery=1, Cooldown=10.5, Cost=18, Range=28, Multiplier=4.4, Break=46, Hits=4, Mechanic="HybridInfernoCyclone", Element="Void", Desc="[Dạng 1 • Bán Long] Xoay người tạo cơn lốc lưỡi đao lửa rồng cuốn hút kẻ địch xung quanh vào tâm."},
            V = {Key="V", Name="Dragon Form Shift • Hóa Hình Bán Long / Long Hoàng", ShortName="Chuyển Dạng Rồng", AwakenedName="Sovereign Ascension • Hóa Thái Cổ Long Hoàng", Mastery=1, Cooldown=3.0, Cost=10, Range=36, Multiplier=4.5, Break=50, Mechanic="DragonFormShift", Element="Void", Desc="Chuyển đổi tuần tự: Nhân Dạng -> [Dạng 1] Bán Long Nhân -> [Dạng 2] Chân Thân Thái Cổ Long Hoàng 3D!"},
            F = {Key="F", Name="Hybrid Wing Dash • Long Ảnh Bộ", ShortName="Long Ảnh Bộ", AwakenedName="Crimson Wing Blitz • Long Ảnh Bộ", Mastery=1, Cooldown=4.5, Cost=8, Range=36, Multiplier=2.0, Break=20, Mechanic="HybridWingDash", Element="Void", Desc="[Dạng 1 • Bán Long] Vỗ cánh Bán Long lướt chớp nhoáng 36m để lại tàn ảnh trảo lửa đỏ."},
        },
        Form2Moves = {
            Z = {Key="Z", Name="Sovereign Obliteration Beam • Thái Cổ Long Tức", ShortName="Thái Cổ Long Tức", AwakenedName="Abyssal Sovereign Breath • Thái Cổ Long Tức", Mastery=1, Cooldown=5.5, Cost=14, Range=52, Multiplier=4.8, Break=48, Hits=5, Mechanic="SovereignBeam", Element="Void", Desc="[Dạng 2 • Long Hoàng] Há miệng Rồng Khổng Lồ bắn đại trụ laser Hư Không xuyên thấu 52m cày nát mặt đất."},
            X = {Key="X", Name="Sovereign Skyfall Dive • Long Hoàng Giáng Thế", ShortName="Long Hoàng Giáng", AwakenedName="Cataclysmic Dragon Dive • Long Hoàng Giáng Thế", Mastery=1, Cooldown=9.0, Cost=18, Range=38, Multiplier=5.5, Break=62, Hits=3, Mechanic="SovereignSkyfallDive", Element="Void", Desc="[Dạng 2 • Long Hoàng] Bay vọt lên không trung rồi bổ nhào xuống như thiên thạch rồng, tạo 3 vòng sóng chấn động khổng lồ."},
            C = {Key="C", Name="Apocalyptic Eclipse Starshower • Vạn Long Thiên Hỏa Vũ", ShortName="Vạn Long Hỏa Vũ", AwakenedName="Eclipse Dragon Starshower • Vạn Long Thiên Hỏa Vũ", Mastery=1, Cooldown=12.5, Cost=24, Range=48, Multiplier=6.4, Break=68, Hits=6, Mechanic="SovereignStarshower", Element="Void", Desc="[Dạng 2 • Long Hoàng] Mở Cổng Nhật Thực Hư Không trên bầu trời, trút mưa 12 thiên thạch rồng hủy diệt diện rộng 48m."},
            V = {Key="V", Name="Revert Sovereign Form • Thu Hồi Long Hồn", ShortName="Thu Hồi Rồng", AwakenedName="Revert Sovereign Form • Thu Hồi Long Hồn", Mastery=1, Cooldown=3.0, Cost=0, Range=28, Multiplier=2.0, Break=20, Mechanic="DragonFormShift", Element="Void", Desc="[Dạng 2 • Long Hoàng] Thu hồi Chân Thân Thái Cổ Long Hoàng trở về Nhân Dạng."},
            F = {Key="F", Name="Sovereign Supersonic Flight • Long Vũ Cửu Thiên", ShortName="Long Vũ Cửu Thiên", AwakenedName="Abyssal Supersonic Soar • Long Vũ Cửu Thiên", Mastery=1, Cooldown=4.5, Cost=10, Range=60, Multiplier=2.8, Break=30, Mechanic="SovereignSupersonicFlight", Element="Void", Desc="[Dạng 2 • Long Hoàng] Vỗ đôi cánh Hắc Long Khổng Lồ bay siêu thanh 60m kèm 6 vòng sóng xung kích Mach Cone."},
        },
        Moves = {
            Z = {Key="Z", Name="Draconic Fireball Volley • Hỏa Long Liên Đạn", ShortName="Hỏa Long Đạn", AwakenedName="Abyssal Sovereign Breath • Thái Cổ Long Tức", Mastery=1, Cooldown=4.5, Cost=10, Range=32, Multiplier=3.2, Break=32, Element="Void", Desc="[Dạng 1] Bắn 3 cầu lửa rồng liên hoàn | [Dạng 2] Phun đại trụ laser Thái Cổ Long Tức 52m."},
            X = {Key="X", Name="Hybrid Talon Rend • Bán Long Đột Trảo", ShortName="Bán Long Trảo", AwakenedName="Sovereign Skyfall Dive • Long Hoàng Giáng Thế", Mastery=1, Cooldown=7.5, Cost=14, Range=24, Multiplier=3.8, Break=40, Element="Void", Desc="[Dạng 1] Lao tới chộp cổ bằng vuốt Bán Long | [Dạng 2] Bổ nhào từ không trung chấn vỡ mặt đất."},
            C = {Key="C", Name="Draconic Inferno Vortex • Cuồng Long Lốc Xoáy", ShortName="Cuồng Long Xoáy", AwakenedName="Apocalyptic Eclipse Starshower • Vạn Long Hỏa Vũ", Mastery=1, Cooldown=10.5, Cost=18, Range=28, Multiplier=4.4, Break=46, Element="Void", Desc="[Dạng 1] Xoay lốc đao lửa cuốn kẻ địch | [Dạng 2] Mở Cổng Nhật Thực trút mưa 12 thiên thạch rồng."},
            V = {Key="V", Name="Dragon Form Shift • Hóa Bán Long / Long Hoàng 3D", ShortName="Chuyển Dạng Rồng", AwakenedName="Sovereign Ascension • Chân Thân Hắc Long Đế Vương", Mastery=1, Cooldown=3.0, Cost=10, Range=36, Multiplier=4.5, Break=50, Element="Void", Desc="Nhấn [V] lần 1 hóa Dạng 1 (Bán Long Nhân), nhấn [V] lần 2 hóa Dạng 2 (Thái Cổ Long Hoàng Khổng Lồ), nhấn [V] lần 3 thu hồi!"},
            F = {Key="F", Name="Hybrid Wing Dash • Long Ảnh Bộ", ShortName="Long Ảnh Bộ", AwakenedName="Sovereign Supersonic Flight • Long Vũ Cửu Thiên", Mastery=1, Cooldown=4.5, Cost=8, Range=36, Multiplier=2.0, Break=20, Element="Void", Desc="[Dạng 1] Lướt nhanh để lại tàn ảnh lửa | [Dạng 2] Bay siêu thanh 60m tạo sóng xung kích Mach Cone."},
        },
    },
}

-- ============================================================================
-- 5 CANONICAL MARTIAL ARTS STYLES + LEGACY ALIASES (SLOT 1: MELEE)
-- ============================================================================
C.StyleOrder = {
    "skyborn_combat",
    "jade_dragon",
    "thunder_talon",
    "solar_ashura",
    "celestial_godhuman",
}

C.FightingStyles = {
    skyborn_combat = {
        Id = "skyborn_combat",
        Name = "Võ Thuật Skyborn - Skyborn Combat",
        PriceGold = 0,
        PriceShards = 0,
        Element = "Sky",
        Desc = "Quyền pháp chưởng phong linh hoạt của chiến binh bầu trời với chuỗi 4 đòn M1 Kata cân bằng.",
        Moves = {
            Z = {Key="Z", Name="Gale Palm Thrust - Kình Phong Chưởng", Mastery=1, Cooldown=4.5, Cost=8, Range=22, Multiplier=2.25, Break=22, Element="Sky", Desc="Lao nhanh về phía trước tung chưởng kình phong xuyên thấu."},
            X = {Key="X", Name="Rising Sky Kick - Thăng Thiên Cước", Mastery=50, Cooldown=7.0, Cost=12, Range=20, Multiplier=2.75, Break=28, Element="Sky", Desc="Tung cước xoáy hướng thiên tạo lốc khí hất tung kẻ địch."},
            C = {Key="C", Name="Aether Flurry - Liên Hoàn Bách Chưởng", Mastery=100, Cooldown=9.5, Cost=16, Range=24, Multiplier=3.45, Break=35, Element="Sky", Desc="Giải phóng liên hoàn chưởng Aether tốc độ cao chấn văng mục tiêu."},
        },
    },
    jade_dragon = {
        Id = "jade_dragon",
        Name = "Long Quyền Ngọc Bích - Jade Dragon Kung Fu",
        PriceGold = 450000,
        PriceShards = 350,
        Element = "Jade",
        Desc = "Tuyệt học Long Trảo xoáy ngọc bích chuyên phá giáp, cuốn hút mục tiêu và gầm vang long khí.",
        Moves = {
            Z = {Key="Z", Name="Jade Claw Rush - Ngọc Long Đột Trảo", Mastery=1, Cooldown=4.8, Cost=10, Range=26, Multiplier=2.55, Break=26, Element="Jade", Desc="Lướt xoáy 3 nhịp cào xé mục tiêu bằng trảo rồng ngọc bích."},
            X = {Key="X", Name="Coiling Dragon Sweep - Cuộn Long Quét Địa", Mastery=50, Cooldown=7.8, Cost=14, Range=24, Multiplier=3.10, Break=32, Element="Jade", Desc="Quét vòng xoáy long khí cuốn kẻ địch xung quanh vào tâm chấn."},
            C = {Key="C", Name="Emerald Dragon Roar - Ngọc Long Cửu Thiên Hống", Mastery=100, Cooldown=10.8, Cost=18, Range=34, Multiplier=3.95, Break=42, Element="Jade", Desc="Phóng luồng long xung ngọc bích xuyên thấu hàng ngũ kẻ địch."},
        },
    },
    thunder_talon = {
        Id = "thunder_talon",
        Name = "Lôi Trảo Cước - Thunder Talon",
        PriceGold = 1250000,
        PriceShards = 1200,
        Element = "Lightning",
        Desc = "Cước pháp sấm sét tốc độ ánh sáng với M1 Kata siêu tốc và chuỗi đòn giáng lôi làm tê liệt.",
        Moves = {
            Z = {Key="Z", Name="Volt Snap Kick - Điện Thiểm Cước", Mastery=1, Cooldown=4.5, Cost=10, Range=28, Multiplier=2.75, Break=28, Element="Lightning", Desc="Biến ảnh áp sát tung cú đá chớp giật làm choáng tức thời."},
            X = {Key="X", Name="Lightning Drop Heel - Thiên Lôi Giáng Cước", Mastery=50, Cooldown=7.5, Cost=15, Range=26, Multiplier=3.40, Break=35, Element="Lightning", Desc="Bật cao rồi bổ gót chân sấm sét xuống đất gây nổ điện trường."},
            C = {Key="C", Name="Storm Talon Barrage - Bão Lôi Vạn Trảo", Mastery=100, Cooldown=10.5, Cost=20, Range=30, Multiplier=4.30, Break=46, Element="Lightning", Desc="Dịch chuyển chớp nhoáng 6 nhịp càn quét mục tiêu trong bão sét."},
        },
    },
    solar_ashura = {
        Id = "solar_ashura",
        Name = "Thái Dương Tu La Quyền - Solar Ashura Fist",
        PriceGold = 2200000,
        PriceShards = 2200,
        Element = "Flame",
        Desc = "Trọng quyền rực lửa mặt trời mang sức phá vỡ Break Gauge khủng khiếp và thiêu đốt liên tục.",
        Moves = {
            Z = {Key="Z", Name="Ignited Knuckle - Viêm Dương Thiết Quyền", Mastery=1, Cooldown=5.0, Cost=11, Range=24, Multiplier=3.00, Break=32, Element="Flame", Desc="Đấm bùng nổ hỏa cầu thái dương thiêu đốt mục tiêu."},
            X = {Key="X", Name="Eruption Uppercut - Dung Nham Xung Thiên Quyền", Mastery=50, Cooldown=8.2, Cost=16, Range=24, Multiplier=3.70, Break=40, Element="Flame", Desc="Tung cú móc ngược kích hoạt cột lửa phun trào dưới chân địch."},
            C = {Key="C", Name="Ashura Sunburst - Tu La Nhật Thực Bạo", Mastery=100, Cooldown=11.5, Cost=22, Range=28, Multiplier=4.65, Break=52, Element="Flame", Desc="Hóa thân Tu La giáng đại nhật bùng nổ hủy diệt toàn chiến trường."},
        },
    },
    celestial_godhuman = {
        Id = "celestial_godhuman",
        Name = "Thiên Thần Tuyệt Kỹ - Celestial Godhuman",
        PriceGold = 3500000,
        PriceShards = 3500,
        Element = "Celestial",
        Desc = "Đỉnh cao võ học hợp nhất lục giới, tung thần quyền tinh tú chấn vỡ không gian.",
        Moves = {
            Z = {Key="Z", Name="Soaring Beast Barrage - Bách Thú Tinh Quyền", Mastery=1, Cooldown=4.8, Cost=12, Range=32, Multiplier=3.35, Break=36, Element="Celestial", Desc="Lao xuyên mục tiêu kèm hàng loạt tàn ảnh thần quyền bùng nổ."},
            X = {Key="X", Name="Heaven & Earth Shatter - Thiên Địa Phá Toái", Mastery=50, Cooldown=8.0, Cost=18, Range=30, Multiplier=4.25, Break=48, Element="Celestial", Desc="Tụ lực tinh hà đập vỡ mặt đất giải phóng sóng thần quang diện rộng."},
            C = {Key="C", Name="Sixth Realm Celestial Impact - Lục Giới Thần Xung", Mastery=100, Cooldown=11.8, Cost=24, Range=36, Multiplier=5.45, Break=62, Element="Celestial", Desc="Áp sát siêu thanh tung cú đấm Lục Giới xuyên phá mọi phòng ngự."},
        },
    },
    SkybornCombat = {
        Id = "SkybornCombat",
        Name = "Võ Thuật Skyborn • Skyborn Combat",
        PriceGold = 0,
        PriceShards = 0,
        Element = "Sky",
        Desc = "Quyền pháp căn bản của các chiến binh bầu trời, cân bằng giữa tốc độ và phòng ngự.",
        Moves = {
            Z = {Key="Z", Name="Quick Tackle • Đột Kích Sơ Khai", Mastery=1, Cooldown=4.5, Cost=8, Range=18, Multiplier=2.1, Break=20, Element="Sky", Desc="Lao nhanh về phía trước tung cú đấm kình phong trực diện."},
            X = {Key="X", Name="Ground Smash • Chấn Địa Xung Thiên", Mastery=1, Cooldown=7.0, Cost=12, Range=20, Multiplier=2.6, Break=26, Element="Sky", Desc="Đấm xuống mặt đất tạo lốc xoáy chấn động hất tung kẻ địch."},
            C = {Key="C", Name="Skyborn Combo • Liên Hoàn Bách Quyền", Mastery=1, Cooldown=9.5, Cost=16, Range=22, Multiplier=3.2, Break=32, Element="Sky", Desc="Tung chuỗi liên hoàn quyền tốc độ cao kết thúc bằng cú đá xoáy."},
            V = {Key="V", Name="Heaven's Ascent • Thiên Phạt Sơ Khai", Mastery=1, Cooldown=14.0, Cost=22, Range=28, Multiplier=4.0, Break=42, Element="Sky", Desc="Tụ khí bay lên không trung rồi giáng đòn đại chấn địa hủy diệt."},
            F = {Key="F", Name="Cloud Stride • Bộ Pháp Cưỡi Gió", Mastery=1, Cooldown=5.0, Cost=8, Range=26, Multiplier=1.4, Break=12, Element="Sky", Desc="Đạp mây lướt nhanh về phía trước tạo sóng xung kích."},
        },
    },
    SkyStep = {
        Id = "SkyStep",
        Name = "Thiên Cước • Sky Step (Death Step)",
        PriceGold = 150000,
        PriceShards = 0,
        Element = "Sky",
        Desc = "Tuyệt kỹ cước pháp rực lửa trên không, xoay vòng tạo lốc lửa thiêu đốt.",
        Moves = {
            Z = {Key="Z", Name="Rocket Kick • Phi Cước Hỏa Tiễn", Mastery=1, Cooldown=5, Cost=10, Range=20, Multiplier=2.4, Break=24, Element="Sky", Desc="Phóng cước trên không lao thẳng vào mục tiêu."},
            X = {Key="X", Name="Wind Bullet • Phong Cước Phá", Mastery=40, Cooldown=8, Cost=14, Range=24, Multiplier=2.9, Break=28, Element="Sky", Desc="Đá xoáy tạo lưỡi gió lửa tầm trung đẩy lùi kẻ địch."},
            C = {Key="C", Name="Vermilion Drill • Hỏa Vũ Thiên Cước", Mastery=90, Cooldown=11, Cost=18, Range=22, Multiplier=3.6, Break=36, Element="Sky", Desc="Xoay tròn tạo bão lửa dưới chân nghiền nát đối thủ."},
        },
    },
    GlacialFist = {
        Id = "GlacialFist",
        Name = "Hàn Băng Quyền • Glacial Fist (Sharkman Karate)",
        PriceGold = 750000,
        PriceShards = 500,
        Element = "Frost",
        Desc = "Võ thuật dòng chảy băng giá với tốc độ ra đòn M1 cực nhanh và sóng xung kích xuyên giáp.",
        Moves = {
            Z = {Key="Z", Name="Twelve Water Palms • Thập Nhị Hàn Chưởng", Mastery=1, Cooldown=5, Cost=10, Range=20, Multiplier=2.6, Break=26, Element="Frost", Desc="Lao tới tung 12 chưởng băng liên hoàn rồi đẩy văng mục tiêu."},
            X = {Key="X", Name="Pressure Vortex • Xoáy Nước Áp Suất", Mastery=60, Cooldown=8.5, Cost=15, Range=26, Multiplier=3.1, Break=32, Element="Frost", Desc="Phóng xoáy nước băng giá kéo kẻ địch lại gần."},
            C = {Key="C", Name="Great Sea Spear • Đại Hải Băng Thương", Mastery=120, Cooldown=11.5, Cost=18, Range=24, Multiplier=3.9, Break=40, Element="Frost", Desc="Hội tụ dòng chảy hàn băng đâm xuyên và làm choáng diện rộng."},
        },
    },
    ElectricClaw = {
        Id = "ElectricClaw",
        Name = "Lôi Trảo • Electric Claw",
        PriceGold = 1500000,
        PriceShards = 1500,
        Element = "Lightning",
        Desc = "Trảo pháp lôi điện tốc độ ánh sáng, chuyên áp sát tức thời và kết liễu mục tiêu.",
        Moves = {
            Z = {Key="Z", Name="Electric Rampage • Cuồng Lôi Trảo", Mastery=1, Cooldown=5, Cost=10, Range=24, Multiplier=2.8, Break=28, Element="Lightning", Desc="Lướt nhanh cào xé mục tiêu bằng vuốt điện liên hoàn rồi nổ sét."},
            X = {Key="X", Name="Lightning Thrust • Lôi Kích Xuyên Thấu", Mastery=80, Cooldown=8, Cost=15, Range=28, Multiplier=3.4, Break=34, Element="Lightning", Desc="Hóa thành tia chớp đâm xuyên qua hàng phòng ngự kẻ địch."},
            C = {Key="C", Name="Thunderclap & Flash • Lôi Đình Nhất Thiểm", Mastery=160, Cooldown=11, Cost=20, Range=28, Multiplier=4.2, Break=44, Element="Lightning", Desc="Dịch chuyển chớp nhoáng 6 lần quanh mục tiêu rồi giáng thiên lôi."},
        },
    },
    AbyssalTalon = {
        Id = "AbyssalTalon",
        Name = "Long Trảo Hư Không • Abyssal Talon (Dragon Talon)",
        PriceGold = 2500000,
        PriceShards = 3000,
        Element = "Void",
        Desc = "Tuyệt kỹ Long Trảo bọc hắc hỏa hư không, gây sát thương bùng nổ và thiêu đốt linh hồn.",
        Moves = {
            Z = {Key="Z", Name="Talon Lighter • Hắc Long Trảo", Mastery=1, Cooldown=5.5, Cost=12, Range=22, Multiplier=3.0, Break=32, Element="Void", Desc="Lao tới chụp cổ mục tiêu và kích nổ ngọn lửa rồng hư không."},
            X = {Key="X", Name="Ember Annihilation • Long Hỏa Xung Kích", Mastery=100, Cooldown=8.5, Cost=16, Range=28, Multiplier=3.6, Break=38, Element="Void", Desc="Phóng rồng lửa tím càn quét đường thẳng để lại vệt lửa cháy."},
            C = {Key="C", Name="Infernal Vortex • Vòng Xoáy Hắc Long", Mastery=200, Cooldown=12, Cost=20, Range=28, Multiplier=4.5, Break=48, Element="Void", Desc="Đập mạnh xuống đất tạo đại hỏa ngục hư không bao trùm chiến trường."},
        },
    },
    CelestialGodhuman = {
        Id = "CelestialGodhuman",
        Name = "Thần Quyền Tối Thượng • Celestial Godhuman",
        PriceGold = 5000000,
        PriceShards = 5000,
        Element = "Sky",
        Desc = "Đỉnh cao võ học hợp nhất cả 5 trường phái bầu trời, phát ra hào quang thần quyền cực đại.",
        Moves = {
            Z = {Key="Z", Name="Soaring Beast • Bách Thú Thần Quyền", Mastery=1, Cooldown=5, Cost=12, Range=28, Multiplier=3.2, Break=35, Element="Sky", Desc="Lao vút qua mục tiêu kèm hàng chục tàn ảnh thần quyền bùng nổ."},
            X = {Key="X", Name="Heaven and Earth • Thiên Địa Đồng Quy", Mastery=125, Cooldown=8.5, Cost=16, Range=30, Multiplier=3.9, Break=42, Element="Sky", Desc="Tụ lực giải phóng quả cầu năng lượng thần thánh bao phủ diện rộng."},
            C = {Key="C", Name="Sixth Realm Gun • Lục Đạo Thần Xung", Mastery=250, Cooldown=11.5, Cost=22, Range=32, Multiplier=4.9, Break=55, Element="Sky", Desc="Áp sát với tốc độ siêu thanh và tung cú đấm Lục Đạo chấn vỡ không gian."},
        },
    },
}

C.Companions = {}

C.Enemies = {
    -- Sea 1: Golden Sky Mobs & Bosses (Lv. 1 - 700)
    TrainingDrone = {Name="Training Drone", Level=10, VisualAsset="TrainingDrone", Element="Sky", HP=85, ATK=8, Attack=8, DEF=0, Defense=0, XP=2400, Gold=120, Range=6, Speed=9, Aggro=30, Leash=30, Drop="SkyIron"},
    SkyPirate = {Name="Sky Pirate", Level=75, VisualAsset="SkyPirate", Element="Sky", HP=145, ATK=12, Attack=12, DEF=3, Defense=3, XP=4800, Gold=180, Range=7, Speed=11, Aggro=30, Leash=30, Drop="SkyIron"},
    CorruptedGuard = {Name="Corrupted Guard", Level=175, VisualAsset="CorruptedGuard", Element="Sky", HP=210, ATK=16, Attack=16, DEF=5, Defense=5, XP=8500, Gold=260, Range=7, Speed=11, Aggro=34, Leash=34, Drop="SunshardCore"},
    LightArcher = {Name="Light Archer", Level=325, VisualAsset="LightArcher", Element="Sky", HP=260, ATK=20, Attack=20, DEF=6, Defense=6, XP=14000, Gold=350, Range=27, Speed=9, Aggro=32, Leash=32, Ranged=true, Drop="CelestialFeather"},
    SunshardRoyalGuard = {Name="Sunshard Royal Guard", Level=450, VisualAsset="SunshardRoyalGuard", Element="Sky", HP=360, ATK=24, Attack=24, DEF=8, Defense=8, XP=22000, Gold=450, Range=7.5, Speed=11, Aggro=34, Leash=38, Drop="SunshardCore"},
    GoldenKnight = {Name="Golden Knight", Level=500, VisualAsset="GoldenKnight", Element="Sky", HP=920, ATK=32, Attack=32, DEF=14, Defense=14, XP=45000, Gold=950, Range=10, Speed=10, Aggro=35, Leash=35, Elite=true, Drop="SunshardCore"},
    SunshardTemplar = {Name="Sunshard Templar", Level=575, VisualAsset="SunshardTemplar", Element="Sky", HP=540, ATK=28, Attack=28, DEF=11, Defense=11, XP=32000, Gold=650, Range=8, Speed=11, Aggro=34, Leash=42, Drop="SunshardCore"},
    AureonSentinel = {Name="AUREON SENTINEL", Level=700, VisualAsset="AureonSentinel", Element="Sky", HP=4200, ATK=42, Attack=42, DEF=18, Defense=18, XP=180000, Gold=5000, Range=16, Speed=9, Aggro=47, Leash=47, Boss=true, Drop="CoreEssence"},
    EnergyPylon = {Name="Energy Pylon", Level=700, VisualAsset="EnergyPylon", Element="Sky", HP=240, ATK=0, Attack=0, DEF=0, Defense=0, XP=0, Gold=0, Range=0, Speed=0, Aggro=0, Leash=0},

    -- Sea 2: Frozen Cyber Mobs & Bosses (Lv. 700 - 1500)
    FrostDrone = {Name="Frost Automaton", Level=750, VisualAsset="FrostDrone", Element="Frost", HP=780, ATK=38, Attack=38, DEF=14, Defense=14, Speed=14, Range=6.5, Aggro=38, Leash=55, XP=65000, Gold=1200, Drop="SkyIron"},
    FrostAutomaton = {Name="Frost Automaton", Level=750, VisualAsset="FrostAutomaton", Element="Frost", HP=780, ATK=38, Attack=38, DEF=14, Defense=14, Speed=14, Range=6.5, Aggro=38, Leash=55, XP=65000, Gold=1200, Drop="SkyIron"},
    CyberMercenary = {Name="Cyber Mercenary", Level=875, VisualAsset="CyberMercenary", Element="Frost", HP=920, ATK=44, Attack=44, DEF=16, Defense=16, Speed=14, Range=24, Aggro=42, Leash=58, Ranged=true, XP=85000, Gold=1500, Drop="SkyIron"},
    CryoGuard = {Name="Cryo Vanguard", Level=1025, VisualAsset="CryoGuard", Element="Frost", HP=1250, ATK=50, Attack=50, DEF=20, Defense=20, Speed=14, Range=7, Aggro=40, Leash=60, XP=110000, Gold=1850, Drop="SunshardCore"},
    CryoVanguard = {Name="Cryo Vanguard", Level=1025, VisualAsset="CryoVanguard", Element="Frost", HP=1250, ATK=50, Attack=50, DEF=20, Defense=20, Speed=14, Range=7, Aggro=40, Leash=60, XP=110000, Gold=1850, Drop="SunshardCore"},
    CyberArcher = {Name="Glacial Sniper", Level=1150, VisualAsset="GlacialMarksman", Element="Frost", HP=1080, ATK=54, Attack=54, DEF=18, Defense=18, Speed=13, Range=28, Aggro=45, Leash=60, Ranged=true, XP=125000, Gold=2100, Drop="CelestialFeather"},
    GlacialMarksman = {Name="Glacial Sniper", Level=1150, VisualAsset="GlacialMarksman", Element="Frost", HP=1080, ATK=54, Attack=54, DEF=18, Defense=18, Speed=13, Range=28, Aggro=45, Leash=60, Ranged=true, XP=125000, Gold=2100, Drop="CelestialFeather"},
    GlacialSniper = {Name="Glacial Sniper", Level=1150, VisualAsset="GlacialSniper", Element="Frost", HP=1080, ATK=54, Attack=54, DEF=18, Defense=18, Speed=13, Range=28, Aggro=45, Leash=60, Ranged=true, XP=125000, Gold=2100, Drop="CelestialFeather"},
    MechaDrone = {Name="Mecha Security Drone", Level=1250, VisualAsset="MechaDrone", Element="Frost", HP=1380, ATK=58, Attack=58, DEF=22, Defense=22, Speed=15, Range=7.5, Aggro=42, Leash=60, XP=145000, Gold=2400, Drop="SkyIron"},
    ArcticCorsair = {Name="Arctic Corsair", Level=1375, VisualAsset="ArcticCorsair", Element="Frost", HP=1560, ATK=64, Attack=64, DEF=24, Defense=24, Speed=15, Range=7.5, Aggro=42, Leash=60, XP=175000, Gold=2800, Drop="SkyIron"},
    CryonPillar = {Name="Cryon Glacial Pillar", Level=1500, VisualAsset="CryonPillar", Element="Frost", HP=450, ATK=0, Attack=0, DEF=5, Defense=5, Speed=0, Range=0, Aggro=0, Leash=999, XP=5000, Gold=500},
    CryonPrime = {Name="CRYON PRIME", Level=1500, VisualAsset="CryonPrime", Element="Frost", HP=9800, ATK=74, Attack=74, DEF=30, Defense=30, XP=480000, Gold=12000, Range=24, Speed=0, Aggro=55, Leash=55, Boss=true, Drop="CoreEssence"},

    -- Sea 3: Shadow Realm Mobs & Bosses (Lv. 1500 - 2200)
    VoidPirate = {Name="Void Marauder", Level=1550, VisualAsset="VoidMarauder", Element="Void", HP=1850, ATK=72, Attack=72, DEF=28, Defense=28, Speed=16, Range=7, Aggro=40, Leash=55, XP=220000, Gold=3500, Drop="SunshardCore"},
    VoidMarauder = {Name="Void Marauder", Level=1550, VisualAsset="VoidMarauder", Element="Void", HP=1850, ATK=72, Attack=72, DEF=28, Defense=28, Speed=16, Range=7, Aggro=40, Leash=55, XP=220000, Gold=3500, Drop="SunshardCore"},
    VoidRaider = {Name="Void Raider", Level=1675, VisualAsset="VoidRaider", Element="Void", HP=2050, ATK=78, Attack=78, DEF=30, Defense=30, Speed=16, Range=7.5, Aggro=40, Leash=55, XP=250000, Gold=3800, Drop="SunshardCore"},
    ShadowArcher = {Name="Umbral Ranger", Level=1800, VisualAsset="UmbralBowman", Element="Void", HP=1920, ATK=84, Attack=84, DEF=28, Defense=28, Speed=14, Range=28, Aggro=45, Leash=60, Ranged=true, XP=280000, Gold=4200, Drop="CelestialFeather"},
    UmbralBowman = {Name="Umbral Ranger", Level=1800, VisualAsset="UmbralBowman", Element="Void", HP=1920, ATK=84, Attack=84, DEF=28, Defense=28, Speed=14, Range=28, Aggro=45, Leash=60, Ranged=true, XP=280000, Gold=4200, Drop="CelestialFeather"},
    UmbralRanger = {Name="Umbral Ranger", Level=1800, VisualAsset="UmbralRanger", Element="Void", HP=1920, ATK=84, Attack=84, DEF=28, Defense=28, Speed=14, Range=28, Aggro=45, Leash=60, Ranged=true, XP=280000, Gold=4200, Drop="CelestialFeather"},
    ShadowSpecter = {Name="Shadow Specter", Level=1925, VisualAsset="ShadowSpecter", Element="Void", HP=2400, ATK=90, Attack=90, DEF=32, Defense=32, Speed=17, Range=8, Aggro=44, Leash=60, XP=320000, Gold=4800, Drop="CelestialFeather"},
    AbyssalKnight = {Name="Abyssal Dreadknight", Level=2000, VisualAsset="AbyssalKnight", Element="Void", HP=3200, ATK=98, Attack=98, DEF=38, Defense=38, Speed=14, Range=8, Aggro=42, Leash=65, Elite=true, XP=420000, Gold=6500, Drop="CoreEssence"},
    AbyssalDreadknight = {Name="Abyssal Dreadknight", Level=2000, VisualAsset="AbyssalDreadknight", Element="Void", HP=3200, ATK=98, Attack=98, DEF=38, Defense=38, Speed=14, Range=8, Aggro=42, Leash=65, Elite=true, XP=420000, Gold=6500, Drop="CoreEssence"},
    TerrorSkyShark = {Name="Terror Sky-Shark", Level=2100, VisualAsset="TerrorSkyShark", Element="Void", HP=4200, ATK=108, Attack=108, DEF=42, Defense=42, Speed=15, Range=11, Aggro=52, Leash=75, Elite=true, XP=520000, Gold=8500, Drop="CoreEssence"},
    NoxarVoidFX = {Name="Void Singularity", Level=2200, VisualAsset="NoxarVoidFX", Element="Void", HP=850, ATK=0, Attack=0, DEF=10, Defense=10, Speed=0, Range=0, Aggro=0, Leash=999, XP=15000, Gold=1200},
    Noxar = {Name="NOXAR • VOID SOVEREIGN", Level=2200, VisualAsset="Noxar", Element="Void", HP=18500, ATK=120, Attack=120, DEF=45, Defense=45, XP=950000, Gold=25000, Range=26, Speed=0, Aggro=58, Leash=58, Boss=true, Drop="CoreEssence"},

    -- Sea Event & Island Raid Bosses (Grand Sky Seas v12 Rigged Blender Models)
    PirateCaptainVance = {Name="CAPTAIN VANCE • ĐÔ ĐỐC KHÔNG TẶC", Level=350, VisualAsset="PirateCaptainVance", Element="Sky", HP=2800, ATK=36, Attack=36, DEF=16, Defense=16, XP=85000, Gold=3500, Range=14, Speed=12, Aggro=42, Leash=50, Boss=true, Drop="SunshardCore"},
    OrderCyborg = {Name="ORDER • LÕI LƯỢNG TỬ TỐI THƯỢNG", Level=1250, VisualAsset="OrderCyborg", Element="Frost", HP=7800, ATK=68, Attack=68, DEF=28, Defense=28, XP=320000, Gold=8500, Range=18, Speed=13, Aggro=50, Leash=60, Boss=true, Drop="CoreEssence"},
    OrderCyborgBoss = {Name="ORDER • LÕI LƯỢNG TỬ TỐI THƯỢNG", Level=1250, VisualAsset="OrderCyborgBoss", Element="Frost", HP=7800, ATK=68, Attack=68, DEF=28, Defense=28, XP=320000, Gold=8500, Range=18, Speed=13, Aggro=50, Leash=60, Boss=true, Drop="CoreEssence"},
    SkySeaBeast = {Name="SKY SEA BEAST • THỦY QUÁI BIỂN MÂY", Level=1400, VisualAsset="SkySeaBeast", Element="Frost", HP=9200, ATK=72, Attack=72, DEF=30, Defense=30, XP=380000, Gold=11000, Range=26, Speed=8, Aggro=70, Leash=90, Boss=true, Drop="CoreEssence"},
    SoulReaperRift = {Name="SOUL REAPER • TỬ THẦN HƯ KHÔNG", Level=2050, VisualAsset="SoulReaperRift", Element="Void", HP=14500, ATK=105, Attack=105, DEF=40, Defense=40, XP=680000, Gold=18000, Range=20, Speed=13, Aggro=55, Leash=65, Boss=true, Drop="CoreEssence"},
    AbyssalDragonHybrid = {Name="ABYSSAL DRAGON HYBRID • LONG NHÂN HƯ KHÔNG", Level=2125, VisualAsset="AbyssalDragonHybrid", Element="Void", HP=16000, ATK=112, Attack=112, DEF=42, Defense=42, XP=750000, Gold=20000, Range=22, Speed=12, Aggro=65, Leash=80, Boss=true, Drop="CoreEssence"},
    AbyssalLeviathan = {Name="ABYSSAL LEVIATHAN • THỦY TỔ HƯ KHÔNG", Level=2150, VisualAsset="AbyssalLeviathan", Element="Void", HP=17500, ATK=116, Attack=116, DEF=44, Defense=44, XP=850000, Gold=24000, Range=28, Speed=9, Aggro=80, Leash=100, Boss=true, Drop="CoreEssence"},
    AbyssalSovereignDragon = {Name="ABYSSAL SOVEREIGN DRAGON • THÁI CỔ LONG HOÀNG", Level=2300, VisualAsset="AbyssalSovereignDragon", Element="Void", HP=22000, ATK=128, Attack=128, DEF=48, Defense=48, XP=1100000, Gold=32000, Range=28, Speed=10, Aggro=75, Leash=90, Boss=true, Drop="CoreEssence"},

    -- Regional Island & Expansion Realm Bosses (Lv. 100 - 2550 MAX)
    SkyHubWatchCommander = {Name="COMMANDER VALEN • THỦ VỆ SÂN TẬP", Level=100, VisualAsset="SunshardRoyalGuard", Element="Sky", HP=1100, ATK=22, Attack=22, DEF=10, Defense=10, XP=28000, Gold=1200, Range=11, Speed=11, Aggro=36, Leash=42, Boss=true, Drop="SunshardCore"},
    ShrineGuardianBoss = {Name="SHRINE WARDEN ORION • HỘ VỆ ĐIỆN THỜ", Level=225, VisualAsset="SunshardTemplar", Element="Sky", HP=1550, ATK=26, Attack=26, DEF=12, Defense=12, XP=48000, Gold=1800, Range=11, Speed=11, Aggro=36, Leash=42, Boss=true, Drop="SunshardCore"},
    AetherArchonBoss = {Name="ARCHON HELIOS • LINH VỆ AETHER", Level=450, VisualAsset="GoldenKnight", Element="Sky", HP=2100, ATK=30, Attack=30, DEF=14, Defense=14, XP=75000, Gold=2500, Range=12, Speed=11, Aggro=36, Leash=42, Boss=true, Drop="SunshardCore"},
    SolarHighPriestBoss = {Name="HIGH PRIEST SOLARIUS • ĐẠI TƯ TẾ THÁI DƯƠNG", Level=625, VisualAsset="SolarTitanBuddha", Element="Sky", HP=3500, ATK=38, Attack=38, DEF=16, Defense=16, XP=135000, Gold=4200, Range=16, Speed=11, Aggro=45, Leash=55, Boss=true, Drop="CoreEssence"},
    CyberSyndicateBoss = {Name="OVERLORD KRON • TRÙM HẮC THỊ CYBERPORT", Level=950, VisualAsset="CyberMercenary", Element="Frost", HP=5800, ATK=56, Attack=56, DEF=24, Defense=24, XP=240000, Gold=6500, Range=18, Speed=13, Aggro=45, Leash=55, Boss=true, Drop="CoreEssence"},
    PermafrostWardenBoss = {Name="GENERAL BOREAS • THỐNG LĨNH PHÁO ĐÀI BĂNG", Level=1125, VisualAsset="CryoVanguard", Element="Frost", HP=6800, ATK=62, Attack=62, DEF=26, Defense=26, XP=280000, Gold=7500, Range=14, Speed=12, Aggro=45, Leash=55, Boss=true, Drop="CoreEssence"},
    VoidCastellanBoss = {Name="LORD MALAKOR • LÃNH CHÚA DINH THỰ HƯ KHÔNG", Level=1725, VisualAsset="AbyssalDreadknight", Element="Void", HP=12000, ATK=92, Attack=92, DEF=36, Defense=36, XP=520000, Gold=14000, Range=16, Speed=13, Aggro=52, Leash=65, Boss=true, Drop="CoreEssence"},
    UmbralArchfiendBoss = {Name="ARCHFIEND ZERATH • KIẾM MA TINH THỂ ĐEN", Level=1875, VisualAsset="AbyssalDragonHybrid", Element="Void", HP=13500, ATK=98, Attack=98, DEF=38, Defense=38, XP=600000, Gold=16000, Range=18, Speed=13, Aggro=52, Leash=65, Boss=true, Drop="CoreEssence"},
    Sylvaris = {Name="SYLVARIS • ĐẠI CỔ THỤ HOÀNG", Level=2250, VisualAsset="AbyssalDragonHybrid", Element="Sky", HP=26000, ATK=135, Attack=135, DEF=50, Defense=50, XP=1350000, Gold=35000, Range=22, Speed=12, Aggro=65, Leash=80, Boss=true, Drop="CoreEssence"},
    Ignivar = {Name="IGNIVAR • TITAN LÒ RÈN LỬA", Level=2325, VisualAsset="SolarTitanBuddha", Element="Sky", HP=34000, ATK=155, Attack=155, DEF=56, Defense=56, XP=1650000, Gold=45000, Range=24, Speed=12, Aggro=65, Leash=80, Boss=true, Drop="CoreEssence"},
    Nerith = {Name="NERITH • THỦY HOÀNG VỰC SÂU", Level=2400, VisualAsset="AbyssalLeviathan", Element="Frost", HP=44000, ATK=180, Attack=180, DEF=64, Defense=64, XP=2100000, Gold=60000, Range=28, Speed=11, Aggro=75, Leash=90, Boss=true, Drop="CoreEssence"},
    Aion = {Name="AION • PHÁP VƯƠNG THỜI GIAN", Level=2475, VisualAsset="OrderCyborgBoss", Element="Sky", HP=56000, ATK=210, Attack=210, DEF=72, Defense=72, XP=2800000, Gold=80000, Range=24, Speed=13, Aggro=70, Leash=85, Boss=true, Drop="CoreEssence"},
    Veyr = {Name="VEYR • ĐẤNG KIẾN TẠO ĐẦU TIÊN", Level=2550, VisualAsset="AbyssalSovereignDragon", Element="Void", HP=82000, ATK=260, Attack=260, DEF=85, Defense=85, XP=5000000, Gold=150000, Range=30, Speed=12, Aggro=80, Leash=95, Boss=true, Drop="CoreEssence"},
}

C.NPCs = {
    Lyra = {Id="Lyra", Name="Lyra • Chỉ Huy Skyborn", VisualAsset="Lyra", Scale=2.6},
    Kael = {Id="Kael", Name="Kael • Thợ Rèn Thần Khí", VisualAsset="Kael", Scale=2.7},
    ZiolesGachaNPC = {Id="ZiolesGachaNPC", Name="Zioles • Thương Nhân Trái Aether", VisualAsset="ZiolesGachaNPC", Scale=2.7},
    AncientMonkNPC = {Id="AncientMonkNPC", Name="Đại Sư Cổ Tự • Thần Quyền Sư Tổ", VisualAsset="AncientMonkNPC", Scale=2.8},
    SkyShipwrightNPC = {Id="SkyShipwrightNPC", Name="Thuyền Trưởng Thợ Đóng Tàu • Sky Shipwright", VisualAsset="SkyShipwrightNPC", Scale=2.7},
}

C.EquipSlots = {"Weapon", "Helmet", "Helm", "Chest", "Gloves", "Gauntlets", "Boots", "Greaves", "Ring", "Necklace", "Offhand", "Artifact"}

C.Items = {
    -- Starter Weapons
    starter_sword = {Id="starter_sword", Name="Kiếm Skyborn", Slot="Weapon", Rarity="Common", ATK=12, CritRate=2, CritDmg=10, ClassId="SkyGuardian", Desc="Thanh kiếm tiêu chuẩn của vệ binh bầu trời."},
    starter_daggers = {Id="starter_daggers", Name="Song đao Skyborn", Slot="Weapon", Rarity="Common", ATK=12, CritRate=4, CritDmg=12, ClassId="ThunderStriker", Desc="Cặp song đao nhẹ giúp lướt nhanh và ra đòn liên hoàn."},
    starter_staff = {Id="starter_staff", Name="Trượng Arcane", Slot="Weapon", Rarity="Common", ATK=12, CritRate=3, CritDmg=12, ClassId="ArcaneMage", Desc="Quyền trượng dẫn truyền ma lực cổ ngữ cơ bản."},

    -- Legendary & Mythic Swords (10 Swords total)
    dawnbringer_sword = {Id="dawnbringer_sword", Name="Dawnbringer • Sword of the First Light", Slot="Weapon", ClassId="SkyGuardian", Rarity="Legendary", ATK=72, CritRate=12, CritDmg=24, Desc="Thanh đại kiếm ánh sáng ban mai có xác suất 15% kích hoạt Heaven's Cleave gây 300% sát thương Ánh Sáng."},
    stormfang_daggers = {Id="stormfang_daggers", Name="Stormfang • Twinblades of the Tempest", Slot="Weapon", ClassId="ThunderStriker", Rarity="Legendary", ATK=76, CritRate=18, CritDmg=30, Desc="Song đao sấm sét triệu hồi chuỗi lôi kích mỗi đòn chí mạng."},
    astral_staff = {Id="astral_staff", Name="Chronostaff • Scepter of the Void Star", Slot="Weapon", ClassId="ArcaneMage", Rarity="Legendary", ATK=78, CritRate=15, CritDmg=28, Desc="Quyền trượng tinh cầu khuếch đại sát thương phép và tạo khiên năng lượng."},
    saber_of_aureon = {Id="saber_of_aureon", Name="Saber of Aureon • Đại Kiếm Thánh Quang", Slot="Weapon", Rarity="Legendary", ATK=115, CritRate=16, CritDmg=32, Desc="Thanh đại kiếm của Aureon Sentinel, chém sóng năng lượng xuyên giáp."},
    cryon_frostblade = {Id="cryon_frostblade", Name="Cryon Frostblade • Tuyệt Độ Hàn Đao", Slot="Weapon", Rarity="Legendary", ATK=135, CritRate=18, CritDmg=36, Desc="Đại đao băng tinh của Cryon Prime, đóng băng kẻ địch trúng đòn."},
    cursed_dual_skyblades = {Id="cursed_dual_skyblades", Name="Cursed Dual Skyblades (CDK) • Song Kiếm Huyền Thoại", Slot="Weapon", Rarity="Mythic", ATK=185, CritRate=25, CritDmg=48, Desc="Song kiếm tối thượng kết hợp Ánh Sáng và Hư Không, càn quét mọi đấu trường."},
    noxar_abyssal_greatsword = {Id="noxar_abyssal_greatsword", Name="Noxar's Abyssal Greatsword • Hắc Kiếm Hư Không", Slot="Weapon", Rarity="Mythic", ATK=210, CritRate=28, CritDmg=55, Desc="Đại kiếm tối thượng của Hư Không Vương Noxar, chém rách không gian."},

    -- 4 Arcane Guns (Slot 4: Gun)
    aether_flintlock = {Id="aether_flintlock", Name="Aether Flintlock", Slot="Gun", Rarity="Common", ATK=35, CritRate=5, CritDmg=15, Desc="Súng lục Aether cơ bản của thợ săn bầu trời."},
    solar_kabucha = {Id="solar_kabucha", Name="Solar Kabucha • Ná Thần Mặt Trời", Slot="Gun", Rarity="Rare", ATK=78, CritRate=12, CritDmg=25, Desc="Ná bắn đạn năng lượng mặt trời đẩy lùi và phá giáp kẻ địch."},
    cryo_railgun = {Id="cryo_railgun", Name="Cryo Railgun • Pháo Từ Trường Băng", Slot="Gun", Rarity="Legendary", ATK=125, CritRate=18, CritDmg=35, Desc="Pháo điện từ bắn xuyên thấu tia laser băng giá cực đại."},
    soul_guitar_void = {Id="soul_guitar_void", Name="Soul Guitar of the Void • Đàn Linh Hồn Hư Không", Slot="Gun", Rarity="Mythic", ATK=165, CritRate=22, CritDmg=45, Desc="Pháp khí âm hồn triệu hồi sóng âm hủy diệt và hồi phục sinh lực."},

    -- Armor & Accessory Pieces
    skyward_helm = {Id="skyward_helm", Name="Mũ Giáp Azure Vanguard", Slot="Helmet", Rarity="Epic", HP=180, DEF=18, Desc="Mũ giáp hợp kim thiên thanh bảo vệ khỏi chấn động không gian."},
    skyward_chest = {Id="skyward_chest", Name="Chiến Giáp Skyward Cloak", Slot="Chest", Rarity="Legendary", HP=320, DEF=32, Desc="Chiến giáp dệt từ lông vũ thiên giới và lõi tinh thể."},
    skyward_gloves = {Id="skyward_gloves", Name="Hộ Uyển Thiên Không", Slot="Gloves", Rarity="Epic", ATK=22, CritRate=6, Desc="Hộ uyển gia tăng lực cầm nắm và độ chuẩn xác khi ra đòn."},
    skyward_boots = {Id="skyward_boots", Name="Chiến Hài Lướt Gió", Slot="Boots", Rarity="Epic", HP=140, DEF=16, Desc="Chiến hài gắn đá phong năng giúp di chuyển linh hoạt."},
    aether_ring = {Id="aether_ring", Name="Nhẫn Tinh Cầu Aether", Slot="Ring", Rarity="Legendary", ATK=28, CritRate=8, Desc="Chiếc nhẫn hội tụ dòng chảy Aether tăng mạnh tỉ lệ chí mạng."},
    celestial_necklace = {Id="celestial_necklace", Name="Dây Chuyền Ánh Sao", Slot="Necklace", Rarity="Legendary", HP=220, CritDmg=20, Desc="Mặt dây chuyền chứa mảnh sao băng cổ đại."},
    core_artifact = {Id="core_artifact", Name="Thánh Vật Core of Light", Slot="Artifact", Rarity="Mythic", ATK=35, HP=250, DEF=20, CritRate=5, CritDmg=15, Desc="Thánh vật cộng hưởng từ Core of Light, ban sức mạnh toàn diện cho Skyborn."},
    leviathan_shield = {Id="leviathan_shield", Name="Khiên Thần Leviathan", Slot="Artifact", Rarity="Mythic", HP=850, DEF=85, ATK=60, CritRate=10, CritDmg=20, Desc="Khiên thần rèn từ vảy Thủy Tổ Leviathan, kháng chấn động biển mây và tăng mạnh sinh lực."},
    sovereign_cloak = {Id="sovereign_cloak", Name="Áo Choàng Hư Không Đế Vương", Slot="Chest", Rarity="Mythic", HP=750, DEF=70, ATK=55, CritRate=12, CritDmg=30, Desc="Áo choàng tối thượng của Hư Không Vương Noxar, gia tăng sát thương toàn diện."},

    -- Materials & Quest Items
    SunshardCore = {Id="SunshardCore", Name="Sunshard Core", Slot="Material", Rarity="Legendary", Desc="Tinh thể mặt trời rực cháy dùng để rèn thần khí."},
    SkyIron = {Id="SkyIron", Name="Sky Iron", Slot="Material", Rarity="Rare", Desc="Quặng sắt lơ lửng thu thập từ các đảo cổ."},
    CelestialFeather = {Id="CelestialFeather", Name="Celestial Feather", Slot="Material", Rarity="Epic", Desc="Lông vũ phát sáng dùng trong chế tác giáp trụ."},
    CoreEssence = {Id="CoreEssence", Name="Core Essence", Slot="Material", Rarity="Mythic", Desc="Tinh chất lõi năng lượng thuần khiết từ Boss."},
    upgrade_material = {Id="upgrade_material", Name="Vật liệu ánh sáng", Slot="Material", Rarity="Rare", Desc="Mảnh tinh thể dùng để cường hóa trang bị."},
    CoreOfLight = {Id="CoreOfLight", Name="Core of Light", Slot="Quest", Rarity="Mythic", Desc="Trái tim ánh sáng của Golden Sky."},
    DawnbringerBlueprint = {Id="DawnbringerBlueprint", Name="Bản vẽ Dawnbringer", Slot="Quest", Rarity="Legendary", Desc="Bản thiết kế vũ khí huyền thoại của Kael."},
    BossKey = {Id="BossKey", Name="Chìa khóa tháp", Slot="Quest", Rarity="Epic", Desc="Chìa khóa mở cổng đấu trường Aureon."},
    -- V2 Premium UI Catalog Aliases
    Dawnbringer = {Id="Dawnbringer", Name="Dawnbringer • Thánh Kiếm Ban Mai", Slot="Weapon", ClassId="SkyGuardian", Rarity="Legendary", ATK=120, DEF=35, HP=180, CritRate=10, CritDmg=24, Desc="Thánh kiếm rèn từ Core of Light của Aureon."},
    Stormfang = {Id="Stormfang", Name="Stormfang • Song Đao Lôi Đình", Slot="Weapon", ClassId="ThunderStriker", Rarity="Legendary", ATK=135, CritRate=18, CritDmg=30, Desc="Song đao sấm sét tụ hội từ Frozen Cyber."},
    EternalFrost = {Id="EternalFrost", Name="Eternal Frost • Quyền Trượng Băng Giá", Slot="Weapon", ClassId="ArcaneMage", Rarity="Legendary", ATK=142, CritRate=14, CritDmg=28, Desc="Quyền trượng gắn tinh thể trái tim của Cryon Prime."},
    ArchitectsSeverance = {Id="ArchitectsSeverance", Name="Architect's Severance • Kiếm Kiến Tạo Veyr", Slot="Weapon", ClassId="SkyGuardian", Rarity="Mythic", ATK=380, DEF=95, HP=620, CritRate=22, CritDmg=50, Desc="Thần kiếm tối thượng dệt từ kỳ điểm Veil's End."},
    SkyHelm = {Id="SkyHelm", Name="Skyborn Vanguard Helm", Slot="Helm", Rarity="Rare", HP=65, DEF=14, Desc="Mũ giáp vệ binh Sky Hub."},
    CelestialPlate = {Id="CelestialPlate", Name="Celestial Aegis Plate", Slot="Chest", Rarity="Epic", HP=160, DEF=38, Desc="Giáp ngực hợp kim Hắc Diện - Lam Ngọc."},
    StarlightGauntlets = {Id="StarlightGauntlets", Name="Starlight Gauntlets", Slot="Gauntlets", Rarity="Rare", ATK=18, DEF=12, CritRate=4, Desc="Hộ uyển tinh quang Golden Sky."},
    WindstriderGreaves = {Id="WindstriderGreaves", Name="Windstrider Greaves", Slot="Greaves", Rarity="Rare", HP=50, DEF=14, Desc="Chiến hài phong hành."},
    AureonCrestShield = {Id="AureonCrestShield", Name="Aureon Crest Bulwark", Slot="Offhand", Rarity="Epic", HP=110, DEF=28, Desc="Khiên hộ vệ ánh sáng của Aureon."},
    SolarBand = {Id="SolarBand", Name="Solar Band", Slot="Ring", Rarity="Epic", ATK=24, CritRate=8, Desc="Nhẫn thái dương hồi năng lượng."},
    CoreShardArtifact = {Id="CoreShardArtifact", Name="Astral Core Reliquary", Slot="Artifact", Rarity="Legendary", HP=140, ATK=32, DEF=20, Desc="Cổ vật mảnh lõi bầu trời."},
    SkyCrystal = {Id="SkyCrystal", Name="Sky Crystal", Slot="Material", Rarity="Rare", Desc="Pha lê Aether tinh khiết."},
    VoidShard = {Id="VoidShard", Name="Void Shard", Slot="Material", Rarity="Epic", Desc="Mảnh tinh thể Hư Không."},
    VoidEssence = {Id="VoidEssence", Name="Void Essence • Tinh Chất Hư Không", Slot="Material", Rarity="Epic", Desc="Tinh chất năng lượng Hư Không thu thập từ quái và Boss Sea 3."},
    EnchantScroll = {Id="EnchantScroll", Name="Cuộn Phù Phép Cổ Ngữ", Slot="Material", Rarity="Legendary", Desc="Cuộn phù phép cổ đại dùng tại Arcane Enchanter để khắc dòng chỉ số vũ khí."},
    AwakeningMicrochip = {Id="AwakeningMicrochip", Name="Chip Thức Tỉnh V2", Slot="Material", Rarity="Mythic", Desc="Vi mạch cổ đại từ Mythic Awakening Raid giúp thức tỉnh toàn diện Trái Ác Quỷ V2."},
    LeviathanHeart = {Id="LeviathanHeart", Name="Trái Tim Thủy Tổ Leviathan", Slot="Material", Rarity="Mythic", Desc="Chiến lợi phẩm tối thượng từ Thủy Tổ Leviathan dùng rèn Khiên Thần và mở khóa Thần Quyền."},
    BlueResonanceGear = {Id="BlueResonanceGear", Name="Bánh Răng Cộng Hưởng Xanh", Slot="Material", Rarity="Mythic", Desc="Cổ vật cộng hưởng trên Đảo Bí Ẩn Mirage mở khóa sức mạnh Tộc V4."},
    CoreGear = {Id="CoreGear", Name="Bánh Răng Thức Tỉnh V4", Slot="Material", Rarity="Mythic", Desc="Bánh răng lõi cổ đại nâng cấp thiên phú Tộc V4 tại Đền Thờ Lõi."},
    noxar_greatsword = {Id="noxar_greatsword", Name="Noxar Greatsword - Đại Kiếm Hắc Tinh", Slot="Weapon", Rarity="Mythic", ATK=210, CritRate=28, CritDmg=55, Desc="Đại kiếm Hư Không tích tụ kiếm khí Bán Nguyệt Dung Nham Hắc Ám."},
    abyssal_greatsword = {Id="abyssal_greatsword", Name="Abyssal Greatsword - Đại Kiếm Vực Thẳm", Slot="Weapon", Rarity="Mythic", ATK=210, CritRate=28, CritDmg=55, Desc="Đại kiếm vực thẳm giải phóng Charged Crescent Slash cực đại."},
    yamo_voidblade = {Id="yamo_voidblade", Name="Yamo Voidblade - Yêu Đao Hư Không", Slot="Weapon", Rarity="Mythic", ATK=198, CritRate=26, CritDmg=52, Desc="Yêu đao hư không chém sóng bán nguyệt phá vỡ giáp Boss."},
}

-- ============================================================================
-- 10 SWORDS (SLOT 3) & 4 GUNS (SLOT 4) WITH Z / X SKILLS
-- ============================================================================
C.SwordOrder = {
    "starter_sword",
    "starter_daggers",
    "starter_staff",
    "dawnbringer_sword",
    "stormfang_daggers",
    "astral_staff",
    "saber_of_aureon",
    "cryon_frostblade",
    "cursed_dual_skyblades",
    "noxar_abyssal_greatsword",
}

C.Swords = {
    starter_sword = {
        Id = "starter_sword", Name = "Kiếm Skyborn", Rarity = "Common", ATK = 12, CritRate = 2, CritDmg = 10, Element = "Sky",
        Desc = "Thanh kiếm tiêu chuẩn của vệ binh bầu trời.",
        Moves = {
            Z = {Key="Z", Name="Sky Thrust • Đâm Xung Kích", Mastery=1, Cooldown=4.5, Cost=8, Range=20, Multiplier=2.1, Break=18, Element="Sky", Desc="Đâm kiếm kết hợp chém sóng kình phong về phía trước."},
            X = {Key="X", Name="Crescent Slash • Bán Nguyệt Xung Thiên", Mastery=1, Cooldown=7.0, Cost=12, Range=22, Multiplier=2.6, Break=24, Element="Sky", Desc="Chém ngược từ dưới lên tạo lốc kiếm cuốn tung mục tiêu."},
            C = {Key="C", Name="Tempest Flurry • Liên Hoàn Bão Kiếm", Mastery=1, Cooldown=9.5, Cost=16, Range=24, Multiplier=3.2, Break=32, Element="Sky", Desc="Tung liên hoàn trảm tốc độ cao cùng kiếm ảnh hộ thể."},
            V = {Key="V", Name="Sovereign Skyfall • Thiên Kiếm Phán Quyết", Mastery=1, Cooldown=14.0, Cost=22, Range=30, Multiplier=4.1, Break=42, Element="Sky", Desc="Nhảy lên không tụ kiếm khí rồi giáng đại kiếm quang xuống đất."},
            F = {Key="F", Name="Zephyr Lunge • Kiếm Phong Lướt Gió", Mastery=1, Cooldown=5.0, Cost=8, Range=28, Multiplier=1.5, Break=14, Element="Sky", Desc="Hóa kiếm quang lướt xuyên qua kẻ địch với tốc độ âm thanh."},
        },
    },
    starter_daggers = {
        Id = "starter_daggers", Name = "Song đao Skyborn", Rarity = "Common", ATK = 12, CritRate = 4, CritDmg = 12, Element = "Lightning",
        Desc = "Cặp song đao nhẹ giúp lướt nhanh và ra đòn liên hoàn.",
        Moves = {
            Z = {Key="Z", Name="Twin Cut • Song Đao Đột Kích", Mastery=1, Cooldown=4.2, Cost=8, Range=18, Multiplier=2.1, Break=18, Element="Lightning", Desc="Phóng chéo cặp song đao tạo lưỡi sét cắt xuyên mục tiêu."},
            X = {Key="X", Name="Spinning Blades • Xoáy Đao Lôi Điện", Mastery=1, Cooldown=7.0, Cost=12, Range=22, Multiplier=2.6, Break=24, Element="Lightning", Desc="Xoay người bật cao tạo lốc xoáy song đao sấm sét."},
            C = {Key="C", Name="Lightning Cross Flurry • Thập Tự Liên Trảm", Mastery=1, Cooldown=9.5, Cost=16, Range=24, Multiplier=3.3, Break=32, Element="Lightning", Desc="Chém thập tự liên hoàn triệu hồi ảo ảnh đao lôi điện."},
            V = {Key="V", Name="Thunderstorm Execution • Lôi Ngục Tuyệt Sát", Mastery=1, Cooldown=14.0, Cost=22, Range=28, Multiplier=4.1, Break=42, Element="Lightning", Desc="Triệu hồi trận pháp sấm sét và giáng thiên lôi hủy diệt."},
            F = {Key="F", Name="Flash Stride • Lôi Ảnh Bộ", Mastery=1, Cooldown=5.0, Cost=8, Range=28, Multiplier=1.5, Break=14, Element="Lightning", Desc="Hóa tia chớp lướt xuyên không gian để lại tàn ảnh điện từ."},
        },
    },
    starter_staff = {
        Id = "starter_staff", Name = "Trượng Arcane", Rarity = "Common", ATK = 12, CritRate = 3, CritDmg = 12, Element = "Frost",
        Desc = "Quyền trượng dẫn truyền ma lực cổ ngữ cơ bản.",
        Moves = {
            Z = {Key="Z", Name="Arcane Pulse • Xung Ma Lực Băng", Mastery=1, Cooldown=4.5, Cost=8, Range=26, Multiplier=2.1, Break=18, Element="Frost", Desc="Phóng sóng bán nguyệt hàn băng xuyên thấu mục tiêu."},
            X = {Key="X", Name="Rune Burst • Bùng Nổ Cổ Ngữ", Mastery=1, Cooldown=7.5, Cost=12, Range=28, Multiplier=2.6, Break=24, Element="Frost", Desc="Kích hoạt trận cổ ngữ dưới chân tạo cột băng xoáy xung thiên."},
            C = {Key="C", Name="Glacial Star Convergence • Tinh Cầu Hội Tụ", Mastery=1, Cooldown=9.5, Cost=16, Range=30, Multiplier=3.3, Break=32, Element="Frost", Desc="Triệu hồi mũi thương băng tinh hội tụ nghiền nát mục tiêu."},
            V = {Key="V", Name="Astral Frost Supernova • Đại Tinh Vân Hàn Băng", Mastery=1, Cooldown=14.0, Cost=22, Range=34, Multiplier=4.2, Break=42, Element="Frost", Desc="Ngưng tụ tinh cầu băng giá khổng lồ rồi kích nổ toàn vùng."},
            F = {Key="F", Name="Phase Blink • Dịch Chuyển Tinh Không", Mastery=1, Cooldown=5.0, Cost=8, Range=28, Multiplier=1.5, Break=14, Element="Frost", Desc="Lướt qua không gian bằng luồng ma lực băng tinh."},
        },
    },
    dawnbringer_sword = {
        Id = "dawnbringer_sword", Name = "Dawnbringer • Sword of the First Light", Rarity = "Legendary", ATK = 72, CritRate = 12, CritDmg = 24, Element = "Sky",
        Desc = "Thanh đại kiếm ánh sáng ban mai có xác suất 15% kích hoạt Heaven's Cleave.",
        Moves = {
            Z = {Key="Z", Name="Dawn Slash • Bình Minh Trảm", Mastery=1, Cooldown=5.5, Cost=12, Range=26, Multiplier=2.9, Break=30, Element="Sky"},
            X = {Key="X", Name="Heaven's Cleave • Thiên Quang Phán Quyết", Mastery=100, Cooldown=10, Cost=18, Range=30, Multiplier=3.8, Break=40, Element="Sky"},
        },
    },
    stormfang_daggers = {
        Id = "stormfang_daggers", Name = "Stormfang • Twinblades of the Tempest", Rarity = "Legendary", ATK = 76, CritRate = 18, CritDmg = 30, Element = "Lightning",
        Desc = "Song đao sấm sét triệu hồi chuỗi lôi kích mỗi đòn chí mạng.",
        Moves = {
            Z = {Key="Z", Name="Tempest Fang • Nanh Bão Sấm Sét", Mastery=1, Cooldown=5, Cost=12, Range=24, Multiplier=3.0, Break=28, Element="Lightning"},
            X = {Key="X", Name="Thunder Cross • Thập Tự Lôi Kích", Mastery=100, Cooldown=9.5, Cost=18, Range=28, Multiplier=3.9, Break=38, Element="Lightning"},
        },
    },
    astral_staff = {
        Id = "astral_staff", Name = "Chronostaff • Scepter of the Void Star", Rarity = "Legendary", ATK = 78, CritRate = 15, CritDmg = 28, Element = "Void",
        Desc = "Quyền trượng tinh cầu khuếch đại sát thương phép và tạo khiên năng lượng.",
        Moves = {
            Z = {Key="Z", Name="Star Lance • Mũi Thương Tinh Cầu", Mastery=1, Cooldown=5.5, Cost=12, Range=32, Multiplier=3.0, Break=28, Element="Void"},
            X = {Key="X", Name="Chrono Nova • Tinh Vân Ngưng Đọng", Mastery=100, Cooldown=10, Cost=18, Range=34, Multiplier=3.9, Break=40, Element="Void"},
        },
    },
    saber_of_aureon = {
        Id = "saber_of_aureon", Name = "Saber of Aureon • Đại Kiếm Thánh Quang", Rarity = "Legendary", ATK = 115, CritRate = 16, CritDmg = 32, Element = "Sky",
        Desc = "Thanh đại kiếm của Aureon Sentinel, chém sóng năng lượng xuyên giáp.",
        Moves = {
            Z = {Key="Z", Name="Aureon Rush • Thánh Kiếm Đột Kích", Mastery=50, Cooldown=5.5, Cost=12, Range=28, Multiplier=3.2, Break=34, Element="Sky"},
            X = {Key="X", Name="Triple Radiance • Tam Đoạn Thánh Quang Trảm", Mastery=125, Cooldown=10, Cost=18, Range=34, Multiplier=4.2, Break=44, Element="Sky"},
        },
    },
    cryon_frostblade = {
        Id = "cryon_frostblade", Name = "Cryon Frostblade • Tuyệt Độ Hàn Đao", Rarity = "Legendary", ATK = 135, CritRate = 18, CritDmg = 36, Element = "Frost",
        Desc = "Đại đao băng tinh của Cryon Prime, đóng băng kẻ địch trúng đòn.",
        Moves = {
            Z = {Key="Z", Name="Absolute Slash • Hàn Băng Nhất Trảm", Mastery=75, Cooldown=5.5, Cost=12, Range=28, Multiplier=3.4, Break=36, Element="Frost"},
            X = {Key="X", Name="Blizzard Tempest • Bão Đao Tuyết Vĩnh Cửu", Mastery=150, Cooldown=10.5, Cost=18, Range=32, Multiplier=4.4, Break=46, Element="Frost"},
        },
    },
    cursed_dual_skyblades = {
        Id = "cursed_dual_skyblades", Name = "Cursed Dual Skyblades (CDK) • Song Kiếm Huyền Thoại", Rarity = "Mythic", ATK = 185, CritRate = 25, CritDmg = 48, Element = "Lightning",
        Desc = "Song kiếm tối thượng kết hợp Ánh Sáng và Hư Không, càn quét mọi đấu trường.",
        Moves = {
            Z = {Key="Z", Name="Revolving Ravager • Vòng Xoáy Song Kiếm", Mastery=175, Cooldown=5.5, Cost=14, Range=32, Multiplier=3.9, Break=44, Element="Lightning"},
            X = {Key="X", Name="Slayer of Skies • Tuyệt Kiếm Phá Thiên", Mastery=350, Cooldown=11, Cost=22, Range=38, Multiplier=5.2, Break=58, Element="Lightning"},
        },
    },
    noxar_abyssal_greatsword = {
        Id = "noxar_abyssal_greatsword", Name = "Noxar's Abyssal Greatsword - Hắc Kiếm Hư Không", Rarity = "Mythic", ATK = 210, CritRate = 28, CritDmg = 55, Element = "Void",
        Desc = "Đại kiếm tối thượng của Hư Không Vương Noxar, chém rách không gian.",
        Moves = {
            Z = {Key="Z", Name="Abyssal Cleave - Hắc Kiếm Xé Không Gian", Mastery=1, Cooldown=5.5, Cost=14, Range=34, Multiplier=4.2, Break=48, Element="Void"},
            X = {Key="X", Name="Void Sovereign's Decree - Sắc Lệnh Hư Không Vương", Mastery=100, Cooldown=11.5, Cost=24, Range=40, Multiplier=5.6, Break=64, Element="Void"},
        },
    },
    noxar_greatsword = {
        Id = "noxar_greatsword", Name = "Noxar Greatsword - Đại Kiếm Hắc Tinh", Rarity = "Mythic", ATK = 210, CritRate = 28, CritDmg = 55, Element = "Void",
        Desc = "Đại kiếm Hư Không tích tụ kiếm khí Charged Crescent Slash.",
        Moves = {
            Z = {Key="Z", Name="Charged Crescent Slash - Hắc Nguyệt Trảm", Mastery=1, Cooldown=5.5, Cost=14, Range=36, Multiplier=4.2, Break=45, Element="Void"},
            X = {Key="X", Name="Void Sovereign's Decree - Sắc Lệnh Hư Không Vương", Mastery=100, Cooldown=11.5, Cost=24, Range=40, Multiplier=5.6, Break=64, Element="Void"},
        },
    },
    abyssal_greatsword = {
        Id = "abyssal_greatsword", Name = "Abyssal Greatsword - Đại Kiếm Vực Thẳm", Rarity = "Mythic", ATK = 210, CritRate = 28, CritDmg = 55, Element = "Void",
        Desc = "Đại kiếm vực thẳm giải phóng Charged Crescent Slash cực đại.",
        Moves = {
            Z = {Key="Z", Name="Charged Crescent Slash - Hắc Nguyệt Trảm", Mastery=1, Cooldown=5.5, Cost=14, Range=36, Multiplier=4.2, Break=45, Element="Void"},
            X = {Key="X", Name="Abyssal Cataclysm - Vực Thẳm Diệt Thế", Mastery=100, Cooldown=11.5, Cost=24, Range=40, Multiplier=5.6, Break=64, Element="Void"},
        },
    },
    yamo_voidblade = {
        Id = "yamo_voidblade", Name = "Yamo Voidblade - Yêu Đao Hư Không", Rarity = "Mythic", ATK = 198, CritRate = 26, CritDmg = 52, Element = "Void",
        Desc = "Yêu đao hư không chém sóng bán nguyệt phá vỡ giáp Boss.",
        Moves = {
            Z = {Key="Z", Name="Charged Crescent Slash - Yêu Đao Bán Nguyệt", Mastery=1, Cooldown=5.2, Cost=14, Range=36, Multiplier=4.0, Break=45, Element="Void"},
            X = {Key="X", Name="Hellfire Dimension Cut - Minh Giới Trảm", Mastery=100, Cooldown=11.0, Cost=22, Range=38, Multiplier=5.4, Break=60, Element="Void"},
        },
    },
}

C.GunOrder = {
    "aether_flintlock",
    "solar_kabucha",
    "cryo_railgun",
    "soul_guitar_void",
}

C.Guns = {
    aether_flintlock = {
        Id = "aether_flintlock", Name = "Aether Flintlock", Rarity = "Common", ATK = 35, CritRate = 5, CritDmg = 15, Element = "Sky",
        Desc = "Súng lục Aether cơ bản của thợ săn bầu trời.",
        Moves = {
            Z = {Key="Z", Name="Armor Piercing Shot • Đạn Xuyên Giáp", Mastery=1, Cooldown=4.5, Cost=8, Range=40, Multiplier=2.2, Break=22, Element="Sky", Desc="Bắn viên đạn năng lượng Aether tốc độ cao xuyên thủng mục tiêu."},
            X = {Key="X", Name="Scatter Volley • Loạt Đạn Chùm Xoáy", Mastery=1, Cooldown=7.0, Cost=12, Range=34, Multiplier=2.8, Break=28, Element="Sky", Desc="Bắn loạt đạn chùm tạo xoáy năng lượng đẩy lùi kẻ địch."},
            C = {Key="C", Name="Ricochet Barrage • Mưa Đạn Liên Thanh", Mastery=1, Cooldown=9.5, Cost=16, Range=36, Multiplier=3.3, Break=32, Element="Sky", Desc="Xả loạt đạn năng lượng liên hoàn từ mọi hướng vào mục tiêu."},
            V = {Key="V", Name="Aether Overcharge • Đại Pháo Ánh Sáng", Mastery=1, Cooldown=14.0, Cost=22, Range=42, Multiplier=4.1, Break=42, Element="Sky", Desc="Tụ toàn bộ năng lượng Aether bắn cột đại pháo hủy diệt."},
            F = {Key="F", Name="Recoil Jet Dash • Phản Lực Đẩy Lướt", Mastery=1, Cooldown=5.0, Cost=8, Range=28, Multiplier=1.4, Break=12, Element="Sky", Desc="Dùng phản lực súng Aether lướt nhanh qua không trung."},
        },
    },
    solar_kabucha = {
        Id = "solar_kabucha", Name = "Solar Kabucha • Ná Thần Mặt Trời", Rarity = "Rare", ATK = 78, CritRate = 12, CritDmg = 25, Element = "Sky",
        Desc = "Ná bắn đạn năng lượng mặt trời đẩy lùi và phá giáp kẻ địch.",
        Moves = {
            Z = {Key="Z", Name="Flying Fire Bird • Hỏa Điểu Xung Kích", Mastery=50, Cooldown=5.5, Cost=10, Range=42, Multiplier=2.9, Break=30, Element="Sky"},
            X = {Key="X", Name="Intense Wind • Cuồng Phong Đạn Đẩy Lùi", Mastery=100, Cooldown=9.5, Cost=15, Range=38, Multiplier=3.6, Break=38, Element="Sky"},
        },
    },
    cryo_railgun = {
        Id = "cryo_railgun", Name = "Cryo Railgun • Pháo Từ Trường Băng", Rarity = "Legendary", ATK = 125, CritRate = 18, CritDmg = 35, Element = "Frost",
        Desc = "Pháo điện từ bắn xuyên thấu tia laser băng giá cực đại.",
        Moves = {
            Z = {Key="Z", Name="Cryo Pulse Beam • Tia Xung Từ Trường Băng", Mastery=100, Cooldown=6, Cost=12, Range=46, Multiplier=3.4, Break=36, Element="Frost"},
            X = {Key="X", Name="Orbital Subzero Cannon • Đại Pháo Hàn Băng", Mastery=200, Cooldown=11, Cost=18, Range=48, Multiplier=4.4, Break=46, Element="Frost"},
        },
    },
    soul_guitar_void = {
        Id = "soul_guitar_void", Name = "Soul Guitar of the Void • Đàn Linh Hồn Hư Không", Rarity = "Mythic", ATK = 165, CritRate = 22, CritDmg = 45, Element = "Void",
        Desc = "Pháp khí âm hồn triệu hồi sóng âm hủy diệt và hồi phục sinh lực.",
        Moves = {
            Z = {Key="Z", Name="Soul Shaker • Sóng Âm Rung Chuyển Linh Hồn", Mastery=150, Cooldown=6, Cost=14, Range=42, Multiplier=3.8, Break=42, Element="Void"},
            X = {Key="X", Name="El Diablo Requiem • Khúc Nhạc Hư Không", Mastery=300, Cooldown=11.5, Cost=20, Range=44, Multiplier=4.9, Break=54, Element="Void"},
        },
    },
}

-- ============================================================================
-- 6 RACES (WITH V4 AWAKENING) & 4 SKY SHIPS
-- ============================================================================
C.RaceOrder = {"Skyborn", "Mink", "Leviathan", "Cyborg", "Ghoul", "Draco"}

C.Races = {
    Skyborn = {
        Id = "Skyborn",
        Name = "Thiên Tộc • Skyborn (Angel)",
        Title = "Đôi Cánh Thánh Quang",
        PassiveDesc = "Tăng độ cao nhảy kép, lướt trên không và hồi phục HP tự nhiên.",
        V4Desc = "Vua Bầu Trời (V4): Bung đôi cánh Hoàng Kim, tạo hào quang làm chậm kẻ địch xung quanh và tăng 25% sát thương.",
        SpeedMult = 1.10,
        DefenseMult = 1.12,
        DamageMult = 1.25,
    },
    Mink = {
        Id = "Mink",
        Name = "Tộc Thú • Cloud Mink",
        Title = "Tia Chớp Phong Vân",
        PassiveDesc = "Tăng 25% tốc độ chạy và giảm thời gian hồi lướt (Dash).",
        V4Desc = "Cuồng Phong Điện Ảnh (V4): Mỗi lần lướt để lại lốc xoáy điện từ và tăng 35% tốc độ di chuyển.",
        SpeedMult = 1.35,
        DefenseMult = 1.05,
        DamageMult = 1.15,
    },
    Leviathan = {
        Id = "Leviathan",
        Name = "Hải Tộc • Shark / LeviathanKin",
        Title = "Giáp Vảy Biển Sâu",
        PassiveDesc = "Miễn nhiễm sát thương vùng mây độc và tăng mạnh khả năng chống chịu.",
        V4Desc = "Thủy Tổ Hộ Thể (V4): Tạo lớp giáp vảy Leviathan giảm 35% sát thương nhận vào và làm chậm kẻ địch.",
        SpeedMult = 1.05,
        DefenseMult = 1.35,
        DamageMult = 1.12,
    },
    Cyborg = {
        Id = "Cyborg",
        Name = "Cơ Giới • Frost Cyborg",
        Title = "Lõi Phản Ứng Lượng Tử",
        PassiveDesc = "Chuyển hóa 15% sát thương nhận vào thành năng lượng và phá Haki Quan Sát.",
        V4Desc = "Quá Tải Lượng Tử (V4): Phóng chuỗi tia sét từ trường nhảy lan giữa các mục tiêu xung quanh.",
        SpeedMult = 1.10,
        DefenseMult = 1.22,
        DamageMult = 1.22,
    },
    Ghoul = {
        Id = "Ghoul",
        Name = "Huyết Tộc • Shadow Ghoul",
        Title = "Khế Ước Bóng Đêm",
        PassiveDesc = "Hút máu 15% từ mọi đòn đánh và giảm thời gian hồi chiêu.",
        V4Desc = "Chúa Tể Huyết Nguyệt (V4): Triệu hồi đàn quạ hư không, hút máu 25% và tăng 24% sát thương.",
        SpeedMult = 1.18,
        DefenseMult = 1.12,
        DamageMult = 1.24,
    },
    Draco = {
        Id = "Draco",
        Name = "Long Tộc • Ancient Draco",
        Title = "Huyết Mạch Cổ Long",
        PassiveDesc = "Phản lại sát thương cận chiến và tăng sức công phá diện rộng.",
        V4Desc = "Thái Cổ Long Hoàng (V4): Mở lãnh địa Lửa Rồng cổ đại, phản chấn sát thương và tăng 30% sát thương.",
        SpeedMult = 1.15,
        DefenseMult = 1.25,
        DamageMult = 1.30,
    },
}

C.ShipOrder = {"SkySloop", "CelestialBrigantine", "CyberEnforcer", "LeviathanHunterShip"}

C.SkyShips = {
    SkySloop = {
        Id = "SkySloop",
        Name = "Thuyền Buồm Mây • Sky Sloop",
        HP = 1200,
        Speed = 45,
        Price = 0,
        Desc = "Thuyền buồm lướt mây cơ bản dành cho tân thủ khám phá Sea 1.",
    },
    CelestialBrigantine = {
        Id = "CelestialBrigantine",
        Name = "Chiến Hạm Ánh Sáng • Celestial Brigantine",
        HP = 3500,
        Speed = 62,
        Price = 25000,
        Desc = "Chiến hạm hai cột buồm gắn động cơ tinh thể mặt trời.",
    },
    CyberEnforcer = {
        Id = "CyberEnforcer",
        Name = "Tàu Tuần Dương Băng Giá • Cyber Enforcer",
        HP = 6000,
        Speed = 78,
        Price = 75000,
        Desc = "Chiến hạm bọc thép từ trường của Sea 2, lướt nhanh qua bão băng.",
    },
    LeviathanHunterShip = {
        Id = "LeviathanHunterShip",
        Name = "Thần Hạm Săn Leviathan • Void Dreadnought",
        HP = 12000,
        Speed = 95,
        Price = 250000,
        Desc = "Đại chiến hạm tối thượng trang bị lao móc thần để săn Thủy Tổ Leviathan tại Danger Level 6.",
    },
}

local recipeList = {
    {Id="dawnbringer_sword", ItemId="dawnbringer_sword", Name="Dawnbringer • Sword of the First Light", Slot="Weapon", ClassId="SkyGuardian", Rarity="Legendary", Gold=400, Materials={SunshardCore=2, SkyIron=5, CoreEssence=1}, Desc="Thần kiếm Ánh Sáng dành cho Sky Guardian (+72 ATK, +12% Crit, +24% Crit DMG)."},
    {Id="stormfang_daggers", ItemId="stormfang_daggers", Name="Stormfang • Twinblades of the Tempest", Slot="Weapon", ClassId="ThunderStriker", Rarity="Legendary", Gold=400, Materials={SunshardCore=2, SkyIron=5, CoreEssence=1}, Desc="Song đao Lôi Đình dành cho Thunder Striker (+76 ATK, +18% Crit, +30% Crit DMG)."},
    {Id="astral_staff", ItemId="astral_staff", Name="Chronostaff • Scepter of the Void Star", Slot="Weapon", ClassId="ArcaneMage", Rarity="Legendary", Gold=400, Materials={SunshardCore=2, SkyIron=5, CoreEssence=1}, Desc="Quyền trượng Tinh Cầu dành cho Arcane Mage (+78 ATK, +15% Crit, +28% Crit DMG)."},
    {Id="saber_of_aureon", ItemId="saber_of_aureon", Name="Saber of Aureon • Đại Kiếm Thánh Quang", Slot="Weapon", Rarity="Legendary", Gold=1200, Materials={SunshardCore=3, SkyIron=6, CoreEssence=1}, Desc="Đại kiếm của Aureon Sentinel (+115 ATK, +16% Crit, +32% Crit DMG)."},
    {Id="cryon_frostblade", ItemId="cryon_frostblade", Name="Cryon Frostblade • Tuyệt Độ Hàn Đao", Slot="Weapon", Rarity="Legendary", Gold=1800, Materials={SunshardCore=4, CelestialFeather=3, CoreEssence=2}, Desc="Đại đao băng tinh của Cryon Prime (+135 ATK, +18% Crit, +36% Crit DMG)."},
    {Id="cursed_dual_skyblades", ItemId="cursed_dual_skyblades", Name="Cursed Dual Skyblades (CDK) • Song Kiếm Huyền Thoại", Slot="Weapon", Rarity="Mythic", Gold=5000, Materials={SunshardCore=6, CelestialFeather=5, CoreEssence=3}, Desc="Song kiếm thần thoại kết hợp Ánh Sáng & Hư Không (+185 ATK, +25% Crit, +48% Crit DMG)."},
    {Id="noxar_abyssal_greatsword", ItemId="noxar_abyssal_greatsword", Name="Noxar's Abyssal Greatsword • Hắc Kiếm Hư Không", Slot="Weapon", Rarity="Mythic", Gold=7500, Materials={SunshardCore=8, CelestialFeather=6, CoreEssence=4}, Desc="Đại kiếm tối thượng của Hư Không Vương Noxar (+210 ATK, +28% Crit, +55% Crit DMG)."},
    {Id="solar_kabucha", ItemId="solar_kabucha", Name="Solar Kabucha • Ná Thần Mặt Trời", Slot="Gun", Rarity="Rare", Gold=900, Materials={SunshardCore=2, SkyIron=4}, Desc="Ná thần bắn đạn mặt trời phá giáp (+78 ATK, +12% Crit)."},
    {Id="cryo_railgun", ItemId="cryo_railgun", Name="Cryo Railgun • Pháo Từ Trường Băng", Slot="Gun", Rarity="Legendary", Gold=2400, Materials={SunshardCore=3, SkyIron=6, CoreEssence=2}, Desc="Pháo từ trường bắn tia laser băng giá (+125 ATK, +18% Crit)."},
    {Id="soul_guitar_void", ItemId="soul_guitar_void", Name="Soul Guitar of the Void • Đàn Linh Hồn Hư Không", Slot="Gun", Rarity="Mythic", Gold=6000, Materials={SunshardCore=5, CelestialFeather=5, CoreEssence=3}, Desc="Đàn linh hồn thần thoại triệu hồi sóng âm hư không (+165 ATK, +22% Crit)."},
    {Id="skyward_chest", ItemId="skyward_chest", Name="Chiến Giáp Skyward Cloak", Slot="Chest", Rarity="Legendary", Gold=250, Materials={CelestialFeather=2, SkyIron=4}, Desc="Chiến giáp huyền thoại tăng +320 HP và +32 DEF."},
    {Id="sovereign_cloak", ItemId="sovereign_cloak", Name="Áo Choàng Hư Không Đế Vương", Slot="Chest", Rarity="Mythic", Gold=4500, Materials={CelestialFeather=5, SunshardCore=4, CoreEssence=2}, Desc="Áo choàng thần thoại tăng +750 HP, +70 DEF, +55 ATK, +30% Crit DMG."},
    {Id="aether_ring", ItemId="aether_ring", Name="Nhẫn Tinh Cầu Aether", Slot="Ring", Rarity="Legendary", Gold=250, Materials={SunshardCore=1, SkyIron=3}, Desc="Nhẫn cổ ngữ tăng +28 ATK và +8% Crit Rate."},
    {Id="core_artifact", ItemId="core_artifact", Name="Thánh Vật Core of Light", Slot="Artifact", Rarity="Mythic", Gold=500, Materials={SunshardCore=2, CelestialFeather=2, CoreEssence=1}, Desc="Thánh vật thần thoại tăng +35 ATK, +250 HP, +20 DEF."},
    {Id="leviathan_shield", ItemId="leviathan_shield", Name="Khiên Thần Leviathan", Slot="Artifact", Rarity="Mythic", Gold=5500, Materials={SunshardCore=5, SkyIron=8, CoreEssence=3}, Desc="Khiên thần rèn từ vảy Thủy Tổ Leviathan (+850 HP, +85 DEF, +60 ATK)."},
    -- V2 Celestial Forge Blueprints (1:1 parity with RarityConfig.Recipes & Forge.lua)
    {Id="Dawnbringer", ItemId="Dawnbringer", Name="Dawnbringer • Thánh Kiếm Ban Mai", Slot="Weapon", ClassId="SkyGuardian", Rarity="Legendary", Gold=500, Materials={SunshardCore=2, SkyIron=5, upgrade_material=3}, Desc="Thánh kiếm rèn từ Core of Light của Aureon (+120 ATK, +35 DEF, +180 HP)."},
    {Id="Stormfang", ItemId="Stormfang", Name="Stormfang • Song Đao Lôi Đình", Slot="Weapon", ClassId="ThunderStriker", Rarity="Legendary", Gold=1200, Materials={SunshardCore=2, SkyIron=6, upgrade_material=4}, Desc="Song đao sấm sét tụ hội từ Frozen Cyber (+135 ATK, +18% Crit)."},
    {Id="EternalFrost", ItemId="EternalFrost", Name="Eternal Frost • Quyền Trượng Băng Giá", Slot="Weapon", ClassId="ArcaneMage", Rarity="Legendary", Gold=1200, Materials={SunshardCore=2, CelestialFeather=3, upgrade_material=4}, Desc="Quyền trượng gắn tinh thể trái tim của Cryon Prime (+142 ATK, +14% Crit)."},
    {Id="CelestialPlate", ItemId="CelestialPlate", Name="Celestial Aegis Plate", Slot="Chest", Rarity="Epic", Gold=800, Materials={CelestialFeather=2, SkyIron=5, upgrade_material=3}, Desc="Giáp ngực hợp kim Hắc Diện - Lam Ngọc (+160 HP, +38 DEF)."},
    {Id="SolarBand", ItemId="SolarBand", Name="Solar Band", Slot="Ring", Rarity="Epic", Gold=600, Materials={SunshardCore=1, SkyIron=4, upgrade_material=2}, Desc="Nhẫn thái dương hồi năng lượng (+24 ATK, +8% Crit)."},
    {Id="ArchitectsSeverance", ItemId="ArchitectsSeverance", Name="Architect's Severance • Kiếm Kiến Tạo Veyr", Slot="Weapon", ClassId="SkyGuardian", Rarity="Mythic", Gold=9500, Materials={SunshardCore=8, CelestialFeather=6, CoreEssence=5}, Desc="Thần kiếm tối thượng dệt từ kỳ điểm Veil's End (+380 ATK, +95 DEF, +620 HP)."},
}
local recipeById = {}
for _, r in ipairs(recipeList) do
    recipeById[r.Id] = r
end
C.ForgeRecipes = setmetatable(recipeList, {
    __index = function(_, k)
        return recipeById[k]
    end
})

-- Sequential Main Storyline Quests (Q01 -> Q14) across all 8 Realms (Lv. 1 -> Lv. 2550 MAX).
-- Reward XP + TargetLevel milestone covers every Sea & Realm bracket smoothly without mandatory grinding.
C.Quests = {
    -- CHƯƠNG 1: SEA 1 • GOLDEN SKY (Lv. 1 - 700)
    {Id="Q01", Name="Lời Gọi Skyborn (Sea 1 • Lv. 1–120)", Realm="GoldenSky", Level=1, TargetLevel=120, XP=95000, Gold=1500, CoreShards=100,
        Text="Các quần đảo bầu trời đang mất dần năng lượng. Hãy tiêu diệt 3 Training Drone tại sân tập Sky Hub để làm quen với vũ khí và đột phá Lv. 120.",
        Objectives={{Kind="Kill", Target="TrainingDrone", Count=3, Label="Hạ gục Training Drone"}}},
    {Id="Q02", Name="Khôi Phục Cầu Năng Lượng (Sea 1 • Lv. 120–260)", Realm="GoldenSky", Level=120, TargetLevel=260, XP=320000, Gold=3500, CoreShards=150,
        Text="Năng lượng cầu sang Quảng Trường Lumen đã cạn. Hãy đánh bại 3 Corrupted Guard và bật 3 Trạm Năng Lượng.",
        Objectives={{Kind="Kill", Target="CorruptedGuard", Count=3, Label="Hạ gục Corrupted Guard"},
        {Kind="Interact", Target="Station1", Count=1, Label="Bật Trạm 1"}, {Kind="Interact", Target="Station2", Count=1, Label="Bật Trạm 2"}, {Kind="Interact", Target="Station3", Count=1, Label="Bật Trạm 3"}}},
    {Id="Q03", Name="Giải Cứu Quảng Trường Lumen (Sea 1 • Lv. 260–420)", Realm="GoldenSky", Level=260, TargetLevel=420, XP=720000, Gold=6000, CoreShards=220,
        Text="Cầu ánh sáng đã mở. Hãy giải cứu 3 người dân bị mắc kẹt và đánh bại Tinh Anh Golden Knight tại quảng trường.",
        Objectives={{Kind="Interact", Target="Citizen1", Count=1, Label="Cứu người dân 1"}, {Kind="Interact", Target="Citizen2", Count=1, Label="Cứu người dân 2"}, {Kind="Interact", Target="Citizen3", Count=1, Label="Cứu người dân 3"}, {Kind="Kill", Target="GoldenKnight", Count=1, Label="Hạ gục Golden Knight"}}},
    {Id="Q04", Name="Chìa Khóa Tháp Ánh Sáng (Sea 1 • Lv. 420–560)", Realm="GoldenSky", Level=420, TargetLevel=560, XP=1100000, Gold=9000, CoreShards=300,
        Text="Tiến tới Tiền Điện Aureon, kích hoạt 2 Công Tắc Cổ Ngữ và hạ 3 Light Archer để nhận Chìa Khóa Đấu Trường.",
        Objectives={{Kind="Interact", Target="Switch1", Count=1, Label="Bật Công tắc 1"}, {Kind="Interact", Target="Switch2", Count=1, Label="Bật Công tắc 2"}, {Kind="Kill", Target="LightArcher", Count=3, Label="Hạ gục Light Archer"}}},
    {Id="Q05", Name="Trái Tim Ánh Sáng (Boss Sea 1 • Đột Phá Lv. 700)", Realm="GoldenSky", Level=560, TargetLevel=700, XP=1800000, Gold=15000, CoreShards=500,
        Text="Tiến vào Đấu Trường Tháp Ánh Sáng và đánh bại AUREON SENTINEL [Lv.700]. Phá hủy 2 trụ năng lượng khi Boss bật khiên để mở khóa Sea 2 (Lv. 700)!",
        Objectives={{Kind="Kill", Target="AureonSentinel", Count=1, Label="Đánh bại Boss Aureon Sentinel [Lv.700]"}}},

    -- CHƯƠNG 2: SEA 2 • FROZEN CYBER (Lv. 700 - 1500)
    {Id="Q06", Name="Đột Nhập Thành Trì Băng Giá (Sea 2 • Lv. 700–960)", Realm="FrozenCyber", Level=700, TargetLevel=960, XP=3200000, Gold=22000, CoreShards=600,
        Text="Cổng dịch chuyển Sea 2 • Frozen Cyber đã mở! Hãy tiêu diệt 3 Frost Automaton và 2 Cryo Vanguard để mở đường vào trung tâm.",
        Objectives={{Kind="Kill", Target="FrostDrone", Count=3, Label="Hạ gục Frost Automaton"}, {Kind="Kill", Target="CryoGuard", Count=2, Label="Hạ gục Cryo Vanguard"}}},
    {Id="Q07", Name="Lõi Lượng Tử Nổi Loạn (Sea 2 • Lv. 960–1240)", Realm="FrozenCyber", Level=960, TargetLevel=1240, XP=4800000, Gold=32000, CoreShards=750,
        Text="Tại Phòng Thí Nghiệm Đột Kích (hoặc vùng biển mây Sea 2), hãy đánh bại ORDER • Lõi Lượng Tử hoặc Thủy Quái Sky Sea Beast.",
        Objectives={{Kind="Kill", Target="OrderCyborg", Count=1, Label="Đánh bại Order Cyborg / Sky Sea Beast"}}},
    {Id="Q08", Name="Thực Thể Băng Giá Vĩnh Cửu (Boss Sea 2 • Đột Phá Lv. 1500)", Realm="FrozenCyber", Level=1240, TargetLevel=1500, XP=6800000, Gold=45000, CoreShards=1000,
        Text="Tiến vào Đấu Trường Băng Giá và tiêu diệt CRYON PRIME [Lv.1500]. Phá 3 Cột Băng Vĩnh Cửu để tiến vào Sea 3 (Lv. 1500)!",
        Objectives={{Kind="Kill", Target="CryonPrime", Count=1, Label="Đánh bại Boss Cryon Prime [Lv.1500]"}}},

    -- CHƯƠNG 3: SEA 3 • SHADOW REALM (Lv. 1500 - 2200)
    {Id="Q09", Name="Quân Đoàn Bóng Đêm (Sea 3 • Lv. 1500–1750)", Realm="ShadowRealm", Level=1500, TargetLevel=1750, XP=8500000, Gold=60000, CoreShards=1200,
        Text="Bước qua cổng Hư Không vào Sea 3 • Shadow Realm. Hãy thanh trừng 3 Void Marauder và 2 Kỵ Sĩ Hắc Ám Abyssal Dreadknight.",
        Objectives={{Kind="Kill", Target="VoidPirate", Count=3, Label="Hạ gục Void Marauder"}, {Kind="Kill", Target="AbyssalKnight", Count=2, Label="Hạ gục Abyssal Dreadknight"}}},
    {Id="Q10", Name="Săn Lùng Thủy Tổ Hư Không (Sea 3 • Lv. 1750–1980)", Realm="ShadowRealm", Level=1750, TargetLevel=1980, XP=11000000, Gold=80000, CoreShards=1500,
        Text="Tiến vào Vực Thẳm Leviathan (hoặc Điện Thờ Lõi) tại Shadow Realm và đánh bại Thủy Tổ ABYSSAL LEVIATHAN hoặc SOUL REAPER.",
        Objectives={{Kind="Kill", Target="AbyssalLeviathan", Count=1, Label="Đánh bại Abyssal Leviathan / Soul Reaper"}}},
    {Id="Q11", Name="Chúa Tể Hư Không (Boss Sea 3 • Đột Phá Lv. 2200)", Realm="ShadowRealm", Level=1980, TargetLevel=2200, XP=14000000, Gold=110000, CoreShards=2000,
        Text="Đối mặt với NOXAR • THE VOID SOVEREIGN [Lv.2200] tại Đấu Trường Hắc Tinh. Phá hủy Void Singularity để đoạt lấy Song Kiếm Huyền Thoại!",
        Objectives={{Kind="Kill", Target="Noxar", Count=1, Label="Đánh bại Boss Noxar • Void Sovereign [Lv.2200]"}}},

    -- CHƯƠNG 4 - 5: CÁC CÕI GIỚI THƯỢNG CỔ & CHUNG CUỘC (Lv. 2200 - 2550 MAX)
    {Id="Q12", Name="Thức Tỉnh Nguyên Tố Cổ Đại (Realms 4–5 • Lv. 2200–2340)", Realm="VerdantCrown", Level=2200, TargetLevel=2340, XP=18000000, Gold=150000, CoreShards=2500,
        Text="Dịch chuyển tới Verdant Crown và Emberforge Wastes để chinh phục Đại Cổ Thụ SYLVARIS [Lv.2250] cùng Titan Lửa IGNIVAR [Lv.2325].",
        Objectives={{Kind="Kill", Target="Sylvaris", Count=1, Label="Đánh bại Sylvaris (Verdant Crown)"}, {Kind="Kill", Target="Ignivar", Count=1, Label="Đánh bại Ignivar (Emberforge Wastes)"}}},
    {Id="Q13", Name="Vượt Qua Dòng Chảy Thời Gian (Realms 6–7 • Lv. 2340–2480)", Realm="ChronosBastion", Level=2340, TargetLevel=2480, XP=24000000, Gold=220000, CoreShards=3200,
        Text="Tiến vào Abyssal Tides và Chronos Bastion để đánh bại Thủy Hoàng NERITH [Lv.2400] và Pháp Vương Thời Gian AION [Lv.2475].",
        Objectives={{Kind="Kill", Target="Nerith", Count=1, Label="Đánh bại Nerith (Abyssal Tides)"}, {Kind="Kill", Target="Aion", Count=1, Label="Đánh bại Aion (Chronos Bastion)"}}},
    {Id="Q14", Name="Đấng Kiến Tạo Đầu Tiên (Chung Cuộc • MAX LV. 2550)", Realm="VeilsEnd", Level=2480, TargetLevel=2550, XP=40000000, Gold=350000, CoreShards=5000,
        Text="Bước lên Đỉnh Phán Quyết tại Veil's End và đánh bại Boss tối thượng VEYR • ĐẤNG KIẾN TẠO ĐẦU TIÊN [Lv.2550] để đạt MAX LEVEL 2550!",
        Objectives={{Kind="Kill", Target="Veyr", Count=1, Label="Đánh bại Final Boss Veyr [Lv.2550]"}}},
}

-- ============================================================================
-- 3D ARSENAL EXPANSION MERGE (45+ Assets, 8 Wearable Armor Sets, Vendor Catalogs & Parity)
-- ============================================================================
do
    local ReplicatedStorage = (game ~= nil and game.GetService) and game:GetService("ReplicatedStorage") or nil
    local skyShared = ReplicatedStorage and ReplicatedStorage.FindFirstChild and (ReplicatedStorage:FindFirstChild("SkybreakShared") or (ReplicatedStorage.WaitForChild and ReplicatedStorage:WaitForChild("SkybreakShared", 5))) or nil
    local cfgFolder = skyShared and skyShared.FindFirstChild and (skyShared:FindFirstChild("Config") or (skyShared.WaitForChild and skyShared:WaitForChild("Config", 5))) or nil
    local expMod = cfgFolder and cfgFolder.FindFirstChild and cfgFolder:FindFirstChild("ArsenalExpansionConfig") or nil
    local rarMod = cfgFolder and cfgFolder.FindFirstChild and cfgFolder:FindFirstChild("RarityConfig") or nil
    local ArsenalExp = expMod and require(expMod) or nil
    local RarityCfg = rarMod and require(rarMod) or nil

    if ArsenalExp then
        C.ArsenalExpansion = ArsenalExp
        C.ArmorSets = ArsenalExp.ArmorSets
        C.ArmorSetsById = ArsenalExp.ArmorSetsById
        C.GetActiveArmorSetInfo = ArsenalExp.GetActiveArmorSetInfo
        C.VendorCatalogs = ArsenalExp.VendorCatalogs

        local swordExists = {}
        for _, sid in ipairs(C.SwordOrder) do
            swordExists[sid] = true
        end
        local gunExists = {}
        for _, gid in ipairs(C.GunOrder) do
            gunExists[gid] = true
        end

        for itemId, def in pairs(ArsenalExp.Items) do
            local st = type(def.Stats) == "table" and def.Stats or {}
            local isGun = (def.WeaponType == "Gun" or def.Icon == "Gun")
            local mappedSlot = isGun and "Gun"
                or ((def.Category == "Materials" or def.Slot == nil) and "Material" or tostring(def.Slot))
            local displayName = (def.VietnameseName and def.Name and (def.VietnameseName .. " • " .. def.Name))
                or def.VietnameseName or def.Name or itemId

            if C.Items[itemId] == nil then
                C.Items[itemId] = {
                    Id = itemId,
                    Name = displayName,
                    VietnameseName = def.VietnameseName or def.Name,
                    EnglishName = def.Name,
                    Slot = mappedSlot,
                    CanonicalSlot = def.Slot,
                    Category = def.Category,
                    WeaponType = def.WeaponType,
                    Rarity = def.Rarity or "Rare",
                    LevelReq = def.LevelReq or 1,
                    Sea = def.Sea,
                    Realm = def.Realm,
                    PriceGold = def.PriceGold or 0,
                    PriceShards = def.PriceShards or 0,
                    Model3DKind = def.Model3DKind,
                    AccentHex = def.AccentHex,
                    ArmorSetId = def.ArmorSetId,
                    ATK = st.ATK or 0,
                    DEF = st.DEF or 0,
                    HP = st.HP or 0,
                    CritRate = st.CRIT or 0,
                    CritDmg = def.CritDmg or ((st.CRIT and st.CRIT > 0) and (st.CRIT * 2) or 0),
                    SkillZ = def.SkillZ,
                    SkillX = def.SkillX,
                    Desc = def.Description or "",
                }
            end

            if def.Category == "Weapons" and not isGun and C.Swords[itemId] == nil then
                local elem = def.Element or "Sky"
                C.Swords[itemId] = {
                    Id = itemId,
                    Name = displayName,
                    Rarity = def.Rarity or "Legendary",
                    ATK = st.ATK or 95,
                    DEF = st.DEF or 0,
                    CritRate = st.CRIT or 15,
                    CritDmg = def.CritDmg or 30,
                    Element = elem,
                    Model3DKind = def.Model3DKind,
                    AccentHex = def.AccentHex,
                    Desc = def.Description or "",
                    Moves = {
                        Z = {
                            Key = "Z",
                            Name = tostring(def.SkillZ or "Thần Trảm"),
                            Mastery = 1,
                            Cooldown = 5.2,
                            Cost = 12,
                            Range = 30,
                            Multiplier = 3.4,
                            Break = 36,
                            Element = elem,
                        },
                        X = {
                            Key = "X",
                            Name = tostring(def.SkillX or "Tuyệt Kỹ Hư Không"),
                            Mastery = 100,
                            Cooldown = 10.5,
                            Cost = 20,
                            Range = 34,
                            Multiplier = 4.8,
                            Break = 52,
                            Element = elem,
                        },
                    },
                }
                if not swordExists[itemId] then
                    swordExists[itemId] = true
                    table.insert(C.SwordOrder, itemId)
                end
            elseif isGun and C.Guns[itemId] == nil then
                local elem = def.Element or "Sky"
                C.Guns[itemId] = {
                    Id = itemId,
                    Name = displayName,
                    Rarity = def.Rarity or "Legendary",
                    ATK = st.ATK or 95,
                    CritRate = st.CRIT or 16,
                    CritDmg = def.CritDmg or 34,
                    Element = elem,
                    Model3DKind = def.Model3DKind,
                    AccentHex = def.AccentHex,
                    Desc = def.Description or "",
                    Moves = {
                        Z = {
                            Key = "Z",
                            Name = tostring(def.SkillZ or "Pháo Kích Aether"),
                            Mastery = 1,
                            Cooldown = 5.5,
                            Cost = 12,
                            Range = 46,
                            Multiplier = 3.5,
                            Break = 38,
                            Element = elem,
                        },
                        X = {
                            Key = "X",
                            Name = tostring(def.SkillX or "Bão Đạn Hủy Diệt"),
                            Mastery = 120,
                            Cooldown = 11.0,
                            Cost = 18,
                            Range = 48,
                            Multiplier = 4.9,
                            Break = 54,
                            Element = elem,
                        },
                    },
                }
                if not gunExists[itemId] then
                    gunExists[itemId] = true
                    table.insert(C.GunOrder, itemId)
                end
            end
        end

        -- Merge Expansion Forge Recipes into C.ForgeRecipes
        for _, expRec in ipairs(ArsenalExp.ExpansionRecipes or {}) do
            local outId = expRec.OutputItemId or expRec.Id
            if outId and not recipeById[outId] and not recipeById[expRec.Id] then
                local matMap = {}
                for _, m in ipairs(expRec.Materials or {}) do
                    if m and m.ItemId then
                        matMap[m.ItemId] = m.Count or 1
                    end
                end
                local entry = {
                    Id = outId,
                    RecipeId = expRec.Id,
                    ItemId = outId,
                    Name = expRec.Name,
                    Slot = expRec.Slot or "Weapon",
                    Rarity = expRec.Rarity or "Legendary",
                    Gold = expRec.GoldCost or 1000,
                    CoreShards = expRec.CoreShardCost or 0,
                    Materials = matMap,
                    Desc = expRec.Description or "",
                }
                table.insert(recipeList, entry)
                recipeById[outId] = entry
                recipeById[expRec.Id] = entry
            end
        end
    end

    -- 7th Martial Style (ChronoVoidPalm) & Shipwright Fleet Aliases
    if not C.FightingStyles.ChronoVoidPalm then
        local chronoDef = {
            Id = "ChronoVoidPalm",
            Name = "Chưởng Pháp Thời Không - Chrono Void Palm",
            PriceGold = 5000000,
            PriceShards = 5000,
            Element = "Void",
            Desc = "Tuyệt kỹ chưởng pháp bẻ cong thời không của Pháp Vương Aion, ngưng đọng kẻ địch và nổ xung kỳ điểm.",
            Moves = {
                Z = { Key = "Z", Name = "Chrono Ripple Palm - Chưởng Gợn Thời Gian", Mastery = 1, Cooldown = 4.6, Cost = 12, Range = 30, Multiplier = 3.5, Break = 38, Element = "Void", Desc = "Tung chưởng xuyên không làm chậm và chấn vỡ phòng ngự." },
                X = { Key = "X", Name = "Stasis Collapse - Nhãn Ấn Ngưng Đọng", Mastery = 75, Cooldown = 8.2, Cost = 18, Range = 32, Multiplier = 4.4, Break = 50, Element = "Void", Desc = "Đóng băng nhịp thời gian quanh mục tiêu rồi kích nổ hư không." },
                C = { Key = "C", Name = "Genesis Singularity Strike - Vạn Kiếp Quy Không Chưởng", Mastery = 150, Cooldown = 11.5, Cost = 24, Range = 36, Multiplier = 5.7, Break = 65, Element = "Void", Desc = "Dịch chuyển xuyên thời không giáng đại chưởng kỳ điểm tối thượng." },
            },
        }
        C.FightingStyles.ChronoVoidPalm = chronoDef
        C.FightingStyles.chrono_void_palm = chronoDef
    end

    if not C.SkyShips.CyberEnforcerShip then
        C.SkyShips.CyberEnforcerShip = {
            Id = "CyberEnforcerShip",
            Name = "Tuần Dương Hạm Băng • Cyber Enforcer",
            HP = 6000,
            Speed = 78,
            Price = 45000,
            Desc = "Chiến hạm bọc thép từ trường của Sea 2, lướt nhanh qua bão băng.",
        }
    end
    if not C.SkyShips.CelestialAetherGalleon then
        C.SkyShips.CelestialAetherGalleon = {
            Id = "CelestialAetherGalleon",
            Name = "Đại Chiến Hạm Thánh Quang • Celestial Aether Galleon",
            HP = 9200,
            Speed = 86,
            Price = 250000,
            Desc = "Đại chiến hạm buồm ánh sáng hoàng kim trang bị 6 đại pháo mạn tàu.",
        }
    end

    -- Enforce 100% ItemCatalog.ConfigRarityParity in both directions
    if RarityCfg and type(RarityCfg.Items) == "table" then
        for itemId, cItem in pairs(C.Items) do
            if RarityCfg.Items[itemId] == nil then
                RarityCfg.Items[itemId] = {
                    Id = itemId,
                    Name = cItem.Name or itemId,
                    Category = (cItem.Slot == "Weapon" or cItem.Slot == "Gun") and "Weapons"
                        or ((cItem.Slot == "Material" or cItem.Slot == "Quest") and "Materials" or "Armor"),
                    Slot = (cItem.Slot == "Material" or cItem.Slot == "Quest") and nil
                        or (cItem.Slot == "Gun" and "Offhand" or cItem.Slot),
                    WeaponType = (cItem.Slot == "Gun") and "Gun" or nil,
                    Rarity = cItem.Rarity or "Common",
                    LevelReq = cItem.LevelReq or 1,
                    Icon = (cItem.Slot == "Gun") and "Gun" or ((cItem.Slot == "Weapon") and "Sword" or "Shield"),
                    Stats = {
                        ATK = cItem.ATK,
                        DEF = cItem.DEF,
                        HP = cItem.HP,
                        CRIT = cItem.CritRate,
                    },
                    Description = cItem.Desc or "",
                }
            end
        end
        for itemId, rItem in pairs(RarityCfg.Items) do
            if C.Items[itemId] == nil then
                local st = type(rItem.Stats) == "table" and rItem.Stats or {}
                local isGun = (rItem.WeaponType == "Gun" or rItem.Icon == "Gun")
                C.Items[itemId] = {
                    Id = itemId,
                    Name = rItem.VietnameseName or rItem.Name or itemId,
                    Slot = isGun and "Gun" or ((rItem.Category == "Materials" or rItem.Slot == nil) and "Material" or rItem.Slot),
                    Rarity = rItem.Rarity or "Common",
                    LevelReq = rItem.LevelReq or 1,
                    ATK = st.ATK or 0,
                    DEF = st.DEF or 0,
                    HP = st.HP or 0,
                    CritRate = st.CRIT or 0,
                    Desc = rItem.Description or "",
                }
            end
        end
    end
end

function C.GetDragonFormMoves(tier)
    local dragonCfg = C.AetherFruits and C.AetherFruits.AbyssalSovereignCore
    if not dragonCfg then
        return nil
    end
    if tonumber(tier) and tonumber(tier) >= 2 then
        return dragonCfg.Form2Moves or dragonCfg.Moves
    end
    return dragonCfg.Form1Moves or dragonCfg.Moves
end

if game:GetService("RunService"):IsServer() then
    task.spawn(function()
        local function isDisabledRailOrCompanionInstance(inst)
            if not inst then
                return false
            end
            local n = inst.Name
            if n == "SkyRailPad" or string.sub(n, 1, 10) == "RailTrack_" or string.sub(n, 1, 14) == "AetherSkyRail_" then
                return true
            end
            if inst:GetAttribute("CompanionId") ~= nil then
                return true
            end
            return false
        end

        local function purgeDisabledWorldFeatures()
            for _, fname in ipairs({ "JumpPads", "AetherSkyRails", "ActiveCompanions" }) do
                local f = workspace:FindFirstChild(fname)
                if f then
                    f:ClearAllChildren()
                end
            end
            for _, folderName in ipairs({ "ActiveEnemies", "SkybreakWorldObjects", "SkybreakExpansionWorld" }) do
                local ef = workspace:FindFirstChild(folderName)
                if ef then
                    for _, d in ipairs(ef:GetDescendants()) do
                        if d.Name == "DummyFloorRing" and d:IsA("BasePart") then
                            d.Transparency = 1
                            d.CanCollide = false
                            d.CanQuery = false
                            d.CanTouch = false
                        elseif isDisabledRailOrCompanionInstance(d) then
                            pcall(function() d:Destroy() end)
                        end
                    end
                end
            end
        end

        workspace.ChildAdded:Connect(function(child)
            if child.Name == "JumpPads" or child.Name == "AetherSkyRails" or child.Name == "ActiveCompanions" then
                task.defer(function()
                    if child.Parent then
                        child:ClearAllChildren()
                    end
                end)
                child.ChildAdded:Connect(function(sub)
                    task.defer(function()
                        if sub and sub.Parent then
                            pcall(function() sub:Destroy() end)
                        end
                    end)
                end)
            end
        end)

        workspace.DescendantAdded:Connect(function(desc)
            if isDisabledRailOrCompanionInstance(desc) then
                task.defer(function()
                    if desc and desc.Parent then
                        pcall(function() desc:Destroy() end)
                    end
                end)
            elseif desc.Name == "DummyFloorRing" and desc:IsA("BasePart") then
                task.defer(function()
                    desc.Transparency = 1
                    desc.CanCollide = false
                    desc.CanQuery = false
                    desc.CanTouch = false
                end)
            end
        end)

        local tickIdx = 0
        while true do
            tickIdx += 1
            task.wait(tickIdx <= 40 and 0.25 or 0.5)
            purgeDisabledWorldFeatures()
            local sss = game:GetService("ServerScriptService")
            local services = sss and sss:FindFirstChild("Services")
            local gsMod = services and services:FindFirstChild("GameService")
            local pdMod = services and services:FindFirstChild("PlayerDataService")
            if gsMod then
                local okG, G = pcall(require, gsMod)
                local okD, D = false, nil
                if pdMod then
                    okD, D = pcall(require, pdMod)
                end
                if okG and type(G) == "table" then
                    if type(G.JumpPads) == "table" then
                        table.clear(G.JumpPads)
                    end
                    G.SyncCompanions = function(p)
                        if G.Runtime and G.Runtime[p] and type(G.Runtime[p].Companions) == "table" then
                            for k, comp in pairs(G.Runtime[p].Companions) do
                                if comp and comp.Model then
                                    pcall(function() comp.Model:Destroy() end)
                                end
                                G.Runtime[p].Companions[k] = nil
                            end
                        end
                        local ac = workspace:FindFirstChild("ActiveCompanions")
                        if ac then ac:ClearAllChildren() end
                    end
                    G.TickCompanions = function() end

                    if not G._CompanionNotifyFiltered and type(G.Notify) == "function" then
                        G._CompanionNotifyFiltered = true
                        local prevNotify = G.Notify
                        G.Notify = function(p, msg, ...)
                            if type(msg) == "string" and string.find(msg, "Đồng Hành", 1, true) then
                                msg = string.gsub(msg, "%s*•%s*Mở khóa Đồng Hành.*", "")
                            end
                            return prevNotify(p, msg, ...)
                        end
                    end

                    if not G._CompanionSyncFiltered and G.SocialEconomy ~= nil then
                        G._CompanionSyncFiltered = true
                        local prevBeforeSync = G.OnBeforeSync
                        G.OnBeforeSync = function(p, profile, rt, stats, statePayload)
                            if prevBeforeSync then
                                prevBeforeSync(p, profile, rt, stats, statePayload)
                            end
                            if type(profile) == "table" then
                                profile.PartySize = "Solo"
                            end
                            if type(statePayload) == "table" then
                                statePayload.PartySize = "Solo"
                                statePayload.Companions = {}
                            end
                        end
                    end

                    if type(G.Runtime) == "table" then
                        for plr, rt in pairs(G.Runtime) do
                            if type(rt) == "table" then
                                rt.FuryMeter = 100
                                if type(rt.Companions) == "table" then
                                    for k, comp in pairs(rt.Companions) do
                                        if comp and comp.Model then
                                            pcall(function() comp.Model:Destroy() end)
                                        end
                                        rt.Companions[k] = nil
                                    end
                                end
                            end
                            if plr and plr.Parent then
                                if (plr:GetAttribute("FuryMeter") or 0) < 100 then
                                    plr:SetAttribute("FuryMeter", 100)
                                end
                                local prof = okD and D and type(D.Get) == "function" and D.Get(plr) or nil
                                if type(prof) == "table" and prof.PartySize ~= "Solo" then
                                    prof.PartySize = "Solo"
                                end
                            end
                        end
                    end

                    -- Hook Dual-Form Dragon (Dạng 1: Bán Long Nhân vs Dạng 2: Thái Cổ Long Hoàng) AFTER expansion services initialize
                    if not G._DragonDualFormsHooked and type(G.UseSlotMove) == "function" and (G.SocialEconomy ~= nil or tickIdx >= 16) then
                        G._DragonDualFormsHooked = true
                        local prevUseSlotMove = G.UseSlotMove
                        local prevAction = G.Action
                        local remotesFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                        local combatFXRemote = remotesFolder and remotesFolder:FindFirstChild("CombatFX")

                        local function isDragonFruitId(fid)
                            local s = string.lower(tostring(fid or ""))
                            return s == "abyssalsovereigncore" or s == "dragon" or s == "abyssal_dragon" or s == "void_dragon" or s == "abyssal_sovereign"
                        end

                        local function resolveActiveDragonTier(p, rt)
                            local ch = p and p.Character
                            local t = tonumber(rt and rt.DragonFormTier)
                                or tonumber(ch and ch:GetAttribute("DragonFormTier"))
                                or tonumber(p and p:GetAttribute("DragonFormTier"))
                                or 0
                            local tf = tostring((ch and ch:GetAttribute("FruitTransform")) or (p and p:GetAttribute("FruitTransform")) or "")
                            if t >= 2 or tf == "AbyssalSovereign" then
                                return 2
                            elseif t == 1 or tf == "AbyssalDragonHybrid" then
                                return 1
                            end
                            return 0
                        end

                        local function safeDashPlayer(p, rt, hrp, dist, invDur)
                            local lookVec = hrp.CFrame.LookVector
                            local originPos = hrp.Position
                            local rp = RaycastParams.new()
                            rp.FilterType = Enum.RaycastFilterType.Exclude
                            rp.FilterDescendantsInstances = { p.Character, workspace:FindFirstChild("ActiveEnemies"), workspace:FindFirstChild("ActiveBosses") }
                            rp.RespectCanCollide = true
                            local hit = workspace:Raycast(originPos, lookVec * dist, rp)
                            local target = hit and (hit.Position - lookVec * 2.8) or (originPos + lookVec * dist)
                            rt.InvincibleUntil = math.max(rt.InvincibleUntil or 0, os.clock() + (invDur or 1.2))
                            rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, os.clock() + 1.6)
                            if type(G.Teleport) == "function" then
                                G.Teleport(p, target)
                            else
                                hrp.CFrame = CFrame.new(target) * hrp.CFrame.Rotation
                            end
                            return target
                        end

                        G.Action = function(p, action, payload)
                            local profile = okD and D and type(D.Get) == "function" and D.Get(p) or nil
                            local rt = G.Runtime and G.Runtime[p]
                            local act = tostring(action or "")
                            if (act == "Attack" or act == "Light" or act == "M1") and profile and rt then
                                local slot = math.clamp(tonumber(profile.ActiveSlot) or 2, 1, 4)
                                if slot == 2 and isDragonFruitId(profile.EquippedFruit) then
                                    local ch = p.Character
                                    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
                                    local tier = resolveActiveDragonTier(p, rt)
                                    if hrp and tier > 0 then
                                        local now = os.clock()
                                        local cd = (tier == 2) and 0.46 or 0.34
                                        if now < (rt.Cooldowns and rt.Cooldowns.DragonM1 or 0) then
                                            return
                                        end
                                        rt.Cooldowns = rt.Cooldowns or {}
                                        rt.Cooldowns.DragonM1 = now + cd
                                        rt.FuryMeter = 100
                                        p:SetAttribute("FuryMeter", 100)
                                        if ch then ch:SetAttribute("FuryMeter", 100) end

                                        local combo = ((tonumber(rt.DragonM1Combo) or 0) % 4) + 1
                                        rt.DragonM1Combo = combo
                                        local stats = type(G.Stats) == "function" and G.Stats(p) or { ATK = 65 }
                                        local atk = (stats and stats.ATK) or 65
                                        local reach = (tier == 2) and 28 or 18
                                        local mult = (tier == 2) and (combo == 4 and 2.35 or 1.85) or (combo == 4 and 1.75 or 1.35)
                                        local brk = (tier == 2) and 22 or 14
                                        local center = hrp.Position + hrp.CFrame.LookVector * (reach * 0.45)
                                        for _, e in ipairs(G.Enemies or {}) do
                                            if e.Alive and e.Body and ((e.Body.Position - center).Magnitude <= reach or (e.Body.Position - hrp.Position).Magnitude <= reach) then
                                                G.Hit(p, e, atk * mult, brk, tier == 2 and "SovereignDragonM1" or "HybridDragonM1")
                                            end
                                        end
                                        if combatFXRemote then
                                            combatFXRemote:FireAllClients({
                                                Kind = "Swing",
                                                Action = "Attack",
                                                FruitId = "AbyssalSovereignCore",
                                                DragonFormTier = tier,
                                                SubMode = (tier == 2) and "AbyssalSovereign" or "AbyssalDragonHybrid",
                                                Combo = combo,
                                                Element = "Void",
                                                Position = center,
                                                Origin = hrp.Position,
                                                Direction = hrp.CFrame.LookVector,
                                                Actor = p.UserId,
                                            })
                                        end
                                        return
                                    end
                                end
                            end
                            return prevAction(p, action, payload)
                        end

                        G.UseSlotMove = function(p, rawKey, payload)
                            local profile = okD and D and type(D.Get) == "function" and D.Get(p) or nil
                            local rt = G.Runtime and G.Runtime[p]
                            if profile and rt then
                                local slot = math.clamp(tonumber(profile.ActiveSlot) or 2, 1, 4)
                                local key = string.upper(tostring(rawKey or "Z"))
                                if slot == 2 and isDragonFruitId(profile.EquippedFruit) then
                                    profile.EquippedFruit = "AbyssalSovereignCore"
                                    local ch = p.Character
                                    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
                                    if not hrp then
                                        return
                                    end
                                    rt.FuryMeter = 100
                                    p:SetAttribute("FuryMeter", 100)
                                    if ch then ch:SetAttribute("FuryMeter", 100) end

                                    local curTier = resolveActiveDragonTier(p, rt)
                                    local now = os.clock()
                                    rt.Cooldowns = rt.Cooldowns or {}

                                    -- [V]: Cycle 0 (Nhân dạng) -> 1 (Dạng 1: Bán Long Nhân) -> 2 (Dạng 2: Thái Cổ Long Hoàng) -> 0 (Nhân dạng)
                                    if key == "V" then
                                        if now < (rt.Cooldowns.Slot_V or 0) then
                                            return
                                        end
                                        rt.Cooldowns.Slot_V = now + 1.8
                                        local nextTier = (curTier == 0 and 1) or (curTier == 1 and 2) or 0
                                        local tfName = (nextTier == 2 and "AbyssalSovereign") or (nextTier == 1 and "AbyssalDragonHybrid") or ""
                                        rt.DragonFormTier = nextTier
                                        p:SetAttribute("DragonFormTier", nextTier)
                                        p:SetAttribute("FruitTransform", tfName)
                                        if ch then
                                            ch:SetAttribute("DragonFormTier", nextTier)
                                            ch:SetAttribute("FruitTransform", tfName)
                                        end

                                        local stats = type(G.Stats) == "function" and G.Stats(p) or { ATK = 65 }
                                        local atk = (stats and stats.ATK) or 65
                                        if nextTier == 1 then
                                            G.Notify(p, "[DẠNG 1 • BÁN LONG NHÂN] Mở Bộ Kỹ Năng 1: [Z] Hỏa Long Đạn • [X] Bán Long Trảo • [C] Cuồng Long Xoáy • [F] Long Ảnh Bộ! (Nhấn [V] lần nữa để hóa Rồng Khổng Lồ Dạng 2)")
                                            for _, e in ipairs(G.Enemies or {}) do
                                                if e.Alive and e.Body and (e.Body.Position - hrp.Position).Magnitude <= 28 then
                                                    G.Hit(p, e, atk * 4.0, 42, "DragonHybridAscension_T1")
                                                end
                                            end
                                        elseif nextTier == 2 then
                                            rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, now + 60)
                                            G.Notify(p, "[DẠNG 2 • THÁI CỔ LONG HOÀNG] Mở Bộ Kỹ Năng 2: [Z] Thái Cổ Long Tức • [X] Long Hoàng Giáng Thế • [C] Vạn Long Hỏa Vũ • [F] Long Vũ Cửu Thiên!")
                                            for _, e in ipairs(G.Enemies or {}) do
                                                if e.Alive and e.Body and (e.Body.Position - hrp.Position).Magnitude <= 46 then
                                                    G.Hit(p, e, atk * 6.2, 68, "DragonSovereignAscension_T2")
                                                end
                                            end
                                        else
                                            G.Notify(p, "Đã thu hồi Long Hồn, trở về nhân dạng.")
                                        end

                                        if combatFXRemote then
                                            combatFXRemote:FireAllClients({
                                                Kind = "DragonTransform",
                                                DragonFormTier = nextTier,
                                                TransformName = tfName,
                                                SubMode = tfName,
                                                Awakened = true,
                                                FuryMeter = 100,
                                                Radius = nextTier == 2 and 46 or (nextTier == 1 and 28 or 14),
                                                Position = hrp.Position,
                                                Actor = p.UserId,
                                            })
                                        end
                                        if type(G.Sync) == "function" then
                                            G.Sync(p)
                                        end
                                        return
                                    end

                                    -- [Z], [X], [C], [F]: Distinct Skill Sets for Form 1 (Hybrid / Base) vs Form 2 (Full Sovereign Dragon)
                                    local moveSet = C.GetDragonFormMoves(curTier)
                                    local moveSpec = moveSet and moveSet[key]
                                    if moveSpec then
                                        local cdKey = "Slot_" .. key
                                        if now < (rt.Cooldowns[cdKey] or 0) then
                                            return
                                        end
                                        local cost = tonumber(moveSpec.Cost) or 12
                                        if (rt.Energy or 100) < cost then
                                            G.Notify(p, "Không đủ Aether Energy!")
                                            return
                                        end
                                        rt.Cooldowns[cdKey] = now + (tonumber(moveSpec.Cooldown) or 5.0)
                                        rt.Energy = math.max(0, (rt.Energy or 100) - cost)

                                        local stats = type(G.Stats) == "function" and G.Stats(p) or { ATK = 65 }
                                        local atk = (stats and stats.ATK) or 65
                                        local originPos = hrp.Position
                                        local lookVec = hrp.CFrame.LookVector
                                        local range = tonumber(moveSpec.Range) or 32
                                        local mult = tonumber(moveSpec.Multiplier) or 3.5
                                        local brk = tonumber(moveSpec.Break) or 36
                                        local hits = math.max(1, tonumber(moveSpec.Hits) or 1)
                                        local endPos = originPos + lookVec * range
                                        local subMode = (curTier >= 2) and "AbyssalSovereign" or "AbyssalDragonHybrid"

                                        if curTier >= 2 then
                                            -- === FORM 2 (CHÂN THÂN THÁI CỔ LONG HOÀNG) ===
                                            if key == "Z" then
                                                -- [Z] Thái Cổ Long Tức: 52m Colossal Beam (5 multi-hits along beam corridor)
                                                endPos = originPos + lookVec * 52
                                                for pulse = 1, 5 do
                                                    task.delay((pulse - 1) * 0.10, function()
                                                        if not p or not p.Parent then return end
                                                        for _, e in ipairs(G.Enemies or {}) do
                                                            if e.Alive and e.Body then
                                                                local eb = e.Body.Position
                                                                local proj = math.clamp((eb - originPos):Dot(lookVec), 0, 52)
                                                                local closest = originPos + lookVec * proj
                                                                if (eb - closest).Magnitude <= 22 then
                                                                    G.Hit(p, e, (atk * mult) / 5, math.ceil(brk / 5), "Form2_SovereignBeam_Z")
                                                                end
                                                            end
                                                        end
                                                    end)
                                                end
                                            elseif key == "X" then
                                                -- [X] Long Hoàng Giáng Thế: 28m Skyfall Dive + 3 Tectonic Shockwaves (38m radius)
                                                endPos = safeDashPlayer(p, rt, hrp, 28, 1.4)
                                                for wave = 1, 3 do
                                                    task.delay((wave - 1) * 0.14, function()
                                                        if not p or not p.Parent then return end
                                                        for _, e in ipairs(G.Enemies or {}) do
                                                            if e.Alive and e.Body and (e.Body.Position - endPos).Magnitude <= 38 then
                                                                G.Hit(p, e, (atk * mult) / 3, math.ceil(brk / 3), "Form2_SovereignSkyfall_X")
                                                                e.StunnedUntil = math.max(e.StunnedUntil or 0, os.clock() + 1.8)
                                                            end
                                                        end
                                                    end)
                                                end
                                            elseif key == "C" then
                                                -- [C] Vạn Long Thiên Hỏa Vũ: 6-wave Eclipse Meteor Starshower across 48m radius
                                                endPos = originPos + lookVec * 22
                                                for wave = 1, 6 do
                                                    task.delay((wave - 1) * 0.14, function()
                                                        if not p or not p.Parent then return end
                                                        for _, e in ipairs(G.Enemies or {}) do
                                                            if e.Alive and e.Body and (e.Body.Position - endPos).Magnitude <= 48 then
                                                                G.Hit(p, e, (atk * mult) / 6, math.ceil(brk / 6), "Form2_EclipseStarshower_C")
                                                            end
                                                        end
                                                    end)
                                                end
                                            elseif key == "F" then
                                                -- [F] Long Vũ Cửu Thiên: 58m Supersonic Flight Rush
                                                endPos = safeDashPlayer(p, rt, hrp, 58, 1.8)
                                                local mid = (originPos + endPos) * 0.5
                                                for _, e in ipairs(G.Enemies or {}) do
                                                    if e.Alive and e.Body and ((e.Body.Position - endPos).Magnitude <= 26 or (e.Body.Position - mid).Magnitude <= 28) then
                                                        G.Hit(p, e, atk * mult, brk, "Form2_SupersonicSoar_F")
                                                    end
                                                end
                                            end
                                        else
                                            -- === FORM 1 (BÁN LONG NHÂN / HYBRID DRAGON) ===
                                            if key == "Z" then
                                                -- [Z] Hỏa Long Liên Đạn: 3-Fireball Volley (3 sequential explosions along 32m line)
                                                endPos = originPos + lookVec * 32
                                                for shot = 1, 3 do
                                                    task.delay((shot - 1) * 0.11, function()
                                                        if not p or not p.Parent then return end
                                                        local impactPos = originPos + lookVec * (10 * shot)
                                                        for _, e in ipairs(G.Enemies or {}) do
                                                            if e.Alive and e.Body and ((e.Body.Position - impactPos).Magnitude <= 18 or (e.Body.Position - endPos).Magnitude <= 18) then
                                                                G.Hit(p, e, (atk * mult) / 3, math.ceil(brk / 3), "Form1_FireballVolley_Z")
                                                            end
                                                        end
                                                    end)
                                                end
                                            elseif key == "X" then
                                                -- [X] Bán Long Đột Trảo: 20m Claw Rush + Grab Slam
                                                endPos = safeDashPlayer(p, rt, hrp, 20, 1.0)
                                                for _, e in ipairs(G.Enemies or {}) do
                                                    if e.Alive and e.Body and ((e.Body.Position - endPos).Magnitude <= 22 or (e.Body.Position - originPos).Magnitude <= 20) then
                                                        G.Hit(p, e, atk * mult, brk, "Form1_HybridTalonRend_X")
                                                        e.StunnedUntil = math.max(e.StunnedUntil or 0, os.clock() + 1.2)
                                                    end
                                                end
                                            elseif key == "C" then
                                                -- [C] Cuồng Long Lốc Xoáy: 4-pulse Spinning Inferno Blade Vortex around player (pulls enemies in)
                                                endPos = originPos
                                                for pulse = 1, 4 do
                                                    task.delay((pulse - 1) * 0.12, function()
                                                        if not p or not p.Parent then return end
                                                        local curPos = (p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character.HumanoidRootPart.Position) or originPos
                                                        for _, e in ipairs(G.Enemies or {}) do
                                                            if e.Alive and e.Body and (e.Body.Position - curPos).Magnitude <= 28 then
                                                                G.Hit(p, e, (atk * mult) / 4, math.ceil(brk / 4), "Form1_InfernoCyclone_C")
                                                                if not (e.Config and e.Config.Boss) and (e.Config and (e.Config.Speed or 0) > 0) and e.Model then
                                                                    local pullPos = e.Body.Position:Lerp(Vector3.new(curPos.X, e.Body.Position.Y, curPos.Z), 0.35)
                                                                    local rot = e.Body.CFrame - e.Body.Position
                                                                    e.Model:PivotTo(CFrame.new(pullPos) * rot)
                                                                end
                                                            end
                                                        end
                                                    end)
                                                end
                                            elseif key == "F" then
                                                -- [F] Long Ảnh Bộ: 36m Rapid Crimson Wing Dash
                                                endPos = safeDashPlayer(p, rt, hrp, 36, 1.2)
                                                for _, e in ipairs(G.Enemies or {}) do
                                                    if e.Alive and e.Body and (e.Body.Position - endPos).Magnitude <= 18 then
                                                        G.Hit(p, e, atk * mult, brk, "Form1_HybridWingDash_F")
                                                    end
                                                end
                                            end
                                        end

                                        if combatFXRemote then
                                            combatFXRemote:FireAllClients({
                                                Kind = "FruitMove",
                                                Action = "Fruit" .. key,
                                                Awakened = (curTier >= 2),
                                                FruitId = "AbyssalSovereignCore",
                                                activeId = "AbyssalSovereignCore",
                                                MoveKey = key,
                                                key = key,
                                                MoveName = moveSpec.Name,
                                                Mechanic = moveSpec.Mechanic,
                                                DragonFormTier = (curTier >= 2) and 2 or 1,
                                                SubMode = subMode,
                                                Hits = hits,
                                                Element = "Void",
                                                Origin = originPos,
                                                StartPos = originPos,
                                                Position = endPos,
                                                EndPos = endPos,
                                                Direction = lookVec,
                                                Radius = range,
                                                Actor = p.UserId,
                                            })
                                        end
                                        if type(G.Sync) == "function" then
                                            G.Sync(p)
                                        end
                                        return
                                    end
                                end
                            end
                            return prevUseSlotMove(p, rawKey, payload)
                        end

                        task.spawn(function()
                            while true do
                                task.wait(0.5)
                                if type(G.Runtime) == "table" then
                                    for plr, rt in pairs(G.Runtime) do
                                        if type(rt) == "table" then
                                            rt.FuryMeter = 100
                                            if plr and plr.Parent then
                                                if (plr:GetAttribute("FuryMeter") or 0) < 100 then
                                                    plr:SetAttribute("FuryMeter", 100)
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end)
                    end
                end
            end
        end
    end)
end

return C
