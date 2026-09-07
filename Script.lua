-- Nyx Speed Menu v2 | Mobile + PC Support
-- Touch-friendly UI, joystick-aware movement, TP speedhack, humanoid bypass

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- // Detect device
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

-- // Control Module (works for both PC WASD and mobile joystick)
local ControlModule = require(LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("ControlModule"))

-- // State
local Settings = {
    Speed = 16,
    SpeedEnabled = false,
    AntiCheatBypass = false,
    Smoothness = 0.35,
}

local Character, HumanoidRootPart, Humanoid

-- // Character handling
local function GetCharacter()
    Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    HumanoidRootPart = Character:WaitForChild("HumanoidRootPart")
    Humanoid = Character:WaitForChild("Humanoid")
end

GetCharacter()
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    GetCharacter()
    if Settings.AntiCheatBypass then
        task.wait(1)
        RemoveHumanoid()
    end
end)

-- // AntiCheat Bypass
function RemoveHumanoid()
    if not Character then return end
    local hum = Character:FindFirstChild("Humanoid")
    if hum then
        local camSubject = Camera.CameraSubject
        
        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
        hum:ChangeState(Enum.HumanoidStateType.Physics)
        
        task.delay(0.1, function()
            if hum and hum.Parent then
                Camera.CameraSubject = Character:FindFirstChild("HumanoidRootPart") or camSubject
                
                local animate = Character:FindFirstChild("Animate")
                if animate then animate:Destroy() end
                
                hum:Destroy()
            end
        end)
    end
    
    task.wait(0.15)
    if HumanoidRootPart then
        HumanoidRootPart.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5, 100, 1)
    end
end

function RestoreHumanoid()
    if LocalPlayer.Character then
        LocalPlayer.Character:BreakJoints()
    end
end

-- // Get move direction — universal (joystick on mobile, WASD on PC)
local function GetMoveDirection()
    local moveVec = ControlModule:GetMoveVector()
    -- moveVec is camera-relative already on mobile, but on PC it might need transform
    if not isMobile then
        -- PC: convert WASD input to camera space
        local camCF = Camera.CFrame
        local worldDir = camCF:VectorToWorldSpace(Vector3.new(moveVec.X, 0, -moveVec.Z))
        return Vector3.new(worldDir.X, 0, worldDir.Z)
    else
        -- Mobile: moveVec is already in the right space
        local camCF = Camera.CFrame
        local worldDir = camCF:VectorToWorldSpace(Vector3.new(moveVec.X, 0, moveVec.Z))
        return Vector3.new(worldDir.X, 0, worldDir.Z)
    end
end

-- // Smooth TP Speedhack
RunService.Heartbeat:Connect(function(deltaTime)
    if not Settings.SpeedEnabled then return end
    if not Character or not HumanoidRootPart or not HumanoidRootPart.Parent then return end
    
    local moveDirection = GetMoveDirection()
    
    if moveDirection.Magnitude > 0.1 then
        moveDirection = moveDirection.Unit
        
        local stepSize = (Settings.Speed / 16) * Settings.Smoothness
        local steps = math.clamp(math.ceil(stepSize / 0.5), 1, 20)
        
        for i = 1, steps do
            local step = moveDirection * (stepSize / steps)
            HumanoidRootPart.CFrame = HumanoidRootPart.CFrame + step
        end
        
        if HumanoidRootPart.AssemblyLinearVelocity then
            HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        end
    end
end)

-- // UI Sizing (bigger on mobile)
local SIZES = isMobile and {
    frameW = 340, frameH = 320,
    toggleH = 44, sliderH = 50,
    btnSize = 36, textSize = 15,
    labelSize = 14, valueSize = 14,
    corner = 12, pad = 10
} or {
    frameW = 320, frameH = 280,
    toggleH = 34, sliderH = 42,
    btnSize = 28, textSize = 14,
    labelSize = 12, valueSize = 12,
    corner = 10, pad = 8
}

-- // ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NyxSpeedMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Parent logic (CoreGui for executors, PlayerGui fallback)
local success = pcall(function()
    ScreenGui.Parent = game:GetService("CoreGui")
end)
if not success then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

-- // Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, SIZES.frameW, 0, SIZES.frameH)
MainFrame.Position = UDim2.new(0.5, -SIZES.frameW/2, 0.5, -SIZES.frameH/2)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, SIZES.corner)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(120, 80, 200)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, isMobile and 42 or 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 20, 40)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, SIZES.corner)
TitleCorner.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -80, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡ NYX SPEED" .. (isMobile and " 📱" or "")
Title.TextColor3 = Color3.fromRGB(180, 140, 255)
Title.TextSize = SIZES.textSize + 2
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, SIZES.btnSize, 0, SIZES.btnSize)
CloseBtn.Position = UDim2.new(1, -(SIZES.btnSize + 6), 0, (isMobile and 42 or 36)/2 - SIZES.btnSize/2)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = SIZES.textSize
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

-- Minimize Button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, SIZES.btnSize, 0, SIZES.btnSize)
MinBtn.Position = UDim2.new(1, -(SIZES.btnSize * 2 + 12), 0, (isMobile and 42 or 36)/2 - SIZES.btnSize/2)
MinBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = SIZES.textSize
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Parent = TitleBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinBtn

-- // Scrollable Content (important for mobile — less screen space)
local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -16, 1, -(isMobile and 52 or 46))
Content.Position = UDim2.new(0, 8, 0, isMobile and 48 or 42)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = isMobile and 6 or 4
Content.ScrollBarImageColor3 = Color3.fromRGB(120, 80, 200)
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, SIZES.pad)
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = Content

local UIPadding = Instance.new("UIPadding")
UIPadding.PaddingRight = UDim.new(0, 6)
UIPadding.Parent = Content

-- // Toggle Builder
local function CreateToggle(name, order, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, 0, 0, SIZES.toggleH)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(30, 28, 45)
    toggleFrame.BorderSizePixel = 0
    toggleFrame.LayoutOrder = order
    toggleFrame.Parent = Content
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = toggleFrame
    
    -- make whole row tappable (better for mobile)
    local tapBtn = Instance.new("TextButton")
    tapBtn.Size = UDim2.new(1, 0, 1, 0)
    tapBtn.BackgroundTransparency = 1
    tapBtn.Text = ""
    tapBtn.Parent = toggleFrame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(220, 220, 240)
    label.TextSize = SIZES.labelSize
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = tapBtn
    
    local toggleBtn = Instance.new("Frame")
    toggleBtn.Size = UDim2.new(0, isMobile and 52 or 46, 0, isMobile and 28 or 22)
    toggleBtn.Position = UDim2.new(1, -(isMobile and 60 or 54), 0.5, isMobile and -14 or -11)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    toggleBtn.Parent = toggleFrame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleBtn
    
    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, isMobile and 22 or 16, 0, isMobile and 22 or 16)
    toggleCircle.Position = UDim2.new(0, 3, 0.5, isMobile and -11 or -8)
    toggleCircle.BackgroundColor3 = Color3.fromRGB(150, 150, 170)
    toggleCircle.Parent = toggleBtn
    
    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = toggleCircle
    
    local isOn = false
    local function update()
        if isOn then
            TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(120, 80, 200)}):Play()
            TweenService:Create(toggleCircle, TweenInfo.new(0.2), {
                Position = UDim2.new(1, -(isMobile and 25 or 19), 0.5, isMobile and -11 or -8),
                BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            }):Play()
        else
            TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 80)}):Play()
            TweenService:Create(toggleCircle, TweenInfo.new(0.2), {
                Position = UDim2.new(0, 3, 0.5, isMobile and -11 or -8),
                BackgroundColor3 = Color3.fromRGB(150, 150, 170)
            }):Play()
        end
    end
    
    tapBtn.MouseButton1Click:Connect(function()
        isOn = not isOn
        update()
        callback(isOn)
    end)
    
    return toggleFrame
end

-- // Slider Builder
local function CreateSlider(name, order, minValue, maxValue, defaultValue, callback)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, 0, 0, SIZES.sliderH)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(30, 28, 45)
    sliderFrame.BorderSizePixel = 0
    sliderFrame.LayoutOrder = order
    sliderFrame.Parent = Content
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = sliderFrame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 0, 20)
    label.Position = UDim2.new(0, 10, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(220, 220, 240)
    label.TextSize = SIZES.labelSize
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = sliderFrame
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 60, 0, 20)
    valueLabel.Position = UDim2.new(1, -66, 0, 4)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(defaultValue)
    valueLabel.TextColor3 = Color3.fromRGB(180, 140, 255)
    valueLabel.TextSize = SIZES.valueSize
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = sliderFrame
    
    local sliderBack = Instance.new("Frame")
    sliderBack.Size = UDim2.new(1, -20, 0, isMobile and 10 or 6)
    sliderBack.Position = UDim2.new(0, 10, 0, isMobile and 32 or 28)
    sliderBack.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    sliderBack.BorderSizePixel = 0
    sliderBack.Parent = sliderFrame
    
    local backCorner = Instance.new("UICorner")
    backCorner.CornerRadius = UDim.new(1, 0)
    backCorner.Parent = sliderBack
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new((defaultValue - minValue) / (maxValue - minValue), 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBack
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = sliderFill
    
    -- bigger touch knob for mobile
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, isMobile and 22 or 14, 0, isMobile and 22 or 14)
    knob.Position = UDim2.new((defaultValue - minValue) / (maxValue - minValue), isMobile and -11 or -7, 0.5, isMobile and -11 or -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.ZIndex = 2
    knob.Parent = sliderBack
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob
    
    local dragging = false
    local function updateSlider(inputPos)
        local relPos = math.clamp((inputPos - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X, 0, 1)
        sliderFill.Size = UDim2.new(relPos, 0, 1, 0)
        knob.Position = UDim2.new(relPos, isMobile and -11 or -7, 0.5, isMobile and -11 or -7)
        local value = math.floor(minValue + (maxValue - minValue) * relPos)
        valueLabel.Text = tostring(value)
        callback(value)
    end
    
    sliderBack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input.Position.X)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateSlider(input.Position.X)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    return sliderFrame
end

-- // Build UI
CreateSlider("⚡ Speed", 1, 16, 1000, 16, function(value)
    Settings.Speed = value
end)

CreateToggle("Enable Speed", 2, function(state)
    Settings.SpeedEnabled = state
end)

CreateToggle("Anticheat Bypass", 3, function(state)
    Settings.AntiCheatBypass = state
    if state then
        RemoveHumanoid()
    else
        RestoreHumanoid()
    end
end)

CreateSlider("TP Smoothness", 4, 0.1, 2, 0.35, function(value)
    Settings.Smoothness = value
end)

-- Info label
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, 0, 0, 24)
infoLabel.BackgroundTransparency = 1
infoLabel.LayoutOrder = 5
infoLabel.Text = isMobile and "📱 touch mode active" or "⌨️ PC mode — Insert hides menu"
infoLabel.TextColor3 = Color3.fromRGB(100, 100, 130)
infoLabel.TextSize = isMobile and 12 or 11
infoLabel.Font = Enum.Font.Gotham
infoLabel.Parent = Content

-- // Drag — works for both mouse and touch
local dragging = false
local dragStart, startPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- // Close / Minimize
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    Settings.SpeedEnabled = false
end)

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Content.Visible = not minimized
    MainFrame.Size = minimized 
        and UDim2.new(0, SIZES.frameW, 0, isMobile and 42 or 36) 
        or UDim2.new(0, SIZES.frameW, 0, SIZES.frameH)
end)

-- // Toggle visibility
if not isMobile then
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.Insert then
            ScreenGui.Enabled = not ScreenGui.Enabled
        end
    end)
end
