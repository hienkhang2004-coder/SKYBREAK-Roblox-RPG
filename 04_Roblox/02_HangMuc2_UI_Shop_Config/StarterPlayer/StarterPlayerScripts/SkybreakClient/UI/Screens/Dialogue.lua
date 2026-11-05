-- SKYBREAK: Fragments of the Core — Contextual 3D NPC Dialogue Overlay (Figma File 3 Board 01 1:1)
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/Dialogue.lua
-- Covers Tasks #8, #94, #98 with 100% geometric vector icons and zero tofu glyphs.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))
local UIState = require(Shared:WaitForChild("Types"):WaitForChild("UIState"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Store = require(script.Parent.Parent:WaitForChild("Store"))
local ScreenRouter = require(script.Parent.Parent:WaitForChild("ScreenRouter"))
local I18n = require(script.Parent.Parent:WaitForChild("I18n"))
local PremiumPanel = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumPanel"))
local PremiumButton = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumButton"))
local ViewportOrbit = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("ViewportOrbit"))
local QuestController = require(script.Parent.Parent:WaitForChild("Controllers"):WaitForChild("QuestController"))

local Dialogue = {}

function Dialogue.DispatchActionCommand(cmd)
    if type(cmd) ~= "string" or #cmd == 0 then
        return
    end
    if cmd:sub(1, 19) == "OpenScreen:NPCShop:" then
        local mode = cmd:sub(20)
        if #mode > 0 then
            Store.SetView({ activeVendorMode = mode })
        end
        ScreenRouter.Navigate(UIState.Screens.NPCShop, { forceRebuild = true })
    elseif cmd:sub(1, 11) == "OpenScreen:" then
        local targetScreen = cmd:sub(12)
        if targetScreen:find("NPCShop:") == 1 then
            local mode = targetScreen:sub(9)
            if #mode > 0 then
                Store.SetView({ activeVendorMode = mode })
            end
            ScreenRouter.Navigate(UIState.Screens.NPCShop, { forceRebuild = true })
        else
            ScreenRouter.Navigate(targetScreen)
        end
    end
end

-- Resolve speaker keyword, short tag, 3D rig fallback, accent color, sculpted bust archetype & contextual choices
local SPEAKER_PRESETS = {
    zioles = {
        Short = "ZIOLES",
        V5 = "ZiolesGachaNPC",
        Accent = Color3.fromRGB(204, 108, 255),
        Archetype = "mage_hood",
        RoleVi = "ĐIỆN THỜ GACHA • SKY HUB",
        RoleEn = "GACHA SHRINE • SKY HUB",
        C1Vi = "[1] MỞ ĐÀI TRIỆU HỒI GACHA",
        C1En = "[1] OPEN GACHA SHRINE",
        C1Cmd = "OpenScreen:Fruits",
        C1Icon = "Star",
        C2Vi = "[2] XEM KHO TRÁI & THỨC TỈNH [G]",
        C2En = "[2] FRUIT VAULT & AWAKEN [G]",
        C2Cmd = "OpenScreen:NPCShop:MirageDealer",
        C2Icon = "Fruit",
        C3Vi = "[3] TỶ LỆ RƠI & BẢO HIỂM PITY",
        C3En = "[3] DROP RATES & PITY INFO",
        LoreVi = "\"Tỷ lệ minh bạch 6 phẩm cấp: Common 42% • Uncommon 25% • Rare 18% • Epic 9% • Legendary 4.5% • Mythic 1.5%! Đủ 50 lượt kích hoạt Bảo Hiểm Pity chắc chắn nhận Trái Huyền Thoại hoặc Thần Thoại 3D!\"",
        LoreEn = "\"Transparent 6-tier odds: Common 42% • Uncommon 25% • Rare 18% • Epic 9% • Legendary 4.5% • Mythic 1.5%! At 50 rolls, Mythic Pity guarantees a Legendary or Mythic 3D Fruit!\"",
    },
    mirage = {
        Short = "MIRAGE",
        V5 = "ZiolesGachaNPC",
        Accent = Color3.fromRGB(252, 211, 77),
        Archetype = "mage_hood",
        RoleVi = "KHO TRÁI 2 GIỜ • ĐẢO ẢO ẢNH",
        RoleEn = "2H ROTATING STOCK • MIRAGE",
        C1Vi = "[1] MỞ KỆ TRÁI MIRAGE 2 GIỜ",
        C1En = "[1] OPEN 2H MIRAGE STOCK",
        C1Cmd = "OpenScreen:NPCShop:MirageDealer",
        C1Icon = "Gold",
        C2Vi = "[2] ĐÀI GACHA ZIOLES [G]",
        C2En = "[2] ZIOLES GACHA [G]",
        C2Cmd = "OpenScreen:Fruits",
        C2Icon = "Fruit",
        C3Vi = "[3] CƠ CHẾ ĐẢO BÍ ẨN MIRAGE",
        C3En = "[3] MIRAGE ISLAND LORE",
        LoreVi = "\"Kệ hàng của ta làm mới mỗi 2 giờ trên toàn máy chủ! Nếu bắt gặp ta trên Đảo Bí Ẩn Mirage (tồn tại 15 phút), tỷ lệ xuất hiện Trái Thần Thoại Kim Thân & Hắc Long tăng gấp 3 lần!\"",
        LoreEn = "\"My fruit shelves refresh every 2 hours! Find me on Mirage Island during its 15-minute window for 3x Mythic stock odds!\"",
    },
    sword = {
        Short = "KIẾM SƯ",
        V5 = "GoldenKnight",
        Accent = Color3.fromRGB(252, 211, 77),
        Archetype = "samurai_kabuto",
        RoleVi = "CỬA HÀNG DANH KIẾM • SKY 1-3",
        RoleEn = "MASTER SWORD DEALER • SKY 1-3",
        C1Vi = "[1] CỬA HÀNG DANH KIẾM 3D",
        C1En = "[1] 3D MASTER SWORD SHOP",
        C1Cmd = "OpenScreen:NPCShop:SwordDealer",
        C1Icon = "Sword",
        C2Vi = "[2] LÒ RÈN THẦN KHÍ KAEL",
        C2En = "[2] CELESTIAL FORGE",
        C2Cmd = "OpenScreen:Forge",
        C2Icon = "Forge",
        C3Vi = "[3] BÍ KÍP SONG KIẾM CDK",
        C3En = "[3] DUAL BLADES LORE",
        LoreVi = "\"Mỗi thanh Danh Kiếm 3D sở hữu 2 tuyệt kỹ [Z] và [X] riêng biệt! Đạt Thông Thạo Lv.350 trên Song Đao Stormfang và Yêu Đao Yamo để rèn mở khóa Song Kiếm Huyền Thoại CDK!\"",
        LoreEn = "\"Every 3D Blade carries bespoke [Z] and [X] weapon skills! Master Stormfang and Yamo to unlock Cursed Dual Skyblades!\"",
    },
    gun = {
        Short = "XẠ THỦ",
        V5 = "LightArcher",
        Accent = Color3.fromRGB(56, 189, 248),
        Archetype = "tactical_goggles",
        RoleVi = "XƯỞNG PHÁP KHÍ & THẦN GIÁP",
        RoleEn = "ARCANE GUNSMITH & ARMOR",
        C1Vi = "[1] SÚNG 3D & 8 BỘ THẦN GIÁP",
        C1En = "[1] 3D GUNS & 8 ARMOR SETS",
        C1Cmd = "OpenScreen:NPCShop:GunDealer",
        C1Icon = "Gun",
        C2Vi = "[2] MỞ HÀNH TRANG 3D [I]",
        C2En = "[2] 3D INVENTORY [I]",
        C2Cmd = "OpenScreen:Inventory",
        C2Icon = "Shield",
        C3Vi = "[3] HIỆU ỨNG BỘ GIÁP 2/4 & 4/4",
        C3En = "[3] ARMOR SET BONUSES",
        LoreVi = "\"Pháp khí tầm xa bắn đạn nguyên tố xuyên giáp! Kết hợp đủ 2/4 và 4/4 món Thần Giáp 3D cùng bộ sẽ kích hoạt Hào Quang Cộng Hưởng tăng mạnh ATK, HP và Chí Mạng!\"",
        LoreEn = "\"Pair 2/4 and 4/4 wearable 3D Armor pieces from the same set to unlock powerful Resonance Set Bonuses!\"",
    },
    monk = {
        Short = "ĐẠI SƯ",
        V5 = "AncientMonkNPC",
        Accent = Color3.fromRGB(52, 211, 153),
        Archetype = "monk_halo",
        RoleVi = "VÕ ĐƯỜNG CỔ TỰ • SLOT [1]",
        RoleEn = "MARTIAL DOJO • SLOT [1]",
        C1Vi = "[1] LĨNH HỘI 7 VÕ ĐƯỜNG 3D",
        C1En = "[1] 7 MARTIAL ARTS DOJOS",
        C1Cmd = "OpenScreen:NPCShop:MartialDojo",
        C1Icon = "Fist",
        C2Vi = "[2] BẢNG CHỈ SỐ & KỸ NĂNG [K]",
        C2En = "[2] STATS & MASTERY [K]",
        C2Cmd = "OpenScreen:Skills",
        C2Icon = "Bolt",
        C3Vi = "[3] ĐIỀU KIỆN GODHUMAN",
        C3En = "[3] GODHUMAN REQUIREMENTS",
        LoreVi = "\"Tu luyện thông thạo 4 hệ quyền pháp cơ bản lên Lv.400 để lĩnh hội Thiên Thần Tuyệt Kỹ Godhuman và Chưởng Pháp Thời Không Hư Không Lv.2450!\"",
        LoreEn = "\"Master the foundational martial styles to Lv.400 to awaken Celestial Godhuman and Chrono Void Palm!\"",
    },
    enchant = {
        Short = "PHÙ PHÉP",
        V5 = "ZiolesGachaNPC",
        Accent = Color3.fromRGB(192, 132, 252),
        Archetype = "rune_hood",
        RoleVi = "PHÁP SƯ CỔ NGỮ • ENCHANTER",
        RoleEn = "ARCANE ENCHANTER • RUNES",
        C1Vi = "[1] KHẮC PHÙ PHÉP CỔ NGỮ",
        C1En = "[1] INSCRIBE WEAPON RUNES",
        C1Cmd = "OpenScreen:NPCShop:EnchanterAndChronos",
        C1Icon = "CoreShards",
        C2Vi = "[2] LÒ RÈN NÂNG CẤP SAO",
        C2En = "[2] STAR UPGRADE FORGE",
        C2Cmd = "OpenScreen:Forge",
        C2Icon = "Forge",
        C3Vi = "[3] 5 DÒNG PHÙ PHÉP THẦN",
        C3En = "[3] MYTHIC BLESSING ODDS",
        LoreVi = "\"Dùng Cuộn Cổ Ngữ hoặc Core Shards để khắc 5 dòng phù phép Huyền Thoại: Hút Máu Vampiric, Giảm Hồi Chiêu ChronoHaste, Lôi Điện ChainVolt, Bạo Kích SolarCrit và Kỳ Điểm Veyr!\"",
        LoreEn = "\"Use Enchant Scrolls or Core Shards to roll Vampiric, ChronoHaste, ChainVolt, SolarCrit, or Mythic Veyr Singularity!\"",
    },
    chronos = {
        Short = "CHRONOS",
        V5 = "ZiolesGachaNPC",
        Accent = Color3.fromRGB(168, 85, 247),
        Archetype = "void_horns",
        RoleVi = "CHỢ ĐEN HƯ KHÔNG • 10 PHÚT",
        RoleEn = "10-MIN VOID BLACK MARKET",
        C1Vi = "[1] MỞ CHỢ ĐEN HƯ KHÔNG",
        C1En = "[1] OPEN VOID BLACK MARKET",
        C1Cmd = "OpenScreen:NPCShop:EnchanterAndChronos",
        C1Icon = "Void",
        C2Vi = "[2] ĐỊNH VỊ BẢN ĐỒ ĐẢO [M]",
        C2En = "[2] WORLD ISLAND MAP [M]",
        C2Cmd = "OpenScreen:WorldMap",
        C2Icon = "Compass",
        C3Vi = "[3] QUY LUẬT DỊCH CHUYỂN",
        C3En = "[3] WANDERING MERCHANT LORE",
        LoreVi = "\"Mỗi 10 phút ta dịch chuyển ngẫu nhiên sang 1 trong 20 hòn đảo bay, bán vật phẩm hiếm bằng Core Shards rẻ hơn giá gốc 20-35%! Hãy mua nhanh kẻo lỡ!\"",
        LoreEn = "\"Every 10 minutes I warp to a new sky island with 20-35% discounted Core Shard contraband!\"",
    },
    shipwright = {
        Short = "ĐÓNG TÀU",
        V5 = "ShipwrightNPC",
        Accent = Color3.fromRGB(56, 189, 248),
        Archetype = "captain_tricorn",
        RoleVi = "XƯỞNG CHIẾN HẠM BAY • DOCK",
        RoleEn = "3D SKY-SHIPWRIGHT DOCK",
        C1Vi = "[1] XƯỞNG ĐÓNG & GỌI TÀU 3D",
        C1En = "[1] 3D WARSHIP DOCKYARD",
        C1Cmd = "OpenScreen:NPCShop:Shipwright",
        C1Icon = "Ship",
        C2Vi = "[2] TỔ ĐỘI SĂN THỦY QUÁI [B]",
        C2En = "[2] CREW & SEABEAST [B]",
        C2Cmd = "OpenScreen:SocialRewards",
        C2Icon = "Users",
        C3Vi = "[3] KỲ HẠM SĂN LEVIATHAN",
        C3En = "[3] LEVIATHAN HARPOON LORE",
        LoreVi = "\"Kỳ Hạm Leviathan Hunter trang bị 8 Đại Pháo Aether và Móc Cáp Harpoon chuyên dụng để kéo Trái Tim Thủy Tổ Leviathan từ Vùng Biển Nguy Hiểm 6 về cảng!\"",
        LoreEn = "\"The Leviathan Hunter Dreadnought mounts an Abyssal Harpoon to haul the Leviathan Heart back to port!\"",
    },
    vega = {
        Short = "DR. VEGA",
        V5 = "ShipwrightNPC",
        Accent = Color3.fromRGB(45, 212, 191),
        Archetype = "scientist_visor",
        RoleVi = "PHÒNG THÍ NGHIỆM TỘC & RAID V2",
        RoleEn = "RACE LAB & RAID V2",
        C1Vi = "[1] ĐỔI 6 TỘC & ĐỀN TỘC V4",
        C1En = "[1] 6-RACE LAB & V4 ALTAR",
        C1Cmd = "OpenScreen:NPCShop:DrVegaAndTempleV4",
        C1Icon = "Wing",
        C2Vi = "[2] ĐỘT KÍCH RAID TRÁI V2 [P]",
        C2En = "[2] AWAKENING RAID V2 [P]",
        C2Cmd = "OpenScreen:Raid",
        C2Icon = "Raid",
        C3Vi = "[3] TỶ LỆ 6 HUYẾT THỐNG",
        C3En = "[3] 6 LINEAGE REROLL ODDS",
        LoreVi = "\"Tỷ lệ tái cấu trúc 6 Huyết Thống: Skyborn 25% • Mink 25% • Leviathan 20% • Cyborg 12% • Ghoul 12% • Cổ Long Draco 6%! Vượt 5 đảo Raid V2 nhận +1,000 Core Shards!\"",
        LoreEn = "\"Lineage odds: Skyborn 25% • Mink 25% • Leviathan 20% • Cyborg 12% • Ghoul 12% • Ancient Draco 6%!\"",
    },
    temple = {
        Short = "TẾ ĐÀN V4",
        V5 = "AncientMonkNPC",
        Accent = Color3.fromRGB(251, 191, 36),
        Archetype = "temple_crown",
        RoleVi = "ĐỀN THỜ LÕI • TEMPLE OF CORE",
        RoleEn = "TEMPLE OF THE CORE • V4",
        C1Vi = "[1] MỞ TẾ ĐÀN CÁNH TỘC V4",
        C1En = "[1] OPEN RACE V4 ALTAR",
        C1Cmd = "OpenScreen:NPCShop:DrVegaAndTempleV4",
        C1Icon = "Wing",
        C2Vi = "[2] KÍCH HOẠT TỘC V4 [G]",
        C2En = "[2] ACTIVATE RACE V4 [G]",
        C2Cmd = "OpenScreen:Fruits",
        C2Icon = "Bolt",
        C3Vi = "[3] 4 BƯỚC CẦN GẠT CỔ ĐẠI",
        C3En = "[3] 4 ANCIENT LEVER STEPS",
        LoreVi = "\"Thu thập Mảnh Gương & Bánh Răng Xanh trên Đảo Mirage, kéo Cần Gạt Cổ Đại vượt ải 60 giây dưới Trăng Tròn để khảm Bánh Răng V4 mở khóa Đôi Cánh 3D tối thượng!\"",
        LoreEn = "\"Gather the Mirror Fractal & Blue Gear, pull the Ancient Lever, and clear the 60s Trial to awaken 3D V4 Wings!\"",
    },
    collector = {
        Short = "SƯU TẬP",
        V5 = "LightArcher",
        Accent = Color3.fromRGB(245, 158, 11),
        Archetype = "collector_tophat",
        RoleVi = "BÀN GIAO DỊCH TRÁI 4X4",
        RoleEn = "4X4 FRUIT TRADING TABLE",
        C1Vi = "[1] BÀN GIAO DỊCH TRÁI 4X4",
        C1En = "[1] OPEN 4X4 FRUIT TRADE",
        C1Cmd = "OpenScreen:NPCShop:TradingTable",
        C1Icon = "Trade",
        C2Vi = "[2] KHO TRÁI VĨNH VIỄN [G]",
        C2En = "[2] STORED FRUITS [G]",
        C2Cmd = "OpenScreen:Fruits",
        C2Icon = "Fruit",
        C3Vi = "[3] LUẬT CHỐNG LỪA ĐẢO 40%",
        C3En = "[3] 40% ANTI-SCAM RULE",
        LoreVi = "\"Bàn Giao Dịch 4 ô tự động khóa nếu chênh lệch giá trị vượt quá 40%! Đặc biệt khi chơi đơn (Solo), ta sẵn sàng trao đổi trực tiếp 4 Khế Ước Trái Thần Thoại công bằng!\"",
        LoreEn = "\"Our 4x4 Anti-Scam Scale locks trades above 40% value gap, and offers fair Solo Mythic Collector Pacts!\"",
    },
    warden = {
        Short = "QUẢN ĐẤU",
        V5 = "GoldenKnight",
        Accent = Color3.fromRGB(251, 113, 133),
        Archetype = "valkyrie_crest",
        RoleVi = "ĐẤU TRƯỜNG 1V1 & THÁP 50F",
        RoleEn = "1V1 COLOSSEUM & 50F SPIRE",
        C1Vi = "[1] ĐẤU TRƯỜNG 1V1 & THÁP 50F",
        C1En = "[1] 1V1 ARENA & 50F SPIRE",
        C1Cmd = "OpenScreen:NPCShop:ColosseumAndSpire",
        C1Icon = "Trophy",
        C2Vi = "[2] BẢNG XẾP HẠNG BOUNTY [B]",
        C2En = "[2] TOP BOUNTY BOARD [B]",
        C2Cmd = "OpenScreen:SocialRewards",
        C2Icon = "Crown",
        C3Vi = "[3] PHẦN THƯỞNG TẦNG 50",
        C3En = "[3] FLOOR 50 REWARDS",
        LoreVi = "\"Luận võ 1v1 công bằng không mất Bounty, tự hồi 100% HP! Chinh phục đỉnh Tháp Vô Tận tầng 50 nhận Danh Hiệu [Bá Chủ Tháp Trời], Lõi Nguyên Thủy Veyr và 1,000 Shards!\"",
        LoreEn = "\"Duel fairly in 1v1 Colosseum with zero Bounty loss, or climb all 50 Sky Spire floors for Mythic Veyr Relics!\"",
    },
    kael = {
        Short = "THỢ RÈN KAEL",
        V5 = "GoldenKnight",
        Accent = Color3.fromRGB(251, 191, 36),
        Archetype = "smith_pauldrons",
        RoleVi = "LÒ RÈN THẦN KHÍ • SKY HUB",
        RoleEn = "CELESTIAL FORGE • SKY HUB",
        C1Vi = "[1] MỞ LÒ RÈN & NÂNG SAO",
        C1En = "[1] OPEN CELESTIAL FORGE",
        C1Cmd = "OpenScreen:Forge",
        C1Icon = "Forge",
        C2Vi = "[2] KHẮC PHÙ PHÉP CỔ NGỮ",
        C2En = "[2] ARCANE ENCHANTER",
        C2Cmd = "OpenScreen:NPCShop:EnchanterAndChronos",
        C2Icon = "CoreShards",
        C3Vi = "[3] BÍ QUYẾT CƯỜNG HÓA +5 SAO",
        C3En = "[3] 5-STAR FORGE TIPS",
        LoreVi = "\"Thu thập Mảnh Lõi Aether và nguyên liệu Boss để cường hóa Thần Khí lên 5 Sao Hoàng Kim, mở khóa chỉ số cộng thêm vượt giới hạn và hào quang rực sáng!\"",
        LoreEn = "\"Gather Boss materials and Core Shards to ascend your weapons and armor to 5 Golden Stars!\"",
    },
    lyra = {
        Short = "CHỈ HUY LYRA",
        V5 = "LightArcher",
        Accent = Color3.fromRGB(252, 211, 77),
        Archetype = "halo_crown",
        RoleVi = "LIÊN MINH SKYBORN • SKY HUB",
        RoleEn = "SKYBORN COMMAND • SKY HUB",
        C1Vi = "[1] NHẬN NHIỆM VỤ & CHỈ ĐƯỜNG [L]",
        C1En = "[1] QUEST BOARD & COMPASS [L]",
        C1Cmd = "OpenScreen:QuestJournal",
        C1Icon = "Quest",
        C2Vi = "[2] BẢN ĐỒ 20 ĐẢO BAY [M]",
        C2En = "[2] 20-ISLAND WORLD MAP [M]",
        C2Cmd = "OpenScreen:WorldMap",
        C2Icon = "Compass",
        C3Vi = "[3] HƯỚNG DẪN TÂN THỦ SKY 1-3",
        C3En = "[3] SKY 1-3 PROGRESSION GUIDE",
        LoreVi = "\"Hạt nhân Veil's End đang rạn nứt! Hãy bật [Tự Lặp Nhiệm Vụ] trong bảng Nhiệm Vụ [L] để cày cấp mượt tới Lv.2550, sưu tập 12 Trái Aether 3D và thức tỉnh Đôi Cánh Tộc V4!\"",
        LoreEn = "\"Enable Quick-Repeat Quests in [L] to level smoothly to Lv.2550, collect all 12 3D Fruits, and awaken V4 Wings!\"",
    },
}

local function classifySpeaker(speakerText)
    local low = string.lower(tostring(speakerText or "Lyra"))
    if low:find("mirage") or low:find("ảo ảnh") then
        return "mirage", SPEAKER_PRESETS.mirage
    elseif low:find("zioles") or low:find("gacha") then
        return "zioles", SPEAKER_PRESETS.zioles
    elseif low:find("sword") or low:find("kiếm") or low:find("blade") or low:find("ryu") then
        return "sword", SPEAKER_PRESETS.sword
    elseif low:find("gun") or low:find("súng") or low:find("xạ thủ") or low:find("marksman") then
        return "gun", SPEAKER_PRESETS.gun
    elseif low:find("temple") or low:find("cần gạt") or low:find("tế đàn") or low:find("v4") then
        return "temple", SPEAKER_PRESETS.temple
    elseif low:find("monk") or low:find("sư") or low:find("võ") or low:find("dojo") then
        return "monk", SPEAKER_PRESETS.monk
    elseif low:find("chronos") or low:find("hư không") or low:find("chợ đen") or low:find("void") then
        return "chronos", SPEAKER_PRESETS.chronos
    elseif low:find("enchant") or low:find("phù phép") or low:find("cổ ngữ") then
        return "enchant", SPEAKER_PRESETS.enchant
    elseif low:find("ship") or low:find("thuyền") or low:find("tàu") then
        return "shipwright", SPEAKER_PRESETS.shipwright
    elseif low:find("vega") or low:find("tộc") or low:find("microchip") or low:find("khoa học") then
        return "vega", SPEAKER_PRESETS.vega
    elseif low:find("collector") or low:find("sưu tập") or low:find("giao dịch") or low:find("trade") then
        return "collector", SPEAKER_PRESETS.collector
    elseif low:find("warden") or low:find("đấu trường") or low:find("tháp") or low:find("colosseum") or low:find("spire") then
        return "warden", SPEAKER_PRESETS.warden
    elseif low:find("kael") or low:find("forge") or low:find("rèn") then
        return "kael", SPEAKER_PRESETS.kael
    end
    return "lyra", SPEAKER_PRESETS.lyra
end

local function cloneLiveWorkspaceNPC(keyword)
    local lp = Players.LocalPlayer
    local ch = lp and lp.Character
    local hrp = ch and (ch.PrimaryPart or ch:FindFirstChild("HumanoidRootPart"))
    local playerPos = hrp and hrp.Position or nil

    local expWorld = workspace:FindFirstChild("SkybreakExpansionWorld")
    local folders = {
        expWorld and expWorld:FindFirstChild("VendorNPCs") or nil,
        expWorld and expWorld:FindFirstChild("WorldNPCs") or nil,
        workspace:FindFirstChild("ActiveNPCs"),
        workspace:FindFirstChild("NPCs"),
        workspace:FindFirstChild("HubNPCs"),
        workspace:FindFirstChild("Vendors"),
        workspace,
    }

    local bestExact = nil
    local bestNear = nil
    local bestNearDist = 48

    for _, folder in pairs(folders) do
        if typeof(folder) == "Instance" then
            for _, child in ipairs(folder:GetChildren()) do
                if child:IsA("Model") and child ~= ch then
                    local nameLow = string.lower(child.Name)
                    local isNPCLike = (folder.Name == "NPCs" or folder.Name == "HubNPCs" or folder.Name == "Vendors")
                        or child:GetAttribute("NPCId") ~= nil
                        or child:GetAttribute("VendorMode") ~= nil
                        or nameLow:find("lyra")
                        or nameLow:find("kael")
                        or nameLow:find("zioles")
                        or nameLow:find("mirage")
                        or nameLow:find("monk")
                        or nameLow:find("ship")
                        or nameLow:find("sword")
                        or nameLow:find("gun")
                        or nameLow:find("chronos")
                        or nameLow:find("enchant")
                        or nameLow:find("vega")
                        or nameLow:find("temple")
                        or nameLow:find("collector")
                        or nameLow:find("warden")
                        or nameLow:find("dealer")
                        or nameLow:find("merchant")
                    if isNPCLike then
                        if nameLow:find(keyword, 1, true) then
                            bestExact = child
                            break
                        elseif playerPos then
                            local pp = child.PrimaryPart or child:FindFirstChild("HumanoidRootPart") or child:FindFirstChildWhichIsA("BasePart")
                            if pp then
                                local d = (pp.Position - playerPos).Magnitude
                                if d < bestNearDist then
                                    bestNearDist = d
                                    bestNear = child
                                end
                            end
                        end
                    end
                end
            end
        end
        if bestExact then
            break
        end
    end

    local sourceModel = bestExact or bestNear
    if not sourceModel then
        return nil
    end

    local prevArch = sourceModel.Archivable
    sourceModel.Archivable = true
    local ok, cloned = pcall(function()
        return sourceModel:Clone()
    end)
    sourceModel.Archivable = prevArch

    if ok and cloned and cloned:IsA("Model") then
        for _, desc in ipairs(cloned:GetDescendants()) do
            if desc:IsA("BillboardGui") or desc:IsA("ProximityPrompt") or desc:IsA("Script") or desc:IsA("LocalScript") then
                desc:Destroy()
            elseif desc:IsA("BasePart") then
                desc.Anchored = true
                desc.CanCollide = false
                desc.CanQuery = false
                desc.CanTouch = false
            end
        end
        return cloned
    end
    return nil
end

-- Bespoke 12-Archetype Sculpted 3D NPC Bust matching Figma File 3 portraits
local function buildSculpted3DBust(accentColor, archetype)
    archetype = archetype or "halo_crown"
    local m = Instance.new("Model")
    m.Name = "CelestialNPCBust3D_" .. tostring(archetype)

    local torsoColor = Color3.fromRGB(32, 48, 82)
    if archetype == "mage_hood" or archetype == "void_horns" or archetype == "rune_hood" then
        torsoColor = Color3.fromRGB(88, 36, 148)
    elseif archetype == "monk_halo" or archetype == "temple_crown" then
        torsoColor = Color3.fromRGB(22, 118, 96)
    elseif archetype == "samurai_kabuto" or archetype == "smith_pauldrons" then
        torsoColor = Color3.fromRGB(146, 84, 24)
    elseif archetype == "valkyrie_crest" then
        torsoColor = Color3.fromRGB(136, 32, 58)
    elseif archetype == "captain_tricorn" or archetype == "scientist_visor" or archetype == "tactical_goggles" then
        torsoColor = Color3.fromRGB(22, 92, 148)
    end

    local function part(name, size, cf, col, mat, shape, className)
        local p = Instance.new(className or "Part")
        p.Name = name
        p.Size = size
        p.CFrame = cf
        p.Color = col
        p.Material = mat or Enum.Material.SmoothPlastic
        p.Anchored = true
        p.CanCollide = false
        if p:IsA("Part") and shape then
            p.Shape = shape
        end
        p.Parent = m
        return p
    end

    part("UpperTorso", Vector3.new(1.78, 1.82, 0.96), CFrame.new(0, 0, 0), torsoColor, Enum.Material.SmoothPlastic)
    part("ChestEmblem", Vector3.new(0.46, 0.46, 1.02), CFrame.new(0, 0.36, 0) * CFrame.Angles(0, 0, math.rad(45)), accentColor, Enum.Material.Neon)
    part("RuneCollar", Vector3.new(1.36, 0.24, 1.04), CFrame.new(0, 0.92, 0), accentColor:Lerp(Color3.new(1, 1, 1), 0.22), Enum.Material.Neon)

    for _, side in ipairs({ -1, 1 }) do
        local pCol = (archetype == "mage_hood" or archetype == "void_horns")
            and accentColor:Lerp(Color3.fromRGB(40, 20, 72), 0.35)
            or Theme.Colors.ACCENT_GOLD
        part(
            "Pauldron_" .. side,
            Vector3.new(0.76, 0.54, 1.08),
            CFrame.new(side * 1.10, 0.68, 0) * CFrame.Angles(0, 0, math.rad(-side * 18)),
            pCol,
            Enum.Material.Metal
        )
    end

    local skinCol = (archetype == "void_horns") and Color3.fromRGB(212, 198, 238) or Color3.fromRGB(244, 212, 184)
    local head = part("Head", Vector3.new(1.22, 1.26, 1.20), CFrame.new(0, 1.66, 0), skinCol, Enum.Material.SmoothPlastic, Enum.PartType.Ball)

    -- Expressive eyes matching Figma bust portraits
    for _, side in ipairs({ -1, 1 }) do
        part("Eye_" .. side, Vector3.new(0.13, 0.14, 0.10), CFrame.new(side * 0.22, 1.68, -0.55), Color3.fromRGB(24, 28, 42), Enum.Material.SmoothPlastic, Enum.PartType.Ball)
    end

    if archetype == "samurai_kabuto" then
        part("KabutoCone", Vector3.new(1.86, 0.56, 1.86), CFrame.new(0, 2.18, 0), Color3.fromRGB(214, 148, 38), Enum.Material.Metal, Enum.PartType.Cylinder)
        for _, side in ipairs({ -1, 1 }) do
            part("KabutoHorn_" .. side, Vector3.new(0.14, 0.66, 0.24), CFrame.new(side * 0.34, 2.42, -0.44) * CFrame.Angles(-0.15, 0, -side * 0.45), accentColor, Enum.Material.Neon, nil, "WedgePart")
        end
    elseif archetype == "tactical_goggles" or archetype == "scientist_visor" then
        part("VisorBand", Vector3.new(1.14, 0.28, 0.30), CFrame.new(0, 1.70, -0.52), accentColor, Enum.Material.Neon)
        part("TechHood", Vector3.new(1.34, 0.48, 1.30), CFrame.new(0, 2.14, 0.04), torsoColor:Lerp(Color3.new(0, 0, 0), 0.25), Enum.Material.Metal)
    elseif archetype == "mage_hood" or archetype == "rune_hood" then
        part("MysticHood", Vector3.new(1.46, 1.38, 1.34), CFrame.new(0, 1.78, 0.16), torsoColor:Lerp(accentColor, 0.22), Enum.Material.SmoothPlastic)
        part("ForeheadGem", Vector3.new(0.22, 0.22, 0.14), CFrame.new(0, 2.02, -0.54) * CFrame.Angles(0, 0, math.rad(45)), Color3.fromRGB(125, 232, 255), Enum.Material.Neon)
    elseif archetype == "void_horns" then
        part("VoidCowl", Vector3.new(1.42, 1.30, 1.30), CFrame.new(0, 1.76, 0.16), Color3.fromRGB(48, 22, 82), Enum.Material.SmoothPlastic)
        for _, side in ipairs({ -1, 1 }) do
            part("VoidHorn_" .. side, Vector3.new(0.18, 0.84, 0.26), CFrame.new(side * 0.48, 2.30, -0.10) * CFrame.Angles(-0.2, 0, -side * 0.38), accentColor, Enum.Material.Neon, nil, "WedgePart")
        end
    elseif archetype == "captain_tricorn" then
        part("TricornBrim", Vector3.new(1.76, 0.20, 1.56), CFrame.new(0, 2.14, 0), Color3.fromRGB(26, 48, 86), Enum.Material.SmoothPlastic)
        part("CaptainCrest", Vector3.new(0.26, 0.26, 0.14), CFrame.new(0, 2.24, -0.74) * CFrame.Angles(0, 0, math.rad(45)), Theme.Colors.ACCENT_GOLD_BRIGHT, Enum.Material.Neon)
    elseif archetype == "collector_tophat" then
        part("HatBrim", Vector3.new(0.14, 1.74, 1.74), CFrame.new(0, 2.12, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(76, 34, 114), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
        part("HatCrown", Vector3.new(0.76, 1.18, 1.18), CFrame.new(0, 2.50, 0) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(98, 44, 146), Enum.Material.SmoothPlastic, Enum.PartType.Cylinder)
        part("HatRibbon", Vector3.new(0.16, 1.22, 1.22), CFrame.new(0, 2.24, 0) * CFrame.Angles(0, 0, math.rad(90)), Theme.Colors.ACCENT_GOLD_BRIGHT, Enum.Material.Neon, Enum.PartType.Cylinder)
    elseif archetype == "valkyrie_crest" or archetype == "temple_crown" then
        for i = -2, 2 do
            part("CrownSpire_" .. i, Vector3.new(0.14, (i == 0 and 0.64 or 0.44), 0.18), CFrame.new(i * 0.24, 2.34, -0.32) * CFrame.Angles(-0.1, 0, -i * 0.22), accentColor, Enum.Material.Neon, nil, "WedgePart")
        end
    else
        part("HaloRing", Vector3.new(0.10, 1.68, 1.68), CFrame.new(0, 2.18, -0.10) * CFrame.Angles(0, math.rad(90), math.rad(18)), accentColor, Enum.Material.Neon, Enum.PartType.Cylinder)
        for _, side in ipairs({ -1, 1 }) do
            part("WingCrest_" .. side, Vector3.new(0.14, 0.52, 0.24), CFrame.new(side * 0.56, 2.04, -0.16) * CFrame.Angles(0, 0, -side * 0.48), Color3.new(1, 1, 1), Enum.Material.Neon, nil, "WedgePart")
        end
    end

    m.PrimaryPart = head
    return m
end

function Dialogue.CreateOverlay(parent)
    local colors = Theme.Colors
    local activeSpeakerSig = nil
    local breathConn = nil
    local activeWorldModel = nil
    local portraitTicket = 0
    local choiceHandlers = {}

    -- Top Panel of SKYBREAK_NPC_01_Dialogue_Zioles_Mirage.png:
    -- Wide Gold-Corner-Bracketed Obsidian Dialogue Card: AnchorPoint (0.5, 1), Position (0.5, 0, 1, -24), min(980px, 92%) x 214px
    local card = PremiumPanel.Create(parent, {
        name = "DialogueOverlay",
        variant = "gold",
        anchorPoint = Vector2.new(0.5, 1),
        position = UDim2.new(0.5, 0, 1, -24),
        size = UDim2.new(0.92, 0, 0, 214),
        transparency = 0.04,
        visible = false,
        zIndex = 30,
    })
    UIFactory.SizeConstraint(card, Vector2.new(580, 214), Vector2.new(980, 214))

    -- Left (14, 16, 136 x 178): Framed Live 3D NPC Bust Card
    local portraitFrame = UIFactory.Create("Frame", card, {
        Name = "NPCPortraitFrame",
        Position = UDim2.fromOffset(14, 16),
        Size = UDim2.fromOffset(136, 178),
        BackgroundColor3 = Color3.fromRGB(11, 16, 30),
        BorderSizePixel = 0,
        ClipsDescendants = false,
        ZIndex = 32,
    })
    UIFactory.Corner(portraitFrame, 12)
    local portraitStroke = UIFactory.Stroke(portraitFrame, colors.ACCENT_GOLD, 2.0, 0.06)
    UIFactory.Gradient(portraitFrame, Color3.fromRGB(28, 34, 66), Color3.fromRGB(9, 13, 24), 90)

    -- Soft radial aura disc behind the 3D bust (matching Figma circular backdrop)
    local auraOuter = UIFactory.Create("Frame", portraitFrame, {
        Name = "RadialAuraOuter",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.45, 0),
        Size = UDim2.fromOffset(104, 104),
        BackgroundColor3 = colors.ACCENT_GOLD,
        BackgroundTransparency = 0.84,
        BorderSizePixel = 0,
        ZIndex = 32,
    })
    UIFactory.PillCorner(auraOuter)
    local auraRingStroke = UIFactory.Stroke(auraOuter, colors.ACCENT_GOLD, 1.3, 0.42)

    local auraInner = UIFactory.Create("Frame", portraitFrame, {
        Name = "RadialAuraInner",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.45, 0),
        Size = UDim2.fromOffset(76, 76),
        BackgroundColor3 = colors.ACCENT_GOLD,
        BackgroundTransparency = 0.76,
        BorderSizePixel = 0,
        ZIndex = 32,
    })
    UIFactory.PillCorner(auraInner)

    local portraitViewport = UIFactory.Create("ViewportFrame", portraitFrame, {
        Name = "NPCPortraitViewport3D",
        Position = UDim2.fromOffset(4, 4),
        Size = UDim2.new(1, -8, 1, -22),
        BackgroundTransparency = 1,
        Ambient = Color3.fromRGB(192, 206, 236),
        LightColor = Color3.fromRGB(255, 246, 222),
        LightDirection = Vector3.new(-0.5, -0.65, -0.9),
        ZIndex = 33,
    })
    UIFactory.Corner(portraitViewport, 10)

    local portraitCam = Instance.new("Camera")
    portraitCam.Name = "PortraitCam"
    portraitCam.FieldOfView = 28
    portraitCam.Parent = portraitViewport
    portraitViewport.CurrentCamera = portraitCam

    -- Overlapping bottom dark pill: "• 3D LIVE - <SHORT_NAME>"
    local livePill = UIFactory.Create("Frame", portraitFrame, {
        Name = "Live3DPill",
        AnchorPoint = Vector2.new(0.5, 1),
        Position = UDim2.new(0.5, 0, 1, 5),
        Size = UDim2.new(1, -10, 0, 22),
        BackgroundColor3 = Color3.fromRGB(9, 13, 24),
        BorderSizePixel = 0,
        ZIndex = 35,
    })
    UIFactory.PillCorner(livePill)
    local livePillStroke = UIFactory.Stroke(livePill, colors.ACCENT_GOLD, 1.3, 0.16)

    local liveTag = UIFactory.Label(livePill, {
        Name = "Live3DTag",
        Text = "• 3D LIVE - ZIOLES",
        Position = UDim2.fromOffset(4, 0),
        Size = UDim2.new(1, -8, 1, 0),
        TextSize = 10,
        TextColor = colors.TEXT_PRIMARY,
        Bold = true,
        XAlign = Enum.TextXAlignment.Center,
        Wrapped = false,
        Truncate = Enum.TextTruncate.AtEnd,
        ZIndex = 36,
    })

    -- Right Top (166, 16): Bold Gold Uppercase NPC Speaker Title + Accent-Stroked Location/Role Pill right beside it
    local headerRow = UIFactory.Create("Frame", card, {
        Name = "SpeakerHeaderRow",
        Position = UDim2.fromOffset(166, 16),
        Size = UDim2.new(1, -182, 0, 26),
        BackgroundTransparency = 1,
        ZIndex = 32,
    })
    UIFactory.ListLayout(headerRow, Enum.FillDirection.Horizontal, 10, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    local speakerLabel = UIFactory.Create("TextLabel", headerRow, {
        Name = "NPCName",
        Text = "ZIOLES • ĐẠI THƯƠNG NHÂN TRÁI AETHER",
        Size = UDim2.fromOffset(0, 26),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Font = Theme.Fonts.Bold,
        TextSize = 16,
        TextColor3 = colors.ACCENT_GOLD_BRIGHT,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        LayoutOrder = 1,
        ZIndex = 33,
    })
    UIFactory.SizeConstraint(speakerLabel, Vector2.new(80, 24), Vector2.new(520, 26))

    local rolePill = UIFactory.Create("Frame", headerRow, {
        Name = "NPCRolePill",
        Size = UDim2.fromOffset(0, 24),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundColor3 = Color3.fromRGB(46, 22, 78),
        BackgroundTransparency = 0.12,
        BorderSizePixel = 0,
        LayoutOrder = 2,
        ZIndex = 33,
    })
    UIFactory.PillCorner(rolePill)
    UIFactory.Padding(rolePill, 0, 12, 0, 12)
    local rolePillStroke = UIFactory.Stroke(rolePill, colors.VOID_PURPLE, 1.3, 0.15)

    local roleLabel = UIFactory.Create("TextLabel", rolePill, {
        Name = "NPCRole",
        Text = "ĐIỆN THỜ GACHA • SKY HUB",
        Size = UDim2.fromOffset(0, 24),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Font = Theme.Fonts.Bold,
        TextSize = 11,
        TextColor3 = colors.TEXT_PRIMARY,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 34,
    })

    -- Right Middle (166, 50): Crisp dialogue quote text (TextSize = 14, TEXT_PRIMARY)
    local bodyLabel = UIFactory.Label(card, {
        Name = "DialogueText",
        Text = "",
        Position = UDim2.fromOffset(166, 50),
        Size = UDim2.new(1, -184, 0, 78),
        TextSize = 14,
        TextColor = colors.TEXT_PRIMARY,
        YAlign = Enum.TextYAlignment.Top,
        Wrapped = true,
        ZIndex = 32,
    })

    -- Right Bottom (166, 138, height 48): Horizontal Row of 4 Glossy Tactile Action Buttons
    local actionRow = UIFactory.Create("Frame", card, {
        Name = "ActionChoiceRow",
        Position = UDim2.fromOffset(166, 138),
        Size = UDim2.new(1, -182, 0, 48),
        BackgroundTransparency = 1,
        ZIndex = 33,
    })
    UIFactory.ListLayout(actionRow, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)

    local _, choice1Api = PremiumButton.Create(actionRow, {
        name = "Choice1GoldBtn",
        icon = "Star",
        label = "[1] MỞ ĐÀI TRIỆU HỒI GACHA",
        variant = "gold",
        size = UDim2.new(0.285, -6, 1, 0),
        textSize = 12,
        minTextSize = 9,
        layoutOrder = 1,
        zIndex = 34,
        onActivated = function()
            if choiceHandlers[1] then
                choiceHandlers[1]()
            end
        end,
    })

    local _, choice2Api = PremiumButton.Create(actionRow, {
        name = "Choice2PrimaryBtn",
        icon = "Bag",
        label = "[2] XEM KHO TRÁI & THỨC TỈNH [G]",
        variant = "primary",
        size = UDim2.new(0.275, -6, 1, 0),
        textSize = 12,
        minTextSize = 9,
        layoutOrder = 2,
        zIndex = 34,
        onActivated = function()
            if choiceHandlers[2] then
                choiceHandlers[2]()
            end
        end,
    })

    local _, choice3Api = PremiumButton.Create(actionRow, {
        name = "Choice3SecondaryBtn",
        label = "[3] TỶ LỆ RƠI & BẢO HIỂM PITY",
        variant = "secondary",
        size = UDim2.new(0.24, -6, 1, 0),
        textSize = 11,
        minTextSize = 9,
        layoutOrder = 3,
        zIndex = 34,
        onActivated = function()
            if choiceHandlers[3] then
                choiceHandlers[3]()
            end
        end,
    })

    local _, exitBtnApi = PremiumButton.Create(actionRow, {
        name = "Choice4ExitDangerBtn",
        label = "[ESC] TẠM BIỆT",
        variant = "danger",
        size = UDim2.new(0.20, -6, 1, 0),
        textSize = 12,
        minTextSize = 9,
        layoutOrder = 4,
        zIndex = 34,
        onActivated = function()
            if choiceHandlers[4] then
                choiceHandlers[4]()
            end
        end,
    })

    -- [1]-[4] Keyboard Choice Support while Dialogue is open
    local keyConn = UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not card.Visible or UserInputService:GetFocusedTextBox() then
            return
        end
        if input.KeyCode == Enum.KeyCode.One and choiceHandlers[1] then
            choiceHandlers[1]()
        elseif input.KeyCode == Enum.KeyCode.Two and choiceHandlers[2] then
            choiceHandlers[2]()
        elseif input.KeyCode == Enum.KeyCode.Three and choiceHandlers[3] then
            choiceHandlers[3]()
        elseif input.KeyCode == Enum.KeyCode.Four and choiceHandlers[4] then
            choiceHandlers[4]()
        end
    end)

    local function cleanupPortrait3D()
        portraitTicket += 1
        activeSpeakerSig = nil
        if breathConn then
            breathConn:Disconnect()
            breathConn = nil
        end
        if activeWorldModel and activeWorldModel.Parent then
            activeWorldModel:Destroy()
        end
        activeWorldModel = nil
    end

    local function applyAccentStyling(accentColor, shortTag)
        portraitStroke.Color = accentColor
        livePillStroke.Color = accentColor
        auraOuter.BackgroundColor3 = accentColor
        auraInner.BackgroundColor3 = accentColor
        auraRingStroke.Color = accentColor
        rolePill.BackgroundColor3 = accentColor:Lerp(colors.BG_900, 0.74)
        rolePillStroke.Color = accentColor
        roleLabel.TextColor3 = accentColor:Lerp(Color3.new(1, 1, 1), 0.45)
        liveTag.Text = "• 3D LIVE - " .. tostring(shortTag or "NPC")
        liveTag.TextColor3 = accentColor:Lerp(Color3.new(1, 1, 1), 0.42)
    end

    local function frameChestToHeadAndBreathe(npcModel, renderer, idleClip)
        if breathConn then
            breathConn:Disconnect()
            breathConn = nil
        end
        if activeWorldModel and activeWorldModel.Parent then
            activeWorldModel:Destroy()
        end

        local wm = Instance.new("WorldModel")
        wm.Name = "PortraitWorld"
        wm.Parent = portraitViewport
        activeWorldModel = wm

        ViewportOrbit.SanitizeModelForViewport(npcModel)
        npcModel.Parent = wm
        pcall(function()
            npcModel:PivotTo(CFrame.identity)
        end)

        local okBox, boxCF, boxSize = pcall(function()
            return npcModel:GetBoundingBox()
        end)
        if not okBox or not boxCF then
            boxCF = CFrame.identity
            boxSize = Vector3.new(2, 5, 2)
        end

        local headPart = npcModel:FindFirstChild("Head", true)
        local focusCenter
        local camDist
        local lookDir = Vector3.new(0, 0, -1)

        if headPart and headPart:IsA("BasePart") then
            focusCenter = headPart.Position - Vector3.new(0, math.clamp(boxSize.Y * 0.08, 0.18, 0.55), 0)
            lookDir = headPart.CFrame.LookVector
            if lookDir.Magnitude < 0.1 then
                lookDir = Vector3.new(0, 0, -1)
            end
            camDist = math.clamp(math.max(boxSize.X, boxSize.Y * 0.44) * 1.44, 2.4, 8.5)
        else
            focusCenter = boxCF.Position + Vector3.new(0, boxSize.Y * 0.24, 0)
            lookDir = boxCF.LookVector
            camDist = math.clamp(math.max(boxSize.X, boxSize.Y * 0.48) * 1.52, 2.6, 9.5)
        end

        local flatForward = Vector3.new(lookDir.X, 0, lookDir.Z)
        if flatForward.Magnitude < 0.05 then
            flatForward = Vector3.new(0, 0, 1)
        else
            flatForward = flatForward.Unit
        end

        local t0 = os.clock()
        breathConn = RunService.RenderStepped:Connect(function()
            if not card.Visible or not npcModel.Parent then
                return
            end
            local t = os.clock() - t0
            if renderer and idleClip and type(renderer.Pose) == "function" then
                pcall(renderer.Pose, npcModel, idleClip, t)
            end
            local breatheY = math.sin(t * 2.1) * 0.045
            local swayYaw = math.sin(t * 0.95) * 0.08
            local rotatedDir = CFrame.Angles(0, swayYaw, 0):VectorToWorldSpace(flatForward)
            local camPos = focusCenter + (rotatedDir * camDist) + Vector3.new(0, 0.14 + breatheY, 0)
            portraitCam.CFrame = CFrame.lookAt(camPos, focusCenter + Vector3.new(0, breatheY * 0.5, 0))
        end)
    end

    local function mountSpeaker3DPortrait(keyword, preset)
        applyAccentStyling(preset.Accent, preset.Short)
        if activeSpeakerSig == keyword and activeWorldModel ~= nil then
            return
        end
        cleanupPortrait3D()
        activeSpeakerSig = keyword
        applyAccentStyling(preset.Accent, preset.Short)
        local myTicket = portraitTicket

        local liveClone = cloneLiveWorkspaceNPC(keyword)
        if liveClone then
            frameChestToHeadAndBreathe(liveClone, nil, nil)
            return
        end

        local renderer = ViewportOrbit.GetRenderer()
        local v5Asset = preset.V5
        if renderer and type(renderer.Models) == "table" and renderer.Models[v5Asset] then
            local okC, cachedClone = pcall(function()
                return renderer.Models[v5Asset]:Clone()
            end)
            if okC and cachedClone then
                local idleClip = nil
                if type(renderer.Clips) == "function" then
                    local okCl, clips = pcall(renderer.Clips, v5Asset)
                    if okCl and type(clips) == "table" then
                        idleClip = clips.TalkIdle or clips.Idle
                    end
                end
                frameChestToHeadAndBreathe(cachedClone, renderer, idleClip)
                return
            end
        end

        frameChestToHeadAndBreathe(buildSculpted3DBust(preset.Accent, preset.Archetype), nil, nil)

        if renderer and type(renderer.CloneModel) == "function" then
            task.spawn(function()
                local okM, builtNPC = pcall(renderer.CloneModel, v5Asset, 0)
                if portraitTicket ~= myTicket or not card.Visible then
                    if okM and builtNPC then
                        builtNPC:Destroy()
                    end
                    return
                end
                if okM and builtNPC then
                    local idleClip = nil
                    if type(renderer.Clips) == "function" then
                        local okCl, clips = pcall(renderer.Clips, v5Asset)
                        if okCl and type(clips) == "table" then
                            idleClip = clips.TalkIdle or clips.Idle
                        end
                    end
                    frameChestToHeadAndBreathe(builtNPC, renderer, idleClip)
                end
            end)
        end
    end

    local api = {
        Instance = card,
    }

    function api:Update(dialogueState)
        dialogueState = dialogueState or {}
        card.Visible = dialogueState.visible == true
        if not card.Visible then
            cleanupPortrait3D()
            return
        end

        local isEn = (I18n.GetLanguage() == "en")
        local spk = tostring(dialogueState.speaker or "ZIOLES • ĐẠI THƯƠNG NHÂN TRÁI AETHER")
        local keyword, preset = classifySpeaker(spk)

        speakerLabel.Text = string.upper(spk)
        local rawRole = dialogueState.role
        if type(rawRole) == "string" and #rawRole > 0 then
            roleLabel.Text = string.upper(rawRole)
        else
            roleLabel.Text = isEn and preset.RoleEn or preset.RoleVi
        end

        local rawBody = tostring(dialogueState.text or "")
        if #rawBody > 0 and rawBody:sub(1, 1) ~= "\"" then
            bodyLabel.Text = "\"" .. rawBody .. "\""
        else
            bodyLabel.Text = rawBody
        end

        local primaryCmd = dialogueState.actionCommand or preset.C1Cmd
        local primaryLabel = dialogueState.actionLabel
        if type(primaryLabel) == "string" and #primaryLabel > 0 then
            if not primaryLabel:find("%[1%]") then
                primaryLabel = "[1] " .. primaryLabel
            end
        else
            primaryLabel = isEn and preset.C1En or preset.C1Vi
        end

        -- Keep Store.View.dialogue.actionCommand synchronized so [Space] in App.lua dispatches Choice 1
        if Store.View and Store.View.dialogue and not Store.View.dialogue.actionCommand then
            Store.View.dialogue.actionCommand = primaryCmd
        end

        local customChoices = type(dialogueState.choices) == "table" and dialogueState.choices or nil
        local c2Label = (customChoices and customChoices[2] and customChoices[2].label) or (isEn and preset.C2En or preset.C2Vi)
        local c2Cmd = (customChoices and customChoices[2] and customChoices[2].command) or preset.C2Cmd
        local c3Label = (customChoices and customChoices[3] and customChoices[3].label) or (isEn and preset.C3En or preset.C3Vi)
        local c3Cmd = customChoices and customChoices[3] and customChoices[3].command or nil
        local loreReply = isEn and preset.LoreEn or preset.LoreVi

        choice1Api:Update({ label = primaryLabel })
        choice2Api:Update({ label = c2Label })
        choice3Api:Update({ label = c3Label })
        exitBtnApi:Update({ label = I18n.Pick("[ESC] TẠM BIỆT", "[ESC] FAREWELL") })

        choiceHandlers[1] = function()
            QuestController.CloseDialogue()
            Dialogue.DispatchActionCommand(primaryCmd)
        end
        choiceHandlers[2] = function()
            QuestController.CloseDialogue()
            Dialogue.DispatchActionCommand(c2Cmd)
        end
        choiceHandlers[3] = function()
            if type(c3Cmd) == "string" and #c3Cmd > 0 then
                QuestController.CloseDialogue()
                Dialogue.DispatchActionCommand(c3Cmd)
            else
                bodyLabel.Text = loreReply
            end
        end
        choiceHandlers[4] = function()
            QuestController.CloseDialogue()
        end

        mountSpeaker3DPortrait(keyword, preset)
    end

    function api:Destroy()
        cleanupPortrait3D()
        if keyConn then
            keyConn:Disconnect()
            keyConn = nil
        end
        if card and card.Parent then
            card:Destroy()
        end
    end

    return card, api
end

return Dialogue
