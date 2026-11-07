# BẢNG ÁNH XẠ ĐỔI TÊN IP PHÁI SINH (IP RENAME MAP — P0-02 / Quyết định D1)

> **Căn cứ:** Mục 3.1 (Quyết định `D1`) và Mục 4 (`P0-02`) trong [`PUBLISH_PLAN.md`](../PUBLISH_PLAN.md).  
> **Nguyên tắc thực thi (`D1`):**
> 1. **Đổi 100% chuỗi hiển thị cho người chơi (Player-Facing Text):** Giao diện UI (`Screens/*`, `Components/*`, `I18n.lua`), trường `Name`, `NameVi`, `NameEn`, `Title`, `Desc`, `Description`, thông báo `G.Notify`, `BillboardGui`, tên NPC, tên đảo/vùng đất, tên kỹ năng và hướng dẫn nhiệm vụ.
> 2. **Giữ nguyên ID nội bộ (Internal ID / DataStore Key / Remote Key / VisualAsset Key) trong giai đoạn P0:** Không đổi khóa lưu trữ trong `PlayerDataService.lua`, tên thuộc tính `Attribute`, tên nhánh `DelegatedV5Sources` / `runtime_v8`, hoặc ID tra cứu trong bảng `Config.lua` / `SkybreakCombatData.lua` / `ArsenalExpansionConfig.lua` để tránh làm hỏng dữ liệu hồ sơ người chơi và đường ống đồng bộ 3D.
> 3. **Quy tắc kiểm chứng (`P0-02`):** Khi chạy lệnh `grep` kiểm tra từ khóa phái sinh trên `04_Roblox/0*`, mọi kết quả còn lại bắt buộc chỉ là các **ID nội bộ** đã được kê khai trong tài liệu này — tuyệt đối không còn chuỗi hiển thị trực tiếp cho người chơi.

---

## 1. Bảng Ánh Xạ Chính Thức (22 Nhóm Thuật Ngữ Theo Mục 3.1 `PUBLISH_PLAN.md` & Mở Rộng)

| Tên cũ (phái sinh) | Tên mới tiếng Việt | Tên mới tiếng Anh | ID nội bộ giữ nguyên (Internal ID / Key) | Ghi chú |
| :--- | :--- | :--- | :--- | :--- |
| Haki | Ý Chí Aether | Aether Will | `Haki`, `HakiActive`, `HakiColor`, `UnlockedHakiColors`, `HakiXP`, `HakiStage`, `ActiveHakiColor` | Hệ thống cường hóa ý chí tổng thể; giữ khóa DataStore `UnlockedHakiColors` và `ActiveHakiColor`. |
| Busoshoku / Armament Haki | Giáp Ý Chí | Will Armor | `Busoshoku`, `Armament`, `ArmamentHaki`, `BusoStage`, `HakiArmament`, `haki_armament` | Kỹ năng bọc giáp cường hóa vũ khí/cơ thể (phím `J`). |
| Kenbunshoku / Observation Haki / Ken | Thấu Ý | Will Sense | `Kenbunshoku`, `Observation`, `ObservationHaki`, `Instinct`, `InstinctActive`, `InstinctDodges`, `haki_instinct`, `InstinctVision` | Kỹ năng cảm nhận & né đòn tự động (phím `E` / `K`); giữ tên `ColorCorrectionEffect` `InstinctVision`. |
| Conqueror's Haki | Bá Ý | Sovereign Will | `Conqueror`, `ConquerorsHaki`, `ConquerorHaki`, `haki_conqueror`, `crimson_conqueror` | Xung kích trấn áp diện rộng; giữ ID màu `crimson_conqueror` (thưởng hạ Boss World 3 theo `D9`). |
| Geppo | Bộ Không | Sky Step | `Geppo`, `SkyStep`, `geppo_step`, `MaxAirJumps`, `AirJumpCount` | Kỹ năng đạp không nhảy đa tầng trên không. |
| Soru | Thuấn Bộ | Blink Dash | `Soru`, `FlashStep`, `flash_step`, `FlashStepCooldown` | Kỹ năng dịch chuyển chớp nhoáng tầm ngắn (phím `R` / `Q`). |
| Devil Fruit / Trái Ác Quỷ | Lõi Aether | Aether Core | `DevilFruit`, `Fruit`, `ActiveFruit`, `EquippedFruit`, `StoredFruits`, `FruitMastery`, `FruitAction`, `AetherFruitsCollection1`, `AetherFruitsCollection2`, `AncientAetherFruitTrees` | Toàn bộ hệ thống 12 Lõi nguyên tố; giữ tên Remote `FruitAction` và gói 3D `Fruit_*`. |
| Awakened fruit / Thức tỉnh trái | Lõi Thức Tỉnh | Awakened Core | `Awakened`, `AwakenedMoves`, `FruitAwakening`, `V2Awakening`, `MicrochipAwakeningRaidLab` | Nâng cấp kỹ năng Lõi bậc 2 sau khi hoàn thành Raid. |
| Race V4 | Thăng Hoa | Ascension | `RaceV4`, `RaceV4Active`, `RaceV4Meter`, `RaceV4Tier`, `RaceV4Unlocked`, `RaceV4WingsSet`, `TempleOfTheCoreRaceV4` | Trạng thái biến hình bung cánh 3D tối thượng (phím `Y`); giữ gói 3D `RaceV4WingsSet`. |
| Leviathan | Thủy Xà Vực Thẳm | Abyss Serpent | `Leviathan`, `AbyssalLeviathan`, `LeviathanHeart`, `LeviathanScale`, ` LeviathanCrown`, ` LeviathanShield`, `MirageSkyIslandLeviathanAbyss` | Boss đại dương tầng sâu, tộc và nguyên liệu chế tạo liên quan. |
| Sea Beast | Thú Trời | Sky Beast | `SeaBeast`, `SkyBeast`, `DangerSeaBeast`, `AncientSeaBeast` | Quái thú khổng lồ xuất hiện trong sự kiện Vùng Trời Nguy Hiểm (`DangerSea`). |
| Mirage Island | Đảo Hư Quang | Phantom Isle | `MirageIsland`, `Mirage`, `MirageSkyIsland`, `MirageSkyIslandLeviathanAbyss`, `MirageGear` | Đảo bí ẩn xuất hiện định kỳ chứa mảnh ghép Thăng Hoa. |
| Temple of Time / Temple of the Core Race V4 | Đền Thăng Hoa | Ascension Shrine | `TempleOfTheCoreRaceV4`, `TempleOfTheCore`, `TempleOfTime`, `RaceV4Temple` | Khu vực World 12 (`W12`) nơi thực hiện nghi thức Thăng Hoa (`Ascension`). |
| Castle on the Sea / Castle on the Void | Pháo Đài Hư Không | Void Bastion | `CastleOnTheVoidMansion`, `CastleOnTheVoid`, `VoidCastle`, `CastleVoid` | Khu vực trung tâm World 10 (`W10` — Tầng Trời 3). |
| Cafe / Cyberport Cafe | Trạm Giao Thương | Trade Station | `CyberportCafeTradingHub`, `CyberportCafe`, `CafeTradingHub`, `TradeTable` | Khu vực an toàn và bàn giao dịch tại World 5 (`W5` — Tầng Trời 2). |
| Cursed Dual Katana / CDK / Cursed Dual Skyblades | Song Kiếm Nguyệt Thực | Eclipse Twinblades | `CursedDualSkyblades`, `CDK`, `cursed_dual_skyblades` | Vũ khí thần thoại song kiếm (Slot 3); giữ ID `CursedDualSkyblades` trong `VirtualSplitSpecs`. |
| Soul Guitar | Đàn Hồn Hư Không | Void Lyre | `SoulGuitar`, `SoulGuitarVoid`, `soul_guitar` | Vũ khí tầm xa âm hồn (Slot 4); giữ ID `SoulGuitar` / `SoulGuitarVoid` trong `Config` & `VirtualSplitSpecs`. |
| Kabucha | Ná Gió Mặt Trời | Sunwind Sling | `Kabucha`, `KabuchaSling`, `kabucha_sling` | Vũ khí tầm xa hệ Phong/Nhật (Slot 4); giữ ID `KabuchaSling` / `Kabucha`. |
| Buddha (trái) | Lõi Kim Thân | Colossus Core | `SolarTitanCore`, `Buddha`, `SolarTitanBuddha`, `Fruit_SolarTitan` | Lõi biến hình khổng lồ hoàng kim (Rule 3 giữ cả Canonical ID `SolarTitanCore` và alias `Buddha`). |
| Portal (trái) | Lõi Khe Nứt | Rift Core | `DimensionalPortalCore`, `Portal`, `Fruit_DimensionalPortal` | Lõi dịch chuyển không gian (Rule 3 giữ cả Canonical ID `DimensionalPortalCore` và alias `Portal`). |
| Sea 1 / 2 / 3 | Tầng Trời 1 / 2 / 3 | Sky 1 / 2 / 3 | `Sea1`, `Sea2`, `Sea3`, `WorldGate_Sea1_to_Sea2`, `WorldGate_Sea2_to_Sea3`, `DangerSea` | Phân tầng thế giới chính; giữ tên cổng `WorldGate_Sea1_to_Sea2` và `WorldGate_Sea2_to_Sea3` trong Workspace. |
| Zioles / Gacha Shrine | Điện Cầu Lõi / Hiền Giả Lõi | Core Oracle / Core Shrine | `Zioles`, `ZiolesGachaShrine`, `ZiolesGacha` | NPC và điện thờ triệu hồi Lõi Aether ngẫu nhiên; giữ tên asset 3D `ZiolesGachaShrine`. |

---

## 2. Bảng Ánh Xạ Chi Tiết 12 Lõi Aether (Rule 3 Canonical IDs + Legacy Aliases)

Theo **Rule 3 (`AGENTS.md`)**, mọi bảng tra cứu trong code bắt buộc giữ nguyên cả Canonical ID lẫn Legacy Alias dưới đây làm khóa nội bộ, nhưng tên hiển thị trên UI phải dùng tên chuẩn **Lõi Aether (`Aether Core`)**:

| Tên cũ / Phái sinh | Tên mới tiếng Việt | Tên mới tiếng Anh | Canonical ID & Legacy Alias bắt buộc giữ nguyên | Модел 3D / Biến hình nội bộ |
| :--- | :--- | :--- | :--- | :--- |
| Gale / Smoke / Gió | Lõi Cuồng Phong | Gale Core | `GaleCore`, `Gale` | `Fruit_Gale` |
| Smoke / Sandstone / Cát Khói | Lõi Sa Thạch | Sandstone Core | `SandstoneCore`, `Smoke` | `Fruit_Sandstone` |
| Flame / Mera / Lửa | Lõi Nhật Viêm | Solar Flame Core | `SolarFlameCore`, `Flame` | `Fruit_SolarFlame` |
| Ice / Hie / Băng | Lõi Băng Hà | Glacier Ice Core | `GlacierIceCore`, `Ice` | `Fruit_GlacierIce` |
| Rumble / Goro / Sét | Lõi Lôi Đình | Thunder Rumble Core | `ThunderRumbleCore`, `Rumble` | `Fruit_ThunderRumble` |
| Light / Pika / Ánh Sáng | Lõi Thiên Quang | Celestial Light Core | `CelestialLightCore`, `Light` | `Fruit_CelestialLight` |
| Magma / Magu / Dung Nham | Lõi Tinh Nham | Starforged Magma Core | `StarforgedMagmaCore`, `Magma` | `Fruit_StarforgedMagma` |
| Gravity / Zushi / Trọng Lực | Lõi Tinh Cầu | Astral Gravity Core | `AstralGravityCore`, `Gravity` | `Fruit_AstralGravity` |
| Portal / Door / Cổng | Lõi Khe Nứt | Rift Core | `DimensionalPortalCore`, `Portal` | `Fruit_DimensionalPortal` |
| Buddha / Phật Tổ | Lõi Kim Thân | Colossus Core | `SolarTitanCore`, `Buddha` | `Fruit_SolarTitan`, `SolarTitanBuddha` |
| Dough / Mochi / Bột | Lõi Tinh Lưu | Aetherflow Core | `AetherflowCore`, `SweetDoughCore`, `Dough` | `Fruit_Aetherflow` |
| Dragon / Kaido / Rồng | Lõi Long Đế Vực Thẳm | Abyssal Sovereign Core | `AbyssalSovereignCore`, `Dragon` | `Fruit_AbyssalSovereign`, `AbyssalSovereignDragon`, `AbyssalDragonHybrid` |

---

## 3. Bảng Ánh Xạ Võ Thuật, Chủng Tộc, Sự Kiện & Vật Phẩm Liên Quan

| Phân loại | Tên cũ (phái sinh) | Tên mới tiếng Việt | Tên mới tiếng Anh | ID nội bộ giữ nguyên (Internal ID / Key) | Ghi chú |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Võ thuật (`Fighting Style`) | Fishman Karate / Sharkman Karate | Võ Thiên Không | Skyborn Martial | `SkybornKarate`, `skyborn_karate` | Trường phái võ thuật khởi đầu / bậc trung. |
| Võ thuật (`Fighting Style`) | Dragon Talon / Dragon Breath | Long Trảo Tuyệt Kỹ | Sovereign Claw | `DragonTalon`, `dragon_talon` | Trường phái võ thuật hệ Hỏa/Long. |
| Võ thuật (`Fighting Style`) | Electric Claw / Electro | Lôi Trảo | Astral Bolt Claw | `ElectricClaw`, `electric_claw` | Trường phái võ thuật tốc độ cao hệ Lôi. |
| Võ thuật (`Fighting Style`) | Death Step / Dark Step | Hư Không Bộ | Void Step | `VoidStep`, `void_step` | Trường phái võ thuật cước pháp hệ Hư Không. |
| Võ thuật (`Fighting Style`) | Godhuman / Superhuman | Thần Võ Aether | Celestial Paragon | `Godhuman`, `godhuman` | Trường phái võ thuật tối thượng tổng hợp. |
| Chủng tộc (`Lineage`) | Mink | Tộc Phong Linh | Galekin | `Mink`, `Race_Mink` | Tăng tốc độ di chuyển và lướt. |
| Chủng tộc (`Lineage`) | Fishman / Shark / Leviathan Race | Tộc Hải Lưu | Tideborn | `Leviathan`, `Race_Leviathan` | Giảm sát thương và bơi/lướt trên mây. |
| Chủng tộc (`Lineage`) | Cyborg | Tộc Cơ Giới | Automaton | `Cyborg`, `Race_Cyborg` | Giáp phản chấn và hồi năng lượng. |
| Chủng tộc (`Lineage`) | Ghoul | Tộc Dạ Ảnh | Nightshade | `Ghoul`, `Race_Ghoul` | Hút sinh lực và tăng tốc ban đêm. |
| Chủng tộc (`Lineage`) | Draco / Dragon Race | Tộc Long Huyết | Draconic | `Draco`, `Race_Draco` | Sát thương nguyên tố và kháng lực. |
| Sự kiện (`World Event`) | Danger Sea / Terror Shark / Piranha | Vùng Trời Bão Tố / Cá Mập Hư Không | Tempest Expanse / Void Maw | `DangerSea`, `GlacialWreckageDangerSea`, `TerrorShark`, `SkyPiranha` | Sự kiện săn quái vật bằng tàu bay theo cấp độ nguy hiểm 1–6. |
| Khu vực (`Raid Lab`) | Microchip Raid / Law Raid | Đấu Trường Giải Mã Lõi | Core Decryption Lab | `MicrochipAwakeningRaidLab`, `MicrochipRaid` | Khu vực World 7 (`W7`) dùng thẻ giải mã để thức tỉnh Lõi Aether. |
| Chỉ số (`Stat` / `Bounty`) | Bounty / Honor (Pirate / Marine) | Điểm Uy Danh / Vinh Quang | Renown / Valor | `Bounty`, `Honor` | Giữ khóa hồ sơ `Bounty` và `Honor` trong `PlayerDataService.lua`. |

---

## 4. Lệnh Kiểm Chứng Tự Động Sau Khi Đổi Tên (`P0-02`)

Chạy lệnh dưới đây từ thư mục gốc `SKYBREAK_Antigravity_Handoff` để rà soát các chuỗi phái sinh trong 3 thư mục Hạng Mục:

```bash
grep -rniE "haki|busoshoku|kenbun|conqueror|geppo|soru|devil ?fruit|race ?v4|cursed dual|\bcdk\b|soul ?guitar|kabucha|buddha|leviathan|mirage|sea beast" 04_Roblox/0* --include=*.lua
```

**Tiêu chí đạt (`PASS`):**
- Không còn bất kỳ dòng nào nằm trong trường hiển thị văn bản (`Name = "..."`, `NameVi = "..."`, `Title = "..."`, `Desc = "..."`, `Text = "..."`, `G.Notify(...)`) chứa từ khóa phái sinh bên cột **Tên cũ (phái sinh)**.
- Mọi kết quả khớp còn lại đều thuộc cột **ID nội bộ giữ nguyên (Internal ID / Key)** trong bảng trên.
