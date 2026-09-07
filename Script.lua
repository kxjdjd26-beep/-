-- Nyx Speed Menu | Mobile Edition
-- Touch-optimized TP-based speedhack + humanoid removal anticheat bypass
-- Adapted for phone/tablet Roblox executors

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCameraх

-- // State
local Settings = {
    Speed = 16,
    SpeedEnabled = false,
    AntiCheatBypass = false,
    Smoothness = 0.35,
    MobileMoveEnabled = false,
    MobileMoveVector = Vector3.zero,
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

-- // Movement input source (keyboard OR mobile joystick)
local function GetMoveDirection()
    if Settings.MobileMoveEnabled and Settings.MobileMoveVector.Magnitude > 0 then
        return Settings.MobileMoveVector
    end
    
    local moveDirection = Vector3.zero
    
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        moveDirection = moveDirection + Camera.CFrame.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        moveDirection = moveDirection - Camera.CFrame.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        moveDirection = moveDirection - Camera.CFrame.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        moveDirection = moveDirection + Camera.CFrame.RightVector
    end
    
    return moveDirection
end

-- // Smooth TP Speedhack
RunService.Heartbeat:Connect(function(deltaTime)
    if not Settings.SpeedEnabled then return end
    if not Character or not HumanoidRootPart or not HumanoidRootPart.Parent then return end
    
    local moveDirection = GetMoveDirection()
    
    moveDirection = Vector3.new(moveDirection.X, 0, moveDirection.Z)
    
    if moveDirection.Magnitude > 0 then
        moveDirection = moveDirection.Unit
        
        local stepSize = (Settings.Speed / 16) * Settings.Smoothness
        local steps = math.ceil(stepSize / 0.5)
        
        for i = 1, steps do
            local step = moveDirection * (stepSize / steps)
            HumanoidRootPart.CFrame = HumanoidRootPart.CFrame + step
            task.wait()
        end
        
        if HumanoidRootPart.AssemblyLinearVelocity then
            HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        end
    end
end)

-- // UI Library — Mobile Optimized
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NyxSpeedMenuMobile"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.ScreenOrientation = Enum.ScreenOrientation.Sensor

-- Larger frame for touch targets
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 360, 0, 460)
MainFrame.Position = UDim2.new(0.5, -180, 0.5, -230)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(120, 80, 200)
MainStroke.Thickness = 2
MainStroke.Parent = MainFrame

-- Title Bar — taller for touch
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 48)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 20, 40)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -100, 1, 0)
Title.Position = UDim2.new(0, 16, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡️ NYX SPEED"
Title.TextColor3 = Color3.fromRGB(180, 140, 255)
Title.TextSize = 20
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Close Button — bigger touch target
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 40, 0, 40)
CloseBtn.Position = UDim2.new(1, -46, 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 18
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseBtn

-- Minimize Button — bigger touch target
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 40, 0, 40)
MinBtn.Position = UDim2.new(1, -92, 0, 4)
MinBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 18
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Parent = TitleBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 8)
MinCorner.Parent = MinBtn

-- // Content Area — scrollable for small screens
local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -20, 1, -58)
Content.Position = UDim2.new(0, 0, 10, 50)  -- fixed below
Content.Position = UDim2.new(0, 10, 0, 54)
Content.BackgroundTransparency = 1
Content.ScrollBarThickness = 4
Content.ScrollBarImageColor3 = Color3.fromRGB(120, 80, 200)
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 10)
UIListLayout.Parent = Content

-- // Toggle Function — Mobile-sized
local function CreateToggle(name, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, 0, 0, 48)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(30, 28, 45)
    toggleFrame.BorderSizePixel = 0
    toggleFrame.Parent = Content
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = toggleFrame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -80, 1, 0)
    label.Position = UDim2.new(0, 14, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(220, 220, 240)
    label.TextSize = 16
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = toggleFrame
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 60, 0, 30)
    toggleBtn.Position = UDim2.new(1, -70, 0.5, -15)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    toggleBtn.Text = ""
    toggleBtn.Parent = toggleFrame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleBtn
    
    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, 22, 0, 22)
    toggleCircle.Position = UDim2.new(0, 4, 0.5, -11)
    toggleCircle.BackgroundColor3 = Color3.fromRGB(150, 150, 170)
    toggleCircle.Parent = toggleBtn
    
    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = toggleCircle
    
    local isOn = false
    local function update()
        if isOn then
            TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(120, 80, 200)}):Play()
            TweenService:Create(toggleCircle, TweenInfo.new(0.2), {Position = UDim2.new(1, -26, 0.5, -11), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        else
            TweenService:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 80)}):Play()
            TweenService:Create(toggleCircle, TweenInfo.new(0.2), {Position = UDim2.new(0, 4, 0.5, -11), BackgroundColor3 = Color3.fromRGB(150, 150, 170)}):Play()
        end
    end
    
    toggleBtn.MouseButton1Click:Connect(function()
        isOn = not isOn
        update()
        callback(isOn)
    end)
    
    return toggleFrame
end

-- // Slider Function — Mobile touch optimized
local function CreateSlider(name, minValue, maxValue, defaultValue, callback)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, 0, 0, 58)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(30, 28, 45)
    sliderFrame.BorderSizePixel = 0
    sliderFrame.Parent = Content
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = sliderFrame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 0, 24)
    label.Position = UDim2.new(0, 14, 0, 6)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(220, 220, 240)
    label.TextSize = 15
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = sliderFrame
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 60, 0, 24)
    valueLabel.Position = UDim2.new(1, -66, 0, 6)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(defaultValue)
    valueLabel.TextColor3 = Color3.fromRGB(180, 140, 255)
    valueLabel.TextSize = 15
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = sliderFrame
    
    -- Wider touch area for slider
    local sliderTouchArea = Instance.new("TextButton")
    sliderTouchArea.Size = UDim2.new(1, -20, 0, 36)
    sliderTouchArea.Position = UDim2.new(0, 10, 0, 30)
    sliderTouchArea.BackgroundTransparency = 1
    sliderTouchArea.Text = ""
    sliderTouchArea.Parent = sliderFrame
    
    local sliderBack = Instance.new("Frame")
    sliderBack.Size = UDim2.new(1, 0, 0, 8)
    sliderBack.Position = UDim2.new(0, 0, 0.5, -4)
    sliderBack.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    sliderBack.BorderSizePixel = 0
    sliderBack.Parent = sliderTouchArea
    
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
    
    -- Visible knob for touch feedback
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 24, 0, 24)
    knob.Position = UDim2.new(sliderFill.Size.X.Scale, -12, 0.5, -12)
    knob.BackgroundColor3 = Color3.fromRGB(200, 180, 255)
    knob.BorderSizePixel = 0
    knob.Parent = sliderBack
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob
    
    local knobStroke = Instance.new("UIStroke")
    knobStroke.Color = Color3.fromRGB(120, 80, 200)
    knobStroke.Thickness = 2
    knobStroke.Parent = knob
    
    local dragging = false
    local function updateSlider(inputPos)
        local relPos = math.clamp((inputPos - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X, 0, 1)
        sliderFill.Size = UDim2.new(relPos, 0, 1, 0)
        knob.Position = UDim2.new(relPos, -12, 0.5, -12)
        local value = math.floor(minValue + (maxValue - minValue) * relPos)
        valueLabel.Text = tostring(value)
        callback(value)
    end
    
    sliderTouchArea.MouseButton1Down:Connect(function()
        dragging = true
        local mousePos = UserInputService:GetMouseLocation()
        updateSlider(mousePos.X)
    end)
    
    sliderTouchArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input.Position.X)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging then
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                updateSlider(input.Position.X)
            elseif input.UserInputType == Enum.UserInputType.Touch then
                updateSlider(input.Position.X)
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    return sliderFrame
end

-- // Mobile Virtual Joystick for movement control
local JoystickEnabled = false
local JoystickBase, JoystickKnob, JoystickCenter
local JoystickActive = false
local JoystickTouchInput = nil

local function CreateJoystick()
    local joystickGui = Instance.new("Frame")
    joystickGui.Name = "NyxJoystick"
    joystickGui.Size = UDim2.new(0, 140, 0, 140)
    joystickGui.Position = UDim2.new(0, 30, 1, -170)
    joystickGui.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    joystickGui.BackgroundTransparency = 0.3
    joystickGui.BorderSizePixel = 0
    joystickGui.Parent = ScreenGui
    
    local jCorner = Instance.new("UICorner")
    jCorner.CornerRadius = UDim.new(1, 0)
    jCorner.Parent = joystickGui
    
    local jStroke = Instance.new("UIStroke")
    jStroke.Color = Color3.fromRGB(120, 80, 200)
    jStroke.Thickness = 2
    jStroke.Parent = joystickGui
    
    JoystickBase = joystickGui
    JoystickCenter = joystickGui.AbsolutePosition + joystickGui.AbsoluteSize / 2
    
    JoystickKnob = Instance.new("Frame")
    JoystickKnob.Size = UDim2.new(0, 56, 0, 56)
    JoystickKnob.Position = UDim2.new(0.5, -28, 0.5, -28)
    JoystickKnob.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
    JoystickKnob.BorderSizePixel = 0
    JoystickKnob.Parent = joystickGui
    
    local kCorner = Instance.new("UICorner")
    kCorner.CornerRadius = UDim.new(1, 0)
    kCorner.Parent = JoystickKnob
    
    local kStroke = Instance.new("UIStroke")
    kStroke.Color = Color3.fromRGB(200, 180, 255)
    kStroke.Thickness = 2
    kStroke.Parent = JoystickKnob
    
    -- Touch handling for joystick
    joystickGui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            JoystickActive = true
            JoystickTouchInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if JoystickActive and input == JoystickTouchInput then
            local center = joystickGui.AbsolutePosition + joystickGui.AbsoluteSize / 2
            local delta = input.Position - center
            local maxDist = joystickGui.AbsoluteSize.X / 2 - 28
            local clampedDelta = delta.Magnitude > maxDist and (delta.Unit * maxDist) or delta
            
            JoystickKnob.Position = UDim2.new(0.5, clampedDelta.X - 28, 0.5, clampedDelta.Y - 28)
            
            -- Convert joystick position to 3D movement vector
            local normalized = Vector2.new(clampedDelta.X / maxDist, clampedDelta.Y / maxDist)
            
            if normalized.Magnitude > 0.1 then
                -- Map to camera-relative 3D direction
                local forward = Camera.CFrame.LookVector
                local right = Camera.CFrame.RightVector
                
                local moveVec = (right * normalized.X) + (forward * -normalized.Y)
                Settings.MobileMoveVector = moveVec
                Settings.MobileMoveEnabled = true
            else
                Settings.MobileMoveEnabled = false
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input == JoystickTouchInput then
            JoystickActive = false
            JoystickTouchInput = nil
            JoystickKnob.Position = UDim2.new(0.5, -28, 0.5, -28)
            Settings.MobileMoveEnabled = false
        end
    end)
    
    return joystickGui
end

local joystickInstance = nil

-- // Build UI Elements
CreateSlider("Speed", 16, 1000, 16, function(value)
    Settings.Speed = value
end)

CreateToggle("Enable Speed", function(state)
    Settings.SpeedEnabled = state
    if state and Humanoid then
        Humanoid.WalkSpeed = 16
    end
end)

CreateToggle("AntiCheat Bypass", function(state)
    Settings.AntiCheatBypass = state
    if state then
        RemoveHumanoid()
    else
        RestoreHumanoid()
    end
end)

CreateSlider("TP Smoothness", 0.1, 2, 0.35, function(value)
    Settings.Smoothness = value
end)

CreateToggle("Virtual Joystick", function(state)
    if state then
        if not joystickInstance then
            joystickInstance = CreateJoystick()
        end
    else
        if joystickInstance then
            joystickInstance:Destroy()
            joystickInstance = nil
            Settings.MobileMoveEnabled = false
        end
    end
end)

-- Hint
local KeybindHint = Instance.new("TextLabel")
KeybindHint.Size = UDim2.new(1, 0, 0, 24)
KeybindHint.BackgroundTransparency = 1
KeybindHint.Text = "Tap floating button to toggle menu"
KeybindHint.TextColor3 = Color3.fromRGB(100, 100, 130)
KeybindHint.TextSize = 13
KeybindHint.Font = Enum.Font.Gotham
KeybindHint.Parent = Content

-- // Floating toggle button (replaces Insert keybind for mobile)
local FloatBtn = Instance.new("TextButton")
FloatBtn.Size = UDim2.new(0, 56, 0, 56)
FloatBtn.Position = UDim2.new(1, -70, 0, 120)
FloatBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 200)
FloatBtn.Text = "⚡️"
FloatBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
FloatBtn.TextSize = 24
FloatBtn.Parent = ScreenGui

local floatCorner = Instance.new("UICorner")
floatCorner.CornerRadius = UDim.new(1, 0)
floatCorner.Parent = FloatBtn

local floatStroke = Instance.new("UIStroke")
floatStroke.Color = Color3.fromRGB(200, 180, 255)
floatStroke.Thickness = 2
floatStroke.Parent = FloatBtn

-- Floating button drag
local floatDragging = false
local floatDragStart, floatStartPos

FloatBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        floatDragging = true
        floatDragStart = input.Position
        floatStartPos = FloatBtn.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if floatDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - floatDragStart
        FloatBtn.Position = UDim2.new(
            math.clamp(floatStartPos.X.Scale + delta.X / ScreenGui.AbsoluteSize.X, 0, 1),
            floatStartPos.X.Offset,
            math.clamp(floatStartPos.Y.Scale + delta.Y / ScreenGui.AbsoluteSize.Y, 0, 1),
            floatStartPos.Y.Offset
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        local totalDelta = (input.Position - floatDragStart).Magnitude
        if totalDelta < 8 then
            -- It was a tap, not a drag
            MainFrame.Visible = not MainFrame.Visible
        end
        floatDragging = false
    end
end)

-- // Drag main frame — touch + mouse support
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
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- // Close/Minimize
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    Settings.SpeedEnabled = false
    Settings.MobileMoveEnabled = false
end)

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Content.Visible = not minimized
    MainFrame.Size = minimized and UDim2.new(0, 360, 0, 48) or UDim2.new(0, 360, 0, 460)
end)

-- // Parent
local parentTo = game:GetService("CoreGui")
if not parentTo then
    parentTo = LocalPlayer:WaitForChild("PlayerGui")
end
ScreenGui.Parent = parentTo
