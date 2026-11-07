# HƯỚNG DẪN LÀM VIỆC NHÓM 3 NGƯỜI TRÊN GITHUB & GOOGLE DRIVE (SKYBREAK RPG)

> **Cập nhật quan trọng (theo [`CLAUDE.md`](../CLAUDE.md) & [`PUBLISH_PLAN.md`](../PUBLISH_PLAN.md)):**
> 1. **Luôn sửa code trong 3 thư mục Hạng Mục chuẩn (`04_Roblox/0x_HangMuc*`)**: Toàn bộ **129 file `.lua`** nằm trong `04_Roblox/01_HangMuc1_Server_Combat_World`, `04_Roblox/02_HangMuc2_UI_Shop_Config`, và `04_Roblox/03_HangMuc3_3D_VuKhi_Giap_VFX`. **Tuyệt đối không sửa trực tiếp `04_Roblox/src/`** vì `04_Roblox/src/` là thư mục build nằm trong `.gitignore` và sẽ bị ghi đè mỗi lần chạy sync.
> 2. **Bản đồ thế giới hiện hành là `Gameplay3x Clean3D` (`../SKYBREAK_Argon_Refinement/Worlds_Gameplay3x_Clean3D`)**, không phải bản đồ `27× / 9×` đã ngừng sử dụng (`Worlds_27x_9x_Final_Preview`).

Tài liệu này giải thích cách tách **Hằng Số (Đồ họa 3D / Map gốc)** và **Biến Số (Code Luau)**, cách thiết lập **GitHub cho 3 thành viên (Khang, Quang Khai, Phạm Gia Bảo)**, và cách **chia thư mục code cho 3 người** để làm song song không bao giờ bị đè file (merge conflict).

---

## 1. Phân Biệt "Hằng Số" (Google Drive) và "Biến Số" (GitHub)

Đúng như **Quang Khai** và **Khang** đã trao đổi:

| Phân loại | Gồm những gì? | Dung lượng | Lưu ở đâu? | Cách dùng |
| :--- | :--- | :--- | :--- | :--- |
| **HẰNG SỐ (Cố định / Database đồ họa)** | • Kho Blender 3D (`.blend`, `.fbx`, ảnh render, nguồn map `Worlds_Gameplay3x_Clean3D`)<br>• File map gốc [`SKYBREAK_Playable_v12_PremiumUI.rbxlx`](../04_Roblox/SKYBREAK_Playable_v12_PremiumUI.rbxlx) | **~9 GB** (Blender)<br>**~318 MB** (`.rbxlx`) | **Google Drive chung** (`SKYBREAK_3D_MoiNhat_2026-10-27`) hoặc **Roblox Cloud (Team Create)** | Mỗi thành viên chỉ cần tải file `.rbxlx` từ Google Drive về bỏ vào thư mục `04_Roblox/` **1 lần duy nhất**. File [`.gitignore`](../.gitignore) đã tự động chặn các file nặng này để không đẩy nhầm lên GitHub. |
| **BIẾN SỐ (Thay đổi liên tục mỗi ngày)** | • Toàn bộ **129 file code Luau** trong 3 thư mục Hạng Mục `04_Roblox/0x_HangMuc*`<br>• Bộ tool đồng bộ tự động [`05_Pipeline_Tools_27x_9x/`](../05_Pipeline_Tools_27x_9x/)<br>• Cấu hình Rojo [`default.project.json`](../04_Roblox/default.project.json) | **4.11 MB** (Code Luau)<br>**0.59 MB** (Tool đồng bộ)<br>*(Tổng chỉ **~4.7 MB**)* | **GitHub Repository** (`https://github.com/hienkhang2004-coder/SKYBREAK-Roblox-RPG.git`) | Sửa trong `04_Roblox/0x_HangMuc*`, `git commit` + `git push` (chỉ mất **1–2 giây**). Khi người khác `git pull` về, chạy lệnh đồng bộ là code mới tự động nạp vào `04_Roblox/src/` và file `.rbxlx` trên máy họ! |

---

## 2. Giải Đáp Thắc Mắc Về GitHub Free & Tài Khoản Nhóm

1. **GitHub Free có giới hạn số lần commit không?**
   - **KHÔNG GIỚI HẠN!** Đúng như Quang Khai nói, GitHub Free cho phép tạo cả kho Public lẫn Private với **số lần commit/push không giới hạn** (1 ngày commit 500 lần cũng hoàn toàn miễn phí).
   - Giới hạn duy nhất của GitHub là **không cho phép 1 file lẻ nặng quá 100 MB** — đó là lý do mình đã cấu hình sẵn [`.gitignore`](../.gitignore) để loại bỏ file `.rbxlx` (~318 MB), thư mục build `04_Roblox/src/` và thư mục Blender, chỉ đẩy **~4.7 MB code Luau trong 3 thư mục Hạng Mục** lên GitHub.

2. **Có nên dùng chung 1 tài khoản GitHub không? Làm sao nắm bắt tình hình chung của dự án?**
   - **KHÔNG dùng chung 1 tài khoản!** Mỗi người (**Khang**, **Quang Khai**, **Gia Bảo**) dùng **1 tài khoản GitHub cá nhân riêng**.
   - **Cách thêm thành viên**: Khang (chủ repo `hienkhang2004-coder/SKYBREAK-Roblox-RPG`) vào **Settings -> Collaborators -> Add people**, nhập tên tài khoản hoặc email GitHub của **Quang Khai** và **Gia Bảo**.
   - **Cách theo dõi tiến độ dự án cực dễ**:
     - Khi mỗi người dùng tài khoản riêng, mở mục **Commits** hoặc **Insights -> Network / Contributors** trên GitHub sẽ hiện rõ: **Ai** vừa sửa file nào, vào **lúc mấy giờ**, thêm dòng nào (màu xanh), xóa dòng nào (màu đỏ).
     - Cài thêm ứng dụng **GitHub Desktop** (có giao diện đồ họa trực quan, không cần nhớ lệnh đen trắng) để bấm 1 nút là thấy ngay lịch sử thay đổi của cả 3 người.

---

## 3. Chia Việc & Chia Thư Mục Cho 3 Người ("3 th mỗi th lo 1 phần")

> **Lưu ý cực kỳ quan trọng về cấu trúc thư mục chuẩn (`04_Roblox/0x_HangMuc*`)**:
> Mã nguồn chuẩn được chia tách vật lý vào 3 thư mục Hạng Mục trong `04_Roblox/`. Khi chạy `sync_solid3d_and_scripts_to_rbxlx.py`, hệ thống sẽ gom cả 3 thư mục Hạng Mục sang bản build `04_Roblox/src/` (gitignored) rồi đóng gói vào `.rbxlx`.
> **CHỈ SỬA TRONG 3 THƯ MỤC HẠNG MỤC (`04_Roblox/0x_HangMuc*`), TUYỆT ĐỐI KHÔNG SỬA TRONG `04_Roblox/src/`!**

### 👤 Hạng Mục 1: Gameplay, Combat, Boss AI & Thế Giới (Server-Side)
- **File mở nhanh**: [`01_HangMuc1_Server_Combat_World.code-workspace`](../01_HangMuc1_Server_Combat_World.code-workspace)
- **Phụ trách chính**: Logic đánh quái, sát thương chiêu thức, AI Boss, nhiệm vụ, đảo, sự kiện thế giới, bảo mật remote & lưu trữ dữ liệu.
- **Thư mục làm việc riêng**: [`04_Roblox/01_HangMuc1_Server_Combat_World/ServerScriptService/`](../04_Roblox/01_HangMuc1_Server_Combat_World/ServerScriptService/)
  - `Services/GameService.lua` — Logic M1, chiêu thức Z/X/C/V/F, sát thương, máu quái & Boss.
  - `Services/SkybreakCombatExpansion.lua` — Kỹ năng vũ khí mới, súng/cung tầm xa, hiệu ứng trúng đòn.
  - `Services/WorldService.lua` & `Services/SkybreakWorldEventsService.lua` — Quái xuất hiện (spawn), Sea Events, Boss Raid.
  - `Services/PlayerDataService.lua`, `Services/RemoteGuard.lua`, `Services/DevGate.lua` — Lưu/tải dữ liệu người chơi, bảo vệ tần suất Remote và khóa Dev Sandbox.
- **Câu lệnh dặn AI (Claude / Antigravity) cho Người 1**:
  > *"Tôi phụ trách Hạng mục 1 (Server & Combat). Bạn CHỈ ĐƯỢC PHÉP chỉnh sửa các file nằm trong `04_Roblox/01_HangMuc1_Server_Combat_World/`, tuyệt đối không sửa các file trong `02_HangMuc2_UI_Shop_Config/`, `03_HangMuc3_3D_VuKhi_Giap_VFX/` hoặc `04_Roblox/src/` để tránh xung đột Git với đồng đội."*

### 👤 Hạng Mục 2: Giao Diện UI/UX, Kho Đồ, Shop, Rèn Đồ & Cân Bằng Thông Số (Client UI & Config)
- **File mở nhanh**: [`02_HangMuc2_UI_Shop_Config.code-workspace`](../02_HangMuc2_UI_Shop_Config.code-workspace)
- **Phụ trách chính**: Màn hình Kho đồ (Inventory), Cửa hàng NPC, Rèn đồ (Forge), Bản đồ, HUD máu/năng lượng, và chỉnh sửa chỉ số vũ khí/giáp/độ hiếm.
- **Thư mục làm việc riêng**: [`04_Roblox/02_HangMuc2_UI_Shop_Config/`](../04_Roblox/02_HangMuc2_UI_Shop_Config/)
  - `StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/` (`Screens/Inventory.lua`, `Screens/NPCShop.lua`, `Screens/Forge.lua`, `Screens/HUD.lua`, `Controllers/InventoryController.lua`, `Components/ViewportOrbit.lua`)
  - `ReplicatedStorage/SkybreakShared/Config/` (`ArsenalExpansionConfig.lua`, `RarityConfig.lua`, `WorldConfig.lua`)
- **Câu lệnh dặn AI (Claude / Antigravity) cho Người 2**:
  > *"Tôi phụ trách Hạng mục 2 (UI & Config). Bạn CHỈ ĐƯỢC PHÉP chỉnh sửa các file nằm trong `04_Roblox/02_HangMuc2_UI_Shop_Config/`, tuyệt đối không sửa `01_HangMuc1_Server_Combat_World/`, `03_HangMuc3_3D_VuKhi_Giap_VFX/` hoặc `04_Roblox/src/` để tránh xung đột Git."*

### 👤 Hạng Mục 3: Đồ Họa 3D, Vũ Khí/Giáp 3D, Hiệu Ứng VFX, Camera & Âm Thanh (3D Assets & VFX)
- **File mở nhanh**: [`03_HangMuc3_3D_VuKhi_Giap_VFX.code-workspace`](../03_HangMuc3_3D_VuKhi_Giap_VFX.code-workspace)
- **Phụ trách chính**: Thiết kế/chỉnh sửa mô hình 3D vũ khí, súng, cung, 8 bộ giáp mặc lên người, hiệu ứng chém/bắn VFX, điều khiển bay/camera, âm thanh, và quản lý kho Google Drive + đồng bộ build.
- **Thư mục làm việc riêng**: [`04_Roblox/03_HangMuc3_3D_VuKhi_Giap_VFX/`](../04_Roblox/03_HangMuc3_3D_VuKhi_Giap_VFX/)
  - `ReplicatedStorage/DelegatedV5Renderer.lua` & `ReplicatedStorage/Shared/` (`Config.lua`, `Skybreak3DEquipment.lua`, `SkybreakExpansion3DAndVFX.lua`, `SkybreakCombatData.lua`)
  - `StarterPlayer/StarterPlayerScripts/` (`ClientBootstrap.client.lua`, `SkybreakFlightAndCamera.client.lua`, `DelegatedV5.client.lua`, `SkybreakAudioEngine.lua`, `SkybreakClient/UniversalVFXOverhaul.lua`, `SkybreakClient/VFXStudioLibrary.lua`, `SkybreakClient/DragonSovereignVFX.lua`)
- **Câu lệnh dặn AI (Claude / Antigravity) cho Người 3**:
  > *"Tôi phụ trách Hạng mục 3 (Mô hình 3D & VFX). Bạn CHỈ ĐƯỢC PHÉP chỉnh sửa các file nằm trong `04_Roblox/03_HangMuc3_3D_VuKhi_Giap_VFX/`, tuyệt đối không sửa `01_HangMuc1_Server_Combat_World/`, `02_HangMuc2_UI_Shop_Config/` hoặc `04_Roblox/src/` để tránh xung đột Git."*

---

## 4. Quy Trình 4 Bước Hàng Ngày Cho Cả 3 Anh Em

### Bước 0 (Chỉ làm 1 lần đầu tiên trên máy của Quang Khai & Gia Bảo):
1. Clone code từ GitHub về máy:
   ```powershell
   git clone https://github.com/hienkhang2004-coder/SKYBREAK-Roblox-RPG.git
   ```
2. Lên link **Google Drive (`SKYBREAK_3D_MoiNhat_2026-10-27`)** tải file `SKYBREAK_Playable_v12_PremiumUI.rbxlx` về bỏ vào đúng thư mục `04_Roblox/SKYBREAK_Playable_v12_PremiumUI.rbxlx`.

### Bước 1 — Trước khi bắt đầu code: Lấy bản mới nhất của đồng đội về
```powershell
git pull
```

### Bước 2 — Chỉnh sửa code (bằng Cursor / VS Code / Antigravity / Claude)
- Ai phụ trách phần nào thì mở đúng thư mục Hạng Mục của người đó (`04_Roblox/01_HangMuc1_Server_Combat_World`, `04_Roblox/02_HangMuc2_UI_Shop_Config`, hoặc `04_Roblox/03_HangMuc3_3D_VuKhi_Giap_VFX`) để sửa. **Không sửa trong `04_Roblox/src/`**.

### Bước 3 — Bơm code vừa sửa vào file `.rbxlx` và kiểm định
Chạy lệnh đồng bộ và kiểm tra lint (cập nhật 129 script từ `04_Roblox/0x_HangMuc*` vào `04_Roblox/src/` và `.rbxlx`):
```powershell
python 05_Pipeline_Tools_27x_9x/sync_solid3d_and_scripts_to_rbxlx.py
python 05_Pipeline_Tools_27x_9x/lint_luau_globals.py
```
*(Nếu dùng plugin **Rojo** trong Roblox Studio: Rojo đọc từ `04_Roblox/src/`, nên cần chạy lệnh sync trước để cập nhật `04_Roblox/src/`).*

### Bước 4 — Test ngon lành trong Studio xong thì đẩy thư mục Hạng Mục lên GitHub
```powershell
# Stage đúng thư mục Hạng Mục của mình (ví dụ Hạng Mục 1, 2 hoặc 3 — KHÔNG git add 04_Roblox/src vì đã gitignore):
git add 04_Roblox/01_HangMuc1_Server_Combat_World 04_Roblox/02_HangMuc2_UI_Shop_Config 04_Roblox/03_HangMuc3_3D_VuKhi_Giap_VFX
git commit -m "fix(HangMucX): Mo ta ngan gon phan vua sua"
git push
```
