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
	                if type(G.Runtime) == "table" then
	                    for plr, rt in pairs(G.Runtime) do
	                        if type(rt) == "table" then
	                            rt.FuryMeter = 100
	                            rt.MaxEnergy = 100
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
	                                    -- Chi tinh trang bi dung nhom o (chan profile cu da deo 1 vu khi vao nhieu o)
	                                    if item and slot ~= "Weapon" and SLOT_GROUP[tostring(item.Slot or "")] ~= grp then
	                                        item = nil
	                                    end
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
	                            local rt = G.Runtime and G.Runtime[p]
	                            local preEnergy = rt and tonumber(rt.Energy) or nil
	                            prevHit(p, e, math.max(1, scaledDmg), scaledBreak, action)
	                            if rt then
	                                rt.MaxEnergy = 100
	                                if isBasic then
	                                    rt.Energy = math.clamp((preEnergy or 100) + 6, 0, 100)
	                                elseif preEnergy ~= nil then
	                                    rt.Energy = math.clamp(preEnergy, 0, 100)
	                                end
	                            end
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

	                    -- Danh dau don "direct strike" ben duoi de PlayerDamage biet day khong phai don goc cua GameService.
	                    local directStrikeActive = false
	                    if type(prevPlayerDamage) == "function" then
	                        G.PlayerDamage = function(p, amount, attackerEnemy)
	                            if type(attackerEnemy) == "table" and not directStrikeActive then
	                                attackerEnemy._LastNativeHitAt = os.clock()
	                            end
	                            local ch = p and p.Character
	                            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	                            local rt = G.Runtime and G.Runtime[p]
	                            local profile = okD and D and type(D.Get) == "function" and D.Get(p) or nil
	                            local stats = type(G.Stats) == "function" and G.Stats(p) or nil
	                            if not ch or not hum or hum.Health <= 0 or not rt or not stats then return end
	                            if workspace:GetServerTimeNow() < (tonumber(ch:GetAttribute("SpawnShieldUntil")) or 0) then return end
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
	                            -- Direct strike chi la du phong cho quai co don goc khong trung. Truoc day ca hai cung gay sat thuong
	                            -- (moi quai ~2 don/giay), Lv120 + 357 diem chi so van chet trong 3s truoc Corrupted Guard cua Q02.
	                            local nativeLanding = (now - (e._LastNativeHitAt or -99)) < 2.0
	                            if eAtk > 0 and not nativeLanding and now >= (e.StunnedUntil or 0) and now >= (e.BossBrokenUntil or 0) and now >= (e._BalNextDirectStrike or 0) then
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
	                                            directStrikeActive = true
	                                            pcall(G.PlayerDamage, bestPlr, eAtk, e)
	                                            directStrikeActive = false
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
	                        if rt then
	                            rt.MaxEnergy = 100
	                            if rt.Energy == nil then rt.Energy = 100 end
	                        end
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
	                        local preE = rt and tonumber(rt.Energy) or 100
	                        local res = prevAction(p, action, payload)
	                        if rt then
	                            rt.MaxEnergy = 100
	                            if (tonumber(rt.Energy) or 100) < preE or (act ~= "Attack" and act ~= "Light" and act ~= "M1" and act ~= "Block" and act ~= "Dash" and act ~= "Dodge") then
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
	                        if rt then
	                            rt.MaxEnergy = 100
	                            if rt.Energy == nil then rt.Energy = 100 end
	                        end
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
	                                    local vCost = (curTier >= 2) and 0 or 15
	                                    if (tonumber(rt.Energy) or 0) < vCost then
	                                        G.Notify(p, "Không đủ Energy!")
	                                        return
	                                    end
	                                    rt.Energy = math.max(0, (tonumber(rt.Energy) or 0) - vCost)
	                                    rt.LastCastAt = now
	                                    rt._LastSkillAt = now
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
	                                    local mCost = math.max(0, tonumber(moveSpec.Cost or moveSpec.EnergyCost) or 0)
	                                    if (tonumber(rt.Energy) or 0) < mCost then
	                                        G.Notify(p, "Không đủ Energy!")
	                                        return
	                                    end
	                                    rt.Energy = math.max(0, (tonumber(rt.Energy) or 0) - mCost)
	                                    rt.LastCastAt = now
	                                    rt._LastSkillAt = now
	                                    rt.Cooldowns[cdKey] = now + (tonumber(moveSpec.Cooldown) or 5.0)
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
	                        local preE = rt and tonumber(rt.Energy) or 100
	                        local res = prevUseSlotMove(p, rawKey, payload)
	                        if rt then
	                            rt.MaxEnergy = 100
	                            if (tonumber(rt.Energy) or 100) < preE then
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
	                            if rt then
	                                rt.MaxEnergy = 100
	                                if rt.Energy == nil then rt.Energy = 100 end
	                            end
	                            local res = prevUseSkill(p, skillId, ...)
	                            if rt then
	                                rt.MaxEnergy = 100
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
	                                        rt.FuryMeter = 100
	                                        rt.MaxEnergy = 100
	                                        if rt.Energy == nil then rt.Energy = 100 end
	                                        local lastSkill = math.max(tonumber(rt.LastCastAt) or 0, tonumber(rt._LastSkillAt) or 0)
	                                        if now - lastSkill >= 1.5 and now >= (tonumber(rt.ActionUntil) or 0) then
	                                            local curE = tonumber(rt.Energy) or 100
	                                            if curE < 100 and math.abs(curE - (tonumber(rt._PrevLoopEnergy) or curE)) < 0.01 then
	                                                rt.Energy = math.min(100, curE + 8 * dt)
	                                            end
	                                        end
	                                        rt._PrevLoopEnergy = tonumber(rt.Energy) or 100
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
end

return Overrides
