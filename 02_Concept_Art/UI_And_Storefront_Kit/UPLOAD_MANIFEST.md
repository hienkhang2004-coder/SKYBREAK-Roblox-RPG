# SKYBREAK: Fragments of the Core — Hướng Dẫn Upload Bộ UI PNG & Ảnh Quảng Bá Storefront (`UPLOAD_MANIFEST.md`)

Tài liệu này hướng dẫn chi tiết quy trình tải bộ **76 file PNG chuẩn phát hành** (`5` ảnh Storefront + `71` tài nguyên UI RGBA trong suốt) lên **Roblox Creator Hub / Roblox Studio Asset Manager** và điền mã `rbxassetid://<ID>` vào đúng khóa trong `ReplicatedStorage/SkybreakShared/Config/UIAssets.lua`.

---

## 1. Cấu Trúc Thư Mục Bộ Kit (`UI_And_Storefront_Kit/`)

- `Storefront/` (**5 file PNG**):
  - `GameIcon_512x512.png` (`512x512` RGB) — Biểu tượng chính thức của game trên trang Home / Discover.
  - `Thumbnail_01_SkyClash_1920x1080.png` (`1920x1080` RGB) — Thumbnail 1: Đại chiến kiếm khí Ánh Dương & Sấm Sét 3D.
  - `Thumbnail_02_AbyssalDragon_1920x1080.png` (`1920x1080` RGB) — Thumbnail 2: Hóa Rồng Vực Thẳm (`Abyssal Sovereign`) & Thức Tỉnh Thiên Giới.
  - `Thumbnail_03_FloatingRealms_1920x1080.png` (`1920x1080` RGB) — Thumbnail 3: Khinh hạm `Celestial Aether Galleon` du hành giữa Đảo Trời Vàng & Trạm Giao Thương Băng Giá.
  - `Thumbnail_04_ArsenalAndCores_1920x1080.png` (`1920x1080` RGB) — Thumbnail 4: Bộ sưu tập 12 Trái Lõi Aether (`Aether Cores`), 6 Thần Binh (`Mythic Weapons`) & Đấu Trường Đột Kích Thức Tỉnh.
- `UI_Icons/` (**71 file PNG**):
  - Đầy đủ Logo kim loại 3D (`ui_logo.png`), khung 9-Slice (`ui_panel_9slice.png`, `ui_button_9slice.png` kèm bản `64x64`), hiệu ứng sáng mềm (`ui_soft_glow.png`), nền Bản Đồ Thế Giới không dính chữ (`ui_worldmap_bg.png`), nền Menu Chính (`ui_mainmenu_bg.png`), 5 khung phẩm chất (`RarityBorders`), 47 Icon kỹ năng/vũ khí/tiền tệ/GamePass, 3 Chân dung Hệ phái (`ClassPortraits`) và 8 Chân dung Trùm (`BossPortraits`).

---

## 2. Hướng Dẫn Upload Ảnh Quảng Bá Lên Roblox Creator Hub (`Storefront/`)

### Bước 2.1 — Upload Biểu Tượng Game (`GameIcon_512x512.png`)
1. Truy cập **Roblox Creator Hub** (`create.roblox.com`) -> **Creations** -> Chọn Experience **SKYBREAK: Fragments of the Core**.
2. Ở thanh điều hướng bên trái, vào **Configure** -> **Places** -> Chọn **Start Place** -> Tab **Icon**.
3. Chọn **Change** -> Tải lên file `Storefront/GameIcon_512x512.png` (`512x512` px) -> Nhấn **Save Changes**.
   - *Lưu ý thiết kế*: Chữ kim loại vàng `"SKYBREAK"` và khối tương phản Lõi Aether + Song Kiếm đã được kiểm định độ nét ở kích thước thu nhỏ `150x150` trên trang Roblox Discover/Home.

### Bước 2.2 — Upload 4 Ảnh Thumbnail Quảng Bá (`1920x1080`)
1. Tại **Creator Hub** -> **Creations** -> Chọn Experience **SKYBREAK** -> Vào mục **Configure -> Promotional Media** (hoặc **Places -> Start Place -> Thumbnails**).
2. Nhấn **Add Media / Upload Image** và tải lần lượt theo đúng thứ tự ưu tiên hiển thị:
   1. `Storefront/Thumbnail_01_SkyClash_1920x1080.png` *(Đặt làm Thumbnail đầu tiên — tỷ lệ CTR cao nhất)*
   2. `Storefront/Thumbnail_02_AbyssalDragon_1920x1080.png`
   3. `Storefront/Thumbnail_03_FloatingRealms_1920x1080.png`
   4. `Storefront/Thumbnail_04_ArsenalAndCores_1920x1080.png`
3. Kéo thả sắp xếp thứ tự `01 -> 02 -> 03 -> 04` và nhấn **Save Changes**.

| STT | Tên File (`Storefront/`) | Kích Thước | Nơi Upload Trên Creator Hub | Vai Trò Hiển Thị |
| :-: | :--- | :-: | :--- | :--- |
| 1 | `GameIcon_512x512.png` | `512x512` | Experience -> Places -> Start Place -> **Icon** | Ảnh đại diện vuông trên Home, Search & Discover |
| 2 | `Thumbnail_01_SkyClash_1920x1080.png` | `1920x1080` | Experience -> **Promotional Media** (Vị trí #1) | Banner chính trang thông tin Game (Combat & VFX) |
| 3 | `Thumbnail_02_AbyssalDragon_1920x1080.png` | `1920x1080` | Experience -> **Promotional Media** (Vị trí #2) | Banner biến hình Rồng Vực Thẳm & Thức Tỉnh V4 |
| 4 | `Thumbnail_03_FloatingRealms_1920x1080.png` | `1920x1080` | Experience -> **Promotional Media** (Vị trí #3) | Banner khám phá Đảo Bay & Tàu Chiến Không Gian |
| 5 | `Thumbnail_04_ArsenalAndCores_1920x1080.png` | `1920x1080` | Experience -> **Promotional Media** (Vị trí #4) | Banner 12 Tinh Thể Lõi Aether (Vòng Cổ Tự), Đại Kiếm Skyborn & Đàn Hạc Hư Không (`Void Lyre`) |

---

## 3. Quy Trình Upload Bộ UI PNG & Lưu Ý Quan Trọng (`Image ID` vs `Decal ID`)

> **QUAN TRỌNG — Tránh lỗi ảnh trắng trong Game do nhầm `Decal ID` với `Image ID`**:
> - **Cách khuyên dùng nhanh và chuẩn nhất (qua Roblox Studio)**:
>   1. Mở file `.rbxlx` của dự án trong **Roblox Studio** (sau khi đã Publish lên Roblox).
>   2. Mở **View -> Asset Manager** -> Nhấn nút **Bulk Import** -> Chọn toàn bộ 71 file `.png` trong thư mục `UI_Icons/` (Roblox cho phép import tối đa 50 file/lượt, nên chia làm 2 lượt).
>   3. Trong cửa sổ **Asset Manager -> Images**, nhấp chuột phải vào từng ảnh -> chọn **Copy ID to Clipboard**. Mã thu được chính là **Image Asset ID** thật — dán vào `UIAssets.lua` theo định dạng `"rbxassetid://1234567890"`.
> - **Nếu upload qua trình duyệt Web (`Creator Hub -> Creations -> Development Items -> Decals`)**:
>   - ID trên thanh URL của trang Decal là `Decal ID` (không phải `Image ID` trực tiếp cho `ImageLabel`). Hãy copy `Decal ID` đó dán tạm vào thuộc tính `Image` của một `ImageLabel` bất kỳ trong Roblox Studio rồi nhấn `Enter` — Studio sẽ tự động đổi sang mã `rbxassetid://<ImageID>` chuẩn để bạn copy vào `UIAssets.lua`.
> - **Quy tắc Fallback an toàn**: Các khóa nào chưa upload thì giữ nguyên chuỗi rỗng `""` trong `UIAssets.lua` để `UIFactory` tự động hiển thị biểu tượng Vector dự phòng sạch đẹp, tuyệt đối không điền ID giả.
> - **Lưu ý cấu hình `NineSliceRects`**:
>   - Trong `UIAssets.lua`, `NineSliceRects.Panel = Rect.new(16, 16, 48, 48)` và `NineSliceRects.Button = Rect.new(12, 12, 52, 52)` được thiết kế khớp trực tiếp 1:1 với bản `64x64` (`ui_panel_9slice_64.png`, `ui_button_9slice_64.png`).
>   - Cả hai bản `128x128` (`ui_panel_9slice.png`, `ui_button_9slice.png`) đều được giữ phần vát góc nằm gọn trong `< 14px` (Panel) và `< 10px` (Button) với vùng nền trung tâm đồng nhất 100%, nên hoạt động mượt với cả `Rect.new(16,16,48,48)` lẫn `Rect.new(32,32,96,96)`.

---

## 4. Bảng Ánh Xạ Chi Tiết `UI_Icons/` -> `ReplicatedStorage/SkybreakShared/Config/UIAssets.lua`

### 4.1. Nhóm Core UI, Logo, Backgrounds & Khung 9-Slice (`8` file)

| Tên File (`UI_Icons/`) | Kích Thước | Hệ Màu | Loại Upload | Khóa Đích Trong `UIAssets.lua` | Ghi Chú Kỹ Thuật |
| :--- | :-: | :-: | :-: | :--- | :--- |
| `ui_logo.png` | `512x160` | `RGBA` | Image / Decal | `UIAssets.Logo` | Logo kim loại vàng 3D nền trong suốt |
| `ui_panel_9slice.png` | `128x128` | `RGBA` | Image / Decal | `UIAssets.PanelNineSlice` | Khung Panel 9-Slice HD (`Rect(32,32,96,96)` hoặc giữ mặc định) |
| `ui_panel_9slice_64.png` | `64x64` | `RGBA` | Image / Decal | `UIAssets.PanelNineSlice` *(Tùy chọn 1:1)* | Bản chuẩn `64x64` khớp 1:1 `Rect.new(16, 16, 48, 48)` |
| `ui_button_9slice.png` | `128x128` | `RGBA` | Image / Decal | `UIAssets.ButtonNineSlice` | Khung Nút bấm 9-Slice HD (nhuộm màu mượt qua `ImageColor3`) |
| `ui_button_9slice_64.png` | `64x64` | `RGBA` | Image / Decal | `UIAssets.ButtonNineSlice` *(Tùy chọn 1:1)* | Bản chuẩn `64x64` khớp 1:1 `Rect.new(12, 12, 52, 52)` |
| `ui_worldmap_bg.png` | `1920x1080` | `RGB` | Image / Decal | `UIAssets.WorldMapBackground` | Nền bản đồ tinh vân 8 Cõi (không dính chữ tĩnh) |
| `ui_mainmenu_bg.png` | `1920x1080` | `RGB` | Image / Decal | `UIAssets.MainMenuBackground` | Cảnh Đền Lõi Aether 3D dự phòng cho Main Menu |
| `ui_soft_glow.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.SoftGlow` | Quầng sáng mềm Alpha không cắt viền vuông |

### 4.2. Nhóm Biểu Tượng Vũ Khí, Kỹ Năng, Tiền Tệ & Hệ Thống (`35` file -> `UIAssets.Icons`)

| Tên File (`UI_Icons/`) | Kích Thước | Hệ Màu | Loại Upload | Khóa Đích Trong `UIAssets.lua` |
| :--- | :-: | :-: | :-: | :--- |
| `ui_icon_sword.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Sword` |
| `ui_icon_daggers.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Daggers` |
| `ui_icon_staff.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Staff` |
| `ui_icon_gun.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Gun` |
| `ui_icon_fist.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Fist` |
| `ui_icon_haki.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Haki` |
| `ui_icon_fruit.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Fruit` |
| `ui_icon_shield.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Shield` |
| `ui_icon_bolt.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Bolt` |
| `ui_icon_lightning.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Lightning` |
| `ui_icon_frost.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Frost` |
| `ui_icon_flame.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Flame` |
| `ui_icon_wing.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Wing` |
| `ui_icon_bag.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Bag` |
| `ui_icon_potion.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Potion` |
| `ui_icon_ship.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Ship` |
| `ui_icon_gift.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Gift` |
| `ui_icon_skill.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Skill` |
| `ui_icon_quest.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Quest` |
| `ui_icon_map.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Map` |
| `ui_icon_compass.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Compass` |
| `ui_icon_forge.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Forge` |
| `ui_icon_raid.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Raid` |
| `ui_icon_settings.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Settings` |
| `ui_icon_volume.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Volume` |
| `ui_icon_close.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Close` |
| `ui_icon_gold.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Gold` |
| `ui_icon_coreshard.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.CoreShard` |
| `ui_icon_coreshards.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.CoreShards` |
| `ui_icon_voidessence.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.VoidEssence` |
| `ui_icon_anchor.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Anchor` |
| `ui_icon_lock.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Lock` |
| `ui_icon_check.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Check` |
| `ui_icon_star.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Star` |
| `ui_icon_heart.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Heart` |

*(Bộ Kit cũng đi kèm sẵn 5 icon mở rộng tương thích với `UIFactory.lua`: `ui_icon_flask.png`, `ui_icon_scroll.png`, `ui_icon_trade.png`, `ui_icon_trophy.png`, `ui_icon_users.png` — có thể thêm khóa tương ứng vào `UIAssets.Icons` nếu muốn dùng).*

### 4.3. Nhóm Biểu Tượng Cửa Hàng, VIP, GamePass (`512x512`) & Developer Products (`512x512`) (`12` file)

| Tên File (`UI_Icons/`) | Kích Thước | Hệ Màu | Loại Upload | Khóa Đích Trong `UIAssets.lua` / Creator Hub | Ý Nghĩa Hiển Thị |
| :--- | :-: | :-: | :-: | :--- | :--- |
| `ui_icon_crown.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.Crown` | Vương miện VIP / Cửa hàng Robux |
| `ui_icon_passexp.png` | `512x512` | `RGBA` | Pass Icon & Decal | `UIAssets.Icons.PassExp` + Pass `x2_exp` | GamePass x2 Mastery / EXP Vĩnh Viễn |
| `ui_icon_passgold.png` | `512x512` | `RGBA` | Pass Icon & Decal | `UIAssets.Icons.PassGold` + Pass `x2_gold` | GamePass x2 Gold Vĩnh Viễn |
| `ui_icon_passstorage.png` | `512x512` | `RGBA` | Pass Icon & Decal | `UIAssets.Icons.PassStorage` + Pass `extra_core_storage` | GamePass Mở rộng Kho Lõi (`+3 Ô`) |
| `ui_icon_passship.png` | `512x512` | `RGBA` | Pass Icon & Decal | `UIAssets.Icons.PassShip` + Pass `golden_sky_ship` | GamePass Thuyền Hoàng Kim (`Golden Sky Ship`) |
| `ui_icon_passaura.png` | `512x512` | `RGBA` | Pass Icon & Decal | `UIAssets.Icons.PassAura` + Pass `sovereign_name_aura` | GamePass Hào Quang Danh Hiệu `[VIP]` |
| `ui_icon_robuxgem.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.Icons.RobuxGem` | Ngọc Cao Cấp / Cửa Hàng Robux |
| `ui_icon_prod_gold_s.png` | `512x512` | `RGBA` | DevProduct Icon | Creator Hub DevProduct `gold_pouch_s` | Túi Gold Nhỏ (`+5,000 Gold`) |
| `ui_icon_prod_gold_m.png` | `512x512` | `RGBA` | DevProduct Icon | Creator Hub DevProduct `gold_pouch_m` | Rương Gold Vừa (`+20,000 Gold`) |
| `ui_icon_prod_gold_l.png` | `512x512` | `RGBA` | DevProduct Icon | Creator Hub DevProduct `gold_pouch_l` | Kho Báu Gold Lớn (`+60,000 Gold`) |
| `ui_icon_prod_exp30m.png` | `512x512` | `RGBA` | DevProduct Icon | Creator Hub DevProduct `double_exp_30m` | Buff x2 EXP (`30 Phút` Online) |
| `ui_icon_prod_stat_refund.png` | `512x512` | `RGBA` | DevProduct Icon | Creator Hub DevProduct `stat_refund` | Vé Tẩy Toàn Bộ Điểm Chỉ Số |

### 4.4. Nhóm Khung Viền Phẩm Chất Vật Phẩm (`5` file -> `UIAssets.RarityBorders`)

| Tên File (`UI_Icons/`) | Kích Thước | Hệ Màu | Loại Upload | Khóa Đích Trong `UIAssets.lua` |
| :--- | :-: | :-: | :-: | :--- |
| `ui_rarity_common.png` | `128x128` | `RGBA` | Image / Decal | `UIAssets.RarityBorders.Common` |
| `ui_rarity_rare.png` | `128x128` | `RGBA` | Image / Decal | `UIAssets.RarityBorders.Rare` |
| `ui_rarity_epic.png` | `128x128` | `RGBA` | Image / Decal | `UIAssets.RarityBorders.Epic` |
| `ui_rarity_legendary.png` | `128x128` | `RGBA` | Image / Decal | `UIAssets.RarityBorders.Legendary` |
| `ui_rarity_mythic.png` | `128x128` | `RGBA` | Image / Decal | `UIAssets.RarityBorders.Mythic` |

### 4.5. Nhóm Chân Dung 3D Hệ Phái Khởi Đầu (`3` file -> `UIAssets.ClassPortraits`)

| Tên File (`UI_Icons/`) | Kích Thước | Hệ Màu | Loại Upload | Khóa Đích Trong `UIAssets.lua` |
| :--- | :-: | :-: | :-: | :--- |
| `ui_class_skyguardian_portrait.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.ClassPortraits.SkyGuardian` |
| `ui_class_thunderstriker_portrait.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.ClassPortraits.ThunderStriker` |
| `ui_class_arcanemage_portrait.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.ClassPortraits.ArcaneMage` |

### 4.6. Nhóm Chân Dung 3D Trùm Các Cõi & Raid (`8` file -> `UIAssets.BossPortraits`)

| Tên File (`UI_Icons/`) | Kích Thước | Hệ Màu | Loại Upload | Khóa Đích Trong `UIAssets.lua` | Cõi / Trùm Tương Ứng |
| :--- | :-: | :-: | :-: | :--- | :--- |
| `ui_boss_aureonsentinel_portrait.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.BossPortraits.AureonSentinel` | Golden Sky — Aureon Sentinel |
| `ui_boss_cryonprime_portrait.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.BossPortraits.CryonPrime` | Frozen Cyber — Cryon Prime |
| `ui_boss_noxar_portrait.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.BossPortraits.Noxar` | Abyssal Nebula — Noxar |
| `ui_boss_sylvaris_portrait.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.BossPortraits.Sylvaris` | Verdant Spire — Sylvaris |
| `ui_boss_ignivar_portrait.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.BossPortraits.Ignivar` | Molten Forge — Ignivar |
| `ui_boss_nerith_portrait.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.BossPortraits.Nerith` | Sunken Astral — Nerith |
| `ui_boss_aion_portrait.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.BossPortraits.Aion` | Chrono Citadel — Aion |
| `ui_boss_veyr_portrait.png` | `256x256` | `RGBA` | Image / Decal | `UIAssets.BossPortraits.Veyr` | Shattered Core — Sovereign Veyr |

---

## 5. Ví Dụ Điền Mã Vào `UIAssets.lua` Sau Khi Upload

```lua
local UIAssets = {
    Logo = "rbxassetid://18900000001",
    PanelNineSlice = "rbxassetid://18900000002",
    ButtonNineSlice = "rbxassetid://18900000003",
    WorldMapBackground = "rbxassetid://18900000004",
    MainMenuBackground = "rbxassetid://18900000005",
    SoftGlow = "rbxassetid://18900000006",
    -- ...
}
```
Sau khi lưu `UIAssets.lua`, chạy lại script đồng bộ `.rbxlx` của dự án để toàn bộ giao diện HUD, Cửa Hàng, Bản Đồ Thế Giới và Chọn Hệ Phái tự động nạp bộ PNG chính thức.
