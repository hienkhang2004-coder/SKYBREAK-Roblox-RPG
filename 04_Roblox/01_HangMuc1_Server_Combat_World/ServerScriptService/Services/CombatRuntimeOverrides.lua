-- SKYBREAK: luat combat va hoi Energy cua server (P1-01).
-- Truoc day nam cuoi ReplicatedStorage/Shared/Config.lua nen moi client deu tai duoc.
-- ServerBootstrap.server.lua goi Install(C) mot lan, truoc GameService.Start().
local Overrides = {}
local installed = false

function Overrides.Install(C)
	if installed then return end
	installed = true
	local BALANCED_ENEMY_STATS = C._BalancedEnemyStats or {}
	if game:GetService("RunService"):IsServer() then
	task.spawn(function()
	    local tickIdx = 0
	    while true do
	        tickIdx += 1
	        task.wait(tickIdx <= 40 and 0.25 or 0.5)
	        local sss = game:GetService("ServerScriptService")
	        local services = sss and sss:FindFirstChild("Services")
	        local gsMod = services and services:FindFirstChild("GameService")
	        local pdMod = services and services:FindFirstChild("PlayerDataService")
	        local hlMod = services and services:FindFirstChild("GameExperienceHelpers")
	        if gsMod then
	            local okG, G = pcall(require, gsMod)
	            local okD, D = false, nil
	            if pdMod then okD, D = pcall(require, pdMod) end
	            local okH, Helpers = false, nil
	            if hlMod then okH, Helpers = pcall(require, hlMod) end
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
	                if type(G.Runtime) == "table" then
	                    for plr, rt in pairs(G.Runtime) do
	                        if type(rt) == "table" then
	                            if rt.FuryMeter == nil then rt.FuryMeter = 100 end
	                            local st = (typeof(plr) == "Instance" and type(G.Stats) == "function") and G.Stats(plr) or nil
	                            local maxE = math.max(100, (st and tonumber(st.MaxEnergy)) or tonumber(rt.MaxEnergy) or 100)
	                            rt.MaxEnergy = maxE
	                            if rt.Energy ~= nil and tonumber(rt.Energy) > maxE then
	                                rt.Energy = maxE
	                            end
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
	                        if okH and Helpers and type(Helpers.ResolveFruitId) == "function" then
	                            return Helpers.ResolveFruitId(fid) == "AbyssalSovereignCore"
	                        end
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
	                    local function resolveMaxEnergy(p, rt, stats)
	                        local st = stats or (type(G.Stats) == "function" and G.Stats(p) or nil)
	                        local maxE = math.max(100, (st and tonumber(st.MaxEnergy)) or tonumber(rt and rt.MaxEnergy) or 100)
	                        if rt then rt.MaxEnergy = maxE end
	                        return maxE
	                    end
	                    local function resolve3DAim(hrp, payload)
	                        if okH and Helpers and type(Helpers.Resolve3DAimDirection) == "function" then
	                            return Helpers.Resolve3DAimDirection(hrp, payload)
	                        end
	                        return (hrp and hrp.CFrame.LookVector) or Vector3.new(0, 0, -1), (hrp and hrp.Position) or Vector3.zero
	                    end

	                    if type(prevStats) == "function" then
	                        G.Stats = function(p, slotOverride)
	                            G._StatSlotOverride = G._StatSlotOverride or {}
	                            G._StatSlotOverride[p] = slotOverride
	                            local s = prevStats(p, slotOverride)
	                            G._StatSlotOverride[p] = nil
	                            local profile = okD and D and type(D.Get) == "function" and D.Get(p) or nil
	                            if not s or not profile then return s end

	                            -- Add 8-Armor-Set 3D 2-Piece & 4-Piece Set Bonus cleanly without cross-slot weapon bleed
	                            local eq = type(profile.Equipped) == "table" and profile.Equipped or {}
	                            local setHP, setATK, setDEF, setCrit, setSpeedPct = 0, 0, 0, 0, 0
	                            if type(C.GetActiveArmorSetInfo) == "function" then
	                                local uiEq = {
	                                    Helm = eq.Helm or eq.Helmet,
	                                    Chest = eq.Chest or eq.Armor,
	                                    Gauntlets = eq.Gauntlets or eq.Gloves,
	                                    Greaves = eq.Greaves or eq.Boots,
	                                }
	                                local okSet, setInfo = pcall(C.GetActiveArmorSetInfo, uiEq)
	                                local bStats = okSet and type(setInfo) == "table" and setInfo.BonusStats or nil
	                                if type(bStats) == "table" then
	                                    setHP = tonumber(bStats.HP) or 0
	                                    setATK = tonumber(bStats.ATK) or 0
	                                    setDEF = tonumber(bStats.DEF) or 0
	                                    setCrit = tonumber(bStats.CRIT) or 0
	                                    setSpeedPct = (tonumber(bStats.SPEED) or 0) / 100
	                                end
	                            end
	                            s.HP = math.max(100, math.floor((tonumber(s.HP) or 100) + setHP + 0.5))
	                            s.ATK = math.max(10, math.floor((tonumber(s.ATK) or 20) + setATK + 0.5))
	                            if s.MeleeATK then s.MeleeATK = math.floor(s.MeleeATK + setATK + 0.5) end
	                            if s.FruitATK then s.FruitATK = math.floor(s.FruitATK + setATK + 0.5) end
	                            if s.SwordATK then s.SwordATK = math.floor(s.SwordATK + setATK + 0.5) end
	                            if s.GunATK then s.GunATK = math.floor(s.GunATK + setATK + 0.5) end
	                            s.BestATK = math.max(s.MeleeATK or 0, s.FruitATK or 0, s.SwordATK or 0, s.GunATK or 0, s.ATK or 0)
	                            s.DEF = math.max(4, math.floor((tonumber(s.DEF) or 10) + setDEF + 0.5))
	                            s.CritRate = math.clamp(math.floor((tonumber(s.CritRate) or 5) + setCrit + 0.5), 4, 75)
	                            s.CritDmg = math.clamp(math.floor((tonumber(s.CritDmg) or 50) + 0.5), 50, 180)
	                            s.MaxEnergy = math.max(100, math.floor(tonumber(s.MaxEnergy) or 100))
	                            local rt = G.Runtime and G.Runtime[p]
	                            if rt then rt.MaxEnergy = s.MaxEnergy end
	                            if setSpeedPct > 0 and p and p.Character then
	                                local hum = p.Character:FindFirstChildOfClass("Humanoid")
	                                if hum then
	                                    hum.WalkSpeed = math.clamp(hum.WalkSpeed * (1 + setSpeedPct), 16, 52)
	                                end
	                            end
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
	                            local isShipWeapon = (actStr == "ShipCannon" or actStr == "WarshipCannon" or actStr == "FireShipCannon" or actStr == "Harpoon")
	                            local isBasic = (actStr == "Attack" or actStr == "Light" or actStr == "M1" or actStr == "HybridDragonM1" or actStr == "SovereignDragonM1")
	                            local isBoss = (e.Config and e.Config.Boss == true) or (e == G.Boss)

	                            -- Faithful skill damage with anti-exploit ceiling (atk * 14.0 & 25% Boss MaxHP per hit)
	                            local rawDmg = math.max(1, tonumber(damage) or atk)
	                            local scaledDmg
	                            if isShipWeapon then
	                                scaledDmg = rawDmg
	                            else
	                                scaledDmg = math.min(rawDmg, atk * 14.0)
	                                if isBoss and (e.MaxHP or 0) > 0 then
	                                    scaledDmg = math.min(scaledDmg, math.max(60, (e.MaxHP or 10000) * 0.25))
	                                end
	                            end

	                            local scaledBreak = isShipWeapon and math.clamp(math.floor(tonumber(breakPower) or 18), 1, 35)
	                                or math.clamp(math.floor(tonumber(breakPower) or 8), 1, isBoss and 26 or 34)
	                            if now < (e._BalStunImmuneUntil or 0) then
	                                scaledBreak = 0; e.StunnedUntil = 0; e.FrozenUntil = 0
	                            end
	                            local rt = G.Runtime and G.Runtime[p]
	                            local maxE = resolveMaxEnergy(p, rt, stats)
	                            local preEnergy = rt and tonumber(rt.Energy) or nil
	                            prevHit(p, e, math.max(1, scaledDmg), scaledBreak, action)
	                            if rt then
	                                rt.MaxEnergy = maxE
	                                rt.LastCombatAt = now
	                                -- Real Dragon Fury Meter: dealing combat hits restores +4 Fury!
	                                rt.FuryMeter = math.clamp((tonumber(rt.FuryMeter) or 100) + 4, 0, 100)
	                                if p then
	                                    p:SetAttribute("FuryMeter", math.floor(rt.FuryMeter + 0.5))
	                                    if p.Character then p.Character:SetAttribute("FuryMeter", math.floor(rt.FuryMeter + 0.5)) end
	                                end
	                                local postEnergy = tonumber(rt.Energy) or preEnergy or maxE
	                                if isBasic then
	                                    if now - (tonumber(rt._LastM1EnergyAt) or 0) >= 0.16 then
	                                        rt._LastM1EnergyAt = now
	                                        rt.Energy = math.clamp(math.max(preEnergy or maxE, postEnergy) + math.max(6, math.floor(maxE * 0.03)), 0, maxE)
	                                    else
	                                        rt.Energy = math.clamp(math.max(preEnergy or maxE, postEnergy), 0, maxE)
	                                    end
	                                elseif preEnergy ~= nil then
	                                    rt.Energy = math.clamp(math.max(preEnergy, postEnergy), 0, maxE)
	                                end
	                            end
	                            local afterNow = os.clock()
	                            if afterNow < (e._BalStunImmuneUntil or 0) then
	                                e.StunnedUntil = 0; e.FrozenUntil = 0
	                            else
	                                local stunned, frozen, broken = (e.StunnedUntil or 0) > afterNow, (e.FrozenUntil or 0) > afterNow, (e.BossBrokenUntil or 0) > afterNow
	                                if stunned or frozen or broken then
	                                    local maxCC = isBoss and 1.35 or 1.25
	                                    if stunned then e.StunnedUntil = math.min(e.StunnedUntil, afterNow + maxCC) end
	                                    if frozen then e.FrozenUntil = math.min(e.FrozenUntil, afterNow + maxCC) end
	                                    if broken then e.BossBrokenUntil = math.min(e.BossBrokenUntil, afterNow + 4.5) end
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
	                            local stats = type(G.Stats) == "function" and G.Stats(p) or nil
	                            if not ch or not hum or hum.Health <= 0 or not rt or not stats then return end
	                            if workspace:GetServerTimeNow() < (tonumber(ch:GetAttribute("SpawnShieldUntil")) or 0) then return end
	                            local now = os.clock()
	                            if (rt.InvincibleUntil or 0) > now + 0.42 then rt.InvincibleUntil = now + 0.42 end
	                            if now < (rt.InvincibleUntil or 0) then return end
	                            rt.LastCombatAt = now
	                            local enemyCfg = attackerEnemy and attackerEnemy.Config
	                            local rawHit = math.max(1, tonumber(amount) or (enemyCfg and tonumber(enemyCfg.ATK)) or 18)
	                            local enemyLv = (enemyCfg and tonumber(enemyCfg.Level)) or 10
	                            local defVal = math.max(0, tonumber(stats.DEF) or 10)
	                            -- Genuine Defense mitigation with ZERO unavoidable %MaxHP floor!
	                            local defMit = math.clamp(defVal / (defVal + 180 + enemyLv * 0.35), 0.04, 0.72)
	                            local dTier = resolveActiveDragonTier(p, rt)
	                            local ft = tostring(ch:GetAttribute("FruitTransform") or "")
	                            local tfMult = (dTier >= 2 and 0.72) or ((dTier == 1 or ft ~= "") and 0.82) or 1.0
	                            local targetDmg = math.max(1, rawHit * (1.0 - defMit) * tfMult)
	                            local gsDefFactor = (100 + defVal) / 100
	                            local gsTfFactor = (ft ~= "") and (1.0 / 0.42) or 1.0
	                            prevPlayerDamage(p, math.max(1, math.floor(targetDmg * gsDefFactor * gsTfFactor + 0.5)), attackerEnemy)
	                        end
	                    end

	                    if type(prevTickEnemy) == "function" then
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
	                        end
	                    end

	                    local function safeDashPlayer(p, rt, hrp, dist, invDur, aimDir)
	                        local lookVec = (typeof(aimDir) == "Vector3" and aimDir.Magnitude > 0.05) and aimDir.Unit or hrp.CFrame.LookVector
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

	                    local cachedExpSvc = nil
	                    local function getExpansionSvc()
	                        if cachedExpSvc ~= nil then return cachedExpSvc end
	                        local expMod = services and services:FindFirstChild("SkybreakCombatExpansion")
	                        if expMod then
	                            local okE, modE = pcall(require, expMod)
	                            if okE and type(modE) == "table" then cachedExpSvc = modE end
	                        end
	                        return cachedExpSvc
	                    end
	                    local function dragonPvPHit(attacker, originPos, facing, reach, rawDmg, skillName)
	                        local soc = G.SocialEconomy
	                        if type(soc) == "table" and type(soc.ApplyPvPHitCheck) == "function" then
	                            pcall(soc.ApplyPvPHitCheck, attacker, originPos, facing, reach, rawDmg, skillName)
	                            return
	                        end
	                        local expSvc = getExpansionSvc()
	                        if expSvc and type(expSvc.DamagePlayersInPvPArea) == "function" then
	                            pcall(expSvc.DamagePlayersInPvPArea, attacker, originPos, reach, rawDmg, skillName)
	                        end
	                    end
	                    local function grantDragonMasteryXP(p, xpAmount)
	                        local expSvc = getExpansionSvc()
	                        if expSvc and type(expSvc.AddMasteryXP) == "function" then
	                            pcall(expSvc.AddMasteryXP, p, "AbyssalSovereignCore", xpAmount)
	                        end
	                    end
	                    local function checkDragonMastery(p, profile, reqMastery, keyLabel)
	                        local need = math.max(1, tonumber(reqMastery) or 1)
	                        local mTbl = type(profile.Mastery) == "table" and profile.Mastery or {}
	                        local curLv = math.max(tonumber(mTbl.AbyssalSovereignCore) or 1, tonumber(mTbl.Dragon) or 1)
	                        if curLv < need then
	                            if type(G.Notify) == "function" then
	                                G.Notify(p, string.format("Kỹ năng [%s] yêu cầu Mastery Lv. %d (Hiện tại: Lv. %d)!", tostring(keyLabel), need, curLv))
	                            end
	                            return false
	                        end
	                        return true
	                    end

	                    G.Action = function(p, action, payload)
	                        local profile = okD and D and type(D.Get) == "function" and D.Get(p) or nil
	                        local rt = G.Runtime and G.Runtime[p]
	                        local maxE = resolveMaxEnergy(p, rt, nil)
	                        if rt and rt.Energy == nil then rt.Energy = maxE end
	                        local act = tostring(action or "")
	                        if (act == "Attack" or act == "Light" or act == "M1") and profile and rt then
	                            local slot = math.clamp(tonumber(profile.ActiveSlot) or 2, 1, 4)
	                            if slot == 2 and isDragonFruitId(profile.EquippedFruit) then
	                                local ch = p.Character
	                                local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	                                local tier = resolveActiveDragonTier(p, rt)
	                                if hrp and tier > 0 then
	                                    local now = os.clock()
	                                    if now < (tonumber(rt.StunnedUntil) or 0) then return end
	                                    local cd = (tier == 2) and 0.52 or 0.40
	                                    if now < (rt.Cooldowns and rt.Cooldowns.DragonM1 or 0) then return end
	                                    rt.Cooldowns = rt.Cooldowns or {}
	                                    rt.Cooldowns.DragonM1 = now + cd
	                                    local combo = ((tonumber(rt.DragonM1Combo) or 0) % 4) + 1
	                                    rt.DragonM1Combo = combo
	                                    local stats = type(G.Stats) == "function" and G.Stats(p, 2) or { ATK = 65 }
	                                    local atk = (stats and stats.ATK) or 65
	                                    local isV2Awk = type(profile.AwakenedFruits) == "table" and (profile.AwakenedFruits.AbyssalSovereignCore == true or profile.AwakenedFruits.Dragon == true)
	                                    local v2Boost = isV2Awk and 1.28 or 1.0
	                                    local reach = (tier == 2) and 24 or 16
	                                    local mult = ((tier == 2) and (combo == 4 and 1.65 or 1.30) or (combo == 4 and 1.35 or 1.05)) * v2Boost
	                                    local brk = (tier == 2) and 12 or 8
	                                    local lookVec = resolve3DAim(hrp, payload)
	                                    local center = hrp.Position + lookVec * (reach * 0.45)
	                                    local m1Tag = tier == 2 and "SovereignDragonM1" or "HybridDragonM1"
	                                    local hitCount = 0
	                                    for _, e in ipairs(G.Enemies or {}) do
	                                        if e.Alive and e.Body and ((e.Body.Position - center).Magnitude <= reach or (e.Body.Position - hrp.Position).Magnitude <= reach) then
	                                            hitCount += 1
	                                            G.Hit(p, e, atk * mult, brk, m1Tag)
	                                        end
	                                    end
	                                    dragonPvPHit(p, center, lookVec, reach, atk * mult, m1Tag)
	                                    if hitCount > 0 then
	                                        grantDragonMasteryXP(p, 8 + math.min(hitCount, 4) * 2)
	                                    end
	                                    if combatFXRemote then
	                                        combatFXRemote:FireAllClients({
	                                            Kind = "Swing", Action = "Attack", FruitId = "AbyssalSovereignCore", DragonFormTier = tier,
	                                            SubMode = (tier == 2) and "AbyssalSovereign" or "AbyssalDragonHybrid", Combo = combo, Element = "Void",
	                                            Position = center, Origin = hrp.Position, Direction = lookVec, Actor = p.UserId,
	                                        })
	                                    end
	                                    return
	                                end
	                            end
	                        end
	                        local preE = rt and tonumber(rt.Energy) or maxE
	                        local res = prevAction(p, action, payload)
	                        if rt then
	                            local postMaxE = resolveMaxEnergy(p, rt, nil)
	                            if (tonumber(rt.Energy) or postMaxE) < preE or (act ~= "Attack" and act ~= "Light" and act ~= "M1" and act ~= "Block" and act ~= "Dash" and act ~= "Dodge") then
	                                local now = os.clock()
	                                rt.LastCastAt = now
	                                rt._LastSkillAt = now
	                            end
	                        end
	                        return res
	                    end

	                    G.UseSlotMove = function(p, rawKey, payload)
	                        local profile = okD and D and type(D.Get) == "function" and D.Get(p) or nil
	                        local rt = G.Runtime and G.Runtime[p]
	                        local maxE = resolveMaxEnergy(p, rt, nil)
	                        if rt and rt.Energy == nil then rt.Energy = maxE end
	                        if profile and rt then
	                            local slot = math.clamp(tonumber(profile.ActiveSlot) or 2, 1, 4)
	                            local key = string.upper(tostring(rawKey or "Z"))
	                            if slot == 2 and isDragonFruitId(profile.EquippedFruit) then
	                                profile.EquippedFruit = "AbyssalSovereignCore"
	                                local curTier = resolveActiveDragonTier(p, rt)
	                                -- O Dang Nguoi (curTier == 0) va phim khac V: roi xuong prevUseSlotMove de chay chieu Dang Nguoi, Mastery XP va PvP chuan!
	                                if curTier > 0 or key == "V" then
	                                    local ch = p.Character
	                                    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	                                    if not hrp then return end
	                                    local now = os.clock()
	                                    if now < (tonumber(rt.StunnedUntil) or 0) then return end
	                                    rt.Cooldowns = rt.Cooldowns or {}
	                                    local dFruitCfg = C.AetherFruits and C.AetherFruits.AbyssalSovereignCore
	                                    if key == "V" then
	                                        if now < (rt.Cooldowns.Slot_V or 0) then return end
	                                        local curFury = tonumber(rt.FuryMeter) or tonumber(rt.DragonFury) or 100
	                                        local nextTier = (curTier == 0 and 1) or (curTier == 1 and 2) or 0
	                                        if curTier == 0 then
	                                            local vReqMastery = dFruitCfg and dFruitCfg.Moves and dFruitCfg.Moves.V and dFruitCfg.Moves.V.Mastery
	                                            if not checkDragonMastery(p, profile, vReqMastery, "V") then return end
	                                            if curFury < 15 then
	                                                G.Notify(p, string.format("Cần tối thiểu 15%% Nộ Khí (Fury) để hóa Bán Long Nhân (Hiện tại: %d%%)! / Need 15%% Fury for Hybrid Form 1!", math.floor(curFury)))
	                                                return
	                                            end
	                                        elseif curTier == 1 then
	                                            local vReqMastery = dFruitCfg and dFruitCfg.Moves and dFruitCfg.Moves.V and dFruitCfg.Moves.V.Mastery
	                                            if not checkDragonMastery(p, profile, vReqMastery, "V") or curFury < 25 then
	                                                nextTier = 0
	                                            end
	                                        end
	                                        local vCost = (nextTier == 0) and 0 or 15
	                                        if vCost > 0 and (tonumber(rt.Energy) or 0) < vCost then
	                                            G.Notify(p, "Không đủ Năng Lượng (Energy)! / Not enough Energy!")
	                                            return
	                                        end
	                                        rt.Energy = math.max(0, (tonumber(rt.Energy) or 0) - vCost)
	                                        rt.LastCastAt = now
	                                        rt._LastSkillAt = now
	                                        rt.Cooldowns.Slot_V = now + ((nextTier == 0) and 1.5 or 3.0)
	                                        local tfName = (nextTier == 2 and "AbyssalSovereign") or (nextTier == 1 and "AbyssalDragonHybrid") or ""
	                                        rt.DragonFormTier = nextTier
	                                        rt.FuryMeter = curFury
	                                        rt.DragonFury = curFury
	                                        p:SetAttribute("DragonFormTier", nextTier); p:SetAttribute("FruitTransform", tfName)
	                                        if ch then ch:SetAttribute("DragonFormTier", nextTier); ch:SetAttribute("FruitTransform", tfName) end
	                                        if nextTier < 2 then
	                                            rt.FreeFlightActive = false
	                                            rt.FreeFlightUntil = 0
	                                            p:SetAttribute("SkybreakFlightActive", false)
	                                            p:SetAttribute("FreeFlightUntil", 0)
	                                            if ch then ch:SetAttribute("SkybreakFlightActive", false) end
	                                        end
	                                        local isV2Awk = type(profile.AwakenedFruits) == "table" and (profile.AwakenedFruits.AbyssalSovereignCore == true or profile.AwakenedFruits.Dragon == true)
	                                        local v2Boost = isV2Awk and 1.28 or 1.0
	                                        local stats = type(G.Stats) == "function" and G.Stats(p, 2) or { ATK = 65 }
	                                        local atk = (stats and stats.ATK) or 65
	                                        local canDealBurst = (nextTier > 0) and (now >= (rt.Cooldowns.DragonAscensionDmg or 0))
	                                        if nextTier == 1 then
	                                            G.Notify(p, "[DẠNG 1 • BÁN LONG NHÂN / HYBRID FORM 1] Mở Bộ Kỹ Năng 1 ([Z][X][C] + [F] Long Ảnh Bộ)! Nhấn [V] lần nữa để hóa Rồng Khổng Lồ Dạng 2!")
	                                            if canDealBurst then
	                                                rt.Cooldowns.DragonAscensionDmg = now + 14.0
	                                                local hitCnt = 0
	                                                for _, e in ipairs(G.Enemies or {}) do
	                                                    if e.Alive and e.Body and (e.Body.Position - hrp.Position).Magnitude <= 26 then
	                                                        hitCnt += 1
	                                                        G.Hit(p, e, atk * 2.0 * v2Boost, 16, "DragonHybridAscension_T1")
	                                                    end
	                                                end
	                                                dragonPvPHit(p, hrp.Position, hrp.CFrame.LookVector, 26, atk * 2.0 * v2Boost, "DragonHybridAscension_T1")
	                                                if hitCnt > 0 then grantDragonMasteryXP(p, 20) end
	                                            end
	                                        elseif nextTier == 2 then
	                                            rt.JumpPadUntil = math.max(rt.JumpPadUntil or 0, now + 60)
	                                            profile.UnlockedTitles = type(profile.UnlockedTitles) == "table" and profile.UnlockedTitles or {}
	                                            profile.UnlockedTitles["sovereign_dragon_king"] = true
	                                            G.Notify(p, "[DẠNG 2 • THÁI CỔ LONG HOÀNG / SOVEREIGN FORM 2] Mở khóa Bay 3D [F] Long Vũ Cửu Thiên & Tuyệt Kỹ Long Đế! Nhấn [V] để thu hồi (0 Energy).")
	                                            if canDealBurst then
	                                                rt.Cooldowns.DragonAscensionDmg = now + 14.0
	                                                local hitCnt = 0
	                                                for _, e in ipairs(G.Enemies or {}) do
	                                                    if e.Alive and e.Body and (e.Body.Position - hrp.Position).Magnitude <= 36 then
	                                                        hitCnt += 1
	                                                        G.Hit(p, e, atk * 2.6 * v2Boost, 22, "DragonSovereignAscension_T2")
	                                                    end
	                                                end
	                                                dragonPvPHit(p, hrp.Position, hrp.CFrame.LookVector, 36, atk * 2.6 * v2Boost, "DragonSovereignAscension_T2")
	                                                if hitCnt > 0 then grantDragonMasteryXP(p, 30) end
	                                            end
	                                        else
	                                            G.Notify(p, "Đã thu hồi Long Hồn, trở về nhân dạng (0 Energy). / Reverted to Human form (0 Energy).")
	                                        end
	                                        if combatFXRemote then
	                                            combatFXRemote:FireAllClients({
	                                                Kind = "DragonTransform", DragonFormTier = nextTier, TransformName = tfName, SubMode = tfName,
	                                                Awakened = isV2Awk or (nextTier >= 2), FuryMeter = curFury, Radius = nextTier == 2 and 46 or (nextTier == 1 and 28 or 14),
	                                                Position = hrp.Position, Actor = p.UserId,
	                                            })
	                                        end
	                                        if type(G.Sync) == "function" then G.Sync(p) end
	                                        return
	                                    end

	                                    local moveSet = C.GetDragonFormMoves(curTier)
	                                    local moveSpec = moveSet and moveSet[key]
	                                    if moveSpec then
	                                        local reqM = moveSpec.Mastery or (dFruitCfg and dFruitCfg.Moves and dFruitCfg.Moves[key] and dFruitCfg.Moves[key].Mastery)
	                                        if not checkDragonMastery(p, profile, reqM, key) then return end
	                                        local cdKey = "Slot_" .. key
	                                        if now < (rt.Cooldowns[cdKey] or 0) then return end
	                                        local mCost = math.max(0, tonumber(moveSpec.Cost or moveSpec.EnergyCost) or 0)
	                                        if (tonumber(rt.Energy) or 0) < mCost then
	                                            G.Notify(p, "Không đủ Energy!")
	                                            return
	                                        end
	                                        rt.Energy = math.max(0, (tonumber(rt.Energy) or 0) - mCost)
	                                        rt.LastCastAt = now
	                                        rt._LastSkillAt = now
	                                        rt.Cooldowns[cdKey] = now + (tonumber(moveSpec.Cooldown) or 5.0)
	                                        local stats = type(G.Stats) == "function" and G.Stats(p, 2) or { ATK = 65 }
	                                        local atk = (stats and stats.ATK) or 65
	                                        local lookVec, aimOrigin = resolve3DAim(hrp, payload)
	                                        local originPos = aimOrigin or hrp.Position
	                                        local isV2Awk = type(profile.AwakenedFruits) == "table" and (profile.AwakenedFruits.AbyssalSovereignCore == true or profile.AwakenedFruits.Dragon == true)
	                                        local v2Boost = isV2Awk and 1.28 or 1.0
	                                        local range = tonumber(moveSpec.Range) or 32
	                                        local mult = (tonumber(moveSpec.Multiplier) or 2.5) * v2Boost
	                                        local brk = tonumber(moveSpec.Break) or 20
	                                        local hits = math.max(1, tonumber(moveSpec.Hits) or 1)
	                                        local endPos = originPos + lookVec * range
	                                        local subMode = (curTier >= 2) and "AbyssalSovereign" or "AbyssalDragonHybrid"
	                                        local grantedSkillXP = false
	                                        local function onDragonSkillHit(hitCount)
	                                            if not grantedSkillXP and hitCount > 0 then
	                                                grantedSkillXP = true
	                                                grantDragonMasteryXP(p, 24 + math.min(hitCount, 5) * 4)
	                                            end
	                                        end

	                                        if curTier >= 2 then
	                                            if key == "Z" then
	                                                endPos = originPos + lookVec * 46
	                                                for pulse = 1, 5 do
	                                                    task.delay((pulse - 1) * 0.10, function()
	                                                        if not p or not p.Parent then return end
	                                                        local hc = 0
	                                                        for _, e in ipairs(G.Enemies or {}) do
	                                                            if e.Alive and e.Body then
	                                                                local eb = e.Body.Position
	                                                                local proj = math.clamp((eb - originPos):Dot(lookVec), 0, 46)
	                                                                if (eb - (originPos + lookVec * proj)).Magnitude <= 20 then
	                                                                    hc += 1
	                                                                    G.Hit(p, e, (atk * mult) / 5, math.ceil(brk / 5), "Form2_SovereignBeam_Z")
	                                                                end
	                                                            end
	                                                        end
	                                                        dragonPvPHit(p, originPos + lookVec * 23, lookVec, 28, (atk * mult) / 5, "Form2_SovereignBeam_Z")
	                                                        onDragonSkillHit(hc)
	                                                    end)
	                                                end
	                                            elseif key == "X" then
	                                                endPos = safeDashPlayer(p, rt, hrp, 30, 0.42, lookVec)
	                                                for wave = 1, 4 do
	                                                    task.delay((wave - 1) * 0.13, function()
	                                                        if not p or not p.Parent then return end
	                                                        local hc = 0
	                                                        for _, e in ipairs(G.Enemies or {}) do
	                                                            if e.Alive and e.Body and (e.Body.Position - endPos).Magnitude <= 34 then
	                                                                hc += 1
	                                                                G.Hit(p, e, (atk * mult) / 4, math.ceil(brk / 4), "Form2_SovereignSkyfall_X")
	                                                                e.StunnedUntil = math.max(e.StunnedUntil or 0, os.clock() + 1.0)
	                                                            end
	                                                        end
	                                                        dragonPvPHit(p, endPos, lookVec, 34, (atk * mult) / 4, "Form2_SovereignSkyfall_X")
	                                                        onDragonSkillHit(hc)
	                                                    end)
	                                                end
	                                            elseif key == "C" then
	                                                endPos = originPos + lookVec * 20
	                                                for wave = 1, 6 do
	                                                    task.delay((wave - 1) * 0.14, function()
	                                                        if not p or not p.Parent then return end
	                                                        local hc = 0
	                                                        for _, e in ipairs(G.Enemies or {}) do
	                                                            if e.Alive and e.Body and ((e.Body.Position - endPos).Magnitude <= 42 or (e.Body.Position - originPos).Magnitude <= 22) then
	                                                                hc += 1
	                                                                G.Hit(p, e, (atk * mult) / 6, math.ceil(brk / 6), "Form2_EclipseStarshower_C")
	                                                            end
	                                                        end
	                                                        dragonPvPHit(p, endPos, lookVec, 42, (atk * mult) / 6, "Form2_EclipseStarshower_C")
	                                                        onDragonSkillHit(hc)
	                                                    end)
	                                                end
	                                            elseif key == "F" then
	                                                endPos = safeDashPlayer(p, rt, hrp, 48, 0.42, lookVec)
	                                                local mid = (originPos + endPos) * 0.5
	                                                local hc = 0
	                                                for _, e in ipairs(G.Enemies or {}) do
	                                                    if e.Alive and e.Body and ((e.Body.Position - endPos).Magnitude <= 22 or (e.Body.Position - mid).Magnitude <= 24) then
	                                                        hc += 1
	                                                        G.Hit(p, e, atk * mult, brk, "Form2_SupersonicSoar_F")
	                                                    end
	                                                end
	                                                dragonPvPHit(p, mid, lookVec, 28, atk * mult, "Form2_SupersonicSoar_F")
	                                                onDragonSkillHit(hc)
	                                            end
	                                        else
	                                            if key == "Z" then
	                                                endPos = originPos + lookVec * 32
	                                                for shot = 1, 5 do
	                                                    task.delay((shot - 1) * 0.08, function()
	                                                        if not p or not p.Parent then return end
	                                                        local impactPos = originPos + lookVec * (6.4 * shot)
	                                                        local hc = 0
	                                                        for _, e in ipairs(G.Enemies or {}) do
	                                                            if e.Alive and e.Body and ((e.Body.Position - impactPos).Magnitude <= 16 or (e.Body.Position - endPos).Magnitude <= 16) then
	                                                                hc += 1
	                                                                G.Hit(p, e, (atk * mult) / 5, math.ceil(brk / 5), "Form1_FireballVolley_Z")
	                                                            end
	                                                        end
	                                                        dragonPvPHit(p, impactPos, lookVec, 16, (atk * mult) / 5, "Form1_FireballVolley_Z")
	                                                        onDragonSkillHit(hc)
	                                                    end)
	                                                end
	                                            elseif key == "X" then
	                                                endPos = safeDashPlayer(p, rt, hrp, 20, 0.38, lookVec)
	                                                local hc = 0
	                                                for _, e in ipairs(G.Enemies or {}) do
	                                                    if e.Alive and e.Body and ((e.Body.Position - endPos).Magnitude <= 20 or (e.Body.Position - originPos).Magnitude <= 18) then
	                                                        hc += 1
	                                                        G.Hit(p, e, atk * mult, brk, "Form1_HybridTalonRend_X")
	                                                        e.StunnedUntil = math.max(e.StunnedUntil or 0, os.clock() + 0.9)
	                                                    end
	                                                end
	                                                dragonPvPHit(p, endPos, lookVec, 20, atk * mult, "Form1_HybridTalonRend_X")
	                                                onDragonSkillHit(hc)
	                                            elseif key == "C" then
	                                                endPos = originPos
	                                                for pulse = 1, 4 do
	                                                    task.delay((pulse - 1) * 0.12, function()
	                                                        if not p or not p.Parent then return end
	                                                        local curPos = (p.Character and p.Character:FindFirstChild("HumanoidRootPart") and p.Character.HumanoidRootPart.Position) or originPos
	                                                        local hc = 0
	                                                        for _, e in ipairs(G.Enemies or {}) do
	                                                            if e.Alive and e.Body and (e.Body.Position - curPos).Magnitude <= 26 then
	                                                                hc += 1
	                                                                G.Hit(p, e, (atk * mult) / 4, math.ceil(brk / 4), "Form1_InfernoCyclone_C")
	                                                                if not (e.Config and e.Config.Boss) and (e.Config and (e.Config.Speed or 0) > 0) and e.Model then
	                                                                    local pullPos = e.Body.Position:Lerp(Vector3.new(curPos.X, e.Body.Position.Y, curPos.Z), 0.35)
	                                                                    local rot = e.Body.CFrame - e.Body.Position
	                                                                    e.Model:PivotTo(CFrame.new(pullPos) * rot)
	                                                                end
	                                                            end
	                                                        end
	                                                        dragonPvPHit(p, curPos, lookVec, 26, (atk * mult) / 4, "Form1_InfernoCyclone_C")
	                                                        onDragonSkillHit(hc)
	                                                    end)
	                                                end
	                                            elseif key == "F" then
	                                                local flatLook = Vector3.new(lookVec.X, 0, lookVec.Z)
	                                                local groundDashDir = flatLook.Magnitude > 0.05 and flatLook.Unit or hrp.CFrame.LookVector
	                                                endPos = safeDashPlayer(p, rt, hrp, 32, 0.38, groundDashDir)
	                                                local hc = 0
	                                                for _, e in ipairs(G.Enemies or {}) do
	                                                    if e.Alive and e.Body and (e.Body.Position - endPos).Magnitude <= 16 then
	                                                        hc += 1
	                                                        G.Hit(p, e, atk * mult, brk, "Form1_HybridWingDash_F")
	                                                    end
	                                                end
	                                                dragonPvPHit(p, endPos, groundDashDir, 18, atk * mult, "Form1_HybridWingDash_F")
	                                                onDragonSkillHit(hc)
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
	                        end
	                        local preE = rt and tonumber(rt.Energy) or maxE
	                        local res = prevUseSlotMove(p, rawKey, payload)
	                        if rt then
	                            local postMaxE = resolveMaxEnergy(p, rt, nil)
	                            if (tonumber(rt.Energy) or postMaxE) < preE then
	                                local now = os.clock()
	                                rt.LastCastAt = now
	                                rt._LastSkillAt = now
	                            end
	                        end
	                        return res
	                    end

	                    if type(G.UseSkill) == "function" then
	                        local prevUseSkill = G.UseSkill
	                        G.UseSkill = function(p, skillId, ...)
	                            local rt = G.Runtime and G.Runtime[p]
	                            local maxE = resolveMaxEnergy(p, rt, nil)
	                            if rt and rt.Energy == nil then rt.Energy = maxE end
	                            local res = prevUseSkill(p, skillId, ...)
	                            if rt then
	                                resolveMaxEnergy(p, rt, nil)
	                                local now = os.clock()
	                                rt.LastCastAt = now
	                                rt._LastSkillAt = now
	                            end
	                            return res
	                        end
	                    end

	                    task.spawn(function()
	                        local lastLoopAt = os.clock()
	                        while true do
	                            task.wait(0.25)
	                            local now = os.clock()
	                            local dt = math.clamp(now - lastLoopAt, 0.05, 1.0)
	                            lastLoopAt = now
	                            if type(G.Runtime) == "table" then
	                                for plr, rt in pairs(G.Runtime) do
	                                    if type(rt) == "table" then
	                                        if rt.FuryMeter == nil then rt.FuryMeter = 100 end
	                                        local maxE = resolveMaxEnergy(typeof(plr) == "Instance" and plr or nil, rt, nil)
	                                        if rt.Energy == nil then rt.Energy = maxE end

	                                        -- Out-of-combat dynamic MaxEnergy regen (maxE * 0.08 * dt)
	                                        local lastSkill = math.max(tonumber(rt.LastCastAt) or 0, tonumber(rt._LastSkillAt) or 0)
	                                        if now - lastSkill >= 1.5 and now >= (tonumber(rt.ActionUntil) or 0) then
	                                            local curE = tonumber(rt.Energy) or maxE
	                                            if curE < maxE and math.abs(curE - (tonumber(rt._PrevLoopEnergy) or curE)) < 0.01 then
	                                                rt.Energy = math.min(maxE, curE + maxE * 0.08 * dt)
	                                            end
	                                        end
	                                        rt._PrevLoopEnergy = tonumber(rt.Energy) or maxE

	                                        -- Real Dragon Fury Meter: +3/s out-of-combat regen, 1.8 Fury/s gentle combat drain in Form 2
	                                        if typeof(plr) == "Instance" and plr.Parent then
	                                            local dTier = resolveActiveDragonTier(plr, rt)
	                                            local profChk = okD and D and type(D.Get) == "function" and D.Get(plr) or nil
	                                            if dTier > 0 and profChk and not isDragonFruitId(profChk.EquippedFruit) then
	                                                rt.DragonFormTier = 0
	                                                rt.FreeFlightActive = false
	                                                rt.FreeFlightUntil = 0
	                                                plr:SetAttribute("DragonFormTier", 0)
	                                                plr:SetAttribute("FruitTransform", "")
	                                                plr:SetAttribute("SkybreakFlightActive", false)
	                                                plr:SetAttribute("FreeFlightUntil", 0)
	                                                if plr.Character then
	                                                    plr.Character:SetAttribute("DragonFormTier", 0)
	                                                    plr.Character:SetAttribute("FruitTransform", "")
	                                                    plr.Character:SetAttribute("SkybreakFlightActive", false)
	                                                end
	                                                dTier = 0
	                                            end
	                                            local lastCombat = math.max(tonumber(rt.LastCombatAt) or 0, tonumber(rt.LastHurt) or 0)
	                                            local inCombat = (now - lastCombat) < 5.0
	                                            local curFury = tonumber(rt.FuryMeter) or tonumber(rt.DragonFury) or 100
	                                            if dTier >= 2 and inCombat then
	                                                curFury = math.max(0, curFury - 1.8 * dt)
	                                                rt.FuryMeter = curFury
	                                                rt.DragonFury = curFury
	                                                if curFury <= 0 then
	                                                    local ch = plr.Character
	                                                    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
	                                                    rt.DragonFormTier = 0
	                                                    rt.FreeFlightActive = false
	                                                    rt.FreeFlightUntil = 0
	                                                    plr:SetAttribute("DragonFormTier", 0)
	                                                    plr:SetAttribute("FruitTransform", "")
	                                                    plr:SetAttribute("SkybreakFlightActive", false)
	                                                    plr:SetAttribute("FreeFlightUntil", 0)
	                                                    if ch then
	                                                        ch:SetAttribute("DragonFormTier", 0)
	                                                        ch:SetAttribute("FruitTransform", "")
	                                                        ch:SetAttribute("SkybreakFlightActive", false)
	                                                    end
	                                                    if combatFXRemote and hrp then
	                                                        combatFXRemote:FireAllClients({
	                                                            Kind = "DragonTransform", DragonFormTier = 0, TransformName = "", SubMode = "",
	                                                            Awakened = true, FuryMeter = 0, Radius = 14, Position = hrp.Position, Actor = plr.UserId,
	                                                        })
	                                                    end
	                                                    if type(G.Notify) == "function" then
	                                                        G.Notify(plr, "Nộ Khí (Fury) đã cạn — Thu hồi Thái Cổ Long Hoàng, trở về nhân dạng! / Fury depleted — Reverted to Human form!")
	                                                    end
	                                                    if type(G.Sync) == "function" then G.Sync(plr) end
	                                                end
	                                            elseif not inCombat and curFury < 100 then
	                                                curFury = math.min(100, curFury + 3.0 * dt)
	                                                rt.FuryMeter = curFury
	                                                rt.DragonFury = curFury
	                                            else
	                                                rt.FuryMeter = curFury
	                                                rt.DragonFury = curFury
	                                            end
	                                            local roundedFury = math.floor((tonumber(rt.FuryMeter) or 100) + 0.5)
	                                            plr:SetAttribute("FuryMeter", roundedFury)
	                                            plr:SetAttribute("DragonFury", roundedFury)
	                                            if plr.Character then
	                                                plr.Character:SetAttribute("FuryMeter", roundedFury)
	                                                plr.Character:SetAttribute("DragonFury", roundedFury)
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
end

return Overrides
