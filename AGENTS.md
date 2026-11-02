# SKYBREAK: Fragments of the Core — AI Agent Workspace Rules (`AGENTS.md`)

Always obey these critical engineering invariants when modifying or packaging SKYBREAK (`v12 PremiumUI • Macro-World 27x / 9x Edition`):

1. **Single Source of Truth for Luau Code (`123` modules)**:
   - Edit Luau files ONLY inside `04_Roblox/src/`.
   - Never rely on edits made only in `06_Antigravity_Work/luau_v8/` or `SKYBREAK_Visual_v2/src/` — run `05_Pipeline_Tools_27x_9x/sync_solid3d_and_scripts_to_rbxlx.py` to synchronize `04_Roblox/src/` + `06_Antigravity_Work/runtime_v8/` into `04_Roblox/SKYBREAK_Playable_v12_PremiumUI.rbxlx` and all mirror directories.
   - Never run legacy October scripts such as `06_Antigravity_Work/rework_skybreak_from_scratch.py` (they target the obsolete `1x` world scale).

2. **Hard Roblox Engine Limits (`< 199,000` Bytes & `< 2,048` Studs)**:
   - Every `.lua` file MUST stay strictly `< 199,000` UTF-8 bytes so Roblox Studio's XML parser never truncates `<ProtectedString name="Source">`. `ServerScriptService/Services/GameService.lua` is `~186.5 KB` — extract new server subsystems into separate `ModuleScript`s under `ServerScriptService/Services/` rather than growing `GameService.lua`.
   - Every `EditableMesh` chunk (`Mesh000..MeshNNN`) and every physics collider `Part.Size` component MUST stay strictly `< 2,048` studs (`<= 1,748` studs for mesh tiles, `<= 1,680` studs for collider parts).

3. **Headless Blender Safety**:
   - Never launch interactive Blender GUI or concurrent `blender.exe` processes. Always invoke Blender sequentially via `../SKYBREAK_Argon_Refinement/run_blender_safe.py` (one world per invocation: `-- --world W1`).

4. **Mandatory Verification Before Finishing Any Change**:
   - Always run both `05_Pipeline_Tools_27x_9x/verify_27x_9x_game_sync.py` and `05_Pipeline_Tools_27x_9x/skybreak_contract_simulator_v3.py` and confirm zero errors before reporting completion.
