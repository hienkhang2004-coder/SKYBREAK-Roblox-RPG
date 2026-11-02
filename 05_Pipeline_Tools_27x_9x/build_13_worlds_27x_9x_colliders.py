"""
Headless Blender Physics Collider Extractor & Compact Luau Generator
for all 13 SKYBREAK 27x / 9x Macro-Scale Worlds.

Modes:
  1. Single-world Blender extraction (invoke via run_blender_safe.py, 1 world per run):
       python.exe run_blender_safe.py build_13_worlds_27x_9x_colliders.py -- --world W1
  2. Sequential 13-world driver (invokes run_blender_safe.py 1 world at a time W1..W13):
       python.exe build_13_worlds_27x_9x_colliders.py --driver-extract-all
  3. Compact Luau module generation (< 185,000 bytes per .lua file, all Part.Size <= 1700 studs):
       python.exe build_13_worlds_27x_9x_colliders.py --generate-lua
"""
import sys
import os
import re
import json
import math
import argparse
import subprocess
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8")

TOOLS_DIR = Path(__file__).resolve().parent
HANDOFF_ROOT = TOOLS_DIR.parent
OUTPUTS_ROOT = HANDOFF_ROOT.parent
CODEX_PYTHON = sys.executable
REF_ROOT = OUTPUTS_ROOT / "SKYBREAK_Argon_Refinement"
RUN_BLENDER_SAFE = REF_ROOT / "run_blender_safe.py"
MANIFEST_PATH = REF_ROOT / "Worlds_27x_9x_Final_Preview" / "SKYBREAK_All13Worlds_27x_9x_Manifest.json"

COORDS_JSON_PATH = TOOLS_DIR / "macro_world_coords_27x_9x.json"
EXTRACTED_JSON_PATH = TOOLS_DIR / "extracted_colliders_27x_9x.json"

SERVICES_DIR = HANDOFF_ROOT / "04_Roblox" / "src" / "ServerScriptService" / "Services"

MAX_PART_SIZE = 1680.0  # Strictly <= 1700.0 (< 1750.0 requirement & < 2048 Roblox limit)
DECK_THICKNESS = 12.0
BRIDGE_THICKNESS = 10.0

SKIP_COL_RE = re.compile(
    r"(COL-00|Archived|RenderOnly|RenderClouds|RenderAtmosphere|Lights|Cameras|Collision)",
    re.I,
)
SKIP_OBJ_RE = re.compile(
    r"(floor_studio|stage|backdrop|shadowcatcher|herobg|^cloud_|_cloud_|collision)",
    re.I,
)
BRIDGE_COL_RE = re.compile(r"(Bridge|Viaduct|Causeway)", re.I)

# Category A: Primary Walkable Island Decks & Piers
PRIMARY_DECK_RE = re.compile(
    r"(_MainDeck|_SlateDeck|_ArmorDeck|_ObsidianDeck|_StoneDeck|_OuterPromenade|"
    r"_SiliconWafer|_OuterRingWalk|_ObsidianMirror|_StoneQuayRing|_QuayRing|"
    r"_SouthPromenade|_FrozenFloor|_BoardingSkyway_\d+|_FingerPier_[0-9.\-]+|"
    r"_CausewayGold_\d+|_HeartIsland|CitadelForecourtEsplanade|CitadelForecourtDeck|_Deck)$"
)
PRIMARY_DECK_EXCL_RE = re.compile(
    r"(SubDeck|SubPlinth|SubBastion|SubFoundation|SubBase|_Sub$|Curb|Parapet|Rim|"
    r"Border|Inlay|CollarDeck|BastionDeck|PodiumDeck|Acropolis_Tier\d+_Deck|"
    r"CitadelForecourtSlab|CitadelForecourtPaving)"
)

WATER_DISC_RE = re.compile(
    r"(Lagoon_TurquoiseBasin|Maelstrom_WaterDisc|Maelstrom_AbyssEye|"
    r"SpiritLake_MirrorWater|Atoll_AbyssWaterDisc|Harbor_WaterBasin)$"
)

COLLAR_FALLBACK_RE = re.compile(r"(_SnowMantle|_PlateauCollar)$")

RING_NAME_RE = re.compile(
    r"(OuterRingWalk|StoneQuayRing|QuayRing|OrbitalDock_MainDeck)$"
)
ELONGATED_PIER_RE = re.compile(
    r"(_BoardingSkyway_\d+|_FingerPier_[0-9.\-]+|_CausewayGold_\d+|"
    r"CitadelForecourtEsplanade|CitadelForecourtDeck)$"
)

# Category B: Bridges / Viaducts / Causeways + Abutment Boulevard Heads
BRIDGE_SURF_RE = re.compile(
    r"(_BoulevardPaving|_BoulevardSlab|_AbutmentDeck|_Paving|_SlateRoad|_StoneRoad|"
    r"_TimberRoad|_SiliconDeck|_SlateDeck|_PearlWalk|_Road|_Slate|_Stone|"
    r"_DeckCore|_GirderCore|_Chassis|_MainHull|_Deck)$"
)
BRIDGE_EXCL_RE = re.compile(
    r"(Rail|Parapet|Kerb|Curb|Wall|Coping|Arch|Pillar|Pier|Corbel|Chain|Cable|"
    r"Tower|Pylon|Lamp|Lantern|Banner|Torii|Stream|Line|Runner|Track|Conduit|Pipe|Trim$)",
    re.I,
)
BRIDGE_GROUP_STRIP_RE = re.compile(
    r"(_BoulevardPaving|_BoulevardSlab|_AbutmentDeck|_Paving|_SlateRoad|_StoneRoad|_TimberRoad|"
    r"_SiliconDeck|_SlateDeck|_PearlWalk|_Road|_Slate|_Stone|_DeckCore|"
    r"_GirderCore|_Chassis|_MainHull|_Deck)$"
)

# Category C: Major Architectural Stepped Terraces
TERRACE_RE = re.compile(
    r"^GEO-(SunCitadel_ConcentricPlinth(\.\d+)?|Acropolis_Tier\d+_Deck|"
    r"Acropolis_Tier3_Step_\d+|CitadelOctTerrace_\d+|CafePodium_Step_\d+|"
    r"Citadel_BastionDeck|CPUSocket_Tier_\d+|CitadelTerrace_\d+|"
    r"VoidKeep_PodiumDeck|CoreZiggurat_Tier_\d+|MiragePeak_MidTerrace|"
    r"MiragePeak_UpperSanctum|MirageShrine_Stylobate)$"
)

# Category D: Solid Vertical Monument Cores (for Solid3DObstacles)
OBST_CORE_RE = re.compile(
    r"(CathedralDrum|CitadelLowerBastion|CafeHall_WarmGlassCore|StormLighthouse_Tower|"
    r"Mansion_MainHall_Wall|HeartUmbralPagoda_Core_0|MiragePeak_BaseMassif|"
    r"Reactor_Core|Reactor_Tower|Reactor_Shaft|VoidKeep_MainKeep|VoidKeep_Tower|"
    r"CommandHall_Walls|CorsairTavern_Walls|CitadelTowerCore|BastionCore)",
    re.I,
)
OBST_FALLBACK_NAME_RE = re.compile(
    r"(Drum|Keep|MainHall_Wall|Core_0|Reactor|TowerShaft|CitadelCore|BastionBase|Cella)",
    re.I,
)
OBST_EXCL_RE = re.compile(
    r"(Cliff|Root|Mantle|Collar|Deck|Plinth|Terrace|Podium|Step|Stair|Ramp|Ring|"
    r"Curb|Rim|Inlay|Circuit|Halo|Roof|Eave|Dome|Arch|Gate|Portal|Pillar|Column|"
    r"Tree|Leaf|Canopy|Crystal|Water|Sheet|Curtain|Mist|Cloud|Plume|Coil|Serpent|"
    r"Dragon|Leviathan|Sail|Bridge|Viaduct|Causeway|Rail|Parapet|Wall_-?\d|Floor|"
    r"Paving|Road|Light|Lantern|Banner|Finial|Trim|Cornice|Belt|Band)",
    re.I,
)


# ---------------------------------------------------------------------------
# 2D Computational Geometry Helpers
# ---------------------------------------------------------------------------
def convex_hull_2d(pts):
    """Monotone chain 2D convex hull on (x, z) points."""
    pts = sorted(set((round(p[0], 3), round(p[1], 3)) for p in pts))
    if len(pts) <= 2:
        return pts

    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])

    lower = []
    for p in pts:
        while len(lower) >= 2 and cross(lower[-2], lower[-1], p) <= 0:
            lower.pop()
        lower.append(p)
    upper = []
    for p in reversed(pts):
        while len(upper) >= 2 and cross(upper[-2], upper[-1], p) <= 0:
            upper.pop()
        upper.append(p)
    return lower[:-1] + upper[:-1]


def min_area_obb_2d(pts_2d):
    """
    Returns (cx, cz, theta, len_u, len_v, obb_area) where:
      u = (cos(theta), sin(theta)) is longitudinal axis (len_u >= len_v),
      v = (-sin(theta), cos(theta)) is transverse axis,
      Roblox CFrame yaw = -theta.
    """
    hull = convex_hull_2d(pts_2d)
    if not hull:
        return 0.0, 0.0, 0.0, 4.0, 4.0, 16.0
    if len(hull) == 1:
        return hull[0][0], hull[0][1], 0.0, 4.0, 4.0, 16.0

    angles = [0.0]
    n = len(hull)
    for i in range(n):
        p0 = hull[i]
        p1 = hull[(i + 1) % n]
        dx = p1[0] - p0[0]
        dz = p1[1] - p0[1]
        if dx * dx + dz * dz > 1e-6:
            angles.append(math.atan2(dz, dx))

    best = None
    for ang in angles:
        ca = math.cos(ang)
        sa = math.sin(ang)
        us = [p[0] * ca + p[1] * sa for p in hull]
        vs = [-p[0] * sa + p[1] * ca for p in hull]
        u0, u1 = min(us), max(us)
        v0, v1 = min(vs), max(vs)
        lu = max(0.5, u1 - u0)
        lv = max(0.5, v1 - v0)
        area = lu * lv
        # Slight preference for axis-aligned when area is virtually identical
        score = area * (0.998 if abs(ang) < 1e-6 else 1.0)
        if best is None or score < best[0]:
            best = (score, ang, u0, u1, v0, v1, area)

    _, theta, u0, u1, v0, v1, area = best
    lu = u1 - u0
    lv = v1 - v0
    uc = 0.5 * (u0 + u1)
    vc = 0.5 * (v0 + v1)
    ca = math.cos(theta)
    sa = math.sin(theta)
    cx = uc * ca - vc * sa
    cz = uc * sa + vc * ca

    # Ensure len_u >= len_v so u is always longitudinal
    if lv > lu:
        theta += 0.5 * math.pi
        lu, lv = lv, lu

    # Normalize theta to (-pi/2, pi/2] since rectangle is 180-deg symmetric; keep u always longitudinal (lu >= lv)
    while theta <= -0.5 * math.pi:
        theta += math.pi
    while theta > 0.5 * math.pi:
        theta -= math.pi
    if abs(theta) < 1e-4:
        theta = 0.0
    elif abs(abs(theta) - 0.5 * math.pi) < 1e-4:
        theta = 0.5 * math.pi

    return cx, cz, theta, lu, lv, area


def obb_along_fixed_theta(pts_2d, theta: float):
    """Computes (cx, cz, lu, lv) of pts_2d projected onto a fixed longitudinal angle theta."""
    ca = math.cos(theta)
    sa = math.sin(theta)
    us = [p[0] * ca + p[1] * sa for p in pts_2d]
    vs = [-p[0] * sa + p[1] * ca for p in pts_2d]
    u0, u1 = min(us), max(us)
    v0, v1 = min(vs), max(vs)
    uc = 0.5 * (u0 + u1)
    vc = 0.5 * (v0 + v1)
    cx = uc * ca - vc * sa
    cz = uc * sa + vc * ca
    return cx, cz, max(1.0, u1 - u0), max(1.0, v1 - v0)


def emit_tiled_obb_blocks(out_list, name_prefix, cx, cz, top_y, thickness, theta, len_u, len_v, slope_ang=0.0):
    """Splits an OBB into <= MAX_PART_SIZE blocks along u and v with +0.4-stud seam overlap (zero gaps)."""
    len_u = max(4.0, float(len_u))
    len_v = max(4.0, float(len_v))
    nu = max(1, math.ceil(len_u / MAX_PART_SIZE))
    nv = max(1, math.ceil(len_v / MAX_PART_SIZE))
    sub_u = len_u / nu
    sub_v = len_v / nv
    ca = math.cos(theta)
    sa = math.sin(theta)
    is_flat_ns = (abs(slope_ang) < 1e-4) and (abs(abs(theta) - 0.5 * math.pi) < 1e-4)
    yaw = 0.0 if (is_flat_ns or abs(theta) < 1e-4) else -theta
    base_cy = top_y - 0.5 * thickness

    idx = 0
    for iu in range(nu):
        du = -0.5 * len_u + (iu + 0.5) * sub_u
        for iv in range(nv):
            dv = -0.5 * len_v + (iv + 0.5) * sub_v
            scx = cx + du * ca - dv * sa
            scz = cz + du * sa + dv * ca
            scy = base_cy + (du * math.tan(slope_ang) if abs(slope_ang) >= 1e-4 else 0.0)
            actual_u = sub_u / math.cos(slope_ang) if abs(slope_ang) >= 1e-4 else sub_u
            if nu > 1:
                actual_u += 0.4
            actual_v = sub_v + (0.4 if nv > 1 else 0.0)
            actual_u = min(MAX_PART_SIZE, actual_u)
            actual_v = min(MAX_PART_SIZE, actual_v)
            out_sx, out_sz = (actual_v, actual_u) if is_flat_ns else (actual_u, actual_v)
            idx += 1
            sfx = f"_{idx}" if (nu * nv > 1) else ""
            out_list.append({
                "shape": "Block",
                "name": f"{name_prefix}{sfx}",
                "pos": [round(scx, 2), round(scy, 2), round(scz, 2)],
                "size": [round(out_sx, 2), round(thickness, 2), round(out_sz, 2)],
                "yaw": round(yaw, 5),
                "slope": round(slope_ang, 5),
                "top_y": round(top_y, 2),
            })


def merge_1d_intervals(segs, max_gap=8.0):
    if not segs:
        return []
    segs = sorted(segs, key=lambda s: s[0])
    merged = [[segs[0][0], segs[0][1]]]
    for a, b in segs[1:]:
        if a <= merged[-1][1] + max_gap:
            if b > merged[-1][1]:
                merged[-1][1] = b
        else:
            merged.append([a, b])
    return merged


def intersect_tris_at_z(tris_2d, z_val):
    """Returns merged X-intervals where 2D triangles (x0,z0,x1,z1,x2,z2) cross z = z_val."""
    segs = []
    for x0, z0, x1, z1, x2, z2 in tris_2d:
        if z_val < min(z0, z1, z2) - 1e-5 or z_val > max(z0, z1, z2) + 1e-5:
            continue
        xs = []
        for ax, az, bx, bz in ((x0, z0, x1, z1), (x1, z1, x2, z2), (x2, z2, x0, z0)):
            if (az <= z_val <= bz) or (bz <= z_val <= az):
                dz = bz - az
                if abs(dz) < 1e-7:
                    xs.extend([ax, bx])
                else:
                    t = (z_val - az) / dz
                    if -1e-5 <= t <= 1.0 + 1e-5:
                        xs.append(ax + t * (bx - ax))
        if len(xs) >= 2:
            xa, xb = min(xs), max(xs)
            if xb - xa > 0.25:
                segs.append((xa, xb))
    return merge_1d_intervals(segs, max_gap=10.0)


def slice_triangles_into_z_blocks(out_list, name_prefix, tris_2d, min_z, max_z, top_y, thickness):
    """
    Slices arbitrary convex or non-convex 2D top-surface triangles (mega-disks > 1680 studs,
    octagons, and crescent promenades) into contiguous <= MAX_PART_SIZE axis-aligned Blocks.
    """
    sz = max_z - min_z
    if sz < 2.0 or not tris_2d:
        return
    n_bands = max(10, math.ceil(sz / 240.0))
    dz = sz / n_bands
    cy = top_y - 0.5 * thickness
    part_idx = 0

    for b in range(n_bands):
        z0 = min_z + b * dz
        z1 = z0 + dz
        z_mid = 0.5 * (z0 + z1)
        # Sample 3 interior scanlines in the band; union nearby intervals per scanline,
        # and intersect/average bounds so curved rims never protrude past circular boundaries.
        s_mid = intersect_tris_at_z(tris_2d, z_mid)
        s_lo = intersect_tris_at_z(tris_2d, z0 + 0.22 * dz)
        s_hi = intersect_tris_at_z(tris_2d, z0 + 0.78 * dz)

        base_intervals = s_mid if s_mid else (s_lo if s_lo else s_hi)
        if not base_intervals:
            continue

        for xa, xb in base_intervals:
            # Refine against s_lo and s_hi if matching interval exists
            matches = [(xa, xb)]
            for other in (s_lo, s_hi):
                for oa, ob in other:
                    if min(xb, ob) - max(xa, oa) > 0.0:
                        matches.append((oa, ob))
            # Average across matching scanlines in the band for smooth, tight fit
            avg_a = sum(m[0] for m in matches) / len(matches)
            avg_b = sum(m[1] for m in matches) / len(matches)
            width_x = avg_b - avg_a
            if width_x < 3.0:
                continue
            nx = max(1, math.ceil(width_x / MAX_PART_SIZE))
            sub_w = width_x / nx
            pad_w = sub_w + (0.4 if nx > 1 else 0.0)
            for ix in range(nx):
                sub_cx = avg_a + (ix + 0.5) * sub_w
                part_idx += 1
                out_list.append({
                    "shape": "Block",
                    "name": f"{name_prefix}_S{part_idx}",
                    "pos": [round(sub_cx, 2), round(cy, 2), round(z_mid, 2)],
                    "size": [round(min(MAX_PART_SIZE, pad_w), 2), round(thickness, 2), round(min(MAX_PART_SIZE, dz + 0.4), 2)],
                    "yaw": 0.0,
                    "slope": 0.0,
                    "top_y": round(top_y, 2),
                })


def emit_annular_ring_blocks(out_list, name_prefix, cx, cz, inner_r, outer_r, top_y, thickness, n_sectors=16):
    """Emits 16 overlapping tangential OBB Blocks forming a solid walkable ring with open interior."""
    inner_r = max(10.0, float(inner_r))
    outer_r = max(inner_r + 12.0, float(outer_r))
    mid_r = 0.5 * (inner_r + outer_r)
    radial_w = (outer_r - inner_r) + 4.0
    chord_l = 2.0 * outer_r * math.tan(math.pi / n_sectors) + 10.0
    for k in range(n_sectors):
        theta = (k + 0.5) * (2.0 * math.pi / n_sectors)
        scx = cx + mid_r * math.cos(theta)
        scz = cz + mid_r * math.sin(theta)
        # Along theta is radial (radial_w), perpendicular to theta is tangential (chord_l)
        if chord_l >= radial_w:
            # Make longitudinal u = tangential direction (theta + pi/2)
            t_ang = theta + 0.5 * math.pi
            while t_ang > 0.5 * math.pi:
                t_ang -= math.pi
            while t_ang <= -0.5 * math.pi:
                t_ang += math.pi
            emit_tiled_obb_blocks(
                out_list, f"{name_prefix}_R{k+1}", scx, scz, top_y, thickness, t_ang, chord_l, radial_w
            )
        else:
            t_ang = theta
            while t_ang > 0.5 * math.pi:
                t_ang -= math.pi
            while t_ang <= -0.5 * math.pi:
                t_ang += math.pi
            emit_tiled_obb_blocks(
                out_list, f"{name_prefix}_R{k+1}", scx, scz, top_y, thickness, t_ang, radial_w, chord_l
            )


# ---------------------------------------------------------------------------
# Mode 1: Single-World Blender Extraction
# ---------------------------------------------------------------------------
def extract_single_world_in_blender(world_code_arg: str):
    import bpy
    from mathutils import Matrix

    T = Matrix((
        (1.0, 0.0, 0.0, 0.0),
        (0.0, 0.0, 1.0, 0.0),
        (0.0, -1.0, 0.0, 0.0),
        (0.0, 0.0, 0.0, 1.0),
    ))

    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    worlds_map = manifest["worlds"]

    matched_code = None
    for wc, winfo in worlds_map.items():
        if wc.upper() == world_code_arg.upper() or winfo["world_name"].lower() == world_code_arg.lower():
            matched_code = wc
            break
    if not matched_code:
        raise ValueError(f"Unknown world '{world_code_arg}'")

    winfo = worlds_map[matched_code]
    world_name = winfo["world_name"]
    tier = winfo["tier"]
    blend_path = Path(winfo["blend_file"])
    if not blend_path.exists():
        raise FileNotFoundError(f"Missing blend file: {blend_path}")

    print(f"[COLLIDER EXTRACT] {matched_code} {world_name} ({tier}) <- {blend_path.name}", flush=True)
    bpy.ops.wm.open_mainfile(filepath=str(blend_path))

    allowed_from_tree = set()
    skipped_from_tree = set()

    def walk_col(col, is_root: bool, parent_skip: bool):
        this_skip = parent_skip
        if not is_root and (col.hide_render or SKIP_COL_RE.search(col.name)):
            this_skip = True
        for o in col.objects:
            if this_skip:
                skipped_from_tree.add(o.name)
            else:
                allowed_from_tree.add(o.name)
        for child in col.children:
            walk_col(child, False, this_skip)

    walk_col(bpy.context.scene.collection, True, False)

    deps = None
    records = []

    for o in bpy.context.scene.objects:
        if o.type != "MESH" or o.hide_render:
            continue
        if o.name in skipped_from_tree and o.name not in allowed_from_tree:
            continue
        if any(c.hide_render or SKIP_COL_RE.search(c.name) for c in o.users_collection):
            continue
        if SKIP_OBJ_RE.search(o.name):
            continue
        if o.data is None or len(o.data.polygons) == 0:
            continue

        col_names = [c.name for c in o.users_collection]
        is_bridge_col = any(bool(BRIDGE_COL_RE.search(cn)) for cn in col_names)
        oname = o.name

        # Quick pre-filter so we only evaluate geometry for candidate decks/bridges/terraces/obstacles
        is_primary_deck = (not is_bridge_col) and bool(PRIMARY_DECK_RE.search(oname)) and not bool(PRIMARY_DECK_EXCL_RE.search(oname))
        is_water_disc = (not is_bridge_col) and bool(WATER_DISC_RE.search(oname))
        is_collar = (not is_bridge_col) and bool(COLLAR_FALLBACK_RE.search(oname))
        is_bridge_surf = is_bridge_col and bool(BRIDGE_SURF_RE.search(oname)) and not bool(BRIDGE_EXCL_RE.search(oname))
        is_terrace = (not is_bridge_col) and bool(TERRACE_RE.search(oname))
        is_obst_cand = (not is_bridge_col) and (
            bool(OBST_CORE_RE.search(oname))
            or (bool(OBST_FALLBACK_NAME_RE.search(oname)) and not bool(OBST_EXCL_RE.search(oname)))
        )

        if not (is_primary_deck or is_water_disc or is_collar or is_bridge_surf or is_terrace or is_obst_cand):
            continue

        need_eval = any(
            m.show_render and m.type in ("MIRROR", "ARRAY", "SOLIDIFY", "BOOLEAN")
            for m in o.modifiers
        )
        if need_eval:
            if deps is None:
                deps = bpy.context.evaluated_depsgraph_get()
            ev = o.evaluated_get(deps)
            me = ev.to_mesh()
        else:
            ev = None
            me = o.data

        if me is None or len(me.vertices) == 0 or len(me.polygons) == 0:
            if ev is not None and me is not None:
                ev.to_mesh_clear()
            continue

        mw = T @ o.matrix_world
        verts_rbx = []
        min_x = min_y = min_z = 1e18
        max_x = max_y = max_z = -1e18
        for v in me.vertices:
            rc = mw @ v.co
            vx, vy, vz = float(rc.x), float(rc.y), float(rc.z)
            verts_rbx.append((vx, vy, vz))
            if vx < min_x: min_x = vx
            if vy < min_y: min_y = vy
            if vz < min_z: min_z = vz
            if vx > max_x: max_x = vx
            if vy > max_y: max_y = vy
            if vz > max_z: max_z = vz

        top_y = max_y
        bot_y = min_y
        sx = max_x - min_x
        sy = max_y - min_y
        sz = max_z - min_z
        cx = 0.5 * (min_x + max_x)
        cz = 0.5 * (min_z + max_z)
        poly_count = len(me.polygons)

        top_verts_3d = []
        top_tris_2d = []
        top_tri_area = 0.0

        if is_primary_deck or is_water_disc or is_collar or is_bridge_surf or is_terrace:
            y_cut = top_y - (3.5 if is_collar else 1.8)
            top_verts_3d = [p for p in verts_rbx if p[1] >= y_cut]
            if len(top_verts_3d) < 3:
                top_verts_3d = sorted(verts_rbx, key=lambda p: p[1], reverse=True)[:max(4, len(verts_rbx) // 2)]

            me.calc_loop_triangles()
            for tri in me.loop_triangles:
                i0, i1, i2 = tri.vertices
                p0, p1, p2 = verts_rbx[i0], verts_rbx[i1], verts_rbx[i2]
                if max(p0[1], p1[1], p2[1]) < y_cut:
                    continue
                # Check upward normal in Roblox space (note T has det = +1: x'=x, y'=z, z'=-y -> det = 1)
                ax, ay, az = p1[0] - p0[0], p1[1] - p0[1], p1[2] - p0[2]
                bx, by, bz = p2[0] - p0[0], p2[1] - p0[1], p2[2] - p0[2]
                nx = ay * bz - az * by
                ny = az * bx - ax * bz
                nz = ax * by - ay * bx
                nlen = math.sqrt(nx * nx + ny * ny + nz * nz)
                if nlen > 1e-6 and (ny / nlen) > 0.35:
                    top_tris_2d.append((p0[0], p0[2], p1[0], p1[2], p2[0], p2[2]))
                    top_tri_area += 0.5 * abs(ny)

        if ev is not None and me is not None:
            ev.to_mesh_clear()

        records.append({
            "name": oname,
            "cols": col_names,
            "polys": poly_count,
            "min": (min_x, min_y, min_z),
            "max": (max_x, max_y, max_z),
            "size": (sx, sy, sz),
            "center": (cx, 0.5 * (min_y + max_y), cz),
            "top_y": top_y,
            "bot_y": bot_y,
            "is_primary_deck": is_primary_deck,
            "is_water_disc": is_water_disc,
            "is_collar": is_collar,
            "is_bridge_surf": is_bridge_surf,
            "is_terrace": is_terrace,
            "is_obst_cand": is_obst_cand,
            "top_verts_3d": top_verts_3d,
            "top_tris_2d": top_tris_2d,
            "top_tri_area": top_tri_area,
        })

    walkables = []

    def decompose_horizontal_slab(rec, thickness: float, tag_prefix: str):
        oname = rec["name"]
        sx, sy, sz = rec["size"]
        cx, _, cz = rec["center"]
        min_x, _, min_z = rec["min"]
        max_x, _, max_z = rec["max"]
        top_y = rec["top_y"]
        polys = rec["polys"]
        pts_2d = [(p[0], p[2]) for p in rec["top_verts_3d"]]
        tris_2d = rec["top_tris_2d"]
        tri_area = rec["top_tri_area"]

        clean_name = re.sub(r"[^A-Za-z0-9_]", "_", oname.replace("GEO-", ""))

        # 1. Elongated / angled piers & rectangular esplanades
        if ELONGATED_PIER_RE.search(oname):
            ocx, ocz, theta, lu, lv, _ = min_area_obb_2d(pts_2d)
            emit_tiled_obb_blocks(walkables, f"{tag_prefix}_{clean_name}", ocx, ocz, top_y, thickness, theta, lu, lv)
            return

        # 2. Annular hollow rings
        radii = [math.hypot(px - cx, pz - cz) for px, pz in pts_2d] if pts_2d else []
        if radii:
            r_min = min(radii)
            r_max = max(radii)
        else:
            r_min, r_max = 0.0, 0.5 * max(sx, sz)

        is_ring = bool(RING_NAME_RE.search(oname)) or (
            r_min > 85.0
            and r_min < 0.93 * r_max
            and abs(sx - sz) <= 0.12 * max(sx, sz)
            and tri_area < 0.72 * (math.pi * r_max * r_max)
        )
        if is_ring:
            emit_annular_ring_blocks(
                walkables, f"{tag_prefix}_{clean_name}", cx, cz, r_min, r_max, top_y, thickness, n_sectors=16
            )
            return

        # 3. Solid circular disk <= MAX_PART_SIZE
        circle_area = 0.25 * math.pi * sx * sz
        is_round_disk = (
            polys >= 28
            and max(sx, sz) <= MAX_PART_SIZE
            and abs(sx - sz) <= 0.08 * max(sx, sz)
            and (tri_area >= 0.68 * circle_area or len(tris_2d) == 0)
            and "SouthPromenade" not in oname
        )
        if is_round_disk:
            diam = min(MAX_PART_SIZE, round(0.5 * (sx + sz), 2))
            walkables.append({
                "shape": "Cylinder",
                "name": f"{tag_prefix}_{clean_name}",
                "pos": [round(cx, 2), round(top_y - 0.5 * thickness, 2), round(cz, 2)],
                "size": [round(thickness, 2), diam, diam],
                "yaw": 0.0,
                "slope": 0.0,
                "top_y": round(top_y, 2),
            })
            return

        # 4. Compact rectangular / square OBB (where top triangles fill >= 89% of OBB)
        ocx, ocz, theta, lu, lv, obb_area = min_area_obb_2d(pts_2d)
        if obb_area > 1.0 and tri_area >= 0.89 * obb_area and "SouthPromenade" not in oname:
            emit_tiled_obb_blocks(walkables, f"{tag_prefix}_{clean_name}", ocx, ocz, top_y, thickness, theta, lu, lv)
            return

        # 5. Mega-disks (> 1680 studs), Octagons, Chamfered Wafers, and Non-Convex Crescents
        if tris_2d:
            slice_triangles_into_z_blocks(
                walkables, f"{tag_prefix}_{clean_name}", tris_2d, min_z, max_z, top_y, thickness
            )
        else:
            emit_tiled_obb_blocks(walkables, f"{tag_prefix}_{clean_name}", ocx, ocz, top_y, thickness, theta, lu, lv)

    # Category A1 & A2: Primary Decks + Water Discs
    primary_centers = []
    for rec in records:
        if rec["is_primary_deck"] or rec["is_water_disc"]:
            decompose_horizontal_slab(rec, DECK_THICKNESS, "Deck")
            if rec["is_primary_deck"]:
                primary_centers.append((rec["center"][0], rec["center"][2], max(rec["size"][0], rec["size"][2])))
        elif rec["is_terrace"]:
            primary_centers.append((rec["center"][0], rec["center"][2], max(rec["size"][0], rec["size"][2])))

    # Category A3: Fallback Distant-Island / Spur Collars (only if no primary deck/terrace covers that island)
    for rec in records:
        if not rec["is_collar"]:
            continue
        cx, _, cz = rec["center"]
        csize = max(rec["size"][0], rec["size"][2])
        if csize < 60.0:
            continue
        covered = False
        for px, pz, psize in primary_centers:
            if math.hypot(cx - px, cz - pz) <= max(360.0, 0.52 * max(csize, psize)):
                covered = True
                break
        if not covered:
            decompose_horizontal_slab(rec, DECK_THICKNESS, "Collar")

    # Category B: Bridges / Viaducts / Causeways + Abutment Boulevard Heads
    bridge_groups = {}
    for rec in records:
        if not rec["is_bridge_surf"]:
            continue
        gkey = BRIDGE_GROUP_STRIP_RE.sub("", rec["name"])
        bridge_groups.setdefault(gkey, []).append(rec)

    # First pass: record parent bridge longitudinal angles so HeadA/HeadB align & extend along bridge axis
    parent_bridge_thetas = {}
    for gkey, grecs in sorted(bridge_groups.items()):
        if re.search(r"_Head[AB]$", gkey):
            continue
        pts_all = [(p[0], p[2]) for r in grecs for p in r["top_verts_3d"]]
        if len(pts_all) >= 2:
            _, _, b_theta, _, _, _ = min_area_obb_2d(pts_all)
            parent_bridge_thetas[gkey] = b_theta

    for gkey, grecs in sorted(bridge_groups.items()):
        # Prefer structural deck's top_y when paired with thin +0.03..0.18 paving overlay
        struct_ys = [
            r["top_y"] for r in grecs
            if re.search(r"(_Deck|_DeckCore|_GirderCore|_Chassis|_MainHull|_BoulevardSlab|_AbutmentDeck)$", r["name"])
        ]
        if struct_ys:
            group_top_y = max(struct_ys)
        else:
            group_top_y = min(r["top_y"] for r in grecs)

        merged_pts_3d = []
        for r in grecs:
            for p in r["top_verts_3d"]:
                if abs(p[1] - group_top_y) <= 6.0:
                    merged_pts_3d.append(p)
        if len(merged_pts_3d) < 3:
            for r in grecs:
                merged_pts_3d.extend(r["top_verts_3d"])

        pts_2d = [(p[0], p[2]) for p in merged_pts_3d]
        is_head = bool(re.search(r"_Head[AB]$", gkey))
        parent_gkey = re.sub(r"_Head[AB]$", "", gkey)
        if is_head and parent_gkey in parent_bridge_thetas:
            theta = parent_bridge_thetas[parent_gkey]
            ocx, ocz, lu, lv = obb_along_fixed_theta(pts_2d, theta)
        else:
            ocx, ocz, theta, lu, lv, _ = min_area_obb_2d(pts_2d)

        # Extend HeadA/HeadB +96.0 studs longitudinally (+48 each end) across snow/chamfer aprons into island decks
        lu_padded = lu + (96.0 if is_head else 12.0)
        lv_padded = max(10.0, lv)

        # Check longitudinal slope along u = (cos(theta), sin(theta))
        ca, sa = math.cos(theta), math.sin(theta)
        u_ys = [((p[0] - ocx) * ca + (p[2] - ocz) * sa, p[1]) for p in merged_pts_3d]
        slope_ang = 0.0
        if len(u_ys) >= 4 and lu > 15.0:
            u_ys.sort(key=lambda t: t[0])
            k_end = max(2, len(u_ys) // 6)
            y_lo = sum(t[1] for t in u_ys[:k_end]) / k_end
            y_hi = sum(t[1] for t in u_ys[-k_end:]) / k_end
            u_lo = sum(t[0] for t in u_ys[:k_end]) / k_end
            u_hi = sum(t[0] for t in u_ys[-k_end:]) / k_end
            if abs(y_hi - y_lo) > 2.5 and (u_hi - u_lo) > 10.0:
                slope_ang = math.atan2(y_hi - y_lo, u_hi - u_lo)
                group_top_y = 0.5 * (y_lo + y_hi)

        clean_bname = re.sub(r"[^A-Za-z0-9_]", "_", gkey.replace("GEO-", ""))
        emit_tiled_obb_blocks(
            walkables, f"Bridge_{clean_bname}", ocx, ocz, group_top_y, BRIDGE_THICKNESS, theta, lu_padded, lv_padded, slope_ang
        )

    # Category C: Stepped Walkable Terraces
    for rec in records:
        if rec["is_terrace"]:
            decompose_horizontal_slab(rec, DECK_THICKNESS, "Terrace")

    # World-specific guaranteed gameplay pads:
    if world_name == "WestGardenPirateBastion":
        # Ensure EmberforgeNorthCitadel local (0, 47.5, 1065) harbor-mouth citadel point has solid ground
        walkables.append({
            "shape": "Cylinder",
            "name": "Deck_HarborMouthCitadelPad",
            "pos": [0.0, round(47.5 - 0.5 * DECK_THICKNESS, 2), 1065.0],
            "size": [DECK_THICKNESS, 180.0, 180.0],
            "yaw": 0.0,
            "slope": 0.0,
            "top_y": 47.5,
        })
    elif world_name == "MicrochipAwakeningRaidLab":
        # 5 procedural RaidSpirePlatforms at local (0, 124..140, 120..-185)
        spire_pts = [
            (0.0, 124.0, 120.0),
            (0.0, 128.0, 45.0),
            (0.0, 132.0, -30.0),
            (0.0, 136.0, -105.0),
            (0.0, 140.0, -185.0),
        ]
        for idx, (px, py, pz) in enumerate(spire_pts, start=1):
            walkables.append({
                "shape": "Block",
                "name": f"Terrace_RaidSpirePlatform_{idx}",
                "pos": [px, round(py - 2.0, 2), pz],
                "size": [24.0, 4.0, 24.0],
                "yaw": 0.0,
                "slope": 0.0,
                "top_y": py,
            })

    # Category D: Solid Vertical Monument Obstacles
    raw_obst = []
    primary_obst = [r for r in records if r["is_obst_cand"] and OBST_CORE_RE.search(r["name"])]
    cand_pool = primary_obst if primary_obst else [r for r in records if r["is_obst_cand"]]

    for rec in cand_pool:
        sx, sy, sz = rec["size"]
        cx, cy, cz = rec["center"]
        if sy < 28.0 or rec["bot_y"] < 40.0:
            continue
        if max(sx, sz) < 30.0 or max(sx, sz) > 3200.0:
            continue
        # Shrink XZ by 0.84 so outer walkways, stairs, and colonnades remain completely clear
        bsx = max(16.0, sx * 0.84)
        bsz = max(16.0, sz * 0.84)
        bsy = min(sy, 900.0)
        bcy = rec["bot_y"] + 0.5 * bsy
        raw_obst.append((bsx * bsz * bsy, cx, bcy, cz, bsx, bsy, bsz, rec["name"]))

    raw_obst.sort(key=lambda t: t[0], reverse=True)
    max_obst = 18 if tier == "MainMap_27x" else 10
    obstacles = []
    for _, cx, bcy, cz, bsx, bsy, bsz, oname in raw_obst[:max_obst]:
        nx = max(1, math.ceil(bsx / MAX_PART_SIZE))
        ny = max(1, math.ceil(bsy / MAX_PART_SIZE))
        nz = max(1, math.ceil(bsz / MAX_PART_SIZE))
        sub_x, sub_y, sub_z = bsx / nx, bsy / ny, bsz / nz
        for ix in range(nx):
            ox = cx - 0.5 * bsx + (ix + 0.5) * sub_x
            for iy in range(ny):
                oy = bcy - 0.5 * bsy + (iy + 0.5) * sub_y
                for iz in range(nz):
                    oz = cz - 0.5 * bsz + (iz + 0.5) * sub_z
                    obstacles.append([
                        round(ox, 2),
                        round(oy, 2),
                        round(oz, 2),
                        round(min(MAX_PART_SIZE, sub_x), 2),
                        round(min(MAX_PART_SIZE, sub_y), 2),
                        round(min(MAX_PART_SIZE, sub_z), 2),
                        oname,
                    ])

    # Hard assertion: every part size <= 1700 studs
    max_walk_dim = 0.0
    for w in walkables:
        md = max(w["size"])
        if md > max_walk_dim:
            max_walk_dim = md
        if md > 1700.0:
            raise AssertionError(f"Walkable {w['name']} in {world_name} exceeds 1700 studs: {w['size']}")
    for ob in obstacles:
        md = max(ob[3], ob[4], ob[5])
        if md > 1700.0:
            raise AssertionError(f"Obstacle {ob[6]} in {world_name} exceeds 1700 studs: {ob[3:6]}")

    PARENT_SCRATCH.mkdir(parents=True, exist_ok=True)
    if EXTRACTED_JSON_PATH.exists():
        all_data = json.loads(EXTRACTED_JSON_PATH.read_text(encoding="utf-8"))
    else:
        all_data = {}

    all_data[matched_code] = {
        "world_code": matched_code,
        "world_name": world_name,
        "tier": tier,
        "blend_file": str(blend_path),
        "walkable_count": len(walkables),
        "obstacle_count": len(obstacles),
        "max_part_dim": round(max_walk_dim, 2),
        "walkables": walkables,
        "obstacles": obstacles,
    }
    EXTRACTED_JSON_PATH.write_text(json.dumps(all_data, indent=2), encoding="utf-8")
    print(
        f"[COLLIDER OK] {matched_code:3s} {world_name:30s} | walkables={len(walkables):3d} | "
        f"obstacles={len(obstacles):2d} | max_dim={max_walk_dim:.2f} studs",
        flush=True,
    )


# ---------------------------------------------------------------------------
# Mode 2: Sequential 13-World Driver (1 world per run_blender_safe.py call)
# ---------------------------------------------------------------------------
def run_driver_extract_all():
    script_path = Path(__file__).resolve()
    for i in range(1, 14):
        wc = f"W{i}"
        cmd = [
            CODEX_PYTHON,
            str(RUN_BLENDER_SAFE),
            str(script_path),
            "--",
            "--world",
            wc,
        ]
        print(f"\n>>> Running Blender collider extraction for {wc}...", flush=True)
        subprocess.run(cmd, check=True)
    print("\n[ALL 13 WORLDS EXTRACTED SUCCESSFULLY]", flush=True)


# ---------------------------------------------------------------------------
# Mode 3: Pure-Python Gameplay Clearance Filtering & Compact Luau Generation
# ---------------------------------------------------------------------------
def collect_local_gameplay_points(coords: dict) -> dict:
    """
    Collects all local-space gameplay points per world_name -> list of (lx, expected_floor_y, lz, label).
    Used to guarantee:
      1. Zero obstacle boxes within +-26 studs XZ (> 18 required) of any gameplay coordinate.
      2. Zero elevated terrace roofs (> expected_floor_y + 4.2) shadowing any DeckY/platform coordinate.
    """
    local_pts = {}

    def add_pt(asset_name, lx, exp_y, lz, label):
        if asset_name in ("ZiolesGachaShrine", "AetherShrines"):
            return
        local_pts.setdefault(asset_name, []).append((float(lx), float(exp_y), float(lz), label))

    # 1. Realms (3 main + 5 expansion)
    for rname, r in coords["realms"].items():
        asset = r.get("Asset", rname)
        ox, oy, oz = r["Origin"]
        exp_local_y = r["DeckY"] - oy
        sp = r["Spawn"]
        add_pt(asset, sp[0] - ox, exp_local_y, sp[2] - oz, f"realms.{rname}.Spawn")
        if "SkybornSpawnPartPos" in r:
            sbp = r["SkybornSpawnPartPos"]
            add_pt(asset, sbp[0] - ox, exp_local_y, sbp[2] - oz, f"realms.{rname}.SkybornSpawn")
        for iname, ip in r.get("Islands", {}).items():
            add_pt(asset, ip[0] - ox, exp_local_y, ip[2] - oz, f"realms.{rname}.Islands.{iname}")
        if "Boss" in r:
            bp = r["Boss"]["Spawn"]
            pp = r["Boss"]["PlayerPos"]
            add_pt(asset, bp[0] - ox, exp_local_y, bp[2] - oz, f"realms.{rname}.Boss.Spawn")
            add_pt(asset, pp[0] - ox, exp_local_y, pp[2] - oz, f"realms.{rname}.Boss.PlayerPos")
        if "WorldGateExit" in r:
            wg = r["WorldGateExit"]
            add_pt(asset, wg[0] - ox, exp_local_y, wg[2] - oz, f"realms.{rname}.WorldGateExit")

    # 2. Fast travel islands -> map back to owning main map or streaming 9x world
    stream_list = coords["grand_sky_islands_streaming"]
    main_origins = {
        "GoldenSky": coords["realms"]["GoldenSky"]["Origin"],
        "FrozenCyber": coords["realms"]["FrozenCyber"]["Origin"],
        "ShadowRealm": coords["realms"]["ShadowRealm"]["Origin"],
    }
    for ft_name, ft in coords["fast_travel_islands"].items():
        wx, wy, wz = ft["Pos"]
        dy = ft["DeckY"]
        # Find closest streaming island within 3200 studs XZ, else main realm
        matched_stream = None
        for st in stream_list:
            sox, soy, soz = st["Origin"]
            if math.hypot(wx - sox, wz - soz) < 3200.0:
                matched_stream = st
                break
        if matched_stream:
            sox, soy, soz = matched_stream["Origin"]
            add_pt(matched_stream["Asset"], wx - sox, dy - soy, wz - soz, f"fast_travel.{ft_name}")
        else:
            mrealm = ft["Realm"]
            mox, moy, moz = main_origins[mrealm]
            add_pt(mrealm, wx - mox, dy - moy, wz - moz, f"fast_travel.{ft_name}")

    # 3. Landmarks and gameplay
    for k, blk in coords["landmarks_and_gameplay"].items():
        if k in ("ZiolesGachaShrine", "AetherShrines"):
            continue
        ox, oy, oz = blk.get("Origin", [0.0, 0.0, 0.0])
        deck_local = blk.get("DeckY", 50.5 if k == "GoldenSky" else 54.1)

        def walk_dict(prefix, d):
            for sk, sv in d.items():
                if sk in ("Origin", "DeckY", "Radius", "SafeRadius", "DangerSeaRadius") or "Water" in sk:
                    continue
                if isinstance(sv, list) and len(sv) == 3 and all(isinstance(n, (int, float)) for n in sv):
                    ey = (sv[1] - oy) if "RaidSpire" in sk else deck_local
                    add_pt(k, sv[0] - ox, ey, sv[2] - oz, f"{prefix}.{sk}")
                elif isinstance(sv, list) and len(sv) > 0 and isinstance(sv[0], list):
                    for idx, item in enumerate(sv):
                        ey = (item[1] - oy) if "RaidSpire" in sk else deck_local
                        add_pt(k, item[0] - ox, ey, item[2] - oz, f"{prefix}.{sk}[{idx}]")
                elif isinstance(sv, dict):
                    walk_dict(f"{prefix}.{sk}", sv)

        walk_dict(k, blk)

    return local_pts


def carve_elevated_walkables_around_points(walkables: list, pts: list, pocket_half: float = 16.0) -> list:
    """
    Ensures no elevated walkable part (top_y > expected_floor_y + 4.2) overhangs a lower-floor
    gameplay coordinate (lx, expected_floor_y, lz). Carves a clean 2*pocket_half pocket out of
    any overlapping elevated Block/Cylinder so downward raycasts hit the exact DeckY/platform floor.
    """
    current = list(walkables)
    for lx, exp_y, lz, _ in pts:
        next_list = []
        for w in current:
            if w["top_y"] <= exp_y + 4.2:
                next_list.append(w)
                continue

            if w["shape"] == "Cylinder":
                cx, cy, cz = w["pos"]
                h, d, _ = w["size"]
                r = 0.5 * d
                if math.hypot(lx - cx, lz - cz) > r + pocket_half:
                    next_list.append(w)
                    continue
                # Convert overlapping elevated cylinder into 10 chord blocks, then carve pocket
                n_b = 10
                dz = (2.0 * r) / n_b
                temp_blocks = []
                for bi in range(n_b):
                    z0 = cz - r + bi * dz
                    z1 = z0 + dz
                    zm = 0.5 * (z0 + z1)
                    z_near = min(abs(z0 - cz), abs(z1 - cz))
                    if (z0 - cz) * (z1 - cz) <= 0:
                        z_near = 0.0
                    hc = math.sqrt(max(0.0, r * r - z_near * z_near))
                    if hc > 2.0:
                        temp_blocks.append({
                            "shape": "Block",
                            "name": f"{w['name']}_C{bi+1}",
                            "pos": [cx, cy, round(zm, 2)],
                            "size": [round(2.0 * hc, 2), h, round(dz, 2)],
                            "yaw": 0.0,
                            "slope": 0.0,
                            "top_y": w["top_y"],
                        })
                next_list.extend(carve_elevated_walkables_around_points(temp_blocks, [(lx, exp_y, lz, "")], pocket_half))
                continue

            # Oriented or axis-aligned Block
            cx, cy, cz = w["pos"]
            sx, sy, sz = w["size"]
            yaw = w.get("yaw", 0.0)
            slope = w.get("slope", 0.0)
            # In Roblox CFrame.Angles(0, yaw, 0): local X = (cos(yaw), 0, -sin(yaw)), local Z = (sin(yaw), 0, cos(yaw))
            cyaw = math.cos(yaw)
            syaw = math.sin(yaw)
            dx = lx - cx
            dz = lz - cz
            lu_pt = dx * cyaw - dz * syaw
            lv_pt = dx * syaw + dz * cyaw
            hu = 0.5 * sx
            hv = 0.5 * sz

            if abs(lu_pt) >= hu + pocket_half or abs(lv_pt) >= hv + pocket_half or abs(slope) > 1e-4:
                next_list.append(w)
                continue

            # Carve [lu_pt - pocket_half, lu_pt + pocket_half] x [lv_pt - pocket_half, lv_pt + pocket_half]
            pu0 = max(-hu, lu_pt - pocket_half)
            pu1 = min(hu, lu_pt + pocket_half)
            pv0 = max(-hv, lv_pt - pocket_half)
            pv1 = min(hv, lv_pt + pocket_half)

            sub_rects = []
            # Left strip: [-hu, pu0] x [-hv, hv]
            if pu0 - (-hu) >= 4.0:
                sub_rects.append((-hu, pu0, -hv, hv))
            # Right strip: [pu1, hu] x [-hv, hv]
            if hu - pu1 >= 4.0:
                sub_rects.append((pu1, hu, -hv, hv))
            # Bottom center strip: [pu0, pu1] x [-hv, pv0]
            if (pu1 - pu0) >= 4.0 and (pv0 - (-hv)) >= 4.0:
                sub_rects.append((pu0, pu1, -hv, pv0))
            # Top center strip: [pu0, pu1] x [pv1, hv]
            if (pu1 - pu0) >= 4.0 and (hv - pv1) >= 4.0:
                sub_rects.append((pu0, pu1, pv1, hv))

            for si, (u0, u1, v0, v1) in enumerate(sub_rects, start=1):
                uc = 0.5 * (u0 + u1)
                vc = 0.5 * (v0 + v1)
                ncx = cx + uc * cyaw + vc * syaw
                ncz = cz - uc * syaw + vc * cyaw
                next_list.append({
                    "shape": "Block",
                    "name": f"{w['name']}_P{si}",
                    "pos": [round(ncx, 2), cy, round(ncz, 2)],
                    "size": [round(u1 - u0, 2), sy, round(v1 - v0, 2)],
                    "yaw": yaw,
                    "slope": 0.0,
                    "top_y": w["top_y"],
                })
        current = next_list
    return current


def filter_obstacles_against_points(obstacles: list, pts: list, clearance_xz: float = 26.0) -> list:
    """Drops any obstacle box within +-clearance_xz (> 18 required) of any gameplay coordinate."""
    kept = []
    for ob in obstacles:
        ox, oy, oz, osx, osy, osz = ob[0], ob[1], ob[2], ob[3], ob[4], ob[5]
        hx = 0.5 * osx + clearance_xz
        hz = 0.5 * osz + clearance_xz
        blocked = False
        for lx, _, lz, _ in pts:
            if abs(lx - ox) <= hx and abs(lz - oz) <= hz:
                blocked = True
                break
        if not blocked:
            kept.append([ox, oy, oz, osx, osy, osz])
    return kept


def fmt_num(v: float, ndigits: int = 2) -> str:
    rv = round(float(v), ndigits)
    if abs(rv) < 1e-6:
        return "0"
    if abs(rv - round(rv)) < 1e-6:
        return str(int(round(rv)))
    s = f"{rv:.{ndigits}f}".rstrip("0").rstrip(".")
    return s if s else "0"


def format_cyl_lua_table(cyls: list, indent: str = "\t") -> str:
    lines = []
    for w in cyls:
        cx, cy, cz = w["pos"]
        h, d, _ = w["size"]
        lines.append(f"{indent}{{{fmt_num(cx)},{fmt_num(cy)},{fmt_num(cz)},{fmt_num(h)},{fmt_num(d)}}},")
    return "\n".join(lines)


def format_blk_lua_table(blks: list, indent: str = "\t") -> str:
    lines = []
    for w in blks:
        cx, cy, cz = w["pos"]
        sx, sy, sz = w["size"]
        yaw = w.get("yaw", 0.0)
        slope = w.get("slope", 0.0)
        if abs(yaw) < 1e-4 and abs(slope) < 1e-4:
            lines.append(
                f"{indent}{{{fmt_num(cx)},{fmt_num(cy)},{fmt_num(cz)},{fmt_num(sx)},{fmt_num(sy)},{fmt_num(sz)}}},"
            )
        elif abs(slope) < 1e-4:
            lines.append(
                f"{indent}{{{fmt_num(cx)},{fmt_num(cy)},{fmt_num(cz)},{fmt_num(sx)},{fmt_num(sy)},{fmt_num(sz)},{fmt_num(yaw, 4)}}},"
            )
        else:
            lines.append(
                f"{indent}{{{fmt_num(cx)},{fmt_num(cy)},{fmt_num(cz)},{fmt_num(sx)},{fmt_num(sy)},{fmt_num(sz)},{fmt_num(yaw, 4)},{fmt_num(slope, 4)}}},"
            )
    return "\n".join(lines)


def build_main_realm_collision_lua(realm_name: str, walkables: list) -> str:
    cyls = [w for w in walkables if w["shape"] == "Cylinder"]
    blks = [w for w in walkables if w["shape"] == "Block"]
    cyl_rows = format_cyl_lua_table(cyls, "\t")
    blk_rows = format_blk_lua_table(blks, "\t")

    return f"""-- Auto-generated 27x Macro-Scale Physics Collider Module for {realm_name}
-- All Part.Size components strictly <= 1700 studs (< 2048 Roblox limit).
local M = {{}}

local CYL_ROT = CFrame.Angles(0, 0, math.pi * 0.5)

local CYL = {{
{cyl_rows}
}}

local BLK = {{
{blk_rows}
}}

function M.Build(parent, origin)
	parent = parent or workspace:FindFirstChild("{realm_name}") or workspace
	local folder = parent:FindFirstChild("{realm_name}_Collision")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "{realm_name}_Collision"
		folder.Parent = parent
	else
		folder:ClearAllChildren()
	end

	local hasOrigin = (typeof(origin) == "Vector3")
	local baseCF = hasOrigin and CFrame.new(origin) or nil
	local idx = 0

	for _, c in ipairs(CYL) do
		idx += 1
		local p = Instance.new("Part")
		p.Name = "{realm_name}_Floor_" .. idx
		p.Shape = Enum.PartType.Cylinder
		p.Anchored = true
		p.CanCollide = true
		p.CanQuery = true
		p.CanTouch = true
		p.CastShadow = false
		p.Transparency = 1
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Size = Vector3.new(c[4], c[5], c[5])
		local lcf = CFrame.new(c[1], c[2], c[3]) * CYL_ROT
		p.CFrame = hasOrigin and (baseCF * lcf) or lcf
		p.Parent = folder
	end

	for _, b in ipairs(BLK) do
		idx += 1
		local p = Instance.new("Part")
		p.Name = "{realm_name}_Floor_" .. idx
		p.Shape = Enum.PartType.Block
		p.Anchored = true
		p.CanCollide = true
		p.CanQuery = true
		p.CanTouch = true
		p.CastShadow = false
		p.Transparency = 1
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Size = Vector3.new(b[4], b[5], b[6])
		local lcf = CFrame.new(b[1], b[2], b[3])
		local yaw = b[7]
		local slp = b[8]
		if yaw and yaw ~= 0 then
			lcf = lcf * CFrame.Angles(0, yaw, 0)
		end
		if slp and slp ~= 0 then
			lcf = lcf * CFrame.Angles(0, 0, slp)
		end
		p.CFrame = hasOrigin and (baseCF * lcf) or lcf
		p.Parent = folder
	end

	folder:SetAttribute("ColliderCount", idx)
	return folder
end

M.CYL = CYL
M.BLK = BLK

setmetatable(M, {{
	__call = function(_, parent, origin)
		return M.Build(parent, origin)
	end,
}})

return M
"""


def build_solid3d_world_colliders_lua(
    main_boxes_world: list,
    island_assets_filtered: dict,
    coords: dict,
) -> str:
    main_rows = "\n".join(
        f"\t{{{fmt_num(b[0])},{fmt_num(b[1])},{fmt_num(b[2])},{fmt_num(b[3])},{fmt_num(b[4])},{fmt_num(b[5])}}},"
        for b in main_boxes_world
    )

    asset_chunks = []
    # Include ZiolesGachaShrine asset for the 2 Sea 1 Sanctuary Shrines (DeckY = 50.0, Origin.Y = 50 -> local top_y = 0.0 -> cy = -6.0)
    asset_chunks.append(
        """\tZiolesGachaShrine = {
\t\toffY = 0,
\t\tcyl = {
\t\t\t{0,-6,0,12,270},
\t\t},
\t\tblk = {},
\t\tobst = {},
\t},"""
    )

    ordered_9x = coords["notes"]["expansion_worlds_9x"]
    for aname in ordered_9x:
        ainfo = island_assets_filtered[aname]
        cyl_s = format_cyl_lua_table(ainfo["cyl"], "\t\t\t")
        blk_s = format_blk_lua_table(ainfo["blk"], "\t\t\t")
        obst_s = "\n".join(
            f"\t\t\t{{{fmt_num(o[0])},{fmt_num(o[1])},{fmt_num(o[2])},{fmt_num(o[3])},{fmt_num(o[4])},{fmt_num(o[5])}}},"
            for o in ainfo["obst"]
        )
        asset_chunks.append(
            f"""\t{aname} = {{
\t\toffY = 0,
\t\tcyl = {{
{cyl_s}
\t\t}},
\t\tblk = {{
{blk_s}
\t\t}},
\t\tobst = {{
{obst_s}
\t\t}},
\t}},"""
        )
    assets_lua = "\n".join(asset_chunks)

    placement_lines = []
    for st in coords["grand_sky_islands_streaming"]:
        ox, oy, oz = st["Origin"]
        placement_lines.append(
            f'\t{{ Name = "{st["Name"]}", Asset = "{st["Asset"]}", Origin = Vector3.new({fmt_num(ox)}, {fmt_num(oy)}, {fmt_num(oz)}) }},'
        )
    for exp_name in ("VerdantCrown", "EmberforgeWastes", "AbyssalTides", "ChronosBastion", "VeilsEnd"):
        er = coords["realms"][exp_name]
        ox, oy, oz = er["Origin"]
        placement_lines.append(
            f'\t{{ Name = "{exp_name}", Asset = "{er["Asset"]}", Origin = Vector3.new({fmt_num(ox)}, {fmt_num(oy)}, {fmt_num(oz)}), ExpansionRealm = "{exp_name}" }},'
        )
    placements_lua = "\n".join(placement_lines)

    return f"""-- Auto-generated 27x / 9x Macro-Scale Solid3DWorldColliders Module
-- Populates GrandSkyIslands_Collision (10 9x streaming worlds + 2 Sea 1 shrines),
-- all 5 Expansion Realm <RealmName>_Collision folders in-place, and Solid3DObstacles.
-- All Part.Size components strictly <= 1700 studs (< 2048 Roblox limit).
local M = {{}}

local CYL_ROT = CFrame.Angles(0, 0, math.pi * 0.5)

M.MAIN_BOXES = {{
{main_rows}
}}

M.ISLAND_ASSETS = {{
{assets_lua}
}}

M.ISLAND_PLACEMENTS = {{
{placements_lua}
}}

local function sampleAssetFloorY(data, lx, lz)
	local bestY = nil
	for _, c in ipairs(data.cyl) do
		local dx = lx - c[1]
		local dz = lz - c[3]
		local r = math.max(0.5, c[5] * 0.5 - 1.0)
		if (dx * dx + dz * dz) <= (r * r) then
			local ty = c[2] + c[4] * 0.5
			if not bestY or ty > bestY then
				bestY = ty
			end
		end
	end
	for _, b in ipairs(data.blk) do
		local dx = lx - b[1]
		local dz = lz - b[3]
		local yaw = b[7] or 0
		local lu, lv
		if yaw ~= 0 then
			local cy = math.cos(yaw)
			local sy = math.sin(yaw)
			lu = dx * cy - dz * sy
			lv = dx * sy + dz * cy
		else
			lu = dx
			lv = dz
		end
		local hx = math.max(0.5, b[4] * 0.5 - 1.0)
		local hz = math.max(0.5, b[6] * 0.5 - 1.0)
		if math.abs(lu) <= hx and math.abs(lv) <= hz then
			local slp = b[8] or 0
			local ty = b[2] + b[5] * 0.5 + (slp ~= 0 and (lu * math.tan(slp)) or 0)
			if not bestY or ty > bestY then
				bestY = ty
			end
		end
	end
	return bestY
end

local function isBlockedInAsset(data, lx, gy, lz, clear)
	for _, o in ipairs(data.obst) do
		local ox, oy, oz, osx, osy, osz = o[1], o[2], o[3], o[4], o[5], o[6]
		if math.abs(lx - ox) < (osx * 0.5 + clear) and math.abs(lz - oz) < (osz * 0.5 + clear) then
			if not gy or ((oy + osy * 0.5) > gy + 1.0 and (oy - osy * 0.5) < gy + 25.0) then
				return true
			end
		end
	end
	return false
end

function M.IsBlockedByMainBox(x, y, z, minClearance)
	local clear = tonumber(minClearance) or 3.5
	for _, b in ipairs(M.MAIN_BOXES) do
		local bx, by, bz, bsx, bsy, bsz = b[1], b[2], b[3], b[4], b[5], b[6]
		if math.abs(x - bx) < (bsx * 0.5 + clear) and math.abs(z - bz) < (bsz * 0.5 + clear) then
			if not y or ((by + bsy * 0.5) > y + 1.0 and (by - bsy * 0.5) < y + 25.0) then
				return true
			end
		end
	end
	for _, isl in ipairs(M.ISLAND_PLACEMENTS) do
		local dx = x - isl.Origin.X
		local dz = z - isl.Origin.Z
		if math.abs(dx) < 2850 and math.abs(dz) < 2850 then
			local data = M.ISLAND_ASSETS[isl.Asset]
			if data then
				local baseY = isl.Origin.Y - (data.offY or 0)
				local ly = y and (y - baseY) or nil
				if isBlockedInAsset(data, dx, ly, dz, clear) then
					return true
				end
			end
		end
	end
	return false
end

function M.IsBlockedXZ(x, z, minClearance, y)
	return M.IsBlockedByMainBox(x, y, z, minClearance)
end

function M.SnapToOpenGround(pos, refFloorY, heightOffset, minClearance)
	local hOff = tonumber(heightOffset) or 0
	local clear = tonumber(minClearance) or 3.2
	if heightOffset == nil and minClearance == nil and tonumber(refFloorY) and tonumber(refFloorY) <= 18 and math.abs(pos.Y - tonumber(refFloorY)) > 25 then
		clear = tonumber(refFloorY)
		refFloorY = nil
	end

	for _, isl in ipairs(M.ISLAND_PLACEMENTS) do
		local dx = pos.X - isl.Origin.X
		local dz = pos.Z - isl.Origin.Z
		if math.abs(dx) < 2850 and math.abs(dz) < 2850 then
			local data = M.ISLAND_ASSETS[isl.Asset]
			if data then
				local baseY = isl.Origin.Y - (data.offY or 0)
				local ly = sampleAssetFloorY(data, dx, dz)
				if ly and not isBlockedInAsset(data, dx, ly, dz, clear) then
					local fy = baseY + ly
					return Vector3.new(pos.X, fy + hOff, pos.Z), fy, true
				end
				for _, rad in ipairs({ 8, 16, 28, 44, 68, 96 }) do
					for step = 0, 11 do
						local ang = (step / 12) * math.pi * 2
						local sx = dx + math.cos(ang) * rad
						local sz = dz + math.sin(ang) * rad
						local sly = sampleAssetFloorY(data, sx, sz)
						if sly and not isBlockedInAsset(data, sx, sly, sz, clear) then
							local fy = baseY + sly
							return Vector3.new(isl.Origin.X + sx, fy + hOff, isl.Origin.Z + sz), fy, true
						end
					end
				end
			end
		end
	end
	local fallbackY = tonumber(refFloorY) or pos.Y
	return Vector3.new(pos.X, fallbackY + hOff, pos.Z), fallbackY, false
end

local function stampAssetWalkables(targetFolder, prefix, origin, data)
	local baseY = origin.Y - (data.offY or 0)
	local baseCF = CFrame.new(origin.X, baseY, origin.Z)
	local count = 0

	for _, c in ipairs(data.cyl) do
		count += 1
		local p = Instance.new("Part")
		p.Name = prefix .. "_Floor_" .. count
		p.Shape = Enum.PartType.Cylinder
		p.Anchored = true
		p.CanCollide = true
		p.CanQuery = true
		p.CanTouch = true
		p.CastShadow = false
		p.Transparency = 1
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Size = Vector3.new(c[4], c[5], c[5])
		p.CFrame = baseCF * (CFrame.new(c[1], c[2], c[3]) * CYL_ROT)
		p.Parent = targetFolder
	end

	for _, b in ipairs(data.blk) do
		count += 1
		local p = Instance.new("Part")
		p.Name = prefix .. "_Floor_" .. count
		p.Shape = Enum.PartType.Block
		p.Anchored = true
		p.CanCollide = true
		p.CanQuery = true
		p.CanTouch = true
		p.CastShadow = false
		p.Transparency = 1
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Size = Vector3.new(b[4], b[5], b[6])
		local lcf = CFrame.new(b[1], b[2], b[3])
		local yaw = b[7]
		local slp = b[8]
		if yaw and yaw ~= 0 then
			lcf = lcf * CFrame.Angles(0, yaw, 0)
		end
		if slp and slp ~= 0 then
			lcf = lcf * CFrame.Angles(0, 0, slp)
		end
		p.CFrame = baseCF * lcf
		p.Parent = targetFolder
	end

	return count
end

function M.Build()
	local gsi = workspace:FindFirstChild("GrandSkyIslands")
	if gsi then
		for _, ch in ipairs(gsi:GetChildren()) do
			if ch.Name:sub(1, 10) == "Collision_" then
				ch:Destroy()
			end
		end
	end

	local colFolder = workspace:FindFirstChild("GrandSkyIslands_Collision")
	if not colFolder then
		colFolder = Instance.new("Folder")
		colFolder.Name = "GrandSkyIslands_Collision"
		colFolder.Parent = workspace
	else
		colFolder:ClearAllChildren()
	end

	-- Clear all 5 Expansion Realm collision folders in-place (preserving Folder instances in floors)
	local expFolders = {{}}
	for _, expName in ipairs({{ "VerdantCrown", "EmberforgeWastes", "AbyssalTides", "ChronosBastion", "VeilsEnd" }}) do
		local expModel = workspace:FindFirstChild(expName)
		if not expModel then
			expModel = Instance.new("Model")
			expModel.Name = expName
			expModel.Parent = workspace
		end
		local expCol = expModel:FindFirstChild(expName .. "_Collision")
		if not expCol then
			expCol = Instance.new("Folder")
			expCol.Name = expName .. "_Collision"
			expCol.Parent = expModel
		else
			expCol:ClearAllChildren()
		end
		expFolders[expName] = expCol
	end

	local totalWalkables = 0
	for _, isl in ipairs(M.ISLAND_PLACEMENTS) do
		local data = M.ISLAND_ASSETS[isl.Asset]
		if data then
			local dest = isl.ExpansionRealm and expFolders[isl.ExpansionRealm] or colFolder
			totalWalkables += stampAssetWalkables(dest, isl.Name, isl.Origin, data)
		end
	end
	colFolder:SetAttribute("WalkableColliderCount", totalWalkables)

	-- Rebuild Solid3DObstacles
	local oldObst = workspace:FindFirstChild("Solid3DObstacles")
	if oldObst then
		oldObst:Destroy()
	end
	local obstFolder = Instance.new("Folder")
	obstFolder.Name = "Solid3DObstacles"
	obstFolder.Parent = workspace

	local idx = 0
	for _, b in ipairs(M.MAIN_BOXES) do
		idx += 1
		local p = Instance.new("Part")
		p.Name = "Solid3D_" .. idx
		p.Anchored = true
		p.CanCollide = true
		p.CanQuery = true
		p.CanTouch = false
		p.CastShadow = false
		p.Transparency = 1
		p.Size = Vector3.new(b[4], b[5], b[6])
		p.Position = Vector3.new(b[1], b[2], b[3])
		p.Parent = obstFolder
	end

	for _, isl in ipairs(M.ISLAND_PLACEMENTS) do
		local data = M.ISLAND_ASSETS[isl.Asset]
		if data then
			local baseY = isl.Origin.Y - (data.offY or 0)
			for _, o in ipairs(data.obst) do
				idx += 1
				local p = Instance.new("Part")
				p.Name = "Solid3D_" .. idx
				p.Anchored = true
				p.CanCollide = true
				p.CanQuery = true
				p.CanTouch = false
				p.CastShadow = false
				p.Transparency = 1
				p.Size = Vector3.new(o[4], o[5], o[6])
				p.Position = Vector3.new(isl.Origin.X + o[1], baseY + o[2], isl.Origin.Z + o[3])
				p.Parent = obstFolder
			end
		end
	end

	obstFolder:SetAttribute("SolidColliderCount", idx)
	return obstFolder
end

return M
"""


def run_generate_lua():
    if not EXTRACTED_JSON_PATH.exists():
        raise FileNotFoundError(f"Missing extracted JSON: {EXTRACTED_JSON_PATH}")

    extracted = json.loads(EXTRACTED_JSON_PATH.read_text(encoding="utf-8"))
    coords = json.loads(COORDS_JSON_PATH.read_text(encoding="utf-8"))
    by_world = {v["world_name"]: v for v in extracted.values()}
    if len(by_world) != 13:
        raise RuntimeError(f"Expected 13 worlds in {EXTRACTED_JSON_PATH}, found {len(by_world)}: {list(by_world.keys())}")

    local_pts_map = collect_local_gameplay_points(coords)

    # 1. Generate the 3 Main 27x Map Collision Modules + World-Space MAIN_BOXES
    main_specs = [
        ("GoldenSky", "GoldenSkyCollision.lua"),
        ("FrozenCyber", "FrozenCyberCollision.lua"),
        ("ShadowRealm", "ShadowRealmCollision.lua"),
    ]
    main_boxes_world = []

    for rname, fname in main_specs:
        wdata = by_world[rname]
        pts = local_pts_map.get(rname, [])
        carved_walkables = carve_elevated_walkables_around_points(wdata["walkables"], pts, pocket_half=16.0)
        lua_src = build_main_realm_collision_lua(rname, carved_walkables)
        out_path = SERVICES_DIR / fname
        out_path.write_text(lua_src, encoding="utf-8")
        bsize = out_path.stat().st_size
        print(f"[LUA OK] {fname:30s} | parts={len(carved_walkables):4d} | bytes={bsize:7d} (< 185000)", flush=True)
        if bsize >= 185000:
            raise AssertionError(f"{fname} exceeds 185,000 bytes: {bsize}")

        ox, oy, oz = coords["realms"][rname]["Origin"]
        clean_obst = filter_obstacles_against_points(wdata["obstacles"], pts, clearance_xz=26.0)
        for o in clean_obst:
            main_boxes_world.append([
                round(ox + o[0], 2),
                round(oy + o[1], 2),
                round(oz + o[2], 2),
                o[3],
                o[4],
                o[5],
            ])

    # 2. Filter all 10 9x Expansion Worlds & Generate Solid3DWorldColliders.lua
    island_assets_filtered = {}
    total_9x_parts = 0
    for aname in coords["notes"]["expansion_worlds_9x"]:
        wdata = by_world[aname]
        pts = local_pts_map.get(aname, [])
        carved_walkables = carve_elevated_walkables_around_points(wdata["walkables"], pts, pocket_half=16.0)
        clean_obst = filter_obstacles_against_points(wdata["obstacles"], pts, clearance_xz=26.0)
        cyls = [w for w in carved_walkables if w["shape"] == "Cylinder"]
        blks = [w for w in carved_walkables if w["shape"] == "Block"]
        total_9x_parts += len(cyls) + len(blks)
        island_assets_filtered[aname] = {
            "cyl": cyls,
            "blk": blks,
            "obst": clean_obst,
        }

    solid_src = build_solid3d_world_colliders_lua(main_boxes_world, island_assets_filtered, coords)
    solid_path = SERVICES_DIR / "Solid3DWorldColliders.lua"
    solid_path.write_text(solid_src, encoding="utf-8")
    sbsize = solid_path.stat().st_size
    print(
        f"[LUA OK] {'Solid3DWorldColliders.lua':30s} | 9x_asset_parts={total_9x_parts:4d} | "
        f"main_obst={len(main_boxes_world):2d} | bytes={sbsize:7d} (< 185000)",
        flush=True,
    )
    if sbsize >= 185000:
        raise AssertionError(f"Solid3DWorldColliders.lua exceeds 185,000 bytes: {sbsize}")


def parse_args():
    argv = sys.argv[1:]
    if "--" in argv:
        argv = argv[argv.index("--") + 1:]
    parser = argparse.ArgumentParser(description="SKYBREAK 13-World 27x/9x Physics Collider Extractor & Luau Builder")
    parser.add_argument("--world", help="Extract single world W1..W13 inside headless Blender")
    parser.add_argument("--driver-extract-all", action="store_true", help="Invoke run_blender_safe.py 1 world at a time for W1..W13")
    parser.add_argument("--generate-lua", action="store_true", help="Generate all 4 Luau collider modules from extracted JSON")
    return parser.parse_args(argv)


def main():
    args = parse_args()
    if args.world:
        extract_single_world_in_blender(args.world)
    elif args.driver_extract_all:
        run_driver_extract_all()
    elif args.generate_lua:
        run_generate_lua()
    else:
        raise SystemExit("Specify --world W1..W13, --driver-extract-all, or --generate-lua")


if __name__ == "__main__":
    main()
