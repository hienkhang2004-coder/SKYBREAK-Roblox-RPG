"""
Reworks the SKYBREAK .rbxlx place files from scratch using all 78 runtime_v8 Blender 3D assets
(15 Worlds/Islands + 63 Rigged & Animated Asset folders = 50 canonical rigged assets + 13 runtime aliases/FX),
purging all legacy boxy Part islands/mannequins and broken white untextured MeshParts.
"""
import hashlib
import json
import math
import shutil
import uuid
import xml.etree.ElementTree as ET
from pathlib import Path

HANDOFF_ROOT = Path(r"C:\Users\khang\Documents\Codex\2026-10-22\new-chat\outputs\SKYBREAK_Antigravity_Handoff")
ROBLOX_DIR = HANDOFF_ROOT / "04_Roblox"
WORK_DIR = HANDOFF_ROOT / "06_Antigravity_Work"
LUAU_V8_DIR = WORK_DIR / "luau_v8"
RUNTIME_V8_DIR = WORK_DIR / "runtime_v8"

V2_ROOT = Path(r"C:\Users\khang\Documents\Codex\2026-10-22\new-chat\outputs\SKYBREAK_Visual_v2")
SRC_ROOT = V2_ROOT / "src"

MATERIAL_TOKENS = {
    "Plastic": "256",
    "SmoothPlastic": "272",
    "Neon": "288",
    "Wood": "512",
    "WoodPlanks": "528",
    "Marble": "784",
    "Slate": "800",
    "Granite": "832",
    "Metal": "1088",
    "Grass": "1280",
    "Glass": "1568",
}

SHAPE_TOKENS = {
    "Ball": "0",
    "Block": "1",
    "Cylinder": "2",
}

LOADER = (
    'local t={} for i=1,#script:GetChildren() do t[i]=script[string.format("Data%03d",i)].Value end '
    'local e=game:GetService("EncodingService") '
    'local b=e:DecompressBuffer(e:Base64Decode(buffer.fromstring(table.concat(t))),Enum.CompressionAlgorithm.Zstd) '
    'return game:GetService("HttpService"):JSONDecode(buffer.tostring(b))'
)

GRAND_SKY_ISLANDS_STORYLINE = [
    {
        "asset": "ZiolesGachaShrine",
        "origin": (-220.0, 38.0, 260.0),
        "slab_size": (44.0, 3.0, 44.0),
        "title": "⛩ ZIOLES GACHA SHRINE • ĐIỆN THỜ TRIỆU HỒI TRÁI ÁC QUỶ (ZONE 1)",
        "glow_rgb": (110, 235, 255),
    },
    {
        "asset": "AetherShrinesAndRaidConsole",
        "origin": (60.0, 38.0, 260.0),
        "slab_size": (44.0, 3.0, 44.0),
        "title": "⛩ AETHER HOME SHRINE • ĐÀI ĐIỆN THỜ LƯU ĐIỂM HỒI SINH (ZONE 1)",
        "glow_rgb": (88, 238, 255),
    },
    {
        "asset": "WestGardenPirateBastion",
        "origin": (-520.0, 48.0, 40.0),
        "slab_size": (300.0, 4.0, 300.0),
        "title": "🏴‍☠️ WEST GARDEN PIRATE BASTION • PHÁO ĐÀI VƯỜN TÂY (ZONE 2 • LV. 50–150)",
        "glow_rgb": (255, 205, 82),
    },
    {
        "asset": "SunshardSkySanctuary",
        "origin": (540.0, 88.0, -40.0),
        "slab_size": (310.0, 4.0, 310.0),
        "title": "☀ SUNSHARD SKY SANCTUARY • THÁNH ĐỊA THÁI DƯƠNG (ZONE 4 • LV. 300–500)",
        "glow_rgb": (255, 218, 95),
    },
    {
        "asset": "CyberportCafeTradingHub",
        "origin": (2020.0, 46.0, 360.0),
        "slab_size": (290.0, 4.0, 290.0),
        "title": "☕ CYBERPORT CAFÉ • QUÁN CÀ PHÊ GIAO DỊCH SEA 2 (ZONE 6 • LV. 700–850)",
        "glow_rgb": (88, 238, 255),
    },
    {
        "asset": "PermafrostGarrisonFortress",
        "origin": (1960.0, 56.0, -180.0),
        "slab_size": (300.0, 4.0, 300.0),
        "title": "❄ PERMAFROST GARRISON • PHÁO ĐÀI TUYẾT BĂNG (ZONE 7 • LV. 850–1050)",
        "glow_rgb": (115, 242, 255),
    },
    {
        "asset": "MicrochipAwakeningRaidLab",
        "origin": (3040.0, 68.0, 120.0),
        "slab_size": (310.0, 4.0, 310.0),
        "title": "⚡ MICROCHIP RAID LAB • PHÒNG THÍ NGHIỆM THỨC TỈNH (ZONE 8 • LV. 1050–1250)",
        "glow_rgb": (95, 240, 255),
    },
    {
        "asset": "GlacialWreckageDangerSea",
        "origin": (2980.0, 44.0, -440.0),
        "slab_size": (320.0, 4.0, 320.0),
        "title": "🚢 GLACIAL WRECKAGE • XÁC TÀU BĂNG CỔ ĐẠI (ZONE 9 • LV. 1250–1375)",
        "glow_rgb": (145, 242, 255),
    },
    {
        "asset": "CastleOnTheVoidMansion",
        "origin": (-3160.0, 56.0, 260.0),
        "slab_size": (320.0, 4.0, 320.0),
        "title": "🏰 CASTLE ON THE VOID • DINH THỰ PHÁO ĐÀI HƯ KHÔNG (ZONE 11 • LV. 1500–1750)",
        "glow_rgb": (225, 110, 255),
    },
    {
        "asset": "UmbralCrystalSanctumForest",
        "origin": (-1920.0, 60.0, 240.0),
        "slab_size": (310.0, 4.0, 310.0),
        "title": "🌲 UMBRAL CRYSTAL SANCTUM • RỪNG TINH THỂ ĐEN (ZONE 12 • LV. 1750–2000)",
        "glow_rgb": (245, 95, 255),
    },
    {
        "asset": "TempleOfTheCoreRaceV4",
        "origin": (-3160.0, 96.0, -320.0),
        "slab_size": (310.0, 4.0, 310.0),
        "title": "⚙ TEMPLE OF THE CORE • ĐỀN THỜ THỨC TỈNH TỘC V4 (ZONE 13 • LV. 2000–2250)",
        "glow_rgb": (210, 120, 255),
    },
    {
        "asset": "MirageSkyIslandLeviathanAbyss",
        "origin": (-2540.0, 68.0, -680.0),
        "slab_size": (310.0, 4.0, 310.0),
        "title": "🌙 MIRAGE SKY ISLAND • VỰC THẲM LEVIATHAN (ZONE 14 • LV. 2250–2400)",
        "glow_rgb": (78, 238, 255),
    },
]

CLEAN_COSMETIC_SERVICE_CODE = """-- V8 Rigged EditableMesh Cosmetic Service (Zero legacy white MeshPart prefabs)
local A={}
function A.Boss(model,body)
    for _,o in ipairs(model:GetDescendants()) do
        if o:IsA("BasePart") then
            o.Anchored=true o.CanCollide=false o.CanTouch=false o.Transparency=1
        end
    end
end
function A.Enemy(model,body,id)
    for _,o in ipairs(model:GetDescendants()) do
        if o:IsA("BasePart") then
            o.Anchored=true o.CanCollide=false o.CanTouch=false o.CanQuery=false o.Transparency=1
        end
    end
end
function A.Weapon(ch,hand,equipped)
    local blade=ch and ch:FindFirstChild("SkybornBlade")
    if blade then blade.Transparency=1 end
    A.Equip(ch,equipped)
end
function A.Guardian(ch)
    local root=ch and ch:FindFirstChild("HumanoidRootPart")
    local humanoid=ch and ch:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return false end
    for _,o in ipairs(ch:GetDescendants()) do
        if o:IsA("BasePart") and o.Name~="HumanoidRootPart" and not o:FindFirstAncestor("SkyGuardianVisual") and not o:FindFirstAncestor("ThunderStrikerVisual") and not o:FindFirstAncestor("ArcaneMageVisual") then
            o.Transparency=1
        end
        if o:IsA("Decal") then
            o.Transparency=1
        end
    end
    ch:SetAttribute("BlenderGuardian",true)
    ch:SetAttribute("SkybreakCosmeticsReady",true)
    return true
end
function A.Equip(ch,equipped)
    if not ch then return end
    local body=ch:FindFirstChild("SkyGuardianVisual")
    if body then
        for _,o in ipairs(body:GetDescendants()) do
            if o:IsA("MeshPart") and o.Name:find("_Weapon_") then
                o.Transparency=equipped and 0 or 1
            end
        end
    end
    local blade=ch:FindFirstChild("SkybornBlade")
    if blade then blade.Transparency=1 end
end
function A.BossSwing(model,windup)
    if model then
        model:SetAttribute("V5SwingAt",workspace:GetServerTimeNow())
    end
end
return A
"""

CLEAN_DELEGATED_WORLD_SERVICE_CODE = """local M={}
function M.Build(W)
    for _,name in {'SkyHub','GoldenSky'} do
        local old=workspace:FindFirstChild(name)
        if old then old:Destroy() end
    end
    local hub=Instance.new('Model');hub.Name='SkyHub';hub.Parent=workspace
    local sky=Instance.new('Model');sky.Name='GoldenSky';sky.Parent=workspace;hub:SetAttribute('WorldVersion',5)
    W.Hub=hub;W.Sky=sky;W.Interactions={}
    require(script.Parent.GoldenSkyCollision)(sky)
    for _,name in {'ActiveEnemies','ActiveBosses','SpawnPoints'} do
        if not workspace:FindFirstChild(name) then
            local f=Instance.new('Folder');f.Name=name;f.Parent=workspace
        end
    end
    local spawn=Instance.new('SpawnLocation');spawn.Name='SkybornSpawn';spawn.Size=Vector3.new(8,1,8);spawn.Position=Vector3.new(-92,36.6,153)
    spawn.Anchored=true;spawn.Transparency=1;spawn.CanCollide=false;spawn.Neutral=true;spawn.Duration=2;spawn.Parent=hub;W.Spawn=spawn
    local locations={
        Lyra={-78,39,145},Kael={-68,39,145},FrozenPortal={16,49,-199},ReturnHub={19,43,20},
        Station1={-18,43,17},Station2={0,43,23},Station3={18,43,17},
        Citizen1={-22,43,-4},Citizen2={0,43,-26},Citizen3={22,43,-4},
        Switch1={-24,43,-25},Switch2={24,43,-25},ArenaGate={0,43,-42},LeaveArena={29,49,-90},
    }
    local labels={Lyra='Lyra • Chỉ Huy Skyborn',Kael='Kael • Thợ Rèn Thần Khí',FrozenPortal='Frozen Cyber • Sea 2',ReturnHub='Về Sky Hub',ArenaGate='Aureon • Vào / bắt đầu trận',LeaveArena='Rời đấu trường'}
    for id,pos in locations do
        local marker=W.Interactable((id=='Lyra' or id=='Kael') and hub or sky,id,Vector3.new(table.unpack(pos)),labels[id]or id)
        marker.Transparency=1
        if id=='Lyra' or id=='Kael' then
            for _,ch in ipairs(marker:GetChildren()) do
                if ch:IsA("BillboardGui") or ch:IsA("ProximityPrompt") then
                    ch:Destroy()
                end
            end
        end
    end
    local floors={sky.GoldenSky_Collision}
    if game.ReplicatedStorage.DelegatedV5Sources:FindFirstChild('FrozenCyber') then
        local origin=require(game.ReplicatedStorage.Shared.RealmConfig).FrozenCyber.Origin
        local oldF=workspace:FindFirstChild('FrozenCyber')
        if oldF then oldF:Destroy() end
        local frozen=Instance.new('Model');frozen.Name='FrozenCyber';frozen.Parent=workspace
        local collision=require(script.Parent.FrozenCyberCollision)(frozen)
        collision=collision or frozen.FrozenCyber_Collision
        for _,o in collision:GetDescendants() do if o:IsA('BasePart')then o.CFrame=CFrame.new(origin)*o.CFrame end end
        table.insert(floors,collision)
        local frHub=W.Interactable(frozen,'FrozenReturnHub',origin+Vector3.new(-101,43,150),'Về Golden Sky')
        if frHub then frHub.Transparency=1 end
        local shPortal=W.Interactable(frozen,'ShadowPortal',origin+Vector3.new(120,68,-130),'Shadow Realm • Sea 3')
        if shPortal then shPortal.Transparency=1 end
    end
    if game.ReplicatedStorage.DelegatedV5Sources:FindFirstChild('ShadowRealm')then
        local origin=require(game.ReplicatedStorage.Shared.RealmConfig).ShadowRealm.Origin
        local oldS=workspace:FindFirstChild('ShadowRealm')
        if oldS then oldS:Destroy() end
        local shadow=Instance.new('Model');shadow.Name='ShadowRealm';shadow.Parent=workspace
        require(script.Parent.ShadowRealmCollision)(shadow)
        local collision=shadow.ShadowRealm_Collision
        for _,o in collision:GetDescendants()do if o:IsA('BasePart')then o.CFrame=CFrame.new(origin)*o.CFrame end end
        table.insert(floors,collision)
        local shRet=W.Interactable(shadow,'ShadowReturnHub',origin+Vector3.new(-158,51,90),'Về Golden Sky')
        if shRet then shRet.Transparency=1 end
    end
    for _,extraName in ipairs({'GrandSkyIslands','VerdantCrown','EmberforgeWastes','AbyssalTides','ChronosBastion','VeilsEnd'}) do
        local ex=workspace:FindFirstChild(extraName)
        if ex then table.insert(floors,ex) end
    end
    local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances=floors
    function W.GroundY(pos)
        local hit=workspace:Raycast(pos+Vector3.new(0,60,0),Vector3.new(0,-180,0),params)
        return hit and hit.Position.Y or pos.Y-3
    end
    workspace:SetAttribute('WorldArtVersion',8)
end
return M
"""


def get_name(node: ET.Element) -> str | None:
    return node.findtext("Properties/string[@name='Name']")


def find_child(parent: ET.Element, child_name: str) -> ET.Element | None:
    return next((x for x in parent.findall("Item") if get_name(x) == child_name), None)


def ensure_item(parent: ET.Element, child_name: str, cls: str) -> ET.Element:
    existing = find_child(parent, child_name)
    if existing is not None:
        if existing.get("class") != cls:
            existing.set("class", cls)
        return existing
    node = ET.SubElement(parent, "Item", {"class": cls, "referent": "RBX" + uuid.uuid4().hex.upper()})
    props = ET.SubElement(node, "Properties")
    ET.SubElement(props, "string", {"name": "Name"}).text = child_name
    if cls in ("Script", "LocalScript"):
        ET.SubElement(props, "bool", {"name": "Disabled"}).text = "false"
    return node


def set_prop(node: ET.Element, tag: str, prop_name: str, value: str) -> None:
    props = node.find("Properties")
    assert props is not None
    p = props.find(f"{tag}[@name='{prop_name}']")
    if p is None:
        p = ET.SubElement(props, tag, {"name": prop_name})
    p.text = value


def rgb_to_uint8(r: int, g: int, b: int) -> str:
    r = max(0, min(255, int(r)))
    g = max(0, min(255, int(g)))
    b = max(0, min(255, int(b)))
    val = (0xFF << 24) | (r << 16) | (g << 8) | b
    return str(val)


def add_part(
    parent: ET.Element,
    name: str,
    size: tuple[float, float, float],
    pos: tuple[float, float, float],
    rgb: tuple[int, int, int],
    material: str = "SmoothPlastic",
    shape: str = "Block",
    can_collide: bool = True,
    transparency: float = 0.0,
) -> ET.Element:
    node = ET.SubElement(parent, "Item", {"class": "Part", "referent": "RBX" + uuid.uuid4().hex.upper()})
    props = ET.SubElement(node, "Properties")
    ET.SubElement(props, "string", {"name": "Name"}).text = name
    ET.SubElement(props, "token", {"name": "shape"}).text = SHAPE_TOKENS.get(shape, "1")
    ET.SubElement(props, "token", {"name": "formFactorRaw"}).text = "1"
    ET.SubElement(props, "bool", {"name": "Anchored"}).text = "true"
    ET.SubElement(props, "bool", {"name": "CanCollide"}).text = "true" if can_collide else "false"
    ET.SubElement(props, "bool", {"name": "CanQuery"}).text = "true" if can_collide else "false"
    ET.SubElement(props, "bool", {"name": "CanTouch"}).text = "false"
    ET.SubElement(props, "bool", {"name": "CastShadow"}).text = "false" if transparency >= 0.99 else "true"
    ET.SubElement(props, "Color3uint8", {"name": "Color3uint8"}).text = rgb_to_uint8(*rgb)
    ET.SubElement(props, "token", {"name": "Material"}).text = MATERIAL_TOKENS.get(material, "272")
    ET.SubElement(props, "float", {"name": "Transparency"}).text = f"{transparency:.3f}"
    ET.SubElement(props, "token", {"name": "TopSurface"}).text = "0"
    ET.SubElement(props, "token", {"name": "BottomSurface"}).text = "0"

    cf = ET.SubElement(props, "CoordinateFrame", {"name": "CFrame"})
    ET.SubElement(cf, "X").text = f"{pos[0]:.3f}"
    ET.SubElement(cf, "Y").text = f"{pos[1]:.3f}"
    ET.SubElement(cf, "Z").text = f"{pos[2]:.3f}"
    r_tags = ("R00", "R01", "R02", "R10", "R11", "R12", "R20", "R21", "R22")
    for tag_name, val in zip(r_tags, (1, 0, 0, 0, 1, 0, 0, 0, 1)):
        ET.SubElement(cf, tag_name).text = f"{val:.6f}"

    sz = ET.SubElement(props, "Vector3", {"name": "size"})
    ET.SubElement(sz, "X").text = f"{max(0.2, size[0]):.3f}"
    ET.SubElement(sz, "Y").text = f"{max(0.2, size[1]):.3f}"
    ET.SubElement(sz, "Z").text = f"{max(0.2, size[2]):.3f}"
    return node


def add_billboard_title(parent_part: ET.Element, title_text: str, rgb: tuple[int, int, int], offset_y: float = 12.0) -> None:
    bb = ET.SubElement(parent_part, "Item", {"class": "BillboardGui", "referent": "RBX" + uuid.uuid4().hex.upper()})
    bprops = ET.SubElement(bb, "Properties")
    ET.SubElement(bprops, "string", {"name": "Name"}).text = "IslandTitleBanner"
    ET.SubElement(bprops, "bool", {"name": "Active"}).text = "true"
    ET.SubElement(bprops, "bool", {"name": "AlwaysOnTop"}).text = "false"
    ET.SubElement(bprops, "bool", {"name": "Enabled"}).text = "true"
    ET.SubElement(bprops, "float", {"name": "MaxDistance"}).text = "120"
    sz = ET.SubElement(bprops, "UDim2", {"name": "Size"})
    ET.SubElement(sz, "XS").text = "0"
    ET.SubElement(sz, "XO").text = "340"
    ET.SubElement(sz, "YS").text = "0"
    ET.SubElement(sz, "YO").text = "52"
    off = ET.SubElement(bprops, "Vector3", {"name": "StudsOffset"})
    ET.SubElement(off, "X").text = "0"
    ET.SubElement(off, "Y").text = f"{offset_y:.1f}"
    ET.SubElement(off, "Z").text = "0"

    tl = ET.SubElement(bb, "Item", {"class": "TextLabel", "referent": "RBX" + uuid.uuid4().hex.upper()})
    tprops = ET.SubElement(tl, "Properties")
    ET.SubElement(tprops, "string", {"name": "Name"}).text = "TitleLabel"
    ET.SubElement(tprops, "float", {"name": "BackgroundTransparency"}).text = "0.35"
    ET.SubElement(tprops, "Color3uint8", {"name": "BackgroundColor3"}).text = rgb_to_uint8(10, 18, 32)
    ET.SubElement(tprops, "Color3uint8", {"name": "TextColor3"}).text = rgb_to_uint8(*rgb)
    ET.SubElement(tprops, "float", {"name": "TextStrokeTransparency"}).text = "0.15"
    ET.SubElement(tprops, "token", {"name": "Font"}).text = "18"
    ET.SubElement(tprops, "float", {"name": "TextSize"}).text = "15"
    ET.SubElement(tprops, "bool", {"name": "TextWrapped"}).text = "true"
    ET.SubElement(tprops, "string", {"name": "Text"}).text = title_text
    tsz = ET.SubElement(tprops, "UDim2", {"name": "Size"})
    ET.SubElement(tsz, "XS").text = "1"
    ET.SubElement(tsz, "XO").text = "0"
    ET.SubElement(tsz, "YS").text = "1"
    ET.SubElement(tsz, "YO").text = "0"


def rebuild_workspace_clean(workspace: ET.Element) -> dict:
    # 1. Remove legacy boxy SkyHub, GoldenSky, old boxy GrandSkyIslands, and boxy expansion realm placeholders
    for legacy_name in ("SkyHub", "GoldenSky", "GrandSkyIslands", "VerdantCrown", "EmberforgeWastes", "AbyssalTides", "ChronosBastion", "VeilsEnd"):
        old = find_child(workspace, legacy_name)
        if old is not None:
            workspace.remove(old)

    # 1b. Create clean invisible walkable collision slabs for Realms 4-8 (3D Macro-Worlds cloned by DelegatedV5)
    for exp_name, exp_origin in (
        ("VerdantCrown", (0.0, 120.0, -2400.0)),
        ("EmberforgeWastes", (2400.0, 120.0, -2400.0)),
        ("AbyssalTides", (-2400.0, 120.0, -2400.0)),
        ("ChronosBastion", (0.0, 180.0, -4200.0)),
        ("VeilsEnd", (0.0, 260.0, -5800.0)),
    ):
        exp_model = ensure_item(workspace, exp_name, "Model")
        add_part(
            exp_model,
            f"{exp_name}_WalkableFloor",
            (310.0, 4.0, 310.0),
            (exp_origin[0], exp_origin[1] - 2.0, exp_origin[2]),
            (95, 220, 255),
            "SmoothPlastic",
            can_collide=True,
            transparency=1.0,
        )

    # 2. Create clean SkyHub with invisible SpawnLocation at (-92, 36.6, 153)
    sky_hub = ensure_item(workspace, "SkyHub", "Model")
    spawn = ET.SubElement(sky_hub, "Item", {"class": "SpawnLocation", "referent": "RBX" + uuid.uuid4().hex.upper()})
    sprops = ET.SubElement(spawn, "Properties")
    ET.SubElement(sprops, "string", {"name": "Name"}).text = "SkybornSpawn"
    ET.SubElement(sprops, "bool", {"name": "Anchored"}).text = "true"
    ET.SubElement(sprops, "bool", {"name": "CanCollide"}).text = "false"
    ET.SubElement(sprops, "bool", {"name": "Neutral"}).text = "true"
    ET.SubElement(sprops, "float", {"name": "Transparency"}).text = "1.000"
    cf = ET.SubElement(sprops, "CoordinateFrame", {"name": "CFrame"})
    ET.SubElement(cf, "X").text = "-92.000"
    ET.SubElement(cf, "Y").text = "36.600"
    ET.SubElement(cf, "Z").text = "153.000"
    for tag_name, val in zip(("R00", "R01", "R02", "R10", "R11", "R12", "R20", "R21", "R22"), (1, 0, 0, 0, 1, 0, 0, 0, 1)):
        ET.SubElement(cf, tag_name).text = f"{val:.6f}"
    sz = ET.SubElement(sprops, "Vector3", {"name": "size"})
    ET.SubElement(sz, "X").text = "8.000"
    ET.SubElement(sz, "Y").text = "1.000"
    ET.SubElement(sz, "Z").text = "8.000"

    # 3. Create clean GoldenSky container (collision built by GoldenSkyCollision module + 3D art streamed by DelegatedV5)
    ensure_item(workspace, "GoldenSky", "Model")

    # 4. Create clean GrandSkyIslands with ONLY invisible walkable collision slabs + title banners (3D art streamed by DelegatedV5)
    islands_folder = ensure_item(workspace, "GrandSkyIslands", "Folder")
    for spec in GRAND_SKY_ISLANDS_STORYLINE:
        asset_name = spec["asset"]
        wx, wy, wz = spec["origin"]
        sx, sy, sz_val = spec["slab_size"]
        isl_collision = ensure_item(islands_folder, f"Collision_{asset_name}", "Model")
        slab = add_part(
            isl_collision,
            f"{asset_name}_WalkableFloor",
            (sx, sy, sz_val),
            (wx, wy - sy * 0.5, wz),
            spec["glow_rgb"],
            "SmoothPlastic",
            can_collide=True,
            transparency=1.0,
        )
        add_billboard_title(slab, spec["title"], spec["glow_rgb"], offset_y=18.0)

    return {
        "grand_sky_islands_clean_collision_models": len(GRAND_SKY_ISLANDS_STORYLINE),
    }


def classify_lua_file(file_path: Path) -> tuple[str, str]:
    name = file_path.name
    if name.endswith(".server.lua"):
        return name[: -len(".server.lua")], "Script"
    if name.endswith(".client.lua"):
        return name[: -len(".client.lua")], "LocalScript"
    if name.endswith(".lua"):
        return name[: -len(".lua")], "ModuleScript"
    raise ValueError(f"Unsupported file: {file_path}")


def collect_ui_entries() -> list[tuple[list[str], str, Path]]:
    entries: list[tuple[list[str], str, Path]] = []

    shared_dir = SRC_ROOT / "ReplicatedStorage" / "SkybreakShared"
    for f in sorted(shared_dir.rglob("*.lua")):
        rel_parts = list(f.relative_to(SRC_ROOT).parent.parts)
        node_name, cls = classify_lua_file(f)
        entries.append((rel_parts + [node_name], cls, f))

    client_dir = SRC_ROOT / "StarterPlayer" / "StarterPlayerScripts" / "SkybreakClient"
    for f in sorted(client_dir.rglob("*.lua")):
        rel_parts = list(f.relative_to(SRC_ROOT).parent.parts)
        node_name, cls = classify_lua_file(f)
        entries.append((rel_parts + [node_name], cls, f))

    server_dir = SRC_ROOT / "ServerScriptService" / "SkybreakServer"
    for f in sorted(server_dir.rglob("*.lua")):
        rel_parts = list(f.relative_to(SRC_ROOT).parent.parts)
        node_name, cls = classify_lua_file(f)
        entries.append((rel_parts + [node_name], cls, f))

    ui_bridge_dir = SRC_ROOT / "StarterPlayer" / "StarterPlayerScripts" / "UI"
    for bridge_name in ("Theme.lua", "Interface.lua"):
        f = ui_bridge_dir / bridge_name
        node_name, cls = classify_lua_file(f)
        entries.append((["StarterPlayer", "StarterPlayerScripts", "UI", node_name], cls, f))

    ui_ctrl_path = SRC_ROOT / "StarterPlayer" / "StarterPlayerScripts" / "SkybreakUIController.client.lua"
    if ui_ctrl_path.exists():
        entries.append((["StarterPlayer", "StarterPlayerScripts", "SkybreakUIController"], "LocalScript", ui_ctrl_path))

    entries.append((["ReplicatedStorage", "Shared", "RealmConfig"], "ModuleScript", SRC_ROOT / "ReplicatedStorage/Shared/RealmConfig.lua"))
    entries.append((["ReplicatedStorage", "Shared", "RealmEnvironment"], "ModuleScript", SRC_ROOT / "ReplicatedStorage/Shared/RealmEnvironment.lua"))
    if LUAU_V8_DIR.is_dir():
        entries.append((["ReplicatedStorage", "DelegatedV5Renderer"], "ModuleScript", LUAU_V8_DIR / "DelegatedV5Renderer.lua"))
        entries.append((["StarterPlayer", "StarterPlayerScripts", "DelegatedV5"], "LocalScript", LUAU_V8_DIR / "DelegatedV5.client.lua"))
        entries.append((["StarterPlayer", "StarterPlayerScripts", "BlenderEnemies"], "LocalScript", LUAU_V8_DIR / "BlenderEnemies.client.lua"))
        entries.append((["StarterPlayer", "StarterPlayerScripts", "ClientBootstrap"], "LocalScript", LUAU_V8_DIR / "ClientBootstrap.lua"))
        entries.append((["ReplicatedStorage", "Shared", "Config"], "ModuleScript", LUAU_V8_DIR / "Config.lua"))
        entries.append((["ServerScriptService", "Services", "GameService"], "ModuleScript", LUAU_V8_DIR / "GameService.lua"))
        entries.append((["ServerScriptService", "Services", "PlayerDataService"], "ModuleScript", LUAU_V8_DIR / "PlayerDataService.lua"))

    return entries


def build_module_with_chunks(folder: ET.Element, label: str, raw_b64: str) -> tuple[int, int]:
    module = ensure_item(folder, label, "ModuleScript")
    for old_child in list(module.findall("Item")):
        module.remove(old_child)
    set_prop(module, "ProtectedString", "Source", LOADER)
    chunks = [raw_b64[i : i + 150000] for i in range(0, len(raw_b64), 150000)]
    for idx, chunk in enumerate(chunks, 1):
        val = ensure_item(module, f"Data{idx:03d}", "StringValue")
        set_prop(val, "string", "Value", chunk)
    return len(raw_b64), len(chunks)


def populate_asset_folder(sources: ET.Element, target_name: str, source_dir: Path) -> dict:
    folder = ensure_item(sources, target_name, "Folder")
    existing_clips = find_child(folder, "Clips")

    for child in list(folder.findall("Item")):
        folder.remove(child)

    clips_json_path = source_dir / "Clips.json"
    has_nonempty_clips = False
    clip_count = 0
    if clips_json_path.exists():
        clips_data = json.loads(clips_json_path.read_text(encoding="utf-8"))
        if isinstance(clips_data, dict) and len(clips_data) > 0:
            has_nonempty_clips = True
            clip_count = len(clips_data)

    b64_bytes = 0
    raw_bytes = 0
    module_count = 0
    chunk_count = 0
    mesh_count = 0

    for blob in sorted(source_dir.glob("*.zstd.b64")):
        original_name = blob.name.removesuffix(".zstd.b64")
        label = original_name.removesuffix(".json")
        if label == "Clips" and not has_nonempty_clips:
            if existing_clips is not None:
                folder.append(existing_clips)
                module_count += 1
            continue

        raw_b64 = blob.read_text(encoding="utf-8").strip()
        orig_file = source_dir / original_name
        if orig_file.exists():
            raw_bytes += orig_file.stat().st_size

        b_len, c_len = build_module_with_chunks(folder, label, raw_b64)
        b64_bytes += b_len
        chunk_count += c_len
        module_count += 1
        if label.startswith("Mesh"):
            mesh_count += 1

    header_data = json.loads((source_dir / "Header.json").read_text(encoding="utf-8"))
    expected_mc = header_data.get("mesh_count", len(header_data.get("meshes", [])))
    assert mesh_count == expected_mc, (
        f"{target_name}: built {mesh_count} meshes but Header expected {expected_mc}"
    )

    return {
        "source": source_dir.name,
        "mesh_count": mesh_count,
        "triangles": header_data.get("triangles", 0),
        "bones": len(header_data.get("bones", [])),
        "clips": clip_count,
        "modules": module_count,
        "chunks": chunk_count,
        "b64_bytes": b64_bytes,
        "raw_bytes": raw_bytes,
    }


def build_canonical_starter_gui(scene: ET.Element) -> None:
    sg = find_child(scene, "StarterGui")
    if sg is None:
        return
    sky_gui = ensure_item(sg, "SkybreakGui", "ScreenGui")
    for ch in list(sky_gui.findall("Item")):
        sky_gui.remove(ch)
    set_prop(sky_gui, "bool", "ResetOnSpawn", "false")
    set_prop(sky_gui, "bool", "IgnoreGuiInset", "true")
    set_prop(sky_gui, "bool", "Enabled", "false")

    # 1. MainMenu (CanvasGroup)
    main_menu = ensure_item(sky_gui, "MainMenu", "CanvasGroup")
    logo_group = ensure_item(main_menu, "LogoGroup", "Frame")
    ensure_item(logo_group, "LogoBase", "ImageLabel")
    ensure_item(logo_group, "LogoGlow", "ImageLabel")
    ensure_item(main_menu, "CorePulse", "ImageLabel")
    btn_col = ensure_item(main_menu, "ButtonColumn", "Frame")
    play_btn = ensure_item(btn_col, "PlayButton", "ImageButton")
    ensure_item(play_btn, "UIScale", "UIScale")
    ensure_item(play_btn, "UIStroke", "UIStroke")
    ensure_item(btn_col, "ContinueButton", "ImageButton")
    ensure_item(btn_col, "RealmSelectButton", "ImageButton")
    ensure_item(btn_col, "SettingsButton", "ImageButton")

    # 2. CombatHUD (Frame)
    combat_hud = ensure_item(sky_gui, "CombatHUD", "Frame")
    vitals = ensure_item(combat_hud, "VitalsCard", "Frame")
    ensure_item(vitals, "HPBar", "Frame")
    ensure_item(vitals, "EnergyBar", "Frame")
    ensure_item(vitals, "EXPBar", "Frame")
    ensure_item(combat_hud, "QuestTracker", "Frame")
    ensure_item(combat_hud, "MinimapCard", "Frame")
    hotbar = ensure_item(combat_hud, "SkillHotbar", "Frame")
    ensure_item(hotbar, "Slot1", "ImageButton")
    ensure_item(hotbar, "Slot2", "ImageButton")
    ensure_item(hotbar, "Slot3", "ImageButton")
    ensure_item(hotbar, "DodgeSlot", "ImageButton")
    ult_slot = ensure_item(hotbar, "UltimateSlot", "ImageButton")
    ensure_item(ult_slot, "UltimateRing", "ImageLabel")
    ensure_item(combat_hud, "BossWarningBanner", "CanvasGroup")

    # 3. InventoryPanel (CanvasGroup)
    inv_panel = ensure_item(sky_gui, "InventoryPanel", "CanvasGroup")
    char_prev = ensure_item(inv_panel, "CharacterPreview", "Frame")
    inv_vp = ensure_item(char_prev, "ViewportFrame", "ViewportFrame")
    ensure_item(inv_vp, "WorldModel", "WorldModel")
    ensure_item(inv_vp, "PreviewCamera", "Camera")
    ensure_item(inv_panel, "EquipSlots", "Frame")
    ensure_item(inv_panel, "ItemGrid", "ScrollingFrame")
    ensure_item(inv_panel, "TooltipCard", "CanvasGroup")

    # 4. SkillsPanel (CanvasGroup)
    skills_panel = ensure_item(sky_gui, "SkillsPanel", "CanvasGroup")
    ensure_item(skills_panel, "ClassTabs", "Frame")
    ensure_item(skills_panel, "NodeCanvas", "Frame")
    ensure_item(skills_panel, "SkillDetailCard", "Frame")

    # 5. WorldMapPanel (CanvasGroup)
    map_panel = ensure_item(sky_gui, "WorldMapPanel", "CanvasGroup")
    ensure_item(map_panel, "MapCanvas", "Frame")
    ensure_item(map_panel, "RegionDetailCard", "Frame")
    ensure_item(map_panel, "FastTravelButton", "ImageButton")

    # 6. ForgePanel (CanvasGroup)
    forge_panel = ensure_item(sky_gui, "ForgePanel", "CanvasGroup")
    weap_prev = ensure_item(forge_panel, "WeaponPreview", "Frame")
    forge_vp = ensure_item(weap_prev, "ViewportFrame", "ViewportFrame")
    ensure_item(forge_vp, "WorldModel", "WorldModel")
    ensure_item(forge_vp, "PreviewCamera", "Camera")
    ensure_item(forge_panel, "MaterialSlots", "Frame")
    ensure_item(forge_panel, "CraftButton", "ImageButton")

    # 7. DialoguePanel, 8. RaidHUD, 9. SettingsPanel (CanvasGroup)
    ensure_item(sky_gui, "DialoguePanel", "CanvasGroup")
    ensure_item(sky_gui, "RaidHUD", "CanvasGroup")
    ensure_item(sky_gui, "SettingsPanel", "CanvasGroup")


def rework_rbxlx(source_rbxlx: Path, output_rbxlx: Path, entries: list[tuple[list[str], str, Path]]) -> dict:
    tree = ET.parse(source_rbxlx)
    scene = tree.getroot()
    build_canonical_starter_gui(scene)

    rs = find_child(scene, "ReplicatedStorage")
    assert rs is not None, "Missing ReplicatedStorage"
    delegated_sources = ensure_item(rs, "DelegatedV5Sources", "Folder")

    # 1. Inject all 78 runtime_v8 folders (63 rigged/animated + 15 worlds/islands)
    assets_updated = 0
    total_rigged_clips = 0
    for asset_dir in sorted(RUNTIME_V8_DIR.iterdir()):
        if asset_dir.is_dir() and (asset_dir / "Header.json.zstd.b64").exists() and (asset_dir / "Header.json").exists():
            info = populate_asset_folder(delegated_sources, asset_dir.name, asset_dir)
            assets_updated += 1
            total_rigged_clips += info["clips"]

    # 2. Purge ServerStorage legacy white untextured MeshParts (VisualPrefabs, SkybornMeshSources, SkybornStaging)
    ss = find_child(scene, "ServerStorage")
    if ss is not None:
        for legacy_ss in ("VisualPrefabs", "SkybornMeshSources", "SkybornStaging", "LegacyV4World"):
            old_node = find_child(ss, legacy_ss)
            if old_node is not None:
                ss.remove(old_node)

    # 3. Rebuild Workspace cleanly without legacy boxy SkyHub/GoldenSky/GrandSkyIslands or white untextured MeshParts
    ws = find_child(scene, "Workspace")
    assert ws is not None, "Missing Workspace"
    ws_metrics = rebuild_workspace_clean(ws)

    # 4. Update DelegatedWorldService and CosmeticService in ServerScriptService.Services
    sss = find_child(scene, "ServerScriptService")
    services_folder = find_child(sss, "Services") if sss is not None else None
    if services_folder is not None:
        dws_node = ensure_item(services_folder, "DelegatedWorldService", "ModuleScript")
        set_prop(dws_node, "ProtectedString", "Source", CLEAN_DELEGATED_WORLD_SERVICE_CODE)
        cs_node = ensure_item(services_folder, "CosmeticService", "ModuleScript")
        set_prop(cs_node, "ProtectedString", "Source", CLEAN_COSMETIC_SERVICE_CODE)

    # 5. Inject all Luau scripts & UI modules
    injected_count = 0
    total_code_bytes = 0
    for path_parts, cls, file_path in entries:
        cur = scene
        top_service = find_child(cur, path_parts[0])
        assert top_service is not None, f"Missing top-level service {path_parts[0]}"
        cur = top_service

        for folder_name in path_parts[1:-1]:
            existing = find_child(cur, folder_name)
            if existing is not None:
                cur = existing
            else:
                cur = ensure_item(cur, folder_name, "Folder")

        leaf_name = path_parts[-1]
        leaf_node = ensure_item(cur, leaf_name, cls)
        code = file_path.read_text(encoding="utf-8")
        set_prop(leaf_node, "ProtectedString", "Source", code)
        injected_count += 1
        total_code_bytes += len(code.encode("utf-8"))

    # Ensure ClientBootstrap is enabled (soft lighting) and legacy NativeGeometry / BlenderNPCs are disabled
    sp = find_child(scene, "StarterPlayer")
    sps = find_child(sp, "StarterPlayerScripts") if sp is not None else None
    if sps is not None:
        cb = find_child(sps, "ClientBootstrap")
        if cb is not None:
            set_prop(cb, "bool", "Disabled", "false")
        bnpcs = find_child(sps, "BlenderNPCs")
        if bnpcs is not None:
            set_prop(bnpcs, "bool", "Disabled", "true")
    if sss is not None:
        ng = find_child(sss, "NativeGeometry")
        if ng is not None:
            set_prop(ng, "bool", "Disabled", "true")

    tmp_out = output_rbxlx.with_suffix(".tmp.rbxlx")
    ET.ElementTree(scene).write(tmp_out, encoding="utf-8", xml_declaration=True)

    # Verify written XML
    verify_root = ET.parse(tmp_out).getroot()
    remaining_meshparts = len(verify_root.findall(".//Item[@class='MeshPart']"))
    verify_rs = find_child(verify_root, "ReplicatedStorage")
    verify_delegated = find_child(verify_rs, "DelegatedV5Sources") if verify_rs is not None else None
    delegated_after = len(verify_delegated.findall("Item")) if verify_delegated is not None else 0

    assert remaining_meshparts == 0, f"Expected 0 legacy white MeshParts, found {remaining_meshparts}"
    assert delegated_after >= 78, f"Expected >= 78 DelegatedV5Sources folders, found {delegated_after}"

    tmp_out.replace(output_rbxlx)
    sha256_hex = hashlib.sha256(output_rbxlx.read_bytes()).hexdigest().upper()

    return {
        "file": str(output_rbxlx),
        "size_bytes": output_rbxlx.stat().st_size,
        "sha256": sha256_hex,
        "injected_scripts": injected_count,
        "injected_code_bytes": total_code_bytes,
        "legacy_white_meshparts_remaining": remaining_meshparts,
        "delegated_v5_folders_total": delegated_after,
        "runtime_v8_folders_updated": assets_updated,
        "total_rigged_clips_injected": total_rigged_clips,
        "workspace_clean_metrics": ws_metrics,
    }


def main() -> None:
    entries = collect_ui_entries()
    print(f"Collected {len(entries)} UI/UX + World script & module entries to inject.")

    shutil.copy2(SRC_ROOT / "StarterPlayer/StarterPlayerScripts/UI/Theme.lua", LUAU_V8_DIR / "Theme.lua")
    shutil.copy2(SRC_ROOT / "StarterPlayer/StarterPlayerScripts/UI/Interface.lua", LUAU_V8_DIR / "Interface.lua")
    shutil.copy2(LUAU_V8_DIR / "Config.lua", SRC_ROOT / "ReplicatedStorage/Shared/Config.lua")

    v12_roblox_path = ROBLOX_DIR / "SKYBREAK_Playable_v12_PremiumUI.rbxlx"
    report = rework_rbxlx(v12_roblox_path, v12_roblox_path, entries)

    target_copies = [
        V2_ROOT / "SKYBREAK_Playable_v12_PremiumUI.rbxlx",
        V2_ROOT / "SKYBREAK_Playable_v8.rbxlx",
        ROBLOX_DIR / "SKYBREAK_Playable_v11_GrandSkySeas.rbxlx",
        ROBLOX_DIR / "SKYBREAK_Playable_v11_BloxFruitsScale.rbxlx",
        ROBLOX_DIR / "SKYBREAK_Playable_v10_BigUpdate.rbxlx",
        ROBLOX_DIR / "SKYBREAK_Playable_v9.rbxlx",
        ROBLOX_DIR / "SKYBREAK_Playable_v8.rbxlx",
        WORK_DIR / "SKYBREAK_Playable_v8_Refined.rbxlx",
    ]
    for target in target_copies:
        shutil.copy2(v12_roblox_path, target)

    print(json.dumps({"status": "OK", "primary_build": report, "copied_to": [str(p) for p in target_copies]}, indent=2))


if __name__ == "__main__":
    main()
