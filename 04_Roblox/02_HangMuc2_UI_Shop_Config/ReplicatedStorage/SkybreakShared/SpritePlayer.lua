-- SKYBREAK: Fragments of the Core — Canonical Sprite Sheet Atlas Player (Section 09)
-- Location: ReplicatedStorage/SkybreakShared/SpritePlayer.lua
-- Drives 4x4 (16-frame) sprite sheet animations via ImageRectOffset and ImageRectSize.
-- Supports both uploaded rbxassetid:// atlases and runtime EditableImage 4x4 atlases so effects
-- animate with zero blank/grey placeholders even in offline Studio sessions.

local AssetService = game:GetService("AssetService")
local RunService = game:GetService("RunService")

local UIAnimator = require(script.Parent:WaitForChild("UIAnimator"))
local AssetManifest = require(script.Parent:WaitForChild("AssetManifest"))

local SpritePlayer = {}
local activeLoops = setmetatable({}, { __mode = "k" })
local cachedEditableAtlases = {}

-- Generates a real 4x4 (256x256, 64x64 per frame) RGBA sprite sheet in memory using EditableImage
local function getOrCreateEditableAtlas(atlasKey: string)
	if cachedEditableAtlases[atlasKey] ~= nil then
		return cachedEditableAtlases[atlasKey]
	end

	local ok, editable = pcall(function()
		return AssetService:CreateEditableImage({ Size = Vector2.new(256, 256) })
	end)
	if not ok or not editable then
		cachedEditableAtlases[atlasKey] = false
		return nil
	end

	local isUlt = (atlasKey == "SYNTH_ULTIMATE_4X4" or string.find(tostring(atlasKey), "Ultimate") ~= nil)
	local r1, g1, b1 = isUlt and 215 or 58, isUlt and 185 or 150, isUlt and 121 or 232
	local r2, g2, b2 = 157, 225, 255

	local pixels = table.create(256 * 256 * 4, 0)
	local cellW, cellH = 64, 64

	for frameIdx = 0, 15 do
		local col = frameIdx % 4
		local row = math.floor(frameIdx / 4)
		local phase = (frameIdx / 16) * (math.pi * 2)
		local baseR = 21 + 3.0 * math.sin(phase)

		for y = 0, cellH - 1 do
			for x = 0, cellW - 1 do
				local dx = x - 31.5
				local dy = y - 31.5
				local dist = math.sqrt(dx * dx + dy * dy)
				local ang = math.atan2(dy, dx)

				local ringDelta = math.abs(dist - baseR)
				local alpha = 0
				local pr, pg, pb = r1, g1, b1

				if ringDelta < 4.2 then
					local wave = 0.55 + 0.45 * math.sin(ang * 4 - phase * 2)
					alpha = math.clamp((1 - ringDelta / 4.2) * wave, 0, 1)
				end

				-- 4 orbiting rune nodes
				for s = 0, 3 do
					local orbAng = phase * (isUlt and 1 or -1) + s * (math.pi / 2)
					local ox = math.cos(orbAng) * baseR
					local oy = math.sin(orbAng) * baseR
					local od = math.sqrt((dx - ox) ^ 2 + (dy - oy) ^ 2)
					if od < 4.8 then
						local oa = math.clamp(1 - od / 4.8, 0, 1)
						if oa > alpha then
							alpha = oa
							pr, pg, pb = r2, g2, b2
						end
					end
				end

				-- Inner core pulse for CorePulse atlas
				if not isUlt and dist < 11 then
					local ca = math.clamp((1 - dist / 11) * (0.45 + 0.35 * math.cos(phase)), 0, 0.85)
					if ca > alpha then
						alpha = ca
						pr, pg, pb = r2, g2, b2
					end
				end

				if alpha > 0.01 then
					local gx = col * cellW + x
					local gy = row * cellH + y
					local idx = (gy * 256 + gx) * 4
					pixels[idx + 1] = pr / 255
					pixels[idx + 2] = pg / 255
					pixels[idx + 3] = pb / 255
					pixels[idx + 4] = alpha
				end
			end
		end
	end

	pcall(function()
		if editable.WritePixelsBuffer then
			local buf = buffer.create(256 * 256 * 4)
			for i = 0, (256 * 256) - 1 do
				local base = i * 4
				buffer.writeu8(buf, base, math.clamp(math.floor((pixels[base + 1] or 0) * 255), 0, 255))
				buffer.writeu8(buf, base + 1, math.clamp(math.floor((pixels[base + 2] or 0) * 255), 0, 255))
				buffer.writeu8(buf, base + 2, math.clamp(math.floor((pixels[base + 3] or 0) * 255), 0, 255))
				buffer.writeu8(buf, base + 3, math.clamp(math.floor((pixels[base + 4] or 0) * 255), 0, 255))
			end
			editable:WritePixelsBuffer(Vector2.zero, Vector2.new(256, 256), buf)
		elseif editable.WritePixels then
			editable:WritePixels(Vector2.zero, Vector2.new(256, 256), pixels)
		end
	end)

	cachedEditableAtlases[atlasKey] = editable
	return editable
end

function SpritePlayer.Stop(label: ImageLabel)
	if not label then
		return
	end
	local conn = activeLoops[label]
	if conn then
		conn:Disconnect()
		activeLoops[label] = nil
	end
end

function SpritePlayer.StopAll()
	for label, conn in pairs(activeLoops) do
		if conn then
			conn:Disconnect()
		end
		activeLoops[label] = nil
	end
end

function SpritePlayer.Play(
	label: ImageLabel,
	assetId: string,
	columns: number,
	rows: number,
	frameW: number,
	frameH: number,
	fps: number,
	frameCount: number?
)
	if not label then
		return
	end
	SpritePlayer.Stop(label)

	local actualCols = math.max(1, math.floor(tonumber(columns) or 4))
	local actualRows = math.max(1, math.floor(tonumber(rows) or 4))
	local totalFrames = math.max(1, math.floor(tonumber(frameCount) or (actualCols * actualRows)))
	local actualFrameW = frameW
	local actualFrameH = frameH
	local useProceduralFallback = false

	if AssetManifest.IsValidRbxAsset(assetId) then
		label.Image = assetId
	else
		local editable = getOrCreateEditableAtlas(assetId or "SYNTH_COREPULSE_4X4")
		if editable and Content and Content.fromObject then
			local ok = pcall(function()
				label.ImageContent = Content.fromObject(editable)
			end)
			if ok then
				actualCols = 4
				totalFrames = 16
				actualFrameW = 64
				actualFrameH = 64
			else
				useProceduralFallback = true
			end
		else
			useProceduralFallback = true
		end
	end

	label.BackgroundTransparency = 1
	label.ImageRectSize = Vector2.new(actualFrameW, actualFrameH)
	label.ImageRectOffset = Vector2.new(0, 0)

	local fallbackRing = label:FindFirstChild("ProceduralAtlasRing")
	if useProceduralFallback then
		label.Image = ""
		if not fallbackRing then
			fallbackRing = Instance.new("Frame")
			fallbackRing.Name = "ProceduralAtlasRing"
			fallbackRing.AnchorPoint = Vector2.new(0.5, 0.5)
			fallbackRing.Position = UDim2.fromScale(0.5, 0.5)
			fallbackRing.Size = UDim2.fromScale(0.86, 0.86)
			fallbackRing.BackgroundTransparency = 1
			fallbackRing.Parent = label

			local corner = Instance.new("UICorner")
			corner.CornerRadius = UDim.new(1, 0)
			corner.Parent = fallbackRing

			local stroke = Instance.new("UIStroke")
			stroke.Thickness = 2.2
			stroke.Color = (string.find(tostring(assetId), "Ultimate") ~= nil) and Color3.fromHex("#D7B979") or Color3.fromHex("#3A96E8")
			stroke.Transparency = 0.25
			stroke.Parent = fallbackRing
		else
			fallbackRing.Visible = true
		end
	elseif fallbackRing then
		fallbackRing.Visible = false
	end

	if UIAnimator.ReducedMotion then
		return
	end

	local elapsed = 0
	local currentFrame = 0
	local safeFps = math.max(1, tonumber(fps) or 16)

	activeLoops[label] = RunService.RenderStepped:Connect(function(dt)
		if not label.Parent or not label.Visible or UIAnimator.ReducedMotion then
			SpritePlayer.Stop(label)
			return
		end

		elapsed += dt
		local nextFrame = math.floor(elapsed * safeFps) % totalFrames
		if nextFrame ~= currentFrame then
			currentFrame = nextFrame
			local col = currentFrame % actualCols
			local row = math.floor(currentFrame / actualCols)
			label.ImageRectOffset = Vector2.new(col * actualFrameW, row * actualFrameH)

			if useProceduralFallback and fallbackRing then
				local phase = (currentFrame / totalFrames) * (math.pi * 2)
				local pulse = 0.84 + 0.08 * math.sin(phase)
				fallbackRing.Size = UDim2.fromScale(pulse, pulse)
				fallbackRing.Rotation = (currentFrame / totalFrames) * 360
			end
		end
	end)
end

return SpritePlayer
