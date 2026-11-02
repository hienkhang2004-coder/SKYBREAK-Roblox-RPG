# SKYBREAK: Fragments of the Core (Roblox 3D Celestial Action-RPG)

> **Phiên bản:** `v12 PremiumUI • Macro-World 27× / 9× Edition` (`WorldArtVersion = 8` • `30/10/2026`)  
> **Quy mô dự án:** **8** Realms (`20` Cụm Thế Giới 3D: **3** Đại Lục Chính `27×` `~15,274–16,517` studs + **10** Thế Giới Mở Rộng `9×` `~4,153–5,431` studs + Đảo Điện Thờ & 5 Cõi Thượng Cổ) • **123** File Luau (`74,760` dòng) • **94** Gói Tài Nguyên 3D V5 (`+21` VirtualSplit Models) • **12** Trái Ác Quỷ 3D (`60` Chiêu + Thức Tỉnh V2 + Hóa Rồng/Phật Tổ) • **11** Màn Hình UI Song Ngữ `VI / EN` • **30** Tệp Âm Thanh Gốc & Synthesizer.

---

## 📚 Bộ Tài Liệu Kỹ Thuật & Bàn Giao Toàn Tập (Full Documentation Suite)

Dự án đi kèm bộ tài liệu chuẩn Studio-to-Studio đầy đủ gồm **9 văn bản chuyên sâu**:

1. **[HỒ SƠ BÀN GIAO TỔNG THỂ DỰ ÁN (Master Technical & Production Handover)](SKYBREAK_MASTER_PROJECT_HANDOVER.md)** *(Đọc đầu tiên cho CTO / Producer / Tech Lead)*
2. **[Tập 00 — Cổng Điều Hướng Tài Liệu & Lộ Trình Đọc Theo Vai Trò](00_Documents/00_DOCUMENTATION_INDEX.md)**
3. **[Tập 01 — Kiến Trúc Hệ Thống, Giao Thức Mạng 15 RemoteEvents & DataStore Schema](00_Documents/01_SYSTEM_ARCHITECTURE_AND_NETWORK_PROTOCOL.md)**
4. **[Tập 02 — Từ Điển API Chi Tiết Toàn Bộ 123 File Mã Nguồn Luau](00_Documents/02_COMPLETE_LUAU_API_REFERENCE_123_MODULES.md)**
5. **[Tập 03 — Tài Liệu Thiết Kế Gameplay, Công Thức Toán Học & Cân Bằng Toàn Tập (GDD Bible)](00_Documents/03_GAME_DESIGN_AND_COMBAT_BALANCE_BIBLE.md)**
6. **[Tập 04 — Bản Đồ Địa Lý 20 Thế Giới `27× / 9×`, Danh Mục `94 + 21` Model 3D & Pipeline Blender V8](00_Documents/04_WORLD_ATLAS_27X_9X_AND_3D_ASSET_PIPELINE.md)**
7. **[Tập 05 — Kiến Trúc UI 11 Màn Hình, Song Ngữ `VI/EN`, Bay Tự Do 6-DOF & Hệ Thống Âm Thanh](00_Documents/05_UI_UX_11_SCREENS_I18N_AND_AUDIO_GUIDE.md)**
8. **[Tập 06 — Sổ Tay Vận Hành Build CLI, 130 Bài SmokeTest, Bảo Trì & Publish Roblox Cloud](00_Documents/06_DEVOPS_BUILD_QA_AND_CLOUD_PUBLISHING_RUNBOOK.md)**
9. **[Tập 07 — Tài Liệu Cài Đặt Phần Mềm, Môi Trường Kỹ Thuật, MCP Servers & AI Agent Skills](00_Documents/07_SOFTWARE_ENVIRONMENT_MCP_AND_AGENT_SKILLS_SETUP.md)**

---

## 🚀 Cách Mở & Chạy Ngay Trong Roblox Studio (Quick Start)

1. Mở trực tiếp file Place chính thức [`04_Roblox/SKYBREAK_Playable_v12_PremiumUI.rbxlx`](04_Roblox/SKYBREAK_Playable_v12_PremiumUI.rbxlx) (`306,809,536` bytes • SHA-256: `f8a6182e07aaf790...`) trong **Roblox Studio**.
2. Đảm bảo tính năng **EditableMesh & EditableImage** đang bật trong Studio.
3. Nhấn **Play (F5)** — nhân vật sẽ khởi đầu tại đại sảnh `SkyHub` quy mô `27×` `(-2484, 54, 4131)`.
4. Để kiểm thử nhanh toàn bộ tính năng, mở màn hình **Settings (Cài đặt)** để chuyển đổi ngôn ngữ `VI ⇄ EN`, bật **Dev Sandbox** hoặc chạy bộ kiểm thử tự động **130 bài `SkybreakSmokeTest`**.

---

## 🛠️ Đóng Gói & Kiểm Định Tự Động Qua CLI (`05_Pipeline_Tools_27x_9x`)

Mọi chỉnh sửa mã nguồn Luau thực hiện tại nguồn chân lý duy nhất [`04_Roblox/src/`](04_Roblox/src/), sau đó đóng gói và kiểm định bằng bộ công cụ đường dẫn tương đối trong [`05_Pipeline_Tools_27x_9x/`](05_Pipeline_Tools_27x_9x/):

```powershell
# 1. Đồng bộ runtime_v8 + 123 script Luau vào .rbxlx & các bản mirror
python 05_Pipeline_Tools_27x_9x/sync_solid3d_and_scripts_to_rbxlx.py

# 2. Kiểm định toàn diện AABB < 2,048 studs, 0 chồng lấn 20 vùng, script < 199 KB & SHA-256
python 05_Pipeline_Tools_27x_9x/verify_27x_9x_game_sync.py

# 3. Kiểm định hợp đồng VisualAsset, Vũ khí/Súng, Giftcodes & an toàn toán học Luau
python 05_Pipeline_Tools_27x_9x/skybreak_contract_simulator_v3.py
```

---

## 🗂️ Cấu Trúc Thư Mục Chuẩn (Repository Structure)

```text
SKYBREAK_Antigravity_Handoff/
├── README.md                                     # Tổng quan kho lưu trữ & chỉ mục nhanh
├── SKYBREAK_MASTER_PROJECT_HANDOVER.md           # Hồ sơ bàn giao tổng thể Studio-to-Studio
├── 00_Documents/                                 # Bộ tài liệu kỹ thuật & thiết kế đầy đủ (Tập 00 -> 06)
├── 02_Blender_Files/ & 02_Concept_Art/           # Lưu trữ nguồn 3D & 17 bức Concept Art gốc
├── 04_Roblox/
│   ├── SKYBREAK_Playable_v12_PremiumUI.rbxlx     # File Roblox Place chính thức (94 gói V5 + 123 Scripts)
│   └── src/                                      # Nguồn chân lý duy nhất của 123 file mã nguồn Luau
├── 05_Pipeline_Tools_27x_9x/                     # Bộ script Python đóng gói .rbxlx, sinh Collider & kiểm định QA
├── 06_Antigravity_Work/
│   ├── runtime_v8/                               # Dữ liệu mesh nén Zstd+Base64 của 13 thế giới 27x/9x & Rồng
│   ├── luau_v8/                                  # Mirror phẳng tự động cập nhật khi đóng gói
│   └── SKYBREAK_Playable_v12_PremiumUI.rbxlx     # Bản sao dự phòng đồng nhất SHA-256
└── 07_Audio_SFX/                                 # 30 tệp âm thanh gốc .wav (SFX chiến đấu & BGM theo Realm)
```
