# SKYBREAK: Fragments of the Core — AI Agent Workspace Rules (`AGENTS.md`)

Always obey these critical engineering invariants and anti-regression rules when modifying or packaging SKYBREAK (`v12 PremiumUI • Macro-World 27x / 9x Edition`):

---

## I. Kiến Trúc Nguồn & Giới Hạn Engine (Core Pipeline Invariants)

1. **Nguồn Chân Lý Duy Nhất (3 Hạng Mục Handoff -> `src` -> `.rbxlx`)**:
   - `05_Pipeline_Tools_27x_9x/sync_solid3d_and_scripts_to_rbxlx.py` tự động đồng bộ từ **3 thư mục Hạng Mục** (`04_Roblox/01_HangMuc1_Server_Combat_World`, `04_Roblox/02_HangMuc2_UI_Shop_Config`, `04_Roblox/03_HangMuc3_3D_VuKhi_Giap_VFX`) vào `04_Roblox/src/` rồi mới đóng gói vào `04_Roblox/SKYBREAK_Playable_v12_PremiumUI.rbxlx`.
   - **BẮT BUỘC** sửa code trong đúng thư mục Hạng Mục được giao (không sửa trực tiếp mỗi `04_Roblox/src/` vì khi chạy sync sẽ bị thư mục Hạng Mục ghi đè ngược lại!).
   - Tuyệt đối không sửa sang thư mục Hạng Mục của người khác khi đang làm việc phân chia theo Hạng Mục.

2. **Giới Hạn Cứng của Roblox Engine (`< 199,000` Bytes & `< 2,048` Studs)**:
   - Mọi file `.lua` **BẮT BUỘC** `< 199,000` UTF-8 bytes để trình đọc XML của Roblox Studio không bao giờ cắt cụt `<ProtectedString name="Source">`.
   - Mọi `EditableMesh` chunk (`Mesh000..MeshNNN`) và mọi `Part.Size` vật lý **BẮT BUỘC** `< 2,048` studs (`<= 1,748` studs cho mesh tiles, `<= 1,680` studs cho collider parts).

3. **An Toàn Blender Headless & Python**:
   - Không mở giao diện GUI của Blender hoặc chạy nhiều tiến trình `blender.exe` song song.
   - Trên Windows PowerShell, luôn dùng Python của Blender (`& "C:\Program Files\Blender Foundation\Blender 5.2\5.2\python\bin\python.exe"`) khi chạy các script `.py` trong `05_Pipeline_Tools_27x_9x/`.

---

## II. 6 Quy Tắc Chống Nhảy Lỗi Chéo (Anti-Regression Rules)

### Rule 1 — Kiểm tra cả 3 đầu mối trước khi sửa bất kỳ Phím bấm / Kỹ năng nào (End-to-End Trace)
Trước khi sửa bất kỳ phím (`Z, X, C, V, F, Q, M1, Shift`) hay kỹ năng nào, **bắt buộc** đọc kiểm tra đủ 3 nơi để tránh xung đột sự kiện:
1. `StarterPlayer/StarterPlayerScripts/ClientBootstrap.client.lua` (`ContextActionService`, nơi gửi `AbilityRequest` và nhận `StateUpdate` / `TeleportSnap`).
2. `StarterPlayer/StarterPlayerScripts/SkybreakFlightAndCamera.client.lua` (`UserInputService`, nơi điều khiển Bay 3D `startFreeFlight`, Flash Step, Camera, Gamepad).
3. Server (`ServerScriptService/Services/GameService.lua` & `SkybreakCombatExpansion.lua`) — kiểm tra xem Server có trả về `TeleportSnap`, `JumpPadUntil`, hoặc `FreeFlightUntil` làm ngắt/xung đột chuyển động ở Client hay không.

### Rule 2 — Cấm dùng Fallback "Đánh đồng tất cả" (Explicit Whitelisting)
- Không bao giờ viết nhánh `else` ép mọi Trái Ác Quỷ hoặc mọi Slot vũ khí chạy chung một hành vi đặc thù (như bay 3D hay đắp mảnh giáp khối hộp).
- **Ví dụ bắt buộc với kỹ năng `[F]`**:
  - **Nhóm Bay 3D (6-DOF Free Flight)** — chỉ kích hoạt `startFreeFlight()` ở Slot 2 cho đúng 6 Trái Bay (`GaleCore`, `SandstoneCore`, `SolarFlameCore`, `CelestialLightCore`, `StarforgedMagmaCore`, `AstralGravityCore`) và `AbyssalSovereignCore` **chỉ khi ở Form 2** (`DragonFormTier >= 2` / `FruitTransform == "AbyssalSovereign"`).
  - **Nhóm `[F]` Mặt Đất / Nhảy / Lướt / Dịch Chuyển** (`GlacierIceCore` Trượt Băng, `ThunderRumbleCore` Lôi Bộ, `DimensionalPortalCore` Bước Nhảy Lượng Tử, `SolarTitanCore` Bước Nhảy Kim Thân, `AetherflowCore` Bánh Xe Tốc Độ, `AbyssalSovereignCore` Form 0/1 Long Ảnh Bộ, và mọi kỹ năng `[F]` của Slot 1 Võ / Slot 3 Kiếm / Slot 4 Súng) **KHÔNG BAO GIỜ** kích hoạt bay 3D dù bấm hay giữ `[F]`, mà phải kích hoạt `SlotMove("F")` tức thì (`0ms`).

### Rule 3 — Luôn tra cứu đủ bộ Canonical ID + Legacy Alias của 12 Trái Ác Quỷ
Mọi bảng tra cứu (`Map` / `Table` / điều kiện `if`) bắt buộc hỗ trợ đầy đủ cả ID chuẩn lẫn Alias:
- `GaleCore` / `Gale`
- `SandstoneCore` / `Smoke`
- `SolarFlameCore` / `Flame`
- `GlacierIceCore` / `Ice`
- `ThunderRumbleCore` / `Rumble`
- `CelestialLightCore` / `Light`
- `StarforgedMagmaCore` / `Magma`
- `AstralGravityCore` / `Gravity`
- `DimensionalPortalCore` / `Portal`
- `SolarTitanCore` / `Buddha`
- `AetherflowCore` / `SweetDoughCore` / `Dough`
- `AbyssalSovereignCore` / `Dragon`

### Rule 4 — Sửa Phẫu Thuật Tối Thiểu (Surgical Edit) & Bảo toàn Trạng thái Nhân Vật (`Character` / `Rig`)
- Chỉ sửa đúng hàm/nhánh gây lỗi; tuyệt đối không xóa hoặc viết lại các tính năng xung quanh đang chạy ổn định.
- **Nhân vật khởi đầu là Avatar Roblox thật của người chơi (`IsNativeAvatar`)**: Quyết định đã chốt ngày 04/11/2026. Không dựng lại hình nhân giả `SkybreakStarterForm` (tên thuộc tính này chỉ còn dùng làm cờ tương thích), không ẩn `Head`, khuôn mặt, tóc, quần áo hay phụ kiện thật, không đắp khối hộp `SmoothPlastic` lên cơ thể. Khi kiểm tra avatar phải test trên bản đã publish, vì Studio offline (`game.PlaceId == 0`) hiển thị đầu R15 khác bản thật.
- Mọi hiệu ứng can thiệp vào `HumanoidRootPart.CFrame`, `Transparency`, hoặc `Motor6D` bắt buộc có `Token` chống chồng chéo (khi người chơi spam phím) và tự dọn dẹp (`Cleanup` / `Debris`) khi kết thúc, đổi Slot, biến hình, hoặc chết.

### Rule 5 — Tự Kiểm Tra Chéo 4 Tình Huống Biên (4-Point Edge-Case Checklist) Trước Khi Hoàn Tất
Mọi bản sửa lỗi phải tự kiểm chứng qua 4 câu hỏi:
1. **Khác Slot**: Đang cầm Slot 1/3/4 (Võ/Kiếm/Súng) bấm phím có bị lẫn hiệu ứng của Slot 2 (Trái Ác Quỷ) không?
2. **Khác Dạng Biến Hình**: Đang ở dạng Người thường vs. dạng Biến Hình (`SolarTitan`, `DragonFormTier 1 & 2`, `RaceV4`) có bị lỗi tỷ lệ (`Scale`), mất bộ phận, hay sai kỹ năng không?
3. **Chưa đủ điều kiện**: Khi chưa mở khóa `Mastery` hoặc đang `Cooldown` thì Client có bị chạy nhầm hiệu ứng di chuyển/bay không?
4. **Spam / Ngắt quãng**: Khi bấm phím liên tục hoặc đổi vũ khí/chết giữa chừng có bị kẹt `Anchored`, kẹt `PlatformStand`, hay sót rác VFX trên mặt đất (như vòng đỏ của Boss sau khi chết) không?

### Rule 6 — Kỷ Luật Đồng Bộ & Kiểm Định Tự Động Bắt Buộc
Trước khi báo cáo hoàn thành bất kỳ thay đổi code nào, **BẮT BUỘC** chạy:
1. `05_Pipeline_Tools_27x_9x/sync_solid3d_and_scripts_to_rbxlx.py`
2. `05_Pipeline_Tools_27x_9x/verify_27x_9x_game_sync.py`
3. `05_Pipeline_Tools_27x_9x/lint_luau_globals.py`
Và xác nhận đạt `[PASS]` ở cả bước 2 và 3. `[PASS]` chỉ xác nhận đóng gói và code tĩnh; thay đổi gameplay chỉ được báo hoàn tất sau khi test trong Studio.

### Rule 7 — Gỡ tính năng phải gỡ từ gốc
Khi gỡ một tính năng hoặc vật thể, xóa nơi tạo ra nó. Không dùng vòng lặp chạy nền để liên tục dọn hoặc ẩn đồ vừa sinh ra.

### Rule 8 — Ánh sáng chỉ có một nơi quyết định
Độ sáng, phơi sáng, bloom và màu do `stepAtmosphereAndWeather` trong `SkybreakWorldClient.client.lua` quyết định. Không đặt các giá trị này ở script khác.
