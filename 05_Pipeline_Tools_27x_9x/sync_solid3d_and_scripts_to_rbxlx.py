import json
import shutil
import uuid
import xml.etree.ElementTree as ET
from pathlib import Path

HANDOFF_ROOT = Path(__file__).resolve().parents[1]
OUTPUTS_ROOT = HANDOFF_ROOT.parent
rbxlx_path = HANDOFF_ROOT / "04_Roblox" / "SKYBREAK_Playable_v12_PremiumUI.rbxlx"
rbxlx_copy_path = HANDOFF_ROOT / "06_Antigravity_Work" / "SKYBREAK_Playable_v12_PremiumUI.rbxlx"
rbxlx_v2_path = OUTPUTS_ROOT / "SKYBREAK_Visual_v2" / "SKYBREAK_Playable_v12_PremiumUI.rbxlx"
luau_dir = HANDOFF_ROOT / "06_Antigravity_Work" / "luau_v8"
runtime_v8_dir = HANDOFF_ROOT / "06_Antigravity_Work" / "runtime_v8"
src_04_root = HANDOFF_ROOT / "04_Roblox" / "src"
src_v2_root = OUTPUTS_ROOT / "SKYBREAK_Visual_v2" / "src"

SYNC_SERVICES = ("ReplicatedStorage", "ServerScriptService", "ServerStorage", "StarterPlayer")
SYNC_RUNTIME_V8_ASSETS = (
    # 3 Main Maps (27x)
    "GoldenSky",
    "FrozenCyber",
    "ShadowRealm",
    # 10 Expansion Worlds (9x)
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
    # Standalone Shrines & Dragon Rigs
    "ZiolesGachaShrine",
    "AetherShrinesAndRaidConsole",
    "AbyssalSovereignDragon",
    "AbyssalDragonHybrid",
    # Pass 15 Chiseled 3D Equipment, Weapons, Guns, Armor & Crafting Relics
    "ExpansionMeleeWeaponsSet",
    "ExpansionGunsAndBowsSet",
    "ArmorSetsAndAccessoriesSet",
    "CraftingMaterialsAndRelicsSet",
)
HARD_BYTE_LIMIT = 199000
CHUNK_SIZE = 150000
V5_LOADER = (
    'local t={} for i=1,#script:GetChildren() do t[i]=script[string.format("Data%03d",i)].Value end '
    'local e=game:GetService("EncodingService") '
    'local b=e:DecompressBuffer(e:Base64Decode(buffer.fromstring(table.concat(t))),Enum.CompressionAlgorithm.Zstd) '
    'return game:GetService("HttpService"):JSONDecode(buffer.tostring(b))'
)


def get_name(item):
    props = item.find("Properties")
    if props is None:
        return None
    for s in props.findall("string"):
        if s.attrib.get("name") == "Name":
            return s.text
    return None


def set_source(item, code: str):
    props = item.find("Properties")
    if props is None:
        props = ET.SubElement(item, "Properties")
    for ps in props.findall("ProtectedString"):
        if ps.attrib.get("name") == "Source":
            ps.text = code
            return
    ps = ET.SubElement(props, "ProtectedString", {"name": "Source"})
    ps.text = code


def create_item(parent, cls_name: str, inst_name: str):
    item = ET.SubElement(parent, "Item", {"class": cls_name, "referent": "RBX" + uuid.uuid4().hex.upper()})
    props = ET.SubElement(item, "Properties")
    nm = ET.SubElement(props, "string", {"name": "Name"})
    nm.text = inst_name
    return item


def find_or_create_path(root, parts, leaf_class: str):
    curr = root
    for idx, p in enumerate(parts):
        is_leaf = idx == len(parts) - 1
        found = None
        for ch in curr.findall("Item"):
            if get_name(ch) == p:
                if not is_leaf or ch.attrib.get("class") == leaf_class:
                    found = ch
                    break
        if found is None:
            assert idx > 0, f"Top-level service missing in rbxlx: {p}"
            found = create_item(curr, leaf_class if is_leaf else "Folder", p)
            print(f"   [+] Created {leaf_class if is_leaf else 'Folder'}: {'/'.join(parts[:idx+1])}")
        curr = found
    return curr


def set_string_prop(item, prop_name: str, value: str):
    props = item.find("Properties")
    if props is None:
        props = ET.SubElement(item, "Properties")
    for s in props.findall("string"):
        if s.attrib.get("name") == prop_name:
            s.text = value
            return
    s = ET.SubElement(props, "string", {"name": prop_name})
    s.text = value


def sync_runtime_v8_assets(root):
    find_or_create_path(root, ["ReplicatedStorage", "DelegatedV5Sources"], "Folder")
    synced_assets = []
    for asset_name in SYNC_RUNTIME_V8_ASSETS:
        asset_dir = runtime_v8_dir / asset_name
        if not asset_dir.is_dir() or not (asset_dir / "Header.json.zstd.b64").exists():
            print(f"   [!] Skipping missing runtime_v8 asset: {asset_name}")
            continue
        asset_folder = find_or_create_path(root, ["ReplicatedStorage", "DelegatedV5Sources", asset_name], "Folder")
        for old_ch in list(asset_folder.findall("Item")):
            asset_folder.remove(old_ch)

        b64_files = sorted(asset_dir.glob("*.json.zstd.b64"))
        mod_count = 0
        chunk_total = 0
        for b64_file in b64_files:
            label = b64_file.name[: -len(".json.zstd.b64")]
            raw_b64 = b64_file.read_text(encoding="ascii").strip()
            mod_item = create_item(asset_folder, "ModuleScript", label)
            set_source(mod_item, V5_LOADER)
            chunks = [raw_b64[i : i + CHUNK_SIZE] for i in range(0, len(raw_b64), CHUNK_SIZE)]
            for idx, chunk in enumerate(chunks, 1):
                sv = create_item(mod_item, "StringValue", f"Data{idx:03d}")
                set_string_prop(sv, "Value", chunk)
            mod_count += 1
            chunk_total += len(chunks)
        synced_assets.append(f"{asset_name}({mod_count} mods, {chunk_total} chunks)")
    if synced_assets:
        print("   [+] Synced runtime_v8 DelegatedV5Sources:", ", ".join(synced_assets))


def classify_lua_file(rel_parts):
    fname = rel_parts[-1]
    if fname.endswith(".server.lua"):
        return list(rel_parts[:-1]) + [fname[:-11]], "Script"
    elif fname.endswith(".client.lua"):
        return list(rel_parts[:-1]) + [fname[:-11]], "LocalScript"
    else:
        return list(rel_parts[:-1]) + [fname[:-4]], "ModuleScript"


def set_typed_prop(item, tag: str, prop_name: str, value: str):
    props = item.find("Properties")
    if props is None:
        props = ET.SubElement(item, "Properties")
    for el in props.findall(tag):
        if el.attrib.get("name") == prop_name:
            el.text = value
            return
    el = ET.SubElement(props, tag, {"name": prop_name})
    el.text = value


def set_cframe_xyz(item, x: float, y: float, z: float):
    props = item.find("Properties")
    if props is None:
        return
    for cf in props.findall("CoordinateFrame"):
        if cf.attrib.get("name") == "CFrame":
            for axis, val in (("X", x), ("Y", y), ("Z", z)):
                el = cf.find(axis)
                if el is None:
                    el = ET.SubElement(cf, axis)
                el.text = f"{val:.3f}"
            return


def enforce_datamodel_properties(root):
    for item in root.findall("Item"):
        cls = item.attrib.get("class")
        if cls == "Lighting":
            set_typed_prop(item, "float", "Brightness", "1.35")
            set_typed_prop(item, "float", "ExposureCompensation", "-0.22")
            set_typed_prop(item, "float", "FogStart", "1800")
            set_typed_prop(item, "float", "FogEnd", "18000")
        elif cls == "StarterPlayer":
            set_typed_prop(item, "bool", "EnableMouseLockOption", "false")
        elif cls == "Workspace":
            set_typed_prop(item, "float", "FallenPartsDestroyHeight", "-4500")
            for sub in item.findall("Item"):
                if get_name(sub) == "SkyHub":
                    for sp in sub.findall("Item"):
                        if get_name(sp) == "SkybornSpawn":
                            set_cframe_xyz(sp, -2484.0, 51.5, 4131.0)
                            print("   [+] Updated Workspace.SkyHub.SkybornSpawn -> (-2484.0, 51.5, 4131.0)")


def sync_three_category_folders():
    roblox_dir = HANDOFF_ROOT / "04_Roblox"
    cat_dirs = (
        roblox_dir / "01_HangMuc1_Server_Combat_World",
        roblox_dir / "02_HangMuc2_UI_Shop_Config",
        roblox_dir / "03_HangMuc3_3D_VuKhi_Giap_VFX",
    )
    pulled_from_cats = 0
    for cat_dir in cat_dirs:
        if not cat_dir.exists():
            continue
        for cat_file in sorted(cat_dir.rglob("*.lua")):
            rel = cat_file.relative_to(cat_dir)
            src_file = src_04_root / rel
            src_file.parent.mkdir(parents=True, exist_ok=True)
            if not src_file.exists() or cat_file.read_bytes() != src_file.read_bytes():
                shutil.copy2(cat_file, src_file)
                pulled_from_cats += 1
    if pulled_from_cats:
        print(f"   [+] Synced {pulled_from_cats} modified files from 3 Category Folders -> local build src/")


def main():
    sync_three_category_folders()
    # Mirror canonical shared duplicates inside 04_Roblox/src
    rend_main = src_04_root / "ReplicatedStorage" / "DelegatedV5Renderer.lua"
    rend_shared = src_04_root / "ReplicatedStorage" / "Shared" / "DelegatedV5Renderer.lua"
    if rend_main.exists():
        rend_shared.write_text(rend_main.read_text(encoding="utf-8").replace("\r\n", "\n"), encoding="utf-8", newline="\n")

    wc_cfg = src_04_root / "ReplicatedStorage" / "SkybreakShared" / "Config" / "WorldConfig.lua"
    wc_dup = src_04_root / "ReplicatedStorage" / "SkybreakShared" / "WorldConfig.lua"
    if wc_cfg.exists():
        wc_dup.write_text(wc_cfg.read_text(encoding="utf-8").replace("\r\n", "\n"), encoding="utf-8", newline="\n")

    uistate_types = src_04_root / "ReplicatedStorage" / "SkybreakShared" / "Types" / "UIState.lua"
    uistate_dup = src_04_root / "ReplicatedStorage" / "SkybreakShared" / "UIState.lua"
    if uistate_types.exists():
        uistate_dup.write_text(uistate_types.read_text(encoding="utf-8").replace("\r\n", "\n"), encoding="utf-8", newline="\n")

    print("1. Parsing SKYBREAK_Playable_v12_PremiumUI.rbxlx...")
    tree = ET.parse(rbxlx_path)
    root = tree.getroot()
    enforce_datamodel_properties(root)
    sync_runtime_v8_assets(root)

    manifest = []
    synced_count = 0
    max_sz = 0
    max_rel = ""

    for svc in SYNC_SERVICES:
        svc_dir = src_04_root / svc
        if not svc_dir.exists():
            continue
        for fpath in sorted(svc_dir.rglob("*.lua")):
            rel_posix = fpath.relative_to(src_04_root).as_posix()
            code = fpath.read_text(encoding="utf-8").replace("\r\n", "\n")
            fpath.write_text(code, encoding="utf-8", newline="\n")
            b_len = len(code.encode("utf-8"))
            assert b_len < HARD_BYTE_LIMIT, f"HARD BYTE LIMIT EXCEEDED ({b_len} >= {HARD_BYTE_LIMIT}): {rel_posix}"
            if b_len > max_sz:
                max_sz = b_len
                max_rel = rel_posix

            inst_parts, cls_name = classify_lua_file(fpath.relative_to(src_04_root).parts)
            el = find_or_create_path(root, inst_parts, cls_name)
            set_source(el, code)
            synced_count += 1

            # Mirror to SKYBREAK_Visual_v2/src if sibling workspace exists
            if (OUTPUTS_ROOT / "SKYBREAK_Visual_v2").exists():
                v2_target = src_v2_root / fpath.relative_to(src_04_root)
                v2_target.parent.mkdir(parents=True, exist_ok=True)
                v2_target.write_text(code, encoding="utf-8", newline="\n")

            # Also keep luau_v8 mirror updated if same filename exists there
            luau_copy = luau_dir / fpath.name
            if luau_copy.exists() and fpath.name != "Theme.lua" and fpath.name != "PlayerDataService.lua":
                luau_copy.write_text(code, encoding="utf-8", newline="\n")

            manifest.append({
                "path": inst_parts,
                "class": cls_name,
                "url": rel_posix,
                "bytes": b_len,
            })

    manifest_path = src_04_root / "studio_sync_manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8", newline="\n")

    tree.write(rbxlx_path, encoding="utf-8", xml_declaration=False)
    raw_bytes = rbxlx_path.read_bytes()
    old_hdr = b'<roblox xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">'
    new_hdr = b'<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">'
    if raw_bytes.startswith(old_hdr):
        raw_bytes = new_hdr + raw_bytes[len(old_hdr):]
        rbxlx_path.write_bytes(raw_bytes)

    for mirror_rbxlx in (rbxlx_copy_path, rbxlx_v2_path):
        if mirror_rbxlx.parent.exists():
            shutil.copy2(rbxlx_path, mirror_rbxlx)

    print(f"2. Synced {synced_count} Luau scripts (< {HARD_BYTE_LIMIT}B; largest: {max_rel} = {max_sz}B) -> .rbxlx + v2 + manifest!")


if __name__ == "__main__":
    main()
