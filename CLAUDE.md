# SKYBREAK: Fragments of the Core — hướng dẫn cho Claude Code

Game Roblox Action-RPG 3D (Luau + pipeline Blender/Python). Bản hiện hành: `v12 PremiumUI • Macro-World 27× / 9×`.
Trao đổi với chủ dự án bằng tiếng Việt, trực tiếp, không báo cáo dài dòng.

> **Bản đồ trong game là Gameplay3x Clean3D, không phải 27×/9×.** Chủ dự án đã bỏ 27×/9× ngày 31/10; tên phiên bản, tên thư mục và tài liệu còn ghi 27×/9× là cũ.
> Nguồn map hiện hành nằm ở `../SKYBREAK_Argon_Refinement/Worlds_Gameplay3x_Clean3D` (dựng lại ngày 05/11, cả 13 world khớp số object và tam giác với `runtime_v8`). **Không xuất lại thế giới từ `Worlds_27x_9x_Final_Preview`**, vì sẽ đưa bản đồ đã bỏ vào game.

## Quy tắc bắt buộc

Bộ quy tắc gốc dùng chung với Antigravity/Codex nằm trong file dưới đây, và luôn được nạp cùng file này:

@AGENTS.md

Phần còn lại là bổ sung cho AGENTS.md. Nếu tài liệu khác mâu thuẫn, thứ tự ưu tiên là:
code thật > CLAUDE.md này > AGENTS.md > mọi tài liệu còn lại.

## Sửa code ở đâu (nhiều tài liệu cũ ghi sai)

Luồng thật, theo `sync_solid3d_and_scripts_to_rbxlx.py`:

```text
04_Roblox/0x_HangMuc*/  ──sync──▶  04_Roblox/src/  ──sync──▶  .rbxlx (3 bản) + SKYBREAK_Visual_v2/src + luau_v8
   (SỬA Ở ĐÂY)                   (bản build, gitignore)
```

- **Chỉ sửa trong 3 thư mục Hạng Mục.** 129 file `.lua` nằm hết ở đó.
- `04_Roblox/src/` là bản build và bị `.gitignore`. Sửa ở đây sẽ bị ghi đè ở lần sync sau và không lên Git.
- Không sửa `SKYBREAK_Visual_v2/src/`, `06_Antigravity_Work/luau_v8/`, hay trực tiếp trong Roblox Studio: đều bị sync ghi đè.
- Rojo (`04_Roblox/default.project.json`) đọc từ `src/`, nên phải sync thì Rojo mới thấy thay đổi.

Ai đang đúng/sai về điểm này: `AGENTS.md` đúng. `README.md`, `SKYBREAK_MASTER_PROJECT_HANDOVER.md`,
`00_Documents/08_TEAM_GITHUB_WORKFLOW_3_MEMBERS.md` và skill `skybreak-rbxlx-build-and-qa` còn ghi "sửa tại `04_Roblox/src`" là đã cũ.

### Cặp file mirror — chỉ sửa file bên trái

Sync ghi đè bên phải bằng bên trái, nên sửa bên phải là mất. Đường dẫn tính từ thư mục Hạng Mục:

| Sửa file này | Không sửa file này | Hạng Mục |
| :--- | :--- | :--- |
| `ReplicatedStorage/DelegatedV5Renderer.lua` | `ReplicatedStorage/Shared/DelegatedV5Renderer.lua` | 3 |
| `ReplicatedStorage/SkybreakShared/Config/WorldConfig.lua` | `ReplicatedStorage/SkybreakShared/WorldConfig.lua` | 2 |
| `ReplicatedStorage/SkybreakShared/Types/UIState.lua` | `ReplicatedStorage/SkybreakShared/UIState.lua` | 2 |

Bản `Shared/DelegatedV5Renderer.lua` trong Hạng Mục 3 đang cũ hơn hẳn (140,072 B so với 157,199 B). Đừng đọc nó để hiểu renderer.

### Hạng Mục nào giữ file nào

| Hạng Mục | Thư mục trong `04_Roblox/` | File then chốt |
| :--- | :--- | :--- |
| 1 — Server, combat, boss, thế giới | `01_HangMuc1_Server_Combat_World` | `GameService`, `SkybreakCombatExpansion`, `WorldService`, `SkybreakWorldEventsService`, `PlayerDataService` |
| 2 — UI, shop, config | `02_HangMuc2_UI_Shop_Config` | `SkybreakClient/UI/*`, `SkybreakShared/Config/*` |
| 3 — 3D, vũ khí, giáp, VFX, chuyển động | `03_HangMuc3_3D_VuKhi_Giap_VFX` | **`ClientBootstrap`, `SkybreakFlightAndCamera`**, `DelegatedV5.client`, `DelegatedV5Renderer`, `Skybreak3DEquipment`, `Config.lua`, `GuardianMotion/*` |

- Dự án chia cho 3 người. Nếu chưa biết phiên này thuộc Hạng Mục nào, hỏi trước khi sửa.
- Đọc Hạng Mục khác thì thoải mái (Rule 1 bắt buộc đọc cả Client lẫn Server). Cần **sửa** ngoài Hạng Mục được giao thì nói rõ và hỏi trước.

## Build và kiểm định

Chạy từ thư mục gốc repo này, trong PowerShell:

```powershell
$py = "C:\Program Files\Blender Foundation\Blender 5.2\5.2\python\bin\python.exe"
& $py 05_Pipeline_Tools_27x_9x/sync_solid3d_and_scripts_to_rbxlx.py      # đóng gói
& $py 05_Pipeline_Tools_27x_9x/verify_27x_9x_game_sync.py                # phải ra [PASS]
& $py 05_Pipeline_Tools_27x_9x/lint_luau_globals.py                     # phải ra [PASS]
& $py 05_Pipeline_Tools_27x_9x/skybreak_contract_simulator_v3.py         # phải đọc output
```

Các script này chỉ dùng thư viện chuẩn, nên `python` thường cũng chạy được. `README_PHAN_VIEC.md` ghi Blender 4.3 là cũ.
`check_workstation_setup.py` dùng để kiểm tra máy mới.

Kiểm thử trong Studio (Play, hoặc Command Bar):

```lua
print(require(game.ReplicatedStorage.Shared.SkybreakSmokeTest).RunAll().Summary)
```

### Giới hạn của bộ kiểm định — đừng báo quá mức

- `verify` **không** chạy game và **không** so nội dung script trong `.rbxlx` với nguồn.
  Mục "Part.Size" trong docstring thực tế chưa được kiểm tra (nhánh code là `pass`).
- `skybreak_contract_simulator_v3.py` **không có** dòng `[PASS]` và luôn thoát mã 0, dù skill ghi ngược lại.
  Phải tự đọc output tìm `[UNRESOLVED VISUAL ASSET]`, `[GUN MISSING STATS]`, `[HAZARD ...]`.
- Vì vậy `[PASS]` chỉ nghĩa là đóng gói và hình học hợp lệ. Thay đổi về gameplay, UI, VFX phải báo là **"chưa test trong Studio"**
  cho tới khi chủ dự án xác nhận. Không viết "đã sửa xong" chỉ dựa vào `[PASS]`.

### Lưu ý khi chạy sync

- Sync ghi lại cả 3 bản `.rbxlx` (mỗi bản khoảng 318 MB), nên mất thời gian và cần đủ ổ đĩa.
- Nếu Studio đang mở file này, Save trong Studio sẽ ghi đè kết quả sync. Sau khi sync phải mở lại file.
- Sync dừng bằng `assert` nếu một file vượt 199,000 B.

## File sát giới hạn 199,000 bytes

Số liệu đo ngày 05/11/2026; số trong tài liệu bàn giao đã cũ. Kiểm tra kích thước thật trước khi thêm code.

| File | Bytes | Còn lại |
| :--- | ---: | ---: |
| `ReplicatedStorage/Shared/Config.lua` | 190,424 | 8,576 |
| `ServerScriptService/Services/GameService.lua` | 187,161 | 11,839 |
| `StarterPlayerScripts/ClientBootstrap.client.lua` | 186,019 | 12,981 |
| `ReplicatedStorage/Shared/Skybreak3DEquipment.lua` | 179,205 | 19,795 |
| `StarterPlayerScripts/DelegatedV5.client.lua` | 175,392 | 23,608 |

Tính năng lớn thì tách `ModuleScript` mới rồi `require`, không viết nối vào các file trên.

## Git

- Remote: `hienkhang2004-coder/SKYBREAK-Roblox-RPG`, nhánh `main`. `.rbxlx`, `.blend`, âm thanh và `04_Roblox/src/` không lên GitHub.
- Stage đúng thư mục Hạng Mục, ví dụ `git add 04_Roblox/03_HangMuc3_3D_VuKhi_Giap_VFX`.
  Lệnh `git add 04_Roblox/src` trong tài liệu 08 không dùng được vì thư mục này bị ignore.
- Commit theo mẫu đang dùng: `fix(HangMuc3): ...`, `feat(HangMuc3): ...`.
- Chỉ commit/push khi chủ dự án yêu cầu.

## Không được tự làm

- **Publish**: `deploy_skybreak_to_roblox_cloud.py` mặc định đẩy bản `Published` công khai. Chỉ chạy khi được yêu cầu rõ ràng, và xác nhận lại trước khi chạy.
  Cờ `--cloud-strip-v5-sources` gỡ `DelegatedV5Sources`, tức gỡ dữ liệu mesh mà game đang dựng lúc chạy. Chỉ dùng được sau khi đã chuyển sang asset Roblox thật.
- **Script thế hệ cũ, tuyệt đối không chạy**: `rework_skybreak_from_scratch.py`, `export_all_15_worlds_v8.py` (ghi đè thế giới 27×/9×).
- `SKYBREAK_Visual_v2/build.py` là script cũ cho `SKYBREAK_Playable_v4.rbxlx`, không dùng cho bản hiện hành.
- Không tự cài phần mềm, mua asset, tải nguồn lên cloud, đổi cài đặt Security của Studio.

## Tài liệu tham khảo (đọc khi cần, không nạp sẵn)

| Khi làm việc này | Đọc |
| :--- | :--- |
| Nhân vật, rig, `VisualAsset`, `VirtualSplitSpecs` | `.agents/skills/skybreak-3d-rig-and-virtualsplit/SKILL.md` |
| Xuất thế giới Blender W1–W13, sinh collider | Dừng và hỏi trước: skill `skybreak-blender-27x-9x-world-pipeline` và script xuất trong repo còn trỏ tới bản đã bỏ |
| Kiến trúc, 15 RemoteEvents, DataStore | `00_Documents/01_SYSTEM_ARCHITECTURE_AND_NETWORK_PROTOCOL.md` |
| API từng module | `00_Documents/02_COMPLETE_LUAU_API_REFERENCE_123_MODULES.md` |
| Cân bằng gameplay, công thức | `00_Documents/03_GAME_DESIGN_AND_COMBAT_BALANCE_BIBLE.md` |
| Tọa độ, thế giới, pipeline 3D | `00_Documents/04_WORLD_ATLAS_27X_9X_AND_3D_ASSET_PIPELINE.md` |
| UI, i18n, âm thanh, bay 6-DOF | `00_Documents/05_UI_UX_11_SCREENS_I18N_AND_AUDIO_GUIDE.md` |
| Build, QA, publish | `00_Documents/06_DEVOPS_BUILD_QA_AND_CLOUD_PUBLISHING_RUNBOOK.md` |
| Ràng buộc kỹ thuật, lộ trình | `SKYBREAK_MASTER_PROJECT_HANDOVER.md` mục 8 và 9 |

Các tài liệu này viết khi còn 123 file Luau và trước khi chia Hạng Mục. Dùng để hiểu thiết kế, còn số liệu và đường dẫn phải đối chiếu lại với code.
`00_START_HERE.md` (23/10, thời v7/v8) và `CODEX_HANDOFF_REPORT.md` (27/10, gọi script scratch của Antigravity) chỉ còn giá trị lịch sử.

Đường dẫn tuyệt đối trong tài liệu trỏ tới máy của Khang: `C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/`.
Script xuất thế giới và mirror cần hai thư mục anh em cùng cấp với repo: `SKYBREAK_Argon_Refinement` và `SKYBREAK_Visual_v2`.
