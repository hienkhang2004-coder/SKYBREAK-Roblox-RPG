"""
Headless Blender V8 Tiled Mesh Exporter for all 13 SKYBREAK 27x / 9x Macro-Scale Worlds.
Solves Roblox EditableMesh 2,048-stud bounding box limit via:
  Step A: Recursive longest-edge midpoint splitting of oversized triangles (<= 750 studs)
  Step B: Top-down recursive AABB KD-splitting per material (<= 18,000 tris & <= 1,750 studs)

Invoke 1 world per run via run_blender_safe.py:
  python.exe run_blender_safe.py export_all_13_worlds_27x_9x_v8.py -- --world W1
"""
import sys
import os
import re
import json
import math
import base64
import hashlib
import argparse
import subprocess
from pathlib import Path

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8")

import bpy
from mathutils import Matrix, Vector

try:
    import zstandard as zstd
    HAS_ZSTD = True
    CCTX = zstd.ZstdCompressor(level=12)
except ImportError:
    HAS_ZSTD = False
    CCTX = None

CODEX_PYTHON = r"C:/Users/khang/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe"
REF_ROOT = Path(r"C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Argon_Refinement")
MANIFEST_PATH = REF_ROOT / "Worlds_27x_9x_Final_Preview" / "SKYBREAK_All13Worlds_27x_9x_Manifest.json"
OUT_ROOT = Path(r"C:/Users/khang/Documents/Codex/2026-10-22/new-chat/outputs/SKYBREAK_Antigravity_Handoff/06_Antigravity_Work/runtime_v8")

# Exact Blender -> Roblox transform: rbx = (x_bl, z_bl, -y_bl), scale = 1.0, offset = (0,0,0)
T = Matrix(((1.0, 0.0, 0.0, 0.0),
            (0.0, 0.0, 1.0, 0.0),
            (0.0, -1.0, 0.0, 0.0),
            (0.0, 0.0, 0.0, 1.0)))

# Strict collection & object filters (keep waterfalls, distant islands, portal islands, all trees!)
SKIP_COL_RE = re.compile(
    r"(COL-00|Archived|RenderOnly|RenderClouds|RenderAtmosphere|Lights|Cameras|Collision)",
    re.I,
)
SKIP_OBJ_RE = re.compile(
    r"(floor_studio|stage|backdrop|shadowcatcher|herobg|^cloud_|_cloud_|collision)",
    re.I,
)
SKIP_MAT_RE = re.compile(r"(floor_studio|stage|backdrop|shadowcatcher)", re.I)

# Protect horizontal walkable decks/plazas/bridges (< 500 tris) from decimation
PROTECT_DECK_RE = re.compile(
    r"(deck|plaza|promenade|wafer|ringwalk|quay|mirror|terrace|plinth|podium|platform|bridge|viaduct|causeway|road|paving|step|stair|ramp|collar|waterdisc|basin)",
    re.I,
)

TRUE_GLOW_RE = re.compile(
    r"(crystal|portal|neon|plasma|rune|coreglow|laser|voidfx|lava|magma|energycore)",
    re.I,
)
NON_GLOW_RE = re.compile(
    r"(gold|marble|stone|rock|cliff|leaf|foliage|tree|grass|wood|roof|wall|floor|tile|pillar|stair|brick|hull|sail|sand|snow|ice|cloud|foam|water|plaza|banner|trim|arch)",
    re.I,
)

# Guard against DelegatedV5Renderer character FX cage skip filter
RENDERER_FX_SKIP_SUBSTRS = (
    "elementalfx", "holocyanfx", "brassgoldfx", "compassgoldfx", "tempestfx",
    "godhumangoldfx", "kicyanfx", "cosmicgoldfx", "aethervioletfx",
    "overdrivemagentafx", "plasmafx", "riftmagentafx", "soulfirefx",
    "mat_kael_fx_", "mat_lyra_fx_", "griddivider",
)

MAX_TRI_SPAN = 748.0     # <= 750.0 studs per triangle after midpoint split
MAX_CHUNK_SPAN = 1748.0  # <= 1750.0 studs per MeshXXX chunk
MAX_CHUNK_TRIS = 18000


def sanitize_env_mat_name(mat_name: str) -> str:
    low = mat_name.lower()
    if (low.startswith("mat_") and low.endswith("fx")) or any(s in low for s in RENDERER_FX_SKIP_SUBSTRS):
        return mat_name + "_Env"
    if low in ("sg_solarenergy", "mat-ts-lightning", "mat-tsf-lightning"):
        return mat_name + "_Env"
    if "mat_elem" in low:
        return mat_name.replace("mat_elem", "mat_world_elem").replace("MAT_Elem", "MAT_WorldElem")
    return mat_name


def sample_material_color(ps):
    if not ps:
        return [0.65, 0.65, 0.65, 1.0]
    default_c = (
        [float(x) for x in ps.inputs["Base Color"].default_value]
        if "Base Color" in ps.inputs
        else [0.65, 0.65, 0.65, 1.0]
    )
    if (
        abs(default_c[0] - 0.8) < 0.015
        and abs(default_c[1] - 0.8) < 0.015
        and abs(default_c[2] - 0.8) < 0.015
        and "Base Color" in ps.inputs
    ):
        inp = ps.inputs["Base Color"]
        if inp.is_linked:
            fn = inp.links[0].from_node
            if fn.type == "VALTORGB" and len(fn.color_ramp.elements) > 0:
                els = fn.color_ramp.elements
                n = len(els)
                return [
                    sum(e.color[0] for e in els) / n,
                    sum(e.color[1] for e in els) / n,
                    sum(e.color[2] for e in els) / n,
                    1.0,
                ]
            for sock in fn.inputs:
                if sock.is_linked and sock.links[0].from_node.type == "VALTORGB":
                    els = sock.links[0].from_node.color_ramp.elements
                    if len(els) > 0:
                        n = len(els)
                        return [
                            sum(e.color[0] for e in els) / n,
                            sum(e.color[1] for e in els) / n,
                            sum(e.color[2] for e in els) / n,
                            1.0,
                        ]
    return default_c


def extract_material_info(mat, mat_name: str) -> dict:
    ps = (
        next((n for n in mat.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
        if mat and mat.node_tree
        else None
    )
    c_lin = sample_material_color(ps)
    m_val = float(ps.inputs["Metallic"].default_value) if ps and "Metallic" in ps.inputs else 0.0
    r_val = float(ps.inputs["Roughness"].default_value) if ps and "Roughness" in ps.inputs else 0.5
    em_strength = (
        float(ps.inputs["Emission Strength"].default_value)
        if ps and "Emission Strength" in ps.inputs
        else 0.0
    )
    em_lin = (
        [float(x) for x in ps.inputs["Emission Color"].default_value]
        if ps and "Emission Color" in ps.inputs
        else [0.0, 0.0, 0.0, 1.0]
    )
    is_true_glow = bool(TRUE_GLOW_RE.search(mat_name)) and not bool(NON_GLOW_RE.search(mat_name))
    if not is_true_glow or max(em_lin[0], em_lin[1], em_lin[2]) < 0.08:
        em_strength = 0.0
        em_lin = [0.0, 0.0, 0.0, 1.0]
    else:
        em_strength = min(1.2, em_strength)

    peak_lin = max(c_lin[0], c_lin[1], c_lin[2])
    if peak_lin > 0.52:
        target_lin = 0.52 + (peak_lin - 0.52) * 0.22
        sc = target_lin / peak_lin
        c_lin = [c_lin[0] * sc, c_lin[1] * sc, c_lin[2] * sc, c_lin[3]]

    alpha_val = float(ps.inputs["Alpha"].default_value) if ps and "Alpha" in ps.inputs else 1.0
    safe_name = sanitize_env_mat_name(mat_name)
    return {
        "name": safe_name,
        "color_linear": [round(x, 4) for x in c_lin],
        "alpha": round(alpha_val, 4),
        "metalness": round(m_val, 4),
        "roughness": round(r_val, 4),
        "emission_linear": [round(x, 4) for x in em_lin],
        "emission_strength": round(em_strength, 4),
        "maps": {},
    }


def collect_allowed_objects() -> list:
    """Walk scene collection tree so parent collection skip flags propagate to child collections."""
    allowed_From_tree = set()
    skipped_From_tree = set()

    def walk_col(col, is_root: bool, parent_skip: bool):
        this_skip = parent_skip
        if not is_root:
            if col.hide_render or SKIP_COL_RE.search(col.name):
                this_skip = True
        for o in col.objects:
            if this_skip:
                skipped_From_tree.add(o.name)
            else:
                allowed_From_tree.add(o.name)
        for child in col.children:
            walk_col(child, False, this_skip)

    walk_col(bpy.context.scene.collection, True, False)

    kept = []
    for o in bpy.context.scene.objects:
        if o.type != "MESH" or o.hide_render:
            continue
        if o.name in skipped_From_tree and o.name not in allowed_From_tree:
            continue
        if any(c.hide_render or SKIP_COL_RE.search(c.name) for c in o.users_collection):
            continue
        if SKIP_OBJ_RE.search(o.name):
            continue
        if o.data is None or len(o.data.polygons) == 0:
            continue
        kept.append(o)
    return kept


def interp_mid(pa, pb, na, nb, uva, uvb):
    pm = (
        round(0.5 * (pa[0] + pb[0]), 3),
        round(0.5 * (pa[1] + pb[1]), 3),
        round(0.5 * (pa[2] + pb[2]), 3),
    )
    nx = na[0] + nb[0]
    ny = na[1] + nb[1]
    nz = na[2] + nb[2]
    nl = math.sqrt(nx * nx + ny * ny + nz * nz)
    if nl > 1e-8:
        nm = (round(nx / nl, 3), round(ny / nl, 3), round(nz / nl, 3))
    else:
        nm = na
    uvm = (round(0.5 * (uva[0] + uvb[0]), 3), round(0.5 * (uva[1] + uvb[1]), 3))
    return pm, nm, uvm


def split_oversized_triangle(p0, p1, p2, n0, n1, n2, uv0, uv1, uv2, ob_name: str, out_list: list, depth: int = 0):
    """Step A: Recursively split triangle along longest 3D edge while max(dx, dy, dz) > MAX_TRI_SPAN."""
    dx = max(p0[0], p1[0], p2[0]) - min(p0[0], p1[0], p2[0])
    dy = max(p0[1], p1[1], p2[1]) - min(p0[1], p1[1], p2[1])
    dz = max(p0[2], p1[2], p2[2]) - min(p0[2], p1[2], p2[2])
    if (dx <= MAX_TRI_SPAN and dy <= MAX_TRI_SPAN and dz <= MAX_TRI_SPAN) or depth >= 12:
        out_list.append((p0, p1, p2, n0, n1, n2, uv0, uv1, uv2, ob_name))
        return

    d01 = (p0[0] - p1[0]) ** 2 + (p0[1] - p1[1]) ** 2 + (p0[2] - p1[2]) ** 2
    d12 = (p1[0] - p2[0]) ** 2 + (p1[1] - p2[1]) ** 2 + (p1[2] - p2[2]) ** 2
    d20 = (p2[0] - p0[0]) ** 2 + (p2[1] - p0[1]) ** 2 + (p2[2] - p0[2]) ** 2

    if d01 >= d12 and d01 >= d20:
        pm, nm, uvm = interp_mid(p0, p1, n0, n1, uv0, uv1)
        split_oversized_triangle(p0, pm, p2, n0, nm, n2, uv0, uvm, uv2, ob_name, out_list, depth + 1)
        split_oversized_triangle(pm, p1, p2, nm, n1, n2, uvm, uv1, uv2, ob_name, out_list, depth + 1)
    elif d12 >= d20:
        pm, nm, uvm = interp_mid(p1, p2, n1, n2, uv1, uv2)
        split_oversized_triangle(p0, p1, pm, n0, n1, nm, uv0, uv1, uvm, ob_name, out_list, depth + 1)
        split_oversized_triangle(p0, pm, p2, n0, nm, n2, uv0, uvm, uv2, ob_name, out_list, depth + 1)
    else:
        pm, nm, uvm = interp_mid(p2, p0, n2, n0, uv2, uv0)
        split_oversized_triangle(p0, p1, pm, n0, n1, nm, uv0, uv1, uvm, ob_name, out_list, depth + 1)
        split_oversized_triangle(pm, p1, p2, nm, n1, n2, uvm, uv1, uv2, ob_name, out_list, depth + 1)


def compute_tris_bounds(tris: list):
    min_x = min_y = min_z = 1e18
    max_x = max_y = max_z = -1e18
    for t in tris:
        p0, p1, p2 = t[0], t[1], t[2]
        x0, y0, z0 = p0
        x1, y1, z1 = p1
        x2, y2, z2 = p2
        if x0 < min_x: min_x = x0
        if x1 < min_x: min_x = x1
        if x2 < min_x: min_x = x2
        if x0 > max_x: max_x = x0
        if x1 > max_x: max_x = x1
        if x2 > max_x: max_x = x2

        if y0 < min_y: min_y = y0
        if y1 < min_y: min_y = y1
        if y2 < min_y: min_y = y2
        if y0 > max_y: max_y = y0
        if y1 > max_y: max_y = y1
        if y2 > max_y: max_y = y2

        if z0 < min_z: min_z = z0
        if z1 < min_z: min_z = z1
        if z2 < min_z: min_z = z2
        if z0 > max_z: max_z = z0
        if z1 > max_z: max_z = z1
        if z2 > max_z: max_z = z2
    return (min_x, max_x, min_y, max_y, min_z, max_z)


def kd_split_triangles(tris: list, out_chunks: list):
    """Step B: Top-down recursive spatial-midpoint AABB KD-split until len(tris) <= 18000 and max(dx, dy, dz) <= 1748.0."""
    if not tris:
        return
    min_x, max_x, min_y, max_y, min_z, max_z = compute_tris_bounds(tris)
    dx = max_x - min_x
    dy = max_y - min_y
    dz = max_z - min_z
    if len(tris) <= 1 or (len(tris) <= MAX_CHUNK_TRIS and dx <= MAX_CHUNK_SPAN and dy <= MAX_CHUNK_SPAN and dz <= MAX_CHUNK_SPAN):
        out_chunks.append([tris, min_x, max_x, min_y, max_y, min_z, max_z])
        return

    if dx >= dy and dx >= dz:
        axis = 0
        mid_sum3 = 1.5 * (min_x + max_x)
    elif dy >= dz:
        axis = 1
        mid_sum3 = 1.5 * (min_y + max_y)
    else:
        axis = 2
        mid_sum3 = 1.5 * (min_z + max_z)

    left = []
    right = []
    for t in tris:
        if (t[0][axis] + t[1][axis] + t[2][axis]) < mid_sum3:
            left.append(t)
        else:
            right.append(t)

    if not left or not right:
        tris_sorted = sorted(tris, key=lambda t: t[0][axis] + t[1][axis] + t[2][axis])
        mid = len(tris_sorted) // 2
        left = tris_sorted[:mid]
        right = tris_sorted[mid:]

    kd_split_triangles(left, out_chunks)
    kd_split_triangles(right, out_chunks)


def merge_compatible_chunks(chunks: list) -> list:
    """Greedily pack spatially adjacent same-material chunks whose union stays <= 1748.0 studs and <= 18000 tris."""
    if len(chunks) <= 1:
        return chunks
    chunks_sorted = sorted(
        chunks,
        key=lambda c: (
            int((c[1] + c[2]) * 0.5 // 850.0),
            int((c[5] + c[6]) * 0.5 // 850.0),
            int((c[3] + c[4]) * 0.5 // 850.0),
        ),
    )
    bins = []
    for c in chunks_sorted:
        ctris, x0, x1, y0, y1, z0, z1 = c
        clen = len(ctris)
        merged = False
        for b in bins:
            if len(b[0]) + clen > MAX_CHUNK_TRIS:
                continue
            nx0 = x0 if x0 < b[1] else b[1]
            nx1 = x1 if x1 > b[2] else b[2]
            if (nx1 - nx0) > MAX_CHUNK_SPAN:
                continue
            ny0 = y0 if y0 < b[3] else b[3]
            ny1 = y1 if y1 > b[4] else b[4]
            if (ny1 - ny0) > MAX_CHUNK_SPAN:
                continue
            nz0 = z0 if z0 < b[5] else b[5]
            nz1 = z1 if z1 > b[6] else b[6]
            if (nz1 - nz0) > MAX_CHUNK_SPAN:
                continue
            b[0].extend(ctris)
            b[1], b[2], b[3], b[4], b[5], b[6] = nx0, nx1, ny0, ny1, nz0, nz1
            merged = True
            break
        if not merged:
            bins.append([list(ctris), x0, x1, y0, y1, z0, z1])
    return bins


def build_mesh_chunk_dict(chunk_name: str, mat_info: dict, tris: list):
    vertices = []
    v_lookup = {}
    triangles = []
    normals = []
    uvs = []
    source_parts = set()

    for p0, p1, p2, n0, n1, n2, uv0, uv1, uv2, ob_name in tris:
        i0 = v_lookup.get(p0)
        if i0 is None:
            i0 = len(vertices)
            v_lookup[p0] = i0
            vertices.append([p0[0], p0[1], p0[2]])
        i1 = v_lookup.get(p1)
        if i1 is None:
            i1 = len(vertices)
            v_lookup[p1] = i1
            vertices.append([p1[0], p1[1], p1[2]])
        i2 = v_lookup.get(p2)
        if i2 is None:
            i2 = len(vertices)
            v_lookup[p2] = i2
            vertices.append([p2[0], p2[1], p2[2]])

        if i0 == i1 or i1 == i2 or i2 == i0:
            continue

        triangles.append([i0, i1, i2])
        normals.append([
            [n0[0], n0[1], n0[2]],
            [n1[0], n1[1], n1[2]],
            [n2[0], n2[1], n2[2]],
        ])
        uvs.append([
            [uv0[0], uv0[1]],
            [uv1[0], uv1[1]],
            [uv2[0], uv2[1]],
        ])
        if len(source_parts) < 24:
            source_parts.add(ob_name)

    if not triangles:
        return None

    return {
        "name": chunk_name,
        "role": "Environment",
        "material": mat_info,
        "vertices": vertices,
        "weights": [],
        "triangles": triangles,
        "normals": normals,
        "uvs": uvs,
        "source_parts": sorted(source_parts)[:20],
    }


def write_json_and_zstd(path: Path, obj):
    raw_bytes = json.dumps(obj, separators=(",", ":")).encode("utf-8")
    path.write_bytes(raw_bytes)
    if HAS_ZSTD:
        comp = CCTX.compress(raw_bytes)
        b64 = base64.b64encode(comp).decode("ascii")
        path.with_name(path.name + ".zstd.b64").write_text(b64, encoding="utf-8")


def compress_folder_via_codex_python(folder: Path):
    """Fallback compressor using Codex runtime Python if Blender's embedded Python lacks zstandard."""
    helper = (
        "import sys, base64, zstandard as zstd\n"
        "from pathlib import Path\n"
        "cctx = zstd.ZstdCompressor(level=12)\n"
        "d = Path(sys.argv[1])\n"
        "for p in sorted(d.glob('*.json')):\n"
        "    b64 = base64.b64encode(cctx.compress(p.read_bytes())).decode('ascii')\n"
        "    p.with_name(p.name + '.zstd.b64').write_text(b64, encoding='utf-8')\n"
    )
    subprocess.run([CODEX_PYTHON, "-c", helper, str(folder)], check=True)


def export_single_world(world_code: str, winfo: dict):
    world_name = winfo["world_name"]
    tier = winfo["tier"]
    blend_path = Path(winfo["blend_file"])
    is_27x = (tier == "MainMap_27x")
    max_tris_budget = 140000 if is_27x else 60000

    if not blend_path.exists():
        raise FileNotFoundError(f"Missing blend file for {world_code} ({world_name}): {blend_path}")

    print(f"[EXPORT START] {world_code} {world_name} ({tier}) <- {blend_path.name}", flush=True)
    bpy.ops.wm.open_mainfile(filepath=str(blend_path))

    parts = collect_allowed_objects()

    # Disable heavy subdivision/bevel/armature modifiers and count exact raw triangles
    obj_tri_counts = []
    raw_tri_count = 0
    for o in parts:
        for mod in o.modifiers:
            if mod.type in ("SUBSURF", "BEVEL", "ARMATURE"):
                mod.show_viewport = False
                mod.show_render = False
        me_raw = o.data
        est_tris = max(1, len(me_raw.loops) - 2 * len(me_raw.polygons))
        obj_tri_counts.append(est_tris)
        raw_tri_count += est_tris

    decimate_applied = False
    decimate_ratio = 1.0
    if raw_tri_count > max_tris_budget:
        protected_tris = 0
        decimatable_tris = 0
        protect_flags = []
        for o, tcount in zip(parts, obj_tri_counts):
            is_protected = (tcount <= 12) or (tcount < 500 and bool(PROTECT_DECK_RE.search(o.name)))
            protect_flags.append(is_protected)
            if is_protected:
                protected_tris += tcount
            else:
                decimatable_tris += tcount

        if decimatable_tris > 0:
            # Target 91% of max_tris_budget to leave headroom for DECIMATE floor & Step A cliff splits
            target_rem = max(2000.0, (max_tris_budget * 0.91) - protected_tris)
            decimate_ratio = max(0.06, min(0.95, target_rem / float(decimatable_tris)))
            if decimate_ratio < 0.98:
                decimate_applied = True
                for o, is_prot in zip(parts, protect_flags):
                    if not is_prot:
                        dec = o.modifiers.new(name="ExportDecimate27x9x", type="DECIMATE")
                        dec.decimate_type = "COLLAPSE"
                        dec.ratio = decimate_ratio
                        dec.show_viewport = True
                        dec.show_render = True

    deps = bpy.context.evaluated_depsgraph_get()
    raw_mat_to_key = {}
    mat_info_cache = {}
    mat_triangles = {}
    split_extra_tris = 0

    for ob in parts:
        ev = ob.evaluated_get(deps)
        me = ev.to_mesh(preserve_all_data_layers=True, depsgraph=deps)
        if me is None or len(me.polygons) == 0:
            if me is not None:
                ev.to_mesh_clear()
            continue

        me.calc_loop_triangles()
        mw = T @ ob.matrix_world
        try:
            nm = mw.to_3x3().inverted().transposed()
        except ValueError:
            nm = mw.to_3x3()

        uv_layer = me.uv_layers.active
        uv_data = uv_layer.data if uv_layer else None
        verts = me.vertices
        cnormals = me.corner_normals
        mats = me.materials
        num_mats = len(mats)
        ob_name = ob.name

        # Pre-transform object vertices into quantized Roblox world coords
        rbx_verts = [None] * len(verts)
        for vi, v in enumerate(verts):
            rc = mw @ v.co
            rbx_verts[vi] = (round(float(rc.x), 3), round(float(rc.y), 3), round(float(rc.z), 3))

        for tri in me.loop_triangles:
            mat = mats[tri.material_index] if (num_mats > 0 and tri.material_index < num_mats) else None
            raw_mat_name = mat.name if mat else "Default"
            if SKIP_MAT_RE.search(raw_mat_name):
                continue

            mkey = raw_mat_to_key.get(raw_mat_name)
            if mkey is None:
                base_mat_name = re.sub(r"\.\d+$", "", raw_mat_name)
                minfo = extract_material_info(mat, base_mat_name)
                mkey = (
                    minfo["name"],
                    tuple(minfo["color_linear"]),
                    minfo["alpha"],
                    minfo["metalness"],
                    minfo["roughness"],
                    tuple(minfo["emission_linear"]),
                    minfo["emission_strength"],
                )
                raw_mat_to_key[raw_mat_name] = mkey
                if mkey not in mat_info_cache:
                    mat_info_cache[mkey] = minfo
                    mat_triangles[mkey] = []

            v0, v1, v2 = tri.vertices
            l0, l1, l2 = tri.loops

            p0 = rbx_verts[v0]
            p1 = rbx_verts[v1]
            p2 = rbx_verts[v2]

            cn0 = (nm @ cnormals[l0].vector).normalized()
            cn1 = (nm @ cnormals[l1].vector).normalized()
            cn2 = (nm @ cnormals[l2].vector).normalized()
            n0 = (round(float(cn0.x), 3), round(float(cn0.y), 3), round(float(cn0.z), 3))
            n1 = (round(float(cn1.x), 3), round(float(cn1.y), 3), round(float(cn1.z), 3))
            n2 = (round(float(cn2.x), 3), round(float(cn2.y), 3), round(float(cn2.z), 3))

            if uv_data is not None:
                u0 = uv_data[l0].uv
                u1 = uv_data[l1].uv
                u2 = uv_data[l2].uv
                uv0 = (round(float(u0[0]), 3), round(float(u0[1]), 3))
                uv1 = (round(float(u1[0]), 3), round(float(u1[1]), 3))
                uv2 = (round(float(u2[0]), 3), round(float(u2[1]), 3))
            else:
                uv0 = uv1 = uv2 = (0.5, 0.5)

            tlist = mat_triangles[mkey]
            before_len = len(tlist)
            split_oversized_triangle(p0, p1, p2, n0, n1, n2, uv0, uv1, uv2, ob_name, tlist, 0)
            added = len(tlist) - before_len
            if added > 1:
                split_extra_tris += (added - 1)

        ev.to_mesh_clear()

    # Clean output directory ONLY for this world inside runtime_v8
    OUT_ROOT.mkdir(parents=True, exist_ok=True)
    out_dir = OUT_ROOT / world_name
    out_dir.mkdir(parents=True, exist_ok=True)
    for stale in out_dir.glob("*"):
        if stale.is_file() and (
            stale.name.startswith("Mesh")
            or stale.name.startswith("Header")
            or stale.name.startswith("Clips")
        ):
            stale.unlink()

    # Step B: KD-split each material's triangles into <= 1,750-stud & <= 18,000-tri chunks
    meshes = []
    total_exported_tris = 0
    global_max_span = 0.0

    for mat_idx, mkey in enumerate(sorted(mat_triangles.keys(), key=lambda k: k[0])):
        tlist = mat_triangles[mkey]
        if not tlist:
            continue
        kd_chunks = []
        kd_split_triangles(tlist, kd_chunks)
        kd_chunks = merge_compatible_chunks(kd_chunks)
        mat_info = mat_info_cache[mkey]
        for sub_idx, citem in enumerate(kd_chunks):
            ctris = citem[0]
            chunk_name = f"{world_name}_{mat_idx:03d}_{sub_idx:02d}"
            chunk_dict = build_mesh_chunk_dict(chunk_name, mat_info, ctris)
            if chunk_dict is None:
                continue
            # Re-verify exact serialized vertex AABB span
            vs = chunk_dict["vertices"]
            xs = [v[0] for v in vs]
            ys = [v[1] for v in vs]
            zs = [v[2] for v in vs]
            sx = max(xs) - min(xs)
            sy = max(ys) - min(ys)
            sz = max(zs) - min(zs)
            span = max(sx, sy, sz)
            if span > 1750.0:
                raise RuntimeError(
                    f"Chunk {chunk_name} exceeded 1750.0 studs: ({sx:.2f}, {sy:.2f}, {sz:.2f})"
                )
            if span > global_max_span:
                global_max_span = span

            mesh_idx = len(meshes)
            meshes.append(chunk_dict)
            total_exported_tris += len(chunk_dict["triangles"])
            write_json_and_zstd(out_dir / f"Mesh{mesh_idx:03d}.json", chunk_dict)

    if len(meshes) == 0 or len(meshes) > 999:
        raise RuntimeError(f"Invalid mesh_count={len(meshes)} for {world_name} (must be 1..999)")

    header = {
        "name": world_name,
        "bones": [],
        "source": str(blend_path),
        "source_sha256": hashlib.sha256(blend_path.read_bytes()).hexdigest(),
        "static": True,
        "source_parts": len(parts),
        "triangles": total_exported_tris,
        "mesh_count": len(meshes),
        "mapping": "(x,z,-y)",
    }
    write_json_and_zstd(out_dir / "Header.json", header)
    write_json_and_zstd(out_dir / "Clips.json", {})

    if not HAS_ZSTD:
        compress_folder_via_codex_python(out_dir)

    print(
        f"[WORLD OK] {world_code:3s} {world_name:30s} | meshes={len(meshes):3d} | "
        f"raw_tris={raw_tri_count:6d} -> out_tris={total_exported_tris:6d} "
        f"(decim={decimate_ratio:.3f}, split_added={split_extra_tris}) | "
        f"max_span={global_max_span:.2f} studs",
        flush=True,
    )


def parse_cli_args():
    argv = sys.argv
    if "--" in argv:
        argv = argv[argv.index("--") + 1:]
    else:
        argv = []
    parser = argparse.ArgumentParser(description="Export 27x/9x SKYBREAK worlds to runtime_v8")
    parser.add_argument("--world", required=True, help="World code W1..W13, world_name, or ALL")
    return parser.parse_args(argv)


def main():
    args = parse_cli_args()
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    worlds_map = manifest["worlds"]

    target = args.world.strip()
    if target.upper() == "ALL":
        ordered_codes = [f"W{i}" for i in range(1, 14)]
        for wc in ordered_codes:
            export_single_world(wc, worlds_map[wc])
        return

    # Match by W1..W13 or world_name
    matched_code = None
    for wc, winfo in worlds_map.items():
        if wc.upper() == target.upper() or winfo["world_name"].lower() == target.lower():
            matched_code = wc
            break

    if not matched_code:
        raise ValueError(f"Unknown --world '{target}'. Expected W1..W13 or valid world_name.")

    export_single_world(matched_code, worlds_map[matched_code])


if __name__ == "__main__":
    main()
