---
name: skybreak-3d-rig-and-virtualsplit
description: >-
  Use this skill when adding or debugging rigged 3D characters, bosses, dragons, devil fruits, weapons, wings, or VirtualSplitSpecs in DelegatedV5Renderer.lua and DelegatedV5Sources.
---

# SKYBREAK `DelegatedV5Renderer` Rigging & `VirtualSplitSpecs` Guide

## 1. `DelegatedV5Sources` Asset Structure
- Every embedded 3D package in `ReplicatedStorage.DelegatedV5Sources.<AssetName>` contains `ModuleScript`s: `Header`, optional `Clips`, and `0`-indexed `Mesh000` .. `MeshNNN` (`mesh_count` total meshes).
- Each `ModuleScript` stores `150,000`-character ASCII `StringValue` children (`Data001`, `Data002`, ...) holding `Base64(Zstd(JSON))`.
- `MeshXXX.json` uses keys `"vertices"`, `"normals"`, `"uvs"`, `"triangles"`, `"material"`, `"bone_weights"`, and `"bone_indices"`.

## 2. Rig Conventions
- **Player Classes (`Shared19` 19-bone rig)**: Must preserve exact bone names and rest poses compatible with `ReplicatedStorage/GuardianMotion/*` (`23` CFrame clips).
- **V5 Animated Bosses, Mobs, Fruits, Ships & Props**: Include `Clips` (`8` standardized `12`-keyframe clips: `Idle`, `Walk`, `Run`, `Attack`, `Skill`, `ElementalSurge`, `HeroicKata`, `UltimateAwakening`) interpolated with `0.18s` crossfade in `DelegatedV5Renderer.lua`.
- **Visual Binding**: Server enemies/NPCs specify `VisualAsset` in `ReplicatedStorage/Shared/Config.lua` or `GameStaticData.lua`, which `BlenderEnemies.client.lua` and `BlenderNPCs.client.lua` resolve against `DelegatedV5Sources` + `VirtualSplitSpecs`.

## 3. Adding or Updating `VirtualSplitSpecs`
- Multi-item Blender packs (`MythicalWeaponsSet`, `RaceV4WingsSet`, `AncientAetherFruitTrees`, `AetherShrinesAndRaidConsole`) are split at runtime via `VirtualSplitSpecs` in `04_Roblox/src/ReplicatedStorage/DelegatedV5Renderer.lua` using `source`, `minMesh`..`maxMesh`, or bone prefix filters.
- After editing `DelegatedV5Renderer.lua` or any `VisualAsset`, run `python 05_Pipeline_Tools_27x_9x/skybreak_contract_simulator_v3.py` to verify zero unresolved `VisualAsset` contracts.
