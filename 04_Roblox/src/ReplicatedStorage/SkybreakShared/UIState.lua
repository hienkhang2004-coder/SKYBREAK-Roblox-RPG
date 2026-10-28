-- SKYBREAK: Fragments of the Core — UI Data Contracts & State Normalization
-- Location: ReplicatedStorage/SkybreakShared/Types/UIState.lua
-- Enforces strict separation between Server-Authoritative PlayerSnapshot and Local Client ViewState.

local RarityConfig = require(script.Parent.Parent.Config.RarityConfig)
local WorldConfig = require(script.Parent.Parent.Config.WorldConfig)

local UIState = {}

UIState.Screens = {
    MainMenu = "MainMenu",
    HUD = "HUD",
    Inventory = "Inventory",
    Skills = "Skills",
    Fruits = "Fruits",
    WorldMap = "WorldMap",
    QuestJournal = "QuestJournal",
    Forge = "Forge",
    Raid = "Raid",
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
    Fruits = "Fruits",
    SKILLS = "Skills",
    Fruits = "Fruits",
    FRUITS = "Fruits",
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
    Settings = "Settings",
    SETTINGS = "Settings",
}

function UIState.CreateDefaultSnapshot(isDemoMode)
    local demo = isDemoMode ~= false
    return {
        isDemoMode = demo,
        saveStatus = demo and "DEMO MODE • Client Preview (Server syncs on Play)" or "Connecting to server...",
        player = {
            level = demo and 24 or 1,
            exp = demo and 12450 or 0,
            expToNext = demo and 20000 or 115,
            classId = "SkyGuardian",
            gender = "Male",
            outfitStage = "SkyGuardian",
        },
        vitals = {
            hp = demo and 320 or 150,
            maxHp = demo and 320 or 150,
            energy = demo and 85 or 0,
            maxEnergy = 100,
            stamina = 100,
            maxStamina = 100,
            shieldRemaining = 0,
        },
        currency = {
            gold = demo and 4520 or 300,
            coreShards = demo and 125 or 50,
            voidEssence = demo and 18 or 0,
        },
        equipped = {
            Weapon = demo and "Dawnbringer" or "starter_sword",
            Offhand = demo and "AureonCrestShield" or nil,
            Helm = demo and "SkyHelm" or nil,
            Chest = demo and "CelestialPlate" or nil,
            Gauntlets = demo and "StarlightGauntlets" or nil,
            Greaves = demo and "WindstriderGreaves" or nil,
            Ring = demo and "SolarBand" or nil,
            Artifact = demo and "CoreShardArtifact" or nil,
        },
        inventory = demo and {
            { itemId = "Dawnbringer", count = 1, upgrade = 3, equipped = true },
            { itemId = "starter_sword", count = 1, upgrade = 1, equipped = false },
            { itemId = "starter_daggers", count = 1, upgrade = 0, equipped = false },
            { itemId = "starter_staff", count = 1, upgrade = 0, equipped = false },
            { itemId = "Stormfang", count = 1, upgrade = 2, equipped = false },
            { itemId = "EternalFrost", count = 1, upgrade = 1, equipped = false },
            { itemId = "SkyHelm", count = 1, upgrade = 1, equipped = true },
            { itemId = "CelestialPlate", count = 1, upgrade = 2, equipped = true },
            { itemId = "StarlightGauntlets", count = 1, upgrade = 1, equipped = true },
            { itemId = "WindstriderGreaves", count = 1, upgrade = 1, equipped = true },
            { itemId = "AureonCrestShield", count = 1, upgrade = 2, equipped = true },
            { itemId = "SolarBand", count = 1, upgrade = 1, equipped = true },
            { itemId = "CoreShardArtifact", count = 1, upgrade = 0, equipped = true },
            { itemId = "SkyCrystal", count = 14, upgrade = 0, equipped = false },
            { itemId = "upgrade_material", count = 9, upgrade = 0, equipped = false },
            { itemId = "CoreOfLight", count = 1, upgrade = 0, equipped = false },
            { itemId = "DawnbringerBlueprint", count = 1, upgrade = 0, equipped = false },
            { itemId = "VoidShard", count = 6, upgrade = 0, equipped = false },
        } or {
            { itemId = "starter_sword", count = 1, upgrade = 0, equipped = true },
            { itemId = "starter_daggers", count = 1, upgrade = 0, equipped = false },
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
        party = {
            partySize = demo and "Squad" or "Solo",
            companions = {
                { Id = "Kairo", Name = "Kairo • Vanguard", Role = "TANK", UnlockLevel = 3, Unlocked = demo, Active = demo },
                { Id = "Lumen", Name = "Lumen • Starweaver", Role = "HEALER", UnlockLevel = 6, Unlocked = demo, Active = demo },
                { Id = "Nyx", Name = "Nyx • Shadowblitz", Role = "ASSASSIN", UnlockLevel = 10, Unlocked = demo, Active = demo },
            },
            maxSize = 6,
            members = {
                { name = "Skyborn Leader (You)", classId = "SkyGuardian", level = demo and 24 or 1, hpRatio = 1.0, isLeader = true },
            },
        },
        fruits = {
            equippedFruit = "SolarTitanCore",
            heldFruit = "",
            activeSlot = 2,
            fightingStyle = "SkybornCombat",
            equippedGun = "aether_flintlock",
            storedFruits = { GaleCore = 1, SolarFlameCore = 1, SolarTitanCore = 1, AbyssalSovereignCore = 1 },
            awakenedFruits = {},
            mastery = { GaleCore = 120, SolarTitanCore = 300, AbyssalSovereignCore = 300 },
            haki = { Aura = false, Instinct = false, InstinctDodges = 8 },
            race = "Skyborn",
            raceV4Active = false,
            statPoints = 0,
            statAlloc = { Melee = 1, Defense = 1, Sword = 1, Gun = 1, Fruit = 1 },
            bounty = 2500000,
            faction = "Pirate",
        },
    }
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
        questTrackerCollapsed = false,
        interactPrompt = nil,
        dialogue = {
            visible = false,
            speaker = "LYRA • SKY HUB",
            role = "Lorekeeper of the Core",
            text = "",
            questId = nil,
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
    snapshot.saveStatus = rawState.SaveStatus or "Connected"

    snapshot.player.level = tonumber(rawState.Level) or 1
    snapshot.player.exp = tonumber(rawState.XP) or 0
    snapshot.player.expToNext = math.max(1, tonumber(rawState.RequiredXP) or 100)
    snapshot.player.classId = rawState.ClassId or "SkyGuardian"
    snapshot.player.gender = rawState.Gender or "Male"

    snapshot.vitals.hp = tonumber(rawState.HP) or 100
    snapshot.vitals.maxHp = math.max(1, tonumber(rawState.MaxHP) or 100)
    snapshot.vitals.energy = tonumber(rawState.Energy) or 0
    snapshot.vitals.maxEnergy = 100
    snapshot.vitals.stamina = tonumber(rawState.Stamina) or 100
    snapshot.vitals.maxStamina = 100
    snapshot.vitals.shieldRemaining = tonumber(rawState.Shield) or 0

    snapshot.currency.gold = tonumber(rawState.Gold) or 0
    snapshot.currency.coreShards = tonumber(rawState.CoreShards) or (rawState.Complete and 20 or 0)
    snapshot.currency.voidEssence = tonumber(rawState.VoidEssence) or 0

    snapshot.equipped = {
        Weapon = rawState.Weapon,
        Offhand = rawState.Equipped and rawState.Equipped.Offhand or nil,
        Helm = rawState.Equipped and rawState.Equipped.Helm or nil,
        Chest = rawState.Equipped and rawState.Equipped.Chest or nil,
        Gauntlets = rawState.Equipped and rawState.Equipped.Gauntlets or nil,
        Greaves = rawState.Equipped and rawState.Equipped.Greaves or nil,
        Ring = rawState.Equipped and rawState.Equipped.Ring or nil,
        Artifact = rawState.Equipped and rawState.Equipped.Artifact or nil,
    }

    local invList = {}
    local upgrades = rawState.Upgrades or {}
    if type(rawState.Inventory) == "table" then
        for itemId, count in pairs(rawState.Inventory) do
            if type(count) == "number" and count > 0 then
                local isEquipped = (rawState.Weapon == itemId)
                if rawState.Equipped then
                    for _, eqId in pairs(rawState.Equipped) do
                        if eqId == itemId then
                            isEquipped = true
                        end
                    end
                end
                table.insert(invList, {
                    itemId = itemId,
                    count = count,
                    upgrade = tonumber(upgrades[itemId]) or 0,
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
                current = tonumber(o.Count) or 0,
                target = math.max(1, tonumber(o.Goal) or 1),
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
            name = "Thống Nhất Bầu Trời (Hoàn Tất)",
            text = "Bạn đã hoàn thành toàn bộ 14 nhiệm vụ cốt truyện và đánh bại Veyr • Đấng Kiến Tạo Đầu Tiên!",
            accepted = true,
            level = 100,
            objectives = {
                { id = "1", label = "Chinh phục toàn bộ 8 Cõi Giới", current = 1, target = 1 },
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

    snapshot.party = {
        partySize = rawState.PartySize or "Solo",
        companions = type(rawState.Companions) == "table" and rawState.Companions or {},
        maxSize = 6,
        members = {
            { name = "Skyborn Leader (You)", classId = snapshot.player.classId, level = snapshot.player.level, hpRatio = 1.0, isLeader = true },
        },
    }

    snapshot.fruits = {
        equippedFruit = rawState.EquippedFruit or "GaleCore",
        heldFruit = rawState.HeldFruit or "",
        activeSlot = tonumber(rawState.ActiveSlot) or 2,
        fightingStyle = rawState.FightingStyle or "SkybornCombat",
        equippedGun = rawState.EquippedGun or "aether_flintlock",
        storedFruits = type(rawState.StoredFruits) == "table" and rawState.StoredFruits or { GaleCore = 1, SolarFlameCore = 1 },
        awakenedFruits = type(rawState.AwakenedFruits) == "table" and rawState.AwakenedFruits or {},
        mastery = type(rawState.Mastery) == "table" and rawState.Mastery or {},
        haki = type(rawState.Haki) == "table" and rawState.Haki or { Aura = false, Instinct = false, InstinctDodges = 8 },
        race = rawState.Race or "Skyborn",
        raceV4Active = rawState.RaceV4Active == true,
        statPoints = tonumber(rawState.StatPoints) or 0,
        statAlloc = type(rawState.StatAlloc) == "table" and rawState.StatAlloc or { Melee = 1, Defense = 1, Sword = 1, Gun = 1, Fruit = 1 },
        bounty = tonumber(rawState.Bounty) or 2500000,
        faction = rawState.Faction or "Pirate",
    }

    return snapshot
end

return UIState
