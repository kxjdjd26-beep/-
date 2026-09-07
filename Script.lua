-- SpeedX v2.0 — Anti-Cheat Bypass Speed System
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
    Speed = 16,           -- студа/сек (до 1000)
    AntiCheatBypass = true,
    SmoothTeleport = true,
    TeleportStep = 3,     -- дистанция шага телепортации
    RemoveHumanoid = true,
    KeepCamera = true,
    Smoothness = 0.05     -- задержка между шагами
}

-- ============ GUI ============
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpeedX"
ScreenGui.Parent = game:GetService("CoreGui")
ScreenGui.ResetOnSpawn = false

-- Main frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 280, 0, 200)
MainFrame.Position = UDim2.new(0.5, -140, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
MainFrame.Active = true
MainFrame.Draggable = true

-- Title
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, 0, 0, 30)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundColor3 = Color3.fromRGB(255, 45, 85)
Title.BorderSizePixel = 0
Title.Text = "⚡ SpeedX v2.0"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 16
Title.Parent = MainFrame

-- Enable button
local EnableBtn = Instance.new("TextButton")
EnableBtn.Name = "EnableBtn"
EnableBtn.Size = UDim2.new(1, -20, 0, 30)
EnableBtn.Position = UDim2.new(0, 10, 0, 40)
EnableBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
EnableBtn.BorderSizePixel = 0
EnableBtn.Text = "ВКЛЮЧИТЬ"
EnableBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
EnableBtn.Font = Enum.Font.GothamBold
EnableBtn.TextSize = 14
EnableBtn.Parent = MainFrame

-- Speed label
local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Name = "SpeedLabel"
SpeedLabel.Size = UDim2.new(1, -20, 0, 20)
SpeedLabel.Position = UDim2.new(0, 10, 0, 80)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "Скорость: 16 studs/s"
SpeedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
SpeedLabel.Font = Enum.Font.Gotham
SpeedLabel.TextSize = 13
SpeedLabel.Parent = MainFrame

-- Speed slider
local SpeedSlider = Instance.new("TextBox")
SpeedSlider.Name = "SpeedSlider"
SpeedSlider.Size = UDim2.new(1, -20, 0, 25)
SpeedSlider.Position = UDim2.new(0, 10, 0, 105)
SpeedSlider.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
SpeedSlider.BorderSizePixel = 0
SpeedSlider.Text = "16"
SpeedSlider.TextColor3 = Color3.fromRGB(255, 255, 255)
SpeedSlider.Font = Enum.Font.Gotham
SpeedSlider.TextSize = 14
SpeedSlider.Parent = MainFrame

-- Apply button
local ApplyBtn = Instance.new("TextButton")
ApplyBtn.Name = "ApplyBtn"
ApplyBtn.Size = UDim2.new(1, -20, 0, 25)
ApplyBtn.Position = UDim2.new(0, 10, 0, 140)
ApplyBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
ApplyBtn.BorderSizePixel = 0
ApplyBtn.Text = "ПРИМЕНИТЬ"
ApplyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ApplyBtn.Font = Enum.Font.GothamBold
ApplyBtn.TextSize = 13
ApplyBtn.Parent = MainFrame

-- Status label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Size = UDim2.new(1, -20, 0, 20)
StatusLabel.Position = UDim2.new(0, 10, 0, 170)
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

-- Anti-Cheat Bypass: удаляем Humanoid но сохраняем камеру
local function EnableAntiCheatBypass()
    if not Settings.RemoveHumanoid then return end
    
    SaveOriginalState()
    
    local character = LocalPlayer.Character
    if not character then return end
    
    Humanoid = character:FindFirstChildOfClass("Humanoid")
    RootPart = character:FindFirstChild("HumanoidRootPart")
    
    if Humanoid then
        -- Сохраняем камеру до удаления
        if Camera and Camera.CameraSubject == Humanoid then
            CameraSaved.CameraSubject = Humanoid
        end
        
        -- Отключаем humanoid от камеры
        if Camera then
            Camera.CameraSubject = character
        end
        
        -- Удаляем humanoid
        Humanoid:Destroy()
        Humanoid = nil
        
        -- Создаём фейковый humanoid для камеры
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

-- Отключение Anti-Cheat Bypass
local function DisableAntiCheatBypass()
    RestoreOriginalState()
    StatusLabel.Text = "Статус: Anti-Cheat Bypass ВЫКЛ"
    StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
end

-- SpeedHack с плавной телепортацией
local function EnableSpeedHack()
    if not Settings.Enabled then return end
    if not LocalPlayer.Character then return end
    
    local character = LocalPlayer.Character
    local root = character:FindFirstChild("HumanoidRootPart")
    
    if not root then return end
    
    -- Сохраняем камеру
    if Camera and not Camera.CameraSubject then
        Camera.CameraSubject = character
    end
    
    SpeedConnection = RunService.RenderStepped:Connect(function(deltaTime)
        if not Settings.Enabled then return end
        if not LocalPlayer.Character then return end
        
        root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        -- Определяем направление движения
        local moveDirection = Vector3.zero
        
        if Humanoid and Humanoid:IsA("Humanoid") and Humanoid.MoveDirection.Magnitude > 0 then
            moveDirection = Humanoid.MoveDirection
        else
            -- Используем клавиши для определения направления
            local direction = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                direction = direction + Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                direction = direction - Camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                direction = direction + Camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                direction = direction - Camera.CFrame.RightVector
            end
            direction = Vector3.new(direction.X, 0, direction.Z).Unit
            moveDirection = direction
        end
        
        if moveDirection.Magnitude > 0 then
            moveDirection = Vector3.new(moveDirection.X, 0, moveDirection.Z).Unit
            
            local stepDistance = Settings.TeleportStep
            local speed = Settings.Speed
            local stepsPerSecond = speed / stepDistance
            local stepDelay = 1 / stepsPerSecond
            
            -- Плавная телепортация
            if Settings.SmoothTeleport then
                local newPosition = root.Position + moveDirection * stepDistance
                
                -- Проверяем коллизии (опционально)
                local rayOrigin = root.Position + Vector3.new(0, 1, 0)
                local rayDirection = moveDirection
                local rayParams = RaycastParams.new()
                rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
                rayParams.FilterType = Enum.RaycastFilterType.Blacklist
                
                local rayResult = workspace:Raycast(rayOrigin, rayDirection * stepDistance, rayParams)
                
                if not rayResult then
                    root.CFrame = root.CFrame + moveDirection * stepDistance
                else
                    -- Скольжение вдоль стены
                    local slideDirection = moveDirection - moveDirection:Dot(rayResult.Normal) * rayResult.Normal
                    if slideDirection.Magnitude > 0.01 then
                        root.CFrame = root.CFrame + slideDirection.Unit * (stepDistance * 0.5)
                    end
                end
                
                -- Обновляем камеру
                if Camera and Settings.KeepCamera then
                    local camOffset = Camera.CFrame.Position - root.Position
                    Camera.CFrame = CFrame.new(root.Position + camOffset)
                end
            else
                -- Мгновенная телепортация (менее плавно но быстрее)
                root.CFrame = root.CFrame + moveDirection * stepDistance
            end
        end
    end)
end

-- Отключение SpeedHack
local function DisableSpeedHack()
    if SpeedConnection then
        SpeedConnection:Disconnect()
        SpeedConnection = nil
    end
end

-- ============ GUI HANDLERS ============
EnableBtn.MouseButton1Click:Connect(function()
    Settings.Enabled = not Settings.Enabled
    
    if Settings.Enabled then
        EnableBtn.Text = "ВЫКЛЮЧИТЬ"
        EnableBtn.BackgroundColor3 = Color3.fromRGB(255, 45, 85)
        StatusLabel.Text = "Статус: ВКЛ"
        StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        
        EnableAntiCheatBypass()
        EnableSpeedHack()
    else
        EnableBtn.Text = "ВКЛЮЧИТЬ"
        EnableBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        StatusLabel.Text = "Статус: ВЫКЛ"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        
        DisableSpeedHack()
        DisableAntiCheatBypass()
    end
end)

ApplyBtn.MouseButton1Click:Connect(function()
    local newSpeed = tonumber(SpeedSlider.Text)
    if newSpeed and newSpeed > 0 and newSpeed <= 1000 then
        Settings.Speed = newSpeed
        SpeedLabel.Text = "Скорость: " .. newSpeed .. " studs/s"
        
        if Settings.Enabled then
            DisableSpeedHack()
            EnableSpeedHack()
        end
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

print("[SpeedX] Загружен. Настройки: Speed=" .. Settings.Speed .. ", AntiCheat=" .. tostring(Settings.AntiCheatBypass))
