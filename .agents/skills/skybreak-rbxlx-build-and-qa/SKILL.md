---
name: skybreak-rbxlx-build-and-qa
description: >-
  Use this skill whenever editing Luau scripts in the three canonical 04_Roblox/0x_HangMuc* folders, syncing runtime_v8 3D packages into SKYBREAK_Playable_v12_PremiumUI.rbxlx, checking the 199,000-byte XML script limit, or running automated SKYBREAK QA verification suites.
---

# SKYBREAK `.rbxlx` Packaging & Automated QA Workflow

Follow this exact procedure whenever modifying gameplay, UI, VFX, or collider Luau code in SKYBREAK:

## 1. Edit Only the 3 Canonical `04_Roblox/0x_HangMuc*` Source Folders
- **Always edit in the 3 canonical `04_Roblox/0x_HangMuc*` folders** (`01_HangMuc1_Server_Combat_World`, `02_HangMuc2_UI_Shop_Config`, `03_HangMuc3_3D_VuKhi_Giap_VFX`). **Never edit `04_Roblox/src/` directly** — `04_Roblox/src/` is a gitignored build folder that is overwritten every time sync runs.
- **Active World Map**: The active world map in the game is **`Gameplay3x Clean3D`** (`../SKYBREAK_Argon_Refinement/Worlds_Gameplay3x_Clean3D`), **not** the retired `27x/9x` map (`Worlds_27x_9x_Final_Preview`). Never re-export worlds from `Worlds_27x_9x_Final_Preview`.
- Keep every `.lua` file strictly below **`199,000` UTF-8 bytes** (`Config.lua`, `GameService.lua`, `ClientBootstrap.client.lua`, `Skybreak3DEquipment.lua`, and `DelegatedV5.client.lua` are near the ceiling; split new features into helper `ModuleScript`s).
- Canonical mirror pairs inside the `04_Roblox/0x_HangMuc*` folders (always edit the left file; sync overwrites the right file from the left):
  - `ReplicatedStorage/DelegatedV5Renderer.lua` -> `ReplicatedStorage/Shared/DelegatedV5Renderer.lua` (Hạng Mục 3)
  - `ReplicatedStorage/SkybreakShared/Config/WorldConfig.lua` -> `ReplicatedStorage/SkybreakShared/WorldConfig.lua` (Hạng Mục 2)
  - `ReplicatedStorage/SkybreakShared/Types/UIState.lua` -> `ReplicatedStorage/SkybreakShared/UIState.lua` (Hạng Mục 2)
- If modifying atmosphere or fog/DOF, update BOTH `ReplicatedStorage/Shared/RealmEnvironment.lua` AND `updateRealmAtmosphere()` in `StarterPlayer/StarterPlayerScripts/ClientBootstrap.client.lua`.

## 2. Package Into `.rbxlx` and Mirrors
Run from `SKYBREAK_Antigravity_Handoff/`:
```powershell
python 05_Pipeline_Tools_27x_9x/sync_solid3d_and_scripts_to_rbxlx.py
```

## 3. Run Mandatory Offline Verification
```powershell
python 05_Pipeline_Tools_27x_9x/verify_27x_9x_game_sync.py
python 05_Pipeline_Tools_27x_9x/lint_luau_globals.py
python 05_Pipeline_Tools_27x_9x/skybreak_contract_simulator_v3.py
```
`verify` and `lint_luau_globals` must print `[PASS]`. The contract simulator always exits 0, so read its output for `[UNRESOLVED`, `[GUN MISSING` and `[HAZARD`.

## 4. Optional Live Studio SmokeTest (130 Checks)
Inside Roblox Studio Play mode (or via `Roblox_Studio` MCP `execute_luau`):
```lua
print(require(game.ReplicatedStorage.Shared.SkybreakSmokeTest).RunAll().Summary)
```
