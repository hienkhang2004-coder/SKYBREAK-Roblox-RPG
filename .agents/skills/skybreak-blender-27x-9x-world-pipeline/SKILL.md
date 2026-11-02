---
name: skybreak-blender-27x-9x-world-pipeline
description: >-
  Use this skill whenever modifying, exporting, tiling, or generating physics colliders for any of the 13 SKYBREAK 27x / 9x macro-scale Blender worlds (W1..W13).
---

# SKYBREAK `27x / 9x` Blender World Export & OBB Collider Pipeline

## 1. Coordinate & Collection Contract
- Coordinate mapping: `Roblox (X, Y, Z) = Blender (x, z, -y)` with `scale = 1.0`, `offset = (0, 0, 0)`, and `DECK_OFFSET_Y = 0` for all 13 `27x / 9x` worlds (`W1..W13`).
- Source `.blend` files are indexed in `../SKYBREAK_Argon_Refinement/Worlds_27x_9x_Final_Preview/SKYBREAK_All13Worlds_27x_9x_Manifest.json`.
- World origins and FastTravel points are locked in `05_Pipeline_Tools_27x_9x/macro_world_coords_27x_9x.json`.
- Collection skip regex MUST ONLY exclude `(COL-00|Archived|RenderOnly|RenderClouds|RenderAtmosphere|Lights|Cameras|Collision)`. Never exclude `COL-08/09/10` (they contain waterfalls, vistas, and portal islands).

## 2. Export Tiled `runtime_v8` Meshes (`<= 1,748 < 2,048` Studs)
Always run **one world per headless Blender invocation** through `run_blender_safe.py` (requires `zstandard` installed in Blender 5.2's embedded Python):
```powershell
python ../SKYBREAK_Argon_Refinement/run_blender_safe.py ../SKYBREAK_Argon_Refinement/export_all_13_worlds_27x_9x_v8.py -- --world W1
```
This bisects triangles `> 748` studs and partitions geometry via KD-tree AABB tiling so every `Mesh000..MeshNNN` chunk has AABB `<= 1,748 < 2,048` studs, `<= 18,000` tris, and `mesh_count <= 999`.

## 3. Extract & Generate Physics Colliders (`<= 1,680 < 2,048` Studs)
```powershell
# Re-extract geometry from W1..W13 .blend files sequentially via run_blender_safe.py
python 05_Pipeline_Tools_27x_9x/build_13_worlds_27x_9x_colliders.py --driver-extract-all

# Regenerate GoldenSkyCollision.lua, FrozenCyberCollision.lua, ShadowRealmCollision.lua & Solid3DWorldColliders.lua
python 05_Pipeline_Tools_27x_9x/build_13_worlds_27x_9x_colliders.py --generate-lua
```

## 4. Repackage & Audit
Run `05_Pipeline_Tools_27x_9x/sync_solid3d_and_scripts_to_rbxlx.py` followed by `05_Pipeline_Tools_27x_9x/verify_27x_9x_game_sync.py`.
