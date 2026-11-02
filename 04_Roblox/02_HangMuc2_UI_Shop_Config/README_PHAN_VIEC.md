# HẠNG MỤC 2: GIAO DIỆN UI/UX, KHO ĐỒ, SHOP, RÈN ĐỒ & BẢNG CHỈ SỐ (56 FILE LUAU)

Thư mục này chứa toàn bộ **56 script Giao diện UI Client & Bảng cấu hình thông số**, hoàn toàn độc lập với 2 hạng mục còn lại:

- `StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/*`: 13 màn hình giao diện chính (`Inventory.lua`, `NPCShop.lua`, `Forge.lua`, `HUD.lua`, `Skills.lua`, `Fruits.lua`, `WorldMap.lua`, `Raid.lua`, `QuestJournal.lua`, `SocialRewards.lua`...).
- `StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Controllers/*`: Bộ điều khiển trạng thái UI (`InventoryController.lua`, `HUDController.lua`, `QuestController.lua`, `PartyController.lua`).
- `StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Components/*`: Các thành phần giao diện (`ViewportOrbit.lua`, `ItemSlot.lua`, `CelestialMinimap.lua`, `LootFeed.lua`...).
- `ReplicatedStorage/SkybreakShared/Config/*`: Bảng thông số trang bị, vũ khí, 8 bộ giáp (`ArsenalExpansionConfig.lua`), độ hiếm (`RarityConfig.lua`), màu sắc giao diện (`Theme.lua`).

## Quy trình sửa code & đồng bộ vào game:
1. Chỉnh sửa trực tiếp các file `.lua` trong thư mục `02_HangMuc2_UI_Shop_Config` này.
2. Chạy lệnh đồng bộ để tự động cập nhật vào `04_Roblox/src` và file game `.rbxlx`:
   ```powershell
   & "C:\Program Files\Blender Foundation\Blender 4.3\4.3\python\bin\python.exe" 05_Pipeline_Tools_27x_9x/sync_solid3d_and_scripts_to_rbxlx.py
   ```
   *(Hoặc dùng `python 05_Pipeline_Tools_27x_9x/sync_solid3d_and_scripts_to_rbxlx.py` trên máy có cài Python).*
3. Commit & Push thư mục `04_Roblox/02_HangMuc2_UI_Shop_Config` lên GitHub.
