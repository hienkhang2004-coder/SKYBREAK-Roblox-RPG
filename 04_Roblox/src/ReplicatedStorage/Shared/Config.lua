local C = {}
C.MaxLevel = 100
C.MaxStat = 100
C.StatPointsPerLevel = 3
C.StudioPersistence = false -- Enable only in a published, isolated test experience.
C.StoreName = "SKYBREAK_P0_TEST_v1"
C.LeaseSeconds = 180
C.AutosaveSeconds = 45
C.Spawn = Vector3.new(-92, 42, 153)
C.Arena = Vector3.new(0, 49, -104)
C.ArenaEntry = Vector3.new(0, 51, -79)
C.BossSpawn = Vector3.new(0, 52, -111)
C.QuestCheckpoint = Vector3.new(-91, 45, 61)

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
    return math.floor(80 + 25 * (level - 1) + 3 * ((level - 1) ^ 1.5))
end

local islandList = {
    -- Sea 1: Golden Sky Archipelago (Lv. 1–10)
    {Id="SkyHub", Name="Sea 1 • Zone 1: Đảo Khởi Đầu (Sky Hub Nexus)", Realm="GoldenSky", Sea=1, Pos=Vector3.new(-92, 42, 153), Level="Lv. 1–3", MinLevel=1, MaxLevel=3, Order=1},
    {Id="GoldenSky", Name="Sea 1 • Zone 1: Bầu Trời Hoàng Kim (Golden Sky Hub)", Realm="GoldenSky", Sea=1, Pos=Vector3.new(-92, 42, 153), Level="Lv. 1–10", MinLevel=1, MaxLevel=10, Order=1},
    {Id="ZiolesGachaShrine", Name="Sea 1 • Zone 1B: Điện Thờ Zioles Gacha (Zioles Shrine)", Realm="GoldenSky", Sea=1, Pos=Vector3.new(-220, 42, 272), Level="Lv. 2–5", MinLevel=2, MaxLevel=5, Order=2},
    {Id="AetherShrines", Name="Sea 1 • Zone 1C: Đài Điện Thờ Aether (Aether Shrine)", Realm="GoldenSky", Sea=1, Pos=Vector3.new(60, 42, 276), Level="Lv. 3–6", MinLevel=3, MaxLevel=6, Order=2},
    {Id="WestGarden", Name="Sea 1 • Zone 2: Pháo Đài Không Tặc Vườn Tây (West Garden Bastion)", Realm="GoldenSky", Sea=1, Pos=Vector3.new(-520, 52, 78), Level="Lv. 4–7", MinLevel=4, MaxLevel=7, Order=3},
    {Id="LumenPlaza", Name="Sea 1 • Zone 3: Quảng Trường Ánh Sáng (Lumen Plaza)", Realm="GoldenSky", Sea=1, Pos=Vector3.new(0, 44, 20), Level="Lv. 5–8", MinLevel=5, MaxLevel=8, Order=4},
    {Id="SunshardSanctuary", Name="Sea 1 • Zone 4: Đảo Đền Mây Nổi (Sunshard Sky Sanctuary)", Realm="GoldenSky", Sea=1, Pos=Vector3.new(540, 92, -32), Level="Lv. 8–10", MinLevel=8, MaxLevel=10, Order=5},
    {Id="BossForecourt", Name="Sea 1 • Zone 5: Tháp Phán Quyết (Aureon Spire Citadel)", Realm="GoldenSky", Sea=1, Pos=Vector3.new(0, 45, -42), Level="Lv. 10 (Boss)", MinLevel=8, MaxLevel=10, Order=6},

    -- Sea 2: Frozen Cyber Expanse (Lv. 11–20)
    {Id="FrozenCyber", Name="Sea 2 • Zone 6: Cảng Băng Giá (Cyberport Outpost)", Realm="FrozenCyber", Sea=2, Pos=Vector3.new(2390, 46, 155), Level="Lv. 11–14", MinLevel=11, MaxLevel=14, Order=7},
    {Id="CyberportCafe", Name="Sea 2 • Zone 6B: Quán Cà Phê Giao Dịch (Cyberport Café Island)", Realm="FrozenCyber", Sea=2, Pos=Vector3.new(2020, 50, 340), Level="Lv. 12–15", MinLevel=12, MaxLevel=15, Order=8},
    {Id="PermafrostGarrison", Name="Sea 2 • Zone 7: Pháo Đài Tuyết (Permafrost Garrison Fortress)", Realm="FrozenCyber", Sea=2, Pos=Vector3.new(1940, 60, -180), Level="Lv. 14–17", MinLevel=14, MaxLevel=17, Order=9},
    {Id="MicrochipRaidLab", Name="Sea 2 • Zone 8: Phòng Thí Nghiệm Đột Kích (Microchip Raid Lab)", Realm="FrozenCyber", Sea=2, Pos=Vector3.new(3040, 72, 152), Level="Lv. 16–19", MinLevel=16, MaxLevel=19, Order=10},
    {Id="GlacialWreckage", Name="Sea 2 • Zone 9: Xác Tàu Băng Cổ Đại (Glacial Wreckage Sea)", Realm="FrozenCyber", Sea=2, Pos=Vector3.new(2962, 48, -422), Level="Lv. 18–20", MinLevel=18, MaxLevel=20, Order=11},
    {Id="CryonArena", Name="Sea 2 • Zone 10: Ngai Vàng Băng Đế (Cryon Prime Citadel)", Realm="FrozenCyber", Sea=2, Pos=Vector3.new(2500, 55, -72), Level="Lv. 20 (Boss)", MinLevel=18, MaxLevel=20, Order=12},

    -- Sea 3: Shadow Realm Abyss (Lv. 21–30)
    {Id="ShadowRealm", Name="Sea 3 • Zone 11: Pháo Đài Hư Không (Shadow Realm Outpost)", Realm="ShadowRealm", Sea=3, Pos=Vector3.new(-2570, 58, 125), Level="Lv. 21–24", MinLevel=21, MaxLevel=24, Order=13},
    {Id="CastleOnTheVoid", Name="Sea 3 • Zone 11B: Dinh Thự Hư Không (Castle on the Void Mansion)", Realm="ShadowRealm", Sea=3, Pos=Vector3.new(-3160, 60, 280), Level="Lv. 23–26", MinLevel=23, MaxLevel=26, Order=14},
    {Id="UmbralSanctum", Name="Sea 3 • Zone 12: Rừng Tinh Thể Đen (Umbral Crystal Sanctum)", Realm="ShadowRealm", Sea=3, Pos=Vector3.new(-1920, 64, 276), Level="Lv. 25–28", MinLevel=25, MaxLevel=28, Order=15},
    {Id="TempleOfTheCore", Name="Sea 3 • Zone 13: Đền Thờ Thức Tỉnh Tộc V4 (Temple of the Core)", Realm="ShadowRealm", Sea=3, Pos=Vector3.new(-3160, 100, -288), Level="Lv. 27–29", MinLevel=27, MaxLevel=29, Order=16},
    {Id="LeviathanAbyss", Name="Sea 3 • Zone 14: Đảo Ảo Ảnh & Vực Thẳm Leviathan (Mirage Abyss)", Realm="ShadowRealm", Sea=3, Pos=Vector3.new(-2540, 72, -708), Level="Lv. 28–30", MinLevel=28, MaxLevel=30, Order=17},
    {Id="NoxarArena", Name="Sea 3 • Zone 15: Ngai Vàng Hư Không (Noxar's Sovereign Throne)", Realm="ShadowRealm", Sea=3, Pos=Vector3.new(-2434, 69, -29), Level="Lv. 30 (Boss)", MinLevel=28, MaxLevel=30, Order=18},

    -- Expansion Realms (Celestial World Map Realms 4–8 • Lv. 31–100)
    {Id="VerdantCrown", Name="Realm 4 • Vương Miện Cổ Thụ (The Verdant Crown)", Realm="VerdantCrown", Sea=4, Pos=Vector3.new(0, 124, -2364), Level="Lv. 31–42", MinLevel=31, MaxLevel=42, Order=19},
    {Id="EmberforgeWastes", Name="Realm 5 • Hoang Mạc Lò Rèn Lửa (Emberforge Wastes)", Realm="EmberforgeWastes", Sea=5, Pos=Vector3.new(2400, 124, -2362), Level="Lv. 43–54", MinLevel=43, MaxLevel=54, Order=20},
    {Id="AbyssalTides", Name="Realm 6 • Thủy Triều Vực Sâu (Abyssal Tides)", Realm="AbyssalTides", Sea=6, Pos=Vector3.new(-2400, 124, -2428), Level="Lv. 55–66", MinLevel=55, MaxLevel=66, Order=21},
    {Id="ChronosBastion", Name="Realm 7 • Pháo Đài Thời Gian (Chronos Bastion)", Realm="ChronosBastion", Sea=7, Pos=Vector3.new(0, 184, -4168), Level="Lv. 67–80", MinLevel=67, MaxLevel=80, Order=22},
    {Id="VeilsEnd", Name="Realm 8 • Tận Cùng Bức Màn (The Veil's End)", Realm="VeilsEnd", Sea=8, Pos=Vector3.new(0, 264, -5780), Level="Lv. 81–100", MinLevel=81, MaxLevel=100, Order=23},
}

C.FastTravel = {}
C.FastTravelOrder = {}
for _, isl in ipairs(islandList) do
    C.FastTravel[isl.Id] = isl
    table.insert(C.FastTravelOrder, isl.Id)
end
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
    local class = C.Classes[classId or 'SkyGuardian'] or C.Classes.SkyGuardian
    local baseCrit = classId == 'ThunderStriker' and 12 or (classId == 'ArcaneMage' and 8 or 5)
    local baseCritDmg = classId == 'ThunderStriker' and 60 or 50
    local alloc = type(statAlloc) == "table" and statAlloc or {}
    local defPts = math.max(0, (tonumber(alloc.Defense) or 1) - 1)
    local offensePts = math.max(
        0,
        (tonumber(alloc.Melee) or 1) - 1,
        (tonumber(alloc.Sword) or 1) - 1,
        (tonumber(alloc.Gun) or 1) - 1,
        (tonumber(alloc.Fruit) or 1) - 1
    )
    return {
        HP = math.floor((120 + 22 * (level - 1) + defPts * 12) * class.HP),
        ATK = math.floor((12 + 2.5 * (level - 1) + offensePts * 1.8) * class.ATK),
        DEF = math.floor((5 + 1.2 * (level - 1) + defPts * 1.0) * class.DEF),
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
            Z = {Key="Z", Name="Gale Blades • Phong Đao", AwakenedName="Tempest Cleaver • Cuồng Phong Đao", Mastery=1, Cooldown=5, Cost=10, Range=24, Multiplier=2.2, Break=20, Element="Sky", Desc="Phóng chuỗi lưỡi đao gió cắt xuyên mục tiêu phía trước."},
            X = {Key="X", Name="Cyclone Burst • Lốc Xoáy Không Trung", AwakenedName="Supercell Vortex • Siêu Bão Đẩy Lùi", Mastery=20, Cooldown=8, Cost=14, Range=22, Multiplier=2.6, Break=26, Element="Sky", Desc="Tạo cột lốc xoáy cuốn tung kẻ địch lên không trung."},
            C = {Key="C", Name="Tornado Crush • Bão Phong Nghiền Nát", AwakenedName="Eye of the Hurricane • Tâm Bão Hủy Diệt", Mastery=45, Cooldown=11, Cost=18, Range=26, Multiplier=3.1, Break=32, Element="Sky", Desc="Triệu hồi bão lớn giam cầm và gây sát thương liên hoàn."},
            V = {Key="V", Name="Skyborn Typhoon • Đại Cuồng Phong", AwakenedName="Cataclysmic Gale • Thiên Tai Gió Lốc", Mastery=75, Cooldown=16, Cost=24, Range=30, Multiplier=3.9, Break=42, Element="Sky", Desc="Giải phóng đại cuồng phong càn quét toàn bộ khu vực."},
            F = {Key="F", Name="Wind Ride • Cưỡi Gió", AwakenedName="Jetstream Flight • Phản Lực Không Lưu", Mastery=10, Cooldown=6, Cost=10, Range=24, Multiplier=1.2, Break=10, Element="Sky", Desc="Hóa thành luồng gió bay nhanh qua bầu trời."},
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
        Passive = "Long Vương Nộ Khí (3D Transform): Hóa thân thành Hắc Long Hư Không 3D có đôi cánh năng lượng và sừng vương miện, giảm 62% sát thương và cường hóa toàn diện!",
        Desc = "Trái Thần Thoại tối thượng trị giá 5,000,000 Gold của Skybreak, sở hữu biến hình 3D Long Vương Hư Không hủy diệt vạn vật.",
        Moves = {
            Z = {Key="Z", Name="Heatwave Cannon • Long Tức Hư Không", AwakenedName="Abyssal Sovereign Breath • Hơi Thở Hắc Long Vương", Mastery=1, Cooldown=5, Cost=12, Range=36, Multiplier=3.3, Break=36, Element="Void", Desc="Bắn luồng hơi thở rồng hư không xuyên thấu phát nổ diện rộng."},
            X = {Key="X", Name="Dragonic Claw • Long Trảo Xé Toạc", AwakenedName="Void Talons • Tuyệt Trảo Hắc Long", Mastery=100, Cooldown=9, Cost=16, Range=28, Multiplier=3.9, Break=42, Element="Void", Desc="Lao tới vồ lấy mục tiêu bằng vuốt rồng bọc lửa tím rồi kéo lê kích nổ."},
            C = {Key="C", Name="Fire Shower • Mưa Thiên Hỏa Long Vương", AwakenedName="Cataclysmic Starshower • Vạn Long Hỏa Vũ", Mastery=200, Cooldown=12.5, Cost=22, Range=38, Multiplier=4.6, Break=50, Element="Void", Desc="Bay lên không trung trút hàng chục quả cầu lửa rồng xuống toàn bộ khu vực."},
            V = {Key="V", Name="Imperial Transformation • Hóa Hình Long Vương 3D", AwakenedName="Sovereign Ascension • Chân Thân Hắc Long Đế Vương", Mastery=300, Cooldown=6, Cost=20, Range=36, Multiplier=6.0, Break=68, Element="Void", Desc="Biến hình 3D thành Long Vương Hư Không với cánh rồng khổng lồ, giảm 62% sát thương và bùng nổ sóng chấn động!"},
            F = {Key="F", Name="Dragonic Soar • Long Vũ Cửu Thiên", AwakenedName="Abyssal Wing Glide • Cánh Rồng Xuyên Không", Mastery=60, Cooldown=5, Cost=10, Range=32, Multiplier=2.2, Break=24, Element="Void", Desc="Vỗ đôi cánh Hắc Long lướt nhanh qua bầu trời kèm lốc lửa tím."},
        },
    },
}

-- ============================================================================
-- 6 FIGHTING STYLES (SLOT 1: MELEE)
-- ============================================================================
C.StyleOrder = {
    "SkybornCombat",
    "SkyStep",
    "GlacialFist",
    "ElectricClaw",
    "AbyssalTalon",
    "CelestialGodhuman",
}

C.FightingStyles = {
    SkybornCombat = {
        Id = "SkybornCombat",
        Name = "Võ Thuật Skyborn • Skyborn Combat",
        PriceGold = 0,
        PriceShards = 0,
        Element = "Sky",
        Desc = "Quyền pháp căn bản của các chiến binh bầu trời, cân bằng giữa tốc độ và phòng ngự.",
        Moves = {
            Z = {Key="Z", Name="Quick Tackle • Đột Kích Nhanh", Mastery=1, Cooldown=5, Cost=10, Range=16, Multiplier=2.1, Break=20, Element="Sky", Desc="Lao nhanh về phía trước tung cú đấm trực diện."},
            X = {Key="X", Name="Ground Smash • Chấn Địa Quyền", Mastery=20, Cooldown=8, Cost=14, Range=18, Multiplier=2.6, Break=26, Element="Sky", Desc="Đấm xuống mặt đất tạo sóng chấn động hất tung kẻ địch."},
            C = {Key="C", Name="Skyborn Combo • Liên Hoàn Quyền", Mastery=50, Cooldown=11, Cost=18, Range=18, Multiplier=3.2, Break=32, Element="Sky", Desc="Tung chuỗi liên hoàn quyền tốc độ cao kết thúc bằng cú đá xoáy."},
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

C.Companions = {
    Kairo = {Id="Kairo", Name="Kairo • Vanguard", ClassId="SkyGuardian", VisualAsset="Male_SkyGuardian", Role="TANK", HP=1800, MaxHP=1800, ATK=42, Offset=Vector3.new(-6, 0, 5)},
    Lumen = {Id="Lumen", Name="Lumen • Starweaver", ClassId="ArcaneMage", VisualAsset="ArcaneMage", Role="HEALER", HP=1350, MaxHP=1350, ATK=48, Offset=Vector3.new(6, 0, 6)},
    Nyx = {Id="Nyx", Name="Nyx • Shadowblitz", ClassId="ThunderStriker", VisualAsset="ThunderStrikerFemale", Role="ASSASSIN", HP=1450, MaxHP=1450, ATK=55, Offset=Vector3.new(0, 0, 8)},
}

C.Enemies = {
    -- Realm 1: Golden Sky Mobs & Bosses (Lv. 1 - 10)
    TrainingDrone = {Name="Training Drone", Level=1, VisualAsset="TrainingDrone", Element="Sky", HP=65, ATK=6, Attack=6, DEF=0, Defense=0, XP=40, Gold=25, Range=6, Speed=9, Aggro=30, Leash=30, Drop="SkyIron"},
    SkyPirate = {Name="Sky Pirate", Level=2, VisualAsset="SkyPirate", Element="Sky", HP=110, ATK=10, Attack=10, DEF=3, Defense=3, XP=55, Gold=35, Range=7, Speed=11, Aggro=30, Leash=30, Drop="SkyIron"},
    CorruptedGuard = {Name="Corrupted Guard", Level=3, VisualAsset="CorruptedGuard", Element="Sky", HP=145, ATK=13, Attack=13, DEF=5, Defense=5, XP=75, Gold=45, Range=7, Speed=11, Aggro=34, Leash=34, Drop="SunshardCore"},
    LightArcher = {Name="Light Archer", Level=5, VisualAsset="LightArcher", Element="Sky", HP=130, ATK=16, Attack=16, DEF=4, Defense=4, XP=95, Gold=55, Range=27, Speed=9, Aggro=32, Leash=32, Ranged=true, Drop="CelestialFeather"},
    SunshardRoyalGuard = {Name="Sunshard Royal Guard", Level=6, VisualAsset="SunshardRoyalGuard", Element="Sky", HP=220, ATK=19, Attack=19, DEF=8, Defense=8, XP=120, Gold=75, Range=7.5, Speed=11, Aggro=34, Leash=38, Drop="SunshardCore"},
    GoldenKnight = {Name="Golden Knight", Level=6, VisualAsset="GoldenKnight", Element="Sky", HP=560, ATK=25, Attack=25, DEF=12, Defense=12, XP=260, Gold=160, Range=10, Speed=10, Aggro=35, Leash=35, Elite=true, Drop="SunshardCore"},
    SunshardTemplar = {Name="Sunshard Templar", Level=7, VisualAsset="SunshardTemplar", Element="Sky", HP=340, ATK=22, Attack=22, DEF=10, Defense=10, XP=165, Gold=95, Range=8, Speed=11, Aggro=34, Leash=42, Drop="SunshardCore"},
    AureonSentinel = {Name="AUREON SENTINEL", Level=10, VisualAsset="AureonSentinel", Element="Sky", HP=2400, ATK=34, Attack=34, DEF=16, Defense=16, XP=1000, Gold=900, Range=16, Speed=9, Aggro=47, Leash=47, Boss=true, Drop="CoreEssence"},
    EnergyPylon = {Name="Energy Pylon", Level=10, VisualAsset="EnergyPylon", Element="Sky", HP=160, ATK=0, Attack=0, DEF=0, Defense=0, XP=0, Gold=0, Range=0, Speed=0, Aggro=0, Leash=0},

    -- Realm 2: Frozen Cyber Mobs & Bosses (Lv. 11 - 20)
    FrostDrone = {Name="Frost Automaton", Level=11, VisualAsset="FrostDrone", Element="Frost", HP=420, ATK=30, Attack=30, DEF=12, Defense=12, Speed=14, Range=6.5, Aggro=38, Leash=55, XP=180, Gold=120, Drop="SkyIron"},
    FrostAutomaton = {Name="Frost Automaton", Level=11, VisualAsset="FrostAutomaton", Element="Frost", HP=420, ATK=30, Attack=30, DEF=12, Defense=12, Speed=14, Range=6.5, Aggro=38, Leash=55, XP=180, Gold=120, Drop="SkyIron"},
    CyberMercenary = {Name="Cyber Mercenary", Level=12, VisualAsset="CyberMercenary", Element="Frost", HP=490, ATK=34, Attack=34, DEF=14, Defense=14, Speed=14, Range=24, Aggro=42, Leash=58, Ranged=true, XP=210, Gold=140, Drop="SkyIron"},
    CryoGuard = {Name="Cryo Vanguard", Level=14, VisualAsset="CryoGuard", Element="Frost", HP=640, ATK=38, Attack=38, DEF=18, Defense=18, Speed=14, Range=7, Aggro=40, Leash=60, XP=250, Gold=165, Drop="SunshardCore"},
    CryoVanguard = {Name="Cryo Vanguard", Level=14, VisualAsset="CryoVanguard", Element="Frost", HP=640, ATK=38, Attack=38, DEF=18, Defense=18, Speed=14, Range=7, Aggro=40, Leash=60, XP=250, Gold=165, Drop="SunshardCore"},
    CyberArcher = {Name="Glacial Sniper", Level=15, VisualAsset="GlacialMarksman", Element="Frost", HP=520, ATK=42, Attack=42, DEF=14, Defense=14, Speed=13, Range=28, Aggro=45, Leash=60, Ranged=true, XP=240, Gold=155, Drop="CelestialFeather"},
    GlacialMarksman = {Name="Glacial Sniper", Level=15, VisualAsset="GlacialMarksman", Element="Frost", HP=520, ATK=42, Attack=42, DEF=14, Defense=14, Speed=13, Range=28, Aggro=45, Leash=60, Ranged=true, XP=240, Gold=155, Drop="CelestialFeather"},
    GlacialSniper = {Name="Glacial Sniper", Level=15, VisualAsset="GlacialSniper", Element="Frost", HP=520, ATK=42, Attack=42, DEF=14, Defense=14, Speed=13, Range=28, Aggro=45, Leash=60, Ranged=true, XP=240, Gold=155, Drop="CelestialFeather"},
    MechaDrone = {Name="Mecha Security Drone", Level=16, VisualAsset="MechaDrone", Element="Frost", HP=680, ATK=44, Attack=44, DEF=18, Defense=18, Speed=15, Range=7.5, Aggro=42, Leash=60, XP=270, Gold=175, Drop="SkyIron"},
    ArcticCorsair = {Name="Arctic Corsair", Level=18, VisualAsset="ArcticCorsair", Element="Frost", HP=760, ATK=48, Attack=48, DEF=20, Defense=20, Speed=15, Range=7.5, Aggro=42, Leash=60, XP=310, Gold=200, Drop="SkyIron"},
    CryonPillar = {Name="Cryon Glacial Pillar", Level=20, VisualAsset="CryonPillar", Element="Frost", HP=300, ATK=0, Attack=0, DEF=5, Defense=5, Speed=0, Range=0, Aggro=0, Leash=999, XP=50, Gold=60},
    CryonPrime = {Name="CRYON PRIME", Level=20, VisualAsset="CryonPrime", Element="Frost", HP=5400, ATK=58, Attack=58, DEF=26, Defense=26, XP=2200, Gold=1800, Range=24, Speed=0, Aggro=55, Leash=55, Boss=true, Drop="CoreEssence"},

    -- Realm 3: Shadow Realm Mobs & Bosses (Lv. 21 - 30)
    VoidPirate = {Name="Void Marauder", Level=21, VisualAsset="VoidMarauder", Element="Void", HP=920, ATK=56, Attack=56, DEF=24, Defense=24, Speed=16, Range=7, Aggro=40, Leash=55, XP=380, Gold=260, Drop="SunshardCore"},
    VoidMarauder = {Name="Void Marauder", Level=21, VisualAsset="VoidMarauder", Element="Void", HP=920, ATK=56, Attack=56, DEF=24, Defense=24, Speed=16, Range=7, Aggro=40, Leash=55, XP=380, Gold=260, Drop="SunshardCore"},
    VoidRaider = {Name="Void Raider", Level=22, VisualAsset="VoidRaider", Element="Void", HP=980, ATK=60, Attack=60, DEF=25, Defense=25, Speed=16, Range=7.5, Aggro=40, Leash=55, XP=410, Gold=280, Drop="SunshardCore"},
    ShadowArcher = {Name="Umbral Ranger", Level=24, VisualAsset="UmbralBowman", Element="Void", HP=860, ATK=64, Attack=64, DEF=22, Defense=22, Speed=14, Range=28, Aggro=45, Leash=60, Ranged=true, XP=430, Gold=300, Drop="CelestialFeather"},
    UmbralBowman = {Name="Umbral Ranger", Level=24, VisualAsset="UmbralBowman", Element="Void", HP=860, ATK=64, Attack=64, DEF=22, Defense=22, Speed=14, Range=28, Aggro=45, Leash=60, Ranged=true, XP=430, Gold=300, Drop="CelestialFeather"},
    UmbralRanger = {Name="Umbral Ranger", Level=24, VisualAsset="UmbralRanger", Element="Void", HP=860, ATK=64, Attack=64, DEF=22, Defense=22, Speed=14, Range=28, Aggro=45, Leash=60, Ranged=true, XP=430, Gold=300, Drop="CelestialFeather"},
    ShadowSpecter = {Name="Shadow Specter", Level=25, VisualAsset="ShadowSpecter", Element="Void", HP=1120, ATK=68, Attack=68, DEF=26, Defense=26, Speed=17, Range=8, Aggro=44, Leash=60, XP=480, Gold=340, Drop="CelestialFeather"},
    AbyssalKnight = {Name="Abyssal Dreadknight", Level=26, VisualAsset="AbyssalKnight", Element="Void", HP=1450, ATK=74, Attack=74, DEF=32, Defense=32, Speed=14, Range=8, Aggro=42, Leash=65, Elite=true, XP=620, Gold=450, Drop="CoreEssence"},
    AbyssalDreadknight = {Name="Abyssal Dreadknight", Level=26, VisualAsset="AbyssalDreadknight", Element="Void", HP=1450, ATK=74, Attack=74, DEF=32, Defense=32, Speed=14, Range=8, Aggro=42, Leash=65, Elite=true, XP=620, Gold=450, Drop="CoreEssence"},
    TerrorSkyShark = {Name="Terror Sky-Shark", Level=28, VisualAsset="TerrorSkyShark", Element="Void", HP=1850, ATK=80, Attack=80, DEF=34, Defense=34, Speed=15, Range=11, Aggro=52, Leash=75, Elite=true, XP=780, Gold=580, Drop="CoreEssence"},
    NoxarVoidFX = {Name="Void Singularity", Level=30, VisualAsset="NoxarVoidFX", Element="Void", HP=550, ATK=0, Attack=0, DEF=10, Defense=10, Speed=0, Range=0, Aggro=0, Leash=999, XP=100, Gold=120},
    Noxar = {Name="NOXAR • VOID SOVEREIGN", Level=30, VisualAsset="Noxar", Element="Void", HP=9500, ATK=90, Attack=90, DEF=36, Defense=36, XP=4200, Gold=3600, Range=26, Speed=0, Aggro=58, Leash=58, Boss=true, Drop="CoreEssence"},

    -- Sea Event & Island Raid Bosses (Grand Sky Seas v12 Rigged Blender Models)
    PirateCaptainVance = {Name="CAPTAIN VANCE • ĐÔ ĐỐC KHÔNG TẶC", Level=9, VisualAsset="PirateCaptainVance", Element="Sky", HP=1650, ATK=28, Attack=28, DEF=14, Defense=14, XP=650, Gold=550, Range=14, Speed=12, Aggro=42, Leash=50, Boss=true, Drop="SunshardCore"},
    OrderCyborg = {Name="ORDER • LÕI LƯỢNG TỬ TỐI THƯỢNG", Level=18, VisualAsset="OrderCyborg", Element="Frost", HP=4200, ATK=52, Attack=52, DEF=24, Defense=24, XP=1500, Gold=1350, Range=18, Speed=13, Aggro=50, Leash=60, Boss=true, Drop="CoreEssence"},
    OrderCyborgBoss = {Name="ORDER • LÕI LƯỢNG TỬ TỐI THƯỢNG", Level=18, VisualAsset="OrderCyborgBoss", Element="Frost", HP=4200, ATK=52, Attack=52, DEF=24, Defense=24, XP=1500, Gold=1350, Range=18, Speed=13, Aggro=50, Leash=60, Boss=true, Drop="CoreEssence"},
    SkySeaBeast = {Name="SKY SEA BEAST • THỦY QUÁI BIỂN MÂY", Level=19, VisualAsset="SkySeaBeast", Element="Frost", HP=4800, ATK=55, Attack=55, DEF=24, Defense=24, XP=1800, Gold=2200, Range=26, Speed=8, Aggro=70, Leash=90, Boss=true, Drop="CoreEssence"},
    SoulReaperRift = {Name="SOUL REAPER • TỬ THẦN HƯ KHÔNG", Level=28, VisualAsset="SoulReaperRift", Element="Void", HP=7600, ATK=82, Attack=82, DEF=34, Defense=34, XP=3100, Gold=2600, Range=20, Speed=13, Aggro=55, Leash=65, Boss=true, Drop="CoreEssence"},
    AbyssalDragonHybrid = {Name="ABYSSAL DRAGON HYBRID • LONG NHÂN HƯ KHÔNG", Level=29, VisualAsset="AbyssalDragonHybrid", Element="Void", HP=8200, ATK=85, Attack=85, DEF=35, Defense=35, XP=3400, Gold=3200, Range=22, Speed=12, Aggro=65, Leash=80, Boss=true, Drop="CoreEssence"},
    AbyssalLeviathan = {Name="ABYSSAL LEVIATHAN • THỦY TỔ HƯ KHÔNG", Level=30, VisualAsset="AbyssalLeviathan", Element="Void", HP=9000, ATK=88, Attack=88, DEF=36, Defense=36, XP=4000, Gold=4500, Range=28, Speed=9, Aggro=80, Leash=100, Boss=true, Drop="CoreEssence"},
    AbyssalSovereignDragon = {Name="ABYSSAL SOVEREIGN DRAGON • THÁI CỔ LONG HOÀNG", Level=32, VisualAsset="AbyssalSovereignDragon", Element="Void", HP=10500, ATK=94, Attack=94, DEF=38, Defense=38, XP=4500, Gold=5500, Range=28, Speed=10, Aggro=75, Leash=90, Boss=true, Drop="CoreEssence"},

    -- Regional Island & Expansion Realm Bosses (Lv. 4 - 100)
    SkyHubWatchCommander = {Name="COMMANDER VALEN • THỦ VỆ SÂN TẬP", Level=4, VisualAsset="SunshardRoyalGuard", Element="Sky", HP=750, ATK=18, Attack=18, DEF=10, Defense=10, XP=320, Gold=250, Range=11, Speed=11, Aggro=36, Leash=42, Boss=true, Drop="SunshardCore"},
    ShrineGuardianBoss = {Name="SHRINE WARDEN ORION • HỘ VỆ ĐIỆN THỜ", Level=6, VisualAsset="SunshardTemplar", Element="Sky", HP=980, ATK=21, Attack=21, DEF=11, Defense=11, XP=380, Gold=300, Range=11, Speed=11, Aggro=36, Leash=42, Boss=true, Drop="SunshardCore"},
    AetherArchonBoss = {Name="ARCHON HELIOS • LINH VỆ AETHER", Level=8, VisualAsset="GoldenKnight", Element="Sky", HP=1250, ATK=24, Attack=24, DEF=12, Defense=12, XP=450, Gold=360, Range=12, Speed=11, Aggro=36, Leash=42, Boss=true, Drop="SunshardCore"},
    SolarHighPriestBoss = {Name="HIGH PRIEST SOLARIUS • ĐẠI TƯ TẾ THÁI DƯƠNG", Level=10, VisualAsset="SolarTitanBuddha", Element="Sky", HP=2100, ATK=31, Attack=31, DEF=15, Defense=15, XP=850, Gold=700, Range=16, Speed=11, Aggro=45, Leash=55, Boss=true, Drop="CoreEssence"},
    CyberSyndicateBoss = {Name="OVERLORD KRON • TRÙM HẮC THỊ CYBERPORT", Level=14, VisualAsset="CyberMercenary", Element="Frost", HP=3200, ATK=44, Attack=44, DEF=20, Defense=20, XP=1100, Gold=950, Range=18, Speed=13, Aggro=45, Leash=55, Boss=true, Drop="CoreEssence"},
    PermafrostWardenBoss = {Name="GENERAL BOREAS • THỐNG LĨNH PHÁO ĐÀI BĂNG", Level=16, VisualAsset="CryoVanguard", Element="Frost", HP=3600, ATK=48, Attack=48, DEF=22, Defense=22, XP=1250, Gold=1100, Range=14, Speed=12, Aggro=45, Leash=55, Boss=true, Drop="CoreEssence"},
    VoidCastellanBoss = {Name="LORD MALAKOR • LÃNH CHÚA DINH THỰ HƯ KHÔNG", Level=25, VisualAsset="AbyssalDreadknight", Element="Void", HP=6400, ATK=74, Attack=74, DEF=30, Defense=30, XP=2500, Gold=2000, Range=16, Speed=13, Aggro=52, Leash=65, Boss=true, Drop="CoreEssence"},
    UmbralArchfiendBoss = {Name="ARCHFIEND ZERATH • KIẾM MA TINH THỂ ĐEN", Level=27, VisualAsset="AbyssalDragonHybrid", Element="Void", HP=7000, ATK=78, Attack=78, DEF=32, Defense=32, XP=2800, Gold=2300, Range=18, Speed=13, Aggro=52, Leash=65, Boss=true, Drop="CoreEssence"},
    Sylvaris = {Name="SYLVARIS • ĐẠI CỔ THỤ HOÀNG", Level=40, VisualAsset="AbyssalDragonHybrid", Element="Sky", HP=14500, ATK=110, Attack=110, DEF=42, Defense=42, XP=6500, Gold=6000, Range=22, Speed=12, Aggro=65, Leash=80, Boss=true, Drop="CoreEssence"},
    Ignivar = {Name="IGNIVAR • TITAN LÒ RÈN LỬA", Level=52, VisualAsset="SolarTitanBuddha", Element="Sky", HP=21000, ATK=135, Attack=135, DEF=50, Defense=50, XP=9500, Gold=8500, Range=24, Speed=12, Aggro=65, Leash=80, Boss=true, Drop="CoreEssence"},
    Nerith = {Name="NERITH • THỦY HOÀNG VỰC SÂU", Level=65, VisualAsset="AbyssalLeviathan", Element="Frost", HP=29000, ATK=165, Attack=165, DEF=58, Defense=58, XP=13500, Gold=12000, Range=28, Speed=11, Aggro=75, Leash=90, Boss=true, Drop="CoreEssence"},
    Aion = {Name="AION • PHÁP VƯƠNG THỜI GIAN", Level=80, VisualAsset="OrderCyborgBoss", Element="Sky", HP=42000, ATK=200, Attack=200, DEF=68, Defense=68, XP=19000, Gold=18000, Range=24, Speed=13, Aggro=70, Leash=85, Boss=true, Drop="CoreEssence"},
    Veyr = {Name="VEYR • ĐẤNG KIẾN TẠO ĐẦU TIÊN", Level=100, VisualAsset="AbyssalSovereignDragon", Element="Void", HP=65000, ATK=250, Attack=250, DEF=80, Defense=80, XP=32000, Gold=30000, Range=30, Speed=12, Aggro=80, Leash=95, Boss=true, Drop="CoreEssence"},
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
            Z = {Key="Z", Name="Sky Thrust • Đâm Xung Kích", Mastery=1, Cooldown=5, Cost=10, Range=18, Multiplier=2.0, Break=18, Element="Sky"},
            X = {Key="X", Name="Crescent Slash • Bán Nguyệt Trảm", Mastery=20, Cooldown=8, Cost=14, Range=22, Multiplier=2.5, Break=24, Element="Sky"},
        },
    },
    starter_daggers = {
        Id = "starter_daggers", Name = "Song đao Skyborn", Rarity = "Common", ATK = 12, CritRate = 4, CritDmg = 12, Element = "Lightning",
        Desc = "Cặp song đao nhẹ giúp lướt nhanh và ra đòn liên hoàn.",
        Moves = {
            Z = {Key="Z", Name="Twin Cut • Song Đao Liên Trảm", Mastery=1, Cooldown=4.5, Cost=10, Range=16, Multiplier=2.1, Break=18, Element="Lightning"},
            X = {Key="X", Name="Spinning Blades • Xoáy Đao Lôi Điện", Mastery=20, Cooldown=8, Cost=14, Range=20, Multiplier=2.6, Break=24, Element="Lightning"},
        },
    },
    starter_staff = {
        Id = "starter_staff", Name = "Trượng Arcane", Rarity = "Common", ATK = 12, CritRate = 3, CritDmg = 12, Element = "Frost",
        Desc = "Quyền trượng dẫn truyền ma lực cổ ngữ cơ bản.",
        Moves = {
            Z = {Key="Z", Name="Arcane Pulse • Xung Ma Lực", Mastery=1, Cooldown=5, Cost=10, Range=26, Multiplier=2.1, Break=18, Element="Frost"},
            X = {Key="X", Name="Rune Burst • Bùng Nổ Cổ Ngữ", Mastery=20, Cooldown=8.5, Cost=14, Range=28, Multiplier=2.6, Break=24, Element="Frost"},
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
        Id = "noxar_abyssal_greatsword", Name = "Noxar's Abyssal Greatsword • Hắc Kiếm Hư Không", Rarity = "Mythic", ATK = 210, CritRate = 28, CritDmg = 55, Element = "Void",
        Desc = "Đại kiếm tối thượng của Hư Không Vương Noxar, chém rách không gian.",
        Moves = {
            Z = {Key="Z", Name="Abyssal Cleave • Hắc Kiếm Xé Không Gian", Mastery=200, Cooldown=5.5, Cost=14, Range=34, Multiplier=4.2, Break=48, Element="Void"},
            X = {Key="X", Name="Void Sovereign's Decree • Sắc Lệnh Hư Không Vương", Mastery=375, Cooldown=11.5, Cost=24, Range=40, Multiplier=5.6, Break=64, Element="Void"},
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
            Z = {Key="Z", Name="Armor Piercing Shot • Đạn Xuyên Giáp", Mastery=1, Cooldown=5, Cost=8, Range=40, Multiplier=2.2, Break=22, Element="Sky"},
            X = {Key="X", Name="Scatter Volley • Loạt Đạn Chùm", Mastery=25, Cooldown=8.5, Cost=12, Range=34, Multiplier=2.8, Break=28, Element="Sky"},
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

-- Sequential Main Storyline Quests (Q01 -> Q14) across all 8 Realms.
-- Reward XP + Mob XP covers every following level gate smoothly without mandatory grinding.
C.Quests = {
    -- CHƯƠNG 1: GOLDEN SKY (Lv. 1 - 10)
    {Id="Q01", Name="Lời Gọi Skyborn", Realm="GoldenSky", Level=1, XP=350, Gold=150, CoreShards=60,
        Text="Các quần đảo bầu trời đang mất dần năng lượng. Hãy tiêu diệt 3 Training Drone tại sân tập Sky Hub để làm quen với vũ khí.",
        Objectives={{Kind="Kill", Target="TrainingDrone", Count=3, Label="Hạ gục Training Drone"}}},
    {Id="Q02", Name="Khôi Phục Cầu Năng Lượng", Realm="GoldenSky", Level=2, XP=650, Gold=250, CoreShards=80,
        Text="Năng lượng cầu sang Quảng Trường Lumen đã cạn. Hãy đánh bại 3 Corrupted Guard và bật 3 Trạm Năng Lượng.",
        Objectives={{Kind="Kill", Target="CorruptedGuard", Count=3, Label="Hạ gục Corrupted Guard"},
        {Kind="Interact", Target="Station1", Count=1, Label="Bật Trạm 1"}, {Kind="Interact", Target="Station2", Count=1, Label="Bật Trạm 2"}, {Kind="Interact", Target="Station3", Count=1, Label="Bật Trạm 3"}}},
    {Id="Q03", Name="Giải Cứu Quảng Trường Lumen", Realm="GoldenSky", Level=4, XP=1100, Gold=400, CoreShards=120,
        Text="Cầu ánh sáng đã mở. Hãy giải cứu 3 người dân bị mắc kẹt và đánh bại Tinh Anh Golden Knight tại quảng trường.",
        Objectives={{Kind="Interact", Target="Citizen1", Count=1, Label="Cứu người dân 1"}, {Kind="Interact", Target="Citizen2", Count=1, Label="Cứu người dân 2"}, {Kind="Interact", Target="Citizen3", Count=1, Label="Cứu người dân 3"}, {Kind="Kill", Target="GoldenKnight", Count=1, Label="Hạ gục Golden Knight"}}},
    {Id="Q04", Name="Chìa Khóa Tháp Ánh Sáng", Realm="GoldenSky", Level=6, XP=1600, Gold=550, CoreShards=150,
        Text="Tiến tới Tiền Điện Aureon, kích hoạt 2 Công Tắc Cổ Ngữ và hạ 3 Light Archer để nhận Chìa Khóa Đấu Trường.",
        Objectives={{Kind="Interact", Target="Switch1", Count=1, Label="Bật Công tắc 1"}, {Kind="Interact", Target="Switch2", Count=1, Label="Bật Công tắc 2"}, {Kind="Kill", Target="LightArcher", Count=3, Label="Hạ gục Light Archer"}}},
    {Id="Q05", Name="Trái Tim Ánh Sáng (Boss Chương 1)", Realm="GoldenSky", Level=8, XP=2400, Gold=1000, CoreShards=250,
        Text="Tiến vào Đấu Trường Tháp Ánh Sáng và đánh bại AUREON SENTINEL. Phá hủy 2 trụ năng lượng khi Boss bật khiên để thu hồi Core of Light!",
        Objectives={{Kind="Kill", Target="AureonSentinel", Count=1, Label="Đánh bại Boss Aureon Sentinel"}}},

    -- CHƯƠNG 2: FROZEN CYBER (Lv. 10 - 20)
    {Id="Q06", Name="Đột Nhập Thành Trì Băng Giá", Realm="FrozenCyber", Level=10, XP=3200, Gold=1400, CoreShards=300,
        Text="Cổng dịch chuyển Frozen Cyber đã mở! Hãy tiêu diệt 3 Frost Automaton và 2 Cryo Vanguard để mở đường vào trung tâm.",
        Objectives={{Kind="Kill", Target="FrostDrone", Count=3, Label="Hạ gục Frost Automaton"}, {Kind="Kill", Target="CryoGuard", Count=2, Label="Hạ gục Cryo Vanguard"}}},
    {Id="Q07", Name="Lõi Lượng Tử Nổi Loạn", Realm="FrozenCyber", Level=13, XP=4200, Gold=1800, CoreShards=380,
        Text="Tại Phòng Thí Nghiệm Lượng Tử (hoặc vùng biển mây Sea 2), hãy đánh bại ORDER • Lõi Lượng Tử hoặc Thủy Quái Sky Sea Beast.",
        Objectives={{Kind="Kill", Target="OrderCyborg", Count=1, Label="Đánh bại Order Cyborg / Sky Sea Beast"}}},
    {Id="Q08", Name="Thực Thể Băng Giá Vĩnh Cửu (Boss Chương 2)", Realm="FrozenCyber", Level=16, XP=5800, Gold=2600, CoreShards=500,
        Text="Tiến vào Đấu Trường Băng Giá và tiêu diệt CRYON PRIME. Phá 3 Cột Băng Vĩnh Cửu khi Boss triệu hồi bão tuyết!",
        Objectives={{Kind="Kill", Target="CryonPrime", Count=1, Label="Đánh bại Boss Cryon Prime"}}},

    -- CHƯƠNG 3: SHADOW REALM (Lv. 20 - 30)
    {Id="Q09", Name="Quân Đoàn Bóng Đêm", Realm="ShadowRealm", Level=19, XP=7500, Gold=3500, CoreShards=600,
        Text="Bước qua cổng Hư Không vào Shadow Realm. Hãy thanh trừng 3 Void Marauder và 2 Kỵ Sĩ Hắc Ám Abyssal Dreadknight.",
        Objectives={{Kind="Kill", Target="VoidPirate", Count=3, Label="Hạ gục Void Marauder"}, {Kind="Kill", Target="AbyssalKnight", Count=2, Label="Hạ gục Abyssal Dreadknight"}}},
    {Id="Q10", Name="Săn Lùng Thủy Tổ Hư Không", Realm="ShadowRealm", Level=23, XP=9500, Gold=5000, CoreShards=750,
        Text="Tiến vào Vực Thẳm Leviathan (hoặc Điện Thờ Lõi) tại Shadow Realm và đánh bại Thủy Tổ ABYSSAL LEVIATHAN hoặc SOUL REAPER.",
        Objectives={{Kind="Kill", Target="AbyssalLeviathan", Count=1, Label="Đánh bại Abyssal Leviathan / Soul Reaper"}}},
    {Id="Q11", Name="Chúa Tể Hư Không (Boss Chương 3)", Realm="ShadowRealm", Level=26, XP=12500, Gold=7000, CoreShards=1000,
        Text="Đối mặt với NOXAR • THE VOID SOVEREIGN tại Đấu Trường Hắc Tinh. Phá hủy Void Singularity để đoạt lấy Song Kiếm Huyền Thoại!",
        Objectives={{Kind="Kill", Target="Noxar", Count=1, Label="Đánh bại Boss Noxar • Void Sovereign"}}},

    -- CHƯƠNG 4 - 5: CÁC CÕI GIỚI THƯỢNG CỔ & CHUNG CUỘC (Lv. 30 - 100)
    {Id="Q12", Name="Thức Tỉnh Nguyên Tố Cổ Đại (Chương 4)", Realm="VerdantCrown", Level=30, XP=18000, Gold=10000, CoreShards=1400,
        Text="Dịch chuyển tới Verdant Crown và Emberforge Wastes để chinh phục Đại Cổ Thụ SYLVARIS cùng Titan Lửa IGNIVAR.",
        Objectives={{Kind="Kill", Target="Sylvaris", Count=1, Label="Đánh bại Sylvaris (Verdant Crown)"}, {Kind="Kill", Target="Ignivar", Count=1, Label="Đánh bại Ignivar (Emberforge Wastes)"}}},
    {Id="Q13", Name="Vượt Qua Dòng Chảy Thời Gian (Chương 5)", Realm="ChronosBastion", Level=40, XP=28000, Gold=16000, CoreShards=2000,
        Text="Tiến vào Abyssal Tides và Chronos Bastion để đánh bại Thủy Hoàng NERITH và Pháp Vương Thời Gian AION.",
        Objectives={{Kind="Kill", Target="Nerith", Count=1, Label="Đánh bại Nerith (Abyssal Tides)"}, {Kind="Kill", Target="Aion", Count=1, Label="Đánh bại Aion (Chronos Bastion)"}}},
    {Id="Q14", Name="Đấng Kiến Tạo Đầu Tiên (Chung Cuộc)", Realm="VeilsEnd", Level=55, XP=50000, Gold=30000, CoreShards=3500,
        Text="Bước lên Đỉnh Phán Quyết tại Veil's End và đánh bại Boss tối thượng VEYR • ĐẤNG KIẾN TẠO ĐẦU TIÊN để thống nhất bầu trời!",
        Objectives={{Kind="Kill", Target="Veyr", Count=1, Label="Đánh bại Final Boss Veyr (Veil's End)"}}},
}

return C
