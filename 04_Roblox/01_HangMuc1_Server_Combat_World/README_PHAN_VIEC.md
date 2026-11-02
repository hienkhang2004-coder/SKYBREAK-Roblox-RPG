# HẠNG MỤC 1: SERVER, COMBAT, BOSS AI & THẾ GIỚI (27 FILE LUAU)

Thư mục này chứa toàn bộ **27 script phía Server** (`ServerScriptService` & `ServerStorage`), hoàn toàn độc lập với 2 hạng mục còn lại:

- `ServerScriptService/Services/GameService.lua`: Hệ thống chiến đấu cốt lõi (M1, chiêu Z/X/C/V/F, sát thương, máu quái & Boss, trạng thái nhân vật).
- `ServerScriptService/Services/SkybreakCombatExpansion.lua`: Kỹ năng vũ khí cận chiến mở rộng & súng/cung tầm xa.
- `ServerScriptService/Services/WorldService.lua` & `SkybreakWorldEventsService.lua`: Quái xuất hiện (spawn), Boss Raid, Sea Events, cổng dịch chuyển.
- `ServerScriptService/Services/PlayerDataService.lua`: Dữ liệu người chơi, cấp độ, vàng, kho đồ.
- `ServerScriptService/SkybreakServer/*`: Các dịch vụ phụ trợ (CraftingService, InventoryService, QuestService, SkillService, TravelService).

## Quy trình sửa code & đồng bộ vào game:
1. Chỉnh sửa trực tiếp các file `.lua` trong thư mục `01_HangMuc1_Server_Combat_World` này.
2. Chạy lệnh đồng bộ để tự động cập nhật vào `04_Roblox/src` và file game `.rbxlx`:
   ```powershell
   & "C:\Program Files\Blender Foundation\Blender 4.3\4.3\python\bin\python.exe" 05_Pipeline_Tools_27x_9x/sync_solid3d_and_scripts_to_rbxlx.py
   ```
   *(Hoặc dùng `python 05_Pipeline_Tools_27x_9x/sync_solid3d_and_scripts_to_rbxlx.py` trên máy có cài Python).*
3. Commit & Push thư mục `04_Roblox/01_HangMuc1_Server_Combat_World` lên GitHub.
