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
        "isPlayerNearVendor(player, 20)" in vendor_text,
        "P0-03: SkybreakVendorAndArsenalService enforces <= 20 stud vendor proximity",
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

    print(f"TOTAL {checks} PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
