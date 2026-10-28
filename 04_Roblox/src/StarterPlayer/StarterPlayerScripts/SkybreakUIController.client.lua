-- SKYBREAK: Fragments of the Core — Canonical SkybreakUIController (Section 05 & Section 13)
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakUIController.client.lua
-- Wires the StarterGui.SkybreakGui Explorer hierarchy (MainMenu, CombatHUD, InventoryPanel,
-- SkillsPanel, WorldMapPanel, ForgePanel, DialoguePanel, RaidHUD, SettingsPanel) to UIAnimator,
-- PanelMotion, SpritePlayer, AssetManifest, and the primary SkybreakUI App router.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local UIAnimator = require(Shared:WaitForChild("UIAnimator"))
local PanelMotion = require(Shared:WaitForChild("PanelMotion"))
local SpritePlayer = require(Shared:WaitForChild("SpritePlayer"))
local AssetManifest = require(Shared:WaitForChild("AssetManifest"))
local MotionTokens = require(Shared:WaitForChild("MotionTokens"))

local skybreakGui = playerGui:WaitForChild("SkybreakGui", 10)
if not skybreakGui then
	return
end

local mainMenu = skybreakGui:FindFirstChild("MainMenu")
local combatHUD = skybreakGui:FindFirstChild("CombatHUD")
local settingsPanel = skybreakGui:FindFirstChild("SettingsPanel")

if mainMenu then
	local buttonColumn = mainMenu:FindFirstChild("ButtonColumn")
	local playButton = buttonColumn and buttonColumn:FindFirstChild("PlayButton")
	local settingsButton = buttonColumn and buttonColumn:FindFirstChild("SettingsButton")
	local corePulse = mainMenu:FindFirstChild("CorePulse")

	if corePulse and corePulse:IsA("ImageLabel") then
		SpritePlayer.Play(corePulse, AssetManifest.CorePulseAtlas, 4, 4, 256, 256, 12, 16)
	end

	if playButton and playButton:IsA("GuiButton") then
		local playScale = playButton:FindFirstChildOfClass("UIScale")
		local playStroke = playButton:FindFirstChildOfClass("UIStroke")

		playButton.MouseEnter:Connect(function()
			if playButton:IsA("ImageButton") and AssetManifest.IsValidRbxAsset(AssetManifest.PlayHover) then
				playButton.Image = AssetManifest.PlayHover
			end
			if playScale then
				UIAnimator.Tween(
					playScale,
					{ Scale = 1.04 },
					MotionTokens.hoverFast.duration,
					MotionTokens.hoverFast.style,
					MotionTokens.hoverFast.direction
				)
			end
			if playStroke then
				UIAnimator.Tween(playStroke, { Transparency = 0.05 }, 0.14)
			end
		end)

		playButton.MouseLeave:Connect(function()
			if playButton:IsA("ImageButton") and AssetManifest.IsValidRbxAsset(AssetManifest.PlayIdle) then
				playButton.Image = AssetManifest.PlayIdle
			end
			if playScale then
				UIAnimator.Tween(playScale, { Scale = 1.0 }, 0.14)
			end
			if playStroke then
				UIAnimator.Tween(playStroke, { Transparency = 0.55 }, 0.14)
			end
		end)

		playButton.MouseButton1Down:Connect(function()
			if playButton:IsA("ImageButton") and AssetManifest.IsValidRbxAsset(AssetManifest.PlayPressed) then
				playButton.Image = AssetManifest.PlayPressed
			end
			if playScale then
				UIAnimator.Tween(
					playScale,
					{ Scale = 0.96 },
					MotionTokens.press.duration,
					MotionTokens.press.style,
					MotionTokens.press.direction
				)
			end
		end)

		playButton.MouseButton1Up:Connect(function()
			if playScale then
				UIAnimator.Tween(
					playScale,
					{ Scale = 1.0 },
					MotionTokens.rebound.duration,
					MotionTokens.rebound.style,
					MotionTokens.rebound.direction
				)
			end
			PanelMotion.Close(mainMenu :: CanvasGroup, function()
				if combatHUD and combatHUD:IsA("GuiObject") then
					combatHUD.Visible = true
				end
			end)
		end)
	end

	if settingsButton and settingsButton:IsA("GuiButton") and settingsPanel and settingsPanel:IsA("CanvasGroup") then
		settingsButton.Activated:Connect(function()
			PanelMotion.Open(settingsPanel)
		end)
	end
end

if combatHUD then
	local hotbar = combatHUD:FindFirstChild("SkillHotbar")
	local ultSlot = hotbar and hotbar:FindFirstChild("UltimateSlot")
	local ultRing = ultSlot and ultSlot:FindFirstChild("UltimateRing")
	if ultRing and ultRing:IsA("ImageLabel") then
		SpritePlayer.Play(ultRing, AssetManifest.UltimateAtlas, 4, 4, 256, 256, 16, 16)
	end
end
