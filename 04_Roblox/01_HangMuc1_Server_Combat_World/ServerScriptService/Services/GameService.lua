local Players=game:GetService("Players")
local Debris=game:GetService("Debris")
local TweenService=game:GetService("TweenService")
local RunService=game:GetService("RunService")
local _V3,_RGB,_IN,_CF,_CFA,_UD2S=Vector3.new,Color3.fromRGB,Instance.new,CFrame.new,CFrame.Angles,UDim2.fromScale
local C=require(game.ReplicatedStorage.Shared.Config)
local D=require(script.Parent.PlayerDataService)
local W=require(script.Parent.WorldService)
local Cosmetics=require(script.Parent.CosmeticService)
local DevGate=require(script.Parent.DevGate)
local RemoteGuard=require(script.Parent.RemoteGuard)
local G={Runtime={},Joining={},Enemies={},Boss=nil,Preparing=false,ResetAt=0,Chests={},Shrines={},JumpPads={},WorldPortals={}}
local R=game.ReplicatedStorage.Remotes
if not R:FindFirstChild("CombatEvent") then
	local ce=_IN("RemoteEvent")
	ce.Name="CombatEvent"
	ce.Parent=R
end

local StaticData=require(script.Parent.GameStaticData)
local Helpers=require(script.Parent.GameExperienceHelpers)
local LiveOps=require(script.Parent.SkybreakLiveOpsService)
local Monetization=nil
local function getMonetization()
	if Monetization==nil then
		local m=script.Parent:FindFirstChild("MonetizationService")
		if m and m:IsA("ModuleScript") then
			local ok,mod=pcall(require,m)
			Monetization=(ok and type(mod)=="table") and mod or false
		else
			Monetization=false
		end
	end
	return Monetization or nil
end
local BLENDER_ENEMIES=StaticData.BLENDER_ENEMIES
local FALLBACK_FRUITS=StaticData.FALLBACK_FRUITS
local FALLBACK_STYLES=StaticData.FALLBACK_STYLES
local FALLBACK_GUNS=StaticData.FALLBACK_GUNS
local FALLBACK_FAST_TRAVEL=StaticData.FALLBACK_FAST_TRAVEL
local FALLBACK_ENEMIES=StaticData.FALLBACK_ENEMIES
G.StaticData=StaticData
G.Helpers=Helpers
G.LiveOps=LiveOps

local RACE_ORDER={"Skyborn","Mink","Leviathan","Cyborg","Ghoul","Draco"}

local function getFruitCfg(fruitId)
	local tbl=C.AetherFruits or FALLBACK_FRUITS
	return (fruitId and (tbl[fruitId] or FALLBACK_FRUITS[fruitId])) or tbl.SolarTitanCore or FALLBACK_FRUITS.SolarTitanCore
end

local function getStyleCfg(styleId)
	local tbl=C.FightingStyles or FALLBACK_STYLES
	return (styleId and (tbl[styleId] or FALLBACK_STYLES[styleId])) or tbl.SkybornCombat or FALLBACK_STYLES.SkybornCombat
end

local function getGunCfg(gunId)
	local tbl=C.Guns or FALLBACK_GUNS
	return (gunId and (tbl[gunId] or FALLBACK_GUNS[gunId])) or tbl.soul_guitar_void or FALLBACK_GUNS.soul_guitar_void
end

local EQUIP_SLOT_ALIASES={
	Helm={"Helm","Helmet"},
	Helmet={"Helm","Helmet"},
	Gauntlets={"Gauntlets","Gloves"},
	Gloves={"Gauntlets","Gloves"},
	Greaves={"Greaves","Boots"},
	Boots={"Greaves","Boots"},
	Offhand={"Offhand","Necklace"},
	Necklace={"Offhand","Necklace"},
}
local EQUIP_SLOT_GROUP={
	Weapon="Weapon",
	Helmet="Head", Helm="Head",
	Chest="Chest",
	Gloves="Hands", Gauntlets="Hands",
	Boots="Feet", Greaves="Feet",
	Ring="Ring",
	Necklace="Offhand", Offhand="Offhand",
	Artifact="Artifact",
}

local function ensureProfileFields(profile)
	if not profile then return end
	local maxLv=C.MaxLevel or 2550
	local maxSt=C.MaxStat or 2550
	if not profile.ClassId or not C.Classes[profile.ClassId] then
		profile.ClassId="SkyGuardian"
	end
	profile.Level=math.clamp(math.floor(tonumber(profile.Level) or 1),1,maxLv)
	profile.XP=math.max(0,tonumber(profile.XP) or 0)
	profile.Gold=math.max(0,tonumber(profile.Gold) or 0)
	profile.CoreShards=math.max(0,tonumber(profile.CoreShards) or 0)
	profile.QuestIndex=math.max(1,math.floor(tonumber(profile.QuestIndex) or 1))
	profile.Inventory=type(profile.Inventory)=="table" and profile.Inventory or {}
	profile.Equipped=type(profile.Equipped)=="table" and profile.Equipped or {}
	profile.Progress=type(profile.Progress)=="table" and profile.Progress or {}
	profile.CompletedQuests=type(profile.CompletedQuests)=="table" and profile.CompletedQuests or {}
	profile.FirstClearBosses=type(profile.FirstClearBosses)=="table" and profile.FirstClearBosses or {}
	profile.SkillLevels=type(profile.SkillLevels)=="table" and profile.SkillLevels or {}
	profile.StatPoints=math.max(0,math.floor(tonumber(profile.StatPoints) or 0))
	profile.StatAlloc=type(profile.StatAlloc)=="table" and profile.StatAlloc or {Melee=1,Defense=1,Sword=1,Gun=1,Fruit=1}
	local spentStats=0
	for _,k in ipairs({"Melee","Defense","Sword","Gun","Fruit"}) do
		if type(profile.StatAlloc[k])~="number" or profile.StatAlloc[k]<1 then
			profile.StatAlloc[k]=1
		else
			profile.StatAlloc[k]=math.clamp(math.floor(profile.StatAlloc[k]),1,maxSt)
		end
		spentStats+=(profile.StatAlloc[k]-1)
	end
	local expectedTotal=(profile.Level-1)*(C.StatPointsPerLevel or 3)
	if spentStats+profile.StatPoints<expectedTotal then
		profile.StatPoints=expectedTotal-spentStats
	end
	profile.ActiveSlot=math.clamp(tonumber(profile.ActiveSlot) or 1,1,4)
	profile.FightingStyle=profile.FightingStyle or "SkybornCombat"
	profile.UnlockedStyles=type(profile.UnlockedStyles)=="table" and profile.UnlockedStyles or {
		SkybornCombat=true,
	}
	profile.UnlockedStyles.SkybornCombat=true
	profile.EquippedFruit=type(profile.EquippedFruit)=="string" and profile.EquippedFruit or ""
	profile.HeldFruit=type(profile.HeldFruit)=="string" and profile.HeldFruit or ""
	profile.StoredFruits=type(profile.StoredFruits)=="table" and profile.StoredFruits or {}
	profile.AwakenedFruits=type(profile.AwakenedFruits)=="table" and profile.AwakenedFruits or {}
	profile.EquippedGun=profile.EquippedGun or "aether_flintlock"
	profile.Mastery=type(profile.Mastery)=="table" and profile.Mastery or {
		SkybornCombat=1, starter_sword=1, aether_flintlock=1,
	}
	profile.Haki=type(profile.Haki)=="table" and profile.Haki or {
		Aura=false, AuraStage=1, Instinct=false, InstinctDodges=8, ConquerorUnlocked=false,
	}
	if profile.Haki.InstinctDodges==nil then profile.Haki.InstinctDodges=8 end
	profile.Race=profile.Race or "Skyborn"
	profile.RaceTier=math.clamp(math.floor(tonumber(profile.RaceTier) or (profile.RaceV4Unlocked and 4 or 1)),1,4)
	profile.RaceV4Active=(profile.RaceV4Unlocked==true and profile.RaceV4Active==true)
	if profile.AwakeningMeter==nil then
		profile.AwakeningMeter=0
	end
	profile.ClassChosen=(profile.ClassChosen==true)
	profile.RaidChipsCleared=math.max(0,math.floor(tonumber(profile.RaidChipsCleared) or 0))
	profile.MicrochipRaidsCleared=type(profile.MicrochipRaidsCleared)=="table" and profile.MicrochipRaidsCleared or {}
	profile.QuestProgress=profile.Progress
	profile.Faction=profile.Faction or "Pirate"
	profile.Bounty=profile.Bounty or 0
	profile.Honor=profile.Honor or 0
	profile.Title=profile.Title or "sky_rookie"
	profile.OwnedGamePasses=type(profile.OwnedGamePasses)=="table" and profile.OwnedGamePasses or {}
	if profile.OwnedGamePasses.golden_sky_ship==true then
		profile.UnlockedShips=type(profile.UnlockedShips)=="table" and profile.UnlockedShips or {SkySloop=true}
		profile.UnlockedShips.GoldenSovereignSloop=true
		profile.UnlockedShips.SkyGalleon=true
	end
	if profile.OwnedGamePasses.sovereign_name_aura==true then
		profile.UnlockedTitles=type(profile.UnlockedTitles)=="table" and profile.UnlockedTitles or {sky_rookie=true}
		profile.UnlockedTitles.celestial_vip=true
	end
	profile.UnlockedWorlds=type(profile.UnlockedWorlds)=="table" and profile.UnlockedWorlds or {}
	profile.UnlockedWorlds.SkyHub=true
	profile.UnlockedWorlds.GoldenSky=true
	profile.PartySize=profile.PartySize or "Solo"
	profile.FruitPity=math.clamp(math.floor(tonumber(profile.FruitPity) or 0),0,C.FruitPityMax or 50)
	profile.FreeFruitVouchers=math.max(0,math.floor(tonumber(profile.FreeFruitVouchers) or 0))
	profile.StatRefundTokens=math.max(0,math.floor(tonumber(profile.StatRefundTokens) or 0))
	profile.DoubleExpRemainingSec=math.max(0,math.floor(tonumber(profile.DoubleExpRemainingSec or profile.DoubleExpRemaining or profile.DoubleExpSeconds) or 0))
	profile.UnlockedBadges=type(profile.UnlockedBadges)=="table" and profile.UnlockedBadges or {}
	profile.HighestBossDPS=math.max(0,math.floor(tonumber(profile.HighestBossDPS) or 0))
	Helpers.SyncDiscoveredIslands(profile,C)
	Helpers.CheckAndAutoUnlockConqueror(nil,profile,nil,nil)
end

local COMPANION_LIST={
	{Id="Kairo", Name="Kairo • Vanguard", ClassId="SkyGuardian", VisualAsset="Male_SkyGuardian", Role="TANK", UnlockLevel=15, HP=1800, MaxHP=1800, ATK=42, Offset=_V3(-10,0,-5)},
	{Id="Lumen", Name="Lumen • Starweaver", ClassId="ArcaneMage", VisualAsset="ArcaneMage", Role="HEALER", UnlockLevel=30, HP=1350, MaxHP=1350, ATK=48, Offset=_V3(10,0,-5)},
	{Id="Nyx", Name="Nyx • Shadowblitz", ClassId="ThunderStriker", VisualAsset="ThunderStrikerFemale", Role="ASSASSIN", UnlockLevel=50, HP=1450, MaxHP=1450, ATK=55, Offset=_V3(0,0,-9)},
}
local COMPANION_SPECS={}
for _,s in ipairs(COMPANION_LIST) do COMPANION_SPECS[s.Id]=s end

local function maxPartySizeForLevel(level)
	local lv=tonumber(level) or 1
	if lv>=50 then return "Squad"
	elseif lv>=30 then return "Trio"
	elseif lv>=15 then return "Duo"
	else return "Solo" end
end

local function getCompanionIds() return {} end -- Tính năng 3 AI đã bị gỡ

local function root(player)
	local ch=player.Character local h=ch and ch:FindFirstChildOfClass("Humanoid")
	local r=ch and ch:FindFirstChild("HumanoidRootPart")
	if h and r and h.Health>0 then return r,h end
end
local function distance(a,b) return (a-b).Magnitude end
local function finiteVector(v)
	return typeof(v)=="Vector3" and v.X==v.X and v.Y==v.Y and v.Z==v.Z and math.abs(v.X)<1e6 and math.abs(v.Y)<1e6 and math.abs(v.Z)<1e6
end
local function safeGroundY(pos, refFloorY)
	local gy=W.GroundY(pos, refFloorY)
	if refFloorY then
		if math.abs(gy-refFloorY)>32.0 then
			return refFloorY
		end
		return gy
	end
	if math.abs(gy-pos.Y)>36 then
		return pos.Y-2.5
	end
	return gy
end

function G.FireCombatEvent(payload)
	if R:FindFirstChild("CombatEvent") then
		R.CombatEvent:FireAllClients(payload)
	end
	if payload.Position or payload.pos then
		local fxPayload=table.clone(payload)
		fxPayload.Kind=fxPayload.Kind or "Hit"
		fxPayload.Position=fxPayload.Position or fxPayload.pos
		if not fxPayload.Text and fxPayload.amount then
			fxPayload.Text=fxPayload.crit and (tostring(fxPayload.amount).."!") or tostring(fxPayload.amount)
		end
		R.CombatFX:FireAllClients(fxPayload)
	end
end

function G.Notify(p,text) R.StateUpdate:FireClient(p,{Message=text}) end
function G.SendDialogue(p,speaker,role,text,actionLabel,actionCommand,choices)
	R.StateUpdate:FireClient(p,{
		Message=speaker..": "..text,
		Dialogue={
			speaker=speaker,
			role=role or "SKYBORN NPC",
			text=text,
			actionLabel=actionLabel,
			actionCommand=actionCommand,
			choices=choices,
			Choices=choices,
		}
	})
end
function G.ResolveWorldOrderFromPos(pos)
	if not G.WorldPortals or typeof(pos)~="Vector3" then return 1 end
	local bestOrder,bestDist=1,math.huge
	for i=1,20 do
		local gate=G.WorldPortals[string.format("WorldGate_%02d",i)]
		local prevGate=G.WorldPortals[string.format("WorldGate_%02d",i==1 and 20 or (i-1))]
		if gate and gate.Pos then
			local exitPos=gate.Pos
			local entryPos=(prevGate and prevGate.TargetPos) or exitPos
			local midPos=(exitPos+entryPos)*0.5
			local d=math.min((pos-exitPos).Magnitude,(pos-entryPos).Magnitude,(pos-midPos).Magnitude)
			if d<bestDist then
				bestDist=d
				bestOrder=i
			end
		end
	end
	return bestOrder
end
local REALM_MIN_LV={FrozenCyber=700,ShadowRealm=1500,VerdantCrown=2200,EmberforgeWastes=2270,AbyssalTides=2340,ChronosBastion=2410,VeilsEnd=2480}
local function inLockedEncounter(p)
	return (G.Boss and G.Boss.Party and G.Boss.Party[p])
		or p:GetAttribute("InTrade")==true
		or p:GetAttribute("InRaceTrial")==true
		or p:GetAttribute("RaidActive")==true
		or p:GetAttribute("InColosseum")==true
		or p:GetAttribute("ColosseumActive")==true
		or (tonumber(p:GetAttribute("SpireFloor")) or 0)>0
		or (tonumber(p:GetAttribute("PvPCombatUntil")) or 0)>os.time()
end

function G.FindSafeRescuePos(p, rPos, rt, profile)
	local curRealm = (p and p:GetAttribute("CurrentRealm")) or "GoldenSky"
	local candidates = {}
	if rt and rt.LastGroundedPos and finiteVector(rt.LastGroundedPos) and rt.LastGroundedPos.Y > 15 then
		if not finiteVector(rPos) or _V3(rt.LastGroundedPos.X - rPos.X, 0, rt.LastGroundedPos.Z - rPos.Z).Magnitude < 2500 then
			table.insert(candidates, {pos=rt.LastGroundedPos, realm=curRealm})
		end
	end
	if curRealm ~= "GoldenSky" then
		local okRC, rc = pcall(require, game:GetService("ReplicatedStorage").Shared.RealmConfig)
		if okRC and rc and rc[curRealm] and rc[curRealm].Spawn then
			table.insert(candidates, {pos=rc[curRealm].Spawn, realm=curRealm})
		end
	end
	if G.WorldPortals and finiteVector(rPos) then
		local bestGate, bestDist = nil, math.huge
		for i = 1, 20 do
			local gate = G.WorldPortals[string.format("WorldGate_%02d", i)]
			if gate and gate.Pos then
				local d = _V3(rPos.X - gate.Pos.X, 0, rPos.Z - gate.Pos.Z).Magnitude
				if d < bestDist then
					bestDist = d
					bestGate = gate
				end
			end
		end
		if bestGate and bestDist < 2200 then
			table.insert(candidates, {pos=bestGate.Pos, realm=curRealm})
		end
	end
	local cpNode = (profile and profile.Checkpoint and C.FastTravel[profile.Checkpoint]) or C.FastTravel.GoldenSky
	if cpNode and cpNode.Pos then
		table.insert(candidates, {pos=cpNode.Pos, realm=cpNode.Realm or "GoldenSky"})
	end
	table.insert(candidates, {pos=C.Spawn or _V3(-317.4, 50.5, 527.8), realm="GoldenSky"})

	for _, entry in ipairs(candidates) do
		local cand = entry.pos
		local snapped = cand
		if W.SnapToOpenGround then
			snapped = select(1, W.SnapToOpenGround(cand, cand.Y - 3.2, 3.5))
		end
		if W.RaycastGround then
			local hit = W.RaycastGround(snapped, snapped.Y - 3.5)
			if hit and hit.Instance and hit.Instance.CanCollide and hit.Position.Y > 12 then
				if not (W.IsBlockedByObstacle and W.IsBlockedByObstacle(snapped.X, hit.Position.Y, snapped.Z, 3.5)) then
					if p and entry.realm then p:SetAttribute("CurrentRealm", entry.realm) end
					return _V3(snapped.X, hit.Position.Y + 3.5, snapped.Z)
				end
			end
		else
			if p and entry.realm then p:SetAttribute("CurrentRealm", entry.realm) end
			return _V3(snapped.X, math.max(snapped.Y, 50.5), snapped.Z)
		end
	end
	if p then p:SetAttribute("CurrentRealm", "GoldenSky") end
	local sp = C.Spawn or _V3(-317.4, 50.5, 527.8)
	local gy = safeGroundY(sp, 46.5)
	return _V3(sp.X, gy + 3.5, sp.Z)
end

function G.Teleport(p,pos,moveCompanions,forceInternal)
	local r,h=root(p) local rt=G.Runtime[p]
	if not forceInternal and p and (tonumber(p:GetAttribute("PvPCombatUntil")) or 0)>os.time()
		and p:GetAttribute("InColosseum")~=true and p:GetAttribute("ColosseumActive")~=true
		and (tonumber(p:GetAttribute("SpireFloor")) or 0)<=0 and p:GetAttribute("RaidActive")~=true then
		if not r or (pos-r.Position).Magnitude>115 then
			LiveOps.Notify(G,p,"Đang trong trạng thái Giao Tranh PvP! Không thể dịch chuyển!","Cannot teleport while PvP combat-tagged!")
			return false
		end
	end
	if r then
		if W.SnapToOpenGround then
			pos=select(1,W.SnapToOpenGround(pos,pos.Y-3.0,3.5))
		end
		if W.RaycastGround then
			local hit=W.RaycastGround(pos,pos.Y-3.5)
			if hit and hit.Position.Y>10 then
				pos=_V3(pos.X,hit.Position.Y+3.5,pos.Z)
			end
		end
		local oldPos=r.Position
		r.Anchored=false
		if h then
			h.PlatformStand=false
		end
		r.CFrame=_CF(pos)*r.CFrame.Rotation
		r.AssemblyLinearVelocity=Vector3.zero
		r.AssemblyAngularVelocity=Vector3.zero
		if R:FindFirstChild("StateUpdate") then
			R.StateUpdate:FireClient(p,{TeleportSnap=pos})
		end
		if rt then
			rt.Safe=pos
			rt.LastGroundedPos=pos
			rt.MoveAt=os.clock()
			rt.JumpPadUntil=math.max(rt.JumpPadUntil or 0,rt.MoveAt+1.5)
			if moveCompanions~=false and (pos-oldPos).Magnitude>28 and rt.Companions then
				for _,comp in pairs(rt.Companions) do
					if comp.Root and comp.Root.Parent then
						local cpos=pos+comp.Spec.Offset
						local fy=safeGroundY(cpos,pos.Y-2.5)
						comp.Root.CFrame=_CF(cpos.X,fy+2.5,cpos.Z)
						if comp.Model then comp.Model:SetAttribute("EnemyFloorY",fy) end
					end
				end
			end
		end
		if G.UpdatePlayerPortalCompass then
			local resolvedOrder=G.ResolveWorldOrderFromPos(pos)
			local profile=D.Get(p)
			if profile then profile.CurrentWorldOrder=resolvedOrder end
			G.UpdatePlayerPortalCompass(p,resolvedOrder)
		end
	end
end
local function clearLine(_a,_b)
	return true
end
function G.Stats(p,slotOverride)
	local profile=D.Get(p) if not profile then return end
	ensureProfileFields(profile)
	local effSlot=slotOverride or (G._StatSlotOverride and G._StatSlotOverride[p]) or profile.ActiveSlot
	return Helpers.ComputeStats(C,profile,effSlot,p)
end

function G.SyncCompanions() end -- Giữ tên hàm cho các nơi gọi cũ; tính năng 3 AI đã bị gỡ

local function findActiveBossForPlayer(p)
	local r=root(p)
	if G.Boss and G.Boss.Alive and G.Boss.Model and G.Boss.Model.Parent then
		if (G.Boss.Party and G.Boss.Party[p]) or (r and distance(r.Position,G.Boss.Body.Position)<=95) then
			return G.Boss
		end
	end
	if not r then return nil end
	local best,bestDist=nil,95
	for _,e in ipairs(G.Enemies) do
		if e.Alive and e.Model and e.Model.Parent and (e.Config and e.Config.Boss or e.Id=="AureonSentinel" or e.Id=="CryonPrime" or e.Id=="Noxar" or e.Id=="PirateCaptainVance" or e.Id=="OrderCyborgBoss" or e.Id=="SoulReaperRift" or e.Id=="SkySeaBeast" or e.Id=="AbyssalLeviathan") then
			local d=distance(r.Position,e.Body.Position)
			if d<=bestDist then
				bestDist=d
				best=e
			end
		end
	end
	return best
end
function G.Sync(p)
	local profile=D.Get(p) local rt=G.Runtime[p] if not profile or not rt then return end
	ensureProfileFields(profile)
	local eq=type(profile.Equipped)=='table' and profile.Equipped or {}
	local heldFruitId=(profile.HeldFruit~="" and profile.HeldFruit) or (profile.ActiveSlot==2 and profile.EquippedFruit or '')
	local slot=math.clamp(tonumber(profile.ActiveSlot) or 1,1,4)
	local wEnh=math.clamp(tonumber(profile.WeaponEnhance) or 0,0,15)
	p:SetAttribute('ClassId',profile.ClassId)
	p:SetAttribute('WeaponEquipped',profile.Weapon~=nil)
	p:SetAttribute('ActiveSlot',slot)
	p:SetAttribute('WeaponEnhance',wEnh)
	p:SetAttribute('EquippedSword',profile.Weapon or '')
	p:SetAttribute('EquippedGun',profile.EquippedGun or '')
	p:SetAttribute('HeldFruit',profile.HeldFruit or '')
	p:SetAttribute('EquippedChest',tostring(eq.Chest or eq.Armor or ''))
	p:SetAttribute('EquippedHelmet',tostring(eq.Helmet or eq.Helm or ''))
	p:SetAttribute('EquippedHelm',tostring(eq.Helm or eq.Helmet or ''))
	p:SetAttribute('EquippedGauntlets',tostring(eq.Gauntlets or eq.Gloves or ''))
	p:SetAttribute('EquippedGloves',tostring(eq.Gloves or eq.Gauntlets or ''))
	p:SetAttribute('EquippedGreaves',tostring(eq.Greaves or eq.Boots or ''))
	p:SetAttribute('EquippedBoots',tostring(eq.Boots or eq.Greaves or ''))
	p:SetAttribute('EquippedRing',tostring(eq.Ring or ''))
	p:SetAttribute('EquippedNecklace',tostring(eq.Necklace or eq.Offhand or ''))
	p:SetAttribute('EquippedOffhand',tostring(eq.Offhand or eq.Necklace or ''))
	p:SetAttribute('EquippedArtifact',tostring(eq.Artifact or eq.Offhand or ''))
	p:SetAttribute('EquippedAccessory',tostring(eq.Accessory or profile.EquippedAccessory or ''))
	p:SetAttribute('EquippedArmor',tostring(eq.Armor or profile.EquippedArmor or ''))
	p:SetAttribute('SkybornGender',profile.Gender or 'Male')
	p:SetAttribute('OutfitStage',profile.Level>=8 and 'SkyGuardian' or(profile.Level>=4 and 'Adventurer' or 'Novice'))
	local ch=p.Character
	if ch then
		ch:SetAttribute('ActiveSlot',slot)
		ch:SetAttribute('WeaponEnhance',wEnh)
		ch:SetAttribute('EquippedSword',profile.Weapon or '')
		ch:SetAttribute('EquippedGun',profile.EquippedGun or '')
		ch:SetAttribute('HeldFruit',heldFruitId)
		ch:SetAttribute('EquippedChest',tostring(eq.Chest or eq.Armor or ''))
		ch:SetAttribute('EquippedHelmet',tostring(eq.Helmet or eq.Helm or ''))
		ch:SetAttribute('EquippedHelm',tostring(eq.Helm or eq.Helmet or ''))
		ch:SetAttribute('EquippedGauntlets',tostring(eq.Gauntlets or eq.Gloves or ''))
		ch:SetAttribute('EquippedGloves',tostring(eq.Gloves or eq.Gauntlets or ''))
		ch:SetAttribute('EquippedGreaves',tostring(eq.Greaves or eq.Boots or ''))
		ch:SetAttribute('EquippedBoots',tostring(eq.Boots or eq.Greaves or ''))
		ch:SetAttribute('EquippedRing',tostring(eq.Ring or ''))
		ch:SetAttribute('EquippedNecklace',tostring(eq.Necklace or eq.Offhand or ''))
		ch:SetAttribute('EquippedOffhand',tostring(eq.Offhand or eq.Necklace or ''))
		ch:SetAttribute('EquippedArtifact',tostring(eq.Artifact or eq.Offhand or ''))
		ch:SetAttribute('EquippedAccessory',tostring(eq.Accessory or profile.EquippedAccessory or ''))
		ch:SetAttribute('EquippedArmor',tostring(eq.Armor or profile.EquippedArmor or ''))
	end
	local _,h=root(p) local s=G.Stats(p) local q=C.Quests[profile.QuestIndex]
	local maxE=math.max(100,tonumber(s and s.MaxEnergy) or tonumber(rt.MaxEnergy) or 100)
	rt.MaxEnergy=maxE
	rt.Energy=math.clamp(tonumber(rt.Energy) or maxE,0,maxE)
	p:SetAttribute('MaxEnergy',maxE)
	p:SetAttribute('RaceTier',profile.RaceTier or 1)
	p:SetAttribute('MaxCoreStorage',Helpers.GetMaxCoreStorage(p,profile))
	if profile.OwnedGamePasses and profile.OwnedGamePasses.sovereign_name_aura==true then
		p:SetAttribute('SovereignNameAura',true)
	end
	if profile.OwnedGamePasses and profile.OwnedGamePasses.golden_sky_ship==true then
		p:SetAttribute('GoldenShipSkin',true)
	end
	local socMod=G.SocialEconomy
	if not socMod and script.Parent:FindFirstChild("SkybreakSocialEconomyService") then
		local okS,m=pcall(require,script.Parent.SkybreakSocialEconomyService)
		if okS and type(m)=="table" then socMod=m G.SocialEconomy=m end
	end
	local socSnap=(socMod and type(socMod.GetSnapshotForPlayer)=="function") and socMod.GetSnapshotForPlayer(p) or nil
	local objectives={}
	if q then for i,o in ipairs(q.Objectives) do table.insert(objectives,{Label=o.Label,Count=profile.Progress[tostring(i)] or 0,Goal=o.Count}) end end
	local cooldowns={} for k,t in pairs(rt.Cooldowns) do cooldowns[k]=math.max(0,t-os.clock()) end
	local boss=findActiveBossForPlayer(p)
	local b=boss and boss.Alive and {
		Name=boss.Config.Name,
		Id=boss.Id,
		HP=boss.HP,
		MaxHP=boss.MaxHP,
		Break=boss.Break,
		Phase=boss.Phase,
		Shield=boss.Shield,
		Stunned=os.clock()<boss.StunnedUntil,
		Warning=boss.Id=='Noxar' and (boss.Shield and 'VOID SINGULARITY — Phá hủy Hố Đen Hư Không!' or (boss.Phase>=2 and 'VOID ANNIHILATION — Noxar đang tụ hội hư không!' or nil))
			or (boss.Id=='CryonPrime' and (boss.Shield and 'GLACIAL AEGIS — Phá hủy 3 Cột Băng Vĩnh Cửu!' or (boss.Phase>=2 and 'ABSOLUTE ZERO — Bão băng cực đại!' or nil))
			or (boss.Shield and 'SOLAR AEGIS — Phá hai trụ năng lượng trước!' or nil))
	} or nil
	local activeIds=getCompanionIds(profile.PartySize or "Solo", profile.Level)
	local activeSet={}
	for _,cid in ipairs(activeIds) do activeSet[cid]=true end
	local companionsState={}
	local curLv=tonumber(profile.Level) or 1
	for _,spec in ipairs(COMPANION_LIST) do
		table.insert(companionsState,{
			Id=spec.Id,
			Name=spec.Name,
			Role=spec.Role,
			ClassId=spec.ClassId,
			UnlockLevel=spec.UnlockLevel or 1,
			Unlocked=curLv>=(spec.UnlockLevel or 1),
			HP=spec.HP,
			MaxHP=spec.MaxHP,
			ATK=math.floor(spec.ATK*(1+curLv*0.04)),
			Active=activeSet[spec.Id]==true,
		})
	end
	local statePayload={
		Level=profile.Level,
		ClassId=profile.ClassId,
		ClassChosen=profile.ClassChosen==true,
		Gender=profile.Gender or 'Male',
		OutfitStage=p:GetAttribute('OutfitStage') or (profile.Level>=8 and 'SkyGuardian' or(profile.Level>=4 and 'Adventurer' or 'Novice')),
		XP=profile.XP,
		RequiredXP=C.RequiredXP(profile.Level),
		Gold=profile.Gold,
		CoreShards=profile.CoreShards or 0,
		SkillPoints=profile.SkillPoints or 0,
		SkillLevels=profile.SkillLevels or {},
		StatPoints=profile.StatPoints or 0,
		StatAlloc=profile.StatAlloc,
		ActiveSlot=profile.ActiveSlot or 2,
		FightingStyle=profile.FightingStyle,
		UnlockedStyles=profile.UnlockedStyles,
		EquippedFruit=profile.EquippedFruit,
		HeldFruit=profile.HeldFruit or '',
		StoredFruits=profile.StoredFruits,
		OwnedGamePasses=profile.OwnedGamePasses or {},
		MaxCoreStorage=Helpers.GetMaxCoreStorage(p,profile),
		AwakenedFruits=profile.AwakenedFruits,
		EquippedGun=profile.EquippedGun,
		Mastery=profile.Mastery,
		Haki=profile.Haki,
		Race=profile.Race,
		RaceTier=profile.RaceTier or 1,
		RaceV4Unlocked=profile.RaceV4Unlocked==true,
		RaceV4Active=profile.RaceV4Active==true,
		AwakeningMeter=tonumber(rt.AwakeningMeter or profile.AwakeningMeter) or 0,
		FuryMeter=tonumber(rt.FuryMeter) or 100,
		RaidChipsCleared=profile.RaidChipsCleared or 0,
		MicrochipRaidsCleared=profile.MicrochipRaidsCleared or {},
		DiscoveredIslands=profile.DiscoveredIslands or {},
		SocialEconomy=socSnap,
		Faction=profile.Faction or "Pirate",
		Bounty=profile.Bounty or 0,
		Honor=profile.Honor or 0,
		Title=profile.Title or "sky_rookie",
		WeaponEnhance=profile.WeaponEnhance or 0,
		EnhancePity=profile.EnhancePity or 0,
		Upgrades=profile.Upgrades or {},
		Equipped=profile.Equipped or {},
		DailyClaimed=profile.DailyClaimed or 0,
		PartySize=profile.PartySize or "Solo",
		Companions=companionsState,
		Potions=profile.Potions or 0,
		HP=h and h.Health or 0,
		MaxHP=s.HP,
		ATK=s.ATK,
		MeleeATK=s.MeleeATK or s.ATK,
		FruitATK=s.FruitATK or s.ATK,
		SwordATK=s.SwordATK or s.ATK,
		GunATK=s.GunATK or s.ATK,
		BestATK=s.BestATK or s.ATK,
		DEF=s.DEF,
		CritRate=s.CritRate,
		CritDmg=s.CritDmg,
		Break=s.Break,
		Stamina=rt.Stamina,
		Energy=rt.Energy,
		MaxEnergy=maxE,
		Cooldowns=cooldowns,
		Inventory=profile.Inventory,
		Weapon=profile.Weapon,
		SaveStatus=D.Sessions[p] and D.Sessions[p].SaveStatus or "Studio",
		CurrentRealm=p:GetAttribute("CurrentRealm") or "GoldenSky",
		UnlockedWorlds=profile.UnlockedWorlds,
		CompletedQuests=profile.CompletedQuests or {},
		LastCompletedQuest=profile.LastCompletedQuest,
		Quest=q and {Name=q.Name,Id=q.Id,Text=q.Text,Realm=q.Realm or "GoldenSky",XP=q.XP,Gold=q.Gold,CoreShards=q.CoreShards or 100,Accepted=profile.Accepted,Level=q.Level,Objectives=objectives} or nil,
		Complete=profile.QuestIndex>#C.Quests,
		Boss=b,
		Shield=math.max(0,rt.ShieldUntil-os.clock()),
		FruitPity=tonumber(profile.FruitPity) or 0,
		FreeFruitVouchers=tonumber(profile.FreeFruitVouchers) or 0,
		StatRefundTokens=tonumber(profile.StatRefundTokens) or 0,
		DoubleExpRemainingSec=tonumber(profile.DoubleExpRemainingSec) or 0,
		PaidRandomRestricted=(p:GetAttribute("PaidRandomRestricted")==true),
		PlaytimeGifts=LiveOps.GetPlaytimeState(p),
		FriendBoostPct=LiveOps.GetFriendBoostPct(p),
		UnlockedBadges=profile.UnlockedBadges or {},
		GlobalLeaderboards=LiveOps.GetGlobalLeaderboards(D,G.SocialEconomy),
		PvPCombatUntil=tonumber(p:GetAttribute("PvPCombatUntil")) or 0,
	}
	if G.OnBeforeSync then G.OnBeforeSync(p,profile,rt,s,statePayload) end
	R.StateUpdate:FireClient(p,{State=statePayload})
end
function G.Reward(p,xp,gold,shards)
	local profile=D.Get(p) if not profile then return end
	ensureProfileFields(profile)
	if p and p:GetAttribute("RaidActive")==true and workspace:GetAttribute("RaidActive")==false then
		profile.RaidChipsCleared=(tonumber(profile.RaidChipsCleared) or 0)+1
		local eqF=Helpers.ResolveFruitId(profile.EquippedFruit)
		if eqF~="" then
			profile.MicrochipRaidsCleared=type(profile.MicrochipRaidsCleared)=="table" and profile.MicrochipRaidsCleared or {}
			profile.MicrochipRaidsCleared[eqF]=true
		end
	end
	xp=math.max(0,tonumber(xp) or 0)
	gold=math.max(0,tonumber(gold) or 0)
	local ownsExpPass=(profile.OwnedGamePasses and profile.OwnedGamePasses.x2_exp==true) or (p and p:GetAttribute("OwnedPass_x2_exp")==true)
	local ownsGoldPass=(profile.OwnedGamePasses and profile.OwnedGamePasses.x2_gold==true) or (p and p:GetAttribute("OwnedPass_x2_gold")==true)
	local has2x=(tonumber(profile.DoubleExpRemainingSec) or 0)>0
	local fbMult=LiveOps.GetFriendBoostMultiplier(p)
	if ownsExpPass then xp=xp*2 end
	if has2x then xp=xp*2 end
	if fbMult>1 then xp=math.floor(xp*fbMult+0.5) end
	if ownsGoldPass then gold=gold*2 end
	profile.XP+=xp profile.Gold+=gold
	if shards and shards>0 then profile.CoreShards=(profile.CoreShards or 0)+shards end
	local previous=profile.Level
	while profile.Level<C.MaxLevel and profile.XP>=C.RequiredXP(profile.Level) do
		profile.XP-=C.RequiredXP(profile.Level) profile.Level+=1
	end
	if profile.Level==C.MaxLevel then profile.XP=0 end
	if previous~=profile.Level then
		local gained=profile.Level-previous
		local ptsPerLv=C.StatPointsPerLevel or 3
		profile.SkillPoints=(profile.SkillPoints or 0)+gained
		profile.StatPoints=(profile.StatPoints or 0)+gained*ptsPerLv
		profile.CoreShards=(profile.CoreShards or 0)+gained*2
		profile.Potions=math.max(profile.Potions or 0,4)
		ensureProfileFields(profile)
		Helpers.CheckAndAutoUnlockConqueror(p,profile,G,nil)
		LiveOps.EvaluateProgressionBadges(G,p,profile)
		LiveOps.RecordLeaderboardScore(p,"Level",profile.Level,false)
		local _,h=root(p)
		local st=G.Stats(p)
		if h and st then h.MaxHealth=st.HP h.Health=h.MaxHealth end
		local rt=G.Runtime[p]
		if rt and st then rt.MaxEnergy=st.MaxEnergy or 100 rt.Energy=rt.MaxEnergy end
		LiveOps.Notify(G,p,"ĐỘT PHÁ CẤP ĐỘ: Lv. "..profile.Level.." / "..C.MaxLevel.."! (+"..gained.." Levels, +"..(gained*ptsPerLv).." Stat Points)","LEVEL BREAKTHROUGH: Lv. "..profile.Level.." / "..C.MaxLevel.."! (+"..gained.." Levels, +"..(gained*ptsPerLv).." Stat Points)")
	end
end
local QUEST_TARGET_ALIASES={
	SkyPirate={SkyPirate=true,PirateCaptainVance=true,SkyHubWatchCommander=true},
	CorruptedGuard={CorruptedGuard=true,SunshardRoyalGuard=true,SunshardTemplar=true,SkyHubWatchCommander=true,ShrineGuardianBoss=true,AetherArchonBoss=true},
	LightArcher={LightArcher=true,SunshardRoyalGuard=true,SunshardTemplar=true},
	GoldenKnight={GoldenKnight=true,SunshardTemplar=true,SolarHighPriestBoss=true,PirateCaptainVance=true,Ignivar=true},
	FrostDrone={FrostDrone=true,FrostAutomaton=true,MechaDrone=true,CyberMercenary=true},
	CryoGuard={CryoGuard=true,CryoVanguard=true,FrostAutomaton=true,ArcticCorsair=true,Aion=true,Chronovex=true},
	CyberArcher={CyberArcher=true,GlacialMarksman=true,GlacialSniper=true,CyberMercenary=true},
	OrderCyborg={OrderCyborg=true,OrderCyborgBoss=true,SkySeaBeast=true,CyberSyndicateBoss=true,PermafrostWardenBoss=true,Aion=true,Chronovex=true},
	VoidPirate={VoidPirate=true,VoidMarauder=true,VoidRaider=true,ShadowSpecter=true,Sylvaris=true},
	AbyssalKnight={AbyssalKnight=true,AbyssalDreadknight=true,VoidCastellanBoss=true,UmbralArchfiendBoss=true},
	ShadowArcher={ShadowArcher=true,UmbralBowman=true,UmbralRanger=true,ShadowSpecter=true,Sylvaris=true},
	AbyssalLeviathan={AbyssalLeviathan=true,SoulReaperRift=true,TerrorSkyShark=true,AbyssalDragonHybrid=true,AbyssalSovereignDragon=true,Nerith=true},
	ShadowSpecter={ShadowSpecter=true,Sylvaris=true},
	SunshardTemplar={SunshardTemplar=true,Ignivar=true},
	TerrorSkyShark={TerrorSkyShark=true,Nerith=true},
	CryoVanguard={CryoVanguard=true,Aion=true,Chronovex=true},
}
local function matchesQuestTarget(objTarget,actualTarget)
	if objTarget==actualTarget then return true end
	local aliases=QUEST_TARGET_ALIASES[objTarget]
	return aliases~=nil and aliases[actualTarget]==true
end
function G.QuestEvent(p,kind,target)
	local profile=D.Get(p) if not profile then return end
	ensureProfileFields(profile)
	if not profile.Accepted and profile.QuestIndex<=#C.Quests then profile.Accepted=true end
	local q=C.Quests[profile.QuestIndex] if not q then return end
	for i,o in ipairs(q.Objectives) do
		if o.Kind==kind and matchesQuestTarget(o.Target,target) then
			local key=tostring(i)
			profile.Progress[key]=math.min(o.Count,(profile.Progress[key] or 0)+1)
		end
	end
	profile.QuestProgress=profile.Progress
	for i,o in ipairs(q.Objectives) do if (profile.Progress[tostring(i)] or 0)<o.Count then return end end
	local function hasTarget(tid)
		for _,o in ipairs(q.Objectives or {}) do if o.Target==tid then return true end end
		return false
	end
	if not profile.CompletedQuests[q.Id] then
		profile.CompletedQuests[q.Id]=true
		profile.Inventory.SkyIron=(profile.Inventory.SkyIron or 0)+4
		profile.Inventory.SunshardCore=(profile.Inventory.SunshardCore or 0)+2
		profile.Equipped=profile.Equipped or {}
		if q.Id=="Q01" and not profile.StarterCoreVoucherGranted then
			profile.StarterCoreVoucherGranted=true
			profile.FreeFruitVouchers=(tonumber(profile.FreeFruitVouchers) or 0)+1
			LiveOps.AwardBadge(G,p,profile,"welcome_skyborn")
			LiveOps.Notify(G,p,"Chào mừng Chiến Binh Bầu Trời! +1 Vé Quay Lõi Aether Miễn Phí tại Hiền Giả Zioles!","Welcome Skyborn! +1 Free Aether Core Spin Voucher at Oracle Zioles!")
		elseif q.Id=="Q02" then
			profile.Inventory.skyward_boots=math.max(1,profile.Inventory.skyward_boots or 0)
			if not profile.Equipped.Boots then profile.Equipped.Boots="skyward_boots" end
		elseif q.Id=="Q03" then
			profile.Inventory.upgrade_material=(profile.Inventory.upgrade_material or 0)+3
			profile.Inventory.CelestialFeather=(profile.Inventory.CelestialFeather or 0)+2
			profile.Inventory.skyward_helm=math.max(1,profile.Inventory.skyward_helm or 0)
			if not profile.Equipped.Helmet then profile.Equipped.Helmet="skyward_helm" end
		elseif q.Id=="Q04" then
			profile.Inventory.BossKey=1
			profile.Inventory.skyward_gloves=math.max(1,profile.Inventory.skyward_gloves or 0)
			if not profile.Equipped.Gloves then profile.Equipped.Gloves="skyward_gloves" end
		elseif q.Id=="Q06" then
			profile.Inventory.skyward_chest=math.max(1,profile.Inventory.skyward_chest or 0)
			if not profile.Equipped.Chest then profile.Equipped.Chest="skyward_chest" end
		elseif q.Id=="Q07" then
			profile.Inventory.aether_ring=math.max(1,profile.Inventory.aether_ring or 0)
			if not profile.Equipped.Ring then profile.Equipped.Ring="aether_ring" end
		elseif q.Id=="Q09" then
			profile.Inventory.celestial_necklace=math.max(1,profile.Inventory.celestial_necklace or 0)
			if not profile.Equipped.Necklace then profile.Equipped.Necklace="celestial_necklace" end
		end
		if hasTarget("AureonSentinel") or q.Id=="Q10" then
			profile.FirstClearBosses.AureonSentinel=true
			profile.Inventory.CoreOfLight=1
			profile.Inventory.DawnbringerBlueprint=1
			profile.Inventory.saber_of_aureon=math.max(1,profile.Inventory.saber_of_aureon or 0)
			profile.Inventory.CoreEssence=(profile.Inventory.CoreEssence or 0)+2
			profile.Inventory.upgrade_material=(profile.Inventory.upgrade_material or 0)+5
			profile.UnlockedWorlds.FrozenCyber=true
			Helpers.CheckAndAutoUnlockConqueror(p,profile,G,"AureonSentinel")
		elseif hasTarget("CryonPrime") or q.Id=="Q17" then
			profile.FirstClearBosses.CryonPrime=true
			profile.Inventory.cryon_frostblade=math.max(1,profile.Inventory.cryon_frostblade or 0)
			profile.Inventory.CoreEssence=(profile.Inventory.CoreEssence or 0)+2
			profile.UnlockedWorlds.ShadowRealm=true
			Helpers.CheckAndAutoUnlockConqueror(p,profile,G,"CryonPrime")
		elseif hasTarget("Noxar") or q.Id=="Q24" then
			profile.FirstClearBosses.Noxar=true
			profile.Inventory.cursed_dual_skyblades=math.max(1,profile.Inventory.cursed_dual_skyblades or 0)
			profile.Inventory.CoreEssence=(profile.Inventory.CoreEssence or 0)+3
			profile.UnlockedWorlds.VerdantCrown=true
			profile.UnlockedWorlds.EmberforgeWastes=true
			Helpers.CheckAndAutoUnlockConqueror(p,profile,G,"Noxar")
		elseif hasTarget("Ignivar") or q.Id=="Q26" then
			profile.UnlockedWorlds.AbyssalTides=true
			profile.UnlockedWorlds.ChronosBastion=true
		elseif hasTarget("Aion") or hasTarget("Chronovex") or q.Id=="Q28" then
			profile.UnlockedWorlds.VeilsEnd=true
		elseif hasTarget("Veyr") or hasTarget("VeyrTheArchitect") or q.Id=="Q30" then
			profile.FirstClearBosses.Veyr=true
			profile.Inventory.noxar_abyssal_greatsword=math.max(1,profile.Inventory.noxar_abyssal_greatsword or 0)
			profile.Inventory.sovereign_cloak=math.max(1,profile.Inventory.sovereign_cloak or 0)
		end
	end
	profile.LastCompletedQuest=q.Id
	G.Reward(p,q.XP,q.Gold,q.CoreShards or 15)
	LiveOps.EvaluateProgressionBadges(G,p,profile)
	local nextQuest=C.Quests[profile.QuestIndex+1]
	if nextQuest then
		local reqLv=tonumber(nextQuest.Level or nextQuest.LevelReq) or 1
		if (tonumber(profile.Level) or 1)>=reqLv then
			profile.QuestIndex+=1
			profile.Progress={}
			profile.QuestProgress=profile.Progress
			profile.Accepted=true
			Helpers.SyncDiscoveredIslands(profile,C)
			G.Notify(p,"Hoàn thành "..q.Id.." ("..q.Name..")! +"..q.Gold.." Gold • Tiếp theo: "..nextQuest.Id.." "..nextQuest.Name)
		else
			profile.Progress={}
			profile.QuestProgress=profile.Progress
			profile.Accepted=true
			G.Notify(p,"Hoàn thành nhiệm vụ! Đạt Lv. "..tostring(reqLv).." để mở nhiệm vụ tiếp theo (Đã tự động nhận lại nhiệm vụ hiện tại).")
		end
	else
		profile.QuestIndex=#C.Quests+1
		profile.Progress={}
		profile.QuestProgress=profile.Progress
		profile.Accepted=false
		G.Notify(p,"Hoàn thành "..q.Id.." ("..q.Name..")! Bạn đã hoàn tất toàn bộ chiến dịch!")
	end
	task.spawn(D.Save,p,false)
end
local function eligible(p)
	local profile=D.Get(p)
	if not profile then return false end
	if DevGate.IsAllowed(p) then return true end
	local lv=tonumber(profile.Level) or 1
	local hasKey=(tonumber(profile.Inventory and profile.Inventory.BossKey) or 0)>0
	local qReady=(tonumber(profile.QuestIndex) or 1)>=5 or (profile.CompletedQuests and profile.CompletedQuests.Q04==true)
	if lv>=560 or (lv>=420 and (hasKey or qReady)) then
		if profile.QuestIndex==5 then profile.Accepted=true end
		return true
	end
	return false
end
function G.Rate(p,channel,interval)
	local rt=G.Runtime[p] if not rt or not D.Get(p) then return false end
	local now=os.clock() local last=rt.Requests[channel] or 0
	if now-last<interval then return false end rt.Requests[channel]=now return true
end

function G.ActivateShrine(p,shrine)
	local r,h=root(p)
	local rt=G.Runtime[p]
	local profile=D.Get(p)
	if not r or not h or not rt or not profile then return end
	p:SetAttribute("RespawnPos",shrine.Pos)
	p:SetAttribute("RespawnRealm",shrine.Realm)
	h.Health=h.MaxHealth
	rt.Stamina=100
	rt.Energy=rt.MaxEnergy or 100
	profile.Potions=math.max(profile.Potions or 0,4)
	G.FireCombatEvent({
		kind="DamageNumber",
		pos=r.Position+_V3(0,2.5,0),
		amount=math.floor(h.MaxHealth),
		crit=true,
		breakDmg=0,
		element="Heal",
		Text="100% HP & AETHER",
	})
	G.Notify(p,"Điện Thờ Aether ("..shrine.Realm.."): Đã lưu điểm hồi sinh & hồi phục 100% HP/Stamina!")
	G.Sync(p)
end


function G.UpdatePlayerPortalCompass(p,order)
	if not p or not G.WorldPortals then return end
	local wOrder=math.clamp(tonumber(order) or 1,1,20)
	local gateKey=string.format("WorldGate_%02d",wOrder)
	local nextGate=G.WorldPortals[gateKey] or G.WorldPortals.WorldGate_01
	p:SetAttribute("CurrentWorldOrder",wOrder)
	if nextGate then
		p:SetAttribute("NextWorldGateId",nextGate.Id)
		p:SetAttribute("NextWorldGatePos",nextGate.CenterPos)
		p:SetAttribute("NextWorldGateLabel",nextGate.StageLabel.." -> "..nextGate.TargetTitle)
	end
end

function G.EnterWorldPortal(p,gate)
	local r,h=root(p)
	local rt=G.Runtime[p]
	local profile=D.Get(p)
	if not r or not h or not rt or not profile or not gate then return end
	local now=os.clock()
	if now<(rt.PortalTouchCooldown or 0) then return end
	if inLockedEncounter(p) then
		rt.PortalTouchCooldown=now+1.5
		G.Notify(p,"Không thể dùng Cổng Không Gian khi đang trong giao tranh, Raid, Tháp hoặc Giao Dịch!")
		return
	end
	ensureProfileFields(profile)
	profile.UnlockedWorlds=profile.UnlockedWorlds or {}
	if gate.Id=="WorldGate_SkyHub_Plaza" and (tonumber(profile.Level) or 1)<75 then
		rt.PortalTouchCooldown=now+2.0
		G.Notify(p,"Cổng Dịch Chuyển Sky Hub yêu cầu đạt Lv. 75+!")
		return
	end
	local targetRealm=gate.TargetRealm or "GoldenSky"
	local minLv=REALM_MIN_LV[targetRealm] or 1
	if targetRealm~="GoldenSky" and not profile.UnlockedWorlds[targetRealm] and (tonumber(profile.Level) or 1)<minLv then
		rt.PortalTouchCooldown=now+2.0
		G.Notify(p,"Cổng Không Gian ["..tostring(gate.StageLabel or targetRealm).."] yêu cầu đạt Level "..minLv.."!")
		return
	end
	rt.PortalTouchCooldown=now+3.2
	if gate.TargetRealm then profile.UnlockedWorlds[gate.TargetRealm]=true profile.DiscoveredIslands[gate.TargetRealm]=true end
	if gate.TargetWorldKey then profile.UnlockedWorlds[gate.TargetWorldKey]=true profile.DiscoveredIslands[gate.TargetWorldKey]=true end
	profile.DiscoveredPortals=type(profile.DiscoveredPortals)=="table" and profile.DiscoveredPortals or {}
	local firstTime=not profile.DiscoveredPortals[gate.Id]
	if firstTime then
		profile.DiscoveredPortals[gate.Id]=true
		profile.Gold=(profile.Gold or 0)+300
		profile.CoreShards=(profile.CoreShards or 0)+75
	end
	profile.CurrentWorldOrder=gate.NextOrder or 1
	p:SetAttribute("CurrentRealm",gate.TargetRealm or "GoldenSky")
	p:SetAttribute("RespawnPos",gate.TargetPos)
	p:SetAttribute("RespawnRealm",gate.TargetRealm or "GoldenSky")
	G.UpdatePlayerPortalCompass(p,profile.CurrentWorldOrder)
	G.FireCombatEvent({
		kind="SkillVFX",
		skillId="WorldGateTeleport",
		element=gate.Element or "Sky",
		pos=r.Position,
		look=r.CFrame.LookVector,
		userId=p.UserId,
	})
	R.CombatFX:FireAllClients({Kind="Skill",Position=r.Position,Actor=p.UserId,Action="PortalSurge"})
	G.Teleport(p,gate.TargetPos,true)
	G.FireCombatEvent({
		kind="SkillVFX",
		skillId="WorldGateTeleport",
		element=gate.Element or "Sky",
		pos=gate.TargetPos,
		look=r.CFrame.LookVector,
		userId=p.UserId,
	})
	local bonusTxt=firstTime and " (+300 Gold, +75 Core Shards mở khóa cổng mới!)" or ""
	G.Notify(p,"CỔNG KHÔNG GIAN ["..gate.StageLabel.."]: Dịch chuyển tới "..gate.TargetTitle.."!"..bonusTxt)
	G.Sync(p)
end

function G.OpenChest() end

function G.LaunchPlayer(p,startPos,targetPos,arcHeight,duration)
	local r,h=root(p)
	local rt=G.Runtime[p]
	if not r or not h or not rt then return end
	duration=duration or 1.1
	arcHeight=arcHeight or 20
	rt.JumpPadUntil=os.clock()+duration+0.5
	rt.InvincibleUntil=math.max(rt.InvincibleUntil or 0,os.clock()+duration+0.4)
	local character=p.Character
	local goal=targetPos+_V3(0,3,0)
	local dir=_V3(goal.X-startPos.X,0,goal.Z-startPos.Z)
	local look=dir.Magnitude>0.1 and dir.Unit or r.CFrame.LookVector
	R.CombatFX:FireAllClients({Kind="Dodge",Position=startPos,Actor=p.UserId,Action="Dash"})
	task.spawn(function()
		local t0=os.clock()
		while p.Character==character and r.Parent and h.Health>0 do
			RunService.Heartbeat:Wait()
			local alpha=math.clamp((os.clock()-t0)/duration,0,1)
			local flat=startPos:Lerp(goal,alpha)
			local lift=4*arcHeight*alpha*(1-alpha)
			local pos=_V3(flat.X,flat.Y+lift,flat.Z)
			r.CFrame=CFrame.lookAt(pos,pos+look)
			r.AssemblyLinearVelocity=Vector3.zero
			rt.Safe=pos
			rt.MoveAt=os.clock()
			if alpha>=1 then break end
		end
	end)
end

function G.Interact(p,id)
	if type(id)~="string" or #id>40 or not G.Rate(p,"Interact",.25) then return end
	local r=root(p) local profile=D.Get(p)
	if not r or not profile then return end
	if G.WorldPortals and G.WorldPortals[id] then
		if distance(r.Position,G.WorldPortals[id].CenterPos)<=18 then
			G.EnterWorldPortal(p,G.WorldPortals[id])
		end
		return
	end
	if G.Chests[id] then
		G.OpenChest(p,id)
		return
	elseif id=="Chest" then
		for cid,c in pairs(G.Chests) do
			if distance(r.Position,c.Part.Position)<=16 then
				G.OpenChest(p,cid)
				return
			end
		end
	end
	if G.Shrines[id] then
		if distance(r.Position,G.Shrines[id].Pos)<=16 then
			G.ActivateShrine(p,G.Shrines[id])
		end
		return
	elseif id=="AetherShrine" then
		for _,sh in pairs(G.Shrines) do
			if distance(r.Position,sh.Pos)<=16 then
				G.ActivateShrine(p,sh)
				return
			end
		end
	end
	local object=W.Interactions[id]
	if not object and (id=="Zioles" or id=="ZiolesGachaNPC" or id=="AncientMonk" or id=="AncientMonkNPC" or id=="Kael" or id=="Kael_WeaponMaster" or id=="DrVega" or id=="DrVega_Alchemist") then
		local prefix=(id=="Zioles" or id=="ZiolesGachaNPC") and "Zioles_"
			or ((id=="AncientMonk" or id=="AncientMonkNPC") and "AncientMonk_"
			or ((id=="Kael" or id=="Kael_WeaponMaster") and "Kael" or "DrVega"))
		local bestD=math.huge
		for k,part in pairs(W.Interactions) do
			if type(k)=="string" and k:sub(1,#prefix)==prefix and part and part.Parent then
				local d=distance(r.Position,part.Position)
				if d<bestD then bestD=d object=part end
			end
		end
	end
	if not object and id:sub(1,14)~="FruitPedestal_" then return end
	if object and distance(r.Position,object.Position)>22 then return end
	if id=='Lyra' or id=='Kael' or id=='Kael_WeaponMaster' or id=='DrVega' or id=='DrVega_Alchemist' then
		if object.Parent and object.Parent:IsA("Model") then object.Parent:SetAttribute('NPCTalkAt',workspace:GetServerTimeNow()) end
		object:SetAttribute('NPCTalkAt',workspace:GetServerTimeNow())
	end
	if id:sub(1,4)=="NPC_" then
		if Helpers.InteractRegionalNPC(p,id,profile,G,C) then
			G.Sync(p)
			return
		end
	end
	if id:sub(1,14)=="FruitPedestal_" then
		if p:GetAttribute("InTrade")==true then return end
		if not object and G.HandleFruitAction then
			G.HandleFruitAction(p,"ClaimWildFruit",id:sub(15))
			return
		end
		local rt=G.Runtime[p]
		local now=os.clock()
		if rt and now<(rt.Cooldowns.FruitPedestal or 0) then return end
		if not object then
			local nearTree=false
			for _,tp in ipairs({_V3(105,46.5,58),_V3(12095,46.9,65),_V3(-11892,46.9,165)}) do
				if _V3(r.Position.X-tp.X,0,r.Position.Z-tp.Z).Magnitude<=45 then nearTree=true break end
			end
			if not nearTree then return end
		end
		if rt then rt.Cooldowns.FruitPedestal=now+22 end
		local fid=id:sub(15)
		local fcfg=getFruitCfg(fid)
		if not ((C.AetherFruits and C.AetherFruits[fid]) or FALLBACK_FRUITS[fid]) then return end
		local fname=fcfg and fcfg.Name or fid
		local maxCap=Helpers.GetMaxCoreStorage(p,profile)
		if (tonumber(profile.StoredFruits[fid]) or 0)<maxCap then
			profile.StoredFruits[fid]=(tonumber(profile.StoredFruits[fid]) or 0)+1
			if rt then rt.HeldAlreadyStored=true end
		elseif rt then
			rt.HeldAlreadyStored=false
		end
		profile.EquippedFruit=fid
		profile.ActiveSlot=2
		profile.HeldFruit=fid
		if p.Character then p.Character:SetAttribute("HeldFruit",fid) end
		G.SendDialogue(p,"Bệ Đá Lõi Aether",fcfg and fcfg.Rarity or "Mythical","Bạn đã thu thập & trang bị 3D ["..fname.."]! Bấm [G] để mở bảng Lõi Aether hoặc dùng chiêu [Z][X][C][V][F]!","Mở Bảng Lõi Aether [G]","OpenScreen:Fruits")
		G.Sync(p)
		return
	elseif id=="Zioles" or id=="ZiolesGachaNPC" then
		Helpers.OpenZiolesDialogue(p,profile,G.Runtime[p],G,C)
		return
	elseif id=="AncientMonk" or id=="AncientMonkNPC" then
		Helpers.OpenAncientMonkDialogue(p,profile,G)
		return
	elseif id=="Lyra" then
		local q=C.Quests[profile.QuestIndex]
		if not q then
			G.SendDialogue(p,"Lyra • Chỉ Huy Skyborn","CHỈ HUY TỐI CAO","Ngươi đã chinh phục cả 8 cõi giới Skybreak! Danh hiệu Huyền Thoại Bầu Trời thuộc về ngươi.","Mở Bản Đồ Thế Giới [M]","OpenScreen:Map")
			return
		end
		profile.Accepted=true
		G.SendDialogue(p,"Lyra • Chỉ Huy Skyborn","NHIỆM VỤ ["..q.Id.."] "..q.Name,q.Text.." (Phần thưởng: +"..tostring(q.XP).." XP, +"..tostring(q.Gold).." Gold)","Xem Nhật Ký Nhiệm Vụ [L]","OpenScreen:Quests")
	elseif id=="Kael" or id=="Kael_WeaponMaster" then
		Helpers.OpenKaelDialogue(p,profile,G,C)
		return
	elseif id=="DrVega" or id=="DrVega_Alchemist" then
		Helpers.OpenDrVegaDialogue(p,profile,G)
		return
	elseif id=="FrozenPortal" then
		if G.WorldPortals and G.WorldPortals.WorldGate_Sea1_to_Sea2 then
			G.EnterWorldPortal(p,G.WorldPortals.WorldGate_Sea1_to_Sea2)
		elseif not inLockedEncounter(p) and (profile.UnlockedWorlds.FrozenCyber or (tonumber(profile.Level) or 1)>=700) then
			profile.UnlockedWorlds.FrozenCyber=true
			profile.DiscoveredIslands.FrozenCyber=true
			if not workspace:FindFirstChild('FrozenCyber') then G.Notify(p,'Frozen Cyber đang được chuẩn bị.')
			else
				p:SetAttribute('CurrentRealm','FrozenCyber')
				G.Teleport(p,require(game.ReplicatedStorage.Shared.RealmConfig).FrozenCyber.Spawn)
			end
		else
			G.Notify(p,"Cổng Tầng Trời 2 (Frozen Cyber) yêu cầu đạt Level 700!")
		end
	elseif id=='FrozenReturnHub' then if not inLockedEncounter(p) then p:SetAttribute('CurrentRealm','GoldenSky');G.Teleport(p,C.Spawn) end
	elseif id=='ShadowPortal'then
		if G.WorldPortals and G.WorldPortals.WorldGate_Sea2_to_Sea3 then
			G.EnterWorldPortal(p,G.WorldPortals.WorldGate_Sea2_to_Sea3)
		elseif not inLockedEncounter(p) and (profile.UnlockedWorlds.ShadowRealm or (tonumber(profile.Level) or 1)>=1500) then
			profile.UnlockedWorlds.ShadowRealm=true
			profile.DiscoveredIslands.ShadowRealm=true
			if not workspace:FindFirstChild('ShadowRealm')then return end
			p:SetAttribute('CurrentRealm','ShadowRealm')
			G.Teleport(p,require(game.ReplicatedStorage.Shared.RealmConfig).ShadowRealm.Spawn)
		else
			G.Notify(p,"Cổng Tầng Trời 3 (Shadow Realm) yêu cầu đạt Level 1500!")
		end
	elseif id=='ShadowReturnHub' or id=='VerdantReturnHub' or id=='EmberReturnHub' or id=='AbyssalReturnHub' or id=='ChronosReturnHub' or id=='VeilsReturnHub' then if not inLockedEncounter(p) then p:SetAttribute('CurrentRealm','GoldenSky');G.Teleport(p,C.Spawn) end
	elseif id=="ReturnHub" or id=="LeaveArena" then
		if id=="LeaveArena" and G.Boss and G.Boss.Party then G.Boss.Party[p]=nil end
		if not inLockedEncounter(p) then p:SetAttribute("CurrentRealm","GoldenSky");G.Teleport(p,C.Spawn) end
	elseif id=="ArenaGate" then
		if inLockedEncounter(p) then LiveOps.Notify(G,p,"Không thể tiến vào Đấu Trường khi đang giao tranh!","Cannot enter Arena while in combat!") return end
		if not eligible(p) then G.Notify(p,"Cần hoàn thành Q04 (Chìa Khóa Tháp Ánh Sáng) hoặc đạt Lv.560 để tiến vào Đấu Trường Aureon!") return end
		if G.Boss or os.clock()<G.ResetAt then G.Notify(p,"Đấu trường đang có trận / đang hồi. Vui lòng chờ.") return end
		G.Teleport(p,C.ArenaEntry,nil,true)
		if not G.Preparing then
			G.Preparing=true
			for _,other in ipairs(Players:GetPlayers()) do G.Notify(other,"Aureon bắt đầu sau 4 giây. Hãy tiến vào đấu trường!") end
			task.delay(4,function()
				G.Preparing=false local party={}
				for _,other in ipairs(Players:GetPlayers()) do
					local rr=root(other)
					if eligible(other) and rr and distance(rr.Position,C.Arena)<220 and #party<6 then table.insert(party,other) end
				end
				if #party>0 then G.StartBoss(party) end
			end)
		end
	else G.QuestEvent(p,"Interact",id) end
	G.Sync(p)
end
local SINGLETON_BOSSES={
	Noxar=true, CryonPrime=true, AureonSentinel=true, PirateCaptainVance=true, OrderCyborgBoss=true,
	SoulReaperRift=true, SkySeaBeast=true, AbyssalLeviathan=true, AbyssalSovereignDragon=true,
	SkyHubWatchCommander=true, ShrineGuardianBoss=true, AetherArchonBoss=true, SolarHighPriestBoss=true,
	CyberSyndicateBoss=true, PermafrostWardenBoss=true, VoidCastellanBoss=true, UmbralArchfiendBoss=true,
	Sylvaris=true, Ignivar=true, Nerith=true, Aion=true, Veyr=true,
}
function G.SpawnEnemy(id,pos,boss,noRespawn)
	local cfg=C.Enemies[id] or FALLBACK_ENEMIES[id] if not cfg then return end
	if SINGLETON_BOSSES[id] then
		for _,existing in ipairs(G.Enemies) do
			if existing.Id==id and existing.Alive and existing.Model and existing.Model.Parent then
				return existing
			end
		end
	end
	local folder=boss and workspace.ActiveBosses or workspace.ActiveEnemies
	local model=_IN("Model")
	model.Name=id
	model:SetAttribute("EnemyId",id)
	model:SetAttribute("VisualAsset",cfg.VisualAsset or id)
	model:SetAttribute("Element",cfg.Element or "Sky")
	local isSeaBeast=(id=="SkySeaBeast" or id=="AbyssalLeviathan")
	local size=id=="AureonSentinel" and _V3(7,12,5)
		or (isSeaBeast and _V3(9,16,9)
		or ((id=="EnergyPylon" or id=="CryonPillar") and _V3(4,9,4)
		or (id=="NoxarVoidFX" and _V3(6,6,6) or _V3(4,5,3))))
	local col=cfg.Element=="Frost" and _RGB(95,215,255)
		or (cfg.Element=="Void" and _RGB(168,85,247) or _RGB(199,153,61))
	local mat=(id=="EnergyPylon" or id=="CryonPillar" or id=="NoxarVoidFX") and Enum.Material.Neon or Enum.Material.Metal
	local body=W.Part(model,"Body",size,pos,col,mat)
	if id=="NoxarVoidFX" then body.Shape=Enum.PartType.Ball end
	body.CanCollide=true model.PrimaryPart=body
	local eye=W.Part(model,"Core",_V3(size.X*.6,1,1),pos+_V3(0,1,-size.Z/2),_RGB(112,229,255),Enum.Material.Neon) eye.CanCollide=false
	if isSeaBeast then
		local scaleCol=id=="AbyssalLeviathan" and _RGB(38,24,68) or _RGB(24,65,98)
		local finCol=id=="AbyssalLeviathan" and _RGB(195,95,255) or _RGB(85,235,255)
		body.Color=scaleCol
		body.Material=Enum.Material.Granite
		for seg=1,4 do
			local segPart=W.Part(model,"SpineSeg_"..seg,_V3(8-seg*1.1,12-seg*1.6,7-seg*0.8),pos+_V3(0,-seg*1.5,seg*5.5),scaleCol,Enum.Material.Granite)
			segPart.CanCollide=false
			local fin=W.Part(model,"DorsalFin_"..seg,_V3(1.2,6-seg*0.8,4.5),pos+_V3(0,6-seg*1.2,seg*5.2),finCol,Enum.Material.Neon)
			fin.CanCollide=false
		end
		local head=W.Part(model,"LeviathanHead",_V3(8.5,6.5,9.5),pos+_V3(0,8.5,-3.5),scaleCol,Enum.Material.Metal)
		head.CanCollide=false
		local jaw=W.Part(model,"LeviathanJaw",_V3(7.2,2.4,8.5),pos+_V3(0,5.2,-4.2),finCol,Enum.Material.Neon)
		jaw.CanCollide=false
		for _,side in ipairs({-1,1}) do
			local horn=W.Part(model,"CrownHorn_"..side,_V3(1.4,7.5,2.2),pos+_V3(side*4.2,12.5,-1.5),finCol,Enum.Material.Neon)
			horn.CanCollide=false
			horn.CFrame*=_CFA(-0.35,0,side*0.42)
		end
		W.Ring(model,"SeaVortexRing",pos+_V3(0,-5,0),14,finCol,20)
		local pl=_IN("PointLight")
		pl.Color=finCol
		pl.Brightness=1.42
		pl.Range=16
		pl.Parent=head
	elseif id=="AureonSentinel" or id=="GoldenKnight" or id=="AbyssalKnight" then
		body.Color=id=="AbyssalKnight" and _RGB(68,42,108) or _RGB(231,224,201)
		local factor=id=="AureonSentinel" and 1 or .5
		local function armor(name,s,offset,color,neon)
			local part=W.Part(model,name,s*factor,pos+offset*factor,color,neon and Enum.Material.Neon or Enum.Material.Metal) part.CanCollide=false return part
		end
		local g=id=="AbyssalKnight" and _RGB(175,90,255) or _RGB(234,184,66)
		local white=id=="AbyssalKnight" and _RGB(48,36,68) or _RGB(226,222,207)
		armor("Helmet",_V3(4,4,4),_V3(0,8,0),g)
		armor("Visor",_V3(.6,2.6,.3),_V3(0,8,-2.1),g,true)
		for _,side in ipairs({-1,1}) do
			armor("Pauldron",_V3(4,3,5),_V3(side*5,4,0),g)
			armor("Arm",_V3(2.6,6,2.6),_V3(side*5,0,0),white)
			armor("Leg",_V3(2.5,5,3),_V3(side*2,-7,0),white)
			if id=="AureonSentinel" then for n=1,3 do
				local wing=armor("HaloWing",_V3(8,1.5,1),_V3(side*(8+n),4+n*2,3),g)
				wing.CFrame*=_CFA(0,0,side*(.3+n*.12))
			end end
		end
		armor("EnergySword",_V3(1.3,13,.5),_V3(5,-6,-2),g,true)
		if id=="AureonSentinel" then W.Ring(model,"CrownHalo",pos+_V3(0,12,0),5,g,20) end
	end
	local visualId=cfg.VisualAsset or id
	if id=="AureonSentinel" then Cosmetics.Boss(model,body)
	else pcall(Cosmetics.Enemy,model,body,visualId) end
	local halfH = math.max(2.2, size.Y * 0.5)
	local alignedPos, homeFloorY
	if W.SnapToOpenGround and id~="EnergyPylon" and id~="CryonPillar" and id~="NoxarVoidFX" then
		alignedPos, homeFloorY = W.SnapToOpenGround(pos, pos.Y - 2.5, halfH)
	else
		homeFloorY = safeGroundY(pos, pos.Y - 2.5)
		alignedPos = _V3(pos.X, homeFloorY + halfH, pos.Z)
	end
	body.Position = alignedPos
	model:SetAttribute('EnemyFloorY', homeFloorY)
	if id=="Noxar" or id=="CryonPrime" or id=="AureonSentinel" or isSeaBeast then
		model:PivotTo(CFrame.lookAt(alignedPos,alignedPos+_V3(0,0,1)))
	end
	local lvTag=cfg.Level and (" [Lv."..tostring(cfg.Level).."]") or ""
	local bar=(W.EnemyBar and W.EnemyBar(body,cfg,boss)) or W.Label(body,cfg.Name..lvTag)
	model.Parent=folder
	local e={
		Id=id,
		Config=cfg,
		Model=model,
		Body=body,
		Root=body,
		Label=bar,
		Home=alignedPos,
		HomeFloorY=homeFloorY,
		HP=cfg.HP,
		MaxHP=cfg.HP,
		Alive=true,
		NextAttack=0,
		SpecialTimer=0,
		Contributors={},
		State="Idle",
		Respawn=(not boss) and (not noRespawn),
		NoRespawn=noRespawn==true,
		Break=0,
		StunnedUntil=0,
		ImmuneUntil=0,
		Phase=1,
		Shield=false,
	}
	table.insert(G.Enemies,e) return e
end
function G.StartBoss(party)
	local boss=G.SpawnEnemy("AureonSentinel",C.BossSpawn,true,true)
	local extra=#party-1
	local first=party[1] and D.Get(party[1])
	if first and first.PartySize=="Duo" then extra=math.max(extra,1)
	elseif first and (first.PartySize=="Trio" or first.PartySize=="Raid 4") then extra=math.max(extra,2)
	elseif first and (first.PartySize=="Squad" or first.PartySize=="Raid 6") then extra=math.max(extra,3) end
	boss.MaxHP=math.floor(boss.MaxHP*(1+.25*extra)) boss.HP=boss.MaxHP
	boss.Party={} for _,p in ipairs(party) do boss.Party[p]=true end
	boss.EmptySince=nil boss.State="Phase1" G.Boss=boss
	return boss
end
local function participant(e,p)
	if not e.Party then return true end
	return e.Party[p]==true
end
local function cleanupBossMinions(bossEnemy)
	if not bossEnemy then return end
	for _,other in ipairs(G.Enemies) do
		if other.BossOwner==bossEnemy and other.Alive then
			other.Alive=false
			if other.Model then other.Model:Destroy() end
		end
	end
end
local function cleanupEnemyTelegraphs(e)
	if not e then return end
	if type(e._ActiveTelegraphs)=="table" then
		for _,tz in ipairs(e._ActiveTelegraphs) do
			if tz and tz.Parent then tz:Destroy() end
		end
		table.clear(e._ActiveTelegraphs)
	end
	local tf=workspace:FindFirstChild("TempFX")
	if tf and e.Id then
		for _,ch in ipairs(tf:GetChildren()) do
			if ch.Name=="TelegraphZone" and ch:GetAttribute("OwnerEnemyId")==e.Id then
				ch:Destroy()
			end
		end
	end
end
function G.Kill(e)
	if not e.Alive then return end e.Alive=false e.State="Dead"
	cleanupEnemyTelegraphs(e)
	if W.UpdateEnemyBar then W.UpdateEnemyBar(e) end
	if BLENDER_ENEMIES[e.Id] then
		e.Model:SetAttribute('EnemyDead',true)
		e.Label.Visible=false
		for _,o in e.Model:GetDescendants()do if o:IsA('BasePart')then o.CanQuery=false;o.CanCollide=false;o.CanTouch=false end end
		Debris:AddItem(e.Model,2)
	else e.Model:Destroy()end
	local isBossOrElite=e.Config.Boss or e.Config.Elite or e.Id=="AureonSentinel" or e.Id=="CryonPrime" or e.Id=="Noxar" or e.Id=="GoldenKnight" or e.Id=="AbyssalKnight" or e.Id=="SkySeaBeast" or e.Id=="AbyssalLeviathan"
	for p,hit in pairs(e.Contributors) do
		local r=root(p)
		local prof=D.Get(p)
		if r and prof and os.clock()-hit.Time<45 and distance(r.Position,e.BodyPosition or e.Home)<95 and participant(e,p) then
			ensureProfileFields(prof)
			local shards=(e.Id=="CryonPrime" or e.Id=="Noxar" or e.Id=="AureonSentinel" or e.Id=="SkySeaBeast" or e.Id=="AbyssalLeviathan") and 120 or 12
			if e.Config.Drop then
				prof.Inventory[e.Config.Drop]=(prof.Inventory[e.Config.Drop] or 0)+1
			end
			if e.Id=="CryonPrime" or e.Id=="Noxar" or e.Id=="AureonSentinel" or e.Id=="SkySeaBeast" or e.Id=="AbyssalLeviathan" then
				prof.Inventory.SunshardCore=(prof.Inventory.SunshardCore or 0)+2
				prof.Inventory.CoreEssence=(prof.Inventory.CoreEssence or 0)+1
				prof.Inventory.SkyIron=(prof.Inventory.SkyIron or 0)+4
			else
				prof.Inventory.SkyIron=(prof.Inventory.SkyIron or 0)+1
			end
			if isBossOrElite then
				prof.Bounty=(prof.Bounty or 2500000)+15000
				prof.Honor=(prof.Honor or 2500000)+15000
				if e.Id=="AureonSentinel" or e.Id=="CryonPrime" or e.Id=="Noxar" then
					prof.FirstClearBosses=type(prof.FirstClearBosses)=="table" and prof.FirstClearBosses or {}
					prof.FirstClearBosses[e.Id]=true
					Helpers.CheckAndAutoUnlockConqueror(p,prof,G,e.Id)
				end
				if e.Id=="Noxar" then
					prof.UnlockedHakiColors=type(prof.UnlockedHakiColors)=="table" and prof.UnlockedHakiColors or {}
					if not prof.UnlockedHakiColors.crimson_conqueror then
						prof.UnlockedHakiColors.crimson_conqueror=true
						G.Notify(p,"Chiến công hạ gục Noxar lần đầu: Mở khóa sắc Ý Chí [Hồng Liên Bá Ý]!")
					end
				end
				LiveOps.Notify(G,p,"Chiến công hạ gục "..e.Config.Name..": +15,000 Điểm Danh Vọng / Vinh Dự!","Defeated "..e.Config.Name..": +15,000 Renown / Honor!")
				LiveOps.EvaluateProgressionBadges(G,p,prof)
				LiveOps.RecordLeaderboardScore(p,"Renown",prof.Bounty,false)
			end
			G.Reward(p,e.Config.XP or 0,e.Config.Gold or 0,shards) G.QuestEvent(p,"Kill",e.Id)
		end
	end
	cleanupBossMinions(e)
	if e==G.Boss then
		G.Boss=nil G.ResetAt=os.clock()+10
	elseif e.Respawn and not e.NoRespawn then
		task.delay(10,function() G.SpawnEnemy(e.Id,e.Home,false,false) end)
	end
end
function G.Hit(p,e,damage,breakPower,action)
	if not e or not e.Alive or not e.Model or not e.Model.Parent then return end
	if e.Party then e.Party[p]=true end
	if e.BossOwner and e.BossOwner.Party then e.BossOwner.Party[p]=true end
	if e.Shield then
		local hasAlivePylons=false
		for _,other in ipairs(G.Enemies) do
			if other.BossOwner==e and other.Alive then
				hasAlivePylons=true
				break
			end
		end
		if not hasAlivePylons and (e==G.Boss or e.Id=="AureonSentinel") then
			e.Shield=false
			e.SolarAegis70=false
			if e.Model then e.Model:SetAttribute("Shielded",false) end
		else
			damage=math.max(1,damage*0.25)
		end
	end
	local def=e.Config.DEF or e.Config.Defense or 0
	local actual=math.max(1,math.floor(damage*100/(100+def)))
	local profile=D.Get(p);local rt=G.Runtime[p]
	local stats=G.Stats(p)
	if profile and profile.ClassId=='ThunderStriker' and rt and action=='Attack' then
		rt.StrikerStacks=(rt.StrikerTarget==e and os.clock()<(rt.StrikerUntil or 0))and math.min(5,(rt.StrikerStacks or 0)+1)or 1
		rt.StrikerTarget=e;rt.StrikerUntil=os.clock()+3
	end
	local isCrit=(math.random(1,100)<=((stats and stats.CritRate) or 10))
	if isCrit then
		actual=math.floor(actual*(1+((stats and stats.CritDmg) or 50)/100))
	end
	if profile and profile.Weapon=="dawnbringer_sword" and math.random()<0.15 then
		actual=math.floor(actual*1.35)
	end
	if e==G.Boss and not G.WorldEvents then
		if e.Phase==1 then actual=math.min(actual,e.HP-math.floor(e.MaxHP*.65))
		elseif e.Phase==2 then actual=math.min(actual,e.HP-math.floor(e.MaxHP*.30)) end
	end
	actual=math.max(0,actual) e.HP=math.max(0,e.HP-actual)
	if rt then
		local maxE=tonumber(rt.MaxEnergy) or 100
		rt.Energy=math.min(maxE,(rt.Energy or 0)+6)
		rt.AwakeningMeter=math.min(100,(tonumber(rt.AwakeningMeter or (profile and profile.AwakeningMeter)) or 0)+4)
		if profile then profile.AwakeningMeter=rt.AwakeningMeter end
	end
	local hit=e.Contributors[p] or {Damage=0} hit.Damage+=actual hit.Time=os.clock() e.Contributors[p]=hit
	if os.clock()>e.ImmuneUntil and os.clock()>e.StunnedUntil then
		e.Break+=breakPower
		if e.Break>=100 then e.Break=0 e.StunnedUntil=os.clock()+3 e.ImmuneUntil=os.clock()+9 end
	end
	e.Model:SetAttribute('EnemyHitAt',workspace:GetServerTimeNow())
	if W.UpdateEnemyBar then W.UpdateEnemyBar(e) end
	local skillCfg=action and C.Actions[action]
	local elem=(skillCfg and skillCfg.Element) or (profile and profile.ClassId=="ArcaneMage" and "Frost") or (profile and profile.ClassId=="ThunderStriker" and "Lightning") or "Sky"
	G.FireCombatEvent({
		kind="DamageNumber",
		pos=e.Body.Position,
		amount=math.floor(actual),
		crit=isCrit,
		breakDmg=breakPower,
		element=elem,
	})
	if e==G.Boss and e.Phase==1 and e.HP<=e.MaxHP*.65 then
		e.Phase=2 e.State="Phase2"
		if not G.WorldEvents then
			e.Shield=true
			for _,x in ipairs({-24,24}) do
				local pillar=G.SpawnEnemy("EnergyPylon",C.Arena+_V3(x,2,0),true,true) pillar.BossOwner=e
			end
		end
	elseif e==G.Boss and e.Phase==2 and e.HP<=e.MaxHP*.3 and not e.Shield then e.Phase=3 e.State="Phase3" end
	if e.HP<=0 then e.BodyPosition=e.Body.Position G.Kill(e) end
end
local function inArena(p)
	local r=root(p) return r and distance(r.Position,C.Arena)<220
end
function G.PlayerDamage(p,amount,attackerEnemy)
	local r,h=root(p) local rt=G.Runtime[p] local stats=G.Stats(p)
	if not r or not h or not rt or not stats or os.clock()<rt.InvincibleUntil then return end
	local profile=D.Get(p)
	if profile then
		ensureProfileFields(profile)
		if ((p.Character and p.Character:GetAttribute("HakiInstinct")) or p:GetAttribute("HakiInstinct")) and profile.Haki and (profile.Haki.InstinctDodges or 0)>0 then
			profile.Haki.InstinctDodges=math.max(0,(profile.Haki.InstinctDodges or 0)-1)
			p:SetAttribute("InstinctDodges",profile.Haki.InstinctDodges)
			if p.Character then p.Character:SetAttribute("InstinctDodges",profile.Haki.InstinctDodges) end
			G.FireCombatEvent({
				kind="DamageNumber",
				pos=r.Position+_V3(0,2.5,0),
				amount=0,
				crit=false,
				element="Sky",
				Text="THẤU Ý NÉ! ("..tostring(profile.Haki.InstinctDodges).."/8)",
			})
			R.CombatFX:FireAllClients({
				Kind="InstinctDodge",
				Action="InstinctDodge",
				Position=r.Position,
				DodgesLeft=profile.Haki.InstinctDodges,
				MaxDodges=8,
				Actor=p.UserId,
			})
			G.Sync(p)
			return
		end
		local fruitCfg=getFruitCfg(profile.EquippedFruit)
		local isBossOrElite=attackerEnemy and (attackerEnemy==G.Boss or attackerEnemy.Config.Boss or attackerEnemy.Config.Elite)
		local enemyLv=(attackerEnemy and attackerEnemy.Config.Level) or 1
		if fruitCfg and fruitCfg.Logia and not isBossOrElite and profile.Level>=(enemyLv+5) and math.random()<0.65 then
			G.FireCombatEvent({
				kind="DamageNumber",
				pos=r.Position+_V3(0,2.5,0),
				amount=0,
				crit=false,
				element=fruitCfg.Element or "Sky",
				Text="MIỄN NHIỄM AETHER!",
			})
			return
		end
	end
	if p.Character and (p.Character:GetAttribute("FruitTransform") or "")~="" then
		amount=math.floor(amount*0.42)
	end
	local multiplier=os.clock()<rt.ShieldUntil and .35 or 1
	if profile and profile.ClassId=='SkyGuardian' and profile.Level>=10 then
		for _,ally in ipairs(Players:GetPlayers()) do local ar=root(ally)
			if ally~=p and ar and distance(r.Position,ar.Position)<18 then multiplier*=.9 break end
		end
	end
	h:TakeDamage(math.max(1,math.floor(amount*100/(100+stats.DEF)*multiplier))) rt.LastHurt=os.clock()
	rt.AwakeningMeter=math.min(100,(tonumber(rt.AwakeningMeter or (profile and profile.AwakeningMeter)) or 0)+5)
	if profile then profile.AwakeningMeter=rt.AwakeningMeter end
end

function G.SpawnTelegraph(centerPos,radius,duration,label,onDetonate,_,_,_,ownerEnemy)
	local tempFolder=workspace:FindFirstChild("TempFX")
	if not tempFolder then
		tempFolder=_IN("Folder")
		tempFolder.Name="TempFX"
		tempFolder.Parent=workspace
	end
	local gy=safeGroundY(centerPos)+0.48
	local m=_IN("Model")
	m.Name="TelegraphZone"
	if type(ownerEnemy)=="table" then
		m:SetAttribute("OwnerEnemyId",tostring(ownerEnemy.Id or ""))
		ownerEnemy._ActiveTelegraphs=ownerEnemy._ActiveTelegraphs or {}
		table.insert(ownerEnemy._ActiveTelegraphs,m)
	end
	m.Parent=tempFolder

	local ring=_IN("Part")
	ring.Name="OuterRing"
	ring.Shape=Enum.PartType.Cylinder
	ring.Size=_V3(0.25,radius*2,radius*2)
	ring.CFrame=_CF(centerPos.X,gy,centerPos.Z)*_CFA(0,0,math.pi/2)
	ring.Color=_RGB(255,64,84)
	ring.Material=Enum.Material.Neon
	ring.Transparency=0.25
	ring.Anchored=true
	ring.CanCollide=false
	ring.CanQuery=false
	ring.CanTouch=false
	ring.Parent=m

	local inner=_IN("Part")
	inner.Name="InnerFill"
	inner.Shape=Enum.PartType.Cylinder
	inner.Size=_V3(0.3,1,1)
	inner.CFrame=ring.CFrame
	inner.Color=_RGB(255,32,64)
	inner.Material=Enum.Material.Neon
	inner.Transparency=0.45
	inner.Anchored=true
	inner.CanCollide=false
	inner.CanQuery=false
	inner.CanTouch=false
	inner.Parent=m

	if label and label~="" then
		local bill=_IN("BillboardGui")
		bill.Size=_UD2S(3.6,0.68)
		bill.StudsOffset=_V3(0,3.2,0)
		bill.AlwaysOnTop=false bill.MaxDistance=52
		bill.Parent=ring
		local tl=_IN("TextLabel")
		tl.Size=_UD2S(1,1)
		tl.BackgroundTransparency=1
		tl.Font=Enum.Font.GothamBlack
		tl.TextScaled=true
		tl.TextColor3=_RGB(255,95,110)
		tl.TextStrokeTransparency=0.2
		tl.Text=label
		tl.Parent=bill
	end

	TweenService:Create(inner,TweenInfo.new(duration,Enum.EasingStyle.Linear),{
		Size=_V3(0.3,radius*2,radius*2),
		Transparency=0.12,
	}):Play()

	Debris:AddItem(m,duration+0.35)
	task.delay(duration,function()
		if m.Parent then m:Destroy() end
		if onDetonate then pcall(onDetonate) end
	end)
end

function G.Telegraph(e,pos,radius,delayTime,damage,label,checkLiveMelee)
	G.SpawnTelegraph(pos,radius,delayTime,label or " DANGER",function()
		if not e.Alive or not e.Model.Parent or os.clock()<e.StunnedUntil then return end
		local liveOrigin=checkLiveMelee and e.Body and e.Body.Position or pos
		for _,p in ipairs(Players:GetPlayers()) do
			local r=root(p)
			if r and participant(e,p) and math.abs(r.Position.Y-pos.Y)<=14 then
				local dFlat=distance(_V3(r.Position.X,pos.Y,r.Position.Z),pos)
				local dLive=checkLiveMelee and distance(r.Position,liveOrigin) or dFlat
				if dFlat<=radius and dLive<=(radius+2.5) and clearLine(e.Body.Position,r.Position) then
					G.PlayerDamage(p,damage,e)
				end
			end
		end
	end,nil,nil,nil,e)
end
function G.Action(p,action,payload)
	if type(action)~="string" or not C.Actions[action] or not G.Rate(p,"Action",.08) then return end
	local r=root(p) local rt=G.Runtime[p] local profile=D.Get(p) local cfg=C.Actions[action]
	if not r or not rt or not profile or not C.Classes[profile.ClassId] or (cfg.ClassId and cfg.ClassId~=profile.ClassId) then return end
	cfg=table.clone(cfg)
	local effSlot=math.clamp(tonumber(profile.ActiveSlot) or 1,1,4)
	local skillLv=(profile.SkillLevels and profile.SkillLevels[action]) or 1
	local skillScale=(1+0.12*skillLv-0.12)
	if cfg.Multiplier and action~="Attack" and action~="Heavy" then
		cfg.Multiplier=cfg.Multiplier*skillScale
	end
	local mage=(profile.ClassId=='ArcaneMage' and effSlot~=3)
	if mage and action=='Attack'then cfg.Range=34;cfg.Cooldown=.7 end
	if mage and action=='Heavy'then cfg.Range=16 end
	local striker=profile.ClassId=='ThunderStriker'
	local speed=1
	if striker and (action=='Attack' or action=='Heavy') then
		speed=1+((os.clock()<(rt.StrikerUntil or 0))and math.min(5,rt.StrikerStacks or 0)*.04 or 0)
		cfg.Cooldown=(action=='Attack'and .3 or 1.5)/speed
	end
	local now=os.clock()
	local evade=action=="Dodge" or action=="Dash" or action=='FlashStep'
	if now<rt.ActionUntil or now<(rt.Cooldowns[action] or 0) or (evade and now<(rt.EvadeUntil or 0)) or rt.Stamina<(cfg.Cost or 0) then return end
	local activeFruitTransform=tostring((p.Character and p.Character:GetAttribute("FruitTransform")) or "")
	if not profile.Weapon or profile.Weapon=="" then profile.Weapon="sunshard_halberd" end
	cfg.Range=math.max(tonumber(cfg.Range) or 24, action=="Attack" and 24 or 28)
	if activeFruitTransform~="" and not evade then
		cfg.Range=(cfg.Range or 24)*2.0
		cfg.Multiplier=(cfg.Multiplier or 1)*1.35
	end
	rt.Cooldowns[action]=now+cfg.Cooldown rt.Stamina-=cfg.Cost or 0
	local aimDir3D=Helpers.Resolve3DAimDirection(r,payload)
	if evade then
		local _,h=root(p)
		local duration=action=='FlashStep' and .34 or (action=="Dash" and .38 or .34)
		local travel=action=='FlashStep' and 58 or (action=="Dash" and 44 or 38)
		local move=h.MoveDirection
		local direction=_V3(move.X,0,move.Z)
		if action=='FlashStep' then direction=aimDir3D end
		if direction.Magnitude<.1 then
			direction=(action=="Dodge") and -r.CFrame.LookVector or aimDir3D
		end
		if action~='FlashStep' then direction=_V3(direction.X,0,direction.Z) end
		if direction.Magnitude<.05 then direction=_V3(0,0,-1) else direction=direction.Unit end
		rt.InvincibleUntil=now+.38 rt.ActionUntil=now+duration*.65 rt.EvadeUntil=now+(action=='FlashStep'and .45 or math.min(cfg.Cooldown or .9,.85))
		rt.JumpPadUntil=math.max(rt.JumpPadUntil or 0, now+duration+1.45)
		R.CombatFX:FireAllClients({
			Kind="Dodge",
			Position=r.Position,
			Actor=p.UserId,
			Action=action,
			Direction=direction,
			Travel=travel,
			Duration=duration,
		})
		if action=='FlashStep' then
			local character=p.Character
			task.delay(duration,function()
				if p.Character==character then
					local rr=root(p) local stats=G.Stats(p,effSlot)
					if rr and stats then
						for _,e in ipairs(G.Enemies) do
							if e.Alive and e.Model and e.Model.Parent and e.Body and distance(rr.Position,e.Body.Position)<=16 then
								G.Hit(p,e,stats.ATK*(cfg.Multiplier or 1.4),cfg.Break or 12,action)
							end
						end
					end
				end
			end)
		end
		return
	elseif action=="GuardianShield" or action=='ManaBarrier' then
		rt.ActionUntil=now+.3
		if action=='ManaBarrier' then rt.Stamina=math.min(100,rt.Stamina+25) end
		for _,ally in ipairs(Players:GetPlayers()) do local ar=root(ally) local art=G.Runtime[ally]
			if ar and art and ally.Character and (action~='ManaBarrier'or ally==p)and distance(ar.Position,r.Position)<20 then
				art.ShieldUntil=now+5
				ally.Character:SetAttribute("GuardianShieldUntil",workspace:GetServerTimeNow()+5)
			end
		end
		R.CombatFX:FireAllClients({Kind="Shield",Position=r.Position,Actor=p.UserId,Action=action}) return
	end
	if action=="CelestialAegis" then
		for _,ally in ipairs(Players:GetPlayers()) do
			local ar=root(ally) local art=G.Runtime[ally]
			if ar and art and ally.Character and distance(ar.Position,r.Position)<24 then
				art.ShieldUntil=now+6
				ally.Character:SetAttribute("GuardianShieldUntil",workspace:GetServerTimeNow()+6)
			end
		end
		R.CombatFX:FireAllClients({Kind="Shield",Position=r.Position,Actor=p.UserId,Action=action})
	elseif action=="StormBlitz" then
		rt.StrikerStacks=5
		rt.StrikerUntil=now+6
	end
	local combo=1
	if action=="Attack" then rt.Combo=(now-rt.LastAttack<1.2) and (rt.Combo%3+1) or 1 rt.LastAttack=now combo=rt.Combo end
	local duration=action=='ArcCut'and 1.6 or(striker and .52/speed or(action=="Heavy" and (34/30) or (action=="SkySlash" and (32/30) or (({18,20,24})[combo]/30))))
	if mage then duration=action=='Heavy'and 1.3 or 1.0 end
	local windup=duration*.45
	rt.ActionUntil=now+duration*.72
	local origin=r.Position local facing=aimDir3D
	R.CombatFX:FireAllClients({Kind="Swing",Position=origin+facing*4,Look=facing,Actor=p.UserId,Action=action,Combo=combo})
	local character=p.Character
	local radialAoE=(action=="CelestialAegis" or action=="StormBlitz" or action=="ThunderJudgement" or action=="AstralCataclysm" or action=="ArcaneComet" or action=="JudgmentStrike")
	local function strike()
		local rr=root(p) local stats=G.Stats(p,effSlot)
		if not rr or not stats or p.Character~=character or distance(rr.Position,origin)>85 then return end
		local curFacing=Helpers.Resolve3DAimDirection(rr,payload)
		for _,e in ipairs(G.Enemies) do
			if e.Alive and e.Model and e.Model.Parent and e.Body then
				local delta=e.Body.Position-rr.Position
				local flatDist=_V3(delta.X,0,delta.Z).Magnitude
				local dUnit=delta.Magnitude>0.01 and delta.Unit or curFacing
				if (delta.Magnitude<=cfg.Range or (flatDist<=cfg.Range and math.abs(delta.Y)<=24)) and (radialAoE or (mage and action=='Heavy') or delta.Magnitude<14 or facing:Dot(dUnit)>-0.45 or curFacing:Dot(dUnit)>-0.45) then
					G.Hit(p,e,stats.ATK*(cfg.Multiplier or 1)*(combo==3 and 1.45 or 1),(cfg.Break or 10)*(combo==3 and 1.5 or 1),action)
				end
			end
		end
	end
	if action=='ArcCut' then for _,at in {.25,.7,1.15}do task.delay(at,strike)end else task.delay(windup,strike)end
end
function G.BuildSkyShip(pOrShipId,spawnPos,customShipId)
	local isPlayer=typeof(pOrShipId)=="Instance" and pOrShipId:IsA("Player")
	local p=isPlayer and pOrShipId or nil
	local r=p and root(p) or nil
	local basePos=spawnPos or (r and (r.Position+r.CFrame.LookVector*14+_V3(0,2,0)) or _V3(-428,44,565))
	local shipId=customShipId or (not isPlayer and tostring(pOrShipId or "CelestialBrigantine")) or nil
	if not shipId and p then
		local realm=p:GetAttribute("CurrentRealm") or "GoldenSky"
		if realm=="FrozenCyber" then
			shipId="CyberEnforcer"
		elseif realm=="ShadowRealm" then
			shipId="LeviathanHunterShip"
		else
			shipId="CelestialBrigantine"
		end
	end
	shipId=shipId or "CelestialBrigantine"

	local worldObjects=workspace:FindFirstChild("SkybreakWorldObjects") or workspace
	local modelName=p and ("SkyShip_"..p.Name) or ("SkyShip_"..shipId)
	local existing=worldObjects:FindFirstChild(modelName)
	if existing then existing:Destroy() end

	local ship=_IN("Model")
	ship.Name=modelName
	ship:SetAttribute("ShipId",shipId)
	ship.Parent=worldObjects

	local helm=nil
	local bannerTarget=nil
	local shipTitle="CELESTIAL AETHER GALLEON"
	local shipTitleColor=_RGB(255,222,105)
	local shipVisualAsset="CelestialAetherGalleon"

	if shipId=="CyberEnforcer" then
		shipTitle="CYBER ENFORCER • VTOL CRYO GUNSHIP"
		shipTitleColor=_RGB(92,240,255)
		shipVisualAsset="CyberEnforcerShip"
	elseif shipId=="LeviathanHunterShip" then
		shipTitle="SERPENT HUNTER • VOID DREADNOUGHT"
		shipTitleColor=_RGB(215,112,255)
		shipVisualAsset="LeviathanHunterShip"
	end

	-- Walkable invisible collision deck + helm anchor; 3D rigged ship is built by BlenderEnemies.client.lua via DelegatedV5Renderer!
	local hull=W.Part(ship,"Body",_V3(14,2.2,32),basePos,shipTitleColor,Enum.Material.Metal)
	hull.Transparency=1
	ship.PrimaryPart=hull
	helm=W.Part(ship,"CaptainHelm",_V3(2.2,3.4,2.2),basePos+_V3(0,2.5,4.0),shipTitleColor,Enum.Material.Neon)
	helm.Transparency=0.85
	helm.CanCollide=true
	bannerTarget=helm
	ship:SetAttribute("NPCId",shipVisualAsset)
	ship:SetAttribute("VisualAsset",shipVisualAsset)
	ship:SetAttribute("ShowcaseScale",4.2)
	ship:SetAttribute("NPCFloorY",basePos.Y-1.2)

	bannerTarget=bannerTarget or ship.PrimaryPart
	local light=_IN("PointLight")
	light.Color=shipTitleColor
	light.Brightness=1.38
	light.Range=16
	light.Parent=bannerTarget

	local seat=_IN("Seat")
	seat.Name="PilotSeat"
	seat.Size=_V3(2.4,1.2,2.4)
	seat.CFrame=_CF(helm.Position+_V3(0,-0.8,1.8))
	seat.Anchored=true
	seat.Transparency=1
	seat.Color=_RGB(36,42,58)
	seat.Material=Enum.Material.SmoothPlastic
	seat.Parent=ship

	local bill=_IN("BillboardGui")
	bill.Size=_UD2S(4.2,0.76)
	bill.StudsOffset=_V3(0,11.5,0)
	bill.AlwaysOnTop=false bill.MaxDistance=52
	bill.Parent=bannerTarget
	local tl=_IN("TextLabel")
	tl.Size=_UD2S(1,1)
	tl.BackgroundTransparency=1
	tl.Font=Enum.Font.GothamBlack
	tl.TextScaled=true
	tl.TextColor3=shipTitleColor
	tl.TextStrokeTransparency=0.2
	tl.Text=shipTitle..(p and (" • "..p.Name) or "")
	tl.Parent=bill

	local islandTargets={
		{Name="Sunshard Sanctuary", Realm="GoldenSky", Pos=_V3(2800,50.5,-55)},
		{Name="West Garden Bastion", Realm="GoldenSky", Pos=_V3(-2800,50.5,-65)},
		{Name="Core Shrine", Realm="GoldenSky", Pos=_V3(-560,52.5,996)},
		{Name="Trade Station", Realm="FrozenCyber", Pos=_V3(9400,50.9,1785)},
		{Name="Permafrost Garrison", Realm="FrozenCyber", Pos=_V3(9400,50.9,-2055)},
		{Name="Microchip Raid Lab", Realm="FrozenCyber", Pos=_V3(14600,50.9,1785)},
		{Name="Glacial Wreckage", Realm="FrozenCyber", Pos=_V3(14600,50.9,-1812)},
		{Name="Void Bastion", Realm="ShadowRealm", Pos=_V3(-14600,50.9,2173.1)},
		{Name="Umbral Crystal Sanctum", Realm="ShadowRealm", Pos=_V3(-9400,50.9,1815)},
		{Name="Ascension Shrine", Realm="ShadowRealm", Pos=_V3(-14600,50.9,-1785)},
		{Name="Phantom Isle (Serpent Abyss)", Realm="ShadowRealm", Pos=_V3(-12000,50.9,-3364.5)},
		{Name="Sky Hub", Realm="GoldenSky", Pos=C.Spawn},
	}
	local routeIdx=1
	local prompt=_IN("ProximityPrompt")
	prompt.ActionText="Lái Tàu Bay / Bay Tới Đảo Tiếp Theo"
	prompt.ObjectText=shipTitle
	prompt.MaxActivationDistance=16
	prompt.HoldDuration=0
	prompt.Parent=helm
	prompt.Triggered:Connect(function(plr)
		local pr=root(plr)
		if not pr then return end
		if inLockedEncounter(plr) then
			LiveOps.Notify(G,plr,"Không thể lái tàu vượt đảo khi đang giao tranh PvP!","Cannot warp ship while in PvP combat!")
			return
		end
		local dest=islandTargets[routeIdx]
		routeIdx=(routeIdx%#islandTargets)+1
		plr:SetAttribute("CurrentRealm",dest.Realm)
		local newBase=dest.Pos+_V3(0,2,26)
		ship:SetAttribute("NPCFloorY",newBase.Y-1.2)
		ship:PivotTo(_CF(newBase))
		G.Teleport(plr,dest.Pos)
		G.Notify(plr," "..shipTitle.." đã đưa bạn vượt biển mây tới: "..dest.Name.."!")
		G.Sync(plr)
	end)

	return ship
end

function G.UseSlotMove(p,key,payload)
	if not G.Rate(p,"SlotMove",.12) then return end
	local r,h=root(p) local rt=G.Runtime[p] local profile=D.Get(p)
	if not r or not h or not rt or not profile then return end
	ensureProfileFields(profile)
	key=string.upper(tostring(key or "Z"))
	if key~="Z" and key~="X" and key~="C" and key~="V" and key~="F" then key="Z" end

	local slot=math.clamp(tonumber(profile.ActiveSlot) or 2,1,4)
	local activeId="SolarTitanCore"
	local activeCfg=nil
	local element="Sky"
	if slot==1 then
		activeId=profile.FightingStyle or "SkybornCombat"
		activeCfg=getStyleCfg(activeId)
		element=(activeCfg and activeCfg.Element) or "Sky"
	elseif slot==2 then
		local rawF=profile.EquippedFruit or "SolarTitanCore"
		activeId=Helpers.ResolveFruitId(rawF)~="" and Helpers.ResolveFruitId(rawF) or rawF
		activeCfg=getFruitCfg(activeId)
		element=(activeCfg and activeCfg.Element) or "Sky"
	elseif slot==3 then
		activeId=profile.Weapon or "dawnbringer_sword"
		activeCfg=(C.Swords and C.Swords[activeId]) or (C.Items and C.Items[activeId]) or {Name="Thần Kiếm Skyborn", Element="Sky"}
		element=activeCfg.Element or "Sky"
	else
		activeId=profile.EquippedGun or "soul_guitar_void"
		activeCfg=getGunCfg(activeId)
		element=(activeCfg and activeCfg.Element) or "Void"
	end

	local defaultByKey={
		Z={Name=activeId.."_Z", Mult=2.3, Range=24, Cooldown=3.2},
		X={Name=activeId.."_X", Mult=2.9, Range=28, Cooldown=4.8},
		C={Name=activeId.."_C", Mult=3.6, Range=32, Cooldown=6.5},
		V={Name=activeId.."_V", Mult=4.8, Range=38, Cooldown=9.5},
		F={Name=activeId.."_F", Mult=1.8, Range=28, Cooldown=4.0},
	}
	local moveSpec=defaultByKey[key]
	if activeCfg and type(activeCfg.Moves)=="table" then
		if activeCfg.Moves[key] then
			moveSpec=activeCfg.Moves[key]
		else
			for _,m in pairs(activeCfg.Moves) do
				if type(m)=="table" and string.upper(tostring(m.Key or ""))==key then
					moveSpec=m
					break
				end
			end
		end
	end

	local now=os.clock()
	local cdKey="Slot_"..key
	if now<(rt.Cooldowns[cdKey] or 0) then return end
	local maxE=tonumber(rt.MaxEnergy) or 100
	local cost=math.max(0,tonumber(moveSpec and moveSpec.Cost) or 10)
	if cost>0 and (rt.Energy or maxE)<cost then
		G.Notify(p,"Không đủ Aether Energy!")
		return
	end
	local cd=tonumber(moveSpec and moveSpec.Cooldown) or defaultByKey[key].Cooldown
	if profile.RaceV4Active and profile.Race=="Ghoul" then
		cd*=0.80
	end
	rt.Cooldowns[cdKey]=now+cd
	rt.Cooldowns[key]=now+cd
	if cost>0 then
		rt.Energy=math.max(0,(rt.Energy or maxE)-cost)
		rt.LastCastAt=now
	end

	local moveName=(moveSpec and (moveSpec.Name or moveSpec.Id)) or (activeId.."_"..key)
	local mult=tonumber(moveSpec and (moveSpec.Mult or moveSpec.Multiplier)) or defaultByKey[key].Mult
	local range=tonumber(moveSpec and moveSpec.Range) or defaultByKey[key].Range

	if slot==2 and profile.AwakenedFruits and profile.AwakenedFruits[activeId] then
		mult*=1.25
		range*=1.20
	end

	local originPos=r.Position
	local lookVec=Helpers.Resolve3DAimDirection(r,payload)
	local endPos=originPos

	local function safeDashTo(dist)
		local dir=lookVec*dist
		local rp=RaycastParams.new() rp.FilterType=Enum.RaycastFilterType.Exclude rp.FilterDescendantsInstances={p.Character,workspace.ActiveEnemies,workspace.ActiveBosses} rp.RespectCanCollide=true
		local hit=workspace:Raycast(originPos,dir,rp)
		local target=hit and (hit.Position-lookVec*2.8) or (originPos+dir)
		local gy=safeGroundY(target,originPos.Y-3.2)
		local desiredY=math.abs(lookVec.Y)>0.22 and math.clamp(target.Y,gy+2.8,originPos.Y+36) or math.clamp(gy+3.0,originPos.Y-14,originPos.Y+18)
		target=_V3(target.X,desiredY,target.Z)
		rt.JumpPadUntil=math.max(rt.JumpPadUntil or 0,now+1.45)
		G.Teleport(p,target)
		return target
	end

	-- Special Transformation, Lunge, Beam, Domain & Dash Moves across all 12 Aether Fruits
	if slot==2 then
		if activeId=="SolarTitanCore" and key=="Z" then
			local cur=(p.Character and p.Character:GetAttribute("FruitTransform")) or p:GetAttribute("FruitTransform") or ""
			local nextState=(cur=="SolarTitan") and "" or "SolarTitan"
			p:SetAttribute("FruitTransform",nextState)
			if p.Character then p.Character:SetAttribute("FruitTransform",nextState) end
			if nextState=="SolarTitan" then
				G.Notify(p,"SOLAR TITAN SHIFT: Hóa Kim Thân Khổng Lồ 3D (+58% Giáp, x2.5 Tầm Đánh)!")
			else
				G.Notify(p,"SOLAR TITAN SHIFT: Thu hồi Kim Thân, trở về nhân dạng!")
			end
		elseif activeId=="AbyssalSovereignCore" and key=="V" then
			local cur=(p.Character and p.Character:GetAttribute("FruitTransform")) or p:GetAttribute("FruitTransform") or ""
			local nextState=(cur=="AbyssalSovereign") and "" or "AbyssalSovereign"
			p:SetAttribute("FruitTransform",nextState)
			if p.Character then p.Character:SetAttribute("FruitTransform",nextState) end
			if nextState=="AbyssalSovereign" then
				G.Notify(p,"ABYSSAL SOVEREIGN: Hóa Thân Thái Cổ Long Hoàng 3D (+65% Giáp, x2.2 Tầm Đánh)!")
			else
				G.Notify(p,"ABYSSAL SOVEREIGN: Thu hồi Long Hồn, trở về nhân dạng!")
			end
		elseif key=="F" then
			rt.InvincibleUntil=math.max(rt.InvincibleUntil or 0,now+1.6)
			local fDist=(activeId=="CelestialLightCore" and 62) or (activeId=="DimensionalPortalCore" and 56) or (activeId=="AbyssalSovereignCore" and 52) or (activeId=="ThunderRumbleCore" and 52) or 46
			endPos=safeDashTo(fDist)
		elseif activeId=="DimensionalPortalCore" and key=="Z" then
			rt.InvincibleUntil=math.max(rt.InvincibleUntil or 0,now+0.8)
			endPos=safeDashTo(28)
		elseif activeId=="DimensionalPortalCore" and key=="X" then
			rt.InvincibleUntil=math.max(rt.InvincibleUntil or 0,now+2.2)
			endPos=originPos+lookVec*10
			G.Notify(p,"PARALLEL ESCAPE: Ẩn thân Dị Giới Vô Địch 2.2s!")
		elseif activeId=="DimensionalPortalCore" and key=="C" then
			endPos=safeDashTo(58)
			G.Notify(p,"WORLD GATE RIFT: Dịch chuyển xuyên không gian 58m!")
		elseif activeId=="CelestialLightCore" and key=="C" then
			rt.InvincibleUntil=math.max(rt.InvincibleUntil or 0,now+0.9)
			endPos=safeDashTo(26)
		elseif activeId=="AetherflowCore" and key=="C" then
			endPos=safeDashTo(30)
		elseif activeId=="AbyssalSovereignCore" and key=="X" then
			endPos=safeDashTo(18)
		elseif activeId=="StarforgedMagmaCore" and key=="X" then
			endPos=safeDashTo(18)
		elseif activeId=="SolarTitanCore" and key=="X" then
			endPos=safeDashTo(14)
		elseif key=="Z" then
			local zDist=(activeId=="CelestialLightCore" and 38) or (activeId=="AbyssalSovereignCore" and 34) or (activeId=="ThunderRumbleCore" and 32) or (activeId=="AetherflowCore" and 30) or 24
			endPos=originPos+lookVec*zDist
		elseif key=="X" then
			endPos=originPos+lookVec*14
		elseif key=="C" then
			local cDist=(activeId=="GlacierIceCore" and 30) or (activeId=="StarforgedMagmaCore" and 28) or (activeId=="ThunderRumbleCore" and 32) or (activeId=="SolarTitanCore" and 26) or 14
			endPos=originPos+lookVec*cDist
		elseif key=="V" then
			local vDist=(activeId=="SolarFlameCore" or activeId=="ThunderRumbleCore" or activeId=="AstralGravityCore" or activeId=="AetherflowCore") and 16 or 0
			endPos=originPos+lookVec*vDist
		end
	elseif key=="Z" and (slot==1 or slot==3) then
		endPos=safeDashTo(14)
	elseif key=="F" then
		rt.InvincibleUntil=math.max(rt.InvincibleUntil or 0,now+1.5)
		endPos=safeDashTo(44)
	end

	local ft=p.Character and p.Character:GetAttribute("FruitTransform")
	if ft=="SolarTitan" or ft=="AbyssalSovereign" then
		range*=2.2
	end

	local isFreezeFruit=(slot==2 and (activeId=="GlacierIceCore" or activeId=="ThunderRumbleCore" or activeId=="AstralGravityCore" or (activeId=="SandstoneCore" and key=="X") or (activeId=="AetherflowCore" and (key=="X" or key=="C"))))
	local isPullFruit=(slot==2 and ((activeId=="GaleCore" and key=="C") or (activeId=="SandstoneCore" and key=="C") or (activeId=="AstralGravityCore" and (key=="X" or key=="V")) or (activeId=="DimensionalPortalCore" and (key=="C" or key=="V"))))
	local isDoTFruit=(slot==2 and (activeId=="SolarFlameCore" or activeId=="StarforgedMagmaCore"))
	local isMultiWave=(slot==2 and (key=="C" or key=="V"))

	local stats=G.Stats(p,slot)
	if stats then
		local midPos=(originPos+endPos)*0.5
		local breakAmt=(moveSpec and moveSpec.Break) or 24
		for _,e in ipairs(G.Enemies) do
			if e.Alive and e.Model and e.Model.Parent and e.Body then
				local ebPos=e.Body.Position
				if distance(r.Position,ebPos)<=range or distance(originPos,ebPos)<=range or distance(endPos,ebPos)<=range or distance(midPos,ebPos)<=math.max(16,range*0.75) then
					G.Hit(p,e,stats.ATK*mult,breakAmt,moveName)
					if isFreezeFruit and e.Alive then
						local stunDur=(key=="V" and 2.8) or 1.8
						e.StunnedUntil=math.max(e.StunnedUntil or 0,now+stunDur)
					end
					if isPullFruit and e.Alive and not e.Config.Boss and not SINGLETON_BOSSES[e.Id] and not e.BossOwner and (e.Config.Speed or 0)>0 and e.Body and e.Model then
						local pullCenter=(endPos-originPos).Magnitude>2 and endPos or originPos
						local pullPos=ebPos:Lerp(_V3(pullCenter.X,ebPos.Y,pullCenter.Z),0.42)
						local curRot=e.Body.CFrame-e.Body.Position
						e.Model:PivotTo(_CF(pullPos)*curRot)
						e.CachedGroundY=nil
					end
				end
			end
		end

		-- Multi-tick Elemental DoT (Solar Flame / Starforged Magma) or Multi-Wave Barrage (C / V Ultimates)
		local extraTicks=(isDoTFruit and 3) or (isMultiWave and 2) or 0
		local tickMult=isDoTFruit and (mult*0.22) or (mult*0.28)
		if extraTicks>0 then
			local character=p.Character
			for tIdx=1,extraTicks do
				task.delay(tIdx*0.28,function()
					if p.Character~=character then return end
					local curStats=G.Stats(p,slot)
					if not curStats then return end
					for _,e in ipairs(G.Enemies) do
						if e.Alive and e.Model and e.Model.Parent and e.Body then
							local ebPos=e.Body.Position
							if distance(originPos,ebPos)<=range or distance(endPos,ebPos)<=range or distance(midPos,ebPos)<=range then
								G.Hit(p,e,curStats.ATK*tickMult,8,moveName)
							end
						end
					end
				end)
			end
		end
	end

	if not G.CombatExpansion then
		local mMult=LiveOps.GetFriendBoostMultiplier(p)
		if (profile.OwnedGamePasses and profile.OwnedGamePasses.x2_mastery==true) or p:GetAttribute("OwnedPass_x2_mastery")==true then mMult*=2 end
		if (tonumber(profile.DoubleExpRemainingSec) or 0)>0 then mMult*=2 end
		profile.Mastery[activeId]=math.min(600,(profile.Mastery[activeId] or 1)+math.max(1,math.floor(12*mMult+0.5)))
	end
	rt.AwakeningMeter=math.min(100,(tonumber(rt.AwakeningMeter or profile.AwakeningMeter) or 0)+10)
	profile.AwakeningMeter=rt.AwakeningMeter

	local clipAct=(slot==2 and ("Fruit"..key)) or ("Skill"..key)
	R.CombatFX:FireAllClients({
		Kind="Skill",
		kind="SkillVFX",
		Position=originPos,
		pos=originPos,
		startPos=originPos,
		endPos=endPos,
		look=lookVec,
		Actor=p.UserId,
		userId=p.UserId,
		Action=clipAct,
		Clip=clipAct,
		skillId=moveName,
		key=key,
		moveKey=key,
		slot=slot,
		activeId=activeId,
		element=element,
	})
	G.Sync(p)
end

-- Cong thuc Lo Ren V2/Expansion (RarityConfig.Recipes, da gop ExpansionRecipes) quy ve dang C.ForgeRecipes.
local rarityForgeIndex=nil
local function findRarityForgeRecipe(itemId,recipeId)
	if not rarityForgeIndex then
		rarityForgeIndex={}
		local okR,RC=pcall(function()
			return require(game:GetService("ReplicatedStorage"):WaitForChild("SkybreakShared"):WaitForChild("Config"):WaitForChild("RarityConfig"))
		end)
		if okR and type(RC)=="table" and type(RC.Recipes)=="table" then
			for _,rec in ipairs(RC.Recipes) do
				if type(rec)=="table" and type(rec.OutputItemId)=="string" then
					local mats={}
					for _,m in ipairs(rec.Materials or {}) do
						if type(m)=="table" and m.ItemId then mats[m.ItemId]=(mats[m.ItemId] or 0)+(tonumber(m.Count) or 1) end
					end
					local conv={Id=rec.Id,ItemId=rec.OutputItemId,Gold=tonumber(rec.GoldCost) or 0,CoreShards=tonumber(rec.CoreShardCost) or 0,LevelReq=tonumber(rec.LevelReq) or 1,Materials=mats}
					rarityForgeIndex[rec.OutputItemId]=rarityForgeIndex[rec.OutputItemId] or conv
					if type(rec.Id)=="string" then rarityForgeIndex["#"..rec.Id]=conv end
				end
			end
		end
	end
	local byRecipe=type(recipeId)=="string" and rarityForgeIndex["#"..recipeId] or nil
	if byRecipe and byRecipe.ItemId==itemId then return byRecipe end
	return rarityForgeIndex[itemId]
end
function G.Equipment(p,payload)
	if type(payload)~="table" then return end
	local act=payload.action
	if act=="SetLocale" or act=="SyncLocale" or act=="SetLanguage" then
		if not G.Rate(p,"Equipment_Locale",0.05) then return end
		local raw=payload.Language or payload.lang or payload.locale or payload.Locale or payload.RobloxLocaleId or payload.id
		LiveOps.SetPlayerLocale(p,raw)
		if D.Get(p) then G.Sync(p) end
		return
	end
	local rateWindow=(act=="AddStat" or act=="RefundStats" or act=="BoostLevel") and 0.01 or 0.08
	if not G.Rate(p,"Equipment_"..tostring(act or "General"),rateWindow) then return end
	local profile=D.Get(p) local rt=G.Runtime[p] local r,h=root(p)
	if not profile or not rt then return end
	ensureProfileFields(profile)
	profile.Equipped=profile.Equipped or {}
	profile.SkillLevels=profile.SkillLevels or {}
	if act=="Unequip" then
		local slot=payload.slot or (payload.itemId and C.Items[payload.itemId] and C.Items[payload.itemId].Slot) or "Weapon"
		if slot=="Weapon" then
			profile.Weapon=nil
			profile.Equipped.Weapon=nil
		elseif slot=="Gun" then
			profile.EquippedGun=nil
			profile.Equipped.Gun=nil
			if C.Guns and C.Guns[profile.Equipped.Offhand] then profile.Equipped.Offhand=nil end
		elseif slot=="Offhand" then
			profile.Equipped.Offhand=nil
			profile.Equipped.Necklace=nil
			if payload.itemId and payload.itemId==profile.EquippedGun then
				profile.EquippedGun=nil
				profile.Equipped.Gun=nil
			end
		elseif EQUIP_SLOT_ALIASES[slot] then
			for _,alias in ipairs(EQUIP_SLOT_ALIASES[slot]) do
				profile.Equipped[alias]=nil
			end
		else
			profile.Equipped[slot]=nil
		end
		G.Notify(p,"Đã tháo trang bị ("..slot..").")
	elseif act=="Equip" or act=="EquipSword" then
		local itemId=payload.itemId or payload.swordId
		local item=itemId and C.Items[itemId]
		if item and (profile.Inventory[itemId] or 0)>0 then
			-- Khong tin payload.slot: truoc day 1 vu khi deo duoc vao ca 8 o (Helmet/Ring/Artifact...) => cong ATK x8,
			-- va slot = chuoi tuy y lam phinh profile.Equipped (>3.5MB => khong luu duoc).
			local itemSlot=item.Slot or "Weapon"
			local slot=payload.slot or itemSlot
			if itemSlot=="Gun" or item.WeaponType=="Gun" then
				slot="Gun"
			elseif slot~=itemSlot and (EQUIP_SLOT_GROUP[slot]==nil or EQUIP_SLOT_GROUP[slot]~=EQUIP_SLOT_GROUP[itemSlot]) then
				slot=itemSlot
			end
			if slot~="Gun" and not EQUIP_SLOT_GROUP[slot] then return end
			if slot=="Weapon" then
				profile.Weapon=itemId
				profile.Equipped.Weapon=itemId
				profile.Loadouts=profile.Loadouts or {}
				profile.Loadouts[profile.ClassId]=itemId
			elseif slot=="Gun" or item.Slot=="Gun" or item.WeaponType=="Gun" then
				profile.EquippedGun=itemId
				profile.Equipped.Gun=itemId
				profile.Equipped.Offhand=itemId
				profile.Equipped.Necklace=itemId
			else
				if EQUIP_SLOT_ALIASES[slot] then
					for _,alias in ipairs(EQUIP_SLOT_ALIASES[slot]) do
						profile.Equipped[alias]=itemId
					end
				end
				profile.Equipped[slot]=itemId
				if slot=="Chest" then profile.Equipped.Armor=itemId end
			end
			G.Notify(p,"Đã trang bị "..item.Name.."!")
		end
	elseif act=="ForgeCraft" or act=="CraftWeapon" then
		local itemId=payload.itemId or payload.recipeId
		local item=itemId and C.Items[itemId]
		local recipe=itemId and (C.ForgeRecipes[itemId] or findRarityForgeRecipe(itemId,payload.recipeId))
		if not item then return end
		-- Truoc day item khong co cong thuc => mac dinh 300 Gold, 0 nguyen lieu: client goi ForgeCraft voi
		-- bat ky itemId nao (vu khi Mythic, SunshardCore/CoreEssence/upgrade_material...) deu nhan duoc.
		if not recipe then
			G.Notify(p,item.Name.." không có công thức rèn tại Lò Rèn!")
			return
		end
		if (tonumber(recipe.LevelReq) or 1)>(tonumber(profile.Level) or 1) then
			G.Notify(p,"Cần đạt Lv. "..tostring(recipe.LevelReq).." để chế tác "..item.Name.."!")
			return
		end
		local costShards=tonumber(recipe.CoreShards) or 0
		if costShards>0 and (profile.CoreShards or 0)<costShards then
			G.Notify(p,"Không đủ Core Shards để chế tác "..item.Name.." (Cần "..costShards..")!")
			return
		end
		if item.Slot~="Material" and item.Slot~="Quest" and (profile.Inventory[itemId] or 0)>0 then
			G.Notify(p,"Bạn đã sở hữu "..item.Name.."! Hãy dùng Cường Hóa (+1..+15) hoặc Nâng Sao (*1..*5).")
			return
		end
		local costGold=recipe and recipe.Gold or 300
		if (profile.Gold or 0)<costGold then
			G.Notify(p,"Không đủ Gold để chế tác "..item.Name.." (Cần "..costGold.." Gold)!")
			return
		end
		if recipe and recipe.Materials then
			for matId,reqCount in pairs(recipe.Materials) do
				if (profile.Inventory[matId] or 0)<reqCount then
					local matName=C.Items[matId] and C.Items[matId].Name or matId
					G.Notify(p,"Thiếu nguyên liệu: "..matName.." ("..(profile.Inventory[matId] or 0).."/"..reqCount..")!")
					return
				end
			end
			for matId,reqCount in pairs(recipe.Materials) do
				profile.Inventory[matId]=math.max(0,(profile.Inventory[matId] or 0)-reqCount)
			end
		end
		profile.Gold-=costGold
		if costShards>0 then profile.CoreShards-=costShards end
		profile.Inventory[itemId]=(profile.Inventory[itemId] or 0)+1
		if item.Slot=="Weapon" then
			if not item.ClassId or item.ClassId==profile.ClassId then
				profile.Weapon=itemId
				profile.Equipped.Weapon=itemId
				profile.Loadouts=profile.Loadouts or {}
				profile.Loadouts[profile.ClassId]=itemId
			else
				profile.Loadouts=profile.Loadouts or {}
				profile.Loadouts[item.ClassId]=itemId
			end
		elseif item.Slot=="Gun" then
			profile.EquippedGun=itemId
			profile.Equipped.Gun=itemId
		elseif item.Slot and item.Slot~="Material" and item.Slot~="Quest" then
			if EQUIP_SLOT_ALIASES[item.Slot] then
				for _,alias in ipairs(EQUIP_SLOT_ALIASES[item.Slot]) do
					profile.Equipped[alias]=nil
				end
			end
			profile.Equipped[item.Slot]=itemId
		end
		G.Notify(p,"Rèn thành công: "..item.Name.."!")
	elseif act=="ForgeEnhance" or act=="Upgrade" then
		if not Helpers.ExecuteForgeEnhance(p,profile,payload,G,C,LiveOps) then return end
	elseif act=="UpgradeSkill" then
		local skillId=payload.skillId
		if not skillId or not C.Actions[skillId] then return end
		local cur=profile.SkillLevels[skillId] or 1
		if cur>=5 then
			G.Notify(p,(C.SkillNames[skillId] or skillId).." đã đạt cấp tối đa (Lv. 5)!")
			return
		end
		if (profile.SkillPoints or 0)<1 then
			G.Notify(p,"Không đủ Điểm Kỹ Năng (Skill Points)!")
			return
		end
		profile.SkillPoints-=1
		profile.SkillLevels[skillId]=cur+1
		G.Notify(p,"Nâng cấp "..(C.SkillNames[skillId] or skillId).." lên Lv. "..profile.SkillLevels[skillId].."!")
	elseif act=="ResetSkills" then
		local refund=0
		for k,lv in pairs(profile.SkillLevels) do
			if type(lv)=="number" and lv>1 then
				refund+=(lv-1)
			end
			profile.SkillLevels[k]=1
		end
		profile.SkillPoints=(profile.SkillPoints or 0)+refund
		G.Notify(p,"Đã đặt lại Kỹ Năng! Hoàn trả "..refund.." Skill Points.")
	elseif act=="FastTravel" then
		local nodeId=payload.nodeId or payload.id
		local node=nodeId and ((C.FastTravel and C.FastTravel[nodeId]) or FALLBACK_FAST_TRAVEL[nodeId])
		if not node or not r then return end
		if inLockedEncounter(p) then
			G.Notify(p,"Không thể dịch chuyển khi đang trong giao tranh, Raid, Tháp hoặc Giao Dịch!")
			return
		end
		local okFT,canonIsl=Helpers.CheckIslandTeleportGate(p,profile,C,nodeId,G)
		if not okFT then return end
		local realm=node.Realm or "GoldenSky"
		profile.UnlockedWorlds=profile.UnlockedWorlds or {}
		profile.UnlockedWorlds[realm]=true
		if canonIsl then profile.DiscoveredIslands[canonIsl]=true end
		if type(nodeId)=="string" and not tonumber(nodeId) then profile.UnlockedWorlds[nodeId]=true end
		p:SetAttribute("CurrentRealm",realm)
		G.Teleport(p,node.Pos)
		G.Notify(p,"Dịch chuyển: "..node.Name)
	elseif act=="ClaimDaily" then
		if (profile.DailyClaimed or 0)>=7 then
			G.Notify(p,"Bạn đã nhận trọn bộ quà điểm danh 7 Ngày!")
			return
		end
		profile.DailyClaimed=math.min(7,(profile.DailyClaimed or 0)+1)
		profile.Gold=(profile.Gold or 0)+500
		profile.CoreShards=(profile.CoreShards or 0)+100
		profile.Inventory.SunshardCore=(profile.Inventory.SunshardCore or 0)+2
		profile.Potions=(profile.Potions or 0)+1
		G.Notify(p,"Nhận quà Ngày "..profile.DailyClaimed..": +500 Gold, +100 Core Shards, +2 Sunshard Core!")
	elseif act=="SetPartySize" then
		local req=tostring(payload.size or payload.partySize or "Solo")
		local lv=tonumber(profile.Level) or 1
		if req=="Duo" and lv<15 then
			profile.PartySize="Solo"
			G.SyncCompanions(p)
			G.Notify(p,"Cần đạt Cấp 15 để mở khóa Đồng Hành đầu tiên [Kairo • Vanguard]!")
		elseif (req=="Trio" or req=="Raid 4") and lv<30 then
			profile.PartySize=maxPartySizeForLevel(lv)
			G.SyncCompanions(p)
			G.Notify(p,"Cần đạt Cấp 30 để mở khóa Pháp Sư Trị Liệu [Lumen • Starweaver]!")
		elseif (req=="Squad" or req=="Raid 6") and lv<50 then
			profile.PartySize=maxPartySizeForLevel(lv)
			G.SyncCompanions(p)
			G.Notify(p,"Cần đạt Cấp 50 để mở khóa Sát Thủ Lôi Tốc [Nyx • Shadowblitz]!")
		else
			profile.PartySize=req
			G.SyncCompanions(p)
			G.Notify(p,"Đội hình Đồng Hành AI: "..profile.PartySize)
		end
	elseif act=="StartBossRush" then
		local bossId=tostring(payload.bossId or "CryonPrime")
		if not r then return end
		if not G.Rate(p,"BossRushStart",6) then
			G.Notify(p,"Boss Rush đang hồi, vui lòng chờ vài giây!")
			return
		end
		if inLockedEncounter(p) then
			LiveOps.Notify(G,p,"Không thể dịch chuyển Boss Rush khi đang Giao Tranh PvP, Giao Dịch, Đấu Trường, Raid hoặc Sky Spire!","Cannot Boss Rush teleport while in PvP combat, Trading, Colosseum, Raid, or Sky Spire!")
			return
		end
		local bossReqLvMap={
			PirateCaptainVance=300, SolarHighPriestBoss=550, AureonSentinel=560,
			OrderCyborgBoss=960, SkySeaBeast=1100, FrostSeaBeast=1100, CryonPrime=1240,
			SoulReaperRift=1750, AbyssalLeviathan=1750, Noxar=1980, AbyssalSovereignDragon=2150,
			Sylvaris=2200, Ignivar=2270, Nerith=2340, Aion=2410, Chronovex=2410, Veyr=2480, VeyrTheArchitect=2480,
		}
		local cfgBoss=C.Enemies and C.Enemies[bossId]
		local reqLv=bossReqLvMap[bossId] or (cfgBoss and math.max(1,math.floor((cfgBoss.Level or 1)*0.85))) or 560
		local pLv=profile.Level or 1
		if pLv<reqLv then
			G.Notify(p,string.format("Cần đạt Lv. %d để khiêu chiến Boss [%s]!",reqLv,bossId))
			return
		end
		profile.UnlockedWorlds=profile.UnlockedWorlds or {}
		profile.UnlockedWorlds.GoldenSky=true
		if pLv>=700 then profile.UnlockedWorlds.FrozenCyber=true end
		if pLv>=1500 then profile.UnlockedWorlds.ShadowRealm=true end
		if rt then rt.JumpPadUntil=math.max(rt.JumpPadUntil or 0,os.clock()+2.5) end
		local targetBoss=nil
		if bossId=="AureonSentinel" then
			p:SetAttribute("CurrentRealm","GoldenSky")
			if not G.Boss or not G.Boss.Alive then
				targetBoss=G.StartBoss({p})
			else
				targetBoss=G.Boss
				targetBoss.Party[p]=true
			end
			G.Teleport(p,_V3(0,50.5,-275))
		elseif bossId=="PirateCaptainVance" then
			p:SetAttribute("CurrentRealm","GoldenSky")
			for _,e in ipairs(G.Enemies) do
				if e.Id=="PirateCaptainVance" and e.Alive then targetBoss=e break end
			end
			if not targetBoss then
				targetBoss=G.SpawnEnemy("PirateCaptainVance",_V3(-2800,49.5,-95),true,false)
			end
			G.Teleport(p,_V3(-2800,50.5,-65))
		elseif bossId=="OrderCyborgBoss" then
			p:SetAttribute("CurrentRealm","FrozenCyber")
			for _,e in ipairs(G.Enemies) do
				if (e.Id=="OrderCyborgBoss" or e.Id=="OrderCyborg") and e.Alive then targetBoss=e break end
			end
			if not targetBoss then
				targetBoss=G.SpawnEnemy("OrderCyborgBoss",_V3(14600,50.5,1825),true,false)
			end
			G.Teleport(p,_V3(14600,50.9,1785))
		elseif bossId=="CryonPrime" then
			p:SetAttribute("CurrentRealm","FrozenCyber")
			for _,e in ipairs(G.Enemies) do
				if e.Id=="CryonPrime" and e.Alive then targetBoss=e break end
			end
			if not targetBoss then
				targetBoss=G.SpawnEnemy("CryonPrime",_V3(12000,50.5,-358.8),true,false)
			end
			G.Teleport(p,_V3(12000,50.9,-285))
		elseif bossId=="SoulReaperRift" then
			p:SetAttribute("CurrentRealm","ShadowRealm")
			for _,e in ipairs(G.Enemies) do
				if e.Id=="SoulReaperRift" and e.Alive then targetBoss=e break end
			end
			if not targetBoss then
				targetBoss=G.SpawnEnemy("SoulReaperRift",_V3(-14600,50.5,-1812),true,false)
			end
			G.Teleport(p,_V3(-14600,50.9,-1785))
		elseif bossId=="AbyssalLeviathan" or bossId=="SkySeaBeast" or bossId=="FrostSeaBeast" then
			local isLev=(bossId=="AbyssalLeviathan")
			p:SetAttribute("CurrentRealm",isLev and "ShadowRealm" or "FrozenCyber")
			local spawnPos=isLev and _V3(-12000,50.5,-3378) or _V3(14600,50.5,-1832)
			local spawnId=isLev and "AbyssalLeviathan" or "SkySeaBeast"
			for _,e in ipairs(G.Enemies) do
				if (e.Id==bossId or e.Id==spawnId) and e.Alive then targetBoss=e break end
			end
			if not targetBoss then
				targetBoss=G.SpawnEnemy(spawnId,spawnPos,true,false)
			end
			G.Teleport(p,spawnPos+_V3(0,2,25))
		elseif bossId=="Noxar" then
			p:SetAttribute("CurrentRealm","ShadowRealm")
			for _,e in ipairs(G.Enemies) do
				if e.Id=="Noxar" and e.Alive then targetBoss=e break end
			end
			if not targetBoss then
				targetBoss=G.SpawnEnemy("Noxar",_V3(-11672.2,50.8,-189.8),true,false)
			end
			G.Teleport(p,_V3(-11672.2,50.9,-150))
		else
			local expansionBossArenas={
				Sylvaris={Realm="VerdantCrown", MinRealmLv=2200, Spawn=_V3(22,170,-8995), PlayerPos=_V3(0,170.9,-8975)},
				Ignivar={Realm="EmberforgeWastes", MinRealmLv=2270, Spawn=_V3(12000,169.5,-9295), PlayerPos=_V3(12000,170.5,-9245)},
				Nerith={Realm="AbyssalTides", MinRealmLv=2340, Spawn=_V3(-11980,170,-8974), PlayerPos=_V3(-12000,170.9,-8962)},
				Aion={Realm="ChronosBastion", MinRealmLv=2410, Spawn=_V3(0,230,-13512), PlayerPos=_V3(0,230.9,-13480)},
				Chronovex={Realm="ChronosBastion", MinRealmLv=2410, Spawn=_V3(0,230,-13512), PlayerPos=_V3(0,230.9,-13480)},
				Veyr={Realm="VeilsEnd", MinRealmLv=2480, Spawn=_V3(0,310,-18295), PlayerPos=_V3(0,310.9,-18245)},
				VeyrTheArchitect={Realm="VeilsEnd", MinRealmLv=2480, Spawn=_V3(0,310,-18295), PlayerPos=_V3(0,310.9,-18245)},
				AbyssalSovereignDragon={Realm="ShadowRealm", MinRealmLv=1500, Spawn=_V3(-11635,50.8,-225), PlayerPos=_V3(-11655,50.9,-198)},
				SolarHighPriestBoss={Realm="GoldenSky", MinRealmLv=1, Spawn=_V3(2800,49.5,-475), PlayerPos=_V3(2800,50.5,-450)},
			}
			local bArena=expansionBossArenas[bossId]
			if bArena then
				if pLv>=(bArena.MinRealmLv or 2200) then
					profile.UnlockedWorlds[bArena.Realm]=true
				end
				p:SetAttribute("CurrentRealm",bArena.Realm)
				for _,e in ipairs(G.Enemies) do
					if e.Id==bossId and e.Alive then targetBoss=e break end
				end
				if not targetBoss then
					targetBoss=G.SpawnEnemy(bossId,bArena.Spawn,true,false)
				end
				G.Teleport(p,bArena.PlayerPos)
			else
				for _,e in ipairs(G.Enemies) do
					-- Chi Boss moi duoc Boss Rush toi (truoc day bossId = Id quai bat ky => dich chuyen toi moi quai/cõi)
					if e.Id==bossId and e.Alive and e.Body and (SINGLETON_BOSSES[e.Id] or (e.Config and e.Config.Boss)) then
						targetBoss=e
						G.Teleport(p,e.Body.Position+_V3(0,2,16))
						break
					end
				end
			end
		end
		local othersEngaged=false
		if targetBoss then
			for plr,hit in pairs(targetBoss.Contributors or {}) do
				if plr~=p and typeof(plr)=="Instance" and plr.Parent==Players and type(hit)=="table" and os.clock()-(tonumber(hit.Time) or 0)<45 then
					othersEngaged=true
					break
				end
			end
		end
		if targetBoss and othersEngaged then
			-- Khong hoi day mau Boss khi nguoi khac dang danh (truoc day spam StartBossRush => Boss bat tu)
			G.Notify(p,"BOSS RUSH: Đã tham chiến cùng đội đang đánh "..tostring(targetBoss.Config and targetBoss.Config.Name or targetBoss.Id).."!")
		elseif targetBoss then
			cleanupBossMinions(targetBoss)
			local baseHP=C.Enemies[targetBoss.Id] and C.Enemies[targetBoss.Id].HP or targetBoss.MaxHP
			targetBoss.MaxHP=math.floor(baseHP*1.5)
			targetBoss.HP=targetBoss.MaxHP
			targetBoss.Break=0
			targetBoss.Phase=1
			targetBoss.Shield=false
			targetBoss.TwinSolarPylonsSpawned=false
			targetBoss.SolarAegis70=false
			targetBoss.CryonShieldActive=false
			targetBoss.Phase2Triggered=false
			targetBoss.Phase3Triggered=false
			if targetBoss.Model then
				targetBoss.Model:SetAttribute("BossPhase",1)
				targetBoss.Model:SetAttribute("EnemyAttackClip","UltimateAwakening")
				targetBoss.Model:SetAttribute("EnemyAttackAt",workspace:GetServerTimeNow())
			end
			G.Notify(p,"ABYSSAL REMATCH: "..targetBoss.Config.Name)
		end
	elseif act=="TriggerKataPose" then
		local clipName=tostring(payload.clip or "UltimateAwakening")
		if clipName~="HeroicKata" and clipName~="ElementalSurge" and clipName~="UltimateAwakening" then
			clipName="UltimateAwakening"
		end
		if r then
			R.CombatFX:FireAllClients({
				Kind="PoseKata",
				Position=r.Position,
				Actor=p.UserId,
				Action=clipName,
				Clip=clipName,
			})
		end
		G.Notify(p,"3D MOTION KATA: Đang thi triển bộ chuyển động 12-Keyframe ["..clipName.."]!")
	elseif act=="UsePotion" then
		local now=os.clock()
		if now<(rt.Cooldowns.Potion or 0) then
			G.Notify(p,"Bình Hồi Phục đang hồi ("..math.ceil(rt.Cooldowns.Potion-now).."s)!")
			return
		end
		if (profile.Potions or 0)<=0 then
			G.Notify(p,"Đã hết Bình Hồi Phục!")
			return
		end
		if not h or not r then return end
		profile.Potions-=1
		rt.Cooldowns.Potion=now+6
		local heal=math.max(60,math.floor(h.MaxHealth*0.4))
		h.Health=math.min(h.MaxHealth,h.Health+heal)
		G.FireCombatEvent({
			kind="DamageNumber",
			pos=r.Position+_V3(0,2,0),
			amount=heal,
			crit=false,
			breakDmg=0,
			element="Heal",
			Text="+"..tostring(heal).." HP",
		})
		G.Notify(p,"Đã dùng Bình Hồi Phục (+"..heal.." HP)!")
	elseif act=="ClaimQuestReward" or act=="AcceptQuest" then
		if profile.LastCompletedQuest then
			local cid=profile.LastCompletedQuest
			profile.LastCompletedQuest=nil
			profile.Gold=(profile.Gold or 0)+200
			profile.CoreShards=(profile.CoreShards or 0)+50
			profile.Potions=(profile.Potions or 0)+1
			G.Notify(p,"Nhận thưởng nhiệm vụ "..cid..": +200 Gold, +50 Core Shards, +1 Potion!")
		end
		local q=C.Quests[profile.QuestIndex]
		if q and not profile.Accepted then
			profile.Accepted=true
			G.Notify(p,"Đã nhận nhiệm vụ "..q.Id..": "..q.Name)
		end
	elseif act=="SelectSlot" then
		profile.ActiveSlot=math.clamp(tonumber(payload.slot) or 1,1,4)
		if payload.clearHeldFruit then
			profile.HeldFruit=""
			if rt then rt.HeldAlreadyStored=false end
		end
	elseif act=="HoldFruit" then
		local rawFid=tostring(payload.fruitId or profile.HeldFruit or profile.EquippedFruit or "")
		local fid=(D.NormalizeFruitId and D.NormalizeFruitId(rawFid)) or rawFid
		if fid=="" then return end
		if profile.HeldFruit==fid and not payload.forceHold then
			profile.HeldFruit=""
			if rt then rt.HeldAlreadyStored=false end
			G.Notify(p,"Đã cất Lõi Aether 3D vào túi.")
		else
			local owned=(tonumber(profile.StoredFruits and profile.StoredFruits[fid]) or 0)>0 or profile.EquippedFruit==fid
			if not owned then
				if payload.showcasePreview then return end
				local fcfg=getFruitCfg(fid)
				G.Notify(p,"Bạn chưa sở hữu ["..(fcfg and fcfg.Name or fid).."] trong kho để cầm trên tay!")
				return
			end
			profile.HeldFruit=fid
			if rt then rt.HeldAlreadyStored=true end
			local fcfg=getFruitCfg(fid)
			G.Notify(p,"Đang cầm mô hình 3D ["..(fcfg and fcfg.Name or fid).."] trên tay!")
		end
	elseif act=="StoreFruit" then
		if profile._ReadOnlyFallback==true or p:GetAttribute("InTrade")==true then
			G.Notify(p,"Không thể cất Lõi Aether khi đang Giao Dịch hoặc ở chế độ Bảo Vệ Dữ Liệu!")
			return
		end
		local rawHeld=tostring(profile.HeldFruit or "")
		local canonId=(D.NormalizeFruitId and D.NormalizeFruitId(rawHeld)) or rawHeld
		if canonId=="" then
			G.Notify(p,"Bạn hiện không cầm Lõi Aether nào trên tay để cất vào Kho!")
			return
		end
		profile.StoredFruits=type(profile.StoredFruits)=="table" and profile.StoredFruits or {}
		local maxCap=Helpers.GetMaxCoreStorage(p,profile)
		local curStored=tonumber(profile.StoredFruits[canonId]) or 0
		if not (rt and rt.HeldAlreadyStored==true) then
			if curStored>=maxCap then
				local fcfgFull=getFruitCfg(canonId)
				G.Notify(p,string.format("Kho Lõi [%s] đã đầy (%d/%d)! Mở rộng Kho Lõi (+3 Ô) tại tab Đặc Quyền Robux [N]!",fcfgFull and fcfgFull.Name or canonId,curStored,maxCap))
				return
			end
			profile.StoredFruits[canonId]=curStored+1
		end
		if rt then rt.HeldAlreadyStored=false end
		profile.HeldFruit=""
		p:SetAttribute("HeldFruit","")
		if p.Character then p.Character:SetAttribute("HeldFruit","") end
		local fcfg=getFruitCfg(canonId)
		task.spawn(D.Save,p,false)
		G.Notify(p,"Đã cất Lõi Aether ["..(fcfg and fcfg.Name or canonId).."] vào Kho Lưu Trữ!")
	elseif act=="RollFruit" then
		Helpers.ExecuteRollFruit(p,profile,rt,G,C,payload.currency)
		return
	elseif act=="SelectClass" then
		G.ChooseAppearance(p,{ClassId=payload.classId or payload.id})
		return
	elseif act=="EvolveRace" then
		Helpers.EvolveRace(p,profile,G,C)
		return
	elseif act=="EatFruit" then
		if p:GetAttribute("InTrade")==true then
			G.Notify(p,"Không thể hấp thụ Lõi Aether khi đang ngồi Bàn Giao Dịch!")
			return
		end
		local rawFid=tostring(payload.fruitId or (profile.HeldFruit~="" and profile.HeldFruit) or profile.EquippedFruit or "")
		local fid=(D.NormalizeFruitId and D.NormalizeFruitId(rawFid)) or rawFid
		if fid=="" then
			G.Notify(p,"Hãy chọn một Lõi Aether hợp lệ để hấp thụ!")
			return
		end
		local fruit=getFruitCfg(fid)
		local storedCnt=tonumber(profile.StoredFruits and profile.StoredFruits[fid]) or 0
		local heldCanon=(D.NormalizeFruitId and D.NormalizeFruitId(profile.HeldFruit or "")) or tostring(profile.HeldFruit or "")
		if profile.EquippedFruit~=fid then
			if storedCnt>0 then
				profile.StoredFruits[fid]=storedCnt-1
				if profile.StoredFruits[fid]<=0 then
					profile.StoredFruits[fid]=nil
				end
			elseif heldCanon==fid and not (rt and rt.HeldAlreadyStored==true) then
				-- Consuming unstored fruit directly from hand
			else
				G.Notify(p,"Bạn chưa có ["..(fruit and fruit.Name or fid).."] trong kho! Hãy cầu lõi tại Hiền Giả Lõi, mua tại Thương Nhân Hư Quang hoặc nhặt Lõi Tự Nhiên.")
				return
			end
		end
		profile.EquippedFruit=fid
		profile.ActiveSlot=2
		if heldCanon==fid then
			profile.HeldFruit=""
			if rt then rt.HeldAlreadyStored=false end
		end
		if p.Character then p.Character:SetAttribute("FruitTransform","") end
		p:SetAttribute("DragonFormTier",0)
		if p.Character then p.Character:SetAttribute("DragonFormTier",0) end
		G.Notify(p,"Đã hấp thụ & trang bị "..(fruit and fruit.Name or fid).."! Bấm [2] và dùng chiêu [Z][X][C][V][F]!")
	elseif act=="AwakenFruit" then
		local rawFid=tostring(payload.fruitId or profile.EquippedFruit or "SolarTitanCore")
		local fid=Helpers.ResolveFruitId(rawFid)~="" and Helpers.ResolveFruitId(rawFid) or rawFid
		local fruit=getFruitCfg(fid)
		if not profile.AwakenedFruits[fid] then
			if not Helpers.CanAwakenFruit(p,profile,fid,G) then
				return
			end
			profile.CoreShards-=1000
			profile.AwakenedFruits[fid]=true
		end
		G.Notify(p,"THỨC TỈNH V2: Đã mở khóa kỹ năng Awakened V2 (+25% Sát Thương, +20% Tầm Đánh) cho "..(fruit and fruit.Name or fid).."!")
	elseif act=="SwitchFightingStyle" then
		local sid=tostring(payload.styleId or "SkybornCombat")
		if G.CombatExpansion and G.CombatExpansion.SelectOrLearnStyle then
			G.CombatExpansion.SelectOrLearnStyle(p,sid)
			return
		end
		local req=Helpers.GetMartialReq(sid)
		local style=getStyleCfg(sid)
		if req and not profile.UnlockedStyles[req.Id] and not profile.UnlockedStyles[req.Alias] and req.Id~="skyborn_combat" then
			if (tonumber(profile.Level) or 1)<req.MinLevel then
				G.Notify(p,string.format("Cần đạt Lv. %d để lĩnh ngộ [%s]!",req.MinLevel,req.Name))
				return
			end
			local bestMas=Helpers.GetBestMartialMastery(profile)
			if req.ReqMastery>0 and bestMas<req.ReqMastery then
				G.Notify(p,string.format("Cần đạt Mastery Quyền Pháp %d+ (hiện tại %d) để lĩnh ngộ [%s]!",req.ReqMastery,bestMas,req.Name))
				return
			end
			if (profile.Gold or 0)<req.Gold or (profile.CoreShards or 0)<req.Shards then
				G.Notify(p,string.format("Cần %d Gold & %d Core Shards để lĩnh ngộ [%s]!",req.Gold,req.Shards,req.Name))
				return
			end
			profile.Gold-=req.Gold
			profile.CoreShards-=req.Shards
			profile.UnlockedStyles[req.Id]=true
			profile.UnlockedStyles[req.Alias]=true
		end
		profile.FightingStyle=sid
		profile.UnlockedStyles[sid]=true
		G.Notify(p,"Đã chuyển sang bộ võ: "..(style and style.Name or sid))
	elseif act=="EquipGun" then
		local gid=tostring(payload.gunId or "sylvaris_thornbow")
		local gun=getGunCfg(gid)
		if (tonumber(profile.Inventory and profile.Inventory[gid]) or 0)<=0 then
			G.Notify(p,"Bạn chưa sở hữu Pháp Khí ["..(gun and gun.Name or gid).."] trong túi đồ!")
			return
		end
		profile.EquippedGun=gid
		profile.Equipped.Gun=gid
		profile.Equipped.Offhand=gid
		profile.Equipped.Necklace=gid
		G.Notify(p,"Đã trang bị Pháp Khí: "..(gun and gun.Name or gid))
	elseif act=="AddStat" then
		local stat=tostring(payload.stat or "Melee")
		if profile.StatAlloc[stat]~=nil then
			local maxSt=C.MaxStat or 2550
			local curVal=math.clamp(math.floor(tonumber(profile.StatAlloc[stat]) or 1),1,maxSt)
			if curVal>=maxSt then
				G.Notify(p,"Chỉ số ["..stat.."] đã đạt giới hạn tối đa (MAX "..tostring(maxSt)..")!")
			else
				local room=maxSt-curVal
				local amt=math.clamp(math.floor(tonumber(payload.amount) or 1),1,room)
				local avail=profile.StatPoints or 0
				local use=avail>0 and math.min(avail,amt) or 0
				if use>0 then
					profile.StatPoints=avail-use
					profile.StatAlloc[stat]=curVal+use
					G.Notify(p,"+"..tostring(use).." Điểm vào ["..stat.."] -> Lv. "..tostring(profile.StatAlloc[stat]).." / "..tostring(maxSt).."!")
				else
					G.Notify(p,"Không đủ Điểm Chỉ Số (Stat Points)! Hãy lên cấp hoặc bấm Đột Phá Cấp Độ để nhận thêm +3 điểm/cấp.")
				end
			end
		end
	elseif act=="BoostLevel" then
		if not DevGate.IsAllowed(p) then
			G.Notify(p,"Tính năng Đột Phá Cấp Nhanh chỉ mở trong chế độ Studio / Dev Sandbox!")
			return
		end
		local maxLv=C.MaxLevel or 2550
		local prevLv=profile.Level or 1
		local targetLv=tonumber(payload.targetLevel) or (prevLv+(tonumber(payload.addLevels) or 100))
		targetLv=math.clamp(math.floor(targetLv),1,maxLv)
		if targetLv<=prevLv and targetLv<maxLv then
			targetLv=math.min(maxLv,prevLv+100)
		end
		profile.Level=targetLv
		profile.XP=0
		ensureProfileFields(profile)
		G.SyncCompanions(p)
		G.Notify(p,"ĐỘT PHÁ CẤP ĐỘ SKYBREAK: Đạt Lv. "..tostring(profile.Level).." / "..tostring(maxLv).." (Còn "..tostring(profile.StatPoints).." Stat Points)!")
	elseif act=="RefundStats" then
		if not Helpers.ExecuteRefundStats(p,profile,ensureProfileFields,G,C,LiveOps) then return end
	elseif act=="ToggleAura" then
		profile.Haki.Aura=not profile.Haki.Aura
		p:SetAttribute("HakiAura",profile.Haki.Aura)
		if p.Character then p.Character:SetAttribute("HakiAura",profile.Haki.Aura) end
		local stg=tonumber(profile.HakiStage) or 0
		local stInfo=G.CombatData and G.CombatData.HakiStages and G.CombatData.HakiStages[stg]
		local bonusTxt=stInfo and string.format("%s (+%d%% ATK, +%d%% DEF)",stInfo.Name,math.floor(stInfo.AtkBonus*100),math.floor(stInfo.DefBonus*100)) or "+20% ATK, +15% DEF"
		if profile.Haki.Aura and r then
			R.CombatFX:FireAllClients({Kind="HakiStageUp",Action="HakiStageUp",Stage=math.max(1,stg),Position=r.Position,Actor=p.UserId})
		end
		G.Notify(p,"Giáp Ý Chí (Will Armor): "..(profile.Haki.Aura and ("BẬT — "..bonusTxt) or "TẮT"))
	elseif act=="ToggleInstinct" then
		profile.Haki.Instinct=not profile.Haki.Instinct
		local dodges=math.clamp(tonumber(profile.Haki.InstinctDodges) or 8,0,8)
		profile.Haki.InstinctDodges=dodges
		local kenV2=(profile.Haki.Instinct==true and profile.KenV2Unlocked==true)
		p:SetAttribute("HakiInstinct",profile.Haki.Instinct)
		p:SetAttribute("InstinctDodges",dodges)
		p:SetAttribute("KenV2Active",kenV2)
		if p.Character then
			p.Character:SetAttribute("HakiInstinct",profile.Haki.Instinct)
			p.Character:SetAttribute("InstinctDodges",dodges)
			p.Character:SetAttribute("KenV2Active",kenV2)
		end
		if profile.Haki.Instinct and r then
			R.CombatFX:FireAllClients({Kind="InstinctDodge",Action="InstinctToggle",Position=r.Position,DodgesLeft=dodges,MaxDodges=8,Actor=p.UserId})
		end
		G.Notify(p,"Thấu Ý (Will Sense"..(profile.KenV2Unlocked and " V2" or "").."): "..(profile.Haki.Instinct and string.format("BẬT (%d/8 Né)",dodges) or "TẮT"))
	elseif act=="ConquerorBurst" then
		Helpers.CheckAndAutoUnlockConqueror(p,profile,G,nil)
		if not (profile.Haki and profile.Haki.ConquerorUnlocked==true) then
			G.Notify(p,"Bạn cần hạ gục Boss chính (Aureon / Cryon Prime / Noxar) hoặc đạt Giáp Ý Chí Cấp 3 & Lv. 700+ để mở khóa Bá Ý [H]!")
			return
		end
		if r and rt then
			local now=os.clock()
			local rem=(rt.Cooldowns.ConquerorBurst or 0)-now
			if rem>0 then
				G.Notify(p,string.format("Bá Ý đang hồi chiêu (%.1fs)!",rem))
				return
			end
			local maxE=tonumber(rt.MaxEnergy) or 100
			if (rt.Energy or maxE)<20 then
				G.Notify(p,"Cần 20 Aether Energy để phát động Bá Ý!")
				return
			end
			rt.Cooldowns.ConquerorBurst=now+18
			rt.Cooldowns.ConquerorHaki=now+18
			rt.Energy=math.max(0,(rt.Energy or maxE)-20)
			rt.LastCastAt=now
			local stats=G.Stats(p)
			local dmg=((stats and stats.ATK) or 50)*3.5
			for _,e in ipairs(G.Enemies) do
				if e.Alive and e.Model and e.Model.Parent and e.Body and distance(r.Position,e.Body.Position)<=38 then
					if not e.Config.Boss and e~=G.Boss and not SINGLETON_BOSSES[e.Id] and not e.BossOwner then
						e.StunnedUntil=math.max(e.StunnedUntil or 0,now+4)
					end
					G.Hit(p,e,dmg,45,"ConquerorHaki")
				end
			end
			G.FireCombatEvent({
				kind="SkillVFX",
				skillId="ConquerorHaki",
				element="Void",
				pos=r.Position,
				look=r.CFrame.LookVector,
				userId=p.UserId,
			})
			R.CombatFX:FireAllClients({Kind="Skill",Position=r.Position,Actor=p.UserId,Action="ConquerorHaki"})
			G.Notify(p,"BÁ Ý (SOVEREIGN WILL): Chấn động không gian (Choáng 4s, Hồi chiêu 18s)!")
		end
	elseif act=="ActivateRaceV4" then
		if rt then
			local now=os.clock()
			if now<(rt.Cooldowns.RaceV4Toggle or 0) then return end
			rt.Cooldowns.RaceV4Toggle=now+1.2
		end
		if not profile.RaceV4Active then
			if profile.RaceV4Unlocked~=true then
				G.Notify(p,"Bạn cần hoàn thành Khảo Thí Đền Thăng Hoa (Sea 3 • Lv. 1900+) để mở khóa Tộc V4!")
				return
			end
			local curMeter=tonumber((rt and rt.AwakeningMeter) or profile.AwakeningMeter) or 0
			if curMeter<100 then
				G.Notify(p,string.format("Thanh Nộ Thăng Hoa chưa đầy (%d/100)! Hãy chiến đấu tích nộ để kích hoạt Tộc V4 [Y]!",math.floor(curMeter)))
				return
			end
			if rt then rt.AwakeningMeter=0 end
			profile.AwakeningMeter=0
		end
		local prevPct=(h and h.MaxHealth>0) and math.clamp(h.Health/h.MaxHealth,0.01,1) or 1
		profile.RaceV4Active=not profile.RaceV4Active
		local raceName=profile.Race or "Skyborn"
		p:SetAttribute("RaceV4Active",profile.RaceV4Active)
		p:SetAttribute("RaceV4",profile.RaceV4Active and raceName or "")
		if p.Character then
			p.Character:SetAttribute("RaceV4Active",profile.RaceV4Active)
			p.Character:SetAttribute("RaceV4",profile.RaceV4Active and raceName or "")
		end
		if h and h.Health>0 then
			local s=G.Stats(p)
			if s then
				h.MaxHealth=s.HP
				if profile.RaceV4Active then
					h.Health=math.min(s.HP,math.max(h.Health,math.floor(s.HP*math.max(prevPct,0.55))))
				else
					h.Health=math.clamp(math.floor(s.HP*prevPct),1,s.HP)
				end
			end
		end
		if profile.RaceV4Active then
			if r then
				R.CombatFX:FireAllClients({Kind="RaceV4Unlock",Position=r.Position,Actor=p.UserId,Action="RaceV4Awaken",Race=raceName})
			end
			G.Notify(p,"THĂNG HOA HUYẾT MẠCH ["..raceName.."]: Toàn bộ chỉ số +30%!")
		else
			if rt then rt.LeviathanShieldHP=0 end
			p:SetAttribute("LeviathanShieldHP",0)
			if p.Character then p.Character:SetAttribute("LeviathanShieldHP",0) end
			G.Notify(p,"Đã thu hồi trạng thái Thăng Hoa ["..raceName.."].")
		end
	elseif act=="RerollRace" then
		if G.CombatExpansion and type(G.CombatExpansion.RerollRace)=="function" then
			G.CombatExpansion.RerollRace(p)
			return
		end
		local rrCost=tonumber(C.RaceRerollCostShards) or 50
		if (profile.CoreShards or 0)<rrCost then
			G.Notify(p,"Cần "..tostring(rrCost).." Core Shards để đổi Chủng Tộc mới!")
			return
		end
		profile.CoreShards-=rrCost
		local curIdx=1
		for i,rname in ipairs(RACE_ORDER) do
			if rname==profile.Race then curIdx=i break end
		end
		profile.Race=RACE_ORDER[(curIdx%#RACE_ORDER)+1]
		if p.Character and profile.RaceV4Active then
			p.Character:SetAttribute("RaceV4",profile.Race)
		end
		G.Notify(p,"Đã thức tỉnh dòng máu mới: Chủng tộc "..profile.Race.."!")
	elseif act=="SetFaction" then
		profile.Faction=(payload.faction=="Marine") and "Marine" or "Pirate"
		G.Notify(p,"Đã chọn phe: "..(profile.Faction=="Marine" and "Hải Quân Thiên Không (Sky Marines)" or "Hải Tặc Bầu Trời (Sky Pirates)").."!")
	elseif act=="SpawnSkyShip" then
		if r then
			G.BuildSkyShip(p,payload.dockPos or (r.Position+r.CFrame.LookVector*14),payload.shipId)
			G.Notify(p,"Đã triệu hồi Chiến Hạm Bay 3D (Sky Ship)!")
		end
	elseif act=="StartAwakeningRaid" or act=="StartMicrochipRaid" then
		if G.WorldEvents and G.WorldEvents.StartMicrochipRaid then
			G.WorldEvents.StartMicrochipRaid(p,payload.difficulty)
		end
	elseif act=="SpawnSeaEvent" or act=="SummonLeviathan" then
		if r and DevGate.IsAllowed(p) then
			local seaId=(act=="SummonLeviathan" or payload.bossId=="AbyssalLeviathan") and "AbyssalLeviathan"
				or ((payload.bossId=="SkySeaBeast") and "SkySeaBeast" or ((math.random()<0.5) and "SkySeaBeast" or "AbyssalLeviathan"))
			G.SpawnEnemy(seaId,r.Position+_V3(0,2,-26),false,true)
			G.Notify(p,"SỰ KIỆN BIỂN MÂY: "..(seaId=="AbyssalLeviathan" and "Thủy Xà Vực Thẳm ABYSS SERPENT" or "Thú Trời SKY BEAST").." đã trồi lên từ biển mây!")
		end
	end
	if h and h.Health>0 then
		local s=G.Stats(p)
		if s then
			local ratio=h.Health/math.max(1,h.MaxHealth)
			h.MaxHealth=s.HP
			h.Health=math.clamp(math.floor(s.HP*ratio),1,s.HP)
		end
	end
	local blade=p.Character and p.Character:FindFirstChild("SkybornBlade") if blade then blade.Transparency=1 end
	if p.Character then Cosmetics.Equip(p.Character,profile.Weapon~=nil) end
	G.Sync(p)
end
function G.ChooseAppearance(p,payload)
	if not G.Rate(p,'Appearance',.2)then return end
	if type(payload)=='string'then payload={Gender=payload}end
	if type(payload)~='table'then return end
	local profile=D.Get(p);local rt=G.Runtime[p];local r,h=root(p)
	if not profile or not rt or not r or not h then return end
	local class=payload.ClassId or profile.ClassId;local gender=payload.Gender or profile.Gender or'Male'
	if not C.Classes[class]or(gender~='Male'and gender~='Female')then return end
	if G.Boss and G.Boss.Party[p] then G.Notify(p,'Không thể đổi nhân vật khi đang đánh Boss Aureon!')return end
	local hp=h.Health/math.max(1,h.MaxHealth)
	profile.Loadouts=profile.Loadouts or{}
	profile.Equipped=profile.Equipped or{}
	if class~=profile.ClassId then
		if profile.Weapon then
			profile.Loadouts[profile.ClassId]=profile.Weapon
		end
		local weapon=profile.Loadouts[class]
		if not weapon or (profile.Inventory[weapon] or 0)<=0 then
			weapon=C.ClassWeapons[class]
			profile.Inventory[weapon]=math.max(1,profile.Inventory[weapon]or 0)
		end
		profile.Weapon=weapon
		profile.Equipped.Weapon=weapon
	end
	profile.ClassId=class;profile.Gender=gender;profile.ClassChosen=true
	local st=G.Stats(p)
	h.MaxHealth=st.HP;h.Health=math.max(1,h.MaxHealth*hp);h.WalkSpeed=(C.Classes[class].Speed or 16)*(st.RaceWalkSpeedMult or 1)
	local blade=p.Character and p.Character:FindFirstChild("SkybornBlade") if blade then blade.Transparency=1 end
	if p.Character then Cosmetics.Equip(p.Character,profile.Weapon~=nil) end
	G.Notify(p,"Đã chọn: "..C.Classes[class].Name.." • "..(gender=="Female" and "Nữ" or "Nam"))
	G.Sync(p)
end
G.Appearance=G.ChooseAppearance
local function setEnemyMoving(e,isMoving)
	if e.LastMoving~=isMoving then
		e.LastMoving=isMoving
		if e.Model and e.Model.Parent then
			e.Model:SetAttribute("EnemyMoving",isMoving)
		end
	end
end
local function move(e,destination,dt,speedOverride)
	local spd=speedOverride or e.Config.Speed or 0
	if spd<=0 or not e.Body or not e.Model then setEnemyMoving(e,false) return false end
	local isSeaSwimmer=e.IsSeaEventMonster or e.Id=="AbyssalLeviathan" or e.Id=="SkySeaBeast" or e.Id=="TerrorSkyShark"
	local cf=Helpers.ComputeSafeEnemyTransform(e,destination,spd,dt,G.Enemies,isSeaSwimmer and {IsBlockedByObstacle=W.IsBlockedByObstacle} or W)
	if not cf then setEnemyMoving(e,false) return false end
	e.Model:PivotTo(cf)
	local fy=cf.Position.Y-math.max(2.2,e.Body.Size.Y*0.5)
	if e.LastAttrFloorY~=fy then
		e.LastAttrFloorY=fy
		e.Model:SetAttribute('EnemyFloorY',fy)
	end
	setEnemyMoving(e,true)
	return true
end
function G.TickEnemy(e,dt)
	if not e.Alive or not e.Model.Parent then return end
	local now=os.clock()
	if e~=G.Boss and (SINGLETON_BOSSES[e.Id] or e.Config.Boss) then
		local nextPhase=(e.HP>e.MaxHP*0.70) and 1 or ((e.HP>e.MaxHP*0.35) and 2 or 3)
		if e.Shield and nextPhase>2 then nextPhase=2 end
		e.Phase=nextPhase
	end
	if e.LastBossPhase~=e.Phase then
		e.LastBossPhase=e.Phase
		e.Model:SetAttribute("BossPhase",e.Phase)
	end
	if W.UpdateEnemyBar then
		W.UpdateEnemyBar(e)
	else
		local lvTag=e.Config.Level and (" [Lv."..tostring(e.Config.Level).."]") or ""
		local nextLabel=e.Config.Name..lvTag.." • "..math.ceil(e.HP).." / "..e.MaxHP
		if e.LastLabelText~=nextLabel then
			e.LastLabelText=nextLabel
			e.Label.Text=nextLabel
		end
	end
	if e.Id=="EnergyPylon" or e.Id=="CryonPillar" or e.Id=="NoxarVoidFX" then return end

	if e.Id=="CryonPrime" then
		if e.Phase>=2 and not e.Phase2Triggered then
			e.Phase2Triggered=true
			e.Shield=true
			e.Model:SetAttribute("EnemyAttackClip","UltimateAwakening")
			e.Model:SetAttribute("EnemyAttackDuration",1.6)
			e.Model:SetAttribute("EnemyAttackAt",workspace:GetServerTimeNow())
			e.Model:SetAttribute("CryonSummonAt",workspace:GetServerTimeNow())
			local pillarCoords={
				_V3(11984,49.9,-348),
				_V3(12016,49.9,-348),
				_V3(12000,49.9,-374),
			}
			for _,ppos in ipairs(pillarCoords) do
				local pil=G.SpawnEnemy("CryonPillar",ppos,false,true)
				if pil then pil.BossOwner=e end
			end
			for _,plr in ipairs(Players:GetPlayers()) do
				local pr=root(plr)
				if pr and distance(pr.Position,e.Body.Position)<95 then
					G.Notify(plr," CRYON PRIME bật Khiên Băng! Hãy phá 3 Cột Băng Vĩnh Cửu!")
				end
			end
		end
		if e.Shield then
			local alivePillars=0
			for _,other in ipairs(G.Enemies) do
				if other.Id=="CryonPillar" and other.Alive and (other.BossOwner==e or other.BossOwner==nil) then alivePillars+=1 end
			end
			if alivePillars==0 then
				e.Shield=false
				e.StunnedUntil=now+5
				e.ImmuneUntil=now+11
				for _,plr in ipairs(Players:GetPlayers()) do
					local pr=root(plr)
					if pr and distance(pr.Position,e.Body.Position)<95 then
						G.Notify(plr,"Các cột băng đã vỡ! Cryon Prime bị choáng!")
					end
				end
			end
		end
	elseif e.Id=="Noxar" then
		if e.Phase>=2 and not e.Phase2Triggered then
			e.Phase2Triggered=true
			e.Shield=true
			e.Model:SetAttribute("EnemyAttackClip","UltimateAwakening")
			e.Model:SetAttribute("EnemyAttackDuration",1.8)
			e.Model:SetAttribute("EnemyAttackAt",workspace:GetServerTimeNow())
			local vfx=G.SpawnEnemy("NoxarVoidFX",_V3(-11672.2,50.8,-176),false,true)
			if vfx then vfx.BossOwner=e end
			G.SpawnEnemy("VoidPirate",_V3(-11684,50.8,-178),false,true)
			for _,plr in ipairs(Players:GetPlayers()) do
				local pr=root(plr)
				if pr and distance(pr.Position,e.Body.Position)<95 then
					G.Notify(plr," NOXAR triệu hồi Void Singularity! Phá hủy nó để phá khiên!")
				end
			end
		end
		if e.Shield then
			local aliveVoid=0
			for _,other in ipairs(G.Enemies) do
				if other.Id=="NoxarVoidFX" and other.Alive and (other.BossOwner==e or other.BossOwner==nil) then aliveVoid+=1 end
			end
			if aliveVoid==0 then
				e.Shield=false
				e.StunnedUntil=now+5
				e.ImmuneUntil=now+11
				for _,plr in ipairs(Players:GetPlayers()) do
					local pr=root(plr)
					if pr and distance(pr.Position,e.Body.Position)<95 then
						G.Notify(plr,"Void Singularity đã bị phá hủy! Noxar bị choáng 5 giây!")
					end
				end
			end
		end
	end

	if e==G.Boss then
		local active=false for p in pairs(e.Party) do if inArena(p) and D.Get(p) then active=true break end end
		if not active then
			e.EmptySince=e.EmptySince or now
			if now-e.EmptySince>8 then
				e.Alive=false e.Model:Destroy() G.Boss=nil G.ResetAt=now+8
				cleanupEnemyTelegraphs(e)
				cleanupBossMinions(e)
			end
			return
		else e.EmptySince=nil end
	end
	if (e==G.Boss or e.Id=="AureonSentinel") and e.Shield then
		local remaining=0 for _,pillar in ipairs(G.Enemies) do if pillar.BossOwner==e and pillar.Alive then remaining+=1 end end
		if remaining==0 then
			e.Shield=false
			e.SolarAegis70=false
			if e.Model then e.Model:SetAttribute("Shielded",false) end
			e.StunnedUntil=math.max(e.StunnedUntil or 0,now+3)
			e.ImmuneUntil=math.max(e.ImmuneUntil or 0,now+9)
		end
	end
	if now<e.StunnedUntil then e.State="Stunned" setEnemyMoving(e,false) return end
	if distance(e.Body.Position,e.Home)>e.Config.Leash then e.Returning=true end
	if e.Returning then
		e.State="ReturnToSpawn"
		local moved=move(e,e.Home,dt)
		e.ReturnTotalTimer=(e.ReturnTotalTimer or 0)+(dt or 0.04)
		e.ReturnStuckTimer=moved and 0 or ((e.ReturnStuckTimer or 0)+(dt or 0.04))
		if distance(e.Body.Position,e.Home)<2 or e.ReturnStuckTimer>=1.5 or e.ReturnTotalTimer>=7.5 then
			if distance(e.Body.Position,e.Home)>=2 and e.Model then
				e.Model:PivotTo(_CF(e.Home))
				e.CachedGroundY=nil
			end
			e.Returning=false e.ReturnStuckTimer=0 e.ReturnTotalTimer=0
			e.HP=e.MaxHP e.Contributors={}
			if e~=G.Boss and (SINGLETON_BOSSES[e.Id] or e.Config.Boss) then
				e.Phase=1 e.Shield=false e.Phase2Triggered=false e.Phase3Triggered=false
				cleanupBossMinions(e)
			end
			setEnemyMoving(e,false)
		end
		return
	end
	local aggroRange=e.Config.Aggro or e.Config.Leash or 35
	local target=nil local closest=aggroRange
	for _,p in ipairs(Players:GetPlayers()) do
		local r=root(p)
		if r and D.Get(p) and participant(e,p) and (e~=G.Boss or inArena(p)) and distance(r.Position,e.Home)<e.Config.Leash then
			local d=distance(r.Position,e.Body.Position) if d<closest then closest=d target=p end
		end
	end
	if not target then
		e.State="Patrol"
		if (e.Config.Speed or 0)<=0 or e.Id=="TrainingDrone" or e.Id=="FrostDrone" or e.Config.Boss or e==G.Boss then
			setEnemyMoving(e,false)
			return
		end
		if now<(e.PatrolWaitUntil or 0) then
			setEnemyMoving(e,false)
			return
		end
		local dir=e.PatrolDir or 1
		local goal=e.Home+_V3(dir*4.2,0,0)
		local dx=math.abs(goal.X-e.Body.Position.X)
		if dx<0.35 or not move(e,goal,dt,math.min((e.Config.Speed or 12)*0.55,7.5)) then
			e.PatrolDir=-dir
			e.PatrolWaitUntil=now+2.4
			setEnemyMoving(e,false)
		end
		return
	end
	local r=root(target) if not r then setEnemyMoving(e,false) return end

	if e.Id=="CryonPrime" then
		e.SpecialTimer=(e.SpecialTimer or 0)+dt
		if e.SpecialTimer>=7 then
			e.SpecialTimer=0
			e.RecoverUntil=now+2.2
			setEnemyMoving(e,false)
			if e.Phase==1 then
				e.Model:SetAttribute("EnemyAttackClip","HeroicKata")
				e.Model:SetAttribute("EnemyAttackDuration",2.0)
				e.Model:SetAttribute("EnemyAttackAt",workspace:GetServerTimeNow())
				G.Telegraph(e,e.Body.Position,18,2.0,(e.Config.ATK or 38)*1.3," GLACIAL SMASH")
			else
				e.Model:SetAttribute("EnemyAttackClip","UltimateAwakening")
				e.Model:SetAttribute("EnemyAttackDuration",2.2)
				e.Model:SetAttribute("EnemyAttackAt",workspace:GetServerTimeNow())
				local tpos=r.Position
				G.Telegraph(e,tpos,16,2.2,(e.Config.ATK or 38)*1.45," ABSOLUTE ZERO STORM")
				for _,off in ipairs({_V3(-12,0,8),_V3(12,0,8),_V3(0,0,-12)}) do
					G.Telegraph(e,tpos+off,6.5,1.8,(e.Config.ATK or 38)*0.85," FROST SHARD")
				end
			end
			return
		end
	elseif e.Id=="Noxar" then
		e.SpecialTimer=(e.SpecialTimer or 0)+dt
		if e.SpecialTimer>=6.5 then
			e.SpecialTimer=0
			e.RecoverUntil=now+2.3
			setEnemyMoving(e,false)
			if e.Phase>=3 then
				e.Phase3Triggered=true
				e.Model:SetAttribute("EnemyAttackClip","UltimateAwakening")
				e.Model:SetAttribute("EnemyAttackDuration",2.4)
				e.Model:SetAttribute("EnemyAttackAt",workspace:GetServerTimeNow())
				e.Model:SetAttribute("NoxarPhaseFX","Phase3Judgement")
				e.Model:SetAttribute("NoxarFXAt",workspace:GetServerTimeNow())
				local tpos=r.Position
				G.Telegraph(e,tpos,16,2.1,(e.Config.ATK or 44)*1.5," VOID ANNIHILATION")
				G.Telegraph(e,e.Home+_V3(-14,0,10),12,2.4,(e.Config.ATK or 44)*1.2," VOID ANNIHILATION")
				G.Telegraph(e,e.Home+_V3(14,0,-10),12,2.4,(e.Config.ATK or 44)*1.2," VOID ANNIHILATION")
			else
				e.Model:SetAttribute("EnemyAttackClip","HeroicKata")
				e.Model:SetAttribute("EnemyAttackDuration",2.0)
				e.Model:SetAttribute("EnemyAttackAt",workspace:GetServerTimeNow())
				G.Telegraph(e,r.Position,17,2.0,(e.Config.ATK or 44)*1.35," VOID OBLITERATION")
			end
			return
		end
	end

	if now<(e.RecoverUntil or 0) then e.State="Recover" setEnemyMoving(e,false) return end
	if closest>e.Config.Range or not clearLine(e.Body.Position,r.Position) then e.State="Chase" move(e,r.Position,dt) return end
	if now<e.NextAttack then e.State="Recover" setEnemyMoving(e,false) return end
	e.State="Attack"
	setEnemyMoving(e,false)
	local isBoss=e==G.Boss local phase=isBoss and e.Phase or 1
	local isAnyBoss=isBoss or SINGLETON_BOSSES[e.Id] or (e.Config and e.Config.Boss==true)
	local isRanged=(e.Id=="LightArcher" or e.Id=="CyberArcher" or e.Id=="ShadowArcher" or e.Config.Ranged)
	local windup=isBoss and (phase==3 and .6 or .95) or ((e.Id=='CryonPrime' or e.Id=='Noxar') and 1.1 or (isAnyBoss and .82 or (isRanged and .68 or .42)))
	e.AttackNumber=(e.AttackNumber or 0)+1
	local cycleClip="Attack"
	if e.AttackNumber%5==0 then
		cycleClip="UltimateAwakening"
	elseif e.AttackNumber%4==0 then
		cycleClip="Heavy"
	elseif e.AttackNumber%3==0 then
		cycleClip="HeroicKata"
	elseif e.AttackNumber%2==0 then
		cycleClip="ElementalSurge"
	end
	if e.Model then
		local faceFlat=_V3(r.Position.X,e.Body.Position.Y,r.Position.Z)
		if (faceFlat-e.Body.Position).Magnitude>0.15 then
			e.Model:PivotTo(CFrame.lookAt(e.Body.Position,faceFlat))
		end
	end
	e.Model:SetAttribute('EnemyAttackClip',cycleClip)
	e.Model:SetAttribute('EnemyAttackDuration',windup+.35)
	e.Model:SetAttribute('EnemyAttackAt',workspace:GetServerTimeNow())
	e.NextAttack=now+(isBoss and (phase==3 and 1.7 or 2.7) or (isAnyBoss and 2.1 or 1.65)) e.RecoverUntil=now+windup+.35
	local attackPos=isRanged and r.Position or e.Body.Position
	local radius=isBoss and 15 or (isRanged and 5.5 or e.Config.Range)
	if e.Id=='CryonPrime' or e.Id=='Noxar' then radius=14 end
	if e.Id~="TrainingDrone" and e.Id~="FrostDrone" then pcall(Cosmetics.BossSwing,e.Model,windup) end
	G.Telegraph(e,_V3(attackPos.X,safeGroundY(attackPos)+.1,attackPos.Z),radius,windup,e.Config.ATK or e.Config.Attack or 15,isBoss and " SOLAR CLEAVE" or " DANGER",not isRanged)
	if isBoss then
		e.AttackNumber=(e.AttackNumber or 0)+1
		if phase>=2 or e.AttackNumber%3==0 then
			local pos=_V3(r.Position.X,safeGroundY(r.Position)+.1,r.Position.Z)
			G.Telegraph(e,pos,phase==3 and 9 or 7,windup+.35,(e.Config.ATK or 30)*.8," SOLAR FLARE")
		end
	end
end

function G.EnsureWorld()
	local hubModel=workspace:FindFirstChild("SkyHub")
	local spawnLoc=(hubModel and hubModel:FindFirstChild("SkybornSpawn")) or workspace:FindFirstChild("SkybornSpawn",true)
	if spawnLoc and spawnLoc:IsA("BasePart") then
		spawnLoc.Anchored=true
		spawnLoc.CanCollide=true
		if spawnLoc:IsA("SpawnLocation") then spawnLoc.Neutral=true end
		spawnLoc.CFrame=_CF((C.Spawn or _V3(-317.4,50.5,527.8))-_V3(0,2.5,0))
	end
	if not workspace:FindFirstChild("ActiveCompanions") then
		local f=_IN("Folder")
		f.Name="ActiveCompanions"
		f.Parent=workspace
	end
	if not workspace:FindFirstChild("TempFX") then
		local f=_IN("Folder")
		f.Name="TempFX"
		f.Parent=workspace
	end
	local keepEditShowcase = {
		CryonPillar = true,
		NoxarVoidFX = true,
		AbyssalDragonHybrid = true,
		AbyssalSovereignDragon = true,
		Chronos = true,
		DrVega = true,
	}
	for _, folderName in ipairs({"HeroShowcase", "NPCs", "Ships", "ActiveEnemies", "ActiveBosses", "SkybreakWorldObjects"}) do
		local f = workspace:FindFirstChild(folderName)
		if f then
			for _, ch in ipairs(f:GetChildren()) do
				if ch:IsA("Model") and not ch:FindFirstChild("Body") and not keepEditShowcase[ch.Name] then
					ch:Destroy()
				end
			end
		end
	end
	local worldObjects=workspace:FindFirstChild("SkybreakWorldObjects")
	if not worldObjects then
		worldObjects=_IN("Folder")
		worldObjects.Name="SkybreakWorldObjects"
		worldObjects.Parent=workspace
	end

	G.Chests={}
	G.Shrines={}

	-- Interactive Shrine & Raid Console Triggers ONLY on islands without a HomePointCrystal (avoiding duplicate HomePoint pillars)
	local islandSpecs={
		{Id="AetherShrines", Title=" AETHER HOME SHRINE • ĐÀI ĐIỆN THỜ LƯU ĐIỂM HỒI SINH", Realm="GoldenSky", Pos=_V3(340,48.5,988), GlowCol=_RGB(88,238,255)},
		{Id="MicrochipRaidLab", Title=" MICROCHIP RAID LAB • PHÒNG THÍ NGHIỆM THỨC TỈNH", Realm="FrozenCyber", Pos=_V3(14600,46.9,1765), GlowCol=_RGB(95,240,255), IsRaidLab=true},
		{Id="GlacialWreckage", Title=" GLACIAL WRECKAGE • XÁC TÀU BĂNG CỔ ĐẠI", Realm="FrozenCyber", Pos=_V3(14600,46.9,-1796), GlowCol=_RGB(145,242,255)},
		{Id="UmbralSanctum", Title=" UMBRAL CRYSTAL SANCTUM • RỪNG TINH THỂ ĐEN", Realm="ShadowRealm", Pos=_V3(-9400,46.9,1802), GlowCol=_RGB(245,95,255)},
		{Id="VerdantCrown", Title=" THE VERDANT CROWN • VƯƠNG MIỆN CỔ THỤ (REALM 4)", Realm="VerdantCrown", Pos=_V3(0,166.9,-8970), GlowCol=_RGB(95,242,155)},
		{Id="EmberforgeWastes", Title=" EMBERFORGE WASTES • HOANG MẠC LÒ RÈN LỬA (REALM 5)", Realm="EmberforgeWastes", Pos=_V3(12000,166.5,-9250), GlowCol=_RGB(255,145,78)},
		{Id="AbyssalTides", Title=" ABYSSAL TIDES • THỦY TRIỀU VỰC SÂU (REALM 6)", Realm="AbyssalTides", Pos=_V3(-12000,166.9,-8950), GlowCol=_RGB(68,215,245)},
		{Id="ChronosBastion", Title=" CHRONOS BASTION • PHÁO ĐÀI THỜI GIAN (REALM 7)", Realm="ChronosBastion", Pos=_V3(0,226.9,-13470), GlowCol=_RGB(255,215,92)},
		{Id="VeilsEnd", Title=" THE VEIL'S END • TẬN CÙNG BỨC MÀN (REALM 8)", Realm="VeilsEnd", Pos=_V3(0,306.9,-17612), GlowCol=_RGB(215,115,255)},
	}
	for _,isl in ipairs(islandSpecs) do
		local ipos=W.SnapToOpenGround and select(1,W.SnapToOpenGround(isl.Pos,isl.Pos.Y,0)) or isl.Pos
		isl.Pos=ipos
		if isl.IsRaidLab then
			local consolePos=ipos+_V3(0,3.5,0)
			local consolePillar=W.Part(worldObjects,isl.Id.."_Console",_V3(2.8,5.5,2.8),consolePos,isl.GlowCol,Enum.Material.SmoothPlastic)
			consolePillar.Transparency=1
			consolePillar.CanCollide=false

			local cBill=_IN("BillboardGui")
			cBill.Size=_UD2S(4.4,0.82)
			cBill.StudsOffset=_V3(0,5.5,0)
			cBill.AlwaysOnTop=false cBill.MaxDistance=48
			cBill.Parent=consolePillar
			local cLbl=_IN("TextLabel")
			cLbl.Size=_UD2S(1,1)
			cLbl.BackgroundTransparency=1
			cLbl.Font=Enum.Font.GothamBlack
			cLbl.TextScaled=true
			cLbl.TextColor3=isl.GlowCol
			cLbl.TextStrokeTransparency=0.2
			cLbl.Text=isl.Title
			cLbl.Parent=cBill

			local cPrompt=_IN("ProximityPrompt")
			cPrompt.MaxActivationDistance=15
			cPrompt.HoldDuration=0
			cPrompt.ActionText="Khởi Động Awakening Raid (5-Chip Console)"
			cPrompt.ObjectText="Microchip Raid Console • Frozen Cyber"
			cPrompt.Parent=consolePillar
			cPrompt.Triggered:Connect(function(p)
				G.Equipment(p,{action="StartAwakeningRaid"})
			end)
		else
			local shId="Shrine_"..isl.Id
			G.Shrines[shId]={Id=shId,Realm=isl.Realm,Pos=ipos}
		end
	end


	-- Sequential End-of-World 3D Progression Portals (World n -> World n+1 at the culmination/boss exit of every World!)
	local wpFolder=workspace:FindFirstChild("WorldPortals")
	if wpFolder then wpFolder:Destroy() end
	wpFolder=_IN("Folder")
	wpFolder.Name="WorldPortals"
	wpFolder.Parent=workspace

	local worldPortalSpecs={
		-- Tầng Trời 1: Golden Sky Odyssey (Worlds 1 -> 2 -> 3 -> 4 -> 5 -> Tầng Trời 2)
		{Id="WorldGate_01", Order=1, NextOrder=2, StageLabel="WORLD 1  WORLD 2", Title="Cổng Cuối World 1 (Aureon Citadel Exit)", TargetTitle="World 2 • Core Shrine", TargetRealm="GoldenSky", TargetWorldKey="ZiolesGachaShrine", Element="Sky", Pos=_V3(-42,46.5,-435), TargetPos=_V3(-560,52.5,996), Col=_RGB(255,215,85)},
		{Id="WorldGate_02", Order=2, NextOrder=3, StageLabel="WORLD 2  WORLD 3", Title="Cổng Cuối World 2 (Core Shrine Exit)", TargetTitle="World 3 • Aether Home Shrine", TargetRealm="GoldenSky", TargetWorldKey="AetherShrines", Element="Sky", Pos=_V3(-560,48.5,956), TargetPos=_V3(340,52.5,996), Col=_RGB(95,238,255)},
		{Id="WorldGate_03", Order=3, NextOrder=4, StageLabel="WORLD 3  WORLD 4", Title="Cổng Cuối World 3 (Aether Shrine Exit)", TargetTitle="World 4 • West Garden Pirate Bastion", TargetRealm="GoldenSky", TargetWorldKey="WestGarden", Element="Sky", Pos=_V3(340,48.5,956), TargetPos=_V3(-2800,50.5,-65), Col=_RGB(255,205,82)},
		{Id="WorldGate_04", Order=4, NextOrder=5, StageLabel="WORLD 4  WORLD 5", Title="Cổng Cuối World 4 (West Garden Exit)", TargetTitle="World 5 • Sunshard Sky Sanctuary", TargetRealm="GoldenSky", TargetWorldKey="SunshardSanctuary", Element="Sky", Pos=_V3(-2828,46.5,-40), TargetPos=_V3(2800,50.5,-55), Col=_RGB(255,222,95)},
		{Id="WorldGate_05", Order=5, NextOrder=6, StageLabel="WORLD 5  WORLD 6 (TẦNG TRỜI 2)", Title="Cổng Cuối World 5 (Sunshard Apex Exit)", TargetTitle="World 6 • Frozen Cyber Continent", TargetRealm="FrozenCyber", TargetWorldKey="FrozenCyber", Element="Frost", Pos=_V3(2800,46.5,-445), TargetPos=_V3(11620.5,50.9,534.8), Col=_RGB(88,238,255)},
		-- Tầng Trời 2: Frozen Cyber Odyssey (Worlds 6 -> 7 -> 8 -> 9 -> 10 -> Tầng Trời 3)
		{Id="WorldGate_06", Order=6, NextOrder=7, StageLabel="WORLD 6  WORLD 7", Title="Cổng Cuối World 6 (Cryon Citadel Exit)", TargetTitle="World 7 • Trade Station", TargetRealm="FrozenCyber", TargetWorldKey="CyberportCafe", Element="Frost", Pos=_V3(12000,46.9,-430), TargetPos=_V3(9400,50.9,1785), Col=_RGB(88,238,255)},
		{Id="WorldGate_07", Order=7, NextOrder=8, StageLabel="WORLD 7  WORLD 8", Title="Cổng Cuối World 7 (Trade Station Exit)", TargetTitle="World 8 • Permafrost Garrison Fortress", TargetRealm="FrozenCyber", TargetWorldKey="PermafrostGarrison", Element="Frost", Pos=_V3(9400,46.9,1825), TargetPos=_V3(9400,50.9,-2055), Col=_RGB(115,242,255)},
		{Id="WorldGate_08", Order=8, NextOrder=9, StageLabel="WORLD 8  WORLD 9", Title="Cổng Cuối World 8 (Permafrost Exit)", TargetTitle="World 9 • Microchip Awakening Raid Lab", TargetRealm="FrozenCyber", TargetWorldKey="MicrochipRaidLab", Element="Frost", Pos=_V3(9400,46.9,-2025), TargetPos=_V3(14600,50.9,1785), Col=_RGB(95,245,255)},
		{Id="WorldGate_09", Order=9, NextOrder=10, StageLabel="WORLD 9  WORLD 10", Title="Cổng Cuối World 9 (Raid Lab Exit)", TargetTitle="World 10 • Glacial Wreckage Danger Sea", TargetRealm="FrozenCyber", TargetWorldKey="GlacialWreckage", Element="Frost", Pos=_V3(14600,46.9,1855), TargetPos=_V3(14600,50.9,-1812), Col=_RGB(135,242,255)},
		{Id="WorldGate_10", Order=10, NextOrder=11, StageLabel="WORLD 10  WORLD 11 (TẦNG TRỜI 3)", Title="Cổng Cuối World 10 (Glacial Abyss Exit)", TargetTitle="World 11 • Shadow Realm Continent", TargetRealm="ShadowRealm", TargetWorldKey="ShadowRealm", Element="Void", Pos=_V3(14600,46.9,-1361.3), TargetPos=_V3(-12593.4,50.9,414), Col=_RGB(215,95,255)},
		-- Tầng Trời 3: Shadow Realm Odyssey (Worlds 11 -> 12 -> 13 -> 14 -> 15 -> Realm 4)
		{Id="WorldGate_11", Order=11, NextOrder=12, StageLabel="WORLD 11  WORLD 12", Title="Cổng Cuối World 11 (Noxar Throne Exit)", TargetTitle="World 12 • Void Bastion", TargetRealm="ShadowRealm", TargetWorldKey="CastleOnTheVoid", Element="Void", Pos=_V3(-11672.2,46.9,-270), TargetPos=_V3(-14600,50.9,2173.1), Col=_RGB(225,110,255)},
		{Id="WorldGate_12", Order=12, NextOrder=13, StageLabel="WORLD 12  WORLD 13", Title="Cổng Cuối World 12 (Void Bastion Exit)", TargetTitle="World 13 • Umbral Crystal Sanctum", TargetRealm="ShadowRealm", TargetWorldKey="UmbralSanctum", Element="Void", Pos=_V3(-14600,46.9,1565), TargetPos=_V3(-9400,50.9,1815), Col=_RGB(245,95,255)},
		{Id="WorldGate_13", Order=13, NextOrder=14, StageLabel="WORLD 13  WORLD 14", Title="Cổng Cuối World 13 (Umbral Sanctum Exit)", TargetTitle="World 14 • Ascension Shrine", TargetRealm="ShadowRealm", TargetWorldKey="TempleOfTheCore", Element="Void", Pos=_V3(-9400,46.9,1845), TargetPos=_V3(-14600,50.9,-1785), Col=_RGB(210,120,255)},
		{Id="WorldGate_14", Order=14, NextOrder=15, StageLabel="WORLD 14  WORLD 15", Title="Cổng Cuối World 14 (Ascension Shrine Exit)", TargetTitle="World 15 • Phantom Isle (Serpent Abyss)", TargetRealm="ShadowRealm", TargetWorldKey="LeviathanAbyss", Element="Void", Pos=_V3(-14600,46.9,-1768), TargetPos=_V3(-12000,50.9,-3364.5), Col=_RGB(78,238,255)},
		{Id="WorldGate_15", Order=15, NextOrder=16, StageLabel="WORLD 15  WORLD 16 (REALM 4)", Title="Cổng Cuối World 15 (Phantom Isle Exit)", TargetTitle="World 16 • The Verdant Crown (Realm 4)", TargetRealm="VerdantCrown", TargetWorldKey="VerdantCrown", Element="Sky", Pos=_V3(-12000,46.9,-2945), TargetPos=_V3(0,170.9,-8985), Col=_RGB(95,242,155)},
		-- Expansion Realms 4-8 (Worlds 16 -> 17 -> 18 -> 19 -> 20 -> Ascension Loop to World 1)
		{Id="WorldGate_16", Order=16, NextOrder=17, StageLabel="WORLD 16  WORLD 17 (REALM 5)", Title="Cổng Cuối World 16 (Verdant Crown Exit)", TargetTitle="World 17 • Emberforge Wastes (Realm 5)", TargetRealm="EmberforgeWastes", TargetWorldKey="EmberforgeWastes", Element="Sky", Pos=_V3(0,166.9,-8520), TargetPos=_V3(12000,170.5,-9265), Col=_RGB(255,145,78)},
		{Id="WorldGate_17", Order=17, NextOrder=18, StageLabel="WORLD 17  WORLD 18 (REALM 6)", Title="Cổng Cuối World 17 (Emberforge Exit)", TargetTitle="World 18 • Abyssal Tides (Realm 6)", TargetRealm="AbyssalTides", TargetWorldKey="AbyssalTides", Element="Frost", Pos=_V3(12000,166.5,-9230), TargetPos=_V3(-12000,170.9,-8964.5), Col=_RGB(68,215,245)},
		{Id="WorldGate_18", Order=18, NextOrder=19, StageLabel="WORLD 18  WORLD 19 (REALM 7)", Title="Cổng Cuối World 18 (Abyssal Tides Exit)", TargetTitle="World 19 • Chronos Bastion (Realm 7)", TargetRealm="ChronosBastion", TargetWorldKey="ChronosBastion", Element="Sky", Pos=_V3(-12000,166.9,-8545), TargetPos=_V3(0,230.9,-13485), Col=_RGB(255,215,92)},
		{Id="WorldGate_19", Order=19, NextOrder=20, StageLabel="WORLD 19  WORLD 20 (REALM 8)", Title="Cổng Cuối World 19 (Chronos Bastion Exit)", TargetTitle="World 20 • The Veil's End (Realm 8)", TargetRealm="VeilsEnd", TargetWorldKey="VeilsEnd", Element="Void", Pos=_V3(0,226.9,-13005), TargetPos=_V3(0,310.9,-17626.9), Col=_RGB(215,115,255)},
		{Id="WorldGate_20", Order=20, NextOrder=1, StageLabel="WORLD 20  WORLD 1 (ASCENSION)", Title="Cổng Tận Cùng Bức Màn (Veil's End Apex)", TargetTitle="World 1 • Golden Sky Hub (Luân Hồi Thiên Giới)", TargetRealm="GoldenSky", TargetWorldKey="GoldenSky", Element="Sky", Pos=_V3(0,306.9,-18230), TargetPos=_V3(-317.4,50.5,527.8), Col=_RGB(255,232,125)},
		-- Direct Main Continent Gates & Spawn Plaza Portals
		{Id="WorldGate_SkyHub_Plaza", Order=1, NextOrder=2, StageLabel="SKY HUB  WORLD 2", Title="Cổng Dịch Chuyển Sky Hub", TargetTitle="World 2 • Core Shrine", TargetRealm="GoldenSky", TargetWorldKey="ZiolesGachaShrine", Element="Sky", Pos=_V3(-290,46.5,558), TargetPos=_V3(-560,52.5,996), Col=_RGB(255,215,85)},
		{Id="WorldGate_Sea2_Plaza", Order=6, NextOrder=7, StageLabel="TẦNG TRỜI 2  WORLD 7", Title="Cổng Dịch Chuyển Frozen Cyber", TargetTitle="World 7 • Trade Station", TargetRealm="FrozenCyber", TargetWorldKey="CyberportCafe", Element="Frost", Pos=_V3(11648,46.9,512), TargetPos=_V3(9400,50.9,1785), Col=_RGB(88,238,255)},
		{Id="WorldGate_Sea3_Plaza", Order=11, NextOrder=12, StageLabel="TẦNG TRỜI 3  WORLD 12", Title="Cổng Dịch Chuyển Shadow Realm", TargetTitle="World 12 • Void Bastion", TargetRealm="ShadowRealm", TargetWorldKey="CastleOnTheVoid", Element="Void", Pos=_V3(-12622,46.9,395), TargetPos=_V3(-14600,50.9,2173.1), Col=_RGB(215,95,255)},
		{Id="WorldGate_Sea1_to_Sea2", Order=1, NextOrder=6, StageLabel="TẦNG TRỜI 1 -> 2", Title="Cổng Bắc Aureon Citadel", TargetTitle="Tầng Trời 2 • Frozen Cyber Continent", TargetRealm="FrozenCyber", TargetWorldKey="FrozenCyber", Element="Frost", Pos=_V3(42,46.5,-412), TargetPos=_V3(11620.5,50.9,534.8), Col=_RGB(88,238,255)},
		{Id="WorldGate_Sea2_to_Sea3", Order=6, NextOrder=11, StageLabel="TẦNG TRỜI 2 -> 3", Title="Cổng Bắc Cryon Citadel", TargetTitle="Tầng Trời 3 • Shadow Realm Continent", TargetRealm="ShadowRealm", TargetWorldKey="ShadowRealm", Element="Void", Pos=_V3(12610,46.9,-448), TargetPos=_V3(-12593.4,50.9,414), Col=_RGB(215,95,255)},
	}
	G.WorldPortals={}
	for _,wp in ipairs(worldPortalSpecs) do
		if W.SnapToOpenGround then
			wp.Pos=select(1,W.SnapToOpenGround(wp.Pos,wp.Pos.Y,0))
			wp.TargetPos=select(1,W.SnapToOpenGround(wp.TargetPos,wp.TargetPos.Y-3.0,3.0))
		end
		local gm=_IN("Model")
		gm.Name=wp.Id
		gm:SetAttribute("PortalId",wp.Id)
		gm:SetAttribute("StageLabel",wp.StageLabel)
		gm:SetAttribute("TargetTitle",wp.TargetTitle)
		gm:SetAttribute("TargetRealm",wp.TargetRealm)
		gm:SetAttribute("Element",wp.Element)
		gm:SetAttribute("Order",wp.Order)
		gm:SetAttribute("NextOrder",wp.NextOrder)
		gm:SetAttribute("FloorY",wp.Pos.Y)
		gm:SetAttribute("GlowColor",wp.Col)
		gm.Parent=wpFolder

		local centerPos=wp.Pos+_V3(0,4.2,0)
		local core=W.Part(gm,"GateCore",_V3(6.5,8.5,2.5),centerPos,wp.Col,Enum.Material.Neon)
		core.Transparency=1
		core.CanCollide=false
		core:SetAttribute("Interactable","WorldPortal")
		core:SetAttribute("InteractableId",wp.Id)
		gm.PrimaryPart=core

		local pBill=_IN("BillboardGui")
		pBill.Size=_UD2S(4.8,0.92)
		pBill.StudsOffset=_V3(0,6.8,0)
		pBill.AlwaysOnTop=false
		pBill.MaxDistance=58
		pBill.Parent=core
		local pLbl=_IN("TextLabel")
		pLbl.Size=_UD2S(1,1)
		pLbl.BackgroundTransparency=1
		pLbl.Font=Enum.Font.GothamBlack
		pLbl.TextScaled=true
		pLbl.TextColor3=wp.Col
		pLbl.TextStrokeTransparency=0.18
		pLbl.Text=""..wp.StageLabel.."\n "..wp.TargetTitle
		pLbl.Parent=pBill

		local pPrompt=_IN("ProximityPrompt")
		pPrompt.ActionText="Bước Vào Cổng Dịch Chuyển ("..wp.StageLabel..")"
		pPrompt.ObjectText=wp.Title.." → "..wp.TargetTitle
		pPrompt.MaxActivationDistance=15
		pPrompt.HoldDuration=0
		pPrompt.RequiresLineOfSight=false
		pPrompt.Parent=core

		local gateSpec={
			Id=wp.Id,
			Order=wp.Order,
			NextOrder=wp.NextOrder,
			StageLabel=wp.StageLabel,
			Title=wp.Title,
			TargetTitle=wp.TargetTitle,
			TargetRealm=wp.TargetRealm,
			TargetWorldKey=wp.TargetWorldKey,
			Element=wp.Element,
			Pos=wp.Pos,
			CenterPos=centerPos,
			TargetPos=wp.TargetPos,
			Col=wp.Col,
			Part=core,
			Model=gm,
		}
		G.WorldPortals[wp.Id]=gateSpec
		core:SetAttribute("PromptBound",true)
		W.Interactions[wp.Id]=core
		pPrompt.Triggered:Connect(function(p)
			G.EnterWorldPortal(p,gateSpec)
		end)
	end

	-- Strip any leftover invisible marker prompts on Lyra/Kael before rebuilding rigged 3D NPCs
	for _,mk in ipairs({"Kael","Lyra"}) do
		local oldM=W.Interactions[mk]
		if oldM and typeof(oldM)=="Instance" then
			for _,ch in ipairs(oldM:GetChildren()) do
				if ch:IsA("ProximityPrompt") or ch:IsA("BillboardGui") then ch:Destroy() end
			end
		end
	end

	local function spawnRiggedNPC(modelName,interactId,assetId,titleTxt,actTxt,objTxt,pos,floorY,lookPos,col,regKey)
		if W.SnapToOpenGround then
			local sp,sfy=W.SnapToOpenGround(pos,floorY,2.2)
			pos,floorY=sp,sfy
		end
		local existing=worldObjects:FindFirstChild(modelName)
		if existing then existing:Destroy() end
		local nm=_IN("Model")
		nm.Name=modelName
		nm.Parent=worldObjects
		local body=W.Part(nm,"Body",_V3(2.2,4.6,1.8),pos,col,Enum.Material.Metal)
		body.Transparency=1
		body.CanCollide=false
		local flatLook=_V3(lookPos.X,pos.Y,lookPos.Z)
		if (flatLook-pos).Magnitude>0.15 then
			body.CFrame=CFrame.lookAt(pos,flatLook)
		end
		nm.PrimaryPart=body
		nm:SetAttribute("NPCId",assetId)
		nm:SetAttribute("VisualAsset",assetId)
		nm:SetAttribute("NPCFloorY",floorY)
		local bill=_IN("BillboardGui")
		bill.Size=_UD2S(3.8,0.68)
		bill.StudsOffset=_V3(0,4.8,0)
		bill.AlwaysOnTop=false bill.MaxDistance=44
		bill.Parent=body
		local tl=_IN("TextLabel")
		tl.Size=_UD2S(1,1)
		tl.BackgroundTransparency=1
		tl.Font=Enum.Font.GothamBlack
		tl.TextScaled=true
		tl.TextColor3=col
		tl.TextStrokeTransparency=0.2
		tl.Text=titleTxt
		tl.Parent=bill
		local prompt=_IN("ProximityPrompt")
		prompt.ActionText=actTxt
		prompt.ObjectText=objTxt
		prompt.MaxActivationDistance=14
		prompt.HoldDuration=0
		prompt.RequiresLineOfSight=false
		prompt.Style=Enum.ProximityPromptStyle.Default
		prompt.Parent=body
		body:SetAttribute("InteractableId",interactId)
		body:SetAttribute("PromptBound",true)
		W.Interactions[regKey or modelName]=body
		prompt.Triggered:Connect(function(p)
			nm:SetAttribute("NPCTalkAt",workspace:GetServerTimeNow())
			G.Interact(p,interactId)
		end)
		return nm,body
	end

	-- Sky Hub Plaza NPCs (>= 15 studs apart, CFrame.lookAt facing Sky Hub Spawn (-317.4, 50.5, 527.8))
	local hubPlaza=_V3(-317.4,50.5,527.8)
	spawnRiggedNPC("Lyra_SkyHubCommander","Lyra","Lyra","Lyra • Chỉ Huy Skyborn [E]","Nhận Nhiệm Vụ Cốt Truyện","Lyra • Chỉ Huy Skyborn",_V3(-298,49.0,506),46.5,hubPlaza,_RGB(115,235,255),"Lyra")
	spawnRiggedNPC("Kael_WeaponMaster","Kael","Kael","Kael • Đại Sư Rèn Thần Khí [E]","Mở Lò Rèn / Đổi Hệ Phái","Kael • Master Weaponsmith",_V3(-280,49.0,506),46.5,hubPlaza,_RGB(255,192,85),"Kael")
	spawnRiggedNPC("Zioles_AetherGachaShrine","Zioles","ZiolesGachaNPC","Hiền Giả Zioles • Gacha Lõi [E]","Cầu Lõi Aether (Xác Nhận Giá)","Hiền Giả Zioles • Core Oracle",_V3(-338,49.0,500),46.5,hubPlaza,_RGB(255,218,92),"Zioles_AetherGachaShrine")
	spawnRiggedNPC("Zioles_IslandShrine","Zioles","ZiolesGachaNPC","Hiền Giả Zioles • Gacha Lõi [E]","Cầu Lõi Aether (Xác Nhận Giá)","Hiền Giả Zioles • Core Oracle",_V3(-560,50.7,978),48.5,_V3(-560,50.7,1005),_RGB(255,218,92),"Zioles_IslandShrine")
	spawnRiggedNPC("AncientMonk_GodhumanShrine","AncientMonk","AncientMonkNPC","Đại Sư Cổ Tự • Thần Quyền [E]","Bái Sư Lĩnh Ngộ Võ Thuật","Đại Sư Cổ Tự • Ascendant Master",_V3(-358,49.0,518),46.5,hubPlaza,_RGB(255,222,95),"AncientMonk_GodhumanShrine")
	spawnRiggedNPC("AncientMonk_SunshardSanctuary","AncientMonk","AncientMonkNPC","Đại Sư Cổ Tự • Thần Quyền [E]","Bái Sư Lĩnh Ngộ Võ Thuật","Đại Sư Cổ Tự • Ascendant Master",_V3(2774.0,49.0,-49.0),46.5,_V3(2800,49.0,-55),_RGB(255,222,95),"AncientMonk_SunshardSanctuary")
	spawnRiggedNPC("AncientMonk_TempleOfTheCore","AncientMonk","AncientMonkNPC","Đại Sư Cổ Tự • Thần Quyền [E]","Bái Sư Lĩnh Ngộ Võ Thuật","Đại Sư Cổ Tự • Ascendant Master",_V3(-14609.0,49.1,-1788.1),46.9,_V3(-14600,49.1,-1785),_RGB(255,222,95),"AncientMonk_TempleOfTheCore")

	-- All 18 Regional & Expansion World NPCs with Plaza CFrame.lookAt & Authentic Role Dialogues
	for _,rn in ipairs(Helpers.REGIONAL_NPCS) do
		spawnRiggedNPC(rn.Id,rn.Id,rn.Visual,rn.Name.." [E]","Trò Chuyện & Tương Tác",rn.Role,rn.Pos,rn.FloorY,rn.LookAt,rn.Col,rn.Id)
	end

	local naturalFolder=worldObjects:FindFirstChild("NaturalFruits")
	if not naturalFolder then
		naturalFolder=_IN("Folder")
		naturalFolder.Name="NaturalFruits"
		naturalFolder.Parent=worldObjects
	end
end

function G.Character(p,ch)
	local respawnPos=p:GetAttribute("RespawnPos")
	local respawnRealm=p:GetAttribute("RespawnRealm") or "GoldenSky"
	p:SetAttribute('CurrentRealm',typeof(respawnPos)=="Vector3" and respawnRealm or 'GoldenSky')
	local h=ch:WaitForChild("Humanoid",10) local r=ch:WaitForChild("HumanoidRootPart",10)
	-- Tat script "Health" mac dinh cua Roblox (hoi 1% MaxHP/s ca khi dang danh va ca khi da chet).
	-- Game da co hoi mau rieng: 3 HP/s sau 7s khong bi danh (vong lap tick ben duoi).
	local defaultRegen=ch:FindFirstChild("Health")
	if defaultRegen and defaultRegen:IsA("Script") then defaultRegen:Destroy() end
	local profile=D.Get(p)
	if not h or not r or not profile then return end
	ensureProfileFields(profile)
	local auraOn=profile.Haki and profile.Haki.Aura==true
	local kenOn=profile.Haki and profile.Haki.Instinct==true
	local kenDodges=math.clamp(tonumber(profile.Haki and profile.Haki.InstinctDodges) or 8,0,8)
	local v4Race=profile.RaceV4Active and (profile.Race or "Skyborn") or ""
	ch:SetAttribute("HakiAura",auraOn)
	ch:SetAttribute("HakiInstinct",kenOn)
	ch:SetAttribute("InstinctDodges",kenDodges)
	ch:SetAttribute("RaceV4Active",profile.RaceV4Active==true)
	ch:SetAttribute("RaceV4",v4Race)
	ch:SetAttribute("FruitTransform","")
	ch:SetAttribute("DragonFormTier",0)
	ch:SetAttribute("SkybreakFlightActive",false)
	-- 3s khong nhan sat thuong sau khi hoi sinh (CombatRuntimeOverrides.PlayerDamage doc attribute nay).
	ch:SetAttribute("SpawnShieldUntil",workspace:GetServerTimeNow()+3)
	p:SetAttribute("HakiAura",auraOn)
	p:SetAttribute("HakiInstinct",kenOn)
	p:SetAttribute("InstinctDodges",kenDodges)
	p:SetAttribute("RaceV4Active",profile.RaceV4Active==true)
	p:SetAttribute("RaceV4",v4Race)
	p:SetAttribute("FruitTransform","")
	p:SetAttribute("DragonFormTier",0)
	p:SetAttribute("SkybreakFlightActive",false)
	p:SetAttribute("FreeFlightUntil",0)
	p:SetAttribute("PvPCombatUntil",0)
	local charStats=G.Stats(p)
	h.MaxHealth=charStats.HP h.Health=h.MaxHealth h.WalkSpeed=(C.Classes[profile.ClassId].Speed or 16)*(charStats.RaceWalkSpeedMult or 1) h.BreakJointsOnDeath=false
	ch:SetAttribute("GuardianShieldUntil",0)
	local rt=G.Runtime[p] if not rt then return end
	rt.MaxEnergy=charStats.MaxEnergy or 100
	rt.Energy=rt.MaxEnergy
	rt.Stamina=100 rt.ShieldUntil=0 rt.InvincibleUntil=os.clock()+2
	local spawnTarget=typeof(respawnPos)=="Vector3" and (respawnPos+_V3(0,3,0)) or C.Spawn
	G.Teleport(p,spawnTarget,nil,true)
	G.SyncCompanions(p)
	Cosmetics.Guardian(ch)
	G.Sync(p)
	p.CharacterAppearanceLoaded:Once(function(appCh)
		if appCh==ch and ch.Parent then
			Cosmetics.Guardian(ch)
		end
	end)
	local appearanceDeadline=os.clock()+(game.PlaceId==0 and 1.2 or 6.0)
	while p.Character==ch and not p:HasAppearanceLoaded() and os.clock()<appearanceDeadline do task.wait(.1) end
	if p.Character~=ch or not D.Get(p) then return end
	local hand=ch:FindFirstChild("RightHand") or ch:FindFirstChild("Right Arm") or ch:WaitForChild(h.RigType==Enum.HumanoidRigType.R15 and "RightHand" or "Right Arm",8)
	if hand then
		local blade=_IN("Part") blade.Name="SkybornBlade" blade.Size=_V3(.45,4,.25) blade.Color=_RGB(255,213,97) blade.Material=Enum.Material.Metal blade.CanCollide=false blade.CanTouch=false blade.Massless=true blade.Transparency=1 blade.CFrame=hand.CFrame*_CF(0,-1.8,0) blade.Parent=ch
		local weld=_IN("WeldConstraint") weld.Part0=hand weld.Part1=blade weld.Parent=blade
	end
	local torso=ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso") or ch:WaitForChild(h.RigType==Enum.HumanoidRigType.R15 and "UpperTorso" or "Torso",8)
	if torso then
		local function costume(name,size,offset,color)
			local part=_IN("Part") part.Name=name part.Size=size part.Color=color part.Material=Enum.Material.SmoothPlastic part.CanCollide=false part.CanTouch=false part.Massless=true part.Transparency=1 part.CFrame=torso.CFrame*offset part.Parent=ch
			local weld=_IN("WeldConstraint") weld.Part0=torso weld.Part1=part weld.Parent=part
		end
		costume("GuardianBreastplate",_V3(2.1,1.6,.35),_CF(0,0,-.6),_RGB(32,33,39))
		costume("GuardianCrest",_V3(.25,1.35,.15),_CF(0,0,-.84),_RGB(230,180,64))
		costume("CrimsonCape",_V3(2.1,3.2,.15),_CF(0,-.75,.75)*_CFA(.15,0,0),_RGB(132,28,40))
	end
	Cosmetics.Guardian(ch)
	local curProf=D.Get(p)
	if not curProf or p.Character~=ch then return end
	if hand then Cosmetics.Weapon(ch,hand,curProf.Weapon~=nil) end
	G.Sync(p)
end
function G.Join(p)
	if not p or p.Parent~=Players or G.Runtime[p] or G.Joining[p] then return end
	G.Joining[p]=true
	p:SetAttribute('CurrentRealm','GoldenSky')
	local safeSpawnPos=(C.Spawn or _V3(-317.4,50.5,527.8))+_V3(0,3,0)
	local function snapPreLoadChar(ch)
		local hrp=ch and (ch:FindFirstChild("HumanoidRootPart") or ch:WaitForChild("HumanoidRootPart",5))
		if hrp and not G.Runtime[p] then
			hrp.Anchored=false
			hrp.CFrame=_CF(safeSpawnPos)
			hrp.AssemblyLinearVelocity=Vector3.zero
		end
	end
	if p.Character then task.spawn(snapPreLoadChar,p.Character) end
	local preLoadConn=p.CharacterAdded:Connect(function(ch) task.spawn(snapPreLoadChar,ch) end)
	local profile=D.Load(p)
	if preLoadConn then preLoadConn:Disconnect() preLoadConn=nil end
	G.Joining[p]=nil
	if not profile or p.Parent~=Players then
		if profile then D.Release(p) end
		return
	end
	if G.Runtime[p] then return end
	ensureProfileFields(profile)
	p:SetAttribute("DoubleExpSeconds",tonumber(profile.DoubleExpRemainingSec) or 0)
	LiveOps.EvaluateProgressionBadges(G,p,profile)
	LiveOps.SyncPlayerScoresOnSave(p,profile,false)
	local initStats=Helpers.ComputeStats(C,profile,profile.ActiveSlot,p)
	local initMaxE=math.max(100,tonumber(initStats and initStats.MaxEnergy) or 100)
	local rt={Stamina=100,Energy=initMaxE,MaxEnergy=initMaxE,AwakeningMeter=tonumber(profile.AwakeningMeter) or 0,FuryMeter=100,LastCastAt=0,ShieldUntil=0,InvincibleUntil=0,ActionUntil=0,LastAttack=0,Combo=0,LastHurt=0,NextInstinctRegen=os.clock()+5,NextOneSecTick=os.clock()+1,Requests={},Cooldowns={},Companions={},Safe=C.Spawn,MoveAt=os.clock()}
	G.Runtime[p]=rt
	G.UpdatePlayerPortalCompass(p,profile.CurrentWorldOrder or 1)
	rt.CharConn=p.CharacterAdded:Connect(function(ch) G.Character(p,ch) end)
	if p.Character then task.spawn(G.Character,p,p.Character) end
end
function G.Start()
	W.Build()
	G.EnsureWorld()
	D.Start()
	LiveOps.Start(G,D)
	for _,obj in pairs(W.Interactions) do
		if obj:FindFirstChildOfClass("ProximityPrompt") and not obj:GetAttribute("PromptBound") and not G.Chests[obj.Name] and not G.Shrines[obj.Name] then
			obj.ProximityPrompt.Triggered:Connect(function(p) G.Interact(p,obj.Name) end)
		end
	end
	R.CombatRequest.OnServerEvent:Connect(function(p,payload)
		if not RemoteGuard.Allow(p,"Combat") or type(payload)~="table" then return end
		local act=payload.action
		if act=="Attack" or act=="Light" or act=="M1" or act=="Heavy" or act=="ChargeHeavy" or act=="ChargedSlash" or act=="Shoot" or act=="Dodge" or act=="Dash" then
			G.Action(p,act,payload)
		elseif act=="UsePotion" then
			G.Equipment(p,payload)
		end
	end)
	R.AbilityRequest.OnServerEvent:Connect(function(p,payload)
		if not RemoteGuard.Allow(p,"Ability") or type(payload)~="table" then return end
		if G.HandleAbilityExtra and G.HandleAbilityExtra(p,payload) then return end
		local id=payload.skillId or payload.action
		if payload.action=="SlotMove" or payload.key or id=="Z" or id=="X" or id=="C" or id=="V" or id=="F" then
			G.UseSlotMove(p,payload.key or payload.skillId or id,payload)
			return
		elseif payload.action=="ToggleAura" or id=="ToggleAura" then
			G.Equipment(p,{action="ToggleAura"})
			return
		elseif payload.action=="ToggleInstinct" or id=="ToggleInstinct" then
			G.Equipment(p,{action="ToggleInstinct"})
			return
		elseif payload.action=="ConquerorBurst" or id=="ConquerorBurst" then
			G.Equipment(p,{action="ConquerorBurst"})
			return
		elseif payload.action=="ActivateRaceV4" or id=="ActivateRaceV4" then
			G.Equipment(p,{action="ActivateRaceV4"})
			return
		end
		if id=="SkySlash" or id=="GuardianShield" or id=="JudgmentStrike" or id=="CelestialAegis"
			or id=="ArcCut" or id=="FlashStep" or id=="StormBlitz" or id=="ThunderJudgement"
			or id=="FrostBolt" or id=="ManaBarrier" or id=="ArcaneComet" or id=="AstralCataclysm" then
			G.Action(p,id,payload)
		end
	end)
	R.InteractRequest.OnServerEvent:Connect(function(p,payload,extra)
		if not RemoteGuard.Allow(p,"Interact") then return end
		if type(payload)=="string" then
			G.Interact(p,payload,extra)
		elseif type(payload)=="table" then
			G.Interact(p,payload.interactableId or payload.chestId or payload.action or payload.id,payload)
		end
	end)
	R.EquipmentRequest.OnServerEvent:Connect(function(p,payload)
		local ch=(type(payload)=="table" and payload.action=="AddStat") and "StatAllocate" or "Equipment"
		if not RemoteGuard.Allow(p,ch) then return end
		G.Equipment(p,payload)
	end)
	R.AppearanceRequest.OnServerEvent:Connect(function(p,payload)
		if not RemoteGuard.Allow(p,"Appearance") then return end
		G.ChooseAppearance(p,payload)
	end)

	local baseRanFlag=false
	local baseHandleUI=function(p,cmd,payload)
		baseRanFlag=true
		local cmdStr=tostring(cmd or "")
		if cmdStr=="StoreFruit" then
			G.Equipment(p,{action="StoreFruit",fruitId=type(payload)=="table" and (payload.fruitId or payload.id) or nil})
			return true
		elseif cmdStr=="ConfirmNPCAction" or cmdStr:sub(1,17)=="ConfirmNPCAction:" then
			return Helpers.HandleConfirmNPCAction(p,cmdStr=="ConfirmNPCAction" and nil or cmdStr,payload,G,D,C,G.CombatExpansion)
		elseif cmdStr=="EvolveRace" then
			local prof=D.Get(p)
			if prof then Helpers.EvolveRace(p,prof,G,C) end
			return true
		elseif cmdStr=="RollFruitGold" or cmdStr=="RollFruit" then
			G.Equipment(p,{action="RollFruit",currency=(type(payload)=="table" and payload.currency) or "Gold"})
			return true
		elseif cmdStr=="RollFruitShards" then
			G.Equipment(p,{action="RollFruit",currency="Shards"})
			return true
		elseif cmdStr=="SelectClass" then
			G.ChooseAppearance(p,{ClassId=type(payload)=="table" and (payload.classId or payload.id) or payload})
			return true
		elseif cmdStr=="TeleportIsland" then
			if (tonumber(p:GetAttribute("PvPCombatUntil")) or 0)>os.time() then
				LiveOps.Notify(G,p,"Đang trong trạng thái Giao Tranh PvP! Không thể dịch chuyển!","Cannot teleport while PvP combat-tagged!")
				return true
			end
			local islId=type(payload)=="table" and (payload.islandId or payload.nodeId or payload.id) or payload
			if G.CombatExpansion and type(G.CombatExpansion.TeleportToIsland)=="function" then
				G.CombatExpansion.TeleportToIsland(p,islId)
			else
				G.Equipment(p,{action="FastTravel",nodeId=islId})
			end
			return true
		elseif cmdStr=="ClaimPlaytimeGift" then
			LiveOps.ClaimPlaytimeGift(G,D,Helpers,getMonetization(),p,payload)
			return true
		elseif cmdStr=="RequestGlobalLeaderboard" then
			LiveOps.HandleRequestGlobalLeaderboard(G,D,G.SocialEconomy,p,payload)
			return true
		elseif cmdStr=="SetLocale" or cmdStr=="SyncLocale" or cmdStr=="SetLanguage" then
			local raw=type(payload)=="table" and (payload.Language or payload.lang or payload.locale or payload.Locale or payload.RobloxLocaleId or payload.id) or payload
			LiveOps.SetPlayerLocale(p,raw)
			G.Sync(p)
			return true
		end
		return false
	end
	G.HandleUIRequest=baseHandleUI
	G.EnsureProfileFields=ensureProfileFields
	StaticData.SpawnAllInitialEnemies(G)
	for _,sp in ipairs({
		{"SkyPirate",_V3(-632,49.5,146)},{"SkyPirate",_V3(-558,49.5,146)},{"SkyPirate",_V3(-595,49.5,182)},
		{"CorruptedGuard",_V3(-476,48.85,756)},{"CorruptedGuard",_V3(-428,48.85,756)},{"CorruptedGuard",_V3(-476,48.85,788)},{"CorruptedGuard",_V3(-428,48.85,788)},
		{"CorruptedGuard",_V3(132,48.85,716)},{"CorruptedGuard",_V3(200,48.85,716)},
	}) do
		G.SpawnEnemy(sp[1],sp[2],true,false)
	end
	for _,extName in ipairs({"SkybreakCombatExpansion","SkybreakWorldEventsService","SkybreakSocialEconomyService"}) do
		local extMod=script.Parent:FindFirstChild(extName)
		if extMod and extMod:IsA("ModuleScript") then
			local okExt,ext=pcall(require,extMod)
			if okExt and type(ext)=="table" and type(ext.Init)=="function" then
				local okInit,errInit=xpcall(function() ext.Init(G,D,W,C) end,debug.traceback)
				if not okInit then warn("[SKYBREAK] "..extName..".Init error:",errInit) end
			elseif not okExt then
				warn("[SKYBREAK] Failed loading "..extName..":",ext)
			end
		end
	end
	local chainedHandleUI=G.HandleUIRequest
	if chainedHandleUI~=baseHandleUI then
		G.HandleUIRequest=function(p,cmd,payload)
			baseRanFlag=false
			if chainedHandleUI and chainedHandleUI(p,cmd,payload) then return true end
			if not baseRanFlag then return baseHandleUI(p,cmd,payload) end
			return false
		end
	end

	Players.PlayerAdded:Connect(function(p) G.Join(p) end)
	Players.PlayerRemoving:Connect(function(p)
		G.Joining[p]=nil
		local rt=G.Runtime[p]
		if G.SocialEconomy and G.SocialEconomy.OnBeforePlayerRelease then
			pcall(G.SocialEconomy.OnBeforePlayerRelease,p,rt)
		end
		if rt then
			if rt.CharConn then rt.CharConn:Disconnect() rt.CharConn=nil end
			if rt.ReviveBeacon and rt.ReviveBeacon.Parent then rt.ReviveBeacon:Destroy() end
			for _,comp in pairs(rt.Companions or {}) do
				if comp.Model and comp.Model.Parent then comp.Model:Destroy() end
			end
			G.Runtime[p]=nil
		end
		D.Release(p)
		for _,e in ipairs(G.Enemies) do
			e.Contributors[p]=nil
			if e.Party then e.Party[p]=nil end
			if e.Target==p then e.Target=nil end
			if e.ColosseumTarget==p then e.ColosseumTarget=nil end
			if e._raidCounted then e._raidCounted[p]=nil end
		end
	end)
	for _,p in ipairs(Players:GetPlayers()) do task.spawn(G.Join,p) end

	task.spawn(function()
		-- Một lỗi trong quái hoặc người chơi chỉ được bỏ qua đúng phần đó, không được giết vòng lặp của cả server.
		local tickErrAt={}
		local function safeTick(tag,fn,...)
			local ok,err=xpcall(fn,debug.traceback,...)
			if not ok and os.clock()>=(tickErrAt[tag] or 0) then
				tickErrAt[tag]=os.clock()+10
				warn("[SKYBREAK][MainLoop] "..tag..": "..tostring(err))
			end
		end
		local sync=0 local previous=os.clock()
		while true do
			task.wait(.04) local now=os.clock() local dt=math.min(now-previous,.25) previous=now sync+=dt
			local playerRoots={}
			for p in pairs(G.Runtime) do
				local pr=root(p)
				if pr then table.insert(playerRoots,pr.Position) end
			end
			for i=#G.Enemies,1,-1 do
				local e=G.Enemies[i]
				if not e.Alive or not e.Model.Parent then
					table.remove(G.Enemies,i)
				else
					local isNear=false
					local bpos=e.Body and e.Body.Position or e.Home
					for _,ppos in ipairs(playerRoots) do
						if (bpos-ppos).Magnitude<=220 then
							isNear=true
							break
						end
					end
					if isNear or e==G.Boss or e.Returning or e.State=="Chase" or e.State=="Attack" then
						local eDt=now-(e.LastTickAt or (now-dt))
						e.LastTickAt=now
						safeTick("Enemy:"..tostring(e.Id),G.TickEnemy,e,math.min(eDt,.25))
					elseif now>=(e.NextFarTick or 0) then
						local eDt=now-(e.LastTickAt or (now-.4))
						e.LastTickAt=now
						e.NextFarTick=now+.4
						safeTick("Enemy:"..tostring(e.Id),G.TickEnemy,e,math.min(eDt,.5))
					end
				end
			end
			for p,rt in pairs(G.Runtime) do
				safeTick("Player:"..p.Name,function()
				local r,h=root(p) local profile=D.Get(p)
				if r and profile then
					ensureProfileFields(profile)
					if now>=(rt.NextOneSecTick or 0) then
						rt.NextOneSecTick=now+1
						local rem=math.max(0,math.floor(tonumber(profile.DoubleExpRemainingSec) or 0))
						if rem>0 then
							rem-=1
							profile.DoubleExpRemainingSec=rem
							profile.DoubleExpRemaining=rem
							profile.DoubleExpSeconds=rem
							profile.DoubleExpUntil=rem>0 and (os.time()+rem) or 0
							p:SetAttribute("DoubleExpSeconds",rem)
						elseif (tonumber(p:GetAttribute("DoubleExpSeconds")) or 0)>0 then
							p:SetAttribute("DoubleExpSeconds",0)
							profile.DoubleExpUntil=0
						end
					end
					if now>=(rt.NextInstinctRegen or 0) then
						rt.NextInstinctRegen=now+5
						if profile.Haki then
							local nextDodges=math.min(8,(profile.Haki.InstinctDodges or 8)+1)
							if nextDodges~=profile.Haki.InstinctDodges then
								profile.Haki.InstinctDodges=nextDodges
								p:SetAttribute("InstinctDodges",nextDodges)
								if p.Character then p.Character:SetAttribute("InstinctDodges",nextDodges) end
							end
						end
					end
					if now>=(rt.JumpPadUntil or 0) then
						local elapsed=now-rt.MoveAt local delta=r.Position-rt.Safe
						local horizontal=_V3(delta.X,0,delta.Z).Magnitude
						if not finiteVector(r.Position) or horizontal>math.max(48,elapsed*140) then G.Teleport(p,rt.Safe,nil,true)
						else rt.Safe=r.Position rt.MoveAt=now end
						if now>=(rt.NextVoidCheck or 0) then
							rt.NextVoidCheck=now+.2
							local hit=W.RaycastGround and W.RaycastGround(r.Position,r.Position.Y-3.5) or nil
							local isOnSolidFloor=hit and hit.Instance and hit.Instance.CanCollide and hit.Position.Y>12
								and (not h or h.FloorMaterial~=Enum.Material.Air)
								and math.abs(r.AssemblyLinearVelocity.Y)<8
								and math.abs((r.Position.Y-3.0)-hit.Position.Y)<=5.5
								and not (W.IsBlockedByObstacle and W.IsBlockedByObstacle(r.Position.X,hit.Position.Y,r.Position.Z,3.8))
							if isOnSolidFloor then
								local gx,gz,gy=r.Position.X,r.Position.Z,hit.Position.Y
								local allNeighborsGrounded=true
								for _,off in ipairs({{3.0,0},{-3.0,0},{0,3.0},{0,-3.0}}) do
									local nh=W.RaycastGround(_V3(gx+off[1],gy+8,gz+off[2]),gy)
									if not nh or math.abs(nh.Position.Y-gy)>3.5 then
										allNeighborsGrounded=false
										break
									end
								end
								if allNeighborsGrounded then
									rt.LastGroundedPos=_V3(gx,gy+3.5,gz)
								end
							elseif hit and (not h or h.FloorMaterial~=Enum.Material.Air) and math.abs(r.AssemblyLinearVelocity.Y)<4 and (r.Position.Y-3.0-hit.Position.Y)>7.5 and (W.IsBlockedByObstacle and W.IsBlockedByObstacle(r.Position.X,hit.Position.Y,r.Position.Z,2.5)) then
								-- Player is standing on the invisible roof of a Solid3DObstacles box above the deck
								local rescue=G.FindSafeRescuePos(p,r.Position,rt,profile)
								G.Teleport(p,rescue,nil,true)
							elseif not (h and h.SeatPart) and not rt.SeatedInShip and (r.Position.Y<10 or (p:GetAttribute("SkybreakFlightActive")~=true and rt.LastGroundedPos and r.Position.Y<(rt.LastGroundedPos.Y-32) and not hit)) then
								if not (G.OnVoidRescue and G.OnVoidRescue(p,r,rt,profile)) then
									local rescue=G.FindSafeRescuePos(p,r.Position,rt,profile)
									G.Teleport(p,rescue,nil,true)
									if now>=(rt.NextVoidNotify or 0) then
										rt.NextVoidNotify=now+2.5
										G.Notify(p,"Void Rescue: Đã đưa bạn trở lại mặt sàn đảo mây an toàn!")
									end
								end
							end
						end
					else
						rt.Safe=r.Position rt.MoveAt=now
					end
					if now>=(rt.ShrineTouchCooldown or 0) then
						for _,sh in pairs(G.Shrines) do
							if distance(r.Position,sh.Pos)<=8 then
								rt.ShrineTouchCooldown=now+12
								G.ActivateShrine(p,sh)
								break
							end
						end
					end
					if now>=(rt.PortalTouchCooldown or 0) and G.WorldPortals then
						for _,gate in pairs(G.WorldPortals) do
							if distance(r.Position,gate.CenterPos)<=4.6 then
								G.EnterWorldPortal(p,gate)
								break
							end
						end
					end
					rt.Stamina=math.min(100,rt.Stamina+17*dt)
					local maxE=tonumber(rt.MaxEnergy) or 100
					if now-(rt.LastCastAt or 0)>=1.5 and now>=(rt.ActionUntil or 0) then rt.Energy=math.min(maxE,(rt.Energy or maxE)+maxE*0.08*dt) end
					if h.Health>0 and now-rt.LastHurt>7 then h.Health=math.min(h.MaxHealth,h.Health+3*dt) end
				end
				if sync>=.3 then G.Sync(p) end
				end)
			end
			if sync>=.3 then sync=0 end
		end
	end)
	print("[SKYBREAK] Grand Sky Seas v11 initialized. Studio persistence:",C.StudioPersistence)
end
return G
