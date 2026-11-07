# QUY TRÌNH XÓA DỮ LIỆU NGƯỜI DÙNG THEO YÊU CẦU ROBLOX (RIGHT TO ERASURE — P0-06)

> **Căn cứ:** Mục 4 (`P0-06` bước 6) và Quyết định `D3` trong [`PUBLISH_PLAN.md`](../PUBLISH_PLAN.md).  
> **Mục đích:** Đảm bảo tuân thủ chính sách **Right to Erasure (GDPR / CCPA / Roblox Privacy Request)** khi nhận được thông báo xóa dữ liệu người dùng (`UserId`) từ hệ thống tin nhắn của Roblox hoặc Creator Hub.

---

## 1. Danh Mục DataStore & Cấu Trúc Khóa Lưu Trữ Trong SKYBREAK

Toàn bộ dữ liệu người chơi trong **SKYBREAK: Fragments of the Core** được định danh theo `UserId` của Roblox dưới tiền tố khóa `u_<UserId>`:

| Tên DataStore (`StoreName`) | Trạng thái | Định dạng Khóa (`Key`) | Module quản lý | Nội dung lưu trữ |
| :--- | :--- | :--- | :--- | :--- |
| **`SKYBREAK_LIVE_v1`** | **Production (Live)** | `u_<UserId>` *(vd: `u_123456789`)* | `ServerScriptService/Services/PlayerDataService.lua` | Hồ sơ nhân vật chính (`Data`, `Owner`, `Expires`, `SchemaVersion`, Level, Gold, Inventory, Mastery, Quest, Settings). |
| **`SKYBREAK_P0_TEST_v1`** | Legacy / Test | `u_<UserId>` | `PlayerDataService.lua` (trước `P0-06`) | Hồ sơ thử nghiệm giai đoạn phát triển trước khi chuyển sang `SKYBREAK_LIVE_v1`. |
| **`SKYBREAK_TRADE_LOG_v1`** | Dự phòng / Audit (`P1-05`) | `u_<UserId>` | `SkybreakCombatExpansion.lua` | Nhật ký giao dịch vật phẩm của người chơi (nếu có). |
| **`SKYBREAK_ADMIN_BANS_v1`** | Quản trị (`P2-04`) | `u_<UserId>` | `ServerScriptService` | Trạng thái kỷ luật / khóa tài khoản nội bộ (nếu có). |

---

## 2. Quy Trình Xử Lý Khi Nhận Yêu Cầu Right-to-Erasure

Khi nhận được thông báo **Right to Erasure Request** từ Roblox (thường liệt kê một hoặc nhiều `UserId` và `PlaceId` / `UniverseId`):

1. **Bước 1 — Chuẩn bị môi trường:**
   - Mở file Place đã liên kết với Universe chính thức trên **Roblox Studio**.
   - Đảm bảo **Game Settings → Security → Enable Studio Access to API Services** đang bật (`ON`).
2. **Bước 2 — Thực thi xóa dữ liệu qua Studio Command Bar:**
   - Sao chép đoạn script Luau ở **Mục 3** bên dưới vào **Command Bar** của Roblox Studio.
   - Thay danh sách `TARGET_USER_IDS` bằng các `UserId` trong thông báo của Roblox và nhấn **Enter**.
3. **Bước 3 — Kiểm tra xác nhận (`Verification`):**
   - Quan sát cửa sổ **Output** đảm bảo tất cả các Store đều in ra `[ERASURE PASS] Verified nil for u_<UserId>`.
4. **Bước 4 — Lưu nhật ký tuân thủ:**
   - Ghi lại ngày thực hiện và mã `UserId` đã xóa (không lưu tên hay thông tin cá nhân của người dùng) để đối chiếu khi cần.

---

## 3. Script Luau Chạy Trong Roblox Studio Command Bar

Dán đoạn mã sau vào **Studio Command Bar** (chỉ cần thay mảng `TARGET_USER_IDS`):

```lua
-- ============================================================================
-- SKYBREAK — RIGHT TO ERASURE (GDPR / CCPA) DATA DELETION SCRIPT (P0-06)
-- Chạy trực tiếp trong Roblox Studio Command Bar (yêu cầu bật API Services)
-- ============================================================================
local DataStoreService = game:GetService("DataStoreService")

-- 1. Nhập danh sách UserId cần xóa từ thông báo của Roblox:
local TARGET_USER_IDS = {
	123456789, -- Thay bằng UserId thật trong yêu cầu Right-to-Erasure
}

-- 2. Danh sách toàn bộ DataStore cần quét xóa (Live + Legacy Test + Logs):
local STORE_NAMES = {
	"SKYBREAK_LIVE_v1",
	"SKYBREAK_P0_TEST_v1",
	"SKYBREAK_TRADE_LOG_v1",
	"SKYBREAK_ADMIN_BANS_v1",
}

local PURGE_ALL_HISTORICAL_VERSIONS = true

for _, rawId in ipairs(TARGET_USER_IDS) do
	local userId = tonumber(rawId)
	assert(userId and userId > 0, "Invalid UserId: " .. tostring(rawId))
	local key = "u_" .. tostring(userId)
	print(string.format("=== [SKYBREAK ERASURE] Bắt đầu xóa dữ liệu cho UserId=%d (Key=%s) ===", userId, key))

	for _, storeName in ipairs(STORE_NAMES) do
		local okStore, store = pcall(function()
			return DataStoreService:GetDataStore(storeName)
		end)
		if not okStore or not store then
			warn(string.format("[ERASURE WARN] Không mở được DataStore '%s': %s", storeName, tostring(store)))
			continue
		end

		-- Bước A: Xóa bản ghi hiện hành bằng RemoveAsync
		local okRemove, removedVal = pcall(function()
			return store:RemoveAsync(key)
		end)
		if okRemove then
			print(string.format("[ERASURE] %s -> RemoveAsync('%s') thành công (đã có dữ liệu: %s)", storeName, key, tostring(removedVal ~= nil)))
		else
			warn(string.format("[ERASURE ERROR] %s -> RemoveAsync('%s') lỗi: %s", storeName, key, tostring(removedVal)))
		end

		-- Bước B: Xóa các phiên bản lịch sử (Version History) trong 30 ngày nếu có
		if PURGE_ALL_HISTORICAL_VERSIONS then
			local okPages, pages = pcall(function()
				return store:ListVersionsAsync(key, Enum.SortDirection.Descending)
			end)
			if okPages and pages then
				while true do
					local items = pages:GetCurrentPage()
					for _, info in ipairs(items) do
						if not info.IsDeleted then
							pcall(function()
								store:RemoveVersionAsync(key, info.Version)
							end)
						end
					end
					if pages.IsFinished then
						break
					end
					local okNext = pcall(function()
						pages:AdvanceToNextPageAsync()
					end)
					if not okNext then
						break
					end
				end
			end
		end

		-- Bước C: Kiểm chứng lại bằng GetAsync (bắt buộc trả về nil)
		local okVerify, verifyVal = pcall(function()
			return store:GetAsync(key)
		end)
		if okVerify and verifyVal == nil then
			print(string.format("[ERASURE PASS] Verified nil in '%s' for key '%s'", storeName, key))
		else
			warn(string.format("[ERASURE FAIL] '%s' key '%s' vẫn còn dữ liệu hoặc lỗi kiểm chứng: %s", storeName, key, tostring(verifyVal)))
		end
	end

	print(string.format("=== [SKYBREAK ERASURE] Hoàn tất xử lý UserId=%d ===", userId))
end
```

---

## 4. Phương Án Thay Thế: Xóa Tự Động Qua Roblox Open Cloud API (PowerShell)

Trong trường hợp không mở Roblox Studio, chủ tài khoản có thể sử dụng **Open Cloud DataStore API v1** với API Key có quyền `universe-datastores.objects:delete` và `universe-datastores.objects:read`:

```powershell
$UniverseId = "<YOUR_UNIVERSE_ID>"
$ApiKey     = $env:ROBLOX_OPEN_CLOUD_API_KEY
$UserId     = "123456789"
$EntryKey   = "u_$UserId"

foreach ($StoreName in @("SKYBREAK_LIVE_v1", "SKYBREAK_P0_TEST_v1")) {
    $Uri = "https://apis.roblox.com/datastores/v1/universes/$UniverseId/standard-datastores/datastore/entries/entry?datastoreName=$StoreName&entryKey=$EntryKey"
    try {
        Invoke-RestMethod -Method Delete -Uri $Uri -Headers @{ "x-api-key" = $ApiKey }
        Write-Host "[ERASURE PASS] Deleted $EntryKey from $StoreName"
    } catch {
        Write-Host "[ERASURE INFO] $StoreName ($EntryKey): $($_.Exception.Message)"
    }
}
```

---

## 5. Tiêu Chí Nghiệm Thu (`Verification Checklist`)

- [ ] `store:GetAsync("u_" .. userId)` trả về `nil` trên cả `SKYBREAK_LIVE_v1` và `SKYBREAK_P0_TEST_v1`.
- [ ] Nếu người chơi đang trực tuyến tại thời điểm xóa, phiên của họ đã bị ngắt kết nối (`Kick`) trước khi gọi `RemoveAsync` để tránh `BindToClose` / `Autosave` ghi đè lại hồ sơ vào DataStore.
