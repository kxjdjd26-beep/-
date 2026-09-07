-- SpeedX v3.0 — Fixed & Beautiful
-- Для Synapse X / Script-Ware / Krnl / Fluxus

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ============ CONFIG ============
local Settings = {
    Enabled = false,
    Speed = 50,            -- studs/sec, ползунок до 1000
    AntiCheatBypass = true,
    SmoothTeleport = true,
    TeleportStep = 3,      -- шаг телепортации
    RemoveHumanoid = true,
    KeepCamera = true
}

-- ============ GUI ============
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpeedX"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Main frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 300, 0, 250)
MainFrame.Position = UDim2.new(0.5, -150, 0.35, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
MainFrame.Active = true
MainFrame.Draggable = true

-- Corner
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 12)
UICorner.Parent = MainFrame

-- Stroke
local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(255, 45, 85)
UIStroke.Thickness = 2
UIStroke.Transparency = 0.2
UIStroke.Parent = MainFrame

-- Gradient background
local BGradient = Instance.new("UIGradient")
BGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(25, 20, 30)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 22))
})
BGradient.Rotation = 45
BGradient.Parent = MainFrame

-- Title bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 40)
TitleBar.Position = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3 = Color3.fromRGB(255, 45, 85)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

-- Нижнюю часть титульного бара делаем прямой
local TitleBottom = Instance.new("Frame")
TitleBottom.Size = UDim2.new(1, 0, 0, 20)
TitleBottom.Position = UDim2.new(0, 0, 0, 20)
TitleBottom.BackgroundColor3 = Color3.fromRGB(255, 45, 85)
TitleBottom.BorderSizePixel = 0
TitleBottom.Parent = TitleBar

-- Title text
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "⚡ SPEEDX v3.0"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 18
Title.Parent = TitleBar

-- Toggle button
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -20, 0, 36)
ToggleBtn.Position = UDim2.new(0, 10, 0, 50)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Text = "ВКЛЮЧИТЬ"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 15
ToggleBtn.Parent = MainFrame
ToggleBtn.AutoButtonColor = true

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 8)
ToggleCorner.Parent = ToggleBtn

-- Speed label
local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(1, -20, 0, 22)
SpeedLabel.Position = UDim2.new(0, 10, 0, 96)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "Скорость: 50 studs/s"
SpeedLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
SpeedLabel.Font = Enum.Font.Gotham
SpeedLabel.TextSize = 14
SpeedLabel.Parent = MainFrame

-- Slider track
local SliderTrack = Instance.new("Frame")
SliderTrack.Size = UDim2.new(1, -20, 0, 8)
SliderTrack.Position = UDim2.new(0, 10, 0, 124)
SliderTrack.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
SliderTrack.BorderSizePixel = 0
SliderTrack.Parent = MainFrame

local TrackCorner = Instance.new("UICorner")
TrackCorner.CornerRadius = UDim.new(0, 4)
TrackCorner.Parent = SliderTrack

-- Fill
local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(0.05, 0, 1, 0)
SliderFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
SliderFill.BorderSizePixel = 0
SliderFill.Parent = SliderTrack

local FillCorner = Instance.new("UICorner")
FillCorner.CornerRadius = UDim.new(0, 4)
FillCorner.Parent = SliderFill

-- Handle
local SliderHandle = Instance.new("TextButton")
SliderHandle.Size = UDim2.new(0, 16, 0, 16)
SliderHandle.Position = UDim2.new(0.05, -8, 0, -4)
SliderHandle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SliderHandle.BorderSizePixel = 0
SliderHandle.Text = ""
SliderHandle.AutoButtonColor = false
SliderHandle.Parent = SliderTrack

local HandleCorner = Instance.new("UICorner")
HandleCorner.CornerRadius = UDim.new(0, 8)
HandleCorner.Parent = SliderHandle

-- Slider logic
local function UpdateSlider(value)
    value = math.clamp(value, 0, 1)
    SliderFill.Size = UDim2.new(value, 0, 1, 0)
    SliderHandle.Position = UDim2.new(value, -8, 0, -4)
    local speed = math.floor(value * 1000)
    if speed < 1 then speed = 1 end
    Settings.Speed = speed
    SpeedLabel.Text = "Скорость: " .. speed .. " studs/s"
end

local function GetSliderValue()
    return SliderFill.Size.X.Scale
end

local dragging = false

SliderHandle.MouseButton1Down:Connect(function()
    dragging = true
end)

SliderTrack.MouseButton1Down:Connect(function(x, y)
    local relativeX = (x - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X
    UpdateSlider(relativeX)
    dragging = true
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local relativeX = (input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X
        UpdateSlider(relativeX)
    end
end)

-- Initialize slider
UpdateSlider(Settings.Speed / 1000)

-- Status label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -20, 0, 20)
StatusLabel.Position = UDim2.new(0, 10, 0, 145)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "Статус: ВЫКЛ"
StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 12
StatusLabel.Parent = MainFrame

-- ============ FUNCTIONS ============
local Humanoid = nil
local RootPart = nil
local CameraSaved = nil
local OriginalHumanoidState = nil
local SpeedConnection = nil
local MoveAccumulator = 0

-- Сохраняем оригинальные значения
local function SaveOriginalState()
    local character = LocalPlayer.Character
    if not character then return end

    Humanoid = character:FindFirstChildOfClass("Humanoid")
    RootPart = character:FindFirstChild("HumanoidRootPart")

    if Humanoid then
        OriginalHumanoidState = {
            WalkSpeed = Humanoid.WalkSpeed,
            JumpPower = Humanoid.JumpPower,
            HipHeight = Humanoid.HipHeight,
            MaxHealth = Humanoid.MaxHealth,
            Health = Humanoid.Health,
            Parent = Humanoid.Parent,
            Name = Humanoid.Name
        }
    end

    if Camera then
        CameraSaved = {
            CameraSubject = Camera.CameraSubject,
            CameraType = Camera.CameraType,
            FieldOfView = Camera.FieldOfView,
            CFrame = Camera.CFrame,
            Focus = Camera.Focus
        }
    end
end

-- Восстанавливаем оригинальные значения
local function RestoreOriginalState()
    local character = LocalPlayer.Character
    if not character then return end

    if Humanoid and not Humanoid:IsDescendantOf(character) then
        local newHumanoid = Instance.new("Humanoid")
        newHumanoid.Name = OriginalHumanoidState.Name
        newHumanoid.WalkSpeed = OriginalHumanoidState.WalkSpeed
        newHumanoid.JumpPower = OriginalHumanoidState.JumpPower
        newHumanoid.HipHeight = OriginalHumanoidState.HipHeight
        newHumanoid.MaxHealth = OriginalHumanoidState.MaxHealth
        newHumanoid.Health = OriginalHumanoidState.Health
        newHumanoid.Parent = character
        Humanoid = newHumanoid
    end

    if Camera and CameraSaved then
        Camera.CameraSubject = CameraSaved.CameraSubject or character:FindFirstChildOfClass("Humanoid")
        Camera.CameraType = CameraSaved.CameraType or Enum.CameraType.Custom
        Camera.FieldOfView = CameraSaved.FieldOfView or 70
    end
end

-- Anti-Cheat Bypass
local function EnableAntiCheatBypass()
    if not Settings.RemoveHumanoid then return end

    SaveOriginalState()

    local character = LocalPlayer.Character
    if not character then return end

    Humanoid = character:FindFirstChildOfClass("Humanoid")
    RootPart = character:FindFirstChild("HumanoidRootPart")

    if Humanoid then
        if Camera and Camera.CameraSubject == Humanoid then
            CameraSaved.CameraSubject = Humanoid
        end

        if Camera then
            Camera.CameraSubject = character
        end

        Humanoid:Destroy()
        Humanoid = nil

        if Settings.KeepCamera and Camera then
            local FakeHumanoid = Instance.new("Humanoid")
            FakeHumanoid.Name = "CameraController"
            FakeHumanoid.Parent = character
            FakeHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            FakeHumanoid.HealthDisplayType = Enum.HumanoidDisplayDistanceType.None
            FakeHumanoid.NameDisplayDistance = 0
            FakeHumanoid.HealthDisplayDistance = 0
            FakeHumanoid.BreakJointsOnDeath = false
            FakeHumanoid.RequiresNeck = false

            Camera.CameraSubject = FakeHumanoid
            Humanoid = FakeHumanoid
        end
    end

    StatusLabel.Text = "Статус: Anti-Cheat Bypass АКТИВЕН"
    StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
end

local function DisableAntiCheatBypass()
    RestoreOriginalState()
    StatusLabel.Text = "Статус: Anti-Cheat Bypass ВЫКЛ"
    StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
end

-- SpeedHack с плавной телепортацией и контролем скорости
local function EnableSpeedHack()
    if SpeedConnection then return end

    SpeedConnection = RunService.Heartbeat:Connect(function(deltaTime)
        if not Settings.Enabled then return end
        if not LocalPlayer.Character then return end

        local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end

        -- Определяем направление
        local moveDirection = Vector3.zero

        if Humanoid and Humanoid:IsA("Humanoid") and Humanoid.MoveDirection.Magnitude > 0 then
            moveDirection = Humanoid.MoveDirection
        else
            local direction = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                direction += Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                direction -= Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                direction += Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                direction -= Camera.CFrame.RightVector
            end
            direction = Vector3.new(direction.X, 0, direction.Z)
            if direction.Magnitude > 0 then
                direction = direction.Unit
            end
            moveDirection = direction
        end

        if moveDirection.Magnitude > 0 then
            moveDirection = Vector3.new(moveDirection.X, 0, moveDirection.Z).Unit

            local stepDistance = Settings.TeleportStep
            local speed = Settings.Speed
            local stepsPerSecond = speed / stepDistance
            local stepDelay = 1 / stepsPerSecond

            MoveAccumulator += deltaTime

            while MoveAccumulator >= stepDelay do
                MoveAccumulator -= stepDelay

                local newPosition = root.Position + moveDirection * stepDistance
                local rayOrigin = root.Position + Vector3.new(0, 1, 0)
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
                rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                local rayResult = workspace:Raycast(rayOrigin, moveDirection * stepDistance, rayParams)

                if not rayResult then
                    root.CFrame = root.CFrame + moveDirection * stepDistance
                else
                    local slideDirection = moveDirection - moveDirection:Dot(rayResult.Normal) * rayResult.Normal
                    if slideDirection.Magnitude > 0.01 then
                        root.CFrame = root.CFrame + slideDirection.Unit * (stepDistance * 0.5)
                    end
                end
            end

            -- Обновляем камеру
            if Camera and Settings.KeepCamera then
                local camOffset = Camera.CFrame.Position - root.Position
                Camera.CFrame = CFrame.new(root.Position + camOffset)
            end
        end
    end)
end

local function DisableSpeedHack()
    if SpeedConnection then
        SpeedConnection:Disconnect()
        SpeedConnection = nil
    end
    MoveAccumulator = 0
end

-- ============ GUI HANDLERS ============
ToggleBtn.MouseButton1Click:Connect(function()
    Settings.Enabled = not Settings.Enabled

    if Settings.Enabled then
        ToggleBtn.Text = "ВЫКЛЮЧИТЬ"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(255, 45, 85)
        StatusLabel.Text = "Статус: ВКЛ"
        StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)

        EnableAntiCheatBypass()
        EnableSpeedHack()
    else
        ToggleBtn.Text = "ВКЛЮЧИТЬ"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        StatusLabel.Text = "Статус: ВЫКЛ"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)

        DisableSpeedHack()
        DisableAntiCheatBypass()
    end
end)

-- ============ CHARACTER RESPAWN HANDLER ============
local function OnCharacterAdded(character)
    if Settings.Enabled then
        task.wait(0.5)
        SaveOriginalState()
        EnableAntiCheatBypass()
        EnableSpeedHack()
    end
end

LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)

-- ============ CLEANUP ============
script.Destroying:Connect(function()
    DisableSpeedHack()
    DisableAntiCheatBypass()
    ScreenGui:Destroy()
end)

print("[SpeedX] v3.0 загружен. Тяни ползунок — лети.")
