-- SKYBREAK: Fragments of the Core - Living Town NPCs, Villagers, Guards & Hub Rig Controller (#65)
-- Driven on RunService.Heartbeat and guarded by _G.SkybreakLivingNPCsStarted so it runs cleanly once.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Renderer = require(ReplicatedStorage:WaitForChild("DelegatedV5Renderer"))
local Sources = ReplicatedStorage:WaitForChild("DelegatedV5Sources")
local C = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local localPlayer = Players.LocalPlayer

-- 1. Hub Lyra & Kael Marker Rigging (when marker parts exist outside SkybreakWorldObjects)
local markerActors, markerTemplates, markerClips, markerPending = {}, {}, {}, {}

local function hideCharacterRig(model)
  for _, o in ipairs(model:GetDescendants()) do
    if o:IsA("BasePart") then
      o.LocalTransparencyModifier = 1
    elseif o:IsA("Decal") then
      o.Transparency = 1
    end
  end
end

local function registerHubMarker(marker)
  if not marker:IsA("BasePart") then return end
  if marker.Parent and marker.Parent:IsA("Model") and marker.Parent:GetAttribute("NPCId") then return end
  local id = marker:GetAttribute("InteractableId")
  if (id ~= "Lyra" and id ~= "Kael") or markerPending[marker] or markerActors[marker] or not Sources:FindFirstChild(id) then
    return
  end
  markerPending[marker] = true
  local ok, err = xpcall(function()
    markerTemplates[id] = markerTemplates[id] or Renderer.Build(id)
    markerClips[id] = markerClips[id] or Renderer.Clips(id, 2.6)
    if not marker.Parent then return end
    local visual = markerTemplates[id]:Clone()
    visual.Name = id .. "_BlenderVisual"
    visual:ScaleTo(2.6)
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local excl = { marker, marker.Parent }
    for _, fn in ipairs({ "ActiveNPCs", "ActiveEnemies", "SkybreakWorldObjects", "TempFX" }) do
      local f = workspace:FindFirstChild(fn)
      if f then table.insert(excl, f) end
    end
    rayParams.FilterDescendantsInstances = excl
    local hit = workspace:Raycast(marker.Position + Vector3.new(0, 12, 0), Vector3.new(0, -28, 0), rayParams)
    local floorY = (hit and hit.Position.Y) or math.max(46.5, marker.Position.Y - 2.5)
    local floor = Vector3.new(marker.Position.X, floorY, marker.Position.Z)
    local spawnPos = C.Spawn or Vector3.new(-317.4, 50.5, 527.8)
    local facing = CFrame.lookAt(floor, Vector3.new(spawnPos.X, floor.Y, spawnPos.Z))
    visual:PivotTo(facing)
    visual.Parent = marker.Parent

    local old = marker.Parent:FindFirstChild(id .. "Character")
    if old then hideCharacterRig(old) end
    local conn = marker.Parent.ChildAdded:Connect(function(o)
      if o.Name == id .. "Character" then hideCharacterRig(o) end
    end)
    local prop = nil
    if id == "Kael" and Sources:FindFirstChild("KaelWorkstation") then
      prop = Renderer.Build("KaelWorkstation"):Clone()
      prop.Name = "Kael_Anvil"
      prop:ScaleTo(2.6)
      prop:PivotTo(facing)
      prop.Parent = marker.Parent
    end
    local defClip = (id == "Kael" and markerClips[id].HammerWork) and "HammerWork" or "Idle"
    markerActors[marker] = {
      Model = visual, Clips = markerClips[id], Default = defClip, Name = defClip,
      Start = os.clock(), Event = marker:GetAttribute("NPCTalkAt") or 0, BaseCF = facing, YawOffset = 0, Connection = conn, Prop = prop,
    }
    marker:SetAttribute("BlenderNPCReady", true)
  end, debug.traceback)
  markerPending[marker] = nil
  if not ok then warn("[SKYBREAK NPC]", id, err) end
end

for _, o in ipairs(workspace:GetDescendants()) do task.spawn(registerHubMarker, o) end
workspace.DescendantAdded:Connect(function(o) task.spawn(registerHubMarker, o) end)

local markerAccum = 0
RunService.Heartbeat:Connect(function(dt)
  markerAccum += dt
  if markerAccum < 1 / 30 then return end
  local stepDt = markerAccum
  markerAccum = 0
  local now = os.clock()
  local ch = localPlayer and localPlayer.Character
  local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
  local playerPos = hrp and hrp.Position or nil

  for marker, s in pairs(markerActors) do
    if not marker.Parent then
      s.Connection:Disconnect()
      if s.Model then s.Model:Destroy() end
      if s.Prop then s.Prop:Destroy() end
      markerActors[marker] = nil
      continue
    end
    local event = marker:GetAttribute("NPCTalkAt") or 0
    if event ~= s.Event then
      s.Event = event
      s.Name = (s.Clips.Talk and "Talk") or (s.Clips.Wave and "Wave") or s.Default
      s.Start = now
    end
    local clip = s.Clips[s.Name] or s.Clips[s.Default]
    if s.Name ~= s.Default and clip and now - s.Start >= (clip.Duration or 1.6) then
      s.Name, s.Start = s.Default, now
      clip = s.Clips[s.Name]
    end
    if clip then
      if not clip.Loop and now - s.Start >= (clip.Duration or 1.6) then s.Start = now end
      Renderer.Pose(s.Model, clip, now - s.Start)
    end
    local desiredYaw = 0
    if playerPos then
      local delta = playerPos - s.BaseCF.Position
      if delta.Magnitude <= 18 and delta.Magnitude > 0.5 then
        local localDir = s.BaseCF:VectorToObjectSpace(Vector3.new(delta.X, 0, delta.Z).Unit)
        desiredYaw = math.clamp(math.atan2(-localDir.X, -localDir.Z), -0.65, 0.65)
      end
    end
    s.YawOffset += (desiredYaw - s.YawOffset) * (1 - math.exp(-7 * stepDt))
    s.Model:PivotTo(s.BaseCF * CFrame.Angles(0, s.YawOffset, 0))
  end
end)

-- 2. Shared Living Villagers, Watch Guards & Ambient Lore Speech Bubble Controller (#65)
local LORE_LINES = {
  Citizen = {
    "Mảnh Core Shards giữ cho các quần đảo lơ lửng trên biển mây Aether.",
    "Nghe nói Hải Tặc Bầu Trời của Vance đang tập kết ở West Garden!",
    "Rơi xuống biển mây đừng lo, mạch Sky-Geyser sẽ đẩy bạn bay ngược lên bến cảng.",
    "Đến Zioles Gacha Shrine thử vận may xem, biết đâu quay trúng Trái Thần Thoại!",
  },
  Guard = {
    "[CẢNH VỆ] Khu vực Sky Hub an toàn. Hãy cẩn thận khi vượt cổng sang Sky 2!",
    "[CẢNH VỆ] Thủy quái Abyssal Leviathan chỉ trồi lên ở vùng biển sâu Sky 3.",
    "[CẢNH VỆ] Đạt 10 Triệu Bounty sẽ triệu hồi được SkySeaBeast hộ vệ!",
    "[CẢNH VỆ] Chiến hạm Aether Galleon đã sẵn sàng tại bến cảng cho Sky Crew.",
  },
  Master = {
    "Luyện thành thục 4 đòn M1 Kata để khai mở tuyệt kỹ Celestial Godhuman!",
    "Đạt Mastery Lv.600 trên võ thuật và vũ khí sẽ mở khóa danh hiệu Đại Tông Sư.",
    "Kết hợp Busoshoku Haki Stage 5 và Kenbunshoku V2 để áp đảo mọi Boss!",
  },
  Merchant = {
    "Kael có thể nâng cấp Thần Khí lên 5 Sao và khắc phù phép tại lò rèn Aether.",
    "Mirage Fruit Stock làm mới mỗi giờ, hoặc ghé Cyberport Café giao dịch 4 ghế!",
    "Thu thập Microchip tại Raid Lab Sky 2 để Thức Tỉnh V2 toàn bộ chiêu Trái Ác Quỷ!",
  },
  Greet = {
    "Chào chiến binh Skyborn! Chúc hành trình thuận buồm xuôi gió.",
    "Gió Aether hôm nay rất thuận lợi để ra khơi chinh phục bầu trời!",
    "Cần hỗ trợ hãy nhấn [E] trò chuyện nhé, lữ khách!",
  },
}

local AMBIENT_SPAWN_SPECS = {
  { Name = "SkyHub_WatchGuard_West", Asset = "SunshardRoyalGuard", Role = "Guard", Label = "Thiết Giáp Cảnh Vệ • Sky Watch", Pos = Vector3.new(-334.0, 49.5, 542.0), Face = Vector3.new(-317.4, 49.5, 527.8) },
  { Name = "SkyHub_WatchGuard_Gate", Asset = "SunshardRoyalGuard", Role = "Guard", Label = "Thủ Vệ Cổng Không Gian • Gate Guard", Pos = Vector3.new(-296.0, 49.5, 550.0), Face = Vector3.new(-317.4, 49.5, 527.8) },
  { Name = "SkyHub_Villager_Aria", Asset = "Female_Adventurer", Role = "Citizen", Label = "Cư Dân Bầu Trời • Aria", Pos = Vector3.new(-308.0, 49.5, 515.0), Face = Vector3.new(-321.0, 49.5, 523.0) },
  { Name = "SkyHub_Villager_Toma", Asset = "Male_Novice", Role = "Citizen", Label = "Học Giả Aether • Toma", Pos = Vector3.new(-326.0, 49.5, 513.0), Face = Vector3.new(-314.0, 49.5, 523.0) },
  { Name = "Cyberport_Patron_Lin", Asset = "Female_Adventurer", Role = "Merchant", Label = "Thương Khách Café • Lin", Pos = Vector3.new(9376.0, 49.9, 1780.0), Face = Vector3.new(9400.0, 49.9, 1785.0) },
  { Name = "CastleVoid_Sentinel_Korr", Asset = "Male_SkyGuardian", Role = "Guard", Label = "Hộ Vệ Dinh Thự • Korr", Pos = Vector3.new(-14578.0, 49.9, 2160.0), Face = Vector3.new(-14600.0, 49.9, 2173.1) },
}

local function classifyNPCRole(inst)
  local n = (tostring(inst.Name) .. " " .. tostring(inst:GetAttribute("NPCId") or "") .. " " .. tostring(inst:GetAttribute("InteractableId") or "")):lower()
  if n:find("guard") or n:find("sentinel") or n:find("vanguard") or n:find("commander") or n:find("warden") then
    return "Guard"
  elseif n:find("master") or n:find("monk") or n:find("swordmaster") or n:find("dojo") then
    return "Master"
  elseif n:find("zioles") or n:find("kael") or n:find("mirage") or n:find("broker") or n:find("vega") or n:find("cafe") or n:find("shipwright") or n:find("smith") then
    return "Merchant"
  end
  return "Citizen"
end

local function createSpeechBubble(adornee, role)
  local existing = adornee:FindFirstChild("SkybreakLivingSpeech")
  if existing then
    return existing, existing:FindFirstChild("BubbleFrame") and existing.BubbleFrame:FindFirstChild("SpeechText")
  end
  local bill = Instance.new("BillboardGui")
  bill.Name = "SkybreakLivingSpeech"
  bill.Size = UDim2.fromOffset(250, 48)
  bill.StudsOffset = Vector3.new(0, 5.1, 0)
  bill.MaxDistance = 42
  bill.Enabled = false
  bill.Parent = adornee

  local frame = Instance.new("Frame")
  frame.Name = "BubbleFrame"
  frame.Size = UDim2.fromScale(1, 1)
  frame.BackgroundColor3 = Color3.fromRGB(10, 15, 26)
  frame.BackgroundTransparency = 0.14
  frame.BorderSizePixel = 0
  frame.Parent = bill

  local corner = Instance.new("UICorner")
  corner.CornerRadius = UDim.new(0, 9)
  corner.Parent = frame

  local stroke = Instance.new("UIStroke")
  stroke.Color = (role == "Guard" and Color3.fromRGB(106, 214, 248))
    or (role == "Master" and Color3.fromRGB(244, 188, 84))
    or (role == "Merchant" and Color3.fromRGB(122, 236, 186))
    or Color3.fromRGB(224, 198, 132)
  stroke.Thickness = 1.3
  stroke.Transparency = 0.2
  stroke.Parent = frame

  local txt = Instance.new("TextLabel")
  txt.Name = "SpeechText"
  txt.Size = UDim2.new(1, -16, 1, -8)
  txt.Position = UDim2.fromOffset(8, 4)
  txt.BackgroundTransparency = 1
  txt.Font = Enum.Font.GothamMedium
  txt.TextSize = 11
  txt.TextWrapped = true
  txt.TextColor3 = Color3.fromRGB(238, 242, 250)
  txt.Text = ""
  txt.Parent = frame
  return bill, txt
end

function _G.SkybreakStartLivingNPCs()
  if _G.SkybreakLivingNPCsStarted or workspace:GetAttribute("SkybreakLivingNPCsActive") == true then return end
  _G.SkybreakLivingNPCsStarted = true
  workspace:SetAttribute("SkybreakLivingNPCsActive", true)

  local tracked, ambientTemplates, ambientClips = {}, {}, {}

  local function registerEntry(keyInst, rootPart, rigModel, role, isSpawnedRig, assetName)
    if not keyInst or not rootPart or tracked[keyInst] then return end
    local bill, txt = createSpeechBubble(rootPart, role)
    local neck = rigModel and rigModel:FindFirstChild("Neck", true)
    local waist = rigModel and rigModel:FindFirstChild("Waist", true)
    local rShoulder = rigModel and (rigModel:FindFirstChild("RightShoulder", true) or rigModel:FindFirstChild("Right Shoulder", true))
    local headBone = rigModel and rigModel:FindFirstChild("Head", true)
    if headBone and not headBone:IsA("Bone") then headBone = nil end
    local armBone = rigModel and rigModel:FindFirstChild("RightUpperArm", true)
    if armBone and not armBone:IsA("Bone") then armBone = nil end

    tracked[keyInst] = {
      Inst = keyInst, Root = rootPart, Rig = rigModel, Role = role,
      IsSpawnedRig = isSpawnedRig == true, AssetName = assetName,
      Billboard = bill, Label = txt, BaseCF = rootPart.CFrame,
      RigBasePivot = rigModel and rigModel:GetPivot() or rootPart.CFrame,
      Neck = (neck and neck:IsA("Motor6D")) and neck or nil,
      NeckC0 = (neck and neck:IsA("Motor6D")) and neck.C0 or nil,
      Waist = (waist and waist:IsA("Motor6D")) and waist or nil,
      WaistC0 = (waist and waist:IsA("Motor6D")) and waist.C0 or nil,
      RightShoulder = (rShoulder and rShoulder:IsA("Motor6D")) and rShoulder or nil,
      RightShoulderC0 = (rShoulder and rShoulder:IsA("Motor6D")) and rShoulder.C0 or nil,
      HeadBone = headBone, ArmBone = armBone, Yaw = 0,
      Phase = math.random() * math.pi * 2, LineIndex = math.random(1, 4),
      NextSpeechAt = os.clock() + math.random() * 7 + 1.5,
      SpeechHideAt = 0, LastGreetAt = -20, WaveUntil = 0, WasNear = false,
    }
  end

  local function scanCandidate(obj)
    if not obj or tracked[obj] then return end
    if obj:IsA("Model") then
      local mName = obj.Name
      if mName:match("^Citizen%d") or obj:GetAttribute("NPCId") or (obj.Parent and (obj.Parent.Name == "InteractiveNPCs" or obj.Parent.Name == "ActiveNPCs")) then
        if mName:find("AncientAetherFruitTrees") or mName:find("Ship") or mName:find("Galleon") then return end
        local root = obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChild("Body") or obj:FindFirstChild("NPCPillar") or obj:FindFirstChildWhichIsA("BasePart")
        if root then registerEntry(obj, root, obj, classifyNPCRole(obj), false, nil) end
      end
    elseif obj:IsA("BasePart") then
      local id = tostring(obj:GetAttribute("InteractableId") or "")
      if id:match("^Citizen%d") then
        registerEntry(obj, obj, obj.Parent and obj.Parent:FindFirstChild(id .. "Character"), "Citizen", false, nil)
      end
    end
  end

  task.spawn(function()
    local townFolder = workspace:FindFirstChild("SkybreakLivingTownNPCs") or Instance.new("Folder")
    townFolder.Name = "SkybreakLivingTownNPCs"
    townFolder.Parent = workspace

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    local excl = { townFolder }
    for _, fn in ipairs({ "ActiveNPCs", "ActiveEnemies", "SkybreakWorldObjects", "SkybreakWorld3DProps", "TempFX", "WorldPortals", "SkybreakSeaPlanes", "SkybreakVFXDebris" }) do
      local f = workspace:FindFirstChild(fn)
      if f then table.insert(excl, f) end
    end
    rayParams.FilterDescendantsInstances = excl

    for _, spec in ipairs(AMBIENT_SPAWN_SPECS) do
      if not townFolder:FindFirstChild(spec.Name) and Sources:FindFirstChild(spec.Asset) then
        local okB, built = pcall(function()
          ambientTemplates[spec.Asset] = ambientTemplates[spec.Asset] or Renderer.Build(spec.Asset)
          ambientClips[spec.Asset] = ambientClips[spec.Asset] or Renderer.Clips(spec.Asset, 2.6)
          return ambientTemplates[spec.Asset]
        end)
        if okB and built then
          local hit = workspace:Raycast(spec.Pos + Vector3.new(0, 14, 0), Vector3.new(0, -32, 0), rayParams)
          local floorY = hit and hit.Position.Y or (spec.Pos.Y - 4.0)
          local baseCF = CFrame.lookAt(Vector3.new(spec.Pos.X, floorY, spec.Pos.Z), Vector3.new(spec.Face.X, floorY, spec.Face.Z))
          local clone = built:Clone()
          clone.Name = spec.Name
          clone:ScaleTo(2.6)
          for _, d in ipairs(clone:GetDescendants()) do
            if d:IsA("BasePart") then
              d.Anchored, d.CanCollide, d.CanQuery, d.CanTouch, d.CastShadow = true, false, false, false, false
            end
          end
          clone:PivotTo(baseCF)
          clone:SetAttribute("LivingTownNPC", true)
          clone.Parent = townFolder
          if clone.PrimaryPart then
            local nb = Instance.new("BillboardGui")
            nb.Name = "TownNameTag"
            nb.Size = UDim2.fromOffset(190, 22)
            nb.StudsOffset = Vector3.new(0, 3.9, 0)
            nb.MaxDistance = 36
            nb.Parent = clone.PrimaryPart
            local nl = Instance.new("TextLabel")
            nl.Size = UDim2.fromScale(1, 1)
            nl.BackgroundTransparency = 1
            nl.Font = Enum.Font.GothamBold
            nl.TextSize = 11
            nl.TextColor3 = (spec.Role == "Guard") and Color3.fromRGB(132, 224, 255) or Color3.fromRGB(242, 214, 138)
            nl.TextStrokeTransparency = 0.25
            nl.Text = spec.Label
            nl.Parent = nb
            registerEntry(clone, clone.PrimaryPart, clone, spec.Role, true, spec.Asset)
            tracked[clone].BaseCF, tracked[clone].RigBasePivot = baseCF, baseCF
          end
        end
        task.wait(0.05)
      end
    end
    for _, desc in ipairs(workspace:GetDescendants()) do scanCandidate(desc) end
    workspace.DescendantAdded:Connect(function(desc) task.defer(scanCandidate, desc) end)
  end)

  RunService.Heartbeat:Connect(function(dt)
    dt = math.clamp(dt, 1 / 240, 0.12)
    local now = os.clock()
    local ch = localPlayer and localPlayer.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    local pPos = hrp and hrp.Position or nil

    for key, e in pairs(tracked) do
      if not e.Inst.Parent or not e.Root.Parent then
        if e.Billboard and e.Billboard.Parent then e.Billboard:Destroy() end
        tracked[key] = nil
        continue
      end
      local npcPos = e.Root.Position
      local dist = pPos and (pPos - npcPos).Magnitude or 999
      if dist > 480 then
        if e.Billboard.Enabled then e.Billboard.Enabled = false end
        continue
      end
      local isNear = dist <= 18
      if isNear and not e.WasNear and (now - e.LastGreetAt) >= 14 then
        e.LastGreetAt, e.WaveUntil = now, now + 1.85
        e.Inst:SetAttribute("NPCTalkAt", now)
        e.Label.Text = LORE_LINES.Greet[math.random(1, #LORE_LINES.Greet)]
        e.Billboard.Enabled, e.SpeechHideAt, e.NextSpeechAt = true, now + 4.8, now + 10.5
      elseif now >= e.NextSpeechAt and dist <= 44 then
        local pool = LORE_LINES[e.Role] or LORE_LINES.Citizen
        e.LineIndex = (e.LineIndex % #pool) + 1
        e.Label.Text = pool[e.LineIndex]
        e.Billboard.Enabled, e.SpeechHideAt, e.NextSpeechAt = true, now + 5.2, now + math.random(9, 14)
      elseif e.Billboard.Enabled and now >= e.SpeechHideAt then
        e.Billboard.Enabled = false
      end
      e.WasNear = isNear

      local targetYaw = 0
      if isNear and pPos and dist > 0.6 then
        local flatDelta = Vector3.new(pPos.X - npcPos.X, 0, pPos.Z - npcPos.Z)
        if flatDelta.Magnitude > 0.25 then
          local refCF = e.IsSpawnedRig and e.BaseCF or CFrame.new(npcPos) * e.RigBasePivot.Rotation
          local localDir = refCF:VectorToObjectSpace(flatDelta.Unit)
          targetYaw = math.clamp(math.atan2(-localDir.X, -localDir.Z), -0.82, 0.82)
        end
      end
      if e.Yaw ~= e.Yaw then e.Yaw = 0 end
      e.Yaw += (targetYaw - e.Yaw) * (1 - math.exp(-7.0 * dt))

      local breathe = math.sin(now * 2.15 + e.Phase) * 0.045
      local swayRoll = math.cos(now * 1.45 + e.Phase) * 0.018
      local waving = now < e.WaveUntil
      local waveAngle = waving and (0.95 + math.sin(now * 11.0) * 0.35) or 0

      if e.IsSpawnedRig and e.Rig and e.AssetName then
        local clips = ambientClips[e.AssetName]
        local clip = clips and ((waving and clips.Wave) or clips.Idle)
        if clip then Renderer.Pose(e.Rig, clip, now + e.Phase) end
        e.Rig:PivotTo(e.BaseCF * CFrame.new(0, breathe * 0.5, 0) * CFrame.Angles(0, e.Yaw * 0.65, swayRoll))
        if e.HeadBone and e.HeadBone.Parent then
          e.HeadBone.Transform *= CFrame.Angles(0, e.Yaw * 0.45, 0)
        end
      elseif e.Neck and e.NeckC0 then
        e.Neck.C0 = e.NeckC0 * CFrame.Angles(breathe * 0.4, e.Yaw * 0.72, 0)
        if e.Waist and e.WaistC0 then e.Waist.C0 = e.WaistC0 * CFrame.Angles(breathe * 0.3, e.Yaw * 0.28, swayRoll) end
        if e.RightShoulder and e.RightShoulderC0 then e.RightShoulder.C0 = e.RightShoulderC0 * CFrame.Angles(waveAngle, 0, waveAngle * 0.35) end
      elseif e.Rig and e.Rig.Parent and e.Rig.Parent.Name == "InteractiveNPCs" then
        e.Rig:PivotTo(e.RigBasePivot * CFrame.new(0, breathe, 0) * CFrame.Angles(0, e.Yaw * 0.55, swayRoll))
      elseif e.HeadBone and e.HeadBone.Parent then
        e.HeadBone.Transform *= CFrame.Angles(0, e.Yaw * 0.65, 0)
        if e.ArmBone and e.ArmBone.Parent and waving then
          e.ArmBone.Transform *= CFrame.Angles(waveAngle, 0, 0.25)
        end
      end
    end
  end)
end

_G.SkybreakStartLivingNPCs()
