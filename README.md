# SKYBREAK: Fragments of the Core (Roblox 3D Action RPG)

> **Thể loại:** 3D Action RPG • 20 Thế Giới Đảo Bay • 12 Trái Ác Quỷ 3D & Biến Hình Rồng/Phật Tổ • 3 Đồng Hành AI • 22 Boss 3 Pha  
> **Ngôn ngữ chính:** `Luau` (104 tệp mã nguồn Runtime) + `Python` (Build & 3D Mesh Compression Pipeline)

---

## 📚 Tài Liệu Dự Án (Documentation)

1. **[Tài liệu Tổng hợp Giới thiệu Game (Intro) & Kiến trúc Kỹ thuật (Tech Docs)](00_Documents/SKYBREAK_TECH_AND_GAME_INTRO_DOCS.md)** *(Đọc đầu tiên)*
2. **[Báo cáo Bàn giao Kỹ thuật & Kiểm toán 93 Mô hình 3D V5](CODEX_HANDOFF_REPORT.md)**
3. **[Hướng dẫn Khởi động Dự án](00_START_HERE.md)**
4. **[Handoff Mỹ thuật 3D & 17 Concept Art](00_Documents/SKYBREAK_ARGON_3D_HANDOFF.md)**

---

## 🚀 Cách Mở Game Trong Roblox Studio

1. **Cách 1 (Mở bản đầy đủ `.rbxlx` 311 MB mới nhất):**
   - Chạy file [`04_Roblox/restore_rbxlx.bat`](04_Roblox/restore_rbxlx.bat) để tự động ghép 4 phần trong `04_Roblox/rbxlx_parts/` thành file `04_Roblox/SKYBREAK_Playable_v12_PremiumUI.rbxlx` (311.1 MB).
   - Mở `04_Roblox/SKYBREAK_Playable_v12_PremiumUI.rbxlx` trong **Roblox Studio** và bấm **Play**.
2. **Cách 2 (Mở trực tiếp file nén `.rbxl`):**
   - Mở [`04_Roblox/SKYBREAK_Playable_v12_PremiumUI.rbxl`](04_Roblox/SKYBREAK_Playable_v12_PremiumUI.rbxl) (79.6 MB).

---

## 🗂 Cấu Trúc Kho Mã Nguồn (Repository Structure)

```text
├── 00_Documents/
│   ├── SKYBREAK_TECH_AND_GAME_INTRO_DOCS.md   # Tài liệu tổng hợp Intro & Tech Docs
│   └── SKYBREAK_ARGON_3D_HANDOFF.md           # Tài liệu ánh xạ Concept Art & 3D
├── 02_Concept_Art/                            # 17 bức Concept Art gốc
├── 04_Roblox/
│   ├── SKYBREAK_Playable_v12_PremiumUI.rbxl   # File Roblox Place nhị phân (<100MB)
│   ├── rbxlx_parts/                           # 4 phần chia nhỏ (<80MB/phần) của bản .rbxlx 311MB mới nhất
│   ├── restore_rbxlx.bat                      # Script ghép 4 phần lại thành .rbxlx trong 1 giây
│   └── src/                                   # 104 file Luau phân cấp theo dịch vụ Roblox
├── 06_Antigravity_Work/
│   ├── SKYBREAK_Master_Overhaul_Manifest_v13.json
│   ├── generate_skybreak_sfx_wavs.py          # Script tạo 30 hiệu ứng âm thanh & BGM (.wav)
│   ├── rework_skybreak_from_scratch.py        # Script đóng gói cấu trúc Place
│   └── luau_v8/                               # Mã nguồn Luau cốt lõi (Server, Client, UI, 3D Colliders)
└── 07_Audio_SFX/                              # 30 file âm thanh .wav (26 SFX + 4 BGM)
```
