-- SKYBREAK: Fragments of the Core — Canonical PanelMotion (Section 08)
-- Location: ReplicatedStorage/SkybreakShared/PanelMotion.lua
-- Standardizes Open/Close transitions for CanvasGroup panels with UIScale + GroupTransparency.

local UIAnimator = require(script.Parent:WaitForChild("UIAnimator"))

local PanelMotion = {}

local function ensureScale(panel: GuiObject): UIScale
	local scale = panel:FindFirstChildOfClass("UIScale")
	if not scale then
		scale = Instance.new("UIScale")
		scale.Scale = 1
		scale.Parent = panel
	end
	return scale
end

function PanelMotion.Open(panel: CanvasGroup)
	if not panel then
		return
	end
	local scale = ensureScale(panel)
	panel.Visible = true
	if panel:IsA("CanvasGroup") then
		panel.GroupTransparency = 1
	end
	scale.Scale = 0.97

	if panel:IsA("CanvasGroup") then
		UIAnimator.Tween(panel, { GroupTransparency = 0 }, 0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	end
	UIAnimator.Tween(scale, { Scale = 1.0 }, 0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
end

function PanelMotion.Close(panel: CanvasGroup, onClosed: (() -> ())?)
	if not panel then
		if onClosed then
			onClosed()
		end
		return
	end
	local scale = ensureScale(panel)
	local fadeTween = nil
	if panel:IsA("CanvasGroup") then
		fadeTween = UIAnimator.Tween(panel, { GroupTransparency = 1 }, 0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	end
	UIAnimator.Tween(scale, { Scale = 0.985 }, 0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	if fadeTween then
		fadeTween.Completed:Once(function(playbackState)
			if playbackState == Enum.PlaybackState.Completed then
				panel.Visible = false
				if onClosed then
					onClosed()
				end
			end
		end)
	else
		panel.Visible = false
		if onClosed then
			onClosed()
		end
	end
end

return PanelMotion
