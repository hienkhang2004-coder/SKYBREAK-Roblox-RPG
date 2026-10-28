local Players = game:GetService("Players")
local DSS = game:GetService("DataStoreService")
local Http = game:GetService("HttpService")
local Run = game:GetService("RunService")
local C = require(game.ReplicatedStorage.Shared.Config)
local D = {Sessions={}}
local persistent = not Run:IsStudio() or C.StudioPersistence
local okStore, store = pcall(function()
    return persistent and DSS:GetDataStore(C.StoreName) or nil
end)
if not okStore or not store then
    persistent = false
    store = nil
end
local token = game.JobId .. ":" .. Http:GenerateGUID(false)

local function clone(t)
    if type(t) ~= "table" then return t end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = clone(v)
    end
    return copy
end

local function defaultSkillLevels()
    local levels = {}
    for skillId in pairs(C.SkillNames) do
        levels[skillId] = 1
    end
    return levels
end

local function defaults()
    return {
        SchemaVersion = 1,
        Level = 1,
        XP = 0,
        Gold = 300,
        CoreShards = 50,
        SkillPoints = 1,
        StatPoints = 0,
        StatAlloc = {
            Melee = 1,
            Defense = 1,
            Sword = 1,
            Gun = 1,
            Fruit = 1,
        },
        Potions = 4,
        DailyClaimed = 0,
        PartySize = "Solo",
        WeaponEnhance = 0,
        ClassId = "SkyGuardian",
        Gender = "Male",
        ActiveSlot = 3, -- 1=FightingStyle, 2=AetherFruit, 3=Sword, 4=Gun
        FightingStyle = "SkybornCombat",
        UnlockedStyles = {
            SkybornCombat = true,
            SkyStep = true,
        },
        EquippedFruit = "GaleCore",
        StoredFruits = {
            GaleCore = 1,
            SolarFlameCore = 1,
        },
        AwakenedFruits = {},
        EquippedGun = "aether_flintlock",
        Mastery = {
            SkybornCombat = 1,
            GaleCore = 1,
            starter_sword = 1,
            starter_daggers = 1,
            starter_staff = 1,
            aether_flintlock = 1,
        },
        Haki = {
            Aura = false,
            AuraStage = 1,
            Instinct = false,
            InstinctDodges = 4,
            MaxDodges = 4,
            ConquerorUnlocked = false,
        },
        Race = "Skyborn",
        RaceTier = 1,
        RaceV4Active = false,
        AwakeningMeter = 0,
        Faction = "Pirate",
        Bounty = 0,
        Honor = 0,
        Title = "Skyborn Novice",
        UnlockedTitles = {
            ["Skyborn Novice"] = true,
        },
        ActiveShip = "SkySloop",
        UnlockedShips = {
            SkySloop = true,
        },
        Transformed = false,
        TransformId = nil,
        HomeIsland = "SkyHub",
        Loadouts = {
            SkyGuardian = "starter_sword",
            ThunderStriker = "starter_daggers",
            ArcaneMage = "starter_staff",
        },
        SkillLevels = defaultSkillLevels(),
        Equipped = {
            Weapon = "starter_sword",
        },
        QuestIndex = 1,
        Accepted = true,
        Progress = {},
        CompletedQuests = {},
        Inventory = {
            starter_sword = 1,
            starter_daggers = 1,
            starter_staff = 1,
            aether_flintlock = 1,
            SkyIron = 3,
            SunshardCore = 1,
            upgrade_material = 2,
        },
        Weapon = "starter_sword",
        FirstClearBosses = {},
        UnlockedWorlds = {
            SkyHub = true,
            GoldenSky = true,
            FrozenCyber = false,
            ShadowRealm = false,
            VerdantCrown = false,
            EmberforgeWastes = false,
            AbyssalTides = false,
            ChronosBastion = false,
            VeilsEnd = false,
        },
    }
end

D.Default = defaults

local function hydrate(p)
    if type(p) ~= "table" then return defaults() end
    local def = defaults()
    for k, v in pairs(def) do
        if p[k] == nil then
            p[k] = clone(v)
        end
    end
    p.Level = type(p.Level) == "number" and math.clamp(math.floor(p.Level), 1, C.MaxLevel) or def.Level
    p.XP = type(p.XP) == "number" and math.max(0, math.floor(p.XP)) or def.XP
    p.Gold = type(p.Gold) == "number" and math.max(0, math.floor(p.Gold)) or def.Gold
    p.QuestIndex = type(p.QuestIndex) == "number" and math.clamp(math.floor(p.QuestIndex), 1, #C.Quests) or def.QuestIndex
    p.Accepted = (p.Accepted ~= false)
    p.Gender = (p.Gender == "Female") and "Female" or "Male"
    p.PartySize = p.PartySize or "Solo"
    p.ActiveSlot = (type(p.ActiveSlot) == "number" and p.ActiveSlot >= 1 and p.ActiveSlot <= 4) and math.floor(p.ActiveSlot) or 3
    p.StatPoints = type(p.StatPoints) == "number" and math.max(0, math.floor(p.StatPoints)) or def.StatPoints

    p.StatAlloc = type(p.StatAlloc) == "table" and p.StatAlloc or clone(def.StatAlloc)
    for statKey, defVal in pairs(def.StatAlloc) do
        if type(p.StatAlloc[statKey]) ~= "number" or p.StatAlloc[statKey] < 0 then
            p.StatAlloc[statKey] = defVal
        end
    end

    p.FightingStyle = (type(p.FightingStyle) == "string" and C.FightingStyles and C.FightingStyles[p.FightingStyle]) and p.FightingStyle or def.FightingStyle
    p.UnlockedStyles = type(p.UnlockedStyles) == "table" and p.UnlockedStyles or clone(def.UnlockedStyles)
    for styleId, unlocked in pairs(def.UnlockedStyles) do
        if p.UnlockedStyles[styleId] == nil then
            p.UnlockedStyles[styleId] = unlocked
        end
    end

    p.EquippedFruit = (type(p.EquippedFruit) == "string" and C.AetherFruits and C.AetherFruits[p.EquippedFruit]) and p.EquippedFruit or def.EquippedFruit
    p.StoredFruits = type(p.StoredFruits) == "table" and p.StoredFruits or clone(def.StoredFruits)
    for fruitId, count in pairs(def.StoredFruits) do
        if p.StoredFruits[fruitId] == nil then
            p.StoredFruits[fruitId] = count
        end
    end

    p.AwakenedFruits = type(p.AwakenedFruits) == "table" and p.AwakenedFruits or clone(def.AwakenedFruits)
    for fruitId, isAwakened in pairs(def.AwakenedFruits) do
        if p.AwakenedFruits[fruitId] == nil then
            p.AwakenedFruits[fruitId] = isAwakened
        end
    end

    p.EquippedGun = (type(p.EquippedGun) == "string" and C.Items[p.EquippedGun]) and p.EquippedGun or def.EquippedGun
    p.Mastery = type(p.Mastery) == "table" and p.Mastery or clone(def.Mastery)
    for key, val in pairs(def.Mastery) do
        if type(p.Mastery[key]) ~= "number" or p.Mastery[key] < 1 then
            p.Mastery[key] = val
        end
    end

    p.Haki = type(p.Haki) == "table" and p.Haki or clone(def.Haki)
    for k, v in pairs(def.Haki) do
        if p.Haki[k] == nil then
            p.Haki[k] = v
        end
    end

    p.Race = (type(p.Race) == "string" and C.Races and C.Races[p.Race]) and p.Race or def.Race
    p.RaceTier = (type(p.RaceTier) == "number" and p.RaceTier >= 1 and p.RaceTier <= 4) and math.floor(p.RaceTier) or def.RaceTier
    p.RaceV4Active = p.RaceV4Active == true
    p.AwakeningMeter = type(p.AwakeningMeter) == "number" and math.clamp(p.AwakeningMeter, 0, 100) or 0
    p.Faction = (p.Faction == "Marine") and "Marine" or "Pirate"
    p.Bounty = type(p.Bounty) == "number" and math.max(0, math.floor(p.Bounty)) or def.Bounty
    p.Honor = type(p.Honor) == "number" and math.max(0, math.floor(p.Honor)) or def.Honor
    p.Title = type(p.Title) == "string" and p.Title or def.Title
    p.UnlockedTitles = type(p.UnlockedTitles) == "table" and p.UnlockedTitles or clone(def.UnlockedTitles)
    p.ActiveShip = (type(p.ActiveShip) == "string" and C.SkyShips and C.SkyShips[p.ActiveShip]) and p.ActiveShip or def.ActiveShip
    p.UnlockedShips = type(p.UnlockedShips) == "table" and p.UnlockedShips or clone(def.UnlockedShips)
    p.Transformed = p.Transformed == true

    p.Loadouts = type(p.Loadouts) == "table" and p.Loadouts or clone(def.Loadouts)
    for classId, weaponId in pairs(def.Loadouts) do
        if not p.Loadouts[classId] then
            p.Loadouts[classId] = weaponId
        end
    end
    p.SkillLevels = type(p.SkillLevels) == "table" and p.SkillLevels or {}
    for skillId in pairs(C.SkillNames) do
        if type(p.SkillLevels[skillId]) ~= "number" or p.SkillLevels[skillId] < 1 then
            p.SkillLevels[skillId] = 1
        end
    end
    p.Inventory = type(p.Inventory) == "table" and p.Inventory or {}
    for itemId, count in pairs(def.Inventory) do
        if p.Inventory[itemId] == nil then
            p.Inventory[itemId] = count
        end
    end
    p.Equipped = type(p.Equipped) == "table" and p.Equipped or clone(def.Equipped)
    if p.Weapon and p.Equipped.Weapon == nil then
        p.Equipped.Weapon = p.Weapon
    elseif p.Equipped.Weapon and p.Weapon == nil then
        p.Weapon = p.Equipped.Weapon
    end
    p.UnlockedWorlds = type(p.UnlockedWorlds) == "table" and p.UnlockedWorlds or clone(def.UnlockedWorlds)
    p.UnlockedWorlds.SkyHub = true
    p.UnlockedWorlds.GoldenSky = true
    return p
end

local function valid(p)
    if type(p) ~= "table" or p.SchemaVersion ~= 1 then return false end
    for _, key in ipairs({"Level", "XP", "Gold", "QuestIndex"}) do
        local v = p[key]
        if type(v) ~= "number" or v ~= v or v % 1 ~= 0 or v < 0 or v > 1e12 then return false end
    end
    if p.Level < 1 or p.Level > C.MaxLevel or p.QuestIndex < 1 or p.QuestIndex > (#C.Quests + 2) then return false end
    for _, key in ipairs({"Progress", "CompletedQuests", "Inventory", "FirstClearBosses", "UnlockedWorlds"}) do
        if type(p[key]) ~= "table" then return false end
    end
    if not C.Classes[p.ClassId] or type(p.Accepted) ~= "boolean" then return false end
    if p.Gender ~= nil and p.Gender ~= "Male" and p.Gender ~= "Female" then return false end
    if p.Loadouts ~= nil and type(p.Loadouts) ~= "table" then return false end
    if p.Equipped ~= nil and type(p.Equipped) ~= "table" then return false end
    if p.SkillLevels ~= nil and type(p.SkillLevels) ~= "table" then return false end
    if p.StatAlloc ~= nil and type(p.StatAlloc) ~= "table" then return false end
    if p.StoredFruits ~= nil and type(p.StoredFruits) ~= "table" then return false end
    if p.AwakenedFruits ~= nil and type(p.AwakenedFruits) ~= "table" then return false end
    if p.Mastery ~= nil and type(p.Mastery) ~= "table" then return false end
    if p.Haki ~= nil and type(p.Haki) ~= "table" then return false end
    for k, v in pairs(p.Inventory) do
        if type(k) ~= "string" or type(v) ~= "number" or v ~= v or v < 0 or v > 1e8 then return false end
    end
    for k, v in pairs(p.Progress) do
        if type(k) ~= "string" or type(v) ~= "number" or v ~= v or v < 0 then return false end
    end
    return p.Weapon == nil or C.Items[p.Weapon] ~= nil
end

local function retry(fn)
    for n = 1, 3 do
        local ok, result = pcall(fn)
        if ok then return true, result end
        warn("[SKYBREAK] DataStore attempt", n, result)
        if n < 3 then task.wait(2 ^ (n - 1) + math.random()) end
    end
    return false, nil
end

function D.Load(player)
    local profile = defaults()
    local expires = os.time() + C.LeaseSeconds
    local loadedFromStore = false
    if persistent and store then
        local ok, record = retry(function()
            return store:UpdateAsync("u_" .. player.UserId, function(old)
                local rawData = (type(old) == "table" and type(old.Data) == "table") and old.Data or defaults()
                local migrated = hydrate(rawData)
                return {Data = migrated, Owner = token, Expires = os.time() + C.LeaseSeconds}
            end)
        end)
        if ok and type(record) == "table" and type(record.Data) == "table" then
            profile = record.Data
            expires = record.Expires or expires
            loadedFromStore = true
        else
            warn("[SKYBREAK] Falling back to in-memory profile for", player.Name)
        end
    end
    profile = hydrate(profile)
    D.Sessions[player] = {
        Profile = profile,
        Expires = expires,
        Busy = false,
        Active = true,
        SaveStatus = loadedFromStore and "Đã tải" or (persistent and "Tạm lưu bộ nhớ" or "Studio: KHÔNG LƯU"),
    }
    if player.Parent ~= Players then
        D.Release(player)
        return
    end
    return profile
end

function D.Get(player)
    local s = D.Sessions[player]
    if not s or not s.Active then return nil end
    if persistent and os.time() >= s.Expires then
        s.Expires = os.time() + C.LeaseSeconds
    end
    return s.Profile
end

function D.Save(player, release)
    local s = D.Sessions[player]
    if not s then return false end
    while s.Busy do task.wait(0.1) end
    if not s.Active then return false end
    s.Busy = true
    if not persistent then
        s.Busy = false
        return true
    end
    local snapshot = clone(s.Profile)
    local ok, record = retry(function()
        return store:UpdateAsync("u_" .. player.UserId, function()
            return {
                Data = snapshot,
                Owner = not release and token or nil,
                Expires = not release and (os.time() + C.LeaseSeconds) or 0,
            }
        end)
    end)
    local saved = ok and record and record.Data and (release or record.Owner == token)
    if saved then
        s.Expires = record.Expires or (os.time() + C.LeaseSeconds)
        s.SaveStatus = "Đã lưu"
    else
        s.SaveStatus = "Tạm lưu bộ nhớ"
    end
    s.Busy = false
    return saved == true
end

function D.Release(player)
    local s = D.Sessions[player]
    if not s then return end
    D.Save(player, true)
    s.Active = false
    D.Sessions[player] = nil
end

function D.Start()
    task.spawn(function()
        while true do
            task.wait(C.AutosaveSeconds)
            for player in pairs(D.Sessions) do
                task.spawn(D.Save, player, false)
            end
        end
    end)
    game:BindToClose(function()
        local count = 0
        for player in pairs(D.Sessions) do
            count += 1
            task.spawn(function()
                D.Release(player)
                count -= 1
            end)
        end
        local deadline = os.clock() + 25
        while count > 0 and os.clock() < deadline do
            task.wait(0.1)
        end
    end)
end

return D
