"""Runs static contract assertions and (when Luau CLI is available) Luau unit tests against the canonical Hạng Mục sources."""
from pathlib import Path
import os
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "src"
CATS = (
    "01_HangMuc1_Server_Combat_World",
    "02_HangMuc2_UI_Shop_Config",
    "03_HangMuc3_3D_VuKhi_Giap_VFX",
)


def resolve_luau_path(rel_path: str) -> Path:
    """Resolve a relative Luau path across the 3 canonical Hạng Mục folders first, falling back to 04_Roblox/src/."""
    rel = Path(rel_path)
    for cat in CATS:
        candidate = ROOT / cat / rel
        if candidate.exists():
            return candidate
    fallback = SRC / rel
    if fallback.exists():
        return fallback
    raise FileNotFoundError(f"Cannot resolve Luau file '{rel_path}' in {CATS} or src/")


def iter_canonical_luau_files():
    """Yield (relative_posix_path_from_cat, Path) across all 3 canonical Hạng Mục folders."""
    seen = set()
    found = False
    for cat in CATS:
        cat_dir = ROOT / cat
        if not cat_dir.exists():
            continue
        found = True
        for p in sorted(cat_dir.rglob("*.lua")):
            rel = p.relative_to(cat_dir).as_posix()
            seen.add((cat, rel))
            yield f"{cat}/{rel}", p
    if not found and SRC.exists():
        for p in sorted(SRC.rglob("*.lua")):
            rel = p.relative_to(SRC).as_posix()
            yield f"src/{rel}", p


def strip_luau_line_comments(text: str) -> str:
    """Strip single-line Luau comments for code contract checks."""
    out = []
    for line in text.splitlines():
        stripped = line.lstrip()
        if stripped.startswith("--"):
            continue
        code_part = re.sub(r"--.*$", "", line)
        out.append(code_part)
    return "\n".join(out)


def slice_between(text: str, start: str, end: str) -> str:
    i = text.index(start)
    j = text.index(end, i)
    return text[i:j]


BEHAVIOR_HARNESS = r"""
local now = 1000
local unixNow = 1800000000
local os = { clock = function() return now end, time = function() return unixNow end }
local isStudio = false
local storeValue = nil
local storeCalls = 0
local fakeStore = {
    UpdateAsync = function(_, key, fn)
        storeCalls += 1
        local nv = fn(storeValue)
        if nv ~= nil then storeValue = nv end
        return nv
    end,
    GetAsync = function(_, key) return storeValue end,
}
local game = {
    GetService = function(_, name)
        if name == "RunService" then return { IsStudio = function() return isStudio end } end
        if name == "DataStoreService" then return { GetDataStore = function() return fakeStore end } end
        return {}
    end,
}
local task = { spawn = function() end }
local Color3 = { new = function(...) return { ... } end, fromRGB = function(...) return { ... } end, fromHex = function(...) return { ... } end }
local Vector3 = { new = function(...) return { ... } end }
local ColorSequence = { new = function(...) return { ... } end }
local NumberSequence = { new = function(...) return { ... } end }

local CombatData = (function()
--@@COMBATDATA@@
end)()

local profiles, notes = {}, {}
local D = { Get = function(p) return profiles[p] end, Save = function() end }
local G = { Runtime = {}, Notify = function(p, msg) notes[#notes + 1] = msg end, Sync = function() end, Equipment = function() end }
local C = { Items = { MatOre = { Name = "Ore", Slot = "Material" } } }
local ArsenalExpansionConfig = {
    Items = {
        BasicBlade = { Name = "Basic Blade", Slot = "Weapon" },
        EliteBlade = { Name = "Elite Blade", Slot = "Weapon" },
        MatOre = { Name = "Ore", Category = "Materials" },
    },
    VendorCatalogs = {
        SwordDealer = {
            { ItemId = "BasicBlade", PriceGold = 1000, LevelReq = 1 },
            { ItemId = "EliteBlade", PriceGold = 5000, LevelReq = 500 },
        },
        ArmorAndRelicVendor = { { ItemId = "MatOre", PriceGold = 100 } },
        ShipwrightFleet = {},
        MartialDojoStyles = {},
    },
}
local RarityConfig = { Items = {} }
local VendorService = { HandleEquipItem = function() end, SyncCharacterArmorAttributes = function() end }
local Services = { FindFirstChild = function() return nil end }

--@@VENDOR@@

local function newPlayer(level, gold)
    local p = { UserId = #notes + math.random(1, 1e6) }
    profiles[p] = { Level = level, Gold = gold, CoreShards = 0, Inventory = {}, Equipped = {}, RedeemedCodes = {}, StoredFruits = {} }
    return p, profiles[p]
end

-- Vendor: 20 materials cost 20x
local p1, pr1 = newPlayer(10, 10000)
assert(handleBuyVendorItem(p1, { itemId = "MatOre", quantity = 20 }) == true, "buy 20 ore")
assert(pr1.Gold == 10000 - 2000, "20 ore must cost 2000, got " .. tostring(pr1.Gold))
assert(pr1.Inventory.MatOre == 20, "20 ore delivered")
-- quantity clamp 999 -> 20
assert(handleBuyVendorItem(p1, { itemId = "MatOre", quantity = 999 }) == true, "buy clamp")
assert(pr1.Inventory.MatOre == 40 and pr1.Gold == 6000, "quantity clamped to 20")
-- Non-catalog item rejected
local goldBefore = pr1.Gold
assert(handleBuyVendorItem(p1, { itemId = "MYTHICFRUIT" }) == false, "unknown item rejected")
assert(pr1.Gold == goldBefore and pr1.Inventory.MYTHICFRUIT == nil, "unknown item gives nothing")
-- Not enough gold
local p2, pr2 = newPlayer(10, 999)
assert(handleBuyVendorItem(p2, { itemId = "BasicBlade" }) == false, "insufficient gold rejected")
assert(pr2.Gold == 999 and pr2.Inventory.BasicBlade == nil, "no charge when poor")
-- LevelReq enforced
local p3, pr3 = newPlayer(100, 100000)
assert(handleBuyVendorItem(p3, { itemId = "EliteBlade" }) == false, "LevelReq 500 blocks level 100")
assert(pr3.Gold == 100000, "no charge when level blocked")
pr3.Level = 500
assert(handleBuyVendorItem(p3, { itemId = "EliteBlade" }) == true, "LevelReq met")
assert(pr3.Gold == 95000 and pr3.Inventory.EliteBlade == 1, "elite blade bought once")
-- Owned weapon re-equip is free
assert(handleBuyVendorItem(p3, { itemId = "EliteBlade" }) == true and pr3.Gold == 95000, "re-equip free")
print("PASS Luau VM vendor purchase behavior (qty x price, catalog only, gold, LevelReq)")

-- Giftcode expiry relative to launch date
local Expansion = {}
local function ensureExpansionProfile(profile) profile.RedeemedCodes = profile.RedeemedCodes or {} end
local function ensureRuntimeFields(p, rt) rt.RecentCodeDedup = rt.RecentCodeDedup or {} end
function Expansion.RefundAllStats() return 0 end

--@@REDEEM@@

local code30, code14
for k, spec in pairs(CombatData.Giftcodes) do
    assert(spec.Expires == nil, "giftcode " .. k .. " must not use a fixed Expires date")
    assert(tonumber(spec.ExpiresDays), "giftcode " .. k .. " needs ExpiresDays")
end
assert(CombatData.Giftcodes.SKYBREAK2026.ExpiresDays == 30 and CombatData.Giftcodes.AETHERV2.ExpiresDays == 30, "D7: launch codes 30 days")
assert(CombatData.Giftcodes.SKYBREAKLAUNCH.ExpiresDays == 14, "D7: SKYBREAKLAUNCH 14 days")
code30, code14 = "AETHERV2", "SKYBREAKLAUNCH"
assert(CombatData.Giftcodes.MYTHICFRUIT == nil, "MYTHICFRUIT removed")
assert(code30 and code14, "need a 30-day and a 14-day code without level gates")

local function redeemer(level)
    local p, pr = newPlayer(level, 0)
    G.Runtime[p] = {}
    return p, pr
end
-- First live run records launch date
local a = redeemer(50)
assert(Expansion.RedeemCode(a, code14) == true, "redeem on launch day")
assert(storeValue == unixNow, "launch date written to SKYBREAK_META_v1")
-- Launch date is not overwritten later
unixNow += 86400
launchUnixCache = nil
launchUnixRetryAt = 0
assert(getLaunchUnix() == 1800000000, "launch date read back after cache reset")
assert(storeValue == 1800000000, "launch date stays the first value")
-- Day 13: 14-day code still valid; day 15: expired
unixNow = 1800000000 + 13 * 86400
local b = redeemer(50)
now += 5
assert(Expansion.RedeemCode(b, code14) == true, "14-day code valid on day 13")
unixNow = 1800000000 + 15 * 86400
local c = redeemer(50)
now += 5
assert(Expansion.RedeemCode(c, code14) == false, "14-day code expired on day 15")
assert(Expansion.RedeemCode(c, code30) == true, "30-day code still valid on day 15")
unixNow = 1800000000 + 31 * 86400
local d2 = redeemer(50)
now += 5
assert(Expansion.RedeemCode(d2, code30) == false, "30-day code expired on day 31")
-- Same player cannot redeem twice
unixNow = 1800000000 + 2 * 86400
local e = redeemer(50)
assert(Expansion.RedeemCode(e, code30) == true, "first redeem")
now += 5
assert(Expansion.RedeemCode(e, code30) == false, "second redeem rejected")
-- DataStore down: no launch date -> codes do not expire (no false lockout)
launchUnixCache = nil
launchUnixRetryAt = 0
fakeStore.UpdateAsync = function() error("DataStore down") end
fakeStore.GetAsync = function() error("DataStore down") end
unixNow = 1800000000 + 400 * 86400
local f = redeemer(50)
now += 5
assert(Expansion.RedeemCode(f, code30) == true, "no launch date -> no expiry")
print("PASS Luau VM giftcode behavior (launch-relative ExpiresDays, single use, DataStore outage)")
"""


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    checks = 0

    def check(condition: bool, label: str):
        nonlocal checks
        if not condition:
            print(f"[FAIL] {label}")
            raise AssertionError(label)
        checks += 1
        print(f"PASS {label}")

    # 1. Verify canonical path resolution works without 04_Roblox/src/
    config_path = resolve_luau_path("ReplicatedStorage/Shared/Config.lua")
    game_service_path = resolve_luau_path("ServerScriptService/Services/GameService.lua")
    vendor_path = resolve_luau_path("ServerScriptService/Services/SkybreakVendorAndArsenalService.lua")
    dev_gate_path = resolve_luau_path("ServerScriptService/Services/DevGate.lua")
    remote_guard_path = resolve_luau_path("ServerScriptService/Services/RemoteGuard.lua")
    ui_handler_path = resolve_luau_path("ServerScriptService/SkybreakServer/UIRequestHandler.server.lua")

    config_text = config_path.read_text(encoding="utf-8")
    vendor_text = vendor_path.read_text(encoding="utf-8")
    dev_gate_text = dev_gate_path.read_text(encoding="utf-8")
    remote_guard_text = remote_guard_path.read_text(encoding="utf-8")
    ui_handler_text = ui_handler_path.read_text(encoding="utf-8")

    # 2. P0-03 Contract Assertions: SkybreakVendorAndArsenalService.lua
    check(
        "totalGold = costGold * qty" in vendor_text and "totalShards = costShards * qty" in vendor_text,
        "P0-03: SkybreakVendorAndArsenalService multiplies costGold and costShards by qty",
    )
    check(
        "ArsenalExpansionConfig.VendorCatalogs" in vendor_text and "resolveVendorPrice" in vendor_text,
        "P0-03: SkybreakVendorAndArsenalService validates items against VendorCatalogs",
    )
    check(
        "return tier * 15000" not in vendor_text and "tier * 15000" not in vendor_text,
        "P0-03: SkybreakVendorAndArsenalService does NOT contain fallback 'return tier * 15000'",
    )
    check(
        "levelBlocked(catEntry, displayName)" in vendor_text and "isPlayerNearVendor" not in vendor_text,
        "P0-03: Vendor enforces catalog LevelReq (no NPC proximity: HUD Shop opens anywhere)",
    )

    # 3. P0-04 Contract Assertions: DevGate.lua & EnableDevSandbox isolation
    check(
        dev_gate_path.exists() and "function DevGate.IsAllowed" in dev_gate_text,
        "P0-04: DevGate.lua exists and defines DevGate.IsAllowed(player)",
    )
    leaked_dev_sandbox = []
    for rel_label, lua_file in iter_canonical_luau_files():
        if lua_file.name == "DevGate.lua":
            continue
        code_only = strip_luau_line_comments(lua_file.read_text(encoding="utf-8", errors="replace"))
        if "EnableDevSandbox" in code_only:
            leaked_dev_sandbox.append(rel_label)
    check(
        len(leaked_dev_sandbox) == 0,
        f"P0-04: EnableDevSandbox is not used outside DevGate.lua (found in: {leaked_dev_sandbox})",
    )

    # 4. P0-05 Contract Assertions: RemoteGuard.lua & single UIRequest.OnServerEvent router
    check(
        remote_guard_path.exists() and "function RemoteGuard.Allow" in remote_guard_text,
        "P0-05: RemoteGuard.lua exists and defines token-bucket RemoteGuard.Allow",
    )
    check(
        "OnServerEvent:Connect" in ui_handler_text,
        "P0-05: UIRequestHandler.server.lua connects UIRequest.OnServerEvent router",
    )
    extra_ui_listeners = []
    for rel_label, lua_file in iter_canonical_luau_files():
        if lua_file.name == "UIRequestHandler.server.lua":
            continue
        code_only = strip_luau_line_comments(lua_file.read_text(encoding="utf-8", errors="replace"))
        if re.search(r"UIRequest\.OnServerEvent\s*:\s*Connect", code_only):
            extra_ui_listeners.append(rel_label)
    check(
        len(extra_ui_listeners) == 0,
        f"P0-05: UIRequest.OnServerEvent is only connected in UIRequestHandler.server.lua (extra: {extra_ui_listeners})",
    )

    # 5. P0-06 Contract Assertions: Config.lua StoreName & StudioPersistence
    check(
        re.search(r'C\.StoreName\s*=\s*"SKYBREAK_LIVE_v1"', config_text) is not None,
        'P0-06: Config.lua uses C.StoreName = "SKYBREAK_LIVE_v1"',
    )
    check(
        re.search(r"C\.StudioPersistence\s*=\s*false\b", config_text) is not None,
        "P0-06: Config.lua sets C.StudioPersistence = false",
    )

    # 6. Optional live Luau VM execution for DevGate, RemoteGuard, and P0-03 Vendor 4-case logic
    luau_bin = shutil.which(os.environ.get("LUAU_CLI", "luau"))
    if luau_bin:
        luau_harness = f"""
local now = 100
local os = {{ clock = function() return now end, time = function() return math.floor(now) end }}
local isStudio = false
local RunService = {{ IsStudio = function() return isStudio end }}
local Players = {{ PlayerRemoving = {{ Connect = function() end }} }}
local game = {{
    PlaceId = 999,
    GetService = function(_, name)
        if name == "RunService" then return RunService end
        if name == "Players" then return Players end
        return {{}}
    end,
}}
local DevGate = (function()
{dev_gate_text}
end)()
local RemoteGuard = (function()
{remote_guard_text}
end)()

assert(not DevGate.IsAllowed({{ UserId = 12345 }}), "Non-dev rejected on live place")
DevGate.AllowedTestPlaceIds[999] = true
DevGate.AllowedDevUserIds[777] = true
assert(DevGate.IsAllowed({{ UserId = 777 }}), "Whitelisted dev allowed on whitelisted test place")
assert(not DevGate.IsAllowed({{ UserId = 12345 }}), "Non-dev rejected on test place")

local p1 = {{ UserId = 101 }}
for i = 1, 12 do
    assert(RemoteGuard.Allow(p1, "UI"), "Within UI burst " .. i)
end
assert(not RemoteGuard.Allow(p1, "UI"), "Exceeding UI burst rejected")
now += 1
assert(RemoteGuard.Allow(p1, "UI"), "Token bucket refills after 1s")
print("PASS Luau VM DevGate + RemoteGuard behavioral checks")
"""
        target = Path(tempfile.gettempdir()) / "skybreak_logic_tests.luau"
        target.write_text(luau_harness, encoding="utf-8")
        res = subprocess.run([luau_bin, str(target)], capture_output=True, text=True, encoding="utf-8")
        if res.stdout:
            print(res.stdout.strip())
        if res.stderr:
            print(res.stderr.strip())
        check(res.returncode == 0, "Luau VM unit tests exited with 0")

        # 7. Behavioral checks on the REAL vendor purchase + giftcode code (sliced from source, mocked deps)
        expansion_text = resolve_luau_path("ServerScriptService/Services/SkybreakCombatExpansion.lua").read_text(encoding="utf-8")
        combat_data_text = resolve_luau_path("ReplicatedStorage/Shared/SkybreakCombatData.lua").read_text(encoding="utf-8")
        vendor_slice = slice_between(vendor_text, "local catalogPriceCache = nil", "local function getTradeItemValue")
        redeem_slice = slice_between(expansion_text, "local launchUnixCache = nil", "function Expansion.AscendWeaponStar")
        harness2 = (
            BEHAVIOR_HARNESS.replace("--@@COMBATDATA@@", combat_data_text)
            .replace("--@@VENDOR@@", vendor_slice)
            .replace("--@@REDEEM@@", redeem_slice)
        )
        target2 = Path(tempfile.gettempdir()) / "skybreak_behavior_tests.luau"
        target2.write_text(harness2, encoding="utf-8")
        res2 = subprocess.run([luau_bin, str(target2)], capture_output=True, text=True, encoding="utf-8")
        if res2.stdout:
            print(res2.stdout.strip())
        if res2.stderr:
            print(res2.stderr.strip())
        check(res2.returncode == 0, "Luau VM vendor + giftcode behavioral tests exited with 0")
    elif os.environ.get("SKYBREAK_REQUIRE_LUAU") == "1":
        check(False, "SKYBREAK_REQUIRE_LUAU=1 but luau CLI not found (set LUAU_CLI)")
    else:
        print("SKIP Luau VM tests: luau CLI not found (set LUAU_CLI or SKYBREAK_REQUIRE_LUAU=1 in CI)")

    print(f"TOTAL {checks} PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
