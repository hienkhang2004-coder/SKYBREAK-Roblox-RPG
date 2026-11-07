# SKYBREAK — Kế hoạch hoàn thiện để publish (bản thẩm định)

> Người lập: Claude, theo yêu cầu của Khang, ngày 07/11/2026.
> Người thực hiện: AI agent (Antigravity, Codex, Claude…) cùng 3 thành viên nhóm.
> Cơ sở: đọc toàn bộ 129 file Luau trong 3 thư mục Hạng Mục, log Roblox Studio ngày 05–06/11, chạy thử trong Studio ngày 06/11.
> Code đối chiếu: HEAD `91f3c1b` cộng 37 file Claude sửa (chưa commit) mà Claude đã ghi vào máy Khang đến 06/11.

---

## 0. Đọc trước khi làm (bắt buộc với AI thực hiện)

1. Đọc `AGENTS.md` (Rule 1–8) và `CLAUDE.md` ở thư mục gốc repo. Nếu mâu thuẫn, ưu tiên: code thật > `CLAUDE.md` > `AGENTS.md` > tài liệu khác.
2. **Chỉ sửa trong 3 thư mục Hạng Mục** `04_Roblox/0x_HangMuc*/`. Không sửa `04_Roblox/src/`, `SKYBREAK_Visual_v2/src/`, `06_Antigravity_Work/luau_v8/` hay trực tiếp trong Studio: sync sẽ ghi đè.
3. Mỗi file `.lua` phải **< 199,000 bytes**. `Config.lua`, `ClientBootstrap`, `Skybreak3DEquipment`, `GameService`, `DelegatedV5.client` đã sát giới hạn: code mới thì tách `ModuleScript` mới.
4. **Không publish, không chạy `deploy_skybreak_to_roblox_cloud.py`**, không commit/push nếu Khang chưa yêu cầu rõ.
5. Không chạy `rework_skybreak_from_scratch.py`, `export_all_15_worlds_v8.py`. Không xuất thế giới từ `Worlds_27x_9x_Final_Preview`.
6. Sau mỗi task:
   - Chạy `python 05_Pipeline_Tools_27x_9x/lint_luau_globals.py`, kết quả phải `[PASS]`.
   - Ghi kết quả vào mục 9 (Nhật ký) theo mẫu ở đó.
   - Ghi rõ "đã test trong Studio" hay "chưa test". `[PASS]` của lint hay verify **không** có nghĩa là gameplay đúng.
7. Các quyết định đã chốt ở mục 3. Làm theo đó, không hỏi lại. Chỉ dừng và báo khi bằng chứng trong code mâu thuẫn với quyết định.
8. Số dòng trong plan có thể lệch do đã sửa. Luôn tìm theo **chuỗi neo** (anchor) ghi kèm, đừng tin số dòng.

---

## 1. Kết luận thẩm định

**Game chưa publish được.** Phần kỹ thuật lõi (combat, render mesh runtime, lưu dữ liệu có khóa phiên) đã có nền. Nhưng còn 4 nhóm rủi ro chặn phát hành công khai:

| # | Rủi ro chặn publish | Mức | Hệ quả nếu publish ngay |
| :-- | :--- | :--- | :--- |
| 1 | **Bản quyền.** Tên và cơ chế lấy gần như nguyên từ Blox Fruits và One Piece (Haki 512 dòng code, Race V4 276, Leviathan 324, Mirage 188, CDK, Soul Guitar, Kabucha, Buddha, Geppo, Soru, Busoshoku, Kenbunshoku, Devil Fruit…) | Rất cao | Nhận DMCA, game bị gỡ, tài khoản bị cảnh cáo |
| 2 | **Lỗ hổng kinh tế qua remote.** Mua 20 vật liệu với giá của 1; mua bất kỳ vật phẩm nào bằng remote mà không cần đứng gần NPC; giftcode tặng trái Mythic | Rất cao | Kinh tế sụp ngay tuần đầu, không sửa lại được |
| 3 | **Dữ liệu người chơi.** DataStore đang tên `SKYBREAK_P0_TEST_v1`; chưa có quy trình xóa dữ liệu theo yêu cầu Roblox; chế độ dự phòng chỉ so Level và Gold nên có thể ghi đè kho đồ | Cao | Mất hoặc lẫn dữ liệu, không di trú được về sau |
| 4 | **Chưa có bản build đã kiểm chứng.** Các bản sửa skill, camera, rồng v2, tỉ lệ vũ khí đều chưa test trọn vẹn trong Studio; chưa test trên điện thoại; chưa test bản published với nhiều người | Cao | Lỗi hàng loạt lúc ra mắt, đánh giá xấu |

Ngoài ra còn các việc không chặn publish nhưng quyết định game có sống được không: không có hệ thống kiếm tiền, không có analytics, gần như không hỗ trợ cảm ứng, UI trộn Việt và Anh, kiến trúc có một module `Config.lua` ở ReplicatedStorage tự ghi đè logic combat của server.

---

## 2. Bảng điểm thẩm định

Điểm 1–5 (5 là sẵn sàng phát hành).

| Mảng | Điểm | Nhận xét ngắn |
| :--- | :-: | :--- |
| Combat và gameplay lõi | 3 | Đủ skill, boss, trái, võ, kiếm, súng; skill từng crash VFX (đã sửa, chưa test hết) |
| Đồ họa 3D và VFX | 3 | Pipeline mesh runtime chạy được; nhiều asset còn thô; 3 asset không tải được |
| Camera, điều khiển | 2 | Góc nhìn thứ nhất vừa sửa, chưa test; gần như chưa có điều khiển cảm ứng |
| Bảo mật server, chống gian lận | 2 | Không giới hạn tần suất remote; vendor tin dữ liệu client; một remote có 5 bộ xử lý |
| Kinh tế, cân bằng | 2 | Lỗ hổng mua hàng; năng lượng vô hạn và mastery bị tắt; giftcode quá tay |
| Lưu dữ liệu | 3 | Có khóa phiên, retry, BindToClose; còn tên store test và chưa có versioning hay xóa dữ liệu |
| Hiệu năng | 2 | Place khoảng 318 MB; dựng mesh từ chuỗi Base64 lúc chạy; chưa đo trên máy yếu |
| Nội dung, onboarding | 3 | 13 world, quest, NPC; chưa có hướng dẫn người mới rõ ràng |
| Ngôn ngữ | 2 | Khoảng 950 chuỗi UI tiếng Việt và 730 chuỗi tiếng Anh trộn lẫn; không dùng LocalizationService |
| Pháp lý, chính sách Roblox | 1 | IP phái sinh nặng; chưa làm bảng câu hỏi Maturity & Compliance |
| Kiếm tiền | 0 | Không có `MarketplaceService` nào |
| Analytics, vận hành | 0 | Không có `AnalyticsService`, không có telemetry lỗi |
| Quy trình nhóm | 2 | 37 file chưa commit; tài liệu cũ mâu thuẫn; test tự động đọc thư mục build |

---

## 3. Các quyết định đã chốt

Người thẩm định đã chốt 10 quyết định dưới đây. Agent làm theo, **không** hỏi lại. Muốn đổi thì Khang sửa trực tiếp bảng này, rồi ghi vào nhật ký mục 9.

| Mã | Chủ đề | Quyết định |
| :-- | :--- | :--- |
| D1 | Đổi tên IP | Đổi **mọi thứ người chơi thấy**: UI, tên vật phẩm, NPC, đảo, skill, thông báo, mô tả. ID nội bộ được giữ ở giai đoạn này, nhưng phải liệt kê trong `00_Documents/IP_RENAME_MAP.md`. Dùng đúng bảng tên ở mục 3.1, không tự đặt tên khác |
| D2 | Kiếm tiền | Chỉ bán tiện ích và trang trí, không bán sức mạnh trực tiếp. Không bán Lõi (trái) Mythic; không quay gacha bằng Robux. Danh mục ở mục 3.2 |
| D3 | DataStore | `C.StoreName = "SKYBREAK_LIVE_v1"`. Không chuyển dữ liệu từ store test. `StudioPersistence` giữ `false` |
| D4 | Năng lượng, mastery | Bật lại khóa mastery theo `CombatData.MasteryConfig`. Bỏ đoạn đặt chi phí skill bằng 0 và bỏ hồi năng lượng về 100 mỗi đòn: dùng lại chi phí gốc trong config. Năng lượng tối đa 100, hồi 8/giây khi không ra chiêu trong 1.5 giây, giữ +6 mỗi đòn trúng. Giữ hệ số giảm chỉ số 0.45 hiện tại |
| D5 | Nền tảng | PC và điện thoại lúc ra mắt. Tay cầm console làm sau, không chặn publish |
| D6 | Ngôn ngữ | Tiếng Việt và tiếng Anh. Mặc định theo `LocalizationService.RobloxLocaleId` (bắt đầu bằng `vi` thì tiếng Việt, còn lại tiếng Anh), đổi được trong Settings |
| D7 | Giftcode lúc ra mắt | Giữ `SKYBREAK2026` (25,000 Gold, 15 phút x2 EXP) và `AETHERV2` (150 Core Shards), hạn dùng 30 ngày kể từ ngày publish. Xóa `MYTHICFRUIT` và mã tặng `SolarTitanCore`. Thêm `SKYBREAKLAUNCH`: 10,000 Gold, 30 phút x2 EXP, hạn 14 ngày |
| D8 | Mức độ tuổi | Bạo lực fantasy nhẹ, không máu, không nội dung nhạy cảm. Bảng câu hỏi trả lời đúng theo nội dung game |
| D9 | Đồ mở sẵn | Mặc định chỉ có thuyền `SkySloop` và màu Haki (Aether Will) cơ bản. `CelestialAetherGalleon` bán ở Shipwright. Màu `crimson_conqueror` thưởng khi hạ boss world 3 lần đầu. Bỏ 2 dòng ép mở trong `hydrate` |
| D10 | Người mỗi server | `MaxPlayers = 16`. Hạ xuống 12 nếu bài test P1-09 cho thấy server tốn quá 12 ms mỗi Heartbeat ở mức 16 người |

Có 4 việc chỉ chủ tài khoản Roblox làm được, agent chỉ chuẩn bị nội dung rồi giao cho Khang bấm:
- Nộp bảng câu hỏi Maturity & Compliance.
- Tạo Game Pass, Developer Product và nhập giá.
- Bật API Services cho place test.
- Bấm Publish.

### 3.1 Bảng đổi tên (D1)

| Tên cũ (phái sinh) | Tên mới tiếng Việt | Tên mới tiếng Anh |
| :--- | :--- | :--- |
| Haki | Ý Chí Aether | Aether Will |
| Busoshoku / Armament Haki | Giáp Ý Chí | Will Armor |
| Kenbunshoku / Observation Haki / Ken | Thấu Ý | Will Sense |
| Conqueror's Haki | Bá Ý | Sovereign Will |
| Geppo | Bộ Không | Sky Step |
| Soru | Thuấn Bộ | Blink Dash |
| Devil Fruit / Trái Ác Quỷ | Lõi Aether | Aether Core |
| Awakened fruit / Thức tỉnh trái | Lõi Thức Tỉnh | Awakened Core |
| Race V4 | Thăng Hoa | Ascension |
| Leviathan | Thủy Xà Vực Thẳm | Abyss Serpent |
| Sea Beast | Thú Trời | Sky Beast |
| Mirage Island | Đảo Hư Quang | Phantom Isle |
| Temple of Time / Temple of the Core Race V4 | Đền Thăng Hoa | Ascension Shrine |
| Castle on the Sea / Castle on the Void | Pháo Đài Hư Không | Void Bastion |
| Cafe / Cyberport Cafe | Trạm Giao Thương | Trade Station |
| Cursed Dual Katana / CDK / Cursed Dual Skyblades | Song Kiếm Nguyệt Thực | Eclipse Twinblades |
| Soul Guitar | Đàn Hồn Hư Không | Void Lyre |
| Kabucha | Ná Gió Mặt Trời | Sunwind Sling |
| Buddha (trái) | Lõi Kim Thân | Colossus Core |
| Portal (trái) | Lõi Khe Nứt | Rift Core |
| Sea 1 / 2 / 3 | Tầng Trời 1 / 2 / 3 | Sky 1 / 2 / 3 |

Gặp tên phái sinh không có trong bảng: đặt tên mới theo cùng phong cách (Aether, Sky, Void, Core), rồi thêm dòng vào bảng này và vào `IP_RENAME_MAP.md`.

### 3.2 Danh mục kiếm tiền (D2)

| Loại | Tên | Nội dung | Giá đề xuất (Robux) |
| :--- | :--- | :--- | ---: |
| Game Pass | x2 EXP | Gấp đôi EXP vĩnh viễn | 299 |
| Game Pass | x2 Gold | Gấp đôi Gold rơi từ quái và quest | 249 |
| Game Pass | Kho Lõi mở rộng | +3 ô chứa Lõi Aether | 199 |
| Game Pass | Thuyền Hoàng Kim | Thuyền trang trí, tốc độ như thuyền thường | 349 |
| Game Pass | Hào quang tên | Hiệu ứng tên và khung chat | 99 |
| Developer Product | Túi Gold S / M / L | 5,000 / 20,000 / 60,000 Gold | 49 / 149 / 399 |
| Developer Product | Tẩy điểm chỉ số | Hoàn toàn bộ điểm chỉ số | 79 |
| Developer Product | x2 EXP 30 phút | Cộng dồn với Game Pass | 39 |

## 4. Giai đoạn P0 — chặn publish (bắt buộc)

### P0-01 Đồng bộ và chốt bản code đang chạy
- **Vì sao:** Nhiều bản sửa của Claude ngày 05–06/11 nằm trong thư mục Hạng Mục nhưng có thể chưa vào `.rbxlx`. Bản sửa tỉ lệ vũ khí được ghi sau lần sync cuối (00:50 ngày 06/11).
- **Làm:**
  1. Đóng Studio.
  2. Chạy `04_Roblox\DONG_BO_CODE_VAO_GAME.bat`.
  3. Chạy `verify_27x_9x_game_sync.py`, `lint_luau_globals.py`, `skybreak_contract_simulator_v3.py`. Simulator không có dòng `[PASS]`: phải tự đọc output tìm `[UNRESOLVED VISUAL ASSET]`, `[GUN MISSING STATS]`, `[HAZARD`.
  4. Mở lại `.rbxlx` rồi Play.
- **Xong khi:** verify và lint đều `[PASS]`; simulator không còn `UNRESOLVED`; vào Play không có lỗi đỏ trong Output trong 3 phút đầu.
- **Phụ trách:** Khang.

### P0-02 Đổi tên IP phái sinh (theo D1)
- **Bằng chứng:** chạy lệnh dưới để đếm (số dòng ngày 07/11: Haki 512, Leviathan 324, Race V4 276, Mirage 188, Busoshoku 112, Buddha 59, Kabucha 49, Kenbunshoku 43, Geppo 42, Devil Fruit 34, Soul Guitar 30, CDK 25, Soru 11).
  ```bash
  grep -rniE "haki|busoshoku|kenbun|conqueror|geppo|soru|devil ?fruit|race ?v4|cursed dual|\bcdk\b|soul ?guitar|kabucha|buddha|leviathan|mirage|sea beast" 04_Roblox/0* --include=*.lua | wc -l
  ```
- **Làm:**
  1. Lập `00_Documents/IP_RENAME_MAP.md`: cột tên cũ, tên mới, ID nội bộ. Dùng đúng bảng tên ở mục 3.1.
  2. Thay **mọi chuỗi hiển thị**: UI, `Name`, `NameVi`, `Desc`, thông báo `G.Notify`, `BillboardGui`, tên NPC, tên đảo, mô tả skill.
  3. Đổi tên thế giới và NPC phái sinh, ví dụ `TempleOfTheCoreRaceV4`, `MirageSkyIslandLeviathanAbyss`, `CastleOnTheVoidMansion`, `CyberportCafeTradingHub`, `ZiolesGachaShrine`. Phải sửa cả `VisualAsset` và `DelegatedV5Sources`. Đổi tên asset 3D là việc lớn: làm theo `VirtualSplitSpecs` hoặc ALIAS trong `DelegatedV5Renderer.lua`, không đổi tên thư mục `runtime_v8` khi chưa có kế hoạch riêng.
  4. Rà luôn icon, hình ảnh, âm thanh mô phỏng Blox Fruits hay One Piece.
  5. Đổi cả thiết kế quá giống bản gốc: bảng trái ác quỷ, Race V4 kích hoạt bằng phím, Soul Guitar…
- **Xong khi:** lệnh grep trên chỉ còn trả về ID nội bộ đã liệt kê trong bảng ánh xạ, không còn chuỗi hiển thị nào.
- **Phụ trách:** cả 3 Hạng Mục.

### P0-03 Vá lỗ hổng mua hàng của vendor
- **File:** `01_HangMuc1_Server_Combat_World/ServerScriptService/Services/SkybreakVendorAndArsenalService.lua`, hàm `handleBuyVendorItem` (neo: `local function handleBuyVendorItem`).
- **Lỗi 1, mua 20 với giá 1:** trừ `costGold` và `costShards` một lần, rồi mới tính `qty = math.clamp(... payload.quantity or payload.count ..., 1, 20)` cho vật liệu. Neo: `local qty = math.clamp(math.floor(tonumber(payload.quantity`.
- **Lỗi 2, mua được mọi thứ từ xa:** client gửi `itemId` bất kỳ. Server tìm trong `ArsenalExpansionConfig.Items` hoặc `RarityConfig.Items` và định giá dự phòng `tier * 15000` (neo: `return tier * 15000`). Không kiểm tra món đó có trong catalog của vendor nào, cũng không kiểm tra người chơi đứng gần NPC. Hệ quả: đồ chỉ rơi từ boss hoặc chỉ forge được cũng mua được bằng Gold.
- **Lỗi 3, giá 0:** vật phẩm `Rarity` tier 1 không có trong catalog trả giá `0, 0`.
- **Làm:**
  1. Tính `qty` trước, rồi `totalGold = costGold * qty` và `totalShards = costShards * qty`; kiểm tra đủ tiền, sau đó mới trừ.
  2. Chỉ cho mua nếu `itemId` có trong `ArsenalExpansionConfig.VendorCatalogs` (5 danh sách `SwordDealer`, `GunDealer`, `ArmorAndRelicVendor`, `ShipwrightFleet`, `MartialDojoStyles`). Bỏ nhánh định giá dự phòng theo tier khi bán.
  3. Kiểm tra khoảng cách: người chơi trong vòng 20 stud quanh NPC bán catalog đó (ProximityPrompt dùng 14 stud).
  4. Thêm giới hạn tần suất (xem P0-05).
- **Xong khi:** đã viết test (mở rộng `tests/test_logic.py` hoặc harness mới) với 4 ca: mua 20 vật liệu bị trừ 20 lần giá; mua món ngoài catalog bị từ chối; mua khi ở xa bị từ chối; mua khi thiếu tiền bị từ chối.

### P0-04 Khóa chế độ Dev Sandbox
- **Bằng chứng:** mọi lệnh cheat (Unlock All lên Lv.2550, 12 trái thức tỉnh, Zero Cooldown, triệu hồi boss, dịch chuyển, `BoostLevel`, mở world) chỉ chặn bằng `RunService:IsStudio() or workspace:GetAttribute("EnableDevSandbox") == true`. Neo: `SocialEconomy.HandleDevSandbox`, `act=="BoostLevel"`, `TravelService.lua` dòng có `EnableDevSandbox`, `GameService.lua` 3 chỗ mở world.
- **Rủi ro:** nếu thuộc tính `EnableDevSandbox` của Workspace đang bật trong file place, bản published sẽ cho mọi người dùng cheat. Không script nào bật nó, nên chỉ có thể bật tay trong place.
- **Làm:**
  1. Trong Studio, chạy ở Command Bar: `print(workspace:GetAttribute("EnableDevSandbox"))`. Kết quả phải là `nil` hoặc `false`.
  2. Thêm một hàm duy nhất `DevGate.IsAllowed(player)` (module server mới). Hàm trả `true` khi đang ở Studio, hoặc khi `game.PlaceId` thuộc danh sách place test **và** `player.UserId` thuộc danh sách dev. Thay cả 7 chỗ kiểm tra bằng hàm này.
  3. Không đưa danh sách UserId dev lên ReplicatedStorage.
- **Xong khi:** grep `EnableDevSandbox` chỉ còn trong `DevGate`; trên place published, tài khoản không phải dev gửi `DevSandbox` bị từ chối.

### P0-05 Giới hạn tần suất và hợp nhất remote
- **Bằng chứng:**
  - `GameService.lua` (neo: `R.CombatRequest.OnServerEvent:Connect`) xử lý `CombatRequest`, `AbilityRequest`, `InteractRequest`, `EquipmentRequest`, `AppearanceRequest` không có giới hạn tần suất. Combat có cooldown theo action, nhưng `EquipmentRequest` và `InteractRequest` thì không.
  - `UIRequest` có tới 5 bộ lắng nghe: `UIRequestHandler.server.lua`, `SkybreakVendorAndArsenalService.lua`, `SkybreakWorldEventsService.lua`, `SkybreakSocialEconomyService.lua`, `SkybreakCombatExpansion.lua`. Code còn có bản vá chống "Settings.lua bắn cả UIRequest lẫn EquipmentRequest" (neo: `Deduplicate dual-remote clicks`). Một hành động có thể bị xử lý hai lần.
  - `SKYBREAK_BuildNative` (RemoteFunction trong `NativeGeometry.server.lua`) cho client yêu cầu server dựng mesh: có giới hạn 2 yêu cầu đồng thời, nhưng không giới hạn tổng số, nên một client có thể bắt server dựng mọi asset.
- **Làm:**
  1. Tạo module `RemoteGuard` dùng token bucket theo người chơi và theo kênh (ví dụ Combat 20/s, UI 8/s, Equipment 6/s, Native 1/s, tối đa 40 lần cả phiên). Bọc mọi `OnServerEvent` và `OnServerInvoke`. `SkybreakCombatExpansion` đã có `consumeToken`, nên tái sử dụng nó.
  2. `UIRequest` chỉ để **một** bộ lắng nghe làm router theo `cmd`; các service đăng ký handler vào router. Xóa các listener trùng.
  3. Sửa client để mỗi nút chỉ bắn một remote.
  4. Kiểm tra kiểu và giới hạn mọi trường của payload (`tostring`, độ dài chuỗi ≤ 64, số trong khoảng hợp lệ).
- **Xong khi:** script spam 500 request/giây từ client (chạy trong Studio) không làm thay đổi Gold hay kho đồ, và server không giật.

### P0-06 Dữ liệu người chơi sẵn sàng cho bản live (theo D3)
- **File:** `03_HangMuc3_3D_VuKhi_Giap_VFX/ReplicatedStorage/Shared/Config.lua` dòng 5–6 (`C.StudioPersistence`, `C.StoreName = "SKYBREAK_P0_TEST_v1"`), `01_HangMuc1_Server_Combat_World/ServerScriptService/Services/PlayerDataService.lua`.
- **Làm:**
  1. Đổi `StoreName` sang tên đã chốt. Để `StudioPersistence = false`.
  2. Chế độ bảo vệ khi tải lỗi (`ReadOnlyFallback`, neo: `blockedClobber`) chỉ so `Level` và `Gold`. Đổi thành: **không bao giờ ghi** lên bản cloud khi phiên đang ở chế độ fallback. Báo cho người chơi và thử tải lại mỗi 30 giây.
  3. Kiểm tra kích thước profile trước khi lưu: `#HttpService:JSONEncode(profile)` phải dưới khoảng 3.5 MB (giới hạn 4 MB). Cảnh báo khi vượt 1 MB.
  4. Thêm `SchemaVersion` và hàm di trú theo phiên bản (hiện luôn là 1).
  5. Lưu ngay sau giao dịch quan trọng: trade, mua bằng Robux (P2), mở trái hiếm.
  6. Quy trình xóa dữ liệu theo yêu cầu Roblox (right to erasure): viết `00_Documents/DATA_ERASURE.md` nêu cách xóa khóa `u_<UserId>` khi nhận yêu cầu, cùng script Command Bar để làm việc đó.
- **Xong khi:** trên place test đã publish, bật API Services: vào, chơi, thoát rồi vào lại thì dữ liệu còn; hai server cùng lúc không làm mất dữ liệu; tắt mạng giả lập lúc tải thì profile cloud không bị ghi đè.

### P0-07 Giftcode và đồ tặng (theo D7, D9)
- **File:** `03_HangMuc3_3D_VuKhi_Giap_VFX/ReplicatedStorage/Shared/SkybreakCombatData.lua` (neo: `CombatData.Giftcodes = {`), `PlayerDataService.lua` (neo: `UnlockedHakiColors.crimson_conqueror = true`, `UnlockedShips.CelestialAetherGalleon = true`).
- **Vấn đề:**
  - `MYTHICFRUIT` tặng trái `AbyssalSovereignCore` (rồng). Một mã khác tặng `SolarTitanCore`.
  - Các mã không có ngày hết hạn.
  - Hàm `hydrate` mở sẵn thuyền cao cấp và màu Haki đặc biệt cho mọi người mỗi lần tải profile.
- **Làm:**
  - Thêm trường `Expires` (Unix time) và `MaxLevel` hoặc `MinLevel` cho từng mã.
  - Bỏ các mã tặng trái Mythic.
  - Chuyển mở khóa mặc định về `defaults()` chỉ cho đồ khởi đầu; không ép trong `hydrate`.

### P0-08 Asset không tải được và quyền sở hữu asset
- **Bằng chứng (log Studio 05–06/11):** `MeshContentProvider failed ... id=74564640282568`, `id=112107804308297`, `HSRDataContentProvider failed ... id=137354588220741`, đều báo `could not fetch`. Ba ID này không có trong code Luau, tức nằm trong file place.
- **Làm:**
  1. Tìm instance dùng 3 ID này bằng Command Bar: lặp `game:GetDescendants()`, so `MeshId` hay `TextureID` có chứa ID.
  2. Thay bằng asset thuộc tài khoản hoặc group sở hữu game, hoặc xóa.
  3. Liệt kê 78 `rbxassetid` trong code, kiểm tra từng cái thuộc chủ game và đã qua kiểm duyệt. Âm thanh phải là của mình hoặc từ thư viện được phép.
- **Xong khi:** Output không còn `could not fetch` khi vào game.

### P0-09 Giới hạn nền tảng của pipeline mesh runtime
- **Bối cảnh:** game dựng mesh lúc chạy từ `ReplicatedStorage.DelegatedV5Sources` (chuỗi Base64 Zstd), qua `EditableMesh` (10 chỗ) và `AssetService:CreateMeshPartAsync` (3 chỗ). Place khoảng 318 MB.
- **Phải xác minh (đọc tài liệu Roblox mới nhất, ghi nguồn vào nhật ký):**
  1. Điều kiện dùng `EditableMesh` và `EditableImage` trong game đã publish, như yêu cầu xác minh tài khoản chủ game, giới hạn bộ nhớ trên thiết bị yếu, hành vi khi vượt ngân sách.
  2. Giới hạn kích thước file place khi publish từ Studio. Open Cloud giới hạn 100 MB, nên đừng dùng script deploy.
  3. Thời gian tải lần đầu trên điện thoại tầm trung.
- **Làm nếu có vấn đề:** chuyển dần các mesh tĩnh (thế giới, NPC, vũ khí) sang MeshPart đã upload thật. Chỉ giữ dựng runtime cho thứ cần biến dạng. Đây là dự án riêng, phải lập kế hoạch trước khi làm.
- **Xong khi:** có bảng số đo: thời gian vào game, bộ nhớ client (Developer Console → Memory) trên PC và 1 điện thoại Android tầm trung.

### P0-10 Kiểm chứng các bản sửa gần nhất (chưa test)
Mỗi mục phải có ảnh hoặc clip làm bằng chứng và ghi vào nhật ký.

| Mã | Bản sửa | Cách test |
| :-- | :--- | :--- |
| V1 | Skill không xả (sai thứ tự tham số trong `DragonSovereignVFX`, `UniversalVFXOverhaul`) | Xả Z X C V F của mọi trái, võ, kiếm, súng; Output không có lỗi `VFXStudioLibrary` |
| V2 | `DelegatedV5` chết khi khởi động (`GuardianAnimator`, `RealmConfig`, `DelegatedV5Sources` chưa tải) | Vào game 5 lần liền, mỗi lần đều thấy nhân vật và vũ khí 3D |
| V3 | Góc nhìn thứ nhất khi zoom sát | Zoom hết vào, cả lúc bật và tắt khóa góc nhìn (LeftCtrl); không thấy bên trong thân; zoom ra thì thân hiện lại |
| V4 | Rồng `AbyssalSovereignDragon` và Bán Long Nhân `AbyssalDragonHybrid` v2 (màu, Neon, cánh chuyển màu theo đỉnh) | Biến hình V ở dạng 1 và 2; xem trước, sau, ngang; không còn mảng FX thừa dưới chân, không đâm xuyên mặt |
| V5 | VFX rồng mới (nứt lava, khói đen, vỗ cánh) | Xả từng skill rồng; FPS không tụt dưới 40 trên PC |
| V6 | Tỉ lệ và điểm cầm vũ khí (`WEAPON_HOLD_SPECS` trong `Skybreak3DEquipment.lua`) | Cầm mọi vũ khí trong bảng; súng không quay ngược, không lùi sau tay; vũ khí cán dài cầm ở khoảng 1/3 thân |
| V7 | Bỏ companion, jump pad; một nguồn duy nhất điều khiển ánh sáng | Không còn thẻ companion; ánh sáng không nhấp nháy khi đổi world |

### P0-11 Chính sách Roblox (theo D8)
- Hoàn thành bảng câu hỏi **Maturity & Compliance** trong Creator Hub.
- Kiểm tra mọi chỗ hiển thị chữ do người chơi nhập cho người khác thấy. Hiện có 3 `TextBox`: ô giftcode (`SocialRewards.lua`, `Settings.lua`) và ô tìm kiếm (`Inventory.lua`); đều không hiển thị cho người khác, nên ổn. Nếu thêm tên crew hay đổi tên thuyền thì **bắt buộc** lọc bằng `TextService:FilterStringAsync`.
- Hệ thống gacha (`ZiolesGachaShrine`): nếu sau này cho quay bằng Robux, phải hiện tỉ lệ rơi và tuân theo quy định về vật phẩm ngẫu nhiên trả phí. Gacha bằng tiền trong game cũng nên hiện tỉ lệ.
- Thêm trang **Điều khoản và Quyền riêng tư** ngắn trong Settings nếu dùng dữ liệu ngoài Roblox (hiện không có `HttpService` gọi ra ngoài, nên ổn).

---

## 5. Giai đoạn P1 — chất lượng ra mắt (nên xong trước khi mở công khai)

### P1-01 Logic combat của server nằm trong `Config.lua` ở ReplicatedStorage
- **Bằng chứng:** `03_HangMuc3_3D_VuKhi_Giap_VFX/ReplicatedStorage/Shared/Config.lua`:
  - Đoạn quanh `G.Action = function(p, action, payload)` ghi đè hàm `G.Action` của server, tự hồi `rt.Energy` và `rt.Stamina` về 100 mỗi đòn.
  - Đoạn quanh `sk.Cost = 0; sk.EnergyCost = 0` đặt chi phí mọi skill bằng 0.
  - Đoạn khác nhân ATK, DEF, HP với 0.45.
- **Hệ quả:**
  - Code combat của server bị gửi xuống mọi client, nên kẻ gian đọc được.
  - Hai nguồn sự thật cho cùng một luật.
  - File đã 186 KB, sát giới hạn.
- **Làm:** chuyển toàn bộ phần ghi đè server sang module mới trong `ServerScriptService` thuộc Hạng Mục 1. `Config.lua` chỉ giữ số liệu. Chốt D4 rồi mới quyết giữ hay bỏ năng lượng vô hạn.

### P1-02 Bật lại khóa mastery (theo D4)
- **File:** `SkybreakCombatExpansion.lua`, neo `local function checkMoveMasteryUnlock(_p, _profile, _itemId, _moveKey, _slot)`: luôn `return true, 1`.
- **Làm:** dùng `getMasteryLevel` và ngưỡng trong `CombatData.MasteryConfig`. UI phải hiện "Mở ở Mastery N" trên skill bị khóa (HUD đã có dòng `Mas. 1`).

### P1-03 Điều khiển trên điện thoại (theo D5)
- **Bằng chứng:** chỉ `Responsive.lua` kiểm tra `TouchEnabled`. `ContextActionService` chỉ gắn phím bàn phím (neo: `CAS:BindActionAtPriority("Skybreak"..name`). Không có nút cảm ứng cho M1, Z X C V F, né, bay, đổi slot 1–4.
- **Làm:**
  - Bộ nút cảm ứng: đánh thường, 5 skill, né, nhảy kép hoặc Sky Step, bay lên và xuống, đổi slot.
  - Hiện thời gian hồi trên nút.
  - Không che joystick mặc định.
  - Kiểm tra mọi màn hình UI ở độ phân giải 1334×750 và 2400×1080.
- **Xong khi:** chơi hết Q01 đến Q05 trên điện thoại thật không cần bàn phím.

### P1-04 Va chạm, quái lơ lửng, tường vô hình
- Đã ghi nhận từ đợt rà soát trước nhưng chưa test.
- **Làm:** đi hết 13 world bằng nhân vật thường. Ghi tọa độ chỗ kẹt, rơi xuyên đất, tường vô hình, quái lơ lửng hoặc chìm. Sửa collider ở nguồn Blender (`SKYBREAK_Argon_Refinement/Worlds_Gameplay3x_Clean3D`) hoặc trong code sinh collider. Không sửa tay trong Studio.
- Hàm `safeGroundY` trong `GameService.lua` (neo: `if math.abs(gy-pos.Y)>36 then`) trả về `pos.Y-2.5` khi mặt đất tìm được lệch quá 36 stud, tức là đoán độ cao chứ không bám đất thật. Đây là một nguồn khả dĩ của quái lơ lửng hoặc chìm. Nên ghi log tọa độ những lần rơi vào nhánh này để tìm chỗ collider thiếu.

### P1-05 Trade an toàn
- **File:** `SkybreakCombatExpansion.lua`, neo `executeAtomicTradeSwap`.
- **Làm:**
  - Sau khi đổi, gọi `D.Save` cho **cả hai** người ngay lập tức.
  - Khóa không cho trade khi một bên đang ở chế độ fallback (P0-06).
  - Ghi log trade (ai, đổi gì, lúc nào) vào DataStore riêng để tra cứu khiếu nại.
  - Kiểm tra lại số lượng ngay trước khi đổi, không chỉ lúc thêm vào bàn.

### P1-06 Hướng dẫn người mới
- **Làm:** 10 phút đầu có lộ trình rõ ràng: chọn ngoại hình, 3 đòn cơ bản, skill đầu tiên, quest đầu, mua món đầu, gặp boss nhỏ. Màn hình ban đầu đang có rất nhiều bảng (bảng xếp hạng, radar, nhật ký nhiệm vụ, hotbar 4 ô, 9 nút menu); nên ẩn bớt và mở dần theo tiến trình.
- **Đo:** tỉ lệ người chơi hoàn thành Q01 (cần P2-02).

### P1-07 Ngôn ngữ (theo D6)
- **Bằng chứng:** trong UI có khoảng 954 chuỗi tiếng Việt và 731 chuỗi kiểu tiếng Anh trộn lẫn; một số bảng đã có cặp `labelVi` và `labelEn` (`HUD.lua`).
- **Làm:** gom chuỗi về một bảng `Strings.lua` (vi và en), tra theo khóa; hoặc dùng LocalizationService và Localization Table của Roblox. Thêm lựa chọn ngôn ngữ trong Settings.

### P1-08 Hiệu năng client
- **Bằng chứng:** 24 `Heartbeat:Connect`, 27 `RenderStepped:Connect`, 28 `Stepped:Connect`, 97 lệnh `GetDescendants()` ở 29 file. Nhiều vòng lặp mỗi khung hình quét toàn bộ model (ví dụ ép `LocalTransparencyModifier` trong `Skybreak3DEquipment.lua`).
- **Làm:**
  1. Dùng MicroProfiler (Ctrl+F6) đo 60 giây ở hub, ở world đông quái và lúc đánh boss.
  2. Lập bảng 10 hàm tốn nhất.
  3. Thay quét `GetDescendants()` mỗi khung hình bằng danh sách cache hoặc sự kiện `DescendantAdded`.
  4. Có chế độ Low FX tự bật khi FPS dưới 30.
- **Mục tiêu:** PC tầm trung trên 60 FPS ở hub; điện thoại tầm trung trên 30 FPS.

### P1-09 Hiệu năng server và số người tối đa (theo D10)
- Vòng lặp chính đã có LOD (quái trong 220 stud tick đầy đủ, quái xa tick mỗi 0.4 giây) và `safeTick` chống crash.
- **Làm:** test với 8, 12 rồi 16 người (Studio → Test → Clients and Servers). Ghi `Heartbeat` time, bộ nhớ server, độ trễ remote. Chốt `MaxPlayers` theo kết quả.

### P1-10 Hoàn thiện đồ họa còn thô
- Liệt kê asset còn hình khối đơn giản hoặc màu chưa khớp phong cách. Ưu tiên thứ người chơi thấy nhiều: nhân vật, vũ khí khởi đầu, hub, 3 world đầu, boss đầu.
- Mọi sửa đổi 3D làm ở file `.blend` nguồn rồi xuất bằng `export_single_asset_v8.py`.
- **Lưu ý:** exporter chỉ đọc giá trị Principled phẳng, không nhận texture node. Vật liệu tên bắt đầu `MAT_ASD2_` hoặc `MAT_ADH2_` được renderer giữ đúng màu và bật Neon khi `emission_strength ≥ 1.5`. Thêm tiền tố mới phải sửa `DelegatedV5Renderer.lua` (neo: `isAuthoredDragon`).

### P1-11 Âm thanh
- Âm thanh chủ yếu đi qua `SkybreakAudioEngine.lua`.
- **Làm:** kiểm tra mỗi skill, đòn đánh, UI, nhạc nền đều có tiếng và ID thuộc chủ game; âm lượng cân bằng; có thanh trượt âm lượng nhạc và hiệu ứng riêng trong Settings.

---

## 6. Giai đoạn P2 — kinh doanh và vận hành (trước hoặc ngay sau soft launch)

### P2-01 Kiếm tiền (theo D2)
- Hiện không có `MarketplaceService`.
- **Làm:**
  - Module `MonetizationService` (server):
    - `ProcessReceipt` **idempotent**: lưu `PurchaseId` đã xử lý vào profile trước khi trả `PurchaseGranted`.
    - Chỉ trả `PurchaseGranted` sau khi lưu thành công.
    - Kiểm tra Game Pass bằng `UserOwnsGamePassAsync` có cache và `pcall`.
  - UI cửa hàng Robux tách riêng khỏi cửa hàng Gold.
  - Tránh pay-to-win nặng ở PvP.
- **Xong khi:** mua thử bằng tài khoản test trong Studio; tắt server giữa lúc mua; vào lại thì nhận đúng một lần.

### P2-02 Analytics
- Dùng `AnalyticsService` (Funnel, Economy, Custom events):
  - Funnel onboarding: vào game → chọn ngoại hình → M1 đầu → skill đầu → Q01 xong → Q05 xong.
  - Economy: mọi nguồn và nơi tiêu Gold, Shards.
  - Custom: chết, boss clear, thời gian mỗi world.
- **Mục tiêu theo dõi:** D1, D7 retention; thời gian chơi trung bình; tỉ lệ chuyển đổi mua.

### P2-03 Telemetry lỗi
- Bắt `ScriptContext.Error` ở client và server, gom theo chữ ký lỗi, gửi qua `AnalyticsService` custom event hoặc ghi MemoryStore.
- `safeTick` trong `GameService.lua` đang `warn` mỗi 10 giây; cũng đẩy về đây.
- Mục tiêu: biết lỗi phổ biến nhất trong 24 giờ đầu sau publish.

### P2-04 Quản trị và kiểm duyệt
- Lệnh admin server-side cho đúng UserId của nhóm: kick, ban (lưu DataStore), xem profile, hoàn đồ.
- Tích hợp API ban của Roblox nếu dùng được.
- Không đưa danh sách admin xuống client.

### P2-05 Sao lưu dữ liệu và rollback
- Trước mỗi bản cập nhật có thay đổi profile: tăng `SchemaVersion`, viết hàm di trú, test trên bản sao dữ liệu.
- Ghi rõ cách khôi phục profile một người từ phiên bản DataStore cũ (`ListVersionsAsync`, `GetVersionAsync`).

### P2-06 Kế hoạch ra mắt
1. Place test riêng (private), mời 10–20 người thử 1 tuần.
2. Soft launch: public nhưng không quảng cáo, 1–2 tuần, theo dõi analytics và lỗi.
3. Sửa theo số liệu, rồi mới chạy quảng cáo và sponsor.
- Chuẩn bị: icon game, 5 thumbnail hoặc video, mô tả tiếng Việt và tiếng Anh, thể loại, `MaxPlayers`, cài đặt Private Server, social link (Discord, group).

---

## 7. Giai đoạn P3 — quy trình nhóm và kỹ thuật dài hạn

| Mã | Việc | Chi tiết |
| :-- | :--- | :--- |
| P3-01 | Commit sạch | 37 file đang sửa chưa commit. Khang kiểm tra trong Studio rồi chia commit theo Hạng Mục (`fix(HangMuc1): ...`). Báo Quang Khai và Gia Bảo trước vì có sửa chéo Hạng Mục |
| P3-02 | CI tối thiểu | GitHub Actions chạy `lint_luau_globals.py` và kiểm tra giới hạn 199,000 B trên mỗi PR |
| P3-03 | Test tự động | `tests/test_logic.py` đọc `04_Roblox/src/` (bản build bị gitignore), nên chạy trên máy sạch sẽ lỗi. Đổi sang đọc thư mục Hạng Mục hoặc chạy sync trước. Thêm test cho P0-03, P0-05, P0-06 |
| P3-04 | Dọn tài liệu | `README.md`, `SKYBREAK_MASTER_PROJECT_HANDOVER.md`, `00_Documents/08_TEAM_GITHUB_WORKFLOW_3_MEMBERS.md`, skill `skybreak-rbxlx-build-and-qa` còn ghi "sửa tại `04_Roblox/src`" và còn nhắc 27×/9×. Sửa theo `CLAUDE.md`. Đánh dấu `00_START_HERE.md` và `CODEX_HANDOFF_REPORT.md` là lịch sử |
| P3-05 | Đổi tên pipeline | `05_Pipeline_Tools_27x_9x` và `verify_27x_9x_game_sync.py` mang tên bản đã bỏ. Đổi tên phải sửa `.bat`, `.ps1` và tài liệu cùng lúc |
| P3-06 | Lưu file lớn | `.rbxlx` (318 MB, 3 bản), `.blend` không lên Git. Chọn nơi lưu có lịch sử (Git LFS hoặc ổ chung có version) và ghi vào tài liệu |
| P3-07 | Tách file sát giới hạn | `Config.lua` 186 KB, `ClientBootstrap` 183 KB, `Skybreak3DEquipment` 180 KB, `GameService` 178 KB, `DelegatedV5.client` 175 KB. Tách theo chức năng trước khi thêm tính năng |

---

## 8. Ma trận test trước khi bấm publish

Mỗi ô phải được đánh dấu "Đạt" kèm ngày, người test, thiết bị.

| Hạng mục | PC (chuột, phím) | Android tầm trung | iPhone | 12 người cùng server |
| :--- | :-: | :-: | :-: | :-: |
| Vào game, tải nhân vật, không lỗi đỏ | | | | |
| Onboarding đến Q05 | | | | |
| Combat: M1, 5 skill mỗi loại vũ khí, trái, võ | | | | |
| Biến hình rồng, Bán Long Nhân | | | | |
| Bay, Sky Step, né | | | | |
| Camera: góc 3 và góc 1, khóa góc nhìn | | | | |
| Mua bán vendor, forge, trade | | | | |
| Đổi world, dịch chuyển đảo | | | | |
| Boss đầu tiên | | | | |
| Lưu dữ liệu: thoát, vào lại, đổi server | | | | |
| Mua Robux (khi có P2-01) | | | | |
| FPS và bộ nhớ đạt mục tiêu P1-08 | | | | |

---

## 9. Nhật ký thực hiện (agent ghi tiếp vào đây)

Mẫu mỗi dòng:

```text
[YYYY-MM-DD] <Mã task> | <người/agent> | Trạng thái: Xong / Đang làm / Chặn
  File đã sửa: ...
  Kiểm tra: lint PASS / verify PASS / đã test Studio (mô tả) / CHƯA test
  Ghi chú, việc còn lại: ...
```

| Ngày | Task | Ai | Trạng thái | Ghi chú |
| :--- | :--- | :--- | :--- | :--- |
| 2026-11-07 | Chốt D1–D10 | Claude | Xong | Theo yêu cầu của Khang; xem mục 3 |
| 2026-11-07 | Lập plan | Claude | Xong | Máy Khang không kết nối lúc lập plan; mục P0-04 bước 1, P0-08, P0-09 cần làm trên máy có Studio |
| 2026-11-07 | P0-01 | Antigravity | Đang làm | Đã chạy `sync_solid3d_and_scripts_to_rbxlx.py` (131 file `< 199,000` B), `verify` (`[PASS]`), `lint_luau_globals` (`[PASS]`), `skybreak_contract_simulator_v3` (0 `UNRESOLVED`, 0 `GUN MISSING`, 0 `HAZARD`). **Chưa test trong Studio** |
| 2026-11-07 | P0-02 (D1) | Antigravity (4 Subagents) | Đang làm | Đã lập `00_Documents/IP_RENAME_MAP.md` và đổi toàn bộ chuỗi hiển thị IP sang tên mới (Mục 3.1) trên cả 3 Hạng Mục (30 file sửa), giữ nguyên ID nội bộ. `lint` PASS, `verify` PASS. **Chưa test trong Studio** |
| 2026-11-07 | P0-03 | Antigravity (Subagent 1 & 2) | Đang làm | Vá `SkybreakVendorAndArsenalService.lua` (tính `qty` trước khi trừ `totalGold`/`totalShards`, kiểm tra `VendorCatalogs`, bỏ `tier * 15000`, kiểm tra khoảng cách ≤ 20 studs tới NPC) + chuẩn hóa `ArsenalExpansionConfig.lua` + 4 test trong `test_logic.py` PASS. **Chưa test trong Studio** |
| 2026-11-07 | P0-04 | Antigravity (Subagent 1 & 3) | Đang làm | Quét `.rbxlx` xác nhận `Workspace` không bật `EnableDevSandbox`; tạo `ServerScriptService/Services/DevGate.lua` và thay toàn bộ 10 chỗ gọi `EnableDevSandbox` (grep chỉ còn trong `DevGate.lua`). `lint` PASS, `test_logic.py` PASS. **Chưa test trong Studio** |
| 2026-11-07 | P0-05 | Antigravity (Subagent 1 & 2) | Đang làm | Tạo `ServerScriptService/Services/RemoteGuard.lua` (token bucket theo kênh + giới hạn 40 lần `Native` mỗi phiên), gộp 5 listener `UIRequest` về 1 router duy nhất `UIRequestHandler.server.lua`, sửa client `Settings.lua`/`SocialRewards.lua`/`NPCShop.lua`/`Skills.lua` chỉ bắn 1 remote. `lint` PASS, `test_logic.py` PASS. **Chưa test trong Studio** |
| 2026-11-07 | P0-06 (D3) | Antigravity (Subagent 1, 3, 4) | Đang làm | Đổi `C.StoreName = "SKYBREAK_LIVE_v1"`, `C.StudioPersistence = false`; chặn tuyệt đối ghi đè cloud khi `_ReadOnlyFallback == true` (thử tải lại mỗi 30s); kiểm tra JSON < 3.5 MB; thêm `CURRENT_SCHEMA_VERSION = 2` & `migrateProfile`; tạo `00_Documents/DATA_ERASURE.md`. `test_data.py` PASS. **Chưa test trong Studio** |
| 2026-11-07 | P0-07 (D7, D9) | Antigravity (Subagent 1, 2, 3) | Đang làm | Xóa `MYTHICFRUIT`; cập nhật `SKYBREAK2026`, `AETHERV2`, thêm `SKYBREAKLAUNCH` kèm `Expires` & `MinLevel`; bỏ mở khóa chùa `crimson_conqueror` & `CelestialAetherGalleon` trong `hydrate` (chỉ mở `SkySloop`; `crimson_conqueror` thưởng khi hạ Boss World 3 lần đầu; `CelestialAetherGalleon` bán ở Shipwright). `test_data.py` PASS. **Chưa test trong Studio** |
| 2026-11-07 | P0-08, P0-09 | Antigravity (Subagent 4) | Đang làm | Quét `.rbxlx` xác nhận 3 ID lỗi (`74564640282568`, `112107804308297`, `137354588220741`) không nằm trong place/code; lập `00_Documents/ASSET_AND_PLATFORM_AUDIT.md` kiểm kê 78 `rbxassetid://` và giới hạn `EditableMesh`. Cần kiểm tra quyền sở hữu âm thanh & đo bộ nhớ thực tế trong Studio/Mobile |
| 2026-11-07 | P1-01, P1-02 (D4) | Antigravity (Subagent 1, 2, 3) | Đang làm | Bỏ ép `sk.Cost = 0` và bỏ hồi 100 Energy mỗi đòn trong `Config.lua`; hồi 8 Energy/s sau 1.5s không ra chiêu, +6 mỗi đòn M1; bật lại khóa Mastery trong `SkybreakCombatExpansion.lua` và hiển thị `"Mở ở Mastery N"` trên HUD/Skills/Fruits. `lint` PASS. **Chưa test trong Studio** |
| 2026-11-07 | P1-05 | Antigravity (Subagent 1) | Đang làm | Khóa `executeAtomicTradeSwap` khi một bên ở `_ReadOnlyFallback`, kiểm tra lại số lượng ngay trước khi đổi và gọi `D.Save` tức thì cho cả 2 người chơi. `lint` PASS. **Chưa test trong Studio** |
| 2026-11-07 | P3-02, P3-03, P3-04 | Antigravity (Subagent 4) | Xong | Tạo `.github/workflows/ci.yml`; nâng cấp `04_Roblox/tests/test_logic.py` (11 PASS) & `test_data.py` (7 PASS) đọc trực tiếp từ 3 thư mục Hạng Mục; cập nhật `README.md`, `SKYBREAK_MASTER_PROJECT_HANDOVER.md`, `08_TEAM_GITHUB_WORKFLOW_3_MEMBERS.md`, `SKILL.md` và gắn nhãn lịch sử cho `00_START_HERE.md` & `CODEX_HANDOFF_REPORT.md` |

---

## 10. Phụ lục — lệnh hay dùng

```powershell
# Từ thư mục gốc repo
$py = "C:\Program Files\Blender Foundation\Blender 5.2\5.2\python\bin\python.exe"
& $py 05_Pipeline_Tools_27x_9x/sync_solid3d_and_scripts_to_rbxlx.py
& $py 05_Pipeline_Tools_27x_9x/verify_27x_9x_game_sync.py
& $py 05_Pipeline_Tools_27x_9x/lint_luau_globals.py
& $py 05_Pipeline_Tools_27x_9x/skybreak_contract_simulator_v3.py
```

```lua
-- Studio Command Bar
print(workspace:GetAttribute("EnableDevSandbox"))                  -- P0-04: phải nil/false
print(require(game.ReplicatedStorage.Shared.SkybreakSmokeTest).RunAll().Summary)
for _, d in ipairs(game:GetDescendants()) do                         -- P0-08
	local ok, id = pcall(function() return d.MeshId or d.TextureID end)
	if ok and id and (id:find("74564640282568") or id:find("112107804308297") or id:find("137354588220741")) then
		print(d:GetFullName(), id)
	end
end
```

- Log Studio (lỗi thật kèm stack): `C:\Users\khang\AppData\Local\Roblox\logs\`, file `*_Studio_*_last.log` mới nhất. Tìm `FLog::CreatorError`, `[SKYBREAK`.
- Bảo vệ trước khi thử cheat hay spam: chỉ làm trên place test, không làm trên place chính.
