-- SKYBREAK: Fragments of the Core — Contextual NPC Dialogue Overlay (Phase 4)
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Screens/Dialogue.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Store = require(script.Parent.Parent:WaitForChild("Store"))
local ScreenRouter = require(script.Parent.Parent:WaitForChild("ScreenRouter"))
local PremiumPanel = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumPanel"))
local PremiumButton = require(script.Parent.Parent:WaitForChild("Components"):WaitForChild("PremiumButton"))
local QuestController = require(script.Parent.Parent:WaitForChild("Controllers"):WaitForChild("QuestController"))

local Dialogue = {}

function Dialogue.CreateOverlay(parent)
    local colors = Theme.Colors
    local currentActionCommand = nil

    local card = PremiumPanel.Create(parent, {
        name = "DialogueOverlay",
        variant = "gold",
        anchorPoint = Vector2.new(0.5, 1),
        position = UDim2.new(0.5, 0, 1, -32),
        size = UDim2.fromOffset(740, 210),
        visible = false,
        zIndex = 30,
    })

    local portraitBox = UIFactory.Create("Frame", card, {
        Name = "NPCPortrait",
        Position = UDim2.fromOffset(18, 18),
        Size = UDim2.fromOffset(88, 88),
        BackgroundColor3 = colors.BG_900,
        BorderSizePixel = 0,
        ZIndex = 32,
    })
    UIFactory.Corner(portraitBox, Theme.Radius.Medium)
    UIFactory.Stroke(portraitBox, colors.ACCENT_GOLD, 1.6, 0.15)
    UIFactory.Icon(portraitBox, "Core", UDim2.new(0.5, -24, 0.5, -24), 48, colors.ACCENT_GOLD)

    local speakerLabel = UIFactory.Label(card, {
        Name = "NPCName",
        Text = "LYRA • SKY HUB",
        Position = UDim2.fromOffset(122, 16),
        Size = UDim2.new(1, -140, 0, 24),
        TextSize = 18,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
        ZIndex = 32,
    })

    local roleLabel = UIFactory.Label(card, {
        Name = "NPCRole",
        Text = "Lorekeeper of the Core",
        Position = UDim2.fromOffset(122, 38),
        Size = UDim2.new(1, -140, 0, 18),
        TextSize = 12,
        TextColor = colors.ACCENT_SAPPHIRE,
        Bold = true,
        ZIndex = 32,
    })

    local bodyLabel = UIFactory.Label(card, {
        Name = "DialogueText",
        Text = "",
        Position = UDim2.fromOffset(122, 64),
        Size = UDim2.new(1, -144, 0, 76),
        TextSize = 15,
        TextColor = colors.TEXT_PRIMARY,
        YAlign = Enum.TextYAlignment.Top,
        Wrapped = true,
        ZIndex = 32,
    })

    local _, continueBtnApi = PremiumButton.Create(card, {
        name = "ContinueButton",
        label = "TIẾP TỤC / MỞ BẢNG [SPACE]",
        variant = "gold",
        position = UDim2.new(1, -268, 1, -54),
        size = UDim2.fromOffset(250, 40),
        textSize = 12,
        zIndex = 33,
        onActivated = function()
            local cmd = currentActionCommand
            QuestController.CloseDialogue()
            if type(cmd) == "string" and cmd:sub(1, 11) == "OpenScreen:" then
                local targetScreen = cmd:sub(12)
                ScreenRouter.Navigate(targetScreen)
            end
        end,
    })

    PremiumButton.Create(card, {
        name = "SkipButton",
        label = "ĐÓNG [ESC]",
        variant = "secondary",
        position = UDim2.new(1, -392, 1, -54),
        size = UDim2.fromOffset(114, 40),
        textSize = 12,
        zIndex = 33,
        onActivated = function()
            QuestController.CloseDialogue()
        end,
    })

    local api = {
        Instance = card,
    }

    function api:Update(dialogueState)
        dialogueState = dialogueState or {}
        card.Visible = dialogueState.visible == true
        if not card.Visible then
            return
        end
        speakerLabel.Text = dialogueState.speaker or "LYRA • SKY HUB"
        roleLabel.Text = dialogueState.role or "Celestial Archive"
        bodyLabel.Text = dialogueState.text or ""
        currentActionCommand = dialogueState.actionCommand
        if continueBtnApi then
            continueBtnApi:Update({
                label = dialogueState.actionLabel or "TIẾP TỤC / ĐÓNG [SPACE]",
            })
        end
    end

    return card, api
end

return Dialogue
