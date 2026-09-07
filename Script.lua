--[[
    StealEgg.lua
    SpeedHack with AntiCheat Bypass
    Humanoid removes ONLY when Speed is enabled
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
    SpeedValue = 50,
    Smoothness = 0.4,
}

-- ====================== VARIABLES ======================
local character = nil
local root = nil
local humanoid = nil
local bodyVelocity = nil
local speedConnection = nil
local humanoidRemoved = false

-- ====================== HELPERS ======================
local function GetRoot()
    if LocalPlayer.Character then
        return LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    end
    return nil
end

local function GetHumanoid()
    if LocalPlayer.Character then
        return LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    end
    return nil
end

local function CleanupSpeed()
    if speedConnection then
        speedConnection:Disconnect()
        speedConnection = nil
    end
    if bodyVelocity and bodyVelocity.Parent then
        bodyVelocity:Destroy()
        bodyVelocity = nil
    end
end

-- ====================== BYPASS (только при включении) ======================
local function EnableBypass()
    local char = LocalPlayer.Character
    if not char then return false end

    root = char:FindFirstChild("HumanoidRootPart")
    humanoid = char:FindFirstChildOfClass("Humanoid")

    if not root then return false end

    -- Переключаем камеру на RootPart ПЕРЕД удалением Humanoid
    Camera.CameraSubject = root
    Camera.CameraType = Enum.CameraType.Custom

    if humanoid and humanoid.Parent then
        humanoid:Destroy()
        humanoidRemoved = true
    end

    -- BodyVelocity для более плавного движения
    if bodyVelocity then
        pcall(function() bodyVelocity:Destroy() end)
    end

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Name = "StealEggVelocity"
    bodyVelocity.MaxForce = Vector3.new(100000, 0, 100000)
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.P = 10000
    bodyVelocity.Parent = root

    return true
end

local function DisableBypass()
    CleanupSpeed()
    humanoidRemoved = false

    -- Просто ждём респавн / новый персонаж
    -- (Humanoid уже удалён, восстановить можно только респавном)
end

-- ====================== SPEED LOOP ======================
local function StartSpeedLoop()
    CleanupSpeed()

    speedConnection = RunService.RenderStepped:Connect(function(dt)
        if not Settings.SpeedEnabled then return end

        root = GetRoot()
        if not root or not root.Parent then return end

        -- Если BodyVelocity пропал — создаём заново
        if not bodyVelocity or not bodyVelocity.Parent then
            bodyVelocity = Instance.new("BodyVelocity")
            bodyVelocity.Name = "StealEggVelocity"
            bodyVelocity.MaxForce = Vector3.new(100000, 0, 100000)
            bodyVelocity.Velocity = Vector3.zero
            bodyVelocity.Parent = root
        end

        local moveDir = Vector3.zero
        local camCF = Camera.CFrame

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDir = moveDir + camCF.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDir = moveDir - camCF.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDir = moveDir - camCF.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDir = moveDir + camCF.RightVector
        end

        -- Убираем Y чтобы не улетать
        moveDir = Vector3.new(moveDir.X, 0, moveDir.Z)

        if moveDir.Magnitude > 0.05 then
            moveDir = moveDir.Unit

            local speed = Settings.SpeedValue

            -- Плавный телепорт
            local offset = moveDir * (speed * dt * Settings.Smoothness * 2.8)
            root.CFrame = root.CFrame + offset

            -- + BodyVelocity
            bodyVelocity.MaxForce = Vector3.new(100000, 0, 100000)
            bodyVelocity.Velocity = moveDir * (speed * 0.85)
        else
            bodyVelocity.Velocity = Vector3.zero
        end
    end)
end

-- ====================== CHARACTER ======================
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(0.6)
    humanoidRemoved = false
    CleanupSpeed()

    -- Камера по умолчанию
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        Camera.CameraSubject = hum
    end

    -- Если спид был включен — включаем заново
    if Settings.SpeedEnabled then
        task.wait(0.3)
        if EnableBypass() then
            StartSpeedLoop()
        end
    end
end)

-- ====================== GUI ======================
local Window = Rayfield:CreateWindow({
    Name = "StealEgg | Speed Bypass",
    LoadingTitle = "StealEgg",
    LoadingSubtitle = "AntiCheat Bypass",
    ConfigurationSaving = { Enabled = false },
    KeySystem = false,
})

local Tab = Window:CreateTab("Speed", 4483362458)

Tab:CreateToggle({
    Name = "Enable SpeedHack (Bypass)",
    CurrentValue = false,
    Flag = "SpeedEnabled",
    Callback = function(Value)
        Settings.SpeedEnabled = Value

        if Value then
            -- Включаем только сейчас
            if EnableBypass() then
                StartSpeedLoop()
                Rayfield:Notify({
                    Title = "SpeedHack",
                    Content = "Bypass включен. Humanoid удалён.",
                    Duration = 3,
                })
            else
                Rayfield:Notify({
                    Title = "Ошибка",
                    Content = "Персонаж не найден",
                    Duration = 3,
                })
                Settings.SpeedEnabled = false
            end
        else
            -- Выключаем
            CleanupSpeed()
            if bodyVelocity then
                pcall(function() bodyVelocity:Destroy() end)
                bodyVelocity = nil
            end
            Rayfield:Notify({
                Title = "SpeedHack",
                Content = "Выключен. Чтобы вернуть Humanoid — респавнись.",
                Duration = 4,
            })
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
    Name = "Smoothness",
    Range = {0.15, 1},
    Increment = 0.05,
    Suffix = "",
    CurrentValue = 0.4,
    Flag = "Smoothness",
    Callback = function(Value)
        Settings.Smoothness = Value
    end,
})

Tab:CreateParagraph({
    Title = "Важно",
    Content = "Humanoid удаляется ТОЛЬКО когда ты нажимаешь Enable.\nПосле выключения Speed — респавнись (сброс персонажа), чтобы Humanoid вернулся.\nКамера не ломается."
})

print("StealEgg fixed | Humanoid removes only on toggle")
