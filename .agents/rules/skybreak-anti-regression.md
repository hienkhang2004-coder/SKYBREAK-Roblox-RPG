---
trigger: always_on
description: Bộ 8 Quy Tắc Chống Nhảy Lỗi Chéo (Anti-Regression Rules) và Ranh Giới Hạng Mục cho dự án SKYBREAK Roblox RPG.
---

# SKYBREAK — Bộ Quy Tắc Chống Nhảy Lỗi Chéo (Anti-Regression Rules)

Khi sửa lỗi hoặc cập nhật bất kỳ tính năng nào trong **SKYBREAK**, luôn tuân thủ nghiêm ngặt 8 quy tắc dưới đây để tránh việc sửa được lỗi này lại phát sinh lỗi khác:

1. **Rule 1 — Kiểm tra cả 3 đầu mối trước khi sửa Phím bấm / Kỹ năng (End-to-End Trace)**:
   - Trước khi sửa bất kỳ phím (`Z, X, C, V, F, Q, M1, Shift`) hay kỹ năng nào, bắt buộc đọc kiểm tra đủ 3 nơi:
     1. `StarterPlayer/StarterPlayerScripts/ClientBootstrap.client.lua` (`ContextActionService`, nơi gửi `AbilityRequest` và nhận `StateUpdate` / `TeleportSnap`).
     2. `StarterPlayer/StarterPlayerScripts/SkybreakFlightAndCamera.client.lua` (`UserInputService`, nơi điều khiển Bay 3D `startFreeFlight`, Flash Step, Camera, Gamepad).
     3. Server (`ServerScriptService/Services/GameService.lua` & `SkybreakCombatExpansion.lua`) — kiểm tra xem Server có trả về `TeleportSnap`, `JumpPadUntil`, hoặc `FreeFlightUntil` làm ngắt/xung đột chuyển động ở Client hay không.

2. **Rule 2 — Cấm dùng Fallback "Đánh đồng tất cả" (Explicit Whitelisting)**:
   - Không bao giờ viết nhánh `else` ép mọi Trái Ác Quỷ hoặc mọi Slot vũ khí chạy chung một hành vi đặc thù (như bay 3D hay đắp mảnh giáp khối hộp).
   - **Với kỹ năng `[F]`**:
     - **Chỉ 6 Trái Bay** (`GaleCore`, `SandstoneCore`, `SolarFlameCore`, `CelestialLightCore`, `StarforgedMagmaCore`, `AstralGravityCore`) + **`AbyssalSovereignCore` ở Form 2** (`DragonFormTier >= 2`) mới được vào chế độ Bay 3D (`startFreeFlight()`) khi đang cầm Slot 2.
     - **6 Trái `[F]` Không Phải Bay** (`GlacierIceCore`, `ThunderRumbleCore`, `DimensionalPortalCore`, `SolarTitanCore`, `AetherflowCore`, `AbyssalSovereignCore` ở dạng Người / Form 1) và **Slot 1 / 3 / 4** không bao giờ kích hoạt bay 3D dù bấm hay giữ `[F]`, mà phải kích hoạt `SlotMove("F")` tức thì (`0ms`).

3. **Rule 3 — Luôn tra cứu đủ bộ Canonical ID + Legacy Alias của 12 Trái Ác Quỷ**:
   - Mọi bảng tra cứu (`Map` / `Table` / điều kiện `if`) bắt buộc hỗ trợ đầy đủ cả ID chuẩn lẫn Alias (`GaleCore`/`Gale`, `SandstoneCore`/`Smoke`, `SolarFlameCore`/`Flame`, `GlacierIceCore`/`Ice`, `ThunderRumbleCore`/`Rumble`, `CelestialLightCore`/`Light`, `StarforgedMagmaCore`/`Magma`, `AstralGravityCore`/`Gravity`, `DimensionalPortalCore`/`Portal`, `SolarTitanCore`/`Buddha`, `AetherflowCore`/`SweetDoughCore`/`Dough`, `AbyssalSovereignCore`/`Dragon`).

4. **Rule 4 — Sửa Phẫu Thuật Tối Thiểu (Surgical Edit) & Bảo toàn Trạng thái Nhân Vật (`Character` / `Rig`)**:
   - Chỉ sửa đúng hàm/nhánh gây lỗi; tuyệt đối không xóa hoặc viết lại các tính năng xung quanh đang chạy ổn định.
   - Nhân vật khởi đầu là Avatar Roblox thật (`IsNativeAvatar`). Không dựng lại hình nhân `SkybreakStarterForm`, không ẩn `Head`, mặt, tóc, quần áo hay phụ kiện thật. Test avatar trên bản đã publish.
   - Mọi hiệu ứng can thiệp vào `HumanoidRootPart.CFrame`, `Transparency`, hoặc `Motor6D` bắt buộc có `Token` chống chồng chéo (khi spam phím) và tự dọn dẹp (`Cleanup` / `Debris`) khi kết thúc, đổi Slot, biến hình, hoặc chết.

5. **Rule 5 — Tự Kiểm Tra Chéo 4 Tình Huống Biên (4-Point Edge-Case Checklist) Trước Khi Hoàn Tất**:
   - *(a)* **Khác Slot**: Đang cầm Slot 1/3/4 bấm phím có bị lẫn hiệu ứng của Slot 2 không?
   - *(b)* **Khác Dạng Biến Hình**: Đang ở dạng Người thường vs. dạng Biến Hình (`SolarTitan`, `DragonFormTier 1 & 2`, `RaceV4`) có hoạt động đúng tỷ lệ và đúng kỹ năng không?
   - *(c)* **Chưa đủ điều kiện**: Khi chưa mở khóa `Mastery` hoặc đang `Cooldown` thì Client có bị kích hoạt nhầm hiệu ứng không?
   - *(d)* **Spam / Ngắt quãng**: Khi bấm phím liên tục hoặc đổi vũ khí/chết giữa chừng có bị kẹt `Anchored`, mất bộ phận cơ thể, hay sót rác VFX (như vòng đỏ của Boss sau khi chết) không?

6. **Rule 6 — Ranh Giới Hạng Mục, Giới Hạn `< 199,000` Bytes & Kiểm Định Tự Động**:
   - Luôn sửa code trong đúng thư mục Hạng Mục được giao (`04_Roblox/01_HangMuc1_Server_Combat_World`, `04_Roblox/02_HangMuc2_UI_Shop_Config`, hoặc `04_Roblox/03_HangMuc3_3D_VuKhi_Giap_VFX`), giữ mọi file `.lua` `< 199,000` bytes, và chạy `sync_solid3d_and_scripts_to_rbxlx.py`, `verify_27x_9x_game_sync.py`, `lint_luau_globals.py` đạt `[PASS]` trước khi báo cáo hoàn tất.

7. **Rule 7 — Gỡ tính năng từ gốc**: Xóa nơi tạo ra tính năng, không dùng vòng lặp nền để dọn hoặc ẩn.

8. **Rule 8 — Một nguồn ánh sáng**: Độ sáng, phơi sáng, bloom và màu chỉ đặt trong `stepAtmosphereAndWeather` của `SkybreakWorldClient.client.lua`.
