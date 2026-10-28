-- SKYBREAK: Fragments of the Core — Canonical Asset Manifest (Section 04.3, 05, 13)
-- Location: ReplicatedStorage/SkybreakShared/AssetManifest.lua
-- Rule 10 (Section 15): Never fabricate rbxassetid://0000000000 placeholder IDs.
-- Real uploaded IDs are populated here when uploaded via Studio Asset Manager / MCP upload_image;
-- empty strings automatically trigger crisp runtime EditableImage / procedural celestial rendering.

local AssetManifest = {
	PlayIdle = "",
	PlayHover = "",
	PlayPressed = "",
	PanelNineSlice = "",
	LogoBase = "",
	LogoGlow = "",
	UltimateAtlas = "SYNTH_ULTIMATE_4X4",
	CorePulseAtlas = "SYNTH_COREPULSE_4X4",

	-- Source Blender renders on disk (for reference & asset pipeline verification)
	BlenderSources = {
		PlayIdle = "Assets/UI/mainmenu/SKY_UI_Play_Idle.png",
		PlayHover = "Assets/UI/mainmenu/SKY_UI_Play_Hover.png",
		PlayPressed = "Assets/UI/mainmenu/SKY_UI_Play_Pressed.png",
		PanelNineSlice = "Assets/UI/mainmenu/SKY_UI_Panel_9Slice.png",
		LogoBase = "Assets/UI/logo/SKY_Logo_Base.png",
		LogoGlow = "Assets/UI/logo/SKY_Logo_Glow.png",
		UltimateAtlas = "Assets/UI/fx/SKY_FX_UltimateCharge_4x4.png",
		CorePulseAtlas = "Assets/UI/fx/SKY_FX_CorePulse_4x4.png",
		WeaponDawnbringerModel = "Assets/Models/SKY_Weapon_Dawnbringer.fbx",
		CharacterGuardianModel = "Assets/Models/SKY_Character_Guardian.fbx",
	},

	Icons = {
		Dawnbringer = "",
		FrostBolt = "",
		Thunderfall = "",
		SkySlash = "",
		GuardianShield = "",
		JudgmentStrike = "",
		CelestialAegis = "",
		Stormfang = "",
		EternalFrost = "",
		SkyHelm = "",
		CelestialPlate = "",
		StarlightGauntlets = "",
		WindstriderGreaves = "",
		AureonCrestShield = "",
		SolarBand = "",
		CoreShardArtifact = "",
		SkyCrystal = "",
		CoreOfLight = "",
		VoidShard = "",
		DawnbringerBlueprint = "",
	},
}

function AssetManifest.IsValidRbxAsset(assetId)
	if type(assetId) ~= "string" or assetId == "" then
		return false
	end
	if string.match(assetId, "^rbxassetid://0+$") then
		return false
	end
	return string.match(assetId, "^rbxassetid://%d+$") ~= nil or string.match(assetId, "^rbxtemp://") ~= nil
end

return AssetManifest
