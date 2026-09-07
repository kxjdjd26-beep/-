-- Nyx Speed Menu | Roblox Executor Script
-- Smooth TP-based speedhack + humanoid removal anticheat bypass

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- // State
local Settings = {
    Speed = 16,
    SpeedEnabled = false,
    AntiCheatBypass = false,
    Smoothness = 0.35, -- teleport step distance multiplier
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
    -- Re-apply bypass if it was on
    if Settings.AntiCheatBypass then
        task.wait(1)
        RemoveHumanoid()
    end
end)

-- // AntiCheat Bypass — removes humanoid, preserves camera
function RemoveHumanoid()
    if not Character then return end
    local hum = Character:FindFirstChild("Humanoid")
    if hum then
        -- Store camera subject before removing
        local camSubject = Camera.CameraSubject
        
        -- Disable humanoid states that anticheat monitors
        hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
        hum:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
        hum:ChangeState(Enum.HumanoidStateType.Physics)
        
        -- Remove humanoid after a short delay
        task.delay(0.1, function()
            if hum and hum.Parent then
                -- Keep camera locked to root part
                Camera.CameraSubject = Character:FindFirstChild("HumanoidRootPart") or camSubject
                
                -- Animate script will break, so kill it too
                local animate = Character:FindFirstChild("Animate")
                if animate then animate:Destroy() end
                
                hum:Destroy()
            end
        end)
    end
    
    -- Anchor the root slightly to prevent ragdoll/physics death
    task.wait(0.15)
    if HumanoidRootPart then
        HumanoidRootPart.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5, 100, 1)
    end
end

function RestoreHumanoid()
    -- Respawn to get humanoid back
    if LocalPlayer.Character then
        LocalPlayer.Character:BreakJoints()
    end
end

-- // Smooth TP Speedhack
local lastPosition = nil

RunService.Heartbeat:Connect(function(deltaTime)
    if not Settings.SpeedEnabled then return end
    if not Character or not HumanoidRootPart or not HumanoidRootPart.Parent then return end
    
    -- Get move direction from controls
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
    
    -- Flatten Y to avoid vertical drift
    moveDirection = Vector3.new(moveDirection.X, 0, moveDirection.Z)
    
    if moveDirection.Magnitude > 0 then
        moveDirection = moveDirection.Unit
        
        -- Calculate teleport step
        local stepSize = (Settings.Speed / 16) * Settings.Smoothness
        local steps = math.ceil(stepSize / 0.5) -- break into small teleports
        
        for i = 1, steps do
            local step = moveDirection * (stepSize / steps)
            HumanoidRootPart.CFrame = HumanoidRootPart.CFrame + step
            task.wait()
        end
        
        -- Reset velocity to prevent anticheat velocity checks
        if HumanoidRootPart.AssemblyLinearVelocity then
            HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        end
    end
end)

-- // UI Library (Clean custom menu)
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "NyxSpeedMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 320, 0, 280)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -140)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(120, 80, 200)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 36)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 20, 40)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡ NYX SPEED"
Title.TextColor3 = Color3.fromRGB(180, 140, 255)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -34, 0, 4)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

-- Minimize Button
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 28, 0, 28)
MinBtn.Position = UDim2.new(1, -70, 0, 4)
MinBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
MinBtn.Text = "—"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 14
MinBtn.Font = Enum.Font.GothamBold
MinBtn.Parent = TitleBar

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinBtn

-- // Content Area
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -20, 1, -50)
Content.Position = UDim2.new(0, 10, 0, 42)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 8)
UIListLayout.Parent = Content

-- // Toggle Function
local function CreateToggle(name, yPos, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, 0, 0, 34)
    toggleFrame.BackgroundColor3 = Color3.fromRGB(30, 28, 45)
    toggleFrame.BorderSizePixel = 0
    toggleFrame.Parent = Content
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = toggleFrame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(220, 220, 240)
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = toggleFrame
    
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(0, 46, 0, 22)
    toggleBtn.Position = UDim2.new(1, -54, 0.5, -11)
    toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    toggleBtn.Text = ""
    toggleBtn.Parent = toggleFrame
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleBtn
    
    local toggleCircle = Instance.new("Frame")
    toggleCircle.Size = UDim2.new(0, 16, 0, 16)
    toggleCircle.Position = UDim2.new(0, 3, 0.5, -8)
    toggleCircle.BackgroundColor3 = Color3.fromRGB(150, 150, 170)
    toggleCircle.Parent = toggleBtn
    
    local circleCorner = Instance.new("UICorner")
    circleCorner.CornerRadius = UDim.new(1, 0)
    circleCorner.Parent = toggleCircle
    
    local isOn = false
    local function update()
        local tween = game:GetService("TweenService")
        if isOn then
            tween:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(120, 80, 200)}):Play()
            tween:Create(toggleCircle, TweenInfo.new(0.2), {Position = UDim2.new(1, -19, 0.5, -8), BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
        else
            tween:Create(toggleBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 60, 80)}):Play()
            tween:Create(toggleCircle, TweenInfo.new(0.2), {Position = UDim2.new(0, 3, 0.5, -8), BackgroundColor3 = Color3.fromRGB(150, 150, 170)}):Play()
        end
    end
    
    toggleBtn.MouseButton1Click:Connect(function()
        isOn = not isOn
        update()
        callback(isOn)
    end)
    
    return toggleFrame
end

-- // Slider Function
local function CreateSlider(name, yPos, minValue, maxValue, defaultValue, callback)
    local sliderFrame = Instance.new("Frame")
    sliderFrame.Size = UDim2.new(1, 0, 0, 42)
    sliderFrame.BackgroundColor3 = Color3.fromRGB(30, 28, 45)
    sliderFrame.BorderSizePixel = 0
    sliderFrame.Parent = Content
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = sliderFrame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -60, 0, 18)
    label.Position = UDim2.new(0, 10, 0, 4)
    label.BackgroundTransparency = 1
    label.Text = name
    label.TextColor3 = Color3.fromRGB(220, 220, 240)
    label.TextSize = 12
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = sliderFrame
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Size = UDim2.new(0, 50, 0, 18)
    valueLabel.Position = UDim2.new(1, -56, 0, 4)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(defaultValue)
    valueLabel.TextColor3 = Color3.fromRGB(180, 140, 255)
    valueLabel.TextSize = 12
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = sliderFrame
    
    local sliderBack = Instance.new("Frame")
    sliderBack.Size = UDim2.new(1, -20, 0, 6)
    sliderBack.Position = UDim2.new(0, 10, 0, 28)
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
    
    local dragging = false
    local function updateSlider(inputPos)
        local relPos = math.clamp((inputPos - sliderBack.AbsolutePosition.X) / sliderBack.AbsoluteSize.X, 0, 1)
        sliderFill.Size = UDim2.new(relPos, 0, 1, 0)
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

-- // Build UI Elements
-- Speed Slider
CreateSlider("Speed", 0, 16, 1000, 16, function(value)
    Settings.Speed = value
end)

-- Speed Toggle
CreateToggle("Enable Speed", 0, function(state)
    Settings.SpeedEnabled = state
    if state and Humanoid then
        Humanoid.WalkSpeed = 16 -- keep normal, we handle movement ourselves
    end
end)

-- AntiCheat Bypass Toggle
CreateToggle("AntiCheat Bypass", 0, function(state)
    Settings.AntiCheatBypass = state
    if state then
        RemoveHumanoid()
    else
        RestoreHumanoid()
    end
end)

-- Smoothness Slider
CreateSlider("TP Smoothness", 0, 0.1, 2, 0.35, function(value)
    Settings.Smoothness = value
end)

-- Keybind Hint
local KeybindHint = Instance.new("TextLabel")
KeybindHint.Size = UDim2.new(1, 0, 0, 20)
KeybindHint.BackgroundTransparency = 1
KeybindHint.Text = "Insert — toggle menu visibility"
KeybindHint.TextColor3 = Color3.fromRGB(100, 100, 130)
KeybindHint.TextSize = 11
KeybindHint.Font = Enum.Font.Gotham
KeybindHint.Parent = Content

-- // Drag functionality
local dragging = false
local dragStart, startPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- // Toggle visibility with Insert key
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.Insert then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end)

-- // Close/Minimize
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    Settings.SpeedEnabled = false
end)

local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    Content.Visible = not minimized
    MainFrame.Size = minimized and UDim2.new(0, 320, 0, 36) or UDim2.new(0, 320, 0, 280)
end)

-- // Parent to correct location
local parentTo = game:GetService("CoreGui")
if not parentTo then
    parentTo = LocalPlayer:WaitForChild("PlayerGui")
end
ScreenGui.Parent = parentTo
