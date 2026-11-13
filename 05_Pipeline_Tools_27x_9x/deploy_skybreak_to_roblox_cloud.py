#!/usr/bin/env python3
"""
Official Roblox Open Cloud Place Deployment Tool for SKYBREAK.

Uses ONLY documented Roblox Open Cloud APIs:
  - POST https://apis.roblox.com/universes/v1/{universeId}/places/{placeId}/versions?versionType=Published
    Header: x-api-key: <ROBLOX_OPEN_CLOUD_KEY>

Required environment variables (or CLI flags):
  - ROBLOX_OPEN_CLOUD_KEY  (Creator Hub -> Open Cloud -> API Keys -> place:write)
  - ROBLOX_UNIVERSE_ID     (Experience Universe ID)
  - ROBLOX_PLACE_ID        (Root Place ID)
"""

import argparse
import json
import os
import sys
import urllib.error
import urllib.request
import xml.etree.ElementTree as ET
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")

DEFAULT_RBXLX = (
    Path(__file__).resolve().parents[1] / "04_Roblox" / "SKYBREAK_Playable_v12_PremiumUI.rbxlx"
)
OPEN_CLOUD_XML_MAX_BYTES = 100 * 1024 * 1024


def build_cloud_rbxlx_bytes(rbxlx_path: Path, strip_v5_sources: bool) -> bytes:
    raw = rbxlx_path.read_bytes()
    if not strip_v5_sources:
        return raw

    tree = ET.fromstring(raw)
    for svc in tree.findall("Item"):
        if svc.attrib.get("class") == "ReplicatedStorage":
            for child in list(svc.findall("Item")):
                props = child.find("Properties")
                if props is None:
                    continue
                name_el = next(
                    (s for s in props.findall("string") if s.attrib.get("name") == "Name"),
                    None,
                )
                if name_el is not None and name_el.text == "DelegatedV5Sources":
                    svc.remove(child)
    xml_bytes = ET.tostring(tree, encoding="utf-8", xml_declaration=False)
    return xml_bytes


def publish_place_open_cloud(
    api_key: str,
    universe_id: str,
    place_id: str,
    payload_bytes: bytes,
    version_type: str = "Published",
) -> dict:
    url = (
        f"https://apis.roblox.com/universes/v1/{universe_id}"
        f"/places/{place_id}/versions?versionType={version_type}"
    )
    req = urllib.request.Request(
        url=url,
        data=payload_bytes,
        method="POST",
        headers={
            "x-api-key": api_key,
            "Content-Type": "application/xml",
            "Accept": "application/json",
        },
    )
    with urllib.request.urlopen(req, timeout=180) as resp:
        body = resp.read().decode("utf-8", errors="replace")
        return json.loads(body) if body.strip() else {"status": resp.status}


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Deploy SKYBREAK_Playable_v12_PremiumUI.rbxlx via official Roblox Open Cloud API."
    )
    parser.add_argument(
        "--rbxlx",
        type=Path,
        default=DEFAULT_RBXLX,
        help="Path to SKYBREAK_Playable_v12_PremiumUI.rbxlx",
    )
    parser.add_argument(
        "--api-key",
        default=os.environ.get("ROBLOX_OPEN_CLOUD_KEY", "").strip(),
        help="Roblox Open Cloud API Key (or env ROBLOX_OPEN_CLOUD_KEY)",
    )
    parser.add_argument(
        "--universe-id",
        default=os.environ.get("ROBLOX_UNIVERSE_ID", "").strip(),
        help="Target Roblox Universe ID (or env ROBLOX_UNIVERSE_ID)",
    )
    parser.add_argument(
        "--place-id",
        default=os.environ.get("ROBLOX_PLACE_ID", "").strip(),
        help="Target Roblox Place ID (or env ROBLOX_PLACE_ID)",
    )
    parser.add_argument(
        "--cloud-strip-v5-sources",
        action="store_true",
        help="BLOCKED BY DEFAULT: stripping ReplicatedStorage.DelegatedV5Sources breaks all 98 EditableMesh 3D assets",
    )
    parser.add_argument(
        "--i-have-migrated-cloud-assets",
        action="store_true",
        help="Explicit override only after all 98 DelegatedV5Sources assets are migrated to external cloud asset IDs",
    )
    parser.add_argument(
        "--version-type",
        choices=("Published", "Saved"),
        default="Published",
        help="Publish immediately (Published) or save version only (Saved)",
    )
    args = parser.parse_args()

    if args.cloud_strip_v5_sources and not args.i_have_migrated_cloud_assets:
        print(
            "[BLOCKED] --cloud-strip-v5-sources is disabled to prevent broken live builds!\n"
            "  Why: Stripping ReplicatedStorage.DelegatedV5Sources deletes all 98 Zstd-compressed 3D runtime payloads\n"
            "       (13 worlds + enemies + bosses + weapons + shrines), leaving players in an empty invisible world.\n"
            "  Required Publish Path:\n"
            "    1. Open 04_Roblox/SKYBREAK_Playable_v12_PremiumUI.rbxlx in Roblox Studio.\n"
            "    2. Ensure you are logged into a 13+ ID-Verified Roblox Creator/Group account (required for live EditableMesh).\n"
            "    3. Use File -> Publish to Roblox (Studio automatically compresses the ~318 MB XML into binary format\n"
            "       with 100% of DelegatedV5Sources intact).\n"
            "    See CREATOR_HUB_PUBLISH_CHECKLIST.md for the complete publish checklist.",
            file=sys.stderr,
        )
        return 5

    if not args.rbxlx.is_file():
        print(f"[ERROR] Place file not found: {args.rbxlx}", file=sys.stderr)
        return 1

    missing = []
    if not args.api_key:
        missing.append("ROBLOX_OPEN_CLOUD_KEY (--api-key)")
    if not args.universe_id:
        missing.append("ROBLOX_UNIVERSE_ID (--universe-id)")
    if not args.place_id:
        missing.append("ROBLOX_PLACE_ID (--place-id)")

    if missing:
        print(
            "[BLOCKED] Missing required official Roblox Open Cloud credentials/IDs:\n  - "
            + "\n  - ".join(missing),
            file=sys.stderr,
        )
        print(
            "\nNOTE: Full SKYBREAK_Playable_v12_PremiumUI.rbxlx (~318 MB XML) exceeds Open Cloud's 100 MB XML limit.\n"
            "Publish directly via Roblox Studio -> File -> Publish to Roblox (under a 13+ ID-Verified account/Group)\n"
            "so binary compression preserves all 98 ReplicatedStorage.DelegatedV5Sources 3D EditableMesh payloads.\n"
            "See CREATOR_HUB_PUBLISH_CHECKLIST.md for step-by-step instructions.",
            file=sys.stderr,
        )
        return 2

    print(f"[1/2] Preparing payload from {args.rbxlx.name}...")
    payload = build_cloud_rbxlx_bytes(args.rbxlx, args.cloud_strip_v5_sources)
    mb = len(payload) / (1024 * 1024)
    print(f"      Payload size: {len(payload):,} bytes ({mb:.2f} MB)")
    if len(payload) > OPEN_CLOUD_XML_MAX_BYTES:
        print(
            f"[BLOCKED] XML payload ({mb:.2f} MB) exceeds Roblox Open Cloud's 100 MB XML upload limit.\n"
            "  Do NOT strip DelegatedV5Sources. Instead, open SKYBREAK_Playable_v12_PremiumUI.rbxlx in Roblox Studio\n"
            "  (logged into a 13+ ID-Verified account/Group) and run File -> Publish to Roblox for binary upload.",
            file=sys.stderr,
        )
        return 6

    print(
        f"[2/2] Uploading to Roblox Open Cloud (Universe={args.universe_id}, Place={args.place_id}, Type={args.version_type})..."
    )
    try:
        res = publish_place_open_cloud(
            api_key=args.api_key,
            universe_id=args.universe_id,
            place_id=args.place_id,
            payload_bytes=payload,
            version_type=args.version_type,
        )
        print(f"[SUCCESS] Published to Roblox Open Cloud: {json.dumps(res)}")
        print(f"          Play URL: https://www.roblox.com/games/{args.place_id}")
        return 0
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8", errors="replace")
        print(
            f"[ERROR] Roblox Open Cloud HTTP {e.code}: {err_body}",
            file=sys.stderr,
        )
        return 3
    except Exception as e:
        print(f"[ERROR] Open Cloud publish failed: {e}", file=sys.stderr)
        return 4


if __name__ == "__main__":
    raise SystemExit(main())
