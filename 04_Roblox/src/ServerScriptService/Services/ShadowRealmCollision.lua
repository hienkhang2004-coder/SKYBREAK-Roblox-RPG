-- Offline generated proposal. Review and invoke manually after importing art.
-- 1 intended Blender unit = 1 Roblox stud; verify importer scale before calling.
-- Does not change sky/lighting or import/upload meshes.
return function(parent)
    assert(not parent:FindFirstChild("ShadowRealm_Collision"), "ShadowRealm_Collision already exists")
    local folder = Instance.new("Folder")
    folder.Name = "ShadowRealm_Collision"
    folder.Parent = parent
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-Spawn_Floor"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(2.0000000, 78.1200000, 78.1200000)
        p.CFrame = CFrame.new(-165.00000000, 47.02999878, 95.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000) * CFrame.Angles(0, 0, math.pi / 2)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-Spawn"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(2.0000000, 66.0000000, 66.0000000)
        p.CFrame = CFrame.new(-165.00000000, 47.29999924, 95.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000) * CFrame.Angles(0, 0, math.pi / 2)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-RuinedOutpost_Floor"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(2.0000000, 61.3800000, 61.3800000)
        p.CFrame = CFrame.new(-70.00000000, 52.02999878, 125.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000) * CFrame.Angles(0, 0, math.pi / 2)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-RuinedOutpost"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(2.0000000, 48.0000000, 48.0000000)
        p.CFrame = CFrame.new(-70.00000000, 52.29999924, 125.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000) * CFrame.Angles(0, 0, math.pi / 2)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-VoidPlaza_Floor"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(2.0000000, 91.1400000, 91.1400000)
        p.CFrame = CFrame.new(5.00000000, 57.02999878, 35.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000) * CFrame.Angles(0, 0, math.pi / 2)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-VoidPlaza"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(2.0000000, 84.0000000, 84.0000000)
        p.CFrame = CFrame.new(5.00000000, 57.29999924, 35.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000) * CFrame.Angles(0, 0, math.pi / 2)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-NoxarArena_Floor"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(2.0000000, 85.5600000, 85.5600000)
        p.CFrame = CFrame.new(95.00000000, 65.02999878, -55.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000) * CFrame.Angles(0, 0, math.pi / 2)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-NoxarArena"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(2.0000000, 76.0000000, 76.0000000)
        p.CFrame = CFrame.new(95.00000000, 65.30000305, -55.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000) * CFrame.Angles(0, 0, math.pi / 2)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-CitadelMassif_Floor"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(2.0000000, 191.5800000, 191.5800000)
        p.CFrame = CFrame.new(-5.00000000, 75.02999878, -190.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000) * CFrame.Angles(0, 0, math.pi / 2)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-CitadelTerrace0"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(2.0000000, 176.0000000, 176.0000000)
        p.CFrame = CFrame.new(-5.00000000, 76.30000305, -190.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000) * CFrame.Angles(0, 0, math.pi / 2)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-CitadelTerrace1"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(2.0000000, 166.0000000, 166.0000000)
        p.CFrame = CFrame.new(-5.00000000, 77.30000305, -190.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000) * CFrame.Angles(0, 0, math.pi / 2)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-CitadelTerrace2"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(2.0000000, 156.0000000, 156.0000000)
        p.CFrame = CFrame.new(-5.00000000, 78.30000305, -190.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000) * CFrame.Angles(0, 0, math.pi / 2)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-CitadelTerrace3"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(2.0000000, 146.0000000, 146.0000000)
        p.CFrame = CFrame.new(-5.00000000, 79.30000305, -190.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000) * CFrame.Angles(0, 0, math.pi / 2)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-CitadelTerrace4"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(2.0000000, 136.0000000, 136.0000000)
        p.CFrame = CFrame.new(-5.00000000, 80.30000305, -190.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000) * CFrame.Angles(0, 0, math.pi / 2)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-CitadelTerrace5"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(2.0000000, 126.0000000, 126.0000000)
        p.CFrame = CFrame.new(-5.00000000, 81.30000305, -190.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000) * CFrame.Angles(0, 0, math.pi / 2)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-CitadelGrandStep0"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(18.0000000, 0.5000000, 2.6000000)
        p.CFrame = CFrame.new(-5.00000000, 76.55000305, -100.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-CitadelGrandStep1"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(18.0000000, 0.5000000, 2.6000000)
        p.CFrame = CFrame.new(-5.00000000, 77.05000305, -102.50000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-CitadelGrandStep2"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(18.0000000, 0.5000000, 2.6000000)
        p.CFrame = CFrame.new(-5.00000000, 77.55000305, -105.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-CitadelGrandStep3"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(18.0000000, 0.5000000, 2.6000000)
        p.CFrame = CFrame.new(-5.00000000, 78.05000305, -107.50000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-CitadelGrandStep4"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(18.0000000, 0.5000000, 2.6000000)
        p.CFrame = CFrame.new(-5.00000000, 78.55000305, -110.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-CitadelGrandStep5"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(18.0000000, 0.5000000, 2.6000000)
        p.CFrame = CFrame.new(-5.00000000, 79.05000305, -112.50000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-CitadelGrandStep6"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(18.0000000, 0.5000000, 2.6000000)
        p.CFrame = CFrame.new(-5.00000000, 79.55000305, -115.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-CitadelGrandStep7"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(18.0000000, 0.5000000, 2.6000000)
        p.CFrame = CFrame.new(-5.00000000, 80.05000305, -117.50000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-CitadelGrandStep8"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(18.0000000, 0.5000000, 2.6000000)
        p.CFrame = CFrame.new(-5.00000000, 80.55000305, -120.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-CitadelGrandStep9"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(18.0000000, 0.5000000, 2.6000000)
        p.CFrame = CFrame.new(-5.00000000, 81.05000305, -122.50000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-CitadelGrandStep10"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(18.0000000, 0.5000000, 2.6000000)
        p.CFrame = CFrame.new(-5.00000000, 81.55000305, -125.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-CitadelGrandStep11"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(18.0000000, 0.5000000, 2.6000000)
        p.CFrame = CFrame.new(-5.00000000, 82.05000305, -127.50000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-SpawnToRuinedOutpost_Rail"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(41.7185461, 3.8000000, 0.6000000)
        p.CFrame = CFrame.new(-119.88175201, 52.70000076, 117.86028290, 0.90190268, -0.11074839, -0.41750017, 0.12187874, 0.99254501, 0.00000000, 0.41438773, -0.05088440, 0.90867686)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-SpawnToRuinedOutpost_Rail.001"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(41.7185461, 3.8000000, 0.6000000)
        p.CFrame = CFrame.new(-113.11824799, 52.70000076, 103.13971710, 0.90190268, -0.11074839, -0.41750017, 0.12187874, 0.99254501, 0.00000000, 0.41438773, -0.05088440, 0.90867686)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-SpawnToRuinedOutpost_Floor"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(41.7185461, 1.4000000, 15.0000000)
        p.CFrame = CFrame.new(-116.50000000, 50.09999847, 110.50000000, 0.90190268, -0.11074839, -0.41750017, 0.12187874, 0.99254501, 0.00000000, 0.41438773, -0.05088440, 0.90867686)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-OutpostToVoid_Rail"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(53.2015325, 3.8000000, 0.6000000)
        p.CFrame = CFrame.new(-30.98295021, 57.70000076, 90.81020355, 0.59114677, -0.05662160, 0.80457407, 0.09534626, 0.99544418, 0.00000000, -0.80090857, 0.07671313, 0.59385228)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-OutpostToVoid_Rail.001"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(53.2015325, 3.8000000, 0.6000000)
        p.CFrame = CFrame.new(-44.01705170, 57.70000076, 81.18979645, 0.59114677, -0.05662160, 0.80457407, 0.09534626, 0.99544418, 0.00000000, -0.80090857, 0.07671313, 0.59385228)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-OutpostToVoid_Floor"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(53.2015325, 1.4000000, 15.0000000)
        p.CFrame = CFrame.new(-37.50000000, 55.09999847, 86.00000000, 0.59114677, -0.05662160, 0.80457407, 0.09534626, 0.99544418, 0.00000000, -0.80090857, 0.07671313, 0.59385228)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-VoidToNoxar_Rail"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(45.1021541, 3.8000000, 0.6000000)
        p.CFrame = CFrame.new(56.79558563, 64.20000458, -1.09205151, 0.53545284, -0.09712961, 0.83896130, 0.17848438, 0.98394275, 0.00000000, -0.82548988, 0.14974149, 0.54419106)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-VoidToNoxar_Rail.001"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(45.1021541, 3.8000000, 0.6000000)
        p.CFrame = CFrame.new(43.20441437, 64.20000458, -9.90794849, 0.53545284, -0.09712961, 0.83896130, 0.17848438, 0.98394275, 0.00000000, -0.82548988, 0.14974149, 0.54419106)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-VoidToNoxar_Floor"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(45.1021541, 1.4000000, 15.0000000)
        p.CFrame = CFrame.new(50.00000000, 61.60000229, -5.50000000, 0.53545284, -0.09712961, 0.83896130, 0.17848438, 0.98394275, 0.00000000, -0.82548988, 0.14974149, 0.54419106)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-NoxarArrivalApron"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(16.0000000, 1.4000000, 16.0000000)
        p.CFrame = CFrame.new(66.00000000, 65.59999847, -29.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-NoxarToCitadel_Rail"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(55.4885309, 3.8000000, 0.6000000)
        p.CFrame = CFrame.new(77.81325531, 73.20000458, -85.83975983, -0.66788745, 0.12257395, 0.73409945, 0.18051012, 0.98357314, 0.00000000, -0.72204047, 0.13251239, -0.67904198)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-NoxarToCitadel_Rail.001"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(55.4885309, 3.8000000, 0.6000000)
        p.CFrame = CFrame.new(65.18674469, 73.20000458, -74.16024017, -0.66788745, 0.12257395, 0.73409945, 0.18051012, 0.98357314, 0.00000000, -0.72204047, 0.13251239, -0.67904198)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-NoxarToCitadel_Floor"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(55.4885309, 1.4000000, 16.0000000)
        p.CFrame = CFrame.new(71.50000000, 70.60000610, -80.00000000, -0.66788745, 0.12257395, 0.73409945, 0.18051012, 0.98357314, 0.00000000, -0.72204047, 0.13251239, -0.67904198)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-CitadelLandingCauseway_Rail"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(45.2040722, 3.8000000, 0.6000000)
        p.CFrame = CFrame.new(46.30932617, 78.20000458, -122.75290680, -0.61080337, 0.00000000, 0.79178232, 0.00000000, 1.00000000, 0.00000000, -0.79178232, 0.00000000, -0.61080337)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-CitadelLandingCauseway_Rail.001"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(45.2040722, 3.8000000, 0.6000000)
        p.CFrame = CFrame.new(32.69067383, 78.20000458, -112.24709320, -0.61080337, 0.00000000, 0.79178232, 0.00000000, 1.00000000, 0.00000000, -0.79178232, 0.00000000, -0.61080337)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-CitadelLandingCauseway_Floor"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(45.2040722, 1.4000000, 16.0000000)
        p.CFrame = CFrame.new(39.50000000, 75.60000610, -117.50000000, -0.61080337, 0.00000000, 0.79178232, 0.00000000, 1.00000000, 0.00000000, -0.79178232, 0.00000000, -0.61080337)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-LeftVoidGate_Floor"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(2.0000000, 87.4200000, 87.4200000)
        p.CFrame = CFrame.new(-165.00000000, 71.02999878, -95.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000) * CFrame.Angles(0, 0, math.pi / 2)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-VoidGateLanding"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(2.0000000, 72.0000000, 72.0000000)
        p.CFrame = CFrame.new(-165.00000000, 71.30000305, -95.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000) * CFrame.Angles(0, 0, math.pi / 2)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-OptionalCube0"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(8.5000000, 5.0000000, 8.5000000)
        p.CFrame = CFrame.new(-46.00000000, 56.29999924, 26.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-OptionalCube1"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(8.5000000, 5.0000000, 8.5000000)
        p.CFrame = CFrame.new(-56.00000000, 57.65000153, 18.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-OptionalCube2"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(8.5000000, 5.0000000, 8.5000000)
        p.CFrame = CFrame.new(-66.00000000, 59.00000000, 10.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-OptionalCube3"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(8.5000000, 5.0000000, 8.5000000)
        p.CFrame = CFrame.new(-76.00000000, 60.34999847, 2.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-OptionalCube4"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(8.5000000, 5.0000000, 8.5000000)
        p.CFrame = CFrame.new(-86.00000000, 61.70000076, -6.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-OptionalCube5"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(8.5000000, 5.0000000, 8.5000000)
        p.CFrame = CFrame.new(-96.00000000, 63.04999924, -14.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-OptionalCube6"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(8.5000000, 5.0000000, 8.5000000)
        p.CFrame = CFrame.new(-106.00000000, 64.40000153, -22.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-OptionalCube7"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(8.5000000, 5.0000000, 8.5000000)
        p.CFrame = CFrame.new(-116.00000000, 65.75000000, -30.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-OptionalCube8"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(8.5000000, 5.0000000, 8.5000000)
        p.CFrame = CFrame.new(-126.00000000, 67.09999847, -38.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-OptionalCube9"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(8.5000000, 5.0000000, 8.5000000)
        p.CFrame = CFrame.new(-136.00000000, 68.44999695, -46.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-OptionalGateRest_Floor"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(2.0000000, 35.3400000, 35.3400000)
        p.CFrame = CFrame.new(-142.00000000, 71.02999878, -65.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000) * CFrame.Angles(0, 0, math.pi / 2)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-OptionalGateRest"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(2.0000000, 28.0000000, 28.0000000)
        p.CFrame = CFrame.new(-142.00000000, 71.30000305, -65.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000) * CFrame.Angles(0, 0, math.pi / 2)
        p.Parent = folder
    end
    return folder
end
