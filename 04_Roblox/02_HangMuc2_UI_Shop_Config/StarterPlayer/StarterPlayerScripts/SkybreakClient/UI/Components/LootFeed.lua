--!strict
--[[
	LootFeed.lua (#95)
	Right-Side Stacked Loot Notification Feed (+Gold, +EXP, +Item, +Mastery, +Shards)
	Slides in smoothly on the middle-right edge and auto-fades without blocking headers or hotbars.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Theme = require(ReplicatedStorage:WaitForChild("SkybreakShared"):WaitForChild("Config"):WaitForChild("Theme"))
local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))

local LootFeed = {}

export type LootEntry = {
	Category: string?, -- "Gold" | "EXP" | "Shards" | "Item" | "Mastery" | "Gift"
	Title: string,
	Subtitle: string?,
	Color: Color3?,
	Duration: number?,
}

local Container: Frame? = nil
local ActiveCards: { Frame } = {}
local MAX_VISIBLE = 6

local CATEGORY_STYLE: { [string]: { Color: Color3, Icon: string, Tag: string } } = {
	Gold = { Color = Theme.Colors.ACCENT_GOLD_BRIGHT, Icon = "Gold", Tag = "GOLD" },
	EXP = { Color = Theme.Colors.ACCENT_SAPPHIRE, Icon = "Star", Tag = "EXP" },
	Shards = { Color = Theme.Colors.VOID_PURPLE, Icon = "CoreShards", Tag = "AETHER" },
	Item = { Color = Theme.Colors.ACCENT_GOLD, Icon = "Weapon", Tag = "LOOT" },
	Mastery = { Color = Theme.Colors.SUCCESS, Icon = "Check", Tag = "MASTERY" },
	Gift = { Color = Theme.Colors.VOID_PURPLE, Icon = "Gift", Tag = "GIFT" },
}

function LootFeed.Init(parentLayer: GuiObject)
	if Container and Container.Parent then
		return
	end
	local holder = UIFactory.Create("Frame", parentLayer, {
		Name = "LootFeedStack",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.48, 0),
		Size = UDim2.fromOffset(252, 286),
		BackgroundTransparency = 1,
		ZIndex = 120,
	})
	UIFactory.ListLayout(holder, Enum.FillDirection.Vertical, 6, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Center)
	Container = holder
end

function LootFeed.Push(entry: LootEntry)
	local host = Container
	if not host or not host.Parent then
		return
	end

	while #ActiveCards >= MAX_VISIBLE do
		local oldest = table.remove(ActiveCards, 1)
		if oldest and oldest.Parent then
			oldest:Destroy()
		end
	end

	local catKey = entry.Category or "Item"
	local catCfg = CATEGORY_STYLE[catKey] or CATEGORY_STYLE.Item
	local accent = entry.Color or catCfg.Color
	local rowH = (entry.Subtitle and entry.Subtitle ~= "") and 44 or 36

	local slotWrap = UIFactory.Create("Frame", host, {
		Name = "LootEntryWrap",
		Size = UDim2.new(1, 0, 0, rowH),
		BackgroundTransparency = 1,
		ZIndex = 120,
	})

	local card = UIFactory.Create("Frame", slotWrap, {
		Name = "LootCard",
		Position = UDim2.fromOffset(72, 0),
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Theme.Colors.BG_800,
		BackgroundTransparency = 0.12,
		BorderSizePixel = 0,
		ZIndex = 121,
	})
	UIFactory.Corner(card, Theme.Radius.Small)
	local stroke = UIFactory.Stroke(card, accent, 1.2, 0.25)

	local bar = UIFactory.Create("Frame", card, {
		Name = "AccentBar",
		Size = UDim2.new(0, 3, 1, -8),
		Position = UDim2.fromOffset(4, 4),
		BackgroundColor3 = accent,
		BorderSizePixel = 0,
		ZIndex = 122,
	})
	UIFactory.PillCorner(bar)

	local iconBox = UIFactory.Create("Frame", card, {
		Name = "IconWrap",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 12, 0.5, 0),
		Size = UDim2.fromOffset(22, 22),
		BackgroundColor3 = Theme.Colors.BG_900,
		BackgroundTransparency = 0.18,
		BorderSizePixel = 0,
		ZIndex = 122,
	})
	UIFactory.PillCorner(iconBox)
	UIFactory.Stroke(iconBox, accent, 1, 0.42)

	local icon = UIFactory.Icon(iconBox, catCfg.Icon, UDim2.fromScale(0.5, 0.5), 14, accent)
	icon.AnchorPoint = Vector2.new(0.5, 0.5)
	icon.ZIndex = 123

	local hasSub = (entry.Subtitle and entry.Subtitle ~= "")
	local title = UIFactory.Label(card, {
		Name = "Title",
		Text = entry.Title,
		TextSize = 13,
		TextColor = Theme.Colors.TEXT_PRIMARY,
		Bold = true,
		Position = UDim2.fromOffset(40, hasSub and 4 or 0),
		Size = UDim2.new(1, -88, 0, hasSub and 19 or rowH),
		Wrapped = false,
		Truncate = Enum.TextTruncate.AtEnd,
		ZIndex = 122,
	})

	local subLabel: TextLabel? = nil
	if hasSub then
		subLabel = UIFactory.Label(card, {
			Name = "Subtitle",
			Text = entry.Subtitle :: string,
			TextSize = 11,
			TextColor = Theme.Colors.TEXT_SECONDARY,
			Position = UDim2.fromOffset(40, 22),
			Size = UDim2.new(1, -88, 0, 16),
			Wrapped = false,
			Truncate = Enum.TextTruncate.AtEnd,
			ZIndex = 122,
		})
	end

	local tagLbl = UIFactory.Label(card, {
		Name = "Tag",
		Text = catCfg.Tag,
		TextSize = 10,
		TextColor = accent,
		Bold = true,
		XAlign = Enum.TextXAlignment.Right,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -8, 0.5, 0),
		Size = UDim2.fromOffset(44, 16),
		Wrapped = false,
		ZIndex = 122,
	})

	table.insert(ActiveCards, slotWrap)

	TweenService:Create(
		card,
		TweenInfo.new(0.24, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
		{ Position = UDim2.fromOffset(0, 0), BackgroundTransparency = 0.08 }
	):Play()

	local holdDuration = entry.Duration or 2.8
	task.delay(holdDuration, function()
		if not slotWrap.Parent then
			return
		end
		local fadeInfo = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		TweenService:Create(card, fadeInfo, { Position = UDim2.fromOffset(48, 0), BackgroundTransparency = 1 }):Play()
		TweenService:Create(stroke, fadeInfo, { Transparency = 1 }):Play()
		TweenService:Create(bar, fadeInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(iconBox, fadeInfo, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(title, fadeInfo, { TextTransparency = 1 }):Play()
		TweenService:Create(tagLbl, fadeInfo, { TextTransparency = 1 }):Play()
		if subLabel then
			TweenService:Create(subLabel, fadeInfo, { TextTransparency = 1 }):Play()
		end
		task.delay(0.3, function()
			local idx = table.find(ActiveCards, slotWrap)
			if idx then
				table.remove(ActiveCards, idx)
			end
			if slotWrap.Parent then
				slotWrap:Destroy()
			end
		end)
	end)
end

return LootFeed
