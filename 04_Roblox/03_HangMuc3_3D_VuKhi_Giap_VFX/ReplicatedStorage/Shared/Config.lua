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
    return math.floor(150 + 38 * (lv - 1) + 0.14 * ((lv - 1) ^ 1.75))
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
    SkySlash = {Id='SkySlash', Name='Sky Slash', Key='1', Type='Active', Element='Sky', ClassId='SkyGuardian', Cooldown=6.5, Cost=12, Range=18, Multiplier=1.65, Break=14, Level=1, Desc='Chém vòng cung ánh sáng tầm trung, gây 165% sát thương ATK và phá giáp.'},
    GuardianShield = {Id='GuardianShield', Name='Guardian Shield', Key='2', Type='Defense', Element='Sky', ClassId='SkyGuardian', Cooldown=16, Cost=18, Range=20, Multiplier=0, Break=0, Level=1, Desc='Tạo khiên thánh quang cho bản thân và đồng đội xung quanh trong 4 giây, giảm 35% sát thương nhận vào.'},
    JudgmentStrike = {Id='JudgmentStrike', Name='Judgment Strike', Key='3', Type='Heavy Skill', Element='Sky', ClassId='SkyGuardian', Cooldown=11, Cost=20, Range=20, Multiplier=2.25, Break=20, Level=1, Desc='Giáng đòn phán xét từ trên cao xuống mục tiêu phía trước, gây 225% sát thương ATK và 20 Break.'},
    CelestialAegis = {Id='CelestialAegis', Name='Celestial Aegis', Key='R', Type='Ultimate', Element='Sky', ClassId='SkyGuardian', Cooldown=22, Cost=28, Range=24, Multiplier=3.1, Break=28, Level=1, Desc='Tuyệt kỹ Thiên Khiên: Bùng nổ thánh quang diện rộng gây 310% sát thương ATK và ban khiên hộ thể.'},

    ArcCut = {Id='ArcCut', Name='Arc Cut', Key='1', Type='Combo Skill', Element='Lightning', ClassId='ThunderStriker', Cooldown=5.5, Cost=12, Range=12, Multiplier=0.72, Break=6, Level=1, Desc='Tung 3 nhát chém lôi điện cực nhanh liên tiếp, mỗi đòn gây 72% sát thương ATK.'},
    FlashStep = {Id='FlashStep', Name='Flash Step', Key='2', Type='Mobility', Element='Lightning', ClassId='ThunderStriker', Cooldown=9, Cost=16, Range=20, Multiplier=1.1, Break=8, Level=1, Desc='Lướt chớp nhoáng 20m qua không trung, gây sát thương lôi điện trên đường lướt.'},
    StormBlitz = {Id='StormBlitz', Name='Storm Blitz', Key='3', Type='Burst Skill', Element='Lightning', ClassId='ThunderStriker', Cooldown=12, Cost=20, Range=16, Multiplier=2.35, Break=18, Level=1, Desc='Bão kiếm sấm sét càn quét xung quanh, gây 235% sát thương ATK và kích hoạt 5 tầng tốc đánh.'},
    ThunderJudgement = {Id='ThunderJudgement', Name='Thunder Judgement', Key='R', Type='Ultimate', Element='Lightning', ClassId='ThunderStriker', Cooldown=22, Cost=28, Range=24, Multiplier=3.25, Break=26, Level=1, Desc='Tuyệt kỹ Lôi Phạt: Triệu hồi thiên lôi giáng xuống toàn bộ kẻ địch trong bán kính 24m, gây 325% sát thương ATK.'},

    FrostBolt = {Id='FrostBolt', Name='Frost Bolt', Key='1', Type='Ranged Spell', Element='Frost', ClassId='ArcaneMage', Cooldown=6.0, Cost=12, Range=40, Multiplier=1.7, Break=14, Level=1, Desc='Bắn mũi tên băng tinh tầm xa 40m, gây 170% sát thương phép và làm suy yếu giáp kẻ địch.'},
    ManaBarrier = {Id='ManaBarrier', Name='Mana Barrier', Key='2', Type='Arcane Ward', Element='Frost', ClassId='ArcaneMage', Cooldown=16, Cost=18, Range=18, Multiplier=0, Break=0, Level=1, Desc='Kết giới ma lực bao bọc cơ thể trong 4 giây, hấp thụ 35% sát thương và hồi nhẹ Stamina.'},
    ArcaneComet = {Id='ArcaneComet', Name='Arcane Comet', Key='3', Type='AoE Spell', Element='Void', ClassId='ArcaneMage', Cooldown=12, Cost=22, Range=34, Multiplier=2.4, Break=18, Level=1, Desc='Triệu hồi sao chổi cổ ngữ rơi xuống mục tiêu tầm xa, gây 240% sát thương diện rộng.'},
    AstralCataclysm = {Id='AstralCataclysm', Name='Astral Cataclysm', Key='R', Type='Ultimate', Element='Void', ClassId='ArcaneMage', Cooldown=22, Cost=28, Range=36, Multiplier=3.35, Break=28, Level=1, Desc='Tuyệt kỹ Tinh Vân Đại Diệt: Nổ tung trường trọng lực hư không tầm xa, gây 335% sát thương phép.'},
}

C.Stats = function(level, classId, statAlloc)
    local lv = math.clamp(tonumber(level) or 1, 1, C.MaxLevel)
    local class = C.Classes[classId or 'SkyGuardian'] or C.Classes.SkyGuardian
    local baseCrit = classId == 'ThunderStriker' and 8 or (classId == 'ArcaneMage' and 6 or 4)
    local baseCritDmg = classId == 'ThunderStriker' and 30 or 25
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
        HP = math.floor((110 + 1.45 * (lv - 1) + 2.6 * defPts) * class.HP),
        ATK = math.floor((10 + 0.09 * (lv - 1) + 0.18 * offensePts) * class.ATK),
        DEF = math.floor((4 + 0.035 * (lv - 1) + 0.075 * defPts) * class.DEF),
        CritRate = baseCrit,
        CritDmg = baseCritDmg,
        Break = 100,
    }
end

C.Actions = {
    Attack = {Name='Attack', Cooldown=0.45, Range=10, Multiplier=0.9, Break=5},
    Heavy = {Name='Heavy Attack', Cooldown=2.0, Range=11, Multiplier=1.75, Break=14, Cost=22},
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
            Z = {Key="Z", Name="Draconic Fireball Volley • Hỏa Long Liên Đạn", ShortName="Hỏa Long Đạn", AwakenedName="Crimson Fireball Volley • Hỏa Long Liên Đạn", Mastery=1, Cooldown=6.0, Cost=14, Range=32, Multiplier=2.0, Break=16, Hits=5, Mechanic="HybridFireballVolley", Element="Void", Desc="[Dạng 1 • Bán Long] Bắn liên hoàn 5 quả cầu Đầu Hỏa Long phát nổ thành cột dung nham liên tiếp."},
            X = {Key="X", Name="Hybrid Talon Rend • Bán Long Đột Trảo", ShortName="Bán Long Trảo", AwakenedName="Abyssal Claw Slam • Bán Long Đột Trảo", Mastery=1, Cooldown=8.5, Cost=18, Range=24, Multiplier=2.3, Break=20, Hits=2, Mechanic="HybridTalonRend", Element="Void", Desc="[Dạng 1 • Bán Long] Lao vút 20m chộp cổ mục tiêu bằng song trảo Bán Long rồi quật nổ hắc hỏa."},
            C = {Key="C", Name="Draconic Inferno Vortex • Cuồng Long Lốc Xoáy", ShortName="Cuồng Long Xoáy", AwakenedName="Hybrid Blade Cyclone • Cuồng Long Lốc Xoáy", Mastery=1, Cooldown=12.0, Cost=24, Range=26, Multiplier=2.7, Break=24, Hits=4, Mechanic="HybridInfernoCyclone", Element="Void", Desc="[Dạng 1 • Bán Long] Xoay người tạo cơn lốc 3 Hỏa Long Hồn cuốn hút kẻ địch xung quanh vào tâm và kích nổ."},
            V = {Key="V", Name="Dragon Form Shift • Hóa Hình Bán Long / Long Hoàng", ShortName="Chuyển Dạng Rồng", AwakenedName="Sovereign Ascension • Hóa Thái Cổ Long Hoàng", Mastery=1, Cooldown=3.5, Cost=15, Range=28, Multiplier=2.0, Break=18, Mechanic="DragonFormShift", Element="Void", Desc="Chuyển đổi tuần tự: Nhân Dạng -> [Dạng 1] Bán Long Nhân -> [Dạng 2] Chân Thân Thái Cổ Long Hoàng 3D!"},
            F = {Key="F", Name="Hybrid Wing Dash • Long Ảnh Bộ", ShortName="Long Ảnh Bộ", AwakenedName="Crimson Wing Blitz • Long Ảnh Bộ", Mastery=1, Cooldown=6.5, Cost=14, Range=32, Multiplier=1.4, Break=10, Mechanic="HybridWingDash", Element="Void", Desc="[Dạng 1 • Bán Long] Vỗ cánh Bán Long lướt chớp nhoáng 32m để lại 6 cặp tàn ảnh cánh lửa."},
        },
        Form2Moves = {
            Z = {Key="Z", Name="Sovereign Obliteration Beam • Thái Cổ Long Tức", ShortName="Thái Cổ Long Tức", AwakenedName="Abyssal Sovereign Breath • Thái Cổ Long Tức", Mastery=1, Cooldown=8.0, Cost=22, Range=46, Multiplier=2.8, Break=24, Hits=5, Mechanic="SovereignBeam", Element="Void", Desc="[Dạng 2 • Long Hoàng] Há miệng Rồng Khổng Lồ bắn đại trụ laser Hư Không 4 lõi xuyên thấu 46m cày nát mặt đất."},
            X = {Key="X", Name="Sovereign Skyfall Dive • Long Hoàng Giáng Thế", ShortName="Long Hoàng Giáng", AwakenedName="Cataclysmic Dragon Dive • Long Hoàng Giáng Thế", Mastery=1, Cooldown=11.5, Cost=26, Range=34, Multiplier=3.1, Break=28, Hits=4, Mechanic="SovereignSkyfallDive", Element="Void", Desc="[Dạng 2 • Long Hoàng] Mở Tinh Môn trên không rồi bổ nhào xuống như thiên thạch rồng, tạo 4 vòng sóng chấn động kiến tạo."},
            C = {Key="C", Name="Apocalyptic Eclipse Starshower • Vạn Long Thiên Hỏa Vũ", ShortName="Vạn Long Hỏa Vũ", AwakenedName="Eclipse Dragon Starshower • Vạn Long Thiên Hỏa Vũ", Mastery=1, Cooldown=16.0, Cost=34, Range=42, Multiplier=3.6, Break=32, Hits=6, Mechanic="SovereignStarshower", Element="Void", Desc="[Dạng 2 • Long Hoàng] Mở Cổng Nhật Thực Hư Không trên bầu trời, trút mưa 12 thiên thạch Đầu Rồng hủy diệt diện rộng 42m."},
            V = {Key="V", Name="Revert Sovereign Form • Thu Hồi Long Hồn", ShortName="Thu Hồi Rồng", AwakenedName="Revert Sovereign Form • Thu Hồi Long Hồn", Mastery=1, Cooldown=3.5, Cost=0, Range=24, Multiplier=0, Break=0, Mechanic="DragonFormShift", Element="Void", Desc="[Dạng 2 • Long Hoàng] Thu hồi Chân Thân Thái Cổ Long Hoàng trở về Nhân Dạng."},
            F = {Key="F", Name="Sovereign Supersonic Flight • Long Vũ Cửu Thiên", ShortName="Long Vũ Cửu Thiên", AwakenedName="Abyssal Supersonic Soar • Long Vũ Cửu Thiên", Mastery=1, Cooldown=7.5, Cost=18, Range=48, Multiplier=1.8, Break=14, Mechanic="SovereignSupersonicFlight", Element="Void", Desc="[Dạng 2 • Long Hoàng] Vỗ đôi cánh Hắc Long Khổng Lồ bay siêu thanh 48m kèm 8 vòng sóng xung kích Mach Cone."},
        },
        Moves = {
            Z = {Key="Z", Name="Draconic Fireball Volley • Hỏa Long Liên Đạn", ShortName="Hỏa Long Đạn", AwakenedName="Abyssal Sovereign Breath • Thái Cổ Long Tức", Mastery=1, Cooldown=6.0, Cost=14, Range=32, Multiplier=2.0, Break=16, Element="Void", Desc="[Dạng 1] Bắn 5 cầu lửa Đầu Rồng liên hoàn | [Dạng 2] Phun đại trụ laser Thái Cổ Long Tức."},
            X = {Key="X", Name="Hybrid Talon Rend • Bán Long Đột Trảo", ShortName="Bán Long Trảo", AwakenedName="Sovereign Skyfall Dive • Long Hoàng Giáng Thế", Mastery=1, Cooldown=8.5, Cost=18, Range=24, Multiplier=2.3, Break=20, Element="Void", Desc="[Dạng 1] Lao tới chộp cổ bằng vuốt Bán Long | [Dạng 2] Bổ nhào từ không trung chấn vỡ mặt đất."},
            C = {Key="C", Name="Draconic Inferno Vortex • Cuồng Long Lốc Xoáy", ShortName="Cuồng Long Xoáy", AwakenedName="Apocalyptic Eclipse Starshower • Vạn Long Hỏa Vũ", Mastery=1, Cooldown=12.0, Cost=24, Range=26, Multiplier=2.7, Break=24, Element="Void", Desc="[Dạng 1] Xoay lốc đao lửa cuốn kẻ địch | [Dạng 2] Mở Cổng Nhật Thực trút mưa 12 thiên thạch rồng."},
            V = {Key="V", Name="Dragon Form Shift • Hóa Bán Long / Long Hoàng 3D", ShortName="Chuyển Dạng Rồng", AwakenedName="Sovereign Ascension • Chân Thân Hắc Long Đế Vương", Mastery=1, Cooldown=3.5, Cost=15, Range=28, Multiplier=2.0, Break=18, Element="Void", Desc="Nhấn [V] lần 1 hóa Dạng 1 (Bán Long Nhân), nhấn [V] lần 2 hóa Dạng 2 (Thái Cổ Long Hoàng Khổng Lồ), nhấn [V] lần 3 thu hồi!"},
            F = {Key="F", Name="Hybrid Wing Dash • Long Ảnh Bộ", ShortName="Long Ảnh Bộ", AwakenedName="Sovereign Supersonic Flight • Long Vũ Cửu Thiên", Mastery=1, Cooldown=6.5, Cost=14, Range=32, Multiplier=1.4, Break=10, Element="Void", Desc="[Dạng 1] Lướt nhanh để lại tàn ảnh lửa | [Dạng 2] Bay siêu thanh tạo sóng xung kích Mach Cone."},
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
    TrainingDrone = {Name="Training Drone", Level=10, VisualAsset="TrainingDrone", Element="Sky", HP=320, ATK=28, Attack=28, DEF=8, Defense=8, XP=450, Gold=150, Range=8, Speed=12, Aggro=36, Leash=45, Drop="SkyIron"},
    SkyPirate = {Name="Sky Pirate", Level=75, VisualAsset="SkyPirate", Element="Sky", HP=950, ATK=62, Attack=62, DEF=18, Defense=18, XP=1800, Gold=320, Range=8.5, Speed=13, Aggro=38, Leash=48, Drop="SkyIron"},
    CorruptedGuard = {Name="Corrupted Guard", Level=175, VisualAsset="CorruptedGuard", Element="Sky", HP=1950, ATK=105, Attack=105, DEF=32, Defense=32, XP=4200, Gold=520, Range=9, Speed=13, Aggro=40, Leash=50, HasBusoHaki=true, Drop="SunshardCore"},
    LightArcher = {Name="Light Archer", Level=325, VisualAsset="LightArcher", Element="Sky", HP=3100, ATK=155, Attack=155, DEF=45, Defense=45, XP=8200, Gold=780, Range=30, Speed=12, Aggro=44, Leash=52, Ranged=true, HasBusoHaki=true, Drop="CelestialFeather"},
    SunshardRoyalGuard = {Name="Sunshard Royal Guard", Level=450, VisualAsset="SunshardRoyalGuard", Element="Sky", HP=4600, ATK=210, Attack=210, DEF=62, Defense=62, XP=12500, Gold=1050, Range=9.5, Speed=14, Aggro=42, Leash=52, HasBusoHaki=true, Drop="SunshardCore"},
    GoldenKnight = {Name="Golden Knight", Level=500, VisualAsset="GoldenKnight", Element="Sky", HP=11500, ATK=255, Attack=255, DEF=78, Defense=78, XP=26000, Gold=2400, Range=11, Speed=14, Aggro=46, Leash=55, Elite=true, HasBusoHaki=true, Drop="SunshardCore"},
    SunshardTemplar = {Name="Sunshard Templar", Level=575, VisualAsset="SunshardTemplar", Element="Sky", HP=6400, ATK=265, Attack=265, DEF=82, Defense=82, XP=18000, Gold=1400, Range=10, Speed=14, Aggro=44, Leash=55, HasBusoHaki=true, Drop="SunshardCore"},
    AureonSentinel = {Name="AUREON SENTINEL", Level=700, VisualAsset="AureonSentinel", Element="Sky", HP=48000, ATK=420, Attack=420, DEF=110, Defense=110, XP=145000, Gold=20000, Range=18, Speed=14, Aggro=65, Leash=75, Boss=true, HasBusoHaki=true, Drop="CoreEssence"},
    EnergyPylon = {Name="Energy Pylon", Level=700, VisualAsset="EnergyPylon", Element="Sky", HP=3500, ATK=0, Attack=0, DEF=30, Defense=30, XP=0, Gold=0, Range=0, Speed=0, Aggro=0, Leash=0},

    -- Sea 2: Frozen Cyber Mobs & Bosses (Lv. 700 - 1500)
    FrostDrone = {Name="Frost Automaton", Level=750, VisualAsset="FrostDrone", Element="Frost", HP=8800, ATK=350, Attack=350, DEF=95, Defense=95, Speed=15, Range=9, Aggro=45, Leash=60, XP=24000, Gold=2200, HasBusoHaki=true, Drop="SkyIron"},
    FrostAutomaton = {Name="Frost Automaton", Level=750, VisualAsset="FrostAutomaton", Element="Frost", HP=8800, ATK=350, Attack=350, DEF=95, Defense=95, Speed=15, Range=9, Aggro=45, Leash=60, XP=24000, Gold=2200, HasBusoHaki=true, Drop="SkyIron"},
    CyberMercenary = {Name="Cyber Mercenary", Level=875, VisualAsset="CyberMercenary", Element="Frost", HP=10800, ATK=405, Attack=405, DEF=110, Defense=110, Speed=15, Range=28, Aggro=48, Leash=62, Ranged=true, XP=30000, Gold=2650, HasBusoHaki=true, Drop="SkyIron"},
    CryoGuard = {Name="Cryo Vanguard", Level=1025, VisualAsset="CryoGuard", Element="Frost", HP=13800, ATK=465, Attack=465, DEF=125, Defense=125, Speed=15, Range=9.5, Aggro=46, Leash=65, XP=38000, Gold=3100, HasBusoHaki=true, Drop="SunshardCore"},
    CryoVanguard = {Name="Cryo Vanguard", Level=1025, VisualAsset="CryoVanguard", Element="Frost", HP=13800, ATK=465, Attack=465, DEF=125, Defense=125, Speed=15, Range=9.5, Aggro=46, Leash=65, XP=38000, Gold=3100, HasBusoHaki=true, Drop="SunshardCore"},
    CyberArcher = {Name="Glacial Sniper", Level=1150, VisualAsset="GlacialMarksman", Element="Frost", HP=13200, ATK=515, Attack=515, DEF=132, Defense=132, Speed=14, Range=32, Aggro=50, Leash=65, Ranged=true, XP=44000, Gold=3500, HasBusoHaki=true, Drop="CelestialFeather"},
    GlacialMarksman = {Name="Glacial Sniper", Level=1150, VisualAsset="GlacialMarksman", Element="Frost", HP=13200, ATK=515, Attack=515, DEF=132, Defense=132, Speed=14, Range=32, Aggro=50, Leash=65, Ranged=true, XP=44000, Gold=3500, HasBusoHaki=true, Drop="CelestialFeather"},
    GlacialSniper = {Name="Glacial Sniper", Level=1150, VisualAsset="GlacialSniper", Element="Frost", HP=13200, ATK=515, Attack=515, DEF=132, Defense=132, Speed=14, Range=32, Aggro=50, Leash=65, Ranged=true, XP=44000, Gold=3500, HasBusoHaki=true, Drop="CelestialFeather"},
    MechaDrone = {Name="Mecha Security Drone", Level=1250, VisualAsset="MechaDrone", Element="Frost", HP=16500, ATK=555, Attack=555, DEF=145, Defense=145, Speed=16, Range=10, Aggro=48, Leash=65, XP=50000, Gold=3900, HasBusoHaki=true, Drop="SkyIron"},
    ArcticCorsair = {Name="Arctic Corsair", Level=1375, VisualAsset="ArcticCorsair", Element="Frost", HP=19200, ATK=600, Attack=600, DEF=158, Defense=158, Speed=16, Range=10, Aggro=48, Leash=65, XP=58000, Gold=4400, HasBusoHaki=true, Drop="SkyIron"},
    CryonPillar = {Name="Cryon Glacial Pillar", Level=1500, VisualAsset="CryonPillar", Element="Frost", HP=6500, ATK=0, Attack=0, DEF=60, Defense=60, Speed=0, Range=0, Aggro=0, Leash=999, XP=5000, Gold=500},
    CryonPrime = {Name="CRYON PRIME", Level=1500, VisualAsset="CryonPrime", Element="Frost", HP=140000, ATK=840, Attack=840, DEF=185, Defense=185, XP=420000, Gold=55000, Range=22, Speed=14, Aggro=70, Leash=80, Boss=true, HasBusoHaki=true, Drop="CoreEssence"},

    -- Sea 3: Shadow Realm Mobs & Bosses (Lv. 1500 - 2200)
    VoidPirate = {Name="Void Marauder", Level=1550, VisualAsset="VoidMarauder", Element="Void", HP=24000, ATK=680, Attack=680, DEF=170, Defense=170, Speed=16, Range=10, Aggro=48, Leash=65, XP=72000, Gold=5500, HasBusoHaki=true, Drop="SunshardCore"},
    VoidMarauder = {Name="Void Marauder", Level=1550, VisualAsset="VoidMarauder", Element="Void", HP=24000, ATK=680, Attack=680, DEF=170, Defense=170, Speed=16, Range=10, Aggro=48, Leash=65, XP=72000, Gold=5500, HasBusoHaki=true, Drop="SunshardCore"},
    VoidRaider = {Name="Void Raider", Level=1675, VisualAsset="VoidRaider", Element="Void", HP=28000, ATK=740, Attack=740, DEF=185, Defense=185, Speed=16, Range=10, Aggro=48, Leash=65, XP=82000, Gold=6200, HasBusoHaki=true, Drop="SunshardCore"},
    ShadowArcher = {Name="Umbral Ranger", Level=1800, VisualAsset="UmbralBowman", Element="Void", HP=27000, ATK=795, Attack=795, DEF=192, Defense=192, Speed=15, Range=32, Aggro=52, Leash=68, Ranged=true, XP=94000, Gold=6800, HasBusoHaki=true, Drop="CelestialFeather"},
    UmbralBowman = {Name="Umbral Ranger", Level=1800, VisualAsset="UmbralBowman", Element="Void", HP=27000, ATK=795, Attack=795, DEF=192, Defense=192, Speed=15, Range=32, Aggro=52, Leash=68, Ranged=true, XP=94000, Gold=6800, HasBusoHaki=true, Drop="CelestialFeather"},
    UmbralRanger = {Name="Umbral Ranger", Level=1800, VisualAsset="UmbralRanger", Element="Void", HP=27000, ATK=795, Attack=795, DEF=192, Defense=192, Speed=15, Range=32, Aggro=52, Leash=68, Ranged=true, XP=94000, Gold=6800, HasBusoHaki=true, Drop="CelestialFeather"},
    ShadowSpecter = {Name="Shadow Specter", Level=1925, VisualAsset="ShadowSpecter", Element="Void", HP=33000, ATK=850, Attack=850, DEF=208, Defense=208, Speed=17, Range=10.5, Aggro=52, Leash=68, XP=108000, Gold=7600, HasBusoHaki=true, Drop="CelestialFeather"},
    AbyssalKnight = {Name="Abyssal Dreadknight", Level=2000, VisualAsset="AbyssalKnight", Element="Void", HP=52000, ATK=940, Attack=940, DEF=230, Defense=230, Speed=16, Range=11, Aggro=54, Leash=72, Elite=true, XP=165000, Gold=11500, HasBusoHaki=true, Drop="CoreEssence"},
    AbyssalDreadknight = {Name="Abyssal Dreadknight", Level=2000, VisualAsset="AbyssalDreadknight", Element="Void", HP=52000, ATK=940, Attack=940, DEF=230, Defense=230, Speed=16, Range=11, Aggro=54, Leash=72, Elite=true, XP=165000, Gold=11500, HasBusoHaki=true, Drop="CoreEssence"},
    TerrorSkyShark = {Name="Terror Sky-Shark", Level=2100, VisualAsset="TerrorSkyShark", Element="Void", HP=68000, ATK=1020, Attack=1020, DEF=245, Defense=245, Speed=17, Range=13, Aggro=60, Leash=80, Elite=true, XP=210000, Gold=14500, HasBusoHaki=true, Drop="CoreEssence"},
    NoxarVoidFX = {Name="Void Singularity", Level=2200, VisualAsset="NoxarVoidFX", Element="Void", HP=12000, ATK=0, Attack=0, DEF=80, Defense=80, Speed=0, Range=0, Aggro=0, Leash=999, XP=15000, Gold=1200},
    Noxar = {Name="NOXAR • VOID SOVEREIGN", Level=2200, VisualAsset="Noxar", Element="Void", HP=320000, ATK=1450, Attack=1450, DEF=270, Defense=270, XP=1050000, Gold=135000, Range=24, Speed=15, Aggro=75, Leash=85, Boss=true, HasBusoHaki=true, Drop="CoreEssence"},

    -- Sea Event & Island Raid Bosses (Grand Sky Seas v12 Rigged Blender Models)
    PirateCaptainVance = {Name="CAPTAIN VANCE • ĐÔ ĐỐC KHÔNG TẶC", Level=350, VisualAsset="PirateCaptainVance", Element="Sky", HP=18000, ATK=215, Attack=215, DEF=58, Defense=58, XP=42000, Gold=6500, Range=15, Speed=14, Aggro=48, Leash=60, Boss=true, HasBusoHaki=true, Drop="SunshardCore"},
    OrderCyborg = {Name="ORDER • LÕI LƯỢNG TỬ TỐI THƯỢNG", Level=1250, VisualAsset="OrderCyborg", Element="Frost", HP=98000, ATK=680, Attack=680, DEF=162, Defense=162, XP=260000, Gold=36000, Range=19, Speed=15, Aggro=58, Leash=72, Boss=true, HasBusoHaki=true, Drop="CoreEssence"},
    OrderCyborgBoss = {Name="ORDER • LÕI LƯỢNG TỬ TỐI THƯỢNG", Level=1250, VisualAsset="OrderCyborgBoss", Element="Frost", HP=98000, ATK=680, Attack=680, DEF=162, Defense=162, XP=260000, Gold=36000, Range=19, Speed=15, Aggro=58, Leash=72, Boss=true, HasBusoHaki=true, Drop="CoreEssence"},
    SkySeaBeast = {Name="SKY SEA BEAST • THỦY QUÁI BIỂN MÂY", Level=1400, VisualAsset="SkySeaBeast", Element="Frost", HP=118000, ATK=750, Attack=750, DEF=175, Defense=175, XP=320000, Gold=45000, Range=26, Speed=12, Aggro=75, Leash=95, Boss=true, HasBusoHaki=true, Drop="CoreEssence"},
    SoulReaperRift = {Name="SOUL REAPER • TỬ THẦN HƯ KHÔNG", Level=2050, VisualAsset="SoulReaperRift", Element="Void", HP=235000, ATK=1140, Attack=1140, DEF=245, Defense=245, XP=680000, Gold=88000, Range=21, Speed=15, Aggro=65, Leash=80, Boss=true, HasBusoHaki=true, Drop="CoreEssence"},
    AbyssalDragonHybrid = {Name="ABYSSAL DRAGON HYBRID • LONG NHÂN HƯ KHÔNG", Level=2125, VisualAsset="AbyssalDragonHybrid", Element="Void", HP=265000, ATK=1220, Attack=1220, DEF=255, Defense=255, XP=750000, Gold=98000, Range=22, Speed=15, Aggro=70, Leash=85, Boss=true, HasBusoHaki=true, Drop="CoreEssence"},
    AbyssalLeviathan = {Name="ABYSSAL LEVIATHAN • THỦY TỔ HƯ KHÔNG", Level=2150, VisualAsset="AbyssalLeviathan", Element="Void", HP=295000, ATK=1310, Attack=1310, DEF=265, Defense=265, XP=880000, Gold=115000, Range=28, Speed=13, Aggro=85, Leash=105, Boss=true, HasBusoHaki=true, Drop="CoreEssence"},
    AbyssalSovereignDragon = {Name="ABYSSAL SOVEREIGN DRAGON • THÁI CỔ LONG HOÀNG", Level=2300, VisualAsset="AbyssalSovereignDragon", Element="Void", HP=420000, ATK=1650, Attack=1650, DEF=295, Defense=295, XP=1450000, Gold=175000, Range=28, Speed=15, Aggro=78, Leash=95, Boss=true, HasBusoHaki=true, Drop="CoreEssence"},

    -- Regional Island & Expansion Realm Bosses (Lv. 100 - 2550 MAX)
    SkyHubWatchCommander = {Name="COMMANDER VALEN • THỦ VỆ SÂN TẬP", Level=100, VisualAsset="SunshardRoyalGuard", Element="Sky", HP=5500, ATK=95, Attack=95, DEF=28, Defense=28, XP=12000, Gold=2200, Range=12, Speed=13, Aggro=44, Leash=55, Boss=true, HasBusoHaki=true, Drop="SunshardCore"},
    ShrineGuardianBoss = {Name="SHRINE WARDEN ORION • HỘ VỆ ĐIỆN THỜ", Level=225, VisualAsset="SunshardTemplar", Element="Sky", HP=10500, ATK=145, Attack=145, DEF=42, Defense=42, XP=24000, Gold=3800, Range=12, Speed=13, Aggro=44, Leash=55, Boss=true, HasBusoHaki=true, Drop="SunshardCore"},
    AetherArchonBoss = {Name="ARCHON HELIOS • LINH VỆ AETHER", Level=450, VisualAsset="GoldenKnight", Element="Sky", HP=25000, ATK=265, Attack=265, DEF=72, Defense=72, XP=58000, Gold=8500, Range=14, Speed=14, Aggro=48, Leash=60, Boss=true, HasBusoHaki=true, Drop="SunshardCore"},
    SolarHighPriestBoss = {Name="HIGH PRIEST SOLARIUS • ĐẠI TƯ TẾ THÁI DƯƠNG", Level=625, VisualAsset="SolarTitanBuddha", Element="Sky", HP=35000, ATK=345, Attack=345, DEF=92, Defense=92, XP=85000, Gold=12000, Range=17, Speed=14, Aggro=52, Leash=65, Boss=true, HasBusoHaki=true, Drop="CoreEssence"},
    CyberSyndicateBoss = {Name="OVERLORD KRON • TRÙM HẮC THỊ CYBERPORT", Level=950, VisualAsset="CyberMercenary", Element="Frost", HP=62000, ATK=520, Attack=520, DEF=130, Defense=130, XP=165000, Gold=22000, Range=18, Speed=15, Aggro=54, Leash=68, Boss=true, HasBusoHaki=true, Drop="CoreEssence"},
    PermafrostWardenBoss = {Name="GENERAL BOREAS • THỐNG LĨNH PHÁO ĐÀI BĂNG", Level=1125, VisualAsset="CryoVanguard", Element="Frost", HP=80000, ATK=600, Attack=600, DEF=148, Defense=148, XP=210000, Gold=28000, Range=16, Speed=15, Aggro=54, Leash=68, Boss=true, HasBusoHaki=true, Drop="CoreEssence"},
    VoidCastellanBoss = {Name="LORD MALAKOR • LÃNH CHÚA DINH THỰ HƯ KHÔNG", Level=1725, VisualAsset="AbyssalDreadknight", Element="Void", HP=165000, ATK=920, Attack=920, DEF=210, Defense=210, XP=480000, Gold=62000, Range=18, Speed=15, Aggro=60, Leash=75, Boss=true, HasBusoHaki=true, Drop="CoreEssence"},
    UmbralArchfiendBoss = {Name="ARCHFIEND ZERATH • KIẾM MA TINH THỂ ĐEN", Level=1875, VisualAsset="AbyssalDragonHybrid", Element="Void", HP=195000, ATK=1010, Attack=1010, DEF=225, Defense=225, XP=560000, Gold=72000, Range=19, Speed=15, Aggro=60, Leash=75, Boss=true, HasBusoHaki=true, Drop="CoreEssence"},
    Sylvaris = {Name="SYLVARIS • ĐẠI CỔ THỤ HOÀNG", Level=2250, VisualAsset="AbyssalDragonHybrid", Element="Sky", HP=380000, ATK=1550, Attack=1550, DEF=285, Defense=285, XP=1250000, Gold=155000, Range=23, Speed=15, Aggro=72, Leash=88, Boss=true, HasBusoHaki=true, Drop="CoreEssence"},
    Ignivar = {Name="IGNIVAR • TITAN LÒ RÈN LỬA", Level=2325, VisualAsset="SolarTitanBuddha", Element="Sky", HP=460000, ATK=1750, Attack=1750, DEF=310, Defense=310, XP=1600000, Gold=190000, Range=24, Speed=15, Aggro=72, Leash=88, Boss=true, HasBusoHaki=true, Drop="CoreEssence"},
    Nerith = {Name="NERITH • THỦY HOÀNG VỰC SÂU", Level=2400, VisualAsset="AbyssalLeviathan", Element="Frost", HP=530000, ATK=1920, Attack=1920, DEF=330, Defense=330, XP=1950000, Gold=225000, Range=28, Speed=15, Aggro=78, Leash=95, Boss=true, HasBusoHaki=true, Drop="CoreEssence"},
    Aion = {Name="AION • PHÁP VƯƠNG THỜI GIAN", Level=2475, VisualAsset="OrderCyborgBoss", Element="Sky", HP=620000, ATK=2120, Attack=2120, DEF=355, Defense=355, XP=2400000, Gold=275000, Range=25, Speed=16, Aggro=76, Leash=92, Boss=true, HasBusoHaki=true, Drop="CoreEssence"},
    Veyr = {Name="VEYR • ĐẤNG KIẾN TẠO ĐẦU TIÊN", Level=2550, VisualAsset="AbyssalSovereignDragon", Element="Void", HP=780000, ATK=2400, Attack=2400, DEF=390, Defense=390, XP=3500000, Gold=400000, Range=30, Speed=16, Aggro=85, Leash=100, Boss=true, HasBusoHaki=true, Drop="CoreEssence"},
}

local BALANCED_ENEMY_STATS = {}
for enemyId, enemyDef in pairs(C.Enemies) do
    BALANCED_ENEMY_STATS[enemyId] = {
        HP = enemyDef.HP,
        ATK = enemyDef.ATK,
        Attack = enemyDef.Attack or enemyDef.ATK,
        DEF = enemyDef.DEF,
        Defense = enemyDef.Defense or enemyDef.DEF,
        XP = enemyDef.XP,
        Gold = enemyDef.Gold,
        Speed = enemyDef.Speed,
        Range = enemyDef.Range,
        Aggro = enemyDef.Aggro,
        Leash = enemyDef.Leash,
        HasBusoHaki = enemyDef.HasBusoHaki,
    }
end

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
    {Id="dawnbringer_sword", ItemId="dawnbringer_sword", Name="Dawnbringer • Sword of the First Light", Slot="Weapon", ClassId="SkyGuardian", Rarity="Legendary", Gold=45000, Materials={SunshardCore=2, SkyIron=5, CoreEssence=1}, Desc="Thần kiếm Ánh Sáng dành cho Sky Guardian (+72 ATK, +12% Crit, +24% Crit DMG)."},
    {Id="stormfang_daggers", ItemId="stormfang_daggers", Name="Stormfang • Twinblades of the Tempest", Slot="Weapon", ClassId="ThunderStriker", Rarity="Legendary", Gold=45000, Materials={SunshardCore=2, SkyIron=5, CoreEssence=1}, Desc="Song đao Lôi Đình dành cho Thunder Striker (+76 ATK, +18% Crit, +30% Crit DMG)."},
    {Id="astral_staff", ItemId="astral_staff", Name="Chronostaff • Scepter of the Void Star", Slot="Weapon", ClassId="ArcaneMage", Rarity="Legendary", Gold=45000, Materials={SunshardCore=2, SkyIron=5, CoreEssence=1}, Desc="Quyền trượng Tinh Cầu dành cho Arcane Mage (+78 ATK, +15% Crit, +28% Crit DMG)."},
    {Id="saber_of_aureon", ItemId="saber_of_aureon", Name="Saber of Aureon • Đại Kiếm Thánh Quang", Slot="Weapon", Rarity="Legendary", Gold=125000, Materials={SunshardCore=3, SkyIron=6, CoreEssence=1}, Desc="Đại kiếm của Aureon Sentinel (+115 ATK, +16% Crit, +32% Crit DMG)."},
    {Id="cryon_frostblade", ItemId="cryon_frostblade", Name="Cryon Frostblade • Tuyệt Độ Hàn Đao", Slot="Weapon", Rarity="Legendary", Gold=280000, Materials={SunshardCore=4, CelestialFeather=3, CoreEssence=2}, Desc="Đại đao băng tinh của Cryon Prime (+135 ATK, +18% Crit, +36% Crit DMG)."},
    {Id="cursed_dual_skyblades", ItemId="cursed_dual_skyblades", Name="Cursed Dual Skyblades (CDK) • Song Kiếm Huyền Thoại", Slot="Weapon", Rarity="Mythic", Gold=950000, Materials={SunshardCore=6, CelestialFeather=5, CoreEssence=3}, Desc="Song kiếm thần thoại kết hợp Ánh Sáng & Hư Không (+185 ATK, +25% Crit, +48% Crit DMG)."},
    {Id="noxar_abyssal_greatsword", ItemId="noxar_abyssal_greatsword", Name="Noxar's Abyssal Greatsword • Hắc Kiếm Hư Không", Slot="Weapon", Rarity="Mythic", Gold=1450000, Materials={SunshardCore=8, CelestialFeather=6, CoreEssence=4}, Desc="Đại kiếm tối thượng của Hư Không Vương Noxar (+210 ATK, +28% Crit, +55% Crit DMG)."},
    {Id="solar_kabucha", ItemId="solar_kabucha", Name="Solar Kabucha • Ná Thần Mặt Trời", Slot="Gun", Rarity="Rare", Gold=65000, Materials={SunshardCore=2, SkyIron=4}, Desc="Ná thần bắn đạn mặt trời phá giáp (+78 ATK, +12% Crit)."},
    {Id="cryo_railgun", ItemId="cryo_railgun", Name="Cryo Railgun • Pháo Từ Trường Băng", Slot="Gun", Rarity="Legendary", Gold=320000, Materials={SunshardCore=3, SkyIron=6, CoreEssence=2}, Desc="Pháo từ trường bắn tia laser băng giá (+125 ATK, +18% Crit)."},
    {Id="soul_guitar_void", ItemId="soul_guitar_void", Name="Soul Guitar of the Void • Đàn Linh Hồn Hư Không", Slot="Gun", Rarity="Mythic", Gold=1100000, Materials={SunshardCore=5, CelestialFeather=5, CoreEssence=3}, Desc="Đàn linh hồn thần thoại triệu hồi sóng âm hư không (+165 ATK, +22% Crit)."},
    {Id="skyward_chest", ItemId="skyward_chest", Name="Chiến Giáp Skyward Cloak", Slot="Chest", Rarity="Legendary", Gold=35000, Materials={CelestialFeather=2, SkyIron=4}, Desc="Chiến giáp huyền thoại tăng +320 HP và +32 DEF."},
    {Id="sovereign_cloak", ItemId="sovereign_cloak", Name="Áo Choàng Hư Không Đế Vương", Slot="Chest", Rarity="Mythic", Gold=750000, Materials={CelestialFeather=5, SunshardCore=4, CoreEssence=2}, Desc="Áo choàng thần thoại tăng +750 HP, +70 DEF, +55 ATK, +30% Crit DMG."},
    {Id="aether_ring", ItemId="aether_ring", Name="Nhẫn Tinh Cầu Aether", Slot="Ring", Rarity="Legendary", Gold=28000, Materials={SunshardCore=1, SkyIron=3}, Desc="Nhẫn cổ ngữ tăng +28 ATK và +8% Crit Rate."},
    {Id="core_artifact", ItemId="core_artifact", Name="Thánh Vật Core of Light", Slot="Artifact", Rarity="Mythic", Gold=150000, Materials={SunshardCore=2, CelestialFeather=2, CoreEssence=1}, Desc="Thánh vật thần thoại tăng +35 ATK, +250 HP, +20 DEF."},
    {Id="leviathan_shield", ItemId="leviathan_shield", Name="Khiên Thần Leviathan", Slot="Artifact", Rarity="Mythic", Gold=980000, Materials={SunshardCore=5, SkyIron=8, CoreEssence=3}, Desc="Khiên thần rèn từ vảy Thủy Tổ Leviathan (+850 HP, +85 DEF, +60 ATK)."},
    -- V2 Celestial Forge Blueprints (1:1 parity with RarityConfig.Recipes & Forge.lua)
    {Id="Dawnbringer", ItemId="Dawnbringer", Name="Dawnbringer • Thánh Kiếm Ban Mai", Slot="Weapon", ClassId="SkyGuardian", Rarity="Legendary", Gold=95000, Materials={SunshardCore=2, SkyIron=5, upgrade_material=3}, Desc="Thánh kiếm rèn từ Core of Light của Aureon (+120 ATK, +35 DEF, +180 HP)."},
    {Id="Stormfang", ItemId="Stormfang", Name="Stormfang • Song Đao Lôi Đình", Slot="Weapon", ClassId="ThunderStriker", Rarity="Legendary", Gold=240000, Materials={SunshardCore=2, SkyIron=6, upgrade_material=4}, Desc="Song đao sấm sét tụ hội từ Frozen Cyber (+135 ATK, +18% Crit)."},
    {Id="EternalFrost", ItemId="EternalFrost", Name="Eternal Frost • Quyền Trượng Băng Giá", Slot="Weapon", ClassId="ArcaneMage", Rarity="Legendary", Gold=260000, Materials={SunshardCore=2, CelestialFeather=3, upgrade_material=4}, Desc="Quyền trượng gắn tinh thể trái tim của Cryon Prime (+142 ATK, +14% Crit)."},
    {Id="CelestialPlate", ItemId="CelestialPlate", Name="Celestial Aegis Plate", Slot="Chest", Rarity="Epic", Gold=55000, Materials={CelestialFeather=2, SkyIron=5, upgrade_material=3}, Desc="Giáp ngực hợp kim Hắc Diện - Lam Ngọc (+160 HP, +38 DEF)."},
    {Id="SolarBand", ItemId="SolarBand", Name="Solar Band", Slot="Ring", Rarity="Epic", Gold=42000, Materials={SunshardCore=1, SkyIron=4, upgrade_material=2}, Desc="Nhẫn thái dương hồi năng lượng (+24 ATK, +8% Crit)."},
    {Id="ArchitectsSeverance", ItemId="ArchitectsSeverance", Name="Architect's Severance • Kiếm Kiến Tạo Veyr", Slot="Weapon", ClassId="SkyGuardian", Rarity="Mythic", Gold=2400000, Materials={SunshardCore=8, CelestialFeather=6, CoreEssence=5}, Desc="Thần kiếm tối thượng dệt từ kỳ điểm Veil's End (+380 ATK, +95 DEF, +620 HP)."},
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
    {Id="Q01", Name="Lời Gọi Skyborn (Sea 1 • Lv. 1–120)", Realm="GoldenSky", Level=1, TargetLevel=120, XP=95000, Gold=8000, CoreShards=100,
        Text="Các quần đảo bầu trời đang mất dần năng lượng. Hãy tiêu diệt 3 Training Drone tại sân tập Sky Hub để làm quen với vũ khí và đột phá Lv. 120.",
        Objectives={{Kind="Kill", Target="TrainingDrone", Count=3, Label="Hạ gục Training Drone"}}},
    {Id="Q02", Name="Khôi Phục Cầu Năng Lượng (Sea 1 • Lv. 120–260)", Realm="GoldenSky", Level=120, TargetLevel=260, XP=320000, Gold=16000, CoreShards=150,
        Text="Năng lượng cầu sang Quảng Trường Lumen đã cạn. Hãy đánh bại 3 Corrupted Guard và bật 3 Trạm Năng Lượng.",
        Objectives={{Kind="Kill", Target="CorruptedGuard", Count=3, Label="Hạ gục Corrupted Guard"},
        {Kind="Interact", Target="Station1", Count=1, Label="Bật Trạm 1"}, {Kind="Interact", Target="Station2", Count=1, Label="Bật Trạm 2"}, {Kind="Interact", Target="Station3", Count=1, Label="Bật Trạm 3"}}},
    {Id="Q03", Name="Giải Cứu Quảng Trường Lumen (Sea 1 • Lv. 260–420)", Realm="GoldenSky", Level=260, TargetLevel=420, XP=720000, Gold=28000, CoreShards=220,
        Text="Cầu ánh sáng đã mở. Hãy giải cứu 3 người dân bị mắc kẹt và đánh bại Tinh Anh Golden Knight tại quảng trường.",
        Objectives={{Kind="Interact", Target="Citizen1", Count=1, Label="Cứu người dân 1"}, {Kind="Interact", Target="Citizen2", Count=1, Label="Cứu người dân 2"}, {Kind="Interact", Target="Citizen3", Count=1, Label="Cứu người dân 3"}, {Kind="Kill", Target="GoldenKnight", Count=1, Label="Hạ gục Golden Knight"}}},
    {Id="Q04", Name="Chìa Khóa Tháp Ánh Sáng (Sea 1 • Lv. 420–560)", Realm="GoldenSky", Level=420, TargetLevel=560, XP=1100000, Gold=42000, CoreShards=300,
        Text="Tiến tới Tiền Điện Aureon, kích hoạt 2 Công Tắc Cổ Ngữ và hạ 3 Light Archer để nhận Chìa Khóa Đấu Trường.",
        Objectives={{Kind="Interact", Target="Switch1", Count=1, Label="Bật Công tắc 1"}, {Kind="Interact", Target="Switch2", Count=1, Label="Bật Công tắc 2"}, {Kind="Kill", Target="LightArcher", Count=3, Label="Hạ gục Light Archer"}}},
    {Id="Q05", Name="Trái Tim Ánh Sáng (Boss Sea 1 • Đột Phá Lv. 700)", Realm="GoldenSky", Level=560, TargetLevel=700, XP=1800000, Gold=75000, CoreShards=500,
        Text="Tiến vào Đấu Trường Tháp Ánh Sáng và đánh bại AUREON SENTINEL [Lv.700]. Phá hủy 2 trụ năng lượng khi Boss bật khiên để mở khóa Sea 2 (Lv. 700)!",
        Objectives={{Kind="Kill", Target="AureonSentinel", Count=1, Label="Đánh bại Boss Aureon Sentinel [Lv.700]"}}},

    -- CHƯƠNG 2: SEA 2 • FROZEN CYBER (Lv. 700 - 1500)
    {Id="Q06", Name="Đột Nhập Thành Trì Băng Giá (Sea 2 • Lv. 700–960)", Realm="FrozenCyber", Level=700, TargetLevel=960, XP=3200000, Gold=95000, CoreShards=600,
        Text="Cổng dịch chuyển Sea 2 • Frozen Cyber đã mở! Hãy tiêu diệt 3 Frost Automaton và 2 Cryo Vanguard để mở đường vào trung tâm.",
        Objectives={{Kind="Kill", Target="FrostDrone", Count=3, Label="Hạ gục Frost Automaton"}, {Kind="Kill", Target="CryoGuard", Count=2, Label="Hạ gục Cryo Vanguard"}}},
    {Id="Q07", Name="Lõi Lượng Tử Nổi Loạn (Sea 2 • Lv. 960–1240)", Realm="FrozenCyber", Level=960, TargetLevel=1240, XP=4800000, Gold=135000, CoreShards=750,
        Text="Tại Phòng Thí Nghiệm Đột Kích (hoặc vùng biển mây Sea 2), hãy đánh bại ORDER • Lõi Lượng Tử hoặc Thủy Quái Sky Sea Beast.",
        Objectives={{Kind="Kill", Target="OrderCyborg", Count=1, Label="Đánh bại Order Cyborg / Sky Sea Beast"}}},
    {Id="Q08", Name="Thực Thể Băng Giá Vĩnh Cửu (Boss Sea 2 • Đột Phá Lv. 1500)", Realm="FrozenCyber", Level=1240, TargetLevel=1500, XP=6800000, Gold=200000, CoreShards=1000,
        Text="Tiến vào Đấu Trường Băng Giá và tiêu diệt CRYON PRIME [Lv.1500]. Phá 3 Cột Băng Vĩnh Cửu để tiến vào Sea 3 (Lv. 1500)!",
        Objectives={{Kind="Kill", Target="CryonPrime", Count=1, Label="Đánh bại Boss Cryon Prime [Lv.1500]"}}},

    -- CHƯƠNG 3: SEA 3 • SHADOW REALM (Lv. 1500 - 2200)
    {Id="Q09", Name="Quân Đoàn Bóng Đêm (Sea 3 • Lv. 1500–1750)", Realm="ShadowRealm", Level=1500, TargetLevel=1750, XP=8500000, Gold=250000, CoreShards=1200,
        Text="Bước qua cổng Hư Không vào Sea 3 • Shadow Realm. Hãy thanh trừng 3 Void Marauder và 2 Kỵ Sĩ Hắc Ám Abyssal Dreadknight.",
        Objectives={{Kind="Kill", Target="VoidPirate", Count=3, Label="Hạ gục Void Marauder"}, {Kind="Kill", Target="AbyssalKnight", Count=2, Label="Hạ gục Abyssal Dreadknight"}}},
    {Id="Q10", Name="Săn Lùng Thủy Tổ Hư Không (Sea 3 • Lv. 1750–1980)", Realm="ShadowRealm", Level=1750, TargetLevel=1980, XP=11000000, Gold=320000, CoreShards=1500,
        Text="Tiến vào Vực Thẳm Leviathan (hoặc Điện Thờ Lõi) tại Shadow Realm và đánh bại Thủy Tổ ABYSSAL LEVIATHAN hoặc SOUL REAPER.",
        Objectives={{Kind="Kill", Target="AbyssalLeviathan", Count=1, Label="Đánh bại Abyssal Leviathan / Soul Reaper"}}},
    {Id="Q11", Name="Chúa Tể Hư Không (Boss Sea 3 • Đột Phá Lv. 2200)", Realm="ShadowRealm", Level=1980, TargetLevel=2200, XP=14000000, Gold=480000, CoreShards=2000,
        Text="Đối mặt với NOXAR • THE VOID SOVEREIGN [Lv.2200] tại Đấu Trường Hắc Tinh. Phá hủy Void Singularity để đoạt lấy Song Kiếm Huyền Thoại!",
        Objectives={{Kind="Kill", Target="Noxar", Count=1, Label="Đánh bại Boss Noxar • Void Sovereign [Lv.2200]"}}},

    -- CHƯƠNG 4 - 5: CÁC CÕI GIỚI THƯỢNG CỔ & CHUNG CUỘC (Lv. 2200 - 2550 MAX)
    {Id="Q12", Name="Thức Tỉnh Nguyên Tố Cổ Đại (Realms 4–5 • Lv. 2200–2340)", Realm="VerdantCrown", Level=2200, TargetLevel=2340, XP=18000000, Gold=600000, CoreShards=2500,
        Text="Dịch chuyển tới Verdant Crown và Emberforge Wastes để chinh phục Đại Cổ Thụ SYLVARIS [Lv.2250] cùng Titan Lửa IGNIVAR [Lv.2325].",
        Objectives={{Kind="Kill", Target="Sylvaris", Count=1, Label="Đánh bại Sylvaris (Verdant Crown)"}, {Kind="Kill", Target="Ignivar", Count=1, Label="Đánh bại Ignivar (Emberforge Wastes)"}}},
    {Id="Q13", Name="Vượt Qua Dòng Chảy Thời Gian (Realms 6–7 • Lv. 2340–2480)", Realm="ChronosBastion", Level=2340, TargetLevel=2480, XP=24000000, Gold=800000, CoreShards=3200,
        Text="Tiến vào Abyssal Tides và Chronos Bastion để đánh bại Thủy Hoàng NERITH [Lv.2400] và Pháp Vương Thời Gian AION [Lv.2475].",
        Objectives={{Kind="Kill", Target="Nerith", Count=1, Label="Đánh bại Nerith (Abyssal Tides)"}, {Kind="Kill", Target="Aion", Count=1, Label="Đánh bại Aion (Chronos Bastion)"}}},
    {Id="Q14", Name="Đấng Kiến Tạo Đầu Tiên (Chung Cuộc • MAX LV. 2550)", Realm="VeilsEnd", Level=2480, TargetLevel=2550, XP=40000000, Gold=1250000, CoreShards=5000,
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

        -- Merge Expansion Forge Recipes into C.ForgeRecipes (with balanced Gold scaling across Rarity tiers)
        for _, expRec in ipairs(ArsenalExp.ExpansionRecipes or {}) do
            local outId = expRec.OutputItemId or expRec.Id
            if outId and not recipeById[outId] and not recipeById[expRec.Id] then
                local matMap = {}
                for _, m in ipairs(expRec.Materials or {}) do
                    if m and m.ItemId then
                        matMap[m.ItemId] = m.Count or 1
                    end
                end
                local rawGold = tonumber(expRec.GoldCost) or 1000
                local rar = expRec.Rarity or "Legendary"
                local balancedGold = rawGold
                if rawGold < 25000 then
                    if rar == "Mythic" then
                        balancedGold = math.clamp(rawGold * 160, 750000, 2400000)
                    elseif rar == "Legendary" then
                        balancedGold = math.clamp(rawGold * 95, 95000, 480000)
                    else
                        balancedGold = math.clamp(rawGold * 45, 25000, 90000)
                    end
                end
                local entry = {
                    Id = outId,
                    RecipeId = expRec.Id,
                    ItemId = outId,
                    Name = expRec.Name,
                    Slot = expRec.Slot or "Weapon",
                    Rarity = rar,
                    Gold = balancedGold,
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
        if type(RarityCfg.Recipes) == "table" then
            for _, rec in pairs(RarityCfg.Recipes) do
                if type(rec) == "table" then
                    local matched = recipeById[rec.OutputItemId or ""] or recipeById[rec.Id or ""]
                    if matched and matched.Gold then
                        rec.GoldCost = matched.Gold
                        rec.Gold = matched.Gold
                    end
                end
            end
        end
    end

    local RARITY_LV = { Common = 1, Uncommon = 50, Rare = 150, Epic = 350, Legendary = 700, Mythic = 1800, Mythical = 1800 }
    for _, item in pairs(C.Items) do
        if type(item) == "table" and item.Slot ~= "Material" and item.Slot ~= "Quest" then
            if not item.LevelReq or item.LevelReq <= 1 then item.LevelReq = RARITY_LV[tostring(item.Rarity or "Common")] or 1 end
            if item.ATK and item.ATK > 0 then item.ATK = math.max(5, math.floor(item.ATK * 0.45 + 0.5)) end
            if item.DEF and item.DEF > 0 then item.DEF = math.max(2, math.floor(item.DEF * 0.45 + 0.5)) end
            if item.HP and item.HP > 0 then item.HP = math.max(15, math.floor(item.HP * 0.45 + 0.5)) end
            if item.CritRate and item.CritRate > 0 then item.CritRate = math.clamp(math.floor(item.CritRate * 0.45 + 0.5), 1, 8) end
            if item.CritDmg and item.CritDmg > 0 then item.CritDmg = math.clamp(math.floor(item.CritDmg * 0.45 + 0.5), 3, 12) end
        end
    end
    local function normMoves(cat, skipId)
        for id, entry in pairs(cat or {}) do
            if id ~= skipId and type(entry) == "table" then
                if entry.ATK and entry.ATK > 0 then entry.ATK = math.max(5, math.floor(entry.ATK * 0.45 + 0.5)) end
                if entry.CritRate and entry.CritRate > 0 then entry.CritRate = math.clamp(math.floor(entry.CritRate * 0.45 + 0.5), 1, 8) end
                if entry.CritDmg and entry.CritDmg > 0 then entry.CritDmg = math.clamp(math.floor(entry.CritDmg * 0.45 + 0.5), 3, 12) end
                if type(entry.Moves) == "table" then
                    for k, mv in pairs(entry.Moves) do
                        if type(mv) == "table" then
                            local ku = string.upper(tostring(mv.Key or k or "Z"))
                            local minCd = (ku == "V" and 15.0) or (ku == "C" and 10.5) or (ku == "X" and 7.5) or (ku == "F" and 6.0) or 5.0
                            mv.Cooldown = math.max(minCd, math.floor(((tonumber(mv.Cooldown) or 5.0) * 1.20) * 10 + 0.5) / 10)
                            mv.Cost = math.max(10, math.floor((tonumber(mv.Cost) or 10) * 1.25 + 0.5))
                            if mv.Multiplier and mv.Multiplier > 0 then mv.Multiplier = math.clamp(math.floor((mv.Multiplier * 0.65) * 100 + 0.5) / 100, 1.05, 3.40) end
                            if mv.Break and mv.Break > 0 then mv.Break = math.clamp(math.floor(mv.Break * 0.48 + 0.5), 6, 26) end
                        end
                    end
                end
            end
        end
    end
    normMoves(C.AetherFruits, "AbyssalSovereignCore")
    normMoves(C.FightingStyles, nil)
    normMoves(C.Swords, nil)
    normMoves(C.Guns, nil)
end

function C.GetDragonFormMoves(tier)
    local d = C.AetherFruits and C.AetherFruits.AbyssalSovereignCore
    if not d then return nil end
    return (tonumber(tier) and tonumber(tier) >= 2) and (d.Form2Moves or d.Moves) or (d.Form1Moves or d.Moves)
end

if game:GetService("RunService"):IsServer() then
task.spawn(function()
    local function isDisabledInst(inst)
        if not inst then return false end
        local n = inst.Name
        return n == "SkyRailPad" or string.sub(n, 1, 10) == "RailTrack_" or string.sub(n, 1, 14) == "AetherSkyRail_" or inst:GetAttribute("CompanionId") ~= nil
    end
    local function purgeWorld()
        for _, fn in ipairs({ "JumpPads", "AetherSkyRails", "ActiveCompanions" }) do
            local f = workspace:FindFirstChild(fn)
            if f then f:ClearAllChildren() end
        end
        for _, fn in ipairs({ "ActiveEnemies", "SkybreakWorldObjects", "SkybreakExpansionWorld" }) do
            local ef = workspace:FindFirstChild(fn)
            if ef then
                for _, d in ipairs(ef:GetDescendants()) do
                    if d.Name == "DummyFloorRing" and d:IsA("BasePart") then
                        d.Transparency = 1; d.CanCollide = false; d.CanQuery = false; d.CanTouch = false
                    elseif isDisabledInst(d) then
                        pcall(function() d:Destroy() end)
                    end
                end
            end
        end
    end
    workspace.ChildAdded:Connect(function(ch)
        if ch.Name == "JumpPads" or ch.Name == "AetherSkyRails" or ch.Name == "ActiveCompanions" then
            task.defer(function() if ch.Parent then ch:ClearAllChildren() end end)
            ch.ChildAdded:Connect(function(sub) task.defer(function() if sub and sub.Parent then pcall(function() sub:Destroy() end) end end) end)
        end
    end)
    workspace.DescendantAdded:Connect(function(desc)
        if isDisabledInst(desc) then
            task.defer(function() if desc and desc.Parent then pcall(function() desc:Destroy() end) end end)
        elseif desc.Name == "DummyFloorRing" and desc:IsA("BasePart") then
            task.defer(function() desc.Transparency = 1; desc.CanCollide = false; desc.CanQuery = false; desc.CanTouch = false end)
        end
    end)

    local tickIdx = 0
    while true do
        tickIdx += 1
        task.wait(tickIdx <= 40 and 0.25 or 0.5)
        purgeWorld()
        local sss = game:GetService("ServerScriptService")
        local services = sss and sss:FindFirstChild("Services")
        local gsMod = services and services:FindFirstChild("GameService")
        local pdMod = services and services:FindFirstChild("PlayerDataService")
        if gsMod then
            local okG, G = pcall(require, gsMod)
            local okD, D = false, nil
            if pdMod then okD, D = pcall(require, pdMod) end
            if okG and type(G) == "table" then
                local function applyBalCfg(dst, bal)
                    if type(dst) ~= "table" then return end
                    dst.HP = bal.HP; dst.ATK = bal.ATK; dst.Attack = bal.Attack; dst.DEF = bal.DEF; dst.Defense = bal.Defense; dst.XP = bal.XP; dst.Gold = bal.Gold
                    if bal.Speed ~= nil then dst.Speed = bal.Speed end
                    if bal.Range ~= nil then dst.Range = bal.Range end
                    if bal.Aggro ~= nil then dst.Aggro = bal.Aggro end
                    if bal.Leash ~= nil then dst.Leash = bal.Leash end
                    if bal.HasBusoHaki ~= nil then dst.HasBusoHaki = bal.HasBusoHaki end
                end
                for enemyId, bal in pairs(BALANCED_ENEMY_STATS) do
                    applyBalCfg(C.Enemies and C.Enemies[enemyId], bal)
                    if G.StaticData and G.StaticData.FALLBACK_ENEMIES then applyBalCfg(G.StaticData.FALLBACK_ENEMIES[enemyId], bal) end
                end
                for _, e in ipairs(G.Enemies or {}) do
                    if type(e) == "table" and e.Id and BALANCED_ENEMY_STATS[e.Id] then
                        local bal = BALANCED_ENEMY_STATS[e.Id]
                        applyBalCfg(e.Config, bal)
                        if e.Model and bal.HasBusoHaki then e.Model:SetAttribute("HasBusoHaki", true) end
                        if (e.MaxHP or 0) ~= bal.HP then
                            local wasFull = (e.HP or 0) >= (e.MaxHP or 1) * 0.99
                            e.MaxHP = bal.HP
                            if wasFull or (e.HP or 0) > bal.HP then e.HP = bal.HP end
                            if e.HPText then e.HPText.Text = string.format("%d / %d", math.floor(e.HP or bal.HP), bal.HP) end
                        end
                    end
                end
                if type(G.JumpPads) == "table" then table.clear(G.JumpPads) end
                G.SyncCompanions = function(p)
                    if G.Runtime and G.Runtime[p] and type(G.Runtime[p].Companions) == "table" then
                        for k, comp in pairs(G.Runtime[p].Companions) do
                            if comp and comp.Model then pcall(function() comp.Model:Destroy() end) end
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
                        if prevBeforeSync then prevBeforeSync(p, profile, rt, stats, statePayload) end
                        if type(profile) == "table" then profile.PartySize = "Solo" end
                        if type(statePayload) == "table" then statePayload.PartySize = "Solo"; statePayload.Companions = {} end
                    end
                end

                if type(G.Runtime) == "table" then
                    for plr, rt in pairs(G.Runtime) do
                        if type(rt) == "table" then
                            rt.FuryMeter = 100
                            if type(rt.Companions) == "table" then
                                for k, comp in pairs(rt.Companions) do
                                    if comp and comp.Model then pcall(function() comp.Model:Destroy() end) end
                                    rt.Companions[k] = nil
                                end
                            end
                        end
                        if plr and plr.Parent then
                            if (plr:GetAttribute("FuryMeter") or 0) < 100 then plr:SetAttribute("FuryMeter", 100) end
                            local prof = okD and D and type(D.Get) == "function" and D.Get(plr) or nil
                            if type(prof) == "table" and prof.PartySize ~= "Solo" then prof.PartySize = "Solo" end
                        end
                    end
                end

                if not G._DragonDualFormsHooked and type(G.UseSlotMove) == "function" and (G.SocialEconomy ~= nil or tickIdx >= 16) then
                    G._DragonDualFormsHooked = true
                    local prevUseSlotMove = G.UseSlotMove
                    local prevAction = G.Action
                    local prevStats = G.Stats
                    local prevHit = G.Hit
                    local prevPlayerDamage = G.PlayerDamage
                    local prevTickEnemy = G.TickEnemy
                    local remotesFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                    local combatFXRemote = remotesFolder and remotesFolder:FindFirstChild("CombatFX")

                    local function isDragonFruitId(fid)
                        local s = string.lower(tostring(fid or ""))
                        return s == "abyssalsovereigncore" or s == "dragon" or s == "abyssal_dragon" or s == "void_dragon" or s == "abyssal_sovereign"
                    end
                    local function resolveActiveDragonTier(p, rt)
                        local ch = p and p.Character
                        local t = tonumber(rt and rt.DragonFormTier) or tonumber(ch and ch:GetAttribute("DragonFormTier")) or tonumber(p and p:GetAttribute("DragonFormTier")) or 0
                        local tf = tostring((ch and ch:GetAttribute("FruitTransform")) or (p and p:GetAttribute("FruitTransform")) or "")
                        if t >= 2 or tf == "AbyssalSovereign" then return 2
                        elseif t == 1 or tf == "AbyssalDragonHybrid" then return 1 end
                        return 0
                    end

                    local SLOT_GROUP = { Weapon="Weapon", Helmet="Head", Helm="Head", Chest="Chest", Gloves="Hands", Gauntlets="Hands", Boots="Feet", Greaves="Feet", Ring="Ring", Necklace="Offhand", Offhand="Offhand", Artifact="Artifact" }
                    if type(prevStats) == "function" then
                        G.Stats = function(p)
                            local s = prevStats(p)
                            local profile = okD and D and type(D.Get) == "function" and D.Get(p) or nil
                            if not s or not profile then return s end
                            local lv = math.clamp(tonumber(profile.Level) or 1, 1, C.MaxLevel)
                            local base = C.Stats(lv, profile.ClassId, profile.StatAlloc)
                            local eq = type(profile.Equipped) == "table" and profile.Equipped or {}
                            local seenGrp = {}
                            local gearHP, gearATK, gearDEF, gearCrit, gearCritDmg = 0, 0, 0, 0, 0
                            for _, slot in ipairs(C.EquipSlots or { "Weapon", "Helmet", "Chest", "Gloves", "Boots", "Ring", "Necklace", "Artifact" }) do
                                local grp = SLOT_GROUP[slot] or slot
                                if not seenGrp[grp] then
                                    local itemId = (slot == "Weapon") and ((profile.ActiveSlot == 4 and (eq.Gun or profile.EquippedGun)) or eq[slot] or profile.Weapon) or eq[slot]
                                    local item = itemId and C.Items[itemId]
                                    if item then
                                        seenGrp[grp] = true
                                        local isGunOffhand = (grp == "Offhand") and (item.Slot == "Gun" or item.WeaponType == "Gun")
                                        if not isGunOffhand then
                                            local reqLv = math.max(1, tonumber(item.LevelReq) or 1)
                                            local gearScale = (lv >= reqLv) and 1.0 or math.clamp(lv / reqLv, 0.12, 1.0)
                                            gearATK += math.floor((tonumber(item.ATK) or 0) * gearScale)
                                            gearDEF += math.floor((tonumber(item.DEF) or 0) * gearScale)
                                            gearHP += math.floor((tonumber(item.HP) or 0) * gearScale)
                                            gearCrit += math.floor((tonumber(item.CritRate) or 0) * gearScale)
                                            gearCritDmg += math.floor((tonumber(item.CritDmg) or 0) * gearScale)
                                        end
                                    end
                                end
                            end
                            local atkBonusPct, defBonusPct, hpBonusPct = 0, 0, 0
                            local ch = p and p.Character
                            if (ch and ch:GetAttribute("HakiAura")) or (profile.Haki and profile.Haki.Aura) then
                                atkBonusPct += 0.10; defBonusPct += 0.10
                            end
                            local bounty = math.max(tonumber(profile.Bounty) or 0, tonumber(profile.Honor) or 0)
                            if bounty > 0 then
                                local bPct = math.clamp(bounty / 30000000, 0, 1) * 0.08
                                atkBonusPct += bPct; defBonusPct += bPct
                            end
                            local rv4 = ch and ch:GetAttribute("RaceV4")
                            if (rv4 and rv4 ~= "") or profile.RaceV4Active then
                                atkBonusPct += 0.14; defBonusPct += 0.14; hpBonusPct += 0.14
                            end
                            local rt = G.Runtime and G.Runtime[p]
                            local dTier = resolveActiveDragonTier(p, rt)
                            local ft = tostring((ch and ch:GetAttribute("FruitTransform")) or (p and p:GetAttribute("FruitTransform")) or "")
                            if dTier >= 2 then
                                atkBonusPct += 0.16; defBonusPct += 0.20
                            elseif dTier == 1 or ft ~= "" then
                                atkBonusPct += 0.10; defBonusPct += 0.14
                            end
                            s.HP = math.max(100, math.floor((base.HP + gearHP) * math.min(1.35, 1.0 + hpBonusPct)))
                            s.ATK = math.max(10, math.floor((base.ATK + gearATK) * math.min(1.55, 1.0 + atkBonusPct)))
                            s.DEF = math.max(4, math.floor((base.DEF + gearDEF) * math.min(1.55, 1.0 + defBonusPct)))
                            s.CritRate = math.clamp(base.CritRate + gearCrit, 4, 32)
                            s.CritDmg = math.clamp(base.CritDmg + gearCritDmg, 20, 42)
                            s.StarSkillDmgPct = math.min(tonumber(s.StarSkillDmgPct) or 0, 0.12)
                            return s
                        end
                    end

                    if type(prevHit) == "function" then
                        G.Hit = function(p, e, damage, breakPower, action)
                            if not e or not e.Alive then return end
                            local now = os.clock()
                            local stats = type(G.Stats) == "function" and G.Stats(p) or nil
                            local atk = math.max(12, (stats and tonumber(stats.ATK)) or 45)
                            local actStr = tostring(action or "")
                            local isBasic = (actStr == "Attack" or actStr == "Light" or actStr == "M1" or actStr == "HybridDragonM1" or actStr == "SovereignDragonM1")
                            local isMultiTick = (string.find(actStr, "Form1_", 1, true) ~= nil or string.find(actStr, "Form2_", 1, true) ~= nil) and actStr ~= "Form1_HybridTalonRend_X" and actStr ~= "Form1_HybridWingDash_F" and actStr ~= "Form2_SupersonicSoar_F"
                            local scaledDmg = math.min((tonumber(damage) or atk) * 0.58, isBasic and (atk * 1.45) or (isMultiTick and (atk * 0.68) or (atk * 2.85)))
                            local isBoss = (e.Config and e.Config.Boss == true) or (e == G.Boss)
                            if isBoss and (e.MaxHP or 0) > 0 then
                                scaledDmg = math.min(scaledDmg, math.max(40, (e.MaxHP or 10000) * (isMultiTick and 0.014 or 0.038)))
                            end
                            local scaledBreak = math.clamp(math.floor((tonumber(breakPower) or 6) * 0.30), 1, isBoss and 10 or 14)
                            if now < (e._BalStunImmuneUntil or 0) then
                                scaledBreak = 0; e.StunnedUntil = 0; e.FrozenUntil = 0
                            end
                            prevHit(p, e, math.max(1, scaledDmg), scaledBreak, action)
                            local afterNow = os.clock()
                            if afterNow < (e._BalStunImmuneUntil or 0) then
                                e.StunnedUntil = 0; e.FrozenUntil = 0
                            else
                                local stunned, frozen, broken = (e.StunnedUntil or 0) > afterNow, (e.FrozenUntil or 0) > afterNow, (e.BossBrokenUntil or 0) > afterNow
                                if stunned or frozen or broken then
                                    local maxCC = isBoss and 1.35 or 1.05
                                    if stunned then e.StunnedUntil = math.min(e.StunnedUntil, afterNow + maxCC) end
                                    if frozen then e.FrozenUntil = math.min(e.FrozenUntil, afterNow + maxCC) end
                                    if broken then e.BossBrokenUntil = math.min(e.BossBrokenUntil, afterNow + 1.8) end
                                    e._BalStunImmuneUntil = afterNow + 6.5
                                end
                            end
                        end
                    end

                    if type(prevPlayerDamage) == "function" then
                        G.PlayerDamage = function(p, amount, attackerEnemy)
                            local ch = p and p.Character
                            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                            local rt = G.Runtime and G.Runtime[p]
                            local profile = okD and D and type(D.Get) == "function" and D.Get(p) or nil
                            local stats = type(G.Stats) == "function" and G.Stats(p) or nil
                            if not ch or not hum or hum.Health <= 0 or not rt or not stats then return end
                            local now = os.clock()
                            if (rt.InvincibleUntil or 0) > now + 0.42 then rt.InvincibleUntil = now + 0.42 end
                            if now < (rt.InvincibleUntil or 0) then return end
                            local isBoss = attackerEnemy and ((attackerEnemy.Config and attackerEnemy.Config.Boss) or attackerEnemy == G.Boss)
                            local isElite = attackerEnemy and (attackerEnemy.Config and attackerEnemy.Config.Elite)
                            if profile and type(profile.Haki) == "table" and (profile.Haki.InstinctDodges or 0) > 3 then
                                profile.Haki.InstinctDodges = 3; p:SetAttribute("InstinctDodges", 3); ch:SetAttribute("InstinctDodges", 3)
                            end
                            local enemyCfg = attackerEnemy and attackerEnemy.Config
                            local enemyATK = math.max(tonumber(amount) or 18, (enemyCfg and tonumber(enemyCfg.ATK)) or 18)
                            local enemyLv = (enemyCfg and tonumber(enemyCfg.Level)) or 10
                            local plrLv = (profile and tonumber(profile.Level)) or 1
                            local defVal = math.max(0, tonumber(stats.DEF) or 10)
                            local defMit = math.clamp(defVal / (defVal + 200 + enemyLv * 0.25), 0.04, 0.40)
                            local dTier = resolveActiveDragonTier(p, rt)
                            local ft = tostring(ch:GetAttribute("FruitTransform") or "")
                            local tfMult = (dTier >= 2 and 0.84) or ((dTier == 1 or ft ~= "") and 0.90) or 1.0
                            local targetDmg = enemyATK * (1.0 - defMit) * tfMult
                            local maxHP = math.max(100, hum.MaxHealth)
                            if isBoss then targetDmg = math.max(targetDmg, maxHP * 0.14)
                            elseif isElite then targetDmg = math.max(targetDmg, maxHP * 0.10)
                            elseif enemyLv >= plrLv * 0.60 then targetDmg = math.max(targetDmg, maxHP * 0.065) end
                            local instinctOn = (ch:GetAttribute("HakiInstinct") == true or p:GetAttribute("HakiInstinct") == true)
                            local dodgesLeft = (profile and profile.Haki and tonumber(profile.Haki.InstinctDodges)) or 0
                            if (isBoss or isElite) and instinctOn and dodgesLeft > 0 then
                                profile.Haki.InstinctDodges = math.max(0, dodgesLeft - 1)
                                p:SetAttribute("InstinctDodges", profile.Haki.InstinctDodges)
                                ch:SetAttribute("InstinctDodges", profile.Haki.InstinctDodges)
                                hum:TakeDamage(math.max(1, math.floor(targetDmg * 0.65)))
                                rt.LastHurt = now
                                return
                            end
                            local gsDefFactor = (100 + defVal) / 100
                            local gsTfFactor = (ft ~= "") and (1.0 / 0.42) or 1.0
                            prevPlayerDamage(p, math.max(1, math.floor(targetDmg * gsDefFactor * gsTfFactor + 0.5)), attackerEnemy)
                        end
                    end

                    if type(prevTickEnemy) == "function" then
                        local PlayersService = game:GetService("Players")
                        G.TickEnemy = function(e, dt)
                            if not e or not e.Alive then return end
                            local now = os.clock()
                            if now < (e._BalStunImmuneUntil or 0) then e.StunnedUntil = 0; e.FrozenUntil = 0 end
                            prevTickEnemy(e, dt)
                            if not e.Alive or not e.Body or not e.Config then return end
                            local isBoss = (e.Config.Boss == true) or (e == G.Boss)
                            local maxAtkCd = isBoss and 1.35 or 1.45
                            if (e.NextAttack or 0) > now + maxAtkCd then e.NextAttack = now + maxAtkCd end
                            if (e.RecoverUntil or 0) > now + 0.55 then e.RecoverUntil = now + 0.55 end
                            local eAtk = tonumber(e.Config.ATK or e.Config.Attack) or 0
                            if eAtk > 0 and now >= (e.StunnedUntil or 0) and now >= (e.BossBrokenUntil or 0) and now >= (e._BalNextDirectStrike or 0) then
                                local reach = math.max(9.5, (tonumber(e.Config.Range) or 8) + (isBoss and 5.0 or 2.5))
                                local ePos = e.Body.Position
                                local bestPlr, bestDist = nil, reach
                                for _, plr in ipairs(PlayersService:GetPlayers()) do
                                    local ch = plr.Character
                                    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
                                    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
                                    if hrp and hum and hum.Health > 0 then
                                        local d = (hrp.Position - ePos).Magnitude
                                        if d <= bestDist then bestDist = d; bestPlr = plr end
                                    end
                                end
                                if bestPlr then
                                    e._BalNextDirectStrike = now + (isBoss and 1.45 or 1.65)
                                    if e.Model then
                                        e.Model:SetAttribute("EnemyAttackClip", isBoss and "HeroicKata" or "Attack")
                                        e.Model:SetAttribute("EnemyAttackDuration", 0.55)
                                        e.Model:SetAttribute("EnemyAttackAt", workspace:GetServerTimeNow())
                                    end
                                    task.delay(0.30, function()
                                        if not e or not e.Alive or not e.Body or os.clock() < (e.StunnedUntil or 0) then return end
                                        local ch = bestPlr and bestPlr.Character
                                        local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
                                        if hrp and (hrp.Position - e.Body.Position).Magnitude <= (reach + 3.0) then
                                            G.PlayerDamage(bestPlr, eAtk, e)
                                        end
                                    end)
                                end
                            end
                        end
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
                        rt.InvincibleUntil = math.max(rt.InvincibleUntil or 0, os.clock() + math.min(invDur or 0.38, 0.42))
                        rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, os.clock() + 1.6)
                        if type(G.Teleport) == "function" then G.Teleport(p, target) else hrp.CFrame = CFrame.new(target) * hrp.CFrame.Rotation end
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
                                    local cd = (tier == 2) and 0.52 or 0.40
                                    if now < (rt.Cooldowns and rt.Cooldowns.DragonM1 or 0) then return end
                                    rt.Cooldowns = rt.Cooldowns or {}
                                    rt.Cooldowns.DragonM1 = now + cd
                                    rt.FuryMeter = 100; p:SetAttribute("FuryMeter", 100)
                                    if ch then ch:SetAttribute("FuryMeter", 100) end
                                    local combo = ((tonumber(rt.DragonM1Combo) or 0) % 4) + 1
                                    rt.DragonM1Combo = combo
                                    local stats = type(G.Stats) == "function" and G.Stats(p) or { ATK = 65 }
                                    local atk = (stats and stats.ATK) or 65
                                    local reach = (tier == 2) and 24 or 16
                                    local mult = (tier == 2) and (combo == 4 and 1.65 or 1.30) or (combo == 4 and 1.35 or 1.05)
                                    local brk = (tier == 2) and 12 or 8
                                    local center = hrp.Position + hrp.CFrame.LookVector * (reach * 0.45)
                                    for _, e in ipairs(G.Enemies or {}) do
                                        if e.Alive and e.Body and ((e.Body.Position - center).Magnitude <= reach or (e.Body.Position - hrp.Position).Magnitude <= reach) then
                                            G.Hit(p, e, atk * mult, brk, tier == 2 and "SovereignDragonM1" or "HybridDragonM1")
                                        end
                                    end
                                    if combatFXRemote then
                                        combatFXRemote:FireAllClients({
                                            Kind = "Swing", Action = "Attack", FruitId = "AbyssalSovereignCore", DragonFormTier = tier,
                                            SubMode = (tier == 2) and "AbyssalSovereign" or "AbyssalDragonHybrid", Combo = combo, Element = "Void",
                                            Position = center, Origin = hrp.Position, Direction = hrp.CFrame.LookVector, Actor = p.UserId,
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
                                if not hrp then return end
                                rt.FuryMeter = 100; p:SetAttribute("FuryMeter", 100)
                                if ch then ch:SetAttribute("FuryMeter", 100) end
                                local curTier = resolveActiveDragonTier(p, rt)
                                local now = os.clock()
                                rt.Cooldowns = rt.Cooldowns or {}
                                if key == "V" then
                                    if now < (rt.Cooldowns.Slot_V or 0) then return end
                                    rt.Cooldowns.Slot_V = now + 3.5
                                    local nextTier = (curTier == 0 and 1) or (curTier == 1 and 2) or 0
                                    local tfName = (nextTier == 2 and "AbyssalSovereign") or (nextTier == 1 and "AbyssalDragonHybrid") or ""
                                    rt.DragonFormTier = nextTier
                                    p:SetAttribute("DragonFormTier", nextTier); p:SetAttribute("FruitTransform", tfName)
                                    if ch then ch:SetAttribute("DragonFormTier", nextTier); ch:SetAttribute("FruitTransform", tfName) end
                                    local stats = type(G.Stats) == "function" and G.Stats(p) or { ATK = 65 }
                                    local atk = (stats and stats.ATK) or 65
                                    local canDealBurst = now >= (rt.Cooldowns.DragonAscensionDmg or 0)
                                    if nextTier == 1 then
                                        G.Notify(p, "[DẠNG 1 • BÁN LONG NHÂN] Mở Bộ Kỹ Năng 1: [Z] Hỏa Long Đạn • [X] Bán Long Trảo • [C] Cuồng Long Xoáy • [F] Long Ảnh Bộ! (Nhấn [V] lần nữa để hóa Rồng Khổng Lồ Dạng 2)")
                                        if canDealBurst then
                                            rt.Cooldowns.DragonAscensionDmg = now + 14.0
                                            for _, e in ipairs(G.Enemies or {}) do
                                                if e.Alive and e.Body and (e.Body.Position - hrp.Position).Magnitude <= 26 then
                                                    G.Hit(p, e, atk * 2.0, 16, "DragonHybridAscension_T1")
                                                end
                                            end
                                        end
                                    elseif nextTier == 2 then
                                        rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, now + 60)
                                        G.Notify(p, "[DẠNG 2 • THÁI CỔ LONG HOÀNG] Mở Bộ Kỹ Năng 2: [Z] Thái Cổ Long Tức • [X] Long Hoàng Giáng Thế • [C] Vạn Long Hỏa Vũ • [F] Long Vũ Cửu Thiên!")
                                        if canDealBurst then
                                            rt.Cooldowns.DragonAscensionDmg = now + 14.0
                                            for _, e in ipairs(G.Enemies or {}) do
                                                if e.Alive and e.Body and (e.Body.Position - hrp.Position).Magnitude <= 36 then
                                                    G.Hit(p, e, atk * 2.6, 22, "DragonSovereignAscension_T2")
                                                end
                                            end
                                        end
                                    else
                                        G.Notify(p, "Đã thu hồi Long Hồn, trở về nhân dạng.")
                                    end
                                    if combatFXRemote then
                                        combatFXRemote:FireAllClients({
                                            Kind = "DragonTransform", DragonFormTier = nextTier, TransformName = tfName, SubMode = tfName,
                                            Awakened = true, FuryMeter = 100, Radius = nextTier == 2 and 46 or (nextTier == 1 and 28 or 14),
                                            Position = hrp.Position, Actor = p.UserId,
                                        })
                                    end
                                    if type(G.Sync) == "function" then G.Sync(p) end
                                    return
                                end

                                local moveSet = C.GetDragonFormMoves(curTier)
                                local moveSpec = moveSet and moveSet[key]
                                if moveSpec then
                                    local cdKey = "Slot_" .. key
                                    if now < (rt.Cooldowns[cdKey] or 0) then return end
                                    local cost = tonumber(moveSpec.Cost) or 12
                                    if (rt.Energy or 100) < cost then G.Notify(p, "Không đủ Aether Energy!"); return end
                                    rt.Cooldowns[cdKey] = now + (tonumber(moveSpec.Cooldown) or 5.0)
                                    rt.Energy = math.max(0, (rt.Energy or 100) - cost)
                                    local stats = type(G.Stats) == "function" and G.Stats(p) or { ATK = 65 }
                                    local atk = (stats and stats.ATK) or 65
                                    local originPos = hrp.Position
                                    local lookVec = hrp.CFrame.LookVector
                                    local range = tonumber(moveSpec.Range) or 32
                                    local mult = tonumber(moveSpec.Multiplier) or 2.5
                                    local brk = tonumber(moveSpec.Break) or 20
                                    local hits = math.max(1, tonumber(moveSpec.Hits) or 1)
                                    local endPos = originPos + lookVec * range
                                    local subMode = (curTier >= 2) and "AbyssalSovereign" or "AbyssalDragonHybrid"

                                    if curTier >= 2 then
                                        if key == "Z" then
                                            endPos = originPos + lookVec * 46
                                            for pulse = 1, 5 do
                                                task.delay((pulse - 1) * 0.10, function()
                                                    if not p or not p.Parent then return end
                                                    for _, e in ipairs(G.Enemies or {}) do
                                                        if e.Alive and e.Body then
                                                            local eb = e.Body.Position
                                                            local proj = math.clamp((eb - originPos):Dot(lookVec), 0, 46)
                                                            if (eb - (originPos + lookVec * proj)).Magnitude <= 20 then
                                                                G.Hit(p, e, (atk * mult) / 5, math.ceil(brk / 5), "Form2_SovereignBeam_Z")
                                                            end
                                                        end
                                                    end
                                                end)
                                            end
                                        elseif key == "X" then
                                            endPos = safeDashPlayer(p, rt, hrp, 30, 0.42)
                                            for wave = 1, 4 do
                                                task.delay((wave - 1) * 0.13, function()
                                                    if not p or not p.Parent then return end
                                                    for _, e in ipairs(G.Enemies or {}) do
                                                        if e.Alive and e.Body and (e.Body.Position - endPos).Magnitude <= 34 then
                                                            G.Hit(p, e, (atk * mult) / 4, math.ceil(brk / 4), "Form2_SovereignSkyfall_X")
                                                            e.StunnedUntil = math.max(e.StunnedUntil or 0, os.clock() + 1.0)
                                                        end
                                                    end
                                                end)
                                            end
                                        elseif key == "C" then
                                            endPos = originPos + lookVec * 20
                                            for wave = 1, 6 do
                                                task.delay((wave - 1) * 0.14, function()
                                                    if not p or not p.Parent then return end
                                                    for _, e in ipairs(G.Enemies or {}) do
                                                        if e.Alive and e.Body and (e.Body.Position - endPos).Magnitude <= 42 then
                                                            G.Hit(p, e, (atk * mult) / 6, math.ceil(brk / 6), "Form2_EclipseStarshower_C")
                                                        end
                                                    end
                                                end)
                                            end
                                        elseif key == "F" then
                                            endPos = safeDashPlayer(p, rt, hrp, 48, 0.42)
                                            local mid = (originPos + endPos) * 0.5
                                            for _, e in ipairs(G.Enemies or {}) do
                                                if e.Alive and e.Body and ((e.Body.Position - endPos).Magnitude <= 22 or (e.Body.Position - mid).Magnitude <= 24) then
                                                    G.Hit(p, e, atk * mult, brk, "Form2_SupersonicSoar_F")
                                                end
                                            end
                                        end
                                    else
                                        if key == "Z" then
                                            endPos = originPos + lookVec * 32
                                            for shot = 1, 5 do
                                                task.delay((shot - 1) * 0.08, function()
                                                    if not p or not p.Parent then return end
                                                    local impactPos = originPos + lookVec * (6.4 * shot)
                                                    for _, e in ipairs(G.Enemies or {}) do
                                                        if e.Alive and e.Body and ((e.Body.Position - impactPos).Magnitude <= 16 or (e.Body.Position - endPos).Magnitude <= 16) then
                                                            G.Hit(p, e, (atk * mult) / 5, math.ceil(brk / 5), "Form1_FireballVolley_Z")
                                                        end
                                                    end
                                                end)
                                            end
                                        elseif key == "X" then
                                            endPos = safeDashPlayer(p, rt, hrp, 20, 0.38)
                                            for _, e in ipairs(G.Enemies or {}) do
                                                if e.Alive and e.Body and ((e.Body.Position - endPos).Magnitude <= 20 or (e.Body.Position - originPos).Magnitude <= 18) then
                                                    G.Hit(p, e, atk * mult, brk, "Form1_HybridTalonRend_X")
                                                    e.StunnedUntil = math.max(e.StunnedUntil or 0, os.clock() + 0.9)
                                                end
                                            end
                                        elseif key == "C" then
                                            endPos = originPos
                                            for pulse = 1, 4 do
                                                task.delay((pulse - 1) * 0.12, function()
                                                    if not p or not p.Parent then return end
                                                    local curPos = (p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character.HumanoidRootPart.Position) or originPos
                                                    for _, e in ipairs(G.Enemies or {}) do
                                                        if e.Alive and e.Body and (e.Body.Position - curPos).Magnitude <= 26 then
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
                                            endPos = safeDashPlayer(p, rt, hrp, 32, 0.38)
                                            for _, e in ipairs(G.Enemies or {}) do
                                                if e.Alive and e.Body and (e.Body.Position - endPos).Magnitude <= 16 then
                                                    G.Hit(p, e, atk * mult, brk, "Form1_HybridWingDash_F")
                                                end
                                            end
                                        end
                                    end

                                    if combatFXRemote then
                                        combatFXRemote:FireAllClients({
                                            Kind = "FruitMove", Action = "Fruit" .. key, Awakened = (curTier >= 2), FruitId = "AbyssalSovereignCore",
                                            activeId = "AbyssalSovereignCore", MoveKey = key, key = key, MoveName = moveSpec.Name, Mechanic = moveSpec.Mechanic,
                                            DragonFormTier = (curTier >= 2) and 2 or 1, SubMode = subMode, Hits = hits, Element = "Void",
                                            Origin = originPos, StartPos = originPos, Position = endPos, EndPos = endPos, Direction = lookVec, Radius = range, Actor = p.UserId,
                                        })
                                    end
                                    if type(G.Sync) == "function" then G.Sync(p) end
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
                                        if plr and plr.Parent and (plr:GetAttribute("FuryMeter") or 0) < 100 then
                                            plr:SetAttribute("FuryMeter", 100)
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
