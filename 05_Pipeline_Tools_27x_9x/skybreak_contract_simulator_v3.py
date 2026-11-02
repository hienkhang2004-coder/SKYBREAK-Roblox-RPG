import os
import re
import xml.etree.ElementTree as ET

from pathlib import Path
HANDOFF_ROOT = Path(__file__).resolve().parents[1]
SRC_ROOT = str(HANDOFF_ROOT / "04_Roblox" / "src")
RBXLX_PATH = str(HANDOFF_ROOT / "04_Roblox" / "SKYBREAK_Playable_v12_PremiumUI.rbxlx")

def collect_files():
    files = {}
    for dp, _, fns in os.walk(SRC_ROOT):
        for fn in sorted(fns):
            if fn.endswith(".lua"):
                full = os.path.join(dp, fn)
                rel = os.path.relpath(full, SRC_ROOT).replace("\\", "/")
                files[rel] = open(full, "r", encoding="utf-8").read()
    return files

def get_v5_sources():
    tree = ET.parse(RBXLX_PATH)
    root = tree.getroot()
    def gname(it):
        p = it.find("Properties")
        if p is not None:
            for s in p.findall("string"):
                if s.attrib.get("name") == "Name":
                    return s.text or ""
        return ""
    for ch in root.findall("Item"):
        if gname(ch) == "ReplicatedStorage":
            for sub in ch.findall("Item"):
                if gname(sub) == "DelegatedV5Sources":
                    return {gname(x) for x in sub.findall("Item")}
    return set()

def main():
    files = collect_files()
    v5_sources = get_v5_sources()
    renderer = files["ReplicatedStorage/DelegatedV5Renderer.lua"]
    vsplit = set(re.findall(r'([A-Za-z0-9_]+)\s*=\s*\{\s*source\s*=\s*["\']([A-Za-z0-9_]+)["\']', renderer))
    valid_3d_assets = set(v5_sources) | {k for k, src in vsplit if src in v5_sources}

    # CHECK A: Enemy VisualAssets vs BlenderEnemies.client.lua & DelegatedV5Sources
    print("=== CHECK A: ENEMY & NPC VISUAL ASSETS VS 3D SOURCES ===")
    benemies = files["StarterPlayer/StarterPlayerScripts/BlenderEnemies.client.lua"]
    bnpcs = files["StarterPlayer/StarterPlayerScripts/BlenderNPCs.client.lua"]

    for rel in ["ReplicatedStorage/Shared/Config.lua", "ServerScriptService/Services/GameStaticData.lua",
                "ServerScriptService/Services/SkybreakWorldEventsService.lua",
                "ServerScriptService/Services/SkybreakSocialEconomyService.lua",
                "ServerScriptService/Services/SkybreakCombatExpansion.lua"]:
        txt = files[rel]
        for idx, ln in enumerate(txt.splitlines(), 1):
            for m in re.finditer(r'VisualAsset["\']?\s*[=:]\s*["\']([A-Za-z0-9_]+)["\']', ln):
                va = m.group(1)
                in_3d = va in valid_3d_assets
                in_be = (f'"{va}"' in benemies) or (f"'{va}'" in benemies) or (f"{va} =" in benemies) or (f"{va}=" in benemies)
                in_bn = (f'"{va}"' in bnpcs) or (f"'{va}'" in bnpcs) or (f"{va} =" in bnpcs) or (f"{va}=" in bnpcs)
                if not in_3d and not in_be and not in_bn:
                    print(f"  [UNRESOLVED VISUAL ASSET] {rel}:{idx}: VisualAsset='{va}' NOT in DelegatedV5Sources, BlenderEnemies, or BlenderNPCs!")
                elif not in_3d:
                    print(f"  [REMAPPED/PROCEDURAL] {rel}:{idx}: VisualAsset='{va}' (not raw V5Source; in BlenderEnemies={in_be}, BlenderNPCs={in_bn})")

    # CHECK B: Giftcodes in Settings.lua vs SkybreakCombatData.lua / SkybreakCombatExpansion.lua
    print("\n=== CHECK B: GIFTCODES UI VS SERVER ===")
    settings_txt = files["StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/Settings.lua"]
    cdata_txt = files["ReplicatedStorage/Shared/SkybreakCombatData.lua"]
    cexp_txt = files["ServerScriptService/Services/SkybreakCombatExpansion.lua"]
    ui_codes = set(re.findall(r'"([A-Z0-9_]{5,24})"', settings_txt))
    # Filter to likely giftcodes
    for code in sorted(ui_codes):
        if any(w in code for w in ("SKY", "CORE", "AETHER", "DRAGON", "UPDATE", "RELEASE", "FREE", "2X", "V12", "VOID", "FRUIT")):
            in_cd = code in cdata_txt
            in_ce = code in cexp_txt
            print(f"  UI Code candidate '{code}': in CombatData={in_cd}, in CombatExpansion={in_ce}")

    # CHECK C: Swords & Guns in Config.lua
    print("\n=== CHECK C: WEAPONS & GUNS SKILLS PARITY ===")
    cfg_txt = files["ReplicatedStorage/Shared/Config.lua"]
    for m in re.finditer(r'([A-Za-z0-9_]+)\s*=\s*\{Id=["\']([^"\']+)["\'][^}]*Slot=["\'](Weapon|Gun)["\']', cfg_txt):
        item_id, _, slot = m.group(1), m.group(2), m.group(3)
        if slot == "Gun":
            in_guns = bool(re.search(rf'\b{re.escape(item_id)}\s*=\s*\{{[^}}]*Cooldown', cfg_txt))
            if not in_guns:
                print(f"  [GUN MISSING STATS] '{item_id}' has Slot='Gun' in Config.Items but NOT in Config.Guns!")

    # CHECK D: Dynamic math.clamp(x, min, max) where max is an expression that could be < min, and math.random(1, #x)
    print("\n=== CHECK D: RISKY math.clamp & math.random CALLS ===")
    for rel, txt in sorted(files.items()):
        for idx, ln in enumerate(txt.splitlines(), 1):
            st = ln.strip()
            if st.startswith("--"):
                continue
            # Check math.clamp(..., 1, #something) where #something could be 0!
            for m in re.finditer(r'math\.clamp\s*\([^,]+,\s*([1-9]\d*(?:\.\d+)?)\s*,\s*(#[A-Za-z0-9_\.]+)\s*\)', st):
                print(f"  [HAZARD math.clamp(x, {m.group(1)}, {m.group(2)})] {rel}:{idx}: {st[:100]}")
            # Check math.random(1, #something) where something is not a constant table
            for m in re.finditer(r'math\.random\s*\(\s*1\s*,\s*#([A-Za-z0-9_\.]+)\s*\)', st):
                tbl = m.group(1)
                if not tbl.isupper():
                    print(f"  [CHECK math.random(1, #{tbl})] {rel}:{idx}: {st[:100]}")

if __name__ == "__main__":
    main()
