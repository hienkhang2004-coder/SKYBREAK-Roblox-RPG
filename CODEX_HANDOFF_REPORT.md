# BÁO CÁO BÀN GIAO DỰ ÁN SKYBREAK (ANTIGRAVITY → CODEX)

- **Dự án**: `SKYBREAK: Fragments of the Core` (Roblox Action RPG)
- **Phiên bản bàn giao**: `v14_Full93Models_InGameSync_WorldPortals` (100% `93/93` Rigged & Animated V5 Models Active In-Game + `52` Blender `.blend` Packs + `22` Sequential End-of-World Portals `World n -> World n+1` + 3D Transformations `SolarTitanBuddha` / `AbyssalSovereignDragon` / `RaceV4WingsSet` + Balanced RPG + Procedural DSP Audio/BGM)
- **Ngày bàn giao**: `2026-10-27`
- **File Roblox Place chính thức**: `04_Roblox/SKYBREAK_Playable_v12_PremiumUI.rbxlx` (`312.46 MB` / `327,641,819 bytes` | SHA256: `050578a24b80d75c06a995e4bb7238981b5fd86ac289870bcf7fa5a9f8f84d4e`)
- **Chỉ mục Master Manifest**: `06_Antigravity_Work/SKYBREAK_Master_Overhaul_Manifest_v13.json`
- **Trạng thái**: Đã hoàn tất 100% đại tu Nhân vật, Boss, NPC, Quái, Vũ khí, Trái Ác Quỷ, Tàu, Đài thờ, **toàn bộ 21 World/Đảo lớn/Cổng dịch chuyển** và **đồng bộ 100% (`93/93` mô hình V5 + `104` tệp Luau)** vào trực tiếp hệ thống gameplay thời gian thực (`0` mô hình bị bỏ sót).

---

## 1. Tổng Kết Các Hạng Mục Đã Hoàn Thành (Waves 1 → 21)

### 1.1. Đại Tu & Tích Hợp Trực Tiếp `93/93` Mô Hình 3D Trong `ReplicatedStorage.DelegatedV5Sources` & `52/52` File `.blend`
- **Tổng số mô hình V5 đã đóng gói (`Zstd + Base64`) trong `.rbxlx`**: **`93 / 93` mô hình (100% có xương Rig, `Clips.json` & đang hoạt động trực tiếp trong game)**:
  - **72 Mô hình Nhân vật, Boss, NPC, Quái, Vũ khí, Trái Ác Quỷ & Tàu chiến**:
    - Chia lưới cong **PN-Triangle Subdivision (`4×` / `16×`)** với pháp tuyến mượt (`Smooth Vertex Normals`).
    - Điêu khắc **5 lớp hình học nguyên tố 3D thật (`Elem3D_<Model>_AuraRibbon`, `CoreOrb`, `GroundSigil`, `CrownSwirl`, `SparkOrbs`)** gắn trực tiếp vào xương (`Spine`, `Hand_R`, `Weapon_R`, `Head`, `Root`) cùng `ElementalShaderProfile` (`SOLAR`, `LIGHTNING`, `ARCANE`, `CRYO`, `VOID`, `GALE`, `ABYSS`, `CHRONO`, `EMBER`).
    - Mỗi mô hình sở hữu **8 clip hoạt ảnh chuẩn hóa** (`Idle`, `Walk`, `Run`, `Attack`, `Skill`, `ElementalSurge`, `HeroicKata`, `UltimateAwakening` — `12 Keyframes` nội suy `Cubic Hermite / Bezier AUTO_CLAMPED` với chuyển động thứ cấp trên Tóc, Áo choàng, Cánh, Đuôi và Vũ khí).
  - **21 Mô hình Thế giới (Worlds), Đảo Lớn (Grand Sky Islands), Cổng Không Gian (Portals), Đài Thờ (Shrines) & Công Trình**:
    - **Nhóm Sea 1 & Sea 2 (11 mô hình)**: `GoldenSky`, `SunshardSkySanctuary`, `WestGardenPirateBastion`, `FrozenCyber`, `CyberportCafeTradingHub`, `PermafrostGarrisonFortress`, `MicrochipAwakeningRaidLab`, `GlacialWreckageDangerSea`, `FrozenPortal`, `CryonPillar`, `KaelWorkstation`.
    - **Nhóm Sea 3 & Expansion (10 mô hình)**: `ShadowRealm`, `CastleOnTheVoidMansion`, `UmbralCrystalSanctumForest`, `TempleOfTheCoreRaceV4`, `MirageSkyIslandLeviathanAbyss`, `ShadowPortal`, `NoxarVoidFX`, `ZiolesGachaShrine`, `AetherShrinesAndRaidConsole`, `AncientAetherFruitTrees`.
    - **Hệ thống Rig 10 Xương Môi Trường (`10-Bone World Rig`)**:
      - Mỗi World/Đảo được gắn 10 xương chuyển động: `Root`, `CentralCore_Rotor`, `OuterAstrolabe_Rotor`, `FloatingCrystals_Bob`, `FoliageCanopy_Sway`, `BannerSail_Sway`, `WaterfallCascade_Flow`, `BeaconHalo_Pulse`, `ExitPortalRing_Spin`, `ExitPortalVortex_Pulse` cùng **8 clip hoạt ảnh môi trường 12-Keyframe** (`Idle`, `WorldIdle_Loop`, `ElementalPulse`, `PortalSurge`, `AstrolabeSpin`, `CrystalResonance`, `TempestSway`, `CataclysmAwakening`).
- **Thông số kiểm toán toàn cục (`verify_all_93_v5_and_4_targets_sync.py` & `SKYBREAK_Master_Overhaul_Manifest_v13.json`)**:
  - `total_models`: **`93 / 93`** (`0` mô hình tĩnh, `0` mô hình không được tham chiếu trong game — `100%` xuất hiện & chuyển động trong gameplay)
  - `total_meshes`: **`2,461`** (`1,000` mesh nguyên tố `Elem3D_*`)
  - `total_triangles`: **`7,337,723`** tam giác (`4,246,130` đỉnh)
  - `total_bones`: **`2,135`** xương
  - `total_clips`: **`754`** clip hoạt ảnh (`93/93` mô hình có đủ $\ge 8$ clip và `ElementalShaderProfile`)
  - `Synchronized Luau Scripts`: **`104 / 104`** tệp Luau khớp tuyệt đối `100% byte-for-byte` giữa `04_Roblox/src/`, `SKYBREAK_Visual_v2/src/`, `06_Antigravity_Work/luau_v8/` và `SKYBREAK_Playable_v12_PremiumUI.rbxlx`.

---

### 1.2. Đại Tu Hệ Thống Biến Hình 3D, Cánh Tộc V4, Trái Ác Quỷ 3D & AI Boss 3-Phase (Waves 20 → 21)
1. **Biến Hình 3D Đầy Đủ Xương & Hoạt Ảnh (`DelegatedV5.client.lua`)**:
   - **Kim Thân Thái Dương Phật Tổ (`SolarTitanBuddha`)**: Khi người chơi kích hoạt chiêu `[Z]` của `SolarTitanCore`, `buildFruitTransformFX` & `stepFruitTransformFX` dựng trực tiếp mô hình V5 `SolarTitanBuddha` (`Scale = 1.65`) bám theo `HumanoidRootPart` và chạy hoạt ảnh `Idle`, `Run`, `Attack`, `ElementalSurge`, `HeroicKata`, `UltimateAwakening` đồng bộ với trạng thái di chuyển và chiến đấu của người chơi.
   - **Thái Cổ Long Hoàng & Long Nhân Hư Không (`AbyssalSovereignDragon` / `AbyssalDragonHybrid`)**: Khi người chơi kích hoạt chiêu `[V]` của `AbyssalSovereignCore`, hệ thống dựng trực tiếp mô hình V5 `AbyssalSovereignDragon` (`Scale = 1.95`) hoặc `AbyssalDragonHybrid` (`Scale = 1.45`) đập cánh và uốn lượn theo 8 clip 12-Keyframe.
   - **Bộ Cánh Thức Tỉnh Tộc V4 (`RaceV4WingsSet`)**: Khi kích hoạt `RaceV4` (`[Y]`), `buildRaceV4FX` & `stepRaceV4FX` gắn trực tiếp mô hình V5 `RaceV4WingsSet` (`Scale = 1.38`) vào `UpperTorso` và vỗ cánh theo clip `UltimateAwakening` / `HeroicKata`.
   - **12 Trái Ác Quỷ 3D Cầm Tay & Trên UI (`Fruit_*`)**: `buildHeldFruitFX` & `stepHeldFruitFX` trong `DelegatedV5.client.lua` và `mount3DFruitPreview` trong `Fruits.lua` (`[G]`) cùng gọi `Renderer.Pose(model, clip, now)` để vòng nguyên tố và lõi của 12 trái `Fruit_*` xoay & đập nhịp trực tiếp trên tay nhân vật lẫn trong khung 3D `ViewportFrame`.
   - **Lò Rèn Thần Khí 3D (`Forge.lua` & `GameService.lua`)**: Trưng bày trực tiếp mô hình V5 `KaelWorkstation`, `MythicalWeaponsSet`, `AetherFruitsCollection1`, `AetherFruitsCollection2` tại `Sky Hub`, `Lumen Plaza` và `Zioles Shrine`, đồng thời dựng và chạy hoạt ảnh `MythicalWeaponsSet` ngay trong `WeaponViewport` của màn hình `Forge [H]`.
2. **Hệ Thống Chuyển Pha Boss 3 Giai Đoạn & Chu Kỳ Kata Chiến Đấu (`GameService.lua` & `BlenderEnemies.client.lua`)**:
   - Toàn bộ 22 Singleton Bosses trên 20 Worlds chuyển pha tự động (`Phase 1` $\rightarrow$ `Phase 2` ở `70% HP` $\rightarrow$ `Phase 3` ở `35% HP`), phát hoạt ảnh `UltimateAwakening` kèm sóng xung kích và luân phiên ra đòn bằng chuỗi `Attack` $\rightarrow$ `ElementalSurge` $\rightarrow$ `HeroicKata` $\rightarrow$ `Heavy` $\rightarrow$ `UltimateAwakening`.
   - Nâng cấp `StartBossRush` trong `GameService.lua` và nút `WARP & START BOSS RUSH` trong `Raid.lua` (`[P]`) hỗ trợ dịch chuyển và đấu lại trực tiếp toàn bộ Boss chính kể cả 5 Boss Expansion Realms (`Sylvaris`, `Ignivar`, `Nerith`, `Aion`, `Veyr`).
   - Bổ sung thanh kích hoạt **3D Motion Kata (`[🥋 KATA]`, `[⚡ SURGE]`, `[👑 AWAKEN]`)** trong màn hình `Skills [K]` để người chơi biểu diễn trực tiếp các clip 12-Keyframe `HeroicKata`, `ElementalSurge`, `UltimateAwakening`.

---

### 1.3. Hệ Thống 22 Cổng Dịch Chuyển Tuần Tự Cuối World (`World n -> World n+1`) & La Bàn Cổng 3D
- **Thiết kế tiến trình không gian (`GameService.lua`, `DelegatedV5.client.lua`, `ClientBootstrap.lua`, `HUD.lua`)**:
  - Khởi tạo thư mục `workspace.WorldPortals` chứa **22 Cổng Dịch Chuyển Cuối World (`WorldGate_01` $\rightarrow$ `WorldGate_20` + `WorldGate_Sea1_to_Sea2` + `WorldGate_Sea2_to_Sea3`)**.
  - Mỗi cổng `WorldGate_n` được đặt tại **điểm cuối của World thứ $n$ (ngay phía sau vị trí Boss trấn ải của World $n$)** và dẫn thẳng tới **điểm khởi đầu (Entrance Spawn) của World thứ $n+1$** xuyên suốt chuỗi 20 World (`W1` $\rightarrow$ `W20` $\rightarrow$ `Ascension Loop về W1`).
- **La Bàn Dẫn Đường Tới Cổng Cuối World (`UpdatePlayerPortalCompass` & `WorldGateCompass`)**:
  - Hàm `G.ResolveWorldOrderFromPos(pos)` và `G.UpdatePlayerPortalCompass(p, order)` trong `GameService.lua` tự động cập nhật thuộc tính `CurrentWorldOrder`, `NextWorldGateId`, `NextWorldGatePos`, `NextWorldGateLabel` mỗi khi người chơi đi qua cổng hoặc dịch chuyển nhanh (`FastTravel`).
  - `ClientBootstrap.lua` hiển thị thanh dẫn đường `🌀 CỔNG CUỐI WORLD n ➡ WORLD n+1 (khoảng cách m)` và `HUD.lua` hiển thị trực tiếp tiến trình `◈ <REALM> (Wn/20)` cùng cổng tiếp theo ở góc trên bên phải.
- **Cổng 3D Đa Tầng Chuyển Động Thời Gian Thực (`DelegatedV5.client.lua`)**:
  - `stepWorldGates3D(now, camPos)` và vòng lặp 20 `animatedWorlds` được gọi trực tiếp mỗi khung hình trong `Run.RenderStepped` của `DelegatedV5.client.lua`.

---

## 2. Cấu Trúc Thư Mục Bàn Giao Đã Kiểm Kê & Đồng Bộ 100%

```text
SKYBREAK_Antigravity_Handoff/
├── 00_START_HERE.md
├── CODEX_HANDOFF_REPORT.md                                  # Báo cáo bàn giao chính thức này
├── 00_Documents/
│   └── SKYBREAK_Game_Design_And_Asset_Guide.md
├── 02_Blender/                                              # Các file .blend nguồn & môi trường đã gắn Rig 10 xương
├── 02_Blender_Files/                                        # 52 bộ file .blend đã đại tu (Subsurf + NURBS + 12-KF Action)
├── 02_Concept_Art/                                          # Ảnh Concept Art gốc
├── 04_Roblox/
│   ├── SKYBREAK_Playable_v12_PremiumUI.rbxlx                # (312.45 MB) FILE ROBLOX PLACE CHÍNH THỨC DUY NHẤT (93 V5 Models + 104 Scripts)
│   └── src/                                                 # 104 tệp Luau đồng bộ 100% byte-for-byte với .rbxlx & SKYBREAK_Visual_v2/src
├── 06_Antigravity_Work/
│   ├── SKYBREAK_Playable_v12_PremiumUI.rbxlx                # Bản sao dự phòng 100% byte-identical của Place chính thức
│   ├── SKYBREAK_Master_Overhaul_Manifest_v13.json           # Chỉ mục kiểm toán chi tiết toàn bộ 93 mô hình V5 & 52 file .blend
│   ├── generate_skybreak_sfx_wavs.py                        # Script tổng hợp 30 file .wav (SFX + BGM)
│   ├── rework_skybreak_from_scratch.py                      # Script đóng gói cấu trúc Place
│   └── luau_v8/                                             # Mã nguồn Luau cốt lõi (Master Source)
│       ├── Config.lua                                       # Cấu hình Level, Stats, Enemies/Bosses, 14 Quests (Q01-Q14)
│       ├── PlayerDataService.lua                            # Lưu trữ DataStore an toàn & khởi tạo Profile Lv.1
│       ├── GameService.lua                                  # Chiến đấu, AI Boss 3-Phase, 22 Cổng Cuối World & La Bàn Cổng
│       ├── DelegatedWorldService.lua                        # Khởi tạo mặt sàn va chạm chuẩn xác (ISLAND_FLOOR_SLABS)
│       ├── DelegatedV5.client.lua                           # Dựng & chạy hoạt ảnh 93 mô hình V5, Biến hình 3D, 20 Worlds & 22 Cổng Stargate
│       ├── BlenderEnemies.client.lua                        # Dựng & chạy hoạt ảnh toàn bộ Quái, Boss, NPC, Tàu, Đài thờ & Bệ Trái Ác Quỷ
│       ├── DelegatedV5Renderer.lua                          # Bộ giải mã EditableMesh, Skinning, 0.18s Crossfade & Elemental Pulse
│       ├── ClientBootstrap.lua / ClientBootstrap.client.lua # Điều khiển Client, VFX Stargate, La Bàn Cổng, 3D Audio & Dynamic BGM
│       ├── HUD.lua / Fruits.lua / Skills.lua / Raid.lua / Forge.lua
│       └── ...
└── 07_Audio_SFX/                                            # 30 tệp âm thanh & nhạc nền Stereo .wav (26 SFX + 4 BGM)
```

---

## 3. Hướng Dẫn Nhanh Cho Codex Khi Tiếp Tục Phát Triển

1. **Mở & Kiểm tra trong Roblox Studio**:
   - Mở trực tiếp file `SKYBREAK_Antigravity_Handoff/04_Roblox/SKYBREAK_Playable_v12_PremiumUI.rbxlx` (đã dọn sạch file `.lock` cũ).
   - Toàn bộ **93/93 thư mục mô hình V5** nằm trong `ReplicatedStorage.DelegatedV5Sources` (mỗi thư mục gồm `Header`, `Clips`, `Mesh000..MeshNNN` nén `Zstd + Base64`).
2. **Kiểm toán & Đồng bộ tự động 4 đích (`luau_v8`, `04_Roblox/src`, `SKYBREAK_Visual_v2/src`, `.rbxlx`)**:
   - Chạy script đồng bộ và kiểm toán tự động bằng Python của Blender 5.2:
     ```powershell
     $py = "C:\Program Files\Blender Foundation\Blender 5.2\5.2\python\bin\python.exe"
     & $py "C:\Users\khang\.gemini\antigravity\brain\a5ff31b6-f80a-4fc5-9966-3fd7bc2d86e4\scratch\master_sync_all_4_targets.py"
     & $py "C:\Users\khang\.gemini\antigravity\brain\a5ff31b6-f80a-4fc5-9966-3fd7bc2d86e4\scratch\verify_all_93_v5_and_4_targets_sync.py"
     ```
