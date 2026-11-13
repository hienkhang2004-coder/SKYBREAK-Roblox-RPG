# SKYBREAK: Fragments of the Core — Creator Hub & Public Launch Runbook (`CREATOR_HUB_PUBLISH_CHECKLIST.md`)

Complete, copy-paste-ready release checklist for publishing **SKYBREAK: Fragments of the Core** (`04_Roblox/SKYBREAK_Playable_v12_PremiumUI.rbxlx`) to Roblox Public Discovery (`PC`, `Mobile`, `Tablet`, `Console`).

---

## 1. Critical Pre-Publish Gates (Do These First!)

1. **13+ Government ID Verification on the Publishing Account / Group Owner (MANDATORY)**
   - **Why**: SKYBREAK renders its 13 custom 3D floating worlds, bosses, weapons, and shrines via Roblox's runtime `AssetService:CreateEditableMesh()` and `CreateEditableImage()` APIs (`ReplicatedStorage.DelegatedV5Sources`). Roblox Studio allows `EditableMesh` without ID verification, **but live Roblox production servers silently block `EditableMesh` unless the Experience Creator (or Group Owner) is 13+ Government ID-Verified**.
   - **Action**: Log into [Creator Hub -> Account Settings](https://www.roblox.com/my/account#!/info) -> Confirm **Age Verified (13+ ID Badge)** is active on the publishing account (or the Owner account of the publishing Group) **before** opening public servers.
2. **Publish via Roblox Studio Binary Upload (`File -> Publish to Roblox`) — NEVER Strip `DelegatedV5Sources`**
   - Full `04_Roblox/SKYBREAK_Playable_v12_PremiumUI.rbxlx` is `~318 MB` in uncompressed XML because it embeds all `98` Zstd-compressed 3D runtime mesh payloads inside `ReplicatedStorage.DelegatedV5Sources`.
   - Roblox Open Cloud's raw XML endpoint (`deploy_skybreak_to_roblox_cloud.py`) enforces a `100 MB` XML cap; `--cloud-strip-v5-sources` is now **hard-blocked** because stripping `DelegatedV5Sources` deletes all 3D worlds in live servers.
   - Opening `.rbxlx` in **Roblox Studio** and clicking **`File -> Publish to Roblox`** automatically serializes and compresses the place into Roblox's compact binary format while preserving **100% of `DelegatedV5Sources`**.
3. **Production Sandbox Safety (`DevGate.lua`)**
   - `ServerScriptService/Services/DevGate.lua` automatically disables all `[DEV]` sandbox shortcuts, mock zero-ID store grants, and smoke-test commands on live production `PlaceId`s (`RunService:IsStudio() == false` and `game.PlaceId` not in `AllowedTestPlaceIds`).
   - Any GamePass, Developer Product, or Badge left at `0` in `MonetizationConfig.lua` / `BadgeConfig.lua` gracefully displays a polite bilingual `"Sắp mở bán trên Roblox Store / Coming soon on Roblox Store"` toast with **zero runtime errors** until you paste the live Creator Hub IDs below.

---

## 2. Storefront Title & Descriptions (Copy-Paste Ready — 100% IP-Clean)

### 2.1 English (Default / Primary Storefront Listing)
- **Experience Title**:
  ```text
  SKYBREAK: Fragments of the Core
  ```
- **Storefront Description**:
  ```text
  ⚡ AWAKEN YOUR AETHER CORE & CONQUER THE SHATTERED SKIES! ⚡

  Welcome to SKYBREAK: Fragments of the Core — an action-packed 3D Aerial Fantasy RPG across 3 vast Sky Tiers and 8 Floating Realms! Choose your starting combat path, master 12 elemental Aether Cores, forge Mythic Skyborn blades, and command sky-galleons into the Abyss.

  ✨ KEY FEATURES
  • 12 Elemental Aether Cores: Harness Gale, Solar Flame, Glacier Ice, Celestial Light, Thunder Rumble, Starforged Magma, Astral Gravity, Dimensional Portal, Solar Titan, Aetherflow, and the 3-Stage Abyssal Sovereign Dragon!
  • Deep Progression (Max Lv. 2,550): Quest across Golden Sky, Frozen Cyber, Shadow Realm, and 5 Endgame Realms — solo or with your Party (+EXP Boost with Friends!).
  • Core Awakening (V2) & Skyborn Ascension (V4): Raid the Microchip Lab to awaken V2 Core skills and clear the Ancient Temple Trial to unlock V4 Celestial Wings!
  • World Bosses & Abyssal Leviathan Hunts: Crew up on armed warships, brave Danger Zones, defeat the Abyssal Leviathan, and harpoon-tow its Heart back to port!
  • Fair-Play Arena & Trading: 1v1 Colosseum Duels, P2P Core Trading at Cyberport Cafe (Lv. 700+), Session Playtime Gifts, and Cross-Server Leaderboards.

  💎 100% FAIR PLAY PROMISE
  Utility & cosmetic passes only — every Aether Core, Mythic weapon, and Awakening is 100% earnable through gameplay!

  🎮 CONTROLS (PC / Mobile / Console Supported)
  [M1] Combo • [Z/X/C/V] Skills • [F] Core Flight / Mobility • [Q] Dash • [E] Aether Armament • [U] Will Sense • [T] Skyborn Ascension
  ```

### 2.2 Tiếng Việt (`Creator Hub -> Localization -> Languages -> Vietnamese`)
- **Tên Trải Nghiệm (Experience Name)**:
  ```text
  SKYBREAK: Mảnh Vỡ Lõi Thiên Giới
  ```
- **Mô Tả Cửa Hàng (Experience Description)**:
  ```text
  ⚡ THỨC TỈNH LÕI AETHER & CHINH PHỤC ĐẠI THIÊN GIỚI 3D! ⚡

  Chào mừng đến với SKYBREAK: Fragments of the Core — tựa game nhập vai hành động không chiến 3D trải dài qua 3 Tầng Trời và 8 Cõi Đảo Bay kỳ vĩ! Khai mở sức mạnh từ 12 Lõi Aether nguyên tố, rèn Thần Khí, lập Hạm Đội săn Đại Thủy Xà và vươn tới đỉnh cao Cấp 2.550.

  ✨ TÍNH NĂNG ĐẶC SẮC
  • 12 Lõi Aether Nguyên Tố: Làm chủ Cuồng Phong, Hỏa Dương, Băng Tinh, Thiên Quang, Lôi Điện, Dung Nham, Trọng Lực, Không Gian, Thái Dương Khổng Lồ, Quang Lưu và Hóa Rồng Vực Thẳm 3 Giai Đoạn!
  • Hành Trình Cấp 2.550: Khám phá Golden Sky, Frozen Cyber, Shadow Realm cùng 5 Cõi Mở Rộng — tổ đội cùng Bạn Bè nhận ngay cộng dồn +EXP!
  • Thức Tỉnh Lõi V2 & Huyết Thống V4: Vượt Đấu Trường Giải Mã Lõi mở khóa kỹ năng V2 và chinh phục Cổ Điện Khởi Nguyên để thức tỉnh Đôi Cánh V4!
  • Săn Boss Thế Giới & Thủy Xà Vực Thẳm: Điều khiển chiến hạm vượt vùng biển mây nguy hiểm, hạ gục Đại Thủy Xà và phóng lao kéo Trái Tim Thủy Xà về cảng!
  • Đấu Trường Công Bằng & Giao Dịch 4x4: Quyết đấu 1v1 Đấu Trường La Mã, giao dịch Lõi tại Quán Cà Phê Cyberport (Lv. 700+), Quà Online mỗi ngày & Bảng Xếp Hạng Liên Server.

  💎 CAM KẾT 100% CÔNG BẰNG
  Cửa hàng chỉ bán tiện ích & ngoại trang — toàn bộ Lõi Thần Thoại, Thần Khí và Thức Tỉnh đều cày miễn phí 100% trong game!
  ```

---

## 3. Storefront Promotional Media Upload Order

Location: `02_Concept_Art/UI_And_Storefront_Kit/Storefront/`

| Order | File Name | Dimensions | Creator Hub Destination | Notes |
| :-: | :--- | :-: | :--- | :--- |
| **Icon** | `GameIcon_512x512.png` | `512x512` | `Places -> Start Place -> Icon` | Tested for crisp silhouette readability at `150x150` on Home/Discover. |
| **#1** | `Thumbnail_01_SkyClash_1920x1080.png` | `1920x1080` | `Promotional Media` (Slot 1 — Primary CTR) | Hero Skyborn sword & lightning clash showcase. |
| **#2** | `Thumbnail_02_AbyssalDragon_1920x1080.png` | `1920x1080` | `Promotional Media` (Slot 2) | Abyssal Sovereign Dragon Form 2 & V4 Ascension. |
| **#3** | `Thumbnail_03_FloatingRealms_1920x1080.png` | `1920x1080` | `Promotional Media` (Slot 3) | Celestial Aether Galleon & Frozen Cyber floating archipelago. |
| **#4** | `Thumbnail_04_ArsenalAndCores_1920x1080.png` | `1920x1080` | `Promotional Media` (Slot 4) | **Regenerated IP-Clean Showcase**: 12 faceted Aether Crystal Cores with orbital rune rings, Skyborn Greatswords & Celestial Void Lyre. |

---

## 4. Creator Hub Place, Avatar & Security Settings

Verify all settings below under **`Creator Hub -> Creations -> Experiences -> SKYBREAK -> Configure`** (these are also baked directly into `.rbxlx` by `sync_solid3d_and_scripts_to_rbxlx.py`):

| Category | Setting | Required Value | Why |
| :--- | :--- | :--- | :--- |
| **Access** | **Maximum Visitor Count (`MaxPlayers`)** | **`16`** | Balanced for 16-player island mob density, 60s boss respawns, and mobile `EditableMesh` memory budget. |
| **Access** | **Server Fill** | **Roblox Optimized** | Keeps friends together while leaving headroom for party joins. |
| **Avatar** | **Avatar Type** | **R15 (`Standard`)** | Enforces native R15 player avatar preservation (Rule 4) with full clothing/accessory/face support. |
| **Devices** | **Playable Devices** | **Computer, Phone, Tablet, Console** | Responsive mobile HUD/flight + gamepad bindings + desktop shift-lock/mouse combat are all enabled. |
| **Security** | **Enable Studio Access to API Services** | **ON** | Required for `DataStoreService` (`PlayerDataService`) and `OrderedDataStore` cross-server leaderboards. |
| **Security** | **Allow Third Party Sales / Teleports** | **OFF** | Prevents unauthorized asset prompts or place hijacks. |
| **Chat** | **TextChatService (`ChatVersion`)** | **`TextChatService` (`1`)** | Required for Roblox safety compliance + `[VIP]` Golden Sovereign chat tags. |

> **Custom Audio / Animation Asset Permissions Check**:
> If publishing under a **Roblox Group** rather than your personal account, ensure the Group has **Use** permission on the 21 uploaded `rbxassetid://` sound/animation assets referenced in `SkybreakAudioEngine.lua` and `Config.lua` (`Creator Hub -> Development Items -> Audio / Animations -> Permissions`).

---

## 5. Maturity & Compliance Questionnaire Answers (Target Rating: `Mild` / `9+`)

Navigate to **`Creator Hub -> Creations -> Experiences -> SKYBREAK -> Questionnaire`** and enter:

| Questionnaire Section | Exact Answer | Technical Implementation Reference |
| :--- | :--- | :--- |
| **Violence** | **Yes -> Mild / Fantasy Violence** | Stylized anime/fantasy elemental slashes & energy beams against sky pirates, golems, and bosses. |
| **Violence Frequency** | **Repeated** | Core RPG combat loop. |
| **Blood / Gore / Realistic Violence** | **No** | Zero blood decals, dismemberment, or realistic corpses; enemies dissolve cleanly. |
| **Fear / Horror** | **No** | High-fantasy celestial & cyber-glacial aesthetic; no jump-scares or horror themes. |
| **Gambling / Casino** | **No** | Zero wagering, slots, blackjack, or cash-out mechanics. |
| **Paid Random Items** | **Yes (In-game currency purchasable with Robux can roll randomized items; odds disclosed & `PolicyService` enforced)** | No direct Robux gacha exists. Because Robux `Gold Pouches` grant `Gold` (which can also roll Zioles' Aether Core Shrine or Arcane Runes), SKYBREAK discloses exact `%` odds (`Mythic 2.4%`, `Legendary 6.6%`, `Epic 12.0%`, `Rare 18.0%`, `Uncommon 29.0%`, `Common 32.0%` + `50`-roll Pity) **AND** checks `PolicyService:GetPolicyInfoForPlayerAsync(player).ArePaidRandomItemsRestricted` server-side to automatically block `Gold Pouch` purchases in restricted jurisdictions/accounts! |
| **Unscripted User Text Creation** | **Yes (Filtered via `TextService`)** | Custom Crew Names & Crew Tags are sanitized server-side via `TextService:FilterStringAsync` before storage or display. |
| **Player-to-Player Trading** | **Yes (Earned In-Game Items Only)** | 4x4 P2P Trading Table at `Cyberport Cafe` (`Lv. 700+`, `<= 28 studs`), restricted to F2P stored Cores & crafting relics (Robux items are non-tradable). |
| **Profanity / Crude Humor / Romance / Substances** | **No** | Clean bilingual EN/VI fantasy dialogue throughout. |
| **Unmoderated Off-Platform Links / Voice** | **No** | Promo giftcode hints have zero external URLs; friend invites use official `SocialService:PromptGameInvite`. |

---

## 6. Monetization & Badges Setup Tables (5 GamePasses + 5 DevProducts + 8 Badges)

All `10` Monetization icons are pre-rendered at crisp **`512x512` RGBA PNG** inside:
`02_Concept_Art/UI_And_Storefront_Kit/UI_Icons/`

### 6.1 Five Launch GamePasses (`Creator Hub -> Monetization -> Passes`)

Paste each generated **Pass ID** into `04_Roblox/02_HangMuc2_UI_Shop_Config/ReplicatedStorage/SkybreakShared/Config/MonetizationConfig.lua` (`MonetizationConfig.GamePasses`):

| # | Config `Key` | `MonetizationConfig.lua` Field | Price (R$) | `512x512` Icon File (`UI_Icons/`) | Creator Hub Pass Name (EN / VI) | Creator Hub Description |
| :-: | :--- | :--- | :-: | :--- | :--- | :--- |
| 1 | `x2_exp` | `GamePassId = 0` *(Line 38)* | **299 R$** | `ui_icon_passexp.png` | `Permanent 2x EXP Pass` / `Đặc Quyền x2 EXP Vĩnh Viễn` | Permanently doubles all EXP & Mastery earned from Enemies, Bosses, and Quests. |
| 2 | `x2_gold` | `GamePassId = 0` *(Line 51)* | **249 R$** | `ui_icon_passgold.png` | `Permanent 2x Gold Pass` / `Đặc Quyền x2 Gold Vĩnh Viễn` | Permanently doubles Gold earned from Enemies, Bosses, and Quests. |
| 3 | `extra_core_storage` | `GamePassId = 0` *(Line 64)* | **199 R$** | `ui_icon_passstorage.png` | `Expanded Core Storage (+3)` / `Mở Rộng Kho Lõi (+3 Ô)` | Increases maximum Vault storage per Aether Core type by +3 slots. |
| 4 | `golden_sky_ship` | `GamePassId = 0` *(Line 78)* | **349 R$** | `ui_icon_passship.png` | `Golden Sovereign Sloop` / `Thuyền Hoàng Kim` | Unlocks the radiant Golden Sovereign Ship skin (balanced standard speed). |
| 5 | `sovereign_name_aura` | `GamePassId = 0` *(Line 91)* | **99 R$** | `ui_icon_passaura.png` | `Celestial Nameplate Aura` / `Hào Quang Danh Hiệu Thiên Giới` | Unlocks the Golden Sovereign `[VIP]` chat tag & overhead nameplate aura. |

### 6.2 Five Launch Developer Products (`Creator Hub -> Monetization -> Developer Products`)

Paste each generated **Product ID** into `04_Roblox/02_HangMuc2_UI_Shop_Config/ReplicatedStorage/SkybreakShared/Config/MonetizationConfig.lua` (`MonetizationConfig.DevProducts`):

| # | Config `Key` | `MonetizationConfig.lua` Field | Price (R$) | `512x512` Icon File (`UI_Icons/`) | Creator Hub Product Name (EN / VI) | Creator Hub Description |
| :-: | :--- | :--- | :-: | :--- | :--- | :--- |
| 1 | `gold_pouch_s` | `ProductId = 0` *(Line 108)* | **49 R$** | `ui_icon_prod_gold_s.png` | `Small Gold Pouch (+5,000 Gold)` | Instantly grants +5,000 Gold for weapon forging and ship upgrades. |
| 2 | `gold_pouch_m` | `ProductId = 0` *(Line 122)* | **149 R$** | `ui_icon_prod_gold_m.png` | `Medium Gold Chest (+20,000 Gold)` | Instantly grants +20,000 Gold for gear and Martial Dojo training. |
| 3 | `gold_pouch_l` | `ProductId = 0` *(Line 136)* | **399 R$** | `ui_icon_prod_gold_l.png` | `Large Gold Treasury (+60,000 Gold)` | Instantly grants +60,000 Gold for high-tier weapons and ships. |
| 4 | `stat_refund` | `ProductId = 0` *(Line 150)* | **79 R$** | `ui_icon_prod_stat_refund.png` | `Full Stat Points Refund` | Grants +1 Stat Refund Token to respec all allocated Stat Points freely. |
| 5 | `double_exp_30m` | `ProductId = 0` *(Line 164)* | **39 R$** | `ui_icon_prod_exp30m.png` | `2x EXP Boost (30 Minutes)` | Adds 30 minutes of online-only 2x EXP (stacks with Permanent 2x EXP Pass!). |

### 6.3 Eight Launch Badges (`Creator Hub -> Engagement -> Badges`)

Create the 8 Badges below (you can reuse matching `UI_Icons/ui_icon_*.png` icons) and paste each **Badge ID** into `04_Roblox/02_HangMuc2_UI_Shop_Config/ReplicatedStorage/SkybreakShared/BadgeConfig.lua`:

| # | `BadgeConfig.lua` `Id` | `BadgeConfig.lua` Field | Suggested Icon (`UI_Icons/`) | Badge Name (EN / VI) | Badge Description (EN) |
| :-: | :--- | :--- | :--- | :--- | :--- |
| 1 | `welcome_skyborn` | `BadgeId = 0` *(Line 13)* | `ui_icon_sword.png` | `Skyborn Initiate` / `Tân Chiến Binh Bầu Trời` | Arrive at Sky Hub Sanctuary and complete starter training quest Q01. |
| 2 | `first_aether_core` | `BadgeId = 0` *(Line 27)* | `ui_icon_fruit.png` | `First Aether Core` / `Khế Ước Lõi Aether` | Roll or attune your very first Aether Core at Oracle Zioles' Shrine. |
| 3 | `aureon_slayer` | `BadgeId = 0` *(Line 41)* | `ui_icon_shield.png` | `Warden of Dawnbreaker` / `Kẻ Phá Vỡ Hào Quang` | Vanquish Aureon Sentinel in the Sun Citadel Arena (Sky 1). |
| 4 | `sea2_cyberport` | `BadgeId = 0` *(Line 55)* | `ui_icon_compass.png` | `Frozen Cyber Voyager` / `Lữ Khách Băng Thành` | Reach Level 700 and unlock passage into Sky 2 • Frozen Cyber. |
| 5 | `cryon_slayer` | `BadgeId = 0` *(Line 69)* | `ui_icon_frost.png` | `Sub-Zero Conqueror` / `Chinh Phục Tuyệt Độ` | Defeat Cryon Prime and unseal the Void Gate to Sky 3 • Shadow Realm. |
| 6 | `awakened_core_v2` | `BadgeId = 0` *(Line 83)* | `ui_icon_bolt.png` | `Awakened Core Sovereign` / `Thức Tỉnh Lõi Cực Hạn` | Clear the Microchip Raid Lab and awaken any Aether Core to V2. |
| 7 | `leviathan_slayer` | `BadgeId = 0` *(Line 97)* | `ui_icon_crown.png` | `Abyssal Leviathan Slayer` / `Thợ Săn Thủy Xà Vực Thẳm` | Slay the Abyssal Leviathan and harpoon-tow its Heart back to port. |
| 8 | `apex_architect_2550` | `BadgeId = 0` *(Line 111)* | `ui_icon_star.png` | `Apex Skyborn (Lv. 2550)` / `Đỉnh Cao Thiên Giới Lv.2550` | Reach Max Level 2550 or defeat Veyr, The First Architect at Veil's End. |

---

## 7. Step-by-Step Build, Sync & Roblox Studio Publish Procedure

Whenever you paste new Creator Hub IDs or edit any Luau script inside `04_Roblox/01_HangMuc1_Server_Combat_World`, `02_HangMuc2_UI_Shop_Config`, or `03_HangMuc3_3D_VuKhi_Giap_VFX`:

### Step 1 — Run the Automated `.rbxlx` Sync & Verification Gate Suite
Double-click `DONG_BO_CODE_VAO_GAME.bat` **or** run in PowerShell:
```powershell
$PY = "C:\Program Files\Blender Foundation\Blender 5.2\5.2\python\bin\python.exe"
& $PY "05_Pipeline_Tools_27x_9x\sync_solid3d_and_scripts_to_rbxlx.py"
& $PY "05_Pipeline_Tools_27x_9x\verify_27x_9x_game_sync.py"
& $PY "05_Pipeline_Tools_27x_9x\lint_luau_globals.py"
& $PY "04_Roblox\tests\test_logic.py"
& $PY "04_Roblox\tests\test_data.py"
& $PY "05_Pipeline_Tools_27x_9x\skybreak_contract_simulator_v3.py"
```
Confirm **100% `[PASS]`** across all 6 gates (`< 199,000 B` on every `.lua` script, `SkybornSpawn == (-317.4, 50.5, 527.8)`, `0` orphan scripts, `100%` SHA-256 `Source` parity).

### Step 2 — Open & Smoke-Test in Roblox Studio
1. Open `04_Roblox/SKYBREAK_Playable_v12_PremiumUI.rbxlx` in **Roblox Studio** (logged into your **13+ ID-Verified** Creator/Group Owner account).
2. Press **Play (`F5`)**:
   - Confirm your native R15 avatar spawns cleanly on Sky Hub Plaza at `(-317.4, 50.5, 527.8)` with the Class Onboarding Modal centered cleanly.
   - Check **Output** window: confirm `0` red Luau errors and `DelegatedV5` streams Sky 1 `GoldenSky` 3D meshes smoothly.
   - *(Optional)* Switch to **Device Emulator (`iPhone SE / 667x375`)** to verify responsive mobile HUD, thumbstick clearance, and `[F]` Flight Up/Down controls.
3. Press **Stop (`Shift+F5`)**.

### Step 3 — Binary Publish to Roblox Cloud
1. In Roblox Studio, select **`File -> Publish to Roblox`** (or **`File -> Publish to Roblox As...`** on first upload).
2. Select your target Experience (**SKYBREAK: Fragments of the Core**).
3. Wait for Studio's binary upload progress bar to complete (`Published successfully`).
4. In **Creator Hub -> Configure -> Access**, switch **Visibility** from `Private` -> **`Public`** when ready to launch, then join a **live Roblox Player client** (outside Studio!) to verify live `EditableMesh` rendering, `DataStore` persistence, `TextChatService`, and Store prompts!
