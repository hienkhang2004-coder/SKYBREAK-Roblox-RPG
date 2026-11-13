-- SKYBREAK: Fragments of the Core — UI Data Contracts & State Normalization
-- Location: ReplicatedStorage/SkybreakShared/Types/UIState.lua
-- Enforces strict separation between Server-Authoritative PlayerSnapshot and Local Client ViewState.

local sharedRoot = script.Parent:FindFirstChild("Config") and script.Parent or script.Parent.Parent
local RarityConfig = require(sharedRoot.Config.RarityConfig)
local WorldConfig = require(sharedRoot.Config.WorldConfig)

local UIState = {}

UIState.Screens = {
    MainMenu = "MainMenu",
    HUD = "HUD",
    Inventory = "Inventory",
    Skills = "Skills",
    Fruits = "Fruits",
    NPCShop = "NPCShop",
    WorldMap = "WorldMap",
    QuestJournal = "QuestJournal",
    Forge = "Forge",
    Raid = "Raid",
    RaidReady = "Raid",
    SocialRewards = "SocialRewards",
    Dialogue = "Dialogue",
    Settings = "Settings",
}

-- Map legacy Interface.lua page names to canonical ScreenRouter screen IDs
UIState.LegacyPageMap = {
    Menu = "MainMenu",
    HOME = "MainMenu",
    MainMenu = "MainMenu",
    HUD = "HUD",
    Inventory = "Inventory",
    INVENTORY = "Inventory",
    Classes = "Skills",
    Skills = "Skills",
    SKILLS = "Skills",
    Fruits = "Fruits",
    FRUITS = "Fruits",
    Shops = "NPCShop",
    SHOPS = "NPCShop",
    NPCShop = "NPCShop",
    Map = "WorldMap",
    ["WORLD MAP"] = "WorldMap",
    WorldMap = "WorldMap",
    Quests = "QuestJournal",
    QUESTS = "QuestJournal",
    QuestJournal = "QuestJournal",
    Forge = "Forge",
    FORGE = "Forge",
    Raid = "Raid",
    RAID = "Raid",
    Rewards = "SocialRewards",
    REWARDS = "SocialRewards",
    Party = "SocialRewards",
    PARTY = "SocialRewards",
    SocialRewards = "SocialRewards",
    Settings = "Settings",
    SETTINGS = "Settings",
}

function UIState.CreateDefaultSnapshot(isDemoMode)
    local demo = isDemoMode ~= false
    local snap = {
        isDemoMode = demo,
        raw = {},
        saveStatus = demo and "DEMO MODE • Client Preview (Server syncs on Play)" or "Connecting to server...",
        player = {
            level = demo and 24 or 1,
            exp = demo and 12450 or 0,
            expToNext = demo and 20000 or 115,
            classId = "SkyGuardian",
            gender = "Male",
            outfitStage = "SkyGuardian",
            classChosen = true,
        },
        vitals = {
            hp = demo and 320 or 150,
            maxHp = demo and 320 or 150,
            energy = demo and 85 or 100,
            maxEnergy = 100,
            stamina = 100,
            maxStamina = 100,
            shieldRemaining = 0,
            furyMeter = 0,
            dragonFormTier = 0,
            awakeningMeter = 0,
        },
        currency = {
            gold = demo and 4520 or 0,
            coreShards = demo and 125 or 0,
            voidEssence = demo and 18 or 0,
        },
        equipped = demo and {
            Weapon = "sunshard_halberd",
            Offhand = "sylvaris_thornbow",
            Helm = "aureon_halo_helm",
            Chest = "aureon_sunplate",
            Gauntlets = "aureon_gauntlets",
            Greaves = "aureon_greaves",
            Ring = "aureon_sun_ring",
            Artifact = "veyr_genesis_core",
        } or {
            Weapon = "starter_sword",
            Offhand = "",
            Helm = "",
            Chest = "",
            Gauntlets = "",
            Greaves = "",
            Ring = "",
            Artifact = "",
        },
        inventory = demo and {
            { itemId = "sunshard_halberd", count = 1, upgrade = 3, equipped = true },
            { itemId = "cyber_katana_mk2", count = 1, upgrade = 2, equipped = false },
            { itemId = "sylvaris_thornblade", count = 1, upgrade = 2, equipped = false },
            { itemId = "ignivar_magma_breaker", count = 1, upgrade = 2, equipped = false },
            { itemId = "nerith_abyssal_trident", count = 1, upgrade = 2, equipped = false },
            { itemId = "aion_chrono_scythe", count = 1, upgrade = 3, equipped = false },
            { itemId = "architect_severance", count = 1, upgrade = 3, equipped = false },
            { itemId = "eternal_frost_staff", count = 1, upgrade = 2, equipped = false },
            { itemId = "sylvaris_thornbow", count = 1, upgrade = 2, equipped = true },
            { itemId = "ignivar_hellcannon", count = 1, upgrade = 2, equipped = false },
            { itemId = "aion_chrono_pistols", count = 1, upgrade = 3, equipped = false },
            { itemId = "veyr_singularity_cannon", count = 1, upgrade = 3, equipped = false },
            { itemId = "kabucha_wind", count = 1, upgrade = 1, equipped = false },
            { itemId = "bizarre_rifle_cyber", count = 1, upgrade = 1, equipped = false },
            { itemId = "aether_flintlock", count = 1, upgrade = 1, equipped = false },
            { itemId = "aureon_halo_helm", count = 1, upgrade = 2, equipped = true },
            { itemId = "aureon_sunplate", count = 1, upgrade = 2, equipped = true },
            { itemId = "aureon_gauntlets", count = 1, upgrade = 2, equipped = true },
            { itemId = "aureon_greaves", count = 1, upgrade = 2, equipped = true },
            { itemId = "cryon_cyber_helm", count = 1, upgrade = 2, equipped = false },
            { itemId = "cryon_reactor_plate", count = 1, upgrade = 2, equipped = false },
            { itemId = "cryon_gauntlets", count = 1, upgrade = 2, equipped = false },
            { itemId = "cryon_greaves", count = 1, upgrade = 2, equipped = false },
            { itemId = "noxar_horns", count = 1, upgrade = 2, equipped = false },
            { itemId = "sovereign_cloak", count = 1, upgrade = 2, equipped = false },
            { itemId = "noxar_abyss_gauntlets", count = 1, upgrade = 2, equipped = false },
            { itemId = "noxar_abyss_greaves", count = 1, upgrade = 2, equipped = false },
            { itemId = "sylvaris_antler_crown", count = 1, upgrade = 2, equipped = false },
            { itemId = "ignivar_drake_cuirass", count = 1, upgrade = 2, equipped = false },
            { itemId = "ignivar_lava_gauntlets", count = 1, upgrade = 2, equipped = false },
            { itemId = "sylvaris_root_greaves", count = 1, upgrade = 2, equipped = false },
            { itemId = "nerith_tidal_diadem", count = 1, upgrade = 2, equipped = false },
            { itemId = "aion_chrono_vestment", count = 1, upgrade = 2, equipped = false },
            { itemId = "aion_astral_gauntlets", count = 1, upgrade = 2, equipped = false },
            { itemId = "nerith_abyss_greaves", count = 1, upgrade = 2, equipped = false },
            { itemId = "veyr_architect_crown", count = 1, upgrade = 3, equipped = false },
            { itemId = "veyr_singularity_armor", count = 1, upgrade = 3, equipped = false },
            { itemId = "veyr_void_gauntlets", count = 1, upgrade = 3, equipped = false },
            { itemId = "veyr_genesis_greaves", count = 1, upgrade = 3, equipped = false },
            { itemId = "aureon_sun_ring", count = 1, upgrade = 2, equipped = true },
            { itemId = "cryon_frost_reactor", count = 1, upgrade = 2, equipped = false },
            { itemId = "noxar_eclipse_ring", count = 1, upgrade = 2, equipped = false },
            { itemId = "sylvaris_life_amulet", count = 1, upgrade = 2, equipped = false },
            { itemId = "ignivar_molten_heart", count = 1, upgrade = 2, equipped = false },
            { itemId = "nerith_leviathan_ring", count = 1, upgrade = 2, equipped = false },
            { itemId = "veyr_genesis_core", count = 1, upgrade = 3, equipped = true },
            { itemId = "sylvaris_heartwood", count = 12, upgrade = 0, equipped = false },
            { itemId = "nerith_pearl_core", count = 12, upgrade = 0, equipped = false },
            { itemId = "veyr_architect_sigil", count = 12, upgrade = 0, equipped = false },
        } or {
            { itemId = "starter_sword", count = 1, upgrade = 0, equipped = true },
        },
        cooldowns = {},
        quest = {
            activeId = "Q01",
            name = "Lời Gọi Skyborn",
            text = "Các quần đảo bầu trời đang mất dần năng lượng. Hãy tiêu diệt 3 Training Drone tại sân tập Sky Hub để làm quen với vũ khí.",
            accepted = true,
            level = 1,
            objectives = {
                { id = "1", label = "Hạ gục Training Drone", current = demo and 2 or 0, target = 3 },
            },
            completedIds = {},
        },
        world = {
            current = "GoldenSky",
            unlocked = {
                SkyHub = true,
                GoldenSky = true,
                FrozenCyber = demo,
                ShadowRealm = demo,
                VerdantCrown = demo,
                EmberforgeWastes = demo,
                AbyssalTides = demo,
                ChronosBastion = demo,
                VeilsEnd = demo,
            },
        },
        discoveredIslands = {
            SkyHub = true,
            GoldenSky = true,
        },
        raid = {
            active = false,
            bossId = nil,
            bossName = "AUREON SENTINEL",
            phase = 1,
            maxPhases = 3,
            bossHp = 2400,
            bossMaxHp = 2400,
            breakGauge = 0,
            shield = false,
            stunned = false,
            purificationReady = false,
        },
        raidChipsCleared = 0,
        highestSpireFloor = 0,
        party = {
            partyId = "",
            leaderId = 0,
            partySize = demo and "Squad" or "Solo",
            companions = {
                { Id = "Kairo", Name = "Kairo • Vanguard", Role = "TANK", UnlockLevel = 3, Unlocked = demo, Active = demo },
                { Id = "Lumen", Name = "Lumen • Starweaver", Role = "HEALER", UnlockLevel = 6, Unlocked = demo, Active = demo },
                { Id = "Nyx", Name = "Nyx • Shadowblitz", Role = "ASSASSIN", UnlockLevel = 10, Unlocked = demo, Active = demo },
            },
            maxSize = 6,
            members = {
                { userId = 0, name = "Skyborn Leader (You)", classId = "SkyGuardian", level = demo and 24 or 1, hpRatio = 1.0, isLeader = true },
            },
            pendingInviteFrom = nil,
            pendingPartyId = nil,
            pendingInviterId = nil,
        },
        crewData = {
            InCrew = false,
            CrewId = "",
            Name = "",
            Tag = "",
            Color = "255,215,90",
            TotalBounty = 0,
            LeaderId = 0,
            Members = {},
            PendingInvite = nil,
        },
        dailyLogin = {
            streak = 1,
            canClaim = true,
            claimedToday = false,
            allBonusClaimed = false,
        },
        dailyBounties = {
            { Id = "Kill25", Kind = "Kill", Title = "Tiêu Diệt 25 Kẻ Địch", Progress = demo and 14 or 0, Count = 25, Gold = 2500, Shards = 120, Claimed = false },
            { Id = "Boss1", Kind = "Boss", Title = "Hạ Gục 1 Boss Khu Vực", Progress = 0, Count = 1, Gold = 5000, Shards = 250, Claimed = false },
            { Id = "Explore2", Kind = "Explore", Title = "Mở 2 Rương Kho Báu hoặc Bia Cổ Ngữ", Progress = demo and 2 or 0, Count = 2, Gold = 2000, Shards = 110, Claimed = false },
        },
        p2pTrade = {
            Active = false,
            SessionId = "",
            PartnerId = 0,
            PartnerName = "",
            MyOffer = {},
            PartnerOffer = {},
            MyReady = false,
            PartnerReady = false,
            MyConfirmed = false,
            PartnerConfirmed = false,
            Countdown = 0,
            PendingFrom = nil,
            PendingFromId = nil,
            StatusText = "",
        },
        fruits = {
            equippedFruit = demo and "SolarTitanCore" or "",
            heldFruit = "",
            activeSlot = demo and 2 or 1,
            fightingStyle = "SkybornCombat",
            equippedGun = demo and "aether_flintlock" or "",
            storedFruits = demo and { GaleCore = 1, SolarFlameCore = 1, SolarTitanCore = 1, AbyssalSovereignCore = 1 } or {},
            awakenedFruits = {},
            mastery = demo and { GaleCore = 120, SolarTitanCore = 300, AbyssalSovereignCore = 300 } or {},
            freeVouchers = 0,
            fruitPity = 0,
            pityCount = 0,
            statRefundTokens = 0,
            haki = { Aura = false, Instinct = false, InstinctDodges = 8 },
            race = "Skyborn",
            raceTier = 1,
            raceV4Unlocked = false,
            raceV4Active = false,
            awakeningMeter = 0,
            furyMeter = 0,
            dragonFormTier = 0,
            statPoints = 0,
            statAlloc = { Melee = 1, Defense = 1, Sword = 1, Gun = 1, Fruit = 1 },
            bounty = demo and 2500000 or 0,
            faction = "Pirate",
        },
        fruitPity = 0,
        FruitPity = 0,
        freeFruitVouchers = 0,
        FreeFruitVouchers = 0,
        statRefundTokens = 0,
        StatRefundTokens = 0,
        paidRandomRestricted = false,
        PaidRandomRestricted = false,
        playtimeGifts = { ElapsedSec = 0, SyncUnix = 0, Claimed = {}, Tiers = {} },
        PlaytimeGifts = { ElapsedSec = 0, SyncUnix = 0, Claimed = {}, Tiers = {} },
        friendBoostPct = 0,
        FriendBoostPct = 0,
        unlockedBadges = {},
        UnlockedBadges = {},
        globalLeaderboards = { Level = {}, Renown = {}, BossDPS = {} },
        GlobalLeaderboards = { Level = {}, Renown = {}, BossDPS = {} },
        pvpCombatUntil = 0,
        PvPCombatUntil = 0,
    }
    snap.partyData = snap.party
    return snap
end

function UIState.CreateDefaultViewState()
    return {
        currentScreen = UIState.Screens.HUD,
        backStack = {},
        selectedItemId = "starter_sword",
        compareMode = false,
        inventoryFilter = "All",
        inventorySort = "Rarity",
        searchQuery = "",
        selectedClassTab = "SkyGuardian",
        selectedRealmId = "GoldenSky",
        selectedQuestCategory = "Main",
        selectedQuestId = "Q01",
        selectedRecipeId = "craft_dawnbringer",
        selectedRaidId = "Veyr",
        activeVendorMode = "SwordDealer",
        fruitsMode = "Vault",
        questTrackerCollapsed = false,
        interactPrompt = nil,
        dialogue = {
            visible = false,
            speaker = "LYRA • SKY HUB",
            role = "Lorekeeper of the Core",
            text = "",
            questId = nil,
            choices = nil,
        },
        modal = {
            visible = false,
            title = "",
            content = "",
            confirmLabel = "CONFIRM",
            cancelLabel = "CANCEL",
            variant = "primary",
            onConfirm = nil,
            onCancel = nil,
        },
        settings = {
            reducedMotion = false,
            lowFX = false,
            textScale = 1.0,
            showMinimap = true,
            masterVolume = 80,
            sfxVolume = 85,
            layoutMode = "Auto", -- "Auto" | "Desktop" | "Mobile"
        },
    }
end

-- Converts the live GameService.Sync payload (src/ServerScriptService/Services/GameService.lua)
-- into our canonical PlayerSnapshot without losing any field!
function UIState.NormalizeServerState(rawState, currentRealmAttr)
    if type(rawState) ~= "table" then
        return UIState.CreateDefaultSnapshot(true)
    end
    -- If already normalized
    if rawState.player and rawState.vitals and rawState.currency then
        return rawState
    end

    local snapshot = UIState.CreateDefaultSnapshot(false)
    snapshot.isDemoMode = false
    snapshot.raw = rawState
    snapshot.saveStatus = rawState.SaveStatus or "Connected"

    local lv = tonumber(rawState.Level) or 1
    snapshot.player.level = lv
    snapshot.player.exp = tonumber(rawState.XP) or 0
    snapshot.player.expToNext = math.max(1, tonumber(rawState.RequiredXP) or 100)
    snapshot.player.classId = rawState.ClassId or "SkyGuardian"
    snapshot.player.gender = rawState.Gender or "Male"
    if rawState.ClassChosen ~= nil then
        snapshot.player.classChosen = (rawState.ClassChosen == true)
    else
        snapshot.player.classChosen = (lv > 1)
    end

    local maxEnergy = math.max(100, tonumber(rawState.MaxEnergy) or 100)
    snapshot.vitals.hp = tonumber(rawState.HP) or 100
    snapshot.vitals.maxHp = math.max(1, tonumber(rawState.MaxHP) or 100)
    snapshot.vitals.maxEnergy = maxEnergy
    snapshot.vitals.energy = math.clamp(tonumber(rawState.Energy) or maxEnergy, 0, maxEnergy)
    snapshot.vitals.stamina = tonumber(rawState.Stamina) or 100
    snapshot.vitals.maxStamina = math.max(100, tonumber(rawState.MaxStamina) or 100)
    snapshot.vitals.shieldRemaining = tonumber(rawState.Shield) or 0
    snapshot.vitals.furyMeter = tonumber(rawState.FuryMeter or rawState.DragonFury) or 0
    snapshot.vitals.dragonFormTier = tonumber(rawState.DragonFormTier) or 0
    snapshot.vitals.awakeningMeter = tonumber(rawState.AwakeningMeter) or 0

    snapshot.currency.gold = tonumber(rawState.Gold) or 0
    snapshot.currency.coreShards = tonumber(rawState.CoreShards) or (rawState.Complete and 20 or 0)
    snapshot.currency.voidEssence = tonumber(rawState.VoidEssence) or 0

    snapshot.player.atk = tonumber(rawState.ATK) or nil
    snapshot.player.def = tonumber(rawState.DEF) or nil
    snapshot.player.critRate = tonumber(rawState.CritRate) or nil
    snapshot.player.critDmg = tonumber(rawState.CritDmg) or nil
    snapshot.player.meleeAtk = tonumber(rawState.MeleeATK) or nil
    snapshot.player.swordAtk = tonumber(rawState.SwordATK) or nil
    snapshot.player.gunAtk = tonumber(rawState.GunATK) or nil
    snapshot.player.fruitAtk = tonumber(rawState.FruitATK) or nil
    snapshot.player.maxEnergy = maxEnergy

    local rawEq = rawState.Equipped or {}
    snapshot.equipped = {
        Weapon = rawState.Weapon or rawEq.Weapon,
        Offhand = rawEq.Offhand or rawEq.Necklace or rawState.EquippedGun or nil,
        Helm = rawEq.Helm or rawEq.Helmet or nil,
        Chest = rawEq.Chest or nil,
        Gauntlets = rawEq.Gauntlets or rawEq.Gloves or nil,
        Greaves = rawEq.Greaves or rawEq.Boots or nil,
        Ring = rawEq.Ring or nil,
        Artifact = rawEq.Artifact or nil,
    }

    local invList = {}
    local upgrades = type(rawState.Upgrades) == "table" and rawState.Upgrades or {}
    local weaponEnhances = type(rawState.WeaponEnhances) == "table" and rawState.WeaponEnhances or {}
    local hasPerWeaponEnhances = (next(weaponEnhances) ~= nil) or (next(upgrades) ~= nil)
    local baseWepEnhance = math.max(0, math.floor(tonumber(rawState.WeaponEnhance) or 0))
    local weaponStars = type(rawState.WeaponStars) == "table" and rawState.WeaponStars or {}
    if type(rawState.Inventory) == "table" then
        for itemId, count in pairs(rawState.Inventory) do
            if type(count) == "number" and count > 0 then
                local isEquipped = (rawState.Weapon == itemId) or (rawState.EquippedGun == itemId)
                if rawState.Equipped then
                    for _, eqId in pairs(rawState.Equipped) do
                        if eqId == itemId then
                            isEquipped = true
                        end
                    end
                end
                local resolvedUpg = tonumber(weaponEnhances[itemId])
                if resolvedUpg == nil then
                    resolvedUpg = tonumber(upgrades[itemId])
                end
                if resolvedUpg == nil then
                    resolvedUpg = (not hasPerWeaponEnhances and rawState.Weapon == itemId) and baseWepEnhance or 0
                end
                local rawStar = tonumber(weaponStars[itemId])
                table.insert(invList, {
                    itemId = itemId,
                    count = count,
                    upgrade = math.max(0, math.floor(resolvedUpg)),
                    stars = rawStar and math.clamp(math.floor(rawStar), 1, 5) or nil,
                    equipped = isEquipped,
                })
            end
        end
        table.sort(invList, function(a, b)
            local itemA = RarityConfig.GetItem(a.itemId)
            local itemB = RarityConfig.GetItem(b.itemId)
            local tierA = itemA and RarityConfig.GetRarity(itemA.Rarity).Tier or 1
            local tierB = itemB and RarityConfig.GetRarity(itemB.Rarity).Tier or 1
            if tierA ~= tierB then
                return tierA > tierB
            end
            return a.itemId < b.itemId
        end)
    end
    snapshot.inventory = invList
    snapshot.cooldowns = type(rawState.Cooldowns) == "table" and rawState.Cooldowns or {}

    if type(rawState.Quest) == "table" then
        local q = rawState.Quest
        local objs = {}
        for i, o in ipairs(q.Objectives or {}) do
            table.insert(objs, {
                id = tostring(i),
                label = o.Label or ("Objective " .. i),
                current = tonumber(o.Count or o.Current) or 0,
                target = math.max(1, tonumber(o.Goal or o.Target) or 1),
            })
        end
        snapshot.quest = {
            activeId = q.Id or "Q01",
            name = q.Name or "Active Quest",
            text = q.Text or "",
            accepted = q.Accepted == true,
            level = tonumber(q.Level) or 1,
            objectives = objs,
            completedIds = rawState.CompletedQuests or {},
        }
    elseif rawState.Complete then
        snapshot.quest = {
            activeId = "COMPLETE_ALL",
            name = "Thống Nhất Bầu Trời (Hoàn Tất Q01–Q30)",
            text = "Bạn đã hoàn thành toàn bộ 30 nhiệm vụ cốt truyện và đánh bại Veyr • Đấng Kiến Tạo Đầu Tiên!",
            accepted = true,
            level = 2550,
            objectives = {
                { id = "1", label = "Chinh phục toàn bộ 8 Cõi Giới (Lv. 2550)", current = 1, target = 1 },
            },
            completedIds = rawState.CompletedQuests or {},
        }
    end

    local unlocked = {
        SkyHub = true,
        GoldenSky = true,
        FrozenCyber = (rawState.Complete == true) or (rawState.UnlockedWorlds and rawState.UnlockedWorlds.FrozenCyber == true) or false,
        ShadowRealm = (rawState.Complete == true) or (rawState.UnlockedWorlds and rawState.UnlockedWorlds.ShadowRealm == true) or false,
    }
    if type(rawState.UnlockedWorlds) == "table" then
        for k, v in pairs(rawState.UnlockedWorlds) do
            if v then unlocked[k] = true end
        end
    end
    snapshot.world = {
        current = currentRealmAttr or rawState.CurrentRealm or "GoldenSky",
        unlocked = unlocked,
    }

    local discovered = {
        SkyHub = true,
        GoldenSky = true,
    }
    if type(rawState.DiscoveredIslands) == "table" then
        for k, v in pairs(rawState.DiscoveredIslands) do
            if type(k) == "number" and type(v) == "string" then
                discovered[v] = true
            elseif v then
                discovered[tostring(k)] = true
            end
        end
    end
    if type(rawState.UnlockedWorlds) == "table" then
        for k, v in pairs(rawState.UnlockedWorlds) do
            if v then
                discovered[tostring(k)] = true
            end
        end
    end
    snapshot.discoveredIslands = discovered

    if type(rawState.Boss) == "table" then
        local b = rawState.Boss
        local bossId = b.Id or "AureonSentinel"
        local raidCfg = WorldConfig.Raids[bossId] or WorldConfig.Raids.AureonSentinel
        snapshot.raid = {
            active = true,
            bossId = bossId,
            bossName = b.Name or raidCfg.Name,
            phase = tonumber(b.Phase) or 1,
            maxPhases = raidCfg.MaxPhases or 3,
            bossHp = tonumber(b.HP) or 0,
            bossMaxHp = math.max(1, tonumber(b.MaxHP) or 2200),
            breakGauge = tonumber(b.Break) or 0,
            shield = b.Shield == true,
            stunned = b.Stunned == true,
            purificationReady = b.PurificationReady == true,
        }
    else
        snapshot.raid.active = false
    end

    local chipsCleared = math.max(0, math.floor(tonumber(rawState.RaidChipsCleared) or 0))
    if chipsCleared == 0 and type(rawState.MicrochipRaidsCleared) == "table" then
        for _, v in pairs(rawState.MicrochipRaidsCleared) do
            if type(v) == "number" and v > 0 then
                chipsCleared += math.floor(v)
            elseif v == true then
                chipsCleared += 1
            end
        end
    end
    snapshot.raidChipsCleared = chipsCleared
    snapshot.highestSpireFloor = math.max(0, math.floor(tonumber(rawState.HighestSpireFloor) or 0))

    -- PartyData normalization (never overwrite active multi-member party back to Solo!)
    local rawParty = type(rawState.PartyData) == "table" and rawState.PartyData or {}
    local partyId = tostring(rawParty.PartyId or rawParty.Id or rawState.PartyId or "")
    local leaderId = tonumber(rawParty.LeaderId or rawState.PartyLeaderId) or 0
    local rawMembers = (type(rawParty.Members) == "table" and rawParty.Members)
        or (type(rawState.PartyMembers) == "table" and rawState.PartyMembers)
        or nil
    local normMembers = {}
    if type(rawMembers) == "table" and #rawMembers > 0 then
        for _, m in ipairs(rawMembers) do
            if type(m) == "table" then
                local mHp = tonumber(m.HP or m.hp) or 100
                local mMax = math.max(1, tonumber(m.MaxHP or m.maxHp) or 100)
                table.insert(normMembers, {
                    userId = tonumber(m.UserId or m.userId) or 0,
                    name = tostring(m.DisplayName or m.Name or m.name or "Skyborn"),
                    classId = tostring(m.ClassId or m.classId or "SkyGuardian"),
                    level = tonumber(m.Level or m.level) or 1,
                    hpRatio = tonumber(m.hpRatio) or math.clamp(mHp / mMax, 0, 1),
                    isLeader = (m.IsLeader == true) or (m.isLeader == true) or (leaderId > 0 and tonumber(m.UserId or m.userId) == leaderId),
                })
            else
                table.insert(normMembers, {
                    userId = 0,
                    name = tostring(m),
                    classId = "SkyGuardian",
                    level = 1,
                    hpRatio = 1.0,
                    isLeader = false,
                })
            end
        end
    end
    if #normMembers == 0 then
        table.insert(normMembers, {
            userId = 0,
            name = "Skyborn Leader (You)",
            classId = snapshot.player.classId,
            level = snapshot.player.level,
            hpRatio = math.clamp(snapshot.vitals.hp / math.max(1, snapshot.vitals.maxHp), 0, 1),
            isLeader = true,
        })
    end
    local rawInv = rawParty.PendingInviteFrom or rawParty.PendingInvite or rawState.PendingPartyInvite
    local pendingFromName = nil
    local pendingPartyId = nil
    local pendingInviterId = nil
    if type(rawInv) == "table" then
        pendingFromName = tostring(rawInv.LeaderName or rawInv.InviterName or rawInv.FromName or rawInv.Name or "")
        pendingPartyId = tostring(rawInv.PartyId or rawInv.Id or "")
        pendingInviterId = tonumber(rawInv.LeaderId or rawInv.InviterId or rawInv.UserId) or nil
    elseif type(rawInv) == "string" and rawInv ~= "" then
        pendingFromName = rawInv
    end
    if pendingFromName == "" then
        pendingFromName = nil
    end
    local computedPartySize = rawParty.Mode or rawParty.PartySize or rawState.PartySize or "Solo"
    if (partyId ~= "" or #normMembers > 1) and computedPartySize == "Solo" then
        computedPartySize = (#normMembers <= 2) and "Duo" or "Squad"
    end
    snapshot.party = {
        partyId = partyId,
        leaderId = leaderId,
        partySize = computedPartySize,
        companions = type(rawState.Companions) == "table" and rawState.Companions or {},
        maxSize = 6,
        members = normMembers,
        pendingInviteFrom = pendingFromName,
        pendingPartyId = pendingPartyId,
        pendingInviterId = pendingInviterId,
    }
    snapshot.partyData = snapshot.party

    -- CrewData normalization
    local rawCrew = type(rawState.CrewData) == "table" and rawState.CrewData or {}
    local crewName = tostring(rawCrew.Name or rawCrew.CrewName or rawState.CrewName or "")
    local crewTag = tostring(rawCrew.Tag or rawCrew.CrewTag or rawState.CrewTag or "")
    local crewColor = tostring(rawCrew.Color or rawCrew.CrewColor or rawState.CrewColor or "255,215,90")
    local crewLeaderId = tonumber(rawCrew.LeaderId or rawCrew.CaptainUserId) or 0
    local crewMembers = {}
    if type(rawCrew.Members) == "table" then
        if #rawCrew.Members > 0 then
            for _, cm in ipairs(rawCrew.Members) do
                if type(cm) == "table" then
                    table.insert(crewMembers, {
                        UserId = tonumber(cm.UserId or cm.userId) or 0,
                        Name = tostring(cm.DisplayName or cm.Name or cm.name or "Member"),
                        Role = tostring(cm.Role or cm.role or ((cm.IsCaptain or cm.isCaptain) and "Captain" or "Member")),
                        Bounty = tonumber(cm.Bounty or cm.bounty) or 0,
                    })
                else
                    table.insert(crewMembers, { UserId = 0, Name = tostring(cm), Role = "Member", Bounty = 0 })
                end
            end
        else
            for uid, val in pairs(rawCrew.Members) do
                if type(val) == "table" then
                    table.insert(crewMembers, {
                        UserId = tonumber(val.UserId or uid) or 0,
                        Name = tostring(val.DisplayName or val.Name or "Member"),
                        Role = tostring(val.Role or ((tonumber(uid) == crewLeaderId) and "Captain" or "Member")),
                        Bounty = tonumber(val.Bounty) or 0,
                    })
                else
                    table.insert(crewMembers, {
                        UserId = tonumber(uid) or 0,
                        Name = tostring(val),
                        Role = (tonumber(uid) == crewLeaderId) and "Captain" or "Member",
                        Bounty = 0,
                    })
                end
            end
        end
    end
    local pendingCrewInv = rawCrew.PendingInvite or rawCrew.PendingInviteFrom or rawState.PendingCrewInvite or nil
    snapshot.crewData = {
        InCrew = (crewName ~= ""),
        CrewId = tostring(rawCrew.Id or rawCrew.CrewId or crewName),
        Name = crewName,
        Tag = crewTag,
        Color = crewColor,
        TotalBounty = tonumber(rawCrew.TotalBounty or rawCrew.Bounty) or (crewName ~= "" and (tonumber(rawState.Bounty) or 0) or 0),
        LeaderId = crewLeaderId,
        Members = crewMembers,
        PendingInvite = pendingCrewInv,
    }

    -- DailyLogin & 3 DailyBounties normalization
    local rawDL = type(rawState.DailyLogin) == "table" and rawState.DailyLogin or {}
    local streak = math.clamp(math.floor(tonumber(rawDL.Streak or rawState.LoginStreak) or 1), 1, 7)
    local claimedToday = false
    if rawDL.CanClaim ~= nil then
        claimedToday = (rawDL.CanClaim == false)
    elseif rawDL.ClaimedToday ~= nil then
        claimedToday = (rawDL.ClaimedToday == true)
    end
    local canClaim = (rawDL.CanClaim ~= nil) and (rawDL.CanClaim == true) or (not claimedToday)
    snapshot.dailyLogin = {
        streak = streak,
        canClaim = canClaim,
        claimedToday = claimedToday,
        allBonusClaimed = (rawDL.AllBonusClaimed == true),
    }

    local rawBounties = (type(rawState.DailyBounties) == "table" and rawState.DailyBounties)
        or (type(rawDL.Tasks) == "table" and rawDL.Tasks)
        or (type(rawState.DailyTasks) == "table" and rawState.DailyTasks)
        or {}
    local normBounties = {}
    for i, b in ipairs(rawBounties) do
        if type(b) == "table" then
            table.insert(normBounties, {
                Id = tostring(b.Id or b.id or ("Bounty_" .. i)),
                Kind = tostring(b.Kind or b.kind or "Kill"),
                Title = tostring(b.Title or b.Label or b.Name or ("Nhiệm Vụ Ngày #" .. i)),
                Progress = math.max(0, math.floor(tonumber(b.Progress or b.Current or b.CountCurrent) or 0)),
                Count = math.max(1, math.floor(tonumber(b.Count or b.Goal or b.Target) or 1)),
                Gold = math.max(0, math.floor(tonumber(b.Gold or b.RewardGold) or 2500)),
                Shards = math.max(0, math.floor(tonumber(b.Shards or b.CoreShards or b.RewardShards) or 120)),
                Claimed = (b.Claimed == true),
            })
        end
    end
    snapshot.dailyBounties = normBounties

    -- P2PTrade normalization
    local rawTrade = type(rawState.P2PTrade) == "table" and rawState.P2PTrade or nil
    if rawTrade then
        local rawPend = type(rawTrade.PendingInvite) == "table" and rawTrade.PendingInvite or nil
        local pendFrom = (rawPend and (rawPend.FromDisplayName or rawPend.FromName))
            or rawTrade.PendingFrom
            or rawTrade.PendingInviteFrom
            or nil
        local pendFromId = (rawPend and tonumber(rawPend.FromUserId))
            or tonumber(rawTrade.PendingFromId or rawTrade.InviterId)
            or nil
        local myOff = rawTrade.MyOffers or rawTrade.MyOffer
        local theirOff = rawTrade.PartnerOffers or rawTrade.PartnerOffer or rawTrade.TheirOffer
        snapshot.p2pTrade = {
            Active = (rawTrade.Active == true),
            SessionId = tostring(rawTrade.SessionId or rawTrade.Id or ""),
            TableId = tostring(rawTrade.TableId or ""),
            PartnerId = tonumber(rawTrade.PartnerId or rawTrade.PartnerUserId) or 0,
            PartnerName = tostring(rawTrade.PartnerDisplayName or rawTrade.PartnerName or rawTrade.OtherName or "Đối Phương"),
            PartnerUsername = tostring(rawTrade.PartnerName or ""),
            MyOffer = type(myOff) == "table" and myOff or {},
            PartnerOffer = type(theirOff) == "table" and theirOff or {},
            MyReady = (rawTrade.MyReady == true) or (rawTrade.Ready == true),
            PartnerReady = (rawTrade.PartnerReady == true) or (rawTrade.TheirReady == true),
            MyConfirmed = (rawTrade.MyConfirmed == true) or (rawTrade.Accepted == true),
            PartnerConfirmed = (rawTrade.PartnerConfirmed == true) or (rawTrade.TheirAccepted == true),
            MyValue = tonumber(rawTrade.MyValue) or nil,
            PartnerValue = tonumber(rawTrade.PartnerValue or rawTrade.TheirValue) or nil,
            DiffPct = tonumber(rawTrade.DiffPct) or 0,
            IsFair = (rawTrade.IsFair == nil) or (rawTrade.IsFair == true),
            FairWarning = tostring(rawTrade.FairWarning or ""),
            Countdown = tonumber(rawTrade.Countdown) or 0,
            PendingFrom = (type(pendFrom) == "string" and pendFrom ~= "") and pendFrom or nil,
            PendingFromId = pendFromId,
            NearbyPlayers = type(rawTrade.NearbyPlayers) == "table" and rawTrade.NearbyPlayers or {},
            StatusText = tostring(rawTrade.StatusText or rawTrade.Message or ""),
            IsNPCCollector = (rawTrade.IsNPCCollector == true),
        }
    end

    local raceV4Unlocked = (rawState.RaceV4Unlocked == true)
    local rawRaceTier = tonumber(rawState.RaceTier) or (raceV4Unlocked and 4) or 1
    local normFruitPity = math.clamp(math.floor(tonumber(rawState.FruitPity or rawState.fruitPity) or 0), 0, 50)
    local normFreeVouchers = math.max(0, math.floor(tonumber(rawState.FreeFruitVouchers or rawState.freeFruitVouchers) or 0))
    local normStatRefundTokens = math.max(0, math.floor(tonumber(rawState.StatRefundTokens or rawState.statRefundTokens) or 0))
    local normBounty = math.max(0, math.floor(tonumber(rawState.Bounty or rawState.Renown) or 0))
    snapshot.fruits = {
        equippedFruit = (rawState.EquippedFruit ~= nil) and tostring(rawState.EquippedFruit) or "",
        heldFruit = rawState.HeldFruit or "",
        activeSlot = tonumber(rawState.ActiveSlot) or 2,
        fightingStyle = rawState.FightingStyle or "SkybornCombat",
        equippedGun = rawState.EquippedGun or "aether_flintlock",
        storedFruits = type(rawState.StoredFruits) == "table" and rawState.StoredFruits or {},
        awakenedFruits = type(rawState.AwakenedFruits) == "table" and rawState.AwakenedFruits or {},
        mastery = type(rawState.Mastery) == "table" and rawState.Mastery or {},
        freeVouchers = normFreeVouchers,
        fruitPity = normFruitPity,
        pityCount = normFruitPity,
        statRefundTokens = normStatRefundTokens,
        haki = type(rawState.Haki) == "table" and rawState.Haki or { Aura = false, Instinct = false, InstinctDodges = 8 },
        race = rawState.Race or "Skyborn",
        raceTier = math.clamp(math.floor(rawRaceTier), 1, 4),
        raceV4Unlocked = raceV4Unlocked,
        raceV4Active = rawState.RaceV4Active == true,
        awakeningMeter = tonumber(rawState.AwakeningMeter) or 0,
        furyMeter = tonumber(rawState.FuryMeter or rawState.DragonFury) or 0,
        dragonFormTier = tonumber(rawState.DragonFormTier) or 0,
        statPoints = tonumber(rawState.StatPoints) or 0,
        statAlloc = type(rawState.StatAlloc) == "table" and rawState.StatAlloc or { Melee = 1, Defense = 1, Sword = 1, Gun = 1, Fruit = 1 },
        bounty = normBounty,
        faction = rawState.Faction or "Pirate",
    }

    local mergedWeaponEnhances = {}
    for k, v in pairs(upgrades) do
        if tonumber(v) then
            mergedWeaponEnhances[tostring(k)] = math.max(0, math.floor(tonumber(v)))
        end
    end
    for k, v in pairs(weaponEnhances) do
        if tonumber(v) then
            mergedWeaponEnhances[tostring(k)] = math.max(0, math.floor(tonumber(v)))
        end
    end
    if not hasPerWeaponEnhances and rawState.Weapon and baseWepEnhance > 0 then
        mergedWeaponEnhances[tostring(rawState.Weapon)] = baseWepEnhance
    end

    local unlockedShips = { SkySloop = true }
    if type(rawState.UnlockedShips) == "table" then
        for k, v in pairs(rawState.UnlockedShips) do
            if v then
                unlockedShips[tostring(k)] = true
            end
        end
    end

    snapshot.weaponStars = weaponStars
    snapshot.starPity = type(rawState.StarPity) == "table" and rawState.StarPity or {}
    snapshot.weaponEnhance = baseWepEnhance
    snapshot.weaponEnhances = mergedWeaponEnhances
    snapshot.enhancePity = math.clamp(math.floor(tonumber(rawState.EnhancePity) or 0), 0, 100)
    snapshot.statPresets = type(rawState.StatPresets) == "table" and rawState.StatPresets or {}
    snapshot.redeemedCodes = type(rawState.RedeemedCodes) == "table" and rawState.RedeemedCodes or {}
    snapshot.doubleExpSeconds = tonumber(rawState.DoubleExpRemainingSec or rawState.DoubleExpSeconds) or 0
    snapshot.unlockedShips = unlockedShips
    snapshot.activeShip = tostring(rawState.ActiveShip or "SkySloop")
    snapshot.mirageStock = type(rawState.MirageStock) == "table" and rawState.MirageStock or nil
    snapshot.freeFruitVouchers = normFreeVouchers
    snapshot.FreeFruitVouchers = normFreeVouchers
    snapshot.fruitPity = normFruitPity
    snapshot.FruitPity = normFruitPity
    snapshot.statRefundTokens = normStatRefundTokens
    snapshot.StatRefundTokens = normStatRefundTokens
    snapshot.paidRandomRestricted = (rawState.PaidRandomRestricted == true) or (rawState.paidRandomRestricted == true)
    snapshot.PaidRandomRestricted = snapshot.paidRandomRestricted
    local rawPlaytime = type(rawState.PlaytimeGifts) == "table" and rawState.PlaytimeGifts
        or (type(rawState.playtimeGifts) == "table" and rawState.playtimeGifts)
        or { ElapsedSec = 0, SyncUnix = 0, Claimed = {}, Tiers = {} }
    snapshot.playtimeGifts = rawPlaytime
    snapshot.PlaytimeGifts = rawPlaytime
    snapshot.friendBoostPct = math.max(0, math.floor(tonumber(rawState.FriendBoostPct or rawState.friendBoostPct) or 0))
    snapshot.FriendBoostPct = snapshot.friendBoostPct
    local rawBadges = type(rawState.UnlockedBadges) == "table" and rawState.UnlockedBadges
        or (type(rawState.unlockedBadges) == "table" and rawState.unlockedBadges)
        or {}
    snapshot.unlockedBadges = rawBadges
    snapshot.UnlockedBadges = rawBadges
    local rawGlobalLB = type(rawState.GlobalLeaderboards) == "table" and rawState.GlobalLeaderboards
        or (type(rawState.globalLeaderboards) == "table" and rawState.globalLeaderboards)
        or { Level = {}, Renown = {}, BossDPS = {} }
    snapshot.globalLeaderboards = rawGlobalLB
    snapshot.GlobalLeaderboards = rawGlobalLB
    snapshot.pvpCombatUntil = tonumber(rawState.PvPCombatUntil or rawState.pvpCombatUntil) or 0
    snapshot.PvPCombatUntil = snapshot.pvpCombatUntil
    snapshot.unlockedStyles = type(rawState.UnlockedStyles) == "table" and rawState.UnlockedStyles or { SkybornCombat = true }
    snapshot.unlockedHakiColors = type(rawState.UnlockedHakiColors) == "table" and rawState.UnlockedHakiColors or {}
    snapshot.hakiColorId = tostring(rawState.HakiColorId or "")

    return snapshot
end

return UIState
