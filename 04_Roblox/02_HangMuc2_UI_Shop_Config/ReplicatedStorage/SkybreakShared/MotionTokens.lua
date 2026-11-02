-- SKYBREAK: Fragments of the Core — Canonical Motion Tokens (Section 06)
-- Location: ReplicatedStorage/SkybreakShared/MotionTokens.lua

local MotionTokens = {
	hoverFast = {
		duration = 0.14,
		style = Enum.EasingStyle.Quad,
		direction = Enum.EasingDirection.Out,
	},
	press = {
		duration = 0.08,
		style = Enum.EasingStyle.Quad,
		direction = Enum.EasingDirection.Out,
	},
	rebound = {
		duration = 0.16,
		style = Enum.EasingStyle.Back,
		direction = Enum.EasingDirection.Out,
	},
	panelIn = {
		duration = 0.28,
		style = Enum.EasingStyle.Quart,
		direction = Enum.EasingDirection.Out,
	},
	panelOut = {
		duration = 0.20,
		style = Enum.EasingStyle.Quad,
		direction = Enum.EasingDirection.In,
	},
	tabSwitch = {
		duration = 0.20,
		style = Enum.EasingStyle.Quad,
		direction = Enum.EasingDirection.Out,
	},
	barUpdate = {
		duration = 0.25,
		style = Enum.EasingStyle.Quad,
		direction = Enum.EasingDirection.Out,
	},
	questComplete = {
		duration = 0.50,
		style = Enum.EasingStyle.Back,
		direction = Enum.EasingDirection.Out,
	},
	bossWarning = {
		duration = 0.20,
		style = Enum.EasingStyle.Quad,
		direction = Enum.EasingDirection.Out,
	},
	ambientLoop = {
		duration = 2.40,
		style = Enum.EasingStyle.Sine,
		direction = Enum.EasingDirection.InOut,
	},
}

return MotionTokens
