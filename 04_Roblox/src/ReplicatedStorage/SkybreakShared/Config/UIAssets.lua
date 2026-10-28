-- SKYBREAK: Fragments of the Core — UI Asset Manifest
-- Location: ReplicatedStorage/SkybreakShared/Config/UIAssets.lua
-- Rule: Never fabricate fake rbxassetid:// IDs. Un-uploaded assets stay "" and trigger clean procedural Roblox GUI fallbacks.

local UIAssets = {
    -- Core Brand & 9-Slice Frames (Fill with real rbxassetid:// after Creator Hub upload)
    Logo = "",                 -- ui_logo_skybreak (PNG transparent)
    PanelNineSlice = "",       -- ui_panel_9slice (PNG 9-slice frame)
    ButtonNineSlice = "",      -- ui_button_primary_9slice (PNG 9-slice button texture)
    WorldMapBackground = "",   -- ui_map_worlds (Clean map background without baked text)
    MainMenuBackground = "",   -- ui_mainmenu_bg (Sky Hub vista fallback when 3D scene not active)
    SoftGlow = "",             -- ui_fx_glow_soft (Subtle alpha radial glow)

    -- Optional Verified Project Atlas (only used when UseProjectAtlas is explicitly enabled)
    UseProjectAtlas = false,
    ProjectIconAtlas = "rbxassetid://100014627871168",
    ProjectRealmPreview = "rbxassetid://84846582893628",

    -- 9-Slice Center Rectangles (configured for 64x64 or 128x128 9-slice textures once uploaded)
    NineSliceRects = {
        Panel = Rect.new(16, 16, 48, 48),
        Button = Rect.new(12, 12, 52, 52),
    },

    -- Individual Icon Asset IDs (Empty string = procedural geometric/vector fallback in UIFactory)
    Icons = {
        Sword = "",
        Daggers = "",
        Staff = "",
        Shield = "",
        Bolt = "",
        Frost = "",
        Bag = "",
        Skill = "",
        Quest = "",
        Map = "",
        Forge = "",
        Raid = "",
        Settings = "",
        Close = "",
        Gold = "",
        CoreShard = "",
        VoidEssence = "",
        Anchor = "",
        Lock = "",
        Check = "",
        Star = "",
        Heart = "",
    },

    -- Rarity Border Frame Textures (Empty string = procedural UIStroke + UIGradient by RarityConfig)
    RarityBorders = {
        Common = "",
        Rare = "",
        Epic = "",
        Legendary = "",
        Mythic = "",
    },

    -- Class Portraits (Empty string = live ViewportFrame 3D clone or procedural crest fallback)
    ClassPortraits = {
        SkyGuardian = "",
        ThunderStriker = "",
        ArcaneMage = "",
    },

    -- Boss Portraits for World Map & Raid UI (Empty string = procedural boss emblem badge)
    BossPortraits = {
        AureonSentinel = "",
        CryonPrime = "",
        Noxar = "",
        Sylvaris = "",
        Ignivar = "",
        Nerith = "",
        Aion = "",
        Veyr = "",
    },
}

function UIAssets.IsValidAssetId(assetId)
    return type(assetId) == "string"
        and #assetId > 13
        and string.sub(assetId, 1, 13) == "rbxassetid://"
        and tonumber(string.sub(assetId, 14)) ~= nil
end

function UIAssets.GetIcon(iconName)
    local id = UIAssets.Icons[iconName]
    if UIAssets.IsValidAssetId(id) then
        return id
    end
    return nil
end

function UIAssets.GetPendingUploadList()
    local pending = {}
    local topKeys = { "Logo", "PanelNineSlice", "ButtonNineSlice", "WorldMapBackground", "MainMenuBackground", "SoftGlow" }
    for _, key in ipairs(topKeys) do
        if not UIAssets.IsValidAssetId(UIAssets[key]) then
            table.insert(pending, { Category = "CoreUI", Key = key, SuggestedFile = "ui_" .. string.lower(key) .. ".png" })
        end
    end
    for key, val in pairs(UIAssets.Icons) do
        if not UIAssets.IsValidAssetId(val) then
            table.insert(pending, { Category = "Icons", Key = key, SuggestedFile = "ui_icon_" .. string.lower(key) .. ".png" })
        end
    end
    for key, val in pairs(UIAssets.ClassPortraits) do
        if not UIAssets.IsValidAssetId(val) then
            table.insert(pending, { Category = "ClassPortraits", Key = key, SuggestedFile = "ui_class_" .. string.lower(key) .. "_portrait.png" })
        end
    end
    for key, val in pairs(UIAssets.BossPortraits) do
        if not UIAssets.IsValidAssetId(val) then
            table.insert(pending, { Category = "BossPortraits", Key = key, SuggestedFile = "ui_boss_" .. string.lower(key) .. "_portrait.png" })
        end
    end
    table.sort(pending, function(a, b)
        if a.Category ~= b.Category then
            return a.Category < b.Category
        end
        return a.Key < b.Key
    end)
    return pending
end

return UIAssets
