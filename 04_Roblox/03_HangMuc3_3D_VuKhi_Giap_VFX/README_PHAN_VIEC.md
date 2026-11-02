# HẠNG MỤC 3: MÔ HÌNH 3D VŨ KHÍ, SÚNG/CUNG, GIÁP 3D, CHUYỂN ĐỘNG & HIỆU ỨNG VFX (46 FILE LUAU)

Thư mục này chứa toàn bộ **46 script Mô hình 3D, Trang bị, Hoạt ảnh & Hiệu ứng VFX**, hoàn toàn độc lập với 2 hạng mục còn lại:

- `ReplicatedStorage/Shared/SkybreakExpansion3DAndVFX.lua`: Hình dáng 3D chi tiết của kiếm, đại đao, súng, cung, 8 bộ giáp (mỗi bộ tách 7 món độc lập), nguyên liệu rèn và tia đạn VFX.
- `ReplicatedStorage/Shared/Skybreak3DEquipment.lua`: Khung gắn vũ khí 3D, giáp 3D và cánh lên nhân vật.
- `ReplicatedStorage/Shared/SkybreakCombatData.lua`: Thông số đường đạn, tốc độ đạn và màu sắc hiệu ứng súng/cung.
- `ReplicatedStorage/GuardianMotion/*`: 23 bộ chuyển động đòn đánh & di chuyển của nhân vật.
- `StarterPlayer/StarterPlayerScripts/SkybreakClient/UniversalVFXOverhaul.lua`, `VFXStudioLibrary.lua`, `DragonSovereignVFX.lua`, `SkybreakClientVFX.lua`: Toàn bộ hiệu ứng kỹ năng, hào quang, âm thanh và camera chiến đấu.

## Quy trình sửa code & đồng bộ vào game:
1. Chỉnh sửa trực tiếp các file `.lua` trong thư mục `03_HangMuc3_3D_VuKhi_Giap_VFX` này.
2. Chạy lệnh đồng bộ để tự động cập nhật vào `04_Roblox/src` và file game `.rbxlx`:
   ```powershell
   & "C:\Program Files\Blender Foundation\Blender 4.3\4.3\python\bin\python.exe" 05_Pipeline_Tools_27x_9x/sync_solid3d_and_scripts_to_rbxlx.py
   ```
   *(Hoặc dùng `python 05_Pipeline_Tools_27x_9x/sync_solid3d_and_scripts_to_rbxlx.py` trên máy có cài Python).*
3. Commit & Push thư mục `04_Roblox/03_HangMuc3_3D_VuKhi_Giap_VFX` lên GitHub.
