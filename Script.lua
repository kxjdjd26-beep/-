--[[
    StealEgg.lua
    SpeedHack with AntiCheat Bypass
    Method: Remove Humanoid + smooth CFrame teleports
    Camera stays intact
]]

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ====================== SETTINGS ======================
local Settings = {
    SpeedEnabled = false,
    SpeedValue = 50,          -- 1 - 1000
    Smoothness = 0.35,        -- насколько плавно телепортирует (меньше = резче)
}

-- ====================== VARIABLES ======================
local character = nil
local root = nil
local humanoid = nil
local bodyVelocity = nil
local connection = nil
local originalCameraSubject = nil

-- ====================== BYPASS + SPEED ======================
local function Cleanup()
    if connection then
        connection:Disconnect()
        connection = nil
    end
    if bodyVelocity and bodyVelocity.Parent then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
end

local function SetupCharacter(char)
    Cleanup()

    character = char
    root = char:WaitForChild("HumanoidRootPart", 5)
    humanoid = char:FindFirstChildOfClass("Humanoid")

    if not root then return end

    -- Сохраняем камеру
    originalCameraSubject = Camera.CameraSubject

    -- AntiCheat Bypass: удаляем Humanoid
    -- Камеру переключаем на RootPart, чтобы не ломалась
    if humanoid then
        Camera.CameraSubject = root
        humanoid:Destroy()
        humanoid = nil
    end

    -- Создаём BodyVelocity на всякий случай (для стабильности)
    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(0, 0, 0) -- пока выключен
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.Parent = root
end

local function StartSpeed()
    if connection then return end

    connection = RunService.Heartbeat:Connect(function(dt)
        if not Settings.SpeedEnabled then return end
        if not character or not root or not root.Parent then return end

        local moveDirection = Vector3.zero

        -- Читаем WASD + стрелки
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

        -- Убираем вертикаль, чтобы не улетать вверх/вниз от камеры
        moveDirection = Vector3.new(moveDirection.X, 0, moveDirection.Z)

        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit

            -- Плавная телепортация
            local speed = Settings.SpeedValue
            local offset = moveDirection * speed * dt * Settings.Smoothness * 3.5

            -- Небольшая плавная телепортация
            root.CFrame = root.CFrame + offset

            -- Можно дополнительно подталкивать BodyVelocity для ещё большей плавности
            if bodyVelocity then
                bodyVelocity.MaxForce = Vector3.new(1e5, 0, 1e5)
                bodyVelocity.Velocity = moveDirection * speed * 0.6
            end
        else
            if bodyVelocity then
                bodyVelocity.Velocity = Vector3.zero
                bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
            end
        end
    end)
end

local function StopSpeed()
    Cleanup()
    if bodyVelocity and bodyVelocity.Parent then
        bodyVelocity.Velocity = Vector3.zero
        bodyVelocity.MaxForce = Vector3.new(0, 0, 0)
    end
end

-- ====================== CHARACTER HANDLING ======================
local function OnCharacterAdded(char)
    task.wait(0.4) -- ждём полной загрузки
    SetupCharacter(char)

    if Settings.SpeedEnabled then
        StartSpeed()
    end
end

if LocalPlayer.Character then
    OnCharacterAdded(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(OnCharacterAdded)

-- ====================== RAYFIELD GUI ======================
local Window = Rayfield:CreateWindow({
    Name = "StealEgg | Speed Bypass",
    LoadingTitle = "StealEgg",
    LoadingSubtitle = "AntiCheat Bypass Speed",
    ConfigurationSaving = {
        Enabled = false,
    },
    KeySystem = false,
})

local Tab = Window:CreateTab("Speed", 4483362458)

Tab:CreateToggle({
    Name = "Enable SpeedHack",
    CurrentValue = false,
    Flag = "SpeedEnabled",
    Callback = function(Value)
        Settings.SpeedEnabled = Value
        if Value then
            if character and root then
                StartSpeed()
            else
                if LocalPlayer.Character then
                    OnCharacterAdded(LocalPlayer.Character)
                end
            end
        else
            StopSpeed()
        end
    end,
})

Tab:CreateSlider({
    Name = "Speed",
    Range = {1, 1000},
    Increment = 1,
    Suffix = "",
    CurrentValue = 50,
    Flag = "SpeedValue",
    Callback = function(Value)
        Settings.SpeedValue = Value
    end,
})

Tab:CreateSlider({
    Name = "Smoothness (Teleport)",
    Range = {0.1, 1},
    Increment = 0.05,
    Suffix = "",
    CurrentValue = 0.35,
    Flag = "Smoothness",
    Callback = function(Value)
        Settings.Smoothness = Value
    end,
})

Tab:CreateParagraph({
    Title = "Как работает",
    Content = "Humanoid удаляется (bypass). Камера остаётся на RootPart. Скорость = плавные микро-телепорты + BodyVelocity. Чем выше Smoothness — тем мягче движение."
})

print("StealEgg loaded | AntiCheat Bypass SpeedHack ready")
