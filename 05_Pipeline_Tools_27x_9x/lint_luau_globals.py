"""Bắt biến toàn cục chưa khai báo trong toàn bộ Luau của 3 thư mục Hạng Mục.

Biên dịch vẫn qua và verify vẫn [PASS] khi code gọi một biến chưa tồn tại,
nên loại lỗi này chỉ lộ ra lúc đang chơi. Script dùng luau-analyze chính thức.
Thoát 1 nếu có lỗi cú pháp hoặc biến lạ.
"""
import re
import shutil
import subprocess
import sys
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
ROBLOX = TOOLS.parent / "04_Roblox"
CATS = ("01_HangMuc1_Server_Combat_World", "02_HangMuc2_UI_Shop_Config", "03_HangMuc3_3D_VuKhi_Giap_VFX")
ROBLOX_GLOBALS = set("""
Axes BrickColor CFrame CatalogSearchParams Color3 ColorSequence ColorSequenceKeypoint Content DateTime DockWidgetPluginGuiInfo
Enum Faces FloatCurveKey Font Instance NumberRange NumberSequence NumberSequenceKeypoint OverlapParams Path2DControlPoint
PathWaypoint PhysicalProperties Random Ray RaycastParams Rect Region3 Region3int16 RotationCurveKey SharedTable TweenInfo
UDim UDim2 Vector2 Vector2int16 Vector3 Vector3int16 buffer delay elapsedTime game gcinfo plugin script settings shared
spawn stats task tick time typeof UserSettings version wait warn workspace bit32 utf8
""".split())
LINE = re.compile(r"^(?P<file>.+?):(?P<line>\d+):\S+ \(\w+\) (?P<kind>\w+): (?P<msg>.*)$")


def find_analyzer():
    local = TOOLS / "bin" / ("luau-analyze.exe" if sys.platform == "win32" else "luau-analyze")
    if local.exists():
        return str(local)
    return shutil.which("luau-analyze")


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    exe = find_analyzer()
    if not exe:
        print("[FAIL] Không tìm thấy luau-analyze trong 05_Pipeline_Tools_27x_9x/bin hoặc PATH")
        return 1
    files = [str(p) for cat in CATS for p in sorted((ROBLOX / cat).rglob("*.lua"))]
    bad = []
    for i in range(0, len(files), 25):
        out = subprocess.run([exe, "--formatter=plain", *files[i:i + 25]], capture_output=True, text=True, encoding="utf-8", errors="replace")
        for raw in (out.stdout + out.stderr).splitlines():
            m = LINE.match(raw.strip())
            if not m:
                continue
            kind, msg = m["kind"], m["msg"]
            g = re.match(r"Unknown global '(\w+)'", msg)
            if kind == "SyntaxError" or (g and g.group(1) not in ROBLOX_GLOBALS) or kind == "UninitializedLocal":
                bad.append(f"{Path(m['file']).name}:{m['line']} {msg[:110]}")
    bad = sorted(set(bad))
    print(f"=== LUAU GLOBAL LINT: {len(files)} file ===")
    if bad:
        print(f"[FAIL] {len(bad)} lỗi:")
        for b in bad:
            print("  -", b)
        return 1
    print("[PASS] Không có lỗi cú pháp hoặc biến chưa khai báo.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
