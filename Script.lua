-- ================================
--   SpeedHack + AntiCheat Bypass
--   by: executor script
-- ================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ================================
-- НАСТРОЙКИ
-- ================================
local Settings = {
    Speed = 50,
    Enabled = false,
    BypassEnabled = false,
    StepSize = 3,       -- размер одного шага телепортации (меньше = плавнее)
    StepDelay = 0.01,   -- задержка между шагами
}

-- ================================
-- GUI
-- ================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SpeedHackGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = game:GetService("CoreGui")

-- Основное окно
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 300, 0, 360)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -180)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(100, 80, 200)
MainStroke.Thickness = 1.5
MainStroke.Parent = MainFrame

-- Градиент-заголовок
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 50)
TitleBar.BackgroundColor3 = Color3.fromRGB(25, 18, 50)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 12)
TitleCorner.Parent = TitleBar

-- Нижняя часть заголовка (скрывает нижние углы)
local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 12)
TitleFix.Position = UDim2.new(0, 0, 1, -12)
TitleFix.BackgroundColor3 = Color3.fromRGB(25, 18, 50)
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text = "⚡ SpeedHack"
TitleLabel.Size = UDim2.new(1, -60, 1, 0)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = Color3.fromRGB(200, 180, 255)
TitleLabel.TextSize = 16
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TitleBar

local SubLabel = Instance.new("TextLabel")
SubLabel.Text = "Anticheat Bypass Edition"
SubLabel.Size = UDim2.new(1, -60, 0, 16)
SubLabel.Position = UDim2.new(0, 15, 0, 28)
SubLabel.BackgroundTransparency = 1
SubLabel.TextColor3 = Color3.fromRGB(120, 100, 180)
SubLabel.TextSize = 11
SubLabel.Font = Enum.Font.Gotham
SubLabel.TextXAlignment = Enum.TextXAlignment.Left
SubLabel.Parent = TitleBar

-- Кнопка закрыть
local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "✕"
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -42, 0, 9)
CloseBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = TitleBar

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Контент
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, 0, 1, -50)
Content.Position = UDim2.new(0, 0, 0, 50)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 8)
ContentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
ContentLayout.Parent = Content

local ContentPadding = Instance.new("UIPadding")
ContentPadding.PaddingTop = UDim.new(0, 12)
ContentPadding.PaddingLeft = UDim.new(0, 12)
ContentPadding.PaddingRight = UDim.new(0, 12)
ContentPadding.Parent = Content

-- Функция создания секции
local function CreateSection(title)
    local Section = Instance.new("Frame")
    Section.Size = UDim2.new(1, 0, 0, 28)
    Section.BackgroundTransparency = 1

    local Line = Instance.new("Frame")
    Line.Size = UDim2.new(1, 0, 0, 1)
    Line.Position = UDim2.new(0, 0, 0.5, 0)
    Line.BackgroundColor3 = Color3.fromRGB(60, 45, 100)
    Line.BorderSizePixel = 0
    Line.Parent = Section

    local SLabel = Instance.new("TextLabel")
    SLabel.Text = " " .. title .. " "
    SLabel.Size = UDim2.new(0, 0, 1, 0)
    SLabel.Position = UDim2.new(0, 10, 0, 0)
    SLabel.AutomaticSize = Enum.AutomaticSize.X
    SLabel.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
    SLabel.TextColor3 = Color3.fromRGB(120, 100, 180)
    SLabel.TextSize = 11
    SLabel.Font = Enum.Font.GothamBold
    SLabel.Parent = Section

    Section.Parent = Content
    return Section
end

-- Функция создания переключателя
local function CreateToggle(labelText, callback)
    local Row = Instance.new("Frame")
    Row.Size = UDim2.new(1, 0, 0, 36)
    Row.BackgroundColor3 = Color3.fromRGB(22, 18, 38)
    Row.BorderSizePixel = 0
    Row.Parent = Content

    local RowCorner = Instance.new("UICorner")
    RowCorner.CornerRadius = UDim.new(0, 8)
    RowCorner.Parent = Row

    local Label = Instance.new("TextLabel")
    Label.Text = labelText
    Label.Size = UDim2.new(1, -60, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.TextColor3 = Color3.fromRGB(220, 210, 255)
    Label.TextSize = 13
    Label.Font = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Row

    local Toggle = Instance.new("Frame")
    Toggle.Size = UDim2.new(0, 40, 0, 20)
    Toggle.Position = UDim2.new(1, -50, 0.5, -10)
    Toggle.BackgroundColor3 = Color3.fromRGB(50, 40, 80)
    Toggle.BorderSizePixel = 0
    Toggle.Parent = Row

    local ToggleCorner = Instance.new("UICorner")
    ToggleCorner.CornerRadius = UDim.new(1, 0)
    ToggleCorner.Parent = Toggle

    local Knob = Instance.new("Frame")
    Knob.Size = UDim2.new(0, 16, 0, 16)
    Knob.Position = UDim2.new(0, 2, 0.5, -8)
    Knob.BackgroundColor3 = Color3.fromRGB(150, 130, 200)
    Knob.BorderSizePixel = 0
    Knob.Parent = Toggle

    local KnobCorner = Instance.new("UICorner")
    KnobCorner.CornerRadius = UDim.new(1, 0)
    KnobCorner.Parent = Knob

    local state = false

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 1, 0)
    Btn.BackgroundTransparency = 1
    Btn.Text = ""
    Btn.Parent = Row

    Btn.MouseButton1Click:Connect(function()
        state = not state
        local goal_knob = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
        local goal_color = state and Color3.fromRGB(80, 50, 180) or Color3.fromRGB(50, 40, 80)
        local knob_color = state and Color3.fromRGB(180, 160, 255) or Color3.fromRGB(150, 130, 200)

        TweenService:Create(Knob, TweenInfo.new(0.2), {Position = goal_knob, BackgroundColor3 = knob_color}):Play()
        TweenService:Create(Toggle, TweenInfo.new(0.2), {BackgroundColor3 = goal_color}):Play()

        callback(state)
    end)

    return Row
end

-- Функция слайдера
local function CreateSlider(labelText, minV, maxV, defaultV, callback)
    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, 0, 0, 60)
    Container.BackgroundColor3 = Color3.fromRGB(22, 18, 38)
    Container.BorderSizePixel = 0
    Container.Parent = Content

    local ContCorner = Instance.new("UICorner")
    ContCorner.CornerRadius = UDim.new(0, 8)
    ContCorner.Parent = Container

    local LabelRow = Instance.new("Frame")
    LabelRow.Size = UDim2.new(1, 0, 0, 28)
    LabelRow.BackgroundTransparency = 1
    LabelRow.Parent = Container

    local SLabel = Instance.new("TextLabel")
    SLabel.Text = labelText
    SLabel.Size = UDim2.new(0.7, 0, 1, 0)
    SLabel.Position = UDim2.new(0, 12, 0, 0)
    SLabel.BackgroundTransparency = 1
    SLabel.TextColor3 = Color3.fromRGB(220, 210, 255)
    SLabel.TextSize = 13
    SLabel.Font = Enum.Font.Gotham
    SLabel.TextXAlignment = Enum.TextXAlignment.Left
    SLabel.Parent = LabelRow

    local ValLabel = Instance.new("TextLabel")
    ValLabel.Text = tostring(defaultV)
    ValLabel.Size = UDim2.new(0.3, -12, 1, 0)
    ValLabel.Position = UDim2.new(0.7, 0, 0, 0)
    ValLabel.BackgroundTransparency = 1
    ValLabel.TextColor3 = Color3.fromRGB(140, 120, 220)
    ValLabel.TextSize = 13
    ValLabel.Font = Enum.Font.GothamBold
    ValLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValLabel.Parent = LabelRow

    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(1, -24, 0, 6)
    Track.Position = UDim2.new(0, 12, 0, 38)
    Track.BackgroundColor3 = Color3.fromRGB(40, 32, 70)
    Track.BorderSizePixel = 0
    Track.Parent = Container

    local TrackCorner = Instance.new("UICorner")
    TrackCorner.CornerRadius = UDim.new(1, 0)
    TrackCorner.Parent = Track

    local Fill = Instance.new("Frame")
    Fill.Size = UDim2.new((defaultV - minV)/(maxV - minV), 0, 1, 0)
    Fill.BackgroundColor3 = Color3.fromRGB(100, 70, 200)
    Fill.BorderSizePixel = 0
    Fill.Parent = Track

    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(1, 0)
    FillCorner.Parent = Fill

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 32)
    Btn.Position = UDim2.new(0, 0, 0, 24)
    Btn.BackgroundTransparency = 1
    Btn.Text = ""
    Btn.Parent = Container

    local dragging = false

    local function update(input)
        local trackPos = Track.AbsolutePosition.X
        local trackSize = Track.AbsoluteSize.X
        local rel = math.clamp((input.Position.X - trackPos) / trackSize, 0, 1)
        local value = math.floor(minV + rel * (maxV - minV))
        Fill.Size = UDim2.new(rel, 0, 1, 0)
        ValLabel.Text = tostring(value)
        callback(value)
    end

    Btn.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            update(i)
        end
    end)
    Btn.MouseButton1Down:Connect(function(x, y)
        update({Position = Vector3.new(x, y, 0)})
    end)

    return Container
end

-- ================================
-- UI ЭЛЕМЕНТЫ
-- ================================

CreateSection("SPEED HACK")
CreateToggle("SpeedHack ON/OFF", function(state)
    Settings.Enabled = state
end)
CreateSlider("Скорость", 1, 1000, 50, function(v)
    Settings.Speed = v
end)

CreateSection("ANTICHEAT BYPASS")
CreateToggle("Bypass Humanoid", function(state)
    Settings.BypassEnabled = state
end)

CreateSection("ИНФОРМАЦИЯ")
local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, 0, 0, 48)
InfoLabel.BackgroundColor3 = Color3.fromRGB(18, 25, 18)
InfoLabel.TextColor3 = Color3.fromRGB(100, 200, 120)
InfoLabel.TextSize = 11
InfoLabel.Font = Enum.Font.Gotham
InfoLabel.Text = "Bypass: удаляет Humanoid,\nкамера остаётся на месте.\nSpeed: микро-телепортации."
InfoLabel.TextWrapped = true
InfoLabel.BorderSizePixel = 0
InfoLabel.Parent = Content

local InfoCorner = Instance.new("UICorner")
InfoCorner.CornerRadius = UDim.new(0, 8)
InfoCorner.Parent = InfoLabel

-- ================================
-- DRAG (перетаскивание окна)
-- ================================
local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
TitleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- ================================
-- ANTICHEAT BYPASS LOGIC
-- ================================
-- Сохраняем ссылку на камеру и CFrame до удаления
local bypassActive = false
local fakeRoot = nil
local savedCameraCFrame = nil

local function ApplyBypass()
    local character = LocalPlayer.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not hrp then return end

    -- Сохраняем subject камеры
    savedCameraCFrame = Camera.CFrame

    -- Создаём невидимый Part как anchor для камеры вместо HumanoidRootPart
    fakeRoot = Instance.new("Part")
    fakeRoot.Name = "FakeRoot"
    fakeRoot.Size = Vector3.new(0.1, 0.1, 0.1)
    fakeRoot.Transparency = 1
    fakeRoot.CanCollide = false
    fakeRoot.Anchored = true
    fakeRoot.CFrame = hrp.CFrame
    fakeRoot.Parent = workspace

    -- Переключаем камеру на fakeRoot
    Camera.CameraSubject = fakeRoot

    -- Удаляем humanoid (обходит некоторые античиты)
    humanoid:Destroy()

    bypassActive = true
end

local function RemoveBypass()
    local character = LocalPlayer.Character
    if not character then return end

    -- Восстанавливаем камеру на новый humanoid (если respawn)
    if fakeRoot then
        fakeRoot:Destroy()
        fakeRoot = nil
    end

    -- Пробуем найти humanoid (после respawn)
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        Camera.CameraSubject = humanoid
    end

    bypassActive = false
end

-- Следим за состоянием bypass
RunService.Heartbeat:Connect(function()
    if Settings.BypassEnabled and not bypassActive then
        ApplyBypass()
    elseif not Settings.BypassEnabled and bypassActive then
        RemoveBypass()
    end

    -- Синхронизируем fakeRoot с позицией персонажа (камера следит)
    if bypassActive and fakeRoot then
        local character = LocalPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if hrp then
            fakeRoot.CFrame = hrp.CFrame
        end
    end
end)

-- ================================
-- SPEEDHACK LOGIC (микро-телепортации)
-- ================================
local isStepping = false

local function GetMoveDirection()
    local moveDir = Vector3.new(0, 0, 0)
    local camCF = Camera.CFrame
    local right = camCF.RightVector
    local fwd = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z).Unit

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + fwd end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - fwd end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - Vector3.new(right.X, 0, right.Z) end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + Vector3.new(right.X, 0, right.Z) end

    if moveDir.Magnitude > 0 then
        moveDir = moveDir.Unit
    end
    return moveDir
end

RunService.Heartbeat:Connect(function(dt)
    if not Settings.Enabled then return end

    local character = LocalPlayer.Character
    local hrp = character and character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local dir = GetMoveDirection()
    if dir.Magnitude == 0 then return end

    -- Скорость в единицах/сек → смещение за кадр
    local speed = Settings.Speed
    local distance = speed * dt

    -- Разбиваем на мелкие шаги для плавности
    local steps = math.max(1, math.floor(distance / Settings.StepSize))
    local stepDist = distance / steps

    for i = 1, steps do
        hrp.CFrame = hrp.CFrame + dir * stepDist
        -- Небольшая пауза каждые несколько шагов
        if i % 5 == 0 then
            RunService.Heartbeat:Wait()
        end
    end
end)

-- ================================
-- RESPAWN — восстановление
-- ================================
LocalPlayer.CharacterAdded:Connect(function(character)
    bypassActive = false
    fakeRoot = nil
    wait(1) -- ждём загрузки персонажа

    if Settings.BypassEnabled then
        ApplyBypass()
    end
end)

print("[SpeedHack] GUI загружен. Используй меню для управления.")
