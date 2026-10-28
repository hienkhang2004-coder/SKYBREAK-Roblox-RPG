-- Offline generated proposal. Review and invoke manually after importing art.
-- 1 intended Blender unit = 1 Roblox stud; verify importer scale before calling.
-- Does not change sky/lighting or import/upload meshes.
return function(parent)
    assert(not parent:FindFirstChild("GoldenSky_Collision"), "GoldenSky_Collision already exists")
    local folder = Instance.new("Folder")
    folder.Name = "GoldenSky_Collision"
    folder.Parent = parent
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-Spawn"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(2.0000000, 50.0000000, 50.0000000)
        p.CFrame = CFrame.new(-92.00000000, 35.02999878, 153.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000) * CFrame.Angles(0, 0, math.pi / 2)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-WestGarden"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(2.0000000, 42.0000000, 42.0000000)
        p.CFrame = CFrame.new(-91.00000000, 39.02999878, 61.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000) * CFrame.Angles(0, 0, math.pi / 2)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-LumenPlaza"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(2.0000000, 96.0000000, 96.0000000)
        p.CFrame = CFrame.new(0.00000000, 39.02999878, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000) * CFrame.Angles(0, 0, math.pi / 2)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-BossArena"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(2.0000000, 70.0000000, 70.0000000)
        p.CFrame = CFrame.new(0.00000000, 45.02999878, -104.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000) * CFrame.Angles(0, 0, math.pi / 2)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-CitadelLanding"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(2.0000000, 110.0000000, 110.0000000)
        p.CFrame = CFrame.new(0.00000000, 45.00000000, -182.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000) * CFrame.Angles(0, 0, math.pi / 2)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-CitadelTier0"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(2.0000000, 110.7600000, 110.7600000)
        p.CFrame = CFrame.new(0.00000000, 45.89699936, -182.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000) * CFrame.Angles(0, 0, math.pi / 2)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-CitadelTier1"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(2.0000000, 104.5200000, 104.5200000)
        p.CFrame = CFrame.new(0.00000000, 46.79399872, -182.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000) * CFrame.Angles(0, 0, math.pi / 2)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-CitadelTier2"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(2.0000000, 98.2800000, 98.2800000)
        p.CFrame = CFrame.new(0.00000000, 47.69100189, -182.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000) * CFrame.Angles(0, 0, math.pi / 2)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-CitadelTier3"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(2.0000000, 92.0400000, 92.0400000)
        p.CFrame = CFrame.new(0.00000000, 48.58800125, -182.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000) * CFrame.Angles(0, 0, math.pi / 2)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-CitadelTier4"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(2.0000000, 85.8000000, 85.8000000)
        p.CFrame = CFrame.new(0.00000000, 49.48500061, -182.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000) * CFrame.Angles(0, 0, math.pi / 2)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-ProcessionalStep0"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(14.0000000, 0.4500000, 2.0000000)
        p.CFrame = CFrame.new(0.00000000, 46.22999954, -132.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-ProcessionalStep1"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(14.0000000, 0.4500000, 2.0000000)
        p.CFrame = CFrame.new(0.00000000, 46.68000031, -133.89999390, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-ProcessionalStep2"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(14.0000000, 0.4500000, 2.0000000)
        p.CFrame = CFrame.new(0.00000000, 47.13000107, -135.80000305, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-ProcessionalStep3"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(14.0000000, 0.4500000, 2.0000000)
        p.CFrame = CFrame.new(0.00000000, 47.58000183, -137.69999695, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-ProcessionalStep4"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(14.0000000, 0.4500000, 2.0000000)
        p.CFrame = CFrame.new(0.00000000, 48.02999878, -139.60000610, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-ProcessionalStep5"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(14.0000000, 0.4500000, 2.0000000)
        p.CFrame = CFrame.new(0.00000000, 48.47999954, -141.50000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-ProcessionalStep6"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(14.0000000, 0.4500000, 2.0000000)
        p.CFrame = CFrame.new(0.00000000, 48.93000031, -143.39999390, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-ProcessionalStep7"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(14.0000000, 0.4500000, 2.0000000)
        p.CFrame = CFrame.new(0.00000000, 49.38000107, -145.30000305, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-ProcessionalStep8"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(14.0000000, 0.4500000, 2.0000000)
        p.CFrame = CFrame.new(0.00000000, 49.83000183, -147.19999695, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-ProcessionalStep9"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(14.0000000, 0.4500000, 2.0000000)
        p.CFrame = CFrame.new(0.00000000, 50.27999878, -149.10000610, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-SpawnToGarden_Ramp"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(49.0104155, 1.4000000, 14.0000000)
        p.CFrame = CFrame.new(-91.50000000, 37.29999924, 106.00000000, 0.02075693, -0.00172937, 0.99978304, 0.08302759, 0.99654722, 0.00000000, -0.99633104, 0.08300958, 0.02082884)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-SpawnToGarden_Guardrail"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(49.0104155, 4.6000000, 0.5000000)
        p.CFrame = CFrame.new(-83.90164948, 40.29999924, 106.15830231, 0.02075693, -0.00172937, 0.99978304, 0.08302759, 0.99654722, 0.00000000, -0.99633104, 0.08300958, 0.02082884)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-SpawnToGarden_Guardrail.001"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(49.0104155, 4.6000000, 0.5000000)
        p.CFrame = CFrame.new(-99.09835052, 40.29999924, 105.84169769, 0.02075693, -0.00172937, 0.99978304, 0.08302759, 0.99654722, 0.00000000, -0.99633104, 0.08300958, 0.02082884)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-GardenToPlaza_Ramp"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(49.6004115, 1.4000000, 14.0000000)
        p.CFrame = CFrame.new(-55.50000000, 39.29999924, 34.50000000, 0.80246234, 0.00000000, 0.59670275, 0.00000000, 1.00000000, 0.00000000, -0.59670275, 0.00000000, 0.80246234)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-GardenToPlaza_Guardrail"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(49.6004115, 4.6000000, 0.5000000)
        p.CFrame = CFrame.new(-50.96505737, 42.29999924, 40.59871292, 0.80246234, 0.00000000, 0.59670275, 0.00000000, 1.00000000, 0.00000000, -0.59670275, 0.00000000, 0.80246234)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-GardenToPlaza_Guardrail.001"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(49.6004115, 4.6000000, 0.5000000)
        p.CFrame = CFrame.new(-60.03494263, 42.29999924, 28.40128708, 0.80246234, 0.00000000, 0.59670275, 0.00000000, 1.00000000, 0.00000000, -0.59670275, 0.00000000, 0.80246234)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-PlazaToBoss_Ramp"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(24.0000000, 1.4000000, 15.0000000)
        p.CFrame = CFrame.new(0.00000000, 42.29999924, -49.50000000, -0.00000004, 0.00000001, 1.00000000, 0.25242189, 0.96761727, 0.00000000, -0.96761727, 0.25242189, -0.00000004)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-PlazaToBoss_Guardrail"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(24.0000000, 4.6000000, 0.5000000)
        p.CFrame = CFrame.new(8.10000038, 45.29999924, -49.50000000, -0.00000004, 0.00000001, 1.00000000, 0.25242189, 0.96761727, 0.00000000, -0.96761727, 0.25242189, -0.00000004)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-PlazaToBoss_Guardrail.001"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(24.0000000, 4.6000000, 0.5000000)
        p.CFrame = CFrame.new(-8.10000038, 45.29999924, -49.50000000, -0.00000004, 0.00000001, 1.00000000, 0.25242189, 0.96761727, 0.00000000, -0.96761727, 0.25242189, -0.00000004)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-BossApproachApron"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(16.0000000, 1.2000000, 18.0000000)
        p.CFrame = CFrame.new(0.00000000, 45.40000153, -70.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-WestSkyGallery_Ramp"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(87.5563400, 1.4000000, 10.0000000)
        p.CFrame = CFrame.new(-103.00000000, 53.79999924, -142.00000000, 0.74821472, 0.14695226, 0.64697742, -0.19272196, 0.98125339, 0.00000000, -0.63484883, -0.12468676, 0.76250917)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-WestSkyGallery_Guardrail"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(87.5563400, 4.6000000, 0.5000000)
        p.CFrame = CFrame.new(-99.37692261, 56.79999924, -137.72994995, 0.74821472, 0.14695226, 0.64697742, -0.19272196, 0.98125339, 0.00000000, -0.63484883, -0.12468676, 0.76250917)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-WestSkyGallery_Guardrail.001"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(87.5563400, 4.6000000, 0.5000000)
        p.CFrame = CFrame.new(-106.62307739, 56.79999924, -146.27005005, 0.74821472, 0.14695226, 0.64697742, -0.19272196, 0.98125339, 0.00000000, -0.63484883, -0.12468676, 0.76250917)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-EastSkyGallery_Ramp"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(88.1320836, 1.4000000, 10.0000000)
        p.CFrame = CFrame.new(105.00000000, 52.29999924, -175.00000000, 0.97450817, -0.15657969, -0.16067560, 0.15864086, 0.98733634, 0.00000000, 0.15864086, -0.02548972, 0.98700726)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-EastSkyGallery_Guardrail"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(88.1320836, 4.6000000, 0.5000000)
        p.CFrame = CFrame.new(104.10021973, 55.29999924, -169.47276306, 0.97450817, -0.15657969, -0.16067560, 0.15864086, 0.98733634, 0.00000000, 0.15864086, -0.02548972, 0.98700726)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-EastSkyGallery_Guardrail.001"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(88.1320836, 4.6000000, 0.5000000)
        p.CFrame = CFrame.new(105.89978027, 55.29999924, -180.52723694, 0.97450817, -0.15657969, -0.16067560, 0.15864086, 0.98733634, 0.00000000, 0.15864086, -0.02548972, 0.98700726)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-TraversalPlatform0"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(7.0000000, 1.2000000, 7.0000000)
        p.CFrame = CFrame.new(62.00000000, 40.40000153, 13.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-TraversalPlatform1"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(7.0000000, 1.2000000, 7.0000000)
        p.CFrame = CFrame.new(68.40000153, 42.21276093, 4.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-TraversalPlatform2"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(7.0000000, 1.2000000, 7.0000000)
        p.CFrame = CFrame.new(74.80000305, 43.86676407, -5.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-TraversalPlatform3"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(7.0000000, 1.2000000, 7.0000000)
        p.CFrame = CFrame.new(81.19999695, 45.22589874, -14.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-TraversalPlatform4"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(7.0000000, 1.2000000, 7.0000000)
        p.CFrame = CFrame.new(87.59999847, 46.19612885, -23.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-TraversalPlatform5"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(7.0000000, 1.2000000, 7.0000000)
        p.CFrame = CFrame.new(94.00000000, 46.73889923, -32.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-TraversalPlatform6"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(7.0000000, 1.2000000, 7.0000000)
        p.CFrame = CFrame.new(100.40000153, 46.87664032, -41.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-TraversalPlatform7"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(7.0000000, 1.2000000, 7.0000000)
        p.CFrame = CFrame.new(106.80000305, 46.68957520, -50.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-TraversalPlatform8"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(7.0000000, 1.2000000, 7.0000000)
        p.CFrame = CFrame.new(113.19999695, 46.30425262, -59.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-TraversalPlatform9"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(7.0000000, 1.2000000, 7.0000000)
        p.CFrame = CFrame.new(119.59999847, 45.87552643, -68.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-TraversalPlatform10"
        p.Shape = Enum.PartType.Block
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(7.0000000, 1.2000000, 7.0000000)
        p.CFrame = CFrame.new(126.00000000, 45.56442642, -77.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000)
        p.Parent = folder
    end
    do
        local p = Instance.new("Part")
        p.Name = "GEO-COLLISION-TraversalRest"
        p.Shape = Enum.PartType.Cylinder
        p.Anchored = true
        p.Transparency = 1
        p.CanCollide = true
        p.CanQuery = true
        p.CanTouch = false
        p.Size = Vector3.new(2.0000000, 32.0000000, 32.0000000)
        p.CFrame = CFrame.new(136.00000000, 49.02999878, -94.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000, 0.00000000, 0.00000000, 0.00000000, 1.00000000) * CFrame.Angles(0, 0, math.pi / 2)
        p.Parent = folder
    end
    return folder
end
