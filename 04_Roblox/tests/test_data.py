"""Runs PlayerDataService & Config data-persistence contract checks (P0-06, D3, D9) against the canonical Hạng Mục sources."""
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


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    count = 0

    def check(condition: bool, label: str):
        nonlocal count
        if not condition:
            print(f"[FAIL] {label}")
            raise AssertionError(label)
        count += 1
        print(f"PASS {label}")

    config_path = resolve_luau_path("ReplicatedStorage/Shared/Config.lua")
    data_path = resolve_luau_path("ServerScriptService/Services/PlayerDataService.lua")

    config = config_path.read_text(encoding="utf-8")
    data = data_path.read_text(encoding="utf-8")

    # 1. P0-06 & D3 Config.lua checks
    check(
        re.search(r'C\.StoreName\s*=\s*"SKYBREAK_LIVE_v1"', config) is not None,
        'P0-06 (D3): Config.lua sets C.StoreName = "SKYBREAK_LIVE_v1"',
    )
    check(
        re.search(r"C\.StudioPersistence\s*=\s*false\b", config) is not None,
        "P0-06 (D3): Config.lua sets C.StudioPersistence = false",
    )

    # 2. P0-06 PlayerDataService.lua schema migration, size guard, and ReadOnlyFallback checks
    check(
        "CURRENT_SCHEMA_VERSION" in data and "SCHEMA_MIGRATIONS" in data and "migrateProfile" in data,
        "P0-06: PlayerDataService defines CURRENT_SCHEMA_VERSION and migrateProfile",
    )
    check(
        "s.ReadOnlyFallback" in data and "Bảo vệ dữ liệu gốc (ReadOnly)" in data,
        "P0-06: PlayerDataService blocks cloud overwrites while in ReadOnlyFallback mode",
    )
    check(
        "JSONEncode" in data and "3500000" in data and "1000000" in data,
        "P0-06: PlayerDataService enforces 3.5 MB JSON size ceiling and 1 MB warning",
    )

    # 3. D9 Starter unlock checks in PlayerDataService.lua
    check(
        'ActiveShip = "SkySloop"' in data,
        'P0-07 (D9): PlayerDataService defaults ActiveShip to "SkySloop"',
    )
    check(
        "UnlockedHakiColors.crimson_conqueror = true" not in data
        and "UnlockedShips.CelestialAetherGalleon = true" not in data,
        "P0-07 (D9): hydrate() does not force-unlock crimson_conqueror or CelestialAetherGalleon",
    )

    # 4. Optional live Luau VM execution when luau CLI is installed
    luau_bin = shutil.which(os.environ.get("LUAU_CLI", "luau"))
    if luau_bin:
        luau_harness = r"""
local now = 1000
local os = {
    time = function() return now end,
    clock = function() return now end,
}
local function copy(v)
    if type(v) ~= "table" then return v end
    local c = {}
    for k, x in pairs(v) do c[k] = copy(x) end
    return c
end
local task = {
    wait = function(seconds) now += (tonumber(seconds) or 0) end,
    spawn = function() end,
    delay = function() end,
}
local warn = function() end
local C = {
    MaxLevel = 2550,
    MaxStat = 2550,
    StatPointsPerLevel = 3,
    StudioPersistence = false,
    StoreName = "SKYBREAK_LIVE_v1",
    LeaseSeconds = 180,
    AutosaveSeconds = 45,
    SkillNames = { SkySlash = "Sky Slash" },
    Classes = { SkyGuardian = true, ThunderStriker = true, ArcaneMage = true },
    Quests = { { Id = "Q01" } },
    Islands = { { Id = "SkyHub" } },
}
local store = { Rows = {}, Fails = 0, Calls = 0 }
function store:UpdateAsync(key, fn)
    self.Calls += 1
    if self.Fails > 0 then
        self.Fails -= 1
        error("simulated outage")
    end
    local record = fn(copy(self.Rows[key]))
    if record == nil then return nil end
    self.Rows[key] = copy(record)
    return copy(record)
end
local Players = {}
local services = {
    Players = Players,
    DataStoreService = { GetDataStore = function() return store end },
    HttpService = {
        GenerateGUID = function() return "test-guid" end,
        JSONEncode = function(_, val) return "{}" end,
    },
    RunService = { IsStudio = function() return false end },
}
local game = {
    JobId = "test-job",
    ReplicatedStorage = {
        Shared = { Config = "config" },
        FindFirstChild = function() return nil end,
    },
    GetService = function(_, name) return services[name] end,
    BindToClose = function() end,
}
local require = function() return C end
local D = (function()
""" + data + r"""
end)()
local function player(id)
    return {
        UserId = id,
        Name = "Player" .. tostring(id),
        Parent = Players,
        SetAttribute = function() end,
        Kick = function(self, msg) self.Kicked = msg end,
    }
end
local p1 = player(1)
local prof = D.Load(p1)
assert(prof and prof.Level == 1 and prof.ActiveShip == "SkySloop", "New profile created with SkySloop")
assert(store.Rows.u_1.Owner == "test-job:test-guid", "Load acquires session lock")
prof.Gold = 777
assert(D.Save(p1, false) and store.Rows.u_1.Data.Gold == 777, "Save persists Gold")
D.Release(p1)
assert(D.Sessions[p1] == nil and store.Rows.u_1.Owner == nil, "Release unlocks session")

-- Test ReadOnlyFallback never clobbers existing cloud data (P0-06)
store.Fails = 3
local p1Fallback = player(1)
local fbProf = D.Load(p1Fallback)
assert(fbProf and D.Sessions[p1Fallback].ReadOnlyFallback == true, "Outage enters ReadOnlyFallback")
fbProf.Gold = 1
assert(not D.Save(p1Fallback, false), "Save blocked during ReadOnlyFallback")
assert(store.Rows.u_1.Data.Gold == 777, "Cloud Gold=777 preserved from ReadOnlyFallback overwrite")
print("PASS Luau VM PlayerDataService session-lock & ReadOnlyFallback checks")
"""
        target = Path(tempfile.gettempdir()) / "skybreak_data_tests.luau"
        target.write_text(luau_harness, encoding="utf-8")
        res = subprocess.run([luau_bin, str(target)], capture_output=True, text=True, encoding="utf-8")
        if res.stdout:
            print(res.stdout.strip())
        if res.stderr:
            print(res.stderr.strip())
        check(res.returncode == 0, "Luau VM PlayerDataService unit tests exited with 0")

    print(f"TOTAL {count} PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
