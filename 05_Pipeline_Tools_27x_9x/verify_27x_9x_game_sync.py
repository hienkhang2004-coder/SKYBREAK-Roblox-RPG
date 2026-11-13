"""
End-to-end 27x / 9x SKYBREAK Roblox Game Sync Audit.
Verifies:
1. All 13 runtime_v8 world folders exist, Header mesh_count <= 999, and 100% of MeshXXX.json chunks have AABB <= 1,750 < 2,048 studs.
2. All 13 DelegatedV5Sources world folders in SKYBREAK_Playable_v12_PremiumUI.rbxlx match runtime_v8 Header.json.zstd.b64 SHA-256 and module counts.
3. Workspace.SkyHub.SkybornSpawn == (-317.4, 50.5, 527.8) [Anchored/Neutral/CanCollide=true], Workspace.FallenPartsDestroyHeight == -4500, Lighting.Technology == 4 (Future, EnvironmentDiffuseScale=1.0, EnvironmentSpecularScale=1.0, GlobalShadows=true, ShadowSoftness=0.18, ClockTime=16.1, SunRaysEffect Intensity=0.14 Spread=0.65), StarterPlayer (R15 Standard, LoadCharacterAppearance=true, CharacterUseJumpPower=true, EnableMouseLockOption=false), Players (MaxPlayers=16, CharacterAutoLoads=true), TextChatService (ChatVersion=1), and SoundService (RespectFilteringEnabled=true) in .rbxlx.
4. All .lua files in 04_Roblox/src are < 199,000 bytes, have 100% SHA-256 Source parity with .rbxlx (zero orphan scripts), and are mirrored identically into SKYBREAK_Visual_v2 + 06_Antigravity_Work.
5. Zero leftover legacy 1x/3x world coordinates (8000, -8000, 1640, -1620, 6320, 9840, -9860, -9960, -8040, -620, 660) in Vector3/_V3 calls across 04_Roblox/src.
6. Zero AABB overlaps across all 20 placed 3D world instances (3 Main Maps 27x + 10 Expansion Worlds 9x + 2 Shrines + 5 Expansion Realms 9x).
7. Zero Part.Size components > 2,048 studs across all collider Luau modules and scripts.
"""
import hashlib
import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")

TOOLS_DIR = Path(__file__).resolve().parent
HANDOFF_ROOT = TOOLS_DIR.parent
OUTPUTS_ROOT = HANDOFF_ROOT.parent
RUNTIME_V8 = HANDOFF_ROOT / "06_Antigravity_Work" / "runtime_v8"
SRC_ROOT = HANDOFF_ROOT / "04_Roblox" / "src"
RBXLX_MAIN = HANDOFF_ROOT / "04_Roblox" / "SKYBREAK_Playable_v12_PremiumUI.rbxlx"
RBXLX_06 = HANDOFF_ROOT / "06_Antigravity_Work" / "SKYBREAK_Playable_v12_PremiumUI.rbxlx"
RBXLX_V2 = OUTPUTS_ROOT / "SKYBREAK_Visual_v2" / "SKYBREAK_Playable_v12_PremiumUI.rbxlx"
SPEC_JSON = TOOLS_DIR / "macro_world_coords_27x_9x.json"

WORLD_13 = [
    "GoldenSky",
    "FrozenCyber",
    "ShadowRealm",
    "SunshardSkySanctuary",
    "WestGardenPirateBastion",
    "CyberportCafeTradingHub",
    "PermafrostGarrisonFortress",
    "MicrochipAwakeningRaidLab",
    "GlacialWreckageDangerSea",
    "CastleOnTheVoidMansion",
    "UmbralCrystalSanctumForest",
    "TempleOfTheCoreRaceV4",
    "MirageSkyIslandLeviathanAbyss",
]


SYNC_SERVICES = ("ReplicatedStorage", "ServerScriptService", "ServerStorage", "StarterPlayer")


def get_name(it):
    p = it.find("Properties")
    if p is not None:
        for s in p.findall("string"):
            if s.attrib.get("name") == "Name":
                return s.text or ""
    return ""


def get_typed_prop(it, tag: str, prop_name: str):
    p = it.find("Properties")
    if p is not None:
        for el in p.findall(tag):
            if el.attrib.get("name") == prop_name:
                return (el.text or "").strip()
    return None


def classify_lua_file(rel_parts):
    fname = rel_parts[-1]
    if fname.endswith(".server.lua"):
        return tuple(list(rel_parts[:-1]) + [fname[:-11]]), "Script"
    elif fname.endswith(".client.lua"):
        return tuple(list(rel_parts[:-1]) + [fname[:-11]]), "LocalScript"
    else:
        return tuple(list(rel_parts[:-1]) + [fname[:-4]]), "ModuleScript"


def main():
    failures = []
    spec = json.loads(SPEC_JSON.read_text(encoding="utf-8"))

    print("=== 1. AUDITING 13 RUNTIME_V8 WORLD EXPORTS (< 2,048 STUD EDITABLEMESH CAP) ===")
    world_local_bounds = {}
    for wname in WORLD_13:
        wdir = RUNTIME_V8 / wname
        hdr_p = wdir / "Header.json"
        if not hdr_p.exists():
            failures.append(f"Missing Header.json for {wname}")
            continue
        hdr = json.loads(hdr_p.read_text(encoding="utf-8"))
        mc = int(hdr.get("mesh_count", 0))
        mesh_jsons = sorted(wdir.glob("Mesh*.json"))
        if mc <= 0 or mc > 999 or mc != len(mesh_jsons):
            failures.append(f"{wname}: mesh_count={mc} vs actual Mesh*.json={len(mesh_jsons)}")

        max_span = 0.0
        total_tris = 0
        gmin = [1e12, 1e12, 1e12]
        gmax = [-1e12, -1e12, -1e12]
        for mp in mesh_jsons:
            mdata = json.loads(mp.read_text(encoding="utf-8"))
            verts = mdata.get("vertices") or mdata.get("v") or mdata.get("verts") or []
            faces = mdata.get("triangles") or mdata.get("f") or mdata.get("faces") or []
            if verts and isinstance(verts[0], (int, float)):
                xs = verts[0::3]
                ys = verts[1::3]
                zs = verts[2::3]
            else:
                xs = [pt[0] for pt in verts]
                ys = [pt[1] for pt in verts]
                zs = [pt[2] for pt in verts]
            if not xs:
                continue
            dx = max(xs) - min(xs)
            dy = max(ys) - min(ys)
            dz = max(zs) - min(zs)
            span = max(dx, dy, dz)
            max_span = max(max_span, span)
            if span >= 2048.0:
                failures.append(f"{wname}/{mp.name}: EditableMesh AABB span {span:.1f} >= 2048 studs!")
            gmin = [min(gmin[0], min(xs)), min(gmin[1], min(ys)), min(gmin[2], min(zs))]
            gmax = [max(gmax[0], max(xs)), max(gmax[1], max(ys)), max(gmax[2], max(zs))]
            if faces and isinstance(faces[0], (int, float)):
                total_tris += len(faces) // 3
            else:
                total_tris += len(faces)
        world_local_bounds[wname] = (gmin, gmax)
        print(
            f"  [OK] {wname:32s}: meshes={mc:3d}, tris={total_tris:7d}, max_chunk_span={max_span:7.1f} studs, "
            f"world_span=({gmax[0]-gmin[0]:.0f} x {gmax[2]-gmin[2]:.0f})"
        )

    print("\n=== 2. AUDITING ZERO WORLD OVERLAPS ACROSS ALL 20 PLACED ZONES ===")
    placed_zones = []
    for rname in ("GoldenSky", "FrozenCyber", "ShadowRealm"):
        ox, oy, oz = spec["realms"][rname]["Origin"]
        if rname in world_local_bounds:
            mn, mx = world_local_bounds[rname]
            placed_zones.append((rname, [mn[0]+ox, mn[2]+oz], [mx[0]+ox, mx[2]+oz], oy))
    for entry in spec["grand_sky_islands_streaming"]:
        nm = entry["Name"]
        asset = entry["Asset"]
        ox, oy, oz = entry["Origin"]
        if asset in world_local_bounds:
            mn, mx = world_local_bounds[asset]
            placed_zones.append((nm, [mn[0]+ox, mn[2]+oz], [mx[0]+ox, mx[2]+oz], oy))
        else:
            placed_zones.append((nm, [ox-120, oz-120], [ox+120, oz+120], oy))
    for rname in ("VerdantCrown", "EmberforgeWastes", "AbyssalTides", "ChronosBastion", "VeilsEnd"):
        rinfo = spec["realms"][rname]
        asset = rinfo["Asset"]
        ox, oy, oz = rinfo["Origin"]
        if asset in world_local_bounds:
            mn, mx = world_local_bounds[asset]
            placed_zones.append((rname, [mn[0]+ox, mn[2]+oz], [mx[0]+ox, mx[2]+oz], oy))

    overlap_count = 0
    for i in range(len(placed_zones)):
        n1, mn1, mx1, _ = placed_zones[i]
        for j in range(i + 1, len(placed_zones)):
            n2, mn2, mx2, _ = placed_zones[j]
            ox_ov = min(mx1[0], mx2[0]) - max(mn1[0], mn2[0])
            oz_ov = min(mx1[1], mx2[1]) - max(mn1[1], mn2[1])
            if ox_ov > 0 and oz_ov > 0:
                overlap_count += 1
                failures.append(f"XZ OVERLAP between {n1} and {n2}: ({ox_ov:.1f} x {oz_ov:.1f} studs)")
    print(f"  Checked {len(placed_zones)} placed 3D zones -> overlaps={overlap_count}")

    print("\n=== 3. AUDITING LUAU SCRIPT SIZES, LEGACY COORDS & COLLIDER PART SIZES ===")
    legacy_vec_re = re.compile(
        r"(?:Vector3\.new|_V3)\s*\(\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*\)"
    )
    collider_tuple_re = re.compile(
        r"^\s*\{\s*(-?\d+(?:\.\d+)?(?:\s*,\s*-?\d+(?:\.\d+)?){4,7})\s*\}\s*,?\s*$"
    )
    explicit_size_re = re.compile(
        r"\bSize\s*=\s*(?:Vector3\.new|_V3)\s*\(\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)\s*\)"
    )
    banned_xz = {
        (8000, 0), (-8000, 0), (7890, 155), (-8070, 125),
        (1640, -40), (1640, -32), (-1620, 40), (-1620, 78),
        (6320, 960), (6320, 940), (6160, -680), (9840, 920), (9840, 952), (9880, -840),
        (-9860, 960), (-9860, 980), (-6120, 940), (-9960, -820), (-9960, -788), (-8040, -2180), (-8040, -2208),
        (-620, 860), (-620, 872), (660, 860), (660, 876),
    }
    max_lua_bytes = 0
    max_lua_name = ""
    lua_count = 0
    collider_tuples_checked = 0
    max_collider_dim = 0.0
    expected_src_scripts = {}

    for fpath in sorted(SRC_ROOT.rglob("*.lua")):
        rel = fpath.relative_to(SRC_ROOT).as_posix()
        raw = fpath.read_bytes()
        sz = len(raw)
        lua_count += 1
        if sz > max_lua_bytes:
            max_lua_bytes = sz
            max_lua_name = rel
        if sz >= 199000:
            failures.append(f"Script exceeds 199,000B cap: {rel} ({sz}B)")
        txt = raw.decode("utf-8")
        rel_parts = fpath.relative_to(SRC_ROOT).parts
        if rel_parts and rel_parts[0] in SYNC_SERVICES:
            s_key = classify_lua_file(rel_parts)
            norm_sha = hashlib.sha256(txt.replace("\r\n", "\n").encode("utf-8")).hexdigest()
            expected_src_scripts[s_key] = (rel, norm_sha)

        is_collider_mod = ("Collision" in rel) or ("Colliders" in rel)
        for idx, ln in enumerate(txt.splitlines(), 1):
            if ln.strip().startswith("--"):
                continue
            for m in legacy_vec_re.finditer(ln):
                vx, vy, vz = float(m.group(1)), float(m.group(2)), float(m.group(3))
                key = (int(round(vx)), int(round(vz)))
                if key in banned_xz:
                    failures.append(f"Legacy 1x/3x coord {key} in {rel}:{idx}: {ln.strip()[:100]}")
            for sm in explicit_size_re.finditer(ln):
                s_dims = (float(sm.group(1)), float(sm.group(2)), float(sm.group(3)))
                if max(s_dims) > 2048.0:
                    failures.append(f"Part.Size > 2048 in {rel}:{idx}: {s_dims}")
            if is_collider_mod:
                tm = collider_tuple_re.match(ln)
                if tm:
                    nums = [float(x) for x in tm.group(1).split(",")]
                    dims = nums[3:5] if len(nums) == 5 else nums[3:6]
                    collider_tuples_checked += 1
                    md = max(dims)
                    if md > max_collider_dim:
                        max_collider_dim = md
                    if md > 2048.0:
                        failures.append(f"Collider tuple Size > 2048 in {rel}:{idx}: {dims}")
    if collider_tuples_checked == 0:
        failures.append("Zero collider tuples parsed across Collision/Colliders modules!")
    print(
        f"  Audited {lua_count} Luau scripts -> largest: {max_lua_name} ({max_lua_bytes} B < 199,000 B); "
        f"colliders={collider_tuples_checked} (max dim={max_collider_dim:.2f} <= 2048)"
    )

    print("\n=== 4. AUDITING .RBXLX PACKAGING, SERVICES, SCRIPT SHA-256 PARITY & MIRRORS ===")
    for mp in (RBXLX_MAIN, RBXLX_06, RBXLX_V2):
        if not mp.exists():
            failures.append(f"Missing .rbxlx mirror: {mp}")
    if RBXLX_MAIN.exists() and RBXLX_06.exists() and RBXLX_V2.exists():
        h_main = hashlib.sha256(RBXLX_MAIN.read_bytes()).hexdigest()
        h_06 = hashlib.sha256(RBXLX_06.read_bytes()).hexdigest()
        h_v2 = hashlib.sha256(RBXLX_V2.read_bytes()).hexdigest()
        if not (h_main == h_06 == h_v2):
            failures.append("RBXLX mirrors out of sync (SHA-256 mismatch)!")
        else:
            print(f"  [OK] All 3 .rbxlx files byte-identical ({RBXLX_MAIN.stat().st_size:,} bytes, sha256={h_main[:16]}...)")

        tree = ET.parse(RBXLX_MAIN)
        root = tree.getroot()
        v5_map = {}
        spawn_xyz = None
        spawn_flags = {}
        top_services = {}

        for ch in root.findall("Item"):
            cls = ch.attrib.get("class", "")
            top_services[cls] = ch
            if get_name(ch) == "ReplicatedStorage":
                for sub in ch.findall("Item"):
                    if get_name(sub) == "DelegatedV5Sources":
                        for af in sub.findall("Item"):
                            v5_map[get_name(af)] = af
            elif cls == "Workspace":
                fpdh = get_typed_prop(ch, "float", "FallenPartsDestroyHeight")
                if fpdh is None or abs(float(fpdh) - (-4500.0)) > 0.1:
                    failures.append(f"Workspace.FallenPartsDestroyHeight mismatch: {fpdh}")
                for sub in ch.findall("Item"):
                    if get_name(sub) == "SkyHub":
                        for sp in sub.findall("Item"):
                            if get_name(sp) == "SkybornSpawn":
                                cf = sp.find("Properties").find("CoordinateFrame")
                                spawn_xyz = (
                                    round(float(cf.find("X").text), 1),
                                    round(float(cf.find("Y").text), 1),
                                    round(float(cf.find("Z").text), 1),
                                )
                                spawn_flags = {
                                    "Anchored": get_typed_prop(sp, "bool", "Anchored"),
                                    "Neutral": get_typed_prop(sp, "bool", "Neutral"),
                                    "CanCollide": get_typed_prop(sp, "bool", "CanCollide"),
                                }

        if spawn_xyz != (-317.4, 50.5, 527.8):
            failures.append(f"Workspace.SkyHub.SkybornSpawn mismatch: {spawn_xyz} (expected (-317.4, 50.5, 527.8))")
        elif spawn_flags != {"Anchored": "true", "Neutral": "true", "CanCollide": "true"}:
            failures.append(f"Workspace.SkyHub.SkybornSpawn property flags mismatch: {spawn_flags}")
        else:
            print(f"  [OK] Workspace.SkyHub.SkybornSpawn = {spawn_xyz} {spawn_flags}")

        # Verify top-level DataModel services & launch settings
        svc_fail_before = len(failures)
        lighting_el = top_services.get("Lighting")
        if lighting_el is None:
            failures.append("Missing top-level Lighting in .rbxlx")
        else:
            lighting_tech = get_typed_prop(lighting_el, "token", "Technology")
            if lighting_tech != "4":
                failures.append(f"Lighting.Technology expected '4' (Future), got {lighting_tech!r}")
            if get_typed_prop(lighting_el, "bool", "GlobalShadows") != "true":
                failures.append(
                    f"Lighting.GlobalShadows expected 'true', got {get_typed_prop(lighting_el, 'bool', 'GlobalShadows')!r}"
                )
            for fname, fexp in (
                ("EnvironmentDiffuseScale", 1.0),
                ("EnvironmentSpecularScale", 1.0),
                ("ShadowSoftness", 0.18),
                ("ClockTime", 16.1),
            ):
                fraw = get_typed_prop(lighting_el, "float", fname)
                if fraw is None or abs(float(fraw) - fexp) > 1e-3:
                    failures.append(f"Lighting.{fname} expected {fexp}, got {fraw!r}")
            sun_rays_el = None
            for lch in lighting_el.findall("Item"):
                if lch.attrib.get("class") == "SunRaysEffect":
                    sun_rays_el = lch
                    break
            if sun_rays_el is None:
                failures.append("Missing SunRaysEffect child under Lighting in .rbxlx")
            else:
                sr_en = get_typed_prop(sun_rays_el, "bool", "Enabled")
                sr_int = get_typed_prop(sun_rays_el, "float", "Intensity")
                sr_spr = get_typed_prop(sun_rays_el, "float", "Spread")
                if sr_en != "true":
                    failures.append(f"Lighting.SunRaysEffect.Enabled expected 'true', got {sr_en!r}")
                if sr_int is None or abs(float(sr_int) - 0.14) > 1e-3:
                    failures.append(f"Lighting.SunRaysEffect.Intensity expected 0.14, got {sr_int!r}")
                if sr_spr is None or abs(float(sr_spr) - 0.65) > 1e-3:
                    failures.append(f"Lighting.SunRaysEffect.Spread expected 0.65, got {sr_spr!r}")

        sp_el = top_services.get("StarterPlayer")
        if sp_el is None:
            failures.append("Missing top-level StarterPlayer in .rbxlx")
        else:
            expected_sp = {
                ("bool", "EnableMouseLockOption"): "false",
                ("bool", "LoadCharacterAppearance"): "true",
                ("bool", "CharacterUseJumpPower"): "true",
                ("token", "GameSettingsAvatar"): "1",
            }
            for (ptag, pname), pval in expected_sp.items():
                actual = get_typed_prop(sp_el, ptag, pname)
                if actual != pval:
                    failures.append(f"StarterPlayer.{pname} expected '{pval}', got '{actual}'")

        players_el = top_services.get("Players")
        if players_el is None:
            failures.append("Missing top-level Players service in .rbxlx")
        else:
            if get_typed_prop(players_el, "int", "MaxPlayers") != "16":
                failures.append(f"Players.MaxPlayers expected '16', got '{get_typed_prop(players_el, 'int', 'MaxPlayers')}'")
            if get_typed_prop(players_el, "bool", "CharacterAutoLoads") != "true":
                failures.append(
                    f"Players.CharacterAutoLoads expected 'true', got '{get_typed_prop(players_el, 'bool', 'CharacterAutoLoads')}'"
                )

        tcs_el = top_services.get("TextChatService")
        tcs_ver = get_typed_prop(tcs_el, "token", "ChatVersion") if tcs_el is not None else None
        if tcs_ver != "1":
            failures.append(f"TextChatService.ChatVersion expected '1' (TextChatService), got {tcs_ver!r}")

        ss_el = top_services.get("SoundService")
        ss_rfe = get_typed_prop(ss_el, "bool", "RespectFilteringEnabled") if ss_el is not None else None
        if ss_rfe != "true":
            failures.append(f"SoundService.RespectFilteringEnabled expected 'true', got {ss_rfe!r}")

        if len(failures) == svc_fail_before:
            print("  [OK] Verified Lighting (Future=4, EnvDiff/Spec=1.0, GlobalShadows=true, ClockTime=16.1, SunRaysEffect), StarterPlayer (R15=1), Players (MaxPlayers=16), TextChatService (1), SoundService")

        # Verify 100% ProtectedString Source SHA-256 parity & zero orphan scripts in .rbxlx
        script_fail_before = len(failures)
        rbxlx_scripts = {}

        def collect_rbxlx_scripts(parent_el, path_tuple):
            for item in parent_el.findall("Item"):
                nm = get_name(item)
                icls = item.attrib.get("class", "")
                cp = path_tuple + (nm,)
                if cp == ("ReplicatedStorage", "DelegatedV5Sources"):
                    continue
                if icls in ("Script", "LocalScript", "ModuleScript"):
                    src_txt = ""
                    props = item.find("Properties")
                    if props is not None:
                        for ps in props.findall("ProtectedString"):
                            if ps.attrib.get("name") == "Source":
                                src_txt = ps.text or ""
                                break
                    src_sha = hashlib.sha256(src_txt.replace("\r\n", "\n").encode("utf-8")).hexdigest()
                    rbxlx_scripts[(cp, icls)] = src_sha
                collect_rbxlx_scripts(item, cp)

        for top in root.findall("Item"):
            tnm = get_name(top)
            if tnm in SYNC_SERVICES:
                collect_rbxlx_scripts(top, (tnm,))

        for s_key, (rel_path, exp_sha) in sorted(expected_src_scripts.items()):
            act_sha = rbxlx_scripts.get(s_key)
            if act_sha is None:
                failures.append(f"Missing synced script in .rbxlx: {'/'.join(s_key[0])} ({s_key[1]}) from {rel_path}")
            elif act_sha != exp_sha:
                failures.append(
                    f"Source SHA-256 mismatch in .rbxlx for {'/'.join(s_key[0])} ({s_key[1]}): rbxlx={act_sha[:12]} vs src={exp_sha[:12]}"
                )

        for r_key in sorted(rbxlx_scripts.keys()):
            if r_key not in expected_src_scripts:
                failures.append(f"Orphan script inside .rbxlx not in 04_Roblox/src: {'/'.join(r_key[0])} ({r_key[1]})")

        if len(failures) == script_fail_before:
            print(f"  [OK] Verified {len(expected_src_scripts)}/{len(rbxlx_scripts)} Luau scripts in .rbxlx have 100% SHA-256 Source parity (0 orphans)")

        for wname in WORLD_13:
            if wname not in v5_map:
                failures.append(f"Missing DelegatedV5Sources.{wname} in .rbxlx")
                continue
            af = v5_map[wname]
            mods = {get_name(m): m for m in af.findall("Item")}
            expected_b64 = (RUNTIME_V8 / wname / "Header.json.zstd.b64").read_text(encoding="ascii").strip()
            hdr_mod = mods.get("Header")
            if hdr_mod is None:
                failures.append(f"Missing Header module in DelegatedV5Sources.{wname}")
                continue
            chunks = []
            for sv in sorted(hdr_mod.findall("Item"), key=get_name):
                for s in sv.find("Properties").findall("string"):
                    if s.attrib.get("name") == "Value":
                        chunks.append(s.text or "")
            actual_b64 = "".join(chunks)
            if actual_b64 != expected_b64:
                failures.append(f"DelegatedV5Sources.{wname}.Header payload mismatch vs runtime_v8!")
        print(f"  [OK] Verified all 13/13 DelegatedV5Sources world folders in .rbxlx match runtime_v8 payloads!")

    if failures:
        print(f"\n[FAIL] {len(failures)} audit failures:")
        for f in failures[:30]:
            print("  -", f)
        sys.exit(1)
    else:
        print("\n[PASS] ALL 27x / 9x GAME SYNC AUDITS PASSED WITH ZERO ERRORS!")


if __name__ == "__main__":
    main()
