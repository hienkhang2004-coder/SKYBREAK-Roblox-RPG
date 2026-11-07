# SKYBREAK: Fragments of the Core (Roblox 3D Celestial Action-RPG)

> **Phiên bản:** `v12 PremiumUI • Gameplay3x Clean3D Edition` (`WorldArtVersion = 8` • Cập nhật `07/11/2026`)  
> **Bản đồ Thế giới hiện hành:** **`Gameplay3x Clean3D`** (`../SKYBREAK_Argon_Refinement/Worlds_Gameplay3x_Clean3D`), **không phải** bản đồ `27× / 9×` đã ngừng sử dụng (`Worlds_27x_9x_Final_Preview`). Một số tên thư mục công cụ (`05_Pipeline_Tools_27x_9x`) vẫn giữ tên lịch sử nhưng dữ liệu trong game là `Gameplay3x Clean3D`.  
> **Nguồn mã nguồn Luau chuẩn (Canonical Source):** Toàn bộ **129 file `.lua`** nằm trong **3 thư mục Hạng Mục** (`04_Roblox/01_HangMuc1_Server_Combat_World`, `04_Roblox/02_HangMuc2_UI_Shop_Config`, `04_Roblox/03_HangMuc3_3D_VuKhi_Giap_VFX`). **Tuyệt đối không sửa trực tiếp `04_Roblox/src/`** (thư mục `src/` chỉ là bản build trung gian nằm trong `.gitignore` và sẽ bị ghi đè khi chạy lệnh sync).

---

## 📚 Bộ Tài Liệu Kỹ Thuật & Bàn Giao Toàn Tập (Full Documentation Suite)

> **Tài liệu điều hành mới nhất:** Đọc [`CLAUDE.md`](CLAUDE.md), [`AGENTS.md`](AGENTS.md) và [`PUBLISH_PLAN.md`](PUBLISH_PLAN.md) trước khi sửa code.

Dự án đi kèm bộ tài liệu kỹ thuật & kiểm toán:

1. **[HỒ SƠ BÀN GIAO TỔNG THỂ DỰ ÁN (Master Technical & Production Handover)](SKYBREAK_MASTER_PROJECT_HANDOVER.md)** *(Đọc đầu tiên cho CTO / Producer / Tech Lead)*
2. **[Tập 00 — Cổng Điều Hướng Tài Liệu & Lộ Trình Đọc Theo Vai Trò](00_Documents/00_DOCUMENTATION_INDEX.md)**
3. **[Tập 01 — Kiến Trúc Hệ Thống, Giao Thức Mạng 15 RemoteEvents & DataStore Schema](00_Documents/01_SYSTEM_ARCHITECTURE_AND_NETWORK_PROTOCOL.md)**
4. **[Tập 02 — Từ Điển API Chi Tiết Toàn Bộ Mã Nguồn Luau](00_Documents/02_COMPLETE_LUAU_API_REFERENCE_123_MODULES.md)**
5. **[Tập 03 — Tài Liệu Thiết Kế Gameplay, Công Thức Toán Học & Cân Bằng Toàn Tập (GDD Bible)](00_Documents/03_GAME_DESIGN_AND_COMBAT_BALANCE_BIBLE.md)**
6. **[Tập 04 — Bản Đồ Địa Lý Thế Giới, Danh Mục Model 3D & Pipeline Blender V8](00_Documents/04_WORLD_ATLAS_27X_9X_AND_3D_ASSET_PIPELINE.md)**
7. **[Tập 05 — Kiến Trúc UI 11 Màn Hình, Song Ngữ `VI/EN`, Bay Tự Do 6-DOF & Hệ Thống Âm Thanh](00_Documents/05_UI_UX_11_SCREENS_I18N_AND_AUDIO_GUIDE.md)**
8. **[Tập 06 — Sổ Tay Vận Hành Build CLI, 130 Bài SmokeTest, Bảo Trì & Publish Roblox Cloud](00_Documents/06_DEVOPS_BUILD_QA_AND_CLOUD_PUBLISHING_RUNBOOK.md)**
9. **[Tập 07 — Tài Liệu Cài Đặt Phần Mềm, Môi Trường Kỹ Thuật, MCP Servers & AI Agent Skills](00_Documents/07_SOFTWARE_ENVIRONMENT_MCP_AND_AGENT_SKILLS_SETUP.md)**
10. **[Tập 08 — Hướng Dẫn Làm Việc Nhóm 3 Người Trên GitHub & Google Drive](00_Documents/08_TEAM_GITHUB_WORKFLOW_3_MEMBERS.md)**
11. **[Bảng Ánh Xạ Đổi Tên IP (`IP_RENAME_MAP.md`)](00_Documents/IP_RENAME_MAP.md)** • **[Quy Trình Xóa Dữ Liệu (`DATA_ERASURE.md`)](00_Documents/DATA_ERASURE.md)** • **[Kiểm Toán Asset & Nền Tảng (`ASSET_AND_PLATFORM_AUDIT.md`)](00_Documents/ASSET_AND_PLATFORM_AUDIT.md)**

---

## 🚀 Cách Mở & Chạy Ngay Trong Roblox Studio (Quick Start)

1. Mở trực tiếp file Place chính thức [`04_Roblox/SKYBREAK_Playable_v12_PremiumUI.rbxlx`](04_Roblox/SKYBREAK_Playable_v12_PremiumUI.rbxlx) trong **Roblox Studio**.
2. Đảm bảo tính năng **EditableMesh & EditableImage** đang bật trong Studio.
3. Nhấn **Play (F5)** — nhân vật sẽ khởi đầu tại đại sảnh `SkyHub` trên bản đồ `Gameplay3x Clean3D`.
4. Để kiểm thử nhanh toàn bộ tính năng, mở màn hình **Settings (Cài đặt)** để chuyển đổi ngôn ngữ `VI ⇄ EN` hoặc chạy bộ kiểm thử tự động **130 bài `SkybreakSmokeTest`**.

---

## 🛠️ Đóng Gói & Kiểm Định Tự Động Qua CLI (`05_Pipeline_Tools_27x_9x`)

Mọi chỉnh sửa mã nguồn Luau **bắt buộc thực hiện trong 3 thư mục Hạng Mục chuẩn**:
- `04_Roblox/01_HangMuc1_Server_Combat_World/` (Server, Combat, Boss, World)
- `04_Roblox/02_HangMuc2_UI_Shop_Config/` (UI, Shop, Config)
- `04_Roblox/03_HangMuc3_3D_VuKhi_Giap_VFX/` (3D, Vũ khí, Giáp, VFX, Camera/Flight)

*(Không bao giờ sửa trực tiếp `04_Roblox/src/`, vì `04_Roblox/src/` là thư mục build bị `.gitignore` và sẽ bị ghi đè khi chạy sync).*

Sau khi sửa trong `04_Roblox/0x_HangMuc*`, đóng gói và kiểm định bằng bộ công cụ trong [`05_Pipeline_Tools_27x_9x/`](05_Pipeline_Tools_27x_9x/):

```powershell
# 1. Đồng bộ 129 script Luau từ 04_Roblox/0x_HangMuc* -> 04_Roblox/src/ -> .rbxlx & các bản mirror
python 05_Pipeline_Tools_27x_9x/sync_solid3d_and_scripts_to_rbxlx.py

# 2. Kiểm định giới hạn hình học < 2,048 studs, script < 199 KB & SHA-256
python 05_Pipeline_Tools_27x_9x/verify_27x_9x_game_sync.py

# 3. Kiểm tra biến toàn cục & cú pháp bằng luau-analyze trên 129 file Luau
python 05_Pipeline_Tools_27x_9x/lint_luau_globals.py

# 4. Kiểm định hợp đồng VisualAsset, Vũ khí/Súng, Giftcodes & an toàn toán học Luau
python 05_Pipeline_Tools_27x_9x/skybreak_contract_simulator_v3.py
```

---

## 🗂️ Cấu Trúc Thư Mục Chuẩn (Repository Structure)

```text
SKYBREAK_Antigravity_Handoff/
├── CLAUDE.md & AGENTS.md                         # Quy tắc làm việc & kiến trúc hiện hành (ưu tiên cao nhất)
├── PUBLISH_PLAN.md                               # Kế hoạch thẩm định & hoàn thiện để publish
├── README.md                                     # Tổng quan kho lưu trữ & chỉ mục nhanh
├── SKYBREAK_MASTER_PROJECT_HANDOVER.md           # Hồ sơ bàn giao tổng thể Studio-to-Studio
├── 00_Documents/                                 # Bộ tài liệu kỹ thuật, thiết kế & kiểm toán (Tập 00 -> 08 + P0 Docs)
├── 02_Blender_Files/ & 02_Concept_Art/           # Lưu trữ nguồn 3D & 17 bức Concept Art gốc
├── 04_Roblox/
│   ├── 01_HangMuc1_Server_Combat_World/          # [SỬA Ở ĐÂY] Nguồn chuẩn Hạng Mục 1 (Server, Combat, World)
│   ├── 02_HangMuc2_UI_Shop_Config/               # [SỬA Ở ĐÂY] Nguồn chuẩn Hạng Mục 2 (UI, Shop, Config)
│   ├── 03_HangMuc3_3D_VuKhi_Giap_VFX/            # [SỬA Ở ĐÂY] Nguồn chuẩn Hạng Mục 3 (3D, Vũ khí, Giáp, VFX)
│   ├── tests/                                    # Bộ kiểm thử tự động (test_logic.py, test_data.py)
│   ├── SKYBREAK_Playable_v12_PremiumUI.rbxlx     # File Roblox Place chính thức (bản đồ Gameplay3x Clean3D)
│   └── src/                                      # [KHÔNG SỬA] Bản build tự động sinh từ 0x_HangMuc* (gitignored)
├── 05_Pipeline_Tools_27x_9x/                     # Bộ script Python đóng gói .rbxlx, lint Luau & kiểm định QA
├── 06_Antigravity_Work/
│   ├── runtime_v8/                               # Dữ liệu mesh nén Zstd+Base64 của 13 thế giới Gameplay3x Clean3D & Rồng
│   ├── luau_v8/                                  # Mirror phẳng tự động cập nhật khi đóng gói
│   └── SKYBREAK_Playable_v12_PremiumUI.rbxlx     # Bản sao dự phòng đồng nhất SHA-256
└── 07_Audio_SFX/                                 # 30 tệp âm thanh gốc .wav (SFX chiến đấu & BGM theo Realm)
```
