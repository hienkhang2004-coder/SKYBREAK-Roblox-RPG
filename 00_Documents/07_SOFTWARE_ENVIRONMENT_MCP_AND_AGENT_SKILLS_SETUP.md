# TẬP 07 — TÀI LIỆU CÀI ĐẶT PHẦN MỀM, MÔI TRƯỜNG KỸ THUẬT, MCP SERVERS & AI AGENT SKILLS
## Dự án: **SKYBREAK: Fragments of the Core** (`v12 PremiumUI • Macro-World 27× / 9× Edition`)

- **Mã tài liệu**: `00_Documents/07_SOFTWARE_ENVIRONMENT_MCP_AND_AGENT_SKILLS_SETUP.md`
- **Đối tượng sử dụng**: IT / DevOps Onboarding, Lập trình viên Luau/Roblox, Technical Artists (Blender 3D), và Kỹ sư vận hành AI Coding Agents (Antigravity / Codex / Cursor / Claude Code) của đơn vị tiếp nhận dự án.
- **Script kiểm tra tự động đi kèm**: [check_workstation_setup.py](file:///C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Antigravity_Handoff/05_Pipeline_Tools_27x_9x/check_workstation_setup.py)

---

## 1. Yêu Cầu Phần Cứng Máy Trạm (Recommended Workstation Specs)

Do dự án vận hành đồng thời file Roblox Place chứa **94 gói tài nguyên 3D nén** (`~292.6 MB` `.rbxlx`) cùng **13 đại cảnh Blender `27× / 9×`** xuất ngầm qua `EditableMesh`, cấu hình máy trạm cho kỹ sư phát triển cần đáp ứng:

| Thành phần | Cấu hình Tối thiểu | Cấu hình Khuyến nghị (Production) | Lý do kỹ thuật |
| :--- | :--- | :--- | :--- |
| **Hệ điều hành** | Windows 10/11 64-bit | **Windows 11 Pro 64-bit** *(hoặc macOS Sonoma+)* | [run_blender_safe.py](file:///C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Argon_Refinement/run_blender_safe.py) dùng Windows Named Mutex `kernel32.CreateMutexW` để xếp hàng Blender an toàn |
| **RAM** | `16 GB` | **`32 GB – 64 GB`** | Mở đồng thời Roblox Studio (`~4–6 GB` RAM khi dựng 20 vùng `EditableMesh`) + Blender 5.2 headless (`~3–5 GB`) |
| **GPU** | GTX 1660 / RTX 2060 (`6 GB` VRAM) | **`NVIDIA RTX 3060 / 4070+ (8–12 GB VRAM)`** | Render preview Cycles/EEVEE OptiX và giữ `60 FPS` khi test đại cảnh `27×` (`16,500` studs) |
| **Lưu trữ (SSD)** | `25 GB` trống (NVMe SSD) | **`50 GB+` trống (PCIe Gen4 NVMe)** | Đọc/ghi nhanh file `.rbxlx` `306.8 MB`, `52+` file `.blend` và bộ đệm `runtime_v8` |

---

## 2. Danh Mục Toàn Bộ Phần Mềm & Công Cụ Cần Cài Đặt (Required Software Stack)

### 2.1. Bảng Tổng Hợp Phần Mềm Cốt Lõi & Bổ Trợ

| STT | Phần mềm / Runtime | Phiên bản chuẩn trên máy gốc | Mức độ | Vai trò trong dự án SKYBREAK |
| :---: | :--- | :---: | :---: | :--- |
| 1 | **Roblox Studio** | Bản mới nhất (`2026+`) | **Bắt buộc** | Mở, chạy thử (Play F5), debug và Publish file [SKYBREAK_Playable_v12_PremiumUI.rbxlx](file:///C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Antigravity_Handoff/04_Roblox/SKYBREAK_Playable_v12_PremiumUI.rbxlx) |
| 2 | **Blender** | **`5.2.2 LTS`** *(tương thích `4.2 LTS+`)* | **Bắt buộc** | Chỉnh sửa 13 thế giới `27× / 9×`, 81 rig nhân vật/Boss/vũ khí/tàu và chạy script xuất mesh V8 + trích xuất Collider vật lý |
| 3 | **Python (Độc lập)** | **`Python 3.12.x / 3.13.x`** (`64-bit`) | **Bắt buộc** | Chạy bộ công cụ đóng gói `.rbxlx` và kiểm định tự động trong [05_Pipeline_Tools_27x_9x](file:///C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Antigravity_Handoff/05_Pipeline_Tools_27x_9x) |
| 4 | **Thư viện Python (`pip`)** | `zstandard==0.25.0`, `numpy>=2.3`, `Pillow>=11.0`, `requests>=2.32` | **Bắt buộc** | Nén/giải nén luồng mesh `Zstd + Base64` (`.json.zstd.b64`), tính toán hình học OBB/KD-tree và xử lý texture PBR |
| 5 | **Git & Git LFS** | `Git 2.56+` & **`Git LFS 3.8+`** | **Bắt buộc** | Quản lý phiên bản mã nguồn LF chuẩn và lưu trữ nhị phân lớn (`*.rbxlx`, `*.blend`, `*.wav`, `*.png`) theo [.gitattributes](file:///C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Antigravity_Handoff/.gitattributes) |
| 6 | **Node.js LTS (`npm` / `npx`)** | **`v22.14.0+`** *(tối thiểu `v20 LTS`)* | **Bắt buộc (AI/MCP)** | Cài đặt AI Agent Skills qua `npx skills add ...` và chạy các trình cầu nối MCP Server (`stdio`) |
| 7 | **AI Agent IDE / CLI** | **Google Antigravity** / **Codex** / Cursor / Claude Code | **Khuyến nghị cao** | Đọc tự động `AGENTS.md`, kích hoạt `.agents/skills/` và điều khiển trực tiếp Roblox Studio qua MCP |
| 8 | **Rojo (`v7.4+`) hoặc Argon (`v2+`)** | Theo chuẩn hệ sinh thái Luau | *Tùy chọn* | Đồng bộ live-sync mã nguồn Luau nếu đội ngũ muốn làm việc qua `SKYBREAK_Visual_v2/default.project.json` thay vì đóng gói `.rbxlx` trực tiếp |
| 9 | **StyLua & Selene** | `StyLua 2.x` • `Selene 0.27+` | *Tùy chọn* | Định dạng code (formatter) và kiểm tra lỗi tĩnh (static linter) cho `123` file Luau trong CI/CD |
| 10 | **Adobe Photoshop** | `Photoshop 2025 / 2026` | *Tùy chọn (Art/UI)* | Tinh chỉnh texture atlas, concept art, icon UI và kết nối với `Photoshop` MCP Server |
| 11 | **FFmpeg / Audacity / Reaper** | `FFmpeg 7.x+` | *Tùy chọn (Audio)* | Xử lý, chuẩn hóa âm lượng LUFS và xuất các tệp âm thanh `.wav` 44.1kHz Stereo trong `07_Audio_SFX/` |

---

### 2.2. Hướng Dẫn Cài Đặt & Cấu Hình Từng Phần Mềm Chi Tiết

#### Bước A — Cấu hình Roblox Studio (Bắt buộc trước khi nhấn Play)
1. Cài đặt và đăng nhập **Roblox Studio** từ trang chính thức của Roblox Creator Hub.
2. Mở **File → Beta Features** (hoặc **Game Settings → Security** khi đã lưu lên Group):
   - Bật **`EditableMesh and EditableImage`** *(nếu tắt, `DelegatedV5Renderer.lua` sẽ không được phép gọi `AssetService:CreateEditableMesh()` để dựng 94 mô hình 3D!)*.
   - Khi test lưu dữ liệu Cloud thực tế: bật **`Enable Studio Access to API Services`** (ở chế độ mặc định chưa publish, `PlayerDataService.lua` tự động dùng `StudioSessionCache` nên vẫn chơi thử mượt mà không báo lỗi).
3. Khởi động lại Roblox Studio một lần sau khi bật Beta Features.

#### Bước B — Cài đặt Blender `5.2.2 LTS` & Các Gói Python Nhúng Trong Blender
> [!IMPORTANT]
> Blender sử dụng **môi trường Python nhúng riêng biệt** bên trong thư mục cài đặt của nó (`5.2\python\bin\python.exe`), hoàn toàn tách biệt với Python của Windows! Trình xuất thế giới [export_all_13_worlds_27x_9x_v8.py](file:///C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Argon_Refinement/export_all_13_worlds_27x_9x_v8.py) chạy bên trong tiến trình Blender nên **bắt buộc phải cài `zstandard`, `numpy`, `Pillow` vào đúng Python nhúng của Blender**.

1. Cài đặt **Blender 5.2 LTS** tại đường dẫn mặc định `C:\Program Files\Blender Foundation\Blender 5.2\blender.exe` *(nếu cài ở ổ đĩa khác, cập nhật hằng số `BLENDER_EXE` tại dòng 14 của [run_blender_safe.py](file:///C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Argon_Refinement/run_blender_safe.py))*.
2. Mở **PowerShell (Run as Administrator)** và chạy lệnh cài thư viện vào Python nhúng của Blender:
   ```powershell
   $blenderPy = "C:\Program Files\Blender Foundation\Blender 5.2\5.2\python\bin\python.exe"
   & $blenderPy -m ensurepip --upgrade
   & $blenderPy -m pip install --upgrade pip
   & $blenderPy -m pip install "zstandard==0.25.0" "numpy>=2.3.0" "Pillow>=11.0.0" "requests>=2.32.0"
   ```
3. Các Add-on có sẵn của Blender cần giữ ở trạng thái **Enabled** trong *Edit → Preferences → Add-ons*:
   - `Import-Export: FBX format` (`io_scene_fbx`)
   - `Import-Export: glTF 2.0 format` (`io_scene_gltf2`)
   - `Node: Node Wrangler` (`node_wrangler`)

#### Bước C — Cài đặt Standalone Python `3.12+` Cho Bộ Công Cụ Đóng Gói & Kiểm Định
1. Cài đặt **Python 3.12 hoặc 3.13 (64-bit)** (tích chọn *Add python.exe to PATH*).
2. Cài đặt cùng bộ thư viện để mọi script kiểm định, giải mã thử `.zstd.b64` hoặc upload Open Cloud đều chạy được từ terminal:
   ```powershell
   python -m pip install --upgrade pip
   python -m pip install "zstandard==0.25.0" "numpy>=2.3.0" "Pillow>=11.0.0" "requests>=2.32.0"
   ```

#### Bước D — Cài đặt Git, Git LFS & Node.js LTS
```powershell
# Cài nhanh qua Windows Package Manager (winget)
winget install --id Git.Git -e --source winget
winget install --id GitHub.GitLFS -e --source winget
winget install --id OpenJS.NodeJS.LTS -e --source winget

# Kích hoạt Git LFS trong kho mã nguồn trước khi commit/push lên Git nội bộ của công ty
git lfs install
```

---

## 3. Cài Đặt & Kết Nối Các MCP Servers (Model Context Protocol)

Khi phát triển bằng AI Coding Agent (**Google Antigravity**, **Codex**, **Cursor**, **Claude Code**), dự án tận dụng **2 MCP Servers** giúp Agent nhìn thấy cây `DataModel`, chạy lệnh Luau trực tiếp trong phiên Play của Roblox Studio, chụp màn hình viewport để tự nghiệm thu thị giác và xử lý texture tự động:

### 3.1. `Roblox_Studio` MCP Server *(Quan trọng nhất — 34 Live Studio Tools)*
- **Chức năng**: Kết nối hai chiều giữa AI Agent và cửa sổ Roblox Studio đang mở thông qua plugin **Studio MCP Proxy**. Cung cấp 34 công cụ trực tiếp:
  - *Đọc & Sửa cây Game*: `search_game_tree`, `inspect_instance`, `script_read`, `script_search`, `script_grep`, `multi_edit`.
  - *Chạy thử & Kiểm định tự động*: `start_stop_play`, `execute_luau` (chạy trực tiếp `SkybreakSmokeTest.RunAll()`), `get_console_output`, `get_studio_state`, `screen_capture`.
  - *Tạo tài nguyên & Điều hướng*: `character_navigation`, `user_keyboard_input`, `user_mouse_input`, `insert_asset`, `generate_mesh`, `generate_material`, `generate_texture`.
- **Cách cài đặt**:
  1. Cài đặt **Roblox Studio MCP Plugin / Studio MCP Proxy** chính thức từ Roblox Creator Store hoặc bật tích hợp MCP trong Roblox Studio (*Plugins → MCP Proxy / Studio Assistant MCP*).
  2. Khai báo server `Roblox_Studio` trong tệp cấu hình MCP của Agent:
     - Trên **Google Antigravity**: `~/.gemini/config/mcp_config.json` (hoặc bật trực tiếp trong menu **Additional Options (`...`) → MCP Servers**).
     - Trên **Cursor / Claude Desktop / Codex**: thêm vào `mcp.json` / `config.toml` tương ứng.

### 3.2. `Photoshop` MCP Server *(Tùy chọn cho đội UI & Technical Art)*
- **Chức năng**: Điều khiển trực tiếp Adobe Photoshop để tạo texture PBR, tách nền icon vũ khí/trái ác quỷ, chỉnh màu LUT/Curves và xuất hàng loạt tài nguyên UI (`photoshop_create_document`, `photoshop_apply_gaussian_blur`, `photoshop_adjust_curves`, `photoshop_export_as`, `photoshop_recipe_prepare_for_web`...).
- **Cách cài đặt**: Bật plugin **Adobe Photoshop MCP** trong bảng *Plugins Manager / MCP Servers* của Antigravity khi máy trạm đã cài Adobe Photoshop.

### 3.3. Mẫu Cấu Hình `~/.gemini/config/mcp_config.json` Tham Khảo
```json
{
  "mcpServers": {
    "Roblox_Studio": {
      "command": "rbx-studio-mcp",
      "args": ["--stdio"]
    }
  }
}
```
*(Lưu ý: Nếu dùng bản cài đặt tích hợp qua giao diện Plugins/MCP của Antigravity hoặc Roblox Studio Installer mới nhất, đường dẫn binary `rbx-studio-mcp` sẽ được tự động đăng ký mà không cần gõ tay).*

---

## 4. Danh Mục Toàn Bộ AI Agent Skills Cần Cài Đặt (Skills Architecture)

Hệ thống AI Agent sử dụng cơ chế **Progressive Disclosure Skills** (`SKILL.md` có YAML frontmatter `name` & `description`): Agent chỉ nạp phần mô tả ngắn vào bộ nhớ và tự động mở toàn bộ sổ tay quy trình khi gặp đúng tác vụ chuyên môn.

Các Agent hiện đại tự động quét Skills theo thứ tự ưu tiên sau:
1. **Project-Local Skills (Trong kho mã nguồn — tự động chia sẻ cho mọi thành viên)**:
   `SKYBREAK_Antigravity_Handoff/.agents/skills/<skill-name>/SKILL.md` cùng tệp quy tắc gốc [AGENTS.md](file:///C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Antigravity_Handoff/AGENTS.md).
2. **Global Multi-Agent Skills (Trên từng máy trạm cá nhân)**:
   - `~/.agents/skills/<skill-name>/SKILL.md` *(tương thích đồng thời Antigravity, Antigravity CLI, Codex, Cursor, Claude Code, GitHub Copilot, Cline, Windsurf/Zed)*.
   - `~/.codex/skills/<skill-name>/SKILL.md` *(thư mục chuyên biệt của Codex)*.
   - `~/.gemini/config/skills/<skill-name>/SKILL.md` *(thư mục global của Antigravity)*.

---

### 4.1. Nhóm A — 3 Skills Đặc Thù Của Dự Án SKYBREAK *(Đã Đóng Gói Sẵn Trong `.agents/skills/`!)*

Đơn vị tiếp nhận **không cần cài tay** nhóm này: chúng đã được đóng gói trực tiếp vào thư mục `.agents/skills/` ngay trong gói bàn giao để bất kỳ AI Agent nào mở workspace cũng tự động hiểu rõ kiến trúc SKYBREAK:

| Tên Skill | Đường dẫn trong Repo | Khi nào AI Agent tự động kích hoạt |
| :--- | :--- | :--- |
| **`skybreak-rbxlx-build-and-qa`** | [SKILL.md](file:///C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Antigravity_Handoff/.agents/skills/skybreak-rbxlx-build-and-qa/SKILL.md) | Khi sửa bất kỳ file Luau nào trong `04_Roblox/src`, đóng gói `.rbxlx`, kiểm tra trần `< 199,000 B`, đồng bộ 3 cặp file mirror hoặc chạy kiểm định `verify_27x_9x_game_sync.py` & `SkybreakSmokeTest`. |
| **`skybreak-blender-27x-9x-world-pipeline`** | [SKILL.md](file:///C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Antigravity_Handoff/.agents/skills/skybreak-blender-27x-9x-world-pipeline/SKILL.md) | Khi chỉnh sửa hoặc xuất lại bất kỳ thế giới Blender `27× / 9×` nào (`W1..W13`), chạy `run_blender_safe.py`, chia lưới KD-tree `<= 1,748 < 2,048` studs hoặc sinh 4 module Collider OBB. |
| **`skybreak-3d-rig-and-virtualsplit`** | [SKILL.md](file:///C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Antigravity_Handoff/.agents/skills/skybreak-3d-rig-and-virtualsplit/SKILL.md) | Khi thêm nhân vật mới theo rig `Shared19` (19 xương), thêm Boss/Rồng/Trái Ác Quỷ 3D có 8 clip 12-Keyframe, hoặc tách model từ gói gộp qua `VirtualSplitSpecs` trong `DelegatedV5Renderer.lua`. |

---

### 4.2. Nhóm B — Bộ 10 Skills Sản Xuất Blender 3D Cốt Lõi *(Cần Cài Cho Máy Technical Art / 3D AI)*

Đây là bộ 10 kỹ năng nền tảng đã được sử dụng trên máy phát triển gốc (`~/.codex/skills/` hoặc `~/.agents/skills/`) để dựng hình, gán vật liệu PBR, đặt ánh sáng, diễn hoạt F-curve và kết xuất preview cho 13 thế giới và 81 mô hình nhân vật/Boss:

| STT | Định danh Skill (`name`) | Chức năng chuyên môn |
| :---: | :--- | :--- |
| 1 | `blender-pro-workflow` | Quy trình chuẩn lắp ráp cảnh 3D từ đầu đến cuối (`block-out → camera → light → forms → materials → detail → render`). |
| 2 | `blender-modeling` | Dựng hình hard-surface & địa hình đảo bay, quản lý stack Modifier (`Bevel`, `Subdivision`, `Boolean`, `Mirror`, `Array`) sạch topology. |
| 3 | `blender-materials` | Thiết lập vật liệu PBR `Principled BSDF` (kim loại vàng Aureon, băng phát sáng Cryon, đá Hư Không Noxar, kính, vải, da) tương thích xuất sang Roblox. |
| 4 | `blender-uv-texturing` | Trải UV unwrap, ánh xạ texture atlas, decal alpha và bake bản đồ màu/ánh sáng cho mô hình game. |
| 5 | `blender-lighting` | Bố trí ánh sáng 3 điểm, môi trường bầu trời/HDRI, nhiệt độ màu và phân nhóm đèn chiếu sáng đại cảnh. |
| 6 | `blender-cameras` | Thiết lập tiêu cự, góc máy điện ảnh (hero overview, monument closeup, elevation profile), độ sâu trường ảnh (DOF) và bố cục 1/3. |
| 7 | `blender-animation` | Diễn hoạt xương Armature, F-curves, nội suy `Bezier AUTO_CLAMPED`, chu kỳ lặp 12-Keyframe (`Idle`, `Walk`, `Run`, `Attack`, `UltimateAwakening`). |
| 8 | `blender-rendering` | Tối ưu thông số kết xuất Cycles (OptiX/OIDN denoising) và EEVEE cho bảng tổng hợp nghiệm thu mỹ thuật. |
| 9 | `blender-export` | Quy chuẩn xuất dữ liệu cảnh Blender sang FBX / glTF / định dạng game engine đúng tỷ lệ trục và pháp tuyến. |
| 10 | `blender-skill-harmonizer` | Điều phối thứ tự ưu tiên và cổng kiểm tra chất lượng khi kích hoạt nhiều skill Blender cùng lúc. |

---

### 4.3. Nhóm C — Bộ 20 Skills Dựng Hình Từ Concept Art (`Reference-to-3D`) & Kiểm Định Chất Lượng 3D

Bộ kỹ năng chuyên sâu dùng để bám sát 17 bức tranh Concept Art gốc trong `02_Concept_Art/` và kiểm soát chất lượng hoạt ảnh/UV không bị lỗi:

| Nhóm con | Các Skill cần cài đặt | Mục đích sử dụng thực tế trong SKYBREAK |
| :--- | :--- | :--- |
| **Chuyển đổi Concept / Wireframe → 3D** | `reference-to-3d`, `text-to-blender`, `wireframe-to-3d`, `contour-to-mesh`, `mascot-logo-reconstruction`, `source-part-segmentation` | Phân tách các lớp giáp, tóc, áo choàng, vũ khí từ tranh concept 2D và tái tạo khối 3D có cấu trúc rõ ràng. |
| **Căn chỉnh Tỉ lệ Đa góc nhìn (Multiview Fit)** | `orthographic-registration`, `multiview-constraint-solver`, `multiview-fit-loop`, `landmark-fit-repair`, `fit-repair-optimizer` | Khóa tỉ lệ silhouette mặt trước / ngang / sau / trên của nhân vật (`SkyGuardian`, `ThunderStriker`, `ArcaneMage`) và Boss (`Aureon`, `Cryon`, `Noxar`). |
| **Khớp UV, Vật liệu & Hiệu ứng Vòng Hào Quang** | `atlas-uv-fitting`, `texture-driven-mesh-fitting`, `closed-surface-uv-coverage`, `texture-state-animation`, `orbital-hud-motion` | Đảm bảo UV phủ kín các mặt cắt khối đùn và tạo hiệu ứng vòng nguyên tố 3D (`Elem3D_*_AuraRibbon`, `CrownSwirl`) xoay mượt quanh nhân vật/đảo. |
| **Cổng Kiểm Định Tự Động (Quality Gates)** | `reference-analysis-validator`, `reference-look-calibration`, `animation-quality-gate`, `quality-refinement-autoloop` | Tự động render contact-sheet đa khung hình để phát hiện lỗi xuyên giáp/tóc, nhấp nháy silhouette hoặc sai lệch ánh sáng trước khi đóng gói vào game. |

---

### 4.4. Nhóm D — Các Skills Quy Trình, Kiến Trúc Không Gian & Built-in Skills

1. **Khám phá & Cài đặt Skill công cộng (`find-skills`)** — cài trực tiếp qua `npx`:
   ```powershell
   npx -y skills add vercel-labs/skills --skill find-skills -g -y
   ```
2. **Quy trình Phỏng vấn Chốt Thiết Kế & Quy hoạch Tổng mặt bằng Đảo**:
   - `grill-me`: Phỏng vấn làm rõ từng quyết định thiết kế gameplay/UI với Product Owner trước khi code tính năng lớn.
   - `architecture-site-analysis`, `architecture-research`, `architecture-board-composition`, `architecture-pinup-review`: Dùng khi thiết kế quy hoạch mặt bằng đại cảnh quần đảo mới (phân khu quảng trường, trục đại lộ, cầu nối, cao độ địa hình `elevation profile`).
3. **Các Built-in Skills có sẵn trên Google Antigravity** *(tự động kích hoạt, không cần cài thêm)*:
   - `agy-customizations`, `antigravity-guide`, `automation`, `plugin`, `migrate-workflows`, `ui-plugin-navigation`.

### 4.5. Hướng Dẫn Chuyển Giao Gói Skills Giữa Hai Công Ty
- **Đối với 3 Skills đặc thù của dự án (Nhóm A)**: Đã nằm sẵn trong `SKYBREAK_Antigravity_Handoff/.agents/skills/` — tự động hoạt động ngay khi giải nén repo.
- **Đối với các Skills công cộng (`find-skills`, Remotion, Blender skills trên GitHub)**: Dùng công cụ chuẩn `npx skills add <owner/repo> -g` (sẽ tự động cài vào `~/.agents/skills/` cho cả Antigravity, Codex, Cursor và Claude Code).
- **Đối với bộ Skills nội bộ tùy biến trên máy gốc (`~/.codex/skills/`)**: Nếu bàn giao kèm bộ công cụ AI nội bộ theo thỏa thuận chuyển giao công nghệ, chỉ cần sao chép các thư mục con chứa `SKILL.md` vào `C:\Users\<TenUserMoi>\.agents\skills\` (hoặc `.codex\skills\`) trên máy trạm của đối tác.

---

## 5. Kiểm Tra Nghiệm Thu Toàn Bộ Môi Trường Bằng 1 Lệnh Duy Nhất

Sau khi cài đặt xong phần mềm và giải nén dự án trên máy trạm của công ty mới, hãy mở PowerShell tại thư mục `SKYBREAK_Antigravity_Handoff` và chạy trình chẩn đoán tự động [check_workstation_setup.py](file:///C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Antigravity_Handoff/05_Pipeline_Tools_27x_9x/check_workstation_setup.py):

```powershell
python 05_Pipeline_Tools_27x_9x/check_workstation_setup.py
```

Script này sẽ tự động kiểm tra và in báo cáo `[OK]` / `[WARN]` / `[MISSING]` kèm lệnh khắc phục cụ thể cho:
1. Phiên bản Standalone Python (`>= 3.11`) và các thư viện `zstandard`, `numpy`, `Pillow`, `requests`.
2. Sự hiện diện của **Blender 5.2+** và thư viện `zstandard` bên trong **Python nhúng của Blender**.
3. Sự hiện diện của **Roblox Studio** trên hệ điều hành.
4. Phiên bản **Git**, **Git LFS** và **Node.js / npx**.
5. Sự toàn vẹn của **3 Project-Local Skills** trong `.agents/skills/`, tệp `AGENTS.md`, cấu hình MCP và các thư mục Global Skills (`~/.agents/skills`, `~/.codex/skills`).
