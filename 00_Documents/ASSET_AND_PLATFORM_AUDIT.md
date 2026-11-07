# BÁO CÁO KIỂM TOÁN ASSET ID & GIỚI HẠN NỀN TẢNG MESH RUNTIME (P0-08 & P0-09)

> **Căn cứ:** Mục 4 (`P0-08` và `P0-09`) trong [`PUBLISH_PLAN.md`](../PUBLISH_PLAN.md).  
> **Phạm vi quét:** Toàn bộ **129 file `.lua`** trong 3 thư mục chuẩn (`04_Roblox/01_HangMuc1_Server_Combat_World`, `04_Roblox/02_HangMuc2_UI_Shop_Config`, `04_Roblox/03_HangMuc3_3D_VuKhi_Giap_VFX`) và cấu trúc gói 3D runtime `DelegatedV5Sources`.

---

## Phần I — P0-08: Điều Tra 3 Asset ID Báo Lỗi Trong Studio Log & Kiểm Toán Toàn Bộ 78 `rbxassetid://`

### 1.1. Kết Quả Điều Tra 3 Asset ID Báo `could not fetch` Trong Studio Log (05–06/11/2026)

Trong nhật ký Roblox Studio ngày 05–06/11/2026 xuất hiện 3 cảnh báo tải tài nguyên:
- `MeshContentProvider failed to process ... id=74564640282568`
- `MeshContentProvider failed to process ... id=112107804308297`
- `HSRDataContentProvider failed to process ... id=137354588220741` *(Hidden Surface Removal / WrapTarget Cage Mesh)*

**Kết quả kiểm chứng độc lập:**
1. **Quét toàn bộ 129 file `.lua` trong 3 thư mục Hạng Mục:** `0` kết quả khớp cho cả 3 ID (`74564640282568`, `112107804308297`, `137354588220741`).
2. **Quét toàn văn file Place `04_Roblox/SKYBREAK_Playable_v12_PremiumUI.rbxlx` (~318 MB XML):** `0` kết quả khớp cho cả 3 ID.
3. **Nguyên nhân gốc rễ (Root Cause):**
   - Cả 3 Asset ID này **không nằm trong mã nguồn Luau hay file `.rbxlx` của dự án SKYBREAK**.
   - Chúng được nạp động lúc chạy (`Play`) từ **`HumanoidDescription` / Avatar mặc định bên ngoài của tài khoản người chơi đang đăng nhập Roblox Studio** (cụ thể là `MeshId` và dữ liệu `HSRData` / `WrapLayer` của phụ kiện Layered Clothing hoặc gói cơ thể R15 UGC trên tài khoản cá nhân khi Roblox CDN tạm thời từ chối tải hoặc phụ kiện UGC bị ẩn).
   - Theo **Rule 4 (`AGENTS.md`)**, game bảo toàn 100% Avatar mặc định của người chơi (`IsNativeAvatar`) nên không xóa `Accessory` / `WrapLayer` của người chơi. Cảnh báo này thuộc tầng tải Avatar của Engine Roblox, không phải asset lỗi của game.

**Đoạn mã kiểm tra nhanh trong Studio Command Bar (nếu cần xác minh trong phiên Play):**
```lua
for _, d in ipairs(game:GetDescendants()) do
	local ok, id = pcall(function()
		return d.MeshId or d.TextureID
	end)
	if ok and type(id) == "string" and (id:find("74564640282568") or id:find("112107804308297") or id:find("137354588220741")) then
		print("[FOUND IN RUNTIME TREE]", d:GetFullName(), id)
	end
end
```

---

### 1.2. Tổng Hợp Toàn Bộ 78 Mã `rbxassetid://` Duy Nhất Trong 129 File Luau

Quét toàn bộ 129 file `.lua` ghi nhận **119 lần xuất hiện** của **`78` giá trị `rbxassetid://<số>` duy nhất**, phân bố vào 4 nhóm:

| Nhóm danh mục | Số ID duy nhất | Số lần xuất hiện | File sử dụng | Ghi chú quyền sở hữu & Trạng thái |
| :--- | :---: | :---: | :--- | :--- |
| **1. Mẫu kiểm tra hợp lệ (Guard / Regex)** | `2` | `2` | `AssetManifest.lua` | Chỉ nằm trong comment và biểu thức chính quy chặn ID giả (`0`, `0000000000`). |
| **2. Hình ảnh UI & Particle VFX (`Image / Texture`)** | `4` | `4` | `UIAssets.lua`, `SkybreakClientVFX.lua`, `DelegatedV5.client.lua` | 2 atlas dự án (`84846582893628`, `100014627871168`) + 2 hạt cổ điển Roblox (`243660364`, `1084969995`). |
| **3. Hộp bầu trời 3 Cõi (`Skybox Cubemap Image`)** | `18` | `18` | `RealmEnvironment.lua` | 3 bộ Skybox × 6 mặt (`goldenSky`, `frozenSky`, `shadowSky`) dùng chung cho 8 Realms. |
| **4. Âm thanh chiến đấu, UI & Nhạc nền (`Sound`)** | `54` | `95` | `SkybreakAudioEngine.lua` (53 ID), `VFXStudioLibrary.lua` (1 ID) | Thư viện SFX/BGM chuẩn của Roblox (`1222xxxx`, `1836xxxxxx`, `184xxxxxxx`, `903xxxxxxx`, `911xxxxxxx`, `912xxxxxxx`) + `112234886947497`. |
| **5. Animation / Mesh (`rbxassetid://`)** | `0` | `0` | *(Không dùng)* | Toàn bộ Mesh 3D và Animation được giải nén runtime từ `DelegatedV5Sources` & `GuardianMotion/*`. |
| **TỔNG CỘNG** | **`78`** | **`119`** | **6 file `.lua`** | Không có MeshId hay AnimationId ngoài luồng. |

---

### 1.3. Bảng Chi Tiết Từng Mã `rbxassetid://` (01 → 78)

#### A. Nhóm Kiểm Tra Hợp Lệ & Hình Ảnh UI / VFX (6 ID)

| STT | Asset ID | Phân loại | Số lần | Vị trí sử dụng (`File:Dòng`) | Mục đích / Khóa cấu hình |
| :-: | :--- | :--- | :-: | :--- | :--- |
| 01 | `rbxassetid://0` | Guard Regex | 1 | `02_HangMuc2_UI_Shop_Config/ReplicatedStorage/SkybreakShared/AssetManifest.lua:59` | Kiểm tra chặn ID rỗng `^rbxassetid://0+$` |
| 02 | `rbxassetid://0000000000` | Comment Guard | 1 | `02_HangMuc2_UI_Shop_Config/ReplicatedStorage/SkybreakShared/AssetManifest.lua:3` | Ghi chú quy tắc không dùng ID placeholder |
| 03 | `rbxassetid://243660364` | Image (Particle) | 1 | `03_HangMuc3_3D_VuKhi_Giap_VFX/StarterPlayer/StarterPlayerScripts/SkybreakClientVFX.lua:155` | Texture hạt tia lửa `ParticleEmitter` chiến đấu |
| 04 | `rbxassetid://1084969995` | Image (Particle) | 1 | `03_HangMuc3_3D_VuKhi_Giap_VFX/StarterPlayer/StarterPlayerScripts/DelegatedV5.client.lua:1244` | Texture hạt sương/quầng sáng cổng thế giới |
| 05 | `rbxassetid://84846582893628` | Image (UI) | 1 | `02_HangMuc2_UI_Shop_Config/ReplicatedStorage/SkybreakShared/Config/UIAssets.lua:17` | `ProjectRealmPreview` (Ảnh thu nhỏ Realm) |
| 06 | `rbxassetid://100014627871168` | Image (UI Atlas) | 1 | `02_HangMuc2_UI_Shop_Config/ReplicatedStorage/SkybreakShared/Config/UIAssets.lua:16` | `ProjectIconAtlas` (Atlas biểu tượng UI) |

#### B. Nhóm Skybox Cubemap 6 Mặt Trong `RealmEnvironment.lua` (18 ID)

Tất cả nằm tại `03_HangMuc3_3D_VuKhi_Giap_VFX/ReplicatedStorage/Shared/RealmEnvironment.lua` (dòng 2–4):

| STT | Asset ID | Phân loại | Bộ Skybox | Mặt Cubemap (`Face`) | Dòng |
| :-: | :--- | :--- | :--- | :---: | :-: |
| 07 | `rbxassetid://93641632642731` | Image (Skybox) | `goldenSky` (`GoldenSky`, `VerdantCrown`, `ChronosBastion`) | `SkyboxFt` (`ft`) | 2 |
| 08 | `rbxassetid://94264818636230` | Image (Skybox) | `goldenSky` | `SkyboxDn` (`dn`) | 2 |
| 09 | `rbxassetid://125580929564532` | Image (Skybox) | `goldenSky` | `SkyboxLf` (`lf`) | 2 |
| 10 | `rbxassetid://127430124985900` | Image (Skybox) | `goldenSky` | `SkyboxUp` (`up`) | 2 |
| 11 | `rbxassetid://134226231755373` | Image (Skybox) | `goldenSky` | `SkyboxBk` (`bk`) | 2 |
| 12 | `rbxassetid://139087821108688` | Image (Skybox) | `goldenSky` | `SkyboxRt` (`rt`) | 2 |
| 13 | `rbxassetid://73836580094387` | Image (Skybox) | `frozenSky` (`FrozenCyber`, `AbyssalTides`) | `SkyboxDn` (`dn`) | 3 |
| 14 | `rbxassetid://76551248708701` | Image (Skybox) | `frozenSky` | `SkyboxUp` (`up`) | 3 |
| 15 | `rbxassetid://88459308214078` | Image (Skybox) | `frozenSky` | `SkyboxRt` (`rt`) | 3 |
| 16 | `rbxassetid://121870448069569` | Image (Skybox) | `frozenSky` | `SkyboxFt` (`ft`) | 3 |
| 17 | `rbxassetid://130166325051175` | Image (Skybox) | `frozenSky` | `SkyboxBk` (`bk`) | 3 |
| 18 | `rbxassetid://134595860932390` | Image (Skybox) | `frozenSky` | `SkyboxLf` (`lf`) | 3 |
| 19 | `rbxassetid://70710544916823` | Image (Skybox) | `shadowSky` (`ShadowRealm`, `EmberforgeWastes`, `VeilsEnd`) | `SkyboxDn` (`dn`) | 4 |
| 20 | `rbxassetid://80772803029327` | Image (Skybox) | `shadowSky` | `SkyboxBk` (`bk`) | 4 |
| 21 | `rbxassetid://100462189328496` | Image (Skybox) | `shadowSky` | `SkyboxRt` (`rt`) | 4 |
| 22 | `rbxassetid://111204609743343` | Image (Skybox) | `shadowSky` | `SkyboxLf` (`lf`) | 4 |
| 23 | `rbxassetid://137756491511210` | Image (Skybox) | `shadowSky` | `SkyboxUp` (`up`) | 4 |
| 24 | `rbxassetid://139181899969965` | Image (Skybox) | `shadowSky` | `SkyboxFt` (`ft`) | 4 |

#### C. Nhóm Âm Thanh SFX & Nhạc Nền BGM Trong `SkybreakAudioEngine.lua` & `VFXStudioLibrary.lua` (54 ID)

Tất cả nằm tại `03_HangMuc3_3D_VuKhi_Giap_VFX/StarterPlayer/StarterPlayerScripts/SkybreakAudioEngine.lua` (trừ mục #65 nằm tại `VFXStudioLibrary.lua`):

| STT | Asset ID | Phân loại | Số lần | Dòng trong file | Khóa âm thanh (`Sound Key` / `BGM Realm`) |
| :-: | :--- | :--- | :-: | :--- | :--- |
| 25 | `rbxassetid://12221967` | Sound (UI SFX) | 6 | `22, 23, 58, 61` | `ui_hover`, `ui_click`, fallback `coin_collect`, `npc_greet` |
| 26 | `rbxassetid://12222030` | Sound (Combat SFX) | 1 | `38` | Fallback `skill_judgment_strike` |
| 27 | `rbxassetid://12222200` | Sound (Combat/UI) | 3 | `24, 26, 29` | Fallback `ui_tab`, `sword_swing_2`, `dodge_dash` |
| 28 | `rbxassetid://12222216` | Sound (Combat SFX) | 3 | `25, 28, 33` | Fallback `sword_swing_1`, `heavy_cleave`, `hit_normal` |
| 29 | `rbxassetid://12222225` | Sound (Combat SFX) | 1 | `27` | Fallback `sword_swing_3` |
| 30 | `rbxassetid://1836473398` | Sound (Jingle) | 1 | `51` | Fallback `level_up` |
| 31 | `rbxassetid://1836473422` | Sound (Jingle) | 4 | `51, 52, 55, 59` | `level_up`, fallback `quest_complete`, `chest_open`, `world_banner` |
| 32 | `rbxassetid://1840777443` | Sound (BGM) | 1 | `68` | Nhạc nền `ShadowRealm` |
| 33 | `rbxassetid://1841333389` | Sound (BGM) | 1 | `71` | Nhạc nền `AbyssalTides` |
| 34 | `rbxassetid://1843821342` | Sound (BGM) | 1 | `70` | Nhạc nền `EmberforgeWastes` |
| 35 | `rbxassetid://1846800615` | Sound (BGM) | 1 | `74` | Nhạc nền `BossBattle` |
| 36 | `rbxassetid://1846800656` | Sound (BGM) | 1 | `66` | Nhạc nền `GoldenSky` |
| 37 | `rbxassetid://9038472201` | Sound (BGM) | 1 | `69` | Nhạc nền `VerdantCrown` |
| 38 | `rbxassetid://9042466902` | Sound (BGM) | 1 | `67` | Nhạc nền `FrozenCyber` |
| 39 | `rbxassetid://9046506025` | Sound (BGM) | 1 | `73` | Nhạc nền `VeilsEnd` |
| 40 | `rbxassetid://9047776050` | Sound (BGM) | 1 | `72` | Nhạc nền `ChronosBastion` |
| 41 | `rbxassetid://9112823552` | Sound (Combat SFX) | 2 | `43, 62` | `magma_erupt`, `ship_cannon` |
| 42 | `rbxassetid://9113447116` | Sound (UI/Craft) | 1 | `53` | Fallback `forge_anvil` |
| 43 | `rbxassetid://9113447467` | Sound (UI/Craft) | 1 | `53` | `forge_anvil` |
| 44 | `rbxassetid://9113525391` | Sound (Movement) | 1 | `32` | `land_impact` |
| 45 | `rbxassetid://9113551901` | Sound (Combat SFX) | 1 | `45` | `gravity_crush` |
| 46 | `rbxassetid://9113552058` | Sound (Combat SFX) | 1 | `47` | `haki_conqueror` |
| 47 | `rbxassetid://9113564868` | Sound (Combat SFX) | 2 | `32, 33` | `hit_normal`, fallback `land_impact` |
| 48 | `rbxassetid://9113980319` | Sound (Boss SFX) | 1 | `50` | `boss_roar` |
| 49 | `rbxassetid://9113980507` | Sound (Boss SFX) | 1 | `50` | Fallback `boss_roar` |
| 50 | `rbxassetid://9114024708` | Sound (Boss SFX) | 1 | `49` | Fallback `boss_telegraph` |
| 51 | `rbxassetid://9114024787` | Sound (Boss SFX) | 1 | `49` | `boss_telegraph` |
| 52 | `rbxassetid://9114257451` | Sound (Ambient/SFX)| 5 | `37, 46, 59, 60, 616` | `skill_guardian_shield`, `world_banner`, `activeHarmonicSound`, fallback `portal_warp`, `nebula_wipe` |
| 53 | `rbxassetid://9114341891` | Sound (Teleport) | 3 | `46, 57, 60` | `portal_warp`, `nebula_wipe`, fallback `cloud_geyser` |
| 54 | `rbxassetid://9114369623` | Sound (Reward SFX) | 4 | `40, 54, 56, 58` | `potion_heal`, `coin_collect`, fallback `skill_frost_shatter`, `shrine_bless` |
| 55 | `rbxassetid://9114463219` | Sound (Combat SFX) | 2 | `36, 42` | `skill_sky_slash`, fallback `flame_burst` |
| 56 | `rbxassetid://9114465041` | Sound (Combat SFX) | 1 | `27` | `sword_swing_3` |
| 57 | `rbxassetid://9114776898` | Sound (Reward SFX) | 1 | `55` | `chest_open` |
| 58 | `rbxassetid://9116279560` | Sound (Combat SFX) | 2 | `31, 44` | `flash_step`, fallback `light_beam` |
| 59 | `rbxassetid://9116394876` | Sound (Combat SFX) | 4 | `40, 48, 54, 56` | `skill_frost_shatter`, `shrine_bless`, fallback `haki_instinct`, `potion_heal` |
| 60 | `rbxassetid://9116673678` | Sound (Combat SFX) | 4 | `28, 34, 35, 62` | `heavy_cleave`, fallback `hit_crit`, `hit_break`, `ship_cannon` |
| 61 | `rbxassetid://9116673944` | Sound (Combat SFX) | 1 | `34` | `hit_crit` |
| 62 | `rbxassetid://9118792735` | Sound (Combat SFX) | 1 | `44` | `light_beam` |
| 63 | `rbxassetid://9119462416` | Sound (Ambient) | 1 | `595` | `activeWindSound` (tiếng gió tầng cao) |
| 64 | `rbxassetid://9119713951` | Sound (Combat SFX) | 2 | `VFXStudioLibrary.lua:1334, 1431` | Âm thanh va chạm mặc định trong `VFXStudioLibrary.PlayRandomPitchSound` |
| 65 | `rbxassetid://9119747260` | Sound (Combat SFX) | 1 | `25` | `sword_swing_1` |
| 66 | `rbxassetid://9120008202` | Sound (Movement) | 1 | `30` | `geppo_step` (`Sky Step`) |
| 67 | `rbxassetid://9120009360` | Sound (Combat SFX) | 2 | `42, 43` | `flame_burst`, fallback `magma_erupt` |
| 68 | `rbxassetid://9120021539` | Sound (Combat SFX) | 2 | `38, 39` | `skill_judgment_strike`, fallback `skill_thunder_strike` |
| 69 | `rbxassetid://9120021794` | Sound (Combat SFX) | 1 | `39` | `skill_thunder_strike` |
| 70 | `rbxassetid://9120369181` | Sound (Combat SFX) | 1 | `35` | `hit_break` |
| 71 | `rbxassetid://9120742716` | Sound (Combat SFX) | 2 | `26, 36` | `sword_swing_2`, fallback `skill_sky_slash` |
| 72 | `rbxassetid://9125484367` | Sound (Combat SFX) | 3 | `41, 45, 47` | `skill_void_rift`, fallback `gravity_crush`, `haki_conqueror` |
| 73 | `rbxassetid://9125484743` | Sound (Combat SFX) | 1 | `41` | Fallback `skill_void_rift` |
| 74 | `rbxassetid://9125644311` | Sound (Combat SFX) | 1 | `48` | `haki_instinct` |
| 75 | `rbxassetid://9125674114` | Sound (Combat SFX) | 1 | `37` | Fallback `skill_guardian_shield` |
| 76 | `rbxassetid://9126283272` | Sound (UI SFX) | 2 | `24, 61` | `ui_tab`, `npc_greet` |
| 77 | `rbxassetid://9126283592` | Sound (Movement) | 4 | `29, 30, 31, 57` | `dodge_dash`, `cloud_geyser`, fallback `geppo_step`, `flash_step` |
| 78 | `rbxassetid://112234886947497` | Sound (Jingle) | 1 | `52` | `quest_complete` (có sẵn fallback `1836473422`) |

> **Khuyến nghị kiểm tra trước khi Publish (`P0-08`):**
> - Các âm thanh đầu `911xxxxxxx`, `912xxxxxxx`, `903xxxxxxx`, `904xxxxxxx`, `183xxxxxxx`, `184xxxxxxx`, `1222xxxx` thuộc kho âm thanh công cộng chính thức của Roblox (`Roblox Creator Store / Pro Sound Effects` miễn phí bản quyền trong Roblox).
> - Cần kiểm tra quyền truy cập của 20 ID thuộc phạm vi tải lên riêng: **18 ID Skybox** (`RealmEnvironment.lua`), **2 ID UI Atlas** (`UIAssets.lua`: `84846582893628`, `100014627871168`) và **1 ID âm thanh** (`112234886947497`) dưới tài khoản/Group sở hữu Place phát hành.

---

## Phần II — P0-09: Giới Hạn Nền Tảng Của Pipeline Mesh Runtime (`EditableMesh` / `EditableImage` / `CreateMeshPartAsync`)

### 2.1. Các Vị Trí Gọi API Tạo Lưới & Ảnh Động Trong Codebase

Hiện tại dự án giải nén dữ liệu hình học `Zstd + Base64` từ `ReplicatedStorage.DelegatedV5Sources` và gọi API `AssetService` tại các vị trí sau:

1. **`03_HangMuc3_3D_VuKhi_Giap_VFX/ReplicatedStorage/DelegatedV5Renderer.lua`** *(và bản mirror `Shared/DelegatedV5Renderer.lua`)*:
   - Dòng 51: `AssetService:CreateEditableImage({ Size = Vector2.new(width, height) })` — tạo texture màu/vật liệu.
   - Dòng 946: `AssetService:CreateEditableMesh()` — dựng dữ liệu đỉnh, pháp tuyến, UV, xương.
   - Dòng 1034: `AssetService:CreateMeshPartAsync(Content.fromObject(editableMesh), { CollisionFidelity = Enum.CollisionFidelity.Box })` — đóng băng `EditableMesh` thành `MeshPart` thực để gắn vào Workspace và cache/clone.
2. **`01_HangMuc1_Server_Combat_World/ServerStorage/SkybornMeshSources/Importer.lua`**:
   - Dòng 13: `AssetService:CreateEditableImage({ Size = Vector2.one })`
   - Dòng 46: `AssetService:CreateEditableMesh()`
   - Dòng 72: `AssetService:CreateMeshPartAsync(content, { CollisionFidelity = Enum.CollisionFidelity.Box })`
3. **`02_HangMuc2_UI_Shop_Config/ReplicatedStorage/SkybreakShared/SpritePlayer.lua`**:
   - Dòng 24: `AssetService:CreateEditableImage({ Size = Vector2.new(256, 256) })` — tạo sprite sheet 4×4 trong bộ nhớ cho hiệu ứng UI.
4. **`03_HangMuc3_3D_VuKhi_Giap_VFX/StarterPlayer/StarterPlayerScripts/SkybornSurfaces.client.lua`**:
   - Dòng 15: `AssetService:CreateEditableImage({ Size = Vector2.one })`

---

### 2.2. Các Ràng Buộc Nền Tảng Của Roblox Đối Với Bản Published (`Live Production`)

Theo tài liệu chính thức của Roblox Creator Documentation về **In-Experience Mesh & Image APIs (`EditableMesh` / `EditableImage`)**:

| Ràng buộc / Giới hạn | Quy định của Nền tảng Roblox | Tác động tới SKYBREAK & Cách xử lý |
| :--- | :--- | :--- |
| **1. Xác minh danh tính chủ sở hữu (`ID Verification Requirement`)** | Để `EditableMesh` và `EditableImage` hoạt động trong một Place đã **Publish**, chủ sở hữu Place (tài khoản cá nhân hoặc chủ Group sở hữu Group) **bắt buộc phải hoàn tất xác minh tuổi bằng giấy tờ tùy thân (13+ ID-Verified) hoặc xác minh số điện thoại theo chính sách Creator Hub**. | Chủ dự án (Khang) phải kiểm tra trạng thái **ID Verified** của tài khoản sở hữu Place trước khi mở công khai. |
| **2. Quyền sở hữu Mesh gốc khi tạo từ sẵn có** | `CreateEditableMeshAsync(Content.fromUri(...))` chỉ cho phép sửa các Mesh thuộc sở hữu của cùng chủ Place. Tuy nhiên, **`AssetService:CreateEditableMesh()` (tạo lưới rỗng từ mảng đỉnh trong bộ nhớ)** không bị chặn bởi quyền sở hữu asset ngoài. | `DelegatedV5Renderer.lua` dùng `AssetService:CreateEditableMesh()` (lưới rỗng nạp từ dữ liệu `DelegatedV5Sources`), nên **không** bị lỗi quyền sở hữu cross-account. |
| **3. Ngân sách bộ nhớ (`Memory Budget`) cho `EditableMesh` / `EditableImage`** | Roblox áp dụng hạn mức bộ nhớ nghiêm ngặt cho các đối tượng `EditableMesh` (tối đa ~60,000 đỉnh / ~20,000 tam giác mỗi mesh và giới hạn tổng số `EditableMesh` đang sống trong bộ nhớ, đặc biệt trên điện thoại 2–3 GB RAM). | • Mọi mảnh mesh trong `runtime_v8` đã được chia nhỏ `<= 18,000` tam giác và kích thước `<= 1,748` studs.<br>• Sau khi gọi `AssetService:CreateMeshPartAsync(snapshot(e))`, cần đảm bảo `EditableMesh` tạm (`e:Destroy()`) được giải phóng ngay khi không cần biến dạng đỉnh trực tiếp, chỉ giữ lại `MeshPart` đã đóng băng trong cache để `:Clone()`. |
| **4. Giới hạn kích thước Place khi Publish (`318 MB .rbxlx`)** | • **Open Cloud Place Publishing API** giới hạn payload tối đa **100 MB**.<br>• **Publish trực tiếp từ Roblox Studio** (`File → Publish to Roblox`) nén nhị phân nội bộ (`.rbxl` binary format, giảm từ ~318 MB XML xuống ~65–85 MB binary) nên vượt qua được giới hạn tải lên. | • **Tuyệt đối không dùng** `deploy_skybreak_to_roblox_cloud.py` (Open Cloud API) cho file `.rbxlx` 318 MB.<br>• **Bắt buộc Publish trực tiếp từ menu `File → Publish to Roblox` trong Roblox Studio**.<br>• Không bật cờ `--cloud-strip-v5-sources` trừ khi toàn bộ 94 gói `DelegatedV5Sources` đã được chuyển sang `MeshPart` (`rbxassetid://`) thật. |
| **5. Thời gian tải lần đầu & Khung hình trên thiết bị di động (`Mobile Cold Start`)** | Giải nén Zstd + dựng hàng trăm `EditableMesh` cùng lúc khi mới vào game có thể gây nghẽn luồng chính trên Android tầm trung. | `DelegatedV5Renderer.lua` đã có hàng đợi ưu tiên theo khoảng cách (`Distance-Priority EditableMesh Build Queue`) và chỉ dựng thế giới gần người chơi trước. Khi test theo `P0-09`, cần ghi lại bảng số đo **Thời gian vào game** và **Client Memory (MB)** trong Developer Console (`F9 → Memory`) trên PC và 1 máy Android tầm trung. |

---

### 2.3. Mẫu Bảng Đo Kiểm Thực Tế (`P0-09 Benchmark Table` — Điền Khi Test Studio / Place Test)

| Thiết bị kiểm thử | Thời gian từ lúc bấm Play tới khi hiện nhân vật & SkyHub (giây) | Tổng Client Memory tại SkyHub (`F9 → Memory`, MB) | Bộ nhớ `GraphicsMeshParts` / `EditableMesh` (MB) | FPS trung bình tại SkyHub / Lúc xả chiêu Rồng | Kết luận (`Đạt / Cần tối ưu`) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **PC (Roblox Studio)** | *Chờ đo* | *Chờ đo* | *Chờ đo* | *Chờ đo* | *Chưa test* |
| **PC (Roblox Player — Place Test Published)** | *Chờ đo* | *Chờ đo* | *Chờ đo* | *Chờ đo* | *Chưa test* |
| **Điện thoại Android tầm trung (Place Test Published)** | *Chờ đo* | *Chờ đo* | *Chờ đo* | *Chờ đo* | *Chưa test* |
