"""
SKYBREAK Workstation, Toolchain, MCP & AI Agent Skills Doctor.
Run this script on any new developer machine after receiving the project handover package:
    python 05_Pipeline_Tools_27x_9x/check_workstation_setup.py
"""
import importlib
import os
import shutil
import subprocess
import sys
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

TOOLS_DIR = Path(__file__).resolve().parent
HANDOFF_ROOT = TOOLS_DIR.parent
HOME = Path.home()

BLENDER_CANDIDATES = [
    Path(r"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe"),
    Path(r"C:\Program Files\Blender Foundation\Blender 5.1\blender.exe"),
    Path(r"C:\Program Files\Blender Foundation\Blender 5.0\blender.exe"),
    Path(r"C:\Program Files\Blender Foundation\Blender 4.5\blender.exe"),
    Path(r"C:\Program Files\Blender Foundation\Blender 4.2\blender.exe"),
    Path("/Applications/Blender.app/Contents/MacOS/Blender"),
]

REQUIRED_PY_PACKAGES = ("zstandard", "numpy", "PIL", "requests")
PROJECT_LOCAL_SKILLS = (
    "skybreak-rbxlx-build-and-qa",
    "skybreak-blender-27x-9x-world-pipeline",
    "skybreak-3d-rig-and-virtualsplit",
)
RECOMMENDED_3D_SKILLS = (
    "blender-pro-workflow",
    "blender-modeling",
    "blender-materials",
    "blender-uv-texturing",
    "blender-lighting",
    "blender-cameras",
    "blender-animation",
    "blender-rendering",
    "blender-export",
    "reference-to-3d",
    "animation-quality-gate",
    "find-skills",
)


def run_cmd_version(cmd_args):
    try:
        res = subprocess.run(cmd_args, capture_output=True, text=True, timeout=10)
        if res.returncode == 0:
            line = (res.stdout.strip() or res.stderr.strip()).splitlines()[0]
            return True, line
    except Exception:
        pass
    return False, ""


def find_blender():
    for cand in BLENDER_CANDIDATES:
        if cand.exists():
            return cand
    which_bl = shutil.which("blender")
    return Path(which_bl) if which_bl else None


def find_roblox_studio():
    if sys.platform == "win32":
        local_app = Path(os.environ.get("LOCALAPPDATA", ""))
        versions_dir = local_app / "Roblox" / "Versions"
        if versions_dir.exists():
            exes = list(versions_dir.rglob("RobloxStudioBeta.exe"))
            if exes:
                return exes[0]
        start_menu = local_app.parent / "Roaming" / "Microsoft" / "Windows" / "Start Menu" / "Programs" / "Roblox"
        if start_menu.exists():
            return start_menu
    elif sys.platform == "darwin":
        mac_app = Path("/Applications/RobloxStudio.app")
        if mac_app.exists():
            return mac_app
    return None


def main():
    print("=" * 78)
    print(" SKYBREAK WORKSTATION, TOOLCHAIN, MCP & AI AGENT SKILLS DIAGNOSTIC")
    print("=" * 78)
    warnings = []
    missing_critical = []

    # 1. Standalone Python
    py_ver = f"{sys.version_info.major}.{sys.version_info.minor}.{sys.version_info.micro}"
    if sys.version_info >= (3, 11):
        print(f"  [OK] Standalone Python: {py_ver} ({sys.executable})")
    else:
        print(f"  [MISSING] Python >= 3.11 required (found {py_ver})")
        missing_critical.append("Upgrade Python to 3.12+")

    missing_pkgs = []
    for pkg in REQUIRED_PY_PACKAGES:
        try:
            importlib.import_module(pkg)
        except ImportError:
            missing_pkgs.append("Pillow" if pkg == "PIL" else pkg)
    if not missing_pkgs:
        print("  [OK] Standalone Python packages: zstandard, numpy, Pillow, requests installed")
    else:
        print(f"  [WARN] Standalone Python missing packages: {', '.join(missing_pkgs)}")
        warnings.append(f'Run: "{sys.executable}" -m pip install zstandard numpy Pillow requests')

    # 2. Blender & Blender Embedded Python
    blender_exe = find_blender()
    if blender_exe:
        ok, ver_line = run_cmd_version([str(blender_exe), "--version"])
        print(f"  [OK] Blender detected: {ver_line or blender_exe}")
        bl_py_candidates = list(blender_exe.parent.rglob("python.exe")) if sys.platform == "win32" else list(blender_exe.parent.parent.rglob("python3*"))
        if bl_py_candidates:
            bl_py = bl_py_candidates[0]
            res = subprocess.run([str(bl_py), "-c", "import zstandard, numpy; print(zstandard.__version__)"], capture_output=True, text=True)
            if res.returncode == 0:
                print(f"  [OK] Blender Embedded Python zstandard={res.stdout.strip()} ({bl_py})")
            else:
                print(f"  [MISSING] Blender Embedded Python lacks zstandard/numpy ({bl_py})")
                missing_critical.append(f'Run: "{bl_py}" -m pip install zstandard==0.25.0 numpy Pillow requests')
    else:
        print("  [MISSING] Blender 5.2 LTS not found in standard locations")
        missing_critical.append("Install Blender 5.2 LTS from blender.org")

    # 3. Roblox Studio
    studio_path = find_roblox_studio()
    if studio_path:
        print(f"  [OK] Roblox Studio detected: {studio_path}")
    else:
        print("  [WARN] Roblox Studio not detected in default user AppData path")
        warnings.append("Install Roblox Studio and enable Beta Feature: EditableMesh and EditableImage")

    # 4. Git, Git LFS, Node.js
    for label, cmd, crit in (
        ("Git", ["git", "--version"], True),
        ("Git LFS", ["git", "lfs", "version"], False),
        ("Node.js (for npx skills & MCP)", ["node", "--version"], False),
    ):
        ok, line = run_cmd_version(cmd)
        if ok:
            print(f"  [OK] {label}: {line}")
        elif crit:
            print(f"  [MISSING] {label} not found in PATH")
            missing_critical.append(f"Install {label}")
        else:
            print(f"  [WARN] {label} not found in PATH")
            warnings.append(f"Install {label}")

    # 5. Project-Local AGENTS.md & .agents/skills/
    print("\n--- Project-Local AI Agent Rules & Skills ---")
    agents_md = HANDOFF_ROOT / "AGENTS.md"
    print(f"  [{'OK' if agents_md.exists() else 'MISSING'}] {agents_md.relative_to(HANDOFF_ROOT)}")
    for sk in PROJECT_LOCAL_SKILLS:
        sk_p = HANDOFF_ROOT / ".agents" / "skills" / sk / "SKILL.md"
        if sk_p.exists():
            print(f"  [OK] Project Skill: {sk}")
        else:
            print(f"  [MISSING] Project Skill: {sk}")
            missing_critical.append(f"Restore .agents/skills/{sk}/SKILL.md")

    # 6. Global AI Agent Skills & MCP
    print("\n--- Global AI Agent Skills & MCP Discovery ---")
    global_skill_dirs = [
        HOME / ".agents" / "skills",
        HOME / ".codex" / "skills",
        HOME / ".gemini" / "config" / "skills",
    ]
    discovered_global = set()
    for gd in global_skill_dirs:
        if gd.exists():
            names = [p.name for p in gd.iterdir() if (p / "SKILL.md").exists()]
            discovered_global.update(names)
            print(f"  [OK] Global skills folder {gd}: {len(names)} skills")
    found_rec = [s for s in RECOMMENDED_3D_SKILLS if s in discovered_global]
    print(f"  [INFO] Recommended 3D/Workflow Global Skills present: {len(found_rec)}/{len(RECOMMENDED_3D_SKILLS)}")
    if len(found_rec) < len(RECOMMENDED_3D_SKILLS):
        warnings.append(
            "Optional for 3D AI Artists: install global skills (see 00_Documents/07_SOFTWARE_ENVIRONMENT_MCP_AND_AGENT_SKILLS_SETUP.md)"
        )

    mcp_dirs = [
        HOME / ".gemini" / "antigravity" / "mcp" / "Roblox_Studio",
        HOME / ".gemini" / "config" / "mcp_config.json",
    ]
    if any(p.exists() for p in mcp_dirs):
        print("  [OK] Antigravity MCP configuration / Roblox_Studio MCP bridge detected")
    else:
        print("  [INFO] Roblox_Studio MCP bridge not yet configured on this user profile (optional for AI live-Studio control)")

    print("\n" + "=" * 78)
    if missing_critical:
        print(f" RESULT: {len(missing_critical)} CRITICAL ITEM(S) REQUIRE SETUP:")
        for item in missing_critical:
            print(f"   -> {item}")
        sys.exit(1)
    else:
        print(" RESULT: [PASS] CORE SKYBREAK DEVELOPMENT ENVIRONMENT IS READY!")
        if warnings:
            print(" Optional recommendations:")
            for w in warnings:
                print(f"   * {w}")
    print("=" * 78)


if __name__ == "__main__":
    main()
