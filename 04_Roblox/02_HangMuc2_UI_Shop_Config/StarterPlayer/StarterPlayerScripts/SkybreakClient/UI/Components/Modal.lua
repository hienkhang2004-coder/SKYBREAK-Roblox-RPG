-- SKYBREAK: Fragments of the Core — Confirmation & Alert Modal Overlay
-- Location: StarterPlayer/StarterPlayerScripts/SkybreakClient/UI/Components/Modal.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("SkybreakShared")
local Theme = require(Shared:WaitForChild("Config"):WaitForChild("Theme"))

local UIFactory = require(script.Parent.Parent:WaitForChild("UIFactory"))
local Store = require(script.Parent.Parent:WaitForChild("Store"))
local I18n = require(script.Parent.Parent:WaitForChild("I18n"))
local PremiumButton = require(script.Parent:WaitForChild("PremiumButton"))

local Modal = {}

function Modal.Create(parent, props)
    props = props or {}
    local colors = Theme.Colors

    local overlay = UIFactory.Create("TextButton", parent, {
        Name = props.name or "ConfirmModalOverlay",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = colors.BG_900,
        BackgroundTransparency = Theme.Transparency.ModalBackdrop,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Visible = props.visible == true,
        ZIndex = props.zIndex or 40,
    })

    local dialog = UIFactory.Create("Frame", overlay, {
        Name = "ModalDialog",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = props.size or UDim2.fromOffset(440, 230),
        BackgroundColor3 = colors.BG_800,
        BackgroundTransparency = 0.03,
        BorderSizePixel = 0,
        ZIndex = overlay.ZIndex + 1,
    })
    UIFactory.Corner(dialog, Theme.Radius.Large)
    UIFactory.Stroke(dialog, colors.ACCENT_GOLD, 1.8, 0.12)
    UIFactory.Gradient(dialog, colors.BG_700, colors.BG_900, 90)

    local titleLabel = UIFactory.Label(dialog, {
        Name = "ModalTitle",
        Text = props.title or "CONFIRM ACTION",
        Position = UDim2.fromOffset(22, 18),
        Size = UDim2.new(1, -44, 0, 26),
        TextSize = 19,
        TextColor = colors.ACCENT_GOLD,
        Bold = true,
        ZIndex = dialog.ZIndex + 2,
    })

    UIFactory.Divider(dialog, UDim2.fromOffset(22, 50), UDim2.new(1, -44, 0, 1), true)

    local contentLabel = UIFactory.Label(dialog, {
        Name = "ModalContent",
        Text = props.content or "",
        Position = UDim2.fromOffset(22, 62),
        Size = UDim2.new(1, -44, 1, -132),
        TextSize = 15,
        TextColor = colors.TEXT_PRIMARY,
        YAlign = Enum.TextYAlignment.Top,
        ZIndex = dialog.ZIndex + 2,
    })

    local currentOnConfirm = props.onConfirm
    local currentOnCancel = props.onCancel

    local _, cancelApi = PremiumButton.Create(dialog, {
        name = "CancelButton",
        label = props.cancelLabel or "CANCEL",
        variant = "secondary",
        position = UDim2.new(0, 22, 1, -58),
        size = UDim2.fromOffset(186, 42),
        zIndex = dialog.ZIndex + 3,
        onActivated = function()
            local cb = currentOnCancel
            overlay.Visible = false
            Store.CloseModal()
            if type(cb) == "function" then
                cb()
            end
        end,
    })

    local _, confirmApi = PremiumButton.Create(dialog, {
        name = "ConfirmButton",
        label = props.confirmLabel or "CONFIRM",
        variant = props.variant or "primary",
        position = UDim2.new(1, -208, 1, -58),
        size = UDim2.fromOffset(186, 42),
        zIndex = dialog.ZIndex + 3,
        onActivated = function()
            local cb = currentOnConfirm
            overlay.Visible = false
            Store.CloseModal()
            if type(cb) == "function" then
                cb()
            end
        end,
    })

    local api = {
        Instance = overlay,
        Dialog = dialog,
    }

    function api:Update(state)
        state = state or {}
        overlay.Visible = state.visible == true
        if state.title then
            titleLabel.Text = state.title
        end
        if state.content then
            contentLabel.Text = state.content
        end
        confirmApi:Update({
            label = state.confirmLabel or I18n.Pick("XÁC NHẬN", "CONFIRM"),
            variant = state.variant or "primary",
        })
        cancelApi:Update({
            label = state.cancelLabel or I18n.Pick("HỦY", "CANCEL"),
        })
        currentOnConfirm = state.onConfirm
        currentOnCancel = state.onCancel
    end

    function api:Destroy()
        cancelApi:Destroy()
        confirmApi:Destroy()
        if overlay and overlay.Parent then
            overlay:Destroy()
        end
    end

    return overlay, api
end

Modal.create = Modal.Create

return Modal
