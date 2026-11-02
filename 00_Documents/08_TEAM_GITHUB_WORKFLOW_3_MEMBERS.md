# HƯỚNG DẪN LÀM VIỆC NHÓM 3 NGƯỜI TRÊN GITHUB & GOOGLE DRIVE (SKYBREAK RPG)

Tài liệu này giải thích cách tách **Hằng Số (Đồ họa 3D / Map gốc)** và **Biến Số (Code Luau)**, cách thiết lập **GitHub cho 3 thành viên (Khang, Quang Khai, Phạm Gia Bảo)**, và cách **chia thư mục code cho 3 người** để làm song song không bao giờ bị đè file (merge conflict).

---

## 1. Phân Biệt "Hằng Số" (Google Drive) và "Biến Số" (GitHub)

Đúng như **Quang Khai** và **Khang** đã trao đổi:

| Phân loại | Gồm những gì? | Dung lượng | Lưu ở đâu? | Cách dùng |
| :--- | :--- | :--- | :--- | :--- |
| **HẰNG SỐ (Cố định / Database đồ họa)** | • Kho Blender 3D (`.blend`, `.fbx`, ảnh render)<br>• File map gốc [`SKYBREAK_Playable_v12_PremiumUI.rbxlx`](../04_Roblox/SKYBREAK_Playable_v12_PremiumUI.rbxlx) | **~9 GB** (Blender)<br>**297.75 MB** (`.rbxlx`) | **Google Drive chung** (`SKYBREAK_3D_MoiNhat_2026-10-27`) hoặc **Roblox Cloud (Team Create)** | Mỗi thành viên chỉ cần tải file `.rbxlx` (297.7 MB) từ Google Drive về bỏ vào thư mục `04_Roblox/` **1 lần duy nhất**. File [`.gitignore`](../.gitignore) đã tự động chặn các file nặng này để không đẩy nhầm lên GitHub. |
| **BIẾN SỐ (Thay đổi liên tục mỗi ngày)** | • Toàn bộ **129 file code Luau** trong [`04_Roblox/src/`](../04_Roblox/src/)<br>• Bộ tool đồng bộ tự động [`05_Pipeline_Tools_27x_9x/`](../05_Pipeline_Tools_27x_9x/)<br>• Cấu hình Rojo [`default.project.json`](../04_Roblox/default.project.json) | **4.11 MB** (Code Luau)<br>**0.59 MB** (Tool đồng bộ)<br>*(Tổng chỉ **~4.7 MB**)* | **GitHub Repository** (`https://github.com/hienkhang2004-coder/SKYBREAK-Roblox-RPG.git`) | Sửa dòng nào `git commit` + `git push` dòng đó (chỉ mất **1–2 giây**). Khi người khác `git pull` về, chạy lệnh đồng bộ 3 giây là code mới tự động nạp vào file `.rbxlx` trên máy họ! |

---

## 2. Giải Đáp Thắc Mắc Về GitHub Free & Tài Khoản Nhóm

1. **GitHub Free có giới hạn số lần commit không?**
   - **KHÔNG GIỚI HẠN!** Đúng như Quang Khai nói, GitHub Free cho phép tạo cả kho Public lẫn Private với **số lần commit/push không giới hạn** (1 ngày commit 500 lần cũng hoàn toàn miễn phí).
   - Giới hạn duy nhất của GitHub là **không cho phép 1 file lẻ nặng quá 100 MB** — đó là lý do mình đã cấu hình sẵn [`.gitignore`](../.gitignore) để loại bỏ file `.rbxlx` (297 MB) và thư mục Blender, chỉ đẩy **4.7 MB code Luau** lên GitHub.

2. **Có nên dùng chung 1 tài khoản GitHub không? Làm sao nắm bắt tình hình chung của dự án?**
   - **KHÔNG dùng chung 1 tài khoản!** Mỗi người (**Khang**, **Quang Khai**, **Gia Bảo**) dùng **1 tài khoản GitHub cá nhân riêng**.
   - **Cách thêm thành viên**: Khang (chủ repo `hienkhang2004-coder/SKYBREAK-Roblox-RPG`) vào **Settings -> Collaborators -> Add people**, nhập tên tài khoản hoặc email GitHub của **Quang Khai** và **Gia Bảo**.
   - **Cách theo dõi tiến độ dự án cực dễ**:
     - Khi mỗi người dùng tài khoản riêng, mở mục **Commits** hoặc **Insights -> Network / Contributors** trên GitHub sẽ hiện rõ: **Ai** vừa sửa file nào, vào **lúc mấy giờ**, thêm dòng nào (màu xanh), xóa dòng nào (màu đỏ).
     - Cài thêm ứng dụng **GitHub Desktop** (có giao diện đồ họa trực quan, không cần nhớ lệnh đen trắng) để bấm 1 nút là thấy ngay lịch sử thay đổi của cả 3 người.

---

## 3. Chia Việc & Chia Thư Mục Cho 3 Người ("3 th mỗi th lo 1 phần")

> **Lưu ý cực kỳ quan trọng về cấu trúc thư mục Roblox**:
> Trong Roblox Studio, các câu lệnh `require(ReplicatedStorage.Shared...)` và bộ tool đồng bộ `.rbxlx` bắt buộc phải giữ nguyên tên các thư mục dịch vụ chuẩn của Roblox (`ServerScriptService`, `ReplicatedStorage`, `StarterPlayer`).
> Vì vậy, **KHÔNG đổi tên thư mục gốc trong `04_Roblox/src/`**, mà mình đã tạo sẵn **3 file Workspace tách riêng 3 hạng mục** ngay ngoài thư mục gốc. Ai làm hạng mục nào chỉ cần bấm đúp mở đúng file `.code-workspace` đó bằng VS Code / Cursor / Antigravity là thanh bên trái **chỉ hiện đúng thư mục của người đó**!

### 👤 Hạng Mục 1: Gameplay, Combat, Boss AI & Thế Giới (Server-Side)
- **File mở nhanh**: [`01_HangMuc1_Server_Combat_World.code-workspace`](../01_HangMuc1_Server_Combat_World.code-workspace)
- **Phụ trách chính**: Logic đánh quái, sát thương chiêu thức, AI Boss, nhiệm vụ, đảo, sự kiện thế giới.
- **Thư mục làm việc riêng**: [`04_Roblox/src/ServerScriptService/Services/`](../04_Roblox/src/ServerScriptService/Services/)
  - [`GameService.lua`](../04_Roblox/src/ServerScriptService/Services/GameService.lua) — Logic M1, chiêu thức Z/X/C/V/F, sát thương, máu quái & Boss.
  - [`SkybreakCombatExpansion.lua`](../04_Roblox/src/ServerScriptService/Services/SkybreakCombatExpansion.lua) — Kỹ năng vũ khí mới, súng/cung tầm xa, hiệu ứng trúng đòn.
  - [`WorldService.lua`](../04_Roblox/src/ServerScriptService/Services/WorldService.lua) & [`SkybreakWorldEventsService.lua`](../04_Roblox/src/ServerScriptService/Services/SkybreakWorldEventsService.lua) — Quái xuất hiện (spawn), Sea Events, Boss Raid.
  - [`PlayerDataService.lua`](../04_Roblox/src/ServerScriptService/Services/PlayerDataService.lua) — Lưu/tải dữ liệu người chơi, cấp độ, kho đồ khởi đầu.
- **Câu lệnh dặn AI (Claude / Antigravity) cho Người 1**:
  > *"Tôi phụ trách Hạng mục 1 (Server & Combat). Bạn CHỈ ĐƯỢC PHÉP chỉnh sửa các file nằm trong `04_Roblox/src/ServerScriptService/`, tuyệt đối không sửa các file trong `UI/` hoặc `ReplicatedStorage/Shared/` để tránh xung đột Git với đồng đội."*

### 👤 Hạng Mục 2: Giao Diện UI/UX, Kho Đồ, Shop, Rèn Đồ & Cân Bằng Thông Số (Client UI & Config)
- **File mở nhanh**: [`02_HangMuc2_UI_Shop_Config.code-workspace`](../02_HangMuc2_UI_Shop_Config.code-workspace)
- **Phụ trách chính**: Màn hình Kho đồ (Inventory), Cửa hàng NPC, Rèn đồ (Forge), Bản đồ, HUD máu/năng lượng, và chỉnh sửa chỉ số vũ khí/giáp/độ hiếm.
- **Thư mục làm việc riêng**:
  - [`04_Roblox/src/StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/`](../04_Roblox/src/StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/)
    - [`Screens/Inventory.lua`](../04_Roblox/src/StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/Inventory.lua), [`Screens/NPCShop.lua`](../04_Roblox/src/StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/NPCShop.lua), [`Screens/Forge.lua`](../04_Roblox/src/StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/Forge.lua), [`Screens/HUD.lua`](../04_Roblox/src/StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/HUD.lua)
    - [`Controllers/InventoryController.lua`](../04_Roblox/src/StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Controllers/InventoryController.lua), [`Components/ViewportOrbit.lua`](../04_Roblox/src/StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Components/ViewportOrbit.lua)
  - [`04_Roblox/src/ReplicatedStorage/SkybreakShared/Config/`](../04_Roblox/src/ReplicatedStorage/SkybreakShared/Config/)
    - [`ArsenalExpansionConfig.lua`](../04_Roblox/src/ReplicatedStorage/SkybreakShared/Config/ArsenalExpansionConfig.lua) — Chỉ số tấn công, thủ, tốc chạy, giá tiền của toàn bộ vũ khí & 8 bộ giáp.
    - [`RarityConfig.lua`](../04_Roblox/src/ReplicatedStorage/SkybreakShared/Config/RarityConfig.lua) — Màu sắc và cấp độ hiếm.
- **Câu lệnh dặn AI (Claude / Antigravity) cho Người 2**:
  > *"Tôi phụ trách Hạng mục 2 (UI & Config). Bạn CHỈ ĐƯỢC PHÉP chỉnh sửa các file nằm trong `04_Roblox/src/StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/` và `04_Roblox/src/ReplicatedStorage/SkybreakShared/`, tuyệt đối không sửa `ServerScriptService/` hay `ReplicatedStorage/Shared/` để tránh xung đột Git."*

### 👤 Hạng Mục 3: Đồ Họa 3D, Vũ Khí/Giáp 3D, Hiệu Ứng VFX & Âm Thanh (3D Assets & VFX)
- **File mở nhanh**: [`03_HangMuc3_3D_VuKhi_Giap_VFX.code-workspace`](../03_HangMuc3_3D_VuKhi_Giap_VFX.code-workspace)
- **Phụ trách chính**: Thiết kế/chỉnh sửa mô hình 3D vũ khí, súng, cung, 8 bộ giáp mặc lên người, hiệu ứng chém/bắn VFX, âm thanh, và quản lý kho Google Drive + đồng bộ build.
- **Thư mục làm việc riêng**:
  - [`04_Roblox/src/ReplicatedStorage/Shared/`](../04_Roblox/src/ReplicatedStorage/Shared/)
    - [`Skybreak3DEquipment.lua`](../04_Roblox/src/ReplicatedStorage/Shared/Skybreak3DEquipment.lua) — Khung 3D gắn vũ khí/giáp/cánh lên nhân vật.
    - [`SkybreakExpansion3DAndVFX.lua`](../04_Roblox/src/ReplicatedStorage/Shared/SkybreakExpansion3DAndVFX.lua) — Hình dáng 3D chi tiết của kiếm, đại đao, súng, cung, giáp 7 món, cổ vật và tia đạn VFX.
    - [`SkybreakCombatData.lua`](../04_Roblox/src/ReplicatedStorage/Shared/SkybreakCombatData.lua) — Thông số đường đạn, tốc độ bay và màu VFX của súng/cung.
  - [`04_Roblox/src/StarterPlayer/StarterPlayerScripts/SkybreakClient/`](../04_Roblox/src/StarterPlayer/StarterPlayerScripts/SkybreakClient/)
    - [`UniversalVFXOverhaul.lua`](../04_Roblox/src/StarterPlayer/StarterPlayerScripts/SkybreakClient/UniversalVFXOverhaul.lua), [`VFXStudioLibrary.lua`](../04_Roblox/src/StarterPlayer/StarterPlayerScripts/SkybreakClient/VFXStudioLibrary.lua), [`DragonSovereignVFX.lua`](../04_Roblox/src/StarterPlayer/StarterPlayerScripts/SkybreakClient/DragonSovereignVFX.lua)
- **Câu lệnh dặn AI (Claude / Antigravity) cho Người 3**:
  > *"Tôi phụ trách Hạng mục 3 (Mô hình 3D & VFX). Bạn CHỈ ĐƯỢC PHÉP chỉnh sửa các file nằm trong `04_Roblox/src/ReplicatedStorage/Shared/` và các file VFX trong `SkybreakClient/`, tuyệt đối không sửa `ServerScriptService/` hay `UI/` để tránh xung đột Git."*

---

## 4. Quy Trình 4 Bước Hàng Ngày Cho Cả 3 Anh Em

### Bước 0 (Chỉ làm 1 lần đầu tiên trên máy của Quang Khai & Gia Bảo):
1. Clone code từ GitHub về máy:
   ```powershell
   git clone https://github.com/hienkhang2004-coder/SKYBREAK-Roblox-RPG.git
   ```
2. Lên link **Google Drive (`SKYBREAK_3D_MoiNhat_2026-10-27`)** tải file `SKYBREAK_Playable_v12_PremiumUI.rbxlx` (297.7 MB) về bỏ vào đúng thư mục `04_Roblox/SKYBREAK_Playable_v12_PremiumUI.rbxlx`.

### Bước 1 — Trước khi bắt đầu code: Lấy bản mới nhất của đồng đội về
```powershell
git pull
```

### Bước 2 — Chỉnh sửa code (bằng Cursor / VS Code / Antigravity / Claude)
- Ai phụ trách phần nào thì mở đúng thư mục của người đó trong `04_Roblox/src/` để sửa.

### Bước 3 — Bơm code vừa sửa vào file `.rbxlx` để vào Roblox Studio test ngay
Chạy 1 lệnh Python (mất ~5 giây, tự động cập nhật cả 129 script vào file `.rbxlx`):
```powershell
python 05_Pipeline_Tools_27x_9x/sync_solid3d_and_scripts_to_rbxlx.py
```
*(Hoặc nếu dùng plugin **Rojo** trong Roblox Studio thì mở file [`04_Roblox/default.project.json`](../04_Roblox/default.project.json), code sửa tới đâu nhảy vào Studio tới đó theo thời gian thực).*

### Bước 4 — Test ngon lành xong thì đẩy code lên GitHub cho 2 người kia
```powershell
git add 04_Roblox/src 04_Roblox/default.project.json 05_Pipeline_Tools_27x_9x 00_Documents
git commit -m "Mo ta ngan gon phan vua sua"
git push
```
