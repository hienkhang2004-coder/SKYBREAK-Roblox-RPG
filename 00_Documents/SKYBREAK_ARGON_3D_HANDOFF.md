# SKYBREAK — bàn giao cải thiện 3D cho Model 4 Argon

Tài liệu lập ngày 23/10/2026. Người dùng sẽ tự chuyển tài liệu này cho Argon; việc tạo tài liệu không có nghĩa đã khởi chạy hoặc giao việc qua Antigravity.

## Mục tiêu người dùng

Cải thiện các model Blender hiện có để bám sát ảnh concept SKYBREAK, ưu tiên silhouette, tỉ lệ, khuôn mặt, tóc, thiết kế giáp/quần áo, vũ khí và vật liệu. Người dùng đặt mục tiêu thị giác **99% giống tham chiếu**. Đây là mục tiêu, chưa có model nào được xác nhận đạt mức này. Không dùng dung lượng file hoặc số polygon để thay cho đánh giá chất lượng.

## Cách đọc các đường dẫn

Tất cả liên kết là **đường dẫn tuyệt đối trên máy Windows của người dùng**, không phải URL công khai. Argon chạy trên cùng máy có thể đọc trực tiếp bằng công cụ filesystem/Blender. Nếu trình chat không mở được link Markdown, lấy nguyên đường dẫn trong ngoặc và dùng Open/Read File. Argon chạy trên máy khác sẽ cần được cung cấp các file thực tế; link C:/ không tải từ xa được.

Đường dẫn tài liệu thiết kế gốc:


[DESIGN_SOURCE.md](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/DESIGN_SOURCE.md>)



## Prompt để giao cho Argon

> Hãy mở các ảnh tham chiếu và file Blender được chỉ định trong tài liệu này, đối chiếu trực tiếp rồi cải thiện model 3D để giống concept nhất có thể. Trước khi dựng thủ công tóc, giáp, vải, rig hoặc vật liệu, hãy kiểm tra công cụ Blender, add-on và asset dự án có sẵn; chỉ dùng asset ngoài sau khi xem hình thực tế và giấy phép, không mua gì. Giữ nguồn chỉnh sửa được, bảo toàn rig/action/UV và khả năng xuất Roblox. Làm trên bản sao trong thư mục cải thiện riêng, không ghi đè nguồn hiện tại hoặc file Roblox. Render bản hiện có cạnh concept trước, chỉ rõ sai lệch, sửa một mẫu rồi render lại để duyệt phương pháp trước khi nhân rộng. Không tự nhận đạt 99% khi chưa có bằng chứng. Xuất nguồn .blend, bản game, FBX và ảnh so sánh kèm báo cáo kỹ thuật. Đây là nhiệm vụ cải thiện mỹ thuật 3D, không phải tự đăng game hay thay cài đặt bảo mật.

## 1. Ảnh tham chiếu gốc

Các ảnh dưới đây đã được lưu riêng trong thư mục references:


- **Tổng quan ba class, ba thế giới:** [01_key_art.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/01_key_art.png>)

- **Nhân vật phong cách Roblox và đường di chuyển:** [02_traversal.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/02_traversal.png>)

- **Golden Sky:** [03_golden_sky.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/03_golden_sky.png>)

- **Frozen Cyber:** [04_frozen_cyber.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/04_frozen_cyber.png>)

- **Shadow Realm:** [05_shadow_realm.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/05_shadow_realm.png>)

- **Sky Guardian — nam, kiếm/khiên, giáp/khăn đỏ:** [06_sky_guardian.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/06_sky_guardian.png>)

- **Thunder Striker — nam, song dao, khăn xanh:** [07_thunder_striker.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/07_thunder_striker.png>)

- **Arcane Mage — nam, tóc trắng xoăn, trượng:** [08_arcane_mage.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/08_arcane_mage.png>)

- **Aureon Sentinel — boss Golden Sky:** [09_aureon.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/09_aureon.png>)

- **Cryon Prime — boss Frozen Cyber:** [10_cryon.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/10_cryon.png>)

- **Noxar — boss Shadow Realm:** [11_noxar.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/11_noxar.png>)

- **UI kit — tham khảo phong cách:** [12_ui_kit.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/12_ui_kit.png>)

- **Inventory — tham khảo phong cách:** [13_inventory.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/13_inventory.png>)

- **Main menu — tham khảo phong cách:** [14_main_menu.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/14_main_menu.png>)

- **Combat HUD — tham khảo phong cách:** [15_combat_hud.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/15_combat_hud.png>)

- **World map — bố cục thế giới:** [16_world_map.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/16_world_map.png>)

- **Raid HUD — tham khảo bối cảnh trận boss:** [17_raid_hud.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/17_raid_hud.png>)


## 2. Nhân vật người chơi — file Blender nên mở

Không đếm các phiên bản tóc/LOD là nhân vật mới. Hiện có 5 mẫu class/giới tính dưới đây. Guardian có thêm các giai đoạn trang phục trong thư viện chung.


### Sky Guardian nam

Concept: [06_sky_guardian.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/06_sky_guardian.png>)

- [Nguồn mỹ thuật](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/blender/SKYBREAK_SkyGuardian_ArtRefinement.blend>)

- [Nguồn rig và animation có sửa khoảng hở chuyển động](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/blender/SKYBREAK_SkyGuardian_MotionClearance.blend>)


**Hướng cải thiện:** Đối chiếu dáng giáp, tóc đen, khăn/áo choàng đỏ, kiếm và khiên vàng với concept. Giữ các động tác chém mạnh tay, nhảy, lướt đã có.


### Sky Guardian nữ

Concept: [06_sky_guardian.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/06_sky_guardian.png>)

- [Nguồn nữ](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/blender/SKYBREAK_SkyGuardian_Female.blend>)

- [Thư viện nam/nữ và các giai đoạn đồ](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/blender/SKYBREAK_Skyborn_ImportLibrary.blend>)

- [Rig chung](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/blender/SKYBREAK_Skyborn_SharedRig.blend>)


**Hướng cải thiện:** Không có concept nữ riêng trong bộ ảnh gốc. Đây là bản phát triển từ ngôn ngữ Sky Guardian nam; cải thiện silhouette và tỉ lệ nữ rõ ràng, không chỉ thay tóc. Không tự tuyên bố khớp một concept nữ chưa được cung cấp.


### Thunder Striker nam

Concept: [07_thunder_striker.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/07_thunder_striker.png>)

- [Nguồn Complete](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-thunder-striker/outputs/ThunderStriker/ThunderStriker_Complete.blend>)

- [Nguồn rig và animation](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-thunder-striker/outputs/ThunderStriker/ThunderStriker_Rigged_Animated.blend>)

- [Handoff](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-thunder-striker/outputs/ThunderStriker/HANDOFF.md>)


**Hướng cải thiện:** Đối chiếu tóc, giáp tối màu, khăn xanh rách, tỉ lệ thân và song dao. Hiệu ứng điện phải bổ trợ hình dáng, không che model còn sai.


### Thunder Striker nữ

Concept: [07_thunder_striker.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/07_thunder_striker.png>)

- [Nguồn nữ](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-thunder-striker/outputs/ThunderStrikerFemale/ThunderStrikerFemale_Source.blend>)

- [Bản Optimized](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-thunder-striker/outputs/ThunderStrikerFemale/ThunderStrikerFemale_Optimized.blend>)

- [Handoff](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-thunder-striker/outputs/ThunderStrikerFemale/HANDOFF.md>)


**Hướng cải thiện:** Không có concept nữ riêng trong bộ gốc. Giữ tính nhận diện Thunder Striker, phân biệt nữ bằng hình dáng/tỉ lệ phù hợp với rig chung.


### Arcane Mage nam

Concept: [08_arcane_mage.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/08_arcane_mage.png>)

- [Nguồn rig, native groom và 15 action](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/blender/SKYBREAK_ArcaneMage_Rigged.blend>)

- [Nguồn PBR theo vùng](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/blender/SKYBREAK_ArcaneMage_PBRTiles.blend>)

- [Nguồn có các LOD tóc hiện có](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/blender/SKYBREAK_ArcaneMage_DistanceLODs_v3.blend>)

- [Hướng dẫn Mage](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/blender/README_ARCANE_MAGE_VI.md>)


**Hướng cải thiện:** Ưu tiên tóc trắng xoăn, dày, chân tóc hợp lý; mặt, áo khoác dài, hoa văn, vai và trượng phải bám concept. Tóc gần có 5.481.320 tam giác; LOD1 tóc có 686.576, LOD2 có 256.588. Bản runtime v8 mới dùng LOD1, toàn Mage 756.056 tam giác. Cần tối ưu có kiểm chứng; không lặp lại tóc quá dày polygon gây lỗi dung lượng mesh. Nguồn đầy đủ vẫn được giữ.


**Arcane Mage nữ chưa được dựng trong bộ hiện tại.** Không ghi nhận là đã có.

**Trang phục khởi đầu:** nhân vật nam/nữ có tiến trình Novice → Adventurer → Sky Guardian. Giữ cùng hợp đồng rig/kích thước sử dụng trong game; hình dáng cơ thể và trang phục có thể khác theo giới tính. Xem thư viện Skyborn trước khi tạo trùng model hoặc rig.

## 3. NPC và quái/lính đã có nguồn

Các mẫu sau có file 3D nhưng **không có sheet concept riêng được người dùng cung cấp trong bộ 17 ảnh**. Dùng ngôn ngữ Golden Sky, key art và traversal làm tham chiếu phong cách; phải gọi rõ đây là thiết kế suy diễn. Không dùng ảnh boss làm chứng cứ rằng NPC đã có mẫu gốc chính xác.


Tham chiếu chung: [01_key_art.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/01_key_art.png>) · [02_traversal.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/02_traversal.png>) · [03_golden_sky.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/03_golden_sky.png>)

- **Lyra:** [Source](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-thunder-striker/outputs/GoldenSky_NPC_Mobs/Lyra/Lyra_Source.blend>) · [Game](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-thunder-striker/outputs/GoldenSky_NPC_Mobs/Lyra/Lyra_Game.blend>)

- **Kael:** [Source](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-thunder-striker/outputs/GoldenSky_NPC_Mobs/Kael/Kael_Source.blend>) · [Game](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-thunder-striker/outputs/GoldenSky_NPC_Mobs/Kael/Kael_Game.blend>)

- **SkyPirate:** [Source](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-thunder-striker/outputs/GoldenSky_NPC_Mobs/SkyPirate/SkyPirate_Source.blend>) · [Game](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-thunder-striker/outputs/GoldenSky_NPC_Mobs/SkyPirate/SkyPirate_Game.blend>)

- **CorruptedGuard:** [Source](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-thunder-striker/outputs/GoldenSky_NPC_Mobs/CorruptedGuard/CorruptedGuard_Source.blend>) · [Game](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-thunder-striker/outputs/GoldenSky_NPC_Mobs/CorruptedGuard/CorruptedGuard_Game.blend>)

- **LightArcher:** [Source](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-thunder-striker/outputs/GoldenSky_Archer_Knight/LightArcher/LightArcher_Source.blend>) · [Game](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-thunder-striker/outputs/GoldenSky_Archer_Knight/LightArcher/LightArcher_Game.blend>)

- **GoldenKnight:** [Source](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-thunder-striker/outputs/GoldenSky_Archer_Knight/GoldenKnight/GoldenKnight_Source.blend>) · [Game](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-thunder-striker/outputs/GoldenSky_Archer_Knight/GoldenKnight/GoldenKnight_Game.blend>)


## 4. Boss — nguồn hiện hành


### Aureon Sentinel

Concept: [09_aureon.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/09_aureon.png>)

- [Nguồn](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-aureon-sentinel/outputs/AureonSentinel/AureonSentinel_SOURCE.blend>)

- [Showcase](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-aureon-sentinel/outputs/AureonSentinel/GoldenSky_Aureon_SHOWCASE.blend>)

- [Handoff](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-aureon-sentinel/outputs/AureonSentinel/HANDOFF.md>)


**Đối chiếu:** Giáp trắng/vàng, kích thước vai, cánh dạng phiến, vòng halo, mũ kín và kiếm vàng là các dấu hiệu nhận diện chính.


### Cryon Prime

Concept: [10_cryon.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/10_cryon.png>)

- [Nguồn chi tiết](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-aureon-sentinel/outputs/CryonPrime/CryonPrime_SOURCE.blend>)

- [Bản game 1024](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-aureon-sentinel/outputs/CryonPrime_GAME1024/Cryon_GAME_SOURCE.blend>)

- [Trụ triệu hồi](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-aureon-sentinel/outputs/CryonPrime_GAME1024/Cryon_GAME_Pillar_SOURCE.blend>)

- [Handoff](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-aureon-sentinel/outputs/CryonPrime_GAME1024/HANDOFF.md>)


**Đối chiếu:** Kiểm tra khối giáp nặng, các tháp/băng nhọn, lõi ngực hình thoi và tỉ lệ chân tay. Trụ triệu hồi là asset phụ, không tính thêm một nhân vật.


### Noxar

Concept: [11_noxar.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/11_noxar.png>)

- [Nguồn authoring trước bake](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-aureon-sentinel/outputs/Noxar/Noxar_AUTHORING_SOURCE.blend>)

- [Nguồn high-res PBR](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-aureon-sentinel/outputs/Noxar/Noxar_HIGHRES_SOURCE.blend>)

- [Nguồn game có rig](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-aureon-sentinel/outputs/Noxar/GAME/Noxar_GAME_SOURCE.blend>)

- [Nguồn Void FX](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-aureon-sentinel/outputs/Noxar/GAME/Noxar_GAME_VoidFX_SOURCE.blend>)

- [Showcase phase 2](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-aureon-sentinel/outputs/Noxar/Noxar_Phase2_SHOWCASE.blend>)

- [Showcase phase 3](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-aureon-sentinel/outputs/Noxar/Noxar_Phase3_SHOWCASE.blend>)

- [Handoff hiện hành](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-aureon-sentinel/outputs/Noxar/HANDOFF.md>)


**Đối chiếu:** Giữ mũ kín theo lựa chọn đã có của người dùng. So sát mái tóc trắng, halo gãy, vai nhọn, giáp đen nứt đỏ, lõi diamond, xích, cape và kiếm void. Bản giáp chia các băng ngang cũ đã bị loại; không quay về các snapshot rejected trong work/noxar. Bộ hiện hành vẫn chờ duyệt ngoại hình, không coi chữ HIGHRES/GAME là đã đạt chất lượng final.



## 5. Môi trường 3D — nếu cải thiện cả thế giới

Ưu tiên file Editable để sửa, giữ ExportPackage để đối chiếu phần đưa vào engine. Không tự sửa collider hay thay layout gameplay khi chỉ làm mỹ thuật.


- **GoldenSky:** [03_golden_sky.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/03_golden_sky.png>) · [Editable](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-golden-sky/outputs/GoldenSky/SKYBREAK_GoldenSky_Editable.blend>) · [ExportPackage](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-golden-sky/outputs/GoldenSky/SKYBREAK_GoldenSky_ExportPackage.blend>)

- **FrozenCyber:** [04_frozen_cyber.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/04_frozen_cyber.png>) · [Editable](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-golden-sky/outputs/FrozenCyber/FrozenCyber_Editable.blend>) · [ExportPackage](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-golden-sky/outputs/FrozenCyber/FrozenCyber_ExportPackage.blend>)

- **ShadowRealm:** [05_shadow_realm.png](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/references/05_shadow_realm.png>) · [Editable](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-golden-sky/outputs/ShadowRealm/ShadowRealm_Editable.blend>) · [ExportPackage](<C:/Users/khang/Documents/Codex/2026-10-23/skybreak-golden-sky/outputs/ShadowRealm/ShadowRealm_ExportPackage.blend>)


## 6. Ràng buộc sản xuất và tích hợp

1. **Không ghi đè bản nguồn.** Đề xuất thư mục kết quả riêng `C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Argon_Refinement/<AssetName>/`. Lưu Source, Game và render riêng; chưa tự thay file v7/v8.
2. **Giữ rig và chuyển động.** Người chơi/NPC dùng hợp đồng Shared19 ở các bộ được bàn giao; boss có rig riêng. Noxar có 36 xương boss và 7 xương FX, không ép thành Shared19. Đọc Handoff từng asset; bảo toàn tên xương, bind/rest pose, skin weight, action, đơn vị/trục. Nếu buộc đổi, ghi rõ mapping và xuất phép kiểm tra lại animation.
3. **Tìm công cụ/asset trước khi làm thủ công.** Kiểm tra native Curves/Geometry Nodes, bộ tóc/giáp/vật liệu hiện có, add-on và tài sản tái sử dụng. Xem hình thật và giấy phép trước khi nhận asset ngoài. Ghi lại công cụ/asset thực dùng; không mua/cài tùy tiện.
4. **Nguồn đẹp và bản chạy game cần phân biệt.** Giữ groom/procedural chỉnh sửa được trong Source, tạo bản Game có ngân sách hợp lý. Đừng tăng polygon, tệp hoặc lớp mesh trùng chỉ để gọi là chi tiết. Tối ưu phải giữ silhouette, UV, skin và chất liệu nhận diện; render so trước/sau.
5. **Bảo toàn PBR.** BaseColor/Emission dùng sRGB, Normal/Roughness/Metallic dùng Non-Color; kiểm tra alpha, UV và tangent sau FBX roundtrip. Không tự tô trắng toàn model hoặc mất texture rồi coi export thành công.
6. **Kiểm tra trong engine sau bàn giao.** Chạy được Blender/FBX chưa chứng minh chạy được Roblox. Bản v8 trước từng lỗi EditableMesh API, memory allocation và StorageLimitExceeded. Nguồn v8 mới chuyển dựng mesh sang server, texture xem thử tối đa 256 px và Mage dùng tóc LOD1; đây là giới hạn runtime hiện tại, không phải chất lượng texture gốc.
7. **Không tự publish/upload hoặc đổi quyền bảo mật.** Lần bàn giao này chỉ cải thiện 3D và xuất file để chủ dự án duyệt/tích hợp. Không xóa bản cũ, không tác động tài khoản/Studio đang mở ngoài phạm vi.

## 7. Gói bàn giao yêu cầu cho mỗi asset

- `<Asset>_Refined_Source.blend`: model chỉnh sửa được, nguồn tóc/vải/chi tiết còn giữ; pack texture hoặc kèm thư mục đầy đủ.
- `<Asset>_Refined_Game.blend` và `.fbx`: bản đưa vào Roblox, cùng rig/action, có UV và texture đã kiểm tra.
- Render front, side, back, hero và close-up tóc/đầu/giáp/vũ khí; đặt cạnh concept cùng góc/crop gần tương ứng. Không dùng ảnh concept làm mặt phẳng để giả một model hoàn chỉnh.
- Nếu có animation: contact sheet idle/run/attack/jump/dash và các action riêng; kiểm tra giáp xuyên thân, bàn chân, cape/tóc, trục và tỉ lệ.
- `HANDOFF.md`: đường dẫn tuyệt đối, nguồn/giấy phép asset thực dùng, Blender version, số mesh/triangles/bones, danh sách action, map texture, thay đổi đã làm, lỗi còn lại và bằng chứng FBX mở lại.
- Phân biệt **đã dựng**, **đã render**, **đã xuất–nhập kiểm tra**, **đã nhập Roblox**, **đã chạy trong game**, **được người dùng duyệt**. Không gộp các trạng thái này thành “hoàn tất”.

## 8. Trạng thái game để tránh lấy nhầm bản



- [v7 — nền người dùng cho biết vẫn chạy bình thường](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/SKYBREAK_Playable_v7.rbxlx>)

- [v8 — file mới dựng lại từ v7](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/SKYBREAK_Playable_v8.rbxlx>)

- [v8 cũ trước dựng lại — bản sao bảo toàn](<C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Visual_v2/SKYBREAK_Playable_v8_before_v7_rebuild.rbxlx>)


V8 mới đã lưu với tóc Mage LOD1, khoảng 148 MB. Phiên thử trước thay LOD đã vào được game và nạp ba thế giới/NPC/quái; khi thử Mage high-detail vẫn chạm StorageLimitExceeded. **Lần Play cuối sau đổi LOD chưa hoàn tất vì người dùng dừng Computer Use.** Không tự nói bản mới đã qua nghiệm thu hoặc đã public.

Thứ tự cải thiện đề xuất: chọn một nhân vật có concept riêng làm mẫu để duyệt phương pháp, sau đó nhân rộng theo nhóm. Với nữ/NPC không có concept riêng, trình bày rõ phần suy diễn thiết kế. Mọi đánh giá 99% cần sự duyệt thực tế và bằng chứng phù hợp, không suy từ tên file hay báo cáo cũ.
