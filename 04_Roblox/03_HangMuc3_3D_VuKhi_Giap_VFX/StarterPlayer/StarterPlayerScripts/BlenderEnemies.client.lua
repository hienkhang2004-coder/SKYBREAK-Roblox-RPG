-- Actual Blender handoff mesh, deep 3D regional mob upgrades, boss FX, and 3D AI companions.
local Renderer = require(game.ReplicatedStorage:WaitForChild('DelegatedV5Renderer'))
local Sources = game.ReplicatedStorage:WaitForChild('DelegatedV5Sources')
local Run = game:GetService('RunService')
local folder = workspace:WaitForChild('ActiveEnemies')
local bossesFolder = workspace:WaitForChild('ActiveBosses', 15)

local actors = {}
local pending = {}
local templates = {}
local motions = {}
local pillars = {}
local voidfx = {}
local companions = {}
local pendingCompanions = {}
local npcs = {}
local pendingNPCs = {}
local activeShips = {}
local pendingShips = {}

local SUPPORTED = {
    -- Hero Classes & Outfits
    SkyGuardian = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    SkyGuardianFemale = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    Male_SkyGuardian = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    Female_SkyGuardian = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    Male_Novice = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    Female_Novice = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    Male_Adventurer = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    Female_Adventurer = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    ThunderStriker = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    ThunderStrikerFemale = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    ArcaneMage = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },

    -- Mobs & Drones
    TrainingDrone = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    DPSTrainingDummy = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    SkyPirate = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    CorruptedGuard = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    LightArcher = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    GoldenKnight = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    SunshardTemplar = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    SunshardRoyalGuard = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    FrostDrone = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    MechaDrone = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    FrostAutomaton = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    CryoGuard = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    CryoVanguard = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    GlacialMarksman = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    GlacialSniper = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    ArcticCorsair = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    CyberMercenary = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    VoidRaider = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    VoidMarauder = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    UmbralBowman = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    UmbralRanger = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    AbyssalKnight = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    AbyssalDreadknight = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    ShadowSpecter = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    TerrorSkyShark = { Idle = 'Idle', Run = 'Swim', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },

    -- Bosses, Sea Beasts, Dragons & Transformations
    AureonSentinel = { Idle = 'Idle', Run = 'Idle', Attack = 'DivineSlash', Heavy = 'Ascend', Hit = 'Idle', Death = 'Ascend' },
    CryonPrime = { Idle = 'Idle', Run = 'CombatReady', Attack = 'IceSlash', Heavy = 'Smash', Hit = 'HitReact', Death = 'Death' },
    CryonPillar = { Idle = 'Cryon_Hover', Run = 'Cryon_Hover', Attack = 'Cryon_Rise', Heavy = 'Cryon_Rise', Hit = 'Cryon_Hover', Death = 'Cryon_Collapse' },
    EnergyPylon = { Idle = 'Cryon_Hover', Run = 'Cryon_Hover', Attack = 'Cryon_Rise', Heavy = 'Cryon_Rise', Hit = 'Cryon_Hover', Death = 'Cryon_Collapse' },
    Noxar = { Idle = 'Idle', Run = 'CombatReady', Attack = 'VoidSlash', Heavy = 'HeavyDown', Hit = 'HitReact', Death = 'Death' },
    NoxarVoidFX = { Idle = 'Noxar_Phase2Awaken', Run = 'Noxar_Phase2Awaken', Attack = 'Noxar_Phase3Judgement', Heavy = 'Noxar_Phase3Judgement', Hit = 'Noxar_Phase2Awaken', Death = 'Noxar_Phase3Judgement' },
    AbyssalLeviathan = { Idle = 'Idle', Run = 'Swim', Attack = 'Attack', Heavy = 'Roar', Hit = 'HitReact', Death = 'Death' },
    SkySeaBeast = { Idle = 'Idle', Run = 'Swim', Attack = 'Attack', Heavy = 'HydroBeam', Hit = 'HitReact', Death = 'Death' },
    AbyssalSovereignDragon = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    AbyssalDragonHybrid = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    SolarTitanBuddha = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    PirateCaptainVance = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    VanceBoss = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    OrderCyborg = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    OrderCyborgBoss = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    SoulReaperRift = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    SkyHubWatchCommander = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    ShrineGuardianBoss = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    AetherArchonBoss = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    SolarHighPriestBoss = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    CyberSyndicateBoss = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    PermafrostWardenBoss = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    VoidCastellanBoss = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    UmbralArchfiendBoss = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    Sylvaris = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    Ignivar = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    Nerith = { Idle = 'Idle', Run = 'Swim', Attack = 'Attack', Heavy = 'Roar', Hit = 'HitReact', Death = 'Death' },
    Aion = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },
    Veyr = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'HitReact', Death = 'Death' },

    -- Hub NPCs
    Lyra = { Idle = 'Idle', Run = 'Idle', Attack = 'Wave', Heavy = 'Talk', Hit = 'Wave', Death = 'Idle' },
    Kael = { Idle = 'Idle', Run = 'Idle', Attack = 'Hammer', Heavy = 'Wave', Hit = 'Wave', Death = 'Idle' },
    Chronos = { Idle = 'Idle', Run = 'Idle', Attack = 'Cast', Heavy = 'Wave', Hit = 'Wave', Death = 'Idle' },
    DrVega = { Idle = 'Idle', Run = 'Idle', Attack = 'Cast', Heavy = 'Wave', Hit = 'Wave', Death = 'Idle' },
    Zioles = { Idle = 'Idle', Run = 'Idle', Attack = 'Cast', Heavy = 'Wave', Hit = 'Wave', Death = 'Idle' },
    ZiolesGachaNPC = { Idle = 'Idle', Run = 'Idle', Attack = 'Cast', Heavy = 'Wave', Hit = 'Wave', Death = 'Idle' },
    AncientMonk = { Idle = 'Idle', Run = 'Idle', Attack = 'Meditate', Heavy = 'Wave', Hit = 'Wave', Death = 'Idle' },
    AncientMonkNPC = { Idle = 'Idle', Run = 'Idle', Attack = 'Meditate', Heavy = 'Wave', Hit = 'Wave', Death = 'Idle' },
    SkyShipwright = { Idle = 'Idle', Run = 'Idle', Attack = 'Hammer', Heavy = 'Wave', Hit = 'Wave', Death = 'Idle' },
    ShipwrightNPC = { Idle = 'Idle', Run = 'Idle', Attack = 'Hammer', Heavy = 'Wave', Hit = 'Wave', Death = 'Idle' },
    SkyShipwrightNPC = { Idle = 'Idle', Run = 'Idle', Attack = 'Hammer', Heavy = 'Wave', Hit = 'Wave', Death = 'Idle' },

    -- Sky Ships, Shrines, Forge Workstation & Mythic Collections (Animated)
    CelestialAetherGalleon = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'Idle', Death = 'Idle', Skill = 'ElementalSurge', Kata = 'HeroicKata', Ultimate = 'UltimateAwakening' },
    CelestialBrigantine = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'Idle', Death = 'Idle', Skill = 'ElementalSurge', Kata = 'HeroicKata', Ultimate = 'UltimateAwakening' },
    CyberEnforcerShip = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'Idle', Death = 'Idle', Skill = 'ElementalSurge', Kata = 'HeroicKata', Ultimate = 'UltimateAwakening' },
    CyberEnforcer = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'Idle', Death = 'Idle', Skill = 'ElementalSurge', Kata = 'HeroicKata', Ultimate = 'UltimateAwakening' },
    LeviathanHunterShip = { Idle = 'Idle', Run = 'Run', Attack = 'Attack', Heavy = 'Heavy', Hit = 'Idle', Death = 'Idle', Skill = 'ElementalSurge', Kata = 'HeroicKata', Ultimate = 'UltimateAwakening' },
    AetherFruitsCollection1 = { Idle = 'Idle', Run = 'Idle', Attack = 'ElementalSurge', Heavy = 'UltimateAwakening', Hit = 'HeroicKata', Death = 'Idle' },
    AetherFruitsCollection2 = { Idle = 'Idle', Run = 'Idle', Attack = 'ElementalSurge', Heavy = 'UltimateAwakening', Hit = 'HeroicKata', Death = 'Idle' },
    AncientAetherFruitTrees = { Idle = 'WorldIdle_Loop', Run = 'WorldIdle_Loop', Attack = 'ElementalPulse', Heavy = 'CataclysmAwakening', Hit = 'CrystalResonance', Death = 'WorldIdle_Loop' },
    MythicalWeaponsSet = { Idle = 'Idle', Run = 'Idle', Attack = 'ElementalSurge', Heavy = 'UltimateAwakening', Hit = 'HeroicKata', Death = 'Idle' },
    RaceV4WingsSet = { Idle = 'Idle', Run = 'Idle', Attack = 'ElementalSurge', Heavy = 'UltimateAwakening', Hit = 'HeroicKata', Death = 'Idle' },
    KaelWorkstation = { Idle = 'WorldIdle_Loop', Run = 'WorldIdle_Loop', Attack = 'ElementalPulse', Heavy = 'CataclysmAwakening', Hit = 'AstrolabeSpin', Death = 'WorldIdle_Loop' },
    ZiolesGachaShrine = { Idle = 'WorldIdle_Loop', Run = 'WorldIdle_Loop', Attack = 'PortalSurge', Heavy = 'CataclysmAwakening', Hit = 'AstrolabeSpin', Death = 'WorldIdle_Loop' },
    AetherShrinesAndRaidConsole = { Idle = 'WorldIdle_Loop', Run = 'WorldIdle_Loop', Attack = 'PortalSurge', Heavy = 'CataclysmAwakening', Hit = 'CrystalResonance', Death = 'WorldIdle_Loop' },
    FrozenPortal = { Idle = 'WorldIdle_Loop', Run = 'PortalSurge', Attack = 'PortalSurge', Heavy = 'CataclysmAwakening', Hit = 'ElementalPulse', Death = 'WorldIdle_Loop' },
    ShadowPortal = { Idle = 'WorldIdle_Loop', Run = 'PortalSurge', Attack = 'PortalSurge', Heavy = 'CataclysmAwakening', Hit = 'ElementalPulse', Death = 'WorldIdle_Loop' },
    Fruit_GaleCore = { Idle = 'Idle', Run = 'Idle', Attack = 'ElementalSurge', Heavy = 'UltimateAwakening', Hit = 'HeroicKata', Death = 'Idle' },
    Fruit_SandstoneCore = { Idle = 'Idle', Run = 'Idle', Attack = 'ElementalSurge', Heavy = 'UltimateAwakening', Hit = 'HeroicKata', Death = 'Idle' },
    Fruit_SolarFlameCore = { Idle = 'Idle', Run = 'Idle', Attack = 'ElementalSurge', Heavy = 'UltimateAwakening', Hit = 'HeroicKata', Death = 'Idle' },
    Fruit_GlacierIceCore = { Idle = 'Idle', Run = 'Idle', Attack = 'ElementalSurge', Heavy = 'UltimateAwakening', Hit = 'HeroicKata', Death = 'Idle' },
    Fruit_CelestialLightCore = { Idle = 'Idle', Run = 'Idle', Attack = 'ElementalSurge', Heavy = 'UltimateAwakening', Hit = 'HeroicKata', Death = 'Idle' },
    Fruit_StarforgedMagmaCore = { Idle = 'Idle', Run = 'Idle', Attack = 'ElementalSurge', Heavy = 'UltimateAwakening', Hit = 'HeroicKata', Death = 'Idle' },
    Fruit_ThunderRumbleCore = { Idle = 'Idle', Run = 'Idle', Attack = 'ElementalSurge', Heavy = 'UltimateAwakening', Hit = 'HeroicKata', Death = 'Idle' },
    Fruit_AstralGravityCore = { Idle = 'Idle', Run = 'Idle', Attack = 'ElementalSurge', Heavy = 'UltimateAwakening', Hit = 'HeroicKata', Death = 'Idle' },
    Fruit_DimensionalPortalCore = { Idle = 'Idle', Run = 'Idle', Attack = 'ElementalSurge', Heavy = 'UltimateAwakening', Hit = 'HeroicKata', Death = 'Idle' },
    Fruit_SolarTitanCore = { Idle = 'Idle', Run = 'Idle', Attack = 'ElementalSurge', Heavy = 'UltimateAwakening', Hit = 'HeroicKata', Death = 'Idle' },
    Fruit_AetherflowCore = { Idle = 'Idle', Run = 'Idle', Attack = 'ElementalSurge', Heavy = 'UltimateAwakening', Hit = 'HeroicKata', Death = 'Idle' },
    Fruit_AbyssalSovereignCore = { Idle = 'Idle', Run = 'Idle', Attack = 'ElementalSurge', Heavy = 'UltimateAwakening', Hit = 'HeroicKata', Death = 'Idle' },
}

local DEFAULT_VISUAL_ASSET = {
    TrainingDrone = 'TrainingDrone',
    DPSTrainingDummy = 'TrainingDrone',
    FrostDrone = 'MechaDrone',
    MechaDrone = 'MechaDrone',
    FrostAutomaton = 'FrostAutomaton',
    SkyPirate = 'SkyPirate',
    VoidPirate = 'VoidRaider',
    VoidRaider = 'VoidRaider',
    VoidMarauder = 'VoidMarauder',
    CorruptedGuard = 'CorruptedGuard',
    CryoGuard = 'CryoVanguard',
    CryoVanguard = 'CryoVanguard',
    LightArcher = 'LightArcher',
    CyberArcher = 'GlacialSniper',
    GlacialMarksman = 'GlacialSniper',
    GlacialSniper = 'GlacialSniper',
    ShadowArcher = 'UmbralRanger',
    UmbralBowman = 'UmbralRanger',
    UmbralRanger = 'UmbralRanger',
    GoldenKnight = 'GoldenKnight',
    AbyssalKnight = 'AbyssalDreadknight',
    AbyssalDreadknight = 'AbyssalDreadknight',
    SunshardTemplar = 'SunshardTemplar',
    SunshardRoyalGuard = 'SunshardRoyalGuard',
    ArcticCorsair = 'ArcticCorsair',
    CyberMercenary = 'CyberMercenary',
    ShadowSpecter = 'ShadowSpecter',
    TerrorSkyShark = 'TerrorSkyShark',
    AureonSentinel = 'AureonSentinel',
    CryonPrime = 'CryonPrime',
    CryonPillar = 'CryonPillar',
    EnergyPylon = 'CryonPillar',
    Noxar = 'Noxar',
    NoxarVoidFX = 'NoxarVoidFX',
    AbyssalLeviathan = 'AbyssalLeviathan',
    SkySeaBeast = 'SkySeaBeast',
    AbyssalSovereignDragon = 'AbyssalSovereignDragon',
    AbyssalDragonHybrid = 'AbyssalDragonHybrid',
    SolarTitanBuddha = 'SolarTitanBuddha',
    PirateCaptainVance = 'PirateCaptainVance',
    VanceBoss = 'VanceBoss',
    OrderCyborg = 'OrderCyborg',
    OrderCyborgBoss = 'OrderCyborgBoss',
    SoulReaperRift = 'SoulReaperRift',
    SkyHubWatchCommander = 'SunshardRoyalGuard',
    ShrineGuardianBoss = 'SunshardTemplar',
    AetherArchonBoss = 'GoldenKnight',
    SolarHighPriestBoss = 'SolarTitanBuddha',
    CyberSyndicateBoss = 'CyberMercenary',
    PermafrostWardenBoss = 'CryoVanguard',
    VoidCastellanBoss = 'AbyssalDreadknight',
    UmbralArchfiendBoss = 'AbyssalDragonHybrid',
    Sylvaris = 'AbyssalDragonHybrid',
    Ignivar = 'SolarTitanBuddha',
    Nerith = 'AbyssalLeviathan',
    Aion = 'OrderCyborgBoss',
    Veyr = 'AbyssalSovereignDragon',
    Lyra = 'Lyra',
    Kael = 'Kael',
    Chronos = 'Chronos',
    DrVega = 'DrVega',
    Zioles = 'Zioles',
    ZiolesGachaNPC = 'ZiolesGachaNPC',
    AncientMonk = 'AncientMonk',
    AncientMonkNPC = 'AncientMonkNPC',
    SkyShipwright = 'SkyShipwright',
    ShipwrightNPC = 'ShipwrightNPC',
    SkyShipwrightNPC = 'SkyShipwright',
    CelestialAetherGalleon = 'CelestialAetherGalleon',
    CelestialBrigantine = 'CelestialAetherGalleon',
    CyberEnforcerShip = 'CyberEnforcerShip',
    CyberEnforcer = 'CyberEnforcerShip',
    LeviathanHunterShip = 'LeviathanHunterShip',
    AetherFruitsCollection1 = 'AetherFruitsCollection1',
    AetherFruitsCollection2 = 'AetherFruitsCollection2',
    AncientAetherFruitTrees = 'AncientAetherFruitTrees',
    MythicalWeaponsSet = 'MythicalWeaponsSet',
    RaceV4WingsSet = 'RaceV4WingsSet',
    KaelWorkstation = 'KaelWorkstation',
    ZiolesGachaShrine = 'ZiolesGachaShrine',
    AetherShrinesAndRaidConsole = 'AetherShrinesAndRaidConsole',
    FrozenPortal = 'FrozenPortal',
    ShadowPortal = 'ShadowPortal',
}

local ASSET_ALIASES = {
    OrderCyborgBoss = 'OrderCyborg',
    OrderCyborg = 'OrderCyborgBoss',
    ZiolesGachaNPC = 'Zioles',
    Zioles = 'ZiolesGachaNPC',
    AncientMonkNPC = 'AncientMonk',
    AncientMonk = 'AncientMonkNPC',
    SkyShipwrightNPC = 'SkyShipwright',
    SkyShipwright = 'ShipwrightNPC',
    ShipwrightNPC = 'SkyShipwright',
    FrostDrone = 'MechaDrone',
    CryoGuard = 'CryoVanguard',
    CyberArcher = 'GlacialSniper',
    GlacialMarksman = 'GlacialSniper',
    VoidPirate = 'VoidRaider',
    ShadowArcher = 'UmbralRanger',
    UmbralBowman = 'UmbralRanger',
    AbyssalKnight = 'AbyssalDreadknight',
    PirateCaptainVance = 'VanceBoss',
    VanceBoss = 'PirateCaptainVance',
    EnergyPylon = 'CryonPillar',
}

local FALLBACK_VISUAL_ASSET = {
    FrostDrone = 'TrainingDrone',
    CryoGuard = 'CorruptedGuard',
    CyberArcher = 'LightArcher',
    GlacialMarksman = 'LightArcher',
    VoidPirate = 'SkyPirate',
    VoidRaider = 'SkyPirate',
    ShadowArcher = 'LightArcher',
    UmbralBowman = 'LightArcher',
    AbyssalKnight = 'GoldenKnight',
    SunshardTemplar = 'GoldenKnight',
    ArcticCorsair = 'SkyPirate',
    ShadowSpecter = 'SkyPirate',
    TerrorSkyShark = 'TrainingDrone',
    AbyssalLeviathan = 'Noxar',
    SkySeaBeast = 'CryonPrime',
    PirateCaptainVance = 'SkyPirate',
    OrderCyborg = 'CorruptedGuard',
    OrderCyborgBoss = 'CorruptedGuard',
    SoulReaperRift = 'GoldenKnight',
    Zioles = 'ArcaneMage',
    ZiolesGachaNPC = 'ArcaneMage',
    AncientMonk = 'GoldenKnight',
    AncientMonkNPC = 'GoldenKnight',
    SkyShipwright = 'SkyPirate',
    SkyShipwrightNPC = 'SkyPirate',
}

local ASSET_SCALES = {
    FrostDrone = 2.6,
    MechaDrone = 2.6,
    FrostAutomaton = 2.6,
    CryoGuard = 2.7,
    CryoVanguard = 2.7,
    GlacialMarksman = 2.6,
    GlacialSniper = 2.6,
    ArcticCorsair = 2.7,
    CyberMercenary = 2.7,
    VoidRaider = 2.7,
    VoidMarauder = 2.7,
    UmbralBowman = 2.6,
    UmbralRanger = 2.6,
    AbyssalKnight = 2.9,
    AbyssalDreadknight = 2.9,
    SunshardTemplar = 2.7,
    SunshardRoyalGuard = 2.7,
    ShadowSpecter = 2.75,
    TerrorSkyShark = 3.8,
    AureonSentinel = 1.9,
    Noxar = 1.45,
    CryonPrime = 1.45,
    CryonPillar = 1.15,
    EnergyPylon = 1.15,
    NoxarVoidFX = 0.85,
    AbyssalLeviathan = 5.5,
    SkySeaBeast = 4.8,
    AbyssalSovereignDragon = 3.6,
    AbyssalDragonHybrid = 3.2,
    SolarTitanBuddha = 3.8,
    PirateCaptainVance = 3.2,
    VanceBoss = 3.2,
    OrderCyborg = 3.8,
    OrderCyborgBoss = 3.8,
    SoulReaperRift = 4.0,
    SkyHubWatchCommander = 3.1,
    ShrineGuardianBoss = 3.1,
    AetherArchonBoss = 3.2,
    SolarHighPriestBoss = 3.6,
    CyberSyndicateBoss = 3.2,
    PermafrostWardenBoss = 3.3,
    VoidCastellanBoss = 3.4,
    UmbralArchfiendBoss = 3.4,
    Sylvaris = 3.8,
    Ignivar = 4.2,
    Nerith = 5.5,
    Aion = 4.0,
    Veyr = 4.2,
    Lyra = 2.7,
    Kael = 2.7,
    Chronos = 2.7,
    DrVega = 2.7,
    Zioles = 2.7,
    ZiolesGachaNPC = 2.7,
    AncientMonk = 2.8,
    AncientMonkNPC = 2.8,
    SkyShipwright = 2.7,
    ShipwrightNPC = 2.7,
    SkyShipwrightNPC = 2.7,
    CelestialAetherGalleon = 4.2,
    CyberEnforcerShip = 4.2,
    LeviathanHunterShip = 4.5,
    AetherFruitsCollection1 = 1.6,
    AetherFruitsCollection2 = 1.6,
    AncientAetherFruitTrees = 2.0,
    MythicalWeaponsSet = 1.6,
    RaceV4WingsSet = 1.6,
    KaelWorkstation = 1.45,
    ZiolesGachaShrine = 1.25,
    AetherShrinesAndRaidConsole = 1.25,
    FrozenPortal = 1.15,
    ShadowPortal = 1.15,
    Fruit_GaleCore = 1.35,
    Fruit_SandstoneCore = 1.35,
    Fruit_SolarFlameCore = 1.35,
    Fruit_GlacierIceCore = 1.35,
    Fruit_CelestialLightCore = 1.35,
    Fruit_StarforgedMagmaCore = 1.35,
    Fruit_ThunderRumbleCore = 1.35,
    Fruit_AstralGravityCore = 1.35,
    Fruit_DimensionalPortalCore = 1.35,
    Fruit_SolarTitanCore = 1.35,
    Fruit_AetherflowCore = 1.35,
    Fruit_AbyssalSovereignCore = 1.35,
}

local DEFAULT_ELEMENT = {
    SunshardTemplar = 'Sky',
    SunshardRoyalGuard = 'Sky',
    FrostDrone = 'Frost',
    MechaDrone = 'Frost',
    FrostAutomaton = 'Frost',
    CryoGuard = 'Frost',
    CryoVanguard = 'Frost',
    CyberArcher = 'Frost',
    GlacialMarksman = 'Frost',
    GlacialSniper = 'Frost',
    ArcticCorsair = 'Frost',
    CyberMercenary = 'Frost',
    CryonPrime = 'Frost',
    CryonPillar = 'Frost',
    SkySeaBeast = 'Frost',
    OrderCyborg = 'Frost',
    OrderCyborgBoss = 'Frost',
    VoidPirate = 'Void',
    VoidRaider = 'Void',
    VoidMarauder = 'Void',
    AbyssalKnight = 'Void',
    AbyssalDreadknight = 'Void',
    ShadowArcher = 'Void',
    UmbralBowman = 'Void',
    UmbralRanger = 'Void',
    ShadowSpecter = 'Void',
    TerrorSkyShark = 'Void',
    Noxar = 'Void',
    NoxarVoidFX = 'Void',
    AbyssalLeviathan = 'Void',
    AbyssalSovereignDragon = 'Void',
    AbyssalDragonHybrid = 'Void',
    SoulReaperRift = 'Void',
    PirateCaptainVance = 'Sky',
    VanceBoss = 'Sky',
    SolarTitanBuddha = 'Sky',
    SkyHubWatchCommander = 'Sky',
    ShrineGuardianBoss = 'Sky',
    AetherArchonBoss = 'Sky',
    SolarHighPriestBoss = 'Sky',
    CyberSyndicateBoss = 'Frost',
    PermafrostWardenBoss = 'Frost',
    VoidCastellanBoss = 'Void',
    UmbralArchfiendBoss = 'Void',
    Sylvaris = 'Sky',
    Ignivar = 'Sky',
    Nerith = 'Frost',
    Aion = 'Sky',
    Veyr = 'Void',
}

local COMPANION_DEFAULTS = {
    Kairo = 'Male_SkyGuardian',
    Lumen = 'ArcaneMage',
    Nyx = 'ThunderStrikerFemale',
}

local function enrichClips(assetName, clips)
    if not clips then
        return {}
    end
    local prefixes = {
        'TS_', 'Cryon_', 'Noxar_', 'GoldenKnight_', 'CorruptedGuard_', 'LightArcher_', 'SkyPirate_', 'TrainingDrone_',
        'FrostDrone_', 'CryoGuard_', 'GlacialMarksman_', 'VoidRaider_', 'UmbralBowman_', 'AbyssalKnight_',
        'SunshardTemplar_', 'ArcticCorsair_', 'ShadowSpecter_', 'TerrorSkyShark_',
        'AbyssalLeviathan_', 'SkySeaBeast_', 'PirateCaptainVance_', 'OrderCyborg_', 'OrderCyborgBoss_', 'SoulReaperRift_',
        'Zioles_', 'ZiolesGachaNPC_', 'AncientMonk_', 'AncientMonkNPC_', 'SkyShipwright_', 'SkyShipwrightNPC_',
        assetName .. '_'
    }
    local snapshot = {}
    for k, v in clips do
        snapshot[k] = v
    end
    for k, v in snapshot do
        for _, pre in ipairs(prefixes) do
            if not clips[pre .. k] then
                clips[pre .. k] = v
            end
        end
    end
    if clips.Swim and not clips.Run then
        clips.Run = clips.Swim
    elseif clips.Run and not clips.Swim then
        clips.Swim = clips.Run
    end
    if (clips.Roar or clips.HydroBeam) and not clips.Heavy then
        clips.Heavy = clips.Roar or clips.HydroBeam
    elseif clips.Heavy then
        clips.Roar = clips.Roar or clips.Heavy
        clips.HydroBeam = clips.HydroBeam or clips.Heavy
    end
    if clips.Talk and not clips.Wave then
        clips.Wave = clips.Talk
    elseif clips.Wave and not clips.Talk then
        clips.Talk = clips.Wave
    end
    if not clips.Cast and (clips.ElementalSurge or clips.Wave or clips.Attack or clips.Idle) then
        clips.Cast = clips.ElementalSurge or clips.Wave or clips.Attack or clips.Idle
    end
    if not clips.Meditate and (clips.HeroicKata or clips.Wave or clips.Idle) then
        clips.Meditate = clips.HeroicKata or clips.Wave or clips.Idle
    end
    if not clips.Hammer and (clips.HeroicKata or clips.Attack or clips.Wave or clips.Idle) then
        clips.Hammer = clips.HeroicKata or clips.Attack or clips.Wave or clips.Idle
    end
    if clips.WorldIdle_Loop and not clips.Idle then
        clips.Idle = clips.WorldIdle_Loop
        clips.Run = clips.WorldIdle_Loop
    end
    if clips.ElementalPulse and not clips.Attack then
        clips.Attack = clips.ElementalPulse
    end
    if clips.CataclysmAwakening and not clips.Heavy then
        clips.Heavy = clips.CataclysmAwakening
    end
    if clips.Hover and not clips.Idle then
        clips.Idle = clips.Hover
        clips.Run = clips.Hover
        clips.HitReact = clips.Hover
    end
    if clips.Rise and not clips.Attack then
        clips.Attack = clips.Rise
        clips.Heavy = clips.Rise
    end
    if clips.Collapse and not clips.Death then
        clips.Death = clips.Collapse
    end
    if clips.Phase2Awaken and not clips.Idle then
        clips.Idle = clips.Phase2Awaken
        clips.Run = clips.Phase2Awaken
        clips.HitReact = clips.Phase2Awaken
    end
    if clips.Phase3Judgement and not clips.Attack then
        clips.Attack = clips.Phase3Judgement
        clips.Heavy = clips.Phase3Judgement
        clips.Death = clips.Phase3Judgement
    end
    return clips
end

local function getClips(assetName, scale)
    local key = assetName .. ':' .. string.format('%.2f', scale)
    if motions[key] then
        return motions[key]
    end
    local raw = {}
    if Sources:FindFirstChild(assetName) and Sources[assetName]:FindFirstChild('Clips') then
        local ok, loaded = pcall(Renderer.Clips, assetName, scale)
        if ok and loaded then
            raw = loaded
        end
    end
    -- Kairo (Male_SkyGuardian) shares the exact 19-bone Shared19 armature with GoldenKnight!
    if next(raw) == nil and (assetName == 'Male_SkyGuardian' or assetName == 'Female_SkyGuardian') then
        if Sources:FindFirstChild('GoldenKnight') then
            local ok, gk = pcall(Renderer.Clips, 'GoldenKnight', scale)
            if ok and gk then
                raw = gk
            end
        end
    end
    motions[key] = enrichClips(assetName, raw)
    motions[assetName] = motions[key]
    return motions[key]
end

local function resolveClip(clips, map, key)
    if not clips then
        return nil
    end
    if clips[key] then
        return clips[key]
    end
    local mapped = map and map[key]
    if mapped and clips[mapped] then
        return clips[mapped]
    end
    if key == 'HitReact' and map and map.Hit and clips[map.Hit] then
        return clips[map.Hit]
    end
    local stripped = tostring(key)
        :gsub('^TS_', '')
        :gsub('^Cryon_', '')
        :gsub('^Noxar_', '')
        :gsub('^GoldenKnight_', '')
        :gsub('^CorruptedGuard_', '')
        :gsub('^LightArcher_', '')
        :gsub('^SkyPirate_', '')
        :gsub('^TrainingDrone_', '')
        :gsub('^FrostDrone_', '')
        :gsub('^CryoGuard_', '')
        :gsub('^GlacialMarksman_', '')
        :gsub('^VoidRaider_', '')
        :gsub('^UmbralBowman_', '')
        :gsub('^AbyssalKnight_', '')
        :gsub('^SunshardTemplar_', '')
        :gsub('^ArcticCorsair_', '')
        :gsub('^ShadowSpecter_', '')
        :gsub('^TerrorSkyShark_', '')
        :gsub('^AbyssalLeviathan_', '')
        :gsub('^SkySeaBeast_', '')
        :gsub('^PirateCaptainVance_', '')
        :gsub('^OrderCyborg_', '')
        :gsub('^OrderCyborgBoss_', '')
        :gsub('^SoulReaperRift_', '')
        :gsub('^Zioles_', '')
        :gsub('^ZiolesGachaNPC_', '')
        :gsub('^AncientMonk_', '')
        :gsub('^AncientMonkNPC_', '')
        :gsub('^SkyShipwright_', '')
        :gsub('^SkyShipwrightNPC_', '')
    if clips[stripped] then
        return clips[stripped]
    end
    return clips.Idle or clips.WorldIdle_Loop or clips.Swim or clips.Hover or clips.Phase2Awaken
end

local function resolveVisualAsset(requestedAsset)
    if Sources:FindFirstChild(requestedAsset) then
        return requestedAsset, false
    end
    local alias = ASSET_ALIASES[requestedAsset]
    if alias and Sources:FindFirstChild(alias) then
        return alias, false
    end
    local fallback = FALLBACK_VISUAL_ASSET[requestedAsset]
    if fallback and Sources:FindFirstChild(fallback) then
        return fallback, true
    end
    return requestedAsset, false
end

local function hasToken(str, token)
    return string.find(str, token, 1, true) ~= nil
end

local function addBonePart(list, folder, bone, name, className, size, color, material, offsetCF, reflectance, transparency, spinSpeed)
    if not bone then
        return nil
    end
    local p = Instance.new(className or 'Part')
    p.Name = name
    p.Size = size
    p.Color = color
    p.Material = material or Enum.Material.Metal
    p.Reflectance = reflectance or 0
    p.Transparency = transparency or 0
    p.Anchored = true
    p.CanCollide = false
    p.CanQuery = false
    p.CanTouch = false
    p.Massless = true
    p.Parent = folder
    table.insert(list, {
        Part = p,
        Bone = bone,
        Offset = offsetCF or CFrame.identity,
        Spin = spinSpeed,
    })
    return p
end

local function upgradeMob3D(visual, enemyId, visualAsset, element, usedFallback)
    if true then
        return nil
    end

    -- Part A: Material-Slot-Specific Palette Remapping
    for _, part in visual:GetDescendants() do
        if part:IsA('BasePart') then
            local mat = tostring(part:GetAttribute('BlenderMaterial') or part.Name)
            if enemyId == 'FrostDrone' then
                if hasToken(mat, 'SolarGlow') or hasToken(mat, 'CyanGlow') then
                    part.Color = Color3.fromRGB(72, 245, 255)
                    part.Material = Enum.Material.Neon
                    part.Reflectance = 0
                elseif hasToken(mat, 'BrightGold') or hasToken(mat, 'Gold') then
                    part.Color = Color3.fromRGB(185, 225, 255)
                    part.Material = Enum.Material.Metal
                    part.Reflectance = 0.26
                elseif hasToken(mat, 'Ivory') then
                    part.Color = Color3.fromRGB(24, 42, 68)
                    part.Material = Enum.Material.Metal
                    part.Reflectance = 0.12
                elseif hasToken(mat, 'SapphireNavy') or hasToken(mat, 'DarkSteel') then
                    part.Color = Color3.fromRGB(14, 26, 46)
                    part.Material = Enum.Material.Metal
                    part.Reflectance = 0.08
                end
            elseif enemyId == 'CryoGuard' then
                if hasToken(mat, 'VoidMagenta') or hasToken(mat, 'CrimsonCore') then
                    part.Color = Color3.fromRGB(64, 242, 255)
                    part.Material = Enum.Material.Neon
                    part.Reflectance = 0
                elseif hasToken(mat, 'TarnishedGold') or hasToken(mat, 'BrightGold') then
                    part.Color = Color3.fromRGB(120, 190, 245)
                    part.Material = Enum.Material.Metal
                    part.Reflectance = 0.24
                elseif hasToken(mat, 'ObsidianPlate') or hasToken(mat, 'DarkSteel') then
                    part.Color = Color3.fromRGB(20, 36, 62)
                    part.Material = Enum.Material.Metal
                    part.Reflectance = 0.14
                elseif hasToken(mat, 'RoyalCrimson') or hasToken(mat, 'VoidCloth') or hasToken(mat, 'DarkLeather') then
                    part.Color = Color3.fromRGB(32, 68, 115)
                    part.Material = Enum.Material.SmoothPlastic
                end
            elseif enemyId == 'CyberArcher' then
                if hasToken(mat, '-Light') or hasToken(mat, 'CyanGlow') then
                    part.Color = Color3.fromRGB(56, 245, 255)
                    part.Material = Enum.Material.Neon
                    part.Reflectance = 0
                elseif hasToken(mat, 'BrightGold') or hasToken(mat, 'PaleGold') or hasToken(mat, 'Gold') then
                    part.Color = Color3.fromRGB(175, 220, 255)
                    part.Material = Enum.Material.Metal
                    part.Reflectance = 0.25
                elseif hasToken(mat, 'Hair') then
                    part.Color = Color3.fromRGB(220, 242, 255)
                    part.Material = Enum.Material.SmoothPlastic
                elseif hasToken(mat, 'Skin') then
                    part.Color = Color3.fromRGB(215, 228, 245)
                    part.Material = Enum.Material.SmoothPlastic
                elseif hasToken(mat, 'Ivory') or hasToken(mat, 'Teal') then
                    part.Color = Color3.fromRGB(42, 82, 135)
                    part.Material = Enum.Material.Metal
                    part.Reflectance = 0.16
                elseif hasToken(mat, 'Leather') or hasToken(mat, 'DarkLeather') then
                    part.Color = Color3.fromRGB(18, 34, 58)
                    part.Material = Enum.Material.SmoothPlastic
                end
            elseif enemyId == 'VoidPirate' then
                if hasToken(mat, 'Rune') or (hasToken(mat, '-Eye') and not hasToken(mat, 'EyeWhite')) then
                    part.Color = Color3.fromRGB(225, 52, 255)
                    part.Material = Enum.Material.Neon
                    part.Reflectance = 0
                elseif hasToken(mat, 'EyeWhite') then
                    part.Color = Color3.fromRGB(225, 210, 240)
                    part.Material = Enum.Material.SmoothPlastic
                elseif hasToken(mat, 'BrightGold') or hasToken(mat, 'Gold') then
                    part.Color = Color3.fromRGB(162, 102, 232)
                    part.Material = Enum.Material.Metal
                    part.Reflectance = 0.26
                elseif hasToken(mat, 'Steel') or hasToken(mat, 'DarkSteel') then
                    part.Color = Color3.fromRGB(88, 66, 128)
                    part.Material = Enum.Material.Metal
                    part.Reflectance = 0.20
                elseif hasToken(mat, 'Skin') then
                    part.Color = Color3.fromRGB(168, 156, 188)
                    part.Material = Enum.Material.SmoothPlastic
                elseif hasToken(mat, 'Hair') then
                    part.Color = Color3.fromRGB(195, 182, 220)
                    part.Material = Enum.Material.SmoothPlastic
                elseif hasToken(mat, 'Red') or hasToken(mat, 'Coat') then
                    part.Color = Color3.fromRGB(76, 22, 58)
                    part.Material = Enum.Material.SmoothPlastic
                elseif hasToken(mat, 'Leather') or hasToken(mat, 'DarkLeather') or hasToken(mat, 'Ivory') or hasToken(mat, 'Cloth') then
                    part.Color = Color3.fromRGB(28, 20, 44)
                    part.Material = Enum.Material.SmoothPlastic
                end
            elseif enemyId == 'AbyssalKnight' then
                if hasToken(mat, '-Light') then
                    part.Color = Color3.fromRGB(218, 44, 255)
                    part.Material = Enum.Material.Neon
                    part.Reflectance = 0
                elseif hasToken(mat, 'BrightGold') or hasToken(mat, 'PaleGold') then
                    part.Color = Color3.fromRGB(158, 108, 228)
                    part.Material = Enum.Material.Metal
                    part.Reflectance = 0.28
                elseif hasToken(mat, 'Gold') then
                    part.Color = Color3.fromRGB(74, 46, 118)
                    part.Material = Enum.Material.Metal
                    part.Reflectance = 0.22
                elseif hasToken(mat, 'Ivory') then
                    part.Color = Color3.fromRGB(44, 30, 72)
                    part.Material = Enum.Material.Metal
                    part.Reflectance = 0.16
                elseif hasToken(mat, 'DarkSteel') or hasToken(mat, 'DarkLeather') then
                    part.Color = Color3.fromRGB(24, 18, 38)
                    part.Material = Enum.Material.SmoothPlastic
                end
            elseif enemyId == 'ShadowArcher' then
                if hasToken(mat, '-Light') or hasToken(mat, 'CyanGlow') then
                    part.Color = Color3.fromRGB(245, 45, 145)
                    part.Material = Enum.Material.Neon
                    part.Reflectance = 0
                elseif hasToken(mat, 'BrightGold') or hasToken(mat, 'PaleGold') or hasToken(mat, 'Gold') then
                    part.Color = Color3.fromRGB(156, 92, 212)
                    part.Material = Enum.Material.Metal
                    part.Reflectance = 0.25
                elseif hasToken(mat, 'Hair') then
                    part.Color = Color3.fromRGB(205, 190, 228)
                    part.Material = Enum.Material.SmoothPlastic
                elseif hasToken(mat, 'Skin') then
                    part.Color = Color3.fromRGB(172, 160, 192)
                    part.Material = Enum.Material.SmoothPlastic
                elseif hasToken(mat, 'Ivory') or hasToken(mat, 'Teal') then
                    part.Color = Color3.fromRGB(62, 28, 86)
                    part.Material = Enum.Material.Metal
                    part.Reflectance = 0.16
                elseif hasToken(mat, 'Leather') or hasToken(mat, 'DarkLeather') then
                    part.Color = Color3.fromRGB(26, 18, 40)
                    part.Material = Enum.Material.SmoothPlastic
                end
            else
                -- Golden Sky Mobs: crisp metallic sheen & SkyPirate BrightGold fix
                if hasToken(mat, 'BrightGold') or hasToken(mat, 'Gold') or hasToken(mat, 'TarnishedGold') or hasToken(mat, 'PaleGold') then
                    if enemyId == 'SkyPirate' and hasToken(mat, 'BrightGold') then
                        part.Color = Color3.fromRGB(242, 198, 92)
                    end
                    part.Material = Enum.Material.Metal
                    part.Reflectance = 0.22
                elseif hasToken(mat, 'DarkSteel') or hasToken(mat, 'Steel') or hasToken(mat, 'ObsidianPlate') then
                    part.Material = Enum.Material.Metal
                    part.Reflectance = 0.14
                end
            end
        end
    end

    -- Part B: Bone-Tracked 3D Sculpted Armor, Horns, Wings, Pauldrons & Weapon Attachments
    local root = visual.PrimaryPart
    if not root then
        return nil
    end
    local function bone(name)
        return root:FindFirstChild(name, true)
    end

    local head = bone('Head') or bone('HeadTurret') or bone('Skull') or bone('JawUpper')
    local torso = bone('UpperTorso') or bone('CoreBody') or bone('Spine_02') or bone('Spine_01') or bone('Spine')
    local tail = bone('Tail_04') or bone('Tail_03') or bone('Tail_02') or bone('Tail') or torso
    local lArm = bone('LeftUpperArm') or bone('Fin_L')
    local rArm = bone('RightUpperArm') or bone('Fin_R')
    local lHand = bone('LeftHand') or bone('LeftBlade') or lArm
    local rHand = bone('RightHand') or bone('RightBlade') or rArm

    local attFolder = Instance.new('Folder')
    attFolder.Name = 'Mob3DAttachments'
    attFolder.Parent = visual

    local items = {}

    if enemyId == 'AbyssalLeviathan' or visualAsset == 'AbyssalLeviathan' then
        -- 14_abyssal_leviathan_boss.png: Void Singularity chest core + 6 glowing crimson-violet eyes + dorsal neon rune fins + tail blades
        local voidPurple = Color3.fromRGB(205, 52, 255)
        local crimsonEye = Color3.fromRGB(255, 42, 95)
        local goldTrim = Color3.fromRGB(255, 208, 86)
        local darkScale = Color3.fromRGB(22, 16, 38)
        addBonePart(items, attFolder, torso, 'LeviathanSingularityCore', 'Part', Vector3.new(1.45, 1.45, 1.45), voidPurple, Enum.Material.Neon, CFrame.new(0, -0.35, -0.85), 0, 0.04, 2.2)
        addBonePart(items, attFolder, torso, 'LeviathanSingularityRing', 'Part', Vector3.new(2.15, 0.22, 2.15), goldTrim, Enum.Material.Metal, CFrame.new(0, -0.35, -0.85) * CFrame.Angles(0.45, 0, 0.35), 0.32, 0, -1.8)
        for i = 1, 3 do
            for _, s in ipairs({ -1, 1 }) do
                local tag = (s < 0 and 'L' or 'R') .. i
                addBonePart(items, attFolder, head or torso, 'LeviathanVoidEye_' .. tag, 'Part', Vector3.new(0.24, 0.16, 0.28), crimsonEye, Enum.Material.Neon, CFrame.new(s * (0.42 + i * 0.12), 0.25 + i * 0.14, -0.65 + i * 0.18), 0, 0.02)
            end
        end
        for i = 1, 5 do
            local finCF = CFrame.new(0, 0.95 + (3 - math.abs(3 - i)) * 0.18, -1.1 + i * 0.55) * CFrame.Angles(-0.38, 0, 0)
            addBonePart(items, attFolder, torso, 'LeviathanDorsalSpine_' .. i, 'WedgePart', Vector3.new(0.22, 1.85 - i * 0.12, 0.58), voidPurple, Enum.Material.Neon, finCF, 0, 0.08)
            addBonePart(items, attFolder, torso, 'LeviathanDorsalGold_' .. i, 'WedgePart', Vector3.new(0.28, 1.45 - i * 0.10, 0.34), darkScale, Enum.Material.Metal, finCF * CFrame.new(0, -0.15, 0.16), 0.26, 0)
        end
        for _, s in ipairs({ -1, 1 }) do
            local tag = s < 0 and 'L' or 'R'
            addBonePart(items, attFolder, tail or torso, 'LeviathanTailBlade_' .. tag, 'WedgePart', Vector3.new(0.18, 2.15, 0.72), voidPurple, Enum.Material.Neon, CFrame.new(s * 0.75, 0.15, 1.15) * CFrame.Angles(-0.25, s * 0.35, -s * 0.78), 0, 0.08)
        end
    elseif enemyId == 'SkySeaBeast' or visualAsset == 'SkySeaBeast' then
        -- 15_sky_sea_beast.png: Glowing cyan crystal dorsal spikes + golden-trimmed pectoral hydro-fins + glowing cyan jaws
        local hydroCyan = Color3.fromRGB(72, 245, 255)
        local royalGold = Color3.fromRGB(255, 214, 92)
        local deepAzure = Color3.fromRGB(26, 62, 118)
        addBonePart(items, attFolder, head or torso, 'SeaBeastHydroCore', 'Part', Vector3.new(0.95, 0.95, 1.25), hydroCyan, Enum.Material.Neon, CFrame.new(0, -0.12, -0.82), 0, 0.08)
        addBonePart(items, attFolder, head or torso, 'SeaBeastCrownHorn', 'WedgePart', Vector3.new(0.26, 1.75, 0.52), royalGold, Enum.Material.Metal, CFrame.new(0, 0.92, -0.45) * CFrame.Angles(-0.35, 0, 0), 0.30, 0)
        for i = 1, 4 do
            local spCF = CFrame.new(0, 0.85, -0.75 + i * 0.52) * CFrame.Angles(-0.42, 0, 0)
            addBonePart(items, attFolder, torso, 'SeaBeastCrystalSpike_' .. i, 'WedgePart', Vector3.new(0.20, 1.65 - i * 0.12, 0.48), hydroCyan, Enum.Material.Neon, spCF, 0, 0.06)
        end
        for _, side in ipairs({ { lArm or torso, -1, 'L' }, { rArm or torso, 1, 'R' } }) do
            local b, s, tag = side[1], side[2], side[3]
            addBonePart(items, attFolder, b, 'SeaBeastPectoralFin_' .. tag, 'WedgePart', Vector3.new(0.16, 2.25, 0.85), hydroCyan, Enum.Material.Neon, CFrame.new(s * 0.95, -0.15, 0.15) * CFrame.Angles(-0.18, s * 0.25, -s * 1.05), 0, 0.10)
            addBonePart(items, attFolder, b, 'SeaBeastPectoralTrim_' .. tag, 'WedgePart', Vector3.new(0.22, 1.95, 0.45), royalGold, Enum.Material.Metal, CFrame.new(s * 0.88, -0.10, -0.12) * CFrame.Angles(-0.18, s * 0.25, -s * 1.05), 0.28, 0)
        end
    elseif enemyId == 'PirateCaptainVance' or visualAsset == 'PirateCaptainVance' then
        -- 16_pirate_captain_vance.png: Glowing cyan rune cutlass + golden Aether flintlock pistol + tricorn hat plume
        local aetherCyan = Color3.fromRGB(78, 242, 255)
        local captainGold = Color3.fromRGB(255, 208, 82)
        local crimsonCoat = Color3.fromRGB(168, 28, 42)
        addBonePart(items, attFolder, head, 'VanceTricornBrim', 'Part', Vector3.new(1.55, 0.16, 1.48), Color3.fromRGB(26, 22, 34), Enum.Material.SmoothPlastic, CFrame.new(0, 0.58, 0), 0.05, 0)
        addBonePart(items, attFolder, head, 'VanceHatPlume', 'WedgePart', Vector3.new(0.16, 1.25, 0.45), aetherCyan, Enum.Material.Neon, CFrame.new(0.42, 0.95, 0.25) * CFrame.Angles(-0.48, 0.22, -0.25), 0, 0.06)
        for _, side in ipairs({ { lArm, -1, 'L' }, { rArm, 1, 'R' } }) do
            local b, s, tag = side[1], side[2], side[3]
            addBonePart(items, attFolder, b, 'VanceEpaulette_' .. tag, 'Part', Vector3.new(0.68, 0.34, 0.78), captainGold, Enum.Material.Metal, CFrame.new(s * 0.34, 0.30, 0), 0.30, 0)
        end
        addBonePart(items, attFolder, rHand, 'VanceRuneCutlassBlade', 'WedgePart', Vector3.new(0.12, 2.65, 0.42), aetherCyan, Enum.Material.Neon, CFrame.new(0, -1.20, -0.42), 0, 0.05)
        addBonePart(items, attFolder, rHand, 'VanceCutlassGuard', 'Part', Vector3.new(0.28, 0.42, 0.55), captainGold, Enum.Material.Metal, CFrame.new(0, -0.10, -0.35), 0.32, 0)
        addBonePart(items, attFolder, lHand, 'VanceFlintlockBarrel', 'Part', Vector3.new(0.22, 1.15, 0.28), captainGold, Enum.Material.Metal, CFrame.new(0, -0.48, -0.35), 0.28, 0)
        addBonePart(items, attFolder, lHand, 'VanceFlintlockCore', 'Part', Vector3.new(0.16, 0.85, 0.18), aetherCyan, Enum.Material.Neon, CFrame.new(0, -0.52, -0.44), 0, 0.05)
    elseif enemyId == 'OrderCyborgBoss' or visualAsset == 'OrderCyborgBoss' then
        -- 17_order_cyborg_boss.png: 4 neon cyan/magenta X-wing plasma blades + glowing cyan X-visor + twin forearm plasma blades
        local cyberCyan = Color3.fromRGB(64, 245, 255)
        local cyberMagenta = Color3.fromRGB(255, 58, 195)
        local titanium = Color3.fromRGB(215, 232, 250)
        addBonePart(items, attFolder, head, 'OrderVisorX1', 'Part', Vector3.new(0.88, 0.14, 0.24), cyberCyan, Enum.Material.Neon, CFrame.new(0, 0.08, -0.48) * CFrame.Angles(0, 0, 0.38), 0, 0.04)
        addBonePart(items, attFolder, head, 'OrderVisorX2', 'Part', Vector3.new(0.88, 0.14, 0.24), cyberMagenta, Enum.Material.Neon, CFrame.new(0, 0.08, -0.49) * CFrame.Angles(0, 0, -0.38), 0, 0.04)
        addBonePart(items, attFolder, torso, 'OrderQuantumCore', 'Part', Vector3.new(0.72, 0.72, 0.36), cyberCyan, Enum.Material.Neon, CFrame.new(0, 0.15, -0.58) * CFrame.Angles(0, 0, math.pi * 0.25), 0, 0.04, 2.4)
        for i = 1, 4 do
            local s = (i <= 2) and -1 or 1
            local upper = (i % 2 == 1)
            local wingCol = upper and cyberCyan or cyberMagenta
            local zAng = upper and (-s * 0.65) or (-s * 2.35)
            local yPos = upper and 0.68 or -0.22
            local wCF = CFrame.new(s * 0.78, yPos, 0.75) * CFrame.Angles(-0.18, s * 0.28, zAng)
            addBonePart(items, attFolder, torso, 'OrderXWingPlasma_' .. i, 'WedgePart', Vector3.new(0.14, 2.45, 0.48), wingCol, Enum.Material.Neon, wCF, 0, 0.06)
            addBonePart(items, attFolder, torso, 'OrderXWingPylon_' .. i, 'Part', Vector3.new(0.24, 1.35, 0.28), titanium, Enum.Material.Metal, wCF * CFrame.new(0, -0.35, 0.14), 0.28, 0)
        end
        addBonePart(items, attFolder, lHand, 'OrderPlasmaBladeL', 'WedgePart', Vector3.new(0.14, 2.55, 0.44), cyberCyan, Enum.Material.Neon, CFrame.new(0, -1.15, -0.42), 0, 0.05)
        addBonePart(items, attFolder, rHand, 'OrderPlasmaBladeR', 'WedgePart', Vector3.new(0.14, 2.55, 0.44), cyberMagenta, Enum.Material.Neon, CFrame.new(0, -1.15, -0.42), 0, 0.05)
    elseif enemyId == 'SoulReaperRift' or visualAsset == 'SoulReaperRift' then
        -- 18_soul_reaper_rift.png: Giant purple crystal Void Scythe + 2 floating purple soul lanterns + horned skull crown
        local soulViolet = Color3.fromRGB(212, 58, 255)
        local soulCyan = Color3.fromRGB(115, 240, 255)
        local boneIvory = Color3.fromRGB(228, 222, 238)
        local darkObsidian = Color3.fromRGB(24, 16, 38)
        for _, s in ipairs({ -1, 1 }) do
            local tag = s < 0 and 'L' or 'R'
            addBonePart(items, attFolder, head, 'ReaperCrownHorn_' .. tag, 'WedgePart', Vector3.new(0.22, 1.35, 0.36), soulViolet, Enum.Material.Neon, CFrame.new(s * 0.48, 0.65, -0.08) * CFrame.Angles(-0.22, 0, -s * 0.36), 0, 0.06)
            addBonePart(items, attFolder, torso, 'ReaperSoulLantern_' .. tag, 'Part', Vector3.new(0.42, 0.58, 0.42), soulCyan, Enum.Material.Neon, CFrame.new(s * 1.15, -0.45, -0.35), 0, 0.08, s * 1.8)
        end
        addBonePart(items, attFolder, rHand, 'ReaperScytheShaft', 'Part', Vector3.new(0.18, 4.2, 0.18), darkObsidian, Enum.Material.Metal, CFrame.new(0, -0.95, -0.35), 0.25, 0)
        addBonePart(items, attFolder, rHand, 'ReaperScytheCrescent', 'WedgePart', Vector3.new(0.16, 2.65, 0.78), soulViolet, Enum.Material.Neon, CFrame.new(0, -2.85, -0.95) * CFrame.Angles(1.32, 0, 0), 0, 0.05)
        addBonePart(items, attFolder, rHand, 'ReaperScytheSkull', 'Part', Vector3.new(0.44, 0.44, 0.44), boneIvory, Enum.Material.SmoothPlastic, CFrame.new(0, -2.75, -0.35), 0.10, 0)
    elseif enemyId == 'ZiolesGachaNPC' or visualAsset == 'ZiolesGachaNPC' then
        -- 19_npc_zioles_core_gacha.png: Floating galaxy apple in right hand + golden astrolabe ring on hat + back wheel of 5 elemental fruit orbs
        local cosmicPurple = Color3.fromRGB(192, 68, 255)
        local astroGold = Color3.fromRGB(255, 214, 92)
        local fruitColors = {
            Color3.fromRGB(255, 118, 52),
            Color3.fromRGB(72, 240, 255),
            Color3.fromRGB(255, 224, 88),
            Color3.fromRGB(198, 64, 255),
            Color3.fromRGB(92, 255, 168),
        }
        addBonePart(items, attFolder, head, 'ZiolesAstrolabeHalo', 'Part', Vector3.new(1.45, 0.14, 1.45), astroGold, Enum.Material.Metal, CFrame.new(0, 0.72, 0) * CFrame.Angles(0.22, 0, 0.22), 0.32, 0, 1.5)
        addBonePart(items, attFolder, rHand, 'ZiolesGalaxyCoreFruit', 'Part', Vector3.new(0.62, 0.62, 0.62), cosmicPurple, Enum.Material.Neon, CFrame.new(0, -0.45, -0.45), 0, 0.05, 2.2)
        addBonePart(items, attFolder, rHand, 'ZiolesFruitSwirlRing', 'Part', Vector3.new(0.92, 0.10, 0.92), astroGold, Enum.Material.Neon, CFrame.new(0, -0.45, -0.45) * CFrame.Angles(0.45, 0, -0.35), 0, 0.08, -2.6)
        for i = 1, 5 do
            local ang = (i - 1) * (2 * math.pi / 5)
            local orbCF = CFrame.new(math.cos(ang) * 1.35, 0.55 + math.sin(ang) * 1.35, 0.82)
            addBonePart(items, attFolder, torso, 'ZiolesWheelFruit_' .. i, 'Part', Vector3.new(0.38, 0.38, 0.38), fruitColors[i], Enum.Material.Neon, orbCF, 0, 0.06, 1.6)
        end
    elseif enemyId == 'AncientMonkNPC' or visualAsset == 'AncientMonkNPC' then
        -- 20_npc_ancient_monk_godhuman.png: 8-point golden mandala halo behind head/torso + 6 floating golden lotus prayer spheres + dual gauntlets
        local divineGold = Color3.fromRGB(255, 218, 88)
        local lightningCyan = Color3.fromRGB(88, 242, 255)
        local voidFlame = Color3.fromRGB(208, 62, 255)
        addBonePart(items, attFolder, torso, 'MonkMandalaRing', 'Part', Vector3.new(2.15, 2.15, 0.12), divineGold, Enum.Material.Neon, CFrame.new(0, 0.85, 0.78), 0, 0.12, 1.2)
        for i = 1, 6 do
            local ang = (i - 1) * (math.pi / 3)
            local beadCF = CFrame.new(math.cos(ang) * 1.45, 0.85 + math.sin(ang) * 1.45, 0.72)
            addBonePart(items, attFolder, torso, 'MonkPrayerSphere_' .. i, 'Part', Vector3.new(0.34, 0.34, 0.34), divineGold, Enum.Material.Neon, beadCF, 0, 0.05, -1.8)
        end
        addBonePart(items, attFolder, lHand, 'GodhumanGauntletL', 'Part', Vector3.new(0.48, 0.68, 0.48), lightningCyan, Enum.Material.Neon, CFrame.new(0, -0.22, 0), 0, 0.08)
        addBonePart(items, attFolder, rHand, 'GodhumanGauntletR', 'Part', Vector3.new(0.48, 0.68, 0.48), voidFlame, Enum.Material.Neon, CFrame.new(0, -0.22, 0), 0, 0.08)
    elseif enemyId == 'SkyShipwrightNPC' or visualAsset == 'SkyShipwrightNPC' then
        -- 21_npc_sky_shipwright.png: Giant golden Aether Chrono-Wrench on right hand/shoulder + holographic cyan ship blueprint on left forearm
        local brassGold = Color3.fromRGB(245, 196, 78)
        local holoCyan = Color3.fromRGB(72, 242, 255)
        addBonePart(items, attFolder, head, 'ShipwrightGoggles', 'Part', Vector3.new(0.86, 0.22, 0.28), holoCyan, Enum.Material.Neon, CFrame.new(0, 0.28, -0.46), 0, 0.06)
        addBonePart(items, attFolder, rHand, 'ChronoWrenchShaft', 'Part', Vector3.new(0.22, 2.65, 0.22), brassGold, Enum.Material.Metal, CFrame.new(0, -0.85, -0.32), 0.30, 0)
        addBonePart(items, attFolder, rHand, 'ChronoWrenchJaw', 'Part', Vector3.new(0.75, 0.62, 0.28), brassGold, Enum.Material.Metal, CFrame.new(0, -2.15, -0.32), 0.32, 0)
        addBonePart(items, attFolder, rHand, 'ChronoWrenchCore', 'Part', Vector3.new(0.38, 0.38, 0.34), holoCyan, Enum.Material.Neon, CFrame.new(0, -2.15, -0.32), 0, 0.05, 2.0)
        addBonePart(items, attFolder, lHand, 'HoloShipBlueprint', 'Part', Vector3.new(0.95, 0.08, 0.62), holoCyan, Enum.Material.Neon, CFrame.new(0, -0.35, -0.45), 0, 0.28)
    elseif enemyId == 'FrostDrone' then
        local chrome = Color3.fromRGB(185, 225, 255)
        local cyan = Color3.fromRGB(72, 245, 255)
        for i = 1, 4 do
            local ang = (i - 1) * (math.pi * 0.5) + math.pi * 0.25
            local dirCF = CFrame.Angles(0, ang, 0) * CFrame.new(0, 0.35, -1.25) * CFrame.Angles(math.rad(-28), 0, 0)
            addBonePart(items, attFolder, torso, 'GlacierFinFrame_' .. i, 'WedgePart', Vector3.new(0.18, 1.35, 0.55), chrome, Enum.Material.Metal, dirCF, 0.26, 0)
            addBonePart(items, attFolder, torso, 'GlacierFinEdge_' .. i, 'WedgePart', Vector3.new(0.10, 1.45, 0.25), cyan, Enum.Material.Neon, dirCF * CFrame.new(0, 0, -0.22), 0, 0.08)
        end
        for i = 1, 6 do
            local ang = (i - 1) * (math.pi / 3)
            local off = CFrame.Angles(0, ang, 0) * CFrame.new(0, 1.55, 1.15) * CFrame.Angles(0, 0, math.pi * 0.25)
            addBonePart(items, attFolder, torso, 'CryoHaloDiamond_' .. i, 'Part', Vector3.new(0.26, 0.26, 0.12), cyan, Enum.Material.Neon, off, 0, 0.05, 1.8)
        end
        addBonePart(items, attFolder, lHand, 'SubzeroBladeL', 'WedgePart', Vector3.new(0.12, 1.65, 0.38), cyan, Enum.Material.Neon, CFrame.new(0, -0.55, -0.35), 0, 0.06)
        addBonePart(items, attFolder, rHand, 'SubzeroBladeR', 'WedgePart', Vector3.new(0.12, 1.65, 0.38), cyan, Enum.Material.Neon, CFrame.new(0, -0.55, -0.35), 0, 0.06)
    elseif enemyId == 'CryoGuard' then
        local ice = Color3.fromRGB(82, 240, 255)
        local cobalt = Color3.fromRGB(125, 195, 250)
        for _, side in ipairs({ { lArm, -1, 'L' }, { rArm, 1, 'R' } }) do
            local b, s, tag = side[1], side[2], side[3]
            addBonePart(items, attFolder, b, 'GlacierSpikeA_' .. tag, 'WedgePart', Vector3.new(0.28, 1.35, 0.45), ice, Enum.Material.Neon, CFrame.new(s * 0.55, 0.55, 0) * CFrame.Angles(0, 0, -s * 0.48), 0, 0.10)
            addBonePart(items, attFolder, b, 'GlacierSpikeB_' .. tag, 'WedgePart', Vector3.new(0.24, 1.05, 0.38), cobalt, Enum.Material.Metal, CFrame.new(s * 0.42, 0.30, 0.28) * CFrame.Angles(-0.25, 0, -s * 0.65), 0.25, 0)
        end
        addBonePart(items, attFolder, head, 'CryoHornVisor', 'Part', Vector3.new(0.95, 0.18, 0.24), ice, Enum.Material.Neon, CFrame.new(0, 0.12, -0.52), 0, 0.05)
        addBonePart(items, attFolder, head, 'CryoHornL', 'WedgePart', Vector3.new(0.18, 1.15, 0.32), ice, Enum.Material.Neon, CFrame.new(-0.48, 0.55, -0.15) * CFrame.Angles(-0.35, 0, 0.32), 0, 0.08)
        addBonePart(items, attFolder, head, 'CryoHornR', 'WedgePart', Vector3.new(0.18, 1.15, 0.32), ice, Enum.Material.Neon, CFrame.new(0.48, 0.55, -0.15) * CFrame.Angles(-0.35, 0, -0.32), 0, 0.08)
        addBonePart(items, attFolder, torso, 'CryoReactorFrame', 'Part', Vector3.new(1.15, 1.35, 0.35), cobalt, Enum.Material.Metal, CFrame.new(0, 0.15, 0.72), 0.24, 0)
        addBonePart(items, attFolder, torso, 'CryoReactorCore', 'Part', Vector3.new(0.65, 0.85, 0.28), ice, Enum.Material.Neon, CFrame.new(0, 0.15, 0.82), 0, 0.05)
        addBonePart(items, attFolder, rHand, 'FrostCleaverEdge', 'WedgePart', Vector3.new(0.14, 2.55, 0.46), ice, Enum.Material.Neon, CFrame.new(0, -1.15, -0.45), 0, 0.08)
    elseif enemyId == 'CyberArcher' then
        local cyan = Color3.fromRGB(56, 245, 255)
        local alloy = Color3.fromRGB(175, 220, 255)
        addBonePart(items, attFolder, head, 'CyberOpticVisor', 'Part', Vector3.new(0.88, 0.18, 0.26), cyan, Enum.Material.Neon, CFrame.new(0, 0.08, -0.48), 0, 0.05)
        for _, s in ipairs({ -1, 1 }) do
            local tag = s < 0 and 'L' or 'R'
            addBonePart(items, attFolder, head, 'CyberAntenna_' .. tag, 'WedgePart', Vector3.new(0.10, 0.85, 0.26), alloy, Enum.Material.Metal, CFrame.new(s * 0.46, 0.42, 0.08) * CFrame.Angles(-0.45, 0, -s * 0.22), 0.25, 0)
            addBonePart(items, attFolder, torso, 'MechaWingUpper_' .. tag, 'WedgePart', Vector3.new(0.14, 1.85, 0.48), cyan, Enum.Material.Neon, CFrame.new(s * 0.85, 0.55, 0.68) * CFrame.Angles(-0.22, s * 0.35, -s * 0.68), 0, 0.08)
            addBonePart(items, attFolder, torso, 'MechaWingLower_' .. tag, 'WedgePart', Vector3.new(0.14, 1.45, 0.38), alloy, Enum.Material.Metal, CFrame.new(s * 0.72, -0.15, 0.68) * CFrame.Angles(-0.18, s * 0.35, -s * 1.05), 0.25, 0)
        end
        addBonePart(items, attFolder, lHand, 'RailBowUpper', 'WedgePart', Vector3.new(0.12, 1.65, 0.32), cyan, Enum.Material.Neon, CFrame.new(0, 0.95, -0.35) * CFrame.Angles(0.25, 0, 0), 0, 0.06)
        addBonePart(items, attFolder, lHand, 'RailBowLower', 'WedgePart', Vector3.new(0.12, 1.65, 0.32), cyan, Enum.Material.Neon, CFrame.new(0, -0.95, -0.35) * CFrame.Angles(math.pi - 0.25, 0, 0), 0, 0.06)
    elseif enemyId == 'VoidPirate' then
        local voidGlow = Color3.fromRGB(225, 52, 255)
        local obsidian = Color3.fromRGB(32, 18, 48)
        for _, s in ipairs({ -1, 1 }) do
            local tag = s < 0 and 'L' or 'R'
            addBonePart(items, attFolder, head, 'AbyssalHornBase_' .. tag, 'WedgePart', Vector3.new(0.22, 0.95, 0.32), obsidian, Enum.Material.Metal, CFrame.new(s * 0.45, 0.48, -0.05) * CFrame.Angles(-0.25, 0, -s * 0.42), 0.20, 0)
            addBonePart(items, attFolder, head, 'AbyssalHornTip_' .. tag, 'WedgePart', Vector3.new(0.14, 0.85, 0.24), voidGlow, Enum.Material.Neon, CFrame.new(s * 0.68, 0.95, -0.22) * CFrame.Angles(0.35, 0, -s * 0.20), 0, 0.05)
        end
        for _, side in ipairs({ { lArm, -1, 'L' }, { rArm, 1, 'R' } }) do
            local b, s, tag = side[1], side[2], side[3]
            addBonePart(items, attFolder, b, 'VoidPauldronPlate_' .. tag, 'Part', Vector3.new(0.75, 0.45, 0.85), obsidian, Enum.Material.Metal, CFrame.new(s * 0.35, 0.25, 0), 0.20, 0)
            addBonePart(items, attFolder, b, 'VoidPauldronSpike_' .. tag, 'WedgePart', Vector3.new(0.22, 1.05, 0.34), voidGlow, Enum.Material.Neon, CFrame.new(s * 0.52, 0.62, 0) * CFrame.Angles(0, 0, -s * 0.55), 0, 0.08)
        end
        addBonePart(items, attFolder, rHand, 'VoidScytheEdgeR', 'WedgePart', Vector3.new(0.12, 2.05, 0.42), voidGlow, Enum.Material.Neon, CFrame.new(0, -0.85, -0.45), 0, 0.06)
        addBonePart(items, attFolder, lHand, 'VoidScytheEdgeL', 'WedgePart', Vector3.new(0.12, 1.75, 0.38), voidGlow, Enum.Material.Neon, CFrame.new(0, -0.75, -0.40), 0, 0.06)
    elseif enemyId == 'AbyssalKnight' then
        local voidFire = Color3.fromRGB(218, 44, 255)
        local darkPlate = Color3.fromRGB(28, 18, 42)
        for i = 1, 6 do
            local s = (i <= 3) and -1 or 1
            local tier = ((i - 1) % 3) + 1
            local wingCF = CFrame.new(s * (0.65 + tier * 0.28), 0.75 - tier * 0.32, 0.78)
                * CFrame.Angles(-0.18, s * 0.28, -s * (0.45 + tier * 0.26))
            addBonePart(items, attFolder, torso, 'DarkMatterWing_' .. i, 'WedgePart', Vector3.new(0.16, 1.95 - tier * 0.2, 0.46), voidFire, Enum.Material.Neon, wingCF, 0, 0.08)
            addBonePart(items, attFolder, torso, 'DarkMatterSpine_' .. i, 'WedgePart', Vector3.new(0.22, 1.75 - tier * 0.2, 0.28), darkPlate, Enum.Material.Metal, wingCF * CFrame.new(0, 0, 0.14), 0.22, 0)
        end
        for _, s in ipairs({ -1, 1 }) do
            local tag = s < 0 and 'L' or 'R'
            addBonePart(items, attFolder, head, 'AbyssalGreatHorn_' .. tag, 'WedgePart', Vector3.new(0.24, 1.35, 0.38), voidFire, Enum.Material.Neon, CFrame.new(s * 0.52, 0.68, -0.10) * CFrame.Angles(-0.22, 0, -s * 0.32), 0, 0.06)
        end
        addBonePart(items, attFolder, rHand, 'AbyssalGreatswordCore', 'Part', Vector3.new(0.18, 3.1, 0.36), darkPlate, Enum.Material.Metal, CFrame.new(0, -1.45, -0.35), 0.24, 0)
        addBonePart(items, attFolder, rHand, 'AbyssalGreatswordEdge', 'WedgePart', Vector3.new(0.12, 3.3, 0.52), voidFire, Enum.Material.Neon, CFrame.new(0, -1.50, -0.46), 0, 0.06)
    elseif enemyId == 'ShadowArcher' then
        local umbral = Color3.fromRGB(245, 45, 145)
        local darkSteel = Color3.fromRGB(48, 28, 72)
        addBonePart(items, attFolder, head, 'UmbralMaskVisor', 'Part', Vector3.new(0.86, 0.22, 0.26), umbral, Enum.Material.Neon, CFrame.new(0, 0.06, -0.48), 0, 0.05)
        for i = 1, 4 do
            local s = (i <= 2) and -1 or 1
            local row = ((i - 1) % 2) + 1
            local fCF = CFrame.new(s * (0.68 + row * 0.25), 0.55 - row * 0.35, 0.68)
                * CFrame.Angles(-0.2, s * 0.3, -s * (0.55 + row * 0.32))
            addBonePart(items, attFolder, torso, 'ShadowFeather_' .. i, 'WedgePart', Vector3.new(0.12, 1.65, 0.38), umbral, Enum.Material.Neon, fCF, 0, 0.08)
        end
        addBonePart(items, attFolder, lHand, 'VoidStarBowUpper', 'WedgePart', Vector3.new(0.14, 1.75, 0.34), umbral, Enum.Material.Neon, CFrame.new(0, 1.0, -0.38) * CFrame.Angles(0.28, 0, 0), 0, 0.06)
        addBonePart(items, attFolder, lHand, 'VoidStarBowLower', 'WedgePart', Vector3.new(0.14, 1.75, 0.34), umbral, Enum.Material.Neon, CFrame.new(0, -1.0, -0.38) * CFrame.Angles(math.pi - 0.28, 0, 0), 0, 0.06)
        addBonePart(items, attFolder, lHand, 'VoidStarBowGrip', 'Part', Vector3.new(0.22, 0.65, 0.28), darkSteel, Enum.Material.Metal, CFrame.new(0, 0, -0.32), 0.20, 0)
    elseif enemyId == 'TrainingDrone' then
        local gold = Color3.fromRGB(255, 215, 92)
        local cyan = Color3.fromRGB(102, 238, 255)
        addBonePart(items, attFolder, head or torso, 'CelestialSunCrest', 'Part', Vector3.new(0.32, 0.32, 0.14), gold, Enum.Material.Neon, CFrame.new(0, 0.95, 0) * CFrame.Angles(0, 0, math.pi * 0.25), 0, 0.05, 1.6)
        addBonePart(items, attFolder, head or torso, 'CelestialSunCore', 'Part', Vector3.new(0.18, 0.58, 0.18), cyan, Enum.Material.Neon, CFrame.new(0, 0.95, 0), 0, 0.05)
    elseif enemyId == 'SkyPirate' then
        local crimson = Color3.fromRGB(255, 88, 68)
        addBonePart(items, attFolder, rHand, 'CutlassPlasmaR', 'WedgePart', Vector3.new(0.10, 1.75, 0.32), crimson, Enum.Material.Neon, CFrame.new(0, -0.75, -0.38), 0, 0.08)
        addBonePart(items, attFolder, lHand, 'CutlassPlasmaL', 'WedgePart', Vector3.new(0.10, 1.55, 0.28), crimson, Enum.Material.Neon, CFrame.new(0, -0.65, -0.34), 0, 0.08)
    elseif enemyId == 'CorruptedGuard' then
        local corrupt = Color3.fromRGB(220, 62, 255)
        addBonePart(items, attFolder, lArm, 'CorruptShoulderCrystal', 'WedgePart', Vector3.new(0.24, 1.15, 0.38), corrupt, Enum.Material.Neon, CFrame.new(-0.48, 0.52, 0) * CFrame.Angles(0, 0, 0.48), 0, 0.08)
        addBonePart(items, attFolder, torso, 'CorruptBackSpike', 'WedgePart', Vector3.new(0.22, 1.10, 0.35), corrupt, Enum.Material.Neon, CFrame.new(0.25, 0.48, 0.68) * CFrame.Angles(-0.55, 0, -0.22), 0, 0.08)
        addBonePart(items, attFolder, rHand, 'CorruptHalberdEdge', 'WedgePart', Vector3.new(0.12, 2.25, 0.42), corrupt, Enum.Material.Neon, CFrame.new(0, -1.05, -0.42), 0, 0.08)
    elseif enemyId == 'LightArcher' then
        local solar = Color3.fromRGB(255, 222, 105)
        for _, s in ipairs({ -1, 1 }) do
            local tag = s < 0 and 'L' or 'R'
            addBonePart(items, attFolder, torso, 'SolarWingCrest_' .. tag, 'WedgePart', Vector3.new(0.12, 1.55, 0.36), solar, Enum.Material.Neon, CFrame.new(s * 0.65, 0.48, 0.62) * CFrame.Angles(-0.2, s * 0.28, -s * 0.62), 0, 0.08)
        end
        addBonePart(items, attFolder, lHand, 'SolarBowArcUpper', 'WedgePart', Vector3.new(0.10, 1.45, 0.28), solar, Enum.Material.Neon, CFrame.new(0, 0.85, -0.32) * CFrame.Angles(0.22, 0, 0), 0, 0.08)
        addBonePart(items, attFolder, lHand, 'SolarBowArcLower', 'WedgePart', Vector3.new(0.10, 1.45, 0.28), solar, Enum.Material.Neon, CFrame.new(0, -0.85, -0.32) * CFrame.Angles(math.pi - 0.22, 0, 0), 0, 0.08)
    elseif enemyId == 'GoldenKnight' or enemyId == 'SunshardTemplar' then
        local sunGold = Color3.fromRGB(255, 218, 92)
        for i = 1, 4 do
            local s = (i <= 2) and -1 or 1
            local row = ((i - 1) % 2) + 1
            local wCF = CFrame.new(s * (0.68 + row * 0.24), 0.65 - row * 0.32, 0.72)
                * CFrame.Angles(-0.18, s * 0.25, -s * (0.48 + row * 0.28))
            addBonePart(items, attFolder, torso, 'SeraphWing_' .. i, 'WedgePart', Vector3.new(0.14, 1.75 - row * 0.15, 0.40), sunGold, Enum.Material.Neon, wCF, 0, 0.08)
        end
        addBonePart(items, attFolder, rHand, 'SolarBroadswordAura', 'WedgePart', Vector3.new(0.12, 2.75, 0.42), sunGold, Enum.Material.Neon, CFrame.new(0, -1.25, -0.38), 0, 0.08)
    elseif enemyId == 'ArcticCorsair' then
        local iceCyan = Color3.fromRGB(82, 240, 255)
        addBonePart(items, attFolder, rHand, 'CorsairHarpoon', 'WedgePart', Vector3.new(0.14, 2.35, 0.36), iceCyan, Enum.Material.Neon, CFrame.new(0, -1.05, -0.40), 0, 0.06)
        addBonePart(items, attFolder, lHand, 'CorsairFrostAxe', 'WedgePart', Vector3.new(0.14, 1.65, 0.42), iceCyan, Enum.Material.Neon, CFrame.new(0, -0.75, -0.36), 0, 0.06)
    elseif enemyId == 'ShadowSpecter' or enemyId == 'TerrorSkyShark' then
        local voidMagenta = Color3.fromRGB(225, 52, 255)
        addBonePart(items, attFolder, rHand, 'VoidSpecterBladeR', 'WedgePart', Vector3.new(0.14, 2.15, 0.42), voidMagenta, Enum.Material.Neon, CFrame.new(0, -0.95, -0.40), 0, 0.06)
        addBonePart(items, attFolder, lHand, 'VoidSpecterBladeL', 'WedgePart', Vector3.new(0.14, 2.15, 0.42), voidMagenta, Enum.Material.Neon, CFrame.new(0, -0.95, -0.40), 0, 0.06)
    end

    if element == 'Frost' or element == 'Void' then
        local elemColor = element == 'Frost' and Color3.fromRGB(82, 238, 255) or Color3.fromRGB(215, 58, 255)
        local accentColor = element == 'Frost' and Color3.fromRGB(205, 250, 255) or Color3.fromRGB(245, 130, 255)
        local emitter = Instance.new('ParticleEmitter')
        emitter.Name = 'ElementalParticles'
        emitter.Color = ColorSequence.new(elemColor, accentColor)
        emitter.LightEmission = 0.75
        emitter.LightInfluence = 0
        emitter.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.18),
            NumberSequenceKeypoint.new(0.6, 0.11),
            NumberSequenceKeypoint.new(1, 0),
        })
        emitter.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.2),
            NumberSequenceKeypoint.new(1, 1),
        })
        emitter.Lifetime = NumberRange.new(0.5, 0.95)
        emitter.Rate = 12
        emitter.Speed = NumberRange.new(1.0, 2.4)
        emitter.SpreadAngle = Vector2.new(35, 35)
        emitter.Parent = root
    end

    return {
        Folder = attFolder,
        Items = items,
    }
end

local function stepMobAttachments(mobAtt, now)
    if not mobAtt or not mobAtt.Folder or not mobAtt.Folder.Parent then
        return
    end
    for _, item in ipairs(mobAtt.Items) do
        local p = item.Part
        local b = item.Bone
        if p and p.Parent and b and b.Parent then
            local cf = b.TransformedWorldCFrame * item.Offset
            if item.Spin then
                cf = cf * CFrame.Angles(0, now * item.Spin, 0)
            end
            p.CFrame = cf
        end
    end
end

local function summon(s)
    if not Sources:FindFirstChild('CryonPillar') then
        return
    end
    templates.CryonPillar = templates.CryonPillar or Renderer.Build('CryonPillar')
    local scale = 1.6
    local pillarClips = getClips('CryonPillar', scale)
    for _, x in { -17, 17 } do
        local visual = templates.CryonPillar:Clone()
        visual.Name = 'Cryon_SummonedPillar'
        visual:ScaleTo(scale)
        visual:PivotTo(CFrame.new(s.Body.Position.X + x, s.Owner:GetAttribute('EnemyFloorY') or s.Body.Position.Y - 2.5, s.Body.Position.Z))
        visual.Parent = workspace
        table.insert(pillars, { Visual = visual, Start = os.clock(), Clips = pillarClips })
    end
end

local function summonVoidFX(s, clipName)
    if not Sources:FindFirstChild('NoxarVoidFX') then
        return
    end
    templates.NoxarVoidFX = templates.NoxarVoidFX or Renderer.Build('NoxarVoidFX')
    local scale = 1.0
    local fxClips = getClips('NoxarVoidFX', scale)
    local clip = resolveClip(fxClips, SUPPORTED.NoxarVoidFX, clipName or 'Phase2Awaken')
    if not clip then
        return
    end
    local visual = templates.NoxarVoidFX:Clone()
    visual.Name = 'Noxar_SummonedVoidFX'
    visual:ScaleTo(scale)
    for _, part in visual:GetDescendants() do
        if part:IsA('BasePart') and part ~= visual.PrimaryPart then
            part.Transparency = 0.28
        end
    end
    visual:PivotTo(CFrame.new(s.Body.Position.X, s.Owner:GetAttribute('EnemyFloorY') or s.Body.Position.Y - 2.5, s.Body.Position.Z) * s.Body.CFrame.Rotation)
    visual.Parent = workspace
    table.insert(voidfx, { Visual = visual, Start = os.clock(), Clip = clip, Duration = math.max(2.5, clip.Duration) })
end

local function hide(model, visual)
    for _, o in model:GetDescendants() do
        if not o:IsDescendantOf(visual) then
            if o:IsA('BasePart') then
                if o.Name ~= 'VoidRiftPad' and o.Name ~= 'ResonanceFrostRing' then
                    o.LocalTransparencyModifier = 1
                    o.Transparency = 1
                    if o.Name == 'DummyFloorRing' then
                        o.CanCollide = false
                        o.CanQuery = false
                        o.CanTouch = false
                    end
                end
            elseif o:IsA('Decal') then
                o.Transparency = 1
            elseif o:IsA('Light') or o:IsA('ParticleEmitter') or o:IsA('Highlight') then
                o.Enabled = false
            end
        end
    end
end

local buildQueueBusy = false
local function acquireTemplateAndClips(visualAsset, scale)
    if not templates[visualAsset] then
        while buildQueueBusy do
            task.wait()
        end
        if not templates[visualAsset] then
            buildQueueBusy = true
            local okB, built = pcall(Renderer.Build, visualAsset)
            if okB and built then
                templates[visualAsset] = built
            end
            task.wait()
            buildQueueBusy = false
        end
    end
    local clips = getClips(visualAsset, scale)
    return templates[visualAsset], clips
end

local function register(model)
    if not model or not model:IsA('Model') then
        return
    end
    local enemyId = model:GetAttribute('EnemyId') or model.Name
    -- AureonSentinel inside ActiveBosses is already rigged & animated by DelegatedV5.client.lua
    if bossesFolder and model.Parent == bossesFolder and (enemyId == 'AureonSentinel' or model.Name == 'AureonSentinel') then
        return
    end
    local requestedAsset = model:GetAttribute('VisualAsset') or DEFAULT_VISUAL_ASSET[enemyId] or enemyId
    local visualAsset, usedFallback = resolveVisualAsset(requestedAsset)
    local element = model:GetAttribute('Element') or DEFAULT_ELEMENT[enemyId] or 'Sky'
    local clipMap = SUPPORTED[requestedAsset] or SUPPORTED[visualAsset]
    if not clipMap or actors[model] or pending[model] or not Sources:FindFirstChild(visualAsset) then
        return
    end
    pending[model] = true
    local ok, err = xpcall(function()
        local body = model:WaitForChild('Body', 5) or model:WaitForChild('Root', 2) or model.PrimaryPart
        if not body then
            return
        end
        for _, o in model:GetDescendants() do
            if o:IsA('BasePart') then
                o.LocalTransparencyModifier = 1
                o.Transparency = 1
            end
        end
        local scale = ASSET_SCALES[requestedAsset] or ASSET_SCALES[visualAsset] or 2.6
        local isBossOrSea = (bossesFolder ~= nil and model.Parent == bossesFolder)
            or scale >= 3.1
            or enemyId == 'AbyssalLeviathan'
            or enemyId == 'SkySeaBeast'
            or enemyId == 'TerrorSkyShark'
        local maxRenderDist = isBossOrSea and 1650 or 850
        while model.Parent and body.Parent do
            local cam = workspace.CurrentCamera
            local refPos = cam and cam.CFrame.Position or Vector3.new(-317.4, 50.5, 527.8)
            if (body.Position - refPos).Magnitude <= maxRenderDist then
                break
            end
            task.wait(0.45)
        end
        if not model.Parent or not body.Parent then
            return
        end
        local tmpl, clips = acquireTemplateAndClips(visualAsset, scale)
        if not model.Parent or not tmpl then
            return
        end
        local visual = templates[visualAsset]:Clone()
        visual.Name = enemyId .. '_BlenderVisual'
        visual:ScaleTo(scale)
        if visualAsset == 'NoxarVoidFX' then
            for _, part in visual:GetDescendants() do
                if part:IsA('BasePart') and part ~= visual.PrimaryPart then
                    part.Transparency = 0.28
                end
            end
        end
        local floorY = model:GetAttribute('EnemyFloorY') or (body.Position.Y - 2.5)
        visual:PivotTo(CFrame.new(body.Position.X, floorY, body.Position.Z) * body.CFrame.Rotation)

        local isBossOrSummon = (requestedAsset == 'Noxar' or requestedAsset == 'CryonPrime' or requestedAsset == 'NoxarVoidFX' or requestedAsset == 'CryonPillar' or requestedAsset == 'EnergyPylon')
        local mobAttachments = nil
        if not isBossOrSummon then
            mobAttachments = upgradeMob3D(visual, enemyId, requestedAsset, element, usedFallback)
        elseif requestedAsset == 'EnergyPylon' then
            for _, part in visual:GetDescendants() do
                if part:IsA('BasePart') and part ~= visual.PrimaryPart then
                    part.Color = Color3.fromRGB(255, 214, 88)
                end
            end
        elseif visualAsset == 'Noxar' then
            for _, part in visual:GetDescendants() do
                if part:IsA('BasePart') then
                    local bmat = tostring(part:GetAttribute('BlenderMaterial') or '')
                    if hasToken(bmat, 'ObsidianArmor') then
                        part.Color = Color3.fromRGB(58, 52, 76)
                        part.Material = Enum.Material.Metal
                        part.Reflectance = 0.24
                    elseif hasToken(bmat, 'HelmetObsidian') or hasToken(bmat, 'DarkIron') then
                        part.Color = Color3.fromRGB(82, 76, 106)
                        part.Material = Enum.Material.Metal
                        part.Reflectance = 0.28
                    elseif hasToken(bmat, 'ChainSteel') then
                        part.Color = Color3.fromRGB(168, 174, 196)
                        part.Material = Enum.Material.Metal
                        part.Reflectance = 0.32
                    elseif hasToken(bmat, 'DarkCloth') then
                        part.Color = Color3.fromRGB(68, 32, 58)
                        part.Material = Enum.Material.SmoothPlastic
                    end
                end
            end
        end
        visual.Parent = model
        hide(model, visual)
        local connection = model.DescendantAdded:Connect(function(o)
            if o:IsA('BasePart') and not o:IsDescendantOf(visual) then
                o.LocalTransparencyModifier = 1
                o.Transparency = 1
            end
        end)
        actors[model] = {
            Owner = model,
            EnemyId = enemyId,
            VisualAsset = visualAsset,
            RequestedAsset = requestedAsset,
            Element = element,
            MobAttachments = mobAttachments,
            ClipMap = clipMap,
            Visual = visual,
            Body = body,
            Clips = clips,
            Scale = scale,
            MaxRenderDist = maxRenderDist,
            IsSeaSwimmer = (enemyId == 'AbyssalLeviathan' or enemyId == 'SkySeaBeast' or enemyId == 'TerrorSkyShark' or visualAsset == 'AbyssalLeviathan' or visualAsset == 'SkySeaBeast'),
            Name = clipMap.Idle or 'Idle',
            Start = os.clock(),
            Until = 0,
            BossPhase = model:GetAttribute('BossPhase') or 1,
            Attack = model:GetAttribute('EnemyAttackAt') or 0,
            Hit = model:GetAttribute('EnemyHitAt') or 0,
            Summon = model:GetAttribute('CryonSummonAt') or 0,
            VoidFX = model:GetAttribute('NoxarFXAt') or 0,
            LastPosition = body.Position,
            Connection = connection,
            Rate = 1,
        }
        model:SetAttribute('BlenderEnemyReady', true)
        model:SetAttribute('BlenderVisualAsset', visualAsset)
    end, debug.traceback)
    pending[model] = nil
    if not ok then
        warn('[SKYBREAK enemy]', enemyId, visualAsset, err)
    end
end

folder.ChildAdded:Connect(function(o)
    task.spawn(register, o)
end)
if bossesFolder then
    bossesFolder.ChildAdded:Connect(function(o)
        task.spawn(register, o)
    end)
end
workspace.ChildAdded:Connect(function(ch)
    if ch.Name == 'ActiveBosses' and ch ~= bossesFolder then
        bossesFolder = ch
        ch.ChildAdded:Connect(function(o)
            task.spawn(register, o)
        end)
        for _, o in ch:GetChildren() do
            task.spawn(register, o)
        end
    end
end)
task.spawn(function()
    local waitUntil = os.clock() + 3.5
    while not workspace:GetAttribute('Sea1IslandsReady') and os.clock() < waitUntil do
        task.wait(0.05)
    end
    for _, o in folder:GetChildren() do
        task.spawn(register, o)
    end
    if bossesFolder then
        for _, o in bossesFolder:GetChildren() do
            task.spawn(register, o)
        end
    end
end)

-- 3D Animated Hub & Regional NPCs
local NPC_ASSETS = {
    Lyra = true,
    Kael = true,
    Chronos = true,
    DrVega = true,
    Zioles = true,
    ZiolesGachaNPC = true,
    AncientMonk = true,
    AncientMonkNPC = true,
    SkyShipwright = true,
    ShipwrightNPC = true,
    SkyShipwrightNPC = true,
    Male_SkyGuardian = true,
    Female_SkyGuardian = true,
    Male_Adventurer = true,
    Female_Adventurer = true,
    Male_Novice = true,
    Female_Novice = true,
    CelestialAetherGalleon = true,
    CelestialBrigantine = true,
    CyberEnforcerShip = true,
    CyberEnforcer = true,
    LeviathanHunterShip = true,
}

local function registerNPC(npcModel)
    if not npcModel:IsA('Model') or npcs[npcModel] or pendingNPCs[npcModel] then
        return
    end
    local mName = tostring(npcModel.Name or '')
    if mName:sub(1, 16) == 'SeparatedFruit3D' or mName:sub(1, 12) == 'HeroPedestal' or npcModel:GetAttribute('IsShowcase') == true then
        return
    end
    local npcId = npcModel:GetAttribute('NPCId') or npcModel:GetAttribute('VisualAsset') or npcModel.Name
    if not NPC_ASSETS[npcId] then
        return
    end
    local requestedAsset = npcModel:GetAttribute('VisualAsset') or DEFAULT_VISUAL_ASSET[npcId] or npcId
    local visualAsset, usedFallback = resolveVisualAsset(requestedAsset)
    if not Sources:FindFirstChild(visualAsset) then
        return
    end
    pendingNPCs[npcModel] = true
    local ok, err = xpcall(function()
        local body = npcModel.PrimaryPart
            or npcModel:WaitForChild('Body', 5)
            or npcModel:WaitForChild('Root', 2)
            or npcModel:FindFirstChildWhichIsA('BasePart')
        if not body then
            return
        end
        body.LocalTransparencyModifier = 1
        body.Transparency = 1
        while npcModel.Parent and body.Parent do
            local cam = workspace.CurrentCamera
            local refPos = cam and cam.CFrame.Position or Vector3.new(-317.4, 50.5, 527.8)
            if (body.Position - refPos).Magnitude <= 950 then
                break
            end
            task.wait(0.45)
        end
        if not npcModel.Parent or not body.Parent then
            return
        end
        local scale = tonumber(npcModel:GetAttribute('ShowcaseScale'))
            or ASSET_SCALES[requestedAsset]
            or ASSET_SCALES[visualAsset]
            or 2.6
        local tmpl, clips = acquireTemplateAndClips(visualAsset, scale)
        if not npcModel.Parent or not tmpl then
            return
        end
        local visual = tmpl:Clone()
        visual.Name = npcId .. '_BlenderNPCRig'
        visual:ScaleTo(scale)
        local extraY = tonumber(npcModel:GetAttribute('YOffset'))
            or ((visualAsset == 'AetherFruitsCollection1' or visualAsset == 'AetherFruitsCollection2') and (2.25 * scale) or 0)
        local floorY = (npcModel:GetAttribute('NPCFloorY')
            or npcModel:GetAttribute('EnemyFloorY')
            or (body.Position.Y - math.max(2.0, body.Size.Y * 0.5))) + extraY
        visual:PivotTo(CFrame.new(body.Position.X, floorY, body.Position.Z) * body.CFrame.Rotation)
        local mobAttachments = upgradeMob3D(visual, npcId, requestedAsset, 'Sky', usedFallback)
        visual.Parent = npcModel
        hide(npcModel, visual)

        local connection = npcModel.DescendantAdded:Connect(function(o)
            if o:IsA('BasePart') and not o:IsDescendantOf(visual) then
                o.LocalTransparencyModifier = 1
                o.Transparency = 1
            end
        end)

        -- Trigger NPC action clip when player interacts with ProximityPrompt
        local promptConns = {}
        for _, desc in npcModel:GetDescendants() do
            if desc:IsA('ProximityPrompt') then
                table.insert(promptConns, desc.Triggered:Connect(function()
                    npcModel:SetAttribute('NPCTalkAt', os.clock())
                end))
            end
        end

        local clipMap = SUPPORTED[requestedAsset] or SUPPORTED[visualAsset] or { Idle = 'Idle', Attack = 'Attack', Heavy = 'Heavy' }
        npcs[npcModel] = {
            Owner = npcModel,
            NPCId = npcId,
            VisualAsset = visualAsset,
            RequestedAsset = requestedAsset,
            MobAttachments = mobAttachments,
            ClipMap = clipMap,
            Visual = visual,
            Body = body,
            Clips = clips,
            Scale = scale,
            ExtraY = extraY,
            Name = clipMap.Idle or 'Idle',
            Start = os.clock(),
            Until = 0,
            TalkAt = npcModel:GetAttribute('NPCTalkAt') or 0,
            NextGestureAt = os.clock() + math.random(4, 8),
            Connection = connection,
            PromptConns = promptConns,
            Rate = 1,
        }
        npcModel:SetAttribute('BlenderNPCReady', true)
        npcModel:SetAttribute('BlenderEnemyReady', true)
    end, debug.traceback)
    pendingNPCs[npcModel] = nil
    if not ok then
        warn('[SKYBREAK npc]', npcModel.Name, visualAsset, err)
    end
end

local boundWorldFolders = {}
local function bindNPCWorldFolder(worldFolder)
    if not worldFolder or boundWorldFolders[worldFolder] then
        return
    end
    boundWorldFolders[worldFolder] = true
    worldFolder.ChildAdded:Connect(function(o)
        task.spawn(registerNPC, o)
    end)
    task.spawn(function()
        local waitUntil = os.clock() + 3.5
        while not workspace:GetAttribute('Sea1IslandsReady') and os.clock() < waitUntil do
            task.wait(0.05)
        end
        for idx, o in ipairs(worldFolder:GetChildren()) do
            task.spawn(registerNPC, o)
            if idx % 6 == 0 then
                task.wait(0.02)
            end
        end
    end)
end

task.spawn(function()
    for _, fName in ipairs({ 'SkybreakWorldObjects', 'ActiveNPCs', 'GrandAssetShowcase' }) do
        local existing = workspace:FindFirstChild(fName)
        if existing then
            bindNPCWorldFolder(existing)
        end
    end
    local wObj = workspace:WaitForChild('SkybreakWorldObjects', 10)
    if wObj then
        bindNPCWorldFolder(wObj)
    end
    local showcase = workspace:FindFirstChild('GrandAssetShowcase') or workspace:WaitForChild('GrandAssetShowcase', 10)
    if showcase then
        bindNPCWorldFolder(showcase)
    end
end)
workspace.ChildAdded:Connect(function(child)
    if child.Name == 'SkybreakWorldObjects' or child.Name == 'ActiveNPCs' or child.Name == 'GrandAssetShowcase' then
        bindNPCWorldFolder(child)
    end
end)

-- 3D AI Companions (workspace.ActiveCompanions — Kairo, Lumen, Nyx)
local function buildCompanionFootRing(visual)
    local ringFolder = Instance.new('Folder')
    ringFolder.Name = 'CompanionFootRing'
    ringFolder.Parent = visual

    local motes = {}
    for i = 1, 3 do
        local mote = Instance.new('Part')
        mote.Name = 'CompanionStarMote_' .. i
        mote.Size = Vector3.new(0.14, 0.24, 0.14)
        mote.Color = i % 2 == 0 and Color3.fromRGB(75, 165, 195) or Color3.fromRGB(185, 155, 72)
        mote.Material = Enum.Material.SmoothPlastic
        mote.Transparency = 0.72
        mote.Anchored = true
        mote.CanCollide = false
        mote.CanQuery = false
        mote.CanTouch = false
        mote.Massless = true
        mote.Parent = ringFolder
        table.insert(motes, mote)
    end

    return { Motes = motes }
end

local function registerCompanion(compModel)
    if compModel then
        pcall(function()
            compModel:Destroy()
        end)
    end
end

local boundCompanionsFolder = nil
local function bindCompanionsFolder(compFolder)
    if not compFolder or boundCompanionsFolder == compFolder then
        return
    end
    boundCompanionsFolder = compFolder
    compFolder.ChildAdded:Connect(function(o)
        task.spawn(registerCompanion, o)
    end)
    for _, o in compFolder:GetChildren() do
        task.spawn(registerCompanion, o)
    end
end

task.spawn(function()
    local existing = workspace:FindFirstChild('ActiveCompanions') or workspace:WaitForChild('ActiveCompanions', 10)
    if existing then
        bindCompanionsFolder(existing)
    end
end)
workspace.ChildAdded:Connect(function(child)
    if child.Name == 'ActiveCompanions' then
        bindCompanionsFolder(child)
    end
end)

-- 3D Blender Warship Client Renderer & Sky Crew Fleet Banner (#114)
local SHIP_MESH_ALIASES = {
    CelestialAetherGalleon = 'CelestialAetherGalleon',
    CelestialBrigantine = 'CelestialAetherGalleon',
    Brigantine = 'CelestialAetherGalleon',
    AetherGalleon = 'CelestialAetherGalleon',
    Galleon = 'CelestialAetherGalleon',
    SkyGalleon = 'CelestialAetherGalleon',
    CyberEnforcerShip = 'CyberEnforcerShip',
    CyberEnforcer = 'CyberEnforcerShip',
    EnforcerShip = 'CyberEnforcerShip',
    LeviathanHunterShip = 'LeviathanHunterShip',
    LeviathanHunter = 'LeviathanHunterShip',
    HunterShip = 'LeviathanHunterShip',
}

local SHIP_BANNER_ACCENTS = {
    CelestialAetherGalleon = Color3.fromRGB(238, 192, 84),
    CyberEnforcerShip = Color3.fromRGB(88, 224, 248),
    LeviathanHunterShip = Color3.fromRGB(192, 108, 248),
}

local function resolveShipMeshId(shipModel)
    local raw = tostring(
        shipModel:GetAttribute('ShipMeshId')
        or shipModel:GetAttribute('VisualAsset')
        or shipModel:GetAttribute('ShipId')
        or shipModel:GetAttribute('NPCId')
        or 'CelestialAetherGalleon'
    )
    local mapped = SHIP_MESH_ALIASES[raw]
    if not mapped then
        local lower = raw:lower()
        if lower:find('cyber') or lower:find('enforcer') then
            mapped = 'CyberEnforcerShip'
        elseif lower:find('leviathan') or lower:find('hunter') then
            mapped = 'LeviathanHunterShip'
        else
            mapped = 'CelestialAetherGalleon'
        end
    end
    if not Sources:FindFirstChild(mapped) then
        mapped = 'CelestialAetherGalleon'
    end
    return mapped
end

local function shouldHideServerShipPart(part, visual, bannerFolder)
    if not part:IsA('BasePart') then
        return false
    end
    if (visual and part:IsDescendantOf(visual)) or (bannerFolder and part:IsDescendantOf(bannerFolder)) then
        return false
    end
    local n = part.Name:lower()
    if n:find('cannon') or n:find('turret') or n:find('muzzle') or n:find('proj') or n:find('fx') then
        return false
    end
    return true
end

local function formatCrewLabel(shipModel)
    local crew = tostring(shipModel:GetAttribute('CrewName') or ''):gsub('^%s+', ''):gsub('%s+$', '')
    if crew == '' then
        local captain = tostring(shipModel:GetAttribute('CaptainName') or shipModel:GetAttribute('OwnerName') or '')
        if captain ~= '' then
            crew = captain:upper() .. ' FLEET'
        else
            crew = 'SKYBORN FLEET'
        end
    end
    return '[SKY CREW] • ' .. crew
end

local function buildShipCrewBanner(shipModel, shipMeshId)
    local accent = SHIP_BANNER_ACCENTS[shipMeshId] or Color3.fromRGB(238, 192, 84)
    local bannerFolder = Instance.new('Folder')
    bannerFolder.Name = 'CrewFleetBanner3D'
    bannerFolder.Parent = shipModel

    local function makeBannerPart(name, size, color, material)
        local p = Instance.new('Part')
        p.Name = name
        p.Size = size
        p.Color = color
        p.Material = material or Enum.Material.SmoothPlastic
        p.Anchored = true
        p.CanCollide = false
        p.CanQuery = false
        p.CanTouch = false
        p.Massless = true
        p.CastShadow = false
        p.Parent = bannerFolder
        return p
    end

    local mast = makeBannerPart('BannerMastPole', Vector3.new(0.28, 7.6, 0.28), Color3.fromRGB(28, 34, 48), Enum.Material.Metal)
    local crossbar = makeBannerPart('BannerCrossbar', Vector3.new(0.24, 0.24, 4.4), accent, Enum.Material.Metal)
    local finial = makeBannerPart('BannerFinial', Vector3.new(0.55, 0.55, 0.55), accent, Enum.Material.SmoothPlastic)
    finial.Shape = Enum.PartType.Ball

    local panels = {}
    local clothColors = {
        Color3.fromRGB(16, 22, 38),
        Color3.fromRGB(20, 28, 48),
        accent,
    }
    for i = 1, 3 do
        local seg = makeBannerPart(
            'BannerCloth_' .. i,
            Vector3.new(0.10, 2.2 - (i - 1) * 0.18, 1.38),
            clothColors[i],
            Enum.Material.Fabric
        )
        panels[i] = seg
    end

    local bill = Instance.new('BillboardGui')
    bill.Name = 'SkyCrewBannerGui'
    bill.Size = UDim2.fromOffset(230, 42)
    bill.StudsOffset = Vector3.new(0, 4.6, 0)
    bill.AlwaysOnTop = false
    bill.MaxDistance = 190
    bill.Parent = mast

    local bg = Instance.new('Frame')
    bg.Name = 'Badge'
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundColor3 = Color3.fromRGB(10, 14, 26)
    bg.BackgroundTransparency = 0.14
    bg.BorderSizePixel = 0
    bg.Parent = bill

    local corner = Instance.new('UICorner')
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = bg

    local stroke = Instance.new('UIStroke')
    stroke.Color = accent
    stroke.Thickness = 1.5
    stroke.Transparency = 0.15
    stroke.Parent = bg

    local lbl = Instance.new('TextLabel')
    lbl.Name = 'CrewLabel'
    lbl.Size = UDim2.new(1, -14, 1, -4)
    lbl.Position = UDim2.fromOffset(7, 2)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextColor3 = accent
    lbl.TextStrokeTransparency = 0.35
    lbl.TextTruncate = Enum.TextTruncate.AtEnd
    lbl.Text = formatCrewLabel(shipModel)
    lbl.Parent = bg

    return {
        Folder = bannerFolder,
        Mast = mast,
        Crossbar = crossbar,
        Finial = finial,
        Panels = panels,
        Label = lbl,
    }
end

local function registerShip(shipModel)
    if not shipModel:IsA('Model') or activeShips[shipModel] or pendingShips[shipModel] then
        return
    end
    pendingShips[shipModel] = true
    local shipMeshId = resolveShipMeshId(shipModel)
    local ok, err = xpcall(function()
        local hullRoot = shipModel.PrimaryPart
            or shipModel:FindFirstChild('HullRoot')
            or shipModel:FindFirstChild('Body')
            or shipModel:WaitForChild('HullRoot', 5)
            or shipModel.PrimaryPart
            or shipModel:FindFirstChildWhichIsA('BasePart')
        if not hullRoot or not shipModel.Parent then
            return
        end

        templates[shipMeshId] = templates[shipMeshId] or Renderer.Build(shipMeshId)
        local tmpl = templates[shipMeshId]
        if not tmpl or not shipModel.Parent then
            return
        end

        local scale = tonumber(shipModel:GetAttribute('ShipScale') or shipModel:GetAttribute('ShowcaseScale'))
            or ASSET_SCALES[shipMeshId]
            or 4.2
        local visual = tmpl:Clone()
        visual.Name = shipMeshId .. '_BlenderShipVisual'
        visual:ScaleTo(scale)

        for _, desc in ipairs(visual:GetDescendants()) do
            if desc:IsA('WeldConstraint') then
                desc:Destroy()
            elseif desc:IsA('BasePart') then
                desc.Anchored = true
                desc.CanCollide = false
                desc.CanQuery = false
                desc.CanTouch = false
                desc.Massless = true
                desc.CastShadow = false
            end
        end

        visual:PivotTo(CFrame.identity)
        local boxCF, boxSize = visual:GetBoundingBox()
        local yAdjust = tonumber(shipModel:GetAttribute('ShipYOffset')) or 0
        local centerOffset = CFrame.new(-boxCF.Position.X, -boxCF.Position.Y + boxSize.Y * 0.16 + yAdjust, -boxCF.Position.Z)
        local yawDeg = tonumber(shipModel:GetAttribute('ShipYawOffsetDeg')) or 0
        local localAlignCF = CFrame.Angles(0, math.rad(yawDeg), 0) * centerOffset

        local banner = buildShipCrewBanner(shipModel, shipMeshId)
        visual:PivotTo(hullRoot.CFrame * localAlignCF)
        visual.Parent = shipModel

        for _, desc in ipairs(shipModel:GetDescendants()) do
            if shouldHideServerShipPart(desc, visual, banner.Folder) then
                desc.LocalTransparencyModifier = 1
            end
        end

        local descConn = shipModel.DescendantAdded:Connect(function(o)
            if shouldHideServerShipPart(o, visual, banner.Folder) then
                o.LocalTransparencyModifier = 1
            end
        end)
        local function refreshBannerLabel()
            if banner and banner.Label and banner.Label.Parent then
                banner.Label.Text = formatCrewLabel(shipModel)
            end
        end
        local attrConns = {
            shipModel:GetAttributeChangedSignal('CrewName'):Connect(refreshBannerLabel),
            shipModel:GetAttributeChangedSignal('CaptainName'):Connect(refreshBannerLabel),
            shipModel:GetAttributeChangedSignal('OwnerName'):Connect(refreshBannerLabel),
        }

        local mastHeightOffset = Vector3.new(0, math.clamp(boxSize.Y * 0.62, 10.5, 22.0), math.clamp(boxSize.Z * 0.18, 2.5, 9.0))
        activeShips[shipModel] = {
            Model = shipModel,
            HullRoot = hullRoot,
            ShipMeshId = shipMeshId,
            Visual = visual,
            LocalAlignCF = localAlignCF,
            Banner = banner,
            MastOffset = mastHeightOffset,
            Phase = math.random() * math.pi * 2,
            SmoothCF = hullRoot.CFrame,
            DescConn = descConn,
            AttrConns = attrConns,
        }
        shipModel:SetAttribute('BlenderShipReady', true)
        shipModel:SetAttribute('BlenderShipAsset', shipMeshId)
    end, debug.traceback)
    pendingShips[shipModel] = nil
    if not ok then
        warn('[SKYBREAK ship]', shipModel.Name, shipMeshId, err)
    end
end

local boundShipFolders = {}
local function bindActiveShipsFolder(shipsFolder)
    if not shipsFolder or boundShipFolders[shipsFolder] then
        return
    end
    boundShipFolders[shipsFolder] = true
    shipsFolder.ChildAdded:Connect(function(o)
        task.spawn(registerShip, o)
    end)
    for _, o in ipairs(shipsFolder:GetChildren()) do
        task.spawn(registerShip, o)
    end
end

task.spawn(function()
    local existing = workspace:FindFirstChild('ActiveShips') or workspace:WaitForChild('ActiveShips', 30)
    if existing then
        bindActiveShipsFolder(existing)
    end
end)
workspace.ChildAdded:Connect(function(child)
    if child.Name == 'ActiveShips' then
        bindActiveShipsFolder(child)
    end
end)


local surfaceRayParams = RaycastParams.new()
surfaceRayParams.FilterType = Enum.RaycastFilterType.Include
local lastFilterRefresh = 0

local REALM_FLOOR_SOURCES = {
    'GrandSkyIslands', 'GrandSkyIslands_Collision', 'Worlds',
    'GoldenSky', 'GoldenSky_ImportedArt',
    'FrozenCyber', 'FrozenCyber_ImportedArt',
    'ShadowRealm', 'ShadowRealm_ImportedArt',
    'VerdantCrown', 'VerdantCrown_ImportedArt',
    'EmberforgeWastes', 'EmberforgeWastes_ImportedArt',
    'AbyssalTides', 'AbyssalTides_ImportedArt',
    'ChronosBastion', 'ChronosBastion_ImportedArt',
    'VeilsEnd', 'VeilsEnd_ImportedArt',
}

local function snapFloorYTo3D(s, x, baseFloorY, z, now)
    if s.CachedFloorY and s.CachedX and math.abs(x - s.CachedX) < 1.2 and math.abs(z - s.CachedZ) < 1.2 and math.abs(baseFloorY - (s.CachedBaseY or baseFloorY)) < 1.5 then
        return s.CachedFloorY
    end
    if now - lastFilterRefresh > 4.0 then
        lastFilterRefresh = now
        local list = {}
        for _, name in ipairs(REALM_FLOOR_SOURCES) do
            local inst = workspace:FindFirstChild(name)
            if inst then
                table.insert(list, inst)
            end
        end
        surfaceRayParams.FilterDescendantsInstances = list
    end
    local hit = workspace:Raycast(Vector3.new(x, baseFloorY + 6.5, z), Vector3.new(0, -16, 0), surfaceRayParams)
    local resolved = baseFloorY
    if hit and hit.Instance and hit.Instance.CanCollide and math.abs(hit.Position.Y - baseFloorY) <= 5.5 then
        resolved = hit.Position.Y
    end
    s.CachedFloorY = resolved
    s.CachedBaseY = baseFloorY
    s.CachedX = x
    s.CachedZ = z
    s.CachedAt = now
    return resolved
end

Run.Heartbeat:Connect(function(dt)
    dt = math.clamp(dt, 1 / 240, 0.15)
    local now = os.clock()
    local cam = workspace.CurrentCamera
    local camPos = cam and cam.CFrame.Position or nil

    for model, s in actors do
        if not model.Parent or not s.Body or not s.Body.Parent then
            s.Connection:Disconnect()
            if s.Visual then
                s.Visual:Destroy()
            end
            actors[model] = nil
            continue
        end
        local bodyPos = s.Body.Position
        local camDist = camPos and (bodyPos - camPos).Magnitude or 0
        local maxDist = s.MaxRenderDist or 240
        if camDist > maxDist then
            continue
        elseif camDist > (maxDist * 0.42) then
            if now < (s.NextFarStep or 0) then
                continue
            end
            s.NextFarStep = now + 0.08
        end

        local frameDist = (bodyPos - s.LastPosition).Magnitude
        if frameDist > 0.015 then
            s.LastPosition = bodyPos
            s.LastMoveAt = now
        end
        local attrMoving = model:GetAttribute('EnemyMoving')
        local moving = if attrMoving ~= nil then attrMoving else ((now - (s.LastMoveAt or 0)) < 0.28)

        local attack = model:GetAttribute('EnemyAttackAt') or 0
        local bossPhase = model:GetAttribute('BossPhase') or 1
        local event = model:GetAttribute('CryonSummonAt') or 0
        if event ~= s.Summon then
            s.Summon = event
            task.spawn(summon, s)
        end
        local fxEvent = model:GetAttribute('NoxarFXAt') or 0
        if fxEvent ~= s.VoidFX then
            s.VoidFX = fxEvent
            task.spawn(summonVoidFX, s, model:GetAttribute('NoxarPhaseFX'))
        end
        local hit = model:GetAttribute('EnemyHitAt') or 0
        if model:GetAttribute('EnemyDead') then
            local deathKey = (s.ClipMap and s.ClipMap.Death) or 'Death'
            if s.Name ~= deathKey then
                s.Name = deathKey
                s.Start = now
                s.Rate = 1
            end
        elseif bossPhase ~= (s.BossPhase or 1) then
            s.BossPhase = bossPhase
            local awakenClip = (s.Clips and s.Clips.UltimateAwakening and 'UltimateAwakening')
                or (s.ClipMap and s.ClipMap.Heavy)
                or 'Heavy'
            s.Name = awakenClip
            s.Start = now
            local clipObj = resolveClip(s.Clips, s.ClipMap, s.Name)
            local duration = 1.65
            s.Rate = (clipObj and clipObj.Duration > 0) and (clipObj.Duration / duration) or 1
            s.Until = now + duration
        elseif attack ~= s.Attack then
            s.Attack = attack
            s.AttackCount = (s.AttackCount or 0) + 1
            local explicitClip = model:GetAttribute('EnemyAttackClip')
            local reqClip = explicitClip
            if not reqClip or reqClip == '' then
                if s.Clips and s.AttackCount % 6 == 0 and s.Clips.UltimateAwakening then
                    reqClip = 'UltimateAwakening'
                elseif s.Clips and s.AttackCount % 4 == 0 and s.Clips.HeroicKata then
                    reqClip = 'HeroicKata'
                elseif s.Clips and s.AttackCount % 3 == 0 and s.Clips.Heavy then
                    reqClip = 'Heavy'
                else
                    local comboKey = string.format('Attack0%d', ((s.AttackCount - 1) % 3) + 1)
                    if s.Clips and s.Clips[comboKey] then
                        reqClip = comboKey
                    else
                        reqClip = (s.ClipMap and s.ClipMap.Attack) or 'Attack'
                    end
                end
            end
            s.Name = reqClip
            s.Start = now
            local clipObj = resolveClip(s.Clips, s.ClipMap, s.Name)
            local duration = model:GetAttribute('EnemyAttackDuration') or (clipObj and clipObj.Duration) or 0.85
            s.Rate = (clipObj and clipObj.Duration > 0) and (clipObj.Duration / duration) or 1
            s.Until = now + duration
        elseif hit ~= s.Hit and now >= s.Until then
            s.Hit = hit
            local hitKey = (s.ClipMap and s.ClipMap.Hit) or 'HitReact'
            local clipObj = resolveClip(s.Clips, s.ClipMap, hitKey)
            s.Name = hitKey
            s.Start = now
            s.Rate = 1
            s.Until = now + ((clipObj and clipObj.Duration) or 0.5)
        elseif now >= s.Until then
            local name = moving and ((s.ClipMap and s.ClipMap.Run) or 'Run') or ((s.ClipMap and s.ClipMap.Idle) or 'Idle')
            if s.Name ~= name then
                s.Name = name
                s.Start = now
                s.Rate = 1
            end
        end
        -- Do not replay stale hits after an attack finishes.
        s.Hit = hit
        local halfBodyY = math.max(2.5, s.Body.Size.Y * 0.5)
        local rawFloorY = s.IsSeaSwimmer and (bodyPos.Y - halfBodyY) or (model:GetAttribute('EnemyFloorY') or (bodyPos.Y - halfBodyY))
        local floorY = s.IsSeaSwimmer and rawFloorY or snapFloorYTo3D(s, bodyPos.X, rawFloorY, bodyPos.Z, now)
        local floorPos = Vector3.new(bodyPos.X, floorY, bodyPos.Z)
        local targetRot = s.Body.CFrame.Rotation
        if not s.SmoothPos or (floorPos - s.SmoothPos).Magnitude > 24 then
            s.SmoothPos = floorPos
            s.SmoothRot = targetRot
        else
            local posAlpha = 1 - math.exp(-16 * dt)
            local rotAlpha = 1 - math.exp(-14 * dt)
            s.SmoothPos = s.SmoothPos:Lerp(floorPos, posAlpha)
            s.SmoothRot = s.SmoothRot:Lerp(targetRot, rotAlpha)
        end
        s.Visual:PivotTo(CFrame.new(s.SmoothPos) * s.SmoothRot)
        if camDist <= 95 or now >= (s.NextPoseAt or 0) then
            s.NextPoseAt = now + 0.032
            local activeClip = resolveClip(s.Clips, s.ClipMap, s.Name)
            Renderer.Pose(s.Visual, activeClip, (now - s.Start) * s.Rate)
        end
        if s.MobAttachments then
            stepMobAttachments(s.MobAttachments, now)
        end
        if s.LastReportedClip ~= s.Name then
            s.LastReportedClip = s.Name
            model:SetAttribute('BlenderEnemyClip', s.Name)
        end
    end

    for npcModel, s in npcs do
        if not npcModel.Parent or not s.Body.Parent then
            s.Connection:Disconnect()
            if s.PromptConns then
                for _, pc in ipairs(s.PromptConns) do
                    pc:Disconnect()
                end
            end
            if s.Visual then
                s.Visual:Destroy()
            end
            npcs[npcModel] = nil
            continue
        end
        local bodyPos = s.Body.Position
        local camDist = camPos and (bodyPos - camPos).Magnitude or 0
        if camPos then
            if camDist > 950 then
                continue
            elseif camDist > 260 then
                if now < (s.NextFarStep or 0) then
                    continue
                end
                s.NextFarStep = now + 0.06
            end
        end
        local talkAt = npcModel:GetAttribute('NPCTalkAt') or 0
        if talkAt ~= s.TalkAt then
            s.TalkAt = talkAt
            local actionKey = (s.Clips and s.Clips.Wave and 'Wave')
                or (s.Clips and s.Clips.Talk and 'Talk')
                or (s.ClipMap and s.ClipMap.Attack)
                or 'Idle'
            s.Name = actionKey
            s.Start = now
            s.Rate = 1
            local clipObj = resolveClip(s.Clips, s.ClipMap, s.Name)
            s.Until = now + ((clipObj and clipObj.Duration) or 1.6)
            s.NextGestureAt = s.Until + math.random(5, 9)
        elseif now >= s.Until and now >= (s.NextGestureAt or 0) then
            local gestureKey = nil
            local va = tostring(s.VisualAsset or s.NPCId or '')
            if s.Clips then
                if (va == 'Kael' or va == 'SkyShipwright' or va == 'ShipwrightNPC' or va == 'SkyShipwrightNPC') and s.Clips.HammerWork then
                    gestureKey = (math.random(1, 2) == 1 and s.Clips.InspectOre) and 'InspectOre' or 'HammerWork'
                elseif (va == 'AncientMonk' or va == 'AncientMonkNPC') and s.Clips.Meditate then
                    gestureKey = 'Meditate'
                elseif s.Clips.Talk and s.Clips.Wave then
                    gestureKey = (math.random(1, 2) == 1) and 'Talk' or 'Wave'
                elseif s.Clips.Wave then
                    gestureKey = 'Wave'
                elseif s.Clips.HeroicKata then
                    gestureKey = 'HeroicKata'
                end
            end
            if gestureKey and s.Clips[gestureKey] then
                s.Name = gestureKey
                s.Start = now
                s.Rate = 1
                s.Until = now + (s.Clips[gestureKey].Duration or 1.8)
            end
            s.NextGestureAt = now + math.random(6, 11)
        elseif now >= s.Until then
            local idleKey = (s.ClipMap and s.ClipMap.Idle) or 'Idle'
            if s.Name ~= idleKey then
                s.Name = idleKey
                s.Start = now
                s.Rate = 1
            end
        end
        local rawFloorY = (npcModel:GetAttribute('NPCFloorY')
            or npcModel:GetAttribute('EnemyFloorY')
            or (bodyPos.Y - math.max(2.0, s.Body.Size.Y * 0.5)))
        local snappedY = snapFloorYTo3D(s, bodyPos.X, rawFloorY, bodyPos.Z, now)
        if npcModel:GetAttribute('PreserveDaisY') == true then
            snappedY = math.max(rawFloorY, snappedY)
        end
        local isFruit = tostring(s.VisualAsset or ''):sub(1, 6) == 'Fruit_'
        local floorY = snappedY + (s.ExtraY or 0) + (isFruit and 0.85 or 0)
        local floorPos = Vector3.new(bodyPos.X, floorY, bodyPos.Z)
        if not s.LastPivotPos or (floorPos - s.LastPivotPos).Magnitude > 0.02 then
            s.LastPivotPos = floorPos
            s.Visual:PivotTo(CFrame.new(floorPos) * s.Body.CFrame.Rotation)
        end
        if camDist <= 85 or now >= (s.NextPoseAt or 0) then
            s.NextPoseAt = now + 0.036
            local activeClip = resolveClip(s.Clips, s.ClipMap, s.Name)
            if activeClip and activeClip.Names and #activeClip.Names > 0 then
                Renderer.Pose(s.Visual, activeClip, (now - s.Start) * s.Rate)
            end
        end
        if s.MobAttachments then
            stepMobAttachments(s.MobAttachments, now)
        end
        if s.LastReportedClip ~= s.Name then
            s.LastReportedClip = s.Name
            npcModel:SetAttribute('BlenderNPCClip', s.Name)
        end
    end

    for compModel, s in companions do
        if not compModel.Parent or not s.Body.Parent then
            s.Connection:Disconnect()
            if s.Visual then
                s.Visual:Destroy()
            end
            companions[compModel] = nil
            continue
        end
        local bodyPos = s.Body.Position
        local frameDist = (bodyPos - s.LastPosition).Magnitude
        if frameDist > 0.015 then
            s.LastPosition = bodyPos
            s.LastMoveAt = now
        end
        local movingByPos = (now - (s.LastMoveAt or 0)) < 0.28
        local cState = tostring(compModel:GetAttribute('CompanionState') or '')
        local nonce = compModel:GetAttribute('CompanionAttackNonce') or compModel:GetAttribute('EnemyAttackAt') or 0

        local isStriker = (s.VisualAsset == 'ThunderStrikerFemale' or s.VisualAsset == 'ThunderStriker')
        local isMage = (s.VisualAsset == 'ArcaneMage')

        if nonce ~= s.AttackNonce or (cState == 'Attack' and now >= s.Until) then
            s.AttackNonce = nonce
            s.AttackCount += 1
            local atkName
            if s.Clips and s.AttackCount % 5 == 0 and s.Clips.UltimateAwakening then
                atkName = 'UltimateAwakening'
            elseif s.Clips and s.AttackCount % 3 == 0 and s.Clips.HeroicKata then
                atkName = 'HeroicKata'
            elseif s.Clips and s.AttackCount % 2 == 0 and s.Clips.ElementalSurge then
                atkName = 'ElementalSurge'
            elseif isMage then
                atkName = (s.AttackCount % 3 == 0 and s.Clips.ArcaneCircle) and 'ArcaneCircle' or 'FrostBolt'
            elseif isStriker then
                atkName = (s.AttackCount % 4 == 0) and 'TS_Dash' or 'TS_DaggerCombo'
            else
                atkName = (s.AttackCount % 3 == 0) and 'GoldenKnight_Heavy' or 'GoldenKnight_Attack'
            end
            local clipObj = resolveClip(s.Clips, nil, atkName)
            local duration = 0.85
            s.Name = atkName
            s.Start = now
            s.Rate = (clipObj and clipObj.Duration > 0) and (clipObj.Duration / duration) or 1
            s.Until = now + duration
        elseif now >= s.Until then
            local moving = (cState == 'Run' or cState == 'Chase' or cState == 'Follow' or movingByPos)
            local desired
            if isStriker then
                desired = moving and 'TS_Run' or 'TS_Idle'
            elseif isMage then
                desired = moving and 'Run' or 'Idle'
            else
                desired = moving and 'GoldenKnight_Run' or 'GoldenKnight_Idle'
            end
            if s.Name ~= desired then
                s.Name = desired
                s.Start = now
                s.Rate = 1
            end
        end

        local floorY = compModel:GetAttribute('CompanionFloorY')
            or compModel:GetAttribute('EnemyFloorY')
            or (bodyPos.Y - math.max(2.0, s.Body.Size.Y * 0.5))
        local floorPos = Vector3.new(bodyPos.X, floorY, bodyPos.Z)
        local targetRot = s.Body.CFrame.Rotation
        if not s.SmoothPos or (floorPos - s.SmoothPos).Magnitude > 24 then
            s.SmoothPos = floorPos
            s.SmoothRot = targetRot
        else
            local posAlpha = 1 - math.exp(-16 * dt)
            local rotAlpha = 1 - math.exp(-14 * dt)
            s.SmoothPos = s.SmoothPos:Lerp(floorPos, posAlpha)
            s.SmoothRot = s.SmoothRot:Lerp(targetRot, rotAlpha)
        end
        s.Visual:PivotTo(CFrame.new(s.SmoothPos) * s.SmoothRot)
        if s.FootRing and s.FootRing.Motes then
            for i, mote in ipairs(s.FootRing.Motes) do
                if mote and mote.Parent then
                    local ang = now * 1.9 + (i - 1) * (2 * math.pi / #s.FootRing.Motes)
                    local yOff = 2.25 + math.sin(now * 2.8 + i) * 0.25
                    local p = s.SmoothPos + Vector3.new(math.cos(ang) * 1.65, yOff, math.sin(ang) * 1.65)
                    mote.CFrame = CFrame.new(p) * CFrame.Angles(0.35, -ang, math.pi * 0.25)
                end
            end
        end
        local activeClip = resolveClip(s.Clips, nil, s.Name)
        Renderer.Pose(s.Visual, activeClip, (now - s.Start) * s.Rate)
        if s.LastReportedClip ~= s.Name then
            s.LastReportedClip = s.Name
            compModel:SetAttribute('BlenderCompanionClip', s.Name)
        end
    end

    for i = #pillars, 1, -1 do
        local p = pillars[i]
        local t = now - p.Start
        if t > 6 then
            p.Visual:Destroy()
            table.remove(pillars, i)
        else
            local name = t < 1 and 'Rise' or (t < 4.5 and 'Hover' or 'Collapse')
            local clip = resolveClip(p.Clips, SUPPORTED.CryonPillar, name)
            Renderer.Pose(p.Visual, clip, t - (name == 'Rise' and 0 or (name == 'Hover' and 1 or 4.5)))
        end
    end

    for i = #voidfx, 1, -1 do
        local fx = voidfx[i]
        local t = now - fx.Start
        if t > fx.Duration then
            fx.Visual:Destroy()
            table.remove(voidfx, i)
        else
            Renderer.Pose(fx.Visual, fx.Clip, t)
        end
    end

    local skyMdl = workspace:FindFirstChild('GoldenSky')
    if skyMdl then
        for sIdx = 1, 3 do
            local st = skyMdl:FindFirstChild('Station' .. sIdx .. '_3DModel')
            if st then
                local outer = st:FindFirstChild('AetherCrystalOuter')
                local inner = st:FindFirstChild('AetherCrystalInner')
                local base = st:FindFirstChild('BasePlinth')
                if outer and base then
                    local bob = math.sin(now * 2.2 + sIdx * 1.4) * 0.22
                    local center = Vector3.new(base.Position.X, base.Position.Y + 4.0 + bob, base.Position.Z)
                    local spinCF = CFrame.new(center) * CFrame.Angles(math.rad(35), now * 1.35 + sIdx, math.rad(35))
                    outer.CFrame = spinCF
                    if inner then
                        inner.CFrame = CFrame.new(center) * CFrame.Angles(math.rad(-35), -now * 1.85 + sIdx, math.rad(35))
                    end
                end
            end
        end
    end

    for shipModel, s in activeShips do
        if not shipModel.Parent or not s.HullRoot or not s.HullRoot.Parent then
            if s.DescConn then
                s.DescConn:Disconnect()
            end
            if s.AttrConns then
                for _, ac in ipairs(s.AttrConns) do
                    ac:Disconnect()
                end
            end
            if s.Visual then
                s.Visual:Destroy()
            end
            if s.Banner and s.Banner.Folder then
                s.Banner.Folder:Destroy()
            end
            activeShips[shipModel] = nil
            continue
        end

        local targetCF = s.HullRoot.CFrame
        if not s.SmoothCF or (targetCF.Position - s.SmoothCF.Position).Magnitude > 48 then
            s.SmoothCF = targetCF
        else
            local followAlpha = 1 - math.exp(-18 * dt)
            s.SmoothCF = s.SmoothCF:Lerp(targetCF, followAlpha)
        end

        local wavePitch = math.sin(now * 1.38 + s.Phase) * 0.024
        local waveRoll = math.cos(now * 1.08 + s.Phase * 1.3) * 0.030
        local waveHeave = math.sin(now * 1.62 + s.Phase * 0.7) * 0.28
        local bobbedRootCF = s.SmoothCF * CFrame.new(0, waveHeave, 0) * CFrame.Angles(wavePitch, 0, waveRoll)

        if s.Visual and s.Visual.Parent then
            s.Visual:PivotTo(bobbedRootCF * s.LocalAlignCF)
        end

        local banner = s.Banner
        if banner and banner.Mast and banner.Mast.Parent then
            local mastBaseCF = bobbedRootCF * CFrame.new(s.MastOffset)
            banner.Mast.CFrame = mastBaseCF
            banner.Finial.CFrame = mastBaseCF * CFrame.new(0, 4.0, 0)
            banner.Crossbar.CFrame = mastBaseCF * CFrame.new(0, 3.3, -2.05)
            for idx, seg in ipairs(banner.Panels) do
                if seg and seg.Parent then
                    local zOff = -0.78 - (idx - 1) * 1.34
                    local flutterYaw = math.sin(now * 4.4 - idx * 0.85 + s.Phase) * 0.14
                    local flutterRoll = math.cos(now * 3.2 - idx * 0.65 + s.Phase) * 0.05
                    local xWave = math.sin(now * 4.4 - idx * 0.85 + s.Phase) * (0.10 * idx)
                    seg.CFrame = mastBaseCF
                        * CFrame.new(xWave, 2.05, zOff)
                        * CFrame.Angles(0, flutterYaw, flutterRoll)
                end
            end
        end
    end
end)
