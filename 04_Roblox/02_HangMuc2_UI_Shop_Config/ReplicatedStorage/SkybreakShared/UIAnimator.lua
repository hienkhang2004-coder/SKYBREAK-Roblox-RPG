-- SKYBREAK: Fragments of the Core — Canonical UIAnimator (Section 06)
-- Location: ReplicatedStorage/SkybreakShared/UIAnimator.lua
-- Central Tween Engine with weak-table active tween cancellation and ReducedMotion support.

local TweenService = game:GetService("TweenService")

local UIAnimator = {}
UIAnimator.ReducedMotion = false

local activeTweens = setmetatable({}, { __mode = "k" })

function UIAnimator.Cancel(instance: Instance, key: string)
	local bucket = activeTweens[instance]
	if bucket and bucket[key] then
		pcall(function()
			bucket[key]:Cancel()
		end)
		bucket[key] = nil
	end
end

function UIAnimator.Tween(
	instance: Instance,
	goals: { [string]: any },
	duration: number?,
	style: Enum.EasingStyle?,
	direction: Enum.EasingDirection?
)
	if not instance then
		return nil
	end

	local key = table.concat((function()
		local keys = {}
		for prop in pairs(goals) do
			table.insert(keys, prop)
		end
		table.sort(keys)
		return keys
	end)(), "|")

	UIAnimator.Cancel(instance, key)

	if UIAnimator.ReducedMotion then
		for prop, value in pairs(goals) do
			pcall(function()
				(instance :: any)[prop] = value
			end)
		end
		return nil
	end

	local info = TweenInfo.new(
		duration or 0.16,
		style or Enum.EasingStyle.Quad,
		direction or Enum.EasingDirection.Out
	)

	local tween = TweenService:Create(instance, info, goals)
	activeTweens[instance] = activeTweens[instance] or {}
	activeTweens[instance][key] = tween
	tween:Play()
	return tween
end

function UIAnimator.Stop(instance: Instance)
	local bucket = activeTweens[instance]
	if not bucket then
		return
	end
	for key, tween in pairs(bucket) do
		pcall(function()
			tween:Cancel()
		end)
		bucket[key] = nil
	end
	activeTweens[instance] = nil
end

return UIAnimator
