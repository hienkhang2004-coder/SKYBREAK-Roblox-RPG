---
name: skybreak-rbxlx-build-and-qa
description: >-
  Use this skill whenever editing Luau scripts in 04_Roblox/src, syncing runtime_v8 3D packages into SKYBREAK_Playable_v12_PremiumUI.rbxlx, checking the 199,000-byte XML script limit, or running automated SKYBREAK QA verification suites.
---

# SKYBREAK `.rbxlx` Packaging & Automated QA Workflow

Follow this exact procedure whenever modifying gameplay, UI, VFX, or collider Luau code in SKYBREAK:

## 1. Edit Only the Canonical Source Tree
- All Luau edits must be made in the three `04_Roblox/0x_HangMuc*` folders. `04_Roblox/src/` is a generated build that sync overwrites.
- Keep every `.lua` file strictly below **`199,000` UTF-8 bytes** (`GameService.lua` is near `186.5 KB`; split new features into helper `ModuleScript`s in `ServerScriptService/Services/`).
- Canonical mirror pairs inside `04_Roblox/src` (automatically copied by the packager from left to right):
  - `ReplicatedStorage/DelegatedV5Renderer.lua` -> `ReplicatedStorage/Shared/DelegatedV5Renderer.lua`
  - `ReplicatedStorage/SkybreakShared/Config/WorldConfig.lua` -> `ReplicatedStorage/SkybreakShared/WorldConfig.lua`
  - `ReplicatedStorage/SkybreakShared/Types/UIState.lua` -> `ReplicatedStorage/SkybreakShared/UIState.lua`
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
